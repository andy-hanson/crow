module util.repr;

@safe @nogc pure nothrow:

import util.bools : Bool, False, True;
import util.collection.arr : Arr, at, empty, emptyArr, first, size;
import util.collection.arrUtil : arrLiteral, map, mapWithIndex, tail;
import util.collection.fullIndexDict : FullIndexDict;
import util.collection.str : CStr, Str;
import util.memory : allocate;
import util.opt : force, has, mapOption, Opt;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.sym : shortSymAlphaLiteral, Sym, symSize, writeSym;
import util.types : abs, IntN, NatN, safeIntFromSizeT;
import util.util : todo;
import util.writer :
	finishWriterToCStr,
	writeChar,
	writeFloatLiteral,
	writeInt,
	writeNat,
	writeNewline,
	Writer,
	writeQuotedStr,
	writeStatic,
	writeWithCommas;

immutable(Repr) reprRecord(immutable Sym name, immutable Arr!Repr children) {
	return immutable Repr(immutable ReprRecord(name, children));
}

immutable(Repr) reprRecord(immutable string name, immutable Arr!Repr children) {
	return reprRecord(shortSymAlphaLiteral(name), children);
}

immutable(Repr) reprRecord(immutable string name) {
	return reprRecord(name, emptyArr!Repr);
}

immutable(Repr) reprRecord(Alloc)(ref Alloc alloc, immutable string name, scope immutable Repr[] children) {
	return reprRecord(name, arrLiteral(alloc, children));
}

private struct ReprRecord {
	immutable Sym name;
	immutable Arr!Repr children;
}

immutable(Repr) reprNamedRecord(immutable string name, immutable Arr!NameAndRepr children) {
	return immutable Repr(immutable ReprNamedRecord(shortSymAlphaLiteral(name), children));
}

immutable(Repr) reprNamedRecord(Alloc)(
	ref Alloc alloc,
	immutable string name,
	scope immutable NameAndRepr[] children,
) {
	return reprNamedRecord(name, arrLiteral(alloc, children));
}

immutable(Repr) reprArr(T, Alloc)(
	ref Alloc alloc,
	immutable T[] xs,
	scope immutable(Repr) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	return immutable Repr(immutable ReprArr(False, map(alloc, xs, cb)), true);
}

immutable(Repr) reprArr(T, Alloc)(
	ref Alloc alloc,
	immutable T[] xs,
	scope immutable(Repr) delegate(immutable size_t, ref immutable T) @safe @nogc pure nothrow cb,
) {
	return immutable Repr(immutable ReprArr(False, mapWithIndex(alloc, xs, cb)), true);
}

immutable(Repr) reprFullIndexDict(K, V, Alloc)(
	ref Alloc alloc,
	ref immutable FullIndexDict!(K, V) a,
	scope immutable(Repr) delegate(ref immutable V) @safe @nogc pure nothrow cb,
) {
	return immutable Repr(immutable ReprArr(True, map(alloc, a.values, cb)), true);
}

immutable(Repr) reprBool(immutable Bool a) {
	return immutable Repr(a);
}

immutable(Repr) reprFloat(immutable double a) {
	return immutable Repr(a);
}

immutable(Repr) reprHex(T)(immutable NatN!T a) {
	return immutable Repr(immutable ReprInt(a.raw(), 16));
}

immutable(Repr) reprInt(immutable long a) {
	return immutable Repr(immutable ReprInt(a, 10));
}

immutable(Repr) reprInt(T)(immutable IntN!T a) {
	return immutable Repr(immutable ReprInt(a.raw(), 10));
}

immutable(Repr) reprNat(T)(immutable NatN!T a) {
	return reprNat(a.raw());
}

immutable(Repr) reprNat(immutable size_t a) {
	return immutable Repr(immutable ReprInt(a, 10));
}

immutable(Repr) reprStr(immutable string a) {
	return immutable Repr(a);
}

immutable(Repr) reprSym(immutable Sym a) {
	return immutable Repr(a);
}

immutable(Repr) reprSym(immutable string a) {
	return reprSym(shortSymAlphaLiteral(a));
}

immutable(Repr) reprOpt(Alloc, T)(
	ref Alloc alloc,
	immutable Opt!T opt,
	scope immutable(Repr) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	return immutable Repr(mapOption!(Ptr!Repr, T)(opt, (ref immutable T t) =>
		allocate!Repr(alloc, cb(t))));
}

private struct ReprNamedRecord {
	immutable Sym name;
	immutable Arr!NameAndRepr children;
}

immutable(NameAndRepr) nameAndRepr(immutable string name, immutable Repr value) {
	return immutable NameAndRepr(shortSymAlphaLiteral(name), value);
}

struct NameAndRepr {
	immutable Sym name;
	immutable Repr value;
}

