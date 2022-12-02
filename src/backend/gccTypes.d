module backend.gccTypes;

@safe @nogc pure nothrow:

import backend.libgccjit :
	gcc_jit_binary_op,
	gcc_jit_block,
	gcc_jit_block_end_with_return,
	gcc_jit_comparison,
	gcc_jit_context,
	gcc_jit_context_get_type,
	gcc_jit_context_new_array_type,
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
import backend.writeTypes : ElementAndCount, getElementAndCountForExtern, TypeWriters, writeTypes;
import model.concreteModel : ConcreteStruct;
import model.lowModel :
	debugName,
	LowExternType,
	LowField,
	LowFunPtrType,
	LowProgram,
	LowPtrCombine,
	LowRecord,
	LowType,
	LowUnion,
	PrimitiveType,
	typeSize;
import util.alloc.alloc : Alloc;
import util.col.arr : empty;
import util.col.arrUtil : map, mapWithIndex, zip;
import util.col.enumDict : EnumDict, makeEnumDict;
import util.col.fullIndexDict :
	FullIndexDict,
	fullIndexDictCastImmutable,
	fullIndexDictCastImmutable2,
	fullIndexDictZip3,
	mapFullIndexDict,
	mapFullIndexDict_mut;
import util.col.str : CStr;
import util.conv : safeToInt;
import util.opt : force, has, MutOpt, none, noneMut, Opt, some, someMut;
import util.ptr : castImmutable, castNonScope_ref, ptrTrustMe;
import util.sym : AllSymbols, writeSym;
import util.util : typeAs, verify;
import util.writer : finishWriterToCStr, Writer;

immutable struct GccTypes {
	private:
	GccPrimitiveTypes primitiveTypes;
	public GccExternTypes extern_;
	FullIndexDict!(LowType.FunPtr, gcc_jit_type*) funPtrs;
	FullIndexDict!(LowType.Record, gcc_jit_struct*) records;
	public FullIndexDict!(LowType.Record, gcc_jit_field*[]) recordFields;
	FullIndexDict!(LowType.Union, gcc_jit_struct*) unions;
	public FullIndexDict!(LowType.Union, UnionFields) unionFields;
}

private alias GccPrimitiveTypes = immutable EnumDict!(PrimitiveType, gcc_jit_type*);
private alias GccExternTypes = immutable FullIndexDict!(LowType.Extern, ExternTypeInfo);

immutable struct ExternTypeInfo {
	gcc_jit_type* type;
	Opt!ExternTypeArrayInfo array;
}
immutable struct ExternTypeArrayInfo {
	gcc_jit_field* field;
	gcc_jit_type* gccArrayType;
	ElementAndCount elementAndCount;
}

immutable struct UnionFields {
	gcc_jit_field* kindField;
	gcc_jit_field* innerField;
	gcc_jit_field*[] memberFields;
}

