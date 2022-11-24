module model.parseDiag;

@safe @nogc pure nothrow:

import frontend.parse.lexer : Token;
import util.opt : Opt;
import util.path : Path, PathAndRange, RelPath;
import util.sym : Sym;

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

	private:
	enum Kind {
		cantPrecedeMutEquals,
		cantPrecedeOptEquals,
		circularImport,
		expected,
		fileDoesNotExist,
		fileReadError,
		functionTypeMissingParens,
		importFileTypeNotSupported,
		indentNotDivisible,
		indentTooMuch,
		indentWrongCharacter,
		invalidName,
		invalidStringEscape,
		letMustHaveThen,
		needsBlockCtx,
		relativeImportReachesPastRoot,
		unexpected,
		unexpectedCharacter,
		unexpectedOperator,
		unexpectedToken,
		unionCantBeEmpty,
		whenMustHaveElse,
	}
	immutable Kind kind;
	union {
		immutable CantPrecedeMutEquals cantPrecedeMutEquals;
		immutable CantPrecedeOptEquals cantPrecedeOptEquals;
		immutable CircularImport circularImport;
		immutable Expected expected;
		immutable FileDoesNotExist fileDoesNotExist;
		immutable FileReadError fileReadError;
		immutable FunctionTypeMissingParens functionTypeMissingParens;
		immutable ImportFileTypeNotSupported importFileTypeNotSupported;
		immutable IndentNotDivisible indentNotDivisible;
		immutable IndentTooMuch indentTooMuch;
		immutable IndentWrongCharacter indentWrongCharacter;
		immutable InvalidName invalidName;
		immutable InvalidStringEscape invalidStringEscape;
		immutable LetMustHaveThen letMustHaveThen;
		immutable NeedsBlockCtx needsBlockCtx;
		immutable RelativeImportReachesPastRoot relativeImportReachesPastRoot;
		immutable Unexpected unexpected;
		immutable UnexpectedCharacter unexpectedCharacter;
		immutable UnexpectedOperator unexpectedOperator;
		immutable UnexpectedToken unexpectedToken;
		immutable UnionCantBeEmpty unionCantBeEmpty;
		immutable WhenMustHaveElse whenMustHaveElse;
	}

	public:
	immutable this(immutable CantPrecedeMutEquals a) { kind = Kind.cantPrecedeMutEquals; cantPrecedeMutEquals = a; }
	immutable this(immutable CantPrecedeOptEquals a) { kind = Kind.cantPrecedeOptEquals; cantPrecedeOptEquals = a; }
	@trusted immutable this(immutable CircularImport a) { kind = Kind.circularImport; circularImport = a; }
	immutable this(immutable Expected a) { kind = Kind.expected; expected = a; }
	immutable this(immutable FileDoesNotExist a) { kind = Kind.fileDoesNotExist; fileDoesNotExist = a; }
	immutable this(immutable FileReadError a) { kind = Kind.fileReadError; fileReadError = a; }
	immutable this(immutable FunctionTypeMissingParens a) {
		kind = Kind.functionTypeMissingParens; functionTypeMissingParens = a;
	}
	immutable this(immutable ImportFileTypeNotSupported a) {
		kind = Kind.importFileTypeNotSupported; importFileTypeNotSupported = a;
	}
	immutable this(immutable IndentNotDivisible a) { kind = Kind.indentNotDivisible; indentNotDivisible = a; }
	immutable this(immutable IndentTooMuch a) { kind = Kind.indentTooMuch; indentTooMuch = a; }
	immutable this(immutable IndentWrongCharacter a) { kind = Kind.indentWrongCharacter; indentWrongCharacter = a; }
	@trusted immutable this(immutable InvalidName a) { kind = Kind.invalidName; invalidName = a; }
	immutable this(immutable InvalidStringEscape a) { kind = Kind.invalidStringEscape; invalidStringEscape = a; }
	immutable this(immutable LetMustHaveThen a) { kind = Kind.letMustHaveThen; letMustHaveThen = a; }
	immutable this(immutable NeedsBlockCtx a) {
		kind = Kind.needsBlockCtx; needsBlockCtx = a;
	}
	@trusted immutable this(immutable RelativeImportReachesPastRoot a) {
		kind = Kind.relativeImportReachesPastRoot; relativeImportReachesPastRoot = a;
	}
	immutable this(immutable Unexpected a) { kind = Kind.unexpected; unexpected = a; }
	immutable this(immutable UnexpectedCharacter a) { kind = Kind.unexpectedCharacter; unexpectedCharacter = a; }
	immutable this(immutable UnexpectedOperator a) { kind = Kind.unexpectedOperator; unexpectedOperator = a; }
	immutable this(immutable UnexpectedToken a) { kind = Kind.unexpectedToken; unexpectedToken = a; }
	immutable this(immutable UnionCantBeEmpty a) { kind = Kind.unionCantBeEmpty; unionCantBeEmpty = a; }
	immutable this(immutable WhenMustHaveElse a) { kind = Kind.whenMustHaveElse; whenMustHaveElse = a; }
}
static assert(ParseDiag.sizeof <= 32);

