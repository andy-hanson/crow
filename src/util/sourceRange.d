module util.sourceRange;

@safe @nogc pure nothrow:

import util.collection.arrUtil : arrLiteral;
import util.sexpr : Sexpr, tataNat, tataRecord;
import util.types : u32;

alias Pos = u32;

struct SourceRange {
	immutable Pos start;
	immutable Pos end;

	static immutable SourceRange empty = SourceRange(Pos(0), Pos(0));
}

immutable(Sexpr) sexprOfSourceRange(Alloc)(ref Alloc alloc, immutable SourceRange a) {
	return tataRecord(alloc, "range", tataNat(a.start), tataNat(a.end));
}