GccTypes getGccTypes(
	ref Alloc alloc,
	ref gcc_jit_context ctx,
	in AllSymbols allSymbols,
	in LowProgram program,
	in MangledNames mangledNames,
) {
	GccTypesWip typesWip = GccTypesWip(
		getPrimitiveTypes(ctx),
		gccExternTypes(alloc, ctx, program, mangledNames),
		mapFullIndexDict_mut!(LowType.FunPtr, MutOpt!(gcc_jit_type*), LowFunPtrType)(
			alloc,
			program.allFunPtrTypes,
			(LowType.FunPtr, ref LowFunPtrType) =>
				noneMut!(gcc_jit_type*)),
		mapFullIndexDict_mut!(LowType.Record, gcc_jit_struct*, LowRecord)(
			alloc,
			program.allRecords,
			(LowType.Record, scope ref LowRecord record) =>
				structStub(alloc, ctx, mangledNames, record.source)),
		mapFullIndexDict_mut!(LowType.Record, immutable gcc_jit_field*[], LowRecord)(
			alloc,
			program.allRecords,
			(LowType.Record, ref LowRecord record) => 
				typeAs!(immutable gcc_jit_field*[])([])),
		mapFullIndexDict_mut!(LowType.Union, gcc_jit_struct*, LowUnion)(
			alloc,
			program.allUnions,
			(LowType.Union, ref LowUnion union_) =>
				structStub(alloc, ctx, mangledNames, union_.source)),
		mapFullIndexDict_mut!(LowType.Union, Opt!UnionFields, LowUnion)(
			alloc,
			program.allUnions,
			(LowType.Union, ref LowUnion) =>
				none!UnionFields));

	scope TypeWriters writers = TypeWriters(
		(ConcreteStruct*) {
			// Do nothing, we declared types ahead of time.
		},
		(ConcreteStruct* source, in Opt!ElementAndCount) {
			// Declared ahead of time
		},
		(LowType.FunPtr funPtrIndex, in LowFunPtrType funPtr) {
			writeFunPtrType(alloc, ctx, typesWip, funPtrIndex, funPtr);
		},
		(LowType.Record recordIndex, in LowRecord record) {
			writeRecordType(alloc, ctx, typesWip, allSymbols, recordIndex, record);
		},
		(LowType.Union unionIndex, in LowUnion union_) {
			writeUnionType(alloc, ctx, mangledNames, typesWip, unionIndex, union_);
		});
	writeTypes(alloc, program, writers);

	return GccTypes(
		typesWip.primitiveTypes,
		typesWip.extern_,
		//TODO:PERF just cast, since Opt!Ptr and Ptr representations are the same
		mapFullIndexDict!(LowType.FunPtr, gcc_jit_type*, MutOpt!(gcc_jit_type*))(
			alloc,
			fullIndexDictCastImmutable(typesWip.funPtrs),
			(LowType.FunPtr, scope ref immutable MutOpt!(gcc_jit_type*) a) =>
				force(a)),
		fullIndexDictCastImmutable(typesWip.records),
		fullIndexDictCastImmutable2!(LowType.Record, gcc_jit_field*[])(typesWip.recordFields),
		fullIndexDictCastImmutable(typesWip.unions),
		mapFullIndexDict!(LowType.Union, UnionFields, MutOpt!UnionFields)(
			alloc,
			fullIndexDictCastImmutable2(typesWip.unionFields),
			(LowType.Union, scope ref Opt!UnionFields it) =>
				force(it)));
}

immutable char* assertFieldOffsetsFunctionName = "__assertFieldOffsets";

extern(C) {
	alias AssertFieldOffsetsType = immutable bool function();
}

