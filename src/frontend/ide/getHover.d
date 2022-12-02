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

SafeCStr getHoverStr(
	ref TempAlloc tempAlloc,
	ref Alloc alloc,
	in AllSymbols allSymbols,
	in AllPaths allPaths,
	in PathsInfo pathsInfo,
	in Program program,
	in Position pos,
) {
	Writer writer = Writer(ptrTrustMe(alloc));
	getHover(tempAlloc, writer, allSymbols, allPaths, pathsInfo, program, pos);
	return finishWriterToSafeCStr(writer);
}

void getHover(
	ref TempAlloc tempAlloc,
	scope ref Writer writer,
	in AllSymbols allSymbols,
	in AllPaths allPaths,
	in PathsInfo pathsInfo,
	in Program program,
	in Position pos,
) =>
	pos.matchIn!void(
		(in Expr it) {
			getExprHover(writer, it);
		},
		(in FunDecl it) {
			writer ~= "fun ";
			writeSym(writer, allSymbols, it.name);
		},
		(in Position.ImportedModule it) {
			writer ~= "import module ";
			writeFile(writer, allPaths, pathsInfo, program.filesInfo, it.module_.fileIndex);
		},
		(in Position.ImportedName it) {
			getImportedNameHover(writer, it);
		},
		(in Param it) {
			writer ~= "param ";
			writeSym(writer, allSymbols, it.nameOrUnderscore);
		},
		(in Position.RecordFieldPosition it) {
			writer ~= "field ";
			writeStructDecl(writer, allSymbols, *it.struct_);
			writer ~= '.';
			writeSym(writer, allSymbols, it.field.name);
			writer ~= " (";
			writeTypeUnquoted(writer, allSymbols, it.field.type);
			writer ~= ')';
		},
		(in SpecDecl _) {
			writer ~= "TODO: spec hover";
		},
		(in StructDecl it) {
			writer ~= body_(it).matchIn!string(
				(in StructBody.Bogus) =>
					"type ",
				(in StructBody.Builtin) =>
					"builtin type ",
				(in StructBody.Enum) =>
					"enum type ",
				(in StructBody.Extern) =>
					"extern type ",
				(in StructBody.Flags) =>
					"flags type ",
				(in StructBody.Record) =>
					"record ",
				(in StructBody.Union) =>
					"union ");
			writeSym(writer, allSymbols, it.name);
		},
		(in Type a) {
			writer ~= "TODO: hover for type";
		},
		(in TypeParam _) {
			writer ~= "TODO: hover for type param";
		});

private:

void getImportedNameHover(ref Writer writer, in Position.ImportedName) {
	writer ~= "TODO: getImportedNameHover";
}

void getExprHover(ref Writer writer, in Expr) {
	writer ~= "TODO: getExprHover";
}

