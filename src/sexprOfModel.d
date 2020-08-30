module sexprOfModel;

@safe @nogc pure nothrow:

import model : FunDecl, Module, SpecDecl, StructDecl, StructInst;
import util.collection.arrUtil : arrLiteral, findIndex, map;
import util.collection.mutDict : getOrAdd, MutDict;
import util.path : baseName, PathAndStorageKind, pathToStrNoRoot, storageKindSym;
import util.ptr : comparePtr, Ptr, ptrTrustMe;
import util.sexpr : NameAndSexpr, Sexpr, SexprNamedRecord, SexprRecord;
import util.sym : shortSymAlphaLiteral, Sym;
import util.util : todo;
import util.writer : Writer;

immutable(Sexpr) sexprOfModule(Alloc)(ref Alloc alloc, ref immutable Module a) {
	Ctx ctx = Ctx(ptrTrustMe(a));
	return immutable Sexpr(immutable SexprNamedRecord(
		shortSymAlphaLiteral("module"),
		arrLiteral!NameAndSexpr(
			alloc,
			immutable NameAndSexpr(
				shortSymAlphaLiteral("path"),
				sexprOfPathAndStorageKind(alloc, a.pathAndStorageKind)),
			immutable NameAndSexpr(
				shortSymAlphaLiteral("imports"),
				immutable Sexpr(map(alloc, a.imports, (ref immutable Ptr!Module p) =>
					sexprOfModulePtr(alloc, ctx, p)))),
			immutable NameAndSexpr(
				shortSymAlphaLiteral("exports"),
				immutable Sexpr(map(alloc, a.exports, (ref immutable Ptr!Module p) =>
					sexprOfModulePtr(alloc, ctx, p)))),
			immutable NameAndSexpr(
				shortSymAlphaLiteral("structs"),
				immutable Sexpr(map(alloc, a.structs, (ref immutable StructDecl s) =>
					sexprOfStructDecl(alloc, ctx, s)))),
			immutable NameAndSexpr(
				shortSymAlphaLiteral("specs"),
				immutable Sexpr(map(alloc, a.specs, (ref immutable SpecDecl s) =>
					sexprOfSpecDecl(alloc, ctx, s)))),
			immutable NameAndSexpr(
				shortSymAlphaLiteral("funs"),
				immutable Sexpr(map(alloc, a.funs, (ref immutable FunDecl f) =>
					sexprOfFunDecl(alloc, ctx, f)))))));
}

private:

struct Ctx {
	immutable Ptr!Module curModule;
	MutDict!(immutable Ptr!Module, immutable Sym, comparePtr!Module) sexprOfModulePtr;
}

immutable(Sexpr) sexprOfPathAndStorageKind(Alloc)(ref Alloc alloc, ref immutable PathAndStorageKind a) {
	return immutable Sexpr(immutable SexprRecord(
		shortSymAlphaLiteral("path-sk"),
		arrLiteral!Sexpr(
			alloc,
			immutable Sexpr(pathToStrNoRoot(alloc, a.path)),
			immutable Sexpr(storageKindSym(a.storageKind)))));
}

immutable(Sexpr) sexprOfModulePtr(Alloc)(ref Alloc alloc, ref Ctx ctx, immutable Ptr!Module a) {
	return immutable Sexpr(getOrAdd(
		alloc,
		ctx.sexprOfModulePtr,
		a,
		() => baseName(a.pathAndStorageKind.path)));
}

immutable(Sexpr) sexprOfStructDecl(Alloc)(ref Alloc alloc, ref Ctx ctx, ref immutable StructDecl a) {
	return todo!(immutable Sexpr)("sexprOfStructDecl");
}

immutable(Sexpr) sexprOfSpecDecl(Alloc)(ref Alloc alloc, ref Ctx ctx, ref immutable SpecDecl a) {
	return todo!(immutable Sexpr)("sexprOfSpecDecl");
}

