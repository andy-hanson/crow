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
	PtrAst,
	SeqAst,
	SpecBodyAst,
	SpecDeclAst,
	SpecSigAst,
	StructAliasAst,
	StructDeclAst,
	symForTypeAstSuffix,
	symOfModifierKind,
	symOfSpecialFlag,
	ThenAst,
	ThrowAst,
	TrustedAst,
	TypeAst,
	TypedAst,
	UnlessAst,
	WithAst;
import model.model : symOfAssertOrForbidKind, symOfFieldMutability, symOfFunKind, symOfImportFileType, symOfVisibility;
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
	jsonList,
	jsonString,
	kindField;
import util.opt : Opt;
import util.sourceRange : jsonOfRangeWithinFile;
import util.sym : Sym, sym;
import util.union_ : Union;
import util.uri : pathOrRelPathToJson, AllUris;

Json jsonOfAst(ref Alloc alloc, in AllUris allUris, in FileAst ast) =>
	jsonObject(alloc, [
		optionalStringField!"doc"(alloc, ast.docComment),
		optionalField!("imports", ImportsOrExportsAst)(ast.imports, (in ImportsOrExportsAst x) =>
			jsonOfImportsOrExports(alloc, allUris, x)),
		optionalField!("exports", ImportsOrExportsAst)(ast.exports, (in ImportsOrExportsAst x) =>
			jsonOfImportsOrExports(alloc, allUris, x)),
		optionalArrayField!("specs", SpecDeclAst)(alloc, ast.specs, (in SpecDeclAst a) =>
			jsonOfSpecDeclAst(alloc, a)),
		optionalArrayField!("aliases", StructAliasAst)(alloc, ast.structAliases, (in StructAliasAst a) =>
			jsonOfStructAliasAst(alloc, a)),
		optionalArrayField!("structs", StructDeclAst)(alloc, ast.structs, (in StructDeclAst a) =>
			jsonOfStructDeclAst(alloc, a)),
		optionalArrayField!("funs", FunDeclAst)(alloc, ast.funs, (in FunDeclAst a) =>
			jsonOfFunDeclAst(alloc, a))]);

private:

Json jsonOfImportsOrExports(ref Alloc alloc, in AllUris allUris, in ImportsOrExportsAst a) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRangeWithinFile(alloc, a.range)),
		field!"imports"(jsonList!ImportOrExportAst(alloc, a.paths, (in ImportOrExportAst a) =>
			jsonOfImportOrExportAst(alloc, allUris, a)))]);

Json jsonOfImportOrExportAst(ref Alloc alloc, in AllUris allUris, in ImportOrExportAst a) =>
	jsonObject(alloc, [
		field!"path"(pathOrRelPathToJson(alloc, allUris, a.path)),
		field!"import-kind"(a.kind.matchIn!Json(
			(in ImportOrExportAstKind.ModuleWhole) =>
				jsonString!"whole",
			(in Sym[] names) =>
				jsonObject(alloc, [field!"names"(jsonList!Sym(alloc, names, (in Sym name) => jsonString(name)))]),
			(in ImportOrExportAstKind.File f) =>
				jsonObject(alloc, [
					field!"name"(f.name),
					field!"file-type"(symOfImportFileType(f.type))])))]);

Json jsonOfSpecDeclAst(ref Alloc alloc, in SpecDeclAst a) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRangeWithinFile(alloc, a.range)),
		field!"comment"(jsonString(alloc, a.docComment)),
		field!"visibility"(symOfVisibility(a.visibility)),
		field!"name"(a.name),
		field!"parents"(jsonOfTypeAsts(alloc, a.parents)),
		maybeTypeParams(alloc, a.typeParams),
		field!"body"(jsonOfSpecBodyAst(alloc, a.body_))]);

Json jsonOfSpecBodyAst(ref Alloc alloc, in SpecBodyAst a) =>
	a.matchIn!Json(
		(in SpecBodyAst.Builtin) =>
			jsonString!"builtin",
		(in SpecSigAst[] sigs) =>
			jsonList!SpecSigAst(alloc, sigs, (in SpecSigAst sig) =>
				jsonOfSpecSig(alloc, sig)));

Json jsonOfSpecSig(ref Alloc alloc, in SpecSigAst a) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRangeWithinFile(alloc, a.range)),
		field!"doc"(jsonString(alloc, a.docComment)),
		field!"name"(a.name),
		field!"return-type"(jsonOfTypeAst(alloc, a.returnType)),
		field!"params"(jsonOfParamsAst(alloc, a.params))]);

