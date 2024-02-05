module frontend.ide.getPosition;

@safe @nogc pure nothrow:

import frontend.ide.ideUtil : eachTypeArgForSpecUse, eachTypeComponent, specsMatch;
import frontend.ide.position : ExprContainer, LocalContainer, Position, PositionKind, VisibilityContainer;
import model.ast :
	CallAst,
	DestructureAst,
	IdentifierAst,
	ExprAst,
	FieldMutabilityAst,
	FunDeclAst,
	ModifierAst,
	IfOptionAst,
	ImportOrExportAst,
	LambdaAst,
	LetAst,
	MatchAst,
	NameAndRange,
	paramsArray,
	ParamsAst,
	RecordFieldAst,
	SpecSigAst,
	SpecUseAst,
	StructBodyAst,
	StructDeclAst,
	TestAst,
	TypeAst,
	VisibilityAndRange;
import model.diag : TypeContainer, TypeWithContainer;
import model.model :
	AssertOrForbidExpr,
	BogusExpr,
	BuiltinType,
	CallExpr,
	ClosureGetExpr,
	ClosureSetExpr,
	Destructure,
	EnumMember,
	Expr,
	FunBody,
	FunDecl,
	FunDeclSource,
	FunPointerExpr,
	IfExpr,
	IfOptionExpr,
	ImportOrExport,
	ImportOrExportKind,
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
	Module,
	nameRange,
	NameReferents,
	Params,
	PtrToFieldExpr,
	PtrToLocalExpr,
	RecordField,
	SeqExpr,
	SpecInst,
	StructBody,
	SpecDecl,
	SpecDeclSig,
	StructAlias,
	StructDecl,
	Test,
	ThrowExpr,
	TrustedExpr,
	Type,
	TypedExpr,
	TypeParamIndex,
	UnionMember,
	VarDecl;
import model.model : paramsArray, StructDeclSource;
import util.col.array :
	first, firstPointer, firstWithIndex, firstZip, firstZipPointerFirst, firstZipPointerFirst3, isEmpty, SmallArray;
import util.conv : safeToUint;
import util.opt : force, has, none, Opt, optIf, optOr, optOr, optOrDefault, some;
import util.sourceRange : hasPos, Pos, Range;
import util.symbol : AllSymbols;
import util.union_ : Union;
import util.uri : AllUris;
import util.util : enumConvert, ptrTrustMe;

Position getPosition(in AllSymbols allSymbols, in AllUris allUris, Module* module_, Pos pos) {
	Opt!PositionKind kind = getPositionKind(allSymbols, allUris, *module_, pos);
	return Position(module_, has(kind) ? force(kind) : PositionKind(PositionKind.None()));
}

private:

Opt!PositionKind getPositionKind(in AllSymbols allSymbols, in AllUris allUris, ref Module module_, Pos pos) =>
	optOr!PositionKind(
		positionInImportsOrExports(allSymbols, allUris, module_.imports, pos),
		() => positionInImportsOrExports(allSymbols, allUris, module_.reExports, pos),
		() => firstPointer!(PositionKind, StructAlias)(module_.aliases, (StructAlias* x) =>
			hasPos(x.range.range, pos)
				? positionInAlias(allSymbols, x, pos)
				: none!PositionKind),
		() => firstPointer!(PositionKind, StructDecl)(module_.structs, (StructDecl* x) =>
			hasPos(x.range.range, pos)
				? positionInStruct(allSymbols, x, pos)
				: none!PositionKind),
		() => firstPointer!(PositionKind, VarDecl)(module_.vars, (VarDecl* x) =>
			hasPos(x.range.range, pos)
				? positionInVar(allSymbols, x, pos)
				: none!PositionKind),
		() => firstPointer!(PositionKind, SpecDecl)(module_.specs, (SpecDecl* x) =>
			hasPos(x.range.range, pos)
				? positionInSpec(allSymbols, x, pos)
				: none!PositionKind),
		() => firstPointer!(PositionKind, FunDecl)(module_.funs, (FunDecl* x) =>
			x.source.isA!(FunDeclSource.Ast)
				? positionInFun(allSymbols, x, x.source.as!(FunDeclSource.Ast).ast, pos)
				: none!PositionKind),
		() => firstPointer!(PositionKind, Test)(module_.tests, (Test* x) =>
			hasPos(x.ast.range, pos)
				? some(positionInTest(allSymbols, x, *x.ast, pos))
				: none!PositionKind));

