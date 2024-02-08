module model.jsonOfModel;

@safe @nogc pure nothrow:

import model.ast : ImportOrExportAst, NameAndRange;
import model.jsonOfConstant : jsonOfConstant;
import model.model :
	AssertOrForbidExpr,
	BogusExpr,
	BuiltinFun,
	BuiltinSpec,
	Called,
	CalledSpecSig,
	CallExpr,
	ClosureGetExpr,
	ClosureSetExpr,
	Destructure,
	emptyTypeParams,
	EnumFunction,
	Expr,
	ExprAndType,
	FlagsFunction,
	FunBody,
	FunDecl,
	FunFlags,
	FunInst,
	FunPointerExpr,
	IfExpr,
	IfOptionExpr,
	ImportOrExport,
	ImportOrExportKind,
	LambdaExpr,
	LetExpr,
	LiteralExpr,
	LiteralStringLikeExpr,
	Local,
	LocalGetExpr,
	LocalSetExpr,
	LoopBreakExpr,
	LoopContinueExpr,
	LoopExpr,
	LoopUntilExpr,
	LoopWhileExpr,
	MatchEnumExpr,
	MatchUnionExpr,
	Module,
	NameReferents,
	Params,
	PtrToFieldExpr,
	PtrToLocalExpr,
	Purity,
	SeqExpr,
	SpecDecl,
	SpecDeclSig,
	SpecInst,
	StructDecl,
	StructInst,
	stringOfVisibility,
	Test,
	ThrowExpr,
	TrustedExpr,
	Type,
	TypedExpr,
	TypeParamIndex,
	TypeParams,
	VarDecl,
	VariableRef,
	Visibility;
import util.alloc.alloc : Alloc;
import util.col.array : mapOp;
import util.json :
	field,
	Json,
	jsonList,
	jsonNull,
	jsonObject,
	jsonString,
	optionalArrayField,
	optionalFlagField,
	optionalField,
	kindField;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : jsonOfLineAndColumnRange, LineAndColumnGetter, Range;
import util.symbol : Symbol, symbol;
import util.uri : AllUris, stringOfUri;
import util.util : ptrTrustMe, stringOfEnum;

Json jsonOfModule(ref Alloc alloc, in AllUris allUris, in LineAndColumnGetter lcg, in Module a) {
	Ctx ctx = Ctx(ptrTrustMe(a), ptrTrustMe(allUris), lcg);
	return jsonObject(alloc, [
		field!"uri"(stringOfUri(alloc, allUris, a.uri)),
		optionalArrayField!("imports", ImportOrExport)(alloc, a.imports, (in ImportOrExport x) =>
			jsonOfImportOrExport(alloc, ctx, x)),
		optionalArrayField!("re-exports", ImportOrExport)(alloc, a.reExports, (in ImportOrExport x) =>
			jsonOfImportOrExport(alloc, ctx, x)),
		optionalArrayField!("structs", StructDecl)(alloc, a.structs, (in StructDecl x) =>
			jsonOfStructDecl(alloc, ctx, x)),
		optionalArrayField!("vars", VarDecl)(alloc, a.vars, (in VarDecl x) =>
			jsonOfVarDecl(alloc, ctx, x)),
		optionalArrayField!("specs", SpecDecl)(alloc, a.specs, (in SpecDecl x) =>
			jsonOfSpecDecl(alloc, ctx, x)),
		optionalArrayField!("funs", FunDecl)(alloc, a.funs, (in FunDecl x) =>
			jsonOfFunDecl(alloc, ctx, x)),
		optionalArrayField!("tests", Test)(alloc, a.tests, (in Test x) =>
			jsonOfTest(alloc, ctx, x))]);
}

private:

Json jsonOfRange(ref Alloc alloc, in Ctx ctx, in Range range) =>
	jsonOfLineAndColumnRange(alloc, ctx.lineAndColumnGetter[range]);

