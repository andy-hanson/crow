module concretize.concretizeCtx;

@safe @nogc pure nothrow:

import concreteModel :
	BuiltinStructKind,
	byVal,
	compareConcreteType,
	ConcreteField,
	ConcreteFun,
	ConcreteFunBody,
	ConcreteParam,
	ConcreteType,
	concreteType_fromStruct,
	concreteType_pointer,
	ConcreteStruct,
	ConcreteStructBody,
	ConcreteStructInfo,
	sizeOrPointerSizeBytes;
import concretize.concretizeExpr : concretizeExpr;
import concretize.mangleName : mangleExternFunName, mangleName, writeMangledName;
import model :
	asExtern,
	body_,
	CommonTypes,
	decl,
	Expr,
	ForcedByValOrRef,
	FunBody,
	FunDecl,
	isExtern,
	matchFunBody,
	matchStructBody,
	matchType,
	name,
	noCtx,
	Param,
	params,
	range,
	RecordField,
	returnType,
	StructBody,
	StructDecl,
	StructInst,
	Type,
	typeArgs,
	TypeParam;
import util.bools : Bool, False, not, True;
import util.collection.arr : Arr, at, empty, emptyArr, only, ptrAt, range, sizeEq;
import util.collection.arrBuilder : add, ArrBuilder;
import util.collection.arrUtil : arrLiteral, arrMax, compareArr, exists, map, mapWithIndex;
import util.collection.mutArr : MutArr;
import util.collection.mutDict : addToMutDict, getOrAdd, getOrAddAndDidAdd, mustDelete, MutDict, ValueAndDidAdd;
import util.collection.str : copyStr, Str;
import util.comparison : Comparison;
import util.late : Late, lateIsSet, lateSet, lateSetOverwrite, lazilySet;
import util.memory : nu, nuMut;
import util.opt : force, has, none, Opt, some;
import util.ptr : castImmutable, castMutable, comparePtr, Ptr, ptrEquals, ptrTrustMe_mut;
import util.sym : shortSymAlphaLiteralValue, Sym;
import util.types : safeSizeTToU8;
import util.util : min, max, roundUp, todo, unreachable, verify;
import util.writer : finishWriter, Writer, writeStatic, writeStr;

void writeConcreteTypeForMangle(Alloc)(ref Writer!Alloc writer, ref immutable ConcreteType t) {
	writeStatic(writer, "__");
	if (t.isPointer)
		writeStatic(writer, "ptr_");
	writeStr(writer, t.struct_.mangledName);
}

struct TypeArgsScope {
	@safe @nogc pure nothrow:

	/*
	Suppose we have:
	pair<?ts> record
		a ?ts
		b ?ts
	make-pair pair ?tf(value ?tf)
		new value, value

	When we instantiate the struct 'pair' for the return type, and are getting the type for 'a':
	The StructInst* for that will already have an instantiated fieldTypes containing ?tf and not ?ts.
	So the only type params and args we need here come from the concretefun.
	TODO:PERF no need to store typeParams then.
	*/

	immutable Arr!TypeParam typeParams;
	immutable Arr!ConcreteType typeArgs;

	immutable this(immutable Arr!TypeParam tp, immutable Arr!ConcreteType ta) {
		typeParams = tp;
		typeArgs = ta;
		verify(sizeEq(typeParams, typeArgs));
	}

	static immutable(TypeArgsScope) empty() {
		return immutable TypeArgsScope(emptyArr!TypeParam, emptyArr!ConcreteType);
	}
}

struct ConcreteStructKey {
	immutable Ptr!StructDecl decl;
	immutable Arr!ConcreteType typeArgs;
}

immutable(Comparison) compareConcreteStructKey(ref const ConcreteStructKey a, ref const ConcreteStructKey b) {
	immutable Comparison res = comparePtr(a.decl, b.decl);
	return res != Comparison.equal ? res : compareConcreteTypeArr(a.typeArgs, b.typeArgs);
}

struct ConcreteFunKey {
	immutable Ptr!FunDecl decl;
	immutable Arr!ConcreteType typeArgs;
	immutable Arr!(Ptr!ConcreteFun) specImpls;
}

