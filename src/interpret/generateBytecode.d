module interpret.generateBytecode;

@safe @nogc pure nothrow:

import interpret.bytecode :
	ByteCode,
	ByteCodeIndex,
	ByteCodeSource,
	FileToFuns,
	FunNameAndPos,
	FunPtrToOperationPtr,
	Operation,
	Operations;
import interpret.bytecodeWriter :
	ByteCodeWriter,
	fillDelayedCall,
	fillDelayedFunPtr,
	finishOperations,
	getNextStackEntry,
	newByteCodeWriter,
	nextByteCodeIndex,
	setNextStackEntry,
	setStackEntryAfterParameters,
	StackEntries,
	StackEntry,
	writeCallFunPtrExtern,
	writeLongjmp,
	writePushConstant,
	writeRead,
	writeReturn,
	writeSetjmp;
import interpret.extern_ :
	DynCallType, DynCallSig, ExternFunPtrsForAllLibraries, FunPtr, FunPtrInputs, MakeSyntheticFunPtrs;
import interpret.funToReferences :
	eachFunPtr,
	finishAt,
	FunPtrReferences,
	FunPtrTypeToDynCallSig,
	FunReferences,
	FunToReferences,
	initFunToReferences;
import interpret.generateExpr : generateFunFromExpr;
import interpret.generateText :
	generateText, generateThreadLocalsInfo, TextAndInfo, TextIndex, TextInfo, ThreadLocalsInfo;
import interpret.runBytecode : maxThreadLocalsSizeWords;
import model.concreteModel : ConcreteStructSource, name;
import model.lowModel :
	LowField,
	LowFun,
	LowFunBody,
	LowFunExprBody,
	lowFunRange,
	LowFunIndex,
	LowFunPtrType,
	LowLocal,
	LowProgram,
	LowType,
	LowUnion,
	name,
	PrimitiveType,
	typeSize;
import model.model : FunDecl, Module, name, Program, range;
import model.typeLayout : nStackEntriesForType, typeSizeBytes;
import util.alloc.alloc : Alloc, TempAlloc;
import util.col.arr : castImmutable;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : map;
import util.col.dict : Dict, KeyValuePair, mustGetAt, zipToDict;
import util.col.fullIndexDict :
	FullIndexDict, fullIndexDictEach, fullIndexDictOfArr, fullIndexDictSize, mapFullIndexDict;
import util.col.mutMaxArr : initializeMutMaxArr, MutMaxArr, push, tempAsArr;
import util.opt : force, has, Opt;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.ptr : ptrTrustMe;
import util.sourceRange : FileIndex;
import util.sym : AllSymbols, Sym, sym;
import util.util : todo, unreachable, verify;
import util.writer : Writer;

ByteCode generateBytecode(
	ref Alloc alloc,
	scope ref Perf perf,
	in AllSymbols allSymbols,
	in Program modelProgram,
	in LowProgram program,
	ExternFunPtrsForAllLibraries externFunPtrs,
	in MakeSyntheticFunPtrs makeSyntheticFunPtrs,
) {
	//TODO: use a temp alloc for 2nd arg
	return withMeasure!(ByteCode, () =>
		generateBytecodeInner(alloc, alloc, allSymbols, modelProgram, program, externFunPtrs, makeSyntheticFunPtrs)
	)(alloc, perf, PerfMeasure.generateBytecode);
}

