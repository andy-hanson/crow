module frontend.ide.getHover;

@safe @nogc pure nothrow:

import frontend.ide.position : Position, PositionKind;
import frontend.showModel :
	ShowModelCtx,
	writeCalled,
	writeFile,
	writeFunDecl,
	writeFunInst,
	writeLineAndColumnRange,
	writeName,
	writeSpecInst,
	writeTypeQuoted,
	writeVisibility;
import lib.lsp.lspTypes : Hover, MarkupContent, MarkupKind;
import model.ast : ModifierKeyword;
import model.diag : TypeContainer, TypeWithContainer;
import model.model :
	AssertOrForbidExpr,
	AssertOrForbidKind,
	BogusExpr,
	BuiltinType,
	CallExpr,
	ClosureGetExpr,
	ClosureRef,
	ClosureSetExpr,
	Expr,
	FunDecl,
	FunPointerExpr,
	IfExpr,
	IfOptionExpr,
	LambdaExpr,
	LetExpr,
	LiteralExpr,
	LiteralStringLikeExpr,
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
	NameReferents,
	PtrToFieldExpr,
	PtrToLocalExpr,
	SeqExpr,
	StructAlias,
	StructBody,
	SpecDecl,
	stringOfVarKindUpperCase,
	StructDecl,
	StructInst,
	Test,
	ThrowExpr,
	TrustedExpr,
	Type,
	TypedExpr,
	TypeParamIndex,
	VarDecl;
import util.alloc.alloc : Alloc;
import util.col.array : isEmpty;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : UriAndRange;
import util.symbol : symbol, writeSymbol;
import util.uri : Uri;
import util.writer : makeStringWithWriter, writeNewline, Writer;

Opt!Hover getHover(ref Alloc alloc, in ShowModelCtx ctx, in Position pos) {
	string content = makeStringWithWriter(alloc, (scope ref Writer writer) {
		getHover(writer, ctx, pos);
	});
	return isEmpty(content)
		? none!Hover
		: some(Hover(MarkupContent(MarkupKind.plaintext, content)));
}

