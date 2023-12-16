module util.json;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.arr : isEmpty;
import util.col.arrUtil : arraysEqual, concatenateIn, copyArray, every, exists, find, map;
import util.col.fullIndexMap : FullIndexMap;
import util.col.map : KeyValuePair;
import util.col.str : copyStr, SafeCStr, safeCStrIsEmpty, strEq, strOfSafeCStr;
import util.opt : force, has, Opt;
import util.sym : AllSymbols, Sym, sym, writeQuotedSym;
import util.union_ : Union;
import util.util : todo;
import util.writer :
	withWriter, writeFloatLiteral, Writer, writeQuotedString, writeWithCommasCompact, writeWithSeparator;

immutable struct Json {
	@safe @nogc pure nothrow:

	immutable struct Null {}
	alias List = immutable Json[];
	alias ObjectField = immutable KeyValuePair!(Sym, Json);
	alias Object = immutable ObjectField[];
	alias StringObjectField = immutable KeyValuePair!(string, Json);
	alias StringObject = immutable StringObjectField[];
	// string and Sym cases should be treated as equivalent.
	mixin Union!(Null, bool, double, string, Sym, List, Object, StringObject);

	// Distinguishes SafeCStr / string / Sym. Use only for tests.
	bool opEquals(in Json b) scope =>
		matchIn!bool(
			(in Null _) =>
				b.isA!Null,
			(in bool x) =>
				b.isA!bool && b.as!bool == x,
			(in double x) =>
				b.isA!double && b.as!double == x,
			(in string x) =>
				b.isA!string && strEq(x, b.as!string),
			(in Sym x) =>
				b.isA!Sym && x == b.as!Sym,
			(in Json[] x) =>
				b.isA!(Json[]) && arraysEqual!Json(x, b.as!(Json[])),
			(in Json.Object oa) =>
				b.isA!Object && arraysEqual(oa, b.as!Object),
			(in Json.StringObject ob) =>
				todo!bool(""));
}

Json get(string key)(in Json a) {
	Opt!(Json.ObjectField) pair = find!(Json.ObjectField)(a.as!(Json.Object), (in Json.ObjectField pair) =>
		pair.key == sym!key);
	return has(pair) ? force(pair).value : jsonNull;
}
bool hasKey(string key)(in Json a) =>
	a.isA!(Json.Object) && exists!(Json.ObjectField)(a.as!(Json.Object), (in Json.ObjectField pair) =>
		pair.key == sym!key);

Json jsonObject(return scope Json.ObjectField[] fields) =>
	Json(fields);
Json jsonObject(ref Alloc alloc, in Json.ObjectField[] fields) =>
	jsonObject(copyArray(alloc, fields));

// TODO: should be possible to concatenate in the caller (assuming array sizes are compile-time constants).
// But a D bug prevents this: https://issues.dlang.org/show_bug.cgi?id=1654
Json jsonObject(ref Alloc alloc, in Json.ObjectField[] fields1, in Json.ObjectField[] fields2) =>
	jsonObject(alloc, concatenateIn!(Json.ObjectField)(alloc, fields1, fields2));

Json jsonBool(bool b) =>
	Json(b);

Json jsonNull() =>
	Json(Json.Null());

Json.ObjectField optionalField(string name)(bool isPresent, in Json delegate() @safe @nogc pure nothrow cb) =>
	field!name(isPresent ? cb() : jsonNull);

Json.ObjectField optionalField(string name, T)(in Opt!T a, in Json delegate(in T) @safe @nogc pure nothrow cb) =>
	field!name(has(a) ? cb(force(a)) : jsonNull);

Json.ObjectField optionalFlagField(string name)(bool value) =>
	field!name(value ? jsonBool(true) : jsonNull);

Json.ObjectField optionalArrayField(string name)(Json[] array) =>
	optionalField!name(!isEmpty(array), () => jsonList(array));
Json.ObjectField optionalArrayField(string name, T)(
	ref Alloc alloc,
	in T[] array,
	in Json delegate(in T) @safe @nogc pure nothrow cb,
) =>
	optionalField!name(!isEmpty(array), () =>
		jsonList(map!(Json, const T)(alloc, array, (ref const T x) => cb(x))));

Json.ObjectField optionalStringField(string name)(ref Alloc alloc, in SafeCStr value) =>
	optionalField!name(!safeCStrIsEmpty(value), () => jsonString(alloc, value));

Json.ObjectField kindField(string kindName)() =>
	.kindField(kindName);
Json.ObjectField kindField(string kindName) =>
	field!"kind"(kindName);

Json jsonList(Json[] xs) =>
	Json(xs);

Json jsonList(T)(ref Alloc alloc, in T[] xs, in Json delegate(in T) @safe @nogc pure nothrow cb) =>
	jsonList(map!(Json, const T)(alloc, xs, (ref const T x) => cb(x)));

