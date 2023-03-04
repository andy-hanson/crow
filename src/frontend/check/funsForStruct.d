module frontend.check.funsForStruct;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : CheckCtx;
import frontend.check.getCommonFuns : makeParam, makeParams, param, ParamShort;
import frontend.check.instantiate :
	instantiateStructNeverDelay, makeArrayType, makeConstPointerType, makeMutPointerType, TypeArgsArray, typeArgsArray;
import frontend.check.typeFromAst : makeTupleType;
import frontend.programState : ProgramState;
import model.model :
	body_,
	CommonTypes,
	Destructure,
	EnumBackingType,
	EnumFunction,
	FieldMutability,
	FlagsFunction,
	ForcedByValOrRefOrNone,
	FunBody,
	FunDecl,
	FunFlags,
	IntegralTypes,
	leastVisibility,
	name,
	Params,
	range,
	RecordField,
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
import util.col.arr : empty, ptrsRange;
import util.col.arrUtil : count, map, sum;
import util.col.exactSizeArrBuilder : ExactSizeArrBuilder, exactSizeArrBuilderAdd;
import util.col.mutMaxArr : push, tempAsArr;
import util.col.str : safeCStr;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : FileAndPos, fileAndPosFromFileAndRange, FileAndRange;
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
		(in StructBody.Record it) {
			bool byVal = recordIsAlwaysByVal(it);
			size_t nConstructors = byVal ? 1 : 2;
			size_t nMutableFields = count!RecordField(it.fields, (in RecordField field) =>
				field.mutability != FieldMutability.const_);
			return nConstructors + it.fields.length * (byVal ? 2 : 1) + nMutableFields * (byVal ? 2 : 1);
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
	ref ExactSizeArrBuilder!FunDecl funsBuilder,
	ref CommonTypes commonTypes,
	VarDecl* var,
) {
	exactSizeArrBuilderAdd(funsBuilder, FunDecl(
		safeCStr!"",
		var.visibility,
		var.pos,
		var.name,
		[],
		var.type,
		Params([]),
		FunFlags.generatedNoCtxUnsafe,
		[],
		FunBody(FunBody.VarGet(var))));
	exactSizeArrBuilderAdd(funsBuilder, FunDecl(
		safeCStr!"",
		var.visibility,
		var.pos,
		prependSet(ctx.allSymbols, var.name),
		[],
		Type(commonTypes.void_),
		makeParams(ctx.alloc, var.range, [param!"a"(var.type)]),
		FunFlags.generatedNoCtxUnsafe,
		[],
		FunBody(FunBody.VarSet(var))));
}

private:

FunDecl newExtern(ref Alloc alloc, ref ProgramState programState, StructDecl* struct_) =>
	FunDecl(
		safeCStr!"",
		struct_.visibility,
		fileAndPosFromFileAndRange(struct_.range),
		sym!"new",
		[],
		Type(instantiateNonTemplateStructDeclNeverDelay(alloc, programState, struct_)),
		Params([]),
		FunFlags.generatedNoCtxUnsafe,
		[],
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
	FileAndRange range = struct_.range;
	addEnumFlagsCommonFunctions(
		ctx.alloc, funsBuilder, ctx.programState, visibility, range, enumType, enum_.backingType, commonTypes,
		sym!"enum-members");
	foreach (ref StructBody.Enum.Member member; enum_.members)
		exactSizeArrBuilderAdd(funsBuilder, enumOrFlagsConstructor(ctx.alloc, visibility, enumType, member));
}

void addFunsForFlags(
	ref CheckCtx ctx,
	ref ExactSizeArrBuilder!FunDecl funsBuilder,
	ref CommonTypes commonTypes,
	StructDecl* struct_,
	ref StructBody.Flags flags,
) {
	Type type = Type(instantiateNonTemplateStructDeclNeverDelay(ctx.alloc, ctx.programState, struct_));
	Visibility visibility = struct_.visibility;
	FileAndRange range = struct_.range;
	addEnumFlagsCommonFunctions(
		ctx.alloc, funsBuilder, ctx.programState, visibility, range, type, flags.backingType, commonTypes,
		sym!"flags-members");
	exactSizeArrBuilderAdd(funsBuilder, flagsNewFunction(ctx.alloc, visibility, range, type));
	exactSizeArrBuilderAdd(funsBuilder, flagsAllFunction(ctx.alloc, visibility, range, type));
	exactSizeArrBuilderAdd(funsBuilder, flagsNegateFunction(ctx.alloc, visibility, range, type));
	exactSizeArrBuilderAdd(funsBuilder, flagsUnionOrIntersectFunction(
		ctx.alloc, visibility, range, type, sym!"|", EnumFunction.union_));
	exactSizeArrBuilderAdd(funsBuilder, flagsUnionOrIntersectFunction(
		ctx.alloc, visibility, range, type, sym!"&", EnumFunction.intersect));

	foreach (ref StructBody.Enum.Member member; flags.members)
		exactSizeArrBuilderAdd(funsBuilder, enumOrFlagsConstructor(ctx.alloc, visibility, type, member));
}

