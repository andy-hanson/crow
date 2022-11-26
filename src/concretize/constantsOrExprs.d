module concretize.constantsOrExprs;

@safe @nogc pure nothrow:

import model.concreteModel : ConcreteExpr;
import model.constant : Constant;
import util.alloc.alloc : Alloc;
import util.col.arr : SmallArray;
import util.col.arrUtil : every, map;
import util.union_ : Union;

struct ConstantsOrExprs {
	mixin Union!(immutable SmallArray!Constant, immutable SmallArray!ConcreteExpr);
}
static assert(ConstantsOrExprs.sizeof == ulong.sizeof);

immutable(ConstantsOrExprs) asConstantsOrExprs(ref Alloc alloc, immutable ConcreteExpr[] exprs) =>
	every!ConcreteExpr(exprs, (ref immutable ConcreteExpr arg) => arg.kind.isA!Constant)
		? immutable ConstantsOrExprs(map(alloc, exprs, (ref immutable ConcreteExpr arg) =>
			arg.kind.as!Constant))
		: immutable ConstantsOrExprs(exprs);
