module lower.lowExprHelpers;

@safe @nogc pure nothrow:

import model.constant : Constant;
import model.lowModel :
	asGcOrRawPointee,
	AllLowTypes,
	asPtrRaw,
	LowExpr,
	LowExprKind,
	LowFunIndex,
	LowLocal,
	LowLocalSource,
	LowParam,
	LowParamIndex,
	LowParamSource,
	LowRecord,
	LowType,
	name,
	PrimitiveType;
import util.collection.arr : at, emptyArr, size;
import util.collection.fullIndexDict : fullIndexDictGet;
import util.memory : allocate, nu;
import util.ptr : Ptr;
import util.sourceRange : FileAndRange;
import util.sym : shortSymAlphaLiteral, Sym, symEq;
import util.util : verify;

immutable LowType boolType = immutable LowType(PrimitiveType.bool_);
private immutable LowType charType = immutable LowType(PrimitiveType.char_);
private immutable LowType charPtrType = immutable LowType(immutable LowType.PtrRaw(immutable Ptr!LowType(&charType)));
immutable LowType charPtrPtrType = immutable LowType(immutable LowType.PtrRaw(immutable Ptr!LowType(&charPtrType)));
immutable LowType int32Type = immutable LowType(PrimitiveType.int32);
immutable LowType nat64Type = immutable LowType(PrimitiveType.nat64);
private immutable LowType nat8Type = immutable LowType(PrimitiveType.nat8);
immutable LowType anyPtrType = immutable LowType(immutable LowType.PtrRaw(immutable Ptr!LowType(&nat8Type)));
immutable LowType voidType = immutable LowType(PrimitiveType.void_);

immutable(LowExpr) genAddPtr(Alloc)(
	ref Alloc alloc,
	immutable LowType.PtrRaw ptrType,
	ref immutable FileAndRange range,
	immutable LowExpr ptr,
	immutable LowExpr added,
) {
	return immutable LowExpr(
		immutable LowType(ptrType),
		range,
		immutable LowExprKind(immutable LowExprKind.SpecialBinary(
			LowExprKind.SpecialBinary.Kind.addPtr,
			allocate(alloc, ptr),
			allocate(alloc, added))));
}

immutable(LowExpr) genAsAnyPtr(Alloc)(ref Alloc alloc, ref immutable FileAndRange range, ref immutable LowExpr a) {
	return immutable LowExpr(
		anyPtrType,
		range,
		immutable LowExprKind(immutable LowExprKind.SpecialUnary(
			LowExprKind.SpecialUnary.Kind.asAnyPtr,
			allocate(alloc, a))));
}

immutable(LowExpr) genDrop(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable LowExpr a,
	immutable ubyte localIndex,
) {
	// TODO: less hacky way?
	return immutable LowExpr(
		voidType,
		range,
		immutable LowExprKind(immutable LowExprKind.Let(
			genLocal(alloc, shortSymAlphaLiteral("dropped"), localIndex, a.type),
			allocate(alloc, a),
			allocate(alloc, genVoid(range)))));
}

private immutable(LowExpr) genDerefGcOrRawPtr(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	immutable LowExpr ptr,
) {
	return genUnary(alloc, range, asGcOrRawPointee(ptr.type), LowExprKind.SpecialUnary.Kind.deref, ptr);
}

immutable(LowExpr) genDerefGcPtr(Alloc)(ref Alloc alloc, ref immutable FileAndRange range, immutable LowExpr ptr) {
	return genDerefGcOrRawPtr(alloc, range, ptr);
}

immutable(LowExpr) genDerefRawPtr(Alloc)(ref Alloc alloc, ref immutable FileAndRange range, immutable LowExpr ptr) {
	return genDerefGcOrRawPtr(alloc, range, ptr);
}

private immutable(LowExpr) genUnary(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	immutable LowType type,
	immutable LowExprKind.SpecialUnary.Kind kind,
	immutable LowExpr arg,
) {
	return immutable LowExpr(
		type,
		range,
		immutable LowExprKind(immutable LowExprKind.SpecialUnary(kind, allocate(alloc, arg))));
}

