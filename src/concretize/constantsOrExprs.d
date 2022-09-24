module concretize.constantsOrExprs;

@safe @nogc pure nothrow:

import model.concreteModel : asConstant, ConcreteExpr, isConstant;
import model.constant : Constant;
import util.alloc.alloc : Alloc;
import util.col.arrUtil : every, map;

struct ConstantsOrExprs {
	@safe @nogc pure nothrow:

	@trusted immutable this(immutable Constant[] a) {
		kind_ = Kind.constants;
		constants = a;
	}
	@trusted immutable this(immutable ConcreteExpr[] a) { kind_ = Kind.exprs; exprs = a; }

	private:
	enum Kind {
		constants,
		exprs,
	}
	immutable Kind kind_;
	union {
		immutable Constant[] constants;
		immutable ConcreteExpr[] exprs;
	}
}

@trusted T matchConstantsOrExprs(T)(
	ref immutable ConstantsOrExprs a,
	scope T delegate(ref immutable Constant[]) @safe @nogc pure nothrow cbConstants,
	scope T delegate(ref immutable ConcreteExpr[]) @safe @nogc pure nothrow cbExprs,
) {
	final switch (a.kind_) {
		case ConstantsOrExprs.Kind.constants:
			return cbConstants(a.constants);
		case ConstantsOrExprs.Kind.exprs:
			return cbExprs(a.exprs);
	}
}


immutable(ConstantsOrExprs) asConstantsOrExprs(ref Alloc alloc, immutable ConcreteExpr[] exprs) =>
	every!ConcreteExpr(exprs, (ref immutable ConcreteExpr arg) => isConstant(arg.kind))
		? immutable ConstantsOrExprs(map!Constant(alloc, exprs, (ref immutable ConcreteExpr arg) =>
			asConstant(arg.kind)))
		: immutable ConstantsOrExprs(exprs);
