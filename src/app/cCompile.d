module backend.cCompile;

@safe @nogc nothrow: // not pure

import app.appUtil : printError;
import app.fileSystem : spawnAndWait;
version (Windows) {
	import app.fileSystem : findPathToCl;
}
import frontend.lang : OptimizationLevel;
import lib.cliParser : CCompileOptions;
import model.lowModel : ExternLibrary;
import util.alloc.alloc : Alloc;
import util.col.arrBuilder : add, addAll, finishArr, ArrBuilder;
import util.exitCode : ExitCode;
import util.opt : force, has, none;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.string : CString, cString;
import util.symbol : AllSymbols, concatSyms, cStringOfSymbol, Symbol, symbol, writeSym;
import util.uri : AllUris, asFileUri, childFileUri, FileUri, cStringOfFileUri, isFileUri, Uri, writeFileUri;
import util.util : todo;
import util.writer : withWriter, Writer;

@trusted ExitCode compileC(
	scope ref Perf perf,
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllUris allUris,
	in FileUri cPath,
	in Uri exePath,
	in ExternLibrary[] externLibraries,
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
		spawnAndWait(alloc, allUris, executable, args)
	)(perf, alloc, PerfMeasure.cCompile);
}

pure:
private:

CString[] cCompileArgs(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllUris allUris,
	in FileUri cPath,
	in FileUri exePath,
	in ExternLibrary[] externLibraries,
	in CCompileOptions options,
) {
	ArrBuilder!CString args;
	addAll(alloc, args, cCompilerArgs(options));
	add(alloc, args, cStringOfFileUri(alloc, allUris, cPath));
	version (Windows) {
		add(alloc, args, cString!"/link");
	}
	foreach (ExternLibrary x; externLibraries) {
		version (Windows) {
			Symbol xDotLib = concatSyms(allSymbols, [x.libraryName, symbol!".lib"]);
			if (has(x.configuredDir)) {
				FileUri path = childFileUri(allUris, force(x.configuredDir), xDotLib);
				add(alloc, args, cStringOfFileUri(alloc, allUris, path));
			} else
				switch (x.libraryName.value) {
					case symbol!"c".value:
					case symbol!"m".value:
						break;
					default:
						add(alloc, args, cStringOfSymbol(alloc, allSymbols, xDotLib));
						break;
				}
		} else {
			if (has(x.configuredDir)) {
				add(alloc, args, withWriter(alloc, (scope ref Writer writer) {
					writer ~= "-L";
					if (!isFileUri(allUris, force(x.configuredDir)))
						todo!void("diagnostic: can't link to non-file");
					writeFileUri(writer, allUris, asFileUri(allUris, force(x.configuredDir)));
				}));
			}

			add(alloc, args, withWriter(alloc, (scope ref Writer writer) {
				writer ~= "-l";
				writeSym(writer, allSymbols, x.libraryName);
			}));
		}
	}
	version (Windows) {
		add(alloc, args, cString!"/DEBUG");
		add(alloc, args, withWriter(writer, (scope ref Writer writer) {
			writer ~= "/out:";
			writeFileUri(writer, allUris, exePath);
		}));
	} else {
		add(alloc, args, cString!"-lm");
		addAll(alloc, args, [
			cString!"-o",
			cStringOfFileUri(alloc, allUris, exePath),
		]);
	}
	return finishArr(alloc, args);
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
			cString!"-Wno-maybe-uninitialized",
			cString!"-Wno-missing-field-initializers",
			cString!"-Wno-unused-function",
			cString!"-Wno-unused-parameter",
			cString!"-Wno-unused-but-set-variable",
			cString!"-Wno-unused-variable",
			cString!"-Wno-unused-value",
			cString!"-Wno-builtin-declaration-mismatch",
			cString!"-Wno-address-of-packed-member",
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

