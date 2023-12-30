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
import model.ast :
	AssignmentAst,
	AssignmentCallAst,
	CallAst,
	DestructureAst,
	ExprAstKind,
	FunDeclAst,
	ImportOrExportAst,
	NameAndRange,
	ParamsAst,
	paramsArray,
	pathRange,
	range,
	rangeOfNameAndRange,
	StructDeclAst,
	TypeAst;
import model.model :
	AssertOrForbidExpr,
	BogusExpr,
	Called,
	CalledSpecSig,
	CallExpr,
	ClosureGetExpr,
	ClosureSetExpr,
	Destructure,
	eachImportOrReExport,
	EnumMember,
	Expr,
	ExprKind,
	FunBody,
	FunDecl,
	FunDeclSource,
	FunInst,
	FunPtrExpr,
	greatestVisibility,
	IfExpr,
	IfOptionExpr,
	ImportOrExport,
	LambdaExpr,
	LetExpr,
	Local,
	LocalSetExpr,
	LoopBreakExpr,
	LoopContinueExpr,
	LoopExpr,
	LoopUntilExpr,
	LoopWhileExpr,
	MatchEnumExpr,
	MatchUnionExpr,
	Module,
	NameReferents,
	Params,
	paramsArray,
	Program,
	PtrToFieldExpr,
	PtrToLocalExpr,
	RecordField,
	SeqExpr,
	SpecDecl,
	SpecDeclBody,
	SpecDeclSig,
	SpecInst,
	StructAlias,
	StructBody,
	StructDecl,
	StructDeclSource,
	StructInst,
	Test,
	ThrowExpr,
	Type,
	UnionMember,
	VarDecl,
	Visibility;
import util.alloc.alloc : Alloc;
import util.col.array : allSame, contains, find, fold, isEmpty, only, zip, zipIn;
import util.col.arrayBuilder : buildArray;
import util.col.hashTable : mustGet;
import util.col.mutMaxArr : asTemporaryArray, mutMaxArr, MutMaxArr, push;
import util.opt : force, has, none, Opt, optEqual, some;
import util.sourceRange : Range, UriAndRange;
import util.symbol : AllSymbols, prependSet, Symbol;
import util.uri : AllUris, Uri;
import util.util : ptrTrustMe;

UriAndRange[] getReferencesForPosition(
	ref Alloc alloc,
	scope ref AllSymbols allSymbols,
	in AllUris allUris,
	in Program program,
	in Position pos,
) {
	Opt!Target target = targetForPosition(pos.kind);
	return has(target)
		? buildArray!UriAndRange(alloc, (in ReferenceCb cb) {
			eachReferenceForTarget(allSymbols, allUris, program, pos.module_.uri, force(target), cb);
		})
		: [];
}

