module frontend.config;

@safe @nogc nothrow: // not pure

import frontend.diagnosticsBuilder : DiagnosticsBuilder;
import model.diag : Diag, DiagnosticWithinFile;
import model.parseDiag : ParseDiag;
import util.alloc.alloc : Alloc;
import util.col.arr : only;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : fold;
import util.col.dict : KeyValuePair, SymDict;
import util.col.dictBuilder : finishDict, SymDictBuilder, tryAddToDict;
import util.col.str : SafeCStr, safeCStr;
import util.readOnlyStorage : matchReadFileResult, ReadFileResult, ReadOnlyStorage, withFile;
import util.opt : force, has, none, Opt, some;
import util.jsonParse : asObject, asString, isObject, isString, Json, parseJson;
import util.path : AllPaths, childPath, commonAncestor, parent, parseAbsoluteOrRelPath, Path, PathAndRange;
import util.sourceRange : RangeWithinFile;
import util.sym : AllSymbols, shortSym, Sym, symEq;
import util.util : todo;

struct Config {
	immutable SymDict!Path include;
}

immutable(Config) getConfig(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	scope ref const ReadOnlyStorage storage,
	ref DiagnosticsBuilder diagsBuilder,
	scope immutable Path[] rootPaths,
) {
	immutable Opt!Path search = rootPaths.length == 1
		? parent(allPaths, only(rootPaths))
		: some(commonAncestor(allPaths, rootPaths));
	return has(search)
		? getConfigRecur(alloc, allSymbols, allPaths, storage, diagsBuilder, force(search))
		: emptyConfig;
}

private:

immutable(Config) getConfigRecur(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	scope ref const ReadOnlyStorage storage,
	ref DiagnosticsBuilder diagsBuilder,
	immutable Path searchPath,
) {
	immutable Path configPath = childPath(allPaths, searchPath, shortSym("crow-config"));
	ArrBuilder!DiagnosticWithinFile diags;
	immutable Opt!Config res = withFile(storage, configPath, safeCStr!".json", (immutable ReadFileResult a) =>
		matchReadFileResult!(immutable Opt!Config)(
			a,
			(immutable SafeCStr content) pure =>
				some(parseConfig(alloc, allSymbols, allPaths, searchPath, diags, content)),
			(immutable(ReadFileResult.NotFound)) pure =>
				none!Config,
			(immutable(ReadFileResult.Error)) pure {
				add(alloc, diags, immutable DiagnosticWithinFile(RangeWithinFile.empty, immutable Diag(
					immutable ParseDiag(immutable ParseDiag.FileReadError(none!PathAndRange)))));
				return some(emptyConfig);
			}));
	foreach (immutable DiagnosticWithinFile d; finishArr(alloc, diags))
		todo!void("!");
	if (has(res))
		return force(res);
	else {
		immutable Opt!Path par = parent(allPaths, searchPath);
		return has(par)
			? getConfigRecur(alloc, allSymbols, allPaths, storage, diagsBuilder, force(par))
			: emptyConfig;
	}
}

pure:

immutable(Config) emptyConfig() {
	return immutable Config(immutable SymDict!Path());
}

immutable(Config) withInclude(immutable(Config), immutable SymDict!Path include) {
	return immutable Config(include);
}

immutable(Config) parseConfig(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	immutable Path dirContainingConfig,
	ref ArrBuilder!DiagnosticWithinFile diags,
	immutable SafeCStr content,
) {
	immutable Opt!Json json = parseJson(alloc, allSymbols, content);
	if (has(json)) {
		if (isObject(force(json)))
			return parseConfigRecur(alloc, allSymbols, allPaths, dirContainingConfig, diags, asObject(force(json)));
		else {
			todo!void("diag -- expected object at root");
			return emptyConfig;
		}
	} else {
		todo!void("diag -- bad JSON");
		return emptyConfig;
	}
}

immutable(Config) parseConfigRecur(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	immutable Path dirContainingConfig,
	ref ArrBuilder!DiagnosticWithinFile diags,
	immutable KeyValuePair!(Sym, Json)[] fields,
) {
	return fold(emptyConfig, fields, (immutable Config cur, ref immutable KeyValuePair!(Sym, Json) field) {
		if (symEq(field.key, shortSym("include"))) {
			return withInclude(cur, parseInclude(alloc, allSymbols, allPaths, dirContainingConfig, diags, field.value));
		} else {
			todo!void("diag -- bad key");
			return cur;
		}
	});
}

immutable(SymDict!Path) parseInclude(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	immutable Path dirContainingConfig,
	ref ArrBuilder!DiagnosticWithinFile diags,
	immutable Json json,
) {
	SymDictBuilder!Path res;
	if (isObject(json)) {
		foreach (immutable KeyValuePair!(Sym, Json) field; asObject(json)) {
			if (isString(field.value)) {
				immutable Path value = parseAbsoluteOrRelPath(allPaths, dirContainingConfig, asString(field.value));
				immutable Opt!Path before = tryAddToDict(alloc, res, field.key, value);
				if (has(before))
					todo!void("diag -- duplicate include key");
			} else
				todo!void("diag -- 'include' values should be strings");
		}
	} else
		todo!void("diag -- include should be an object");
	return finishDict(alloc, res);
}
