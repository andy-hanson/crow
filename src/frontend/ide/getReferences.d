module frontend.ide.getReferences;

@safe @nogc pure nothrow:

import frontend.ide.getDefinition : definitionForTarget;
import frontend.ide.getTarget : exprTarget, Target, targetForPosition;
import frontend.ide.ideUtil :
	eachDestructureComponent,
	eachFunSpec,
	eachSpecParent,
	eachTypeComponent,
	eachDescendentExprExcluding,
	eachDescendentExprIncluding,
	eachTypeArg,
	ReferenceCb;
import frontend.ide.position : Position, PositionKind;
import frontend.parse.ast :
	DestructureAst, FunDeclAst, ParamsAst, paramsArray, pathRange, range, StructDeclAst, TypeAst;
import model.model :
	body_,
	Called,
	CalledSpecSig,
	Destructure,
	decl,
	Expr,
	ExprKind,
	FunBody,
	FunDecl,
	FunDeclSource,
	FunInst,
	greatestVisibility,
	ImportOrExport,
	Local,
	LocalSource,
	Module,
	moduleUri,
	Params,
	paramsArray,
	Program,
	range,
	RecordField,
	SpecDecl,
	SpecDeclBody,
	SpecDeclSig,
	SpecInst,
	StructBody,
	StructDecl,
	StructInst,
	Test,
	Type,
	typeArgs,
	UnionMember,
	VarDecl,
	Visibility;
import util.alloc.alloc : Alloc;
import util.col.arr : only;
import util.col.arrBuilder : buildArray;
import util.col.arrUtil : allSame, contains, find, fold, zip, zipIn;
import util.col.map : mapEach, mustGetAt;
import util.col.mutMaxArr : mutMaxArr, MutMaxArr, push, tempAsArr;
import util.json : Json, jsonList;
import util.lineAndColumnGetter : LineAndColumnGetters;
import util.opt : force, has, none, Opt, optEqual, some;
import util.ptr : ptrTrustMe;
import util.sourceRange : UriAndRange, jsonOfUriAndRange;
import util.sym : AllSymbols, prependSet, Sym;
import util.uri : AllUris, Uri;
import util.util : todo, verify;

UriAndRange[] getReferencesForPosition(
	ref Alloc alloc,
	scope ref AllSymbols allSymbols,
	in AllUris allUris,
	in Program program,
	ref Position pos,
) {
	Opt!Target target = targetForPosition(program, pos.kind);
	return has(target)
		? buildArray!UriAndRange(alloc, (in ReferenceCb cb) {
			definitionForTarget(allSymbols, pos.module_.uri, force(target), cb);
			referencesForTarget(allSymbols, allUris, program, pos.module_.uri, force(target), cb);
		})
		: [];
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

void referencesForTarget(
	scope ref AllSymbols allSymbols,
	in AllUris allUris,
	in Program program,
	Uri curUri,
	in Target a,
	in ReferenceCb cb,
) =>
	a.matchWithPointers!void(
		(StructBody.Enum.Member* x) {
			referencesForEnumMember(program, x, cb);
		},
		(FunDecl* x) {
			referencesForFunDecls(program, [x], cb);
		},
		(PositionKind.ImportedName x) {
			//TODO: this should be references in the current module only
		},
		(PositionKind.LocalPosition x) {
			referencesForLocal(allSymbols, program, curUri, x, cb);
		},
		(ExprKind.Loop* x) {
			referencesForLoop(curUri, *x, cb);
		},
		(Module* x) {
			referencesForModule(allUris, program, x, cb);
		},
		(RecordField* x) {
			referencesForRecordField(program, *x, cb);
		},
		(SpecDecl* x) {
			referencesForSpecDecl(allSymbols, program, x, cb);
		},
		(PositionKind.SpecSig x) {
			referencesForSpecSig(allSymbols, program, x, cb);
		},
		(StructDecl* x) {
			referencesForStructDecl(allSymbols, program, x, cb);
		},
		(PositionKind.TypeParamWithContainer x) {
			referencesForTypeParam(allSymbols, curUri, x, cb);
		},
		(VarDecl* x) {
			referencesForVarDecl(allSymbols, program, x, cb);
		});

void referencesForLocal(
	in AllSymbols allSymbols,
	in Program program,
	Uri curUri,
	in PositionKind.LocalPosition a,
	in ReferenceCb cb,
) {
	a.container.match!void(
		(ref FunDecl fun) {
			Expr body_ = fun.body_.isA!(FunBody.ExpressionBody)
				? fun.body_.as!(FunBody.ExpressionBody).expr
				: Expr(UriAndRange.empty, ExprKind(ExprKind.Bogus()));
			eachDescendentExprIncluding(body_, (in Expr x) @safe {
				Opt!Target xTarget = exprTarget(program, PositionKind.Expression(&fun, ptrTrustMe(x)));
				if (optEqual!Target(xTarget, some(Target(a))))
					cb(x.range);
			});
		},
		(ref SpecDecl) {});
}

void referencesForLoop(Uri curUri, in ExprKind.Loop loop, in ReferenceCb cb) {
	eachDescendentExprExcluding(ExprKind(&loop), (in Expr child) {
		if (child.kind.isA!(ExprKind.LoopBreak*) || child.kind.isA!(ExprKind.LoopContinue))
			cb(child.range);
	});
}

void referencesForTypeParam(
	in AllSymbols allSymbols,
	Uri curUri,
	in PositionKind.TypeParamWithContainer a,
	in ReferenceCb refCb,
) {
	scope TypeCb typeCb = (in Type type, in TypeAst ast) {
		if (type == Type(a.typeParam))
			refCb(UriAndRange(curUri, range(ast, allSymbols)));
	};
	a.container.matchIn!void(
		(in FunDecl x) =>
			eachTypeInFun(x, typeCb),
		(in SpecDecl x) =>
			eachTypeInSpec(x, typeCb),
		(in StructDecl x) =>
			eachTypeInStruct(x, typeCb));
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
		eachTypeInParams(a.params, ast.params, cb);
		// TODO: search in specs
		if (a.body_.isA!(FunBody.ExpressionBody))
			eachTypeInExpr(a.body_.as!(FunBody.ExpressionBody).expr, cb);
	}
}

