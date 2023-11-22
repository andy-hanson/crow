module model.parseDiag;

@safe @nogc pure nothrow:

import frontend.parse.lexer : Token;
import util.sourceRange : Range;
import util.storage : ReadFileIssue;
import util.sym : Sym;
import util.union_ : Union;
import util.uri : RelPath;

immutable struct ParseDiagnostic {
	Range range;
	ParseDiag kind;
}

immutable struct ParseDiag {
	@safe @nogc pure nothrow:
	immutable struct Expected {
		enum Kind {
			afterMut,
			blockCommentEnd,
			closeInterpolated,
			closingBracket,
			closingParen,
			colon,
			comma,
			dedent,
			endOfLine,
			equals,
			indent,
			lambdaArrow,
			less,
			literalIntOrNat,
			literalNat,
			modifier,
			name,
			nameOrOperator,
			newline,
			newlineOrDedent,
			openParen,
			questionEqual,
			quoteDouble,
			quoteDouble3,
			slash,
			then,
			typeArgsEnd,
		}
		Kind kind;
	}
	immutable struct FunctionTypeMissingParens {}
	immutable struct ImportFileTypeNotSupported {}
	immutable struct IndentNotDivisible {
		uint nSpaces;
		uint nSpacesPerIndent;
	}
	immutable struct IndentTooMuch {}
	immutable struct IndentWrongCharacter {
		bool expectedTabs;
	}
	immutable struct InvalidName {
		string actual;
	}
	immutable struct InvalidStringEscape {
		char actual;
	}
	immutable struct NeedsBlockCtx {
		enum Kind {
			break_,
			for_,
			if_,
			match,
			lambda,
			loop,
			throw_,
			trusted,
			unless,
			until,
			while_,
			with_,
		}
		Kind kind;
	}
	immutable struct RelativeImportReachesPastRoot {
		RelPath imported;
	}
	immutable struct TrailingComma {}
	immutable struct UnexpectedCharacter {
		char ch;
	}
	immutable struct UnexpectedOperator {
		Sym operator;
	}
	immutable struct UnexpectedToken {
		Token token;
	}
	immutable struct WhenMustHaveElse {}

	mixin Union!(
		Expected,
		FunctionTypeMissingParens,
		ImportFileTypeNotSupported,
		IndentNotDivisible,
		IndentTooMuch,
		IndentWrongCharacter,
		InvalidName,
		InvalidStringEscape,
		NeedsBlockCtx,
		ReadFileIssue,
		RelativeImportReachesPastRoot,
		TrailingComma,
		UnexpectedCharacter,
		UnexpectedOperator,
		UnexpectedToken,
		WhenMustHaveElse);
}
static assert(ParseDiag.sizeof <= 32);
