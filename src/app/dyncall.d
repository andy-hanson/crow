module app.dyncall;

@safe @nogc nothrow:

import interpret.applyFn : u64OfI32, u64OfI64;
import interpret.bytecode : Operation;
import interpret.extern_ :
	DynCallSig,
	DynCallType,
	Extern,
	ExternFunPtrsForAllLibraries,
	ExternFunPtrsForLibrary,
	FunPtr,
	FunPtrInputs,
	funPtrEquals,
	hashFunPtr,
	WriteError,
	writeSymToCb;
import interpret.runBytecode : syntheticCall;
import interpret.stacks : dataPush, Stacks;
import lib.compiler : ExitCode;
import model.lowModel : ExternLibraries, ExternLibrary;
import util.alloc.alloc : Alloc;
import util.col.arrUtil : map, mapImpure, zipImpureSystem;
import util.col.dict : Dict, KeyValuePair, makeDictFromKeys, SymDict, zipToDict;
import util.col.dictBuilder : DictBuilder, finishDict, tryAddToDict;
import util.col.mutArr : MutArr, mutArrIsEmpty, push, tempAsArr;
import util.col.str : CStr, SafeCStr, safeCStr;
import util.conv : bitsOfFloat32, bitsOfFloat64, float32OfBits, float64OfBits;
import util.late : Late, late, lateGet, lateSet;
import util.memory : allocate;
import util.opt : force, has, Opt, none, some;
import util.path : AllPaths, childPath, Path, pathToTempStr, TempStrForPath;
import util.sym :
	AllSymbols,
	concatSyms,
	hashSym,
	shortSym,
	shortSymValue,
	SpecialSym,
	Sym,
	symAsTempBuffer,
	symEq,
	symForSpecial;
import util.util : todo, unreachable, verify;

@trusted immutable(ExitCode) withRealExtern(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	scope immutable(ExitCode) delegate(scope ref Extern) @safe @nogc nothrow cb,
) {
	Late!(immutable DebugNames) debugNames = late!(immutable DebugNames);
	scope Extern extern_ = Extern(
		(scope immutable ExternLibraries libraries, scope WriteError writeError) {
			immutable LoadedLibraries res = loadLibraries(alloc, allSymbols, allPaths, libraries, writeError);
			lateSet(debugNames, res.debugNames);
			return res.funPtrs;
		},
		(scope immutable FunPtrInputs[] inputs) =>
			makeSyntheticFunPtrs(alloc, inputs),
		(immutable FunPtr funPtr, scope immutable DynCallSig sig, scope immutable ulong[] parameters) =>
			// lateGet(debugNames)[funPtr]
			dynamicCallFunPtr(funPtr, allSymbols, sig, parameters));
	return cb(extern_);
}

private:

alias DebugNames = immutable Dict!(FunPtr, Sym, funPtrEquals, hashFunPtr);

struct LoadedLibraries {
	immutable DebugNames debugNames;
	immutable Opt!ExternFunPtrsForAllLibraries funPtrs;
}

immutable(LoadedLibraries) loadLibraries(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	scope immutable ExternLibraries libraries,
	scope WriteError writeError,
) {
	bool success = true;
	immutable DLLib*[] libs = mapImpure(alloc, libraries, (ref immutable ExternLibrary x) {
		immutable LibraryAndError lib = getLibrary(allSymbols, allPaths, x.libraryName, x.configuredPath, writeError);
		if (lib.error) success = false;
		return lib.library;
	});
	return success
		? loadLibrariesInner(alloc, allSymbols, libraries, libs, writeError)
		: immutable LoadedLibraries(immutable DebugNames(), none!ExternFunPtrsForAllLibraries);
}

// Can't use Opt since 'null' is sometimes allowed as the library
struct LibraryAndError {
	immutable DLLib* library;
	immutable bool error;
}

