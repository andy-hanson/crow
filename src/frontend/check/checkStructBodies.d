module frontend.check.checkStructs;

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
import model.ast : LiteralIntAst, LiteralNatAst, ModifierAst, ModifierKeyword, StructBodyAst, StructDeclAst, TypeAst;
import model.concreteModel : TypeSize;
import model.diag : Diag, DeclKind;
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
import util.conv : safeToSizeT;
import util.opt : force, has, MutOpt, none, noneMut, Opt, optOrDefault, some, someMut;
import util.sourceRange : Range;
import util.symbol : Symbol, symbol;
import util.util : enumConvert, isMultipleOf, ptrTrustMe, todo;

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
				StructBody(checkExtern(ctx, ast, it)),
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

StructBody.Extern checkExtern(ref CheckCtx ctx, in StructDeclAst declAst, in StructBodyAst.Extern bodyAst) {
	checkNoTypeParams(ctx, declAst.typeParams, DeclKind.extern_);
	checkOnlyStructModifiers(ctx, DeclKind.extern_, declAst.modifiers);
	Opt!size_t optNat(Opt!(LiteralNatAst*) value) {
		if (has(value)) {
			LiteralNatAst n = *force(value);
			if (n.overflow || n.value > size_t.max) {
				todo!void("checkExtern diagnostic");
				return none!size_t;
			} else
				return some(safeToSizeT(n.value));
		} else
			return none!size_t;
	}
	return StructBody.Extern(toTypeSize(ctx, optNat(bodyAst.size), optNat(bodyAst.alignment)));
}
Opt!TypeSize toTypeSize(ref CheckCtx ctx, Opt!size_t optSize, Opt!size_t optAlignment) {
	if (has(optSize)) {
		size_t size = force(optSize);
		size_t defAlign = defaultAlignment(size);
		size_t alignment = () {
			if (has(optAlignment)) {
				switch (force(optAlignment)) {
					case 1:
					case 2:
					case 4:
					case 8:
						return force(optAlignment);
					default:
						todo!void("toTypeSize diagnostic");
						return defAlign;
				}
			} else
				return defAlign;
		}();
		return some(TypeSize(size, alignment));
	} else
		return none!TypeSize;
}

size_t defaultAlignment(size_t size) =>
	size == 0 ? 0 :
	isMultipleOf(size, 8) ? 8 :
	isMultipleOf(size, 4) ? 4 :
	isMultipleOf(size, 2) ? 2 :
	1;

immutable struct LinkageAndPurity {
	Linkage linkage;
	PurityAndForced purityAndForced;
}
immutable struct OptLinkageAndPurity {
	Opt!Linkage linkage;
	Opt!PurityAndForced purityAndForced;
}

immutable struct PurityAndForced {
	Purity purity;
	bool forced;
}

// Note: purity is taken for granted here, and verified later when we check the body.
LinkageAndPurity getStructModifiers(ref CheckCtx ctx, DeclKind declKind, in ModifierAst[] modifiers) {
	Linkage defaultLinkage = defaultLinkage(declKind);
	PurityAndForced defaultPurity = PurityAndForced(defaultPurity(declKind), false);
	OptLinkageAndPurity opts = fold!(OptLinkageAndPurity, ModifierAst)(
		OptLinkageAndPurity(),
		modifiers,
		(OptLinkageAndPurity cur, in ModifierAst mod) {
			if (isStructModifier(mod)) {
				ModifierAst.Keyword kw = mod.as!(ModifierAst.Keyword);
				void addDiagConflictOrDuplicate(ModifierKeyword prev) {
					addDiag(ctx, kw.range, modifierConflictOrDuplicate(prev, kw.kind));
				}
				void addDiagRedundant() {
					addDiag(ctx, kw.range, Diag(
						Diag.ModifierRedundantDueToDeclKind(kw.kind, declKind)));
				}
				if (kw.kind == ModifierKeyword.extern_) {
					if (has(cur.linkage))
						addDiagConflictOrDuplicate(ModifierKeyword.extern_);
					else if (Linkage.extern_ == defaultLinkage)
						addDiagRedundant();
					return OptLinkageAndPurity(some(Linkage.extern_), cur.purityAndForced);
				} else {
					Opt!PurityAndForced opt = purityAndForcedFromModifier(kw.kind);
					PurityAndForced pur = force(opt);
					if (has(cur.purityAndForced))
						addDiagConflictOrDuplicate(modifierForPurityAndForced(force(cur.purityAndForced)));
					else if (pur == defaultPurity)
						addDiagRedundant();
					return OptLinkageAndPurity(cur.linkage, some(pur));
				}
			} else
				// Already warned in 'checkOnlyStructModifiers'
				return cur;
		});
	return LinkageAndPurity(
		optOrDefault!Linkage(opts.linkage, () => defaultLinkage),
		optOrDefault!PurityAndForced(opts.purityAndForced, () => defaultPurity));
}

