module frontend.ide.getTarget;

@safe @nogc pure nothrow:

import frontend.ide.position : ExpressionPosition, ExpressionPositionKind, ExprKeyword, ExprRef, PositionKind;
import model.diag : TypeWithContainer;
import model.model :
	AutoFun,
	BuiltinFun,
	Called,
	CalledSpecSig,
	CallExpr,
	Destructure,
	EnumFunction,
	EnumOrFlagsMember,
	Expr,
	FlagsFunction,
	FunBody,
	FunDecl,
	FunInst,
	FunPointerExpr,
	Module,
	RecordField,
	StructBody,
	SpecDecl,
	StructAlias,
	StructDecl,
	StructInst,
	Test,
	TypeParamIndex,
	UnionMember,
	VarDecl;
import util.opt : none, Opt, some;
import util.union_ : Union;

immutable struct Target {
	immutable struct Loop {
		ExprRef loop;
	}

	mixin Union!(
		EnumOrFlagsMember*,
		FunDecl*,
		PositionKind.ImportedName,
		PositionKind.LocalPosition,
		Loop,
		Module*,
		RecordField*,
		SpecDecl*,
		PositionKind.SpecSig,
		StructAlias*,
		StructDecl*,
		PositionKind.TypeParamWithContainer,
		UnionMember*,
		VarDecl*,
	);
}

Opt!Target targetForPosition(PositionKind pos) =>
	pos.matchWithPointers!(Opt!Target)(
		(EnumOrFlagsMember* x) =>
			some(Target(x)),
		(ExpressionPosition x) =>
			exprTarget(x),
		(FunDecl* x) =>
			some(Target(x)),
		(PositionKind.ImportedModule x) =>
			some(Target(x.modulePtr)),
		(PositionKind.ImportedName x) =>
			some(Target(x)),
		(PositionKind.Keyword _) =>
			none!Target,
		(PositionKind.LocalPosition x) =>
			some(Target(x)),
		(PositionKind.MatchEnumCase x) =>
			some(Target(x.member)),
		(PositionKind.MatchIntegralCase x) =>
			none!Target,
		(PositionKind.MatchStringLikeCase x) =>
			none!Target,
		(PositionKind.MatchUnionCase x) =>
			some(Target(x.member)),
		(PositionKind.Modifier) =>
			none!Target,
		(PositionKind.ModifierExtern) =>
			none!Target,
		(RecordField* x) =>
			some(Target(x)),
		(PositionKind.RecordFieldMutability) =>
			none!Target,
		(SpecDecl* x) =>
			some(Target(x)),
		(PositionKind.SpecSig x) =>
			some(Target(x)),
		(PositionKind.SpecUse x) =>
			some(Target(x.spec.decl)),
		(StructAlias* x) =>
			some(Target(x)),
		(StructDecl* x) =>
			some(Target(x)),
		(Test*) =>
			none!Target,
		(TypeWithContainer x) =>
			x.type.matchWithPointers!(Opt!Target)(
				(Bogus) =>
					none!Target,
				(TypeParamIndex p) =>
					some(Target(PositionKind.TypeParamWithContainer(p, x.container))),
				(StructInst* x) =>
					some(Target(x.decl))),
		(PositionKind.TypeParamWithContainer x) =>
			some(Target(x)),
		(UnionMember* x) =>
			some(Target(x)),
		(VarDecl* x) =>
			some(Target(x)),
		(PositionKind.VisibilityMark) =>
			none!Target);

private:

Opt!Target exprTarget(ExpressionPosition a) =>
	a.kind.match!(Opt!Target)(
		(CallExpr x) =>
			calledTarget(x.called),
		(ExprKeyword x) =>
			none!Target,
		(FunPointerExpr x) =>
			some(Target(x.funInst.decl)),
		(ExpressionPositionKind.Literal) =>
			none!Target,
		(ExpressionPositionKind.LocalRef x) =>
			some(Target(PositionKind.LocalPosition(a.container.toLocalContainer, x.local))),
		(ExpressionPositionKind.LoopKeyword x) =>
			some(Target(Target.Loop(x.loop))));

Opt!Target calledTarget(ref Called a) =>
	a.match!(Opt!Target)(
		(ref Called.Bogus) =>
			none!Target,
		(ref FunInst funInst) {
			FunDecl* decl = funInst.decl;
			return some(decl.body_.match!Target(
				(FunBody.Bogus) =>
					Target(decl),
				(AutoFun _) =>
					Target(decl),
				(BuiltinFun _) =>
					Target(decl),
				(FunBody.CreateEnumOrFlags x) =>
					// goto the enum member
					Target(x.member),
				(FunBody.CreateExtern) =>
					// goto the return type
					returnTypeTarget(decl),
				(FunBody.CreateRecord) =>
					returnTypeTarget(decl),
				(FunBody.CreateUnion) =>
					// TODO: goto the particular union member
					returnTypeTarget(decl),
				(EnumFunction x) =>
					// goto the type
					returnTypeTarget(decl),
				(Expr _) =>
					Target(decl),
				(FunBody.Extern) =>
					Target(decl),
				(FunBody.FileImport) =>
					// TODO: Target for a file showing all imports
					Target(decl),
				(FlagsFunction) =>
					returnTypeTarget(decl),
				(FunBody.RecordFieldCall x) =>
					recordFieldTarget(decl, x.fieldIndex),
				(FunBody.RecordFieldGet x) =>
					recordFieldTarget(decl, x.fieldIndex),
				(FunBody.RecordFieldPointer x) =>
					recordFieldTarget(decl, x.fieldIndex),
				(FunBody.RecordFieldSet x) =>
					recordFieldTarget(decl, x.fieldIndex),
				(FunBody.VarGet x) =>
					Target(x.var),
				(FunBody.VarSet x) =>
					Target(x.var)));
		},
		(CalledSpecSig x) =>
			some(Target(PositionKind.SpecSig(x.specInst.decl, x.nonInstantiatedSig))));

Target returnTypeTarget(FunDecl* fun) =>
	Target(fun.returnType.as!(StructInst*).decl);

Target recordFieldTarget(FunDecl* fun, size_t fieldIndex) {
	StructDecl* record = fun.params.as!(Destructure[])[0].type.as!(StructInst*).decl;
	return Target(&record.body_.as!(StructBody.Record).fields[fieldIndex]);
}
