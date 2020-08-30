module concretize.concretizeBuiltin;

@safe @nogc pure nothrow:

import concreteModel :
	arityExcludingCtxAndClosure,
	asRecord,
	asUnion,
	body_,
	BuiltinFunEmit,
	BuiltinFunInfo,
	BuiltinFunKind,
	BuiltinStructInfo,
	BuiltinStructKind,
	ConcreteExpr,
	ConcreteField,
	ConcreteFun,
	ConcreteFunBody,
	ConcreteFunExprBody,
	ConcreteLocal,
	ConcreteParam,
	ConcreteStructBody,
	ConcreteType,
	defaultIsPointer,
	matchConcreteStructBody,
	mustBeNonPointer,
	paramsExcludingCtxAndClosure,
	returnType,
	SpecialStructInfo;
import concretize.builtinInfo : getBuiltinFunInfo;
import concretize.concretizeCtx :
	boolType,
	ConcretizeCtx,
	ConcreteFunKey,
	ConcreteFunSource,
	containingFunDecl,
	getOrAddConcreteFunAndFillBody,
	typeArgs,
	withTypeArgs;
import concretize.concretizeExpr : allocExpr;
import util.bools : Bool, False;
import util.collection.arr : Arr, at, emptyArr, first, empty, only, ptrAt, size;
import util.collection.arrBuilder : addMany, ArrBuilder, finishArr;
import util.collection.arrUtil : arrLiteral, cat, rtail;
import util.collection.str : Str, strEq, strEqLiteral, strLiteral;
import util.memory : nu;
import util.opt : force, has, none;
import util.ptr : Ptr;
import util.sourceRange : SourceRange;
import util.util : todo;

immutable(ConcreteFunBody) getBuiltinFunBody(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable ConcreteFunSource source,
	immutable Ptr!ConcreteFun cf,
) {
	immutable BuiltinFunInfo info = getBuiltinFunInfo(containingFunDecl(source).sig);
	immutable Arr!ConcreteType typeArgs = typeArgs(source);
	switch (info.kind) {
		case BuiltinFunKind.compare:
			return immutable ConcreteFunBody(generateCompare!Alloc(alloc, ctx, source.containingConcreteFunKey, cf));
		default:
			assert(info.emit != BuiltinFunEmit.generate);
			return immutable ConcreteFunBody(immutable ConcreteFunBody.Builtin(info, typeArgs));
	}
	return todo!(immutable ConcreteFunBody)("getBuiltinFunBody");
}

private:

immutable(ConcreteFunExprBody) generateCompare(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable ConcreteFunKey compareFunKey,
	immutable Ptr!ConcreteFun compareFun,
) {
	immutable ComparisonTypes types = getComparisonTypes(returnType(compareFun), compareFunKey.typeArgs);
	assert(arityExcludingCtxAndClosure(compareFun) == 2);
	immutable Ptr!ConcreteParam aParam = ptrAt(paramsExcludingCtxAndClosure(compareFun), 0);
	immutable Ptr!ConcreteParam bParam = ptrAt(paramsExcludingCtxAndClosure(compareFun), 1);
	immutable Bool aIsPointer = aParam.type.isPointer;
	immutable Bool bIsPointer = bParam.type.isPointer;
	immutable ConcreteExpr a =
		immutable ConcreteExpr(types.t, SourceRange.empty, immutable ConcreteExpr.ParamRef(aParam));
	immutable ConcreteExpr b =
		immutable ConcreteExpr(types.t, SourceRange.empty, immutable ConcreteExpr.ParamRef(bParam));
	immutable ConcreteType boolType = boolType(alloc, ctx);
	if (types.t.isPointer != defaultIsPointer(types.t.struct_))
		todo!void("compare by value -- just take a ref and compare by ref");

	if (has(types.t.struct_.special)) {
		immutable SpecialStructInfo info = force(types.t.struct_.special);
		final switch (info.kind) {
			case SpecialStructInfo.Kind.arr:
				return generateCompareArr(
					alloc,
					ctx,
					compareFunKey,
					types.comparison,
					compareFun,
					types,
					info.elementType,
					a,
					b);
		}
	} else {
		return matchConcreteStructBody!(immutable ConcreteFunExprBody)(
			body_(types.t.struct_),
			(ref immutable ConcreteStructBody.Builtin builtin) =>
				generateCompareBuiltin(alloc, boolType, types, builtin, a, b),
			(ref immutable ConcreteStructBody.Record it) =>
				generateCompareRecord(alloc, ctx, compareFunKey, types, it, a, b, aIsPointer, bIsPointer),
			(ref immutable ConcreteStructBody.Union) =>
				todo!(immutable ConcreteFunExprBody)("compare union"));
		return todo!(immutable ConcreteFunExprBody)("generateCompare");
	}
}

