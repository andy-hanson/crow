module model.ast;

@safe @nogc pure nothrow:

import model.diag : ReadFileDiag;
import model.model : AssertOrForbidKind, FunKind, ImportFileType, stringOfVarKindLowerCase, VarKind, Visibility;
import model.parseDiag : ParseDiag, ParseDiagnostic;
import util.alloc.alloc : Alloc;
import util.col.array : arrayOfSingle, exists, isEmpty, newSmallArray, sizeEq, SmallArray;
import util.conv : safeToUint;
import util.memory : allocate;
import util.opt : force, has, none, Opt, optOrDefault, some;
import util.sourceRange : combineRanges, Pos, Range, rangeOfStartAndLength;
import util.string : SmallString;
import util.symbol : AllSymbols, Symbol, symbol, symbolSize;
import util.union_ : Union;
import util.uri : AllUris, Path, pathLength, RelPath, relPathLength;

immutable struct NameAndRange {
	@safe @nogc pure nothrow:

	Symbol name;
	// Range length is given by size of name
	Pos start;

	this(Pos s, Symbol n) {
		name = n;
		start = s;
	}
}
static assert(NameAndRange.sizeof == ulong.sizeof * 2);

Range rangeOfNameAndRange(NameAndRange a, in AllSymbols allSymbols) =>
	rangeOfStartAndLength(a.start, symbolSize(allSymbols, a.name));

immutable struct FieldMutabilityAst {
	@safe @nogc pure nothrow:

	Pos pos;
	Opt!Visibility visibility;

	Range range() =>
		rangeOfStartAndLength(pos, has(visibility) ? "-mut".length : "mut".length);
}
static assert(FieldMutabilityAst.sizeof == ulong.sizeof);

immutable struct TypeAst {
	immutable struct Bogus {
		Range range;
	}

	immutable struct Fun {
		@safe @nogc pure nothrow:

		Range range;
		FunKind kind;
		TypeAst[] returnAndParamTypes;

		TypeAst returnType() return scope =>
			returnAndParamTypes[0];
		TypeAst[] paramTypes() return scope =>
			returnAndParamTypes[1 .. $];
	}

	immutable struct Map {
		@safe @nogc pure nothrow:
		enum Kind {
			data,
			mut,
		}
		Kind kind;
		// They are actually written v[k] at the use, but applied as (k, v)
		TypeAst[2] kv;
		TypeAst k() return scope =>
			kv[0];
		TypeAst v() return scope =>
			kv[1];
	}

	immutable struct SuffixName {
		TypeAst left;
		NameAndRange name;
	}

	immutable struct SuffixSpecial {
		enum Kind {
			future,
			list,
			mutList,
			mutPtr,
			option,
			ptr,
		}
		TypeAst left;
		Pos suffixPos;
		Kind kind;
	}

	immutable struct Tuple {
		@safe @nogc pure nothrow:

		Range range;
		TypeAst[] members;

		this(Range r, TypeAst[] ms) {
			range = r;
			members = ms;
			assert(members.length >= 2);
		}
	}

	mixin Union!(Bogus, Fun*, Map*, NameAndRange, SuffixName*, SuffixSpecial*, Tuple*);
}
//TODO: static assert(TypeAst.sizeof == ulong.sizeof);

Range range(in TypeAst a, in AllSymbols allSymbols) =>
	a.matchIn!Range(
		(in TypeAst.Bogus x) => x.range,
		(in TypeAst.Fun x) => x.range,
		(in TypeAst.Map x) => range(x, allSymbols),
		(in NameAndRange x) => rangeOfNameAndRange(x, allSymbols),
		(in TypeAst.SuffixName x) => range(x, allSymbols),
		(in TypeAst.SuffixSpecial x) => range(x, allSymbols),
		(in TypeAst.Tuple x) => x.range);

Range range(in TypeAst.Map a, in AllSymbols allSymbols) =>
	Range(range(a.v, allSymbols).start, safeToUint(range(a.k, allSymbols).end + "]".length));
Range range(in TypeAst.SuffixSpecial a, in AllSymbols allSymbols) =>
	Range(range(a.left, allSymbols).start, suffixEnd(a));
Range suffixRange(in TypeAst.SuffixSpecial a) =>
	Range(a.suffixPos, suffixEnd(a));
private Pos suffixEnd(in TypeAst.SuffixSpecial a) =>
	a.suffixPos + suffixLength(a.kind);
Range range(in TypeAst.SuffixName a, in AllSymbols allSymbols) =>
	Range(range(a.left, allSymbols).start, suffixRange(a, allSymbols).end);
