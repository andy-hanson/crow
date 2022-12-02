module util.repr;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.arr : small, SmallArray;
import util.col.arrUtil : arrLiteral, map;
import util.col.fullIndexDict : FullIndexDict;
import util.col.str : copyStr, SafeCStr, strOfSafeCStr;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.ptr : ptrTrustMe;
import util.sym : AllSymbols, Sym, sym, writeQuotedSym;
import util.union_ : Union;
import util.writer : finishWriterToSafeCStr, writeFloatLiteral, writeJoin, Writer, writeQuotedStr;

Repr reprRecord(Sym name, in Repr[] children) =>
	Repr(ReprRecord(name, small(children)));

Repr reprRecord(string name)(in Repr[] children) =>
	reprRecord(sym!name, children);

Repr reprRecord(string name)() =>
	reprRecord(name, []);

Repr reprRecord(ref Alloc alloc, Sym name, in Repr[] children) =>
	reprRecord(name, arrLiteral(alloc, children));

Repr reprRecord(string name)(ref Alloc alloc, in Repr[] children) =>
	reprRecord!name(arrLiteral(alloc, children));

private immutable struct ReprRecord {
	Sym name;
	SmallArray!Repr children;
}

Repr reprNamedRecord(Sym name, NameAndRepr[] children) =>
	Repr(ReprNamedRecord(name, small(children)));

Repr reprNamedRecord(string name)(NameAndRepr[] children) =>
	reprNamedRecord(sym!name, children);

Repr reprNamedRecord(ref Alloc alloc, Sym name, in NameAndRepr[] children) =>
	reprNamedRecord(name, arrLiteral(alloc, children));

Repr reprNamedRecord(string name)(ref Alloc alloc, in NameAndRepr[] children) =>
	reprNamedRecord(alloc, sym!name, children);

Repr reprArr(Repr[] xs) =>
	Repr(ReprArr(xs));

Repr reprArr(T)(ref Alloc alloc, in T[] xs, in Repr delegate(in T) @safe @nogc pure nothrow cb) =>
	reprArr(map!(Repr, const T)(alloc, xs, (ref const T x) => cb(x)));

Repr reprFullIndexDict(K, V)(
	ref Alloc alloc,
	in immutable FullIndexDict!(K, V) a,
	in Repr delegate(ref immutable V) @safe @nogc pure nothrow cb,
) =>
	Repr(ReprArr(map(alloc, a.values, cb)));

Repr reprBool(bool a) =>
	Repr(a);

Repr reprFloat(double a) =>
	Repr(a);

Repr reprInt(long a) =>
	Repr(a);

Repr reprNat(ulong a) =>
	Repr(a);

Repr reprStr(string a) =>
	Repr(a);

Repr reprStr(SafeCStr a) =>
	reprStr(strOfSafeCStr(a));

Repr reprStr(ref Alloc alloc, in string a) =>
	reprStr(copyStr(alloc, a));

Repr reprStr(ref Alloc alloc, in SafeCStr a) =>
	reprStr(alloc, strOfSafeCStr(a));

Repr reprSym(Sym a) =>
	Repr(a);

Repr reprSym(string a)() =>
	reprSym(sym!a);

Repr reprOpt(T)(ref Alloc alloc, in Opt!T opt, in Repr delegate(in T) @safe @nogc pure nothrow cb) =>
	Repr(has(opt) ? some(allocate!Repr(alloc, cb(force(opt)))) : none!(Repr*));

private immutable struct ReprNamedRecord {
	Sym name;
	SmallArray!NameAndRepr children;
}

NameAndRepr nameAndRepr(string name)(Repr value) =>
	NameAndRepr(sym!name, value);

immutable struct NameAndRepr {
	Sym name;
	Repr value;
}

private immutable struct ReprArr {
	Repr[] arr;
}

immutable struct Repr {
	mixin Union!(
		ReprArr,
		bool,
		double,
		long,
		ReprNamedRecord,
		Opt!(Repr*),
		ReprRecord,
		string,
		Sym);
}
static assert(Repr.sizeof == ReprRecord.sizeof + ulong.sizeof);

SafeCStr jsonStrOfRepr(ref Alloc alloc, in AllSymbols allSymbols, in Repr a) {
	Writer writer = Writer(ptrTrustMe(alloc));
	writeReprJSON(writer, allSymbols, a);
	return finishWriterToSafeCStr(writer);
}

void writeReprJSON(ref Writer writer, in AllSymbols allSymbols, in Repr a) {
	a.matchIn!void(
		(in ReprArr x) {
			writer ~= '[';
			writeJoin!Repr(writer, x.arr, ",", (in Repr em) {
				writeReprJSON(writer, allSymbols, em);
			});
			writer ~= ']';
		},
		(bool it) {
			writer ~= it ? "true" : "false";
		},
		(double it) {
			writeFloatLiteral(writer, it);
		},
		(long it) {
			writer ~= it;
		},
		(in ReprNamedRecord it) {
			writer ~= "{\"_type\":";
			writeQuotedSym(writer, allSymbols, it.name);
			foreach (ref NameAndRepr pair; it.children) {
				writer ~= ',';
				writeQuotedSym(writer, allSymbols, pair.name);
				writer ~= ':';
				writeReprJSON(writer, allSymbols, pair.value);
			}
			writer ~= '}';
		},
		(in Opt!(Repr*) it) {
			if (has(it)) {
				writer ~= "{\"_type\":\"some\",\"value\":";
				writeReprJSON(writer, allSymbols, *force(it));
				writer ~= '}';
			} else {
				writer ~= "{\"_type\":\"none\"}";
			}
		},
		(in ReprRecord it) {
			writer ~= "{\"_type\":";
			writeQuotedSym(writer, allSymbols, it.name);
			writer ~= ",\"args\":[";
			writeJoin!Repr(writer, it.children, ",", (in Repr child) {
				writeReprJSON(writer, allSymbols, child);
			});
			writer ~= "]}";
		},
		(in string it) {
			writeQuotedStr(writer, it);
		},
		(in Sym it) {
			writeQuotedSym(writer, allSymbols, it);
		});
}