immutable(TypeArgsScope) typeArgsScope(ref immutable ConcreteFunKey a) {
	return immutable TypeArgsScope(a.decl.typeParams, a.typeArgs);
}

immutable(ConcreteFunKey) withTypeArgs(ref immutable ConcreteFunKey a, immutable Arr!ConcreteType newTypeArgs) {
	return ConcreteFunKey(a.decl, newTypeArgs, a.specImpls);
}

immutable(Comparison) compareConcreteFunKey(ref immutable ConcreteFunKey a, ref immutable ConcreteFunKey b) {
	immutable Comparison cmpDecl = comparePtr(a.decl, b.decl);
	if (cmpDecl != Comparison.equal)
		return cmpDecl;
	else {
		immutable Comparison res = compareConcreteTypeArr(a.typeArgs, b.typeArgs);
		return res != Comparison.equal
			? res
			: compareArr!(Ptr!ConcreteFun)(
				a.specImpls,
				b.specImpls,
				(ref immutable Ptr!ConcreteFun x, ref immutable Ptr!ConcreteFun y) =>
					comparePtr(x, y));
	}
}

struct ConcreteFunSource {
	immutable Ptr!ConcreteFun concreteFun;
	// NOTE: for a lambda, this is for the *outermost* fun (the one with type args and spec impls).
	// The FunDecl is needed for its TypeParam declataions.
	immutable ConcreteFunKey containingConcreteFunKey;
	// Similarly, body of the current fun, not the outer one.
	// For a lambda this is always an Expr.
	immutable FunBody body_;

}

immutable(Ptr!FunDecl) containingFunDecl(ref immutable ConcreteFunSource a) {
	return a.containingConcreteFunKey.decl;
}

ref immutable(Arr!ConcreteType) typeArgs(return scope ref immutable ConcreteFunSource a) {
	return a.containingConcreteFunKey.typeArgs;
}

immutable(TypeArgsScope) typeArgsScope(ref immutable ConcreteFunSource a) {
	return typeArgsScope(a.containingConcreteFunKey);
}

ref immutable(Arr!(Ptr!ConcreteFun)) specImpls(return scope ref immutable ConcreteFunSource a) {
	return a.containingConcreteFunKey.specImpls;
}

struct ConcretizeCtx {
	@safe @nogc pure nothrow:

	immutable Ptr!FunDecl allocFun;
	immutable Ptr!FunDecl getVatAndActorFun;
	immutable Arr!(Ptr!FunDecl) ifFuns;
	immutable Arr!(Ptr!FunDecl) callFuns;
	immutable Ptr!FunDecl nullFun;
	immutable Ptr!StructInst ctxStructInst;
	immutable Ptr!CommonTypes commonTypes;
	MutDict!(
		immutable ConcreteStructKey,
		immutable Ptr!ConcreteStruct,
		compareConcreteStructKey,
	) nonLambdaConcreteStructs;
	ArrBuilder!(immutable Ptr!ConcreteStruct) allConcreteStructs;
	MutDict!(immutable ConcreteFunKey, immutable Ptr!ConcreteFun, compareConcreteFunKey) nonLambdaConcreteFuns;
	ArrBuilder!(immutable Ptr!ConcreteFun) allConcreteFuns;

	// Funs we still need to write the bodies for
	MutArr!(Ptr!ConcreteFun) concreteFunsQueue;
	// This will only have an entry while a ConcreteFun hasn't had it's body filled in yet.
	MutDict!(immutable Ptr!ConcreteFun, immutable ConcreteFunSource, comparePtr!ConcreteFun) concreteFunToSource;
	// TODO: do these eagerly
	Late!(immutable ConcreteType) _boolType;
	Late!(immutable ConcreteType) _charType;
	Late!(immutable ConcreteType) _voidType;
	Late!(immutable ConcreteType) _anyPtrType;
	Late!(immutable ConcreteType) _ctxType;
}

