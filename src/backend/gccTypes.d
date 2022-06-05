module backend.gccTypes;

@safe @nogc pure nothrow:

import backend.libgccjit :
	gcc_jit_binary_op,
	gcc_jit_block,
	gcc_jit_block_end_with_return,
	gcc_jit_comparison,
	gcc_jit_context,
	gcc_jit_context_get_type,
	gcc_jit_context_new_binary_op,
	gcc_jit_context_new_cast,
	gcc_jit_context_new_comparison,
	gcc_jit_context_new_field,
	gcc_jit_context_new_function,
	gcc_jit_context_new_function_ptr_type,
	gcc_jit_context_new_opaque_struct,
	gcc_jit_context_new_rvalue_from_long,
	gcc_jit_context_new_struct_type,
	gcc_jit_context_new_union_type,
	gcc_jit_field,
	gcc_jit_function,
	gcc_jit_function_kind,
	gcc_jit_function_new_block,
	gcc_jit_function_new_local,
	gcc_jit_lvalue,
	gcc_jit_lvalue_access_field,
	gcc_jit_lvalue_get_address,
	gcc_jit_rvalue,
	gcc_jit_struct,
	gcc_jit_struct_as_type,
	gcc_jit_struct_set_fields,
	gcc_jit_type,
	gcc_jit_type_get_pointer,
	gcc_jit_types;
import backend.mangle : MangledNames, writeStructMangledName;
import backend.writeTypes : TypeWriters, writeTypes;
import model.concreteModel : ConcreteStruct;
import model.lowModel :
	debugName,
	LowExternPtrType,
	LowField,
	LowFunPtrType,
	LowProgram,
	LowPtrCombine,
	LowRecord,
	LowType,
	LowUnion,
	matchLowTypeCombinePtr,
	PrimitiveType;
import util.alloc.alloc : Alloc;
import util.col.arr : empty;
import util.col.arrUtil : map, mapWithIndex, zip;
import util.col.fullIndexDict :
	FullIndexDict,
	fullIndexDictCastImmutable,
	fullIndexDictCastImmutable2,
	fullIndexDictZip3,
	mapFullIndexDict,
	mapFullIndexDict_mut;
import util.col.str : CStr;
import util.opt : force, has, none, noneMut, Opt, some, someMut;
import util.ptr : castImmutable, ptrTrustMe_mut;
import util.sym : AllSymbols, writeSym;
import util.util : as, verify;
import util.writer : finishWriterToCStr, Writer;

struct GccTypes {
	private:
	immutable gcc_jit_type*[PrimitiveType.max + 1] primitiveTypes;
	immutable FullIndexDict!(LowType.ExternPtr, gcc_jit_type*) externPtrs;
	immutable FullIndexDict!(LowType.FunPtr, gcc_jit_type*) funPtrs;
	immutable FullIndexDict!(LowType.Record, gcc_jit_struct*) records;
	public immutable FullIndexDict!(LowType.Record, gcc_jit_field*[]) recordFields;
	immutable FullIndexDict!(LowType.Union, gcc_jit_struct*) unions;
	public immutable FullIndexDict!(LowType.Union, UnionFields) unionFields;
}

struct UnionFields {
	immutable gcc_jit_field* kindField;
	immutable gcc_jit_field* innerField;
	immutable gcc_jit_field*[] memberFields;
}

