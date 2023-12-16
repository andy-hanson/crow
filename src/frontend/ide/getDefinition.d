module frontend.ide.getDefinition;

@safe @nogc pure nothrow:

import frontend.ide.getTarget : Target, targetForPosition;
import frontend.ide.ideUtil : ReferenceCb;
import frontend.ide.position : Position, PositionKind;
import model.ast : rangeOfNameAndRange;
import model.model :
	FunDecl,
	LoopExpr,
	localMustHaveNameRange,
	loopKeywordRange,
	Module,
	nameRange,
	NameReferents,
	Program,
	RecordField,
	SpecDecl,
	StructBody,
	StructDecl,
	VarDecl;
import util.alloc.alloc : Alloc;
import util.col.arrayBuilder : buildArray;
import util.opt : force, has, Opt;
import util.sourceRange : UriAndRange;
import util.symbol : AllSymbols;
import util.uri : Uri;

UriAndRange[] getDefinitionForPosition(ref Alloc alloc, in AllSymbols allSymbols, in Program program, in Position pos) {
	Opt!Target target = targetForPosition(program, pos.kind);
	return has(target)
		? buildArray!UriAndRange(alloc, (in ReferenceCb cb) {
			definitionForTarget(allSymbols, pos.module_.uri, force(target), cb);
		})
		: [];
}

private:

// public for 'getReferences' only
public void definitionForTarget(in AllSymbols allSymbols, Uri curUri, in Target a, in ReferenceCb cb) =>
	a.matchIn!void(
		(in StructBody.Enum.Member x) {
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
		(in StructDecl x) {
			cb(nameRange(allSymbols, x));
		},
		(in PositionKind.TypeParamWithContainer x) {
			cb(UriAndRange(
				x.container.moduleUri,
				rangeOfNameAndRange(x.container.typeParams[x.typeParam.index], allSymbols)));
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
