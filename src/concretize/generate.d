module concretize.generate;

@safe @nogc pure nothrow:

import concretize.allConstantsBuilder : getConstantArray;
import concretize.concretizeCtx :
	arrayElementType,
	ConcretizeCtx,
	constantSymbol,
	getOrAddConcreteFunAndFillBody,
	getConcreteType,
	getFunKey,
	nat64Type,
	symbolType,
	toContainingFunInfo;
import concretize.concretizeExpr : concretizeBogus, ConcretizeExprCtx, getConcreteFunFromCalled;
import model.concreteModel :
	ConcreteExpr,
	ConcreteExprKind,
	ConcreteField,
	ConcreteFun,
	ConcreteFunBody,
	ConcreteFunKey,
	ConcreteLocal,
	ConcreteLocalSource,
	ConcreteStruct,
	ConcreteStructBody,
	ConcreteStructSource,
	ConcreteType,
	mustBeByVal;
import model.constant : Constant, constantBool;
import model.model : AutoFun, BuiltinType, Called, EnumOrFlagsMember, FunKind, RecordField, StructBody, UnionMember;
import util.alloc.alloc : Alloc;
import util.col.array :
	allSame,
	emptySmallArray,
	map,
	mapWithIndex,
	mapZipWithIndex,
	newArray,
	only,
	only2,
	sizeEq,
	sizeEq3,
	small,
	SmallArray;
import util.col.map : values;
import util.conv : safeToUint;
import util.memory : allocate;
import util.opt : force, has, Opt, some;
import util.sourceRange : UriAndRange;
import util.symbol : Symbol, symbol;
import util.util : ptrTrustMe;

ConcreteExpr makeLocalGet(in UriAndRange range, ConcreteLocal* local) =>
	ConcreteExpr(local.type, range, ConcreteExprKind(ConcreteExprKind.LocalGet(local)));

ConcreteFunBody.RecordFieldCall getRecordFieldCall(
	ref ConcretizeCtx ctx,
	FunKind funKind,
	ConcreteType recordType,
	size_t fieldIndex,
) {
	ConcreteStruct* fieldType = mustBeByVal(
		recordType.struct_.body_.as!(ConcreteStructBody.Record).fields[fieldIndex].type);
	ConcreteType[2] typeArgs = only2(fieldType.source.as!(ConcreteStructSource.Inst).typeArgs);
	ConcreteFun* callFun = getOrAddConcreteFunAndFillBody(ctx, ConcreteFunKey(
		ctx.program.commonFuns.lambdaSubscript[funKind],
		// TODO: don't always allocate, only on create
		small!ConcreteType(newArray!ConcreteType(ctx.alloc, typeArgs)),
		emptySmallArray!(immutable ConcreteFun*)));
	return ConcreteFunBody.RecordFieldCall(fieldIndex, fieldType, typeArgs[1], callFun);
}

ConcreteFunBody bodyForEnumOrFlagsMembers(ref ConcretizeCtx ctx, ConcreteType returnType) {
	// First type arg is 'symbol'
	ConcreteType enumOrFlagsType =
		only2(mustBeByVal(arrayElementType(returnType)).source.as!(ConcreteStructSource.Inst).typeArgs)[1];
	Constant[] elements = map(ctx.alloc, enumOrFlagsMembers(enumOrFlagsType), (ref EnumOrFlagsMember member) =>
		Constant(Constant.Record(newArray!Constant(ctx.alloc, [
			constantSymbol(ctx, member.name),
			Constant(Constant.Integral(member.value.value))]))));
	Constant arr = getConstantArray(ctx.alloc, ctx.allConstants, mustBeByVal(returnType), elements);
	return ConcreteFunBody(ConcreteExpr(returnType, UriAndRange.empty, ConcreteExprKind(arr)));
}

private SmallArray!EnumOrFlagsMember enumOrFlagsMembers(ConcreteType type) =>
	mustBeByVal(type).source.as!(ConcreteStructSource.Inst).inst.decl.body_.match!(SmallArray!EnumOrFlagsMember)(
		(StructBody.Bogus) =>
			assert(false),
		(BuiltinType _) =>
			assert(false),
		(StructBody.Enum x) =>
			x.members,
		(StructBody.Extern) =>
			assert(false),
		(StructBody.Flags x) =>
			x.members,
		(StructBody.Record) =>
			assert(false),
		(StructBody.Union) =>
			assert(false));

