module frontend.showModel;

@safe @nogc pure nothrow:

import frontend.check.typeFromAst : typeSyntaxKind;
import model.diag : Diag;
import model.model :
	Called,
	CalledDecl,
	CalledSpecSig,
	decl,
	Destructure,
	FunDecl,
	FunDeclAndTypeArgs,
	FunInst,
	isTuple,
	Local,
	name,
	Params,
	ParamShort,
	Program,
	Purity,
	ReturnAndParamTypes,
	StructInst,
	symOfPurity,
	Type,
	typeArgs,
	TypeParam,
	TypeParamsAndSig;
import util.col.arr : empty, only, only2, sizeEq;
import util.lineAndColumnGetter :
	lineAndColumnAtPos, LineAndColumn, LineAndColumnGetters, LineAndColumnRange, lineAndColumnRange, PosKind;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : UriAndPos, UriAndRange;
import util.sym : AllSymbols, Sym, writeSym;
import util.uri : AllUris, Uri, UrisInfo, writeUri, writeUriPreferRelative;
import util.util : verify;
import util.writer :
	writeBold, writeHyperlink, writeNewline, writeRed, writeReset, writeWithCommas, writeWithCommasZip, Writer;

struct ShowCtx {
	@safe @nogc pure nothrow:

	const AllSymbols* allSymbolsPtr;
	const AllUris* allUrisPtr;
	LineAndColumnGetters* lineAndColumnGettersPtr;
	UrisInfo urisInfo;
	ShowOptions options;
	immutable Program* programPtr;

	ref const(AllSymbols) allSymbols() return scope const =>
		*allSymbolsPtr;
	ref const(AllUris) allUris() return scope const =>
		*allUrisPtr;
	ref Program program() return scope const =>
		*programPtr;
	ref LineAndColumnGetters lineAndColumnGetters() return scope =>
		*lineAndColumnGettersPtr;
}

immutable struct ShowOptions {
	bool color;
}

void writeLineAndColumnRange(ref Writer writer, in LineAndColumnRange a) {
	writeLineAndColumn(writer, a.start);
	writer ~= '-';
	writeLineAndColumn(writer, a.end);
}

private void writeLineAndColumn(ref Writer writer, LineAndColumn lc) {
	writer ~= lc.line + 1;
	writer ~= ':';
	writer ~= lc.column + 1;
}

void writeCalled(ref Writer writer, scope ref ShowCtx ctx, in Called a) {
	a.matchIn!void(
		(in FunInst x) {
			writeFunInst(writer, ctx, x);
		},
		(in CalledSpecSig x) {
			writeCalledSpecSig(writer, ctx, x);
		});
}

private void writeCalledDecl(ref Writer writer, scope ref ShowCtx ctx, in CalledDecl a) {
	a.matchIn!void(
		(in FunDecl x) {
			writeFunDecl(writer, ctx, x);
		},
		(in CalledSpecSig x) {
			writeCalledSpecSig(writer, ctx, x);
		});
}

void writeCalledDecls(
	ref Writer writer,
	scope ref ShowCtx ctx,
	in CalledDecl[] cs,
	in bool delegate(in CalledDecl) @safe @nogc pure nothrow filter = (in _) => true,
) {
	foreach (ref CalledDecl c; cs)
		if (filter(c)) {
			writeNewline(writer);
			writer ~= '\t';
			writeCalledDecl(writer, ctx, c);
		}
}

void writeCalleds(ref Writer writer, scope ref ShowCtx ctx, in Called[] cs) {
	foreach (ref Called x; cs) {
		writeNewline(writer);
		writer ~= '\t';
		writeCalled(writer, ctx, x);
	}
}

private void writeCalledSpecSig(ref Writer writer, scope ref ShowCtx ctx, in CalledSpecSig x) {
	writeSig(writer, ctx, x.name, x.returnType, Params(x.nonInstantiatedSig.params), some(x.instantiatedSig));
	writer ~= " (from spec ";
	writeName(writer, ctx, name(*x.specInst));
	writer ~= ')';
}

