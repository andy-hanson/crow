module frontend.check.funsForStruct;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : CheckCtx;
import frontend.check.getCommonFuns : makeParam, makeParams, param;
import frontend.check.inferringType : FunType, getFunType;
import frontend.check.instantiate :
	InstantiateCtx,
	instantiateStructNeverDelay,
	makeConstPointerType,
	makeMutPointerType,
	TypeArgsArray,
	typeArgsArray;
import model.model :
	asTuple,
	BuiltinType,
	ByValOrRef,
	CommonTypes,
	EnumBackingType,
	EnumFunction,
	EnumMember,
	FunBody,
	FunDecl,
	FunDeclSource,
	FunFlags,
	Params,
	ParamShort,
	RecordField,
	SpecInst,
	StructBody,
	StructDecl,
	StructInst,
	Type,
	TypeParamIndex,
	TypeParams,
	UnionMember,
	VarDecl,
	Visibility;
import util.alloc.alloc : Alloc;
import util.col.array : isEmpty, map, mapWithFirst, small, sum;
import util.col.exactSizeArrayBuilder : ExactSizeArrayBuilder;
import util.col.mutMaxArr : asTemporaryArray;
import util.conv : safeToUint;
import util.opt : force, has, Opt, optEqual, some;
import util.symbol : prependSet, prependSetDeref, Symbol, symbol;

size_t countFunsForStructs(in CommonTypes commonTypes, in StructDecl[] structs) =>
	sum!StructDecl(structs, (in StructDecl x) => countFunsForStruct(commonTypes, x));

private size_t countFunsForStruct(in CommonTypes commonTypes, in StructDecl a) =>
	a.body_.matchIn!size_t(
		(in StructBody.Bogus) =>
			0,
		(in BuiltinType _) =>
			0,
		(in StructBody.Enum x) =>
			// 'to' and a constructor for each member
			1 + x.members.length,
		(in StructBody.Extern x) =>
			size_t(has(x.size) ? 1 : 0),
		(in StructBody.Flags x) =>
			// 'to' and a constructor for each member
			1 + x.members.length,
		(in StructBody.Record x) {
			size_t forGetSet = sum!RecordField(x.fields, (in RecordField field) =>
				1 + has(field.mutability));
			size_t forCall = sum!RecordField(x.fields, (in RecordField field) =>
				fieldHasCaller(commonTypes, field.type));
			// byVal has get/set for pointer too
			return 1 + forGetSet * (recordIsAlwaysByVal(x) ? 2 : 1) + forCall;
		},
		(in StructBody.Union x) =>
			x.members.length);

size_t countFunsForVars(in VarDecl[] vars) =>
	vars.length * 2;

void addFunsForStruct(
	ref CheckCtx ctx,
	scope ref ExactSizeArrayBuilder!FunDecl funsBuilder,
	ref CommonTypes commonTypes,
	StructDecl* struct_,
) {
	struct_.body_.match!void(
		(StructBody.Bogus) {},
		(BuiltinType _) {},
		(StructBody.Enum x) {
			addFunsForEnum(ctx, funsBuilder, commonTypes, struct_, x);
		},
		(StructBody.Extern x) {
			if (has(x.size))
				funsBuilder ~= newExtern(ctx.instantiateCtx, struct_);
		},
		(StructBody.Flags x) {
			addFunsForFlags(ctx, funsBuilder, commonTypes, struct_, x);
		},
		(StructBody.Record x) {
			addFunsForRecord(ctx, funsBuilder, commonTypes, struct_, x);
		},
		(StructBody.Union x) {
			addFunsForUnion(ctx, funsBuilder, commonTypes, struct_, x);
		});
}

