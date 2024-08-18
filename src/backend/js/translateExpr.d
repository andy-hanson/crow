module backend.js.translateExpr;

@safe @nogc pure nothrow:

import backend.js.allUsed : allUsed, AnyDecl, bodyIsInlined, isAsyncCall, isAsyncFun, tryEvalConstantBool;
import backend.js.jsAst :
	genAnd,
	genArray,
	genArrowFunction,
	genAssign,
	genAwait,
	genBinary,
	genBitwiseNot,
	genBlockStatement,
	genBool,
	genBreak,
	genBreakNoLabel,
	genCall,
	genCallAwait,
	genCallPropertySync,
	genCallSync,
	genCallWithSpread,
	genConst,
	genEqEqEq,
	genGlobal,
	genIf,
	genIife,
	genIn,
	genInstanceMethod,
	genInstanceof,
	genIntegerSigned,
	genIntegerUnsigned,
	genLet,
	genTimes,
	genNew,
	genNot,
	genNotEqEq,
	genNull,
	genNumber,
	genOr,
	genPropertyAccess,
	genPropertyAccessComputed,
	genReturn,
	genString,
	genStringFromSymbol,
	genSwitch,
	genTernary,
	genThis,
	genThrow,
	genTryCatch,
	genTypeof,
	genUnary,
	genUndefined,
	genVarDecl,
	genWhile,
	genWhileTrue,
	JsArrowFunction,
	JsBinaryExpr,
	JsBlockStatement,
	JsClassMember,
	JsContinueStatement,
	JsDecl,
	JsDeclKind,
	JsDefaultDestructure,
	JsDestructure,
	JsExpr,
	JsExprOrBlockStatement,
	JsMemberName,
	JsName,
	JsObjectDestructure,
	JsParams,
	JsStatement,
	JsSwitchStatement,
	JsTryFinallyStatement,
	JsUnaryExpr,
	JsVarDecl,
	SyncOrAsync;
import backend.js.translateModuleCtx :
	localName,
	makeDecl,
	TranslateModuleCtx,
	translateFunReference,
	translateStructReference,
	translateTestReference,
	translateVarReference;
import frontend.storage : FileContentGetters;
import model.constant : asBool, asInt64, asNat64, Constant;
import model.model :
	arrayElementType,
	AssertOrForbidExpr,
	asTuple,
	AutoFun,
	BogusExpr,
	Builtin4ary,
	BuiltinBinary,
	BuiltinBinaryLazy,
	BuiltinBinaryMath,
	BuiltinFun,
	BuiltinTernary,
	BuiltinType,
	BuiltinUnary,
	BuiltinUnaryMath,
	Called,
	CalledSpecSig,
	CallExpr,
	CallOptionExpr,
	ClosureGetExpr,
	ClosureSetExpr,
	CommonTypes,
	Condition,
	defaultAssertOrForbidMessage,
	Destructure,
	eachLocal,
	eachSpecInFunIncludingParents,
	eachTest,
	EnumOrFlagsFunction,
	EnumOrFlagsMember,
	Expr,
	ExprAndType,
	ExternExpr,
	FinallyExpr,
	FunBody,
	FunDecl,
	FunDeclSource,
	FunInst,
	FunKind,
	FunPointerExpr,
	IfExpr,
	ImportFileContent,
	isSigned,
	isVoid,
	JsFun,
	LambdaExpr,
	LetExpr,
	LiteralExpr,
	LiteralStringLikeExpr,
	Local,
	LocalGetExpr,
	LocalPointerExpr,
	LocalSetExpr,
	LoopExpr,
	LoopBreakExpr,
	LoopContinueExpr,
	LoopWhileOrUntilExpr,
	MatchEnumExpr,
	MatchIntegralExpr,
	MatchStringLikeExpr,
	MatchUnionExpr,
	MatchVariantExpr,
	mustUnwrapOptionType,
	Params,
	paramsArray,
	paramTypeAt,
	RecordField,
	RecordFieldPointerExpr,
	SeqExpr,
	Signature,
	SpecInst,
	StructBody,
	StructDecl,
	StructInst,
	Test,
	ThrowExpr,
	TrustedExpr,
	TryExpr,
	TryLetExpr,
	Type,
	TypedExpr,
	TypeParamIndex,
	UnionMember,
	variantMethodCaller;
import util.alloc.alloc : Alloc;
import util.alloc.stackAlloc : withMapToStackArray;
import util.col.array :
	emptySmallArray,
	exists,
	foldRange,
	foldReverse,
	foldReverseWithIndex,
	isEmpty,
	makeArray,
	map,
	mapReduce,
	mapWithIndex,
	mapZip,
	newArray,
	newSmallArray,
	only,
	only2,
	SmallArray;
import util.col.arrayBuilder : add, ArrayBuilder, buildArray, Builder, buildSmallArray, finish, sizeSoFar;
import util.col.map : KeyValuePair;
import util.conv : safeToUshort;
import util.memory : allocate;
import util.opt : force, has, none, Opt, optIf, some;
import util.symbol : Symbol, symbol;
import util.unicode : mustUnicodeDecode;
import util.union_ : TaggedUnion, Union;
import util.uri : Uri;
import util.util : ptrTrustMe;
import versionInfo : isVersion, VersionFun;

private JsExpr genNewList(ref TranslateModuleCtx ctx, JsExpr[] elements) =>
	genCallSync(allocate(ctx.alloc, translateFunReference(ctx, ctx.program.commonFuns.newTList)), elements);
JsExpr genArrayToList(ref TranslateModuleCtx ctx, JsExpr array) =>
	genCallWithSpread(
		ctx.alloc, SyncOrAsync.sync, translateFunReference(ctx, ctx.program.commonFuns.newTList), [], array);
JsExpr genNewPair(ref TranslateModuleCtx ctx, JsExpr a, JsExpr b) =>
	genNew(ctx.alloc, translateStructReference(ctx, ctx.commonTypes.pair), [a, b]);

private void genAssertTypesForDestructure(
	scope ref ArrayBuilder!JsStatement out_,
	ref TranslateModuleCtx ctx,
	in Destructure destructure,
) {
	eachLocal(destructure, (Local* x) {
		genAssertType(out_, ctx, x.type, translateLocalGet(x));
	});
}
void genAssertType(scope ref ArrayBuilder!JsStatement out_, ref TranslateModuleCtx ctx, in Type type, JsExpr get) {
	type.matchIn!void(
		(in Type.Bogus) {},
		(in TypeParamIndex _) {},
		(in StructInst x) {
			Opt!JsExpr notOk = x.decl.body_.isA!BuiltinType
				? genIsNotBuiltinType(ctx, x.decl.body_.as!BuiltinType, get)
				: optIf(!x.decl.body_.isA!(StructBody.Extern), () =>
					genNot(ctx.alloc, genInstanceof(ctx.alloc, get, translateStructReference(ctx, x.decl))));
			if (has(notOk))
				add(ctx.alloc, out_, genIf(
					ctx.alloc,
					force(notOk),
					genThrowJsError(ctx.alloc, "Value did not have expected type")));
		});
}
private Opt!JsExpr genIsNotBuiltinType(ref TranslateModuleCtx ctx, BuiltinType type, JsExpr get) {
	Opt!JsExpr instanceof(Symbol expected) =>
		some(genNot(ctx.alloc, genInstanceof(ctx.alloc, get, genGlobal(expected))));
	Opt!JsExpr typeof_(string expected) =>
		some(genNotEqEq(ctx.alloc, genTypeof(ctx.alloc, get), genString(expected)));
	final switch (type) {
		case BuiltinType.array:
		case BuiltinType.mutArray:
			return instanceof(symbol!"Array");
		case BuiltinType.bool_:
			return typeof_("boolean");
		case BuiltinType.catchPoint:
		case BuiltinType.pointerConst:
		case BuiltinType.pointerMut:
			return some(genBool(true));
		case BuiltinType.char8:
		case BuiltinType.char32:
		case BuiltinType.int8:
		case BuiltinType.int16:
		case BuiltinType.int32:
		case BuiltinType.int64:
		case BuiltinType.nat8:
		case BuiltinType.nat16:
		case BuiltinType.nat32:
		case BuiltinType.nat64:
			return typeof_("bigint");
		case BuiltinType.float32:
		case BuiltinType.float64:
			return typeof_("number");
		case BuiltinType.funPointer:
			return typeof_("function");
		case BuiltinType.future:
			return instanceof(symbol!"Promise");
		case BuiltinType.jsAny:
			return none!JsExpr;
		case BuiltinType.lambda:
			return typeof_("function");
		case BuiltinType.string_:
		case BuiltinType.symbol:
			return typeof_("string");
		case BuiltinType.void_:
			return typeof_("undefined");
	}
}

JsDecl translateTest(ref TranslateModuleCtx ctx, Test* a) {
	TranslateExprCtx exprCtx = TranslateExprCtx(ptrTrustMe(ctx), a.moduleUri, none!(FunDecl*));
	return makeDecl(ctx, AnyDecl(a), JsDeclKind(genArrowFunction(
		SyncOrAsync.async,
		JsParams(),
		translateExprToExprOrBlockStatement(exprCtx, a.body_, Type(ctx.commonTypes.void_)))));
}
JsDecl translateFunDecl(ref TranslateModuleCtx ctx, FunDecl* a) {
	TranslateExprCtx exprCtx = TranslateExprCtx(ptrTrustMe(ctx), a.moduleUri, some(a));
	JsParams params = translateFunParams(exprCtx, *a);
	JsExpr fun = genArrowFunction(isAsyncFun(ctx.allUsed, a), params, translateFunBody(exprCtx, a));
	return makeDecl(ctx, AnyDecl(a), JsDeclKind(fun));
}

JsClassMember variantMethodImpl(
	ref TranslateModuleCtx ctx,
	in FunDeclSource.VariantMethod variantMethod,
	in Opt!Called optImpl,
) {
	Symbol name = variantMethod.method.name;
	FunDecl* caller = variantMethodCaller(ctx.program, variantMethod);
	SyncOrAsync async = has(optImpl) ? isAsyncCall(ctx.allUsed, caller, force(optImpl)) : SyncOrAsync.sync;
	if (has(optImpl) && isInlined(force(optImpl))) {
		Called impl = force(optImpl);
		FunDecl* decl = impl.as!(FunInst*).decl;
		TranslateExprCtx exprCtx = TranslateExprCtx(ptrTrustMe(ctx), caller.moduleUri, none!(FunDecl*));
		return genInstanceMethod(
			async,
			JsMemberName.variantMethod(name),
			translateFunParams(exprCtx, *decl, omitFirst: true),
			translateToBlockStatement(ctx.alloc, (scope ExprPos pos) =>
				translateInlineCall(
					exprCtx, impl.returnType, pos, decl, impl.paramTypes, impl.arity.as!uint, (size_t i) =>
						i == 0
							? genThis()
							: JsExpr(localName(*decl.params.as!(Destructure[])[i].as!(Local*))))));
	} else {
		// foo(...args) { return foo(anySpecs, this, ...args) }
		JsName args = JsName.specialLocal(symbol!"args");
		return genInstanceMethod(
			async,
			JsMemberName.variantMethod(name),
			JsParams(emptySmallArray!JsDestructure, some(JsDestructure(args))),
			genBlockStatement(ctx.alloc, [
				has(optImpl)
					? genReturn(ctx.alloc, makeCallNoInlineWithSpread(
						ctx,
						async,
						none!(FunDecl*),
						force(optImpl),
						(scope ref Builder!JsExpr out_) { out_ ~= genThis(); },
						JsExpr(args)))
					: genThrowBogus(ctx.alloc)]));
	}
}

private:

JsParams translateFunParams(ref TranslateExprCtx ctx, in FunDecl a, bool omitFirst = false) {
	SmallArray!JsDestructure params = buildSmallArray!JsDestructure(ctx.alloc, (scope ref Builder!JsDestructure out_) {
		translateSpecsToParams(out_, a);
		a.params.match!void(
			(Destructure[] xs) {
				foreach (ref Destructure x; xs[(omitFirst ? 1 : 0) .. $])
					out_ ~= translateDestructure(ctx, x);
			},
			(ref Params.Varargs x) {});
	});
	return JsParams(params, a.params.match!(Opt!JsDestructure)(
		(Destructure[]) => none!JsDestructure,
		(ref Params.Varargs x) =>
			some(translateDestructure(ctx, x.param))));
}
JsDestructure translateDestructure(ref TranslateExprCtx ctx, in Destructure a) =>
	a.matchIn!JsDestructure(
		(in Destructure.Ignore) =>
			JsDestructure(tempName(ctx, symbol!"ignore")),
		(in Local x) =>
			JsDestructure(localName(x)),
		(in Destructure.Split x) =>
			translateDestructureSplit(ctx, x));