immutable(LibraryAndError) getLibrary(
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	immutable Sym libraryName,
	immutable Opt!Path configuredPath,
	scope WriteError writeError,
) {
	immutable Sym fileName = dllOrSoName(allSymbols, libraryName);
	immutable Opt!(DLLib*) fromPath = has(configuredPath)
		? tryLoadLibraryFromPath(allPaths, childPath(allPaths, force(configuredPath), fileName))
		: none!(DLLib*);
	if (has(fromPath)) {
		return immutable LibraryAndError(force(fromPath), false);
	} else {
		switch (libraryName.value) {
			case shortSymValue("c"):
			case shortSymValue("m"):
				version (Windows) {
					return loadLibraryFromName(safeCStr!"ucrtbase.dll", writeError);
				} else {
					return immutable LibraryAndError(null, false);
				}
			case shortSymValue("pthread"):
				// TODO: understand why this is different
				return loadLibraryFromName(safeCStr!"libpthread.so.0", writeError);
			default:
				return loadLibraryFromName(allSymbols, fileName, writeError);
		}
	}
}

immutable(Sym) dllOrSoName(ref AllSymbols allSymbols, immutable Sym libraryName) {
	version (Windows) {
		return concatSyms(allSymbols, [libraryName, symForSpecial(SpecialSym.dotDll)]);
	} else {
		return concatSyms(allSymbols, [shortSym("lib"), libraryName, symForSpecial(SpecialSym.dotSo)]);
	}
}

@trusted immutable(Opt!(DLLib*)) tryLoadLibraryFromPath(
	ref const AllPaths allPaths,
	immutable Path path,
) {
	TempStrForPath buf = void;
	immutable SafeCStr pathStr = pathToTempStr(buf, allPaths, path);
	immutable DLLib* res = dlLoadLibrary(pathStr.ptr);
	return res == null ? none!(DLLib*) : some(res);
}

@trusted immutable(LibraryAndError) loadLibraryFromName(
	ref const AllSymbols allSymbols,
	immutable Sym name,
	scope WriteError writeError,
) {
	char[256] buf = symAsTempBuffer!256(allSymbols, name);
	return loadLibraryFromName(immutable SafeCStr(cast(immutable) buf.ptr), writeError);
}

immutable(LibraryAndError) loadLibraryFromName(scope immutable SafeCStr name, scope WriteError writeError) {
	immutable DLLib* res = dlLoadLibrary(name.ptr);
	if (res == null) {
		// TODO: use a Diagnostic
		writeError(safeCStr!"Could not load library ");
		writeError(name);
		writeError(safeCStr!"\n");
	}
	return immutable LibraryAndError(res, res == null);
}

immutable(LoadedLibraries) loadLibrariesInner(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	scope immutable ExternLibraries libraries,
	immutable DLLib*[] libs,
	scope WriteError writeError,
) {
	DictBuilder!(FunPtr, Sym, funPtrEquals, hashFunPtr) debugNames;
	MutArr!(immutable KeyValuePair!(Sym, Sym)) failures;
	immutable ExternFunPtrsForAllLibraries res = zipToDict!(Sym, SymDict!FunPtr, symEq, hashSym, ExternLibrary, DLLib*)(
		alloc,
		libraries,
		libs,
		(ref immutable ExternLibrary x, ref immutable DLLib* lib) @safe @nogc nothrow {
			immutable ExternFunPtrsForLibrary funPtrs = makeDictFromKeys!(Sym, FunPtr, symEq, hashSym)(
				alloc,
				x.importNames,
				(immutable Sym importName) {
					immutable Opt!FunPtr p = getExternFunPtr(allSymbols, lib, importName);
					if (has(p)) {
						// sometimes two names refer to the same function -- just go with the first name
						tryAddToDict(alloc, debugNames, force(p), importName);
						return force(p);
					} else {
						push(alloc, failures, immutable KeyValuePair!(Sym , Sym)(x.libraryName, importName));
						return immutable FunPtr(null);
					}
				});
			return immutable KeyValuePair!(Sym, ExternFunPtrsForLibrary)(x.libraryName, funPtrs);
		});
	foreach (immutable KeyValuePair!(Sym, Sym) x; tempAsArr(failures)) {
		writeError(safeCStr!"Could not load extern function ");
		writeSymToCb(writeError, allSymbols, x.value);
		writeError(safeCStr!" from library ");
		writeSymToCb(writeError, allSymbols, x.key);
		writeError(safeCStr!"\n");
	}
	return immutable LoadedLibraries(
		finishDict(alloc, debugNames),
		mutArrIsEmpty(failures) ? some(res) : none!ExternFunPtrsForAllLibraries);
}

