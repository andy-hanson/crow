module frontend.ide.getTarget;

@safe @nogc pure nothrow:

import frontend.ide.position : LocalContainer, PositionKind;
import model.diag : TypeWithContainer;
import model.model :
	AssertOrForbidExpr,
	BogusExpr,
	Called,
	CalledSpecSig,
	CallExpr,
	ClosureGetExpr,
	ClosureSetExpr,
	Destructure,
	EnumFunction,
	FlagsFunction,
	FunBody,
	FunDecl,
	FunInst,
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
	Module,
	Program,
	PtrToFieldExpr,
	PtrToLocalExpr,
	RecordField,
	SeqExpr,
	StructBody,
	SpecDecl,
	StructDecl,
	StructInst,
	ThrowExpr,
	toLocal,
	TypeParamIndex,
	VarDecl,
	Visibility;
import util.opt : none, Opt, some;
import util.json : field;
import util.union_ : Union;

immutable struct Target {
	mixin Union!(
		StructBody.Enum.Member*,
		FunDecl*,
		PositionKind.ImportedName,
		PositionKind.LocalPosition,
		LoopExpr*,
		Module*,
		RecordField*,
		SpecDecl*,
		PositionKind.SpecSig,
		StructDecl*,
		PositionKind.TypeParamWithContainer,
		VarDecl*,
	);
}

Opt!Target targetForPosition(in Program program, PositionKind pos) =>
	pos.matchWithPointers!(Opt!Target)(
		(PositionKind.None) =>
			none!Target,
		(PositionKind.Expression x) =>
			exprTarget(program, x),
		(FunDecl* x) =>
			some(Target(x)),
		(PositionKind.FunExtern) =>
			none!Target,
		(PositionKind.FunSpecialModifier) =>
			none!Target,
		(PositionKind.ImportedModule x) =>
			some(Target(x.module_)),
		(PositionKind.ImportedName x) =>
			some(Target(x)),
		(PositionKind.Keyword _) =>
			none!Target,
		(PositionKind.LocalPosition x) =>
			some(Target(x)),
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
		(StructDecl* x) =>
			some(Target(x)),
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
		(Visibility _) =>
			none!Target);

Opt!Target exprTarget(in Program program, PositionKind.Expression a) {
	Opt!Target local(Local* x) =>
		some(Target(PositionKind.LocalPosition(LocalContainer(a.containingFun), x)));
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
		(FunPtrExpr x) =>
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
		(LiteralCStringExpr _) =>
			none!Target,
		(LiteralSymbolExpr _) =>
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
				(FunBody.Builtin) =>
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