void getHover(scope ref Writer writer, in ShowModelCtx ctx, in Position pos) =>
	pos.kind.matchWithPointers!void(
		(PositionKind.None) {},
		(PositionKind.EnumOrFlagsMemberPosition x) {
			writer ~= x.struct_.body_.isA!(StructBody.Enum) ? "Enum " : "Flags ";
			writer ~= " member ";
			writeSymbol(writer, ctx.allSymbols, x.struct_.name);
			writer ~= '.';
			writeSymbol(writer, ctx.allSymbols, x.member.name);
		},
		(PositionKind.Expression x) {
			getExprHover(writer, ctx, pos.module_.uri, x.container.toTypeContainer, *x.expr);
		},
		(FunDecl* x) {
			writeFunDecl(writer, ctx, x);
		},
		(PositionKind.ImportedModule x) {
			writer ~= "Import module ";
			writeFile(writer, ctx, x.module_.uri);
		},
		(PositionKind.ImportedName x) {
			getImportedNameHover(writer, ctx, x);
		},
		(PositionKind.Keyword x) {
			writer ~= () {
				final switch (x.kind) {
					case PositionKind.Keyword.Kind.alias_:
						return "Declares a type alias.";
					case PositionKind.Keyword.Kind.builtin:
						return "Declares a type implemented natively by Crow.";
					case PositionKind.Keyword.Kind.enum_:
						return "Declares an enumerated type. The type can only have the values listed.";
					case PositionKind.Keyword.Kind.extern_:
						return "Declares a type implemented by an external library.";
					case PositionKind.Keyword.Kind.flags:
						return "Declares a type that can have any combination of flags (this would be an 'enum' in C)";
					case PositionKind.Keyword.Kind.global:
						return "Declares a mutable global variable (shared between all threads).";
					case PositionKind.Keyword.Kind.localMut:
						return "Makes this a mutable variable.";
					case PositionKind.Keyword.Kind.record:
						return "Declares a type combining several named members.";
					case PositionKind.Keyword.Kind.spec:
						return "Specifies function signatures which to be provided by a function's caller.";
					case PositionKind.Keyword.Kind.threadLocal:
						return "Declares a mutable thread-local variable.";
					case PositionKind.Keyword.Kind.underscore:
						return "Ignores the value.";
					case PositionKind.Keyword.Kind.union_:
						return "Declares a type where a value will be one of the listed choices.";
				}
			}();
		},
		(PositionKind.LocalPosition x) {
			writer ~= "Local ";
			localHover(writer, ctx, x.container.toTypeContainer, *x.local);
		},
		(PositionKind.MatchEnumCase x) {
			writer ~= "Handler for enum ";
			writeName(writer, ctx, x.member.containingEnum.name);
			writer ~= " member ";
			writeName(writer, ctx, x.member.name);
		},
		(PositionKind.MatchUnionCase x) {
			writer ~= "Handler for union ";
			writeName(writer, ctx, x.member.containingUnion.name);
			writer ~= " member ";
			writeName(writer, ctx, x.member.name);
		},
		(PositionKind.Modifier x) {
			writer ~= () {
				final switch (x.modifier) {
					case ModifierKeyword.bare:
						return "This function does not use the Crow runtime.";
					case ModifierKeyword.builtin:
						return "This function is implemented natively by Crow.";
					case ModifierKeyword.byRef:
						return "This type is behind a pointer.\n" ~
							"This is more efficient if there are many references to the same value.";
					case ModifierKeyword.byVal:
						return "This type is stored by-value.\n" ~
							"This avoids allocation but each place this value is used has its own copy of the content.";
					case ModifierKeyword.data:
						return "The type is completely immutable.";
					case ModifierKeyword.extern_:
						return "This type is compatible with external libraries.";
					case ModifierKeyword.forceCtx:
						return "This function uses the runtime, but 'bare' functions can call it. " ~
							"(Don't use outside of the Crow runtime.)";
					case ModifierKeyword.forceShared:
						return "This type is be considered 'shared' even though it has 'mut' content.";
					case ModifierKeyword.mut:
						return "This type is either directly mutable or references something mutable.";
					case ModifierKeyword.newInternal:
						return "The 'new' function is internal.";
					case ModifierKeyword.newPrivate:
						return "The 'new' function is private.";
					case ModifierKeyword.newPublic:
						return "The 'new' function is public.";
					case ModifierKeyword.packed:
						return "The type will be laid out without gaps for alignment.";
					case ModifierKeyword.shared_:
						return "The type is mutable, but in a way that is safe to share between concurrent tasks.";
					case ModifierKeyword.summon:
						return "This function can directly access all I/O capacilities.";
					case ModifierKeyword.trusted:
						return "This function is not unsafe, but can do unsafe things internally.";
					case ModifierKeyword.unsafe:
						return "This function can only be called by 'trusted' or 'unsafe' functions.";
				}
			}();
		},
		(PositionKind.ModifierExtern x) {
			writer ~= "Function comes from external library ";
			writeName(writer, ctx, x.libraryName);
			writer ~= '.';
		},
		(PositionKind.RecordFieldMutability x) {
			writer ~= "Defines a ";
			if (has(x.visibility)) {
				writeVisibility(writer, ctx.show, force(x.visibility));
				writer ~= ' ';
			}
			writer ~= "setter.";
		},
		(PositionKind.RecordFieldPosition x) {
			writer ~= "Record field ";
			writeSymbol(writer, ctx.allSymbols, x.struct_.name);
			writer ~= '.';
			writeSymbol(writer, ctx.allSymbols, x.field.name);
			writer ~= " (of type ";
			writeTypeQuoted(writer, ctx, TypeWithContainer(x.field.type, TypeContainer(x.struct_)));
			writer ~= ')';
		},
		(SpecDecl* x) {
			writeSpecDeclHover(writer, ctx, *x);
		},
		(PositionKind.SpecSig x) {
			writer ~= "Spec signature ";
			writeName(writer, ctx, x.sig.name);
		},
		(PositionKind.SpecUse x) {
			writer ~= "Spec ";
			writeSpecInst(writer, ctx, x.container, *x.spec);
		},
		(StructAlias* x) {
			writeStructAliasHover(writer, ctx, x);
		},
		(StructDecl* x) {
			writeStructDeclHover(writer, ctx, *x);
		},
		(Test* x) {
			writer ~= "Declares a unit test.";
		},
		(TypeWithContainer x) {
			x.type.matchIn!void(
				(in Type.Bogus) {},
				(in TypeParamIndex p) {
					hoverTypeParam(writer, ctx, x.container, p);
				},
				(in StructInst i) {
					writeStructDeclHover(writer, ctx, *i.decl);
				});
		},
		(PositionKind.TypeParamWithContainer x) {
			hoverTypeParam(writer, ctx, x.container, x.typeParam);
		},
		(PositionKind.UnionMemberPosition x) {
			writer ~= "Union member ";
			writeSymbol(writer, ctx.allSymbols, x.struct_.name);
			writer ~= '.';
			writeSymbol(writer, ctx.allSymbols, x.member.name);
			if (x.member.type == Type(ctx.commonTypes.void_))
				writer ~= " (no associated value)";
			else {
				writer ~= " (of type ";
				writeTypeQuoted(writer, ctx, TypeWithContainer(x.member.type, TypeContainer(x.struct_)));
				writer ~= ')';
			}
		},
		(VarDecl* x) {
			writer ~= stringOfVarKindUpperCase(x.kind);
			writer ~= " variable ";
			writeName(writer, ctx, x.name);
			writer ~= " (of type ";
			writeTypeQuoted(writer, ctx, TypeWithContainer(x.type, TypeContainer(x)));
			writer ~= ')';
		},
		(PositionKind.VisibilityMark x) {
			writer ~= "Marks ";
			writeName(writer, ctx, x.container.name);
			writer ~= " as ";
			writeVisibility(writer, ctx, x.container.visibility);
			writer ~= '.';
		});

