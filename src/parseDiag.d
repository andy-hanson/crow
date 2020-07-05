module parseDiag;

@safe @nogc pure nothrow:

import util.bools : Bool;
import util.sourceRange : SourceRange;
import util.sym : Sym;
import util.types : u32;

struct ParseDiag {
	@safe @nogc pure nothrow:
	struct ExpectedCharacter {
		immutable char ch;
	}
	struct ExpectedDedent {}
	struct ExpectedIndent {}
	struct ExpectedPurityAfterSpace {}
	struct IndentNotDivisible {
		immutable u32 nSpaces;
		immutable u32 nSpacesPerIndent;
	}
	struct IndentWrongCharacter {
		immutable Bool expectedTabs;
	}
	struct LetMustHaveThen {}
	struct MatchWhenNewMayNotAppearInsideArg {}
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
		expectedCharacter,
		expectedDedent,
		expectedIndent,
		expectedPurityAfterSpace,
		indentNotDivisible,
		indentWrongCharacter,
		letMustHaveThen,
		matchWhenNewMayNotAppearInsideArg,
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
		immutable ExpectedCharacter expectedCharacter;
		immutable ExpectedDedent expectedDedent;
		immutable ExpectedIndent expectedIndent;
		immutable ExpectedPurityAfterSpace expectedPurityAfterSpace;
		immutable IndentNotDivisible indentNotDivisible;
		immutable IndentWrongCharacter indentWrongCharacter;
		immutable LetMustHaveThen letMustHaveThen;
		immutable MatchWhenNewMayNotAppearInsideArg matchWhenNewMayNotAppearInsideArg;
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
	immutable this(immutable ExpectedCharacter a) { kind = Kind.expectedCharacter; expectedCharacter = a; }
	immutable this(immutable ExpectedDedent a) { kind = Kind.expectedDedent; expectedDedent = a; }
	immutable this(immutable ExpectedIndent a) { kind = Kind.expectedIndent; expectedIndent = a; }
	immutable this(immutable ExpectedPurityAfterSpace a) { kind = Kind.expectedPurityAfterSpace; expectedPurityAfterSpace = a; }
	immutable this(immutable IndentNotDivisible a) { kind = Kind.indentNotDivisible; indentNotDivisible = a; }
	immutable this(immutable IndentWrongCharacter a) { kind = Kind.indentWrongCharacter; indentWrongCharacter = a; }
	immutable this(immutable LetMustHaveThen a) { kind = Kind.letMustHaveThen; letMustHaveThen = a; }
	immutable this(immutable MatchWhenNewMayNotAppearInsideArg a) { kind = Kind.matchWhenNewMayNotAppearInsideArg; matchWhenNewMayNotAppearInsideArg = a; }
	immutable this(immutable MustEndInBlankLine a) { kind = Kind.mustEndInBlankLine; mustEndInBlankLine = a; }
	immutable this(immutable ReservedName a) { kind = Kind.reservedName; reservedName = a; }
	immutable this(immutable TypeParamCantHaveTypeArgs a) { kind = Kind.typeParamCantHaveTypeArgs; typeParamCantHaveTypeArgs = a; }
	immutable this(immutable UnexpectedCharacter a) { kind = Kind.unexpectedCharacter; unexpectedCharacter = a; }
	immutable this(immutable UnexpectedDedent a) { kind = Kind.unexpectedDedent; unexpectedDedent = a; }
	immutable this(immutable UnexpectedIndent a) { kind = Kind.unexpectedIndent; unexpectedIndent = a; }
	immutable this(immutable UnionCantBeEmpty a) { kind = Kind.unionCantBeEmpty; unionCantBeEmpty = a; }
	immutable this(immutable WhenMustHaveElse a) { kind = Kind.whenMustHaveElse; whenMustHaveElse = a; }
}

T matchParseDiag(T)(
	ref immutable ParseDiag a,
	scope T delegate(ref immutable ParseDiag.ExpectedCharacter) @safe @nogc pure nothrow cbExpectedCharacter,
	scope T delegate(ref immutable ParseDiag.ExpectedDedent) @safe @nogc pure nothrow cbExpectedDedent,
	scope T delegate(ref immutable ParseDiag.ExpectedIndent) @safe @nogc pure nothrow cbExpectedIndent,
	scope T delegate(ref immutable ParseDiag.ExpectedPurityAfterSpace) @safe @nogc pure nothrow cbExpectedPurityAfterSpace,
	scope T delegate(ref immutable ParseDiag.IndentNotDivisible) @safe @nogc pure nothrow cbIndentNotDivisible,
	scope T delegate(ref immutable ParseDiag.IndentWrongCharacter) @safe @nogc pure nothrow cbIndentWrongCharacter,
	scope T delegate(ref immutable ParseDiag.LetMustHaveThen) @safe @nogc pure nothrow cbLetMustHaveThen,
	scope T delegate(ref immutable ParseDiag.MatchWhenNewMayNotAppearInsideArg) @safe @nogc pure nothrow cbMatchWhenNewMayNotAppearInsideArg,
	scope T delegate(ref immutable ParseDiag.MustEndInBlankLine) @safe @nogc pure nothrow cbMustEndInBlankLine,
	scope T delegate(ref immutable ParseDiag.ReservedName) @safe @nogc pure nothrow cbReservedName,
	scope T delegate(ref immutable ParseDiag.TypeParamCantHaveTypeArgs) @safe @nogc pure nothrow cbTypeParamCantHaveTypeArgs,
	scope T delegate(ref immutable ParseDiag.UnexpectedCharacter) @safe @nogc pure nothrow cbUnexpectedCharacter,
	scope T delegate(ref immutable ParseDiag.UnexpectedDedent) @safe @nogc pure nothrow cbUnexpectedDedent,
	scope T delegate(ref immutable ParseDiag.UnexpectedIndent) @safe @nogc pure nothrow cbUnexpectedIndent,
	scope T delegate(ref immutable ParseDiag.UnionCantBeEmpty) @safe @nogc pure nothrow cbUnionCantBeEmpty,
	scope T delegate(ref immutable ParseDiag.WhenMustHaveElse) @safe @nogc pure nothrow cbWhenMustHaveElse,
) {
	final switch (a.kind) {
		case ParseDiag.Kind.expectedCharacter:
			return cbExpectedCharacter(a.expectedCharacter);
		case ParseDiag.Kind.expectedDedent:
			return cbExpectedDedent(a.expectedDedent);
		case ParseDiag.Kind.expectedIndent:
			return cbExpectedIndent(a.expectedIndent);
		case ParseDiag.Kind.expectedPurityAfterSpace:
			return cbExpectedPurityAfterSpace(a.expectedPurityAfterSpace);
		case ParseDiag.Kind.indentNotDivisible:
			return cbIndentNotDivisible(a.indentNotDivisible);
		case ParseDiag.Kind.indentWrongCharacter:
			return cbIndentWrongCharacter(a.indentWrongCharacter);
		case ParseDiag.Kind.letMustHaveThen:
			return cbLetMustHaveThen(a.letMustHaveThen);
		case ParseDiag.Kind.matchWhenNewMayNotAppearInsideArg:
			return cbMatchWhenNewMayNotAppearInsideArg(a.matchWhenNewMayNotAppearInsideArg);
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