Json jsonList(K, V)(
	ref Alloc alloc,
	in immutable FullIndexMap!(K, V) a,
	in Json delegate(in V) @safe @nogc pure nothrow cb,
) =>
	.jsonList!V(alloc, a.values, cb);

Json jsonInt(long a) =>
	Json(a);

Json jsonString(string a) =>
	Json(a);

Json jsonString(SafeCStr a) =>
	jsonString(strOfSafeCStr(a));

Json jsonString(ref Alloc alloc, in string a) =>
	jsonString(copyStr(alloc, a));

Json jsonString(ref Alloc alloc, in SafeCStr a) =>
	jsonString(alloc, strOfSafeCStr(a));

Json jsonString(Sym a) =>
	Json(a);

Json jsonString(string a)() =>
	jsonString(a);

Json.ObjectField field(string name)(return scope Json value) =>
	Json.ObjectField(sym!name, value);
Json.ObjectField field(string name)(double value) =>
	field!name(Json(value));
Json.ObjectField field(string name)(SafeCStr value) =>
	field!name(strOfSafeCStr(value));
Json.ObjectField field(string name)(string value) =>
	field!name(Json(value));
Json.ObjectField field(string name)(Sym value) =>
	field!name(Json(value));

SafeCStr jsonToString(ref Alloc alloc, in AllSymbols allSymbols, in Json a) =>
	withWriter(alloc, (scope ref Writer writer) {
		writeJson(writer, allSymbols, a);
	});

SafeCStr jsonToStringPretty(ref Alloc alloc, in AllSymbols allSymbols, in Json a) =>
	withWriter(alloc, (scope ref Writer writer) {
		writeJsonPretty(writer, allSymbols, a, 0);
	});

void writeJson(ref Writer writer, in AllSymbols allSymbols, in Json a) =>
	a.matchIn!void(
		(in Json.Null _) {
			writer ~= "null";
		},
		(in bool x) {
			writer ~= x ? "true" : "false";
		},
		(in double x) {
			writeFloatLiteral(writer, x);
		},
		(in string x) {
			writeQuotedString(writer, x);
		},
		(in Sym it) {
			writeQuotedSym(writer, allSymbols, it);
		},
		(in Json[] x) {
			writer ~= '[';
			writeWithCommasCompact!Json(writer, x, (in Json y) {
				writeJson(writer, allSymbols, y);
			});
			writer ~= ']';
		},
		(in Json.Object x) {
			writeObjectCompact!Sym(writer, allSymbols, x, (in Sym key) {
				writeQuotedSym(writer, allSymbols, key);
			});
		},
		(in Json.StringObject x) {
			writeObjectCompact!string(writer, allSymbols, x, (in string key) {
				writeQuotedString(writer, key);
			});
		});

private:

void writeObjectCompact(K)(
	ref Writer writer,
	in AllSymbols allSymbols,
	in KeyValuePair!(K, Json)[] pairs,
	in void delegate(in K) @safe @nogc pure nothrow writeKey,
) {
	writer ~= '{';
	writeWithCommasCompact!(KeyValuePair!(K, Json))(writer, pairs, (in KeyValuePair!(K, Json) pair) {
		writeKey(pair.key);
		writer ~= ':';
		writeJson(writer, allSymbols, pair.value);
	});
	writer ~= '}';
}

void writeJsonPretty(ref Writer writer, in AllSymbols allSymbols, in Json a, in uint indent) {
	if (a.isA!(Json[])) {
		bool singleLine = every!Json(a.as!(Json[]), (in Json x) => isPrimitive(x));
		writer ~= '[';
		writeWithSeparator!Json(writer, a.as!(Json[]), singleLine ? ", " : ",", (in Json x) {
			if (!singleLine) writeNewlineAndIndent(writer, indent + 1);
			writeJsonPretty(writer, allSymbols, x, indent + 1);
		});
		if (!singleLine) writeNewlineAndIndent(writer, indent);
		writer ~= ']';
	} else if (a.isA!(Json.Object)) {
		bool singleLine = every!(Json.ObjectField)(a.as!(Json.Object), (in Json.ObjectField x) =>
			isPrimitive(x.value));
		writer ~= '{';
		string comma = singleLine ? ", " : ",";
		writeWithSeparator!(Json.ObjectField)(writer, a.as!(Json.Object), comma, (in Json.ObjectField pair) {
			if (!singleLine) writeNewlineAndIndent(writer, indent + 1);
			writeQuotedSym(writer, allSymbols, pair.key);
			writer ~= ": ";
			writeJsonPretty(writer, allSymbols, pair.value, indent + 1);
		});
		if (!singleLine) writeNewlineAndIndent(writer, indent);
		writer ~= '}';
	} else
		writeJson(writer, allSymbols, a);
}

void writeNewlineAndIndent(ref Writer writer, in uint indent) {
	writer ~= '\n';
	foreach (uint i; 0 .. indent)
		writer ~= '\t';
}

bool isPrimitive(in Json a) =>
	!a.isA!(Json[]) && !a.isA!(Json.Object);