immutable(ConcreteFunExprBody) generateCompareBuiltin(Alloc)(
	ref Alloc alloc,
	ref immutable ConcreteType boolType,
	ref immutable ComparisonTypes types,
	ref immutable ConcreteStructBody.Builtin builtin,
	ref immutable ConcreteExpr a,
	ref immutable ConcreteExpr b,
) {
	immutable BuiltinStructInfo info = builtin.info;
	final switch (info.kind) {
		case BuiltinStructKind.bool_:
		case BuiltinStructKind.byte_:
		case BuiltinStructKind.char_:
		case BuiltinStructKind.float64:
		case BuiltinStructKind.int16:
		case BuiltinStructKind.int32:
		case BuiltinStructKind.int64:
		case BuiltinStructKind.nat16:
		case BuiltinStructKind.nat32:
		case BuiltinStructKind.nat64:
		case BuiltinStructKind.ptr: {
			// Output: a < b ? less : b < a ? greater : equal
			immutable ConcreteExpr aLessB = makeLess(alloc, boolType, a, b);
			immutable ConcreteExpr bLessA = makeLess(alloc, boolType, b, a);
			immutable ConcreteExpr else_ = makeCond(
				alloc,
				types.comparison,
				bLessA,
				genGreaterLiteral(alloc, types),
				genEqualLiteral(alloc, types));
			immutable ConcreteExpr expr = makeCond(
				alloc,
				types.comparison,
				aLessB,
				genLessLiteral(alloc, types),
				else_);
			return ConcreteFunExprBody(emptyArr!(Ptr!ConcreteLocal), expr);
		}

		case BuiltinStructKind.funPtrN:
			// should be a compile error? (Or just allow this?)
			return todo!ConcreteFunExprBody("compare fun-ptrN");

		case BuiltinStructKind.void_:
			return ConcreteFunExprBody(emptyArr!(Ptr!ConcreteLocal), genEqualLiteral(alloc, types));
	}
}

struct ComparisonTypes {
	immutable ConcreteType t; // the type filling in for ?t in `compare comparison(a ?t, b ?t)`
	immutable ConcreteType comparison;
	immutable ConcreteType less;
	immutable ConcreteType equal;
	immutable ConcreteType greater;
}

immutable(ComparisonTypes) getComparisonTypes(
	ref immutable ConcreteType comparison,
	ref immutable Arr!ConcreteType typeArgs,
) {
	immutable ConcreteType t = only(typeArgs);
	immutable Arr!ConcreteType unionMembers = asUnion(body_(comparison.struct_)).members;
	assert(size(unionMembers) == 3);
	immutable ConcreteType less = at(unionMembers, 0);
	immutable ConcreteType equal = at(unionMembers, 1);
	immutable ConcreteType greater = at(unionMembers, 2);
	assert(strEqLiteral(comparison.struct_.mangledName, "comparison"));
	assert(strEqLiteral(less.struct_.mangledName, "less"));
	assert(strEqLiteral(equal.struct_.mangledName, "equal"));
	assert(strEqLiteral(greater.struct_.mangledName, "greater"));
	return immutable ComparisonTypes(t, comparison, less, equal, greater);
}

immutable(ConcreteExpr) makeLess(Alloc)(
	ref Alloc alloc,
	ref immutable ConcreteType boolType,
	ref immutable ConcreteExpr a,
	ref immutable ConcreteExpr b,
) {
	return immutable ConcreteExpr(boolType, SourceRange.empty, immutable ConcreteExpr.SpecialBinary(
		ConcreteExpr.SpecialBinary.Kind.less,
		allocExpr(alloc, a),
		allocExpr(alloc, b)));
}

immutable(ConcreteExpr) makeCond(Alloc)(
	ref Alloc alloc,
	ref immutable ConcreteType type,
	immutable ConcreteExpr cond,
	immutable ConcreteExpr then,
	immutable ConcreteExpr else_,
) {
	return immutable ConcreteExpr(
		type,
		SourceRange.empty,
		immutable ConcreteExpr.Cond(
			allocExpr(alloc, cond),
			allocExpr(alloc, then),
			allocExpr(alloc, else_)));
}

struct LocalsAndExpr {
	immutable Arr!(Ptr!ConcreteLocal) locals;
	immutable Ptr!ConcreteExpr expr;
}

