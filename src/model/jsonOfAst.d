module model.jsonOfAst;

@safe @nogc pure nothrow:

import model.ast :
	ArrowAccessAst,
	AssertOrForbidAst,
	AssignmentAst,
	AssignmentCallAst,
	BogusAst,
	CallAst,
	CallNamedAst,
	CaseAst,
	CaseMemberAst,
	ConditionAst,
	DestructureAst,
	DoAst,
	EmptyAst,
	EnumOrFlagsMemberAst,
	ExprAst,
	ExprAstKind,
	FieldMutabilityAst,
	FileAst,
	ForAst,
	FunDeclAst,
	ModifierAst,
	IdentifierAst,
	IfAst,
	ImportOrExportAst,
	ImportOrExportAstKind,
	ImportsOrExportsAst,
	InterpolatedAst,
	LambdaAst,
	LetAst,
	LiteralFloatAst,
	LiteralIntegral,
	LiteralIntegralAndRange,
	LiteralStringAst,
	LoopAst,
	LoopBreakAst,
	LoopContinueAst,
	LoopWhileOrUntilAst,
	MatchAst,
	MatchElseAst,
	ModifierAst,
	NameAndRange,
	ParamsAst,
	ParenthesizedAst,
	PathOrRelPath,
	PtrAst,
	RecordOrUnionMemberAst,
	SeqAst,
	SharedAst,
	SpecDeclAst,
	SpecSigAst,
	SpecUseAst,
	StructAliasAst,
	StructBodyAst,
	StructDeclAst,
	stringOfModifierKeyword,
	symbolForTypeAstSuffix,
	ThenAst,
	ThrowAst,
	TrustedAst,
	TypeAst,
	TypedAst,
	WithAst;
import model.model : Visibility;
import util.alloc.alloc : Alloc;
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
import util.opt : Opt;
import util.sourceRange : jsonOfLineAndColumn, jsonOfLineAndColumnRange, LineAndColumnGetter, Pos, PosKind, Range;
import util.union_ : Union;
import util.uri : Path, RelPath, stringOfPath;
import util.util : stringOfEnum;

Json jsonOfAst(ref Alloc alloc, in LineAndColumnGetter lineAndColumnGetter, in FileAst ast) {
	Ctx ctx = Ctx(lineAndColumnGetter);
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
	LineAndColumnGetter lineAndColumnGetter;
}

Json jsonOfRange(ref Alloc alloc, in Ctx ctx, in Range a) =>
	jsonOfLineAndColumnRange(alloc, ctx.lineAndColumnGetter[a]);

Json jsonOfImportsOrExports(ref Alloc alloc, in Ctx ctx, in ImportsOrExportsAst a) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRange(alloc, ctx, a.range)),
		field!"imports"(jsonList!ImportOrExportAst(alloc, a.paths, (in ImportOrExportAst a) =>
			jsonOfImportOrExportAst(alloc, ctx, a)))]);

Json jsonOfImportOrExportAst(ref Alloc alloc, in Ctx ctx, in ImportOrExportAst a) =>
	jsonObject(alloc, [
		field!"path"(pathOrRelPathToJson(alloc, a.path)),
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

Json pathOrRelPathToJson(ref Alloc alloc, in PathOrRelPath a) =>
	a.match!Json(
		(Path global) =>
			jsonString(stringOfPath(alloc, global)),
		(RelPath relPath) =>
			jsonObject(alloc, [
				field!"n-parents"(relPath.nParents),
				field!"path"(stringOfPath(alloc, relPath.path))]));

Json jsonOfSpecDeclAst(ref Alloc alloc, in Ctx ctx, in SpecDeclAst a) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRange(alloc, ctx, a.range)),
		field!"comment"(jsonString(alloc, a.docComment)),
		visibilityField(a.visibility_),
		field!"name"(jsonOfNameAndRange(alloc, ctx, a.name)),
		field!"modifiers"(jsonOfModifiers(alloc, ctx, a.modifiers)),
		maybeTypeParams(alloc, ctx, a.typeParams),
		field!"sigs"(jsonList!SpecSigAst(alloc, a.sigs, (in SpecSigAst sig) =>
			jsonOfSpecSig(alloc, ctx, sig)))]);

Json.ObjectField visibilityField(Opt!Visibility a) =>
	optionalField!("visibility", Visibility)(a, (in Visibility x) => jsonString(stringOfEnum(x)));

