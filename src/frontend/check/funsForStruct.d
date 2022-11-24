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
	matchStructBody,
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

immutable(size_t) countFunsForStruct(immutable StructDecl[] structs) =>
	sum!StructDecl(structs, (ref immutable StructDecl s) =>
		matchStructBody!(immutable size_t)(
			body_(s),
			(ref immutable StructBody.Bogus) =>
				immutable size_t(0),
			(ref immutable StructBody.Builtin) =>
				immutable size_t(0),
			(ref immutable StructBody.Enum it) =>
				// '==', 'to-intXX'/'to-natXX', 'enum-members', and a constructor for each member
				3 + it.members.length,
			(ref immutable StructBody.Extern x) =>
				immutable size_t(has(x.size) ? 1 : 0),
			(ref immutable StructBody.Flags it) =>
				// '()', 'all', '==', '~', '|', '&', 'to-intXX'/'to-natXX', 'flags-members',
				// and a constructor for each member
				8 + it.members.length,
			(ref immutable StructBody.Record it) {
				immutable size_t nConstructors = recordIsAlwaysByVal(it) ? 1 : 2;
				immutable size_t nMutableFields = count!RecordField(it.fields, (ref immutable RecordField field) =>
					field.mutability != FieldMutability.const_);
				return nConstructors + it.fields.length + nMutableFields;
			},
			(ref immutable StructBody.Union it) =>
				it.members.length));

void addFunsForStruct(
	ref CheckCtx ctx,
	ref ExactSizeArrBuilder!FunDecl funsBuilder,
	ref immutable CommonTypes commonTypes,
	immutable StructDecl* struct_,
) {
	matchStructBody!void(
		body_(*struct_),
		(ref immutable StructBody.Bogus) {},
		(ref immutable StructBody.Builtin) {},
		(ref immutable StructBody.Enum it) {
			addFunsForEnum(ctx, funsBuilder, commonTypes, struct_, it);
		},
		(ref immutable StructBody.Extern x) {
			if (has(x.size)) {
				exactSizeArrBuilderAdd(funsBuilder, newExtern(ctx.alloc, ctx.programState, struct_));
			}
		},
		(ref immutable StructBody.Flags it) {
			addFunsForFlags(ctx, funsBuilder, commonTypes, struct_, it);
		},
		(ref immutable StructBody.Record it) {
			addFunsForRecord(ctx, funsBuilder, commonTypes, struct_, it);
		},
		(ref immutable StructBody.Union it) {
			addFunsForUnion(ctx, funsBuilder, commonTypes, struct_, it);
		});
}

private:

immutable(FunDecl) newExtern(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable StructDecl* struct_,
) =>
	FunDecl(
		safeCStr!"",
		struct_.visibility,
		fileAndPosFromFileAndRange(struct_.range),
		sym!"new",
		[],
		immutable Type(instantiateNonTemplateStructDeclNeverDelay(alloc, programState, struct_)),
		immutable Params([]),
		FunFlags.generatedNoCtxUnsafe,
		[],
		immutable FunBody(immutable FunBody.CreateExtern()));

immutable(StructInst*) instantiateNonTemplateStructDeclNeverDelay(
	ref Alloc alloc,
	ref ProgramState programState,
	immutable StructDecl* structDecl,
) =>
	instantiateStructNeverDelay(alloc, programState, structDecl, []);

immutable(bool) recordIsAlwaysByVal(ref immutable StructBody.Record record) =>
	empty(record.fields) || record.flags.forcedByValOrRef == ForcedByValOrRefOrNone.byVal;

