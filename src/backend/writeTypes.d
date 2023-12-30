module backend.writeTypes;

@safe @nogc pure nothrow:

import model.concreteModel : ConcreteStruct, TypeSize;
import model.lowModel :
	LowExternType,
	LowField,
	LowFunPointerType,
	LowProgram,
	LowPtrCombine,
	LowRecord,
	LowType,
	LowUnion,
	PrimitiveType,
	typeSize;
import util.alloc.alloc : Alloc;
import util.col.array : every;
import util.col.fullIndexMap :
	FullIndexMap, fullIndexMapEachKey, fullIndexMapSize, makeFullIndexMap_mut;
import util.opt : none, Opt, some;
import util.util : isMultipleOf;

void writeTypes(ref Alloc alloc, in LowProgram program, in TypeWriters writers) {
	foreach (ref LowExternType x; program.allExternTypes)
		writers.cbWriteExternWithSize(x.source, getElementAndCountForExtern(typeSize(x)));

	// TODO: use a temp alloc...
	scope StructStates structStates = StructStates(
		makeFullIndexMap_mut!(LowType.FunPointer, bool)(
			alloc, fullIndexMapSize(program.allFunPointerTypes), (LowType.FunPointer) => false),
		makeFullIndexMap_mut!(LowType.Record, StructState)(
			alloc, fullIndexMapSize(program.allRecords), (LowType.Record) => StructState.none),
		makeFullIndexMap_mut!(LowType.Union, StructState)(
			alloc, fullIndexMapSize(program.allUnions), (LowType.Union) => StructState.none));
	for (;;) {
		bool madeProgress = false;
		bool someIncomplete = false;
		fullIndexMapEachKey!(LowType.FunPointer, LowFunPointerType)(
			program.allFunPointerTypes,
			(LowType.FunPointer funPtrIndex) {
				bool curState = structStates.funPtrStates[funPtrIndex];
				if (!curState) {
					if (tryWriteFunPointerDeclaration(program, structStates, writers, funPtrIndex)) {
						structStates.funPtrStates[funPtrIndex] = true;
						madeProgress = true;
					} else
						someIncomplete = true;
				}
			});
		//TODO: each over structStates.recordStates once that's a MutFullIndexMap
		fullIndexMapEachKey!(LowType.Record, LowRecord)(
			program.allRecords,
			(LowType.Record recordIndex) {
				StructState curState = structStates.recordStates[recordIndex];
				if (curState != StructState.defined) {
					StructState didWork = writeRecordDeclarationOrDefinition(
						program, writers, structStates, curState, recordIndex);
					if (didWork > curState) {
						structStates.recordStates[recordIndex] = didWork;
						madeProgress = true;
					} else
						someIncomplete = true;
				}
			});
		//TODO: each over structStates.unionStates once that's a MutFullIndexMap
		fullIndexMapEachKey!(LowType.Union, LowUnion)(program.allUnions, (LowType.Union unionIndex) {
			StructState curState = structStates.unionStates[unionIndex];
			if (curState != StructState.defined) {
				StructState didWork = writeUnionDeclarationOrDefinition(
					program, writers, structStates, curState, unionIndex);
				if (didWork > curState) {
					structStates.unionStates[unionIndex] = didWork;
					madeProgress = true;
				} else
					someIncomplete = true;
			}
		});
		if (someIncomplete)
			assert(madeProgress);
		else
			break;
	}
}

immutable struct TypeWriters {
	void delegate(ConcreteStruct*) @safe @nogc pure nothrow cbDeclareStruct;
	void delegate(ConcreteStruct*, in Opt!ElementAndCount) @safe @nogc pure nothrow cbWriteExternWithSize;
	void delegate(LowType.FunPointer, in LowFunPointerType) @safe @nogc pure nothrow cbWriteFunPointer;
	void delegate(LowType.Record, in LowRecord) @safe @nogc pure nothrow cbWriteRecord;
	void delegate(LowType.Union, in LowUnion) @safe @nogc pure nothrow cbWriteUnion;
}

