module frontend.check.checkStructBodies;

@safe @nogc pure nothrow:

import frontend.check.checkCtx :
	addDiag,
	addDiagAssertSameUri,
	CheckCtx,
	checkNoTypeParams,
	visibilityFromDefaultWithDiag,
	visibilityFromExplicitTopLevel;
import frontend.check.instantiate : DelayStructInsts;
import frontend.check.maps : StructsAndAliasesMap;
import frontend.check.typeFromAst : checkTypeParams, typeFromAst;
import model.ast :
	EnumMemberAst,
	LiteralIntAst,
	LiteralNatAst,
	LiteralNatAndRange,
	ModifierAst,
	ModifierKeyword,
	RecordFieldAst,
	StructBodyAst,
	StructDeclAst,
	TypeAst,
	UnionMemberAst,
	VisibilityAndRange;
import model.concreteModel : TypeSize;
import model.diag : Diag, DeclKind, TypeContainer, TypeWithContainer;
import model.model :
	BuiltinType,
	ByValOrRef,
	CommonTypes,
	emptyTypeParams,
	EnumBackingType,
	EnumMember,
	EnumValue,
	IntegralTypes,
	isLinkagePossiblyCompatible,
	isPurityPossiblyCompatible,
	leastVisibility,
	Linkage,
	linkageRange,
	nameRange,
	Purity,
	purityRange,
	RecordField,
	RecordFlags,
	StructBody,
	StructDecl,
	StructDeclSource,
	StructInst,
	Type,
	TypeParamIndex,
	UnionMember,
	Visibility;
import util.col.array : eachPair, fold, mapPointers, zipPtrFirst;
import util.conv : safeToUint;
import util.opt : force, has, MutOpt, none, noneMut, Opt, some, someMut;
import util.sourceRange : Range;
import util.symbol : Symbol, symbol;
import util.util : enumConvertOrAssert, isMultipleOf, ptrTrustMe;

StructDecl[] checkStructsInitial(ref CheckCtx ctx, in StructDeclAst[] asts) =>
	mapPointers!(StructDecl, StructDeclAst)(ctx.alloc, asts, (StructDeclAst* ast) {
		checkTypeParams(ctx, ast.typeParams);
		LinkageAndPurity p = getStructModifiers(ctx, getDeclKind(ast.body_), ast.modifiers);
		return StructDecl(
			StructDeclSource(ast),
			ctx.curUri,
			ast.name.name,
			visibilityFromExplicitTopLevel(ast.visibility),
			p.linkage,
			p.purityAndForced.purity,
			p.purityAndForced.forced);
	});

void checkStructBodies(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesMap structsAndAliasesMap,
	ref StructDecl[] structs,
	in StructDeclAst[] asts,
	scope ref DelayStructInsts delayStructInsts,
) {
	zipPtrFirst!(StructDecl, StructDeclAst)(structs, asts, (StructDecl* struct_, ref StructDeclAst ast) {
		struct_.body_ = ast.body_.matchIn!StructBody(
			(in StructBodyAst.Builtin) {
				checkOnlyStructModifiers(ctx, DeclKind.builtin, ast.modifiers);
				return StructBody(getBuiltinType(ctx, struct_));
			},
			(in StructBodyAst.Enum x) {
				checkNoTypeParams(ctx, ast.typeParams, DeclKind.enum_);
				checkOnlyStructModifiers(ctx, DeclKind.enum_, ast.modifiers);
				return StructBody(checkEnum(
					ctx, commonTypes, structsAndAliasesMap, struct_, ast.range, x, delayStructInsts));
			},
			(in StructBodyAst.Extern it) =>
				StructBody(checkExtern(ctx, commonTypes, struct_, ast, it)),
			(in StructBodyAst.Flags x) {
				checkNoTypeParams(ctx, ast.typeParams, DeclKind.flags);
				checkOnlyStructModifiers(ctx, DeclKind.flags, ast.modifiers);
				return StructBody(checkFlags(
					ctx, commonTypes, structsAndAliasesMap, struct_, ast.range, x, delayStructInsts));
			},
			(in StructBodyAst.Record x) =>
				StructBody(checkRecord(
					ctx, commonTypes, structsAndAliasesMap, struct_, ast.modifiers, x, delayStructInsts)),
			(in StructBodyAst.Union x) {
				checkOnlyStructModifiers(ctx, DeclKind.union_, ast.modifiers);
				return StructBody(checkUnion(ctx, commonTypes, structsAndAliasesMap, struct_, x, delayStructInsts));
			});
	});
}

