module frontend.ide.getPosition;

@safe @nogc pure nothrow:

import frontend.ide.ideUtil : eachTypeArg, eachTypeComponent, specsMatch;
import frontend.ide.position : ExprContainer, LocalContainer, Position, PositionKind, VisibilityContainer;
import model.ast :
	DestructureAst,
	ExprAst,
	FieldMutabilityAst,
	FunDeclAst,
	ModifierAst,
	IfOptionAst,
	ImportOrExportAst,
	LambdaAst,
	LetAst,
	MatchAst,
	NameAndRange,
	paramsArray,
	ParamsAst,
	pathRange,
	range,
	rangeOfDestructureSingle,
	rangeOfMutKeyword,
	rangeOfNameAndRange,
	SpecSigAst,
	StructBodyAst,
	StructDeclAst,
	TestAst,
	TypeAst;
import model.diag : TypeContainer, TypeWithContainer;
import model.model :
	AssertOrForbidExpr,
	BogusExpr,
	BuiltinType,
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
	SpecInst,
	StructBody,
	SpecDecl,
	SpecDeclSig,
	StructAlias,
	StructDecl,
	Test,
	ThrowExpr,
	TrustedExpr,
	Type,
	TypeParamIndex,
	VarDecl;
import model.model : paramsArray, StructDeclSource;
import util.col.array : first, firstPointer, firstWithIndex, firstZip, firstZipPointerFirst, isEmpty, SmallArray;
import util.opt : force, has, none, Opt, optIf, optOr, optOr, optOrDefault, some;
import util.sourceRange : hasPos, Pos, Range;
import util.symbol : AllSymbols;
import util.union_ : Union;
import util.uri : AllUris;
import util.util : enumConvert;

Position getPosition(in AllSymbols allSymbols, in AllUris allUris, Module* module_, Pos pos) {
	Opt!PositionKind kind = getPositionKind(allSymbols, allUris, *module_, pos);
	return Position(module_, has(kind) ? force(kind) : PositionKind(PositionKind.None()));
}

private:

Opt!PositionKind getPositionKind(in AllSymbols allSymbols, in AllUris allUris, ref Module module_, Pos pos) =>
	optOr!PositionKind(
		positionInImportsOrExports(allSymbols, allUris, module_.imports, pos),
		() => positionInImportsOrExports(allSymbols, allUris, module_.reExports, pos),
		() => firstPointer!(PositionKind, StructAlias)(module_.aliases, (StructAlias* x) =>
			hasPos(x.range.range, pos)
				? positionInAlias(allSymbols, x, pos)
				: none!PositionKind),
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
				? positionInFun(allSymbols, x, x.source.as!(FunDeclSource.Ast).ast, pos)
				: none!PositionKind),
		() => firstPointer!(PositionKind, Test)(module_.tests, (Test* x) =>
			hasPos(x.ast.range, pos)
				? some(positionInTest(allSymbols, x, *x.ast, pos))
				: none!PositionKind));

Opt!PositionKind positionInFun(in AllSymbols allSymbols, FunDecl* a, in FunDeclAst* ast, Pos pos) =>
	optOr!PositionKind(
		positionInVisibility(VisibilityContainer(a), ast, pos),
		() => optIf(hasPos(allSymbols, ast.name, pos), () => PositionKind(a)),
		() => positionInTypeParams(allSymbols, TypeContainer(a), ast.typeParams, pos),
		() => positionInType(allSymbols, TypeContainer(a), a.returnType, ast.returnType, pos),
		() => positionInParams(allSymbols, LocalContainer(a), a.params, ast.params, pos),
		() => positionInModifiers(allSymbols, TypeContainer(a), some(a.specs), ast.modifiers, pos),
		() => a.body_.isA!(FunBody.ExpressionBody)
			? positionInExpr(allSymbols, ExprContainer(a), a.body_.as!(FunBody.ExpressionBody).expr, pos)
			: none!PositionKind);

PositionKind positionInTest(in AllSymbols allSymbols, Test* a, in TestAst ast, Pos pos) =>
	optOrDefault!PositionKind(
		positionInExpr(allSymbols, ExprContainer(a), a.body_, pos),
		() => PositionKind(a));

