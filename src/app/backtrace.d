module app.backtrace;

@safe @nogc nothrow: // not pure

version (Windows) {
	import core.sys.windows.core :
		BOOL,
		CONTEXT,
		CONTEXT_FULL,
		DWORD,
		DWORD64,
		GetCurrentProcess,
		GetCurrentThread,
		HANDLE,
		PCSTR,
		PDWORD,
		PVOID;
	import core.sys.windows.winbase : GetProcAddress, LoadLibraryA;
	import core.sys.windows.dbghelp :
		FunctionTableAccessProc64, GetModuleBaseProc64, ReadProcessMemoryProc64, TranslateAddressProc64;
	import core.sys.windows.dbghelp_types :
		ADDRESS64,
		IMAGE_FILE_MACHINE_AMD64,
		IMAGEHLP_LINEA64,
		IMAGEHLP_SYMBOLA64,
		KDHELP64,
		STACKFRAME64,
		SYMOPT_LOAD_LINES;
	import core.sys.windows.imagehlp : ADDRESS_MODE;
}

import core.stdc.stdint : uintptr_t;

import util.string : CString;
import util.writer : Writer;

@system void writeBacktrace(scope ref Writer writer) {
	version (Windows) {
		DbgHelp dbgHelp = getDbgHelp();

		HANDLE process = GetCurrentProcess();
		HANDLE thread = GetCurrentThread();
		int ok = dbgHelp.SymInitialize(process, null, true);
		assert(ok);
		CONTEXT context = CONTEXT(CONTEXT_FULL);
		RtlCaptureContext(&context);
		STACKFRAME64 frame = STACKFRAME64(
			AddrPC: toAddr(context.Rip),
			AddrReturn: ADDRESS64(),
			AddrFrame: toAddr(context.Rbp),
			AddrStack: toAddr(context.Rsp),
			AddrBStore: ADDRESS64(),
			FuncTableEntry: null,
			Params: [0, 0, 0, 0],
			Far: false,
			Virtual: false,
			Reserved: [0, 0, 0],
			KdHelp: KDHELP64());
		dbgHelp.SymSetOptions(SYMOPT_LOAD_LINES);

		writer ~= "\nBacktrace:";

		DWORD step() =>
			dbgHelp.StackWalk64(
				IMAGE_FILE_MACHINE_AMD64, process, thread,
				&frame, &context, null, dbgHelp.SymFunctionTableAccess64, null, null);

		foreach (size_t i; 0 .. 6)
			step();

		while (step()) {
			size_t offset;
			IMAGEHLP_SYMBOLA64 symbol;
			writer ~= "\n\tat ";
			if (dbgHelp.SymGetSymFromAddr64(process, frame.AddrPC.Offset, &offset, &symbol)) {
				writer ~= CString(cast(immutable) &symbol.Name[0]);
				DWORD displacement;
				IMAGEHLP_LINEA64 line;
				if (dbgHelp.SymGetLineFromAddr64(process, frame.AddrPC.Offset, &displacement, &line)) {
					writer ~= '(';
					writer ~= CString(cast(immutable) line.FileName);
					writer ~= " line ";
					writer ~= line.LineNumber;
					writer ~= ')';
				}
			} else
				writer ~= "<<unknown>>";
		}

		int ok1 = dbgHelp.SymCleanup(process);
		assert(ok1);
	} else {
		unw_cursor_t cursor;
		unw_context_t context;
		int err = unw_getcontext(&context);
		err = err || unw_init_local(&cursor, &context);
		bool step() {
			if (err == 0) {
				int res = unw_step(&cursor);
				if (res < 0)
					err = -res;
				return res > 0;
			} else
				return false;
		}
		// skip '__assert' and 'printBacktrace'
		foreach (size_t i; 0 .. 2)
			step();
		while (step()) {
			unw_word_t offset = 0;
			char[1024] buf;
			err = err || unw_get_proc_name(&cursor, buf.ptr, buf.length, &offset);
			if (err == 0) {
				writer ~= "\n\tat ";
				writer ~= CString(cast(immutable) buf.ptr);
			}
		}
		if (err != 0)
			writer ~= "\n\terror getting backtrace";
		writer ~= "\n";
	}
}

private:

version (Windows) {
	ADDRESS64 toAddr(DWORD64 offset) =>
		ADDRESS64(offset, 0, ADDRESS_MODE.AddrModeFlat);

	// Copied from D's core/sys/windows/dbgHelp.d, but adding @nogc nothrow
	alias SymInitializeFunc = extern(Windows) BOOL function(
		HANDLE hProcess,
		PCSTR UserSearchPath,
		bool fInvadeProcess,
	) @nogc nothrow;
	alias SymCleanupFunc = extern(Windows) BOOL function(HANDLE hProcess) @nogc nothrow;
	alias SymSetOptionsFunc = extern(Windows) DWORD function(DWORD SymOptions) @nogc nothrow;
	alias SymFunctionTableAccess64Func = extern(Windows) PVOID function(
		HANDLE hProcess,
		DWORD64 AddrBase,
	) @nogc nothrow;
	alias StackWalk64Func = extern(Windows) BOOL function(
		DWORD MachineType,
		HANDLE hProcess,
		HANDLE hThread,
		STACKFRAME64 *StackFrame,
		PVOID ContextRecord,
		ReadProcessMemoryProc64 ReadMemoryRoutine,
		FunctionTableAccessProc64 FunctionTableAccess,
		GetModuleBaseProc64 GetModuleBaseRoutine,
		TranslateAddressProc64 TranslateAddress,
	) @nogc nothrow;
	alias SymGetLineFromAddr64Func = extern(Windows) BOOL function(
		HANDLE hProcess,
		DWORD64 dwAddr,
		PDWORD pdwDisplacement,
		IMAGEHLP_LINEA64 *line,
	) @nogc nothrow;
	alias SymGetSymFromAddr64Func = extern(Windows) BOOL function(
		HANDLE hProcess,
		DWORD64 Address,
		DWORD64 *Displacement,
		IMAGEHLP_SYMBOLA64 *Symbol,
	) @nogc nothrow;

	struct DbgHelp {
		SymInitializeFunc SymInitialize;
		SymCleanupFunc SymCleanup;
		StackWalk64Func StackWalk64;
		SymSetOptionsFunc SymSetOptions;
		SymFunctionTableAccess64Func SymFunctionTableAccess64;
		SymGetLineFromAddr64Func SymGetLineFromAddr64;
		SymGetSymFromAddr64Func SymGetSymFromAddr64;
	}

	@system DbgHelp getDbgHelp() {
		HANDLE lib = LoadLibraryA("dbghelp.dll");
		void* get(immutable char* name) {
			void* res = GetProcAddress(lib, name);
			assert(res != null);
			return res;
		}
		return DbgHelp(
			SymInitialize: cast(SymInitializeFunc) get("SymInitialize"),
			SymCleanup: cast(SymCleanupFunc) get("SymCleanup"),
			StackWalk64: cast(StackWalk64Func) get("StackWalk64"),
			SymSetOptions: cast(SymSetOptionsFunc) get("SymSetOptions"),
			SymFunctionTableAccess64: cast(SymFunctionTableAccess64Func) get("SymFunctionTableAccess64"),
			SymGetLineFromAddr64: cast(SymGetLineFromAddr64Func) get("SymGetLineFromAddr64"),
			SymGetSymFromAddr64: cast(SymGetSymFromAddr64Func) get("SymGetSymFromAddr64"));
	}

	extern(Windows) @system void RtlCaptureContext(CONTEXT* ContextRecord);
} else {
	alias unw_word_t = uintptr_t;
	struct unw_context_t {
		ulong[1024] data = void;
	}
	struct unw_cursor_t {
		ulong[1024] data = void;
	}

	@system:
	int unw_getcontext(unw_context_t* a) =>
		_Ux86_64_getcontext(a);
	extern(C) int _Ux86_64_getcontext(unw_context_t*);
	int unw_init_local(unw_cursor_t* a, unw_context_t* b) =>
		_ULx86_64_init_local(a, b);
	extern(C) int _ULx86_64_init_local(unw_cursor_t*, unw_context_t*);
	int unw_step(unw_cursor_t* a) =>
		_ULx86_64_step(a);
	extern(C) int _ULx86_64_step(unw_cursor_t*);
	int unw_get_proc_name(unw_cursor_t* a, char* b, size_t c, unw_word_t* d) =>
		_ULx86_64_get_proc_name(a, b, c, d);
	extern(C) int _ULx86_64_get_proc_name(unw_cursor_t*, char*, size_t, unw_word_t*);
}
