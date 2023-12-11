module frontend.showDiag;

@safe @nogc pure nothrow:

import frontend.getDiagnosticSeverity : getDiagnosticSeverity;
import frontend.parse.lexer : Token;
import frontend.showModel :
	ShowCtx,
	writeCalledDecls,
	writeCalleds,
	writeFunDecl,
	writeFunDeclAndTypeArgs,
	writeLineAndColumnRange,
	writeName,
	writePurity,
	writeSig,
	writeSigSimple,
	writeStructInst,
	writeTypeQuoted,
	writeUri,
	writeUriAndRange;
import model.diag :
	Diagnostic,
	Diag,
	DiagnosticSeverity,
	ExpectedForDiag,
	ReadFileDiag,
	TypeContainer,
	TypeKind,
	TypeWithContainer,
	UriAndDiagnostic;
import model.model :
	arity,
	arityMatches,
	bestCasePurity,
	CalledDecl,
	eachDiagnostic,
	EnumBackingType,
	FunDeclAndTypeArgs,
	Local,
	LocalMutability,
	name,
	nTypeParams,
	Params,
	Program,
	range,
	SpecDecl,
	SpecDeclSig,
	StructInst,
	stringOfSpecBodyBuiltinKind,
	stringOfVisibility,
	Type,
	TypeParamsAndSig;
import model.parseDiag : ParseDiag, ParseDiagnostic;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.col.arr : empty, only;
import util.col.arrBuilder : add, ArrBuilder, arrBuilderSort, finishArr;
import util.col.arrUtil : exists;
import util.lineAndColumnGetter : LineAndColumnGetter, lineAndColumnRange;
import util.col.multiMap : makeMultiMap, MultiMap, MultiMapCb;
import util.col.sortUtil : sorted;
import util.col.str : SafeCStr;
import util.comparison : Comparison;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : compareRange;
import util.sym : AllSymbols, Sym, writeSym;
import util.uri : AllUris, baseName, compareUriAlphabetically, Uri, writeRelPath, writeUri;
import util.util : stringOfEnum, max, unreachable;
import util.writer :
	withWriter, writeEscapedChar, writeNewline, writeQuotedString, writeWithCommas, writeWithSeparator, Writer;

SafeCStr stringOfDiagnostics(ref Alloc alloc, in ShowCtx ctx, in Program program) =>
	withWriter(alloc, (scope ref Writer writer) {
		DiagnosticSeverity severity = maxDiagnosticSeverity(program);
		bool first = true;
		foreach (UriAndDiagnostics x; sortedDiagnostics(alloc, ctx.allUris, program)) {
			foreach (Diagnostic diagnostic; x.diagnostics) {
				if (getDiagnosticSeverity(diagnostic.kind) == severity) {
					if (!first)
						writer ~= '\n';
					else
						first = false;
					showDiagnostic(writer, ctx, UriAndDiagnostic(x.uri, diagnostic));
				}
			}
		}
	});

SafeCStr stringOfDiag(ref Alloc alloc, in ShowCtx ctx, in Diag diag) =>
	withWriter(alloc, (scope ref Writer writer) {
		writeDiag(writer, ctx, diag);
	});

SafeCStr stringOfParseDiagnostics(
	ref Alloc alloc,
	in AllSymbols allSymbols,
	in AllUris allUris,
	in LineAndColumnGetter lcg,
	in ParseDiagnostic[] diagnostics,
) =>
	withWriter(alloc, (scope ref Writer writer) {
		foreach (ref ParseDiagnostic x; diagnostics) {
			writeLineAndColumnRange(writer, lineAndColumnRange(lcg, x.range));
			writer ~= ' ';
			writeParseDiag(writer, allSymbols, allUris, x.kind);
		}
	});

immutable struct UriAndDiagnostics {
	Uri uri;
	Diagnostic[] diagnostics;
}

UriAndDiagnostics[] sortedDiagnostics(ref Alloc alloc, in AllUris allUris, in Program program) {
	MultiMap!(Uri, Diagnostic) map = makeMultiMap!(Uri, Diagnostic)(alloc, (in MultiMapCb!(Uri, Diagnostic) cb) {
		eachDiagnostic(program, (in UriAndDiagnostic x) {
			cb(x.uri, x.diagnostic);
		});
	});

	ArrBuilder!UriAndDiagnostics res; // TODO:PERF ExactSizeArrBuilder
	foreach (Uri uri, immutable Diagnostic[] diags; map) {
		Diagnostic[] sortedDiags = sorted!Diagnostic(alloc, diags, (in Diagnostic x, in Diagnostic y) =>
			compareDiagnostic(x, y));
		add(alloc, res, UriAndDiagnostics(uri, sortedDiags));
	}
	arrBuilderSort!UriAndDiagnostics(res, (in UriAndDiagnostics x, in UriAndDiagnostics y) =>
		compareUriAlphabetically(allUris, x.uri, y.uri));
	return finishArr(alloc, res);
}

private:

Comparison compareDiagnostic(in Diagnostic a, in Diagnostic b) =>
	compareRange(a.range, b.range);

DiagnosticSeverity maxDiagnosticSeverity(in Program a) {
	DiagnosticSeverity res = DiagnosticSeverity.unusedCode;
	eachDiagnostic(a, (in UriAndDiagnostic x) {
		res = max(res, getDiagnosticSeverity(x.kind));
	});
	return res;
}

