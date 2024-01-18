module app.dyncall;

@safe @nogc nothrow: // not pure

import interpret.applyFn : u64OfI32, u64OfI64;
import interpret.bytecode : Operation;
import interpret.extern_ :
	DynCallSig,
	DynCallType,
	Extern,
	ExternPointer,
	ExternPointersForAllLibraries,
	ExternPointersForLibrary,
	FunPointer,
	FunPointerInputs,
	WriteError,
	writeSymbolToCb;
import interpret.runBytecode : syntheticCall;
import interpret.stacks : dataPush, Stacks;
import model.lowModel : ExternLibraries, ExternLibrary;
import util.alloc.alloc : Alloc;
import util.col.array : map, mapImpure;
import util.col.map : Map, KeyValuePair, makeMapFromKeys, zipToMap;
import util.col.mapBuilder : MapBuilder, finishMap, tryAddToMap;
import util.col.mutArr : MutArr, mutArrIsEmpty, push;
import util.conv : bitsOfFloat32, bitsOfFloat64, float32OfBits, float64OfBits;
import util.exitCode : ExitCode;
import util.late : Late, late, lateGet, lateSet;
import util.memory : allocate;
import util.opt : force, has, Opt, none, some;
import util.string : CString, cString;
import util.symbol : AllSymbols, concatSymbols, Symbol, symbol, symbolAsTempBuffer;
import util.uri : AllUris, asFileUri, childUri, fileUriToTempStr, isFileUri, TempStrForPath, Uri;

@trusted ExitCode withRealExtern(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllUris allUris,
	in ExitCode delegate(in Extern) @safe @nogc nothrow cb,
) {
	Late!DebugNames debugNames = late!DebugNames;
	scope Extern extern_ = Extern(
		(in ExternLibraries libraries, scope WriteError writeError) {
			LoadedLibraries res = loadLibraries(alloc, allSymbols, allUris, libraries, writeError);
			lateSet(debugNames, res.debugNames);
			return res.funPointers;
		},
		(in FunPointerInputs[] inputs) =>
			makeSyntheticFunPointers(alloc, inputs),
		(FunPointer funPointer, in DynCallSig sig, in ulong[] parameters) =>
			dynamicCallFunPointer(
				funPointer, allSymbols, lateGet(debugNames)[funPointer.asExternPointer], sig, parameters));
	return cb(extern_);
}

private:

alias DebugNames = Map!(ExternPointer, Symbol);

immutable struct LoadedLibraries {
	DebugNames debugNames;
	Opt!ExternPointersForAllLibraries funPointers;
}

LoadedLibraries loadLibraries(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllUris allUris,
	in ExternLibraries libraries,
	in WriteError writeError,
) {
	bool success = true;
	immutable DLLib*[] libs = mapImpure!(immutable DLLib*, ExternLibrary)(alloc, libraries, (in ExternLibrary x) {
		LibraryAndError lib = getLibrary(allSymbols, allUris, x.libraryName, x.configuredDir, writeError);
		if (lib.error) success = false;
		return lib.library;
	});
	return success
		? loadLibrariesInner(alloc, allSymbols, libraries, libs, writeError)
		: LoadedLibraries(DebugNames(), none!ExternPointersForAllLibraries);
}

// Can't use Opt since 'null' is sometimes allowed as the library
immutable struct LibraryAndError {
	DLLib* library;
	bool error;
}

LibraryAndError getLibrary(
	ref AllSymbols allSymbols,
	ref AllUris allUris,
	Symbol libraryName,
	Opt!Uri configuredDir,
	in WriteError writeError,
) {
	Symbol fileName = dllOrSoName(allSymbols, libraryName);
	Opt!(DLLib*) fromUri = has(configuredDir)
		? tryLoadLibraryFromUri(allUris, childUri(allUris, force(configuredDir), fileName))
		: none!(DLLib*);
	if (has(fromUri))
		return LibraryAndError(force(fromUri), false);
	else {
		switch (libraryName.value) {
			case symbol!"c".value:
			case symbol!"m".value:
				version (Windows) {
					return loadLibraryFromName(cString!"ucrtbase.dll", writeError);
				} else {
					return LibraryAndError(null, false);
				}
			case symbol!"pthread".value:
				// TODO: understand why this is different
				return loadLibraryFromName(cString!"libpthread.so.0", writeError);
			default:
				return loadLibraryFromName(allSymbols, fileName, writeError);
		}
	}
}