Opt!PositionKind positionInFun(in AllSymbols allSymbols, FunDecl* a, in FunDeclAst* ast, Pos pos) =>
	optOr!PositionKind(
		positionInVisibility(VisibilityContainer(a), ast.visibility, pos),
		() => optIf(hasPos(allSymbols, ast.name, pos), () => PositionKind(a)),
		() => positionInTypeParams(allSymbols, TypeContainer(a), ast.typeParams, pos),
		() => positionInType(allSymbols, TypeContainer(a), a.returnType, ast.returnType, pos),
		() => positionInParams(allSymbols, LocalContainer(a), a.params, ast.params, pos),
		() => positionInModifiers(allSymbols, TypeContainer(a), some(a.specs), ast.modifiers, pos),
		() => a.body_.isA!(FunBody.ExpressionBody)
			? positionInExpr(allSymbols, ExprContainer(a), a.body_.as!(FunBody.ExpressionBody).expr, pos)
			: none!PositionKind);

PositionKind positionInTest(in AllSymbols allSymbols, Test* a, in TestAst ast, Pos pos) =>
	optOrDefault!PositionKind(
		positionInExpr(allSymbols, ExprContainer(a), a.body_, pos),
		() => PositionKind(a));

Opt!PositionKind positionInParams(
	in AllSymbols allSymbols,
	LocalContainer container,
	in Params params,
	in ParamsAst ast,
	Pos pos,
) =>
	firstZip!(PositionKind, Destructure, DestructureAst)(
		paramsArray(params), paramsArray(ast), (Destructure x, DestructureAst y) =>
			positionInDestructure(allSymbols, container, x, y, pos));

Opt!PositionKind positionInModifiers(
	in AllSymbols allSymbols,
	TypeContainer container,
	in Opt!(SmallArray!(immutable SpecInst*)) specs,
	in ModifierAst[] modifiers,
	Pos pos,
) =>
	firstWithIndex!(PositionKind, ModifierAst)(modifiers, (size_t index, ModifierAst modifier) =>
		optIf(hasPos(modifier.range(allSymbols), pos), () =>
			positionInModifier(allSymbols, container, specs, modifiers, index, modifier, pos)));

PositionKind positionInModifier(
	in AllSymbols allSymbols,
	TypeContainer container,
	Opt!(SmallArray!(immutable SpecInst*)) specs,
	in ModifierAst[] modifiers,
	size_t index,
	in ModifierAst modifier,
	Pos pos,
) =>
	modifier.matchIn!PositionKind(
		(in ModifierAst.Keyword x) =>
			PositionKind(PositionKind.Modifier(container, x.kind)),
		(in ModifierAst.Extern x) =>
			container.isA!(FunDecl*) && container.as!(FunDecl*).body_.isA!(FunBody.Extern)
				? PositionKind(PositionKind.ModifierExtern(
					container.as!(FunDecl*).body_.as!(FunBody.Extern).libraryName))
				: PositionKind(PositionKind.None()),
		(in SpecUseAst x) {
			if (has(specs) && specsMatch(force(specs), modifiers)) {
				// Find the corresponding spec
				size_t specIndex = 0;
				foreach (ref ModifierAst prevModifier; modifiers[0 .. index])
					if (prevModifier.isA!SpecUseAst)
						specIndex++;

				SpecInst* spec = force(specs)[specIndex];
				return optOrDefault!PositionKind(
					eachTypeArgForSpecUse!PositionKind(spec.typeArgs, x, (in Type t, in TypeAst a) =>
						positionInType(allSymbols, container, t, a, pos)),
					() => PositionKind(PositionKind.SpecUse(container, force(specs)[specIndex])));
			} else
				return PositionKind(PositionKind.None());
		});