immutable(LocalsAndExpr) combineCompares(Alloc)(
	ref Alloc alloc,
	immutable Str name,
	ref immutable ConcreteExpr cmpFirst,
	ref immutable ConcreteExpr cmpSecond,
	ref immutable ConcreteType comparisonType,
) {
	immutable Ptr!ConcreteLocal cmpFirstLocal = nu!ConcreteLocal(
		alloc,
		cat(alloc, strLiteral("_cmp"), name),
		comparisonType);
	immutable ConcreteExpr getCmpFirst = immutable ConcreteExpr(
		comparisonType,
		SourceRange.empty,
		immutable ConcreteExpr.LocalRef(cmpFirstLocal));
	immutable ConcreteExpr.Match.Case caseUseFirst = ConcreteExpr.Match.Case(none!(Ptr!ConcreteLocal), getCmpFirst);
	immutable ConcreteExpr.Match.Case caseUseSecond = ConcreteExpr.Match.Case(none!(Ptr!ConcreteLocal), cmpSecond);
	immutable Arr!(ConcreteExpr.Match.Case) cases = arrLiteral!(ConcreteExpr.Match.Case)(
		alloc,
		caseUseFirst,
		caseUseSecond,
		caseUseFirst);
	immutable Ptr!ConcreteLocal matchedLocal = nu!ConcreteLocal(
		alloc,
		cat(alloc, strLiteral("_matched"), name),
		comparisonType);
	immutable ConcreteExpr then = immutable ConcreteExpr(
		comparisonType,
		SourceRange.empty,
		immutable ConcreteExpr.Match(matchedLocal, allocExpr(alloc, getCmpFirst), cases));
	immutable ConcreteExpr res = immutable ConcreteExpr(
		comparisonType,
		SourceRange.empty,
		immutable ConcreteExpr.Let(
			cmpFirstLocal,
			allocExpr(alloc, cmpFirst),
			allocExpr(alloc, then)));
	return LocalsAndExpr(
		arrLiteral!(Ptr!ConcreteLocal)(alloc, cmpFirstLocal, matchedLocal),
		allocExpr(alloc, res));
}

immutable(ConcreteExpr) genFieldAccess(Alloc)(
	ref Alloc alloc,
	ref immutable ConcreteExpr a,
	immutable Bool aIsPointer,
	immutable Ptr!ConcreteField field,
) {
	return immutable ConcreteExpr(
		field.type,
		SourceRange.empty,
		immutable ConcreteExpr.RecordFieldAccess(aIsPointer, allocExpr(alloc, a), field));
}

immutable(ConcreteExpr) genCreateArr(Alloc)(
	ref Alloc alloc,
	ref immutable ConcreteType arrType,
	ref immutable ConcreteExpr size,
	ref immutable ConcreteExpr data,
) {
	immutable Arr!ConcreteExpr args = arrLiteral(alloc, size, data);
	return immutable ConcreteExpr(arrType, SourceRange.empty, immutable ConcreteExpr.CreateRecord(args));
}

