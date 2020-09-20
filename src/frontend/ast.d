module frontend.ast;

@safe @nogc pure nothrow:

import util.bools : Bool, True;
import util.collection.arr : Arr, ArrWithSize, empty, emptyArr, toArr;
import util.collection.arrBuilder : add, ArrBuilder, finishArr;
import util.collection.arrUtil : arrLiteral, map;
import util.collection.str : emptyStr, Str;
import util.opt : force, has, mapOption, none, Opt, some;
import util.path : Path, pathToStr;
import util.ptr : Ptr;
import util.sexpr :
	NameAndSexpr,
	nameAndTata,
	Sexpr,
	tataArr,
	tataBool,
	tataNamedRecord,
	tataNat,
	tataOpt,
	tataRecord,
	tataStr,
	tataSym;
import util.sourceRange : sexprOfSourceRange, SourceRange;
import util.sym : shortSymAlphaLiteral, Sym;
import util.types : u8;
import util.util : todo, unreachable, verify;

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
		immutable ArrWithSize!TypeAst typeArgs;
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

@trusted T matchTypeAst(T)(
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

immutable(SourceRange) range(ref immutable TypeAst a) {
	return matchTypeAst(
		a,
		(ref immutable TypeAst.TypeParam it) => it.range,
		(ref immutable TypeAst.InstStruct it) => it.range);
}

struct BogusAst {}

struct CallAst {
	immutable Sym funName;
	immutable ArrWithSize!TypeAst typeArgs;
	immutable Arr!ExprAst args;
}

struct WhenAst {
	struct Case {
		// TODO: would prefer to store by value, but that causes WASM compile errors
		immutable Ptr!ExprAst cond;
		immutable Ptr!ExprAst then;
	}
	immutable Arr!Case cases;
	immutable Opt!(Ptr!ExprAst) else_; // parse error if missing
}

struct CreateArrAst {
	immutable Opt!(Ptr!TypeAst) elementType; // Ptr because this is rarely needed
	immutable Arr!ExprAst args;
}

struct CreateRecordAst {
	immutable Opt!(Ptr!TypeAst) type;
	immutable Arr!ExprAst args;
}

struct CreateRecordMultiLineAst {
	struct Line {
		immutable NameAndRange name;
		immutable ExprAst value;
	}

	immutable Opt!(Ptr!TypeAst) type;
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

	immutable Kind literalKind;
	immutable Str literal;
}

// This is never parsed directly.
// This is used by 'checkLiteral' to ensure we don't recurse.
struct LiteralInnerAst {
	immutable LiteralAst.Kind literalKind;
	immutable Str literal;
}

struct MatchAst {
	struct CaseAst {
		immutable SourceRange range;
		immutable Sym structName;
		immutable Opt!NameAndRange local;
		immutable Ptr!ExprAst then;
	}

	immutable Opt!(Ptr!ExprAst) matched; // parse error if missing
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
		bogus,
		call,
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
		when,
	}
	immutable Kind kind;
	union {
		immutable BogusAst bogus;
		immutable CallAst call;
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
		immutable WhenAst when;
	}

	public:
	@trusted immutable this(immutable BogusAst a) { kind = Kind.bogus; bogus = a; }
	@trusted immutable this(immutable CallAst a) { kind = Kind.call; call = a; }
	@trusted immutable this(immutable CreateArrAst a) { kind = Kind.createArr; createArr = a; }
	@trusted immutable this(immutable CreateRecordAst a) { kind = Kind.createRecord; createRecord = a; }
	@trusted immutable this(immutable CreateRecordMultiLineAst a) {
		kind = Kind.createRecordMultiLine; createRecordMultiLine = a;
	}
	@trusted immutable this(immutable IdentifierAst a) { kind = Kind.identifier; identifier = a; }
	@trusted immutable this(immutable LambdaAst a) { kind = Kind.lambda; lambda = a; }
	@trusted immutable this(immutable LetAst a) { kind = Kind.let; let = a; }
	@trusted immutable this(immutable LiteralAst a) { kind = Kind.literal; literal = a; }
	@trusted immutable this(immutable LiteralInnerAst a) { kind = Kind.literalInner; literalInner = a; }
	@trusted immutable this(immutable MatchAst a) { kind = Kind.match; match_ = a; }
	@trusted immutable this(immutable SeqAst a) { kind = Kind.seq; seq = a; }
	@trusted immutable this(immutable RecordFieldSetAst a) { kind = Kind.recordFieldSet; recordFieldSet = a; }
	@trusted immutable this(immutable ThenAst a) { kind = Kind.then; then = a; }
	@trusted immutable this(immutable WhenAst a) { kind = Kind.when; when = a; }
}