private:

StructBody.Extern checkExtern(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	StructDecl* struct_,
	in StructDeclAst declAst,
	in StructBodyAst.Extern bodyAst,
) {
	checkNoTypeParams(ctx, declAst.typeParams, DeclKind.extern_);
	checkOnlyStructModifiers(ctx, DeclKind.extern_, declAst.modifiers);
	return StructBody.Extern(getExternTypeSize(ctx, commonTypes, TypeContainer(struct_), declAst, bodyAst));
}

Opt!TypeSize getExternTypeSize(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	TypeContainer container,
	in StructDeclAst declAst,
	in StructBodyAst.Extern bodyAst,
) {
	if (has(bodyAst.size)) {
		uint size = getSizeValue(ctx, commonTypes, container, *force(bodyAst.size));
		uint default_ = defaultAlignment(size);
		uint alignment = () {
			if (has(bodyAst.alignment)) {
				uint alignment = getSizeValue(ctx, commonTypes, container, *force(bodyAst.alignment));
				if (isValidAlignment(alignment)) {
					if (alignment == default_)
						addDiag(ctx, force(bodyAst.alignment).range, Diag(
							Diag.ExternTypeError(Diag.ExternTypeError.Reason.alignmentIsDefault)));
					return alignment;
				} else {
					addDiag(ctx, force(bodyAst.alignment).range, Diag(
						Diag.ExternTypeError(Diag.ExternTypeError.Reason.badAlignment)));
					return default_;
				}
			} else
				return default_;
		}();
		return some(TypeSize(size, alignment));
	} else {
		assert(!has(bodyAst.alignment));
		return none!TypeSize;
	}
}

uint getSizeValue(ref CheckCtx ctx, ref CommonTypes commonTypes, TypeContainer container, in LiteralNatAndRange ast) {
	if (ast.nat.overflow || ast.nat.value > uint.max) {
		addDiag(ctx, ast.range, Diag(
			Diag.LiteralOverflow(TypeWithContainer(Type(commonTypes.integrals.nat32), container))));
		return 0;
	} else
		return safeToUint(ast.nat.value);
}

bool isValidAlignment(uint alignment) {
	switch (alignment) {
		case 1:
		case 2:
		case 4:
		case 8:
			return true;
		default:
			return false;
	}
}

uint defaultAlignment(size_t size) =>
	size == 0 ? 0 :
	isMultipleOf(size, 8) ? 8 :
	isMultipleOf(size, 4) ? 4 :
	isMultipleOf(size, 2) ? 2 :
	1;

immutable struct LinkageAndPurity {
	Linkage linkage;
	PurityAndForced purityAndForced;
}

immutable struct PurityAndForced {
	Purity purity;
	bool forced;
}