Json jsonOfImportOrExport(ref Alloc alloc, in Ctx ctx, in ImportOrExport a) =>
	jsonObject(alloc, [
		optionalField!("source", ImportOrExportAst*)(a.source, (in ImportOrExportAst* x) =>
			jsonOfRange(alloc, ctx, x.pathRange(ctx.allUris))),
		field!"module"(stringOfUri(alloc, ctx.allUris, a.module_.uri)),
		field!"import-kind"(jsonOfImportOrExportKind(alloc, a.kind))]);

Json jsonOfImportOrExportKind(ref Alloc alloc, in ImportOrExportKind a) =>
	a.matchIn!Json(
		(in ImportOrExportKind.ModuleWhole) =>
			jsonString("whole"),
		(in Opt!(NameReferents*)[] referents) =>
			jsonList!(Opt!(NameReferents*))(alloc, referents, (in Opt!(NameReferents*) x) =>
				has(x) ? jsonString(force(x).name) : jsonNull));

const struct Ctx {
	@safe @nogc pure nothrow:

	Module* curModule;
	AllUris* allUrisPtr;
	LineAndColumnGetter lineAndColumnGetter;

	ref const(AllUris) allUris() return scope =>
		*allUrisPtr;
}

Json jsonOfStructDecl(ref Alloc alloc, in Ctx ctx, in StructDecl a) =>
	jsonObject(alloc,
		commonDeclFields(alloc, ctx, a.visibility, a.name, a.typeParams),
		[
			optionalField!"purity"(a.purity != Purity.data, () => jsonString(stringOfEnum(a.purity))),
			optionalFlagField!"forced"(a.purityIsForced),
		]);

Json jsonOfVarDecl(ref Alloc alloc, in Ctx ctx, in VarDecl a) =>
	jsonObject(alloc,
		commonDeclFields(alloc, ctx, a.visibility, a.name, emptyTypeParams),
		[
			field!"var-kind"(stringOfEnum(a.kind)),
			field!"type"(jsonOfType(alloc, ctx, a.type)),
			optionalField!("library-name", Symbol)(a.externLibraryName, (in Symbol x) => jsonString(x)),
		]);

Json jsonOfSpecDecl(ref Alloc alloc, in Ctx ctx, in SpecDecl a) =>
	jsonObject(
		alloc,
		commonDeclFields(alloc, ctx, a.visibility, a.name, a.typeParams),
		[
			optionalField!("builtin", BuiltinSpec)(a.builtin, (in BuiltinSpec x) => jsonString(stringOfEnum(x))),
				field!"parents"(jsonList!(SpecInst*)(alloc, a.parents, (in SpecInst* x) =>
					jsonOfSpecInst(alloc, ctx, *x))),
				field!"sigs"(jsonList!SpecDeclSig(alloc, a.sigs, (in SpecDeclSig x) =>
					jsonOfSpecDeclSig(alloc, ctx, x)))
		]);

Json jsonOfSpecDeclSig(ref Alloc alloc, in Ctx ctx, in SpecDeclSig a) =>
	jsonObject(alloc, [
		field!"where"(jsonOfLineAndColumnRange(alloc, ctx.lineAndColumnGetter[a.range.range])),
		field!"name"(a.name),
		field!"return-type"(jsonOfType(alloc, ctx, a.returnType)),
		field!"params"(jsonOfDestructures(alloc, ctx, a.params))]);

Json jsonOfFunDecl(ref Alloc alloc, in Ctx ctx, in FunDecl a) =>
	jsonObject(
		alloc,
		commonDeclFields(alloc, ctx, a.visibility, a.name, a.typeParams),
		[
			field!"flags"(funFlags(alloc, a.flags)),
			field!"return-type"(jsonOfType(alloc, ctx, a.returnType)),
			field!"params"(jsonOfParams(alloc, ctx, a.params)),
			optionalArrayField!"specs"(alloc, a.specs, (in SpecInst* x) => jsonOfSpecInst(alloc, ctx, *x)),
			field!"body"(jsonOfFunBody(alloc, ctx, a.body_)),
		]);

