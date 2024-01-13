module interpret.generateBytecode;

@safe @nogc pure nothrow:

import interpret.bytecode :
	ByteCode, ByteCodeIndex, ByteCodeSource, FunPointerToOperationPointer, Operation, Operations;
import interpret.bytecodeWriter :
	ByteCodeWriter,
	fillDelayedCall,
	fillDelayedFunPointer,
	finishOperations,
	getNextStackEntry,
	newByteCodeWriter,
	nextByteCodeIndex,
	setNextStackEntry,
	setStackEntryAfterParameters,
	StackEntries,
	StackEntry,
	writeCallFunPointerExtern,
	writeLongjmp,
	writeReturn,
	writeSetjmp;
import interpret.extern_ :
	DynCallType, DynCallSig, ExternPointersForAllLibraries, FunPointer, FunPointerInputs, MakeSyntheticFunPointers;
import interpret.funToReferences :
	eachFunPointer,
	finishAt,
	FunPointerReferences,
	FunPointerTypeToDynCallSig,
	FunReferences,
	FunToReferences,
	initFunToReferences;
import interpret.generateExpr : generateFunFromExpr, maxGlobalsSizeWords;
import interpret.generateText :
	generateText, generateVarsInfo, TextAndInfo, TextIndex, TextInfo, VarsInfo;
import interpret.runBytecode : maxThreadLocalsSizeWords;
import model.concreteModel : ConcreteStructSource, name;
import model.lowModel :
	LowField,
	LowFun,
	LowFunBody,
	LowFunExprBody,
	lowFunRange,
	LowFunIndex,
	LowFunPointerType,
	LowLocal,
	LowProgram,
	LowType,
	LowUnion,
	name,
	PrimitiveType,
	typeSize;
import model.model : Program, VarKind;
import model.typeLayout : nStackEntriesForType;
import util.alloc.alloc : Alloc, TempAlloc;
import util.col.array : map;
import util.col.arrayBuilder : add, ArrayBuilder, finish;
import util.col.map : Map, KeyValuePair, mustGet, zipToMap;
import util.col.fullIndexMap : FullIndexMap, fullIndexMapEach, fullIndexMapSize, mapFullIndexMap;
import util.col.mutMaxArr : asTemporaryArray, initializeMutMaxArr, MutMaxArr, push;
import util.opt : force, has, Opt;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.symbol : AllSymbols, Symbol, symbol;
import util.util : castImmutable, enumConvert, ptrTrustMe, todo;

ByteCode generateBytecode(
	scope ref Perf perf,
	ref Alloc alloc,
	in AllSymbols allSymbols,
	in Program modelProgram,
	in LowProgram program,
	ExternPointersForAllLibraries externPointers,
	in MakeSyntheticFunPointers makeSyntheticFunPointers,
) {
	//TODO: use a temp alloc for 2nd arg
	return withMeasure!(ByteCode, () =>
		generateBytecodeInner(alloc, alloc, allSymbols, modelProgram, program, externPointers, makeSyntheticFunPointers)
	)(perf, alloc, PerfMeasure.generateBytecode);
}

