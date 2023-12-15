module frontend.parse.jsonOfAst;

@safe @nogc pure nothrow:

import frontend.parse.ast :
	ArrowAccessAst,
	AssertOrForbidAst,
	AssignmentAst,
	AssignmentCallAst,
	BogusAst,
	CallAst,
	DestructureAst,
	EmptyAst,
	ExprAst,
	ExprAstKind,
	FieldMutabilityAst,
	FileAst,
	ForAst,
	FunDeclAst,
	FunModifierAst,
	IdentifierAst,
	IfAst,
	IfOptionAst,
	ImportOrExportAst,
	ImportOrExportAstKind,
	ImportsOrExportsAst,
	InterpolatedAst,
	InterpolatedPart,
	LambdaAst,
	LetAst,
	LiteralFloatAst,
	LiteralIntAst,
	LiteralIntOrNat,
	LiteralNatAst,
	LiteralStringAst,
	LoopAst,
	LoopBreakAst,
	LoopContinueAst,
	LoopUntilAst,
	LoopWhileAst,
	MatchAst,
	ModifierAst,
	NameAndRange,
	ParamsAst,
	ParenthesizedAst,
	PathOrRelPath,
	PtrAst,
	SeqAst,
	SpecBodyAst,
	SpecDeclAst,
	SpecSigAst,
	StructAliasAst,
	StructDeclAst,
	stringOfFieldMutabilityAstKind,
	stringOfSpecialFlag,
	symForTypeAstSuffix,
	symOfModifierKind,
	ThenAst,
	ThrowAst,
	TrustedAst,
	TypeAst,
	TypedAst,
	UnlessAst,
	WithAst;
import util.alloc.alloc : Alloc;
import util.col.arr : empty;
import util.json :
	field,
	Json,
	jsonObject,
	optionalArrayField,
	optionalFlagField,
	optionalField,
	optionalStringField,
	Json,
	jsonInt,
	jsonList,
	jsonString,
	kindField;
import util.lineAndColumnGetter : LineAndColumnGetter, PosKind;
import util.opt : Opt;
import util.sourceRange : jsonOfPosWithinFile, jsonOfRange, Pos, Range;
import util.union_ : Union;
import util.uri : AllUris, Path, pathToSafeCStr, RelPath;
import util.util : ptrTrustMe, stringOfEnum;

Json jsonOfAst(ref Alloc alloc, in AllUris allUris, in LineAndColumnGetter lineAndColumnGetter, in FileAst ast) {
	Ctx ctx = Ctx(ptrTrustMe(allUris), lineAndColumnGetter);
	return jsonObject(alloc, [
		optionalStringField!"doc"(alloc, ast.docComment),
		optionalField!("imports", ImportsOrExportsAst)(ast.imports, (in ImportsOrExportsAst x) =>
			jsonOfImportsOrExports(alloc, ctx, x)),
		optionalField!("exports", ImportsOrExportsAst)(ast.reExports, (in ImportsOrExportsAst x) =>
			jsonOfImportsOrExports(alloc, ctx, x)),
		optionalArrayField!("specs", SpecDeclAst)(alloc, ast.specs, (in SpecDeclAst a) =>
			jsonOfSpecDeclAst(alloc, ctx, a)),
		optionalArrayField!("aliases", StructAliasAst)(alloc, ast.structAliases, (in StructAliasAst a) =>
			jsonOfStructAliasAst(alloc, ctx, a)),
		optionalArrayField!("structs", StructDeclAst)(alloc, ast.structs, (in StructDeclAst a) =>
			jsonOfStructDeclAst(alloc, ctx, a)),
		optionalArrayField!("funs", FunDeclAst)(alloc, ast.funs, (in FunDeclAst a) =>
			jsonOfFunDeclAst(alloc, ctx, a))]);
}

private:

const struct Ctx {
	@safe @nogc pure nothrow:

	const AllUris* allUrisPtr;
	LineAndColumnGetter lineAndColumnGetter;

	ref const(AllUris) allUris() const return scope =>
		*allUrisPtr;
}

Json jsonOfRange(ref Alloc alloc, scope ref Ctx ctx, in Range a) =>
	jsonOfRange(alloc, ctx.lineAndColumnGetter, a);

