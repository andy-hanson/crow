module util.sexpr;

@safe @nogc pure nothrow:

import util.bools : Bool;
import util.collection.arr : Arr, range;
import util.collection.str : Str;
import util.memory : allocate;
import util.opt : force, has, Opt;
import util.ptr : Ptr, ptrTrustMe_mut;
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
		immutable u32 nat;
		immutable Opt!(Ptr!Sexpr) opt;
		immutable SexprRecord record;
		immutable Str str;
		immutable Sym symbol;
	}

	public:
	@trusted this(immutable Arr!Sexpr a) immutable { kind = Kind.arr; arr = a; }
	this(immutable Bool a) immutable { kind = Kind.bool_; bool_ = a; }
	@trusted this(immutable SexprNamedRecord a) immutable { kind = Kind.namedRecord; namedRecord = a; }
	@trusted this(immutable u32 a) immutable { kind = Kind.nat; nat = a; }
	@trusted this(immutable Opt!(Ptr!Sexpr) a) immutable { kind = Kind.opt; opt = a; }
	@trusted this(immutable SexprRecord a) immutable { kind = Kind.record; record = a; }
	@trusted this(immutable Str a) immutable { kind = Kind.str; str = a; }
	this(immutable Sym a) immutable { kind = Kind.symbol; symbol = a; }
}

@trusted T matchSexpr(T)(
	ref immutable Sexpr a,
	scope T delegate(ref immutable Arr!Sexpr) @safe @nogc pure nothrow cbArr,
	scope T delegate(immutable Bool) @safe @nogc pure nothrow cbBool,
	scope T delegate(ref immutable u32) @safe @nogc pure nothrow cbNat,
	scope T delegate(ref immutable SexprNamedRecord) @safe @nogc pure nothrow cbNamedRecord,
	scope T delegate(ref immutable Opt!(Ptr!Sexpr)) @safe @nogc pure nothrow cbOpt,
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

immutable(Sexpr) arrToSexpr(Alloc)(ref Alloc alloc, ref immutable Arr!T a, scope Sexpr delegate(ref immutable T) @safe @nogc pure nothrow cbToSexpr) {
	return Sexpr(map!(const Sexpr)(alloc, a, cbToSexpr));
}

void writeSexpr(Alloc)(ref WriterWithIndent!Alloc writer, ref immutable Sexpr a) {
	matchSexpr(
		a,
		(ref immutable Arr!Sexpr s) {
			writeChar(writer, '[');
			incrIndent(writer);
			foreach (ref immutable Sexpr element; s.range) {
				newline(writer);
				writeSexpr(writer, element);
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
				writeSexpr(writer, element.value);
			}
			dedent(writer);
			writeChar(writer, ')');
		},
		(ref immutable Opt!(Ptr!Sexpr) s) {
			if (has(s)) {
				writeStatic(writer, "some(");
				writeSexpr(writer, force(s).deref);
				writeChar(writer, ')');
			} else
				writeStatic(writer, "none");
		},
		(ref immutable SexprRecord s) {
			writeSym(writer.writer, s.name);
			writeChar(writer, '(');
			incrIndent(writer);
			foreach (ref immutable Sexpr element; s.children.range) {
				newline(writer);
				writeSexpr(writer, element);
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
