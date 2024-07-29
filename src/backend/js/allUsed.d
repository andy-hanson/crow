module backend.js.allUsed;

@safe @nogc pure nothrow:

import backend.js.jsAst : SyncOrAsync;
import frontend.ide.ideUtil : variantMethodCaller;
import frontend.showModel : ShowCtx, ShowTypeCtx, writeFunDecl;
import model.constant : Constant;
import model.model :
	asExtern,
	AssertOrForbidExpr,
	AutoFun,
	Builtin4ary,
	BuiltinBinary,
	BuiltinBinaryLazy,
	BuiltinBinaryMath,
	BuiltinFun,
	BuiltinTernary,
	BuiltinType,
	BuiltinUnary,
	BuiltinUnaryMath,
	Called,
	CallOptionExpr,
	CalledSpecSig,
	CallExpr,
	CommonTypes,
	Condition,
	Destructure,
	eachDirectChildExpr,
	eachSpecSigAndImpl,
	eachLocal,
	eachTest,
	EnumOrFlagsFunction,
	evalExternCondition,
	Expr,
	ExprRef,
	ExternCondition,
	FunBody,
	funBodyExprRef,
	FunDecl,
	FunDeclSource,
	FunInst,
	FunKind,
	getCalledAtExpr,
	IfExpr,
	JsFun,
	LiteralStringLikeExpr,
	Local,
	MatchEnumExpr,
	MatchUnionExpr,
	MatchVariantExpr,
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
	testBodyExprRef,
	TryExpr,
	TryLetExpr,
	Type,
	TypeParamIndex,
	UnionMember,
	VarDecl,
	VariantAndMethodImpls,
	Visibility;
import util.alloc.alloc : Alloc;
import util.col.array : zipPointers;
import util.col.map : Map, mustGet;
import util.col.mutArr : mustPop, MutArr, mutArrIsEmpty, push;
import util.col.mutMap : getOrAdd, mapToMap, MutMap;
import util.col.mutMultiMap : add, countKeys, countPairs, eachValueForKey, MutMultiMap;
import util.col.mutSet : mayAddToMutSet, MutSet;
import util.col.set : moveToSet, Set;
import util.hash : HashCode, hashPointers;
import util.opt : force, has, none, Opt, optIf, some;
import util.sourceRange : UriAndRange;
import util.symbol : Symbol, symbol;
import util.symbolSet : SymbolSet;
import util.union_ : TaggedUnion;
import util.uri : Uri;
import util.util : ptrTrustMe, todo;
import util.writer : debugLogWithWriter, Writer; // -------------------------------------------------------------------------
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
	private:
	public Map!(Uri, Set!AnyDecl) usedByModule; // This will let us know exactly what each module needs to import. TODO: PRIVATE
	Set!AnyDecl usedDecls;
	AsyncSets async;
}
bool isUsedAnywhere(in AllUsed a, in AnyDecl x) =>
	x in a.usedDecls;
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
	return has(set) && x in force(set);
}

private immutable struct AsyncSets {
	Set!(FunDecl*) asyncFuns;
	Set!(FunAndSpecSig) asyncSpecSigs;
}
SyncOrAsync isAsyncFun(in AllUsed a, FunDecl* fun) =>
	fun in a.async.asyncFuns ? SyncOrAsync.async : SyncOrAsync.sync;
SyncOrAsync isAsyncCall(in AllUsed a, in FunDecl* caller, in Called called) =>
	isAsyncCall(a, some(caller), called);
SyncOrAsync isAsyncCall(in AllUsed a, in Opt!(FunDecl*) caller, in Called called) =>
	called.matchIn!SyncOrAsync(
		(in Called.Bogus) =>
			SyncOrAsync.sync,
		(in FunInst x) =>
			isAsyncFun(a, x.decl),
		(in CalledSpecSig x) =>
			FunAndSpecSig(force(caller), x.nonInstantiatedSig) in a.async.asyncSpecSigs ? SyncOrAsync.async : SyncOrAsync.sync);