Opt!PositionKind positionInParams(
	in AllSymbols allSymbols,
	LocalContainer container,
	in Params params,
	in ParamsAst ast,
	Pos pos,
) =>
	firstZip!(PositionKind, Destructure, DestructureAst)(
		paramsArray(params), paramsArray(ast), (Destructure x, DestructureAst y) =>
			positionInDestructure(allSymbols, container, x, y, pos));

Opt!PositionKind positionInModifiers(
	in AllSymbols allSymbols,
	TypeContainer container,
	in Opt!(SmallArray!(immutable SpecInst*)) specs,
	in ModifierAst[] modifiers,
	Pos pos,
) =>
	firstWithIndex!(PositionKind, ModifierAst)(modifiers, (size_t index, ModifierAst modifier) =>
		optIf(hasPos(modifier.range(allSymbols), pos), () =>
			positionInModifier(allSymbols, container, specs, modifiers, index, modifier, pos)));

PositionKind positionInModifier(
	in AllSymbols allSymbols,
	TypeContainer container,
	Opt!(SmallArray!(immutable SpecInst*)) specs,
	in ModifierAst[] modifiers,
	size_t index,
	in ModifierAst modifier,
	Pos pos,
) =>
	modifier.matchIn!PositionKind(
		(in ModifierAst.Keyword x) =>
			PositionKind(PositionKind.Modifier(container, x.kind)),
		(in ModifierAst.Extern x) =>
			container.isA!(FunDecl*) && container.as!(FunDecl*).body_.isA!(FunBody.Extern)
				? PositionKind(PositionKind.ModifierExtern(
					container.as!(FunDecl*).body_.as!(FunBody.Extern).libraryName))
				: PositionKind(PositionKind.None()),
		(in TypeAst x) {
			if (has(specs) && specsMatch(force(specs), modifiers)) {
				// Find the corresponding spec
				size_t specIndex = 0;
				foreach (ref ModifierAst prevModifier; modifiers[0 .. index])
					if (prevModifier.isA!TypeAst)
						specIndex++;

				SpecInst* spec = force(specs)[specIndex];
				return optOrDefault!PositionKind(
					positionInTypeArgs(allSymbols, container, spec.typeArgs, x, pos),
					() => PositionKind(PositionKind.SpecUse(container, force(specs)[specIndex])));
			} else
				return PositionKind(PositionKind.None());
		});

Opt!PositionKind positionInDestructure(
	in AllSymbols allSymbols,
	LocalContainer container,
	in Destructure a,
	in DestructureAst destructureAst,
	Pos pos,
) {
	Opt!PositionKind handleSingle(Type type, in PositionKind delegate() @safe @nogc pure nothrow cbName) {
		DestructureAst.Single ast = destructureAst.as!(DestructureAst.Single);
		return hasPos(rangeOfDestructureSingle(ast, allSymbols), pos)
			? optOr!PositionKind(
				optIf(hasPos(rangeOfNameAndRange(ast.name, allSymbols), pos), cbName),
				() => optIf(optHasPos(rangeOfMutKeyword(ast), pos), () =>
					PositionKind(PositionKind.Keyword(PositionKind.Keyword.Kind.localMut))),
				() => has(ast.type)
					? positionInType(allSymbols, container.toTypeContainer(), type, *force(ast.type), pos)
					: none!PositionKind)
			: none!PositionKind;
	}
	return a.matchWithPointers!(Opt!PositionKind)(
		(Destructure.Ignore* x) =>
			destructureAst.isA!(DestructureAst.Void)
				? none!PositionKind
				: handleSingle(x.type, () => PositionKind(PositionKind.Keyword(PositionKind.Keyword.Kind.underscore))),
		(Local* x) =>
			handleSingle(x.type, () => PositionKind(PositionKind.LocalPosition(container, x))),
		(Destructure.Split* x) =>
			isEmpty(x.parts)
				? none!PositionKind
				: firstZip!(PositionKind, Destructure, DestructureAst)(
					x.parts, destructureAst.as!(DestructureAst[]), (Destructure part, DestructureAst partAst) =>
						positionInDestructure(allSymbols, container, part, partAst, pos)));
}

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
			PositionKind(PositionKind.Keyword(enumConvert!(PositionKind.Keyword.Kind)(a.kind)))),
		() => positionInType(allSymbols, TypeContainer(a), a.type, a.ast.type, pos));

