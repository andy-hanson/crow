module frontend.ide.getHover;

@safe @nogc pure nothrow:

import frontend.ide.position : ExpressionPosition, ExpressionPositionKind, ExprKeyword, ExprRef, Position, PositionKind;
import frontend.showModel :
	ShowModelCtx,
	writeCalled,
	writeFile,
	writeFunDecl,
	writeFunInst,
	writeLineAndColumn,
	writeName,
	writeSpecInst,
	writeTypeQuoted,
	writeVisibility;
import lib.lsp.lspTypes : Hover, MarkupContent, MarkupKind;
import model.ast : ExprAstKind, IfAst, IfOptionAst, ModifierKeyword, TernaryAst;
import model.diag : TypeContainer, TypeWithContainer;
import model.model :
	BuiltinType,
	CallExpr,
	EnumOrFlagsMember,
	ExprKind,
	FunDecl,
	FunPointerExpr,
	LambdaExpr,
	Local,
	NameReferents,
	RecordField,
	StructAlias,
	StructBody,
	SpecDecl,
	stringOfVarKindUpperCase,
	StructDecl,
	StructInst,
	Test,
	Type,
	TypeParamIndex,
	UnionMember,
	VarDecl;
import util.alloc.alloc : Alloc;
import util.opt : force, has;
import util.sourceRange : PosKind;
import util.symbol : writeSymbol;
import util.uri : Uri;
import util.writer : makeStringWithWriter, writeNewline, Writer;

Hover getHover(ref Alloc alloc, in ShowModelCtx ctx, in Position pos) =>
	Hover(MarkupContent(MarkupKind.plaintext, makeStringWithWriter(alloc, (scope ref Writer writer) {
		getHover(writer, ctx, pos);
	})));

