module backend.js.allUsed;

@safe @nogc pure nothrow:

import frontend.ide.getReferences : getCalledAtExpr;
import frontend.ide.ideUtil : eachDirectChildExpr; // TODO: MOVE ------------------------------------------------------------------------
import frontend.ide.position : ExprRef; // TODO: MOVE ------------------------------------------------------------------------
import model.model :
	asExtern,
	AutoFun,
	BuiltinFun,
	BuiltinType,
	Called,
	CallOptionExpr,
	CalledSpecSig,
	CallExpr,
	CommonTypes,
	Condition,
	Destructure,
	eachLocal,
	eachTest,
	EnumFunction,
	Expr,
	FlagsFunction,
	FunBody,
	FunDecl,
	FunInst,
	getModuleUri,
	IfExpr,
	Local,
	MatchEnumExpr,
	MatchUnionExpr,
	MatchVariantExpr,
	Module,
	paramsArray,
	Program,
	ProgramWithMain,
	RecordField,
	Signature,
	SpecDecl,
	SpecInst,
	Specs,
	StructAlias,
	StructBody,
	StructDecl,
	StructInst,
	Test,
	TryExpr,
	TryLetExpr,
	Type,
	TypeParamIndex,
	UnionMember,
	VarDecl,
	VariantAndMethodImpls,
	Visibility;
import util.alloc.alloc : Alloc;
import util.col.map : hasKey, Map, mustGet;
import util.col.mutMap : getOrAdd, mapToMap, MutMap;
import util.col.mutSet : mayAddToMutSet, MutSet;
import util.col.set : moveToSet, Set;
import util.opt : force, has, none, Opt, optIf, some;
import util.sourceRange : Range, UriAndRange;
import util.symbol : Symbol, symbol;
import util.symbolSet : SymbolSet;
import util.union_ : TaggedUnion;
import util.uri : Uri;
import util.util : ptrTrustMe, todo;
import versionInfo : isVersion, VersionInfo, VersionFun;

immutable struct AnyDecl {
	@safe @nogc pure nothrow:

	// WARN: We'll never consider a StructAlias as 'used', only the underlying StructDecl.
	// An inlined function is not considered used, just its return type
	mixin TaggedUnion!(FunDecl*, SpecDecl*, StructAlias*, StructDecl*, Test*, VarDecl*);

	Uri moduleUri() scope =>
		matchIn!Uri(
			(in FunDecl x) => x.moduleUri,
			(in SpecDecl x) => x.moduleUri,
			(in StructAlias x) => x.moduleUri,
			(in StructDecl x) => x.moduleUri,
			(in Test x) => x.moduleUri,
			(in VarDecl x) => x.moduleUri);

	Symbol name() scope =>
		matchIn!Symbol(
			(in FunDecl x) => x.name,
			(in SpecDecl x) => x.name,
			(in StructAlias x) => x.name,
			(in StructDecl x) => x.name,
			(in Test x) => symbol!"test",
			(in VarDecl x) => x.name);

	UriAndRange range() scope =>
		matchIn!UriAndRange(
			(in FunDecl x) => x.range,
			(in SpecDecl x) => x.range,
			(in StructAlias x) => x.range,
			(in StructDecl x) => x.range,
			(in Test x) => x.range,
			(in VarDecl x) => x.range);

	Visibility visibility() scope =>
		matchIn!Visibility(
			(in FunDecl x) => x.visibility,
			(in SpecDecl x) => x.visibility,
			(in StructAlias x) => x.visibility,
			(in StructDecl x) => x.visibility,
			// Treat as public since 'run-all-tests' runs tests from other modules
			(in Test x) => Visibility.public_,
			(in VarDecl x) => x.visibility);
}
// This does not include FunDecl if the body would be inlined
immutable struct AllUsed {
	Map!(Uri, Set!AnyDecl) usedByModule; // This will let us know exactly what each module needs to import.
	Set!AnyDecl usedDecls;
}
bool isUsedAnywhere(in AllUsed a, in AnyDecl x) =>
	a.usedDecls.has(x);
bool isModuleUsed(in AllUsed a, Uri module_) {
	// TODO: PERF ------------------------------------------------------------------------------------------------------------
	foreach (AnyDecl x; a.usedDecls) {
		if (x.moduleUri == module_)
			return true;
	}
	return false;
}

