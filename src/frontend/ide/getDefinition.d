module frontend.ide.getDefinition;

@safe @nogc pure nothrow:

import frontend.ide.getPosition : Position;
import model.model : decl, Expr, FunDecl, Program, SpecDecl, StructDecl, StructInst, Type, TypeParam;
import util.alloc.alloc : Alloc;
import util.opt : none, Opt, some;
import util.path : AllPaths, Path, pathToSafeCStr;
import util.json : field, Json, jsonObject;
import util.sourceRange : FileAndRange, jsonOfRangeWithinFile, RangeWithinFile;

immutable struct Definition {
	Path path;
	RangeWithinFile range;
}

Json jsonOfDefinition(ref Alloc alloc, in AllPaths allPaths, in Definition a) =>
	jsonObject(alloc, [
		field!"path"(pathToSafeCStr(alloc, allPaths, a.path)),
		field!"range"(jsonOfRangeWithinFile(alloc, a.range))]);

Opt!Definition getDefinitionForPosition(in Program program, in Position pos) =>
	pos.matchIn!(Opt!Definition)(
		(in Expr x) =>
			getExprDefinition(program, x),
		(in FunDecl x) =>
			toDefinition(program, x.range),
		(in Position.ImportedModule x) =>
			toDefinition(program, x.module_.range),
		(in Position.ImportedName x) =>
			// TODO: get the declaration
			none!Definition,
		(in Position.Parameter x) =>
			toDefinition(program, x.local.range),
		(in Position.RecordFieldPosition x) =>
			toDefinition(program, x.field.range),
		(in SpecDecl x) =>
			toDefinition(program, x.range),
		(in StructDecl x) =>
			toDefinition(program, x.range),
		(in Type x) =>
			x.matchIn!(Opt!Definition)(
				(in Bogus) =>
					none!Definition,
				(in TypeParam x) =>
					toDefinition(program, x.range),
				(in StructInst x) =>
					toDefinition(program, decl(x).range)),
		(in TypeParam x) =>
			toDefinition(program, x.range));

private:

Opt!Definition toDefinition(in Program program, FileAndRange range) =>
	some(Definition(program.filesInfo.filePaths[range.fileIndex], range.range));

Opt!Definition getExprDefinition(in Program program, in Expr x) =>
	// TODO
	none!Definition;
