module frontend.ide.getPosition;

@safe @nogc pure nothrow:

import frontend.ide.ideUtil : eachDestructureComponent, eachSpecParent, eachTypeArg, eachTypeComponent;
import frontend.ide.position : ExprContainer, LocalContainer, Position, PositionKind, VisibilityContainer;
import model.ast :
	DestructureAst,
	ExplicitVisibility,
	FieldMutabilityAst,
	FunDeclAst,
	FunModifierAst,
	ImportOrExportAst,
	NameAndRange,
	paramsArray,
	pathRange,
	range,
	rangeOfDestructureSingle,
	rangeOfMutKeyword,
	rangeOfNameAndRange,
	SpecSigAst,
	stringOfFieldMutabilityAstKind,
	StructBodyAst,
	StructDeclAst,
	TestAst,
	TypeAst;
import model.diag : TypeContainer, TypeWithContainer;
import model.model :
	AssertOrForbidExpr,
	BogusExpr,
	CallExpr,
	ClosureGetExpr,
	ClosureSetExpr,
	Destructure,
	Expr,
	FunBody,
	FunDecl,
	FunDeclSource,
	FunPointerExpr,
	IfExpr,
	IfOptionExpr,
	ImportOrExport,
	ImportOrExportKind,
	LambdaExpr,
	LetExpr,
	LiteralCStringExpr,
	LiteralExpr,
	LiteralSymbolExpr,
	Local,
	LocalGetExpr,
	LocalSetExpr,
	LoopBreakExpr,
	LoopContinueExpr,
	LoopExpr,
	LoopUntilExpr,
	LoopWhileExpr,
	MatchEnumExpr,
	MatchUnionExpr,
	Module,
	nameRange,
	NameReferents,
	Params,
	PtrToFieldExpr,
	PtrToLocalExpr,
	RecordField,
	SeqExpr,
	SpecDeclBody,
	SpecInst,
	StructBody,
	SpecDecl,
	SpecDeclSig,
	StructDecl,
	Test,
	ThrowExpr,
	Type,
	TypeParamIndex,
	VarDecl,
	VarKind;
import model.model : paramsArray, StructDeclSource;
import util.col.array : first, firstPointer, firstWithIndex, firstZipPointerFirst;
import util.opt : force, has, none, Opt, optIf, optOr, optOr, optOrDefault, some;
import util.sourceRange : hasPos, Pos, Range, rangeOfStartAndLength;
import util.symbol : AllSymbols;
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
		() => firstPointer!(PositionKind, VarDecl)(module_.vars, (VarDecl* x) =>
			hasPos(x.range.range, pos)
				? positionInVar(allSymbols, x, pos)
				: none!PositionKind),
		() => firstPointer!(PositionKind, SpecDecl)(module_.specs, (SpecDecl* x) =>
			hasPos(x.range.range, pos)
				? positionInSpec(allSymbols, x, pos)
				: none!PositionKind),
		() => firstPointer!(PositionKind, FunDecl)(module_.funs, (FunDecl* x) =>
			x.source.isA!(FunDeclSource.Ast)
				? positionInFun(allSymbols, x, *x.source.as!(FunDeclSource.Ast).ast, pos)
				: none!PositionKind),
		() => firstPointer!(PositionKind, Test)(module_.tests, (Test* x) =>
			hasPos(x.ast.range, pos)
				? some(positionInTest(allSymbols, x, *x.ast, pos))
				: none!PositionKind));
	//TODO: check for aliases too

