module frontend.showModel;

@safe @nogc pure nothrow:

import frontend.check.typeFromAst : typeSyntaxKind;
import frontend.storage : lineAndColumnAtPos, LineAndColumnGetters, lineAndColumnRange;
import model.ast : NameAndRange;
import model.diag : Diag, TypeContainer, typeParamAsts, TypeWithContainer;
import model.model :
	Called,
	CalledDecl,
	CalledSpecSig,
	Destructure,
	FunDecl,
	FunDeclAndTypeArgs,
	FunInst,
	isTuple,
	Local,
	Params,
	ParamShort,
	Program,
	Purity,
	ReturnAndParamTypes,
	SpecInst,
	StructInst,
	symOfPurity,
	Type,
	TypeParamIndex,
	TypeParams,
	TypeParamsAndSig;
import util.col.arr : empty, only, only2, sizeEq;
import util.lineAndColumnGetter : LineAndColumn, LineAndColumnRange, PosKind;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : toUriAndPos, UriAndPos, UriAndRange;
import util.sym : AllSymbols, Sym, writeSym;
import util.uri : AllUris, Uri, UrisInfo, writeUri, writeUriPreferRelative;
import util.writer :
	writeBold, writeHyperlink, writeNewline, writeRed, writeReset, writeWithCommas, writeWithCommasZip, Writer;

const struct ShowCtx {
	@safe @nogc pure nothrow:

	const AllSymbols* allSymbolsPtr;
	const AllUris* allUrisPtr;
	LineAndColumnGetters lineAndColumnGetters;
	UrisInfo urisInfo;
	ShowOptions options;
	immutable Program* programPtr;

	ref const(AllSymbols) allSymbols() return scope const =>
		*allSymbolsPtr;
	ref const(AllUris) allUris() return scope const =>
		*allUrisPtr;
	ref Program program() return scope const =>
		*programPtr;
}

struct ShowOptions {
	bool color;
}

void writeLineAndColumnRange(scope ref Writer writer, in LineAndColumnRange a) {
	writeLineAndColumn(writer, a.start);
	writer ~= '-';
	writeLineAndColumn(writer, a.end);
}

private void writeLineAndColumn(scope ref Writer writer, LineAndColumn lc) {
	writer ~= lc.line1Indexed;
	writer ~= ':';
	writer ~= lc.column1Indexed;
}

void writeCalled(scope ref Writer writer, in ShowCtx ctx, in TypeContainer typeContainer, in Called a) {
	a.matchIn!void(
		(in FunInst x) {
			writeFunInst(writer, ctx, typeContainer, x);
		},
		(in CalledSpecSig x) {
			writeCalledSpecSig(writer, ctx, typeContainer, x);
		});
}

private void writeCalledDecl(scope ref Writer writer, in ShowCtx ctx, in TypeContainer typeContainer, in CalledDecl a) {
	a.matchWithPointers!void(
		(FunDecl* x) {
			writeFunDecl(writer, ctx, x);
		},
		(CalledSpecSig x) {
			writeCalledSpecSig(writer, ctx, typeContainer, x);
		});
}

void writeCalledDecls(
	scope ref Writer writer,
	in ShowCtx ctx,
	in TypeContainer typeContainer,
	in CalledDecl[] cs,
	in bool delegate(in CalledDecl) @safe @nogc pure nothrow filter = (in _) => true,
) {
	foreach (ref CalledDecl c; cs)
		if (filter(c)) {
			writeNewline(writer, 1);
			writeCalledDecl(writer, ctx, typeContainer, c);
		}
}

void writeCalleds(scope ref Writer writer, in ShowCtx ctx, in TypeContainer typeContainer, in Called[] cs) {
	foreach (ref Called x; cs) {
		writeNewline(writer, 1);
		writeCalled(writer, ctx, typeContainer, x);
	}
}

private void writeCalledSpecSig(
	scope ref Writer writer,
	in ShowCtx ctx,
	in TypeContainer typeContainer,
	in CalledSpecSig x,
) {
	writeSig(
		writer, ctx, typeContainer, x.name, x.returnType, Params(x.nonInstantiatedSig.params), some(x.instantiatedSig));
	writer ~= " (from spec ";
	writeName(writer, ctx, x.specInst.decl.name);
	writer ~= ')';
}

private void writeTypeParamsAndArgs(
	scope ref Writer writer,
	in ShowCtx ctx,
	in TypeParams typeParams,
	in TypeContainer typeArgsContext,
	in Type[] typeArgs,
) {
	assert(sizeEq(typeParams, typeArgs));
	if (!empty(typeParams)) {
		writer ~= " with ";
		writeWithCommasZip!(NameAndRange, Type)(writer, typeParams, typeArgs, (in NameAndRange param, in Type arg) {
			writeSym(writer, ctx.allSymbols, param.name);
			writer ~= '=';
			writeTypeUnquoted(writer, ctx, TypeWithContainer(arg, typeArgsContext));
		});
	}
}

