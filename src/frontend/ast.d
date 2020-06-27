module frontend.ast;

@safe @nogc pure nothrow:

import util.opt : Opt;
import util.path : Path;
import util.ptr : Ptr;

import util.bools : Bool;
import util.collection.arr : Arr;
import util.collection.str : Str;
import util.sourceRange : SourceRange;
import util.sym : Sym;
import util.types : u8;

struct NameAndRange {
	immutable SourceRange range;
	immutable Sym name;
}

struct TypeAst {
	@safe @nogc pure nothrow:
	struct TypeParam {
		immutable SourceRange range;
		immutable Sym name;
	}

	struct InstStruct {
		immutable SourceRange range;
		immutable Sym name;
		immutable Arr!TypeAst typeArgs;
	}

	@trusted this(immutable TypeParam t) {
		kind = Kind.typeParam;
		typeParam = t;
	}
	@trusted this(immutable InstStruct i) {
		kind = Kind.instStruct;
		instStruct = i;
	}

	private:

	enum Kind {
		typeParam,
		instStruct
	}
	immutable Kind kind;
	union {
		immutable TypeParam typeParam;
		immutable InstStruct instStruct;
	}
}

@trusted T match(T)(
	ref immutable TypeAst a,
	scope T delegate(ref immutable TypeAst.TypeParam) @safe @nogc pure nothrow cbTypeParam,
	scope T delegate(ref immutable TypeAst.InstStruct) @safe @nogc pure nothrow cbInstStruct
) {
	final switch (a.kind) {
		case TypeAst.Kind.typeParam:
			return cbTypeParam(a.typeParam);
		case TypeAst.Kind.instStruct:
			return cbInstStruct(a.instStruct);
	}
}

struct CallAst {
	immutable Sym funName;
	immutable Arr!TypeAst typeArgs;
	immutable Arr!ExprAst args;
}

struct CondAst {
	immutable Ptr!ExprAst cond;
	immutable Ptr!ExprAst then;
	immutable Ptr!ExprAst elze;
}

struct CreateArrAst {
	immutable Opt!TypeAst elementType;
	immutable Arr!ExprAst args;
}

struct CreateRecordAst {
	immutable Opt!TypeAst type;
	immutable Arr!ExprAst args;
}

struct CreateRecordMultiLineAst {
	struct Line {
		immutable NameAndRange name;
		immutable ExprAst value;
	}

	immutable Opt!TypeAst type;
	immutable Arr!Line lines;
}

struct IdentifierAst {
	immutable Sym name;
}

struct LambdaAst {
	struct Param {
		immutable SourceRange range;
		immutable Sym name;
	}

	immutable Arr!Param params;
	immutable Ptr!ExprAst body_;
}

struct LetAst {
	immutable NameAndRange name;
	immutable Ptr!ExprAst initializer;
	immutable Ptr!ExprAst then;
}

struct LiteralAst {
	enum Kind {
		numeric,
		string_,
	}

	immutable Kind kind;
	immutable Str literal;
}

// This is never parsed directly.
// This is used by 'checkLiteral' to ensure we don't recurse.
struct LiteralInnerAst {
	immutable LiteralAst.Kind kind;
	immutable Str literal;
}

struct MatchAst {
	struct CaseAst {
		immutable SourceRange range;
		immutable Sym structName;
		immutable Opt!NameAndRange local;
		immutable Ptr!ExprAst then;
	}

	immutable Ptr!ExprAst matched;
	immutable Arr!CaseAst cases;
}

struct SeqAst {
	immutable Ptr!ExprAst first;
	immutable Ptr!ExprAst then;
}

struct RecordFieldSetAst {
	immutable Ptr!ExprAst target;
	immutable Sym fieldName;
	immutable Ptr!ExprAst value;
}

struct ThenAst {
	immutable LambdaAst.Param left;
	immutable Ptr!ExprAst futExpr;
	immutable Ptr!ExprAst then;
}

struct ExprAstKind {
	@safe @nogc pure nothrow:

	private:
	enum Kind {
		call,
		cond,
		createArr,
		createRecord,
		createRecordMultiLine,
		identifier,
		lambda,
		let,
		literal,
		literalInner,
		match,
		seq,
		recordFieldSet,
		then,
	}
	immutable Kind kind;
	union {
		immutable CallAst call;
		immutable CondAst cond;
		immutable CreateArrAst createArr;
		immutable CreateRecordAst createRecord;
		immutable CreateRecordMultiLineAst createRecordMultiLine;
		immutable IdentifierAst identifier;
		immutable LambdaAst lambda;
		immutable LetAst let;
		immutable LiteralAst literal;
		immutable LiteralInnerAst literalInner;
		immutable MatchAst match_;
		immutable SeqAst seq;
		immutable RecordFieldSetAst recordFieldSet;
		immutable ThenAst then;
	}

	public:
	@trusted this(immutable CallAst a) { kind = Kind.call; call = a; }
	@trusted this(immutable CondAst a) { kind = Kind.cond; cond = a; }
	@trusted this(immutable CreateArrAst a) { kind = Kind.createArr; createArr = a; }
	@trusted this(immutable CreateRecordAst a) { kind = Kind.createRecord; createRecord = a; }
	@trusted this(immutable CreateRecordMultiLineAst a) { kind = Kind.createRecordMultiLine; createRecordMultiLine = a; }
	@trusted this(immutable IdentifierAst a) { kind = Kind.identifier; identifier = a; }
	@trusted this(immutable LambdaAst a) { kind = Kind.lambda; lambda = a; }
	@trusted this(immutable LetAst a) { kind = Kind.let; let = a; }
	@trusted this(immutable LiteralAst a) { kind = Kind.literal; literal = a; }
	@trusted this(immutable LiteralInnerAst a) { kind = Kind.literalInner; literalInner = a; }
	@trusted this(immutable MatchAst a) { kind = Kind.match; match_ = a; }
	@trusted this(immutable SeqAst a) { kind = Kind.seq; seq = a; }
	@trusted this(immutable RecordFieldSetAst a) { kind = Kind.recordFieldSet; recordFieldSet = a; }
	@trusted this(immutable ThenAst a) { kind = Kind.then; then = a; }
}

immutable(Bool) isIdentifier(ref immutable ExprAstKind a) {
	return Bool(a.kind == ExprAstKind.Kind.identifier);
}
ref immutable(IdentifierAst) asIdentifier(return ref immutable ExprAstKind a) {
	assert(a.isIdentifier);
	return a.identifier;
}

immutable(Bool) isCall(ref immutable ExprAstKind a) {
	return Bool(a.kind == ExprAstKind.Kind.call);
}
@trusted ref immutable(CallAst) asCall(return ref immutable ExprAstKind a) {
	assert(a.isCall);
	return a.call;
}

