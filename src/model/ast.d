module model.ast;

@safe @nogc pure nothrow:

import model.model : AssertOrForbidKind, FunKind, stringOfVarKindLowerCase, VarKind, Visibility;
import model.parseDiag : ParseDiag, ParseDiagnostic;
import util.alloc.alloc : Alloc;
import util.col.array : arrayOfSingle, exists, isEmpty, newSmallArray, sizeEq, SmallArray;
import util.conv : safeToUint;
import util.integralValues : IntegralValue;
import util.opt : force, has, none, Opt, optIf, optOrDefault, some;
import util.sourceRange : combineRanges, Pos, Range, rangeOfStartAndLength;
import util.string : SmallString;
import util.symbol : Symbol, symbol, symbolSize;
import util.union_ : TaggedUnion, Union;
import util.uri : Path, pathLength, RelPath, relPathLength;
import util.util : roundUp, stringOfEnum;

immutable struct NameAndRange {
	@safe @nogc pure nothrow:

	Symbol name;
	// Range length is given by size of name
	Pos start;

	this(Pos s, Symbol n) {
		name = n;
		start = s;
	}

	Range range() scope =>
		rangeOfStartAndLength(start, symbolSize(name));
}
static assert(NameAndRange.sizeof == ulong.sizeof);

immutable struct FieldMutabilityAst {
	@safe @nogc pure nothrow:

	Pos pos;
	Opt!Visibility visibility_;

	Range range() =>
		rangeOfStartAndLength(pos, has(visibility) ? "-mut".length : "mut".length);

	Opt!VisibilityAndRange visibility() =>
		getVisibilityAndRange(pos, visibility_);
}
static assert(FieldMutabilityAst.sizeof == ulong.sizeof);

immutable struct VisibilityAndRange {
	@safe @nogc pure nothrow:

	Visibility visibility;
	Pos pos;

	Range range() =>
		rangeOfStartAndLength(pos, "+".length);
}

private Opt!VisibilityAndRange getVisibilityAndRange(Pos pos, Opt!Visibility visibility) =>
	optIf(has(visibility), () =>
		VisibilityAndRange(force(visibility), pos));

immutable struct TypeAst {
	@safe @nogc pure nothrow:

	immutable struct Bogus {
		Range range;
	}

	immutable struct Fun {
		@safe @nogc pure nothrow:

		TypeAst returnType;
		Pos kindPos;
		FunKind kind;
		Range paramsRange;
		ParamsAst params;

		Range range() scope =>
			combineRanges(returnType.range, paramsRange);
		Range kindRange() scope =>
			rangeOfStartAndLength(kindPos, stringOfEnum(kind).length);
	}

	immutable struct Map {
		@safe @nogc pure nothrow:
		enum Kind {
			data,
			mut,
			shared_,
		}
		Kind kind;
		// They are actually written v[k] at the use, but applied as (k, v)
		TypeAst[2] kv;
		TypeAst k() return scope =>
			kv[0];
		TypeAst v() return scope =>
			kv[1];

		Range range() scope =>
			Range(v.range.start, safeToUint(k.range.end + "]".length));
	}

	immutable struct SuffixName {
		@safe @nogc pure nothrow:
		TypeAst left;
		NameAndRange name;

		Range range() scope =>
			combineRanges(left.range, suffixRange);
		Range suffixRange() scope =>
			name.range;
	}

	immutable struct SuffixSpecial {
		@safe @nogc pure nothrow:
		enum Kind : ubyte {
			future,
			list,
			mutList,
			mutPtr,
			option,
			ptr,
			sharedList,
		}
		TypeAst left;
		Pos suffixPos;
		Kind kind;

		Range range() scope =>
			Range(left.range.start, suffixEnd);
		Range suffixRange() scope =>
			Range(suffixPos, suffixEnd);
		private Pos suffixEnd() scope =>
			suffixPos + suffixLength(kind);
	}

	immutable struct Tuple {
		@safe @nogc pure nothrow:

		Range range;
		SmallArray!TypeAst members;

		this(Range r, TypeAst[] ms) {
			range = r;
			members = ms;
			assert(members.length >= 2);
		}
	}

	mixin Union!(Bogus, Fun*, Map*, NameAndRange, SuffixName*, SuffixSpecial*, Tuple*);

	Range range() scope =>
		matchIn!Range(
			(in TypeAst.Bogus x) => x.range,
			(in TypeAst.Fun x) => x.range,
			(in TypeAst.Map x) => x.range,
			(in NameAndRange x) => x.range,
			(in TypeAst.SuffixName x) => x.range,
			(in TypeAst.SuffixSpecial x) => x.range,
			(in TypeAst.Tuple x) => x.range);
	Range nameRangeOrRange() scope =>
		matchIn!Range(
			(in TypeAst.Bogus x) => x.range,
			(in TypeAst.Fun x) => x.kindRange,
			(in TypeAst.Map x) => x.range,
			(in NameAndRange x) => x.range,
			(in TypeAst.SuffixName x) => x.suffixRange,
			(in TypeAst.SuffixSpecial x) => x.suffixRange,
			(in TypeAst.Tuple x) => x.range);
}
static assert(TypeAst.sizeof == size_t.sizeof + NameAndRange.sizeof);

