module frontend.ide.getPosition;

@safe @nogc pure nothrow:

import frontend.ide.ideUtil :
	findInPackedTypeArgs, eachTypeComponent, findDirectChildExpr, funBodyExprRef, specsMatch, testBodyExprRef;
import frontend.ide.position :
	ExpressionPosition,
	ExpressionPositionKind,
	ExprContainer,
	ExprKeyword,
	ExprRef,
	LocalContainer,
	Position,
	PositionKind,
	VisibilityContainer;
import model.ast :
	AssertOrForbidAst,
	AssignmentAst,
	AssignmentCallAst,
	CallAst,
	CaseAst,
	CaseMemberAst,
	DestructureAst,
	IdentifierAst,
	EnumOrFlagsMemberAst,
	ExprAst,
	ForAst,
	FunDeclAst,
	ModifierAst,
	IfAst,
	IfOptionAst,
	ImportOrExportAst,
	keywordRange,
	LambdaAst,
	LetAst,
	LiteralIntegralAndRange,
	LoopAst,
	LoopBreakAst,
	LoopUntilAst,
	LoopWhileAst,
	MatchAst,
	ModifierKeyword,
	NameAndRange,
	paramsArray,
	ParamsAst,
	PtrAst,
	RecordOrUnionMemberAst,
	SpecSigAst,
	SpecUseAst,
	StructBodyAst,
	StructDeclAst,
	TernaryAst,
	TestAst,
	ThrowAst,
	TrustedAst,
	TypeAst,
	TypedAst,
	UnlessAst,
	VisibilityAndRange,
	WithAst;
import model.diag : TypeContainer, TypeWithContainer;
import model.model :
	AssertOrForbidExpr,
	BogusExpr,
	BuiltinType,
	CallExpr,
	ClosureGetExpr,
	ClosureSetExpr,
	CommonTypes,
	Destructure,
	EnumOrFlagsMember,
	Expr,
	FunBody,
	FunDecl,
	FunDeclSource,
	FunPointerExpr,
	IfExpr,
	IfOptionExpr,
	ImportOrExport,
	ImportOrExportKind,
	IntegralType,
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
	MatchIntegralExpr,
	MatchStringLikeExpr,
	MatchUnionExpr,
	Module,
	nameRange,
	NameReferents,
	Params,
	Program,
	PtrToFieldExpr,
	PtrToLocalExpr,
	RecordField,
	SeqExpr,
	SpecInst,
	Specs,
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
	findIndex,
	firstPointer,
	firstZip,
	firstZipIfSizeEq,
	firstZipPointerFirst,
	isEmpty,
	SmallArray;
import util.col.stackMap : StackMap, stackMapAdd, stackMapMustGet, withStackMap;
import util.conv : safeToUint;
import util.opt : force, has, none, Opt, optIf, optOr, optOr, optOrDefault, some;
import util.sourceRange : Pos, Range;
import util.union_ : Union;
import util.util : enumConvert;

Opt!Position getPosition(ref Program program, Module* module_, Pos pos) {
	Ctx ctx = Ctx(program.commonTypes);
	Opt!PositionKind kind = getPositionKind(ctx, *module_, pos);
	return optIf(has(kind), () => Position(module_, force(kind)));
}

private:

bool hasPos(Range range, Pos pos) =>
	range.start <= pos && pos <= range.end;

const struct Ctx {
	@safe @nogc pure nothrow:
	CommonTypes* commonTypesPtr;

	ref CommonTypes commonTypes() return scope =>
		*commonTypesPtr;
}

Opt!PositionKind getPositionKind(in Ctx ctx, ref Module module_, Pos pos) =>
	optOr!PositionKind(
		positionInImportsOrExports(module_.imports, pos),
		() => positionInImportsOrExports(module_.reExports, pos),
		() => firstPointer!(PositionKind, StructAlias)(module_.aliases, (StructAlias* x) =>
			hasPos(x.range.range, pos)
				? positionInAlias(x, pos)
				: none!PositionKind),
		() => firstPointer!(PositionKind, StructDecl)(module_.structs, (StructDecl* x) =>
			hasPos(x.range.range, pos)
				? positionInStruct(ctx, x, pos)
				: none!PositionKind),
		() => firstPointer!(PositionKind, VarDecl)(module_.vars, (VarDecl* x) =>
			hasPos(x.range.range, pos)
				? positionInVar(x, pos)
				: none!PositionKind),
		() => firstPointer!(PositionKind, SpecDecl)(module_.specs, (SpecDecl* x) =>
			hasPos(x.range.range, pos)
				? positionInSpec(x, pos)
				: none!PositionKind),
		() => firstPointer!(PositionKind, FunDecl)(module_.funs, (FunDecl* x) =>
			x.source.isA!(FunDeclSource.Ast)
				? positionInFun(ctx, x, x.source.as!(FunDeclSource.Ast).ast, pos)
				: none!PositionKind),
		() => firstPointer!(PositionKind, Test)(module_.tests, (Test* x) =>
			hasPos(x.ast.range, pos)
				? some(positionInTest(ctx, x, *x.ast, pos))
				: none!PositionKind));

