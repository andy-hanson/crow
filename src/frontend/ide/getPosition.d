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
	matchFunBody,
	matchImportOrExportKind,
	matchStructBody,
	matchType,
	Module,
	Param,
	paramsArray,
	range,
	RecordField,
	Sig,
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

struct Position {
	@safe @nogc pure nothrow:

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

	@trusted immutable this(immutable Expr a) { kind = Kind.expr; expr = a; }
	@trusted immutable this(immutable FunDecl* a) { kind = Kind.funDecl; funDecl = a; }
	@trusted immutable this(immutable ImportedModule a) { kind = Kind.importedModule; importedModule = a; }
	@trusted immutable this(immutable ImportedName a) { kind = Kind.importedName; importedName = a; }
	immutable this(immutable Param* a) { kind = Kind.param; param = a; }
	@trusted immutable this(immutable RecordFieldPosition a) { kind = Kind.recordField; recordField = a; }
	@trusted immutable this(immutable SpecDecl* a) { kind = Kind.specDecl; specDecl = a; }
	@trusted immutable this(immutable StructDecl* a) { kind = Kind.structDecl; structDecl = a; }
	immutable this(immutable Type a) { kind = Kind.type; type = a; }
	@trusted immutable this(immutable TypeParam* a) { kind = Kind.typeParam; typeParam = a; }

	private:
	enum Kind {
		expr,
		funDecl,
		importedModule,
		importedName,
		param,
		recordField,
		specDecl,
		structDecl,
		type,
		typeParam,
	}
	immutable Kind kind;
	union {
		immutable Expr expr;
		immutable FunDecl* funDecl;
		immutable ImportedModule importedModule;
		immutable ImportedName importedName;
		immutable Param* param;
		immutable RecordFieldPosition recordField;
		immutable SpecDecl* specDecl;
		immutable StructDecl* structDecl;
		immutable Type type;
		immutable TypeParam* typeParam;
	}
}

@trusted immutable(T) matchPosition(T)(
	ref immutable Position a,
	scope immutable(T) delegate(ref immutable Expr) @safe @nogc pure nothrow cbExpr,
	scope immutable(T) delegate(ref immutable FunDecl) @safe @nogc pure nothrow cbFunDecl,
	scope immutable(T) delegate(ref immutable Position.ImportedModule) @safe @nogc pure nothrow cbImportedModule,
	scope immutable(T) delegate(ref immutable Position.ImportedName) @safe @nogc pure nothrow cbImportedName,
	scope immutable(T) delegate(ref immutable Param) @safe @nogc pure nothrow cbParam,
	scope immutable(T) delegate(ref immutable Position.RecordFieldPosition) @safe @nogc pure nothrow cbRecordField,
	scope immutable(T) delegate(ref immutable SpecDecl) @safe @nogc pure nothrow cbSpecDecl,
	scope immutable(T) delegate(ref immutable StructDecl) @safe @nogc pure nothrow cbStructDecl,
	scope immutable(T) delegate(ref immutable Type) @safe @nogc pure nothrow cbType,
	scope immutable(T) delegate(ref immutable TypeParam) @safe @nogc pure nothrow cbTypeParam,
) {
	final switch (a.kind) {
		case Position.Kind.expr:
			return cbExpr(a.expr);
		case Position.Kind.funDecl:
			return cbFunDecl(*a.funDecl);
		case Position.Kind.importedModule:
			return cbImportedModule(a.importedModule);
		case Position.Kind.importedName:
			return cbImportedName(a.importedName);
		case Position.Kind.param:
			return cbParam(*a.param);
		case Position.Kind.recordField:
			return cbRecordField(a.recordField);
		case Position.Kind.specDecl:
			return cbSpecDecl(*a.specDecl);
		case Position.Kind.structDecl:
			return cbStructDecl(*a.structDecl);
		case Position.Kind.type:
			return cbType(a.type);
		case Position.Kind.typeParam:
			return cbTypeParam(*a.typeParam);
	}
}