void writeUnusedDiag(scope ref Writer writer, in ShowCtx ctx, in Diag.Unused a) {
	a.kind.matchIn!void(
		(in Diag.Unused.Kind.Import x) {
			if (has(x.importedName)) {
				writer ~= "imported name ";
				writeName(writer, ctx, force(x.importedName));
			} else {
				writer ~= "imported module ";
				writeName(writer, ctx, baseName(ctx.allUris, x.importedModule.uri));
			}
			writer ~= " is unused";
		},
		(in Diag.Unused.Kind.Local x) {
			writer ~= "local ";
			writeName(writer, ctx, x.local.name);
			writer ~= (x.local.mutability == LocalMutability.immut)
				? " is unused"
				: x.usedGet
				? " is mutable but never reassigned"
				: x.usedSet
				? " is assigned to but unused"
				: " is unused";
		},
		(in Diag.Unused.Kind.PrivateDecl x) {
			writeName(writer, ctx, x.name);
			writer ~= " is unused";
		});
}

void writeParseDiag(scope ref Writer writer, in AllSymbols allSymbols, in AllUris allUris, in ParseDiag d) {
	d.matchIn!void(
		(in ParseDiag.Expected x) {
			final switch (x.kind) {
				case ParseDiag.Expected.Kind.afterMut:
					writer ~= "expected '[' or '*' after 'mut'";
					break;
				case ParseDiag.Expected.Kind.blockCommentEnd:
					writer ~= "Expected '###' (then a newline)";
					break;
				case ParseDiag.Expected.Kind.closeInterpolated:
					writer ~= "expected '}'";
					break;
				case ParseDiag.Expected.Kind.closingBracket:
					writer ~= "expected ']'";
					break;
				case ParseDiag.Expected.Kind.closingParen:
					writer ~= "expected ')'";
					break;
				case ParseDiag.Expected.Kind.colon:
					writer ~= "expected ':'";
					break;
				case ParseDiag.Expected.Kind.comma:
					writer ~= "expected ', '";
					break;
				case ParseDiag.Expected.Kind.dedent:
					writer ~= "expected a dedent";
					break;
				case ParseDiag.Expected.Kind.endOfLine:
					writer ~= "expected end of line";
					break;
				case ParseDiag.Expected.Kind.equals:
					writer ~= "expected '='";
					break;
				case ParseDiag.Expected.Kind.indent:
					writer ~= "expected an indent";
					break;
				case ParseDiag.Expected.Kind.lambdaArrow:
					writer ~= "expected ' =>' after lambda parameters";
					break;
				case ParseDiag.Expected.Kind.less:
					writer ~= "expected '<'";
					break;
				case ParseDiag.Expected.Kind.literalIntOrNat:
					writer ~= "expected an integer";
					break;
				case ParseDiag.Expected.Kind.literalNat:
					writer ~= "expected a natural number";
					break;
				case ParseDiag.Expected.Kind.modifier:
					writer ~= "expected a valid modifier";
					break;
				case ParseDiag.Expected.Kind.name:
					writer ~= "expected a name (non-operator)";
					break;
				case ParseDiag.Expected.Kind.nameOrOperator:
					writer ~= "expected a name or operator";
					break;
				case ParseDiag.Expected.Kind.newline:
					writer ~= "expected a newline";
					break;
				case ParseDiag.Expected.Kind.newlineOrDedent:
					writer ~= "expected a newline or dedent";
					break;
				case ParseDiag.Expected.Kind.openParen:
					writer ~= "expected '('";
					break;
				case ParseDiag.Expected.Kind.then:
					writer ~= "expected '<-'";
					break;
				case ParseDiag.Expected.Kind.questionEqual:
					writer ~= "expected '?='";
					break;
				case ParseDiag.Expected.Kind.quoteDouble:
					writer ~= "expected '\"'";
					break;
				case ParseDiag.Expected.Kind.quoteDouble3:
					writer ~= "expected '\"\"\"'";
					break;
				case ParseDiag.Expected.Kind.slash:
					writer ~= "expected '/'";
					break;
				case ParseDiag.Expected.Kind.typeArgsEnd:
					writer ~= "expected '>'";
					break;
			}
		},
		(in ParseDiag.FunctionTypeMissingParens) {
			writer ~= "function type missing parentheses";
		},
		(in ParseDiag.ImportFileTypeNotSupported) {
			writer ~= "import file type not allowed; the only supported types are 'nat8 array' and 'string'";
		},
		(in ParseDiag.IndentNotDivisible d) {
			writer ~= "expected indentation by ";
			writer ~= d.nSpacesPerIndent;
			writer ~= " spaces per level, but got ";
			writer ~= d.nSpaces;
			writer ~= " which is not divisible";
		},
		(in ParseDiag.IndentTooMuch x) {
			writer ~= "indented too far";
		},
		(in ParseDiag.IndentWrongCharacter d) {
			writer ~= "expected indentation by ";
			writer ~= d.expectedTabs ? "tabs" : "spaces";
			writer ~= " (based on first indented line), but here there is a ";
			writer ~= d.expectedTabs ? "space" : "tab";
		},
		(in ParseDiag.InvalidName x) {
			writeQuotedString(writer, x.actual);
			writer ~= " is not a valid name";
		},
		(in ParseDiag.InvalidStringEscape x) {
			writer ~= "invalid escape character '";
			writeEscapedChar(writer, x.actual);
			writer ~= '\'';
		},
		(in ParseDiag.NeedsBlockCtx x) {
			if (x.kind == ParseDiag.NeedsBlockCtx.Kind.lambda)
				writer ~= "lambda";
			else {
				writer ~= '\'';
				writer ~= stringOfEnum(x.kind);
				writer ~= '\'';
			}
			writer ~= " expression must appear ";
			writer ~= x.kind == ParseDiag.NeedsBlockCtx.Kind.break_
				? "on its own line"
				: "in a context where it can be followed by an indented block";
		},
		(in ReadFileDiag x) {
			showReadFileDiag(writer, x);
		},
		(in ParseDiag.TrailingComma) {
			writer ~= "trailing comma";
		},
		(in ParseDiag.UnexpectedCharacter u) {
			writer ~= "unexpected character '";
			showChar(writer, u.ch);
			writer ~= "'";
		},
		(in ParseDiag.UnexpectedOperator x) {
			writer ~= "unexpected '";
			writeSym(writer, allSymbols, x.operator);
			writer ~= '\'';
		},
		(in ParseDiag.UnexpectedToken u) {
			writer ~= describeTokenForUnexpected(u.token);
		},
		(in ParseDiag.WhenMustHaveElse) {
			writer ~= "'if' expression must end in 'else'";
		});
}

