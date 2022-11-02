module frontend.showDiag;

@safe @nogc pure nothrow:

import frontend.lang : crowExtension;
import frontend.parse.lexer : Token;
import model.diag : Diagnostic, Diag, Diagnostics, FilesInfo, matchDiag, TypeKind, writeFileAndRange;
import model.model :
	arity,
	arityMatches,
	bestCasePurity,
	CalledDecl,
	decl,
	EnumBackingType,
	FunDecl,
	matchCalledDecl,
	matchParams,
	name,
	nTypeParams,
	Param,
	Params,
	Purity,
	range,
	SpecBody,
	SpecSig,
	symOfPurity,
	symOfVisibility,
	Type,
	writeStructInst,
	writeTypeQuoted,
	writeTypeUnquoted;
import model.parseDiag : matchParseDiag, ParseDiag;
import util.alloc.alloc : Alloc, TempAlloc;
import util.col.arr : empty, only;
import util.col.arrUtil : exists;
import util.col.str : SafeCStr;
import util.lineAndColumnGetter : lineAndColumnAtPos;
import util.opt : force, has, Opt;
import util.path : AllPaths, baseName, Path, PathsInfo, writePath, writeRelPath;
import util.ptr : ptrTrustMe_mut;
import util.sourceRange : FileAndPos;
import util.sym : AllSymbols, strOfOperator, Sym, writeSym;
import util.util : unreachable;
import util.writer :
	finishWriter,
	finishWriterToSafeCStr,
	writeBold,
	writeEscapedChar,
	writeQuotedStr,
	writeReset,
	writeWithCommas,
	writeWithNewlines,
	Writer;
import util.writerUtils : showChar, writeName, writeNl;

struct ShowDiagOptions {
	immutable bool color;
}

immutable(SafeCStr) strOfDiagnostics(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	ref immutable ShowDiagOptions options,
	ref immutable FilesInfo filesInfo,
	ref immutable Diagnostics diagnostics,
) {
	Writer writer = Writer(ptrTrustMe_mut(alloc));
	writeWithNewlines!Diagnostic(writer, diagnostics.diags, (ref immutable Diagnostic it) {
		showDiagnostic(alloc, writer, allSymbols, allPaths, pathsInfo, options, filesInfo, it);
	});
	return finishWriterToSafeCStr(writer);
}

immutable(string) strOfDiagnostic(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	ref immutable ShowDiagOptions options,
	ref immutable FilesInfo filesInfo,
	ref immutable Diagnostic diagnostic,
) {
	Writer writer = Writer(ptrTrustMe_mut(alloc));
	showDiagnostic(alloc, writer, allSymbols, allPaths, pathsInfo, options, filesInfo, diagnostic);
	return finishWriter(writer);
}

private:

void writeLineNumber(
	ref Writer writer,
	ref const AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	ref immutable ShowDiagOptions options,
	ref immutable FilesInfo fi,
	immutable FileAndPos pos,
) {
	immutable Path where = fi.filePaths[pos.fileIndex];
	if (options.color)
		writeBold(writer);
	writePath(writer, allPaths, pathsInfo, where, crowExtension);
	writer ~= ".crow";
	if (options.color)
		writeReset(writer);
	writer ~= " line ";
	immutable size_t line = lineAndColumnAtPos(fi.lineAndColumnGetters[pos.fileIndex], pos.pos).line;
	writer ~= line + 1;
}

