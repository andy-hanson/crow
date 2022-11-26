module model.parseDiag;

@safe @nogc pure nothrow:

import frontend.parse.lexer : Token;
import util.opt : Opt;
import util.path : Path, PathAndRange, RelPath;
import util.sym : Sym;
import util.union_ : Union;

struct ParseDiag {
	@safe @nogc pure nothrow:
	struct CantPrecedeMutEquals {}
	struct CantPrecedeOptEquals {}
	struct CircularImport {
		immutable Path from;
		immutable Path to;
	}
	struct Expected {
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
		immutable Kind kind;
	}
	struct FileDoesNotExist {
		immutable Opt!PathAndRange importedFrom;
	}
	struct FileReadError {
		immutable Opt!PathAndRange importedFrom;
	}
	struct FunctionTypeMissingParens {}
	struct ImportFileTypeNotSupported {}
	struct IndentNotDivisible {
		immutable uint nSpaces;
		immutable uint nSpacesPerIndent;
	}
	struct IndentTooMuch {}
	struct IndentWrongCharacter {
		immutable bool expectedTabs;
	}
	struct InvalidName {
		immutable string actual;
	}
	struct InvalidStringEscape {
		immutable char actual;
	}
	struct LetMustHaveThen {}
	struct NeedsBlockCtx {
		enum Kind {
			break_,
			for_,
			if_,
			match,
			lambda,
			loop,
			unless,
			until,
			while_,
			with_,
		}
		immutable Kind kind;
	}
	struct RelativeImportReachesPastRoot {
		immutable RelPath imported;
	}
	//TODO:KILL, always use UnexpectedToken
	struct Unexpected {
		enum Kind {
			dedent,
			indent,
		}
		immutable Kind kind;
	}
	struct UnexpectedCharacter {
		immutable char ch;
	}
	struct UnexpectedOperator {
		immutable Sym operator;
	}
	struct UnexpectedToken {
		immutable Token token;
	}
	struct UnionCantBeEmpty {}
	struct WhenMustHaveElse {}

	mixin Union!(
		immutable CantPrecedeMutEquals,
		immutable CantPrecedeOptEquals,
		immutable CircularImport,
		immutable Expected,
		immutable FileDoesNotExist,
		immutable FileReadError,
		immutable FunctionTypeMissingParens,
		immutable ImportFileTypeNotSupported,
		immutable IndentNotDivisible,
		immutable IndentTooMuch,
		immutable IndentWrongCharacter,
		immutable InvalidName,
		immutable InvalidStringEscape,
		immutable LetMustHaveThen,
		immutable NeedsBlockCtx,
		immutable RelativeImportReachesPastRoot,
		immutable Unexpected,
		immutable UnexpectedCharacter,
		immutable UnexpectedOperator,
		immutable UnexpectedToken,
		immutable UnionCantBeEmpty,
		immutable WhenMustHaveElse);
}
static assert(ParseDiag.sizeof <= 32);