immutable(Opt!Position) getPosition(ref const AllSymbols allSymbols, ref immutable Module module_, immutable Pos pos) {
	immutable Opt!Position fromImports = positionInImportsOrExports(allSymbols, module_.imports, pos);
	if (has(fromImports))
		return fromImports;
	immutable Opt!Position fromExports = positionInImportsOrExports(allSymbols, module_.exports, pos);
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
	immutable Opt!Position fromSig = positionInSig(a.sig, pos, immutable Position(a), allSymbols);
	if (has(fromSig))
		return fromSig;
	return matchFunBody!(
		immutable Opt!Position,
		(ref immutable FunBody.Builtin) =>
			none!Position,
		(ref immutable FunBody.CreateEnum) =>
			none!Position,
		(ref immutable FunBody.CreateRecord) =>
			none!Position,
		(ref immutable FunBody.CreateUnion) =>
			none!Position,
		(immutable(EnumFunction)) =>
			none!Position,
		(ref immutable FunBody.Extern) =>
			none!Position,
		(ref immutable Expr it) =>
			hasPos(range(it).range, pos)
				//TODO: delve inside!
				? some(immutable Position(it))
				: none!Position,
		(immutable(FunBody.FileBytes)) =>
			none!Position,
		(immutable(FlagsFunction)) =>
			none!Position,
		(ref immutable FunBody.RecordFieldGet) =>
			none!Position,
		(ref immutable FunBody.RecordFieldSet) =>
			none!Position,
	)(a.body_);
}

immutable(Opt!Position) positionInSig(
	ref immutable Sig a,
	immutable Pos pos,
	immutable Position atName,
	ref const AllSymbols allSymbols,
) {
	immutable RangeWithinFile nameRange = a.nameRange(allSymbols);
	if (hasPos(nameRange, pos))
		return some(atName);

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
	return none!Position;
}

immutable(Opt!Position) positionInImportsOrExports(
	ref const AllSymbols allSymbols,
	immutable ImportOrExport[] importsOrExports,
	immutable Pos pos,
) {
	foreach (immutable ImportOrExport* im; ptrsRange(importsOrExports)) {
		if (has(im.importSource) && hasPos(force(im.importSource), pos)) {
			return matchImportOrExportKind!(immutable Opt!Position)(
				im.kind,
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
		}
	}
	return none!Position;
}

immutable(Position) positionInStruct(ref const AllSymbols allSymbols, immutable StructDecl* a, immutable Pos pos) {
	//TODO: look through type params!

	immutable Opt!Position specific = matchStructBody!(immutable Opt!Position)(
		body_(*a),
		(ref immutable StructBody.Bogus) =>
			none!Position,
		(ref immutable StructBody.Builtin) =>
			none!Position,
		(ref immutable StructBody.Enum) =>
			none!Position, // TODO
		(ref immutable StructBody.Flags) =>
			none!Position, // TODO
		(ref immutable StructBody.ExternPtr) =>
			none!Position,
		(ref immutable StructBody.Record it) {
			foreach (immutable RecordField* field; ptrsRange(it.fields))
				if (hasPos(field.range.range, pos))
					return nameHasPos(allSymbols, field.range.start, field.name, pos)
						? some(immutable Position(immutable Position.RecordFieldPosition(a, field)))
						: positionOfType(field.type);
			return none!Position;
		},
		(ref immutable StructBody.Union) =>
			//TODO
			none!Position);
	return has(specific) ? force(specific) : immutable Position(a);
}

immutable(Opt!Position) positionOfType(immutable Type a) {
	return matchType!(immutable Opt!Position)(
		a,
		(immutable Type.Bogus) => none!Position,
		(immutable TypeParam* it) => some(immutable Position(it)),
		(immutable StructInst* it) => some(immutable Position(decl(*it))));
}

immutable(bool) nameHasPos(
	ref const AllSymbols allSymbols,
	immutable Pos start,
	immutable Sym name,
	immutable Pos pos,
) {
	return start <= pos && pos < start + symSize(allSymbols, name);
}

immutable(bool) betweenRanges(immutable RangeWithinFile left, immutable Pos pos, immutable RangeWithinFile right) {
	return left.end <= pos && pos < right.start;
}