void showReadFileDiag(scope ref Writer writer, ReadFileDiag a) {
	writer ~= () {
		final switch (a) {
			case ReadFileDiag.notFound:
				return "File does not exist";
			case ReadFileDiag.error:
				return "Unable to read file";
			case ReadFileDiag.loading:
				return "IDE is still loading file";
			case ReadFileDiag.unknown:
				return "IDE has not started loading file";
		}
	}();
}

void showChar(scope ref Writer writer, char c) {
	switch (c) {
		case '\0':
			writer ~= "\\0";
			break;
		case '\n':
			writer ~= "\\n";
			break;
		case '\t':
			writer ~= "\\t";
			break;
		default:
			writer ~= c;
			break;
	}
}

void writeSpecTrace(
	scope ref Writer writer,
	in ShowCtx ctx,
	in TypeContainer outermostTypeContainer,
	in FunDeclAndTypeArgs[] trace,
) {
	Cell!TypeContainer prevTypeContainer = Cell!TypeContainer(outermostTypeContainer);
	foreach (FunDeclAndTypeArgs x; trace) {
		writer ~= "\n\t";
		writeFunDeclAndTypeArgs(writer, ctx, cellGet(prevTypeContainer), x);
		cellSet(prevTypeContainer, TypeContainer(x.decl));
	}
}

void writeCallNoMatch(scope ref Writer writer, in ShowCtx ctx, in Diag.CallNoMatch d) {
	bool someCandidateHasCorrectNTypeArgs =
		d.actualNTypeArgs == 0 ||
		exists!CalledDecl(d.allCandidates, (in CalledDecl c) =>
			nTypeParams(c) == 1 || nTypeParams(c) == d.actualNTypeArgs);
	bool someCandidateHasCorrectArity =
		exists!CalledDecl(d.allCandidates, (in CalledDecl c) =>
			(d.actualNTypeArgs == 0 || nTypeParams(c) == d.actualNTypeArgs) &&
			arityMatches(arity(c), d.actualArity));

	if (empty(d.allCandidates)) {
		writer ~= "there is no function ";
		if (d.actualArity == 0)
			// If there is no local variable by that name we try a call,
			// but message should reflect that the user might not have wanted a call.
			writer ~= "or variable ";
		writer ~= "named ";
		writeName(writer, ctx, d.funName);

		if (d.actualArgTypes.length == 1) {
			writer ~= "\nargument type: ";
			writeTypeQuoted(writer, ctx, TypeWithContainer(only(d.actualArgTypes), d.typeContainer));
		}
	} else if (!someCandidateHasCorrectArity) {
		writer ~= "there are functions named ";
		writeName(writer, ctx, d.funName);
		writer ~= ", but none takes ";
		if (someCandidateHasCorrectNTypeArgs) {
			writer ~= d.actualArity;
		} else {
			writer ~= d.actualNTypeArgs;
			writer ~= " type";
		}
		writer ~= " arguments. candidates:";
		writeCalledDecls(writer, ctx, d.typeContainer, d.allCandidates);
	} else {
		writer ~= "there are functions named ";
		writeName(writer, ctx, d.funName);
		writer ~= ", but they do not match the ";
		bool hasRet = d.expectedReturnType.isA!(ExpectedForDiag.Choices);
		bool hasArgs = empty(d.actualArgTypes);
		string descr = hasRet
			? hasArgs ? "expected return type and actual argument types" : "expected return type"
			: "actual argument types";
		writer ~= descr;
		writer ~= '.';
		writeNewline(writer, 0);
		if (hasRet)
			writeExpected(writer, ctx, d.expectedReturnType, ExpectedKind.return_);
		if (hasArgs) {
			writer ~= "\nactual argument types: ";
			writeWithCommas!Type(writer, d.actualArgTypes, (in Type t) {
				writeTypeQuoted(writer, ctx, TypeWithContainer(t, d.typeContainer));
			});
			if (d.actualArgTypes.length < d.actualArity)
				writer ~= " (other arguments not checked, gave up early)";
		}
		writer ~= "\ncandidates (with ";
		writer ~= d.actualArity;
		writer ~= " arguments):";
		writeCalledDecls(writer, ctx, d.typeContainer, d.allCandidates, (in CalledDecl c) =>
			arityMatches(arity(c), d.actualArity));
	}
}

