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
	Visibility;
import model.reprModel : reprVisibility;
import util.alloc.alloc : Alloc;
import util.col.arr : empty, emptySmallArray, SmallArray;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : arrLiteral, exists;
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
import util.sym : AllSymbols, Sym, sym, symSize;
import util.union_ : Union;
import util.util : verify;

struct NameAndRange {
	@safe @nogc pure nothrow:

	immutable Sym name;
	// Range length is given by size of name
	immutable Pos start;

	immutable this(immutable Pos s, immutable Sym n) {
		name = n;
		start = s;
	}
}

immutable(RangeWithinFile) rangeOfNameAndRange(immutable NameAndRange a, ref const AllSymbols allSymbols) =>
	rangeOfStartAndName(a.start, a.name, allSymbols);

struct OptNameAndRange {
	immutable Pos start;
	immutable Opt!Sym name;
}

immutable(RangeWithinFile) rangeOfOptNameAndRange(immutable OptNameAndRange a, ref const AllSymbols allSymbols) =>
	rangeOfStartAndName(a.start, has(a.name) ? force(a.name) : sym!"_", allSymbols);

struct TypeAst {
	struct Dict {
		enum Kind {
			data,
			mut,
		}
		immutable Kind kind;
		immutable TypeAst v;
		immutable TypeAst k;
	}

	struct Fun {
		immutable RangeWithinFile range;
		immutable FunKind kind;
		immutable TypeAst[] returnAndParamTypes;
	}

	struct InstStruct {
		immutable RangeWithinFile range;
		immutable NameAndRange name;
		immutable SmallArray!TypeAst typeArgs;
	}

	struct Suffix {
		enum Kind {
			future,
			list,
			mutList,
			mutPtr,
			option,
			ptr,
		}
		immutable Kind kind;
		immutable TypeAst left;
	}

	struct Tuple {
		immutable TypeAst a;
		immutable TypeAst b;
	}

	mixin Union!(immutable Dict*, immutable Fun, immutable InstStruct, immutable Suffix*, immutable Tuple*);
}
static assert(TypeAst.sizeof <= 40);

immutable(TypeAst) bogusTypeAst(immutable RangeWithinFile range) =>
	immutable TypeAst(immutable TypeAst.InstStruct(
		range,
		immutable NameAndRange(range.start, sym!"bogus"),
		emptySmallArray!TypeAst));

immutable(RangeWithinFile) range(immutable TypeAst a) =>
	a.match!(immutable RangeWithinFile)(
		(ref immutable TypeAst.Dict it) => range(it),
		(immutable TypeAst.Fun it) => it.range,
		(immutable TypeAst.InstStruct it) => it.range,
		(ref immutable TypeAst.Suffix it) => range(it),
		(ref immutable TypeAst.Tuple it) => range(it));

immutable(RangeWithinFile) range(immutable TypeAst.Dict a) =>
	immutable RangeWithinFile(range(a.v).start, safeToUint(range(a.k).end + "]".length));

immutable(RangeWithinFile) range(immutable TypeAst.Suffix a) {
	immutable RangeWithinFile leftRange = range(a.left);
	return immutable RangeWithinFile(leftRange.start, leftRange.end + suffixLength(a.kind));
}
immutable(RangeWithinFile) suffixRange(immutable TypeAst.Suffix a) {
	immutable uint leftEnd = range(a.left).end;
	return immutable RangeWithinFile(leftEnd, leftEnd + suffixLength(a.kind));
}
immutable(RangeWithinFile) range(immutable TypeAst.Tuple a) =>
	immutable RangeWithinFile(range(a.a).start, range(a.b).end);

private immutable(uint) suffixLength(immutable TypeAst.Suffix.Kind a) {
	final switch (a) {
		case TypeAst.Suffix.Kind.future:
			return cast(uint) "$".length;
		case TypeAst.Suffix.Kind.list:
			return cast(uint) "[]".length;
		case TypeAst.Suffix.Kind.option:
			return cast(uint) "?".length;
		case TypeAst.Suffix.Kind.mutList:
			return cast(uint) "mut[]".length;
		case TypeAst.Suffix.Kind.mutPtr:
			return cast(uint) "mut*".length;
		case TypeAst.Suffix.Kind.ptr:
			return cast(uint) "*".length;
	}
}

immutable(Sym) symForTypeAstDict(immutable TypeAst.Dict.Kind a) {
	final switch (a) {
		case TypeAst.Dict.Kind.data:
			return sym!"dict";
		case TypeAst.Dict.Kind.mut:
			return sym!"mut-dict";
	}
}

immutable(Sym) symForTypeAstSuffix(immutable TypeAst.Suffix.Kind a) {
	final switch (a) {
		case TypeAst.Suffix.Kind.future:
			return sym!"future";
		case TypeAst.Suffix.Kind.list:
			return sym!"list";
		case TypeAst.Suffix.Kind.mutList:
			return sym!"mut-list";
		case TypeAst.Suffix.Kind.mutPtr:
			return sym!"mut-pointer";
		case TypeAst.Suffix.Kind.option:
			return sym!"option";
		case TypeAst.Suffix.Kind.ptr:
			return sym!"const-pointer";
	}
}

struct ArrowAccessAst {
	immutable ExprAst left;
	immutable NameAndRange name;
	immutable SmallArray!TypeAst typeArgs;
}

