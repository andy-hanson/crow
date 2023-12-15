module model.ast;

@safe @nogc pure nothrow:

import model.diag : ReadFileDiag;
import model.model : AssertOrForbidKind, FunKind, ImportFileType, VarKind;
import model.parseDiag : ParseDiag, ParseDiagnostic;
import util.alloc.alloc : Alloc;
import util.col.arr : arrayOfSingle, SmallArray;
import util.col.arrUtil : arrLiteral, exists;
import util.col.str : SafeCStr, safeCStr;
import util.conv : safeToUint;
import util.memory : allocate;
import util.opt : force, has, none, Opt, optOrDefault, some;
import util.sourceRange : Pos, Range, rangeOfStartAndLength, rangeOfStartAndName;
import util.sym : AllSymbols, Sym, sym;
import util.union_ : Union;
import util.uri : AllUris, Path, pathLength, RelPath, relPathLength;
import util.util : unreachable;

immutable struct NameAndRange {
	@safe @nogc pure nothrow:

	Sym name;
	// Range length is given by size of name
	Pos start;

	this(Pos s, Sym n) {
		name = n;
		start = s;
	}
}
static assert(NameAndRange.sizeof == ulong.sizeof * 2);

Range rangeOfNameAndRange(NameAndRange a, in AllSymbols allSymbols) =>
	rangeOfStartAndName(a.start, a.name, allSymbols);

enum ExplicitVisibility {
	default_,
	private_,
	internal,
	public_,
}

immutable struct FieldMutabilityAst {
	enum Kind {
		private_,
		public_,
	}

	Pos pos;
	Kind kind;
}

string stringOfFieldMutabilityAstKind(FieldMutabilityAst.Kind a) {
	final switch (a) {
		case FieldMutabilityAst.Kind.private_:
			return "-mut";
		case FieldMutabilityAst.Kind.public_:
			return "mut";
	}
}

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

Sym symForTypeAstMap(TypeAst.Map.Kind a) {
	final switch (a) {
		case TypeAst.Map.Kind.data:
			return sym!"map";
		case TypeAst.Map.Kind.mut:
			return sym!"mut-map";
	}
}

