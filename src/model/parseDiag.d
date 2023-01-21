module model.parseDiag;

@safe @nogc pure nothrow:

import frontend.parse.lexer : Token;
import util.opt : Opt;
import util.path : Path, PathAndRange, RelPath;
import util.sym : Sym;
import util.union_ : Union;

immutable struct ParseDiag {
	@safe @nogc pure nothrow:
	immutable struct CantPrecedeOptEquals {}
	immutable struct CircularImport {
		Path from;
		Path to;
	}
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
			name,
			nameOrOperator,
			openParen,
			quoteDouble,
			quoteDouble3,
			slash,
			then,
			typeArgsEnd,
		}
		Kind kind;
	}
	immutable struct FileDoesNotExist {
		Opt!PathAndRange importedFrom;
	}
	immutable struct FileReadError {
		Opt!PathAndRange importedFrom;
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
	immutable struct LetMustHaveThen {}
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
	//TODO:KILL, always use UnexpectedToken
	immutable struct Unexpected {
		enum Kind {
			dedent,
			indent,
		}
		Kind kind;
	}
	immutable struct UnexpectedCharacter {
		char ch;
	}
	immutable struct UnexpectedOperator {
		Sym operator;
	}
	immutable struct UnexpectedToken {
		Token token;
	}
	immutable struct UnionCantBeEmpty {}
	immutable struct WhenMustHaveElse {}

	mixin Union!(
		CantPrecedeOptEquals,
		CircularImport,
		Expected,
		FileDoesNotExist,
		FileReadError,
		FunctionTypeMissingParens,
		ImportFileTypeNotSupported,
		IndentNotDivisible,
		IndentTooMuch,
		IndentWrongCharacter,
		InvalidName,
		InvalidStringEscape,
		LetMustHaveThen,
		NeedsBlockCtx,
		RelativeImportReachesPastRoot,
		Unexpected,
		UnexpectedCharacter,
		UnexpectedOperator,
		UnexpectedToken,
		UnionCantBeEmpty,
		WhenMustHaveElse);
}
static assert(ParseDiag.sizeof <= 32);
