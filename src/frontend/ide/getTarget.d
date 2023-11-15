module frontend.ide.getTarget;

@safe @nogc pure nothrow:

import frontend.ide.position : LocalContainer, PositionKind;
import model.model :
	body_,
	Called,
	CalledSpecSig,
	decl,
	Destructure,
	EnumFunction,
	ExprKind,
	FlagsFunction,
	FunBody,
	FunDecl,
	FunInst,
	Local,
	Module,
	Program,
	RecordField,
	StructBody,
	SpecDecl,
	SpecInst,
	StructDecl,
	StructInst,
	toLocal,
	TypeParam,
	VarDecl,
	Visibility;
import util.opt : none, Opt, some;
import util.json : field;
import util.union_ : Union;
import util.util : todo;

immutable struct Target {
	mixin Union!(
		StructBody.Enum.Member*,
		FunDecl*,
		PositionKind.ImportedName,
		PositionKind.LocalPosition,
		ExprKind.Loop*,
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
		(SpecInst* x) =>
			some(Target(decl(*x))),
		(PositionKind.SpecSig x) =>
			some(Target(x)),
		(StructDecl* x) =>
			some(Target(x)),
		(PositionKind.TypeWithContainer x) =>
			x.type.matchWithPointers!(Opt!Target)(
				(Bogus) =>
					none!Target,
				(TypeParam* p) =>
					some(Target(PositionKind.TypeParamWithContainer(x.container, p))),
				(StructInst* x) =>
					some(Target(decl(*x)))),
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
		(ref FunInst funInst) {
			FunDecl* decl = decl(funInst);
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
					// goto the union member
					todo!Target("!"),
				(EnumFunction x) =>
					// goto the type
					returnTypeTarget(decl),
				(FunBody.Extern) =>
					Target(decl),
				(FunBody.ExpressionBody) =>
					Target(decl),
				(FunBody.FileBytes) =>
					todo!(Target)("!"),
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
		(ref CalledSpecSig x) =>
			some(Target(PositionKind.SpecSig(decl(*x.specInst), x.nonInstantiatedSig))));

Target returnTypeTarget(FunDecl* fun) =>
	Target(decl(*fun.returnType.as!(StructInst*)));

Target recordFieldTarget(FunDecl* fun, size_t fieldIndex) {
	StructDecl* record = decl(*fun.params.as!(Destructure[])[0].type.as!(StructInst*));
	return Target(&body_(*record).as!(StructBody.Record).fields[fieldIndex]);
}