struct AssertOrForbidAst {
	immutable AssertOrForbidKind kind;
	immutable ExprAst condition;
	immutable Opt!ExprAst thrown;
}

struct BogusAst {}

struct CallAst {
	@safe @nogc pure nothrow:

	enum Style {
		comma, // `a, b`, `a, b, c`, etc.
		dot, // `a.b`
		emptyParens, // `()`
		infix, // `a b`, `a b c`, `a b c, d`, etc.
		prefix, // `a: b`, `a: b, c`, etc.
		prefixOperator, // `-x`, `!x`, `~x`
		setDeref, // `*a := b`
		setDot, // a.x := b
		setSubscript, // `a[b] := c` (or `a[b, c] := d`, etc.)
		single, // `a<t>` (without the type arg, it would just be an Identifier)
		subscript, // a[b]
		suffixOperator, // 'x!'
	}
	// For some reason we have to break this up to get the struct size lower
	//immutable NameAndRange funName;
	immutable Sym funNameName;
	immutable Pos funNameStart;
	immutable Style style;
	immutable SmallArray!TypeAst typeArgs;
	immutable SmallArray!ExprAst args;

	immutable this(
		immutable Style s, immutable NameAndRange f, immutable TypeAst[] t, immutable ExprAst[] a) {
		funNameName = f.name;
		funNameStart = f.start;
		style = s;
		typeArgs = t;
		args = a;
	}

	immutable(NameAndRange) funName() immutable =>
		immutable NameAndRange(funNameStart, funNameName);
}

struct ForAst {
	immutable LambdaAst.Param[] params;
	immutable ExprAst collection;
	immutable ExprAst body_;
	immutable Opt!ExprAst else_;
}

struct IdentifierAst {
	immutable Sym name;
}

// 'name := value'
struct IdentifierSetAst {
	immutable Sym name;
	immutable ExprAst value;
}

struct IfAst {
	immutable ExprAst cond;
	immutable ExprAst then;
	immutable Opt!ExprAst else_;
}

struct IfOptionAst {
	immutable NameAndRange name;
	immutable ExprAst option;
	immutable ExprAst then;
	immutable Opt!ExprAst else_;
}

struct InterpolatedAst {
	@safe @nogc pure nothrow:

	immutable InterpolatedPart[] parts;

	immutable this(immutable InterpolatedPart[] p) {
		parts = p;
		verify(exists!(immutable InterpolatedPart)(parts, (ref immutable InterpolatedPart part) =>
			part.isA!ExprAst));
	}
}

struct InterpolatedPart {
	mixin Union!(immutable string, immutable ExprAst);
}

struct LambdaAst {
	alias Param = OptNameAndRange;
	immutable Param[] params;
	immutable ExprAst body_;
}

struct LetAst {
	immutable Opt!Sym name;
	immutable bool mut;
	immutable Opt!(TypeAst*) type;
	immutable ExprAst initializer;
	immutable ExprAst then;
}

struct LiteralFloatAst {
	immutable double value;
	immutable bool overflow;
}

struct LiteralIntAst {
	immutable long value;
	immutable bool overflow;
}

struct LiteralNatAst {
	immutable ulong value;
	immutable bool overflow;
}

struct LiteralStringAst {
	immutable string value;
}

struct LoopAst {
	immutable ExprAst body_;
}

struct LoopBreakAst {
	immutable Opt!ExprAst value;
}

struct LoopContinueAst {}

struct LoopUntilAst {
	immutable ExprAst condition;
	immutable ExprAst body_;
}

struct LoopWhileAst {
	immutable ExprAst condition;
	immutable ExprAst body_;
}

struct NameOrUnderscoreOrNone {
	struct Underscore {}
	struct None {}
	mixin Union!(immutable Sym, immutable Underscore, immutable None);
}

// Includes size of the ' ' before the name (but not for None)
private immutable(size_t) nameOrUnderscoreOrNoneSize(
	ref const AllSymbols allSymbols,
	ref immutable NameOrUnderscoreOrNone a,
) =>
	a.match!(immutable size_t)(
		(immutable Sym s) =>
			1 + symSize(allSymbols, s),
		(immutable NameOrUnderscoreOrNone.Underscore) =>
			immutable size_t(2),
		(immutable NameOrUnderscoreOrNone.None) =>
			immutable size_t(0));

struct MatchAst {
	struct CaseAst {
		@safe @nogc pure nothrow:

		immutable RangeWithinFile range;
		immutable Sym memberName;
		immutable NameOrUnderscoreOrNone local;
		immutable ExprAst then;

		//TODO: NOT INSTANCE
		immutable(RangeWithinFile) memberNameRange(ref const AllSymbols allSymbols) immutable =>
			rangeOfStartAndName(safeToUint(range.start + "as ".length), memberName, allSymbols);

		immutable(RangeWithinFile) localRange(ref const AllSymbols allSymbols) immutable =>
			rangeOfStartAndLength(
				memberNameRange(allSymbols).end,
				nameOrUnderscoreOrNoneSize(allSymbols, local));
	}

	immutable ExprAst matched;
	immutable CaseAst[] cases;
}

struct ParenthesizedAst {
	immutable ExprAst inner;
}

struct PtrAst {
	immutable ExprAst inner;
}

struct SeqAst {
	immutable ExprAst first;
	immutable ExprAst then;
}