private void writeTypeParamsAndArgs(
	ref Writer writer,
	scope ref ShowCtx ctx,
	in TypeParam[] typeParams,
	in Type[] typeArgs,
) {
	verify(sizeEq(typeParams, typeArgs));
	if (!empty(typeParams)) {
		writer ~= " with ";
		writeWithCommasZip!(TypeParam, Type)(writer, typeParams, typeArgs, (in TypeParam param, in Type arg) {
			writeSym(writer, ctx.allSymbols, param.name);
			writer ~= '=';
			writeTypeUnquoted(writer, ctx, arg);
		});
	}
}

void writeFunDecl(ref Writer writer, scope ref ShowCtx ctx, in FunDecl a) {
	writeSig(writer, ctx, a.name, a.returnType, a.params, none!ReturnAndParamTypes);
	writeFunDeclLocation(writer, ctx, a);
}

void writeFunDeclAndTypeArgs(ref Writer writer, scope ref ShowCtx ctx, in FunDeclAndTypeArgs a) {
	writeSym(writer, ctx.allSymbols, a.decl.name);
	writeTypeArgs(writer, ctx, a.typeArgs);
	writeFunDeclLocation(writer, ctx, *a.decl);
}

void writeFunInst(ref Writer writer, scope ref ShowCtx ctx, in FunInst a) {
	writeFunDecl(writer, ctx, *decl(a));
	writeTypeParamsAndArgs(writer, ctx, decl(a).typeParams, typeArgs(a));
}

private void writeFunDeclLocation(ref Writer writer, scope ref ShowCtx ctx, in FunDecl funDecl) {
	writer ~= " (from ";
	writeLineNumber(writer, ctx, funDecl.fileAndPos);
	writer ~= ')';
}

private void writeLineNumber(ref Writer writer, scope ref ShowCtx ctx, in UriAndPos pos) {
	if (ctx.options.color)
		writeBold(writer);
	writeUri(writer, ctx, pos.uri);
	if (ctx.options.color)
		writeReset(writer);
	writer ~= " line ";
	size_t line = lineAndColumnAtPos(ctx.lineAndColumnGetters, pos, PosKind.startOfRange).line;
	writer ~= line + 1;
}

void writeSig(
	ref Writer writer,
	scope ref ShowCtx ctx,
	Sym name,
	in Type returnType,
	in Params params,
	in Opt!ReturnAndParamTypes instantiated,
) {
	writeSym(writer, ctx.allSymbols, name);
	writer ~= ' ';
	writeTypeUnquoted(writer, ctx, has(instantiated) ? force(instantiated).returnType : returnType);
	writer ~= '(';
	params.matchIn!void(
		(in Destructure[] paramsArray) {
			if (has(instantiated))
				writeWithCommasZip!(Destructure, Type)(
					writer,
					paramsArray,
					force(instantiated).paramTypes,
					(in Destructure x, in Type t) {
						writeDestructure(writer, ctx, x, some(t));
					});
			else
				writeWithCommas!Destructure(writer, paramsArray, (in Destructure x) {
					writeDestructure(writer, ctx, x, none!Type);
				});
		},
		(in Params.Varargs varargs) {
			writer ~= "...";
			writeTypeUnquoted(writer, ctx, has(instantiated)
				? only(force(instantiated).paramTypes)
				: varargs.param.type);
		});
	writer ~= ')';
}

void writeSigSimple(ref Writer writer, scope ref ShowCtx ctx, Sym name, in TypeParamsAndSig sig) {
	writeSym(writer, ctx.allSymbols, name);
	if (!empty(sig.typeParams)) {
		writer ~= '[';
		writeWithCommas!TypeParam(writer, sig.typeParams, (in TypeParam x) {
			writeSym(writer, ctx.allSymbols, x.name);
		});
		writer ~= ']';
	}
	writer ~= ' ';
	writeTypeUnquoted(writer, ctx, sig.returnType);
	writer ~= '(';
	writeWithCommas!ParamShort(writer, sig.params, (in ParamShort x) {
		writeSym(writer, ctx.allSymbols, x.name);
		writer ~= ' ';
		writeTypeUnquoted(writer, ctx, x.type);
	});
	writer ~= ')';
}

