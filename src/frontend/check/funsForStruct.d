module frontend.check.funsForStruct;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : CheckCtx;
import frontend.check.getCommonFuns : makeParam, makeParams, param;
import frontend.check.instantiate :
	instantiateStructNeverDelay, makeArrayType, makeConstPointerType, makeMutPointerType, TypeArgsArray, typeArgsArray;
import frontend.check.typeFromAst : makeTupleType;
import frontend.programState : ProgramState;
import model.model :
	body_,
	CommonTypes,
	EnumBackingType,
	EnumFunction,
	FieldMutability,
	FlagsFunction,
	ForcedByValOrRefOrNone,
	FunBody,
	FunDecl,
	FunDeclSource,
	FunFlags,
	IntegralTypes,
	leastVisibility,
	name,
	Params,
	ParamShort,
	RecordField,
	SpecInst,
	setBody,
	StructBody,
	StructDecl,
	StructInst,
	Type,
	typeArgs,
	TypeParam,
	typeParams,
	UnionMember,
	VarDecl,
	Visibility,
	visibility;
import util.alloc.alloc : Alloc;
import util.col.arr : empty, small;
import util.col.arrUtil : map, sum;
import util.col.exactSizeArrBuilder : ExactSizeArrBuilder, exactSizeArrBuilderAdd;
import util.col.mutMaxArr : push, tempAsArr;
import util.opt : force, has, none, Opt, some;
import util.sym : prependSet, prependSetDeref, Sym, sym;

size_t countFunsForStructs(in StructDecl[] structs) =>
	sum!StructDecl(structs, (in StructDecl x) => countFunsForStruct(x));

private size_t countFunsForStruct(in StructDecl a) =>
	body_(a).matchIn!size_t(
		(in StructBody.Bogus) =>
			0,
		(in StructBody.Builtin) =>
			0,
		(in StructBody.Enum it) =>
			// '==', 'to', 'enum-members', and a constructor for each member
			3 + it.members.length,
		(in StructBody.Extern x) =>
			size_t(has(x.size) ? 1 : 0),
		(in StructBody.Flags it) =>
			// '()', 'all', '==', '~', '|', '&', 'to', 'flags-members',
			// and a constructor for each member
			8 + it.members.length,
		(in StructBody.Record x) {
			size_t forFields = sum!RecordField(x.fields, (in RecordField field) =>
				field.mutability == FieldMutability.const_ ? 1 : 2);
			// byVal has get/set for pointer too
			return 1 + forFields * (recordIsAlwaysByVal(x) ? 2 : 1);
		},
		(in StructBody.Union it) =>
			it.members.length);

size_t countFunsForVars(in VarDecl[] vars) =>
	vars.length * 2;

void addFunsForStruct(
	ref CheckCtx ctx,
	ref ExactSizeArrBuilder!FunDecl funsBuilder,
	ref CommonTypes commonTypes,
	StructDecl* struct_,
) {
	body_(*struct_).match!void(
		(StructBody.Bogus) {},
		(StructBody.Builtin) {},
		(StructBody.Enum it) {
			addFunsForEnum(ctx, funsBuilder, commonTypes, struct_, it);
		},
		(StructBody.Extern x) {
			if (has(x.size)) {
				exactSizeArrBuilderAdd(funsBuilder, newExtern(ctx.alloc, ctx.programState, struct_));
			}
		},
		(StructBody.Flags it) {
			addFunsForFlags(ctx, funsBuilder, commonTypes, struct_, it);
		},
		(StructBody.Record it) {
			addFunsForRecord(ctx, funsBuilder, commonTypes, struct_, it);
		},
		(StructBody.Union it) {
			addFunsForUnion(ctx, funsBuilder, commonTypes, struct_, it);
		});
}

