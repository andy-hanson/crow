module document.document;

@safe @nogc pure nothrow:

import model.model :
	body_,
	FieldMutability,
	FunDecl,
	isVariadic,
	matchSpecBody,
	matchStructBody,
	matchStructOrAlias,
	matchType,
	Module,
	name,
	NameReferents,
	noCtx,
	noDoc,
	Param,
	paramsArray,
	Program,
	Purity,
	RecordField,
	SpecBody,
	SpecDecl,
	SpecDeclSig,
	SpecInst,
	StructAlias,
	StructBody,
	StructDecl,
	StructInst,
	StructOrAlias,
	summon,
	symOfPurity,
	target,
	Type,
	typeArgs,
	TypeParam,
	typeParams,
	UnionMember,
	unsafe,
	Visibility;
import util.alloc.alloc : Alloc;
import util.col.arr : empty;
import util.col.arrBuilder : add, ArrBuilder, arrBuilderSort, finishArr;
import util.col.arrUtil : exists, findIndex, mapOp;
import util.col.dict : dictEach;
import util.col.str : SafeCStr, safeCStrIsEmpty;
import util.comparison : compareNat16, compareNat32, Comparison;
import util.opt : force, has, none, Opt, some;
import util.path : AllPaths, Path, PathsInfo, pathToSafeCStrPreferRelative;
import util.repr : jsonStrOfRepr, NameAndRepr, nameAndRepr, Repr, reprArr, reprBool, reprNamedRecord, reprStr, reprSym;
import util.sourceRange : FileAndRange;
import util.sym : AllSymbols, Sym, sym;
import util.util : unreachable, verify;

immutable(SafeCStr) documentJSON(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	ref immutable Program program,
) =>
	jsonStrOfRepr(alloc, allSymbols, documentRootModules(alloc, allSymbols, allPaths, pathsInfo, program));

private:

immutable(Repr) documentRootModules(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	ref immutable Program program,
) =>
	reprNamedRecord!"root"(alloc, [
		nameAndRepr!"modules"(reprArr(alloc, program.specialModules.rootModules, (ref immutable Module* x) =>
			documentModule(alloc, allSymbols, allPaths, pathsInfo, program, *x)))]);

immutable(Repr) documentModule(
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	ref immutable Program program,
	ref immutable Module a,
) {
	immutable Path path = program.filesInfo.filePaths[a.fileIndex];
	immutable SafeCStr pathStr = pathToSafeCStrPreferRelative(alloc, allPaths, pathsInfo, path);
	ArrBuilder!DocExport exports;
	dictEach!(Sym, NameReferents)(
		a.allExportedNames,
		(immutable(Sym), ref immutable NameReferents referents) {
			if (has(referents.structOrAlias))
				add(alloc, exports, documentStructOrAlias(alloc, force(referents.structOrAlias)));
			if (has(referents.spec))
				add(alloc, exports, documentSpec(alloc, *force(referents.spec)));
			foreach (immutable FunDecl* fun; referents.funs)
				if (!noDoc(*fun))
					add(alloc, exports, documentFun(alloc, *fun));
		});
	arrBuilderSort!DocExport(exports, (ref immutable DocExport x, ref immutable DocExport y) =>
		compareRanges(x.range, y.range));
	ArrBuilder!NameAndRepr fields;
	add(alloc, fields, nameAndRepr!"path"(reprStr(pathStr)));
	if (!safeCStrIsEmpty(a.docComment))
		add(alloc, fields, nameAndRepr!"comment"(reprStr(a.docComment)));
	add(alloc, fields, nameAndRepr!"exports"(
		reprArr(alloc, finishArr(alloc, exports), (ref immutable DocExport x) => x.repr)));
	return reprNamedRecord!"module"(finishArr(alloc, fields));
}

immutable(Comparison) compareRanges(immutable FileAndRange a, immutable FileAndRange b) {
	immutable Comparison compareFile = compareNat16(a.fileIndex.index, b.fileIndex.index);
	return compareFile == Comparison.equal ? compareNat32(a.start, b.start) : compareFile;
}

struct DocExport {
	immutable FileAndRange range;
	immutable Repr repr;
}

immutable(DocExport) documentExport(
	ref Alloc alloc,
	immutable FileAndRange range,
	immutable Sym name,
	immutable SafeCStr docComment,
	immutable TypeParam[] typeParams,
	immutable Repr value,
) {
	ArrBuilder!NameAndRepr fields;
	add(alloc, fields, nameAndRepr!"name"(reprSym(name)));
	if (!safeCStrIsEmpty(docComment))
		add(alloc, fields, nameAndRepr!"comment"(reprStr(docComment)));
	if (!empty(typeParams))
		add(alloc, fields, nameAndRepr!"type-params"(documentTypeParams(alloc, typeParams)));
	add(alloc, fields, nameAndRepr!"value"(value));
	return immutable DocExport(range, reprNamedRecord!"export"(finishArr(alloc, fields)));
}