void writeFunDecl(scope ref Writer writer, in ShowCtx ctx, in FunDecl* a) {
	writeSig(writer, ctx, TypeContainer(a), a.name, a.returnType, a.params, none!ReturnAndParamTypes);
	writeFunDeclLocation(writer, ctx, *a);
}

void writeFunDeclAndTypeArgs(
	scope ref Writer writer,
	in ShowCtx ctx,
	in TypeContainer typeContainer,
	in FunDeclAndTypeArgs a,
) {
	writeSym(writer, ctx.allSymbols, a.decl.name);
	writeTypeArgs(writer, ctx, typeContainer, a.typeArgs);
	writeFunDeclLocation(writer, ctx, *a.decl);
}

void writeFunInst(scope ref Writer writer, in ShowCtx ctx, in TypeContainer typeContainer, in FunInst a) {
	writeFunDecl(writer, ctx, a.decl);
	writeTypeParamsAndArgs(writer, ctx, a.decl.typeParams, typeContainer, a.typeArgs);
}

private void writeFunDeclLocation(scope ref Writer writer, in ShowCtx ctx, in FunDecl funDecl) {
	writer ~= " (from ";
	writeLineNumber(writer, ctx, toUriAndPos(funDecl.range));
	writer ~= ')';
}

private void writeLineNumber(scope ref Writer writer, in ShowCtx ctx, in UriAndPos pos) {
	if (ctx.options.color)
		writeBold(writer);
	writeUri(writer, ctx, pos.uri);
	if (ctx.options.color)
		writeReset(writer);
	writer ~= " line ";
	writer ~= lineAndColumnAtPos(ctx.lineAndColumnGetters, pos, PosKind.startOfRange).line1Indexed;
}

void writeSig(
	scope ref Writer writer,
	in ShowCtx ctx,
	in TypeContainer typeContainer,
	Sym name,
	in Type returnType,
	in Params params,
	in Opt!ReturnAndParamTypes instantiated,
) {
	writeSym(writer, ctx.allSymbols, name);
	writer ~= ' ';
	writeTypeUnquoted(writer, ctx, TypeWithContainer(
		has(instantiated) ? force(instantiated).returnType : returnType,
		typeContainer));
	writer ~= '(';
	params.matchIn!void(
		(in Destructure[] paramsArray) {
			if (has(instantiated))
				writeWithCommasZip!(Destructure, Type)(
					writer,
					paramsArray,
					force(instantiated).paramTypes,
					(in Destructure x, in Type t) {
						writeDestructure(writer, ctx, typeContainer, x, some(t));
					});
			else
				writeWithCommas!Destructure(writer, paramsArray, (in Destructure x) {
					writeDestructure(writer, ctx, typeContainer, x, none!Type);
				});
		},
		(in Params.Varargs varargs) {
			writer ~= "...";
			writeTypeUnquoted(writer, ctx, TypeWithContainer(
				has(instantiated) ? only(force(instantiated).paramTypes) : varargs.param.type,
				typeContainer));
		});
	writer ~= ")";
}

void writeSigSimple(
	scope ref Writer writer,
	in ShowCtx ctx,
	in TypeContainer typeContainer,
	Sym name,
	in TypeParamsAndSig sig,
) {
	writeSym(writer, ctx.allSymbols, name);
	if (!empty(sig.typeParams)) {
		writer ~= '[';
		writeWithCommas!NameAndRange(writer, sig.typeParams, (in NameAndRange x) {
			writeSym(writer, ctx.allSymbols, x.name);
		});
		writer ~= ']';
	}
	writer ~= ' ';
	writeTypeUnquoted(writer, ctx, TypeWithContainer(sig.returnType, typeContainer));
	writer ~= '(';
	writeWithCommas!ParamShort(writer, sig.params, (in ParamShort x) {
		writeSym(writer, ctx.allSymbols, x.name);
		writer ~= ' ';
		writeTypeUnquoted(writer, ctx, TypeWithContainer(x.type, typeContainer));
	});
	writer ~= ')';
}

private void writeDestructure(
	scope ref Writer writer,
	in ShowCtx ctx,
	in TypeContainer typeContainer,
	in Destructure a,
	in Opt!Type instantiated,
) {
	Type type = has(instantiated) ? force(instantiated) : a.type;
	a.matchIn!void(
		(in Destructure.Ignore) {
			writer ~= "_ ";
			writeTypeUnquoted(writer, ctx, TypeWithContainer(type, typeContainer));
		},
		(in Local x) {
			writeSym(writer, ctx.allSymbols, x.name);
			writer ~= ' ';
			writeTypeUnquoted(writer, ctx, TypeWithContainer(type, typeContainer));
		},
		(in Destructure.Split x) {
			writer ~= '(';
			writeWithCommasZip!(Destructure, Type)(
				writer, x.parts, type.as!(StructInst*).typeArgs, (in Destructure part, in Type partType) {
					writeDestructure(writer, ctx, typeContainer, part, some(partType));
				});
			writer ~= ')';
		});
}

