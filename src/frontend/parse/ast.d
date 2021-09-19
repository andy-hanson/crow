module frontend.parse.ast;

@safe @nogc pure nothrow:

import util.collection.arr : ArrWithSize, empty, emptyArr, toArr;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.arrUtil : arrLiteral;
import util.collection.str : emptySafeCStr, SafeCStr, safeCStrIsEmpty;
import util.opt : force, has, none, Opt, OptPtr, some, toOpt;
import util.path : AllPaths, Path, pathToStr;
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
import util.sourceRange : Pos, reprRangeWithinFile, rangeOfStartAndName, RangeWithinFile;
import util.sym : shortSymAlphaLiteral, Sym, symSize;
import util.types : safeSizeTToU32;
import util.util : todo, verify;

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

immutable(RangeWithinFile) rangeOfNameAndRange(immutable NameAndRange a) {
	return rangeOfStartAndName(a.start, a.name);
}

struct TypeAst {
	@safe @nogc pure nothrow:
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
		immutable ArrWithSize!TypeAst typeArgs;
	}

	struct TypeParam {
		immutable RangeWithinFile range;
		immutable Sym name;
	}

	@trusted immutable this(immutable Fun a) { kind = Kind.fun; fun = a; }
	@trusted immutable this(immutable InstStruct a) { kind = Kind.instStruct; instStruct = a; }
	@trusted immutable this(immutable TypeParam a) { kind = Kind.typeParam; typeParam = a; }

	private:

	enum Kind {
		fun,
		instStruct,
		typeParam,
	}
	immutable Kind kind;
	union {
		immutable Fun fun;
		immutable TypeParam typeParam;
		immutable InstStruct instStruct;
	}
}
static assert(TypeAst.sizeof <= 40);

@trusted T matchTypeAst(T)(
	ref immutable TypeAst a,
	scope T delegate(ref immutable TypeAst.Fun) @safe @nogc pure nothrow cbFun,
	scope T delegate(ref immutable TypeAst.InstStruct) @safe @nogc pure nothrow cbInstStruct,
	scope T delegate(ref immutable TypeAst.TypeParam) @safe @nogc pure nothrow cbTypeParam,
) {
	final switch (a.kind) {
		case TypeAst.Kind.fun:
			return cbFun(a.fun);
		case TypeAst.Kind.instStruct:
			return cbInstStruct(a.instStruct);
		case TypeAst.Kind.typeParam:
			return cbTypeParam(a.typeParam);
	}
}

immutable(RangeWithinFile) range(ref immutable TypeAst a) {
	return matchTypeAst!(immutable RangeWithinFile)(
		a,
		(ref immutable TypeAst.Fun it) => it.range,
		(ref immutable TypeAst.InstStruct it) => it.range,
		(ref immutable TypeAst.TypeParam it) => it.range);
}

struct BogusAst {}

struct CallAst {
	@safe @nogc pure nothrow:

	enum Style {
		dot, // `a.b`
		infix, // `a b`, `a b c`, `a b c, d`, etc.
		prefix, // `a: b`, `a: b, c`, etc.
		setDot,
		setSingle,
		setSubscript,
		single, // `a<t>` (without the type arg, it would just be an Identifier)
		subscript, // a[b]
	}
	// For some reason we have to break this up to get the struct size lower
	//immutable NameAndRange funName;
	immutable Sym funNameName;
	immutable Pos funNameStart;
	immutable Style style;
	immutable ArrWithSize!TypeAst typeArgs;
	immutable ArrWithSize!ExprAst args;