Range suffixRange(in TypeAst.SuffixName a, in AllSymbols allSymbols) =>
	rangeOfNameAndRange(a.name, allSymbols);

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
	}
}

Symbol symbolForTypeAstMap(TypeAst.Map.Kind a) {
	final switch (a) {
		case TypeAst.Map.Kind.data:
			return symbol!"map";
		case TypeAst.Map.Kind.mut:
			return symbol!"mut-map";
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
	}
}

immutable struct ArrowAccessAst {
	ExprAst* left;
	NameAndRange name;
}

immutable struct AssertOrForbidAst {
	AssertOrForbidKind kind;
	ExprAst condition;
	Opt!ExprAst thrown;
}

// `left := right`
immutable struct AssignmentAst {
	ExprAst left;
	Pos assignmentPos;
	ExprAst right;
}

// `left f:= right`
immutable struct AssignmentCallAst {
	@safe @nogc pure nothrow:

	ExprAst left;
	NameAndRange funName;
	ExprAst right;
}

immutable struct BogusAst {}

immutable struct CallAst {
	@safe @nogc pure nothrow:

	enum Style {
		comma, // `a, b`, `a, b, c`, etc.
		dot, // `a.b`
		emptyParens, // `()`
		infix, // `a b`, `a b c`, `a b c, d`, etc.
		prefixBang,
		prefixOperator, // `-x`, `x`, `~x`
		single, // `a<t>` (without the type arg, it would just be an Identifier)
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
}

Range nameRange(in AllSymbols allSymbols, in CallAst a) =>
	rangeOfNameAndRange(a.funName, allSymbols);

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
	DestructureAst param;
	ExprAst collection;
	ExprAst body_;
	ExprAst else_;
}

immutable struct IdentifierAst {
	Symbol name;
}

// This can come from the 'if' keyword or a ternary expression (`cond ? then : else`).
immutable struct IfAst {
	ExprAst cond;
	ExprAst then;
	// May be EmptyAst
	ExprAst else_;
}

immutable struct IfOptionAst {
	DestructureAst destructure;
	ExprAst option;
	ExprAst then;
	// May be EmptyAst
	ExprAst else_;
}

immutable struct InterpolatedAst {
	@safe @nogc pure nothrow:

	InterpolatedPart[] parts;

	this(InterpolatedPart[] p) {
		parts = p;
		assert(exists!InterpolatedPart(parts, (in InterpolatedPart part) =>
			part.isA!ExprAst));
	}
}

immutable struct InterpolatedPart {
	mixin Union!(string, ExprAst);
}

immutable struct LambdaAst {
	DestructureAst param;
	ExprAst body_;
}

immutable struct DestructureAst {
	@safe @nogc pure nothrow:

	immutable struct Single {
		NameAndRange name; // Name may be '_', meaning ignore and don't create a local
		Opt!Pos mut; // position of 'mut' keyword if it exists
		Opt!(TypeAst*) type;
	}
	// `()` is a destructure matching only void values
	immutable struct Void {
		Pos pos;
	}
	mixin Union!(Single, Void, DestructureAst[]);

	Pos pos() scope =>
		matchIn!Pos(
			(in DestructureAst.Single x) =>
				x.name.start,
			(in DestructureAst.Void x) =>
				x.pos,
			(in DestructureAst[] parts) =>
				parts[0].pos);

	Range range(in AllSymbols allSymbols) scope =>
		matchIn!Range(
			(in DestructureAst.Single x) {
				Range name = rangeOfNameAndRange(x.name, allSymbols);
				return has(x.type)
					? Range(name.start, .range(*force(x.type), allSymbols).end)
					: name;
			},
			(in DestructureAst.Void x) =>
				rangeOfStartAndLength(x.pos, "()".length),
			(in DestructureAst[] parts) =>
				Range(parts[0].range(allSymbols).start, parts[$ - 1].range(allSymbols).end));
}

Opt!Range rangeOfMutKeyword(in DestructureAst.Single a) =>
	has(a.mut)
		? some(Range(force(a.mut), force(a.mut) + safeToUint("mut".length)))
		: none!Range;

Range nameRangeOfDestructureSingle(in DestructureAst.Single a, in AllSymbols allSymbols) =>
	rangeOfNameAndRange(a.name, allSymbols);

Range rangeOfDestructureSingle(in DestructureAst.Single a, in AllSymbols allSymbols) =>
	Range(a.name.start, (
		has(a.type)
		? range(*force(a.type), allSymbols)
		: optOrDefault!Range(rangeOfMutKeyword(a), () => rangeOfNameAndRange(a.name, allSymbols))
	).end);

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