Opt!PositionKind positionInDestructure(ref ExprCtx ctx, in Destructure a, in DestructureAst ast, Pos pos) =>
	positionInDestructure(ctx.allSymbols, ctx.container.toLocalContainer, a, ast, pos);

Opt!PositionKind positionInDestructure(
	in AllSymbols allSymbols,
	LocalContainer container,
	in Destructure a,
	in DestructureAst destructureAst,
	Pos pos,
) {
	Opt!PositionKind handleSingle(Type type, in PositionKind delegate() @safe @nogc pure nothrow cbName) {
		DestructureAst.Single ast = destructureAst.as!(DestructureAst.Single);
		return hasPos(ast.range(allSymbols), pos)
			? optOr!PositionKind(
				optIf(hasPos(ast.nameRange(allSymbols), pos), cbName),
				() => optIf(optHasPos(ast.mutRange, pos), () =>
					PositionKind(PositionKind.Keyword(PositionKind.Keyword.Kind.localMut))),
				() => has(ast.type)
					? positionInType(allSymbols, container.toTypeContainer(), type, *force(ast.type), pos)
					: none!PositionKind)
			: none!PositionKind;
	}
	return a.matchWithPointers!(Opt!PositionKind)(
		(Destructure.Ignore* x) =>
			destructureAst.isA!(DestructureAst.Void)
				? none!PositionKind
				: handleSingle(x.type, () => PositionKind(PositionKind.Keyword(PositionKind.Keyword.Kind.underscore))),
		(Local* x) =>
			handleSingle(x.type, () => PositionKind(PositionKind.LocalPosition(container, x))),
		(Destructure.Split* x) =>
			isEmpty(x.parts)
				? none!PositionKind
				: firstZip!(PositionKind, Destructure, DestructureAst)(
					x.parts, destructureAst.as!(DestructureAst[]), (Destructure part, DestructureAst partAst) =>
						positionInDestructure(allSymbols, container, part, partAst, pos)));
}

Opt!PositionKind positionInImportsOrExports(
	in AllSymbols allSymbols,
	in AllUris allUris,
	ImportOrExport[] importsOrExports,
	Pos pos,
) {
	foreach (ref ImportOrExport im; importsOrExports)
		if (has(im.source) && hasPos(force(im.source).range, pos)) {
			ImportOrExportAst* source = force(im.source);
			return im.kind.matchIn!(Opt!PositionKind)(
				(in ImportOrExportKind.ModuleWhole) =>
					some(PositionKind(PositionKind.ImportedModule(&im))),
				(in Opt!(NameReferents*)[] referents) =>
					hasPos(force(im.source).pathRange(allUris), pos)
						? some(PositionKind(PositionKind.ImportedModule(&im)))
						: positionInImportedNames(
							allSymbols, im.modulePtr, source.kind.as!(NameAndRange[]), referents, pos));
		}
	return none!PositionKind;
}

Opt!PositionKind positionInImportedNames(
	in AllSymbols allSymbols,
	Module* module_,
	in NameAndRange[] names,
	in Opt!(NameReferents*)[] referents,
	Pos pos,
) {
	foreach (size_t index, NameAndRange x; names)
		if (hasPos(allSymbols, x, pos))
			return some(PositionKind(PositionKind.ImportedName(module_, x.name, referents[index])));
	return none!PositionKind;
}

Opt!PositionKind positionInVar(in AllSymbols allSymbols, VarDecl* a, Pos pos) =>
	optOr!PositionKind(
		positionInVisibility(VisibilityContainer(a), a.ast.visibility, pos),
		() => optIf(hasPos(a.nameRange(allSymbols).range, pos), () => PositionKind(a)),
		() => optIf(hasPos(a.ast.keywordRange, pos), () =>
			PositionKind(PositionKind.Keyword(enumConvert!(PositionKind.Keyword.Kind)(a.kind)))),
		() => positionInType(allSymbols, TypeContainer(a), a.type, a.ast.type, pos));