immutable(DocExport) documentStructOrAlias(ref Alloc alloc, immutable StructOrAlias a) =>
	matchStructOrAlias!(immutable DocExport)(
		a,
		(ref immutable StructAlias x) =>
			documentStructAlias(alloc, x),
		(ref immutable StructDecl x) =>
			documentStructDecl(alloc, x));

immutable(DocExport) documentStructAlias(ref Alloc alloc, ref immutable StructAlias a) {
	immutable Opt!(StructInst*) optTarget = target(a);
	return documentExport(alloc, a.range, a.name, a.docComment, a.typeParams, reprNamedRecord!"alias"(alloc, [
		nameAndRepr!"target"(documentStructInst(alloc, *force(optTarget)))]));
}

immutable(DocExport) documentStructDecl(ref Alloc alloc, ref immutable StructDecl a) =>
	documentExport(alloc, a.range, a.name, a.docComment, a.typeParams, matchStructBody!(immutable Repr)(
		body_(a),
		(ref immutable StructBody.Bogus) =>
			unreachable!(immutable Repr),
		(ref immutable StructBody.Builtin) =>
			reprNamedRecord!"builtin"(alloc, [nameAndRepr!"name"(reprSym(a.name))]),
		(ref immutable StructBody.Enum it) =>
			reprNamedRecord!"enum"(alloc, [nameAndRepr!"members"(
				reprArr(alloc, it.members, (ref immutable StructBody.Enum.Member member) =>
					reprSym(member.name)))]),
		(ref immutable StructBody.Flags it) =>
			reprNamedRecord!"flags"(alloc, [nameAndRepr!"members"(
				reprArr(alloc, it.members, (ref immutable StructBody.Enum.Member member) =>
					reprSym(member.name)))]),
		(ref immutable StructBody.ExternPointer) =>
			reprNamedRecord!"extern-pointer"(alloc, []),
		(ref immutable StructBody.Record it) =>
			documentRecord(alloc, a, it),
		(ref immutable StructBody.Union it) =>
			documentUnion(alloc, a, it)));

immutable(Repr) documentRecord(ref Alloc alloc, ref immutable StructDecl decl, ref immutable StructBody.Record a) {
	ArrBuilder!NameAndRepr fields;
	maybeAddPurity(alloc, fields, decl);
	if (hasPrivateFields(a))
		add(alloc, fields, nameAndRepr!"has-private"(reprBool(true)));
	add(alloc, fields, nameAndRepr!"fields"(reprArr(mapOp(alloc, a.fields, (ref immutable RecordField field) =>
		documentRecordField(alloc, field)))));
	return reprNamedRecord!"record"(finishArr(alloc, fields));
}

void maybeAddPurity(ref Alloc alloc, ref ArrBuilder!NameAndRepr fields, ref immutable StructDecl decl) {
	if (decl.purity != Purity.data)
		add(alloc, fields, nameAndRepr!"purity"(reprSym(symOfPurity(decl.purity))));
}

immutable(bool) hasPrivateFields(ref immutable StructBody.Record a) =>
	exists!(immutable RecordField)(a.fields, (ref immutable RecordField x) {
		final switch (x.visibility) {
			case Visibility.public_:
				return false;
			case Visibility.private_:
				return true;
		}
	});

immutable(Repr) documentUnion(ref Alloc alloc, ref immutable StructDecl decl, ref immutable StructBody.Union a) {
	ArrBuilder!NameAndRepr fields;
	maybeAddPurity(alloc, fields, decl);
	add(alloc, fields, nameAndRepr!"members"(reprArr(alloc, a.members, (ref immutable UnionMember member) =>
		documentUnionMember(alloc, member))));
	return reprNamedRecord!"union"(finishArr(alloc, fields));
}

immutable(Opt!Repr) documentRecordField(ref Alloc alloc, ref immutable RecordField a) {
	final switch (a.visibility) {
		case Visibility.private_:
			return none!Repr;
		case Visibility.public_:
			ArrBuilder!NameAndRepr fields;
			add(alloc, fields, nameAndRepr!"name"(reprSym(a.name)));
			add(alloc, fields, nameAndRepr!"type"(documentTypeRef(alloc, a.type)));
			final switch (a.mutability) {
				case FieldMutability.const_:
					break;
				case FieldMutability.private_:
					break;
				case FieldMutability.public_:
					add(alloc, fields, nameAndRepr!"mut"(reprBool(true)));
					break;
			}
			return some(reprNamedRecord!"field"(finishArr(alloc, fields)));
	}
}

immutable(Repr) documentUnionMember(ref Alloc alloc, ref immutable UnionMember a) {
	ArrBuilder!NameAndRepr fields;
	add(alloc, fields, nameAndRepr!"name"(reprSym(a.name)));
	if (has(a.type))
		add(alloc, fields, nameAndRepr!"type"(documentTypeRef(alloc, force(a.type))));
	return reprNamedRecord!"member"(finishArr(alloc, fields));
}