struct ThenAst {
	immutable LambdaAst.Param[] left;
	immutable ExprAst futExpr;
	immutable ExprAst then;
}

struct ThrowAst {
	immutable ExprAst thrown;
}

// expr :: t
struct TypedAst {
	immutable ExprAst expr;
	immutable TypeAst type;
}

struct UnlessAst {
	immutable ExprAst cond;
	immutable ExprAst body_;
}

struct WithAst {
	immutable LambdaAst.Param[] params;
	immutable ExprAst arg;
	immutable ExprAst body_;
	immutable Opt!ExprAst else_;
}

struct ExprAstKind {
	mixin Union!(
		immutable ArrowAccessAst*,
		immutable AssertOrForbidAst*,
		immutable BogusAst,
		immutable CallAst,
		immutable ForAst*,
		immutable IdentifierAst,
		immutable IdentifierSetAst*,
		immutable IfAst*,
		immutable IfOptionAst*,
		immutable InterpolatedAst,
		immutable LambdaAst*,
		immutable LetAst*,
		immutable LiteralFloatAst,
		immutable LiteralIntAst,
		immutable LiteralNatAst,
		immutable LiteralStringAst,
		immutable LoopAst*,
		immutable LoopBreakAst*,
		immutable LoopContinueAst,
		immutable LoopUntilAst*,
		immutable LoopWhileAst*,
		immutable MatchAst*,
		immutable ParenthesizedAst*,
		immutable PtrAst*,
		immutable SeqAst*,
		immutable ThenAst*,
		immutable ThrowAst*,
		immutable TypedAst*,
		immutable UnlessAst*,
		immutable WithAst*);
}
static assert(ExprAstKind.sizeof <= 40);

struct ExprAst {
	immutable RangeWithinFile range;
	immutable ExprAstKind kind;
}
static assert(ExprAst.sizeof <= 56);

struct ParamAst {
	immutable RangeWithinFile range;
	immutable Opt!Sym name;
	immutable TypeAst type;
}

struct ParamsAst {
	struct Varargs {
		immutable ParamAst param;
	}
	mixin Union!(immutable SmallArray!ParamAst, immutable Varargs*);
}
static assert(ParamsAst.sizeof == 8);

struct SpecSigAst {
	immutable SafeCStr docComment;
	immutable RangeWithinFile range;
	immutable Sym name;
	immutable TypeAst returnType;
	immutable ParamsAst params;
}

struct StructAliasAst {
	immutable RangeWithinFile range;
	immutable SafeCStr docComment;
	immutable Visibility visibility;
	immutable Sym name;
	immutable SmallArray!NameAndRange typeParams;
	immutable TypeAst target;
}

struct ModifierAst {
	enum Kind {
		byRef,
		byVal,
		data,
		extern_,
		forceSendable,
		mut,
		newPublic,
		newPrivate,
		packed,
		sendable,
	}

	immutable Pos pos;
	immutable Kind kind;
}

immutable(RangeWithinFile) rangeOfModifierAst(immutable ModifierAst a, ref const AllSymbols allSymbols) =>
	rangeOfStartAndName(a.pos, symOfModifierKind(a.kind), allSymbols);

struct LiteralIntOrNat {
	mixin Union!(immutable LiteralIntAst, immutable LiteralNatAst);
}

struct StructDeclAst {
	struct Body {
		struct Builtin {}
		struct Enum {
			struct Member {
				immutable RangeWithinFile range;
				immutable Sym name;
				immutable Opt!LiteralIntOrNat value;
			}

			immutable Opt!(TypeAst*) typeArg;
			immutable SmallArray!Member members;
		}
		struct Extern {
			immutable Opt!(LiteralNatAst*) size;
			immutable Opt!(LiteralNatAst*) alignment;
		}
		struct Flags {
			alias Member = Enum.Member;
			immutable Opt!(TypeAst*) typeArg;
			immutable SmallArray!Member members;
		}
		struct Record {
			struct Field {
				immutable RangeWithinFile range;
				immutable Visibility visibility;
				immutable Sym name;
				immutable FieldMutability mutability;
				immutable TypeAst type;
			}
			immutable SmallArray!Field fields;
		}
		struct Union {
			struct Member {
				immutable RangeWithinFile range;
				immutable Sym name;
				immutable Opt!TypeAst type;
			}
			immutable Member[] members;
		}

		mixin .Union!(
			immutable Builtin,
			immutable Enum,
			immutable Extern,
			immutable Flags,
			immutable Record,
			immutable Union);
	}

	immutable RangeWithinFile range;
	immutable SafeCStr docComment;
	immutable Visibility visibility;
	immutable Sym name; // start is range.start
	immutable SmallArray!NameAndRange typeParams;
	immutable SmallArray!ModifierAst modifiers;
	immutable Body body_;
}
static assert(StructDeclAst.Body.sizeof <= 24);
static assert(StructDeclAst.sizeof <= 88);

struct SpecBodyAst {
	struct Builtin {}
	mixin Union!(immutable Builtin, immutable SmallArray!SpecSigAst);
}
static assert(SpecBodyAst.sizeof == ulong.sizeof);

struct SpecDeclAst {
	immutable RangeWithinFile range;
	immutable SafeCStr docComment;
	immutable Visibility visibility;
	immutable Sym name;
	immutable SmallArray!NameAndRange typeParams;
	immutable SpecBodyAst body_;
}

