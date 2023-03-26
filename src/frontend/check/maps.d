module frontend.check.maps;

@safe @nogc pure nothrow:

import model.model : FunDecl, SpecDecl, StructOrAlias;
import util.col.map : Map;
import util.col.multiMap : MultiMap;
import util.sym : Sym;

alias StructsAndAliasesMap = Map!(Sym, StructOrAlias);
alias SpecsMap = Map!(Sym, SpecDecl*);
alias FunsMap = MultiMap!(Sym, immutable FunDecl*);