immutable(ConcreteType) boolType(Alloc)(ref Alloc alloc, ref ConcretizeCtx a) {
	return lazilySet(a._boolType, () =>
		getConcreteType_forStructInst(alloc, a, a.commonTypes.bool_, TypeArgsScope.empty));
}

immutable(ConcreteType) charType(Alloc)(ref Alloc alloc, ref ConcretizeCtx a) {
	return lazilySet(a._charType, () =>
		getConcreteType_forStructInst(alloc, a, a.commonTypes.char_, TypeArgsScope.empty));
}

immutable(ConcreteType) voidType(Alloc)(ref Alloc alloc, ref ConcretizeCtx a) {
	return lazilySet(a._voidType, () =>
		getConcreteType_forStructInst(alloc, a, a.commonTypes.void_, TypeArgsScope.empty));
}

immutable(ConcreteType) anyPtrType(Alloc)(ref Alloc alloc, ref ConcretizeCtx a) {
	return lazilySet(a._anyPtrType, () =>
		getConcreteType_forStructInst(alloc, a, a.commonTypes.anyPtr, TypeArgsScope.empty));
}

immutable(ConcreteType) ctxType(Alloc)(ref Alloc alloc, ref ConcretizeCtx a)
out(it) { verify(it.isPointer); }
body {
	return lazilySet(a._ctxType, () =>
		getConcreteType_forStructInst(alloc, a, a.ctxStructInst, TypeArgsScope.empty));
}

immutable(Ptr!ConcreteFun) getOrAddConcreteFunAndFillBody(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable ConcreteFunKey key,
) {
	Ptr!ConcreteFun cf = castMutable(getOrAddConcreteFunWithoutFillingBody(alloc, ctx, key));
	fillInConcreteFunBody(alloc, ctx, cf);
	return castImmutable(cf);
}

immutable(Ptr!ConcreteFun) getConcreteFunForLambdaAndFillBody(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	immutable Bool needsCtx,
	immutable Sym name,
	ref immutable Str mangledName,
	immutable ConcreteType returnType,
	ref immutable Opt!ConcreteParam closureParam,
	ref immutable Arr!ConcreteParam params,
	ref immutable ConcreteFunKey containingConcreteFunKey,
	immutable Ptr!Expr body_,
) {
	Ptr!ConcreteFun res =
		nuMut!ConcreteFun(alloc, body_.range, name, mangledName, returnType, needsCtx, closureParam, params);
	immutable ConcreteFunSource source = ConcreteFunSource(
		castImmutable(res),
		containingConcreteFunKey,
		immutable FunBody(body_));
	addToMutDict(alloc, ctx.concreteFunToSource, castImmutable(res), source);
	fillInConcreteFunBody(alloc, ctx, res);
	add(alloc, ctx.allConcreteFuns, castImmutable(res));
	return castImmutable(res);
}

immutable(Ptr!ConcreteFun) getOrAddNonTemplateConcreteFunAndFillBody(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	immutable Ptr!FunDecl decl,
) {
	immutable ConcreteFunKey key = ConcreteFunKey(decl, emptyArr!ConcreteType, emptyArr!(Ptr!ConcreteFun));
	return getOrAddConcreteFunAndFillBody(alloc, ctx, key);
}

immutable(ConcreteType) getConcreteType_forStructInst(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	immutable Ptr!StructInst i,
	immutable TypeArgsScope typeArgsScope,
) {
	immutable Arr!ConcreteType typeArgs = typesToConcreteTypes!Alloc(alloc, ctx, typeArgs(i), typeArgsScope);
	if (ptrEquals(i.decl, ctx.commonTypes.byVal))
		return byVal(only(typeArgs));
	else {
		immutable ConcreteStructKey key = ConcreteStructKey(i.decl, typeArgs);
		immutable ValueAndDidAdd!(immutable Ptr!ConcreteStruct) res =
			getOrAddAndDidAdd(alloc, ctx.nonLambdaConcreteStructs, key, () {
				immutable Ptr!ConcreteStruct res = nu!ConcreteStruct(
					alloc,
					i.decl.name,
					getConcreteStructMangledName(alloc, i.decl.name, key.typeArgs));
				add(alloc, ctx.allConcreteStructs, res);
				return res;
			});
		if (res.didAdd)
			initializeConcreteStruct!Alloc(alloc, ctx, typeArgs, i, castMutable(res.value).deref, typeArgsScope);
		return concreteType_fromStruct(res.value);
	}
}