Opt!PositionKind positionInAlias(in AllSymbols allSymbols, StructAlias* a, Pos pos) =>
	optOr!PositionKind(
		positionInVisibility(VisibilityContainer(a), a.ast, pos),
		() => optIf(hasPos(nameRange(allSymbols, *a).range, pos), () => PositionKind(a)),
		() => optIf(hasPos(a.ast.keywordRange, pos), () =>
			PositionKind(PositionKind.Keyword(PositionKind.Keyword.Kind.alias_))),
		() => has(a.target)
			? positionInType(allSymbols, TypeContainer(a), Type(force(a.target)), a.ast.target, pos)
			: none!PositionKind);

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
		() => positionInModifiers(
			allSymbols, TypeContainer(a), none!(SmallArray!(immutable SpecInst*)), ast.modifiers, pos),
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
	pos == ast.range.start && has(ast.visibility)
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
		() => positionInModifiers(allSymbols, TypeContainer(a), some(a.parents), a.ast.modifiers, pos),
		() => positionInSpecSigs(allSymbols, a, pos));

Opt!PositionKind positionInSpecSigs(in AllSymbols allSymbols, SpecDecl* a, Pos pos) =>
	firstZipPointerFirst!(PositionKind, SpecDeclSig, SpecSigAst)(
		a.sigs, a.ast.sigs, (SpecDeclSig* sig, SpecSigAst sigAst) =>
			positionInSpecSig(allSymbols, a, sig, sigAst, pos));

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
			() => positionInParams(allSymbols, LocalContainer(spec), Params(sig.params), ast.params, pos))
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
		(BuiltinType _) =>
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
		hasPos(ast.range, pos),
		() => PositionKind(PositionKind.RecordFieldMutability(ast.visibility)));

Opt!PositionKind positionInExpr(in AllSymbols allSymbols, ExprContainer container, ref Expr a, Pos pos) {
	if (!hasPos(a.range, pos))
		return none!PositionKind;
	else {
		ExprAst* ast = a.ast;
		Opt!PositionKind here() =>
			some(PositionKind(PositionKind.Expression(container, &a)));
		Opt!PositionKind inDestructure(in Destructure x, in DestructureAst y) =>
			positionInDestructure(allSymbols, container.toLocalContainer, x, y, pos);
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
					inDestructure(x.destructure, ast.kind.as!(IfOptionAst*).destructure),
					() => recur(x.option.expr),
					() => recur(x.then),
					() => recur(x.else_),
					() => here()),
			(ref LambdaExpr x) =>
				optOr!PositionKind(
					inDestructure(x.param, ast.kind.as!(LambdaAst*).param),
					() => recur(x.body_),
					() => here()),
			(ref LetExpr x) =>
				optOr!PositionKind(
					inDestructure(x.destructure, ast.kind.as!(LetAst*).destructure),
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
					() => firstZip!(PositionKind, MatchUnionExpr.Case, MatchAst.CaseAst)(
						x.cases,
						ast.kind.as!(MatchAst*).cases,
						(MatchUnionExpr.Case case_, MatchAst.CaseAst caseAst) =>
							optOr!PositionKind(
								has(caseAst.destructure)
									? inDestructure(case_.destructure, force(caseAst.destructure))
									: none!PositionKind,
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
				optOr!PositionKind(recur(x.thrown), () => here()),
			(ref TrustedExpr x) =>
				optOr!PositionKind(recur(x.inner), () => here()));
	}
}

Opt!PositionKind positionInType(in AllSymbols allSymbols, TypeContainer container, Type type, TypeAst ast, Pos pos) =>
	hasPos(range(ast, allSymbols), pos)
		? optOr!PositionKind(
			eachTypeComponent!PositionKind(type, ast, (in Type t, in TypeAst a) =>
				positionInType(allSymbols, container, t, a, pos)),
			() => some(PositionKind(TypeWithContainer(type, container))))
		: none!PositionKind;

Opt!PositionKind positionInTypeArgs(
	in AllSymbols allSymbols,
	TypeContainer container,
	in Type[] typeArgs,
	TypeAst ast,
	Pos pos,
) =>
	eachTypeArg!PositionKind(typeArgs, ast, (in Type t, in TypeAst a) =>
		positionInType(allSymbols, container, t, a, pos));

bool hasPos(in AllSymbols allSymbols, in NameAndRange nr, Pos pos) =>
	hasPos(rangeOfNameAndRange(nr, allSymbols), pos);

bool optHasPos(in Opt!Range a, Pos p) =>
	has(a) && hasPos(force(a), p);
