module lower.generateCompareFun;

@safe @nogc pure nothrow:

import lower.lower : CompareFuns, getCompareFun;
import lower.lowExprHelpers :
	boolType,
	decrNat64,
	genBinary,
	genCall,
	genCreateRecord,
	genCreateUnion,
	genDeref,
	genIf,
	genNat64Eq0,
	incrPointer,
	localRef,
	paramRef,
	recordFieldGet;
import model.lowModel :
	AllLowTypes,
	asNonFunPtrType,
	asRecordType,
	LowExpr,
	LowExprKind,
	LowField,
	LowFun,
	LowFunBody,
	LowFunExprBody,
	LowFunIndex,
	LowFunParamsKind,
	LowFunSig,
	LowFunSource,
	LowLocal,
	LowLocalSource,
	LowParam,
	LowParamIndex,
	LowParamSource,
	LowRecord,
	LowType,
	LowUnion,
	matchLowType,
	name,
	PrimitiveType;
import util.bools : Bool, False, True;
import util.collection.arr : Arr, at, empty, ptrAt, size;
import util.collection.arrUtil : arrLiteral, fillArr, mapWithIndex, rtail;
import util.collection.fullIndexDict : fullIndexDictGet;
import util.memory : allocate, nu;
import util.opt : none, some;
import util.ptr : Ptr;
import util.sourceRange : FileAndRange;
import util.sym : shortSymAlphaLiteral, Sym, symEq;
import util.types : safeSizeTToU8, u8;
import util.util : unreachable, verify;

immutable(LowFun) generateCompareFun(Alloc)(
	ref Alloc alloc,
	ref immutable AllLowTypes allTypes,
	ref immutable ComparisonTypes comparisonTypes,
	ref const CompareFuns compareFuns,
	ref immutable LowType paramType,
	immutable Bool typeIsArr,
) {
	immutable FileAndRange range = FileAndRange.empty;
	immutable Arr!LowParam params = arrLiteral!LowParam(alloc, [
		immutable LowParam(
			immutable LowParamSource(immutable LowParamSource.Generated(shortSymAlphaLiteral("a"))),
			paramType),
		immutable LowParam(
			immutable LowParamSource(immutable LowParamSource.Generated(shortSymAlphaLiteral("b"))),
			paramType)]);
	immutable LowExpr a = paramRef(range, paramType, immutable LowParamIndex(0));
	immutable LowExpr b = paramRef(range, paramType, immutable LowParamIndex(1));
	immutable LowFunExprBody body_ = typeIsArr
		? arrCompareBody(alloc, range, allTypes, comparisonTypes, compareFuns, paramType, a, b)
		: compareBody(alloc, range, allTypes, comparisonTypes, compareFuns, paramType, a, b);
	return immutable LowFun(
		immutable LowFunSource(nu!(LowFunSource.Generated)(
			alloc,
			shortSymAlphaLiteral("compare"),
			arrLiteral!LowType(alloc, [paramType]))),
		nu!LowFunSig(
			alloc,
			immutable LowType(comparisonTypes.comparison),
			immutable LowFunParamsKind(False, False),
			params),
		immutable LowFunBody(body_));
}

struct ComparisonTypes {
	immutable LowType.Union comparison;
	immutable LowType.Record less;
	immutable LowType.Record equal;
	immutable LowType.Record greater;
}

private:

