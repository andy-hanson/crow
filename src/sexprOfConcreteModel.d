module sexprOfConcreteModel;

@safe @nogc pure nothrow:

import concreteModel :
	ConcreteFun,
	ConcreteProgram,
	ConcreteStruct;
import util.ptr : Ptr;
import util.sexpr : Sexpr, tataArr, tataRecord;
import util.util : todo;

immutable(Sexpr) tataOfConcreteProgram(Alloc)(ref Alloc alloc, ref immutable ConcreteProgram a) {
	Ctx ctx;
	return tataRecord(
		alloc,
		"program",
		tataArr(alloc, a.allStructs, (ref immutable Ptr!ConcreteStruct it) =>
			tataOfConcreteStruct(alloc, ctx, it)),
		tataArr(alloc, a.allFuns, (ref immutable Ptr!ConcreteFun it) =>
			tataOfConcreteFun(alloc, ctx, it)),
		tataOfConcreteFunPtr(alloc, ctx, a.rtMain),
		tataOfConcreteFunPtr(alloc, ctx, a.userMain),
		tataOfConcreteStructPtr(alloc, ctx, a.ctxType));
}

private:

struct Ctx {

}

immutable(Sexpr) tataOfConcreteStruct(Alloc)(ref Alloc alloc, ref Ctx ctx, ref immutable ConcreteStruct a) {
	return todo!(immutable Sexpr)("tataOfConcreteStruct");
}

immutable(Sexpr) tataOfConcreteFun(Alloc)(ref Alloc alloc, ref Ctx ctx, ref immutable ConcreteFun a) {
	return todo!(immutable Sexpr)("tataOfConcreteFun");
}

immutable(Sexpr) tataOfConcreteStructPtr(Alloc)(ref Alloc alloc, ref Ctx ctx, immutable Ptr!ConcreteStruct a) {
	return todo!(immutable Sexpr)("tataOfConcreteStructPtr");
}

immutable(Sexpr) tataOfConcreteFunPtr(Alloc)(ref Alloc alloc, ref Ctx ctx, immutable Ptr!ConcreteFun a) {
	return todo!(immutable Sexpr)("tataOfConcreteFunptr");
}
