module frontend.ide.getDefinition;

@safe @nogc pure nothrow:

import frontend.ide.getTarget : Target, targetForPosition;
import frontend.ide.position : Position;
import model.model :
	ExprKind,
	FunDecl,
	localMustHaveNameRange,
	loopKeywordRange,
	Module,
	Program,
	range,
	RecordField,
	SpecDecl,
	SpecDeclSig,
	StructDecl,
	TypeParam,
	uriAndRange;
import util.alloc.alloc : Alloc;
import util.json : Json;
import util.lineAndColumnGetter : LineAndColumnGetters;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : UriAndRange, jsonOfUriAndRange;
import util.sym : AllSymbols;
import util.uri : AllUris, Uri;

struct Definition {
	UriAndRange range;
}

Json jsonOfDefinition(ref Alloc alloc, in AllUris allUris, ref LineAndColumnGetters lcg, in Definition a) =>
	jsonOfUriAndRange(alloc, allUris, lcg, a.range);

Opt!Definition getDefinitionForPosition(in AllSymbols allSymbols, in Program program, in Position pos) {
	Opt!Target target = targetForPosition(program, pos.kind);
	return has(target)
		? some(definitionForTarget(allSymbols, program, pos.module_.uri, force(target)))
		: none!Definition;
}

private:

Definition definitionForTarget(in AllSymbols allSymbols, in Program program, Uri curUri, in Target a) =>
	Definition(rangeForTarget(allSymbols, curUri, a));

UriAndRange rangeForTarget(in AllSymbols allSymbols, Uri curUri, in Target a) =>
	a.matchIn!UriAndRange(
		(in FunDecl x) =>
			x.range,
		(in Target.LocalInFunction x) =>
			localMustHaveNameRange(*x.local, allSymbols),
		(in ExprKind.Loop x) =>
			UriAndRange(curUri, loopKeywordRange(x)),
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
