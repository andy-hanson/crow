module frontend.ide.getPosition;

@safe @nogc pure nothrow:

import frontend.ide.position : Position, PositionKind;
import frontend.parse.ast :
	DestructureAst,
	ExplicitVisibility,
	FieldMutabilityAst,
	FunDeclAst,
	FunModifierAst,
	ImportOrExportAst,
	keywordRange,
	NameAndRange,
	pathRange,
	range,
	rangeOfDestructureSingle,
	rangeOfMutKeyword,
	rangeOfNameAndRange,
	StructDeclAst,
	symOfFieldMutabilityAstKind,
	TypeAst;
import model.model :
	body_,
	decl,
	Destructure,
	Expr,
	ExprKind,
	FunBody,
	FunDecl,
	FunDeclSource,
	ImportOrExport,
	ImportOrExportKind,
	Local,
	LocalSource,
	Module,
	paramsArray,
	range,
	RecordField,
	SpecDecl,
	StructBody,
	StructDecl,
	StructInst,
	Type,
	typeArgs,
	TypeParam;
import util.col.arr : only, ptrsRange;
import util.col.arrUtil : first, firstPointer, firstWithIndex, firstZip, firstZipPointerFirst;
import util.opt : force, has, none, Opt, optIf, optOr, optOr, some;
import util.sourceRange : hasPos, Pos, RangeWithinFile;
import util.sym : AllSymbols;
import util.union_ : Union;
import util.uri : AllUris;

Position getPosition(in AllSymbols allSymbols, in AllUris allUris, Module* module_, Pos pos) {
	Opt!PositionKind kind = getPositionKind(allSymbols, allUris, *module_, pos);
	return Position(module_, has(kind) ? force(kind) : PositionKind(PositionKind.None()));
}

private:

Opt!PositionKind getPositionKind(in AllSymbols allSymbols, in AllUris allUris, ref Module module_, Pos pos) =>
	optOr!PositionKind(
		positionInImportsOrExports(allSymbols, allUris, module_.imports, pos),
		() => positionInImportsOrExports(allSymbols, allUris, module_.reExports, pos),
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
			x.source.isA!(FunDeclSource.Ast)
				? positionInFun(allSymbols, x, *x.source.as!(FunDeclSource.Ast).ast, pos)
				: none!PositionKind));
	//TODO: check for aliases too