struct FunDeclAst {
	immutable RangeWithinFile range;
	immutable SafeCStr docComment;
	immutable Visibility visibility;
	immutable Sym name; // Range starts at sig.range.start
	immutable SmallArray!NameAndRange typeParams;
	immutable TypeAst returnType;
	immutable ParamsAst params;
	immutable SmallArray!FunModifierAst modifiers;
	immutable Opt!ExprAst body_;
}

struct FunModifierAst {
	@safe @nogc pure nothrow:

	// keywords like 'extern' are changed to symbols here
	immutable NameAndRange name;
	immutable SmallArray!TypeAst typeArgs;

	enum SpecialFlags {
		none = 0,
		builtin = 1,
		extern_ = 0b10,
		global = 0b100,
		noctx = 0b1000,
		no_doc = 0b1_0000,
		summon = 0b10_0000,
		thread_local = 0b100_0000,
		trusted = 0b1000_0000,
		unsafe = 0b10000_0000,
	}

	immutable(bool) isSpecial() scope immutable =>
		specialFlags() != SpecialFlags.none;

	immutable(SpecialFlags) specialFlags() scope immutable {
		switch (name.name.value) {
			case sym!"builtin".value:
				return SpecialFlags.builtin;
			case sym!"extern".value:
				return SpecialFlags.extern_;
			case sym!"global".value:
				return SpecialFlags.global;
			case sym!"noctx".value:
				return SpecialFlags.noctx;
			case sym!"no-doc".value:
				return SpecialFlags.no_doc;
			case sym!"summon".value:
				return SpecialFlags.summon;
			case sym!"thread-local".value:
				return SpecialFlags.thread_local;
			case sym!"trusted".value:
				return SpecialFlags.trusted;
			case sym!"unsafe".value:
				return SpecialFlags.unsafe;
			default:
				return SpecialFlags.none;
		}
	}
}

struct TestAst {
	immutable Opt!ExprAst body_;
}

struct ImportOrExportAst {
	immutable RangeWithinFile range;
	// Does not include the extension (which is only allowed for file imports)
	immutable PathOrRelPath path;
	immutable ImportOrExportAstKind kind;
}

struct ImportOrExportAstKind {
	struct ModuleWhole {}
	struct File {
		immutable Sym name;
		immutable ImportFileType type;
	}
	mixin Union!(immutable ModuleWhole, immutable SmallArray!Sym, immutable File*);
}
static assert(ImportOrExportAstKind.sizeof == ulong.sizeof);

struct ImportsOrExportsAst {
	immutable RangeWithinFile range;
	immutable ImportOrExportAst[] paths;
}

struct FileAst {
	immutable SafeCStr docComment;
	immutable bool noStd;
	immutable Opt!ImportsOrExportsAst imports;
	immutable Opt!ImportsOrExportsAst exports;
	immutable SpecDeclAst[] specs;
	immutable StructAliasAst[] structAliases;
	immutable StructDeclAst[] structs;
	immutable FunDeclAst[] funs;
	immutable TestAst[] tests;
}

private immutable ImportsOrExportsAst emptyImportsOrExports = immutable ImportsOrExportsAst(RangeWithinFile.empty, []);
immutable FileAst emptyFileAst =
	immutable FileAst(safeCStr!"", true, some(emptyImportsOrExports), some(emptyImportsOrExports), [], [], [], [], []);

immutable(Repr) reprAst(
	ref Alloc alloc,
	ref const AllPaths allPaths,
	ref immutable FileAst ast,
) {
	ArrBuilder!NameAndRepr args;
	if (has(ast.imports))
		add(alloc, args, nameAndRepr!"imports"(reprImportsOrExports(alloc, allPaths, force(ast.imports))));
	if (has(ast.exports))
		add(alloc, args, nameAndRepr!"exports"(reprImportsOrExports(alloc, allPaths, force(ast.exports))));
	add(alloc, args, nameAndRepr!"specs"(reprArr(alloc, ast.specs, (ref immutable SpecDeclAst a) =>
		reprSpecDeclAst(alloc, a))));
	add(alloc, args, nameAndRepr!"aliases"(reprArr(alloc, ast.structAliases, (ref immutable StructAliasAst a) =>
		reprStructAliasAst(alloc, a))));
	add(alloc, args, nameAndRepr!"structs"(reprArr(alloc, ast.structs, (ref immutable StructDeclAst a) =>
		reprStructDeclAst(alloc, a))));
	add(alloc, args, nameAndRepr!"funs"(reprArr(alloc, ast.funs, (ref immutable FunDeclAst a) =>
		reprFunDeclAst(alloc, a))));
	return reprNamedRecord(sym!"file-ast", finishArr(alloc, args));
}

private:

immutable(Repr) reprImportsOrExports(
	ref Alloc alloc,
	ref const AllPaths allPaths,
	ref immutable ImportsOrExportsAst a,
) =>
	reprRecord!"ports"(alloc, [
		reprRangeWithinFile(alloc, a.range),
		reprArr(alloc, a.paths, (ref immutable ImportOrExportAst a) =>
			reprImportOrExportAst(alloc, allPaths, a))]);