immutable(GccTypes) getGccTypes(
	ref Alloc alloc,
	ref gcc_jit_context ctx,
	ref const AllSymbols allSymbols,
	ref immutable LowProgram program,
	ref immutable MangledNames mangledNames,
) {
	GccTypesWip typesWip = GccTypesWip(
		getPrimitiveTypes(ctx),
		gccExternPtrTypes(alloc, ctx, program, mangledNames),
		mapFullIndexDict_mut!(LowType.FunPtr, Opt!(gcc_jit_type*), LowFunPtrType)(
			alloc,
			program.allFunPtrTypes,
			(immutable LowType.FunPtr, ref immutable LowFunPtrType) =>
				noneMut!(gcc_jit_type*)),
		mapFullIndexDict_mut!(LowType.Record, gcc_jit_struct*, LowRecord)(
			alloc,
			program.allRecords,
			(immutable LowType.Record, scope ref immutable LowRecord record) =>
				structStub(alloc, ctx, mangledNames, record.source)),
		mapFullIndexDict_mut!(LowType.Record, immutable gcc_jit_field*[], LowRecord)(
			alloc,
			program.allRecords,
			(immutable LowType.Record, ref immutable LowRecord record) => 
				as!(immutable gcc_jit_field*[])([])),
		mapFullIndexDict_mut!(LowType.Union, gcc_jit_struct*, LowUnion)(
			alloc,
			program.allUnions,
			(immutable LowType.Union, ref immutable LowUnion union_) =>
				structStub(alloc, ctx, mangledNames, union_.source)),
		mapFullIndexDict_mut!(LowType.Union, immutable Opt!UnionFields, LowUnion)(
			alloc,
			program.allUnions,
			(immutable LowType.Union, ref immutable LowUnion) =>
				none!UnionFields));

	scope immutable TypeWriters writers = immutable TypeWriters(
		(immutable ConcreteStruct*) {
			// Do nothing, we declared types ahead of time.
		},
		(immutable LowType.FunPtr funPtrIndex, ref immutable LowFunPtrType funPtr) {
			writeFunPtrType(alloc, ctx, typesWip, funPtrIndex, funPtr);
		},
		(immutable LowType.Record recordIndex, ref immutable LowRecord record) {
			writeRecordType(alloc, ctx, typesWip, allSymbols, recordIndex, record);
		},
		(immutable LowType.Union unionIndex, ref immutable LowUnion union_) {
			writeUnionType(alloc, ctx, mangledNames, typesWip, unionIndex, union_);
		});
	writeTypes(alloc, program, writers);

	return immutable GccTypes(
		typesWip.primitiveTypes,
		typesWip.externPtrs,
		//TODO:PERF just cast, since Opt!Ptr and Ptr representations are the same
		mapFullIndexDict!(LowType.FunPtr, gcc_jit_type*, Opt!(gcc_jit_type*))(
			alloc,
			fullIndexDictCastImmutable(typesWip.funPtrs),
			(immutable LowType.FunPtr, scope ref immutable Opt!(gcc_jit_type*) a) =>
				force(a)),
		fullIndexDictCastImmutable(typesWip.records),
		fullIndexDictCastImmutable2!(LowType.Record, gcc_jit_field*[])(typesWip.recordFields),
		fullIndexDictCastImmutable(typesWip.unions),
		mapFullIndexDict!(LowType.Union, UnionFields, Opt!UnionFields)(
			alloc,
			fullIndexDictCastImmutable2(typesWip.unionFields),
			(immutable LowType.Union, scope ref immutable Opt!UnionFields it) =>
				force(it)));
}

immutable char* assertFieldOffsetsFunctionName = "__assertFieldOffsets";

extern(C) {
	alias AssertFieldOffsetsType = bool function();
}