immutable(LowExpr) genIf(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	immutable LowExpr cond,
	immutable LowExpr then,
	immutable LowExpr else_,
) {
	return immutable LowExpr(
		then.type,
		range,
		immutable LowExprKind(nu!(LowExprKind.SpecialTrinary)(
			alloc,
			LowExprKind.SpecialTrinary.Kind.if_,
			allocate(alloc, cond),
			allocate(alloc, then),
			allocate(alloc, else_))));
}

immutable(LowExpr) genNat64Eq0(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	immutable LowExpr a,
) {
	return genBinary(alloc, range, boolType, LowExprKind.SpecialBinary.Kind.eqNat64, a, constantNat64(range, 0));
}

immutable(LowExpr) incrPointer(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable LowType.PtrRaw ptrType,
	ref immutable LowExpr ptr,
) {
	return genAddPtr(alloc, ptrType, range, ptr, constantNat64(range, 1));
}

immutable(LowExpr) constantNat64(
	ref immutable FileAndRange range,
	immutable ulong value,
) {
	return immutable LowExpr(
		nat64Type,
		range,
		immutable LowExprKind(immutable Constant(immutable Constant.Integral(value))));
}

immutable(LowExpr) genCreateRecord(
	ref immutable FileAndRange range,
	immutable LowType.Record record,
	immutable LowExpr[] args,
) {
	return immutable LowExpr(
		immutable LowType(record),
		range,
		immutable LowExprKind(immutable LowExprKind.CreateRecord(args)));
}

immutable(LowExpr) genCreateRecord(ref immutable FileAndRange range, immutable LowType.Record record) {
	return genCreateRecord(range, record, emptyArr!LowExpr);
}

immutable(LowExpr) genCreateUnion(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	immutable LowType.Union union_,
	immutable ubyte memberIndex,
	immutable LowExpr member,
) {
	return immutable LowExpr(
		immutable LowType(union_),
		range,
		immutable LowExprKind(immutable LowExprKind.ConvertToUnion(memberIndex, allocate(alloc, member))));
}

immutable(LowExpr) genBinary(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	immutable LowType returnType,
	immutable LowExprKind.SpecialBinary.Kind kind,
	immutable LowExpr a,
	immutable LowExpr b,
) {
	return immutable LowExpr(
		returnType,
		range,
		immutable LowExprKind(immutable LowExprKind.SpecialBinary(kind, allocate(alloc, a), allocate(alloc, b))));
}

immutable(LowExpr) decrNat64(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	immutable LowExpr arg,
) {
	return immutable LowExpr(
		nat64Type,
		range,
		immutable LowExprKind(immutable LowExprKind.SpecialBinary(
			LowExprKind.SpecialBinary.Kind.wrapSubNat64,
			allocate(alloc, arg),
			allocate(alloc, constantNat64(range, 1)))));
}

immutable(LowExpr) genTailRecur(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	immutable LowType returnType,
	immutable LowExpr[] args,
) {
	return immutable LowExpr(returnType, range, immutable LowExprKind(immutable LowExprKind.TailRecur(args)));
}

immutable(LowExpr) genCall(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	immutable LowFunIndex called,
	immutable LowType returnType,
	immutable LowExpr[] args,
) {
	return immutable LowExpr(
		returnType,
		range,
		immutable LowExprKind(immutable LowExprKind.Call(called, args)));
}

immutable(LowExpr) getSizeOf(immutable FileAndRange range, immutable LowType t) {
	return immutable LowExpr(nat64Type, range, immutable LowExprKind(immutable LowExprKind.SizeOf(t)));
}

immutable(LowExpr) localRef(Alloc)(ref Alloc alloc, ref immutable FileAndRange range, immutable Ptr!LowLocal local) {
	return immutable LowExpr(local.type, range, immutable LowExprKind(immutable LowExprKind.LocalRef(local)));
}

immutable(LowParam) genParam(immutable Sym name, immutable LowType type) {
	return immutable LowParam(
		immutable LowParamSource(immutable LowParamSource.Generated(name)),
		type);
}

immutable(LowExpr) paramRef(
	ref immutable FileAndRange range,
	immutable LowType type,
	immutable LowParamIndex param,
) {
	return immutable LowExpr(
		type,
		range,
		immutable LowExprKind(immutable LowExprKind.ParamRef(param)));
}

