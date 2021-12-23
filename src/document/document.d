module document.document;

@safe @nogc pure nothrow:

import model.model :
	body_,
	FieldMutability,
	FunDecl,
	generated,
	matchSpecBody,
	matchStructBody,
	matchStructOrAlias,
	matchType,
	Module,
	name,
	NameReferents,
	Param,
	params,
	paramsArray,
	Program,
	RecordField,
	returnType,
	Sig,
	SpecBody,
	SpecDecl,
	StructAlias,
	StructBody,
	StructDecl,
	StructInst,
	StructOrAlias,
	target,
	Type,
	typeArgs,
	TypeParam,
	typeParams,
	UnionMember,
	Visibility;
import util.alloc.alloc : Alloc;
import util.col.arr : empty;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : findIndex, mapOp;
import util.col.dict : dictEach;
import util.col.fullIndexDict : fullIndexDictGet;
import util.col.str : SafeCStr, safeCStr, safeCStrIsEmpty;
import util.opt : force, has, none, Opt, some;
import util.path : AllPaths, Path, pathToSafeCStr;
import util.ptr : Ptr;
import util.repr : jsonStrOfRepr, NameAndRepr, nameAndRepr, Repr, reprArr, reprBool, reprNamedRecord, reprStr, reprSym;
import util.sym : AllSymbols, hashSym, shortSym, Sym, symEq;
import util.util : unreachable, verify;

immutable(SafeCStr) documentJSON(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable Program program,
) {
	return jsonStrOfRepr(alloc, allSymbols, documentRootModules(alloc, allSymbols, allPaths, program));
}

private:

immutable(Repr) documentRootModules(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable Program program,
) {
	return reprNamedRecord(alloc, "root", [
		nameAndRepr("modules", reprArr(alloc, program.specialModules.rootModules, (ref immutable Ptr!Module x) =>
			documentModule(alloc, allSymbols, allPaths, program, x.deref())))]);
}

immutable(Repr) documentModule(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable Program program,
	ref immutable Module a,
) {
	immutable Path path = fullIndexDictGet(program.filesInfo.filePaths, a.fileIndex).path;
	immutable SafeCStr pathStr = pathToSafeCStr(alloc, allPaths, safeCStr!"", path, safeCStr!"");
	ArrBuilder!Repr exports;
	dictEach!(Sym, NameReferents, symEq, hashSym)(
		a.allExportedNames,
		(immutable(Sym), ref immutable NameReferents referents) {
			if (has(referents.structOrAlias))
				add(alloc, exports, documentStructOrAlias(alloc, force(referents.structOrAlias)));
			if (has(referents.spec))
				add(alloc, exports, documentSpec(alloc, force(referents.spec).deref()));
			foreach (immutable Ptr!FunDecl fun; referents.funs)
				if (!fun.deref().generated)
					add(alloc, exports, documentFun(alloc, fun.deref()));
		});
	return reprNamedRecord(alloc, "module", [
		nameAndRepr("path", reprStr(pathStr)),
		nameAndRepr("exports", reprArr(finishArr(alloc, exports)))]);
}

immutable(Repr) documentExport(
	ref Alloc alloc,
	immutable Sym name,
	immutable SafeCStr docComment,
	immutable TypeParam[] typeParams,
	immutable Repr value,
) {
	ArrBuilder!NameAndRepr fields;
	add(alloc, fields, nameAndRepr("name", reprSym(name)));
	if (!safeCStrIsEmpty(docComment))
		add(alloc, fields, nameAndRepr("comment", reprStr(docComment)));
	if (!empty(typeParams))
		add(alloc, fields, nameAndRepr("type-params", documentTypeParams(alloc, typeParams)));
	add(alloc, fields, nameAndRepr("value", value));
	return reprNamedRecord("export", finishArr(alloc, fields));
}

immutable(Repr) documentStructOrAlias(ref Alloc alloc, immutable StructOrAlias a) {
	return matchStructOrAlias!(immutable Repr)(
		a,
		(ref immutable StructAlias x) =>
			documentStructAlias(alloc, x),
		(ref immutable StructDecl x) =>
			documentStructDecl(alloc, x));
}

immutable(Repr) documentStructAlias(ref Alloc alloc, ref immutable StructAlias a) {
	immutable Opt!(Ptr!StructInst) optTarget = target(a);
	return documentExport(alloc, a.name, a.docComment, typeParams(a), reprNamedRecord(alloc, "alias", [
		nameAndRepr("target", documentStructInst(alloc, force(optTarget).deref()))]));
}

immutable(Repr) documentStructDecl(ref Alloc alloc, ref immutable StructDecl a) {
	return documentExport(alloc, a.name, a.docComment, typeParams(a), matchStructBody!(immutable Repr)(
		body_(a),
		(ref immutable StructBody.Bogus) =>
			unreachable!(immutable Repr),
		(ref immutable StructBody.Builtin) =>
			reprNamedRecord(alloc, "builtin", [nameAndRepr("name", reprSym(a.name))]),
		(ref immutable StructBody.Enum it) =>
			reprNamedRecord(alloc, "enum", [nameAndRepr(
				"members",
				reprArr(alloc, it.members, (ref immutable StructBody.Enum.Member member) =>
					reprSym(member.name)))]),
		(ref immutable StructBody.Flags it) =>
			reprNamedRecord(alloc, "flags", [nameAndRepr(
				"members",
				reprArr(alloc, it.members, (ref immutable StructBody.Enum.Member member) =>
					reprSym(member.name)))]),
		(ref immutable StructBody.ExternPtr) =>
			reprNamedRecord(alloc, "extern-ptr", []),
		(ref immutable StructBody.Record it) {
			immutable Repr[] fields = mapOp(alloc, it.fields, (ref immutable RecordField field) =>
				documentRecordField(alloc, field));
			return reprNamedRecord(alloc, "record", [nameAndRepr("fields", reprArr(fields))]);
		},
		(ref immutable StructBody.Union it) =>
			reprNamedRecord(alloc, "union", [
				nameAndRepr("members", reprArr(alloc, it.members, (ref immutable UnionMember member) =>
					documentUnionMember(alloc, member)))])));
}

