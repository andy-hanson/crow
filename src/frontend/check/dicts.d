module frontend.check.dicts;

@safe @nogc pure nothrow:

import model.model : FunDecl, SpecDecl, StructOrAlias;
import util.col.dict : Dict;
import util.col.multiDict : MultiDict;
import util.sym : Sym;

alias StructsAndAliasesDict = Dict!(Sym, StructOrAlias);
alias SpecsDict = Dict!(Sym, SpecDecl*);
alias FunsDict = MultiDict!(Sym, immutable FunDecl*);
