module frontend.parse.ast;

@safe @nogc pure nothrow:

import model.model : FieldMutability, symOfFieldMutability, Visibility;
import model.reprModel : reprVisibility;
import util.alloc.alloc : Alloc;
import util.col.arr : empty, emptyArr, emptySmallArray, SmallArray;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : arrLiteral;
import util.col.str : SafeCStr, safeCStr, safeCStrIsEmpty;
import util.conv : safeToUint;
import util.opt : force, has, none, Opt, some;
import util.path : PathOrRelPath, pathOrRelPathToStr, AllPaths;
import util.ptr : Ptr;
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
import util.sym : AllSymbols, shortSym, SpecialSym, Sym, symForSpecial, symSize;
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

immutable(RangeWithinFile) rangeOfNameAndRange(immutable NameAndRange a, ref const AllSymbols allSymbols) {
	return rangeOfStartAndName(a.start, a.name, allSymbols);
}

struct OptNameAndRange {
	immutable Pos start;
	immutable Opt!Sym name;
}

immutable(RangeWithinFile) rangeOfOptNameAndRange(immutable OptNameAndRange a, ref const AllSymbols allSymbols) {
	return rangeOfStartAndName(a.start, has(a.name) ? force(a.name) : shortSym("_"), allSymbols);
}

struct TypeAst {
	@safe @nogc pure nothrow:

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
		enum Kind {
			act,
			fun,
			ref_,
		}
		immutable RangeWithinFile range;
		immutable Kind kind;
		immutable TypeAst[] returnAndParamTypes;
	}

	struct InstStruct {
		immutable RangeWithinFile range;
		immutable NameAndRange name;
		immutable SmallArray!TypeAst typeArgs;
	}

	struct Suffix {
		@safe @nogc pure nothrow:

		enum Kind {
			arr,
			arrMut,
			opt,
			ptr,
			ptrMut,
		}
		immutable Kind kind;
		immutable TypeAst left;
	}

	immutable this(immutable Ptr!Dict a) { kind = Kind.dict; dict = a; }
	@trusted immutable this(immutable Fun a) { kind = Kind.fun; fun = a; }
	@trusted immutable this(immutable InstStruct a) { kind = Kind.instStruct; instStruct = a; }
	immutable this(immutable Ptr!Suffix a) { kind = Kind.suffix; suffix = a; }

	private:

	enum Kind {
		dict,
		fun,
		instStruct,
		suffix,
	}
	immutable Kind kind;
	union {
		immutable Ptr!Dict dict;
		immutable Fun fun;
		immutable InstStruct instStruct;
		immutable Ptr!Suffix suffix;
	}
}
static assert(TypeAst.sizeof <= 40);

@trusted immutable(T) matchTypeAst(T, alias cbDict, alias cbFun, alias cbInstStruct, alias cbSuffix)(
	immutable TypeAst a,
) {
	final switch (a.kind) {
		case TypeAst.Kind.dict:
			return cbDict(a.dict.deref());
		case TypeAst.Kind.fun:
			return cbFun(a.fun);
		case TypeAst.Kind.instStruct:
			return cbInstStruct(a.instStruct);
		case TypeAst.Kind.suffix:
			return cbSuffix(a.suffix.deref());
	}
}

immutable(TypeAst) bogusTypeAst(immutable RangeWithinFile range) {
	return immutable TypeAst(immutable TypeAst.InstStruct(
		range,
		immutable NameAndRange(range.start, shortSym("bogus")),
		emptySmallArray!TypeAst));
}

immutable(RangeWithinFile) range(immutable TypeAst a) {
	return matchTypeAst!(
		immutable RangeWithinFile,
		(immutable TypeAst.Dict it) => range(it),
		(immutable TypeAst.Fun it) => it.range,
		(immutable TypeAst.InstStruct it) => it.range,
		(immutable TypeAst.Suffix it) => range(it),
	)(a);
}

immutable(RangeWithinFile) range(immutable TypeAst.Dict a) {
	return immutable RangeWithinFile(range(a.v).start, safeToUint(range(a.k).end + "]".length));
}

immutable(RangeWithinFile) range(immutable TypeAst.Suffix a) {
	immutable RangeWithinFile leftRange = range(a.left);
	return immutable RangeWithinFile(leftRange.start, leftRange.end + suffixLength(a.kind));
}
immutable(RangeWithinFile) suffixRange(immutable TypeAst.Suffix a) {
	immutable uint leftEnd = range(a.left).end;
	return immutable RangeWithinFile(leftEnd, leftEnd + suffixLength(a.kind));
}

private immutable(uint) suffixLength(immutable TypeAst.Suffix.Kind a) {
	final switch (a) {
		case TypeAst.Suffix.Kind.arr:
			return cast(uint) "[]".length;
		case TypeAst.Suffix.Kind.arrMut:
			return cast(uint) "mut[]".length;
		case TypeAst.Suffix.Kind.opt:
			return cast(uint) "?".length;
		case TypeAst.Suffix.Kind.ptr:
			return cast(uint) "*".length;
		case TypeAst.Suffix.Kind.ptrMut:
			return cast(uint) "mut*".length;
	}
}

immutable(Sym) symForTypeAstDict(immutable TypeAst.Dict.Kind a) {
	final switch (a) {
		case TypeAst.Dict.Kind.data:
			return shortSym("dict");
		case TypeAst.Dict.Kind.mut:
			return shortSym("mut-dict");
	}
}

immutable(Sym) symForTypeAstSuffix(immutable TypeAst.Suffix.Kind a) {
	final switch (a) {
		case TypeAst.Suffix.Kind.arr:
			return shortSym("arr");
		case TypeAst.Suffix.Kind.arrMut:
			return shortSym("mut-arr");
		case TypeAst.Suffix.Kind.opt:
			return shortSym("opt");
		case TypeAst.Suffix.Kind.ptr:
			return shortSym("const-ptr");
		case TypeAst.Suffix.Kind.ptrMut:
			return shortSym("mut-ptr");
	}
}

struct ArrowAccessAst {
	immutable ExprAst left;
	immutable NameAndRange name;
	immutable SmallArray!TypeAst typeArgs;
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
		setSingle, // a := b
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

	immutable(NameAndRange) funName() immutable {
		return immutable NameAndRange(funNameStart, funNameName);
	}
}

