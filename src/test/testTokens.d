module test.testTokens;

@safe @nogc pure nothrow:

import frontend.ide.getTokens : sexprOfTokens, Token, tokensOfAst;
import frontend.parse.ast : sexprOfAst;
import frontend.parse.parse : FileAstAndParseDiagnostics, parseFile;
import test.testUtil : Test;
import util.bools : Bool;
import util.collection.arr : Arr, emptyArr;
import util.collection.arrUtil : arrEqual, arrLiteral;
import util.collection.str : copyToNulTerminatedStr, Str, strLiteral;
import util.dbg : log;
import util.sexpr : writeSexpr;
import util.sourceRange : RangeWithinFile;
import util.sym : AllSymbols;
import util.util : verifyFail;
import util.writer : finishWriter, Writer, writeStatic;

void testTokens(Debug, Alloc)(ref Test!(Debug, Alloc) test) {
	testOne(test, "", emptyArr!Token);

	testOne(test, testSource, arrLiteral!Token(test.alloc, [
		immutable Token(Token.Kind.keyword, immutable RangeWithinFile(0, 6)),
		immutable Token(Token.Kind.importPath, immutable RangeWithinFile(8, 10)),
		immutable Token(Token.Kind.funDef, immutable RangeWithinFile(12, 16)),
		immutable Token(Token.Kind.structRef, immutable RangeWithinFile(17, 20)),
		immutable Token(Token.Kind.structRef, immutable RangeWithinFile(21, 30)),
		immutable Token(Token.Kind.paramDef, immutable RangeWithinFile(31, 35)),
		immutable Token(Token.Kind.structRef, immutable RangeWithinFile(36, 39)),
		immutable Token(Token.Kind.structRef, immutable RangeWithinFile(40, 43)),
		immutable Token(Token.Kind.literalNumber, immutable RangeWithinFile(53, 54)),
		immutable Token(Token.Kind.funRef, immutable RangeWithinFile(55, 63))]));

	testOne(test, testSource2, arrLiteral!Token(test.alloc, [
		immutable Token(Token.Kind.funDef, immutable RangeWithinFile(0, 1)),
		immutable Token(Token.Kind.structRef, immutable RangeWithinFile(2, 5)),
		immutable Token(Token.Kind.paramDef, immutable RangeWithinFile(6, 7)),
		immutable Token(Token.Kind.structRef, immutable RangeWithinFile(7, 7)),
		immutable Token(Token.Kind.structRef, immutable RangeWithinFile(9, 12)),
		immutable Token(Token.Kind.literalNumber, immutable RangeWithinFile(15, 16))]));
}

private:

void testOne(Debug, Alloc)(ref Test!(Debug, Alloc) test, immutable string source, immutable Arr!Token expectedTokens) {
	AllSymbols!Alloc allSymbols = AllSymbols!Alloc(test.alloc);
	immutable Str sourceStr = strLiteral(source);
	immutable FileAstAndParseDiagnostics ast = parseFile(
		test.alloc,
		test.allPaths,
		allSymbols,
		copyToNulTerminatedStr(test.alloc, sourceStr));
	immutable Arr!Token tokens = tokensOfAst(test.alloc, ast.ast);
	if (!tokensEq(tokens, expectedTokens)) {
		Writer!Alloc writer = Writer!Alloc(test.alloc);
		writeStatic(writer, "expected tokens:\n");
		writeSexpr(writer, sexprOfTokens(test.alloc, expectedTokens));
		writeStatic(writer, "\nactual tokens:\n");
		writeSexpr(writer, sexprOfTokens(test.alloc, tokens));

		writeStatic(writer, "\n\n(hint: ast is:)\n");
		writeSexpr(writer, sexprOfAst(test.alloc, test.allPaths, ast.ast));
		log(test.dbg, finishWriter(writer));
		verifyFail();
	}
}

immutable(Bool) tokensEq(ref immutable Arr!Token a, ref immutable Arr!Token b) {
	return arrEqual!Token(a, b, (ref immutable Token x, ref immutable Token y) =>
		tokenEq(x, y));
}

immutable(Bool) tokenEq(ref immutable Token a, ref immutable Token b) {
	return immutable Bool(a.kind == b.kind && rangeEq(a.range, b.range));
}

immutable(Bool) rangeEq(ref immutable RangeWithinFile a, ref immutable RangeWithinFile b) {
	return immutable Bool(a.start == b.start && a.end == b.end);
}

immutable string testSource = `import
	io

main fut exit-code(args arr str) summon
	0 resolved
`;

immutable string testSource2 = `f nat(aA nat)
	0`;