JsDestructure translateDestructureSplit(ref TranslateExprCtx ctx, in Destructure.Split x) {
	if (x.isValidDestructure(ctx.commonTypes)) {
		SmallArray!RecordField fields = x.destructuredType.as!(StructInst*).decl.body_.as!(StructBody.Record).fields;
		return JsDestructure(JsObjectDestructure(
			mapZip!(immutable KeyValuePair!(JsMemberName, JsDestructure), RecordField, Destructure)(
				ctx.alloc, fields, x.parts, (ref RecordField field, ref Destructure part) =>
					immutable KeyValuePair!(JsMemberName, JsDestructure)(
						JsMemberName.recordField(field.name),
						translateDestructure(ctx, part)))));
	} else
		return JsDestructure(JsObjectDestructure(
			map(ctx.alloc, x.parts, (ref Destructure part) =>
				immutable KeyValuePair!(JsMemberName, JsDestructure)(
					JsMemberName.special(symbol!"bogus"),
					JsDestructure(allocate(ctx.alloc, JsDefaultDestructure(
						translateDestructure(ctx, part),
						genThrowBogusExpr(ctx.alloc))))))));
}
void translateSpecsToParams(scope ref Builder!JsDestructure out_, in FunDecl a) {
	eachSpecInFunIncludingParents(a, (SpecInst* spec) {
		foreach (ref Signature x; spec.decl.sigs)
			out_ ~= JsDestructure(JsName(JsName.Kind.specSig, x.name, some(safeToUshort(sizeSoFar(out_)))));
		return false;
	});
}

JsExprOrBlockStatement translateAutoFun(ref TranslateExprCtx ctx, FunDecl* fun, in AutoFun auto_) {
	Destructure[] params = fun.params.as!(Destructure[]);
	JsExpr param(size_t i) =>
		translateLocalGet(params[i].as!(Local*));
	StructDecl* struct_ = params[0].type.as!(StructInst*).decl;
	StructDecl* returnStruct = fun.returnType.as!(StructInst*).decl;
	final switch (auto_.kind) {
		case AutoFun.Kind.compare:
			assert(params.length == 2);
			return matchRecordOrUnion(
				struct_,
				(in RecordField[] fields) =>
					translateCompareRecord(ctx, auto_, returnStruct, fields, param(0), param(1)),
				(in UnionMember[] members) =>
					translateCompareUnion(ctx, auto_, returnStruct, members, param(0), param(1)));
		case AutoFun.Kind.equals:
			assert(params.length == 2);
			return matchRecordOrUnion(
				struct_,
				(in RecordField[] fields) =>
					translateEqualRecord(ctx, auto_, fields, param(0), param(1)),
				(in UnionMember[] members) =>
					translateEqualUnion(ctx, auto_, members, param(0), param(1)));
		case AutoFun.Kind.toJson:
			assert(params.length == 1);
			return matchRecordOrUnion(
				struct_,
				(in RecordField[] fields) =>
					translateRecordToJson(ctx, auto_, fields, param(0)),
				(in UnionMember[] members) =>
					translateUnionToJson(ctx, auto_, members, param(0)));
	}
}

JsExprOrBlockStatement matchRecordOrUnion(
	in StructDecl* struct_,
	in JsExprOrBlockStatement delegate(in RecordField[]) @safe @nogc pure nothrow cbRecord,
	in JsExprOrBlockStatement delegate(in UnionMember[]) @safe @nogc pure nothrow cbUnion,
) =>
	struct_.body_.isA!(StructBody.Record)
		? cbRecord(struct_.body_.as!(StructBody.Record).fields)
		: cbUnion(struct_.body_.as!(StructBody.Union*).members);

JsExprOrBlockStatement translateCompareRecord(
	ref TranslateExprCtx ctx,
	in AutoFun auto_,
	StructDecl* comparison,
	in RecordField[] fields,
	JsExpr p0,
	JsExpr p1,
) {
	JsExpr equal = genPropertyAccess(
		ctx.alloc,
		translateStructReference(ctx, comparison),
		JsMemberName.enumMember(symbol!"equal"));
	if (isEmpty(fields)) return JsExprOrBlockStatement(allocate(ctx.alloc, equal));
	/*
	const compareFoo = (p0, p1) => {
		const x = compareX(p0.x, p1.x)
		if (x !== Comparison.equal)
			return x
		const y = compareY(p0.y, p1.y)
		if (y !== Comparison.equal)
			return y
		return compareZ(p0.z, p1.z)
	}
	*/
	return JsExprOrBlockStatement(translateToBlockStatement(
		ctx.alloc,
		(scope ref ArrayBuilder!JsStatement out_, scope ExprPos pos) {
			foreach (size_t index, ref RecordField field; fields) {
				JsExpr compare = genCallCompareProperty(
					ctx, auto_.members[index], p0, p1, JsMemberName.recordField(field.name));
				if (index == fields.length - 1)
					add(ctx.alloc, out_, genReturn(ctx.alloc, compare));
				else {
					JsName name = tempName(ctx, field.name);
					add(ctx.alloc, out_, genConst(ctx.alloc, name, compare));
					add(ctx.alloc, out_, genIf(
						ctx.alloc,
						genNotEqEq(ctx.alloc, JsExpr(name), equal),
						genReturn(ctx.alloc, JsExpr(name))));
				}
			}
			return ExprResult.done;
		}));
}
JsExprOrBlockStatement translateCompareUnion(
	ref TranslateExprCtx ctx,
	in AutoFun auto_,
	StructDecl* comparison,
	in UnionMember[] members,
	JsExpr p0,
	JsExpr p1,
) =>
	/*
	if ("x" in a)
		return "x" in b
			? compare(a.x, b.x)
			: less
	else if ("y" in a)
		return "y" in b
			? compare(a.y, b.y)
			// This needs to have a case for each preceding kind
			: "x" in b ? greater : less
	else
		throw
	*/
	matchUnionMembers(ctx, members, p0, (size_t memberIndex, ref UnionMember member) {
		JsExpr comparisonRef = translateStructReference(ctx, comparison);
		JsExpr greater = genPropertyAccess(ctx.alloc, comparisonRef, JsMemberName.enumMember(symbol!"greater"));
		JsExpr less = genPropertyAccess(ctx.alloc, comparisonRef, JsMemberName.enumMember(symbol!"less"));
		JsExpr then = genCallCompareProperty(
			ctx, auto_.members[memberIndex], p0, p1, JsMemberName.unionMember(member.name));
		JsExpr else_ = memberIndex == 0
			? less
			: genTernary(
				ctx.alloc,
				combineWithOr!UnionMember(ctx.alloc, members[0 .. memberIndex], (ref UnionMember x) =>
					genIn(ctx.alloc, JsMemberName.unionMember(x.name), p1)),
				greater, less);
		return genReturn(
			ctx.alloc,
			genTernary(ctx.alloc, genIn(ctx.alloc, JsMemberName.unionMember(member.name), p1), then, else_));
	});
JsExpr combineWithOr(T)(ref Alloc alloc, in T[] xs, in JsExpr delegate(ref T) @safe @nogc pure nothrow cb) =>
	mapReduce!(JsExpr, T)(xs, cb, (JsExpr x, JsExpr y) => genOr(alloc, x, y));

JsExprOrBlockStatement translateEqualRecord(
	ref TranslateExprCtx ctx,
	in AutoFun auto_,
	in RecordField[] fields,
	JsExpr p0,
	JsExpr p1,
) =>
	JsExprOrBlockStatement(allocate(ctx.alloc, isEmpty(fields)
		? genBool(true)
		: foldRange!JsExpr(
			fields.length,
			(size_t i) =>
				genCallCompareProperty(ctx, auto_.members[i], p0, p1, JsMemberName.recordField(fields[i].name)),
			(JsExpr x, JsExpr y) => genAnd(ctx.alloc, x, y))));
JsExprOrBlockStatement translateEqualUnion(
	ref TranslateExprCtx ctx,
	in AutoFun auto_,
	in UnionMember[] members,
	JsExpr p0,
	JsExpr p1,
) =>
	matchUnionMembers(ctx, members, p0, (size_t memberIndex, ref UnionMember member) =>
		genReturn(ctx.alloc, genAnd(
			ctx.alloc,
			genIn(ctx.alloc, JsMemberName.unionMember(member.name), p1),
			genCallCompareProperty(ctx, auto_.members[memberIndex], p0, p1, JsMemberName.unionMember(member.name)))));
JsExpr genCallCompareProperty(ref TranslateExprCtx ctx, Called called, JsExpr p0, JsExpr p1, JsMemberName name) =>
	makeCall(ctx, called, [
		genPropertyAccess(ctx.alloc, p0, name),
		genPropertyAccess(ctx.alloc, p1, name)]);

JsExprOrBlockStatement matchUnionMembers(
	ref TranslateExprCtx ctx,
	in UnionMember[] members,
	JsExpr p0,
	in JsStatement delegate(size_t, ref UnionMember) @safe @nogc pure nothrow cbCase,
) =>
	JsExprOrBlockStatement(genBlockStatement(ctx.alloc, [
		foldReverseWithIndex!(JsStatement, UnionMember)(
			genThrowJsError(ctx.alloc, "Invalid union value"),
			members,
			(JsStatement else_, size_t index, ref UnionMember member) =>
				genIf(
					ctx.alloc,
					genIn(ctx.alloc, JsMemberName.unionMember(member.name), p0),
					cbCase(index, member), else_))]));

SyncOrAsync isCurFunAsync(in TranslateExprCtx ctx) =>
	has(ctx.curFun) ? isAsyncFun(ctx.ctx.allUsed, force(ctx.curFun)) : SyncOrAsync.async;
SyncOrAsync isAsyncCall(in TranslateExprCtx ctx, in Called called) =>
	isAsyncCall(ctx.ctx.allUsed, ctx.curFun, called);

JsExprOrBlockStatement translateRecordToJson(
	ref TranslateExprCtx ctx,
	in AutoFun auto_,
	in RecordField[] fields,
	JsExpr p0,
) =>
	JsExprOrBlockStatement(allocate(ctx.alloc, genNewJson(
		ctx.ctx,
		mapWithIndex!(JsExpr, RecordField)(ctx.alloc, fields, (size_t i, ref RecordField field) =>
			genNewPair(
				ctx.ctx,
				genStringFromSymbol(field.name),
				makeCall(ctx, auto_.members[i], [
					genPropertyAccess(ctx.alloc, p0, JsMemberName.recordField(field.name))]))))));
JsExprOrBlockStatement translateUnionToJson(
	ref TranslateExprCtx ctx,
	in AutoFun auto_,
	in UnionMember[] members,
	JsExpr p0,
) =>
	matchUnionMembers(ctx, members, p0, (size_t memberIndex, ref UnionMember member) =>
		// return new_json(new_pair("foo", toJson(a.foo)))
		genReturn(ctx.alloc,
			genNewJson(ctx.ctx, newArray(ctx.alloc, [
				genNewPair(
					ctx.ctx,
					genStringFromSymbol(member.name),
					makeCall(ctx, auto_.members[memberIndex], [
						genPropertyAccess(ctx.alloc, p0, JsMemberName.unionMember(member.name))]))]))));
JsExpr genNewJson(ref TranslateModuleCtx ctx, JsExpr[] pairs) =>
	genCallAwait(
		ctx.alloc,
		allocate(ctx.alloc, translateFunReference(ctx, ctx.program.commonFuns.newJsonFromPairs.decl)),
		pairs);
JsExpr genTuple(ref TranslateExprCtx ctx, size_t nArgs, in JsExpr delegate(size_t) @safe @nogc pure nothrow cbArg) {
	switch (nArgs) {
		case 0:
			return genNull();
		case 1:
			return cbArg(0);
		default:
			return genNew(
				ctx.alloc,
				translateStructReference(ctx, force(ctx.commonTypes.tuple(nArgs))),
				makeArray(ctx.alloc, nArgs, cbArg));
	}
}

JsExprOrBlockStatement translateFunBody(ref TranslateExprCtx ctx, FunDecl* fun) {
	if (fun.body_.isA!(FunBody.FileImport))
		return fun.body_.as!(FunBody.FileImport).content.matchIn!JsExprOrBlockStatement(
			(in immutable ubyte[] bytes) =>
				JsExprOrBlockStatement(allocate(ctx.alloc, genArray(map(ctx.alloc, bytes, (ref immutable ubyte x) =>
					genIntegerUnsigned(x))))),
			(in string s) =>
				JsExprOrBlockStatement(allocate(ctx.alloc, genString(s))),
			(in ImportFileContent.Bogus) =>
				JsExprOrBlockStatement(genBlockStatement(ctx.alloc, [genThrowBogus(ctx.alloc)])));
	else {
		if (fun.body_.isA!AutoFun)
			return translateAutoFun(ctx, fun, fun.body_.as!AutoFun);
		else if (fun.body_.isA!Expr)
			return JsExprOrBlockStatement(JsBlockStatement(
				translateToStatements(ctx.alloc, (scope ref ArrayBuilder!JsStatement out_, scope ExprPos pos) {
					foreach (ref Destructure param; paramsArray(fun.params))
						genAssertTypesForDestructure(out_, ctx.ctx, param);
					return translateExpr(ctx, fun.body_.as!Expr, fun.returnType, pos);
				})));
		else {
			Destructure[] params = fun.params.as!(Destructure[]);
			return translateToExprOrBlockStatement(ctx.alloc, (scope ExprPos pos) =>
				withMapToStackArray!(ExprResult, Type, Destructure)(
					params,
					(ref Destructure x) => x.type,
					(scope Type[] paramTypes) =>
						translateInlineCall(ctx, fun.returnType, pos, fun, paramTypes, params.length, (size_t i) =>
							translateLocalGet(params[i].as!(Local*)))));
		}
	}
}

