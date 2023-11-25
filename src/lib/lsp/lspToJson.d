module lib.lsp.lspToJson;

@safe @nogc pure nothrow:

import frontend.storage : jsonOfUriAndRange, LineAndColumnGetters;
import lib.lsp.lspTypes :
	Hover,
	InitializeResult,
	LspDiagnostic,
	LspOutMessage,
	LspOutNotification,
	LspOutResponse,
	LspOutResult,
	MarkupContent,
	MarkupKind,
	PublishDiagnosticsParams,
	RegisterCapability,
	TextEdit,
	UnknownUris,
	UnloadedUris,
	WorkspaceEdit;
import util.alloc.alloc : Alloc;
import util.col.arrUtil : arrLiteral, map;
import util.col.multiMap : mapMultiMap, MultiMap;
import util.col.str : strOfSafeCStr;
import util.json : field, Json, jsonList, jsonNull, jsonObject, jsonString;
import util.lineAndColumnGetter : LineAndColumnGetter;
import util.opt : force, has, Opt;
import util.sourceRange : jsonOfRange, UriAndRange;
import util.uri : AllUris, stringOfUri, Uri;

Json jsonOfLspOutMessage(ref Alloc alloc, in AllUris allUris, in LineAndColumnGetters lcg, ref LspOutMessage a) =>
	a.match!Json(
		(LspOutNotification x) =>
			jsonOfLspOutNotification(alloc, allUris, lcg, x),
		(LspOutResponse x) =>
			jsonObject(alloc, [
				field!"id"(x.id),
				field!"result"(jsonOfLspOutResult(alloc, allUris, lcg, x.result))]));

private:

Json jsonOfLspOutNotification(
	ref Alloc alloc,
	in AllUris allUris,
	in LineAndColumnGetters lcg,
	ref LspOutNotification a,
) {
	Json res(string method, Json params) =>
		jsonObject(alloc, [field!"method"(method), field!"params"(params)]);
	return a.match!Json(
		(PublishDiagnosticsParams x) =>
			res("textDocument/publishDiagnostics", jsonOfPublishDiagnosticsParams(alloc, allUris, lcg[x.uri], x)),
		(RegisterCapability x) =>
			res("client/registerCapability", jsonObject(alloc, [
				field!"id"(x.id),
				field!"method"(x.method)])),
		(UnknownUris x) =>
			res("custom/unknownUris", jsonObject(alloc, [
				field!"unknownUris"(jsonList!Uri(alloc, x.unknownUris, (in Uri x) =>
					Json(stringOfUri(alloc, allUris, x))))])));
}

Json jsonOfLspOutResult(ref Alloc alloc, in AllUris allUris, in LineAndColumnGetters lcg, ref LspOutResult a) =>
	a.match!Json(
		(InitializeResult _) =>
			jsonObject(alloc, [field!"capabilities"(initializeCapabilities(alloc))]),
		(Opt!Hover x) =>
			jsonOfHover(alloc, x),
		(UnloadedUris x) =>
			jsonObject(alloc, [field!"unloadedUris"(jsonList!Uri(alloc, x.unloadedUris, (in Uri x) =>
				Json(stringOfUri(alloc, allUris, x))))]),
		(UriAndRange[] x) =>
			jsonOfReferences(alloc, allUris, lcg, x),
		(Opt!WorkspaceEdit x) =>
			jsonOfRename(alloc, allUris, lcg, x),
		(LspOutResult.Null) =>
			jsonNull);

Json initializeCapabilities(ref Alloc alloc) =>
	Json(arrLiteral!(Json.StringObjectField)(alloc, [
		Json.StringObjectField("textDocumentSync", Json(2)), // incremental
		//Json.StringObjectField/TODO: completionProvider: {resolveProvider: true},
		Json.StringObjectField("definitionProvider", jsonObject([])),
		Json.StringObjectField("hoverProvider", jsonObject([])),
		Json.StringObjectField("referencesProvider", jsonObject([])),
		Json.StringObjectField("renameProvider", jsonObject([]))]));

Json jsonOfPublishDiagnosticsParams(
	ref Alloc alloc,
	in AllUris allUris,
	in LineAndColumnGetter lcg,
	in PublishDiagnosticsParams a,
) =>
	jsonObject(alloc, [
		field!"uri"(stringOfUri(alloc, allUris, a.uri)),
		field!"diagnostics"(jsonList(map(alloc, a.diagnostics, (ref LspDiagnostic x) =>
			jsonOfDiagnostic(alloc, lcg, x))))]);

public Json jsonOfHover(ref Alloc alloc, in Opt!Hover a) =>
	has(a) ? jsonOfHover(alloc, force(a)) : jsonNull;

Json jsonOfHover(ref Alloc alloc, in Hover a) =>
	jsonObject(alloc, [field!"contents"(jsonOfMarkupContent(alloc, a.contents))]);

public Json jsonOfReferences(
	ref Alloc alloc,
	in AllUris allUris,
	in LineAndColumnGetters lineAndColumnGetters,
	in UriAndRange[] references,
) =>
	jsonList!UriAndRange(alloc, references, (in UriAndRange x) =>
		jsonOfUriAndRange(alloc, allUris, lineAndColumnGetters, x));

public Json jsonOfRename(ref Alloc alloc, in AllUris allUris, in LineAndColumnGetters lcg, in Opt!WorkspaceEdit a) =>
	has(a)
		? jsonOfWorkspaceEdit(alloc, allUris, lcg, force(a))
		: jsonNull;

Json jsonOfDiagnostic(ref Alloc alloc, in LineAndColumnGetter lcg, LspDiagnostic a) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRange(alloc, lcg, a.range)),
		field!"severity"(cast(uint) a.severity),
		field!"message"(strOfSafeCStr(a.message))]);

Json jsonOfWorkspaceEdit(ref Alloc alloc, in AllUris allUris, in LineAndColumnGetters lcg, in WorkspaceEdit a) =>
	jsonObject(alloc, [field!"changes"(jsonOfWorkspaceEditChanges(alloc, allUris, lcg, a.changes))]);

Json jsonOfWorkspaceEditChanges(
	ref Alloc alloc,
	in AllUris allUris,
	in LineAndColumnGetters lcg,
	in MultiMap!(Uri, TextEdit) a,
) =>
	Json(mapMultiMap!(Json.StringObjectField, Uri, TextEdit)(alloc, a, (Uri uri, in TextEdit[] changes) =>
		Json.StringObjectField(
			stringOfUri(alloc, allUris, uri),
			jsonOfTextEdits(alloc, lcg[uri], changes))));

Json jsonOfTextEdits(ref Alloc alloc, in LineAndColumnGetter lcg, in TextEdit[] a) =>
	jsonList(map!(Json, TextEdit)(alloc, a, (ref TextEdit x) =>
		jsonOfTextEdit(alloc, lcg, x)));

Json jsonOfTextEdit(ref Alloc alloc, in LineAndColumnGetter lcg, ref TextEdit a) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRange(alloc, lcg, a.range)),
		field!"newText"(a.newText)]);

Json jsonOfMarkupContent(ref Alloc alloc, in MarkupContent a) =>
	jsonObject(alloc, [
		field!"kind"(stringOfMarkupKind(a.kind)),
		field!"value"(jsonString(alloc, a.value))]);

string stringOfMarkupKind(MarkupKind a) {
	final switch (a) {
		case MarkupKind.plaintext:
			return "plaintext";
		case MarkupKind.markdown:
			return "markdown";
	}
}