void writeStructInst(scope ref Writer writer, in ShowCtx ctx, in TypeContainer typeContainer, in StructInst s) {
	TypeWithContainer withContainer(Type x) =>
		TypeWithContainer(x, typeContainer);
	void fun(string keyword) @safe {
		writer ~= keyword;
		writer ~= ' ';
		Type[2] rp = only2(s.typeArgs);
		writeTypeUnquoted(writer, ctx, withContainer(rp[0]));
		Type param = rp[1];
		bool needParens = !(param.isA!(StructInst*) && isTuple(ctx.program.commonTypes, *param.as!(StructInst*)));
		if (needParens) writer ~= '(';
		writeTypeUnquoted(writer, ctx, withContainer(param));
		if (needParens) writer ~= ')';
	}
	void map(string open) {
		Type[2] vk = only2(s.typeArgs);
		writeTypeUnquoted(writer, ctx, withContainer(vk[0]));
		writer ~= open;
		writeTypeUnquoted(writer, ctx, withContainer(vk[1]));
		writer ~= ']';
	}
	void suffix(string suffix) {
		writeTypeUnquoted(writer, ctx, withContainer(only(s.typeArgs)));
		writer ~= suffix;
	}

	Sym name = s.decl.name;
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
				return writeTupleType(writer, ctx, typeContainer, s.typeArgs);
		}
	} else {
		switch (s.typeArgs.length) {
			case 0:
				break;
			case 1:
				writeTypeUnquoted(writer, ctx, withContainer(only(s.typeArgs)));
				writer ~= ' ';
				break;
			default:
				writeTupleType(writer, ctx, typeContainer, s.typeArgs);
				writer ~= ' ';
				break;
		}
		writeSym(writer, ctx.allSymbols, name);
	}
}

private void writeTupleType(
	scope ref Writer writer,
	in ShowCtx ctx,
	in TypeContainer typeContainer,
	in Type[] members,
) {
	writer ~= '(';
	writeWithCommas!Type(writer, members, (in Type arg) {
		writeTypeUnquoted(writer, ctx, TypeWithContainer(arg, typeContainer));
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

private void writeTypeArgs(scope ref Writer writer, in ShowCtx ctx, in TypeContainer typeContainer, in Type[] types) {
	writeTypeArgsGeneric!Type(writer, types,
		(in Type x) =>
			!x.isA!(StructInst*) || empty(x.as!(StructInst*).typeArgs),
		(in Type x) {
			writeTypeUnquoted(writer, ctx, TypeWithContainer(x, typeContainer));
		});
}

void writeTypeQuoted(scope ref Writer writer, in ShowCtx ctx, in TypeWithContainer a) {
	writer ~= '\'';
	writeTypeUnquoted(writer, ctx, a);
	writer ~= '\'';
}

void writeTypeUnquoted(scope ref Writer writer, in ShowCtx ctx, in TypeWithContainer a) {
	a.type.matchIn!void(
		(in Type.Bogus) {
			writer ~= "<<any>>";
		},
		(in TypeParamIndex x) {
			writeSym(writer, ctx.allSymbols, typeParamAsts(a.container)[x.index].name);
		},
		(in StructInst x) {
			writeStructInst(writer, ctx, a.container, x);
		});
}

void writePurity(scope ref Writer writer, in ShowCtx ctx, Purity p) {
	writeName(writer, ctx, symOfPurity(p));
}

void writeName(scope ref Writer writer, in ShowCtx ctx, Sym name) {
	writer ~= '\'';
	writeSym(writer, ctx.allSymbols, name);
	writer ~= '\'';
}

void writeSpecInst(scope ref Writer writer, in ShowCtx ctx, in TypeContainer typeContainer, in SpecInst a) {
	writeSym(writer, ctx.allSymbols, a.name);
	writeTypeArgs(writer, ctx, typeContainer, a.typeArgs);
}

void writeUriAndRange(scope ref Writer writer, in ShowCtx ctx, in UriAndRange where) {
	writeFileNoResetWriter(writer, ctx, where.uri);
	if (where.uri != Uri.empty)
		writeLineAndColumnRange(writer, lineAndColumnRange(ctx.lineAndColumnGetters, where));
	if (ctx.options.color)
		writeReset(writer);
}

void writeUriAndPos(scope ref Writer writer, in ShowCtx ctx, in UriAndPos where) {
	writeFileNoResetWriter(writer, ctx, where.uri);
	if (where.uri != Uri.empty)
		writeLineAndColumn(writer, lineAndColumnAtPos(ctx.lineAndColumnGetters, where, PosKind.startOfRange));
	if (ctx.options.color)
		writeReset(writer);
}

void writeFile(scope ref Writer writer, in ShowCtx ctx, Uri uri) {
	writeFileNoResetWriter(writer, ctx, uri);
	if (ctx.options.color)
		writeReset(writer);
}

void writeUri(scope ref Writer writer, in ShowCtx ctx, Uri uri) {
	writeUriPreferRelative(writer, ctx.allUris, ctx.urisInfo, uri);
}

private void writeFileNoResetWriter(scope ref Writer writer, in ShowCtx ctx, Uri uri) {
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