Opt!PositionKind positionInFun(in AllSymbols allSymbols, FunDecl* a, in FunDeclAst ast, Pos pos) =>
	optOr!PositionKind(
		positionInVisibility(VisibilityContainer(a), ast, pos),
		() => optIf(hasPos(allSymbols, ast.name, pos), () => PositionKind(a)),
		() => positionInTypeParams(allSymbols, TypeContainer(a), ast.typeParams, pos),
		() => positionInType(allSymbols, TypeContainer(a), a.returnType, ast.returnType, pos),
		() => positionInParams(allSymbols, LocalContainer(a), a.params, pos),
		() => firstWithIndex!(PositionKind, FunModifierAst)(ast.modifiers, (size_t index, FunModifierAst modifier) =>
			optIf(hasPos(range(modifier, allSymbols), pos), () =>
				positionForModifier(a, ast, index, modifier))),
		() => a.body_.isA!(FunBody.ExpressionBody)
			? positionInExpr(allSymbols, ExprContainer(a), a.body_.as!(FunBody.ExpressionBody).expr, pos)
			: none!PositionKind);

PositionKind positionInTest(in AllSymbols allSymbols, Test* a, in TestAst ast, Pos pos) =>
	optOrDefault!PositionKind(
		positionInExpr(allSymbols, ExprContainer(a), a.body_, pos),
		() => PositionKind(a));

Opt!PositionKind positionInParams(in AllSymbols allSymbols, LocalContainer container, in Params params, Pos pos) =>
	first!(PositionKind, Destructure)(paramsArray(params), (Destructure x) =>
		positionInDestructure(allSymbols, container, x, pos));

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
			return PositionKind(PositionKind.SpecUse(TypeContainer(a), a.specs[specIndex]));
		});

Opt!PositionKind positionInDestructure(in AllSymbols allSymbols, LocalContainer container, in Destructure a, Pos pos) =>
	eachDestructureComponent!PositionKind(a, (Local* x) {
		DestructureAst.Single* ast = x.source.as!(DestructureAst.Single*);
		return hasPos(rangeOfDestructureSingle(*ast, allSymbols), pos)
			? optOr!PositionKind(
				optIf(hasPos(rangeOfNameAndRange(ast.name, allSymbols), pos), () =>
					PositionKind(PositionKind.LocalPosition(container, x))),
				() => optIf(optHasPos(rangeOfMutKeyword(*ast), pos), () =>
					PositionKind(PositionKind.Keyword(PositionKind.Keyword.Kind.localMut))),
				() => has(ast.type)
					? positionInType(allSymbols, container.toTypeContainer(), x.type, *force(ast.type), pos)
					: none!PositionKind)
			: none!PositionKind;
	});

Opt!PositionKind positionInImportsOrExports(
	in AllSymbols allSymbols,
	in AllUris allUris,
	ImportOrExport[] importsOrExports,
	Pos pos,
) {
	foreach (ref ImportOrExport im; importsOrExports)
		if (has(im.source) && hasPos(force(im.source).range, pos)) {
			ImportOrExportAst* source = force(im.source);
			return im.kind.matchIn!(Opt!PositionKind)(
				(in ImportOrExportKind.ModuleWhole) =>
					some(PositionKind(PositionKind.ImportedModule(&im))),
				(in Opt!(NameReferents*)[] referents) =>
					hasPos(pathRange(allUris, *force(im.source)), pos)
						? some(PositionKind(PositionKind.ImportedModule(&im)))
						: positionInImportedNames(
							allSymbols, im.modulePtr, source.kind.as!(NameAndRange[]), referents, pos));
		}
	return none!PositionKind;
}

Opt!PositionKind positionInImportedNames(
	in AllSymbols allSymbols,
	Module* module_,
	in NameAndRange[] names,
	in Opt!(NameReferents*)[] referents,
	Pos pos,
) {
	foreach (size_t index, NameAndRange x; names)
		if (hasPos(allSymbols, x, pos))
			return some(PositionKind(PositionKind.ImportedName(module_, x.name, referents[index])));
	return none!PositionKind;
}

Opt!PositionKind positionInVar(in AllSymbols allSymbols, VarDecl* a, Pos pos) =>
	optOr!PositionKind(
		positionInVisibility(VisibilityContainer(a), a.ast, pos),
		() => optIf(hasPos(nameRange(allSymbols, *a).range, pos), () => PositionKind(a)),
		() => optIf(hasPos(a.ast.keywordRange, pos), () =>
			PositionKind(PositionKind.Keyword(keywordKindForVar(a.kind)))),
		() => positionInType(allSymbols, TypeContainer(a), a.type, a.ast.type, pos));

