module frontend.showDiag;

@safe @nogc pure nothrow:

import diag : Diagnostic, Diag, Diagnostics, Diags, FilesInfo, matchDiag, TypeKind, writeFileAndRange;
import frontend.lang : nozeExtension;
import model :
	arity,
	bestCasePurity,
	CalledDecl,
	comparePathAndStorageKind,
	decl,
	FunDecl,
	getAbsolutePath,
	matchCalledDecl,
	Module,
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
import parseDiag : matchParseDiag, ParseDiag;

import util.bools : Bool, not, True;
import util.collection.arr : Arr, empty, only, range, size;
import util.collection.arrUtil : exists, map, sort;
import util.collection.dict : mustGetAt;
import util.collection.fullIndexDict : fullIndexDictGet;
import util.collection.str : CStr, emptyStr, Str;
import util.diff : diffSymbols;
import util.lineAndColumnGetter : lineAndColumnAtPos, LineAndColumnGetter;
import util.opt : force, has;
import util.path : PathAndStorageKind, pathToStr;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.sourceRange : FileAndRange, FileIndex, FilePaths;
import util.sym : Sym, writeSym;
import util.util : todo;
import util.writer :
	finishWriter,
	finishWriterToCStr,
	writeBold,
	writeChar,
	writeEscapedChar,
	writeHyperlink,
	writeNat,
	writeQuotedStr,
	writeRed,
	writeReset,
	writeStatic,
	writeStr,
	writeWithCommas,
	Writer;
import util.writerUtils : showChar, writeName, writeNl, writePathAndStorageKind, writeRangeWithinFile, writeRelPath;

immutable(CStr) cStrOfDiagnostics(Alloc)(ref Alloc alloc, ref immutable Diagnostics diagnostics) {
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	immutable FilePaths filePaths = diagnostics.filesInfo.filePaths;
	immutable Diags sorted = sort!(Diagnostic, Alloc)(
		alloc,
		diagnostics.diagnostics,
		(ref immutable Diagnostic a, ref immutable Diagnostic b) =>
			// TOOD: sort by file position too
			comparePathAndStorageKind(
				fullIndexDictGet(filePaths, a.where.fileIndex),
				fullIndexDictGet(filePaths, b.where.fileIndex)));
	foreach (ref immutable Diagnostic d; sorted.range)
		showDiagnostic(alloc, writer, diagnostics.filesInfo, d);
	return finishWriterToCStr(writer);
}

public immutable(Str) strOfParseDiag(Alloc)(ref Alloc alloc, ref immutable ParseDiag a) {
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	writeParseDiag(writer, a);
	return finishWriter(writer);
}

private:

immutable(Str) getAbsolutePathStr(Alloc)(ref Alloc alloc, ref immutable FilesInfo fi, immutable FileIndex file) {
	return ;
}

void writeLineNumber(Alloc)(
	ref Writer!Alloc writer,
	immutable FilesInfo fi,
	immutable FileAndRange range,
) {
	immutable PathAndStorageKind where = fullIndexDictGet(fi.filePaths, range.fileIndex);
	writeBold(writer);
	writePathAndStorageKind(writer, where);
	writeStatic(writer, ".nz");
	writeReset(writer);
	writeStatic(writer, " line ");
	immutable size_t line = lineAndColumnAtPos(
		fullIndexDictGet(fi.lineAndColumnGetters, range.fileIndex),
		range.range.start,
	).line;
	writeNat(writer, line + 1);
}

