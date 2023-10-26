module frontend.config;

@safe @nogc nothrow: // not pure

import frontend.diagnosticsBuilder : DiagnosticsBuilder;
import model.diag : Diag, DiagnosticWithinFile;
import model.model : Config, ConfigExternUris, ConfigImportUris;
import model.parseDiag : ParseDiag;
import util.alloc.alloc : Alloc;
import util.col.arr : only;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : fold;
import util.col.map : Map;
import util.col.mapBuilder : finishMap, MapBuilder, tryAddToMap;
import util.col.str : SafeCStr;
import util.readOnlyStorage : ReadFileResult, ReadOnlyStorage, withFileText;
import util.opt : force, has, none, Opt, some;
import util.json : Json;
import util.jsonParse : parseJson;
import util.sourceRange : RangeWithinFile;
import util.sym : AllSymbols, Sym, sym;
import util.uri : AllUris, bogusUri, childUri, commonAncestor, parent, parseUriWithCwd, Uri, UriAndRange;
import util.util : todo;

Config getConfig(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllUris allUris,
	in ReadOnlyStorage storage,
	scope ref DiagnosticsBuilder diagsBuilder,
	in Uri[] rootUris,
) {
	Opt!Uri search = rootUris.length == 1
		? parent(allUris, only(rootUris))
		: commonAncestor(allUris, rootUris);
	return has(search)
		? getConfigRecur(alloc, allSymbols, allUris, storage, diagsBuilder, force(search))
		: emptyConfig;
}

private:

Config getConfigRecur(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllUris allUris,
	in ReadOnlyStorage storage,
	scope ref DiagnosticsBuilder diagsBuilder,
	Uri searchUri,
) {
	Uri configUri = childUri(allUris, searchUri, sym!"crow-config.json");
	ArrBuilder!DiagnosticWithinFile diags;
	Opt!Config res = withFileText!(Opt!Config)(storage, configUri, (in ReadFileResult!SafeCStr a) =>
		a.matchIn!(Opt!Config)(
			(in SafeCStr content) =>
				some(parseConfig(alloc, allSymbols, allUris, searchUri, diags, content)),
			(in ReadFileResult!SafeCStr.NotFound) =>
				none!Config,
			(in ReadFileResult!SafeCStr.Error) {
				add(alloc, diags, DiagnosticWithinFile(RangeWithinFile.empty, Diag(
					ParseDiag(ParseDiag.FileReadError(none!UriAndRange)))));
				return some(emptyConfig);
			}));
	foreach (ref DiagnosticWithinFile d; finishArr(alloc, diags))
		todo!void("!");
	if (has(res))
		return force(res);
	else {
		Opt!Uri par = parent(allUris, searchUri);
		return has(par)
			? getConfigRecur(alloc, allSymbols, allUris, storage, diagsBuilder, force(par))
			: emptyConfig;
	}
}

pure:

Config emptyConfig() =>
	Config(ConfigImportUris(), ConfigExternUris());

Config withInclude(Config a, ConfigImportUris include) =>
	Config(include, a.extern_);

Config withExtern(Config a, ConfigExternUris extern_) =>
	Config(a.include, extern_);

Config parseConfig(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllUris allUris,
	Uri dirContainingConfig,
	scope ref ArrBuilder!DiagnosticWithinFile diags,
	in SafeCStr content,
) {
	Opt!Json json = parseJson(alloc, allSymbols, content);
	if (has(json)) {
		if (force(json).isA!(Json.Object))
			return parseConfigRecur(
				alloc, allSymbols, allUris, dirContainingConfig, diags, force(json).as!(Json.Object));
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
	ref AllUris allUris,
	Uri dirContainingConfig,
	scope ref ArrBuilder!DiagnosticWithinFile diags,
	in Json.Object fields,
) =>
	fold!(Config, Json.ObjectField)(emptyConfig, fields, (Config cur, in Json.ObjectField field) {
		Json value = field.value;
		switch (field.key.value) {
			case sym!"include".value:
				return withInclude(
					cur,
					parseIncludeOrExtern(alloc, allSymbols, allUris, dirContainingConfig, diags, value));
			case sym!"extern".value:
				return withExtern(
					cur,
					parseIncludeOrExtern(alloc, allSymbols, allUris, dirContainingConfig, diags, value));
			default:
				todo!void("diag -- bad key");
				return cur;
		}
	});

Map!(Sym, Uri) parseIncludeOrExtern(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	ref AllUris allUris,
	Uri dirContainingConfig,
	scope ref ArrBuilder!DiagnosticWithinFile diags,
	in Json json,
) =>
	parseSymMap!Uri(alloc, allSymbols, diags, json, (in Json value) {
		Opt!Uri res = parseUri(allUris, dirContainingConfig, diags, value);
		return has(res) ? force(res) : bogusUri(allUris);
	});

Opt!Uri parseUri(
	ref AllUris allUris,
	Uri dirContainingConfig,
	scope ref ArrBuilder!DiagnosticWithinFile diags,
	in Json json,
) {
	if (json.isA!string)
		return some(parseUriWithCwd(allUris, dirContainingConfig, json.as!string));
	else {
		todo!void("diag -- 'include' values should be strings");
		return none!Uri;
	}
}

Map!(Sym, T) parseSymMap(T)(
	ref Alloc alloc,
	ref AllSymbols allSymbols,
	scope ref ArrBuilder!DiagnosticWithinFile diags,
	in Json json,
	in T delegate(in Json) @safe @nogc pure nothrow cbValue,
) {
	MapBuilder!(Sym, T) res;
	if (json.isA!(Json.Object)) {
		foreach (ref Json.ObjectField field; json.as!(Json.Object)) {
			T value = cbValue(field.value);
			Opt!T before = tryAddToMap(alloc, res, field.key, value);
			if (has(before))
				todo!void("diag -- duplicate include key");
		}
	} else
		todo!void("diag -- include should be an object");
	return finishMap(alloc, res);
}