PositionKind.Keyword.Kind keywordKindForVar(VarKind a) {
	final switch (a) {
		case VarKind.global:
			return PositionKind.Keyword.Kind.global;
		case VarKind.threadLocal:
			return PositionKind.Keyword.Kind.threadLocal;
	}
}

Opt!PositionKind positionInStruct(in AllSymbols allSymbols, StructDecl* a, Pos pos) =>
	a.source.matchIn!(Opt!PositionKind)(
		(in StructDeclAst x) =>
			positionInStruct(allSymbols, a, x, pos),
		(in StructDeclSource.Bogus) =>
			none!PositionKind);

Opt!PositionKind positionInStruct(in AllSymbols allSymbols, StructDecl* a, in StructDeclAst ast, Pos pos) =>
	optOr!PositionKind(
		positionInVisibility(VisibilityContainer(a), ast, pos),
		() => optIf(hasPos(nameRange(allSymbols, *a).range, pos), () => PositionKind(a)),
		() => optIf(hasPos(ast.keywordRange, pos), () =>
			PositionKind(PositionKind.Keyword(keywordKindForStructBody(ast.body_)))),
		() => positionInTypeParams(allSymbols, TypeContainer(a), ast.typeParams, pos),
		//TODO: positions for flags (like 'extern' or 'by-val')
		() => positionInStructBody(allSymbols, a, a.body_, ast.body_, pos));

PositionKind.Keyword.Kind keywordKindForStructBody(in StructBodyAst a) =>
	a.matchIn!(PositionKind.Keyword.Kind)(
		(in StructBodyAst.Builtin) =>
			PositionKind.Keyword.Kind.builtin,
		(in StructBodyAst.Enum) =>
			PositionKind.Keyword.Kind.enum_,
		(in StructBodyAst.Extern) =>
			PositionKind.Keyword.Kind.extern_,
		(in StructBodyAst.Flags) =>
			PositionKind.Keyword.Kind.flags,
		(in StructBodyAst.Record) =>
			PositionKind.Keyword.Kind.record,
		(in StructBodyAst.Union) =>
			PositionKind.Keyword.Kind.union_);

Opt!PositionKind positionInVisibility(TAst)(VisibilityContainer a, in TAst ast, Pos pos) =>
	pos == ast.range.start && ast.visibility != ExplicitVisibility.default_
		? some(PositionKind(PositionKind.VisibilityMark(a)))
		: none!PositionKind;

Opt!PositionKind positionInTypeParams(
	in AllSymbols allSymbols,
	TypeContainer container,
	in NameAndRange[] asts,
	Pos pos,
) =>
	firstWithIndex!(PositionKind, NameAndRange)(asts, (size_t index, NameAndRange x) =>
		optIf(hasPos(allSymbols, x, pos), () =>
			PositionKind(PositionKind.TypeParamWithContainer(TypeParamIndex(index), container))));

Opt!PositionKind positionInSpec(in AllSymbols allSymbols, SpecDecl* a, Pos pos) =>
	optOr!PositionKind(
		positionInVisibility(VisibilityContainer(a), a.ast, pos),
		() => optIf(hasPos(allSymbols, a.ast.name, pos), () => PositionKind(a)),
		() => positionInTypeParams(allSymbols, TypeContainer(a), a.ast.typeParams, pos),
		() => optIf(hasPos(a.ast.keywordRange, pos), () =>
			PositionKind(PositionKind.Keyword(PositionKind.Keyword.Kind.spec))),
		() => positionInSpecParents(allSymbols, a, pos),
		() => positionInSpecBody(allSymbols, a, pos));

