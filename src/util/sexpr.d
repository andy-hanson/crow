module util.sexpr;

@safe @nogc pure nothrow:

import util.bools : Bool;
import util.collection.arr : Arr, range;
import util.collection.str : Str;
import util.ptr : ptrTrustMe_mut;
import util.sym : Sym, writeSym;
import util.types : u32;
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

struct SexprRecord {
	immutable Sym name;
	immutable Arr!Sexpr children;
}

struct SexprNamedRecord {
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
		record,
		str,
		symbol,
	}
	immutable Kind kind;
	union {
		immutable Arr!Sexpr arr;
		immutable Bool bool_;
		immutable SexprNamedRecord namedRecord;
		immutable u32 nat;
		immutable SexprRecord record;
		immutable Str str;
		immutable Sym symbol;
	}

	public:
	@trusted this(immutable Arr!Sexpr a) immutable { kind = Kind.arr; arr = a; }
	this(immutable Bool a) immutable { kind = Kind.bool_; bool_ = a; }
	@trusted this(immutable SexprNamedRecord a) immutable { kind = Kind.namedRecord; namedRecord = a; }
	@trusted this(immutable u32 a) immutable { kind = Kind.nat;nat = a; }
	@trusted this(immutable SexprRecord a) immutable { kind = Kind.record; record = a; }
	@trusted this(immutable Str a) immutable { kind = Kind.str; str = a; }
	this(immutable Sym a) immutable { kind = Kind.symbol; symbol = a; }
}

@trusted T matchSexpr(T)(
	ref immutable Sexpr a,
	scope T delegate(ref immutable Arr!Sexpr) @safe @nogc pure nothrow cbArr,
	scope T delegate(immutable Bool) @safe @nogc pure nothrow cbBool,
	scope T delegate(ref immutable u32) @safe @nogc pure nothrow cbInt,
	scope T delegate(ref immutable SexprNamedRecord) @safe @nogc pure nothrow cbNamedRecord,
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
			return cbInt(a.nat);
		case Sexpr.Kind.record:
			return cbRecord(a.record);
		case Sexpr.Kind.str:
			return cbStr(a.str);
		case Sexpr.Kind.symbol:
			return cbSym(a.symbol);
	}
}

immutable(Sexpr) arrToSexpr(Alloc)(ref Alloc alloc, ref immutable Arr!T a, scope Sexpr delegate(ref immutable T) @safe @nogc pure nothrow cbToSexpr) {
	return Sexpr(map!(const Sexpr)(alloc, a, cbToSexpr));
}

void writeSexpr(Alloc)(ref Writer!Alloc writer, ref immutable Sexpr a) {
	WriterWithIndent!Alloc wi = WriterWithIndent!Alloc(ptrTrustMe_mut(writer), 0);
	return writeSexprRecur(wi, a);
}

private:

void writeSexprRecur(Alloc)(ref WriterWithIndent!Alloc writer, ref immutable Sexpr a) {
	matchSexpr(
		a,
		(ref immutable Arr!Sexpr s) {
			writeChar(writer, '[');
			incrIndent(writer);
			foreach (ref immutable Sexpr element; s.range) {
				newline(writer);
				writeSexprRecur(writer, element);
			}
			dedent(writer);
			writeChar(writer, ']');
		},
		(immutable Bool s) {
			writeStatic(writer, s ? "true" : "false");
		},
		(ref immutable u32 s) {
			writeNat(writer.writer, s);
		},
		(ref immutable SexprNamedRecord s) {
			writeSym(writer.writer, s.name);
			writeChar(writer, '(');
			incrIndent(writer);
			foreach (ref immutable NameAndSexpr element; s.children.range) {
				newline(writer);
				writeSym(writer.writer, element.name);
				writeStatic(writer, ": ");
				writeSexprRecur(writer, element.value);
			}
			dedent(writer);
			writeChar(writer, ')');
		},
		(ref immutable SexprRecord s) {
			writeSym(writer.writer, s.name);
			writeChar(writer, '(');
			incrIndent(writer);
			foreach (ref immutable Sexpr element; s.children.range) {
				newline(writer);
				writeSexprRecur(writer, element);
			}
			dedent(writer);
			writeChar(writer, ')');
		},
		(ref immutable Str s) {
			//TODO: escape inside quotes
			writeChar(writer, '"');
			writeStr(writer, s);
			writeChar(writer, '"');
		},
		(immutable Sym s) {
			writeSym(writer.writer, s);
		},
	);

}
