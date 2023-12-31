module frontend.ide.getHover;

@safe @nogc pure nothrow:

import frontend.ide.position : Position, PositionKind;
import frontend.showModel :
	ShowModelCtx,
	writeCalled,
	writeFile,
	writeFunInst,
	writeLineAndColumnRange,
	writeName,
	writeSpecInst,
	writeTypeQuoted;
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
	FunPointerExpr,
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
	stringOfVarKind,
	stringOfVisibility,
	StructDecl,
	StructInst,
	Test,
	ThrowExpr,
	Type,
	TypeParamIndex,
	VarDecl,
	Visibility;
import util.alloc.alloc : Alloc;
import util.col.array : isEmpty;
import util.opt : none, Opt, some;
import util.sourceRange : UriAndRange;
import util.symbol : symbol, writeSymbol;
import util.uri : Uri;
import util.util : ptrTrustMe;
import util.writer : makeStringWithWriter, Writer;

Opt!Hover getHover(ref Alloc alloc, in ShowModelCtx ctx, in Position pos) {
	string content = makeStringWithWriter(alloc, (scope ref Writer writer) {
		getHover(writer, ctx, pos);
	});
	return isEmpty(content)
		? none!Hover
		: some(Hover(MarkupContent(MarkupKind.plaintext, content)));
}