private ByteCode generateBytecodeInner(
	ref Alloc codeAlloc,
	ref TempAlloc tempAlloc,
	in AllSymbols allSymbols,
	in Program modelProgram,
	in LowProgram program,
	ExternFunPtrsForAllLibraries externFunPtrs,
	in MakeSyntheticFunPtrs cbMakeSyntheticFunPtrs,
) {
	FunPtrTypeToDynCallSig funPtrTypeToDynCallSig =
		mapFullIndexDict!(LowType.FunPtr, DynCallSig, LowFunPtrType)(
			codeAlloc,
			program.allFunPtrTypes,
			(LowType.FunPtr, scope ref LowFunPtrType x) =>
				funPtrDynCallSig(codeAlloc, program, x));

	FunToReferences funToReferences =
		initFunToReferences(tempAlloc, funPtrTypeToDynCallSig, fullIndexDictSize(program.allFuns));
	TextAndInfo text = generateText(codeAlloc, tempAlloc, program, funToReferences);
	ThreadLocalsInfo threadLocals = generateThreadLocalsInfo(codeAlloc, program);
	ByteCodeWriter writer = newByteCodeWriter(ptrTrustMe(codeAlloc));

	immutable FullIndexDict!(LowFunIndex, ByteCodeIndex) funToDefinition =
		mapFullIndexDict!(LowFunIndex, ByteCodeIndex, LowFun)(
			tempAlloc,
			program.allFuns,
			(LowFunIndex funIndex, scope ref LowFun fun) {
				ByteCodeIndex funPos = nextByteCodeIndex(writer);
				generateBytecodeForFun(
					tempAlloc,
					writer,
					allSymbols,
					funToReferences,
					text.info,
					threadLocals,
					program,
					externFunPtrs,
					funIndex,
					fun);
				return funPos;
		});

	Operations operations = finishOperations(writer);

	SyntheticFunPtrs syntheticFunPtrs = makeSyntheticFunPtrs(
		codeAlloc, allSymbols, program, operations.byteCode, funToDefinition, funToReferences, cbMakeSyntheticFunPtrs);

	fullIndexDictEach!(LowFunIndex, ByteCodeIndex)(
		funToDefinition,
		(LowFunIndex funIndex, ref ByteCodeIndex definitionIndex) @trusted {
			Operation* definition = &operations.byteCode[definitionIndex.index];
			FunReferences references = finishAt(tempAlloc, funToReferences, funIndex);
			foreach (ByteCodeIndex reference; references.calls)
				fillDelayedCall(operations, reference, definition);
			if (has(references.ptrRefs)) {
				FunPtrReferences ptrRefs = force(references.ptrRefs);
				FunPtr funPtr = mustGetAt(syntheticFunPtrs.funToFunPtr, funIndex);
				foreach (TextIndex reference; ptrRefs.textRefs)
					*(cast(ulong*) &text.text[reference.index]) = cast(ulong) funPtr.fn;
				foreach (ByteCodeIndex reference; ptrRefs.funPtrRefs)
					fillDelayedFunPtr(operations, reference, funPtr);
			}
		});

	return ByteCode(
		operations,
		syntheticFunPtrs.funPtrToOperationPtr,
		fileToFuns(codeAlloc, allSymbols, modelProgram),
		castImmutable(text.text),
		threadLocals.totalSizeWords,
		funToDefinition[program.main]);
}

private:

SyntheticFunPtrs makeSyntheticFunPtrs(
	ref Alloc alloc,
	in AllSymbols allSymbols,
	in LowProgram program,
	Operation[] byteCode,
	in FunToDefinition funToDefinition,
	in FunToReferences funToReferences,
	in MakeSyntheticFunPtrs cbMakeSyntheticFunPtrs,
) {
	ArrBuilder!FunPtrInputs inputsBuilder;
	eachFunPtr(funToReferences, (LowFunIndex funIndex, DynCallSig sig) {
		add(alloc, inputsBuilder, FunPtrInputs(funIndex, sig, &byteCode[funToDefinition[funIndex].index]));
	});
	FunPtrInputs[] inputs = finishArr(alloc, inputsBuilder);
	FunPtr[] funPtrs = cbMakeSyntheticFunPtrs(inputs);
	FunToFunPtr funToFunPtr = zipToDict!(LowFunIndex, FunPtr, FunPtrInputs, FunPtr)(
		alloc, inputs, funPtrs, (ref FunPtrInputs inputs, ref FunPtr funPtr) =>
			immutable KeyValuePair!(LowFunIndex, FunPtr)(inputs.funIndex, funPtr));
	FunPtrToOperationPtr funPtrToOperationPtr = zipToDict!(FunPtr, Operation*, FunPtrInputs, FunPtr)(
		alloc, inputs, funPtrs, (ref FunPtrInputs inputs, ref FunPtr funPtr) =>
			immutable KeyValuePair!(FunPtr, immutable Operation*)(funPtr, inputs.operationPtr));
	return SyntheticFunPtrs(funToFunPtr, funPtrToOperationPtr);
}

