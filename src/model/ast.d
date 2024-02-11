module model.ast;

@safe @nogc pure nothrow:

import model.diag : ReadFileDiag;
import model.model : AssertOrForbidKind, FunKind, ImportFileType, stringOfVarKindLowerCase, VarKind, Visibility;
import model.parseDiag : ParseDiag, ParseDiagnostic;
import util.alloc.alloc : Alloc;
import util.col.array : arrayOfSingle, exists, isEmpty, newSmallArray, sizeEq, SmallArray;
import util.conv : safeToUint;
import util.memory : allocate;
import util.opt : force, has, none, Opt, optIf, optOrDefault, some;
import util.sourceRange : combineRanges, Pos, Range, rangeOfStartAndLength;
import util.string : SmallString;
import util.symbol : AllSymbols, Symbol, symbol, symbolSize;
import util.union_ : TaggedUnion, Union;
import util.uri : AllUris, Path, pathLength, RelPath, relPathLength;
import util.util : stringOfEnum;

immutable struct NameAndRange {
	@safe @nogc pure nothrow:

	Symbol name;
	// Range length is given by size of name
	Pos start;

	this(Pos s, Symbol n) {
		name = n;
		start = s;
	}

	Range range(in AllSymbols allSymbols) scope =>
		rangeOfStartAndLength(start, symbolSize(allSymbols, name));
}
static assert(NameAndRange.sizeof == ulong.sizeof * 2);

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

		Range range(in AllSymbols allSymbols) scope =>
			combineRanges(returnType.range(allSymbols), paramsRange);
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

		Range range(in AllSymbols allSymbols) scope =>
			Range(v.range(allSymbols).start, safeToUint(k.range(allSymbols).end + "]".length));
	}

	immutable struct SuffixName {
		@safe @nogc pure nothrow:
		TypeAst left;
		NameAndRange name;

		Range range(in AllSymbols allSymbols) scope =>
			combineRanges(left.range(allSymbols), suffixRange(allSymbols));
		Range suffixRange(in AllSymbols allSymbols) scope =>
			name.range(allSymbols);
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
		TypeAst* left;
		Pos suffixPos;
		Kind kind;

		Range range(in AllSymbols allSymbols) scope =>
			Range(left.range(allSymbols).start, suffixEnd);
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

	mixin Union!(Bogus, Fun*, Map*, NameAndRange, SuffixName*, SuffixSpecial, Tuple);

	Range range(in AllSymbols allSymbols) scope =>
		matchIn!Range(
			(in TypeAst.Bogus x) => x.range,
			(in TypeAst.Fun x) => x.range(allSymbols),
			(in TypeAst.Map x) => x.range(allSymbols),
			(in NameAndRange x) => x.range(allSymbols),
			(in TypeAst.SuffixName x) => x.range(allSymbols),
			(in TypeAst.SuffixSpecial x) => x.range(allSymbols),
			(in TypeAst.Tuple x) => x.range);
	Range nameRangeOrRange(in AllSymbols allSymbols) scope =>
		matchIn!Range(
			(in TypeAst.Bogus x) => x.range,
			(in TypeAst.Fun x) => x.kindRange,
			(in TypeAst.Map x) => x.range(allSymbols),
			(in NameAndRange x) => x.range(allSymbols),
			(in TypeAst.SuffixName x) => x.suffixRange(allSymbols),
			(in TypeAst.SuffixSpecial x) => x.suffixRange,
			(in TypeAst.Tuple x) => x.range);
}
static assert(TypeAst.sizeof == ulong.sizeof * 3);

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
	ExprAst[2] leftAndRight;

	ref ExprAst left() scope return =>
		leftAndRight[0];
	ref ExprAst right() scope return =>
		leftAndRight[1];

	Range keywordRange(in AllSymbols allSymbols) =>
		rangeOfStartAndLength(funName.range(allSymbols).end, ":=".length);
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
	// For some reason we have to break this up to get the struct size lower
	//immutable NameAndRange funName;
	Symbol funNameName;
	Pos funNameStart;
	Style style;
	Opt!(TypeAst*) typeArg;
	SmallArray!ExprAst args_;

	ExprAst[] args() return scope =>
		args_;

	this(Style s, NameAndRange f, ExprAst[] a, Opt!(TypeAst*) t = none!(TypeAst*)) {
		funNameName = f.name;
		funNameStart = f.start;
		style = s;
		typeArg = t;
		args_ = a;
	}

	NameAndRange funName() scope =>
		NameAndRange(funNameStart, funNameName);
	Range nameRange(in AllSymbols allSymbols, in ExprAst* ast) scope =>
		style == Style.comma ? ast.range : funName.range(allSymbols);
}
static assert(CallAst.sizeof == ulong.sizeof * 4);

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

immutable struct ElifOrElseKeyword {
	@safe @nogc pure nothrow:
	enum Kind { elif, else_ }
	Kind kind;
	Pos pos;

	static assert("elif".length == "else".length);
	Range range() scope =>
		rangeOfStartAndLength(pos, "else".length);
}

