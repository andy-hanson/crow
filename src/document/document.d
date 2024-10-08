module document.document;

@safe @nogc pure nothrow:

import model.ast : NameAndRange;
import model.concreteModel : TypeSize;
import model.model :
	BuiltinType,
	Destructure,
	EnumOrFlagsMember,
	FunBody,
	FunDecl,
	Module,
	moduleAtUri,
	NameReferents,
	Params,
	paramsArray,
	Program,
	Purity,
	RecordField,
	SpecDecl,
	Signature,
	SpecInst,
	StructAlias,
	StructBody,
	StructDecl,
	StructInst,
	StructOrAlias,
	Type,
	TypeParamIndex,
	TypeParams,
	UnionMember,
	VarDecl,
	VariantAndMethodImpls,
	VarKind,
	Visibility;
import util.alloc.alloc : Alloc;
import util.col.array : exists, indexOf, isEmpty, map, mapOp;
import util.col.arrayBuilder : arrayBuilderSort, buildArray, Builder;
import util.comparison : Comparison;
import util.json :
	field,
	Json,
	jsonObject,
	optionalArrayField,
	optionalFlagField,
	optionalField,
	optionalStringField,
	jsonList,
	jsonString,
	kindField;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : compareUriAndRange, UriAndRange;
import util.string : SmallString;
import util.symbol : Symbol, symbol;
import util.uri : stringOfUri, Uri;
import util.util : stringOfEnum;

Json documentModules(ref Alloc alloc, in Program program, in Uri[] moduleUris) =>
	jsonObject(alloc, [
		field!"modules"(jsonList!Uri(alloc, moduleUris, (in Uri x) =>
			documentModule(alloc, program, *moduleAtUri(program, x))))]);

private:

Json documentModule(ref Alloc alloc, in Program program, in Module a) {
	DocExport[] exports = buildArray!DocExport(alloc, (scope ref Builder!DocExport res) {
		// Use 'exports' instead of direct module members so it accounts for re-exports
		foreach (NameReferents referents; a.exports) {
			if (has(referents.structOrAlias) && force(referents.structOrAlias).visibility == Visibility.public_)
				res ~= documentStructOrAlias(alloc, force(referents.structOrAlias));
			if (has(referents.spec) && force(referents.spec).visibility == Visibility.public_)
				res ~= documentSpec(alloc, *force(referents.spec));
			foreach (FunDecl* fun; referents.funs)
				if (fun.visibility == Visibility.public_) {
					if (fun.isGenerated) {
						if (fun.body_.isA!(FunBody.VarGet))
							res ~= documentVarDecl(alloc, *fun.body_.as!(FunBody.VarGet).var);
					} else
						res ~= documentFun(alloc, *fun);
				}
		}
		arrayBuilderSort!(DocExport, compareDocExport)(res);
	});
	return jsonObject(alloc, [
		field!"uri"(stringOfUri(alloc, a.uri)),
		optionalStringField!"doc"(alloc, a.ast.docComment),
		field!"exports"(jsonList!DocExport(alloc, exports, (in DocExport x) => x.json))]);
}

immutable struct DocExport {
	UriAndRange range;
	Json json;
}
Comparison compareDocExport(in DocExport a, in DocExport b) =>
	compareUriAndRange(a.range, b.range);

DocExport documentExport(
	ref Alloc alloc,
	UriAndRange range,
	Symbol name,
	in SmallString docComment,
	in TypeParams typeParams,
	Json value,
) =>
	DocExport(range, jsonObject(alloc, [
		field!"name"(name),
		optionalStringField!"doc"(alloc, docComment),
		optionalArrayField!("type-params", NameAndRange)(alloc, typeParams, (in NameAndRange x) =>
			jsonObject(alloc, [field!"name"(x.name)])),
		field!"value"(value)]));

DocExport documentStructOrAlias(ref Alloc alloc, in StructOrAlias a) =>
	a.matchIn!DocExport(
		(in StructAlias x) =>
			documentStructAlias(alloc, x),
		(in StructDecl x) =>
			documentStructDecl(alloc, x));

DocExport documentStructAlias(ref Alloc alloc, in StructAlias a) =>
	documentExport(alloc, a.range, a.name, a.docComment, a.typeParams, jsonObject(alloc, [
		kindField!"alias",
		field!"target"(documentStructInst(alloc, a.typeParams, *a.target))]));

