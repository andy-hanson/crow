module backend.writeTypes;

@safe @nogc pure nothrow:

import model.concreteModel : ConcreteStruct, TypeSize;
import model.lowModel :
	LowExternType,
	LowField,
	LowFunPtrType,
	LowProgram,
	LowPtrCombine,
	LowRecord,
	LowType,
	LowUnion,
	matchLowTypeCombinePtr,
	PrimitiveType,
	typeSize;
import util.alloc.alloc : Alloc;
import util.col.arrUtil : every;
import util.col.fullIndexDict :
	FullIndexDict, fullIndexDictEachKey, fullIndexDictEachValue, fullIndexDictSize, makeFullIndexDict_mut;
import util.opt : none, Opt, some;
import util.util : isMultipleOf, unreachable, verify;

void writeTypes(
	ref Alloc alloc,
	scope ref immutable LowProgram program,
	scope ref immutable TypeWriters writers,
) {
	fullIndexDictEachValue!(LowType.Extern, LowExternType)(program.allExternTypes, (ref immutable LowExternType it) {
		writers.cbWriteExternWithSize(it.source, getElementAndCountForExtern(typeSize(it)));
	});

	// TODO: use a temp alloc...
	scope StructStates structStates = StructStates(
		makeFullIndexDict_mut!(LowType.FunPtr, bool)(
			alloc, fullIndexDictSize(program.allFunPtrTypes), (immutable(LowType.FunPtr)) => false),
		makeFullIndexDict_mut!(LowType.Record, StructState)(
			alloc, fullIndexDictSize(program.allRecords), (immutable(LowType.Record)) => StructState.none),
		makeFullIndexDict_mut!(LowType.Union, StructState)(
			alloc, fullIndexDictSize(program.allUnions), (immutable(LowType.Union)) => StructState.none));
	for (;;) {
		bool madeProgress = false;
		bool someIncomplete = false;
		fullIndexDictEachKey!(LowType.FunPtr, LowFunPtrType)(
			program.allFunPtrTypes,
			(immutable LowType.FunPtr funPtrIndex) {
				immutable bool curState = structStates.funPtrStates[funPtrIndex];
				if (!curState) {
					if (tryWriteFunPtrDeclaration(program, structStates, writers, funPtrIndex)) {
						structStates.funPtrStates[funPtrIndex] = true;
						madeProgress = true;
					} else
						someIncomplete = true;
				}
			});
		//TODO: each over structStates.recordStates once that's a MutFullIndexDict
		fullIndexDictEachKey!(LowType.Record, LowRecord)(
			program.allRecords,
			(immutable LowType.Record recordIndex) {
				immutable StructState curState = structStates.recordStates[recordIndex];
				if (curState != StructState.defined) {
					immutable StructState didWork = writeRecordDeclarationOrDefinition(
						program, writers, structStates, curState, recordIndex);
					if (didWork > curState) {
						structStates.recordStates[recordIndex] = didWork;
						madeProgress = true;
					} else
						someIncomplete = true;
				}
			});
		//TODO: each over structStates.unionStates once that's a MutFullIndexDict
		fullIndexDictEachKey!(LowType.Union, LowUnion)(program.allUnions, (immutable LowType.Union unionIndex) {
			immutable StructState curState = structStates.unionStates[unionIndex];
			if (curState != StructState.defined) {
				immutable StructState didWork = writeUnionDeclarationOrDefinition(
					program, writers, structStates, curState, unionIndex);
				if (didWork > curState) {
					structStates.unionStates[unionIndex] = didWork;
					madeProgress = true;
				} else
					someIncomplete = true;
			}
		});
		if (someIncomplete)
			verify(madeProgress);
		else
			break;
	}
}

struct TypeWriters {
	void delegate(immutable ConcreteStruct*) @safe @nogc pure nothrow cbDeclareStruct;
	void delegate(
		immutable ConcreteStruct*,
		immutable Opt!ElementAndCount,
	) @safe @nogc pure nothrow cbWriteExternWithSize;
	void delegate(immutable LowType.FunPtr, ref immutable LowFunPtrType) @safe @nogc pure nothrow cbWriteFunPtr;
	void delegate(immutable LowType.Record, ref immutable LowRecord) @safe @nogc pure nothrow cbWriteRecord;
	void delegate(immutable LowType.Union, ref immutable LowUnion) @safe @nogc pure nothrow cbWriteUnion;
}

