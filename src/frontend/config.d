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
import util.col.dict : Dict;
import util.col.dictBuilder : finishDict, DictBuilder, tryAddToDict;
import util.col.str : SafeCStr;
import util.readOnlyStorage : ReadFileResult, ReadOnlyStorage, withFileText;
import util.opt : force, has, none, Opt, some;
import util.jsonParse : Json, parseJson;
import util.path : AllPaths, childPath, commonAncestor, parent, parseAbsoluteOrRelPath, Path, PathAndRange;
import util.sourceRange : RangeWithinFile;
import util.sym : AllSymbols, Sym, sym;
import util.util : todo;

Config getConfig(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in ReadOnlyStorage storage,
	scope ref DiagnosticsBuilder diagsBuilder,
	in Path[] rootPaths,
) {
	Opt!Path search = rootPaths.length == 1
		? parent(allPaths, only(rootPaths))
		: some(commonAncestor(allPaths, rootPaths));
	return has(search)
		? getConfigRecur(alloc, allSymbols, allPaths, storage, diagsBuilder, force(search))
		: emptyConfig;
}

private:

Config getConfigRecur(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	in ReadOnlyStorage storage,
	scope ref DiagnosticsBuilder diagsBuilder,
	Path searchPath,
) {
	Path configPath = childPath(allPaths, searchPath, sym!"crow-config");
	ArrBuilder!DiagnosticWithinFile diags;
	Opt!Config res = withFileText!(Opt!Config)(
		storage,
		configPath,
		sym!".json",
		(in ReadFileResult!SafeCStr a) =>
			a.matchIn!(Opt!Config)(
				(in SafeCStr content) @safe =>
					some(parseConfig(alloc, allSymbols, allPaths, searchPath, diags, content)),
				(in ReadFileResult!SafeCStr.NotFound) =>
					none!Config,
				(in ReadFileResult!SafeCStr.Error) {
					add(alloc, diags, DiagnosticWithinFile(RangeWithinFile.empty, Diag(
						ParseDiag(ParseDiag.FileReadError(none!PathAndRange)))));
					return some(emptyConfig);
				}));
	foreach (ref DiagnosticWithinFile d; finishArr(alloc, diags))
		todo!void("!");
	if (has(res))
		return force(res);
	else {
		Opt!Path par = parent(allPaths, searchPath);
		return has(par)
			? getConfigRecur(alloc, allSymbols, allPaths, storage, diagsBuilder, force(par))
			: emptyConfig;
	}
}

pure:

Config emptyConfig() =>
	Config(ConfigImportPaths(), ConfigExternPaths());

Config withInclude(Config a, ConfigImportPaths include) =>
	Config(include, a.extern_);

Config withExtern(Config a, ConfigExternPaths extern_) =>
	Config(a.include, extern_);

Config parseConfig(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	Path dirContainingConfig,
	scope ref ArrBuilder!DiagnosticWithinFile diags,
	in SafeCStr content,
) {
	Opt!Json json = parseJson(alloc, allSymbols, content);
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

Config parseConfigRecur(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	Path dirContainingConfig,
	scope ref ArrBuilder!DiagnosticWithinFile diags,
	in Json.Object fields,
) =>
	fold!(Config, Json.ObjectField)(emptyConfig, fields, (Config cur, in Json.ObjectField field) {
		Json value = field.value;
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

Dict!(Sym, Path) parseIncludeOrExtern(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllPaths allPaths,
	Path dirContainingConfig,
	scope ref ArrBuilder!DiagnosticWithinFile diags,
	in Json json,
) {
	DictBuilder!(Sym, Path) res;
	if (json.isA!(Json.Object)) {
		foreach (ref Json.ObjectField field; json.as!(Json.Object)) {
			if (field.value.isA!SafeCStr) {
				Path value = parseAbsoluteOrRelPath(allPaths, dirContainingConfig, field.value.as!SafeCStr);
				Opt!Path before = tryAddToDict(alloc, res, field.key, value);
				if (has(before))
					todo!void("diag -- duplicate include key");
			} else
				todo!void("diag -- 'include' values should be strings");
		}
	} else
		todo!void("diag -- include should be an object");
	return finishDict(alloc, res);
}