immutable(ConcreteType) getConcreteType(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable Type t,
	ref immutable TypeArgsScope typeArgsScope,
) {
	return matchType!(immutable ConcreteType)(
		t,
		(ref immutable Type.Bogus) =>
			unreachable!(immutable ConcreteType),
		(immutable Ptr!TypeParam p) {
			// Handle calledConcreteFun first
			verify(ptrEquals(p, ptrAt(typeArgsScope.typeParams, p.index)));
			return at(typeArgsScope.typeArgs, p.index);
		},
		(immutable Ptr!StructInst i) =>
			getConcreteType_forStructInst!Alloc(alloc, ctx, i, typeArgsScope));
}

immutable(Arr!ConcreteType) typesToConcreteTypes(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	immutable Arr!Type types,
	ref immutable TypeArgsScope typeArgsScope,
) {
	return map!ConcreteType(alloc, types, (ref immutable Type t) =>
		getConcreteType(alloc, ctx, t, typeArgsScope));
}

immutable(ConcreteType) concreteTypeFromFields_alwaysPointer(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable Arr!ConcreteField fields,
	immutable Sym name,
	immutable Str mangledName,
) {
	verify(!empty(fields));
	Ptr!ConcreteStruct cs = nuMut!ConcreteStruct(alloc, name, mangledName);
	lateSet(cs.info_, getConcreteStructInfoForFields(none!ForcedByValOrRef, fields));
	add(alloc, ctx.allConcreteStructs, castImmutable(cs));
	return concreteType_pointer(castImmutable(cs));
}

immutable(Ptr!ConcreteFun) getAllocFun(Alloc)(ref Alloc alloc, ref ConcretizeCtx ctx) {
	return getOrAddNonTemplateConcreteFunAndFillBody(alloc, ctx, ctx.allocFun);
}

immutable(Ptr!ConcreteFun) getGetVatAndActorFun(Alloc)(ref Alloc alloc, ref ConcretizeCtx ctx) {
	return getOrAddNonTemplateConcreteFunAndFillBody(alloc, ctx, ctx.getVatAndActorFun);
}

immutable(Ptr!ConcreteFun) getNullAnyPtrFun(Alloc)(ref Alloc alloc, ref ConcretizeCtx ctx) {
	//TODO: allocating this over and over will take up space..
	// Type we choose is arbitrary
	immutable Arr!ConcreteType typeArgs = arrLiteral!ConcreteType(alloc, boolType(alloc, ctx));
	immutable ConcreteFunKey key = immutable ConcreteFunKey(ctx.nullFun, typeArgs, emptyArr!(Ptr!ConcreteFun));
	return getOrAddConcreteFunAndFillBody(alloc, ctx, key);
}

private:

immutable(Ptr!ConcreteFun) getOrAddConcreteFunWithoutFillingBody(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable ConcreteFunKey key,
) {
	return getOrAdd(alloc, ctx.nonLambdaConcreteFuns, key, () {
		immutable Ptr!ConcreteFun res = getConcreteFunFromKey(alloc, ctx, key);
		add(alloc, ctx.allConcreteFuns, res);
		return res;
	});
}

immutable(Ptr!ConcreteFun) getConcreteFunFromKey(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable ConcreteFunKey key,
) {
	immutable Ptr!FunDecl decl = key.decl;
	immutable TypeArgsScope typeScope = typeArgsScope(key);
	immutable ConcreteType returnType = getConcreteType(alloc, ctx, returnType(decl), typeScope);
	immutable Arr!ConcreteParam params = concretizeParams(alloc, ctx, params(decl), typeScope);
	immutable Str mangledName = getMangledName(alloc, ctx, key, returnType, params);
	Ptr!ConcreteFun res = nuMut!ConcreteFun(
		alloc,
		range(key.decl),
		decl.name,
		mangledName,
		returnType,
		not(noCtx(decl)),
		none!ConcreteParam,
		params);
	immutable ConcreteFunSource source = ConcreteFunSource(
		castImmutable(res),
		key,
		body_(decl));
	addToMutDict(alloc, ctx.concreteFunToSource, castImmutable(res), source);
	return castImmutable(res);
}

