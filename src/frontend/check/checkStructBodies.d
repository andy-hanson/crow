module frontend.check.checkStructs;

@safe @nogc pure nothrow:

import frontend.check.check : visibilityFromExplicit;
import frontend.check.checkCtx : addDiag, CheckCtx, rangeInFile;
import frontend.check.instantiate : DelayStructInsts;
import frontend.check.maps : StructsAndAliasesMap;
import frontend.check.typeFromAst : checkTypeParams, typeFromAst;
import model.ast :
	FieldMutabilityAst,
	LiteralIntAst,
	LiteralNatAst,
	ModifierAst,
	rangeOfModifierAst,
	StructDeclAst,
	symbolOfModifierKind,
	TypeAst;
import model.concreteModel : TypeSize;
import model.diag : Diag, TypeKind;
import model.model :
	CommonTypes,
	emptyTypeParams,
	EnumBackingType,
	EnumValue,
	FieldMutability,
	ForcedByValOrRefOrNone,
	IntegralTypes,
	isLinkagePossiblyCompatible,
	isPurityPossiblyCompatible,
	leastVisibility,
	Linkage,
	linkageRange,
	Purity,
	purityRange,
	RecordField,
	RecordFlags,
	StructBody,
	StructDecl,
	StructDeclSource,
	StructInst,
	symbolOfForcedByValOrRefOrNone,
	symbolOfLinkage,
	Type,
	TypeParamIndex,
	UnionMember,
	Visibility;
import util.col.array : eachPair, fold, isEmpty, map, mapAndFold, MapAndFold, mapPointers, zipPtrFirst;
import util.conv : safeToSizeT;
import util.opt : force, has, none, Opt, optOrDefault, some, someMut;
import util.sourceRange : Range;
import util.symbol : Symbol, symbol;
import util.util : isMultipleOf, ptrTrustMe, todo, unreachable;

StructDecl[] checkStructsInitial(ref CheckCtx ctx, in StructDeclAst[] asts) =>
	mapPointers!(StructDecl, StructDeclAst)(ctx.alloc, asts, (StructDeclAst* ast) {
		checkTypeParams(ctx, ast.typeParams);
		LinkageAndPurity p = getStructModifiers(ctx, getTypeKind(ast.body_), ast.modifiers);
		return StructDecl(
			StructDeclSource(ast),
			ctx.curUri,
			ast.name.name,
			visibilityFromExplicit(ast.visibility),
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
			(in StructDeclAst.Body.Builtin) {
				checkOnlyStructModifiers(ctx, TypeKind.builtin, ast.modifiers);
				return StructBody(StructBody.Builtin());
			},
			(in StructDeclAst.Body.Enum x) {
				checkOnlyStructModifiers(ctx, TypeKind.enum_, ast.modifiers);
				return StructBody(checkEnum(
					ctx, commonTypes, structsAndAliasesMap, struct_, ast.range, x, delayStructInsts));
			},
			(in StructDeclAst.Body.Extern it) =>
				StructBody(checkExtern(ctx, ast, it)),
			(in StructDeclAst.Body.Flags x) {
				checkOnlyStructModifiers(ctx, TypeKind.flags, ast.modifiers);
				return StructBody(checkFlags(
					ctx, commonTypes, structsAndAliasesMap, struct_, ast.range, x, delayStructInsts));
			},
			(in StructDeclAst.Body.Record x) =>
				StructBody(checkRecord(
					ctx, commonTypes, structsAndAliasesMap, struct_, ast.modifiers, x, delayStructInsts)),
			(in StructDeclAst.Body.Union x) {
				checkOnlyStructModifiers(ctx, TypeKind.union_, ast.modifiers);
				return StructBody(checkUnion(ctx, commonTypes, structsAndAliasesMap, struct_, x, delayStructInsts));
			});
	});
}

private:

StructBody.Extern checkExtern(ref CheckCtx ctx, in StructDeclAst declAst, in StructDeclAst.Body.Extern bodyAst) {
	checkOnlyStructModifiers(ctx, TypeKind.extern_, declAst.modifiers);
	if (!isEmpty(declAst.typeParams))
		addDiag(ctx, declAst.range, Diag(Diag.ExternHasTypeParams()));
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
LinkageAndPurity getStructModifiers(ref CheckCtx ctx, TypeKind typeKind, in ModifierAst[] modifiers) {
	Linkage defaultLinkage = defaultLinkage(typeKind);
	PurityAndForced defaultPurity = PurityAndForced(defaultPurity(typeKind), false);
	OptLinkageAndPurity opts = fold!(OptLinkageAndPurity, ModifierAst)(
		OptLinkageAndPurity(),
		modifiers,
		(OptLinkageAndPurity cur, in ModifierAst mod) {
			void addDiagConflictOrDuplicate(Symbol prev) {
				addDiag(
					ctx,
					rangeOfModifierAst(mod, ctx.allSymbols),
					modifierConflictOrDuplicate(prev, symbolOfModifierKind(mod.kind)));
			}
			void addDiagRedundant() {
				addDiag(ctx, rangeOfModifierAst(mod, ctx.allSymbols), Diag(Diag.ModifierRedundantDueToTypeKind(
					symbolOfModifierKind(mod.kind),
					typeKind)));
			}

			if (mod.kind == ModifierAst.Kind.extern_) {
				if (has(cur.linkage))
					addDiagConflictOrDuplicate(symbolOfLinkage(force(cur.linkage)));
				else if (Linkage.extern_ == defaultLinkage)
					addDiagRedundant();
				return OptLinkageAndPurity(some(Linkage.extern_), cur.purityAndForced);
			} else {
				Opt!PurityAndForced op = purityAndForcedFromModifier(mod.kind);
				if (has(op)) {
					if (has(cur.purityAndForced))
						addDiagConflictOrDuplicate(symbolOfPurityAndForced(force(cur.purityAndForced)));
					else if (force(op) == defaultPurity)
						addDiagRedundant();
					return OptLinkageAndPurity(cur.linkage, op);
				} else
					return cur;
			}
		});
	return LinkageAndPurity(
		optOrDefault!Linkage(opts.linkage, () => defaultLinkage),
		optOrDefault!PurityAndForced(opts.purityAndForced, () => defaultPurity));
}

Diag modifierConflictOrDuplicate(Symbol a, Symbol b) =>
	a == b ? Diag(Diag.ModifierDuplicate(a)) : Diag(Diag.ModifierConflict(a, b));

Linkage defaultLinkage(TypeKind a) {
	final switch (a) {
		case TypeKind.builtin:
		case TypeKind.enum_:
		case TypeKind.flags:
		case TypeKind.record:
		case TypeKind.union_:
			return Linkage.internal;
		case TypeKind.extern_:
			return Linkage.extern_;
	}
}

Purity defaultPurity(TypeKind a) {
	final switch (a) {
		case TypeKind.builtin:
		case TypeKind.enum_:
		case TypeKind.flags:
		case TypeKind.record:
		case TypeKind.union_:
			return Purity.data;
		case TypeKind.extern_:
			return Purity.mut;
	}
}

TypeKind getTypeKind(in StructDeclAst.Body a) =>
	a.matchIn!TypeKind(
		(in StructDeclAst.Body.Builtin) =>
			TypeKind.builtin,
		(in StructDeclAst.Body.Enum) =>
			TypeKind.enum_,
		(in StructDeclAst.Body.Extern) =>
			TypeKind.extern_,
		(in StructDeclAst.Body.Flags) =>
			TypeKind.flags,
		(in StructDeclAst.Body.Record) =>
			TypeKind.record,
		(in StructDeclAst.Body.Union) =>
			TypeKind.union_);

Opt!PurityAndForced purityAndForcedFromModifier(ModifierAst.Kind a) {
	final switch (a) {
		case ModifierAst.Kind.byRef:
		case ModifierAst.Kind.byVal:
		case ModifierAst.Kind.extern_:
		case ModifierAst.Kind.newPrivate:
		case ModifierAst.Kind.newPublic:
		case ModifierAst.Kind.packed:
			return none!PurityAndForced;
		case ModifierAst.Kind.data:
			return some(PurityAndForced(Purity.data, false));
		case ModifierAst.Kind.forceShared:
			return some(PurityAndForced(Purity.shared_, true));
		case ModifierAst.Kind.mut:
			return some(PurityAndForced(Purity.mut, false));
		case ModifierAst.Kind.shared_:
			return some(PurityAndForced(Purity.shared_, false));
	}
}

Symbol symbolOfPurityAndForced(PurityAndForced a) {
	final switch (a.purity) {
		case Purity.data:
			assert(!a.forced);
			return symbol!"data";
		case Purity.shared_:
			return a.forced ? symbol!"force-shared" : symbol!"shared";
		case Purity.mut:
			assert(!a.forced);
			return symbol!"mut";
	}
}

void checkOnlyStructModifiers(ref CheckCtx ctx, TypeKind typeKind, in ModifierAst[] modifiers) {
	foreach (ref ModifierAst modifier; modifiers)
		if (!isStructModifier(modifier.kind)) {
			Symbol symbol = symbolOfModifierKind(modifier.kind);
			addDiag(ctx, rangeOfModifierAst(modifier, ctx.allSymbols), modifier.kind == ModifierAst.Kind.byVal
				? Diag(Diag.ModifierRedundantDueToTypeKind(symbol, typeKind))
				: Diag(Diag.ModifierInvalid(symbol, typeKind)));
		}
}

bool isStructModifier(ModifierAst.Kind a) {
	if (a == ModifierAst.Kind.extern_)
		return true;
	else {
		Opt!PurityAndForced purity = purityAndForcedFromModifier(a);
		return has(purity);
	}
}

StructBody.Enum checkEnum(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesMap structsAndAliasesMap,
	StructDecl* struct_,
	in Range range,
	in StructDeclAst.Body.Enum e,
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
	in StructDeclAst.Body.Flags f,
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
	StructBody.Enum.Member[] members;
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
	in StructDeclAst.Body.Enum.Member[] memberAsts,
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

	StructBody.Enum.Member[] members =
		mapAndFold!(StructBody.Enum.Member, Opt!EnumValue, StructDeclAst.Body.Enum.Member)(
			ctx.alloc,
			none!EnumValue,
			memberAsts,
			(in StructDeclAst.Body.Enum.Member memberAst, Opt!EnumValue lastValue) {
				ValueAndOverflow valueAndOverflow = () {
					if (has(memberAst.value))
						return isSignedEnumBackingType(enumType)
							? force(memberAst.value).matchIn!ValueAndOverflow(
								(in LiteralIntAst i) =>
									ValueAndOverflow(EnumValue(i.value), i.overflow),
								(in LiteralNatAst n) =>
									ValueAndOverflow(EnumValue(n.value), n.value > long.max))
							: force(memberAst.value).match!ValueAndOverflow(
								(LiteralIntAst) =>
									todo!ValueAndOverflow("signed value in unsigned enum"),
								(LiteralNatAst n) =>
									ValueAndOverflow(EnumValue(n.value), n.overflow));
					else
						return cbGetNextValue(lastValue, enumType);
				}();
				EnumValue value = valueAndOverflow.value;
				if (valueAndOverflow.overflow || valueOverflows(enumType, value))
					addDiag(ctx, memberAst.range, Diag(Diag.EnumMemberOverflows(enumType)));
				return MapAndFold!(StructBody.Enum.Member, Opt!EnumValue)(
					StructBody.Enum.Member(rangeInFile(ctx, memberAst.range), memberAst.name, value),
					some(value));
			}).output;

	eachPair!(StructBody.Enum.Member)(members, (in StructBody.Enum.Member a, in StructBody.Enum.Member b) {
		if (a.name == b.name)
			addDiag(ctx, b.range, Diag(Diag.DuplicateDeclaration(memberKind, b.name)));
		if (a.value == b.value)
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
			unreachable!EnumBackingType(),
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
	in StructDeclAst.Body.Record r,
	scope ref DelayStructInsts delayStructInsts,
) {
	RecordModifiers modifiers = checkRecordModifiers(ctx, modifierAsts);
	bool isExtern = struct_.linkage != Linkage.internal;
	ForcedByValOrRefOrNone valOrRef = isExtern ? ForcedByValOrRefOrNone.byVal : modifiers.byValOrRefOrNone;
	if (isExtern && modifiers.byValOrRefOrNone != ForcedByValOrRefOrNone.none)
		addDiag(ctx, struct_.range, Diag(Diag.ExternRecordImplicitlyByVal(struct_)));
	RecordField[] fields = mapPointers!(RecordField, StructDeclAst.Body.Record.Field)(
		ctx.alloc, r.fields, (StructDeclAst.Body.Record.Field* field) =>
			checkRecordField(ctx, commonTypes, structsAndAliasesMap, delayStructInsts, struct_, field));
	eachPair!RecordField(fields, (in RecordField a, in RecordField b) {
		if (a.name == b.name)
			addDiag(ctx, b.range, Diag(Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.recordField, a.name)));
	});
	return StructBody.Record(
		RecordFlags(recordNewVisibility(ctx, *struct_, fields, modifiers.newVisibility), modifiers.packed, valOrRef),
		fields);
}

RecordField checkRecordField(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesMap structsAndAliasesMap,
	scope ref DelayStructInsts delayStructInsts,
	StructDecl* struct_,
	StructDeclAst.Body.Record.Field* ast,
) {
	Type fieldType = typeFromAst(
		ctx, commonTypes, ast.type, structsAndAliasesMap, struct_.typeParams, someMut(ptrTrustMe(delayStructInsts)));
	checkReferenceLinkageAndPurity(ctx, struct_, ast.range, fieldType);
	if (has(ast.mutability) && struct_.purity != Purity.mut && !struct_.purityIsForced)
		addDiag(ctx, ast.range, Diag(Diag.MutFieldNotAllowed()));
	return RecordField(
		ast,
		struct_,
		visibilityFromExplicit(ast.visibility),
		ast.name.name,
		fieldMutabilityFromAst(ast.mutability),
		fieldType);
}

FieldMutability fieldMutabilityFromAst(Opt!FieldMutabilityAst a) {
	if (has(a)) {
		final switch (force(a).kind) {
			case FieldMutabilityAst.Kind.private_:
				return FieldMutability.private_;
			case FieldMutabilityAst.Kind.public_:
				return FieldMutability.public_;
		}
	} else
		return FieldMutability.const_;
}

StructBody.Union checkUnion(
	ref CheckCtx ctx,
	ref CommonTypes commonTypes,
	ref StructsAndAliasesMap structsAndAliasesMap,
	StructDecl* struct_,
	in StructDeclAst.Body.Union ast,
	scope ref DelayStructInsts delayStructInsts,
) {
	final switch (struct_.linkage) {
		case Linkage.internal:
			break;
		case Linkage.extern_:
			addDiag(ctx, struct_.range, Diag(Diag.ExternUnion()));
	}
	UnionMember[] members = map(ctx.alloc, ast.members, (ref StructDeclAst.Body.Union.Member memberAst) =>
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
	in StructDeclAst.Body.Union.Member ast,
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
	return UnionMember(rangeInFile(ctx, ast.range), ast.name, type);
}

immutable struct RecordModifiers {
	ForcedByValOrRefOrNone byValOrRefOrNone;
	Opt!Visibility newVisibility;
	bool packed;
}

RecordModifiers withByValOrRef(
	ref CheckCtx ctx,
	RecordModifiers cur,
	in Range range,
	ForcedByValOrRefOrNone value) {
	if (cur.byValOrRefOrNone != ForcedByValOrRefOrNone.none) {
		Symbol valueSym = symbolOfForcedByValOrRefOrNone(value);
		addDiag(ctx, range, value == cur.byValOrRefOrNone
			? Diag(Diag.ModifierDuplicate(valueSym))
			: Diag(Diag.ModifierConflict(symbolOfForcedByValOrRefOrNone(cur.byValOrRefOrNone), valueSym)));
	}
	return RecordModifiers(value, cur.newVisibility, cur.packed);
}

RecordModifiers withNewVisibility(ref CheckCtx ctx, RecordModifiers cur, in Range range, Visibility value) {
	if (has(cur.newVisibility)) {
		Symbol valueSym = symbolOfNewVisibility(value);
		addDiag(ctx, range, value == force(cur.newVisibility)
			? Diag(Diag.ModifierDuplicate(valueSym))
			: Diag(Diag.ModifierConflict(symbolOfNewVisibility(force(cur.newVisibility)), valueSym)));
	}
	return RecordModifiers(cur.byValOrRefOrNone, some(value), cur.packed);
}

Symbol symbolOfNewVisibility(Visibility a) {
	final switch (a) {
		case Visibility.private_:
			return symbol!"-new";
		case Visibility.internal:
			return symbol!"~new";
		case Visibility.public_:
			return symbol!"+new";
	}
}

RecordModifiers withPacked(ref CheckCtx ctx, RecordModifiers cur, in Range range) {
	if (cur.packed)
		addDiag(ctx, range, Diag(Diag.ModifierDuplicate(symbol!"packed")));
	return RecordModifiers(cur.byValOrRefOrNone, cur.newVisibility, true);
}

RecordModifiers checkRecordModifiers(ref CheckCtx ctx, ModifierAst[] modifiers) =>
	fold!(RecordModifiers, ModifierAst)(
		RecordModifiers(ForcedByValOrRefOrNone.none, none!Visibility, false),
		modifiers,
		(RecordModifiers cur, in ModifierAst modifier) {
			Range range = rangeOfModifierAst(modifier, ctx.allSymbols);
			final switch (modifier.kind) {
				case ModifierAst.Kind.byRef:
					return withByValOrRef(ctx, cur, range, ForcedByValOrRefOrNone.byRef);
				case ModifierAst.Kind.byVal:
					return withByValOrRef(ctx, cur, range, ForcedByValOrRefOrNone.byVal);
				case ModifierAst.Kind.newPrivate:
					return withNewVisibility(ctx, cur, range, Visibility.private_);
				case ModifierAst.Kind.newPublic:
					return withNewVisibility(ctx, cur, range, Visibility.public_);
				case ModifierAst.Kind.packed:
					return withPacked(ctx, cur, range);
				case ModifierAst.Kind.data:
				case ModifierAst.Kind.extern_:
				case ModifierAst.Kind.forceShared:
				case ModifierAst.Kind.mut:
				case ModifierAst.Kind.shared_:
					// already handled in getStructModifiers
					return cur;
			}
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
	ref StructDecl struct_,
	in RecordField[] fields,
	Opt!Visibility explicit,
) {
	Visibility default_ = fold!(Visibility, RecordField)(
		struct_.visibility, fields, (Visibility cur, in RecordField field) =>
			leastVisibility(cur, field.visibility));
	if (has(explicit)) {
		if (force(explicit) == default_)
			//TODO: better range
			addDiag(ctx, struct_.range, Diag(Diag.RecordNewVisibilityIsRedundant(default_)));
		return force(explicit);
	} else
		return default_;
}
