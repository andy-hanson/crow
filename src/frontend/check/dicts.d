module frontend.check.dicts;

@safe @nogc pure nothrow:

import model.model : FunDecl, SpecDecl, StructOrAlias;
import util.col.dict : Dict;
import util.col.multiDict : MultiDict;
import util.sym : Sym;

alias StructsAndAliasesDict = Dict!(Sym, StructOrAliasAndIndex);
alias SpecsDict = Dict!(Sym, SpecDeclAndIndex);
alias FunsDict = MultiDict!(Sym, FunDeclAndIndex);

immutable struct StructOrAliasAndIndex {
	StructOrAlias structOrAlias;
	ModuleLocalStructOrAliasIndex index;
}

// An index into the structs arr or alias arr (depends on context)
immutable struct ModuleLocalStructOrAliasIndex {
	@safe @nogc pure nothrow:

	size_t index;

	ModuleLocalAliasIndex asAlias() =>
		ModuleLocalAliasIndex(index);

	ModuleLocalStructIndex asStruct() =>
		ModuleLocalStructIndex(index);
}

immutable struct ModuleLocalAliasIndex { size_t index; }
immutable struct ModuleLocalStructIndex { size_t index; }

immutable struct SpecDeclAndIndex {
	SpecDecl* decl;
	ModuleLocalSpecIndex index;
}

immutable struct ModuleLocalSpecIndex {
	size_t index;
}

immutable struct FunDeclAndIndex {
	ModuleLocalFunIndex index;
	FunDecl* decl;
}

// Index of a function in this module.
immutable struct ModuleLocalFunIndex {
	size_t index;
}