immutable(Comparison) compareConcreteTypeArr(ref immutable Arr!ConcreteType a, ref immutable Arr!ConcreteType b) {
	return compareArr!ConcreteType(a, b, (ref immutable ConcreteType x, ref immutable ConcreteType y) =>
		compareConcreteType(x, y));
}

immutable(Str) getConcreteStructMangledName(Alloc)(
	ref Alloc alloc,
	immutable Sym declName,
	immutable Arr!ConcreteType typeArgs,
) {
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	writeMangledName(writer, declName);
	foreach (ref immutable ConcreteType ta; range(typeArgs))
		writeConcreteTypeForMangle(writer, ta);
	return finishWriter(writer);
}

// Don't need to take typeArgs here, since we have the concrete return type and param types anyway.
immutable(Str) getConcreteFunMangledName(Alloc)(
	ref Alloc alloc,
	immutable Sym declName,
	ref immutable ConcreteType returnType,
	ref immutable Arr!ConcreteParam params,
	ref immutable Arr!(Ptr!ConcreteFun) specImpls,
) {
	Writer!Alloc writer = Writer!Alloc(ptrTrustMe_mut(alloc));
	writeMangledName(writer, declName);
	writeConcreteTypeForMangle(writer, returnType);
	foreach (ref immutable ConcreteParam p; range(params))
		writeConcreteTypeForMangle(writer, p.type);
	foreach (immutable Ptr!ConcreteFun si; range(specImpls)) {
		writeStatic(writer, "__");
		writeStr(writer, si.mangledName);
	}
	return finishWriter(writer);
}


size_t sizeFromConcreteFields(immutable Arr!ConcreteField fields) {
	// TODO: this is definitely not accurate. Luckily I use static asserts in the generated code to check this.
	size_t s = 0;
	size_t maxFieldAlign = 1;
	foreach (ref immutable ConcreteField field; range(fields)) {
		immutable size_t itsSize = sizeOrPointerSizeBytes(field.type);
		//TODO: this is wrong!
		const size_t itsAlign = min(itsSize, 8);
		maxFieldAlign = max(maxFieldAlign, itsAlign);
		while (s % itsAlign != 0)
			s++;
		s += itsSize;
	}
	while (s % maxFieldAlign != 0)
		s++;
	return max(s, 1);
}

immutable(Bool) getDefaultIsPointerForFields(
	immutable Opt!ForcedByValOrRef forcedByValOrRef,
	immutable size_t sizeBytes,
	immutable Bool isSelfMutable,
) {
	if (has(forcedByValOrRef))
		final switch (force(forcedByValOrRef)) {
			case ForcedByValOrRef.byVal:
				verify(!isSelfMutable);
				return False;
			case ForcedByValOrRef.byRef:
				return True;
		}
	else
		return Bool(isSelfMutable || sizeBytes > (void*).sizeof * 2);
}

immutable(ConcreteStructInfo) getConcreteStructInfoForFields(
	immutable Opt!ForcedByValOrRef forcedByValOrRef,
	immutable Arr!ConcreteField fields,
) {
	immutable size_t sizeBytes = sizeFromConcreteFields(fields);
	immutable Bool isSelfMutable = exists(fields, (ref immutable ConcreteField fld) =>
		fld.isMutable);
	return ConcreteStructInfo(
		immutable ConcreteStructBody(ConcreteStructBody.Record(fields)),
		sizeBytes,
		isSelfMutable,
		getDefaultIsPointerForFields(forcedByValOrRef, sizeBytes, isSelfMutable));
}

