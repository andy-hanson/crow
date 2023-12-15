module frontend.check.maps;

@safe @nogc pure nothrow:

import model.model : FunDecl, SpecDecl, StructOrAlias;
import util.col.arrUtil : allSame;
import util.col.hashTable : HashTable;
import util.sym : Sym;

alias StructsAndAliasesMap = HashTable!(StructOrAlias, Sym, structOrAliasName);
alias SpecsMap = HashTable!(immutable SpecDecl*, Sym, specDeclName);
alias FunsMap = HashTable!(immutable FunDecl*[], Sym, funDeclsName);

Sym structOrAliasName(in StructOrAlias a) =>
	a.name;

Sym funDeclsName(in immutable FunDecl*[] a) {
	assert(allSame!(Sym, immutable FunDecl*)(a, (in immutable FunDecl* x) =>
		x.name));
	return a[0].name;
}

Sym specDeclName(in SpecDecl* a) =>
	a.name;
