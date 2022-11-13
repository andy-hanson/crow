module frontend.parse.ast;

@safe @nogc nothrow:

import model.model :
	AssertOrForbidKind,
	FieldMutability,
	ImportFileType,
	symOfAssertOrForbidKind,
	symOfFieldMutability,
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
import util.util : verify;

@trusted immutable(T) matchImportOrExportAstKindImpure(T)(
	immutable ImportOrExportAstKind a,
	scope immutable(T) delegate(immutable ImportOrExportAstKind.ModuleWhole) @safe @nogc nothrow cbModuleWhole,
	scope immutable(T) delegate(immutable ImportOrExportAstKind.ModuleNamed) @safe @nogc nothrow cbModuleNamed,
	scope immutable(T) delegate(immutable ImportOrExportAstKind.File) @safe @nogc nothrow cbFile,
) {
	final switch (a.kind) {
		case ImportOrExportAstKind.Kind.moduleWhole:
			return cbModuleWhole(a.moduleWhole);
		case ImportOrExportAstKind.Kind.moduleNamed:
			return cbModuleNamed(a.moduleNamed);
		case ImportOrExportAstKind.Kind.file:
			return cbFile(*a.file);
	}
}

pure:

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
			funPointer,
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

	immutable this(immutable Dict* a) { kind = Kind.dict; dict = a; }
	@trusted immutable this(immutable Fun a) { kind = Kind.fun; fun = a; }
	@trusted immutable this(immutable InstStruct a) { kind = Kind.instStruct; instStruct = a; }
	immutable this(immutable Suffix* a) { kind = Kind.suffix; suffix = a; }
	immutable this(immutable Tuple* a) { kind = Kind.tuple; tuple = a; }

	private:

	enum Kind {
		dict,
		fun,
		instStruct,
		suffix,
		tuple,
	}
	immutable Kind kind;
	union {
		immutable Dict* dict;
		immutable Fun fun;
		immutable InstStruct instStruct;
		immutable Suffix* suffix;
		immutable Tuple* tuple;
	}
}
static assert(TypeAst.sizeof <= 40);

@trusted immutable(T) matchTypeAst(T, alias cbDict, alias cbFun, alias cbInstStruct, alias cbSuffix, alias cbTuple)(
	immutable TypeAst a,
) {
	final switch (a.kind) {
		case TypeAst.Kind.dict:
			return cbDict(*a.dict);
		case TypeAst.Kind.fun:
			return cbFun(a.fun);
		case TypeAst.Kind.instStruct:
			return cbInstStruct(a.instStruct);
		case TypeAst.Kind.suffix:
			return cbSuffix(*a.suffix);
		case TypeAst.Kind.tuple:
			return cbTuple(*a.tuple);
	}
}

immutable(TypeAst) bogusTypeAst(immutable RangeWithinFile range) =>
	immutable TypeAst(immutable TypeAst.InstStruct(
		range,
		immutable NameAndRange(range.start, sym!"bogus"),
		emptySmallArray!TypeAst));

