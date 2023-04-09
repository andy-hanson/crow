module frontend.parse.ast;

@safe @nogc pure nothrow:

import model.model :
	AssertOrForbidKind,
	FieldMutability,
	FunKind,
	ImportFileType,
	symOfAssertOrForbidKind,
	symOfFieldMutability,
	symOfFunKind,
	symOfImportFileType,
	VarKind,
	Visibility;
import model.reprModel : reprVisibility;
import util.alloc.alloc : Alloc;
import util.col.arr : empty, SmallArray;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : exists;
import util.col.str : SafeCStr, safeCStr, safeCStrIsEmpty;
import util.conv : safeToUint;
import util.opt : force, has, none, Opt, some;
import util.path : PathOrRelPath, pathOrRelPathToStr, AllPaths;
import util.repr :
	NameAndRepr,
	nameAndRepr,
	Repr,
	reprArr,
	reprBool,
	reprFloat,
	reprInt,
	reprNamedRecord,
	reprNat,
	reprOpt,
	reprRecord,
	reprStr,
	reprSym;
import util.sourceRange : Pos, rangeOfStartAndLength, rangeOfStartAndName, RangeWithinFile, reprRangeWithinFile;
import util.sym : AllSymbols, Sym, sym;
import util.union_ : Union;
import util.util : unreachable, verify;

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

RangeWithinFile rangeOfNameAndRange(NameAndRange a, ref const AllSymbols allSymbols) =>
	rangeOfStartAndName(a.start, a.name, allSymbols);

immutable struct TypeAst {
	immutable struct Bogus {
		RangeWithinFile range;
	}

	immutable struct Fun {
		RangeWithinFile range;
		FunKind kind;
		TypeAst[] returnAndParamTypes;
	}

	immutable struct Map {
		enum Kind {
			data,
			mut,
		}
		Kind kind;
		TypeAst v;
		TypeAst k;
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

		RangeWithinFile range;
		TypeAst[] members;

		this(RangeWithinFile r, TypeAst[] ms) {
			range = r;
			members = ms;
			verify(members.length >= 2);
		}
	}

	mixin Union!(Bogus, Fun*, Map*, NameAndRange, SuffixName*, SuffixSpecial*, Tuple*);
}
//TODO: static assert(TypeAst.sizeof == ulong.sizeof);

RangeWithinFile range(in TypeAst a, in AllSymbols allSymbols) =>
	a.matchIn!RangeWithinFile(
		(in TypeAst.Bogus x) => x.range,
		(in TypeAst.Fun x) => x.range,
		(in TypeAst.Map x) => range(x, allSymbols),
		(in NameAndRange x) => rangeOfNameAndRange(x, allSymbols),
		(in TypeAst.SuffixName x) => range(x, allSymbols),
		(in TypeAst.SuffixSpecial x) => range(x, allSymbols),
		(in TypeAst.Tuple x) => x.range);

RangeWithinFile range(in TypeAst.Map a, in AllSymbols allSymbols) =>
	RangeWithinFile(range(a.v, allSymbols).start, safeToUint(range(a.k, allSymbols).end + "]".length));
RangeWithinFile range(in TypeAst.SuffixSpecial a, in AllSymbols allSymbols) =>
	RangeWithinFile(range(a.left, allSymbols).start, suffixEnd(a));
RangeWithinFile suffixRange(in TypeAst.SuffixSpecial a) =>
	RangeWithinFile(a.suffixPos, suffixEnd(a));
private Pos suffixEnd(in TypeAst.SuffixSpecial a) =>
	a.suffixPos + suffixLength(a.kind);
RangeWithinFile range(in TypeAst.SuffixName a, in AllSymbols allSymbols) =>
	RangeWithinFile(range(a.left, allSymbols).start, suffixRange(a, allSymbols).end);