void addEnumFlagsCommonFunctions(
	ref Alloc alloc,
	ref ExactSizeArrBuilder!FunDecl funsBuilder,
	ref ProgramState programState,
	Visibility visibility,
	FileAndRange range,
	Type type,
	EnumBackingType backingType,
	ref CommonTypes commonTypes,
	Sym membersName,
) {
	exactSizeArrBuilderAdd(funsBuilder, enumEqualFunction(alloc, visibility, range, type, commonTypes));
	exactSizeArrBuilderAdd(
		funsBuilder,
		enumToIntegralFunction(alloc, visibility, range, backingType, type, commonTypes));
	exactSizeArrBuilderAdd(
		funsBuilder,
		enumOrFlagsMembersFunction(alloc, programState, visibility, range, membersName, type, commonTypes));
}

FunDecl enumOrFlagsConstructor(
	ref Alloc alloc,
	Visibility visibility,
	Type enumType,
	ref StructBody.Enum.Member member,
) =>
	FunDecl(
		safeCStr!"",
		visibility,
		fileAndPosFromFileAndRange(member.range),
		member.name,
		[],
		enumType,
		Params([]),
		FunFlags.generatedNoCtx,
		[],
		FunBody(FunBody.CreateEnum(member.value)));

FunDecl enumEqualFunction(
	ref Alloc alloc,
	Visibility visibility,
	FileAndRange fileAndRange,
	Type enumType,
	in CommonTypes commonTypes,
) =>
	FunDecl(
		safeCStr!"",
		visibility,
		fileAndPosFromFileAndRange(fileAndRange),
		sym!"==",
		[],
		Type(commonTypes.bool_),
		makeParams(alloc, fileAndRange, [param!"a"(enumType), param!"b"(enumType)]),
		FunFlags.generatedNoCtx.withOkIfUnused(),
		[],
		FunBody(EnumFunction.equal));

FunDecl flagsNewFunction(ref Alloc alloc, Visibility visibility, FileAndRange fileAndRange, Type enumType) =>
	FunDecl(
		safeCStr!"",
		visibility,
		fileAndPosFromFileAndRange(fileAndRange),
		sym!"new",
		[],
		enumType,
		Params([]),
		FunFlags.generatedNoCtx.withOkIfUnused(),
		[],
		FunBody(FlagsFunction.new_));

FunDecl flagsAllFunction(ref Alloc alloc, Visibility visibility, FileAndRange fileAndRange, Type enumType) =>
	FunDecl(
		safeCStr!"",
		visibility,
		fileAndPosFromFileAndRange(fileAndRange),
		sym!"all",
		[],
		enumType,
		Params([]),
		FunFlags.generatedNoCtx.withOkIfUnused(),
		[],
		FunBody(FlagsFunction.all));

FunDecl flagsNegateFunction(ref Alloc alloc, Visibility visibility, FileAndRange fileAndRange, Type enumType) =>
	FunDecl(
		safeCStr!"",
		visibility,
		fileAndPosFromFileAndRange(fileAndRange),
		sym!"~",
		[],
		enumType,
		makeParams(alloc, fileAndRange, [param!"a"(enumType)]),
		FunFlags.generatedNoCtx.withOkIfUnused(),
		[],
		FunBody(FlagsFunction.negate));

FunDecl enumToIntegralFunction(
	ref Alloc alloc,
	Visibility visibility,
	FileAndRange fileAndRange,
	EnumBackingType enumBackingType,
	Type enumType,
	in CommonTypes commonTypes,
) =>
	FunDecl(
		safeCStr!"",
		visibility,
		fileAndPosFromFileAndRange(fileAndRange),
		sym!"to",
		[],
		Type(getBackingTypeFromEnumType(enumBackingType, commonTypes)),
		makeParams(alloc, fileAndRange, [param!"a"(enumType)]),
		FunFlags.generatedNoCtx.withOkIfUnused(),
		[],
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
	Visibility visibility,
	FileAndRange fileAndRange,
	Sym name,
	Type enumType,
	ref CommonTypes commonTypes,
) =>
	FunDecl(
		safeCStr!"",
		visibility,
		fileAndPosFromFileAndRange(fileAndRange),
		name,
		[],
		Type(makeArrayType(
			alloc,
			programState,
			commonTypes,
			makeTupleType(alloc, programState, commonTypes, [Type(commonTypes.symbol), enumType]))),
		Params([]),
		FunFlags.generatedNoCtx.withOkIfUnused(),
		[],
		FunBody(EnumFunction.members));

