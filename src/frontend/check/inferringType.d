module frontend.check.inferringType;

@safe @nogc pure nothrow:

import frontend.check.exprCtx : addDiag2, ExprCtx, typeContext, typeWithContext;
import frontend.check.instantiate : InstantiateCtx, instantiateStructNeverDelay, TypeArgsArray, typeArgsArray;
import frontend.parse.ast : ExprAst;
import model.diag : Diag, ExpectedForDiag, TypeWithContext;
import model.model :
	BogusExpr,
	CommonTypes,
	decl,
	emptyTypeParams,
	Expr,
	ExprKind,
	FunKind,
	LoopExpr,
	range,
	StructDecl,
	StructInst,
	Type,
	typeArgs,
	TypeParam,
	TypeParamIndex,
	TypeParams;
import util.alloc.alloc : Alloc;
import util.cell : Cell, cellGet, cellSet;
import util.col.arr : only, only2;
import util.col.arrBuilder : add, ArrBuilder, arrBuilderIsEmpty, arrBuilderTempAsArr, finishArr;
import util.col.arrUtil : arrLiteral, contains, exists, indexOf, map, zip, zipEvery;
import util.col.enumMap : enumMapFindKey;
import util.col.mutMaxArr : push, tempAsArr;
import util.opt : has, force, MutOpt, none, noneMut, Opt, some, someConst, someMut;
import util.ptr : castNonScope, castNonScope_ref;
import util.union_ : UnionMutable;
import util.util : unreachable;

struct SingleInferringType {
	@safe @nogc pure nothrow:

	private Cell!(Opt!Type) type;

	this(Opt!Type t) {
		type = Cell!(Opt!Type)(t);
	}
}

Opt!Type tryGetInferred(ref const SingleInferringType a) =>
	cellGet(a.type);

struct TypeContext {
	//TODO: use SmallArray
	immutable TypeParams typeParams; // Type params of the function the type comes from, FOR DEBUG -----------------------------------
	// TODO: use empty array instead of option -------------------------------------------------------------------------
	MutOpt!(SingleInferringType[]) args; // This may be empty if we are not inferring anything
}
TypeContext emptyTypeContext() =>
	nonInferringTypeContext(emptyTypeParams);

TypeContext nonInferringTypeContext(return scope TypeParams typeParams) =>
	TypeContext(typeParams, noneMut!(SingleInferringType[]));
TypeContext withoutInferring(const TypeContext a) =>
	nonInferringTypeContext(a.typeParams);

const(MutOpt!(SingleInferringType*)) tryGetInferring(const TypeContext context, TypeParamIndex param) {
	context.typeParams.assertIndex(param);
	return has(context.args)
		? someConst!(SingleInferringType*)(&force(context.args)[param.index])
		: noneMut!(SingleInferringType*);
}
MutOpt!(SingleInferringType*) tryGetInferring(TypeContext ctx, TypeParamIndex param) {
	ctx.typeParams.assertIndex(param);
	return has(ctx.args)
		? someMut!(SingleInferringType*)(&force(ctx.args)[param.index])
		: noneMut!(SingleInferringType*);
}

@trusted inout(InferringTypeArgs) asInferringTypeArgs(inout TypeContext a) =>
	has(a.args) ? inout InferringTypeArgs(a.typeParams, force(a.args)) : cast(inout) InferringTypeArgs.empty;

struct InferringTypeArgs {
	@safe @nogc pure nothrow:

	immutable TypeParams params; // TODO: this will no longer be needed? -----------------------------------------------------
	SingleInferringType[] args;

	static InferringTypeArgs empty() =>
		InferringTypeArgs(emptyTypeParams, []);
}

// We can infer type args of 'a' but can't change inferred type args for 'b'
bool matchTypesNoDiagnostic(ref InstantiateCtx ctx, TypeParams outerContext, TypeAndContext expectedType, const TypeAndContext actualType) =>
	checkType(ctx, outerContext, expectedType, actualType);

struct LoopInfo {
	immutable Type voidType;
	immutable LoopExpr* loop;
	immutable Type type;
	bool hasBreak;
}

struct TypeAndContext {
	@safe @nogc pure nothrow:

	immutable Type type;
	TypeContext context;

	//TODO:KILL------------------------------------------------------------------------------------------------------------------------
	this(Type t, inout TypeContext c) inout {
		type = t;
		context = c;
		assertTypeContainsOnlyParams(t, c.typeParams);
	}
}

