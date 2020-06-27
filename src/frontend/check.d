module frontend.check;

@safe @nogc pure nothrow:

import model : CommonTypes, Module;

import frontend.ast : FileAst;
import frontend.programState : ProgramState;

import diag : Diags;

import util.collection.arr : Arr;
import util.path : PathAndStorageKind;
import util.ptr : Ptr;
import util.result : Result;

struct PathAndAst {
	immutable PathAndStorageKind pathAndStorageKind;
	immutable FileAst ast;
}

struct BootstrapCheck {
	immutable Ptr!Module module_;
	immutable CommonTypes commonTypes;
}

immutable(Result!(BootstrapCheck, Diags)) checkBootstrapNz(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable PathAndAst pathAndAst,
) {
	assert(0); //TODO
}

immutable(Result!(Ptr!Module, Diags)) check(Alloc)(
	ref Alloc alloc,
	ref ProgramState programState,
	ref immutable Arr!(Ptr!Module) imports,
	ref immutable Arr!(Ptr!Module) exports,
	immutable PathAndAst pathAndAst,
	immutable CommonTypes commonTypes,
) {
	assert(0); //TODO
}