// Note: purity is taken for granted here, and verified later when we check the body.
LinkageAndPurity getStructModifiers(ref CheckCtx ctx, DeclKind declKind, ModifierAst[] modifiers) {
	LinkageAndPurityModifiers accum = accumulateStructModifiers(ctx, modifiers);
	Linkage linkage = () {
		Linkage defaultLinkage = defaultLinkage(declKind);
		if (has(accum.linkage)) {
			ModifierAst.Keyword* keyword = force(accum.linkage);
			assert(keyword.kind == ModifierKeyword.extern_);
			if (defaultLinkage == Linkage.extern_)
				addDiag(ctx, keyword.range, Diag(Diag.ModifierRedundantDueToDeclKind(keyword.kind, declKind)));
			return Linkage.extern_;
		} else
			return defaultLinkage;
	}();
	PurityAndForced purity = () {
		Purity defaultPurity = defaultPurity(declKind);
		if (has(accum.purityAndForced)) {
			ModifierAst.Keyword* keyword = force(accum.purityAndForced);
			Opt!PurityAndForced opt = purityAndForcedFromModifier(keyword.kind);
			PurityAndForced pf = force(opt);
			if (pf.purity == defaultPurity)
				addDiag(ctx, keyword.range, Diag(Diag.ModifierRedundantDueToDeclKind(keyword.kind, declKind)));
			return pf;
		} else
			return PurityAndForced(defaultPurity, false);
	}();
	return LinkageAndPurity(linkage, purity);
}

struct LinkageAndPurityModifiers {
	MutOpt!(ModifierAst.Keyword*) linkage;
	MutOpt!(ModifierAst.Keyword*) purityAndForced;
}
LinkageAndPurityModifiers accumulateStructModifiers(ref CheckCtx ctx, ModifierAst[] modifiers) {
	LinkageAndPurityModifiers cur = LinkageAndPurityModifiers();
	foreach (ref ModifierAst modifier; modifiers) {
		if (isStructModifier(modifier)) {
			ModifierAst.Keyword* kw = &modifier.as!(ModifierAst.Keyword)();
			accumulateModifier(ctx, kw.kind == ModifierKeyword.extern_ ? cur.linkage : cur.purityAndForced, kw);
		} // else already warned in 'checkOnlyStructModifiers'
	}
	return cur;
}

Linkage defaultLinkage(DeclKind a) {
	final switch (a) {
		case DeclKind.builtin:
		case DeclKind.enum_:
		case DeclKind.flags:
		case DeclKind.record:
		case DeclKind.union_:
			return Linkage.internal;
		case DeclKind.extern_:
			return Linkage.extern_;
		case DeclKind.alias_:
		case DeclKind.externFunction:
		case DeclKind.function_:
		case DeclKind.global:
		case DeclKind.spec:
		case DeclKind.test:
		case DeclKind.threadLocal:
			assert(false);
	}
}

Purity defaultPurity(DeclKind a) {
	final switch (a) {
		case DeclKind.builtin:
		case DeclKind.enum_:
		case DeclKind.flags:
		case DeclKind.record:
		case DeclKind.union_:
			return Purity.data;
		case DeclKind.extern_:
			return Purity.mut;
		case DeclKind.alias_:
		case DeclKind.externFunction:
		case DeclKind.function_:
		case DeclKind.global:
		case DeclKind.test:
		case DeclKind.spec:
		case DeclKind.threadLocal:
			assert(false);
	}
}

DeclKind getDeclKind(in StructBodyAst a) =>
	a.matchIn!DeclKind(
		(in StructBodyAst.Builtin) =>
			DeclKind.builtin,
		(in StructBodyAst.Enum) =>
			DeclKind.enum_,
		(in StructBodyAst.Extern) =>
			DeclKind.extern_,
		(in StructBodyAst.Flags) =>
			DeclKind.flags,
		(in StructBodyAst.Record) =>
			DeclKind.record,
		(in StructBodyAst.Union) =>
			DeclKind.union_);

Opt!PurityAndForced purityAndForcedFromModifier(ModifierKeyword a) {
	switch (a) {
		case ModifierKeyword.data:
			return some(PurityAndForced(Purity.data, false));
		case ModifierKeyword.forceShared:
			return some(PurityAndForced(Purity.shared_, true));
		case ModifierKeyword.mut:
			return some(PurityAndForced(Purity.mut, false));
		case ModifierKeyword.shared_:
			return some(PurityAndForced(Purity.shared_, false));
		default:
			return none!PurityAndForced;
	}
}

