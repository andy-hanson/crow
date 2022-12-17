module frontend.check.funsForStruct;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : CheckCtx;
import frontend.check.instantiate :
	instantiateStructNeverDelay, makeArrayType, makeNamedValType, TypeArgsArray, typeArgsArray;
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
	FunFlags,
	IntegralTypes,
	leastVisibility,
	name,
	Param,
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
	Visibility,
	visibility;
import util.alloc.alloc : Alloc;
import util.col.arr : empty, ptrsRange;
import util.col.arrUtil : arrLiteral, count, map, sum;
import util.col.exactSizeArrBuilder : ExactSizeArrBuilder, exactSizeArrBuilderAdd;
import util.col.mutMaxArr : push, tempAsArr;
import util.col.str : safeCStr;
import util.opt : force, has, none, Opt, some;
import util.sourceRange : fileAndPosFromFileAndRange, FileAndRange;
import util.sym : prependSet, Sym, sym;

size_t countFunsForStruct(in StructDecl[] structs) =>
	sum!StructDecl(structs, (in StructDecl s) =>
		body_(s).matchIn!size_t(
			(in StructBody.Bogus) =>
				0,
			(in StructBody.Builtin) =>
				0,
			(in StructBody.Enum it) =>
				// '==', 'to-intXX'/'to-natXX', 'enum-members', and a constructor for each member
				3 + it.members.length,
			(in StructBody.Extern x) =>
				size_t(has(x.size) ? 1 : 0),
			(in StructBody.Flags it) =>
				// '()', 'all', '==', '~', '|', '&', 'to-intXX'/'to-natXX', 'flags-members',
				// and a constructor for each member
				8 + it.members.length,
			(in StructBody.Record it) {
				size_t nConstructors = recordIsAlwaysByVal(it) ? 1 : 2;
				size_t nMutableFields = count!RecordField(it.fields, (in RecordField field) =>
					field.mutability != FieldMutability.const_);
				return nConstructors + it.fields.length + nMutableFields;
			},
			(in StructBody.Union it) =>
				it.members.length));

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
		Params(arrLiteral!Param(alloc, [
			Param(fileAndRange, some(sym!"a"), enumType, 0),
			Param(fileAndRange, some(sym!"b"), enumType, 1)])),
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
		Params(arrLiteral!Param(alloc, [Param(fileAndRange, some(sym!"a"), enumType, 0)])),
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
		enumToIntegralName(enumBackingType),
		[],
		Type(getBackingTypeFromEnumType(enumBackingType, commonTypes)),
		Params(arrLiteral!Param(alloc, [Param(fileAndRange, some(sym!"a"), enumType, 0)])),
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
			Type(makeNamedValType(alloc, programState, commonTypes, enumType)))),
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
		Params(arrLiteral!Param(alloc, [
			Param(fileAndRange, some(sym!"a"), enumType, 0),
			Param(fileAndRange, some(sym!"b"), enumType, 0)])),
		FunFlags.generatedNoCtx.withOkIfUnused(),
		[],
		FunBody(fn));

//TODO: actually, we should record the type name used,
//so if they had 'e enum<size_t>' we should have 'to-size_t' not 'to-nat64'
Sym enumToIntegralName(EnumBackingType a) {
	final switch (a) {
		case EnumBackingType.int8:
			return sym!"to-int8";
		case EnumBackingType.int16:
			return sym!"to-int16";
		case EnumBackingType.int32:
			return sym!"to-int32";
		case EnumBackingType.int64:
			return sym!"to-int64";
		case EnumBackingType.nat8:
			return sym!"to-nat8";
		case EnumBackingType.nat16:
			return sym!"to-nat16";
		case EnumBackingType.nat32:
			return sym!"to-nat32";
		case EnumBackingType.nat64:
			return sym!"to-nat64";
	}
}

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
	Param[] ctorParams = map(ctx.alloc, record.fields, (ref RecordField it) =>
		Param(it.range, some(it.name), it.type, it.index));
	FunDecl constructor(Type returnType, FunFlags flags) {
		return FunDecl(
			safeCStr!"",
			record.flags.newVisibility,
			fileAndPosFromFileAndRange(struct_.range),
			sym!"new",
			typeParams,
			returnType,
			Params(ctorParams),
			flags.withOkIfUnused(),
			[],
			FunBody(FunBody.CreateRecord()));
	}

	if (recordIsAlwaysByVal(record)) {
		exactSizeArrBuilderAdd(funsBuilder, constructor(structType, FunFlags.generatedNoCtx));
	} else {
		exactSizeArrBuilderAdd(funsBuilder, constructor(structType, FunFlags.generatedPreferred));
		Type byValType = Type(
			instantiateStructNeverDelay(ctx.alloc, ctx.programState, commonTypes.byVal, [structType]));
		exactSizeArrBuilderAdd(funsBuilder, constructor(byValType, FunFlags.generatedNoCtx));
	}

	foreach (size_t fieldIndex, ref RecordField field; record.fields) {
		Visibility fieldVisibility = leastVisibility(struct_.visibility, field.visibility);
		exactSizeArrBuilderAdd(funsBuilder, FunDecl(
			safeCStr!"",
			fieldVisibility,
			fileAndPosFromFileAndRange(field.range),
			field.name,
			typeParams,
			field.type,
			Params(arrLiteral!Param(ctx.alloc, [Param(field.range, some(sym!"a"), structType, 0)])),
			FunFlags.generatedNoCtx,
			[],
			FunBody(FunBody.RecordFieldGet(fieldIndex))));

		Opt!Visibility mutVisibility = visibilityOfFieldMutability(field.mutability);
		if (has(mutVisibility))
			exactSizeArrBuilderAdd(funsBuilder, FunDecl(
				safeCStr!"",
				leastVisibility(struct_.visibility, force(mutVisibility)),
				fileAndPosFromFileAndRange(field.range),
				prependSet(ctx.allSymbols, field.name),
				typeParams,
				Type(commonTypes.void_),
				Params(arrLiteral!Param(ctx.alloc, [
					Param(field.range, some(sym!"a"), structType, 0),
					Param(field.range, some(field.name), field.type, 1)])),
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
		Param[] params = has(member.type)
			? arrLiteral(ctx.alloc, [Param(member.range, some(sym!"a"), force(member.type), 0)])
			: [];
		exactSizeArrBuilderAdd(funsBuilder, FunDecl(
			safeCStr!"",
			struct_.visibility,
			fileAndPosFromFileAndRange(member.range),
			member.name,
			typeParams,
			structType,
			Params(params),
			FunFlags.generatedNoCtx,
			[],
			FunBody(FunBody.CreateUnion(memberIndex))));
	}
}
