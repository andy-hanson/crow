module interpret.generateBytecode;

@safe @nogc pure nothrow:

import interpret.bytecode :
	ByteCode,
	ByteCodeIndex,
	ByteCodeSource,
	castImmutable,
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
import model.concreteModel : asInst, name;
import model.lowModel :
	asRecordType,
	asUnionType,
	isRecordType,
	isUnionType,
	LowField,
	LowFun,
	LowFunBody,
	LowFunExprBody,
	lowFunRange,
	LowFunIndex,
	LowFunPtrType,
	LowParam,
	LowProgram,
	LowType,
	LowUnion,
	matchLowFunBody,
	matchLowType,
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
import util.util : unreachable, verify;
import util.writer : Writer;

immutable(ByteCode) generateBytecode(
	ref Alloc alloc,
	scope ref Perf perf,
	ref const AllSymbols allSymbols,
	scope ref immutable Program modelProgram,
	ref immutable LowProgram program,
	scope immutable ExternFunPtrsForAllLibraries externFunPtrs,
	scope immutable MakeSyntheticFunPtrs makeSyntheticFunPtrs,
) {
	//TODO: use a temp alloc for 2nd arg
	return withMeasure!(immutable ByteCode, () =>
		generateBytecodeInner(alloc, alloc, allSymbols, modelProgram, program, externFunPtrs, makeSyntheticFunPtrs)
	)(alloc, perf, PerfMeasure.generateBytecode);
}

