module util.repr;

@safe @nogc pure nothrow:

import util.alloc.alloc : Alloc;
import util.collection.arr : empty, emptyArr;
import util.collection.arrUtil : arrLiteral, map, mapWithIndex;
import util.collection.fullIndexDict : FullIndexDict;
import util.collection.str : CStr, SafeCStr, strOfSafeCStr;
import util.memory : allocate;
import util.opt : force, has, mapOption, Opt;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.sym : AllSymbols, shortSym, Sym, symSize, writeSym;
import util.util : abs, todo;
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

immutable(Repr) reprRecord(immutable Sym name, immutable Repr[] children) {
	return immutable Repr(immutable ReprRecord(name, children));
}

immutable(Repr) reprRecord(immutable string name, immutable Repr[] children) {
	return reprRecord(shortSym(name), children);
}

immutable(Repr) reprRecord(immutable string name) {
	return reprRecord(name, emptyArr!Repr);
}

immutable(Repr) reprRecord(ref Alloc alloc, immutable string name, scope immutable Repr[] children) {
	return reprRecord(name, arrLiteral(alloc, children));
}

private struct ReprRecord {
	immutable Sym name;
	immutable Repr[] children;
}

immutable(Repr) reprNamedRecord(immutable string name, immutable NameAndRepr[] children) {
	return immutable Repr(immutable ReprNamedRecord(shortSym(name), children));
}

immutable(Repr) reprNamedRecord(
	ref Alloc alloc,
	immutable string name,
	scope immutable NameAndRepr[] children,
) {
	return reprNamedRecord(name, arrLiteral(alloc, children));
}

immutable(Repr) reprArr(T)(
	ref Alloc alloc,
	immutable T[] xs,
	scope immutable(Repr) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	return immutable Repr(immutable ReprArr(false, map(alloc, xs, cb)), true);
}

immutable(Repr) reprArr(T)(
	ref Alloc alloc,
	immutable T[] xs,
	scope immutable(Repr) delegate(immutable size_t, ref immutable T) @safe @nogc pure nothrow cb,
) {
	return immutable Repr(immutable ReprArr(false, mapWithIndex(alloc, xs, cb)), true);
}

immutable(Repr) reprFullIndexDict(K, V)(
	ref Alloc alloc,
	ref immutable FullIndexDict!(K, V) a,
	scope immutable(Repr) delegate(ref immutable V) @safe @nogc pure nothrow cb,
) {
	return immutable Repr(immutable ReprArr(true, map(alloc, a.values, cb)), true);
}

immutable(Repr) reprBool(immutable bool a) {
	return immutable Repr(a);
}

immutable(Repr) reprFloat(immutable double a) {
	return immutable Repr(a);
}

immutable(Repr) reprInt(immutable long a) {
	return immutable Repr(immutable ReprInt(a, 10));
}

immutable(Repr) reprNat(immutable ulong a) {
	return immutable Repr(immutable ReprInt(a, 10));
}

immutable(Repr) reprStr(immutable string a) {
	return immutable Repr(a);
}

immutable(Repr) reprStr(immutable SafeCStr a) {
	return reprStr(strOfSafeCStr(a));
}

immutable(Repr) reprSym(immutable Sym a) {
	return immutable Repr(a);
}

immutable(Repr) reprSym(immutable string a) {
	return reprSym(shortSym(a));
}

immutable(Repr) reprOpt(T)(
	ref Alloc alloc,
	immutable Opt!T opt,
	scope immutable(Repr) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	return immutable Repr(mapOption!(Ptr!Repr, T)(opt, (ref immutable T t) =>
		allocate!Repr(alloc, cb(t))));
}

private struct ReprNamedRecord {
	immutable Sym name;
	immutable NameAndRepr[] children;
}

immutable(NameAndRepr) nameAndRepr(immutable string name, immutable Repr value) {
	return immutable NameAndRepr(shortSym(name), value);
}

struct NameAndRepr {
	immutable Sym name;
	immutable Repr value;
}