DocExport documentStructDecl(ref Alloc alloc, in StructDecl a) {
	Json.ObjectField variantsField = optionalArrayField!("variants", VariantAndMethodImpls)(
		alloc, a.variants, (in VariantAndMethodImpls x) =>
			documentStructInst(alloc, a.typeParams, *x.variant));
	return documentExport(alloc, a.range, a.name, a.docComment, a.typeParams, a.body_.matchIn!Json(
		(in StructBody.Bogus) =>
			assert(false),
		(in BuiltinType _) =>
			jsonObject(alloc, [kindField!"builtin", variantsField]),
		(in StructBody.Enum x) =>
			jsonObject(alloc, [kindField!"enum", field!"members"(jsonOfEnumMembers(alloc, x.members)), variantsField]),
		(in StructBody.Extern x) =>
			jsonObject(alloc, [
				kindField!"extern",
				optionalField!("size", TypeSize)(x.size, (in TypeSize size) =>
					jsonObject(alloc, [
						field!"size"(size.sizeBytes),
						field!"alignment"(size.alignmentBytes)])),
				variantsField]),
		(in StructBody.Flags x) =>
			jsonObject(alloc, [kindField!"flags", field!"members"(jsonOfEnumMembers(alloc, x.members)), variantsField]),
		(in StructBody.Record x) =>
			documentRecord(alloc, a, x, variantsField),
		(in StructBody.Union x) =>
			documentUnion(alloc, a, x, variantsField),
		(in StructBody.Variant x) =>
			documentVariant(alloc, a, x, variantsField)));
}

Json jsonOfEnumMembers(ref Alloc alloc, in EnumOrFlagsMember[] members) =>
	jsonList!EnumOrFlagsMember(alloc, members, (in EnumOrFlagsMember member) =>
		jsonString(member.name));

Json documentRecord(ref Alloc alloc, in StructDecl decl, in StructBody.Record a, Json.ObjectField variantsField) =>
	jsonObject(alloc, [
		kindField!"record",
		maybePurity(alloc, decl),
		optionalFlagField!"has-non-public-fields"(hasNonPublicFields(a)),
		optionalFlagField!"nominal"(a.flags.nominal),
		field!"fields"(jsonList(
			mapOp!(Json, RecordField)(alloc, a.fields, (ref RecordField field) =>
				documentRecordField(alloc, decl.typeParams, field)))),
		variantsField]);

Json.ObjectField maybePurity(ref Alloc alloc, in StructDecl decl) =>
	optionalField!"purity"(decl.purity != Purity.data, () => jsonString(stringOfEnum(decl.purity)));

bool hasNonPublicFields(in StructBody.Record a) =>
	exists!RecordField(a.fields, (in RecordField x) {
		final switch (x.visibility) {
			case Visibility.private_:
			case Visibility.internal:
				return true;
			case Visibility.public_:
				return false;
		}
	});

Json documentUnion(ref Alloc alloc, in StructDecl decl, in StructBody.Union a, Json.ObjectField variantsField) =>
	jsonObject(alloc, [
		kindField!"union",
		maybePurity(alloc, decl),
		field!"members"(jsonList!UnionMember(alloc, a.members, (in UnionMember member) =>
			documentUnionMember(alloc, decl.typeParams, member))),
		variantsField]);

Json documentVariant(ref Alloc alloc, in StructDecl decl, in StructBody.Variant a, Json.ObjectField variantsField) =>
	jsonObject(alloc, [kindField!"variant", maybePurity(alloc, decl), variantsField]);

Opt!Json documentRecordField(ref Alloc alloc, in TypeParams typeParams, in RecordField a) {
	final switch (a.visibility) {
		case Visibility.private_:
		case Visibility.internal:
			return none!Json;
		case Visibility.public_:
			return some(jsonObject(alloc, [
				field!"name"(a.name),
				field!"type"(documentTypeRef(alloc, typeParams, a.type)),
				optionalFlagField!"mut"(has(a.mutability) && force(a.mutability) == Visibility.public_)]));
	}
}

Json documentUnionMember(ref Alloc alloc, in TypeParams typeParams, in UnionMember a) =>
	jsonObject(alloc, [
		field!"name"(a.name),
		field!"type"(documentTypeRef(alloc, typeParams, a.type))]);

DocExport documentSpec(ref Alloc alloc, in SpecDecl a) =>
	documentExport(alloc, a.range, a.name, a.docComment, a.typeParams, jsonObject(alloc, [
		kindField!"spec",
		optionalFlagField!"builtin"(has(a.builtin)),
		field!"parents"(jsonList(map(alloc, a.parents, (ref immutable SpecInst* x) =>
			documentSpecInst(alloc, a.typeParams, *x)))),
		field!"sigs"(jsonList!Signature(alloc, a.sigs, (in Signature sig) =>
			documentSpecDeclSig(alloc, a.typeParams, sig)))]));