//TODO: this is just for debugging
immutable(gcc_jit_function*) generateAssertFieldOffsetsFunction(
	ref Alloc alloc,
	ref gcc_jit_context ctx,
	ref immutable LowProgram program,
	ref immutable GccTypes types,
) {
	immutable gcc_jit_type* boolType = getGccType(types, immutable LowType(PrimitiveType.bool_));
	immutable gcc_jit_type* nat64Type = getGccType(types, immutable LowType(PrimitiveType.nat64));
	immutable gcc_jit_type* voidPtrType = gcc_jit_context_get_type(ctx, gcc_jit_types.GCC_JIT_TYPE_VOID_PTR);

	gcc_jit_function* fn = gcc_jit_context_new_function(
		ctx,
		null,
		gcc_jit_function_kind.GCC_JIT_FUNCTION_EXPORTED,
		boolType,
		assertFieldOffsetsFunctionName,
		0,
		null,
		false);

	immutable(gcc_jit_rvalue)* accum = gcc_jit_context_new_rvalue_from_long(ctx, boolType, 1);
	fullIndexDictZip3!(LowType.Record, LowRecord, gcc_jit_struct*, gcc_jit_field*[])(
		program.allRecords,
		types.records,
		types.recordFields,
		(immutable LowType.Record,
		 ref immutable LowRecord record,
		 ref immutable gcc_jit_struct* gccRecord,
		 ref immutable gcc_jit_field*[] gccFields) {
			gcc_jit_lvalue* local = gcc_jit_function_new_local(fn, null, gcc_jit_struct_as_type(gccRecord), "temp");
			immutable gcc_jit_rvalue* recordAddress = gcc_jit_context_new_cast(
				ctx,
				null,
				gcc_jit_lvalue_get_address(local, null),
				voidPtrType);
			zip!(LowField, gcc_jit_field*)(
				record.fields,
				gccFields,
				(ref immutable LowField field, ref immutable gcc_jit_field* gccField) {
					immutable gcc_jit_rvalue* fieldAddress = gcc_jit_context_new_cast(
						ctx,
						null,
						gcc_jit_lvalue_get_address(gcc_jit_lvalue_access_field(local, null, gccField), null),
						voidPtrType);
					immutable gcc_jit_rvalue* actualOffset = gcc_jit_context_new_binary_op(
						ctx,
						null,
						//TODO: pointer subtraction?
						gcc_jit_binary_op.GCC_JIT_BINARY_OP_MINUS,
						nat64Type,
						fieldAddress,
						recordAddress);
					immutable gcc_jit_rvalue* expectedOffset =
						gcc_jit_context_new_rvalue_from_long(ctx, nat64Type, field.offset);
					immutable gcc_jit_rvalue* eq = gcc_jit_context_new_comparison(
						ctx,
						null,
						gcc_jit_comparison.GCC_JIT_COMPARISON_EQ,
						actualOffset,
						expectedOffset);
					accum = gcc_jit_context_new_binary_op(
						ctx, null, gcc_jit_binary_op.GCC_JIT_BINARY_OP_LOGICAL_OR, boolType, accum, eq);
				});
		});

	gcc_jit_block* block = gcc_jit_function_new_block(fn, null);
	gcc_jit_block_end_with_return(block, null, accum);

	return castImmutable(fn);
}

immutable(gcc_jit_type*) getGccType(ref immutable GccTypes types, scope immutable LowType a) {
	immutable gcc_jit_type* res = matchLowTypeCombinePtr!(
		immutable gcc_jit_type*,
		(immutable LowType.ExternPtr x) =>
			types.externPtrs[x],
		(immutable LowType.FunPtr x) =>
			types.funPtrs[x],
		(immutable PrimitiveType it) =>
			types.primitiveTypes[it],
		(immutable LowPtrCombine it) =>
			gcc_jit_type_get_pointer(getGccType(types, it.pointee)),
		(immutable LowType.Record x) =>
			gcc_jit_struct_as_type(types.records[x]),
		(immutable LowType.Union x) =>
			gcc_jit_struct_as_type(types.unions[x]),
	)(a);
	verify(res != null);
	return res;
}

private:

immutable(gcc_jit_type*) getGccType(ref GccTypesWip typesWip, immutable LowType a) {
	immutable gcc_jit_type* res = matchLowTypeCombinePtr!(
		immutable gcc_jit_type*,
		(immutable LowType.ExternPtr x) =>
			typesWip.externPtrs[x],
		(immutable LowType.FunPtr x) =>
			castImmutable(force(typesWip.funPtrs[x])),
		(immutable PrimitiveType it) =>
			typesWip.primitiveTypes[it],
		(immutable LowPtrCombine it) =>
			gcc_jit_type_get_pointer(getGccType(typesWip, it.pointee)),
		(immutable LowType.Record x) =>
			gcc_jit_struct_as_type(typesWip.records[x]),
		(immutable LowType.Union x) =>
			gcc_jit_struct_as_type(typesWip.unions[x]),
	)(a);
	verify(res != null);
	return res;
}

@trusted immutable(gcc_jit_type*[PrimitiveType.max + 1]) getPrimitiveTypes(ref gcc_jit_context ctx) {
	gcc_jit_type*[PrimitiveType.max + 1] res;
	foreach (immutable size_t i; cast(size_t) PrimitiveType.min .. cast(size_t) PrimitiveType.max + 1)
		res[i] = cast(gcc_jit_type*) getOnePrimitiveType(ctx, cast(immutable PrimitiveType) i);
	return cast(immutable gcc_jit_type*[PrimitiveType.max + 1]) res;
}

