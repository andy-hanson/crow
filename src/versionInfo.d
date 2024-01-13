module versionInfo;

@safe @nogc pure nothrow:

import model.model : VersionFun;

immutable struct VersionInfo {
	@safe @nogc pure nothrow:
	private:
	bool isInterpreted;
	bool isJit;
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
			return isWasm;
		case VersionFun.isWasm:
			return isWasm;
		case VersionFun.isWindows:
			version (Windows) {
				return true;
			} else {
				return false;
			}
	}
}

VersionInfo versionInfoForInterpret() =>
	VersionInfo(isInterpreted: true, isJit: false);

VersionInfo versionInfoForJIT() =>
	VersionInfo(isInterpreted: false, isJit: true);

VersionInfo versionInfoForBuildToC() =>
	VersionInfo(isInterpreted: false, isJit: false);

private:

bool isWasm() {
	version (WebAssembly) {
		return true;
	} else {
		return false;
	}
}