struct TranslateExprCtx {
	@safe @nogc pure nothrow:
	TranslateModuleCtx* ctxPtr;
	Uri curUri;
	Opt!(FunDecl*) curFun;
	private uint nextTempIndex;

	ref inout(TranslateModuleCtx) ctx() return scope inout =>
		*ctxPtr;
	ref Alloc alloc() =>
		ctx.alloc;
	ref CommonTypes commonTypes() =>
		ctx.commonTypes;
	ref FileContentGetters fileContentGetters() =>
		*ctx.ctx.fileContentGetters;
}
JsExpr translateStructReference(in TranslateExprCtx ctx, in StructDecl* a) =>
	translateStructReference(ctx.ctx, a);

struct ExprPos {
	immutable struct Expression {}
	// Used for return from a function (since an arrow function can be an expression or a block)
	immutable struct ExpressionOrBlockStatement {}
	// If the expression is non-void, the statement should 'return'
	struct Statements { ArrayBuilder!JsStatement statements; }
	mixin TaggedUnion!(Expression, ExpressionOrBlockStatement, Statements*);
}
immutable struct ExprResult {
	@safe @nogc pure nothrow:

	immutable struct Done {}
	mixin Union!(Done, JsExpr, JsBlockStatement);

	static ExprResult done() =>
		ExprResult(ExprResult.Done());
}

JsExpr translateExprToExpr(ref TranslateExprCtx ctx, ExprAndType a) =>
	translateExprToExpr(ctx, a.expr, a.type);
JsExpr translateExprToExpr(ref TranslateExprCtx ctx, ref Expr a, Type type) =>
	translateExpr(ctx, a, type, ExprPos(ExprPos.Expression())).as!JsExpr;
alias TranslateCb = ExprResult delegate(scope ExprPos) @safe @nogc pure nothrow;
JsExpr translateToExpr(in TranslateCb cb) =>
	cb(ExprPos(ExprPos.Expression())).as!JsExpr;
JsStatement translateToStatement(ref Alloc alloc, in TranslateCb cb) =>
	translateToStatement(alloc, (scope ref ArrayBuilder!JsStatement, scope ExprPos pos) => cb(pos));
alias StatementsCb = ExprResult delegate(scope ref ArrayBuilder!JsStatement, scope ExprPos) @safe @nogc pure nothrow;
JsStatement translateToStatement(ref Alloc alloc, in StatementsCb cb) {
	JsStatement[] statements = translateToStatements(alloc, cb);
	return statements.length == 1 ? only(statements) : JsStatement(JsBlockStatement(statements));
}
JsBlockStatement translateToBlockStatement(ref Alloc alloc, in StatementsCb cb) =>
	JsBlockStatement(translateToStatements(alloc, cb));
JsBlockStatement translateToBlockStatement(ref Alloc alloc, in TranslateCb cb) =>
	translateToBlockStatement(alloc, (scope ref ArrayBuilder!JsStatement, scope ExprPos pos) => cb(pos));
JsStatement[] translateToStatements(ref Alloc alloc, in StatementsCb cb) {
	ExprPos.Statements pos;
	ExprResult res = cb(pos.statements, ExprPos(&pos));
	assert(res.isA!(ExprResult.Done));
	JsStatement[] statements = finish(alloc, pos.statements);
	assert(!isEmpty(statements));
	return statements;
}

JsBlockStatement translateExprToBlockStatement(ref TranslateExprCtx ctx, ref Expr a, Type type) =>
	translateToBlockStatement(ctx.alloc, (scope ExprPos pos) => translateExpr(ctx, a, type, pos));
JsExprOrBlockStatement translateExprToExprOrBlockStatement(ref TranslateExprCtx ctx, ref Expr a, Type type) =>
	toExprOrBlockStatement(ctx.alloc, translateExpr(ctx, a, type, ExprPos(ExprPos.ExpressionOrBlockStatement())));
JsExprOrBlockStatement translateToExprOrBlockStatement(ref Alloc alloc, in TranslateCb cb) =>
	toExprOrBlockStatement(alloc, cb(ExprPos(ExprPos.ExpressionOrBlockStatement())));
JsExprOrBlockStatement toExprOrBlockStatement(ref Alloc alloc, ExprResult result) =>
	result.match!JsExprOrBlockStatement(
		(ExprResult.Done) =>
			assert(false),
		(JsExpr x) =>
			JsExprOrBlockStatement(allocate(alloc, x)),
		(JsBlockStatement x) =>
			JsExprOrBlockStatement(x));

JsBlockStatement translateExprToSwitchBlockStatement(ref TranslateExprCtx ctx, ref Expr a, Type type) =>
	isVoid(type)
		? translateToBlockStatement(ctx.alloc, (scope ExprPos pos) =>
			forceStatements(ctx, pos, (scope ref ArrayBuilder!JsStatement out_, scope ExprPos inner) {
				ExprResult result = translateExpr(ctx, a, type, inner);
				assert(result.isA!(ExprResult.Done));
				add(ctx.alloc, out_, genBreakNoLabel());
				return result;
			}))
		: translateExprToBlockStatement(ctx, a, type);

ExprResult forceExpr(ref TranslateExprCtx ctx, scope ExprPos pos, Type type, JsExpr expr) =>
	forceExpr(ctx.alloc, pos, type, expr);
ExprResult forceExpr(ref Alloc alloc, scope ExprPos pos, Type type, JsExpr expr) =>
	pos.match!ExprResult(
		(ExprPos.Expression) =>
			ExprResult(expr),
		(ExprPos.ExpressionOrBlockStatement) =>
			ExprResult(expr),
		(ref ExprPos.Statements x) {
			add(alloc, x.statements, isVoid(type) ? JsStatement(expr) : genReturn(alloc, expr));
			return ExprResult.done;
		});
ExprResult forceStatements(ref TranslateExprCtx ctx, scope ExprPos pos, in StatementsCb cb) =>
	pos.match!ExprResult(
		(ExprPos.Expression) =>
			ExprResult(genIife(ctx.alloc, isCurFunAsync(ctx), makeBlockStatement(ctx.alloc, cb))),
		(ExprPos.ExpressionOrBlockStatement) =>
			ExprResult(makeBlockStatement(ctx.alloc, cb)),
		(ref ExprPos.Statements x) =>
			cb(x.statements, pos));
JsBlockStatement makeBlockStatement(
	ref Alloc alloc,
	in ExprResult delegate(scope ref ArrayBuilder!JsStatement, scope ExprPos) @safe @nogc pure nothrow cb,
) {
	ExprPos.Statements res;
	ExprResult inner = cb(res.statements, ExprPos(&res));
	assert(inner.isA!(ExprResult.Done));
	return JsBlockStatement(finish(alloc, res.statements));
}

ExprResult forceStatement(ref TranslateExprCtx ctx, scope ExprPos pos, JsStatement statement) =>
	forceStatement(ctx.alloc, isCurFunAsync(ctx), pos, statement);
ExprResult forceStatement(ref Alloc alloc, SyncOrAsync curFunAsync, scope ExprPos pos, JsStatement statement) =>
	pos.match!ExprResult(
		(ExprPos.Expression) =>
			ExprResult(genIife(alloc, curFunAsync, genBlockStatement(alloc, [statement]))),
		(ExprPos.ExpressionOrBlockStatement) =>
			ExprResult(genBlockStatement(alloc, [statement])),
		(ref ExprPos.Statements x) {
			add(alloc, x.statements, statement);
			return ExprResult.done;
		});

ExprResult translateExpr(ref TranslateExprCtx ctx, ref Expr a, Type type, scope ExprPos pos) =>
	a.kind.match!ExprResult(
		(ref AssertOrForbidExpr x) =>
			translateAssertOrForbid(ctx, a, x, type, pos),
		(BogusExpr x) =>
			forceStatement(ctx, pos, genThrowBogus(ctx.alloc)),
		(CallExpr x) =>
			translateCall(ctx, x, type, pos),
		(ref CallOptionExpr x) =>
			translateCallOption(ctx, x, type, pos),
		(ClosureGetExpr x) =>
			forceExpr(ctx, pos, type, JsExpr(localName(*x.local))),
		(ClosureSetExpr x) =>
			forceStatement(ctx, pos, genAssign(
				ctx.alloc,
				localName(*x.local),
				translateExprToExpr(ctx, *x.value, x.local.type))),
		(ExternExpr x) =>
			forceExpr(ctx, pos, type, genBool(x.name.asSymbol in ctx.ctx.allExterns)),
		(ref FinallyExpr x) =>
			translateFinally(ctx, x, type, pos),
		(FunPointerExpr x) =>
			forceExpr(ctx, pos, type, translateFunToExpr(ctx, x.called)),
		(ref IfExpr x) =>
			translateIf(ctx, x, type, pos),
		(ref LambdaExpr x) =>
			translateLambda(ctx, x, type, pos),
		(ref LetExpr x) =>
			translateLet(ctx, x, type, pos),
		(LiteralExpr x) =>
			forceExpr(ctx, pos, type, translateConstant(ctx.ctx, x.value, type)),
		(LiteralStringLikeExpr x) =>
			forceExpr(ctx, pos, type, translateLiteralStringLike(ctx, x)),
		(LocalGetExpr x) {
			if (x.local.type.isBogus)
				return translateToBogus(ctx.alloc, pos);
			else {
				assert(type == x.local.type);
				return forceExpr(ctx, pos, type, translateLocalGet(x.local));
			}
		},
		(LocalPointerExpr x) =>
			assert(false),
		(LocalSetExpr x) =>
			forceStatement(ctx, pos, genAssign(
				ctx.alloc,
				localName(*x.local),
				translateExprToExpr(ctx, *x.value, x.local.type))),
		(ref LoopExpr x) =>
			forceStatement(ctx, pos, genWhileTrue(
				ctx.alloc,
				some(JsName.noPrefix(symbol!"loop")),
				translateExprToBlockStatement(ctx, x.body_, type))),
		(ref LoopBreakExpr x) {
			assert(pos.isA!(ExprPos.Statements*));
			ExprResult res = translateExpr(ctx, x.value, type, pos);
			assert(res.isA!(ExprResult.Done));
			if (isVoid(type))
				add(ctx.alloc, pos.as!(ExprPos.Statements*).statements, genBreak(JsName.noPrefix(symbol!"loop")));
			return res;
		},
		(LoopContinueExpr x) {
			assert(pos.isA!(ExprPos.Statements*));
			return forceStatement(ctx, pos, JsStatement(JsContinueStatement()));
		},
		(ref LoopWhileOrUntilExpr x) =>
			translateLoopWhileOrUntil(ctx, x, type, pos),
		(ref MatchEnumExpr x) =>
			translateMatchEnum(ctx, x, type, pos),
		(ref MatchIntegralExpr x) =>
			translateMatchIntegral(ctx, x, type, pos),
		(ref MatchStringLikeExpr x) =>
			translateMatchStringLike(ctx, x, type, pos),
		(ref MatchUnionExpr x) =>
			translateMatchUnion(ctx, x, type, pos),
		(ref MatchVariantExpr x) =>
			translateMatchVariant(ctx, x, type, pos),
		(ref RecordFieldPointerExpr x) =>
			assert(false),
		(ref SeqExpr x) =>
			forceStatements(ctx, pos, (scope ref ArrayBuilder!JsStatement, scope ExprPos inner) {
				ExprResult first = translateExpr(ctx, x.first, Type(ctx.commonTypes.void_), inner);
				assert(first.isA!(ExprResult.Done));
				return translateExpr(ctx, x.then, type, inner);
			}),
		(ref ThrowExpr x) =>
			forceStatement(ctx, pos, genThrow(
				ctx.alloc,
				translateExprToExpr(ctx, x.thrown, Type(ctx.commonTypes.exception)))),
		(ref TrustedExpr x) =>
			translateExpr(ctx, x.inner, type, pos),
		(ref TryExpr x) =>
			translateTry(ctx, x, type, pos),
		(ref TryLetExpr x) =>
			translateTryLet(ctx, x, type, pos),
		(ref TypedExpr x) =>
			translateExpr(ctx, x.inner, type, pos));