Json jsonOfStructAliasAst(ref Alloc alloc, in StructAliasAst a) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRangeWithinFile(alloc, a.range)),
		optionalStringField!"doc"(alloc, a.docComment),
		field!"visibility"(symOfVisibility(a.visibility)),
		field!"name"(a.name),
		maybeTypeParams(alloc, a.typeParams),
		field!"target"(jsonOfTypeAst(alloc, a.target))]);

Json jsonOfEnumOrFlags(
	ref Alloc alloc,
	Sym name,
	in Opt!(TypeAst*) typeArg,
	in StructDeclAst.Body.Enum.Member[] members,
) =>
	jsonObject(alloc, [
		kindField(name),
		optionalField!("backing-type", TypeAst*)(typeArg, (in TypeAst* x) =>
			jsonOfTypeAst(alloc, *x)),
		field!"members"(jsonList!(StructDeclAst.Body.Enum.Member)(
			alloc, members, (in StructDeclAst.Body.Enum.Member x) =>
				jsonOfEnumMember(alloc, x)))]);

Json jsonOfEnumMember(ref Alloc alloc, in StructDeclAst.Body.Enum.Member a) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRangeWithinFile(alloc, a.range)),
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

Json jsonOfField(ref Alloc alloc, in StructDeclAst.Body.Record.Field a) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRangeWithinFile(alloc, a.range)),
		field!"mutability"(symOfFieldMutability(a.mutability)),
		field!"name"(a.name),
		field!"type"(jsonOfTypeAst(alloc, a.type))]);

Json jsonOfRecordAst(ref Alloc alloc, in StructDeclAst.Body.Record a) =>
	jsonObject(alloc, [
		kindField!"record",
		field!"fields"(jsonList!(StructDeclAst.Body.Record.Field)(
			alloc,
			a.fields,
			(in StructDeclAst.Body.Record.Field x) =>
				jsonOfField(alloc, x)))]);

Json jsonOfUnion(ref Alloc alloc, in StructDeclAst.Body.Union a) =>
	jsonObject(alloc, [
		kindField!"union",
		field!"members"(jsonList!(StructDeclAst.Body.Union.Member)(
			alloc,
			a.members,
			(in StructDeclAst.Body.Union.Member x) =>
				jsonObject(alloc, [
					field!"name"(x.name),
					optionalField!("type", TypeAst)(x.type, (in TypeAst t) =>
						jsonOfTypeAst(alloc, t))])))]);

Json jsonOfStructBodyAst(ref Alloc alloc, in StructDeclAst.Body a) =>
	a.matchIn!Json(
		(in StructDeclAst.Body.Builtin) =>
			jsonString!"builtin" ,
		(in StructDeclAst.Body.Enum e) =>
			jsonOfEnumOrFlags(alloc, sym!"enum", e.typeArg, e.members),
		(in StructDeclAst.Body.Extern) =>
			jsonString!"extern",
		(in StructDeclAst.Body.Flags e) =>
			jsonOfEnumOrFlags(alloc, sym!"flags", e.typeArg, e.members),
		(in StructDeclAst.Body.Record a) =>
			jsonOfRecordAst(alloc, a),
		(in StructDeclAst.Body.Union a) =>
			jsonOfUnion(alloc, a));

Json jsonOfStructDeclAst(ref Alloc alloc, in StructDeclAst a) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRangeWithinFile(alloc, a.range)),
		field!"doc"(jsonString(alloc, a.docComment)),
		field!"visibility"(symOfVisibility(a.visibility)),
		maybeTypeParams(alloc, a.typeParams),
		optionalArrayField!("modifiers", ModifierAst)(alloc, a.modifiers, (in ModifierAst x) =>
			jsonOfModifierAst(alloc, x)),
		field!"body"(jsonOfStructBodyAst(alloc, a.body_))]);

Json.ObjectField maybeTypeParams(ref Alloc alloc, in NameAndRange[] typeParams) =>
	optionalArrayField!("type-params", NameAndRange)(alloc, typeParams, (in NameAndRange x) =>
		jsonOfNameAndRange(alloc, x));

Json jsonOfModifierAst(ref Alloc alloc, in ModifierAst a) =>
	jsonObject(alloc, [
		field!"pos"(a.pos),
		field!"modifier"(symOfModifierKind(a.kind))]);