Symbol dllOrSoName(ref AllSymbols allSymbols, immutable Symbol libraryName) {
	version (Windows) {
		return concatSymbols(allSymbols, [libraryName, symbol!".dll"]);
	} else {
		return concatSymbols(allSymbols, [symbol!"lib", libraryName, symbol!".so"]);
	}
}

@trusted Opt!(DLLib*) tryLoadLibraryFromUri(ref AllUris allUris, Uri uri) {
	if (isFileUri(allUris, uri)) {
		TempStrForPath buf = void;
		CString file = fileUriToTempStr(buf, allUris, asFileUri(allUris, uri));
		DLLib* res = dlLoadLibrary(file.ptr);
		return res == null ? none!(DLLib*) : some(res);
	} else
		return none!(DLLib*);
}

@trusted LibraryAndError loadLibraryFromName(in AllSymbols allSymbols, Symbol name, in WriteError writeError) {
	char[256] buf = symbolAsTempBuffer!256(allSymbols, name);
	return loadLibraryFromName(CString(cast(immutable) buf.ptr), writeError);
}

LibraryAndError loadLibraryFromName(in CString name, in WriteError writeError) {
	DLLib* res = dlLoadLibrary(name.ptr);
	if (res == null) {
		// TODO: use a Diagnostic
		writeError(cString!"Could not load library ");
		writeError(name);
		writeError(cString!"\n");
	}
	return LibraryAndError(res, res == null);
}

LoadedLibraries loadLibrariesInner(
	ref Alloc alloc,
	in AllSymbols allSymbols,
	in ExternLibraries libraries,
	immutable DLLib*[] libs,
	in WriteError writeError,
) {
	MapBuilder!(ExternPointer, Symbol) debugNames;
	MutArr!(KeyValuePair!(Symbol, Symbol)) failures;
	ExternPointersForAllLibraries res = zipToMap!(Symbol, Map!(Symbol, ExternPointer), ExternLibrary, DLLib*)(
		alloc,
		libraries,
		libs,
		(ref ExternLibrary x, ref DLLib* lib) {
			ExternPointersForLibrary pointers = makeMapFromKeys!(Symbol, ExternPointer)(
				alloc,
				x.importNames,
				(Symbol importName) {
					Opt!ExternPointer p = getExternPointer(allSymbols, lib, importName);
					if (has(p)) {
						// sometimes two names refer to the same function -- just go with the first name
						tryAddToMap!(ExternPointer, Symbol)(alloc, debugNames, force(p), importName);
						return force(p);
					} else {
						push(alloc, failures, KeyValuePair!(Symbol, Symbol)(x.libraryName, importName));
						return ExternPointer(null);
					}
				});
			return immutable KeyValuePair!(Symbol, ExternPointersForLibrary)(x.libraryName, pointers);
		});
	foreach (KeyValuePair!(Symbol, Symbol) x; failures) {
		writeError(cString!"Could not load extern function ");
		writeSymbolToCb(writeError, allSymbols, x.value);
		writeError(cString!" from library ");
		writeSymbolToCb(writeError, allSymbols, x.key);
		writeError(cString!"\n");
	}
	return LoadedLibraries(
		finishMap(alloc, debugNames),
		mutArrIsEmpty(failures) ? some(res) : none!ExternPointersForAllLibraries);
}

@trusted pure Opt!ExternPointer getExternPointer(in AllSymbols allSymbols, DLLib* library, Symbol name) {
	immutable char[256] nameBuffer = symbolAsTempBuffer!256(allSymbols, name);
	DCpointer ptr = dlFindSymbol(library, nameBuffer.ptr);
	return ptr == null ? none!ExternPointer : some(ExternPointer(cast(immutable) ptr));
}