private uint suffixLength(TypeAst.SuffixSpecial.Kind a) {
	final switch (a) {
		case TypeAst.SuffixSpecial.Kind.future:
			return cast(uint) "$".length;
		case TypeAst.SuffixSpecial.Kind.list:
			return cast(uint) "[]".length;
		case TypeAst.SuffixSpecial.Kind.option:
			return cast(uint) "?".length;
		case TypeAst.SuffixSpecial.Kind.mutList:
			return cast(uint) "mut[]".length;
		case TypeAst.SuffixSpecial.Kind.mutPtr:
			return cast(uint) "mut*".length;
		case TypeAst.SuffixSpecial.Kind.ptr:
			return cast(uint) "*".length;
		case TypeAst.SuffixSpecial.Kind.sharedList:
			return cast(uint) "shared[]".length;
	}
}

Symbol symbolForTypeAstMap(TypeAst.Map.Kind a) {
	final switch (a) {
		case TypeAst.Map.Kind.data:
			return symbol!"map";
		case TypeAst.Map.Kind.mut:
			return symbol!"mut-map";
		case TypeAst.Map.Kind.shared_:
			return symbol!"shared-map";
	}
}

Symbol symbolForTypeAstSuffix(TypeAst.SuffixSpecial.Kind a) {
	final switch (a) {
		case TypeAst.SuffixSpecial.Kind.future:
			return symbol!"future";
		case TypeAst.SuffixSpecial.Kind.list:
			return symbol!"list";
		case TypeAst.SuffixSpecial.Kind.mutList:
			return symbol!"mut-list";
		case TypeAst.SuffixSpecial.Kind.mutPtr:
			return symbol!"mut-pointer";
		case TypeAst.SuffixSpecial.Kind.option:
			return symbol!"option";
		case TypeAst.SuffixSpecial.Kind.ptr:
			return symbol!"const-pointer";
		case TypeAst.SuffixSpecial.Kind.sharedList:
			return symbol!"shared-list";
	}
}

immutable struct ArrowAccessAst {
	@safe @nogc pure nothrow:
	ExprAst* left;
	Pos keywordPos;
	NameAndRange name;

	Range keywordRange() =>
		rangeOfStartAndLength(keywordPos, "->".length);
}

immutable struct AssertOrForbidAst {
	@safe @nogc pure nothrow:
	AssertOrForbidKind kind;
	ExprAst condition;
	Opt!ExprAst thrown;

	Range keywordRange(in ExprAst* ast) scope {
		assert(ast.kind.as!(AssertOrForbidAst*) == &this);
		static assert("assert".length == "forbid".length);
		return ast.range[0 .. "assert".length];
	}
}

// `left := right`
immutable struct AssignmentAst {
	@safe @nogc pure nothrow:
	ExprAst left;
	Pos assignmentPos;
	ExprAst right;

	Range keywordRange() =>
		rangeOfStartAndLength(assignmentPos, ":=".length);
}