private struct ReprArr {
	immutable bool showIndices;
	immutable Repr[] arr;
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
		immutable bool bool_;
		immutable ReprNamedRecord namedRecord;
		immutable double float_;
		immutable ReprInt int_;
		immutable Opt!(Ptr!Repr) opt;
		immutable ReprRecord record;
		immutable string str;
		immutable Sym symbol;
	}

	@trusted immutable this(immutable ReprArr a, bool b) { kind = Kind.arr; arr = a; }
	immutable this(immutable bool a) { kind = Kind.bool_; bool_ = a; }

	@trusted immutable this(immutable ReprNamedRecord a) { kind = Kind.namedRecord; namedRecord = a; }
	immutable this(immutable double a) { kind = Kind.float_; float_ = a; }
	immutable this(immutable ReprInt a) { kind = Kind.int_; int_ = a; }
	@trusted immutable this(immutable Opt!(Ptr!Repr) a) { kind = Kind.opt; opt = a; }
	@trusted immutable this(immutable ReprRecord a) { kind = Kind.record; record = a; }
	@trusted immutable this(immutable string a) { kind = Kind.str; str = a; }
	immutable this(immutable Sym a) { kind = Kind.symbol; symbol = a; }
}

private @trusted T matchRepr(T)(
	ref immutable Repr a,
	scope T delegate(ref immutable ReprArr) @safe @nogc pure nothrow cbArr,
	scope T delegate(immutable bool) @safe @nogc pure nothrow cbBool,
	scope T delegate(immutable double) @safe @nogc pure nothrow cbFloat,
	scope T delegate(immutable ReprInt) @safe @nogc pure nothrow cbInt,
	scope T delegate(ref immutable ReprNamedRecord) @safe @nogc pure nothrow cbNamedRecord,
	scope T delegate(immutable Opt!(Ptr!Repr)) @safe @nogc pure nothrow cbOpt,
	scope T delegate(ref immutable ReprRecord) @safe @nogc pure nothrow cbRecord,
	scope T delegate(ref immutable string) @safe @nogc pure nothrow cbStr,
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

void writeReprNoNewline(ref Writer writer, ref const AllSymbols allSymbols, immutable Repr a) {
	writeRepr(writer, allSymbols, 0, maxWidth, a);
}

void writeRepr(ref Writer writer, ref const AllSymbols allSymbols, immutable Repr a) {
	writeReprNoNewline(writer, allSymbols, a);
	writeChar(writer, '\n');
}

immutable(CStr) jsonStrOfRepr(ref Alloc alloc, ref const AllSymbols allSymbols, ref immutable Repr a) {
	Writer writer = Writer(ptrTrustMe_mut(alloc));
	writeReprJSON(writer, allSymbols, a);
	return finishWriterToCStr(writer);
}

void writeReprJSON(ref Writer writer, ref const AllSymbols allSymbols, ref immutable Repr a) {
	matchRepr!void(
		a,
		(ref immutable ReprArr it) {
			writeChar(writer, '[');
			writeWithCommas!Repr(writer, it.arr, (ref immutable Repr em) {
				writeReprJSON(writer, allSymbols, em);
			});
			writeChar(writer, ']');
		},
		(immutable bool it) {
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
			writeQuotedSym(writer, allSymbols, it.name);
			foreach (ref immutable NameAndRepr pair; it.children) {
				writeChar(writer, ',');
				writeQuotedSym(writer, allSymbols, pair.name);
				writeChar(writer, ':');
				writeReprJSON(writer, allSymbols, pair.value);
			}
			writeChar(writer,'}');
		},
		(immutable Opt!(Ptr!Repr) it) {
			if (has(it)) {
				writeStatic(writer, "{\"_type\":\"some\",\"value\":");
				writeReprJSON(writer, allSymbols, force(it).deref());
				writeChar(writer, '}');
			} else {
				writeStatic(writer, "{\"_type\":\"none\"}");
			}
		},
		(ref immutable ReprRecord it) {
			writeStatic(writer, "{\"_type\":");
			writeQuotedSym(writer, allSymbols, it.name);
			writeStatic(writer, ",\"args\":[");
			writeWithCommas!Repr(writer, it.children, (ref immutable Repr child) {
				writeReprJSON(writer, allSymbols, child);
			});
			writeStatic(writer, "]}");
		},
		(ref immutable string it) {
			writeQuotedStr(writer, it);
		},
		(immutable Sym it) {
			writeQuotedSym(writer, allSymbols, it);
		});
}

private:

void writeQuotedSym(ref Writer writer, ref const AllSymbols allSymbols, immutable Sym a) {
	writeChar(writer, '"');
	writeSym(writer, allSymbols, a);
	writeChar(writer, '"');
}

immutable int indentSize = 4;
immutable size_t maxWidth = 120;

void writeRepr(
	ref Writer writer,
	ref const AllSymbols allSymbols,
	immutable size_t indent,
	immutable int availableWidth,
	ref immutable Repr a,
) {
	matchRepr!void(
		a,
		(ref immutable ReprArr s) {
			if (measureReprArr(s, allSymbols, availableWidth) < 0) {
				writeChar(writer, '[');
				foreach (immutable size_t index; 0 .. s.arr.length) {
					writeNewline(writer, indent + 1);
					if (s.showIndices) {
						writeNat(writer, index);
						writeStatic(writer, ": ");
					}
					writeRepr(writer, allSymbols, indent + 1, availableWidth - indentSize, s.arr[index]);
				}
				writeChar(writer, ']');
			} else
				writeReprArrSingleLine(writer, allSymbols, s.arr);
		},
		(immutable bool s) {
			writeReprBool(writer, s);
		},
		(immutable double it) {
			writeFloatLiteral(writer, it);
		},
		(immutable ReprInt it) {
			writeReprInt(writer, it);
		},
		(ref immutable ReprNamedRecord it) {
			if (measureReprNamedRecord(it, allSymbols, availableWidth) < 0) {
				writeSym(writer, allSymbols, it.name);
				writeChar(writer, '(');
				foreach (ref immutable NameAndRepr element; it.children) {
					writeNewline(writer, indent + 1);
					writeSym(writer, allSymbols, element.name);
					writeStatic(writer, ": ");
					writeRepr(writer, allSymbols, indent + 1, availableWidth - indentSize, element.value);
				}
				writeChar(writer, ')');
			} else
				writeReprNamedRecordSingleLine(writer, allSymbols, it);
		},
		(immutable Opt!(Ptr!Repr) s) {
			if (has(s)) {
				writeStatic(writer, "some(");
				writeRepr(writer, allSymbols, indent, availableWidth, force(s).deref);
				writeChar(writer, ')');
			} else
				writeStatic(writer, "none");
		},
		(ref immutable ReprRecord s) {
			if (measureReprRecord(s, allSymbols, availableWidth) < 0) {
				writeSym(writer, allSymbols, s.name);
				writeChar(writer, '(');
				foreach (ref immutable Repr element; s.children) {
					writeNewline(writer, indent + 1);
					writeRepr(writer, allSymbols, indent + 1, availableWidth - indentSize, element);
				}
				writeChar(writer, ')');
			} else
				writeReprRecordSingleLine(writer, allSymbols, s);
		},
		(ref immutable string s) {
			writeQuotedStr(writer, s);
		},
		(immutable Sym s) {
			writeSym(writer, allSymbols, s);
		});
}

// Returns the size remaining, but all negative numbers considered equivalent
immutable(int) measureReprSingleLine(ref immutable Repr a, ref const AllSymbols allSymbols, immutable int available) {
	return matchRepr!(immutable int)(
		a,
		(ref immutable ReprArr s) =>
			measureReprArr(s, allSymbols, available),
		(immutable bool s) =>
			available - measureReprBool(s),
		(immutable double) =>
			// TODO: more accurate
			3,
		(immutable ReprInt s) =>
			available - measureReprInt(s),
		(ref immutable ReprNamedRecord s) =>
			measureReprNamedRecord(s, allSymbols, available),
		(immutable Opt!(Ptr!Repr) s) =>
			has(s)
				? measureReprSingleLine(force(s).deref(), allSymbols, available - len!"some()")
				: available - len!"none",
		(ref immutable ReprRecord s) =>
			measureReprRecord(s, allSymbols, available),
		(ref immutable string s) =>
			available - len!"\"\"" - cast(int) s.length,
		(immutable Sym s) =>
			cast(int) (available - symSize(allSymbols, s)));
}

immutable(int) measureReprArr(ref immutable ReprArr a, ref const AllSymbols allSymbols, immutable int available) {
	return measureCommaSeparatedChildren(a.arr, allSymbols, available - len!"[]");
}

immutable(int) measureReprNamedRecord(
	ref immutable ReprNamedRecord a,
	ref const AllSymbols allSymbols,
	immutable int available,
) {
	return measureReprNamedRecordRecur(a.children, allSymbols, available - symSize(allSymbols, a.name) - len!"()");
}
immutable(int) measureReprNamedRecordRecur(
	immutable NameAndRepr[] xs,
	ref const AllSymbols allSymbols,
	immutable int available,
) {
	if (empty(xs))
		return available;
	else {
		immutable int availableAfterFirst =
			measureReprSingleLine(xs[0].value, allSymbols, available - symSize(allSymbols, xs[0].name) - len!": ");
		return availableAfterFirst < 0 || empty(xs[1 .. $])
			? availableAfterFirst
			: measureReprNamedRecordRecur(xs[1 .. $], allSymbols, availableAfterFirst - len!", ");
	}
}

immutable(int) measureReprRecord(
	ref immutable ReprRecord a,
	ref const AllSymbols allSymbols,
	immutable int available,
) {
	return measureCommaSeparatedChildren(a.children, allSymbols, available - symSize(allSymbols, a.name) - len!"()");
}

immutable(int) measureCommaSeparatedChildren(
	immutable Repr[] xs,
	ref const AllSymbols allSymbols,
	immutable int available,
) {
	if (empty(xs))
		return available;
	else {
		immutable int availableAfterFirst = measureReprSingleLine(xs[0], allSymbols, available);
		return availableAfterFirst < 0 || empty(xs[1 .. $])
			? availableAfterFirst
			: measureCommaSeparatedChildren(xs[1 .. $], allSymbols, availableAfterFirst - len!", ");
	}
}

void writeReprSingleLine(ref Writer writer, ref const AllSymbols allSymbols, ref immutable Repr a) {
	matchRepr!void(
		a,
		(ref immutable ReprArr s) {
			writeReprArrSingleLine(writer, allSymbols, s.arr);
		},
		(immutable bool s) {
			writeReprBool(writer, s);
		},
		(immutable double it) {
			writeFloatLiteral(writer, it);
		},
		(immutable ReprInt it) {
			writeReprInt(writer, it);
		},
		(ref immutable ReprNamedRecord s) {
			writeReprNamedRecordSingleLine(writer, allSymbols, s);
		},
		(immutable Opt!(Ptr!Repr) s) {
			if (has(s)) {
				writeStatic(writer, "some(");
				writeReprSingleLine(writer, allSymbols, force(s).deref());
				writeChar(writer, ')');
			} else
				writeStatic(writer, "none");
		},
		(ref immutable ReprRecord s) {
			writeReprRecordSingleLine(writer, allSymbols, s);
		},
		(ref immutable string s) {
			writeQuotedStr(writer, s);
		},
		(immutable Sym s) {
			writeSym(writer, allSymbols, s);
		});
}

void writeReprArrSingleLine(ref Writer writer, ref const AllSymbols allSymbols, ref immutable Repr[] a) {
	writeChar(writer, '[');
	writeCommaSeparatedChildren(writer, allSymbols, a);
	writeChar(writer, ']');
}

void writeReprNamedRecordSingleLine(
	ref Writer writer,
	ref const AllSymbols allSymbols,
	ref immutable ReprNamedRecord a,
) {
	writeSym(writer, allSymbols, a.name);
	writeChar(writer, '(');
	writeWithCommas!NameAndRepr(writer, a.children, (ref immutable NameAndRepr child) {
		writeSym(writer, allSymbols, child.name);
		writeStatic(writer, ": ");
		writeReprSingleLine(writer, allSymbols, child.value);
	});
	writeChar(writer, ')');
}

void writeReprRecordSingleLine(ref Writer writer, ref const AllSymbols allSymbols, ref immutable ReprRecord a) {
	writeSym(writer, allSymbols, a.name);
	writeChar(writer, '(');
	writeCommaSeparatedChildren(writer, allSymbols, a.children);
	writeChar(writer, ')');
}

void writeCommaSeparatedChildren(ref Writer writer, ref const AllSymbols allSymbols, ref immutable Repr[] a) {
	writeWithCommas!Repr(writer, a, (ref immutable Repr it) {
		writeReprSingleLine(writer, allSymbols, it);
	});
}

immutable(int) measureReprBool(ref immutable bool s) {
	return s ? len!"true" : len!"false";
}

void writeReprBool(ref Writer writer, ref immutable bool s) {
	writeStatic(writer, s ? "true" : "false");
}

immutable(int) measureReprInt(immutable ReprInt s) {
	uint recur(immutable uint size, immutable ulong a) {
		return a == 0 ? 0 : recur(size + 1, a / s.base);
	}
	return (s.value < 0 ? 1 : 0) + recur(1, abs(s.value) / s.base);
}

void writeReprInt(ref Writer writer, ref immutable ReprInt a) {
	if (a.base == 16)
		writeStatic(writer, "0x");
	writeInt(writer, a.value, a.base);
}

immutable(int) len(immutable string s)() {
	return cast(int) s.length;
}
