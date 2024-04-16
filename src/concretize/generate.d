module concretize.generate;

@safe @nogc pure nothrow:

import concretize.allConstantsBuilder : getConstantArray;
import concretize.concretizeCtx :
	arrayElementType,
	char8ArrayType,
	char32ArrayType,
	ConcretizeCtx,
	constantOfBytes,
	constantSymbol,
	getConcreteFun,
	getConcreteType,
	getFunKey,
	nat64Type,
	stringType,
	symbolType,
	toContainingFunInfo,
	voidType;
import concretize.concretizeExpr : concretizeBogus, ConcretizeExprCtx, getConcreteFunFromCalled;
import model.concreteModel :
	ConcreteExpr,
	ConcreteExprKind,
	ConcreteField,
	ConcreteFun,
	ConcreteFunBody,
	ConcreteLocal,
	ConcreteLocalSource,
	ConcreteStruct,
	ConcreteStructBody,
	ConcreteStructSource,
	ConcreteType,
	mustBeByVal;
import model.constant : Constant, constantBool, constantZero;
import model.model : AutoFun, Called, EnumOrFlagsMember, FunKind, RecordField, StructBody, UnionMember;
import util.alloc.alloc : Alloc;
import util.col.array :
	allSame,
	map,
	mapWithIndex,
	mapZipWithIndex,
	newArray,
	newSmallArray,
	only,
	only2,
	sizeEq,
	sizeEq3,
	SmallArray;
import util.col.arrayBuilder : buildArray, Builder;
import util.conv : safeToUint;
import util.integralValues : IntegralValue, integralValuesRange;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : UriAndRange;
import util.string : bytesOfString;
import util.symbol : Symbol, symbol;
import util.unicode : mustUnicodeDecode;
import util.util : ptrTrustMe;

ConcreteExpr genCall(ref Alloc alloc, in UriAndRange range, ConcreteFun* called, in ConcreteExpr[] args) =>
	ConcreteExpr(called.returnType, range, ConcreteExprKind(ConcreteExprKind.Call(called, newSmallArray(alloc, args))));

ConcreteExpr genIf(ref Alloc alloc, UriAndRange range, ConcreteExpr cond, ConcreteExpr then, ConcreteExpr else_) =>
	ConcreteExpr(then.type, range, ConcreteExprKind(allocate(alloc, ConcreteExprKind.If(cond, then, else_))));

ConcreteExpr genSeq(ref Alloc alloc, UriAndRange range, ConcreteExpr a, ConcreteExpr b) =>
	ConcreteExpr(b.type, range, ConcreteExprKind(allocate(alloc, ConcreteExprKind.Seq(a, b))));

ConcreteExpr genSome(ref ConcretizeCtx ctx, in UriAndRange range, ConcreteType optionType, ConcreteExpr arg) {
	assertIsOptionType(ctx, optionType);
	return ConcreteExpr(optionType, range, ConcreteExprKind(allocate(ctx.alloc, ConcreteExprKind.CreateUnion(1, arg))));
}
ConcreteExpr genNone(ref ConcretizeCtx ctx, in UriAndRange range, ConcreteType optionType) {
	assertIsOptionType(ctx, optionType);
	return ConcreteExpr(optionType, range, ConcreteExprKind(allocate(ctx.alloc,
		ConcreteExprKind.CreateUnion(0, genVoid(ctx, range)))));
}
ConcreteType unwrapOptionType(in ConcretizeCtx ctx, ConcreteType optionType) {
	assertIsOptionType(ctx, optionType);
	return only(mustBeByVal(optionType).source.as!(ConcreteStructSource.Inst).typeArgs);
}
private void assertIsOptionType(in ConcretizeCtx ctx, ConcreteType optionType) {
	assert(mustBeByVal(optionType).source.as!(ConcreteStructSource.Inst).inst.decl == ctx.commonTypes.option);
}
ConcreteExpr genVoid(ref ConcretizeCtx ctx, in UriAndRange range) =>
	ConcreteExpr(voidType(ctx), range, ConcreteExprKind(constantZero));

ConcreteExpr genLocalGet(in UriAndRange range, ConcreteLocal* local) =>
	ConcreteExpr(local.type, range, ConcreteExprKind(ConcreteExprKind.LocalGet(local)));

