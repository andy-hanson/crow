module backend.js.allUsed;

@safe @nogc pure nothrow:

import frontend.ide.getReferences : getCalledAtExpr;
import frontend.ide.ideUtil : eachDescendentExprIncluding; // TODO: MOVE ------------------------------------------------------------------------
import frontend.ide.position : ExprRef; // TODO: MOVE ------------------------------------------------------------------------
import model.model :
	Called,
	CalledSpecSig,
	CommonTypes,
	Destructure,
	Expr,
	FunBody,
	FunDecl,
	FunInst,
	getModuleUri,
	Local,
	Module,
	paramsArray,
	Program,
	ProgramWithMain,
	Signature,
	SpecDecl,
	SpecInst,
	Specs,
	StructAlias,
	StructDecl,
	StructInst,
	Type,
	TypeParamIndex,
	VarDecl,
	VariantAndMethodImpls,
	Visibility;
import util.alloc.alloc : Alloc;
import util.col.map : hasKey, Map, mustGet;
import util.col.mutMap : getOrAdd, mapToMap, MutMap;
import util.col.mutSet : mayAddToMutSet, MutSet;
import util.col.set : moveToSet, Set;
import util.opt : force, has, Opt;
import util.symbol : Symbol;
import util.union_ : TaggedUnion;
import util.uri : Uri;
import util.util : ptrTrustMe, todo;

immutable struct AnyDecl {
	@safe @nogc pure nothrow:

	// WARN: We'll never consider a StructAlias as 'used', only the underlying StructDecl
	mixin TaggedUnion!(FunDecl*, SpecDecl*, StructAlias*, StructDecl*, VarDecl*);

	Symbol name() scope =>
		matchIn!Symbol(
			(in FunDecl x) => x.name,
			(in SpecDecl x) => x.name,
			(in StructAlias x) => x.name,
			(in StructDecl x) => x.name,
			(in VarDecl x) => x.name);

	Visibility visibility() scope =>
		matchIn!Visibility(
			(in FunDecl x) => x.visibility,
			(in SpecDecl x) => x.visibility,
			(in StructAlias x) => x.visibility,
			(in StructDecl x) => x.visibility,
			(in VarDecl x) => x.visibility);
}
// This does not include FunDecl if the body would be inlined
immutable struct AllUsed {
	Map!(Uri, Set!AnyDecl) usedPerModule; // This will let us know exactly what each module needs to import.
	Set!AnyDecl usedDecls;
}
bool isUsedAnywhere(in AllUsed a, in AnyDecl x) =>
	a.usedDecls.has(x);
bool isModuleUsed(in AllUsed a, Uri module_) =>
	hasKey(a.usedPerModule, module_);
bool isUsedInModule(in AllUsed a, Uri module_, in AnyDecl x) =>
	mustGet(a.usedPerModule, module_).has(x);

AllUsed allUsed(ref Alloc alloc, ref ProgramWithMain program) {
	AllUsedBuilder res = AllUsedBuilder(ptrTrustMe(alloc), ptrTrustMe(program.program));
	trackAllUsed(res, program.mainFun.fun.decl.moduleUri, program.mainFun.fun.decl);
	return AllUsed(
		mapToMap!(Uri, Set!AnyDecl, MutSet!AnyDecl)(alloc, res.usedPerModule, (ref MutSet!AnyDecl x) =>
			moveToSet(x)),
		moveToSet(res.usedDecls));
}

bool bodyIsInlined(in FunDecl a) =>
	!a.body_.isA!Expr && !a.body_.isA!(FunBody.FileImport);

private:

struct AllUsedBuilder {
	@safe @nogc pure nothrow:

	Alloc* allocPtr;
	Program* program;
	MutMap!(Uri, MutSet!AnyDecl) usedPerModule;
	MutSet!AnyDecl usedDecls;

	ref Alloc alloc() =>
		*allocPtr;
	ref CommonTypes commonTypes() =>
		*program.commonTypes;
}

bool addDecl(ref AllUsedBuilder res, Uri from, AnyDecl used) {
	MutSet!AnyDecl* perModule = &getOrAdd(res.alloc, res.usedPerModule, from, () => MutSet!AnyDecl());
	return mayAddToMutSet(res.alloc, *perModule, used) && mayAddToMutSet(res.alloc, res.usedDecls, used);
}

void trackAllUsed(ref AllUsedBuilder res, Uri from, Type a) {
	a.match!void(
		(Type.Bogus) {},
		(TypeParamIndex _) {},
		(ref StructInst x) {
			// Don't need to track type args since they are erased	
			trackAllUsed(res, from, x.decl);
		});
}
void trackAllUsed(ref AllUsedBuilder res, Uri from, StructDecl* a) {
	if (addDecl(res, from, AnyDecl(a))) {
		foreach (VariantAndMethodImpls x; a.variants) {
			trackAllUsed(res, a.moduleUri, x.variant.decl);
			foreach (Opt!Called impl; x.methodImpls)
				if (has(impl))
					trackAllUsed(res, a.moduleUri, force(impl));
		}
	}
}

void trackAllUsed(ref AllUsedBuilder res, Uri from, SpecDecl* a) {
	if (addDecl(res, from, AnyDecl(a))) {
		trackAllUsed(res, a.moduleUri, a.parents);
		foreach (Signature x; a.sigs)
			trackAllUsed(res, a.moduleUri, x);
	}
}
void trackAllUsed(ref AllUsedBuilder res, Uri from, Signature a) {
	trackAllUsed(res, from, a.returnType);
	trackAllUsed(res, from, a.params);
}
void trackAllUsed(ref AllUsedBuilder res, Uri from, Specs a) {
	foreach (SpecInst* x; a)
		trackAllUsed(res, from, x.decl);
}

void trackAllUsed(ref AllUsedBuilder res, Uri from, FunDecl* a) {
	if (!bodyIsInlined(*a) && addDecl(res, from, AnyDecl(a))) {
		trackAllUsed(res, from, a.returnType);
		trackAllUsed(res, from, paramsArray(a.params));
		trackAllUsed(res, from, a.specs);
		if (a.body_.isA!Expr)
			trackAllUsed(res, from, ExprRef(&a.body_.as!Expr(), a.returnType));
	}
}
void trackAllUsed(ref AllUsedBuilder res, Uri from, in Destructure[] a) {
	foreach (Destructure x; a)
		trackAllUsed(res, from, x);
}
void trackAllUsed(ref AllUsedBuilder res, Uri from, Destructure a) {
	a.match!void(
		(ref Destructure.Ignore x) {
			trackAllUsed(res, from, x.type);
		},
		(ref Local x) {
			trackAllUsed(res, from, x.type);
		},
		(ref Destructure.Split x) {
			trackAllUsed(res, from, x.destructuredType);
			foreach (Destructure part; x.parts)
				trackAllUsed(res, from, part);
		});
}
void trackAllUsed(ref AllUsedBuilder res, Uri from, Called a) {
	a.match!void(
		(ref Called.Bogus) {},
		(ref FunInst x) {
			trackAllUsed(res, from, x.decl);
		},
		(CalledSpecSig _) {});
}

void trackAllUsed(ref AllUsedBuilder res, Uri from, ExprRef a) {
	eachDescendentExprIncluding(res.commonTypes, a, (ExprRef x) {
		Opt!Called called = getCalledAtExpr(x.expr.kind);
		if (has(called))
			trackAllUsed(res, from, force(called));
	});
}