void checkOnlyStructModifiers(ref CheckCtx ctx, DeclKind declKind, in ModifierAst[] modifiers) {
	foreach (ref ModifierAst modifier; modifiers)
		if (!isStructModifier(modifier))
			addDiag(ctx, modifier.range(ctx.allSymbols), modifier.match!Diag(
				(ModifierAst.Keyword x) =>
					x.kind == ModifierKeyword.byVal
						? Diag(Diag.ModifierRedundantDueToDeclKind(x.kind, declKind))
						: Diag(Diag.ModifierInvalid(x.kind, declKind)),
				(ModifierAst.Extern) =>
					Diag(Diag.ExternHasUnnecessaryLibraryName()),
				(TypeAst x) =>
					Diag(Diag.SpecUseInvalid(declKind))));
}

bool isStructModifier(in ModifierAst a) =>
	a.matchIn!bool(
		(in ModifierAst.Keyword x) =>
			x.kind == ModifierKeyword.extern_ || has(purityAndForcedFromModifier(x.kind)),
		(in ModifierAst.Extern) =>
			false,
		(in TypeAst _) =>
			false);

StructBody.Enum checkEnum(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesMap structsAndAliasesMap,
	StructDecl* struct_,
	in Range range,
	in StructBodyAst.Enum e,
	scope ref DelayStructInsts delayStructInsts,
) {
	EnumOrFlagsTypeAndMembers tm = checkEnumOrFlagsMembers(
		ctx, commonTypes, structsAndAliasesMap, struct_, range, e.typeArg, e.members, delayStructInsts,
		Diag.DuplicateDeclaration.Kind.enumMember,
		(Opt!EnumValue lastValue, EnumBackingType enumType) =>
			has(lastValue)
				? ValueAndOverflow(EnumValue(force(lastValue).value + 1), force(lastValue) == maxValue(enumType))
				: ValueAndOverflow(EnumValue(0), false));
	return StructBody.Enum(tm.backingType, tm.members);
}

StructBody.Flags checkFlags(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesMap structsAndAliasesMap,
	StructDecl* struct_,
	in Range range,
	in StructBodyAst.Flags f,
	scope ref DelayStructInsts delayStructInsts,
) {
	EnumOrFlagsTypeAndMembers tm = checkEnumOrFlagsMembers(
		ctx, commonTypes, structsAndAliasesMap, struct_, range, f.typeArg, f.members, delayStructInsts,
		Diag.DuplicateDeclaration.Kind.flagsMember,
		(Opt!EnumValue lastValue, EnumBackingType enumType) =>
			has(lastValue)
				? ValueAndOverflow(
					//TODO: if the last value isn't a power of 2, there should be a diagnostic
					EnumValue(force(lastValue).value * 2),
					force(lastValue).value >= maxValue(enumType).value / 2)
				: ValueAndOverflow(EnumValue(1), false));
	return StructBody.Flags(tm.backingType, tm.members);
}

immutable struct EnumOrFlagsTypeAndMembers {
	EnumBackingType backingType;
	EnumMember[] members;
}

immutable struct ValueAndOverflow {
	EnumValue value;
	bool overflow;
}