Opt!PositionKind positionInFun(in Ctx ctx, FunDecl* a, in FunDeclAst* ast, Pos pos) =>
	optOr!PositionKind(
		positionInVisibility(VisibilityContainer(a), ast.visibility, pos),
		() => optIf(hasPos(ast.name.range, pos), () => PositionKind(a)),
		() => positionInTypeParams(TypeContainer(a), ast.typeParams, pos),
		() => positionInType(TypeContainer(a), a.returnType, ast.returnType, pos),
		() => positionInParams(LocalContainer(a), a.params, ast.params, pos),
		() => positionInModifiers(TypeContainer(a), some(a.specs), ast.modifiers, pos),
		() => a.body_.isA!Expr
			? positionInExpr(ctx, ExprContainer(a), funBodyExprRef(a), pos)
			: none!PositionKind);

PositionKind positionInTest(ref Ctx ctx, Test* a, in TestAst ast, Pos pos) =>
	optOrDefault!PositionKind(
		positionInExpr(ctx, ExprContainer(a), testBodyExprRef(ctx.commonTypes, a), pos),
		() => PositionKind(a));

Opt!PositionKind positionInParams(LocalContainer container, in Params params, in ParamsAst ast, Pos pos) =>
	firstZip!(PositionKind, Destructure, DestructureAst)(
		paramsArray(params), paramsArray(ast), (Destructure x, DestructureAst y) =>
			positionInDestructure(container, x, y, pos));

Opt!PositionKind positionInModifiers(TypeContainer container, in Opt!Specs specs, in ModifierAst[] modifiers, Pos pos) {
	Opt!size_t index = findIndex!ModifierAst(modifiers, (in ModifierAst modifier) =>
		hasPos(modifier.range, pos));
	return has(index)
		? positionInModifier(container, specs, modifiers, force(index), pos)
		: none!PositionKind;
}

Opt!PositionKind positionInModifier(
	TypeContainer container,
	in Opt!Specs specs,
	in ModifierAst[] modifiers,
	size_t index,
	Pos pos,
) =>
	modifiers[index].matchIn!(Opt!PositionKind)(
		(in ModifierAst.Keyword x) {
			switch (x.keyword) {
				case ModifierKeyword.extern_:
					return some(container.isA!(FunDecl*) && container.as!(FunDecl*).body_.isA!(FunBody.Extern)
						? PositionKind(PositionKind.ModifierExtern(
							container.as!(FunDecl*).body_.as!(FunBody.Extern).libraryName))
						: PositionKind(PositionKind.Modifier(container, x.keyword)));
				default:
					return some(PositionKind(PositionKind.Modifier(container, x.keyword)));
			}
		},
		(in SpecUseAst ast) {
			if (has(specs) && specsMatch(force(specs), modifiers)) {
				// Find the corresponding spec
				size_t specIndex = 0;
				foreach (ref ModifierAst prevModifier; modifiers[0 .. index])
					if (prevModifier.isA!SpecUseAst)
						specIndex++;

				SpecInst* spec = force(specs)[specIndex];
				return optOr!PositionKind(
					findInPackedTypeArgs!PositionKind(spec.typeArgs, ast.typeArg, (in Type t, in TypeAst a) =>
						positionInType(container, t, a, pos)),
					() => optIf(hasPos(ast.nameRange, pos), () =>
						PositionKind(PositionKind.SpecUse(container, force(specs)[specIndex]))));
			} else
				return none!PositionKind;
		});

Opt!PositionKind positionInDestructure(ref ExprCtx ctx, in Destructure a, in DestructureAst ast, Pos pos) =>
	positionInDestructure(ctx.container.toLocalContainer, a, ast, pos);

Opt!PositionKind positionInDestructure(
	LocalContainer container,
	in Destructure a,
	in DestructureAst destructureAst,
	Pos pos,
) {
	Opt!PositionKind handleSingle(Type type, in PositionKind delegate() @safe @nogc pure nothrow cbName) {
		DestructureAst.Single ast = destructureAst.as!(DestructureAst.Single);
		return hasPos(ast.range, pos)
			? optOr!PositionKind(
				optIf(hasPos(ast.nameRange, pos), cbName),
				() => optIf(optHasPos(ast.mutRange, pos), () =>
					PositionKind(PositionKind.Keyword(PositionKind.Keyword.Kind.localMut))),
				() => has(ast.type)
					? positionInType( container.toTypeContainer(), type, *force(ast.type), pos)
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
						positionInDestructure( container, part, partAst, pos)));
}

