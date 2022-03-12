module versionInfo;

@safe @nogc pure nothrow:

struct VersionInfo {
	immutable bool isSingleThreaded;
	immutable bool isWindows;
}

immutable(VersionInfo) versionInfoForInterpret() {
	return immutable VersionInfo(true, isWindows());
}

version (WebAssembly) {} else {
	immutable(VersionInfo) versionInfoForJIT() {
		return immutable VersionInfo(false, isWindows());
	}

	immutable(VersionInfo) versionInfoForBuildToC() {
		return immutable VersionInfo(false, isWindows());
	}
}

private:

immutable(bool) isWindows() {
	version (Windows) {
		return true;
	} else {
		return false;
	}
}