EnumOrFlagsTypeAndMembers checkEnumOrFlagsMembers(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesMap structsAndAliasesMap,
	StructDecl* struct_,
	in Range range,
	in Opt!(TypeAst*) typeArg,
	in EnumMemberAst[] memberAsts,
	scope ref DelayStructInsts delayStructInsts,
	Diag.DuplicateDeclaration.Kind memberKind,
	in ValueAndOverflow delegate(Opt!EnumValue, EnumBackingType) @safe @nogc pure nothrow cbGetNextValue,
) {
	Type implementationType = has(typeArg)
		? typeFromAst(
			ctx, commonTypes, *force(typeArg), structsAndAliasesMap, emptyTypeParams,
			someMut(ptrTrustMe(delayStructInsts)))
		: Type(commonTypes.integrals.nat32);
	EnumBackingType enumType = getEnumTypeFromType(ctx, struct_, range, commonTypes, implementationType);

	MutOpt!long lastValue = noneMut!long;
	bool anyOverflow = false;
	EnumMember[] members = mapPointers(ctx.alloc, memberAsts, (EnumMemberAst* memberAst) {
		ValueAndOverflow valueAndOverflow = () {
			if (has(memberAst.value))
				return isSignedEnumBackingType(enumType)
					? force(memberAst.value).kind.matchIn!ValueAndOverflow(
						(in LiteralIntAst i) =>
							ValueAndOverflow(EnumValue(i.value), i.overflow),
						(in LiteralNatAst n) =>
							ValueAndOverflow(EnumValue(n.value), n.value > long.max))
					: force(memberAst.value).kind.matchIn!ValueAndOverflow(
						(in LiteralIntAst _) =>
							ValueAndOverflow(EnumValue(0), true),
						(in LiteralNatAst n) =>
							ValueAndOverflow(EnumValue(n.value), n.overflow));
			else
				return cbGetNextValue(has(lastValue) ? some(EnumValue(force(lastValue))) : none!EnumValue, enumType);
		}();
		EnumValue value = valueAndOverflow.value;
		if (valueAndOverflow.overflow || valueOverflows(enumType, value)) {
			anyOverflow = true;
			addDiag(ctx, memberAst.range, Diag(Diag.EnumMemberOverflows(enumType)));
		}
		lastValue = someMut!long(value.value);
		return EnumMember(memberAst, struct_, memberAst.name, value);
	});

	eachPair!(EnumMember)(members, (in EnumMember a, in EnumMember b) {
		if (a.name == b.name)
			addDiag(ctx, b.range, Diag(Diag.DuplicateDeclaration(memberKind, b.name)));
		if (a.value == b.value && !anyOverflow)
			addDiag(ctx, b.range, Diag(Diag.EnumDuplicateValue(isSignedEnumBackingType(enumType), b.value.value)));
	});
	return EnumOrFlagsTypeAndMembers(enumType, members);
}

bool valueOverflows(EnumBackingType type, EnumValue value) {
	long v = value.value;
	final switch (type) {
		case EnumBackingType.int8:
			return v < byte.min || v > byte.max;
		case EnumBackingType.int16:
			return v < short.min || v > short.max;
		case EnumBackingType.int32:
			return v < int.min || v > int.max;
		case EnumBackingType.int64:
			return false;
		case EnumBackingType.nat8:
			return v < 0 || v > ubyte.max;
		case EnumBackingType.nat16:
			return v < 0 || v > ushort.max;
		case EnumBackingType.nat32:
			return v < 0 || v > uint.max;
		// For unsigned types, any negative 'value' is actually a wrapped-around large nat.
		case EnumBackingType.nat64:
			return false;
	}
}

EnumValue maxValue(EnumBackingType type) =>
	EnumValue(() {
		final switch (type) {
			case EnumBackingType.int8: return byte.max;
			case EnumBackingType.int16: return short.max;
			case EnumBackingType.int32: return int.max;
			case EnumBackingType.int64: return long.max;
			case EnumBackingType.nat8: return ubyte.max;
			case EnumBackingType.nat16: return ushort.max;
			case EnumBackingType.nat32: return uint.max;
			case EnumBackingType.nat64: return ulong.max;
		}
	}());

bool isSignedEnumBackingType(EnumBackingType a) {
	final switch (a) {
		case EnumBackingType.int8:
		case EnumBackingType.int16:
		case EnumBackingType.int32:
		case EnumBackingType.int64:
			return true;
		case EnumBackingType.nat8:
		case EnumBackingType.nat16:
		case EnumBackingType.nat32:
		case EnumBackingType.nat64:
			return false;
	}
}