@trusted T matchAst(T)(
	scope ref immutable ExprAstKind a,
	scope immutable(T) delegate(scope ref immutable CallAst) @safe @nogc pure nothrow cbCall,
	scope immutable(T) delegate(scope ref immutable CondAst) @safe @nogc pure nothrow cbCond,
	scope immutable(T) delegate(scope ref immutable CreateArrAst) @safe @nogc pure nothrow cbCreateArr,
	scope immutable(T) delegate(scope ref immutable CreateRecordAst) @safe @nogc pure nothrow cbCreateRecord,
	scope immutable(T) delegate(scope ref immutable CreateRecordMultiLineAst) @safe @nogc pure nothrow cbCreateRecordMultiLine,
	scope immutable(T) delegate(scope ref immutable IdentifierAst) @safe @nogc pure nothrow cbIdentifier,
	scope immutable(T) delegate(scope ref immutable LambdaAst) @safe @nogc pure nothrow cbLambda,
	scope immutable(T) delegate(scope ref immutable LetAst) @safe @nogc pure nothrow cbLet,
	scope immutable(T) delegate(scope ref immutable LiteralAst) @safe @nogc pure nothrow cbLiteral,
	scope immutable(T) delegate(scope ref immutable LiteralInnerAst) @safe @nogc pure nothrow cbLiteralInner,
	scope immutable(T) delegate(scope ref immutable MatchAst) @safe @nogc pure nothrow cbMatch,
	scope immutable(T) delegate(scope ref immutable SeqAst) @safe @nogc pure nothrow cbSeq,
	scope immutable(T) delegate(scope ref immutable RecordFieldSetAst) @safe @nogc pure nothrow cbRecordFieldSet,
	scope immutable(T) delegate(scope ref immutable ThenAst) @safe @nogc pure nothrow cbThen,
) {
	final switch (a.kind) {
		case ExprAstKind.Kind.call:
			return cbCall(a.call);
		case ExprAstKind.Kind.cond:
			return cbCond(a.cond);
		case ExprAstKind.Kind.createArr:
			return cbCreateArr(a.createArr);
		case ExprAstKind.Kind.createRecord:
			return cbCreateRecord(a.createRecord);
		case ExprAstKind.Kind.createRecordMultiLine:
			return cbCreateRecordMultiLine(a.createRecordMultiLine);
		case ExprAstKind.Kind.identifier:
			return cbIdentifier(a.identifier);
		case ExprAstKind.Kind.lambda:
			return cbLambda(a.lambda);
		case ExprAstKind.Kind.let:
			return cbLet(a.let);
		case ExprAstKind.Kind.literal:
			return cbLiteral(a.literal);
		case ExprAstKind.Kind.literalInner:
			return cbLiteralInner(a.literalInner);
		case ExprAstKind.Kind.match:
			return cbMatch(a.match_);
		case ExprAstKind.Kind.seq:
			return cbSeq(a.seq);
		case ExprAstKind.Kind.recordFieldSet:
			return cbRecordFieldSet(a.recordFieldSet);
		case ExprAstKind.Kind.then:
			return cbThen(a.then);
	}
}

struct ExprAst {
	immutable SourceRange range;
	immutable ExprAstKind kind;
}

// This is the declaration, TypeAst.TypeParam is the use
struct TypeParamAst {
	immutable SourceRange range;
	immutable Sym name;
}

struct ParamAst {
	immutable SourceRange range;
	immutable Sym name;
	immutable TypeAst type;
}

struct SpecUseAst {
	immutable SourceRange range;
	immutable Sym spec;
	immutable Arr!TypeAst typeArgs;
}

struct SigAst {
	immutable SourceRange range;
	immutable Sym name;
	immutable TypeAst returnType;
	immutable Arr!ParamAst params;
}

enum PuritySpecifier {
	sendable,
	forceSendable,
	mut,
}

struct StructAliasAst {
	immutable SourceRange range;
	immutable Bool isPublic;
	immutable Sym name;
	immutable Arr!TypeParamAst typeParams;
	immutable TypeAst.InstStruct target;
}

enum ExplicitByValOrRef {
	byVal,
	byRef,
}

struct StructDeclAst {
	struct Body {
		@safe @nogc pure nothrow:
		struct Builtin {}
		struct Record {
			struct Field {
				immutable SourceRange range;
				immutable Bool isMutable;
				immutable Sym name;
				immutable TypeAst type;
			}
			immutable Opt!ExplicitByValOrRef explicitByValOrRef;
			immutable Arr!Field fields;
		}
		struct Union {
			immutable Arr!(TypeAst.InstStruct) members;
		}

		private:
		enum Kind {
			builtin,
			record,
			union_,
		}

		immutable Kind kind;
		union {
			immutable Builtin builtin;
			immutable Record record;
			immutable Union union_;
		}

		public:

		this(immutable Builtin a) { kind = Kind.builtin; builtin = a; }
		@trusted this(immutable Record a) { kind = Kind.record; record = a; }
		@trusted this(immutable Union a) { kind = Kind.union_; union_ = a; }
	}