void writeDiag(scope ref Writer writer, in ShowCtx ctx, in Diag diag) {
	diag.matchIn!void(
		(in Diag.AssignmentNotAllowed) {
			writer ~= "can't assign to this kind of expression";
		},
		(in Diag.BuiltinUnsupported x) {
			writer ~= "the compiler does not implement a builtin named ";
			writeName(writer, ctx, x.name);
		},
		(in Diag.CallMultipleMatches x) {
			writer ~= "cannot choose an overload of ";
			writeName(writer, ctx, x.funName);
			writer ~= ". multiple functions match:";
			writeCalledDecls(writer, ctx, x.typeContainer, x.matches);
		},
		(in Diag.CallNoMatch x) {
			writeCallNoMatch(writer, ctx, x);
		},
		(in Diag.CallShouldUseSyntax x) {
			writer ~= () {
				final switch (x.kind) {
					case Diag.CallShouldUseSyntax.Kind.for_break:
						return "prefer to write a 'for' loop instead of calling 'for-break'";
					case Diag.CallShouldUseSyntax.Kind.force:
						return "prefer to write 'x!' instead of 'x.force'";
					case Diag.CallShouldUseSyntax.Kind.for_loop:
						return "prefer to write a 'for' loop instead of calling 'for-loop'";
					case Diag.CallShouldUseSyntax.Kind.new_:
						switch (x.arity) {
							case 0:
								return "prefer to write '()' instead of 'new'";
							case 1:
								return "prefer to write '(x,)' instead of 'x.new'";
							default:
								return "prefer to write 'x, y' instead of 'x new y'";
						}
					case Diag.CallShouldUseSyntax.Kind.not:
						return "prefer to write '!x' instead of 'x.not'";
					case Diag.CallShouldUseSyntax.Kind.set_subscript:
						return "prefer to write 'x[i] := y' instead of 'x set-subscript i, y'";
					case Diag.CallShouldUseSyntax.Kind.subscript:
						return "prefer to write 'x[i]' instead of 'x subscript i'";
					case Diag.CallShouldUseSyntax.Kind.with_block:
						return "prefer to write a 'with' block instead of calling 'with-block'";
				}
			}();
		},
		(in Diag.CantCall x) {
			writer ~= () {
				final switch (x.reason) {
					case Diag.CantCall.Reason.nonBare:
						return "a 'bare' function can't call a non-'bare' function";
					case Diag.CantCall.Reason.summon:
						return "a non-'summon' function can't call a 'summon' function";
					case Diag.CantCall.Reason.unsafe:
						return "a non-'unsafe' function can't call an 'unsafe' function";
					case Diag.CantCall.Reason.variadicFromBare:
						return "a 'bare' function can't call a variadic function";
				}
			}();
			writer ~= ' ';
			writeFunDecl(writer, ctx, x.callee);
			if (x.reason == Diag.CantCall.Reason.unsafe)
				writer ~= "\n(consider putting the call in a 'trusted' expression)";
		},
		(in Diag.CharLiteralMustBeOneChar) {
			writer ~= "value of 'char' type must be a single character";
		},
		(in Diag.CommonFunDuplicate x) {
			writer ~= "module contains multiple valid ";
			writeName(writer, ctx, x.name);
			writer ~= " functions";
		},
		(in Diag.CommonFunMissing x) {
			writer ~= "module should have a function:\n\t";
			writeWithSeparator!TypeParamsAndSig(writer, x.sigChoices, "\nor:\n\t", (in TypeParamsAndSig sig) {
				writeSigSimple(writer, ctx, TypeContainer(x.dummyForContext), x.dummyForContext.name, sig);
			});
		},
		(in Diag.CommonTypeMissing x) {
			writer ~= "expected to find a type named ";
			writeName(writer, ctx, x.name);
			writer ~= " in this module";
		},
		(in Diag.DestructureTypeMismatch x) {
			x.expected.matchIn!void(
				(in Diag.DestructureTypeMismatch.Expected.Tuple t) {
					writer ~= "expected a tuple with ";
					writer ~= t.size;
					writer ~= " elements, but got ";
				},
				(in TypeWithContainer t) {
					writer ~= "expected type ";
					writeTypeQuoted(writer, ctx, t);
					writer ~= ", but got ";
				});
			writeTypeQuoted(writer, ctx, x.actual);
		},
		(in Diag.DuplicateDeclaration x) {
			writer ~= () {
				final switch (x.kind) {
					case Diag.DuplicateDeclaration.Kind.enumMember:
						return "enum member";
					case Diag.DuplicateDeclaration.Kind.flagsMember:
						return "flags member";
					case Diag.DuplicateDeclaration.Kind.paramOrLocal:
						return "local";
					case Diag.DuplicateDeclaration.Kind.recordField:
						return "record field";
					case Diag.DuplicateDeclaration.Kind.spec:
						return "spec";
					case Diag.DuplicateDeclaration.Kind.structOrAlias:
						return "type";
					case Diag.DuplicateDeclaration.Kind.typeParam:
						return "type parameter";
					case Diag.DuplicateDeclaration.Kind.unionMember:
						return "union member";
				}
			}();
			writer ~= " name ";
			writeName(writer, ctx, x.name);
			writer ~= " is already used";
		},
		(in Diag.DuplicateExports x) {
			writer ~= "there are multiple exported ";
			writer ~= () {
				final switch (x.kind) {
					case Diag.DuplicateExports.Kind.spec:
						return "specs";
					case Diag.DuplicateExports.Kind.type:
						return "types";
				}
			}();
			writer ~= " named ";
			writeName(writer, ctx, x.name);
		},
		(in Diag.DuplicateImports x) {
			//TODO: use x.kind
			writer ~= "the symbol ";
			writeName(writer, ctx, x.name);
			writer ~= " appears in multiple modules";
		},
		(in Diag.EnumBackingTypeInvalid x) {
			writer ~= "type ";
			writeTypeQuoted(writer, ctx, TypeWithContainer(x.actual, TypeContainer(x.enum_)));
			writer ~= " cannot be used to back an enum";
		},
		(in Diag.EnumDuplicateValue x) {
			writer ~= "duplicate enum value ";
			if (x.signed)
				writer ~= x.value;
			else
				writer ~= cast(ulong) x.value;
		},
		(in Diag.EnumMemberOverflows x) {
			writer ~= "enum member is not in the allowed range ";
			writer ~= minValue(x.backingType);
			writer ~= " to ";
			writer ~= maxValue(x.backingType);
		},
		(in Diag.ExpectedTypeIsNotALambda x) {
			if (has(x.expectedType)) {
				writer ~= "the expected type at the lambda is ";
				writeTypeQuoted(writer, ctx, force(x.expectedType));
				writer ~= ", which is not a lambda type";
			} else
				writer ~= "there is no expected type at this location; lambdas need an expected type";
		},
		(in Diag.ExternFunForbidden x) {
			writer ~= "'extern' function ";
			writeName(writer, ctx, x.fun.name);
			writer ~= () {
				final switch (x.reason) {
					case Diag.ExternFunForbidden.Reason.hasSpecs:
						return " can't have specs";
					case Diag.ExternFunForbidden.Reason.hasTypeParams:
						return " can't have type parameters";
					case Diag.ExternFunForbidden.Reason.variadic:
						return " can't be variadic";
				}
			}();
		},
		(in Diag.ExternHasTypeParams) {
			writer ~= "an 'extern' type should not be a template";
		},
		(in Diag.ExternMissingLibraryName) {
			writer ~= "expected 'extern' to be preceded by the library name";
		},
		(in Diag.ExternRecordImplicitlyByVal x) {
			writer ~= "'extern' record ";
			writeName(writer, ctx, x.struct_.name);
			writer ~= " is implicitly 'by-val'";
		},
		(in Diag.ExternUnion) {
			writer ~= "a union can't be 'extern'";
		},
		(in Diag.FunMissingBody) {
			writer ~= "this function needs a body";
		},
		(in Diag.FunModifierTrustedOnNonExtern) {
			writer ~= "only 'extern' functions can be 'trusted'; otherwise 'trusted' should be used as an expression";
		},
		(in Diag.IfNeedsOpt x) {
			writer ~= "Expected an option type, but got ";
			writeTypeQuoted(writer, ctx, x.actualType);
		},
		(in Diag.ImportFileDiag x) {
			x.matchIn!void(
				(in Diag.ImportFileDiag.CircularImport y) {
					writer ~= "this is part of a circular import:";
					foreach (Uri uri; y.cycle) {
						writeNewline(writer, 1);
						writeUri(writer, ctx, uri);
						writer ~= " imports";
					}
					writeNewline(writer, 1);
					writeUri(writer, ctx, y.cycle[0]);
				},
				(in Diag.ImportFileDiag.ReadError y) {
					showReadFileDiag(writer, y.diag);
					writer ~= ": ";
					writeUri(writer, ctx, y.uri);
				},
				(in Diag.ImportFileDiag.RelativeImportReachesPastRoot y) {
					writer ~= "relative path ";
					writeRelPath(writer, ctx.allUris, y.imported);
					writer ~= " reaches above the root directory";
				});
		},
		(in Diag.ImportRefersToNothing x) {
			writer ~= "imported name ";
			writeName(writer, ctx, x.name);
			writer ~= " does not refer to anything";
		},
		(in Diag.LambdaCantInferParamType x) {
			writer ~= "Can't infer the lambda parameter's type.";
		},
		(in Diag.LambdaClosesOverMut x) {
			writer ~= "This lambda is a 'fun' but references ";
			writeName(writer, ctx, x.name);
			if (has(x.type)) {
				writer ~= " of 'mut' type ";
				writeTypeQuoted(writer, ctx, force(x.type));
			} else
				writer ~= " which is 'mut'";
			writer ~= " (should it be an 'act' or 'ref' fun?)";
		},
		(in Diag.LambdaMultipleMatch x) {
			writer ~= "Multiple lambda types are possible.\n";
			writeExpected(writer, ctx, x.expected, ExpectedKind.lambda);
			writeNewline(writer, 0);
			writer ~= "Consider explicitly typing the lambda's parameter.";
		},
		(in Diag.LambdaNotExpected x) {
			if (x.expected.isA!(ExpectedForDiag.Infer))
				writer ~= "lambda expression needs an expected type";
			else {
				writer ~= "the lambda doesn't match the expected type at this location.\n";
				writeExpected(writer, ctx, x.expected, ExpectedKind.lambda);
			}
		},
		(in Diag.LinkageWorseThanContainingFun x) {
			writer ~= "'extern' function ";
			writeName(writer, ctx, x.containingFun.name);
			if (has(x.param)) {
				Opt!Sym paramName = force(x.param).name;
				if (has(paramName)) {
					writer ~= " parameter ";
					writeName(writer, ctx, force(paramName));
				}
			}
			writer ~= " can't reference non-extern type ";
			writeTypeQuoted(writer, ctx, TypeWithContainer(x.referencedType, TypeContainer(x.containingFun)));
		},
		(in Diag.LinkageWorseThanContainingType x) {
			writer ~= "extern type ";
			writeName(writer, ctx, x.containingType.name);
			writer ~= " can't reference non-extern type ";
			writeTypeQuoted(writer, ctx, TypeWithContainer(x.referencedType, TypeContainer(x.containingType)));
		},
		(in Diag.LiteralAmbiguous x) {
			writer ~= "multiple possible types for literal expression: ";
			writeWithCommas!(StructInst*)(writer, x.types, (in StructInst* type) {
				writeStructInst(writer, ctx, x.typeContainer, *type);
			});
		},
		(in Diag.LiteralOverflow x) {
			writer ~= "literal exceeds the range of a ";
			writeTypeQuoted(writer, ctx, x.type);
		},
		(in Diag.LocalIgnoredButMutable) {
			writer ~= "unnecessary 'mut' on ignored local variable";
		},
		(in Diag.LocalNotMutable x) {
			writer ~= "local variable ";
			writeName(writer, ctx, name(x.local));
			writer ~= " was not marked 'mut'";
		},
		(in Diag.LoopWithoutBreak) {
			writer ~= "'loop' has no 'break'";
		},
		(in Diag.MatchCaseNamesDoNotMatch x) {
			writer ~= "expected the case names to be: ";
			writeWithCommas!Sym(writer, x.expectedNames, (in Sym name) {
				writeName(writer, ctx, name);
			});
		},
		(in Diag.MatchOnNonUnion x) {
			writer ~= "can't match on non-union type ";
			writeTypeQuoted(writer, ctx, x.type);
		},
		(in Diag.ModifierConflict x) {
			writeName(writer, ctx, x.curModifier);
			writer ~= " conflicts with ";
			writeName(writer, ctx, x.prevModifier);
		},
		(in Diag.ModifierDuplicate x) {
			writer ~= "redundant ";
			writeName(writer, ctx, x.modifier);
		},
		(in Diag.ModifierInvalid x) {
			writeName(writer, ctx, x.modifier);
			writer ~= " is not supported for ";
			writer ~= aOrAnTypeKind(x.typeKind);
		},
		(in Diag.ModifierRedundantDueToModifier x) {
			writeName(writer, ctx, x.redundantModifier);
			writer ~= " is redundant given ";
			writeName(writer, ctx, x.modifier);
		},
		(in Diag.ModifierRedundantDueToTypeKind x) {
			writeName(writer, ctx, x.modifier);
			writer ~= " is already the default for ";
			writer ~= aOrAnTypeKind(x.typeKind);
			writer ~= " type";
		},
		(in Diag.MutFieldNotAllowed) {
			writer ~= "field is mut, but containing record was not marked mut";
		},
		(in Diag.NameNotFound x) {
			writer ~= stringOfEnum(x.kind);
			writer ~= " name not found: ";
			writeName(writer, ctx, x.name);
		},
		(in Diag.NeedsExpectedType x) {
			writer ~= '\'';
			writer ~= stringOfEnum(x.kind);
			writer ~= "' expression needs an expected type";
		},
		(in Diag.ParamCantBeMutable) {
			writer ~= "mutable parameters are not supported";
		},
		(in Diag.ParamMissingType) {
			writer ~= "parameter needs a type";
		},
		(in Diag.ParamNotMutable) {
			writer ~= "can't change the value of a parameter; consider introducing a mutable local instead";
		},
		(in ParseDiag x) {
			writeParseDiag(writer, ctx.allSymbols, ctx.allUris, x);
		},
		(in Diag.PtrIsUnsafe) {
			writer ~= "getting a pointer is unsafe";
		},
		(in Diag.PtrMutToConst x) {
			writer ~= () {
				final switch (x.kind) {
					case Diag.PtrMutToConst.Kind.field:
						return "can't get a mutable pointer to a non-'mut' field";
					case Diag.PtrMutToConst.Kind.local:
						return "can't get a mutable pointer to a non-'mut' local";
				}
			}();
		},
		(in Diag.PtrUnsupported) {
			writer ~= "can't get a pointer to this kind of expression";
		},
		(in Diag.PurityWorseThanParent x) {
			writer ~= "struct ";
			writeName(writer, ctx, x.parent.name);
			writer ~= " has purity ";
			writePurity(writer, ctx, x.parent.purity);
			writer ~= ", but member of type ";
			writeTypeQuoted(writer, ctx, TypeWithContainer(x.child, TypeContainer(x.parent)));
			writer ~= " has purity ";
			writePurity(writer, ctx, bestCasePurity(x.child));
		},
		(in Diag.RecordNewVisibilityIsRedundant x) {
			writer ~= "the 'new' function for this record is already '";
			writer ~= stringOfVisibility(x.visibility);
			writer ~= "' by default";
		},
		(in Diag.SpecMatchError x) {
			x.reason.matchIn!void(
				(in Diag.SpecMatchError.Reason.MultipleMatches y) {
					writer ~= "Multiple implementations found for spec signature ";
					writeName(writer, ctx, y.sigName);
					writer ~= ':';
					writeCalleds(writer, ctx, x.outermostTypeContainer, y.matches);
				});
			writer ~= "\n\tcalling:";
			writeSpecTrace(writer, ctx, x.outermostTypeContainer, x.trace);
		},
		(in Diag.SpecNoMatch x) {
			writer ~= "a spec was not satisfied.\n\t";
			x.reason.matchIn!void(
				(in Diag.SpecNoMatch.Reason.BuiltinNotSatisfied y) {
					writeTypeQuoted(writer, ctx, TypeWithContainer(y.type, x.outermostTypeContainer));
					writer ~= " is not '";
					writer ~= stringOfSpecBodyBuiltinKind(y.kind);
					writer ~= "'";
				},
				(in Diag.SpecNoMatch.Reason.CantInferTypeArguments _) {
					writer ~= "Can't infer type arguments";
				},
				(in Diag.SpecNoMatch.Reason.SpecImplNotFound y) {
					writer ~= "no implementation was found for spec signature ";
					SpecDeclSig* sig = y.sigDecl;
					writeSig(
						writer, ctx, x.outermostTypeContainer, sig.name, sig.returnType,
						Params(sig.params), some(y.sigType));
				},
				(in Diag.SpecNoMatch.Reason.TooDeep _) {
					writer ~= "spec instantiation is too deep";
				});
			writer ~= " calling:";
			writeSpecTrace(writer, ctx, x.outermostTypeContainer, x.trace);
		},
		(in Diag.SpecNameMissing) {
			writer ~= "spec name is missing";
		},
		(in Diag.SpecRecursion x) {
			writer ~= "spec's parents tree is too deep. trace: ";
			writeWithCommas!(immutable SpecDecl*)(writer, x.trace, (in SpecDecl* spec) {
				writeName(writer, ctx, spec.name);
			});
		},
		(in Diag.ThreadLocalError x) {
			writer ~= "thread-local ";
			writeName(writer, ctx, x.fun.name);
			writer ~= () {
				final switch (x.kind) {
					case Diag.ThreadLocalError.Kind.hasParams:
						return " can't have parameters";
					case Diag.ThreadLocalError.Kind.hasSpecs:
						return "can't have specs";
					case Diag.ThreadLocalError.Kind.hasTypeParams:
						return " can't have type parameters";
					case Diag.ThreadLocalError.Kind.mustReturnPtrMut:
						return " return type must be a 'mut*'";
				}
			}();
		},
		(in Diag.TrustedUnnecessary x) {
			writer ~= () {
				final switch (x.reason) {
					case Diag.TrustedUnnecessary.Reason.inTrusted:
						return "'trusted' is redundant inside another 'trusted'";
					case Diag.TrustedUnnecessary.Reason.inUnsafeFunction:
						return "'trusted' has no effect inside an 'unsafe' function";
					case Diag.TrustedUnnecessary.Reason.unused:
						return "there is no unsafe code inside this 'trusted'";
				}
			}();
		},
		(in Diag.TypeAnnotationUnnecessary x) {
			writer ~= "type ";
			writeTypeQuoted(writer, ctx, x.type);
			writer ~= " was already inferred";
		},
		(in Diag.TypeConflict x) {
			writeExpected(writer, ctx, x.expected, ExpectedKind.generic);
			writer ~= "\nactual:\n\t";
			writeTypeQuoted(writer, ctx, x.actual);
		},
		(in Diag.TypeParamCantHaveTypeArgs) {
			writer ~= "a type parameter can't take type arguments";
		},
		(in Diag.TypeShouldUseSyntax x) {
			writer ~= () {
				final switch (x.kind) {
					case Diag.TypeShouldUseSyntax.Kind.funAct:
						return "prefer to write 'act r(p)' instead of '(r, p) fun-act'";
					case Diag.TypeShouldUseSyntax.Kind.funFar:
						return "prefer to write 'far r(p)' instead of '(r, p) fun-far'";
					case Diag.TypeShouldUseSyntax.Kind.funFun:
						return "prefer to write 'fun r(p)' instead of '(r, p) fun-fun'";
					case Diag.TypeShouldUseSyntax.Kind.future:
						return "prefer to write 'a$' instead of 'a future";
					case Diag.TypeShouldUseSyntax.Kind.list:
						return "prefer to write 'a[]' instead of 'a list'";
					case Diag.TypeShouldUseSyntax.Kind.map:
						return "prefer to write 'v[k]' instead of '(k, v) map'";
					case Diag.TypeShouldUseSyntax.Kind.mutMap:
						return "prefer to write 'v mut[k]' instead of '(k, v) mut-map'";
					case Diag.TypeShouldUseSyntax.Kind.mutList:
						return "prefer to write 'a mut[]' instead of 'a mut-list'";
					case Diag.TypeShouldUseSyntax.Kind.mutPointer:
						return "prefer to write 'a mut*' instead of 'a mut-pointer'";
					case Diag.TypeShouldUseSyntax.Kind.opt:
						return "prefer to write 'a?' instead of 'a option'";
					case Diag.TypeShouldUseSyntax.Kind.pointer:
						return "prefer to write 'a*' instead of 'a const-pointer'";
					case Diag.TypeShouldUseSyntax.Kind.tuple:
						return "prefer to write '(a, b)' instead of '(a, b) tuple2'";
				}
			}();
		},
		(in Diag.Unused x) {
			writeUnusedDiag(writer, ctx, x);
		},
		(in Diag.VarargsParamMustBeArray _) {
			writer ~= "variadic parameter must be an 'array'";
		},
		(in Diag.WrongNumberTypeArgs x) {
			writeName(writer, ctx, x.name);
			writer ~= " expected to get ";
			writer ~= x.nExpectedTypeArgs;
			writer ~= " type args, but got ";
			writer ~= x.nActualTypeArgs;
		});
}

