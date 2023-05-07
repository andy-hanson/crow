module backend.libgccjit;

@safe @nogc pure nothrow:

version (GccJitAvailable) {

// based on /usr/include/libgccjit.h
// 'scope', 'immutable' and 'const' annotations are my own guesses
// I've used 'ref' or 'T*' instead of T* where the pointer must point to exactly one thing

extern(C) {
	struct gcc_jit_context;
	struct gcc_jit_result;
	struct gcc_jit_field;
	private struct gcc_jit_location;
	struct gcc_jit_struct;
	struct gcc_jit_function;
	struct gcc_jit_block;
	immutable struct gcc_jit_rvalue;
	struct gcc_jit_lvalue;
	struct gcc_jit_type;
	struct gcc_jit_param;
	struct gcc_jit_case;

	gcc_jit_context* gcc_jit_context_acquire();

	void gcc_jit_context_release(gcc_jit_context* ctxt);

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

	void* gcc_jit_result_get_code(immutable gcc_jit_result* result, const char *funcname);

	void gcc_jit_result_release(immutable gcc_jit_result* result);

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

	immutable(gcc_jit_type*) gcc_jit_context_get_type(
		ref gcc_jit_context ctxt,
		gcc_jit_types type);

	immutable(gcc_jit_type*) gcc_jit_type_get_pointer(immutable gcc_jit_type* type);

	immutable(gcc_jit_type*) gcc_jit_context_new_array_type(
		ref gcc_jit_context ctxt,
		gcc_jit_location *loc,
		immutable gcc_jit_type* element_type,
		int num_elements);

	gcc_jit_struct* gcc_jit_context_new_opaque_struct(
		ref gcc_jit_context ctx,
		gcc_jit_location* loc,
		scope const char* name);

	immutable(gcc_jit_field*) gcc_jit_context_new_field(
		ref gcc_jit_context ctx,
		gcc_jit_location* loc,
		const gcc_jit_type* type,
		scope const char *name);

	void gcc_jit_struct_set_fields(
		gcc_jit_struct* struct_type,
		gcc_jit_location *loc,
		int num_fields,
		immutable gcc_jit_field** fields);

	immutable(gcc_jit_struct*) gcc_jit_context_new_struct_type(
		ref gcc_jit_context ctxt,
		gcc_jit_location* loc,
		const char *name,
		int num_fields,
		immutable gcc_jit_field** fields);

	immutable(gcc_jit_type*) gcc_jit_struct_as_type(const gcc_jit_struct* struct_type);

	immutable(gcc_jit_type*) gcc_jit_context_new_union_type(
		ref gcc_jit_context ctxt,
		gcc_jit_location* loc,
		const char* name,
		int num_fields,
		immutable gcc_jit_field** fields);

	gcc_jit_type* gcc_jit_context_new_function_ptr_type(
		ref gcc_jit_context ctxt,
		gcc_jit_location* loc,
		const gcc_jit_type* return_type,
		int num_params,
		const gcc_jit_type** param_types,
		int is_variadic);

	immutable(gcc_jit_param*) gcc_jit_context_new_param(
		ref gcc_jit_context ctxt,
		gcc_jit_location* loc,
		const gcc_jit_type* type,
		const char* name);

	gcc_jit_lvalue* gcc_jit_param_as_lvalue(gcc_jit_param* param);

	gcc_jit_rvalue* gcc_jit_param_as_rvalue(const gcc_jit_param* param);

	enum gcc_jit_function_kind {
		GCC_JIT_FUNCTION_EXPORTED,
		GCC_JIT_FUNCTION_INTERNAL,
		GCC_JIT_FUNCTION_IMPORTED,
		GCC_JIT_FUNCTION_ALWAYS_INLINE,
	}

	enum gcc_jit_tls_model {
		GCC_JIT_TLS_MODEL_NONE,
		GCC_JIT_TLS_MODEL_GLOBAL_DYNAMIC,
		GCC_JIT_TLS_MODEL_LOCAL_DYNAMIC,
		GCC_JIT_TLS_MODEL_INITIAL_EXEC,
		GCC_JIT_TLS_MODEL_LOCAL_EXEC,
	}

	gcc_jit_function* gcc_jit_context_new_function(
		ref gcc_jit_context ctxt,
		gcc_jit_location* loc,
		gcc_jit_function_kind kind,
		const gcc_jit_type* return_type,
		const char* name,
		int num_params,
		scope const gcc_jit_param** params,
		bool is_variadic);

	immutable(gcc_jit_function*) gcc_jit_context_get_builtin_function(
		ref gcc_jit_context ctxt,
		const char *name);

	inout(gcc_jit_param*) gcc_jit_function_get_param(inout gcc_jit_function* func, int index);

	gcc_jit_block* gcc_jit_function_new_block(gcc_jit_function* func, scope const char* name);

	enum gcc_jit_global_kind {
		GCC_JIT_GLOBAL_EXPORTED,
		GCC_JIT_GLOBAL_INTERNAL,
		GCC_JIT_GLOBAL_IMPORTED,
	}

	gcc_jit_lvalue* gcc_jit_context_new_global(
		ref gcc_jit_context ctxt,
		gcc_jit_location* loc,
		gcc_jit_global_kind kind,
		immutable gcc_jit_type* type,
		const char *name);

	gcc_jit_rvalue* gcc_jit_context_new_array_constructor(
		ref gcc_jit_context ctxt,
		gcc_jit_location* loc,
		immutable gcc_jit_type* type,
		size_t num_values,
		immutable gcc_jit_rvalue** values);

	gcc_jit_rvalue* gcc_jit_lvalue_as_rvalue(const gcc_jit_lvalue* lvalue);

	gcc_jit_rvalue* gcc_jit_context_new_rvalue_from_long(
		ref gcc_jit_context ctxt,
		immutable gcc_jit_type* numeric_type,
		long value);

	gcc_jit_rvalue* gcc_jit_context_zero(
		ref gcc_jit_context ctxt,
		immutable gcc_jit_type* numeric_type);

	gcc_jit_rvalue* gcc_jit_context_new_rvalue_from_double(
		ref gcc_jit_context ctxt,
		immutable gcc_jit_type* numeric_type,
		double value);

	gcc_jit_rvalue* gcc_jit_context_null(
		ref gcc_jit_context ctxt,
		const gcc_jit_type* pointer_type);

	gcc_jit_rvalue* gcc_jit_context_new_string_literal(
		ref gcc_jit_context ctxt,
		const char *value);

	enum gcc_jit_unary_op {
		GCC_JIT_UNARY_OP_MINUS,
		GCC_JIT_UNARY_OP_BITWISE_NEGATE,
		GCC_JIT_UNARY_OP_LOGICAL_NEGATE,
		GCC_JIT_UNARY_OP_ABS,
	}

	gcc_jit_rvalue* gcc_jit_context_new_unary_op(
		ref gcc_jit_context ctxt,
		gcc_jit_location* loc,
		gcc_jit_unary_op op,
		immutable gcc_jit_type* result_type,
		gcc_jit_rvalue* rvalue);

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

	gcc_jit_rvalue* gcc_jit_context_new_binary_op(
		ref gcc_jit_context ctxt,
		gcc_jit_location* loc,
		gcc_jit_binary_op op,
		immutable gcc_jit_type* result_type,
		gcc_jit_rvalue* a,
		gcc_jit_rvalue* b);

	enum gcc_jit_comparison {
		GCC_JIT_COMPARISON_EQ,
		GCC_JIT_COMPARISON_NE,
		GCC_JIT_COMPARISON_LT,
		GCC_JIT_COMPARISON_LE,
		GCC_JIT_COMPARISON_GT,
		GCC_JIT_COMPARISON_GE,
	}

	gcc_jit_rvalue* gcc_jit_context_new_comparison(
		ref gcc_jit_context ctxt,
		gcc_jit_location* loc,
		gcc_jit_comparison op,
		gcc_jit_rvalue* a,
		gcc_jit_rvalue* b);

	gcc_jit_rvalue* gcc_jit_context_new_call(
		ref gcc_jit_context ctxt,
		gcc_jit_location *loc,
		const gcc_jit_function* func,
		int numargs,
		scope immutable gcc_jit_rvalue** args);

	gcc_jit_rvalue* gcc_jit_context_new_call_through_ptr(
		ref gcc_jit_context ctxt,
		gcc_jit_location* loc,
		gcc_jit_rvalue* fn_ptr,
		int numargs,
		scope immutable gcc_jit_rvalue** args);

	gcc_jit_rvalue* gcc_jit_context_new_cast(
		ref gcc_jit_context ctxt,
		gcc_jit_location* loc,
		gcc_jit_rvalue* rvalue,
		immutable gcc_jit_type* type);

	gcc_jit_lvalue* gcc_jit_context_new_array_access(
		ref gcc_jit_context ctxt,
		gcc_jit_location *loc,
		gcc_jit_rvalue* ptr,
		gcc_jit_rvalue* index);

	gcc_jit_lvalue* gcc_jit_lvalue_access_field(
		gcc_jit_lvalue* struct_or_union,
		gcc_jit_location* loc,
		const gcc_jit_field* field);

	gcc_jit_rvalue* gcc_jit_rvalue_access_field(
		gcc_jit_rvalue* struct_or_union,
		gcc_jit_location* loc,
		immutable gcc_jit_field* field);

	gcc_jit_lvalue* gcc_jit_rvalue_dereference_field(
		gcc_jit_rvalue* ptr,
		gcc_jit_location* loc,
		immutable gcc_jit_field* field);

	gcc_jit_lvalue* gcc_jit_rvalue_dereference(gcc_jit_rvalue* rvalue, gcc_jit_location* loc);

	gcc_jit_rvalue* gcc_jit_lvalue_get_address(gcc_jit_lvalue* lvalue, gcc_jit_location* loc);

	void gcc_jit_lvalue_set_tls_model(gcc_jit_lvalue *lvalue, gcc_jit_tls_model mode);

	gcc_jit_lvalue* gcc_jit_function_new_local(
		gcc_jit_function* func,
		gcc_jit_location* loc,
		const gcc_jit_type* type,
		const char* name);

	void gcc_jit_block_add_eval(
		gcc_jit_block* block,
		gcc_jit_location* loc,
		gcc_jit_rvalue* rvalue);

	void gcc_jit_block_add_assignment(
		gcc_jit_block* block,
		gcc_jit_location* loc,
		gcc_jit_lvalue* lvalue,
		gcc_jit_rvalue* rvalue);

	void gcc_jit_block_end_with_conditional(
		gcc_jit_block* block,
		gcc_jit_location* loc,
		gcc_jit_rvalue* boolval,
		gcc_jit_block* on_true,
		gcc_jit_block* on_false);

	void gcc_jit_block_end_with_jump(
		gcc_jit_block* block,
		gcc_jit_location* loc,
		gcc_jit_block* target);

	void gcc_jit_block_end_with_return(
		gcc_jit_block* block,
		gcc_jit_location* loc,
		gcc_jit_rvalue* rvalue);

	immutable(gcc_jit_case*) gcc_jit_context_new_case(
		ref gcc_jit_context ctxt,
		gcc_jit_rvalue* min_value,
		gcc_jit_rvalue* max_value,
		gcc_jit_block* dest_block);

	void gcc_jit_block_end_with_switch(
		gcc_jit_block* block,
		gcc_jit_location* loc,
		gcc_jit_rvalue* expr,
		gcc_jit_block* default_block,
		int num_cases,
		immutable gcc_jit_case** cases);

	gcc_jit_rvalue* gcc_jit_function_get_address(
		const gcc_jit_function* fn,
		gcc_jit_location* loc);
}

} // GccJitAvailable