void addFunsForVar(
	ref CheckCtx ctx,
	scope ref ExactSizeArrayBuilder!FunDecl funsBuilder,
	in CommonTypes commonTypes,
	VarDecl* var,
) {
	funsBuilder ~= basicFunDecl(
		FunDeclSource(var),
		var.visibility,
		var.name,
		var.type,
		Params([]),
		FunFlags.generatedBareUnsafe,
		FunBody(FunBody.VarGet(var)));
	funsBuilder ~= basicFunDecl(
		FunDeclSource(var),
		var.visibility,
		prependSet(ctx.allSymbols, var.name),
		Type(commonTypes.void_),
		makeParams(ctx.alloc, [param!"a"(var.type)]),
		FunFlags.generatedBareUnsafe,
		FunBody(FunBody.VarSet(var)));
}

FunDecl funDeclWithBody(
	FunDeclSource source,
	Visibility visibility,
	Symbol name,
	Type returnType,
	Params params,
	FunFlags flags,
	immutable(SpecInst*)[] specInsts,
	FunBody body_,
) {
	FunDecl res = FunDecl(source, visibility, name, returnType, params, flags, small!(immutable SpecInst*)(specInsts));
	res.body_ = body_;
	return res;
}

private:

FunDecl basicFunDecl(
	FunDeclSource source,
	Visibility visibility,
	Symbol name,
	Type returnType,
	Params params,
	FunFlags flags,
	FunBody body_,
) =>
	funDeclWithBody(source, visibility, name, returnType, params, flags, [], body_);

FunDecl newExtern(ref InstantiateCtx ctx, StructDecl* struct_) =>
	basicFunDecl(
		FunDeclSource(struct_),
		struct_.visibility,
		symbol!"new",
		Type(instantiateNonTemplateStructDeclNeverDelay(ctx, struct_)),
		Params([]),
		FunFlags.generatedBareUnsafe,
		FunBody(FunBody.CreateExtern()));

StructInst* instantiateNonTemplateStructDeclNeverDelay(ref InstantiateCtx ctx, StructDecl* structDecl) =>
	instantiateStructNeverDelay(ctx, structDecl, []);

bool recordIsAlwaysByVal(in StructBody.Record record) =>
	isEmpty(record.fields) || optEqual!ByValOrRef(record.flags.forcedByValOrRef, some(ByValOrRef.byVal));

void addFunsForEnum(
	ref CheckCtx ctx,
	scope ref ExactSizeArrayBuilder!FunDecl funsBuilder,
	ref CommonTypes commonTypes,
	StructDecl* struct_,
	ref StructBody.Enum enum_,
) {
	Type type = Type(instantiateNonTemplateStructDeclNeverDelay(ctx.instantiateCtx, struct_));
	funsBuilder ~= enumToIntegralFunction(ctx.alloc, struct_, enum_.backingType, type, commonTypes);
	foreach (ref EnumMember member; enum_.members)
		funsBuilder ~= enumOrFlagsConstructor(ctx.alloc, struct_.visibility, type, &member);
}

void addFunsForFlags(
	ref CheckCtx ctx,
	scope ref ExactSizeArrayBuilder!FunDecl funsBuilder,
	ref CommonTypes commonTypes,
	StructDecl* struct_,
	ref StructBody.Flags flags,
) {
	Type type = Type(instantiateNonTemplateStructDeclNeverDelay(ctx.instantiateCtx, struct_));
	funsBuilder ~= enumToIntegralFunction(ctx.alloc, struct_, flags.backingType, type, commonTypes);
	foreach (ref EnumMember member; flags.members)
		funsBuilder ~= enumOrFlagsConstructor(ctx.alloc, struct_.visibility, type, &member);
}

FunDecl enumOrFlagsConstructor(ref Alloc alloc, Visibility visibility, Type enumType, EnumMember* member) =>
	basicFunDecl(
		FunDeclSource(member),
		visibility,
		member.name,
		enumType,
		Params([]),
		FunFlags.generatedBare,
		FunBody(FunBody.CreateEnum(member)));

FunDecl enumToIntegralFunction(
	ref Alloc alloc,
	StructDecl* struct_,
	EnumBackingType enumBackingType,
	Type enumType,
	ref CommonTypes commonTypes,
) =>
	basicFunDecl(
		FunDeclSource(struct_),
		struct_.visibility,
		symbol!"to",
		Type(commonTypes.integrals.byEnumBackingType[enumBackingType]),
		makeParams(alloc, [param!"a"(enumType)]),
		FunFlags.generatedBare.withOkIfUnused(),
		FunBody(EnumFunction.toIntegral));