Opt!PositionKind positionInImportsOrExports(ImportOrExport[] importsOrExports, Pos pos) {
	foreach (ref ImportOrExport im; importsOrExports)
		if (has(im.source) && hasPos(force(im.source).range, pos)) {
			ImportOrExportAst* source = force(im.source);
			return im.kind.matchIn!(Opt!PositionKind)(
				(in ImportOrExportKind.ModuleWhole) =>
					some(PositionKind(PositionKind.ImportedModule(&im))),
				(in Opt!(NameReferents*)[] referents) =>
					hasPos(force(im.source).pathRange, pos)
						? some(PositionKind(PositionKind.ImportedModule(&im)))
						: positionInImportedNames(im.modulePtr, source.kind.as!(NameAndRange[]), referents, pos));
		}
	return none!PositionKind;
}

Opt!PositionKind positionInImportedNames(
	Module* module_,
	in NameAndRange[] names,
	in Opt!(NameReferents*)[] referents,
	Pos pos,
) {
	foreach (size_t index, NameAndRange x; names)
		if (hasPos(x.range, pos))
			return some(PositionKind(PositionKind.ImportedName(module_, x.name, referents[index])));
	return none!PositionKind;
}

Opt!PositionKind positionInVar(VarDecl* a, Pos pos) =>
	optOr!PositionKind(
		positionInVisibility(VisibilityContainer(a), a.ast.visibility, pos),
		() => optIf(hasPos(a.nameRange.range, pos), () => PositionKind(a)),
		() => optIf(hasPos(a.ast.keywordRange, pos), () =>
			PositionKind(PositionKind.Keyword(enumConvert!(PositionKind.Keyword.Kind)(a.kind)))),
		() => positionInType(TypeContainer(a), a.type, a.ast.type, pos));

Opt!PositionKind positionInAlias(StructAlias* a, Pos pos) =>
	optOr!PositionKind(
		positionInVisibility(VisibilityContainer(a), a.ast.visibility, pos),
		() => optIf(hasPos(a.nameRange.range, pos), () => PositionKind(a)),
		() => optIf(hasPos(a.ast.keywordRange, pos), () =>
			PositionKind(PositionKind.Keyword(PositionKind.Keyword.Kind.alias_))),
		() => positionInType(TypeContainer(a), Type(a.target), a.ast.target, pos));

Opt!PositionKind positionInStruct(in Ctx ctx, StructDecl* a, Pos pos) =>
	a.source.matchIn!(Opt!PositionKind)(
		(in StructDeclAst x) =>
			positionInStruct(ctx, a, x, pos),
		(in StructDeclSource.Bogus) =>
			none!PositionKind);

Opt!PositionKind positionInStruct(in Ctx ctx, StructDecl* a, in StructDeclAst ast, Pos pos) =>
	optOr!PositionKind(
		positionInVisibility(VisibilityContainer(a), ast.visibility, pos),
		() => optIf(hasPos(a.nameRange.range, pos), () => PositionKind(a)),
		() => optIf(hasPos(ast.keywordRange, pos), () =>
			PositionKind(PositionKind.Keyword(keywordKindForStructBody(ast.body_)))),
		() => positionInTypeParams(TypeContainer(a), ast.typeParams, pos),
		() => positionInModifiers(TypeContainer(a), none!Specs, ast.modifiers, pos),
		() => positionInStructBody(ctx, a, a.body_, ast.body_, pos));

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

Opt!PositionKind positionInTypeParams(TypeContainer container, in NameAndRange[] asts, Pos pos) {
	Opt!size_t index = findIndex!NameAndRange(asts, (in NameAndRange x) => hasPos(x.range, pos));
	return optIf(has(index), () =>
		PositionKind(PositionKind.TypeParamWithContainer(TypeParamIndex(safeToUint(force(index))), container)));
}

Opt!PositionKind positionInSpec(SpecDecl* a, Pos pos) =>
	optOr!PositionKind(
		positionInVisibility(VisibilityContainer(a), a.ast.visibility, pos),
		() => optIf(hasPos(a.ast.name.range, pos), () => PositionKind(a)),
		() => positionInTypeParams(TypeContainer(a), a.ast.typeParams, pos),
		() => optIf(hasPos(a.ast.keywordRange, pos), () =>
			PositionKind(PositionKind.Keyword(PositionKind.Keyword.Kind.spec))),
		() => positionInModifiers(TypeContainer(a), some(a.parents), a.ast.modifiers, pos),
		() => positionInSpecSigs(a, pos));

