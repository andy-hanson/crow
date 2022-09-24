module versionInfo;

@safe @nogc pure nothrow:

struct VersionInfo {
	@safe @nogc pure nothrow:

	immutable bool isInterpreted;
	immutable bool isJit;

	immutable(bool) isSingleThreaded() immutable =>
		isWasm();

	immutable(bool) isWasm() immutable {
		version (WebAssembly) {
			return true;
		} else {
			return false;
		}
	}


	immutable(bool) isWindows() immutable {
		version (Windows) {
			return true;
		} else {
			return false;
		}
	}

	immutable(bool) isBigEndian() immutable {
		version (BigEndian) {
			return true;
		} else {
			return false;
		}
	}
}

immutable(VersionInfo) versionInfoForInterpret() =>
	immutable VersionInfo(true, false);

version (WebAssembly) {} else {
	immutable(VersionInfo) versionInfoForJIT() =>
		immutable VersionInfo(false, true);

	immutable(VersionInfo) versionInfoForBuildToC() =>
		immutable VersionInfo(false, false);
}
