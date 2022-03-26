module frontend.check.checkStructs;

@safe @nogc pure nothrow:

import frontend.check.checkCtx : addDiag, CheckCtx, rangeInFile;
import frontend.check.dicts : StructsAndAliasesDict;
import frontend.check.instantiate : TypeParamsScope;
import frontend.check.typeFromAst : checkTypeParams, typeFromAst;
import frontend.parse.ast :
	LiteralAst,
	matchLiteralIntOrNat,
	matchStructDeclAstBody,
	ModifierAst,
	rangeOfModifierAst,
	StructDeclAst,
	symOfModifierKind,
	TypeAst;
import model.diag : Diag, TypeKind;
import model.model :
	body_,
	CommonTypes,
	EnumBackingType,
	EnumValue,
	FieldMutability,
	ForcedByValOrRefOrNone,
	IntegralTypes,
	isLinkagePossiblyCompatible,
	isPurityPossiblyCompatible,
	leastVisibility,
	Linkage,
	linkage,
	linkageRange,
	matchType,
	name,
	params,
	Purity,
	purityRange,
	range,
	RecordField,
	RecordFlags,
	setBody,
	StructBody,
	StructDecl,
	StructInst,
	symOfForcedByValOrRefOrNone,
	Type,
	TypeParam,
	typeParams,
	UnionMember,
	Visibility,
	visibility;
import util.col.arr : castImmutable, empty, emptyArr, small;
import util.col.arrUtil : eachPair, fold, map, mapAndFold, MapAndFold, mapToMut, mapWithIndex, zipMutPtrFirst;
import util.col.mutArr : MutArr;
import util.col.str : copySafeCStr;
import util.opt : force, has, none, Opt, some, someMut;
import util.ptr : castImmutable, Ptr, ptrEquals, ptrTrustMe_mut;
import util.sourceRange : RangeWithinFile;
import util.sym : shortSym, SpecialSym, Sym, symEq, symForSpecial;
import util.util : todo, unreachable;

StructDecl[] checkStructsInitial(ref CheckCtx ctx, scope immutable StructDeclAst[] asts) {
	return mapToMut!StructDecl(ctx.alloc, asts, (scope ref immutable StructDeclAst ast) {
		immutable LinkageAndPurity p = getStructModifiers(ctx, getTypeKind(ast.body_), ast.modifiers);
		return StructDecl(
			rangeInFile(ctx, ast.range),
			copySafeCStr(ctx.alloc, ast.docComment),
			ast.name,
			small(checkTypeParams(ctx, ast.typeParams)),
			ast.visibility,
			p.linkage,
			p.purityAndForced.purity,
			p.purityAndForced.forced);
	});
}

void checkStructBodies(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref StructDecl[] structs,
	scope immutable StructDeclAst[] asts,
	ref MutArr!(Ptr!StructInst) delayStructInsts,
) {
	zipMutPtrFirst!(StructDecl, StructDeclAst)(
		structs,
		asts,
		(Ptr!StructDecl struct_, ref immutable StructDeclAst ast) {
			immutable StructBody body_ = matchStructDeclAstBody!(
				immutable StructBody,
				(ref immutable StructDeclAst.Body.Builtin) {
					checkOnlyStructModifiers(ctx, TypeKind.builtin, ast.modifiers);
					return immutable StructBody(immutable StructBody.Builtin());
				},
				(ref immutable StructDeclAst.Body.Enum it) {
					checkOnlyStructModifiers(ctx, TypeKind.enum_, ast.modifiers);
					return immutable StructBody(
						checkEnum(ctx, commonTypes, structsAndAliasesDict, ast.range, it, delayStructInsts));
				},
				(ref immutable StructDeclAst.Body.Flags it) {
					checkOnlyStructModifiers(ctx, TypeKind.flags, ast.modifiers);
					return immutable StructBody(
						checkFlags(ctx, commonTypes, structsAndAliasesDict, ast.range, it, delayStructInsts));
				},
				(ref immutable StructDeclAst.Body.ExternPtr) {
					checkOnlyStructModifiers(ctx, TypeKind.externPtr, ast.modifiers);
					if (!empty(ast.typeParams))
						addDiag(ctx, ast.range, immutable Diag(immutable Diag.ExternPtrHasTypeParams()));
					return immutable StructBody(immutable StructBody.ExternPtr());
				},
				(ref immutable StructDeclAst.Body.Record it) =>
					immutable StructBody(checkRecord(
						ctx,
						commonTypes,
						structsAndAliasesDict,
						castImmutable(struct_),
						ast.modifiers,
						it,
						delayStructInsts)),
				(ref immutable StructDeclAst.Body.Union it) {
					checkOnlyStructModifiers(ctx, TypeKind.union_, ast.modifiers);
					return immutable StructBody(checkUnion(
						ctx,
						commonTypes,
						structsAndAliasesDict,
						castImmutable(struct_),
						it,
						delayStructInsts));
				},
			)(ast.body_);
			setBody(struct_.deref(), body_);
		});
}