ExprResult translateAssertOrForbid(
	ref TranslateExprCtx ctx,
	ref Expr expr,
	ref AssertOrForbidExpr a,
	Type type,
	scope ExprPos pos,
) {
	ExprResult throw_(scope ExprPos inner) =>
		forceStatement(ctx, inner, genThrow(ctx.alloc, has(a.thrown)
			? translateExprToExpr(ctx, *force(a.thrown), Type(ctx.commonTypes.exception))
			: genNewError(
				ctx,
				defaultAssertOrForbidMessage(ctx.alloc, ctx.curUri, expr, a, ctx.fileContentGetters))));
	ExprResult after(scope ExprPos inner) =>
		translateExpr(ctx, a.after, type, inner);
	return translateIfCb(
		ctx, type, pos, a.condition,
		cbTrueBranch: (scope ExprPos inner) => a.isForbid ? throw_(inner) : after(inner),
		cbFalseBranch: (scope ExprPos inner) => a.isForbid ? after(inner) : throw_(inner));
}

ExprResult translateCall(ref TranslateExprCtx ctx, ref CallExpr a, Type type, scope ExprPos pos) {
	assert(type == a.called.returnType);
	return translateCallCommon(ctx, a.called, [], a.args, pos);
}
ExprResult translateCallOption(ref TranslateExprCtx ctx, ref CallOptionExpr a, Type type, scope ExprPos pos) =>
	/*
	firstArg?.called
	==>
	const option = firstArg
	return "some" in option
		// 'Option.some' will be omitted if 'called' already returns an option
		? Option.some(called(option.some))
		: Option.none
	*/
	withTemp(ctx, symbol!"option", a.firstArg, pos, (JsName option, scope ExprPos inner) {
		JsExpr forceIt = genOptionForce(ctx.alloc, JsExpr(option));
		JsExpr call = translateToExpr((scope ExprPos callPos) =>
			translateCallCommon(ctx, a.called, [forceIt], a.restArgs, callPos));
		JsExpr then = a.called.returnType == type
			? call
			: genOptionSome(ctx, type, call);
		return forceExpr(ctx, inner, type, genTernary(
			ctx.alloc,
			genOptionHas(ctx.alloc, JsExpr(option)),
			then,
			genOptionNone(ctx, type)));
	});
ExprResult translateCallCommon(
	ref TranslateExprCtx ctx,
	Called called,
	in JsExpr[] prefixArgs,
	in Expr[] args,
	scope ExprPos pos,
) =>
	isInlined(called)
		? translateInlineCall(
			ctx,
			called.returnType,
			pos,
			called.as!(FunInst*).decl,
			called.as!(FunInst*).paramTypes,
			prefixArgs.length + args.length,
			(size_t argIndex) =>
				argIndex < prefixArgs.length
					? prefixArgs[argIndex]
					: translateExprToExpr(ctx, args[argIndex - prefixArgs.length], paramTypeAt(called, argIndex)))
		: forceExpr(ctx, pos, called.returnType, makeCallNoInline(ctx, called, (scope ref Builder!JsExpr out_) {
			out_ ~= prefixArgs;
			foreach (size_t argIndex, ref Expr arg; args)
				out_ ~= translateExprToExpr(ctx, arg, paramTypeAt(called, prefixArgs.length + argIndex));
		}));

bool isInlined(in Called a) =>
	a.isA!(FunInst*) && bodyIsInlined(*a.as!(FunInst*).decl);

ExprResult translateInlineCall(
	ref TranslateExprCtx ctx,
	Type returnType,
	scope ExprPos pos,
	in FunDecl* called,
	in Type[] paramTypes,
	size_t nArgs,
	in JsExpr delegate(size_t) @safe @nogc pure nothrow getArg,
) {
	ExprResult expr(JsExpr value) =>
		forceExpr(ctx.alloc, pos, returnType, value);
	JsExpr onlyArg() {
		assert(nArgs == 1);
		return getArg(0);
	}
	JsExpr[] args(size_t skip = 0) {
		assert(nArgs >= skip);
		return makeArray(ctx.alloc, nArgs - skip, (size_t i) => getArg(i + skip));
	}
	ExprResult createRecord(StructInst* record) =>
		expr(genNew(ctx.alloc, translateStructReference(ctx, record.decl), args()));
	JsExpr returnTypeRef() =>
		translateStructReference(ctx, returnType.as!(StructInst*).decl);
	JsExpr recordField(RecordField* field) =>
		genPropertyAccess(ctx.alloc, getArg(0), JsMemberName.recordField(field.name));
	return called.body_.matchIn!ExprResult(
		(in FunBody.Bogus) =>
			translateToBogus(ctx.alloc, pos),
		(in AutoFun x) =>
			assert(false),
		(in BuiltinFun x) =>
			translateCallBuiltin(ctx, returnType, pos, x, nArgs, getArg),
		(in FunBody.CreateEnumOrFlags x) =>
			expr(genPropertyAccess(ctx.alloc, returnTypeRef, JsMemberName.enumMember(x.member.name))),
		(in FunBody.CreateExtern) =>
			assert(false),
		(in FunBody.CreateRecord) =>
			createRecord(returnType.as!(StructInst*)),
		(in FunBody.CreateRecordAndConvertToVariant x) =>
			createRecord(x.member),
		(in FunBody.CreateUnion x) {
			JsExpr member = genPropertyAccess(ctx.alloc, returnTypeRef, JsMemberName.unionConstructor(x.member.name));
			assert(nArgs == 0 || nArgs == 1);
			return expr(nArgs == 0 ? member : genCallSync(ctx.alloc, member, [getArg(0)]));
		},
		(in FunBody.CreateVariant) =>
			expr(onlyArg()),
		(in EnumOrFlagsFunction x) =>
			expr(translateEnumOrFlagsFunction(ctx, returnType, paramTypes, x, nArgs, getArg)),
		(in Expr _) =>
			assert(false),
		(in FunBody.Extern) =>
			assert(false),
		(in FunBody.FileImport) =>
			assert(false),
		(in FunBody.RecordFieldCall x) {
			assert(nArgs >= 1);
			return expr(genCallAwait(
				ctx.alloc,
				allocate(ctx.alloc, recordField(x.field)),
				x.funKind == FunKind.function_
					? args(skip: 1)
					: newArray(ctx.alloc, [genTuple(ctx, nArgs - 1, (size_t i) => getArg(i + 1))])));
		},
		(in FunBody.RecordFieldGet x) =>
			expr(recordField(x.field)),
		(in FunBody.RecordFieldPointer) =>
			assert(false),
		(in FunBody.RecordFieldSet x) {
			assert(nArgs == 2);
			return forceStatement(ctx, pos, genAssign(ctx.alloc, recordField(x.field), getArg(1)));
		},
		(in FunBody.UnionMemberGet x) =>
			withTemp2(ctx, symbol!"member", onlyArg(), pos, (JsName member, scope ExprPos inner) {
				JsMemberName memberName = JsMemberName.unionMember(x.member.name);
				return forceExpr(ctx.alloc, inner, returnType, genTernary(
					ctx.alloc,
					genIn(ctx.alloc, memberName, JsExpr(member)),
					genOptionSome(ctx, returnType, genPropertyAccess(ctx.alloc, JsExpr(member), memberName)),
					genOptionNone(ctx, returnType)));
			}),
		(in FunBody.VarGet x) =>
			expr(translateVarReference(ctx.ctx, x.var)),
		(in FunBody.VariantMemberGet) {
			assert(!bodyIsInlined(*called));
			JsExpr arg = onlyArg();
			StructDecl* variant = mustUnwrapOptionType(ctx.commonTypes, returnType).as!(StructInst*).decl;
			// x instanceof Foo ? Option.some(x) : Option.none
			return expr(genTernary(ctx.alloc,
				genInstanceof(ctx.alloc, arg, translateStructReference(ctx, variant)),
				genOptionSome(ctx, returnType, arg),
				genOptionNone(ctx, returnType)));
		},
		(in FunBody.VariantMethod x) =>
			expr(genCall(
				ctx.alloc,
				isAsyncFun(ctx.ctx.allUsed, called),
				allocate(ctx.alloc, genPropertyAccess(ctx.alloc, getArg(0), JsMemberName.variantMethod(x.method.name))),
				args(skip: 1))),
		(in FunBody.VarSet x) =>
			forceStatement(ctx, pos, genAssign(ctx.alloc, translateVarReference(ctx.ctx, x.var), onlyArg())));
}

ExprResult translateCallBuiltin(
	ref TranslateExprCtx ctx,
	Type returnType,
	scope ExprPos pos,
	in BuiltinFun a,
	size_t nArgs,
	in JsExpr delegate(size_t) @safe @nogc pure nothrow getArg,
) {
	ExprResult expr(JsExpr value) =>
		forceExpr(ctx.alloc, pos, returnType, value);
	return a.matchIn!ExprResult(
		(in BuiltinFun.AllTests) {
			assert(nArgs == 0);
			return expr(translateAllTests(ctx.ctx));
		},
		(in BuiltinUnary x) {
			assert(nArgs == 1);
			return expr(translateBuiltinUnary(ctx.alloc, x, getArg(0)));
		},
		(in BuiltinUnaryMath x) {
			assert(nArgs == 1);
			return expr(translateBuiltinUnaryMath(ctx.alloc, x, getArg(0)));
		},
		(in BuiltinBinary x) {
			assert(nArgs == 2);
			return translateBuiltinBinary(ctx, returnType, pos, x, getArg(0), getArg(1));
		},
		(in BuiltinBinaryLazy x) {
			assert(nArgs == 2);
			return translateBuiltinBinaryLazy(ctx, returnType, pos, x, getArg(0), getArg(1));
		},
		(in BuiltinBinaryMath x) {
			assert(nArgs == 2);
			return expr(translateBuiltinBinaryMath(ctx, x, getArg(0), getArg(1)));
		},
		(in BuiltinTernary x) =>
			assert(false),
		(in Builtin4ary x) =>
			assert(false),
		(in BuiltinFun.CallLambda) =>
			expr(genCallAwait(ctx.alloc, getArg(0), [
				genTuple(ctx, nArgs - 1, (size_t i) => getArg(i + 1))])),
		(in BuiltinFun.CallFunPointer) =>
			expr(genCallAwait(
				ctx.alloc,
				allocate(ctx.alloc, getArg(0)),
				makeArray(ctx.alloc, nArgs - 1, (size_t i) => getArg(i + 1)))),
		(in Constant x) {
			assert(nArgs == 0);
			return expr(translateConstant(ctx.ctx, x, returnType));
		},
		(in BuiltinFun.GcSafeValue) {
			assert(nArgs == 0);
			return expr(genNull());
		},
		(in BuiltinFun.Init) =>
			assert(false),
		(in JsFun x) =>
			translateCallJsFun(ctx.ctx, returnType, pos, x, nArgs, getArg),
		(in BuiltinFun.MarkRoot) =>
			assert(false),
		(in BuiltinFun.MarkVisit) =>
			assert(false),
		(in BuiltinFun.PointerCast) =>
			assert(false),
		(in BuiltinFun.SizeOf) =>
			assert(false),
		(in BuiltinFun.StaticSymbols) =>
			assert(false),
		(in VersionFun x) {
			assert(nArgs == 0);
			return expr(genBool(isVersion(ctx.ctx.version_, x)));
		});
}
JsExpr translateEnumOrFlagsFunction(
	ref TranslateExprCtx ctx,
	Type returnType,
	in Type[] paramTypes,
	EnumOrFlagsFunction a,
	size_t nArgs,
	in JsExpr delegate(size_t) @safe @nogc pure nothrow getArg,
) {
	JsExpr getValue(JsExpr arg) =>
		genPropertyAccess(ctx.alloc, arg, JsMemberName.special(symbol!"value"));
	JsExpr call(Symbol name) {
		assert(nArgs == 1 || nArgs == 2);
		return nArgs == 1
			? genCallPropertySync(ctx.alloc, getArg(0), JsMemberName.special(name), [])
			: genCallPropertySync(ctx.alloc, getArg(0), JsMemberName.special(name), [getArg(1)]);
	}
	JsExpr staticProperty(Type enumOrFlags, Symbol name) =>
		genPropertyAccess(
			ctx.alloc,
			translateStructReference(ctx, enumOrFlags.as!(StructInst*).decl),
			JsMemberName.special(name));
	final switch (a) {
		case EnumOrFlagsFunction.equal: {
			StructDecl* decl = paramTypes[0].as!(StructInst*).decl;
			if (decl.body_.isA!(StructBody.Flags))
				return genEqEqEq(ctx.alloc, getValue(getArg(0)), getValue(getArg(1)));
			else {
				assert(decl.body_.isA!(StructBody.Enum*));
				return genEqEqEq(ctx.alloc, getArg(0), getArg(1));
			}
		}
		case EnumOrFlagsFunction.intersect:
			return call(symbol!"intersect");
		case EnumOrFlagsFunction.members:
			assert(nArgs == 0);
			Type pair = arrayElementType(returnType);
			return staticProperty(only2(force(asTuple(ctx.commonTypes, pair)))[1], symbol!"members");
		case EnumOrFlagsFunction.negate:
			return call(symbol!"negate");
		case EnumOrFlagsFunction.none:
			return staticProperty(returnType, symbol!"none");
		case EnumOrFlagsFunction.toIntegral:
			assert(nArgs == 1);
			return getValue(getArg(0));
		case EnumOrFlagsFunction.union_:
			return call(symbol!"union");
	}
}