private void writeDestructure(
	ref Writer writer,
	scope ref ShowCtx ctx,
	in Destructure a,
	in Opt!Type instantiated,
) {
	Type type = has(instantiated) ? force(instantiated) : a.type;
	a.matchIn!void(
		(in Destructure.Ignore) {
			writer ~= "_ ";
			writeTypeUnquoted(writer, ctx, type);
		},
		(in Local x) {
			writeSym(writer, ctx.allSymbols, x.name);
			writer ~= ' ';
			writeTypeUnquoted(writer, ctx, type);
		},
		(in Destructure.Split x) {
			writer ~= '(';
			writeWithCommasZip!(Destructure, Type)(
				writer, x.parts, typeArgs(*type.as!(StructInst*)), (in Destructure part, in Type partType) {
					writeDestructure(writer, ctx, part, some(partType));
				});
			writer ~= ')';
		});
}

void writeStructInst(scope ref Writer writer, scope ref ShowCtx ctx, in StructInst s) {
	void fun(string keyword) @safe {
		writer ~= keyword;
		writer ~= ' ';
		Type[2] rp = only2(s.typeArgs);
		writeTypeUnquoted(writer, ctx, rp[0]);
		Type param = rp[1];
		bool needParens = !(param.isA!(StructInst*) && isTuple(ctx.program.commonTypes, *param.as!(StructInst*)));
		if (needParens) writer ~= '(';
		writeTypeUnquoted(writer, ctx, param);
		if (needParens) writer ~= ')';
	}
	void map(string open) {
		Type[2] vk = only2(s.typeArgs);
		writeTypeUnquoted(writer, ctx, vk[0]);
		writer ~= open;
		writeTypeUnquoted(writer, ctx, vk[1]);
		writer ~= ']';
	}
	void suffix(string suffix) {
		writeTypeUnquoted(writer, ctx, only(s.typeArgs));
		writer ~= suffix;
	}

	Sym name = decl(s).name;
	Opt!(Diag.TypeShouldUseSyntax.Kind) kind = typeSyntaxKind(name);
	if (has(kind)) {
		final switch (force(kind)) {
			case Diag.TypeShouldUseSyntax.Kind.map:
				return map("[");
			case Diag.TypeShouldUseSyntax.Kind.funAct:
				return fun("act");
			case Diag.TypeShouldUseSyntax.Kind.funFar:
				return fun("far");
			case Diag.TypeShouldUseSyntax.Kind.funFun:
				return fun("fun");
			case Diag.TypeShouldUseSyntax.Kind.future:
				return suffix("^");
			case Diag.TypeShouldUseSyntax.Kind.list:
				return suffix("[]");
			case Diag.TypeShouldUseSyntax.Kind.mutMap:
				return map(" mut[");
			case Diag.TypeShouldUseSyntax.Kind.mutList:
				return suffix(" mut[]");
			case Diag.TypeShouldUseSyntax.Kind.mutPointer:
				return suffix(" mut*");
			case Diag.TypeShouldUseSyntax.Kind.opt:
				return suffix("?");
			case Diag.TypeShouldUseSyntax.Kind.pointer:
				return suffix("*");
			case Diag.TypeShouldUseSyntax.Kind.tuple:
				return writeTupleType(writer, ctx, s.typeArgs);
		}
	} else {
		switch (s.typeArgs.length) {
			case 0:
				break;
			case 1:
				writeTypeUnquoted(writer, ctx, only(s.typeArgs));
				writer ~= ' ';
				break;
			default:
				writeTupleType(writer, ctx, s.typeArgs);
				writer ~= ' ';
				break;
		}
		writeSym(writer, ctx.allSymbols, name);
	}
}

