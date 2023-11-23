module frontend.config;

@safe @nogc pure nothrow:

import frontend.lang : crowConfigBaseName;
import frontend.storage : getParsedOrDiag, ParseResult, Storage;
import model.diag : Diag, Diagnostic, ReadFileDiag;
import model.model : Config, ConfigExternUris, ConfigImportUris;
import model.parseDiag : ParseDiag;
import util.alloc.alloc : Alloc;
import util.col.arr : only;
import util.col.arrBuilder : ArrBuilder, finishArr;
import util.col.arrUtil : arrLiteral, fold;
import util.col.map : Map;
import util.col.mapBuilder : finishMap, MapBuilder, tryAddToMap;
import util.col.str : SafeCStr;
import util.json : Json;
import util.opt : force, has, none, Opt, some;
import util.jsonParse : parseJson;
import util.sourceRange : Range;
import util.sym : AllSymbols, Sym, sym;
import util.uri : AllUris, bogusUri, childUri, commonAncestor, parent, parseUriWithCwd, Uri;
import util.util : todo;

Config getConfig(
	ref Alloc alloc,
	scope ref AllSymbols allSymbols,
	scope ref AllUris allUris,
	Uri crowIncludeDir,
	ref Storage storage,
	in Uri[] rootUris,
) {
	Opt!Uri search = rootUris.length == 1
		? parent(allUris, only(rootUris))
		: commonAncestor(allUris, rootUris);
	return has(search)
		? getConfigRecur(alloc, allSymbols, allUris, crowIncludeDir, storage, force(search))
		: emptyConfig(none!Uri, crowIncludeDir, []);
}

private:

Config getConfigRecur(
	ref Alloc alloc,
	scope ref AllSymbols allSymbols,
	scope ref AllUris allUris,
	Uri crowIncludeDir,
	ref Storage storage,
	Uri searchUri,
) {
	Uri configUri = childUri(allUris, searchUri, crowConfigBaseName);
	return getParsedOrDiag(storage, configUri).match!Config(
		(ParseResult x) =>
			configFromParsed(crowIncludeDir, configUri, *x.as!(ParsedConfig*)),
		(ReadFileDiag x) {
			final switch (x) {
				case ReadFileDiag.notFound:
					Opt!Uri par = parent(allUris, searchUri);
					return has(par)
						? getConfigRecur(alloc, allSymbols, allUris, crowIncludeDir, storage, force(par))
						: emptyConfig(none!Uri, crowIncludeDir, []);
				case ReadFileDiag.error:
					return emptyConfig(some(configUri), crowIncludeDir, arrLiteral(alloc, [
						Diagnostic(Range.empty, Diag(ParseDiag(x)))]));
				case ReadFileDiag.loading:
				case ReadFileDiag.unknown:
					return emptyConfig(some(configUri), crowIncludeDir, []);
			}
		});
}

pure:

Config emptyConfig(Opt!Uri configUri, Uri crowIncludeDir, Diagnostic[] diagnostics) =>
	Config(configUri, diagnostics, crowIncludeDir, ConfigImportUris(), ConfigExternUris());

ConfigContent emptyConfigContent() =>
	ConfigContent(ConfigImportUris(), ConfigExternUris());

ConfigContent withInclude(ConfigContent a, ConfigImportUris include) =>
	ConfigContent(include, a.extern_);

ConfigContent withExtern(ConfigContent a, ConfigExternUris extern_) =>
	ConfigContent(a.include, extern_);

Config configFromParsed(Uri crowIncludeDir, Uri configUri, ParsedConfig parsed) =>
	Config(some(configUri), parsed.diagnostics, crowIncludeDir, parsed.include, parsed.extern_);

public immutable struct ParsedConfig {
	Diagnostic[] diagnostics;
	ConfigImportUris include;
	ConfigExternUris extern_;
}

public ParsedConfig parseConfig(
	ref Alloc alloc,
	scope ref AllSymbols allSymbols,
	scope ref AllUris allUris,
	Uri dirContainingConfig,
	in SafeCStr text,
) {
	ArrBuilder!Diagnostic diagsBuilder;
	Opt!Json json = parseJson(alloc, allSymbols, text); // TODO: this should take diagsBuilder
	if (has(json) && force(json).isA!(Json.Object)) {
		ConfigContent content = parseConfigRecur(
			alloc, allSymbols, allUris, dirContainingConfig, diagsBuilder, force(json).as!(Json.Object));
		return ParsedConfig(finishArr(alloc, diagsBuilder), content.include, content.extern_);
	} else
		return ParsedConfig(arrLiteral(alloc, [todo!Diagnostic("diag -- bad JSON")]));
}

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
