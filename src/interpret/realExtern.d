module interpret.realExtern;

@safe @nogc nothrow: // not pure

// import core.sys.linux.sys.sysinfo : get_nprocs;
import core.sys.posix.unistd : posixWrite = write;

import interpret.allocTracker : AllocTracker;
import interpret.applyFn : nat64OfI32, nat64OfI64;
import interpret.bytecode : DynCallType;
import util.alloc.mallocator : Mallocator;
import util.bools : Bool;
import util.collection.arr : Arr;
import util.collection.arrUtil : zipImpureSystem;
import util.collection.str : asCStr, NulTerminatedStr;
import util.ptr : PtrRange;
import util.types : Nat64;
import util.util : todo, unreachable, verify;
import util.writer : Writer;

RealExtern newRealExtern() {
	return RealExtern(true);
}

struct RealExtern {
	@safe @nogc nothrow: // not pure

	private:
	@disable this();
	@disable this(ref const RealExtern);

	Mallocator alloc;
	AllocTracker allocTracker;
	void* sdlHandle;
	DCCallVM* dcVm;

	this(bool) {
		// TODO: better way to find where it is (may depend on system)
		sdlHandle = dlopen("/usr/lib64/libSDL2-2.0.so.0", RTLD_LAZY);
		verify(sdlHandle != null);

		dcVm = dcNewCallVM(4096);
		verify(dcVm != null);
		dcMode(dcVm, DC_CALL_C_DEFAULT);
	}

	public:

	~this() {
		int err = dlclose(sdlHandle);
		verify(err == 0);
		dcFree(dcVm);
	}

	// TODO: not trusted
	@trusted pure void free(ubyte* ptr) {
		immutable size_t size = allocTracker.markFree(ptr);
		alloc.free(ptr, size);
	}

	// TODO: not trusted
	@trusted pure ubyte* malloc(immutable size_t size) {
		ubyte* ptr = alloc.allocate(size);
		allocTracker.markAlloced(alloc, ptr, size);
		return ptr;
	}

	@system long write(int fd, immutable char* buf, immutable size_t nBytes) const {
		return posixWrite(fd, buf, nBytes);
	}

	immutable(size_t) getNProcs() const {
		// TODO: interpreter needs to support multiple threads
		return 1;
	}

	immutable(size_t) pthreadYield() const {
		// We don't support launching other threads, so do nothing
		return 0;
	}

	immutable(Bool) hasMallocedPtr(ref const PtrRange range) const {
		return allocTracker.hasAllocedPtr(range);
	}

	@trusted void writeMallocedRanges(WriterAlloc)(ref Writer!WriterAlloc writer) const {
		allocTracker.writeMallocedRanges!WriterAlloc(writer);
	}

	@trusted immutable(Nat64) doDynCall(
		ref immutable NulTerminatedStr name,
		immutable DynCallType returnType,
		ref immutable Arr!Nat64 parameters,
		ref immutable Arr!DynCallType parameterTypes,
	) {
		// TODO: don't just get everything from SDL...
		DCpointer ptr = dlsym(sdlHandle, asCStr(name));
		verify(ptr != null);

		dcReset(dcVm);
		zipImpureSystem(parameters, parameterTypes, (ref immutable Nat64 value, ref immutable DynCallType type) {
			final switch (type) {
				case DynCallType.bool_:
					todo!void("handle this type");
					break;
				case DynCallType.char_:
					todo!void("handle this type");
					break;
				case DynCallType.int8:
					todo!void("handle this type");
					break;
				case DynCallType.int16:
					todo!void("handle this type");
					break;
				case DynCallType.int32:
					todo!void("handle this type");
					break;
				case DynCallType.float32:
					todo!void("handle this type");
					break;
				case DynCallType.float64:
					todo!void("handle this type");
					break;
				case DynCallType.nat8:
					todo!void("handle this type");
					break;
				case DynCallType.nat16:
					todo!void("handle this type");
					break;
				case DynCallType.nat32:
					dcArgInt(dcVm, cast(uint) value.raw());
					break;
				case DynCallType.int64:
				case DynCallType.nat64:
					dcArgLong(dcVm, value.raw());
					break;
				case DynCallType.pointer:
					dcArgPointer(dcVm, cast(void*) value.raw());
					break;
				case DynCallType.void_:
					unreachable!void();
			}
		});

		immutable Nat64 res = () {
			final switch (returnType) {
				case DynCallType.bool_:
					return todo!(immutable Nat64)("handle this type");
				case DynCallType.char_:
					return todo!(immutable Nat64)("handle this type");
				case DynCallType.int8:
					return todo!(immutable Nat64)("handle this type");
				case DynCallType.int16:
					return todo!(immutable Nat64)("handle this type");
				case DynCallType.int32:
					return nat64OfI32(dcCallInt(dcVm, ptr));
				case DynCallType.int64:
					return nat64OfI64(dcCallLong(dcVm, ptr));
				case DynCallType.float32:
					return todo!(immutable Nat64)("handle this type");
				case DynCallType.float64:
					return todo!(immutable Nat64)("handle this type");
				case DynCallType.nat8:
					return todo!(immutable Nat64)("handle this type");
				case DynCallType.nat16:
					return todo!(immutable Nat64)("handle this type");
				case DynCallType.nat32:
					return todo!(immutable Nat64)("handle this type");
				case DynCallType.nat64:
					return todo!(immutable Nat64)("handle this type");
				case DynCallType.pointer:
					return immutable Nat64(cast(size_t) dcCallPointer(dcVm, ptr));
				case DynCallType.void_:
					dcCallVoid(dcVm, ptr);
					return immutable Nat64(0);
			}
		}();
		dcReset(dcVm);
		return res;
	}
}

