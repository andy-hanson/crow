module frontend.ide.getReferences;

@safe @nogc pure nothrow:

import frontend.ide.getTarget : exprTarget, Target, targetForPosition;
import frontend.ide.ideUtil :
	eachDestructureComponent, eachTypeComponent, eachDescendentExprExcluding, eachDescendentExprIncluding;
import frontend.ide.position : Position, PositionKind;
import frontend.parse.ast : DestructureAst, FunDeclAst, paramsArray, pathRange, range, StructDeclAst, TypeAst;
import model.model :
	body_,
	Called,
	Destructure,
	decl,
	Expr,
	ExprKind,
	FunBody,
	FunDecl,
	FunDeclSource,
	FunInst,
	ImportOrExport,
	Local,
	LocalSource,
	localMustHaveNameRange,
	loopKeywordRange,
	Module,
	paramsArray,
	Program,
	range,
	RecordField,
	SpecDecl,
	SpecDeclSig,
	StructBody,
	StructDecl,
	StructInst,
	Test,
	Type,
	UnionMember,
	VarDecl,
	Visibility;
import util.alloc.alloc : Alloc;
import util.col.arrBuilder : add, ArrBuilder, finishArr;
import util.col.arrUtil : zip;
import util.col.map : mapEach, mustGetAt;
import util.json : Json, jsonList;
import util.lineAndColumnGetter : LineAndColumnGetters;
import util.opt : force, has, none, Opt, optEqual, some;
import util.ptr : ptrTrustMe;
import util.sourceRange : UriAndRange, jsonOfUriAndRange;
import util.sym : AllSymbols;
import util.uri : AllUris, Uri;
import util.util : typeAs, verify;

UriAndRange[] getReferencesForPosition(
	ref Alloc alloc,
	in AllSymbols allSymbols,
	in AllUris allUris,
	in Program program,
	ref Position pos,
) {
	Opt!Target target = targetForPosition(program, pos.kind);
	return has(target) ? referencesForTarget(alloc, allSymbols, allUris, program, pos.module_, force(target)) : [];
}

Json jsonOfReferences(
	ref Alloc alloc,
	in AllUris allUris,
	scope ref LineAndColumnGetters lineAndColumnGetters,
	in UriAndRange[] references,
) =>
	jsonList!UriAndRange(alloc, references, (in UriAndRange x) =>
		jsonOfUriAndRange(alloc, allUris, lineAndColumnGetters, x));

private:

UriAndRange[] referencesForTarget(
	ref Alloc alloc,
	in AllSymbols allSymbols,
	in AllUris allUris,
	in Program program,
	in Module* curModule,
	return scope ref Target a,
) =>
	a.matchWithPointers!(UriAndRange[])(
		(FunDecl* x) =>
			referencesForFunDecl(alloc, program, x),
		(PositionKind.ImportedName x) =>
			typeAs!(UriAndRange[])([]), //TODO: this should be references in the current module only
		(PositionKind.LocalInFunction x) =>
			referencesForLocal(alloc, allSymbols, program, curModule.uri, x),
		(ExprKind.Loop* x) =>
			referencesForLoop(alloc, curModule.uri, *x),
		(Module* x) =>
			referencesForModule(alloc, allUris, program, x),
		(RecordField* x) =>
			// TODO (get references for the get/set functions, plus ExprKind.PtrToField)
			typeAs!(UriAndRange[])([]),
		(SpecDecl* x) =>
			// TODO (search all functions)
			typeAs!(UriAndRange[])([]),
		(SpecDeclSig* x) =>
			// TODO (find call references)
			typeAs!(UriAndRange[])([]),
		(StructDecl* x) =>
			referencesForStructDecl(alloc, allSymbols, program, x),
		(PositionKind.TypeParamWithContainer x) =>
			referencesForTypeParam(alloc, allSymbols, curModule.uri, x));

UriAndRange[] referencesForLocal(
	ref Alloc alloc,
	in AllSymbols allSymbols,
	in Program program,
	Uri curUri,
	in PositionKind.LocalInFunction a,
) {
	ArrBuilder!UriAndRange res;
	add(alloc, res, localMustHaveNameRange(*a.local, allSymbols));
	Expr body_ = a.containingFun.body_.isA!(FunBody.ExpressionBody)
		? a.containingFun.body_.as!(FunBody.ExpressionBody).expr
		: Expr(UriAndRange.empty, ExprKind(ExprKind.Bogus()));
	eachDescendentExprIncluding(body_, (in Expr x) @safe {
		Opt!Target xTarget = exprTarget(program, PositionKind.Expression(a.containingFun, ptrTrustMe(x)));
		if (optEqual!Target(xTarget, some(Target(a))))
			add(alloc, res, x.range);
	});
	return finishArr(alloc, res);
}

