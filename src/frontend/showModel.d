module frontend.showModel;

@safe @nogc pure nothrow:

import frontend.check.typeFromAst : typeSyntaxKind;
import frontend.storage : LineAndCharacterGetters, LineAndColumnGetters;
import model.ast : NameAndRange;
import model.diag : Diag, TypeContainer, TypeWithContainer;
import model.model :
	Called,
	CalledDecl,
	CalledSpecSig,
	CommonTypes,
	Destructure,
	FunDecl,
	FunDeclAndTypeArgs,
	FunInst,
	FunKind,
	isTuple,
	Local,
	Params,
	ParamShort,
	ParamsShort,
	Purity,
	ReturnAndParamTypes,
	SpecInst,
	stringOfVisibility,
	StructInst,
	Type,
	TypeParamIndex,
	TypeParams,
	TypeParamsAndSig,
	Visibility;
import util.col.array : isEmpty, only, only2, sizeEq;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : PosKind, toUriAndPos, UriAndPos, UriAndRange;
import util.symbol : Symbol;
import util.uri : Uri, UrisInfo, writeUriPreferRelative;
import util.util : stringOfEnum;
import util.writer :
	writeBold, writeHyperlink, writeNewline, writeRed, writeReset, writeWithCommas, writeWithCommasZip, Writer;

const struct ShowCtx {
	@safe @nogc pure nothrow:

	LineAndColumnGetters lineAndColumnGetters;
	UrisInfo urisInfo;
	ShowOptions options;

	LineAndCharacterGetters lineAndCharacterGetters() return scope =>
		lineAndColumnGetters.lineAndCharacterGetters;
}

const struct ShowTypeCtx {
	@safe @nogc pure nothrow:

	ShowCtx show;
	private CommonTypes* commonTypesPtr;

	alias show this;

	ref CommonTypes commonTypes() return scope =>
		*commonTypesPtr;
}
alias ShowDiagCtx = ShowTypeCtx;
alias ShowModelCtx = ShowTypeCtx;

struct ShowOptions {
	@safe @nogc pure nothrow:
	bool color;

	ShowOptions withoutColor() =>
		ShowOptions(false);
}

void writeCalled(scope ref Writer writer, in ShowTypeCtx ctx, in TypeContainer typeContainer, in Called a) {
	a.matchIn!void(
		(in Called.Bogus x) {
			writer ~= "<<bogus>>";
		},
		(in FunInst x) {
			writeFunInst(writer, ctx, typeContainer, x);
		},
		(in CalledSpecSig x) {
			writeCalledSpecSig(writer, ctx, typeContainer, x);
		});
}