//TODO: this is just for debugging
immutable(gcc_jit_function*) generateAssertFieldOffsetsFunction(
	ref Alloc alloc,
	ref gcc_jit_context ctx,
	in LowProgram program,
	in GccTypes types,
) {
	immutable gcc_jit_type* boolType = getGccType(types, LowType(PrimitiveType.bool_));
	immutable gcc_jit_type* nat64Type = getGccType(types, LowType(PrimitiveType.nat64));
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

	gcc_jit_rvalue* accum = gcc_jit_context_new_rvalue_from_long(ctx, boolType, 1);
	fullIndexDictZip3!(LowType.Record, LowRecord, gcc_jit_struct*, gcc_jit_field*[])(
		program.allRecords,
		types.records,
		types.recordFields,
		(LowType.Record,
		 ref LowRecord record,
		 ref immutable gcc_jit_struct* gccRecord,
		 ref immutable gcc_jit_field*[] gccFields) {
			gcc_jit_lvalue* local = gcc_jit_function_new_local(fn, null, gcc_jit_struct_as_type(gccRecord), "temp");
			gcc_jit_rvalue* recordAddress = gcc_jit_context_new_cast(
				ctx,
				null,
				gcc_jit_lvalue_get_address(local, null),
				voidPtrType);
			zip!(LowField, immutable gcc_jit_field*)(
				record.fields,
				gccFields,
				(ref LowField field, ref immutable gcc_jit_field* gccField) {
					gcc_jit_rvalue* fieldAddress = gcc_jit_context_new_cast(
						ctx,
						null,
						gcc_jit_lvalue_get_address(gcc_jit_lvalue_access_field(local, null, gccField), null),
						voidPtrType);
					gcc_jit_rvalue* actualOffset = gcc_jit_context_new_binary_op(
						ctx,
						null,
						//TODO: pointer subtraction?
						gcc_jit_binary_op.GCC_JIT_BINARY_OP_MINUS,
						nat64Type,
						fieldAddress,
						recordAddress);
					gcc_jit_rvalue* expectedOffset =
						gcc_jit_context_new_rvalue_from_long(ctx, nat64Type, field.offset);
					gcc_jit_rvalue* eq = gcc_jit_context_new_comparison(
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

immutable(gcc_jit_type*) getGccType(in GccTypes types, in LowType a) =>
	a.combinePointer.matchIn!(immutable gcc_jit_type*)(
		(in LowType.Extern x) =>
			types.extern_[x].type,
		(in LowType.FunPtr x) =>
			types.funPtrs[x],
		(in PrimitiveType it) =>
			types.primitiveTypes[it],
		(in LowPtrCombine it) =>
			gcc_jit_type_get_pointer(getGccType(types, it.pointee)),
		(in LowType.Record x) =>
			gcc_jit_struct_as_type(types.records[x]),
		(in LowType.Union x) =>
			gcc_jit_struct_as_type(types.unions[x]));

private:

immutable(gcc_jit_type*) getGccType(ref GccTypesWip typesWip, LowType a) =>
	a.combinePointer.match!(immutable gcc_jit_type*)(
		(LowType.Extern x) =>
			typesWip.extern_[x].type,
		(LowType.FunPtr x) =>
			castImmutable(force(typesWip.funPtrs[x])),
		(PrimitiveType it) =>
			typesWip.primitiveTypes[it],
		(LowPtrCombine it) =>
			gcc_jit_type_get_pointer(getGccType(typesWip, it.pointee)),
		(LowType.Record x) =>
			gcc_jit_struct_as_type(typesWip.records[x]),
		(LowType.Union x) =>
			gcc_jit_struct_as_type(typesWip.unions[x]));

GccPrimitiveTypes getPrimitiveTypes(ref gcc_jit_context ctx) =>
	makeEnumDict!(PrimitiveType, gcc_jit_type*)((PrimitiveType type) =>
		getOnePrimitiveType(ctx, type));

immutable(gcc_jit_type*) getOnePrimitiveType(ref gcc_jit_context ctx, PrimitiveType a) {
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
	immutable GccPrimitiveTypes primitiveTypes;
	immutable GccExternTypes extern_;
	FullIndexDict!(LowType.FunPtr, MutOpt!(gcc_jit_type*)) funPtrs;
	FullIndexDict!(LowType.Record, gcc_jit_struct*) records;
	FullIndexDict!(LowType.Record, immutable gcc_jit_field*[]) recordFields;
	FullIndexDict!(LowType.Union, gcc_jit_struct*) unions;
	FullIndexDict!(LowType.Union, Opt!UnionFields) unionFields;
}

@trusted void writeFunPtrType(
	ref Alloc alloc,
	ref gcc_jit_context ctx,
	ref GccTypesWip typesWip,
	LowType.FunPtr funPtrIndex,
	in LowFunPtrType funPtr,
) {
	MutOpt!(gcc_jit_type*)* ptr = &typesWip.funPtrs[funPtrIndex];
	verify(!has(*ptr));
	const gcc_jit_type* returnType = getGccType(typesWip, funPtr.returnType);
	//TODO:NO ALLOC
	immutable gcc_jit_type*[] paramTypes = map(alloc, funPtr.paramTypes, (ref LowType x) =>
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
	in AllSymbols allSymbols,
	LowType.Record recordIndex,
	in LowRecord record,
) {
	gcc_jit_struct* struct_ = typesWip.records[recordIndex];
	immutable gcc_jit_field*[] fields = map(alloc, record.fields, (ref LowField field) {
		//TODO:NO ALLOC
		Writer writer = Writer(ptrTrustMe(alloc));
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
	in MangledNames mangledNames,
	ref GccTypesWip typesWip,
	LowType.Union unionIndex,
	in LowUnion union_,
) {
	gcc_jit_struct* struct_ = typesWip.unions[unionIndex];

	//TODO:NO ALLOC
	CStr mangledNameInner = () {
		Writer writer = Writer(ptrTrustMe(alloc));
		writeStructMangledName(writer, mangledNames, union_.source);
		writer ~= "_inner";
		return finishWriterToCStr(writer);
	}();

	immutable gcc_jit_field*[] memberFields = mapWithIndex!(immutable gcc_jit_field*, LowType)(
		alloc,
		union_.members,
		(size_t memberIndex, ref LowType memberType) {
			//TODO:NO ALLOC
			Writer writer = Writer(ptrTrustMe(alloc));
			writer ~= "as";
			writer ~= memberIndex;
			return gcc_jit_context_new_field(
				ctx, null, getGccType(typesWip, castNonScope_ref(memberType)), finishWriterToCStr(writer));
		});
	immutable gcc_jit_type* innerUnion = gcc_jit_context_new_union_type(
		ctx,
		null,
		mangledNameInner,
		cast(int) memberFields.length,
		memberFields.ptr);

	immutable gcc_jit_field* kindField =
		gcc_jit_context_new_field(ctx, null, getGccType(typesWip, LowType(PrimitiveType.nat64)), "kind");
	immutable gcc_jit_field* innerField = gcc_jit_context_new_field(ctx, null, innerUnion, "inner");
	scope immutable gcc_jit_field*[2] outerFields = [kindField, innerField];
	gcc_jit_struct_set_fields(struct_, null, 2, outerFields.ptr);
	verify(!has(typesWip.unionFields[unionIndex]));
	typesWip.unionFields[unionIndex] = some(UnionFields(kindField, innerField, memberFields));
}

GccExternTypes gccExternTypes(
	ref Alloc alloc,
	ref gcc_jit_context ctx,
	in LowProgram program,
	in MangledNames mangledNames,
) =>
	mapFullIndexDict!(LowType.Extern, ExternTypeInfo, LowExternType)(
		alloc,
		program.allExternTypes,
		(LowType.Extern, ref LowExternType extern_) {
			gcc_jit_struct* struct_ = structStub(alloc, ctx, mangledNames, extern_.source);
			Opt!ElementAndCount ec = getElementAndCountForExtern(typeSize(extern_));
			Opt!ExternTypeArrayInfo arrayInfo = () {
				if (has(ec)) {
					immutable gcc_jit_type* arrayType = gcc_jit_context_new_array_type(
						ctx,
						null,
						getOnePrimitiveType(ctx, force(ec).elementType),
						safeToInt(force(ec).count));
					immutable gcc_jit_field* field = gcc_jit_context_new_field(ctx, null, arrayType, "__sizer");
					gcc_jit_struct_set_fields(struct_, null, 1, &field);
					return some(ExternTypeArrayInfo(field, arrayType, force(ec)));
				} else
					return none!ExternTypeArrayInfo;
			}();
			return ExternTypeInfo(gcc_jit_struct_as_type(struct_), arrayInfo);
		});

gcc_jit_struct* structStub(
	ref Alloc alloc,
	ref gcc_jit_context ctx,
	in MangledNames mangledNames,
	in ConcreteStruct* source,
) {
	//TODO:PERF use a temporary (dont' allocate string)
	Writer writer = Writer(ptrTrustMe(alloc));
	writeStructMangledName(writer, mangledNames, source);
	return gcc_jit_context_new_opaque_struct(ctx, null, finishWriterToCStr(writer));
}