Json jsonOfSpecSig(ref Alloc alloc, in Ctx ctx, in SpecSigAst a) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRange(alloc, ctx, a.range)),
		field!"doc"(jsonString(alloc, a.docComment)),
		field!"name"(a.name),
		field!"return-type"(jsonOfTypeAst(alloc, ctx, a.returnType)),
		field!"params"(jsonOfParamsAst(alloc, ctx, a.params))]);

Json jsonOfStructAliasAst(ref Alloc alloc, in Ctx ctx, in StructAliasAst a) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRange(alloc, ctx, a.range)),
		optionalStringField!"doc"(alloc, a.docComment),
		visibilityField(a.visibility_),
		field!"name"(jsonOfNameAndRange(alloc, ctx, a.name)),
		maybeTypeParams(alloc, ctx, a.typeParams),
		field!"target"(jsonOfTypeAst(alloc, ctx, a.target))]);

Json jsonOfEnumOrFlags(
	ref Alloc alloc,
	in Ctx ctx,
	string name,
	in Opt!ParamsAst params,
	in EnumOrFlagsMemberAst[] members,
) =>
	jsonObject(alloc, [
		kindField(name),
		optionalField!("params", ParamsAst)(params, (in ParamsAst x) =>
			jsonOfParamsAst(alloc, ctx, x)),
		field!"members"(jsonList!EnumOrFlagsMemberAst(
			alloc, members, (in EnumOrFlagsMemberAst x) =>
				jsonOfEnumOrFlagsMember(alloc, ctx, x)))]);

Json jsonOfEnumOrFlagsMember(ref Alloc alloc, in Ctx ctx, in EnumOrFlagsMemberAst a) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRange(alloc, ctx, a.range)),
		field!"name"(a.name),
		optionalField!("value", LiteralIntegralAndRange)(a.value, (in LiteralIntegralAndRange x) =>
			jsonOfLiteralIntegralAndRange(alloc, ctx, x))]);

Json jsonOfLiteralFloatAst(ref Alloc alloc, in LiteralFloatAst a) =>
	jsonOfLiteral!"float"(alloc, a.value, a.overflow);

Json jsonOfLiteralStringAst(ref Alloc alloc, in LiteralStringAst a) =>
	jsonObject(alloc, [
		kindField!"string",
		field!"value"(jsonString(alloc, a.value))]);

Json jsonOfLiteral(string typeName, T)(ref Alloc alloc, T value, bool overflow) =>
	jsonObject(alloc, [
		kindField!typeName,
		field!"value"(value),
		optionalFlagField!"overflow"(overflow)]);

Json jsonOfLiteralIntegralAndRange(ref Alloc alloc, in Ctx ctx, in LiteralIntegralAndRange a) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRange(alloc, ctx, a.range)),
		field!"literal"(jsonOfLiteralIntegral(alloc, a.literal))]);

Json jsonOfLiteralIntegral(ref Alloc alloc, in LiteralIntegral a) =>
	jsonObject(alloc, [
		field!"is-signed"(a.isSigned),
		field!"overflow"(a.overflow),
		field!"value"(a.value.value)]);

Json jsonOfStructDeclAst(ref Alloc alloc, in Ctx ctx, in StructDeclAst a) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRange(alloc, ctx, a.range)),
		field!"doc"(jsonString(alloc, a.docComment)),
		visibilityField(a.visibility_),
		maybeTypeParams(alloc, ctx, a.typeParams),
		field!"modifiers"(jsonOfModifiers(alloc, ctx, a.modifiers)),
		field!"body"(jsonOfStructBodyAst(alloc, ctx, a.body_))]);

Json jsonOfStructBodyAst(ref Alloc alloc, in Ctx ctx, in StructBodyAst a) =>
	a.matchIn!Json(
		(in StructBodyAst.Builtin) =>
			jsonString!"builtin" ,
		(in StructBodyAst.Enum e) =>
			jsonOfEnumOrFlags(alloc, ctx, "enum", e.params, e.members),
		(in StructBodyAst.Extern) =>
			jsonString!"extern",
		(in StructBodyAst.Flags e) =>
			jsonOfEnumOrFlags(alloc, ctx, "flags", e.params, e.members),
		(in StructBodyAst.Record a) =>
			jsonOfRecordOrUnion(alloc, ctx, "record", a.params, a.fields),
		(in StructBodyAst.Union a) =>
			jsonOfRecordOrUnion(alloc, ctx, "union", a.params, a.members));

