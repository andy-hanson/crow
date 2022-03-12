module versionInfo;

@safe @nogc pure nothrow:

struct VersionInfo {
	immutable bool isSingleThreaded;
	immutable bool isWasm;
	immutable bool isWindows;
}

immutable(VersionInfo) versionInfoForInterpret() {
	return immutable VersionInfo(true, isWasm(), isWindows());
}

version (WebAssembly) {} else {
	immutable(VersionInfo) versionInfoForJIT() {
		return immutable VersionInfo(false, isWasm(), isWindows());
	}

	immutable(VersionInfo) versionInfoForBuildToC() {
		return immutable VersionInfo(false, isWasm(), isWindows());
	}
}

private:

immutable(bool) isWasm() {
	version (WebAssembly) {
		return true;
	} else {
		return false;
	}
}

immutable(bool) isWindows() {
	version (Windows) {
		return true;
	} else {
		return false;
	}
}