Opt!PositionKind positionInSpecSigs(SpecDecl* a, Pos pos) =>
	firstZipPointerFirst!(PositionKind, SpecDeclSig, SpecSigAst)(
		a.sigs, a.ast.sigs, (SpecDeclSig* sig, SpecSigAst sigAst) =>
			positionInSpecSig(a, sig, sigAst, pos));

Opt!PositionKind positionInSpecSig(SpecDecl* spec, SpecDeclSig* sig, in SpecSigAst ast, Pos pos) =>
	hasPos(ast.range, pos)
		? optOr!PositionKind(
			optIf(hasPos(ast.nameAndRange.range, pos), () =>
				PositionKind(PositionKind.SpecSig(spec, sig))),
			() => positionInType(TypeContainer(spec), sig.returnType, ast.returnType, pos),
			() => positionInParams(LocalContainer(spec), Params(sig.params), ast.params, pos))
		: none!PositionKind;

Opt!PositionKind positionInStructBody(
	in Ctx ctx,
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
		(ref StructBody.Enum x) =>
			positionInEnumOrFlagsBody(
				ctx, decl, x.storage, x.members,
				ast.as!(StructBodyAst.Enum).params, ast.as!(StructBodyAst.Enum).members,
				pos),
		(StructBody.Extern) =>
			none!PositionKind,
		(StructBody.Flags x) =>
			positionInEnumOrFlagsBody(
				ctx, decl, x.storage, x.members,
				ast.as!(StructBodyAst.Flags).params, ast.as!(StructBodyAst.Flags).members,
				pos),
		(StructBody.Record x) =>
			positionInRecordOrUnionBody!RecordField(
				ctx, decl, x.fields,
				ast.as!(StructBodyAst.Record).params,
				ast.as!(StructBodyAst.Record).fields,
				pos,
				cbMemberPosition: (RecordField* field) =>
					PositionKind(field),
				cbVisibilityContainer: (RecordField* field) =>
					some(VisibilityContainer(field)),
				cbMutabilityPosition: (RecordField* field) =>
					some(PositionKind(PositionKind.RecordFieldMutability(field.mutability)))),
		(ref StructBody.Union x) =>
			positionInRecordOrUnionBody!UnionMember(
				ctx, decl, x.members,
				ast.as!(StructBodyAst.Union).params,
				ast.as!(StructBodyAst.Union).members,
				pos,
				cbMemberPosition: (UnionMember* member) =>
					PositionKind(member),
				cbVisibilityContainer: (UnionMember*) =>
					none!VisibilityContainer,
				cbMutabilityPosition: (UnionMember*) =>
					none!PositionKind));

Opt!PositionKind positionInRecordOrUnionBody(Member)(
	in Ctx ctx,
	StructDecl* decl,
	in Member[] members,
	Opt!ParamsAst paramsAst,
	SmallArray!RecordOrUnionMemberAst memberAsts,
	Pos pos,
	in PositionKind delegate(Member*) @safe @nogc pure nothrow cbMemberPosition,
	in Opt!VisibilityContainer delegate(Member*) @safe @nogc pure nothrow cbVisibilityContainer,
	in Opt!PositionKind delegate(Member*) @safe @nogc pure nothrow cbMutabilityPosition,
) =>
	isEmpty(members)
		? none!PositionKind
		: has(paramsAst)
		? firstZipPointerFirst!(PositionKind, Member, DestructureAst)(
			members, force(paramsAst).as!(DestructureAst[]), (Member* member, DestructureAst param) =>
				positionInRecordOrUnionMemberParameter!Member(
					decl, member, param.as!(DestructureAst.Single), pos, cbMemberPosition, cbMutabilityPosition))
		: firstZipPointerFirst!(PositionKind, Member, RecordOrUnionMemberAst)(
			members, memberAsts, (Member* member, RecordOrUnionMemberAst memberAst) =>
				positionInRecordOrUnionMember!Member(
					decl, member, memberAst, pos, cbMemberPosition, cbVisibilityContainer, cbMutabilityPosition));

Opt!PositionKind positionInRecordOrUnionMemberParameter(Member)(
	StructDecl* decl,
	Member* member,
	in DestructureAst.Single param,
	Pos pos,
	in PositionKind delegate(Member*) @safe @nogc pure nothrow cbMemberPosition,
	in Opt!PositionKind delegate(Member*) @safe @nogc pure nothrow cbMutabilityPosition,
) =>
	optOr!PositionKind(
		optIf(hasPos(param.name.range, pos), () => cbMemberPosition(member)),
		() {
			Opt!Range mutRange = param.mutRange;
			return has(mutRange) && hasPos(force(mutRange), pos) ? cbMutabilityPosition(member) : none!PositionKind;
		},
		() => positionInType(TypeContainer(decl), member.type, *force(param.type), pos));