struct Expected {
	// Type in the context of the current function
	immutable struct LocalType {
		@safe @nogc pure nothrow:
		Type type;
		TypeParams typeParamsContext; // TODO: only for debugging ----------------------------------------------------------------------------------

		this(Type t, TypeParams tps) {
			type = t;
			typeParamsContext = tps;
			assertTypeContainsOnlyParams(type, typeParamsContext);
		}
	}
	immutable struct Infer {}
	mixin UnionMutable!(Infer, LocalType, TypeAndContext[], LoopInfo*);
}
// TODO: static assert(Expected.sizeof == ulong.sizeof + size_t.sizeof * 2); // TODO: could probably be ulong.sizeof * 1!

private TypeContext localTypeContext(Expected.LocalType a) =>
	nonInferringTypeContext(a.typeParamsContext);
private TypeAndContext localTypeAndContext(Expected.LocalType a) =>
	TypeAndContext(a.type, localTypeContext(a));

MutOpt!(LoopInfo*) tryGetLoop(ref Expected expected) =>
	expected.isA!(LoopInfo*) ? someMut(expected.as!(LoopInfo*)) : noneMut!(LoopInfo*);

@trusted Opt!Type tryGetInferred(ref const Expected expected) =>
	expected.matchConst!(Opt!Type)(
		(Expected.Infer) =>
			none!Type,
		(Expected.LocalType x) =>
			some(x.type),
		(const TypeAndContext[] ti) =>
			ti.length == 1 ? some(only(ti).type) : none!Type,
		(const LoopInfo*) =>
			none!Type);

/**
Returns an index into 'choices' if it is the only allowed choice.
If we are inferring a type, returns defaultChoice.
If there are multiple allowed choices, adds a diagnostic and returns none.
*/
Opt!size_t findExpectedStructForLiteral(
	ref ExprCtx ctx,
	ExprAst* source,
	ref const Expected expected,
	in immutable StructInst*[] choices,
	size_t defaultChoice,
) =>
	expected.matchConst!(Opt!size_t)(
		(Expected.Infer) =>
			some(defaultChoice),
		(Expected.LocalType x) {
			if (x.type.isA!(StructInst*)) {
				Opt!size_t res = indexOf(choices, x.type.as!(StructInst*));
				return has(res) ? res : some(defaultChoice);
			} else
				return some(defaultChoice);
		},
		(const TypeAndContext[] xs) {
			// This function will only be used with types like nat8 with no type arguments, so don't worry about those
			Cell!(Opt!size_t) rslt;
			ArrBuilder!(immutable StructInst*) multiple; // for diag
			foreach (ref const TypeAndContext x; xs)
				if (x.type.isA!(StructInst*)) {
					StructInst* struct_ = x.type.as!(StructInst*);
					Opt!size_t here = indexOf(choices, struct_);
					if (has(here)) {
						if (has(cellGet(rslt))) {
							StructInst* rsltStruct = choices[force(cellGet(rslt))];
							if (struct_ != rsltStruct) {
								if (arrBuilderIsEmpty(multiple))
									add(ctx.alloc, multiple, rsltStruct);
								if (!contains(arrBuilderTempAsArr(multiple), struct_))
									add(ctx.alloc, multiple, struct_);
							}
						} else
							cellSet(rslt, here);
					}
				}
			if (!arrBuilderIsEmpty(multiple)) {
				addDiag2(ctx, source, Diag(Diag.LiteralAmbiguous(typeContext(ctx), finishArr(ctx.alloc, multiple))));
				return none!size_t;
			} else
				return has(cellGet(rslt)) ? cellGet(rslt) : some(defaultChoice);
		},
		(const LoopInfo*) =>
			some(defaultChoice));

private @trusted void setToType(scope ref Expected expected, Expected.LocalType type) {
	expected = type;
}
private void setToBogus(scope ref Expected expected) {
	setToType(expected, Expected.LocalType(Type(Type.Bogus()), emptyTypeParams));
}

struct Pair(T, U) {
	T a;
	U b;
}
Pair!(T, Type) withCopyWithNewExpectedType(T)(
	ref Expected expected,
	Type newExpectedType,
	TypeContext newTypeContext,
	in T delegate(ref Expected) @safe @nogc pure nothrow cb,
) {
	TypeAndContext[1] t = [TypeAndContext(newExpectedType, newTypeContext)];
	Expected newExpected = Expected(castNonScope_ref(t));
	T res = cb(newExpected);
	return Pair!(T, Type)(castNonScope_ref(res), inferred(newExpected));
}