private struct ReprArr {
	immutable Bool showIndices;
	immutable Arr!Repr arr;
}

private struct ReprInt {
	immutable long value;
	immutable size_t base;
}

struct Repr {
	@safe @nogc pure nothrow:
	private:
	enum Kind {
		arr,
		bool_,
		namedRecord,
		float_,
		int_,
		opt,
		record,
		str,
		symbol,
	}
	immutable Kind kind;
	union {
		immutable ReprArr arr;
		immutable Bool bool_;
		immutable ReprNamedRecord namedRecord;
		immutable double float_;
		immutable ReprInt int_;
		immutable Opt!(Ptr!Repr) opt;
		immutable ReprRecord record;
		immutable Str str;
		immutable Sym symbol;
	}

	@trusted immutable this(immutable ReprArr a, bool b) { kind = Kind.arr; arr = a; }
	immutable this(immutable Bool a) { kind = Kind.bool_; bool_ = a; }

	@trusted immutable this(immutable ReprNamedRecord a) { kind = Kind.namedRecord; namedRecord = a; }
	immutable this(immutable double a) { kind = Kind.float_; float_ = a; }
	immutable this(immutable ReprInt a) { kind = Kind.int_; int_ = a; }
	@trusted immutable this(immutable Opt!(Ptr!Repr) a) { kind = Kind.opt; opt = a; }
	@trusted immutable this(immutable ReprRecord a) { kind = Kind.record; record = a; }
	@trusted immutable this(immutable Str a) { kind = Kind.str; str = a; }
	immutable this(immutable Sym a) { kind = Kind.symbol; symbol = a; }
}

private @trusted T matchRepr(T)(
	ref immutable Repr a,
	scope T delegate(ref immutable ReprArr) @safe @nogc pure nothrow cbArr,
	scope T delegate(immutable Bool) @safe @nogc pure nothrow cbBool,
	scope T delegate(immutable double) @safe @nogc pure nothrow cbFloat,
	scope T delegate(immutable ReprInt) @safe @nogc pure nothrow cbInt,
	scope T delegate(ref immutable ReprNamedRecord) @safe @nogc pure nothrow cbNamedRecord,
	scope T delegate(immutable Opt!(Ptr!Repr)) @safe @nogc pure nothrow cbOpt,
	scope T delegate(ref immutable ReprRecord) @safe @nogc pure nothrow cbRecord,
	scope T delegate(ref immutable Str) @safe @nogc pure nothrow cbStr,
	scope T delegate(immutable Sym) @safe @nogc pure nothrow cbSym,
) {
	final switch (a.kind) {
		case Repr.Kind.arr:
			return cbArr(a.arr);
		case Repr.Kind.bool_:
			return cbBool(a.bool_);
		case Repr.Kind.namedRecord:
			return cbNamedRecord(a.namedRecord);
		case Repr.Kind.float_:
			return cbFloat(a.float_);
		case Repr.Kind.int_:
			return cbInt(a.int_);
		case Repr.Kind.opt:
			return cbOpt(a.opt);
		case Repr.Kind.record:
			return cbRecord(a.record);
		case Repr.Kind.str:
			return cbStr(a.str);
		case Repr.Kind.symbol:
			return cbSym(a.symbol);
	}
}

void writeReprNoNewline(Alloc)(ref Writer!Alloc writer, immutable Repr a) {
	writeRepr(writer, 0, maxWidth, a);
}

void writeRepr(Alloc)(ref Writer!Alloc writer, immutable Repr a) {
	writeReprNoNewline(writer, a);
	writeChar(writer, '\n');
}

immutable(CStr) jsonStrOfRepr(Alloc)(ref Alloc alloc, ref immutable Repr a) {
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	writeReprJSON(writer, a);
	return finishWriterToCStr(writer);
}

void writeReprJSON(Alloc)(ref Writer!Alloc writer, ref immutable Repr a) {
	matchRepr!void(
		a,
		(ref immutable ReprArr it) {
			writeChar(writer, '[');
			writeWithCommas!Repr(writer, it.arr, (ref immutable Repr em) {
				writeReprJSON(writer, em);
			});
			writeChar(writer, ']');
		},
		(immutable Bool it) {
			writeReprBool(writer, it);
		},
		(immutable double it) {
			todo!void("");
		},
		(immutable ReprInt it) {
			writeReprInt(writer, it);
		},
		(ref immutable ReprNamedRecord it) {
			writeStatic(writer, "{\"_type\":");
			writeQuotedSym(writer, it.name);
			foreach (ref immutable NameAndRepr pair; it.children) {
				writeChar(writer, ',');
				writeQuotedSym(writer, pair.name);
				writeChar(writer, ':');
				writeReprJSON(writer, pair.value);
			}
			writeChar(writer,'}');
		},
		(immutable Opt!(Ptr!Repr) it) {
			if (has(it)) {
				writeStatic(writer, "{\"_type\":\"some\",\"value\":");
				writeReprJSON(writer, force(it));
				writeChar(writer, '}');
			} else {
				writeStatic(writer, "{\"_type\":\"none\"}");
			}
		},
		(ref immutable ReprRecord it) {
			writeStatic(writer, "{\"_type\":");
			writeQuotedSym(writer, it.name);
			writeStatic(writer, ",\"args\":[");
			writeWithCommas!Repr(writer, it.children, (ref immutable Repr child) {
				writeReprJSON(writer, child);
			});
			writeStatic(writer, "]}");
		},
		(ref immutable Str it) {
			writeQuotedStr(writer, it);
		},
		(immutable Sym it) {
			writeQuotedSym(writer, it);
		});
}

