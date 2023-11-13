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
import util.col.arrUtil : arrLiteral;
import util.opt : force, has, Opt;
import util.sourceRange : UriAndRange;
import util.sym : AllSymbols;
import util.uri : Uri;

UriAndRange[] getDefinitionForPosition(ref Alloc alloc, in AllSymbols allSymbols, in Program program, in Position pos) {
	Opt!Target target = targetForPosition(program, pos.kind);
	return has(target)
		? definitionForTarget(alloc, allSymbols, pos.module_.uri, force(target))
		: [];
}

private:

UriAndRange[] definitionForTarget(ref Alloc alloc, in AllSymbols allSymbols, Uri curUri, in Target a) =>
	a.matchIn!(UriAndRange[])(
		(in FunDecl x) =>
			arrLiteral(alloc, [x.range]),
		(in Target.LocalInFunction x) =>
			arrLiteral(alloc, [localMustHaveNameRange(*x.local, allSymbols)]),
		(in ExprKind.Loop x) =>
			arrLiteral(alloc, [UriAndRange(curUri, loopKeywordRange(x))]),
		(in Module x) =>
			arrLiteral(alloc, [x.range]),
		(in RecordField x) =>
			arrLiteral(alloc, [uriAndRange(x)]),
		(in SpecDecl x) =>
			arrLiteral(alloc, [x.range]),
		(in SpecDeclSig x) =>
			arrLiteral(alloc, [x.range]),
		(in StructDecl x) =>
			arrLiteral(alloc, [x.range]),
		(in TypeParam x) =>
			arrLiteral(alloc, [x.range]));
