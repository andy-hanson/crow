module frontend.config;

@safe @nogc pure nothrow:

import model.diag : Diagnostic;
import model.model : Config, ConfigExternUris, ConfigImportUris;
import util.alloc.alloc : Alloc;
import util.col.arrBuilder : ArrBuilder, finishArr;
import util.col.arrUtil : arrLiteral, fold;
import util.col.map : Map;
import util.col.mapBuilder : finishMap, MapBuilder, tryAddToMap;
import util.col.str : SafeCStr;
import util.json : Json;
import util.opt : force, has, none, Opt, some;
import util.jsonParse : parseJson;
import util.sym : AllSymbols, Sym, sym;
import util.uri : AllUris, bogusUri, parentOrEmpty, parseUriWithCwd, Uri;
import util.util : todo;

Config parseConfig(
	ref Alloc alloc,
	scope ref AllSymbols allSymbols,
	scope ref AllUris allUris,
	Uri configUri,
	in SafeCStr text,
) {
	ArrBuilder!Diagnostic diagsBuilder;
	Opt!Json json = parseJson(alloc, allSymbols, text); // TODO: this should take diagsBuilder
	if (has(json) && force(json).isA!(Json.Object)) {
		ConfigContent content = parseConfigRecur(
			alloc, allSymbols, allUris, parentOrEmpty(allUris, configUri), diagsBuilder, force(json).as!(Json.Object));
		return Config(some(configUri), finishArr(alloc, diagsBuilder), content.include, content.extern_);
	} else
		return Config(some(configUri), arrLiteral(alloc, [todo!Diagnostic("diag -- bad JSON")]));
}

private:

ConfigContent emptyConfigContent() =>
	ConfigContent(ConfigImportUris(), ConfigExternUris());

ConfigContent withInclude(ConfigContent a, ConfigImportUris include) =>
	ConfigContent(include, a.extern_);

ConfigContent withExtern(ConfigContent a, ConfigExternUris extern_) =>
	ConfigContent(a.include, extern_);

struct ConfigContent {
	ConfigImportUris include;
	ConfigExternUris extern_;
}

ConfigContent parseConfigRecur(
	ref Alloc alloc,
	scope ref AllSymbols allSymbols,
	scope ref AllUris allUris,
	Uri dirContainingConfig,
	scope ref ArrBuilder!Diagnostic diags,
	in Json.Object fields,
) =>
	fold!(ConfigContent, Json.ObjectField)(emptyConfigContent, fields, (ConfigContent cur, in Json.ObjectField field) {
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
	scope ref AllSymbols allSymbols,
	scope ref AllUris allUris,
	Uri dirContainingConfig,
	scope ref ArrBuilder!Diagnostic diags,
	in Json json,
) =>
	parseSymMap!Uri(alloc, allSymbols, diags, json, (in Json value) {
		Opt!Uri res = parseUri(allUris, dirContainingConfig, diags, value);
		return has(res) ? force(res) : bogusUri(allUris);
	});

Opt!Uri parseUri(
	scope ref AllUris allUris,
	Uri dirContainingConfig,
	scope ref ArrBuilder!Diagnostic diags,
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
	scope ref ArrBuilder!Diagnostic diags,
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