Opt!PositionKind positionInRecordOrUnionMember(Member)(
	StructDecl* decl,
	Member* member,
	in RecordOrUnionMemberAst memberAst,
	Pos pos,
	in PositionKind delegate(Member*) @safe @nogc pure nothrow cbMemberPosition,
	in Opt!VisibilityContainer delegate(Member*) @safe @nogc pure nothrow cbVisibilityContainer,
	in Opt!PositionKind delegate(Member*) @safe @nogc pure nothrow cbMutabilityPosition,
) =>
	optOr!PositionKind(
		() {
			Opt!VisibilityContainer container = cbVisibilityContainer(member);
			return has(container)
				? positionInVisibility(force(container), memberAst.visibility, pos)
				: none!PositionKind;
		}(),
		() => optIf(hasPos(memberAst.name.range, pos), () => cbMemberPosition(member)),
		() => has(memberAst.mutability) && hasPos(force(memberAst.mutability).range, pos)
			? cbMutabilityPosition(member)
			: none!PositionKind,
		() => has(memberAst.type)
			? positionInType(TypeContainer(decl), member.type, force(memberAst.type), pos)
			: none!PositionKind);

Opt!PositionKind positionInEnumOrFlagsBody(
	in Ctx ctx,
	StructDecl* decl,
	IntegralType storage,
	in EnumOrFlagsMember[] members,
	in Opt!ParamsAst paramsAst,
	in EnumOrFlagsMemberAst[] memberAsts,
	Pos pos
) =>
	isEmpty(members)
		? none!PositionKind
		: has(paramsAst)
		? firstZipPointerFirst!(PositionKind, EnumOrFlagsMember, DestructureAst)(
			members, force(paramsAst).as!(DestructureAst[]), (EnumOrFlagsMember* member, DestructureAst param) =>
				optIf(hasPos(param.range, pos), () => PositionKind(member)))
		: firstZipPointerFirst!(PositionKind, EnumOrFlagsMember, EnumOrFlagsMemberAst)(
			members, memberAsts, (EnumOrFlagsMember* member, EnumOrFlagsMemberAst memberAst) =>
				optIf(hasPos(memberAst.nameRange, pos), () => PositionKind(member)));

Opt!PositionKind positionInExpr(ref Ctx ctx, ExprContainer container, ExprRef a, Pos pos) {
	ExprCtx exprCtx = ExprCtx(ctx.commonTypesPtr, container);
	return withStackMap!(Opt!PositionKind, LoopExpr*, ExprRef)((ref Loops loops) =>
		positionInExprRecur(exprCtx, loops, a, pos));
}

const struct ExprCtx {
	@safe @nogc pure nothrow:

	CommonTypes* commonTypesPtr;
	ExprContainer container;

	ref CommonTypes commonTypes() return scope =>
		*commonTypesPtr;
}

alias Loops = const StackMap!(LoopExpr*, ExprRef);

Opt!PositionKind positionInExprRecur(ref ExprCtx ctx, in Loops loops, ExprRef a, Pos pos) =>
	hasPos(a.expr.range, pos)
		? optOr!PositionKind(positionAtExpr(ctx, loops, a, pos), () =>
			a.expr.kind.isA!(LoopExpr*)
				? positionInExprChild(ctx, stackMapAdd(loops, a.expr.kind.as!(LoopExpr*), a), a, pos)
				: positionInExprChild(ctx, loops, a, pos))
		: none!PositionKind;

Opt!PositionKind positionInExprChild(ref ExprCtx ctx, in Loops loops, ExprRef a, Pos pos) =>
	findDirectChildExpr!PositionKind(ctx.commonTypes, a, (ExprRef child) =>
		positionInExprRecur(ctx, loops, child, pos));

