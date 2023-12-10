module model.jsonOfModel;

@safe @nogc pure nothrow:

import frontend.parse.ast : ImportOrExportAst, NameAndRange, pathRange;
import model.jsonOfConstant : jsonOfConstant;
import model.model :
	AssertOrForbidExpr,
	BogusExpr,
	Called,
	CalledSpecSig,
	CallExpr,
	ClosureGetExpr,
	ClosureSetExpr,
	Destructure,
	emptyTypeParams,
	EnumFunction,
	enumFunctionName,
	Expr,
	ExprAndType,
	FlagsFunction,
	flagsFunctionName,
	FunBody,
	FunDecl,
	FunFlags,
	FunInst,
	FunPtrExpr,
	IfExpr,
	IfOptionExpr,
	ImportOrExport,
	ImportOrExportKind,
	LambdaExpr,
	LetExpr,
	LiteralExpr,
	LiteralCStringExpr,
	LiteralSymbolExpr,
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
	name,
	Params,
	PtrToFieldExpr,
	PtrToLocalExpr,
	Purity,
	range,
	SeqExpr,
	SpecDecl,
	SpecDeclBody,
	SpecDeclSig,
	specImpls,
	SpecInst,
	StructDecl,
	StructInst,
	symOfAssertOrForbidKind,
	symOfFunKind,
	symOfLocalMutability,
	symOfPurity,
	symOfSpecBodyBuiltinKind,
	symOfVarKind,
	symOfVisibility,
	Test,
	ThrowExpr,
	Type,
	typeArgs,
	TypeParamIndex,
	TypeParams,
	typeParams,
	VarDecl,
	VariableRef,
	Visibility;
import util.alloc.alloc : Alloc;
import util.col.arrUtil : mapOp;
import util.json :
	field, Json, jsonList, jsonObject, jsonString, optionalArrayField, optionalFlagField, optionalField, kindField;
import util.lineAndColumnGetter : LineAndColumnGetter;
import util.opt : force, has, none, Opt, some;
import util.ptr : ptrTrustMe;
import util.sourceRange : jsonOfRange;
import util.sym : Sym, sym;
import util.uri : AllUris, stringOfUri;
import util.util : unreachable;

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

Json jsonOfImportOrExport(ref Alloc alloc, in Ctx ctx, in ImportOrExport a) =>
	jsonObject(alloc, [
		optionalField!("source", ImportOrExportAst*)(a.source, (in ImportOrExportAst* x) =>
			jsonOfRange(alloc, ctx.lineAndColumnGetter, pathRange(ctx.allUris, *x))),
		field!"import-kind"(jsonOfImportOrExportKind(alloc, ctx.allUris, a.kind))]);

Json jsonOfImportOrExportKind(ref Alloc alloc, in AllUris allUris, in ImportOrExportKind a) =>
	a.matchIn!Json(
		(in ImportOrExportKind.ModuleWhole m) =>
			jsonObject(alloc, [field!"module"(stringOfUri(alloc, allUris, m.module_.uri))]),
		(in ImportOrExportKind.ModuleNamed m) =>
			jsonObject(alloc, [
				field!"module"(stringOfUri(alloc, allUris, m.module_.uri)),
				field!"names"(jsonList!Sym(alloc, m.names, (in Sym name) =>
					jsonString(name)))]));

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
			optionalField!"purity"(a.purity != Purity.data, () => jsonString(symOfPurity(a.purity))),
			optionalFlagField!"forced"(a.purityIsForced),
		]);

Json jsonOfVarDecl(ref Alloc alloc, in Ctx ctx, in VarDecl a) =>
	jsonObject(alloc,
		commonDeclFields(alloc, ctx, a.visibility, a.name, emptyTypeParams),
		[
			field!"var-kind"(symOfVarKind(a.kind)),
			field!"type"(jsonOfType(alloc, ctx, a.type)),
			optionalField!("library-name", Sym)(a.externLibraryName, (in Sym x) => jsonString(x)),
		]);

