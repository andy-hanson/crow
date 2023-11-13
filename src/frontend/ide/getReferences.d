module frontend.ide.getReferences;

@safe @nogc pure nothrow:

import frontend.ide.getTarget : exprTarget, Target, targetForPosition;
import frontend.ide.position : Position, PositionKind;
import frontend.parse.ast : pathRange;
import model.model :
	eachDescendentExprExcluding,
	eachDescendentExprIncluding,
	Expr,
	ExprKind,
	FunBody,
	FunDecl,
	ImportOrExport,
	localMustHaveNameRange,
	loopKeywordRange,
	Module,
	Program,
	range,
	RecordField,
	SpecDecl,
	SpecDeclSig,
	StructDecl,
	TypeParam;
import util.alloc.alloc : Alloc;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.map : mapEach;
import util.json : Json, jsonList;
import util.lineAndColumnGetter : LineAndColumnGetters;
import util.opt : force, has, Opt, optEqual, some;
import util.ptr : ptrTrustMe;
import util.sourceRange : UriAndRange, jsonOfUriAndRange;
import util.sym : AllSymbols;
import util.uri : AllUris, Uri;
import util.util : typeAs;

UriAndRange[] getReferencesForPosition(
	ref Alloc alloc,
	in AllSymbols allSymbols,
	in AllUris allUris,
	in Program program,
	ref Position pos,
) {
	Opt!Target target = targetForPosition(program, pos.kind);
	return has(target) ? referencesForTarget(alloc, allSymbols, allUris, program, pos.module_.uri, force(target)) : [];
}

Json jsonOfReferences(
	ref Alloc alloc,
	in AllUris allUris,
	scope ref LineAndColumnGetters lineAndColumnGetters,
	in UriAndRange[] references,
) =>
	jsonList!UriAndRange(alloc, references, (in UriAndRange x) =>
		jsonOfUriAndRange(alloc, allUris, lineAndColumnGetters, x));

private:

UriAndRange[] referencesForTarget(
	ref Alloc alloc,
	in AllSymbols allSymbols,
	in AllUris allUris,
	in Program program,
	Uri curUri,
	return scope ref Target a,
) =>
	a.matchWithPointers!(UriAndRange[])(
		(FunDecl* x) =>
			// TODO
			typeAs!(UriAndRange[])([]),
		(Target.LocalInFunction x) =>
			referencesForLocal(alloc, allSymbols, program, curUri, x),
		(ExprKind.Loop* x) =>
			referencesForLoop(alloc, curUri, *x),
		(Module* x) =>
			referencesForModule(alloc, allUris, program, x),
		(RecordField* x) =>
			// TODO (get references for the get/set functions)
			typeAs!(UriAndRange[])([]),
		(SpecDecl* x) =>
			// TODO (search all functions)
			typeAs!(UriAndRange[])([]),
		(SpecDeclSig* x) =>
			// TODO (find call references)
			typeAs!(UriAndRange[])([]),
		(StructDecl* x) =>
			// TODO
			typeAs!(UriAndRange[])([]),
		(TypeParam* x) =>
			// TODO
			typeAs!(UriAndRange[])([]));

UriAndRange[] referencesForLocal(
	ref Alloc alloc,
	in AllSymbols allSymbols,
	in Program program,
	Uri curUri,
	in Target.LocalInFunction a,
) {
	ArrBuilder!UriAndRange res;
	add(alloc, res, localMustHaveNameRange(*a.local, allSymbols));
	Expr body_ = a.containingFun.body_.isA!(FunBody.ExpressionBody)
		? a.containingFun.body_.as!(FunBody.ExpressionBody).expr
		: Expr(UriAndRange.empty, ExprKind(ExprKind.Bogus()));
	eachDescendentExprIncluding(body_, (in Expr x) @safe {
		Opt!Target xTarget = exprTarget(program, PositionKind.Expression(a.containingFun, ptrTrustMe(x)));
		if (optEqual!Target(xTarget, some(Target(a))))
			add(alloc, res, x.range);
	});
	return finishArr(alloc, res);
}

UriAndRange[] referencesForLoop(ref Alloc alloc, Uri curUri, in ExprKind.Loop x) {
	ArrBuilder!UriAndRange res;
	add(alloc, res, UriAndRange(curUri, loopKeywordRange(x)));
	eachDescendentExprExcluding(ExprKind(&x), (in Expr child) {
		if (child.kind.isA!(ExprKind.LoopBreak*) || child.kind.isA!(ExprKind.LoopContinue))
			add(alloc, res, child.range);
	});
	return finishArr(alloc, res);
}

UriAndRange[] referencesForModule(ref Alloc alloc, in AllUris allUris, in Program program, in Module* target) {
	ArrBuilder!UriAndRange res;
	eachModuleReferencing(program, target, (in Module importer, in ImportOrExport ie) {
		if (has(ie.source))
			add(alloc, res, UriAndRange(importer.uri, pathRange(allUris, *force(ie.source))));
	});
	return finishArr(alloc, res);
}

void eachModuleReferencing(
	in Program program,
	in Module* target,
	in void delegate(in Module, in ImportOrExport) @safe @nogc pure nothrow cb,
) {
	mapEach!(Uri, immutable Module*)(program.allModules, (Uri _, ref immutable Module* module_) {
		eachModuleReference(*module_, target, (in ImportOrExport x) {
			cb(*module_, x);
		});
	});
}

void eachModuleReference(in Module a, Module* b, in void delegate(in ImportOrExport) @safe @nogc pure nothrow cb) {
	void iter(in ImportOrExport[] xs) {
		foreach (ImportOrExport ie; xs) {
			if (ie.kind.modulePtr == b)
				cb(ie);
		}
	}
	iter(a.imports);
	iter(a.reExports);
}
