module app.cCompile;

@safe @nogc nothrow: // not pure

import app.appUtil : printError;
import app.fileSystem : printSignalAndExit, spawnAndWait;
version (Windows) {
	import app.fileSystem : findPathToCl;
}
import frontend.lang : OptimizationLevel;
import lib.cliParser : CCompileOptions;
import model.lowModel : ExternLibraries, ExternLibrary;
import util.alloc.alloc : Alloc;
import util.col.arrayBuilder : buildArray, Builder;
import util.exitCode : ExitCode;
import util.opt : force, has, none;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.string : CString, cString;
import util.symbol : AllSymbols, concatSymbols, cStringOfSymbol, Symbol, symbol, writeSymbol;
import util.uri : AllUris, asFileUri, childFileUri, FileUri, cStringOfFileUri, isFileUri, Uri, writeFileUri;
import util.util : todo;
import util.writer : withWriter, Writer;

@trusted ExitCode compileC(
	scope ref Perf perf,
	ref Alloc alloc,
	scope ref AllSymbols allSymbols,
	scope ref AllUris allUris,
	in FileUri cPath,
	in Uri exePath,
	in ExternLibraries externLibraries,
	in CCompileOptions options,
) {
	if (!isFileUri(allUris, exePath))
		return printError(cString!"Can't compile to non-file path\n");

	CString[] args = cCompileArgs(
		alloc, allSymbols, allUris, cPath, asFileUri(allUris, exePath), externLibraries, options);
	version (Windows) {
		TempStrForPath clPath = void;
		ExitCode clErr = findPathToCl(clPath);
		if (clErr != ExitCode.ok)
			return clErr;
		scope CString executable = CString(cast(immutable) clPath.ptr);
	} else {
		scope CString executable = cString!"/usr/bin/cc";
	}
	return withMeasure!(ExitCode, () =>
		printSignalAndExit(spawnAndWait(alloc, allSymbols, allUris, externLibraries, executable, args)),
	)(perf, alloc, PerfMeasure.cCompile);
}

pure:
private:

CString[] cCompileArgs(
	ref Alloc alloc,
	scope ref AllSymbols allSymbols,
	scope ref AllUris allUris,
	in FileUri cPath,
	in FileUri exePath,
	in ExternLibraries externLibraries,
	in CCompileOptions options,
) =>
	buildArray(alloc, (scope ref Builder!CString args) {
		args ~= cCompilerArgs(options);
		args ~= cStringOfFileUri(alloc, allUris, cPath);
		getLinkOptions(alloc, allSymbols, allUris, externLibraries, (CString x) { args ~= x; });
		version (Windows) {
			args ~= [
				cString!"/DEBUG",
				withWriter(writer, (scope ref Writer writer) {
					writer ~= "/out:";
					writeFileUri(writer, allUris, exePath);
				}),
			];
		} else
			args ~= [cString!"-o", cStringOfFileUri(alloc, allUris, exePath)];
	});

public void getLinkOptions(
	ref Alloc alloc,
	scope ref AllSymbols allSymbols,
	scope ref AllUris allUris,
	in ExternLibraries externLibraries,
	in void delegate(CString) @safe @nogc pure nothrow cb,
) {
	version (Windows) {
		cb(cString!"/link");
	}
	foreach (ExternLibrary x; externLibraries) {
		version (Windows) {
			Symbol xDotLib = concatSymbols(allSymbols, [x.libraryName, symbol!".lib"]);
			if (has(x.configuredDir)) {
				cb(cStringOfFileUri(alloc, allUris, childFileUri(allUris, force(x.configuredDir), xDotLib)));
			} else
				switch (x.libraryName.value) {
					case symbol!"c".value:
					case symbol!"m".value:
						break;
					default:
						cb(cStringOfSymbol(alloc, allSymbols, xDotLib));
						break;
				}
		} else {
			if (has(x.configuredDir)) {
				cb(withWriter(alloc, (scope ref Writer writer) {
					writer ~= "-L/";
					if (!isFileUri(allUris, force(x.configuredDir)))
						todo!void("diagnostic: can't link to non-file");
					writeFileUri(writer, allUris, asFileUri(allUris, force(x.configuredDir)));
				}));
			}

			cb(withWriter(alloc, (scope ref Writer writer) {
				writer ~= "-l";
				writeSymbol(writer, allSymbols, x.libraryName);
			}));
		}
	}
}

CString[] cCompilerArgs(in CCompileOptions options) {
	version (Windows) {
		static immutable CString[] optimizedArgs = [
			cString!"/Zi",
			cString!"/std:c17",
			cString!"/Wall",
			cString!"/wd4034",
			cString!"/wd4098",
			cString!"/wd4100",
			cString!"/wd4295",
			cString!"/wd4820",
			cString!"/WX",
			cString!"/O2",
		];
		static immutable CString[] regularArgs = optimizedArgs[0 .. $ - 1];
	} else {
		static immutable CString[] optimizedArgs = [
			cString!"-Werror",
			cString!"-Wextra",
			cString!"-Wall",
			cString!"-ansi",
			cString!"-std=c17",
			cString!"-Wno-address-of-packed-member",
			cString!"-Wno-builtin-declaration-mismatch",
			cString!"-Wno-div-by-zero",
			cString!"-Wno-maybe-uninitialized",
			cString!"-Wno-missing-field-initializers",
			cString!"-Wno-unused-but-set-parameter",
			cString!"-Wno-unused-but-set-variable",
			cString!"-Wno-unused-function",
			cString!"-Wno-unused-parameter",
			cString!"-Wno-unused-variable",
			cString!"-Wno-unused-value",
			cString!"-Ofast",
		];
		static immutable CString[] regularArgs = optimizedArgs[0 .. $ - 1] ~ [cString!"-g"];
	}
	final switch (options.optimizationLevel) {
		case OptimizationLevel.none:
			return regularArgs;
		case OptimizationLevel.o2:
			return optimizedArgs;
	}
}