void eachReferenceForTarget(
	scope ref AllSymbols allSymbols,
	in AllUris allUris,
	in Program program,
	Uri curUri,
	in Target target,
	in ReferenceCb cb,
) {
	definitionForTarget(allSymbols, curUri, target, cb);
	referencesForTarget(allSymbols, allUris, program, curUri, target, cb);
}

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
		(EnumMember* x) {
			referencesForEnumMember(program, x, cb);
		},
		(FunDecl* x) {
			referencesForFunDecls(allSymbols, program, [x], cb);
		},
		(PositionKind.ImportedName x) {
			referencesForImportedName(allSymbols, program, x, cb);
		},
		(PositionKind.LocalPosition x) {
			referencesForLocal(allSymbols, curUri, x, cb);
		},
		(LoopExpr* x) {
			referencesForLoop(curUri, *x, cb);
		},
		(Module* x) {
			referencesForModule(allUris, program, x, cb);
		},
		(RecordField* x) {
			referencesForRecordField(allSymbols, program, *x, cb);
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

void referencesForStructAlias(in StructAlias* a, in ReferenceCb cb) {
	// TODO
}

void referencesForImportedName(
	in AllSymbols allSymbols,
	in Program program,
	in PositionKind.ImportedName a,
	in ReferenceCb cb,
) {
	eachImportForName(allSymbols, program, a.exportingModule, a.name, cb);
	if (has(a.referents)) {
		NameReferents nr = *force(a.referents);
		if (has(nr.structOrAlias))
			force(nr.structOrAlias).matchWithPointers!void(
				(StructAlias* x) {
					referencesForStructAlias(x, cb);
				},
				(StructDecl* x) {
					referencesForStructDecl(allSymbols, program, x, cb);
				});
		if (has(nr.spec))
			referencesForSpecDecl(allSymbols, program, force(nr.spec), cb);
		referencesForFunDecls(allSymbols, program, nr.funs, cb);
	}
}

void eachImportForName(
	in AllSymbols allSymbols,
	in Program program,
	in Module* exportingModule,
	Symbol name,
	in ReferenceCb cb,
) {
	eachModuleReferencing(program, exportingModule, (in Module importingModule, in ImportOrExport x) {
		eachImportForName(allSymbols, importingModule, x, name, cb);
	});
}
void eachImportForName(
	in AllSymbols allSymbols,
	in Module importingModule,
	in ImportOrExport a,
	Symbol name,
	in ReferenceCb cb,
) {
	if (has(a.source)) {
		ImportOrExportAst* source = force(a.source);
		if (source.kind.isA!(NameAndRange[])) {
			foreach (NameAndRange x; source.kind.as!(NameAndRange[]))
				if (x.name == name)
					cb(UriAndRange(importingModule.uri, rangeOfNameAndRange(x, allSymbols)));
		}
	}
}

void referencesForLocal(in AllSymbols allSymbols, Uri curUri, in PositionKind.LocalPosition a, in ReferenceCb cb) {
	a.container.match!void(
		(ref FunDecl fun) {
			Expr body_ = fun.body_.isA!(FunBody.ExpressionBody)
				? fun.body_.as!(FunBody.ExpressionBody).expr
				: Expr(null, ExprKind(BogusExpr()));
			eachDescendentExprIncluding(body_, (in Expr x) @safe {
				Opt!Target xTarget = exprTarget(PositionKind.Expression(&fun, ptrTrustMe(x)));
				if (optEqual!Target(xTarget, some(Target(a))))
					cb(UriAndRange(fun.moduleUri, x.range));
			});
		},
		(ref SpecDecl) {});
}

void referencesForLoop(Uri curUri, in LoopExpr loop, in ReferenceCb cb) {
	eachDescendentExprExcluding(ExprKind(&loop), (in Expr child) {
		if (child.kind.isA!(LoopBreakExpr*) || child.kind.isA!LoopContinueExpr)
			cb(UriAndRange(curUri, child.range));
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
			eachTypeInStruct(x, typeCb),
		(in Test _) =>
			assert(false),
		(in VarDecl _) =>
			assert(false));
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
		if (has(x.body_))
			eachTypeInExpr(force(x.body_), cb);
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
		eachTypeArg(parent.typeArgs, ast, cb);
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

void eachTypeInStruct(in StructDecl a, in TypeCb cb) =>
	a.source.matchIn!void(
		(in StructDeclAst x) {
			eachTypeInStructBody(a.body_, x.body_, cb);
		},
		(in StructDeclSource.Bogus) {});
void eachTypeInStructBody(in StructBody body_, in StructDeclAst.Body ast, in TypeCb cb) {
	body_.matchIn!void(
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
				ast.as!(StructDeclAst.Body.Record).fields,
				(ref RecordField field, ref StructDeclAst.Body.Record.Field fieldAst) {
					eachTypeInType(field.type, fieldAst.type, cb);
				});
		},
		(in StructBody.Union x) {
			zip!(UnionMember, StructDeclAst.Body.Union.Member)(
				x.members,
				ast.as!(StructDeclAst.Body.Union).members,
				(ref UnionMember member, ref StructDeclAst.Body.Union.Member memberAst) {
					if (has(memberAst.type))
						eachTypeInType(member.type, force(memberAst.type), cb);
				});
		});
}

void eachTypeInType(in Type a, in TypeAst ast, in TypeCb cb) {
	cb(a, ast);
	Opt!bool res = eachTypeComponent!bool(a, ast, (in Type x, in TypeAst y) {
		eachTypeInType(x, y, cb);
		return none!bool;
	});
	assert(!has(res));
}

void eachTypeInParams(in Params a, in ParamsAst asts, in TypeCb cb) {
	zip!(Destructure, DestructureAst)(paramsArray(a), paramsArray(asts), (ref Destructure x, ref DestructureAst _) {
		eachTypeInDestructure(x, cb);
	});
}

void eachTypeInDestructure(in Destructure a, in TypeCb cb) {
	Opt!bool res = eachDestructureComponent!bool(a, (Local* x) {
		DestructureAst.Single* ast = x.source.as!(DestructureAst.Single*);
		if (has(ast.type))
			cb(x.type, *force(ast.type));
		return none!bool;
	});
	assert(!has(res));
}

void eachTypeInExpr(in Expr expr, in TypeCb cb) {
	eachDescendentExprIncluding(expr, (in Expr x) {
		eachTypeDirectlyInExpr(x, cb);
	});
}

void eachTypeDirectlyInExpr(in Expr a, in TypeCb cb) {
	a.kind.matchIn!void(
		(in AssertOrForbidExpr x) {},
		(in BogusExpr) {},
		(in CallExpr x) {
			//TODO: types in explicit type args
		},
		(in ClosureGetExpr _) {},
		(in ClosureSetExpr x) {},
		(in FunPtrExpr _) {
			//TODO: types in explicit type args
		},
		(in IfExpr x) {},
		(in IfOptionExpr x) {},
		(in LambdaExpr x) {
			eachTypeInDestructure(x.param, cb);
		},
		(in LetExpr x) {
			eachTypeInDestructure(x.destructure, cb);
		},
		(in LiteralExpr) {},
		(in LiteralCStringExpr) {},
		(in LiteralSymbolExpr) {},
		(in LocalGetExpr) {},
		(in LocalSetExpr x) {},
		(in LoopExpr x) {},
		(in LoopBreakExpr x) {},
		(in LoopContinueExpr) {},
		(in LoopUntilExpr x) {},
		(in LoopWhileExpr x) {},
		(in MatchEnumExpr x) {},
		(in MatchUnionExpr x) {
			foreach (ref MatchUnionExpr.Case case_; x.cases) {
				eachTypeInDestructure(case_.destructure, cb);
			}
		},
		(in PtrToFieldExpr x) {},
		(in PtrToLocalExpr _) {},
		(in SeqExpr x) {},
		(in ThrowExpr x) {});
}

void referencesForFunDecls(in AllSymbols allSymbols, in Program program, in FunDecl*[] decls, in ReferenceCb cb) {
	if (!isEmpty(decls)) {
		Visibility maxVisibility = fold(Visibility.private_, decls, (Visibility a, in FunDecl* b) =>
			greatestVisibility(a, b.visibility));
		assert(allSame!(Uri, FunDecl*)(decls, (in FunDecl* x) => x.moduleUri));
		Module* itsModule = moduleOf(program, decls[0].moduleUri);
		eachExprThatMayReference(program, maxVisibility, itsModule, (in Module module_, in Expr x) {
			if (x.kind.isA!CallExpr) {
				Called called = x.kind.as!CallExpr.called;
				if (called.isA!(FunInst*) && contains(decls, called.as!(FunInst*).decl))
					cb(UriAndRange(module_.uri, callNameRange(allSymbols, x)));
			} else if (x.kind.isA!FunPtrExpr) {
				if (contains(decls, x.kind.as!FunPtrExpr.funInst.decl))
					cb(UriAndRange(module_.uri, callNameRange(allSymbols, x)));
			}
		});
	}
}

Range callNameRange(in AllSymbols allSymbols, in Expr a) {
	ExprAstKind kind = a.ast.kind;
	return kind.isA!(AssignmentAst*)
		? kind.as!(AssignmentAst*).left.range
		: kind.isA!(AssignmentCallAst*)
		? rangeOfNameAndRange(kind.as!(AssignmentCallAst*).funName, allSymbols)
		: kind.isA!CallAst
		? rangeOfNameAndRange(kind.as!CallAst.funName, allSymbols)
		: a.ast.range;
}

void eachExprThatMayReference(
	in Program program,
	Visibility visibility,
	Module* module_,
	in void delegate(in Module, in Expr) @safe @nogc pure nothrow cb,
) {
	eachModuleThatMayReference(program, visibility, module_, (in Module module_) {
		foreach (ref FunDecl fun; module_.funs) {
			if (fun.body_.isA!(FunBody.ExpressionBody))
				eachDescendentExprIncluding(fun.body_.as!(FunBody.ExpressionBody).expr, (in Expr x) {
					cb(module_, x);
				});
		}
		foreach (ref Test test; module_.tests)
			if (has(test.body_)) {
				eachDescendentExprIncluding(force(test.body_), (in Expr x) {
					cb(module_, x);
				});
			}
	});
}

void referencesForSpecSig(in AllSymbols allSymbols, in Program program, in PositionKind.SpecSig a, in ReferenceCb cb) {
	Module* itsModule = moduleOf(program, a.spec.moduleUri);
	eachExprThatMayReference(program, a.spec.visibility, itsModule, (in Module module_, in Expr x) {
		if (x.kind.isA!CallExpr) {
			Called called = x.kind.as!CallExpr.called;
			if (called.isA!(CalledSpecSig) && called.as!(CalledSpecSig).nonInstantiatedSig == a.sig)
				cb(UriAndRange(module_.uri, x.range));
		} else if (x.kind.isA!FunPtrExpr) {
			// Currently doesn't support specs
			assert(x.kind.as!FunPtrExpr.funInst != null);
		}
	});
}

void referencesForRecordField(in AllSymbols allSymbols, in Program program, in RecordField field, in ReferenceCb cb) {
	withRecordFieldFunctions(program, field, (in FunDecl*[] funs) {
		referencesForFunDecls(allSymbols, program, funs, cb);
	});
}

void referencesForEnumMember(in Program program, in EnumMember* x, in ReferenceCb cb) {
	// TODO: Find the corresponding creation function
}

void referencesForVarDecl(scope ref AllSymbols allSymbols, in Program program, in VarDecl* a, in ReferenceCb cb) {
	// Find references to get/set
	Module* module_ = moduleOf(program, a.moduleUri);
	Opt!(FunDecl*) getter = find(funsNamed(module_, a.name), (in FunDecl* x) =>
		x.body_.isA!(FunBody.VarGet) && x.body_.as!(FunBody.VarGet).var == a);
	Opt!(FunDecl*) setter = find(funsNamed(module_, prependSet(allSymbols, a.name)), (in FunDecl* x) =>
		x.body_.isA!(FunBody.VarSet) && x.body_.as!(FunBody.VarSet).var == a);
	referencesForFunDecls(allSymbols, program, [force(getter), force(setter)], cb);
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
			if (paramType.isA!(StructInst*) && paramType.as!(StructInst*).decl == field.containingRecord)
				push(res, fun);
		}
	}
	cb(asTemporaryArray(res));
}