immutable struct SyntheticFunPtrs {
	FunToFunPtr funToFunPtr;
	FunPtrToOperationPtr funPtrToOperationPtr;
}
alias FunToFunPtr = Dict!(LowFunIndex, FunPtr);
alias FunToDefinition = immutable FullIndexDict!(LowFunIndex, ByteCodeIndex);

DynCallSig funPtrDynCallSig(ref Alloc alloc, in LowProgram program, in LowFunPtrType a) {
	ArrBuilder!DynCallType sigTypes;
	add(alloc, sigTypes, toDynCallType(a.returnType));
	foreach (ref LowType x; a.paramTypes)
		toDynCallTypes(program, x, (DynCallType x) {
			add(alloc, sigTypes, x);
		});
	return DynCallSig(finishArr(alloc, sigTypes));
}

FileToFuns fileToFuns(ref Alloc alloc, in AllSymbols allSymbols, in Program program) {
	immutable FullIndexDict!(FileIndex, Module) modulesDict =
		fullIndexDictOfArr!(FileIndex, Module)(program.allModules);
	return mapFullIndexDict!(FileIndex, FunNameAndPos[], Module)(
		alloc,
		modulesDict,
		(FileIndex, ref Module module_) =>
			map(alloc, module_.funs, (ref FunDecl it) =>
				FunNameAndPos(it.name, it.fileAndPos.pos)));
}

void generateBytecodeForFun(
	ref TempAlloc tempAlloc,
	scope ref ByteCodeWriter writer,
	in AllSymbols allSymbols,
	ref FunToReferences funToReferences,
	in TextInfo textInfo,
	in ThreadLocalsInfo threadLocalsInfo,
	in LowProgram program,
	ExternFunPtrsForAllLibraries externFunPtrs,
	LowFunIndex funIndex,
	in LowFun fun,
) {
	verify(threadLocalsInfo.totalSizeWords < maxThreadLocalsSizeWords);

	debug {
		if (false) {
			import util.writer : finishWriterToCStr;
			import core.stdc.stdio : printf;
			import interpret.debugging : writeFunName;
			Writer w = Writer(ptrTrustMe(tempAlloc));
			writeFunName(w, allSymbols, todo!(Program)("!"), program, fun);
			printf("generateBytecodeForFun %s\n", finishWriterToCStr(w));
		}
	}

	size_t stackEntry = 0;
	StackEntries[] parameters = map(tempAlloc, fun.params, (ref LowLocal it) {
		StackEntry start = StackEntry(stackEntry);
		size_t n = nStackEntriesForType(program, it.type);
		stackEntry += n;
		return StackEntries(start, n);
	});
	setStackEntryAfterParameters(writer, StackEntry(stackEntry));
	size_t returnEntries = nStackEntriesForType(program, fun.returnType);
	ByteCodeSource source = ByteCodeSource(funIndex, lowFunRange(fun, allSymbols).range.start);

	fun.body_.matchIn!void(
		(in LowFunBody.Extern body_) {
			generateExternCall(writer, allSymbols, program, funIndex, fun, body_, externFunPtrs);
			writeReturn(writer, source);
		},
		(in LowFunExprBody body_) {
			generateFunFromExpr(
				tempAlloc, writer, allSymbols, program, textInfo, threadLocalsInfo, funIndex,
				funToReferences, fun.params, parameters, returnEntries, body_);
		});
	verify(getNextStackEntry(writer).entry == returnEntries);
	setNextStackEntry(writer, StackEntry(0));
}

