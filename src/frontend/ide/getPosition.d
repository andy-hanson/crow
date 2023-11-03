module frontend.ide.getPosition;

@safe @nogc pure nothrow:

import model.model :
	body_,
	decl,
	Destructure,
	EnumFunction,
	Expr,
	ExprKind,
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
import util.col.arr : ptrsRange;
import util.col.arrUtil : first;
import util.opt : force, has, none, Opt, optOr, some;
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
	immutable struct LocalNonParameter {
		Local* local;
	}
	immutable struct LocalParameter {
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
		LocalNonParameter,
		LocalParameter,
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

	if (hasPos(a.returnTypeRange, pos))
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
			positionInExpr(allSymbols, x.expr, pos),
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
	positionInDestructure(allSymbols, pos, a, (Local* x) => PositionKind(PositionKind.LocalParameter(x)));

Opt!PositionKind positionInDestructure(
	in AllSymbols allSymbols,
	Pos pos,
	in Destructure a,
	in PositionKind delegate(Local*) @safe @nogc pure nothrow cb,
) =>
	a.matchWithPointers!(Opt!PositionKind)(
		(Destructure.Ignore*) =>
			none!PositionKind,
		(Local* x) =>
			hasPos(x.range.range, pos)
				? hasPos(x.nameRange(allSymbols), pos)
					? some(cb(x))
					: some(PositionKind(x.type))
				: none!PositionKind,
		(Destructure.Split* x) =>
			//TODO: handle x.destructuredType
			first!(PositionKind, Destructure)(x.parts, (Destructure part) =>
				positionInDestructure(allSymbols, pos, part, cb)));

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

Opt!PositionKind positionInExpr(in AllSymbols allSymbols, ref Expr a, Pos pos) {
	if (!hasPos(a.range.range, pos))
		return none!PositionKind;
	else {
		Opt!PositionKind here() {
			return some(PositionKind(a));
		}
		Opt!PositionKind inDestructure(in Destructure x) {
			return positionInDestructure(allSymbols, pos, x, (Local* x) =>
				PositionKind(PositionKind.LocalNonParameter(x)));
		}
		Opt!PositionKind recur(in Expr inner) {
			return positionInExpr(allSymbols, inner, pos);
		}
		Opt!PositionKind recurOpt(in Opt!(Expr*) inner) {
			return has(inner)
				? recur(*force(inner))
				: none!PositionKind;
		}

		return a.kind.match!(Opt!PositionKind)(
			(ExprKind.AssertOrForbid x) =>
				optOr!PositionKind(
					recur(*x.condition),
					() => recurOpt(x.thrown),
					() => here()),
			(ExprKind.Bogus) =>
				none!PositionKind,
			(ExprKind.Call x) =>
				optOr!PositionKind(
					first!(PositionKind, Expr)(x.args, (Expr y) => recur(y)),
					() => here()),
			(ExprKind.ClosureGet) =>
				here(),
			(ExprKind.ClosureSet x) =>
				optOr!PositionKind(
					recur(*x.value),
					() => here()),
			(ExprKind.FunPtr) =>
				here(),
			(ref ExprKind.If x) =>
				optOr!PositionKind(
					recur(x.cond),
					() => recur(x.then),
					() => recur(x.else_),
					() => here()),
			(ref ExprKind.IfOption x) =>
				optOr!PositionKind(
					inDestructure(x.destructure),
					() => recur(x.option.expr),
					() => recur(x.then),
					() => recur(x.else_),
					() => here()),
			(ref ExprKind.Lambda x) =>
				optOr!PositionKind(
					inDestructure(x.param),
					() => recur(x.body_),
					() => here()),
			(ref ExprKind.Let x) =>
				optOr!PositionKind(
					inDestructure(x.destructure),
					() => recur(x.value),
					() => recur(x.then),
					() => here()),
			(ref ExprKind.Literal) =>
				here(),
			(ExprKind.LiteralCString) =>
				here(),
			(ExprKind.LiteralSymbol) =>
				here(),
			(ExprKind.LocalGet) =>
				here(),
			(ref ExprKind.LocalSet) =>
				here(),
			(ref ExprKind.Loop x) =>
				optOr!PositionKind(recur(x.body_), () => here()),
			(ref ExprKind.LoopBreak x) =>
				optOr!PositionKind(recur(x.value), () => here()),
			(ExprKind.LoopContinue) =>
				here(),
			(ref ExprKind.LoopUntil x) =>
				optOr!PositionKind(recur(x.condition), () => recur(x.body_), () => here()),
			(ref ExprKind.LoopWhile x) =>
				optOr!PositionKind(recur(x.condition), () => recur(x.body_), () => here()),
			(ref ExprKind.MatchEnum x) =>
				optOr!PositionKind(
					recur(x.matched.expr),
					() => first!(PositionKind, Expr)(x.cases, (Expr y) => recur(y)),
					() => here()),
			(ref ExprKind.MatchUnion x) =>
				optOr!PositionKind(
					recur(x.matched.expr),
					() => first!(PositionKind, ExprKind.MatchUnion.Case)(x.cases, (ExprKind.MatchUnion.Case case_) =>
						optOr!PositionKind(
							inDestructure(case_.destructure),
							() => recur(case_.then)))),
			(ref ExprKind.PtrToField x) =>
				optOr!PositionKind(
					recur(x.target.expr),
					() => here()),
			(ExprKind.PtrToLocal) =>
				here(),
			(ref ExprKind.Seq x) =>
				optOr!PositionKind(recur(x.first), () => recur(x.then)),
			(ref ExprKind.Throw x) =>
				optOr!PositionKind(recur(x.thrown), () => here()));
	}
}

bool nameHasPos(in AllSymbols allSymbols, Pos start, Sym name, Pos pos) =>
	start <= pos && pos < start + symSize(allSymbols, name);