void addFunsForRecord(
	ref CheckCtx ctx,
	scope ref ExactSizeArrayBuilder!FunDecl funsBuilder,
	ref CommonTypes commonTypes,
	StructDecl* struct_,
	ref StructBody.Record record,
) {
	scope TypeArgsArray typeArgs = typeArgsArray();
	typeArgsFromParams(typeArgs, struct_.typeParams);
	Type structType = Type(instantiateStructNeverDelay(ctx.instantiateCtx, struct_, asTemporaryArray(typeArgs)));
	bool byVal = recordIsAlwaysByVal(record);
	addFunsForRecordConstructor(ctx, funsBuilder, commonTypes, struct_, record, structType, byVal);
	foreach (size_t fieldIndex, ref RecordField field; record.fields)
		addFunsForRecordField(ctx, funsBuilder, commonTypes, struct_, structType, byVal, fieldIndex, &field);
}

void typeArgsFromParams(scope ref TypeArgsArray out_, in TypeParams typeParams) {
	foreach (size_t i; 0 .. typeParams.length)
		out_ ~= Type(TypeParamIndex(safeToUint(i)));
}

void addFunsForRecordConstructor(
	ref CheckCtx ctx,
	scope ref ExactSizeArrayBuilder!FunDecl funsBuilder,
	ref CommonTypes commonTypes,
	StructDecl* struct_,
	ref StructBody.Record record,
	Type structType,
	bool byVal,
) {
	funsBuilder ~= funDeclWithBody(
		FunDeclSource(struct_),
		record.flags.newVisibility,
		symbol!"new",
		structType,
		Params(map(ctx.alloc, record.fields, (ref RecordField x) =>
			makeParam(ctx.alloc, x.name, x.type))),
		byVal ? FunFlags.generatedBare : FunFlags.generated,
		[],
		FunBody(FunBody.CreateRecord()));
}

void addFunsForRecordField(
	ref CheckCtx ctx,
	scope ref ExactSizeArrayBuilder!FunDecl funsBuilder,
	ref CommonTypes commonTypes,
	StructDecl* struct_,
	Type recordType,
	bool recordIsByVal,
	size_t fieldIndex,
	RecordField* field,
) {
	funsBuilder ~= funDeclWithBody(
		FunDeclSource(field),
		field.visibility,
		field.name,
		field.type,
		makeParams(ctx.alloc, [param!"a"(recordType)]),
		FunFlags.generatedBare,
		[],
		FunBody(FunBody.RecordFieldGet(fieldIndex)));

	void addRecordFieldPointer(Visibility visibility, Type recordPointer, Type fieldPointer) {
		funsBuilder ~= funDeclWithBody(
			FunDeclSource(field),
			visibility,
			field.name,
			fieldPointer,
			makeParams(ctx.alloc, [param!"a"(recordPointer)]),
			FunFlags.generatedBareUnsafe,
			[],
			FunBody(FunBody.RecordFieldPointer(fieldIndex)));
	}

	maybeAddFieldCaller(ctx, funsBuilder, commonTypes, recordType, fieldIndex, field);

	if (recordIsByVal)
		addRecordFieldPointer(
			field.visibility,
			Type(makeConstPointerType(ctx.instantiateCtx, commonTypes, recordType)),
			Type(makeConstPointerType(ctx.instantiateCtx, commonTypes, field.type)));

	if (has(field.mutability)) {
		Visibility setVisibility = force(field.mutability);
		Type recordMutPointer = Type(makeMutPointerType(ctx.instantiateCtx, commonTypes, recordType));
		if (recordIsByVal) {
			funsBuilder ~= funDeclWithBody(
				FunDeclSource(field),
				setVisibility,
				prependSetDeref(ctx.allSymbols, field.name),
				Type(commonTypes.void_),
				makeParams(ctx.alloc, [
					param!"a"(recordMutPointer),
					ParamShort(field.name, field.type),
				]),
				FunFlags.generatedBareUnsafe,
				[],
				FunBody(FunBody.RecordFieldSet(fieldIndex)));
			addRecordFieldPointer(
				setVisibility,
				recordMutPointer,
				Type(makeMutPointerType(ctx.instantiateCtx, commonTypes, field.type)));
		} else
			funsBuilder ~= funDeclWithBody(
				FunDeclSource(field),
				setVisibility,
				prependSet(ctx.allSymbols, field.name),
				Type(commonTypes.void_),
				makeParams(ctx.alloc, [param!"a"(recordType), ParamShort(field.name, field.type)]),
				FunFlags.generatedBare,
				[],
				FunBody(FunBody.RecordFieldSet(fieldIndex)));
	}
}

