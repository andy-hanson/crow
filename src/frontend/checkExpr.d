module frontend.checkExpr;

@safe @nogc pure nothrow:

import frontend.ast : ExprAst;
import frontend.checkCtx : CheckCtx;
import model : CommonTypes, Expr, FunDecl, FunsMap, StructsAndAliasesMap;
import util.ptr : Ptr;
import util.util : todo;

immutable(Ptr!Expr) checkFunctionBody(Alloc)(
	ref Alloc alloc,
	ref CheckCtx checkCtx,
	ref immutable ExprAst ast,
	ref immutable StructsAndAliasesMap structsAndAliasesMap,
	ref immutable FunsMap funsMap,
	immutable Ptr!FunDecl fun,
	ref immutable CommonTypes commonTypes,
) {
	return todo!(Ptr!Expr)("checkFunctionBody");
}
