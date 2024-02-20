module frontend.check.maps;

@safe @nogc pure nothrow:

import model.ast : ImportOrExportAst;
import model.model : FunDecl, SpecDecl, StructOrAlias, Test;
import util.col.array : allSame, SmallArray;
import util.col.hashTable : HashTable;
import util.symbol : Symbol;
import util.uri : Uri;

alias StructsAndAliasesMap = HashTable!(StructOrAlias, Symbol, structOrAliasName);
alias SpecsMap = HashTable!(immutable SpecDecl*, Symbol, specDeclName);
alias FunsMap = HashTable!(immutable FunDecl*[], Symbol, funDeclsName);

immutable struct FunsAndMap {
	SmallArray!FunDecl funs;
	SmallArray!Test tests;
	FunsMap funsMap;
}

immutable struct ImportOrExportFile {
	ImportOrExportAst* source;
	Uri uri;
}

Symbol structOrAliasName(in StructOrAlias a) =>
	a.name;

Symbol funDeclsName(in immutable FunDecl*[] a) {
	assert(allSame!(Symbol, immutable FunDecl*)(a, (in immutable FunDecl* x) =>
		x.name));
	return a[0].name;
}

Symbol specDeclName(in SpecDecl* a) =>
	a.name;