RangeWithinFile suffixRange(in TypeAst.SuffixName a, in AllSymbols allSymbols) =>
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
		verify(exists!InterpolatedPart(parts, (in InterpolatedPart part) =>
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

	// `()` is a destructure matcing only void values
	immutable struct Single {
		NameAndRange name; // Name may be '_', meaning ignore and don't create a local
		bool mut;
		Opt!(TypeAst*) type;
	}
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

	RangeWithinFile range(in AllSymbols allSymbols) scope =>
		matchIn!RangeWithinFile(
			(in DestructureAst.Single x) {
				RangeWithinFile name = rangeOfNameAndRange(x.name, allSymbols);
				return has(x.type)
					? RangeWithinFile(name.start, .range(*force(x.type), allSymbols).end)
					: name;
			},
			(in DestructureAst.Void x) =>
				rangeOfStartAndLength(x.pos, "()".length),
			(in DestructureAst[] parts) =>
				RangeWithinFile(parts[0].range(allSymbols).start, parts[$ - 1].range(allSymbols).end));
}

immutable struct LetAst {
	DestructureAst destructure;
	ExprAst initializer;
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

		RangeWithinFile range;
		Sym memberName;
		Opt!DestructureAst destructure;
		ExprAst then;

		RangeWithinFile memberNameRange(ref const AllSymbols allSymbols) scope =>
			rangeOfStartAndName(safeToUint(range.start + "as ".length), memberName, allSymbols);
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
	RangeWithinFile range;
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

immutable struct SpecSigAst {
	SafeCStr docComment;
	RangeWithinFile range;
	Sym name;
	TypeAst returnType;
	ParamsAst params;
}

immutable struct StructAliasAst {
	RangeWithinFile range;
	SafeCStr docComment;
	Visibility visibility;
	Sym name;
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

RangeWithinFile rangeOfModifierAst(ModifierAst a, ref const AllSymbols allSymbols) =>
	rangeOfStartAndName(a.pos, symOfModifierKind(a.kind), allSymbols);

immutable struct LiteralIntOrNat {
	mixin Union!(LiteralIntAst, LiteralNatAst);
}

immutable struct StructDeclAst {
	immutable struct Body {
		immutable struct Builtin {}
		immutable struct Enum {
			immutable struct Member {
				RangeWithinFile range;
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
				RangeWithinFile range;
				Visibility visibility;
				Sym name;
				FieldMutability mutability;
				TypeAst type;
			}
			SmallArray!Field fields;
		}
		immutable struct Union {
			immutable struct Member {
				RangeWithinFile range;
				Sym name;
				Opt!TypeAst type;
			}
			Member[] members;
		}

		mixin .Union!(Builtin, Enum, Extern, Flags, Record, Union);
	}
	static assert(Body.sizeof <= 24);

	RangeWithinFile range;
	SafeCStr docComment;
	Visibility visibility;
	Sym name; // start is range.start
	SmallArray!NameAndRange typeParams;
	SmallArray!ModifierAst modifiers;
	Body body_;
}
static assert(StructDeclAst.sizeof <= 80);

immutable struct SpecBodyAst {
	immutable struct Builtin {}
	mixin Union!(Builtin, SmallArray!SpecSigAst);
}
static assert(SpecBodyAst.sizeof == ulong.sizeof);

immutable struct SpecDeclAst {
	RangeWithinFile range;
	SafeCStr docComment;
	Visibility visibility;
	Sym name;
	SmallArray!NameAndRange typeParams;
	SmallArray!TypeAst parents;
	SpecBodyAst body_;
}

immutable struct FunDeclAst {
	RangeWithinFile range;
	SafeCStr docComment;
	Visibility visibility;
	Sym name; // Range starts at sig.range.start
	SmallArray!NameAndRange typeParams;
	TypeAst returnType;
	ParamsAst params;
	SmallArray!FunModifierAst modifiers;
	Opt!ExprAst body_;
}

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

		RangeWithinFile range(in AllSymbols allSymbols) =>
			rangeOfNameAndRange(NameAndRange(pos, symOfSpecialFlag(flag)), allSymbols);
	}

	immutable struct Extern {
		@safe @nogc pure nothrow:

		TypeAst* left;
		Pos externPos;

		RangeWithinFile range(in AllSymbols allSymbols) =>
			RangeWithinFile(
				.range(*left, allSymbols).start,
				suffixRange(allSymbols).end);
		RangeWithinFile suffixRange(in AllSymbols allSymbols) scope =>
			rangeOfNameAndRange(NameAndRange(externPos, sym!"extern"), allSymbols);
	}

	// TypeAst will be interpreted as a spec inst
	mixin Union!(Special, Extern, TypeAst);
}

private Sym symOfSpecialFlag(FunModifierAst.Special.Flags a) {
	switch (a) {
		case FunModifierAst.Special.Flags.bare:
			return sym!"bare";
		case FunModifierAst.Special.Flags.builtin:
			return sym!"builtin";
		case FunModifierAst.Special.Flags.extern_:
			return sym!"extern";
		case FunModifierAst.Special.Flags.summon:
			return sym!"summon";
		case FunModifierAst.Special.Flags.trusted:
			return sym!"trusted";
		case FunModifierAst.Special.Flags.unsafe:
			return sym!"unsafe";
		case FunModifierAst.Special.Flags.forceCtx:
			return sym!"force-ctx";
		default:
			return unreachable!Sym;
	}
}

immutable struct TestAst {
	Opt!ExprAst body_;
}

// 'extern' or 'thread-local'
immutable struct VarDeclAst {
	RangeWithinFile range;
	SafeCStr docComment;
	Visibility visibility;
	Sym name;
	NameAndRange[] typeParams; // This will be a compile error
	VarKind kind;
	TypeAst type;
	FunModifierAst[] modifiers; // Any but 'extern' will be a compile error
}

immutable struct ImportOrExportAst {
	RangeWithinFile range;
	// Does not include the extension (which is only allowed for file imports)
	PathOrRelPath path;
	ImportOrExportAstKind kind;
}

immutable struct ImportOrExportAstKind {
	immutable struct ModuleWhole {}
	immutable struct File {
		Sym name;
		ImportFileType type;
	}
	mixin Union!(ModuleWhole, SmallArray!Sym, File*);
}
static assert(ImportOrExportAstKind.sizeof == ulong.sizeof);

immutable struct ImportsOrExportsAst {
	RangeWithinFile range;
	ImportOrExportAst[] paths;
}

immutable struct FileAst {
	SafeCStr docComment;
	bool noStd;
	Opt!ImportsOrExportsAst imports;
	Opt!ImportsOrExportsAst exports;
	SpecDeclAst[] specs;
	StructAliasAst[] structAliases;
	StructDeclAst[] structs;
	FunDeclAst[] funs;
	TestAst[] tests;
	VarDeclAst[] vars;
}

private ImportsOrExportsAst emptyImportsOrExports() =>
	ImportsOrExportsAst(RangeWithinFile.empty, []);
FileAst emptyFileAst() =>
	FileAst(safeCStr!"", true, some(emptyImportsOrExports), some(emptyImportsOrExports), [], [], [], [], []);

Repr reprAst(ref Alloc alloc, in AllPaths allPaths, in FileAst ast) {
	ArrBuilder!NameAndRepr args;
	if (has(ast.imports))
		add(alloc, args, nameAndRepr!"imports"(reprImportsOrExports(alloc, allPaths, force(ast.imports))));
	if (has(ast.exports))
		add(alloc, args, nameAndRepr!"exports"(reprImportsOrExports(alloc, allPaths, force(ast.exports))));
	add(alloc, args, nameAndRepr!"specs"(reprArr!SpecDeclAst(alloc, ast.specs, (in SpecDeclAst a) =>
		reprSpecDeclAst(alloc, a))));
	add(alloc, args, nameAndRepr!"aliases"(reprArr!StructAliasAst(alloc, ast.structAliases, (in StructAliasAst a) =>
		reprStructAliasAst(alloc, a))));
	add(alloc, args, nameAndRepr!"structs"(reprArr!StructDeclAst(alloc, ast.structs, (in StructDeclAst a) =>
		reprStructDeclAst(alloc, a))));
	add(alloc, args, nameAndRepr!"funs"(reprArr!FunDeclAst(alloc, ast.funs, (in FunDeclAst a) =>
		reprFunDeclAst(alloc, a))));
	return reprNamedRecord(sym!"file-ast", finishArr(alloc, args));
}

private:

Repr reprImportsOrExports(ref Alloc alloc, in AllPaths allPaths, in ImportsOrExportsAst a) =>
	reprRecord!"ports"(alloc, [
		reprRangeWithinFile(alloc, a.range),
		reprArr!ImportOrExportAst(alloc, a.paths, (in ImportOrExportAst a) =>
			reprImportOrExportAst(alloc, allPaths, a))]);

Repr reprImportOrExportAst(ref Alloc alloc, in AllPaths allPaths, in ImportOrExportAst a) =>
	reprRecord!"port"(alloc, [
		reprStr(pathOrRelPathToStr(alloc, allPaths, a.path)),
		a.kind.matchIn!Repr(
			(in ImportOrExportAstKind.ModuleWhole) =>
				reprSym!"whole",
			(in Sym[] names) =>
				reprRecord!"named"(alloc, [reprArr!Sym(alloc, names, (in Sym name) =>
					reprSym(name))]),
			(in ImportOrExportAstKind.File f) =>
				reprRecord!"file"(alloc, [
					reprSym(f.name),
					reprSym(symOfImportFileType(f.type))]))]);

Repr reprSpecDeclAst(ref Alloc alloc, in SpecDeclAst a) =>
	reprRecord!"spec-decl"(alloc, [
		reprRangeWithinFile(alloc, a.range),
		reprStr(alloc, a.docComment),
		reprVisibility(a.visibility),
		reprSym(a.name),
		reprTypeAsts(alloc, a.parents),
		reprTypeParams(alloc, a.typeParams),
		reprSpecBodyAst(alloc, a.body_)]);

Repr reprSpecBodyAst(ref Alloc alloc, in SpecBodyAst a) =>
	a.matchIn!Repr(
		(in SpecBodyAst.Builtin) =>
			reprSym!"builtin",
		(in SpecSigAst[] sigs) =>
			reprArr!SpecSigAst(alloc, sigs, (in SpecSigAst sig) =>
				reprSpecSig(alloc, sig)));

Repr reprSpecSig(ref Alloc alloc, in SpecSigAst a) =>
	reprRecord!"spec-sig"(alloc, [
		reprRangeWithinFile(alloc, a.range),
		reprStr(alloc, a.docComment),
		reprSym(a.name),
		reprTypeAst(alloc, a.returnType),
		reprParamsAst(alloc, a.params)]);

Repr reprStructAliasAst(ref Alloc alloc, in StructAliasAst a) =>
	reprRecord!"alias"(alloc, [
		reprRangeWithinFile(alloc, a.range),
		reprStr(alloc, a.docComment),
		reprVisibility(a.visibility),
		reprSym(a.name),
		reprTypeParams(alloc, a.typeParams),
		reprTypeAst(alloc, a.target)]);

Repr reprEnumOrFlags(
	ref Alloc alloc,
	Sym name,
	in Opt!(TypeAst*) typeArg,
	in StructDeclAst.Body.Enum.Member[] members,
) =>
	reprRecord(alloc, name, [
		reprOpt!(TypeAst*)(alloc, typeArg, (in TypeAst* it) =>
			reprTypeAst(alloc, *it)),
		reprArr!(StructDeclAst.Body.Enum.Member)(alloc, members, (in StructDeclAst.Body.Enum.Member it) =>
			reprEnumMember(alloc, it))]);

Repr reprEnumMember(ref Alloc alloc, in StructDeclAst.Body.Enum.Member a) =>
	reprRecord!"member"(alloc, [
		reprRangeWithinFile(alloc, a.range),
		reprSym(a.name),
		reprOpt!LiteralIntOrNat(alloc, a.value, (in LiteralIntOrNat v) =>
			reprLiteralIntOrNat(alloc, v))]);

Repr reprLiteralFloatAst(ref Alloc alloc, in LiteralFloatAst a) =>
	reprRecord!"float"(alloc, [reprFloat(a.value), reprBool(a.overflow)]);

Repr reprLiteralIntAst(ref Alloc alloc, in LiteralIntAst a) =>
	reprRecord!"int"(alloc, [reprInt(a.value), reprBool(a.overflow)]);

Repr reprLiteralNatAst(ref Alloc alloc, in LiteralNatAst a) =>
	reprRecord!"nat"(alloc, [reprNat(a.value), reprBool(a.overflow)]);

Repr reprLiteralStringAst(ref Alloc alloc, in LiteralStringAst a) =>
	reprRecord!"string"(alloc, [reprStr(alloc, a.value)]);

Repr reprLiteralIntOrNat(ref Alloc alloc, in LiteralIntOrNat a) =>
	a.matchIn!Repr(
		(in LiteralIntAst it) =>
			reprLiteralIntAst(alloc, it),
		(in LiteralNatAst it) =>
			reprLiteralNatAst(alloc, it));

Repr reprField(ref Alloc alloc, in StructDeclAst.Body.Record.Field a) =>
	reprRecord!"field"(alloc, [
		reprRangeWithinFile(alloc, a.range),
		reprSym(symOfFieldMutability(a.mutability)),
		reprSym(a.name),
		reprTypeAst(alloc, a.type)]);

Repr reprRecordAst(ref Alloc alloc, in StructDeclAst.Body.Record a) =>
	reprRecord!"record"(alloc, [
		reprArr!(StructDeclAst.Body.Record.Field)(alloc, a.fields, (in StructDeclAst.Body.Record.Field it) =>
			reprField(alloc, it))]);

public Sym symOfModifierKind(ModifierAst.Kind a) {
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

Repr reprUnion(ref Alloc alloc, in StructDeclAst.Body.Union a) =>
	reprRecord!"union"(alloc, [
		reprArr!(StructDeclAst.Body.Union.Member)(alloc, a.members, (in StructDeclAst.Body.Union.Member it) =>
			reprRecord!"member"(alloc, [
				reprSym(it.name),
				reprOpt!TypeAst(alloc, it.type, (in TypeAst t) =>
					reprTypeAst(alloc, t))]))]);

Repr reprStructBodyAst(ref Alloc alloc, in StructDeclAst.Body a) =>
	a.matchIn!Repr(
		(in StructDeclAst.Body.Builtin) =>
			reprSym!"builtin" ,
		(in StructDeclAst.Body.Enum e) =>
			reprEnumOrFlags(alloc, sym!"enum", e.typeArg, e.members),
		(in StructDeclAst.Body.Extern) =>
			reprSym!"extern",
		(in StructDeclAst.Body.Flags e) =>
			reprEnumOrFlags(alloc, sym!"flags", e.typeArg, e.members),
		(in StructDeclAst.Body.Record a) =>
			reprRecordAst(alloc, a),
		(in StructDeclAst.Body.Union a) =>
			reprUnion(alloc, a));

Repr reprStructDeclAst(ref Alloc alloc, in StructDeclAst a) {
	ArrBuilder!NameAndRepr fields;
	add(alloc, fields, nameAndRepr!"range"(reprRangeWithinFile(alloc, a.range)));
	if (!safeCStrIsEmpty(a.docComment))
		add(alloc, fields, nameAndRepr!"doc"(reprStr(a.docComment)));
	add(alloc, fields, nameAndRepr!"visibility"(reprVisibility(a.visibility)));
	maybeAddTypeParams(alloc, fields, a.typeParams);
	if (!empty(a.modifiers))
		add(alloc, fields, nameAndRepr!"modifiers"(reprArr!ModifierAst(alloc, a.modifiers, (in ModifierAst x) =>
			reprModifierAst(alloc, x))));
	add(alloc, fields, nameAndRepr!"body"(reprStructBodyAst(alloc, a.body_)));
	return reprNamedRecord!"struct-decl"(finishArr(alloc, fields));
}

void maybeAddTypeParams(ref Alloc alloc, ref ArrBuilder!NameAndRepr fields, in NameAndRange[] typeParams) {
	if (!empty(typeParams))
		add(alloc, fields, nameAndRepr!"type-params"(reprTypeParams(alloc, typeParams)));
}

Repr reprModifierAst(ref Alloc alloc, in ModifierAst a) =>
	reprRecord!"modifier"(alloc, [reprNat(a.pos), reprSym(symOfModifierKind(a.kind))]);

Repr reprFunDeclAst(ref Alloc alloc, in FunDeclAst a) {
	ArrBuilder!NameAndRepr fields;
	if (!safeCStrIsEmpty(a.docComment))
		add(alloc, fields, nameAndRepr!"doc"(reprStr(a.docComment)));
	add(alloc, fields, nameAndRepr!"visibility"(reprVisibility(a.visibility)));
	add(alloc, fields, nameAndRepr!"range"(reprRangeWithinFile(alloc, a.range)));
	add(alloc, fields, nameAndRepr!"name"(reprSym(a.name)));
	maybeAddTypeParams(alloc, fields, a.typeParams);
	add(alloc, fields, nameAndRepr!"return"(reprTypeAst(alloc, a.returnType)));
	add(alloc, fields, nameAndRepr!"params"(reprParamsAst(alloc, a.params)));
	if (!empty(a.modifiers))
		add(alloc, fields, nameAndRepr!"modifiers"(reprArr!FunModifierAst(alloc, a.modifiers, (in FunModifierAst s) =>
			reprFunModifierAst(alloc, s))));
	if (has(a.body_))
		add(alloc, fields, nameAndRepr!"body"(reprExprAst(alloc, force(a.body_))));
	return reprNamedRecord!"fun-decl"(finishArr(alloc, fields));
}

Repr reprParamsAst(ref Alloc alloc, in ParamsAst a) =>
	a.matchIn!Repr(
		(in DestructureAst[] params) =>
			reprDestructureAsts(alloc, params),
		(in ParamsAst.Varargs v) =>
			reprRecord!"varargs"(alloc, [reprDestructureAst(alloc, v.param)]));

Repr reprFunModifierAst(ref Alloc alloc, in FunModifierAst a) =>
	a.matchIn!Repr(
		(in FunModifierAst.Special x) =>
			reprRecord!"special"(alloc, [
				reprNat(x.pos),
				reprSym(symOfSpecialFlag(x.flag))]),
		(in FunModifierAst.Extern x) =>
			reprRecord!"extern"(alloc, [
				reprTypeAst(alloc, *x.left),
				reprNat(x.externPos)]),
		(in TypeAst x) =>
			reprTypeAst(alloc, x));

Repr reprTypeAst(ref Alloc alloc, in TypeAst a) =>
	a.matchIn!Repr(
		(in TypeAst.Bogus x) =>
			reprRecord!"bogus"(alloc, [reprRangeWithinFile(alloc, x.range)]),
		(in TypeAst.Fun it) =>
			reprRecord!"fun"(alloc, [
				reprRangeWithinFile(alloc, it.range),
				reprSym(symOfFunKind(it.kind)),
				reprTypeAsts(alloc, it.returnAndParamTypes)]),
		(in TypeAst.Map it) =>
			reprRecord!"map"(alloc, [
				reprTypeAst(alloc, it.v),
				reprTypeAst(alloc, it.k)]),
		(in NameAndRange x) =>
			reprNameAndRange(alloc, x),
		(in TypeAst.SuffixName it) =>
			reprRecord!"suffix"(alloc, [
				reprTypeAst(alloc, it.left),
				reprNameAndRange(alloc, it.name)]),
		(in TypeAst.SuffixSpecial it) =>
			reprRecord!"suffix"(alloc, [
				reprTypeAst(alloc, it.left),
				reprNat(it.suffixPos),
				reprSym(symForTypeAstSuffix(it.kind))]),
		(in TypeAst.Tuple it) =>
			reprRecord!"tuple"(alloc, [
				reprRangeWithinFile(alloc, it.range),
				reprTypeAsts(alloc, it.members)]));

Repr reprTypeAsts(ref Alloc alloc, in TypeAst[] a) =>
	reprArr!TypeAst(alloc, a, (in TypeAst x) =>
		reprTypeAst(alloc, x));

Repr reprDestructureAsts(ref Alloc alloc, in DestructureAst[] a) =>
	reprArr!DestructureAst(alloc, a, (in DestructureAst x) =>
		reprDestructureAst(alloc, x));

Repr reprDestructureAst(ref Alloc alloc, in DestructureAst a) =>
	a.matchIn!Repr(
		(in DestructureAst.Single x) =>
			reprRecord!"single"(alloc, [
				reprNameAndRange(alloc, x.name),
				reprBool(x.mut),
				reprOpt!(TypeAst*)(alloc, x.type, (in TypeAst* t) =>
					reprTypeAst(alloc, *t))]),
		(in DestructureAst.Void x) =>
			reprRecord!"void"(alloc, [reprNat(x.pos)]),
		(in DestructureAst[] parts) =>
			reprArr!DestructureAst(alloc, parts, (in DestructureAst part) =>
				reprDestructureAst(alloc, part)));

Repr reprExprAst(ref Alloc alloc, in ExprAst ast) =>
	reprExprAstKind(alloc, ast.kind);

Repr reprNameAndRange(ref Alloc alloc, in NameAndRange a) =>
	reprRecord!"name-range"(alloc, [reprNat(a.start), reprSym(a.name)]);

Repr reprExprAstKind(ref Alloc alloc, in ExprAstKind ast) =>
	ast.matchIn!Repr(
		(in ArrowAccessAst e) =>
			reprRecord!"arrow-access"(alloc, [
				reprExprAst(alloc, *e.left),
				reprNameAndRange(alloc, e.name)]),
		(in AssertOrForbidAst e) =>
			reprRecord(alloc, symOfAssertOrForbidKind(e.kind), [
				reprExprAst(alloc, e.condition),
				reprOpt!ExprAst(alloc, e.thrown, (in ExprAst thrown) =>
					reprExprAst(alloc, thrown))]),
		(in AssignmentAst e) =>
			reprRecord!"assign"(alloc, [
				reprExprAst(alloc, e.left),
				reprExprAst(alloc, e.right)]),
		(in AssignmentCallAst e) =>
			reprRecord!"assign-call"(alloc, [
				reprExprAst(alloc, e.left),
				reprNameAndRange(alloc, e.funName),
				reprExprAst(alloc, e.right)]),
		(in BogusAst _) =>
			reprSym!"bogus" ,
		(in CallAst e) =>
			reprRecord!"call"(alloc, [
				reprSym(symOfCallAstStyle(e.style)),
				reprNameAndRange(alloc, e.funName),
				reprOpt!(TypeAst*)(alloc, e.typeArg, (in TypeAst* it) =>
					reprTypeAst(alloc, *it)),
				reprArr!ExprAst(alloc, e.args, (in ExprAst it) =>
					reprExprAst(alloc, it))]),
		(in EmptyAst e) =>
			reprSym!"empty",
		(in ForAst x) =>
			reprRecord!"for"(alloc, [
				reprDestructureAst(alloc, x.param),
				reprExprAst(alloc, x.collection),
				reprExprAst(alloc, x.body_),
				reprExprAst(alloc, x.else_)]),
		(in IdentifierAst a) =>
			reprSym(a.name),
		(in IfAst e) =>
			reprRecord!"if"(alloc, [
				reprExprAst(alloc, e.cond),
				reprExprAst(alloc, e.then),
				reprExprAst(alloc, e.else_)]),
		(in IfOptionAst it) =>
			reprRecord!"if"(alloc, [
				reprDestructureAst(alloc, it.destructure),
				reprExprAst(alloc, it.option),
				reprExprAst(alloc, it.then),
				reprExprAst(alloc, it.else_)]),
		(in InterpolatedAst it) =>
			reprRecord!"interpolated"(alloc, [
				reprArr!InterpolatedPart(alloc, it.parts, (in InterpolatedPart part) =>
					reprInterpolatedPart(alloc, part))]),
		(in LambdaAst x) =>
			reprRecord!"lambda"(alloc, [
				reprDestructureAst(alloc, x.param),
				reprExprAst(alloc, x.body_)]),
		(in LetAst a) =>
			reprRecord!"let"(alloc, [
				reprDestructureAst(alloc, a.destructure),
				reprExprAst(alloc, a.initializer),
				reprExprAst(alloc, a.then)]),
		(in LiteralFloatAst a) =>
			reprLiteralFloatAst(alloc, a),
		(in LiteralIntAst a) =>
			reprLiteralIntAst(alloc, a),
		(in LiteralNatAst a) =>
			reprLiteralNatAst(alloc, a),
		(in LiteralStringAst a) =>
			reprLiteralStringAst(alloc, a),
		(in LoopAst a) =>
			reprRecord!"loop"(alloc, [reprExprAst(alloc, a.body_)]),
		(in LoopBreakAst e) =>
			reprRecord!"break"(alloc, [reprExprAst(alloc, e.value)]),
		(in LoopContinueAst _) =>
			reprSym!"continue",
		(in LoopUntilAst e) =>
			reprRecord!"until"(alloc, [
				reprExprAst(alloc, e.condition),
				reprExprAst(alloc, e.body_)]),
		(in LoopWhileAst e) =>
			reprRecord!"while"(alloc, [
				reprExprAst(alloc, e.condition),
				reprExprAst(alloc, e.body_)]),
		(in MatchAst it) =>
			reprRecord!"match"(alloc, [
				reprExprAst(alloc, it.matched),
				reprArr!(MatchAst.CaseAst)(alloc, it.cases, (in MatchAst.CaseAst case_) =>
					reprRecord!"case"(alloc, [
						reprRangeWithinFile(alloc, case_.range),
						reprSym(case_.memberName),
						reprOpt!DestructureAst(alloc, case_.destructure, (in DestructureAst x) =>
							reprDestructureAst(alloc, x)),
						reprExprAst(alloc, case_.then)]))]),
		(in ParenthesizedAst it) =>
			reprRecord!"paren"(alloc, [reprExprAst(alloc, it.inner)]),
		(in PtrAst a) =>
			reprRecord!"ptr"(alloc, [reprExprAst(alloc, a.inner)]),
		(in SeqAst a) =>
			reprRecord!"seq-ast"(alloc, [
				reprExprAst(alloc, a.first),
				reprExprAst(alloc, a.then)]),
		(in ThenAst it) =>
			reprRecord!"then"(alloc, [
				reprDestructureAst(alloc, it.left),
				reprExprAst(alloc, it.futExpr),
				reprExprAst(alloc, it.then)]),
		(in ThrowAst it) =>
			reprRecord!"throw"(alloc, [reprExprAst(alloc, it.thrown)]),
		(in TrustedAst it) =>
			reprRecord!"trusted"(alloc, [reprExprAst(alloc, it.inner)]),
		(in TypedAst it) =>
			reprRecord!"typed"(alloc, [
				reprExprAst(alloc, it.expr),
				reprTypeAst(alloc, it.type)]),
		(in UnlessAst it) =>
			reprRecord!"unless"(alloc, [
				reprExprAst(alloc, it.cond),
				reprExprAst(alloc, it.body_)]),
		(in WithAst x) =>
			reprRecord!"with"(alloc, [
				reprDestructureAst(alloc, x.param),
				reprExprAst(alloc, x.arg),
				reprExprAst(alloc, x.body_)]));

Repr reprInterpolatedPart(ref Alloc alloc, in InterpolatedPart a) =>
	a.matchIn!Repr(
		(in string it) => reprStr(alloc, it),
		(in ExprAst it) => reprExprAst(alloc, it));

Sym symOfCallAstStyle(CallAst.Style a) {
	final switch (a) {
		case CallAst.Style.comma:
			return sym!"comma";
		case CallAst.Style.dot:
			return sym!"dot";
		case CallAst.Style.emptyParens:
			return sym!"empty-parens";
		case CallAst.Style.infix:
			return sym!"infix";
		case CallAst.Style.prefixBang:
			return sym!"prefix-bang";
		case CallAst.Style.prefixOperator:
			return sym!"prefix-op";
		case CallAst.Style.single:
			return sym!"single";
		case CallAst.Style.subscript:
			return sym!"subscript";
		case CallAst.Style.suffixBang:
			return sym!"suffix-bang";
	}
}

Repr reprTypeParams(ref Alloc alloc, in NameAndRange[] typeParams) =>
	reprArr!NameAndRange(alloc, typeParams, (in NameAndRange a) =>
		reprNameAndRange(alloc, a));