ConcreteExpr concretizeAutoFun(ref ConcretizeCtx ctx, ConcreteFun* fun, ref AutoFun a) {
	final switch (a.kind) {
		case AutoFun.Kind.compare:
			return handleRecordOrUnion(
				sameType(fun.paramsIncludingClosure),
				(ConcreteStructBody.Record x) =>
					concretizeCompareRecord(ctx, fun, x.fields, a.members),
				(ConcreteStructBody.Union x) =>
					concretizeCompareUnion(ctx, fun, x.members, a.members));
		case AutoFun.Kind.equals:
			return handleRecordOrUnion(
				sameType(fun.paramsIncludingClosure),
				(ConcreteStructBody.Record x) =>
					concretizeEqualRecord(ctx, fun, x.fields, a.members),
				(ConcreteStructBody.Union x) =>
					concretizeEqualUnion(ctx, fun, x.members, a.members));
		case AutoFun.Kind.toJson:
			return handleRecordOrUnion(
				only(fun.paramsIncludingClosure).type,
				(ConcreteStructBody.Record x) =>
					concretizeRecordToJson(ctx, fun, x.fields, a.members),
				(ConcreteStructBody.Union x) =>
					concretizeUnionToJson(ctx, fun, x.members, a.members));
	}
}

private:

ConcreteType sameType(ConcreteLocal[] params) {
	assert(allSame!(ConcreteType, ConcreteLocal)(params, (in ConcreteLocal x) => x.type));
	return params[0].type;
}

T handleRecordOrUnion(T)(
	in ConcreteType type,
	in T delegate(ConcreteStructBody.Record) @safe @nogc pure nothrow cbRecord,
	in T delegate(ConcreteStructBody.Union) @safe @nogc pure nothrow cbUnion,
) {
	ConcreteStruct* s = type.struct_;
	return s.body_.isA!(ConcreteStructBody.Record)
		? cbRecord(s.body_.as!(ConcreteStructBody.Record))
		: s.body_.isA!(ConcreteStructBody.Union)
		? cbUnion(s.body_.as!(ConcreteStructBody.Union))
		: assert(false);
}

ConcreteExpr concretizeCompareRecord(
	ref ConcretizeCtx ctx,
	ConcreteFun* fun,
	in ConcreteField[] fields,
	in Called[] fieldCompares,
) =>
	equalOrCompareRecord(
		ctx, fun, fields, fieldCompares,
		() => makeComparisonEqual(fun.returnType, fun.range),
		(ConcreteExpr x, ConcreteExpr y) => makeCompareOr(ctx.alloc, fun.range, x, y));

ConcreteExpr equalOrCompareRecord(
	ref ConcretizeCtx ctx,
	ConcreteFun* fun,
	in ConcreteField[] fields,
	in Called[] fieldCalled,
	in ConcreteExpr delegate() @safe @nogc pure nothrow cbNoFields,
	in ConcreteExpr delegate(ConcreteExpr, ConcreteExpr) @safe @nogc pure nothrow cbFold,
) {
	assert(sizeEq(fields, fieldCalled));
	if (fields.length == 0)
		return cbNoFields();
	else {
		UriAndRange range = fun.range;
		ConcreteLocal[] params = fun.paramsIncludingClosure;
		assert(params.length == 2);
		ConcreteExpr* p0 = allocate(ctx.alloc, makeLocalGet(range, &params[0]));
		ConcreteExpr* p1 = allocate(ctx.alloc, makeLocalGet(range, &params[1]));
		return foldRange(
			fields.length,
			(size_t index) =>
				concretizeAndCall(ctx, fun, fieldCalled[index], range, [
					makeRecordFieldGet(fields[index].type, range, p0, index),
					makeRecordFieldGet(fields[index].type, range, p1, index)]),
			cbFold);
	}
}

T foldRange(T)(
	size_t length,
	in T delegate(size_t) @safe @nogc pure nothrow cbGet,
	in T delegate(T, T) @safe @nogc pure nothrow cbCombine,
) {
	assert(length != 0);
	T recur(T acc, size_t i) =>
		i == length ? acc : cbCombine(acc, cbGet(i));
	return recur(cbGet(0), 1);
}

