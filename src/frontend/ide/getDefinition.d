module frontend.ide.getDefinition;

@safe @nogc pure nothrow:

import frontend.ide.getTarget : Target, targetForPosition;
import frontend.ide.ideUtil : ReferenceCb;
import frontend.ide.position : Position, PositionKind;
import model.model :
	ExprKind,
	FunDecl,
	localMustHaveNameRange,
	loopKeywordRange,
	Module,
	NameReferents,
	Program,
	range,
	RecordField,
	SpecDecl,
	StructDecl,
	uriAndRange;
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
		(in FunDecl x) {
			cb(x.range);
		},
		(in PositionKind.ImportedName x) {
			definitionForImportedName(x, cb);
		},
		(in PositionKind.LocalPosition x) {
			cb(localMustHaveNameRange(*x.local, allSymbols));
		},
		(in ExprKind.Loop x) {
			cb(UriAndRange(curUri, loopKeywordRange(x)));
		},
		(in Module x) {
			cb(x.range);
		},
		(in RecordField x) {
			cb(uriAndRange(x));
		},
		(in SpecDecl x) {
			cb(x.range);
		},
		(in PositionKind.SpecSig x) {
			cb(x.sig.range);
		},
		(in StructDecl x) {
			cb(x.range);
		},
		(in PositionKind.TypeParamWithContainer x) {
			cb(x.typeParam.range);
		});

void definitionForImportedName(in PositionKind.ImportedName a, in ReferenceCb cb) {
	NameReferents nr = optOrDefault!NameReferents(a.import_.kind.modulePtr.allExportedNames[a.name], () =>
		NameReferents());
	if (has(nr.structOrAlias))
		cb(range(force(nr.structOrAlias)));
	if (has(nr.spec))
		cb(force(nr.spec).range);
	foreach (FunDecl* f; nr.funs)
		cb(f.range);
}