Json jsonOfImportsOrExports(ref Alloc alloc, scope ref Ctx ctx, in ImportsOrExportsAst a) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRange(alloc, ctx, a.range)),
		field!"imports"(jsonList!ImportOrExportAst(alloc, a.paths, (in ImportOrExportAst a) =>
			jsonOfImportOrExportAst(alloc, ctx, a)))]);

Json jsonOfImportOrExportAst(ref Alloc alloc, scope ref Ctx ctx, in ImportOrExportAst a) =>
	jsonObject(alloc, [
		field!"path"(pathOrRelPathToJson(alloc, ctx.allUris, a.path)),
		field!"import-kind"(a.kind.matchIn!Json(
			(in ImportOrExportAstKind.ModuleWhole) =>
				jsonString!"whole",
			(in NameAndRange[] names) =>
				jsonObject(alloc, [
					field!"names"(jsonList!NameAndRange(alloc, names, (in NameAndRange name) =>
						jsonOfNameAndRange(alloc, ctx, name)))]),
			(in ImportOrExportAstKind.File f) =>
				jsonObject(alloc, [
					field!"name"(jsonOfNameAndRange(alloc, ctx, f.name)),
					field!"file-type"(stringOfEnum(f.type))])))]);

Json pathOrRelPathToJson(ref Alloc alloc, in AllUris allUris, PathOrRelPath a) =>
	a.match!Json(
		(Path global) =>
			jsonString(pathToSafeCStr(alloc, allUris, global, false)),
		(RelPath relPath) =>
			jsonObject(alloc, [
				field!"nParents"(relPath.nParents),
				field!"path"(pathToSafeCStr(alloc, allUris, relPath.path, false))]));

Json jsonOfSpecDeclAst(ref Alloc alloc, scope ref Ctx ctx, in SpecDeclAst a) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRange(alloc, ctx, a.range)),
		field!"comment"(jsonString(alloc, a.docComment)),
		field!"visibility"(stringOfEnum(a.visibility)),
		field!"name"(jsonOfNameAndRange(alloc, ctx, a.name)),
		field!"parents"(jsonOfTypeAsts(alloc, ctx, a.parents)),
		maybeTypeParams(alloc, ctx, a.typeParams),
		field!"body"(jsonOfSpecBodyAst(alloc, ctx, a.body_))]);

Json jsonOfSpecBodyAst(ref Alloc alloc, scope ref Ctx ctx, in SpecBodyAst a) =>
	a.matchIn!Json(
		(in SpecBodyAst.Builtin) =>
			jsonString!"builtin",
		(in SpecSigAst[] sigs) =>
			jsonList!SpecSigAst(alloc, sigs, (in SpecSigAst sig) =>
				jsonOfSpecSig(alloc, ctx, sig)));

Json jsonOfSpecSig(ref Alloc alloc, scope ref Ctx ctx, in SpecSigAst a) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRange(alloc, ctx, a.range)),
		field!"doc"(jsonString(alloc, a.docComment)),
		field!"name"(a.name),
		field!"return-type"(jsonOfTypeAst(alloc, ctx, a.returnType)),
		field!"params"(jsonOfParamsAst(alloc, ctx, a.params))]);

Json jsonOfStructAliasAst(ref Alloc alloc, scope ref Ctx ctx, in StructAliasAst a) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRange(alloc, ctx, a.range)),
		optionalStringField!"doc"(alloc, a.docComment),
		field!"visibility"(stringOfEnum(a.visibility)),
		field!"name"(jsonOfNameAndRange(alloc, ctx, a.name)),
		maybeTypeParams(alloc, ctx, a.typeParams),
		field!"target"(jsonOfTypeAst(alloc, ctx, a.target))]);

Json jsonOfEnumOrFlags(
	ref Alloc alloc,
	scope ref Ctx ctx,
	string name,
	in Opt!(TypeAst*) typeArg,
	in StructDeclAst.Body.Enum.Member[] members,
) =>
	jsonObject(alloc, [
		kindField(name),
		optionalField!("backing-type", TypeAst*)(typeArg, (in TypeAst* x) =>
			jsonOfTypeAst(alloc, ctx, *x)),
		field!"members"(jsonList!(StructDeclAst.Body.Enum.Member)(
			alloc, members, (in StructDeclAst.Body.Enum.Member x) =>
				jsonOfEnumMember(alloc, ctx, x)))]);

