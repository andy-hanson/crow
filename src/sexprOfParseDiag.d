module sexprOfParseDiag;

@safe @nogc pure nothrow:

import parseDiag : ParseDiag, ParseDiagnostic;
import util.sexpr : Sexpr, tataRecord;
import util.sourceRange : sexprOfSourceRange;
import util.util : todo;

immutable(Sexpr) sexprOfParseDiagnostic(Alloc)(ref Alloc alloc, ref immutable ParseDiagnostic a) {
	return tataRecord(alloc, "diagnostic",
		sexprOfSourceRange(alloc, a.range),
		sexprOfParseDiag(alloc, a.diag));
}

immutable(Sexpr) sexprOfParseDiag(Alloc)(ref Alloc alloc, ref immutable ParseDiag d) {
	return todo!(immutable Sexpr)("sexprOfParseDiag");
}
