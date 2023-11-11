module frontend.ide.getHover;

@safe @nogc pure nothrow:

import frontend.ide.position : Position, PositionKind;
import frontend.parse.ast : FieldMutabilityAst, FunModifierAst;
import frontend.showModel :
	ShowCtx, writeCalled, writeFile, writeFunInst, writeLineAndColumnRange, writeName, writeSpecInst, writeTypeUnquoted;
import model.model :
	AssertOrForbidKind,
	body_,
	ClosureRef,
	decl,
	Expr,
	ExprKind,
	FunDecl,
	FunKind,
	StructDecl,
	Local,
	name,
	SpecDecl,
	SpecInst,
	StructBody,
	StructInst,
	symOfVisibility,
	Type,
	TypeParam,
	Visibility;
import util.alloc.alloc : Alloc;
import util.col.str : SafeCStr;
import util.lineAndColumnGetter : lineAndColumnRange;
import util.ptr : ptrTrustMe;
import util.sourceRange : UriAndRange;
import util.sym : writeSym;
import util.uri : Uri;
import util.util : unreachable;
import util.writer : finishWriterToSafeCStr, Writer;

SafeCStr getHoverStr(ref Alloc alloc, scope ref ShowCtx ctx, in Position pos) {
	Writer writer = Writer(ptrTrustMe(alloc));
	getHover(writer, ctx, pos);
	return finishWriterToSafeCStr(writer);
}

void getHover(ref Writer writer, scope ref ShowCtx ctx, in Position pos) =>
	pos.kind.matchIn!void(
		(in PositionKind.None) {},
		(in Expr x) {
			getExprHover(writer, ctx, pos.module_.uri, x);
		},
		(in FunDecl it) {
			writer ~= "function ";
			writeSym(writer, ctx.allSymbols, it.name);
		},
		(in PositionKind.FunExtern x) {
			writer ~= "function comes from external library ";
			writeName(writer, ctx, x.funDecl.name);
		},
		(in PositionKind.FunSpecialModifier x) {
			writer ~= () {
				final switch (x.flag) {
					case FunModifierAst.Special.Flags.none:
						return unreachable!string;
					case FunModifierAst.Special.Flags.builtin:
						return "This function is built in to the compiler.";
					case FunModifierAst.Special.Flags.extern_:
						// This is a compile error, so just let that explain it.
						return "";
					case FunModifierAst.Special.Flags.bare:
						return "This function does not use the Crow runtime.";
					case FunModifierAst.Special.Flags.summon:
						return "This function can directly access all I/O capacilities.";
					case FunModifierAst.Special.Flags.trusted:
						return "This function is not unsafe, but can do unsafe things internally.";
					case FunModifierAst.Special.Flags.unsafe:
						return "This function can only be called by 'trusted' or 'unsafe' functions.";
					case FunModifierAst.Special.Flags.forceCtx:
						return "This function uses the runtime, but 'bare' functions can call it. " ~
							"(Don't use outside of the Crow runtime.)";
				}
			}();
		},
		(in PositionKind.ImportedModule x) {
			writer ~= "import module ";
			writeFile(writer, ctx, x.module_.uri);
		},
		(in PositionKind.ImportedName x) {
			getImportedNameHover(writer, ctx, x);
		},
		(in PositionKind.Keyword x) {
			writer ~= () {
				final switch (x.kind) {
					case PositionKind.Keyword.Kind.builtin:
						return "Declares a type implemented by the compiler.";
					case PositionKind.Keyword.Kind.enum_:
						return "Declares an enumerated type. The type can only have the values listed.";
					case PositionKind.Keyword.Kind.extern_:
						return "Declares a type implemented by an external library.";
					case PositionKind.Keyword.Kind.flags:
						return "Declares a type that can have any combination of flags (this would be an 'enum' in C)";
					case PositionKind.Keyword.Kind.localMut:
						return "Makes this a mutable variable.";
					case PositionKind.Keyword.Kind.record:
						return "Declares a type combining several named members.";
					case PositionKind.Keyword.Kind.union_:
						return "Declares a type where a value will be one of the listed choices.";
				}
			}();
		},
		(in PositionKind.LocalNonParameter x) {
			writer ~= "local ";
			localHover(writer, ctx, *x.local);
		},
		(in PositionKind.LocalParameter x) {
			writer ~= "parameter ";
			localHover(writer, ctx, *x.local);
		},
		(in PositionKind.RecordFieldMutability x) {
			writer ~= () {
				final switch (x.kind) {
					case FieldMutabilityAst.Kind.private_:
						return "Defines a private setter.";
					case FieldMutabilityAst.Kind.public_:
						return "Defines a public setter.";
				}
			}();
		},
		(in PositionKind.RecordFieldPosition x) {
			writer ~= "field ";
			writeSym(writer, ctx.allSymbols, x.struct_.name);
			writer ~= '.';
			writeSym(writer, ctx.allSymbols, x.field.name);
			writer ~= " (";
			writeTypeUnquoted(writer, ctx, x.field.type);
			writer ~= ')';
		},
		(in SpecDecl x) {
			writer ~= "spec ";
			writeSym(writer, ctx.allSymbols, x.name);
		},
		(in SpecInst x) {
			writer ~= "spec ";
			writeSpecInst(writer, ctx, x);
		},
		(in StructDecl x) {
			writeStructDeclHover(writer, ctx, x);
		},
		(in Type x) {
			x.matchIn!void(
				(in Type.Bogus) {},
				(in TypeParam p) {
					hoverTypeParam(writer, ctx, p);
				},
				(in StructInst i) {
					writeStructDeclHover(writer, ctx, *decl(i));
				});
		},
		(in TypeParam x) {
			hoverTypeParam(writer, ctx, x);
		},
		(in Visibility x) {
			writer ~= "The declaration is ";
			writeSym(writer, ctx.allSymbols, symOfVisibility(x));
			writer ~= '.';
		});