EnumBackingType defaultEnumBackingType() =>
	EnumBackingType.nat32;

EnumBackingType getEnumTypeFromType(
	ref CheckCtx ctx,
	StructDecl* struct_,
	in Range range,
	in CommonTypes commonTypes,
	in Type type,
) {
	IntegralTypes integrals = commonTypes.integrals;
	return type.matchWithPointers!EnumBackingType(
		(Type.Bogus) =>
			defaultEnumBackingType(),
		(TypeParamIndex _) =>
			// enums can't have type params
			assert(false),
		(StructInst* x) =>
			x == integrals.int8
				? EnumBackingType.int8
				: x == integrals.int16
				? EnumBackingType.int16
				: x == integrals.int32
				? EnumBackingType.int32
				: x == integrals.int64
				? EnumBackingType.int64
				: x == integrals.nat8
				? EnumBackingType.nat8
				: x == integrals.nat16
				? EnumBackingType.nat16
				: x == integrals.nat32
				? EnumBackingType.nat32
				: x == integrals.nat64
				? EnumBackingType.nat64
				: (() {
					addDiag(ctx, range, Diag(Diag.EnumBackingTypeInvalid(struct_, Type(x))));
					return defaultEnumBackingType();
				})());
}

StructBody.Record checkRecord(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesMap structsAndAliasesMap,
	StructDecl* struct_,
	ModifierAst[] modifierAsts,
	in StructBodyAst.Record r,
	scope ref DelayStructInsts delayStructInsts,
) {
	RecordModifiers modifiers = accumulateRecordModifiers(ctx, modifierAsts);
	bool isExtern = struct_.linkage != Linkage.internal;
	Opt!ByValOrRef valOrRef = isExtern
		? some(ByValOrRef.byVal)
		: has(modifiers.byValOrRef)
		? some(enumConvertOrAssert!ByValOrRef(force(modifiers.byValOrRef).kind))
		: none!ByValOrRef;
	if (isExtern && has(modifiers.byValOrRef))
		addDiag(ctx, force(modifiers.byValOrRef).range, Diag(Diag.ExternRecordImplicitlyByVal(struct_)));
	RecordField[] fields = mapPointers!(RecordField, RecordFieldAst)(ctx.alloc, r.fields, (RecordFieldAst* field) =>
		checkRecordField(ctx, commonTypes, structsAndAliasesMap, delayStructInsts, struct_, field));
	eachPair!RecordField(fields, (in RecordField a, in RecordField b) {
		if (a.name == b.name)
			addDiag(ctx, b.range, Diag(Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.recordField, a.name)));
	});
	return StructBody.Record(
		RecordFlags(recordNewVisibility(ctx, struct_, fields, modifiers), has(modifiers.packed), valOrRef),
		fields);
}

RecordField checkRecordField(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesMap structsAndAliasesMap,
	scope ref DelayStructInsts delayStructInsts,
	StructDecl* record,
	RecordFieldAst* ast,
) {
	Type fieldType = typeFromAst(
		ctx, commonTypes, ast.type, structsAndAliasesMap, record.typeParams, someMut(ptrTrustMe(delayStructInsts)));
	checkReferenceLinkageAndPurity(ctx, record, ast.range, fieldType);
	if (has(ast.mutability) && record.purity != Purity.mut && !record.purityIsForced)
		addDiag(ctx, ast.range, Diag(Diag.MutFieldNotAllowed()));
	Symbol name = ast.name.name;
	Visibility visibility = visibilityFromDefaultWithDiag(ctx, record.visibility, ast.visibility,
		Diag.VisibilityWarning.Kind(Diag.VisibilityWarning.Kind.Field(record, name)));
	Opt!Visibility mutability = has(ast.mutability)
		? some(visibilityFromDefaultWithDiag(
			ctx, visibility, force(ast.mutability).visibility,
			Diag.VisibilityWarning.Kind(Diag.VisibilityWarning.Kind.FieldMutability(name))))
		: none!Visibility;
	return RecordField(ast, record, visibility, name, mutability, fieldType);
}