private:

struct LinkageAndPurity {
	immutable Linkage linkage;
	immutable PurityAndForced purityAndForced;
}

struct PurityAndForced {
	immutable Purity purity;
	immutable bool forced;
}

// Note: purity is taken for granted here, and verified later when we check the body.
immutable(LinkageAndPurity) getStructModifiers(
	ref CheckCtx ctx,
	immutable TypeKind typeKind,
	scope immutable ModifierAst[] modifiers,
) {
	return fold(
		immutable LinkageAndPurity(defaultLinkage(typeKind), immutable PurityAndForced(defaultPurity(typeKind), false)),
		modifiers,
		(immutable LinkageAndPurity cur, ref immutable ModifierAst mod) {
			if (mod.kind == ModifierAst.Kind.extern_) {
				if (cur.linkage != Linkage.internal)
					addDiag(ctx, rangeOfModifierAst(mod, ctx.allSymbols), immutable Diag(
						immutable Diag.ModifierDuplicate(symOfModifierKind(mod.kind))));
				return immutable LinkageAndPurity(Linkage.extern_, cur.purityAndForced);
			} else {
				immutable Opt!PurityAndForced op = purityAndForcedFromModifier(mod.kind);
				if (has(op)) {
					immutable PurityAndForced next = force(op);
					if (next.purity == cur.purityAndForced.purity)
						addDiag(
							ctx,
							rangeOfModifierAst(mod, ctx.allSymbols),
							cur.purityAndForced.purity == defaultPurity(typeKind)
								? immutable Diag(immutable Diag.PuritySpecifierRedundant(next.purity, typeKind))
								: immutable Diag(immutable Diag.ModifierDuplicate(symOfModifierKind(mod.kind))));
					return immutable LinkageAndPurity(cur.linkage, next);
				} else
					return cur;
			}
		});
}

immutable(Linkage) defaultLinkage(immutable TypeKind a) {
	final switch (a) {
		case TypeKind.builtin:
		case TypeKind.enum_:
		case TypeKind.flags:
		case TypeKind.record:
		case TypeKind.union_:
			return Linkage.internal;
		case TypeKind.externPtr:
			return Linkage.extern_;
	}
}

immutable(Purity) defaultPurity(immutable TypeKind a) {
	final switch (a) {
		case TypeKind.builtin:
		case TypeKind.enum_:
		case TypeKind.flags:
		case TypeKind.record:
		case TypeKind.union_:
			return Purity.data;
		case TypeKind.externPtr:
			return Purity.mut;
	}
}