JsExpr translateAllTests(ref TranslateModuleCtx ctx) =>
	genArray(buildArray!JsExpr(ctx.alloc, (scope ref Builder!JsExpr out_) {
		eachTest(ctx.program, ctx.allExterns, (Test* test) {
			out_ ~= translateTestReference(ctx, test);
		});
	}));

JsExpr translateBuiltinUnary(ref Alloc alloc, BuiltinUnary a, JsExpr arg) {
	JsExpr Array = genGlobal(symbol!"Array");
	JsExpr BigInt = genGlobal(symbol!"BigInt");
	JsExpr Number = genGlobal(symbol!"Number");
	JsExpr bitwiseNot() => genBitwiseNot(alloc, arg);
	final switch (a) {
		case BuiltinUnary.asFuture:
		case BuiltinUnary.asFutureImpl:
		case BuiltinUnary.arrayPointer:
		case BuiltinUnary.asAnyPointer:
		case BuiltinUnary.cStringOfSymbol:
		case BuiltinUnary.deref:
		case BuiltinUnary.drop:
		case BuiltinUnary.jumpToCatch:
		case BuiltinUnary.referenceFromPointer:
		case BuiltinUnary.setupCatch:
		case BuiltinUnary.symbolOfCString:
		case BuiltinUnary.toNat64FromPtr:
		case BuiltinUnary.toPtrFromNat64:
			// These are 'native extern'
			assert(false);
		case BuiltinUnary.arraySize:
			return genCallSync(alloc, BigInt, [genPropertyAccess(alloc, arg, JsMemberName.noPrefix(symbol!"length"))]);
		case BuiltinUnary.bitwiseNotNat8:
			return genAsNat8(alloc, bitwiseNot());
		case BuiltinUnary.bitwiseNotNat16:
			return genAsNat16(alloc, bitwiseNot());
		case BuiltinUnary.bitwiseNotNat32:
			return genAsNat32(alloc, bitwiseNot());
		case BuiltinUnary.bitwiseNotNat64:
			return genAsNat64(alloc, bitwiseNot());
		case BuiltinUnary.countOnesNat64:
			// Array.from(n.toString(2))
			JsExpr digits = genCallPropertySync(alloc, Array, JsMemberName.noPrefix(symbol!"from"), [
				genCallPropertySync(alloc, arg, JsMemberName.noPrefix(symbol!"toString"), [genNumber(2)])]);
			JsName x = JsName.specialLocal(symbol!"x");
			// x => x === "1"
			JsExpr fn = genArrowFunction(
				alloc, SyncOrAsync.sync, [JsDestructure(x)], genEqEqEq(alloc, JsExpr(x), genString("1")));
			// BigInt(Array.from(n.toString(2)).filter(x => x === "1").length)
			return genCallSync(alloc, BigInt, [
				genPropertyAccess(
					alloc,
					genCallPropertySync(alloc, digits, JsMemberName.noPrefix(symbol!"filter"), [fn]),
					JsMemberName.noPrefix(symbol!"length"))]);
		case BuiltinUnary.isNanFloat32:
		case BuiltinUnary.isNanFloat64:
			return genCallPropertySync(alloc, Number, JsMemberName.noPrefix(symbol!"isNaN"), [arg]);
		case BuiltinUnary.not:
			return genUnary(alloc, JsUnaryExpr.Kind.not, arg);
		case BuiltinUnary.toChar8FromNat8:
		case BuiltinUnary.toInt64FromInt8:
		case BuiltinUnary.toInt64FromInt16:
		case BuiltinUnary.toInt64FromInt32:
		case BuiltinUnary.toNat8FromChar8:
		case BuiltinUnary.toNat32FromChar32:
		case BuiltinUnary.toNat64FromNat8:
		case BuiltinUnary.toNat64FromNat16:
		case BuiltinUnary.toNat64FromNat32:
		case BuiltinUnary.unsafeToChar32FromChar8:
		case BuiltinUnary.unsafeToChar32FromNat32:
		case BuiltinUnary.unsafeToNat32FromInt32:
		case BuiltinUnary.unsafeToInt8FromInt64:
		case BuiltinUnary.unsafeToInt16FromInt64:
		case BuiltinUnary.unsafeToInt32FromInt64:
		case BuiltinUnary.unsafeToNat64FromInt64:
		case BuiltinUnary.unsafeToInt64FromNat64:
		case BuiltinUnary.unsafeToNat8FromNat64:
		case BuiltinUnary.unsafeToNat16FromNat64:
		case BuiltinUnary.unsafeToNat32FromNat64:
		case BuiltinUnary.toFloat32FromFloat64:
		case BuiltinUnary.toFloat64FromFloat32:
			// These are all conversions between types that are represented the same in JS
			return arg;
		case BuiltinUnary.toFloat64FromInt64:
		case BuiltinUnary.toFloat64FromNat64:
			return genCallSync(alloc, Number, [arg]);
		case BuiltinUnary.toChar8ArrayFromString:
			// Array.from(new TextEncoder().encode(arg)).map(BigInt)
			return genCallPropertySync(
				alloc,
				genArrayFrom(
					alloc,
					genCallPropertySync(
						alloc,
						genNew(alloc, genGlobal(symbol!"TextEncoder"), []),
						JsMemberName.noPrefix(symbol!"encode"),
						[arg])),
				JsMemberName.noPrefix(symbol!"map"),
				[BigInt]);
		case BuiltinUnary.truncateToInt64FromFloat64:
			return genCallSync(alloc, BigInt, [callMath(alloc, symbol!"trunc", arg)]);
		case BuiltinUnary.trustAsString:
			// new TextDecoder().decode(new Uint8Array(arg.map(Number)))
			return genCallPropertySync(
				alloc,
				genNew(alloc, genGlobal(symbol!"TextDecoder"), []),
				JsMemberName.noPrefix(symbol!"decode"),
				[genNew(
					alloc,
					genGlobal(symbol!"Uint8Array"),
					[genCallPropertySync(alloc, arg, JsMemberName.noPrefix(symbol!"map"), [Number])])]);
	}
}
JsExpr genArrayFrom(ref Alloc alloc, JsExpr arg) =>
	genCallPropertySync(alloc, genGlobal(symbol!"Array"), JsMemberName.noPrefix(symbol!"from"), [arg]);

JsExpr translateBuiltinUnaryMath(ref Alloc alloc, BuiltinUnaryMath a, JsExpr arg) {
	JsExpr f32(Symbol name) =>
		toFloat32(alloc, callMath(alloc, name, arg));
	JsExpr f64(Symbol name) =>
		callMath(alloc, name, arg);
	JsExpr round() =>
		// JS round gives wrong results for negative numbers, so fix by only rounding positive
		// Math.sign(arg) * Math.round(Math.abs(arg))
		genTimes(
			alloc,
			callMath(alloc, symbol!"sign", arg),
			callMath(alloc, symbol!"round", callMath(alloc, symbol!"abs", arg)));

	final switch (a) {
		case BuiltinUnaryMath.acosFloat32:
			return f32(symbol!"acos");
		case BuiltinUnaryMath.acoshFloat32:
			return f32(symbol!"acosh");
		case BuiltinUnaryMath.asinFloat32:
			return f32(symbol!"asin");
		case BuiltinUnaryMath.asinhFloat32:
			return f32(symbol!"asinh");
		case BuiltinUnaryMath.atanFloat32:
			return f32(symbol!"atan");
		case BuiltinUnaryMath.atanhFloat32:
			return f32(symbol!"atanh");
		case BuiltinUnaryMath.cosFloat32:
			return f32(symbol!"cos");
		case BuiltinUnaryMath.coshFloat32:
			return f32(symbol!"cosh");
		case BuiltinUnaryMath.roundDownFloat32:
			return f32(symbol!"floor");
		case BuiltinUnaryMath.roundFloat32:
			return toFloat32(alloc, round());
		case BuiltinUnaryMath.roundUpFloat32:
			return f32(symbol!"ceil");
		case BuiltinUnaryMath.sinFloat32:
			return f32(symbol!"sin");
		case BuiltinUnaryMath.sinhFloat32:
			return f32(symbol!"sinh");
		case BuiltinUnaryMath.sqrtFloat32:
			return f32(symbol!"sqrt");
		case BuiltinUnaryMath.tanFloat32:
			return f32(symbol!"tan");
		case BuiltinUnaryMath.tanhFloat32:
			return f32(symbol!"tanh");
		case BuiltinUnaryMath.unsafeLogFloat32:
			return f32(symbol!"log");

		case BuiltinUnaryMath.acosFloat64:
			return f64(symbol!"acos");
		case BuiltinUnaryMath.acoshFloat64:
			return f64(symbol!"acosh");
		case BuiltinUnaryMath.asinFloat64:
			return f64(symbol!"asin");
		case BuiltinUnaryMath.asinhFloat64:
			return f64(symbol!"asinh");
		case BuiltinUnaryMath.atanFloat64:
			return f64(symbol!"atan");
		case BuiltinUnaryMath.atanhFloat64:
			return f64(symbol!"atanh");
		case BuiltinUnaryMath.cosFloat64:
			return f64(symbol!"cos");
		case BuiltinUnaryMath.coshFloat64:
			return f64(symbol!"cosh");
		case BuiltinUnaryMath.roundDownFloat64:
			return f64(symbol!"floor");
		case BuiltinUnaryMath.roundFloat64:
			return round();
		case BuiltinUnaryMath.roundUpFloat64:
			return f64(symbol!"ceil");
		case BuiltinUnaryMath.sinFloat64:
			return f64(symbol!"sin");
		case BuiltinUnaryMath.sinhFloat64:
			return f64(symbol!"sinh");
		case BuiltinUnaryMath.sqrtFloat64:
			return f64(symbol!"sqrt");
		case BuiltinUnaryMath.tanFloat64:
			return f64(symbol!"tan");
		case BuiltinUnaryMath.tanhFloat64:
			return f64(symbol!"tanh");
		case BuiltinUnaryMath.unsafeLogFloat64:
			return f64(symbol!"log");
	}
}
JsExpr callMath(ref Alloc alloc, Symbol name, JsExpr arg) =>
	genCallPropertySync(alloc, genGlobal(symbol!"Math"), JsMemberName.noPrefix(name), [arg]);
JsExpr toFloat32(ref Alloc alloc, JsExpr arg) =>
	callMath(alloc, symbol!"fround", arg);

JsExpr genAsNat(ref Alloc alloc, uint bits, JsExpr arg) =>
	genCallPropertySync(
		alloc,
		genGlobal(symbol!"BigInt"),
		JsMemberName.noPrefix(symbol!"asUintN"),
		[genNumber(bits), arg]);
JsExpr genAsNat8(ref Alloc alloc, JsExpr arg) =>
	genAsNat(alloc, 8, arg);
JsExpr genAsNat16(ref Alloc alloc, JsExpr arg) =>
	genAsNat(alloc, 16, arg);
JsExpr genAsNat32(ref Alloc alloc, JsExpr arg) =>
	genAsNat(alloc, 32, arg);
JsExpr genAsNat64(ref Alloc alloc, JsExpr arg) =>
	genAsNat(alloc, 64, arg);

