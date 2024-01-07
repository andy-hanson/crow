module frontend.showDiag;

@safe @nogc pure nothrow:

import frontend.getDiagnosticSeverity : getDiagnosticSeverity;
import frontend.parse.lexer : Token;
import frontend.showModel :
	ShowCtx,
	ShowDiagCtx,
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
	arityMatches,
	bestCasePurity,
	CalledDecl,
	eachDiagnostic,
	EnumBackingType,
	FunDeclAndTypeArgs,
	Local,
	LocalMutability,
	nTypeParams,
	Params,
	Program,
	SpecDecl,
	SpecDeclSig,
	StructInst,
	stringOfSpecBodyBuiltinKind,
	stringOfVarKindLowerCase,
	stringOfVisibility,
	Type,
	TypeParamsAndSig;
import model.parseDiag : ParseDiag, ParseDiagnostic;
import util.alloc.alloc : Alloc;
import util.col.array : contains, exists, isEmpty, only;
import util.col.arrayBuilder : add, ArrayBuilder, arrBuilderSort, finish;
import util.col.multiMap : makeMultiMap, MultiMap, MultiMapCb;
import util.col.sortUtil : sorted;
import util.comparison : Comparison;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : compareRange;
import util.string : CString;
import util.symbol : Symbol, writeSymbol;
import util.uri : AllUris, baseName, compareUriAlphabetically, Uri, writeRelPath, writeUri;
import util.util : stringOfEnum, max;
import util.writer :
	withWriter,
	writeEscapedChar,
	writeNewline,
	writeQuotedString,
	writeWithCommas,
	writeWithNewlines,
	writeWithSeparator,
	Writer;

CString stringOfDiagnostics(ref Alloc alloc, in ShowDiagCtx ctx, in Program program, in Opt!(Uri[]) onlyForUris) =>
	withWriter(alloc, (scope ref Writer writer) {
		DiagnosticSeverity severity = maxDiagnosticSeverity(program);
		bool first = true;
		foreach (UriAndDiagnostics x; sortedDiagnostics(alloc, ctx.allUris, program))
			if (!has(onlyForUris) || contains(force(onlyForUris), x.uri))
				foreach (Diagnostic diagnostic; x.diagnostics) {
					if (getDiagnosticSeverity(diagnostic.kind) == severity) {
						if (!first)
							writer ~= '\n';
						else
							first = false;
						showDiagnostic(writer, ctx, UriAndDiagnostic(x.uri, diagnostic));
					}
				}
	});

CString stringOfDiag(ref Alloc alloc, in ShowDiagCtx ctx, in Diag diag) =>
	withWriter(alloc, (scope ref Writer writer) {
		writeDiag(writer, ctx, diag);
	});

