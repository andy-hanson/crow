module lower.generateCompareFun;

@safe @nogc pure nothrow:

import lowModel :
	asNonFunPtrType,
	asRecordType,
	asUnionType,
	LowExpr,
	LowExprKind,
	LowField,
	LowFun,
	LowFunBody,
	LowFunExprBody,
	LowFunIndex,
	LowLocal,
	LowParam,
	LowRecord,
	LowType,
	LowUnion,
	matchLowType,
	PrimitiveType;
import lower.lower : AllLowTypes, CompareFuns, getCompareFun;
import lower.lowExprHelpers :
	boolType,
	decrNat64,
	genBinary,
	genCall,
	genCreateRecord,
	genCreateUnion,
	genDeref,
	genIf,
	genLet,
	genNat64Eq0,
	genUnary,
	incrPointer,
	localRef,
	paramRef,
	recordFieldAccess;
import util.bools : Bool;
import util.collection.arr : Arr, at, empty, emptyArr, ptrAt, size;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.arrUtil : arrLiteral, cat, fillArr, mapWithIndex, rtail;
import util.collection.str : Str, strEqLiteral, strLiteral;
import util.memory : allocate, nu;
import util.opt : none, some;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.sourceRange : SourceRange;
import util.util : todo, unreachable;
import util.writer : finishWriter, Writer, writeStatic, writeNat;

immutable(LowFun) generateCompareFun(Alloc)(
	ref Alloc alloc,
	ref immutable SourceRange range,
	ref immutable AllLowTypes allTypes,
	ref immutable ComparisonTypes comparisonTypes,
	ref const CompareFuns compareFuns,
	immutable LowFunIndex thisFunIndex,
	ref immutable LowType paramType,
	immutable Bool typeIsArr,
) {
	immutable Str mangledName = () {
		Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
		writeStatic(writer, "compare");
		writeNat(writer, thisFunIndex.index);
		return finishWriter(writer);
	}();
	immutable Arr!LowParam params = arrLiteral!LowParam(
		alloc,
		immutable LowParam(strLiteral("a"), paramType),
		immutable LowParam(strLiteral("b"), paramType));
	immutable LowExpr a = paramRef(range, ptrAt(params, 0));
	immutable LowExpr b = paramRef(range, ptrAt(params, 1));
	immutable LowFunExprBody body_ = typeIsArr
		? arrCompareBody(alloc, range, allTypes, comparisonTypes, compareFuns, paramType, thisFunIndex, a, b)
		: compareBody(alloc, range, allTypes, comparisonTypes, compareFuns, paramType, a, b);
	return immutable LowFun(
		mangledName,
		immutable LowType(comparisonTypes.comparison),
		params,
		immutable LowFunBody(body_));
}

struct ComparisonTypes {
	immutable LowType.Union comparison;
	immutable LowType.Record less;
	immutable LowType.Record equal;
	immutable LowType.Record greater;
}