void writeParseDiag(Alloc)(ref Writer!Alloc writer, ref immutable ParseDiag d) {
	matchParseDiag!void(
		d,
		(ref immutable ParseDiag.CircularImport it) {
			writeStatic(writer, "circular import from ");
			writePathAndStorageKind(writer, it.from);
			writeStatic(writer, " to ");
			writePathAndStorageKind(writer, it.to);
		},
		(ref immutable ParseDiag.Expected it) {
			final switch (it.kind) {
				case ParseDiag.Expected.Kind.bodyKeyword:
					writeStatic(writer, "expected 'body'");
					break;
				case ParseDiag.Expected.Kind.closingBrace:
					writeStatic(writer, "expected '}'");
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
				writePathAndStorageKind(writer, force(d.importedFrom).path);
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
			writeStatic(writer, "expected indentation by");
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
					case ParseDiag.MatchWhenOrLambdaNeedsBlockCtx.Kind.match:
						return "'match'";
					case ParseDiag.MatchWhenOrLambdaNeedsBlockCtx.Kind.when:
						return "'when'";
					case ParseDiag.MatchWhenOrLambdaNeedsBlockCtx.Kind.lambda:
						return "lambda";
				}
			}());
			writeStatic(writer, " expression must appear in a context where it can be followed by an indented block");
		},
		(ref immutable ParseDiag.MustEndInBlankLine) {
			writeStatic(writer, "file must end in a blank line");
		},
		(ref immutable ParseDiag.RelativeImportReachesPastRoot d) {
			writeStatic(writer, "importing ");
			writeRelPath(writer, d.imported);
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
				case ParseDiag.Unexpected.Kind.else_:
					writeStatic(writer, "unexpected 'else'");
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
			writeStatic(writer, "'when' expression must end in 'else'");
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
	writeType(writer, s.returnType);
	writeChar(writer, ' ');
	writeSym(writer, s.name);
	writeChar(writer, '(');
	writeWithCommas(writer, s.params, (ref immutable Param p) {
		writeType(writer, p.type);
	});
	writeChar(writer, ')');
}

void writeCalledDecl(Alloc)(ref Writer!Alloc writer, immutable FilesInfo fi, immutable CalledDecl c) {
	writeSig(writer, c.sig);
	return matchCalledDecl(
		c,
		(immutable Ptr!FunDecl funDecl) {
			writeStatic(writer, " (from ");
			writeLineNumber(writer, fi, range(funDecl));
			writeChar(writer, ')');
		},
		(ref immutable SpecSig specSig) {
			writeStatic(writer, " (from spec ");
			writeName(writer, specSig.specInst.name);
			writeChar(writer, ')');
		});
}

void writeCalledDecls(Alloc)(
	ref Writer!Alloc writer,
	ref immutable FilesInfo fi,
	ref immutable Arr!CalledDecl cs,
	scope immutable(Bool) delegate(ref immutable CalledDecl) @safe @nogc pure nothrow filter,
) {
	foreach (ref immutable CalledDecl c; cs.range)
		if (filter(c)) {
			writeNl(writer);
			writeCalledDecl(writer, fi, c);
		}
}

void writeCalledDecls(Alloc)(ref Writer!Alloc writer, ref immutable FilesInfo fi, ref immutable Arr!CalledDecl cs) {
	writeCalledDecls(writer, fi, cs, (ref immutable CalledDecl) => True);
}

void writeCallNoMatch(Alloc)(ref Writer!Alloc writer, ref immutable FilesInfo fi, ref immutable Diag.CallNoMatch d) {
	immutable Bool someCandidateHasCorrectNTypeArgs = Bool(
		d.actualNTypeArgs == 0 ||
		exists(d.allCandidates, (ref immutable CalledDecl c) =>
			immutable Bool(nTypeParams(c) == d.actualNTypeArgs)));
	immutable Bool someCandidateHasCorrectArity = exists(d.allCandidates, (ref immutable CalledDecl c) =>
		immutable Bool(
			(d.actualNTypeArgs == 0 || nTypeParams(c) == d.actualNTypeArgs) &&
			arity(c) == d.actualArity));

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
		writeCalledDecls(writer, fi, d.allCandidates);
	} else {
		writeStatic(writer, "there are functions named ");
		writeName(writer, d.funName);
		writeStatic(writer, ", but they do not match the ");
		immutable Bool hasRet = has(d.expectedReturnType);
		immutable Bool hasArgs = not(empty(d.actualArgTypes));
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
			writeWithCommas(writer, d.actualArgTypes, (ref immutable Type t) {
				writeType(writer, t);
			});
			if (size(d.actualArgTypes) < d.actualArity)
				writeStatic(writer, " (other arguments not checked, gave up early)");
		}
		writeStatic(writer, "\ncandidates (with ");
		writeNat(writer, d.actualArity);
		writeStatic(writer, " arguments):");
		writeCalledDecls(writer, fi, d.allCandidates, (ref immutable CalledDecl c) {
			return immutable Bool(arity(c) == d.actualArity);
		});
	}
}

