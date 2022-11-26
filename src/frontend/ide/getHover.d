module frontend.ide.getHover;

@safe @nogc pure nothrow:

import frontend.ide.getPosition : Position;
import model.diag : writeFile;
import model.model :
	body_,
	Expr,
	FunDecl,
	StructDecl,
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
import util.ptr : ptrTrustMe;
import util.sym : AllSymbols, writeSym;
import util.writer : finishWriterToSafeCStr, Writer;

immutable(SafeCStr) getHoverStr(
	ref TempAlloc tempAlloc,
	ref Alloc alloc,
	ref const AllSymbols allSymbols,
	ref const AllPaths allPaths,
	ref immutable PathsInfo pathsInfo,
	ref immutable Program program,
	ref immutable Position pos,
) {
	Writer writer = Writer(ptrTrustMe(alloc));
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
) =>
	pos.match!void(
		(immutable Expr it) {
			getExprHover(writer, it);
		},
		(ref immutable FunDecl it) {
			writer ~= "fun ";
			writeSym(writer, allSymbols, it.name);
		},
		(immutable Position.ImportedModule it) {
			writer ~= "import module ";
			writeFile(writer, allPaths, pathsInfo, program.filesInfo, it.module_.fileIndex);
		},
		(immutable Position.ImportedName it) {
			getImportedNameHover(writer, it);
		},
		(ref immutable Param it) {
			writer ~= "param ";
			writeSym(writer, allSymbols, it.nameOrUnderscore);
		},
		(immutable Position.RecordFieldPosition it) {
			writer ~= "field ";
			writeStructDecl(writer, allSymbols, *it.struct_);
			writer ~= '.';
			writeSym(writer, allSymbols, it.field.name);
			writer ~= " (";
			writeTypeUnquoted(writer, allSymbols, it.field.type);
			writer ~= ')';
		},
		(ref immutable SpecDecl) {
			writer ~= "TODO: spec hover";
		},
		(ref immutable StructDecl it) {
			writer ~= body_(it).match!(immutable string)(
				(immutable StructBody.Bogus) =>
					"type ",
				(immutable StructBody.Builtin) =>
					"builtin type ",
				(immutable StructBody.Enum) =>
					"enum type ",
				(immutable StructBody.Extern) =>
					"extern type ",
				(immutable StructBody.Flags) =>
					"flags type ",
				(immutable StructBody.Record) =>
					"record ",
				(immutable StructBody.Union) =>
					"union ");
			writeSym(writer, allSymbols, it.name);
		},
		(immutable Type a) {
			writer ~= "TODO: hover for type";
		},
		(ref immutable(TypeParam)) {
			writer ~= "TODO: hover for type param";
		});

private:

void getImportedNameHover(ref Writer writer, ref immutable Position.ImportedName) {
	writer ~= "TODO: getImportedNameHover";
}

void getExprHover(ref Writer writer, ref immutable Expr) {
	writer ~= "TODO: getExprHover";
}