struct FunPtrAst {
	immutable Sym name;
}

struct IdentifierAst {
	immutable Sym name;
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
	immutable InterpolatedPart[] parts;
}

struct InterpolatedPart {
	@safe @nogc pure nothrow:

	@trusted immutable this(immutable string a) { kind = Kind.string_; string_ = a; }
	@trusted immutable this(immutable ExprAst a) { kind = Kind.expr; expr = a; }

	private:
	enum Kind {
		string_,
		expr,
	}
	immutable Kind kind;
	union {
		immutable string string_;
		immutable ExprAst expr;
	}
}

@trusted T matchInterpolatedPart(T, alias cbString, alias cbExpr)(ref immutable InterpolatedPart a) {
	final switch (a.kind) {
		case InterpolatedPart.Kind.string_:
			return cbString(a.string_);
		case InterpolatedPart.Kind.expr:
			return cbExpr(a.expr);
	}
}

struct LambdaAst {
	alias Param = OptNameAndRange;
	immutable Param[] params;
	immutable ExprAst body_;
}

struct LetAst {
	immutable Opt!Sym name;
	immutable Opt!(Ptr!TypeAst) type;
	immutable ExprAst initializer;
	immutable ExprAst then;
}

struct LiteralAst {
	@safe @nogc pure nothrow:

	struct Float {
		immutable double value;
		immutable bool overflow;
	}
	struct Int {
		immutable long value;
		immutable bool overflow;
	}
	struct Nat {
		immutable ulong value;
		immutable bool overflow;
	}

	immutable this(immutable Float a) { kind = Kind.float_; float_ = a; }
	immutable this(immutable Int a) { kind = Kind.int_; int_ = a; }
	immutable this(immutable Nat a) { kind = Kind.nat; nat = a; }
	@trusted immutable this(immutable string a) { kind = Kind.str; str = a; }

	private:
	enum Kind {
		float_,
		int_,
		nat,
		str,
	}
	immutable Kind kind;
	union {
		immutable Float float_;
		immutable Int int_;
		immutable Nat nat;
		immutable string str;
	}
}

@trusted T matchLiteralAst(T, alias cbFloat, alias cbInt, alias cbNat, alias cbStr)(
	ref immutable LiteralAst a,
) {
	final switch (a.kind) {
		case LiteralAst.Kind.float_:
			return cbFloat(a.float_);
		case LiteralAst.Kind.int_:
			return cbInt(a.int_);
		case LiteralAst.Kind.nat:
			return cbNat(a.nat);
		case LiteralAst.Kind.str:
			return cbStr(a.str);
	}
}

struct NameOrUnderscoreOrNone {
	@safe @nogc pure nothrow:

	struct Underscore {}
	struct None {}

	immutable this(immutable Sym a) { kind = Kind.name; name = a; }
	immutable this(immutable Underscore a) { kind = Kind.underscore; underscore = a; }
	immutable this(immutable None a) { kind = Kind.none; none = a; }

	private:
	enum Kind {
		name,
		underscore,
		none,
	}
	immutable Kind kind;
	union {
		immutable Sym name;
		immutable Underscore underscore;
		immutable None none;
	}
}

@trusted immutable(T) matchNameOrUnderscoreOrNone(T, alias cbName, alias cbUnderscore, alias cbNone)(
	ref immutable NameOrUnderscoreOrNone a,
) {
	final switch (a.kind) {
		case NameOrUnderscoreOrNone.Kind.name:
			return cbName(a.name);
		case NameOrUnderscoreOrNone.Kind.underscore:
			return cbUnderscore(a.underscore);
		case NameOrUnderscoreOrNone.Kind.none:
			return cbNone(a.none);
	}
}

// Includes size of the ' ' before the name (but not for None)
private immutable(size_t) nameOrUnderscoreOrNoneSize(
	ref const AllSymbols allSymbols,
	ref immutable NameOrUnderscoreOrNone a,
) {
	return matchNameOrUnderscoreOrNone!(
		size_t,
		(immutable Sym s) => 1 + symSize(allSymbols, s),
		(ref immutable NameOrUnderscoreOrNone.Underscore) => immutable size_t(2),
		(ref immutable NameOrUnderscoreOrNone.None) => immutable size_t(0),
	)(a);
}

struct MatchAst {
	struct CaseAst {
		@safe @nogc pure nothrow:

		immutable RangeWithinFile range;
		immutable Sym memberName;
		immutable NameOrUnderscoreOrNone local;
		immutable ExprAst then;

		//TODO: NOT INSTANCE
		immutable(RangeWithinFile) memberNameRange(ref const AllSymbols allSymbols) immutable {
			return rangeOfStartAndName(safeToUint(range.start + "as ".length), memberName, allSymbols);
		}

		immutable(RangeWithinFile) localRange(ref const AllSymbols allSymbols) immutable {
			return rangeOfStartAndLength(
				memberNameRange(allSymbols).end,
				nameOrUnderscoreOrNoneSize(allSymbols, local));
		}
	}

	immutable ExprAst matched;
	immutable CaseAst[] cases;
}

struct ParenthesizedAst {
	immutable ExprAst inner;
}

struct SeqAst {
	immutable ExprAst first;
	immutable ExprAst then;
}

struct ThenAst {
	immutable LambdaAst.Param left;
	immutable ExprAst futExpr;
	immutable ExprAst then;
}

struct ThenVoidAst {
	immutable ExprAst futExpr;
	immutable ExprAst then;
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

struct ExprAstKind {
	@safe @nogc pure nothrow:

	private:
	enum Kind {
		arrowAccess,
		bogus,
		call,
		funPtr,
		identifier,
		if_,
		ifOption,
		interpolated,
		lambda,
		let,
		literal,
		match,
		parenthesized,
		seq,
		then,
		thenVoid,
		typed,
		unless,
	}
	immutable Kind kind;
	union {
		immutable Ptr!ArrowAccessAst arrowAccess;
		immutable BogusAst bogus;
		immutable CallAst call;
		immutable FunPtrAst funPtr;
		immutable IdentifierAst identifier;
		immutable Ptr!IfAst if_;
		immutable Ptr!IfOptionAst ifOption;
		immutable InterpolatedAst interpolated;
		immutable Ptr!LambdaAst lambda;
		immutable Ptr!LetAst let;
		immutable LiteralAst literal;
		immutable Ptr!MatchAst match_;
		immutable Ptr!ParenthesizedAst parenthesized;
		immutable Ptr!SeqAst seq;
		immutable Ptr!ThenAst then;
		immutable Ptr!ThenVoidAst thenVoid;
		immutable Ptr!TypedAst typed;
		immutable Ptr!UnlessAst unless;
	}