ConcreteExpr concretizeCompareUnion(
	ref ConcretizeCtx ctx,
	ConcreteFun* fun,
	ConcreteType[] members,
	in Called[] memberCompares,
) {
	assert(sizeEq(members, memberCompares));
	UriAndRange range = fun.range;
	if (members.length == 0)
		return makeComparisonEqual(fun.returnType, range);
	else {
		ConcreteLocal[] params = fun.paramsIncludingClosure;
		assert(params.length == 2);
		ConcreteExpr* p0 = allocate(ctx.alloc, makeParamGet(ctx.alloc, range, &params[0]));
		ConcreteExpr* p1 = allocate(ctx.alloc, makeParamGet(ctx.alloc, range, &params[1]));
		ConcreteExpr p0Kind = makeUnionKind(ctx, range, p0);
		ConcreteExpr p1Kind = makeUnionKind(ctx, range, p1);
		// p0.kind < p1.kind ? less : p1.kind < p0.kind ? greater : p0.kind match ...
		return makeIf(
			ctx.alloc,
			range,
			makeCall(ctx.alloc, ctx.lessNat64Function, range, [p0Kind, p1Kind]),
			makeComparisonLess(fun.returnType, range),
			makeIf(
				ctx.alloc,
				range,
				makeCall(ctx.alloc, ctx.lessNat64Function, range, [p1Kind, p0Kind]),
				makeComparisonGreater(fun.returnType, range),
				matchUnionsSameKind(ctx, fun, range, p0, p1, members, memberCompares)));
	}
}

ConcreteExpr concretizeEqualRecord(
	ref ConcretizeCtx ctx,
	ConcreteFun* fun,
	in ConcreteField[] fields,
	in Called[] fieldEquals,
) =>
	equalOrCompareRecord(
		ctx, fun, fields, fieldEquals,
		() => ConcreteExpr(fun.returnType, fun.range, ConcreteExprKind(constantBool(true))),
		(ConcreteExpr x, ConcreteExpr y) => makeAnd(ctx, fun.range, x, y));

ConcreteExpr concretizeEqualUnion(
	ref ConcretizeCtx ctx,
	ConcreteFun* fun,
	ConcreteType[] members,
	in Called[] memberEquals,
) {
	UriAndRange range = fun.range;
	if (members.length == 0)
		return ConcreteExpr(fun.returnType, range, ConcreteExprKind(constantBool(true)));
	else {
		ConcreteLocal[] params = fun.paramsIncludingClosure;
		assert(params.length == 2);
		ConcreteExpr* p0 = allocate(ctx.alloc, makeParamGet(ctx.alloc, range, &params[0]));
		ConcreteExpr* p1 = allocate(ctx.alloc, makeParamGet(ctx.alloc, range, &params[1]));
		return makeAnd(
			ctx, range,
			makeCall(ctx.alloc, ctx.equalNat64Function, range, [
				makeUnionKind(ctx, range, p0), makeUnionKind(ctx, range, p1)]),
			matchUnionsSameKind(ctx, fun, range, p0, p1, members, memberEquals));
	}
}

// Caller should guarantee that unions have the same kind
ConcreteExpr matchUnionsSameKind(
	ref ConcretizeCtx ctx,
	ConcreteFun* containingFun,
	UriAndRange range,
	ConcreteExpr* p0,
	ConcreteExpr* p1,
	in ConcreteType[] members,
	in Called[] calleds,
) {
	assert(sizeEq(members, calleds));
	return makeMatchUnion(
		ctx, containingFun.returnType, range, members, *p0,
		(size_t memberIndex, ConcreteExpr getMember) =>
			concretizeAndCall(
				ctx, containingFun, calleds[memberIndex], range, [
					getMember,
					makeUnionAs(getMember.type, range, p1, safeToUint(memberIndex))]));
}

ConcreteExpr concretizeRecordToJson(
	ref ConcretizeCtx ctx,
	ConcreteFun* fun,
	in ConcreteField[] fields,
	in Called[] fieldToJson,
) {
	assert(sizeEq(fields, fieldToJson));
	UriAndRange range = fun.range;
	ConcreteExpr* getParam = allocate(ctx.alloc, makeParamGet(ctx.alloc, range, &only(fun.paramsIncludingClosure)));
	return makeNewJson(ctx, range, mapZipWithIndex!(ConcreteExpr, RecordField, Called)(
		ctx.alloc, recordFieldsForNames(only(fun.paramsIncludingClosure).type), fieldToJson,
		(size_t fieldIndex, ref RecordField field, ref Called called) =>
			makeSymbolJsonTuple(ctx, range, field.name, concretizeAndCall(ctx, fun, called, range, [
				makeRecordFieldGet(fields[fieldIndex].type, range, getParam, fieldIndex)]))));
}

