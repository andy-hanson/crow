module frontend.showDiag;

@safe @nogc pure nothrow:

import frontend.parse.lexer : Token;
import model.diag : Diagnostic, Diag, ExpectedForDiag, FilesInfo, TypeKind, writeFileAndRange;
import model.model :
	arity,
	arityMatches,
	bestCasePurity,
	Called,
	CalledDecl,
	CalledSpecSig,
	decl,
	Destructure,
	EnumBackingType,
	FunDecl,
	FunDeclAndTypeArgs,
	FunInst,
	Local,
	LocalMutability,
	name,
	nTypeParams,
	Params,
	ParamShort,
	Program,
	Purity,
	range,
	ReturnAndParamTypes,
	SpecDecl,
	SpecDeclSig,
	StructInst,
	symOfPurity,
	symOfSpecBodyBuiltinKind,
	symOfVisibility,
	Type,
	typeArgs,
	TypeParam,
	TypeParamsAndSig,
	writeStructInst,
	writeTypeArgs,
	writeTypeQuoted,
	writeTypeUnquoted;
import model.parseDiag : ParseDiag;
import util.alloc.alloc : Alloc, TempAlloc;
import util.col.arr : empty, only, sizeEq;
import util.col.arrUtil : exists;
import util.col.str : SafeCStr;
import util.lineAndColumnGetter : lineAndColumnAtPos, PosKind;
import util.opt : force, has, none, Opt, some;
import util.ptr : ptrTrustMe;
import util.sourceRange : FileAndPos;
import util.sym : AllSymbols, Sym, writeSym;
import util.util : unreachable, verify;
import util.writer :
	finishWriterToSafeCStr,
	writeBold,
	writeEscapedChar,
	writeQuotedStr,
	writeReset,
	writeWithCommas,
	writeWithCommasZip,
	writeWithNewlines,
	writeWithSeparator,
	Writer;
import util.uri : AllUris, baseName, Uri, UrisInfo, writeUri, writeRelPath;
import util.writerUtils : showChar, writeName, writeNl;

immutable struct ShowDiagOptions {
	bool color;
}

SafeCStr strOfDiagnostics(
	ref Alloc alloc,
	in AllSymbols allSymbols,
	in AllUris allUris,
	in UrisInfo urisInfo,
	in ShowDiagOptions options,
	in Program program,
) {
	Writer writer = Writer(ptrTrustMe(alloc));
	writeWithNewlines!Diagnostic(writer, program.diagnostics.diags, (in Diagnostic x) {
		showDiagnostic(alloc, writer, allSymbols, allUris, urisInfo, options, program, x);
	});
	return finishWriterToSafeCStr(writer);
}

SafeCStr strOfDiagnostic(
	ref Alloc alloc,
	in AllSymbols allSymbols,
	in AllUris allUris,
	in UrisInfo urisInfo,
	in ShowDiagOptions options,
	in Program program,
	in Diagnostic diagnostic,
) {
	Writer writer = Writer(ptrTrustMe(alloc));
	showDiagnostic(alloc, writer, allSymbols, allUris, urisInfo, options, program, diagnostic);
	return finishWriterToSafeCStr(writer);
}

private:

void writeUnusedDiag(
	scope ref Writer writer,
	in AllSymbols allSymbols,
	in AllUris allUris,
	in Program program,
	in Diag.Unused a,
) {
	a.kind.matchIn!void(
		(in Diag.Unused.Kind.Import x) {
			if (has(x.importedName)) {
				writer ~= "imported name ";
				writeSym(writer, allSymbols, force(x.importedName));
			} else {
				writer ~= "imported module ";
				// TODO: helper fn
				Sym moduleName = baseName(allUris, program.filesInfo.fileUris[x.importedModule.fileIndex]);
				writeSym(writer, allSymbols, moduleName);
			}
			writer ~= " is unused";
		},
		(in Diag.Unused.Kind.Local x) {
			writer ~= "local ";
			writeSym(writer, allSymbols, x.local.name);
			writer ~= (x.local.mutability == LocalMutability.immut)
				? " is unused"
				: x.usedGet
				? " is mutable but never reassigned"
				: x.usedSet
				? " is assigned to but unused"
				: " is unused";
		},
		(in Diag.Unused.Kind.PrivateDecl x) {
			writeSym(writer, allSymbols, x.name);
			writer ~= " is unused";
		});
}