bool fieldHasCaller(in CommonTypes commonTypes, Type fieldType) {
	Opt!FunType optFunType = getFunType(commonTypes, fieldType);
	return has(optFunType);
}

void maybeAddFieldCaller(
	ref CheckCtx ctx,
	scope ref ExactSizeArrayBuilder!FunDecl funsBuilder,
	ref CommonTypes commonTypes,
	Type recordType,
	size_t fieldIndex,
	RecordField* field,
) {
	Opt!FunType optFunType = getFunType(commonTypes, field.type);
	if (has(optFunType)) {
		FunType funType = force(optFunType);
		Params params = paramsForFieldCaller(ctx.alloc, commonTypes, recordType, funType.paramType);
		funsBuilder ~= funDeclWithBody(
			FunDeclSource(field),
			field.visibility,
			field.name,
			funType.returnType,
			params,
			FunFlags.generated.withOkIfUnused,
			[],
			FunBody(FunBody.RecordFieldCall(fieldIndex, funType.kind)));
	}
}

Params paramsForFieldCaller(ref Alloc alloc, ref CommonTypes commonTypes, Type recordType, Type paramType) {
	Opt!(Type[]) parts = asTuple(commonTypes, paramType);
	ParamShort paramA = param!"a"(recordType);
	return has(parts)
		? makeParams(alloc, mapWithFirst!(ParamShort, Type)(alloc, paramA, force(parts), (size_t i, ref Type type) =>
			ParamShort(symbolForParam(i), type)))
		: paramType == Type(commonTypes.void_)
		? makeParams(alloc, [paramA])
		: makeParams(alloc, [paramA, ParamShort(symbol!"param", paramType)]);
}

Symbol symbolForParam(size_t index) {
	final switch (index) {
		case 0: return symbol!"param0";
		case 1: return symbol!"param1";
		case 2: return symbol!"param2";
		case 3: return symbol!"param3";
		case 4: return symbol!"param4";
		case 5: return symbol!"param5";
		case 6: return symbol!"param6";
		case 7: return symbol!"param7";
		case 8: return symbol!"param8";
		case 9: return symbol!"param9";
	}
}

void addFunsForUnion(
	ref CheckCtx ctx,
	scope ref ExactSizeArrayBuilder!FunDecl funsBuilder,
	in CommonTypes commonTypes,
	StructDecl* struct_,
	ref StructBody.Union union_,
) {
	scope TypeArgsArray typeArgs = typeArgsArray();
	typeArgsFromParams(typeArgs, struct_.typeParams);
	Type unionType = Type(instantiateStructNeverDelay(ctx.instantiateCtx, struct_, asTemporaryArray(typeArgs)));
	foreach (size_t memberIndex, ref UnionMember member; union_.members) {
		Params params = isVoid(commonTypes, member.type)
			? Params([])
			: makeParams(ctx.alloc, [param!"a"(member.type)]);
		funsBuilder ~= funDeclWithBody(
			FunDeclSource(&member),
			struct_.visibility,
			member.name,
			unionType,
			params,
			FunFlags.generatedBare,
			[],
			FunBody(FunBody.CreateUnion(memberIndex)));
	}
}

bool isVoid(in CommonTypes commonTypes, Type a) =>
	a.isA!(StructInst*) && a.as!(StructInst*) == commonTypes.void_;