Opt!PositionKind positionInAlias(in AllSymbols allSymbols, StructAlias* a, Pos pos) =>
	optOr!PositionKind(
		positionInVisibility(VisibilityContainer(a), a.ast.visibility, pos),
		() => optIf(hasPos(a.nameRange(allSymbols).range, pos), () => PositionKind(a)),
		() => optIf(hasPos(a.ast.keywordRange, pos), () =>
			PositionKind(PositionKind.Keyword(PositionKind.Keyword.Kind.alias_))),
		() => positionInType(allSymbols, TypeContainer(a), Type(a.target), a.ast.target, pos));

Opt!PositionKind positionInStruct(in AllSymbols allSymbols, StructDecl* a, Pos pos) =>
	a.source.matchIn!(Opt!PositionKind)(
		(in StructDeclAst x) =>
			positionInStruct(allSymbols, a, x, pos),
		(in StructDeclSource.Bogus) =>
			none!PositionKind);

Opt!PositionKind positionInStruct(in AllSymbols allSymbols, StructDecl* a, in StructDeclAst ast, Pos pos) =>
	optOr!PositionKind(
		positionInVisibility(VisibilityContainer(a), ast.visibility, pos),
		() => optIf(hasPos(a.nameRange(allSymbols).range, pos), () => PositionKind(a)),
		() => optIf(hasPos(ast.keywordRange, pos), () =>
			PositionKind(PositionKind.Keyword(keywordKindForStructBody(ast.body_)))),
		() => positionInTypeParams(allSymbols, TypeContainer(a), ast.typeParams, pos),
		() => positionInModifiers(
			allSymbols, TypeContainer(a), none!(SmallArray!(immutable SpecInst*)), ast.modifiers, pos),
		() => positionInStructBody(allSymbols, a, a.body_, ast.body_, pos));

PositionKind.Keyword.Kind keywordKindForStructBody(in StructBodyAst a) =>
	a.matchIn!(PositionKind.Keyword.Kind)(
		(in StructBodyAst.Builtin) =>
			PositionKind.Keyword.Kind.builtin,
		(in StructBodyAst.Enum) =>
			PositionKind.Keyword.Kind.enum_,
		(in StructBodyAst.Extern) =>
			PositionKind.Keyword.Kind.extern_,
		(in StructBodyAst.Flags) =>
			PositionKind.Keyword.Kind.flags,
		(in StructBodyAst.Record) =>
			PositionKind.Keyword.Kind.record,
		(in StructBodyAst.Union) =>
			PositionKind.Keyword.Kind.union_);

Opt!PositionKind positionInVisibility(VisibilityContainer a, in Opt!VisibilityAndRange visibility, Pos pos) =>
	has(visibility) && hasPos(force(visibility).range, pos)
		? some(PositionKind(PositionKind.VisibilityMark(a)))
		: none!PositionKind;

Opt!PositionKind positionInTypeParams(
	in AllSymbols allSymbols,
	TypeContainer container,
	in NameAndRange[] asts,
	Pos pos,
) =>
	firstWithIndex!(PositionKind, NameAndRange)(asts, (size_t index, NameAndRange x) =>
		optIf(hasPos(allSymbols, x, pos), () =>
			PositionKind(PositionKind.TypeParamWithContainer(TypeParamIndex(safeToUint(index)), container))));

Opt!PositionKind positionInSpec(in AllSymbols allSymbols, SpecDecl* a, Pos pos) =>
	optOr!PositionKind(
		positionInVisibility(VisibilityContainer(a), a.ast.visibility, pos),
		() => optIf(hasPos(allSymbols, a.ast.name, pos), () => PositionKind(a)),
		() => positionInTypeParams(allSymbols, TypeContainer(a), a.ast.typeParams, pos),
		() => optIf(hasPos(a.ast.keywordRange, pos), () =>
			PositionKind(PositionKind.Keyword(PositionKind.Keyword.Kind.spec))),
		() => positionInModifiers(allSymbols, TypeContainer(a), some(a.parents), a.ast.modifiers, pos),
		() => positionInSpecSigs(allSymbols, a, pos));

