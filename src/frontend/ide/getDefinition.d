module frontend.ide.getDefinition;

@safe @nogc pure nothrow:

import frontend.ide.position : Position, PositionKind;
import model.model :
	Called,
	CalledSpecSig,
	decl,
	Expr,
	ExprKind,
	FunDecl,
	FunInst,
	Local,
	localMustHaveRange,
	LocalSource,
	Module,
	Program,
	range,
	RecordField,
	SpecDecl,
	SpecDeclSig,
	SpecInst,
	StructDecl,
	StructInst,
	toLocal,
	Type,
	TypeParam,
	uriAndRange,
	Visibility;
import util.alloc.alloc : Alloc;
import util.opt : force, has, none, Opt, some;
import util.json : field, Json;
import util.sourceRange : UriAndRange, jsonOfUriAndRange;
import util.sym : AllSymbols;
import util.union_ : Union;
import util.uri : AllUris, Uri;

struct Definition {
	UriAndRange range;
}

Json jsonOfDefinition(ref Alloc alloc, in AllUris allUris, in Definition a) =>
	jsonOfUriAndRange(alloc, allUris, a.range);

Opt!Definition getDefinitionForPosition(in AllSymbols allSymbols, in Program program, in Position pos) {
	Opt!Target target = targetForPosition(program, pos.kind);
	return has(target)
		? some(definitionForTarget(allSymbols, program, pos.module_.uri, force(target)))
		: none!Definition;
}

private:

immutable struct Target {
	mixin Union!(
		FunDecl*,
		Local*,
		ExprKind.Loop*,
		Module*,
		RecordField*,
		SpecDecl*,
		SpecDeclSig*,
		StructDecl*,
		TypeParam*,
	);
}

Definition definitionForTarget(in AllSymbols allSymbols, in Program program, Uri curUri, in Target a) =>
	Definition(rangeForTarget(allSymbols, curUri, a));

UriAndRange rangeForTarget(in AllSymbols allSymbols, Uri curUri, in Target a) =>
	a.matchIn!UriAndRange(
		(in FunDecl x) =>
			x.range,
		(in Local x) =>
			localMustHaveRange(x, allSymbols),
		(in ExprKind.Loop x) =>
			UriAndRange(curUri, x.range),
		(in Module x) =>
			x.range,
		(in RecordField x) =>
			uriAndRange(x),
		(in SpecDecl x) =>
			x.range,
		(in SpecDeclSig x) =>
			x.range,
		(in StructDecl x) =>
			x.range,
		(in TypeParam x) =>
			x.range);

Opt!Target targetForPosition(in Program program, PositionKind pos) =>
	pos.matchWithPointers!(Opt!Target)(
		(PositionKind.None) =>
			none!Target,
		(Expr x) =>
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
		(PositionKind.LocalNonParameter x) =>
			some(Target(x.local)),
		(PositionKind.LocalParameter x) =>
			some(Target(x.local)),
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

Opt!Target exprTarget(in Program program, ref Expr a) =>
	a.kind.match!(Opt!Target)(
		(ExprKind.AssertOrForbid) =>
			none!Target,
		(ExprKind.Bogus) =>
			none!Target,
		(ExprKind.Call x) =>
			calledTarget(x.called),
		(ExprKind.ClosureGet x) =>
			some(Target(toLocal(*x.closureRef))),
		(ExprKind.ClosureSet x) =>
			some(Target(toLocal(*x.closureRef))),
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
			some(Target(x.local)),
		(ref ExprKind.LocalSet x) =>
			some(Target(x.local)),
		(ref ExprKind.Loop) =>
			none!Target,
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
			some(Target(x.local)),
		(ref ExprKind.Seq) =>
			none!Target,
		(ref ExprKind.Throw) =>
			none!Target);

Opt!Target calledTarget(ref Called a) =>
	a.match!(Opt!Target)(
		(ref FunInst x) =>
			some(Target(decl(x))),
		(ref CalledSpecSig x) =>
			some(Target(x.nonInstantiatedSig)));