private ByteCode generateBytecodeInner(
	ref Alloc codeAlloc,
	ref TempAlloc tempAlloc,
	in AllSymbols allSymbols,
	in Program modelProgram,
	in LowProgram program,
	ExternPointersForAllLibraries externPointers,
	in MakeSyntheticFunPointers cbMakeSyntheticFunPointers,
) {
	FunPointerTypeToDynCallSig funPtrTypeToDynCallSig =
		mapFullIndexMap!(LowType.FunPointer, DynCallSig, LowFunPointerType)(
			codeAlloc,
			program.allFunPointerTypes,
			(LowType.FunPointer, in LowFunPointerType x) =>
				funPtrDynCallSig(codeAlloc, program, x));

	FunToReferences funToReferences =
		initFunToReferences(tempAlloc, funPtrTypeToDynCallSig, fullIndexMapSize(program.allFuns));
	TextAndInfo text = generateText(codeAlloc, tempAlloc, program, funToReferences);
	VarsInfo vars = generateVarsInfo(codeAlloc, program);
	ByteCodeWriter writer = newByteCodeWriter(ptrTrustMe(codeAlloc));

	immutable FullIndexMap!(LowFunIndex, ByteCodeIndex) funToDefinition =
		mapFullIndexMap!(LowFunIndex, ByteCodeIndex, LowFun)(
			tempAlloc,
			program.allFuns,
			(LowFunIndex funIndex, in LowFun fun) {
				ByteCodeIndex funPos = nextByteCodeIndex(writer);
				generateBytecodeForFun(
					tempAlloc,
					writer,
					allSymbols,
					funToReferences,
					text.info,
					vars,
					modelProgram,
					program,
					externPointers,
					funIndex,
					fun);
				return funPos;
		});

	Operations operations = finishOperations(writer);

	SyntheticFunPointers syntheticFunPointers = makeSyntheticFunPointers(
		codeAlloc, allSymbols, program,
		operations.byteCode, funToDefinition, funToReferences, cbMakeSyntheticFunPointers);

	fullIndexMapEach!(LowFunIndex, ByteCodeIndex)(
		funToDefinition,
		(LowFunIndex funIndex, ref ByteCodeIndex definitionIndex) @trusted {
			Operation* definition = &operations.byteCode[definitionIndex.index];
			FunReferences references = finishAt(tempAlloc, funToReferences, funIndex);
			foreach (ByteCodeIndex reference; references.calls)
				fillDelayedCall(operations, reference, definition);
			if (has(references.ptrRefs)) {
				FunPointerReferences ptrRefs = force(references.ptrRefs);
				FunPointer funPtr = mustGet(syntheticFunPointers.funToFunPointer, funIndex);
				foreach (TextIndex reference; ptrRefs.textRefs)
					*(cast(ulong*) &text.text[reference.index]) = funPtr.asUlong;
				foreach (ByteCodeIndex reference; ptrRefs.funPtrRefs)
					fillDelayedFunPointer(operations, reference, funPtr);
			}
		});

	return ByteCode(
		operations,
		syntheticFunPointers.funPointerToOperationPointer,
		castImmutable(text.text),
		vars.totalSizeWords,
		funToDefinition[program.main]);
}

private:

SyntheticFunPointers makeSyntheticFunPointers(
	ref Alloc alloc,
	in AllSymbols allSymbols,
	in LowProgram program,
	Operation[] byteCode,
	in FunToDefinition funToDefinition,
	in FunToReferences funToReferences,
	in MakeSyntheticFunPointers cbMakeSyntheticFunPointers,
) {
	ArrayBuilder!FunPointerInputs inputsBuilder;
	eachFunPointer(funToReferences, (LowFunIndex funIndex, DynCallSig sig) {
		add(alloc, inputsBuilder, FunPointerInputs(funIndex, sig, &byteCode[funToDefinition[funIndex].index]));
	});
	FunPointerInputs[] inputs = finish(alloc, inputsBuilder);
	FunPointer[] funPtrs = cbMakeSyntheticFunPointers(inputs);
	FunToFunPointer funToFunPointer = zipToMap!(LowFunIndex, FunPointer, FunPointerInputs, FunPointer)(
		alloc, inputs, funPtrs, (ref FunPointerInputs inputs, ref FunPointer funPtr) =>
			immutable KeyValuePair!(LowFunIndex, FunPointer)(inputs.funIndex, funPtr));
	FunPointerToOperationPointer funToOp = zipToMap!(FunPointer, Operation*, FunPointerInputs, FunPointer)(
		alloc, inputs, funPtrs, (ref FunPointerInputs inputs, ref FunPointer funPtr) =>
			immutable KeyValuePair!(FunPointer, immutable Operation*)(funPtr, inputs.operationPtr));
	return SyntheticFunPointers(funToFunPointer, funToOp);
}

immutable struct SyntheticFunPointers {
	FunToFunPointer funToFunPointer;
	FunPointerToOperationPointer funPointerToOperationPointer;
}
alias FunToFunPointer = Map!(LowFunIndex, FunPointer);
alias FunToDefinition = immutable FullIndexMap!(LowFunIndex, ByteCodeIndex);

DynCallSig funPtrDynCallSig(ref Alloc alloc, in LowProgram program, in LowFunPointerType a) {
	ArrayBuilder!DynCallType sigTypes;
	add(alloc, sigTypes, toDynCallType(a.returnType));
	foreach (ref LowType x; a.paramTypes)
		toDynCallTypes(program, x, (DynCallType x) {
			add(alloc, sigTypes, x);
		});
	return DynCallSig(finish(alloc, sigTypes));
}

