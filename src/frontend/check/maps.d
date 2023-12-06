module frontend.check.maps;

@safe @nogc pure nothrow:

import model.model : FunDecl, SpecDecl, StructOrAlias, structOrAliasName;
import util.col.arrUtil : allSame;
import util.col.hashTable : HashTable;
import util.sym : Sym;

alias StructsAndAliasesMap = immutable HashTable!(StructOrAlias, Sym, structOrAliasName);
alias SpecsMap = immutable HashTable!(immutable SpecDecl*, Sym, specDeclName);
alias FunsMap = immutable HashTable!(immutable FunDecl*[], Sym, funDeclsName);

Sym funDeclsName(immutable FunDecl*[] a) {
	assert(allSame!(Sym, immutable FunDecl*)(a, (in immutable FunDecl* x) =>
		x.name));
	return a[0].name;
}

Sym specDeclName(immutable SpecDecl* a) =>
	a.name;