void addFunsForVar(
	ref CheckCtx ctx,
	scope ref ExactSizeArrBuilder!FunDecl funsBuilder,
	in CommonTypes commonTypes,
	VarDecl* var,
) {
	exactSizeArrBuilderAdd(funsBuilder, basicFunDecl(
		FunDeclSource(var),
		var.visibility,
		var.name,
		var.type,
		Params([]),
		FunFlags.generatedBareUnsafe,
		FunBody(FunBody.VarGet(var))));
	exactSizeArrBuilderAdd(funsBuilder, basicFunDecl(
		FunDeclSource(var),
		var.visibility,
		prependSet(ctx.allSymbols, var.name),
		Type(commonTypes.void_),
		makeParams(ctx.alloc, [param!"a"(var.type)]),
		FunFlags.generatedBareUnsafe,
		FunBody(FunBody.VarSet(var))));
}

FunDecl funDeclWithBody(
	FunDeclSource source,
	Visibility visibility,
	Sym name,
	TypeParam[] typeParams,
	Type returnType,
	Params params,
	FunFlags flags,
	immutable(SpecInst*)[] specInsts,
	FunBody body_,
) {
	FunDecl res = FunDecl(source, visibility, name, small(typeParams), returnType, params, flags, small(specInsts));
	res.setBody(body_);
	return res;
}

private:

FunDecl basicFunDecl(
	FunDeclSource source,
	Visibility visibility,
	Sym name,
	Type returnType,
	Params params,
	FunFlags flags,
	FunBody body_,
) =>
	funDeclWithBody(source, visibility, name, [], returnType, params, flags, [], body_);

FunDecl newExtern(ref Alloc alloc, ref ProgramState programState, StructDecl* struct_) =>
	basicFunDecl(
		FunDeclSource(struct_),
		struct_.visibility,
		sym!"new",
		Type(instantiateNonTemplateStructDeclNeverDelay(alloc, programState, struct_)),
		Params([]),
		FunFlags.generatedBareUnsafe,
		FunBody(FunBody.CreateExtern()));

StructInst* instantiateNonTemplateStructDeclNeverDelay(
	ref Alloc alloc,
	ref ProgramState programState,
	StructDecl* structDecl,
) =>
	instantiateStructNeverDelay(alloc, programState, structDecl, []);

bool recordIsAlwaysByVal(in StructBody.Record record) =>
	empty(record.fields) || record.flags.forcedByValOrRef == ForcedByValOrRefOrNone.byVal;

void addFunsForEnum(
	ref CheckCtx ctx,
	ref ExactSizeArrBuilder!FunDecl funsBuilder,
	ref CommonTypes commonTypes,
	StructDecl* struct_,
	ref StructBody.Enum enum_,
) {
	Type enumType = Type(instantiateNonTemplateStructDeclNeverDelay(ctx.alloc, ctx.programState, struct_));
	Visibility visibility = struct_.visibility;
	addEnumFlagsCommonFunctions(
		ctx.alloc, funsBuilder, ctx.programState, struct_, enumType, enum_.backingType, commonTypes,
		sym!"enum-members");
	foreach (ref StructBody.Enum.Member member; enum_.members)
		exactSizeArrBuilderAdd(funsBuilder, enumOrFlagsConstructor(ctx.alloc, visibility, enumType, &member));
}

void addFunsForFlags(
	ref CheckCtx ctx,
	ref ExactSizeArrBuilder!FunDecl funsBuilder,
	ref CommonTypes commonTypes,
	StructDecl* struct_,
	ref StructBody.Flags flags,
) {
	Type type = Type(instantiateNonTemplateStructDeclNeverDelay(ctx.alloc, ctx.programState, struct_));
	addEnumFlagsCommonFunctions(
		ctx.alloc, funsBuilder, ctx.programState, struct_, type, flags.backingType, commonTypes, sym!"flags-members");
	exactSizeArrBuilderAdd(funsBuilder, flagsNewFunction(ctx.alloc, struct_, type));
	exactSizeArrBuilderAdd(funsBuilder, flagsAllFunction(ctx.alloc, struct_, type));
	exactSizeArrBuilderAdd(funsBuilder, flagsNegateFunction(ctx.alloc, struct_, type));
	exactSizeArrBuilderAdd(funsBuilder, flagsUnionOrIntersectFunction(
		ctx.alloc, struct_, type, sym!"|", EnumFunction.union_));
	exactSizeArrBuilderAdd(funsBuilder, flagsUnionOrIntersectFunction(
		ctx.alloc, struct_, type, sym!"&", EnumFunction.intersect));

	foreach (ref StructBody.Enum.Member member; flags.members)
		exactSizeArrBuilderAdd(funsBuilder, enumOrFlagsConstructor(ctx.alloc, struct_.visibility, type, &member));
}