void writeLineNumber(
	scope ref Writer writer,
	in AllUris allUris,
	in UrisInfo urisInfo,
	in ShowDiagOptions options,
	in FilesInfo fi,
	FileAndPos pos,
) {
	Uri where = fi.fileUris[pos.fileIndex];
	if (options.color)
		writeBold(writer);
	writeUri(writer, allUris, urisInfo, where);
	if (options.color)
		writeReset(writer);
	writer ~= " line ";
	size_t line = lineAndColumnAtPos(fi.lineAndColumnGetters[pos.fileIndex], pos.pos, PosKind.startOfRange).line;
	writer ~= line + 1;
}

void writeParseDiag(
	scope ref Writer writer,
	in AllSymbols allSymbols,
	in AllUris allUris,
	in UrisInfo urisInfo,
	in ParseDiag d,
) {
	d.matchIn!void(
		(in ParseDiag.CircularImport x) {
			writer ~= "circular import from ";
			writeUri(writer, allUris, urisInfo, x.from);
			writer ~= " to ";
			writeUri(writer, allUris, urisInfo, x.to);
		},
		(in ParseDiag.Expected it) {
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
		(in ParseDiag.FileDoesNotExist d) {
			writer ~= "file does not exist";
			if (has(d.importedFrom)) {
				writer ~= " (imported from ";
				writeUri(writer, allUris, urisInfo, force(d.importedFrom).uri);
				writer ~= ')';
			}
		},
		(in ParseDiag.FileLoading d) {
			writer ~= "loading this file...";
		},
		(in ParseDiag.FileReadError d) {
			writer ~= "unable to read file";
			if (has(d.importedFrom)) {
				writer ~= " (imported from ";
				writeUri(writer, allUris, urisInfo, force(d.importedFrom).uri);
				writer ~= ')';
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
		(in ParseDiag.IndentTooMuch it) {
			writer ~= "indented too far";
		},
		(in ParseDiag.IndentWrongCharacter d) {
			writer ~= "expected indentation by ";
			writer ~= d.expectedTabs ? "tabs" : "spaces";
			writer ~= " (based on first indented line), but here there is a ";
			writer ~= d.expectedTabs ? "space" : "tab";
		},
		(in ParseDiag.InvalidName it) {
			writeQuotedStr(writer, it.actual);
			writer ~= " is not a valid name";
		},
		(in ParseDiag.InvalidStringEscape it) {
			writer ~= "invalid escape character '";
			writeEscapedChar(writer, it.actual);
			writer ~= '\'';
		},
		(in ParseDiag.NeedsBlockCtx it) {
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
					case ParseDiag.NeedsBlockCtx.Kind.throw_:
						return "'throw'";
					case ParseDiag.NeedsBlockCtx.Kind.trusted:
						return "'trusted'";
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
		(in ParseDiag.RelativeImportReachesPastRoot d) {
			writer ~= "importing ";
			writeRelPath(writer, allUris, d.imported);
			writer ~= " reaches above the source directory";
			//TODO: recommend a compiler option to fix this
		},
		(in ParseDiag.TrailingComma) {
			writer ~= "trailing comma";
		},
		(in ParseDiag.UnexpectedCharacter u) {
			writer ~= "unexpected character '";
			showChar(writer, u.ch);
			writer ~= "'";
		},
		(in ParseDiag.UnexpectedOperator u) {
			writer ~= "unexpected '";
			writeSym(writer, allSymbols, u.operator);
			writer ~= '\'';
		},
		(in ParseDiag.UnexpectedToken u) {
			writer ~= describeTokenForUnexpected(u.token);
		},
		(in ParseDiag.WhenMustHaveElse) {
			writer ~= "'if' expression must end in 'else'";
		});
}

void writePurity(scope ref Writer writer, in AllSymbols allSymbols, Purity p) {
	writeName(writer, allSymbols, symOfPurity(p));
}

void writeSig(
	scope ref Writer writer,
	in AllSymbols allSymbols,
	in Program program,
	Sym name,
	in Type returnType,
	in Params params,
	in Opt!ReturnAndParamTypes instantiated,
) {
	writeSym(writer, allSymbols, name);
	writer ~= ' ';
	writeTypeUnquoted(writer, allSymbols, program, has(instantiated) ? force(instantiated).returnType : returnType);
	writer ~= '(';
	params.matchIn!void(
		(in Destructure[] paramsArray) {
			if (has(instantiated))
				writeWithCommasZip!(Destructure, Type)(
					writer,
					paramsArray,
					force(instantiated).paramTypes,
					(in Destructure x, in Type t) {
						writeDestructure(writer, allSymbols, program, x, some(t));
					});
			else
				writeWithCommas!Destructure(writer, paramsArray, (in Destructure x) {
					writeDestructure(writer, allSymbols, program, x, none!Type);
				});
		},
		(in Params.Varargs varargs) {
			writer ~= "...";
			writeTypeUnquoted(writer, allSymbols, program, has(instantiated)
				? only(force(instantiated).paramTypes)
				: varargs.param.type);
		});
	writer ~= ')';
}

void writeSigSimple(
	scope ref Writer writer,
	in AllSymbols allSymbols,
	in Program program,
	Sym name,
	in TypeParamsAndSig sig,
) {
	writeSym(writer, allSymbols, name);
	if (!empty(sig.typeParams)) {
		writer ~= '[';
		writeWithCommas!TypeParam(writer, sig.typeParams, (in TypeParam x) {
			writeSym(writer, allSymbols, x.name);
		});
		writer ~= ']';
	}
	writer ~= ' ';
	writeTypeUnquoted(writer, allSymbols, program, sig.returnType);
	writer ~= '(';
	writeWithCommas!ParamShort(writer, sig.params, (in ParamShort x) {
		writeSym(writer, allSymbols, x.name);
		writer ~= ' ';
		writeTypeUnquoted(writer, allSymbols, program, x.type);
	});
	writer ~= ')';
}

void writeDestructure(
	scope ref Writer writer,
	in AllSymbols allSymbols,
	in Program program,
	in Destructure a,
	in Opt!Type instantiated,
) {
	Type type = has(instantiated) ? force(instantiated) : a.type;
	a.matchIn!void(
		(in Destructure.Ignore) {
			writer ~= "_ ";
			writeTypeUnquoted(writer, allSymbols, program, type);
		},
		(in Local x) {
			writeSym(writer, allSymbols, x.name);
			writer ~= ' ';
			writeTypeUnquoted(writer, allSymbols, program, type);
		},
		(in Destructure.Split x) {
			writer ~= '(';
			writeWithCommasZip!(Destructure, Type)(
				writer, x.parts, typeArgs(*type.as!(StructInst*)), (in Destructure part, in Type partType) {
					writeDestructure(writer, allSymbols, program, part, some(partType));
				});
			writer ~= ')';
		});
}

void writeSpecTrace(
	scope ref Writer writer,
	in AllSymbols allSymbols,
	in AllUris allUris,
	in UrisInfo urisInfo,
	in ShowDiagOptions options,
	in Program program,
	in FunDeclAndTypeArgs[] trace,
) {
	foreach (FunDeclAndTypeArgs x; trace) {
		writer ~= "\n\t";
		writeFunDeclAndTypeArgs(writer, allSymbols, allUris, urisInfo, options, program, x);
	}
}

void writeFunDeclAndTypeArgs(
	scope ref Writer writer,
	in AllSymbols allSymbols,
	in AllUris allUris,
	in UrisInfo urisInfo,
	in ShowDiagOptions options,
	in Program program,
	in FunDeclAndTypeArgs a,
) {
	writeSym(writer, allSymbols, a.decl.name);
	writeTypeArgs(writer, allSymbols, program, a.typeArgs);
	writeFunDeclLocation(writer, allSymbols, allUris, urisInfo, options, program.filesInfo, *a.decl);
}

public void writeCalled(
	scope ref Writer writer,
	in AllSymbols allSymbols,
	in AllUris allUris,
	in UrisInfo urisInfo,
	in ShowDiagOptions options,
	in Program program,
	in Called a,
) {
	a.matchIn!void(
		(in FunInst x) {
			writeFunInst(writer, allSymbols, allUris, urisInfo, options, program, x);
		},
		(in CalledSpecSig x) {
			writeCalledSpecSig(writer, allSymbols, program, x);
		});
}

public void writeFunInst(
	scope ref Writer writer,
	in AllSymbols allSymbols,
	in AllUris allUris,
	in UrisInfo urisInfo,
	in ShowDiagOptions options,
	in Program program,
	in FunInst a,
) {
	writeFunDecl(writer, allSymbols, allUris, urisInfo, options, program, *decl(a));
	writeTypeParamsAndArgs(writer, allSymbols, program, decl(a).typeParams, typeArgs(a));
}

void writeCalledSpecSig(
	scope ref Writer writer,
	in AllSymbols allSymbols,
	in Program program,
	in CalledSpecSig x,
) {
	writeSig(
		writer, allSymbols, program, x.name, x.returnType,
		Params(x.nonInstantiatedSig.params), some(x.instantiatedSig));
	writer ~= " (from spec ";
	writeName(writer, allSymbols, name(*x.specInst));
	writer ~= ')';
}

void writeTypeParamsAndArgs(
	scope ref Writer writer,
	in AllSymbols allSymbols,
	in Program program,
	in TypeParam[] typeParams,
	in Type[] typeArgs,
) {
	verify(sizeEq(typeParams, typeArgs));
	if (!empty(typeParams)) {
		writer ~= " with ";
		writeWithCommasZip!(TypeParam, Type)(writer, typeParams, typeArgs, (in TypeParam param, in Type arg) {
			writeSym(writer, allSymbols, param.name);
			writer ~= '=';
			writeTypeUnquoted(writer, allSymbols, program, arg);
		});
	}
}

void writeCalledDecl(
	scope ref Writer writer,
	in AllSymbols allSymbols,
	in AllUris allUris,
	in UrisInfo urisInfo,
	in ShowDiagOptions options,
	in Program program,
	in CalledDecl a,
) {
	a.matchIn!void(
		(in FunDecl x) {
			writeFunDecl(writer, allSymbols, allUris, urisInfo, options, program, x);
		},
		(in CalledSpecSig x) {
			writeCalledSpecSig(writer, allSymbols, program, x);
		});
}

void writeFunDecl(
	scope ref Writer writer,
	in AllSymbols allSymbols,
	in AllUris allUris,
	in UrisInfo urisInfo,
	in ShowDiagOptions options,
	in Program program,
	in FunDecl a,
) {
	writeSig(writer, allSymbols, program, a.name, a.returnType, a.params, none!ReturnAndParamTypes);
	writeFunDeclLocation(writer, allSymbols, allUris, urisInfo, options, program.filesInfo, a);
}

void writeFunDeclLocation(
	scope ref Writer writer,
	in AllSymbols allSymbols,
	in AllUris allUris,
	in UrisInfo urisInfo,
	in ShowDiagOptions options,
	in FilesInfo fi,
	in FunDecl funDecl,
) {
	writer ~= " (from ";
	writeLineNumber(writer, allUris, urisInfo, options, fi, funDecl.fileAndPos);
	writer ~= ')';
}

void writeCalleds(
	scope ref Writer writer,
	in AllSymbols allSymbols,
	in AllUris allUris,
	in UrisInfo urisInfo,
	in ShowDiagOptions options,
	in Program program,
	in Called[] cs,
) {
	foreach (ref Called x; cs) {
		writeNl(writer);
		writer ~= '\t';
		writeCalled(writer, allSymbols, allUris, urisInfo, options, program, x);
	}
}

void writeCalledDecls(
	scope ref Writer writer,
	in AllSymbols allSymbols,
	in AllUris allUris,
	in UrisInfo urisInfo,
	in ShowDiagOptions options,
	in Program program,
	in CalledDecl[] cs,
	in bool delegate(in CalledDecl) @safe @nogc pure nothrow filter = (in _) => true,
) {
	foreach (ref CalledDecl c; cs)
		if (filter(c)) {
			writeNl(writer);
			writer ~= '\t';
			writeCalledDecl(writer, allSymbols, allUris, urisInfo, options, program, c);
		}
}

void writeCallNoMatch(
	scope ref Writer writer,
	in AllSymbols allSymbols,
	in AllUris allUris,
	in UrisInfo urisInfo,
	in ShowDiagOptions options,
	in Program program,
	in Diag.CallNoMatch d,
) {
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
		writeName(writer, allSymbols, d.funName);

		if (d.actualArgTypes.length == 1) {
			writer ~= "\nargument type: ";
			writeTypeQuoted(writer, allSymbols, program, only(d.actualArgTypes));
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
		writeCalledDecls(writer, allSymbols, allUris, urisInfo, options, program, d.allCandidates);
	} else {
		writer ~= "there are functions named ";
		writeName(writer, allSymbols, d.funName);
		writer ~= ", but they do not match the ";
		bool hasRet = has(d.expectedReturnType);
		bool hasArgs = empty(d.actualArgTypes);
		string descr = hasRet
			? hasArgs ? "expected return type and actual argument types" : "expected return type"
			: "actual argument types";
		writer ~= descr;
		writer ~= '.';
		if (hasRet) {
			writer ~= "\nexpected return type: ";
			writeTypeQuoted(writer, allSymbols, program, force(d.expectedReturnType));
		}
		if (hasArgs) {
			writer ~= "\nactual argument types: ";
			writeWithCommas!Type(writer, d.actualArgTypes, (in Type t) {
				writeTypeQuoted(writer, allSymbols, program, t);
			});
			if (d.actualArgTypes.length < d.actualArity)
				writer ~= " (other arguments not checked, gave up early)";
		}
		writer ~= "\ncandidates (with ";
		writer ~= d.actualArity;
		writer ~= " arguments):";
		writeCalledDecls(
			writer, allSymbols, allUris, urisInfo, options, program, d.allCandidates,
			(in CalledDecl c) =>
				arityMatches(arity(c), d.actualArity));
	}
}

void writeDiag(
	ref TempAlloc tempAlloc,
	scope ref Writer writer,
	in AllSymbols allSymbols,
	in AllUris allUris,
	in UrisInfo urisInfo,
	in ShowDiagOptions options,
	in Program program,
	in Diag d,
) {
	d.matchIn!void(
		(in Diag.AssignmentNotAllowed d) {
			writer ~= "can't assign to this kind of expression";
		},
		(in Diag.BuiltinUnsupported d) {
			writer ~= "the compiler does not implement a builtin named ";
			writeName(writer, allSymbols, d.name);
		},
		(in Diag.CallMultipleMatches d) {
			writer ~= "cannot choose an overload of ";
			writeName(writer, allSymbols, d.funName);
			writer ~= ". multiple functions match:";
			writeCalledDecls(writer, allSymbols, allUris, urisInfo, options, program, d.matches);
		},
		(in Diag.CallNoMatch d) {
			writeCallNoMatch(writer, allSymbols, allUris, urisInfo, options, program, d);
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
			writeFunDecl(writer, allSymbols, allUris, urisInfo, options, program, *x.callee);
			if (x.reason == Diag.CantCall.Reason.unsafe)
				writer ~= "\n(consider putting the call in a 'trusted' expression)";
		},
		(in Diag.CharLiteralMustBeOneChar) {
			writer ~= "value of 'char' type must be a single character";
		},
		(in Diag.CommonFunDuplicate x) {
			writer ~= "module contains multiple valid ";
			writeName(writer, allSymbols, x.name);
			writer ~= " functions";
		},
		(in Diag.CommonFunMissing x) {
			writer ~= "module should have a function:\n\t";
			writeWithSeparator!TypeParamsAndSig(writer, x.sigChoices, "\nor:\n\t", (in TypeParamsAndSig sig) {
				writeSigSimple(writer, allSymbols, program, x.name, sig);
			});
		},
		(in Diag.CommonTypeMissing d) {
			writer ~= "expected to find a type named ";
			writeName(writer, allSymbols, d.name);
			writer ~= " in this module";
		},
		(in Diag.DestructureTypeMismatch d) {
			d.expected.matchIn!void(
				(in Diag.DestructureTypeMismatch.Expected.Tuple x) {
					writer ~= "expected a tuple with ";
					writer ~= x.size;
					writer ~= " elements, but got ";
				},
				(in Type t) {
					writer ~= "expected type ";
					writeTypeQuoted(writer, allSymbols, program, t);
					writer ~= ", but got ";
				});
			writeTypeQuoted(writer, allSymbols, program, d.actual);
		},
		(in Diag.DuplicateDeclaration d) {
			string desc = () {
				final switch (d.kind) {
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
			writer ~= desc;
			writer ~= " name ";
			writeName(writer, allSymbols, d.name);
			writer ~= " is already used";
		},
		(in Diag.DuplicateExports d) {
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
		(in Diag.DuplicateImports d) {
			//TODO: use d.kind
			writer ~= "the symbol ";
			writeName(writer, allSymbols, d.name);
			writer ~= " appears in multiple modules";
		},
		(in Diag.EnumBackingTypeInvalid d) {
			writer ~= "type ";
			writeStructInst(writer, allSymbols, program, *d.actual);
			writer ~= " cannot be used to back an enum";
		},
		(in Diag.EnumDuplicateValue d) {
			writer ~= "duplicate enum value ";
			if (d.signed)
				writer ~= d.value;
			else
				writer ~= cast(ulong) d.value;
		},
		(in Diag.EnumMemberOverflows d) {
			writer ~= "enum member is not in the allowed range ";
			writer ~= minValue(d.backingType);
			writer ~= " to ";
			writer ~= maxValue(d.backingType);
		},
		(in Diag.ExpectedTypeIsNotALambda d) {
			if (has(d.expectedType)) {
				writer ~= "the expected type at the lambda is ";
				writeTypeQuoted(writer, allSymbols, program, force(d.expectedType));
				writer ~= ", which is not a lambda type";
			} else
				writer ~= "there is no expected type at this location; lambdas need an expected type";
		},
		(in Diag.ExternFunForbidden d) {
			writer ~= "'extern' function ";
			writeName(writer, allSymbols, d.fun.name);
			writer ~= () {
				final switch (d.reason) {
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
		(in Diag.ExternRecordImplicitlyByVal d) {
			writer ~= "'extern' record ";
			writeName(writer, allSymbols, d.struct_.name);
			writer ~= " is implicitly 'by-val'";
		},
		(in Diag.ExternUnion d) {
			writer ~= "a union can't be 'extern'";
		},
		(in Diag.FunMissingBody) {
			writer ~= "this function needs a body";
		},
		(in Diag.FunModifierTrustedOnNonExtern) {
			writer ~= "only 'extern' functions can be 'trusted'; otherwise 'trusted' should be used as an expression";
		},
		(in Diag.IfNeedsOpt d) {
			writer ~= "Expected an option type, but got ";
			writeTypeQuoted(writer, allSymbols, program, d.actualType);
		},
		(in Diag.ImportRefersToNothing it) {
			writer ~= "imported name ";
			writeName(writer, allSymbols, it.name);
			writer ~= " does not refer to anything";
		},
		(in Diag.LambdaCantInferParamType x) {
			writer ~= "can't infer the lambda parameter's type.";
		},
		(in Diag.LambdaClosesOverMut d) {
			writer ~= "this lambda is a 'fun' but references ";
			writeName(writer, allSymbols, d.name);
			if (has(d.type)) {
				writer ~= " of 'mut' type ";
				writeTypeQuoted(writer, allSymbols, program, force(d.type));
			} else
				writer ~= " which is 'mut'";
			writer ~= " (should it be an 'act' or 'ref' fun?)";
		},
		(in Diag.LambdaMultipleMatch x) {
			writer ~= "multiple lambda types are possible.\n";
			writeExpected(writer, allSymbols, program, x.expected);
			writer ~= "consider explicitly typing the lambda's parameter.";
		},
		(in Diag.LambdaNotExpected x) {
			if (x.expected.isA!(ExpectedForDiag.Infer))
				writer ~= "lambda expression needs an expected type";
			else {
				writer ~= "the lambda doesn't match the expected type at this location.\n";
				writeExpected(writer, allSymbols, program, x.expected);
			}
		},
		(in Diag.LinkageWorseThanContainingFun d) {
			writer ~= "'extern' function ";
			writeName(writer, allSymbols, d.containingFun.name);
			if (has(d.param)) {
				Opt!Sym paramName = force(d.param).name;
				if (has(paramName)) {
					writer ~= " parameter ";
					writeName(writer, allSymbols, force(paramName));
				}
			}
			writer ~= " can't reference non-extern type ";
			writeTypeQuoted(writer, allSymbols, program, d.referencedType);
		},
		(in Diag.LinkageWorseThanContainingType d) {
			writer ~= "extern type ";
			writeName(writer, allSymbols, d.containingType.name);
			writer ~= " can't reference non-extern type ";
			writeTypeQuoted(writer, allSymbols, program, d.referencedType);
		},
		(in Diag.LiteralAmbiguous d) {
			writer ~= "multiple possible types for literal expression: ";
			writeWithCommas!(StructInst*)(writer, d.types, (in StructInst* type) {
				writeStructInst(writer, allSymbols, program, *type);
			});
		},
		(in Diag.LiteralOverflow d) {
			writer ~= "literal exceeds the range of a ";
			writeStructInst(writer, allSymbols, program, *d.type);
		},
		(in Diag.LocalIgnoredButMutable) {
			writer ~= "unnecessary 'mut' on ignored local variable";
		},
		(in Diag.LocalNotMutable d) {
			writer ~= "local variable ";
			writeName(writer, allSymbols, name(d.local));
			writer ~= " was not marked 'mut'";
		},
		(in Diag.LoopWithoutBreak d) {
			writer ~= "'loop' has no 'break'";
		},
		(in Diag.MatchCaseNamesDoNotMatch d) {
			writer ~= "expected the case names to be: ";
			writeWithCommas!Sym(writer, d.expectedNames, (in Sym name) {
				writeName(writer, allSymbols, name);
			});
		},
		(in Diag.MatchOnNonUnion d) {
			writer ~= "can't match on non-union type ";
			writeTypeQuoted(writer, allSymbols, program, d.type);
		},
		(in Diag.ModifierConflict d) {
			writeName(writer, allSymbols, d.curModifier);
			writer ~= " conflicts with ";
			writeName(writer, allSymbols, d.prevModifier);
		},
		(in Diag.ModifierDuplicate d) {
			writer ~= "redundant ";
			writeName(writer, allSymbols, d.modifier);
		},
		(in Diag.ModifierInvalid d) {
			writeName(writer, allSymbols, d.modifier);
			writer ~= " is not supported for ";
			writer ~= aOrAnTypeKind(d.typeKind);
		},
		(in Diag.ModifierRedundantDueToModifier d) {
			writeName(writer, allSymbols, d.redundantModifier);
			writer ~= " is redundant given ";
			writeName(writer, allSymbols, d.modifier);
		},
		(in Diag.ModifierRedundantDueToTypeKind d) {
			writeName(writer, allSymbols, d.modifier);
			writer ~= " is already the default for ";
			writer ~= aOrAnTypeKind(d.typeKind);
			writer ~= " type";
		},
		(in Diag.MutFieldNotAllowed d) {
			writer ~= "field is mut, but containing record was not marked mut";
		},
		(in Diag.NameNotFound d) {
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
		(in Diag.NeedsExpectedType x) {
			writer ~= () {
				final switch (x.kind) {
					case Diag.NeedsExpectedType.Kind.loop:
						return "'loop'";
					case Diag.NeedsExpectedType.Kind.pointer:
						return "pointer";
					case Diag.NeedsExpectedType.Kind.throw_:
						return "'throw'";
				}
			}();
			writer ~= " expression needs an expected type";
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
		(in ParseDiag pd) {
			writeParseDiag(writer, allSymbols, allUris, urisInfo, pd);
		},
		(in Diag.PtrIsUnsafe) {
			writer ~= "getting a pointer is unsafe";
		},
		(in Diag.PtrMutToConst d) {
			writer ~= () {
				final switch (d.kind) {
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
		(in Diag.PurityWorseThanParent d) {
			writer ~= "struct ";
			writeName(writer, allSymbols, d.parent.name);
			writer ~= " has purity ";
			writePurity(writer, allSymbols, d.parent.purity);
			writer ~= ", but member of type ";
			writeTypeQuoted(writer, allSymbols, program, d.child);
			writer ~= " has purity ";
			writePurity(writer, allSymbols, bestCasePurity(d.child));
		},
		(in Diag.RecordNewVisibilityIsRedundant d) {
			writer ~= "the 'new' function for this record is already ";
			writeName(writer, allSymbols, symOfVisibility(d.visibility));
			writer ~= " by default";
		},
		(in Diag.SpecMatchError x) {
			x.reason.matchIn!void(
				(in Diag.SpecMatchError.Reason.MultipleMatches y) {
					writer ~= "multiple implementations found for spec signature ";
					writeName(writer, allSymbols, y.sigName);
					writer ~= ':';
					writeCalleds(writer, allSymbols, allUris, urisInfo, options, program, y.matches);
				});
			writer ~= "\n\tcalling:";
			writeSpecTrace(writer, allSymbols, allUris, urisInfo, options, program, x.trace);
		},
		(in Diag.SpecNoMatch x) {
			writer ~= "a spec was not satisfied.\n\t";
			x.reason.matchIn!void(
				(in Diag.SpecNoMatch.Reason.BuiltinNotSatisfied y) {
					writeTypeQuoted(writer, allSymbols, program, y.type);
					writer ~= " is not '";
					writeSym(writer, allSymbols, symOfSpecBodyBuiltinKind(y.kind));
					writer ~= "'";
				},
				(in Diag.SpecNoMatch.Reason.CantInferTypeArguments _) {
					writer ~= "can't infer type arguments";
				},
				(in Diag.SpecNoMatch.Reason.SpecImplNotFound y) {
					writer ~= "no implementation was found for spec signature ";
					SpecDeclSig* sig = y.sigDecl;
					writeSig(
						writer, allSymbols, program, sig.name, sig.returnType, Params(sig.params), some(y.sigType));
				},
				(in Diag.SpecNoMatch.Reason.TooDeep _) {
					writer ~= "spec instantiation is too deep";
				});
			writer ~= " calling:";
			writeSpecTrace(writer, allSymbols, allUris, urisInfo, options, program, x.trace);
		},
		(in Diag.SpecNameMissing) {
			writer ~= "spec name is missing";
		},
		(in Diag.SpecRecursion d) {
			writer ~= "spec's parents tree is too deep. trace: ";
			writeWithCommas!(immutable SpecDecl*)(writer, d.trace, (in SpecDecl* x) {
				writeName(writer, allSymbols, x.name);
			});
		},
		(in Diag.ThreadLocalError d) {
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
		(in Diag.TrustedUnnecessary d) {
			writer ~= () {
				final switch (d.reason) {
					case Diag.TrustedUnnecessary.Reason.inTrusted:
						return "'trusted' is redundant inside another 'trusted'";
					case Diag.TrustedUnnecessary.Reason.inUnsafeFunction:
						return "'trusted' has no effect inside an 'unsafe' function";
					case Diag.TrustedUnnecessary.Reason.unused:
						return "there is no unsafe code inside this 'trusted'";
				}
			}();
		},
		(in Diag.TypeAnnotationUnnecessary d) {
			writer ~= "type ";
			writeTypeQuoted(writer, allSymbols, program, d.type);
			writer ~= " was already inferred";
		},
		(in Diag.TypeConflict d) {
			writeExpected(writer, allSymbols, program, d.expected);
			writer ~= "\nactual:\n\t";
			writeTypeQuoted(writer, allSymbols, program, d.actual);
		},
		(in Diag.TypeParamCantHaveTypeArgs) {
			writer ~= "a type parameter can't take type arguments";
		},
		(in Diag.TypeShouldUseSyntax it) {
			writer ~= () {
				final switch (it.kind) {
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
			writeUnusedDiag(writer, allSymbols, allUris, program, x);
		},
		(in Diag.VarargsParamMustBeArray _) {
			writer ~= "variadic parameter must be an 'array'";
		},
		(in Diag.WrongNumberTypeArgs x) {
			writeName(writer, allSymbols, x.name);
			writer ~= " expected to get ";
			writer ~= x.nExpectedTypeArgs;
			writer ~= " type args, but got ";
			writer ~= x.nActualTypeArgs;
		});
}

void showDiagnostic(
	ref TempAlloc tempAlloc,
	scope ref Writer writer,
	in AllSymbols allSymbols,
	in AllUris allUris,
	in UrisInfo urisInfo,
	in ShowDiagOptions options,
	in Program program,
	in Diagnostic d,
) {
	writeFileAndRange(writer, allUris, urisInfo, options, program.filesInfo, d.where);
	writer ~= ' ';
	writeDiag(tempAlloc, writer, allSymbols, allUris, urisInfo, options, program, d.diag);
	writeNl(writer);
}

void writeExpected(scope ref Writer writer, in AllSymbols allSymbols, in Program program, in ExpectedForDiag a) {
	a.matchIn!void(
		(in Type[] types) {
			if (types.length == 1) {
				writer ~= "expected type: ";
				writeTypeQuoted(writer, allSymbols, program, only(types));
			} else {
				writer ~= "expected one of these types:";
				foreach (Type t; types) {
					writer ~= "\n\t";
					writeTypeQuoted(writer, allSymbols, program, t);
				}
			}
		},
		(in ExpectedForDiag.Infer) {
			writer ~= "this location has no expected type";
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