struct OkSkipOrAbort(T) {
	@safe @nogc pure nothrow:

	struct Ok { T value; }
	immutable struct Skip {}
	immutable struct Abort { Diag diag; }

	static OkSkipOrAbort ok(T value) =>
		OkSkipOrAbort(Ok(value));
	static OkSkipOrAbort skip() =>
		OkSkipOrAbort(Skip());
	static OkSkipOrAbort abort(Diag diag) =>
		OkSkipOrAbort(Abort(diag));

	mixin UnionMutable!(Ok, Skip, Abort);

	OkSkipOrAbort!Out mapOk(Out)(in Out delegate(T) @safe @nogc pure nothrow cb) =>
		match!(OkSkipOrAbort!Out)(
			(ref Ok x) =>
				OkSkipOrAbort!Out.ok(cb(x.value)),
			(Skip _) =>
				OkSkipOrAbort!Out.skip,
			(Abort x) =>
				OkSkipOrAbort!Out.abort(x.diag));
}

OkSkipOrAbort!T handleExpectedLambda(T)(
	ref Alloc allocForDiag,
	ref Expected expected,
	in OkSkipOrAbort!T delegate(TypeAndContext) @safe @nogc pure nothrow cb,
) =>
	expected.match!(OkSkipOrAbort!T)(
		(Expected.Infer) =>
			OkSkipOrAbort!T.skip,
		(Expected.LocalType x) =>
			cb(localTypeAndContext(x)),
		(TypeAndContext[] choices) {
			Cell!(MutOpt!T) res = Cell!(MutOpt!T)();
			foreach (TypeAndContext choice; choices) {
				Opt!Type t = () {
					if (choice.type.isA!TypeParamIndex) {
						MutOpt!(SingleInferringType*) typeArg = tryGetInferring(choice.context, choice.type.as!TypeParamIndex);
						return has(typeArg) ? tryGetInferred(*force(typeArg)) : none!Type;
					} else
						return some(choice.type);
				}();
				if (!has(t))
					return OkSkipOrAbort!T.abort(Diag(Diag.LambdaCantInferParamType()));
				Opt!Diag abort = cb(TypeAndContext(force(t), choice.context)).match!(Opt!Diag)(
					(ref OkSkipOrAbort!T.Ok x) {
						if (has(cellGet(res)))
							return some(Diag(Diag.LambdaMultipleMatch(getExpectedForDiag(allocForDiag, expected))));
						else {
							cellSet(res, someMut(x.value));
							return none!Diag;
						}
					},
					(OkSkipOrAbort!T.Skip) =>
						none!Diag,
					(OkSkipOrAbort!T.Abort x) =>
						some(x.diag));
				if (has(abort))
					return OkSkipOrAbort!T.abort(force(abort));
			}
			return has(cellGet(res)) ? OkSkipOrAbort!T.ok(force(cellGet(res))) : OkSkipOrAbort!T.skip;
		},
		(const LoopInfo*) => OkSkipOrAbort!T.skip);

private const(TypeContext) getTypeContext(ref const Expected expected) =>
	expected.matchConst!(const TypeContext)(
		(Expected.Infer) =>
			unreachable!(const TypeContext),
		(Expected.LocalType x) =>
			localTypeContext(x),
		(const TypeAndContext[] choices) =>
			only(choices).context,
		(const LoopInfo*) =>
			unreachable!(const TypeContext));

private Opt!Type tryGetDeeplyInstantiatedType(ref InstantiateCtx ctx, ref const Expected expected) {
	Opt!Type t = tryGetInferred(expected);
	return has(t)
		? tryGetDeeplyInstantiatedType(ctx, const TypeAndContext(force(t), getTypeContext(expected)))
		: none!Type;
}

bool matchExpectedVsReturnTypeNoDiagnostic(ref InstantiateCtx ctx, TypeParams outerContext, ref const Expected expected, TypeAndContext candidateReturnType) =>
	expected.matchConst!bool(
		(Expected.Infer) =>
			true,
		(Expected.LocalType x) =>
			// We have a particular expected type, so infer its type args
			matchTypesNoDiagnostic(ctx, outerContext, candidateReturnType, localTypeAndContext(x)),
		(const TypeAndContext[] choices) @safe {
			if (choices.length == 1) {
				Opt!Type t = tryGetDeeplyInstantiatedType(ctx, expected);
				if (has(t))
					return matchTypesNoDiagnostic(ctx, outerContext, candidateReturnType, TypeAndContext(force(t), nonInferringTypeContext(outerContext)));
			}
			// Don't infer any type args here; multiple candidates and multiple possible return types.
			return exists!(const TypeAndContext)(choices, (in TypeAndContext x) =>
				isTypeMatchPossible(outerContext, x, candidateReturnType));
		},
		(const LoopInfo*) =>
			false);

