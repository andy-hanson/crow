module util.sexpr;

@safe @nogc pure nothrow:

import util.bools : Bool, False, True;
import util.collection.arr : Arr, at, empty, emptyArr, first, range, size;
import util.collection.arrUtil : arrLiteral, map, mapWithIndex, tail;
import util.collection.fullIndexDict : FullIndexDict;
import util.collection.str : CStr, Str, strLiteral;
import util.memory : allocate;
import util.opt : force, has, mapOption, Opt;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.sym : shortSymAlphaLiteral, Sym, symSize, writeSym;
import util.types : abs, IntN, NatN, safeIntFromSizeT;
import util.writer :
	finishWriterToCStr,
	newline,
	writeChar,
	writeInt,
	writeNat,
	Writer,
	writeQuotedStr,
	writeStatic,
	writeWithCommas;

immutable(Sexpr) tataRecord(immutable Sym name, immutable Arr!Sexpr children) {
	return immutable Sexpr(immutable SexprRecord(name, children));
}

immutable(Sexpr) tataRecord(immutable string name, immutable Arr!Sexpr children) {
	return tataRecord(shortSymAlphaLiteral(name), children);
}

immutable(Sexpr) tataRecord(immutable string name) {
	return tataRecord(name, emptyArr!Sexpr);
}

immutable(Sexpr) tataRecord(Alloc)(ref Alloc alloc, immutable string name, scope immutable Sexpr[] children) {
	return tataRecord(name, arrLiteral(alloc, children));
}

private struct SexprRecord {
	immutable Sym name;
	immutable Arr!Sexpr children;
}

immutable(Sexpr) tataNamedRecord(immutable string name, immutable Arr!NameAndSexpr children) {
	return immutable Sexpr(immutable SexprNamedRecord(shortSymAlphaLiteral(name), children));
}

immutable(Sexpr) tataNamedRecord(Alloc)(
	ref Alloc alloc,
	immutable string name,
	scope immutable NameAndSexpr[] children,
) {
	return tataNamedRecord(name, arrLiteral(alloc, children));
}

immutable(Sexpr) tataArr(T, Alloc)(
	ref Alloc alloc,
	immutable Arr!T xs,
	scope immutable(Sexpr) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	return immutable Sexpr(immutable SexprArr(False, map(alloc, xs, cb)), true);
}

immutable(Sexpr) tataArr(T, Alloc)(
	ref Alloc alloc,
	immutable Arr!T xs,
	scope immutable(Sexpr) delegate(immutable size_t, ref immutable T) @safe @nogc pure nothrow cb,
) {
	return immutable Sexpr(immutable SexprArr(False, mapWithIndex(alloc, xs, cb)), true);
}

immutable(Sexpr) tataFullIndexDict(K, V, Alloc)(
	ref Alloc alloc,
	ref immutable FullIndexDict!(K, V) a,
	scope immutable(Sexpr) delegate(ref immutable V) @safe @nogc pure nothrow cb,
) {
	return immutable Sexpr(immutable SexprArr(True, map(alloc, a.values, cb)), true);
}

immutable(Sexpr) tataBool(immutable Bool a) {
	return immutable Sexpr(a);
}

immutable(Sexpr) tataHex(T)(immutable NatN!T a) {
	return immutable Sexpr(immutable SexprInt(a.raw(), 16));
}

immutable(Sexpr) tataInt(T)(immutable IntN!T a) {
	return immutable Sexpr(immutable SexprInt(a.raw(), 16));
}

immutable(Sexpr) tataNat(T)(immutable NatN!T a) {
	return tataNat(a.raw());
}

immutable(Sexpr) tataNat(immutable size_t a) {
	return immutable Sexpr(immutable SexprInt(a, 10));
}

immutable(Sexpr) tataStr(immutable Str a) {
	return immutable Sexpr(a);
}

immutable(Sexpr) tataStr(immutable string a) {
	return tataStr(strLiteral(a));
}

immutable(Sexpr) tataSym(immutable Sym a) {
	return immutable Sexpr(a);
}

immutable(Sexpr) tataSym(immutable string a) {
	return tataSym(shortSymAlphaLiteral(a));
}

immutable(Sexpr) tataOpt(Alloc, T)(
	ref Alloc alloc,
	immutable Opt!T opt,
	scope immutable(Sexpr) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	return immutable Sexpr(mapOption(opt, (ref immutable T t) =>
		allocate!Sexpr(alloc, cb(t))));
}

private struct SexprNamedRecord {
	immutable Sym name;
	immutable Arr!NameAndSexpr children;
}