Json jsonOfFunDeclAst(ref Alloc alloc, in FunDeclAst a) =>
	jsonObject(alloc, [
		optionalStringField!"doc"(alloc, a.docComment),
		field!"visibility"(symOfVisibility(a.visibility)),
		field!"range"(jsonOfRangeWithinFile(alloc, a.range)),
		field!"name"(a.name),
		maybeTypeParams(alloc, a.typeParams),
		field!"return"(jsonOfTypeAst(alloc, a.returnType)),
		field!"params"(jsonOfParamsAst(alloc, a.params)),
		optionalArrayField!("modifiers", FunModifierAst)(alloc, a.modifiers, (in FunModifierAst s) =>
			jsonOfFunModifierAst(alloc, s)),
		optionalField!("body", ExprAst)(a.body_, (in ExprAst body_) => jsonOfExprAst(alloc, body_))]);

Json jsonOfParamsAst(ref Alloc alloc, in ParamsAst a) =>
	a.matchIn!Json(
		(in DestructureAst[] params) =>
			jsonOfDestructureAsts(alloc, params),
		(in ParamsAst.Varargs v) =>
			jsonObject(alloc, [
				kindField!"varargs",
				field!"param"(jsonOfDestructureAst(alloc, v.param))]));

Json jsonOfFunModifierAst(ref Alloc alloc, in FunModifierAst a) =>
	a.matchIn!Json(
		(in FunModifierAst.Special x) =>
			jsonObject(alloc, [
				kindField!"special",
				field!"pos"(x.pos),
				field!"flag"(symOfSpecialFlag(x.flag))]),
		(in FunModifierAst.Extern x) =>
			jsonObject(alloc, [
				kindField!"extern",
				field!"loeft"(jsonOfTypeAst(alloc, *x.left)),
				field!"extern-pos"(x.externPos)]),
		(in TypeAst x) =>
			jsonOfTypeAst(alloc, x));

Json jsonOfTypeAst(ref Alloc alloc, in TypeAst a) =>
	a.matchIn!Json(
		(in TypeAst.Bogus x) =>
			jsonObject(alloc, [
				kindField!"bogus",
				field!"range"(jsonOfRangeWithinFile(alloc, x.range))]),
		(in TypeAst.Fun x) =>
			jsonObject(alloc, [
				kindField!"fun",
				field!"range"(jsonOfRangeWithinFile(alloc, x.range)),
				field!"fun-kind"(symOfFunKind(x.kind)),
				field!"return-type"(jsonOfTypeAst(alloc, x.returnType)),
				field!"param-types"(jsonOfTypeAsts(alloc, x.paramTypes))]),
		(in TypeAst.Map x) =>
			jsonObject(alloc, [
				kindField!"map",
				field!"key"(jsonOfTypeAst(alloc, x.v)),
				field!"value"(jsonOfTypeAst(alloc, x.k))]),
		(in NameAndRange x) =>
			jsonOfNameAndRange(alloc, x),
		(in TypeAst.SuffixName x) =>
			jsonObject(alloc, [
				kindField!"suffix",
				field!"left"(jsonOfTypeAst(alloc, x.left)),
				field!"name"(jsonOfNameAndRange(alloc, x.name))]),
		(in TypeAst.SuffixSpecial x) =>
			jsonObject(alloc, [
				kindField!"suffix-special",
				field!"left"(jsonOfTypeAst(alloc, x.left)),
				field!"suffix-pos"(x.suffixPos),
				field!"suffix"(symForTypeAstSuffix(x.kind))]),
		(in TypeAst.Tuple x) =>
			jsonObject(alloc, [
				kindField!"tuple",
				field!"range"(jsonOfRangeWithinFile(alloc, x.range)),
				field!"members"(jsonOfTypeAsts(alloc, x.members))]));

Json jsonOfTypeAsts(ref Alloc alloc, in TypeAst[] a) =>
	jsonList!TypeAst(alloc, a, (in TypeAst x) =>
		jsonOfTypeAst(alloc, x));

Json jsonOfDestructureAsts(ref Alloc alloc, in DestructureAst[] a) =>
	jsonList!DestructureAst(alloc, a, (in DestructureAst x) =>
		jsonOfDestructureAst(alloc, x));