	immutable SourceRange range;
	immutable Bool isPublic;
	immutable Sym name;
	immutable Arr!TypeParamAst typeParams;
	immutable Opt!PuritySpecifier purity;
	immutable Body body_;
}

immutable(Bool) isRecord(immutable ref StructDeclAst.Body a) {
	return Bool(a.kind == StructDeclAst.Body.Kind.record);
}
immutable(Bool) isUnion(immutable ref StructDeclAst.Body a) {
	return Bool(a.kind == StructDeclAst.Body.Kind.union_);
}

T match(T)(
	immutable ref StructDeclAst.Body a,
	scope T delegate(ref immutable StructDeclAst.Body.Builtin) @safe @nogc pure nothrow cbBuiltin,
	scope T delegate(ref immutable StructDeclAst.Body.Record) @safe @nogc pure nothrow cbRecord,
	scope T delegate(ref immutable StructDeclAst.Body.Union) @safe @nogc pure nothrow cbUnion,
) {
	final switch (a.kind) {
		case StructDeclAst.Body.Kind.builtin:
			return cbBuiltin(a.builtin);
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
		immutable Arr!SigAst sigs;
	}

	public:
	this(immutable Builtin a) { kind = Kind.builtin; builtin = a; }
	@trusted this(immutable Arr!SigAst a) { kind = Kind.sigs; sigs = a; }
}

T match(T)(
	immutable ref SpecBodyAst a,
	scope T delegate(ref immutable SpecBodyAst.Builtin) @safe @nogc pure nothrow cbBuiltin,
	scope T delegate(ref immutable SpecBodyAst.Sigs) @safe @nogc pure nothrow cbSigs,
) {
	final switch (a.kind) {
		case SpecBodyAst.Kind.builtlin:
			return cbBuiltin(a.builtin);
		case SpecBodyAst.Kind.sigs:
			return cbSigs(a.sigs);
	}
}

struct SpecDeclAst {
	immutable SourceRange range;
	immutable Bool isPublic;
	immutable Sym name;
	immutable Arr!TypeParamAst typeParams;
	immutable SpecBodyAst body_;
}

struct FunBodyAst {
	@safe @nogc pure nothrow:

	struct Builtin {}
	struct Extern {
		Bool isGlobal;
		Opt!Str mangledName;
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
	this(immutable Builtin a) immutable { kind = Kind.builtin; builtin = a; }
	@trusted this(immutable Extern a) immutable { kind = Kind.extern_; extern_ = a; }
	@trusted this(immutable ExprAst a) immutable { kind = Kind.exprAst; exprAst = a; }
}

T match(T)(
	immutable ref FunBodyAst a,
	scope T delegate(ref immutable FunBodyAst.Builtin) @safe @nogc pure nothrow cbBuiltin,
	scope T delegate(ref immutable FunBodyAst.Extern) @safe @nogc pure nothrow cbExtern,
	scope T delegate(ref immutable FunBodyAst.ExprAst) @safe @nogc pure nothrow cbExprAst,
) {
	final switch (a.kind) {
		case Kind.builtin:
			return cbBuiltin(a.builtin);
		case Kind.extern_:
			return cbExtern(a.extern_);
		case Kind.exprAst:
			return cbExprAst(a.exprAst);
	}
}

struct FunDeclAst {
	immutable Bool isPublic;
	immutable Arr!TypeParamAst typeParams; // If this is empty, infer type params
	immutable SigAst sig;
	immutable Arr!SpecUseAst specUses;
	immutable Bool noCtx;
	immutable Bool summon;
	immutable Bool unsafe;
	immutable Bool trusted;
	immutable FunBodyAst body_;
}

struct ImportAst {
	immutable SourceRange range;
	immutable u8 nDots;
	immutable Ptr!Path path;
}

struct FileAst {
	immutable Arr!ImportAst imports;
	immutable Arr!ImportAst exports;
	immutable Arr!SpecDeclAst specs;
	immutable Arr!StructAliasAst structAliases;
	immutable Arr!StructDeclAst structs;
	immutable Arr!FunDeclAst funs;
}