private:

void writeStructDeclHover(ref Writer writer, scope ref ShowCtx ctx, in StructDecl a) {
	writer ~= body_(a).matchIn!string(
		(in StructBody.Bogus) =>
			"type ",
		(in StructBody.Builtin) =>
			"builtin type ",
		(in StructBody.Enum) =>
			"enum type ",
		(in StructBody.Extern) =>
			"extern type ",
		(in StructBody.Flags) =>
			"flags type ",
		(in StructBody.Record) =>
			"record type ",
		(in StructBody.Union) =>
			"union type ");
	writeSym(writer, ctx.allSymbols, a.name);
}

void getImportedNameHover(ref Writer writer, scope ref ShowCtx ctx, in PositionKind.ImportedName) {
	writer ~= "TODO: getImportedNameHover";
}

void hoverTypeParam(ref Writer writer, scope ref ShowCtx ctx, in TypeParam a) {
	writer ~= "type parameter ";
	writeSym(writer, ctx.allSymbols, a.name);
}

void getExprHover(ref Writer writer, scope ref ShowCtx ctx, in Uri curUri, in Expr a) =>
	a.kind.matchIn!void(
		(in ExprKind.AssertOrForbid x) {
			writer ~= "throws if the condition is ";
			writer ~= () {
				final switch (x.kind) {
					case AssertOrForbidKind.assert_:
						return "false";
					case AssertOrForbidKind.forbid:
						return "true";
				}
			}();
		},
		(in ExprKind.Bogus) {},
		(in ExprKind.Call x) {
			writeCalled(writer, ctx, x.called);
		},
		(in ExprKind.ClosureGet x) {
			writer ~= "gets ";
			closureRefHover(writer, ctx, *x.closureRef);
		},
		(in ExprKind.ClosureSet x) {
			writer ~= "sets ";
			closureRefHover(writer, ctx, *x.closureRef);
		},
		(in ExprKind.FunPtr x) {
			writer ~= "pointer to function ";
			writeFunInst(writer, ctx, *x.funInst);
		},
		(in ExprKind.If) {
			writer ~= "returns the first branch if the condition is 'true', " ~
				"and the second branch if the condition is 'false'";
		},
		(in ExprKind.IfOption) {
			writer ~= "returns the first branch if the option is non-empty, " ~
				"and the second branch if it is empty";
		},
		(in ExprKind.Lambda x) {
			writer ~= () {
				final switch (x.kind) {
					case FunKind.fun:
						return "function";
					case FunKind.act:
						return "'act' function";
					case FunKind.far:
						return "far function";
					case FunKind.pointer:
						return "function pointer";
				}
			}();
			writer ~= " literal";
		},
		(in ExprKind.Let) {},
		(in ExprKind.Literal) {},
		(in ExprKind.LiteralCString) {},
		(in ExprKind.LiteralSymbol) {},
		(in ExprKind.LocalGet x) {
			localHover(writer, ctx, *x.local);
		},
		(in ExprKind.LocalSet x) {
			writer ~= "sets ";
			localHover(writer, ctx, *x.local);
		},
		(in ExprKind.Loop) {
			writer ~= "loop that terminates at a 'break'";
		},
		(in ExprKind.LoopBreak x) {
			writer ~= "breaks out of ";
			writeLoop(writer, ctx, curUri, *x.loop);
		},
		(in ExprKind.LoopContinue x) {
			writer ~= "goes back to top of ";
			writeLoop(writer, ctx, curUri, *x.loop);
		},
		(in ExprKind.LoopUntil) {
			writer ~= "loop that runs as long as the condition is 'false'";
		},
		(in ExprKind.LoopWhile) {
			writer ~= "loop that runs as long as the condition is 'true'";
		},
		(in ExprKind.MatchEnum) {},
		(in ExprKind.MatchUnion) {},
		(in ExprKind.PtrToField x) {
			// TODO: ExprKind.PtrToField should have the RecordField
		},
		(in ExprKind.PtrToLocal x) {
			writer ~= "pointer to ";
			localHover(writer, ctx, *x.local);
		},
		(in ExprKind.Seq) {},
		(in ExprKind.Throw) {
			writer ~= "throws an exception";
		});

void closureRefHover(ref Writer writer, scope ref ShowCtx ctx, in ClosureRef a) {
	writer ~= "closure variable ";
	writeSym(writer, ctx.allSymbols, a.name);
	writer ~= ' ';
	writeTypeUnquoted(writer, ctx, a.type);
}

void localHover(ref Writer writer, scope ref ShowCtx ctx, in Local a) {
	writeSym(writer, ctx.allSymbols, a.name);
	writer ~= ' ';
	writeTypeUnquoted(writer, ctx, a.type);
}

void writeLoop(ref Writer writer, scope ref ShowCtx ctx, Uri curUri, in ExprKind.Loop a) {
	writer ~= "loop at ";
	writeLineAndColumnRange(writer, lineAndColumnRange(ctx.lineAndColumnGetters, UriAndRange(curUri, a.range)));
}