immutable(LowFunExprBody) arrCompareBody(Alloc)(
	ref Alloc alloc,
	ref immutable SourceRange range,
	ref immutable AllLowTypes allTypes,
	ref immutable ComparisonTypes comparisonTypes,
	ref const CompareFuns compareFuns,
	ref immutable LowType arrType,
	immutable LowFunIndex currentFunIndex,
	ref immutable LowExpr a,
	ref immutable LowExpr b,
) {
	immutable LowType.Record arrRecordType = asRecordType(arrType);
	immutable LowRecord arrRecord = at(allTypes.allRecords, arrRecordType.index);
	assert(size(arrRecord.fields) == 2);
	immutable Ptr!LowField sizeField = ptrAt(arrRecord.fields, 0);
	immutable Ptr!LowField dataField = ptrAt(arrRecord.fields, 1);
	assert(strEqLiteral(sizeField.mangledName, "size"));
	assert(strEqLiteral(dataField.mangledName, "data"));
	immutable LowType elementPtrType = dataField.type;
	immutable LowType elementType = asNonFunPtrType(elementPtrType).pointee;

	immutable(LowExpr) genGetSize(ref immutable LowExpr arr) {
		return recordFieldAccess(alloc, range, arr, sizeField);
	}
	immutable(LowExpr) genGetData(ref immutable LowExpr arr) {
		return recordFieldAccess(alloc, range, arr, dataField);
	}
	immutable(LowExpr) genTail(ref immutable LowExpr arr) {
		immutable LowExpr curSize = genGetSize(arr);
		immutable LowExpr curData = genGetData(arr);
		immutable LowExpr newSize = decrNat64(alloc, range, curSize);
		immutable LowExpr newData = incrPointer(alloc, range, elementPtrType, curData);
		return genCreateRecord(range, arrRecordType, arrLiteral!LowExpr(alloc, newSize, newData));
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
	immutable LowExpr recurOnTail = genCall(
		alloc,
		range,
		currentFunIndex,
		immutable LowType(comparisonTypes.comparison),
		arrLiteral!LowExpr(alloc, genTail(a), genTail(b)));
	ArrBuilder!(Ptr!LowLocal) locals;
	immutable LowExpr firstThenRecur = combineCompares(
		alloc,
		locals,
		range,
		comparisonTypes,
		strLiteral("element"),
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
	return immutable LowFunExprBody(finishArr(alloc, locals), expr);
}

immutable(LowExpr) combineCompares(Alloc)(
	ref Alloc alloc,
	ref ArrBuilder!(Ptr!LowLocal) locals,
	ref immutable SourceRange range,
	ref immutable ComparisonTypes comparisonTypes,
	immutable Str tempMangledName,
	immutable LowExpr compareFirst,
	immutable LowExpr compareSecond,
) {
	immutable Arr!(LowExprKind.Match.Case) cases = arrLiteral!(LowExprKind.Match.Case)(
		alloc,
		immutable LowExprKind.Match.Case(none!(Ptr!LowLocal), genComparisonLess(alloc, range, comparisonTypes)),
		immutable LowExprKind.Match.Case(none!(Ptr!LowLocal), compareSecond),
		immutable LowExprKind.Match.Case(none!(Ptr!LowLocal), genComparisonGreater(alloc, range, comparisonTypes)));
	immutable Ptr!LowLocal matchedLocal = addLocal(
		alloc,
		locals,
		cat(alloc, strLiteral("matched"), tempMangledName),
		immutable LowType(comparisonTypes.comparison));
	return immutable LowExpr(
		immutable LowType(comparisonTypes.comparison),
		range,
		immutable LowExprKind(immutable LowExprKind.Match(matchedLocal, allocate(alloc, compareFirst), cases)));
}

immutable(Ptr!LowLocal) addLocal(Alloc)(
	ref Alloc alloc,
	ref ArrBuilder!(Ptr!LowLocal) locals,
	immutable Str mangledName,
	immutable LowType type,
) {
	immutable Ptr!LowLocal res = nu!LowLocal(alloc, mangledName, type);
	add(alloc, locals, res);
	return res;
}

immutable(LowExpr) genCompareExpr(Alloc)(
	ref Alloc alloc,
	ref immutable SourceRange range,
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
		arrLiteral!LowExpr(alloc, a, b));
}

immutable(LowExpr) genComparisonLess(Alloc)(
	ref Alloc alloc,
	ref immutable SourceRange range,
	ref immutable ComparisonTypes comparisonTypes,
) {
	return genCreateUnion(alloc, range, comparisonTypes.comparison, 0, genCreateRecord(range, comparisonTypes.less));
}

immutable(LowExpr) genComparisonEqual(Alloc)(
	ref Alloc alloc,
	ref immutable SourceRange range,
	ref immutable ComparisonTypes comparisonTypes,
) {
	return genCreateUnion(alloc, range, comparisonTypes.comparison, 1, genCreateRecord(range, comparisonTypes.equal));
}

immutable(LowExpr) genComparisonGreater(Alloc)(
	ref Alloc alloc,
	ref immutable SourceRange range,
	ref immutable ComparisonTypes comparisonTypes,
) {
	return genCreateUnion(alloc, range, comparisonTypes.comparison, 2, genCreateRecord(range, comparisonTypes.greater));
}

immutable(LowFunExprBody) compareBody(Alloc)(
	ref Alloc alloc,
	ref immutable SourceRange range,
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
			at(allTypes.allRecords, recordType.index).fields,
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
				emptyArr!(Ptr!LowLocal),
				genComparePrimitive(alloc, range, comparisonTypes, it, a, b)),
		(immutable LowType.Record it) =>
			record(it),
		(immutable LowType.Union it) =>
			genCompareUnion(alloc, range, comparisonTypes, compareFuns, at(allTypes.allUnions, it.index), a, b));
}