UriAndRange[] referencesForLoop(ref Alloc alloc, Uri curUri, in ExprKind.Loop loop) {
	ArrBuilder!UriAndRange res;
	add(alloc, res, UriAndRange(curUri, loopKeywordRange(loop)));
	eachDescendentExprExcluding(ExprKind(&loop), (in Expr child) {
		if (child.kind.isA!(ExprKind.LoopBreak*) || child.kind.isA!(ExprKind.LoopContinue))
			add(alloc, res, child.range);
	});
	return finishArr(alloc, res);
}

UriAndRange[] referencesForTypeParam(
	ref Alloc alloc,
	in AllSymbols allSymbols,
	Uri curUri,
	in PositionKind.TypeParamWithContainer a,
) {
	ArrBuilder!UriAndRange res;
	add(alloc, res, a.typeParam.range);
	scope TypeCb cb = (in Type type, in TypeAst ast) {
		if (type == Type(a.typeParam))
			add(alloc, res, UriAndRange(curUri, range(ast, allSymbols)));
	};
	a.container.matchIn!void(
		(in FunDecl x) =>
			eachTypeInFun(x, cb),
		(in SpecDecl x) =>
			eachTypeInSpec(x, cb),
		(in StructDecl x) =>
			eachTypeInStruct(x, cb));
	return finishArr(alloc, res);
}

alias TypeCb = void delegate(in Type, in TypeAst) @safe @nogc pure nothrow;

void eachTypeInModule(in Module a, in TypeCb cb) {
	foreach (ref StructDecl x; a.structs)
		eachTypeInStruct(x, cb);
	foreach (ref VarDecl x; a.vars) {
		// TODO
	}
	foreach (ref SpecDecl x; a.specs)
		eachTypeInSpec(x, cb);
	foreach (ref FunDecl x; a.funs)
		eachTypeInFun(x, cb);
	foreach (ref Test x; a.tests)
		eachTypeInExpr(x.body_, cb);
}

void eachTypeInFun(in FunDecl a, in TypeCb cb) {
	if (a.source.isA!(FunDeclSource.Ast)) {
		FunDeclAst* ast = a.source.as!(FunDeclSource.Ast).ast;
		eachTypeInType(a.returnType, ast.returnType, cb);
		zip!(Destructure, DestructureAst)(
			paramsArray(a.params),
			paramsArray(ast.params),
			(ref Destructure d, ref DestructureAst _) {
				eachTypeInDestructure(d, cb);
			});
		// TODO: search in specs
		if (a.body_.isA!(FunBody.ExpressionBody))
			eachTypeInExpr(a.body_.as!(FunBody.ExpressionBody).expr, cb);
	}
}

void eachTypeInSpec(in SpecDecl a, in TypeCb cb) {
	// TODO
}

void eachTypeInStruct(in StructDecl a, in TypeCb cb) {
	if (has(a.ast)) {
		StructDeclAst* ast = force(a.ast);
		body_(a).matchIn!void(
			(in StructBody.Bogus) {},
			(in StructBody.Builtin) {},
			(in StructBody.Enum) {
				// TODO: references for backingType
			},
			(in StructBody.Extern) {},
			(in StructBody.Flags) {
				// TODO: references for backingType
			},
			(in StructBody.Record x) {
				zip!(RecordField, StructDeclAst.Body.Record.Field)(
					x.fields,
					ast.body_.as!(StructDeclAst.Body.Record).fields,
					(ref RecordField field, ref StructDeclAst.Body.Record.Field fieldAst) {
						eachTypeInType(field.type, fieldAst.type, cb);
					});
			},
			(in StructBody.Union x) {
				zip!(UnionMember, StructDeclAst.Body.Union.Member)(
					x.members,
					ast.body_.as!(StructDeclAst.Body.Union).members,
					(ref UnionMember member, ref StructDeclAst.Body.Union.Member memberAst) {
						if (has(memberAst.type))
							eachTypeInType(member.type, force(memberAst.type), cb);
					});
			});
	}
}

void eachTypeInType(in Type a, in TypeAst ast, in TypeCb cb) {
	cb(a, ast);
	Opt!bool res = eachTypeComponent!bool(a, ast, (in Type x, in TypeAst y) {
		eachTypeInType(x, y, cb);
		return none!bool;
	});
	verify(!has(res));
}

void eachTypeInDestructure(in Destructure a, in TypeCb cb) {
	Opt!bool res = eachDestructureComponent!bool(a, (Local* x) {
		DestructureAst.Single* ast = x.source.as!(LocalSource.Ast).ast;
		if (has(ast.type))
			cb(x.type, *force(ast.type));
		return none!bool;
	});
	verify(!has(res));
}

void eachTypeInExpr(in Expr expr, in TypeCb cb) {
	eachDescendentExprIncluding(expr, (in Expr x) {
		eachTypeDirectlyInExpr(x, cb);
	});
}