@system ulong dynamicCallFunPointer(
	FunPointer fun,
	in AllSymbols allSymbols,
	Opt!Symbol debugName,
	in DynCallSig sig,
	in ulong[] parameters,
) {
	static DCCallVM* dcVm = null;
	if (dcVm == null) {
		// first time an extern function called on this thread
		// TODO: dyncall doesn't seem to have any internal checking,
		// so overflowing this just leads to wierd behavior.
		// (this happens if you call a native function that calls back into crow,
		// which calls another native function, etc, growing the dyncall stack indefinitely.)
		// TODO: manually track the stack size and abort on failure
		dcVm = dcNewCallVM(0x1000);
		assert(dcVm != null);
		dcMode(dcVm, DC_CALL_C_DEFAULT);
	}

	DCpointer ptr = cast(DCpointer) fun.pointer;
	dcReset(dcVm);
	foreach (size_t i, ulong value; parameters) {
		addArgForDynCall(dcVm, value, sig.parameterTypes[i]);
	}

	ulong res = doDynCallForType(dcVm, ptr, sig.returnType);
	dcReset(dcVm);
	return res;
}

@system void addArgForDynCall(DCCallVM* dcVm, ulong value, DynCallType parameterType) {
	final switch (parameterType) {
		case DynCallType.bool_:
			dcArgBool(dcVm, cast(bool) value);
			break;
		case DynCallType.int8:
		case DynCallType.nat8:
			dcArgChar(dcVm, cast(char) value);
			break;
		case DynCallType.int16:
		case DynCallType.nat16:
			dcArgShort(dcVm, cast(short) value);
			break;
		case DynCallType.int32:
		case DynCallType.nat32:
			dcArgInt(dcVm, cast(int) value);
			break;
		case DynCallType.int64:
		case DynCallType.nat64:
			dcArgLongLong(dcVm, value);
			break;
		case DynCallType.float32:
			dcArgFloat(dcVm, float32OfBits(cast(uint) value));
			break;
		case DynCallType.float64:
			dcArgDouble(dcVm, float64OfBits(value));
			break;
			dcArgShort(dcVm, cast(ushort) value);
			break;
		case DynCallType.pointer:
			dcArgPointer(dcVm, cast(void*) value);
			break;
		case DynCallType.void_:
			assert(false);
	}
}

@system ulong doDynCallForType(DCCallVM* dcVm, DCpointer ptr, DynCallType returnType) {
	final switch (returnType) {
		case DynCallType.bool_:
			return dcCallBool(dcVm, ptr);
		case DynCallType.int8:
		case DynCallType.nat8:
			return dcCallChar(dcVm, ptr);
		case DynCallType.int16:
		case DynCallType.nat16:
			return dcCallShort(dcVm, ptr);
		case DynCallType.int32:
		case DynCallType.nat32:
			return u64OfI32(dcCallInt(dcVm, ptr));
		case DynCallType.int64:
		case DynCallType.nat64:
			return u64OfI64(dcCallLongLong(dcVm, ptr));
		case DynCallType.float32:
			return bitsOfFloat32(dcCallFloat(dcVm, ptr));
		case DynCallType.float64:
			return bitsOfFloat64(dcCallDouble(dcVm, ptr));
		case DynCallType.pointer:
			return cast(size_t) dcCallPointer(dcVm, ptr);
		case DynCallType.void_:
			dcCallVoid(dcVm, ptr);
			return 0;
	}
}

immutable struct UserData {
	DynCallSig sig;
	Operation* operationPtr;
}

pure FunPointer[] makeSyntheticFunPointers(ref Alloc alloc, in FunPointerInputs[] inputs) =>
	map(alloc, inputs, (ref FunPointerInputs x) =>
		syntheticFunPointerForSig(alloc, x.sig, x.operationPtr));

@trusted pure FunPointer syntheticFunPointerForSig(ref Alloc alloc, DynCallSig sig, Operation* operationPtr) {
	char[16] sigStr;
	toDynCallSigString(sigStr, sig);
	UserData* userData = allocate(alloc, UserData(sig, operationPtr));
	return FunPointer(cast(immutable) dcbNewCallback(sigStr.ptr, &callbackHandler, cast(void*) userData));
}