Diag modifierConflictOrDuplicate(ModifierKeyword a, ModifierKeyword b) =>
	a == b ? Diag(Diag.ModifierDuplicate(a)) : Diag(Diag.ModifierConflict(a, b));

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

ModifierKeyword modifierForPurityAndForced(PurityAndForced a) {
	final switch (a.purity) {
		case Purity.data:
			assert(!a.forced);
			return ModifierKeyword.data;
		case Purity.shared_:
			return a.forced ? ModifierKeyword.forceShared : ModifierKeyword.shared_;
		case Purity.mut:
			assert(!a.forced);
			return ModifierKeyword.mut;
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
	in StructBodyAst.Enum.Member[] memberAsts,
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
	EnumMember[] members = mapPointers(ctx.alloc, memberAsts, (StructBodyAst.Enum.Member* memberAst) {
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
	RecordModifiers modifiers = checkRecordModifiers(ctx, modifierAsts);
	bool isExtern = struct_.linkage != Linkage.internal;
	Opt!ByValOrRef valOrRef = isExtern ? some(ByValOrRef.byVal) : modifiers.byValOrRef;
	if (isExtern && has(modifiers.byValOrRef))
		addDiagAssertSameUri(ctx, struct_.range, Diag(Diag.ExternRecordImplicitlyByVal(struct_)));
	RecordField[] fields = mapPointers!(RecordField, StructBodyAst.Record.Field)(
		ctx.alloc, r.fields, (StructBodyAst.Record.Field* field) =>
			checkRecordField(ctx, commonTypes, structsAndAliasesMap, delayStructInsts, struct_, field));
	eachPair!RecordField(fields, (in RecordField a, in RecordField b) {
		if (a.name == b.name)
			addDiag(ctx, b.range, Diag(Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.recordField, a.name)));
	});
	return StructBody.Record(
		RecordFlags(recordNewVisibility(ctx, struct_, fields, modifiers.newVisibility), modifiers.packed, valOrRef),
		fields);
}

RecordField checkRecordField(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesMap structsAndAliasesMap,
	scope ref DelayStructInsts delayStructInsts,
	StructDecl* record,
	StructBodyAst.Record.Field* ast,
) {
	Type fieldType = typeFromAst(
		ctx, commonTypes, ast.type, structsAndAliasesMap, record.typeParams, someMut(ptrTrustMe(delayStructInsts)));
	checkReferenceLinkageAndPurity(ctx, record, ast.range, fieldType);
	if (has(ast.mutability) && record.purity != Purity.mut && !record.purityIsForced)
		addDiag(ctx, ast.range, Diag(Diag.MutFieldNotAllowed()));
	Symbol name = ast.name.name;
	Visibility visibility = visibilityFromDefaultWithDiag(ctx, ast.range, record.visibility, ast.visibility,
		Diag.VisibilityWarning.Kind(Diag.VisibilityWarning.Kind.Field(record, name)));
	Opt!Visibility mutability = has(ast.mutability)
		? some(visibilityFromDefaultWithDiag(
			ctx, ast.range, visibility, force(ast.mutability).visibility,
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
	UnionMember[] members = mapPointers(ctx.alloc, ast.members, (StructBodyAst.Union.Member* memberAst) =>
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
	StructBodyAst.Union.Member* ast,
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

immutable struct RecordModifiers {
	Opt!ByValOrRef byValOrRef;
	NewVisibility newVisibility;
	bool packed;
}
immutable struct NewVisibility {
	Range range;
	Opt!Visibility visibility;
}

RecordModifiers withByValOrRef(ref CheckCtx ctx, RecordModifiers cur, in Range range, ByValOrRef value) {
	if (has(cur.byValOrRef)) {
		ModifierKeyword valueKeyword = modifierOfByValOrRef(value);
		addDiag(ctx, range, value == force(cur.byValOrRef)
			? Diag(Diag.ModifierDuplicate(valueKeyword))
			: Diag(Diag.ModifierConflict(modifierOfByValOrRef(force(cur.byValOrRef)), valueKeyword)));
	}
	return RecordModifiers(some(value), cur.newVisibility, cur.packed);
}

ModifierKeyword modifierOfByValOrRef(ByValOrRef a) =>
	enumConvert!ModifierKeyword(a);

RecordModifiers withNewVisibility(ref CheckCtx ctx, RecordModifiers cur, in Range range, Visibility value) {
	if (has(cur.newVisibility.visibility)) {
		ModifierKeyword valueKeyword = modifierOfNewVisibility(value);
		addDiag(ctx, range, value == force(cur.newVisibility.visibility)
			? Diag(Diag.ModifierDuplicate(valueKeyword))
			: Diag(Diag.ModifierConflict(modifierOfNewVisibility(force(cur.newVisibility.visibility)), valueKeyword)));
	}
	return RecordModifiers(cur.byValOrRef, NewVisibility(range, some(value)), cur.packed);
}

ModifierKeyword modifierOfNewVisibility(Visibility a) {
	final switch (a) {
		case Visibility.private_:
			return ModifierKeyword.newPrivate;
		case Visibility.internal:
			return ModifierKeyword.newInternal;
		case Visibility.public_:
			return ModifierKeyword.newPublic;
	}
}

RecordModifiers withPacked(ref CheckCtx ctx, RecordModifiers cur, in Range range) {
	if (cur.packed)
		addDiag(ctx, range, Diag(Diag.ModifierDuplicate(ModifierKeyword.packed)));
	return RecordModifiers(cur.byValOrRef, cur.newVisibility, true);
}

RecordModifiers checkRecordModifiers(ref CheckCtx ctx, ModifierAst[] modifiers) =>
	fold!(RecordModifiers, ModifierAst)(
		RecordModifiers(none!ByValOrRef, NewVisibility(Range.empty, none!Visibility), false),
		modifiers,
		(RecordModifiers cur, in ModifierAst modifier) {
			Range range = modifier.range(ctx.allSymbols);
			return modifier.matchIn!RecordModifiers(
				(in ModifierAst.Keyword x) {
					switch (x.kind) {
						case ModifierKeyword.byRef:
							return withByValOrRef(ctx, cur, range, ByValOrRef.byRef);
						case ModifierKeyword.byVal:
							return withByValOrRef(ctx, cur, range, ByValOrRef.byVal);
						case ModifierKeyword.newInternal:
							return withNewVisibility(ctx, cur, range, Visibility.internal);
						case ModifierKeyword.newPrivate:
							return withNewVisibility(ctx, cur, range, Visibility.private_);
						case ModifierKeyword.newPublic:
							return withNewVisibility(ctx, cur, range, Visibility.public_);
						case ModifierKeyword.packed:
							return withPacked(ctx, cur, range);
						case ModifierKeyword.data:
						case ModifierKeyword.extern_:
						case ModifierKeyword.forceShared:
						case ModifierKeyword.mut:
						case ModifierKeyword.shared_:
							// already handled in getStructModifiers
							return cur;
						default:
							addDiag(ctx, range, Diag(
								Diag.ModifierInvalid(x.kind, DeclKind.record)));
							return cur;
					}
				},
				(in ModifierAst.Extern x) {
					addDiag(ctx, range, Diag(Diag.ExternHasUnnecessaryLibraryName()));
					return cur;
				},
				(in TypeAst x) {
					addDiag(ctx, range, Diag(Diag.SpecUseInvalid(DeclKind.record)));
					return cur;
				});
		});

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
	in NewVisibility ast,
) {
	Visibility default_ = fold!(Visibility, RecordField)(
		record.visibility, fields, (Visibility cur, in RecordField field) =>
			leastVisibility(cur, field.visibility));
	//TODO: better range
	return visibilityFromDefaultWithDiag(ctx, ast.range, default_, ast.visibility, Diag.VisibilityWarning.Kind(
		Diag.VisibilityWarning.Kind.New(record)));
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
			addDiagAssertSameUri(ctx, nameRange(ctx.allSymbols, *struct_), Diag(
				Diag.BuiltinUnsupported(Diag.BuiltinUnsupported.Kind.type, struct_.name)));
			return BuiltinType.void_;
	}
}