Json jsonOfEnumMember(ref Alloc alloc, scope ref Ctx ctx, in StructDeclAst.Body.Enum.Member a) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRange(alloc, ctx, a.range)),
		field!"name"(a.name),
		optionalField!("value", LiteralIntOrNat)(a.value, (in LiteralIntOrNat x) =>
			jsonOfLiteralIntOrNat(alloc, x))]);

Json jsonOfLiteralFloatAst(ref Alloc alloc, in LiteralFloatAst a) =>
	jsonOfLiteral!"float"(alloc, a.value, a.overflow);

Json jsonOfLiteralIntAst(ref Alloc alloc, in LiteralIntAst a) =>
	jsonOfLiteral!"int"(alloc, a.value, a.overflow);

Json jsonOfLiteralNatAst(ref Alloc alloc, in LiteralNatAst a) =>
	jsonOfLiteral!"nat"(alloc, a.value, a.overflow);

Json jsonOfLiteralStringAst(ref Alloc alloc, in LiteralStringAst a) =>
	jsonOfLiteral!"string"(alloc, jsonString(alloc, a.value), false);

Json jsonOfLiteral(string typeName, T)(ref Alloc alloc, T value, bool overflow) =>
	jsonObject(alloc, [
		kindField!typeName,
		field!"value"(value),
		optionalFlagField!"overflow"(overflow)]);

Json jsonOfLiteralIntOrNat(ref Alloc alloc, in LiteralIntOrNat a) =>
	a.matchIn!Json(
		(in LiteralIntAst x) =>
			jsonOfLiteralIntAst(alloc, x),
		(in LiteralNatAst x) =>
			jsonOfLiteralNatAst(alloc, x));

Json jsonOfField(ref Alloc alloc, scope ref Ctx ctx, in StructDeclAst.Body.Record.Field a) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRange(alloc, ctx, a.range)),
		field!"visibility"(stringOfEnum(a.visibility)),
		field!"name"(jsonOfNameAndRange(alloc, ctx, a.name)),
		optionalField!("mutability", FieldMutabilityAst)(a.mutability, (in FieldMutabilityAst x) =>
			jsonObject(alloc, [
				field!"pos"(x.pos),
				field!"kind"(stringOfFieldMutabilityAstKind(x.kind))])),
		field!"type"(jsonOfTypeAst(alloc, ctx, a.type))]);

Json jsonOfRecordAst(ref Alloc alloc, scope ref Ctx ctx, in StructDeclAst.Body.Record a) =>
	jsonObject(alloc, [
		kindField!"record",
		field!"fields"(jsonList!(StructDeclAst.Body.Record.Field)(
			alloc,
			a.fields,
			(in StructDeclAst.Body.Record.Field x) =>
				jsonOfField(alloc, ctx, x)))]);

Json jsonOfUnion(ref Alloc alloc, scope ref Ctx ctx, in StructDeclAst.Body.Union a) =>
	jsonObject(alloc, [
		kindField!"union",
		field!"members"(jsonList!(StructDeclAst.Body.Union.Member)(
			alloc,
			a.members,
			(in StructDeclAst.Body.Union.Member x) =>
				jsonObject(alloc, [
					field!"name"(x.name),
					optionalField!("type", TypeAst)(x.type, (in TypeAst t) =>
						jsonOfTypeAst(alloc, ctx, t))])))]);

Json jsonOfStructBodyAst(ref Alloc alloc, scope ref Ctx ctx, in StructDeclAst.Body a) =>
	a.matchIn!Json(
		(in StructDeclAst.Body.Builtin) =>
			jsonString!"builtin" ,
		(in StructDeclAst.Body.Enum e) =>
			jsonOfEnumOrFlags(alloc, ctx, "enum", e.typeArg, e.members),
		(in StructDeclAst.Body.Extern) =>
			jsonString!"extern",
		(in StructDeclAst.Body.Flags e) =>
			jsonOfEnumOrFlags(alloc, ctx, "flags", e.typeArg, e.members),
		(in StructDeclAst.Body.Record a) =>
			jsonOfRecordAst(alloc, ctx, a),
		(in StructDeclAst.Body.Union a) =>
			jsonOfUnion(alloc, ctx, a));