ExprResult translateBuiltinBinary(
	ref TranslateExprCtx ctx,
	Type type,
	scope ExprPos pos,
	BuiltinBinary a,
	JsExpr left,
	JsExpr right,
) {
	ExprResult expr(JsExpr value) =>
		forceExpr(ctx.alloc, pos, type, value);
	JsExpr binary(JsBinaryExpr.Kind kind) =>
		genBinary(ctx.alloc, kind, left, right);
	JsExpr add() =>
		binary(JsBinaryExpr.Kind.plus);
	JsExpr sub() =>
		binary(JsBinaryExpr.Kind.minus);
	JsExpr mul() =>
		binary(JsBinaryExpr.Kind.times);
	JsExpr div() =>
		binary(JsBinaryExpr.Kind.divide);
	final switch (a) {
		case BuiltinBinary.addFloat32:
			return expr(toFloat32(ctx.alloc, add()));
		case BuiltinBinary.addFloat64:
		case BuiltinBinary.unsafeAddInt8:
		case BuiltinBinary.unsafeAddInt16:
		case BuiltinBinary.unsafeAddInt32:
		case BuiltinBinary.unsafeAddInt64:
		case BuiltinBinary.unsafeAddNat8:
		case BuiltinBinary.unsafeAddNat16:
		case BuiltinBinary.unsafeAddNat32:
		case BuiltinBinary.unsafeAddNat64:
			return expr(add());
		case BuiltinBinary.bitwiseAndInt8:
		case BuiltinBinary.bitwiseAndInt16:
		case BuiltinBinary.bitwiseAndInt32:
		case BuiltinBinary.bitwiseAndInt64:
		case BuiltinBinary.bitwiseAndNat8:
		case BuiltinBinary.bitwiseAndNat16:
		case BuiltinBinary.bitwiseAndNat32:
		case BuiltinBinary.bitwiseAndNat64:
			return expr(binary(JsBinaryExpr.Kind.bitwiseAnd));
		case BuiltinBinary.bitwiseOrInt8:
		case BuiltinBinary.bitwiseOrInt16:
		case BuiltinBinary.bitwiseOrInt32:
		case BuiltinBinary.bitwiseOrInt64:
		case BuiltinBinary.bitwiseOrNat8:
		case BuiltinBinary.bitwiseOrNat16:
		case BuiltinBinary.bitwiseOrNat32:
		case BuiltinBinary.bitwiseOrNat64:
			return expr(binary(JsBinaryExpr.Kind.bitwiseOr));
		case BuiltinBinary.bitwiseXorInt8:
		case BuiltinBinary.bitwiseXorInt16:
		case BuiltinBinary.bitwiseXorInt32:
		case BuiltinBinary.bitwiseXorInt64:
		case BuiltinBinary.bitwiseXorNat8:
		case BuiltinBinary.bitwiseXorNat16:
		case BuiltinBinary.bitwiseXorNat32:
		case BuiltinBinary.bitwiseXorNat64:
			return expr(binary(JsBinaryExpr.Kind.bitwiseXor));
		case BuiltinBinary.eqChar8:
		case BuiltinBinary.eqChar32:
		case BuiltinBinary.eqFloat32:
		case BuiltinBinary.eqFloat64:
		case BuiltinBinary.eqInt8:
		case BuiltinBinary.eqInt16:
		case BuiltinBinary.eqInt32:
		case BuiltinBinary.eqInt64:
		case BuiltinBinary.eqNat8:
		case BuiltinBinary.eqNat16:
		case BuiltinBinary.eqNat32:
		case BuiltinBinary.eqNat64:
		case BuiltinBinary.referenceEqual:
			return expr(binary(JsBinaryExpr.Kind.eqEqEq));
		case BuiltinBinary.lessChar8:
		case BuiltinBinary.lessFloat32:
		case BuiltinBinary.lessFloat64:
		case BuiltinBinary.lessInt8:
		case BuiltinBinary.lessInt16:
		case BuiltinBinary.lessInt32:
		case BuiltinBinary.lessInt64:
		case BuiltinBinary.lessNat8:
		case BuiltinBinary.lessNat16:
		case BuiltinBinary.lessNat32:
		case BuiltinBinary.lessNat64:
			return expr(binary(JsBinaryExpr.Kind.less));
		case BuiltinBinary.mulFloat32:
			return expr(toFloat32(ctx.alloc, mul()));
		case BuiltinBinary.mulFloat64:
		case BuiltinBinary.unsafeMulInt8:
		case BuiltinBinary.unsafeMulInt16:
		case BuiltinBinary.unsafeMulInt32:
		case BuiltinBinary.unsafeMulInt64:
		case BuiltinBinary.unsafeMulNat8:
		case BuiltinBinary.unsafeMulNat16:
		case BuiltinBinary.unsafeMulNat32:
		case BuiltinBinary.unsafeMulNat64:
			return expr(mul());
		case BuiltinBinary.subFloat32:
			return expr(toFloat32(ctx.alloc, sub()));
		case BuiltinBinary.subFloat64:
		case BuiltinBinary.unsafeSubInt8:
		case BuiltinBinary.unsafeSubInt16:
		case BuiltinBinary.unsafeSubInt32:
		case BuiltinBinary.unsafeSubInt64:
		case BuiltinBinary.unsafeSubNat8:
		case BuiltinBinary.unsafeSubNat16:
		case BuiltinBinary.unsafeSubNat32:
		case BuiltinBinary.unsafeSubNat64:
			return expr(sub());
		case BuiltinBinary.unsafeBitShiftLeftNat64:
			return expr(genAsNat64(ctx.alloc, binary(JsBinaryExpr.Kind.bitShiftLeft)));
		case BuiltinBinary.unsafeBitShiftRightNat64:
			return expr(genAsNat64(ctx.alloc, binary(JsBinaryExpr.Kind.bitShiftRight)));
		case BuiltinBinary.unsafeDivFloat32:
			return expr(toFloat32(ctx.alloc, div()));
		case BuiltinBinary.unsafeDivFloat64:
		case BuiltinBinary.unsafeDivInt8:
		case BuiltinBinary.unsafeDivInt16:
		case BuiltinBinary.unsafeDivInt32:
		case BuiltinBinary.unsafeDivInt64:
		case BuiltinBinary.unsafeDivNat8:
		case BuiltinBinary.unsafeDivNat16:
		case BuiltinBinary.unsafeDivNat32:
		case BuiltinBinary.unsafeDivNat64:
			return expr(div());
		case BuiltinBinary.unsafeModNat64:
			return expr(binary(JsBinaryExpr.Kind.modulo));
		case BuiltinBinary.wrapAddNat8:
			return expr(genAsNat8(ctx.alloc, add()));
		case BuiltinBinary.wrapAddNat16:
			return expr(genAsNat16(ctx.alloc, add()));
		case BuiltinBinary.wrapAddNat32:
			return expr(genAsNat32(ctx.alloc, add()));
		case BuiltinBinary.wrapAddNat64:
			return expr(genAsNat64(ctx.alloc, add()));
		case BuiltinBinary.wrapMulNat8:
			return expr(genAsNat8(ctx.alloc, mul()));
		case BuiltinBinary.wrapMulNat16:
			return expr(genAsNat16(ctx.alloc, mul()));
		case BuiltinBinary.wrapMulNat32:
			return expr(genAsNat32(ctx.alloc, mul()));
		case BuiltinBinary.wrapMulNat64:
			return expr(genAsNat64(ctx.alloc, mul()));
		case BuiltinBinary.wrapSubNat8:
			return expr(genAsNat8(ctx.alloc, sub()));
		case BuiltinBinary.wrapSubNat16:
			return expr(genAsNat16(ctx.alloc, sub()));
		case BuiltinBinary.wrapSubNat32:
			return expr(genAsNat32(ctx.alloc, sub()));
		case BuiltinBinary.wrapSubNat64:
			return expr(genAsNat64(ctx.alloc, sub()));
		case BuiltinBinary.addPointerAndNat64:
		case BuiltinBinary.eqPointer:
		case BuiltinBinary.lessPointer:
		case BuiltinBinary.newArray:
		case BuiltinBinary.seq:
		case BuiltinBinary.subPointerAndNat64:
		case BuiltinBinary.switchFiber:
		case BuiltinBinary.writeToPointer:
			assert(false);
	}
}
ExprResult translateBuiltinBinaryLazy(
	ref TranslateExprCtx ctx,
	Type type,
	scope ExprPos pos,
	BuiltinBinaryLazy kind,
	JsExpr left,
	JsExpr right,
) {
	final switch (kind) {
		case BuiltinBinaryLazy.boolAnd:
			return forceExpr(ctx.alloc, pos, type, genBinary(ctx.alloc, JsBinaryExpr.Kind.and, left, right));
		case BuiltinBinaryLazy.boolOr:
			return forceExpr(ctx.alloc, pos, type, genBinary(ctx.alloc, JsBinaryExpr.Kind.or, left, right));
		case BuiltinBinaryLazy.optionOr:
			// const option = x
			// return "some" in option ? option : right
			return withTemp2(ctx, symbol!"option", left, pos, (JsName option, scope ExprPos inner) =>
				forceExpr(ctx.alloc, inner, type, genTernary(
					ctx.alloc,
					genOptionHas(ctx.alloc, JsExpr(option)),
					JsExpr(option),
					right)));
		case BuiltinBinaryLazy.optionQuestion2:
			// const option = left
			// return "some" in option ? option.some : right
			return withTemp2(ctx, symbol!"option", left, pos, (JsName option, scope ExprPos inner) =>
				forceExpr(ctx.alloc, inner, type, genTernary(
					ctx.alloc,
					genOptionHas(ctx.alloc, JsExpr(option)),
					genOptionForce(ctx.alloc, JsExpr(option)),
					right)));
	}
}

JsExpr translateBuiltinBinaryMath(ref TranslateExprCtx ctx, BuiltinBinaryMath kind, JsExpr left, JsExpr right) {
	JsExpr Math = genGlobal(symbol!"Math");
	JsExpr atan2 = genCallPropertySync(ctx.alloc, Math, JsMemberName.noPrefix(symbol!"atan2"), [left, right]);
	final switch (kind) {
		case BuiltinBinaryMath.atan2Float32:
			return toFloat32(ctx.alloc, atan2);
		case BuiltinBinaryMath.atan2Float64:
			return atan2;
	}
}

ExprResult translateCallJsFun(
	ref TranslateModuleCtx ctx,
	Type returnType,
	scope ExprPos pos,
	JsFun fun,
	size_t nArgs,
	in JsExpr delegate(size_t) @safe @nogc pure nothrow getArg,
) {
	ExprResult expr(JsExpr value) =>
		forceExpr(ctx.alloc, pos, returnType, value);
	ExprResult unary(JsUnaryExpr.Kind kind) {
		assert(nArgs == 1);
		return expr(genUnary(ctx.alloc, kind, getArg(0)));
	}
	ExprResult binary(JsBinaryExpr.Kind kind) {
		assert(nArgs == 2);
		return expr(genBinary(ctx.alloc, kind, getArg(0), getArg(1)));
	}
	final switch (fun) {
		case JsFun.asJsAny:
		case JsFun.cast_:
			assert(nArgs == 1);
			return expr(getArg(0));
		case JsFun.await:
			assert(nArgs == 1);
			return expr(genAwait(ctx.alloc, getArg(0)));
		case JsFun.call:
			return expr(genCallSync(
				allocate(ctx.alloc, getArg(0)),
				makeArray(ctx.alloc, nArgs - 1, (size_t i) => getArg(i + 1))));
		case JsFun.callNew:
			return expr(genNew(
				allocate(ctx.alloc, getArg(0)),
				makeArray(ctx.alloc, nArgs - 1, (size_t i) => getArg(i + 1))));
		case JsFun.callProperty:
			assert(nArgs >= 2);
			return expr(genCallSync(
				allocate(ctx.alloc, genPropertyAccessComputed(ctx.alloc, getArg(0), getArg(1))),
				makeArray(ctx.alloc, nArgs - 2, (size_t i) => getArg(i + 2))));
		case JsFun.callPropertySpread:
			assert(nArgs == 3);
			return expr(genCallWithSpread(
				ctx.alloc,
				SyncOrAsync.sync,
				genPropertyAccessComputed(ctx.alloc, getArg(0), getArg(1)),
				[],
				getArg(2)));
		case JsFun.eqEqEq:
			return binary(JsBinaryExpr.Kind.eqEqEq);
		case JsFun.get:
			assert(nArgs == 2);
			return expr(genPropertyAccessComputed(ctx.alloc, getArg(0), getArg(1)));
		case JsFun.instanceof:
			return binary(JsBinaryExpr.Kind.instanceof);
		case JsFun.jsGlobal:
			assert(nArgs == 0);
			return expr(genGlobal(ctx.isBrowser ? symbol!"window" : symbol!"global"));
		case JsFun.less:
			return binary(JsBinaryExpr.Kind.less);
		case JsFun.plus:
			return binary(JsBinaryExpr.Kind.plus);
		case JsFun.set:
			assert(nArgs == 3);
			return forceStatement(ctx.alloc, SyncOrAsync.sync, pos, genAssign(
				ctx.alloc,
				genPropertyAccessComputed(ctx.alloc, getArg(0), getArg(1)),
				getArg(2)));
		case JsFun.typeof_:
			return unary(JsUnaryExpr.Kind.typeof_);
	}
}

ExprResult translateIf(ref TranslateExprCtx ctx, ref IfExpr a, Type type, scope ExprPos pos) =>
	translateIfCb(
		ctx, type, pos, a.condition,
		(scope ExprPos inner) => translateExpr(ctx, a.trueBranch, type, inner),
		(scope ExprPos inner) => translateExpr(ctx, a.falseBranch, type, inner));