void generateBytecodeForFun(
	ref TempAlloc tempAlloc,
	scope ref ByteCodeWriter writer,
	in AllSymbols allSymbols,
	ref FunToReferences funToReferences,
	in TextInfo textInfo,
	in VarsInfo varsInfo,
	in Program modelProgram,
	in LowProgram program,
	ExternPointersForAllLibraries externPointers,
	LowFunIndex funIndex,
	in LowFun fun,
) {
	assert(varsInfo.totalSizeWords[VarKind.global] < maxGlobalsSizeWords);
	assert(varsInfo.totalSizeWords[VarKind.threadLocal] < maxThreadLocalsSizeWords);

	size_t stackEntry = 0;
	StackEntries[] parameters = map(tempAlloc, fun.params, (ref LowLocal it) {
		StackEntry start = StackEntry(stackEntry);
		size_t n = nStackEntriesForType(program, it.type);
		stackEntry += n;
		return StackEntries(start, n);
	});
	setStackEntryAfterParameters(writer, StackEntry(stackEntry));
	size_t returnEntries = nStackEntriesForType(program, fun.returnType);
	ByteCodeSource source = ByteCodeSource(funIndex, lowFunRange(fun).range.start);

	fun.body_.matchIn!void(
		(in LowFunBody.Extern body_) {
			generateExternCall(writer, allSymbols, program, funIndex, fun, body_, externPointers);
			writeReturn(writer, source);
		},
		(in LowFunExprBody body_) {
			generateFunFromExpr(
				tempAlloc, writer, allSymbols, modelProgram, program, textInfo, varsInfo, externPointers, funIndex,
				funToReferences, fun.params, parameters, returnEntries, body_);
		});
	assert(getNextStackEntry(writer).entry == returnEntries);
	setNextStackEntry(writer, StackEntry(0));
}

void generateExternCall(
	ref ByteCodeWriter writer,
	in AllSymbols allSymbols,
	in LowProgram program,
	LowFunIndex funIndex,
	in LowFun fun,
	in LowFunBody.Extern a,
	ExternPointersForAllLibraries externPointers,
) {
	ByteCodeSource source = ByteCodeSource(funIndex, lowFunRange(fun).range.start);
	Opt!Symbol optName = name(fun);
	Symbol name = force(optName);
	switch (name.value) {
		case symbol!"longjmp".value:
			writeLongjmp(writer, source);
			break;
		case symbol!"setjmp".value:
			writeSetjmp(writer, source);
			break;
		default:
			generateExternCallFunPointer(
				writer, source, program, fun, mustGet(mustGet(externPointers, a.libraryName), name).asFunPointer);
			break;
	}
	writeReturn(writer, source);
}

void generateExternCallFunPointer(
	scope ref ByteCodeWriter writer,
	ByteCodeSource source,
	in LowProgram program,
	in LowFun fun,
	FunPointer funPtr,
) {
	MutMaxArr!(16, DynCallType) sigTypes = void;
	initializeMutMaxArr(sigTypes);
	push(sigTypes, toDynCallType(fun.returnType));
	foreach (ref LowLocal x; fun.params)
		toDynCallTypes(program, x.type, (DynCallType x) {
		push(sigTypes, x);
	});
	writeCallFunPointerExtern(writer, source, funPtr, DynCallSig(asTemporaryArray(sigTypes)));
}

DynCallType toDynCallType(in LowType a) =>
	a.matchIn!DynCallType(
		(in LowType.Extern) =>
			todo!DynCallType("!"),
		(in LowType.FunPointer) =>
			DynCallType.pointer,
		(in PrimitiveType x) =>
			primitiveToDynCallType(x),
		(in LowType.PtrGc) =>
			DynCallType.pointer,
		(in LowType.PtrRawConst) =>
			DynCallType.pointer,
		(in LowType.PtrRawMut) =>
			DynCallType.pointer,
		(in LowType.Record) =>
			assert(false),
		(in LowType.Union) =>
			assert(false));

DynCallType primitiveToDynCallType(PrimitiveType a) =>
	enumConvert!DynCallType(a);

void toDynCallTypes(in LowProgram program, in LowType a, in void delegate(DynCallType) @safe @nogc pure nothrow cb) {
	if (a.isA!(LowType.Record)) {
		foreach (LowField field; program.allRecords[a.as!(LowType.Record)].fields)
			toDynCallTypes(program, field.type, cb);
	} else if (a.isA!(LowType.Union)) {
		// TODO: Hardcoded support for the 'string[]' in 'main'. Support more types.
		LowUnion u = program.allUnions[a.as!(LowType.Union)];
		assert(u.source.source.as!(ConcreteStructSource.Inst).inst.decl.name == symbol!"node");
		size_t sizeWords = 3;
		assert(typeSize(u).sizeBytes == ulong.sizeof * sizeWords);
		foreach (size_t i; 0 .. sizeWords)
			cb(DynCallType.nat64);
	} else
		cb(toDynCallType(a));
}
