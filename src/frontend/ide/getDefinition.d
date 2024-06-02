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
import util.uri : Uri;

UriAndRange[] getDefinitionForPosition(ref Alloc alloc, in Position pos) {
	Opt!Target target = targetForPosition(pos.kind);
	return has(target)
		? buildArray!UriAndRange(alloc, (scope ref Builder!UriAndRange res) {
			definitionForTarget(pos.module_.uri, force(target), (in UriAndRange x) { res ~= x; });
		})
		: [];
}

private:

// public for 'getReferences' only
public void definitionForTarget(Uri curUri, in Target a, in ReferenceCb cb) =>
	a.matchIn!void(
		(in EnumOrFlagsMember x) {
			cb(x.nameRange);
		},
		(in FunDecl x) {
			cb(x.nameRange);
		},
		(in PositionKind.ImportedName x) {
			definitionForImportedName(x, cb);
		},
		(in PositionKind.LocalPosition x) {
			cb(UriAndRange(x.container.moduleUri, localMustHaveNameRange(*x.local)));
		},
		(in Target.Loop x) {
			ExprAst* ast = x.loop.expr.ast;
			cb(UriAndRange(curUri, ast.kind.as!(LoopAst*).keywordRange(ast)));
		},
		(in Module x) {
			cb(x.range);
		},
		(in RecordField x) {
			cb(x.nameRange);
		},
		(in SpecDecl x) {
			cb(x.nameRange);
		},
		(in PositionKind.SpecSig x) {
			cb(x.sig.nameRange);
		},
		(in StructAlias x) {
			cb(x.nameRange);
		},
		(in StructDecl x) {
			cb(x.nameRange);
		},
		(in PositionKind.TypeParamWithContainer x) {
			cb(UriAndRange(x.container.moduleUri, x.container.typeParams[x.typeParam.index].range));
		},
		(in UnionMember x) {
			cb(x.nameRange);
		},
		(in VarDecl x) {
			cb(x.nameRange);
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
