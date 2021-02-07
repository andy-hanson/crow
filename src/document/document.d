module document.document;

@safe @nogc pure nothrow:

import model.model :
	FunDecl,
	matchType,
	Module,
	name,
	NameReferents,
	Param,
	params,
	Program,
	returnType,
	SpecDecl,
	StructInst,
	StructOrAlias,
	Type,
	typeArgs,
	TypeParam;
import util.collection.arr : empty, only, size;
import util.collection.dict : dictEach;
import util.collection.fullIndexDict : fullIndexDictGet;
import util.opt : force, has, Opt;
import util.path : AllPaths, eachPathPart, PathAndStorageKind;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.sourceRange : FileIndex, FilePaths;
import util.sym : compareSym, Sym, writeSym;
import util.util : todo, unreachable;
import util.writer : finishWriter, Writer, writeChar, writeStatic, writeWithCommas;

immutable(string) document(Alloc, PathAlloc)(
	ref Alloc alloc,
	ref const AllPaths!PathAlloc allPaths,
	ref immutable Program p,
	ref immutable Module a,
) {
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));

	writeStatic(writer, "../pug-include/documentation.pug\n");
	writeStatic(writer, "+documentationPage(\"");
	writeModulePath(writer, allPaths, p.filesInfo.filePaths, a.fileIndex);
	writeStatic(writer, "\")\n");
	writeStatic(writer, "\tsection");
	dictEach!(Sym, NameReferents, compareSym)(
		a.allExportedNames,
		(ref immutable Sym name, ref immutable NameReferents referents) {
			if (has(referents.structOrAlias))
				writeStructOrAlias(writer, force(referents.structOrAlias));
			if (has(referents.spec))
				writeSpec(writer, force(referents.spec));
			foreach (immutable Ptr!FunDecl fun; referents.funs)
				writeFun(writer, fun);
		});
	writeStatic(writer, "\n");
	return finishWriter(writer);
}

private:

void writeModulePath(Alloc, PathAlloc)(
	ref Writer!Alloc writer,
	ref const AllPaths!PathAlloc allPaths,
	ref immutable FilePaths filePaths,
	immutable FileIndex fileIndex,
) {
	immutable PathAndStorageKind where = fullIndexDictGet(filePaths, fileIndex);
	bool first = true;
	eachPathPart(allPaths, where.path, (immutable string part) {
		if (first)
			first = false;
		else
			writeChar(writer, '.');
		writeStatic(writer, part);
	});
}

void writeStructOrAlias(Alloc)(ref Writer!Alloc writer, ref immutable StructOrAlias a) {
	todo!void("!");
}

void writeSpec(Alloc)(ref Writer!Alloc writer, ref immutable SpecDecl a) {
	todo!void("!");
}

void writeFun(Alloc)(ref Writer!Alloc writer, ref immutable FunDecl a) {
	writeStatic(writer, "\n\t\t+function(");
	writeQuotedSym(writer, name(a));
	writeStatic(writer, ", ");
	writeQuotedType(writer, returnType(a));
	writeStatic(writer, ", [");
	writeWithCommas!(Param, Alloc)(writer, params(a), (ref immutable Param it) {
		writeChar(writer, '[');
		writeQuotedOptSym(writer, it.name);
		writeStatic(writer, ", ");
		writeQuotedType(writer, it.type);
		writeChar(writer, ']');
	});
	writeStatic(writer, "])");
	writeStatic(writer, "\n\t\t\t| Docstring goes here");
}

void writeQuotedOptSym(Alloc)(ref Writer!Alloc writer, ref immutable Opt!Sym a) {
	if (has(a))
		writeQuotedSym(writer, force(a));
	else
		writeStatic(writer, "\"_\"");
}

void writeQuotedSym(Alloc)(ref Writer!Alloc writer, immutable Sym a) {
	writeChar(writer, '\"');
	writeSym(writer, a);
	writeChar(writer, '\"');
}

void writeQuotedType(Alloc)(ref Writer!Alloc writer, ref immutable Type a) {
	writeChar(writer, '\"');
	writeType(writer, a);
	writeChar(writer, '\"');
}

void writeType(Alloc)(ref Writer!Alloc writer, ref immutable Type a) {
	matchType!void(
		a,
		(ref immutable Type.Bogus) {
			unreachable!void();
		},
		(immutable Ptr!TypeParam it) {
			writeChar(writer, '?');
			writeSym(writer, it.name);
		},
		(immutable Ptr!StructInst it) {
			writeSym(writer, it.name);
			immutable Type[] typeArgs = typeArgs(it);
			if (!empty(typeArgs)) {
				if (size(typeArgs) == 1) {
					writeChar(writer, ' ');
					writeType(writer, only(typeArgs));
				} else {
					writeChar(writer, '<');
					writeWithCommas!Type(writer, typeArgs, (ref immutable Type t) {
						writeType(writer, t);
					});
					writeChar(writer, '>');
				}
			}
		});
}