immutable(NameAndSexpr) nameAndTata(immutable string name, immutable Sexpr value) {
	return immutable NameAndSexpr(shortSymAlphaLiteral(name), value);
}

struct NameAndSexpr {
	immutable Sym name;
	immutable Sexpr value;
}

private struct SexprArr {
	immutable Bool showIndices;
	immutable Arr!Sexpr arr;
}

private struct SexprInt {
	immutable long value;
	immutable size_t base;
}

struct Sexpr {
	@safe @nogc pure nothrow:
	private:
	enum Kind {
		arr,
		bool_,
		namedRecord,
		int_,
		opt,
		record,
		str,
		symbol,
	}
	immutable Kind kind;
	union {
		immutable SexprArr arr;
		immutable Bool bool_;
		immutable SexprNamedRecord namedRecord;
		immutable SexprInt int_;
		immutable Opt!(Ptr!Sexpr) opt;
		immutable SexprRecord record;
		immutable Str str;
		immutable Sym symbol;
	}

	@trusted this(immutable SexprArr a, bool b) immutable { kind = Kind.arr; arr = a; }
	this(immutable Bool a) immutable { kind = Kind.bool_; bool_ = a; }
	@trusted this(immutable SexprNamedRecord a) immutable { kind = Kind.namedRecord; namedRecord = a; }
	@trusted this(immutable SexprInt a) immutable { kind = Kind.int_; int_ = a; }
	@trusted this(immutable Opt!(Ptr!Sexpr) a) immutable { kind = Kind.opt; opt = a; }
	@trusted this(immutable SexprRecord a) immutable { kind = Kind.record; record = a; }
	@trusted this(immutable Str a) immutable { kind = Kind.str; str = a; }
	this(immutable Sym a) immutable { kind = Kind.symbol; symbol = a; }
}

private @trusted T matchSexpr(T)(
	ref immutable Sexpr a,
	scope T delegate(ref immutable SexprArr) @safe @nogc pure nothrow cbArr,
	scope T delegate(immutable Bool) @safe @nogc pure nothrow cbBool,
	scope T delegate(immutable SexprInt) @safe @nogc pure nothrow cbInt,
	scope T delegate(ref immutable SexprNamedRecord) @safe @nogc pure nothrow cbNamedRecord,
	scope T delegate(immutable Opt!(Ptr!Sexpr)) @safe @nogc pure nothrow cbOpt,
	scope T delegate(ref immutable SexprRecord) @safe @nogc pure nothrow cbRecord,
	scope T delegate(ref immutable Str) @safe @nogc pure nothrow cbStr,
	scope T delegate(immutable Sym) @safe @nogc pure nothrow cbSym,
) {
	final switch (a.kind) {
		case Sexpr.Kind.arr:
			return cbArr(a.arr);
		case Sexpr.Kind.bool_:
			return cbBool(a.bool_);
		case Sexpr.Kind.namedRecord:
			return cbNamedRecord(a.namedRecord);
		case Sexpr.Kind.int_:
			return cbInt(a.int_);
		case Sexpr.Kind.opt:
			return cbOpt(a.opt);
		case Sexpr.Kind.record:
			return cbRecord(a.record);
		case Sexpr.Kind.str:
			return cbStr(a.str);
		case Sexpr.Kind.symbol:
			return cbSym(a.symbol);
	}
}

void writeSexprNoNewline(Alloc)(ref Writer!Alloc writer, immutable Sexpr a) {
	writeSexpr(writer, 0, maxWidth, a);
}

void writeSexpr(Alloc)(ref Writer!Alloc writer, immutable Sexpr a) {
	writeSexprNoNewline(writer, a);
	writeChar(writer, '\n');
}

immutable(CStr) jsonStrOfSexpr(Alloc)(ref Alloc alloc, ref immutable Sexpr a) {
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	writeSexprJSON(writer, a);
	return finishWriterToCStr(writer);
}