private:

void writeQuotedSym(Alloc)(ref Writer!Alloc writer, immutable Sym a) {
	writeChar(writer, '"');
	writeSym(writer, a);
	writeChar(writer, '"');
}

immutable int indentSize = 4;
immutable size_t maxWidth = 120;

void writeRepr(Alloc)(
	ref Writer!Alloc writer,
	immutable size_t indent,
	immutable int availableWidth,
	ref immutable Repr a,
) {
	matchRepr!void(
		a,
		(ref immutable ReprArr s) {
			if (measureReprArr(s, availableWidth) < 0) {
				writeChar(writer, '[');
				foreach (immutable size_t index; 0..size(s.arr)) {
					writeNewline(writer, indent + 1);
					if (s.showIndices) {
						writeNat(writer, index);
						writeStatic(writer, ": ");
					}
					writeRepr(writer, indent + 1, availableWidth - indentSize, at(s.arr, index));
				}
				writeChar(writer, ']');
			} else
				writeReprArrSingleLine(writer, s.arr);
		},
		(immutable Bool s) {
			writeReprBool(writer, s);
		},
		(immutable double it) {
			writeFloatLiteral(writer, it);
		},
		(immutable ReprInt it) {
			writeReprInt(writer, it);
		},
		(ref immutable ReprNamedRecord it) {
			if (measureReprNamedRecord(it, availableWidth) < 0) {
				writeSym(writer, it.name);
				writeChar(writer, '(');
				foreach (ref immutable NameAndRepr element; it.children) {
					writeNewline(writer, indent + 1);
					writeSym(writer, element.name);
					writeStatic(writer, ": ");
					writeRepr(writer, indent + 1, availableWidth - indentSize, element.value);
				}
				writeChar(writer, ')');
			} else
				writeReprNamedRecordSingleLine(writer, it);
		},
		(immutable Opt!(Ptr!Repr) s) {
			if (has(s)) {
				writeStatic(writer, "some(");
				writeRepr(writer, indent, availableWidth, force(s).deref);
				writeChar(writer, ')');
			} else
				writeStatic(writer, "none");
		},
		(ref immutable ReprRecord s) {
			if (measureReprRecord(s, availableWidth) < 0) {
				writeSym(writer, s.name);
				writeChar(writer, '(');
				foreach (ref immutable Repr element; s.children) {
					writeNewline(writer, indent + 1);
					writeRepr(writer, indent + 1, availableWidth - indentSize, element);
				}
				writeChar(writer, ')');
			} else
				writeReprRecordSingleLine(writer, s);
		},
		(ref immutable Str s) {
			writeQuotedStr(writer, s);
		},
		(immutable Sym s) {
			writeSym(writer, s);
		});
}

// Returns the size remaining, but all negative numbers considered equivalent
immutable(int) measureReprSingleLine(ref immutable Repr a, immutable int available) {
	return matchRepr!(immutable int)(
		a,
		(ref immutable ReprArr s) =>
			measureReprArr(s, available),
		(immutable Bool s) =>
			available - measureReprBool(s),
		(immutable double) =>
			// TODO: more accurate
			3,
		(immutable ReprInt s) =>
			available - measureReprInt(s),
		(ref immutable ReprNamedRecord s) =>
			measureReprNamedRecord(s, available),
		(immutable Opt!(Ptr!Repr) s) =>
			has(s)
				? measureReprSingleLine(force(s), available - safeIntFromSizeT("some()".length))
				: available - safeIntFromSizeT("none".length),
		(ref immutable ReprRecord s) =>
			measureReprRecord(s, available),
		(ref immutable Str s) =>
			available - measureQuotedStr(s),
		(immutable Sym s) =>
			available - safeIntFromSizeT(symSize(s)));
}

immutable(int) measureReprArr(ref immutable ReprArr a, immutable int available) {
	return measureCommaSeparatedChildren(a.arr, available - safeIntFromSizeT("[]".length));
}