immutable(LowFunExprBody) arrCompareBody(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable AllLowTypes allTypes,
	ref immutable ComparisonTypes comparisonTypes,
	ref const CompareFuns compareFuns,
	ref immutable LowType arrType,
	ref immutable LowExpr a,
	ref immutable LowExpr b,
) {
	immutable LowType.Record arrRecordType = asRecordType(arrType);
	immutable LowRecord arrRecord = fullIndexDictGet(allTypes.allRecords, arrRecordType);
	verify(size(arrRecord.fields) == 2);
	verify(symEq(name(at(arrRecord.fields, 0)), shortSymAlphaLiteral("size")));
	verify(symEq(name(at(arrRecord.fields, 1)), shortSymAlphaLiteral("data")));
	immutable LowType sizeType = at(arrRecord.fields, 0).type;
	immutable LowType elementPtrType = at(arrRecord.fields, 1).type;
	immutable LowType elementType = asNonFunPtrType(elementPtrType).pointee;

	immutable(LowExpr) genGetSize(ref immutable LowExpr arr) {
		return recordFieldGet!Alloc(alloc, range, arr, sizeType, 0);
	}
	immutable(LowExpr) genGetData(ref immutable LowExpr arr) {
		return recordFieldGet(alloc, range, arr, elementPtrType, 1);
	}
	immutable(LowExpr) genTail(ref immutable LowExpr arr) {
		immutable LowExpr curSize = genGetSize(arr);
		immutable LowExpr curData = genGetData(arr);
		immutable LowExpr newSize = decrNat64(alloc, range, curSize);
		immutable LowExpr newData = incrPointer(alloc, range, elementPtrType, curData);
		return genCreateRecord(range, arrRecordType, arrLiteral!LowExpr(alloc, [newSize, newData]));
	}
	immutable(LowExpr) genFirst(ref immutable LowExpr arr) {
		return genDeref(alloc, range, genGetData(arr));
	}

	immutable LowExpr compareFirst = genCompareExpr(
		alloc,
		range,
		compareFuns,
		comparisonTypes,
		elementType,
		genFirst(a),
		genFirst(b));
	immutable LowExpr recurOnTail = immutable LowExpr(
		immutable LowType(comparisonTypes.comparison),
		range,
		immutable LowExprKind(immutable LowExprKind.TailRecur(arrLiteral!LowExpr(alloc, [genTail(a), genTail(b)]))));
	immutable LowExpr firstThenRecur = combineCompares(
		alloc,
		range,
		comparisonTypes,
		0,
		compareFirst,
		recurOnTail);

	immutable(LowExpr) genSizeEq0(ref immutable LowExpr arr) {
		return genNat64Eq0(alloc, range, genGetSize(arr));
	}

	immutable LowExpr bSizeIsZero = genSizeEq0(b);
	immutable LowExpr expr = genIf(
		alloc,
		range,
		genSizeEq0(a),
		genIf(
			alloc,
			range,
			bSizeIsZero,
			genComparisonEqual(alloc, range, comparisonTypes),
			genComparisonLess(alloc, range, comparisonTypes)),
		genIf(
			alloc,
			range,
			bSizeIsZero,
			genComparisonGreater(alloc, range, comparisonTypes),
			firstThenRecur));
	return immutable LowFunExprBody(True, allocate(alloc, expr));
}

immutable(LowExpr) combineCompares(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable ComparisonTypes comparisonTypes,
	immutable u8 tempIndex,
	immutable LowExpr compareFirst,
	immutable LowExpr compareSecond,
) {
	immutable Arr!(LowExprKind.Match.Case) cases = arrLiteral!(LowExprKind.Match.Case)(alloc, [
		immutable LowExprKind.Match.Case(none!(Ptr!LowLocal), genComparisonLess(alloc, range, comparisonTypes)),
		immutable LowExprKind.Match.Case(none!(Ptr!LowLocal), compareSecond),
		immutable LowExprKind.Match.Case(none!(Ptr!LowLocal), genComparisonGreater(alloc, range, comparisonTypes))]);
	immutable Ptr!LowLocal matchedLocal = addLocal(
		alloc,
		shortSymAlphaLiteral("temp"),
		tempIndex,
		immutable LowType(comparisonTypes.comparison));
	return immutable LowExpr(
		immutable LowType(comparisonTypes.comparison),
		range,
		immutable LowExprKind(nu!(LowExprKind.Match)(alloc, matchedLocal, allocate(alloc, compareFirst), cases)));
}

immutable(Ptr!LowLocal) addLocal(Alloc)(
	ref Alloc alloc,
	immutable Sym name,
	immutable u8 index,
	immutable LowType type,
) {
	return nu!LowLocal(
		alloc,
		immutable LowLocalSource(immutable LowLocalSource.Generated(name, index)),
		type);
}

immutable(LowExpr) genCompareExpr(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref const CompareFuns compareFuns,
	ref immutable ComparisonTypes comparisonTypes,
	ref immutable LowType type,
	immutable LowExpr a,
	immutable LowExpr b,
) {
	immutable LowFunIndex called = getCompareFun(compareFuns, type);
	return genCall(
		alloc,
		range,
		called,
		immutable LowType(comparisonTypes.comparison),
		arrLiteral!LowExpr(alloc, [a, b]));
}

immutable(LowExpr) genComparisonLess(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable ComparisonTypes comparisonTypes,
) {
	return genCreateUnion(alloc, range, comparisonTypes.comparison, 0, genCreateRecord(range, comparisonTypes.less));
}