private void writeTupleType(scope ref Writer writer, scope ref ShowCtx ctx, in Type[] members) {
	writer ~= '(';
	writeWithCommas!Type(writer, members, (in Type arg) {
		writeTypeUnquoted(writer, ctx, arg);
	});
	writer ~= ')';
}

void writeTypeArgsGeneric(T)(
	scope ref Writer writer,
	in T[] typeArgs,
	in bool delegate(in T) @safe @nogc pure nothrow isSimpleType,
	in void delegate(in T) @safe @nogc pure nothrow cbWriteType,
) {
	if (!empty(typeArgs)) {
		writer ~= '@';
		if (typeArgs.length == 1 && isSimpleType(only(typeArgs)))
			cbWriteType(only(typeArgs));
		else {
			writer ~= '(';
			writeWithCommas!T(writer, typeArgs, cbWriteType);
			writer ~= ')';
		}
	}
}

void writeTypeArgs(scope ref Writer writer, scope ref ShowCtx ctx, in Type[] types) {
	writeTypeArgsGeneric!Type(writer, types,
		(in Type x) =>
			!x.isA!(StructInst*) || empty(typeArgs(*x.as!(StructInst*))),
		(in Type x) {
			writeTypeUnquoted(writer, ctx, x);
		});
}

void writeTypeQuoted(scope ref Writer writer, scope ref ShowCtx ctx, in Type a) {
	writer ~= '\'';
	writeTypeUnquoted(writer, ctx, a);
	writer ~= '\'';
}

void writeTypeUnquoted(scope ref Writer writer, scope ref ShowCtx ctx, in Type a) {
	a.matchIn!void(
		(in Type.Bogus) {
			writer ~= "<<bogus>>";
		},
		(in TypeParam x) {
			writeSym(writer, ctx.allSymbols, x.name);
		},
		(in StructInst x) {
			writeStructInst(writer, ctx, x);
		});
}

void writePurity(ref Writer writer, in ShowCtx ctx, Purity p) {
	writeName(writer, ctx, symOfPurity(p));
}

void writeName(scope ref Writer writer, in ShowCtx ctx, Sym name) {
	writer ~= '\'';
	writeSym(writer, ctx.allSymbols, name);
	writer ~= '\'';
}

void writeUriAndRange(ref Writer writer, scope ref ShowCtx ctx, in UriAndRange where) {
	writeFileNoResetWriter(writer, ctx, where.uri);
	if (where.uri != Uri.empty)
		writeLineAndColumnRange(writer, lineAndColumnRange(ctx.lineAndColumnGetters, where));
	if (ctx.options.color)
		writeReset(writer);
}

void writeUriAndPos(ref Writer writer, scope ref ShowCtx ctx, in UriAndPos where) {
	writeFileNoResetWriter(writer, ctx, where.uri);
	if (where.uri != Uri.empty)
		writeLineAndColumn(writer, lineAndColumnAtPos(ctx.lineAndColumnGetters, where, PosKind.startOfRange));
	if (ctx.options.color)
		writeReset(writer);
}

void writeFile(ref Writer writer, in ShowCtx ctx, Uri uri) {
	writeFileNoResetWriter(writer, ctx, uri);
	if (ctx.options.color)
		writeReset(writer);
}

void writeUri(ref Writer writer, in ShowCtx ctx, Uri uri) {
	writeUriPreferRelative(writer, ctx.allUris, ctx.urisInfo, uri);
}

private void writeFileNoResetWriter(ref Writer writer, in ShowCtx ctx, Uri uri) {
	if (ctx.options.color)
		writeBold(writer);

	if (ctx.options.color) {
		writeHyperlink(
			writer,
			() { writeUri(writer, ctx, uri); },
			() { writeUri(writer, ctx, uri); });
		writeRed(writer);
	} else
		writeUri(writer, ctx, uri);
	writer ~= ' ';
}