	immutable this(
		immutable Style s, immutable NameAndRange f, immutable ArrWithSize!TypeAst t, immutable ArrWithSize!ExprAst a) {
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

struct CreateArrAst {
	immutable ArrWithSize!ExprAst args;
}

struct FunPtrAst {
	immutable Sym name;
}

struct IdentifierAst {
	immutable Sym name;
}

struct IfAst {
	immutable Ptr!ExprAst cond;
	immutable Ptr!ExprAst then;
	immutable Opt!(Ptr!ExprAst) else_;
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

@trusted T matchInterpolatedPart(T)(
	ref immutable InterpolatedPart a,
	scope immutable(T) delegate(ref immutable string) @safe @nogc pure nothrow cbString,
	scope immutable(T) delegate(ref immutable ExprAst) @safe @nogc pure nothrow cbExpr,
) {
	final switch (a.kind) {
		case InterpolatedPart.Kind.string_:
			return cbString(a.string_);
		case InterpolatedPart.Kind.expr:
			return cbExpr(a.expr);
	}
}

struct LambdaAst {
	alias Param = NameAndRange;
	immutable Param[] params;
	immutable Ptr!ExprAst body_;
}

struct LetAst {
	immutable NameAndRange name;
	immutable Ptr!ExprAst initializer;
	immutable Ptr!ExprAst then;
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

@trusted T matchLiteralAst(T)(
	ref immutable LiteralAst a,
	scope immutable(T) delegate(ref immutable LiteralAst.Float) @safe @nogc pure nothrow cbFloat,
	scope immutable(T) delegate(ref immutable LiteralAst.Int) @safe @nogc pure nothrow cbInt,
	scope immutable(T) delegate(ref immutable LiteralAst.Nat) @safe @nogc pure nothrow cbNat,
	scope immutable(T) delegate(ref immutable string) @safe @nogc pure nothrow cbStr,
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

struct MatchAst {
	struct CaseAst {
		immutable RangeWithinFile range;
		immutable NameAndRange structName;
		immutable Opt!NameAndRange local;
		immutable Ptr!ExprAst then;
	}

	immutable Ptr!ExprAst matched;
	immutable CaseAst[] cases;
}

struct ParenthesizedAst {
	immutable Ptr!ExprAst inner;
}

struct SeqAst {
	immutable Ptr!ExprAst first;
	immutable Ptr!ExprAst then;
}

struct ThenAst {
	immutable LambdaAst.Param left;
	immutable Ptr!ExprAst futExpr;
	immutable Ptr!ExprAst then;
}

struct ThenVoidAst {
	immutable Ptr!ExprAst futExpr;
	immutable Ptr!ExprAst then;
}

struct ExprAstKind {
	@safe @nogc pure nothrow:

	private:
	enum Kind {
		bogus,
		call,
		createArr,
		funPtr,
		identifier,
		if_,
		ifOption,
		interpolated,
		lambda,
		let,
		literal,
		parenthesized,
		match,
		seq,
		then,
		thenVoid,
	}
	immutable Kind kind;
	union {
		immutable BogusAst bogus;
		immutable CallAst call;
		immutable CreateArrAst createArr;
		immutable FunPtrAst funPtr;
		immutable IdentifierAst identifier;
		immutable IfAst if_;
		immutable Ptr!IfOptionAst ifOption;
		immutable InterpolatedAst interpolated;
		immutable LambdaAst lambda;
		immutable LetAst let;
		immutable LiteralAst literal;
		immutable ParenthesizedAst parenthesized;
		immutable MatchAst match_;
		immutable SeqAst seq;
		immutable ThenAst then;
		immutable ThenVoidAst thenVoid;
	}

	public:
	@trusted immutable this(immutable BogusAst a) { kind = Kind.bogus; bogus = a; }
	@trusted immutable this(immutable CallAst a) { kind = Kind.call; call = a; }
	@trusted immutable this(immutable CreateArrAst a) { kind = Kind.createArr; createArr = a; }
	@trusted immutable this(immutable FunPtrAst a) { kind = Kind.funPtr; funPtr = a; }
	@trusted immutable this(immutable IdentifierAst a) { kind = Kind.identifier; identifier = a; }
	@trusted immutable this(immutable IfAst a) { kind = Kind.if_; if_ = a; }
	@trusted immutable this(immutable Ptr!IfOptionAst a) { kind = Kind.ifOption; ifOption = a; }
	@trusted immutable this(immutable InterpolatedAst a) { kind = Kind.interpolated; interpolated = a; }
	@trusted immutable this(immutable LambdaAst a) { kind = Kind.lambda; lambda = a; }
	@trusted immutable this(immutable LetAst a) { kind = Kind.let; let = a; }
	@trusted immutable this(immutable LiteralAst a) { kind = Kind.literal; literal = a; }
	@trusted immutable this(immutable MatchAst a) { kind = Kind.match; match_ = a; }
	@trusted immutable this(immutable ParenthesizedAst a) { kind = Kind.parenthesized; parenthesized = a; }
	@trusted immutable this(immutable SeqAst a) { kind = Kind.seq; seq = a; }
	@trusted immutable this(immutable ThenAst a) { kind = Kind.then; then = a; }
	@trusted immutable this(immutable ThenVoidAst a) { kind = Kind.thenVoid; thenVoid = a; }
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

@trusted T matchExprAstKind(T)(
	scope ref immutable ExprAstKind a,
	scope T delegate(ref immutable BogusAst) @safe @nogc pure nothrow cbBogus,
	scope T delegate(ref immutable CallAst) @safe @nogc pure nothrow cbCall,
	scope T delegate(ref immutable CreateArrAst) @safe @nogc pure nothrow cbCreateArr,
	scope T delegate(ref immutable FunPtrAst) @safe @nogc pure nothrow cbFunPtr,
	scope T delegate(ref immutable IdentifierAst) @safe @nogc pure nothrow cbIdentifier,
	scope T delegate(ref immutable IfAst) @safe @nogc pure nothrow cbIf,
	scope T delegate(ref immutable IfOptionAst) @safe @nogc pure nothrow cbIfOption,
	scope T delegate(ref immutable InterpolatedAst) @safe @nogc pure nothrow cbInterpolated,
	scope T delegate(ref immutable LambdaAst) @safe @nogc pure nothrow cbLambda,
	scope T delegate(ref immutable LetAst) @safe @nogc pure nothrow cbLet,
	scope T delegate(ref immutable LiteralAst) @safe @nogc pure nothrow cbLiteral,
	scope T delegate(ref immutable MatchAst) @safe @nogc pure nothrow cbMatch,
	scope T delegate(ref immutable ParenthesizedAst) @safe @nogc pure nothrow cbParenthesized,
	scope T delegate(ref immutable SeqAst) @safe @nogc pure nothrow cbSeq,
	scope T delegate(ref immutable ThenAst) @safe @nogc pure nothrow cbThen,
	scope T delegate(ref immutable ThenVoidAst) @safe @nogc pure nothrow cbThenVoid,
) {
	final switch (a.kind) {
		case ExprAstKind.Kind.bogus:
			return cbBogus(a.bogus);
		case ExprAstKind.Kind.call:
			return cbCall(a.call);
		case ExprAstKind.Kind.createArr:
			return cbCreateArr(a.createArr);
		case ExprAstKind.Kind.funPtr:
			return cbFunPtr(a.funPtr);
		case ExprAstKind.Kind.identifier:
			return cbIdentifier(a.identifier);
		case ExprAstKind.Kind.if_:
			return cbIf(a.if_);
		case ExprAstKind.Kind.ifOption:
			return cbIfOption(a.ifOption);
		case ExprAstKind.Kind.interpolated:
			return cbInterpolated(a.interpolated);
		case ExprAstKind.Kind.lambda:
			return cbLambda(a.lambda);
		case ExprAstKind.Kind.let:
			return cbLet(a.let);
		case ExprAstKind.Kind.literal:
			return cbLiteral(a.literal);
		case ExprAstKind.Kind.match:
			return cbMatch(a.match_);
		case ExprAstKind.Kind.parenthesized:
			return cbParenthesized(a.parenthesized);
		case ExprAstKind.Kind.seq:
			return cbSeq(a.seq);
		case ExprAstKind.Kind.then:
			return cbThen(a.then);
		case ExprAstKind.Kind.thenVoid:
			return cbThenVoid(a.thenVoid);
	}
}

struct ExprAst {
	immutable RangeWithinFile range;
	immutable ExprAstKind kind;
}
static assert(ExprAst.sizeof <= 56);

// This is the declaration, TypeAst.TypeParam is the use
struct TypeParamAst {
	immutable RangeWithinFile range;
	immutable Sym name;
}

struct ParamAst {
	immutable RangeWithinFile range;
	immutable Opt!Sym name;
	immutable TypeAst type;
}

struct SpecUseAst {
	immutable RangeWithinFile range;
	immutable NameAndRange spec;
	immutable ArrWithSize!TypeAst typeArgs;
}

struct SigAst {
	@safe @nogc pure nothrow:

	immutable RangeWithinFile range;
	immutable Sym name; // Range starts at sig.range.start
	immutable TypeAst returnType;
	immutable ArrWithSize!ParamAst params;
}

enum PuritySpecifier {
	data,
	forceData,
	sendable,
	forceSendable,
	mut,
}

private immutable(Sym) symOfPuritySpecifier(immutable PuritySpecifier a) {
	final switch (a) {
		case PuritySpecifier.data:
			return shortSymAlphaLiteral("data");
		case PuritySpecifier.forceData:
			return shortSymAlphaLiteral("force-data");
		case PuritySpecifier.sendable:
			return shortSymAlphaLiteral("sendable");
		case PuritySpecifier.forceSendable:
			return shortSymAlphaLiteral("force-send");
		case PuritySpecifier.mut:
			return shortSymAlphaLiteral("mut");
	}
}

struct PuritySpecifierAndRange {
	immutable Pos start;
	immutable PuritySpecifier specifier;
}

immutable(RangeWithinFile) rangeOfPuritySpecifier(ref immutable PuritySpecifierAndRange a) {
	return immutable RangeWithinFile(a.start, safeSizeTToU32(a.start + symSize(symOfPuritySpecifier(a.specifier))));
}

struct StructAliasAst {
	immutable RangeWithinFile range;
	immutable SafeCStr docComment;
	immutable bool isPublic;
	immutable Sym name;
	immutable ArrWithSize!TypeParamAst typeParams;
	immutable Ptr!TypeAst target;
}

enum ExplicitByValOrRef {
	byVal,
	byRef,
}

private immutable(Sym) symOfExplicitByValOrRef(immutable ExplicitByValOrRef a) {
	final switch (a) {
		case ExplicitByValOrRef.byVal:
			return shortSymAlphaLiteral("by-val");
		case ExplicitByValOrRef.byRef:
			return shortSymAlphaLiteral("by-ref");
	}
}

struct ExplicitByValOrRefAndRange {
	immutable Pos start;
	immutable ExplicitByValOrRef byValOrRef;
}

immutable(RangeWithinFile) rangeOfExplicitByValOrRef(ref immutable ExplicitByValOrRefAndRange a) {
	return immutable RangeWithinFile(a.start, safeSizeTToU32(a.start + symSize(symOfExplicitByValOrRef(a.byValOrRef))));
}

struct RecordModifiers {
	@safe @nogc pure nothrow:

	immutable Opt!Pos packed;
	immutable Opt!ExplicitByValOrRefAndRange explicitByValOrRef;

	immutable this(immutable Opt!Pos p, immutable Opt!ExplicitByValOrRefAndRange e) {
		packed = p;
		explicitByValOrRef = e;

		if (has(packed) && has(explicitByValOrRef)) {
			// TODO: ensure this in the parser
			verify(force(explicitByValOrRef).start > force(packed));
		}
	}

	//TODO:NOT INSTANCE
	immutable(bool) any() immutable {
		return has(packed) || has(explicitByValOrRef);
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
				immutable Opt!(LiteralAst.Int) value;
			}

			immutable Member[] members;
		}
		struct ExternPtr {}
		struct Record {
			@safe @nogc pure nothrow:

			struct Field {
				immutable RangeWithinFile range;
				immutable bool isMutable;
				immutable Sym name;
				immutable TypeAst type;
			}
			private immutable OptPtr!RecordModifiers modifiers_;
			immutable ArrWithSize!Field fields;

			//TODO: NOT INSTANCE
			immutable(RecordModifiers) modifiers() immutable {
				immutable Opt!(Ptr!RecordModifiers) m = toOpt(modifiers_);
				return has(m)
					? force(m)
					: immutable RecordModifiers(none!Pos, none!ExplicitByValOrRefAndRange);
			}

			//TODO: NOT INSTANCE
			immutable(Opt!ExplicitByValOrRefAndRange) explicitByValOrRef() immutable {
				return modifiers.explicitByValOrRef;
			}

			//TODO: NOT INSTANCE
			immutable(Opt!Pos) packed() immutable {
				return modifiers.packed;
			}
		}
		struct Union {
			immutable TypeAst.InstStruct[] members;
		}

		private:
		enum Kind {
			builtin,
			enum_,
			externPtr,
			record,
			union_,
		}

		immutable Kind kind;
		union {
			immutable Builtin builtin;
			immutable Enum enum_;
			immutable ExternPtr externPtr;
			immutable Record record;
			immutable Union union_;
		}

		public:

		immutable this(immutable Builtin a) { kind = Kind.builtin; builtin = a; }
		@trusted immutable this(immutable Enum a) { kind = Kind.enum_; enum_ = a; }
		immutable this(immutable ExternPtr a) { kind = Kind.externPtr; externPtr = a; }
		@trusted immutable this(immutable Record a) { kind = Kind.record; record = a; }
		@trusted immutable this(immutable Union a) { kind = Kind.union_; union_ = a; }
	}

	immutable RangeWithinFile range;
	immutable SafeCStr docComment;
	immutable bool isPublic;
	immutable Sym name; // start is range.start
	immutable ArrWithSize!TypeParamAst typeParams;
	immutable Opt!PuritySpecifierAndRange purity;
	immutable Body body_;
}
static assert(StructDeclAst.Body.sizeof <= 24);
static assert(StructDeclAst.sizeof <= 88);

immutable(bool) isRecord(ref immutable StructDeclAst.Body a) {
	return a.kind == StructDeclAst.Body.Kind.record;
}
immutable(bool) isUnion(ref immutable StructDeclAst.Body a) {
	return a.kind == StructDeclAst.Body.Kind.union_;
}

@trusted T matchStructDeclAstBody(T)(
	ref immutable StructDeclAst.Body a,
	scope T delegate(ref immutable StructDeclAst.Body.Builtin) @safe @nogc pure nothrow cbBuiltin,
	scope T delegate(ref immutable StructDeclAst.Body.Enum) @safe @nogc pure nothrow cbEnum,
	scope T delegate(ref immutable StructDeclAst.Body.ExternPtr) @safe @nogc pure nothrow cbExternPtr,
	scope T delegate(ref immutable StructDeclAst.Body.Record) @safe @nogc pure nothrow cbRecord,
	scope T delegate(ref immutable StructDeclAst.Body.Union) @safe @nogc pure nothrow cbUnion,
) {
	final switch (a.kind) {
		case StructDeclAst.Body.Kind.builtin:
			return cbBuiltin(a.builtin);
		case StructDeclAst.Body.Kind.enum_:
			return cbEnum(a.enum_);
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
		immutable SigAst[] sigs;
	}

	public:
	immutable this(immutable Builtin a) { kind = Kind.builtin; builtin = a; }
	@trusted immutable this(immutable SigAst[] a) { kind = Kind.sigs; sigs = a; }
}

@trusted T matchSpecBodyAst(T)(
	ref immutable SpecBodyAst a,
	scope T delegate(ref immutable SpecBodyAst.Builtin) @safe @nogc pure nothrow cbBuiltin,
	scope T delegate(ref immutable SigAst[]) @safe @nogc pure nothrow cbSigs,
) {
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
	immutable bool isPublic;
	immutable Sym name;
	immutable ArrWithSize!TypeParamAst typeParams;
	immutable SpecBodyAst body_;
}

struct FunBodyAst {
	@safe @nogc pure nothrow:

	struct Builtin {}
	struct Extern {
		immutable bool isGlobal;
		immutable Opt!string libraryName;
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

@trusted T matchFunBodyAst(T)(
	ref immutable FunBodyAst a,
	scope T delegate(ref immutable FunBodyAst.Builtin) @safe @nogc pure nothrow cbBuiltin,
	scope T delegate(ref immutable FunBodyAst.Extern) @safe @nogc pure nothrow cbExtern,
	scope T delegate(ref immutable ExprAst) @safe @nogc pure nothrow cbExprAst,
) {
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
	immutable ArrWithSize!TypeParamAst typeParams; // If this is empty, infer type params
	immutable Ptr!SigAst sig; // Ptr to keep this struct from getting too big
	immutable SpecUseAst[] specUses;
	immutable bool isPublic;
	immutable bool noCtx;
	immutable bool summon;
	immutable bool unsafe;
	immutable bool trusted;
	immutable Ptr!FunBodyAst body_;
}

struct TestAst {
	immutable ExprAst body_;
}

struct ImportAst {
	immutable RangeWithinFile range;
	// Not using RelPath here because if nDots == 0, it's not a relative path
	immutable ubyte nDots;
	immutable Path path;
	immutable Opt!(Sym[]) names;
}

struct ImportsOrExportsAst {
	immutable RangeWithinFile range;
	immutable ImportAst[] paths;
}

// TODO: I'm doing this because the wasm compilation generates a call to 'memset' whenever there's a big struct.
struct FileAstPart0 {
	immutable Opt!ImportsOrExportsAst imports;
	immutable Opt!ImportsOrExportsAst exports;
	immutable SpecDeclAst[] specs;
}

struct FileAstPart1 {
	immutable StructAliasAst[] structAliases;
	immutable StructDeclAst[] structs;
	immutable FunDeclAst[] funs;
	immutable TestAst[] tests;
}

struct FileAst {
	immutable SafeCStr docComment;
	immutable bool noStd;
	immutable Ptr!FileAstPart0 part0;
	immutable Ptr!FileAstPart1 part1;
}

private immutable ImportsOrExportsAst emptyImportsOrExports =
	immutable ImportsOrExportsAst(RangeWithinFile.empty, emptyArr!ImportAst);
private immutable FileAstPart0 emptyFileAstPart0 =
	immutable FileAstPart0(some(emptyImportsOrExports), some(emptyImportsOrExports), emptyArr!SpecDeclAst);
private immutable FileAstPart1 emptyFileAstPart1 =
	immutable FileAstPart1(emptyArr!StructAliasAst, emptyArr!StructDeclAst, emptyArr!FunDeclAst, emptyArr!TestAst);
private immutable FileAst emptyFileAstStorage = immutable FileAst(
	emptySafeCStr,
	true,
	immutable Ptr!FileAstPart0(&emptyFileAstPart0),
	immutable Ptr!FileAstPart1(&emptyFileAstPart1));
immutable Ptr!FileAst emptyFileAst = immutable Ptr!FileAst(&emptyFileAstStorage);

ref immutable(Opt!ImportsOrExportsAst) imports(return scope ref immutable FileAst a) {
	return a.part0.imports;
}

ref immutable(Opt!ImportsOrExportsAst) exports(return scope ref immutable FileAst a) {
	return a.part0.exports;
}

ref immutable(SpecDeclAst[]) specs(return scope ref immutable FileAst a) {
	return a.part0.specs;
}

ref immutable(StructAliasAst[]) structAliases(return scope ref immutable FileAst a) {
	return a.part1.structAliases;
}

ref immutable(StructDeclAst[]) structs(return scope ref immutable FileAst a) {
	return a.part1.structs;
}

ref immutable(FunDeclAst[]) funs(return scope ref immutable FileAst a) {
	return a.part1.funs;
}

ref immutable(TestAst[]) tests(return scope ref immutable FileAst a) {
	return a.part1.tests;
}

immutable(Repr) reprAst(Alloc, PathAlloc)(
	ref Alloc alloc,
	ref const AllPaths!PathAlloc allPaths,
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

immutable(Repr) reprImportsOrExports(Alloc, PathAlloc)(
	ref Alloc alloc,
	ref const AllPaths!PathAlloc allPaths,
	ref immutable ImportsOrExportsAst a,
) {
	return reprRecord(alloc, "ports", [
		reprRangeWithinFile(alloc, a.range),
		reprArr(alloc, a.paths, (ref immutable ImportAst a) =>
			reprImportAst(alloc, allPaths, a))]);
}

immutable(Repr) reprImportAst(Alloc, PathAlloc)(
	ref Alloc alloc,
	ref const AllPaths!PathAlloc allPaths,
	ref immutable ImportAst a,
) {
	return reprRecord(alloc, "import-ast", [
		reprNat(a.nDots),
		reprStr(pathToStr(alloc, allPaths, "", a.path, "")),
		reprOpt!(Alloc, Sym[])(alloc, a.names, (ref immutable Sym[] names) =>
			reprArr(alloc, names, (ref immutable Sym name) =>
				reprSym(name)))]);
}

immutable(Repr) reprSpecDeclAst(Alloc)(ref Alloc alloc, ref immutable SpecDeclAst a) {
	return reprRecord(alloc, "spec-decl", [
		reprRangeWithinFile(alloc, a.range),
		reprStr(a.docComment),
		reprBool(a.isPublic),
		reprSym(a.name),
		reprArr(alloc, toArr(a.typeParams), (ref immutable TypeParamAst it) =>
			reprTypeParamAst(alloc, it)),
		reprSpecBodyAst(alloc, a.body_)]);
}

immutable(Repr) reprSpecBodyAst(Alloc)(ref Alloc alloc, ref immutable SpecBodyAst a) {
	return matchSpecBodyAst!(immutable Repr)(
		a,
		(ref immutable SpecBodyAst.Builtin) =>
			reprSym("builtin"),
		(ref immutable SigAst[] sigs) =>
			reprArr(alloc, sigs, (ref immutable SigAst sig) =>
				reprSig(alloc, sig)));
}

immutable(Repr) reprStructAliasAst(Alloc)(ref Alloc alloc, ref immutable StructAliasAst a) {
	return reprRecord(alloc, "alias", [
		reprRangeWithinFile(alloc, a.range),
		reprStr(a.docComment),
		reprBool(a.isPublic),
		reprSym(a.name),
		reprArr(alloc, toArr(a.typeParams), (ref immutable TypeParamAst it) =>
			reprTypeParamAst(alloc, it)),
		reprTypeAst(alloc, a.target)]);
}

immutable(Repr) reprOptPurity(Alloc)(ref Alloc alloc, immutable Opt!PuritySpecifierAndRange purity) {
	return reprOpt(alloc, purity, (ref immutable PuritySpecifierAndRange it) =>
		reprRecord(alloc, "purity", [
			reprNat(it.start),
			reprSym(symOfPuritySpecifier(it.specifier))]));
}

immutable(Repr) reprOptExplicitByValOrRefAndRange(Alloc)(
	ref Alloc alloc,
	immutable Opt!ExplicitByValOrRefAndRange a,
) {
	return reprOpt(alloc, a, (ref immutable ExplicitByValOrRefAndRange it) =>
		reprRecord(alloc, "by-val-ref", [reprNat(it.start), reprSym(symOfExplicitByValOrRef(it.byValOrRef))]));
}

immutable(Repr) reprEnum(Alloc)(ref Alloc alloc, ref immutable StructDeclAst.Body.Enum a) {
	return todo!(immutable Repr)("!");
}

immutable(Repr) reprField(Alloc)(ref Alloc alloc, ref immutable StructDeclAst.Body.Record.Field a) {
	return reprRecord(alloc, "field", [
		reprRangeWithinFile(alloc, a.range),
		reprBool(a.isMutable),
		reprSym(a.name),
		reprTypeAst(alloc, a.type)]);
}

immutable(Repr) reprRecord(Alloc)(ref Alloc alloc, ref immutable StructDeclAst.Body.Record a) {
	return reprRecord(alloc, "record", [
		reprOptExplicitByValOrRefAndRange(alloc, a.explicitByValOrRef),
		reprArr(alloc, toArr(a.fields), (ref immutable StructDeclAst.Body.Record.Field it) =>
			reprField(alloc, it))]);
}

immutable(Repr) reprUnion(Alloc)(ref Alloc alloc, ref immutable StructDeclAst.Body.Union a) {
	return reprRecord(alloc, "union", [
		reprArr(alloc, a.members, (ref immutable TypeAst.InstStruct member) =>
			reprInstStructAst(alloc, member))]);
}

immutable(Repr) reprStructBodyAst(Alloc)(ref Alloc alloc, ref immutable StructDeclAst.Body a) {
	return matchStructDeclAstBody(
		a,
		(ref immutable StructDeclAst.Body.Builtin) =>
			reprSym("builtin"),
		(ref immutable StructDeclAst.Body.Enum e) =>
			reprEnum(alloc, e),
		(ref immutable StructDeclAst.Body.ExternPtr) =>
			reprSym("extern-ptr"),
		(ref immutable StructDeclAst.Body.Record a) =>
			reprRecord(alloc, a),
		(ref immutable StructDeclAst.Body.Union a) =>
			reprUnion(alloc, a));
}

immutable(Repr) reprStructDeclAst(Alloc)(ref Alloc alloc, ref immutable StructDeclAst a) {
	return reprRecord(alloc, "struct", [
		reprRangeWithinFile(alloc, a.range),
		reprStr(a.docComment),
		reprBool(a.isPublic),
		reprArr(alloc, toArr(a.typeParams), (ref immutable TypeParamAst a) =>
			reprTypeParamAst(alloc, a)),
		reprOptPurity(alloc, a.purity),
		reprStructBodyAst(alloc, a.body_)]);
}

immutable(Repr) reprFunDeclAst(Alloc)(ref Alloc alloc, ref immutable FunDeclAst a) {
	ArrBuilder!NameAndRepr fields;
	if (!safeCStrIsEmpty(a.docComment))
		add(alloc, fields, nameAndRepr("doc", reprStr(a.docComment)));
	add(alloc, fields, nameAndRepr("public?", reprBool(a.isPublic)));
	if (!empty(toArr(a.typeParams)))
		add(alloc, fields, nameAndRepr(
			"typeparams",
			reprArr(alloc, toArr(a.typeParams), (ref immutable TypeParamAst t) =>
				reprTypeParamAst(alloc, t))));
	add(alloc, fields, nameAndRepr("sig", reprSig(alloc, a.sig)));
	if (!empty(a.specUses))
		add(alloc, fields, nameAndRepr("spec-uses", reprArr(alloc, a.specUses, (ref immutable SpecUseAst s) =>
			reprSpecUseAst(alloc, s))));
	if (a.noCtx)
		add(alloc, fields, nameAndRepr("noctx", reprBool(true)));
	if (a.summon)
		add(alloc, fields, nameAndRepr("summon", reprBool(true)));
	if (a.unsafe)
		add(alloc, fields, nameAndRepr("unsafe", reprBool(true)));
	if (a.trusted)
		add(alloc, fields, nameAndRepr("trusted", reprBool(true)));
	add(alloc, fields, nameAndRepr("body", reprFunBodyAst(alloc, a.body_)));
	return reprNamedRecord("fun-decl", finishArr(alloc, fields));
}

immutable(Repr) reprTypeParamAst(Alloc)(ref Alloc alloc, ref immutable TypeParamAst a) {
	return reprRecord(alloc, "type-param", [reprRangeWithinFile(alloc, a.range), reprSym(a.name)]);
}

immutable(Repr) reprSig(Alloc)(ref Alloc alloc, ref immutable SigAst a) {
	return reprRecord(alloc, "sig-ast", [
		reprRangeWithinFile(alloc, a.range),
		reprSym(a.name),
		reprTypeAst(alloc, a.returnType),
		reprArr(alloc, toArr(a.params), (ref immutable ParamAst p) => reprParamAst(alloc, p))]);
}

immutable(Repr) reprSpecUseAst(Alloc)(ref Alloc alloc, ref immutable SpecUseAst a) {
	return reprRecord(alloc, "spec-use", [
		reprRangeWithinFile(alloc, a.range),
		reprSym(a.spec.name),
		reprArr(alloc, toArr(a.typeArgs), (ref immutable TypeAst it) =>
			reprTypeAst(alloc, it))]);
}

immutable(Repr) reprTypeAst(Alloc)(ref Alloc alloc, ref immutable TypeAst a) {
	return matchTypeAst!(immutable Repr)(
		a,
		(ref immutable TypeAst.Fun it) =>
			reprRecord(alloc, "fun", [
				reprRangeWithinFile(alloc, it.range),
				reprSym(symOfFunKind(it.kind)),
				reprArr(alloc, it.returnAndParamTypes, (ref immutable TypeAst t) =>
					reprTypeAst(alloc, t))]),
		(ref immutable TypeAst.InstStruct i) =>
			reprInstStructAst(alloc, i),
		(ref immutable TypeAst.TypeParam p) =>
			reprRecord(alloc, "type-param", [reprRangeWithinFile(alloc, p.range), reprSym(p.name)]));
}

immutable(Sym) symOfFunKind(immutable TypeAst.Fun.Kind a) {
	final switch (a) {
		case TypeAst.Fun.Kind.act:
			return shortSymAlphaLiteral("act");
		case TypeAst.Fun.Kind.fun:
			return shortSymAlphaLiteral("fun");
		case TypeAst.Fun.Kind.ref_:
			return shortSymAlphaLiteral("ref");
	}
}

immutable(Repr) reprInstStructAst(Alloc)(ref Alloc alloc, ref immutable TypeAst.InstStruct a) {
	immutable Repr range = reprRangeWithinFile(alloc, a.range);
	immutable Repr name = reprNameAndRange(alloc, a.name);
	immutable Opt!Repr typeArgs = empty(toArr(a.typeArgs))
		? none!Repr
		: some(reprArr(alloc, toArr(a.typeArgs), (ref immutable TypeAst t) => reprTypeAst(alloc, t)));
	return reprRecord("inststruct", has(typeArgs)
		? arrLiteral!Repr(alloc, [range, name, force(typeArgs)])
		: arrLiteral!Repr(alloc, [range, name]));
}

immutable(Repr) reprParamAst(Alloc)(ref Alloc alloc, ref immutable ParamAst a) {
	return reprRecord(alloc, "param", [
		reprRangeWithinFile(alloc, a.range),
		reprOpt(alloc, a.name, (ref immutable Sym it) =>
			reprSym(it)),
		reprTypeAst(alloc, a.type)]);
}

immutable(Repr) reprFunBodyAst(Alloc)(ref Alloc alloc, ref immutable FunBodyAst a) {
	return matchFunBodyAst(
		a,
		(ref immutable FunBodyAst.Builtin) =>
			reprRecord("builtin"),
		(ref immutable FunBodyAst.Extern e) {
			immutable Repr isGlobal = reprBool(e.isGlobal);
			return reprRecord(alloc, "extern", [isGlobal]);
		},
		(ref immutable ExprAst e) =>
			reprExprAst(alloc, e));
}

immutable(Repr) reprExprAst(Alloc)(ref Alloc alloc, ref immutable ExprAst ast) {
	return reprExprAstKind(alloc, ast.kind);
}

immutable(Repr) reprNameAndRange(Alloc)(ref Alloc alloc, immutable NameAndRange a) {
	return reprRecord(alloc, "name-range", [reprNat(a.start), reprSym(a.name)]);
}

immutable(Repr) reprExprAstKind(Alloc)(ref Alloc alloc, ref immutable ExprAstKind ast) {
	return matchExprAstKind!(immutable Repr)(
		ast,
		(ref immutable BogusAst e) =>
			reprSym( "bogus"),
		(ref immutable CallAst e) =>
			reprRecord(alloc, "call", [
				reprSym(symOfCallAstStyle(e.style)),
				reprNameAndRange(alloc, e.funName),
				reprArr(alloc, toArr(e.typeArgs), (ref immutable TypeAst it) =>
					reprTypeAst(alloc, it)),
				reprArr(alloc, toArr(e.args), (ref immutable ExprAst it) =>
					reprExprAst(alloc, it))]),
		(ref immutable CreateArrAst e) =>
			reprRecord(alloc, "create-arr", [
				reprArr(alloc, toArr(e.args), (ref immutable ExprAst it) =>
					reprExprAst(alloc, it))]),
		(ref immutable FunPtrAst a) =>
			reprRecord(alloc, "fun-ptr", [reprSym(a.name)]),
		(ref immutable IdentifierAst a) =>
			reprSym(a.name),
		(ref immutable IfAst e) =>
			reprRecord(alloc, "if", [
				reprExprAst(alloc, e.cond),
				reprExprAst(alloc, e.then),
				reprOpt(alloc, e.else_, (ref immutable Ptr!ExprAst it) =>
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
					reprNameAndRange(alloc, it)),
				reprExprAst(alloc, it.body_)]),
		(ref immutable LetAst a) =>
			reprRecord(alloc, "let", [
				reprNameAndRange(alloc, a.name),
				reprExprAst(alloc, a.initializer),
				reprExprAst(alloc, a.then)]),
		(ref immutable LiteralAst a) =>
			reprRecord(alloc, "literal", [
				matchLiteralAst!(immutable Repr)(
					a,
					(ref immutable LiteralAst.Float it) =>
						reprRecord(alloc, "float", [reprFloat(it.value), reprBool(it.overflow)]),
					(ref immutable LiteralAst.Int it) =>
						reprRecord(alloc, "int", [reprInt(it.value), reprBool(it.overflow)]),
					(ref immutable LiteralAst.Nat it) =>
						reprRecord(alloc, "nat", [reprNat(it.value), reprBool(it.overflow)]),
					(ref immutable string it) =>
						reprStr(it))]),
		(ref immutable MatchAst it) =>
			reprRecord(alloc, "match", [
				reprExprAst(alloc, it.matched),
				reprArr(alloc, it.cases, (ref immutable MatchAst.CaseAst case_) =>
					reprRecord(alloc, "case", [
						reprRangeWithinFile(alloc, case_.range),
						reprNameAndRange(alloc, case_.structName),
						reprOpt(alloc, case_.local, (ref immutable NameAndRange nr) =>
							reprNameAndRange(alloc, nr)),
						reprExprAst(alloc, case_.then)]))]),
		(ref immutable ParenthesizedAst it) =>
			reprRecord(alloc, "paren", [reprExprAst(alloc, it.inner)]),
		(ref immutable SeqAst a) =>
			reprRecord(alloc, "seq-ast", [
				reprExprAst(alloc, a.first),
				reprExprAst(alloc, a.then)]),
		(ref immutable ThenAst it) =>
			reprRecord(alloc, "then-ast", [
				reprNameAndRange(alloc, it.left),
				reprExprAst(alloc, it.futExpr),
				reprExprAst(alloc, it.then)]),
		(ref immutable ThenVoidAst it) =>
			reprRecord(alloc, "then-void", [
				reprExprAst(alloc, it.futExpr),
				reprExprAst(alloc, it.then)]));
}

immutable(Repr) reprInterpolatedPart(Alloc)(ref Alloc alloc, ref immutable InterpolatedPart a) {
	return matchInterpolatedPart!(immutable Repr)(
		a,
		(ref immutable string it) => reprStr(it),
		(ref immutable ExprAst it) => reprExprAst(alloc, it));
}

immutable(Sym) symOfCallAstStyle(immutable CallAst.Style a) {
	final switch (a) {
		case CallAst.Style.dot:
			return shortSymAlphaLiteral("dot");
		case CallAst.Style.infix:
			return shortSymAlphaLiteral("infix");
		case CallAst.Style.prefix:
			return shortSymAlphaLiteral("prefix");
		case CallAst.Style.setDot:
			return shortSymAlphaLiteral("set-dot");
		case CallAst.Style.setSingle:
			return shortSymAlphaLiteral("set-single");
		case CallAst.Style.setSubscript:
			return shortSymAlphaLiteral("set-at");
		case CallAst.Style.single:
			return shortSymAlphaLiteral("single");
		case CallAst.Style.subscript:
			return shortSymAlphaLiteral("subscript");
	}
}