Opt!PositionKind positionInSpecSigs(in AllSymbols allSymbols, SpecDecl* a, Pos pos) =>
	firstZipPointerFirst!(PositionKind, SpecDeclSig, SpecSigAst)(
		a.sigs, a.ast.sigs, (SpecDeclSig* sig, SpecSigAst sigAst) =>
			positionInSpecSig(allSymbols, a, sig, sigAst, pos));

Opt!PositionKind positionInSpecSig(
	in AllSymbols allSymbols,
	SpecDecl* spec,
	SpecDeclSig* sig,
	in SpecSigAst ast,
	Pos pos,
) =>
	hasPos(ast.range, pos)
		? optOr!PositionKind(
			optIf(hasPos(allSymbols, ast.nameAndRange, pos), () =>
				PositionKind(PositionKind.SpecSig(spec, sig))),
			() => positionInType(allSymbols, TypeContainer(spec), sig.returnType, ast.returnType, pos),
			() => positionInParams(allSymbols, LocalContainer(spec), Params(sig.params), ast.params, pos))
		: none!PositionKind;

Opt!PositionKind positionInStructBody(
	in AllSymbols allSymbols,
	StructDecl* decl,
	ref StructBody body_,
	in StructBodyAst ast,
	Pos pos,
) =>
	body_.match!(Opt!PositionKind)(
		(StructBody.Bogus) =>
			none!PositionKind,
		(BuiltinType _) =>
			none!PositionKind,
		(StructBody.Enum) =>
			none!PositionKind, // TODO
		(StructBody.Extern) =>
			none!PositionKind,
		(StructBody.Flags) =>
			none!PositionKind, // TODO
		(StructBody.Record x) =>
			firstZipPointerFirst!(PositionKind, RecordField, RecordFieldAst)(
				x.fields,
				ast.as!(StructBodyAst.Record).fields,
				(RecordField* field, RecordFieldAst fieldAst) =>
					positionInRecordField(allSymbols, decl, field, fieldAst, pos)),
		(StructBody.Union) =>
			//TODO
			none!PositionKind);

Opt!PositionKind positionInRecordField(
	in AllSymbols allSymbols,
	StructDecl* decl,
	RecordField* field,
	in RecordFieldAst fieldAst,
	Pos pos,
) =>
	optOr!PositionKind(
		positionInVisibility(VisibilityContainer(field), fieldAst.visibility, pos),
		() => optIf(hasPos(allSymbols, fieldAst.name, pos), () =>
			PositionKind(PositionKind.RecordFieldPosition(decl, field))),
		() => has(fieldAst.mutability)
			? positionInFieldMutability(allSymbols, force(fieldAst.mutability), pos)
			: none!PositionKind,
		() => positionInType(allSymbols, TypeContainer(decl), field.type, fieldAst.type, pos));

Opt!PositionKind positionInFieldMutability(in AllSymbols allSymbols, in FieldMutabilityAst ast, Pos pos) =>
	optIf(hasPos(ast.range, pos), () =>
		PositionKind(PositionKind.RecordFieldMutability(ast.visibility_)));

const struct ExprCtx {
	@safe @nogc pure nothrow:

	AllSymbols* allSymbolsPtr;
	ExprContainer container;

	ref const(AllSymbols) allSymbols() return scope =>
		*allSymbolsPtr;
}

Opt!PositionKind positionInExpr(in AllSymbols allSymbols, ExprContainer container, ref Expr a, Pos pos) {
	ExprCtx ctx = ExprCtx(ptrTrustMe(allSymbols), container);
	return positionInExpr(ctx, a, pos);
}

