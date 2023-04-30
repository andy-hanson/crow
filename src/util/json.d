module util.json;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc, allocateT;
import util.col.arr : empty;
import util.col.arrUtil : arrEqual, filter, map;
import util.col.fullIndexMap : FullIndexMap;
import util.col.map : KeyValuePair;
import util.col.str : copyStr, SafeCStr, safeCStrIsEmpty, strEq, strOfSafeCStr;
import util.memory : initMemory;
import util.opt : force, has, Opt;
import util.ptr : ptrTrustMe;
import util.sym : AllSymbols, Sym, sym, writeQuotedSym;
import util.union_ : Union;
import util.writer : finishWriterToSafeCStr, writeFloatLiteral, Writer, writeQuotedStr, writeWithCommas;

immutable struct Json {
	@safe @nogc pure nothrow:

	immutable struct Null {}
	alias List = immutable Json[];
	alias ObjectField = immutable KeyValuePair!(Sym, Json);
	alias Object = immutable ObjectField[];
	// string and Sym cases should be treated as equivalent.
	mixin Union!(Null, bool, double, string, Sym, List, Object);

	// Distinguishes SafeCStr / string / Sym. Use only for tests.
	bool opEquals(in Json b) scope =>
		matchIn!bool(
			(in Null _) =>
				b.isA!Null,
			(bool x) =>
				b.isA!bool && b.as!bool == x,
			(double x) =>
				b.isA!double && b.as!double == x,
			(in string x) =>
				b.isA!string && strEq(x, b.as!string),
			(in Sym x) =>
				b.isA!Sym && x == b.as!Sym,
			(in Json[] x) =>
				b.isA!(Json[]) && arrEqual!Json(x, b.as!(Json[])),
			(in Json.Object oa) =>
				b.isA!Object && arrEqual(oa, b.as!Object));
}

Json jsonObject(Json.ObjectField[] fields) =>
	Json(fields);
Json jsonObject(ref Alloc alloc, in Json.ObjectField[] fields) =>
	jsonObject(filter!(Json.ObjectField)(alloc, fields, (in Json.ObjectField x) =>
		!x.value.isA!(Json.Null)));

// TODO: should be possible to concatenate in the caller (assuming array sizes are compile-time constants).
// But a D bug prevents this: https://issues.dlang.org/show_bug.cgi?id=1654
Json jsonObject(ref Alloc alloc, in Json.ObjectField[] fields1, in Json.ObjectField[] fields2) =>
	jsonObject(alloc, concatenate!(Json.ObjectField)(alloc, fields1, fields2));

private @trusted immutable(T[]) concatenate(T)(ref Alloc alloc, in T[] a, in T[] b) {
	size_t len = a.length + b.length;
	T* res = allocateT!T(alloc, len);
	foreach (size_t i, T x; a)
		initMemory(&res[i], x);
	foreach (size_t i, T x; b)
		initMemory(&res[a.length + i], x);
	return cast(immutable) res[0 .. len];
}

private Json jsonNull() =>
	Json(Json.Null());

Json.ObjectField optionalField(string name)(bool isPresent, in Json delegate() @safe @nogc pure nothrow cb) =>
	field!name(isPresent ? cb() : jsonNull);

Json.ObjectField optionalField(string name, T)(in Opt!T a, in Json delegate(in T) @safe @nogc pure nothrow cb) =>
	field!name(has(a) ? cb(force(a)) : jsonNull); 

Json.ObjectField optionalFlagField(string name)(bool value) =>
	field!name(value ? Json(true) : jsonNull);

Json.ObjectField optionalArrayField(string name)(Json[] array) =>
	optionalField!name(!empty(array), () => jsonList(array));
Json.ObjectField optionalArrayField(string name, T)(
	ref Alloc alloc,
	in T[] array,
	in Json delegate(in T) @safe @nogc pure nothrow cb,
) =>
	optionalField!name(!empty(array), () =>
		jsonList(map!(Json, const T)(alloc, array, (ref const T x) => cb(x))));

Json.ObjectField optionalStringField(string name)(ref Alloc alloc, in SafeCStr value) =>
	optionalField!name(!safeCStrIsEmpty(value), () => jsonString(alloc, value));

Json.ObjectField kindField(string kindName)() =>
	.kindField(sym!kindName);
Json.ObjectField kindField(Sym kindName) =>
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

Json.ObjectField field(string name)(Json value) =>
	Json.ObjectField(sym!name, value);
Json.ObjectField field(string name)(double value) =>
	field!name(Json(value));
Json.ObjectField field(string name)(SafeCStr value) =>
	field!name(strOfSafeCStr(value));
Json.ObjectField field(string name)(string value) =>
	field!name(Json(value));
Json.ObjectField field(string name)(Sym value) =>
	field!name(Json(value));

SafeCStr jsonToString(ref Alloc alloc, in AllSymbols allSymbols, in Json a) {
	Writer writer = Writer(ptrTrustMe(alloc));
	writeJson(writer, allSymbols, a);
	return finishWriterToSafeCStr(writer);
}

void writeJson(ref Writer writer, in AllSymbols allSymbols, in Json a) =>
	a.matchIn!void(
		(in Json.Null _) {
			writer ~= "null";
		},
		(bool x) {
			writer ~= x ? "true" : "false";
		},
		(double x) {
			writeFloatLiteral(writer, x);
		},
		(in string x) {
			writeQuotedStr(writer, x);
		},
		(in Sym it) {
			writeQuotedSym(writer, allSymbols, it);
		},
		(in Json[] x) {
			writer ~= '[';
			writeWithCommas!Json(writer, x, (in Json y) {
				writeJson(writer, allSymbols, y);
			});
			writer ~= ']';
		},
		(in Json.Object x) {
			writer ~= '{';
			writeWithCommas!(Json.ObjectField)(writer, x, (in Json.ObjectField pair) {
				writeQuotedSym(writer, allSymbols, pair.key);
				writer ~= ':';
				writeJson(writer, allSymbols, pair.value);
			});
			writer ~= '}';
		});