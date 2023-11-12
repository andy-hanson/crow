module frontend.ide.getTarget;

@safe @nogc pure nothrow:

import frontend.ide.position : PositionKind;
import model.model :
	Called,
	CalledSpecSig,
	decl,
	ExprKind,
	FunDecl,
	FunInst,
	Local,
	Module,
	Program,
	RecordField,
	SpecDecl,
	SpecDeclSig,
	SpecInst,
	StructDecl,
	StructInst,
	toLocal,
	Type,
	TypeParam,
	Visibility;
import util.opt : none, Opt, some;
import util.json : field;
import util.union_ : Union;

immutable struct Target {
	immutable struct LocalInFunction {
		FunDecl* containingFun;
		Local* local;
	}

	mixin Union!(
		FunDecl*,
		LocalInFunction,
		ExprKind.Loop*,
		Module*,
		RecordField*,
		SpecDecl*,
		SpecDeclSig*,
		StructDecl*,
		TypeParam*,
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
			// TODO: get the declaration
			none!Target,
		(PositionKind.Keyword _) =>
			none!Target,
		(PositionKind.LocalInFunction x) =>
			some(Target(Target.LocalInFunction(x.containingFun, x.local))),
		(PositionKind.RecordFieldMutability) =>
			none!Target,
		(PositionKind.RecordFieldPosition x) =>
			some(Target(x.field)),
		(SpecDecl* x) =>
			some(Target(x)),
		(SpecInst* x) =>
			some(Target(decl(*x))),
		(StructDecl* x) =>
			some(Target(x)),
		(Type x) =>
			x.matchWithPointers!(Opt!Target)(
				(Bogus) =>
					none!Target,
				(TypeParam* x) =>
					some(Target(x)),
				(StructInst* x) =>
					some(Target(decl(*x)))),
		(TypeParam* x) =>
			some(Target(x)),
		(Visibility _) =>
			none!Target);

Opt!Target exprTarget(in Program program, PositionKind.Expression a) {
	Opt!Target local(Local* x) =>
		some(Target(Target.LocalInFunction(a.containingFun, x)));
	return a.expr.kind.match!(Opt!Target)(
		(ExprKind.AssertOrForbid) =>
			none!Target,
		(ExprKind.Bogus) =>
			none!Target,
		(ExprKind.Call x) =>
			calledTarget(x.called),
		(ExprKind.ClosureGet x) =>
			local(toLocal(*x.closureRef)),
		(ExprKind.ClosureSet x) =>
			local(toLocal(*x.closureRef)),
		(ExprKind.FunPtr x) =>
			some(Target(decl(*x.funInst))),
		(ref ExprKind.If) =>
			none!Target,
		(ref ExprKind.IfOption) =>
			none!Target,
		(ref ExprKind.Lambda) =>
			none!Target,
		(ref ExprKind.Let) =>
			none!Target,
		(ref ExprKind.Literal) =>
			none!Target,
		(ExprKind.LiteralCString) =>
			none!Target,
		(ExprKind.LiteralSymbol) =>
			none!Target,
		(ExprKind.LocalGet x) =>
			local(x.local),
		(ref ExprKind.LocalSet x) =>
			local(x.local),
		(ref ExprKind.Loop x) =>
			some(Target(&x)),
		(ref ExprKind.LoopBreak x) =>
			some(Target(x.loop)),
		(ExprKind.LoopContinue x) =>
			some(Target(x.loop)),
		(ref ExprKind.LoopUntil) =>
			none!Target,
		(ref ExprKind.LoopWhile) =>
			none!Target,
		(ref ExprKind.MatchEnum) =>
			none!Target,
		(ref ExprKind.MatchUnion) =>
			none!Target,
		(ref ExprKind.PtrToField x) =>
			// TODO: target the field
			none!Target,
		(ExprKind.PtrToLocal x) =>
			local(x.local),
		(ref ExprKind.Seq) =>
			none!Target,
		(ref ExprKind.Throw) =>
			none!Target);
}

private:

Opt!Target calledTarget(ref Called a) =>
	a.match!(Opt!Target)(
		(ref FunInst x) =>
			some(Target(decl(x))),
		(ref CalledSpecSig x) =>
			some(Target(x.nonInstantiatedSig)));
