module frontend.ide.getDefinition;

@safe @nogc pure nothrow:

import frontend.ide.getTarget : Target, targetForPosition;
import frontend.ide.ideUtil : ReferenceCb;
import frontend.ide.position : Position, PositionKind;
import model.ast : ExprAst, LoopAst;
import model.model :
	EnumOrFlagsMember,
	FunDecl,
	localMustHaveNameRange,
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
		(in EnumOrFlagsMember x) {
			cb(x.nameRange(allSymbols));
		},
		(in FunDecl x) {
			cb(x.nameRange(allSymbols));
		},
		(in PositionKind.ImportedName x) {
			definitionForImportedName(allSymbols, x, cb);
		},
		(in PositionKind.LocalPosition x) {
			cb(UriAndRange(x.container.moduleUri, localMustHaveNameRange(*x.local, allSymbols)));
		},
		(in Target.Loop x) {
			ExprAst* ast = x.loop.expr.ast;
			cb(UriAndRange(curUri, ast.kind.as!(LoopAst*).keywordRange(ast)));
		},
		(in Module x) {
			cb(x.range);
		},
		(in RecordField x) {
			cb(x.nameRange(allSymbols));
		},
		(in SpecDecl x) {
			cb(x.nameRange(allSymbols));
		},
		(in PositionKind.SpecSig x) {
			cb(nameRange(allSymbols, *x.sig));
		},
		(in StructAlias x) {
			cb(x.nameRange(allSymbols));
		},
		(in StructDecl x) {
			cb(x.nameRange(allSymbols));
		},
		(in PositionKind.TypeParamWithContainer x) {
			cb(UriAndRange(x.container.moduleUri, x.container.typeParams[x.typeParam.index].range(allSymbols)));
		},
		(in UnionMember x) {
			cb(x.nameRange(allSymbols));
		},
		(in VarDecl x) {
			cb(x.nameRange(allSymbols));
		});

void definitionForImportedName(in AllSymbols allSymbols, in PositionKind.ImportedName a, in ReferenceCb cb) {
	if (has(a.referents)) {
		NameReferents nr = *force(a.referents);
		if (has(nr.structOrAlias))
			cb(force(nr.structOrAlias).range);
		if (has(nr.spec))
			cb(force(nr.spec).range);
		foreach (FunDecl* f; nr.funs)
			cb(f.range(allSymbols));
	}
}