Opt!PositionKind positionAtExpr(ref ExprCtx ctx, in Loops loops, ExprRef a, Pos pos) {
	ExprAst* ast = a.expr.ast;
	PositionKind expressionPosition(ExpressionPositionKind x) =>
		PositionKind(ExpressionPosition(ctx.container, a, x));
	Opt!PositionKind inDestructure(in Destructure x, in DestructureAst y) =>
		positionInDestructure(ctx, x, y, pos);
	PositionKind keyword(ExprKeyword k) =>
		expressionPosition(ExpressionPositionKind(k));
	Opt!PositionKind keywordAt(Range range, ExprKeyword k, ) =>
		optIf(hasPos(range, pos), () => keyword(k));
	PositionKind local(ExpressionPositionKind.LocalRef.Kind kind, Local* local) =>
		expressionPosition(ExpressionPositionKind(ExpressionPositionKind.LocalRef(kind, local)));
	PositionKind loopKeyword(ExpressionPositionKind.LoopKeyword.Kind kind, LoopExpr* loop) =>
		expressionPosition(ExpressionPositionKind(
			ExpressionPositionKind.LoopKeyword(kind, stackMapMustGet(loops, loop))));
	return a.expr.kind.match!(Opt!PositionKind)(
		(ref AssertOrForbidExpr x) =>
			keywordAt(ast.kind.as!(AssertOrForbidAst*).keywordRange(ast), enumConvert!ExprKeyword(x.kind)),
		(BogusExpr _) =>
			none!PositionKind,
		(CallExpr x) =>
			optIf(posIsAtCall(*ast, pos), () =>
				expressionPosition(ExpressionPositionKind(x))),
		(ClosureGetExpr x) =>
			some(local(ExpressionPositionKind.LocalRef.Kind.closureGet, x.local)),
		(ClosureSetExpr x) {
			return optIf(isAtAssignment(ast, pos), () =>
				local(ExpressionPositionKind.LocalRef.Kind.closureSet, x.local));
		},
		(FunPointerExpr x) =>
			some(expressionPosition(ExpressionPositionKind(x))),
		(ref IfExpr x) {
			Opt!ExprKeyword k = keywordAtIf(ast, pos);
			return optIf(has(k), () => keyword(force(k)));
		},
		(ref IfOptionExpr x) {
			IfOptionAst* if_ = ast.kind.as!(IfOptionAst*);
			return optOr!PositionKind(
				keywordAt(if_.ifKeywordRange(ast), ExprKeyword.if_),
				() => inDestructure(x.destructure, if_.destructure),
				() => keywordAt(if_.questionEqualsRange, ExprKeyword.if_));
		},
		(ref LambdaExpr x) {
			Opt!Range arrowRange = ast.kind.as!(LambdaAst*).arrowRange;
			return optOr!PositionKind(
				has(arrowRange) ? keywordAt(force(arrowRange), ExprKeyword.lambdaArrow) : none!PositionKind,
				() => inDestructure(x.param, ast.kind.as!(LambdaAst*).param));
		},
		(ref LetExpr x) =>
			inDestructure(x.destructure, ast.kind.as!(LetAst*).destructure),
		(LiteralExpr _) =>
			some(expressionPosition(ExpressionPositionKind(ExpressionPositionKind.Literal()))),
		(LiteralStringLikeExpr _) =>
			some(expressionPosition(ExpressionPositionKind(ExpressionPositionKind.Literal()))),
		(LocalGetExpr x) =>
			some(local(ExpressionPositionKind.LocalRef.Kind.get, x.local)),
		(LocalSetExpr x) =>
			optIf(isAtAssignment(ast, pos), () =>
				local(ExpressionPositionKind.LocalRef.Kind.set, x.local)),
		(ref LoopExpr x) =>
			hasPos(ast.kind.as!(LoopAst*).keywordRange(ast), pos)
				? some(expressionPosition(ExpressionPositionKind(
					ExpressionPositionKind.LoopKeyword(ExpressionPositionKind.LoopKeyword.Kind.loop, a))))
				: none!PositionKind,
		(ref LoopBreakExpr x) =>
			optIf(hasPos(ast.kind.as!(LoopBreakAst*).keywordRange(ast), pos), () =>
				loopKeyword(ExpressionPositionKind.LoopKeyword.Kind.break_, x.loop)),
		(LoopContinueExpr x) =>
			some(loopKeyword(ExpressionPositionKind.LoopKeyword.Kind.continue_, x.loop)),
		(ref LoopUntilExpr x) =>
			keywordAt(ast.kind.as!(LoopUntilAst*).keywordRange(ast), ExprKeyword.until),
		(ref LoopWhileExpr x) =>
			keywordAt(ast.kind.as!(LoopWhileAst*).keywordRange(ast), ExprKeyword.while_),
		(ref MatchEnumExpr x) =>
			positionAtMatchEnum(ctx, a, x, *ast, pos),
		(ref MatchIntegralExpr x) =>
			positionAtMatchIntegral(ctx, a, x, *ast, pos),
		(ref MatchStringLikeExpr x) =>
			positionAtMatchStringLike(ctx, a, x, *ast, pos),
		(ref MatchUnionExpr x) =>
			positionAtMatchUnion(ctx, a, x, *ast, pos),
		(ref PtrToFieldExpr x) =>
			keywordAt(ast.kind.as!(PtrAst*).keywordRange(ast), ExprKeyword.ampersand),
		(PtrToLocalExpr x) =>
			some(optOrDefault!PositionKind(
				keywordAt(ast.kind.as!(PtrAst*).keywordRange(ast), ExprKeyword.ampersand),
				() => local(ExpressionPositionKind.LocalRef.Kind.pointer, x.local))),
		(ref SeqExpr x) =>
			none!PositionKind,
		(ref ThrowExpr x) =>
			keywordAt(ast.kind.as!(ThrowAst*).keywordRange(ast), ExprKeyword.throw_),
		(ref TrustedExpr x) =>
			keywordAt(ast.kind.as!(TrustedAst*).keywordRange(ast), ExprKeyword.trusted),
		(ref TypedExpr x) {
			TypedAst* tAst = ast.kind.as!(TypedAst*);
			return optOr!PositionKind(
				keywordAt(tAst.keywordRange, ExprKeyword.colonColon),
				() => positionInType(ctx.container.toTypeContainer, a.type, tAst.type, pos));
		});
}

