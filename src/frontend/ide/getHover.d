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
	Param,
	Program,
	SpecDecl,
	StructBody,
	Type,
	TypeParam,
	writeStructDecl,
	writeTypeUnquoted;
import util.alloc.alloc : Alloc, TempAlloc;
import util.col.str : SafeCStr;
import util.path : AllPaths, PathsInfo;
import util.ptr : ptrTrustMe_mut;
import util.sym : AllSymbols, writeSym;
import util.writer : finishWriterToSafeCStr, writeChar, Writer, writeStatic;

immutable(SafeCStr) getHoverStr(
	ref TempAlloc tempAlloc,
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	ref immutable Program program,
	ref immutable Position pos,
) {
	Writer writer = Writer(ptrTrustMe_mut(alloc));
	getHover(tempAlloc, writer, allSymbols, allPaths, pathsInfo, program, pos);
	return finishWriterToSafeCStr(writer);
}

void getHover(
	ref TempAlloc tempAlloc,
	scope ref Writer writer,
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	ref immutable Program program,
	ref immutable Position pos,
) {
	return matchPosition!void(
		pos,
		(ref immutable Expr it) {
			getExprHover(writer, it);
		},
		(ref immutable FunDecl it) {
			writeStatic(writer, "fun ");
			writeSym(writer, allSymbols, it.name);
		},
		(ref immutable Position.ImportedModule it) {
			writeStatic(writer, "import module ");
			writeFile(writer, allPaths, pathsInfo, program.filesInfo, it.module_.fileIndex);
		},
		(ref immutable Position.ImportedName it) {
			getImportedNameHover(writer, it);
		},
		(ref immutable Param it) {
			writeStatic(writer, "param ");
			writeSym(writer, allSymbols, it.nameOrUnderscore);
		},
		(ref immutable Position.RecordFieldPosition it) {
			writeStatic(writer, "field ");
			writeStructDecl(writer, allSymbols, *it.struct_);
			writeChar(writer, '.');
			writeSym(writer, allSymbols, it.field.name);
			writeStatic(writer, " (");
			writeTypeUnquoted(writer, allSymbols, it.field.type);
			writeChar(writer, ')');
		},
		(ref immutable SpecDecl) {
			writeStatic(writer, "TODO: spec hover");
		},
		(ref immutable StructDecl it) {
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
			writeSym(writer, allSymbols, it.name);
		},
		(ref immutable Type a) {
			writeStatic(writer, "TODO: hover for type");
		},
		(ref immutable(TypeParam)) {
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

