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
import util.col.str : SafeCStr, safeCStr;
import util.exitCode : ExitCode;
import util.opt : force, has, none;
import util.perf : Perf, PerfMeasure, withMeasure;
import util.sym : AllSymbols, concatSyms, safeCStrOfSym, Sym, sym, writeSym;
import util.uri : AllUris, asFileUri, childFileUri, FileUri, fileUriToSafeCStr, isFileUri, Uri, writeFileUri;
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
		return printError(safeCStr!"Can't compile to non-file path\n");

	SafeCStr[] args = cCompileArgs(
		alloc, allSymbols, allUris, cPath, asFileUri(allUris, exePath), externLibraries, options);
	version (Windows) {
		TempStrForPath clPath = void;
		ExitCode clErr = findPathToCl(clPath);
		if (clErr != ExitCode.ok)
			return clErr;
		scope SafeCStr executable = SafeCStr(cast(immutable) clPath.ptr);
	} else {
		scope SafeCStr executable = safeCStr!"/usr/bin/cc";
	}
	return withMeasure!(ExitCode, () =>
		spawnAndWait(alloc, allUris, executable, args)
	)(perf, alloc, PerfMeasure.cCompile);
}

pure:
private:

SafeCStr[] cCompileArgs(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllUris allUris,
	in FileUri cPath,
	in FileUri exePath,
	in ExternLibrary[] externLibraries,
	in CCompileOptions options,
) {
	ArrBuilder!SafeCStr args;
	addAll(alloc, args, cCompilerArgs(options));
	add(alloc, args, fileUriToSafeCStr(alloc, allUris, cPath));
	version (Windows) {
		add(alloc, args, safeCStr!"/link");
	}
	foreach (ExternLibrary x; externLibraries) {
		version (Windows) {
			Sym xDotLib = concatSyms(allSymbols, [x.libraryName, sym!".lib"]);
			if (has(x.configuredDir)) {
				FileUri path = childFileUri(allUris, force(x.configuredDir), xDotLib);
				add(alloc, args, fileUriToSafeCStr(alloc, allUris, path));
			} else
				switch (x.libraryName.value) {
					case sym!"c".value:
					case sym!"m".value:
						break;
					default:
						add(alloc, args, safeCStrOfSym(alloc, allSymbols, xDotLib));
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
		add(alloc, args, safeCStr!"/DEBUG");
		add(alloc, args, withWriter(writer, (scope ref Writer writer) {
			writer ~= "/out:";
			writeFileUri(writer, allUris, exePath);
		}));
	} else {
		add(alloc, args, safeCStr!"-lm");
		addAll(alloc, args, [
			safeCStr!"-o",
			fileUriToSafeCStr(alloc, allUris, exePath),
		]);
	}
	return finishArr(alloc, args);
}

SafeCStr[] cCompilerArgs(in CCompileOptions options) {
	version (Windows) {
		static immutable SafeCStr[] optimizedArgs = [
			safeCStr!"/Zi",
			safeCStr!"/std:c17",
			safeCStr!"/Wall",
			safeCStr!"/wd4034",
			safeCStr!"/wd4098",
			safeCStr!"/wd4100",
			safeCStr!"/wd4295",
			safeCStr!"/wd4820",
			safeCStr!"/WX",
			safeCStr!"/O2",
		];
		static immutable SafeCStr[] regularArgs = optimizedArgs[0 .. $ - 1];
	} else {
		static immutable SafeCStr[] optimizedArgs = [
			safeCStr!"-Werror",
			safeCStr!"-Wextra",
			safeCStr!"-Wall",
			safeCStr!"-ansi",
			safeCStr!"-std=c17",
			safeCStr!"-Wno-maybe-uninitialized",
			safeCStr!"-Wno-missing-field-initializers",
			safeCStr!"-Wno-unused-function",
			safeCStr!"-Wno-unused-parameter",
			safeCStr!"-Wno-unused-but-set-variable",
			safeCStr!"-Wno-unused-variable",
			safeCStr!"-Wno-unused-value",
			safeCStr!"-Wno-builtin-declaration-mismatch",
			safeCStr!"-Wno-address-of-packed-member",
			safeCStr!"-Ofast",
		];
		static immutable SafeCStr[] regularArgs = optimizedArgs[0 .. $ - 1] ~ [safeCStr!"-g"];
	}
	final switch (options.optimizationLevel) {
		case OptimizationLevel.none:
			return regularArgs;
		case OptimizationLevel.o2:
			return optimizedArgs;
	}
}

