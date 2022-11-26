module frontend.ide.getPosition;

@safe @nogc pure nothrow:

import model.model :
	body_,
	decl,
	EnumFunction,
	Expr,
	FlagsFunction,
	FunBody,
	FunDecl,
	ImportOrExport,
	ImportOrExportKind,
	Module,
	Param,
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

struct Position {
	struct ImportedModule {
		immutable ImportOrExport* import_;
		immutable Module* module_;
	}
	struct ImportedName {
		immutable ImportOrExport* import_;
		immutable Sym name;
	}
	struct RecordFieldPosition {
		immutable StructDecl* struct_;
		immutable RecordField* field;
	}

	mixin Union!(
		immutable Expr,
		immutable FunDecl*,
		immutable ImportedModule,
		immutable ImportedName,
		immutable Param*,
		immutable RecordFieldPosition,
		immutable SpecDecl*,
		immutable StructDecl*,
		immutable Type,
		immutable TypeParam*);
}

immutable(Opt!Position) getPosition(ref const AllSymbols allSymbols, ref immutable Module module_, immutable Pos pos) {
	immutable Opt!Position fromImports = positionInImportsOrExports(allSymbols, module_.imports, pos);
	if (has(fromImports))
		return fromImports;
	immutable Opt!Position fromExports = positionInImportsOrExports(allSymbols, module_.reExports, pos);
	if (has(fromExports))
		return fromExports;

	foreach (immutable StructDecl* s; ptrsRange(module_.structs))
		if (hasPos(s.range.range, pos))
			return some(positionInStruct(allSymbols, s, pos));

	foreach (immutable SpecDecl* s; ptrsRange(module_.specs))
		if (hasPos(s.range.range, pos))
			//TODO: delve inside!
			return some(immutable Position(s));

	foreach (immutable FunDecl* f; ptrsRange(module_.funs)) {
		immutable Opt!Position fromFun = positionInFun(f, pos, allSymbols);
		if (has(fromFun))
			return fromFun;
	}

	return none!Position;

	//TODO: check for aliases too
}

private:

immutable(Opt!Position) positionInFun(immutable FunDecl* a, immutable Pos pos, ref const AllSymbols allSymbols) {
	immutable RangeWithinFile nameRange = a.nameRange(allSymbols);
	if (hasPos(nameRange, pos))
		return some(immutable Position(a));

	immutable Param[] params = paramsArray(a.params);
	//TODO: have a way to get return type range if there are no parameters
	if (!empty(params) && betweenRanges(nameRange, pos, params[0].range.range))
		return some(immutable Position(a.returnType));
	foreach (immutable Param* x; ptrsRange(params))
		if (hasPos(x.range.range, pos))
			return some(hasPos(x.nameRange(allSymbols), pos)
				? immutable Position(x)
				: immutable Position(x.type));
	// TODO: specs
	return a.body_.match!(immutable Opt!Position)(
		(immutable FunBody.Bogus) =>
			none!Position,
		(immutable FunBody.Builtin) =>
			none!Position,
		(immutable FunBody.CreateEnum) =>
			none!Position,
		(immutable FunBody.CreateExtern) =>
			none!Position,
		(immutable FunBody.CreateRecord) =>
			none!Position,
		(immutable FunBody.CreateUnion) =>
			none!Position,
		(immutable(EnumFunction)) =>
			none!Position,
		(immutable FunBody.Extern) =>
			none!Position,
		(immutable Expr x) =>
			hasPos(x.range.range, pos)
				//TODO: delve inside!
				? some(immutable Position(x))
				: none!Position,
		(immutable(FunBody.FileBytes)) =>
			none!Position,
		(immutable(FlagsFunction)) =>
			none!Position,
		(immutable FunBody.RecordFieldGet) =>
			none!Position,
		(immutable FunBody.RecordFieldSet) =>
			none!Position,
		(immutable FunBody.ThreadLocal) =>
			none!Position);
}

immutable(Opt!Position) positionInImportsOrExports(
	ref const AllSymbols allSymbols,
	immutable ImportOrExport[] importsOrExports,
	immutable Pos pos,
) {
	foreach (immutable ImportOrExport* im; ptrsRange(importsOrExports))
		if (has(im.importSource) && hasPos(force(im.importSource), pos))
			return im.kind.match!(immutable Opt!Position)(
				(immutable ImportOrExportKind.ModuleWhole m) =>
					some(immutable Position(immutable Position.ImportedModule(im, m.modulePtr))),
				(immutable ImportOrExportKind.ModuleNamed m) {
					Pos namePos = force(im.importSource).start;
					foreach (immutable Sym name; m.names) {
						immutable Pos nameEnd = namePos + symSize(allSymbols, name);
						if (pos < nameEnd)
							return some(immutable Position(immutable Position.ImportedName(im, name)));
						namePos = nameEnd + 1;
					}
					return some(immutable Position(immutable Position.ImportedModule(im, m.modulePtr)));
				});
	return none!Position;
}

immutable(Position) positionInStruct(ref const AllSymbols allSymbols, immutable StructDecl* a, immutable Pos pos) {
	//TODO: look through type params!

	immutable Opt!Position specific = body_(*a).match!(immutable Opt!Position)(
		(immutable StructBody.Bogus) =>
			none!Position,
		(immutable StructBody.Builtin) =>
			none!Position,
		(immutable StructBody.Enum) =>
			none!Position, // TODO
		(immutable StructBody.Extern) =>
			none!Position,
		(immutable StructBody.Flags) =>
			none!Position, // TODO
		(immutable StructBody.Record it) {
			foreach (immutable RecordField* field; ptrsRange(it.fields))
				if (hasPos(field.range.range, pos))
					return nameHasPos(allSymbols, field.range.start, field.name, pos)
						? some(immutable Position(immutable Position.RecordFieldPosition(a, field)))
						: positionOfType(field.type);
			return none!Position;
		},
		(immutable StructBody.Union) =>
			//TODO
			none!Position);
	return has(specific) ? force(specific) : immutable Position(a);
}

immutable(Opt!Position) positionOfType(immutable Type a) =>
	a.matchWithPointers!(immutable Opt!Position)(
		(immutable Type.Bogus) => none!Position,
		(immutable TypeParam* it) => some(immutable Position(it)),
		(immutable StructInst* it) => some(immutable Position(decl(*it))));

immutable(bool) nameHasPos(
	ref const AllSymbols allSymbols,
	immutable Pos start,
	immutable Sym name,
	immutable Pos pos,
) =>
	start <= pos && pos < start + symSize(allSymbols, name);

immutable(bool) betweenRanges(immutable RangeWithinFile left, immutable Pos pos, immutable RangeWithinFile right) =>
	left.end <= pos && pos < right.start;
