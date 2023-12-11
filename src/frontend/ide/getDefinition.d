module frontend.ide.getDefinition;

@safe @nogc pure nothrow:

import frontend.parse.ast : rangeOfNameAndRange;
import frontend.ide.getTarget : Target, targetForPosition;
import frontend.ide.ideUtil : ReferenceCb;
import frontend.ide.position : Position, PositionKind;
import model.diag : typeParamAsts, uriOfTypeContainer;
import model.model :
	FunDecl,
	LoopExpr,
	localMustHaveNameRange,
	loopKeywordRange,
	Module,
	nameRange,
	NameReferents,
	Program,
	range,
	RecordField,
	SpecDecl,
	StructBody,
	StructDecl,
	VarDecl;
import util.alloc.alloc : Alloc;
import util.col.arrBuilder : buildArray;
import util.opt : force, has, Opt, optOrDefault;
import util.sourceRange : UriAndRange;
import util.sym : AllSymbols;
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
			cb(localMustHaveNameRange(*x.local, allSymbols));
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
				uriOfTypeContainer(x.container),
				rangeOfNameAndRange(typeParamAsts(x.container)[x.typeParam.index], allSymbols)));
		},
		(in VarDecl x) {
			cb(nameRange(allSymbols, x));
		});

void definitionForImportedName(in PositionKind.ImportedName a, in ReferenceCb cb) {
	NameReferents nr = optOrDefault!NameReferents(a.import_.modulePtr.allExportedNames[a.name], () =>
		NameReferents());
	if (has(nr.structOrAlias))
		cb(range(force(nr.structOrAlias)));
	if (has(nr.spec))
		cb(range(*force(nr.spec)));
	foreach (FunDecl* f; nr.funs)
		cb(range(*f));
}