private:

extern(C) {
	// dlfcn.h
	void* dlopen(const char* file, int mode);
	int dlclose(void* handle);
	void* dlsym(void* handle, const char* name);
	enum RTLD_LAZY = 1;

	// dyncall_types.h
	//alias DCvoid = void;
	alias DCbool = int;
	alias DCchar = char;
	//alias DCuchar = uchar;
	alias DCshort = short;
	//alias DCushort = ushort;
	alias DCint = int;
	//alias DCuint = uint;
	alias DClong = long;
	//alias DCulong = ulong;
	//typedef DC_LONG_LONG          DClonglong;
	//typedef unsigned DC_LONG_LONG DCulonglong;
	alias DCfloat = float;
	alias DCdouble = double;
	alias DCpointer = void*;
	//alias DCstring = const char*;
	alias DCsize = size_t;

	// dyncall.h
	struct DCCallVM;

	enum DC_CALL_C_DEFAULT = 0;

	DCCallVM*  dcNewCallVM     (DCsize size);
	void       dcFree          (DCCallVM* vm);
	void       dcReset         (DCCallVM* vm);

	void       dcMode          (DCCallVM* vm, DCint mode);

	//void       dcArgBool       (DCCallVM* vm, DCbool     value);
	//void       dcArgChar       (DCCallVM* vm, DCchar     value);
	//void       dcArgShort      (DCCallVM* vm, DCshort    value);
	void       dcArgInt        (DCCallVM* vm, DCint      value);
	void       dcArgLong       (DCCallVM* vm, DClong     value);
	//void       dcArgLongLong   (DCCallVM* vm, DClonglong value);
	//void       dcArgFloat      (DCCallVM* vm, DCfloat    value);
	//void       dcArgDouble     (DCCallVM* vm, DCdouble   value);
	void       dcArgPointer    (DCCallVM* vm, DCpointer  value);
	// void       dcArgStruct     (DCCallVM* vm, DCstruct* s, DCpointer value);

	void       dcCallVoid      (DCCallVM* vm, DCpointer funcptr);
	//DCbool     dcCallBool      (DCCallVM* vm, DCpointer funcptr);
	//DCchar     dcCallChar      (DCCallVM* vm, DCpointer funcptr);
	//DCshort    dcCallShort     (DCCallVM* vm, DCpointer funcptr);
	DCint      dcCallInt       (DCCallVM* vm, DCpointer funcptr);
	DClong     dcCallLong      (DCCallVM* vm, DCpointer funcptr);
	//DClonglong dcCallLongLong  (DCCallVM* vm, DCpointer funcptr);
	//DCfloat    dcCallFloat     (DCCallVM* vm, DCpointer funcptr);
	//DCdouble   dcCallDouble    (DCCallVM* vm, DCpointer funcptr);
	DCpointer  dcCallPointer   (DCCallVM* vm, DCpointer funcptr);
	// void       dcCallStruct    (DCCallVM* vm, DCpointer funcptr, DCstruct* s, DCpointer returnValue);

	//DCint      dcGetError      (DCCallVM* vm);
}

//extern void *dlopen (const char *__file, int __mode) __THROWNL;
