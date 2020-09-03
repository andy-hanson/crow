module util.sexpr;

@safe @nogc pure nothrow:

import util.bools : Bool;
import util.collection.arr : Arr, empty, emptyArr, first, range, size;
import util.collection.arrUtil : arrLiteral, map, tail;
import util.collection.str : Str;
import util.memory : allocate;
import util.opt : force, has, Opt;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.sym : shortSymAlphaLiteral, Sym, symSize, writeSym;
import util.types : safeIntFromSizeT;
import util.util : todo;
import util.verify : unreachable;
import util.writer :
	dedent,
	incrIndent,
	indent,
	newline,
	writeChar,
	writeNat,
	Writer,
	writeStatic,
	writeStr,
	WriterWithIndent,
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

immutable(Sexpr) tataRecord(Alloc)(ref Alloc alloc, immutable string name, immutable Sexpr child0) {
	return tataRecord(name, arrLiteral!Sexpr(alloc, child0));
}

immutable(Sexpr) tataRecord(Alloc)(
	ref Alloc alloc,
	immutable string name,
	immutable Sexpr child0,
	immutable Sexpr child1,
) {
	return tataRecord(name, arrLiteral!Sexpr(alloc, child0, child1));
}

immutable(Sexpr) tataRecord(Alloc)(
	ref Alloc alloc,
	immutable string name,
	immutable Sexpr child0,
	immutable Sexpr child1,
	immutable Sexpr child2,
) {
	return tataRecord(name, arrLiteral!Sexpr(alloc, child0, child1, child2));
}

immutable(Sexpr) tataRecord(Alloc)(
	ref Alloc alloc,
	immutable string name,
	immutable Sexpr child0,
	immutable Sexpr child1,
	immutable Sexpr child2,
	immutable Sexpr child3,
) {
	return tataRecord(name, arrLiteral!Sexpr(alloc, child0, child1, child2, child3));
}

immutable(Sexpr) tataRecord(Alloc)(
	ref Alloc alloc,
	immutable string name,
	immutable Sexpr child0,
	immutable Sexpr child1,
	immutable Sexpr child2,
	immutable Sexpr child3,
	immutable Sexpr child4,
) {
	return tataRecord(name, arrLiteral!Sexpr(alloc, child0, child1, child2, child3, child4));
}

immutable(Sexpr) tataRecord(Alloc)(
	ref Alloc alloc,
	immutable string name,
	immutable Sexpr child0,
	immutable Sexpr child1,
	immutable Sexpr child2,
	immutable Sexpr child3,
	immutable Sexpr child4,
	immutable Sexpr child5,
) {
	return tataRecord(name, arrLiteral!Sexpr(alloc, child0, child1, child2, child3, child4, child5));
}

private struct SexprRecord {
	immutable Sym name;
	immutable Arr!Sexpr children;
}

immutable(Sexpr) tataNamedRecord(immutable string name, immutable Arr!NameAndSexpr children) {
	return immutable Sexpr(immutable SexprNamedRecord(shortSymAlphaLiteral(name), children));
}

immutable(Sexpr) tataArr(T, Alloc)(
	ref Alloc alloc,
	immutable Arr!T xs,
	scope immutable(Sexpr) delegate(ref immutable T) @safe @nogc pure nothrow cb,
) {
	return immutable Sexpr(map(alloc, xs, cb), true);
}

private struct SexprNamedRecord {
	immutable Sym name;
	immutable Arr!NameAndSexpr children;
}

struct NameAndSexpr {
	immutable Sym name;
	immutable Sexpr value;
}

struct Sexpr {
	@safe @nogc pure nothrow:
	private:
	enum Kind {
		arr,
		bool_,
		namedRecord,
		nat,
		opt,
		record,
		str,
		symbol,
	}
	immutable Kind kind;
	union {
		immutable Arr!Sexpr arr;
		immutable Bool bool_;
		immutable SexprNamedRecord namedRecord;
		immutable size_t nat;
		immutable Opt!(Ptr!Sexpr) opt;
		immutable SexprRecord record;
		immutable Str str;
		immutable Sym symbol;
	}

	@trusted this(immutable Arr!Sexpr a, bool b) immutable { kind = Kind.arr; arr = a; }
	public:
	this(immutable Bool a) immutable { kind = Kind.bool_; bool_ = a; }
	@trusted this(immutable SexprNamedRecord a) immutable { kind = Kind.namedRecord; namedRecord = a; }
	@trusted this(immutable size_t a) immutable { kind = Kind.nat; nat = a; }
	@trusted this(immutable Opt!(Ptr!Sexpr) a) immutable { kind = Kind.opt; opt = a; }
	@trusted this(immutable SexprRecord a) immutable { kind = Kind.record; record = a; }
	@trusted this(immutable Str a) immutable { kind = Kind.str; str = a; }
	this(immutable Sym a) immutable { kind = Kind.symbol; symbol = a; }
}