ConcreteExpr concretizeUnionToJson(
	ref ConcretizeCtx ctx,
	ConcreteFun* fun,
	in ConcreteType[] memberTypes,
	in Called[] memberToJson,
) {
	UriAndRange range = fun.range;
	UnionMember[] members = unionMembersForNames(only(fun.paramsIncludingClosure).type);
	assert(sizeEq3(memberTypes, memberToJson, members));
	ConcreteExpr getParam = makeParamGet(ctx.alloc, range, &only(fun.paramsIncludingClosure));
	return makeNewJson(ctx, range, [
		makeMatchUnion(
			ctx, symbolJsonTupleType(ctx), range, memberTypes, getParam,
			(size_t memberIndex, ConcreteExpr getMember) =>
				makeSymbolJsonTuple(
					ctx, range, members[memberIndex].name,
					concretizeAndCall(ctx, fun, memberToJson[memberIndex], range, [getMember])))]);
}

ref StructBody body_(ConcreteType a) =>
	a.struct_.source.as!(ConcreteStructSource.Inst).inst.decl.body_;
// Discards concrete type info, so used only for names
RecordField[] recordFieldsForNames(ConcreteType a) =>
	body_(a).as!(StructBody.Record).fields;
UnionMember[] unionMembersForNames(ConcreteType a) =>
	body_(a).as!(StructBody.Union).members;

ConcreteExpr concretizeAndCall(
	ref ConcretizeCtx ctx,
	ConcreteFun* caller,
	Called called,
	UriAndRange range,
	in ConcreteExpr[] args,
) {
	ConcretizeExprCtx exprCtx = ConcretizeExprCtx(
		ptrTrustMe(ctx),
		caller.moduleUri,
		toContainingFunInfo(getFunKey(caller)),
		caller);
	Opt!(ConcreteFun*) fun = getConcreteFunFromCalled(exprCtx, called);
	return has(fun)
		? makeCall(ctx.alloc, force(fun), range, args)
		: concretizeBogus(ctx, getConcreteType(ctx, called.returnType, getFunKey(caller).typeArgs), range);
}

ConcreteExpr makeMatchUnion(
	ref ConcretizeCtx ctx,
	ConcreteType returnType,
	UriAndRange range,
	in ConcreteType[] memberTypes,
	ConcreteExpr union_,
	in ConcreteExpr delegate(size_t, ConcreteExpr) @safe @nogc pure nothrow cb,
) =>
	ConcreteExpr(returnType, range, ConcreteExprKind(allocate(ctx.alloc, ConcreteExprKind.MatchUnion(
		union_,
		mapWithIndex!(ConcreteExprKind.MatchUnion.Case, ConcreteType)(
			ctx.alloc, memberTypes, (size_t index, ref ConcreteType memberType) {
				ConcreteLocal* local = allocate(ctx.alloc, ConcreteLocal(
					ConcreteLocalSource(ConcreteLocalSource.Generated(ConcreteLocalSource.Generated.member)),
					memberType));
				return ConcreteExprKind.MatchUnion.Case(some(local), cb(index, makeLocalGet(range, local)));
			})))));

ConcreteExpr makeNewJson(ref ConcretizeCtx ctx, UriAndRange range, in ConcreteExpr[] elements) =>
	makeCallVariadic(ctx.alloc, ctx.newJsonFromPairsFunction, range, newArray(ctx.alloc, elements));

ConcreteType symbolJsonTupleType(ref ConcretizeCtx ctx) =>
	arrayElementType(only(ctx.newJsonFromPairsFunction.paramsIncludingClosure).type);

ConcreteExpr makeSymbolJsonTuple(ref ConcretizeCtx ctx, UriAndRange range, Symbol symbol, ConcreteExpr value) =>
	makeCreateRecord(ctx.alloc, symbolJsonTupleType(ctx), range, [constantSymbolExpr(ctx, range, symbol), value]);