bool isUsedInModule(in AllUsed a, Uri module_, in AnyDecl x) {
	// TODO: could we ensure usedByModule is initialized so that this uses mustGet? ---------------------------------------------------
	Opt!(Set!AnyDecl) set = a.usedByModule[module_];
	return has(set) && force(set).has(x);
}

AllUsed allUsed(ref Alloc alloc, ref ProgramWithMain program, VersionInfo version_, SymbolSet allExtern) {
	AllUsedBuilder res = AllUsedBuilder(ptrTrustMe(alloc), ptrTrustMe(program.program), version_, allExtern);
	trackAllUsedInFun(res, program.mainFun.fun.decl.moduleUri, program.mainFun.fun.decl, FunUse.regular);
	return AllUsed(
		mapToMap!(Uri, Set!AnyDecl, MutSet!AnyDecl)(alloc, res.usedByModule, (ref MutSet!AnyDecl x) =>
			moveToSet(x)),
		moveToSet(res.usedDecls));
}

bool bodyIsInlined(in FunDecl a) =>
	!a.body_.isA!AutoFun && !a.body_.isA!Expr && !a.body_.isA!(FunBody.FileImport);

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
	immutable SymbolSet allExterns;
	MutMap!(Uri, MutSet!AnyDecl) usedByModule;
	MutSet!AnyDecl usedDecls;

	ref Alloc alloc() =>
		*allocPtr;
	ref CommonTypes commonTypes() =>
		*program.commonTypes;
}

bool addDecl(ref AllUsedBuilder res, Uri from, AnyDecl used) {
	MutSet!AnyDecl* perModule = &getOrAdd(res.alloc, res.usedByModule, from, () => MutSet!AnyDecl());
	return mayAddToMutSet(res.alloc, *perModule, used) && mayAddToMutSet(res.alloc, res.usedDecls, used);
}

void trackAllUsedInType(ref AllUsedBuilder res, Uri from, Type a) {
	a.match!void(
		(Type.Bogus) {},
		(TypeParamIndex _) {},
		(ref StructInst x) {
			if (!x.decl.body_.isA!BuiltinType)
				// Don't need to track type args since they are erased	
				trackAllUsedInStruct(res, from, x.decl);
		});
}
void trackAllUsedInStruct(ref AllUsedBuilder res, Uri from, StructDecl* a) {
	if (addDecl(res, from, AnyDecl(a))) {
		trackAllUsedInStructBody(res, a.moduleUri, a.body_);
		foreach (VariantAndMethodImpls x; a.variants) {
			trackAllUsedInStruct(res, a.moduleUri, x.variant.decl);
			foreach (Opt!Called impl; x.methodImpls)
				if (has(impl))
					trackAllUsedInCalled(res, a.moduleUri, force(impl), FunUse.regular);
		}
	}
}