@trusted T matchSexpr(T)(
	ref immutable Sexpr a,
	scope T delegate(ref immutable Arr!Sexpr) @safe @nogc pure nothrow cbArr,
	scope T delegate(immutable Bool) @safe @nogc pure nothrow cbBool,
	scope T delegate(immutable size_t) @safe @nogc pure nothrow cbNat,
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
		case Sexpr.Kind.nat:
			return cbNat(a.nat);
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

immutable(Ptr!Sexpr) allocSexpr(Alloc)(ref Alloc alloc, immutable Sexpr s) {
	return allocate!Sexpr(alloc, s);
}

void writeSexpr(Alloc)(ref Writer!Alloc writer, ref immutable Sexpr a) {
	writeSexpr(writer, 0, 120, a);
}

private:

immutable int indentSize = 4;

void writeSexpr(Alloc)(
	ref Writer!Alloc writer,
	immutable size_t indent,
	immutable int availableWidth,
	ref immutable Sexpr a,
) {
	matchSexpr(
		a,
		(ref immutable Arr!Sexpr s) {
			if (measureSexprArr(s, availableWidth) < 0) {
				writeChar(writer, '[');
				foreach (ref immutable Sexpr element; s.range) {
					newline(writer, indent + 1);
					writeSexpr(writer, indent + 1, availableWidth - indentSize, element);
				}
				writeChar(writer, ']');
			} else
				writeSexprArrSingleLine(writer, s);
		},
		(immutable Bool s) {
			writeSexprBool(writer, s);
		},
		(immutable size_t s) {
			writeNat(writer, s);
		},
		(ref immutable SexprNamedRecord s) {
			writeSym(writer, s.name);
			writeChar(writer, '(');
			foreach (ref immutable NameAndSexpr element; s.children.range) {
				newline(writer, indent + 1);
				writeSym(writer, element.name);
				writeStatic(writer, ": ");
				writeSexpr(writer, indent + 1, availableWidth - indentSize, element.value);
			}
			writeChar(writer, ')');
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
		},
	);
}

private:

// Returns the size remaining, but all negative numbers considered equivalent
immutable(int) measureSexprSingleLine(ref immutable Sexpr a, immutable int available) {
	return matchSexpr!(immutable int)(
		a,
		(ref immutable Arr!Sexpr s) =>
			measureSexprArr(s, available),
		(immutable Bool s) =>
			available - measureSexprBool(s),
		(immutable size_t s) =>
			available - measureSexprNat(s),
		(ref immutable SexprNamedRecord s) =>
			// Never format these on one line
			-1,
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

immutable(int) measureSexprArr(ref immutable Arr!Sexpr a, immutable int available) {
	return measureCommaSeparatedChildren(a, available);
}

immutable(int) measureSexprRecord(ref immutable SexprRecord a, immutable int available) {
	return measureCommaSeparatedChildren(a.children, available - safeIntFromSizeT(symSize(a.name)));
}

immutable(int) measureCommaSeparatedChildren(immutable Arr!Sexpr s, immutable int available) {
	immutable int res = available - 2; // for '[' and ']'
	if (res < 0 || empty(s)) return res;
	immutable(int) recur(immutable Arr!Sexpr xs, immutable int remaining) {
		if (empty(xs)) return remaining;
		immutable int x = remaining - 2; // For ", "
		return x < 0 ? x : recur(tail(xs), measureSexprSingleLine(first(xs), x));
	}
	immutable int res2 = measureSexprSingleLine(first(s), res);
	return recur(tail(s), res2);
}

void writeSexprSingleLine(Alloc)(ref Writer!Alloc writer, ref immutable Sexpr a) {
	matchSexpr(
		a,
		(ref immutable Arr!Sexpr s) {
			writeSexprArrSingleLine(writer, s);
		},
		(immutable Bool s) {
			writeSexprBool(writer, s);
		},
		(immutable size_t s) {
			writeNat(writer, s);
		},
		(ref immutable SexprNamedRecord s) {
			unreachable!void(); // Had infinite measure, so we'll never format to single line
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

void writeSexprRecordSingleLine(Alloc)(ref Writer!Alloc writer, ref immutable SexprRecord a) {
	writeSym(writer, a.name);
	writeChar(writer, '(');
	writeCommaSeparatedChildren(writer, a.children);
	writeChar(writer, ')');
}

void writeCommaSeparatedChildren(Alloc)(ref Writer!Alloc writer, ref immutable Arr!Sexpr a) {
	if (!empty(a)) {
		writeSexprSingleLine(writer, first(a));
		void recur(immutable Arr!Sexpr xs) {
			if (!empty(xs)) {
				writeStatic(writer, ", ");
				writeSexprSingleLine(writer, first(xs));
				recur(tail(xs));
			}
		}
		recur(tail(a));
	}
}

immutable(int) measureSexprBool(ref immutable Bool s) {
	return s ? "true".length : "false".length;
}

void writeSexprBool(Alloc)(ref Writer!Alloc writer, ref immutable Bool s) {
	writeStatic(writer, s ? "true" : "false");
}

immutable(int) measureSexprNat(immutable size_t s) {
	uint recur(immutable uint size, immutable size_t a) {
		return a == 0 ? 0 : recur(size + 1, a / 10);
	}
	return recur(1, s / 10);
}

immutable(int) measureQuotedStr(ref immutable Str s) {
	return 2 + safeIntFromSizeT(size(s));
}

void writeQuotedStr(Alloc)(ref Writer!Alloc writer, ref immutable Str s) {
	//TODO: escape inside quotes
	writeChar(writer, '"');
	writeStr(writer, s);
	writeChar(writer, '"');
}