void addEnumFlagsCommonFunctions(
	ref Alloc alloc,
	ref ExactSizeArrBuilder!FunDecl funsBuilder,
	ref ProgramState programState,
	StructDecl* struct_,
	Type type,
	EnumBackingType backingType,
	ref CommonTypes commonTypes,
	Sym membersName,
) {
	exactSizeArrBuilderAdd(funsBuilder, enumEqualFunction(alloc, struct_, type, commonTypes));
	exactSizeArrBuilderAdd(funsBuilder, enumToIntegralFunction(alloc, struct_, backingType, type, commonTypes));
	exactSizeArrBuilderAdd(
		funsBuilder,
		enumOrFlagsMembersFunction(alloc, programState, struct_, membersName, type, commonTypes));
}

FunDecl enumOrFlagsConstructor(ref Alloc alloc, Visibility visibility, Type enumType, StructBody.Enum.Member* member) =>
	basicFunDecl(
		FunDeclSource(member),
		visibility,
		member.name,
		enumType,
		Params([]),
		FunFlags.generatedBare,
		FunBody(FunBody.CreateEnum(member)));

FunDecl enumEqualFunction(ref Alloc alloc, StructDecl* struct_, Type enumType, in CommonTypes commonTypes) =>
	basicFunDecl(
		FunDeclSource(struct_),
		struct_.visibility,
		sym!"==",
		Type(commonTypes.bool_),
		makeParams(alloc, [param!"a"(enumType), param!"b"(enumType)]),
		FunFlags.generatedBare.withOkIfUnused(),
		FunBody(EnumFunction.equal));

FunDecl flagsNewFunction(ref Alloc alloc, StructDecl* struct_, Type enumType) =>
	basicFunDecl(
		FunDeclSource(struct_),
		struct_.visibility,
		sym!"new",
		enumType,
		Params([]),
		FunFlags.generatedBare.withOkIfUnused(),
		FunBody(FlagsFunction.new_));

FunDecl flagsAllFunction(ref Alloc alloc, StructDecl* struct_, Type enumType) =>
	basicFunDecl(
		FunDeclSource(struct_),
		struct_.visibility,
		sym!"all",
		enumType,
		Params([]),
		FunFlags.generatedBare.withOkIfUnused(),
		FunBody(FlagsFunction.all));

FunDecl flagsNegateFunction(ref Alloc alloc, StructDecl* struct_, Type enumType) =>
	basicFunDecl(
		FunDeclSource(struct_),
		struct_.visibility,
		sym!"~",
		enumType,
		makeParams(alloc, [param!"a"(enumType)]),
		FunFlags.generatedBare.withOkIfUnused(),
		FunBody(FlagsFunction.negate));

FunDecl enumToIntegralFunction(
	ref Alloc alloc,
	StructDecl* struct_,
	EnumBackingType enumBackingType,
	Type enumType,
	in CommonTypes commonTypes,
) =>
	basicFunDecl(
		FunDeclSource(struct_),
		struct_.visibility,
		sym!"to",
		Type(getBackingTypeFromEnumType(enumBackingType, commonTypes)),
		makeParams(alloc, [param!"a"(enumType)]),
		FunFlags.generatedBare.withOkIfUnused(),
		FunBody(EnumFunction.toIntegral));

