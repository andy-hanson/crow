module document.document;

@safe @nogc pure nothrow:

import model.ast : NameAndRange;
import model.concreteModel : TypeSize;
import model.model :
	Destructure,
	docComment,
	FieldMutability,
	FunDecl,
	isBare,
	isGenerated,
	isSummon,
	isUnsafe,
	isVariadic,
	Module,
	name,
	NameReferents,
	Params,
	paramsArray,
	Program,
	Purity,
	range,
	RecordField,
	SpecDecl,
	SpecDeclBody,
	SpecDeclSig,
	SpecInst,
	StructAlias,
	StructBody,
	StructDecl,
	StructInst,
	StructOrAlias,
	symOfPurity,
	target,
	Type,
	TypeParamIndex,
	TypeParams,
	typeParams,
	UnionMember,
	Visibility,
	visibility;
import util.alloc.alloc : Alloc;
import util.col.arr : empty;
import util.col.arrBuilder : add, ArrBuilder, arrBuilderSort, finishArr;
import util.col.arrUtil : exists, indexOf, map, mapOp;
import util.col.str : SafeCStr;
import util.json :
	field,
	Json,
	jsonObject,
	jsonToString,
	optionalArrayField,
	optionalFlagField,
	optionalField,
	optionalStringField,
	jsonList,
	jsonString,
	kindField;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : compareUriAndRange, UriAndRange;
import util.sym : AllSymbols, Sym, sym;
import util.uri : AllUris, stringOfUri;
import util.util : unreachable;

SafeCStr documentJSON(ref Alloc alloc, in AllSymbols allSymbols, in AllUris allUris, in Program program) =>
	jsonToString(alloc, allSymbols, documentRootModules(alloc, allSymbols, allUris, program));

private:

Json documentRootModules(ref Alloc alloc, in AllSymbols allSymbols, in AllUris allUris, in Program program) =>
	jsonObject(alloc, [
		field!"modules"(jsonList!(Module*)(alloc, program.rootModules, (in Module* x) =>
			documentModule(alloc, allSymbols, allUris, program, *x)))]);

Json documentModule(
	ref Alloc alloc,
	in AllSymbols allSymbols,
	in AllUris allUris,
	in Program program,
	in Module a,
) {
	ArrBuilder!DocExport exports; // TODO: no alloc
	foreach (NameReferents referents; a.allExportedNames) {
		if (has(referents.structOrAlias) && visibility(force(referents.structOrAlias)) == Visibility.public_)
			add(alloc, exports, documentStructOrAlias(alloc, force(referents.structOrAlias)));
		if (has(referents.spec) && force(referents.spec).visibility == Visibility.public_)
			add(alloc, exports, documentSpec(alloc, *force(referents.spec)));
		foreach (FunDecl* fun; referents.funs)
			if (fun.visibility == Visibility.public_ && !isGenerated(*fun))
				add(alloc, exports, documentFun(alloc, *fun));
	}
	arrBuilderSort!DocExport(exports, (in DocExport x, in DocExport y) =>
		compareUriAndRange(allUris, x.range, y.range));
	return jsonObject(alloc, [
		field!"uri"(stringOfUri(alloc, allUris, a.uri)),
		optionalStringField!"doc"(alloc, a.ast.docComment),
		field!"exports"(jsonList!DocExport(alloc, finishArr(alloc, exports), (in DocExport x) => x.json))]);
}

immutable struct DocExport {
	UriAndRange range;
	Json json;
}

