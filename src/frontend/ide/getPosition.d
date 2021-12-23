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
	matchFunBody,
	matchStructBody,
	matchType,
	Module,
	ModuleAndNames,
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
import util.opt : force, has, none, Opt, optOr2, some;
import util.ptr : Ptr;
import util.sourceRange : hasPos, Pos, RangeWithinFile;
import util.sym : AllSymbols, Sym, symSize;

struct Position {
	@safe @nogc pure nothrow:

	struct ImportedModule {
		immutable Ptr!ModuleAndNames import_;
	}
	struct ImportedName {
		immutable Ptr!ModuleAndNames import_;
		immutable Sym name;
	}
	struct RecordFieldPosition {
		immutable Ptr!StructDecl struct_;
		immutable Ptr!RecordField field;
	}

	@trusted immutable this(immutable Expr a) { kind = Kind.expr; expr = a; }
	@trusted immutable this(immutable Ptr!FunDecl a) { kind = Kind.funDecl; funDecl = a; }
	@trusted immutable this(immutable ImportedModule a) { kind = Kind.importedModule; importedModule = a; }
	@trusted immutable this(immutable ImportedName a) { kind = Kind.importedName; importedName = a; }
	immutable this(immutable Ptr!Param a) { kind = Kind.param; param = a; }
	@trusted immutable this(immutable RecordFieldPosition a) { kind = Kind.recordField; recordField = a; }
	@trusted immutable this(immutable Ptr!SpecDecl a) { kind = Kind.specDecl; specDecl = a; }
	@trusted immutable this(immutable Ptr!StructDecl a) { kind = Kind.structDecl; structDecl = a; }
	immutable this(immutable Type a) { kind = Kind.type; type = a; }
	@trusted immutable this(immutable Ptr!TypeParam a) { kind = Kind.typeParam; typeParam = a; }

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
		immutable Ptr!FunDecl funDecl;
		immutable ImportedModule importedModule;
		immutable ImportedName importedName;
		immutable Ptr!Param param;
		immutable RecordFieldPosition recordField;
		immutable Ptr!SpecDecl specDecl;
		immutable Ptr!StructDecl structDecl;
		immutable Type type;
		immutable Ptr!TypeParam typeParam;
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
			return cbFunDecl(a.funDecl.deref());
		case Position.Kind.importedModule:
			return cbImportedModule(a.importedModule);
		case Position.Kind.importedName:
			return cbImportedName(a.importedName);
		case Position.Kind.param:
			return cbParam(a.param.deref());
		case Position.Kind.recordField:
			return cbRecordField(a.recordField);
		case Position.Kind.specDecl:
			return cbSpecDecl(a.specDecl.deref());
		case Position.Kind.structDecl:
			return cbStructDecl(a.structDecl.deref());
		case Position.Kind.type:
			return cbType(a.type);
		case Position.Kind.typeParam:
			return cbTypeParam(a.typeParam.deref());
	}
}

immutable(Opt!Position) getPosition(ref const AllSymbols allSymbols, ref immutable Module module_, immutable Pos pos) {
	immutable Opt!Position fromImportsOrExports = optOr2(
		positionInImportsOrExports(allSymbols, module_.imports, pos),
		() => positionInImportsOrExports(allSymbols, module_.exports, pos));
	if (has(fromImportsOrExports))
		return fromImportsOrExports;

	foreach (immutable Ptr!StructDecl s; ptrsRange(module_.structs))
		if (hasPos(s.deref().range.range, pos))
			return some(positionInStruct(allSymbols, s, pos));

	foreach (immutable Ptr!SpecDecl s; ptrsRange(module_.specs))
		if (hasPos(s.deref().range.range, pos))
			//TODO: delve inside!
			return some(immutable Position(s));

	foreach (immutable Ptr!FunDecl f; ptrsRange(module_.funs)) {
		immutable Opt!Position fromFun = positionInFun(f, pos, allSymbols);
		if (has(fromFun))
			return fromFun;
	}

	return none!Position;

	//TODO: check for aliases too
}

private:

immutable(Opt!Position) positionInFun(immutable Ptr!FunDecl a, immutable Pos pos, ref const AllSymbols allSymbols) {
	immutable Opt!Position fromSig = positionInSig(a.deref().sig, pos, immutable Position(a), allSymbols);
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
		(immutable(FlagsFunction)) =>
			none!Position,
		(ref immutable FunBody.RecordFieldGet) =>
			none!Position,
		(ref immutable FunBody.RecordFieldSet) =>
			none!Position,
	)(a.deref().body_);
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
	foreach (immutable Ptr!Param x; ptrsRange(params))
		if (hasPos(x.deref().range.range, pos))
			return some(hasPos(x.deref().nameRange(allSymbols), pos)
				? immutable Position(x)
				: immutable Position(x.deref().type));
	// TODO: specs
	return none!Position;
}

immutable(Opt!Position) positionInImportsOrExports(
	ref const AllSymbols allSymbols,
	ref immutable ModuleAndNames[] importsOrExports,
	immutable Pos pos,
) {
	foreach (immutable Ptr!ModuleAndNames im; ptrsRange(importsOrExports)) {
		if (has(im.deref().importSource) && hasPos(force(im.deref().importSource), pos)) {
			if (has(im.deref().names)) {
				Pos namePos = force(im.deref().importSource).start;
				foreach (immutable Sym name; force(im.deref().names)) {
					immutable Pos nameEnd = namePos + symSize(allSymbols, name);
					if (pos < nameEnd)
						return some(immutable Position(immutable Position.ImportedName(im, name)));
					namePos = nameEnd + 1;
				}
			}
			return some(immutable Position(immutable Position.ImportedModule(im)));
		}
	}
	return none!Position;
}

immutable(Position) positionInStruct(ref const AllSymbols allSymbols, immutable Ptr!StructDecl a, immutable Pos pos) {
	//TODO: look through type params!

	immutable Opt!Position specific = matchStructBody!(immutable Opt!Position)(
		body_(a.deref()),
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
			foreach (immutable Ptr!RecordField field; ptrsRange(it.fields))
				if (hasPos(field.deref().range.range, pos))
					return nameHasPos(allSymbols, field.deref().range.start, field.deref().name, pos)
						? some(immutable Position(immutable Position.RecordFieldPosition(a, field)))
						: positionOfType(field.deref().type);
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
		(immutable Ptr!TypeParam it) => some(immutable Position(it)),
		(immutable Ptr!StructInst it) => some(immutable Position(decl(it.deref()))));
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