@system extern(C) char callbackHandler(DCCallback* cb, DCArgs* args, DCValue* result, void* userDataPtr) {
	UserData userData = *(cast(UserData*) userDataPtr);
	DynCallSig sig = userData.sig;
	ulong resValue = syntheticCall(sig, userData.operationPtr, (ref Stacks stacks) {
		foreach (DynCallType argType; sig.parameterTypes)
			dataPush(stacks, dyncallGetArg(args, argType));
	});	dyncallSetResult(result, resValue, sig.returnType);
	return dynCallSigChar(sig.returnType);
}

pure void toDynCallSigString(ref char[16] res, in DynCallSig a) {
	size_t i = 0;
	void push(char x) {
		res[i] = x;
		i++;
	}
	foreach (DynCallType t; a.parameterTypes)
		push(dynCallSigChar(t));
	push(')');
	push(dynCallSigChar(a.returnType));
	push('\0');
}

pure char dynCallSigChar(DynCallType a) {
	final switch (a) {
		case DynCallType.bool_:
			return 'B';
		case DynCallType.int8:
			return 'c';
		case DynCallType.int16:
			return 's';
		case DynCallType.int32:
			return 'i';
		case DynCallType.int64:
			return 'l';
		case DynCallType.float32:
			return 'f';
		case DynCallType.float64:
			return 'd';
		case DynCallType.nat8:
			return 'C';
		case DynCallType.nat16:
			return 'S';
		case DynCallType.nat32:
			return 'I';
		case DynCallType.nat64:
			return 'L';
		case DynCallType.pointer:
			return 'p';
		case DynCallType.void_:
			return 'v';
	}
}

@system pure ulong dyncallGetArg(DCArgs* args, DynCallType type) {
	final switch (type) {
		case DynCallType.bool_:
			return dcbArgBool(args);
		case DynCallType.int8:
			return dcbArgChar(args);
		case DynCallType.int16:
			return dcbArgShort(args);
		case DynCallType.int32:
			return dcbArgInt(args);
		case DynCallType.int64:
			return dcbArgLongLong(args);
		case DynCallType.float32:
			return bitsOfFloat32(dcbArgFloat(args));
		case DynCallType.float64:
			return bitsOfFloat64(dcbArgDouble(args));
		case DynCallType.nat8:
			return dcbArgUChar(args);
		case DynCallType.nat16:
			return dcbArgUShort(args);
		case DynCallType.nat32:
			return dcbArgUInt(args);
		case DynCallType.nat64:
			return dcbArgULongLong(args);
		case DynCallType.pointer:
			return cast(ulong) dcbArgPointer(args);
		case DynCallType.void_:
			assert(false);
	}
}

@system pure void dyncallSetResult(DCValue* result, ulong value, DynCallType type) {
	final switch (type) {
		case DynCallType.bool_:
			result.B = cast(bool) value;
			break;
		case DynCallType.int8:
			result.c = cast(char) value;
			break;
		case DynCallType.int16:
			result.s = cast(short) value;
			break;
		case DynCallType.int32:
			result.i = cast(int) value;
			break;
		case DynCallType.int64:
			result.l = cast(long) value;
			break;
		case DynCallType.float32:
			result.f = float32OfBits(value);
			break;
		case DynCallType.float64:
			result.d = float64OfBits(value);
			break;
		case DynCallType.nat8:
			result.C = cast(ubyte) value;
			break;
		case DynCallType.nat16:
			result.S = cast(ushort) value;
			break;
		case DynCallType.nat32:
			result.I = cast(uint) value;
			break;
		case DynCallType.nat64:
			result.L = value;
			break;
		case DynCallType.pointer:
			result.p = cast(void*) value;
			break;
		case DynCallType.void_:
			// do nothing
			break;
	}
}