private immutable(ByteCode) generateBytecodeInner(
	ref Alloc codeAlloc,
	ref TempAlloc tempAlloc,
	ref const AllSymbols allSymbols,
	scope ref immutable Program modelProgram,
	ref immutable LowProgram program,
	scope immutable ExternFunPtrsForAllLibraries externFunPtrs,
	scope immutable MakeSyntheticFunPtrs cbMakeSyntheticFunPtrs,
) {
	immutable FunPtrTypeToDynCallSig funPtrTypeToDynCallSig =
		mapFullIndexDict!(LowType.FunPtr, DynCallSig, LowFunPtrType)(
			codeAlloc,
			program.allFunPtrTypes,
			(immutable(LowType.FunPtr), scope ref immutable LowFunPtrType x) =>
				funPtrDynCallSig(codeAlloc, program, x));

	FunToReferences funToReferences =
		initFunToReferences(tempAlloc, funPtrTypeToDynCallSig, fullIndexDictSize(program.allFuns));
	TextAndInfo text = generateText(codeAlloc, tempAlloc, &program, &program.allConstants, funToReferences);
	immutable ThreadLocalsInfo threadLocals = generateThreadLocalsInfo(codeAlloc, program);
	ByteCodeWriter writer = newByteCodeWriter(ptrTrustMe(codeAlloc));

	immutable FullIndexDict!(LowFunIndex, ByteCodeIndex) funToDefinition =
		mapFullIndexDict!(LowFunIndex, ByteCodeIndex, LowFun)(
			tempAlloc,
			program.allFuns,
			(immutable LowFunIndex funIndex, scope ref immutable LowFun fun) {
				immutable ByteCodeIndex funPos = nextByteCodeIndex(writer);
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

	immutable SyntheticFunPtrs syntheticFunPtrs = makeSyntheticFunPtrs(
		codeAlloc, allSymbols, program,
		castImmutable(operations.byteCode), funToDefinition, funToReferences, cbMakeSyntheticFunPtrs);

	fullIndexDictEach!(LowFunIndex, ByteCodeIndex)(
		funToDefinition,
		(immutable LowFunIndex funIndex, ref immutable ByteCodeIndex definitionIndex) @trusted {
			immutable Operation* definition = cast(immutable) &operations.byteCode[definitionIndex.index];
			immutable FunReferences references = finishAt(tempAlloc, funToReferences, funIndex);
			foreach (immutable ByteCodeIndex reference; references.calls)
				fillDelayedCall(operations, reference, definition);
			if (has(references.ptrRefs)) {
				immutable FunPtrReferences ptrRefs = force(references.ptrRefs);
				immutable FunPtr funPtr = mustGetAt(syntheticFunPtrs.funToFunPtr, funIndex);
				foreach (immutable TextIndex reference; ptrRefs.textRefs)
					*(cast(ulong*) &text.text[reference.index]) = cast(immutable ulong) funPtr.fn;
				foreach (immutable ByteCodeIndex reference; ptrRefs.funPtrRefs)
					fillDelayedFunPtr(operations, reference, funPtr);
			}
		});

	return immutable ByteCode(
		castImmutable(operations),
		syntheticFunPtrs.funPtrToOperationPtr,
		fileToFuns(codeAlloc, allSymbols, modelProgram),
		castImmutable(text.text),
		threadLocals.totalSizeWords,
		funToDefinition[program.main]);
}

private:

immutable(SyntheticFunPtrs) makeSyntheticFunPtrs(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	scope ref immutable LowProgram program,
	immutable Operation[] byteCode,
	scope immutable FunToDefinition funToDefinition,
	scope ref const FunToReferences funToReferences,
	scope immutable MakeSyntheticFunPtrs cbMakeSyntheticFunPtrs
) {
	ArrBuilder!FunPtrInputs inputsBuilder;
	eachFunPtr(funToReferences, (immutable LowFunIndex funIndex, immutable DynCallSig sig) @trusted {
		add(alloc, inputsBuilder, immutable FunPtrInputs(funIndex, sig, &byteCode[funToDefinition[funIndex].index]));
	});
	immutable FunPtrInputs[] inputs = finishArr(alloc, inputsBuilder);
	immutable FunPtr[] funPtrs = cbMakeSyntheticFunPtrs(inputs);
	immutable FunToFunPtr funToFunPtr = zipToDict!(LowFunIndex, FunPtr)(
		alloc,
		inputs,
		funPtrs,
		(ref immutable FunPtrInputs inputs, ref immutable FunPtr funPtr) =>
			immutable KeyValuePair!(LowFunIndex, FunPtr)(inputs.funIndex, funPtr));
	immutable FunPtrToOperationPtr funPtrToOperationPtr = zipToDict!(FunPtr, Operation*)(
		alloc,
		inputs,
		funPtrs,
		(ref immutable FunPtrInputs inputs, ref immutable FunPtr funPtr) =>
			immutable KeyValuePair!(FunPtr, Operation*)(funPtr, inputs.operationPtr));
	return immutable SyntheticFunPtrs(funToFunPtr, funPtrToOperationPtr);
}

struct SyntheticFunPtrs {
	immutable FunToFunPtr funToFunPtr;
	immutable FunPtrToOperationPtr funPtrToOperationPtr;
}
alias FunToFunPtr = immutable Dict!(LowFunIndex, FunPtr);
alias FunToDefinition = immutable FullIndexDict!(LowFunIndex, ByteCodeIndex);

immutable(DynCallSig) funPtrDynCallSig(
	ref Alloc alloc,
	scope ref immutable LowProgram program,
	scope immutable LowFunPtrType a,
) {
	ArrBuilder!DynCallType sigTypes;
	add(alloc, sigTypes, toDynCallType(a.returnType));
	foreach (ref immutable LowType x; a.paramTypes)
		toDynCallTypes(program, x, (immutable DynCallType x) {
			add(alloc, sigTypes, x);
		});
	return immutable DynCallSig(finishArr(alloc, sigTypes));
}

immutable(FileToFuns) fileToFuns(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	scope ref immutable Program program,
) {
	immutable FullIndexDict!(FileIndex, Module) modulesDict =
		fullIndexDictOfArr!(FileIndex, Module)(program.allModules);
	return mapFullIndexDict!(FileIndex, FunNameAndPos[], Module)(
		alloc,
		modulesDict,
		(immutable FileIndex, ref immutable Module module_) =>
			map(alloc, module_.funs, (ref immutable FunDecl it) =>
				immutable FunNameAndPos(it.name, it.fileAndPos.pos)));
}

void generateBytecodeForFun(
	ref TempAlloc tempAlloc,
	scope ref ByteCodeWriter writer,
	ref const AllSymbols allSymbols,
	ref FunToReferences funToReferences,
	ref immutable TextInfo textInfo,
	ref immutable ThreadLocalsInfo threadLocalsInfo,
	scope ref immutable LowProgram program,
	scope immutable ExternFunPtrsForAllLibraries externFunPtrs,
	immutable LowFunIndex funIndex,
	scope ref immutable LowFun fun,
) {
	verify(threadLocalsInfo.totalSizeWords < maxThreadLocalsSizeWords);

	debug {
		if (false) {
			import util.writer : finishWriterToCStr;
			import core.stdc.stdio : printf;
			import interpret.debugging : writeFunName;
			Writer w = Writer(ptrTrustMe(tempAlloc));
			writeFunName(w, allSymbols, program, fun);
			printf("generateBytecodeForFun %s\n", finishWriterToCStr(w));
		}
	}

	size_t stackEntry = 0;
	immutable StackEntries[] parameters = map(tempAlloc, fun.params, (ref immutable LowParam it) {
		immutable StackEntry start = immutable StackEntry(stackEntry);
		immutable size_t n = nStackEntriesForType(program, it.type);
		stackEntry += n;
		return immutable StackEntries(start, n);
	});
	setStackEntryAfterParameters(writer, immutable StackEntry(stackEntry));
	immutable size_t returnEntries = nStackEntriesForType(program, fun.returnType);
	immutable ByteCodeSource source =
		immutable ByteCodeSource(funIndex, lowFunRange(fun, allSymbols).range.start);

	matchLowFunBody!(
		void,
		(ref immutable LowFunBody.Extern body_) {
			generateExternCall(writer, allSymbols, program, funIndex, fun, body_, externFunPtrs);
			writeReturn(writer, source);
		},
		(ref immutable LowFunExprBody body_) {
			generateFunFromExpr(
				tempAlloc, writer, allSymbols, program, textInfo, threadLocalsInfo, funIndex,
				funToReferences, parameters, returnEntries, body_);
		},
	)(fun.body_);
	verify(getNextStackEntry(writer).entry == returnEntries);
	setNextStackEntry(writer, immutable StackEntry(0));
}

void generateExternCall(
	ref ByteCodeWriter writer,
	ref const AllSymbols allSymbols,
	ref immutable LowProgram program,
	immutable LowFunIndex funIndex,
	scope ref immutable LowFun fun,
	ref immutable LowFunBody.Extern a,
	ref immutable ExternFunPtrsForAllLibraries externFunPtrs,
) {
	immutable ByteCodeSource source = immutable ByteCodeSource(funIndex, lowFunRange(fun, allSymbols).range.start);
	immutable Opt!Sym optName = name(fun);
	immutable Sym name = force(optName);
	switch (name.value) {
		case sym!"longjmp".value:
			writeLongjmp(writer, source);
			break;
		case sym!"setjmp".value:
			writeSetjmp(writer, source);
			break;
		default:
			immutable FunPtr funPtr = mustGetAt(mustGetAt(externFunPtrs, a.libraryName), name);
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
	immutable ByteCodeSource source,
	scope ref immutable LowProgram program,
	scope ref immutable LowType type,
	// TODO: not really immutable
	immutable void* ptr,
) {
	writePushConstant(writer, source, cast(immutable ulong) ptr);
	writeRead(writer, source, 0, typeSizeBytes(program, type));
}

void generateExternCallFunPtr(
	scope ref ByteCodeWriter writer,
	immutable ByteCodeSource source,
	scope ref immutable LowProgram program,
	scope ref immutable LowFun fun,
	immutable FunPtr funPtr,
) {
	MutMaxArr!(16, immutable DynCallType) sigTypes = void;
	initializeMutMaxArr(sigTypes);
	push(sigTypes, toDynCallType(fun.returnType));
	foreach (ref immutable LowParam x; fun.params)
		toDynCallTypes(program, x.type, (immutable DynCallType x) {
		push(sigTypes, x);
	});
	writeCallFunPtrExtern(writer, source, funPtr, immutable DynCallSig(tempAsArr(sigTypes)));
}

immutable(DynCallType) toDynCallType(scope immutable LowType a) =>
	matchLowType!(
		immutable DynCallType,
		(immutable LowType.ExternPtr) =>
			DynCallType.pointer,
		(immutable LowType.FunPtr) =>
			DynCallType.pointer,
		(immutable PrimitiveType it) {
			final switch (it) {
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
		},
		(immutable LowType.PtrGc) =>
			DynCallType.pointer,
		(immutable LowType.PtrRawConst) =>
			DynCallType.pointer,
		(immutable LowType.PtrRawMut) =>
			DynCallType.pointer,
		(immutable LowType.Record) =>
			unreachable!(immutable DynCallType),
		(immutable LowType.Union) =>
			unreachable!(immutable DynCallType),
	)(a);

void toDynCallTypes(
	scope ref immutable LowProgram program,
	scope immutable LowType a,
	scope void delegate(immutable DynCallType) @safe @nogc pure nothrow cb,
) {
	if (isRecordType(a)) {
		foreach (immutable LowField field; program.allRecords[asRecordType(a)].fields)
			toDynCallTypes(program, field.type, cb);
	} else if (isUnionType(a)) {
		// This should only happen for the 'str[]' in 'main'
		immutable LowUnion u = program.allUnions[asUnionType(a)];
		verify(name(*asInst(u.source.source).inst) == sym!"node");
		immutable size_t sizeWords = 3;
		verify(typeSize(u).sizeBytes == ulong.sizeof * sizeWords);
		foreach (immutable size_t i; 0 .. sizeWords)
			cb(DynCallType.nat64);
	} else
		cb(toDynCallType(a));
}