immutable(Repr) reprImportOrExportAst(
	ref Alloc alloc,
	ref const AllPaths allPaths,
	ref immutable ImportOrExportAst a,
) =>
	reprRecord!"port"(alloc, [
		reprStr(pathOrRelPathToStr(alloc, allPaths, a.path)),
		a.kind.match!(immutable Repr)(
			(immutable ImportOrExportAstKind.ModuleWhole) =>
				reprSym!"whole",
			(immutable Sym[] names) =>
				reprRecord!"named"(alloc, [reprArr(alloc, names, (ref immutable Sym name) =>
					reprSym(name))]),
			(ref immutable ImportOrExportAstKind.File f) =>
				reprRecord!"file"(alloc, [
					reprSym(f.name),
					reprSym(symOfImportFileType(f.type))]))]);

immutable(Repr) reprSpecDeclAst(ref Alloc alloc, ref immutable SpecDeclAst a) =>
	reprRecord!"spec-decl"(alloc, [
		reprRangeWithinFile(alloc, a.range),
		reprStr(a.docComment),
		reprVisibility(a.visibility),
		reprSym(a.name),
		reprTypeParams(alloc, a.typeParams),
		reprSpecBodyAst(alloc, a.body_)]);

immutable(Repr) reprSpecBodyAst(ref Alloc alloc, ref immutable SpecBodyAst a) =>
	a.match!(immutable Repr)(
		(immutable SpecBodyAst.Builtin) =>
			reprSym!"builtin",
		(immutable SpecSigAst[] sigs) =>
			reprArr(alloc, sigs, (ref immutable SpecSigAst sig) =>
				reprSpecSig(alloc, sig)));

immutable(Repr) reprSpecSig(ref Alloc alloc, ref immutable SpecSigAst a) =>
	reprRecord!"spec-sig"(alloc, [
		reprRangeWithinFile(alloc, a.range),
		reprStr(a.docComment),
		reprSym(a.name),
		reprTypeAst(alloc, a.returnType),
		a.params.match!(immutable Repr)(
			(immutable ParamAst[] params) =>
				reprArr(alloc, params, (ref immutable ParamAst p) => reprParamAst(alloc, p)),
			(ref immutable ParamsAst.Varargs v) =>
				reprRecord!"varargs"(alloc, [reprParamAst(alloc, v.param)]))]);

immutable(Repr) reprStructAliasAst(ref Alloc alloc, ref immutable StructAliasAst a) =>
	reprRecord!"alias"(alloc, [
		reprRangeWithinFile(alloc, a.range),
		reprStr(a.docComment),
		reprVisibility(a.visibility),
		reprSym(a.name),
		reprTypeParams(alloc, a.typeParams),
		reprTypeAst(alloc, a.target)]);


immutable(Repr) reprEnumOrFlags(
	ref Alloc alloc,
	immutable Sym name,
	immutable Opt!(TypeAst*) typeArg,
	immutable StructDeclAst.Body.Enum.Member[] members,
) =>
	reprRecord(alloc, name, [
		reprOpt!(TypeAst*)(alloc, typeArg, (ref immutable TypeAst* it) =>
			reprTypeAst(alloc, *it)),
		reprArr(alloc, members, (ref immutable StructDeclAst.Body.Enum.Member it) =>
			reprEnumMember(alloc, it))]);

immutable(Repr) reprEnumMember(ref Alloc alloc, ref immutable StructDeclAst.Body.Enum.Member a) =>
	reprRecord!"member"(alloc, [
		reprRangeWithinFile(alloc, a.range),
		reprSym(a.name),
		reprOpt(alloc, a.value, (ref immutable LiteralIntOrNat v) =>
			reprLiteralIntOrNat(alloc, v))]);

immutable(Repr) reprLiteralFloatAst(ref Alloc alloc, ref immutable LiteralFloatAst a) =>
	reprRecord!"float"(alloc, [reprFloat(a.value), reprBool(a.overflow)]);

immutable(Repr) reprLiteralIntAst(ref Alloc alloc, ref immutable LiteralIntAst a) =>
	reprRecord!"int"(alloc, [reprInt(a.value), reprBool(a.overflow)]);

immutable(Repr) reprLiteralNatAst(ref Alloc alloc, ref immutable LiteralNatAst a) =>
	reprRecord!"nat"(alloc, [reprNat(a.value), reprBool(a.overflow)]);

immutable(Repr) reprLiteralStringAst(ref Alloc alloc, ref immutable LiteralStringAst a) =>
	reprRecord!"string"(alloc, [reprStr(a.value)]);

immutable(Repr) reprLiteralIntOrNat(ref Alloc alloc, ref immutable LiteralIntOrNat a) =>
	a.match!(immutable Repr)(
		(immutable LiteralIntAst it) =>
			reprLiteralIntAst(alloc, it),
		(immutable LiteralNatAst it) =>
			reprLiteralNatAst(alloc, it));

immutable(Repr) reprField(ref Alloc alloc, ref immutable StructDeclAst.Body.Record.Field a) =>
	reprRecord!"field"(alloc, [
		reprRangeWithinFile(alloc, a.range),
		reprSym(symOfFieldMutability(a.mutability)),
		reprSym(a.name),
		reprTypeAst(alloc, a.type)]);

immutable(Repr) reprRecordAst(ref Alloc alloc, ref immutable StructDeclAst.Body.Record a) =>
	reprRecord!"record"(alloc, [
		reprArr(alloc, a.fields, (ref immutable StructDeclAst.Body.Record.Field it) =>
			reprField(alloc, it))]);