void writeDiag(TempAlloc, Alloc)(
	ref TempAlloc tempAlloc,
	ref Writer!Alloc writer,
	ref immutable FilesInfo fi,
	ref immutable Diag d,
) {
	matchDiag!void(
		d,
		(ref immutable Diag.CallMultipleMatches d) {
			writeStatic(writer, "cannot choose an overload of ");
			writeName(writer, d.funName);
			writeStatic(writer, ". multiple functions match:");
			writeCalledDecls(writer, fi, d.matches);
		},
		(ref immutable Diag.CallNoMatch d) {
			writeCallNoMatch(writer, fi, d);
		},
		(ref immutable Diag.CantCall c) {
			immutable string descr = () {
				final switch (c.reason) {
					case Diag.CantCall.Reason.nonNoCtx:
						return "a 'noctx' fun can't call a non-'noctx' fun";
					case Diag.CantCall.Reason.summon:
						return "a non-'summon' fun can't call a 'summon' fun";
					case Diag.CantCall.Reason.unsafe:
						return "a non-'trusted' and non-'unsafe' fun can't call an 'unsafe' fun";
				}
			}();
			writeStatic(writer, descr);
			writeStatic(writer, "\ncalling: ");
			writeName(writer, c.callee.name);
			writeStatic(writer, "\ncaller: ");
			writeName(writer, c.caller.name);
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
		(ref immutable Diag.CommonTypesMissing d) {
			writeStatic(writer, "common types are missing from 'include.nz':");
			foreach (immutable Str s; range(d.missing)) {
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
			immutable Arr!Sym expected = map(tempAlloc, d.fields, (ref immutable RecordField f) {
				return f.name;
			});
			diffSymbols(tempAlloc, writer, expected, d.providedFieldNames);
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
		(ref immutable Diag.DuplicateImports d) {
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
		(ref immutable Diag.LambdaCantInferParamTypes) {
			writeStatic(writer, "can't infer parameter types for lambda.\nconsider prefixing with 'as<...>:'");
		},
		(ref immutable Diag.LambdaClosesOverMut d) {
			writeStatic(writer, "lambda is a plain 'fun' but closes over ");
			writeName(writer, d.field.name);
			writeStatic(writer, " of of 'mut' type ");
			writeType(writer, d.field.type);
			writeStatic(writer, " (should it be a 'fun-mut'?)");
		},
		(ref immutable Diag.LambdaForFunPtrHasClosure d) {
			writeStatic(writer, "lambda closes over ");
			writeName(writer, d.field.name);
			writeStatic(writer, "; a lambda for a 'fun-ptr' is not allowed to close over anything");
		},
		(ref immutable Diag.LambdaWrongNumberParams d) {
			writeStatic(writer, "expected a ");
			writeStructInst(writer, d.expectedLambdaType);
			writeStatic(writer, " but lambda has ");
			writeNat(writer, d.actualNParams);
			writeStatic(writer, " parameters");
		},
		(ref immutable Diag.LocalShadowsPrevious d) {
			writeName(writer, d.name);
			writeStatic(writer, " is already in scope");
		},
		(ref immutable Diag.MatchCaseStructNamesDoNotMatch d) {
			writeStatic(writer, "expected the case names to be: ");
			writeWithCommas(writer, d.unionMembers, (ref immutable Ptr!StructInst i) {
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
			writeParseDiag(writer, pd);
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
		(ref immutable Diag.SpecImplHasSpecs d) {
			writeStatic(writer, "spec implementation ");
			writeName(writer, d.funName);
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
		(ref immutable Diag.WriteToNonExistentField d) {
			writeStatic(writer, "type ");
			writeType(writer, d.targetType);
			writeStatic(writer, " has no field ");
			writeName(writer, d.fieldName);
		},
		(ref immutable Diag.WriteToNonMutableField d) {
			writeStatic(writer, "field ");
			writeName(writer, d.field.name);
			writeStatic(writer, " is not mutable");
		},
		(ref immutable Diag.WrongNumberNewStructArgs d) {
			writeStatic(writer, "record type ");
			writeSym(writer, d.decl.name);
			writeStatic(writer, " has ");
			writeNat(writer, d.nExpectedArgs);
			writeStatic(writer, " fields, but got ");
			writeNat(writer, d.nActualArgs);
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

void showDiagnostic(TempAlloc, Alloc)(
	ref TempAlloc tempAlloc,
	ref Writer!Alloc writer,
	ref immutable FilesInfo fi,
	ref immutable Diagnostic d,
) {
	writeFileAndRange(tempAlloc, writer, fi, d.where);
	writeChar(writer, ' ');
	writeDiag(tempAlloc, writer, fi, d.diag);
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