Expr bogus(ref Expected expected, ExprAst* ast) {
	expected.match!void(
		(Expected.Infer) {
			setToBogus(expected);
		},
		(Expected.LocalType) {},
		(TypeAndContext[]) {
			setToBogus(expected);
		},
		(LoopInfo*) {});
	return Expr(ast, ExprKind(BogusExpr()));
}

Type inferred(ref const Expected expected) =>
	expected.matchConst!Type(
		(Expected.Infer) =>
			unreachable!Type,
		(Expected.LocalType x) =>
			x.type,
		(const TypeAndContext[] choices) =>
			// If there were multiple, we should have set the expected.
			only(choices).type,
		(const LoopInfo* x) =>
			// Just treat loop body as 'void'
			x.voidType);

Expr check(ref ExprCtx ctx, ExprAst* source, ref Expected expected, Type exprType, Expr expr) {
	if (setTypeNoDiagnostic(ctx.instantiateCtx, ctx.outermostFunTypeParams, expected, Expected.LocalType(exprType, ctx.outermostFunTypeParams)))
		return expr;
	else {
		addDiag2(ctx, expr.range, Diag(Diag.TypeConflict(getExpectedForDiag(ctx.alloc, expected), typeWithContext(ctx, exprType))));
		return bogus(expected, source);
	}
}

ExpectedForDiag getExpectedForDiag(ref Alloc alloc, ref const Expected expected) =>
	expected.matchConst!ExpectedForDiag(
		(Expected.Infer) =>
			ExpectedForDiag(ExpectedForDiag.Infer()),
		(Expected.LocalType x) =>
			ExpectedForDiag(arrLiteral!TypeWithContext(alloc, [TypeWithContext(x.type, x.typeParamsContext)])),
		(const TypeAndContext[] xs) =>
			// TODO: this should instantiate types as much as possible to reflect inference up to this point
			ExpectedForDiag(map(alloc, xs, (scope ref const TypeAndContext x) =>
				TypeWithContext(x.type, x.context.typeParams))),
		(const LoopInfo*) =>
			ExpectedForDiag(ExpectedForDiag.Loop()));

void setExpectedIfNoInferred(ref Expected expected, in Type delegate() @safe @nogc pure nothrow getType) {
	expected.matchConst!void(
		(Expected.Infer) {
			setToType(expected, Expected.LocalType(getType(), emptyTypeParams));
		},
		(Expected.LocalType) {},
		(const TypeAndContext[]) {},
		(const LoopInfo*) {});
}

// Note: this may infer type parameters
private bool setTypeNoDiagnostic(ref InstantiateCtx ctx, TypeParams outerContext, ref Expected expected, Expected.LocalType actual) =>
	expected.match!bool(
		(Expected.Infer) {
			setToType(expected, actual);
			return true;
		},
		(Expected.LocalType x) =>
			checkType(ctx, outerContext, localTypeAndContext(x), localTypeAndContext(actual)),
		(TypeAndContext[] choices) {
			bool anyOk = false;
			foreach (ref TypeAndContext x; choices)
				if (checkType(ctx, outerContext, x, localTypeAndContext(actual)))
					anyOk = true;
			if (anyOk) setToType(expected, actual);
			return anyOk;
		},
		(LoopInfo* loop) =>
			false);

Opt!Type tryGetDeeplyInstantiatedType(ref InstantiateCtx ctx, const TypeAndContext a) =>
	a.type.matchWithPointers!(Opt!Type)(
		(Type.Bogus) =>
			some(Type(Type.Bogus())),
		(TypeParamIndex x) {
			const MutOpt!(SingleInferringType*) ta = tryGetInferring(a.context, x);
			return has(ta) ? tryGetInferred(*force(ta)) : some(a.type);
		},
		(StructInst* i) {
			scope TypeArgsArray newTypeArgs = typeArgsArray();
			foreach (Type x; typeArgs(*i)) {
				Opt!Type t = tryGetDeeplyInstantiatedType(ctx, const TypeAndContext(x, a.context));
				if (has(t))
					push(newTypeArgs, force(t));
				else
					return none!Type;
			}
			return some(Type(instantiateStructNeverDelay(ctx, decl(*i), tempAsArr(newTypeArgs))));
		});

