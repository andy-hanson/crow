module frontend.check.dicts;

@safe @nogc pure nothrow:

import model.model : FunDecl, SpecDecl, StructOrAlias;
import util.collection.dict : Dict;
import util.collection.multiDict : MultiDict;
import util.ptr : Ptr;
import util.sym : compareSym, Sym;

alias StructsAndAliasesDict = Dict!(Sym, StructOrAliasAndIndex, compareSym);
alias SpecsDict = Dict!(Sym, SpecDeclAndIndex, compareSym);
alias FunsDict = MultiDict!(Sym, FunDeclAndIndex, compareSym);

struct StructOrAliasAndIndex {
	immutable StructOrAlias structOrAlias;
	immutable ModuleLocalStructOrAliasIndex index;
}

// An index into the structs arr or alias arr (depends on context)
struct ModuleLocalStructOrAliasIndex {
	immutable size_t index;
}

struct SpecDeclAndIndex {
	immutable Ptr!SpecDecl decl;
	immutable ModuleLocalSpecIndex index;
}

struct ModuleLocalSpecIndex {
	immutable size_t index;
}

struct FunDeclAndIndex {
	immutable ModuleLocalFunIndex index;
	immutable Ptr!FunDecl decl;
}

// Index of a function in this module.
struct ModuleLocalFunIndex {
	immutable size_t index;
}
