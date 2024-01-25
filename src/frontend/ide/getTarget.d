module frontend.ide.getTarget;

@safe @nogc pure nothrow:

import frontend.ide.position : PositionKind;
import model.diag : TypeWithContainer;
import model.model :
	AssertOrForbidExpr,
	BogusExpr,
	BuiltinFun,
	Called,
	CalledSpecSig,
	CallExpr,
	ClosureGetExpr,
	ClosureSetExpr,
	Destructure,
	EnumFunction,
	EnumMember,
	FlagsFunction,
	FunBody,
	FunDecl,
	FunInst,
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
	Module,
	PtrToFieldExpr,
	PtrToLocalExpr,
	RecordField,
	SeqExpr,
	StructBody,
	SpecDecl,
	StructAlias,
	StructDecl,
	StructInst,
	Test,
	ThrowExpr,
	toLocal,
	TrustedExpr,
	TypedExpr,
	TypeParamIndex,
	UnionMember,
	VarDecl;
import util.opt : none, Opt, some;
import util.json : field;
import util.union_ : Union;

immutable struct Target {
	mixin Union!(
		EnumMember*,
		FunDecl*,
		PositionKind.ImportedName,
		PositionKind.LocalPosition,
		LoopExpr*,
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
		(PositionKind.None) =>
			none!Target,
		(PositionKind.Expression x) =>
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
		(PositionKind.MatchUnionCase x) =>
			some(Target(x.member)),
		(PositionKind.Modifier) =>
			none!Target,
		(PositionKind.ModifierExtern) =>
			none!Target,
		(PositionKind.RecordFieldMutability) =>
			none!Target,
		(PositionKind.RecordFieldPosition x) =>
			some(Target(x.field)),
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
		(VarDecl* x) =>
			some(Target(x)),
		(PositionKind.VisibilityMark) =>
			none!Target);

Opt!Target exprTarget(PositionKind.Expression a) {
	Opt!Target local(Local* x) =>
		some(Target(PositionKind.LocalPosition(a.container.toLocalContainer, x)));
	return a.expr.kind.match!(Opt!Target)(
		(AssertOrForbidExpr _) =>
			none!Target,
		(BogusExpr _) =>
			none!Target,
		(CallExpr x) =>
			calledTarget(x.called),
		(ClosureGetExpr x) =>
			local(toLocal(x.closureRef)),
		(ClosureSetExpr x) =>
			local(toLocal(x.closureRef)),
		(FunPointerExpr x) =>
			some(Target(x.funInst.decl)),
		(ref IfExpr _) =>
			none!Target,
		(ref IfOptionExpr _) =>
			none!Target,
		(ref LambdaExpr _) =>
			none!Target,
		(ref LetExpr _) =>
			none!Target,
		(ref LiteralExpr _) =>
			none!Target,
		(LiteralStringLikeExpr _) =>
			none!Target,
		(LocalGetExpr x) =>
			local(x.local),
		(ref LocalSetExpr x) =>
			local(x.local),
		(ref LoopExpr x) =>
			some(Target(&x)),
		(ref LoopBreakExpr x) =>
			some(Target(x.loop)),
		(LoopContinueExpr x) =>
			some(Target(x.loop)),
		(ref LoopUntilExpr _) =>
			none!Target,
		(ref LoopWhileExpr _) =>
			none!Target,
		(ref MatchEnumExpr _) =>
			none!Target,
		(ref MatchUnionExpr _) =>
			none!Target,
		(ref PtrToFieldExpr x) =>
			// TODO: target the field
			none!Target,
		(PtrToLocalExpr x) =>
			local(x.local),
		(ref SeqExpr _) =>
			none!Target,
		(ref ThrowExpr _) =>
			none!Target,
		(ref TrustedExpr _) =>
			none!Target,
		(ref TypedExpr _) =>
			none!Target);
}

private:

Opt!Target calledTarget(ref Called a) =>
	a.match!(Opt!Target)(
		(ref FunInst funInst) {
			FunDecl* decl = funInst.decl;
			return some(decl.body_.match!(Target)(
				(FunBody.Bogus) =>
					Target(decl),
				(BuiltinFun _) =>
					Target(decl),
				(FunBody.CreateEnum x) =>
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
				(FunBody.Extern) =>
					Target(decl),
				(FunBody.ExpressionBody) =>
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