StructInst* getBackingTypeFromEnumType(EnumBackingType a, ref CommonTypes commonTypes) {
	IntegralTypes integrals = commonTypes.integrals;
	final switch (a) {
		case EnumBackingType.int8:
			return integrals.int8;
		case EnumBackingType.int16:
			return integrals.int16;
		case EnumBackingType.int32:
			return integrals.int32;
		case EnumBackingType.int64:
			return integrals.int64;
		case EnumBackingType.nat8:
			return integrals.nat8;
		case EnumBackingType.nat16:
			return integrals.nat16;
		case EnumBackingType.nat32:
			return integrals.nat32;
		case EnumBackingType.nat64:
			return integrals.nat64;
	}
}

FunDecl enumOrFlagsMembersFunction(
	ref Alloc alloc,
	ref ProgramState programState,
	StructDecl* struct_,
	Sym name,
	Type enumType,
	ref CommonTypes commonTypes,
) =>
	basicFunDecl(
		FunDeclSource(struct_),
		struct_.visibility,
		name,
		Type(makeArrayType(
			alloc,
			programState,
			commonTypes,
			makeTupleType(alloc, programState, commonTypes, [Type(commonTypes.symbol), enumType]))),
		Params([]),
		FunFlags.generatedBare.withOkIfUnused(),
		FunBody(EnumFunction.members));

FunDecl flagsUnionOrIntersectFunction(ref Alloc alloc, StructDecl* struct_, Type enumType, Sym name, EnumFunction fn) =>
	basicFunDecl(
		FunDeclSource(struct_),
		struct_.visibility,
		name,
		enumType,
		makeParams(alloc, [param!"a"(enumType), param!"b"(enumType)]),
		FunFlags.generatedBare.withOkIfUnused(),
		FunBody(fn));

void addFunsForRecord(
	ref CheckCtx ctx,
	ref ExactSizeArrBuilder!FunDecl funsBuilder,
	ref CommonTypes commonTypes,
	StructDecl* struct_,
	ref StructBody.Record record,
) {
	TypeParam[] typeParams = struct_.typeParams;
	scope TypeArgsArray typeArgs = typeArgsArray();
	foreach (ref TypeParam p; typeParams)
		push(typeArgs, Type(&p));
	Type structType = Type(
		instantiateStructNeverDelay(ctx.alloc, ctx.programState, struct_, tempAsArr(typeArgs)));
	bool byVal = recordIsAlwaysByVal(record);
	addFunsForRecordConstructor(ctx, funsBuilder, commonTypes, struct_, record, structType, byVal);
	foreach (size_t fieldIndex, ref RecordField field; record.fields)
		addFunsForRecordField(ctx, funsBuilder, commonTypes, struct_, structType, byVal, fieldIndex, field);
}

void addFunsForRecordConstructor(
	ref CheckCtx ctx,
	ref ExactSizeArrBuilder!FunDecl funsBuilder,
	ref CommonTypes commonTypes,
	StructDecl* struct_,
	ref StructBody.Record record,
	Type structType,
	bool byVal,
) {
	exactSizeArrBuilderAdd(funsBuilder, funDeclWithBody(
		FunDeclSource(struct_),
		record.flags.newVisibility,
		sym!"new",
		struct_.typeParams,
		structType,
		Params(map(ctx.alloc, record.fields, (ref RecordField x) =>
			makeParam(ctx.alloc, x.name, x.type))),
		byVal ? FunFlags.generatedBare : FunFlags.generated,
		[],
		FunBody(FunBody.CreateRecord())));
}