void getHover(scope ref Writer writer, in ShowModelCtx ctx, in Position pos) =>
	pos.kind.matchIn!void(
		(in PositionKind.None) {},
		(in PositionKind.Expression x) {
			getExprHover(writer, ctx, pos.module_.uri, x.container.toTypeContainer, *x.expr);
		},
		(in FunDecl x) {
			writer ~= "Function ";
			writeName(writer, ctx, x.name);
		},
		(in PositionKind.FunExtern x) {
			writer ~= "Function comes from external library ";
			writeName(writer, ctx, x.funDecl.name);
			writer ~= '.';
		},
		(in PositionKind.FunSpecialModifier x) {
			writer ~= () {
				final switch (x.flag) {
					case FunModifierAst.Special.Flags.none:
						assert(false);
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
			writer ~= "Import module ";
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
			writer ~= "Local ";
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
			writer ~= "Record field ";
			writeSymbol(writer, ctx.allSymbols, x.struct_.name);
			writer ~= '.';
			writeSymbol(writer, ctx.allSymbols, x.field.name);
			writer ~= " (of type ";
			writeTypeQuoted(writer, ctx, TypeWithContainer(x.field.type, TypeContainer(x.struct_)));
			writer ~= ')';
		},
		(in SpecDecl x) {
			writer ~= "Spec ";
			writeName(writer, ctx, x.name);
		},
		(in PositionKind.SpecSig x) {
			writer ~= "Spec signature ";
			writeName(writer, ctx, x.sig.name);
		},
		(in PositionKind.SpecUse x) {
			writer ~= "Spec ";
			writeSpecInst(writer, ctx, x.container, *x.spec);
		},
		(in StructDecl x) {
			writeStructDeclHover(writer, ctx, x);
		},
		(in Test x) {
			writer ~= "Declares a unit test.";
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
			writer ~= stringOfVarKind(x.kind);
			writer ~= " variable ";
			writeName(writer, ctx, x.name);
			writer ~= " (of type ";
			writeTypeQuoted(writer, ctx, TypeWithContainer(x.type, TypeContainer(ptrTrustMe(x))));
			writer ~= ')';
		},
		(in Visibility x) {
			writer ~= "The declaration is ";
			writer ~= stringOfVisibility(x);
			writer ~= '.';
		});

private:

void writeStructDeclHover(scope ref Writer writer, in ShowModelCtx ctx, in StructDecl a) {
	writer ~= a.body_.matchIn!string(
		(in StructBody.Bogus) =>
			"Type ",
		(in StructBody.Builtin) =>
			"Builtin type ",
		(in StructBody.Enum) =>
			"Enum type ",
		(in StructBody.Extern) =>
			"Extern type ",
		(in StructBody.Flags) =>
			"Flags type ",
		(in StructBody.Record) =>
			"Record type ",
		(in StructBody.Union) =>
			"Union type ");
	writeName(writer, ctx, a.name);
}

void getImportedNameHover(scope ref Writer writer, in ShowModelCtx ctx, in PositionKind.ImportedName) {
	writer ~= "TODO: getImportedNameHover";
}

void hoverTypeParam(
	scope ref Writer writer,
	in ShowModelCtx ctx,
	in TypeContainer typeContainer,
	in TypeParamIndex index,
) {
	writer ~= "Type parameter ";
	writeName(writer, ctx, typeContainer.typeParams[index.index].name);
}

void getExprHover(
	scope ref Writer writer,
	in ShowModelCtx ctx,
	in Uri curUri,
	in TypeContainer typeContainer,
	in Expr a,
) =>
	a.kind.matchIn!void(
		(in AssertOrForbidExpr x) {
			writer ~= "Throws if the condition is ";
			writeName(writer, ctx, () {
				final switch (x.kind) {
					case AssertOrForbidKind.assert_:
						return symbol!"false";
					case AssertOrForbidKind.forbid:
						return symbol!"true";
				}
			}());
			writer ~= '.';
		},
		(in BogusExpr _) {},
		(in CallExpr x) {
			writer ~= "Calls ";
			writeCalled(writer, ctx, typeContainer, x.called);
			writer ~= '.';
		},
		(in ClosureGetExpr x) {
			writer ~= "Gets ";
			closureRefHover(writer, ctx, typeContainer, x.closureRef);
		},
		(in ClosureSetExpr x) {
			writer ~= "Sets ";
			closureRefHover(writer, ctx, typeContainer, x.closureRef);
		},
		(in FunPointerExpr x) {
			writer ~= "Pointer to function ";
			writeFunInst(writer, ctx, typeContainer, *x.funInst);
		},
		(in IfExpr _) {
			writer ~= "Returns the first branch if the condition is 'true', " ~
				"and the second branch if the condition is 'false'.";
		},
		(in IfOptionExpr _) {
			writer ~= "Returns the first branch if the option is non-empty, " ~
				"and the second branch if it is empty.";
		},
		(in LambdaExpr x) {
			writer ~= () {
				final switch (x.kind) {
					case FunKind.fun:
						return "Function";
					case FunKind.act:
						return "Action function";
					case FunKind.far:
						return "Far function";
					case FunKind.pointer:
						return "Function pointer";
				}
			}();
			writer ~= " literal";
		},
		(in LetExpr _) {},
		(in LiteralExpr _) {
			writer ~= "Number literal";
		},
		(in LiteralCStringExpr _) {
			writeName(writer, ctx, symbol!"c-string");
			writer ~= " literal";
		},
		(in LiteralSymbolExpr _) {
			writer ~= "Symbol literal";
		},
		(in LocalGetExpr x) {
			writer ~= "Gets ";
			localHover(writer, ctx, typeContainer, *x.local);
		},
		(in LocalSetExpr x) {
			writer ~= "Sets ";
			localHover(writer, ctx, typeContainer, *x.local);
			writer ~= '.';
		},
		(in LoopExpr _) {
			writer ~= "Loop that terminates at a 'break'";
		},
		(in LoopBreakExpr x) {
			writer ~= "Breaks out of ";
			writeLoop(writer, ctx, curUri, *x.loop);
			writer ~= '.';
		},
		(in LoopContinueExpr x) {
			writer ~= "Goes back to top of ";
			writeLoop(writer, ctx, curUri, *x.loop);
			writer ~= '.';
		},
		(in LoopUntilExpr _) {
			writer ~= "Loop will run as long as the condition is 'false'.";
		},
		(in LoopWhileExpr _) {
			writer ~= "Loop will run as long as the condition is 'true'.";
		},
		(in MatchEnumExpr _) {},
		(in MatchUnionExpr _) {},
		(in PtrToFieldExpr x) {
			// TODO: PtrToFieldExpr should have the RecordField
		},
		(in PtrToLocalExpr x) {
			writer ~= "Pointer to ";
			localHover(writer, ctx, typeContainer, *x.local);
		},
		(in SeqExpr _) {},
		(in ThrowExpr _) {
			writer ~= "Throws an exception.";
		});

void closureRefHover(scope ref Writer writer, in ShowModelCtx ctx, in TypeContainer typeContainer, in ClosureRef a) {
	writer ~= "closure variable ";
	writeName(writer, ctx, a.name);
	writer ~= "(of type ";
	writeTypeQuoted(writer, ctx, TypeWithContainer(a.type, typeContainer));
	writer ~= ')';
}

void localHover(scope ref Writer writer, in ShowModelCtx ctx, in TypeContainer typeContainer, in Local a) {
	writeName(writer, ctx, a.name);
	writer ~= " (of type ";
	writeTypeQuoted(writer, ctx, TypeWithContainer(a.type, typeContainer));
	writer ~= ')';
}

void writeLoop(scope ref Writer writer, in ShowModelCtx ctx, Uri curUri, in LoopExpr a) {
	writer ~= "loop at ";
	writeLineAndColumnRange(writer, ctx.lineAndColumnGetters[UriAndRange(curUri, a.range)].range);
}
