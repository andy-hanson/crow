module frontend.instantiate;

import model : StructDecl, StructInst;

import util.ptr : Ptr;

immutable(Ptr!StructInst) instantiateNonTemplateStruct(Alloc)(ref Alloc alloc, immutable Ptr!StructDecl decl) {
	assert(0); //TODO
}