immutable(LowExpr) wrapMulNat64(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	immutable LowExpr left,
	immutable LowExpr right,
) {
	return immutable LowExpr(
		nat64Type,
		range,
		immutable LowExprKind(immutable LowExprKind.SpecialBinary(
			LowExprKind.SpecialBinary.Kind.wrapMulNat64,
			allocate(alloc, left),
			allocate(alloc, right))));
}

immutable(LowExpr) genPtrEq(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable LowExpr a,
	ref immutable LowExpr b,
) {
	return immutable LowExpr(boolType, range, immutable LowExprKind(immutable LowExprKind.SpecialBinary(
		LowExprKind.SpecialBinary.Kind.eqPtr,
		allocate(alloc, a),
		allocate(alloc, b))));
}

immutable(LowExpr) ptrCast(Alloc)(
	ref Alloc alloc,
	immutable LowType type,
	ref immutable FileAndRange range,
	immutable LowExpr inner,
) {
	return immutable LowExpr(type, range, ptrCastKind(alloc, inner));
}

immutable(LowExprKind) ptrCastKind(Alloc)(ref Alloc alloc, immutable LowExpr inner) {
	return immutable LowExprKind(immutable LowExprKind.PtrCast(allocate(alloc, inner)));
}

immutable(LowExpr) recordFieldGet(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable LowExpr target,
	immutable LowType fieldType,
	immutable ubyte fieldIndex,
) {
	return immutable LowExpr(fieldType, range, immutable LowExprKind(
		immutable LowExprKind.RecordFieldGet(
			allocate(alloc, target),
			fieldIndex)));
}

immutable(LowExpr) seq(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	immutable LowExpr first,
	immutable LowExpr then,
) {
	return immutable LowExpr(
		then.type,
		range,
		immutable LowExprKind(immutable LowExprKind.Seq(allocate(alloc, first), allocate(alloc, then))));
}

immutable(LowExpr) writeToPtr(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable LowExpr ptr,
	ref immutable LowExpr value,
) {
	return immutable LowExpr(voidType, range, immutable LowExprKind(
		immutable LowExprKind.SpecialBinary(
			LowExprKind.SpecialBinary.Kind.writeToPtr,
			allocate(alloc, ptr),
			allocate(alloc, value))));
}

immutable(LowExpr) genVoid(ref immutable FileAndRange source) {
	return immutable LowExpr(voidType, source, immutable LowExprKind(immutable Constant(immutable Constant.Void())));
}

immutable(Ptr!LowLocal) genLocal(Alloc)(
	ref Alloc alloc,
	immutable Sym name,
	immutable ubyte index,
	immutable LowType type,
) {
	return nu!LowLocal(alloc, immutable LowLocalSource(immutable LowLocalSource.Generated(name, index)), type);
}

immutable(LowExpr) genGetArrSize(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable LowExpr arr,
) {
	return recordFieldGet(alloc, range, arr, nat64Type, 0);
}

immutable(LowExpr) genGetArrData(Alloc)(
	ref Alloc alloc,
	ref immutable FileAndRange range,
	ref immutable LowExpr arr,
	ref immutable LowType.PtrRaw elementPtrType,
) {
	return recordFieldGet(alloc, range, arr, immutable LowType(elementPtrType), 1);
}

immutable(LowType.PtrRaw) getElementPtrTypeFromArrType(
	ref immutable AllLowTypes allTypes,
	ref immutable LowType.Record arrType,
) {
	immutable LowRecord arrRecord = fullIndexDictGet(allTypes.allRecords, arrType);
	verify(size(arrRecord.fields) == 2);
	verify(symEq(name(at(arrRecord.fields, 0)), shortSymAlphaLiteral("size")));
	verify(symEq(name(at(arrRecord.fields, 1)), shortSymAlphaLiteral("data")));
	return asPtrRaw(at(arrRecord.fields, 1).type);
}

immutable(LowExpr) genSwitch(Alloc)(
	ref Alloc alloc,
	ref immutable LowType type,
	ref immutable FileAndRange range,
	ref immutable LowExpr value,
	ref immutable LowExpr[] cases,
) {
	return immutable LowExpr(type, range, immutable LowExprKind(
		immutable LowExprKind.Switch(allocate(alloc, value), cases)));
}