Opt!PositionKind positionInSpecParents(in AllSymbols allSymbols, SpecDecl* a, Pos pos) =>
	eachSpecParent!PositionKind(*a, (SpecInst* parent, in TypeAst ast) =>
		optIf(hasPos(range(ast, allSymbols), pos), () =>
			optOrDefault!PositionKind(
				eachTypeArg!PositionKind(parent.typeArgs, ast, (in Type typeArg, in TypeAst argAst) =>
					positionInType(allSymbols, TypeContainer(a), typeArg, argAst, pos)),
				() => PositionKind(PositionKind.SpecUse(TypeContainer(a), parent)))));

Opt!PositionKind positionInSpecBody(in AllSymbols allSymbols, SpecDecl* a, Pos pos) =>
	a.body_.matchIn!(Opt!PositionKind)(
		(in SpecDeclBody.Builtin) =>
			//TODO: keyword position
			none!PositionKind,
		(in SpecDeclSig[] sigs) =>
			firstZipPointerFirst!(PositionKind, SpecDeclSig, SpecSigAst)(
				sigs,
				a.ast.body_.as!(SpecSigAst[]),
				(SpecDeclSig* sig, SpecSigAst sigAst) =>
					positionInSpecSig(allSymbols, a, sig, sigAst, pos)));

Opt!PositionKind positionInSpecSig(
	in AllSymbols allSymbols,
	SpecDecl* spec,
	SpecDeclSig* sig,
	in SpecSigAst ast,
	Pos pos,
) =>
	hasPos(ast.range, pos)
		? optOr!PositionKind(
			optIf(hasPos(allSymbols, ast.nameAndRange, pos), () =>
				PositionKind(PositionKind.SpecSig(spec, sig))),
			() => positionInType(allSymbols, TypeContainer(spec), sig.returnType, ast.returnType, pos),
			() => positionInParams(allSymbols, LocalContainer(spec), Params(sig.params), pos))
		: none!PositionKind;

Opt!PositionKind positionInStructBody(
	in AllSymbols allSymbols,
	StructDecl* decl,
	ref StructBody body_,
	in StructBodyAst ast,
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
			firstZipPointerFirst!(PositionKind, RecordField, StructBodyAst.Record.Field)(
				x.fields,
				ast.as!(StructBodyAst.Record).fields,
				(RecordField* field, StructBodyAst.Record.Field fieldAst) =>
					positionInRecordField(allSymbols, decl, field, fieldAst, pos)),
		(StructBody.Union) =>
			//TODO
			none!PositionKind);

Opt!PositionKind positionInRecordField(
	in AllSymbols allSymbols,
	StructDecl* decl,
	RecordField* field,
	in StructBodyAst.Record.Field fieldAst,
	Pos pos,
) =>
	optOr!PositionKind(
		positionInVisibility(VisibilityContainer(field), fieldAst, pos),
		() => optIf(hasPos(allSymbols, fieldAst.name, pos), () =>
			PositionKind(PositionKind.RecordFieldPosition(decl, field))),
		() => has(fieldAst.mutability)
			? positionInFieldMutability(allSymbols, force(fieldAst.mutability), pos)
			: none!PositionKind,
		() => positionInType(allSymbols, TypeContainer(decl), field.type, fieldAst.type, pos));

Opt!PositionKind positionInFieldMutability(in AllSymbols allSymbols, in FieldMutabilityAst ast, Pos pos) =>
	optIf(
		hasPos(rangeOfStartAndLength(ast.pos, stringOfFieldMutabilityAstKind(ast.kind).length), pos),
		() => PositionKind(PositionKind.RecordFieldMutability(ast.kind)));