Json jsonOfDestructureAst(ref Alloc alloc, in DestructureAst a) =>
	a.matchIn!Json(
		(in DestructureAst.Single x) =>
			jsonObject(alloc, [
				kindField!"single",
				field!"name"(jsonOfNameAndRange(alloc, x.name)),
				optionalFlagField!"mut"(x.mut),
				optionalField!("type", TypeAst*)(x.type, (in TypeAst* t) =>
					jsonOfTypeAst(alloc, *t))]),
		(in DestructureAst.Void x) =>
			jsonObject(alloc, [
				kindField!"void",
				field!"pos"(x.pos)]),
		(in DestructureAst[] parts) =>
			jsonList!DestructureAst(alloc, parts, (in DestructureAst part) =>
				jsonOfDestructureAst(alloc, part)));

Json jsonOfExprAst(ref Alloc alloc, in ExprAst ast) =>
	jsonOfExprAstKind(alloc, ast.kind);

Json jsonOfNameAndRange(ref Alloc alloc, in NameAndRange a) =>
	jsonObject(alloc, [
		field!"start"(a.start),
		field!"name"(a.name)]);

Json jsonOfExprAstKind(ref Alloc alloc, in ExprAstKind ast) =>
	ast.matchIn!Json(
		(in ArrowAccessAst e) =>
			jsonObject(alloc, [
				kindField!"arrow-access",
				field!"left"(jsonOfExprAst(alloc, *e.left)),
				field!"name"(jsonOfNameAndRange(alloc, e.name))]),
		(in AssertOrForbidAst e) =>
			jsonObject(alloc, [
				kindField(symOfAssertOrForbidKind(e.kind)),
				field!"condition"(jsonOfExprAst(alloc, e.condition)),
				optionalField!("thrown", ExprAst)(e.thrown, (in ExprAst thrown) =>
					jsonOfExprAst(alloc, thrown))]),
		(in AssignmentAst e) =>
			jsonObject(alloc, [
				kindField!"assign",
				field!"left"(jsonOfExprAst(alloc, e.left)),
				field!"right"(jsonOfExprAst(alloc, e.right))]),
		(in AssignmentCallAst e) =>
			jsonObject(alloc, [
				kindField!"assign-call",
				field!"left"(jsonOfExprAst(alloc, e.left)),
				field!"fun-name"(jsonOfNameAndRange(alloc, e.funName)),
				field!"right"(jsonOfExprAst(alloc, e.right))]),
		(in BogusAst _) =>
			jsonObject(alloc, [kindField!"bogus"]),
		(in CallAst e) =>
			jsonObject(alloc, [
				kindField!"call",
				field!"style"(symOfCallAstStyle(e.style)),
				field!"fun-name"(jsonOfNameAndRange(alloc, e.funName)),
				optionalField!("type-arg", TypeAst*)(e.typeArg, (in TypeAst* x) =>
					jsonOfTypeAst(alloc, *x)),
				field!"args"(jsonList!ExprAst(alloc, e.args, (in ExprAst x) =>
					jsonOfExprAst(alloc, x)))]),
		(in EmptyAst e) =>
			jsonObject(alloc, [kindField!"empty"]),
		(in ForAst x) =>
			jsonObject(alloc, [
				kindField!"for",
				field!"param"(jsonOfDestructureAst(alloc, x.param)),
				field!"collection"(jsonOfExprAst(alloc, x.collection)),
				field!"body"(jsonOfExprAst(alloc, x.body_)),
				field!"else"(jsonOfExprAst(alloc, x.else_))]),
		(in IdentifierAst a) =>
			jsonObject(alloc, [
				kindField!"identifier",
				field!"name"(a.name)]),
		(in IfAst e) =>
			jsonObject(alloc, [
				kindField!"if",
				field!"condition"(jsonOfExprAst(alloc, e.cond)),
				field!"then"(jsonOfExprAst(alloc, e.then)),
				field!"else"(jsonOfExprAst(alloc, e.else_))]),
		(in IfOptionAst x) =>
			jsonObject(alloc, [
				kindField!"if-option",
				field!"destructure"(jsonOfDestructureAst(alloc, x.destructure)),
				field!"option"(jsonOfExprAst(alloc, x.option)),
				field!"then"(jsonOfExprAst(alloc, x.then)),
				field!"else"(jsonOfExprAst(alloc, x.else_))]),
		(in InterpolatedAst x) =>
			jsonObject(alloc, [
				kindField!"interpolated",
				field!"parts"(jsonList!InterpolatedPart(alloc, x.parts, (in InterpolatedPart part) =>
					jsonOfInterpolatedPart(alloc, part)))]),
		(in LambdaAst x) =>
			jsonObject(alloc, [
				kindField!"lambda",
				field!"param"(jsonOfDestructureAst(alloc, x.param)),
				field!"body"(jsonOfExprAst(alloc, x.body_))]),
		(in LetAst a) =>
			jsonObject(alloc, [
				kindField!"let",
				field!"destructure"(jsonOfDestructureAst(alloc, a.destructure)),
				field!"value"(jsonOfExprAst(alloc, a.value)),
				field!"then"(jsonOfExprAst(alloc, a.then))]),
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
				field!"body"(jsonOfExprAst(alloc, a.body_))]),
		(in LoopBreakAst e) =>
			jsonObject(alloc, [
				kindField!"break",
				field!"value"(jsonOfExprAst(alloc, e.value))]),
		(in LoopContinueAst _) =>
			jsonObject(alloc, [kindField!"continue"]),
		(in LoopUntilAst e) =>
			jsonObject(alloc, [
				kindField!"until",
				field!"condition"(jsonOfExprAst(alloc, e.condition)),
				field!"body"(jsonOfExprAst(alloc, e.body_))]),
		(in LoopWhileAst e) =>
			jsonObject(alloc, [
				kindField!"while",
				field!"condition"(jsonOfExprAst(alloc, e.condition)),
				field!"body"(jsonOfExprAst(alloc, e.body_))]),
		(in MatchAst x) =>
			jsonObject(alloc, [
				kindField!"match",
				field!"matched"(jsonOfExprAst(alloc, x.matched)),
				field!"cases"(jsonList!(MatchAst.CaseAst)(alloc, x.cases, (in MatchAst.CaseAst case_) =>
					jsonObject(alloc, [
						field!"range"(jsonOfRangeWithinFile(alloc, case_.range)),
						field!"member-name"(case_.memberName),
						optionalField!("destructure", DestructureAst)(case_.destructure, (in DestructureAst x) =>
							jsonOfDestructureAst(alloc, x)),
						field!"then"(jsonOfExprAst(alloc, case_.then))])))]),
		(in ParenthesizedAst x) =>
			jsonObject(alloc, [kindField!"paren", field!"inner"(jsonOfExprAst(alloc, x.inner))]),
		(in PtrAst a) =>
			jsonObject(alloc, [
				kindField!"pointer-to",
				field!"pointee"(jsonOfExprAst(alloc, a.inner))]),
		(in SeqAst a) =>
			jsonObject(alloc, [
				kindField!"seq",
				field!"first"(jsonOfExprAst(alloc, a.first)),
				field!"then"(jsonOfExprAst(alloc, a.then))]),
		(in ThenAst x) =>
			jsonObject(alloc, [
				kindField!"then",
				field!"left"(jsonOfDestructureAst(alloc, x.left)),
				field!"fut-expr"(jsonOfExprAst(alloc, x.futExpr)),
				field!"then"(jsonOfExprAst(alloc, x.then))]),
		(in ThrowAst x) =>
			jsonObject(alloc, [
				kindField!"throw",
				field!"thrown"(jsonOfExprAst(alloc, x.thrown))]),
		(in TrustedAst x) =>
			jsonObject(alloc, [
				kindField!"trusted",
				field!"inner"(jsonOfExprAst(alloc, x.inner))]),
		(in TypedAst x) =>
			jsonObject(alloc, [
				kindField!"typed",
				field!"expr"(jsonOfExprAst(alloc, x.expr)),
				field!"type"(jsonOfTypeAst(alloc, x.type))]),
		(in UnlessAst x) =>
			jsonObject(alloc, [
				kindField!"unless",
				field!"conditoin"(jsonOfExprAst(alloc, x.cond)),
				field!"body"(jsonOfExprAst(alloc, x.body_))]),
		(in WithAst x) =>
			jsonObject(alloc, [
				kindField!"with",
				field!"param"(jsonOfDestructureAst(alloc, x.param)),
				field!"arg"(jsonOfExprAst(alloc, x.arg)),
				field!"body"(jsonOfExprAst(alloc, x.body_))]));

Json jsonOfInterpolatedPart(ref Alloc alloc, in InterpolatedPart a) =>
	a.matchIn!Json(
		(in string x) => jsonString(alloc, x),
		(in ExprAst x) => jsonOfExprAst(alloc, x));

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