Opt!PositionKind positionInExpr(ref ExprCtx ctx, ref Expr a, Pos pos) {
	if (!hasPos(a.range, pos))
		return none!PositionKind;
	else {
		ExprAst* ast = a.ast;
		Opt!PositionKind here() =>
			some(PositionKind(PositionKind.Expression(ctx.container, &a)));
		Opt!PositionKind inDestructure(in Destructure x, in DestructureAst y) =>
			positionInDestructure(ctx, x, y, pos);
		Opt!PositionKind recur(in Expr inner) =>
			positionInExpr(ctx, inner, pos);
		Opt!PositionKind recurOpt(in Opt!(Expr*) inner) =>
			has(inner)
				? recur(*force(inner))
				: none!PositionKind;

		return a.kind.match!(Opt!PositionKind)(
			(AssertOrForbidExpr x) =>
				optOr!PositionKind(
					recur(*x.condition),
					() => recurOpt(x.thrown),
					() => here()),
			(BogusExpr _) =>
				none!PositionKind,
			(CallExpr x) {
				Opt!NameAndRange name = getCallName(*ast);
				return optOr!PositionKind(
					first!(PositionKind, Expr)(x.args, (Expr y) => recur(y)),
					() => !has(name) || hasPos(ctx.allSymbols, force(name), pos) ? here() : none!PositionKind);
			},
			(ClosureGetExpr _) =>
				here(),
			(ClosureSetExpr x) =>
				optOr!PositionKind(
					recur(*x.value),
					() => here()),
			(FunPointerExpr _) =>
				here(),
			(ref IfExpr x) =>
				optOr!PositionKind(
					recur(x.cond),
					() => recur(x.then),
					() => recur(x.else_),
					() => here()),
			(ref IfOptionExpr x) =>
				optOr!PositionKind(
					inDestructure(x.destructure, ast.kind.as!(IfOptionAst*).destructure),
					() => recur(x.option.expr),
					() => recur(x.then),
					() => recur(x.else_),
					() => here()),
			(ref LambdaExpr x) =>
				optOr!PositionKind(
					inDestructure(x.param, ast.kind.as!(LambdaAst*).param),
					() => recur(x.body_),
					() => here()),
			(ref LetExpr x) =>
				optOr!PositionKind(
					inDestructure(x.destructure, ast.kind.as!(LetAst*).destructure),
					() => recur(x.value),
					() => recur(x.then),
					() => here()),
			(ref LiteralExpr _) =>
				here(),
			(LiteralStringLikeExpr _) =>
				here(),
			(LocalGetExpr _) =>
				here(),
			(ref LocalSetExpr _) =>
				here(),
			(ref LoopExpr x) =>
				optOr!PositionKind(recur(x.body_), () => here()),
			(ref LoopBreakExpr x) =>
				optOr!PositionKind(recur(x.value), () => here()),
			(LoopContinueExpr _) =>
				here(),
			(ref LoopUntilExpr x) =>
				optOr!PositionKind(recur(x.condition), () => recur(x.body_), () => here()),
			(ref LoopWhileExpr x) =>
				optOr!PositionKind(recur(x.condition), () => recur(x.body_), () => here()),
			(ref MatchEnumExpr x) =>
				positionInMatchEnum(ctx, &a, x, *ast, pos),
			(ref MatchUnionExpr x) =>
				positionInMatchUnion(ctx, &a, x, *ast, pos),
			(ref PtrToFieldExpr x) =>
				optOr!PositionKind(
					recur(x.target.expr),
					() => here()),
			(PtrToLocalExpr) =>
				here(),
			(ref SeqExpr x) =>
				optOr!PositionKind(recur(x.first), () => recur(x.then)),
			(ref ThrowExpr x) =>
				optOr!PositionKind(recur(x.thrown), () => here()),
			(ref TrustedExpr x) =>
				optOr!PositionKind(recur(x.inner), () => here()),
			(ref TypedExpr x) =>
				optOr!PositionKind(
					recur(x.inner),
					() => hasPos(x.ast(a).keywordRange, pos) ? here() : none!PositionKind,
					() => positionInType(ctx.allSymbols, ctx.container.toTypeContainer, x.type, x.ast(a).type, pos)));
	}
}