private void writeCalledDecl(
	scope ref Writer writer,
	in ShowTypeCtx ctx,
	in TypeContainer typeContainer,
	in CalledDecl a,
) {
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
	in ShowTypeCtx ctx,
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

void writeCalleds(scope ref Writer writer, in ShowTypeCtx ctx, in TypeContainer typeContainer, in Called[] cs) {
	foreach (ref Called x; cs) {
		writeNewline(writer, 1);
		writeCalled(writer, ctx, typeContainer, x);
	}
}

private void writeCalledSpecSig(
	scope ref Writer writer,
	in ShowTypeCtx ctx,
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
	in ShowTypeCtx ctx,
	in TypeParams typeParams,
	in TypeContainer typeArgsContext,
	in Type[] typeArgs,
) {
	assert(sizeEq(typeParams, typeArgs));
	if (!isEmpty(typeParams)) {
		writer ~= " with ";
		writeWithCommasZip!(NameAndRange, Type)(writer, typeParams, typeArgs, (in NameAndRange param, in Type arg) {
			writer ~= param.name;
			writer ~= '=';
			writeTypeUnquoted(writer, ctx, TypeWithContainer(arg, typeArgsContext));
		});
	}
}

void writeFunDecl(scope ref Writer writer, in ShowTypeCtx ctx, in FunDecl* a) {
	writeSig(writer, ctx, TypeContainer(a), a.name, a.returnType, a.params, none!ReturnAndParamTypes);
	writeFunDeclLocation(writer, ctx, *a);
}

void writeFunDeclAndTypeArgs(
	scope ref Writer writer,
	in ShowTypeCtx ctx,
	in TypeContainer typeContainer,
	in FunDeclAndTypeArgs a,
) {
	writer ~= a.decl.name;
	writeTypeArgs(writer, ctx, typeContainer, a.typeArgs);
	writeFunDeclLocation(writer, ctx, *a.decl);
}

void writeFunInst(scope ref Writer writer, in ShowTypeCtx ctx, in TypeContainer typeContainer, in FunInst a) {
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
	writer ~= ctx.lineAndColumnGetters[pos, PosKind.startOfRange].pos.line1Indexed;
}

void writeSig(
	scope ref Writer writer,
	in ShowTypeCtx ctx,
	in TypeContainer typeContainer,
	Symbol name,
	in Type returnType,
	in Params params,
	in Opt!ReturnAndParamTypes instantiated,
) {
	writer ~= '\'';
	writer ~= name;
	if (!has(instantiated))
		writeTypeParams(writer, ctx, typeContainer.typeParams);
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
	writer ~= ")'";
}

void writeSigSimple(
	scope ref Writer writer,
	in ShowTypeCtx ctx,
	in TypeContainer typeContainer,
	Symbol name,
	in TypeParamsAndSig sig,
) {
	writer ~= name;
	writeTypeParams(writer, ctx, sig.typeParams);
	writer ~= ' ';
	writeTypeUnquoted(writer, ctx, TypeWithContainer(sig.returnType, typeContainer));
	writer ~= '(';
	sig.params.matchIn!void(
		(in ParamShort[] params) {
			writeWithCommas!ParamShort(writer, params, (in ParamShort x) {
				writeParamShort(writer, ctx, typeContainer, x);
			});
		},
		(in ParamsShort.Variadic x) {
			writer ~= "...";
			writeParamShort(writer, ctx, typeContainer, x.param);
		});
	writer ~= ')';
}

private void writeParamShort(
	scope ref Writer writer,
	in ShowTypeCtx ctx,
	in TypeContainer typeContainer,
	in ParamShort a,
) {
	writer ~= a.name;
	writer ~= ' ';
	writeTypeUnquoted(writer, ctx, TypeWithContainer(a.type, typeContainer));
}

private void writeTypeParams(scope ref Writer writer, in ShowTypeCtx ctx, in TypeParams typeParams) {
	if (!isEmpty(typeParams)) {
		writer ~= '[';
		writeWithCommas!NameAndRange(writer, typeParams, (in NameAndRange x) {
			writer ~= x.name;
		});
		writer ~= ']';
	}
}

private void writeDestructure(
	scope ref Writer writer,
	in ShowTypeCtx ctx,
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
			writer ~= x.name;
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

void writeStructInst(scope ref Writer writer, in ShowTypeCtx ctx, in TypeContainer typeContainer, in StructInst s) {
	TypeWithContainer withContainer(Type x) =>
		TypeWithContainer(x, typeContainer);
	void fun(FunKind kind) {
		Type[2] rp = only2(s.typeArgs);
		writeFunType(writer, ctx, typeContainer, kind, rp[0], rp[1]);
	}
	void map(string open) {
		Type[2] vk = only2(s.typeArgs);
		writeTypeUnquoted(writer, ctx, withContainer(vk[0]));
		writer ~= open;
		writer ~= '[';
		writeTypeUnquoted(writer, ctx, withContainer(vk[1]));
		writer ~= ']';
	}
	void suffix(string suffix) {
		writeTypeUnquoted(writer, ctx, withContainer(only(s.typeArgs)));
		writer ~= suffix;
	}

	Symbol name = s.decl.name;
	Opt!(Diag.TypeShouldUseSyntax.Kind) kind = typeSyntaxKind(name);
	if (has(kind)) {
		final switch (force(kind)) {
			case Diag.TypeShouldUseSyntax.Kind.array:
				return suffix("[]");
			case Diag.TypeShouldUseSyntax.Kind.map:
				return map("");
			case Diag.TypeShouldUseSyntax.Kind.funData:
				return fun(FunKind.data);
			case Diag.TypeShouldUseSyntax.Kind.funMut:
				return fun(FunKind.mut);
			case Diag.TypeShouldUseSyntax.Kind.funPointer:
				return fun(FunKind.function_);
			case Diag.TypeShouldUseSyntax.Kind.funShared:
				return fun(FunKind.shared_);
			case Diag.TypeShouldUseSyntax.Kind.mutArray:
				return suffix(" mut[]");
			case Diag.TypeShouldUseSyntax.Kind.mutMap:
				return map(" mut");
			case Diag.TypeShouldUseSyntax.Kind.mutPointer:
				return suffix(" mut*");
			case Diag.TypeShouldUseSyntax.Kind.opt:
				return suffix("?");
			case Diag.TypeShouldUseSyntax.Kind.pointer:
				return suffix("*");
			case Diag.TypeShouldUseSyntax.Kind.sharedArray:
				return suffix(" shared[]");
			case Diag.TypeShouldUseSyntax.Kind.sharedMap:
				return map(" shared");
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
		writer ~= name;
	}
}

private void writeFunType(
	scope ref Writer writer,
	in ShowTypeCtx ctx,
	in TypeContainer typeContainer,
	FunKind kind,
	Type returnType,
	Type paramType,
) {
	writeTypeUnquoted(writer, ctx, TypeWithContainer(returnType, typeContainer));
	writer ~= ' ';
	writer ~= stringOfEnum(kind);
	writer ~= '(';
	if (isTuple(ctx.commonTypes, paramType))
		writeWithCommas!Type(writer, paramType.as!(StructInst*).typeArgs, (in Type typeArg) {
			writer ~= "_ ";
			writeTypeUnquoted(writer, ctx, TypeWithContainer(typeArg, typeContainer));
		});
	else if (paramType != Type(ctx.commonTypes.void_))
		writeTypeUnquoted(writer, ctx, TypeWithContainer(paramType, typeContainer));
	writer ~= ')';
}

private void writeTupleType(
	scope ref Writer writer,
	in ShowTypeCtx ctx,
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
	if (!isEmpty(typeArgs)) {
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

private void writeTypeArgs(
	scope ref Writer writer,
	in ShowTypeCtx ctx,
	in TypeContainer typeContainer,
	in Type[] types,
) {
	writeTypeArgsGeneric!Type(writer, types,
		(in Type x) =>
			!x.isA!(StructInst*) || isEmpty(x.as!(StructInst*).typeArgs),
		(in Type x) {
			writeTypeUnquoted(writer, ctx, TypeWithContainer(x, typeContainer));
		});
}

void writeTypeQuoted(scope ref Writer writer, in ShowTypeCtx ctx, in TypeWithContainer a) {
	writer ~= '\'';
	writeTypeUnquoted(writer, ctx, a);
	writer ~= '\'';
}

void writeTypeUnquoted(scope ref Writer writer, in ShowTypeCtx ctx, in TypeWithContainer a) {
	a.type.matchIn!void(
		(in Type.Bogus) {
			writer ~= "<<any>>";
		},
		(in TypeParamIndex x) {
			writer ~= a.container.typeParams[x.index].name;
		},
		(in StructInst x) {
			writeStructInst(writer, ctx, a.container, x);
		});
}

void writePurity(scope ref Writer writer, in ShowCtx ctx, Purity a) {
	writeName(writer, ctx, stringOfEnum(a));
}

alias writeKeyword = writeName;
void writeName(scope ref Writer writer, in ShowCtx ctx, Symbol name) {
	writer ~= '\'';
	writer ~= name;
	writer ~= '\'';
}
void writeName(scope ref Writer writer, in ShowTypeCtx ctx, Symbol name) {
	writeName(writer, ctx.show, name);
}
void writeName(scope ref Writer writer, in ShowCtx ctx, string name) {
	writer ~= '\'';
	writer ~= name;
	writer ~= '\'';
}

void writeSpecInst(scope ref Writer writer, in ShowTypeCtx ctx, in TypeContainer typeContainer, in SpecInst a) {
	writer ~= a.name;
	writeTypeArgs(writer, ctx, typeContainer, a.typeArgs);
}

void writeUriAndRange(scope ref Writer writer, in ShowCtx ctx, in UriAndRange where) {
	writeFileNoResetWriter(writer, ctx, where.uri);
	if (where.uri != Uri.empty)
		writer ~= ctx.lineAndColumnGetters[where].range;
	if (ctx.options.color)
		writeReset(writer);
}

void writeUriAndPos(scope ref Writer writer, in ShowCtx ctx, in UriAndPos where) {
	writeFileNoResetWriter(writer, ctx, where.uri);
	if (where.uri != Uri.empty)
		writer ~= ctx.lineAndColumnGetters[where, PosKind.startOfRange].pos;
	if (ctx.options.color)
		writeReset(writer);
}

void writeFile(scope ref Writer writer, in ShowCtx ctx, Uri uri) {
	writeFileNoResetWriter(writer, ctx, uri);
	if (ctx.options.color)
		writeReset(writer);
}

void writeUri(scope ref Writer writer, in ShowCtx ctx, Uri uri) {
	writeUriPreferRelative(writer, ctx.urisInfo, uri);
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

void writeVisibility(scope ref Writer writer, in ShowCtx ctx, Visibility a) {
	writer ~= stringOfVisibility(a);
}