void getHover(scope ref Writer writer, in ShowModelCtx ctx, in Position pos) =>
	pos.kind.matchWithPointers!void(
		(EnumOrFlagsMember* x) {
			writer ~= x.containingEnum.body_.isA!(StructBody.Enum) ? "Enum " : "Flags ";
			writer ~= " member ";
			writeSymbol(writer, ctx.allSymbols, x.containingEnum.name);
			writer ~= '.';
			writeSymbol(writer, ctx.allSymbols, x.name);
		},
		(ExpressionPosition x) {
			getExprHover(writer, ctx, pos.module_.uri, x);
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
			writeName(writer, ctx, x.local.name);
			writer ~= " of type ";
			writeTypeQuoted(writer, ctx, TypeWithContainer(x.local.type, x.container.toTypeContainer));
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
					case ModifierKeyword.nominal:
						return "The type's constructor uses the type's name instead of 'new'.";
					case ModifierKeyword.packed:
						return "The type will be laid out without gaps for alignment.";
					case ModifierKeyword.shared_:
						return "The type is mutable, but in a way that is safe to share between concurrent tasks.";
					case ModifierKeyword.storage:
						return "Determines the type of number used to store the enum.";
					case ModifierKeyword.summon:
						return "This function can directly access all I/O capabilities.";
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
		(RecordField* x) {
			writer ~= "Record field ";
			writeSymbol(writer, ctx.allSymbols, x.containingRecord.name);
			writer ~= '.';
			writeSymbol(writer, ctx.allSymbols, x.name);
			writer ~= " (of type ";
			writeTypeQuoted(writer, ctx, TypeWithContainer(x.type, TypeContainer(x.containingRecord)));
			writer ~= ')';
		},
		(PositionKind.RecordFieldMutability x) {
			writer ~= "Defines a ";
			if (has(x.visibility)) {
				writeVisibility(writer, ctx.show, force(x.visibility));
				writer ~= ' ';
			}
			writer ~= "setter.";
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
		(UnionMember* x) {
			writer ~= "Union member ";
			writeSymbol(writer, ctx.allSymbols, x.containingUnion.name);
			writer ~= '.';
			writeSymbol(writer, ctx.allSymbols, x.name);
			if (x.type == Type(ctx.commonTypes.void_))
				writer ~= " (no associated value)";
			else {
				writer ~= " (of type ";
				writeTypeQuoted(writer, ctx, TypeWithContainer(x.type, TypeContainer(x.containingUnion)));
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

void getExprKeywordHover(
	scope ref Writer writer,
	in ShowModelCtx ctx,
	in Uri curUri,
	in TypeContainer typeContainer,
	in ExprRef a,
	ExprKeyword keyword,
) {
	ExprKind exprKind() =>
		a.expr.kind;
	ExprAstKind astKind() =>
		a.expr.ast.kind;
	final switch (keyword) {
		case ExprKeyword.ampersand:
			writer ~= "Gets a pointer to an expression. " ~
				"This does not allocate and so is unsafe. This only works for certain expressions.";
			break;
		case ExprKeyword.assert_:
			writer ~= "Throws if the condition is 'false'.";
			break;
		case ExprKeyword.colonColon:
			writer ~= "Provides an expected type for the expression to its left.";
			break;
		case ExprKeyword.elif:
			writer ~= "If the first condition is false, evaluates another 'if'.";
			break;
		case ExprKeyword.else_:
			writer ~= "If the condition is 'false', the 'else' branch is evaluated.";
			break;
		case ExprKeyword.forbid:
			writer ~= "Throws if the condition is 'true'.";
			break;
		case ExprKeyword.if_:
			if (astKind.isA!(IfOptionAst*)) {
				writer ~= "If the value is a non-empty option, destructures it and returns the first branch. ";
				writer ~= astKind.as!(IfOptionAst*).hasElse
					? " Otherwise, returns the second branch."
					: " Otherwise, returns '()'.";
			} else {
				writer ~= "If the condition is 'true', returns the first branch. ";
				bool hasElse = astKind.isA!(IfAst*)
					? astKind.as!(IfAst*).hasElse
					: astKind.as!(TernaryAst*).hasElse;
				writer ~= hasElse
					? " Otherwise, returns the second branch."
					: " Otherwise, returns '()'.";
			}
			break;
		case ExprKeyword.lambdaArrow:
			writer ~= () {
				final switch (exprKind.as!(LambdaExpr*).kind) {
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
			break;
		case ExprKeyword.match:
			writer ~= "Branches with a separate case for each member of the enum or union.";
			break;
		case ExprKeyword.throw_:
			writer ~= "Throws an exception.";
			break;
		case ExprKeyword.trusted:
			writer ~= "Allows 'unsafe' code to be used anywhere.";
			break;
		case ExprKeyword.unless:
			writer ~= "Returns the body if the condition is false. If the condition is true, returns '()'.";
			break;
		case ExprKeyword.until:
			writer ~= "Loop will run as long as the condition is 'false'.";
			break;
		case ExprKeyword.while_:
			writer ~= "Loop will run as long as the condition is 'true'.";
			break;
	}
}

void getExprHover(
	scope ref Writer writer,
	in ShowModelCtx ctx,
	in Uri curUri,
	in ExpressionPosition a,
) {
	TypeContainer typeContainer = a.container.toTypeContainer;
	a.kind.matchIn!void(
		(in CallExpr x) {
			writer ~= "Calls ";
			writeCalled(writer, ctx, typeContainer, x.called);
			writer ~= '.';
		},
		(in ExprKeyword x) {
			getExprKeywordHover(writer, ctx, curUri, typeContainer, a.expr, x);
		},
		(in FunPointerExpr x) {
			writer ~= "Pointer to function ";
			writeFunInst(writer, ctx, typeContainer, *x.funInst);
		},
		(in ExpressionPositionKind.Literal x) {
			writer ~= "Literal expression.";
		},
		(in ExpressionPositionKind.LocalRef x) {
			writer ~= () {
				final switch (x.kind) {
					case ExpressionPositionKind.LocalRef.Kind.get:
						return "Gets local variable ";
					case ExpressionPositionKind.LocalRef.Kind.set:
						return "Sets local variable ";
					case ExpressionPositionKind.LocalRef.Kind.closureGet:
						return "Gets local variable ";
					case ExpressionPositionKind.LocalRef.Kind.closureSet:
						return "Sets local variable ";
					case ExpressionPositionKind.LocalRef.Kind.pointer:
						return "Gets pointer to local variable ";
				}
			}();
			writeName(writer, ctx, x.local.name);
			writer ~= () {
				final switch (x.kind) {
					case ExpressionPositionKind.LocalRef.Kind.get:
					case ExpressionPositionKind.LocalRef.Kind.set:
					case ExpressionPositionKind.LocalRef.Kind.pointer:
						return "";
					case ExpressionPositionKind.LocalRef.Kind.closureGet:
					case ExpressionPositionKind.LocalRef.Kind.closureSet:
						return " (through closure)";
				}
			}();
			writer ~= '.';
		},
		(in ExpressionPositionKind.LoopKeyword x) {
			final switch (x.kind) {
				case ExpressionPositionKind.LoopKeyword.Kind.break_:
					writer ~= "Breaks out of ";
					writeLoop(writer, ctx, curUri, x.loop);
					writer ~= '.';
					break;
				case ExpressionPositionKind.LoopKeyword.Kind.continue_:
					writer ~= "Goes back to the start of ";
					writeLoop(writer, ctx, curUri, x.loop);
					writer ~= '.';
					break;
				case ExpressionPositionKind.LoopKeyword.Kind.loop:
					writer ~= "Loop that terminates at a 'break'.";
					break;
			}
		});

	writer ~= "\nExpression type is: ";
	writeTypeQuoted(writer, ctx, TypeWithContainer(a.expr.type, typeContainer));
}

void writeLoop(scope ref Writer writer, in ShowModelCtx ctx, Uri curUri, in ExprRef a) {
	writer ~= "the loop at ";
	writeLineAndColumn(writer, ctx.lineAndColumnGetters[curUri][a.expr.range.start, PosKind.startOfRange]);
}
