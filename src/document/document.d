module document.document;

@safe @nogc pure nothrow:

import model.concreteModel : TypeSize;
import model.model :
	body_,
	FieldMutability,
	FunDecl,
	isVariadic,
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
import util.col.arrUtil : exists, indexOf, mapOp;
import util.col.dict : dictEachIn;
import util.col.str : SafeCStr, safeCStrIsEmpty;
import util.comparison : compareNat16, compareNat32, Comparison;
import util.opt : force, has, none, Opt, some;
import util.path : AllPaths, Path, PathsInfo, pathToSafeCStrPreferRelative;
import util.repr :
	jsonStrOfRepr,
	NameAndRepr,
	nameAndRepr,
	Repr,
	reprArr,
	reprBool,
	reprNamedRecord,
	reprNat,
	reprOpt,
	reprStr,
	reprSym;
import util.sourceRange : FileAndRange;
import util.sym : AllSymbols, Sym, sym;
import util.util : unreachable, verify;

SafeCStr documentJSON(
	ref Alloc alloc,
	in AllSymbols allSymbols,
	in AllPaths allPaths,
	in PathsInfo pathsInfo,
	in Program program,
) =>
	jsonStrOfRepr(alloc, allSymbols, documentRootModules(alloc, allSymbols, allPaths, pathsInfo, program));

private:

Repr documentRootModules(
	ref Alloc alloc,
	in AllSymbols allSymbols,
	in AllPaths allPaths,
	in PathsInfo pathsInfo,
	in Program program,
) =>
	reprNamedRecord!"root"(alloc, [
		nameAndRepr!"modules"(reprArr!(Module*)(alloc, program.rootModules, (in Module* x) =>
			documentModule(alloc, allSymbols, allPaths, pathsInfo, program, *x)))]);

Repr documentModule(
	ref Alloc alloc,
	in AllSymbols allSymbols,
	in AllPaths allPaths,
	in PathsInfo pathsInfo,
	in Program program,
	in Module a,
) {
	Path path = program.filesInfo.filePaths[a.fileIndex];
	SafeCStr pathStr = pathToSafeCStrPreferRelative(alloc, allPaths, pathsInfo, path);
	ArrBuilder!DocExport exports; // TODO: no alloc
	dictEachIn!(Sym, NameReferents)(
		a.allExportedNames,
		(in Sym _, in NameReferents referents) {
			if (has(referents.structOrAlias))
				add(alloc, exports, documentStructOrAlias(alloc, force(referents.structOrAlias)));
			if (has(referents.spec))
				add(alloc, exports, documentSpec(alloc, *force(referents.spec)));
			foreach (FunDecl* fun; referents.funs)
				if (!noDoc(*fun))
					add(alloc, exports, documentFun(alloc, *fun));
		});
	arrBuilderSort!DocExport(exports, (in DocExport x, in DocExport y) =>
		compareRanges(x.range, y.range));
	ArrBuilder!NameAndRepr fields;
	add(alloc, fields, nameAndRepr!"path"(reprStr(pathStr)));
	if (!safeCStrIsEmpty(a.docComment))
		add(alloc, fields, nameAndRepr!"comment"(reprStr(a.docComment)));
	add(alloc, fields, nameAndRepr!"exports"(
		reprArr!DocExport(alloc, finishArr(alloc, exports), (in DocExport x) => x.repr)));
	return reprNamedRecord!"module"(finishArr(alloc, fields));
}

Comparison compareRanges(FileAndRange a, FileAndRange b) {
	Comparison compareFile = compareNat16(a.fileIndex.index, b.fileIndex.index);
	return compareFile == Comparison.equal ? compareNat32(a.start, b.start) : compareFile;
}

immutable struct DocExport {
	FileAndRange range;
	Repr repr;
}

DocExport documentExport(
	ref Alloc alloc,
	FileAndRange range,
	Sym name,
	in SafeCStr docComment,
	in TypeParam[] typeParams,
	Repr value,
) {
	ArrBuilder!NameAndRepr fields;
	add(alloc, fields, nameAndRepr!"name"(reprSym(name)));
	if (!safeCStrIsEmpty(docComment))
		add(alloc, fields, nameAndRepr!"comment"(reprStr(docComment)));
	if (!empty(typeParams))
		add(alloc, fields, nameAndRepr!"type-params"(documentTypeParams(alloc, typeParams)));
	add(alloc, fields, nameAndRepr!"value"(value));
	return DocExport(range, reprNamedRecord!"export"(finishArr(alloc, fields)));
}

DocExport documentStructOrAlias(ref Alloc alloc, in StructOrAlias a) =>
	a.matchIn!DocExport(
		(in StructAlias x) =>
			documentStructAlias(alloc, x),
		(in StructDecl x) =>
			documentStructDecl(alloc, x));

