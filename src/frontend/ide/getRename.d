module frontend.ide.getRename;

@safe @nogc pure nothrow:

import frontend.ide.getTarget : Target, targetForPosition;
import frontend.ide.ideUtil : ReferenceCb;
import frontend.ide.position : Position;
import frontend.ide.getReferences : eachReferenceForTarget;
import frontend.storage : LineAndColumnGetters;
import model.model : Program;
import util.alloc.alloc : Alloc;
import util.col.arrUtil : map;
import util.col.multiMap : makeMultiMap, mapMultiMap, MultiMap, MultiMapCb;
import util.col.str : copyStr;
import util.json : field, Json, jsonList, jsonNull, jsonObject;
import util.lineAndColumnGetter : LineAndColumnGetter;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : jsonOfRange, Range, UriAndRange;
import util.sym : AllSymbols;
import util.uri : AllUris, Uri, stringOfUri;

immutable struct Rename {
	MultiMap!(Uri, TextEdit) changes;
}

private immutable struct TextEdit {
	Range range;
	string newText;
}

Opt!Rename getRenameForPosition(
	ref Alloc alloc,
	scope ref AllSymbols allSymbols,
	in AllUris allUris,
	in Program program,
	in Position pos,
	in string newName,
) {
	Opt!Target target = targetForPosition(program, pos.kind);
	return has(target)
		? some(Rename(makeMultiMap!(Uri, TextEdit)(alloc, (in MultiMapCb!(Uri, TextEdit) cb) {
			string newNameOut = copyStr(alloc, newName);
			eachRenameLocation(allSymbols, allUris, program, pos.module_.uri, force(target), (in UriAndRange x) {
				cb(x.uri, TextEdit(x.range, newNameOut));
			});
		})))
		: none!Rename;
}

Json jsonOfRename(
	ref Alloc alloc,
	in AllUris allUris,
	in LineAndColumnGetters lineAndColumnGetters,
	in Opt!Rename rename,
) =>
	has(rename)
		? jsonObject(alloc, [
			field!"changes"(jsonOfChanges(alloc, allUris, lineAndColumnGetters, force(rename).changes))])
		: jsonNull;

private:

Json jsonOfChanges(
	ref Alloc alloc,
	in AllUris allUris,
	in LineAndColumnGetters lineAndColumnGetters,
	in MultiMap!(Uri, TextEdit) a,
) =>
	Json(mapMultiMap!(Json.StringObjectField, Uri, TextEdit)(alloc, a, (Uri uri, in TextEdit[] changes) =>
		Json.StringObjectField(stringOfUri(alloc, allUris, uri), jsonList(map(alloc, changes, (ref TextEdit x) =>
			jsonOfTextEdit(alloc, lineAndColumnGetters[uri], x))))));

Json jsonOfTextEdit(ref Alloc alloc, in LineAndColumnGetter lineAndColumnGetter, TextEdit a) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRange(alloc, lineAndColumnGetter, a.range)),
		field!"newText"(a.newText)]);

void eachRenameLocation(
	scope ref AllSymbols allSymbols,
	in AllUris allUris,
	in Program program,
	Uri curUri,
	in Target target,
	in ReferenceCb cb,
) {
	//eachImportLocation(..., cb);
	eachReferenceForTarget(allSymbols, allUris, program, curUri, target, cb);
}