void addFunsForEnum(
	ref CheckCtx ctx,
	ref ExactSizeArrBuilder!FunDecl funsBuilder,
	ref immutable CommonTypes commonTypes,
	immutable StructDecl* struct_,
	ref immutable StructBody.Enum enum_,
) {
	immutable Type enumType =
		immutable Type(instantiateNonTemplateStructDeclNeverDelay(ctx.alloc, ctx.programState, struct_));
	immutable Visibility visibility = struct_.visibility;
	immutable FileAndRange range = struct_.range;
	addEnumFlagsCommonFunctions(
		ctx.alloc, funsBuilder, ctx.programState, visibility, range, enumType, enum_.backingType, commonTypes,
		sym!"enum-members");
	foreach (ref immutable StructBody.Enum.Member member; enum_.members)
		exactSizeArrBuilderAdd(funsBuilder, enumOrFlagsConstructor(ctx.alloc, visibility, enumType, member));
}

void addFunsForFlags(
	ref CheckCtx ctx,
	ref ExactSizeArrBuilder!FunDecl funsBuilder,
	ref immutable CommonTypes commonTypes,
	immutable StructDecl* struct_,
	ref immutable StructBody.Flags flags,
) {
	immutable Type type =
		immutable Type(instantiateNonTemplateStructDeclNeverDelay(ctx.alloc, ctx.programState, struct_));
	immutable Visibility visibility = struct_.visibility;
	immutable FileAndRange range = struct_.range;
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

	foreach (ref immutable StructBody.Enum.Member member; flags.members)
		exactSizeArrBuilderAdd(funsBuilder, enumOrFlagsConstructor(ctx.alloc, visibility, type, member));
}

void addEnumFlagsCommonFunctions(
	ref Alloc alloc,
	ref ExactSizeArrBuilder!FunDecl funsBuilder,
	ref ProgramState programState,
	immutable Visibility visibility,
	immutable FileAndRange range,
	immutable Type type,
	immutable EnumBackingType backingType,
	ref immutable CommonTypes commonTypes,
	immutable Sym membersName,
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
	immutable Visibility visibility,
	immutable Type enumType,
	ref immutable StructBody.Enum.Member member,
) =>
	FunDecl(
		safeCStr!"",
		visibility,
		fileAndPosFromFileAndRange(member.range),
		member.name,
		[],
		enumType,
		immutable Params([]),
		FunFlags.generatedNoCtx,
		[],
		immutable FunBody(immutable FunBody.CreateEnum(member.value)));

FunDecl enumEqualFunction(
	ref Alloc alloc,
	immutable Visibility visibility,
	immutable FileAndRange fileAndRange,
	immutable Type enumType,
	ref immutable CommonTypes commonTypes,
) =>
	FunDecl(
		safeCStr!"",
		visibility,
		fileAndPosFromFileAndRange(fileAndRange),
		sym!"==",
		[],
		immutable Type(commonTypes.bool_),
		immutable Params(arrLiteral!Param(alloc, [
			immutable Param(fileAndRange, some(sym!"a"), enumType, 0),
			immutable Param(fileAndRange, some(sym!"b"), enumType, 1)])),
		FunFlags.generatedNoCtx.withOkIfUnused(),
		[],
		immutable FunBody(EnumFunction.equal));

FunDecl flagsNewFunction(
	ref Alloc alloc,
	immutable Visibility visibility,
	immutable FileAndRange fileAndRange,
	immutable Type enumType,
) =>
	FunDecl(
		safeCStr!"",
		visibility,
		fileAndPosFromFileAndRange(fileAndRange),
		sym!"new",
		[],
		enumType,
		immutable Params([]),
		FunFlags.generatedNoCtx.withOkIfUnused(),
		[],
		immutable FunBody(FlagsFunction.new_));

FunDecl flagsAllFunction(
	ref Alloc alloc,
	immutable Visibility visibility,
	immutable FileAndRange fileAndRange,
	immutable Type enumType,
) =>
	FunDecl(
		safeCStr!"",
		visibility,
		fileAndPosFromFileAndRange(fileAndRange),
		sym!"all",
		[],
		enumType,
		immutable Params([]),
		FunFlags.generatedNoCtx.withOkIfUnused(),
		[],
		immutable FunBody(FlagsFunction.all));