immutable(gcc_jit_type*) getOnePrimitiveType(ref gcc_jit_context ctx, immutable PrimitiveType a) {
	final switch (a) {
		case PrimitiveType.bool_:
			return gcc_jit_context_get_type(ctx, gcc_jit_types.GCC_JIT_TYPE_BOOL);
		case PrimitiveType.char8:
			return gcc_jit_context_get_type(ctx, gcc_jit_types.GCC_JIT_TYPE_CHAR);
		case PrimitiveType.float32:
			return gcc_jit_context_get_type(ctx, gcc_jit_types.GCC_JIT_TYPE_FLOAT);
		case PrimitiveType.float64:
			return gcc_jit_context_get_type(ctx, gcc_jit_types.GCC_JIT_TYPE_DOUBLE);
		case PrimitiveType.int8:
			return gcc_jit_context_get_type(ctx, gcc_jit_types.GCC_JIT_TYPE_CHAR);
		case PrimitiveType.int16:
			return gcc_jit_context_get_type(ctx, gcc_jit_types.GCC_JIT_TYPE_SHORT);
		case PrimitiveType.int32:
			return gcc_jit_context_get_type(ctx, gcc_jit_types.GCC_JIT_TYPE_INT);
		case PrimitiveType.int64:
			return gcc_jit_context_get_type(ctx, gcc_jit_types.GCC_JIT_TYPE_LONG);
		case PrimitiveType.nat8:
			return gcc_jit_context_get_type(ctx, gcc_jit_types.GCC_JIT_TYPE_UNSIGNED_CHAR);
		case PrimitiveType.nat16:
			return gcc_jit_context_get_type(ctx, gcc_jit_types.GCC_JIT_TYPE_UNSIGNED_SHORT);
		case PrimitiveType.nat32:
			return gcc_jit_context_get_type(ctx, gcc_jit_types.GCC_JIT_TYPE_UNSIGNED_INT);
		case PrimitiveType.nat64:
			return gcc_jit_context_get_type(ctx, gcc_jit_types.GCC_JIT_TYPE_UNSIGNED_LONG);
		case PrimitiveType.void_:
			return gcc_jit_struct_as_type(gcc_jit_context_new_struct_type(ctx, null, "void", 0, null));
	}
}

struct GccTypesWip {
	immutable gcc_jit_type*[PrimitiveType.max + 1] primitiveTypes;
	immutable FullIndexDict!(LowType.ExternPtr, gcc_jit_type*) externPtrs;
	FullIndexDict!(LowType.FunPtr, Opt!(gcc_jit_type*)) funPtrs;
	FullIndexDict!(LowType.Record, gcc_jit_struct*) records;
	FullIndexDict!(LowType.Record, immutable gcc_jit_field*[]) recordFields;
	FullIndexDict!(LowType.Union, gcc_jit_struct*) unions;
	FullIndexDict!(LowType.Union, immutable Opt!UnionFields) unionFields;
}

@trusted void writeFunPtrType(
	ref Alloc alloc,
	ref gcc_jit_context ctx,
	ref GccTypesWip typesWip,
	immutable LowType.FunPtr funPtrIndex,
	ref immutable LowFunPtrType funPtr,
) {
	Opt!(gcc_jit_type*)* ptr = &typesWip.funPtrs[funPtrIndex];
	verify(!has(*ptr));
	const gcc_jit_type* returnType = getGccType(typesWip, funPtr.returnType);
	//TODO:NO ALLOC
	immutable gcc_jit_type*[] paramTypes = map!(gcc_jit_type*, LowType)(
		alloc,
		funPtr.paramTypes,
		(ref immutable LowType x) =>
			getGccType(typesWip, x));
	*ptr = someMut!(gcc_jit_type*)(gcc_jit_context_new_function_ptr_type(
		ctx,
		null,
		returnType,
		cast(int) paramTypes.length,
		paramTypes.ptr,
		false));
}