immutable struct ElementAndCount {
	PrimitiveType elementType;
	size_t count;
}
Opt!ElementAndCount getElementAndCountForExtern(TypeSize size) {
	switch (size.alignmentBytes) {
		case 0:
			return none!ElementAndCount;
		case 1:
			return some(ElementAndCount(PrimitiveType.nat8, size.sizeBytes));
		case 2:
			assert(isMultipleOf(size.sizeBytes, 2));
			return some(ElementAndCount(PrimitiveType.nat16, size.sizeBytes / 2));
		case 4:
			assert(isMultipleOf(size.sizeBytes, 4));
			return some(ElementAndCount(PrimitiveType.nat32, size.sizeBytes / 4));
		case 8:
			assert(isMultipleOf(size.sizeBytes, 8));
			return some(ElementAndCount(PrimitiveType.nat64, size.sizeBytes / 8));
		default:
			assert(false);
	}
}

private:

enum StructState {
	none,
	declared,
	defined,
}

struct StructStates {
	FullIndexMap!(LowType.FunPointer, bool) funPtrStates; // No need to define, just declared or not
	FullIndexMap!(LowType.Record, StructState) recordStates;
	FullIndexMap!(LowType.Union, StructState) unionStates;
}

bool canReferenceTypeAsValue(in StructStates states, in LowType a) =>
	a.combinePointer.match!bool(
		(LowType.Extern) =>
			true,
		(LowType.FunPointer it) =>
			states.funPtrStates[it],
		(PrimitiveType) =>
			true,
		(LowPtrCombine it) =>
			canReferenceTypeAsPointee(states, it.pointee),
		(LowType.Record it) =>
			states.recordStates[it] == StructState.defined,
		(LowType.Union it) =>
			states.unionStates[it] == StructState.defined);

bool canReferenceTypeAsPointee(in StructStates states, in LowType a) =>
	a.combinePointer.match!bool(
		(LowType.Extern) =>
			true,
		(LowType.FunPointer it) =>
			states.funPtrStates[it],
		(PrimitiveType) =>
			true,
		(LowPtrCombine it) =>
			canReferenceTypeAsPointee(states, it.pointee),
		(LowType.Record it) =>
			states.recordStates[it] != StructState.none,
		(LowType.Union it) =>
			states.unionStates[it] != StructState.none);

StructState writeRecordDeclarationOrDefinition(
	in LowProgram program,
	in TypeWriters writers,
	in StructStates structStates,
	StructState prevState,
	LowType.Record recordIndex,
) {
	assert(prevState != StructState.defined);
	LowRecord record = program.allRecords[recordIndex];
	bool canWriteFields = every!LowField(record.fields, (in LowField f) =>
		canReferenceTypeAsValue(structStates, f.type));
	if (canWriteFields) {
		writers.cbWriteRecord(recordIndex, record);
		return StructState.defined;
	} else {
		writers.cbDeclareStruct(record.source);
		return StructState.declared;
	}
}

StructState writeUnionDeclarationOrDefinition(
	in LowProgram program,
	in TypeWriters writers,
	in StructStates structStates,
	StructState prevState,
	LowType.Union unionIndex,
) {
	assert(prevState != StructState.defined);
	LowUnion union_ = program.allUnions[unionIndex];
	if (every!LowType(union_.members, (in LowType t) => canReferenceTypeAsValue(structStates, t))) {
		writers.cbWriteUnion(unionIndex, union_);
		return StructState.defined;
	} else {
		writers.cbDeclareStruct(union_.source);
		return StructState.declared;
	}
}

bool tryWriteFunPointerDeclaration(
	in LowProgram program,
	in StructStates structStates,
	in TypeWriters writers,
	LowType.FunPointer funPtrIndex,
) {
	LowFunPointerType funPtr = program.allFunPointerTypes[funPtrIndex];
	bool canDeclare =
		canReferenceTypeAsPointee(structStates, funPtr.returnType) &&
		every!LowType(funPtr.paramTypes, (in LowType it) =>
			canReferenceTypeAsPointee(structStates, it));
	if (canDeclare)
		writers.cbWriteFunPointer(funPtrIndex, funPtr);
	return canDeclare;
}