// `left f:= right`
immutable struct AssignmentCallAst {
	@safe @nogc pure nothrow:

	NameAndRange funName;
	ExprAst[2]* leftAndRight;

	ref ExprAst left() return scope =>
		(*leftAndRight)[0];
	ref ExprAst right() return scope =>
		(*leftAndRight)[1];

	Range keywordRange() =>
		rangeOfStartAndLength(funName.range.end, ":=".length);
}

immutable struct BogusAst {}

immutable struct CallAst {
	@safe @nogc pure nothrow:

	enum Style : ubyte {
		comma, // `a, b`, `a, b, c`, etc.
		dot, // `a.b`
		emptyParens, // `()`
		implicit,
		infix, // `a b`, `a b c`, `a b c, d`, etc.
		prefixBang,
		prefixOperator, // `-x`, `x`, `~x`
		single, // `a@t` (without the type arg, it would just be an Identifier)
		subscript, // a[b]
		suffixBang, // 'x!'
	}
	Style style;
	NameAndRange funName;
	SmallArray!ExprAst args;
	Opt!(TypeAst*) typeArg;

	Range nameRange(in ExprAst* ast) scope =>
		style == Style.comma ? ast.range : funName.range;
}

immutable struct CallNamedAst {
	@safe @nogc pure nothrow:

	NameAndRange[] names;
	ExprAst[] args;

	this(NameAndRange[] ns, ExprAst[] as) {
		names = ns;
		args = as;
		assert(!isEmpty(names));
		assert(sizeEq(names, args));
	}
}

immutable struct DoAst {
	ExprAst* body_;
}

// Used for implicit 'else ()' or implicit '()' after a Let
immutable struct EmptyAst {}

immutable struct ForAst {
	@safe @nogc pure nothrow:
	DestructureAst param;
	Pos colonPos;
	ExprAst collection;
	ExprAst body_;
	ExprAst else_; // May be EmptyAst

	Range forKeywordRange(in ExprAst source) scope {
		assert(source.kind.as!(ForAst*) == &this);
		return source.range[0 .. "for".length];
	}
	Range colonRange() scope =>
		rangeOfStartAndLength(colonPos, ":".length);
}

immutable struct IdentifierAst {
	Symbol name;
}

immutable struct IfConditionAst {
	immutable struct UnpackOption {
		@safe @nogc pure nothrow:
		DestructureAst destructure;
		Pos questionEqualsPos;
		ExprAst* option;

		Range questionEqualsRange() scope =>
			rangeOfStartAndLength(questionEqualsPos, "?=".length);
	}
	mixin TaggedUnion!(UnpackOption*, ExprAst*);
}

immutable struct IfAst {
	@safe @nogc pure nothrow:
	enum Kind {
		ifWithoutElse, // 'if' with no 'else'
		ifElif, // In this case, the 'else' expression will be another IfAst
		ifElse, // Has 'if' and 'else' keywords
		ternaryWithElse, // 'cond ? then : else'
		ternaryWithoutElse, // 'cond ? then'
		unless,
	}

	Kind kind;
	Pos firstKeywordPos; // Position of 'if' or '?' or 'unless'
	Pos secondKeywordPos; // Position of 'elif' or 'else' or ':' keyword
	IfConditionAst condition;
	// For an 'unless', the 'then' is still the first branch syntactically.
	// 'else' is often an EmptyAst.
	private ExprAst[2]* thenElse;

	ref ExprAst then() return scope =>
		(*thenElse)[0];
	ref ExprAst else_() return scope =>
		(*thenElse)[1];

	Range firstKeywordRange() scope {
		size_t length = () {
			final switch (kind) {
				case Kind.ifWithoutElse:
				case Kind.ifElif:
				case Kind.ifElse:
					return "if".length;
				case Kind.ternaryWithElse:
				case Kind.ternaryWithoutElse:
					return "?".length;
				case Kind.unless:
					return "unless".length;
			}
		}();
		return rangeOfStartAndLength(firstKeywordPos, length);
	}
	Range secondKeywordRange() {
		size_t length = () {
			final switch (kind) {
				case Kind.ifWithoutElse:
				case Kind.ternaryWithoutElse:
				case Kind.unless:
					return 0;
				case Kind.ifElif:
				case Kind.ifElse:
					return "else".length;
				case Kind.ternaryWithElse:
					return ":".length;
			}
		}();
		return rangeOfStartAndLength(secondKeywordPos, length);
	}

	bool hasElse() scope {
		final switch (kind) {
			case Kind.ifWithoutElse:
			case Kind.ternaryWithoutElse:
			case Kind.unless:
				return false;
			case Kind.ifElif:
			case Kind.ifElse:
			case Kind.ternaryWithElse:
				return true;
		}
	}
}

