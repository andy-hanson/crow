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
	DestructureAst,
	EnumOrFlagsMemberAst,
	FieldMutabilityAst,
	LiteralIntAst,
	LiteralIntOrNat,
	LiteralNatAst,
	LiteralNatAndRange,
	ModifierAst,
	ModifierKeyword,
	NameAndRange,
	ParamsAst,
	RecordOrUnionMemberAst,
	SpecUseAst,
	StructBodyAst,
	StructDeclAst,
	TypeAst,
	VisibilityAndRange;
import model.concreteModel : TypeSize;
import model.diag : Diag, DeclKind, TypeContainer, TypeWithContainer;
import model.model :
	BuiltinType,
	ByValOrRef,
	CommonTypes,
	emptyTypeParams,
	EnumOrFlagsMember,
	EnumMemberSource,
	EnumValue,
	IntegralType,
	IntegralTypes,
	isLinkagePossiblyCompatible,
	isPurityPossiblyCompatible,
	leastVisibility,
	Linkage,
	linkageRange,
	maxValue,
	minValue,
	nameRange,
	Purity,
	purityRange,
	RecordField,
	RecordOrUnionMemberSource,
	RecordFlags,
	StructBody,
	StructDecl,
	StructDeclSource,
	StructInst,
	Type,
	TypeParamIndex,
	UnionMember,
	Visibility;
import util.col.array :
	eachPair, emptySmallArray, fold, isEmpty, mapOpPointers, mapPointers, small, SmallArray, zipPtrFirst;
import util.conv : safeToUint;
import util.opt : force, has, MutOpt, none, noneMut, Opt, optFromMut, some, someMut;
import util.sourceRange : Range;
import util.symbol : Symbol, symbol;
import util.util : enumConvertOrAssert, isMultipleOf, ptrTrustMe;

