module backend.js.allUsed;

@safe @nogc pure nothrow:

import frontend.ide.getReferences : getCalledAtExpr;
import frontend.ide.ideUtil : eachDirectChildExpr; // TODO: MOVE ------------------------------------------------------------------------
import frontend.ide.position : ExprRef; // TODO: MOVE ------------------------------------------------------------------------
import model.model :
	asExtern,
	AutoFun,
	BuiltinFun,
	Called,
	CalledSpecSig,
	CallExpr,
	CommonTypes,
	Condition,
	Destructure,
	EnumFunction,
	Expr,
	FlagsFunction,
	FunBody,
	FunDecl,
	FunInst,
	getModuleUri,
	IfExpr,
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
import util.opt : force, has, none, Opt, optIf, some;
import util.symbol : Symbol;
import util.symbolSet : SymbolSet;
import util.union_ : TaggedUnion;
import util.uri : Uri;
import util.util : ptrTrustMe, todo;
import versionInfo : isVersion, VersionInfo, VersionFun;

immutable struct AnyDecl {
	@safe @nogc pure nothrow:

	// WARN: We'll never consider a StructAlias as 'used', only the underlying StructDecl.
	// An inlined function is not considered used, just its return type
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

AllUsed allUsed(ref Alloc alloc, ref ProgramWithMain program, VersionInfo version_, SymbolSet allExtern) {
	AllUsedBuilder res = AllUsedBuilder(ptrTrustMe(alloc), ptrTrustMe(program.program), version_, allExtern);
	trackAllUsedInFun(res, program.mainFun.fun.decl.moduleUri, program.mainFun.fun.decl);
	return AllUsed(
		mapToMap!(Uri, Set!AnyDecl, MutSet!AnyDecl)(alloc, res.usedPerModule, (ref MutSet!AnyDecl x) =>
			moveToSet(x)),
		moveToSet(res.usedDecls));
}

bool bodyIsInlined(in FunDecl a) =>
	!a.body_.isA!Expr && !a.body_.isA!(FunBody.FileImport);

Opt!bool tryEvalConstantBool(in VersionInfo version_, in SymbolSet allExtern, in Condition a) {
	if (a.isA!(Expr*)) {
		// TODO: PYRAMID OF DOOM! ------------------------------------------------------------------------------------------------
		Expr* x = a.as!(Expr*);
		if (x.kind.isA!CallExpr) {
			Called y = x.kind.as!CallExpr.called;
			if (y.isA!(FunInst*)) {
				FunDecl* decl = y.as!(FunInst*).decl;
				if (decl.body_.isA!BuiltinFun) {
					BuiltinFun bf = decl.body_.as!BuiltinFun;
					if (bf.isA!VersionFun) {
						return some(isVersion(version_, bf.as!VersionFun));
					}
				}
			}
		}
	}

	Opt!Symbol extern_ = asExtern(a);
	return optIf(has(extern_), () => allExtern.has(force(extern_)));
}

private:

struct AllUsedBuilder {
	@safe @nogc pure nothrow:

	Alloc* allocPtr;
	immutable Program* program;
	immutable VersionInfo version_;
	immutable SymbolSet allExtern;
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

void trackAllUsedInType(ref AllUsedBuilder res, Uri from, Type a) {
	a.match!void(
		(Type.Bogus) {},
		(TypeParamIndex _) {},
		(ref StructInst x) {
			// Don't need to track type args since they are erased	
			trackAllUsedInStruct(res, from, x.decl);
		});
}
void trackAllUsedInStruct(ref AllUsedBuilder res, Uri from, StructDecl* a) {
	if (addDecl(res, from, AnyDecl(a))) {
		foreach (VariantAndMethodImpls x; a.variants) {
			trackAllUsedInStruct(res, a.moduleUri, x.variant.decl);
			foreach (Opt!Called impl; x.methodImpls)
				if (has(impl))
					trackAllUsedInCalled(res, a.moduleUri, force(impl));
		}
	}
}

void trackAllUsedInSpec(ref AllUsedBuilder res, Uri from, SpecDecl* a) {
	if (addDecl(res, from, AnyDecl(a))) {
		trackAllUsedInSpecs(res, a.moduleUri, a.parents);
		foreach (Signature x; a.sigs)
			trackAllUsedInSignature(res, a.moduleUri, x);
	}
}
void trackAllUsedInSignature(ref AllUsedBuilder res, Uri from, Signature a) {
	trackAllUsedInType(res, from, a.returnType);
	trackAllUsedInDestructures(res, from, a.params);
}
void trackAllUsedInSpecs(ref AllUsedBuilder res, Uri from, Specs a) {
	foreach (SpecInst* x; a)
		trackAllUsedInSpec(res, from, x.decl);
}

void trackAllUsedInFun(ref AllUsedBuilder res, Uri from, FunDecl* a) {
	// An inlined function isn't considered 'used', but its type is
	if (bodyIsInlined(*a) || addDecl(res, from, AnyDecl(a))) {
		trackAllUsedInSpecs(res, from, a.specs);
		void usedReturnType() {
			trackAllUsedInType(res, from, a.returnType);
		}
		a.body_.match!void(
			(FunBody.Bogus) {},
			(AutoFun _) {},
			(BuiltinFun _) {},
			(FunBody.CreateEnumOrFlags) { usedReturnType(); },
			(FunBody.CreateExtern) { assert(false); },
			(FunBody.CreateRecord) { usedReturnType(); },
			(FunBody.CreateRecordAndConvertToVariant) { usedReturnType(); },
			(FunBody.CreateUnion) { usedReturnType(); },
			(FunBody.CreateVariant) {},
			(EnumFunction _) { usedReturnType(); },
			(Expr _) {
				trackAllUsedInExprRef(res, a.moduleUri, ExprRef(&a.body_.as!Expr(), a.returnType));
			},
			(FunBody.Extern _) {
				import util.writer : debugLogWithWriter, Writer; // --------------------------------------------------------------------------
				debugLogWithWriter((scope ref Writer writer) {
					writer ~= "Somehow, an extern function was used? ";
					writer ~= a.name;
				});
				assert(false);
			},
			(FunBody.FileImport _) {},
			(FlagsFunction _) {},
			(FunBody.RecordFieldCall) {},
			(FunBody.RecordFieldGet) {},
			(FunBody.RecordFieldPointer) { assert(false); },
			(FunBody.RecordFieldSet) {},
			(FunBody.UnionMemberGet) {},
			(FunBody.VarGet x) {
				addDecl(res, from, AnyDecl(x.var));
			},
			(FunBody.VariantMemberGet) {},
			(FunBody.VariantMethod) {},
			(FunBody.VarSet x) {
				addDecl(res, from, AnyDecl(x.var));
			});
	}
}
void trackAllUsedInDestructures(ref AllUsedBuilder res, Uri from, in Destructure[] a) {
	foreach (Destructure x; a)
		trackAllUsedInDestructure(res, from, x);
}
void trackAllUsedInDestructure(ref AllUsedBuilder res, Uri from, Destructure a) {
	a.match!void(
		(ref Destructure.Ignore x) {
			trackAllUsedInType(res, from, x.type);
		},
		(ref Local x) {
			trackAllUsedInType(res, from, x.type);
		},
		(ref Destructure.Split x) {
			trackAllUsedInType(res, from, x.destructuredType);
			foreach (Destructure part; x.parts)
				trackAllUsedInDestructure(res, from, part);
		});
}
void trackAllUsedInCalled(ref AllUsedBuilder res, Uri from, Called a) {
	a.match!void(
		(ref Called.Bogus) {},
		(ref FunInst x) {
			trackAllUsedInFun(res, from, x.decl);
		},
		(CalledSpecSig _) {});
}

void trackAllUsedInExprRef(ref AllUsedBuilder res, Uri from, ExprRef a) {
	Opt!Called called = getCalledAtExpr(a.expr.kind);
	if (has(called))
		trackAllUsedInCalled(res, from, force(called));

	void trackChildren() {
		eachDirectChildExpr(res.commonTypes, a, (ExprRef x) {
			trackAllUsedInExprRef(res, from, x);
		});
	}

	if (a.expr.kind.isA!(IfExpr*)) {
		IfExpr* if_ = a.expr.kind.as!(IfExpr*);
		Opt!bool constant = tryEvalConstantBool(res.version_, res.allExtern, if_.condition);
		if (has(constant))
			trackAllUsedInExprRef(res, from, ExprRef(force(constant) ? &if_.trueBranch : &if_.falseBranch, a.type));
		else
			trackChildren();
	} else
		trackChildren();
}