void trackAllUsedInStructBody(ref AllUsedBuilder res, Uri from, in StructBody a) {
	a.match!void(
		(StructBody.Bogus) {},
		(BuiltinType _) {},
		(ref StructBody.Enum) {},
		(StructBody.Extern) { assert(false); },
		(StructBody.Flags) {},
		(StructBody.Record record) {
			foreach (RecordField field; record.fields)
				trackAllUsedInType(res, from, field.type);
		},
		(ref StructBody.Union x) {
			foreach (UnionMember member; x.members)
				trackAllUsedInType(res, from, member.type);
		},
		(StructBody.Variant) {});
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

enum FunUse { regular, noInline }
void trackAllUsedInFun(ref AllUsedBuilder res, Uri from, FunDecl* a, FunUse use) {
	// An inlined function isn't considered 'used', but its type is
	bool inlined = () {
		final switch (use) {
			case FunUse.regular:
				return bodyIsInlined(*a);
			case FunUse.noInline:
				return false;
		}
	}();
	if (inlined || addDecl(res, from, AnyDecl(a))) {
		if (true) { // TODO: make paaram type checks opitonal ----------------------------------------------------------------------------
			foreach (ref Destructure param; paramsArray(a.params)) {
				eachLocal(param, (Local* x) {
					trackAllUsedInType(res, a.moduleUri, x.type);
				});
			}
		}

		trackAllUsedInSpecs(res, from, a.specs);
		void usedReturnType(Uri where = from) {
			trackAllUsedInType(res, where, a.returnType);
		}
		a.body_.match!void(
			(FunBody.Bogus) {},
			(AutoFun x) {
				final switch (x.kind) {
					case AutoFun.Kind.equals:
						break;
					case AutoFun.Kind.compare:
					case AutoFun.Kind.toJson:
						usedReturnType(a.moduleUri);
						break;
				}
				foreach (Called called; x.members)
					trackAllUsedInCalled(res, a.moduleUri, called, FunUse.regular);
			},
			(BuiltinFun x) {
				if (x.isA!(BuiltinFun.AllTests)) {
					eachTest(*res.program, res.allExterns, (Test* test) {
						trackAllUsedInTest(res, from, test);
					});
				}
			},
			(FunBody.CreateEnumOrFlags) {
				usedReturnType();
			},
			(FunBody.CreateExtern) {
				assert(false);
			},
			(FunBody.CreateRecord) {
				usedReturnType();
			},
			(FunBody.CreateRecordAndConvertToVariant x) {
				trackAllUsedInStruct(res, from, x.member.decl);
			},
			(FunBody.CreateUnion) {
				usedReturnType();
			},
			(FunBody.CreateVariant) {},
			(EnumFunction _) {
				usedReturnType();
			},
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
void trackAllUsedInTest(ref AllUsedBuilder res, Uri from, Test* test) {
	if (addDecl(res, from, AnyDecl(test)))
		trackAllUsedInExprRef(res, test.moduleUri, ExprRef(&test.body_, Type(res.commonTypes.void_)));
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
void trackAllUsedInCalled(ref AllUsedBuilder res, Uri from, Called a, FunUse funUse) {
	a.match!void(
		(ref Called.Bogus) {},
		(ref FunInst x) {
			trackAllUsedInFun(res, from, x.decl, funUse);
			foreach (Called impl; x.specImpls)
				trackAllUsedInCalled(res, from, impl, FunUse.noInline);
		},
		(CalledSpecSig _) {});
}

void trackAllUsedInExprRef(ref AllUsedBuilder res, Uri from, ExprRef a) {
	Opt!Called called = getCalledAtExpr(a.expr.kind);
	if (has(called))
		trackAllUsedInCalled(res, from, force(called), FunUse.regular); // TODO: for a function pointer, this should not be regular, should be noInline

	void trackChildren() {
		eachDirectChildExpr(res.commonTypes, a, (ExprRef x) {
			trackAllUsedInExprRef(res, from, x);
		});
	}

	if (a.expr.kind.isA!(IfExpr*)) {
		IfExpr* if_ = a.expr.kind.as!(IfExpr*);
		Opt!bool constant = tryEvalConstantBool(res.version_, res.allExterns, if_.condition);
		if (has(constant))
			trackAllUsedInExprRef(res, from, ExprRef(force(constant) ? &if_.trueBranch : &if_.falseBranch, a.type));
		else
			trackChildren();
	} else {
		if (a.expr.kind.isA!(CallOptionExpr*))
			trackAllUsedInType(res, from, a.type);
		else if (a.expr.kind.isA!(MatchEnumExpr*)) // TODO: unions and variants too! ----------------------------------------------
			trackAllUsedInStruct(res, from, a.expr.kind.as!(MatchEnumExpr*).enum_);
		else if (a.expr.kind.isA!(MatchUnionExpr*))
			trackAllUsedInStruct(res, from, a.expr.kind.as!(MatchUnionExpr*).union_.decl);
		else if (a.expr.kind.isA!(MatchVariantExpr*))
			trackAllUsedInMatchVariantCases(res, from, a.expr.kind.as!(MatchVariantExpr*).cases);
		else if (a.expr.kind.isA!(TryExpr*))
			trackAllUsedInMatchVariantCases(res, from, a.expr.kind.as!(TryExpr*).catches);
		else if (a.expr.kind.isA!(TryLetExpr*))
			trackAllUsedInMatchVariantCase(res, from, a.expr.kind.as!(TryLetExpr*).catch_);
		trackChildren();
	}
}

void trackAllUsedInMatchVariantCases(ref AllUsedBuilder res, Uri from, in MatchVariantExpr.Case[] cases) {
	foreach (MatchVariantExpr.Case case_; cases)
		trackAllUsedInStruct(res, from, case_.member.decl);
}
void trackAllUsedInMatchVariantCase(ref AllUsedBuilder res, Uri from, in MatchVariantExpr.Case case_) {
	trackAllUsedInStruct(res, from, case_.member.decl);
}