Json jsonOfTest(ref Alloc alloc, in Ctx ctx, in Test a) =>
	jsonObject(alloc, [
		field!"body"(jsonOfExpr(alloc, ctx, a.body_))]);

Json.ObjectField[3] commonDeclFields(
	ref Alloc alloc,
	in Ctx ctx,
	Visibility visibility,
	Symbol name,
	in TypeParams typeParams,
) =>
	[
		field!"visibility"(stringOfVisibility(visibility)),
		field!"name"(name),
		optionalArrayField!("type-params", NameAndRange)(alloc, typeParams, (in NameAndRange x) =>
			jsonOfTypeParam(alloc, x)),
	];

Json funFlags(ref Alloc alloc, in FunFlags a) {
	Opt!Symbol[5] symbols = [
		flag!"bare"(a.bare),
		flag!"summon"(a.summon),
		() {
			final switch (a.safety) {
				case FunFlags.Safety.safe:
					return none!Symbol;
				case FunFlags.Safety.trusted:
					return some(symbol!"trusted");
				case FunFlags.Safety.unsafe:
					return some(symbol!"unsafe");
			}
		}(),
		flag!"ok-if-unused"(a.okIfUnused),
		() {
			final switch (a.specialBody) {
				case FunFlags.SpecialBody.none:
					return none!Symbol;
				case FunFlags.SpecialBody.builtin:
					return some(symbol!"builtin");
				case FunFlags.SpecialBody.extern_:
					return some(symbol!"extern");
				case FunFlags.SpecialBody.generated:
					return some(symbol!"generated");
			}
		}(),
	];
	return jsonList(mapOp!(Json, Opt!Symbol)(alloc, symbols, (ref Opt!Symbol x) =>
		has(x) ? some(jsonString(force(x))) : none!Json));
}

Opt!Symbol flag(string name)(bool a) =>
	a ? some(symbol!name) : none!Symbol;

Json jsonOfTypeParam(ref Alloc alloc, in NameAndRange a) =>
	jsonObject(alloc, [field!"name"(a.name)]);

Json jsonOfParams(ref Alloc alloc, in Ctx ctx, in Params a) =>
	a.matchIn!Json(
		(in Destructure[] params) =>
			jsonOfDestructures(alloc, ctx, params),
		(in Params.Varargs v) =>
			jsonObject(alloc, [
				kindField!"varargs",
				field!"param"(jsonOfDestructure(alloc, ctx, v.param))]));

Json jsonOfDestructures(ref Alloc alloc, in Ctx ctx, in Destructure[] a) =>
	jsonList!Destructure(alloc, a, (in Destructure x) =>
		jsonOfDestructure(alloc, ctx, x));

Json jsonOfSpecInst(ref Alloc alloc, in Ctx ctx, in SpecInst a) =>
	jsonObject(alloc, [
		field!"name"(a.decl.name),
		optionalArrayField!("type-args", Type)(alloc, a.typeArgs, (in Type x) =>
			jsonOfType(alloc, ctx, x))]);