void showDiagnostic(scope ref Writer writer, in ShowCtx ctx, in UriAndDiagnostic a) {
	writeUriAndRange(writer, ctx, a.where);
	writer ~= ' ';
	writeDiag(writer, ctx, a.kind);
}

enum ExpectedKind {
	generic,
	lambda,
	return_,
}

void writeExpected(scope ref Writer writer, in ShowCtx ctx, in ExpectedForDiag a, ExpectedKind kind) {
	void writeType() {
		if (kind == ExpectedKind.return_) writer ~= "return ";
		writer ~= "type";
	}
	a.matchIn!void(
		(in ExpectedForDiag.Choices choices) {
			if (choices.types.length == 1) {
				writer ~= "expected ";
				writeType();
				writer ~= ": ";
				writeTypeQuoted(writer, ctx, TypeWithContainer(only(choices.types), choices.typeContainer));
			} else {
				writer ~= "expected one of these ";
				writeType();
				writer ~= "s:";
				foreach (Type t; choices.types) {
					writeNewline(writer, 1);
					writeTypeQuoted(writer, ctx, TypeWithContainer(t, choices.typeContainer));
				}
			}
		},
		(in ExpectedForDiag.Infer) {
			writer ~= "this location has no expected ";
			writeType();
		},
		(in ExpectedForDiag.Loop) {
			writer ~= "expected a loop 'break' or 'continue'";
		});
}