Json jsonOfStructDeclAst(ref Alloc alloc, scope ref Ctx ctx, in StructDeclAst a) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRange(alloc, ctx, a.range)),
		field!"doc"(jsonString(alloc, a.docComment)),
		field!"visibility"(stringOfEnum(a.visibility)),
		maybeTypeParams(alloc, ctx, a.typeParams),
		optionalArrayField!("modifiers", ModifierAst)(alloc, a.modifiers, (in ModifierAst x) =>
			jsonOfModifierAst(alloc, x)),
		field!"body"(jsonOfStructBodyAst(alloc, ctx, a.body_))]);

Json.ObjectField maybeTypeParams(ref Alloc alloc, scope ref Ctx ctx, in NameAndRange[] typeParams) =>
	optionalArrayField!("type-params", NameAndRange)(alloc, typeParams, (in NameAndRange x) =>
		jsonOfNameAndRange(alloc, ctx, x));

Json jsonOfModifierAst(ref Alloc alloc, in ModifierAst a) =>
	jsonObject(alloc, [
		field!"pos"(a.pos),
		field!"modifier"(symOfModifierKind(a.kind))]);

Json jsonOfFunDeclAst(ref Alloc alloc, scope ref Ctx ctx, in FunDeclAst a) =>
	jsonObject(alloc, [
		optionalStringField!"doc"(alloc, a.docComment),
		field!"visibility"(stringOfEnum(a.visibility)),
		field!"range"(jsonOfRange(alloc, ctx, a.range)),
		field!"name"(jsonOfNameAndRange(alloc, ctx, a.name)),
		maybeTypeParams(alloc, ctx, a.typeParams),
		field!"return"(jsonOfTypeAst(alloc, ctx, a.returnType)),
		field!"params"(jsonOfParamsAst(alloc, ctx, a.params)),
		optionalArrayField!("modifiers", FunModifierAst)(alloc, a.modifiers, (in FunModifierAst s) =>
			jsonOfFunModifierAst(alloc, ctx, s)),
		optionalField!("body", ExprAst)(a.body_, (in ExprAst body_) => jsonOfExprAst(alloc, ctx, body_))]);

Json jsonOfParamsAst(ref Alloc alloc, scope ref Ctx ctx, in ParamsAst a) =>
	a.matchIn!Json(
		(in DestructureAst[] params) =>
			jsonOfDestructureAsts(alloc, ctx, params),
		(in ParamsAst.Varargs v) =>
			jsonObject(alloc, [
				kindField!"varargs",
				field!"param"(jsonOfDestructureAst(alloc, ctx, v.param))]));

Json jsonOfFunModifierAst(ref Alloc alloc, scope ref Ctx ctx, in FunModifierAst a) =>
	a.matchIn!Json(
		(in FunModifierAst.Special x) =>
			jsonObject(alloc, [
				kindField!"special",
				field!"pos"(x.pos),
				field!"flag"(stringOfSpecialFlag(x.flag))]),
		(in FunModifierAst.Extern x) =>
			jsonObject(alloc, [
				kindField!"extern",
				field!"loeft"(jsonOfTypeAst(alloc, ctx, *x.left)),
				field!"extern-pos"(x.externPos)]),
		(in TypeAst x) =>
			jsonOfTypeAst(alloc, ctx, x));