DocExport documentStructAlias(ref Alloc alloc, in StructAlias a) {
	Opt!(StructInst*) optTarget = target(a);
	return documentExport(alloc, a.range, a.name, a.docComment, a.typeParams, reprNamedRecord!"alias"(alloc, [
		nameAndRepr!"target"(documentStructInst(alloc, *force(optTarget)))]));
}

DocExport documentStructDecl(ref Alloc alloc, in StructDecl a) =>
	documentExport(alloc, a.range, a.name, a.docComment, a.typeParams, body_(a).matchIn!Repr(
		(in StructBody.Bogus) =>
			unreachable!Repr,
		(in StructBody.Builtin) =>
			reprNamedRecord!"builtin"(alloc, [nameAndRepr!"name"(reprSym(a.name))]),
		(in StructBody.Enum x) =>
			reprNamedRecord!"enum"(alloc, [nameAndRepr!"members"(reprEnumMembers(alloc, x.members))]),
		(in StructBody.Extern x) =>
			reprNamedRecord!"extern"(alloc, [
				nameAndRepr!"size"(reprOpt!TypeSize(alloc, x.size, (in TypeSize size) =>
					reprNamedRecord!"type-size"(alloc, [
						nameAndRepr!"size"(reprNat(size.sizeBytes)),
						nameAndRepr!"alignment"(reprNat(size.alignmentBytes))])))]),
		(in StructBody.Flags x) =>
			reprNamedRecord!"flags"(alloc, [nameAndRepr!"members"(reprEnumMembers(alloc, x.members))]),
		(in StructBody.Record x) =>
			documentRecord(alloc, a, x),
		(in StructBody.Union x) =>
			documentUnion(alloc, a, x)));

Repr reprEnumMembers(ref Alloc alloc, in StructBody.Enum.Member[] members) =>
	reprArr!(StructBody.Enum.Member)(alloc, members, (in StructBody.Enum.Member member) =>
		reprSym(member.name));

Repr documentRecord(ref Alloc alloc, in StructDecl decl, in StructBody.Record a) {
	ArrBuilder!NameAndRepr fields;
	maybeAddPurity(alloc, fields, decl);
	if (hasPrivateFields(a))
		add(alloc, fields, nameAndRepr!"has-private"(reprBool(true)));
	add(alloc, fields, nameAndRepr!"fields"(reprArr(
		mapOp!(Repr, RecordField)(alloc, a.fields, (ref RecordField field) =>
			documentRecordField(alloc, field)))));
	return reprNamedRecord!"record"(finishArr(alloc, fields));
}

void maybeAddPurity(ref Alloc alloc, ref ArrBuilder!NameAndRepr fields, in StructDecl decl) {
	if (decl.purity != Purity.data)
		add(alloc, fields, nameAndRepr!"purity"(reprSym(symOfPurity(decl.purity))));
}

bool hasPrivateFields(in StructBody.Record a) =>
	exists!RecordField(a.fields, (in RecordField x) {
		final switch (x.visibility) {
			case Visibility.public_:
				return false;
			case Visibility.private_:
				return true;
		}
	});

Repr documentUnion(ref Alloc alloc, in StructDecl decl, in StructBody.Union a) {
	ArrBuilder!NameAndRepr fields;
	maybeAddPurity(alloc, fields, decl);
	add(alloc, fields, nameAndRepr!"members"(reprArr!UnionMember(alloc, a.members, (in UnionMember member) =>
		documentUnionMember(alloc, member))));
	return reprNamedRecord!"union"(finishArr(alloc, fields));
}

