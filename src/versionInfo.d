module versionInfo;

@safe @nogc pure nothrow:

immutable struct VersionInfo {
	@safe @nogc pure nothrow:

	bool isInterpreted;
	bool isJit;

	bool isSingleThreaded() =>
		isWasm();

	bool isWasm() {
		version (WebAssembly) {
			return true;
		} else {
			return false;
		}
	}


	bool isWindows() {
		version (Windows) {
			return true;
		} else {
			return false;
		}
	}

	bool isBigEndian() {
		version (BigEndian) {
			return true;
		} else {
			return false;
		}
	}
}

VersionInfo versionInfoForInterpret() =>
	VersionInfo(true, false);

version (WebAssembly) {} else {
	VersionInfo versionInfoForJIT() =>
		VersionInfo(false, true);

	VersionInfo versionInfoForBuildToC() =>
		VersionInfo(false, false);
}