immutable(RangeWithinFile) range(immutable TypeAst a) =>
	matchTypeAst!(
		immutable RangeWithinFile,
		(immutable TypeAst.Dict it) => range(it),
		(immutable TypeAst.Fun it) => it.range,
		(immutable TypeAst.InstStruct it) => it.range,
		(immutable TypeAst.Suffix it) => range(it),
		(immutable TypeAst.Tuple it) => range(it),
	)(a);

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
		verify(exists!InterpolatedPart(parts, (ref immutable InterpolatedPart part) =>
			part.kind == InterpolatedPart.Kind.expr));
	}
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
	immutable bool mut;
	immutable Opt!(TypeAst*) type;
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
) =>
	matchNameOrUnderscoreOrNone!(
		size_t,
		(immutable Sym s) => 1 + symSize(allSymbols, s),
		(ref immutable NameOrUnderscoreOrNone.Underscore) => immutable size_t(2),
		(ref immutable NameOrUnderscoreOrNone.None) => immutable size_t(0),
	)(a);

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
	@safe @nogc pure nothrow:

	private:
	enum Kind {
		arrowAccess,
		assertOrForbid,
		bogus,
		call,
		for_,
		identifier,
		identifierSet,
		if_,
		ifOption,
		interpolated,
		lambda,
		let,
		literal,
		loop,
		loopBreak,
		loopContinue,
		loopUntil,
		loopWhile,
		match,
		parenthesized,
		ptr,
		seq,
		then,
		throw_,
		typed,
		unless,
		with_,
	}
	immutable Kind kind;
	union {
		immutable ArrowAccessAst* arrowAccess;
		immutable AssertOrForbidAst* assertOrForbid;
		immutable BogusAst bogus;
		immutable CallAst call;
		immutable ForAst* for_;
		immutable IdentifierAst identifier;
		immutable IdentifierSetAst* identifierSet;
		immutable IfAst* if_;
		immutable IfOptionAst* ifOption;
		immutable InterpolatedAst interpolated;
		immutable LambdaAst* lambda;
		immutable LetAst* let;
		immutable LiteralAst literal;
		immutable LoopAst* loop;
		immutable LoopBreakAst* loopBreak;
		immutable LoopContinueAst loopContinue;
		immutable LoopUntilAst* loopUntil;
		immutable LoopWhileAst* loopWhile;
		immutable MatchAst* match_;
		immutable ParenthesizedAst* parenthesized;
		immutable PtrAst* ptr;
		immutable SeqAst* seq;
		immutable ThenAst* then;
		immutable ThrowAst* throw_;
		immutable TypedAst* typed;
		immutable UnlessAst* unless;
		immutable WithAst* with_;
	}

	public:
	@trusted immutable this(immutable ArrowAccessAst* a) { kind = Kind.arrowAccess; arrowAccess = a; }
	immutable this(immutable AssertOrForbidAst* a) { kind = Kind.assertOrForbid; assertOrForbid = a; }
	@trusted immutable this(immutable BogusAst a) { kind = Kind.bogus; bogus = a; }
	@trusted immutable this(immutable CallAst a) { kind = Kind.call; call = a; }
	immutable this(immutable ForAst* a) { kind = Kind.for_; for_ = a; }
	@trusted immutable this(immutable IdentifierAst a) { kind = Kind.identifier; identifier = a; }
	@trusted immutable this(immutable IdentifierSetAst* a) { kind = Kind.identifierSet; identifierSet = a; }
	@trusted immutable this(immutable IfAst* a) { kind = Kind.if_; if_ = a; }
	@trusted immutable this(immutable IfOptionAst* a) { kind = Kind.ifOption; ifOption = a; }
	@trusted immutable this(immutable InterpolatedAst a) { kind = Kind.interpolated; interpolated = a; }
	@trusted immutable this(immutable LambdaAst* a) { kind = Kind.lambda; lambda = a; }
	@trusted immutable this(immutable LetAst* a) { kind = Kind.let; let = a; }
	@trusted immutable this(immutable LiteralAst a) { kind = Kind.literal; literal = a; }
	@trusted immutable this(immutable LoopAst* a) { kind = Kind.loop; loop = a; }
	@trusted immutable this(immutable LoopBreakAst* a) { kind = Kind.loopBreak; loopBreak = a; }
	@trusted immutable this(immutable LoopContinueAst a) { kind = Kind.loopContinue; loopContinue = a; }
	immutable this(immutable LoopUntilAst* a) { kind = Kind.loopUntil; loopUntil = a; }
	immutable this(immutable LoopWhileAst* a) { kind = Kind.loopWhile; loopWhile = a; }
	@trusted immutable this(immutable MatchAst* a) { kind = Kind.match; match_ = a; }
	@trusted immutable this(immutable ParenthesizedAst* a) { kind = Kind.parenthesized; parenthesized = a; }
	immutable this(immutable PtrAst* a) { kind = Kind.ptr; ptr = a; }
	@trusted immutable this(immutable SeqAst* a) { kind = Kind.seq; seq = a; }
	@trusted immutable this(immutable ThenAst* a) { kind = Kind.then; then = a; }
	immutable this(immutable ThrowAst* a) { kind = Kind.throw_; throw_ = a; }
	immutable this(immutable TypedAst* a) { kind = Kind.typed; typed = a; }
	immutable this(immutable UnlessAst* a) { kind = Kind.unless; unless = a; }
	immutable this(immutable WithAst* a) { kind = Kind.with_; with_ = a; }
}
static assert(ExprAstKind.sizeof <= 40);

immutable(bool) isCall(ref immutable ExprAstKind a) =>
	a.kind == ExprAstKind.Kind.call;
@trusted ref immutable(CallAst) asCall(scope return ref immutable ExprAstKind a) {
	verify(isCall(a));
	return a.call;
}

immutable(bool) isIdentifier(ref immutable ExprAstKind a) =>
	a.kind == ExprAstKind.Kind.identifier;