struct ElementAndCount {
	immutable PrimitiveType elementType;
	immutable size_t count;
}
immutable(Opt!ElementAndCount) getElementAndCountForExtern(immutable TypeSize size) {
	switch (size.alignmentBytes) {
		case 0:
			return none!ElementAndCount;
		case 1:
			return some(immutable ElementAndCount(PrimitiveType.nat8, size.sizeBytes));
		case 2:
			verify(isMultipleOf(size.sizeBytes, 2));
			return some(immutable ElementAndCount(PrimitiveType.nat16, size.sizeBytes / 2));
		case 4:
			verify(isMultipleOf(size.sizeBytes, 4));
			return some(immutable ElementAndCount(PrimitiveType.nat32, size.sizeBytes / 4));
		case 8:
			verify(isMultipleOf(size.sizeBytes, 8));
			return some(immutable ElementAndCount(PrimitiveType.nat64, size.sizeBytes / 8));
		default:
			return unreachable!(immutable Opt!ElementAndCount);
	}
}

private:

enum StructState {
	none,
	declared,
	defined,
}

struct StructStates {
	FullIndexDict!(LowType.FunPtr, bool) funPtrStates; // No need to define, just declared or not
	FullIndexDict!(LowType.Record, StructState) recordStates;
	FullIndexDict!(LowType.Union, StructState) unionStates;
}

immutable(bool) canReferenceTypeAsValue(ref const StructStates states, immutable LowType a) =>
	matchLowTypeCombinePtr!(
		immutable bool,
		(immutable LowType.Extern) =>
			true,
		(immutable LowType.FunPtr it) =>
			states.funPtrStates[it],
		(immutable PrimitiveType) =>
			true,
		(immutable LowPtrCombine it) =>
			canReferenceTypeAsPointee(states, it.pointee),
		(immutable LowType.Record it) =>
			states.recordStates[it] == StructState.defined,
		(immutable LowType.Union it) =>
			states.unionStates[it] == StructState.defined,
	)(a);

immutable(bool) canReferenceTypeAsPointee(ref const StructStates states, immutable LowType a) =>
	matchLowTypeCombinePtr!(
		immutable bool,
		(immutable LowType.Extern) =>
			true,
		(immutable LowType.FunPtr it) =>
			states.funPtrStates[it],
		(immutable PrimitiveType) =>
			true,
		(immutable LowPtrCombine it) =>
			canReferenceTypeAsPointee(states, it.pointee),
		(immutable LowType.Record it) =>
			states.recordStates[it] != StructState.none,
		(immutable LowType.Union it) =>
			states.unionStates[it] != StructState.none,
	)(a);

immutable(StructState) writeRecordDeclarationOrDefinition(
	ref immutable LowProgram program,
	ref immutable TypeWriters writers,
	ref const StructStates structStates,
	immutable StructState prevState,
	immutable LowType.Record recordIndex,
) {
	verify(prevState != StructState.defined);
	immutable LowRecord record = program.allRecords[recordIndex];
	immutable bool canWriteFields = every!LowField(record.fields, (ref immutable LowField f) =>
		canReferenceTypeAsValue(structStates, f.type));
	if (canWriteFields) {
		writers.cbWriteRecord(recordIndex, record);
		return StructState.defined;
	} else {
		writers.cbDeclareStruct(record.source);
		return StructState.declared;
	}
}

immutable(StructState) writeUnionDeclarationOrDefinition(
	ref immutable LowProgram program,
	ref immutable TypeWriters writers,
	ref const StructStates structStates,
	immutable StructState prevState,
	immutable LowType.Union unionIndex,
) {
	verify(prevState != StructState.defined);
	immutable LowUnion union_ = program.allUnions[unionIndex];
	if (every!LowType(union_.members, (ref immutable LowType t) => canReferenceTypeAsValue(structStates, t))) {
		writers.cbWriteUnion(unionIndex, union_);
		return StructState.defined;
	} else {
		writers.cbDeclareStruct(union_.source);
		return StructState.declared;
	}
}

immutable(bool) tryWriteFunPtrDeclaration(
	ref immutable LowProgram program,
	ref const StructStates structStates,
	ref immutable TypeWriters writers,
	immutable LowType.FunPtr funPtrIndex,
) {
	immutable LowFunPtrType funPtr = program.allFunPtrTypes[funPtrIndex];
	immutable bool canDeclare =
		canReferenceTypeAsPointee(structStates, funPtr.returnType) &&
		every!LowType(funPtr.paramTypes, (ref immutable LowType it) =>
			canReferenceTypeAsPointee(structStates, it));
	if (canDeclare)
		writers.cbWriteFunPtr(funPtrIndex, funPtr);
	return canDeclare;
}