immutable struct InterpolatedAst {
	ExprAst[] parts;
}

immutable struct LambdaAst {
	@safe @nogc pure nothrow:
	DestructureAst param;
	Opt!Pos arrowPos; // None for synthetic LambdaAst, in a 'for' or 'with' or '<-'
	ExprAst body_;

	Opt!Range arrowRange() scope =>
		has(arrowPos) ? some(rangeOfStartAndLength(force(arrowPos), "=>".length)) : none!Range;
}

immutable struct DestructureAst {
	@safe @nogc pure nothrow:

	immutable struct Single {
		@safe @nogc pure nothrow:
		NameAndRange name; // Name may be '_', meaning ignore and don't create a local
		Opt!Pos mut; // position of 'mut' keyword if it exists
		Opt!(TypeAst*) type;

		Range range() scope =>
			Range(name.start, (
				has(type)
				? force(type).range
				: optOrDefault!Range(mutRange, () => name.range)
			).end);
		Range nameRange() scope =>
			name.range;
		Opt!Range mutRange() scope =>
			has(mut)
				? some(Range(force(mut), force(mut) + safeToUint("mut".length)))
				: none!Range;
	}
	// `()` is a destructure matching only void values
	immutable struct Void {
		Range range;
	}
	mixin Union!(Single, Void, DestructureAst[]);

	Pos pos() scope =>
		matchIn!Pos(
			(in DestructureAst.Single x) =>
				x.name.start,
			(in DestructureAst.Void x) =>
				x.range.start,
			(in DestructureAst[] parts) =>
				parts[0].pos);

	Range range() scope =>
		matchIn!Range(
			(in DestructureAst.Single x) {
				Range name = x.name.range;
				return has(x.type)
					? Range(name.start, force(x.type).range.end)
					: name;
			},
			(in DestructureAst.Void x) =>
				x.range,
			(in DestructureAst[] parts) =>
				Range(parts[0].range.start, parts[$ - 1].range.end));
}

immutable struct LetAst {
	DestructureAst destructure;
	ExprAst value;
	ExprAst then;
}

immutable struct LiteralFloatAst {
	double value;
	bool overflow;
}

immutable struct LiteralIntegral {
	bool isSigned;
	bool overflow;
	IntegralValue value;
}

immutable struct LiteralIntegralAndRange {
	Range range;
	LiteralIntegral literal;
}

immutable struct LiteralStringAst {
	string value;
}

immutable struct LoopAst {
	@safe @nogc pure nothrow:
	ExprAst body_;
	Range keywordRange(in ExprAst* source) scope {
		assert(source.kind.as!(LoopAst*) == &this);
		return source.range[0 .. "loop".length];
	}
}

immutable struct LoopBreakAst {
	@safe @nogc pure nothrow:
	ExprAst value;

	Range keywordRange(in ExprAst* source) scope {
		assert(source.kind.as!(LoopBreakAst*) == &this);
		return source.range[0 .. "break".length];
	}
}

immutable struct LoopContinueAst {
	@safe @nogc pure nothrow:
	Range keywordRange(in ExprAst* source) =>
		source.range[0 .. "continue".length];
}

immutable struct LoopWhileOrUntilAst {
	@safe @nogc pure nothrow:
	bool isUntil;
	ExprAst condition;
	ExprAst body_;

	Range keywordRange(in ExprAst* source) scope {
		assert(source.kind.as!(LoopWhileOrUntilAst*) == &this);
		static assert("while".length == "until".length);
		return source.range[0 .. "while".length];
	}
}