Json jsonOfTypeAst(ref Alloc alloc, scope ref Ctx ctx, in TypeAst a) =>
	a.matchIn!Json(
		(in TypeAst.Bogus x) =>
			jsonObject(alloc, [
				kindField!"bogus",
				field!"range"(jsonOfRange(alloc, ctx, x.range))]),
		(in TypeAst.Fun x) =>
			jsonObject(alloc, [
				kindField!"fun",
				field!"range"(jsonOfRange(alloc, ctx, x.range)),
				field!"fun-kind"(stringOfEnum(x.kind)),
				field!"return-type"(jsonOfTypeAst(alloc, ctx, x.returnType)),
				field!"param-types"(jsonOfTypeAsts(alloc, ctx, x.paramTypes))]),
		(in TypeAst.Map x) =>
			jsonObject(alloc, [
				kindField!"map",
				field!"key"(jsonOfTypeAst(alloc, ctx, x.v)),
				field!"value"(jsonOfTypeAst(alloc, ctx, x.k))]),
		(in NameAndRange x) =>
			jsonOfNameAndRange(alloc, ctx, x),
		(in TypeAst.SuffixName x) =>
			jsonObject(alloc, [
				kindField!"suffix",
				field!"left"(jsonOfTypeAst(alloc, ctx, x.left)),
				field!"name"(jsonOfNameAndRange(alloc, ctx, x.name))]),
		(in TypeAst.SuffixSpecial x) =>
			jsonObject(alloc, [
				kindField!"suffix-special",
				field!"left"(jsonOfTypeAst(alloc, ctx, x.left)),
				field!"suffix-pos"(x.suffixPos),
				field!"suffix"(symForTypeAstSuffix(x.kind))]),
		(in TypeAst.Tuple x) =>
			jsonObject(alloc, [
				kindField!"tuple",
				field!"range"(jsonOfRange(alloc, ctx, x.range)),
				field!"members"(jsonOfTypeAsts(alloc, ctx, x.members))]));

Json jsonOfTypeAsts(ref Alloc alloc, scope ref Ctx ctx, in TypeAst[] a) =>
	jsonList!TypeAst(alloc, a, (in TypeAst x) =>
		jsonOfTypeAst(alloc, ctx, x));

Json jsonOfDestructureAsts(ref Alloc alloc, scope ref Ctx ctx, in DestructureAst[] a) =>
	jsonList!DestructureAst(alloc, a, (in DestructureAst x) =>
		jsonOfDestructureAst(alloc, ctx, x));

Json jsonOfDestructureAst(ref Alloc alloc, scope ref Ctx ctx, in DestructureAst a) =>
	a.matchIn!Json(
		(in DestructureAst.Single x) =>
			jsonObject(alloc, [
				kindField!"single",
				field!"name"(jsonOfNameAndRange(alloc, ctx, x.name)),
				optionalField!("mut", Pos)(x.mut, (in Pos y) => jsonInt(y)),
				optionalField!("type", TypeAst*)(x.type, (in TypeAst* t) =>
					jsonOfTypeAst(alloc, ctx, *t))]),
		(in DestructureAst.Void x) =>
			jsonObject(alloc, [
				kindField!"void",
				field!"pos"(x.pos)]),
		(in DestructureAst[] parts) =>
			jsonList!DestructureAst(alloc, parts, (in DestructureAst part) =>
				jsonOfDestructureAst(alloc, ctx, part)));

Json jsonOfExprAst(ref Alloc alloc, scope ref Ctx ctx, in ExprAst ast) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRange(alloc, ctx, ast.range)),
		field!"kind"(jsonOfExprAstKind(alloc, ctx, ast.kind))]);

Json jsonOfNameAndRange(ref Alloc alloc, scope ref Ctx ctx, in NameAndRange a) =>
	jsonObject(alloc, [
		field!"start"(jsonOfPosWithinFile(alloc, ctx.lineAndColumnGetter, a.start, PosKind.startOfRange)),
		field!"name"(a.name)]);