Opt!NameAndRange getCallName(in ExprAst a) {
	if (a.kind.isA!CallAst) {
		final switch (a.kind.as!CallAst.style) {
			case CallAst.Style.comma:
			case CallAst.Style.emptyParens:
			case CallAst.Style.implicit:
			case CallAst.Style.subscript:
				return none!NameAndRange;
			case CallAst.Style.dot:
			case CallAst.Style.infix:
			case CallAst.Style.prefixBang:
			case CallAst.Style.prefixOperator:
			case CallAst.Style.single:
			case CallAst.Style.suffixBang:
				return some!NameAndRange(a.kind.as!CallAst.funName);
		}
	} else
		return optIf(a.kind.isA!IdentifierAst, () => NameAndRange(a.range.start, a.kind.as!IdentifierAst.name));
}

Opt!PositionKind positionInMatchEnum(in ExprCtx ctx, Expr* expr, ref MatchEnumExpr a, ref ExprAst ast, Pos pos) =>
	optOr!PositionKind(
		positionInMatchCommon(ctx, expr, a.matched.expr, ast, pos),
		() => firstZipPointerFirst3!(PositionKind, EnumMember, Expr, MatchAst.CaseAst)(
			a.enumMembers, a.cases, ast.kind.as!(MatchAst*).cases,
			(EnumMember* member, Expr then, MatchAst.CaseAst caseAst) =>
				optOr!PositionKind(
					optIf(hasPos(caseAst.keywordAndMemberNameRange(ctx.allSymbols), pos), () =>
						PositionKind(PositionKind.MatchEnumCase(member))),
					() => positionInExpr(ctx, then, pos))));

Opt!PositionKind positionInMatchUnion(in ExprCtx ctx, Expr* expr, ref MatchUnionExpr a, ref ExprAst ast, Pos pos) =>
	optOr!PositionKind(
		positionInMatchCommon(ctx, expr, a.matched.expr, ast, pos),
		() => firstZipPointerFirst3!(PositionKind, UnionMember, MatchUnionExpr.Case, MatchAst.CaseAst)(
			a.unionMembers, a.cases, ast.kind.as!(MatchAst*).cases,
			(UnionMember* member, MatchUnionExpr.Case case_, MatchAst.CaseAst caseAst) =>
				positionInMatchUnionCase(ctx, member, case_, caseAst, pos)));

Opt!PositionKind positionInMatchUnionCase(
	in ExprCtx ctx,
	UnionMember* member,
	MatchUnionExpr.Case case_,
	MatchAst.CaseAst ast,
	Pos pos,
) =>
	optOr!PositionKind(
		optIf(hasPos(ast.keywordAndMemberNameRange(ctx.allSymbols), pos), () =>
			PositionKind(PositionKind.MatchUnionCase(member))),
		() => has(ast.destructure)
			? positionInDestructure(ctx, case_.destructure, force(ast.destructure), pos)
			: none!PositionKind,
		() => positionInExpr(ctx, case_.then, pos));

Opt!PositionKind positionInMatchCommon(in ExprCtx ctx, Expr* matchExpr, ref Expr matched, ref ExprAst ast, Pos pos) =>
	optOr!PositionKind(
		optIf(hasPos(ast.kind.as!(MatchAst*).keywordRange(ast), pos), () =>
			PositionKind(PositionKind.Expression(ctx.container, matchExpr))),
		() => positionInExpr(ctx, matched, pos));

Opt!PositionKind positionInType(in AllSymbols allSymbols, TypeContainer container, Type type, TypeAst ast, Pos pos) =>
	hasPos(ast.range(allSymbols), pos)
		? optOr!PositionKind(
			eachTypeComponent!PositionKind(type, ast, (in Type t, in TypeAst a) =>
				positionInType(allSymbols, container, t, a, pos)),
			() => some(PositionKind(TypeWithContainer(type, container))))
		: none!PositionKind;

bool hasPos(in AllSymbols allSymbols, in NameAndRange nr, Pos pos) =>
	hasPos(nr.range(allSymbols), pos);

bool optHasPos(in Opt!Range a, Pos p) =>
	has(a) && hasPos(force(a), p);
