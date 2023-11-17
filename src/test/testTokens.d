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
import util.lineAndColumnGetter : LineAndColumnGetter, lineAndColumnGetterForText;
import util.perf : Perf, withNullPerf;
import util.sourceRange : Range;
import util.uri : parseUri;
import util.util : verifyFail;
import util.writer : debugLogWithWriter, Writer;

void testTokens(ref Test test) {
	testOne(test, safeCStr!"", []);

	testOne(test, testSource, arrLiteral!Token(test.alloc, [
		Token(Token.Kind.keyword, Range(0, 6)),
		Token(Token.Kind.importPath, Range(8, 10)),
		Token(Token.Kind.fun, Range(12, 16)),
		Token(Token.Kind.struct_, Range(17, 26)),
		Token(Token.Kind.keyword, Range(26, 27)),
		Token(Token.Kind.param, Range(28, 32)),
		Token(Token.Kind.struct_, Range(33, 36)),
		Token(Token.Kind.keyword, Range(36, 38)),
		Token(Token.Kind.modifier, Range(40, 46)),
		Token(Token.Kind.literalNumber, Range(48, 49)),
		Token(Token.Kind.fun, Range(50, 58))]));

	testOne(test, testSource2, arrLiteral!Token(test.alloc, [
		Token(Token.Kind.fun, Range(0, 1)),
		Token(Token.Kind.struct_, Range(2, 5)),
		Token(Token.Kind.param, Range(6, 7)),
		Token(Token.Kind.struct_, Range(9, 12)),
		Token(Token.Kind.literalNumber, Range(15, 16))]));
}

private:

void testOne(ref Test test, SafeCStr source, Token[] expectedTokens) {
	DiagnosticsBuilder diags = DiagnosticsBuilder(test.allocPtr);
	DiagnosticsBuilderForFile diagsForFile = DiagnosticsBuilderForFile(
		&diags, parseUri(test.allUris, "magic:test.crow"));
	FileAst ast = withNullPerf!(FileAst, (scope ref Perf perf) =>
		parseFile(test.alloc, perf, test.allSymbols, test.allUris, diagsForFile, source));
	Token[] tokens = tokensOfAst(test.alloc, test.allSymbols, test.allUris, ast);
	if (!arrEqual(tokens, expectedTokens)) {
		debugLogWithWriter((ref Writer writer) {
			LineAndColumnGetter lcg = lineAndColumnGetterForText(test.alloc, source);
			writer ~= "expected tokens:\n";
			writeJson(writer, test.allSymbols, jsonOfTokens(test.alloc, lcg, expectedTokens));
			writer ~= "\nactual tokens:\n";
			writeJson(writer, test.allSymbols, jsonOfTokens(test.alloc, lcg, tokens));

			writer ~= "\n\n(hint: ast is:)\n";
			writeJson(writer, test.allSymbols, jsonOfAst(test.alloc, test.allUris, lcg, ast));
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