private:

void writeStructAliasHover(scope ref Writer writer, in ShowModelCtx ctx, in StructAlias* a) {
	writer ~= "Alias for ";
	writeTypeQuoted(writer, ctx, TypeWithContainer(Type(a.target), TypeContainer(a)));
}

void writeStructDeclHover(scope ref Writer writer, in ShowModelCtx ctx, in StructDecl a) {
	writer ~= a.body_.matchIn!string(
		(in StructBody.Bogus) =>
			"Type ",
		(in BuiltinType _) =>
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

void writeSpecDeclHover(scope ref Writer writer, in ShowModelCtx ctx, in SpecDecl a) {
	writer ~= "Spec ";
	writeName(writer, ctx, a.name);
}

void getImportedNameHover(scope ref Writer writer, in ShowModelCtx ctx, in PositionKind.ImportedName a) {
	if (has(a.referents)) {
		bool first = true;
		void separate() {
			if (!first)
				writeNewline(writer, 0);
			first = false;
		}

		NameReferents* referents = force(a.referents);
		if (has(referents.structOrAlias)) {
			force(referents.structOrAlias).matchWithPointers!void(
				(StructAlias* x) {
					separate();
					writeStructAliasHover(writer, ctx, x);
				},
				(StructDecl* x) {
					separate();
					writeStructDeclHover(writer, ctx, *x);
				});
		}
		if (has(referents.spec)) {
			separate();
			writeSpecDeclHover(writer, ctx, *force(referents.spec));
		}
		foreach (FunDecl* x; referents.funs) {
			separate();
			writeFunDecl(writer, ctx, x);
		}
	}
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
					case LambdaExpr.Kind.data:
						return "Lambda with 'data' closure and no 'summon'.";
					case LambdaExpr.Kind.shared_:
						return "Lambda with 'shared' closure.";
					case LambdaExpr.Kind.mut:
						return "Lambda with 'mut' closure.";
					case LambdaExpr.Kind.explicitShared:
						return "Lambda with 'mut' closure, converted to 'shared' by waiting for exclusion.";
				}
			}();
		},
		(in LetExpr _) {},
		(in LiteralExpr _) {
			writer ~= "Number literal";
		},
		(in LiteralStringLikeExpr x) {
			writer ~= "Literal '";
			writer ~= () {
				final switch (x.kind) {
					case LiteralStringLikeExpr.Kind.cString:
						return "c-string";
					case LiteralStringLikeExpr.Kind.string_:
						return "string";
					case LiteralStringLikeExpr.Kind.symbol:
						return "symbol";
				}
			}();
			writer ~= "'";
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
			writer ~= "Gets pointer to field ";
			writeName(writer, ctx, x.fieldDecl(ctx.commonTypes).name);
			writer ~= " of record ";
			writeName(writer, ctx, x.recordDecl(ctx.commonTypes).name);
			writer ~= '.';
		},
		(in PtrToLocalExpr x) {
			writer ~= "Pointer to ";
			localHover(writer, ctx, typeContainer, *x.local);
		},
		(in SeqExpr _) {},
		(in ThrowExpr _) {
			writer ~= "Throws an exception.";
		},
		(in TrustedExpr _) {
			writer ~= "Allows 'unsafe' code to be used anywhere.";
		},
		(in TypedExpr _) {
			writer ~= "Provides an explicit type for the left hand side of '::'.";
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