string aOrAnTypeKind(TypeKind a) {
	final switch (a) {
		case TypeKind.builtin:
			return "a builtin";
		case TypeKind.enum_:
			return "an enum";
		case TypeKind.extern_:
			return "an extern";
		case TypeKind.flags:
			return "a flags";
		case TypeKind.record:
			return "a record";
		case TypeKind.union_:
			return "a union";
	}
}

long minValue(EnumBackingType type) {
	final switch (type) {
		case EnumBackingType.int8:
			return byte.min;
		case EnumBackingType.int16:
			return short.min;
		case EnumBackingType.int32:
			return int.min;
		case EnumBackingType.int64:
			return long.min;
		case EnumBackingType.nat8:
		case EnumBackingType.nat16:
		case EnumBackingType.nat32:
		case EnumBackingType.nat64:
			return 0;
	}
}

ulong maxValue(EnumBackingType type) {
	final switch (type) {
		case EnumBackingType.int8:
			return byte.max;
		case EnumBackingType.int16:
			return short.max;
		case EnumBackingType.int32:
			return int.max;
		case EnumBackingType.int64:
			return long.max;
		case EnumBackingType.nat8:
			return ubyte.max;
		case EnumBackingType.nat16:
			return ushort.max;
		case EnumBackingType.nat32:
			return uint.max;
		case EnumBackingType.nat64:
			return ulong.max;
	}
}

