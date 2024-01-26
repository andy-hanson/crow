module versionInfo;

@safe @nogc nothrow: // not pure

import model.model : VersionFun;

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

immutable struct VersionInfo {
	private:
	OS os;
	bool isInterpreted;
	bool isJit;
}

VersionInfo versionInfoForInterpret(OS os) =>
	VersionInfo(os: os, isInterpreted: true, isJit: false);

VersionInfo versionInfoForJIT(OS os) =>
	VersionInfo(os: os, isInterpreted: false, isJit: true);

VersionInfo versionInfoForBuildToC(OS os) =>
	VersionInfo(os: os, isInterpreted: false, isJit: false);

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
			return isWasm;
		case VersionFun.isWasm:
			return isWasm;
		case VersionFun.isWindows:
			return isWindows(a);
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