void eachTypeInSpec(in SpecDecl a, in TypeCb cb) {
	eachSpecParent(a, (SpecInst* parent, in TypeAst ast) {
		eachTypeArg(typeArgs(*parent), ast, cb);
	});
	a.body_.matchIn!void(
		(in SpecDeclBody.Builtin) {},
		(in SpecDeclSig[] sigs) {
			foreach (ref SpecDeclSig sig; sigs) {
				eachTypeInType(sig.returnType, sig.ast.returnType, cb);
				eachTypeInParams(Params(sig.params), sig.ast.params, cb);
			}
		});
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

void eachTypeInParams(in Params a, in ParamsAst asts, in TypeCb cb) {
	zip!(Destructure, DestructureAst)(paramsArray(a), paramsArray(asts), (ref Destructure x, ref DestructureAst _) {
		eachTypeInDestructure(x, cb);
	});
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

void referencesForFunDecls(in Program program, in FunDecl*[] decls, in ReferenceCb cb) {
	Visibility maxVisibility = fold(Visibility.private_, decls, (Visibility a, in FunDecl* b) =>
		greatestVisibility(a, b.visibility));
	verify(allSame!(Uri, FunDecl*)(decls, (in FunDecl* x) => moduleUri(*x)));
	eachExprThatMayReference(program, maxVisibility, moduleOf(program, moduleUri(*decls[0])), (in Expr x) {
		if (x.kind.isA!(ExprKind.Call)) {
			Called called = x.kind.as!(ExprKind.Call).called;
			if (called.isA!(FunInst*) && contains(decls, decl(*called.as!(FunInst*))))
				cb(x.range);
		} else if (x.kind.isA!(ExprKind.FunPtr)) {
			if (contains(decls, decl(*x.kind.as!(ExprKind.FunPtr).funInst)))
				cb(x.range);
		}
	});
}

void eachExprThatMayReference(
	in Program program,
	Visibility visibility,
	Module* module_,
	in void delegate(in Expr) @safe @nogc pure nothrow cb,
) {
	eachModuleThatMayReference(program, visibility, module_, (in Module module_) {
		foreach (ref FunDecl fun; module_.funs) {
			if (fun.body_.isA!(FunBody.ExpressionBody))
				eachDescendentExprIncluding(fun.body_.as!(FunBody.ExpressionBody).expr, cb);
		}
		foreach (ref Test test; module_.tests)
			eachDescendentExprIncluding(test.body_, cb);
	});
}

void referencesForSpecSig(in AllSymbols allSymbols, in Program program, in PositionKind.SpecSig a, in ReferenceCb cb) {
	eachExprThatMayReference(program, a.spec.visibility, moduleOf(program, a.spec.moduleUri), (in Expr x) {
		if (x.kind.isA!(ExprKind.Call)) {
			Called called = x.kind.as!(ExprKind.Call).called;
			if (called.isA!(CalledSpecSig*) && called.as!(CalledSpecSig*).nonInstantiatedSig == a.sig)
				cb(x.range);
		} else if (x.kind.isA!(ExprKind.FunPtr)) {
			// Currently doesn't support specs
			verify(x.kind.as!(ExprKind.FunPtr).funInst != null);
		}
	});
}

void referencesForRecordField(in Program program, in RecordField field, in ReferenceCb cb) {
	withRecordFieldFunctions(program, field, (in FunDecl*[] funs) {
		referencesForFunDecls(program, funs, cb);
	});
}

void referencesForEnumMember(in Program program, in StructBody.Enum.Member* x, in ReferenceCb cb) {
	// Find the corresponding creation function
	todo!void("!!!");
}

void referencesForVarDecl(scope ref AllSymbols allSymbols, in Program program, in VarDecl* a, in ReferenceCb cb) {
	// Find references to get/set
	Module* module_ = moduleOf(program, a.moduleUri);
	Opt!(FunDecl*) getter = find(funsNamed(module_, a.name), (in FunDecl* x) =>
		x.body_.isA!(FunBody.VarGet) && x.body_.as!(FunBody.VarGet).var == a);
	Opt!(FunDecl*) setter = find(funsNamed(module_, prependSet(allSymbols, a.name)), (in FunDecl* x) =>
		x.body_.isA!(FunBody.VarSet) && x.body_.as!(FunBody.VarSet).var == a);
	referencesForFunDecls(program, [force(getter), force(setter)], cb);
}

void withRecordFieldFunctions(
	in Program program,
	in RecordField field,
	in void delegate(in FunDecl*[]) @safe @nogc pure nothrow cb,
) {
	MutMaxArr!(3, FunDecl*) res = mutMaxArr!(3, FunDecl*);
	foreach (FunDecl* fun; funsNamed(moduleOf(program, field.containingRecord.moduleUri), field.name)) {
		if (isRecordFieldFunction(fun.body_)) {
			Type paramType = only(fun.params.as!(Destructure[])).type;
			// TODO: for RecordFieldPointer we need to look for pointer to the struct
			if (paramType.isA!(StructInst*) && decl(*paramType.as!(StructInst*)) == field.containingRecord)
				push(res, fun);
		}
	}
	cb(tempAsArr(res));
}

immutable(FunDecl*)[] funsNamed(in Module* module_, Sym name) =>
	mustGetAt(module_.allExportedNames, name).funs;

bool isRecordFieldFunction(in FunBody a) =>
	a.isA!(FunBody.RecordFieldGet) || a.isA!(FunBody.RecordFieldPointer) || a.isA!(FunBody.RecordFieldSet);

void referencesForSpecDecl(in AllSymbols allSymbols, in Program program, in SpecDecl* a, in ReferenceCb refCb) {
	eachModuleThatMayReference(program, a.visibility, moduleOf(program, a.moduleUri), (in Module module_) {
		scope void delegate(in SpecInst*, in TypeAst) @safe @nogc pure nothrow cb = (spec, ast) {
			if (decl(*spec) == a)
				refCb(UriAndRange(module_.uri, range(ast, allSymbols)));
		};
		foreach (ref SpecDecl spec; module_.specs)
			zipIn!(SpecInst*, TypeAst)(spec.parents, spec.ast.parents, cb);
		foreach (ref FunDecl fun; module_.funs)
			eachFunSpec(fun, cb);
	});
}

void referencesForStructDecl(in AllSymbols allSymbols, in Program program, in StructDecl* a, in ReferenceCb cb) {
	eachModuleThatMayReference(program, a.visibility, moduleOf(program, a.moduleUri), (in Module module_) {
		eachTypeInModule(module_, (in Type t, in TypeAst ast) {
			if (t.isA!(StructInst*) && decl(*t.as!(StructInst*)) == a)
				cb(UriAndRange(module_.uri, range(ast, allSymbols)));
		});
	});
}

Module* moduleOf(in Program program, Uri uri) =>
	mustGetAt(program.allModules, uri);

void referencesForModule(in AllUris allUris, in Program program, in Module* target, in ReferenceCb cb) {
	eachModuleReferencing(program, target, (in Module importer, in ImportOrExport ie) {
		if (has(ie.source))
			cb(UriAndRange(importer.uri, pathRange(allUris, *force(ie.source))));
	});
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