void writeSexprJSON(Alloc)(ref Writer!Alloc writer, ref immutable Sexpr a) {
	matchSexpr!void(
		a,
		(ref immutable SexprArr it) {
			writeChar(writer, '[');
			writeWithCommas!Sexpr(writer, it.arr, (ref immutable Sexpr em) {
				writeSexprJSON(writer, em);
			});
			writeChar(writer, ']');
		},
		(immutable Bool it) {
			writeSexprBool(writer, it);
		},
		(immutable SexprInt it) {
			writeSexprInt(writer, it);
		},
		(ref immutable SexprNamedRecord it) {
			writeStatic(writer, "{\"_type\":");
			writeQuotedSym(writer, it.name);
			foreach (ref immutable NameAndSexpr pair; range(it.children)) {
				writeChar(writer, ',');
				writeQuotedSym(writer, pair.name);
				writeChar(writer, ':');
				writeSexprJSON(writer, pair.value);
			}
			writeChar(writer,'}');
		},
		(immutable Opt!(Ptr!Sexpr) it) {
			if (has(it)) {
				writeStatic(writer, "{\"_type\":\"some\",\"value\":");
				writeSexprJSON(writer, force(it));
				writeChar(writer, '}');
			} else {
				writeStatic(writer, "{\"_type\":\"none\"}");
			}
		},
		(ref immutable SexprRecord it) {
			writeStatic(writer, "{\"_type\":");
			writeQuotedSym(writer, it.name);
			writeStatic(writer, ",\"args\":[");
			writeWithCommas!Sexpr(writer, it.children, (ref immutable Sexpr child) {
				writeSexprJSON(writer, child);
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

void writeSexpr(Alloc)(
	ref Writer!Alloc writer,
	immutable size_t indent,
	immutable int availableWidth,
	ref immutable Sexpr a,
) {
	matchSexpr!void(
		a,
		(ref immutable SexprArr s) {
			if (measureSexprArr(s, availableWidth) < 0) {
				writeChar(writer, '[');
				foreach (immutable size_t index; 0..size(s.arr)) {
					newline(writer, indent + 1);
					if (s.showIndices) {
						writeNat(writer, index);
						writeStatic(writer, ": ");
					}
					writeSexpr(writer, indent + 1, availableWidth - indentSize, at(s.arr, index));
				}
				writeChar(writer, ']');
			} else
				writeSexprArrSingleLine(writer, s.arr);
		},
		(immutable Bool s) {
			writeSexprBool(writer, s);
		},
		(immutable SexprInt it) {
			writeSexprInt(writer, it);
		},
		(ref immutable SexprNamedRecord it) {
			if (measureSexprNamedRecord(it, availableWidth) < 0) {
				writeSym(writer, it.name);
				writeChar(writer, '(');
				foreach (ref immutable NameAndSexpr element; it.children.range) {
					newline(writer, indent + 1);
					writeSym(writer, element.name);
					writeStatic(writer, ": ");
					writeSexpr(writer, indent + 1, availableWidth - indentSize, element.value);
				}
				writeChar(writer, ')');
			} else
				writeSexprNamedRecordSingleLine(writer, it);
		},
		(immutable Opt!(Ptr!Sexpr) s) {
			if (has(s)) {
				writeStatic(writer, "some(");
				writeSexpr(writer, indent, availableWidth, force(s).deref);
				writeChar(writer, ')');
			} else
				writeStatic(writer, "none");
		},
		(ref immutable SexprRecord s) {
			if (measureSexprRecord(s, availableWidth) < 0) {
				writeSym(writer, s.name);
				writeChar(writer, '(');
				foreach (ref immutable Sexpr element; s.children.range) {
					newline(writer, indent + 1);
					writeSexpr(writer, indent + 1, availableWidth - indentSize, element);
				}
				writeChar(writer, ')');
			} else
				writeSexprRecordSingleLine(writer, s);
		},
		(ref immutable Str s) {
			writeQuotedStr(writer, s);
		},
		(immutable Sym s) {
			writeSym(writer, s);
		});
}

// Returns the size remaining, but all negative numbers considered equivalent
immutable(int) measureSexprSingleLine(ref immutable Sexpr a, immutable int available) {
	return matchSexpr!(immutable int)(
		a,
		(ref immutable SexprArr s) =>
			measureSexprArr(s, available),
		(immutable Bool s) =>
			available - measureSexprBool(s),
		(immutable SexprInt s) =>
			available - measureSexprInt(s),
		(ref immutable SexprNamedRecord s) =>
			measureSexprNamedRecord(s, available),
		(immutable Opt!(Ptr!Sexpr) s) =>
			has(s)
				? measureSexprSingleLine(force(s), available - safeIntFromSizeT("some()".length))
				: available - safeIntFromSizeT("none".length),
		(ref immutable SexprRecord s) =>
			measureSexprRecord(s, available),
		(ref immutable Str s) =>
			available - measureQuotedStr(s),
		(immutable Sym s) =>
			available - safeIntFromSizeT(symSize(s)));
}

immutable(int) measureSexprArr(ref immutable SexprArr a, immutable int available) {
	return measureCommaSeparatedChildren(a.arr, available - safeIntFromSizeT("[]".length));
}

immutable(int) measureSexprNamedRecord(ref immutable SexprNamedRecord a, immutable int available) {
	return measureSexprNamedRecordRecur(
		a.children,
		available - safeIntFromSizeT(symSize(a.name)) - safeIntFromSizeT("()".length));
}
immutable(int) measureSexprNamedRecordRecur(immutable Arr!NameAndSexpr xs, immutable int available) {
	if (empty(xs))
		return available;
	else {
		immutable int availableAfterFirst = measureSexprSingleLine(
			first(xs).value,
			available - safeIntFromSizeT(symSize(first(xs).name)) - safeIntFromSizeT(": ".length));
		return availableAfterFirst < 0 || empty(tail(xs))
			? availableAfterFirst
			: measureSexprNamedRecordRecur(tail(xs), availableAfterFirst - safeIntFromSizeT(", ".length));
	}
}

immutable(int) measureSexprRecord(ref immutable SexprRecord a, immutable int available) {
	return measureCommaSeparatedChildren(
		a.children,
		available - safeIntFromSizeT(symSize(a.name)) - safeIntFromSizeT("()".length));
}

immutable(int) measureCommaSeparatedChildren(immutable Arr!Sexpr xs, immutable int available) {
	if (empty(xs))
		return available;
	else {
		immutable int availableAfterFirst = measureSexprSingleLine(first(xs), available);
		return availableAfterFirst < 0 || empty(tail(xs))
			? availableAfterFirst
			: measureCommaSeparatedChildren(tail(xs), availableAfterFirst - safeIntFromSizeT(", ".length));
	}
}

void writeSexprSingleLine(Alloc)(ref Writer!Alloc writer, ref immutable Sexpr a) {
	matchSexpr!void(
		a,
		(ref immutable SexprArr s) {
			writeSexprArrSingleLine(writer, s.arr);
		},
		(immutable Bool s) {
			writeSexprBool(writer, s);
		},
		(immutable SexprInt it) {
			writeSexprInt(writer, it);
		},
		(ref immutable SexprNamedRecord s) {
			writeSexprNamedRecordSingleLine(writer, s);
		},
		(immutable Opt!(Ptr!Sexpr) s) {
			if (has(s)) {
				writeStatic(writer, "some(");
				writeSexprSingleLine(writer, force(s));
				writeChar(writer, ')');
			} else
				writeStatic(writer, "none");
		},
		(ref immutable SexprRecord s) {
			writeSexprRecordSingleLine(writer, s);
		},
		(ref immutable Str s) {
			writeQuotedStr(writer, s);
		},
		(immutable Sym s) {
			writeSym(writer, s);
		});
}

void writeSexprArrSingleLine(Alloc)(ref Writer!Alloc writer, ref immutable Arr!Sexpr a) {
	writeChar(writer, '[');
	writeCommaSeparatedChildren(writer, a);
	writeChar(writer, ']');
}

void writeSexprNamedRecordSingleLine(Alloc)(ref Writer!Alloc writer, ref immutable SexprNamedRecord a) {
	writeSym(writer, a.name);
	writeChar(writer, '(');
	writeWithCommas!NameAndSexpr(writer, a.children, (ref immutable NameAndSexpr child) {
		writeSym(writer, child.name);
		writeStatic(writer, ": ");
		writeSexprSingleLine(writer, child.value);
	});
	writeChar(writer, ')');
}

void writeSexprRecordSingleLine(Alloc)(ref Writer!Alloc writer, ref immutable SexprRecord a) {
	writeSym(writer, a.name);
	writeChar(writer, '(');
	writeCommaSeparatedChildren(writer, a.children);
	writeChar(writer, ')');
}

void writeCommaSeparatedChildren(Alloc)(ref Writer!Alloc writer, ref immutable Arr!Sexpr a) {
	writeWithCommas!Sexpr(writer, a, (ref immutable Sexpr it) {
		writeSexprSingleLine(writer, it);
	});
}

immutable(int) measureSexprBool(ref immutable Bool s) {
	return s ? "true".length : "false".length;
}

void writeSexprBool(Alloc)(ref Writer!Alloc writer, ref immutable Bool s) {
	writeStatic(writer, s ? "true" : "false");
}

immutable(int) measureSexprInt(immutable SexprInt s) {
	uint recur(immutable uint size, immutable ulong a) {
		return a == 0 ? 0 : recur(size + 1, a / s.base);
	}
	return (s.value < 0 ? 1 : 0) + recur(1, abs(s.value) / s.base);
}

immutable(int) measureQuotedStr(ref immutable Str s) {
	return 2 + safeIntFromSizeT(size(s));
}

void writeSexprInt(Alloc)(ref Writer!Alloc writer, ref immutable SexprInt a) {
	if (a.base == 16)
		writeStatic(writer, "0x");
	writeInt(writer, a.value, a.base);
}
