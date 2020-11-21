module test.testTokens;

@safe @nogc pure nothrow:

import frontend.parse : FileAstAndParseDiagnostics, parseFile;
import frontend.getTokens : sexprOfTokens, Token, tokensOfAst;
import test.testUtil : Test;
import util.bools : Bool;
import util.collection.arr : Arr;
import util.collection.arrUtil : arrEqual, arrLiteral;
import util.collection.str : Str, strLiteral, strToNulTerminatedStr;
import util.sexpr : writeSexpr;
import util.sourceRange : RangeWithinFile;
import util.sym : AllSymbols;
import util.util : verify, verifyFail;
import util.writer : finishWriter, Writer, writeStatic;

void testTokens(Alloc)(ref Test!Alloc test) {
	AllSymbols!Alloc allSymbols = AllSymbols!Alloc(test.alloc);
	immutable FileAstAndParseDiagnostics ast = parseFile(
		test.alloc,
		allSymbols,
		strToNulTerminatedStr(test.alloc, strLiteral(testSource)));
	immutable Arr!Token tokens = tokensOfAst(test.alloc, ast.ast);

	immutable Arr!Token expectedTokens = arrLiteral!Token(
		test.alloc,
		immutable Token(Token.Kind.keyword, immutable RangeWithinFile(0, 6)),
		immutable Token(Token.Kind.importPath, immutable RangeWithinFile(8, 10)),
		immutable Token(Token.Kind.funDef, immutable RangeWithinFile(12, 16)),
		immutable Token(Token.Kind.structRef, immutable RangeWithinFile(17, 20)),
		immutable Token(Token.Kind.structRef, immutable RangeWithinFile(21, 30)),
		immutable Token(Token.Kind.paramDef, immutable RangeWithinFile(31, 35)),
		immutable Token(Token.Kind.structRef, immutable RangeWithinFile(36, 39)),
		immutable Token(Token.Kind.structRef, immutable RangeWithinFile(40, 43)),
		immutable Token(Token.Kind.literalNumber, immutable RangeWithinFile(53, 54)),
		immutable Token(Token.Kind.funRef, immutable RangeWithinFile(55, 63)),
		);
	if (!tokensEq(tokens, expectedTokens)) {
		Writer!Alloc writer = Writer!Alloc(test.alloc);
		writeStatic(writer, "expected tokens:\n");
		writeSexpr(writer, sexprOfTokens(test.alloc, expectedTokens));
		writeStatic(writer, "\nactual tokens:\n");
		writeSexpr(writer, sexprOfTokens(test.alloc, tokens));
		immutable Str s = finishWriter(writer);
		debug {
			import core.stdc.stdio : printf;
			import util.collection.arr : begin, size;
			printf("%.*s\n", cast(int) size(s), begin(s));
		}
		verifyFail();
	}
}

private:

immutable(Bool) tokensEq(immutable Arr!Token a, immutable Arr!Token b) {
	return arrEqual!Token(a, b, (ref immutable Token x, ref immutable Token y) =>
		immutable Bool(x == y));
}

immutable string testSource = `import
	io

main fut exit-code(args arr str) summon
	0 resolved
`;
