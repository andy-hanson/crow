module frontend.check.dicts;

@safe @nogc pure nothrow:

import model.model : FunDecl, SpecDecl, StructOrAlias;
import util.col.dict : SymDict;
import util.col.multiDict : SymMultiDict;
import util.ptr : Ptr;

alias StructsAndAliasesDict = SymDict!StructOrAliasAndIndex;
alias SpecsDict = SymDict!SpecDeclAndIndex;
alias FunsDict = SymMultiDict!FunDeclAndIndex;

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