FunDecl flagsUnionOrIntersectFunction(
	ref Alloc alloc,
	Visibility visibility,
	FileAndRange fileAndRange,
	Type enumType,
	Sym name,
	EnumFunction fn,
) =>
	FunDecl(
		safeCStr!"",
		visibility,
		fileAndPosFromFileAndRange(fileAndRange),
		name,
		[],
		enumType,
		makeParams(alloc, fileAndRange, [param!"a"(enumType), param!"b"(enumType)]),
		FunFlags.generatedNoCtx.withOkIfUnused(),
		[],
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
	foreach (TypeParam* p; ptrsRange(typeParams))
		push(typeArgs, Type(p));
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
	Destructure[] params = map(ctx.alloc, record.fields, (ref RecordField it) =>
		makeParam(ctx.alloc, it.range, it.name, it.type));
	FunDecl constructor(Type returnType, FunFlags flags) {
		return FunDecl(
			safeCStr!"",
			record.flags.newVisibility,
			fileAndPosFromFileAndRange(struct_.range),
			sym!"new",
			struct_.typeParams,
			returnType,
			Params(params),
			flags.withOkIfUnused(),
			[],
			FunBody(FunBody.CreateRecord()));
	}

	if (byVal) {
		exactSizeArrBuilderAdd(funsBuilder, constructor(structType, FunFlags.generatedNoCtx));
	} else {
		exactSizeArrBuilderAdd(funsBuilder, constructor(structType, FunFlags.generatedPreferred));
		Type byValType = Type(
			instantiateStructNeverDelay(ctx.alloc, ctx.programState, commonTypes.byVal, [structType]));
		exactSizeArrBuilderAdd(funsBuilder, constructor(byValType, FunFlags.generatedNoCtx));
	}
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
	FileAndPos pos = fileAndPosFromFileAndRange(field.range);
	Visibility fieldVisibility = leastVisibility(struct_.visibility, field.visibility);
	exactSizeArrBuilderAdd(funsBuilder, FunDecl(
		safeCStr!"",
		fieldVisibility,
		pos,
		field.name,
		struct_.typeParams,
		field.type,
		makeParams(ctx.alloc, field.range, [param!"a"(structType)]),
		FunFlags.generatedNoCtx,
		[],
		FunBody(FunBody.RecordFieldGet(fieldIndex))));
	
	void addRecordFieldPointer(Visibility visibility, Type recordPointer, Type fieldPointer) {
		exactSizeArrBuilderAdd(funsBuilder, FunDecl(
			safeCStr!"",
			visibility,
			pos,
			field.name,
			struct_.typeParams,
			fieldPointer,
			makeParams(ctx.alloc, field.range, [param!"a"(recordPointer)]),
			FunFlags.generatedNoCtxUnsafe,
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
			exactSizeArrBuilderAdd(funsBuilder, FunDecl(
				safeCStr!"",
				setVisibility,
				pos,
				prependSetDeref(ctx.allSymbols, field.name),
				struct_.typeParams,
				Type(commonTypes.void_),
				makeParams(ctx.alloc, field.range, [
					param!"a"(recordMutPointer),
					ParamShort(field.name, field.type),
				]),
				FunFlags.generatedNoCtxUnsafe,
				[],
				FunBody(FunBody.RecordFieldSet(fieldIndex))));
			addRecordFieldPointer(
				setVisibility,
				recordMutPointer,
				Type(makeMutPointerType(ctx.alloc, ctx.programState, commonTypes, field.type)));
		} else
			exactSizeArrBuilderAdd(funsBuilder, FunDecl(
				safeCStr!"",
				setVisibility,
				pos,
				prependSet(ctx.allSymbols, field.name),
				struct_.typeParams,
				Type(commonTypes.void_),
				makeParams(ctx.alloc, field.range, [param!"a"(structType), ParamShort(field.name, field.type)]),
				FunFlags.generatedNoCtx,
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
	foreach (TypeParam* x; ptrsRange(typeParams))
		push(typeArgs, Type(x));
	Type structType = Type(instantiateStructNeverDelay(ctx.alloc, ctx.programState, struct_, tempAsArr(typeArgs)));
	foreach (size_t memberIndex, ref UnionMember member; union_.members) {
		Params params = isVoid(commonTypes, member.type)
			? Params([])
			: makeParams(ctx.alloc, member.range, [param!"a"(member.type)]);
		exactSizeArrBuilderAdd(funsBuilder, FunDecl(
			safeCStr!"",
			struct_.visibility,
			fileAndPosFromFileAndRange(member.range),
			member.name,
			typeParams,
			structType,
			params,
			FunFlags.generatedNoCtx,
			[],
			FunBody(FunBody.CreateUnion(memberIndex))));
	}
}

bool isVoid(in CommonTypes commonTypes, Type a) =>
	a.isA!(StructInst*) && a.as!(StructInst*) == commonTypes.void_;