void eachTypeDirectlyInExpr(in Expr a, in TypeCb cb) {
	a.kind.matchIn!void(
		(in ExprKind.AssertOrForbid x) {},
		(in ExprKind.Bogus) {},
		(in ExprKind.Call x) {
			//TODO: types in explicit type args
		},
		(in ExprKind.ClosureGet) {},
		(in ExprKind.ClosureSet x) {},
		(in ExprKind.FunPtr) {
			//TODO: types in explicit type args
		},
		(in ExprKind.If x) {},
		(in ExprKind.IfOption x) {},
		(in ExprKind.Lambda x) {
			eachTypeInDestructure(x.param, cb);
		},
		(in ExprKind.Let x) {
			eachTypeInDestructure(x.destructure, cb);
		},
		(in ExprKind.Literal) {},
		(in ExprKind.LiteralCString) {},
		(in ExprKind.LiteralSymbol) {},
		(in ExprKind.LocalGet) {},
		(in ExprKind.LocalSet x) {},
		(in ExprKind.Loop x) {},
		(in ExprKind.LoopBreak x) {},
		(in ExprKind.LoopContinue) {},
		(in ExprKind.LoopUntil x) {},
		(in ExprKind.LoopWhile x) {},
		(in ExprKind.MatchEnum x) {},
		(in ExprKind.MatchUnion x) {
			foreach (ref ExprKind.MatchUnion.Case case_; x.cases) {
				eachTypeInDestructure(case_.destructure, cb);
			}
		},
		(in ExprKind.PtrToField x) {},
		(in ExprKind.PtrToLocal) {},
		(in ExprKind.Seq x) {},
		(in ExprKind.Throw x) {});
}

UriAndRange[] referencesForFunDecl(ref Alloc alloc, in Program program, in FunDecl* a) {
	ArrBuilder!UriAndRange res;
	eachModuleThatMayReference(program, a.visibility, moduleOf(program, a), (in Module module_) {
		foreach (ref FunDecl x; module_.funs) {
			if (x.body_.isA!(FunBody.ExpressionBody))
				referencesForFunDeclInExpr(alloc, res, a, x.body_.as!(FunBody.ExpressionBody).expr);
		}
	});
	return finishArr(alloc, res);
}

UriAndRange[] referencesForStructDecl(ref Alloc alloc, in AllSymbols allSymbols, in Program program, in StructDecl* a) {
	ArrBuilder!UriAndRange res;
	add(alloc, res, a.range);
	eachModuleThatMayReference(program, a.visibility, moduleOf(program, a), (in Module module_) {
		eachTypeInModule(module_, (in Type t, in TypeAst ast) {
			if (t.isA!(StructInst*) && decl(*t.as!(StructInst*)) == a)
				add(alloc, res, UriAndRange(module_.uri, range(ast, allSymbols)));
		});
	});
	return finishArr(alloc, res);
}

Module* moduleOf(T)(in Program program, in T t) =>
	mustGetAt(program.allModules, t.range.uri);

void referencesForFunDeclInExpr(ref Alloc alloc, scope ref ArrBuilder!UriAndRange res, in FunDecl* a, in Expr expr) {
	eachDescendentExprIncluding(expr, (in Expr x) {
		if (x.kind.isA!(ExprKind.Call)) {
			Called called = x.kind.as!(ExprKind.Call).called;
			if (called.isA!(FunInst*) && decl(*called.as!(FunInst*)) == a)
				add(alloc, res, x.range);
		} else if (x.kind.isA!(ExprKind.FunPtr)) {
			if (decl(*x.kind.as!(ExprKind.FunPtr).funInst) == a)
				add(alloc, res, x.range);
		}
	});
}

UriAndRange[] referencesForModule(ref Alloc alloc, in AllUris allUris, in Program program, in Module* target) {
	ArrBuilder!UriAndRange res;
	eachModuleReferencing(program, target, (in Module importer, in ImportOrExport ie) {
		if (has(ie.source))
			add(alloc, res, UriAndRange(importer.uri, pathRange(allUris, *force(ie.source))));
	});
	return finishArr(alloc, res);
}

void eachModuleThatMayReference(
	in Program program,
	Visibility visibility,
	Module* containingModule,
	in void delegate(in Module) @safe @nogc pure nothrow cb,
) {
	cb(*containingModule);
	if (visibility != Visibility.private_)
		eachModuleReferencing(program, containingModule, (in Module x, in ImportOrExport _) {
			cb(x);
		});
}

void eachModuleReferencing(
	in Program program,
	in Module* target,
	in void delegate(in Module, in ImportOrExport) @safe @nogc pure nothrow cb,
) {
	mapEach!(Uri, immutable Module*)(program.allModules, (Uri _, ref immutable Module* module_) {
		eachModuleReference(*module_, target, (in ImportOrExport x) {
			cb(*module_, x);
		});
	});
}

void eachModuleReference(in Module a, Module* b, in void delegate(in ImportOrExport) @safe @nogc pure nothrow cb) {
	void iter(in ImportOrExport[] xs) {
		foreach (ImportOrExport ie; xs) {
			if (ie.kind.modulePtr == b)
				cb(ie);
		}
	}
	iter(a.imports);
	iter(a.reExports);
}