public immutable(Sym) symOfModifierKind(immutable ModifierAst.Kind a) {
	final switch (a) {
		case ModifierAst.Kind.byRef:
			return sym!"by-ref";
		case ModifierAst.Kind.byVal:
			return sym!"by-val";
		case ModifierAst.Kind.data:
			return sym!"data";
		case ModifierAst.Kind.extern_:
			return sym!"extern";
		case ModifierAst.Kind.forceSendable:
			return sym!"force-sendable";
		case ModifierAst.Kind.mut:
			return sym!"mut";
		case ModifierAst.Kind.newPrivate:
			return sym!".new";
		case ModifierAst.Kind.newPublic:
			return sym!"new";
		case ModifierAst.Kind.packed:
			return sym!"packed";
		case ModifierAst.Kind.sendable:
			return sym!"sendable";
	}
}

immutable(Repr) reprUnion(ref Alloc alloc, ref immutable StructDeclAst.Body.Union a) =>
	reprRecord!"union"(alloc, [
		reprArr(alloc, a.members, (ref immutable StructDeclAst.Body.Union.Member it) =>
			reprRecord!"member"(alloc, [
				reprSym(it.name),
				reprOpt(alloc, it.type, (ref immutable TypeAst t) =>
					reprTypeAst(alloc, t))]))]);

immutable(Repr) reprStructBodyAst(ref Alloc alloc, ref immutable StructDeclAst.Body a) =>
	a.match!(immutable Repr)(
		(immutable StructDeclAst.Body.Builtin) =>
			reprSym!"builtin" ,
		(immutable StructDeclAst.Body.Enum e) =>
			reprEnumOrFlags(alloc, sym!"enum", e.typeArg, e.members),
		(immutable StructDeclAst.Body.Extern) =>
			reprSym!"extern",
		(immutable StructDeclAst.Body.Flags e) =>
			reprEnumOrFlags(alloc, sym!"flags", e.typeArg, e.members),
		(immutable StructDeclAst.Body.Record a) =>
			reprRecordAst(alloc, a),
		(immutable StructDeclAst.Body.Union a) =>
			reprUnion(alloc, a));

immutable(Repr) reprStructDeclAst(ref Alloc alloc, ref immutable StructDeclAst a) {
	ArrBuilder!NameAndRepr fields;
	add(alloc, fields, nameAndRepr!"range"(reprRangeWithinFile(alloc, a.range)));
	if (!safeCStrIsEmpty(a.docComment))
		add(alloc, fields, nameAndRepr!"doc"(reprStr(a.docComment)));
	add(alloc, fields, nameAndRepr!"visibility"(reprVisibility(a.visibility)));
	maybeAddTypeParams(alloc, fields, a.typeParams);
	if (!empty(a.modifiers))
		add(alloc, fields, nameAndRepr!"modifiers"(reprArr(alloc, a.modifiers, (ref immutable ModifierAst x) =>
			reprModifierAst(alloc, x))));
	add(alloc, fields, nameAndRepr!"body"(reprStructBodyAst(alloc, a.body_)));
	return reprNamedRecord!"struct-decl"(finishArr(alloc, fields));
}

void maybeAddTypeParams(ref Alloc alloc, ref ArrBuilder!NameAndRepr fields, immutable NameAndRange[] typeParams) {
	if (!empty(typeParams))
		add(alloc, fields, nameAndRepr!"type-params"(reprTypeParams(alloc, typeParams)));
}

immutable(Repr) reprModifierAst(ref Alloc alloc, immutable ModifierAst a) =>
	reprRecord!"modifier"(alloc, [reprNat(a.pos), reprSym(symOfModifierKind(a.kind))]);

immutable(Repr) reprFunDeclAst(ref Alloc alloc, ref immutable FunDeclAst a) {
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
		add(alloc, fields, nameAndRepr!"modifiers"(reprArr(alloc, a.modifiers, (ref immutable FunModifierAst s) =>
			reprFunModifierAst(alloc, s))));
	if (has(a.body_))
		add(alloc, fields, nameAndRepr!"body"(reprExprAst(alloc, force(a.body_))));
	return reprNamedRecord!"fun-decl"(finishArr(alloc, fields));
}

immutable(Repr) reprParamsAst(ref Alloc alloc, scope immutable ParamsAst a) =>
	a.match!(immutable Repr)(
		(immutable ParamAst[] params) =>
			reprArr(alloc, params, (ref immutable ParamAst p) => reprParamAst(alloc, p)),
		(ref immutable ParamsAst.Varargs v) =>
			reprRecord!"varargs"(alloc, [reprParamAst(alloc, v.param)]));

immutable(Repr) reprFunModifierAst(ref Alloc alloc, scope immutable FunModifierAst a) =>
	reprRecord!"modifier"(alloc, [
		reprNameAndRange(alloc, a.name),
		reprArr(alloc, a.typeArgs, (ref immutable TypeAst it) =>
			reprTypeAst(alloc, it))]);