@trusted T matchParseDiag(T)(
	ref immutable ParseDiag a,
	scope T delegate(ref immutable ParseDiag.CantPrecedeMutEquals) @safe @nogc pure nothrow cbCantPrecedeMutEquals,
	scope T delegate(ref immutable ParseDiag.CantPrecedeOptEquals) @safe @nogc pure nothrow cbCantPrecedeOptEquals,
	scope T delegate(ref immutable ParseDiag.CircularImport) @safe @nogc pure nothrow cbCircularImport,
	scope T delegate(ref immutable ParseDiag.Expected) @safe @nogc pure nothrow cbExpected,
	scope T delegate(ref immutable ParseDiag.FileDoesNotExist) @safe @nogc pure nothrow cbFileDoesNotExist,
	scope T delegate(ref immutable ParseDiag.FileReadError) @safe @nogc pure nothrow cbFileReadError,
	scope T delegate(
		ref immutable ParseDiag.FunctionTypeMissingParens
	) @safe @nogc pure nothrow cbFunctionTypeMissingParens,
	scope T delegate(
		ref immutable ParseDiag.ImportFileTypeNotSupported
	) @safe @nogc pure nothrow cbImportFileTypeNotSupported,
	scope T delegate(ref immutable ParseDiag.IndentNotDivisible) @safe @nogc pure nothrow cbIndentNotDivisible,
	scope T delegate(ref immutable ParseDiag.IndentTooMuch) @safe @nogc pure nothrow cbIndentTooMuch,
	scope T delegate(ref immutable ParseDiag.IndentWrongCharacter) @safe @nogc pure nothrow cbIndentWrongCharacter,
	scope T delegate(ref immutable ParseDiag.InvalidName) @safe @nogc pure nothrow cbInvalidName,
	scope T delegate(ref immutable ParseDiag.InvalidStringEscape) @safe @nogc pure nothrow cbInvalidStringEscape,
	scope T delegate(ref immutable ParseDiag.LetMustHaveThen) @safe @nogc pure nothrow cbLetMustHaveThen,
	scope T delegate(ref immutable ParseDiag.NeedsBlockCtx) @safe @nogc pure nothrow cbNeedsBlockCtx,
	scope immutable(T) delegate(
		ref immutable ParseDiag.RelativeImportReachesPastRoot
	) @safe @nogc pure nothrow cbRelativeImportReachesPastRoot,
	scope T delegate(ref immutable ParseDiag.Unexpected) @safe @nogc pure nothrow cbUnexpected,
	scope T delegate(ref immutable ParseDiag.UnexpectedCharacter) @safe @nogc pure nothrow cbUnexpectedCharacter,
	scope T delegate(ref immutable ParseDiag.UnexpectedOperator) @safe @nogc pure nothrow cbUnexpectedOperator,
	scope T delegate(ref immutable ParseDiag.UnexpectedToken) @safe @nogc pure nothrow cbUnexpectedToken,
	scope T delegate(ref immutable ParseDiag.UnionCantBeEmpty) @safe @nogc pure nothrow cbUnionCantBeEmpty,
	scope T delegate(ref immutable ParseDiag.WhenMustHaveElse) @safe @nogc pure nothrow cbWhenMustHaveElse,
) {
	final switch (a.kind) {
		case ParseDiag.Kind.cantPrecedeMutEquals:
			return cbCantPrecedeMutEquals(a.cantPrecedeMutEquals);
		case ParseDiag.Kind.cantPrecedeOptEquals:
			return cbCantPrecedeOptEquals(a.cantPrecedeOptEquals);
		case ParseDiag.Kind.circularImport:
			return cbCircularImport(a.circularImport);
		case ParseDiag.Kind.expected:
			return cbExpected(a.expected);
		case ParseDiag.Kind.fileDoesNotExist:
			return cbFileDoesNotExist(a.fileDoesNotExist);
		case ParseDiag.Kind.fileReadError:
			return cbFileReadError(a.fileReadError);
		case ParseDiag.Kind.functionTypeMissingParens:
			return cbFunctionTypeMissingParens(a.functionTypeMissingParens);
		case ParseDiag.Kind.importFileTypeNotSupported:
			return cbImportFileTypeNotSupported(a.importFileTypeNotSupported);
		case ParseDiag.Kind.indentNotDivisible:
			return cbIndentNotDivisible(a.indentNotDivisible);
		case ParseDiag.Kind.indentTooMuch:
			return cbIndentTooMuch(a.indentTooMuch);
		case ParseDiag.Kind.indentWrongCharacter:
			return cbIndentWrongCharacter(a.indentWrongCharacter);
		case ParseDiag.Kind.invalidName:
			return cbInvalidName(a.invalidName);
		case ParseDiag.Kind.invalidStringEscape:
			return cbInvalidStringEscape(a.invalidStringEscape);
		case ParseDiag.Kind.letMustHaveThen:
			return cbLetMustHaveThen(a.letMustHaveThen);
		case ParseDiag.Kind.needsBlockCtx:
			return cbNeedsBlockCtx(a.needsBlockCtx);
		case ParseDiag.Kind.relativeImportReachesPastRoot:
			return cbRelativeImportReachesPastRoot(a.relativeImportReachesPastRoot);
		case ParseDiag.Kind.unexpected:
			return cbUnexpected(a.unexpected);
		case ParseDiag.Kind.unexpectedCharacter:
			return cbUnexpectedCharacter(a.unexpectedCharacter);
		case ParseDiag.Kind.unexpectedOperator:
			return cbUnexpectedOperator(a.unexpectedOperator);
		case ParseDiag.Kind.unexpectedToken:
			return cbUnexpectedToken(a.unexpectedToken);
		case ParseDiag.Kind.unionCantBeEmpty:
			return cbUnionCantBeEmpty(a.unionCantBeEmpty);
		case ParseDiag.Kind.whenMustHaveElse:
			return cbWhenMustHaveElse(a.whenMustHaveElse);
	}
}