immutable(Opt!Repr) documentRecordField(ref Alloc alloc, ref immutable RecordField a) {
	final switch (a.visibility) {
		case Visibility.private_:
			return none!Repr;
		case Visibility.public_:
			ArrBuilder!NameAndRepr fields;
			add(alloc, fields, nameAndRepr("name", reprSym(a.name)));
			add(alloc, fields, nameAndRepr("type", documentTypeRef(alloc, a.type)));
			final switch (a.mutability) {
				case FieldMutability.const_:
					break;
				case FieldMutability.private_:
					break;
				case FieldMutability.public_:
					add(alloc, fields, nameAndRepr("mut", reprBool(true)));
					break;
			}
			return some(reprNamedRecord("field", finishArr(alloc, fields)));
	}
}

immutable(Repr) documentUnionMember(ref Alloc alloc, ref immutable UnionMember a) {
	ArrBuilder!NameAndRepr fields;
	add(alloc, fields, nameAndRepr("name", reprSym(a.name)));
	if (has(a.type))
		add(alloc, fields, nameAndRepr("type", documentTypeRef(alloc, force(a.type))));
	return reprNamedRecord("member", finishArr(alloc, fields));
}

immutable(Repr) documentSpec(ref Alloc alloc, ref immutable SpecDecl a) {
	immutable Repr value = reprNamedRecord(alloc, "spec", [
		nameAndRepr("body", matchSpecBody!(immutable Repr)(
			a.body_,
			(immutable SpecBody.Builtin) =>
				reprNamedRecord(alloc, "builtin", []),
			(immutable Sig[] sigs) =>
				reprNamedRecord(alloc, "sigs", [
					nameAndRepr("sigs", reprArr(alloc, sigs, (ref immutable Sig sig) =>
						documentSig(alloc, sig)))])))]);
	return documentExport(alloc, a.name, a.docComment, typeParams(a), value);
}

immutable(Repr) documentSig(ref Alloc alloc, ref immutable Sig a) {
	return reprNamedRecord(alloc, "sig", [
		nameAndRepr("name", reprSym(a.name)),
		nameAndRepr("return-type", documentTypeRef(alloc, a.returnType)),
		nameAndRepr("params", reprArr(alloc, paramsArray(a.params), (ref immutable Param x) =>
			documentParam(alloc, x))) ]);
}

immutable(Repr) documentFun(ref Alloc alloc, ref immutable FunDecl a) {
	//TODO: document specs
	immutable Repr value = reprNamedRecord(alloc, "fun", [
		nameAndRepr("return-type", documentTypeRef(alloc, returnType(a))),
		//TODO:handle variadic
		nameAndRepr("params", reprArr(alloc, paramsArray(params(a)), (ref immutable Param x) =>
			documentParam(alloc, x)))]);
	return documentExport(alloc, a.name, a.docComment, typeParams(a), value);
}

immutable(Repr) documentParam(ref Alloc alloc, ref immutable Param a) {
	return reprNamedRecord(alloc, "param", [
		nameAndRepr("name", reprSym(has(a.name) ? force(a.name) : shortSym("_"))),
		nameAndRepr("type", documentTypeRef(alloc, a.type))]);
}

immutable(Repr) documentTypeRef(ref Alloc alloc, immutable Type a) {
	return matchType!(immutable Repr)(
		a,
		(immutable Type.Bogus) =>
			unreachable!(immutable Repr),
		(immutable Ptr!TypeParam it) =>
			reprSym(it.deref().name),
		(immutable Ptr!StructInst it) =>
			documentStructInst(alloc, it.deref()));
}

immutable(Repr) documentStructInst(ref Alloc alloc, ref immutable StructInst a) {
	return empty(typeArgs(a))
		? reprSym(a.name)
		: reprNamedRecord(alloc, a.name, [
			nameAndRepr("type-args", reprArr(alloc, typeArgs(a), (ref immutable Type typeArg) =>
				documentTypeRef(alloc, typeArg)))]);
}

immutable(Repr) documentTypeParams(ref Alloc alloc, immutable TypeParam[] xs) {
	verify(!empty(xs));
	return reprArr(alloc, xs, (ref immutable TypeParam x) =>
		reprNamedRecord(alloc, "type-param", [
			nameAndRepr("name", reprSym(x.name))]));
}

void eachLine(
	immutable string a,
	scope void delegate(immutable string) @safe @nogc pure nothrow cb
) {
	immutable Opt!size_t index = findIndex!char(a, (ref immutable char c) => c == '\n');
	if (has(index)) {
		cb(a[0..force(index)]);
		eachLine(a[force(index)+1 .. $], cb);
	} else
		cb(a);
}