extern(C) {
	@system:

	// dyncall_types.h
	//alias DCvoid = void;
	alias DCbool = int;
	alias DCchar = byte;
	alias DCuchar = ubyte;
	alias DCshort = short;
	alias DCushort = ushort;
	alias DCint = int;
	alias DCuint = uint;
	// Depends on the system?
	// alias DClong = long;
	// alias DCulong = ulong;
	alias DClonglong = long;
	alias DCulonglong = ulong;
	alias DCfloat = float;
	alias DCdouble = double;
	alias DCpointer = void*;
	alias DCstring = const char*;
	alias DCsize = size_t;

	// dyncall_args.h
	struct DCArgs;
	pure DCbool dcbArgBool(DCArgs*);
	pure DCchar dcbArgChar(DCArgs*);
	pure DCshort dcbArgShort(DCArgs*);
	pure DCint dcbArgInt(DCArgs*);
	// pure DClong dcbArgLong(DCArgs*);
	pure DClonglong dcbArgLongLong(DCArgs*);
	pure DCuchar dcbArgUChar(DCArgs*);
	pure DCushort dcbArgUShort(DCArgs*);
	pure DCuint dcbArgUInt(DCArgs*);
	// pure DCulong dcbArgULong(DCArgs*);
	pure DCulonglong dcbArgULongLong(DCArgs*);
	pure DCfloat dcbArgFloat(DCArgs*);
	pure DCdouble dcbArgDouble(DCArgs*);
	pure DCpointer dcbArgPointer(DCArgs*);

	// dyncall_callback.h
	struct DCCallback;
	alias DCCallbackHandler = char function(DCCallback* pcb, DCArgs* args, DCValue* result, void* userdata);
	pure DCCallback* dcbNewCallback(scope const char* signature, DCCallbackHandler funcptr, void* userdata);

	// dyncall_value.h
	union DCValue {
		// TODO: big-endian architectures are different
		DCbool B;
		DCchar c;
		DCuchar C;
		DCshort s;
		DCushort S;
		DCint i;
		DCuint I;
		//DClong j;
		//DCulong J;
		DClonglong l;
		DCulonglong L;
		DCfloat f;
		DCdouble d;
		DCpointer p;
		//DCstring Z;
	}

	// dyncall.h
	struct DCCallVM;

	enum DC_CALL_C_DEFAULT = 0;

	DCCallVM* dcNewCallVM(DCsize size);
	void dcReset(DCCallVM* vm);

	void dcMode(DCCallVM* vm, DCint mode);

	void dcArgBool (DCCallVM* vm, DCbool value);
	void dcArgChar (DCCallVM* vm, DCchar value);
	void dcArgShort (DCCallVM* vm, DCshort value);
	void dcArgInt (DCCallVM* vm, DCint value);
	//void dcArgLong (DCCallVM* vm, DClong value);
	void dcArgLongLong (DCCallVM* vm, DClonglong value);
	void dcArgFloat (DCCallVM* vm, DCfloat value);
	void dcArgDouble (DCCallVM* vm, DCdouble value);
	void dcArgPointer (DCCallVM* vm, DCpointer value);
	// void dcArgStruct (DCCallVM* vm, DCstruct* s, DCpointer value);

	void dcCallVoid (DCCallVM* vm, DCpointer funcptr);
	DCbool dcCallBool (DCCallVM* vm, DCpointer funcptr);
	DCchar dcCallChar (DCCallVM* vm, DCpointer funcptr);
	DCshort dcCallShort (DCCallVM* vm, DCpointer funcptr);
	DCint dcCallInt (DCCallVM* vm, DCpointer funcptr);
	//DClong dcCallLong (DCCallVM* vm, DCpointer funcptr);
	DClonglong dcCallLongLong (DCCallVM* vm, DCpointer funcptr);
	DCfloat dcCallFloat (DCCallVM* vm, DCpointer funcptr);
	DCdouble dcCallDouble (DCCallVM* vm, DCpointer funcptr);
	DCpointer dcCallPointer (DCCallVM* vm, DCpointer funcptr);
	// void dcCallStruct (DCCallVM* vm, DCpointer funcptr, DCstruct* s, DCpointer returnValue);

	//DCint dcGetError (DCCallVM* vm);
}

extern(C) {
	// based on dyncall/dynload/dynload.h
	immutable struct DLLib;
	DLLib* dlLoadLibrary(scope const char* libpath);
	pure void* dlFindSymbol(DLLib* pLib, scope const char* pSymbolName);
}