private:

/*
Tries to find a way for 'a' and 'b' to be the same type.
It can fill in type arguments for 'a'. But unknown types in 'b' it will assume compatibility.
Returns true if it succeeds.
*/
bool checkType(ref InstantiateCtx ctx, TypeParams outerContext, TypeAndContext a, const TypeAndContext b) =>
	a.type.matchWithPointers!bool(
		(Type.Bogus) =>
			// TODO: make sure to infer type params in this case!
			true,
		(TypeParamIndex pa) =>
			checkType_TypeParam(ctx, outerContext, pa, a.context, b),
		(StructInst* ai) =>
			b.type.matchWithPointers!bool(
				(Type.Bogus) =>
					true,
				(TypeParamIndex pb) =>
					checkType_TypeParamB(ctx, outerContext, a, pb, b.context),
				(StructInst* bi) =>
					decl(*ai) == decl(*bi) &&
					zipEvery!(Type, Type)(typeArgs(*ai), typeArgs(*bi), (ref Type argA, ref Type argB) @safe =>
						checkType(ctx, outerContext, TypeAndContext(argA, a.context), const TypeAndContext(argB, b.context)))));

bool checkType_TypeParam(ref InstantiateCtx ctx, TypeParams outerContext, TypeParamIndex a, TypeContext aContext, const TypeAndContext b) {
	MutOpt!(SingleInferringType*) aInferring = tryGetInferring(aContext, a);
	if (has(aInferring)) {
		Opt!Type inferred = tryGetInferred(*force(aInferring));
		bool ok = !has(inferred) || checkType(ctx, outerContext, TypeAndContext(force(inferred), nonInferringTypeContext(outerContext)), b);
		if (ok) {
			Opt!Type bInferred = tryGetDeeplyInstantiatedType(ctx, b);
			if (has(bInferred))
				cellSet(force(aInferring).type, bInferred);
		}
		return ok;
	} else
		// It's an outer type param (not in either inferring).
		return b.type.match!bool(
			(Type.Bogus) =>
				true,
			(TypeParamIndex bp) {
				const MutOpt!(SingleInferringType*) bInferringB = tryGetInferring(b.context, bp);
				if (has(bInferringB)) {
					Opt!Type inferred = tryGetInferred(*force(bInferringB));
					return !has(inferred) || force(inferred).isA!TypeParamIndex && typeParamEqualSameContext(force(inferred).as!TypeParamIndex, a);
				} else
					return typeParamEqualSameContext(a, bp);
			},
			(ref StructInst) =>
				false);
}

bool checkType_TypeParamB(ref InstantiateCtx ctx, TypeParams outerContext, TypeAndContext a, TypeParamIndex b, in TypeContext bContext) {
	const MutOpt!(SingleInferringType*) bInferred = tryGetInferring(bContext, b);
	if (has(bInferred)) {
		Opt!Type inferred = tryGetInferred(*force(bInferred));
		return !has(inferred) || checkType(ctx, outerContext, a, TypeAndContext(force(inferred), nonInferringTypeContext(outerContext)));
	} else
		return false;
}

public immutable struct FunType {
	FunKind kind;
	StructInst* structInst;
	StructDecl* structDecl;
	Type nonInstantiatedNonFutReturnType;
	Type nonInstantiatedParamType;
}
public Opt!FunType getFunType(in CommonTypes commonTypes, Type a) {
	if (a.isA!(StructInst*)) {
		StructInst* structInst = a.as!(StructInst*);
		StructDecl* structDecl = decl(*structInst);
		Opt!FunKind kind = enumMapFindKey!(FunKind, StructDecl*)(commonTypes.funStructs, (in StructDecl* x) =>
			x == structDecl);
		if (has(kind)) {
			Type[2] typeArgs = only2(typeArgs(*structInst));
			return some(FunType(force(kind), structInst, structDecl, typeArgs[0], typeArgs[1]));
		} else
			return none!FunType;
	} else
		return none!FunType;
}

public void inferTypeArgsFromLambdaParameterType(
	ref InstantiateCtx ctx,
	in CommonTypes commonTypes,
	TypeParams outerContext,
	Type a,
	scope InferringTypeArgs aInferringTypeArgs,
	Type lambdaParameterType,
) {
	Opt!FunType funType = getFunType(commonTypes, a);
	if (has(funType)) {
		Type paramType = force(funType).nonInstantiatedParamType;
		inferTypeArgsFrom(ctx, outerContext, paramType, aInferringTypeArgs, TypeAndContext(lambdaParameterType, nonInferringTypeContext(outerContext)));
	}
}

