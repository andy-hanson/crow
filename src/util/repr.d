module util.repr;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.col.arrUtil : arrLiteral, map, mapWithIndex;
import util.col.fullIndexDict : FullIndexDict;
import util.col.str : SafeCStr, strOfSafeCStr;
import util.memory : allocate;
import util.opt : force, has, none, Opt, some;
import util.ptr : ptrTrustMe;
import util.sym : AllSymbols, Sym, sym, writeQuotedSym;
import util.union_ : Union;
import util.writer : finishWriterToSafeCStr, writeFloatLiteral, writeJoin, Writer, writeQuotedStr;

immutable(Repr) reprRecord(immutable Sym name, immutable Repr[] children) =>
	immutable Repr(immutable ReprRecord(name, children));

immutable(Repr) reprRecord(immutable string name)(immutable Repr[] children) =>
	reprRecord(sym!name, children);

immutable(Repr) reprRecord(immutable string name)() =>
	reprRecord(name, []);

immutable(Repr) reprRecord(ref Alloc alloc, immutable Sym name, scope immutable Repr[] children) =>
	reprRecord(name, arrLiteral(alloc, children));

immutable(Repr) reprRecord(immutable string name)(ref Alloc alloc, scope immutable Repr[] children) =>
	reprRecord!name(arrLiteral(alloc, children));

private struct ReprRecord {
	immutable Sym name;
	immutable Repr[] children;
}

immutable(Repr) reprNamedRecord(immutable Sym name, immutable NameAndRepr[] children) =>
	immutable Repr(immutable ReprNamedRecord(name, children));

immutable(Repr) reprNamedRecord(immutable string name)(immutable NameAndRepr[] children) =>
	reprNamedRecord(sym!name, children);

immutable(Repr) reprNamedRecord(ref Alloc alloc, immutable Sym name, scope immutable NameAndRepr[] children) =>
	reprNamedRecord(name, arrLiteral(alloc, children));

immutable(Repr) reprNamedRecord(immutable string name)(ref Alloc alloc, scope immutable NameAndRepr[] children) =>
	reprNamedRecord(alloc, sym!name, children);

immutable(Repr) reprArr(immutable Repr[] elements) =>
	immutable Repr(immutable ReprArr(false, elements));

immutable(Repr) reprArr(T)(
	ref Alloc alloc,
	scope immutable T[] xs,
	scope immutable(Repr) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) =>
	reprArr(map(alloc, xs, cb));

immutable(Repr) reprArr(T)(
	ref Alloc alloc,
	scope immutable T[] xs,
	scope immutable(Repr) delegate(immutable size_t, ref immutable T) @safe @nogc pure nothrow cb,
) =>
	immutable Repr(immutable ReprArr(false, mapWithIndex(alloc, xs, cb)), true);

immutable(Repr) reprFullIndexDict(K, V)(
	ref Alloc alloc,
	scope immutable FullIndexDict!(K, V) a,
	scope immutable(Repr) delegate(ref immutable V) @safe @nogc pure nothrow cb,
) =>
	immutable Repr(immutable ReprArr(true, map(alloc, a.values, cb)));

immutable(Repr) reprBool(immutable bool a) =>
	immutable Repr(a);

immutable(Repr) reprFloat(immutable double a) =>
	immutable Repr(a);

immutable(Repr) reprInt(immutable long a) =>
	immutable Repr(a);

immutable(Repr) reprNat(immutable ulong a) =>
	immutable Repr(a);

immutable(Repr) reprStr(immutable string a) =>
	immutable Repr(a);

immutable(Repr) reprStr(immutable SafeCStr a) =>
	reprStr(strOfSafeCStr(a));

immutable(Repr) reprSym(immutable Sym a) =>
	immutable Repr(a);

immutable(Repr) reprSym(immutable string a)() =>
	reprSym(sym!a);

immutable(Repr) reprOpt(T)(
	ref Alloc alloc,
	immutable Opt!T opt,
	scope immutable(Repr) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) =>
	immutable Repr(has(opt) ? some(allocate!Repr(alloc, cb(force(opt)))) : none!(Repr*));

private struct ReprNamedRecord {
	immutable Sym name;
	immutable NameAndRepr[] children;
}

immutable(NameAndRepr) nameAndRepr(immutable string name)(immutable Repr value) =>
	immutable NameAndRepr(sym!name, value);

struct NameAndRepr {
	immutable Sym name;
	immutable Repr value;
}

private struct ReprArr {
	immutable bool showIndices;
	immutable Repr[] arr;
}

struct Repr {
	mixin Union!(
		immutable ReprArr,
		immutable bool,
		immutable double,
		immutable long,
		immutable ReprNamedRecord,
		immutable Opt!(Repr*),
		immutable ReprRecord,
		immutable string,
		immutable Sym);
}

immutable(SafeCStr) jsonStrOfRepr(ref Alloc alloc, ref const AllSymbols allSymbols, immutable Repr a) {
	Writer writer = Writer(ptrTrustMe(alloc));
	writeReprJSON(writer, allSymbols, a);
	return finishWriterToSafeCStr(writer);
}

void writeReprJSON(ref Writer writer, ref const AllSymbols allSymbols, immutable Repr a) {
	a.match!void(
		(immutable ReprArr it) {
			writer ~= '[';
			writeJoin!Repr(writer, it.arr, ",", (ref immutable Repr em) {
				writeReprJSON(writer, allSymbols, em);
			});
			writer ~= ']';
		},
		(immutable bool it) {
			writer ~= it ? "true" : "false";
		},
		(immutable double it) {
			writeFloatLiteral(writer, it);
		},
		(immutable long it) {
			writer ~= it;
		},
		(immutable ReprNamedRecord it) {
			writer ~= "{\"_type\":";
			writeQuotedSym(writer, allSymbols, it.name);
			foreach (ref immutable NameAndRepr pair; it.children) {
				writer ~= ',';
				writeQuotedSym(writer, allSymbols, pair.name);
				writer ~= ':';
				writeReprJSON(writer, allSymbols, pair.value);
			}
			writer ~= '}';
		},
		(immutable Opt!(Repr*) it) {
			if (has(it)) {
				writer ~= "{\"_type\":\"some\",\"value\":";
				writeReprJSON(writer, allSymbols, *force(it));
				writer ~= '}';
			} else {
				writer ~= "{\"_type\":\"none\"}";
			}
		},
		(immutable ReprRecord it) {
			writer ~= "{\"_type\":";
			writeQuotedSym(writer, allSymbols, it.name);
			writer ~= ",\"args\":[";
			writeJoin!Repr(writer, it.children, ",", (ref immutable Repr child) {
				writeReprJSON(writer, allSymbols, child);
			});
			writer ~= "]}";
		},
		(immutable string it) {
			writeQuotedStr(writer, it);
		},
		(immutable Sym it) {
			writeQuotedSym(writer, allSymbols, it);
		});
}