immutable(Repr) reprTypeAst(ref Alloc alloc, immutable TypeAst a) =>
	a.match!(immutable Repr)(
		(ref immutable TypeAst.Dict it) =>
			reprRecord!"dict"(alloc, [
				reprTypeAst(alloc, it.v),
				reprTypeAst(alloc, it.k)]),
		(immutable TypeAst.Fun it) =>
			reprRecord!"fun"(alloc, [
				reprRangeWithinFile(alloc, it.range),
				reprSym(symOfFunKind(it.kind)),
				reprArr(alloc, it.returnAndParamTypes, (ref immutable TypeAst t) =>
					reprTypeAst(alloc, t))]),
		(immutable TypeAst.InstStruct i) =>
			reprInstStructAst(alloc, i),
		(ref immutable TypeAst.Suffix it) =>
			reprRecord!"suffix"(alloc, [
				reprTypeAst(alloc, it.left),
				reprSym(symForTypeAstSuffix(it.kind))]),
		(ref immutable TypeAst.Tuple it) =>
			reprRecord!"tuple"(alloc, [
				reprTypeAst(alloc, it.a),
				reprTypeAst(alloc, it.b)]));

immutable(Repr) reprInstStructAst(ref Alloc alloc, immutable TypeAst.InstStruct a) {
	immutable Repr range = reprRangeWithinFile(alloc, a.range);
	immutable Repr name = reprNameAndRange(alloc, a.name);
	immutable Opt!Repr typeArgs = empty(a.typeArgs)
		? none!Repr
		: some(reprArr(alloc, a.typeArgs, (ref immutable TypeAst t) => reprTypeAst(alloc, t)));
	return reprRecord!"inststruct"(has(typeArgs)
		? arrLiteral!Repr(alloc, [range, name, force(typeArgs)])
		: arrLiteral!Repr(alloc, [range, name]));
}

immutable(Repr) reprParamAst(ref Alloc alloc, ref immutable ParamAst a) =>
	reprRecord!"param"(alloc, [
		reprRangeWithinFile(alloc, a.range),
		reprOpt(alloc, a.name, (ref immutable Sym it) =>
			reprSym(it)),
		reprTypeAst(alloc, a.type)]);

immutable(Repr) reprExprAst(ref Alloc alloc, ref immutable ExprAst ast) =>
	reprExprAstKind(alloc, ast.kind);

immutable(Repr) reprNameAndRange(ref Alloc alloc, immutable NameAndRange a) =>
	reprRecord!"name-range"(alloc, [reprNat(a.start), reprSym(a.name)]);

immutable(Repr) reprLambdaParamAsts(ref Alloc alloc, immutable LambdaAst.Param[] a) =>
	reprArr(alloc, a, (ref immutable LambdaAst.Param it) =>
		reprLambdaParamAst(alloc, it));

immutable(Repr) reprLambdaParamAst(ref Alloc alloc, immutable LambdaAst.Param a) =>
	reprRecord!"param"(alloc, [
		reprNat(a.start),
		reprSym(has(a.name) ? force(a.name) : sym!"_")]);

