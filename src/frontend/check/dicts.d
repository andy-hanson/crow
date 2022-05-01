module frontend.check.dicts;

@safe @nogc pure nothrow:

import model.model : FunDecl, SpecDecl, StructOrAlias;
import util.col.dict : Dict;
import util.col.multiDict : MultiDict;
import util.sym : Sym;

alias StructsAndAliasesDict = Dict!(Sym, StructOrAliasAndIndex);
alias SpecsDict = Dict!(Sym, SpecDeclAndIndex);
alias FunsDict = MultiDict!(Sym, FunDeclAndIndex);

struct StructOrAliasAndIndex {
	immutable StructOrAlias structOrAlias;
	immutable ModuleLocalStructOrAliasIndex index;
}

// An index into the structs arr or alias arr (depends on context)
struct ModuleLocalStructOrAliasIndex {
	@safe @nogc pure nothrow:

	immutable size_t index;

	immutable(ModuleLocalAliasIndex) asAlias() immutable {
		return immutable ModuleLocalAliasIndex(index);
	}

	immutable(ModuleLocalStructIndex) asStruct() immutable {
		return immutable ModuleLocalStructIndex(index);
	}
}

struct ModuleLocalAliasIndex { immutable size_t index; }
struct ModuleLocalStructIndex { immutable size_t index; }

struct SpecDeclAndIndex {
	immutable SpecDecl* decl;
	immutable ModuleLocalSpecIndex index;
}

struct ModuleLocalSpecIndex {
	immutable size_t index;
}

struct FunDeclAndIndex {
	immutable ModuleLocalFunIndex index;
	immutable FunDecl* decl;
}

// Index of a function in this module.
struct ModuleLocalFunIndex {
	immutable size_t index;
}
