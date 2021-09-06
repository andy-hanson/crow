module frontend.showDiag;

@safe @nogc pure nothrow:

import model.diag : Diagnostic, Diag, Diags, FilesInfo, matchDiag, TypeKind, writeFileAndRange;
import model.model :
	arity,
	bestCasePurity,
	CalledDecl,
	decl,
	FunDecl,
	matchCalledDecl,
	name,
	nTypeParams,
	Param,
	Purity,
	range,
	RecordField,
	sig,
	Sig,
	SpecBody,
	SpecSig,
	StructInst,
	symOfPurity,
	Type,
	writeStructInst,
	writeType;
import model.parseDiag : EqLikeKind, matchParseDiag, ParseDiag;
import util.collection.arr : empty, only, size;
import util.collection.arrUtil : exists, map, sort;
import util.collection.fullIndexDict : fullIndexDictGet;
import util.diff : diffSymbols;
import util.lineAndColumnGetter : lineAndColumnAtPos;
import util.opt : force, has;
import util.path : AllPaths, baseName, comparePathAndStorageKind, PathAndStorageKind;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.sourceRange : FileAndRange, FilePaths;
import util.sym : Sym, writeSym;
import util.writer :
	finishWriter,
	writeBold,
	writeChar,
	writeEscapedChar,
	writeNat,
	writeQuotedStr,
	writeReset,
	writeStatic,
	writeStr,
	writeWithCommas,
	writeWithNewlines,
	Writer;
import util.writerUtils : showChar, writeName, writeNl, writePathAndStorageKind, writeRelPath;

struct ShowDiagOptions {
	immutable bool color;
}

immutable(string) strOfDiagnostics(Alloc, PathAlloc)(
	ref Alloc alloc,
	ref const AllPaths!PathAlloc allPaths,
	ref immutable ShowDiagOptions options,
	ref immutable FilesInfo filesInfo,
	ref immutable Diags diagnostics,
) {
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	immutable FilePaths filePaths = filesInfo.filePaths;
	immutable Diags sorted = sort!(Diagnostic, Alloc)(
		alloc,
		diagnostics,
		(ref immutable Diagnostic a, ref immutable Diagnostic b) =>
			// TOOD: sort by file position too
			comparePathAndStorageKind(
				fullIndexDictGet(filePaths, a.where.fileIndex),
				fullIndexDictGet(filePaths, b.where.fileIndex)));
	writeWithNewlines!Diagnostic(writer, sorted, (ref immutable Diagnostic it) {
		showDiagnostic(alloc, writer, allPaths, options, filesInfo, it);
	});
	return finishWriter(writer);
}

public immutable(string) strOfParseDiag(Alloc, PathAlloc)(
	ref Alloc alloc,
	ref const AllPaths!PathAlloc allPaths,
	ref immutable ShowDiagOptions options,
	ref immutable ParseDiag a,
) {
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	writeParseDiag(writer, allPaths, a);
	return finishWriter(writer);
}

private:

void writeLineNumber(Alloc, PathAlloc)(
	ref Writer!Alloc writer,
	ref const AllPaths!PathAlloc allPaths,
	ref immutable ShowDiagOptions options,
	immutable FilesInfo fi,
	immutable FileAndRange range,
) {
	immutable PathAndStorageKind where = fullIndexDictGet(fi.filePaths, range.fileIndex);
	if (options.color)
		writeBold(writer);
	writePathAndStorageKind(writer, allPaths, where);
	writeStatic(writer, ".crow");
	if (options.color)
		writeReset(writer);
	writeStatic(writer, " line ");
	immutable size_t line = lineAndColumnAtPos(
		fullIndexDictGet(fi.lineAndColumnGetters, range.fileIndex),
		range.range.start,
	).line;
	writeNat(writer, line + 1);
}