immutable(int) measureReprNamedRecord(ref immutable ReprNamedRecord a, immutable int available) {
	return measureReprNamedRecordRecur(
		a.children,
		available - safeIntFromSizeT(symSize(a.name)) - safeIntFromSizeT("()".length));
}
immutable(int) measureReprNamedRecordRecur(immutable Arr!NameAndRepr xs, immutable int available) {
	if (empty(xs))
		return available;
	else {
		immutable int availableAfterFirst = measureReprSingleLine(
			first(xs).value,
			available - safeIntFromSizeT(symSize(first(xs).name)) - safeIntFromSizeT(": ".length));
		return availableAfterFirst < 0 || empty(tail(xs))
			? availableAfterFirst
			: measureReprNamedRecordRecur(tail(xs), availableAfterFirst - safeIntFromSizeT(", ".length));
	}
}

immutable(int) measureReprRecord(ref immutable ReprRecord a, immutable int available) {
	return measureCommaSeparatedChildren(
		a.children,
		available - safeIntFromSizeT(symSize(a.name)) - safeIntFromSizeT("()".length));
}

immutable(int) measureCommaSeparatedChildren(immutable Arr!Repr xs, immutable int available) {
	if (empty(xs))
		return available;
	else {
		immutable int availableAfterFirst = measureReprSingleLine(first(xs), available);
		return availableAfterFirst < 0 || empty(tail(xs))
			? availableAfterFirst
			: measureCommaSeparatedChildren(tail(xs), availableAfterFirst - safeIntFromSizeT(", ".length));
	}
}

void writeReprSingleLine(Alloc)(ref Writer!Alloc writer, ref immutable Repr a) {
	matchRepr!void(
		a,
		(ref immutable ReprArr s) {
			writeReprArrSingleLine(writer, s.arr);
		},
		(immutable Bool s) {
			writeReprBool(writer, s);
		},
		(immutable double it) {
			writeFloatLiteral(writer, it);
		},
		(immutable ReprInt it) {
			writeReprInt(writer, it);
		},
		(ref immutable ReprNamedRecord s) {
			writeReprNamedRecordSingleLine(writer, s);
		},
		(immutable Opt!(Ptr!Repr) s) {
			if (has(s)) {
				writeStatic(writer, "some(");
				writeReprSingleLine(writer, force(s));
				writeChar(writer, ')');
			} else
				writeStatic(writer, "none");
		},
		(ref immutable ReprRecord s) {
			writeReprRecordSingleLine(writer, s);
		},
		(ref immutable Str s) {
			writeQuotedStr(writer, s);
		},
		(immutable Sym s) {
			writeSym(writer, s);
		});
}

void writeReprArrSingleLine(Alloc)(ref Writer!Alloc writer, ref immutable Arr!Repr a) {
	writeChar(writer, '[');
	writeCommaSeparatedChildren(writer, a);
	writeChar(writer, ']');
}

void writeReprNamedRecordSingleLine(Alloc)(ref Writer!Alloc writer, ref immutable ReprNamedRecord a) {
	writeSym(writer, a.name);
	writeChar(writer, '(');
	writeWithCommas!NameAndRepr(writer, a.children, (ref immutable NameAndRepr child) {
		writeSym(writer, child.name);
		writeStatic(writer, ": ");
		writeReprSingleLine(writer, child.value);
	});
	writeChar(writer, ')');
}

void writeReprRecordSingleLine(Alloc)(ref Writer!Alloc writer, ref immutable ReprRecord a) {
	writeSym(writer, a.name);
	writeChar(writer, '(');
	writeCommaSeparatedChildren(writer, a.children);
	writeChar(writer, ')');
}

void writeCommaSeparatedChildren(Alloc)(ref Writer!Alloc writer, ref immutable Arr!Repr a) {
	writeWithCommas!Repr(writer, a, (ref immutable Repr it) {
		writeReprSingleLine(writer, it);
	});
}

immutable(int) measureReprBool(ref immutable Bool s) {
	return s ? "true".length : "false".length;
}

void writeReprBool(Alloc)(ref Writer!Alloc writer, ref immutable Bool s) {
	writeStatic(writer, s ? "true" : "false");
}

immutable(int) measureReprInt(immutable ReprInt s) {
	uint recur(immutable uint size, immutable ulong a) {
		return a == 0 ? 0 : recur(size + 1, a / s.base);
	}
	return (s.value < 0 ? 1 : 0) + recur(1, abs(s.value) / s.base);
}

immutable(int) measureQuotedStr(ref immutable Str s) {
	return 2 + safeIntFromSizeT(size(s));
}

void writeReprInt(Alloc)(ref Writer!Alloc writer, ref immutable ReprInt a) {
	if (a.base == 16)
		writeStatic(writer, "0x");
	writeInt(writer, a.value, a.base);
}
