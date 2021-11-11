module include.libgccjit;

@safe @nogc pure nothrow:

import util.ptr : Ptr;

// based on /usr/include/libgccjit.h
// 'scope', 'immutable' and 'const' annotations are my own guesses
// I've used 'ref' or 'Ptr!T' instead of T* where the pointer must point to exactly one thing

extern(C) {
	struct gcc_jit_context;
	struct gcc_jit_result;
	struct gcc_jit_field;
	private struct gcc_jit_location;
	struct gcc_jit_struct;
	struct gcc_jit_function;
	struct gcc_jit_block;
	struct gcc_jit_rvalue;
	struct gcc_jit_lvalue;
	struct gcc_jit_type;
	struct gcc_jit_param;
	struct gcc_jit_case;

	gcc_jit_context* gcc_jit_context_acquire();

	void gcc_jit_context_release(Ptr!gcc_jit_context ctxt);

	enum gcc_jit_int_option {
		GCC_JIT_INT_OPTION_OPTIMIZATION_LEVEL,
	}

	enum gcc_jit_bool_option {
		GCC_JIT_BOOL_OPTION_DEBUGINFO,
		GCC_JIT_BOOL_OPTION_DUMP_INITIAL_TREE,
		GCC_JIT_BOOL_OPTION_DUMP_INITIAL_GIMPLE,
		GCC_JIT_BOOL_OPTION_DUMP_GENERATED_CODE,
		GCC_JIT_BOOL_OPTION_DUMP_SUMMARY,
		GCC_JIT_BOOL_OPTION_DUMP_EVERYTHING,
		GCC_JIT_BOOL_OPTION_SELFCHECK_GC,
		GCC_JIT_BOOL_OPTION_KEEP_INTERMEDIATES,
	}

	void gcc_jit_context_set_int_option(
		ref gcc_jit_context ctxt,
		gcc_jit_int_option opt,
		int value);

	void gcc_jit_context_set_bool_option(
		ref gcc_jit_context ctxt,
		gcc_jit_bool_option opt,
		bool value);

	void gcc_jit_context_add_driver_option(ref gcc_jit_context ctxt, const char *optname);

	immutable(gcc_jit_result*) gcc_jit_context_compile(ref gcc_jit_context ctxt);

	enum gcc_jit_output_kind {
		GCC_JIT_OUTPUT_KIND_ASSEMBLER,
		GCC_JIT_OUTPUT_KIND_OBJECT_FILE,
		GCC_JIT_OUTPUT_KIND_DYNAMIC_LIBRARY,
		GCC_JIT_OUTPUT_KIND_EXECUTABLE
	}

	void gcc_jit_context_compile_to_file(
		ref gcc_jit_context ctxt,
		gcc_jit_output_kind output_kind,
		const char *output_path);

	const(char*) gcc_jit_context_get_first_error(ref gcc_jit_context ctxt);

	void* gcc_jit_result_get_code(immutable Ptr!gcc_jit_result result, const char *funcname);

	void gcc_jit_result_release(immutable Ptr!gcc_jit_result result);

	enum gcc_jit_types {
		GCC_JIT_TYPE_VOID,
		GCC_JIT_TYPE_VOID_PTR,
		GCC_JIT_TYPE_BOOL,
		GCC_JIT_TYPE_CHAR,
		GCC_JIT_TYPE_SIGNED_CHAR,
		GCC_JIT_TYPE_UNSIGNED_CHAR,
		GCC_JIT_TYPE_SHORT,
		GCC_JIT_TYPE_UNSIGNED_SHORT,
		GCC_JIT_TYPE_INT,
		GCC_JIT_TYPE_UNSIGNED_INT,
		GCC_JIT_TYPE_LONG,
		GCC_JIT_TYPE_UNSIGNED_LONG,
		GCC_JIT_TYPE_LONG_LONG,
		GCC_JIT_TYPE_UNSIGNED_LONG_LONG,
		GCC_JIT_TYPE_FLOAT,
		GCC_JIT_TYPE_DOUBLE,
		GCC_JIT_TYPE_LONG_DOUBLE,
		GCC_JIT_TYPE_CONST_CHAR_PTR,
		GCC_JIT_TYPE_SIZE_T,
		GCC_JIT_TYPE_FILE_PTR,
		GCC_JIT_TYPE_COMPLEX_FLOAT,
		GCC_JIT_TYPE_COMPLEX_DOUBLE,
		GCC_JIT_TYPE_COMPLEX_LONG_DOUBLE,
	}

	immutable(Ptr!gcc_jit_type) gcc_jit_context_get_type(
		ref gcc_jit_context ctxt,
		gcc_jit_types type);

	immutable(Ptr!gcc_jit_type) gcc_jit_type_get_pointer(immutable Ptr!gcc_jit_type type);

	immutable(Ptr!gcc_jit_type) gcc_jit_context_new_array_type(
		ref gcc_jit_context ctxt,
		gcc_jit_location *loc,
		immutable Ptr!gcc_jit_type element_type,
		int num_elements);

	Ptr!gcc_jit_struct gcc_jit_context_new_opaque_struct(
		ref gcc_jit_context ctx,
		gcc_jit_location* loc,
		scope const char* name);

	immutable(Ptr!gcc_jit_field) gcc_jit_context_new_field(
		ref gcc_jit_context ctx,
		gcc_jit_location* loc,
		const Ptr!gcc_jit_type type,
		scope const char *name);

	void gcc_jit_struct_set_fields(
		Ptr!gcc_jit_struct struct_type,
		gcc_jit_location *loc,
		int num_fields,
		immutable Ptr!gcc_jit_field* fields);

	immutable(Ptr!gcc_jit_struct) gcc_jit_context_new_struct_type(
		ref gcc_jit_context ctxt,
		gcc_jit_location* loc,
		const char *name,
		int num_fields,
		immutable Ptr!gcc_jit_field* fields);

	immutable(Ptr!gcc_jit_type) gcc_jit_struct_as_type(const Ptr!gcc_jit_struct struct_type);

	immutable(Ptr!gcc_jit_type) gcc_jit_context_new_union_type(
		ref gcc_jit_context ctxt,
		gcc_jit_location* loc,
		const char* name,
		int num_fields,
		immutable Ptr!gcc_jit_field* fields);

	Ptr!gcc_jit_type gcc_jit_context_new_function_ptr_type(
		ref gcc_jit_context ctxt,
		gcc_jit_location* loc,
		const Ptr!gcc_jit_type return_type,
		int num_params,
		const Ptr!gcc_jit_type* param_types,
		int is_variadic);

	immutable(Ptr!gcc_jit_param) gcc_jit_context_new_param(
		ref gcc_jit_context ctxt,
		gcc_jit_location* loc,
		const Ptr!gcc_jit_type type,
		const char* name);

	Ptr!gcc_jit_lvalue gcc_jit_param_as_lvalue(Ptr!gcc_jit_param param);

	immutable(Ptr!gcc_jit_rvalue) gcc_jit_param_as_rvalue(const Ptr!gcc_jit_param param);

	enum gcc_jit_function_kind {
		GCC_JIT_FUNCTION_EXPORTED,
		GCC_JIT_FUNCTION_INTERNAL,
		GCC_JIT_FUNCTION_IMPORTED,
		GCC_JIT_FUNCTION_ALWAYS_INLINE,
	}

	Ptr!gcc_jit_function gcc_jit_context_new_function(
		ref gcc_jit_context ctxt,
		gcc_jit_location* loc,
		gcc_jit_function_kind kind,
		const Ptr!gcc_jit_type return_type,
		const char* name,
		int num_params,
		const Ptr!gcc_jit_param* params,
		bool is_variadic);

	immutable(Ptr!gcc_jit_function) gcc_jit_context_get_builtin_function(
		ref gcc_jit_context ctxt,
		const char *name);

	inout(Ptr!gcc_jit_param) gcc_jit_function_get_param(inout Ptr!gcc_jit_function func, int index);

	Ptr!gcc_jit_block gcc_jit_function_new_block(Ptr!gcc_jit_function func, const char* name);

	enum gcc_jit_global_kind {
		GCC_JIT_GLOBAL_EXPORTED,
		GCC_JIT_GLOBAL_INTERNAL,
		GCC_JIT_GLOBAL_IMPORTED,
	}

	Ptr!gcc_jit_lvalue gcc_jit_context_new_global(
		ref gcc_jit_context ctxt,
		gcc_jit_location* loc,
		gcc_jit_global_kind kind,
		immutable Ptr!gcc_jit_type type,
		const char *name);

	immutable(Ptr!gcc_jit_rvalue) gcc_jit_lvalue_as_rvalue(const Ptr!gcc_jit_lvalue lvalue);

	immutable(Ptr!gcc_jit_rvalue) gcc_jit_context_new_rvalue_from_long(
		ref gcc_jit_context ctxt,
		immutable Ptr!gcc_jit_type numeric_type,
		long value);

	immutable(Ptr!gcc_jit_rvalue) gcc_jit_context_zero(
		ref gcc_jit_context ctxt,
		immutable Ptr!gcc_jit_type numeric_type);

	immutable(Ptr!gcc_jit_rvalue) gcc_jit_context_new_rvalue_from_double(
		ref gcc_jit_context ctxt,
		immutable Ptr!gcc_jit_type numeric_type,
		double value);

	immutable(Ptr!gcc_jit_rvalue) gcc_jit_context_null(
		ref gcc_jit_context ctxt,
		const Ptr!gcc_jit_type pointer_type);

	immutable(Ptr!gcc_jit_rvalue) gcc_jit_context_new_string_literal(
		ref gcc_jit_context ctxt,
		const char *value);

	enum gcc_jit_unary_op {
		GCC_JIT_UNARY_OP_MINUS,
		GCC_JIT_UNARY_OP_BITWISE_NEGATE,
		GCC_JIT_UNARY_OP_LOGICAL_NEGATE,
		GCC_JIT_UNARY_OP_ABS,
	}

	immutable(Ptr!gcc_jit_rvalue) gcc_jit_context_new_unary_op(
		ref gcc_jit_context ctxt,
		gcc_jit_location* loc,
		gcc_jit_unary_op op,
		immutable Ptr!gcc_jit_type result_type,
		immutable Ptr!gcc_jit_rvalue rvalue);

	enum gcc_jit_binary_op {
		GCC_JIT_BINARY_OP_PLUS,
		GCC_JIT_BINARY_OP_MINUS,
		GCC_JIT_BINARY_OP_MULT,
		GCC_JIT_BINARY_OP_DIVIDE,
		GCC_JIT_BINARY_OP_MODULO,
		GCC_JIT_BINARY_OP_BITWISE_AND,
		GCC_JIT_BINARY_OP_BITWISE_XOR,
		GCC_JIT_BINARY_OP_BITWISE_OR,
		GCC_JIT_BINARY_OP_LOGICAL_AND,
		GCC_JIT_BINARY_OP_LOGICAL_OR,
		GCC_JIT_BINARY_OP_LSHIFT,
		GCC_JIT_BINARY_OP_RSHIFT,
	}

	immutable(Ptr!gcc_jit_rvalue) gcc_jit_context_new_binary_op(
		ref gcc_jit_context ctxt,
		gcc_jit_location* loc,
		gcc_jit_binary_op op,
		immutable Ptr!gcc_jit_type result_type,
		immutable Ptr!gcc_jit_rvalue a,
		immutable Ptr!gcc_jit_rvalue b);

	enum gcc_jit_comparison {
		GCC_JIT_COMPARISON_EQ,
		GCC_JIT_COMPARISON_NE,
		GCC_JIT_COMPARISON_LT,
		GCC_JIT_COMPARISON_LE,
		GCC_JIT_COMPARISON_GT,
		GCC_JIT_COMPARISON_GE,
	}

	immutable(Ptr!gcc_jit_rvalue) gcc_jit_context_new_comparison(
		ref gcc_jit_context ctxt,
		gcc_jit_location* loc,
		gcc_jit_comparison op,
		immutable Ptr!gcc_jit_rvalue a,
		immutable Ptr!gcc_jit_rvalue b);

	Ptr!gcc_jit_rvalue gcc_jit_context_new_call(
		ref gcc_jit_context ctxt,
		gcc_jit_location *loc,
		const Ptr!gcc_jit_function func,
		int numargs,
		const Ptr!gcc_jit_rvalue* args);

	immutable(Ptr!gcc_jit_rvalue) gcc_jit_context_new_call_through_ptr(
		ref gcc_jit_context ctxt,
		gcc_jit_location* loc,
		immutable Ptr!gcc_jit_rvalue fn_ptr,
		int numargs,
		immutable Ptr!gcc_jit_rvalue* args);

	immutable(Ptr!gcc_jit_rvalue) gcc_jit_context_new_cast(
		ref gcc_jit_context ctxt,
		gcc_jit_location* loc,
		immutable Ptr!gcc_jit_rvalue rvalue,
		immutable Ptr!gcc_jit_type type);

	Ptr!gcc_jit_lvalue gcc_jit_context_new_array_access(
		ref gcc_jit_context ctxt,
		gcc_jit_location *loc,
		immutable Ptr!gcc_jit_rvalue ptr,
		immutable Ptr!gcc_jit_rvalue index);

	Ptr!gcc_jit_lvalue gcc_jit_lvalue_access_field(
		Ptr!gcc_jit_lvalue struct_or_union,
		gcc_jit_location* loc,
		const Ptr!gcc_jit_field field);

	immutable(Ptr!gcc_jit_rvalue) gcc_jit_rvalue_access_field(
		immutable Ptr!gcc_jit_rvalue struct_or_union,
		gcc_jit_location* loc,
		immutable Ptr!gcc_jit_field field);

	Ptr!gcc_jit_lvalue gcc_jit_rvalue_dereference_field(
		immutable Ptr!gcc_jit_rvalue ptr,
		gcc_jit_location* loc,
		immutable Ptr!gcc_jit_field field);

	Ptr!gcc_jit_lvalue gcc_jit_rvalue_dereference(
		immutable Ptr!gcc_jit_rvalue rvalue,
		gcc_jit_location* loc);

	immutable(Ptr!gcc_jit_rvalue) gcc_jit_lvalue_get_address(
		Ptr!gcc_jit_lvalue lvalue,
		gcc_jit_location* loc);

	Ptr!gcc_jit_lvalue gcc_jit_function_new_local(
		Ptr!gcc_jit_function func,
		gcc_jit_location* loc,
		const Ptr!gcc_jit_type type,
		const char* name);

	void gcc_jit_block_add_eval(
		Ptr!gcc_jit_block block,
		gcc_jit_location* loc,
		immutable Ptr!gcc_jit_rvalue rvalue);

	void gcc_jit_block_add_assignment(
		Ptr!gcc_jit_block block,
		gcc_jit_location* loc,
		Ptr!gcc_jit_lvalue lvalue,
		immutable Ptr!gcc_jit_rvalue rvalue);

	void gcc_jit_block_end_with_conditional(
		Ptr!gcc_jit_block block,
		gcc_jit_location* loc,
		immutable Ptr!gcc_jit_rvalue boolval,
		Ptr!gcc_jit_block on_true,
		Ptr!gcc_jit_block on_false);

	void gcc_jit_block_end_with_jump(
		Ptr!gcc_jit_block block,
		gcc_jit_location* loc,
		Ptr!gcc_jit_block target);

	void gcc_jit_block_end_with_return(
		Ptr!gcc_jit_block block,
		gcc_jit_location* loc,
		immutable Ptr!gcc_jit_rvalue rvalue);

	immutable(Ptr!gcc_jit_case) gcc_jit_context_new_case(
		ref gcc_jit_context ctxt,
		immutable Ptr!gcc_jit_rvalue min_value,
		immutable Ptr!gcc_jit_rvalue max_value,
		Ptr!gcc_jit_block dest_block);

	void gcc_jit_block_end_with_switch(
		Ptr!gcc_jit_block block,
		gcc_jit_location* loc,
		immutable Ptr!gcc_jit_rvalue expr,
		Ptr!gcc_jit_block default_block,
		int num_cases,
		immutable Ptr!gcc_jit_case* cases);

	void gcc_jit_rvalue_set_bool_require_tail_call(Ptr!gcc_jit_rvalue call, bool require_tail_call);

	immutable(Ptr!gcc_jit_rvalue) gcc_jit_function_get_address(
		const Ptr!gcc_jit_function fn,
		gcc_jit_location* loc);
}