DocExport documentExport(
	ref Alloc alloc,
	UriAndRange range,
	Sym name,
	in SafeCStr docComment,
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

DocExport documentStructAlias(ref Alloc alloc, in StructAlias a) {
	Opt!(StructInst*) optTarget = target(a);
	return documentExport(alloc, range(a), a.name, a.docComment, a.typeParams, jsonObject(alloc, [
		kindField!"alias",
		field!"target"(documentStructInst(alloc, a.typeParams, *force(optTarget)))]));
}

DocExport documentStructDecl(ref Alloc alloc, in StructDecl a) =>
	documentExport(alloc, a.range, a.name, a.docComment, a.typeParams, a.body_.matchIn!Json(
		(in StructBody.Bogus) =>
			unreachable!Json,
		(in StructBody.Builtin) =>
			jsonObject(alloc, [kindField!"builtin", field!"name"(a.name)]),
		(in StructBody.Enum x) =>
			jsonObject(alloc, [kindField!"enum", field!"members"(jsonOfEnumMembers(alloc, x.members))]),
		(in StructBody.Extern x) =>
			jsonObject(alloc, [
				kindField!"extern",
				optionalField!("size", TypeSize)(x.size, (in TypeSize size) =>
					jsonObject(alloc, [
						field!"size"(size.sizeBytes),
						field!"alignment"(size.alignmentBytes)]))]),
		(in StructBody.Flags x) =>
			jsonObject(alloc, [kindField!"flags", field!"members"(jsonOfEnumMembers(alloc, x.members))]),
		(in StructBody.Record x) =>
			documentRecord(alloc, a, x),
		(in StructBody.Union x) =>
			documentUnion(alloc, a, x)));

Json jsonOfEnumMembers(ref Alloc alloc, in StructBody.Enum.Member[] members) =>
	jsonList!(StructBody.Enum.Member)(alloc, members, (in StructBody.Enum.Member member) =>
		jsonString(member.name));

Json documentRecord(ref Alloc alloc, in StructDecl decl, in StructBody.Record a) =>
	jsonObject(alloc, [
		kindField!"record",
		maybePurity(alloc, decl),
		optionalFlagField!"has-non-public-fields"(hasNonPublicFields(a)),
		field!"fields"(jsonList(
			mapOp!(Json, RecordField)(alloc, a.fields, (ref RecordField field) =>
				documentRecordField(alloc, decl.typeParams, field))))]);

Json.ObjectField maybePurity(ref Alloc alloc, in StructDecl decl) =>
	optionalField!"purity"(decl.purity != Purity.data, () => jsonString(symOfPurity(decl.purity)));

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

Json documentUnion(ref Alloc alloc, in StructDecl decl, in StructBody.Union a) =>
	jsonObject(alloc, [
		kindField!"union",
		maybePurity(alloc, decl),
		field!"members"(jsonList!UnionMember(alloc, a.members, (in UnionMember member) =>
			documentUnionMember(alloc, decl.typeParams, member)))]);

Opt!Json documentRecordField(ref Alloc alloc, in TypeParams typeParams, in RecordField a) {
	final switch (a.visibility) {
		case Visibility.private_:
		case Visibility.internal:
			return none!Json;
		case Visibility.public_:
			return some(jsonObject(alloc, [
				field!"name"(a.name),
				field!"type"(documentTypeRef(alloc, typeParams, a.type)),
				optionalFlagField!"mut"(a.mutability == FieldMutability.public_)]));
	}
}

Json documentUnionMember(ref Alloc alloc, in TypeParams typeParams, in UnionMember a) =>
	jsonObject(alloc, [
		field!"name"(a.name),
		field!"type"(documentTypeRef(alloc, typeParams, a.type))]);

DocExport documentSpec(ref Alloc alloc, in SpecDecl a) =>
	documentExport(alloc, a.range, a.name, a.docComment, a.typeParams, jsonObject(alloc, [
		kindField!"spec",
		field!"parents"(jsonList(map(alloc, a.parents, (ref immutable SpecInst* x) =>
			documentSpecInst(alloc, a.typeParams, *x)))),
		field!"body"(a.body_.matchIn!Json(
			(in SpecDeclBody.Builtin) =>
				jsonObject(alloc, [kindField!"builtin"]),
			(in SpecDeclSig[] sigs) =>
				jsonObject(alloc, [
					kindField!"sigs",
					field!"sigs"(jsonList!SpecDeclSig(alloc, sigs, (in SpecDeclSig sig) =>
						documentSpecDeclSig(alloc, a.typeParams, sig)))])))]));

Json documentSpecDeclSig(ref Alloc alloc, in TypeParams typeParams, in SpecDeclSig a) =>
	jsonObject(alloc, [
		optionalStringField!"doc"(alloc, a.ast.docComment),
		field!"name"(a.name),
		field!"return-type"(documentTypeRef(alloc, typeParams, a.returnType)),
		field!"params"(documentParamDestructures(alloc, typeParams, a.params))]);

DocExport documentFun(ref Alloc alloc, in FunDecl a) =>
	documentExport(alloc, a.range, a.name, docComment(a), a.typeParams, jsonObject(alloc, [
		kindField!"fun",
		field!"return-type"(documentTypeRef(alloc, a.typeParams, a.returnType)),
		documentParams(alloc, a.typeParams, a.params),
		optionalFlagField!"variadic"(isVariadic(a)),
		optionalArrayField!"specs"(documentSpecs(alloc, a))]));

Json[] documentSpecs(ref Alloc alloc, in FunDecl a) {
	ArrBuilder!Json res;
	if (isBare(a))
		add(alloc, res, jsonOfSpecialSpec(alloc, sym!"bare"));
	if (isSummon(a))
		add(alloc, res, jsonOfSpecialSpec(alloc, sym!"summon"));
	if (isUnsafe(a))
		add(alloc, res, jsonOfSpecialSpec(alloc, sym!"unsafe"));
	foreach (SpecInst* spec; a.specs)
		add(alloc, res, documentSpecInst(alloc, a.typeParams, *spec));
	return finishArr(alloc, res);
}

Json jsonOfSpecialSpec(ref Alloc alloc, Sym name) =>
	jsonObject(alloc, [kindField!"special", field!"name"(name)]);

Json.ObjectField documentParams(ref Alloc alloc, in TypeParams typeParams, in Params params) =>
	field!"params"(documentParamDestructures(alloc, typeParams, paramsArray(params)));

Json documentParamDestructures(ref Alloc alloc, in TypeParams typeParams, in Destructure[] a) =>
	jsonList!Destructure(alloc, a, (in Destructure x) =>
		documentParam(alloc, typeParams, x));

Json documentParam(ref Alloc alloc, in TypeParams typeParams, in Destructure a) {
	Opt!Sym name = a.name;
	return jsonObject(alloc, [
		field!"name"(has(name) ? force(name) : sym!"anonymous"),
		field!"type"(documentTypeRef(alloc, typeParams, a.type))]);
}

Json documentTypeRef(ref Alloc alloc, in TypeParams typeParams, in Type a) =>
	a.matchIn!Json(
		(in Type.Bogus) =>
			unreachable!Json,
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
	Sym name,
	in Type[] typeArgs,
) =>
	empty(typeArgs)
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
