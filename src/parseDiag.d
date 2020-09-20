module parseDiag;

@safe @nogc pure nothrow:

import util.bools : Bool;
import util.sourceRange : SourceRange;
import util.sym : Sym;
import util.types : u32;

struct ParseDiag {
	@safe @nogc pure nothrow:
	struct Expected {
		enum Kind {
			closingBrace,
			closingParen,
			dedent,
			indent,
			multiLineArrSeparator,
			multiLineNewSeparator,
			purity,
			space,
			typeArgsEnd,
			typeParamQuestionMark,
		}
		immutable Kind kind;
	}
	struct IndentNotDivisible {
		immutable u32 nSpaces;
		immutable u32 nSpacesPerIndent;
	}
	struct IndentTooMuch {}
	struct IndentWrongCharacter {
		immutable Bool expectedTabs;
	}
	struct LetMustHaveThen {}
	struct MatchWhenOrLambdaNeedsBlockCtx {
		enum Kind {
			match,
			when,
			lambda,
		}
		immutable Kind kind;
	}
	struct MustEndInBlankLine {}
	struct ReservedName {
		immutable Sym name;
	}
	struct TypeParamCantHaveTypeArgs {}
	struct UnexpectedCharacter {
		immutable char ch;
	}
	struct UnexpectedDedent {}
	struct UnexpectedIndent {}
	struct UnionCantBeEmpty {}
	struct WhenMustHaveElse {}

	private:
	enum Kind {
		expected,
		indentNotDivisible,
		indentTooMuch,
		indentWrongCharacter,
		letMustHaveThen,
		matchWhenOrLambdaNeedsBlockCtx,
		mustEndInBlankLine,
		reservedName,
		typeParamCantHaveTypeArgs,
		unexpectedCharacter,
		unexpectedDedent,
		unexpectedIndent,
		unionCantBeEmpty,
		whenMustHaveElse,
	}
	immutable Kind kind;
	union {
		immutable Expected expected;
		immutable IndentNotDivisible indentNotDivisible;
		immutable IndentTooMuch indentTooMuch;
		immutable IndentWrongCharacter indentWrongCharacter;
		immutable LetMustHaveThen letMustHaveThen;
		immutable MatchWhenOrLambdaNeedsBlockCtx matchWhenOrLambdaNeedsBlockCtx;
		immutable MustEndInBlankLine mustEndInBlankLine;
		immutable ReservedName reservedName;
		immutable TypeParamCantHaveTypeArgs typeParamCantHaveTypeArgs;
		immutable UnexpectedCharacter unexpectedCharacter;
		immutable UnexpectedDedent unexpectedDedent;
		immutable UnexpectedIndent unexpectedIndent;
		immutable UnionCantBeEmpty unionCantBeEmpty;
		immutable WhenMustHaveElse whenMustHaveElse;
	}

	public:
	immutable this(immutable Expected a) { kind = Kind.expected; expected = a; }
	immutable this(immutable IndentNotDivisible a) { kind = Kind.indentNotDivisible; indentNotDivisible = a; }
	immutable this(immutable IndentTooMuch a) { kind = Kind.indentTooMuch; indentTooMuch = a; }
	immutable this(immutable IndentWrongCharacter a) { kind = Kind.indentWrongCharacter; indentWrongCharacter = a; }
	immutable this(immutable LetMustHaveThen a) { kind = Kind.letMustHaveThen; letMustHaveThen = a; }
	immutable this(immutable MatchWhenOrLambdaNeedsBlockCtx a) {
		kind = Kind.matchWhenOrLambdaNeedsBlockCtx; matchWhenOrLambdaNeedsBlockCtx = a;
	}
	immutable this(immutable MustEndInBlankLine a) { kind = Kind.mustEndInBlankLine; mustEndInBlankLine = a; }
	immutable this(immutable ReservedName a) { kind = Kind.reservedName; reservedName = a; }
	immutable this(immutable TypeParamCantHaveTypeArgs a) {
		kind = Kind.typeParamCantHaveTypeArgs; typeParamCantHaveTypeArgs = a;
	}
	immutable this(immutable UnexpectedCharacter a) { kind = Kind.unexpectedCharacter; unexpectedCharacter = a; }
	immutable this(immutable UnexpectedDedent a) { kind = Kind.unexpectedDedent; unexpectedDedent = a; }
	immutable this(immutable UnexpectedIndent a) { kind = Kind.unexpectedIndent; unexpectedIndent = a; }
	immutable this(immutable UnionCantBeEmpty a) { kind = Kind.unionCantBeEmpty; unionCantBeEmpty = a; }
	immutable this(immutable WhenMustHaveElse a) { kind = Kind.whenMustHaveElse; whenMustHaveElse = a; }
}