Json jsonOfRecordOrUnion(
	ref Alloc alloc,
	in Ctx ctx,
	string kind,
	in Opt!ParamsAst params,
	in RecordOrUnionMemberAst[] members,
) =>
	jsonObject(alloc, [
		kindField(kind),
		optionalField!("params", ParamsAst)(params, (in ParamsAst x) => jsonOfParamsAst(alloc, ctx, x)),
		field!"members"(jsonList!RecordOrUnionMemberAst(alloc, members, (in RecordOrUnionMemberAst x) =>
			jsonOfRecordOrUnionMember(alloc, ctx, x)))]);

Json jsonOfRecordOrUnionMember(ref Alloc alloc, in Ctx ctx, in RecordOrUnionMemberAst a) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRange(alloc, ctx, a.range)),
		visibilityField(a.visibility_),
		field!"name"(jsonOfNameAndRange(alloc, ctx, a.name)),
		optionalField!("mutability", FieldMutabilityAst)(a.mutability, (in FieldMutabilityAst x) =>
			jsonObject(alloc, [
				field!"pos"(x.pos),
				visibilityField(x.visibility_)])),
		optionalField!("type", TypeAst)(a.type, (in TypeAst x) =>
			jsonOfTypeAst(alloc, ctx, x))]);

Json.ObjectField maybeTypeParams(ref Alloc alloc, in Ctx ctx, in NameAndRange[] typeParams) =>
	optionalArrayField!("type-params", NameAndRange)(alloc, typeParams, (in NameAndRange x) =>
		jsonOfNameAndRange(alloc, ctx, x));

Json jsonOfFunDeclAst(ref Alloc alloc, in Ctx ctx, in FunDeclAst a) =>
	jsonObject(alloc, [
		optionalStringField!"doc"(alloc, a.docComment),
		visibilityField(a.visibility_),
		field!"range"(jsonOfRange(alloc, ctx, a.range)),
		field!"name"(jsonOfNameAndRange(alloc, ctx, a.name)),
		maybeTypeParams(alloc, ctx, a.typeParams),
		field!"return"(jsonOfTypeAst(alloc, ctx, a.returnType)),
		field!"params"(jsonOfParamsAst(alloc, ctx, a.params)),
		field!"modifiers"(jsonOfModifiers(alloc, ctx, a.modifiers)),
		field!"body"(jsonOfExprAst(alloc, ctx, a.body_))]);

Json jsonOfParamsAst(ref Alloc alloc, in Ctx ctx, in ParamsAst a) =>
	a.matchIn!Json(
		(in DestructureAst[] params) =>
			jsonOfDestructureAsts(alloc, ctx, params),
		(in ParamsAst.Varargs v) =>
			jsonObject(alloc, [
				kindField!"varargs",
				field!"param"(jsonOfDestructureAst(alloc, ctx, v.param))]));


Json jsonOfModifiers(ref Alloc alloc, in Ctx ctx, in ModifierAst[] modifiers) =>
	jsonList!ModifierAst(alloc, modifiers, (in ModifierAst x) =>
		jsonOfModifierAst(alloc, ctx, x));

Json jsonOfModifierAst(ref Alloc alloc, in Ctx ctx, in ModifierAst a) =>
	a.matchIn!Json(
		(in ModifierAst.Keyword x) =>
			jsonObject(alloc, [
				kindField!"keyword",
				optionalField!("type-arg", TypeAst)(x.typeArg, (in TypeAst type) =>
					jsonOfTypeAst(alloc, ctx, type)),
				field!"keyword-pos"(x.keywordPos),
				field!"keyword"(stringOfModifierKeyword(x.keyword))]),
		(in SpecUseAst x) =>
			jsonOfSpecUseAst(alloc, ctx, x));

Json jsonOfSpecUseAst(ref Alloc alloc, in Ctx ctx, in SpecUseAst a) =>
	jsonObject(alloc, [
		kindField!"spec",
		optionalField!("type-arg", TypeAst)(a.typeArg, (in TypeAst x) =>
			jsonOfTypeAst(alloc, ctx, x)),
		field!"name"(jsonOfNameAndRange(alloc, ctx, a.name))]);