void writeParseDiag(Alloc, PathAlloc)(
	ref Writer!Alloc writer,
	ref const AllPaths!PathAlloc allPaths,
	ref immutable ParseDiag d,
) {
	matchParseDiag!void(
		d,
		(ref immutable ParseDiag.CantPrecedeEqLike it) {
			writeStatic(writer, "this expression can't appear in front of '");
			final switch (it.kind) {
				case EqLikeKind.equals:
					writeStatic(writer, "=");
					break;
				case EqLikeKind.mutEquals:
					writeStatic(writer, ":=");
					break;
				case EqLikeKind.optEquals:
					writeStatic(writer, "?=");
					break;
				case EqLikeKind.then:
					writeStatic(writer, "<-");
					break;
			}
			writeChar(writer, '\'');
		},
		(ref immutable ParseDiag.CircularImport it) {
			writeStatic(writer, "circular import from ");
			writePathAndStorageKind(writer, allPaths, it.from);
			writeStatic(writer, " to ");
			writePathAndStorageKind(writer, allPaths, it.to);
		},
		(ref immutable ParseDiag.Expected it) {
			final switch (it.kind) {
				case ParseDiag.Expected.Kind.bodyKeyword:
					writeStatic(writer, "expected 'body'");
					break;
				case ParseDiag.Expected.Kind.closingBrace:
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
				case ParseDiag.Expected.Kind.indent:
					writeStatic(writer, "expected an indent");
					break;
				case ParseDiag.Expected.Kind.multiLineArrSeparator:
				case ParseDiag.Expected.Kind.multiLineNewSeparator:
					writeStatic(writer, "'. '");
					break;
				case ParseDiag.Expected.Kind.purity:
					//TODO: better message
					writeStatic(writer, "after trailing space, expected to parse 'mutable' or 'sendable'");
					break;
				case ParseDiag.Expected.Kind.quote:
					writeStatic(writer, "expected '\"'");
					break;
				case ParseDiag.Expected.Kind.space:
					writeStatic(writer, "expected a space");
					break;
				case ParseDiag.Expected.Kind.typeArgsEnd:
					writeStatic(writer, "expected '>'");
					break;
				case ParseDiag.Expected.Kind.typeParamQuestionMark:
					writeStatic(writer, "expected type parameter name to start with '?'");
			}
		},
		(ref immutable ParseDiag.FileDoesNotExist d) {
			writeStatic(writer, "file does not exist");
			if (has(d.importedFrom)) {
				writeStatic(writer, " (imported from ");
				writePathAndStorageKind(writer, allPaths, force(d.importedFrom).path);
				writeChar(writer, ')');
			}
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
		(ref immutable ParseDiag.MatchWhenOrLambdaNeedsBlockCtx it) {
			writeStatic(writer, () {
				final switch (it.kind) {
					case ParseDiag.MatchWhenOrLambdaNeedsBlockCtx.Kind.if_:
						return "'if'";
					case ParseDiag.MatchWhenOrLambdaNeedsBlockCtx.Kind.match:
						return "'match'";
					case ParseDiag.MatchWhenOrLambdaNeedsBlockCtx.Kind.lambda:
						return "lambda";
				}
			}());
			writeStatic(writer, " expression must appear in a context where it can be followed by an indented block");
		},
		(ref immutable ParseDiag.RelativeImportReachesPastRoot d) {
			writeStatic(writer, "importing ");
			writeRelPath(writer, allPaths, d.imported);
			writeStatic(writer, " reaches above the source directory");
			//TODO: recommend a compiler option to fix this
		},
		(ref immutable ParseDiag.ReservedName d) {
			writeName(writer, d.name);
			writeStatic(writer, " is a reserved word and can't be used as a name");
		},
		(ref immutable ParseDiag.TypeParamCantHaveTypeArgs) {
			writeStatic(writer, "a type parameter can't have type arguments");
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
		(ref immutable ParseDiag.UnionCantBeEmpty) {
			writeStatic(writer, "union type can't be empty");
		},
		(ref immutable ParseDiag.WhenMustHaveElse) {
			writeStatic(writer, "'if' expression must end in 'else'");
		});
}

void writePurity(Alloc)(ref Writer!Alloc writer, immutable Purity p) {
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

void writeSig(Alloc)(ref Writer!Alloc writer, ref immutable Sig s) {
	writeSym(writer, s.name);
	writeChar(writer, ' ');
	writeType(writer, s.returnType);
	writeChar(writer, '(');
	writeWithCommas!Param(writer, s.params, (ref immutable Param p) {
		writeType(writer, p.type);
	});
	writeChar(writer, ')');
}

void writeCalledDecl(Alloc, PathAlloc)(
	ref Writer!Alloc writer,
	ref const AllPaths!PathAlloc allPaths,
	ref immutable ShowDiagOptions options,
	immutable FilesInfo fi,
	immutable CalledDecl c,
) {
	writeSig(writer, c.sig);
	return matchCalledDecl(
		c,
		(immutable Ptr!FunDecl funDecl) {
			writeFunDeclLocation(writer, allPaths, options, fi, funDecl);
		},
		(ref immutable SpecSig specSig) {
			writeStatic(writer, " (from spec ");
			writeName(writer, specSig.specInst.name);
			writeChar(writer, ')');
		});
}

void writeFunDeclLocation(Alloc, PathAlloc)(
	ref Writer!Alloc writer,
	ref const AllPaths!PathAlloc allPaths,
	ref immutable ShowDiagOptions options,
	immutable FilesInfo fi,
	immutable Ptr!FunDecl funDecl,
) {
	writeStatic(writer, " (from ");
	writeLineNumber(writer, allPaths, options, fi, range(funDecl));
	writeChar(writer, ')');
}

void writeCalledDecls(Alloc, PathAlloc)(
	ref Writer!Alloc writer,
	ref const AllPaths!PathAlloc allPaths,
	ref immutable ShowDiagOptions options,
	ref immutable FilesInfo fi,
	ref immutable CalledDecl[] cs,
	scope immutable(bool) delegate(ref immutable CalledDecl) @safe @nogc pure nothrow filter,
) {
	foreach (ref immutable CalledDecl c; cs)
		if (filter(c)) {
			writeNl(writer);
			writeChar(writer, '\t');
			writeCalledDecl(writer, allPaths, options, fi, c);
		}
}

void writeCalledDecls(Alloc, PathAlloc)(
	ref Writer!Alloc writer,
	ref const AllPaths!PathAlloc allPaths,
	ref immutable ShowDiagOptions options,
	ref immutable FilesInfo fi,
	ref immutable CalledDecl[] cs,
) {
	writeCalledDecls(writer, allPaths, options, fi, cs, (ref immutable CalledDecl) => true);
}

void writeCallNoMatch(Alloc, PathAlloc)(
	ref Writer!Alloc writer,
	ref const AllPaths!PathAlloc allPaths,
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
		arity(c) == d.actualArity);

	if (empty(d.allCandidates)) {
		writeStatic(writer, "there is no function ");
		if (d.actualArity == 0)
			// If there is no local variable by that name we try a call,
			// but message should reflect that the user might not have wanted a call.
			writeStatic(writer, "or variable ");
		else if (d.actualArity == 1)
			writeStatic(writer, "or field ");
		writeStatic(writer, "named ");
		writeName(writer, d.funName);

		if (size(d.actualArgTypes) == 1) {
			writeStatic(writer, "\nargument type: ");
			writeType(writer, only(d.actualArgTypes));
		}
	} else if (!someCandidateHasCorrectArity) {
		writeStatic(writer, "there are functions named ");
		writeName(writer, d.funName);
		writeStatic(writer, ", but none takes ");
		if (someCandidateHasCorrectNTypeArgs) {
			writeNat(writer, d.actualArity);
		} else {
			writeNat(writer, d.actualNTypeArgs);
			writeStatic(writer, " type");
		}
		writeStatic(writer, " arguments. candidates:");
		writeCalledDecls(writer, allPaths, options, fi, d.allCandidates);
	} else {
		writeStatic(writer, "there are functions named ");
		writeName(writer, d.funName);
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
			writeType(writer, force(d.expectedReturnType));
		}
		if (hasArgs) {
			writeStatic(writer, "\nactual argument types: ");
			writeWithCommas!Type(writer, d.actualArgTypes, (ref immutable Type t) {
				writeType(writer, t);
			});
			if (size(d.actualArgTypes) < d.actualArity)
				writeStatic(writer, " (other arguments not checked, gave up early)");
		}
		writeStatic(writer, "\ncandidates (with ");
		writeNat(writer, d.actualArity);
		writeStatic(writer, " arguments):");
		writeCalledDecls(writer, allPaths, options, fi, d.allCandidates, (ref immutable CalledDecl c) =>
			arity(c) == d.actualArity);
	}
}

void writeDiag(TempAlloc, Alloc, PathAlloc)(
	ref TempAlloc tempAlloc,
	ref Writer!Alloc writer,
	ref const AllPaths!PathAlloc allPaths,
	ref immutable ShowDiagOptions options,
	ref immutable FilesInfo fi,
	ref immutable Diag d,
) {
	matchDiag!void(
		d,
		(ref immutable Diag.CallMultipleMatches d) {
			writeStatic(writer, "cannot choose an overload of ");
			writeName(writer, d.funName);
			writeStatic(writer, ". multiple functions match:");
			writeCalledDecls(writer, allPaths, options, fi, d.matches);
		},
		(ref immutable Diag.CallNoMatch d) {
			writeCallNoMatch(writer, allPaths, options, fi, d);
		},
		(ref immutable Diag.CantCall it) {
			immutable string descr = () {
				final switch (it.reason) {
					case Diag.CantCall.Reason.nonNoCtx:
						return "'noctx' fun can't call non-'noctx' fun";
					case Diag.CantCall.Reason.summon:
						return "non-'summon' fun can't call 'summon' fun";
					case Diag.CantCall.Reason.unsafe:
						return "non-'trusted' and non-'unsafe' fun can't call 'unsafe' fun";
				}
			}();
			writeStatic(writer, descr);
			writeChar(writer, ' ');
			writeName(writer, it.callee.name);
		},
		(ref immutable Diag.CantCreateNonRecordType d) {
			writeStatic(writer, "non-record type ");
			writeType(writer, d.type);
			writeStatic(writer, " can't be constructed");
		},
		(ref immutable Diag.CantCreateRecordWithoutExpectedType) {
			writeStatic(writer, "don't know what to 'new' (maybe provide a type argument)");
		},
		(ref immutable Diag.CantInferTypeArguments) {
			writeStatic(writer, "can't infer type arguments");
		},
		(ref immutable Diag.CommonFunMissing it) {
			writeStatic(writer, "common function ");
			writeName(writer, it.name);
			writeStatic(writer, " is missing from 'bootstrap.crow'");
		},
		(ref immutable Diag.CommonTypesMissing d) {
			writeStatic(writer, "common types are missing from 'bootstrap.crow':");
			foreach (immutable string s; d.missing) {
				writeStatic(writer, "\n\t");
				writeStr(writer, s);
			}
		},
		(ref immutable Diag.CreateArrNoExpectedType) {
			writeStatic(writer, "can't infer element type of array, please provide a type argument to 'new-arr'");
		},
		(ref immutable Diag.CreateRecordByRefNoCtx d) {
			writeStatic(writer, "the current function is 'noctx' and record ");
			writeName(writer, d.struct_.name);
			writeStatic(writer, " is not marked 'by-val'; can't allocate");
		},
		(ref immutable Diag.CreateRecordMultiLineWrongFields d) {
			writeStatic(writer, "didn't get expected fields of ");
			writeName(writer, d.decl.name);
			writeChar(writer, ':');
			immutable Sym[] expected = map(tempAlloc, d.fields, (ref immutable RecordField it) => it.name);
			diffSymbols(tempAlloc, writer, options.color, expected, d.providedFieldNames);
		},
		(ref immutable Diag.DuplicateDeclaration d) {
			writeStatic(writer, "duplicate ");
			final switch (d.kind) {
				case Diag.DuplicateDeclaration.Kind.structOrAlias:
					writeStatic(writer, "struct");
					break;
				case Diag.DuplicateDeclaration.Kind.spec:
					writeStatic(writer, "spec");
					break;
				case Diag.DuplicateDeclaration.Kind.field:
					writeStatic(writer, "field");
					break;
				case Diag.DuplicateDeclaration.Kind.unionMember:
					writeStatic(writer, "member");
					break;
			}
			writeChar(writer, ' ');
			writeName(writer, d.name);
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
			writeName(writer, d.name);
		},
		(ref immutable Diag.DuplicateImports d) {
			//TODO: use d.kind
			writeStatic(writer, "the symbol ");
			writeName(writer, d.name);
			writeStatic(writer, " appears in multiple modules");
		},
		(ref immutable Diag.ExpectedTypeIsNotALambda d) {
			if (has(d.expectedType)) {
				writeStatic(writer, "the expected type at the lambda is ");
				writeType(writer, force(d.expectedType));
				writeStatic(writer, ", which is not a lambda type");
			} else
				writeStatic(writer, "there is no expected type at this location; lambdas need an expected type");
		},
		(ref immutable Diag.ExternPtrHasTypeParams) {
			writeStatic(writer, "an 'extern-ptr' type should not be a template");
		},
		(ref immutable Diag.IfNeedsOpt d) {
			writeStatic(writer, "Expected an 'opt', but got ");
			writeType(writer, d.actualType);
		},
		(ref immutable Diag.IfWithoutElse d) {
			writeStatic(writer, "'if' without 'else' should be 'void' or 'opt'. Instead got ");
			writeType(writer, d.thenType);
			writeChar(writer, '.');
		},
		(ref immutable Diag.ImportRefersToNothing it) {
			writeStatic(writer, "imported name ");
			writeName(writer, it.name);
			writeStatic(writer, " does not refer to anything");
		},
		(ref immutable Diag.LambdaCantInferParamTypes) {
			writeStatic(writer, "can't infer parameter types for lambda.\nconsider prefixing with 'as<...>:'");
		},
		(ref immutable Diag.LambdaClosesOverMut d) {
			writeStatic(writer, "lambda is a plain 'fun' but closes over ");
			writeName(writer, d.field.name);
			writeStatic(writer, " of 'mut' type ");
			writeType(writer, d.field.type);
			writeStatic(writer, " (should it be an 'act' or 'ref' fun?)");
		},
		(ref immutable Diag.LambdaWrongNumberParams d) {
			writeStatic(writer, "expected a ");
			writeStructInst(writer, d.expectedLambdaType);
			writeStatic(writer, " but lambda has ");
			writeNat(writer, d.actualNParams);
			writeStatic(writer, " parameters");
		},
		(ref immutable Diag.LiteralOverflow d) {
			writeStatic(writer, "literal exceeds the range of a ");
			writeStructInst(writer, d.type);
		},
		(ref immutable Diag.LocalShadowsPrevious d) {
			writeName(writer, d.name);
			writeStatic(writer, " is already in scope");
		},
		(ref immutable Diag.MatchCaseStructNamesDoNotMatch d) {
			writeStatic(writer, "expected the case names to be: ");
			writeWithCommas!(Ptr!StructInst)(writer, d.unionMembers, (ref immutable Ptr!StructInst i) {
				writeName(writer, decl(i).name);
			});
		},
		(ref immutable Diag.MatchOnNonUnion d) {
			writeStatic(writer, "can't match on non-union type ");
			writeType(writer, d.type);
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
					case Diag.NameNotFound.Kind.typeParam:
						return "type parameter";
				}
			}();
			writeStatic(writer, kind);
			writeStatic(writer, " name not found: ");
			writeName(writer, d.name);
		},
		(ref immutable Diag.ParamShadowsPrevious d) {
			immutable string message = () {
				final switch (d.kind) {
					case Diag.ParamShadowsPrevious.Kind.param:
						return "there is already a parameter named ";
					case Diag.ParamShadowsPrevious.Kind.typeParam:
						return "there is already a type parameter named ";
				}
			}();
			writeStatic(writer, message);
			writeName(writer, d.name);
		},
		(ref immutable ParseDiag pd) {
			writeParseDiag(writer, allPaths, pd);
		},
		(ref immutable Diag.PurityOfFieldWorseThanRecord d) {
			writeStatic(writer, "struct ");
			writeName(writer, d.strukt.name);
			writeStatic(writer, " has purity ");
			writePurity(writer, d.strukt.purity);
			writeStatic(writer, ", but field type ");
			writeType(writer, d.fieldType);
			writeStatic(writer, " has purity ");
			writePurity(writer, d.fieldType.bestCasePurity());
		},
		(ref immutable Diag.PurityOfMemberWorseThanUnion d) {
			writeStatic(writer, "union ");
			writeName(writer, d.strukt.name);
			writeStatic(writer, " has purity ");
			writePurity(writer, d.strukt.purity);
			writeStatic(writer, ", but member type ");
			writeStructInst(writer, d.member);
			writeStatic(writer, " has purity ");
			writePurity(writer, d.member.bestCasePurity);
		},
		(ref immutable Diag.PuritySpecifierRedundant d) {
			writeStatic(writer, "redundant purity specifier of ");
			writeName(writer, symOfPurity(d.purity));
			writeStatic(writer, " is already the default for ");
			writeStatic(writer, aOrAnTypeKind(d.typeKind));
			writeStatic(writer, " type");
		},
		(ref immutable Diag.SendFunDoesNotReturnFut d) {
			writeStatic(writer, "a fun-ref should return a fut, but returns ");
			writeType(writer, d.actualReturnType);
		},
		(ref immutable Diag.SpecBuiltinNotSatisfied d) {
			writeStatic(writer, "trying to call ");
			writeName(writer, d.called.deref.name);
			writeStatic(writer, ", but ");
			writeType(writer, d.type);
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
			writeName(writer, d.sigName);
			writeChar(writer, ':');
			writeCalledDecls(writer, allPaths, options, fi, d.matches);
		},
		(ref immutable Diag.SpecImplHasSpecs d) {
			writeStatic(writer, "calling ");
			writeName(writer, name(d.outerCalled));
			writeStatic(writer, ", spec implementation for ");
			writeName(writer, name(d.specImpl));
			writeFunDeclLocation(writer, allPaths, options, fi, d.specImpl);
			writeStatic(writer, " has specs itself; currently this is not allowed");
		},
		(ref immutable Diag.SpecImplNotFound d) {
			writeStatic(writer, "no implementation was found for spec signature ");
			writeName(writer, d.sigName);
		},
		(ref immutable Diag.TypeConflict d) {
			writeStatic(writer, "the type of the expression conflicts with its expected type.\n\texpected: ");
			writeType(writer, d.expected);
			writeStatic(writer, "\n\tactual: ");
			writeType(writer, d.actual);
		},
		(ref immutable Diag.TypeNotSendable) {
			writeStatic(writer, "this type is not sendable and should not appear in an interface");
		},
		(ref immutable Diag.UnusedImport it) {
			if (has(it.importedName)) {
				writeStatic(writer, "imported name ");
				writeSym(writer, force(it.importedName));
			} else {
				writeStatic(writer, "imported module ");
				// TODO: helper fn
				immutable string moduleName =
					baseName(allPaths, fullIndexDictGet(fi.filePaths, it.importedModule.fileIndex).path);
				writeStr(writer, moduleName);
			}
			writeStatic(writer, " is unused");
		},
		(ref immutable Diag.UnusedLocal it) {
			writeStatic(writer, "local ");
			writeSym(writer, it.local.name);
			writeStatic(writer, " is unused");
		},
		(ref immutable Diag.UnusedParam it) {
			writeStatic(writer, "parameter ");
			writeSym(writer, force(it.param.name));
			writeStatic(writer, " is unused");
		},
		(ref immutable Diag.UnusedPrivateFun it) {
			writeStatic(writer, "private function ");
			writeSym(writer, name(it.fun));
			writeStatic(writer, " is unused");
		},
		(ref immutable Diag.UnusedPrivateSpec it) {
			writeStatic(writer, "private spec ");
			writeSym(writer, it.spec.name);
			writeStatic(writer, " is unused");
		},
		(ref immutable Diag.UnusedPrivateStruct it) {
			writeStatic(writer, "private type ");
			writeSym(writer, it.struct_.name);
			writeStatic(writer, " is unused");
		},
		(ref immutable Diag.UnusedPrivateStructAlias it) {
			writeStatic(writer, "private type ");
			writeSym(writer, it.alias_.name);
			writeStatic(writer, " is unused");
		},
		(ref immutable Diag.WrongNumberTypeArgsForSpec d) {
			writeName(writer, d.decl.name);
			writeStatic(writer, " expected to get ");
			writeNat(writer, d.nExpectedTypeArgs);
			writeStatic(writer, " type args, but got ");
			writeNat(writer, d.nActualTypeArgs);
		},
		(ref immutable Diag.WrongNumberTypeArgsForStruct d) {
			writeName(writer, d.decl.name);
			writeStatic(writer, " expected to get ");
			writeNat(writer, d.nExpectedTypeArgs);
			writeStatic(writer, " type args, but got ");
			writeNat(writer, d.nActualTypeArgs);
		});
}

void showDiagnostic(TempAlloc, Alloc, PathAlloc)(
	ref TempAlloc tempAlloc,
	ref Writer!Alloc writer,
	ref const AllPaths!PathAlloc allPaths,
	ref immutable ShowDiagOptions options,
	ref immutable FilesInfo fi,
	ref immutable Diagnostic d,
) {
	writeFileAndRange(writer, allPaths, options, fi, d.where);
	writeChar(writer, ' ');
	writeDiag(tempAlloc, writer, allPaths, options, fi, d.diag);
	writeNl(writer);
}

immutable(string) aOrAnTypeKind(immutable TypeKind a) {
	final switch (a) {
		case TypeKind.builtin:
			return "a builtin";
		case TypeKind.externPtr:
			return "an extern-ptr";
		case TypeKind.record:
			return "a record";
		case TypeKind.union_:
			return "a union";
	}
}