CString stringOfParseDiagnostics(ref Alloc alloc, in ShowCtx ctx, Uri uri, in ParseDiagnostic[] diagnostics) =>
	withWriter(alloc, (scope ref Writer writer) {
		writeWithNewlines!ParseDiagnostic(writer, diagnostics, (in ParseDiagnostic x) {
			writeLineAndColumnRange(writer, ctx.lineAndColumnGetters[uri][x.range]);
			writer ~= ' ';
			writeParseDiag(writer, ctx, x.kind);
		});
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

	ArrayBuilder!UriAndDiagnostics res; // TODO:PERF ExactSizeArrayBuilder
	foreach (Uri uri, immutable Diagnostic[] diags; map) {
		Diagnostic[] sortedDiags = sorted!Diagnostic(alloc, diags, (in Diagnostic x, in Diagnostic y) =>
			compareDiagnostic(x, y));
		add(alloc, res, UriAndDiagnostics(uri, sortedDiags));
	}
	arrBuilderSort!UriAndDiagnostics(res, (in UriAndDiagnostics x, in UriAndDiagnostics y) =>
		compareUriAlphabetically(allUris, x.uri, y.uri));
	return finish(alloc, res);
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
				writer ~= "Imported name ";
				writeName(writer, ctx, force(x.importedName));
			} else {
				writer ~= "Imported module ";
				writeName(writer, ctx, baseName(ctx.allUris, x.importedModule.uri));
			}
			writer ~= " is unused";
		},
		(in Diag.Unused.Kind.Local x) {
			writer ~= "Local ";
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

void writeParseDiag(scope ref Writer writer, in ShowCtx ctx, in ParseDiag d) {
	d.matchIn!void(
		(in ParseDiag.Expected x) {
			writer ~= showParseDiagExpected(x.kind);
		},
		(in ParseDiag.FunctionTypeMissingParens) {
			writer ~= "Function type is missing parentheses.";
		},
		(in ParseDiag.ImportFileTypeNotSupported) {
			writer ~= "Import file type not allowed; the only supported types are 'nat8 array' and 'string'.";
		},
		(in ParseDiag.IndentNotDivisible d) {
			writer ~= "Expected indentation by ";
			writer ~= d.nSpacesPerIndent;
			writer ~= " spaces per level, but got ";
			writer ~= d.nSpaces;
			writer ~= " which is not divisible.";
		},
		(in ParseDiag.IndentTooMuch x) {
			writer ~= "Indented too far.";
		},
		(in ParseDiag.IndentWrongCharacter d) {
			writer ~= "Expected indentation by ";
			writer ~= d.expectedTabs ? "tabs" : "spaces";
			writer ~= " (based on first indented line), but here there is a ";
			writer ~= d.expectedTabs ? "space" : "tab.";
		},
		(in ParseDiag.InvalidName x) {
			writeQuotedString(writer, x.actual);
			writer ~= " is not a valid name.";
		},
		(in ParseDiag.InvalidStringEscape x) {
			writer ~= "Invalid escape character '";
			writeEscapedChar(writer, x.actual);
			writer ~= "'.";
		},
		(in ParseDiag.MissingExpression x) {
			writer ~= "Expected an expression here.";
		},
		(in ParseDiag.NeedsBlockCtx x) {
			if (x.kind == ParseDiag.NeedsBlockCtx.Kind.lambda)
				writer ~= "Lambda";
			else {
				writer ~= '\'';
				writer ~= stringOfEnum(x.kind);
				writer ~= '\'';
			}
			writer ~= " expression must appear ";
			writer ~= x.kind == ParseDiag.NeedsBlockCtx.Kind.break_
				? "on its own line."
				: "in a context where it can be followed by an indented block.";
		},
		(in ReadFileDiag x) {
			showReadFileDiag(writer, ctx, x, none!Uri);
		},
		(in ParseDiag.TrailingComma) {
			writer ~= "Remove this trailing comma.";
		},
		(in ParseDiag.UnexpectedCharacter x) {
			writer ~= "Unexpected character '";
			showChar(writer, x.character);
			writer ~= "'.";
		},
		(in ParseDiag.UnexpectedOperator x) {
			writer ~= "Unexpected '";
			writeSymbol(writer, ctx.allSymbols, x.operator);
			writer ~= "'.";
		},
		(in ParseDiag.UnexpectedToken u) {
			writer ~= describeTokenForUnexpected(u.token);
		});
}

string showParseDiagExpected(ParseDiag.Expected.Kind kind) {
	final switch (kind) {
		case ParseDiag.Expected.Kind.afterMut:
			return "Expected '[' or '*' after 'mut'.";
		case ParseDiag.Expected.Kind.blockCommentEnd:
			return "Expected '###' (then a newline).";
		case ParseDiag.Expected.Kind.closeInterpolated:
			return "Expected '}'.";
		case ParseDiag.Expected.Kind.closingBracket:
			return "Expected ']'.";
		case ParseDiag.Expected.Kind.closingParen:
			return "Expected ')'.";
		case ParseDiag.Expected.Kind.colon:
			return "Expected ':'.";
		case ParseDiag.Expected.Kind.comma:
			return "Expected ','.";
		case ParseDiag.Expected.Kind.dedent:
			return "Expected a dedent.";
		case ParseDiag.Expected.Kind.endOfLine:
			return "Expected end of line.";
		case ParseDiag.Expected.Kind.equals:
			return "Expected '='.";
		case ParseDiag.Expected.Kind.indent:
			return "Expected an indent.";
		case ParseDiag.Expected.Kind.lambdaArrow:
			return "Expected ' =>' after lambda parameters.";
		case ParseDiag.Expected.Kind.less:
			return "Expected '<'.";
		case ParseDiag.Expected.Kind.literalIntOrNat:
			return "Expected an integer.";
		case ParseDiag.Expected.Kind.literalNat:
			return "Expected a natural number.";
		case ParseDiag.Expected.Kind.modifier:
			return "Expected a valid modifier.";
		case ParseDiag.Expected.Kind.name:
			return "Expected a name (non-operator).";
		case ParseDiag.Expected.Kind.namedArgument:
			return "Expected another named argument.";
		case ParseDiag.Expected.Kind.nameOrOperator:
			return "Expected a name or operator.";
		case ParseDiag.Expected.Kind.newline:
			return "Expected a newline.";
		case ParseDiag.Expected.Kind.newlineOrDedent:
			return "Expected a newline or dedent.";
		case ParseDiag.Expected.Kind.openParen:
			return "Expected '('.";
		case ParseDiag.Expected.Kind.then:
			return "Expected '<-'.";
		case ParseDiag.Expected.Kind.questionEqual:
			return "Expected '?='.";
		case ParseDiag.Expected.Kind.quoteDouble:
			return "Expected '\"'.";
		case ParseDiag.Expected.Kind.quoteDouble3:
			return "Expected '\"\"\"'.";
		case ParseDiag.Expected.Kind.slash:
			return "Expected '/'.";
		case ParseDiag.Expected.Kind.typeArgsEnd:
			return "Expected '>'.";
	}
}

void showReadFileDiag(scope ref Writer writer, in ShowCtx ctx, ReadFileDiag a, Opt!Uri uri) {
	final switch (a) {
		case ReadFileDiag.notFound:
			if (has(uri)) {
				writer ~= "Imported file ";
				writeUri(writer, ctx, force(uri));
				writer ~= " does not exist.";
			} else
				writer ~= "This file does not exist.";
			break;
		case ReadFileDiag.error:
			if (has(uri)) {
				writer ~= "There was an error reading imported file ";
				writeUri(writer, ctx, force(uri));
				writer ~= '.';
			} else
				writer ~= "There was an error reading this file.";
			break;
		case ReadFileDiag.loading:
			if (has(uri)) {
				writer ~= "IDE is still loading imported file ";
				writeUri(writer, ctx, force(uri));
				writer ~= '.';
			} else
				writer ~= "The editor is still loading this file.";
			break;
		case ReadFileDiag.unknown:
			assert(false);
	}
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
	in ShowDiagCtx ctx,
	in TypeContainer outermostTypeContainer,
	in FunDeclAndTypeArgs[] trace,
) {
	foreach (size_t i, FunDeclAndTypeArgs x; trace) {
		writer ~= "\n\t";
		TypeContainer typeContainer = i == 0 ? outermostTypeContainer : TypeContainer(trace[i - 1].decl);
		writeFunDeclAndTypeArgs(writer, ctx, typeContainer, x);
	}
}

void writeCallNoMatch(scope ref Writer writer, in ShowDiagCtx ctx, in Diag.CallNoMatch d) {
	bool someCandidateHasCorrectNTypeArgs =
		d.actualNTypeArgs == 0 ||
		exists!CalledDecl(d.allCandidates, (in CalledDecl c) =>
			nTypeParams(c) == 1 || nTypeParams(c) == d.actualNTypeArgs);
	bool someCandidateHasCorrectArity =
		exists!CalledDecl(d.allCandidates, (in CalledDecl c) =>
			(d.actualNTypeArgs == 0 || nTypeParams(c) == d.actualNTypeArgs) &&
			arityMatches(c.arity, d.actualArity));

	if (isEmpty(d.allCandidates)) {
		writer ~= "There is no function ";
		if (d.actualArity == 0)
			// If there is no local variable by that name we try a call,
			// but message should reflect that the user might not have wanted a call.
			writer ~= "or variable ";
		writer ~= "named ";
		writeName(writer, ctx, d.funName);
		writer ~= '.';

		if (d.actualArgTypes.length == 1) {
			writer ~= "\nArgument type: ";
			writeTypeQuoted(writer, ctx, TypeWithContainer(only(d.actualArgTypes), d.typeContainer));
		}
	} else if (!someCandidateHasCorrectArity) {
		writer ~= "There are functions named ";
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
		writer ~= "There are functions named ";
		writeName(writer, ctx, d.funName);
		writer ~= ", but they do not match the ";
		bool hasRet = d.expectedReturnType.isA!(ExpectedForDiag.Choices);
		bool hasArgs = isEmpty(d.actualArgTypes);
		string descr = hasRet
			? hasArgs ? "expected return type and actual argument types" : "expected return type"
			: "actual argument types";
		writer ~= descr;
		writer ~= '.';
		writeNewline(writer, 0);
		if (hasRet)
			writeExpected(writer, ctx, d.expectedReturnType, ExpectedKind.return_);
		if (hasArgs) {
			writer ~= "\nActual argument types: ";
			writeWithCommas!Type(writer, d.actualArgTypes, (in Type t) {
				writeTypeQuoted(writer, ctx, TypeWithContainer(t, d.typeContainer));
			});
			if (d.actualArgTypes.length < d.actualArity)
				writer ~= " (Other arguments not checked; gave up early.)";
		}
		writer ~= "\nCandidates (with ";
		writer ~= d.actualArity;
		writer ~= " arguments):";
		writeCalledDecls(writer, ctx, d.typeContainer, d.allCandidates, (in CalledDecl c) =>
			arityMatches(c.arity, d.actualArity));
	}
}

void writeDiag(scope ref Writer writer, in ShowDiagCtx ctx, in Diag diag) {
	diag.matchIn!void(
		(in Diag.AssignmentNotAllowed) {
			writer ~= "Can't assign to this kind of expression.";
		},
		(in Diag.BuiltinUnsupported x) {
			writer ~= "The compiler does not implement a builtin named ";
			writeName(writer, ctx, x.name);
			writer ~= '.';
		},
		(in Diag.CallMultipleMatches x) {
			writer ~= "Cannot choose an overload of ";
			writeName(writer, ctx, x.funName);
			writer ~= ". Multiple functions match:";
			writeCalledDecls(writer, ctx, x.typeContainer, x.matches);
		},
		(in Diag.CallNoMatch x) {
			writeCallNoMatch(writer, ctx, x);
		},
		(in Diag.CallShouldUseSyntax x) {
			writer ~= () {
				final switch (x.kind) {
					case Diag.CallShouldUseSyntax.Kind.for_break:
						return "Prefer to write a 'for' loop instead of calling 'for-break'.";
					case Diag.CallShouldUseSyntax.Kind.force:
						return "Prefer to write 'x!' instead of 'x.force'.";
					case Diag.CallShouldUseSyntax.Kind.for_loop:
						return "Prefer to write a 'for' loop instead of calling 'for-loop'.";
					case Diag.CallShouldUseSyntax.Kind.new_:
						switch (x.arity) {
							case 0:
								return "Prefer to write '()' instead of 'new'.";
							case 1:
								return "Prefer to write '(x,)' instead of 'x.new'.";
							default:
								return "Prefer to write 'x, y' instead of 'x new y'.";
						}
					case Diag.CallShouldUseSyntax.Kind.not:
						return "Prefer to write '!x' instead of 'x.not'";
					case Diag.CallShouldUseSyntax.Kind.set_subscript:
						return "Prefer to write 'x[i] := y' instead of 'x set-subscript i, y'.";
					case Diag.CallShouldUseSyntax.Kind.subscript:
						return "Prefer to write 'x[i]' instead of 'x subscript i'.";
					case Diag.CallShouldUseSyntax.Kind.with_block:
						return "Prefer to write a 'with' block instead of calling 'with-block'.";
				}
			}();
		},
		(in Diag.CantCall x) {
			writer ~= () {
				final switch (x.reason) {
					case Diag.CantCall.Reason.nonBare:
						return "A 'bare' function can't call non-'bare' function";
					case Diag.CantCall.Reason.summon:
						return "A non-'summon' function can't call 'summon' function";
					case Diag.CantCall.Reason.unsafe:
						return "A non-'unsafe' function can't call 'unsafe' function";
					case Diag.CantCall.Reason.variadicFromBare:
						return "A 'bare' function can't call variadic function";
				}
			}();
			writer ~= ' ';
			writeFunDecl(writer, ctx, x.callee);
			writer ~= '.';
			if (x.reason == Diag.CantCall.Reason.unsafe)
				writer ~= "\n(Consider putting the call in a 'trusted' expression.)";
		},
		(in Diag.CharLiteralMustBeOneChar) {
			writer ~= "Value of 'char' type must be a single character";
		},
		(in Diag.CommonFunDuplicate x) {
			writer ~= "Module contains multiple valid ";
			writeName(writer, ctx, x.name);
			writer ~= " functions.";
		},
		(in Diag.CommonFunMissing x) {
			writer ~= "Module should have a function:\n\t";
			writeWithSeparator!TypeParamsAndSig(writer, x.sigChoices, "\nOr:\n\t", (in TypeParamsAndSig sig) {
				writeSigSimple(writer, ctx, TypeContainer(x.dummyForContext), x.dummyForContext.name, sig);
			});
		},
		(in Diag.CommonTypeMissing x) {
			writer ~= "Expected to find a type named ";
			writeName(writer, ctx, x.name);
			writer ~= " in this module.";
		},
		(in Diag.DestructureTypeMismatch x) {
			x.expected.matchIn!void(
				(in Diag.DestructureTypeMismatch.Expected.Tuple t) {
					writer ~= "Expected a tuple with ";
					writer ~= t.size;
					writer ~= " elements, but got ";
				},
				(in TypeWithContainer t) {
					writer ~= "Expected type ";
					writeTypeQuoted(writer, ctx, t);
					writer ~= ", but got ";
				});
			writeTypeQuoted(writer, ctx, x.actual);
			writer ~= '.';
		},
		(in Diag.DuplicateDeclaration x) {
			writer ~= () {
				final switch (x.kind) {
					case Diag.DuplicateDeclaration.Kind.enumMember:
						return "Enum member";
					case Diag.DuplicateDeclaration.Kind.flagsMember:
						return "Flags member";
					case Diag.DuplicateDeclaration.Kind.paramOrLocal:
						return "Local";
					case Diag.DuplicateDeclaration.Kind.recordField:
						return "Record field";
					case Diag.DuplicateDeclaration.Kind.spec:
						return "Spec";
					case Diag.DuplicateDeclaration.Kind.structOrAlias:
						return "Type";
					case Diag.DuplicateDeclaration.Kind.typeParam:
						return "Type parameter";
					case Diag.DuplicateDeclaration.Kind.unionMember:
						return "Union member";
				}
			}();
			writer ~= " name ";
			writeName(writer, ctx, x.name);
			writer ~= " is already used.";
		},
		(in Diag.DuplicateExports x) {
			writer ~= "There are multiple exported ";
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
			writer ~= '.';
		},
		(in Diag.DuplicateImports x) {
			//TODO: use x.kind
			writer ~= "The symbol ";
			writeName(writer, ctx, x.name);
			writer ~= " appears in multiple modules.";
		},
		(in Diag.EnumBackingTypeInvalid x) {
			writer ~= "Type ";
			writeTypeQuoted(writer, ctx, TypeWithContainer(x.actual, TypeContainer(x.enum_)));
			writer ~= " cannot be used to back an enum.";
		},
		(in Diag.EnumDuplicateValue x) {
			writer ~= "Duplicate enum value ";
			if (x.signed)
				writer ~= x.value;
			else
				writer ~= cast(ulong) x.value;
			writer ~= '.';
		},
		(in Diag.EnumMemberOverflows x) {
			writer ~= "Enum member is not in the allowed range from ";
			writer ~= minValue(x.backingType);
			writer ~= " to ";
			writer ~= maxValue(x.backingType);
			writer ~= '.';
		},
		(in Diag.ExpectedTypeIsNotALambda x) {
			if (has(x.expectedType)) {
				writer ~= "The expected type at the lambda is ";
				writeTypeQuoted(writer, ctx, force(x.expectedType));
				writer ~= ", which is not a lambda type.";
			} else
				writer ~= "There is no expected type at this location; lambdas need an expected type.";
		},
		(in Diag.ExternFunForbidden x) {
			writer ~= "'extern' function ";
			writeName(writer, ctx, x.fun.name);
			writer ~= () {
				final switch (x.reason) {
					case Diag.ExternFunForbidden.Reason.hasSpecs:
						return " can't have specs.";
					case Diag.ExternFunForbidden.Reason.hasTypeParams:
						return " can't have type parameters.";
					case Diag.ExternFunForbidden.Reason.variadic:
						return " can't be variadic.";
				}
			}();
		},
		(in Diag.ExternHasTypeParams) {
			writer ~= "An 'extern' type should not be a template.";
		},
		(in Diag.ExternMissingLibraryName) {
			writer ~= "Expected 'extern' to be preceded by the library name.";
		},
		(in Diag.ExternRecordImplicitlyByVal x) {
			writer ~= "'extern' record ";
			writeName(writer, ctx, x.struct_.name);
			writer ~= " is implicitly 'by-val'.";
		},
		(in Diag.ExternUnion) {
			writer ~= "A union can't be 'extern'.";
		},
		(in Diag.FunMissingBody) {
			writer ~= "This function needs a body.";
		},
		(in Diag.FunModifierTrustedOnNonExtern) {
			writer ~= "Only 'extern' functions can be 'trusted'; otherwise 'trusted' should be used as an expression.";
		},
		(in Diag.IfNeedsOpt x) {
			writer ~= "Expected an option type, but got ";
			writeTypeQuoted(writer, ctx, x.actualType);
			writer ~= '.';
		},
		(in Diag.ImportFileDiag x) {
			x.matchIn!void(
				(in Diag.ImportFileDiag.CantImportCrowAsText y) {
					writer ~= "Can't import a '.crow' file as content.";
				},
				(in Diag.ImportFileDiag.CircularImport y) {
					writer ~= "This is part of a circular import:";
					foreach (Uri uri; y.cycle) {
						writeNewline(writer, 1);
						writeUri(writer, ctx, uri);
						writer ~= " imports";
					}
					writeNewline(writer, 1);
					writeUri(writer, ctx, y.cycle[0]);
				},
				(in Diag.ImportFileDiag.LibraryNotConfigured x) {
					writer ~= "Library ";
					writeName(writer, ctx, x.libraryName);
					writer ~= " is not configured.";
					writeNewline(writer, 0);
					writer ~= "It must be added to \"include\" in 'crow-config.json'.";
				},
				(in Diag.ImportFileDiag.ReadError y) {
					showReadFileDiag(writer, ctx, y.diag, some(y.uri));
				},
				(in Diag.ImportFileDiag.RelativeImportReachesPastRoot y) {
					writer ~= "Relative path ";
					writeRelPath(writer, ctx.allUris, y.imported);
					writer ~= " reaches above the root directory.";
				});
		},
		(in Diag.ImportRefersToNothing x) {
			writer ~= "Imported name ";
			writeName(writer, ctx, x.name);
			writer ~= " does not refer to anything.";
		},
		(in Diag.LambdaCantBeFunctionPointer x) {
			writer ~= "A function pointer can't be implemented by a lambda. Write a function and use '&f' instead.";
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
				writer ~= '.';
			} else
				writer ~= " which is 'mut'.";
			writer ~= " (Should it be an 'act' or 'ref' fun?)";
		},
		(in Diag.LambdaMultipleMatch x) {
			writer ~= "Multiple lambda types are possible.\n";
			writeExpected(writer, ctx, x.expected, ExpectedKind.lambda);
			writeNewline(writer, 0);
			writer ~= "Consider explicitly typing the lambda's parameter.";
		},
		(in Diag.LambdaNotExpected x) {
			if (x.expected.isA!(ExpectedForDiag.Infer))
				writer ~= "Lambda expression needs an expected type.";
			else {
				writer ~= "The lambda doesn't match the expected type at this location.\n";
				writeExpected(writer, ctx, x.expected, ExpectedKind.lambda);
			}
		},
		(in Diag.LinkageWorseThanContainingFun x) {
			writer ~= "'extern' function ";
			writeName(writer, ctx, x.containingFun.name);
			if (has(x.param)) {
				Opt!Symbol paramName = force(x.param).name;
				if (has(paramName)) {
					writer ~= " parameter ";
					writeName(writer, ctx, force(paramName));
				}
			}
			writer ~= " can't reference non-extern type ";
			writeTypeQuoted(writer, ctx, TypeWithContainer(x.referencedType, TypeContainer(x.containingFun)));
			writer ~= '.';
		},
		(in Diag.LinkageWorseThanContainingType x) {
			writer ~= "Extern type ";
			writeName(writer, ctx, x.containingType.name);
			writer ~= " can't reference non-extern type ";
			writeTypeQuoted(writer, ctx, TypeWithContainer(x.referencedType, TypeContainer(x.containingType)));
			writer ~= '.';
		},
		(in Diag.LiteralAmbiguous x) {
			writer ~= "Multiple possible types for literal expression: ";
			writeWithCommas!(StructInst*)(writer, x.types, (in StructInst* type) {
				writeStructInst(writer, ctx, x.typeContainer, *type);
			});
		},
		(in Diag.LiteralOverflow x) {
			writer ~= "Literal exceeds the range of a ";
			writeTypeQuoted(writer, ctx, x.type);
			writer ~= '.';
		},
		(in Diag.LocalIgnoredButMutable) {
			writer ~= "Unnecessary 'mut' on ignored local variable.";
		},
		(in Diag.LocalNotMutable x) {
			writer ~= "Local variable ";
			writeName(writer, ctx, x.local.name);
			writer ~= " was not marked 'mut'.";
		},
		(in Diag.LoopWithoutBreak) {
			writer ~= "'loop' has no 'break'.";
		},
		(in Diag.MatchCaseNamesDoNotMatch x) {
			writer ~= "Expected the case names to be: ";
			writeWithCommas!Symbol(writer, x.expectedNames, (in Symbol name) {
				writeName(writer, ctx, name);
			});
		},
		(in Diag.MatchOnNonUnion x) {
			writer ~= "Can't match on non-'enum', non-'union' type ";
			writeTypeQuoted(writer, ctx, x.type);
			writer ~= '.';
		},
		(in Diag.ModifierConflict x) {
			writeName(writer, ctx, x.curModifier);
			writer ~= " conflicts with ";
			writeName(writer, ctx, x.prevModifier);
			writer ~= '.';
		},
		(in Diag.ModifierDuplicate x) {
			writer ~= "Redundant ";
			writeName(writer, ctx, x.modifier);
			writer ~= '.';
		},
		(in Diag.ModifierInvalid x) {
			writeName(writer, ctx, x.modifier);
			writer ~= " is not supported for ";
			writer ~= aOrAnTypeKind(x.typeKind);
			writer ~= '.';
		},
		(in Diag.ModifierRedundantDueToModifier x) {
			writeName(writer, ctx, x.redundantModifier);
			writer ~= " is redundant given ";
			writeName(writer, ctx, x.modifier);
			writer ~= '.';
		},
		(in Diag.ModifierRedundantDueToTypeKind x) {
			writeName(writer, ctx, x.modifier);
			writer ~= " is already the default for ";
			writer ~= aOrAnTypeKind(x.typeKind);
			writer ~= " type.";
		},
		(in Diag.MutFieldNotAllowed) {
			writer ~= "This field is 'mut', so the record must be 'mut'.";
		},
		(in Diag.NameNotFound x) {
			writer ~= "There is no ";
			writer ~= stringOfEnum(x.kind);
			writer ~= " in scope named ";
			writeName(writer, ctx, x.name);
			writer ~= '.';
		},
		(in Diag.NeedsExpectedType x) {
			writer ~= '\'';
			writer ~= stringOfEnum(x.kind);
			writer ~= "' expression needs an expected type.";
		},
		(in Diag.ParamMissingType) {
			writer ~= "This parameter needs a type.";
		},
		(in ParseDiag x) {
			writeParseDiag(writer, ctx, x);
		},
		(in Diag.PointerIsUnsafe) {
			writer ~= "Getting a pointer can only be done in an 'unsafe' function or 'trusted' expression.";
		},
		(in Diag.PointerMutToConst x) {
			writer ~= () {
				final switch (x.kind) {
					case Diag.PointerMutToConst.Kind.field:
						return "Can't get a mutable pointer to a non-'mut' field.";
					case Diag.PointerMutToConst.Kind.local:
						return "Can't get a mutable pointer to a non-'mut' local.";
				}
			}();
		},
		(in Diag.PointerUnsupported) {
			writer ~= "Can't get a pointer to this kind of expression.";
		},
		(in Diag.PurityWorseThanParent x) {
			writer ~= "Type ";
			writeName(writer, ctx, x.parent.name);
			writer ~= " has purity ";
			writePurity(writer, ctx, x.parent.purity);
			writer ~= ", but member of type ";
			writeTypeQuoted(writer, ctx, TypeWithContainer(x.child, TypeContainer(x.parent)));
			writer ~= " has purity ";
			writePurity(writer, ctx, bestCasePurity(x.child));
			writer ~= '.';
		},
		(in Diag.SpecMatchError x) {
			x.reason.matchIn!void(
				(in Diag.SpecMatchError.Reason.MultipleMatches y) {
					writer ~= "Multiple implementations found for spec signature ";
					writeName(writer, ctx, y.sigName);
					writer ~= ':';
					writeCalleds(writer, ctx, x.outermostTypeContainer, y.matches);
				});
			writeNewline(writer, 1);
			writer ~= "Calling:";
			writeSpecTrace(writer, ctx, x.outermostTypeContainer, x.trace);
		},
		(in Diag.SpecNoMatch x) {
			x.reason.matchIn!void(
				(in Diag.SpecNoMatch.Reason.BuiltinNotSatisfied y) {
					writeTypeQuoted(writer, ctx, TypeWithContainer(y.type, x.outermostTypeContainer));
					writer ~= " is not '";
					writer ~= stringOfSpecBodyBuiltinKind(y.kind);
					writer ~= "'.";
				},
				(in Diag.SpecNoMatch.Reason.CantInferTypeArguments y) {
					writer ~= "Can't infer type arguments to ";
					writeFunDecl(writer, ctx, y.fun);
				},
				(in Diag.SpecNoMatch.Reason.SpecImplNotFound y) {
					writer ~= "No implementation was found for spec signature ";
					SpecDeclSig* sig = y.sigDecl;
					writeSig(
						writer, ctx, x.outermostTypeContainer, sig.name, sig.returnType,
						Params(sig.params), some(y.sigType));
					writer ~= '.';
				},
				(in Diag.SpecNoMatch.Reason.TooDeep _) {
					writer ~= "Spec instantiation is too deep.";
				});
			if (!isEmpty(x.trace)) {
				writeNewline(writer, 1);
				writer ~= "Calling:";
				writeSpecTrace(writer, ctx, x.outermostTypeContainer, x.trace);
			}
		},
		(in Diag.SpecNameMissing) {
			writer ~= "Spec name is missing.";
		},
		(in Diag.SpecRecursion x) {
			writer ~= "Spec's parents tree is too deep.";
			writeNewline(writer, 1);
			writer ~= "Trace: ";
			writeWithCommas!(immutable SpecDecl*)(writer, x.trace, (in SpecDecl* spec) {
				writeName(writer, ctx, spec.name);
			});
		},
		(in Diag.StringLiteralInvalid x) {
			final switch (x.reason) {
				case Diag.StringLiteralInvalid.Reason.containsNul:
					writer ~= "String literal can't contain '\\0'";
			}
		},
		(in Diag.TrustedUnnecessary x) {
			writer ~= () {
				final switch (x.reason) {
					case Diag.TrustedUnnecessary.Reason.inTrusted:
						return "'trusted' expression is redundant inside another 'trusted' expression.";
					case Diag.TrustedUnnecessary.Reason.inUnsafeFunction:
						return "'trusted' expression is redundant inside an 'unsafe' function.";
					case Diag.TrustedUnnecessary.Reason.unused:
						return "There is no unsafe code in this expression; you could remove 'trusted'.";
				}
			}();
		},
		(in Diag.TypeAnnotationUnnecessary x) {
			writer ~= "Type annotation is unnecessary; type ";
			writeTypeQuoted(writer, ctx, x.type);
			writer ~= " was already inferred.";
		},
		(in Diag.TypeConflict x) {
			writeExpected(writer, ctx, x.expected, ExpectedKind.generic);
			writeNewline(writer, 0);
			writer ~= "Actual: ";
			writeTypeQuoted(writer, ctx, x.actual);
			writer ~= '.';
		},
		(in Diag.TypeParamCantHaveTypeArgs) {
			writer ~= "Can't provide type arguments to a type parameter.";
		},
		(in Diag.TypeShouldUseSyntax x) {
			writer ~= () {
				final switch (x.kind) {
					case Diag.TypeShouldUseSyntax.Kind.funAct:
						return "Prefer to write 'act r(p)' instead of '(r, p) fun-act'.";
					case Diag.TypeShouldUseSyntax.Kind.funFar:
						return "Prefer to write 'far r(p)' instead of '(r, p) fun-far'.";
					case Diag.TypeShouldUseSyntax.Kind.funFun:
						return "Prefer to write 'fun r(p)' instead of '(r, p) fun-fun'.";
					case Diag.TypeShouldUseSyntax.Kind.future:
						return "Prefer to write 't^' instead of 't future'.";
					case Diag.TypeShouldUseSyntax.Kind.list:
						return "Prefer to write 't[]' instead of 't list'.";
					case Diag.TypeShouldUseSyntax.Kind.map:
						return "Prefer to write 'v[k]' instead of '(k, v) map'.";
					case Diag.TypeShouldUseSyntax.Kind.mutMap:
						return "Prefer to write 'v mut[k]' instead of '(k, v) mut-map'.";
					case Diag.TypeShouldUseSyntax.Kind.mutList:
						return "Prefer to write 't mut[]' instead of 't mut-list'.";
					case Diag.TypeShouldUseSyntax.Kind.mutPointer:
						return "Prefer to write 't mut*' instead of 't mut-pointer'.";
					case Diag.TypeShouldUseSyntax.Kind.opt:
						return "Prefer to write 't?' instead of 't option'.";
					case Diag.TypeShouldUseSyntax.Kind.pointer:
						return "Prefer to write 't*' instead of 't const-pointer'.";
					case Diag.TypeShouldUseSyntax.Kind.tuple:
						return "Prefer to write '(t, u)' instead of '(t, u) tuple2'.";
				}
			}();
		},
		(in Diag.Unused x) {
			writeUnusedDiag(writer, ctx, x);
		},
		(in Diag.VarargsParamMustBeArray) {
			writer ~= "Variadic parameter must be an 'array'.";
		},
		(in Diag.VarDeclTypeParams x) {
			writer ~= "A ";
			writer ~= stringOfVarKindLowerCase(x.kind);
			writer ~= " variable can't have type parameters.";
		},
		(in Diag.VisibilityIsRedundant x) {
			final switch (x.kind) {
				case Diag.VisibilityIsRedundant.Kind.field:
					writer ~= "Fields of record ";
					writeName(writer, ctx, x.record.name);
					writer ~= " are already ";
					writer ~= stringOfVisibility(x.visibility);
					writer ~= " by default.";
					break;
				case Diag.VisibilityIsRedundant.Kind.new_:
					writer ~= "The 'new' function for ";
					writeName(writer, ctx, x.record.name);
					writer ~= " is already ";
					writer ~= stringOfVisibility(x.visibility);
					writer ~= " by default (derived from visibility of fields).";
					break;
			}
		},
		(in Diag.WrongNumberTypeArgs x) {
			writeName(writer, ctx, x.name);
			writer ~= " expected to get ";
			writer ~= x.nExpectedTypeArgs;
			writer ~= " type arguments, but got ";
			writer ~= x.nActualTypeArgs;
			writer ~= '.';
		});
}