Opt!PositionKind positionInFun(in AllSymbols allSymbols, FunDecl* a, in FunDeclAst ast, Pos pos) =>
	optOr!PositionKind(
		optIf(hasPos(allSymbols, ast.name, pos), () => PositionKind(a)),
		() => positionInType(allSymbols, a.returnType, ast.returnType, pos),
		() => first!(PositionKind, Destructure)(paramsArray(a.params), (Destructure x) =>
			positionInDestructure(allSymbols, a, pos, x)),
		() => firstWithIndex!(PositionKind, FunModifierAst)(ast.modifiers, (size_t index, FunModifierAst modifier) =>
			optIf(hasPos(range(modifier, allSymbols), pos), () =>
				positionForModifier(a, ast, index, modifier))),
		() => a.body_.isA!(FunBody.ExpressionBody)
			? positionInExpr(allSymbols, a, a.body_.as!(FunBody.ExpressionBody).expr, pos)
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

Opt!PositionKind positionInDestructure(in AllSymbols allSymbols, FunDecl* containingFun, Pos pos, in Destructure a) =>
	a.matchWithPointers!(Opt!PositionKind)(
		(Destructure.Ignore*) =>
			none!PositionKind,
		(Local* x) {
			DestructureAst.Single* ast = x.source.as!(LocalSource.Ast).ast;
			return hasPos(rangeOfDestructureSingle(*ast, allSymbols), pos)
				? optOr!PositionKind(
					optIf(hasPos(rangeOfNameAndRange(ast.name, allSymbols), pos), () =>
						PositionKind(PositionKind.LocalInFunction(containingFun, x))),
					() => optIf(optHasPos(rangeOfMutKeyword(*ast), pos), () =>
						PositionKind(PositionKind.Keyword(PositionKind.Keyword.Kind.localMut))),
					() => has(ast.type) ? positionInType(allSymbols, x.type, *force(ast.type), pos) : none!PositionKind)
				: none!PositionKind;
		},
		(Destructure.Split* x) =>
			//TODO: handle x.destructuredType
			first!(PositionKind, Destructure)(x.parts, (Destructure part) =>
				positionInDestructure(allSymbols, containingFun, pos, part)));

Opt!PositionKind positionInImportsOrExports(
	in AllSymbols allSymbols,
	in AllUris allUris,
	ImportOrExport[] importsOrExports,
	Pos pos,
) {
	foreach (ImportOrExport* im; ptrsRange(importsOrExports))
		if (has(im.source) && hasPos(force(im.source).range, pos)) {
			ImportOrExportAst* source = force(im.source);
			return im.kind.match!(Opt!PositionKind)(
				(ImportOrExportKind.ModuleWhole m) =>
					some(PositionKind(PositionKind.ImportedModule(im, m.modulePtr))),
				(ImportOrExportKind.ModuleNamed m) =>
					hasPos(pathRange(allUris, *force(im.source)), pos)
						? some(PositionKind(PositionKind.ImportedModule(im, m.modulePtr)))
						: first!(PositionKind, NameAndRange)(source.kind.as!(NameAndRange[]), (NameAndRange x) =>
							optIf(hasPos(allSymbols, x, pos), () =>
								PositionKind(PositionKind.ImportedName(im, x.name)))));
		}
	return none!PositionKind;
}

Opt!PositionKind positionInStruct(in AllSymbols allSymbols, StructDecl* a, Pos pos) =>
	has(a.ast)
		? positionInStruct(allSymbols, a, *force(a.ast), pos)
		: none!PositionKind;

Opt!PositionKind positionInStruct(in AllSymbols allSymbols, StructDecl* a, in StructDeclAst ast, Pos pos) =>
	optOr!PositionKind(
		positionInVisibility(a, ast, pos),
		() => optIf(hasPos(rangeOfNameAndRange(ast.name, allSymbols), pos), () => PositionKind(a)),
		() => optIf(hasPos(keywordRange(ast, allSymbols), pos), () =>
			PositionKind(PositionKind.Keyword(keywordKindForStructBody(ast.body_)))),
		() => positionInTypeParams(allSymbols, a.typeParams, ast.typeParams, pos),
		//TODO: positions for flags (like 'extern' or 'by-val')
		() => positionInStructBody(allSymbols, a, body_(*a), ast.body_, pos));

PositionKind.Keyword.Kind keywordKindForStructBody(in StructDeclAst.Body a) =>
	a.matchIn!(PositionKind.Keyword.Kind)(
		(in StructDeclAst.Body.Builtin) =>
			PositionKind.Keyword.Kind.builtin,
		(in StructDeclAst.Body.Enum) =>
			PositionKind.Keyword.Kind.enum_,
		(in StructDeclAst.Body.Extern) =>
			PositionKind.Keyword.Kind.extern_,
		(in StructDeclAst.Body.Flags) =>
			PositionKind.Keyword.Kind.flags,
		(in StructDeclAst.Body.Record) =>
			PositionKind.Keyword.Kind.record,
		(in StructDeclAst.Body.Union) =>
			PositionKind.Keyword.Kind.union_);

Opt!PositionKind positionInVisibility(T, TAst)(in T a, in TAst ast, Pos pos) =>
	pos == ast.range.start && ast.visibility != ExplicitVisibility.default_
		? some(PositionKind(a.visibility))
		: none!PositionKind;

Opt!PositionKind positionInTypeParams(in AllSymbols allSymbols, TypeParam[] typeParams, NameAndRange[] asts, Pos pos) =>
	firstZipPointerFirst!(PositionKind, TypeParam, NameAndRange)(typeParams, asts, (TypeParam* p, NameAndRange x) =>
		optIf(hasPos(allSymbols, x, pos), () => PositionKind(p)));

Opt!PositionKind positionInSpec(in AllSymbols allSymbols, SpecDecl* a, Pos pos) {
	//TODO:delve inside!
	return some(PositionKind(a));
}

Opt!PositionKind positionInStructBody(
	in AllSymbols allSymbols,
	StructDecl* decl,
	ref StructBody body_,
	in StructDeclAst.Body ast,
	Pos pos,
) =>
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
		(StructBody.Record x) =>
			firstZipPointerFirst!(PositionKind, RecordField, StructDeclAst.Body.Record.Field)(
				x.fields,
				ast.as!(StructDeclAst.Body.Record).fields,
				(RecordField* field, StructDeclAst.Body.Record.Field fieldAst) =>
					positionInRecordField(allSymbols, decl, field, fieldAst, pos)),
		(StructBody.Union) =>
			//TODO
			none!PositionKind);

Opt!PositionKind positionInRecordField(
	in AllSymbols allSymbols,
	StructDecl* decl,
	RecordField* field,
	in StructDeclAst.Body.Record.Field fieldAst,
	Pos pos,
) =>
	optOr!PositionKind(
		positionInVisibility(field, fieldAst, pos),
		() => optIf(hasPos(allSymbols, fieldAst.name, pos), () =>
			PositionKind(PositionKind.RecordFieldPosition(decl, field))),
		() => has(fieldAst.mutability)
			? positionInFieldMutability(allSymbols, force(fieldAst.mutability), pos)
			: none!PositionKind,
		() => positionInType(allSymbols, field.type, fieldAst.type, pos));

Opt!PositionKind positionInFieldMutability(in AllSymbols allSymbols, in FieldMutabilityAst ast, Pos pos) =>
	optIf(
		hasPos(allSymbols, NameAndRange(ast.pos, symOfFieldMutabilityAstKind(ast.kind)), pos),
		() => PositionKind(PositionKind.RecordFieldMutability(ast.kind)));

Opt!PositionKind positionInExpr(in AllSymbols allSymbols, FunDecl* containingFun, ref Expr a, Pos pos) {
	if (!hasPos(a.range.range, pos))
		return none!PositionKind;
	else {
		Opt!PositionKind here() =>
			some(PositionKind(PositionKind.Expression(containingFun, &a)));
		Opt!PositionKind inDestructure(in Destructure x) =>
			positionInDestructure(allSymbols, containingFun, pos, x);
		Opt!PositionKind recur(in Expr inner) =>
			positionInExpr(allSymbols, containingFun, inner, pos);
		Opt!PositionKind recurOpt(in Opt!(Expr*) inner) =>
			has(inner)
				? recur(*force(inner))
				: none!PositionKind;

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

bool hasPos(in AllSymbols allSymbols, in NameAndRange nr, Pos pos) =>
	hasPos(rangeOfNameAndRange(nr, allSymbols), pos);

bool optHasPos(Opt!RangeWithinFile a, Pos p) =>
	has(a) && hasPos(force(a), p);