immutable struct LiteralStringAst {
	string value;
}

immutable struct LoopAst {
	ExprAst body_;
}

immutable struct LoopBreakAst {
	ExprAst value;
}

immutable struct LoopContinueAst {}

immutable struct LoopUntilAst {
	ExprAst condition;
	ExprAst body_;
}

immutable struct LoopWhileAst {
	ExprAst condition;
	ExprAst body_;
}

immutable struct MatchAst {
	immutable struct CaseAst {
		@safe @nogc pure nothrow:

		NameAndRange memberName;
		Opt!DestructureAst destructure;
		ExprAst then;

		Range memberNameRange(in AllSymbols allSymbols) scope =>
			rangeOfNameAndRange(memberName, allSymbols);
	}

	ExprAst matched;
	CaseAst[] cases;
}

immutable struct ParenthesizedAst {
	ExprAst inner;
}

immutable struct PtrAst {
	ExprAst inner;
}

immutable struct SeqAst {
	ExprAst first;
	ExprAst then;
}

immutable struct ThenAst {
	DestructureAst left;
	ExprAst futExpr;
	ExprAst then;
}

immutable struct ThrowAst {
	ExprAst thrown;
}

immutable struct TrustedAst {
	ExprAst inner;
}

// expr :: t
immutable struct TypedAst {
	ExprAst expr;
	TypeAst type;
}

immutable struct UnlessAst {
	ExprAst cond;
	ExprAst body_;
}

immutable struct WithAst {
	DestructureAst param;
	ExprAst arg;
	ExprAst body_;
	ExprAst else_;
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
	mixin Union!(SmallArray!DestructureAst, Varargs*);
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
}

immutable struct StructAliasAst {
	@safe @nogc pure nothrow:

	SmallString docComment;
	Range range;
	Opt!Visibility visibility;
	NameAndRange name;
	SmallArray!NameAndRange typeParams;
	Pos keywordPos;
	TypeAst target;

	Range keywordRange() =>
		rangeOfStartAndLength(keywordPos, "alias".length);
}

Range typeParamsRange(in AllSymbols allSymbols, in SmallArray!NameAndRange typeParams) {
	assert(!isEmpty(typeParams));
	return combineRanges(
		rangeOfNameAndRange(typeParams[0], allSymbols),
		rangeOfNameAndRange(typeParams[$ - 1], allSymbols));
}

immutable struct ModifierAst {
	@safe @nogc pure nothrow:

	immutable struct Keyword {
		@safe @nogc pure nothrow:

		Pos pos;
		ModifierKeyword kind;

		Range range() =>
			rangeOfStartAndLength(pos, stringOfModifierKeyword(kind).length);
	}

	immutable struct Extern {
		@safe @nogc pure nothrow:

		TypeAst* left;
		Pos externPos;

		Range range(in AllSymbols allSymbols) scope =>
			Range(.range(*left, allSymbols).start, suffixRange.end);
		Range suffixRange() scope =>
			rangeOfStartAndLength(externPos, "extern".length);
	}

	// TypeAst will be interpreted as a spec inst
	mixin Union!(Keyword, Extern, TypeAst);

	Range range(in AllSymbols allSymbols) scope =>
		matchIn!Range(
			(in Keyword x) =>
				x.range,
			(in Extern x) =>
				x.range(allSymbols),
			(in TypeAst x) =>
				x.range(allSymbols));
}

enum ModifierKeyword {
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
	packed,
	shared_,
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
		immutable struct Member {
			@safe @nogc pure nothrow:

			Range range;
			Symbol name;
			Opt!LiteralIntOrNat value;

			NameAndRange nameAndRange() scope =>
				NameAndRange(range.start, name);
			Range nameRange(in AllSymbols allSymbols) scope =>
				rangeOfNameAndRange(nameAndRange, allSymbols);
		}

		Opt!(TypeAst*) typeArg;
		SmallArray!Member members;
	}
	immutable struct Extern {
		Opt!(LiteralNatAst*) size;
		Opt!(LiteralNatAst*) alignment;
	}
	immutable struct Flags {
		alias Member = Enum.Member;
		Opt!(TypeAst*) typeArg;
		SmallArray!Member members;
	}
	immutable struct Record {
		immutable struct Field {
			Range range;
			Opt!Visibility visibility;
			NameAndRange name;
			Opt!FieldMutabilityAst mutability;
			TypeAst type;
		}
		SmallArray!Field fields;
	}
	immutable struct Union {
		immutable struct Member {
			@safe @nogc pure nothrow:

			Range range;
			Symbol name;
			Opt!TypeAst type;

			NameAndRange nameAndRange() scope =>
				NameAndRange(range.start, name);
		}
		SmallArray!Member members;
	}

	mixin .Union!(Builtin, Enum, Extern, Flags, Record, Union);
}
static assert(StructBodyAst.sizeof <= 24);