void generateExternCall(
	ref ByteCodeWriter writer,
	in AllSymbols allSymbols,
	in LowProgram program,
	LowFunIndex funIndex,
	in LowFun fun,
	in LowFunBody.Extern a,
	ExternFunPtrsForAllLibraries externFunPtrs,
) {
	ByteCodeSource source = ByteCodeSource(funIndex, lowFunRange(fun, allSymbols).range.start);
	Opt!Sym optName = name(fun);
	Sym name = force(optName);
	switch (name.value) {
		case sym!"longjmp".value:
			writeLongjmp(writer, source);
			break;
		case sym!"setjmp".value:
			writeSetjmp(writer, source);
			break;
		default:
			FunPtr funPtr = mustGetAt(mustGetAt(externFunPtrs, a.libraryName), name);
			if (a.isGlobal)
				generateExternGetGlobal(writer, source, program, fun.returnType, funPtr.fn);
			else
				generateExternCallFunPtr(writer, source, program, fun, funPtr);
			break;
	}
	writeReturn(writer, source);
}

void generateExternGetGlobal(
	scope ref ByteCodeWriter writer,
	ByteCodeSource source,
	in LowProgram program,
	in LowType type,
	// TODO: not really immutable
	immutable void* ptr,
) {
	writePushConstant(writer, source, cast(ulong) ptr);
	writeRead(writer, source, 0, typeSizeBytes(program, type));
}

void generateExternCallFunPtr(
	scope ref ByteCodeWriter writer,
	ByteCodeSource source,
	in LowProgram program,
	in LowFun fun,
	FunPtr funPtr,
) {
	MutMaxArr!(16, DynCallType) sigTypes = void;
	initializeMutMaxArr(sigTypes);
	push(sigTypes, toDynCallType(fun.returnType));
	foreach (ref LowLocal x; fun.params)
		toDynCallTypes(program, x.type, (DynCallType x) {
		push(sigTypes, x);
	});
	writeCallFunPtrExtern(writer, source, funPtr, DynCallSig(tempAsArr(sigTypes)));
}

DynCallType toDynCallType(in LowType a) =>
	a.matchIn!DynCallType(
		(in LowType.Extern) =>
			todo!DynCallType("!"),
		(in LowType.FunPtr) =>
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
			unreachable!DynCallType,
		(in LowType.Union) =>
			unreachable!DynCallType);

DynCallType primitiveToDynCallType(PrimitiveType a) {
	final switch (a) {
		case PrimitiveType.bool_:
			return DynCallType.bool_;
		case PrimitiveType.char8:
			return DynCallType.char8;
		case PrimitiveType.float32:
			return DynCallType.float32;
		case PrimitiveType.float64:
			return DynCallType.float64;
		case PrimitiveType.int8:
			return DynCallType.int8;
		case PrimitiveType.int16:
			return DynCallType.int16;
		case PrimitiveType.int32:
			return DynCallType.int32;
		case PrimitiveType.int64:
			return DynCallType.int64;
		case PrimitiveType.nat8:
			return DynCallType.nat8;
		case PrimitiveType.nat16:
			return DynCallType.nat16;
		case PrimitiveType.nat32:
			return DynCallType.nat32;
		case PrimitiveType.nat64:
			return DynCallType.nat64;
		case PrimitiveType.void_:
			return DynCallType.void_;
	}
}

void toDynCallTypes(in LowProgram program, in LowType a, in void delegate(DynCallType) @safe @nogc pure nothrow cb) {
	if (a.isA!(LowType.Record)) {
		foreach (LowField field; program.allRecords[a.as!(LowType.Record)].fields)
			toDynCallTypes(program, field.type, cb);
	} else if (a.isA!(LowType.Union)) {
		// This should only happen for the 'str[]' in 'main'
		LowUnion u = program.allUnions[a.as!(LowType.Union)];
		verify(name(*u.source.source.as!(ConcreteStructSource.Inst).inst) == sym!"node");
		size_t sizeWords = 3;
		verify(typeSize(u).sizeBytes == ulong.sizeof * sizeWords);
		foreach (size_t i; 0 .. sizeWords)
			cb(DynCallType.nat64);
	} else
		cb(toDynCallType(a));
}