ConcreteFunBody.RecordFieldCall getRecordFieldCall(
	ref ConcretizeCtx ctx,
	FunKind funKind,
	ConcreteType recordType,
	size_t fieldIndex,
) {
	ConcreteStruct* fieldType = mustBeByVal(
		recordType.struct_.body_.as!(ConcreteStructBody.Record).fields[fieldIndex].type);
	ConcreteType[] typeArgs = fieldType.source.as!(ConcreteStructSource.Inst).typeArgs;
	assert(typeArgs.length == 2);
	ConcreteFun* callFun = getConcreteFun(ctx, ctx.program.commonFuns.lambdaSubscript[funKind], typeArgs, []);
	return ConcreteFunBody.RecordFieldCall(fieldIndex, fieldType, typeArgs[1], callFun);
}

ConcreteExpr genUnionMemberGet(ref ConcretizeCtx ctx, ConcreteFun* cf, size_t memberIndex) {
	UriAndRange range = cf.range;
	ConcreteExpr* param = allocate(ctx.alloc, genParamGet(ctx.alloc, range, &only(cf.paramsIncludingClosure)));
	ConcreteType memberType = unwrapOptionType(ctx, cf.returnType);
	return genIf(
		ctx.alloc,
		range,
		genEqualNat64(ctx, range, genUnionKind(ctx, range, param), genConstantNat64(ctx, range, memberIndex)),
		genSome(ctx, range, cf.returnType, genUnionAs(memberType, range, param, memberIndex)),
		genNone(ctx, range, cf.returnType));
}

ConcreteFunBody bodyForEnumOrFlagsMembers(ref ConcretizeCtx ctx, ConcreteType returnType) {
	// First type arg is 'symbol'
	ConcreteType enumOrFlagsType =
		only2(mustBeByVal(arrayElementType(returnType)).source.as!(ConcreteStructSource.Inst).typeArgs)[1];
	Constant[] elements = map(ctx.alloc, enumOrFlagsMembers(enumOrFlagsType), (ref EnumOrFlagsMember member) =>
		Constant(Constant.Record(newSmallArray!Constant(ctx.alloc, [
			constantSymbol(ctx, member.name),
			Constant(IntegralValue(member.value.value))]))));
	Constant arr = getConstantArray(ctx.alloc, ctx.allConstants, mustBeByVal(returnType), elements);
	return ConcreteFunBody(ConcreteExpr(returnType, UriAndRange.empty, ConcreteExprKind(arr)));
}

private SmallArray!EnumOrFlagsMember enumOrFlagsMembers(ConcreteType type) {
	StructBody body_ = mustBeByVal(type).source.as!(ConcreteStructSource.Inst).inst.decl.body_;
	return body_.isA!(StructBody.Enum*) ? body_.as!(StructBody.Enum*).members : body_.as!(StructBody.Flags).members;
}

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

ConcreteExpr genThrow(ref Alloc alloc, ConcreteType type, UriAndRange range, ConcreteExpr thrown) =>
	ConcreteExpr(type, range, genThrowKind(alloc, thrown));

private ConcreteExprKind genThrowKind(ref Alloc alloc, ConcreteExpr thrown) =>
	ConcreteExprKind(allocate(alloc, ConcreteExprKind.Throw(thrown)));

ConcreteExpr genError(ref ConcretizeCtx ctx, UriAndRange range, string message) =>
	genCall(ctx.alloc, range, ctx.createErrorFunction, [genStringLiteral(ctx, range, message)]);

ConcreteExprKind genThrowStringKind(ref ConcretizeCtx ctx, UriAndRange range, string message) =>
	genThrowKind(ctx.alloc, genError(ctx, range, message));

ConcreteExpr genStringLiteral(ref ConcretizeCtx ctx, UriAndRange range, in string value) =>
	ConcreteExpr(stringType(ctx), range, genStringLiteralKind(ctx, range, value));

ConcreteExprKind genStringLiteralKind(ref ConcretizeCtx ctx, UriAndRange range, in string value) =>
	ConcreteExprKind(ConcreteExprKind.Call(ctx.char8ArrayTrustAsString, newSmallArray(ctx.alloc, [
		genChar8Array(ctx, range, value)])));

ConcreteExpr genChar8Array(ref ConcretizeCtx ctx, in UriAndRange range, in string value) {
	ConcreteType type = char8ArrayType(ctx);
	return ConcreteExpr(type, range, ConcreteExprKind(constantOfBytes(ctx, type, bytesOfString(value))));
}