FunDecl flagsNegateFunction(
	ref Alloc alloc,
	immutable Visibility visibility,
	immutable FileAndRange fileAndRange,
	immutable Type enumType,
) =>
	FunDecl(
		safeCStr!"",
		visibility,
		fileAndPosFromFileAndRange(fileAndRange),
		sym!"~",
		[],
		enumType,
		immutable Params(arrLiteral!Param(alloc, [
			immutable Param(fileAndRange, some(sym!"a"), enumType, 0)])),
		FunFlags.generatedNoCtx.withOkIfUnused(),
		[],
		immutable FunBody(FlagsFunction.negate));

FunDecl enumToIntegralFunction(
	ref Alloc alloc,
	immutable Visibility visibility,
	immutable FileAndRange fileAndRange,
	immutable EnumBackingType enumBackingType,
	immutable Type enumType,
	ref immutable CommonTypes commonTypes,
) =>
	FunDecl(
		safeCStr!"",
		visibility,
		fileAndPosFromFileAndRange(fileAndRange),
		enumToIntegralName(enumBackingType),
		[],
		immutable Type(getBackingTypeFromEnumType(enumBackingType, commonTypes)),
		immutable Params(arrLiteral!Param(alloc, [
			immutable Param(fileAndRange, some(sym!"a"), enumType, 0)])),
		FunFlags.generatedNoCtx.withOkIfUnused(),
		[],
		immutable FunBody(EnumFunction.toIntegral));

immutable(StructInst*) getBackingTypeFromEnumType(
	immutable EnumBackingType a,
	ref immutable CommonTypes commonTypes,
) {
	immutable IntegralTypes integrals = commonTypes.integrals;
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
	immutable Visibility visibility,
	immutable FileAndRange fileAndRange,
	immutable Sym name,
	immutable Type enumType,
	ref immutable CommonTypes commonTypes,
) =>
	FunDecl(
		safeCStr!"",
		visibility,
		fileAndPosFromFileAndRange(fileAndRange),
		name,
		[],
		immutable Type(makeArrayType(
			alloc,
			programState,
			commonTypes,
			immutable Type(makeNamedValType(alloc, programState, commonTypes, enumType)))),
		immutable Params([]),
		FunFlags.generatedNoCtx.withOkIfUnused(),
		[],
		immutable FunBody(EnumFunction.members));

FunDecl flagsUnionOrIntersectFunction(
	ref Alloc alloc,
	immutable Visibility visibility,
	immutable FileAndRange fileAndRange,
	immutable Type enumType,
	immutable Sym name,
	immutable EnumFunction fn,
) =>
	FunDecl(
		safeCStr!"",
		visibility,
		fileAndPosFromFileAndRange(fileAndRange),
		name,
		[],
		enumType,
		immutable Params(arrLiteral!Param(alloc, [
			immutable Param(fileAndRange, some(sym!"a"), enumType, 0),
			immutable Param(fileAndRange, some(sym!"b"), enumType, 0)])),
		FunFlags.generatedNoCtx.withOkIfUnused(),
		[],
		immutable FunBody(fn));

