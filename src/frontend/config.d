module frontend.config;

@safe @nogc nothrow: // not pure

import frontend.diagnosticsBuilder : DiagnosticsBuilder;
import model.diag : Diag, DiagnosticWithinFile;
import model.model : Config, ConfigExternPaths, ConfigImportPaths;
import model.parseDiag : ParseDiag;
import util.alloc.alloc : Alloc;
import util.col.arr : only;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : fold;
import util.col.dict : KeyValuePair, Dict;
import util.col.dictBuilder : finishDict, DictBuilder, tryAddToDict;
import util.col.str : SafeCStr;
import util.readOnlyStorage : ReadFileResult, ReadOnlyStorage, withFileText;
import util.opt : force, has, none, Opt, some;
import util.jsonParse : Json, parseJson;
import util.path : AllPaths, childPath, commonAncestor, parent, parseAbsoluteOrRelPath, Path, PathAndRange;
import util.sourceRange : RangeWithinFile;
import util.sym : AllSymbols, Sym, sym;
import util.util : todo;

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
	immutable Path configPath = childPath(allPaths, searchPath, sym!"crow-config");
	ArrBuilder!DiagnosticWithinFile diags;
	immutable Opt!Config res = withFileText(
		storage,
		configPath,
		sym!".json",
		(immutable ReadFileResult!SafeCStr a) =>
			a.match!(immutable Opt!Config)(
				(immutable SafeCStr content) pure =>
					some(parseConfig(alloc, allSymbols, allPaths, searchPath, diags, content)),
				(immutable(ReadFileResult!SafeCStr.NotFound)) pure =>
					none!Config,
				(immutable(ReadFileResult!SafeCStr.Error)) pure {
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

immutable(Config) emptyConfig() =>
	immutable Config(immutable ConfigImportPaths(), immutable ConfigExternPaths());

immutable(Config) withInclude(immutable Config a, immutable ConfigImportPaths include) =>
	immutable Config(include, a.extern_);

immutable(Config) withExtern(immutable Config a, immutable ConfigExternPaths extern_) =>
	immutable Config(a.include, extern_);

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
		if (force(json).isA!(Json.Object))
			return parseConfigRecur(
				alloc, allSymbols, allPaths, dirContainingConfig, diags, force(json).as!(Json.Object));
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
) =>
	fold(emptyConfig, fields, (immutable Config cur, ref immutable KeyValuePair!(Sym, Json) field) {
		immutable Json value = field.value;
		switch (field.key.value) {
			case sym!"include".value:
				return withInclude(
					cur,
					parseIncludeOrExtern(alloc, allSymbols, allPaths, dirContainingConfig, diags, value));
			case sym!"extern".value:
				return withExtern(
					cur,
					parseIncludeOrExtern(alloc, allSymbols, allPaths, dirContainingConfig, diags, value));
			default:
				todo!void("diag -- bad key");
				return cur;
		}
	});

immutable(Dict!(Sym, Path)) parseIncludeOrExtern(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	immutable Path dirContainingConfig,
	ref ArrBuilder!DiagnosticWithinFile diags,
	immutable Json json,
) {
	DictBuilder!(Sym, Path) res;
	if (json.isA!(Json.Object)) {
		foreach (immutable KeyValuePair!(Sym, Json) field; json.as!(Json.Object)) {
			if (field.value.isA!SafeCStr) {
				immutable Path value = parseAbsoluteOrRelPath(allPaths, dirContainingConfig, field.value.as!SafeCStr);
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