immutable(LowExpr) genComparisonEqual(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable ComparisonTypes comparisonTypes,
) {
	return genCreateUnion(alloc, range, comparisonTypes.comparison, 1, genCreateRecord(range, comparisonTypes.equal));
}

immutable(LowExpr) genComparisonGreater(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable ComparisonTypes comparisonTypes,
) {
	return genCreateUnion(alloc, range, comparisonTypes.comparison, 2, genCreateRecord(range, comparisonTypes.greater));
}

immutable(LowFunExprBody) compareBody(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable AllLowTypes allTypes,
	ref immutable ComparisonTypes comparisonTypes,
	ref const CompareFuns compareFuns,
	ref immutable LowType paramType,
	ref immutable LowExpr a,
	ref immutable LowExpr b,
) {
	immutable(LowFunExprBody) record(immutable LowType.Record recordType) {
		return genCompareRecord(
			alloc,
			range,
			comparisonTypes,
			compareFuns,
			fullIndexDictGet(allTypes.allRecords, recordType).fields,
			a,
			b);
	}

	return matchLowType!(immutable LowFunExprBody)(
		paramType,
		(immutable LowType.ExternPtr) =>
			unreachable!(immutable LowFunExprBody),
		(immutable LowType.FunPtr) =>
			unreachable!(immutable LowFunExprBody),
		(immutable LowType.NonFunPtr it) =>
			record(asRecordType(it.pointee)),
		(immutable PrimitiveType it) =>
			immutable LowFunExprBody(
				False,
				allocate(alloc, genComparePrimitive(alloc, range, comparisonTypes, it, a, b))),
		(immutable LowType.Record it) =>
			record(it),
		(immutable LowType.Union it) =>
			genCompareUnion(
				alloc,
				range,
				comparisonTypes,
				compareFuns,
				fullIndexDictGet(allTypes.allUnions, it),
				a,
				b));
}

immutable(LowFunExprBody) genCompareUnion(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable ComparisonTypes comparisonTypes,
	ref const CompareFuns compareFuns,
	immutable LowUnion union_,
	ref immutable LowExpr a,
	ref immutable LowExpr b,
) {
	immutable Ptr!LowLocal aMatchedLocal = addLocal(alloc, shortSymAlphaLiteral("match-a"), 0, a.type);
	immutable Arr!(LowExprKind.Match.Case) aCases =
		mapWithIndex(alloc, union_.members, (immutable size_t aIndex, ref immutable LowType aType) {
			immutable Ptr!LowLocal aLocal = addLocal(
				alloc,
				shortSymAlphaLiteral("a"),
				safeSizeTToU8(aIndex),
				aType);
			immutable LowExpr getALocal = localRef(alloc, range, aLocal);
			immutable Arr!(LowExprKind.Match.Case) bCases =
				fillArr(alloc, size(union_.members), (immutable size_t bIndex) {
					if (aIndex < bIndex)
						return immutable LowExprKind.Match.Case(
							none!(Ptr!LowLocal),
							genComparisonLess(alloc, range, comparisonTypes));
					else if (aIndex > bIndex)
						return immutable LowExprKind.Match.Case(
							none!(Ptr!LowLocal),
							genComparisonGreater(alloc, range, comparisonTypes));
					else {
						immutable Ptr!LowLocal bLocal =
							addLocal(alloc, shortSymAlphaLiteral("b"), safeSizeTToU8(bIndex), aType);
						return immutable LowExprKind.Match.Case(
							some(bLocal),
							genCompareExpr(
								alloc,
								range,
								compareFuns,
								comparisonTypes,
								aType,
								getALocal,
								localRef(alloc, range, bLocal)));
					}
				});
			immutable Ptr!LowLocal bMatchedLocal =
				addLocal(alloc, shortSymAlphaLiteral("match-b"), safeSizeTToU8(aIndex), b.type);
			immutable LowExpr then = immutable LowExpr(immutable LowType(comparisonTypes.comparison), range,
				immutable LowExprKind(nu!(LowExprKind.Match)(alloc, bMatchedLocal, allocate(alloc, b), bCases)));
			return immutable LowExprKind.Match.Case(some(aLocal), then);
		});

	immutable LowExpr expr = immutable LowExpr(
		immutable LowType(comparisonTypes.comparison),
		range,
		immutable LowExprKind(nu!(LowExprKind.Match)(alloc, aMatchedLocal, allocate(alloc, a), aCases)));
	return immutable LowFunExprBody(False, allocate(alloc, expr));
}