immutable(ConcreteFunExprBody) generateCompareArr(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable ConcreteFunKey compareFunKey,
	ref immutable ConcreteType comparisonType,
	immutable Ptr!ConcreteFun compareFun,
	ref immutable ComparisonTypes types,
	ref immutable ConcreteType elementType,
	ref immutable ConcreteExpr a,
	ref immutable ConcreteExpr b,
) {
	// a.size == 0 ? (b.size == 0 ? eq : lt) : (b.size == 0 ? gt : (a[0] <=> b[0] or cmp(tail(a), tail(b))))
	immutable ConcreteType arrType = first(paramsExcludingCtxAndClosure(compareFun)).type;
	immutable ConcreteStructBody.Record r = asRecord(body_(mustBeNonPointer(arrType).deref));
	assert(size(r.fields) == 2);
	immutable Ptr!ConcreteField sizeField = ptrAt(r.fields, 0);
	immutable Ptr!ConcreteField dataField = ptrAt(r.fields, 1);
	assert(strEq(sizeField.mangledName, strLiteral("size")));
	assert(strEq(dataField.mangledName, strLiteral("data")));

	immutable ConcreteType boolType = boolType(alloc, ctx);
	immutable ConcreteType natType = sizeField.type;
	immutable ConcreteType ptrType = dataField.type;

	immutable(ConcreteExpr) genGetSize(ref immutable ConcreteExpr arr) {
		return genFieldAccess(alloc, arr, False, sizeField);
	}
	immutable(ConcreteExpr) genGetData(ref immutable ConcreteExpr arr) {
		return genFieldAccess(alloc, arr, False, dataField);
	}

	immutable(ConcreteExpr) genTail(ref immutable ConcreteExpr arr) {
		immutable ConcreteExpr curSize = genGetSize(arr);
		immutable ConcreteExpr curData = genGetData(arr);
		immutable ConcreteExpr newSize = genDecrNat(alloc, ctx, natType, curSize);
		immutable ConcreteExpr newData = genIncrPointer(alloc, ctx, ptrType, natType, curData);
		return genCreateArr(alloc, arrType, newSize, newData);
	}

	immutable(ConcreteExpr) genFirst(ref immutable ConcreteExpr arr) {
		return genDeref(alloc, elementType, genGetData(arr));
	}

	immutable ConcreteExpr compareFirst = genCompare(alloc, ctx, compareFunKey, elementType, genFirst(a), genFirst(b));
	immutable ConcreteExpr recurOnTail = genCall(alloc, compareFun, genTail(a), genTail(b));
	immutable(LocalsAndExpr) firstThenRecur = combineCompares!Alloc(
		alloc,
		strLiteral("el"),
		compareFirst,
		recurOnTail,
		types.comparison);

	immutable(ConcreteExpr) genSizeEqZero(ref immutable ConcreteExpr arr) {
		immutable ConcreteExpr size = genGetSize(arr);
		return genNatEqZero(alloc, ctx, boolType, natType, size);
	}

	immutable ConcreteExpr bSizeIsZero = genSizeEqZero(b);
	immutable ConcreteExpr res = makeCond(
		alloc,
		comparisonType,
		genSizeEqZero(a),
		makeCond(alloc, comparisonType, bSizeIsZero, genEqualLiteral(alloc, types), genLessLiteral(alloc, types)),
		makeCond(alloc, comparisonType, bSizeIsZero, genGreaterLiteral(alloc, types), firstThenRecur.expr));

	return immutable ConcreteFunExprBody(firstThenRecur.locals, res);
}

immutable(ConcreteExpr) genDecrNat(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable ConcreteType natType,
	ref immutable ConcreteExpr a,
) {
	return immutable ConcreteExpr(
		natType,
		SourceRange.empty,
		immutable ConcreteExpr.SpecialBinary(
			ConcreteExpr.SpecialBinary.Kind.sub,
			allocExpr(alloc, a),
			allocExpr(alloc, immutable ConcreteExpr(
				natType,
				SourceRange.empty,
				immutable ConcreteExpr.SpecialConstant(ConcreteExpr.SpecialConstant.Kind.one)))));
}

immutable(ConcreteExpr) genNatEqNat(Alloc)(
	ref Alloc alloc,
	ref immutable ConcreteType boolType,
	ref immutable ConcreteExpr a,
	ref immutable ConcreteExpr b,
) {
	return immutable ConcreteExpr(
		boolType,
		SourceRange.empty,
		immutable ConcreteExpr.SpecialBinary(
			ConcreteExpr.SpecialBinary.Kind.eq,
			allocExpr(alloc, a),
			allocExpr(alloc, b)));
}

immutable(ConcreteExpr) genNatEqZero(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable ConcreteType boolType,
	ref immutable ConcreteType natType,
	ref immutable ConcreteExpr a,
) {
	immutable ConcreteExpr zero = immutable ConcreteExpr(
		natType,
		SourceRange.empty,
		immutable ConcreteExpr.SpecialConstant(ConcreteExpr.SpecialConstant.Kind.zero));
	return genNatEqNat(alloc, boolType, a, zero);
}

immutable(ConcreteExpr) genIncrPointer(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable ConcreteType ptrType,
	ref immutable ConcreteType natType,
	ref immutable ConcreteExpr ptr,
) {
	return immutable ConcreteExpr(
		ptrType,
		SourceRange.empty,
		immutable ConcreteExpr.SpecialBinary(
			ConcreteExpr.SpecialBinary.Kind.add,
			allocExpr(alloc, ptr),
			allocExpr(alloc, immutable ConcreteExpr(
				natType,
				SourceRange.empty,
				immutable ConcreteExpr.SpecialConstant(ConcreteExpr.SpecialConstant.Kind.one)))));
}

immutable(ConcreteExpr) genDeref(Alloc)(
	ref Alloc alloc,
	ref immutable ConcreteType derefedType,
	immutable ConcreteExpr ptr,
) {
	return immutable ConcreteExpr(
		derefedType,
		SourceRange.empty,
		immutable ConcreteExpr.SpecialUnary(
			ConcreteExpr.SpecialUnary.Kind.deref,
			allocExpr(alloc, ptr)));
}