Json jsonOfSpecDecl(ref Alloc alloc, in Ctx ctx, in SpecDecl a) =>
	jsonObject(
		alloc,
		commonDeclFields(alloc, ctx, a.visibility, a.name, a.typeParams),
		[
			optionalArrayField!"parents"(alloc, a.parents, (in SpecInst* x) => jsonOfSpecInst(alloc, ctx, *x)),
			field!"body"(jsonOfSpecDeclBody(alloc, ctx, a.body_)),
		]);

Json jsonOfSpecDeclBody(ref Alloc alloc, in Ctx ctx, in SpecDeclBody a) =>
	a.matchIn!Json(
		(in SpecDeclBody.Builtin x) =>
			jsonString(symOfSpecBodyBuiltinKind(x.kind)),
		(in SpecDeclSig[] xs) =>
			jsonList!SpecDeclSig(alloc, xs, (in SpecDeclSig x) =>
				jsonOfSpecDeclSig(alloc, ctx, x)));

Json jsonOfSpecDeclSig(ref Alloc alloc, in Ctx ctx, in SpecDeclSig a) =>
	jsonObject(alloc, [
		field!"where"(jsonOfRange(alloc, ctx.lineAndColumnGetter, range(a).range)),
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
	Sym name,
	in TypeParams typeParams,
) =>
	[
		field!"visibility"(symOfVisibility(visibility)),
		field!"name"(name),
		optionalArrayField!("type-params", NameAndRange)(alloc, typeParams, (in NameAndRange x) =>
			jsonOfTypeParam(alloc, x)),
	];

Json funFlags(ref Alloc alloc, in FunFlags a) {
	Opt!Sym[5] syms = [
		flag!"bare"(a.bare),
		flag!"summon"(a.summon),
		() {
			final switch (a.safety) {
				case FunFlags.Safety.safe:
					return none!Sym;
				case FunFlags.Safety.unsafe:
					return some(sym!"unsafe");
			}
		}(),
		flag!"ok-if-unused"(a.okIfUnused),
		() {
			final switch (a.specialBody) {
				case FunFlags.SpecialBody.none:
					return none!Sym;
				case FunFlags.SpecialBody.builtin:
					return some(sym!"builtin");
				case FunFlags.SpecialBody.extern_:
					return some(sym!"extern");
				case FunFlags.SpecialBody.generated:
					return some(sym!"generated");
			}
		}(),
	];
	return jsonList(mapOp!(Json, Opt!Sym)(alloc, syms, (ref Opt!Sym x) =>
		has(x) ? some(jsonString(force(x))) : none!Json));
}

Opt!Sym flag(string name)(bool a) =>
	a ? some(sym!name) : none!Sym;

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
		(in FunBody.Builtin) =>
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
				field!"name"(enumFunctionName(x))]),
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
				field!"name"(flagsFunctionName(x))]),
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
				kindField(symOfAssertOrForbidKind(x.kind)),
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
		(in FunPtrExpr x) =>
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
				field!"fun-kind"(symOfFunKind(x.kind)),
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
		(in LiteralCStringExpr x) =>
			jsonObject(alloc, [
				kindField!"c-string",
				field!"value"(jsonString(alloc, x.value))]),
		(in LiteralSymbolExpr x) =>
			jsonObject(alloc, [
				kindField!"symbol",
				field!"value"(x.value)]),
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
				field!"thrown"(jsonOfExpr(alloc, ctx, a.thrown))]));

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
		field!"mutability"(symOfLocalMutability(a.mutability)),
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
		optionalArrayField!("type-args", Type)(alloc, typeArgs(a), (in Type x) =>
			jsonOfType(alloc, ctx, x)),
		optionalArrayField!("spec-impls", Called)(alloc, specImpls(a), (in Called x) =>
			jsonOfCalled(alloc, ctx, x))]);

Json jsonOfCalledSpecSig(ref Alloc alloc, in Ctx ctx, in CalledSpecSig a) =>
	jsonObject(alloc, [
		kindField!"spec-sig",
		field!"spec"(a.specInst.decl.name),
		field!"name"(a.name)]);