StructBody.Union checkUnion(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesMap structsAndAliasesMap,
	StructDecl* struct_,
	in StructBodyAst.Union ast,
	scope ref DelayStructInsts delayStructInsts,
) {
	final switch (struct_.linkage) {
		case Linkage.internal:
			break;
		case Linkage.extern_:
			addDiagAssertSameUri(ctx, struct_.range, Diag(Diag.ExternUnion()));
	}
	UnionMember[] members = mapPointers(ctx.alloc, ast.members, (UnionMemberAst* memberAst) =>
		checkUnionMember(ctx, commonTypes, structsAndAliasesMap, delayStructInsts, struct_, memberAst));
	eachPair!UnionMember(members, (in UnionMember a, in UnionMember b) {
		if (a.name == b.name)
			addDiag(ctx, b.range, Diag(Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.unionMember, a.name)));
	});
	return StructBody.Union(members);
}

UnionMember checkUnionMember(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesMap structsAndAliasesMap,
	scope ref DelayStructInsts delayStructInsts,
	StructDecl* struct_,
	UnionMemberAst* ast,
) {
	Type type = !has(ast.type)
		? Type(commonTypes.void_)
		: typeFromAst(
			ctx,
			commonTypes,
			force(ast.type),
			structsAndAliasesMap,
			struct_.typeParams,
			someMut(ptrTrustMe(delayStructInsts)));
	checkReferencePurity(ctx, struct_, ast.range, type);
	return UnionMember(ast, struct_, ast.name, type);
}

struct RecordModifiers {
	MutOpt!(ModifierAst.Keyword*) byValOrRef;
	MutOpt!(ModifierAst.Keyword*) newVisibility;
	MutOpt!(ModifierAst.Keyword*) packed;
}

void accumulateModifier(ref CheckCtx ctx, ref MutOpt!(ModifierAst.Keyword*) old, ModifierAst.Keyword* new_) {
	if (has(old)) {
		ModifierKeyword oldKeyword = force(old).kind;
		addDiag(ctx, new_.range, new_.kind == oldKeyword
			? Diag(Diag.ModifierDuplicate(new_.kind))
			: Diag(Diag.ModifierConflict(oldKeyword, new_.kind)));
	}
	old = someMut(new_);
}

RecordModifiers accumulateRecordModifiers(ref CheckCtx ctx, ModifierAst[] modifiers) {
	RecordModifiers res = RecordModifiers();
	foreach (ref ModifierAst modifier; modifiers) {
		Range range() => modifier.range(ctx.allSymbols);
		modifier.match!void(
			(ModifierAst.Keyword x) {
				ModifierAst.Keyword* ptr = &modifier.as!(ModifierAst.Keyword)();
				switch (x.kind) {
					case ModifierKeyword.byRef:
					case ModifierKeyword.byVal:
						accumulateModifier(ctx, res.byValOrRef, ptr);
						break;
					case ModifierKeyword.newInternal:
					case ModifierKeyword.newPrivate:
					case ModifierKeyword.newPublic:
						accumulateModifier(ctx, res.newVisibility, ptr);
						break;
					case ModifierKeyword.packed:
						accumulateModifier(ctx, res.packed, ptr);
						break;
					case ModifierKeyword.data:
					case ModifierKeyword.extern_:
					case ModifierKeyword.forceShared:
					case ModifierKeyword.mut:
					case ModifierKeyword.shared_:
						// already handled in getStructModifiers
						assert(isStructModifier(modifier));
						break;
					default:
						addDiag(ctx, range(), Diag(Diag.ModifierInvalid(x.kind, DeclKind.record)));
						break;
				}
			},
			(ModifierAst.Extern) {
				addDiag(ctx, range(), Diag(Diag.ExternHasUnnecessaryLibraryName()));
			},
			(TypeAst) {
				addDiag(ctx, range(), Diag(Diag.SpecUseInvalid(DeclKind.record)));
			});
	}
	return res;
}