bool isAtAssignment(in ExprAst* ast, Pos pos) {
	if (ast.kind.isA!(AssignmentAst*)) {
		AssignmentAst* assign = ast.kind.as!(AssignmentAst*);
		return hasPos(assign.left.range, pos) || hasPos(assign.keywordRange, pos);
	} else if (ast.kind.isA!AssignmentCallAst) {
		AssignmentCallAst call = ast.kind.as!AssignmentCallAst;
		return hasPos(call.left.range, pos) || hasPos(call.keywordRange, pos);
	} else
		assert(false);
}

Opt!ExprKeyword keywordAtIf(in ExprAst* ast, Pos pos) {
	if (ast.kind.isA!(IfAst*)) {
		IfAst* if_ = ast.kind.as!(IfAst*);
		return hasPos(if_.ifKeywordRange(ast), pos)
			? some(ExprKeyword.if_)
			: has(if_.elifOrElseKeyword) && hasPos(force(if_.elifOrElseKeyword).range, pos)
			? some(enumConvert!ExprKeyword(force(if_.elifOrElseKeyword).kind))
			: none!ExprKeyword;
	} else if (ast.kind.isA!(TernaryAst*)) {
		TernaryAst* ternary = ast.kind.as!(TernaryAst*);
		Opt!Range colonRange = ternary.colonRange;
		return hasPos(ternary.questionRange, pos)
			? some(ExprKeyword.if_)
			: has(colonRange) && hasPos(force(colonRange), pos)
			? some(ExprKeyword.else_)
			: none!ExprKeyword;
	} else if (ast.kind.isA!(UnlessAst*)) {
		UnlessAst* unless = ast.kind.as!(UnlessAst*);
		return optIf(hasPos(unless.keywordRange(ast), pos), () => ExprKeyword.unless);
	} else
		assert(false);
}

bool posIsAtCall(in ExprAst a, Pos pos) {
	if (a.kind.isA!CallAst) {
		CallAst call = a.kind.as!CallAst;
		final switch (call.style) {
			case CallAst.Style.comma:
			case CallAst.Style.emptyParens:
			case CallAst.Style.implicit:
			case CallAst.Style.subscript:
				return false;
			case CallAst.Style.dot:
			case CallAst.Style.infix:
			case CallAst.Style.prefixBang:
			case CallAst.Style.prefixOperator:
			case CallAst.Style.single:
			case CallAst.Style.suffixBang:
				return hasPos(call.funName.range, pos);
		}
	} else if (a.kind.isA!(ForAst*)) {
		ForAst* for_ = a.kind.as!(ForAst*);
		return hasPos(for_.forKeywordRange(a), pos) || hasPos(for_.colonRange, pos);
	} else if (a.kind.isA!(WithAst*)) {
		WithAst* with_ = a.kind.as!(WithAst*);
		return hasPos(with_.withKeywordRange(a), pos) || hasPos(with_.colonRange, pos);
	} else if (a.kind.isA!IdentifierAst)
		return hasPos(a.range, pos);
	else
		return false;
}

Opt!PositionKind positionAtMatchEnum(in ExprCtx ctx, ExprRef expr, ref MatchEnumExpr a, ref ExprAst ast, Pos pos) =>
	optOr!PositionKind(
		positionAtMatchKeyword(ctx, expr, ast, pos),
		() => firstZipIfSizeEq!(PositionKind, MatchEnumExpr.Case, CaseAst)(
			a.cases, ast.kind.as!MatchAst.cases,
			(MatchEnumExpr.Case case_, CaseAst caseAst) =>
				optIf(hasPos(caseAst.keywordAndMemberNameRange, pos), () =>
					PositionKind(PositionKind.MatchEnumCase(case_.member)))));

