module frontend.getHover;

@safe @nogc pure nothrow:

import frontend.getPosition : matchPosition, Position;
import model.diag : writeFile;
import model.model :
	body_,
	Expr,
	FunDecl,
	StructDecl,
	matchStructBody,
	name,
	NameAndReferents,
	Program,
	SpecDecl,
	StructBody;
import util.collection.str : Str;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.sym : writeSym;
import util.writer : finishWriter, Writer, writeStatic;

immutable(Str) getHoverStr(TempAlloc, Alloc)(
	ref TempAlloc tempAlloc,
	ref Alloc alloc,
	ref immutable Program program,
	ref immutable Position pos,
) {
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	getHover(tempAlloc, writer, program, pos);
	return finishWriter(writer);
}

void getHover(TempAlloc, Alloc)(
	ref TempAlloc tempAlloc,
	ref Writer!Alloc writer,
	ref immutable Program program,
	ref immutable Position pos,
) {
	return matchPosition!void(
		pos,
		(immutable Ptr!Expr it) {
			getExprHover(writer, it);
		},
		(immutable Ptr!FunDecl it) {
			writeStatic(writer, "fun ");
			writeSym(writer, name(it));
		},
		(ref immutable Position.ImportedModule it) {
			writeStatic(writer, "import module ");
			writeFile(tempAlloc, writer, program.filesInfo, it.import_.module_.fileIndex);
		},
		(ref immutable Position.ImportedName it) {
			getNameAndReferentsHover(writer, it.name_);
		},
		(immutable Ptr!SpecDecl) {
			writeStatic(writer, "TODO: spec hover");
		},
		(immutable Ptr!StructDecl it) {
			matchStructBody!void(
				body_(it),
				(ref immutable StructBody.Bogus) {
					writeStatic(writer, "type ");
				},
				(ref immutable StructBody.Builtin) {
					writeStatic(writer, "builtin type ");
				},
				(ref immutable StructBody.ExternPtr) {
					writeStatic(writer, "extern type ");
				},
				(ref immutable StructBody.Record) {
					writeStatic(writer, "record ");
				},
				(ref immutable StructBody.Union) {
					writeStatic(writer, "union ");
				});
			writeSym(writer, it.name);
		});
}

private:

void getNameAndReferentsHover(Alloc)(ref Writer!Alloc writer, ref immutable NameAndReferents) {
	writeStatic(writer, "TODO: getNameAndReferentsHover");
}

void getExprHover(Alloc)(ref Writer!Alloc writer, ref immutable Expr) {
	writeStatic(writer, "TODO: getExprHover");
}