immutable(DocExport) documentSpec(ref Alloc alloc, ref immutable SpecDecl a) {
	immutable Repr value = reprNamedRecord!"spec"(alloc, [
		nameAndRepr!"body"(matchSpecBody!(immutable Repr)(
			a.body_,
			(immutable SpecBody.Builtin) =>
				reprNamedRecord!"builtin"(alloc, []),
			(immutable SpecDeclSig[] sigs) =>
				reprNamedRecord!"sigs"(alloc, [
					nameAndRepr!"sigs"(reprArr(alloc, sigs, (ref immutable SpecDeclSig sig) =>
						documentSpecDeclSig(alloc, sig)))])))]);
	return documentExport(alloc, a.range, a.name, a.docComment, a.typeParams, value);
}

immutable(Repr) documentSpecDeclSig(ref Alloc alloc, ref immutable SpecDeclSig a) {
	ArrBuilder!NameAndRepr fields;
	if (!safeCStrIsEmpty(a.docComment))
		add(alloc, fields, nameAndRepr!"comment"(reprStr(a.docComment)));
	add(alloc, fields, nameAndRepr!"name"(reprSym(a.name)));
	add(alloc, fields, nameAndRepr!"return-type"(documentTypeRef(alloc, a.returnType)));
	add(alloc, fields, nameAndRepr!"params"(reprArr(alloc, paramsArray(a.params), (ref immutable Param x) =>
		documentParam(alloc, x))));
	return reprNamedRecord!"sig"(finishArr(alloc, fields));
}

immutable(DocExport) documentFun(ref Alloc alloc, ref immutable FunDecl a) {
	ArrBuilder!NameAndRepr fields;
	add(alloc, fields, nameAndRepr!"return-type"(documentTypeRef(alloc, a.returnType)));
	add(alloc, fields, nameAndRepr!"params"(reprArr(alloc, paramsArray(a.params), (ref immutable Param x) =>
			documentParam(alloc, x))));
	if (isVariadic(a))
		add(alloc, fields, nameAndRepr!"variadic"(reprBool(true)));
	immutable Repr[] specs = documentSpecs(alloc, a);
	if (!empty(specs))
		add(alloc, fields, nameAndRepr!"specs"(reprArr(specs)));
	immutable Repr value = reprNamedRecord!"fun"(finishArr(alloc, fields));
	return documentExport(alloc, a.range, a.name, a.docComment, a.typeParams, value);
}

immutable(Repr[]) documentSpecs(ref Alloc alloc, ref immutable FunDecl a) {
	ArrBuilder!Repr res;
	if (summon(a))
		add(alloc, res, reprSpecialSpec(alloc, sym!"summon"));
	if (unsafe(a))
		add(alloc, res, reprSpecialSpec(alloc, sym!"unsafe"));
	if (noCtx(a))
		add(alloc, res, reprSpecialSpec(alloc, sym!"noctx"));
	foreach (immutable SpecInst* spec; a.specs)
		add(alloc, res, documentSpecInst(alloc, *spec));
	return finishArr(alloc, res);
}

immutable(Repr) reprSpecialSpec(ref Alloc alloc, immutable Sym name) =>
	reprNamedRecord!"special"(alloc, [nameAndRepr!"name"(reprSym(name))]);

immutable(Repr) documentParam(ref Alloc alloc, ref immutable Param a) =>
	reprNamedRecord!"param"(alloc, [
		nameAndRepr!"name"(reprSym(a.nameOrUnderscore)),
		nameAndRepr!"type"(documentTypeRef(alloc, a.type))]);

immutable(Repr) documentTypeRef(ref Alloc alloc, immutable Type a) =>
	matchType!(immutable Repr)(
		a,
		(immutable Type.Bogus) =>
			unreachable!(immutable Repr),
		(immutable TypeParam* it) =>
			reprNamedRecord!"type-param"(alloc, [nameAndRepr!"name"(reprSym(it.name))]),
		(immutable StructInst* it) =>
			documentStructInst(alloc, *it));

immutable(Repr) documentSpecInst(ref Alloc alloc, ref immutable SpecInst a) =>
	documentNameAndTypeArgs(alloc, sym!"spec", name(a), typeArgs(a));

immutable(Repr) documentStructInst(ref Alloc alloc, ref immutable StructInst a) =>
	documentNameAndTypeArgs(alloc, sym!"struct", name(a), typeArgs(a));

immutable(Repr) documentNameAndTypeArgs(
	ref Alloc alloc,
	immutable Sym nodeType,
	immutable Sym name,
	scope immutable Type[] typeArgs,
) =>
	empty(typeArgs)
		? reprNamedRecord(alloc, nodeType, [nameAndRepr!"name"(reprSym(name))])
		: reprNamedRecord(alloc, nodeType, [
			nameAndRepr!"name"(reprSym(name)),
			nameAndRepr!"type-args"(reprArr(alloc, typeArgs, (ref immutable Type typeArg) =>
				documentTypeRef(alloc, typeArg)))]);

immutable(Repr) documentTypeParams(ref Alloc alloc, scope immutable TypeParam[] xs) {
	verify(!empty(xs));
	return reprArr(alloc, xs, (ref immutable TypeParam x) =>
		reprNamedRecord!"type-param"(alloc, [nameAndRepr!"name"(reprSym(x.name))]));
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