void showDiagnostic(scope ref Writer writer, in ShowDiagCtx ctx, in UriAndDiagnostic a) {
	writeUriAndRange(writer, ctx, a.where);
	writer ~= ' ';
	writeDiag(writer, ctx, a.kind);
}

enum ExpectedKind {
	generic,
	lambda,
	return_,
}

void writeExpected(scope ref Writer writer, in ShowDiagCtx ctx, in ExpectedForDiag a, ExpectedKind kind) {
	void writeType() {
		if (kind == ExpectedKind.return_) writer ~= "return ";
		writer ~= "type";
	}
	a.matchIn!void(
		(in ExpectedForDiag.Choices choices) {
			if (choices.types.length == 1) {
				writer ~= "Expected ";
				writeType();
				writer ~= ' ';
				writeTypeQuoted(writer, ctx, TypeWithContainer(only(choices.types), choices.typeContainer));
				writer ~= '.';
			} else {
				writer ~= "Expected one of these ";
				writeType();
				writer ~= "s:";
				foreach (Type t; choices.types) {
					writeNewline(writer, 1);
					writeTypeQuoted(writer, ctx, TypeWithContainer(t, choices.typeContainer));
				}
			}
		},
		(in ExpectedForDiag.Infer) {
			writer ~= "This location has no expected ";
			writeType();
			writer ~= '.';
		},
		(in ExpectedForDiag.Loop) {
			writer ~= "Expected a loop 'break' or 'continue'.";
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
			return "Unexpected keyword 'act'.";
		case Token.alias_:
			return "Unexpected keyword 'alias'.";
		case Token.arrowAccess:
			return "Unexpected '->'.";
		case Token.arrowLambda:
			return "Unexpected '=>'.";
		case Token.arrowThen:
			return "Unexpected '<-'.";
		case Token.as:
			return "Unexpected keyword 'as'.";
		case Token.assert_:
			return "Unexpected keyword 'assert'.";
		case Token.at:
			return "Unexpected '@'.";
		case Token.bang:
			return "Unexpected '!'.";
		case Token.bare:
			return "Unexpected keyword 'bare'.";
		case Token.break_:
			return "Unexpected keyword 'break'.";
		case Token.builtin:
			return "Unexpected keyword 'builtin'.";
		case Token.builtinSpec:
			return "Unexpected keyword 'builtin-spec'.";
		case Token.braceLeft:
			return "Unexpected '{'.";
		case Token.braceRight:
			return "Unexpected '}'.";
		case Token.bracketLeft:
			return "Unexpected '['.";
		case Token.bracketRight:
			return "Unexpected ']'.";
		case Token.colon:
			return "Unexpected ':'.";
		case Token.colon2:
			return "Unexpected '::'.";
		case Token.colonEqual:
			return "Unexpected ':='.";
		case Token.comma:
			return "Unexpected ','.";
		case Token.continue_:
			return "Unexpected keyword 'continue'.";
		case Token.do_:
			return "Unexpected keyword 'do'.";
		case Token.dot:
			return "Unexpected '.'.";
		case Token.dot3:
			return "Unexpected '...'.";
		case Token.elif:
			return "Unexpected keyword 'elif'.";
		case Token.else_:
			return "Unexpected keyword 'else'.";
		case Token.enum_:
			return "Unexpected keyword 'enum'.";
		case Token.export_:
			return "Unexpected keyword 'export'.";
		case Token.equal:
			return "Unexpected '='.";
		case Token.extern_:
			return "Unexpected keyword 'extern'.";
		case Token.EOF:
			return "Unexpected end of file.";
		case Token.far:
			return "Unexpected keyword 'far'.";
		case Token.flags:
			return "Unexpected keyword 'flags'.";
		case Token.for_:
			return "Unexpected keyword 'for'.";
		case Token.forbid:
			return "Unexpected keyword 'forbid'.";
		case Token.forceCtx:
			return "Unexpected keyword 'force-ctx'.";
		case Token.fun:
			return "Unexpected keyword 'fun'.";
		case Token.global:
			return "Unexpected keyword 'global'.";
		case Token.if_:
			return "Unexpected keyword 'if'.";
		case Token.import_:
			return "Unexpected keyword 'import'.";
		case Token.unexpectedCharacter:
			// This is UnexpectedCharacter instead
			assert(false);
		case Token.literalFloat:
		case Token.literalInt:
		case Token.literalNat:
			return "Unexpected number literal expression.";
		case Token.loop:
			return "Unexpected keyword 'loop'.";
		case Token.match:
			return "Unexpected keyword 'match'.";
		case Token.mut:
			return "Unexpected keyword 'mut'.";
		case Token.name:
			return "Did not expect a name here.";
		case Token.nameOrOperatorColonEquals:
			return "Did not expect a 'name:=' here.";
		case Token.nameOrOperatorEquals:
			return "Did not expect a 'name=' here.";
		case Token.newlineDedent:
		case Token.newlineIndent:
		case Token.newlineSameIndent:
			return "Unexpected newline.";
		case Token.noStd:
			return "Unexpected keyword 'no-std'.";
		case Token.operator:
			// This is UnexpectedOperator instead
			assert(false);
		case Token.parenLeft:
			return "Unexpected '('.";
		case Token.parenRight:
			return "Unexpected ')'.";
		case Token.question:
			return "Unexpected '?'.";
		case Token.questionEqual:
			return "Unexpected '?='.";
		case Token.quoteDouble:
			return "Unexpected '\"'.";
		case Token.quoteDouble3:
			return "Unexpected '\"\"\"'.";
		case Token.quotedText:
			assert(false);
		case Token.record:
			return "Unexpected keyword 'record'.";
		case Token.reserved:
			return "Unexpected reserved keyword.";
		case Token.semicolon:
			return "Unexpected ';'.";
		case Token.spec:
			return "Unexpected keyword 'spec'.";
		case Token.summon:
			return "Unexpected keyword 'summon'.";
		case Token.test:
			return "Unexpected keyword 'test'.";
		case Token.thread_local:
			return "Unexpected keyword 'thread-local'.";
		case Token.throw_:
			return "Unexpected keyword 'throw'.";
		case Token.trusted:
			return "Unexpected keyword 'trusted'.";
		case Token.underscore:
			return "Unexpected '_'.";
		case Token.union_:
			return "Unexpected keyword 'union'.";
		case Token.unless:
			return "Unexpected keyword 'unless'.";
		case Token.unsafe:
			return "Unexpected keyword 'unsafe'.";
		case Token.until:
			return "Unexpected keyword 'until'.";
		case Token.while_:
			return "Unexpected keyword 'while'.";
		case Token.with_:
			return "Unexpected keyword 'with'.";
	}
}
