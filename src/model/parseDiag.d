module model.parseDiag;

@safe @nogc pure nothrow:

import frontend.parse.lexer : Token;
import model.diag : ReadFileDiag;
import util.sourceRange : Range;
import util.symbol : Symbol;
import util.union_ : Union;

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
			namedArgument,
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
	immutable struct MissingExpression {}
	immutable struct NeedsBlockCtx {
		enum Kind {
			break_,
			do_,
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
	immutable struct TrailingComma {}
	immutable struct UnexpectedCharacter {
		char character;
	}
	immutable struct UnexpectedOperator {
		Symbol operator;
	}
	immutable struct UnexpectedToken {
		Token token;
	}

	mixin Union!(
		Expected,
		FunctionTypeMissingParens,
		ImportFileTypeNotSupported,
		IndentNotDivisible,
		IndentTooMuch,
		IndentWrongCharacter,
		InvalidName,
		InvalidStringEscape,
		MissingExpression,
		NeedsBlockCtx,
		ReadFileDiag,
		TrailingComma,
		UnexpectedCharacter,
		UnexpectedOperator,
		UnexpectedToken);
}
static assert(ParseDiag.sizeof <= 32);
