module concretize.constantsOrExprs;

@safe @nogc pure nothrow:

import model.concreteModel : ConcreteExpr;
import model.constant : Constant;
import util.alloc.alloc : Alloc;
import util.col.arr : SmallArray;
import util.col.arrUtil : every, map;
import util.union_ : Union;

immutable struct ConstantsOrExprs {
	mixin Union!(SmallArray!Constant, SmallArray!ConcreteExpr);
}
static assert(ConstantsOrExprs.sizeof == ulong.sizeof);

ConstantsOrExprs asConstantsOrExprs(ref Alloc alloc, ConcreteExpr[] exprs) =>
	every!ConcreteExpr(exprs, (in ConcreteExpr arg) => arg.kind.isA!Constant)
		? ConstantsOrExprs(map(alloc, exprs, (ref ConcreteExpr arg) => arg.kind.as!Constant))
		: ConstantsOrExprs(exprs);