void checkReferenceLinkageAndPurity(ref CheckCtx ctx, StructDecl* struct_, in Range range, Type referencedType) {
	if (!isLinkagePossiblyCompatible(struct_.linkage, linkageRange(referencedType)))
		addDiag(ctx, range, Diag(Diag.LinkageWorseThanContainingType(struct_, referencedType)));
	checkReferencePurity(ctx, struct_, range, referencedType);
}

void checkReferencePurity(ref CheckCtx ctx, StructDecl* struct_, in Range range, Type referencedType) {
	if (!isPurityPossiblyCompatible(struct_.purity, purityRange(referencedType)) &&
		!struct_.purityIsForced)
		addDiag(ctx, range, Diag(Diag.PurityWorseThanParent(struct_, referencedType)));
}

Visibility recordNewVisibility(
	ref CheckCtx ctx,
	StructDecl* record,
	in RecordField[] fields,
	in RecordModifiers modifiers,
) {
	Visibility default_ = fold!(Visibility, RecordField)(
		record.visibility, fields, (Visibility cur, in RecordField field) =>
			leastVisibility(cur, field.visibility));
	Opt!VisibilityAndRange explicit = has(modifiers.newVisibility)
		? some(VisibilityAndRange(
			visibilityFromNewVisibility(force(modifiers.newVisibility).kind),
			force(modifiers.newVisibility).pos))
		: none!VisibilityAndRange;
	return visibilityFromDefaultWithDiag(ctx, default_, explicit, Diag.VisibilityWarning.Kind(
		Diag.VisibilityWarning.Kind.New(record)));
}

Visibility visibilityFromNewVisibility(ModifierKeyword a) {
	switch (a) {
		case ModifierKeyword.newPrivate:
			return Visibility.private_;
		case ModifierKeyword.newInternal:
			return Visibility.internal;
		case ModifierKeyword.newPublic:
			return Visibility.public_;
		default:
			assert(false);
	}
}

BuiltinType getBuiltinType(scope ref CheckCtx ctx, StructDecl* struct_) {
	switch (struct_.name.value) {
		case symbol!"bool".value:
			return BuiltinType.bool_;
		case symbol!"char8".value:
			return BuiltinType.char8;
		case symbol!"float32".value:
			return BuiltinType.float32;
		case symbol!"float64".value:
			return BuiltinType.float64;
		case symbol!"fun-act".value:
		case symbol!"fun-fun".value:
			return BuiltinType.funOrAct;
		case symbol!"fun-pointer".value:
			return BuiltinType.funPointer;
		case symbol!"int8".value:
			return BuiltinType.int8;
		case symbol!"int16".value:
			return BuiltinType.int16;
		case symbol!"int32".value:
			return BuiltinType.int32;
		case symbol!"int64".value:
			return BuiltinType.int64;
		case symbol!"nat8".value:
			return BuiltinType.nat8;
		case symbol!"nat16".value:
			return BuiltinType.nat16;
		case symbol!"nat32".value:
			return BuiltinType.nat32;
		case symbol!"nat64".value:
			return BuiltinType.nat64;
		case symbol!"const-pointer".value:
			return BuiltinType.pointerConst;
		case symbol!"mut-pointer".value:
			return BuiltinType.pointerMut;
		case symbol!"void".value:
			return BuiltinType.void_;
		default:
			addDiagAssertSameUri(ctx, struct_.nameRange(ctx.allSymbols), Diag(
				Diag.BuiltinUnsupported(Diag.BuiltinUnsupported.Kind.type, struct_.name)));
			return BuiltinType.void_;
	}
}