immutable struct MatchAst {
	@safe @nogc pure nothrow:

	ExprAst* matched;
	SmallArray!CaseAst cases;
	Opt!(MatchElseAst*) else_;
}

Range keywordRange(in MatchAst ast, in ExprAst source) =>
	rangeOfStartAndLength(source.range.start, "match".length);

immutable struct CaseAst {
	@safe @nogc pure nothrow:

	Pos keywordPos;
	CaseMemberAst member;
	ExprAst then;

	Range keywordAndMemberNameRange() scope =>
		Range(keywordPos, member.nameRange.end);
}

immutable struct CaseMemberAst {
	@safe @nogc pure nothrow:
	immutable struct Bogus {
		Range range;
	}
	immutable struct Name {
		NameAndRange name;
		Opt!DestructureAst destructure;
	}
	immutable struct String {
		Range range;
		string value;
	}

	mixin Union!(Name, LiteralIntegralAndRange, String, Bogus);
	Range nameRange() scope =>
		matchIn!Range(
			(in Name x) => x.name.range,
			(in LiteralIntegralAndRange x) => x.range,
			(in String x) => x.range,
			(in CaseMemberAst.Bogus x) => x.range);
}
static assert(CaseMemberAst.sizeof == roundUp(CaseMemberAst.Name.sizeof, 8) + ulong.sizeof);

immutable struct MatchElseAst {
	@safe @nogc pure nothrow:
	Pos keywordPos;
	ExprAst expr;

	Range keywordRange() =>
		rangeOfStartAndLength(keywordPos, "else".length);
}

immutable struct ParenthesizedAst {
	ExprAst inner;
}

immutable struct PtrAst {
	@safe @nogc pure nothrow:
	ExprAst inner;

	Range keywordRange(in ExprAst* ast) scope {
		assert(ast.kind.as!(PtrAst*) == &this);
		return ast.range[0 .. "&".length];
	}
}

immutable struct SeqAst {
	ExprAst first;
	ExprAst then;
}

immutable struct SharedAst {
	@safe @nogc pure nothrow:
	ExprAst inner;

	Range keywordRange(in ExprAst ast) scope {
		assert(ast.kind.as!(SharedAst*) == &this);
		return ast.range[0 .. "shared".length];
	}
}

immutable struct ThenAst {
	@safe @nogc pure nothrow:
	DestructureAst left;
	Pos keywordPos;
	ExprAst futExpr;
	ExprAst then;

	Range keywordRange() scope =>
		rangeOfStartAndLength(keywordPos, "<-".length);
}

immutable struct ThrowAst {
	@safe @nogc pure nothrow:
	ExprAst thrown;

	Range keywordRange(in ExprAst* ast) scope {
		assert(ast.kind.as!(ThrowAst*) == &this);
		return ast.range[0 .. "throw".length];
	}
}

immutable struct TrustedAst {
	@safe @nogc pure nothrow:
	ExprAst inner;

	Range keywordRange(in ExprAst* ast) scope {
		assert(ast.kind.as!(TrustedAst*) == &this);
		return ast.range[0 .. "trusted".length];
	}
}

// expr :: t
immutable struct TypedAst {
	@safe @nogc pure nothrow:
	ExprAst expr;
	Pos colonPos;
	TypeAst type;

	Range keywordRange() =>
		rangeOfStartAndLength(colonPos, "::".length);
}

immutable struct WithAst {
	@safe @nogc pure nothrow:

	DestructureAst param;
	Pos colonPos;
	ExprAst arg;
	ExprAst body_;
	ExprAst else_; // May be EmptyAst (or else a compile error)

	Range withKeywordRange(in ExprAst ast) scope {
		assert(ast.kind.as!(WithAst*) == &this);
		return ast.range[0 .. "with".length];
	}
	Range colonRange() scope =>
		rangeOfStartAndLength(colonPos, ":".length);
}

