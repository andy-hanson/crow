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
	sig,
	Sig,
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
import util.ptr : Ptr, ptrTrustMe_mut;
import util.sourceRange : FileAndPos;
import util.sym : AllSymbols, strOfOperator, Sym, writeSym;
import util.util : unreachable;
import util.writer :
	finishWriter,
	finishWriterToSafeCStr,
	writeBold,
	writeChar,
	writeEscapedChar,
	writeInt,
	writeNat,
	writeQuotedStr,
	writeReset,
	writeSafeCStr,
	writeStatic,
	writeStr,
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
	writeStatic(writer, ".crow");
	if (options.color)
		writeReset(writer);
	writeStatic(writer, " line ");
	immutable size_t line = lineAndColumnAtPos(fi.lineAndColumnGetters[pos.fileIndex], pos.pos).line;
	writeNat(writer, line + 1);
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
			writeStatic(writer, "this expression can't appear in front of ':='");
		},
		(ref immutable ParseDiag.CantPrecedeOptEquals) {
			writeStatic(writer, "only a plain identifier can appear in front of '?='");
		},
		(ref immutable ParseDiag.CircularImport it) {
			writeStatic(writer, "circular import from ");
			writePath(writer, allPaths, pathsInfo, it.from, crowExtension);
			writeStatic(writer, " to ");
			writePath(writer, allPaths, pathsInfo, it.to, crowExtension);
		},
		(ref immutable ParseDiag.Expected it) {
			final switch (it.kind) {
				case ParseDiag.Expected.Kind.afterMut:
					writeStatic(writer, "expected '[' or '*' after 'mut'");
					break;
				case ParseDiag.Expected.Kind.blockCommentEnd:
					writeStatic(writer, "Expected '###' (then a newline)");
					break;
				case ParseDiag.Expected.Kind.bodyKeyword:
					writeStatic(writer, "expected 'body'");
					break;
				case ParseDiag.Expected.Kind.closeInterpolated:
					writeStatic(writer, "expected '}'");
					break;
				case ParseDiag.Expected.Kind.closingBracket:
					writeStatic(writer, "expected ']'");
					break;
				case ParseDiag.Expected.Kind.closingParen:
					writeStatic(writer, "expected ')'");
					break;
				case ParseDiag.Expected.Kind.comma:
					writeStatic(writer, "expected ', '");
					break;
				case ParseDiag.Expected.Kind.dedent:
					writeStatic(writer, "expected a dedent");
					break;
				case ParseDiag.Expected.Kind.endOfLine:
					writeStatic(writer, "expected end of line");
					break;
				case ParseDiag.Expected.Kind.equalsOrThen:
					writeStatic(writer, "expected '=' or '<-'");
					break;
				case ParseDiag.Expected.Kind.indent:
					writeStatic(writer, "expected an indent");
					break;
				case ParseDiag.Expected.Kind.lambdaArrow:
					writeStatic(writer, "expected ' =>' after lambda parameters");
					break;
				case ParseDiag.Expected.Kind.less:
					writeStatic(writer, "expected '<'");
					break;
				case ParseDiag.Expected.Kind.name:
					writeStatic(writer, "expected a name (non-operator)");
					break;
				case ParseDiag.Expected.Kind.nameOrOperator:
					writeStatic(writer, "expected a name or operator");
					break;
				case ParseDiag.Expected.Kind.quoteDouble:
					writeStatic(writer, "expected '\"'");
					break;
				case ParseDiag.Expected.Kind.quoteDouble3:
					writeStatic(writer, "expected '\"\"\"'");
					break;
				case ParseDiag.Expected.Kind.slash:
					writeStatic(writer, "expected '/'");
					break;
				case ParseDiag.Expected.Kind.typeArgsEnd:
					writeStatic(writer, "expected '>'");
					break;
			}
		},
		(ref immutable ParseDiag.FileDoesNotExist d) {
			writeStatic(writer, "file does not exist");
			if (has(d.importedFrom)) {
				writeStatic(writer, " (imported from ");
				writePath(writer, allPaths, pathsInfo, force(d.importedFrom).path, crowExtension);
				writeChar(writer, ')');
			}
		},
		(ref immutable ParseDiag.FileReadError d) {
			writeStatic(writer, "unable to read file");
			if (has(d.importedFrom)) {
				writeStatic(writer, " (imported from ");
				writePath(writer, allPaths, pathsInfo, force(d.importedFrom).path, crowExtension);
				writeChar(writer, ')');
			}
		},
		(ref immutable ParseDiag.FunctionTypeMissingParens) {
			writeStatic(writer, "function type missing parentheses");
		},
		(ref immutable ParseDiag.ImportFileTypeNotSupported) {
			writeStatic(writer, "import file type not allowed; the only supported types are 'nat8[]' and 'str'");
		},
		(ref immutable ParseDiag.IndentNotDivisible d) {
			writeStatic(writer, "expected indentation by ");
			writeNat(writer, d.nSpacesPerIndent);
			writeStatic(writer, " spaces per level, but got ");
			writeNat(writer, d.nSpaces);
			writeStatic(writer, " which is not divisible");
		},
		(ref immutable ParseDiag.IndentTooMuch it) {
			writeStatic(writer, "indented too far");
		},
		(ref immutable ParseDiag.IndentWrongCharacter d) {
			writeStatic(writer, "expected indentation by ");
			writeStatic(writer, d.expectedTabs ? "tabs" : "spaces");
			writeStatic(writer, " (based on first indented line), but here there is a ");
			writeStatic(writer, d.expectedTabs ? "space" : "tab");
		},
		(ref immutable ParseDiag.InvalidName it) {
			writeQuotedStr(writer, it.actual);
			writeStatic(writer, " is not a valid name");
		},
		(ref immutable ParseDiag.InvalidStringEscape it) {
			writeStatic(writer, "invalid escape character '");
			writeEscapedChar(writer, it.actual);
			writeChar(writer, '\'');
		},
		(ref immutable ParseDiag.LetMustHaveThen) {
			writeStatic(
				writer,
				"the final line of a block can not be 'x = y'\n(hint: remove 'x =', or add another line)");
		},
		(ref immutable ParseDiag.NeedsBlockCtx it) {
			writeStatic(writer, () {
				final switch (it.kind) {
					case ParseDiag.NeedsBlockCtx.Kind.if_:
						return "'if'";
					case ParseDiag.NeedsBlockCtx.Kind.match:
						return "'match'";
					case ParseDiag.NeedsBlockCtx.Kind.lambda:
						return "lambda";
					case ParseDiag.NeedsBlockCtx.Kind.unless:
						return "'unless'";
				}
			}());
			writeStatic(writer, " expression must appear in a context where it can be followed by an indented block");
		},
		(ref immutable ParseDiag.RelativeImportReachesPastRoot d) {
			writeStatic(writer, "importing ");
			writeRelPath(writer, allPaths, d.imported, crowExtension);
			writeStatic(writer, " reaches above the source directory");
			//TODO: recommend a compiler option to fix this
		},
		(ref immutable ParseDiag.Unexpected it) {
			final switch (it.kind) {
				case ParseDiag.Unexpected.Kind.dedent:
					writeStatic(writer, "unexpected dedent");
					break;
				case ParseDiag.Unexpected.Kind.indent:
					writeStatic(writer, "unexpected indent");
					break;
			}
		},
		(ref immutable ParseDiag.UnexpectedCharacter u) {
			writeStatic(writer, "unexpected character '");
			showChar(writer, u.ch);
			writeStatic(writer, "'");
		},
		(ref immutable ParseDiag.UnexpectedOperator u) {
			writeStatic(writer, "unexpected '");
			writeSafeCStr(writer, strOfOperator(u.operator));
			writeChar(writer, '\'');
		},
		(ref immutable ParseDiag.UnexpectedToken u) {
			writeStatic(writer, describeTokenForUnexpected(u.token));
		},
		(ref immutable ParseDiag.UnionCantBeEmpty) {
			writeStatic(writer, "union type can't be empty");
		},
		(ref immutable ParseDiag.WhenMustHaveElse) {
			writeStatic(writer, "'if' expression must end in 'else'");
		});
}