immutable struct IfAst {
	@safe @nogc pure nothrow:
	ExprAst cond;
	ExprAst then;
	Opt!ElifOrElseKeyword elifOrElseKeyword;
	// May be EmptyAst
	ExprAst else_;

	Range ifKeywordRange(in ExprAst* ast) scope {
		assert(ast.kind.as!(IfAst*) == &this);
		return ast.range[0 .. "if".length];
	}
	bool hasElse() scope =>
		!else_.kind.isA!EmptyAst;
}

immutable struct IfOptionAst {
	@safe @nogc pure nothrow:
	DestructureAst destructure;
	Pos questionEqualsPos;
	ExprAst option;
	ExprAst then;
	// May be EmptyAst
	ExprAst else_;

	Range ifKeywordRange(in ExprAst* ast) {
		assert(ast.kind.as!(IfOptionAst*) == &this);
		return ast.range[0 .. "if".length];
	}
	Range questionEqualsRange() scope =>
		rangeOfStartAndLength(questionEqualsPos, "?=".length);
	bool hasElse() scope =>
		!else_.kind.isA!EmptyAst;
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

		Range range(in AllSymbols allSymbols) scope =>
			Range(name.start, (
				has(type)
				? force(type).range(allSymbols)
				: optOrDefault!Range(mutRange, () => name.range(allSymbols))
			).end);
		Range nameRange(in AllSymbols allSymbols) scope =>
			name.range(allSymbols);
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

	Range range(in AllSymbols allSymbols) scope =>
		matchIn!Range(
			(in DestructureAst.Single x) {
				Range name = x.name.range(allSymbols);
				return has(x.type)
					? Range(name.start, force(x.type).range(allSymbols).end)
					: name;
			},
			(in DestructureAst.Void x) =>
				x.range,
			(in DestructureAst[] parts) =>
				Range(parts[0].range(allSymbols).start, parts[$ - 1].range(allSymbols).end));
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

immutable struct LiteralIntAst {
	long value;
	bool overflow;
}

immutable struct LiteralNatAst {
	ulong value;
	bool overflow;
}

immutable struct LiteralNatAndRange {
	Range range;
	LiteralNatAst nat;
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

immutable struct LoopUntilAst {
	@safe @nogc pure nothrow:
	ExprAst condition;
	ExprAst body_;

	Range keywordRange(in ExprAst* source) scope {
		assert(source.kind.as!(LoopUntilAst*) == &this);
		return source.range[0 .. "until".length];
	}
}

immutable struct LoopWhileAst {
	@safe @nogc pure nothrow:
	ExprAst condition;
	ExprAst body_;

	Range keywordRange(in ExprAst* source) scope {
		assert(source.kind.as!(LoopWhileAst*) == &this);
		return source.range[0 .. "while".length];
	}
}

immutable struct MatchAst {
	@safe @nogc pure nothrow:

	immutable struct CaseAst {
		@safe @nogc pure nothrow:

		Pos keywordPos;
		NameAndRange memberName;
		Opt!DestructureAst destructure;
		ExprAst then;

		Range memberNameRange(in AllSymbols allSymbols) scope =>
			memberName.range(allSymbols);

		Range keywordAndMemberNameRange(in AllSymbols allSymbols) scope =>
			Range(keywordPos, memberNameRange(allSymbols).end);
	}

	ExprAst matched;
	CaseAst[] cases;

	Range keywordRange(in ExprAst source) scope {
		assert(source.kind.as!(MatchAst*) == &this);
		return rangeOfStartAndLength(source.range.start, "match".length);
	}
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

immutable struct TernaryAst {
	@safe @nogc pure nothrow:
	ExprAst cond;
	Pos questionPos;
	ExprAst then;
	Opt!Pos colonPos;
	// May be EmptyAst
	ExprAst else_;

	Range questionRange() scope =>
		rangeOfStartAndLength(questionPos, "?".length);
	Opt!Range colonRange() scope =>
		has(colonPos)
			? some(rangeOfStartAndLength(force(colonPos), ":".length))
			: none!Range;
	bool hasElse() scope =>
		!else_.kind.isA!EmptyAst;
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

immutable struct UnlessAst {
	@safe @nogc pure nothrow:
	ExprAst cond;
	ExprAst body_;
	ExprAst emptyElse; // Always EmptyAst

	Range keywordRange(in ExprAst* ast) {
		assert(ast.kind.as!(UnlessAst*) == &this);
		return ast.range[0 .. "unless".length];
	}
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
		AssignmentCallAst*,
		BogusAst,
		CallAst,
		CallNamedAst,
		DoAst,
		EmptyAst,
		ForAst*,
		IdentifierAst,
		IfAst*,
		IfOptionAst*,
		InterpolatedAst,
		LambdaAst*,
		LetAst*,
		LiteralFloatAst,
		LiteralIntAst,
		LiteralNatAst,
		LiteralStringAst,
		LoopAst*,
		LoopBreakAst*,
		LoopContinueAst,
		LoopUntilAst*,
		LoopWhileAst*,
		MatchAst*,
		ParenthesizedAst*,
		PtrAst*,
		SeqAst*,
		SharedAst*,
		TernaryAst*,
		ThenAst*,
		ThrowAst*,
		TrustedAst*,
		TypedAst*,
		UnlessAst*,
		WithAst*);
}
static assert(ExprAstKind.sizeof <= 5 * ulong.sizeof);

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
static assert(ParamsAst.sizeof == 8);

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
	Range nameRange(in AllSymbols allSymbols) scope =>
		nameAndRange.range(allSymbols);
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

	Range nameRange(in AllSymbols allSymbols) scope =>
		name.range(allSymbols);
	Range keywordRange() scope =>
		rangeOfStartAndLength(keywordPos, "alias".length);
	Opt!VisibilityAndRange visibility() scope =>
		getVisibilityAndRange(range.start, visibility_);
}

Range typeParamsRange(in AllSymbols allSymbols, in SmallArray!NameAndRange typeParams) {
	assert(!isEmpty(typeParams));
	return combineRanges(
		typeParams[0].range(allSymbols),
		typeParams[$ - 1].range(allSymbols));
}

immutable struct ModifierAst {
	@safe @nogc pure nothrow:

	immutable struct Keyword {
		@safe @nogc pure nothrow:

		Opt!TypeAst typeArg;
		Pos keywordPos;
		ModifierKeyword keyword;

		Range range(in AllSymbols allSymbols) scope =>
			has(typeArg)
				? combineRanges(force(typeArg).range(allSymbols), keywordRange)
				: keywordRange;
		Range keywordRange() scope =>
			rangeOfStartAndLength(keywordPos, stringOfModifierKeyword(keyword).length);
	}

	mixin Union!(Keyword, SpecUseAst);

	Range range(in AllSymbols allSymbols) scope =>
		matchIn!Range(
			(in Keyword x) =>
				x.range(allSymbols),
			(in SpecUseAst x) =>
				x.range(allSymbols));
}

immutable struct SpecUseAst {
	@safe @nogc pure nothrow:
	Opt!TypeAst typeArg;
	NameAndRange name;

	Range range(in AllSymbols allSymbols) scope =>
		has(typeArg)
			? combineRanges(force(typeArg).range(allSymbols), name.range(allSymbols))
			: name.range(allSymbols);
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
	shared_,
	storage,
	summon,
	trusted,
	unsafe,
}

immutable struct LiteralIntOrNat {
	Range range;
	LiteralIntOrNatKind kind;
}

immutable struct LiteralIntOrNatKind {
	mixin Union!(LiteralIntAst, LiteralNatAst);
}

immutable struct StructBodyAst {
	immutable struct Builtin {}
	immutable struct Enum {
		Opt!ParamsAst params;
		SmallArray!EnumOrFlagsMemberAst members;
	}
	immutable struct Extern {
		Opt!(LiteralNatAndRange*) size;
		Opt!(LiteralNatAndRange*) alignment;
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
	Opt!LiteralIntOrNat value;

	NameAndRange nameAndRange() scope =>
		NameAndRange(range.start, name);
	Range nameRange(in AllSymbols allSymbols) scope =>
		nameAndRange.range(allSymbols);
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

	Range nameRange(in AllSymbols allSymbols) scope =>
		name.range(allSymbols);
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

	Range nameRange(in AllSymbols allSymbols) scope =>
		name.range(allSymbols);
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

	Range nameRange(in AllSymbols allSymbols) scope =>
		name.range(allSymbols);
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

	Range nameRange(in AllSymbols allSymbols) scope =>
		name.range(allSymbols);
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

	Range nameRange(in AllSymbols allSymbols) scope =>
		name.range(allSymbols);
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

	Range pathRange(in AllUris allUris) scope =>
		rangeOfStartAndLength(range.start, pathOrRelPathLength(allUris, path));
}

immutable struct PathOrRelPath {
	mixin TaggedUnion!(Path, RelPath);
}
private size_t pathOrRelPathLength(in AllUris allUris, in PathOrRelPath a) =>
	a.matchIn!size_t(
		(in Path x) =>
			pathLength(allUris, x),
		(in RelPath x) =>
			relPathLength(allUris, x));

immutable struct ImportOrExportAstKind {
	immutable struct ModuleWhole {}
	immutable struct File {
		NameAndRange name;
		TypeAst typeAst;
		ImportFileType type;
	}
	mixin TaggedUnion!(ModuleWhole, SmallArray!NameAndRange, File*);
}

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

private FileAst* fileAstForDiags(ref Alloc alloc, SmallArray!ParseDiagnostic diags) =>
	// Make sure the dummy AST doesn't have implicit imports
	allocate(alloc, FileAst(diags, noStd: true));

FileAst* fileAstForReadFileDiag(ref Alloc alloc, ReadFileDiag a) =>
	fileAstForDiags(alloc, newSmallArray(alloc, [ParseDiagnostic(Range.empty, ParseDiag(a))]));