immutable struct FunOrTest {
	@safe @nogc pure nothrow:
	mixin TaggedUnion!(FunDecl*, Test*);

	Uri moduleUri() scope =>
		matchIn!Uri(
			(in FunDecl x) =>
				x.moduleUri,
			(in Test x) =>
				x.moduleUri);
}
Opt!(FunDecl*) optAsFun(FunOrTest a) =>
	a.matchWithPointers!(Opt!(FunDecl*))(
		(FunDecl* x) => some(x),
		(Test* _) => none!(FunDecl*));

AllUsed allUsed(ref Alloc alloc, in ShowCtx showCtx, ref ProgramWithMain program, VersionInfo version_, SymbolSet allExtern) { // TODO: showCtx unused
	AllUsedBuilder res = AllUsedBuilder(ptrTrustMe(alloc), ptrTrustMe(program.program), version_, allExtern);
	trackAllUsedInFun(res, program.mainFun.fun.decl.moduleUri, program.mainFun.fun.decl, FunUse.regular);
	// Main module needs to create a new list
	if (program.mainFun.needsArgsList)
		trackAllUsedInFun(res, program.mainFun.fun.decl.moduleUri, program.program.commonFuns.newTList, FunUse.regular);
	return AllUsed(
		mapToMap!(Uri, Set!AnyDecl, MutSet!AnyDecl)(alloc, res.usedByModule, (ref MutSet!AnyDecl x) =>
			moveToSet(x)),
		moveToSet(res.usedDecls),
		allAsyncFuns(res, showCtx));
}

bool bodyIsInlined(in FunDecl a) =>
	(!a.body_.isA!AutoFun && !a.body_.isA!Expr && !a.body_.isA!(FunBody.FileImport)) ||
	(a.body_.isA!BuiltinFun && !isInlinedBuiltinFun(a.body_.as!BuiltinFun));
private bool isInlinedBuiltinFun(in BuiltinFun a) =>
	a.matchIn!bool(
		(in BuiltinFun.AllTests) =>
			false,
		(in BuiltinUnary _) =>
			true,
		(in BuiltinUnaryMath x) {
			switch (x) {
				case BuiltinUnaryMath.roundFloat32:
				case BuiltinUnaryMath.roundFloat64:
					return false;
				default:
					return true;
			}
		},
		(in BuiltinBinary _) =>
			true,
		(in BuiltinBinaryLazy _) =>
			true,
		(in BuiltinBinaryMath _) =>
			true,
		(in BuiltinTernary _) =>
			true,
		(in Builtin4ary _) =>
			true,
		(in BuiltinFun.CallLambda) =>
			true,
		(in BuiltinFun.CallFunPointer) =>
			true,
		(in Constant _) =>
			true,
		(in BuiltinFun.GcSafeValue) =>
			true,
		(in BuiltinFun.Init) =>
			true,
		(in JsFun _) =>
			true,
		(in BuiltinFun.MarkRoot) =>
			assert(false),
		(in BuiltinFun.MarkVisit) =>
			assert(false),
		(in BuiltinFun.PointerCast) =>
			assert(false),
		(in BuiltinFun.SizeOf) =>
			assert(false),
		(in BuiltinFun.StaticSymbols) =>
			assert(false),
		(in VersionFun _) =>
			assert(false));

Opt!bool tryEvalConstantBool(in VersionInfo version_, in SymbolSet allExterns, in Condition a) {
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

	Opt!ExternCondition extern_ = asExtern(a);
	return optIf(has(extern_), () => evalExternCondition(force(extern_), allExterns));
}

private:

AsyncSets allAsyncFuns(ref AllUsedBuilder builder, in ShowCtx showCtx) {
	MutSet!(FunDecl*) asyncFuns;
	MutSet!(FunAndSpecSig) asyncSpecSigs;
	MutArr!(FunDecl*) funsToProcess;

	scope ShowTypeCtx showTypeCtx = ShowTypeCtx(showCtx, builder.program.commonTypes);

	debugLogWithWriter((scope ref Writer writer) { // --------------------------------------------------------------------------
		writer ~= "Top of allAsyncFuns:\n";
		writer ~= "countKeys(funToCallers) is ";
		writer ~= countKeys(builder.funToCallers);
		writer ~= " ";
		writer ~= countPairs(builder.funToCallers);
		writer ~= "\nfunToUsedAsSpecImpl: ";
		writer ~= countKeys(builder.funToUsedAsSpecImpl);
		writer ~= " ";
		writer ~= countPairs(builder.funToUsedAsSpecImpl);
		writer ~= "\nspecSigToUsedAsSpecImpl: ";
		writer ~= countKeys(builder.specSigToUsedAsSpecImpl);
		writer ~= " ";
		writer ~= countPairs(builder.specSigToUsedAsSpecImpl);
	});

	bool addFun(FunDecl* x) {
		bool res = mayAddToMutSet(builder.alloc, asyncFuns, x);
		if (res)
			push(builder.alloc, funsToProcess, x);
		return res;
	}

	addFun(builder.program.commonFuns.await);
	foreach (FunKind _, ref immutable FunDecl* f; builder.program.commonFuns.lambdaSubscript)
		addFun(f);

	void recurFunAndSpecSig(FunAndSpecSig x) @safe @nogc nothrow {
		addFun(x.fun);
		bool addedIt = mayAddToMutSet(builder.alloc, asyncSpecSigs, x); // TODO: INLINE ----------------------------------------------------
		if (addedIt) {
			if (x.fun.name == symbol!"size" || x.specSig.name == symbol!"size") {
				debugLogWithWriter((scope ref Writer writer) { // ------------------------------------------------------------------------
					writer ~= "Added an async spec sig ";
					writeFunAndSpecSig(writer, showTypeCtx, x);
				});
			}

			eachValueForKey(builder.specSigToUsedAsSpecImpl, x, (FunAndSpecSig y) {
				if (x.fun.name == symbol!"size" || x.specSig.name == symbol!"size" || y.fun.name == symbol!"size" || y.specSig.name == symbol!"size") {
					debugLogWithWriter((scope ref Writer writer) {
						writer ~= "The spec sig is also used as a spec impl: ";
						writeFunAndSpecSig(writer, showTypeCtx, y);						
					});
				}
				recurFunAndSpecSig(y);
			});
		}
	}

	while (!mutArrIsEmpty(funsToProcess)) {
		FunDecl* fun = mustPop(funsToProcess);
		eachValueForKey(builder.funToCallers, fun, (FunDecl* caller) {
			addFun(caller);
		});
		eachValueForKey(builder.funToUsedAsSpecImpl, fun, (FunAndSpecSig x) {
			if (fun.name == symbol!"size") {
				debugLogWithWriter((scope ref Writer writer) { // ------------------------------------------------------------------------
					writer ~= "This function is used as a spec impl: ";
					writeFunDecl(writer, showTypeCtx, fun);
					writer ~= "   used by ";
					writeFunAndSpecSig(writer, showTypeCtx, x);
				});
			}

			recurFunAndSpecSig(x);
		});
	}

	return AsyncSets(moveToSet(asyncFuns), moveToSet(asyncSpecSigs));
}

void writeFunAndSpecSig(scope ref Writer writer, in ShowTypeCtx showTypeCtx, in FunAndSpecSig a) {
	writer ~= "{fun:";
	writeFunDecl(writer, showTypeCtx, a.fun);
	writer ~= ", sig:";
	writer ~= a.specSig.name;
	writer ~= "}";
}

struct AllUsedBuilder {
	@safe @nogc pure nothrow:

	Alloc* allocPtr;
	immutable Program* program;
	immutable VersionInfo version_;
	immutable SymbolSet allExterns;
	MutMap!(Uri, MutSet!AnyDecl) usedByModule;
	MutSet!AnyDecl usedDecls;
	MutMultiMap!(StructDecl*, StructDecl*) variantMembers;

	// Map from each function to all functions that directly call it.
	MutMultiMap!(FunDecl*, FunDecl*) funToCallers;
	// Maps a function to where it is used as a spec implementation.
	MutMultiMap!(FunDecl*, FunAndSpecSig) funToUsedAsSpecImpl;
	// Maps a spec signature in a function to spec signagures in other functions that are used to implement it.
	MutMultiMap!(FunAndSpecSig, FunAndSpecSig) specSigToUsedAsSpecImpl;