immutable(LowFunExprBody) genCompareRecord(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable ComparisonTypes comparisonTypes,
	ref const CompareFuns compareFuns,
	immutable Arr!LowField allFields,
	ref immutable LowExpr a,
	ref immutable LowExpr b,
) {
	immutable(LowExpr) recur(immutable LowExpr accum, immutable Arr!LowField fields) {
		if (empty(fields))
			return accum;
		else {
			// Generate the comparisons in reverse -- though the first field is the to actually be compared first
			immutable u8 fieldIndex = safeSizeTToU8(size(fields) - 1);
			immutable Ptr!LowField field = ptrAt(fields, fieldIndex);
			immutable LowExpr compareThisField =
				compareOneField(alloc, range, comparisonTypes, compareFuns, field.type, fieldIndex, a, b);
			immutable LowExpr e =
				combineCompares(alloc, range, comparisonTypes, fieldIndex, compareThisField, accum);
			return recur(e, rtail(fields));
		}
	}
	//TODO: simpler -- just use the last field's comparison as the last value, not 'eq'
	immutable LowExpr expr = recur(genComparisonEqual(alloc, range, comparisonTypes), allFields);
	return immutable LowFunExprBody(False, allocate(alloc, expr));
}

immutable(LowExpr) compareOneField(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable ComparisonTypes comparisonTypes,
	ref const CompareFuns compareFuns,
	immutable LowType fieldType,
	immutable u8 fieldIndex,
	ref immutable LowExpr a,
	ref immutable LowExpr b,
) {
	immutable LowExpr ax = recordFieldGet(alloc, range, a, fieldType, fieldIndex);
	immutable LowExpr bx = recordFieldGet(alloc, range, b, fieldType, fieldIndex);
	return genCompareExpr(alloc, range, compareFuns, comparisonTypes, fieldType, ax, bx);
}

immutable(LowExpr) genComparePrimitive(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable ComparisonTypes comparisonTypes,
	immutable PrimitiveType type,
	ref immutable LowExpr a,
	ref immutable LowExpr b,
) {
	immutable(LowExpr) genCompareNumeric(immutable LowExprKind.SpecialBinary.Kind less) {
		immutable LowExpr aLessB = genBinary(alloc, range, boolType, less, a, b);
		immutable LowExpr bLessA = genBinary(alloc, range, boolType, less, b, a);
		immutable LowExpr else_ = genIf(
			alloc,
			range,
			bLessA,
			genComparisonGreater(alloc, range, comparisonTypes),
			genComparisonEqual(alloc, range, comparisonTypes));
		return genIf(
			alloc,
			range,
			aLessB,
			genComparisonLess(alloc, range, comparisonTypes),
			else_);
	}

	final switch (type) {
		case PrimitiveType.bool_:
			return genCompareNumeric(LowExprKind.SpecialBinary.Kind.lessBool);
		case PrimitiveType.char_:
			return genCompareNumeric(LowExprKind.SpecialBinary.Kind.lessChar);
		case PrimitiveType.float64:
			return genCompareNumeric(LowExprKind.SpecialBinary.Kind.lessFloat64);
		case PrimitiveType.fun:
			return unreachable!(immutable LowExpr)();
		case PrimitiveType.int8:
			return genCompareNumeric(LowExprKind.SpecialBinary.Kind.lessInt8);
		case PrimitiveType.int16:
			return genCompareNumeric(LowExprKind.SpecialBinary.Kind.lessInt16);
		case PrimitiveType.int32:
			return genCompareNumeric(LowExprKind.SpecialBinary.Kind.lessInt32);
		case PrimitiveType.int64:
			return genCompareNumeric(LowExprKind.SpecialBinary.Kind.lessInt64);
		case PrimitiveType.nat8:
			return genCompareNumeric(LowExprKind.SpecialBinary.Kind.lessNat8);
		case PrimitiveType.nat16:
			return genCompareNumeric(LowExprKind.SpecialBinary.Kind.lessNat16);
		case PrimitiveType.nat32:
			return genCompareNumeric(LowExprKind.SpecialBinary.Kind.lessNat32);
		case PrimitiveType.nat64:
			return genCompareNumeric(LowExprKind.SpecialBinary.Kind.lessNat64);
		case PrimitiveType.void_:
			return genComparisonEqual(alloc, range, comparisonTypes);
	}
}