immutable struct ExprAstKind {
	mixin Union!(
		ArrowAccessAst,
		AssertOrForbidAst*,
		AssignmentAst*,
		AssignmentCallAst,
		BogusAst,
		CallAst,
		CallNamedAst,
		DoAst,
		EmptyAst,
		ForAst*,
		IdentifierAst,
		IfAst,
		InterpolatedAst,
		LambdaAst*,
		LetAst*,
		LiteralFloatAst,
		LiteralIntegral,
		LiteralStringAst,
		LoopAst*,
		LoopBreakAst*,
		LoopContinueAst,
		LoopWhileOrUntilAst*,
		MatchAst,
		ParenthesizedAst*,
		PtrAst*,
		SeqAst*,
		SharedAst*,
		ThenAst*,
		ThrowAst*,
		TrustedAst*,
		TypedAst*,
		WithAst*);
}
version (WebAssembly) {} else {
	static assert(ExprAstKind.sizeof == CallAst.sizeof + ulong.sizeof);
}

immutable struct ExprAst {
	Range range;
	ExprAstKind kind;
}
static assert(ExprAst.sizeof <= 6 * ulong.sizeof);

immutable struct ParamsAst {
	immutable struct Varargs {
		DestructureAst param;
	}
	mixin TaggedUnion!(SmallArray!DestructureAst, Varargs*);
}

DestructureAst[] paramsArray(return scope ParamsAst a) =>
	a.matchWithPointers!(DestructureAst[])(
		(DestructureAst[] x) =>
			x,
		(ParamsAst.Varargs* x) =>
			arrayOfSingle(&x.param));

immutable struct SpecSigAst {
	@safe @nogc pure nothrow:

	SmallString docComment;
	Range range;
	Symbol name;
	TypeAst returnType;
	ParamsAst params;

	NameAndRange nameAndRange() scope =>
		NameAndRange(range.start, name);
	Range nameRange() scope =>
		nameAndRange.range;
}

immutable struct StructAliasAst {
	@safe @nogc pure nothrow:

	SmallString docComment;
	Range range;
	Opt!Visibility visibility_;
	NameAndRange name;
	SmallArray!NameAndRange typeParams;
	Pos keywordPos;
	TypeAst target;

	Range nameRange() scope =>
		name.range;
	Range keywordRange() scope =>
		rangeOfStartAndLength(keywordPos, "alias".length);
	Opt!VisibilityAndRange visibility() scope =>
		getVisibilityAndRange(range.start, visibility_);
}

Range typeParamsRange(in SmallArray!NameAndRange typeParams) {
	assert(!isEmpty(typeParams));
	return combineRanges(
		typeParams[0].range,
		typeParams[$ - 1].range);
}

immutable struct ModifierAst {
	@safe @nogc pure nothrow:

	immutable struct Keyword {
		@safe @nogc pure nothrow:

		Opt!TypeAst typeArg;
		Pos keywordPos;
		ModifierKeyword keyword;

		Range range() scope =>
			has(typeArg)
				? combineRanges(force(typeArg).range, keywordRange)
				: keywordRange;
		Range keywordRange() scope =>
			rangeOfStartAndLength(keywordPos, stringOfModifierKeyword(keyword).length);
	}

	mixin Union!(Keyword, SpecUseAst);

	Range range() scope =>
		matchIn!Range(
			(in Keyword x) =>
				x.range,
			(in SpecUseAst x) =>
				x.range);
}

immutable struct SpecUseAst {
	@safe @nogc pure nothrow:
	Opt!TypeAst typeArg;
	NameAndRange name;

	Range range() scope =>
		has(typeArg)
			? combineRanges(force(typeArg).range, name.range)
			: name.range;
	Range nameRange() scope =>
		name.range;
}

enum ModifierKeyword : ubyte {
	bare,
	builtin,
	byRef,
	byVal,
	data,
	// It's a compile error to have extern without a library name,
	// so those will usually be a Extern instead
	extern_,
	forceCtx,
	forceShared,
	mut,
	newInternal,
	newPublic,
	newPrivate,
	nominal,
	packed,
	pure_,
	shared_,
	storage,
	summon,
	trusted,
	unsafe,
}