ConcreteExpr genChar32Array(ref ConcretizeCtx ctx, in UriAndRange range, in string value) {
	ConcreteType type = char32ArrayType(ctx);
	return ConcreteExpr(type, range, ConcreteExprKind(char32ArrayConstant(ctx, type, value)));
}
private Constant char32ArrayConstant(ref ConcretizeCtx ctx, ConcreteType type, in string value) =>
	getConstantArray(
		ctx.alloc, ctx.allConstants, mustBeByVal(type),
		buildArray!Constant(ctx.alloc, (scope ref Builder!Constant out_) {
			mustUnicodeDecode(value, (dchar x) {
				out_ ~= Constant(IntegralValue(x));
			});
		}));

ConcreteExpr genChar8List(ref ConcretizeCtx ctx, ConcreteType type, in UriAndRange range, in string value) =>
	ConcreteExpr(type, range, ConcreteExprKind(
		ConcreteExprKind.Call(ctx.newChar8ListFunction, newSmallArray(ctx.alloc, [
			genChar8Array(ctx, range, value)]))));
ConcreteExpr genChar32List(ref ConcretizeCtx ctx, ConcreteType type, in UriAndRange range, in string value) =>
	ConcreteExpr(type, range, ConcreteExprKind(
		ConcreteExprKind.Call(ctx.newChar32ListFunction, newSmallArray(ctx.alloc, [
			genChar32Array(ctx, range, value)]))));

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
		() => genComparisonEqual(fun.returnType, fun.range),
		(ConcreteExpr x, ConcreteExpr y) => genCompareOr(ctx.alloc, fun.range, x, y));

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
		ConcreteExpr* p0 = allocate(ctx.alloc, genLocalGet(range, &params[0]));
		ConcreteExpr* p1 = allocate(ctx.alloc, genLocalGet(range, &params[1]));
		return foldRange(
			fields.length,
			(size_t index) =>
				concretizeAndCall(ctx, fun, fieldCalled[index], range, [
					genRecordFieldGet(fields[index].type, range, p0, index),
					genRecordFieldGet(fields[index].type, range, p1, index)]),
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
	SmallArray!ConcreteType members,
	in Called[] memberCompares,
) {
	assert(sizeEq(members, memberCompares));
	UriAndRange range = fun.range;
	if (members.length == 0)
		return genComparisonEqual(fun.returnType, range);
	else {
		ConcreteLocal[] params = fun.paramsIncludingClosure;
		assert(params.length == 2);
		ConcreteExpr* p0 = allocate(ctx.alloc, genParamGet(ctx.alloc, range, &params[0]));
		ConcreteExpr* p1 = allocate(ctx.alloc, genParamGet(ctx.alloc, range, &params[1]));
		ConcreteExpr p0Kind = genUnionKind(ctx, range, p0);
		ConcreteExpr p1Kind = genUnionKind(ctx, range, p1);
		// p0.kind < p1.kind ? less : p1.kind < p0.kind ? greater : p0.kind match ...
		return genIf(
			ctx.alloc,
			range,
			genCall(ctx.alloc, range, ctx.lessNat64Function, [p0Kind, p1Kind]),
			genComparisonLess(fun.returnType, range),
			genIf(
				ctx.alloc,
				range,
				genCall(ctx.alloc, range, ctx.lessNat64Function, [p1Kind, p0Kind]),
				genComparisonGreater(fun.returnType, range),
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
		(ConcreteExpr x, ConcreteExpr y) => genAnd(ctx, fun.range, x, y));

ConcreteExpr concretizeEqualUnion(
	ref ConcretizeCtx ctx,
	ConcreteFun* fun,
	SmallArray!ConcreteType members,
	in Called[] memberEquals,
) {
	UriAndRange range = fun.range;
	if (members.length == 0)
		return ConcreteExpr(fun.returnType, range, ConcreteExprKind(constantBool(true)));
	else {
		ConcreteLocal[] params = fun.paramsIncludingClosure;
		assert(params.length == 2);
		ConcreteExpr* p0 = allocate(ctx.alloc, genParamGet(ctx.alloc, range, &params[0]));
		ConcreteExpr* p1 = allocate(ctx.alloc, genParamGet(ctx.alloc, range, &params[1]));
		return genAnd(
			ctx, range,
			genEqualNat64(ctx, range, genUnionKind(ctx, range, p0), genUnionKind(ctx, range, p1)),
			matchUnionsSameKind(ctx, fun, range, p0, p1, members, memberEquals));
	}
}

ConcreteExpr genConstantNat64(ref ConcretizeCtx ctx, in UriAndRange range, ulong value) =>
	ConcreteExpr(nat64Type(ctx), range, ConcreteExprKind(Constant(IntegralValue(value))));

ConcreteExpr genEqualNat64(ref ConcretizeCtx ctx, in UriAndRange range, ConcreteExpr left, ConcreteExpr right) =>
	genCall(ctx.alloc, range, ctx.equalNat64Function, [left, right]);

// Caller should guarantee that unions have the same kind
ConcreteExpr matchUnionsSameKind(
	ref ConcretizeCtx ctx,
	ConcreteFun* containingFun,
	UriAndRange range,
	ConcreteExpr* p0,
	ConcreteExpr* p1,
	in SmallArray!ConcreteType members,
	in Called[] calleds,
) {
	assert(sizeEq(members, calleds));
	return genMatchUnion(
		ctx, containingFun.returnType, range, members, *p0,
		(size_t memberIndex, ConcreteExpr getMember) =>
			concretizeAndCall(
				ctx, containingFun, calleds[memberIndex], range, [
					getMember,
					genUnionAs(getMember.type, range, p1, safeToUint(memberIndex))]));
}

ConcreteExpr concretizeRecordToJson(
	ref ConcretizeCtx ctx,
	ConcreteFun* fun,
	in ConcreteField[] fields,
	in Called[] fieldToJson,
) {
	assert(sizeEq(fields, fieldToJson));
	UriAndRange range = fun.range;
	ConcreteExpr* getParam = allocate(ctx.alloc, genParamGet(ctx.alloc, range, &only(fun.paramsIncludingClosure)));
	return genNewJson(ctx, range, mapZipWithIndex!(ConcreteExpr, RecordField, Called)(
		ctx.alloc, recordFieldsForNames(only(fun.paramsIncludingClosure).type), fieldToJson,
		(size_t fieldIndex, ref RecordField field, ref Called called) =>
			genSymbolJsonTuple(ctx, range, field.name, concretizeAndCall(ctx, fun, called, range, [
				genRecordFieldGet(fields[fieldIndex].type, range, getParam, fieldIndex)]))));
}

ConcreteExpr concretizeUnionToJson(
	ref ConcretizeCtx ctx,
	ConcreteFun* fun,
	in SmallArray!ConcreteType memberTypes,
	in Called[] memberToJson,
) {
	UriAndRange range = fun.range;
	UnionMember[] members = unionMembersForNames(only(fun.paramsIncludingClosure).type);
	assert(sizeEq3(memberTypes, memberToJson, members));
	ConcreteExpr getParam = genParamGet(ctx.alloc, range, &only(fun.paramsIncludingClosure));
	return genNewJson(ctx, range, [
		genMatchUnion(
			ctx, symbolJsonTupleType(ctx), range, memberTypes, getParam,
			(size_t memberIndex, ConcreteExpr getMember) =>
				genSymbolJsonTuple(
					ctx, range, members[memberIndex].name,
					concretizeAndCall(ctx, fun, memberToJson[memberIndex], range, [getMember])))]);
}

ref StructBody body_(ConcreteType a) =>
	a.struct_.source.as!(ConcreteStructSource.Inst).inst.decl.body_;
// Discards concrete type info, so used only for names
RecordField[] recordFieldsForNames(ConcreteType a) =>
	body_(a).as!(StructBody.Record).fields;
UnionMember[] unionMembersForNames(ConcreteType a) =>
	body_(a).as!(StructBody.Union*).members;

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
		? genCall(ctx.alloc, range, force(fun), args)
		: concretizeBogus(ctx, getConcreteType(ctx, called.returnType, getFunKey(caller).typeArgs), range);
}

ConcreteExpr genMatchUnion(
	ref ConcretizeCtx ctx,
	ConcreteType returnType,
	UriAndRange range,
	in SmallArray!ConcreteType memberTypes,
	ConcreteExpr union_,
	in ConcreteExpr delegate(size_t, ConcreteExpr) @safe @nogc pure nothrow cb,
) =>
	ConcreteExpr(returnType, range, ConcreteExprKind(allocate(ctx.alloc, ConcreteExprKind.MatchUnion(
		union_,
		integralValuesRange(memberTypes.length),
		mapWithIndex!(ConcreteExprKind.MatchUnion.Case, ConcreteType)(
			ctx.alloc, memberTypes, (size_t memberIndex, ref ConcreteType memberType) {
				ConcreteLocal* local = allocate(ctx.alloc, ConcreteLocal(
					ConcreteLocalSource(ConcreteLocalSource.Generated(ConcreteLocalSource.Generated.member)),
					memberType));
				return ConcreteExprKind.MatchUnion.Case(some(local), cb(memberIndex, genLocalGet(range, local)));
			}),
		none!(ConcreteExpr*)))));

ConcreteExpr genNewJson(ref ConcretizeCtx ctx, UriAndRange range, in ConcreteExpr[] elements) =>
	genCallVariadic(ctx.alloc, range, ctx.newJsonFromPairsFunction, newArray(ctx.alloc, elements));

ConcreteType symbolJsonTupleType(ref ConcretizeCtx ctx) =>
	arrayElementType(only(ctx.newJsonFromPairsFunction.paramsIncludingClosure).type);

ConcreteExpr genSymbolJsonTuple(ref ConcretizeCtx ctx, UriAndRange range, Symbol symbol, ConcreteExpr value) =>
	genCreateRecord(ctx.alloc, symbolJsonTupleType(ctx), range, [constantSymbolExpr(ctx, range, symbol), value]);

ConcreteExpr genComparisonLess(ConcreteType comparisonType, UriAndRange range) =>
	ConcreteExpr(comparisonType, range, ConcreteExprKind(Constant(IntegralValue(0))));
ConcreteExpr genComparisonEqual(ConcreteType comparisonType, UriAndRange range) =>
	ConcreteExpr(comparisonType, range, ConcreteExprKind(Constant(IntegralValue(1))));
ConcreteExpr genComparisonGreater(ConcreteType comparisonType, UriAndRange range) =>
	ConcreteExpr(comparisonType, range, ConcreteExprKind(Constant(IntegralValue(2))));

ConcreteExpr genCompareOr(ref Alloc alloc, UriAndRange range, ConcreteExpr a, ConcreteExpr b) {
	ConcreteType comparison = a.type;
	return ConcreteExpr(comparison, range, ConcreteExprKind(allocate(alloc, ConcreteExprKind.MatchEnumOrIntegral(
		a,
		integralValuesRange(3),
		newArray(alloc, [
			ConcreteExpr(comparison, range, ConcreteExprKind(Constant(IntegralValue(0)))),
			b,
			ConcreteExpr(comparison, range, ConcreteExprKind(Constant(IntegralValue(2))))]),
		none!(ConcreteExpr*)))));
}

ConcreteExpr genCallVariadic(ref Alloc alloc, UriAndRange range, ConcreteFun* called, ConcreteExpr[] args) =>
	genCall(alloc, range, called, [genCreateArray(alloc, only(called.paramsIncludingClosure).type, range, args)]);

ConcreteExpr genCreateArray(ref Alloc alloc, ConcreteType arrayType, UriAndRange range, ConcreteExpr[] args) =>
	ConcreteExpr(arrayType, range, ConcreteExprKind(ConcreteExprKind.CreateArray(args)));

ConcreteExpr genCreateRecord(ref Alloc alloc, ConcreteType type, UriAndRange range, in ConcreteExpr[] args) =>
	ConcreteExpr(type, range, ConcreteExprKind(ConcreteExprKind.CreateRecord(newArray(alloc, args))));

ConcreteExpr constantSymbolExpr(ref ConcretizeCtx ctx, UriAndRange range, Symbol value) =>
	ConcreteExpr(symbolType(ctx), range, ConcreteExprKind(constantSymbol(ctx, value)));

ConcreteExpr genParamGet(ref Alloc alloc, UriAndRange range, ConcreteLocal* param) =>
	ConcreteExpr(param.type, range, ConcreteExprKind(ConcreteExprKind.LocalGet(param)));

ConcreteExpr genRecordFieldGet(ConcreteType fieldType, UriAndRange range, ConcreteExpr* arg, size_t fieldIndex) =>
	ConcreteExpr(fieldType, range, ConcreteExprKind(ConcreteExprKind.RecordFieldGet(arg, fieldIndex)));

public ConcreteExpr genUnionKind(ref ConcretizeCtx ctx, UriAndRange range, ConcreteExpr* arg) =>
	ConcreteExpr(nat64Type(ctx), range, ConcreteExprKind(ConcreteExprKind.UnionKind(arg)));

public ConcreteExpr genUnionAs(ConcreteType type, UriAndRange range, ConcreteExpr* arg, size_t memberIndex) =>
	ConcreteExpr(type, range, ConcreteExprKind(ConcreteExprKind.UnionAs(arg, safeToUint(memberIndex))));

ConcreteExpr genAnd(ref ConcretizeCtx ctx, UriAndRange range, ConcreteExpr a, ConcreteExpr b) =>
	genCall(ctx.alloc, range, ctx.andFunction, [a, b]);