immutable(TypeKind) getTypeKind(ref immutable StructDeclAst.Body a) {
	return matchStructDeclAstBody!(
		immutable TypeKind,
		(ref immutable StructDeclAst.Body.Builtin) => TypeKind.builtin,
		(ref immutable StructDeclAst.Body.Enum) => TypeKind.enum_,
		(ref immutable StructDeclAst.Body.Flags) => TypeKind.flags,
		(ref immutable StructDeclAst.Body.ExternPtr) => TypeKind.externPtr,
		(ref immutable StructDeclAst.Body.Record) => TypeKind.record,
		(ref immutable StructDeclAst.Body.Union) => TypeKind.union_,
	)(a);
}

immutable(Opt!PurityAndForced) purityAndForcedFromModifier(immutable ModifierAst.Kind a) {
	final switch (a) {
		case ModifierAst.Kind.byRef:
		case ModifierAst.Kind.byVal:
		case ModifierAst.Kind.extern_:
		case ModifierAst.Kind.newPrivate:
		case ModifierAst.Kind.newPublic:
		case ModifierAst.Kind.packed:
			return none!PurityAndForced;
		case ModifierAst.Kind.data:
			return some(immutable PurityAndForced(Purity.data, false));
		case ModifierAst.Kind.forceData:
			return some(immutable PurityAndForced(Purity.data, true));
		case ModifierAst.Kind.forceSendable:
			return some(immutable PurityAndForced(Purity.sendable, true));
		case ModifierAst.Kind.mut:
			return some(immutable PurityAndForced(Purity.mut, false));
		case ModifierAst.Kind.sendable:
			return some(immutable PurityAndForced(Purity.sendable, false));
	}
}

void checkOnlyStructModifiers(ref CheckCtx ctx, immutable TypeKind typeKind, immutable ModifierAst[] modifiers) {
	foreach (immutable ModifierAst modifier; modifiers)
		if (!isStructModifier(modifier.kind))
			addDiag(ctx, rangeOfModifierAst(modifier, ctx.allSymbols), immutable Diag(
				immutable Diag.ModifierInvalid(symOfModifierKind(modifier.kind), typeKind)));
}

immutable(bool) isStructModifier(immutable ModifierAst.Kind a) {
	if (a == ModifierAst.Kind.extern_)
		return true;
	else {
		immutable Opt!PurityAndForced purity = purityAndForcedFromModifier(a);
		return has(purity);
	}
}

immutable(StructBody.Enum) checkEnum(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable RangeWithinFile range,
	ref immutable StructDeclAst.Body.Enum e,
	ref MutArr!(Ptr!StructInst) delayStructInsts,
) {
	immutable EnumOrFlagsTypeAndMembers tm = checkEnumOrFlagsMembers(
		ctx, commonTypes, structsAndAliasesDict, range, e.typeArg, e.members, delayStructInsts,
		Diag.DuplicateDeclaration.Kind.enumMember,
		(immutable Opt!EnumValue lastValue, immutable EnumBackingType enumType) =>
			has(lastValue)
				? immutable ValueAndOverflow(
					immutable EnumValue(force(lastValue).value + 1),
					force(lastValue) == maxValue(enumType))
				: immutable ValueAndOverflow(immutable EnumValue(0), false));
	return immutable StructBody.Enum(tm.backingType, tm.members);
}

immutable(StructBody.Flags) checkFlags(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable RangeWithinFile range,
	ref immutable StructDeclAst.Body.Flags f,
	ref MutArr!(Ptr!StructInst) delayStructInsts,
) {
	immutable EnumOrFlagsTypeAndMembers tm = checkEnumOrFlagsMembers(
		ctx, commonTypes, structsAndAliasesDict, range, f.typeArg, f.members, delayStructInsts,
		Diag.DuplicateDeclaration.Kind.flagsMember,
		(immutable Opt!EnumValue lastValue, immutable EnumBackingType enumType) =>
			has(lastValue)
				? immutable ValueAndOverflow(
					//TODO: if the last value isn't a power of 2, there should be a diagnostic
					immutable EnumValue(force(lastValue).value * 2),
					force(lastValue).value >= maxValue(enumType).value / 2)
				: immutable ValueAndOverflow(immutable EnumValue(1), false));
	return immutable StructBody.Flags(tm.backingType, tm.members);
}

