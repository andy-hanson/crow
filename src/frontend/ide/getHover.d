module frontend.ide.getHover;

@safe @nogc pure nothrow:

import frontend.ide.getPosition : matchPosition, Position;
import model.diag : writeFile;
import model.model :
	body_,
	Expr,
	FunDecl,
	StructDecl,
	matchStructBody,
	name,
	Program,
	SpecDecl,
	StructBody,
	TypeParam,
	writeStructDecl,
	writeType;
import util.alloc.alloc : Alloc, TempAlloc;
import util.path : AllPaths;
import util.ptr : Ptr, ptrTrustMe_mut;
import util.sym : writeSym;
import util.writer : finishWriter, writeChar, Writer, writeStatic;

immutable(string) getHoverStr(
	ref TempAlloc tempAlloc,
	ref Alloc alloc,
	ref const AllPaths allPaths,
	ref immutable Program program,
	ref immutable Position pos,
) {
	Writer writer = Writer(ptrTrustMe_mut(alloc));
	getHover(tempAlloc, writer, allPaths, program, pos);
	return finishWriter(writer);
}

void getHover(
	ref TempAlloc tempAlloc,
	ref Writer writer,
	ref const AllPaths allPaths,
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
			writeFile(writer, allPaths, program.filesInfo, it.import_.module_.fileIndex);
		},
		(ref immutable Position.ImportedName it) {
			getImportedNameHover(writer, it);
		},
		(ref immutable Position.RecordFieldPosition it) {
			writeStatic(writer, "field ");
			writeStructDecl(writer, it.struct_);
			writeChar(writer, '.');
			writeSym(writer, it.field.name);
			writeStatic(writer, " (");
			writeType(writer, it.field.type);
			writeChar(writer, ')');
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
				(ref immutable StructBody.Enum) {
					writeStatic(writer, "enum type ");
				},
				(ref immutable StructBody.Flags) {
					writeStatic(writer, "flags type ");
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
		},
		(immutable Ptr!TypeParam) {
			writeStatic(writer, "TODO: type param");
		});
}

private:

void getImportedNameHover(ref Writer writer, ref immutable Position.ImportedName) {
	writeStatic(writer, "TODO: getImportedNameHover");
}

void getExprHover(ref Writer writer, ref immutable Expr) {
	writeStatic(writer, "TODO: getExprHover");
}

