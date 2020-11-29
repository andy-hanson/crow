module frontend.getHover;

@safe @nogc pure nothrow:

import frontend.getPosition : matchPosition, Position;
import model.diag : writeFile;
import model.model : body_, Expr, FunDecl, StructDecl, matchStructBody, Program;
import util.sym : writeSym;
import util.util : todo;
import util.writer : Writer, writeStatic;

void getHover(TempAlloc, Alloc)(
	ref TempAlloc tempAlloc,
	ref Writer!Alloc writer,
	ref immutable Program program,
	ref immutable Position pos,
) {
	return matchPosition!void(
		(immutable Ptr!Expr it) {
			getExprHover(writer, it);
		},
		(immutable Ptr!FunDecl it) {
			writeStatic(writer, "fun ");
			writeSym(writer, it.name);
		},
		(ref immutable Position.ImportedModule it) {
			writeStatic("import module ");
			writeFile(tempAlloc, writer, program.filesInfo, it.import_.module_.fileIndex);
		},
		(ref immutable Position.ImportedName it) {
			writeNameAndReferents(writer, it);
		},
		(immutable Ptr!SpecDecl) {
			writeStatic(writer, "spec ");
			todo!void("!");
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

void getNameAndReferentsHover(Alloc)(ref Writer!Alloc, ref immutable NameAndReferents) {
	todo!void("getNameAndReferentsHover");
}

void getExprHover(Alloc)(ref Writer!Alloc, immutable Ptr!Expr) {
	todo!void("getExprHover");
}