immutable(IdentifierAst) asIdentifier(return scope ref immutable ExprAstKind a) {
	verify(isIdentifier(a));
	return a.identifier;
}

immutable(bool) isLambda(ref immutable ExprAstKind a) =>
	a.kind == ExprAstKind.Kind.lambda;
@trusted ref immutable(LambdaAst) asLambda(return scope ref immutable ExprAstKind a) {
	verify(isLambda(a));
	return *a.lambda;
}

@trusted T matchExprAstKind(
	T,
	alias cbArrowAccess,
	alias cbAssertOrForbid,
	alias cbBogus,
	alias cbCall,
	alias cbFor,
	alias cbIdentifier,
	alias cbIdentifierSet,
	alias cbIf,
	alias cbIfOption,
	alias cbInterpolated,
	alias cbLambda,
	alias cbLet,
	alias cbLiteral,
	alias cbLoop,
	alias cbLoopBreak,
	alias cbLoopContinue,
	alias cbLoopUntil,
	alias cbLoopWhile,
	alias cbMatch,
	alias cbParenthesized,
	alias cbPtr,
	alias cbSeq,
	alias cbThen,
	alias cbThrow,
	alias cbTyped,
	alias cbUnless,
	alias cbWith,
)(
	scope ref immutable ExprAstKind a,
) {
	final switch (a.kind) {
		case ExprAstKind.Kind.arrowAccess:
			return cbArrowAccess(*a.arrowAccess);
		case ExprAstKind.Kind.assertOrForbid:
			return cbAssertOrForbid(*a.assertOrForbid);
		case ExprAstKind.Kind.bogus:
			return cbBogus(a.bogus);
		case ExprAstKind.Kind.call:
			return cbCall(a.call);
		case ExprAstKind.Kind.for_:
			return cbFor(*a.for_);
		case ExprAstKind.Kind.identifier:
			return cbIdentifier(a.identifier);
		case ExprAstKind.Kind.identifierSet:
			return cbIdentifierSet(*a.identifierSet);
		case ExprAstKind.Kind.if_:
			return cbIf(*a.if_);
		case ExprAstKind.Kind.ifOption:
			return cbIfOption(*a.ifOption);
		case ExprAstKind.Kind.interpolated:
			return cbInterpolated(a.interpolated);
		case ExprAstKind.Kind.lambda:
			return cbLambda(*a.lambda);
		case ExprAstKind.Kind.let:
			return cbLet(*a.let);
		case ExprAstKind.Kind.literal:
			return cbLiteral(a.literal);
		case ExprAstKind.Kind.loop:
			return cbLoop(*a.loop);
		case ExprAstKind.Kind.loopBreak:
			return cbLoopBreak(*a.loopBreak);
		case ExprAstKind.Kind.loopContinue:
			return cbLoopContinue(a.loopContinue);
		case ExprAstKind.Kind.loopUntil:
			return cbLoopUntil(*a.loopUntil);
		case ExprAstKind.Kind.loopWhile:
			return cbLoopWhile(*a.loopWhile);
		case ExprAstKind.Kind.match:
			return cbMatch(*a.match_);
		case ExprAstKind.Kind.parenthesized:
			return cbParenthesized(*a.parenthesized);
		case ExprAstKind.Kind.ptr:
			return cbPtr(*a.ptr);
		case ExprAstKind.Kind.seq:
			return cbSeq(*a.seq);
		case ExprAstKind.Kind.then:
			return cbThen(*a.then);
		case ExprAstKind.Kind.throw_:
			return cbThrow(*a.throw_);
		case ExprAstKind.Kind.typed:
			return cbTyped(*a.typed);
		case ExprAstKind.Kind.unless:
			return cbUnless(*a.unless);
		case ExprAstKind.Kind.with_:
			return cbWith(*a.with_);
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

struct ParamsAst {
	@safe @nogc pure nothrow:

	struct Varargs {
		immutable ParamAst param;
	}

	immutable this(immutable ParamAst[] a) { kind = Kind.regular; regular = a; }
	immutable this(immutable Varargs* a) { kind = Kind.varargs; varargs = a; }

	private:

	enum Kind {
		regular,
		varargs,
	}
	immutable Kind kind;
	union {
		immutable SmallArray!ParamAst regular;
		immutable Varargs* varargs;
	}
}

@trusted immutable(T) matchParamsAst(T, alias cbRegular, alias cbVarargs)(ref immutable ParamsAst a) {
	final switch (a.kind) {
		case ParamsAst.Kind.regular:
			return cbRegular(a.regular);
		case ParamsAst.Kind.varargs:
			return cbVarargs(*a.varargs);
	}
}

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

			immutable Opt!(TypeAst*) typeArg;
			immutable SmallArray!Member members;
		}
		struct Flags {
			alias Member = Enum.Member;
			immutable Opt!(TypeAst*) typeArg;
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
	@safe @nogc pure nothrow:

	struct ModuleWhole {}
	struct ModuleNamed {
		immutable Sym[] names;
	}
	struct File {
		immutable Sym name;
		immutable ImportFileType type;
	}

	immutable this(immutable ModuleWhole a) { kind = Kind.moduleWhole; moduleWhole = a; }
	immutable this(immutable ModuleNamed a) { kind = Kind.moduleNamed; moduleNamed = a; }
	immutable this(immutable File* a) { kind = Kind.file; file = a; }

	private:
	enum Kind { moduleWhole, moduleNamed, file }
	immutable Kind kind;
	union {
		immutable ModuleWhole moduleWhole;
		immutable ModuleNamed moduleNamed;
		immutable File* file;
	}
}

@trusted private immutable(T) matchImportOrExportAstKind(T)(
	immutable ImportOrExportAstKind a,
	scope immutable(T) delegate(immutable ImportOrExportAstKind.ModuleWhole) @safe @nogc pure nothrow cbModuleWhole,
	scope immutable(T) delegate(immutable ImportOrExportAstKind.ModuleNamed) @safe @nogc pure nothrow cbModuleNamed,
	scope immutable(T) delegate(immutable ImportOrExportAstKind.File) @safe @nogc pure nothrow cbFile,
) {
	final switch (a.kind) {
		case ImportOrExportAstKind.Kind.moduleWhole:
			return cbModuleWhole(a.moduleWhole);
		case ImportOrExportAstKind.Kind.moduleNamed:
			return cbModuleNamed(a.moduleNamed);
		case ImportOrExportAstKind.Kind.file:
			return cbFile(*a.file);
	}
}

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
		matchImportOrExportAstKind(
			a.kind,
			(immutable(ImportOrExportAstKind.ModuleWhole)) =>
				reprSym!"whole",
			(immutable ImportOrExportAstKind.ModuleNamed m) =>
				reprRecord!"named"(alloc, [reprArr(alloc, m.names, (ref immutable Sym name) =>
					reprSym(name))]),
			(immutable ImportOrExportAstKind.File f) =>
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
	matchSpecBodyAst!(
		immutable Repr,
		(ref immutable SpecBodyAst.Builtin) =>
			reprSym!"builtin",
		(ref immutable SpecSigAst[] sigs) =>
			reprArr(alloc, sigs, (ref immutable SpecSigAst sig) =>
				reprSpecSig(alloc, sig)),
	)(a);

immutable(Repr) reprSpecSig(ref Alloc alloc, ref immutable SpecSigAst a) =>
	reprRecord!"spec-sig"(alloc, [
		reprRangeWithinFile(alloc, a.range),
		reprStr(a.docComment),
		reprSym(a.name),
		reprTypeAst(alloc, a.returnType),
		matchParamsAst!(
			immutable Repr,
			(immutable ParamAst[] params) =>
				reprArr(alloc, params, (ref immutable ParamAst p) => reprParamAst(alloc, p)),
			(ref immutable ParamsAst.Varargs v) =>
				reprRecord!"varargs"(alloc, [reprParamAst(alloc, v.param)]),
		)(a.params)]);

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

immutable(Repr) reprLiteralAst(ref Alloc alloc, ref immutable LiteralAst a) =>
	reprRecord!"literal"(alloc, [
		matchLiteralAst!(
			immutable Repr,
			(immutable LiteralAst.Float it) =>
				reprRecord!"float"(alloc, [reprFloat(it.value), reprBool(it.overflow)]),
			(immutable LiteralAst.Int it) =>
				reprLiteralInt(alloc, it),
			(immutable LiteralAst.Nat it) =>
				reprLiteralNat(alloc, it),
			(immutable string it) =>
				reprStr(it),
		)(a)]);

immutable(Repr) reprLiteralInt(ref Alloc alloc, ref immutable LiteralAst.Int a) =>
	reprRecord!"int"(alloc, [reprInt(a.value), reprBool(a.overflow)]);

immutable(Repr) reprLiteralNat(ref Alloc alloc, ref immutable LiteralAst.Nat a) =>
	reprRecord!"nat"(alloc, [reprNat(a.value), reprBool(a.overflow)]);

immutable(Repr) reprLiteralIntOrNat(ref Alloc alloc, ref immutable LiteralIntOrNat a) =>
	matchLiteralIntOrNat!(
		immutable Repr,
		(ref immutable LiteralAst.Int it) =>
			reprLiteralInt(alloc, it),
		(ref immutable LiteralAst.Nat it) =>
			reprLiteralNat(alloc, it),
	)(a);

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
	matchStructDeclAstBody!(
		immutable Repr,
		(ref immutable StructDeclAst.Body.Builtin) =>
			reprSym!"builtin" ,
		(ref immutable StructDeclAst.Body.Enum e) =>
			reprEnumOrFlags(alloc, sym!"enum", e.typeArg, e.members),
		(ref immutable StructDeclAst.Body.Flags e) =>
			reprEnumOrFlags(alloc, sym!"flags", e.typeArg, e.members),
		(ref immutable StructDeclAst.Body.ExternPtr) =>
			reprSym(sym!"extern-pointer"),
		(ref immutable StructDeclAst.Body.Record a) =>
			reprRecordAst(alloc, a),
		(ref immutable StructDeclAst.Body.Union a) =>
			reprUnion(alloc, a),
	)(a);

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
	matchParamsAst!(
		immutable Repr,
		(immutable ParamAst[] params) =>
			reprArr(alloc, params, (ref immutable ParamAst p) => reprParamAst(alloc, p)),
		(ref immutable ParamsAst.Varargs v) =>
			reprRecord!"varargs"(alloc, [reprParamAst(alloc, v.param)]),
	)(a);

immutable(Repr) reprFunModifierAst(ref Alloc alloc, scope immutable FunModifierAst a) =>
	reprRecord!"modifier"(alloc, [
		reprNameAndRange(alloc, a.name),
		reprArr(alloc, a.typeArgs, (ref immutable TypeAst it) =>
			reprTypeAst(alloc, it))]);

immutable(Repr) reprTypeAst(ref Alloc alloc, immutable TypeAst a) =>
	matchTypeAst!(
		immutable Repr,
		(immutable TypeAst.Dict it) =>
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
		(immutable TypeAst.Suffix it) =>
			reprRecord!"suffix"(alloc, [
				reprTypeAst(alloc, it.left),
				reprSym(symForTypeAstSuffix(it.kind))]),
		(immutable TypeAst.Tuple it) =>
			reprRecord!"tuple"(alloc, [
				reprTypeAst(alloc, it.a),
				reprTypeAst(alloc, it.b)]),
	)(a);

immutable(Sym) symOfFunKind(immutable TypeAst.Fun.Kind a) {
	final switch (a) {
		case TypeAst.Fun.Kind.act:
			return sym!"act";
		case TypeAst.Fun.Kind.fun:
			return sym!"fun";
		case TypeAst.Fun.Kind.ref_:
			return sym!"ref";
		case TypeAst.Fun.Kind.funPointer:
			return sym!"fun-pointer";
	}
}

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
	matchExprAstKind!(
		immutable Repr,
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
		(ref immutable BogusAst e) =>
			reprSym!"bogus" ,
		(ref immutable CallAst e) =>
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
		(ref immutable IdentifierAst a) =>
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
		(ref immutable InterpolatedAst it) =>
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
		(ref immutable LiteralAst a) =>
			reprLiteralAst(alloc, a),
		(ref immutable LoopAst a) =>
			reprRecord!"loop"(alloc, [reprExprAst(alloc, a.body_)]),
		(ref immutable LoopBreakAst e) =>
			reprRecord!"break"(alloc, [
				reprOpt(alloc, e.value, (ref immutable ExprAst value) =>
					reprExprAst(alloc, value))]),
		(ref immutable(LoopContinueAst)) =>
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
						matchNameOrUnderscoreOrNone!(
							immutable Repr,
							(immutable(Sym) it) =>
								reprSym(it),
							(ref immutable NameOrUnderscoreOrNone.Underscore) =>
								reprStr("_"),
							(ref immutable NameOrUnderscoreOrNone.None) =>
								reprSym!"none" ,
						)(case_.local),
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
				reprExprAst(alloc, x.body_)]),
	)(ast);

immutable(Repr) reprInterpolatedPart(ref Alloc alloc, ref immutable InterpolatedPart a) =>
	matchInterpolatedPart!(
		immutable Repr,
		(ref immutable string it) => reprStr(it),
		(ref immutable ExprAst it) => reprExprAst(alloc, it),
	)(a);

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
