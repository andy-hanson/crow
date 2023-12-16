module frontend.check.inferringType;

@safe @nogc pure nothrow:

import frontend.check.exprCtx : addDiag2, ExprCtx, typeWithContainer;
import frontend.check.instantiate : InstantiateCtx, instantiateStructNeverDelay, TypeArgsArray, typeArgsArray;
import model.ast : ExprAst;
import model.diag : Diag, ExpectedForDiag;
import model.model :
	BogusExpr,
	CommonTypes,
	Expr,
	ExprKind,
	FunKind,
	LoopExpr,
	StructDecl,
	StructInst,
	Type,
	TypeParamIndex;
import util.cell : Cell, cellGet, cellSet;
import util.col.array : contains, exists, indexOf, map, MutSmallArray, newArray, only, only2, small, zip, zipEvery;
import util.col.arrayBuilder : add, ArrayBuilder, arrBuilderIsEmpty, arrBuilderTempAsArr, finish;
import util.col.enumMap : enumMapFindKey;
import util.col.mutMaxArr : push, tempAsArr;
import util.opt : has, force, MutOpt, none, noneMut, Opt, optOrDefault, some, someInout, someMut;
import util.union_ : UnionMutable;
import util.util : castNonScope_ref, unreachable;

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
	@safe @nogc pure nothrow:

	struct NonInferring {}
	mixin UnionMutable!(NonInferring, MutSmallArray!SingleInferringType) args;

	static TypeContext nonInferring() =>
		TypeContext(NonInferring());

	bool isInferring() scope const =>
		isA!(MutSmallArray!SingleInferringType);
}
static assert(TypeContext.sizeof == ulong.sizeof);

@trusted inout(InferringTypeArgs) asInferringTypeArgs(inout TypeContext a) =>
	a.isInferring
		? inout InferringTypeArgs(a.as!(MutSmallArray!SingleInferringType))
		: cast(inout) InferringTypeArgs.empty;

private inout(MutOpt!(SingleInferringType*)) tryGetInferring(inout TypeContext context, TypeParamIndex param) =>
	context.isInferring
		? someInout!(SingleInferringType*)(&context.as!(MutSmallArray!SingleInferringType)[param.index])
		: noneMut!(SingleInferringType*);

private Opt!Type tryGetInferred(const TypeContext a, TypeParamIndex param) {
	const MutOpt!(SingleInferringType*) sit = tryGetInferring(a, param);
	return has(sit) ? tryGetInferred(*force(sit)) : none!Type;
}

struct InferringTypeArgs {
	@safe @nogc pure nothrow:

	SingleInferringType[] args;

	static InferringTypeArgs empty() =>
		InferringTypeArgs([]);
}

struct LoopInfo {
	immutable Type voidType;
	immutable LoopExpr* loop;
	immutable Type type;
	bool hasBreak;
}

struct TypeAndContext {
	immutable Type type;
	TypeContext context;
}

TypeAndContext nonInferring(Type a) =>
	TypeAndContext(a, TypeContext.nonInferring);

struct Expected {
	immutable struct Infer {}
	// Type in the context of the function being checked
	immutable struct LocalType { Type type; }
	mixin UnionMutable!(Infer, LocalType, MutSmallArray!TypeAndContext, LoopInfo*);
}
// TODO: I could probably get this to just ulong.sizeof
static assert(Expected.sizeof == ulong.sizeof * 2);

private TypeAndContext localTypeAndContext(Expected.LocalType a) =>
	nonInferring(a.type);

MutOpt!(LoopInfo*) tryGetLoop(ref Expected expected) =>
	expected.isA!(LoopInfo*) ? someMut(expected.as!(LoopInfo*)) : noneMut!(LoopInfo*);