Json jsonOfTypeAst(ref Alloc alloc, in Ctx ctx, in TypeAst a) =>
	a.matchIn!Json(
		(in TypeAst.Bogus x) =>
			jsonObject(alloc, [
				kindField!"bogus",
				field!"range"(jsonOfRange(alloc, ctx, x.range))]),
		(in TypeAst.Fun x) =>
			jsonObject(alloc, [
				kindField!"fun",
				field!"return-type"(jsonOfTypeAst(alloc, ctx, x.returnType)),
				field!"kind"(stringOfEnum(x.kind)),
				field!"param"(jsonOfParamsAst(alloc, ctx, x.params))]),
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
				field!"suffix"(symbolForTypeAstSuffix(x.kind))]),
		(in TypeAst.Tuple x) =>
			jsonObject(alloc, [
				kindField!"tuple",
				field!"range"(jsonOfRange(alloc, ctx, x.range)),
				field!"members"(jsonOfTypeAsts(alloc, ctx, x.members))]));

Json jsonOfTypeAsts(ref Alloc alloc, in Ctx ctx, in TypeAst[] a) =>
	jsonList!TypeAst(alloc, a, (in TypeAst x) =>
		jsonOfTypeAst(alloc, ctx, x));

Json jsonOfDestructureAsts(ref Alloc alloc, in Ctx ctx, in DestructureAst[] a) =>
	jsonList!DestructureAst(alloc, a, (in DestructureAst x) =>
		jsonOfDestructureAst(alloc, ctx, x));

Json jsonOfDestructureAst(ref Alloc alloc, in Ctx ctx, in DestructureAst a) =>
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
				field!"range"(jsonOfRange(alloc, ctx, x.range))]),
		(in DestructureAst[] parts) =>
			jsonList!DestructureAst(alloc, parts, (in DestructureAst part) =>
				jsonOfDestructureAst(alloc, ctx, part)));

Json jsonOfExprAst(ref Alloc alloc, in Ctx ctx, in ExprAst ast) =>
	jsonObject(alloc, [
		field!"range"(jsonOfRange(alloc, ctx, ast.range)),
		field!"kind"(jsonOfExprAstKind(alloc, ctx, ast.kind))]);

Json jsonOfExprAsts(ref Alloc alloc, in Ctx ctx, in ExprAst[] asts) =>
	jsonList!ExprAst(alloc, asts, (in ExprAst x) =>
		jsonOfExprAst(alloc, ctx, x));

Json jsonOfNameAndRange(ref Alloc alloc, in Ctx ctx, in NameAndRange a) =>
	jsonObject(alloc, [
		field!"start"(jsonOfLineAndColumn(alloc, ctx.lineAndColumnGetter[a.start, PosKind.startOfRange])),
		field!"name"(a.name)]);