immutable struct StructDeclAst {
	@safe @nogc pure nothrow:

	SmallString docComment;
	// Range starts at the visibility
	Range range;
	Opt!Visibility visibility;
	NameAndRange name;
	SmallArray!NameAndRange typeParams;
	Pos keywordPos;
	SmallArray!ModifierAst modifiers;
	StructBodyAst body_;

	Range keywordRange() scope =>
		rangeOfStartAndLength(keywordPos, keywordForStructBody(body_).length);
}

Range nameRange(in AllSymbols allSymbols, in StructDeclAst a) =>
	rangeOfNameAndRange(a.name, allSymbols);

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

immutable struct SpecBodyAst {
	immutable struct Builtin {}
	mixin Union!(Builtin, SmallArray!SpecSigAst);
}
static assert(SpecBodyAst.sizeof == ulong.sizeof);

immutable struct SpecDeclAst {
	@safe @nogc pure nothrow:

	Range range;
	SmallString docComment;
	Opt!Visibility visibility;
	NameAndRange name;
	SmallArray!NameAndRange typeParams;
	Pos specKeywordPos;
	SmallArray!TypeAst parents;
	SpecBodyAst body_;

	Range keywordRange() scope =>
		rangeOfStartAndLength(specKeywordPos, keywordForSpecBody(body_).length);
}

Range nameRange(in AllSymbols allSymbols, in SpecDeclAst a) =>
	rangeOfNameAndRange(a.name, allSymbols);

private string keywordForSpecBody(in SpecBodyAst a) =>
	a.matchIn!string(
		(in SpecBodyAst.Builtin) =>
			"builtin-spec",
		(in SpecSigAst[]) =>
			"spec");

immutable struct FunDeclAst {
	Range range;
	SmallString docComment;
	Opt!Visibility visibility;
	NameAndRange name;
	SmallArray!NameAndRange typeParams;
	TypeAst returnType;
	ParamsAst params;
	SmallArray!ModifierAst modifiers;
	ExprAst body_; // EmptyAst if missing
}

Range nameRange(in AllSymbols allSymbols, in FunDeclAst a) =>
	rangeOfNameAndRange(a.name, allSymbols);

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
		case ModifierKeyword.packed:
			return "packed";
		case ModifierKeyword.shared_:
			return "shared";
		case ModifierKeyword.summon:
			return "summon";
		case ModifierKeyword.trusted:
			return "trusted";
		case ModifierKeyword.unsafe:
			return "unsafe";
	}
}
Symbol symbolOfModifierKeyword(ModifierKeyword a) {
	final switch (a) {
		static foreach (ubyte index, string member; __traits(allMembers, ModifierKeyword)) {
			case __traits(getMember, ModifierKeyword, member):
				return symbol!(stringOfModifierKeyword(__traits(getMember, ModifierKeyword, member)));
		}
	}
}

immutable struct TestAst {
	Range range;
	ExprAst body_; // EmptyAst if missing
}

// 'global' or 'thread-local'
immutable struct VarDeclAst {
	@safe @nogc pure nothrow:

	Range range;
	SmallString docComment;
	Opt!Visibility visibility;
	NameAndRange name;
	SmallArray!NameAndRange typeParams; // This will be a compile error
	Pos keywordPos;
	VarKind kind;
	TypeAst type;
	SmallArray!ModifierAst modifiers; // Any but 'extern' will be a compile error

	Range keywordRange() =>
		rangeOfStartAndLength(keywordPos, stringOfVarKindLowerCase(kind).length);
}

immutable struct ImportOrExportAst {
	Range range;
	// Does not include the extension (which is only allowed for file imports)
	PathOrRelPath path;
	ImportOrExportAstKind kind;
}
Range pathRange(in AllUris allUris, in ImportOrExportAst a) =>
	rangeOfStartAndLength(a.range.start, pathOrRelPathLength(allUris, a.path));

immutable struct PathOrRelPath {
	mixin Union!(Path, RelPath);
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
	mixin Union!(ModuleWhole, SmallArray!NameAndRange, File*);
}
static assert(ImportOrExportAstKind.sizeof == ulong.sizeof);

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