immutable struct StructBodyAst {
	immutable struct Builtin {}
	immutable struct Enum {
		Opt!ParamsAst params;
		SmallArray!EnumOrFlagsMemberAst members;
	}
	immutable struct Extern {
		Opt!(LiteralIntegralAndRange*) size;
		Opt!(LiteralIntegralAndRange*) alignment;
	}
	immutable struct Flags {
		Opt!ParamsAst params;
		SmallArray!EnumOrFlagsMemberAst members;
	}
	immutable struct Record {
		Opt!ParamsAst params;
		SmallArray!RecordOrUnionMemberAst fields;
	}
	immutable struct Union {
		Opt!ParamsAst params;
		SmallArray!RecordOrUnionMemberAst members;
	}

	mixin .Union!(Builtin, Enum, Extern, Flags, Record, Union);
}
static assert(StructBodyAst.sizeof <= 24);

immutable struct EnumOrFlagsMemberAst {
	@safe @nogc pure nothrow:

	Range range;
	Symbol name;
	Opt!LiteralIntegralAndRange value;

	NameAndRange nameAndRange() scope =>
		NameAndRange(range.start, name);
	Range nameRange() scope =>
		nameAndRange.range;
}

immutable struct RecordOrUnionMemberAst {
	@safe @nogc pure nothrow:

	Range range;
	Opt!Visibility visibility_;
	NameAndRange name;
	Opt!FieldMutabilityAst mutability;
	Opt!TypeAst type;

	Opt!VisibilityAndRange visibility() scope =>
		getVisibilityAndRange(range.start, visibility_);

	Range nameRange() scope =>
		name.range;
}

immutable struct StructDeclAst {
	@safe @nogc pure nothrow:

	SmallString docComment;
	// Range starts at the visibility
	Range range;
	Opt!Visibility visibility_;
	NameAndRange name;
	SmallArray!NameAndRange typeParams;
	Pos keywordPos;
	SmallArray!ModifierAst modifiers;
	StructBodyAst body_;

	Range nameRange() scope =>
		name.range;
	Range keywordRange() scope =>
		rangeOfStartAndLength(keywordPos, keywordForStructBody(body_).length);
	Opt!VisibilityAndRange visibility() scope =>
		getVisibilityAndRange(range.start, visibility_);
}

private string keywordForStructBody(in StructBodyAst a) =>
	a.matchIn!string(
		(in StructBodyAst.Builtin) =>
			"builtin",
		(in StructBodyAst.Enum) =>
			"enum",
		(in StructBodyAst.Extern) =>
			"extern",
		(in StructBodyAst.Flags) =>
			"flags",
		(in StructBodyAst.Record) =>
			"record",
		(in StructBodyAst.Union) =>
			"union");

immutable struct SpecDeclAst {
	@safe @nogc pure nothrow:

	Range range;
	SmallString docComment;
	Opt!Visibility visibility_;
	NameAndRange name;
	SmallArray!NameAndRange typeParams;
	Pos specKeywordPos;
	SmallArray!ModifierAst modifiers;
	SmallArray!SpecSigAst sigs;

	Range nameRange() scope =>
		name.range;
	Range keywordRange() scope =>
		rangeOfStartAndLength(specKeywordPos, "spec".length);
	Opt!VisibilityAndRange visibility() scope =>
		getVisibilityAndRange(range.start, visibility_);
}

immutable struct FunDeclAst {
	@safe @nogc pure nothrow:

	Range range;
	SmallString docComment;
	Opt!Visibility visibility_;
	NameAndRange name;
	SmallArray!NameAndRange typeParams;
	TypeAst returnType;
	ParamsAst params;
	SmallArray!ModifierAst modifiers;
	ExprAst body_; // EmptyAst if missing

	Opt!VisibilityAndRange visibility() scope =>
		getVisibilityAndRange(range.start, visibility_);

	Range nameRange() scope =>
		name.range;
}