immutable(FunDecl*)[] funsNamed(in Module* module_, Symbol name) =>
	mustGet(module_.allExportedNames, name).funs;

bool isRecordFieldFunction(in FunBody a) =>
	a.isA!(FunBody.RecordFieldGet) || a.isA!(FunBody.RecordFieldPointer) || a.isA!(FunBody.RecordFieldSet);

void referencesForSpecDecl(in AllSymbols allSymbols, in Program program, in SpecDecl* a, in ReferenceCb refCb) {
	eachModuleThatMayReference(program, a.visibility, moduleOf(program, a.moduleUri), (in Module module_) {
		scope void delegate(in SpecInst*, in TypeAst) @safe @nogc pure nothrow cb = (spec, ast) {
			if (spec.decl == a)
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
			if (t.isA!(StructInst*) && t.as!(StructInst*).decl == a)
				cb(UriAndRange(module_.uri, range(ast, allSymbols)));
		});
	});
}

Module* moduleOf(in Program program, Uri uri) =>
	mustGet(program.allModules, uri);

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
	in Module* exportingModule,
	in void delegate(in Module, in ImportOrExport) @safe @nogc pure nothrow cb,
) {
	foreach (immutable Module* importingModule; program.allModules)
		eachImportOrReExport(*importingModule, (in ImportOrExport x) @safe {
			if (x.modulePtr == exportingModule)
				cb(*importingModule, x);
		});
}