Json jsonOfFunBody(ref Alloc alloc, in Ctx ctx, in FunBody a) =>
	a.matchIn!Json(
		(in FunBody.Bogus) =>
			jsonString!"bogus" ,
		(in BuiltinFun _) =>
			jsonString!"builtin" ,
		(in FunBody.CreateEnum x) =>
			jsonObject(alloc, [kindField!"create-enum", field!"member"(x.member.name)]),
		(in FunBody.CreateExtern) =>
			jsonString!"new-extern",
		(in FunBody.CreateRecord) =>
			jsonString!"new-record" ,
		(in FunBody.CreateUnion) =>
			//TODO: more detail
			jsonString!"new-union" ,
		(in EnumFunction x) =>
			jsonObject(alloc, [
				kindField!"enum-fn",
				field!"fn"(stringOfEnum(x))]),
		(in FunBody.Extern x) =>
			jsonObject(alloc, [
				kindField!"extern",
				field!"library-name"(x.libraryName)]),
		(in FunBody.ExpressionBody x) =>
			jsonOfExpr(alloc, ctx, x.expr),
		(in FunBody.FileImport x) =>
			jsonObject(alloc, [
				kindField!"file-import",
				field!"uri"(stringOfUri(alloc, ctx.allUris, x.uri))]),
		(in FlagsFunction x) =>
			jsonObject(alloc, [
				kindField!"flags-fn",
				field!"name"(stringOfEnum(x))]),
		(in FunBody.RecordFieldCall x) =>
			jsonObject(alloc, [
				kindField!"field-call",
				field!"field-index"(x.fieldIndex)]),
		(in FunBody.RecordFieldGet x) =>
			jsonObject(alloc, [
				kindField!"field-get",
				field!"field-index"(x.fieldIndex)]),
		(in FunBody.RecordFieldPointer x) =>
			jsonObject(alloc, [
				kindField!"field-pointer",
				field!"field-index"(x.fieldIndex)]),
		(in FunBody.RecordFieldSet x) =>
			jsonObject(alloc, [
				kindField!"field-set",
				field!"field-index"(x.fieldIndex)]),
		(in FunBody.VarGet) =>
			jsonString!"var-get",
		(in FunBody.VarSet) =>
			jsonString!"var-set");

Json jsonOfType(ref Alloc alloc, in Ctx ctx, in Type a) =>
	a.matchIn!Json(
		(in Type.Bogus) =>
			jsonString!"bogus" ,
		(in TypeParamIndex x) =>
			jsonObject(alloc, [
				kindField!"type-param",
				field!"index"(x.index)]),
		(in StructInst x) =>
			jsonOfStructInst(alloc, ctx, x));

Json jsonOfStructInst(ref Alloc alloc, in Ctx ctx, in StructInst a) =>
	jsonObject(alloc, [
		field!"name"(a.decl.name),
		optionalArrayField!("type-args", Type)(alloc, a.typeArgs, (in Type x) =>
			jsonOfType(alloc, ctx, x))]);

Json jsonOfExprs(ref Alloc alloc, in Ctx ctx, in Expr[] a) =>
	jsonList!Expr(alloc, a, (in Expr x) =>
		jsonOfExpr(alloc, ctx, x));

Json jsonOfExprAndType(ref Alloc alloc, in Ctx ctx, in ExprAndType a) =>
	jsonObject(alloc, [
		field!"expr"(jsonOfExpr(alloc, ctx, a.expr)),
		field!"type"(jsonOfType(alloc, ctx, a.type))]);