string stringOfModifierKeyword(ModifierKeyword a) {
	final switch (a) {
		case ModifierKeyword.bare:
			return "bare";
		case ModifierKeyword.builtin:
			return "builtin";
		case ModifierKeyword.byRef:
			return "by-ref";
		case ModifierKeyword.byVal:
			return "by-val";
		case ModifierKeyword.data:
			return "data";
		case ModifierKeyword.extern_:
			return "extern";
		case ModifierKeyword.forceCtx:
			return "force-ctx";
		case ModifierKeyword.forceShared:
			return "force-shared";
		case ModifierKeyword.mut:
			return "mut";
		case ModifierKeyword.newInternal:
			return "~new";
		case ModifierKeyword.newPrivate:
			return "-new";
		case ModifierKeyword.newPublic:
			return "+new";
		case ModifierKeyword.nominal:
			return "nominal";
		case ModifierKeyword.packed:
			return "packed";
		case ModifierKeyword.pure_:
			return "pure";
		case ModifierKeyword.shared_:
			return "shared";
		case ModifierKeyword.storage:
			return "storage";
		case ModifierKeyword.summon:
			return "summon";
		case ModifierKeyword.trusted:
			return "trusted";
		case ModifierKeyword.unsafe:
			return "unsafe";
	}
}

immutable struct TestAst {
	@safe @nogc pure nothrow:

	Range range;
	SmallArray!ModifierAst modifiers;
	ExprAst body_; // EmptyAst if missing

	Range keywordRange() scope =>
		rangeOfStartAndLength(range.start, "test".length);
}

// 'global' or 'thread-local'
immutable struct VarDeclAst {
	@safe @nogc pure nothrow:

	Range range;
	SmallString docComment;
	Opt!Visibility visibility_;
	NameAndRange name;
	SmallArray!NameAndRange typeParams; // This will be a compile error
	Pos keywordPos;
	VarKind kind;
	TypeAst type;
	SmallArray!ModifierAst modifiers; // Any but 'extern' will be a compile error

	Range nameRange() scope =>
		name.range;
	Range keywordRange() scope =>
		rangeOfStartAndLength(keywordPos, stringOfVarKindLowerCase(kind).length);
	Opt!VisibilityAndRange visibility() scope =>
		getVisibilityAndRange(range.start, visibility_);
}

immutable struct ImportOrExportAst {
	@safe @nogc pure nothrow:
	Range range;
	// Does not include the extension (which is only allowed for file imports)
	PathOrRelPath path;
	ImportOrExportAstKind kind;

	Range pathRange() scope =>
		rangeOfStartAndLength(range.start, pathOrRelPathLength(path));
}

immutable struct PathOrRelPath {
	mixin TaggedUnion!(Path, RelPath);
}
private size_t pathOrRelPathLength(in PathOrRelPath a) =>
	a.matchIn!size_t(
		(in Path x) =>
			pathLength(x),
		(in RelPath x) =>
			relPathLength(x));

immutable struct ImportOrExportAstKind {
	immutable struct ModuleWhole {}
	immutable struct File {
		NameAndRange name;
		TypeAst typeAst;
		ImportFileType type;
	}
	mixin TaggedUnion!(ModuleWhole, SmallArray!NameAndRange, File*);
}

enum ImportFileType { nat8Array, string }

immutable struct ImportsOrExportsAst {
	Range range;
	SmallArray!ImportOrExportAst paths;
}

immutable struct FileAst {
	SmallArray!ParseDiagnostic parseDiagnostics;
	SmallString docComment;
	bool noStd;
	Opt!ImportsOrExportsAst imports;
	Opt!ImportsOrExportsAst reExports;
	SmallArray!SpecDeclAst specs;
	SmallArray!StructAliasAst structAliases;
	SmallArray!StructDeclAst structs;
	SmallArray!FunDeclAst funs;
	SmallArray!TestAst tests;
	SmallArray!VarDeclAst vars;
}

private FileAst fileAstForDiags(SmallArray!ParseDiagnostic diags) =>
	// Make sure the dummy AST doesn't have implicit imports
	FileAst(diags, noStd: true);

FileAst fileAstForDiag(ref Alloc alloc, ParseDiag diag) =>
	fileAstForDiags(newSmallArray(alloc, [ParseDiagnostic(Range.empty, diag)]));