void writeParseDiag(
	ref Writer writer,
	ref const AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	ref immutable ParseDiag d,
) {
	matchParseDiag!void(
		d,
		(ref immutable ParseDiag.CantPrecedeMutEquals) {
			writer ~= "this expression can't appear in front of ':='";
		},
		(ref immutable ParseDiag.CantPrecedeOptEquals) {
			writer ~= "only a plain identifier can appear in front of '?='";
		},
		(ref immutable ParseDiag.CircularImport it) {
			writer ~= "circular import from ";
			writePath(writer, allPaths, pathsInfo, it.from, crowExtension);
			writer ~= " to ";
			writePath(writer, allPaths, pathsInfo, it.to, crowExtension);
		},
		(ref immutable ParseDiag.Expected it) {
			final switch (it.kind) {
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
				case ParseDiag.Expected.Kind.equalsOrThen:
					writer ~= "expected '=' or '<-'";
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
				case ParseDiag.Expected.Kind.name:
					writer ~= "expected a name (non-operator)";
					break;
				case ParseDiag.Expected.Kind.nameOrOperator:
					writer ~= "expected a name or operator";
					break;
				case ParseDiag.Expected.Kind.openParen:
					writer ~= "expected '('";
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
		(ref immutable ParseDiag.FileDoesNotExist d) {
			writer ~= "file does not exist";
			if (has(d.importedFrom)) {
				writer ~= " (imported from ";
				writePath(writer, allPaths, pathsInfo, force(d.importedFrom).path, crowExtension);
				writer ~= ')';
			}
		},
		(ref immutable ParseDiag.FileReadError d) {
			writer ~= "unable to read file";
			if (has(d.importedFrom)) {
				writer ~= " (imported from ";
				writePath(writer, allPaths, pathsInfo, force(d.importedFrom).path, crowExtension);
				writer ~= ')';
			}
		},
		(ref immutable ParseDiag.FunctionTypeMissingParens) {
			writer ~= "function type missing parentheses";
		},
		(ref immutable ParseDiag.ImportFileTypeNotSupported) {
			writer ~= "import file type not allowed; the only supported types are 'array nat8' and 'str'";
		},
		(ref immutable ParseDiag.IndentNotDivisible d) {
			writer ~= "expected indentation by ";
			writer ~= d.nSpacesPerIndent;
			writer ~= " spaces per level, but got ";
			writer ~= d.nSpaces;
			writer ~= " which is not divisible";
		},
		(ref immutable ParseDiag.IndentTooMuch it) {
			writer ~= "indented too far";
		},
		(ref immutable ParseDiag.IndentWrongCharacter d) {
			writer ~= "expected indentation by ";
			writer ~= d.expectedTabs ? "tabs" : "spaces";
			writer ~= " (based on first indented line), but here there is a ";
			writer ~= d.expectedTabs ? "space" : "tab";
		},
		(ref immutable ParseDiag.InvalidName it) {
			writeQuotedStr(writer, it.actual);
			writer ~= " is not a valid name";
		},
		(ref immutable ParseDiag.InvalidStringEscape it) {
			writer ~= "invalid escape character '";
			writeEscapedChar(writer, it.actual);
			writer ~= '\'';
		},
		(ref immutable ParseDiag.LetMustHaveThen) {
			writer ~= "the final line of a block can not be 'x = y'\n(hint: remove 'x =', or add another line)";
		},
		(ref immutable ParseDiag.NeedsBlockCtx it) {
			writer ~= () {
				final switch (it.kind) {
					case ParseDiag.NeedsBlockCtx.Kind.break_:
						return "'break'";
					case ParseDiag.NeedsBlockCtx.Kind.for_:
						return "'for'";
					case ParseDiag.NeedsBlockCtx.Kind.if_:
						return "'if'";
					case ParseDiag.NeedsBlockCtx.Kind.match:
						return "'match'";
					case ParseDiag.NeedsBlockCtx.Kind.lambda:
						return "lambda";
					case ParseDiag.NeedsBlockCtx.Kind.loop:
						return "loop";
					case ParseDiag.NeedsBlockCtx.Kind.unless:
						return "'unless'";
					case ParseDiag.NeedsBlockCtx.Kind.until:
						return "'until'";
					case ParseDiag.NeedsBlockCtx.Kind.while_:
						return "'while'";
					case ParseDiag.NeedsBlockCtx.Kind.with_:
						return "'with'";
				}
			}();
			writer ~= " expression must appear ";
			writer ~= it.kind == ParseDiag.NeedsBlockCtx.Kind.break_
				? "on its own line"
				: "in a context where it can be followed by an indented block";
		},
		(ref immutable ParseDiag.RelativeImportReachesPastRoot d) {
			writer ~= "importing ";
			writeRelPath(writer, allPaths, d.imported, crowExtension);
			writer ~= " reaches above the source directory";
			//TODO: recommend a compiler option to fix this
		},
		(ref immutable ParseDiag.Unexpected it) {
			final switch (it.kind) {
				case ParseDiag.Unexpected.Kind.dedent:
					writer ~= "unexpected dedent";
					break;
				case ParseDiag.Unexpected.Kind.indent:
					writer ~= "unexpected indent";
					break;
			}
		},
		(ref immutable ParseDiag.UnexpectedCharacter u) {
			writer ~= "unexpected character '";
			showChar(writer, u.ch);
			writer ~= "'";
		},
		(ref immutable ParseDiag.UnexpectedOperator u) {
			writer ~= "unexpected '";
			writer ~= strOfOperator(u.operator);
			writer ~= '\'';
		},
		(ref immutable ParseDiag.UnexpectedToken u) {
			writer ~= describeTokenForUnexpected(u.token);
		},
		(ref immutable ParseDiag.UnionCantBeEmpty) {
			writer ~= "union type can't be empty";
		},
		(ref immutable ParseDiag.WhenMustHaveElse) {
			writer ~= "'if' expression must end in 'else'";
		});
}

void writePurity(ref Writer writer, scope ref const AllSymbols allSymbols, immutable Purity p) {
	writer ~= '\'';
	writeSym(writer, allSymbols, symOfPurity(p));
	writer ~= '\'';
}

void writeSig(
	scope ref Writer writer,
	scope ref const AllSymbols allSymbols,
	immutable Sym name,
	scope immutable Type returnType,
	scope immutable Params params,
) {
	writeSym(writer, allSymbols, name);
	writer ~= ' ';
	writeTypeUnquoted(writer, allSymbols, returnType);
	writer ~= '(';
	matchParams!void(
		params,
		(immutable Param[] paramsArray) {
			writeWithCommas!Param(writer, paramsArray, (ref immutable Param p) {
				writeTypeUnquoted(writer, allSymbols, p.type);
			});
		},
		(ref immutable Params.Varargs varargs) {
			writer ~= "...";
			writeTypeUnquoted(writer, allSymbols, varargs.param.type);
		});
	writer ~= ')';
}

void writeCalledDecl(
	ref Writer writer,
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	ref immutable ShowDiagOptions options,
	ref immutable FilesInfo fi,
	immutable CalledDecl c,
) {
	writeSig(writer, allSymbols, c.name, c.returnType, c.params);
	return matchCalledDecl!(
		void,
		(immutable FunDecl* funDecl) {
			writeFunDeclLocation(writer, allSymbols, allPaths, pathsInfo, options, fi, *funDecl);
		},
		(ref immutable SpecSig specSig) {
			writer ~= " (from spec ";
			writeName(writer, allSymbols, name(*specSig.specInst));
			writer ~= ')';
		},
	)(c);
}

void writeFunDeclLocation(
	ref Writer writer,
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	ref immutable ShowDiagOptions options,
	ref immutable FilesInfo fi,
	ref immutable FunDecl funDecl,
) {
	writer ~= " (from ";
	writeLineNumber(writer, allPaths, pathsInfo, options, fi, funDecl.fileAndPos);
	writer ~= ')';
}

void writeCalledDecls(
	ref Writer writer,
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	ref immutable ShowDiagOptions options,
	ref immutable FilesInfo fi,
	ref immutable CalledDecl[] cs,
	scope immutable(bool) delegate(ref immutable CalledDecl) @safe @nogc pure nothrow filter,
) {
	foreach (ref immutable CalledDecl c; cs)
		if (filter(c)) {
			writeNl(writer);
			writer ~= '\t';
			writeCalledDecl(writer, allSymbols, allPaths, pathsInfo, options, fi, c);
		}
}

void writeCalledDecls(
	ref Writer writer,
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	ref immutable ShowDiagOptions options,
	ref immutable FilesInfo fi,
	ref immutable CalledDecl[] cs,
) {
	writeCalledDecls(writer, allSymbols, allPaths, pathsInfo, options, fi, cs, (ref immutable CalledDecl) => true);
}

void writeCallNoMatch(
	ref Writer writer,
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	ref immutable ShowDiagOptions options,
	ref immutable FilesInfo fi,
	ref immutable Diag.CallNoMatch d,
) {
	immutable bool someCandidateHasCorrectNTypeArgs =
		d.actualNTypeArgs == 0 ||
		exists!CalledDecl(d.allCandidates, (ref immutable CalledDecl c) =>
			nTypeParams(c) == d.actualNTypeArgs);
	immutable bool someCandidateHasCorrectArity = exists!CalledDecl(d.allCandidates, (ref immutable CalledDecl c) =>
		(d.actualNTypeArgs == 0 || nTypeParams(c) == d.actualNTypeArgs) &&
		arityMatches(arity(c), d.actualArity));

	if (empty(d.allCandidates)) {
		writer ~= "there is no function ";
		if (d.actualArity == 0)
			// If there is no local variable by that name we try a call,
			// but message should reflect that the user might not have wanted a call.
			writer ~= "or variable ";
		else if (d.actualArity == 1)
			writer ~= "or field ";
		writer ~= "named ";
		writeName(writer, allSymbols, d.funName);

		if (d.actualArgTypes.length == 1) {
			writer ~= "\nargument type: ";
			writeTypeQuoted(writer, allSymbols, only(d.actualArgTypes));
		}
	} else if (!someCandidateHasCorrectArity) {
		writer ~= "there are functions named ";
		writeName(writer, allSymbols, d.funName);
		writer ~= ", but none takes ";
		if (someCandidateHasCorrectNTypeArgs) {
			writer ~= d.actualArity;
		} else {
			writer ~= d.actualNTypeArgs;
			writer ~= " type";
		}
		writer ~= " arguments. candidates:";
		writeCalledDecls(writer, allSymbols, allPaths, pathsInfo, options, fi, d.allCandidates);
	} else {
		writer ~= "there are functions named ";
		writeName(writer, allSymbols, d.funName);
		writer ~= ", but they do not match the ";
		immutable bool hasRet = has(d.expectedReturnType);
		immutable bool hasArgs = empty(d.actualArgTypes);
		immutable string descr = hasRet
			? hasArgs ? "expected return type and actual argument types" : "expected return type"
			: "actual argument types";
		writer ~= descr;
		writer ~= '.';
		if (hasRet) {
			writer ~= "\nexpected return type: ";
			writeTypeQuoted(writer, allSymbols, force(d.expectedReturnType));
		}
		if (hasArgs) {
			writer ~= "\nactual argument types: ";
			writeWithCommas!Type(writer, d.actualArgTypes, (ref immutable Type t) {
				writeTypeQuoted(writer, allSymbols, t);
			});
			if (d.actualArgTypes.length < d.actualArity)
				writer ~= " (other arguments not checked, gave up early)";
		}
		writer ~= "\ncandidates (with ";
		writer ~= d.actualArity;
		writer ~= " arguments):";
		writeCalledDecls(
			writer, allSymbols, allPaths, pathsInfo, options, fi, d.allCandidates,
			(ref immutable CalledDecl c) =>
				arityMatches(arity(c), d.actualArity));
	}
}

void writeDiag(
	ref TempAlloc tempAlloc,
	scope ref Writer writer,
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	ref immutable ShowDiagOptions options,
	ref immutable FilesInfo fi,
	ref immutable Diag d,
) {
	matchDiag!void(
		d,
		(ref immutable Diag.BuiltinUnsupported d) {
			writer ~= "the compiler does not implement a builtin named ";
			writeName(writer, allSymbols, d.name);
		},
		(ref immutable Diag.CallMultipleMatches d) {
			writer ~= "cannot choose an overload of ";
			writeName(writer, allSymbols, d.funName);
			writer ~= ". multiple functions match:";
			writeCalledDecls(writer, allSymbols, allPaths, pathsInfo, options, fi, d.matches);
		},
		(ref immutable Diag.CallNoMatch d) {
			writeCallNoMatch(writer, allSymbols, allPaths, pathsInfo, options, fi, d);
		},
		(ref immutable Diag.CantCall it) {
			immutable string descr = () {
				final switch (it.reason) {
					case Diag.CantCall.Reason.nonNoCtx:
						return "a 'noctx' function can't call a non-'noctx' function";
					case Diag.CantCall.Reason.summon:
						return "a non-'summon' function can't call a 'summon' function";
					case Diag.CantCall.Reason.unsafe:
						return "a non-'trusted' and non-'unsafe' function can't call an 'unsafe' function";
					case Diag.CantCall.Reason.variadicFromNoctx:
						return "a 'noctx' function can't call a variadic function";
				}
			}();
			writer ~= descr;
			writer ~= ' ';
			writeName(writer, allSymbols, it.callee.name);
		},
		(ref immutable Diag.CantInferTypeArguments) {
			writer ~= "can't infer type arguments";
		},
		(ref immutable Diag.CharLiteralMustBeOneChar) {
			writer ~= "value of 'char' type must be a single character";
		},
		(ref immutable Diag.CommonFunMissing it) {
			writer ~= "common function ";
			writeName(writer, allSymbols, it.name);
			writer ~= " is missing from 'bootstrap.crow'";
		},
		(ref immutable Diag.CommonTypesMissing d) {
			writer ~= "common types are missing from 'bootstrap.crow':";
			foreach (immutable string s; d.missing) {
				writer ~= "\n\t";
				writer ~= s;
			}
		},
		(ref immutable Diag.DuplicateDeclaration d) {
			immutable string desc = () {
				final switch (d.kind) {
					case Diag.DuplicateDeclaration.Kind.enumMember:
						return "enum member";
					case Diag.DuplicateDeclaration.Kind.flagsMember:
						return "flags member";
					case Diag.DuplicateDeclaration.Kind.paramOrLocal:
						return "variable";
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
			writer ~= desc;
			writer ~= " name ";
			writeName(writer, allSymbols, d.name);
			writer ~= " is already used";
		},
		(ref immutable Diag.DuplicateExports d) {
			writer ~= "there are multiple exported ";
			writer ~= () {
				final switch (d.kind) {
					case Diag.DuplicateExports.Kind.spec:
						return "specs";
					case Diag.DuplicateExports.Kind.type:
						return "types";
				}
			}();
			writer ~= " named ";
			writeName(writer, allSymbols, d.name);
		},
		(ref immutable Diag.DuplicateImports d) {
			//TODO: use d.kind
			writer ~= "the symbol ";
			writeName(writer, allSymbols, d.name);
			writer ~= " appears in multiple modules";
		},
		(ref immutable Diag.EnumBackingTypeInvalid d) {
			writer ~= "type ";
			writeStructInst(writer, allSymbols, *d.actual);
			writer ~= " cannot be used to back an enum";
		},
		(ref immutable Diag.EnumDuplicateValue d) {
			writer ~= "duplicate enum value ";
			if (d.signed)
				writer ~= d.value;
			else
				writer ~= cast(ulong) d.value;
		},
		(ref immutable Diag.EnumMemberOverflows d) {
			writer ~= "enum member is not in the allowed range ";
			writer ~= minValue(d.backingType);
			writer ~= " to ";
			writer ~= maxValue(d.backingType);
		},
		(ref immutable Diag.ExpectedTypeIsNotALambda d) {
			if (has(d.expectedType)) {
				writer ~= "the expected type at the lambda is ";
				writeTypeQuoted(writer, allSymbols, force(d.expectedType));
				writer ~= ", which is not a lambda type";
			} else
				writer ~= "there is no expected type at this location; lambdas need an expected type";
		},
		(ref immutable Diag.ExternFunForbidden d) {
			writer ~= "'extern' function ";
			writeName(writer, allSymbols, d.fun.name);
			writer ~= () {
				final switch (d.reason) {
					case Diag.ExternFunForbidden.Reason.hasSpecs:
						return " can't have specs";
					case Diag.ExternFunForbidden.Reason.hasTypeParams:
						return " can't have type parameters";
					case Diag.ExternFunForbidden.Reason.missingLibraryName:
						return " is missing the library name";
					case Diag.ExternFunForbidden.Reason.variadic:
						return " can't be variadic";
				}
			}();
		},
		(ref immutable Diag.ExternPtrHasTypeParams) {
			writer ~= "an 'extern-ptr' type should not be a template";
		},
		(ref immutable Diag.ExternRecordMustBeByRefOrVal d) {
			writer ~= "'extern' record ";
			writeName(writer, allSymbols, d.struct_.name);
			writer ~= " must be explicitly 'by-ref' or 'by-val'";
		},
		(ref immutable Diag.ExternUnion d) {
			writer ~= "a union can't be 'extern'";
		},
		(ref immutable Diag.FunMissingBody) {
			writer ~= "this function needs a body";
		},
		(ref immutable Diag.FunModifierConflict d) {
			writer ~= "a function can't be both ";
			writeName(writer, allSymbols, d.modifier0);
			writer ~= " and ";
			writeName(writer, allSymbols, d.modifier1);
		},
		(ref immutable Diag.FunModifierRedundant d) {
			writer ~= "redundant; ";
			writeName(writer, allSymbols, d.modifier);
			writer ~= " function is implicitly ";
			writeName(writer, allSymbols, d.redundantModifier);
		},
		(ref immutable Diag.FunModifierTypeArgs d) {
			writer ~= "function modifier ";
			writeName(writer, allSymbols, d.modifier);
			writer ~= " can not have type arguments";
		},
		(ref immutable Diag.IfNeedsOpt d) {
			writer ~= "Expected an option type, but got ";
			writeTypeQuoted(writer, allSymbols, d.actualType);
		},
		(ref immutable Diag.ImportRefersToNothing it) {
			writer ~= "imported name ";
			writeName(writer, allSymbols, it.name);
			writer ~= " does not refer to anything";
		},
		(ref immutable Diag.LambdaCantInferParamTypes) {
			writer ~= "lambda expression needs an expected type";
		},
		(ref immutable Diag.LambdaClosesOverMut d) {
			writer ~= "lambda is a plain 'fun' but closes over ";
			writeName(writer, allSymbols, d.name);
			writer ~= " of 'mut' type ";
			writeTypeQuoted(writer, allSymbols, d.type);
			writer ~= " (should it be an 'act' or 'ref' fun?)";
		},
		(ref immutable Diag.LambdaWrongNumberParams d) {
			writer ~= "expected a ";
			writeStructInst(writer, allSymbols, *d.expectedLambdaType);
			writer ~= " but lambda has ";
			writer ~= d.actualNParams;
			writer ~= " parameters";
		},
		(ref immutable Diag.LinkageWorseThanContainingFun d) {
			writer ~= "'extern' function ";
			writeName(writer, allSymbols, d.containingFun.name);
			if (has(d.param)) {
				immutable Opt!Sym paramName = force(d.param).name;
				if (has(paramName)) {
					writer ~= " parameter ";
					writeName(writer, allSymbols, force(paramName));
				}
			}
			writer ~= " can't reference non-extern type ";
			writeTypeQuoted(writer, allSymbols, d.referencedType);
		},
		(ref immutable Diag.LinkageWorseThanContainingType d) {
			writer ~= "extern type ";
			writeName(writer, allSymbols, d.containingType.name);
			writer ~= " can't reference non-extern type ";
			writeTypeQuoted(writer, allSymbols, d.referencedType);
		},
		(ref immutable Diag.LiteralOverflow d) {
			writer ~= "literal exceeds the range of a ";
			writeStructInst(writer, allSymbols, *d.type);
		},
		(ref immutable Diag.LocalNotMutable d) {
			writer ~= "local variable ";
			writeName(writer, allSymbols, d.local.name);
			writer ~= " was not marked 'mut'";
		},
		(ref immutable Diag.LoopBreakNotAtTail d) {
			writer ~= "'break' must be appear at the tail of a loop";
		},
		(ref immutable Diag.LoopNeedsBreakOrContinue) {
			writer ~= "a loop must end in 'break' or 'continue'";
		},
		(ref immutable Diag.LoopNeedsExpectedType) {
			writer ~= "can not infer type of loop; provide an expected type";
			writer ~= " (for example, by making it the return expression of a function)";
		},
		(ref immutable Diag.LoopWithoutBreak d) {
			writer ~= "'loop' has no 'break'";
		},
		(ref immutable Diag.MatchCaseNamesDoNotMatch d) {
			writer ~= "expected the case names to be: ";
			writeWithCommas!Sym(writer, d.expectedNames, (ref immutable Sym name) {
				writeName(writer, allSymbols, name);
			});
		},
		(ref immutable Diag.MatchCaseShouldHaveLocal d) {
			writer ~= "union member ";
			writeName(writer, allSymbols, d.name);
			writer ~= " has an associated value that should be declared (or use '_')";
		},
		(ref immutable Diag.MatchCaseShouldNotHaveLocal d) {
			writer ~= "union member ";
			writeName(writer, allSymbols, d.name);
			writer ~= " has no associated value";
		},
		(ref immutable Diag.MatchOnNonUnion d) {
			writer ~= "can't match on non-union type ";
			writeTypeQuoted(writer, allSymbols, d.type);
		},
		(ref immutable Diag.ModifierConflict d) {
			writeName(writer, allSymbols, d.curModifier);
			writer ~= " conflicts with ";
			writeName(writer, allSymbols, d.prevModifier);
		},
		(ref immutable Diag.ModifierDuplicate d) {
			writer ~= "redundant ";
			writeName(writer, allSymbols, d.modifier);
		},
		(ref immutable Diag.ModifierInvalid d) {
			writeName(writer, allSymbols, d.modifier);
			writer ~= " is not supported for ";
			writer ~= aOrAnTypeKind(d.typeKind);
		},
		(ref immutable Diag.MutFieldNotAllowed d) {
			writer ~= () {
				final switch (d.reason) {
					case Diag.MutFieldNotAllowed.Reason.recordIsNotMut:
						return "field is mut, but containing record was not marked mut";
					case Diag.MutFieldNotAllowed.Reason.recordIsForcedByVal:
						return "field is mut, but containing record was forced by-val";
				}
			}();
		},
		(ref immutable Diag.NameNotFound d) {
			writer ~= () {
				final switch (d.kind) {
					case Diag.NameNotFound.Kind.spec:
						return "spec";
					case Diag.NameNotFound.Kind.type:
						return "type";
				}
			}();
			writer ~= " name not found: ";
			writeName(writer, allSymbols, d.name);
		},
		(ref immutable ParseDiag pd) {
			writeParseDiag(writer, allPaths, pathsInfo, pd);
		},
		(ref immutable Diag.PtrIsUnsafe) {
			writer ~= "can only get pointer in an 'unsafe' or 'trusted' function";
		},
		(ref immutable Diag.PtrMutToConst d) {
			writer ~= () {
				final switch (d.kind) {
					case Diag.PtrMutToConst.Kind.field:
						return "can't get a mutable pointer to a non-'mut' field";
					case Diag.PtrMutToConst.Kind.local:
						return "can't get a mutable pointer to a non-'mut' local";
				}
			}();
		},
		(ref immutable Diag.PtrNeedsExpectedType) {
			writer ~= "pointer expression needs an expected type";
		},
		(ref immutable Diag.PtrUnsupported) {
			writer ~= "can't get a pointer to this kind of expression";
		},
		(ref immutable Diag.PurityWorseThanParent d) {
			writer ~= "struct ";
			writeName(writer, allSymbols, d.parent.name);
			writer ~= " has purity ";
			writePurity(writer, allSymbols, d.parent.purity);
			writer ~= ", but member of type ";
			writeTypeQuoted(writer, allSymbols, d.child);
			writer ~= " has purity ";
			writePurity(writer, allSymbols, bestCasePurity(d.child));
		},
		(ref immutable Diag.PuritySpecifierRedundant d) {
			writer ~= "redundant purity specifier of ";
			writePurity(writer, allSymbols, d.purity);
			writer ~= " is already the default for ";
			writer ~= aOrAnTypeKind(d.typeKind);
			writer ~= " type";
		},
		(ref immutable Diag.RecordNewVisibilityIsRedundant d) {
			writer ~= "the 'new' function for this record is already ";
			writeName(writer, allSymbols, symOfVisibility(d.visibility));
			writer ~= " by default";
		},
		(ref immutable Diag.SendFunDoesNotReturnFut d) {
			writer ~= "a 'ref' should return a 'future', but this returns ";
			writeTypeQuoted(writer, allSymbols, d.actualReturnType);
		},
		(ref immutable Diag.SpecBuiltinNotSatisfied d) {
			writer ~= "trying to call ";
			writeName(writer, allSymbols, d.called.name);
			writer ~= ", but ";
			writeTypeQuoted(writer, allSymbols, d.type);
			immutable string message = () {
				final switch (d.kind) {
					case SpecBody.Builtin.Kind.data:
						return " is not 'data'";
					case SpecBody.Builtin.Kind.send:
						return " is not 'send'";
				}
			}();
			writer ~= message;
		},
		(ref immutable Diag.SpecImplFoundMultiple d) {
			writer ~= "multiple implementations found for spec signature ";
			writeName(writer, allSymbols, d.sigName);
			writer ~= ':';
			writeCalledDecls(writer, allSymbols, allPaths, pathsInfo, options, fi, d.matches);
		},
		(ref immutable Diag.SpecImplHasSpecs d) {
			writer ~= "calling ";
			writeName(writer, allSymbols, d.outerCalled.name);
			writer ~= ", spec implementation for ";
			writeName(writer, allSymbols, d.specImpl.name);
			writeFunDeclLocation(writer, allSymbols, allPaths, pathsInfo, options, fi, *d.specImpl);
			writer ~= " has specs itself; currently this is not allowed";
		},
		(ref immutable Diag.SpecImplNotFound d) {
			writer ~= "no implementation was found for spec signature ";
			writeName(writer, allSymbols, d.sigName);
		},
		(ref immutable Diag.ThreadLocalError d) {
			writer ~= "thread-local ";
			writeName(writer, allSymbols, d.fun.name);
			writer ~= () {
				final switch (d.kind) {
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
		(ref immutable Diag.ThrowNeedsExpectedType) {
			writer ~= "'throw' needs an expected type";
		},
		(ref immutable Diag.TypeAnnotationUnnecessary d) {
			writer ~= "type ";
			writeTypeQuoted(writer, allSymbols, d.type);
			writer ~= " was already inferred";
		},
		(ref immutable Diag.TypeConflict d) {
			writer ~= "the type of the expression conflicts with its expected type.\n\texpected: ";
			writeTypeQuoted(writer, allSymbols, d.expected);
			writer ~= "\n\tactual: ";
			writeTypeQuoted(writer, allSymbols, d.actual);
		},
		(ref immutable Diag.TypeParamCantHaveTypeArgs) {
			writer ~= "a type parameter can't take type arguments";
		},
		(ref immutable Diag.TypeShouldUseSyntax it) {
			writer ~= () {
				final switch (it.kind) {
					case Diag.TypeShouldUseSyntax.Kind.dict:
						return "prefer to write 'v[k]' instead of 'dict<k, v>'";
					case Diag.TypeShouldUseSyntax.Kind.future:
						return "prefer to write 'a$' instead of 'future<a>";
					case Diag.TypeShouldUseSyntax.Kind.list:
						return "prefer to write 'a[]' instead of 'list a'";
					case Diag.TypeShouldUseSyntax.Kind.mutDict:
						return "prefer to write 'v mut[k]' instead of 'mut-dict<k, v>'";
					case Diag.TypeShouldUseSyntax.Kind.mutList:
						return "prefer to write 'a mut[]' instead of 'mut-list a'";
					case Diag.TypeShouldUseSyntax.Kind.mutPtr:
						return "prefer to write 'a mut*' instead of 'mut-ptr a'";
					case Diag.TypeShouldUseSyntax.Kind.opt:
						return "prefer to write 'a?' instead of 'opt a'";
					case Diag.TypeShouldUseSyntax.Kind.pair:
						return "prefer to write '(a, b)' instead of 'pair<a, b>'";
					case Diag.TypeShouldUseSyntax.Kind.ptr:
						return "prefer to write 'a*' instead of 'const-ptr a'";
				}
			}();
		},
		(ref immutable Diag.UnusedImport it) {
			if (has(it.importedName)) {
				writer ~= "imported name ";
				writeSym(writer, allSymbols, force(it.importedName));
			} else {
				writer ~= "imported module ";
				// TODO: helper fn
				immutable Sym moduleName = baseName(allPaths, fi.filePaths[it.importedModule.fileIndex]);
				writeSym(writer, allSymbols, moduleName);
			}
			writer ~= " is unused";
		},
		(ref immutable Diag.UnusedLocal it) {
			writer ~= "local ";
			writeSym(writer, allSymbols, it.local.name);
			writer ~= it.usedGet
				? " is mutable but never reassigned"
				: (it.usedSet ? " is assigned to but unused" : " is unused");
		},
		(ref immutable Diag.UnusedParam it) {
			writer ~= "parameter ";
			writeSym(writer, allSymbols, force(it.param.name));
			writer ~= " is unused";
		},
		(ref immutable Diag.UnusedPrivateFun it) {
			writer ~= "private function ";
			writeSym(writer, allSymbols, it.fun.name);
			writer ~= " is unused";
		},
		(ref immutable Diag.UnusedPrivateSpec it) {
			writer ~= "private spec ";
			writeSym(writer, allSymbols, it.spec.name);
			writer ~= " is unused";
		},
		(ref immutable Diag.UnusedPrivateStruct it) {
			writer ~= "private type ";
			writeSym(writer, allSymbols, it.struct_.name);
			writer ~= " is unused";
		},
		(ref immutable Diag.UnusedPrivateStructAlias it) {
			writer ~= "private type ";
			writeSym(writer, allSymbols, it.alias_.name);
			writer ~= " is unused";
		},
		(ref immutable Diag.WrongNumberTypeArgsForSpec d) {
			writeName(writer, allSymbols, d.decl.name);
			writer ~= " expected to get ";
			writer ~= d.nExpectedTypeArgs;
			writer ~= " type args, but got ";
			writer ~= d.nActualTypeArgs;
		},
		(ref immutable Diag.WrongNumberTypeArgsForStruct d) {
			writeName(writer, allSymbols, d.decl.name);
			writer ~= " expected to get ";
			writer ~= d.nExpectedTypeArgs;
			writer ~= " type args, but got ";
			writer ~= d.nActualTypeArgs;
		});
}

void showDiagnostic(
	ref TempAlloc tempAlloc,
	scope ref Writer writer,
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	ref immutable ShowDiagOptions options,
	ref immutable FilesInfo fi,
	ref immutable Diagnostic d,
) {
	writeFileAndRange(writer, allPaths, pathsInfo, options, fi, d.where);
	writer ~= ' ';
	writeDiag(tempAlloc, writer, allSymbols, allPaths, pathsInfo, options, fi, d.diag);
	writeNl(writer);
}

immutable(string) aOrAnTypeKind(immutable TypeKind a) {
	final switch (a) {
		case TypeKind.builtin:
			return "a builtin";
		case TypeKind.enum_:
			return "an enum";
		case TypeKind.flags:
			return "a flags type";
		case TypeKind.externPtr:
			return "an extern-ptr";
		case TypeKind.record:
			return "a record";
		case TypeKind.union_:
			return "a union";
	}
}

immutable(long) minValue(immutable EnumBackingType type) {
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

immutable(ulong) maxValue(immutable EnumBackingType type) {
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

immutable(string) describeTokenForUnexpected(immutable Token token) {
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
		case Token.atLess:
			return "unexpected '@<'";
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
		case Token.data:
			return "unexpected keyword 'data'";
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
		case Token.externPtr:
			return "unexpected keyword 'extern-ptr'";
		case Token.EOF:
			return "unexpected end of file";
		case Token.flags:
			return "unexpected keyword 'flags'";
		case Token.for_:
			return "unexpected keyword 'for'";
		case Token.forbid:
			return "unexpected keyword 'forbid'";
		case Token.forceSendable:
			return "unexpected keyword 'force-sendable'";
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
		case Token.literal:
			return "unexpected literal expression";
		case Token.loop:
			return "unexpected keyword 'loop'";
		case Token.match:
			return "unexpected keyword 'match'";
		case Token.mut:
			return "unexpected keyword 'mut'";
		case Token.name:
			return "did not expect a name here";
		case Token.newline:
			return "unexpected newline";
		case Token.noCtx:
			return "unexpected keyword 'noctx'";
		case Token.noDoc:
			return "unexpected keyword 'no-doc'";
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
		case Token.record:
			return "unexpected keyword 'record'";
		case Token.ref_:
			return "unexpected keyword 'ref'";
		case Token.semicolon:
			return "unexpected ';'";
		case Token.sendable:
			return "unexpected keyword 'sendable'";
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