Json jsonOfExpr(ref Alloc alloc, in Ctx ctx, in Expr a) =>
	a.kind.matchIn!Json(
		(in AssertOrForbidExpr x) =>
			jsonObject(alloc, [
				kindField(stringOfEnum(x.kind)),
				field!"condition"(jsonOfExpr(alloc, ctx, *x.condition)),
				optionalField!("thrown", Expr*)(x.thrown, (in Expr* thrown) =>
					jsonOfExpr(alloc, ctx, *thrown))]),
		(in BogusExpr _) =>
			jsonObject(alloc, [kindField!"bogus"]),
		(in CallExpr x) =>
			jsonObject(alloc, [
				kindField!"call",
				field!"called"(jsonOfCalled(alloc, ctx, x.called)),
				field!"args"(jsonOfExprs(alloc, ctx, x.args))]),
		(in ClosureGetExpr x) =>
			jsonObject(alloc, [
				kindField!"closure-get",
				field!"index"(x.closureRef.index)]),
		(in ClosureSetExpr x) =>
			jsonObject(alloc, [
				kindField!"closure-set",
				field!"index"(x.closureRef.index)]),
		(in FunPointerExpr x) =>
			jsonObject(alloc, [
				kindField!"fun-pointer",
				field!"fun"(jsonOfFunInst(alloc, ctx, *x.funInst))]),
		(in IfExpr x) =>
			jsonObject(alloc, [
				kindField!"if",
				field!"condition"(jsonOfExpr(alloc, ctx, x.cond)),
				field!"then"(jsonOfExpr(alloc, ctx, x.then)),
				field!"else"(jsonOfExpr(alloc, ctx, x.else_))]),
		(in IfOptionExpr x) =>
			jsonObject(alloc, [
				kindField!"if-option",
				field!"destructure"(jsonOfDestructure(alloc, ctx, x.destructure)),
				field!"option"(jsonOfExprAndType(alloc, ctx, x.option)),
				field!"then"(jsonOfExpr(alloc, ctx, x.then)),
				field!"else"(jsonOfExpr(alloc, ctx, x.else_))]),
		(in LambdaExpr x) =>
			jsonObject(alloc, [
				kindField!"lambda",
				field!"param"(jsonOfDestructure(alloc, ctx, x.param)),
				field!"body"(jsonOfExpr(alloc, ctx, x.body_)),
				field!"closure"(jsonList!VariableRef(alloc, x.closure, (in VariableRef v) =>
					jsonString(v.name))),
				field!"fun-kind"(stringOfEnum(x.kind)),
				field!"return-type"(jsonOfType(alloc, ctx, x.returnType))]),
		(in LetExpr x) =>
			jsonObject(alloc, [
				kindField!"let",
				field!"destructure"(jsonOfDestructure(alloc, ctx, x.destructure)),
				field!"value"(jsonOfExpr(alloc, ctx, x.value)),
				field!"then"(jsonOfExpr(alloc, ctx, x.then))]),
		(in LiteralExpr x) =>
			jsonObject(alloc, [
				kindField!"literal",
				field!"value"(jsonOfConstant(alloc, x.value))]),
		(in LiteralStringLikeExpr x) =>
			jsonObject(alloc, [
				kindField!"string",
				field!"type"(jsonString(stringOfEnum(x.kind))),
				field!"value"(jsonString(alloc, x.value))]),
		(in LocalGetExpr x) =>
			jsonObject(alloc, [
				kindField!"local-get",
				field!"name"(x.local.name)]),
		(in LocalSetExpr x) =>
			jsonObject(alloc, [
				kindField!"local-set",
				field!"name"(x.local.name),
				field!"value"(jsonOfExpr(alloc, ctx, x.value))]),
		(in LoopExpr x) =>
			jsonObject(alloc, [
				kindField!"loop",
				field!"body"(jsonOfExpr(alloc, ctx, x.body_))]),
		(in LoopBreakExpr x) =>
			jsonObject(alloc, [
				kindField!"break",
				field!"value"(jsonOfExpr(alloc, ctx, x.value))]),
		(in LoopContinueExpr x) =>
			jsonObject(alloc, [kindField!"continue"]),
		(in LoopUntilExpr x) =>
			jsonObject(alloc, [
				kindField!"until",
				field!"condition"(jsonOfExpr(alloc, ctx, x.condition)),
				field!"body"(jsonOfExpr(alloc, ctx, x.body_))]),
		(in LoopWhileExpr x) =>
			jsonObject(alloc, [
				kindField!"while",
				field!"condition"(jsonOfExpr(alloc, ctx, x.condition)),
				field!"body"(jsonOfExpr(alloc, ctx, x.body_))]),
		(in MatchEnumExpr a) =>
			jsonObject(alloc, [
				kindField!"match-enum",
				field!"matched"(jsonOfExprAndType(alloc, ctx, a.matched)),
				field!"cases"(jsonOfExprs(alloc, ctx, a.cases))]),
		(in MatchUnionExpr a) =>
			jsonObject(alloc, [
				kindField!"match-union",
				field!"matched"(jsonOfExprAndType(alloc, ctx, a.matched)),
				field!"cases"(jsonList!(MatchUnionExpr.Case)(alloc, a.cases, (in MatchUnionExpr.Case case_) =>
					jsonOfMatchUnionCase(alloc, ctx, case_)))]),
		(in PtrToFieldExpr x) =>
			jsonObject(alloc, [
				kindField!"pointer-to-field",
				field!"target"(jsonOfExprAndType(alloc, ctx, x.target)),
				field!"field-index"(x.fieldIndex)]),
		(in PtrToLocalExpr x) =>
			jsonObject(alloc, [
				kindField!"pointer-to-local",
				field!"name"(x.local.name)]),
		(in SeqExpr a) =>
			jsonObject(alloc, [
				kindField!"seq",
				field!"first"(jsonOfExpr(alloc, ctx, a.first)),
				field!"then"(jsonOfExpr(alloc, ctx, a.then))]),
		(in ThrowExpr a) =>
			jsonObject(alloc, [
				kindField!"throw",
				field!"thrown"(jsonOfExpr(alloc, ctx, a.thrown))]),
		(in TrustedExpr a) =>
			jsonObject(alloc, [
				kindField!"trusted",
				field!"inner"(jsonOfExpr(alloc, ctx, a.inner))]),
		(in TypedExpr a) =>
			jsonObject(alloc, [
				kindField!"typed",
				field!"inner"(jsonOfExpr(alloc, ctx, a.inner))]));