public void inferTypeArgsFrom(
	ref InstantiateCtx ctx,
	TypeParams outerContext,
	Type a,
	scope InferringTypeArgs aInferringTypeArgs,
	const TypeAndContext b,
) {
	if (isInferringNonInferredTypeParam(b))
		return;
	const TypeAndContext b2 = maybeInferred(outerContext, b);
	a.matchWithPointers!void(
		(Type.Bogus) {},
		(TypeParamIndex ap) {
			aInferringTypeArgs.params.assertIndex(ap);
			SingleInferringType* aInferring = &aInferringTypeArgs.args[ap.index];
			if (!has(tryGetInferred(*aInferring))) {
				Opt!Type t = tryGetDeeplyInstantiatedType(ctx, b2);
				if (has(t))
					cellSet(aInferring.type, t);
			}
		},
		(StructInst* ai) {
			if (b2.type.isA!(StructInst*)) {
				const StructInst* bi = b2.type.as!(StructInst*);
				if (decl(*ai) == decl(*bi))
					zip(typeArgs(*ai), typeArgs(*bi), (ref Type ta, ref Type tb) {
						inferTypeArgsFrom(ctx, outerContext, ta, aInferringTypeArgs, const TypeAndContext(tb, b2.context));
					});
			}
		});
}

bool isTypeMatchPossible(in TypeParams outerContext, in TypeAndContext a, in TypeAndContext b) {
	if (isInferringNonInferredTypeParam(a) || isInferringNonInferredTypeParam(b))
		return true;
	const TypeAndContext a2 = maybeInferred(outerContext, a);
	const TypeAndContext b2 = maybeInferred(outerContext, b);
	if (a2.type == b2.type ||
		a2.type.isA!(Type.Bogus) ||
		b2.type.isA!(Type.Bogus)) {
		return true;
	} else
		return typesAreCorrespondingStructInsts(a2.type, b2.type, (ref Type x, ref Type y) =>
			isTypeMatchPossible(outerContext, const TypeAndContext(x, a2.context), const TypeAndContext(y, b2.context)));
}
// True for a type param with no inference yet
bool isInferringNonInferredTypeParam(in TypeAndContext a) {
	if (a.type.isA!TypeParamIndex) {
		const MutOpt!(SingleInferringType*) inferring = tryGetInferring(a.context, a.type.as!TypeParamIndex);
		if (has(inferring)) {
			Opt!Type t = tryGetInferred(*force(inferring));
			return !has(t);
		} else
			return false;
	} else
		return false;
}
const(TypeAndContext) maybeInferred(return in TypeParams outerContext, return scope const TypeAndContext a) {
	if (a.type.isA!TypeParamIndex) {
		const MutOpt!(SingleInferringType*) inferring = tryGetInferring(a.context, a.type.as!TypeParamIndex);
		if (has(inferring)) {
			Opt!Type t = tryGetInferred(*force(inferring));
			// force because we tested 'isInferringNonInferredTypeParam' before
			return TypeAndContext(force(t), nonInferringTypeContext(outerContext));
		} else
			return a;
	} else
		return a;
}

public bool typesAreCorrespondingStructInsts(
	in Type a,
	in Type b,
	in bool delegate(ref Type x, ref Type y) @safe @nogc pure nothrow typesCorrespond,
) {
	if (a.isA!(StructInst*) && b.isA!(StructInst*)) {
		StructInst* sa = a.as!(StructInst*);
		StructInst* sb = b.as!(StructInst*);
		if (decl(*sa) != decl(*sb))
			return false;
		return zipEvery!(Type, Type)(typeArgs(*sa), typeArgs(*sb), typesCorrespond);
	} else
		return false;
}

void assertTypeContainsOnlyParams(in Type a, in TypeParams typeParams) {
	a.matchIn!void(
		(in Type.Bogus _) {},
		(in TypeParamIndex x) {
			typeParams.assertIndex(x);
		},
		(in StructInst inst) {
			foreach (Type arg; typeArgs(inst))
				assertTypeContainsOnlyParams(arg, typeParams);
		});
}

bool typeParamEqualSameContext(TypeParamIndex a, TypeParamIndex b) {
	bool res = a.index == b.index;
	assert(res == (a.debugPtr == b.debugPtr));
	return res;
}