ConcreteExpr makeIf(ref Alloc alloc, UriAndRange range, ConcreteExpr cond, ConcreteExpr then, ConcreteExpr else_) =>
	ConcreteExpr(then.type, range, ConcreteExprKind(allocate(alloc, ConcreteExprKind.If(cond, then, else_))));

ConcreteExpr makeComparisonLess(ConcreteType comparisonType, UriAndRange range) =>
	ConcreteExpr(comparisonType, range, ConcreteExprKind(Constant(Constant.Integral(0))));
ConcreteExpr makeComparisonEqual(ConcreteType comparisonType, UriAndRange range) =>
	ConcreteExpr(comparisonType, range, ConcreteExprKind(Constant(Constant.Integral(1))));
ConcreteExpr makeComparisonGreater(ConcreteType comparisonType, UriAndRange range) =>
	ConcreteExpr(comparisonType, range, ConcreteExprKind(Constant(Constant.Integral(2))));

ConcreteExpr makeCompareOr(ref Alloc alloc, UriAndRange range, ConcreteExpr a, ConcreteExpr b) {
	ConcreteType comparison = a.type;
	assert(mustBeByVal(comparison).body_.as!(ConcreteStructBody.Enum).values.as!size_t == 3);
	return ConcreteExpr(comparison, range, ConcreteExprKind(allocate(alloc,
		ConcreteExprKind.MatchEnum(a, newArray(alloc, [
			ConcreteExpr(comparison, range, ConcreteExprKind(Constant(Constant.Integral(0)))),
			b,
			ConcreteExpr(comparison, range, ConcreteExprKind(Constant(Constant.Integral(2))))])))));
}

ConcreteExpr makeCallVariadic(ref Alloc alloc, ConcreteFun* called, UriAndRange range, ConcreteExpr[] args) =>
	makeCall(alloc, called, range, [makeCreateArray(alloc, only(called.paramsIncludingClosure).type, range, args)]);

ConcreteExpr makeCreateArray(ref Alloc alloc, ConcreteType arrayType, UriAndRange range, ConcreteExpr[] args) =>
	ConcreteExpr(arrayType, range, ConcreteExprKind(ConcreteExprKind.CreateArray(args)));

ConcreteExpr makeCreateRecord(ref Alloc alloc, ConcreteType type, UriAndRange range, in ConcreteExpr[] args) =>
	ConcreteExpr(type, range, ConcreteExprKind(ConcreteExprKind.CreateRecord(newArray(alloc, args))));

ConcreteExpr constantSymbolExpr(ref ConcretizeCtx ctx, UriAndRange range, Symbol value) =>
	ConcreteExpr(symbolType(ctx), range, ConcreteExprKind(constantSymbol(ctx, value)));

ConcreteExpr makeParamGet(ref Alloc alloc, UriAndRange range, ConcreteLocal* param) =>
	ConcreteExpr(param.type, range, ConcreteExprKind(ConcreteExprKind.LocalGet(param)));

ConcreteExpr makeRecordFieldGet(ConcreteType fieldType, UriAndRange range, ConcreteExpr* arg, size_t fieldIndex) =>
	ConcreteExpr(fieldType, range, ConcreteExprKind(ConcreteExprKind.RecordFieldGet(arg, fieldIndex)));

ConcreteExpr makeUnionKind(ref ConcretizeCtx ctx, UriAndRange range, ConcreteExpr* arg) =>
	ConcreteExpr(nat64Type(ctx), range, ConcreteExprKind(ConcreteExprKind.UnionKind(arg)));

ConcreteExpr makeUnionAs(ConcreteType type, UriAndRange range, ConcreteExpr* arg, size_t memberIndex) =>
	ConcreteExpr(type, range, ConcreteExprKind(ConcreteExprKind.UnionAs(arg, safeToUint(memberIndex))));

ConcreteExpr makeCall(ref Alloc alloc, ConcreteFun* fun, UriAndRange range, in ConcreteExpr[] args) =>
	ConcreteExpr(fun.returnType, range, ConcreteExprKind(ConcreteExprKind.Call(fun, newArray(alloc, args))));

ConcreteExpr makeAnd(ref ConcretizeCtx ctx, UriAndRange range, ConcreteExpr a, ConcreteExpr b) =>
	makeCall(ctx.alloc, ctx.andFunction, range, [a, b]);