T matchParseDiag(T)(
	ref immutable ParseDiag a,
	scope T delegate(ref immutable ParseDiag.Expected) @safe @nogc pure nothrow cbExpected,
	scope T delegate(ref immutable ParseDiag.IndentNotDivisible) @safe @nogc pure nothrow cbIndentNotDivisible,
	scope T delegate(ref immutable ParseDiag.IndentTooMuch) @safe @nogc pure nothrow cbIndentTooMuch,
	scope T delegate(ref immutable ParseDiag.IndentWrongCharacter) @safe @nogc pure nothrow cbIndentWrongCharacter,
	scope T delegate(ref immutable ParseDiag.LetMustHaveThen) @safe @nogc pure nothrow cbLetMustHaveThen,
	scope T delegate(
		ref immutable ParseDiag.MatchWhenOrLambdaNeedsBlockCtx
	) @safe @nogc pure nothrow cbMatchWhenOrLambdaNeedsBlockCtx,
	scope T delegate(ref immutable ParseDiag.MustEndInBlankLine) @safe @nogc pure nothrow cbMustEndInBlankLine,
	scope T delegate(ref immutable ParseDiag.ReservedName) @safe @nogc pure nothrow cbReservedName,
	scope T delegate(
		ref immutable ParseDiag.TypeParamCantHaveTypeArgs
	) @safe @nogc pure nothrow cbTypeParamCantHaveTypeArgs,
	scope T delegate(ref immutable ParseDiag.UnexpectedCharacter) @safe @nogc pure nothrow cbUnexpectedCharacter,
	scope T delegate(ref immutable ParseDiag.UnexpectedDedent) @safe @nogc pure nothrow cbUnexpectedDedent,
	scope T delegate(ref immutable ParseDiag.UnexpectedIndent) @safe @nogc pure nothrow cbUnexpectedIndent,
	scope T delegate(ref immutable ParseDiag.UnionCantBeEmpty) @safe @nogc pure nothrow cbUnionCantBeEmpty,
	scope T delegate(ref immutable ParseDiag.WhenMustHaveElse) @safe @nogc pure nothrow cbWhenMustHaveElse,
) {
	final switch (a.kind) {
		case ParseDiag.Kind.expected:
			return cbExpected(a.expected);
		case ParseDiag.Kind.indentNotDivisible:
			return cbIndentNotDivisible(a.indentNotDivisible);
		case ParseDiag.Kind.indentTooMuch:
			return cbIndentTooMuch(a.indentTooMuch);
		case ParseDiag.Kind.indentWrongCharacter:
			return cbIndentWrongCharacter(a.indentWrongCharacter);
		case ParseDiag.Kind.letMustHaveThen:
			return cbLetMustHaveThen(a.letMustHaveThen);
		case ParseDiag.Kind.matchWhenOrLambdaNeedsBlockCtx:
			return cbMatchWhenOrLambdaNeedsBlockCtx(a.matchWhenOrLambdaNeedsBlockCtx);
		case ParseDiag.Kind.mustEndInBlankLine:
			return cbMustEndInBlankLine(a.mustEndInBlankLine);
		case ParseDiag.Kind.reservedName:
			return cbReservedName(a.reservedName);
		case ParseDiag.Kind.typeParamCantHaveTypeArgs:
			return cbTypeParamCantHaveTypeArgs(a.typeParamCantHaveTypeArgs);
		case ParseDiag.Kind.unexpectedCharacter:
			return cbUnexpectedCharacter(a.unexpectedCharacter);
		case ParseDiag.Kind.unexpectedDedent:
			return cbUnexpectedDedent(a.unexpectedDedent);
		case ParseDiag.Kind.unexpectedIndent:
			return cbUnexpectedIndent(a.unexpectedIndent);
		case ParseDiag.Kind.unionCantBeEmpty:
			return cbUnionCantBeEmpty(a.unionCantBeEmpty);
		case ParseDiag.Kind.whenMustHaveElse:
			return cbWhenMustHaveElse(a.whenMustHaveElse);
	}
}

struct ParseDiagnostic {
	immutable SourceRange range;
	immutable ParseDiag diag;
}
