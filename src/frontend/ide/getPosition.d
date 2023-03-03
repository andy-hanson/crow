module frontend.ide.getPosition;

@safe @nogc pure nothrow:

import model.model :
	body_,
	decl,
	Destructure,
	EnumFunction,
	Expr,
	FlagsFunction,
	FunBody,
	FunDecl,
	ImportOrExport,
	ImportOrExportKind,
	Module,
	paramsArray,
	range,
	RecordField,
	SpecDecl,
	StructBody,
	StructDecl,
	StructInst,
	Type,
	TypeParam;
import util.col.arr : empty, ptrsRange;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : hasPos, Pos, RangeWithinFile;
import util.sym : AllSymbols, Sym, symSize;
import util.union_ : Union;

immutable struct Position {
	immutable struct ImportedModule {
		ImportOrExport* import_;
		Module* module_;
	}
	immutable struct ImportedName {
		ImportOrExport* import_;
		Sym name;
	}
	immutable struct Parameter {
		Destructure destructure;
	}
	immutable struct RecordFieldPosition {
		StructDecl* struct_;
		RecordField* field;
	}

	mixin Union!(
		Expr,
		FunDecl*,
		ImportedModule,
		ImportedName,
		Parameter,
		RecordFieldPosition,
		SpecDecl*,
		StructDecl*,
		Type,
		TypeParam*);
}

Opt!Position getPosition(in AllSymbols allSymbols, ref Module module_, Pos pos) {
	Opt!Position fromImports = positionInImportsOrExports(allSymbols, module_.imports, pos);
	if (has(fromImports))
		return fromImports;
	Opt!Position fromExports = positionInImportsOrExports(allSymbols, module_.reExports, pos);
	if (has(fromExports))
		return fromExports;

	foreach (StructDecl* s; ptrsRange(module_.structs))
		if (hasPos(s.range.range, pos))
			return some(positionInStruct(allSymbols, s, pos));

	foreach (SpecDecl* s; ptrsRange(module_.specs))
		if (hasPos(s.range.range, pos))
			//TODO: delve inside!
			return some(Position(s));

	foreach (FunDecl* f; ptrsRange(module_.funs)) {
		Opt!Position fromFun = positionInFun(f, pos, allSymbols);
		if (has(fromFun))
			return fromFun;
	}

	return none!Position;

	//TODO: check for aliases too
}

private:

Opt!Position positionInFun(FunDecl* a, Pos pos, in AllSymbols allSymbols) {
	RangeWithinFile nameRange = a.nameRange(allSymbols);
	if (hasPos(nameRange, pos))
		return some(Position(a));

	Destructure[] params = paramsArray(a.params);
	//TODO: have a way to get return type range if there are no parameters
	if (!empty(params) && betweenRanges(nameRange, pos, params[0].range))
		return some(Position(a.returnType));
	foreach (Destructure x; params)
		if (hasPos(x.range, pos))
			return some(optHasPos(x.nameRange(allSymbols), pos)
				? Position(Position.Parameter(x))
				: Position(x.type));
	// TODO: specs
	return a.body_.match!(Opt!Position)(
		(FunBody.Bogus) =>
			none!Position,
		(FunBody.Builtin) =>
			none!Position,
		(FunBody.CreateEnum) =>
			none!Position,
		(FunBody.CreateExtern) =>
			none!Position,
		(FunBody.CreateRecord) =>
			none!Position,
		(FunBody.CreateUnion) =>
			none!Position,
		(EnumFunction _) =>
			none!Position,
		(FunBody.Extern) =>
			none!Position,
		(FunBody.ExpressionBody x) =>
			hasPos(x.expr.range.range, pos)
				//TODO: delve inside!
				? some(Position(x.expr))
				: none!Position,
		(FunBody.FileBytes) =>
			none!Position,
		(FlagsFunction _) =>
			none!Position,
		(FunBody.RecordFieldGet) =>
			none!Position,
		(FunBody.RecordFieldSet) =>
			none!Position,
		(FunBody.VarGet) =>
			none!Position,
		(FunBody.VarSet) =>
			none!Position);
}

Opt!Position positionInImportsOrExports(in AllSymbols allSymbols, ImportOrExport[] importsOrExports, Pos pos) {
	foreach (ImportOrExport* im; ptrsRange(importsOrExports))
		if (has(im.importSource) && hasPos(force(im.importSource), pos))
			return im.kind.match!(Opt!Position)(
				(ImportOrExportKind.ModuleWhole m) =>
					some(Position(Position.ImportedModule(im, m.modulePtr))),
				(ImportOrExportKind.ModuleNamed m) {
					Pos namePos = force(im.importSource).start;
					foreach (Sym name; m.names) {
						Pos nameEnd = namePos + symSize(allSymbols, name);
						if (pos < nameEnd)
							return some(Position(Position.ImportedName(im, name)));
						namePos = nameEnd + 1;
					}
					return some(Position(Position.ImportedModule(im, m.modulePtr)));
				});
	return none!Position;
}

Position positionInStruct(in AllSymbols allSymbols, StructDecl* a, Pos pos) {
	//TODO: look through type params!

	Opt!Position specific = body_(*a).match!(Opt!Position)(
		(StructBody.Bogus) =>
			none!Position,
		(StructBody.Builtin) =>
			none!Position,
		(StructBody.Enum) =>
			none!Position, // TODO
		(StructBody.Extern) =>
			none!Position,
		(StructBody.Flags) =>
			none!Position, // TODO
		(StructBody.Record it) {
			foreach (RecordField* field; ptrsRange(it.fields))
				if (hasPos(field.range.range, pos))
					return nameHasPos(allSymbols, field.range.start, field.name, pos)
						? some(Position(Position.RecordFieldPosition(a, field)))
						: positionOfType(field.type);
			return none!Position;
		},
		(StructBody.Union) =>
			//TODO
			none!Position);
	return has(specific) ? force(specific) : Position(a);
}

Opt!Position positionOfType(Type a) =>
	a.matchWithPointers!(Opt!Position)(
		(Type.Bogus) => none!Position,
		(TypeParam* it) => some(Position(it)),
		(StructInst* it) => some(Position(decl(*it))));

bool optHasPos(Opt!RangeWithinFile range, Pos pos) =>
	has(range) && hasPos(force(range), pos);

bool nameHasPos(in AllSymbols allSymbols, Pos start, Sym name, Pos pos) =>
	start <= pos && pos < start + symSize(allSymbols, name);

bool betweenRanges(RangeWithinFile left, Pos pos, RangeWithinFile right) =>
	left.end <= pos && pos < right.start;