	ref Alloc alloc() =>
		*allocPtr;
	ref CommonTypes commonTypes() =>
		*program.commonTypes;
}
immutable struct FunAndSpecSig {
	@safe @nogc pure nothrow:

	FunDecl* fun;
	Signature* specSig;

	HashCode hash() scope =>
		hashPointers(fun, specSig);
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
			add(res.alloc, res.variantMembers, x.variant.decl, a); // TODO: I think we should just add to callers directly -------------------------
			zipPointers(x.variantDeclMethods, x.methodImpls, (Signature* method, Opt!Called* impl) {
				if (has(*impl))
					trackAllUsedInCalled(
						res, a.moduleUri,
						some(variantMethodCaller(*res.program, FunDeclSource.VariantMethod(x.variant.decl, method))),
						force(*impl), FunUse.regular);
			});
		}
	}
}

void trackAllUsedInStructBody(ref AllUsedBuilder res, Uri from, in StructBody a) {
	a.match!void(
		(StructBody.Bogus) {},
		(BuiltinType _) {},
		(ref StructBody.Enum) {
			// 'members' constructs pairs
			trackAllUsedInStruct(res, from, res.program.commonTypes.pair);
		},
		(StructBody.Extern) { assert(false); },
		(StructBody.Flags) {
			// 'members' constructs pairs
			trackAllUsedInStruct(res, from, res.program.commonTypes.pair);
		},
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
						usedReturnType(a.moduleUri);
						break;
					case AutoFun.Kind.toJson:
						usedReturnType(a.moduleUri);
						trackAllUsedInCalled(res, a.moduleUri, some(a), Called(res.program.commonFuns.newJsonFromPairs), FunUse.regular);
						break;
				}
				foreach (Called called; x.members)
					trackAllUsedInCalled(res, a.moduleUri, some(a), called, FunUse.regular);
			},
			(BuiltinFun x) {
				if (x.isA!(BuiltinFun.AllTests)) {
					eachTest(*res.program, res.allExterns, (Test* test) {
						trackAllUsedInTest(res, from, test);
					});
				} else if (x.isA!(BuiltinFun.CallLambda))
					usedTuple(res, from, a.arity.as!uint - 1);
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
			(EnumOrFlagsFunction _) {
				usedReturnType();
			},
			(Expr _) {
				trackAllUsedInExprRef(res, FunOrTest(a), funBodyExprRef(a));
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
			(FunBody.RecordFieldCall) {
				usedTuple(res, from, a.arity.as!uint - 1);
			},
			(FunBody.RecordFieldGet) {},
			(FunBody.RecordFieldPointer) { assert(false); },
			(FunBody.RecordFieldSet) {},
			(FunBody.UnionMemberGet) {},
			(FunBody.VarGet x) {
				cast(void) addDecl(res, from, AnyDecl(x.var));
			},
			(FunBody.VariantMemberGet) {},
			(FunBody.VariantMethod) {},
			(FunBody.VarSet x) {
				cast(void) addDecl(res, from, AnyDecl(x.var));
			});
	}
}
void trackAllUsedInTest(ref AllUsedBuilder res, Uri from, Test* test) {
	if (addDecl(res, from, AnyDecl(test)))
		trackAllUsedInExprRef(res, FunOrTest(test), testBodyExprRef(res.commonTypes, test));
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

// 'from' may differ from 'caller' for a variant method. 'called' is used from the variant member, but the caller is the variant method.
void trackAllUsedInCalled(ref AllUsedBuilder res, Uri from, Opt!(FunDecl*) caller, Called called, FunUse funUse) {
	called.match!void(
		(ref Called.Bogus) {},
		(ref FunInst calledInst) {
			trackAllUsedInCalledFunInst(res, from, caller, calledInst, funUse);
		},
		(CalledSpecSig x) {
			// Functions are presumed to call their specs, so nothing to do here.
		});
}
void trackAllUsedInCalledFunInst(ref AllUsedBuilder res, Uri from, Opt!(FunDecl*) caller, ref FunInst calledInst, FunUse funUse) {
	FunDecl* calledDecl = calledInst.decl;
	trackAllUsedInFun(res, from, calledDecl, funUse);
	if (has(caller))
		add(res.alloc, res.funToCallers, calledDecl, force(caller));
	eachSpecSigAndImpl(*calledDecl, calledInst.specImpls, (SpecInst* spec, Signature* sig, Called impl) {
		trackAllUsedInSpecImpl(res, caller, calledDecl, spec, sig, impl);
		trackAllUsedInCalled(res, from, caller, impl, FunUse.noInline);
	});
}
void trackAllUsedInSpecImpl(ref AllUsedBuilder res, Opt!(FunDecl*) caller, FunDecl* calledDecl, SpecInst* spec, Signature* sig, Called impl) {
	impl.match!void(
		(ref Called.Bogus) {},
		(ref FunInst x) {
			add(res.alloc, res.funToUsedAsSpecImpl, x.decl, FunAndSpecSig(calledDecl, sig));
			eachSpecSigAndImpl(*x.decl, x.specImpls, (SpecInst* spec2, Signature* sig2, Called impl2) {
				trackAllUsedInSpecImpl(res, caller, x.decl, spec2, sig2, impl2);
			});
		},
		(CalledSpecSig x) {
			if (has(caller))
				add(
					res.alloc,
					res.specSigToUsedAsSpecImpl,
					FunAndSpecSig(force(caller), x.nonInstantiatedSig),
					FunAndSpecSig(calledDecl, sig));
		});
}

void usedTuple(ref AllUsedBuilder res, Uri from, uint tupleSize) {
	if (tupleSize >= 2)
		trackAllUsedInStruct(res, from, force(res.commonTypes.tuple(tupleSize)));
}

void trackAllUsedInExprRef(ref AllUsedBuilder res, FunOrTest curFunc, ExprRef a) {
	Uri from = curFunc.moduleUri;
	Opt!Called called = getCalledAtExpr(a.expr.kind);
	if (has(called))
		trackAllUsedInCalled(res, from, optAsFun(curFunc), force(called), FunUse.regular); // TODO: for a function pointer, this should not be regular, should be noInline

	void trackChildren() {
		eachDirectChildExpr(res.commonTypes, a, (ExprRef x) {
			trackAllUsedInExprRef(res, curFunc, x);
		});
	}

	if (a.expr.kind.isA!(IfExpr*)) {
		IfExpr* if_ = a.expr.kind.as!(IfExpr*);
		Opt!bool constant = tryEvalConstantBool(res.version_, res.allExterns, if_.condition);
		if (has(constant))
			trackAllUsedInExprRef(res, curFunc, ExprRef(force(constant) ? &if_.trueBranch : &if_.falseBranch, a.type));
		else
			trackChildren();
	} else {
		// TODO: use a 'match' -----------------------------------------------------------------------------------------------------
		if (a.expr.kind.isA!(AssertOrForbidExpr*)) {
			if (!has(a.expr.kind.as!(AssertOrForbidExpr*).thrown))
				trackAllUsedInFun(res, from, res.program.commonFuns.createError.decl, FunUse.regular);
		} else if (a.expr.kind.isA!(CallOptionExpr*))
			trackAllUsedInType(res, from, a.type);
		else if (a.expr.kind.isA!LiteralStringLikeExpr) {
			if (a.expr.kind.as!LiteralStringLikeExpr.isList)
				trackAllUsedInFun(res, from, res.program.commonFuns.newTList, FunUse.regular);
		} else if (a.expr.kind.isA!(MatchEnumExpr*))
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
		trackAllUsedInMatchVariantCase(res, from, case_);
}
void trackAllUsedInMatchVariantCase(ref AllUsedBuilder res, Uri from, in MatchVariantExpr.Case case_) {
	trackAllUsedInStruct(res, from, case_.member.decl);
}