struct EnumOrFlagsTypeAndMembers {
	immutable EnumBackingType backingType;
	immutable StructBody.Enum.Member[] members;
}

struct ValueAndOverflow {
	immutable EnumValue value;
	immutable bool overflow;
}

immutable(EnumOrFlagsTypeAndMembers) checkEnumOrFlagsMembers(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable RangeWithinFile range,
	immutable Opt!(Ptr!TypeAst) typeArg,
	immutable StructDeclAst.Body.Enum.Member[] memberAsts,
	ref MutArr!(Ptr!StructInst) delayStructInsts,
	Diag.DuplicateDeclaration.Kind memberKind,
	scope immutable(ValueAndOverflow) delegate(
		immutable Opt!EnumValue,
		immutable EnumBackingType,
	) @safe @nogc pure nothrow cbGetNextValue,
) {
	immutable TypeParamsScope typeParamsScope = immutable TypeParamsScope(emptyArr!TypeParam);
	immutable Type implementationType = has(typeArg)
		? typeFromAst(
			ctx, commonTypes, force(typeArg).deref(), structsAndAliasesDict, typeParamsScope,
			someMut(ptrTrustMe_mut(delayStructInsts)))
		: immutable Type(commonTypes.integrals.nat32);
	immutable EnumBackingType enumType = getEnumTypeFromType(ctx, range, commonTypes, implementationType);

	immutable StructBody.Enum.Member[] members =
		mapAndFold!(StructBody.Enum.Member, Opt!EnumValue, StructDeclAst.Body.Enum.Member)(
			ctx.alloc,
			none!EnumValue,
			memberAsts,
			(ref immutable StructDeclAst.Body.Enum.Member memberAst, immutable Opt!EnumValue lastValue) {
				immutable ValueAndOverflow valueAndOverflow = () {
					if (has(memberAst.value))
						return isSignedEnumBackingType(enumType)
							? matchLiteralIntOrNat!(
								immutable ValueAndOverflow,
								(ref immutable LiteralAst.Int i) =>
									immutable ValueAndOverflow(immutable EnumValue(i.value), i.overflow),
								(ref immutable LiteralAst.Nat n) =>
									immutable ValueAndOverflow(immutable EnumValue(n.value), n.value > long.max),
							)(force(memberAst.value))
							: matchLiteralIntOrNat!(
								immutable ValueAndOverflow,
								(ref immutable LiteralAst.Int) =>
									todo!(immutable ValueAndOverflow)("signed value in unsigned enum"),
								(ref immutable LiteralAst.Nat n) =>
									immutable ValueAndOverflow(immutable EnumValue(n.value), n.overflow),
							)(force(memberAst.value));
					else
						return cbGetNextValue(lastValue, enumType);
				}();
				immutable EnumValue value = valueAndOverflow.value;
				if (valueAndOverflow.overflow || valueOverflows(enumType, value))
					addDiag(ctx, memberAst.range, immutable Diag(immutable Diag.EnumMemberOverflows(enumType)));
				return immutable MapAndFold!(StructBody.Enum.Member, Opt!EnumValue)(
					immutable StructBody.Enum.Member(rangeInFile(ctx, memberAst.range), memberAst.name, value),
					some(value));
			}).output;

	eachPair!(StructBody.Enum.Member)(
		members,
		(ref immutable StructBody.Enum.Member a, ref immutable StructBody.Enum.Member b) {
			if (a.name == b.name)
				addDiag(ctx, b.range, immutable Diag(immutable Diag.DuplicateDeclaration(memberKind, b.name)));
			if (a.value == b.value)
				addDiag(ctx, b.range, immutable Diag(
					immutable Diag.EnumDuplicateValue(isSignedEnumBackingType(enumType), b.value.value)));
		});
	return immutable EnumOrFlagsTypeAndMembers(enumType, members);
}