immutable(ConcreteExpr) genLessLiteral(Alloc)(ref Alloc alloc, ref immutable ComparisonTypes types) {
	return genLtEqOrGtHelper(alloc, types, 0, types.less);
}

immutable(ConcreteExpr) genEqualLiteral(Alloc)(ref Alloc alloc, ref immutable ComparisonTypes types) {
	return genLtEqOrGtHelper(alloc, types, 1, types.equal);
}

immutable(ConcreteExpr) genGreaterLiteral(Alloc)(ref Alloc alloc, ref immutable ComparisonTypes types) {
	return genLtEqOrGtHelper(alloc, types, 2, types.greater);
}

immutable(ConcreteExpr) genLtEqOrGtHelper(Alloc)(
	ref Alloc alloc,
	ref immutable ComparisonTypes types,
	immutable size_t memberIndex,
	ref immutable ConcreteType memberType,
) {
	immutable ConcreteExpr createMember = immutable ConcreteExpr(
		memberType,
		SourceRange.empty,
		immutable ConcreteExpr.CreateRecord(emptyArr!ConcreteExpr));
	return immutable ConcreteExpr(
		types.comparison,
		SourceRange.empty,
		immutable ConcreteExpr.ConvertToUnion(memberIndex, allocExpr(alloc, createMember)));
}

immutable(ConcreteExpr) genCompare(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable ConcreteFunKey compareFunKey,
	ref immutable ConcreteType argsType,
	immutable ConcreteExpr a,
	immutable ConcreteExpr b,
) {
	return genCall(alloc, getCompareFunFor(alloc, ctx, compareFunKey, argsType), a, b);
}

immutable(ConcreteExpr) genCall(Alloc)(
	ref Alloc alloc,
	immutable Ptr!ConcreteFun fun,
	immutable ConcreteExpr a,
	immutable ConcreteExpr b,
) {
	return genCall(alloc, fun, arrLiteral!ConcreteExpr(alloc, a, b));
}

immutable(ConcreteExpr) genCall(Alloc)(
	ref Alloc alloc,
	immutable Ptr!ConcreteFun fun,
	immutable Arr!ConcreteExpr args,
) {
	return immutable ConcreteExpr(
		returnType(fun),
		SourceRange.empty,
		immutable ConcreteExpr.Call(fun, args));
}

immutable(Ptr!ConcreteFun) getCompareFunFor(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable ConcreteFunKey compareFunKey,
	ref immutable ConcreteType ct,
) {
	immutable ConcreteFunKey key = withTypeArgs(compareFunKey, arrLiteral!ConcreteType(alloc, ct));
	return getOrAddConcreteFunAndFillBody(alloc, ctx, key);
}

immutable(ConcreteFunExprBody) generateCompareRecord(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable ConcreteFunKey concreteFunKey,
	ref immutable ComparisonTypes types,
	ref immutable ConcreteStructBody.Record r,
	ref immutable ConcreteExpr a,
	ref immutable ConcreteExpr b,
	immutable Bool aIsPointer,
	immutable Bool bIsPointer,
) {
	ArrBuilder!(Ptr!ConcreteLocal) locals;

	immutable(ConcreteExpr) recur(immutable ConcreteExpr accum, immutable Arr!ConcreteField fields) {
		if (empty(fields))
			return accum;
		else {
			// Generate the comparisons in reverse -- though the first field is the to actually be compared first
			immutable Ptr!ConcreteField field = ptrAt(fields, size(fields) - 1);
			immutable ConcreteExpr compareThisField =
				compareOneField(alloc, ctx, concreteFunKey, field, a, b, aIsPointer, bIsPointer);
			immutable LocalsAndExpr le =
				combineCompares(alloc, field.mangledName, compareThisField, accum, types.comparison);
			addMany(alloc, locals, le.locals);
			return recur(le.expr, rtail(fields));
		}
	}
	immutable ConcreteExpr expr = recur(genEqualLiteral(alloc, types), r.fields);
	return ConcreteFunExprBody(finishArr(alloc, locals), expr);
}

immutable(ConcreteExpr) compareOneField(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable ConcreteFunKey compareFunKey,
	immutable Ptr!ConcreteField field,
	ref immutable ConcreteExpr a,
	ref immutable ConcreteExpr b,
	immutable Bool aIsPointer,
	immutable Bool bIsPointer,
) {
	immutable ConcreteExpr ax = genFieldAccess(alloc, a, aIsPointer, field);
	immutable ConcreteExpr bx = genFieldAccess(alloc, b, bIsPointer, field);
	return genCompare(alloc, ctx, compareFunKey, field.type, ax, bx);
}