@trusted void writeRecordType(
	ref Alloc alloc,
	ref gcc_jit_context ctx,
	ref GccTypesWip typesWip,
	ref const AllSymbols allSymbols,
	immutable LowType.Record recordIndex,
	ref immutable LowRecord record,
) {
	gcc_jit_struct* struct_ = typesWip.records[recordIndex];
	immutable gcc_jit_field*[] fields = map!(gcc_jit_field*, LowField)(
		alloc,
		record.fields,
		(ref immutable LowField field) {
			//TODO:NO ALLOC
			Writer writer = Writer(ptrTrustMe_mut(alloc));
			writeSym(writer, allSymbols, debugName(field));
			return gcc_jit_context_new_field(ctx, null, getGccType(typesWip, field.type), finishWriterToCStr(writer));
		});
	verify(empty(typesWip.recordFields[recordIndex]));
	typesWip.recordFields[recordIndex] = fields;
	gcc_jit_struct_set_fields(struct_, null, cast(int) fields.length, fields.ptr);
}

@trusted void writeUnionType(
	ref Alloc alloc,
	ref gcc_jit_context ctx,
	ref immutable MangledNames mangledNames,
	ref GccTypesWip typesWip,
	immutable LowType.Union unionIndex,
	ref immutable LowUnion union_,
) {
	gcc_jit_struct* struct_ = typesWip.unions[unionIndex];

	//TODO:NO ALLOC
	immutable CStr mangledNameInner = () {
		Writer writer = Writer(ptrTrustMe_mut(alloc));
		writeStructMangledName(writer, mangledNames, union_.source);
		writer ~= "_inner";
		return finishWriterToCStr(writer);
	}();

	immutable gcc_jit_field*[] memberFields = mapWithIndex!(gcc_jit_field*, LowType)(
		alloc,
		union_.members,
		(immutable size_t memberIndex, ref immutable LowType memberType) {
			//TODO:NO ALLOC
			Writer writer = Writer(ptrTrustMe_mut(alloc));
			writer ~= "as";
			writer ~= memberIndex;
			return gcc_jit_context_new_field(ctx, null, getGccType(typesWip, memberType), finishWriterToCStr(writer));
		});
	immutable gcc_jit_type* innerUnion = gcc_jit_context_new_union_type(
		ctx,
		null,
		mangledNameInner,
		cast(int) memberFields.length,
		memberFields.ptr);

	immutable gcc_jit_field* kindField =
		gcc_jit_context_new_field(ctx, null, getGccType(typesWip, immutable LowType(PrimitiveType.nat64)), "kind");
	immutable gcc_jit_field* innerField = gcc_jit_context_new_field(ctx, null, innerUnion, "inner");
	scope immutable gcc_jit_field*[2] outerFields = [kindField, innerField];
	gcc_jit_struct_set_fields(struct_, null, 2, outerFields.ptr);
	verify(!has(typesWip.unionFields[unionIndex]));
	typesWip.unionFields[unionIndex] = some(immutable UnionFields(kindField, innerField, memberFields));
}

immutable(FullIndexDict!(LowType.ExternPtr, gcc_jit_type*)) gccExternPtrTypes(
	ref Alloc alloc,
	ref gcc_jit_context ctx,
	ref immutable LowProgram program,
	ref immutable MangledNames mangledNames,
) {
	return mapFullIndexDict!(LowType.ExternPtr, gcc_jit_type*, LowExternPtrType)(
		alloc,
		program.allExternPtrTypes,
		(immutable LowType.ExternPtr, ref immutable LowExternPtrType extern_) =>
			gcc_jit_type_get_pointer(gcc_jit_struct_as_type(
				castImmutable(structStub(alloc, ctx, mangledNames, extern_.source)))));
}

gcc_jit_struct* structStub(
	ref Alloc alloc,
	ref gcc_jit_context ctx,
	ref immutable MangledNames mangledNames,
	scope immutable ConcreteStruct* source,
) {
	//TODO:PERF use a temporary (dont' allocate string)
	Writer writer = Writer(ptrTrustMe_mut(alloc));
	writeStructMangledName(writer, mangledNames, source);
	return gcc_jit_context_new_opaque_struct(ctx, null, finishWriterToCStr(writer));
}