immutable(Repr) reprExprAstKind(ref Alloc alloc, ref immutable ExprAstKind ast) =>
	ast.match!(immutable Repr)(
		(ref immutable ArrowAccessAst e) =>
			reprRecord!"arrow-access"(alloc, [
				reprExprAst(alloc, e.left),
				reprNameAndRange(alloc, e.name),
				reprArr(alloc, e.typeArgs, (ref immutable TypeAst it) =>
					reprTypeAst(alloc, it))]),
		(ref immutable AssertOrForbidAst e) =>
			reprRecord(alloc, symOfAssertOrForbidKind(e.kind), [
				reprExprAst(alloc, e.condition),
				reprOpt(alloc, e.thrown, (ref immutable ExprAst thrown) =>
					reprExprAst(alloc, thrown))]),
		(immutable(BogusAst)) =>
			reprSym!"bogus" ,
		(immutable CallAst e) =>
			reprRecord!"call"(alloc, [
				reprSym(symOfCallAstStyle(e.style)),
				reprNameAndRange(alloc, e.funName),
				reprArr(alloc, e.typeArgs, (ref immutable TypeAst it) =>
					reprTypeAst(alloc, it)),
				reprArr(alloc, e.args, (ref immutable ExprAst it) =>
					reprExprAst(alloc, it))]),
		(ref immutable ForAst x) =>
			reprRecord!"for"(alloc, [
				reprLambdaParamAsts(alloc, x.params),
				reprExprAst(alloc, x.collection),
				reprExprAst(alloc, x.body_),
				reprOpt(alloc, x.else_, (ref immutable ExprAst else_) => reprExprAst(alloc, else_))]),
		(immutable IdentifierAst a) =>
			reprSym(a.name),
		(ref immutable IdentifierSetAst a) =>
			reprRecord!"set"(alloc, [
				reprSym(a.name),
				reprExprAst(alloc, a.value)]),
		(ref immutable IfAst e) =>
			reprRecord!"if"(alloc, [
				reprExprAst(alloc, e.cond),
				reprExprAst(alloc, e.then),
				reprOpt(alloc, e.else_, (ref immutable ExprAst it) =>
					reprExprAst(alloc, it))]),
		(ref immutable IfOptionAst it) =>
			reprRecord!"if"(alloc, [
				reprNameAndRange(alloc, it.name),
				reprExprAst(alloc, it.option),
				reprExprAst(alloc, it.then),
				reprOpt(alloc, it.else_, (ref immutable ExprAst it) =>
					reprExprAst(alloc, it))]),
		(immutable InterpolatedAst it) =>
			reprRecord!"interpolated"(alloc, [
				reprArr(alloc, it.parts, (ref immutable InterpolatedPart part) =>
					reprInterpolatedPart(alloc, part))]),
		(ref immutable LambdaAst it) =>
			reprRecord!"lambda"(alloc, [
				reprLambdaParamAsts(alloc, it.params),
				reprExprAst(alloc, it.body_)]),
		(ref immutable LetAst a) =>
			reprRecord!"let"(alloc, [
				reprSym(has(a.name) ? force(a.name) : sym!"_"),
				reprExprAst(alloc, a.initializer),
				reprExprAst(alloc, a.then)]),
		(immutable LiteralFloatAst a) =>
			reprLiteralFloatAst(alloc, a),
		(immutable LiteralIntAst a) =>
			reprLiteralIntAst(alloc, a),
		(immutable LiteralNatAst a) =>
			reprLiteralNatAst(alloc, a),
		(immutable LiteralStringAst a) =>
			reprLiteralStringAst(alloc, a),
		(ref immutable LoopAst a) =>
			reprRecord!"loop"(alloc, [reprExprAst(alloc, a.body_)]),
		(ref immutable LoopBreakAst e) =>
			reprRecord!"break"(alloc, [
				reprOpt(alloc, e.value, (ref immutable ExprAst value) =>
					reprExprAst(alloc, value))]),
		(immutable(LoopContinueAst)) =>
			reprSym!"continue" ,
		(ref immutable LoopUntilAst e) =>
			reprRecord!"until"(alloc, [
				reprExprAst(alloc, e.condition),
				reprExprAst(alloc, e.body_)]),
		(ref immutable LoopWhileAst e) =>
			reprRecord!"while"(alloc, [
				reprExprAst(alloc, e.condition),
				reprExprAst(alloc, e.body_)]),
		(ref immutable MatchAst it) =>
			reprRecord!"match"(alloc, [
				reprExprAst(alloc, it.matched),
				reprArr(alloc, it.cases, (ref immutable MatchAst.CaseAst case_) =>
					reprRecord!"case"(alloc, [
						reprRangeWithinFile(alloc, case_.range),
						reprSym(case_.memberName),
						case_.local.match!(immutable Repr)(
							(immutable(Sym) it) =>
								reprSym(it),
							(immutable NameOrUnderscoreOrNone.Underscore) =>
								reprStr("_"),
							(immutable NameOrUnderscoreOrNone.None) =>
								reprSym!"none"),
						reprExprAst(alloc, case_.then)]))]),
		(ref immutable ParenthesizedAst it) =>
			reprRecord!"paren"(alloc, [reprExprAst(alloc, it.inner)]),
		(ref immutable PtrAst a) =>
			reprRecord!"ptr"(alloc, [reprExprAst(alloc, a.inner)]),
		(ref immutable SeqAst a) =>
			reprRecord!"seq-ast"(alloc, [
				reprExprAst(alloc, a.first),
				reprExprAst(alloc, a.then)]),
		(ref immutable ThenAst it) =>
			reprRecord!"then"(alloc, [
				reprLambdaParamAsts(alloc, it.left),
				reprExprAst(alloc, it.futExpr),
				reprExprAst(alloc, it.then)]),
		(ref immutable ThrowAst it) =>
			reprRecord!"throw"(alloc, [reprExprAst(alloc, it.thrown)]),
		(ref immutable TypedAst it) =>
			reprRecord!"typed"(alloc, [
				reprExprAst(alloc, it.expr),
				reprTypeAst(alloc, it.type)]),
		(ref immutable UnlessAst it) =>
			reprRecord!"unless"(alloc, [
				reprExprAst(alloc, it.cond),
				reprExprAst(alloc, it.body_)]),
		(ref immutable WithAst x) =>
			reprRecord!"with"(alloc, [
				reprLambdaParamAsts(alloc, x.params),
				reprExprAst(alloc, x.arg),
				reprExprAst(alloc, x.body_)]));

immutable(Repr) reprInterpolatedPart(ref Alloc alloc, ref immutable InterpolatedPart a) =>
	a.match!(immutable Repr)(
		(immutable string it) => reprStr(it),
		(immutable ExprAst it) => reprExprAst(alloc, it));

immutable(Sym) symOfCallAstStyle(immutable CallAst.Style a) {
	final switch (a) {
		case CallAst.Style.comma:
			return sym!"comma";
		case CallAst.Style.dot:
			return sym!"dot";
		case CallAst.Style.emptyParens:
			return sym!"empty-parens";
		case CallAst.Style.infix:
			return sym!"infix";
		case CallAst.Style.prefix:
			return sym!"prefix";
		case CallAst.Style.prefixOperator:
			return sym!"prefix-op";
		case CallAst.Style.setDeref:
			return sym!"set-deref";
		case CallAst.Style.setDot:
			return sym!"set-dot";
		case CallAst.Style.setSubscript:
			return sym!"set-at";
		case CallAst.Style.single:
			return sym!"single";
		case CallAst.Style.subscript:
			return sym!"subscript";
		case CallAst.Style.suffixOperator:
			return sym!"suffix-op";
	}
}

immutable(Repr) reprTypeParams(ref Alloc alloc, immutable NameAndRange[] typeParams) =>
	reprArr(alloc, typeParams, (ref immutable NameAndRange a) =>
		reprNameAndRange(alloc, a));