string describeTokenForUnexpected(Token token) {
	final switch (token) {
		case Token.act:
			return "unexpected keyword 'act'";
		case Token.alias_:
			return "unexpected keyword 'alias'";
		case Token.arrowAccess:
			return "unexpected '->'";
		case Token.arrowLambda:
			return "unexpected '=>'";
		case Token.arrowThen:
			return "unexpected '<-'";
		case Token.as:
			return "unexpected keyword 'as'";
		case Token.assert_:
			return "unexpected keyword 'assert'";
		case Token.at:
			return "unexpected '@'";
		case Token.bang:
			return "unexpected '!'";
		case Token.bare:
			return "unexpected keyword 'bare'";
		case Token.break_:
			return "unexpected keyword 'break'";
		case Token.builtin:
			return "unexpected keyword 'builtin'";
		case Token.builtinSpec:
			return "unexpected keyword 'builtin-spec'";
		case Token.braceLeft:
			return "unexpected '{'";
		case Token.braceRight:
			return "unexpected '}'";
		case Token.bracketLeft:
			return "unexpected '['";
		case Token.bracketRight:
			return "unexpected ']'";
		case Token.colon:
			return "unexpected ':'";
		case Token.colon2:
			return "unexpected '::'";
		case Token.colonEqual:
			return "unexpected ':='";
		case Token.comma:
			return "unexpected ','";
		case Token.continue_:
			return "unexpected keyword 'continue'";
		case Token.dot:
			return "unexpected '.'";
		case Token.dot3:
			return "unexpected '...'";
		case Token.elif:
			return "unexpected keyword 'elif'";
		case Token.else_:
			return "unexpected keyword 'else'";
		case Token.enum_:
			return "unexpected keyword 'enum'";
		case Token.export_:
			return "unexpected keyword 'export'";
		case Token.equal:
			return "unexpected '='";
		case Token.extern_:
			return "unexpected keyword 'extern'";
		case Token.EOF:
			return "unexpected end of file";
		case Token.far:
			return "unexpected keyword 'far'";
		case Token.flags:
			return "unexpected keyword 'flags'";
		case Token.for_:
			return "unexpected keyword 'for'";
		case Token.forbid:
			return "unexpected keyword 'forbid'";
		case Token.forceCtx:
			return "unexpected keyword 'force-ctx'";
		case Token.fun:
			return "unexpected keyword 'fun'";
		case Token.global:
			return "unexpected keyword 'global'";
		case Token.if_:
			return "unexpected keyword 'if'";
		case Token.import_:
			return "unexpected keyword 'import'";
		case Token.invalid:
			// This is UnexpectedCharacter instead
			return unreachable!string;
		case Token.literalFloat:
		case Token.literalInt:
		case Token.literalNat:
			return "unexpected number literal expression";
		case Token.loop:
			return "unexpected keyword 'loop'";
		case Token.match:
			return "unexpected keyword 'match'";
		case Token.mut:
			return "unexpected keyword 'mut'";
		case Token.name:
		case Token.nameOrOperatorColonEquals:
		case Token.nameOrOperatorEquals:
			return "did not expect a name here";
		case Token.newlineDedent:
		case Token.newlineIndent:
		case Token.newlineSameIndent:
			return "unexpected newline";
		case Token.noStd:
			return "unexpected keyword 'no-std'";
		case Token.operator:
			// This is UnexpectedOperator instead
			return unreachable!string;
		case Token.parenLeft:
			return "unexpected '('";
		case Token.parenRight:
			return "unexpected ')'";
		case Token.question:
			return "unexpected '?'";
		case Token.questionEqual:
			return "unexpected '?='";
		case Token.quoteDouble:
			return "unexpected '\"'";
		case Token.quoteDouble3:
			return "unexpected '\"\"\"'";
		case Token.quotedText:
			return unreachable!string;
		case Token.record:
			return "unexpected keyword 'record'";
		case Token.semicolon:
			return "unexpected ';'";
		case Token.spec:
			return "unexpected keyword 'spec'";
		case Token.summon:
			return "unexpected keyword 'summon'";
		case Token.test:
			return "unexpected keyword 'test'";
		case Token.thread_local:
			return "unexpected keyword 'thread-local'";
		case Token.throw_:
			return "unexpected keyword 'throw'";
		case Token.trusted:
			return "unexpected keyword 'trusted'";
		case Token.underscore:
			return "unexpected '_'";
		case Token.union_:
			return "unexpected keyword 'union'";
		case Token.unless:
			return "unexpected keyword 'unless'";
		case Token.unsafe:
			return "unexpected keyword 'unsafe'";
		case Token.until:
			return "unexpected keyword 'until'";
		case Token.while_:
			return "unexpected keyword 'while'";
		case Token.with_:
			return "unexpected keyword 'with'";
	}
}
