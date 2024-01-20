module frontend.ide.getDefinition;

@safe @nogc pure nothrow:

import frontend.ide.getTarget : Target, targetForPosition;
import frontend.ide.ideUtil : ReferenceCb;
import frontend.ide.position : Position, PositionKind;
import model.ast : rangeOfNameAndRange;
import model.model :
	EnumMember,
	FunDecl,
	LoopExpr,
	localMustHaveNameRange,
	loopKeywordRange,
	Module,
	nameRange,
	NameReferents,
	RecordField,
	SpecDecl,
	StructAlias,
	StructDecl,
	VarDecl,
	UnionMember;
import util.alloc.alloc : Alloc;
import util.col.arrayBuilder : buildArray, Builder;
import util.opt : force, has, Opt;
import util.sourceRange : UriAndRange;
import util.symbol : AllSymbols;
import util.uri : Uri;

UriAndRange[] getDefinitionForPosition(ref Alloc alloc, in AllSymbols allSymbols, in Position pos) {
	Opt!Target target = targetForPosition(pos.kind);
	return has(target)
		? buildArray!UriAndRange(alloc, (scope ref Builder!UriAndRange res) {
			definitionForTarget(allSymbols, pos.module_.uri, force(target), (in UriAndRange x) { res ~= x; });
		})
		: [];
}

private:

// public for 'getReferences' only
public void definitionForTarget(in AllSymbols allSymbols, Uri curUri, in Target a, in ReferenceCb cb) =>
	a.matchIn!void(
		(in EnumMember x) {
			cb(nameRange(allSymbols, x));
		},
		(in FunDecl x) {
			cb(nameRange(allSymbols, x));
		},
		(in PositionKind.ImportedName x) {
			definitionForImportedName(x, cb);
		},
		(in PositionKind.LocalPosition x) {
			cb(UriAndRange(x.container.moduleUri, localMustHaveNameRange(*x.local, allSymbols)));
		},
		(in LoopExpr x) {
			cb(UriAndRange(curUri, loopKeywordRange(x)));
		},
		(in Module x) {
			cb(x.range);
		},
		(in RecordField x) {
			cb(nameRange(allSymbols, x));
		},
		(in SpecDecl x) {
			cb(nameRange(allSymbols, x));
		},
		(in PositionKind.SpecSig x) {
			cb(nameRange(allSymbols, *x.sig));
		},
		(in StructAlias x) {
			cb(nameRange(allSymbols, x));
		},
		(in StructDecl x) {
			cb(nameRange(allSymbols, x));
		},
		(in PositionKind.TypeParamWithContainer x) {
			cb(UriAndRange(
				x.container.moduleUri,
				rangeOfNameAndRange(x.container.typeParams[x.typeParam.index], allSymbols)));
		},
		(in UnionMember x) {
			cb(nameRange(allSymbols, x));
		},
		(in VarDecl x) {
			cb(nameRange(allSymbols, x));
		});

void definitionForImportedName(in PositionKind.ImportedName a, in ReferenceCb cb) {
	if (has(a.referents)) {
		NameReferents nr = *force(a.referents);
		if (has(nr.structOrAlias))
			cb(force(nr.structOrAlias).range);
		if (has(nr.spec))
			cb(force(nr.spec).range);
		foreach (FunDecl* f; nr.funs)
			cb(f.range);
	}
}