immutable(bool) valueOverflows(immutable EnumBackingType type, immutable EnumValue value) {
	immutable long v = value.value;
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

immutable(EnumValue) maxValue(immutable EnumBackingType type) {
	return immutable EnumValue(() {
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
}

immutable(bool) isSignedEnumBackingType(immutable EnumBackingType a) {
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

immutable(EnumBackingType) defaultEnumBackingType() { return EnumBackingType.nat32; }

immutable(EnumBackingType) getEnumTypeFromType(
	ref CheckCtx ctx,
	ref immutable RangeWithinFile range,
	ref immutable CommonTypes commonTypes,
	immutable Type type,
) {
	immutable IntegralTypes integrals = commonTypes.integrals;
	return matchType!(immutable EnumBackingType)(
		type,
		(immutable Type.Bogus) =>
			defaultEnumBackingType(),
		(immutable Ptr!TypeParam) =>
			// enums can't have type params
			unreachable!EnumBackingType(),
		(immutable Ptr!StructInst it) =>
			ptrEquals(integrals.int8, it)
				? EnumBackingType.int8
				: ptrEquals(integrals.int16, it)
				? EnumBackingType.int16
				: ptrEquals(integrals.int32, it)
				? EnumBackingType.int32
				: ptrEquals(integrals.int64, it)
				? EnumBackingType.int64
				: ptrEquals(integrals.nat8, it)
				? EnumBackingType.nat8
				: ptrEquals(integrals.nat16, it)
				? EnumBackingType.nat16
				: ptrEquals(integrals.nat32, it)
				? EnumBackingType.nat32
				: ptrEquals(integrals.nat64, it)
				? EnumBackingType.nat64
				: (() {
					addDiag(ctx, range, immutable Diag(immutable Diag.EnumBackingTypeInvalid(it)));
					return defaultEnumBackingType();
				})());
}

immutable(StructBody.Record) checkRecord(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable Ptr!StructDecl struct_,
	immutable ModifierAst[] modifierAsts,
	ref immutable StructDeclAst.Body.Record r,
	ref MutArr!(Ptr!StructInst) delayStructInsts,
) {
	immutable RecordModifiers modifiers = checkRecordModifiers(ctx, modifierAsts);
	immutable bool forcedByVal = modifiers.byValOrRefOrNone == ForcedByValOrRefOrNone.byVal;
	if (struct_.deref().linkage != Linkage.internal && modifiers.byValOrRefOrNone == ForcedByValOrRefOrNone.none)
		addDiag(ctx, struct_.deref().range, immutable Diag(
				immutable Diag.ExternRecordMustBeByRefOrVal(struct_)));
	immutable RecordField[] fields = mapWithIndex(
		ctx.alloc,
		r.fields,
		(immutable size_t index, ref immutable StructDeclAst.Body.Record.Field field) =>
			checkRecordField(
				ctx, commonTypes, structsAndAliasesDict, delayStructInsts, struct_, forcedByVal, index, field));
	eachPair!RecordField(fields, (ref immutable RecordField a, ref immutable RecordField b) {
		if (symEq(a.name, b.name))
			addDiag(ctx, b.range, immutable Diag(
				immutable Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.recordField, a.name)));
	});
	return immutable StructBody.Record(
		immutable RecordFlags(
			recordNewVisibility(ctx, struct_.deref(), fields, modifiers.newVisibility),
			modifiers.packed,
			modifiers.byValOrRefOrNone),
		fields);
}

immutable(RecordField) checkRecordField(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref MutArr!(Ptr!StructInst) delayStructInsts,
	immutable Ptr!StructDecl struct_,
	immutable bool forcedByVal,
	immutable size_t index,
	ref immutable StructDeclAst.Body.Record.Field ast,
) {
	immutable Type fieldType = typeFromAst(
		ctx,
		commonTypes,
		ast.type,
		structsAndAliasesDict,
		TypeParamsScope(struct_.deref().typeParams),
		someMut(ptrTrustMe_mut(delayStructInsts)));
	checkReferenceLinkageAndPurity(ctx, struct_, ast.range, fieldType);
	if (ast.mutability != FieldMutability.const_) {
		immutable Opt!(Diag.MutFieldNotAllowed.Reason) reason =
			struct_.deref().purity != Purity.mut && !struct_.deref().purityIsForced
				? some(Diag.MutFieldNotAllowed.Reason.recordIsNotMut)
				: forcedByVal
				? some(Diag.MutFieldNotAllowed.Reason.recordIsForcedByVal)
				: none!(Diag.MutFieldNotAllowed.Reason);
		if (has(reason))
			addDiag(ctx, ast.range, immutable Diag(immutable Diag.MutFieldNotAllowed(force(reason))));
	}
	return immutable RecordField(
		rangeInFile(ctx, ast.range), ast.visibility, ast.name, ast.mutability, fieldType, index);
}

immutable(StructBody.Union) checkUnion(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	immutable Ptr!StructDecl struct_,
	ref immutable StructDeclAst.Body.Union ast,
	ref MutArr!(Ptr!StructInst) delayStructInsts,
) {
	final switch (struct_.deref().linkage) {
		case Linkage.internal:
			break;
		case Linkage.extern_:
			addDiag(ctx, struct_.deref().range, immutable Diag(immutable Diag.ExternUnion()));
	}
	immutable UnionMember[] members =
		map!UnionMember(ctx.alloc, ast.members, (ref immutable StructDeclAst.Body.Union.Member memberAst) =>
			checkUnionMember(ctx, commonTypes, structsAndAliasesDict, delayStructInsts, struct_, memberAst));
	eachPair!UnionMember(members, (ref immutable UnionMember a, ref immutable UnionMember b) {
		if (symEq(a.name, b.name))
			addDiag(ctx, b.range, immutable Diag(
				immutable Diag.DuplicateDeclaration(Diag.DuplicateDeclaration.Kind.unionMember, a.name)));
	});
	return immutable StructBody.Union(members);
}

immutable(UnionMember) checkUnionMember(
	ref CheckCtx ctx,
	ref immutable CommonTypes commonTypes,
	ref immutable StructsAndAliasesDict structsAndAliasesDict,
	ref MutArr!(Ptr!StructInst) delayStructInsts,
	immutable Ptr!StructDecl struct_,
	ref immutable StructDeclAst.Body.Union.Member ast,
) {
	immutable Opt!Type type = !has(ast.type) ? none!Type : some(typeFromAst(
		ctx,
		commonTypes,
		force(ast.type),
		structsAndAliasesDict,
		TypeParamsScope(struct_.deref().typeParams),
		someMut(ptrTrustMe_mut(delayStructInsts))));
	if (has(type))
		checkReferencePurity(ctx, struct_, ast.range, force(type));
	return immutable UnionMember(rangeInFile(ctx, ast.range), ast.name, type);
}

struct RecordModifiers {
	immutable ForcedByValOrRefOrNone byValOrRefOrNone;
	immutable Opt!Visibility newVisibility;
	immutable bool packed;
}

immutable(RecordModifiers) withByValOrRef(
	ref CheckCtx ctx,
	immutable RecordModifiers cur,
	immutable RangeWithinFile range,
	immutable ForcedByValOrRefOrNone value,
) {
	if (cur.byValOrRefOrNone != ForcedByValOrRefOrNone.none) {
		immutable Sym valueSym = symOfForcedByValOrRefOrNone(value);
		addDiag(ctx, range, value == cur.byValOrRefOrNone
			? immutable Diag(immutable Diag.ModifierDuplicate(valueSym))
			: immutable Diag(
				immutable Diag.ModifierConflict(symOfForcedByValOrRefOrNone(cur.byValOrRefOrNone), valueSym)));
	}
	return immutable RecordModifiers(value, cur.newVisibility, cur.packed);
}

immutable(RecordModifiers) withNewVisibility(
	ref CheckCtx ctx,
	immutable RecordModifiers cur,
	immutable RangeWithinFile range,
	immutable Visibility value,
) {
	if (has(cur.newVisibility)) {
		immutable Sym valueSym = symOfNewVisibility(value);
		addDiag(ctx, range, value == force(cur.newVisibility)
			? immutable Diag(immutable Diag.ModifierDuplicate(valueSym))
			: immutable Diag(immutable Diag.ModifierConflict(symOfNewVisibility(force(cur.newVisibility)), valueSym)));
	}
	return immutable RecordModifiers(cur.byValOrRefOrNone, some(value), cur.packed);
}

immutable(Sym) symOfNewVisibility(immutable Visibility a) {
	final switch (a) {
		case Visibility.private_:
			return symForSpecial(SpecialSym.dotNew);
		case Visibility.public_:
			return shortSym("new");
	}
}

immutable(RecordModifiers) withPacked(
	ref CheckCtx ctx,
	immutable RecordModifiers cur,
	immutable RangeWithinFile range,
) {
	if (cur.packed)
		addDiag(ctx, range, immutable Diag(immutable Diag.ModifierDuplicate(shortSym("packed"))));
	return immutable RecordModifiers(cur.byValOrRefOrNone, cur.newVisibility, true);
}

immutable(RecordModifiers) checkRecordModifiers(ref CheckCtx ctx, immutable ModifierAst[] modifiers) {
	return fold(
		immutable RecordModifiers(ForcedByValOrRefOrNone.none, none!Visibility, false),
		modifiers,
		(immutable RecordModifiers cur, ref immutable ModifierAst modifier) {
			immutable RangeWithinFile range = rangeOfModifierAst(modifier, ctx.allSymbols);
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
				case ModifierAst.Kind.forceData:
				case ModifierAst.Kind.forceSendable:
				case ModifierAst.Kind.mut:
				case ModifierAst.Kind.sendable:
					// already handled in getPurityFromModifiers
					return cur;
			}
		});
}

void checkReferenceLinkageAndPurity(
	ref CheckCtx ctx,
	immutable Ptr!StructDecl struct_,
	immutable RangeWithinFile range,
	immutable Type referencedType,
) {
	if (!isLinkagePossiblyCompatible(struct_.deref().linkage, linkageRange(referencedType)))
		addDiag(ctx, range, immutable Diag(
			immutable Diag.LinkageWorseThanContainingType(struct_, referencedType)));
	checkReferencePurity(ctx, struct_, range, referencedType);
}

void checkReferencePurity(
	ref CheckCtx ctx,
	immutable Ptr!StructDecl struct_,
	immutable RangeWithinFile range,
	immutable Type referencedType,
) {
	if (!isPurityPossiblyCompatible(struct_.deref().purity, purityRange(referencedType)) &&
		!struct_.deref().purityIsForced)
		addDiag(ctx, range, immutable Diag(immutable Diag.PurityWorseThanParent(struct_, referencedType)));
}

immutable(Visibility) recordNewVisibility(
	ref CheckCtx ctx,
	ref immutable StructDecl struct_,
	scope immutable RecordField[] fields,
	immutable Opt!Visibility explicit,
) {
	immutable Visibility default_ = fold(
		struct_.visibility,
		fields,
		(immutable Visibility cur, ref immutable RecordField field) =>
			leastVisibility(cur, field.visibility));
	if (has(explicit)) {
		if (force(explicit) == default_)
			//TODO: better range
			addDiag(ctx, struct_.range, immutable Diag(
				immutable Diag.RecordNewVisibilityIsRedundant(default_)));
		return force(explicit);
	} else
		return default_;
}