void initializeConcreteStruct(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable Arr!ConcreteType typeArgs,
	immutable Ptr!StructInst i,
	ref ConcreteStruct res,
	ref immutable TypeArgsScope typeArgsScope,
) {
	// Initially make this a by-ref type, so we don't recurse infinitely when computing size
	// TODO: is this a bug? We compute the size based on assuming it's a pointer,
	// then make it not be a pointer and that would change the size?
	lateSet(res.info_, ConcreteStructInfo(
		immutable ConcreteStructBody(ConcreteStructBody.Record(emptyArr!ConcreteField)),
		/*sizeBytes*/ 9999,
		/*isSelfMutable*/ True,
		/*defaultIsPointer*/ True));

	immutable ConcreteStructInfo info = matchStructBody!(immutable ConcreteStructInfo)(
		body_(i),
		(ref immutable StructBody.Bogus) => unreachable!(immutable ConcreteStructInfo),
		(ref immutable StructBody.Builtin) {
			immutable BuiltinStructKind kind = getBuiltinStructKind(i.decl.name);
			return immutable ConcreteStructInfo(
				immutable ConcreteStructBody(ConcreteStructBody.Builtin(kind, typeArgs)),
				getBuiltinStructSize(kind),
				False,
				False);
		},
		(ref immutable StructBody.ExternPtr it) =>
			immutable ConcreteStructInfo(
				immutable ConcreteStructBody(immutable ConcreteStructBody.ExternPtr()),
				(void*).sizeof,
				False,
				//defaultIsPointer is false because the 'extern' type *is* a pointer
				False),
		(ref immutable StructBody.Record r) {
			immutable Arr!ConcreteField fields =
				mapWithIndex!ConcreteField(alloc, r.fields, (immutable size_t index, ref immutable RecordField f) =>
					immutable ConcreteField(
						safeSizeTToU8(index),
						f.isMutable,
						mangleName(alloc, f.name),
						getConcreteType(alloc, ctx, f.type, typeArgsScope)));
			return getConcreteStructInfoForFields(r.forcedByValOrRef, fields);
		},
		(ref immutable StructBody.Union u) {
			immutable Arr!ConcreteType members = map!ConcreteType(alloc, u.members, (ref immutable Ptr!StructInst si) =>
				getConcreteType_forStructInst(alloc, ctx, si, typeArgsScope));
			immutable size_t maxMember =
				arrMax(0, members, (ref immutable ConcreteType t) => sizeOrPointerSizeBytes(t));
			// Must factor in the 'kind' size. It seems that enums are int-sized.
			immutable size_t sizeBytes = roundUp(int.sizeof + maxMember, (void*).sizeof);
			return immutable ConcreteStructInfo(
				immutable ConcreteStructBody(ConcreteStructBody.Union(members)),
				sizeBytes,
				False,
				False);
		});
	lateSetOverwrite(res.info_, info);
}

immutable(Str) getMangledName(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	immutable ConcreteFunKey key,
	immutable ConcreteType returnType,
	immutable Arr!ConcreteParam params,
) {
	immutable Ptr!FunDecl decl = key.decl;
	immutable Sym name = name(decl);
	if (isExtern(decl)) {
		immutable FunBody.Extern e = asExtern(body_(decl));
		return has(e.mangledName)
			? copyStr(alloc, force(e.mangledName))
			: mangleExternFunName(alloc, name);
	} else
		return getConcreteFunMangledName(alloc, name, returnType, params, key.specImpls);
}

void fillInConcreteFunBody(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	Ptr!ConcreteFun cf,
) {
	// TODO: just assert it's not already set?
	if (!lateIsSet(cf._body_)) {
		lateSet(cf._body_, immutable ConcreteFunBody(ConcreteFunBody.Extern(False))); // set to arbitrary temporarily
		immutable ConcreteFunSource source = mustDelete(ctx.concreteFunToSource, castImmutable(cf));
		immutable ConcreteFunBody body_ = matchFunBody!(immutable ConcreteFunBody)(
			source.body_,
			(ref immutable FunBody.Builtin) =>
				immutable ConcreteFunBody(ConcreteFunBody.Builtin(typeArgs(source))),
			(ref immutable FunBody.Extern e) =>
				immutable ConcreteFunBody(ConcreteFunBody.Extern(e.isGlobal)),
			(immutable Ptr!Expr e) =>
				concretizeExpr!Alloc(alloc, ctx, source, castImmutable(cf), e.deref));
		lateSetOverwrite(cf._body_, body_);
	}
}