immutable(Bool) isIdentifier(ref immutable ExprAstKind a) {
	return Bool(a.kind == ExprAstKind.Kind.identifier);
}
ref immutable(IdentifierAst) asIdentifier(return ref immutable ExprAstKind a) {
	verify(a.isIdentifier);
	return a.identifier;
}

immutable(Bool) isCall(ref immutable ExprAstKind a) {
	return Bool(a.kind == ExprAstKind.Kind.call);
}
@trusted ref immutable(CallAst) asCall(return ref immutable ExprAstKind a) {
	verify(a.isCall);
	return a.call;
}

@trusted T matchExprAstKind(T)(
	scope ref immutable ExprAstKind a,
	scope immutable(T) delegate(scope ref immutable BogusAst) @safe @nogc pure nothrow cbBogus,
	scope immutable(T) delegate(scope ref immutable CallAst) @safe @nogc pure nothrow cbCall,
	scope immutable(T) delegate(scope ref immutable CreateArrAst) @safe @nogc pure nothrow cbCreateArr,
	scope immutable(T) delegate(scope ref immutable CreateRecordAst) @safe @nogc pure nothrow cbCreateRecord,
	scope immutable(T) delegate(
		scope ref immutable CreateRecordMultiLineAst
	) @safe @nogc pure nothrow cbCreateRecordMultiLine,
	scope immutable(T) delegate(scope ref immutable IdentifierAst) @safe @nogc pure nothrow cbIdentifier,
	scope immutable(T) delegate(scope ref immutable LambdaAst) @safe @nogc pure nothrow cbLambda,
	scope immutable(T) delegate(scope ref immutable LetAst) @safe @nogc pure nothrow cbLet,
	scope immutable(T) delegate(scope ref immutable LiteralAst) @safe @nogc pure nothrow cbLiteral,
	scope immutable(T) delegate(scope ref immutable LiteralInnerAst) @safe @nogc pure nothrow cbLiteralInner,
	scope immutable(T) delegate(scope ref immutable MatchAst) @safe @nogc pure nothrow cbMatch,
	scope immutable(T) delegate(scope ref immutable SeqAst) @safe @nogc pure nothrow cbSeq,
	scope immutable(T) delegate(scope ref immutable RecordFieldSetAst) @safe @nogc pure nothrow cbRecordFieldSet,
	scope immutable(T) delegate(scope ref immutable ThenAst) @safe @nogc pure nothrow cbThen,
	scope immutable(T) delegate(scope ref immutable WhenAst) @safe @nogc pure nothrow cbWhen,
) {
	final switch (a.kind) {
		case ExprAstKind.Kind.bogus:
			return cbBogus(a.bogus);
		case ExprAstKind.Kind.call:
			return cbCall(a.call);
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
		case ExprAstKind.Kind.when:
			return cbWhen(a.when);
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
	immutable ArrWithSize!TypeAst typeArgs;
}

struct SigAst {
	immutable SourceRange range;
	immutable Sym name;
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
		struct ExternPtr {}
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
			externPtr,
			record,
			union_,
		}

		immutable Kind kind;
		union {
			immutable Builtin builtin;
			immutable ExternPtr externPtr;
			immutable Record record;
			immutable Union union_;
		}

		public:

		immutable this(immutable Builtin a) { kind = Kind.builtin; builtin = a; }
		immutable this(immutable ExternPtr a) { kind = Kind.externPtr; externPtr = a; }
		@trusted immutable this(immutable Record a) { kind = Kind.record; record = a; }
		@trusted immutable this(immutable Union a) { kind = Kind.union_; union_ = a; }
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

@trusted T matchStructDeclAstBody(T)(
	immutable ref StructDeclAst.Body a,
	scope T delegate(ref immutable StructDeclAst.Body.Builtin) @safe @nogc pure nothrow cbBuiltin,
	scope T delegate(ref immutable StructDeclAst.Body.ExternPtr) @safe @nogc pure nothrow cbExternPtr,
	scope T delegate(ref immutable StructDeclAst.Body.Record) @safe @nogc pure nothrow cbRecord,
	scope T delegate(ref immutable StructDeclAst.Body.Union) @safe @nogc pure nothrow cbUnion,
) {
	final switch (a.kind) {
		case StructDeclAst.Body.Kind.builtin:
			return cbBuiltin(a.builtin);
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
		immutable Arr!SigAst sigs;
	}

	public:
	this(immutable Builtin a) { kind = Kind.builtin; builtin = a; }
	@trusted this(immutable Arr!SigAst a) { kind = Kind.sigs; sigs = a; }
}

@trusted T matchSpecBodyAst(T)(
	immutable ref SpecBodyAst a,
	scope T delegate(ref immutable SpecBodyAst.Builtin) @safe @nogc pure nothrow cbBuiltin,
	scope T delegate(ref immutable Arr!SigAst) @safe @nogc pure nothrow cbSigs,
) {
	final switch (a.kind) {
		case SpecBodyAst.Kind.builtin:
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

@trusted T matchFunBodyAst(T)(
	immutable ref FunBodyAst a,
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
	immutable Arr!TypeParamAst typeParams; // If this is empty, infer type params
	immutable Ptr!SigAst sig; // Ptr to keep this struct from getting too big
	immutable Arr!SpecUseAst specUses;
	immutable Bool isPublic;
	immutable Bool noCtx;
	immutable Bool summon;
	immutable Bool unsafe;
	immutable Bool trusted;
	immutable Ptr!FunBodyAst body_;
}

struct ImportAst {
	immutable SourceRange range;
	immutable u8 nDots;
	immutable Ptr!Path path;
}

// TODO: I'm doing this because the wasm compilation generates a call to 'memset' whenever there's a big struct.
struct FileAstPart0 {
	immutable Arr!ImportAst imports;
	immutable Arr!ImportAst exports;
	immutable Arr!SpecDeclAst specs;
}

struct FileAstPart1 {
	immutable Arr!StructAliasAst structAliases;
	immutable Arr!StructDeclAst structs;
	immutable Arr!FunDeclAst funs;
}

struct FileAst {
	immutable Ptr!FileAstPart0 part0;
	immutable Ptr!FileAstPart1 part1;
}

private immutable FileAstPart0 emptyFileAstPart0 =
	immutable FileAstPart0(emptyArr!ImportAst, emptyArr!ImportAst, emptyArr!SpecDeclAst);
private immutable FileAstPart1 emptyFileAstPart1 =
	immutable FileAstPart1(emptyArr!StructAliasAst, emptyArr!StructDeclAst, emptyArr!FunDeclAst);
immutable FileAst emptyFileAst = immutable FileAst(
	immutable Ptr!FileAstPart0(&emptyFileAstPart0),
	immutable Ptr!FileAstPart1(&emptyFileAstPart1));

ref immutable(Arr!ImportAst) imports(return scope ref immutable FileAst a) {
	return a.part0.imports;
}

ref immutable(Arr!ImportAst) exports(return scope ref immutable FileAst a) {
	return a.part0.exports;
}

ref immutable(Arr!SpecDeclAst) specs(return scope ref immutable FileAst a) {
	return a.part0.specs;
}

ref immutable(Arr!StructAliasAst) structAliases(return scope ref immutable FileAst a) {
	return a.part1.structAliases;
}

ref immutable(Arr!StructDeclAst) structs(return scope ref immutable FileAst a) {
	return a.part1.structs;
}

ref immutable(Arr!FunDeclAst) funs(return scope ref immutable FileAst a) {
	return a.part1.funs;
}

immutable(Sexpr) sexprOfAst(Alloc)(ref Alloc alloc, ref immutable FileAst ast) {
	return tataNamedRecord(
		"file-ast",
		arrLiteral!NameAndSexpr(
			alloc,
			nameAndTata("imports", tataArr(alloc, ast.imports, (ref immutable ImportAst a) =>
				sexprOfImportAst(alloc, a))),
			nameAndTata("exports", tataArr(alloc, ast.exports, (ref immutable ImportAst a) =>
				sexprOfImportAst(alloc, a))),
			nameAndTata("specs", tataArr(alloc, ast.specs, (ref immutable SpecDeclAst a) =>
				sexprOfSpecDeclAst(alloc, a))),
			nameAndTata("aliases", tataArr(alloc, ast.structAliases, (ref immutable StructAliasAst a) =>
				sexprOfStructAliasAst(alloc, a))),
			nameAndTata("structs", tataArr(alloc, ast.structs, (ref immutable StructDeclAst a) =>
				sexprOfStructDeclAst(alloc, a))),
			nameAndTata("funs", tataArr(alloc, ast.funs, (ref immutable FunDeclAst a) =>
				sexprOfFunDeclAst(alloc, a)))));
}

private:

immutable(Sexpr) sexprOfImportAst(Alloc)(ref Alloc alloc, ref immutable ImportAst a) {
	return tataRecord(
		alloc,
		"import-ast",
		tataNat(a.nDots),
		tataStr(pathToStr(alloc, emptyStr, a.path, emptyStr)));
}

immutable(Sexpr) sexprOfSpecDeclAst(Alloc)(ref Alloc alloc, ref immutable SpecDeclAst a) {
	return todo!(immutable Sexpr)("sexprOfSpecDecl");
}

immutable(Sexpr) sexprOfStructAliasAst(Alloc)(ref Alloc alloc, ref immutable StructAliasAst a) {
	return todo!(immutable Sexpr)("sexprOfImport");
}

immutable(Sexpr) sexprOfOptPurity(Alloc)(ref Alloc alloc, immutable Opt!PuritySpecifier purity) {
	return tataOpt(alloc, purity, (ref immutable PuritySpecifier a) =>
		tataSym(() {
			final switch (force(purity)) {
				case PuritySpecifier.data:
					return "data";
				case PuritySpecifier.forceData:
					return "force-data";
				case PuritySpecifier.sendable:
					return "sendable";
				case PuritySpecifier.forceSendable:
					return "force-send";
				case PuritySpecifier.mut:
					return "mut";
			}
		}()));
}

immutable(Sexpr) sexprOfOptExplicitByValOrRef(Alloc)(ref Alloc alloc, immutable Opt!ExplicitByValOrRef a) {
	return tataOpt(alloc, a, (ref immutable ExplicitByValOrRef it) =>
		tataSym(() {
			final switch (it) {
				case ExplicitByValOrRef.byVal:
					return "by-val";
				case ExplicitByValOrRef.byRef:
					return "by-ref";
			}
		}()));
}

immutable(Sexpr) sexprOfField(Alloc)(ref Alloc alloc, ref immutable StructDeclAst.Body.Record.Field a) {
	return tataRecord(
		alloc,
		"field",
		sexprOfSourceRange(alloc, a.range),
		tataBool(a.isMutable),
		tataSym(a.name),
		sexprOfTypeAst(alloc, a.type));
}

immutable(Sexpr) sexprOfRecord(Alloc)(ref Alloc alloc, ref immutable StructDeclAst.Body.Record a) {
	return tataRecord(
		alloc,
		"record",
		sexprOfOptExplicitByValOrRef(alloc, a.explicitByValOrRef),
		tataArr(alloc, a.fields, (ref immutable StructDeclAst.Body.Record.Field it) =>
			sexprOfField(alloc, it)));
}

immutable(Sexpr) sexprOfUnion(Alloc)(ref Alloc alloc, ref immutable StructDeclAst.Body.Union a) {
	return tataRecord(
		alloc,
		"union",
		tataArr(alloc, a.members, (ref immutable TypeAst.InstStruct member) =>
			sexprOfInstStructAst(alloc, member)));
}

immutable(Sexpr) sexprOfStructBodyAst(Alloc)(ref Alloc alloc, ref immutable StructDeclAst.Body a) {
	return matchStructDeclAstBody(
		a,
		(ref immutable StructDeclAst.Body.Builtin) =>
			tataSym("builtin"),
		(ref immutable StructDeclAst.Body.ExternPtr) =>
			tataSym("extern"),
		(ref immutable StructDeclAst.Body.Record a) =>
			sexprOfRecord(alloc, a),
		(ref immutable StructDeclAst.Body.Union a) =>
			sexprOfUnion(alloc, a));
}

immutable(Sexpr) sexprOfStructDeclAst(Alloc)(ref Alloc alloc, ref immutable StructDeclAst a) {
	return tataRecord(
		alloc,
		"struct",
		sexprOfSourceRange(alloc, a.range),
		tataBool(a.isPublic),
		tataArr(alloc, a.typeParams, (ref immutable TypeParamAst a) =>
			sexprOfTypeParamAst(alloc, a)),
		sexprOfOptPurity(alloc, a.purity),
		sexprOfStructBodyAst(alloc, a.body_));
}

immutable(Sexpr) sexprOfFunDeclAst(Alloc)(ref Alloc alloc, ref immutable FunDeclAst a) {
	ArrBuilder!NameAndSexpr fields;
	add(alloc, fields, nameAndTata("public?", tataBool(a.isPublic)));
	if (!empty(a.typeParams))
		add(alloc, fields, nameAndTata("typeparams", tataArr(alloc, a.typeParams, (ref immutable TypeParamAst t) =>
			sexprOfTypeParamAst(alloc, t))));
	add(alloc, fields, nameAndTata("sig", sexprOfSig(alloc, a.sig)));
	if (!empty(a.specUses))
		add(alloc, fields, nameAndTata("spec-uses", tataArr(alloc, a.specUses, (ref immutable SpecUseAst s) =>
			sexprOfSpecUseAst(alloc, s))));
	if (a.noCtx)
		add(alloc, fields, nameAndTata("noctx", tataBool(True)));
	if (a.summon)
		add(alloc, fields, nameAndTata("summon", tataBool(True)));
	if (a.unsafe)
		add(alloc, fields, nameAndTata("unsafe", tataBool(True)));
	if (a.trusted)
		add(alloc, fields, nameAndTata("trusted", tataBool(True)));
	add(alloc, fields, nameAndTata("body", sexprOfFunBodyAst(alloc, a.body_)));
	return tataNamedRecord("fun-decl", finishArr(alloc, fields));
}

immutable(Sexpr) sexprOfTypeParamAst(Alloc)(ref Alloc alloc, ref immutable TypeParamAst a) {
	return tataRecord(
		alloc,
		"type-param",
		sexprOfSourceRange(alloc, a.range),
		tataSym(a.name));
}

immutable(Sexpr) sexprOfSig(Alloc)(ref Alloc alloc, ref immutable SigAst a) {
	return tataRecord(
		alloc,
		"sig-ast",
		sexprOfSourceRange(alloc, a.range),
		tataSym(a.name),
		sexprOfTypeAst(alloc, a.returnType),
		tataArr(alloc, toArr(a.params), (ref immutable ParamAst p) => sexprOfParamAst(alloc, p)));
}

immutable(Sexpr) sexprOfSpecUseAst(Alloc)(ref Alloc alloc, ref immutable SpecUseAst a) {
	return todo!(immutable Sexpr)("sexprOfSpecUseAst");
}

immutable(Sexpr) sexprOfTypeAst(Alloc)(ref Alloc alloc, ref immutable TypeAst a) {
	return matchTypeAst!(immutable Sexpr)(
		a,
		(ref immutable TypeAst.TypeParam p) =>
			tataRecord(alloc, "type-param", sexprOfSourceRange(alloc, p.range), tataSym(p.name)),
		(ref immutable TypeAst.InstStruct i) =>
			sexprOfInstStructAst(alloc, i));
}

immutable(Sexpr) sexprOfOptTypeAst(Alloc)(ref Alloc alloc, immutable Opt!(Ptr!TypeAst) a) {
	return tataOpt(alloc, a, (ref immutable Ptr!TypeAst it) =>
		sexprOfTypeAst(alloc, it));
}

immutable(Sexpr) sexprOfInstStructAst(Alloc)(ref Alloc alloc, ref immutable TypeAst.InstStruct a) {
	immutable Sexpr range = sexprOfSourceRange(alloc, a.range);
	immutable Sexpr name = tataSym(a.name);
	immutable Opt!Sexpr typeArgs = empty(toArr(a.typeArgs))
		? none!Sexpr
		: some(tataArr(alloc, toArr(a.typeArgs), (ref immutable TypeAst t) => sexprOfTypeAst(alloc, t)));
	return tataRecord(
		"inststruct",
		has(typeArgs) ? arrLiteral!Sexpr(alloc, range, name, force(typeArgs)) : arrLiteral!Sexpr(alloc, range, name));
}

immutable(Sexpr) sexprOfParamAst(Alloc)(ref Alloc alloc, ref immutable ParamAst a) {
	return tataRecord(
		alloc,
		"param",
		sexprOfSourceRange(alloc, a.range),
		tataSym(a.name),
		sexprOfTypeAst(alloc, a.type));
}

immutable(Sexpr) sexprOfFunBodyAst(Alloc)(ref Alloc alloc, ref immutable FunBodyAst a) {
	return matchFunBodyAst(
		a,
		(ref immutable FunBodyAst.Builtin) =>
			tataRecord("builtin"),
		(ref immutable FunBodyAst.Extern e) {
			immutable Sexpr isGlobal = tataBool(e.isGlobal);
			return tataRecord("extern", has(e.mangledName)
				? arrLiteral!Sexpr(alloc, isGlobal, tataStr(force(e.mangledName)))
				: arrLiteral!Sexpr(alloc, isGlobal));
		},
		(ref immutable ExprAst e) =>
			sexprOfExprAst(alloc, e));
}

immutable(Sexpr) sexprOfExprAst(Alloc)(ref Alloc alloc, ref immutable ExprAst ast) {
	return sexprOfExprAstKind(alloc, ast.kind);
}

immutable(Sexpr) sexprOfNameAndRange(Alloc)(ref Alloc alloc, ref immutable NameAndRange a) {
	return tataRecord(alloc, "name-range", sexprOfSourceRange(alloc, a.range), tataSym(a.name));
}

immutable(Sexpr) sexprOfExprAstKind(Alloc)(ref Alloc alloc, ref immutable ExprAstKind ast) {
	return matchExprAstKind!(immutable Sexpr)(
		ast,
		(ref immutable BogusAst e) =>
			tataSym( "bogus"),
		(ref immutable CallAst e) =>
			tataRecord(
				alloc,
				"call",
				tataSym(e.funName),
				tataArr(alloc, toArr(e.typeArgs), (ref immutable TypeAst it) =>
					sexprOfTypeAst(alloc, it)),
				tataArr(alloc, e.args, (ref immutable ExprAst it) =>
					sexprOfExprAst(alloc, it))),
		(ref immutable CreateArrAst e) =>
			tataRecord(
				alloc,
				"create-arr",
				tataOpt(alloc,  e.elementType, (ref immutable Ptr!TypeAst it) =>
					sexprOfTypeAst(alloc, it)),
				tataArr(alloc, e.args, (ref immutable ExprAst it) =>
					sexprOfExprAst(alloc, it))),
		(ref immutable CreateRecordAst a) =>
			tataRecord(
				alloc,
				"new-record",
				sexprOfOptTypeAst(alloc, a.type),
				tataArr(alloc, a.args, (ref immutable ExprAst it) =>
					sexprOfExprAst(alloc, it))),
		(ref immutable CreateRecordMultiLineAst a) =>
			tataRecord(
				alloc,
				"new-record",
				sexprOfOptTypeAst(alloc, a.type),
				tataArr(alloc, a.lines, (ref immutable CreateRecordMultiLineAst.Line it) =>
					tataRecord(
						alloc,
						"line",
						sexprOfNameAndRange(alloc, it.name),
						sexprOfExprAst(alloc, it.value)))),
		(ref immutable IdentifierAst a)  =>
			tataSym(a.name),
		(ref immutable LambdaAst a) =>
			tataRecord(
				alloc,
				"lambda",
				tataArr(alloc, a.params, (ref immutable LambdaAst.Param it) =>
					sexprOfLambdaParamAst(alloc, it))),
		(ref immutable LetAst a) =>
			tataRecord(
				alloc,
				"let",
				sexprOfNameAndRange(alloc, a.name),
				sexprOfExprAst(alloc, a.initializer),
				sexprOfExprAst(alloc, a.then)),
		(ref immutable LiteralAst a) =>
			tataRecord(
				alloc,
				"literal",
				tataSym(() {
					final switch (a.literalKind) {
						case LiteralAst.Kind.numeric:
							return "numeric";
						case LiteralAst.Kind.string_:
							return "string";
					}
				}()),
				tataStr(a.literal)),
		(ref immutable LiteralInnerAst) =>
			// Only used temporarily; should never need to print this
			unreachable!(immutable Sexpr),
		(ref immutable MatchAst it) =>
			tataRecord(
				alloc,
				"match",
				tataOpt(alloc, it.matched, (ref immutable Ptr!ExprAst matched) =>
					sexprOfExprAst(alloc, matched)),
				tataArr(alloc, it.cases, (ref immutable MatchAst.CaseAst case_) =>
					tataRecord(
						alloc,
						"case",
						sexprOfSourceRange(alloc, case_.range),
						tataSym(case_.structName),
						tataOpt(alloc, case_.local, (ref immutable NameAndRange nr) =>
							sexprOfNameAndRange(alloc, nr)),
						sexprOfExprAst(alloc, case_.then)))),
		(ref immutable SeqAst a) =>
			tataRecord(
				alloc,
				"seq-ast",
				sexprOfExprAst(alloc, a.first),
				sexprOfExprAst(alloc, a.then)),
		(ref immutable RecordFieldSetAst it) =>
			tataRecord(
				alloc,
				"field-set",
				sexprOfExprAst(alloc, it.target),
				tataSym(it.fieldName),
				sexprOfExprAst(alloc, it.value)),
		(ref immutable ThenAst it) =>
			tataRecord(
				alloc,
				"then-ast",
				sexprOfLambdaParamAst(alloc, it.left),
				sexprOfExprAst(alloc, it.futExpr),
				sexprOfExprAst(alloc, it.then)),
		(ref immutable WhenAst e) =>
			tataRecord(
				alloc,
				"when",
				tataArr(alloc, e.cases, (ref immutable WhenAst.Case case_) =>
					tataRecord(
						alloc,
						"case",
						sexprOfExprAst(alloc, case_.cond),
						sexprOfExprAst(alloc, case_.then))),
				tataOpt(alloc, e.else_, (ref immutable Ptr!ExprAst it) =>
					sexprOfExprAst(alloc, it))));
}

immutable(Sexpr) sexprOfLambdaParamAst(Alloc)(ref Alloc alloc, ref immutable LambdaAst.Param a) {
	return tataRecord(
		alloc,
		"param",
		sexprOfSourceRange(alloc, a.range),
		tataSym(a.name));
}