Opt!Repr documentRecordField(ref Alloc alloc, in RecordField a) {
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

Repr documentUnionMember(ref Alloc alloc, in UnionMember a) {
	ArrBuilder!NameAndRepr fields;
	add(alloc, fields, nameAndRepr!"name"(reprSym(a.name)));
	if (has(a.type))
		add(alloc, fields, nameAndRepr!"type"(documentTypeRef(alloc, force(a.type))));
	return reprNamedRecord!"member"(finishArr(alloc, fields));
}

DocExport documentSpec(ref Alloc alloc, in SpecDecl a) =>
	documentExport(alloc, a.range, a.name, a.docComment, a.typeParams, reprNamedRecord!"spec"(alloc, [
		nameAndRepr!"body"(a.body_.matchIn!Repr(
			(in SpecBody.Builtin) =>
				reprNamedRecord!"builtin"(alloc, []),
			(in SpecDeclSig[] sigs) =>
				reprNamedRecord!"sigs"(alloc, [
					nameAndRepr!"sigs"(reprArr!SpecDeclSig(alloc, sigs, (in SpecDeclSig sig) =>
						documentSpecDeclSig(alloc, sig)))])))]));

Repr documentSpecDeclSig(ref Alloc alloc, in SpecDeclSig a) {
	ArrBuilder!NameAndRepr fields;
	if (!safeCStrIsEmpty(a.docComment))
		add(alloc, fields, nameAndRepr!"comment"(reprStr(a.docComment)));
	add(alloc, fields, nameAndRepr!"name"(reprSym(a.name)));
	add(alloc, fields, nameAndRepr!"return-type"(documentTypeRef(alloc, a.returnType)));
	add(alloc, fields, nameAndRepr!"params"(reprArr!Param(alloc, paramsArray(a.params), (in Param x) =>
		documentParam(alloc, x))));
	return reprNamedRecord!"sig"(finishArr(alloc, fields));
}

DocExport documentFun(ref Alloc alloc, in FunDecl a) {
	ArrBuilder!NameAndRepr fields;
	add(alloc, fields, nameAndRepr!"return-type"(documentTypeRef(alloc, a.returnType)));
	add(alloc, fields, nameAndRepr!"params"(reprArr!Param(alloc, paramsArray(a.params), (in Param x) =>
		documentParam(alloc, x))));
	if (isVariadic(a))
		add(alloc, fields, nameAndRepr!"variadic"(reprBool(true)));
	Repr[] specs = documentSpecs(alloc, a);
	if (!empty(specs))
		add(alloc, fields, nameAndRepr!"specs"(reprArr(specs)));
	Repr value = reprNamedRecord!"fun"(finishArr(alloc, fields));
	return documentExport(alloc, a.range, a.name, a.docComment, a.typeParams, value);
}

Repr[] documentSpecs(ref Alloc alloc, in FunDecl a) {
	ArrBuilder!Repr res;
	if (summon(a))
		add(alloc, res, reprSpecialSpec(alloc, sym!"summon"));
	if (unsafe(a))
		add(alloc, res, reprSpecialSpec(alloc, sym!"unsafe"));
	if (noCtx(a))
		add(alloc, res, reprSpecialSpec(alloc, sym!"noctx"));
	foreach (SpecInst* spec; a.specs)
		add(alloc, res, documentSpecInst(alloc, *spec));
	return finishArr(alloc, res);
}

Repr reprSpecialSpec(ref Alloc alloc, Sym name) =>
	reprNamedRecord!"special"(alloc, [nameAndRepr!"name"(reprSym(name))]);

Repr documentParam(ref Alloc alloc, in Param a) =>
	reprNamedRecord!"param"(alloc, [
		nameAndRepr!"name"(reprSym(a.nameOrUnderscore)),
		nameAndRepr!"type"(documentTypeRef(alloc, a.type))]);

Repr documentTypeRef(ref Alloc alloc, Type a) =>
	a.matchIn!Repr(
		(in Type.Bogus) =>
			unreachable!Repr,
		(in TypeParam x) =>
			reprNamedRecord!"type-param"(alloc, [nameAndRepr!"name"(reprSym(x.name))]),
		(in StructInst x) =>
			documentStructInst(alloc, x));

Repr documentSpecInst(ref Alloc alloc, in SpecInst a) =>
	documentNameAndTypeArgs(alloc, sym!"spec", name(a), typeArgs(a));

Repr documentStructInst(ref Alloc alloc, in StructInst a) =>
	documentNameAndTypeArgs(alloc, sym!"struct", name(a), typeArgs(a));

Repr documentNameAndTypeArgs(ref Alloc alloc, Sym nodeType, Sym name, scope Type[] typeArgs) =>
	empty(typeArgs)
		? reprNamedRecord(alloc, nodeType, [nameAndRepr!"name"(reprSym(name))])
		: reprNamedRecord(alloc, nodeType, [
			nameAndRepr!"name"(reprSym(name)),
			nameAndRepr!"type-args"(reprArr!Type(alloc, typeArgs, (in Type typeArg) =>
				documentTypeRef(alloc, typeArg)))]);

Repr documentTypeParams(ref Alloc alloc, scope TypeParam[] xs) {
	verify(!empty(xs));
	return reprArr!TypeParam(alloc, xs, (in TypeParam x) =>
		reprNamedRecord!"type-param"(alloc, [nameAndRepr!"name"(reprSym(x.name))]));
}

void eachLine(string a, in void delegate(string) @safe @nogc pure nothrow cb) {
	Opt!size_t index = indexOf(a, '\n');
	if (has(index)) {
		cb(a[0..force(index)]);
		eachLine(a[force(index)+1 .. $], cb);
	} else
		cb(a);
}
