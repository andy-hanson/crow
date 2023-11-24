module frontend.ide.getHover;

@safe @nogc pure nothrow:

import frontend.ide.position : Position, PositionKind;
import frontend.parse.ast : FieldMutabilityAst, FunModifierAst;
import frontend.showModel :
	ShowCtx, writeCalled, writeFile, writeFunInst, writeLineAndColumnRange, writeName, writeSpecInst, writeTypeUnquoted;
import frontend.storage : lineAndColumnRange;
import lib.lsp.lspTypes : Hover, MarkupContent, MarkupKind;
import model.model;
import util.alloc.alloc : Alloc;
import util.col.str : SafeCStr, safeCStrIsEmpty;
import util.lineAndColumnGetter : LineAndCharacterRange;
import util.opt : none, Opt, some;
import util.sourceRange : UriAndRange;
import util.sym : writeSym;
import util.uri : Uri;
import util.util : unreachable;
import util.writer : withWriter, Writer;

Opt!Hover getHover(ref Alloc alloc, in ShowCtx ctx, in Position pos) {
	SafeCStr content = withWriter(alloc, (scope ref Writer writer) {
		getHover(writer, ctx, pos);
	});
	return safeCStrIsEmpty(content)
		? none!Hover
		: some(Hover(MarkupContent(MarkupKind.plaintext, content), none!LineAndCharacterRange));
}

void getHover(scope ref Writer writer, in ShowCtx ctx, in Position pos) =>
	pos.kind.matchIn!void(
		(in PositionKind.None) {},
		(in PositionKind.Expression x) {
			getExprHover(writer, ctx, pos.module_.uri, *x.expr);
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
		(in PositionKind.LocalPosition x) {
			writer ~= "local ";
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
			writeName(writer, ctx, x.name);
		},
		(in SpecInst x) {
			writer ~= "spec ";
			writeSpecInst(writer, ctx, x);
		},
		(in PositionKind.SpecSig x) {
			writer ~= "spec signature ";
			writeName(writer, ctx, x.sig.name);
		},
		(in StructDecl x) {
			writeStructDeclHover(writer, ctx, x);
		},
		(in PositionKind.TypeWithContainer x) {
			x.type.matchIn!void(
				(in Type.Bogus) {},
				(in TypeParam p) {
					hoverTypeParam(writer, ctx, p);
				},
				(in StructInst i) {
					writeStructDeclHover(writer, ctx, *decl(i));
				});
		},
		(in PositionKind.TypeParamWithContainer x) {
			hoverTypeParam(writer, ctx, *x.typeParam);
		},
		(in VarDecl x) {
			writeSym(writer, ctx.allSymbols, symOfVarKind(x.kind));
			writer ~= " variable ";
			writeName(writer, ctx, x.name);
			writer ~= " (";
			writeTypeUnquoted(writer, ctx, x.type);
			writer ~= ')';
		},
		(in Visibility x) {
			writer ~= "The declaration is ";
			writeSym(writer, ctx.allSymbols, symOfVisibility(x));
			writer ~= '.';
		});

private:

void writeStructDeclHover(scope ref Writer writer, in ShowCtx ctx, in StructDecl a) {
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

void getImportedNameHover(scope ref Writer writer, in ShowCtx ctx, in PositionKind.ImportedName) {
	writer ~= "TODO: getImportedNameHover";
}

void hoverTypeParam(scope ref Writer writer, in ShowCtx ctx, in TypeParam a) {
	writer ~= "type parameter ";
	writeSym(writer, ctx.allSymbols, a.name);
}

void getExprHover(scope ref Writer writer, in ShowCtx ctx, in Uri curUri, in Expr a) =>
	a.kind.matchIn!void(
		(in AssertOrForbidExpr x) {
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
		(in BogusExpr _) {},
		(in CallExpr x) {
			writeCalled(writer, ctx, x.called);
		},
		(in ClosureGetExpr x) {
			writer ~= "gets ";
			closureRefHover(writer, ctx, x.closureRef);
		},
		(in ClosureSetExpr x) {
			writer ~= "sets ";
			closureRefHover(writer, ctx, x.closureRef);
		},
		(in FunPtrExpr x) {
			writer ~= "pointer to function ";
			writeFunInst(writer, ctx, *x.funInst);
		},
		(in IfExpr _) {
			writer ~= "returns the first branch if the condition is 'true', " ~
				"and the second branch if the condition is 'false'";
		},
		(in IfOptionExpr _) {
			writer ~= "returns the first branch if the option is non-empty, " ~
				"and the second branch if it is empty";
		},
		(in LambdaExpr x) {
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
		(in LetExpr _) {},
		(in LiteralExpr _) {},
		(in LiteralCStringExpr _) {},
		(in LiteralSymbolExpr _) {},
		(in LocalGetExpr x) {
			localHover(writer, ctx, *x.local);
		},
		(in LocalSetExpr x) {
			writer ~= "sets ";
			localHover(writer, ctx, *x.local);
		},
		(in LoopExpr _) {
			writer ~= "loop that terminates at a 'break'";
		},
		(in LoopBreakExpr x) {
			writer ~= "breaks out of ";
			writeLoop(writer, ctx, curUri, *x.loop);
		},
		(in LoopContinueExpr x) {
			writer ~= "goes back to top of ";
			writeLoop(writer, ctx, curUri, *x.loop);
		},
		(in LoopUntilExpr _) {
			writer ~= "loop that runs as long as the condition is 'false'";
		},
		(in LoopWhileExpr _) {
			writer ~= "loop that runs as long as the condition is 'true'";
		},
		(in MatchEnumExpr _) {},
		(in MatchUnionExpr _) {},
		(in PtrToFieldExpr x) {
			// TODO: PtrToFieldExpr should have the RecordField
		},
		(in PtrToLocalExpr x) {
			writer ~= "pointer to ";
			localHover(writer, ctx, *x.local);
		},
		(in SeqExpr _) {},
		(in ThrowExpr _) {
			writer ~= "throws an exception";
		});

void closureRefHover(scope ref Writer writer, in ShowCtx ctx, in ClosureRef a) {
	writer ~= "closure variable ";
	writeSym(writer, ctx.allSymbols, a.name);
	writer ~= ' ';
	writeTypeUnquoted(writer, ctx, a.type);
}

void localHover(scope ref Writer writer, in ShowCtx ctx, in Local a) {
	writeSym(writer, ctx.allSymbols, a.name);
	writer ~= ' ';
	writeTypeUnquoted(writer, ctx, a.type);
}

void writeLoop(scope ref Writer writer, in ShowCtx ctx, Uri curUri, in LoopExpr a) {
	writer ~= "loop at ";
	writeLineAndColumnRange(writer, lineAndColumnRange(ctx.lineAndColumnGetters, UriAndRange(curUri, a.range)));
}