//TODO: actually, we should record the type name used,
//so if they had 'e enum<size_t>' we should have 'to-size_t' not 'to-nat64'
immutable(Sym) enumToIntegralName(immutable EnumBackingType a) {
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
	ref immutable CommonTypes commonTypes,
	immutable StructDecl* struct_,
	ref immutable StructBody.Record record,
) {
	immutable TypeParam[] typeParams = struct_.typeParams;
	scope TypeArgsArray typeArgs = typeArgsArray();
	foreach (immutable TypeParam* p; ptrsRange(typeParams))
		push(typeArgs, immutable Type(p));
	immutable Type structType = immutable Type(
		instantiateStructNeverDelay(ctx.alloc, ctx.programState, struct_, tempAsArr(typeArgs)));
	immutable Param[] ctorParams = map(ctx.alloc, record.fields, (ref immutable RecordField it) =>
		immutable Param(it.range, some(it.name), it.type, it.index));
	immutable(FunDecl) constructor(immutable Type returnType, immutable FunFlags flags) =>
		FunDecl(
			safeCStr!"",
			record.flags.newVisibility,
			fileAndPosFromFileAndRange(struct_.range),
			sym!"new",
			typeParams,
			returnType,
			immutable Params(ctorParams),
			flags.withOkIfUnused(),
			[],
			immutable FunBody(immutable FunBody.CreateRecord()));

	if (recordIsAlwaysByVal(record)) {
		exactSizeArrBuilderAdd(funsBuilder, constructor(structType, FunFlags.generatedNoCtx));
	} else {
		exactSizeArrBuilderAdd(funsBuilder, constructor(structType, FunFlags.generatedPreferred));
		immutable Type byValType = immutable Type(
			instantiateStructNeverDelay(ctx.alloc, ctx.programState, commonTypes.byVal, [structType]));
		exactSizeArrBuilderAdd(funsBuilder, constructor(byValType, FunFlags.generatedNoCtx));
	}

	foreach (immutable size_t fieldIndex, ref immutable RecordField field; record.fields) {
		immutable Visibility fieldVisibility = leastVisibility(struct_.visibility, field.visibility);
		exactSizeArrBuilderAdd(funsBuilder, FunDecl(
			safeCStr!"",
			fieldVisibility,
			fileAndPosFromFileAndRange(field.range),
			field.name,
			typeParams,
			field.type,
			immutable Params(arrLiteral!Param(ctx.alloc, [
				immutable Param(field.range, some(sym!"a"), structType, 0)])),
			FunFlags.generatedNoCtx,
			[],
			immutable FunBody(immutable FunBody.RecordFieldGet(fieldIndex))));

		immutable Opt!Visibility mutVisibility = visibilityOfFieldMutability(field.mutability);
		if (has(mutVisibility))
			exactSizeArrBuilderAdd(funsBuilder, FunDecl(
				safeCStr!"",
				force(mutVisibility),
				fileAndPosFromFileAndRange(field.range),
				prependSet(ctx.allSymbols, field.name),
				typeParams,
				immutable Type(commonTypes.void_),
				immutable Params(arrLiteral!Param(ctx.alloc, [
					immutable Param(field.range, some(sym!"a"), structType, 0),
					immutable Param(field.range, some(field.name), field.type, 1)])),
				FunFlags.generatedNoCtx,
				[],
				immutable FunBody(immutable FunBody.RecordFieldSet(fieldIndex))));
	}
}

immutable(Opt!Visibility) visibilityOfFieldMutability(immutable FieldMutability a) {
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
	ref immutable CommonTypes commonTypes,
	immutable StructDecl* struct_,
	ref immutable StructBody.Union union_,
) {
	immutable TypeParam[] typeParams = struct_.typeParams;
	scope TypeArgsArray typeArgs = typeArgsArray();
	foreach (immutable TypeParam* x; ptrsRange(typeParams))
		push(typeArgs, immutable Type(x));
	immutable Type structType = immutable Type(
		instantiateStructNeverDelay(ctx.alloc, ctx.programState, struct_, tempAsArr(typeArgs)));
	foreach (immutable size_t memberIndex, ref immutable UnionMember member; union_.members) {
		immutable Param[] params = has(member.type)
			? arrLiteral!Param(ctx.alloc, [
				immutable Param(member.range, some(sym!"a"), force(member.type), 0)])
			: [];
		exactSizeArrBuilderAdd(funsBuilder, FunDecl(
			safeCStr!"",
			struct_.visibility,
			fileAndPosFromFileAndRange(member.range),
			member.name,
			typeParams,
			structType,
			immutable Params(params),
			FunFlags.generatedNoCtx,
			[],
			immutable FunBody(immutable FunBody.CreateUnion(memberIndex))));
	}
}
