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
	Local,
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
import util.col.arrUtil : first;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : hasPos, Pos, RangeWithinFile;
import util.sym : AllSymbols, Sym, symSize;
import util.union_ : Union;

immutable struct Position {
	Module* module_;
	PositionKind kind;
}

immutable struct PositionKind {
	immutable struct None {}

	immutable struct ImportedModule {
		ImportOrExport* import_;
		Module* module_;
	}
	immutable struct ImportedName {
		ImportOrExport* import_;
		Sym name;
	}
	immutable struct Parameter {
		Local* local;
	}
	immutable struct RecordFieldPosition {
		StructDecl* struct_;
		RecordField* field;
	}

	mixin Union!(
		None,
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

Position getPosition(in AllSymbols allSymbols, Module* module_, Pos pos) {
	Opt!PositionKind kind = getPositionKind(allSymbols, *module_, pos);
	return Position(module_, has(kind) ? force(kind) : PositionKind(PositionKind.None()));
}

private:

Opt!PositionKind getPositionKind(in AllSymbols allSymbols, ref Module module_, Pos pos) {
	Opt!PositionKind fromImports = positionInImportsOrExports(allSymbols, module_.imports, pos);
	if (has(fromImports))
		return fromImports;
	Opt!PositionKind fromExports = positionInImportsOrExports(allSymbols, module_.reExports, pos);
	if (has(fromExports))
		return fromExports;

	foreach (StructDecl* s; ptrsRange(module_.structs))
		if (hasPos(s.range.range, pos))
			return some(positionInStruct(allSymbols, s, pos));

	foreach (SpecDecl* s; ptrsRange(module_.specs))
		if (hasPos(s.range.range, pos))
			//TODO: delve inside!
			return some(PositionKind(s));

	foreach (FunDecl* f; ptrsRange(module_.funs)) {
		Opt!PositionKind fromFun = positionInFun(f, pos, allSymbols);
		if (has(fromFun))
			return fromFun;
	}

	return none!PositionKind;

	//TODO: check for aliases too
}

Opt!PositionKind positionInFun(FunDecl* a, Pos pos, in AllSymbols allSymbols) {
	RangeWithinFile nameRange = a.nameRange(allSymbols);
	if (hasPos(nameRange, pos))
		return some(PositionKind(a));

	Destructure[] params = paramsArray(a.params);
	//TODO: have a way to get return type range if there are no parameters
	if (!empty(params) && betweenRanges(nameRange, pos, params[0].range))
		return some(PositionKind(a.returnType));
	foreach (Destructure x; params) {
		Opt!PositionKind res = positionInParameterDestructure(allSymbols, pos, x);
		if (has(res))
			return res;
	}
	// TODO: specs
	return a.body_.match!(Opt!PositionKind)(
		(FunBody.Bogus) =>
			none!PositionKind,
		(FunBody.Builtin) =>
			none!PositionKind,
		(FunBody.CreateEnum) =>
			none!PositionKind,
		(FunBody.CreateExtern) =>
			none!PositionKind,
		(FunBody.CreateRecord) =>
			none!PositionKind,
		(FunBody.CreateUnion) =>
			none!PositionKind,
		(EnumFunction _) =>
			none!PositionKind,
		(FunBody.Extern) =>
			none!PositionKind,
		(FunBody.ExpressionBody x) =>
			positionInExpr(x.expr),
		(FunBody.FileBytes) =>
			none!PositionKind,
		(FlagsFunction _) =>
			none!PositionKind,
		(FunBody.RecordFieldGet) =>
			none!PositionKind,
		(FunBody.RecordFieldPointer) =>
			none!PositionKind,
		(FunBody.RecordFieldSet) =>
			none!PositionKind,
		(FunBody.VarGet) =>
			none!PositionKind,
		(FunBody.VarSet) =>
			none!PositionKind);
}

Opt!PositionKind positionInParameterDestructure(in AllSymbols allSymbols, Pos pos, in Destructure a) =>
	a.matchWithPointers!(Opt!PositionKind)(
		(Destructure.Ignore*) =>
			none!PositionKind,
		(Local* x) =>
			hasPos(x.range.range, pos)
				? hasPos(x.nameRange(allSymbols), pos)
					? some(PositionKind(PositionKind.Parameter(x)))
					: some(PositionKind(x.type))
				: none!PositionKind,
		(Destructure.Split* x) =>
			//TODO: handle x.destructuredType
			first!(PositionKind, Destructure)(x.parts, (Destructure part) =>
				positionInParameterDestructure(allSymbols, pos, part)));

Opt!PositionKind positionInImportsOrExports(in AllSymbols allSymbols, ImportOrExport[] importsOrExports, Pos pos) {
	foreach (ImportOrExport* im; ptrsRange(importsOrExports))
		if (has(im.importSource) && hasPos(force(im.importSource), pos))
			return im.kind.match!(Opt!PositionKind)(
				(ImportOrExportKind.ModuleWhole m) =>
					some(PositionKind(PositionKind.ImportedModule(im, m.modulePtr))),
				(ImportOrExportKind.ModuleNamed m) {
					Pos namePos = force(im.importSource).start;
					foreach (Sym name; m.names) {
						Pos nameEnd = namePos + symSize(allSymbols, name);
						if (pos < nameEnd)
							return some(PositionKind(PositionKind.ImportedName(im, name)));
						namePos = nameEnd + 1;
					}
					return some(PositionKind(PositionKind.ImportedModule(im, m.modulePtr)));
				});
	return none!PositionKind;
}

PositionKind positionInStruct(in AllSymbols allSymbols, StructDecl* a, Pos pos) {
	//TODO: look through type params!

	Opt!PositionKind specific = body_(*a).match!(Opt!PositionKind)(
		(StructBody.Bogus) =>
			none!PositionKind,
		(StructBody.Builtin) =>
			none!PositionKind,
		(StructBody.Enum) =>
			none!PositionKind, // TODO
		(StructBody.Extern) =>
			none!PositionKind,
		(StructBody.Flags) =>
			none!PositionKind, // TODO
		(StructBody.Record it) {
			foreach (RecordField* field; ptrsRange(it.fields))
				if (hasPos(field.range.range, pos))
					return nameHasPos(allSymbols, field.range.start, field.name, pos)
						? some(PositionKind(PositionKind.RecordFieldPosition(a, field)))
						: positionOfType(field.type);
			return none!PositionKind;
		},
		(StructBody.Union) =>
			//TODO
			none!PositionKind);
	return has(specific) ? force(specific) : PositionKind(a);
}

Opt!PositionKind positionOfType(Type a) =>
	a.matchWithPointers!(Opt!PositionKind)(
		(Type.Bogus) =>
			none!PositionKind,
		(TypeParam* x) =>
			some(PositionKind(x)),
		(StructInst* x) =>
			some(PositionKind(decl(*x))));

Opt!PositionKind positionInExpr(in Expr a) {
	if (!hasPos(x.expr.range.range, pos))
		return none!PositionKind;
	else {
		a.matchIn!(Opt!PositionKind)(
			
		)
		some(PositionKind(x.expr));
	}
}

bool nameHasPos(in AllSymbols allSymbols, Pos start, Sym name, Pos pos) =>
	start <= pos && pos < start + symSize(allSymbols, name);

bool betweenRanges(RangeWithinFile left, Pos pos, RangeWithinFile right) =>
	left.end <= pos && pos < right.start;