@trusted pure immutable(Opt!FunPtr) getExternFunPtr(
	ref const AllSymbols allSymbols,
	immutable DLLib* library,
	immutable Sym name,
) {
	immutable char[256] nameBuffer = symAsTempBuffer!256(allSymbols, name);
	immutable CStr nameCStr = nameBuffer.ptr;
	DCpointer ptr = dlFindSymbol(library, nameCStr);
	return ptr == null ? none!FunPtr : some(immutable FunPtr(cast(immutable) ptr));
}

@system immutable(ulong) dynamicCallFunPtr(
	immutable FunPtr funPtr,
	scope const ref AllSymbols allSymbols,
	/*scope immutable Opt!Sym debugName,*/
	scope immutable DynCallSig sig,
	scope immutable ulong[] parameters,
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
		verify(dcVm != null);
		dcMode(dcVm, DC_CALL_C_DEFAULT);
	}

	DCpointer ptr = cast(DCpointer) funPtr.fn;
	dcReset(dcVm);
	zipImpureSystem!(ulong, DynCallType)(
		parameters,
		sig.parameterTypes,
		(ref immutable ulong value, ref immutable DynCallType type) {
			final switch (type) {
				case DynCallType.bool_:
					dcArgBool(dcVm, cast(bool) value);
					break;
				case DynCallType.char8:
					todo!void("handle this type");
					break;
				case DynCallType.int8:
					todo!void("handle this type");
					break;
				case DynCallType.int16:
					dcArgShort(dcVm, cast(short) value);
					break;
				case DynCallType.int32:
					dcArgInt(dcVm, cast(int) value);
					break;
				case DynCallType.float32:
					dcArgFloat(dcVm, float32OfBits(cast(uint) value));
					break;
				case DynCallType.float64:
					dcArgDouble(dcVm, float64OfBits(value));
					break;
				case DynCallType.nat8:
					todo!void("handle this type");
					break;
				case DynCallType.nat16:
					todo!void("handle this type");
					break;
				case DynCallType.nat32:
					dcArgInt(dcVm, cast(uint) value);
					break;
				case DynCallType.int64:
				case DynCallType.nat64:
					dcArgLongLong(dcVm, value);
					break;
				case DynCallType.pointer:
					dcArgPointer(dcVm, cast(void*) value);
					break;
				case DynCallType.void_:
					unreachable!void();
			}
		});

	immutable ulong res = () {
		final switch (sig.returnType) {
			case DynCallType.bool_:
				return dcCallBool(dcVm, ptr);
			case DynCallType.char8:
				return todo!(immutable ulong)("handle this type");
			case DynCallType.int8:
				return todo!(immutable ulong)("handle this type");
			case DynCallType.int16:
				return todo!(immutable ulong)("handle this type");
			case DynCallType.int32:
				return u64OfI32(dcCallInt(dcVm, ptr));
			case DynCallType.int64:
			case DynCallType.nat64:
				return u64OfI64(dcCallLongLong(dcVm, ptr));
			case DynCallType.float32:
				return todo!(immutable ulong)("handle this type");
			case DynCallType.float64:
				return bitsOfFloat64(dcCallDouble(dcVm, ptr));
			case DynCallType.nat8:
				return todo!(immutable ulong)("handle this type");
			case DynCallType.nat16:
				return todo!(immutable ulong)("handle this type");
			case DynCallType.nat32:
				return cast(uint) dcCallInt(dcVm, ptr);
			case DynCallType.pointer:
				return cast(size_t) dcCallPointer(dcVm, ptr);
			case DynCallType.void_:
				dcCallVoid(dcVm, ptr);
				return 0;
		}
	}();
	dcReset(dcVm);
	return res;
}

struct UserData {
	immutable DynCallSig sig;
	immutable Operation* operationPtr;
}

pure immutable(FunPtr[]) makeSyntheticFunPtrs(ref Alloc alloc, scope immutable FunPtrInputs[] inputs) {
	return map(alloc, inputs, (ref immutable FunPtrInputs x) =>
		syntheticFunPtrForSig(alloc, x.sig, x.operationPtr));
}