ExprResult translateIfCb(
	ref TranslateExprCtx ctx,
	Type type,
	scope ExprPos pos,
	in Condition condition,
	in TranslateCb cbTrueBranch,
	in TranslateCb cbFalseBranch,
) {
	Opt!bool constant = tryEvalConstantBool(ctx.ctx.version_, ctx.ctx.allExterns, condition);
	return has(constant)
		? (force(constant) ? cbTrueBranch : cbFalseBranch)(pos)
		: pos.isA!(ExprPos.Expression) && condition.isA!(Expr*)
		? ExprResult(genTernary(
			ctx.alloc,
			translateExprToExpr(ctx, *condition.as!(Expr*), Type(ctx.commonTypes.bool_)),
			translateToExpr(cbTrueBranch),
			translateToExpr(cbFalseBranch)))
		: condition.match!ExprResult(
			(ref Expr cond) =>
				forceStatement(ctx, pos, genIf(
					ctx.alloc,
					translateExprToExpr(ctx, cond, Type(ctx.commonTypes.bool_)),
					translateToStatement(ctx.alloc, cbTrueBranch),
					translateToStatement(ctx.alloc, cbFalseBranch))),
			(ref Condition.UnpackOption x) =>
				translateUnpackOption(ctx, type, pos, x, cbTrueBranch, cbFalseBranch));
}
ExprResult translateUnpackOption(
	ref TranslateExprCtx ctx,
	Type type,
	scope ExprPos pos,
	ref Condition.UnpackOption unpack,
	in TranslateCb cbTrueBranch,
	in TranslateCb cbFalseBranch,
) =>
	/*
	const option = <<option>>
	if ('some' in option) {
		const <<destructure>> = option.some
		<<true branch>>
	} else {
		<<false branch>>
	}
	*/
	withTemp(ctx, symbol!"option", unpack.option, pos, (JsName option, scope ExprPos inner) =>
		forceStatement(ctx, inner, genIf(
			ctx.alloc,
			genOptionHas(ctx.alloc, JsExpr(option)),
			translateToStatement(ctx.alloc, (scope ExprPos inner2) =>
				translateLetLikeCb(
					ctx, unpack.destructure, genOptionForce(ctx.alloc, JsExpr(option)), inner2,
					(scope ref ArrayBuilder!JsStatement, scope ExprPos inner3) =>
						cbTrueBranch(inner3))),
			translateToStatement(ctx.alloc, cbFalseBranch))));

JsExpr genOptionHas(ref Alloc alloc, JsExpr option) =>
	genIn(alloc, JsMemberName.unionMember(symbol!"some"), option);
JsExpr genOptionForce(ref Alloc alloc, JsExpr option) =>
	genPropertyAccess(alloc, option, JsMemberName.unionMember(symbol!"some"));
JsExpr genOptionSome(ref TranslateExprCtx ctx, Type option, JsExpr arg) =>
	genCallPropertySync(
		ctx.alloc,
		translateStructReference(ctx, option.as!(StructInst*).decl),
		JsMemberName.unionConstructor(symbol!"some"),
		[arg]);
JsExpr genOptionNone(ref TranslateExprCtx ctx, Type option) =>
	genPropertyAccess(
		ctx.alloc,
		translateStructReference(ctx, option.as!(StructInst*).decl),
		JsMemberName.unionConstructor(symbol!"none"));

ExprResult translateLambda(ref TranslateExprCtx ctx, ref LambdaExpr a, Type type, scope ExprPos pos) =>
	forceExpr(ctx, pos, type, JsExpr(JsArrowFunction(
		SyncOrAsync.async,
		JsParams(newSmallArray(ctx.alloc, [translateDestructure(ctx, a.param)])),
		translateExprToExprOrBlockStatement(ctx, a.body_, a.returnType))));

ExprResult translateLet(ref TranslateExprCtx ctx, ref LetExpr a, Type type, scope ExprPos pos) =>
	translateLetLike(ctx, a.destructure, translateExprToExpr(ctx, a.value, a.destructure.type), a.then, type, pos);
ExprResult translateLetLike(
	ref TranslateExprCtx ctx,
	ref Destructure destructure,
	JsExpr value,
	ref Expr then,
	Type type,
	scope ExprPos pos,
) =>
	translateLetLikeCb(ctx, destructure, value, pos, (scope ref ArrayBuilder!JsStatement, scope ExprPos inner) =>
		translateExpr(ctx, then, type, inner));
ExprResult translateLetLikeCb(
	ref TranslateExprCtx ctx,
	in Destructure destructure,
	JsExpr value,
	scope ExprPos pos,
	in StatementsCb cb,
) =>
	forceStatements(ctx, pos, (scope ref ArrayBuilder!JsStatement out_, scope ExprPos inner) {
		if (destructure.isA!(Destructure.Ignore*)) {
			if (!value.isA!JsName)
				add(ctx.alloc, out_, JsStatement(value));
		} else
			add(ctx.alloc, out_, genVarDecl(
				hasAnyMutable(destructure) ? JsVarDecl.Kind.let : JsVarDecl.Kind.const_,
				translateDestructure(ctx, destructure),
				some(allocate(ctx.alloc, value))));
		return cb(out_, inner);
	});

JsExpr translateConstant(ref TranslateModuleCtx ctx, in Constant value, in Type type) {
	if (type.isA!TypeParamIndex) {
		assert(value.isA!(Constant.Zero));
		return genNull();
	} else {
		switch (type.as!(StructInst*).decl.body_.as!BuiltinType) {
			case BuiltinType.bool_:
				return genBool(asBool(value));
			case BuiltinType.float32:
			case BuiltinType.float64:
				return genNumber(value.as!(Constant.Float).value);
			case BuiltinType.int8:
			case BuiltinType.int16:
			case BuiltinType.int32:
			case BuiltinType.int64:
				return genIntegerSigned(asInt64(value));
			case BuiltinType.char8:
			case BuiltinType.char32:
			case BuiltinType.nat8:
			case BuiltinType.nat16:
			case BuiltinType.nat32:
			case BuiltinType.nat64:
				return genIntegerUnsigned(asNat64(value));
			case BuiltinType.void_:
				return genUndefined();
			default:
				assert(false);
		}
	}
}
JsExpr translateLiteralStringLike(ref TranslateExprCtx ctx, ref LiteralStringLikeExpr a) {
	JsExpr[] char8s() =>
		map(ctx.alloc, a.value, (ref immutable char x) =>
			genIntegerUnsigned(x));
	JsExpr[] char32s() =>
		buildArray!JsExpr(ctx.alloc, (scope ref Builder!JsExpr out_) {
			mustUnicodeDecode(a.value, (dchar x) {
				out_ ~= genIntegerUnsigned(x);
			});
		});
	final switch (a.kind) {
		case LiteralStringLikeExpr.Kind.char8Array:
			return genArray(char8s());
		case LiteralStringLikeExpr.Kind.char8List:
			return genNewList(ctx.ctx, char8s());
		case LiteralStringLikeExpr.Kind.char32Array:
			return genArray(char32s());
		case LiteralStringLikeExpr.Kind.char32List:
			return genNewList(ctx.ctx, char32s());
		case LiteralStringLikeExpr.Kind.cString:
			assert(false);
		case LiteralStringLikeExpr.Kind.string_:
		case LiteralStringLikeExpr.Kind.symbol:
			return genString(a.value);
	}
}

JsExpr translateLocalGet(in Local* local) =>
	JsExpr(localName(*local));

ExprResult translateLoopWhileOrUntil(
	ref TranslateExprCtx ctx,
	ref LoopWhileOrUntilExpr a,
	Type type,
	scope ExprPos pos,
) =>
	a.condition.match!ExprResult(
		(ref Expr cond) {
			JsExpr condition = translateExprToExpr(ctx, cond, Type(ctx.commonTypes.bool_));
			JsExpr condition2 = a.isUntil ? genNot(ctx.alloc, condition) : condition;
			return forceStatements(ctx, pos, (scope ref ArrayBuilder!JsStatement res, scope ExprPos inner) {
				add(ctx.alloc, res, genWhile(
					ctx.alloc,
					condition2,
					translateExprToBlockStatement(ctx, a.body_, Type(ctx.commonTypes.void_))));
				return translateExpr(ctx, a.after, type, inner);
			});
		},
		(ref Condition.UnpackOption unpack) =>
			forceStatements(ctx, pos, (scope ref ArrayBuilder!JsStatement outerOut, scope ExprPos outerPos) {
				if (a.isUntil) {
					/*
					let option
					while (true) {
						option = <<option>>
						if ("some" in option) break
						<<body>>
					}
					const <<destructure>> = option.some
					<<after>>
					*/
					JsName option = tempName(ctx, symbol!"option");
					add(ctx.alloc, outerOut, genLet(option));
					JsBlockStatement body_ = translateToBlockStatement(
						ctx.alloc,
						(scope ref ArrayBuilder!JsStatement out_, scope ExprPos bodyPos) {
							add(ctx.alloc, out_, genAssign(ctx.alloc, option, translateExprToExpr(ctx, unpack.option)));
							add(ctx.alloc, out_, genIf(
								ctx.alloc,
								genOptionHas(ctx.alloc, JsExpr(option)),
								genBreakNoLabel()));
							return translateExpr(ctx, a.body_, Type(ctx.commonTypes.void_), bodyPos);
						});
					add(ctx.alloc, outerOut, genWhileTrue(ctx.alloc, body_));
					return translateLetLike(
						ctx, unpack.destructure, genOptionForce(ctx.alloc, JsExpr(option)), a.after, type, outerPos);
				} else {
					/*
					while (true) {
						const option = <<option>>
						if ("some" in option) {
							const <<destructure>> = option.some
							<<body>>
						} else
							break
					}
					<<after>>
					*/
					JsBlockStatement body_ = translateToBlockStatement(
						ctx.alloc,
						(scope ref ArrayBuilder!JsStatement out_, scope ExprPos bodyPos) =>
							translateUnpackOption(
								ctx, Type(ctx.commonTypes.void_), bodyPos, unpack,
								(scope ExprPos thenPos) =>
									translateExpr(ctx, a.body_, Type(ctx.commonTypes.void_), thenPos),
								(scope ExprPos elsePos) =>
									forceStatement(ctx, elsePos, genBreakNoLabel())));
					add(ctx.alloc, outerOut, genWhileTrue(ctx.alloc, body_));
					return translateExpr(ctx, a.after, type, outerPos);
				}
			}));

ExprResult translateMatchEnum(ref TranslateExprCtx ctx, ref MatchEnumExpr a, Type type, scope ExprPos pos) =>
	forceStatement(ctx, pos, genSwitch(
		ctx.alloc,
		translateExprToExpr(ctx, a.matched),
		map(ctx.alloc, a.cases, (ref MatchEnumExpr.Case case_) =>
			JsSwitchStatement.Case(
				translateEnumValue(ctx.ctx, case_.member),
				translateExprToSwitchBlockStatement(ctx, case_.then, type))),
		translateSwitchDefault(ctx, a.else_, type, "Invalid enum value")));

ExprResult translateMatchIntegral(ref TranslateExprCtx ctx, ref MatchIntegralExpr a, Type type, scope ExprPos pos) =>
	forceStatement(ctx, pos, genSwitch(
		ctx.alloc,
		translateExprToExpr(ctx, a.matched),
		map(ctx.alloc, a.cases, (ref MatchIntegralExpr.Case case_) =>
			JsSwitchStatement.Case(
				a.kind.isSigned ? genIntegerSigned(case_.value.asSigned) : genIntegerUnsigned(case_.value.asUnsigned),
				translateExprToSwitchBlockStatement(ctx, case_.then, type))),
		translateExprToSwitchBlockStatement(ctx, a.else_, type)));

ExprResult translateMatchStringLike(
	ref TranslateExprCtx ctx,
	ref MatchStringLikeExpr a,
	Type type,
	scope ExprPos pos,
) =>
	forceStatement(ctx, pos, genSwitch(
		ctx.alloc,
		translateExprToExpr(ctx, a.matched),
		map(ctx.alloc, a.cases, (ref MatchStringLikeExpr.Case case_) =>
			JsSwitchStatement.Case(genString(case_.value), translateExprToSwitchBlockStatement(ctx, case_.then, type))),
		translateExprToSwitchBlockStatement(ctx, a.else_, type)));

ExprResult translateMatchUnion(ref TranslateExprCtx ctx, ref MatchUnionExpr a, Type type, scope ExprPos pos) =>
	withTemp(ctx, symbol!"matched", a.matched, pos, (JsName matched, scope ExprPos inner) =>
		translateMatchUnionOrVariant!(MatchUnionExpr.Case)(
			ctx, matched, a.cases, type, inner,
			translateSwitchDefault(ctx, has(a.else_) ? some(*force(a.else_)) : none!Expr, type, "Invalid union value"),
			(ref MatchUnionExpr.Case case_) =>
				MatchUnionOrVariantCase(
					genIn(ctx.alloc, JsMemberName.unionMember(case_.member.name), JsExpr(matched)),
					genPropertyAccess(ctx.alloc, JsExpr(matched), JsMemberName.unionMember(case_.member.name)))));

ExprResult translateMatchVariant(ref TranslateExprCtx ctx, ref MatchVariantExpr a, Type type, scope ExprPos pos) =>
	withTemp(ctx, symbol!"matched", a.matched, pos, (JsName matched, scope ExprPos inner) =>
		translateMatchVariant(ctx, matched, a.cases, translateExprToBlockStatement(ctx, a.else_, type), type, inner));
