module util.sexpr;

@safe @nogc pure nothrow:

import util.collection.arr : Arr;
import util.collection.str : Str;
import util.sym : Sym;

struct SexprRecord {
	immutable Sym name;
	immutable Arr!Sexpr children;
}

struct Sexpr {
	private:
	enum Kind {
		arr,
		record,
		str,
		symbol,
	}
	immutable Kind kind;
	union {
		immutable Arr!Sexpr arr;
		immutable SexprRecord record;
		immutable Str str;
		immutable Sym symbol;
	}

	public:
	@trusted this(immutable Arr!Sexpr a) { kind = Kind.arr; arr = a; }
	@trusted this(immutable SexprRecord a) { kind = Kind.record; record = a; }
	@trusted this(immutable Str a) { kind = Kind.str; str = a; }
	this(immutable Sym a) { kind = Kind.symbol; symbol = a; }
}

T match(T)(
	ref immutable Sexpr a,
	scope T delegate(ref immutable Arr!Sexpr) @safe @nogc pure nothrow cbArr,
	scope T delegate(ref immutable SexprRecord) @safe @nogc pure nothrow cbRecord,
	scope T delegate(ref immutable Str) @safe @nogc pure nothrow cbStr,
	scope T delegate(immutable Sym) @safe @nogc pure nothrow cbSym,
) {
	final switch (a.kind) {
		case Sexpr.Kind.arr:
			return cbArr(a.arr);
		case Sexpr.Kind.record:
			return cbRecord(a.record);
		case Sexpr.Kind.str:
			return cbStr(a.str);
		case Sexpr.Kind.symbol:
			return cbSymbol(a.symbol);
	}
}

immutable(Sexpr) arrToSexpr(Alloc)(ref Alloc alloc, ref immutable Arr!T a, scope Sexpr delegate(ref immutable T) @safe @nogc pure nothrow cbToSexpr) {
	return Sexpr(map!(const Sexpr)(alloc, a, cbToSexpr));
}

void writeSexpr(Alloc)(ref Writer!Alloc writer, ref immutable Sexpr a) {
	s.match(
		(ref immutable Arr!Sexpr s) {
			writer.writeChar('[');
			writer.writeWithCommas(s, (ref immutable Sexpr element) {
				writer.writeSexpr(element);
			});
			writer.writeChar(']');
		},
		(ref immutable SexprRecord s) {
			writer.writeSym(s.name);
			writer.writeChar('(');
			writer.writeWithCommas(writer, s.children, (ref immutable Sexpr element) {
				writer.writeSexpr(element);
			});
			writer.writeChar(')');
		},
		(ref immutable Str s) {
			//TODO: escape inside quotes
			writer.writeChar('"');
			writer.writeStr(s);
			writer.writeChar('"');
		},
		(immutable Sym s) {
			writer.writeSym(s);
		},
	);
}
