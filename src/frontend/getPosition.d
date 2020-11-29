module frontend.getPosition;

@safe @nogc pure nothrow:

import model.model :
	Expr,
	FunBody,
	FunDecl,
	matchFunBody,
	Module,
	ModuleAndNameReferents,
	NameAndReferents,
	range,
	SpecDecl,
	StructDecl;
import util.collection.arr : Arr, ptrsRange, range;
import util.opt : force, has, none, Opt, optOr2, some;
import util.ptr : Ptr;
import util.sourceRange : hasPos, Pos;

struct Position {
	@safe @nogc pure nothrow:

	struct ImportedModule {
		immutable Ptr!ModuleAndNameReferents import_;
	}
	struct ImportedName {
		immutable Ptr!ModuleAndNameReferents import_;
		immutable Ptr!NameAndReferents name_;
	}

	@trusted immutable this(immutable Ptr!Expr a) { kind = Kind.expr; expr = a; }
	@trusted immutable this(immutable Ptr!FunDecl a) { kind = Kind.funDecl; funDecl = a; }
	@trusted immutable this(immutable ImportedModule a) { kind = Kind.importedModule; importedModule = a; }
	@trusted immutable this(immutable ImportedName a) { kind = Kind.importedName; importedName = a; }
	@trusted immutable this(immutable Ptr!SpecDecl a) { kind = Kind.specDecl; specDecl = a; }
	@trusted immutable this(immutable Ptr!StructDecl a) { kind = Kind.structDecl; structDecl = a; }

	private:
	enum Kind {
		expr,
		funDecl,
		importedModule,
		importedName,
		specDecl,
		structDecl,
	}
	immutable Kind kind;
	union {
		immutable Ptr!Expr expr;
		immutable Ptr!FunDecl funDecl;
		immutable ImportedModule importedModule;
		immutable ImportedName importedName;
		immutable Ptr!SpecDecl specDecl;
		immutable Ptr!StructDecl structDecl;
	}
}

@trusted T matchPosition(T)(
	ref immutable Position a,
	scope T delegate(immutable Ptr!Expr) @safe @nogc pure nothrow cbExpr,
	scope T delegate(immutable Ptr!FunDecl) @safe @nogc pure nothrow cbFunDecl,
	scope T delegate(ref immutable Position.ImportedModule) @safe @nogc pure nothrow cbImportedModule,
	scope T delegate(ref immutable Position.ImportedName) @safe @nogc pure nothrow cbImportedName,
	scope T delegate(immutable Ptr!SpecDecl) @safe @nogc pure nothrow cbSpecDecl,
	scope T delegate(immutable Ptr!StructDecl) @safe @nogc pure nothrow cbStructDecl,
) {
	final switch (a.kind) {
		case Position.Kind.expr:
			return cbExpr(a.expr);
		case Position.Kind.funDecl:
			return cbFunDecl(a.funDecl);
		case Position.Kind.importedModule:
			return cbImportedModule(a.importedModule);
		case Position.Kind.importedName:
			return cbImportedName(a.importedName);
		case Position.Kind.specDecl:
			return cbSpecDecl(a.specDecl);
		case Position.Kind.structDecl:
			return cbStructDecl(a.structDecl);
	}
}

immutable(Opt!Position) getPosition(ref immutable Module module_, immutable Pos pos) {
	immutable Opt!Position fromImportsOrExports = optOr2(positionInImportsOrExports(module_.imports, pos), () =>
		positionInImportsOrExports(module_.exports, pos));
	if (has(fromImportsOrExports))
		return fromImportsOrExports;

	foreach (ref immutable Ptr!StructDecl s; ptrsRange(module_.structs))
		if (hasPos(s.range.range, pos))
			//TODO: delve inside!
			return some(immutable Position(s));

	foreach (ref immutable Ptr!SpecDecl s; ptrsRange(module_.specs))
		if (hasPos(s.range.range, pos))
			//TODO: delve inside!
			return some(immutable Position(s));

	foreach (ref immutable Ptr!FunDecl f; ptrsRange(module_.funs)) {
		if (hasPos(f.sig.range, pos))
			//TODO: delve inside!
			return some(immutable Position(f));
		immutable Opt!Position fromBody = matchFunBody!(immutable Opt!Position)(
			f.body_,
			(ref immutable FunBody.Builtin) =>
				none!Position,
			(ref immutable FunBody.CreateRecord) =>
				none!Position,
			(ref immutable FunBody.Extern) =>
				none!Position,
			(immutable Ptr!Expr it) =>
				hasPos(range(it).range, pos)
					//TODO: delve inside!
					? some(immutable Position(it))
					: none!Position,
			(ref immutable FunBody.RecordFieldGet) =>
				none!Position,
			(ref immutable FunBody.RecordFieldSet) =>
				none!Position);
		if (has(fromBody))
			return fromBody;
	}

	return none!Position;

	//TODO: check for aliases too
}

private:

immutable(Opt!Position) positionInImportsOrExports(
	ref immutable Arr!ModuleAndNameReferents importsOrExports,
	immutable Pos pos,
) {
	foreach (immutable Ptr!ModuleAndNameReferents im; ptrsRange(importsOrExports)) {
		if (hasPos(im.range, pos)) {
			if (has(im.namesAndReferents))
				foreach (immutable Ptr!NameAndReferents nr; ptrsRange(force(im.namesAndReferents)))
					if (hasPos(nr.range, pos))
						return some(immutable Position(immutable Position.ImportedName(im, nr)));
			return some(immutable Position(immutable Position.ImportedModule(im)));
		}
	}
	return none!Position;
}