void addFunsForRecordField(
	ref CheckCtx ctx,
	ref ExactSizeArrBuilder!FunDecl funsBuilder,
	ref CommonTypes commonTypes,
	StructDecl* struct_,
	Type structType,
	bool recordIsByVal,
	size_t fieldIndex,
	ref RecordField field,
) {
	Visibility fieldVisibility = leastVisibility(struct_.visibility, field.visibility);
	exactSizeArrBuilderAdd(funsBuilder, funDeclWithBody(
		FunDeclSource(struct_),
		fieldVisibility,
		field.name,
		struct_.typeParams,
		field.type,
		makeParams(ctx.alloc, [param!"a"(structType)]),
		FunFlags.generatedBare,
		[],
		FunBody(FunBody.RecordFieldGet(fieldIndex))));

	void addRecordFieldPointer(Visibility visibility, Type recordPointer, Type fieldPointer) {
		exactSizeArrBuilderAdd(funsBuilder, funDeclWithBody(
			FunDeclSource(struct_),
			visibility,
			field.name,
			struct_.typeParams,
			fieldPointer,
			makeParams(ctx.alloc, [param!"a"(recordPointer)]),
			FunFlags.generatedBareUnsafe,
			[],
			FunBody(FunBody.RecordFieldPointer(fieldIndex))));
	}

	if (recordIsByVal)
		addRecordFieldPointer(
			fieldVisibility,
			Type(makeConstPointerType(ctx.alloc, ctx.programState, commonTypes, structType)),
			Type(makeConstPointerType(ctx.alloc, ctx.programState, commonTypes, field.type)));

	Opt!Visibility mutVisibility = visibilityOfFieldMutability(field.mutability);
	if (has(mutVisibility)) {
		Visibility setVisibility = leastVisibility(struct_.visibility, force(mutVisibility));
		Type recordMutPointer = Type(makeMutPointerType(ctx.alloc, ctx.programState, commonTypes, structType));
		if (recordIsByVal) {
			exactSizeArrBuilderAdd(funsBuilder, funDeclWithBody(
				FunDeclSource(struct_),
				setVisibility,
				prependSetDeref(ctx.allSymbols, field.name),
				struct_.typeParams,
				Type(commonTypes.void_),
				makeParams(ctx.alloc, [
					param!"a"(recordMutPointer),
					ParamShort(field.name, field.type),
				]),
				FunFlags.generatedBareUnsafe,
				[],
				FunBody(FunBody.RecordFieldSet(fieldIndex))));
			addRecordFieldPointer(
				setVisibility,
				recordMutPointer,
				Type(makeMutPointerType(ctx.alloc, ctx.programState, commonTypes, field.type)));
		} else
			exactSizeArrBuilderAdd(funsBuilder, funDeclWithBody(
				FunDeclSource(struct_),
				setVisibility,
				prependSet(ctx.allSymbols, field.name),
				struct_.typeParams,
				Type(commonTypes.void_),
				makeParams(ctx.alloc, [param!"a"(structType), ParamShort(field.name, field.type)]),
				FunFlags.generatedBare,
				[],
				FunBody(FunBody.RecordFieldSet(fieldIndex))));
	}
}

Opt!Visibility visibilityOfFieldMutability(FieldMutability a) {
	final switch (a) {
		case FieldMutability.const_:
			return none!Visibility;
		case FieldMutability.private_:
			return some(Visibility.private_);
		case FieldMutability.public_:
			return some(Visibility.public_);
	}
}

void addFunsForUnion(
	ref CheckCtx ctx,
	ref ExactSizeArrBuilder!FunDecl funsBuilder,
	in CommonTypes commonTypes,
	StructDecl* struct_,
	ref StructBody.Union union_,
) {
	TypeParam[] typeParams = struct_.typeParams;
	scope TypeArgsArray typeArgs = typeArgsArray();
	foreach (ref TypeParam x; typeParams)
		push(typeArgs, Type(&x));
	Type structType = Type(instantiateStructNeverDelay(ctx.alloc, ctx.programState, struct_, tempAsArr(typeArgs)));
	foreach (size_t memberIndex, ref UnionMember member; union_.members) {
		Params params = isVoid(commonTypes, member.type)
			? Params([])
			: makeParams(ctx.alloc, [param!"a"(member.type)]);
		exactSizeArrBuilderAdd(funsBuilder, funDeclWithBody(
			FunDeclSource(struct_),
			struct_.visibility,
			member.name,
			typeParams,
			structType,
			params,
			FunFlags.generatedBare,
			[],
			FunBody(FunBody.CreateUnion(memberIndex))));
	}
}

bool isVoid(in CommonTypes commonTypes, Type a) =>
	a.isA!(StructInst*) && a.as!(StructInst*) == commonTypes.void_;
