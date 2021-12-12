module test.testTokens;

@safe @nogc pure nothrow:

import frontend.diagnosticsBuilder : DiagnosticsBuilder;
import frontend.ide.getTokens : reprTokens, Token, tokensOfAst;
import frontend.parse.ast : FileAst, reprAst;
import frontend.parse.parse : parseFile;
import test.testUtil : Test;
import util.collection.arr : emptyArr;
import util.collection.arrUtil : arrEqual, arrLiteral;
import util.collection.str : SafeCStr;
import util.dbg : log;
import util.perf : Perf, withNullPerf;
import util.repr : writeRepr;
import util.sourceRange : FileIndex, RangeWithinFile;
import util.sym : AllSymbols;
import util.util : verifyFail;
import util.writer : finishWriter, Writer, writeStatic;

void testTokens(ref Test test) {
	testOne(test, immutable SafeCStr(""), emptyArr!Token);

	debug {
		import core.stdc.stdio : printf;
		printf("testSource2 IS %s\n", testSource2.ptr);
	}

	testOne(test, testSource, arrLiteral!Token(test.alloc, [
		immutable Token(Token.Kind.keyword, immutable RangeWithinFile(0, 6)),
		immutable Token(Token.Kind.importPath, immutable RangeWithinFile(8, 10)),
		immutable Token(Token.Kind.funDef, immutable RangeWithinFile(12, 16)),
		immutable Token(Token.Kind.structRef, immutable RangeWithinFile(17, 20)),
		immutable Token(Token.Kind.structRef, immutable RangeWithinFile(21, 30)),
		immutable Token(Token.Kind.paramDef, immutable RangeWithinFile(31, 35)),
		immutable Token(Token.Kind.structRef, immutable RangeWithinFile(36, 39)),
		immutable Token(Token.Kind.structRef, immutable RangeWithinFile(40, 43)),
		immutable Token(Token.Kind.literalNumber, immutable RangeWithinFile(53, 55)),
		immutable Token(Token.Kind.funRef, immutable RangeWithinFile(55, 63))]));

	testOne(test, testSource2, arrLiteral!Token(test.alloc, [
		immutable Token(Token.Kind.funDef, immutable RangeWithinFile(0, 1)),
		immutable Token(Token.Kind.structRef, immutable RangeWithinFile(2, 5)),
		immutable Token(Token.Kind.paramDef, immutable RangeWithinFile(6, 7)),
		immutable Token(Token.Kind.structRef, immutable RangeWithinFile(7, 12)),
		immutable Token(Token.Kind.literalNumber, immutable RangeWithinFile(15, 16))]));
}

private:

void testOne(ref Test test, immutable SafeCStr source, immutable Token[] expectedTokens) {
	AllSymbols allSymbols = AllSymbols(test.allocPtr);
	DiagnosticsBuilder diags = DiagnosticsBuilder();
	immutable FileAst ast = withNullPerf!(
		immutable FileAst,
		(scope ref Perf perf) => parseFile(
			test.alloc,
			perf,
			test.allPaths,
			allSymbols,
			diags,
			immutable FileIndex(0),
			source));
	immutable Token[] tokens = tokensOfAst(test.alloc, ast);
	if (!tokensEq(tokens, expectedTokens)) {
		Writer writer = Writer(test.allocPtr);
		writeStatic(writer, "expected tokens:\n");
		writeRepr(writer, reprTokens(test.alloc, expectedTokens));
		writeStatic(writer, "\nactual tokens:\n");
		writeRepr(writer, reprTokens(test.alloc, tokens));

		writeStatic(writer, "\n\n(hint: ast is:)\n");
		writeRepr(writer, reprAst(test.alloc, test.allPaths, ast));
		log(test.dbg, finishWriter(writer));
		verifyFail();
	}
}

immutable(bool) tokensEq(ref immutable Token[] a, ref immutable Token[] b) {
	return arrEqual!Token(a, b, (ref immutable Token x, ref immutable Token y) =>
		tokenEq(x, y));
}

immutable(bool) tokenEq(ref immutable Token a, ref immutable Token b) {
	return a.kind == b.kind && rangeEq(a.range, b.range);
}

immutable(bool) rangeEq(ref immutable RangeWithinFile a, ref immutable RangeWithinFile b) {
	return a.start == b.start && a.end == b.end;
}

immutable SafeCStr testSource = immutable SafeCStr(`import
	io

main fut exit-code(args arr str) summon
	0 resolved
`);

immutable SafeCStr testSource2 = immutable SafeCStr(`f nat(a^ nat)
	0`);