immutable(Sexpr) sexprOfFunDecl(Alloc)(ref Alloc alloc, ref Ctx ctx, ref immutable FunDecl a) {
	return todo!(immutable Sexpr)("sexprOfFunDecl");
}

immutable(Sexpr) structInstToSexpr(Alloc)(ref Alloc alloc, immutable Ptr!StructInst si) {
	return Sexpr(SexprRecord(
		shortSymAlphaLIteral("struct-inst"),
		arrLiteral!Sexpr(
			alloc,
			Sexpr(si.decl.name),
			arrToSexpr(alloc, si.typeArgs, (ref immutable Type t) =>
				typeToSexpr(alloc, t))),
	));
}

immutable(Sexpr) typeToSexpr(Alloc)(ref Alloc alloc, ref immutable Type t) {
	return matchType!(immutable Sexpr)(
		t,
		(ref immutable Type.Bogus) =>
			immutable Sexpr(shortSymAlphaLiteral("bogus")),
		(immutable Ptr!TypeParam p) =>
			immutable Sexpr(immutable SexprRecord(
				shortSymAlphaLiteral("?"),
				arrLiteral!Sexpr(alloc, immutable Sexpr(p.name)))),
		(immutable Ptr!StructInst a) =>
			immutable Sexpr(immutable SexprRecord(
				a.declAndArgs.decl.name,
				map(alloc, a.declAndArgs.typeArgs, (ref immutable Type it) =>
					typeToSexpr(alloc, it)))));
}

immutable(Sexpr) exprToSexpr(Alloc)(ref Alloc alloc, ref immutable Expr expr) {
	return matchExpr(
		expr,
		(ref immutable Expr.Bogus) => Sexpr(strLiteral("bogus")),
		(ref immutable Expr.Call e) =>
			Sexpr(SexprRecord(
				shortSymAlphaLiteral("call"),
				arrLiteral!Sexpr(
					alloc,
					calledToSexpr(alloc, e.called),
					arrToSexpr(arena, e.args, (ref immutable Expr arg) => exprToSexpr(alloc, arg))
				),
			)),
		(ref immutable Expr.ClosureFieldRef) => todo!(immutable Sexpr)("closureFieldRef"),
		(ref immutable Expr.Cond) => todo!(immutable Sexpr)("cond"),
		(ref immutable Expr.CreateArr) => todo!(immutable Sexpr)("createArr"),
		(ref immutable Expr.CreateRecord e) =>
			Sexpr(SexprRecord(
				shortSymAlphaLiteral("record"),
				arrLiteral!Sexpr(
					alloc,
					structInstToSexpr(alloc, e.structInst),
					arrToSexpr(alloc, e.args, (ref immutable Expr arg) => exprToSexpr(alloc, arg))
				),
			)),
		(ref immutable Expr.FunAsLambda) => todo!(immutable Sexpr)("funaslambda"),
		(ref immutable Expr.ImplicitConvertToUnion) => todo!(immutable Sexpr)("implicitconverttounion"),
		(ref immutable Expr.Lambda) => todo!(immutable Sexpr)("lambda"),
		(ref immutable Expr.Let) => todo!(immutable Sexpr)("let"),
		(ref immutable Expr.LocalRef) => todo!(immutable Sexpr)("localref"),
		(ref immutable Expr.Match) => todo!(immutable Sexpr)("match"),
		(ref immutable Expr.ParamRef) => todo!(immutable Sexpr)("paramref"),
		(ref immutable Expr.RecordFieldAccess) => todo!(immutable Sexpr)("recordfieldaccess"),
		(ref immutable Expr.RecordFieldSet) => todo!(immutable Sexpr)("recordfieldset"),
		(ref immutable Expr.Seq) => todo!(immutable Sexpr)("seq"),
		(ref immutable Expr.StringLiteral) => todo!(immutable Sexpr)("stringliteral"));
}

void writeExpr(Alloc)(ref Writer!Alloc writer, ref immutable Expr expr) {
	StackAllocator tempAlloc;
	writer.writeSexpr(exprToSexpr(tempAlloc, expr));
}