Opt!PositionKind positionAtMatchIntegral(
	in ExprCtx ctx,
	ExprRef expr,
	ref MatchIntegralExpr a,
	ref ExprAst ast,
	Pos pos,
) =>
	optOr!PositionKind(
		positionAtMatchKeyword(ctx, expr, ast, pos),
		() => firstZipIfSizeEq!(PositionKind, MatchIntegralExpr.Case, CaseAst)(
			a.cases, ast.kind.as!MatchAst.cases,
			(MatchIntegralExpr.Case case_, CaseAst caseAst) =>
				optIf(hasPos(caseAst.keywordAndMemberNameRange, pos), () =>
					PositionKind(PositionKind.MatchIntegralCase(a.kind, case_.value)))));

Opt!PositionKind positionAtMatchStringLike(
	in ExprCtx ctx,
	ExprRef expr,
	ref MatchStringLikeExpr a,
	ref ExprAst ast,
	Pos pos,
) =>
	optOr!PositionKind(
		positionAtMatchKeyword(ctx, expr, ast, pos),
		() => firstZipIfSizeEq!(PositionKind, MatchStringLikeExpr.Case, CaseAst)(
			a.cases, ast.kind.as!MatchAst.cases,
			(MatchStringLikeExpr.Case case_, CaseAst caseAst) =>
				optIf(hasPos(caseAst.keywordAndMemberNameRange, pos), () =>
					PositionKind(PositionKind.MatchStringLikeCase(
						TypeWithContainer(a.matched.type, ctx.container.toTypeContainer),
						case_.value)))));

Opt!PositionKind positionAtMatchUnion(in ExprCtx ctx, ExprRef expr, ref MatchUnionExpr a, ref ExprAst ast, Pos pos) =>
	optOr!PositionKind(
		positionAtMatchKeyword(ctx, expr, ast, pos),
		() => firstZipIfSizeEq!(PositionKind, MatchUnionExpr.Case, CaseAst)(
			a.cases, ast.kind.as!MatchAst.cases,
			(MatchUnionExpr.Case case_, CaseAst caseAst) =>
				positionAtMatchUnionCase(ctx, case_, caseAst, pos)));

Opt!PositionKind positionAtMatchUnionCase(in ExprCtx ctx, MatchUnionExpr.Case case_, CaseAst ast, Pos pos) =>
	optOr!PositionKind(
		optIf(hasPos(ast.keywordAndMemberNameRange, pos), () =>
			PositionKind(PositionKind.MatchUnionCase(case_.member))),
		() => ast.member.matchIn!(Opt!PositionKind)(
			(in CaseMemberAst.Name x) =>
				has(x.destructure)
					? positionInDestructure(ctx, case_.destructure, force(x.destructure), pos)
					: none!PositionKind,
			(in LiteralIntegralAndRange _) => none!PositionKind,
			(in CaseMemberAst.String) => none!PositionKind,
			(in CaseMemberAst.Bogus) => none!PositionKind));

Opt!PositionKind positionAtMatchKeyword(
	in ExprCtx ctx,
	ExprRef matchExpr,
	ref ExprAst ast,
	Pos pos,
) {
	MatchAst matchAst = ast.kind.as!MatchAst;
	return optOr!PositionKind(
		optIf(hasPos(matchAst.keywordRange(ast), pos), () =>
			PositionKind(ExpressionPosition(ctx.container, matchExpr, ExpressionPositionKind(ExprKeyword.match)))),
		() => optIf(has(matchAst.else_) && hasPos(force(matchAst.else_).keywordRange, pos), () =>
			PositionKind(ExpressionPosition(ctx.container, matchExpr, ExpressionPositionKind(ExprKeyword.else_)))));
}

Opt!PositionKind positionInType(TypeContainer container, Type type, in TypeAst ast, Pos pos) =>
	hasPos(ast.range, pos)
		? optOr!PositionKind(
			eachTypeComponent!PositionKind(type, ast, (in Type t, in TypeAst a) =>
				positionInType(container, t, a, pos)),
			() => positionInTypeNotArgs(container, type, ast, pos))
		: none!PositionKind;

Opt!PositionKind positionInTypeNotArgs(TypeContainer container, Type type, in TypeAst ast, Pos pos) {
	PositionKind here = PositionKind(TypeWithContainer(type, container));
	return ast.matchIn!(Opt!PositionKind)(
		(in TypeAst.Bogus) =>
			none!PositionKind,
		(in TypeAst.Fun x) =>
			optIf(hasPos(x.kindRange, pos), () => here),
		(in TypeAst.Map x) =>
			none!PositionKind,
		(in NameAndRange x) =>
			some(here),
		(in TypeAst.SuffixName x) =>
			optIf(hasPos(x.name.range, pos), () => here),
		(in TypeAst.SuffixSpecial x) =>
			optIf(hasPos(x.suffixRange, pos), () => here),
		(in TypeAst.Tuple) =>
			none!PositionKind);
}

bool optHasPos(in Opt!Range a, Pos p) =>
	has(a) && hasPos(force(a), p);