immutable(Arr!ConcreteParam) concretizeParams(Alloc)(
	ref Alloc alloc,
	ref ConcretizeCtx ctx,
	ref immutable Arr!Param params,
	ref immutable TypeArgsScope typeArgsScope,
) {
	return mapWithIndex!ConcreteParam(alloc, params, (immutable size_t index, ref immutable Param p) =>
		immutable ConcreteParam(
			42,
			some!size_t(index),
			mangleName(alloc, p.name),
			getConcreteType(alloc, ctx, p.type, typeArgsScope)));
}

immutable(BuiltinStructKind) getBuiltinStructKind(immutable Sym name) {
	switch (name.value) {
		case shortSymAlphaLiteralValue("bool"):
			return BuiltinStructKind.bool_;
		case shortSymAlphaLiteralValue("char"):
			return BuiltinStructKind.char_;
		case shortSymAlphaLiteralValue("float"):
			return BuiltinStructKind.float64;
		case shortSymAlphaLiteralValue("fun-ptr0"):
		case shortSymAlphaLiteralValue("fun-ptr1"):
		case shortSymAlphaLiteralValue("fun-ptr2"):
		case shortSymAlphaLiteralValue("fun-ptr3"):
		case shortSymAlphaLiteralValue("fun-ptr4"):
		case shortSymAlphaLiteralValue("fun-ptr5"):
		case shortSymAlphaLiteralValue("fun-ptr6"):
			return BuiltinStructKind.funPtrN;
		case shortSymAlphaLiteralValue("int8"):
			return BuiltinStructKind.int8;
		case shortSymAlphaLiteralValue("int16"):
			return BuiltinStructKind.int16;
		case shortSymAlphaLiteralValue("int32"):
			return BuiltinStructKind.int32;
		case shortSymAlphaLiteralValue("int"):
			return BuiltinStructKind.int64;
		case shortSymAlphaLiteralValue("nat8"):
			return BuiltinStructKind.nat8;
		case shortSymAlphaLiteralValue("nat16"):
			return BuiltinStructKind.nat16;
		case shortSymAlphaLiteralValue("nat32"):
			return BuiltinStructKind.nat32;
		case shortSymAlphaLiteralValue("nat"):
			return BuiltinStructKind.nat64;
		case shortSymAlphaLiteralValue("ptr"):
			return BuiltinStructKind.ptr;
		case shortSymAlphaLiteralValue("void"):
			return BuiltinStructKind.void_;
		default:
			return todo!(immutable BuiltinStructKind)("not a builtin struct");
	}
}

immutable(size_t) getBuiltinStructSize(immutable BuiltinStructKind kind) {
	final switch (kind) {
		case BuiltinStructKind.bool_:
			return Bool.sizeof;
		case BuiltinStructKind.char_:
			return char.sizeof;
		case BuiltinStructKind.float64:
			return double.sizeof;
		case BuiltinStructKind.funPtrN:
			return (void*).sizeof;
		case BuiltinStructKind.int8:
			return byte.sizeof;
		case BuiltinStructKind.int16:
			return short.sizeof;
		case BuiltinStructKind.int32:
			return int.sizeof;
		case BuiltinStructKind.int64:
			return long.sizeof;
		case BuiltinStructKind.nat8:
			return ubyte.sizeof;
		case BuiltinStructKind.nat16:
			return ushort.sizeof;
		case BuiltinStructKind.nat32:
			return uint.sizeof;
		case BuiltinStructKind.nat64:
			return ulong.sizeof;
		case BuiltinStructKind.ptr:
			return (void*).sizeof;
		case BuiltinStructKind.void_:
			return 1; // TODO: should be 0?
	}
}