Json jsonOfExprAstKind(ref Alloc alloc, in Ctx ctx, in ExprAstKind ast) =>
	ast.matchIn!Json(
		(in ArrowAccessAst e) =>
			jsonObject(alloc, [
				kindField!"arrow-access",
				field!"left"(jsonOfExprAst(alloc, ctx, *e.left)),
				field!"name"(jsonOfNameAndRange(alloc, ctx, e.name))]),
		(in AssertOrForbidAst e) =>
			jsonObject(alloc, [
				kindField(e.isForbid ? "forbid" : "assert"),
				field!"condition"(jsonOfConditionAst(alloc, ctx, e.condition)),
				optionalField!("thrown", AssertOrForbidAst.Thrown*)(e.thrown, (in AssertOrForbidAst.Thrown* thrown) =>
					jsonObject(alloc, [
						field!"colon"(thrown.colonPos),
						field!"expr"(jsonOfExprAst(alloc, ctx, thrown.expr))])),
				field!"after"(jsonOfExprAst(alloc, ctx, *e.after))]),
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
				field!"args"(jsonOfExprAsts(alloc, ctx, e.args))]),
		(in CallNamedAst x) =>
			jsonObject(alloc, [
				kindField!"call-named",
				field!"names"(jsonList!NameAndRange(alloc, x.names, (in NameAndRange y) =>
					jsonOfNameAndRange(alloc, ctx, y))),
				field!"args"(jsonOfExprAsts(alloc, ctx, x.args))]),
		(in DoAst x) =>
			jsonObject(alloc, [
				kindField!"do",
				field!"body"(jsonOfExprAst(alloc, ctx, *x.body_))]),
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
		(in IfAst e) @safe =>
			jsonObject(alloc, [
				kindField!"if",
				field!"if-kind"(stringOfEnum(e.kind)),
				field!"condition"(jsonOfConditionAst(alloc, ctx, e.condition)),
				field!"first-keyword"(e.firstKeywordPos),
				optionalField!("first-branch", ExprAst*)(e.firstBranch, (in ExprAst* x) =>
					jsonOfExprAst(alloc, ctx, *x)),
				optionalField!("second-keyword", Pos)(e.secondKeywordPos, (in Pos x) => Json(x)),
				optionalField!("second-branch", ExprAst*)(e.secondBranch, (in ExprAst* x) =>
					jsonOfExprAst(alloc, ctx, *x))]),
		(in InterpolatedAst x) =>
			jsonObject(alloc, [
				kindField!"interpolated",
				field!"parts"(jsonOfExprAsts(alloc, ctx, x.parts))]),
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
		(in LiteralIntegral a) =>
			jsonOfLiteralIntegral(alloc, a),
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
		(in LoopWhileOrUntilAst e) =>
			jsonObject(alloc, [
				kindField(e.isUntil ? "until" : "while"),
				field!"condition"(jsonOfConditionAst(alloc, ctx, e.condition)),
				field!"body"(jsonOfExprAst(alloc, ctx, e.body_)),
				field!"after"(jsonOfExprAst(alloc, ctx, e.after))]),
		(in MatchAst x) =>
			jsonObject(alloc, [
				kindField!"match",
				field!"matched"(jsonOfExprAst(alloc, ctx, *x.matched)),
				field!"cases"(jsonList!CaseAst(alloc, x.cases, (in CaseAst case_) =>
					jsonOfCaseAst(alloc, ctx, case_))),
				optionalField!("else", MatchElseAst*)(x.else_, (in MatchElseAst* y) =>
					jsonObject(alloc, [
						field!"keyword-pos"(y.keywordPos),
						field!"expr"(jsonOfExprAst(alloc, ctx, y.expr))]))]),
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
		(in SharedAst a) =>
			jsonObject(alloc, [
				kindField!"shared",
				field!"inner"(jsonOfExprAst(alloc, ctx, a.inner))]),
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
		(in WithAst x) =>
			jsonObject(alloc, [
				kindField!"with",
				field!"param"(jsonOfDestructureAst(alloc, ctx, x.param)),
				field!"arg"(jsonOfExprAst(alloc, ctx, x.arg)),
				field!"body"(jsonOfExprAst(alloc, ctx, x.body_))]));

Json jsonOfConditionAst(ref Alloc alloc, in Ctx ctx, in ConditionAst a) =>
	a.matchIn!Json(
		(in ExprAst x) =>
			jsonOfExprAst(alloc, ctx, x),
		(in ConditionAst.UnpackOption x) =>
			jsonObject(alloc, [
				field!"destructure"(jsonOfDestructureAst(alloc, ctx, x.destructure)),
				field!"option"(jsonOfExprAst(alloc, ctx, *x.option))]));

Json jsonOfCaseAst(ref Alloc alloc, in Ctx ctx, in CaseAst a) =>
	jsonObject(alloc, [
		field!"keyword-pos"(a.keywordPos),
		field!"member"(jsonOfCaseMemberAst(alloc, ctx, a.member)),
		field!"then"(jsonOfExprAst(alloc, ctx, a.then))]);

Json jsonOfCaseMemberAst(ref Alloc alloc, in Ctx ctx, in CaseMemberAst a) =>
	a.matchIn!Json(
		(in CaseMemberAst.Name x) =>
			jsonObject(alloc, [
				field!"name"(jsonOfNameAndRange(alloc, ctx, x.name)),
				optionalField!("destructure", DestructureAst)(x.destructure, (in DestructureAst y) =>
					jsonOfDestructureAst(alloc, ctx, y))]),
		(in LiteralIntegralAndRange x) =>
			jsonObject(alloc, [
				kindField!"integral",
				field!"value"(jsonOfLiteralIntegralAndRange(alloc, ctx, x))]),
		(in CaseMemberAst.String x) =>
			jsonObject(alloc, [
				kindField!"string",
				field!"range"(jsonOfRange(alloc, ctx, x.range)),
				field!"value"(jsonString(alloc, x.value))]),
		(in CaseMemberAst.Bogus x) =>
			jsonObject(alloc, [
				kindField!"bogus",
				field!"range"(jsonOfRange(alloc, ctx, x.range))]));