Sym symForTypeAstSuffix(TypeAst.SuffixSpecial.Kind a) {
	final switch (a) {
		case TypeAst.SuffixSpecial.Kind.future:
			return sym!"future";
		case TypeAst.SuffixSpecial.Kind.list:
			return sym!"list";
		case TypeAst.SuffixSpecial.Kind.mutList:
			return sym!"mut-list";
		case TypeAst.SuffixSpecial.Kind.mutPtr:
			return sym!"mut-pointer";
		case TypeAst.SuffixSpecial.Kind.option:
			return sym!"option";
		case TypeAst.SuffixSpecial.Kind.ptr:
			return sym!"const-pointer";
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
	Sym funNameName;
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

// Used for implicit 'else ()' or implicit '()' after a Let
immutable struct EmptyAst {}

immutable struct ForAst {
	DestructureAst param;
	ExprAst collection;
	ExprAst body_;
	ExprAst else_;
}

immutable struct IdentifierAst {
	Sym name;
}

immutable struct IfAst {
	ExprAst cond;
	ExprAst then;
	ExprAst else_;
}

immutable struct IfOptionAst {
	DestructureAst destructure;
	ExprAst option;
	ExprAst then;
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

		Range range;
		Sym memberName;
		Opt!DestructureAst destructure;
		ExprAst then;

		Range memberNameRange(ref const AllSymbols allSymbols) scope =>
			rangeOfStartAndName(range.start + safeToUint("as ".length), memberName, allSymbols);
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

	SafeCStr docComment;
	Range range;
	Sym name;
	TypeAst returnType;
	ParamsAst params;

	NameAndRange nameAndRange() scope =>
		NameAndRange(range.start, name);
}

immutable struct StructAliasAst {
	SafeCStr docComment;
	Range range;
	ExplicitVisibility visibility;
	NameAndRange name;
	SmallArray!NameAndRange typeParams;
	TypeAst target;
}

immutable struct ModifierAst {
	enum Kind {
		byRef,
		byVal,
		data,
		extern_,
		forceShared,
		mut,
		newPublic,
		newPrivate,
		packed,
		shared_,
	}

	Pos pos;
	Kind kind;
}

Range rangeOfModifierAst(ModifierAst a, ref const AllSymbols allSymbols) =>
	rangeOfStartAndName(a.pos, symOfModifierKind(a.kind), allSymbols);

immutable struct LiteralIntOrNat {
	mixin Union!(LiteralIntAst, LiteralNatAst);
}

immutable struct StructDeclAst {
	immutable struct Body {
		immutable struct Builtin {}
		immutable struct Enum {
			immutable struct Member {
				Range range;
				Sym name;
				Opt!LiteralIntOrNat value;
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
				ExplicitVisibility visibility;
				NameAndRange name;
				Opt!FieldMutabilityAst mutability;
				TypeAst type;
			}
			SmallArray!Field fields;
		}
		immutable struct Union {
			immutable struct Member {
				Range range;
				Sym name;
				Opt!TypeAst type;
			}
			Member[] members;
		}

		mixin .Union!(Builtin, Enum, Extern, Flags, Record, Union);
	}
	static assert(Body.sizeof <= 24);

	SafeCStr docComment;
	// Range starts at the visibility
	Range range;
	ExplicitVisibility visibility;
	NameAndRange name;
	SmallArray!NameAndRange typeParams;
	Pos keywordPos;
	SmallArray!ModifierAst modifiers;
	Body body_;
}

Range keywordRange(in AllSymbols allSymbols, in StructDeclAst a) =>
	rangeOfNameAndRange(NameAndRange(a.keywordPos, keywordForStructBody(a.body_)), allSymbols);

Range nameRange(in AllSymbols allSymbols, in StructDeclAst a) =>
	rangeOfNameAndRange(a.name, allSymbols);

private Sym keywordForStructBody(in StructDeclAst.Body a) =>
	a.matchIn!Sym(
		(in StructDeclAst.Body.Builtin) =>
			sym!"builtin",
		(in StructDeclAst.Body.Enum) =>
			sym!"enum",
		(in StructDeclAst.Body.Extern) =>
			sym!"extern",
		(in StructDeclAst.Body.Flags) =>
			sym!"flags",
		(in StructDeclAst.Body.Record) =>
			sym!"record",
		(in StructDeclAst.Body.Union) =>
			sym!"union");

immutable struct SpecBodyAst {
	immutable struct Builtin {}
	mixin Union!(Builtin, SmallArray!SpecSigAst);
}
static assert(SpecBodyAst.sizeof == ulong.sizeof);

immutable struct SpecDeclAst {
	Range range;
	SafeCStr docComment;
	ExplicitVisibility visibility;
	NameAndRange name;
	SmallArray!NameAndRange typeParams;
	SmallArray!TypeAst parents;
	SpecBodyAst body_;
}

Range nameRange(in AllSymbols allSymbols, in SpecDeclAst a) =>
	rangeOfNameAndRange(a.name, allSymbols);

immutable struct FunDeclAst {
	Range range;
	SafeCStr docComment;
	ExplicitVisibility visibility;
	NameAndRange name;
	SmallArray!NameAndRange typeParams;
	TypeAst returnType;
	ParamsAst params;
	SmallArray!FunModifierAst modifiers;
	Opt!ExprAst body_;
}

Range nameRange(in AllSymbols allSymbols, in FunDeclAst a) =>
	rangeOfNameAndRange(a.name, allSymbols);

immutable struct FunModifierAst {
	@safe @nogc pure nothrow:

	immutable struct Special {
		@safe @nogc pure nothrow:

		enum Flags {
			none = 0,
			builtin = 1,
			// It's a compile error to have extern without a library name,
			// so those will usually be a Extern instead
			extern_ = 0b10,
			bare = 0b100,
			summon = 0b1000,
			trusted = 0b100_0000,
			unsafe = 0b1000_0000,
			forceCtx = 0b1_0000_0000,
		}
		Pos pos;
		Flags flag;

		Range range() =>
			rangeOfStartAndLength(pos, stringOfSpecialFlag(flag).length);
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
	mixin Union!(Special, Extern, TypeAst);
}

Range range(in FunModifierAst a, in AllSymbols allSymbols) =>
	a.matchIn!Range(
		(in FunModifierAst.Special x) =>
			x.range,
		(in FunModifierAst.Extern x) =>
			x.range(allSymbols),
		(in TypeAst x) =>
			x.range(allSymbols));

string stringOfSpecialFlag(FunModifierAst.Special.Flags a) {
	switch (a) {
		case FunModifierAst.Special.Flags.bare:
			return "bare";
		case FunModifierAst.Special.Flags.builtin:
			return "builtin";
		case FunModifierAst.Special.Flags.extern_:
			return "extern";
		case FunModifierAst.Special.Flags.summon:
			return "summon";
		case FunModifierAst.Special.Flags.trusted:
			return "trusted";
		case FunModifierAst.Special.Flags.unsafe:
			return "unsafe";
		case FunModifierAst.Special.Flags.forceCtx:
			return "force-ctx";
		default:
			return unreachable!string;
	}
}

immutable struct TestAst {
	Opt!ExprAst body_;
}

// 'extern' or 'thread-local'
immutable struct VarDeclAst {
	Range range;
	SafeCStr docComment;
	ExplicitVisibility visibility;
	NameAndRange name;
	NameAndRange[] typeParams; // This will be a compile error
	Pos kindPos;
	VarKind kind;
	TypeAst type;
	FunModifierAst[] modifiers; // Any but 'extern' will be a compile error
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
		ImportFileType type;
	}
	mixin Union!(ModuleWhole, SmallArray!NameAndRange, File*);
}
static assert(ImportOrExportAstKind.sizeof == ulong.sizeof);

immutable struct ImportsOrExportsAst {
	Range range;
	ImportOrExportAst[] paths;
}

immutable struct FileAst {
	ParseDiagnostic[] parseDiagnostics;
	SafeCStr docComment;
	bool noStd;
	Opt!ImportsOrExportsAst imports;
	Opt!ImportsOrExportsAst reExports;
	SpecDeclAst[] specs;
	StructAliasAst[] structAliases;
	StructDeclAst[] structs;
	FunDeclAst[] funs;
	TestAst[] tests;
	VarDeclAst[] vars;
}

private FileAst* fileAstForDiags(ref Alloc alloc, ParseDiagnostic[] diags) =>
	allocate(alloc, FileAst(
		diags,
		safeCStr!"",
		false,
		none!ImportsOrExportsAst,
		none!ImportsOrExportsAst,
		[], [], [], [], [], []));

FileAst* fileAstForReadFileDiag(ref Alloc alloc, ReadFileDiag a) =>
	fileAstForDiags(alloc, arrLiteral(alloc, [ParseDiagnostic(Range.empty, ParseDiag(a))]));

Sym symOfModifierKind(ModifierAst.Kind a) {
	final switch (a) {
		case ModifierAst.Kind.byRef:
			return sym!"by-ref";
		case ModifierAst.Kind.byVal:
			return sym!"by-val";
		case ModifierAst.Kind.data:
			return sym!"data";
		case ModifierAst.Kind.extern_:
			return sym!"extern";
		case ModifierAst.Kind.forceShared:
			return sym!"force-shared";
		case ModifierAst.Kind.mut:
			return sym!"mut";
		case ModifierAst.Kind.newPrivate:
			return sym!"-new";
		case ModifierAst.Kind.newPublic:
			return sym!"+new";
		case ModifierAst.Kind.packed:
			return sym!"packed";
		case ModifierAst.Kind.shared_:
			return sym!"shared";
	}
}