Json jsonOfDestructure(ref Alloc alloc, in Ctx ctx, in Destructure a) =>
	a.matchIn!Json(
		(in Destructure.Ignore _) =>
			jsonString!"_",
		(in Local x) =>
			jsonOfLocal(alloc, ctx, x),
		(in Destructure.Split split) =>
			jsonOfDestructureSplit(alloc, ctx, split));

Json jsonOfDestructureSplit(ref Alloc alloc, in Ctx ctx, in Destructure.Split a) =>
	jsonObject(alloc, [
		kindField!"split",
		field!"type"(jsonOfType(alloc, ctx, a.destructuredType)),
		field!"parts"(jsonOfDestructures(alloc, ctx, a.parts))]);

Json jsonOfMatchUnionCase(ref Alloc alloc, in Ctx ctx, in MatchUnionExpr.Case a) =>
	jsonObject(alloc, [
		field!"destructure"(jsonOfDestructure(alloc, ctx, a.destructure)),
		field!"then"(jsonOfExpr(alloc, ctx, a.then))]);

Json jsonOfLocal(ref Alloc alloc, in Ctx ctx, in Local a) =>
	jsonObject(alloc, [
		kindField!"local",
		field!"name"(a.name),
		field!"mutability"(stringOfEnum(a.mutability)),
		field!"type"(jsonOfType(alloc, ctx, a.type))]);

Json jsonOfCalled(ref Alloc alloc, in Ctx ctx, in Called a) =>
	a.matchIn!Json(
		(in FunInst x) =>
			jsonOfFunInst(alloc, ctx, x),
		(in CalledSpecSig x) =>
			jsonOfCalledSpecSig(alloc, ctx, x));

Json jsonOfFunInst(ref Alloc alloc, in Ctx ctx, in FunInst a) =>
	jsonObject(alloc, [
		field!"name"(a.decl.name),
		optionalArrayField!("type-args", Type)(alloc, a.typeArgs, (in Type x) =>
			jsonOfType(alloc, ctx, x)),
		optionalArrayField!("spec-impls", Called)(alloc, a.specImpls, (in Called x) =>
			jsonOfCalled(alloc, ctx, x))]);

Json jsonOfCalledSpecSig(ref Alloc alloc, in Ctx ctx, in CalledSpecSig a) =>
	jsonObject(alloc, [
		kindField!"spec-sig",
		field!"spec"(a.specInst.decl.name),
		field!"name"(a.name)]);