bool isPurelyInferring(in Expected expected) =>
	expected.isA!(Expected.Infer);

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
			ArrayBuilder!(immutable StructInst*) multiple; // for diag
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
				addDiag2(ctx, source, Diag(Diag.LiteralAmbiguous(ctx.typeContainer, finish(ctx.alloc, multiple))));
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
	setToType(expected, Expected.LocalType(Type(Type.Bogus())));
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
	Expected newExpected = Expected(small!TypeAndContext(castNonScope_ref(t)));
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
	ref ExprCtx ctx,
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
				Opt!Type t = choice.type.isA!TypeParamIndex
					? tryGetInferred(choice.context, choice.type.as!TypeParamIndex)
					: some(choice.type);
				if (!has(t))
					return OkSkipOrAbort!T.abort(Diag(Diag.LambdaCantInferParamType()));
				Opt!Diag abort = cb(TypeAndContext(force(t), choice.context)).match!(Opt!Diag)(
					(ref OkSkipOrAbort!T.Ok x) {
						if (has(cellGet(res)))
							return some(Diag(Diag.LambdaMultipleMatch(getExpectedForDiag(ctx, expected))));
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

// This will return a result if there are no references to inferring type parameters.
// (There may be references to the current function's type parameters.)
private Opt!Type tryGetNonInferringType(ref InstantiateCtx ctx, ref const Expected expected) =>
	expected.matchConst!(Opt!Type)(
		(Expected.Infer) =>
			none!Type,
		(Expected.LocalType x) =>
			some(x.type),
		(const TypeAndContext[] choices) =>
			choices.length == 1 ? tryGetNonInferringType(ctx, only(choices)) : none!Type,
		(const LoopInfo*) =>
			none!Type);

bool matchExpectedVsReturnTypeNoDiagnostic(
	ref InstantiateCtx ctx,
	ref const Expected expected,
	TypeAndContext candidateReturnType,
) =>
	expected.matchConst!bool(
		(Expected.Infer) =>
			true,
		(Expected.LocalType x) =>
			// We have a particular expected type, so infer its type args
			matchTypes(ctx, candidateReturnType, localTypeAndContext(x)),
		(const TypeAndContext[] choices) {
			if (choices.length == 1) {
				Opt!Type t = tryGetNonInferringType(ctx, expected);
				if (has(t))
					return matchTypes(ctx, candidateReturnType, nonInferring(force(t)));
			}
			// Don't infer any type args here; multiple candidates and multiple possible return types.
			return exists!(const TypeAndContext)(choices, (in TypeAndContext x) =>
				isTypeMatchPossible(x, candidateReturnType));
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
	if (setTypeNoDiagnostic(ctx.instantiateCtx, expected, Expected.LocalType(exprType)))
		return expr;
	else {
		addDiag2(ctx, expr.range, Diag(
			Diag.TypeConflict(getExpectedForDiag(ctx, expected), typeWithContainer(ctx, exprType))));
		return bogus(expected, source);
	}
}

ExpectedForDiag getExpectedForDiag(ref ExprCtx ctx, ref const Expected expected) =>
	expected.matchConst!ExpectedForDiag(
		(Expected.Infer) =>
			ExpectedForDiag(ExpectedForDiag.Infer()),
		(Expected.LocalType x) =>
			ExpectedForDiag(ExpectedForDiag.Choices(newArray!Type(ctx.alloc, [x.type]), ctx.typeContainer)),
		(const TypeAndContext[] choices) =>
			ExpectedForDiag(ExpectedForDiag.Choices(
				map(ctx.alloc, choices, (ref const TypeAndContext x) => applyInferred(ctx.instantiateCtx, x)),
				ctx.typeContainer)),
		(const LoopInfo*) =>
			ExpectedForDiag(ExpectedForDiag.Loop()));

void setExpectedIfNoInferred(ref Expected expected, in Type delegate() @safe @nogc pure nothrow getType) {
	expected.matchConst!void(
		(Expected.Infer) {
			setToType(expected, Expected.LocalType(getType()));
		},
		(Expected.LocalType) {},
		(const TypeAndContext[]) {},
		(const LoopInfo*) {});
}

// Note: this may infer type parameters
private bool setTypeNoDiagnostic(ref InstantiateCtx ctx, ref Expected expected, Expected.LocalType actual) =>
	expected.match!bool(
		(Expected.Infer) {
			setToType(expected, actual);
			return true;
		},
		(Expected.LocalType x) =>
			matchTypes(ctx, localTypeAndContext(x), localTypeAndContext(actual)),
		(TypeAndContext[] choices) {
			bool anyOk = false;
			foreach (ref TypeAndContext x; choices)
				if (matchTypes(ctx, x, localTypeAndContext(actual)))
					anyOk = true;
			if (anyOk) setToType(expected, actual);
			return anyOk;
		},
		(LoopInfo* loop) =>
			false);

Opt!Type tryGetNonInferringType(ref InstantiateCtx ctx, const TypeAndContext a) =>
	a.type.matchWithPointers!(Opt!Type)(
		(Type.Bogus) =>
			some(Type(Type.Bogus())),
		(TypeParamIndex x) {
			const MutOpt!(SingleInferringType*) ta = tryGetInferring(a.context, x);
			return has(ta) ? tryGetInferred(*force(ta)) : some(a.type);
		},
		(StructInst* i) {
			scope TypeArgsArray newTypeArgs = typeArgsArray();
			foreach (Type x; i.typeArgs) {
				Opt!Type t = tryGetNonInferringType(ctx, const TypeAndContext(x, a.context));
				if (has(t))
					push(newTypeArgs, force(t));
				else
					return none!Type;
			}
			return some(Type(instantiateStructNeverDelay(ctx, i.decl, tempAsArr(newTypeArgs))));
		});

private:

// For diagnostics. Applies types that have been inferred, otherwise uses Bogus.
// This is like 'tryGetNonInferringType' but returns a type with Boguses in it instead of `none`.
Type applyInferred(ref InstantiateCtx ctx, in TypeAndContext a) =>
	a.type.match!Type(
		(Type.Bogus) =>
			Type(Type.Bogus()),
		(TypeParamIndex x) {
			const MutOpt!(SingleInferringType*) ta = tryGetInferring(a.context, x);
			return optOrDefault!Type(
				has(ta) ? tryGetInferred(*force(ta)) : none!Type,
				() => Type(Type.Bogus()));
		},
		(ref StructInst i) @safe {
			scope TypeArgsArray newTypeArgs = typeArgsArray();
			foreach (Type x; i.typeArgs)
				push(newTypeArgs, applyInferred(ctx, const TypeAndContext(x, a.context)));
			return Type(instantiateStructNeverDelay(ctx, i.decl, tempAsArr(newTypeArgs)));
		});

/*
Tries to find a way for 'a' and 'b' to be the same type.
It can fill in type arguments for 'a'. But unknown types in 'b' it will assume compatibility.
Returns true if it succeeds.
*/
public bool matchTypes(ref InstantiateCtx ctx, TypeAndContext a, const TypeAndContext b) =>
	a.type.matchWithPointers!bool(
		(Type.Bogus) =>
			// TODO: make sure to infer type params in this case!
			true,
		(TypeParamIndex pa) =>
			matchTypes_TypeParam(ctx, pa, a.context, b),
		(StructInst* ai) =>
			b.type.matchWithPointers!bool(
				(Type.Bogus) =>
					true,
				(TypeParamIndex pb) =>
					matchTypes_TypeParamB(ctx, a, pb, b.context),
				(StructInst* bi) =>
					ai.decl == bi.decl &&
					zipEvery!(Type, Type)(ai.typeArgs, bi.typeArgs, (ref Type argA, ref Type argB) =>
						matchTypes(
							ctx, TypeAndContext(argA, a.context), const TypeAndContext(argB, b.context)))));

bool matchTypes_TypeParam(ref InstantiateCtx ctx, TypeParamIndex a, TypeContext aContext, const TypeAndContext b) {
	MutOpt!(SingleInferringType*) aInferring = tryGetInferring(aContext, a);
	if (has(aInferring)) {
		Opt!Type inferred = tryGetInferred(*force(aInferring));
		bool ok = !has(inferred) || matchTypes(ctx, TypeAndContext(force(inferred), TypeContext.nonInferring), b);
		if (ok) {
			Opt!Type bInferred = tryGetNonInferringType(ctx, b);
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
					return !has(inferred) ||
						(force(inferred).isA!TypeParamIndex && force(inferred).as!TypeParamIndex == a);
				} else
					return a == bp;
			},
			(ref StructInst) =>
				false);
}

bool matchTypes_TypeParamB(ref InstantiateCtx ctx, TypeAndContext a, TypeParamIndex b, in TypeContext bContext) {
	const MutOpt!(SingleInferringType*) bInferred = tryGetInferring(bContext, b);
	if (has(bInferred)) {
		Opt!Type inferred = tryGetInferred(*force(bInferred));
		return !has(inferred) || matchTypes(ctx, a, nonInferring(force(inferred)));
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
		StructDecl* structDecl = structInst.decl;
		Opt!FunKind kind = enumMapFindKey!(FunKind, StructDecl*)(commonTypes.funStructs, (in StructDecl* x) =>
			x == structDecl);
		if (has(kind)) {
			Type[2] typeArgs = only2(structInst.typeArgs);
			return some(FunType(force(kind), structInst, structDecl, typeArgs[0], typeArgs[1]));
		} else
			return none!FunType;
	} else
		return none!FunType;
}

public void inferTypeArgsFromLambdaParameterType(
	ref InstantiateCtx ctx,
	in CommonTypes commonTypes,
	Type a,
	scope InferringTypeArgs aInferringTypeArgs,
	Type lambdaParameterType,
) {
	Opt!FunType funType = getFunType(commonTypes, a);
	if (has(funType)) {
		Type paramType = force(funType).nonInstantiatedParamType;
		inferTypeArgsFrom(ctx, paramType, aInferringTypeArgs, nonInferring(lambdaParameterType));
	}
}

public void inferTypeArgsFrom(
	ref InstantiateCtx ctx,
	Type a,
	scope InferringTypeArgs aInferringTypeArgs,
	const TypeAndContext b,
) {
	if (isInferringNonInferredTypeParam(b))
		return;
	const TypeAndContext b2 = maybeInferred(b);
	a.matchWithPointers!void(
		(Type.Bogus) {},
		(TypeParamIndex ap) {
			SingleInferringType* aInferring = &aInferringTypeArgs.args[ap.index];
			if (!has(tryGetInferred(*aInferring))) {
				Opt!Type t = tryGetNonInferringType(ctx, b2);
				if (has(t))
					cellSet(aInferring.type, t);
			}
		},
		(StructInst* ai) {
			if (b2.type.isA!(StructInst*)) {
				const StructInst* bi = b2.type.as!(StructInst*);
				if (ai.decl == bi.decl)
					zip(ai.typeArgs, bi.typeArgs, (ref Type ta, ref Type tb) {
						inferTypeArgsFrom(ctx, ta, aInferringTypeArgs, const TypeAndContext(tb, b2.context));
					});
			}
		});
}

bool isTypeMatchPossible(in TypeAndContext a, in TypeAndContext b) {
	if (isInferringNonInferredTypeParam(a) || isInferringNonInferredTypeParam(b))
		return true;
	else {
		const TypeAndContext a2 = maybeInferred(a);
		const TypeAndContext b2 = maybeInferred(b);
		return (a2.type == b2.type && !a2.context.isInferring && !b2.context.isInferring) ||
			a2.type.isA!(Type.Bogus) ||
			b2.type.isA!(Type.Bogus) ||
			typesAreCorrespondingStructInsts(a2.type, b2.type, (ref Type x, ref Type y) =>
				isTypeMatchPossible(const TypeAndContext(x, a2.context), const TypeAndContext(y, b2.context)));
	}
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
const(TypeAndContext) maybeInferred(return scope const TypeAndContext a) {
	if (a.type.isA!TypeParamIndex) {
		const MutOpt!(SingleInferringType*) inferring = tryGetInferring(a.context, a.type.as!TypeParamIndex);
		if (has(inferring)) {
			// force because we tested 'isInferringNonInferredTypeParam' before
			Opt!Type t = tryGetInferred(*force(inferring));
			return nonInferring(force(t));
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
		return sa.decl == sb.decl && zipEvery!(Type, Type)(sa.typeArgs, sb.typeArgs, typesCorrespond);
	} else
		return false;
}