@trusted pure immutable(FunPtr) syntheticFunPtrForSig(
	ref Alloc alloc,
	immutable DynCallSig sig,
	immutable Operation* operationPtr,
) {
	char[16] sigStr;
	toDynCallSigString(sigStr, sig);
	immutable UserData* userData = allocate(alloc, immutable UserData(sig, operationPtr));
	return immutable FunPtr(cast(immutable) dcbNewCallback(sigStr.ptr, &callbackHandler, cast(void*) userData));
}

@system extern(C) immutable(char) callbackHandler(DCCallback* cb, DCArgs* args, DCValue* result, void* userDataPtr) {
	immutable UserData userData = *(cast(immutable UserData*) userDataPtr);
	immutable DynCallSig sig = userData.sig;
	immutable ulong resValue = syntheticCall(sig, userData.operationPtr, (ref Stacks stacks) {
		foreach (immutable DynCallType argType; sig.parameterTypes)
			dataPush(stacks, dyncallGetArg(args, argType));
	});	dyncallSetResult(result, resValue, sig.returnType);
	return dynCallSigChar(sig.returnType);
}

pure void toDynCallSigString(ref char[16] res, immutable DynCallSig a) {
	size_t i = 0;
	void push(immutable char x) { res[i] = x; i++; }
	foreach (immutable DynCallType t; a.parameterTypes)
		push(dynCallSigChar(t));
	push(')');
	push(dynCallSigChar(a.returnType));
	push('\0');
}

pure immutable(char) dynCallSigChar(immutable DynCallType a) {
	final switch (a) {
		case DynCallType.bool_:
			return 'B';
		case DynCallType.char8:
			return 'c';
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

@system pure immutable(ulong) dyncallGetArg(DCArgs* args, immutable DynCallType type) {
	final switch (type) {
		case DynCallType.bool_:
			return dcbArgBool(args);
		case DynCallType.char8:
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
			return cast(immutable ulong) dcbArgPointer(args);
		case DynCallType.void_:
			return unreachable!(immutable ulong);
	}
}

@system pure void dyncallSetResult(DCValue* result, immutable ulong value, immutable DynCallType type) {
	final switch (type) {
		case DynCallType.bool_:
			todo!void("!");
			break;
		case DynCallType.char8:
			todo!void("!");
			break;
		case DynCallType.int8:
			todo!void("!");
			break;
		case DynCallType.int16:
			todo!void("!");
			break;
		case DynCallType.int32:
			todo!void("!");
			break;
		case DynCallType.int64:
			todo!void("!");
			break;
		case DynCallType.float32:
			todo!void("!");
			break;
		case DynCallType.float64:
			todo!void("!");
			break;
		case DynCallType.nat8:
			todo!void("!");
			break;
		case DynCallType.nat16:
			todo!void("!");
			break;
		case DynCallType.nat32:
			todo!void("!");
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
	alias DCCallbackHandler = immutable(char) function(DCCallback* pcb, DCArgs* args, DCValue* result, void* userdata);
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
	//void dcArgChar (DCCallVM* vm, DCchar value);
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
	//DCchar dcCallChar (DCCallVM* vm, DCpointer funcptr);
	//DCshort dcCallShort (DCCallVM* vm, DCpointer funcptr);
	DCint dcCallInt (DCCallVM* vm, DCpointer funcptr);
	//DClong dcCallLong (DCCallVM* vm, DCpointer funcptr);
	DClonglong dcCallLongLong (DCCallVM* vm, DCpointer funcptr);
	//DCfloat dcCallFloat (DCCallVM* vm, DCpointer funcptr);
	DCdouble dcCallDouble (DCCallVM* vm, DCpointer funcptr);
	DCpointer dcCallPointer (DCCallVM* vm, DCpointer funcptr);
	// void dcCallStruct (DCCallVM* vm, DCpointer funcptr, DCstruct* s, DCpointer returnValue);

	//DCint dcGetError (DCCallVM* vm);
}

extern(C) {
	// based on dyncall/dynload/dynload.h
	struct DLLib;
	immutable(DLLib*) dlLoadLibrary(scope const char* libpath);
	pure void* dlFindSymbol(immutable DLLib* pLib, scope const char* pSymbolName);
}
