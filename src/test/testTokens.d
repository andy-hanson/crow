module test.testTokens;

@safe @nogc pure nothrow:

import frontend.ide.getTokens : reprTokens, Token, tokensOfAst;
import frontend.parse.ast : FileAst, reprAst;
import frontend.parse.parse : parseFile;
import model.diag : DiagnosticWithinFile;
import test.testUtil : Test;
import util.col.arrBuilder : ArrBuilder;
import util.col.arrUtil : arrEqual, arrLiteral;
import util.col.str : SafeCStr, safeCStr;
import util.perf : Perf, withNullPerf;
import util.repr : writeReprJSON;
import util.sourceRange : RangeWithinFile;
import util.sym : AllSymbols;
import util.util : verifyFail;
import util.writer : finishWriterToSafeCStr, Writer, writeStatic;

void testTokens(ref Test test) {
	testOne(test, safeCStr!"", []);

	testOne(test, testSource, arrLiteral!Token(test.alloc, [
		immutable Token(Token.Kind.keyword, immutable RangeWithinFile(0, 6)),
		immutable Token(Token.Kind.importPath, immutable RangeWithinFile(8, 10)),
		immutable Token(Token.Kind.fun, immutable RangeWithinFile(12, 16)),
		immutable Token(Token.Kind.struct_, immutable RangeWithinFile(17, 20)),
		immutable Token(Token.Kind.struct_, immutable RangeWithinFile(21, 30)),
		immutable Token(Token.Kind.param, immutable RangeWithinFile(31, 35)),
		immutable Token(Token.Kind.struct_, immutable RangeWithinFile(36, 39)),
		immutable Token(Token.Kind.struct_, immutable RangeWithinFile(40, 43)),
		immutable Token(Token.Kind.modifier, immutable RangeWithinFile(45, 51)),
		immutable Token(Token.Kind.literalNumber, immutable RangeWithinFile(53, 55)),
		immutable Token(Token.Kind.fun, immutable RangeWithinFile(55, 63))]));

	testOne(test, testSource2, arrLiteral!Token(test.alloc, [
		immutable Token(Token.Kind.fun, immutable RangeWithinFile(0, 1)),
		immutable Token(Token.Kind.struct_, immutable RangeWithinFile(2, 5)),
		immutable Token(Token.Kind.param, immutable RangeWithinFile(6, 7)),
		immutable Token(Token.Kind.struct_, immutable RangeWithinFile(7, 12)),
		immutable Token(Token.Kind.literalNumber, immutable RangeWithinFile(15, 16))]));
}

private:

void testOne(ref Test test, immutable SafeCStr source, immutable Token[] expectedTokens) {
	AllSymbols allSymbols = AllSymbols(test.allocPtr);
	ArrBuilder!DiagnosticWithinFile diags;
	immutable FileAst ast = withNullPerf!(
		immutable FileAst,
		(scope ref Perf perf) => parseFile(
			test.alloc,
			perf,
			test.allPaths,
			allSymbols,
			diags,
			source));
	immutable Token[] tokens = tokensOfAst(test.alloc, allSymbols, ast);
	if (!tokensEq(tokens, expectedTokens)) {
		debug {
			import core.stdc.stdio : printf;
			Writer writer = Writer(test.allocPtr);
			writeStatic(writer, "expected tokens:\n");
			writeReprJSON(writer, allSymbols, reprTokens(test.alloc, expectedTokens));
			writeStatic(writer, "\nactual tokens:\n");
			writeReprJSON(writer, allSymbols, reprTokens(test.alloc, tokens));

			writeStatic(writer, "\n\n(hint: ast is:)\n");
			writeReprJSON(writer, allSymbols, reprAst(test.alloc, test.allPaths, ast));
			printf("%s\n", finishWriterToSafeCStr(writer).ptr);
		}
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

immutable SafeCStr testSource = safeCStr!`import
	io

main fut exit-code(args arr str) summon
	0 resolved
`;

immutable SafeCStr testSource2 = safeCStr!`f nat(a^ nat)
	0`;
