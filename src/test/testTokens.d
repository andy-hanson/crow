module test.testTokens;

@safe @nogc pure nothrow:

import frontend.diagnosticsBuilder : DiagnosticsBuilder, DiagnosticsBuilderForFile;
import frontend.ide.getTokens : jsonOfTokens, Token, tokensOfAst;
import frontend.parse.ast : FileAst;
import frontend.parse.jsonOfAst : jsonOfAst;
import frontend.parse.parse : parseFile;
import test.testUtil : Test;
import util.col.arrUtil : arrEqual, arrLiteral;
import util.col.str : SafeCStr, safeCStr;
import util.json : writeJson;
import util.perf : Perf, withNullPerf;
import util.sourceRange : RangeWithinFile;
import util.uri : parseUri;
import util.util : verifyFail;
import util.writer : debugLogWithWriter, Writer;

void testTokens(ref Test test) {
	testOne(test, safeCStr!"", []);

	testOne(test, testSource, arrLiteral!Token(test.alloc, [
		Token(Token.Kind.keyword, RangeWithinFile(0, 6)),
		Token(Token.Kind.importPath, RangeWithinFile(8, 10)),
		Token(Token.Kind.fun, RangeWithinFile(12, 16)),
		Token(Token.Kind.struct_, RangeWithinFile(17, 26)),
		Token(Token.Kind.keyword, RangeWithinFile(26, 27)),
		Token(Token.Kind.param, RangeWithinFile(28, 32)),
		Token(Token.Kind.struct_, RangeWithinFile(33, 36)),
		Token(Token.Kind.keyword, RangeWithinFile(36, 38)),
		Token(Token.Kind.modifier, RangeWithinFile(40, 46)),
		Token(Token.Kind.literalNumber, RangeWithinFile(48, 50)),
		Token(Token.Kind.fun, RangeWithinFile(50, 58))]));

	testOne(test, testSource2, arrLiteral!Token(test.alloc, [
		Token(Token.Kind.fun, RangeWithinFile(0, 1)),
		Token(Token.Kind.struct_, RangeWithinFile(2, 5)),
		Token(Token.Kind.param, RangeWithinFile(6, 7)),
		Token(Token.Kind.struct_, RangeWithinFile(9, 12)),
		Token(Token.Kind.literalNumber, RangeWithinFile(15, 16))]));
}

private:

void testOne(ref Test test, SafeCStr source, Token[] expectedTokens) {
	DiagnosticsBuilder diags = DiagnosticsBuilder(test.allocPtr);
	DiagnosticsBuilderForFile diagsForFile = DiagnosticsBuilderForFile(
		&diags, parseUri(test.allUris, "magic:test.crow"));
	FileAst ast = withNullPerf!(FileAst, (scope ref Perf perf) =>
		parseFile(test.alloc, perf, test.allSymbols, test.allUris, diagsForFile, source));
	Token[] tokens = tokensOfAst(test.alloc, test.allSymbols, ast);
	if (!arrEqual(tokens, expectedTokens)) {
		debugLogWithWriter((ref Writer writer) {
			writer ~= "expected tokens:\n";
			writeJson(writer, test.allSymbols, jsonOfTokens(test.alloc, expectedTokens));
			writer ~= "\nactual tokens:\n";
			writeJson(writer, test.allSymbols, jsonOfTokens(test.alloc, tokens));

			writer ~= "\n\n(hint: ast is:)\n";
			writeJson(writer, test.allSymbols, jsonOfAst(test.alloc, test.allUris, ast));
		});
		verifyFail();
	}
}

SafeCStr testSource() => safeCStr!`import
	io

main exit-code^(args str[]) summon
	0 resolved
`;

SafeCStr testSource2() => safeCStr!`f nat(a^ nat)
	0`;
