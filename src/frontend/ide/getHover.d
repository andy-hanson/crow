module frontend.ide.getHover;

@safe @nogc pure nothrow:

import frontend.ide.position : Position, PositionKind;
import frontend.showModel :
	ShowCtx, writeCalled, writeFile, writeFunInst, writeLineAndColumnRange, writeName, writeSpecInst, writeTypeUnquoted;
import lib.lsp.lspTypes : Hover, MarkupContent, MarkupKind;
import model.ast : FieldMutabilityAst, FunModifierAst;
import model.diag : TypeContainer, TypeWithContainer;
import model.model :
	AssertOrForbidExpr,
	AssertOrForbidKind,
	BogusExpr,
	CallExpr,
	ClosureGetExpr,
	ClosureRef,
	ClosureSetExpr,
	Expr,
	FunDecl,
	FunKind,
	FunPtrExpr,
	IfExpr,
	IfOptionExpr,
	LambdaExpr,
	LetExpr,
	LiteralCStringExpr,
	LiteralExpr,
	LiteralSymbolExpr,
	Local,
	LocalGetExpr,
	LocalSetExpr,
	LoopBreakExpr,
	LoopContinueExpr,
	LoopExpr,
	LoopUntilExpr,
	LoopWhileExpr,
	MatchEnumExpr,
	MatchUnionExpr,
	PtrToFieldExpr,
	PtrToLocalExpr,
	RecordField,
	SeqExpr,
	StructBody,
	SpecDecl,
	stringOfVisibility,
	StructDecl,
	StructInst,
	symbolOfVarKind,
	ThrowExpr,
	Type,
	TypeParamIndex,
	VarDecl,
	Visibility;
import util.alloc.alloc : Alloc;
import util.opt : none, Opt, some;
import util.sourceRange : UriAndRange;
import util.string : CString, cStringIsEmpty;
import util.symbol : writeSymbol;
import util.uri : Uri;
import util.util : ptrTrustMe, unreachable;
import util.writer : withWriter, Writer;

Opt!Hover getHover(ref Alloc alloc, in ShowCtx ctx, in Position pos) {
	CString content = withWriter(alloc, (scope ref Writer writer) {
		getHover(writer, ctx, pos);
	});
	return cStringIsEmpty(content)
		? none!Hover
		: some(Hover(MarkupContent(MarkupKind.plaintext, content)));
}

void getHover(scope ref Writer writer, in ShowCtx ctx, in Position pos) =>
	pos.kind.matchIn!void(
		(in PositionKind.None) {},
		(in PositionKind.Expression x) {
			getExprHover(writer, ctx, pos.module_.uri, TypeContainer(x.containingFun), *x.expr);
		},
		(in FunDecl x) {
			writer ~= "function ";
			writeSymbol(writer, ctx.allSymbols, x.name);
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
			localHover(writer, ctx, x.container.toTypeContainer, *x.local);
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
			writeSymbol(writer, ctx.allSymbols, x.struct_.name);
			writer ~= '.';
			writeSymbol(writer, ctx.allSymbols, x.field.name);
			writer ~= " (";
			writeTypeUnquoted(writer, ctx, TypeWithContainer(x.field.type, TypeContainer(x.struct_)));
			writer ~= ')';
		},
		(in SpecDecl x) {
			writer ~= "spec ";
			writeName(writer, ctx, x.name);
		},
		(in PositionKind.SpecSig x) {
			writer ~= "spec signature ";
			writeName(writer, ctx, x.sig.name);
		},
		(in PositionKind.SpecUse x) {
			writer ~= "spec ";
			writeSpecInst(writer, ctx, x.container, *x.spec);
		},
		(in StructDecl x) {
			writeStructDeclHover(writer, ctx, x);
		},
		(in TypeWithContainer x) {
			x.type.matchIn!void(
				(in Type.Bogus) {},
				(in TypeParamIndex p) {
					hoverTypeParam(writer, ctx, x.container, p);
				},
				(in StructInst i) {
					writeStructDeclHover(writer, ctx, *i.decl);
				});
		},
		(in PositionKind.TypeParamWithContainer x) {
			hoverTypeParam(writer, ctx, x.container, x.typeParam);
		},
		(in VarDecl x) {
			writeSymbol(writer, ctx.allSymbols, symbolOfVarKind(x.kind));
			writer ~= " variable ";
			writeName(writer, ctx, x.name);
			writer ~= " (";
			writeTypeUnquoted(writer, ctx, TypeWithContainer(x.type, TypeContainer(ptrTrustMe(x))));
			writer ~= ')';
		},
		(in Visibility x) {
			writer ~= "The declaration is ";
			writer ~= stringOfVisibility(x);
			writer ~= '.';
		});

private:

void writeStructDeclHover(scope ref Writer writer, in ShowCtx ctx, in StructDecl a) {
	writer ~= a.body_.matchIn!string(
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
	writeSymbol(writer, ctx.allSymbols, a.name);
}

void getImportedNameHover(scope ref Writer writer, in ShowCtx ctx, in PositionKind.ImportedName) {
	writer ~= "TODO: getImportedNameHover";
}

void hoverTypeParam(scope ref Writer writer, in ShowCtx ctx, in TypeContainer typeContainer, in TypeParamIndex index) {
	writer ~= "type parameter ";
	writeSymbol(writer, ctx.allSymbols, typeContainer.typeParams[index.index].name);
}

void getExprHover(scope ref Writer writer, in ShowCtx ctx, in Uri curUri, in TypeContainer typeContainer, in Expr a) =>
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
			writeCalled(writer, ctx, typeContainer, x.called);
		},
		(in ClosureGetExpr x) {
			writer ~= "gets ";
			closureRefHover(writer, ctx, typeContainer, x.closureRef);
		},
		(in ClosureSetExpr x) {
			writer ~= "sets ";
			closureRefHover(writer, ctx, typeContainer, x.closureRef);
		},
		(in FunPtrExpr x) {
			writer ~= "pointer to function ";
			writeFunInst(writer, ctx, typeContainer, *x.funInst);
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
		(in LiteralExpr _) {
			writer ~= "number literal";
		},
		(in LiteralCStringExpr _) {
			writer ~= "c-string literal";
		},
		(in LiteralSymbolExpr _) {
			writer ~= "symbol literal";
		},
		(in LocalGetExpr x) {
			localHover(writer, ctx, typeContainer, *x.local);
		},
		(in LocalSetExpr x) {
			writer ~= "sets ";
			localHover(writer, ctx, typeContainer, *x.local);
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
			localHover(writer, ctx, typeContainer, *x.local);
		},
		(in SeqExpr _) {},
		(in ThrowExpr _) {
			writer ~= "throws an exception";
		});

void closureRefHover(scope ref Writer writer, in ShowCtx ctx, in TypeContainer typeContainer, in ClosureRef a) {
	writer ~= "closure variable ";
	writeSymbol(writer, ctx.allSymbols, a.name);
	writer ~= ' ';
	writeTypeUnquoted(writer, ctx, TypeWithContainer(a.type, typeContainer));
}

void localHover(scope ref Writer writer, in ShowCtx ctx, in TypeContainer typeContainer, in Local a) {
	writeSymbol(writer, ctx.allSymbols, a.name);
	writer ~= ' ';
	writeTypeUnquoted(writer, ctx, TypeWithContainer(a.type, typeContainer));
}

void writeLoop(scope ref Writer writer, in ShowCtx ctx, Uri curUri, in LoopExpr a) {
	writer ~= "loop at ";
	writeLineAndColumnRange(writer, ctx.lineAndColumnGetters[UriAndRange(curUri, a.range)].range);
}