ExprResult translateMatchVariant(
	ref TranslateExprCtx ctx,
	JsName matched,
	MatchVariantExpr.Case[] cases,
	JsBlockStatement else_,
	Type type,
	scope ExprPos pos,
) =>
	translateMatchUnionOrVariant!(MatchVariantExpr.Case)(
		ctx, matched, cases, type, pos, else_,
		(ref MatchVariantExpr.Case case_) =>
			MatchUnionOrVariantCase(
				genInstanceof(ctx.alloc, JsExpr(matched), translateStructReference(ctx, case_.member.decl)),
				JsExpr(matched)));

immutable struct MatchUnionOrVariantCase {
	JsExpr isMatch;
	JsExpr destructured;
}
ExprResult translateMatchUnionOrVariant(Case)(
	ref TranslateExprCtx ctx,
	JsName matched,
	Case[] cases,
	Type type,
	scope ExprPos pos,
	JsBlockStatement default_,
	in MatchUnionOrVariantCase delegate(ref Case) @safe @nogc pure nothrow cbCase,
) =>
	forceStatement(
		ctx, pos,
		foldReverse!(JsStatement, Case)(JsStatement(default_), cases, (JsStatement else_, ref Case case_) {
			MatchUnionOrVariantCase x = cbCase(case_);
			return genIf(ctx.alloc,
				x.isMatch,
				translateToStatement(ctx.alloc, (scope ExprPos pos) =>
					translateLetLike(ctx, case_.destructure, x.destructured, case_.then, type, pos)),
				else_);
		}));

ExprResult withTemp(
	ref TranslateExprCtx ctx,
	Symbol name,
	ExprAndType value,
	scope ExprPos pos,
	in ExprResult delegate(JsName temp, scope ExprPos inner) @safe @nogc pure nothrow cb,
) =>
	withTemp2(ctx, name, translateExprToExpr(ctx, value), pos, cb);
ExprResult withTemp2(
	ref TranslateExprCtx ctx,
	Symbol name,
	JsExpr value,
	scope ExprPos pos,
	in ExprResult delegate(JsName temp, scope ExprPos inner) @safe @nogc pure nothrow cb,
) =>
	forceStatements(ctx, pos, (scope ref ArrayBuilder!JsStatement out_, scope ExprPos inner) {
		JsName jsName = tempName(ctx, name);
		add(ctx.alloc, out_, genConst(ctx.alloc, jsName, value));
		return cb(jsName, inner);
	});
JsName tempName(ref TranslateExprCtx ctx, Symbol base) =>
	JsName.temp(base, safeToUshort(ctx.nextTempIndex++));

ExprResult translateToBogus(ref Alloc alloc, scope ExprPos pos) =>
	forceStatement(alloc, SyncOrAsync.sync, pos, genThrowBogus(alloc));

JsStatement genThrowBogus(ref Alloc alloc) =>
	genThrowJsError(alloc, "Reached compile error");
JsExpr genThrowBogusExpr(ref Alloc alloc) =>
	genIife(alloc, SyncOrAsync.sync, genBlockStatement(alloc, [genThrowBogus(alloc)]));
JsStatement genThrowJsError(ref Alloc alloc, string message) =>
	genThrow(alloc, genNew(alloc, genGlobal(symbol!"Error"), [genString(message)]));
JsExpr genNewError(ref TranslateExprCtx ctx, string message) =>
	makeCall(ctx, Called(ctx.ctx.program.commonFuns.createError), [genString(message)]);

JsBlockStatement translateSwitchDefault(ref TranslateExprCtx ctx, Opt!Expr else_, Type type, string error) =>
	has(else_)
		? translateExprToSwitchBlockStatement(ctx, force(else_), type)
		: genBlockStatement(ctx.alloc, [genThrowJsError(ctx.alloc, error)]);

JsExpr translateEnumValue(ref TranslateModuleCtx ctx, EnumOrFlagsMember* a) =>
	genPropertyAccess(ctx.alloc, translateStructReference(ctx, a.containingEnum), JsMemberName.enumMember(a.name));

ExprResult translateFinally(ref TranslateExprCtx ctx, ref FinallyExpr a, Type type, scope ExprPos pos) =>
	/*
	finally right
	below
	==>
	try {
		below
	} finally {
		right
	}
	*/
	forceStatement(ctx, pos, JsStatement(JsTryFinallyStatement(
		translateExprToBlockStatement(ctx, a.below, type),
		translateExprToBlockStatement(ctx, a.right, Type(ctx.commonTypes.void_)))));

ExprResult translateTry(ref TranslateExprCtx ctx, ref TryExpr a, Type type, scope ExprPos pos) {
	JsName exceptionName = JsName.specialLocal(symbol!"exception");
	return forceStatement(ctx, pos, genTryCatch(
		ctx.alloc,
		translateExprToBlockStatement(ctx, a.tried, type),
		exceptionName,
		translateToBlockStatement(ctx.alloc, (scope ExprPos inner) =>
			translateMatchVariant(
				ctx, exceptionName, a.catches,
				genBlockStatement(ctx.alloc, [genThrow(ctx.alloc, JsExpr(exceptionName))]),
				type, inner))));
}

ExprResult translateTryLet(ref TranslateExprCtx ctx, ref TryLetExpr a, Type type, scope ExprPos pos) =>
	/*
	try destructure = value catch foo f : handler
	then
	==>
	let catching = true
	try {
		const destructure = value
		catching = false
		then
	} catch (exception) {
		if (!catching || !(exception instanceof Foo)) throw exception
		const f = exception
		handler
	}
	*/
	forceStatements(ctx, pos, (scope ref ArrayBuilder!JsStatement out_, scope ExprPos inner) {
		JsName catching = tempName(ctx, symbol!"catching");
		add(ctx.alloc, out_, genLet(ctx.alloc, JsDestructure(catching), genBool(true)));
		JsBlockStatement tryBlock = translateToBlockStatement(ctx.alloc, (scope ExprPos tryPos) =>
			translateLetLikeCb(
				ctx,
				a.destructure,
				translateExprToExpr(ctx, a.value, a.destructure.type),
				tryPos,
				(scope ref ArrayBuilder!JsStatement tryOut, scope ExprPos tryInner) {
					add(ctx.alloc, tryOut, genAssign(ctx.alloc, catching, genBool(false)));
					return translateExpr(ctx, a.then, type, tryInner);
				}));
		JsName exceptionName = tempName(ctx, symbol!"exception");
		JsBlockStatement catchBlock = translateToBlockStatement(
			ctx.alloc,
			(scope ref ArrayBuilder!JsStatement catchOut, scope ExprPos catchPos) {
				JsExpr cond = genOr(
					ctx.alloc,
					genNot(ctx.alloc, JsExpr(catching)),
					genNot(
						ctx.alloc,
						genInstanceof(ctx.alloc, JsExpr(exceptionName),
						translateStructReference(ctx, a.catch_.member.decl))));
				add(ctx.alloc, catchOut, genIf(ctx.alloc, cond, genThrow(ctx.alloc, JsExpr(exceptionName))));
				return translateLetLike(
					ctx, a.catch_.destructure, JsExpr(exceptionName), a.catch_.then, type, catchPos);
			});
		add(ctx.alloc, out_, genTryCatch(ctx.alloc, tryBlock, exceptionName, catchBlock));
		return ExprResult.done;
	});

bool hasAnyMutable(in Destructure a) =>
	a.matchIn!bool(
		(in Destructure.Ignore) =>
			false,
		(in Local x) =>
			!x.mutability.isImmutable,
		(in Destructure.Split x) =>
			exists!Destructure(x.parts, (in Destructure part) => hasAnyMutable(part)));

JsExpr[] withSpecImpls(
	ref TranslateExprCtx ctx,
	in Called a,
	in void delegate(scope ref Builder!JsExpr) @safe @nogc pure nothrow cb,
) =>
	withSpecImpls(ctx.ctx, ctx.curFun, a, cb);
JsExpr[] withSpecImpls(ref TranslateExprCtx ctx, in Called a, in JsExpr[] args) =>
	withSpecImpls(ctx.ctx, ctx.curFun, a, args);
JsExpr[] withSpecImpls(ref TranslateModuleCtx ctx, in Opt!(FunDecl*) caller, in Called called, in JsExpr [] args) =>
	withSpecImpls(ctx, caller, called, (scope ref Builder!JsExpr out_) {
		out_ ~= args;
	});
JsExpr[] withSpecImpls(
	ref TranslateModuleCtx ctx,
	in Opt!(FunDecl*) caller,
	in Called called,
	in void delegate(scope ref Builder!JsExpr) @safe @nogc pure nothrow cb,
) =>
	buildArray!JsExpr(ctx.alloc, (scope ref Builder!JsExpr out_) {
		writeSpecArgs(out_, ctx, caller, called);
		cb(out_);
	});

void writeSpecArgs(
	scope ref Builder!JsExpr out_,
	ref TranslateModuleCtx ctx,
	in Opt!(FunDecl*) caller,
	in Called called,
) {
	called.match!void(
		(ref Called.Bogus x) {},
		(ref FunInst x) {
			foreach (ref Called impl; x.specImpls)
				out_ ~= translateFunToExpr(ctx, caller, impl);
		},
		(CalledSpecSig x) {});
}

JsExpr makeCall(ref TranslateExprCtx ctx, Called called, in JsExpr[] args) =>
	isInlined(called)
		? translateToExpr((scope ExprPos pos) =>
			translateInlineCall(
				ctx,
				called.returnType,
				pos,
				called.as!(FunInst*).decl,
				called.paramTypes,
				args.length,
				(size_t i) => args[i]))
		: makeCallNoInline(ctx, called, (scope ref Builder!JsExpr out_) { out_ ~= args; });

JsExpr makeCallNoInlineWithSpread(
	ref TranslateModuleCtx ctx,
	SyncOrAsync await,
	Opt!(FunDecl*) caller,
	in Called called,
	in void delegate(scope ref Builder!JsExpr) @safe @nogc pure nothrow cbArgs,
	JsExpr spreadArg,
) =>
	genCallWithSpread(
		ctx.alloc,
		await,
		translateFunOrSpecReference(ctx, caller, called),
		withSpecImpls(ctx, caller, called, cbArgs),
		spreadArg);
JsExpr makeCallNoInline(
	ref TranslateExprCtx ctx,
	Called called,
	in void delegate(scope ref Builder!JsExpr) @safe @nogc pure nothrow cbArgs,
) =>
	genCall(
		ctx.alloc,
		isAsyncCall(ctx, called),
		allocate(ctx.alloc, translateFunOrSpecReference(ctx, called)),
		withSpecImpls(ctx, called, cbArgs));

// Just translates the function name -- does not include spec impls
JsExpr translateFunOrSpecReference(ref TranslateExprCtx ctx, in Called called) =>
	translateFunOrSpecReference(ctx.ctx, ctx.curFun, called);
JsExpr translateFunOrSpecReference(ref TranslateModuleCtx ctx, in Opt!(FunDecl*) caller, in Called called) =>
	called.match!JsExpr(
		(ref Called.Bogus x) =>
			genThrowBogusExpr(ctx.alloc),
		(ref FunInst x) =>
			translateFunReference(ctx, x.decl),
		(CalledSpecSig x) =>
			JsExpr(JsName(
				JsName.Kind.specSig,
				x.nonInstantiatedSig.name,
				some(safeToUshort(findSigIndex(*force(caller), x))))));

// This partially applies any spec impls
JsExpr translateFunToExpr(ref TranslateExprCtx ctx, in Called a) =>
	translateFunToExpr(ctx.ctx, ctx.curFun, a);
JsExpr translateFunToExpr(ref TranslateModuleCtx ctx, in Opt!(FunDecl*) caller, in Called a) {
	JsExpr f = translateFunOrSpecReference(ctx, caller, a);
	JsExpr[] specImpls = withSpecImpls(ctx, caller, a, []);
	if (isEmpty(specImpls))
		return f;
	else {
		// (...args) => f(spec_impl, ...args)
		JsName args = JsName.specialLocal(symbol!"args");
		// 'f' can be async, but there's no point in making an async function that does nothing but await it
		return genArrowFunction(
			SyncOrAsync.sync,
			JsParams(emptySmallArray!JsDestructure, some(JsDestructure(args))),
			JsExprOrBlockStatement(allocate(ctx.alloc, genCallWithSpread(
				ctx.alloc, SyncOrAsync.sync, f, specImpls, JsExpr(args)))));
	}
}

size_t findSigIndex(in FunDecl curFun, in CalledSpecSig called) {
	size_t res = 0;
	bool foundIt = eachSpecInFunIncludingParents(curFun, (SpecInst* spec) {
		if (spec == called.specInst) {
			res += called.sigIndex;
			return true;
		} else {
			res += spec.sigTypes.length;
			return false;
		}
	});
	assert(foundIt);
	return res;
}
