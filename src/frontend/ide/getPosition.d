module frontend.ide.getPosition;

@safe @nogc pure nothrow:

import frontend.ide.position : Position, PositionKind;
import frontend.parse.ast : ExplicitVisibility, FunDeclAst, FunModifierAst, NameAndRange, range, TypeAst;
import model.model :
	body_,
	decl,
	Destructure,
	Expr,
	ExprKind,
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
	typeArgs;
import util.col.arr : only, ptrsRange;
import util.col.arrUtil : first, firstPointer, firstWithIndex, firstZip;
import util.opt : force, has, none, Opt, optIf, optOr, optOr, some;
import util.sourceRange : hasPos, Pos;
import util.sym : AllSymbols, Sym, symSize;
import util.union_ : Union;

Position getPosition(in AllSymbols allSymbols, Module* module_, Pos pos) {
	Opt!PositionKind kind = getPositionKind(allSymbols, *module_, pos);
	return Position(module_, has(kind) ? force(kind) : PositionKind(PositionKind.None()));
}

private:

Opt!PositionKind getPositionKind(in AllSymbols allSymbols, ref Module module_, Pos pos) =>
	optOr!PositionKind(
		positionInImportsOrExports(allSymbols, module_.imports, pos),
		() => positionInImportsOrExports(allSymbols, module_.reExports, pos),
		() => firstPointer!(PositionKind, StructDecl)(module_.structs, (StructDecl* x) =>
			hasPos(x.range.range, pos)
				? positionInStruct(allSymbols, x, pos)
				: none!PositionKind),
		() => firstPointer!(PositionKind, SpecDecl)(module_.specs, (SpecDecl* x) =>
			hasPos(x.range.range, pos)
				//TODO: delve inside!
				? positionInSpec(allSymbols, x, pos)
				: none!PositionKind),
		() => firstPointer!(PositionKind, FunDecl)(module_.funs, (FunDecl* x) =>
			has(x.ast)
				? positionInFun(allSymbols, x, *force(x.ast), pos)
				: none!PositionKind));
	//TODO: check for aliases too

Opt!PositionKind positionInFun(in AllSymbols allSymbols, FunDecl* a, in FunDeclAst ast, Pos pos) =>
	optOr!PositionKind(
		optIf(hasPos(a.nameRange(allSymbols), pos), () => PositionKind(a)),
		() => positionInType(allSymbols, a.returnType, ast.returnType, pos),
		() => first!(PositionKind, Destructure)(paramsArray(a.params), (Destructure x) =>
			positionInParameterDestructure(allSymbols, pos, x)),
		() => firstWithIndex!(PositionKind, FunModifierAst)(ast.modifiers, (size_t index, FunModifierAst modifier) =>
			optIf(hasPos(range(modifier, allSymbols), pos), () =>
				positionForModifier(a, ast, index, modifier))),
		() => a.body_.isA!(FunBody.ExpressionBody)
			? positionInExpr(allSymbols, a.body_.as!(FunBody.ExpressionBody).expr, pos)
			: none!PositionKind);

PositionKind positionForModifier(FunDecl* a, in FunDeclAst ast, size_t index, in FunModifierAst modifier) =>
	modifier.matchIn!PositionKind(
		(in FunModifierAst.Special x) =>
			PositionKind(PositionKind.FunSpecialModifier(a, x.flag)),
		(in FunModifierAst.Extern x) =>
			PositionKind(PositionKind.FunExtern(a)),
		(in TypeAst x) {
			// Find the corresponding spec
			size_t specIndex = 0;
			foreach (ref FunModifierAst prevModifier; ast.modifiers[0 .. index])
				if (prevModifier.isA!TypeAst)
					specIndex++;
			return PositionKind(a.specs[specIndex]);
		});

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

Opt!PositionKind positionInStruct(in AllSymbols allSymbols, StructDecl* a, Pos pos) =>
	has(a.ast)
		? optOr!PositionKind(
			positionInVisibility(a, pos),
			//TODO: position for the name itself
			//TODO: position for 'record' keyword
			//TODO: positions for flags (like 'extern')
			() => positionInStructBody(allSymbols, a, body_(*a), pos))
		: none!PositionKind;

Opt!PositionKind positionInVisibility(T)(in T a, Pos pos) =>
	pos == force(a.ast).range.start && force(a.ast).visibility != ExplicitVisibility.default_
		? some(PositionKind(a.visibility))
		: none!PositionKind;

Opt!PositionKind positionInSpec(in AllSymbols allSymbols, SpecDecl* a, Pos pos) {
	//TODO:delve inside!
	return some(PositionKind(a));
}

Opt!PositionKind positionInStructBody(in AllSymbols allSymbols, StructDecl* decl, ref StructBody body_, Pos pos) =>
	body_.match!(Opt!PositionKind)(
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
		(StructBody.Record x) {
			foreach (RecordField* field; ptrsRange(x.fields))
				if (hasPos(field.range.range, pos))
					return nameHasPos(allSymbols, field.range.start, field.name, pos)
						? some(PositionKind(PositionKind.RecordFieldPosition(decl, field)))
						: positionInType(allSymbols, field.type, field.ast.type, pos);
			return none!PositionKind;
		},
		(StructBody.Union) =>
			//TODO
			none!PositionKind);

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

Opt!PositionKind positionInType(in AllSymbols allSymbols, Type type, TypeAst ast, Pos pos) {
	if (!hasPos(range(ast, allSymbols), pos))
		return none!PositionKind;
	else {
		Opt!PositionKind fromArgs(in TypeAst[] typeArgAsts) {
			Type[] args = typeArgs(*type.as!(StructInst*));
			TypeAst[] actualArgAsts = typeArgAsts.length == args.length
				? typeArgAsts
				: only(typeArgAsts).as!(TypeAst.Tuple*).members;
			return firstZip!(PositionKind, Type, TypeAst)(args, actualArgAsts, (Type t, TypeAst y) =>
				positionInType(allSymbols, t, y, pos));
		}

		Opt!PositionKind fromInner = ast.match!(Opt!PositionKind)(
			(TypeAst.Bogus) =>
				none!PositionKind,
			(ref TypeAst.Fun x) =>
				fromArgs(x.returnAndParamTypes),
			(ref TypeAst.Map x) =>
				fromArgs([x.v, x.k]),
			(NameAndRange x) =>
				none!PositionKind,
			(ref TypeAst.SuffixName x) =>
				fromArgs([x.left]),
			(ref TypeAst.SuffixSpecial x) =>
				fromArgs([x.left]),
			(ref TypeAst.Tuple x) =>
				fromArgs(x.members));
		return optOr!PositionKind(fromInner, () => some(PositionKind(type)));
	}
}