Json documentSpecDeclSig(ref Alloc alloc, in TypeParams typeParams, in Signature a) =>
	jsonObject(alloc, [
		optionalStringField!"doc"(alloc, a.ast.docComment),
		field!"name"(a.name),
		field!"return-type"(documentTypeRef(alloc, typeParams, a.returnType)),
		field!"params"(documentParamDestructures(alloc, typeParams, a.params))]);

DocExport documentVarDecl(ref Alloc alloc, in VarDecl a) =>
	documentExport(alloc, a.range, a.name, a.docComment, a.typeParams, jsonObject(alloc, [
		kindField(stringOfVarDeclKind(a.kind)),
		field!"type"(documentTypeRef(alloc, a.typeParams, a.type))]));

string stringOfVarDeclKind(VarKind kind) {
	final switch (kind) {
		case VarKind.global:
			return "global";
		case VarKind.threadLocal:
			return "thread-local";
	}
}

DocExport documentFun(ref Alloc alloc, in FunDecl a) =>
	documentExport(alloc, a.range, a.name, a.docComment, a.typeParams, jsonObject(alloc, [
		kindField!"fun",
		field!"return-type"(documentTypeRef(alloc, a.typeParams, a.returnType)),
		documentParams(alloc, a.typeParams, a.params),
		optionalFlagField!"variadic"(a.isVariadic),
		optionalArrayField!"specs"(documentSpecs(alloc, a))]));

Json[] documentSpecs(ref Alloc alloc, in FunDecl a) =>
	buildArray!Json(alloc, (scope ref Builder!Json res) {
		if (a.isBare)
			res ~= jsonOfSpecialSpec(alloc, symbol!"bare");
		if (a.isSummon)
			res ~= jsonOfSpecialSpec(alloc, symbol!"summon");
		if (a.isUnsafe)
			res ~= jsonOfSpecialSpec(alloc, symbol!"unsafe");
		foreach (SpecInst* spec; a.specs)
			res ~= documentSpecInst(alloc, a.typeParams, *spec);
	});

Json jsonOfSpecialSpec(ref Alloc alloc, Symbol name) =>
	jsonObject(alloc, [kindField!"special", field!"name"(name)]);

Json.ObjectField documentParams(ref Alloc alloc, in TypeParams typeParams, in Params params) =>
	field!"params"(documentParamDestructures(alloc, typeParams, paramsArray(params)));

Json documentParamDestructures(ref Alloc alloc, in TypeParams typeParams, in Destructure[] a) =>
	jsonList!Destructure(alloc, a, (in Destructure x) =>
		documentParam(alloc, typeParams, x));

Json documentParam(ref Alloc alloc, in TypeParams typeParams, in Destructure a) {
	Opt!Symbol name = a.name;
	return jsonObject(alloc, [
		field!"name"(has(name) ? force(name) : symbol!"anonymous"),
		field!"type"(documentTypeRef(alloc, typeParams, a.type))]);
}

Json documentTypeRef(ref Alloc alloc, in TypeParams typeParams, in Type a) =>
	a.matchIn!Json(
		(in Type.Bogus) =>
			assert(false),
		(in TypeParamIndex x) =>
			jsonObject(alloc, [kindField!"type-param", field!"name"(typeParams[x.index].name)]),
		(in StructInst x) =>
			documentStructInst(alloc, typeParams, x));

Json documentSpecInst(ref Alloc alloc, in TypeParams typeParams, in SpecInst a) =>
	documentNameAndTypeArgs(alloc, typeParams, "spec", a.name, a.typeArgs);

Json documentStructInst(ref Alloc alloc, in TypeParams typeParams, in StructInst a) =>
	documentNameAndTypeArgs(alloc, typeParams, "struct", a.decl.name, a.typeArgs);

Json documentNameAndTypeArgs(
	ref Alloc alloc,
	in TypeParams typeParams,
	string nodeType,
	Symbol name,
	in Type[] typeArgs,
) =>
	isEmpty(typeArgs)
		? jsonObject(alloc, [kindField(nodeType), field!"name"(name)])
		: jsonObject(alloc, [
			kindField(nodeType),
			field!"name"(name),
			field!"type-args"(jsonList!Type(alloc, typeArgs, (in Type typeArg) =>
				documentTypeRef(alloc, typeParams, typeArg)))]);

void eachLine(string a, in void delegate(string) @safe @nogc pure nothrow cb) {
	Opt!size_t index = indexOf(a, '\n');
	if (has(index)) {
		cb(a[0..force(index)]);
		eachLine(a[force(index)+1 .. $], cb);
	} else
		cb(a);
}
