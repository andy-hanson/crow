module frontend.check.dicts;

@safe @nogc pure nothrow:

import model.model : FunDecl, SpecDecl, StructOrAlias;
import util.collection.dict : Dict;
import util.collection.multiDict : MultiDict;
import util.ptr : Ptr;
import util.sym : compareSym, Sym;

alias StructsAndAliasesDict = Dict!(Sym, StructOrAlias, compareSym);
alias SpecsDict = Dict!(Sym, Ptr!SpecDecl, compareSym);
alias FunsDict = MultiDict!(Sym, FunDeclAndIndex, compareSym);

struct FunDeclAndIndex {
	immutable ModuleLocalFunIndex index;
	immutable Ptr!FunDecl decl;
}

// Index of a function in this module.
struct ModuleLocalFunIndex {
	immutable size_t index;
}