Opt!PositionKind positionInExpr(in AllSymbols allSymbols, ExprContainer container, ref Expr a, Pos pos) {
	if (!hasPos(a.range, pos))
		return none!PositionKind;
	else {
		Opt!PositionKind here() =>
			some(PositionKind(PositionKind.Expression(container, &a)));
		Opt!PositionKind inDestructure(in Destructure x) =>
			positionInDestructure(allSymbols, container.toLocalContainer, x, pos);
		Opt!PositionKind recur(in Expr inner) =>
			positionInExpr(allSymbols, container, inner, pos);
		Opt!PositionKind recurOpt(in Opt!(Expr*) inner) =>
			has(inner)
				? recur(*force(inner))
				: none!PositionKind;

		return a.kind.match!(Opt!PositionKind)(
			(AssertOrForbidExpr x) =>
				optOr!PositionKind(
					recur(*x.condition),
					() => recurOpt(x.thrown),
					() => here()),
			(BogusExpr _) =>
				none!PositionKind,
			(CallExpr x) =>
				optOr!PositionKind(
					first!(PositionKind, Expr)(x.args, (Expr y) => recur(y)),
					() => here()),
			(ClosureGetExpr _) =>
				here(),
			(ClosureSetExpr x) =>
				optOr!PositionKind(
					recur(*x.value),
					() => here()),
			(FunPointerExpr _) =>
				here(),
			(ref IfExpr x) =>
				optOr!PositionKind(
					recur(x.cond),
					() => recur(x.then),
					() => recur(x.else_),
					() => here()),
			(ref IfOptionExpr x) =>
				optOr!PositionKind(
					inDestructure(x.destructure),
					() => recur(x.option.expr),
					() => recur(x.then),
					() => recur(x.else_),
					() => here()),
			(ref LambdaExpr x) =>
				optOr!PositionKind(
					inDestructure(x.param),
					() => recur(x.body_),
					() => here()),
			(ref LetExpr x) =>
				optOr!PositionKind(
					inDestructure(x.destructure),
					() => recur(x.value),
					() => recur(x.then),
					() => here()),
			(ref LiteralExpr _) =>
				here(),
			(LiteralCStringExpr _) =>
				here(),
			(LiteralSymbolExpr _) =>
				here(),
			(LocalGetExpr _) =>
				here(),
			(ref LocalSetExpr _) =>
				here(),
			(ref LoopExpr x) =>
				optOr!PositionKind(recur(x.body_), () => here()),
			(ref LoopBreakExpr x) =>
				optOr!PositionKind(recur(x.value), () => here()),
			(LoopContinueExpr _) =>
				here(),
			(ref LoopUntilExpr x) =>
				optOr!PositionKind(recur(x.condition), () => recur(x.body_), () => here()),
			(ref LoopWhileExpr x) =>
				optOr!PositionKind(recur(x.condition), () => recur(x.body_), () => here()),
			(ref MatchEnumExpr x) =>
				optOr!PositionKind(
					recur(x.matched.expr),
					() => first!(PositionKind, Expr)(x.cases, (Expr y) => recur(y)),
					() => here()),
			(ref MatchUnionExpr x) =>
				optOr!PositionKind(
					recur(x.matched.expr),
					() => first!(PositionKind, MatchUnionExpr.Case)(x.cases, (MatchUnionExpr.Case case_) =>
						optOr!PositionKind(
							inDestructure(case_.destructure),
							() => recur(case_.then)))),
			(ref PtrToFieldExpr x) =>
				optOr!PositionKind(
					recur(x.target.expr),
					() => here()),
			(PtrToLocalExpr) =>
				here(),
			(ref SeqExpr x) =>
				optOr!PositionKind(recur(x.first), () => recur(x.then)),
			(ref ThrowExpr x) =>
				optOr!PositionKind(recur(x.thrown), () => here()));
	}
}

Opt!PositionKind positionInType(in AllSymbols allSymbols, TypeContainer container, Type type, TypeAst ast, Pos pos) =>
	hasPos(range(ast, allSymbols), pos)
		? optOr!PositionKind(
			eachTypeComponent!PositionKind(type, ast, (in Type t, in TypeAst a) =>
				positionInType(allSymbols, container, t, a, pos)),
			() => some(PositionKind(TypeWithContainer(type, container))))
		: none!PositionKind;

bool hasPos(in AllSymbols allSymbols, in NameAndRange nr, Pos pos) =>
	hasPos(rangeOfNameAndRange(nr, allSymbols), pos);

bool optHasPos(in Opt!Range a, Pos p) =>
	has(a) && hasPos(force(a), p);
