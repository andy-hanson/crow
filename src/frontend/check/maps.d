module frontend.check.maps;

@safe @nogc pure nothrow:

import model.model : FunDecl, SpecDecl, StructOrAlias;
import util.col.array : allSame;
import util.col.hashTable : HashTable;
import util.symbol : Symbol;

alias StructsAndAliasesMap = HashTable!(StructOrAlias, Symbol, structOrAliasName);
alias SpecsMap = HashTable!(immutable SpecDecl*, Symbol, specDeclName);
alias FunsMap = HashTable!(immutable FunDecl*[], Symbol, funDeclsName);

Symbol structOrAliasName(in StructOrAlias a) =>
	a.name;

Symbol funDeclsName(in immutable FunDecl*[] a) {
	assert(allSame!(Symbol, immutable FunDecl*)(a, (in immutable FunDecl* x) =>
		x.name));
	return a[0].name;
}

Symbol specDeclName(in SpecDecl* a) =>
	a.name;