	public:
	@trusted immutable this(immutable Ptr!ArrowAccessAst a) { kind = Kind.arrowAccess; arrowAccess = a; }
	@trusted immutable this(immutable BogusAst a) { kind = Kind.bogus; bogus = a; }
	@trusted immutable this(immutable CallAst a) { kind = Kind.call; call = a; }
	@trusted immutable this(immutable FunPtrAst a) { kind = Kind.funPtr; funPtr = a; }
	@trusted immutable this(immutable IdentifierAst a) { kind = Kind.identifier; identifier = a; }
	@trusted immutable this(immutable Ptr!IfAst a) { kind = Kind.if_; if_ = a; }
	@trusted immutable this(immutable Ptr!IfOptionAst a) { kind = Kind.ifOption; ifOption = a; }
	@trusted immutable this(immutable InterpolatedAst a) { kind = Kind.interpolated; interpolated = a; }
	@trusted immutable this(immutable Ptr!LambdaAst a) { kind = Kind.lambda; lambda = a; }
	@trusted immutable this(immutable Ptr!LetAst a) { kind = Kind.let; let = a; }
	@trusted immutable this(immutable LiteralAst a) { kind = Kind.literal; literal = a; }
	@trusted immutable this(immutable Ptr!MatchAst a) { kind = Kind.match; match_ = a; }
	@trusted immutable this(immutable Ptr!ParenthesizedAst a) { kind = Kind.parenthesized; parenthesized = a; }
	@trusted immutable this(immutable Ptr!SeqAst a) { kind = Kind.seq; seq = a; }
	@trusted immutable this(immutable Ptr!ThenAst a) { kind = Kind.then; then = a; }
	@trusted immutable this(immutable Ptr!ThenVoidAst a) { kind = Kind.thenVoid; thenVoid = a; }
	immutable this(immutable Ptr!TypedAst a) { kind = Kind.typed; typed = a; }
	immutable this(immutable Ptr!UnlessAst a) { kind = Kind.unless; unless = a; }
}
static assert(ExprAstKind.sizeof <= 40);

immutable(bool) isCall(ref immutable ExprAstKind a) {
	return a.kind == ExprAstKind.Kind.call;
}
@trusted ref immutable(CallAst) asCall(return scope ref immutable ExprAstKind a) {
	verify(isCall(a));
	return a.call;
}

immutable(bool) isIdentifier(ref immutable ExprAstKind a) {
	return a.kind == ExprAstKind.Kind.identifier;
}
ref immutable(IdentifierAst) asIdentifier(return scope ref immutable ExprAstKind a) {
	verify(isIdentifier(a));
	return a.identifier;
}

@trusted T matchExprAstKind(
	T,
	alias cbArrowAccess,
	alias cbBogus,
	alias cbCall,
	alias cbFunPtr,
	alias cbIdentifier,
	alias cbIf,
	alias cbIfOption,
	alias cbInterpolated,
	alias cbLambda,
	alias cbLet,
	alias cbLiteral,
	alias cbMatch,
	alias cbParenthesized,
	alias cbSeq,
	alias cbThen,
	alias cbThenVoid,
	alias cbTyped,
	alias cbUnless,
)(
	scope ref immutable ExprAstKind a,
) {
	final switch (a.kind) {
		case ExprAstKind.Kind.arrowAccess:
			return cbArrowAccess(a.arrowAccess.deref());
		case ExprAstKind.Kind.bogus:
			return cbBogus(a.bogus);
		case ExprAstKind.Kind.call:
			return cbCall(a.call);
		case ExprAstKind.Kind.funPtr:
			return cbFunPtr(a.funPtr);
		case ExprAstKind.Kind.identifier:
			return cbIdentifier(a.identifier);
		case ExprAstKind.Kind.if_:
			return cbIf(a.if_.deref());
		case ExprAstKind.Kind.ifOption:
			return cbIfOption(a.ifOption.deref());
		case ExprAstKind.Kind.interpolated:
			return cbInterpolated(a.interpolated);
		case ExprAstKind.Kind.lambda:
			return cbLambda(a.lambda.deref());
		case ExprAstKind.Kind.let:
			return cbLet(a.let.deref());
		case ExprAstKind.Kind.literal:
			return cbLiteral(a.literal);
		case ExprAstKind.Kind.match:
			return cbMatch(a.match_.deref());
		case ExprAstKind.Kind.parenthesized:
			return cbParenthesized(a.parenthesized.deref());
		case ExprAstKind.Kind.seq:
			return cbSeq(a.seq.deref());
		case ExprAstKind.Kind.then:
			return cbThen(a.then.deref());
		case ExprAstKind.Kind.thenVoid:
			return cbThenVoid(a.thenVoid.deref());
		case ExprAstKind.Kind.typed:
			return cbTyped(a.typed.deref());
		case ExprAstKind.Kind.unless:
			return cbUnless(a.unless.deref());
	}
}

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

struct SpecUseAst {
	immutable RangeWithinFile range;
	immutable NameAndRange spec;
	immutable SmallArray!TypeAst typeArgs;
}

struct ParamsAst {
	@safe @nogc pure nothrow:

	struct Varargs {
		immutable ParamAst param;
	}

	immutable this(immutable ParamAst[] a) { kind = Kind.regular; regular = a; }
	immutable this(immutable Ptr!Varargs a) { kind = Kind.varargs; varargs = a; }

	private:

	enum Kind {
		regular,
		varargs,
	}
	immutable Kind kind;
	union {
		immutable SmallArray!ParamAst regular;
		immutable Ptr!Varargs varargs;
	}
}

@trusted immutable(T) matchParamsAst(T, alias cbRegular, alias cbVarargs)(ref immutable ParamsAst a) {
	final switch (a.kind) {
		case ParamsAst.Kind.regular:
			return cbRegular(a.regular);
		case ParamsAst.Kind.varargs:
			return cbVarargs(a.varargs.deref());
	}
}

struct SpecSigAst {
	immutable SafeCStr docComment;
	immutable SigAst sig;
}

struct SigAst {
	immutable RangeWithinFile range;
	immutable Sym name; // Range starts at sig.range.start
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
		forceData,
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

immutable(RangeWithinFile) rangeOfModifierAst(immutable ModifierAst a, ref const AllSymbols allSymbols) {
	return rangeOfStartAndName(a.pos, symOfModifierKind(a.kind), allSymbols);
}

struct LiteralIntOrNat {
	@safe @nogc pure nothrow:

	immutable this(immutable LiteralAst.Int a) { kind = Kind.int_; int_ = a; }
	immutable this(immutable LiteralAst.Nat a) { kind = Kind.nat; nat = a; }

	private:
	enum Kind { int_, nat }
	immutable Kind kind;
	union {
		immutable LiteralAst.Int int_;
		immutable LiteralAst.Nat nat;
	}
}

@trusted immutable(T) matchLiteralIntOrNat(T, alias cbInt, alias cbNat)(ref immutable LiteralIntOrNat a) {
	final switch (a.kind) {
		case LiteralIntOrNat.Kind.int_:
			return cbInt(a.int_);
		case LiteralIntOrNat.Kind.nat:
			return cbNat(a.nat);
	}
}

struct StructDeclAst {
	struct Body {
		@safe @nogc pure nothrow:
		struct Builtin {}
		struct Enum {
			struct Member {
				immutable RangeWithinFile range;
				immutable Sym name;
				immutable Opt!LiteralIntOrNat value;
			}

			immutable Opt!(Ptr!TypeAst) typeArg;
			immutable SmallArray!Member members;
		}
		struct Flags {
			alias Member = Enum.Member;
			immutable Opt!(Ptr!TypeAst) typeArg;
			immutable SmallArray!Member members;
		}
		struct ExternPtr {}
		struct Record {
			@safe @nogc pure nothrow:

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

		private:
		enum Kind {
			builtin,
			enum_,
			flags,
			externPtr,
			record,
			union_,
		}

		immutable Kind kind;
		union {
			immutable Builtin builtin;
			immutable Enum enum_;
			immutable Flags flags;
			immutable ExternPtr externPtr;
			immutable Record record;
			immutable Union union_;
		}

		public:

		immutable this(immutable Builtin a) { kind = Kind.builtin; builtin = a; }
		@trusted immutable this(immutable Enum a) { kind = Kind.enum_; enum_ = a; }
		@trusted immutable this(immutable Flags a) { kind = Kind.flags; flags = a; }
		immutable this(immutable ExternPtr a) { kind = Kind.externPtr; externPtr = a; }
		@trusted immutable this(immutable Record a) { kind = Kind.record; record = a; }
		@trusted immutable this(immutable Union a) { kind = Kind.union_; union_ = a; }
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

immutable(bool) isRecord(ref immutable StructDeclAst.Body a) {
	return a.kind == StructDeclAst.Body.Kind.record;
}

@trusted T matchStructDeclAstBody(
	T,
	alias cbBuiltin,
	alias cbEnum,
	alias cbFlags,
	alias cbExternPtr,
	alias cbRecord,
	alias cbUnion,
)(ref immutable StructDeclAst.Body a) {
	final switch (a.kind) {
		case StructDeclAst.Body.Kind.builtin:
			return cbBuiltin(a.builtin);
		case StructDeclAst.Body.Kind.enum_:
			return cbEnum(a.enum_);
		case StructDeclAst.Body.Kind.flags:
			return cbFlags(a.flags);
		case StructDeclAst.Body.Kind.externPtr:
			return cbExternPtr(a.externPtr);
		case StructDeclAst.Body.Kind.record:
			return cbRecord(a.record);
		case StructDeclAst.Body.Kind.union_:
			return cbUnion(a.union_);
	}
}

struct SpecBodyAst {
	@safe @nogc pure nothrow:

	struct Builtin {}

	private:
	enum Kind {
		builtin,
		sigs,
	}
	immutable Kind kind;
	union {
		immutable Builtin builtin;
		immutable SpecSigAst[] sigs;
	}

	public:
	immutable this(immutable Builtin a) { kind = Kind.builtin; builtin = a; }
	@trusted immutable this(immutable SpecSigAst[] a) { kind = Kind.sigs; sigs = a; }
}

@trusted T matchSpecBodyAst(T, alias cbBuiltin, alias cbSigs)(ref immutable SpecBodyAst a) {
	final switch (a.kind) {
		case SpecBodyAst.Kind.builtin:
			return cbBuiltin(a.builtin);
		case SpecBodyAst.Kind.sigs:
			return cbSigs(a.sigs);
	}
}

struct SpecDeclAst {
	immutable RangeWithinFile range;
	immutable SafeCStr docComment;
	immutable Visibility visibility;
	immutable Sym name;
	immutable SmallArray!NameAndRange typeParams;
	immutable SpecBodyAst body_;
}

struct FunBodyAst {
	@safe @nogc pure nothrow:

	struct Builtin {}
	struct Extern {
		immutable bool isGlobal;
		immutable Opt!Sym libraryName;
	}

	private:
	enum Kind {
		builtin,
		extern_,
		exprAst,
	}
	immutable Kind kind;
	union {
		immutable Builtin builtin;
		immutable Extern extern_;
		immutable ExprAst exprAst;
	}

	public:
	immutable this(immutable Builtin a) { kind = Kind.builtin; builtin = a; }
	@trusted immutable this(immutable Extern a) { kind = Kind.extern_; extern_ = a; }
	@trusted immutable this(immutable ExprAst a) { kind = Kind.exprAst; exprAst = a; }
}

@trusted T matchFunBodyAst(T, alias cbBuiltin, alias cbExtern, alias cbExprAst)(ref immutable FunBodyAst a) {
	final switch (a.kind) {
		case FunBodyAst.Kind.builtin:
			return cbBuiltin(a.builtin);
		case FunBodyAst.Kind.extern_:
			return cbExtern(a.extern_);
		case FunBodyAst.Kind.exprAst:
			return cbExprAst(a.exprAst);
	}
}

struct FunDeclAst {
	immutable RangeWithinFile range;
	immutable SafeCStr docComment;
	immutable SmallArray!NameAndRange typeParams;
	immutable SigAst sig;
	immutable SpecUseAst[] specUses;
	immutable Visibility visibility;
	immutable FunDeclAstFlags flags;
	immutable FunBodyAst body_;
}

struct FunDeclAstFlags {
	@safe @nogc pure nothrow:

	immutable bool noCtx;
	immutable bool noDoc;
	immutable bool summon;
	immutable bool trusted;
	immutable bool unsafe;

	immutable(FunDeclAstFlags) withNoCtx() immutable {
		return immutable FunDeclAstFlags(true, noDoc, summon, trusted, unsafe);
	}
	immutable(FunDeclAstFlags) withNoDoc() immutable {
		return immutable FunDeclAstFlags(noCtx, true, summon, trusted, unsafe);
	}
	immutable(FunDeclAstFlags) withSummon() immutable {
		return immutable FunDeclAstFlags(noCtx, noDoc, true, trusted, unsafe);
	}
	immutable(FunDeclAstFlags) withTrusted() immutable {
		return immutable FunDeclAstFlags(noCtx, noDoc, summon, true, unsafe);
	}
	immutable(FunDeclAstFlags) withUnsafe() immutable {
		return immutable FunDeclAstFlags(noCtx, noDoc, summon, trusted, true);
	}
}

struct TestAst {
	immutable ExprAst body_;
}

struct ImportAst {
	immutable RangeWithinFile range;
	immutable PathOrRelPath path;
	immutable Opt!(Sym[]) names;
}

struct ImportsOrExportsAst {
	immutable RangeWithinFile range;
	immutable ImportAst[] paths;
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

private immutable ImportsOrExportsAst emptyImportsOrExports =
	immutable ImportsOrExportsAst(RangeWithinFile.empty, emptyArr!ImportAst);
immutable FileAst emptyFileAst = immutable FileAst(
	safeCStr!"",
	true,
	some(emptyImportsOrExports),
	some(emptyImportsOrExports),
	emptyArr!SpecDeclAst,
	emptyArr!StructAliasAst,
	emptyArr!StructDeclAst,
	emptyArr!FunDeclAst,
	emptyArr!TestAst);

immutable(Repr) reprAst(
	ref Alloc alloc,
	ref const AllPaths allPaths,
	ref immutable FileAst ast,
) {
	ArrBuilder!NameAndRepr args;
	if (has(ast.imports))
		add(alloc, args, nameAndRepr("imports", reprImportsOrExports(alloc, allPaths, force(ast.imports))));
	if (has(ast.exports))
		add(alloc, args, nameAndRepr("exports", reprImportsOrExports(alloc, allPaths, force(ast.exports))));
	add(alloc, args, nameAndRepr("specs", reprArr(alloc, ast.specs, (ref immutable SpecDeclAst a) =>
		reprSpecDeclAst(alloc, a))));
	add(alloc, args, nameAndRepr("aliases", reprArr(alloc, ast.structAliases, (ref immutable StructAliasAst a) =>
		reprStructAliasAst(alloc, a))));
	add(alloc, args, nameAndRepr("structs", reprArr(alloc, ast.structs, (ref immutable StructDeclAst a) =>
		reprStructDeclAst(alloc, a))));
	add(alloc, args, nameAndRepr("funs", reprArr(alloc, ast.funs, (ref immutable FunDeclAst a) =>
		reprFunDeclAst(alloc, a))));
	return reprNamedRecord("file-ast", finishArr(alloc, args));
}

private:

immutable(Repr) reprImportsOrExports(
	ref Alloc alloc,
	ref const AllPaths allPaths,
	ref immutable ImportsOrExportsAst a,
) {
	return reprRecord(alloc, "ports", [
		reprRangeWithinFile(alloc, a.range),
		reprArr(alloc, a.paths, (ref immutable ImportAst a) =>
			reprImportAst(alloc, allPaths, a))]);
}

immutable(Repr) reprImportAst(
	ref Alloc alloc,
	ref const AllPaths allPaths,
	ref immutable ImportAst a,
) {
	return reprRecord(alloc, "import-ast", [
		reprStr(pathOrRelPathToStr(alloc, allPaths, a.path)),
		reprOpt!(Sym[])(alloc, a.names, (ref immutable Sym[] names) =>
			reprArr(alloc, names, (ref immutable Sym name) =>
				reprSym(name)))]);
}

immutable(Repr) reprSpecDeclAst(ref Alloc alloc, ref immutable SpecDeclAst a) {
	return reprRecord(alloc, "spec-decl", [
		reprRangeWithinFile(alloc, a.range),
		reprStr(a.docComment),
		reprVisibility(a.visibility),
		reprSym(a.name),
		reprTypeParams(alloc, a.typeParams),
		reprSpecBodyAst(alloc, a.body_)]);
}

immutable(Repr) reprSpecBodyAst(ref Alloc alloc, ref immutable SpecBodyAst a) {
	return matchSpecBodyAst!(
		immutable Repr,
		(ref immutable SpecBodyAst.Builtin) =>
			reprSym("builtin"),
		(ref immutable SpecSigAst[] sigs) =>
			reprArr(alloc, sigs, (ref immutable SpecSigAst sig) =>
				reprRecord(alloc, "spec-sig", [
					reprStr(sig.docComment),
					reprSig(alloc, sig.sig)])),
	)(a);
}

immutable(Repr) reprStructAliasAst(ref Alloc alloc, ref immutable StructAliasAst a) {
	return reprRecord(alloc, "alias", [
		reprRangeWithinFile(alloc, a.range),
		reprStr(a.docComment),
		reprVisibility(a.visibility),
		reprSym(a.name),
		reprTypeParams(alloc, a.typeParams),
		reprTypeAst(alloc, a.target)]);
}


immutable(Repr) reprEnumOrFlags(
	ref Alloc alloc,
	immutable string name,
	immutable Opt!(Ptr!TypeAst) typeArg,
	immutable StructDeclAst.Body.Enum.Member[] members,
) {
	return reprRecord(alloc, name, [
		reprOpt(alloc, typeArg, (ref immutable Ptr!TypeAst it) =>
			reprTypeAst(alloc, it.deref())),
		reprArr(alloc, members, (ref immutable StructDeclAst.Body.Enum.Member it) =>
			reprEnumMember(alloc, it))]);
}

immutable(Repr) reprEnumMember(ref Alloc alloc, ref immutable StructDeclAst.Body.Enum.Member a) {
	return reprRecord(alloc, "member", [
		reprRangeWithinFile(alloc, a.range),
		reprSym(a.name),
		reprOpt(alloc, a.value, (ref immutable LiteralIntOrNat v) =>
			reprLiteralIntOrNat(alloc, v))]);
}

immutable(Repr) reprLiteralAst(ref Alloc alloc, ref immutable LiteralAst a) {
	return reprRecord(alloc, "literal", [
		matchLiteralAst!(
			immutable Repr,
			(immutable LiteralAst.Float it) =>
				reprRecord(alloc, "float", [reprFloat(it.value), reprBool(it.overflow)]),
			(immutable LiteralAst.Int it) =>
				reprLiteralInt(alloc, it),
			(immutable LiteralAst.Nat it) =>
				reprLiteralNat(alloc, it),
			(immutable string it) =>
				reprStr(it),
		)(a)]);
}

immutable(Repr) reprLiteralInt(ref Alloc alloc, ref immutable LiteralAst.Int a) {
	return reprRecord(alloc, "int", [reprInt(a.value), reprBool(a.overflow)]);
}

immutable(Repr) reprLiteralNat(ref Alloc alloc, ref immutable LiteralAst.Nat a) {
	return reprRecord(alloc, "nat", [reprNat(a.value), reprBool(a.overflow)]);
}

immutable(Repr) reprLiteralIntOrNat(ref Alloc alloc, ref immutable LiteralIntOrNat a) {
	return matchLiteralIntOrNat!(
		immutable Repr,
		(ref immutable LiteralAst.Int it) =>
			reprLiteralInt(alloc, it),
		(ref immutable LiteralAst.Nat it) =>
			reprLiteralNat(alloc, it),
	)(a);
}

immutable(Repr) reprField(ref Alloc alloc, ref immutable StructDeclAst.Body.Record.Field a) {
	return reprRecord(alloc, "field", [
		reprRangeWithinFile(alloc, a.range),
		reprSym(symOfFieldMutability(a.mutability)),
		reprSym(a.name),
		reprTypeAst(alloc, a.type)]);
}

immutable(Repr) reprRecord(ref Alloc alloc, ref immutable StructDeclAst.Body.Record a) {
	return reprRecord(alloc, "record", [
		reprArr(alloc, a.fields, (ref immutable StructDeclAst.Body.Record.Field it) =>
			reprField(alloc, it))]);
}

public immutable(Sym) symOfModifierKind(immutable ModifierAst.Kind a) {
	final switch (a) {
		case ModifierAst.Kind.byRef:
			return shortSym("by-ref");
		case ModifierAst.Kind.byVal:
			return shortSym("by-val");
		case ModifierAst.Kind.data:
			return shortSym("data");
		case ModifierAst.Kind.extern_:
			return shortSym("extern");
		case ModifierAst.Kind.forceData:
			return shortSym("force-data");
		case ModifierAst.Kind.forceSendable:
			return symForSpecial(SpecialSym.force_sendable);
		case ModifierAst.Kind.mut:
			return shortSym("mut");
		case ModifierAst.Kind.newPrivate:
			return symForSpecial(SpecialSym.dotNew);
		case ModifierAst.Kind.newPublic:
			return shortSym("new");
		case ModifierAst.Kind.packed:
			return shortSym("packed");
		case ModifierAst.Kind.sendable:
			return shortSym("sendable");
	}
}

immutable(Repr) reprUnion(ref Alloc alloc, ref immutable StructDeclAst.Body.Union a) {
	return reprRecord(alloc, "union", [
		reprArr(alloc, a.members, (ref immutable StructDeclAst.Body.Union.Member it) =>
			reprRecord(alloc, "member", [
				reprSym(it.name),
				reprOpt(alloc, it.type, (ref immutable TypeAst t) =>
					reprTypeAst(alloc, t))]))]);
}

immutable(Repr) reprStructBodyAst(ref Alloc alloc, ref immutable StructDeclAst.Body a) {
	return matchStructDeclAstBody!(
		immutable Repr,
		(ref immutable StructDeclAst.Body.Builtin) =>
			reprSym("builtin"),
		(ref immutable StructDeclAst.Body.Enum e) =>
			reprEnumOrFlags(alloc, "enum", e.typeArg, e.members),
		(ref immutable StructDeclAst.Body.Flags e) =>
			reprEnumOrFlags(alloc, "flags", e.typeArg, e.members),
		(ref immutable StructDeclAst.Body.ExternPtr) =>
			reprSym("extern-ptr"),
		(ref immutable StructDeclAst.Body.Record a) =>
			reprRecord(alloc, a),
		(ref immutable StructDeclAst.Body.Union a) =>
			reprUnion(alloc, a),
	)(a);
}

immutable(Repr) reprStructDeclAst(ref Alloc alloc, ref immutable StructDeclAst a) {
	ArrBuilder!NameAndRepr fields;
	add(alloc, fields, nameAndRepr("range", reprRangeWithinFile(alloc, a.range)));
	if (!safeCStrIsEmpty(a.docComment))
		add(alloc, fields, nameAndRepr("doc", reprStr(a.docComment)));
	add(alloc, fields, nameAndRepr("visibility", reprVisibility(a.visibility)));
	maybeAddTypeParams(alloc, fields, a.typeParams);
	if (!empty(a.modifiers))
		add(alloc, fields, nameAndRepr("modifiers", reprArr(alloc, a.modifiers, (ref immutable ModifierAst x) =>
			reprModifierAst(alloc, x))));
	add(alloc, fields, nameAndRepr("body", reprStructBodyAst(alloc, a.body_)));
	return reprNamedRecord("struct-decl", finishArr(alloc, fields));
}

void maybeAddTypeParams(ref Alloc alloc, ref ArrBuilder!NameAndRepr fields, immutable NameAndRange[] typeParams) {
	if (!empty(typeParams))
		add(alloc, fields, nameAndRepr("type-params", reprTypeParams(alloc, typeParams)));
}

immutable(Repr) reprModifierAst(ref Alloc alloc, immutable ModifierAst a) {
	return reprRecord(alloc, "modifier", [reprNat(a.pos), reprSym(symOfModifierKind(a.kind))]);
}

immutable(Repr) reprFunDeclAst(ref Alloc alloc, ref immutable FunDeclAst a) {
	ArrBuilder!NameAndRepr fields;
	if (!safeCStrIsEmpty(a.docComment))
		add(alloc, fields, nameAndRepr("doc", reprStr(a.docComment)));
	add(alloc, fields, nameAndRepr("visibility", reprVisibility(a.visibility)));
	maybeAddTypeParams(alloc, fields, a.typeParams);
	add(alloc, fields, nameAndRepr("sig", reprSig(alloc, a.sig)));
	if (!empty(a.specUses))
		add(alloc, fields, nameAndRepr("spec-uses", reprArr(alloc, a.specUses, (ref immutable SpecUseAst s) =>
			reprSpecUseAst(alloc, s))));
	if (a.flags.noDoc)
		add(alloc, fields, nameAndRepr("nodoc", reprBool(true)));
	if (a.flags.noCtx)
		add(alloc, fields, nameAndRepr("noctx", reprBool(true)));
	if (a.flags.summon)
		add(alloc, fields, nameAndRepr("summon", reprBool(true)));
	if (a.flags.unsafe)
		add(alloc, fields, nameAndRepr("unsafe", reprBool(true)));
	if (a.flags.trusted)
		add(alloc, fields, nameAndRepr("trusted", reprBool(true)));
	add(alloc, fields, nameAndRepr("body", reprFunBodyAst(alloc, a.body_)));
	return reprNamedRecord("fun-decl", finishArr(alloc, fields));
}

immutable(Repr) reprSig(ref Alloc alloc, ref immutable SigAst a) {
	return reprRecord(alloc, "sig-ast", [
		reprRangeWithinFile(alloc, a.range),
		reprSym(a.name),
		reprTypeAst(alloc, a.returnType),
		matchParamsAst!(
			immutable Repr,
			(immutable ParamAst[] params) =>
				reprArr(alloc, params, (ref immutable ParamAst p) => reprParamAst(alloc, p)),
			(ref immutable ParamsAst.Varargs v) =>
				reprRecord(alloc, "varargs", [reprParamAst(alloc, v.param)]),
		)(a.params)]);
}

immutable(Repr) reprSpecUseAst(ref Alloc alloc, ref immutable SpecUseAst a) {
	return reprRecord(alloc, "spec-use", [
		reprRangeWithinFile(alloc, a.range),
		reprSym(a.spec.name),
		reprArr(alloc, a.typeArgs, (ref immutable TypeAst it) =>
			reprTypeAst(alloc, it))]);
}

immutable(Repr) reprTypeAst(ref Alloc alloc, immutable TypeAst a) {
	return matchTypeAst!(
		immutable Repr,
		(immutable TypeAst.Dict it) =>
			reprRecord(alloc, "dict", [
				reprTypeAst(alloc, it.v),
				reprTypeAst(alloc, it.k)]),
		(immutable TypeAst.Fun it) =>
			reprRecord(alloc, "fun", [
				reprRangeWithinFile(alloc, it.range),
				reprSym(symOfFunKind(it.kind)),
				reprArr(alloc, it.returnAndParamTypes, (ref immutable TypeAst t) =>
					reprTypeAst(alloc, t))]),
		(immutable TypeAst.InstStruct i) =>
			reprInstStructAst(alloc, i),
		(immutable TypeAst.Suffix it) =>
			reprRecord(alloc, "suffix", [
				reprTypeAst(alloc, it.left),
				reprSym(symForTypeAstSuffix(it.kind))]),
	)(a);
}

immutable(Sym) symOfFunKind(immutable TypeAst.Fun.Kind a) {
	final switch (a) {
		case TypeAst.Fun.Kind.act:
			return shortSym("act");
		case TypeAst.Fun.Kind.fun:
			return shortSym("fun");
		case TypeAst.Fun.Kind.ref_:
			return shortSym("ref");
	}
}

immutable(Repr) reprInstStructAst(ref Alloc alloc, immutable TypeAst.InstStruct a) {
	immutable Repr range = reprRangeWithinFile(alloc, a.range);
	immutable Repr name = reprNameAndRange(alloc, a.name);
	immutable Opt!Repr typeArgs = empty(a.typeArgs)
		? none!Repr
		: some(reprArr(alloc, a.typeArgs, (ref immutable TypeAst t) => reprTypeAst(alloc, t)));
	return reprRecord("inststruct", has(typeArgs)
		? arrLiteral!Repr(alloc, [range, name, force(typeArgs)])
		: arrLiteral!Repr(alloc, [range, name]));
}

immutable(Repr) reprParamAst(ref Alloc alloc, ref immutable ParamAst a) {
	return reprRecord(alloc, "param", [
		reprRangeWithinFile(alloc, a.range),
		reprOpt(alloc, a.name, (ref immutable Sym it) =>
			reprSym(it)),
		reprTypeAst(alloc, a.type)]);
}

immutable(Repr) reprFunBodyAst(ref Alloc alloc, ref immutable FunBodyAst a) {
	return matchFunBodyAst!(
		immutable Repr,
		(ref immutable FunBodyAst.Builtin) =>
			reprRecord("builtin"),
		(ref immutable FunBodyAst.Extern e) =>
			reprRecord(alloc, "extern", [
				reprBool(e.isGlobal),
				reprOpt(alloc, e.libraryName, (ref immutable Sym it) =>
					reprSym(it))]),
		(ref immutable ExprAst e) =>
			reprExprAst(alloc, e),
	)(a);
}

immutable(Repr) reprExprAst(ref Alloc alloc, ref immutable ExprAst ast) {
	return reprExprAstKind(alloc, ast.kind);
}

immutable(Repr) reprNameAndRange(ref Alloc alloc, immutable NameAndRange a) {
	return reprRecord(alloc, "name-range", [reprNat(a.start), reprSym(a.name)]);
}

immutable(Repr) reprLambdaParamAst(ref Alloc alloc, immutable LambdaAst.Param a) {
	return reprRecord(alloc, "param", [
		reprNat(a.start),
		reprSym(has(a.name) ? force(a.name) : shortSym("_"))]);
}

immutable(Repr) reprExprAstKind(ref Alloc alloc, ref immutable ExprAstKind ast) {
	return matchExprAstKind!(
		immutable Repr,
		(ref immutable ArrowAccessAst e) =>
			reprRecord(alloc, "arrow-access", [
				reprExprAst(alloc, e.left),
				reprNameAndRange(alloc, e.name),
				reprArr(alloc, e.typeArgs, (ref immutable TypeAst it) =>
					reprTypeAst(alloc, it))]),
		(ref immutable BogusAst e) =>
			reprSym("bogus"),
		(ref immutable CallAst e) =>
			reprRecord(alloc, "call", [
				reprSym(symOfCallAstStyle(e.style)),
				reprNameAndRange(alloc, e.funName),
				reprArr(alloc, e.typeArgs, (ref immutable TypeAst it) =>
					reprTypeAst(alloc, it)),
				reprArr(alloc, e.args, (ref immutable ExprAst it) =>
					reprExprAst(alloc, it))]),
		(ref immutable FunPtrAst a) =>
			reprRecord(alloc, "fun-ptr", [reprSym(a.name)]),
		(ref immutable IdentifierAst a) =>
			reprSym(a.name),
		(ref immutable IfAst e) =>
			reprRecord(alloc, "if", [
				reprExprAst(alloc, e.cond),
				reprExprAst(alloc, e.then),
				reprOpt(alloc, e.else_, (ref immutable ExprAst it) =>
					reprExprAst(alloc, it))]),
		(ref immutable IfOptionAst it) =>
			reprRecord(alloc, "if", [
				reprNameAndRange(alloc, it.name),
				reprExprAst(alloc, it.option),
				reprExprAst(alloc, it.then),
				reprOpt(alloc, it.else_, (ref immutable ExprAst it) =>
					reprExprAst(alloc, it))]),
		(ref immutable InterpolatedAst it) =>
			reprRecord(alloc, "interpolated", [
				reprArr(alloc, it.parts, (ref immutable InterpolatedPart part) =>
					reprInterpolatedPart(alloc, part))]),
		(ref immutable LambdaAst it) =>
			reprRecord(alloc, "lambda", [
				reprArr(alloc, it.params, (ref immutable LambdaAst.Param it) =>
					reprLambdaParamAst(alloc, it)),
				reprExprAst(alloc, it.body_)]),
		(ref immutable LetAst a) =>
			reprRecord(alloc, "let", [
				reprSym(has(a.name) ? force(a.name) : shortSym("_")),
				reprExprAst(alloc, a.initializer),
				reprExprAst(alloc, a.then)]),
		(ref immutable LiteralAst a) =>
			reprLiteralAst(alloc, a),
		(ref immutable MatchAst it) =>
			reprRecord(alloc, "match", [
				reprExprAst(alloc, it.matched),
				reprArr(alloc, it.cases, (ref immutable MatchAst.CaseAst case_) =>
					reprRecord(alloc, "case", [
						reprRangeWithinFile(alloc, case_.range),
						reprSym(case_.memberName),
						matchNameOrUnderscoreOrNone!(
							immutable Repr,
							(immutable(Sym) it) =>
								reprSym(it),
							(ref immutable NameOrUnderscoreOrNone.Underscore) =>
								reprStr("_"),
							(ref immutable NameOrUnderscoreOrNone.None) =>
								reprSym("none"),
						)(case_.local),
						reprExprAst(alloc, case_.then)]))]),
		(ref immutable ParenthesizedAst it) =>
			reprRecord(alloc, "paren", [reprExprAst(alloc, it.inner)]),
		(ref immutable SeqAst a) =>
			reprRecord(alloc, "seq-ast", [
				reprExprAst(alloc, a.first),
				reprExprAst(alloc, a.then)]),
		(ref immutable ThenAst it) =>
			reprRecord(alloc, "then-ast", [
				reprLambdaParamAst(alloc, it.left),
				reprExprAst(alloc, it.futExpr),
				reprExprAst(alloc, it.then)]),
		(ref immutable ThenVoidAst it) =>
			reprRecord(alloc, "then-void", [
				reprExprAst(alloc, it.futExpr),
				reprExprAst(alloc, it.then)]),
		(ref immutable TypedAst it) =>
			reprRecord(alloc, "typed", [
				reprExprAst(alloc, it.expr),
				reprTypeAst(alloc, it.type)]),
		(ref immutable UnlessAst it) =>
			reprRecord(alloc, "unless", [
				reprExprAst(alloc, it.cond),
				reprExprAst(alloc, it.body_)]),
	)(ast);
}

immutable(Repr) reprInterpolatedPart(ref Alloc alloc, ref immutable InterpolatedPart a) {
	return matchInterpolatedPart!(
		immutable Repr,
		(ref immutable string it) => reprStr(it),
		(ref immutable ExprAst it) => reprExprAst(alloc, it),
	)(a);
}

immutable(Sym) symOfCallAstStyle(immutable CallAst.Style a) {
	final switch (a) {
		case CallAst.Style.comma:
			return shortSym("comma");
		case CallAst.Style.dot:
			return shortSym("dot");
		case CallAst.Style.emptyParens:
			return shortSym("empty-parens");
		case CallAst.Style.infix:
			return shortSym("infix");
		case CallAst.Style.prefix:
			return shortSym("prefix");
		case CallAst.Style.prefixOperator:
			return shortSym("prefix-op");
		case CallAst.Style.setDeref:
			return shortSym("set-deref");
		case CallAst.Style.setDot:
			return shortSym("set-dot");
		case CallAst.Style.setSingle:
			return shortSym("set-single");
		case CallAst.Style.setSubscript:
			return shortSym("set-at");
		case CallAst.Style.single:
			return shortSym("single");
		case CallAst.Style.subscript:
			return shortSym("subscript");
		case CallAst.Style.suffixOperator:
			return shortSym("suffix-op");
	}
}

immutable(Repr) reprTypeParams(ref Alloc alloc, immutable NameAndRange[] typeParams) {
	return reprArr(alloc, typeParams, (ref immutable NameAndRange a) =>
		reprNameAndRange(alloc, a));
}