Json jsonOfExprAstKind(ref Alloc alloc, scope ref Ctx ctx, in ExprAstKind ast) =>
	ast.matchIn!Json(
		(in ArrowAccessAst e) =>
			jsonObject(alloc, [
				kindField!"arrow-access",
				field!"left"(jsonOfExprAst(alloc, ctx, *e.left)),
				field!"name"(jsonOfNameAndRange(alloc, ctx, e.name))]),
		(in AssertOrForbidAst e) =>
			jsonObject(alloc, [
				kindField(stringOfEnum(e.kind)),
				field!"condition"(jsonOfExprAst(alloc, ctx, e.condition)),
				optionalField!("thrown", ExprAst)(e.thrown, (in ExprAst thrown) =>
					jsonOfExprAst(alloc, ctx, thrown))]),
		(in AssignmentAst e) =>
			jsonObject(alloc, [
				kindField!"assign",
				field!"left"(jsonOfExprAst(alloc, ctx, e.left)),
				field!"right"(jsonOfExprAst(alloc, ctx, e.right))]),
		(in AssignmentCallAst e) =>
			jsonObject(alloc, [
				kindField!"assign-call",
				field!"left"(jsonOfExprAst(alloc, ctx, e.left)),
				field!"fun-name"(jsonOfNameAndRange(alloc, ctx, e.funName)),
				field!"right"(jsonOfExprAst(alloc, ctx, e.right))]),
		(in BogusAst _) =>
			jsonObject(alloc, [kindField!"bogus"]),
		(in CallAst e) =>
			jsonObject(alloc, [
				kindField!"call",
				field!"style"(stringOfEnum(e.style)),
				field!"fun-name"(jsonOfNameAndRange(alloc, ctx, e.funName)),
				optionalField!("type-arg", TypeAst*)(e.typeArg, (in TypeAst* x) =>
					jsonOfTypeAst(alloc, ctx, *x)),
				field!"args"(jsonList!ExprAst(alloc, e.args, (in ExprAst x) =>
					jsonOfExprAst(alloc, ctx, x)))]),
		(in EmptyAst e) =>
			jsonObject(alloc, [kindField!"empty"]),
		(in ForAst x) =>
			jsonObject(alloc, [
				kindField!"for",
				field!"param"(jsonOfDestructureAst(alloc, ctx, x.param)),
				field!"collection"(jsonOfExprAst(alloc, ctx, x.collection)),
				field!"body"(jsonOfExprAst(alloc, ctx, x.body_)),
				field!"else"(jsonOfExprAst(alloc, ctx, x.else_))]),
		(in IdentifierAst a) =>
			jsonObject(alloc, [
				kindField!"identifier",
				field!"name"(a.name)]),
		(in IfAst e) =>
			jsonObject(alloc, [
				kindField!"if",
				field!"condition"(jsonOfExprAst(alloc, ctx, e.cond)),
				field!"then"(jsonOfExprAst(alloc, ctx, e.then)),
				field!"else"(jsonOfExprAst(alloc, ctx, e.else_))]),
		(in IfOptionAst x) =>
			jsonObject(alloc, [
				kindField!"if-option",
				field!"destructure"(jsonOfDestructureAst(alloc, ctx, x.destructure)),
				field!"option"(jsonOfExprAst(alloc, ctx, x.option)),
				field!"then"(jsonOfExprAst(alloc, ctx, x.then)),
				field!"else"(jsonOfExprAst(alloc, ctx, x.else_))]),
		(in InterpolatedAst x) =>
			jsonObject(alloc, [
				kindField!"interpolated",
				field!"parts"(jsonList!InterpolatedPart(alloc, x.parts, (in InterpolatedPart part) =>
					jsonOfInterpolatedPart(alloc, ctx, part)))]),
		(in LambdaAst x) =>
			jsonObject(alloc, [
				kindField!"lambda",
				field!"param"(jsonOfDestructureAst(alloc, ctx, x.param)),
				field!"body"(jsonOfExprAst(alloc, ctx, x.body_))]),
		(in LetAst a) =>
			jsonObject(alloc, [
				kindField!"let",
				field!"destructure"(jsonOfDestructureAst(alloc, ctx, a.destructure)),
				field!"value"(jsonOfExprAst(alloc, ctx, a.value)),
				field!"then"(jsonOfExprAst(alloc, ctx, a.then))]),
		(in LiteralFloatAst a) =>
			jsonOfLiteralFloatAst(alloc, a),
		(in LiteralIntAst a) =>
			jsonOfLiteralIntAst(alloc, a),
		(in LiteralNatAst a) =>
			jsonOfLiteralNatAst(alloc, a),
		(in LiteralStringAst a) =>
			jsonOfLiteralStringAst(alloc, a),
		(in LoopAst a) =>
			jsonObject(alloc, [
				kindField!"loop",
				field!"body"(jsonOfExprAst(alloc, ctx, a.body_))]),
		(in LoopBreakAst e) =>
			jsonObject(alloc, [
				kindField!"break",
				field!"value"(jsonOfExprAst(alloc, ctx, e.value))]),
		(in LoopContinueAst _) =>
			jsonObject(alloc, [kindField!"continue"]),
		(in LoopUntilAst e) =>
			jsonObject(alloc, [
				kindField!"until",
				field!"condition"(jsonOfExprAst(alloc, ctx, e.condition)),
				field!"body"(jsonOfExprAst(alloc, ctx, e.body_))]),
		(in LoopWhileAst e) =>
			jsonObject(alloc, [
				kindField!"while",
				field!"condition"(jsonOfExprAst(alloc, ctx, e.condition)),
				field!"body"(jsonOfExprAst(alloc, ctx, e.body_))]),
		(in MatchAst x) =>
			jsonObject(alloc, [
				kindField!"match",
				field!"matched"(jsonOfExprAst(alloc, ctx, x.matched)),
				field!"cases"(jsonList!(MatchAst.CaseAst)(alloc, x.cases, (in MatchAst.CaseAst case_) =>
					jsonObject(alloc, [
						field!"range"(jsonOfRange(alloc, ctx, case_.range)),
						field!"member-name"(case_.memberName),
						optionalField!("destructure", DestructureAst)(case_.destructure, (in DestructureAst x) =>
							jsonOfDestructureAst(alloc, ctx, x)),
						field!"then"(jsonOfExprAst(alloc, ctx, case_.then))])))]),
		(in ParenthesizedAst x) =>
			jsonObject(alloc, [kindField!"paren", field!"inner"(jsonOfExprAst(alloc, ctx, x.inner))]),
		(in PtrAst a) =>
			jsonObject(alloc, [
				kindField!"pointer-to",
				field!"pointee"(jsonOfExprAst(alloc, ctx, a.inner))]),
		(in SeqAst a) =>
			jsonObject(alloc, [
				kindField!"seq",
				field!"first"(jsonOfExprAst(alloc, ctx, a.first)),
				field!"then"(jsonOfExprAst(alloc, ctx, a.then))]),
		(in ThenAst x) =>
			jsonObject(alloc, [
				kindField!"then",
				field!"left"(jsonOfDestructureAst(alloc, ctx, x.left)),
				field!"fut-expr"(jsonOfExprAst(alloc, ctx, x.futExpr)),
				field!"then"(jsonOfExprAst(alloc, ctx, x.then))]),
		(in ThrowAst x) =>
			jsonObject(alloc, [
				kindField!"throw",
				field!"thrown"(jsonOfExprAst(alloc, ctx, x.thrown))]),
		(in TrustedAst x) =>
			jsonObject(alloc, [
				kindField!"trusted",
				field!"inner"(jsonOfExprAst(alloc, ctx, x.inner))]),
		(in TypedAst x) =>
			jsonObject(alloc, [
				kindField!"typed",
				field!"expr"(jsonOfExprAst(alloc, ctx, x.expr)),
				field!"type"(jsonOfTypeAst(alloc, ctx, x.type))]),
		(in UnlessAst x) =>
			jsonObject(alloc, [
				kindField!"unless",
				field!"conditoin"(jsonOfExprAst(alloc, ctx, x.cond)),
				field!"body"(jsonOfExprAst(alloc, ctx, x.body_))]),
		(in WithAst x) =>
			jsonObject(alloc, [
				kindField!"with",
				field!"param"(jsonOfDestructureAst(alloc, ctx, x.param)),
				field!"arg"(jsonOfExprAst(alloc, ctx, x.arg)),
				field!"body"(jsonOfExprAst(alloc, ctx, x.body_))]));

Json jsonOfInterpolatedPart(ref Alloc alloc, scope ref Ctx ctx, in InterpolatedPart a) =>
	a.matchIn!Json(
		(in string x) => jsonString(alloc, x),
		(in ExprAst x) => jsonOfExprAst(alloc, ctx, x));