void modifierTypeArgInvalid(ref CheckCtx ctx, in ModifierAst.Keyword modifier) {
	if (has(modifier.typeArg)) {
		addDiag(ctx, modifier.range(ctx.allSymbols), Diag(Diag.ModifierTypeArgInvalid(modifier.keyword)));
	}
}
void modifierTypeArgInvalid(ref CheckCtx ctx, in MutOpt!(ModifierAst.Keyword*)[] modifiers) {
	foreach (const MutOpt!(ModifierAst.Keyword*) modifier; modifiers)
		if (has(modifier))
			modifierTypeArgInvalid(ctx, *force(modifier));
}


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
	scope ref DelayStructInsts delayStructInsts,
	ref StructDecl[] structs,
	in StructDeclAst[] asts,
) {
	zipPtrFirst!(StructDecl, StructDeclAst)(structs, asts, (StructDecl* struct_, ref StructDeclAst ast) {
		struct_.body_ = ast.body_.match!StructBody(
			(StructBodyAst.Builtin) {
				checkOnlyStructModifiers(ctx, DeclKind.builtin, ast.modifiers);
				return StructBody(getBuiltinType(ctx, struct_));
			},
			(StructBodyAst.Enum x) {
				checkNoTypeParams(ctx, ast.typeParams, DeclKind.enum_);
				IntegralType storage = checkEnumOrFlagsModifiers(
					ctx, commonTypes, structsAndAliasesMap, delayStructInsts, struct_, DeclKind.enum_, ast.modifiers);
				return StructBody(checkEnum(
					ctx, commonTypes, structsAndAliasesMap, delayStructInsts, struct_, ast.range, x, storage));
			},
			(StructBodyAst.Extern it) =>
				StructBody(checkExtern(ctx, commonTypes, struct_, ast, it)),
			(StructBodyAst.Flags x) {
				checkNoTypeParams(ctx, ast.typeParams, DeclKind.flags);
				IntegralType storage = checkEnumOrFlagsModifiers(
					ctx, commonTypes, structsAndAliasesMap, delayStructInsts, struct_, DeclKind.flags, ast.modifiers);
				return StructBody(checkFlags(
					ctx, commonTypes, structsAndAliasesMap, delayStructInsts, struct_, ast.range, x, storage));
			},
			(StructBodyAst.Record x) =>
				StructBody(checkRecord(
					ctx, commonTypes, structsAndAliasesMap, struct_, ast.modifiers, x, delayStructInsts)),
			(StructBodyAst.Union x) {
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
			ModifierAst.Keyword keyword = *force(accum.linkage);
			assert(keyword.keyword == ModifierKeyword.extern_);
			if (defaultLinkage == Linkage.extern_)
				addDiag(ctx, keyword.keywordRange, Diag(
					Diag.ModifierRedundantDueToDeclKind(keyword.keyword, declKind)));
			return Linkage.extern_;
		} else
			return defaultLinkage;
	}();
	PurityAndForced purity = () {
		Purity defaultPurity = defaultPurity(declKind);
		if (has(accum.purityAndForced)) {
			ModifierAst.Keyword keyword = *force(accum.purityAndForced);
			Opt!PurityAndForced opt = purityAndForcedFromModifier(keyword.keyword);
			PurityAndForced pf = force(opt);
			if (pf.purity == defaultPurity)
				addDiag(ctx, keyword.keywordRange, Diag(
					Diag.ModifierRedundantDueToDeclKind(keyword.keyword, declKind)));
			return pf;
		} else
			return PurityAndForced(defaultPurity, false);
	}();
	return LinkageAndPurity(linkage, purity);
}

immutable struct LinkageAndPurityModifiers {
	Opt!(ModifierAst.Keyword*) linkage;
	Opt!(ModifierAst.Keyword*) purityAndForced;
}
LinkageAndPurityModifiers accumulateStructModifiers(ref CheckCtx ctx, ModifierAst[] modifiers) {
	MutOpt!(ModifierAst.Keyword*) linkage;
	MutOpt!(ModifierAst.Keyword*) purityAndForced;
	foreach (ref ModifierAst modifier; modifiers) {
		if (isStructModifier(modifier)) {
			ModifierAst.Keyword* kw = &modifier.as!(ModifierAst.Keyword)();
			accumulateModifier(ctx, kw.keyword == ModifierKeyword.extern_ ? linkage : purityAndForced, kw);
		} // else already warned in 'checkOnlyStructModifiers'
	}
	modifierTypeArgInvalid(ctx, [linkage, purityAndForced]);
	return LinkageAndPurityModifiers(
		linkage: optFromMut!(ModifierAst.Keyword*)(linkage),
		purityAndForced: optFromMut!(ModifierAst.Keyword*)(purityAndForced));
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
			addDiag(ctx, modifier.range(ctx.allSymbols), modifier.matchIn!Diag(
				(in ModifierAst.Keyword x) =>
					x.keyword == ModifierKeyword.byVal
						? Diag(Diag.ModifierRedundantDueToDeclKind(x.keyword, declKind))
						: Diag(Diag.ModifierInvalid(x.keyword, declKind)),
				(in SpecUseAst _) =>
					Diag(Diag.SpecUseInvalid(declKind))));
}

bool isStructModifier(in ModifierAst a) =>
	a.matchIn!bool(
		(in ModifierAst.Keyword x) =>
			x.keyword == ModifierKeyword.extern_ || has(purityAndForcedFromModifier(x.keyword)),
		(in SpecUseAst _) =>
			false);

StructBody.Enum checkEnum(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesMap structsAndAliasesMap,
	scope ref DelayStructInsts delayStructInsts,
	StructDecl* struct_,
	in Range range,
	in StructBodyAst.Enum e,
	IntegralType storage,
) =>
	StructBody.Enum(storage, checkEnumOrFlagsMembers(
		ctx, commonTypes, structsAndAliasesMap, delayStructInsts,
		struct_, range, e.params, e.members, Diag.DuplicateDeclaration.Kind.enumMember, storage,
		(Opt!EnumValue lastValue) =>
			has(lastValue)
				? ValueAndOverflow(
					EnumValue(force(lastValue).value + 1),
					force(lastValue).asUnsigned() == maxValue(storage))
				: ValueAndOverflow(EnumValue(0), false)));

StructBody.Flags checkFlags(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesMap structsAndAliasesMap,
	scope ref DelayStructInsts delayStructInsts,
	StructDecl* struct_,
	in Range range,
	in StructBodyAst.Flags f,
	IntegralType storage,
) =>
	StructBody.Flags(storage, checkEnumOrFlagsMembers(
		ctx, commonTypes, structsAndAliasesMap, delayStructInsts,
		struct_, range, f.params, f.members, Diag.DuplicateDeclaration.Kind.flagsMember, storage,
		(Opt!EnumValue lastValue) =>
			has(lastValue)
				? ValueAndOverflow(
					//TODO: if the last value isn't a power of 2, there should be a diagnostic
					EnumValue(force(lastValue).value * 2),
					force(lastValue).value >= maxValue(storage) / 2)
				: ValueAndOverflow(EnumValue(1), false)));

immutable struct ValueAndOverflow {
	EnumValue value;
	bool overflow;
}

SmallArray!EnumOrFlagsMember checkEnumOrFlagsMembers(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesMap structsAndAliasesMap,
	scope ref DelayStructInsts delayStructInsts,
	StructDecl* struct_,
	in Range range,
	in Opt!ParamsAst paramsAst,
	in EnumOrFlagsMemberAst[] memberAsts,
	Diag.DuplicateDeclaration.Kind memberKind,
	IntegralType storage,
	in ValueAndOverflow delegate(Opt!EnumValue) @safe @nogc pure nothrow cbGetNextValue,
) {
	if (has(paramsAst) && !isEmpty(memberAsts)) {
		addDiag(ctx, struct_.nameRange(ctx.allSymbols).range, Diag(
			Diag.StructParamsSyntaxError(struct_, Diag.StructParamsSyntaxError.Reason.hasParamsAndFields)));
		return emptySmallArray!EnumOrFlagsMember;
	}

	MutOpt!long lastValue = noneMut!long;
	bool anyOverflow = false;

	scope CbEnumValue cbValue = (Range range, Opt!LiteralIntOrNat literal) {
		ValueAndOverflow valueAndOverflow = () {
			if (has(literal))
				return isSignedEnumBackingType(storage)
					? force(literal).kind.matchIn!ValueAndOverflow(
						(in LiteralIntAst i) =>
							ValueAndOverflow(EnumValue(i.value), i.overflow),
						(in LiteralNatAst n) =>
							ValueAndOverflow(EnumValue(n.value), n.value > long.max))
					: force(literal).kind.matchIn!ValueAndOverflow(
						(in LiteralIntAst _) =>
							ValueAndOverflow(EnumValue(0), true),
						(in LiteralNatAst n) =>
							ValueAndOverflow(EnumValue(n.value), n.overflow));
			else
				return cbGetNextValue(has(lastValue) ? some(EnumValue(force(lastValue))) : none!EnumValue);
		}();
		EnumValue value = valueAndOverflow.value;
		if (valueAndOverflow.overflow || valueOverflows(storage, value)) {
			anyOverflow = true;
			addDiag(ctx, range, Diag(Diag.EnumMemberOverflows(storage)));
		}
		lastValue = someMut!long(value.value);
		return value;
	};

	SmallArray!EnumOrFlagsMember members = has(paramsAst)
		? enumOrFlagsMembersFromParams(ctx, struct_, force(paramsAst), cbValue)
		: mapPointers(ctx.alloc, memberAsts, (EnumOrFlagsMemberAst* x) =>
			EnumOrFlagsMember(EnumMemberSource(x), struct_, x.name, cbValue(x.range, x.value)));
	eachPair!(EnumOrFlagsMember)(members, (in EnumOrFlagsMember a, in EnumOrFlagsMember b) {
		if (a.name == b.name)
			addDiag(ctx, b.nameRange(ctx.allSymbols).range, Diag(Diag.DuplicateDeclaration(memberKind, b.name)));
		if (a.value == b.value && !anyOverflow)
			addDiag(ctx, b.range(ctx.allSymbols), Diag(
				Diag.EnumDuplicateValue(isSignedEnumBackingType(storage), b.value.value)));
	});
	return members;
}

alias CbEnumValue = EnumValue delegate(Range range, Opt!LiteralIntOrNat) @safe @nogc pure nothrow;

SmallArray!EnumOrFlagsMember enumOrFlagsMembersFromParams(
	ref CheckCtx ctx,
	StructDecl* enumOrFlags,
	in ParamsAst params,
	in CbEnumValue cbValue,
) =>
	params.match!(SmallArray!EnumOrFlagsMember)(
		(DestructureAst[] destructures) =>
			small!EnumOrFlagsMember(mapOpPointers!(EnumOrFlagsMember, DestructureAst)(
				ctx.alloc, destructures, (DestructureAst* x) =>
					enumMemberFromParam(ctx, enumOrFlags, x, cbValue(x.range(ctx.allSymbols), none!LiteralIntOrNat)))),
		(ref ParamsAst.Varargs x) {
			addDiag(ctx, x.param.range(ctx.allSymbols), Diag(
				Diag.StructParamsSyntaxError(enumOrFlags, Diag.StructParamsSyntaxError.Reason.variadic)));
			return emptySmallArray!EnumOrFlagsMember;
		});

bool valueOverflows(IntegralType type, EnumValue value) =>
	isSignedEnumBackingType(type)
		? value.asSigned() < minValue(type) || value.asSigned() > cast(long) maxValue(type)
		: value.asUnsigned() > maxValue(type);

bool isSignedEnumBackingType(IntegralType a) {
	final switch (a) {
		case IntegralType.int8:
		case IntegralType.int16:
		case IntegralType.int32:
		case IntegralType.int64:
			return true;
		case IntegralType.nat8:
		case IntegralType.nat16:
		case IntegralType.nat32:
		case IntegralType.nat64:
			return false;
	}
}

IntegralType defaultEnumBackingType() =>
	IntegralType.nat32;

IntegralType getEnumTypeFromType(
	ref CheckCtx ctx,
	StructDecl* struct_,
	in Range range,
	in CommonTypes commonTypes,
	in Type type,
) {
	IntegralTypes integrals = commonTypes.integrals;
	return type.matchWithPointers!IntegralType(
		(Type.Bogus) =>
			defaultEnumBackingType(),
		(TypeParamIndex _) =>
			// enums can't have type params
			assert(false),
		(StructInst* x) =>
			x == integrals.int8
				? IntegralType.int8
				: x == integrals.int16
				? IntegralType.int16
				: x == integrals.int32
				? IntegralType.int32
				: x == integrals.int64
				? IntegralType.int64
				: x == integrals.nat8
				? IntegralType.nat8
				: x == integrals.nat16
				? IntegralType.nat16
				: x == integrals.nat32
				? IntegralType.nat32
				: x == integrals.nat64
				? IntegralType.nat64
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
	ref StructBodyAst.Record ast,
	scope ref DelayStructInsts delayStructInsts,
) {
	RecordModifiers modifiers = accumulateRecordModifiers(ctx, modifierAsts);
	bool isExtern = struct_.linkage != Linkage.internal;
	Opt!ByValOrRef valOrRef = isExtern
		? some(ByValOrRef.byVal)
		: has(modifiers.byValOrRef)
		? some(enumConvertOrAssert!ByValOrRef(force(modifiers.byValOrRef).keyword))
		: none!ByValOrRef;
	if (isExtern && has(modifiers.byValOrRef))
		addDiag(ctx, force(modifiers.byValOrRef).keywordRange, Diag(Diag.ExternRecordImplicitlyByVal(struct_)));

	SmallArray!RecordField fields = checkRecordOrUnionMembers!RecordField(
		ctx, struct_, ast.params, ast.fields, Diag.DuplicateDeclaration.Kind.recordField,
		(RecordOrUnionMemberAstCommon fieldAst) =>
			checkRecordField(ctx, commonTypes, structsAndAliasesMap, delayStructInsts, struct_, fieldAst));
	RecordFlags flags = RecordFlags(
		newVisibility: recordNewVisibility(ctx, struct_, fields, modifiers),
		nominal: has(modifiers.nominal),
		packed: has(modifiers.packed),
		forcedByValOrRef: valOrRef);
	return StructBody.Record(flags, fields);
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
	return StructBody.Union(checkRecordOrUnionMembers!UnionMember(
		ctx, struct_, ast.params, ast.members, Diag.DuplicateDeclaration.Kind.unionMember,
		(RecordOrUnionMemberAstCommon memberAst) =>
			checkUnionMember(ctx, commonTypes, structsAndAliasesMap, delayStructInsts, struct_, memberAst)));
}

// Shared in common between DestructureAst.Single and RecordOrUnionMemberAst
struct RecordOrUnionMemberAstCommon {
	RecordOrUnionMemberSource source;
	Opt!VisibilityAndRange visibility;
	NameAndRange name;
	Opt!FieldMutabilityAst mutability;
	Opt!TypeAst type;
}

alias CbCheckMember(Member) = Member delegate(RecordOrUnionMemberAstCommon) @safe @nogc pure nothrow;

SmallArray!Member checkRecordOrUnionMembers(Member)(
	ref CheckCtx ctx,
	StructDecl* struct_,
	Opt!ParamsAst params,
	SmallArray!RecordOrUnionMemberAst memberAsts,
	Diag.DuplicateDeclaration.Kind duplicateDeclarationKind,
	in CbCheckMember!Member cbCheckMember,
) {
	if (has(params) && !isEmpty(memberAsts))
		addDiag(ctx, struct_.nameRange(ctx.allSymbols).range, Diag(
			Diag.StructParamsSyntaxError(struct_, Diag.StructParamsSyntaxError.Reason.hasParamsAndFields)));
	SmallArray!Member res = has(params)
		? recordOrUnionMembersFromParams!Member(ctx, struct_, force(params), cbCheckMember)
		: small!Member(mapPointers!(Member, RecordOrUnionMemberAst)(
			ctx.alloc, memberAsts, (RecordOrUnionMemberAst* x) =>
				cbCheckMember(RecordOrUnionMemberAstCommon(
					RecordOrUnionMemberSource(x), x.visibility, x.name, x.mutability, x.type))));
	eachPair!Member(res, (in Member a, in Member b) {
		if (a.name == b.name)
			addDiag(ctx, b.range(ctx.allSymbols), Diag(Diag.DuplicateDeclaration(duplicateDeclarationKind, a.name)));
	});
	return res;
}

SmallArray!Member recordOrUnionMembersFromParams(Member)(
	ref CheckCtx ctx,
	StructDecl* struct_,
	ParamsAst ast,
	in CbCheckMember!Member cbCheckMember,
) =>
	ast.match!(SmallArray!Member)(
		(DestructureAst[] destructures) =>
			small!Member(mapOpPointers!(Member, DestructureAst)(
				ctx.alloc, destructures, (DestructureAst* param) =>
					recordOrUnionMemberFromParam!Member(ctx, struct_, param, cbCheckMember))),
		(ref ParamsAst.Varargs x) {
			addDiag(ctx, x.param.range(ctx.allSymbols), Diag(
				Diag.StructParamsSyntaxError(struct_, Diag.StructParamsSyntaxError.Reason.variadic)));
			return emptySmallArray!Member;
		});

Opt!EnumOrFlagsMember enumMemberFromParam(ref CheckCtx ctx, StructDecl* enum_, DestructureAst* ast, EnumValue value) {
	if (ast.isA!(DestructureAst.Single)) {
		DestructureAst.Single* single = &ast.as!(DestructureAst.Single)();
		if (has(single.mut)) {
			Opt!Range mutRange = single.mutRange;
			addDiag(ctx, force(mutRange), Diag(
				Diag.UnsupportedSyntax(Diag.UnsupportedSyntax.Reason.enumMemberMutability)));
		}
		if (has(single.type))
			addDiag(ctx, force(single.type).range(ctx.allSymbols), Diag(
				Diag.UnsupportedSyntax(Diag.UnsupportedSyntax.Reason.enumMemberType)));
		return some(EnumOrFlagsMember(EnumMemberSource(single), enum_, single.name.name, value));
	} else {
		addDiag(ctx, ast.range(ctx.allSymbols), Diag(
			Diag.StructParamsSyntaxError(enum_, Diag.StructParamsSyntaxError.Reason.destructure)));
		return none!EnumOrFlagsMember;
	}
}

Opt!Member recordOrUnionMemberFromParam(Member)(
	ref CheckCtx ctx,
	StructDecl* struct_,
	DestructureAst* ast,
	in CbCheckMember!Member cbCheckMember,
) {
	if (ast.isA!(DestructureAst.Single)) {
		DestructureAst.Single* single = &ast.as!(DestructureAst.Single)();
		return some(cbCheckMember(RecordOrUnionMemberAstCommon(
			RecordOrUnionMemberSource(single),
			none!VisibilityAndRange,
			single.name,
			has(single.mut) ? some(FieldMutabilityAst(force(single.mut), none!Visibility)) : none!FieldMutabilityAst,
			has(single.type) ? some(*force(single.type)) : none!TypeAst)));
	} else {
		addDiag(ctx, ast.range(ctx.allSymbols), Diag(
			Diag.StructParamsSyntaxError(struct_, Diag.StructParamsSyntaxError.Reason.destructure)));
		return none!Member;
	}
}

RecordField checkRecordField(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesMap structsAndAliasesMap,
	scope ref DelayStructInsts delayStructInsts,
	StructDecl* record,
	RecordOrUnionMemberAstCommon ast,
) {
	Symbol name = ast.name.name;
	Type memberType = has(ast.type)
		? typeFromAst(
			ctx, commonTypes, force(ast.type), structsAndAliasesMap,
			record.typeParams, someMut(ptrTrustMe(delayStructInsts)))
		: () {
			addDiag(ctx, ast.name.range(ctx.allSymbols), Diag(Diag.RecordFieldNeedsType(name)));
			return Type(Type.Bogus());
		}();
	checkReferenceLinkageAndPurity(ctx, record, ast.source.range(ctx.allSymbols), memberType);

	if (has(ast.mutability) && record.purity != Purity.mut && !record.purityIsForced)
		addDiag(ctx, force(ast.mutability).range, Diag(Diag.MutFieldNotAllowed()));
	Visibility visibility = visibilityFromDefaultWithDiag(ctx, record.visibility, ast.visibility,
		Diag.VisibilityWarning.Kind(Diag.VisibilityWarning.Kind.Field(record, name)));
	Opt!Visibility mutability = has(ast.mutability)
		? some(visibilityFromDefaultWithDiag(
			ctx, visibility, force(ast.mutability).visibility,
			Diag.VisibilityWarning.Kind(Diag.VisibilityWarning.Kind.FieldMutability(name))))
		: none!Visibility;
	return RecordField(ast.source, record, visibility, name, mutability, memberType);
}

UnionMember checkUnionMember(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesMap structsAndAliasesMap,
	scope ref DelayStructInsts delayStructInsts,
	StructDecl* struct_,
	RecordOrUnionMemberAstCommon ast,
) {
	Type type = has(ast.type)
		? typeFromAst(
			ctx,
			commonTypes,
			force(ast.type),
			structsAndAliasesMap,
			struct_.typeParams,
			someMut(ptrTrustMe(delayStructInsts)))
		: Type(commonTypes.void_);
	checkReferenceLinkageAndPurity(ctx, struct_, ast.name.range(ctx.allSymbols), type);
	if (has(ast.mutability))
		addDiag(ctx, force(ast.mutability).range, Diag(
			Diag.UnsupportedSyntax(Diag.UnsupportedSyntax.Reason.unionMemberMutability)));
	if (has(ast.visibility))
		addDiag(ctx, force(ast.visibility).range, Diag(
			Diag.UnsupportedSyntax(Diag.UnsupportedSyntax.Reason.unionMemberVisibility)));
	return UnionMember(ast.source, struct_, ast.name.name, type);
}

IntegralType checkEnumOrFlagsModifiers(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesMap structsAndAliasesMap,
	scope ref DelayStructInsts delayStructInsts,
	StructDecl* struct_,
	DeclKind declKind,
	ModifierAst[] modifiers,
) {
	MutOpt!(ModifierAst.Keyword*) storage;
	foreach (ref ModifierAst modifier; modifiers) {
		if (!isStructModifier(modifier)) {
			if (modifier.isA!(ModifierAst.Keyword)) {
				ModifierAst.Keyword* x = &modifier.as!(ModifierAst.Keyword)();
				if (x.keyword == ModifierKeyword.storage) {
					if (has(storage))
						addDiag(ctx, x.keywordRange, Diag(Diag.ModifierDuplicate(ModifierKeyword.storage)));
					else
						storage = someMut(x);
				} else
					addDiag(ctx, x.keywordRange, x.keyword == ModifierKeyword.byVal
						? Diag(Diag.ModifierRedundantDueToDeclKind(x.keyword, declKind))
						: Diag(Diag.ModifierInvalid(x.keyword, declKind)));
			} else
				addDiag(ctx, modifier.range(ctx.allSymbols), Diag(Diag.SpecUseInvalid(declKind)));
		}
	}

	if (has(storage)) {
		ModifierAst.Keyword* x = force(storage);
		if (has(x.typeArg)) {
			Type type = typeFromAst(
				ctx, commonTypes, force(x.typeArg), structsAndAliasesMap, emptyTypeParams,
				someMut(ptrTrustMe(delayStructInsts)));
			return getEnumTypeFromType(ctx, struct_, force(x.typeArg).range(ctx.allSymbols), commonTypes, type);
		} else {
			addDiag(ctx, x.keywordRange, Diag(Diag.StorageMissingType()));
			return IntegralType.nat32;
		}
	} else
		return IntegralType.nat32;
}

immutable struct RecordModifiers {
	Opt!(ModifierAst.Keyword*) byValOrRef;
	Opt!(ModifierAst.Keyword*) newVisibility;
	Opt!(ModifierAst.Keyword*) nominal;
	Opt!(ModifierAst.Keyword*) packed;
}

void accumulateModifier(ref CheckCtx ctx, ref MutOpt!(ModifierAst.Keyword*) old, ModifierAst.Keyword* new_) {
	if (has(old)) {
		ModifierKeyword oldKeyword = force(old).keyword;
		addDiag(ctx, new_.keywordRange, new_.keyword == oldKeyword
			? Diag(Diag.ModifierDuplicate(new_.keyword))
			: Diag(Diag.ModifierConflict(oldKeyword, new_.keyword)));
	}
	old = someMut(new_);
}

RecordModifiers accumulateRecordModifiers(ref CheckCtx ctx, ModifierAst[] modifiers) {
	MutOpt!(ModifierAst.Keyword*) byValOrRef;
	MutOpt!(ModifierAst.Keyword*) newVisibility;
	MutOpt!(ModifierAst.Keyword*) nominal;
	MutOpt!(ModifierAst.Keyword*) packed;

	foreach (ref ModifierAst modifier; modifiers) {
		if (modifier.isA!(ModifierAst.Keyword)) {
			ModifierAst.Keyword* x = &modifier.as!(ModifierAst.Keyword)();
			switch (x.keyword) {
				case ModifierKeyword.byRef:
				case ModifierKeyword.byVal:
					accumulateModifier(ctx, byValOrRef, x);
					break;
				case ModifierKeyword.newInternal:
				case ModifierKeyword.newPrivate:
				case ModifierKeyword.newPublic:
					accumulateModifier(ctx, newVisibility, x);
					break;
				case ModifierKeyword.nominal:
					accumulateModifier(ctx, nominal, x);
					break;
				case ModifierKeyword.packed:
					accumulateModifier(ctx, packed, x);
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
					addDiag(ctx, x.keywordRange, Diag(Diag.ModifierInvalid(x.keyword, DeclKind.record)));
					break;
			}
		} else
			addDiag(ctx, modifier.range(ctx.allSymbols), Diag(Diag.SpecUseInvalid(DeclKind.record)));
	}
	modifierTypeArgInvalid(ctx, [byValOrRef, newVisibility, nominal, packed]);
	return RecordModifiers(
		byValOrRef: optFromMut!(ModifierAst.Keyword*)(byValOrRef),
		newVisibility: optFromMut!(ModifierAst.Keyword*)(newVisibility),
		nominal: optFromMut!(ModifierAst.Keyword*)(nominal),
		packed: optFromMut!(ModifierAst.Keyword*)(packed));
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
			visibilityFromNewVisibility(force(modifiers.newVisibility).keyword),
			force(modifiers.newVisibility).keywordPos))
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
		case symbol!"fun-data".value:
		case symbol!"fun-shared".value:
		case symbol!"fun-mut".value:
			return BuiltinType.lambda;
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