immutable(LowFunExprBody) genCompareUnion(Alloc)(
	ref Alloc alloc,
	ref immutable SourceRange range,
	ref immutable ComparisonTypes comparisonTypes,
	ref const CompareFuns compareFuns,
	immutable LowUnion union_,
	ref immutable LowExpr a,
	ref immutable LowExpr b,
) {
	ArrBuilder!(Ptr!LowLocal) locals;
	immutable Ptr!LowLocal aMatchedLocal = addLocal(alloc, locals, strLiteral("matchA"), a.type);
	immutable Arr!(LowExprKind.Match.Case) aCases =
		mapWithIndex(alloc, union_.members, (immutable size_t aIndex, ref immutable LowType aType) {
			immutable Ptr!LowLocal aLocal = addLocal(alloc, locals, localName(alloc, "a", aIndex), aType);
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
						immutable Ptr!LowLocal bLocal = addLocal(alloc, locals, localName(alloc, "b", bIndex), aType);
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
			immutable Ptr!LowLocal bMatchedLocal = addLocal(alloc, locals, localName(alloc, "matchB", aIndex), b.type);
			immutable LowExpr then = immutable LowExpr(immutable LowType(comparisonTypes.comparison), range,
				immutable LowExprKind(immutable LowExprKind.Match(bMatchedLocal, allocate(alloc, b), bCases)));
			return immutable LowExprKind.Match.Case(some(aLocal), then);
		});

	immutable LowExpr expr = immutable LowExpr(
		immutable LowType(comparisonTypes.comparison),
		range,
		immutable LowExprKind(immutable LowExprKind.Match(aMatchedLocal, allocate(alloc, a), aCases)));
	return immutable LowFunExprBody(finishArr(alloc, locals), expr);
}

immutable(Str) localName(Alloc)(ref Alloc alloc, immutable string a, immutable size_t n) {
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	writeStatic(writer, a);
	writeNat(writer, n);
	return finishWriter(writer);
}

immutable(LowFunExprBody) genCompareRecord(Alloc)(
	ref Alloc alloc,
	ref immutable SourceRange range,
	ref immutable ComparisonTypes comparisonTypes,
	ref const CompareFuns compareFuns,
	immutable Arr!LowField allFields,
	ref immutable LowExpr a,
	ref immutable LowExpr b,
) {
	ArrBuilder!(Ptr!LowLocal) locals;

	immutable(LowExpr) recur(immutable LowExpr accum, immutable Arr!LowField fields) {
		if (empty(fields))
			return accum;
		else {
			// Generate the comparisons in reverse -- though the first field is the to actually be compared first
			immutable Ptr!LowField field = ptrAt(fields, size(fields) - 1);
			immutable LowExpr compareThisField =
				compareOneField(alloc, range, comparisonTypes, compareFuns, field, a, b);
			immutable LowExpr e =
				combineCompares(alloc, locals, range, comparisonTypes, field.mangledName, compareThisField, accum);
			return recur(e, rtail(fields));
		}
	}
	//TODO: simpler -- just use the last field's comparison as the last value, not 'eq'
	immutable LowExpr expr = recur(genComparisonEqual(alloc, range, comparisonTypes), allFields);
	return immutable LowFunExprBody(finishArr(alloc, locals), expr);
}

immutable(LowExpr) compareOneField(Alloc)(
	ref Alloc alloc,
	ref immutable SourceRange range,
	ref immutable ComparisonTypes comparisonTypes,
	ref const CompareFuns compareFuns,
	immutable Ptr!LowField field,
	ref immutable LowExpr a,
	ref immutable LowExpr b,
) {
	immutable LowExpr ax = recordFieldAccess(alloc, range, a, field);
	immutable LowExpr bx = recordFieldAccess(alloc, range, b, field);
	return genCompareExpr(alloc, range, compareFuns, comparisonTypes, field.type, ax, bx);
}

immutable(LowExpr) genComparePrimitive(Alloc)(
	ref Alloc alloc,
	ref immutable SourceRange range,
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