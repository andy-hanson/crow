module versionInfo;

@safe @nogc nothrow: // not pure

enum OS {
	linux,
	web,
	windows,
}

OS getOS() {
	version (linux) {
		return OS.linux;
	} else version (Windows) {
		return OS.windows;
	} else version (WebAssembly) {
		return OS.web;
	} else
		static assert(false);
}

pure:

immutable struct VersionOptions {
	@safe @nogc pure nothrow:
	bool isSingleThreaded;
	bool stackTraceEnabled;

	static VersionOptions default_() =>
		VersionOptions(isSingleThreaded: false, stackTraceEnabled: true);
}

immutable struct VersionInfo {
	private:
	public OS os;
	VersionOptions options;
	public bool isInterpreted;
	bool isJit;
}

VersionInfo versionInfoForInterpret(OS os, VersionOptions options) =>
	VersionInfo(os: os, isInterpreted: true, isJit: false, options: options);

VersionInfo versionInfoForJIT(OS os, VersionOptions options) =>
	VersionInfo(os: os, isInterpreted: false, isJit: true, options: options);

VersionInfo versionInfoForBuildToC(OS os, VersionOptions options) =>
	VersionInfo(os: os, isInterpreted: false, isJit: false, options: options);

VersionInfo versionInfoForBuildToJS() =>
	VersionInfo(OS.web, VersionOptions(isSingleThreaded: true, stackTraceEnabled: true), isInterpreted: false, isJit: false);

enum VersionFun {
	isBigEndian,
	isInterpreted,
	isJit,
	isSingleThreaded,
	isStackTraceEnabled,
	isWasm,
	isWindows,
}

bool isVersion(in VersionInfo a, VersionFun fun) {
	final switch (fun) {
		case VersionFun.isBigEndian:
			version (BigEndian) {
				return true;
			} else {
				return false;
			}
		case VersionFun.isInterpreted:
			return a.isInterpreted;
		case VersionFun.isJit:
			return a.isJit;
		case VersionFun.isSingleThreaded:
			return isWasm || a.options.isSingleThreaded;
		case VersionFun.isWasm:
			return isWasm;
		case VersionFun.isWindows:
			return isWindows(a);
		case VersionFun.isStackTraceEnabled:
			return a.options.stackTraceEnabled;
	}
}

bool isWindows(in VersionInfo a) {
	final switch (a.os) {
		case OS.linux:
		case OS.web:
			return false;
		case OS.windows:
			return true;
	}
}

private:

bool isWasm() {
	version (WebAssembly) {
		return true;
	} else {
		return false;
	}
}