void writePurity(ref Writer writer, immutable Purity p) {
	writeChar(writer, '\'');
	final switch (p) {
		case Purity.data:
			writeStatic(writer, "data");
			break;
		case Purity.sendable:
			writeStatic(writer, "sendable");
			break;
		case Purity.mut:
			writeStatic(writer, "mut");
			break;
	}
	writeChar(writer, '\'');
}

void writeSig(ref Writer writer, ref const AllSymbols allSymbols, ref immutable Sig s) {
	writeSym(writer, allSymbols, s.name);
	writeChar(writer, ' ');
	writeTypeUnquoted(writer, allSymbols, s.returnType);
	writeChar(writer, '(');
	matchParams!void(
		s.params,
		(immutable Param[] params) {
			writeWithCommas!Param(writer, params, (ref immutable Param p) {
				writeTypeUnquoted(writer, allSymbols, p.type);
			});
		},
		(ref immutable Params.Varargs varargs) {
			writeStatic(writer, "...");
			writeTypeUnquoted(writer, allSymbols, varargs.param.type);
		});
	writeChar(writer, ')');
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
	writeSig(writer, allSymbols, c.sig);
	return matchCalledDecl!(
		void,
		(immutable Ptr!FunDecl funDecl) {
			writeFunDeclLocation(writer, allSymbols, allPaths, pathsInfo, options, fi, funDecl.deref());
		},
		(ref immutable SpecSig specSig) {
			writeStatic(writer, " (from spec ");
			writeName(writer, allSymbols, specSig.specInst.deref().name);
			writeChar(writer, ')');
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
	writeStatic(writer, " (from ");
	writeLineNumber(writer, allPaths, pathsInfo, options, fi, funDecl.fileAndPos);
	writeChar(writer, ')');
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
			writeChar(writer, '\t');
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
		writeStatic(writer, "there is no function ");
		if (d.actualArity == 0)
			// If there is no local variable by that name we try a call,
			// but message should reflect that the user might not have wanted a call.
			writeStatic(writer, "or variable ");
		else if (d.actualArity == 1)
			writeStatic(writer, "or field ");
		writeStatic(writer, "named ");
		writeName(writer, allSymbols, d.funName);

		if (d.actualArgTypes.length == 1) {
			writeStatic(writer, "\nargument type: ");
			writeTypeQuoted(writer, allSymbols, only(d.actualArgTypes));
		}
	} else if (!someCandidateHasCorrectArity) {
		writeStatic(writer, "there are functions named ");
		writeName(writer, allSymbols, d.funName);
		writeStatic(writer, ", but none takes ");
		if (someCandidateHasCorrectNTypeArgs) {
			writeNat(writer, d.actualArity);
		} else {
			writeNat(writer, d.actualNTypeArgs);
			writeStatic(writer, " type");
		}
		writeStatic(writer, " arguments. candidates:");
		writeCalledDecls(writer, allSymbols, allPaths, pathsInfo, options, fi, d.allCandidates);
	} else {
		writeStatic(writer, "there are functions named ");
		writeName(writer, allSymbols, d.funName);
		writeStatic(writer, ", but they do not match the ");
		immutable bool hasRet = has(d.expectedReturnType);
		immutable bool hasArgs = empty(d.actualArgTypes);
		immutable string descr = hasRet
			? hasArgs ? "expected return type and actual argument types" : "expected return type"
			: "actual argument types";
		writeStatic(writer, descr);
		writeStatic(writer, ".");
		if (hasRet) {
			writeStatic(writer, "\nexpected return type: ");
			writeTypeQuoted(writer, allSymbols, force(d.expectedReturnType));
		}
		if (hasArgs) {
			writeStatic(writer, "\nactual argument types: ");
			writeWithCommas!Type(writer, d.actualArgTypes, (ref immutable Type t) {
				writeTypeQuoted(writer, allSymbols, t);
			});
			if (d.actualArgTypes.length < d.actualArity)
				writeStatic(writer, " (other arguments not checked, gave up early)");
		}
		writeStatic(writer, "\ncandidates (with ");
		writeNat(writer, d.actualArity);
		writeStatic(writer, " arguments):");
		writeCalledDecls(
			writer, allSymbols, allPaths, pathsInfo, options, fi, d.allCandidates,
			(ref immutable CalledDecl c) =>
				arityMatches(arity(c), d.actualArity));
	}
}

void writeDiag(
	ref TempAlloc tempAlloc,
	ref Writer writer,
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
			writeStatic(writer, "the compiler does not implement a builtin named ");
			writeName(writer, allSymbols, d.name);
		},
		(ref immutable Diag.CallMultipleMatches d) {
			writeStatic(writer, "cannot choose an overload of ");
			writeName(writer, allSymbols, d.funName);
			writeStatic(writer, ". multiple functions match:");
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
			writeStatic(writer, descr);
			writeChar(writer, ' ');
			writeName(writer, allSymbols, it.callee.deref().name);
		},
		(ref immutable Diag.CantInferTypeArguments) {
			writeStatic(writer, "can't infer type arguments");
		},
		(ref immutable Diag.CharLiteralMustBeOneChar) {
			writeStatic(writer, "value of 'char' type must be a single character");
		},
		(ref immutable Diag.CommonFunMissing it) {
			writeStatic(writer, "common function ");
			writeName(writer, allSymbols, it.name);
			writeStatic(writer, " is missing from 'bootstrap.crow'");
		},
		(ref immutable Diag.CommonTypesMissing d) {
			writeStatic(writer, "common types are missing from 'bootstrap.crow':");
			foreach (immutable string s; d.missing) {
				writeStatic(writer, "\n\t");
				writeStr(writer, s);
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
			writeStatic(writer, desc);
			writeStatic(writer, " name ");
			writeName(writer, allSymbols, d.name);
			writeStatic(writer, " is already used");
		},
		(ref immutable Diag.DuplicateExports d) {
			writeStatic(writer, "there are multiple exported ");
			writeStatic(writer, () {
				final switch (d.kind) {
					case Diag.DuplicateExports.Kind.spec:
						return "specs";
					case Diag.DuplicateExports.Kind.type:
						return "types";
				}
			}());
			writeStatic(writer, " named ");
			writeName(writer, allSymbols, d.name);
		},
		(ref immutable Diag.DuplicateImports d) {
			//TODO: use d.kind
			writeStatic(writer, "the symbol ");
			writeName(writer, allSymbols, d.name);
			writeStatic(writer, " appears in multiple modules");
		},
		(ref immutable Diag.EnumBackingTypeInvalid d) {
			writeStatic(writer, "type ");
			writeStructInst(writer, allSymbols, d.actual.deref());
			writeStatic(writer, " cannot be used to back an enum");
		},
		(ref immutable Diag.EnumDuplicateValue d) {
			writeStatic(writer, "duplicate enum value ");
			if (d.signed)
				writeInt(writer, d.value);
			else
				writeNat(writer, cast(ulong) d.value);
		},
		(ref immutable Diag.EnumMemberOverflows d) {
			writeStatic(writer, "enum member is not in the allowed range ");
			writeInt(writer, minValue(d.backingType));
			writeStatic(writer, " to ");
			writeNat(writer, maxValue(d.backingType));
		},
		(ref immutable Diag.ExpectedTypeIsNotALambda d) {
			if (has(d.expectedType)) {
				writeStatic(writer, "the expected type at the lambda is ");
				writeTypeQuoted(writer, allSymbols, force(d.expectedType));
				writeStatic(writer, ", which is not a lambda type");
			} else
				writeStatic(writer, "there is no expected type at this location; lambdas need an expected type");
		},
		(ref immutable Diag.ExternFunForbidden d) {
			writeStatic(writer, "'extern' function ");
			writeName(writer, allSymbols, d.fun.deref().name);
			writeStatic(writer, () {
				final switch (d.reason) {
					case Diag.ExternFunForbidden.Reason.hasSpecs:
						return " can't have specs";
					case Diag.ExternFunForbidden.Reason.hasTypeParams:
						return " can't have type parameters";
					case Diag.ExternFunForbidden.Reason.needsNoCtx:
						return " must be 'noctx'";
					case Diag.ExternFunForbidden.Reason.variadic:
						return " can't be variadic";
				}
			}());
		},
		(ref immutable Diag.ExternPtrHasTypeParams) {
			writeStatic(writer, "an 'extern-ptr' type should not be a template");
		},
		(ref immutable Diag.ExternRecordMustBeByRefOrVal d) {
			writeStatic(writer, "'extern' record ");
			writeName(writer, allSymbols, d.struct_.deref().name);
			writeStatic(writer, " must be explicitly 'by-ref' or 'by-val'");
		},
		(ref immutable Diag.ExternUnion d) {
			writeStatic(writer, "a union can't be 'extern'");
		},
		(ref immutable Diag.IfNeedsOpt d) {
			writeStatic(writer, "Expected an option type, but got ");
			writeTypeQuoted(writer, allSymbols, d.actualType);
		},
		(ref immutable Diag.ImportRefersToNothing it) {
			writeStatic(writer, "imported name ");
			writeName(writer, allSymbols, it.name);
			writeStatic(writer, " does not refer to anything");
		},
		(ref immutable Diag.LambdaCantInferParamTypes) {
			writeStatic(writer, "lambda expression needs an expected type");
		},
		(ref immutable Diag.LambdaClosesOverMut d) {
			writeStatic(writer, "lambda is a plain 'fun' but closes over ");
			writeName(writer, allSymbols, d.name);
			writeStatic(writer, " of 'mut' type ");
			writeTypeQuoted(writer, allSymbols, d.type);
			writeStatic(writer, " (should it be an 'act' or 'ref' fun?)");
		},
		(ref immutable Diag.LambdaWrongNumberParams d) {
			writeStatic(writer, "expected a ");
			writeStructInst(writer, allSymbols, d.expectedLambdaType.deref());
			writeStatic(writer, " but lambda has ");
			writeNat(writer, d.actualNParams);
			writeStatic(writer, " parameters");
		},
		(ref immutable Diag.LinkageWorseThanContainingFun d) {
			writeStatic(writer, "'extern' function ");
			writeName(writer, allSymbols, name(d.containingFun.deref()));
			if (has(d.param)) {
				immutable Opt!Sym paramName = force(d.param).deref().name;
				if (has(paramName)) {
					writeStatic(writer, " parameter ");
					writeName(writer, allSymbols, force(paramName));
				}
			}
			writeStatic(writer, " can't reference non-extern type ");
			writeTypeQuoted(writer, allSymbols, d.referencedType);
		},
		(ref immutable Diag.LinkageWorseThanContainingType d) {
			writeStatic(writer, "extern type ");
			writeName(writer, allSymbols, d.containingType.deref().name);
			writeStatic(writer, " can't reference non-extern type ");
			writeTypeQuoted(writer, allSymbols, d.referencedType);
		},
		(ref immutable Diag.LiteralOverflow d) {
			writeStatic(writer, "literal exceeds the range of a ");
			writeStructInst(writer, allSymbols, d.type.deref());
		},
		(ref immutable Diag.MatchCaseNamesDoNotMatch d) {
			writeStatic(writer, "expected the case names to be: ");
			writeWithCommas!Sym(writer, d.expectedNames, (ref immutable Sym name) {
				writeName(writer, allSymbols, name);
			});
		},
		(ref immutable Diag.MatchCaseShouldHaveLocal d) {
			writeStatic(writer, "union member ");
			writeName(writer, allSymbols, d.name);
			writeStatic(writer, " has an associated value that should be declared (or use '_')");
		},
		(ref immutable Diag.MatchCaseShouldNotHaveLocal d) {
			writeStatic(writer, "union member ");
			writeName(writer, allSymbols, d.name);
			writeStatic(writer, " has no associated value");
		},
		(ref immutable Diag.MatchOnNonUnion d) {
			writeStatic(writer, "can't match on non-union type ");
			writeTypeQuoted(writer, allSymbols, d.type);
		},
		(ref immutable Diag.ModifierConflict d) {
			writeName(writer, allSymbols, d.curModifier);
			writeStatic(writer, " conflicts with ");
			writeName(writer, allSymbols, d.prevModifier);
		},
		(ref immutable Diag.ModifierDuplicate d) {
			writeStatic(writer, "redundant ");
			writeName(writer, allSymbols, d.modifier);
		},
		(ref immutable Diag.ModifierInvalid d) {
			writeName(writer, allSymbols, d.modifier);
			writeStatic(writer, " is not supported for ");
			writeStatic(writer, aOrAnTypeKind(d.typeKind));
		},
		(ref immutable Diag.MutFieldNotAllowed d) {
			immutable string message = () {
				final switch (d.reason) {
					case Diag.MutFieldNotAllowed.Reason.recordIsNotMut:
						return "field is mut, but containing record was not marked mut";
					case Diag.MutFieldNotAllowed.Reason.recordIsForcedByVal:
						return "field is mut, but containing record was forced by-val";
				}
			}();
			writeStatic(writer, message);
		},
		(ref immutable Diag.NameNotFound d) {
			immutable string kind = () {
				final switch (d.kind) {
					case Diag.NameNotFound.Kind.spec:
						return "spec";
					case Diag.NameNotFound.Kind.type:
						return "type";
				}
			}();
			writeStatic(writer, kind);
			writeStatic(writer, " name not found: ");
			writeName(writer, allSymbols, d.name);
		},
		(ref immutable ParseDiag pd) {
			writeParseDiag(writer, allPaths, pathsInfo, pd);
		},
		(ref immutable Diag.PurityWorseThanParent d) {
			writeStatic(writer, "struct ");
			writeName(writer, allSymbols, d.parent.deref().name);
			writeStatic(writer, " has purity ");
			writePurity(writer, d.parent.deref().purity);
			writeStatic(writer, ", but member of type ");
			writeTypeQuoted(writer, allSymbols, d.child);
			writeStatic(writer, " has purity ");
			writePurity(writer, bestCasePurity(d.child));
		},
		(ref immutable Diag.PuritySpecifierRedundant d) {
			writeStatic(writer, "redundant purity specifier of ");
			writeName(writer, allSymbols, symOfPurity(d.purity));
			writeStatic(writer, " is already the default for ");
			writeStatic(writer, aOrAnTypeKind(d.typeKind));
			writeStatic(writer, " type");
		},
		(ref immutable Diag.RecordNewVisibilityIsRedundant d) {
			writeStatic(writer, "the 'new' function for this record is already ");
			writeName(writer, allSymbols, symOfVisibility(d.visibility));
			writeStatic(writer, " by default");
		},
		(ref immutable Diag.SendFunDoesNotReturnFut d) {
			writeStatic(writer, "a 'ref' should return a 'fut', but this returns ");
			writeTypeQuoted(writer, allSymbols, d.actualReturnType);
		},
		(ref immutable Diag.SpecBuiltinNotSatisfied d) {
			writeStatic(writer, "trying to call ");
			writeName(writer, allSymbols, d.called.deref.name);
			writeStatic(writer, ", but ");
			writeTypeQuoted(writer, allSymbols, d.type);
			immutable string message = () {
				final switch (d.kind) {
					case SpecBody.Builtin.Kind.data:
						return " is not 'data'";
					case SpecBody.Builtin.Kind.send:
						return " is not 'send'";
				}
			}();
			writeStatic(writer, message);
		},
		(ref immutable Diag.SpecImplFoundMultiple d) {
			writeStatic(writer, "multiple implementations found for spec signature ");
			writeName(writer, allSymbols, d.sigName);
			writeChar(writer, ':');
			writeCalledDecls(writer, allSymbols, allPaths, pathsInfo, options, fi, d.matches);
		},
		(ref immutable Diag.SpecImplHasSpecs d) {
			writeStatic(writer, "calling ");
			writeName(writer, allSymbols, name(d.outerCalled.deref()));
			writeStatic(writer, ", spec implementation for ");
			writeName(writer, allSymbols, name(d.specImpl.deref()));
			writeFunDeclLocation(writer, allSymbols, allPaths, pathsInfo, options, fi, d.specImpl.deref());
			writeStatic(writer, " has specs itself; currently this is not allowed");
		},
		(ref immutable Diag.SpecImplNotFound d) {
			writeStatic(writer, "no implementation was found for spec signature ");
			writeName(writer, allSymbols, d.sigName);
		},
		(ref immutable Diag.TypeAnnotationUnnecessary d) {
			writeStatic(writer, "type ");
			writeTypeQuoted(writer, allSymbols, d.type);
			writeStatic(writer, " was already inferred");
		},
		(ref immutable Diag.TypeConflict d) {
			writeStatic(writer, "the type of the expression conflicts with its expected type.\n\texpected: ");
			writeTypeQuoted(writer, allSymbols, d.expected);
			writeStatic(writer, "\n\tactual: ");
			writeTypeQuoted(writer, allSymbols, d.actual);
		},
		(ref immutable Diag.TypeParamCantHaveTypeArgs) {
			writeStatic(writer, "a type parameter can't take type arguments");
		},
		(ref immutable Diag.TypeShouldUseSyntax it) {
			writeStatic(writer, () {
				final switch (it.kind) {
					case Diag.TypeShouldUseSyntax.Kind.arr:
						return "prefer to write 'a[]' instead of 'arr a'";
					case Diag.TypeShouldUseSyntax.Kind.arrMut:
						return "prefer to write 'a mut[]' instead of 'mut-arr a'";
					case Diag.TypeShouldUseSyntax.Kind.dict:
						return "prefer to write 'v[k]' instead of 'dict<k, v>'";
					case Diag.TypeShouldUseSyntax.Kind.dictMut:
						return "prefer to write 'v mut[k]' instead of 'mut-dict<k, v>'";
					case Diag.TypeShouldUseSyntax.Kind.opt:
						return "prefer to write 'a?' instead of 'opt a'";
					case Diag.TypeShouldUseSyntax.Kind.ptr:
						return "prefer to write 'a*' instead of 'const-ptr a'";
					case Diag.TypeShouldUseSyntax.Kind.ptrMut:
						return "prefer to write 'a mut*' instead of 'mut-ptr a'";
				}
			}());
		},
		(ref immutable Diag.UnusedImport it) {
			if (has(it.importedName)) {
				writeStatic(writer, "imported name ");
				writeSym(writer, allSymbols, force(it.importedName));
			} else {
				writeStatic(writer, "imported module ");
				// TODO: helper fn
				immutable Sym moduleName = baseName(allPaths, fi.filePaths[it.importedModule.deref().fileIndex]);
				writeSym(writer, allSymbols, moduleName);
			}
			writeStatic(writer, " is unused");
		},
		(ref immutable Diag.UnusedLocal it) {
			writeStatic(writer, "local ");
			writeSym(writer, allSymbols, it.local.deref().name);
			writeStatic(writer, " is unused");
		},
		(ref immutable Diag.UnusedParam it) {
			writeStatic(writer, "parameter ");
			writeSym(writer, allSymbols, force(it.param.deref().name));
			writeStatic(writer, " is unused");
		},
		(ref immutable Diag.UnusedPrivateFun it) {
			writeStatic(writer, "private function ");
			writeSym(writer, allSymbols, name(it.fun.deref()));
			writeStatic(writer, " is unused");
		},
		(ref immutable Diag.UnusedPrivateSpec it) {
			writeStatic(writer, "private spec ");
			writeSym(writer, allSymbols, it.spec.deref().name);
			writeStatic(writer, " is unused");
		},
		(ref immutable Diag.UnusedPrivateStruct it) {
			writeStatic(writer, "private type ");
			writeSym(writer, allSymbols, it.struct_.deref().name);
			writeStatic(writer, " is unused");
		},
		(ref immutable Diag.UnusedPrivateStructAlias it) {
			writeStatic(writer, "private type ");
			writeSym(writer, allSymbols, it.alias_.deref().name);
			writeStatic(writer, " is unused");
		},
		(ref immutable Diag.WrongNumberTypeArgsForSpec d) {
			writeName(writer, allSymbols, d.decl.deref().name);
			writeStatic(writer, " expected to get ");
			writeNat(writer, d.nExpectedTypeArgs);
			writeStatic(writer, " type args, but got ");
			writeNat(writer, d.nActualTypeArgs);
		},
		(ref immutable Diag.WrongNumberTypeArgsForStruct d) {
			writeName(writer, allSymbols, d.decl.name);
			writeStatic(writer, " expected to get ");
			writeNat(writer, d.nExpectedTypeArgs);
			writeStatic(writer, " type args, but got ");
			writeNat(writer, d.nActualTypeArgs);
		});
}

void showDiagnostic(
	ref TempAlloc tempAlloc,
	ref Writer writer,
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	ref immutable ShowDiagOptions options,
	ref immutable FilesInfo fi,
	ref immutable Diagnostic d,
) {
	writeFileAndRange(writer, allPaths, pathsInfo, options, fi, d.where);
	writeChar(writer, ' ');
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
		case Token.atLess:
			return "unexpected '@<'";
		case Token.body:
			return "unexpected keyword 'body'";
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
		case Token.sendable:
			return "unexpected keyword 'sendable'";
		case Token.spec:
			return "unexpected keyword 'spec'";
		case Token.summon:
			return "unexpected keyword 'summon'";
		case Token.test:
			return "unexpected keyword 'test'";
		case Token.trusted:
			return "unexpected keyword 'trusted'";
		case Token.underscore:
			return "unexpected '_'";
		case Token.union_:
			return "unexpected keyword 'union'";
		case Token.unsafe:
			return "unexpected keyword 'unsafe'";
		case Token.unless:
			return "unexpected keyword 'unless'";
	}
}
