#include <assert.h>
#include <errno.h>
#include <stdatomic.h>
#include <stddef.h>
#include <stdint.h>

struct void_ {};
typedef uint8_t* (*fun_ptr1)(uint8_t*);
struct ctx {
	uint8_t* gctx_ptr;
	uint64_t island_id;
	uint64_t exclusion;
	uint8_t* gc_ctx_ptr;
	uint8_t* exception_ctx_ptr;
	uint8_t* log_ctx;
};
struct mark_ctx {
	uint64_t memory_size_words;
	uint8_t* marks;
	uint64_t* memory_start;
};
struct arr_0 {
	uint64_t size;
	char* data;
};
struct less {
};
struct equal {
};
struct greater {
};
struct fut_0;
struct lock;
struct _atomic_bool {
	uint8_t value;
};
struct fut_state_callbacks_0;
struct fut_callback_node_0;
struct exception {
	struct arr_0 message;
};
struct ok_0 {
	int32_t value;
};
struct err_0 {
	struct exception value;
};
struct none {
};
struct some_0 {
	struct fut_callback_node_0* value;
};
struct fut_state_resolved_0 {
	int32_t value;
};
struct arr_1 {
	uint64_t size;
	struct arr_0* data;
};
struct global_ctx;
struct island;
struct gc;
struct gc_ctx;
struct some_1 {
	struct gc_ctx* value;
};
struct island_gc_root;
struct task;
struct mut_bag;
struct mut_bag_node;
struct some_2 {
	struct mut_bag_node* value;
};
struct logged;
struct info {
};
struct warn {
};
struct mut_arr_0 {
	uint8_t frozen__q;
	uint64_t size;
	uint64_t capacity;
	uint64_t* data;
};
struct thread_safe_counter;
struct arr_2 {
	uint64_t size;
	struct island** data;
};
struct condition;
struct exception_ctx;
struct jmp_buf_tag;
struct bytes64;
struct bytes32;
struct bytes16 {
	uint64_t n0;
	uint64_t n1;
};
struct bytes128;
struct some_3 {
	uint8_t* value;
};
struct log_ctx;
struct thread_local_stuff {
	struct exception_ctx* exception_ctx;
	struct log_ctx* log_ctx;
};
struct arr_3 {
	uint64_t size;
	char** data;
};
struct fut_1;
struct fut_state_callbacks_1;
struct fut_callback_node_1;
struct ok_1 {
	struct void_ value;
};
struct some_4 {
	struct fut_callback_node_1* value;
};
struct fut_state_resolved_1 {
	struct void_ value;
};
struct fun_ref0;
struct island_and_exclusion {
	uint64_t island;
	uint64_t exclusion;
};
struct fun_ref1;
struct then__lambda0;
struct forward_to__lambda0 {
	struct fut_0* to;
};
struct call_ref_0__lambda0;
struct call_ref_0__lambda0__lambda0;
struct call_ref_0__lambda0__lambda1 {
	struct fut_0* res;
};
struct then2__lambda0;
struct call_ref_1__lambda0;
struct call_ref_1__lambda0__lambda0;
struct call_ref_1__lambda0__lambda1 {
	struct fut_0* res;
};
struct add_first_task__lambda0;
struct mut_arr_1 {
	uint8_t frozen__q;
	uint64_t size;
	uint64_t capacity;
	struct arr_0* data;
};
struct map__lambda0;
struct thread_args {
	uint64_t thread_id;
	struct global_ctx* gctx;
};
struct cell_0 {
	uint64_t value;
};
struct chosen_task;
struct some_5;
struct no_chosen_task {
	uint8_t last_thread_out;
};
struct ok_2;
struct err_1 {
	struct no_chosen_task value;
};
struct some_6;
struct some_7;
struct task_and_nodes;
struct some_8;
struct arr_4 {
	uint64_t size;
	uint64_t* data;
};
struct cell_1 {
	uint8_t* value;
};
struct my_record {
	struct arr_0 a;
	struct arr_0 b;
};
struct comparison {
	uint64_t kind;
	union {
		struct less as0;
		struct equal as1;
		struct greater as2;
	};
};
struct fut_state_0;
struct result_0 {
	uint64_t kind;
	union {
		struct ok_0 as0;
		struct err_0 as1;
	};
};
struct fun_mut1_0 {
	uint64_t kind;
	union {
		struct forward_to__lambda0* as0;
	};
};
struct opt_0 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_0 as1;
	};
};
struct opt_1 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_1 as1;
	};
};
struct fun_mut0_0 {
	uint64_t kind;
	union {
		struct call_ref_0__lambda0__lambda0* as0;
		struct call_ref_0__lambda0* as1;
		struct call_ref_1__lambda0__lambda0* as2;
		struct call_ref_1__lambda0* as3;
	};
};
struct opt_2 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_2 as1;
	};
};
struct fun_mut1_1 {
	uint64_t kind;
	union {
		struct void_ as0;
		struct call_ref_0__lambda0__lambda1* as1;
		struct call_ref_1__lambda0__lambda1* as2;
	};
};
struct log_level {
	uint64_t kind;
	union {
		struct info as0;
		struct warn as1;
	};
};
struct fun1 {
	uint64_t kind;
	union {
		struct void_ as0;
	};
};
struct opt_3 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_3 as1;
	};
};
struct fun2 {
	uint64_t kind;
	union {
		struct void_ as0;
	};
};
struct fut_state_1;
struct result_1 {
	uint64_t kind;
	union {
		struct ok_1 as0;
		struct err_0 as1;
	};
};
struct fun_mut1_2 {
	uint64_t kind;
	union {
		struct then__lambda0* as0;
	};
};
struct opt_4 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_4 as1;
	};
};
struct fun_mut0_1 {
	uint64_t kind;
	union {
		struct add_first_task__lambda0* as0;
	};
};
struct fun_mut1_3 {
	uint64_t kind;
	union {
		struct then2__lambda0* as0;
	};
};
struct fun_mut1_4 {
	uint64_t kind;
	union {
		struct void_ as0;
	};
};
struct fun_mut1_5 {
	uint64_t kind;
	union {
		struct map__lambda0* as0;
	};
};
struct opt_5;
struct result_2;
struct opt_6;
struct opt_7;
struct opt_8;
typedef struct fut_0* (*fun_ptr2)(struct ctx*, struct arr_1);
struct fut_0;
struct lock {
	struct _atomic_bool is_locked;
};
struct fut_state_callbacks_0 {
	struct opt_0 head;
};
struct fut_callback_node_0 {
	struct fun_mut1_0 cb;
	struct opt_0 next_node;
};
struct global_ctx;
struct island;
struct gc {
	struct lock lk;
	uint64_t gc_count;
	struct opt_1 context_head;
	uint8_t needs_gc__q;
	uint64_t size_words;
	uint8_t* mark_begin;
	uint8_t* mark_cur;
	uint8_t* mark_end;
	uint64_t* data_begin;
	uint64_t* data_cur;
	uint64_t* data_end;
};
struct gc_ctx {
	struct gc* gc;
	struct opt_1 next_ctx;
};
struct island_gc_root;
struct task {
	uint64_t exclusion;
	struct fun_mut0_0 fun;
};
struct mut_bag {
	struct opt_2 head;
};
struct mut_bag_node {
	struct task value;
	struct opt_2 next_node;
};
struct logged {
	struct log_level level;
	struct arr_0 message;
};
struct thread_safe_counter {
	struct lock lk;
	uint64_t value;
};
struct condition {
	struct lock lk;
	uint64_t value;
};
struct exception_ctx {
	struct jmp_buf_tag* jmp_buf_ptr;
	struct exception thrown_exception;
};
struct jmp_buf_tag;
struct bytes64;
struct bytes32 {
	struct bytes16 n0;
	struct bytes16 n1;
};
struct bytes128;
struct log_ctx {
	struct fun1 handler;
};
struct fut_1;
struct fut_state_callbacks_1 {
	struct opt_4 head;
};
struct fut_callback_node_1 {
	struct fun_mut1_2 cb;
	struct opt_4 next_node;
};
struct fun_ref0 {
	struct island_and_exclusion island_and_exclusion;
	struct fun_mut0_1 fun;
};
struct fun_ref1 {
	struct island_and_exclusion island_and_exclusion;
	struct fun_mut1_3 fun;
};
struct then__lambda0 {
	struct fun_ref1 cb;
	struct fut_0* res;
};
struct call_ref_0__lambda0 {
	struct fun_ref1 f;
	struct void_ p0;
	struct fut_0* res;
};
struct call_ref_0__lambda0__lambda0 {
	struct fun_ref1 f;
	struct void_ p0;
	struct fut_0* res;
};
struct then2__lambda0 {
	struct fun_ref0 cb;
};
struct call_ref_1__lambda0 {
	struct fun_ref0 f;
	struct fut_0* res;
};
struct call_ref_1__lambda0__lambda0 {
	struct fun_ref0 f;
	struct fut_0* res;
};
struct add_first_task__lambda0 {
	struct arr_3 all_args;
	fun_ptr2 main_ptr;
};
struct map__lambda0 {
	struct fun_mut1_4 mapper;
	struct arr_3 a;
};
struct chosen_task;
struct some_5 {
	struct task value;
};
struct ok_2;
struct some_6;
struct some_7;
struct task_and_nodes {
	struct task task;
	struct opt_2 nodes;
};
struct some_8 {
	struct task_and_nodes value;
};
struct fut_state_0 {
	uint64_t kind;
	union {
		struct fut_state_callbacks_0 as0;
		struct fut_state_resolved_0 as1;
		struct exception as2;
	};
};
struct fut_state_1 {
	uint64_t kind;
	union {
		struct fut_state_callbacks_1 as0;
		struct fut_state_resolved_1 as1;
		struct exception as2;
	};
};
struct opt_5 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_5 as1;
	};
};
struct result_2;
struct opt_6;
struct opt_7;
struct opt_8 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_8 as1;
	};
};
struct fut_0 {
	struct lock lk;
	struct fut_state_0 state;
};
struct global_ctx {
	struct lock lk;
	struct arr_2 islands;
	uint64_t n_live_threads;
	struct condition may_be_work_to_do;
	uint8_t is_shut_down;
	uint8_t any_unhandled_exceptions__q;
};
struct island;
struct island_gc_root {
	struct mut_bag tasks;
	struct fun_mut1_1 exception_handler;
	struct fun1 log_handler;
};
struct jmp_buf_tag;
struct bytes64 {
	struct bytes32 n0;
	struct bytes32 n1;
};
struct bytes128 {
	struct bytes64 n0;
	struct bytes64 n1;
};
struct fut_1 {
	struct lock lk;
	struct fut_state_1 state;
};
struct chosen_task {
	struct island* island;
	struct opt_5 task_or_gc;
};
struct ok_2 {
	struct chosen_task value;
};
struct some_6 {
	struct chosen_task value;
};
struct some_7 {
	struct opt_5 value;
};
struct result_2 {
	uint64_t kind;
	union {
		struct ok_2 as0;
		struct err_1 as1;
	};
};
struct opt_6 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_6 as1;
	};
};
struct opt_7 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_7 as1;
	};
};
struct island {
	struct global_ctx* gctx;
	uint64_t id;
	struct gc gc;
	struct island_gc_root gc_root;
	struct lock tasks_lock;
	struct mut_arr_0 currently_running_exclusions;
	uint64_t n_threads_running;
	struct thread_safe_counter next_exclusion;
};
struct jmp_buf_tag {
	struct bytes64 jmp_buf;
	int32_t mask_was_saved;
	struct bytes128 saved_mask;
};

_Static_assert(sizeof(struct ctx) == 48, "");
_Static_assert(sizeof(struct mark_ctx) == 24, "");
_Static_assert(sizeof(struct arr_0) == 16, "");
_Static_assert(sizeof(struct less) == 0, "");
_Static_assert(sizeof(struct equal) == 0, "");
_Static_assert(sizeof(struct greater) == 0, "");
_Static_assert(sizeof(struct fut_0) == 32, "");
_Static_assert(sizeof(struct lock) == 1, "");
_Static_assert(sizeof(struct _atomic_bool) == 1, "");
_Static_assert(sizeof(struct fut_state_callbacks_0) == 16, "");
_Static_assert(sizeof(struct fut_callback_node_0) == 32, "");
_Static_assert(sizeof(struct exception) == 16, "");
_Static_assert(sizeof(struct ok_0) == 4, "");
_Static_assert(sizeof(struct err_0) == 16, "");
_Static_assert(sizeof(struct none) == 0, "");
_Static_assert(sizeof(struct some_0) == 8, "");
_Static_assert(sizeof(struct fut_state_resolved_0) == 4, "");
_Static_assert(sizeof(struct arr_1) == 16, "");
_Static_assert(sizeof(struct global_ctx) == 56, "");
_Static_assert(sizeof(struct island) == 216, "");
_Static_assert(sizeof(struct gc) == 96, "");
_Static_assert(sizeof(struct gc_ctx) == 24, "");
_Static_assert(sizeof(struct some_1) == 8, "");
_Static_assert(sizeof(struct island_gc_root) == 40, "");
_Static_assert(sizeof(struct task) == 24, "");
_Static_assert(sizeof(struct mut_bag) == 16, "");
_Static_assert(sizeof(struct mut_bag_node) == 40, "");
_Static_assert(sizeof(struct some_2) == 8, "");
_Static_assert(sizeof(struct logged) == 24, "");
_Static_assert(sizeof(struct info) == 0, "");
_Static_assert(sizeof(struct warn) == 0, "");
_Static_assert(sizeof(struct mut_arr_0) == 32, "");
_Static_assert(sizeof(struct thread_safe_counter) == 16, "");
_Static_assert(sizeof(struct arr_2) == 16, "");
_Static_assert(sizeof(struct condition) == 16, "");
_Static_assert(sizeof(struct exception_ctx) == 24, "");
_Static_assert(sizeof(struct jmp_buf_tag) == 200, "");
_Static_assert(sizeof(struct bytes64) == 64, "");
_Static_assert(sizeof(struct bytes32) == 32, "");
_Static_assert(sizeof(struct bytes16) == 16, "");
_Static_assert(sizeof(struct bytes128) == 128, "");
_Static_assert(sizeof(struct some_3) == 8, "");
_Static_assert(sizeof(struct log_ctx) == 8, "");
_Static_assert(sizeof(struct thread_local_stuff) == 16, "");
_Static_assert(sizeof(struct arr_3) == 16, "");
_Static_assert(sizeof(struct fut_1) == 32, "");
_Static_assert(sizeof(struct fut_state_callbacks_1) == 16, "");
_Static_assert(sizeof(struct fut_callback_node_1) == 32, "");
_Static_assert(sizeof(struct ok_1) == 0, "");
_Static_assert(sizeof(struct some_4) == 8, "");
_Static_assert(sizeof(struct fut_state_resolved_1) == 0, "");
_Static_assert(sizeof(struct fun_ref0) == 32, "");
_Static_assert(sizeof(struct island_and_exclusion) == 16, "");
_Static_assert(sizeof(struct fun_ref1) == 32, "");
_Static_assert(sizeof(struct then__lambda0) == 40, "");
_Static_assert(sizeof(struct forward_to__lambda0) == 8, "");
_Static_assert(sizeof(struct call_ref_0__lambda0) == 40, "");
_Static_assert(sizeof(struct call_ref_0__lambda0__lambda0) == 40, "");
_Static_assert(sizeof(struct call_ref_0__lambda0__lambda1) == 8, "");
_Static_assert(sizeof(struct then2__lambda0) == 32, "");
_Static_assert(sizeof(struct call_ref_1__lambda0) == 40, "");
_Static_assert(sizeof(struct call_ref_1__lambda0__lambda0) == 40, "");
_Static_assert(sizeof(struct call_ref_1__lambda0__lambda1) == 8, "");
_Static_assert(sizeof(struct add_first_task__lambda0) == 24, "");
_Static_assert(sizeof(struct mut_arr_1) == 32, "");
_Static_assert(sizeof(struct map__lambda0) == 24, "");
_Static_assert(sizeof(struct thread_args) == 16, "");
_Static_assert(sizeof(struct cell_0) == 8, "");
_Static_assert(sizeof(struct chosen_task) == 40, "");
_Static_assert(sizeof(struct some_5) == 24, "");
_Static_assert(sizeof(struct no_chosen_task) == 1, "");
_Static_assert(sizeof(struct ok_2) == 40, "");
_Static_assert(sizeof(struct err_1) == 1, "");
_Static_assert(sizeof(struct some_6) == 40, "");
_Static_assert(sizeof(struct some_7) == 32, "");
_Static_assert(sizeof(struct task_and_nodes) == 40, "");
_Static_assert(sizeof(struct some_8) == 40, "");
_Static_assert(sizeof(struct arr_4) == 16, "");
_Static_assert(sizeof(struct cell_1) == 8, "");
_Static_assert(sizeof(struct my_record) == 32, "");
_Static_assert(sizeof(struct comparison) == 8, "");
_Static_assert(sizeof(struct fut_state_0) == 24, "");
_Static_assert(sizeof(struct result_0) == 24, "");
_Static_assert(sizeof(struct fun_mut1_0) == 16, "");
_Static_assert(sizeof(struct opt_0) == 16, "");
_Static_assert(sizeof(struct opt_1) == 16, "");
_Static_assert(sizeof(struct fun_mut0_0) == 16, "");
_Static_assert(sizeof(struct opt_2) == 16, "");
_Static_assert(sizeof(struct fun_mut1_1) == 16, "");
_Static_assert(sizeof(struct log_level) == 8, "");
_Static_assert(sizeof(struct fun1) == 8, "");
_Static_assert(sizeof(struct opt_3) == 16, "");
_Static_assert(sizeof(struct fun2) == 8, "");
_Static_assert(sizeof(struct fut_state_1) == 24, "");
_Static_assert(sizeof(struct result_1) == 24, "");
_Static_assert(sizeof(struct fun_mut1_2) == 16, "");
_Static_assert(sizeof(struct opt_4) == 16, "");
_Static_assert(sizeof(struct fun_mut0_1) == 16, "");
_Static_assert(sizeof(struct fun_mut1_3) == 16, "");
_Static_assert(sizeof(struct fun_mut1_4) == 8, "");
_Static_assert(sizeof(struct fun_mut1_5) == 16, "");
_Static_assert(sizeof(struct opt_5) == 32, "");
_Static_assert(sizeof(struct result_2) == 48, "");
_Static_assert(sizeof(struct opt_6) == 48, "");
_Static_assert(sizeof(struct opt_7) == 40, "");
_Static_assert(sizeof(struct opt_8) == 48, "");
char constantarr_0_0[17];
char constantarr_0_1[4];
char constantarr_0_2[20];
char constantarr_0_3[1];
char constantarr_0_4[17];
char constantarr_0_5[13];
char constantarr_0_6[13];
char constantarr_0_7[4];
char constantarr_0_8[4];
char constantarr_0_9[2];
char constantarr_0_10[38];
char constantarr_0_11[33];
char constantarr_0_12[39];
char constantarr_0_13[11];
char constantarr_0_14[13];
char constantarr_0_15[1];
char constantarr_0_16[1];
char constantarr_0_0[17] = "Assertion failed!";
char constantarr_0_1[4] = "TODO";
char constantarr_0_2[20] = "uncaught exception: ";
char constantarr_0_3[1] = "\n";
char constantarr_0_4[17] = "<<empty message>>";
char constantarr_0_5[13] = "assert failed";
char constantarr_0_6[13] = "forbid failed";
char constantarr_0_7[4] = "info";
char constantarr_0_8[4] = "warn";
char constantarr_0_9[2] = ": ";
char constantarr_0_10[38] = "Couldn't acquire lock after 1000 tries";
char constantarr_0_11[33] = "resolving an already-resolved fut";
char constantarr_0_12[39] = "Did not find the element in the mut-arr";
char constantarr_0_13[11] = "unreachable";
char constantarr_0_14[13] = "main failed: ";
char constantarr_0_15[1] = "a";
char constantarr_0_16[1] = "b";
uint8_t mark(struct mark_ctx* ctx, uint8_t* ptr_any, uint64_t size_bytes);
uint64_t words_of_bytes(uint64_t size_bytes);
uint64_t round_up_to_multiple_of_8(uint64_t n);
struct void_ hard_assert(uint8_t condition);
uint8_t _op_equal_equal_0(uint64_t a, uint64_t b);
struct comparison compare_5(uint64_t a, uint64_t b);
uint64_t _op_minus_0(uint64_t* a, uint64_t* b);
uint8_t _op_less(uint64_t a, uint64_t b);
uint8_t _op_less_equal(uint64_t a, uint64_t b);
uint8_t mark_range_recur(uint8_t marked_anything__q, uint8_t* cur, uint8_t* end);
uint8_t* incr_0(uint8_t* p);
uint8_t _op_greater(uint64_t a, uint64_t b);
int32_t rt_main(int32_t argc, char** argv, fun_ptr2 main_ptr);
struct void_ drop_0(struct arr_0 t);
struct arr_0 to_str_0(char* a);
struct arr_0 arr_from_begin_end(char* begin, char* end);
uint64_t _op_minus_1(char* a, char* b);
char* find_cstr_end(char* a);
char* find_char_in_cstr(char* a, char c);
uint8_t _op_equal_equal_1(char a, char b);
struct comparison compare_20(char a, char b);
char* todo_0(void);
char* incr_1(char* p);
struct lock new_lock(void);
struct _atomic_bool new_atomic_bool(void);
struct arr_2 empty_arr(void);
struct condition new_condition(void);
struct island new_island(struct global_ctx* gctx, uint64_t id, uint64_t max_threads);
struct mut_arr_0 new_mut_arr_by_val_with_capacity_from_unmanaged_memory(uint64_t capacity);
uint64_t* unmanaged_alloc_elements_0(uint64_t size_elements);
uint8_t* unmanaged_alloc_bytes(uint64_t size);
extern uint8_t* malloc(uint64_t size);
struct void_ hard_forbid(uint8_t condition);
uint8_t null__q_0(uint8_t* a);
struct mut_bag new_mut_bag(void);
struct void_ default_exception_handler(struct ctx* ctx, struct exception e);
struct void_ print_err_no_newline(struct arr_0 s);
struct void_ write_no_newline(int32_t fd, struct arr_0 a);
extern int64_t write(int32_t fd, uint8_t* buff, uint64_t n_bytes);
uint8_t _op_bang_equal_0(int64_t a, int64_t b);
uint8_t _op_equal_equal_2(int64_t a, int64_t b);
struct comparison compare_41(int64_t a, int64_t b);
struct void_ todo_1(void);
int32_t stderr_fd(void);
struct void_ print_err(struct arr_0 s);
uint8_t empty__q_0(struct arr_0 a);
struct global_ctx* get_gctx(struct ctx* ctx);
struct void_ new_island__lambda0(struct ctx* ctx, struct void_ _closure, struct exception it);
struct void_ default_log_handler(struct ctx* ctx, struct logged* a);
struct void_ print(struct arr_0 a);
struct void_ print_no_newline(struct arr_0 a);
int32_t stdout_fd(void);
struct arr_0 _op_plus_0(struct ctx* ctx, struct arr_0 a, struct arr_0 b);
uint64_t _op_plus_1(struct ctx* ctx, uint64_t a, uint64_t b);
struct void_ assert_0(struct ctx* ctx, uint8_t condition);
struct void_ assert_1(struct ctx* ctx, uint8_t condition, struct arr_0 message);
struct void_ fail(struct ctx* ctx, struct arr_0 reason);
struct void_ throw(struct ctx* ctx, struct exception e);
struct exception_ctx* get_exception_ctx(struct ctx* ctx);
uint8_t null__q_1(struct jmp_buf_tag* a);
extern void longjmp(struct jmp_buf_tag* env, int32_t val);
int32_t number_to_throw(struct ctx* ctx);
uint8_t _op_greater_equal(uint64_t a, uint64_t b);
char* uninitialized_data_0(struct ctx* ctx, uint64_t size);
uint8_t* alloc(struct ctx* ctx, uint64_t size);
uint8_t* gc_alloc(struct ctx* ctx, struct gc* gc, uint64_t size);
struct opt_3 try_gc_alloc(struct gc* gc, uint64_t size_bytes);
struct void_ validate_gc(struct gc* gc);
uint8_t ptr_less_eq__q_0(uint8_t* a, uint8_t* b);
uint8_t ptr_less_eq__q_1(uint64_t* a, uint64_t* b);
uint64_t _op_minus_2(uint8_t* a, uint8_t* b);
uint8_t range_free__q(uint8_t* mark, uint8_t* end);
uint64_t* incr_2(uint64_t* p);
uint8_t* todo_2(void);
struct gc* get_gc(struct ctx* ctx);
struct gc_ctx* get_gc_ctx_0(struct ctx* ctx);
struct void_ copy_data_from(struct ctx* ctx, char* to, char* from, uint64_t len);
struct void_ copy_data_from_small(struct ctx* ctx, char* to, char* from, uint64_t len);
uint8_t _op_bang_equal_1(uint64_t a, uint64_t b);
uint64_t decr(struct ctx* ctx, uint64_t a);
struct void_ forbid_0(struct ctx* ctx, uint8_t condition);
struct void_ forbid_1(struct ctx* ctx, uint8_t condition, struct arr_0 message);
uint64_t wrap_decr(uint64_t a);
uint64_t _op_div(struct ctx* ctx, uint64_t a, uint64_t b);
uint64_t _op_minus_3(struct ctx* ctx, uint64_t a, uint64_t b);
struct arr_0 to_str_1(struct ctx* ctx, struct log_level a);
struct void_ new_island__lambda1(struct ctx* ctx, struct void_ _closure, struct logged* log);
struct gc new_gc(void);
extern void memset(uint8_t* begin, uint8_t value, uint64_t size);
struct thread_safe_counter new_thread_safe_counter_0(void);
struct thread_safe_counter new_thread_safe_counter_1(uint64_t init);
struct fut_0* do_main(struct global_ctx* gctx, struct island* island, int32_t argc, char** argv, fun_ptr2 main_ptr);
struct exception_ctx new_exception_ctx(void);
struct log_ctx new_log_ctx(void);
struct ctx new_ctx(struct global_ctx* gctx, struct thread_local_stuff* tls, struct island* island, uint64_t exclusion);
struct gc_ctx* get_gc_ctx_1(struct gc* gc);
struct void_ acquire_lock(struct lock* a);
struct void_ acquire_lock_recur(struct lock* a, uint64_t n_tries);
uint8_t try_acquire_lock(struct lock* a);
uint8_t try_set(struct _atomic_bool* a);
uint8_t try_change(struct _atomic_bool* a, uint8_t old_value);
struct void_ yield_thread(void);
extern int32_t pthread_yield(void);
uint8_t _op_equal_equal_3(int32_t a, int32_t b);
struct comparison compare_104(int32_t a, int32_t b);
uint64_t noctx_incr(uint64_t n);
uint64_t max_nat(void);
uint64_t wrap_incr(uint64_t a);
struct void_ release_lock(struct lock* l);
struct void_ must_unset(struct _atomic_bool* a);
uint8_t try_unset(struct _atomic_bool* a);
struct fut_0* add_first_task(struct ctx* ctx, struct arr_3 all_args, fun_ptr2 main_ptr);
struct fut_0* then2(struct ctx* ctx, struct fut_1* f, struct fun_ref0 cb);
struct fut_0* then(struct ctx* ctx, struct fut_1* f, struct fun_ref1 cb);
struct fut_0* new_unresolved_fut(struct ctx* ctx);
struct void_ then_void_0(struct ctx* ctx, struct fut_1* f, struct fun_mut1_2 cb);
struct void_ call_0(struct ctx* ctx, struct fun_mut1_2 a, struct result_1 p0);
struct void_ call_w_ctx_117(struct fun_mut1_2 a, struct ctx* ctx, struct result_1 p0);
struct void_ forward_to(struct ctx* ctx, struct fut_0* from, struct fut_0* to);
struct void_ then_void_1(struct ctx* ctx, struct fut_0* f, struct fun_mut1_0 cb);
struct void_ call_1(struct ctx* ctx, struct fun_mut1_0 a, struct result_0 p0);
struct void_ call_w_ctx_121(struct fun_mut1_0 a, struct ctx* ctx, struct result_0 p0);
struct void_ resolve_or_reject(struct ctx* ctx, struct fut_0* f, struct result_0 result);
struct void_ resolve_or_reject_recur(struct ctx* ctx, struct opt_0 node, struct result_0 value);
struct void_ drop_1(struct void_ t);
struct void_ forward_to__lambda0(struct ctx* ctx, struct forward_to__lambda0* _closure, struct result_0 it);
struct fut_0* call_ref_0(struct ctx* ctx, struct fun_ref1 f, struct void_ p0);
struct island* get_island(struct ctx* ctx, uint64_t island_id);
struct island* at_0(struct ctx* ctx, struct arr_2 a, uint64_t index);
struct island* noctx_at_0(struct arr_2 a, uint64_t index);
struct void_ add_task(struct ctx* ctx, struct island* a, struct task t);
struct mut_bag_node* new_mut_bag_node(struct ctx* ctx, struct task value);
struct void_ add(struct mut_bag* bag, struct mut_bag_node* node);
struct mut_bag* tasks(struct island* a);
struct void_ broadcast(struct condition* c);
struct void_ catch(struct ctx* ctx, struct fun_mut0_0 try, struct fun_mut1_1 catcher);
struct void_ catch_with_exception_ctx(struct ctx* ctx, struct exception_ctx* ec, struct fun_mut0_0 try, struct fun_mut1_1 catcher);
struct bytes64 zero_0(void);
struct bytes32 zero_1(void);
struct bytes16 zero_2(void);
struct bytes128 zero_3(void);
extern int32_t setjmp(struct jmp_buf_tag* env);
struct void_ call_2(struct ctx* ctx, struct fun_mut0_0 a);
struct void_ call_w_ctx_143(struct fun_mut0_0 a, struct ctx* ctx);
struct void_ call_3(struct ctx* ctx, struct fun_mut1_1 a, struct exception p0);
struct void_ call_w_ctx_145(struct fun_mut1_1 a, struct ctx* ctx, struct exception p0);
struct fut_0* call_4(struct ctx* ctx, struct fun_mut1_3 a, struct void_ p0);
struct fut_0* call_w_ctx_147(struct fun_mut1_3 a, struct ctx* ctx, struct void_ p0);
struct void_ call_ref_0__lambda0__lambda0(struct ctx* ctx, struct call_ref_0__lambda0__lambda0* _closure);
struct void_ reject(struct ctx* ctx, struct fut_0* f, struct exception e);
struct void_ call_ref_0__lambda0__lambda1(struct ctx* ctx, struct call_ref_0__lambda0__lambda1* _closure, struct exception it);
struct void_ call_ref_0__lambda0(struct ctx* ctx, struct call_ref_0__lambda0* _closure);
struct void_ then__lambda0(struct ctx* ctx, struct then__lambda0* _closure, struct result_1 result);
struct fut_0* call_ref_1(struct ctx* ctx, struct fun_ref0 f);
struct fut_0* call_5(struct ctx* ctx, struct fun_mut0_1 a);
struct fut_0* call_w_ctx_155(struct fun_mut0_1 a, struct ctx* ctx);
struct void_ call_ref_1__lambda0__lambda0(struct ctx* ctx, struct call_ref_1__lambda0__lambda0* _closure);
struct void_ call_ref_1__lambda0__lambda1(struct ctx* ctx, struct call_ref_1__lambda0__lambda1* _closure, struct exception it);
struct void_ call_ref_1__lambda0(struct ctx* ctx, struct call_ref_1__lambda0* _closure);
struct fut_0* then2__lambda0(struct ctx* ctx, struct then2__lambda0* _closure, struct void_ ignore);
struct island_and_exclusion cur_island_and_exclusion(struct ctx* ctx);
struct fut_1* delay(struct ctx* ctx);
struct fut_1* resolved_0(struct ctx* ctx, struct void_ value);
struct arr_3 tail(struct ctx* ctx, struct arr_3 a);
uint8_t empty__q_1(struct arr_3 a);
struct arr_3 slice_starting_at(struct ctx* ctx, struct arr_3 a, uint64_t begin);
struct arr_3 slice(struct ctx* ctx, struct arr_3 a, uint64_t begin, uint64_t size);
struct arr_1 map(struct ctx* ctx, struct arr_3 a, struct fun_mut1_4 mapper);
struct arr_1 make_arr(struct ctx* ctx, uint64_t size, struct fun_mut1_5 f);
struct arr_1 freeze(struct mut_arr_1* a);
struct arr_1 unsafe_as_arr(struct mut_arr_1* a);
struct mut_arr_1* make_mut_arr(struct ctx* ctx, uint64_t size, struct fun_mut1_5 f);
struct mut_arr_1* new_uninitialized_mut_arr(struct ctx* ctx, uint64_t size);
struct arr_0* uninitialized_data_1(struct ctx* ctx, uint64_t size);
struct void_ make_mut_arr_worker(struct ctx* ctx, struct mut_arr_1* m, uint64_t i, struct fun_mut1_5 f);
struct void_ set_at(struct ctx* ctx, struct mut_arr_1* a, uint64_t index, struct arr_0 value);
struct void_ noctx_set_at_0(struct mut_arr_1* a, uint64_t index, struct arr_0 value);
struct arr_0 call_6(struct ctx* ctx, struct fun_mut1_5 a, uint64_t p0);
struct arr_0 call_w_ctx_178(struct fun_mut1_5 a, struct ctx* ctx, uint64_t p0);
uint64_t incr_3(struct ctx* ctx, uint64_t n);
struct arr_0 call_7(struct ctx* ctx, struct fun_mut1_4 a, char* p0);
struct arr_0 call_w_ctx_181(struct fun_mut1_4 a, struct ctx* ctx, char* p0);
char* at_1(struct ctx* ctx, struct arr_3 a, uint64_t index);
char* noctx_at_1(struct arr_3 a, uint64_t index);
struct arr_0 map__lambda0(struct ctx* ctx, struct map__lambda0* _closure, uint64_t i);
struct arr_0 add_first_task__lambda0__lambda0(struct ctx* ctx, struct void_ _closure, char* it);
struct fut_0* add_first_task__lambda0(struct ctx* ctx, struct add_first_task__lambda0* _closure);
struct fut_0* do_main__lambda0(struct ctx* ctx, struct void_ _closure, struct arr_3 all_args, fun_ptr2 main_ptr);
struct fut_0* call_w_ctx_188(struct fun2 a, struct ctx* ctx, struct arr_3 p0, fun_ptr2 p1);
struct void_ run_threads(uint64_t n_threads, struct global_ctx* gctx);
struct thread_args* unmanaged_alloc_elements_1(uint64_t size_elements);
uint64_t noctx_decr(uint64_t n);
struct void_ start_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads, struct thread_args* thread_args_begin, struct global_ctx* gctx);
extern int32_t pthread_create(struct cell_0* thread, uint8_t* attr, fun_ptr1 start_routine, uint8_t* arg);
struct cell_0* as_cell(uint64_t* p);
uint8_t* thread_fun(uint8_t* args_ptr);
struct void_ thread_function(uint64_t thread_id, struct global_ctx* gctx);
struct void_ thread_function_recur(uint64_t thread_id, struct global_ctx* gctx, struct thread_local_stuff* tls);
struct void_ assert_islands_are_shut_down(uint64_t i, struct arr_2 islands);
uint8_t empty__q_2(struct mut_bag* m);
uint8_t empty__q_3(struct opt_2 a);
uint64_t get_last_checked(struct condition* c);
struct result_2 choose_task(struct global_ctx* gctx);
struct opt_6 choose_task_recur(struct arr_2 islands, uint64_t i);
struct opt_7 choose_task_in_island(struct island* island);
struct opt_5 find_and_remove_first_doable_task(struct island* island);
struct opt_8 find_and_remove_first_doable_task_recur(struct island* island, struct opt_2 opt_node);
uint8_t contains__q(struct mut_arr_0* a, uint64_t value);
uint8_t contains_recur__q(struct arr_4 a, uint64_t value, uint64_t i);
uint64_t noctx_at_2(struct arr_4 a, uint64_t index);
struct arr_4 temp_as_arr(struct mut_arr_0* a);
struct void_ push_capacity_must_be_sufficient(struct mut_arr_0* a, uint64_t value);
struct void_ noctx_set_at_1(struct mut_arr_0* a, uint64_t index, uint64_t value);
uint8_t empty__q_4(struct opt_7 a);
struct void_ do_task(struct global_ctx* gctx, struct thread_local_stuff* tls, struct chosen_task chosen_task);
struct void_ run_garbage_collection(struct gc* gc, struct island_gc_root gc_root);
struct void_ mark_visit_216(struct mark_ctx* mark_ctx, struct island_gc_root value);
struct void_ mark_visit_217(struct mark_ctx* mark_ctx, struct mut_bag value);
struct void_ mark_visit_218(struct mark_ctx* mark_ctx, struct opt_2 value);
struct void_ mark_visit_219(struct mark_ctx* mark_ctx, struct some_2 value);
struct void_ mark_visit_220(struct mark_ctx* mark_ctx, struct mut_bag_node value);
struct void_ mark_visit_221(struct mark_ctx* mark_ctx, struct task value);
struct void_ mark_visit_222(struct mark_ctx* mark_ctx, struct fun_mut0_0 value);
struct void_ mark_visit_223(struct mark_ctx* mark_ctx, struct call_ref_0__lambda0__lambda0 value);
struct void_ mark_visit_224(struct mark_ctx* mark_ctx, struct fun_ref1 value);
struct void_ mark_visit_225(struct mark_ctx* mark_ctx, struct fun_mut1_3 value);
struct void_ mark_visit_226(struct mark_ctx* mark_ctx, struct then2__lambda0 value);
struct void_ mark_visit_227(struct mark_ctx* mark_ctx, struct fun_ref0 value);
struct void_ mark_visit_228(struct mark_ctx* mark_ctx, struct fun_mut0_1 value);
struct void_ mark_visit_229(struct mark_ctx* mark_ctx, struct add_first_task__lambda0 value);
struct void_ mark_arr_230(struct mark_ctx* mark_ctx, struct arr_3 a);
struct void_ mark_visit_231(struct mark_ctx* mark_ctx, struct add_first_task__lambda0* value);
struct void_ mark_visit_232(struct mark_ctx* mark_ctx, struct then2__lambda0* value);
struct void_ mark_visit_233(struct mark_ctx* mark_ctx, struct fut_0 value);
struct void_ mark_visit_234(struct mark_ctx* mark_ctx, struct fut_state_0 value);
struct void_ mark_visit_235(struct mark_ctx* mark_ctx, struct fut_state_callbacks_0 value);
struct void_ mark_visit_236(struct mark_ctx* mark_ctx, struct opt_0 value);
struct void_ mark_visit_237(struct mark_ctx* mark_ctx, struct some_0 value);
struct void_ mark_visit_238(struct mark_ctx* mark_ctx, struct fut_callback_node_0 value);
struct void_ mark_visit_239(struct mark_ctx* mark_ctx, struct fun_mut1_0 value);
struct void_ mark_visit_240(struct mark_ctx* mark_ctx, struct forward_to__lambda0 value);
struct void_ mark_visit_241(struct mark_ctx* mark_ctx, struct fut_0* value);
struct void_ mark_visit_242(struct mark_ctx* mark_ctx, struct forward_to__lambda0* value);
struct void_ mark_visit_243(struct mark_ctx* mark_ctx, struct fut_callback_node_0* value);
struct void_ mark_visit_244(struct mark_ctx* mark_ctx, struct exception value);
struct void_ mark_arr_245(struct mark_ctx* mark_ctx, struct arr_0 a);
struct void_ mark_visit_246(struct mark_ctx* mark_ctx, struct call_ref_0__lambda0__lambda0* value);
struct void_ mark_visit_247(struct mark_ctx* mark_ctx, struct call_ref_0__lambda0 value);
struct void_ mark_visit_248(struct mark_ctx* mark_ctx, struct call_ref_0__lambda0* value);
struct void_ mark_visit_249(struct mark_ctx* mark_ctx, struct call_ref_1__lambda0__lambda0 value);
struct void_ mark_visit_250(struct mark_ctx* mark_ctx, struct call_ref_1__lambda0__lambda0* value);
struct void_ mark_visit_251(struct mark_ctx* mark_ctx, struct call_ref_1__lambda0 value);
struct void_ mark_visit_252(struct mark_ctx* mark_ctx, struct call_ref_1__lambda0* value);
struct void_ mark_visit_253(struct mark_ctx* mark_ctx, struct mut_bag_node* value);
struct void_ mark_visit_254(struct mark_ctx* mark_ctx, struct fun_mut1_1 value);
struct void_ mark_visit_255(struct mark_ctx* mark_ctx, struct call_ref_0__lambda0__lambda1 value);
struct void_ mark_visit_256(struct mark_ctx* mark_ctx, struct call_ref_0__lambda0__lambda1* value);
struct void_ mark_visit_257(struct mark_ctx* mark_ctx, struct call_ref_1__lambda0__lambda1 value);
struct void_ mark_visit_258(struct mark_ctx* mark_ctx, struct call_ref_1__lambda0__lambda1* value);
struct void_ noctx_must_remove_unordered(struct mut_arr_0* a, uint64_t value);
struct void_ noctx_must_remove_unordered_recur(struct mut_arr_0* a, uint64_t index, uint64_t value);
uint64_t noctx_at_3(struct mut_arr_0* a, uint64_t index);
struct void_ drop_2(uint64_t t);
uint64_t noctx_remove_unordered_at_index(struct mut_arr_0* a, uint64_t index);
uint64_t noctx_last(struct mut_arr_0* a);
uint8_t empty__q_5(struct mut_arr_0* a);
struct void_ return_ctx(struct ctx* c);
struct void_ return_gc_ctx(struct gc_ctx* gc_ctx);
struct void_ wait_on(struct condition* c, uint64_t last_checked);
int32_t eagain(void);
struct void_ join_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads);
struct void_ join_one_thread(uint64_t tid);
extern int32_t pthread_join(uint64_t thread, struct cell_1* thread_return);
uint8_t _op_bang_equal_2(int32_t a, int32_t b);
int32_t einval(void);
int32_t esrch(void);
uint8_t* get(struct cell_1* c);
struct void_ unmanaged_free_0(uint64_t* p);
extern void free(uint8_t* p);
struct void_ unmanaged_free_1(struct thread_args* p);
struct result_0 must_be_resolved(struct fut_0* f);
struct result_0 hard_unreachable(void);
struct fut_0* main_0(struct ctx* ctx, struct arr_1 args);
struct void_ foo(struct ctx* ctx, struct my_record* r);
struct fut_0* resolved_1(struct ctx* ctx, int32_t value);
int32_t main(int32_t argc, char** argv);
/* mark bool(ctx mark-ctx, ptr-any ptr<nat8>, size-bytes nat) */
uint8_t mark(struct mark_ctx* ctx, uint8_t* ptr_any, uint64_t size_bytes) {
	uint64_t size_words0;
	uint64_t _0 = size_bytes;
	size_words0 = words_of_bytes(_0);
	
	uint64_t* ptr1;
	uint8_t* _1 = ptr_any;
	ptr1 = (uint64_t*) _1;
	
	uint64_t* _2 = ptr1;
	uint64_t _3 = (uint64_t) _2;
	uint64_t _4 = 7u;
	uint64_t _5 = _3 & _4;
	uint64_t _6 = 0u;
	uint8_t _7 = _op_equal_equal_0(_5, _6);
	hard_assert(_7);
	uint64_t index2;
	uint64_t* _8 = ptr1;
	struct mark_ctx* _9 = ctx;
	uint64_t* _10 = _9->memory_start;
	index2 = _op_minus_0(_8, _10);
	
	uint8_t gc_memory__q3;
	uint64_t _11 = index2;
	struct mark_ctx* _12 = ctx;
	uint64_t _13 = _12->memory_size_words;
	gc_memory__q3 = _op_less(_11, _13);
	
	uint8_t _14 = gc_memory__q3;
	if (_14) {
		uint64_t _15 = index2;
		uint64_t _16 = size_words0;
		uint64_t _17 = _15 + _16;
		struct mark_ctx* _18 = ctx;
		uint64_t _19 = _18->memory_size_words;
		uint8_t _20 = _op_less_equal(_17, _19);
		hard_assert(_20);
		uint8_t* mark_start4;
		struct mark_ctx* _21 = ctx;
		uint8_t* _22 = _21->marks;
		uint64_t _23 = index2;
		mark_start4 = _22 + _23;
		
		uint8_t* mark_end5;
		uint8_t* _24 = mark_start4;
		uint64_t _25 = size_words0;
		mark_end5 = _24 + _25;
		
		uint8_t _26 = 0;
		uint8_t* _27 = mark_start4;
		uint8_t* _28 = mark_end5;
		return mark_range_recur(_26, _27, _28);
	} else {
		uint64_t _29 = index2;
		uint64_t _30 = size_words0;
		uint64_t _31 = _29 + _30;
		struct mark_ctx* _32 = ctx;
		uint64_t _33 = _32->memory_size_words;
		uint8_t _34 = _op_greater(_31, _33);
		hard_assert(_34);
		return 0;
	}
}
/* words-of-bytes nat(size-bytes nat) */
uint64_t words_of_bytes(uint64_t size_bytes) {
	uint64_t _0 = size_bytes;
	uint64_t _1 = round_up_to_multiple_of_8(_0);
	uint64_t _2 = 8u;
	return _1 / _2;
}
/* round-up-to-multiple-of-8 nat(n nat) */
uint64_t round_up_to_multiple_of_8(uint64_t n) {
	uint64_t _0 = n;
	uint64_t _1 = 7u;
	uint64_t _2 = _0 + _1;
	uint64_t _3 = 7u;
	uint64_t _4 = ~_3;
	return _2 & _4;
}
/* hard-assert void(condition bool) */
struct void_ hard_assert(uint8_t condition) {
	uint8_t _0 = condition;
	uint8_t _1 = !_0;
	if (_1) {
		return (assert(0),(struct void_) {});
	} else {
		return (struct void_) {};
	}
}
/* ==<nat> bool(a nat, b nat) */
uint8_t _op_equal_equal_0(uint64_t a, uint64_t b) {
	uint64_t _0 = a;
	uint64_t _1 = b;
	struct comparison _2 = compare_5(_0, _1);
	switch (_2.kind) {
		case 0: {
			return 0;
		}
		case 1: {
			return 1;
		}
		case 2: {
			return 0;
		}
		default:
			return (assert(0),0);
	}
}
/* compare<nat-64> (generated) (generated) */
struct comparison compare_5(uint64_t a, uint64_t b) {
	uint64_t _0 = a;
	uint64_t _1 = b;
	uint8_t _2 = _0 < _1;
	if (_2) {
		struct less _3 = (struct less) {};
		return (struct comparison) {0, .as0 = _3};
	} else {
		uint64_t _4 = b;
		uint64_t _5 = a;
		uint8_t _6 = _4 < _5;
		if (_6) {
			struct greater _7 = (struct greater) {};
			return (struct comparison) {2, .as2 = _7};
		} else {
			struct equal _8 = (struct equal) {};
			return (struct comparison) {1, .as1 = _8};
		}
	}
}
/* -<nat> nat(a ptr<nat>, b ptr<nat>) */
uint64_t _op_minus_0(uint64_t* a, uint64_t* b) {
	uint64_t* _0 = a;
	uint64_t _1 = (uint64_t) _0;
	uint64_t* _2 = b;
	uint64_t _3 = (uint64_t) _2;
	uint64_t _4 = _1 - _3;
	uint64_t _5 = sizeof(uint64_t);
	return _4 / _5;
}
/* <<nat> bool(a nat, b nat) */
uint8_t _op_less(uint64_t a, uint64_t b) {
	uint64_t _0 = a;
	uint64_t _1 = b;
	struct comparison _2 = compare_5(_0, _1);
	switch (_2.kind) {
		case 0: {
			return 1;
		}
		case 1: {
			return 0;
		}
		case 2: {
			return 0;
		}
		default:
			return (assert(0),0);
	}
}
/* <=<nat> bool(a nat, b nat) */
uint8_t _op_less_equal(uint64_t a, uint64_t b) {
	uint64_t _0 = b;
	uint64_t _1 = a;
	uint8_t _2 = _op_less(_0, _1);
	return !_2;
}
/* mark-range-recur bool(marked-anything? bool, cur ptr<bool>, end ptr<bool>) */
uint8_t mark_range_recur(uint8_t marked_anything__q, uint8_t* cur, uint8_t* end) {
	top:;
	uint8_t* _0 = cur;
	uint8_t* _1 = end;
	uint8_t _2 = _0 == _1;
	if (_2) {
		return marked_anything__q;
	} else {
		uint8_t new_marked_anything__q0;
		uint8_t _3 = marked_anything__q;
		if (_3) {
			new_marked_anything__q0 = 1;
		} else {
			uint8_t* _4 = cur;
			uint8_t _5 = *_4;
			new_marked_anything__q0 = !_5;
		}
		
		uint8_t* _6 = cur;
		uint8_t _7 = 1;
		*_6 = _7;
		uint8_t _8 = new_marked_anything__q0;
		uint8_t* _9 = cur;
		uint8_t* _10 = incr_0(_9);
		uint8_t* _11 = end;
		marked_anything__q = _8;
		cur = _10;
		end = _11;
		goto top;
	}
}
/* incr<bool> ptr<bool>(p ptr<bool>) */
uint8_t* incr_0(uint8_t* p) {
	uint8_t* _0 = p;
	uint64_t _1 = 1u;
	return _0 + _1;
}
/* ><nat> bool(a nat, b nat) */
uint8_t _op_greater(uint64_t a, uint64_t b) {
	uint64_t _0 = a;
	uint64_t _1 = b;
	uint8_t _2 = _op_less_equal(_0, _1);
	return !_2;
}
/* rt-main int32(argc int32, argv ptr<ptr<char>>, main-ptr fun-ptr2<fut<int32>, ctx, arr<arr<char>>>) */
int32_t rt_main(int32_t argc, char** argv, fun_ptr2 main_ptr) {
	char** _0 = argv;
	char* _1 = *_0;
	struct arr_0 _2 = to_str_0(_1);
	drop_0(_2);
	struct global_ctx gctx_by_val0;
	struct lock _3 = new_lock();
	struct arr_2 _4 = empty_arr();
	uint64_t _5 = 1u;
	struct condition _6 = new_condition();
	uint8_t _7 = 0;
	uint8_t _8 = 0;
	gctx_by_val0 = (struct global_ctx) {_3, _4, _5, _6, _7, _8};
	
	struct global_ctx* gctx1;
	gctx1 = &gctx_by_val0;
	
	struct island island_by_val2;
	struct global_ctx* _9 = gctx1;
	uint64_t _10 = 0u;
	uint64_t _11 = 1u;
	island_by_val2 = new_island(_9, _10, _11);
	
	struct island* island3;
	island3 = &island_by_val2;
	
	struct global_ctx* _12 = gctx1;
	uint64_t _13 = 1u;
	struct island** _14 = &island3;
	struct arr_2 _15 = (struct arr_2) {_13, _14};
	_12->islands = _15;
	struct fut_0* main_fut4;
	struct global_ctx* _16 = gctx1;
	struct island* _17 = island3;
	int32_t _18 = argc;
	char** _19 = argv;
	fun_ptr2 _20 = main_ptr;
	main_fut4 = do_main(_16, _17, _18, _19, _20);
	
	uint64_t _21 = 1u;
	struct global_ctx* _22 = gctx1;
	run_threads(_21, _22);
	struct global_ctx* _23 = gctx1;
	uint8_t _24 = _23->any_unhandled_exceptions__q;
	if (_24) {
		return 1;
	} else {
		struct fut_0* _25 = main_fut4;
		struct result_0 _26 = must_be_resolved(_25);
		switch (_26.kind) {
			case 0: {
				struct ok_0 o5 = _26.as0;
				
				struct ok_0 _27 = o5;
				return _27.value;
			}
			case 1: {
				struct err_0 e6 = _26.as1;
				
				struct arr_0 _28 = (struct arr_0) {13, constantarr_0_14};
				print_err_no_newline(_28);
				struct err_0 _29 = e6;
				struct exception _30 = _29.value;
				struct arr_0 _31 = _30.message;
				print_err(_31);
				return 1;
			}
			default:
				return (assert(0),0);
		}
	}
}
/* drop<arr<char>> void(t arr<char>) */
struct void_ drop_0(struct arr_0 t) {
	return (struct void_) {};
}
/* to-str arr<char>(a ptr<char>) */
struct arr_0 to_str_0(char* a) {
	char* _0 = a;
	char* _1 = a;
	char* _2 = find_cstr_end(_1);
	return arr_from_begin_end(_0, _2);
}
/* arr-from-begin-end<char> arr<char>(begin ptr<char>, end ptr<char>) */
struct arr_0 arr_from_begin_end(char* begin, char* end) {
	char* _0 = end;
	char* _1 = begin;
	uint64_t _2 = _op_minus_1(_0, _1);
	char* _3 = begin;
	return (struct arr_0) {_2, _3};
}
/* -<?t> nat(a ptr<char>, b ptr<char>) */
uint64_t _op_minus_1(char* a, char* b) {
	char* _0 = a;
	uint64_t _1 = (uint64_t) _0;
	char* _2 = b;
	uint64_t _3 = (uint64_t) _2;
	uint64_t _4 = _1 - _3;
	uint64_t _5 = sizeof(char);
	return _4 / _5;
}
/* find-cstr-end ptr<char>(a ptr<char>) */
char* find_cstr_end(char* a) {
	char* _0 = a;
	char _1 = 0u;
	return find_char_in_cstr(_0, _1);
}
/* find-char-in-cstr ptr<char>(a ptr<char>, c char) */
char* find_char_in_cstr(char* a, char c) {
	top:;
	char* _0 = a;
	char _1 = *_0;
	char _2 = c;
	uint8_t _3 = _op_equal_equal_1(_1, _2);
	if (_3) {
		return a;
	} else {
		char* _4 = a;
		char _5 = *_4;
		char _6 = 0u;
		uint8_t _7 = _op_equal_equal_1(_5, _6);
		if (_7) {
			return todo_0();
		} else {
			char* _8 = a;
			char* _9 = incr_1(_8);
			char _10 = c;
			a = _9;
			c = _10;
			goto top;
		}
	}
}
/* ==<char> bool(a char, b char) */
uint8_t _op_equal_equal_1(char a, char b) {
	char _0 = a;
	char _1 = b;
	struct comparison _2 = compare_20(_0, _1);
	switch (_2.kind) {
		case 0: {
			return 0;
		}
		case 1: {
			return 1;
		}
		case 2: {
			return 0;
		}
		default:
			return (assert(0),0);
	}
}
/* compare<char> (generated) (generated) */
struct comparison compare_20(char a, char b) {
	char _0 = a;
	char _1 = b;
	uint8_t _2 = _0 < _1;
	if (_2) {
		struct less _3 = (struct less) {};
		return (struct comparison) {0, .as0 = _3};
	} else {
		char _4 = b;
		char _5 = a;
		uint8_t _6 = _4 < _5;
		if (_6) {
			struct greater _7 = (struct greater) {};
			return (struct comparison) {2, .as2 = _7};
		} else {
			struct equal _8 = (struct equal) {};
			return (struct comparison) {1, .as1 = _8};
		}
	}
}
/* todo<ptr<char>> ptr<char>() */
char* todo_0(void) {
	return (assert(0),NULL);
}
/* incr<char> ptr<char>(p ptr<char>) */
char* incr_1(char* p) {
	char* _0 = p;
	uint64_t _1 = 1u;
	return _0 + _1;
}
/* new-lock lock() */
struct lock new_lock(void) {
	struct _atomic_bool _0 = new_atomic_bool();
	return (struct lock) {_0};
}
/* new-atomic-bool atomic-bool() */
struct _atomic_bool new_atomic_bool(void) {
	uint8_t _0 = 0;
	return (struct _atomic_bool) {_0};
}
/* empty-arr<island> arr<island>() */
struct arr_2 empty_arr(void) {
	uint64_t _0 = 0u;
	struct island** _1 = NULL;
	return (struct arr_2) {_0, _1};
}
/* new-condition condition() */
struct condition new_condition(void) {
	struct lock _0 = new_lock();
	uint64_t _1 = 0u;
	return (struct condition) {_0, _1};
}
/* new-island island(gctx global-ctx, id nat, max-threads nat) */
struct island new_island(struct global_ctx* gctx, uint64_t id, uint64_t max_threads) {
	struct mut_arr_0 exclusions0;
	uint64_t _0 = max_threads;
	exclusions0 = new_mut_arr_by_val_with_capacity_from_unmanaged_memory(_0);
	
	struct island_gc_root gc_root1;
	struct mut_bag _1 = new_mut_bag();
	struct void_ _2 = (struct void_) {};
	struct fun_mut1_1 _3 = (struct fun_mut1_1) {0, .as0 = _2};
	struct void_ _4 = (struct void_) {};
	struct fun1 _5 = (struct fun1) {0, .as0 = _4};
	gc_root1 = (struct island_gc_root) {_1, _3, _5};
	
	struct global_ctx* _6 = gctx;
	uint64_t _7 = id;
	struct gc _8 = new_gc();
	struct island_gc_root _9 = gc_root1;
	struct lock _10 = new_lock();
	struct mut_arr_0 _11 = exclusions0;
	uint64_t _12 = 0u;
	struct thread_safe_counter _13 = new_thread_safe_counter_0();
	return (struct island) {_6, _7, _8, _9, _10, _11, _12, _13};
}
/* new-mut-arr-by-val-with-capacity-from-unmanaged-memory<nat> mut-arr<nat>(capacity nat) */
struct mut_arr_0 new_mut_arr_by_val_with_capacity_from_unmanaged_memory(uint64_t capacity) {
	uint8_t _0 = 0;
	uint64_t _1 = 0u;
	uint64_t _2 = capacity;
	uint64_t _3 = capacity;
	uint64_t* _4 = unmanaged_alloc_elements_0(_3);
	return (struct mut_arr_0) {_0, _1, _2, _4};
}
/* unmanaged-alloc-elements<?t> ptr<nat>(size-elements nat) */
uint64_t* unmanaged_alloc_elements_0(uint64_t size_elements) {
	uint8_t* bytes0;
	uint64_t _0 = size_elements;
	uint64_t _1 = sizeof(uint64_t);
	uint64_t _2 = _0 * _1;
	bytes0 = unmanaged_alloc_bytes(_2);
	
	uint8_t* _3 = bytes0;
	return (uint64_t*) _3;
}
/* unmanaged-alloc-bytes ptr<nat8>(size nat) */
uint8_t* unmanaged_alloc_bytes(uint64_t size) {
	uint8_t* res0;
	uint64_t _0 = size;
	res0 = malloc(_0);
	
	uint8_t* _1 = res0;
	uint8_t _2 = null__q_0(_1);
	hard_forbid(_2);
	return res0;
}
/* hard-forbid void(condition bool) */
struct void_ hard_forbid(uint8_t condition) {
	uint8_t _0 = condition;
	uint8_t _1 = !_0;
	return hard_assert(_1);
}
/* null?<nat8> bool(a ptr<nat8>) */
uint8_t null__q_0(uint8_t* a) {
	uint8_t* _0 = a;
	uint64_t _1 = (uint64_t) _0;
	uint8_t* _2 = NULL;
	uint64_t _3 = (uint64_t) _2;
	return _op_equal_equal_0(_1, _3);
}
/* new-mut-bag<task> mut-bag<task>() */
struct mut_bag new_mut_bag(void) {
	struct none _0 = (struct none) {};
	struct opt_2 _1 = (struct opt_2) {0, .as0 = _0};
	return (struct mut_bag) {_1};
}
/* default-exception-handler void(e exception) */
struct void_ default_exception_handler(struct ctx* ctx, struct exception e) {
	struct arr_0 _0 = (struct arr_0) {20, constantarr_0_2};
	print_err_no_newline(_0);
	struct exception _1 = e;
	struct arr_0 _2 = _1.message;
	uint8_t _3 = empty__q_0(_2);struct arr_0 _4;
	
	if (_3) {
		_4 = (struct arr_0) {17, constantarr_0_4};
	} else {
		struct exception _5 = e;
		_4 = _5.message;
	}
	print_err(_4);
	struct ctx* _6 = ctx;
	struct global_ctx* _7 = get_gctx(_6);
	uint8_t _8 = 1;
	return (_7->any_unhandled_exceptions__q = _8, (struct void_) {});
}
/* print-err-no-newline void(s arr<char>) */
struct void_ print_err_no_newline(struct arr_0 s) {
	int32_t _0 = stderr_fd();
	struct arr_0 _1 = s;
	return write_no_newline(_0, _1);
}
/* write-no-newline void(fd int32, a arr<char>) */
struct void_ write_no_newline(int32_t fd, struct arr_0 a) {
	uint64_t _0 = sizeof(char);
	uint64_t _1 = sizeof(uint8_t);
	uint8_t _2 = _op_equal_equal_0(_0, _1);
	hard_assert(_2);
	int64_t res0;
	int32_t _3 = fd;
	struct arr_0 _4 = a;
	char* _5 = _4.data;
	uint8_t* _6 = (uint8_t*) _5;
	struct arr_0 _7 = a;
	uint64_t _8 = _7.size;
	res0 = write(_3, _6, _8);
	
	int64_t _9 = res0;
	struct arr_0 _10 = a;
	uint64_t _11 = _10.size;
	int64_t _12 = (int64_t) _11;
	uint8_t _13 = _op_bang_equal_0(_9, _12);
	if (_13) {
		return todo_1();
	} else {
		return (struct void_) {};
	}
}
/* !=<int> bool(a int, b int) */
uint8_t _op_bang_equal_0(int64_t a, int64_t b) {
	int64_t _0 = a;
	int64_t _1 = b;
	uint8_t _2 = _op_equal_equal_2(_0, _1);
	return !_2;
}
/* ==<?t> bool(a int, b int) */
uint8_t _op_equal_equal_2(int64_t a, int64_t b) {
	int64_t _0 = a;
	int64_t _1 = b;
	struct comparison _2 = compare_41(_0, _1);
	switch (_2.kind) {
		case 0: {
			return 0;
		}
		case 1: {
			return 1;
		}
		case 2: {
			return 0;
		}
		default:
			return (assert(0),0);
	}
}
/* compare<int-64> (generated) (generated) */
struct comparison compare_41(int64_t a, int64_t b) {
	int64_t _0 = a;
	int64_t _1 = b;
	uint8_t _2 = _0 < _1;
	if (_2) {
		struct less _3 = (struct less) {};
		return (struct comparison) {0, .as0 = _3};
	} else {
		int64_t _4 = b;
		int64_t _5 = a;
		uint8_t _6 = _4 < _5;
		if (_6) {
			struct greater _7 = (struct greater) {};
			return (struct comparison) {2, .as2 = _7};
		} else {
			struct equal _8 = (struct equal) {};
			return (struct comparison) {1, .as1 = _8};
		}
	}
}
/* todo<void> void() */
struct void_ todo_1(void) {
	return (assert(0),(struct void_) {});
}
/* stderr-fd int32() */
int32_t stderr_fd(void) {
	return 2;
}
/* print-err void(s arr<char>) */
struct void_ print_err(struct arr_0 s) {
	struct arr_0 _0 = s;
	print_err_no_newline(_0);
	struct arr_0 _1 = (struct arr_0) {1, constantarr_0_3};
	return print_err_no_newline(_1);
}
/* empty?<char> bool(a arr<char>) */
uint8_t empty__q_0(struct arr_0 a) {
	struct arr_0 _0 = a;
	uint64_t _1 = _0.size;
	uint64_t _2 = 0u;
	return _op_equal_equal_0(_1, _2);
}
/* get-gctx global-ctx() */
struct global_ctx* get_gctx(struct ctx* ctx) {
	struct ctx* _0 = ctx;
	uint8_t* _1 = _0->gctx_ptr;
	return (struct global_ctx*) _1;
}
/* new-island.lambda0 void(it exception) */
struct void_ new_island__lambda0(struct ctx* ctx, struct void_ _closure, struct exception it) {
	struct ctx* _0 = ctx;
	struct exception _1 = it;
	return default_exception_handler(_0, _1);
}
/* default-log-handler void(a logged) */
struct void_ default_log_handler(struct ctx* ctx, struct logged* a) {
	struct ctx* _0 = ctx;
	struct ctx* _1 = ctx;
	struct ctx* _2 = ctx;
	struct logged* _3 = a;
	struct log_level _4 = _3->level;
	struct arr_0 _5 = to_str_1(_2, _4);
	struct arr_0 _6 = (struct arr_0) {2, constantarr_0_9};
	struct arr_0 _7 = _op_plus_0(_1, _5, _6);
	struct logged* _8 = a;
	struct arr_0 _9 = _8->message;
	struct arr_0 _10 = _op_plus_0(_0, _7, _9);
	return print(_10);
}
/* print void(a arr<char>) */
struct void_ print(struct arr_0 a) {
	struct arr_0 _0 = a;
	print_no_newline(_0);
	struct arr_0 _1 = (struct arr_0) {1, constantarr_0_3};
	return print_no_newline(_1);
}
/* print-no-newline void(a arr<char>) */
struct void_ print_no_newline(struct arr_0 a) {
	int32_t _0 = stdout_fd();
	struct arr_0 _1 = a;
	return write_no_newline(_0, _1);
}
/* stdout-fd int32() */
int32_t stdout_fd(void) {
	return 1;
}
/* +<char> arr<char>(a arr<char>, b arr<char>) */
struct arr_0 _op_plus_0(struct ctx* ctx, struct arr_0 a, struct arr_0 b) {
	uint64_t res_size0;
	struct ctx* _0 = ctx;
	struct arr_0 _1 = a;
	uint64_t _2 = _1.size;
	struct arr_0 _3 = b;
	uint64_t _4 = _3.size;
	res_size0 = _op_plus_1(_0, _2, _4);
	
	char* res1;
	struct ctx* _5 = ctx;
	uint64_t _6 = res_size0;
	res1 = uninitialized_data_0(_5, _6);
	
	struct ctx* _7 = ctx;
	char* _8 = res1;
	struct arr_0 _9 = a;
	char* _10 = _9.data;
	struct arr_0 _11 = a;
	uint64_t _12 = _11.size;
	copy_data_from(_7, _8, _10, _12);
	struct ctx* _13 = ctx;
	char* _14 = res1;
	struct arr_0 _15 = a;
	uint64_t _16 = _15.size;
	char* _17 = _14 + _16;
	struct arr_0 _18 = b;
	char* _19 = _18.data;
	struct arr_0 _20 = b;
	uint64_t _21 = _20.size;
	copy_data_from(_13, _17, _19, _21);
	uint64_t _22 = res_size0;
	char* _23 = res1;
	return (struct arr_0) {_22, _23};
}
/* + nat(a nat, b nat) */
uint64_t _op_plus_1(struct ctx* ctx, uint64_t a, uint64_t b) {
	uint64_t res0;
	uint64_t _0 = a;
	uint64_t _1 = b;
	res0 = _0 + _1;
	
	struct ctx* _2 = ctx;
	uint64_t _3 = res0;
	uint64_t _4 = a;
	uint8_t _5 = _op_greater_equal(_3, _4);uint8_t _6;
	
	if (_5) {
		uint64_t _7 = res0;
		uint64_t _8 = b;
		_6 = _op_greater_equal(_7, _8);
	} else {
		_6 = 0;
	}
	assert_0(_2, _6);
	return res0;
}
/* assert void(condition bool) */
struct void_ assert_0(struct ctx* ctx, uint8_t condition) {
	struct ctx* _0 = ctx;
	uint8_t _1 = condition;
	struct arr_0 _2 = (struct arr_0) {13, constantarr_0_5};
	return assert_1(_0, _1, _2);
}
/* assert void(condition bool, message arr<char>) */
struct void_ assert_1(struct ctx* ctx, uint8_t condition, struct arr_0 message) {
	uint8_t _0 = condition;
	uint8_t _1 = !_0;
	if (_1) {
		struct ctx* _2 = ctx;
		struct arr_0 _3 = message;
		return fail(_2, _3);
	} else {
		return (struct void_) {};
	}
}
/* fail<void> void(reason arr<char>) */
struct void_ fail(struct ctx* ctx, struct arr_0 reason) {
	struct ctx* _0 = ctx;
	struct arr_0 _1 = reason;
	struct exception _2 = (struct exception) {_1};
	return throw(_0, _2);
}
/* throw<?t> void(e exception) */
struct void_ throw(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx0;
	struct ctx* _0 = ctx;
	exn_ctx0 = get_exception_ctx(_0);
	
	struct exception_ctx* _1 = exn_ctx0;
	struct jmp_buf_tag* _2 = _1->jmp_buf_ptr;
	uint8_t _3 = null__q_1(_2);
	hard_forbid(_3);
	struct exception_ctx* _4 = exn_ctx0;
	struct exception _5 = e;
	_4->thrown_exception = _5;
	struct exception_ctx* _6 = exn_ctx0;
	struct jmp_buf_tag* _7 = _6->jmp_buf_ptr;
	struct ctx* _8 = ctx;
	int32_t _9 = number_to_throw(_8);
	(longjmp(_7, _9), (struct void_) {});
	return todo_1();
}
/* get-exception-ctx exception-ctx() */
struct exception_ctx* get_exception_ctx(struct ctx* ctx) {
	struct ctx* _0 = ctx;
	uint8_t* _1 = _0->exception_ctx_ptr;
	return (struct exception_ctx*) _1;
}
/* null?<jmp-buf-tag> bool(a ptr<jmp-buf-tag>) */
uint8_t null__q_1(struct jmp_buf_tag* a) {
	struct jmp_buf_tag* _0 = a;
	uint64_t _1 = (uint64_t) _0;
	struct jmp_buf_tag* _2 = NULL;
	uint64_t _3 = (uint64_t) _2;
	return _op_equal_equal_0(_1, _3);
}
/* number-to-throw int32() */
int32_t number_to_throw(struct ctx* ctx) {
	return 7;
}
/* >=<nat> bool(a nat, b nat) */
uint8_t _op_greater_equal(uint64_t a, uint64_t b) {
	uint64_t _0 = a;
	uint64_t _1 = b;
	uint8_t _2 = _op_less(_0, _1);
	return !_2;
}
/* uninitialized-data<?t> ptr<char>(size nat) */
char* uninitialized_data_0(struct ctx* ctx, uint64_t size) {
	uint8_t* bptr0;
	struct ctx* _0 = ctx;
	uint64_t _1 = size;
	uint64_t _2 = sizeof(char);
	uint64_t _3 = _1 * _2;
	bptr0 = alloc(_0, _3);
	
	uint8_t* _4 = bptr0;
	return (char*) _4;
}
/* alloc ptr<nat8>(size nat) */
uint8_t* alloc(struct ctx* ctx, uint64_t size) {
	struct ctx* _0 = ctx;
	struct ctx* _1 = ctx;
	struct gc* _2 = get_gc(_1);
	uint64_t _3 = size;
	return gc_alloc(_0, _2, _3);
}
/* gc-alloc ptr<nat8>(gc gc, size nat) */
uint8_t* gc_alloc(struct ctx* ctx, struct gc* gc, uint64_t size) {
	struct gc* _0 = gc;
	uint64_t _1 = size;
	struct opt_3 _2 = try_gc_alloc(_0, _1);
	switch (_2.kind) {
		case 0: {
			return todo_2();
		}
		case 1: {
			struct some_3 s0 = _2.as1;
			
			struct some_3 _3 = s0;
			return _3.value;
		}
		default:
			return (assert(0),NULL);
	}
}
/* try-gc-alloc opt<ptr<nat8>>(gc gc, size-bytes nat) */
struct opt_3 try_gc_alloc(struct gc* gc, uint64_t size_bytes) {
	top:;
	struct gc* _0 = gc;
	validate_gc(_0);
	uint64_t size_words0;
	uint64_t _1 = size_bytes;
	size_words0 = words_of_bytes(_1);
	
	uint64_t* cur1;
	struct gc* _2 = gc;
	cur1 = _2->data_cur;
	
	uint64_t* next2;
	uint64_t* _3 = cur1;
	uint64_t _4 = size_words0;
	next2 = _3 + _4;
	
	uint64_t* _5 = next2;
	struct gc* _6 = gc;
	uint64_t* _7 = _6->data_end;
	uint8_t _8 = _5 < _7;
	if (_8) {
		struct gc* _9 = gc;
		uint8_t* _10 = _9->mark_cur;
		struct gc* _11 = gc;
		uint8_t* _12 = _11->mark_cur;
		uint64_t _13 = size_words0;
		uint8_t* _14 = _12 + _13;
		uint8_t _15 = range_free__q(_10, _14);
		if (_15) {
			struct gc* _16 = gc;
			struct gc* _17 = gc;
			uint8_t* _18 = _17->mark_cur;
			uint64_t _19 = size_words0;
			uint8_t* _20 = _18 + _19;
			_16->mark_cur = _20;
			struct gc* _21 = gc;
			uint64_t* _22 = next2;
			_21->data_cur = _22;
			uint64_t* _23 = cur1;
			uint8_t* _24 = (uint8_t*) _23;
			struct some_3 _25 = (struct some_3) {_24};
			return (struct opt_3) {1, .as1 = _25};
		} else {
			struct gc* _26 = gc;
			struct gc* _27 = gc;
			uint8_t* _28 = _27->mark_cur;
			uint8_t* _29 = incr_0(_28);
			_26->mark_cur = _29;
			struct gc* _30 = gc;
			struct gc* _31 = gc;
			uint64_t* _32 = _31->data_cur;
			uint64_t* _33 = incr_2(_32);
			_30->data_cur = _33;
			struct gc* _34 = gc;
			uint64_t _35 = size_bytes;
			gc = _34;
			size_bytes = _35;
			goto top;
		}
	} else {
		struct none _36 = (struct none) {};
		return (struct opt_3) {0, .as0 = _36};
	}
}
/* validate-gc void(gc gc) */
struct void_ validate_gc(struct gc* gc) {
	struct gc* _0 = gc;
	uint8_t* _1 = _0->mark_begin;
	struct gc* _2 = gc;
	uint8_t* _3 = _2->mark_cur;
	uint8_t _4 = ptr_less_eq__q_0(_1, _3);
	hard_assert(_4);
	struct gc* _5 = gc;
	uint8_t* _6 = _5->mark_cur;
	struct gc* _7 = gc;
	uint8_t* _8 = _7->mark_end;
	uint8_t _9 = ptr_less_eq__q_0(_6, _8);
	hard_assert(_9);
	struct gc* _10 = gc;
	uint64_t* _11 = _10->data_begin;
	struct gc* _12 = gc;
	uint64_t* _13 = _12->data_cur;
	uint8_t _14 = ptr_less_eq__q_1(_11, _13);
	hard_assert(_14);
	struct gc* _15 = gc;
	uint64_t* _16 = _15->data_cur;
	struct gc* _17 = gc;
	uint64_t* _18 = _17->data_end;
	uint8_t _19 = ptr_less_eq__q_1(_16, _18);
	hard_assert(_19);
	uint64_t mark_idx0;
	struct gc* _20 = gc;
	uint8_t* _21 = _20->mark_cur;
	struct gc* _22 = gc;
	uint8_t* _23 = _22->mark_begin;
	mark_idx0 = _op_minus_2(_21, _23);
	
	uint64_t data_idx1;
	struct gc* _24 = gc;
	uint64_t* _25 = _24->data_cur;
	struct gc* _26 = gc;
	uint64_t* _27 = _26->data_begin;
	data_idx1 = _op_minus_0(_25, _27);
	
	struct gc* _28 = gc;
	uint8_t* _29 = _28->mark_end;
	struct gc* _30 = gc;
	uint8_t* _31 = _30->mark_begin;
	uint64_t _32 = _op_minus_2(_29, _31);
	struct gc* _33 = gc;
	uint64_t _34 = _33->size_words;
	uint8_t _35 = _op_equal_equal_0(_32, _34);
	hard_assert(_35);
	struct gc* _36 = gc;
	uint64_t* _37 = _36->data_end;
	struct gc* _38 = gc;
	uint64_t* _39 = _38->data_begin;
	uint64_t _40 = _op_minus_0(_37, _39);
	struct gc* _41 = gc;
	uint64_t _42 = _41->size_words;
	uint8_t _43 = _op_equal_equal_0(_40, _42);
	hard_assert(_43);
	uint64_t _44 = mark_idx0;
	uint64_t _45 = data_idx1;
	uint8_t _46 = _op_equal_equal_0(_44, _45);
	return hard_assert(_46);
}
/* ptr-less-eq?<bool> bool(a ptr<bool>, b ptr<bool>) */
uint8_t ptr_less_eq__q_0(uint8_t* a, uint8_t* b) {
	uint8_t* _0 = a;
	uint8_t* _1 = b;
	uint8_t _2 = _0 < _1;
	if (_2) {
		return 1;
	} else {
		uint8_t* _3 = a;
		uint8_t* _4 = b;
		return _3 == _4;
	}
}
/* ptr-less-eq?<nat> bool(a ptr<nat>, b ptr<nat>) */
uint8_t ptr_less_eq__q_1(uint64_t* a, uint64_t* b) {
	uint64_t* _0 = a;
	uint64_t* _1 = b;
	uint8_t _2 = _0 < _1;
	if (_2) {
		return 1;
	} else {
		uint64_t* _3 = a;
		uint64_t* _4 = b;
		return _3 == _4;
	}
}
/* -<bool> nat(a ptr<bool>, b ptr<bool>) */
uint64_t _op_minus_2(uint8_t* a, uint8_t* b) {
	uint8_t* _0 = a;
	uint64_t _1 = (uint64_t) _0;
	uint8_t* _2 = b;
	uint64_t _3 = (uint64_t) _2;
	uint64_t _4 = _1 - _3;
	uint64_t _5 = sizeof(uint8_t);
	return _4 / _5;
}
/* range-free? bool(mark ptr<bool>, end ptr<bool>) */
uint8_t range_free__q(uint8_t* mark, uint8_t* end) {
	top:;
	uint8_t* _0 = mark;
	uint8_t* _1 = end;
	uint8_t _2 = _0 == _1;
	if (_2) {
		return 1;
	} else {
		uint8_t* _3 = mark;
		uint8_t _4 = *_3;
		if (_4) {
			return 0;
		} else {
			uint8_t* _5 = mark;
			uint8_t* _6 = incr_0(_5);
			uint8_t* _7 = end;
			mark = _6;
			end = _7;
			goto top;
		}
	}
}
/* incr<nat> ptr<nat>(p ptr<nat>) */
uint64_t* incr_2(uint64_t* p) {
	uint64_t* _0 = p;
	uint64_t _1 = 1u;
	return _0 + _1;
}
/* todo<ptr<nat8>> ptr<nat8>() */
uint8_t* todo_2(void) {
	return (assert(0),NULL);
}
/* get-gc gc() */
struct gc* get_gc(struct ctx* ctx) {
	struct ctx* _0 = ctx;
	struct gc_ctx* _1 = get_gc_ctx_0(_0);
	return _1->gc;
}
/* get-gc-ctx gc-ctx() */
struct gc_ctx* get_gc_ctx_0(struct ctx* ctx) {
	struct ctx* _0 = ctx;
	uint8_t* _1 = _0->gc_ctx_ptr;
	return (struct gc_ctx*) _1;
}
/* copy-data-from<?t> void(to ptr<char>, from ptr<char>, len nat) */
struct void_ copy_data_from(struct ctx* ctx, char* to, char* from, uint64_t len) {
	top:;
	uint64_t _0 = len;
	uint64_t _1 = 8u;
	uint8_t _2 = _op_less(_0, _1);
	if (_2) {
		struct ctx* _3 = ctx;
		char* _4 = to;
		char* _5 = from;
		uint64_t _6 = len;
		return copy_data_from_small(_3, _4, _5, _6);
	} else {
		uint64_t hl0;
		struct ctx* _7 = ctx;
		uint64_t _8 = len;
		uint64_t _9 = 2u;
		hl0 = _op_div(_7, _8, _9);
		
		struct ctx* _10 = ctx;
		char* _11 = to;
		char* _12 = from;
		uint64_t _13 = hl0;
		copy_data_from(_10, _11, _12, _13);
		char* _14 = to;
		uint64_t _15 = hl0;
		char* _16 = _14 + _15;
		char* _17 = from;
		uint64_t _18 = hl0;
		char* _19 = _17 + _18;
		struct ctx* _20 = ctx;
		uint64_t _21 = len;
		uint64_t _22 = hl0;
		uint64_t _23 = _op_minus_3(_20, _21, _22);
		to = _16;
		from = _19;
		len = _23;
		goto top;
	}
}
/* copy-data-from-small<?t> void(to ptr<char>, from ptr<char>, len nat) */
struct void_ copy_data_from_small(struct ctx* ctx, char* to, char* from, uint64_t len) {
	uint64_t _0 = len;
	uint64_t _1 = 0u;
	uint8_t _2 = _op_bang_equal_1(_0, _1);
	if (_2) {
		char* _3 = to;
		char* _4 = from;
		char _5 = *_4;
		*_3 = _5;
		struct ctx* _6 = ctx;
		char* _7 = to;
		char* _8 = incr_1(_7);
		char* _9 = from;
		char* _10 = incr_1(_9);
		struct ctx* _11 = ctx;
		uint64_t _12 = len;
		uint64_t _13 = decr(_11, _12);
		return copy_data_from(_6, _8, _10, _13);
	} else {
		return (struct void_) {};
	}
}
/* !=<nat> bool(a nat, b nat) */
uint8_t _op_bang_equal_1(uint64_t a, uint64_t b) {
	uint64_t _0 = a;
	uint64_t _1 = b;
	uint8_t _2 = _op_equal_equal_0(_0, _1);
	return !_2;
}
/* decr nat(a nat) */
uint64_t decr(struct ctx* ctx, uint64_t a) {
	struct ctx* _0 = ctx;
	uint64_t _1 = a;
	uint64_t _2 = 0u;
	uint8_t _3 = _op_equal_equal_0(_1, _2);
	forbid_0(_0, _3);
	uint64_t _4 = a;
	return wrap_decr(_4);
}
/* forbid void(condition bool) */
struct void_ forbid_0(struct ctx* ctx, uint8_t condition) {
	struct ctx* _0 = ctx;
	uint8_t _1 = condition;
	struct arr_0 _2 = (struct arr_0) {13, constantarr_0_6};
	return forbid_1(_0, _1, _2);
}
/* forbid void(condition bool, message arr<char>) */
struct void_ forbid_1(struct ctx* ctx, uint8_t condition, struct arr_0 message) {
	uint8_t _0 = condition;
	if (_0) {
		struct ctx* _1 = ctx;
		struct arr_0 _2 = message;
		return fail(_1, _2);
	} else {
		return (struct void_) {};
	}
}
/* wrap-decr nat(a nat) */
uint64_t wrap_decr(uint64_t a) {
	uint64_t _0 = a;
	uint64_t _1 = 1u;
	return _0 - _1;
}
/* / nat(a nat, b nat) */
uint64_t _op_div(struct ctx* ctx, uint64_t a, uint64_t b) {
	struct ctx* _0 = ctx;
	uint64_t _1 = b;
	uint64_t _2 = 0u;
	uint8_t _3 = _op_equal_equal_0(_1, _2);
	forbid_0(_0, _3);
	uint64_t _4 = a;
	uint64_t _5 = b;
	return _4 / _5;
}
/* - nat(a nat, b nat) */
uint64_t _op_minus_3(struct ctx* ctx, uint64_t a, uint64_t b) {
	struct ctx* _0 = ctx;
	uint64_t _1 = a;
	uint64_t _2 = b;
	uint8_t _3 = _op_greater_equal(_1, _2);
	assert_0(_0, _3);
	uint64_t _4 = a;
	uint64_t _5 = b;
	return _4 - _5;
}
/* to-str arr<char>(a log-level) */
struct arr_0 to_str_1(struct ctx* ctx, struct log_level a) {
	struct log_level _0 = a;
	switch (_0.kind) {
		case 0: {
			return (struct arr_0) {4, constantarr_0_7};
		}
		case 1: {
			return (struct arr_0) {4, constantarr_0_8};
		}
		default:
			return (assert(0),(struct arr_0) {0, NULL});
	}
}
/* new-island.lambda1 void(log logged) */
struct void_ new_island__lambda1(struct ctx* ctx, struct void_ _closure, struct logged* log) {
	struct ctx* _0 = ctx;
	struct logged* _1 = log;
	return default_log_handler(_0, _1);
}
/* new-gc gc() */
struct gc new_gc(void) {
	uint8_t* mark_begin0;
	uint64_t _0 = 16777216u;
	uint8_t* _1 = malloc(_0);
	mark_begin0 = (uint8_t*) _1;
	
	uint8_t* mark_end1;
	uint8_t* _2 = mark_begin0;
	uint64_t _3 = 16777216u;
	mark_end1 = _2 + _3;
	
	uint64_t* data_begin2;
	uint64_t _4 = 16777216u;
	uint64_t _5 = sizeof(uint64_t);
	uint64_t _6 = _4 * _5;
	uint8_t* _7 = malloc(_6);
	data_begin2 = (uint64_t*) _7;
	
	uint64_t* data_end3;
	uint64_t* _8 = data_begin2;
	uint64_t _9 = 16777216u;
	data_end3 = _8 + _9;
	
	uint8_t* _10 = mark_begin0;
	uint8_t* _11 = (uint8_t*) _10;
	uint8_t _12 = 0u;
	uint64_t _13 = 16777216u;
	(memset(_11, _12, _13), (struct void_) {});
	struct lock _14 = new_lock();
	uint64_t _15 = 0u;
	struct none _16 = (struct none) {};
	struct opt_1 _17 = (struct opt_1) {0, .as0 = _16};
	uint8_t _18 = 0;
	uint64_t _19 = 16777216u;
	uint8_t* _20 = mark_begin0;
	uint8_t* _21 = mark_begin0;
	uint8_t* _22 = mark_end1;
	uint64_t* _23 = data_begin2;
	uint64_t* _24 = data_begin2;
	uint64_t* _25 = data_end3;
	return (struct gc) {_14, _15, _17, _18, _19, _20, _21, _22, _23, _24, _25};
}
/* new-thread-safe-counter thread-safe-counter() */
struct thread_safe_counter new_thread_safe_counter_0(void) {
	uint64_t _0 = 0u;
	return new_thread_safe_counter_1(_0);
}
/* new-thread-safe-counter thread-safe-counter(init nat) */
struct thread_safe_counter new_thread_safe_counter_1(uint64_t init) {
	struct lock _0 = new_lock();
	uint64_t _1 = init;
	return (struct thread_safe_counter) {_0, _1};
}
/* do-main fut<int32>(gctx global-ctx, island island, argc int32, argv ptr<ptr<char>>, main-ptr fun-ptr2<fut<int32>, ctx, arr<arr<char>>>) */
struct fut_0* do_main(struct global_ctx* gctx, struct island* island, int32_t argc, char** argv, fun_ptr2 main_ptr) {
	struct exception_ctx ectx0;
	ectx0 = new_exception_ctx();
	
	struct log_ctx log_ctx1;
	log_ctx1 = new_log_ctx();
	
	struct thread_local_stuff tls2;
	struct exception_ctx* _0 = &ectx0;
	struct log_ctx* _1 = &log_ctx1;
	tls2 = (struct thread_local_stuff) {_0, _1};
	
	struct ctx ctx_by_val3;
	struct global_ctx* _2 = gctx;
	struct thread_local_stuff* _3 = &tls2;
	struct island* _4 = island;
	uint64_t _5 = 0u;
	ctx_by_val3 = new_ctx(_2, _3, _4, _5);
	
	struct ctx* ctx4;
	ctx4 = &ctx_by_val3;
	
	struct fun2 add5;
	struct void_ _6 = (struct void_) {};
	add5 = (struct fun2) {0, .as0 = _6};
	
	struct arr_3 all_args6;
	int32_t _7 = argc;
	int64_t _8 = (int64_t) _7;
	uint64_t _9 = (uint64_t) _8;
	char** _10 = argv;
	all_args6 = (struct arr_3) {_9, _10};
	
	struct fun2 _11 = add5;
	struct ctx* _12 = ctx4;
	struct arr_3 _13 = all_args6;
	fun_ptr2 _14 = main_ptr;
	return call_w_ctx_188(_11, _12, _13, _14);
}
/* new-exception-ctx exception-ctx() */
struct exception_ctx new_exception_ctx(void) {
	struct jmp_buf_tag* _0 = NULL;
	struct arr_0 _1 = (struct arr_0) {0u, NULL};
	struct exception _2 = (struct exception) {_1};
	return (struct exception_ctx) {_0, _2};
}
/* new-log-ctx log-ctx() */
struct log_ctx new_log_ctx(void) {
	struct fun1 _0 = (struct fun1) {0};
	return (struct log_ctx) {_0};
}
/* new-ctx ctx(gctx global-ctx, tls thread-local-stuff, island island, exclusion nat) */
struct ctx new_ctx(struct global_ctx* gctx, struct thread_local_stuff* tls, struct island* island, uint64_t exclusion) {
	uint8_t* gc_ctx0;
	struct gc* _0 = &island->gc;
	struct gc_ctx* _1 = get_gc_ctx_1(_0);
	gc_ctx0 = (uint8_t*) _1;
	
	struct exception_ctx* exception_ctx1;
	struct thread_local_stuff* _2 = tls;
	exception_ctx1 = _2->exception_ctx;
	
	struct log_ctx* log_ctx2;
	struct thread_local_stuff* _3 = tls;
	log_ctx2 = _3->log_ctx;
	
	struct log_ctx* _4 = log_ctx2;
	struct island_gc_root* _5 = &island->gc_root;
	struct fun1 _6 = _5->log_handler;
	_4->handler = _6;
	struct global_ctx* _7 = gctx;
	uint8_t* _8 = (uint8_t*) _7;
	struct island* _9 = island;
	uint64_t _10 = _9->id;
	uint64_t _11 = exclusion;
	uint8_t* _12 = gc_ctx0;
	struct exception_ctx* _13 = exception_ctx1;
	uint8_t* _14 = (uint8_t*) _13;
	struct log_ctx* _15 = log_ctx2;
	uint8_t* _16 = (uint8_t*) _15;
	return (struct ctx) {_8, _10, _11, _12, _14, _16};
}
/* get-gc-ctx gc-ctx(gc gc) */
struct gc_ctx* get_gc_ctx_1(struct gc* gc) {
	struct lock* _0 = &gc->lk;
	acquire_lock(_0);
	struct gc_ctx* res3;
	struct gc* _1 = gc;
	struct opt_1 _2 = _1->context_head;
	switch (_2.kind) {
		case 0: {
			struct gc_ctx* c0;
			uint64_t _3 = sizeof(struct gc_ctx);
			uint8_t* _4 = malloc(_3);
			c0 = (struct gc_ctx*) _4;
			
			struct gc_ctx* _5 = c0;
			struct gc* _6 = gc;
			_5->gc = _6;
			struct gc_ctx* _7 = c0;
			struct none _8 = (struct none) {};
			struct opt_1 _9 = (struct opt_1) {0, .as0 = _8};
			_7->next_ctx = _9;
			res3 = c0;
			break;
		}
		case 1: {
			struct some_1 s1 = _2.as1;
			
			struct gc_ctx* c2;
			struct some_1 _10 = s1;
			c2 = _10.value;
			
			struct gc* _11 = gc;
			struct gc_ctx* _12 = c2;
			struct opt_1 _13 = _12->next_ctx;
			_11->context_head = _13;
			struct gc_ctx* _14 = c2;
			struct none _15 = (struct none) {};
			struct opt_1 _16 = (struct opt_1) {0, .as0 = _15};
			_14->next_ctx = _16;
			res3 = c2;
			break;
		}
		default:
			(assert(0),NULL);
	}
	
	struct lock* _17 = &gc->lk;
	release_lock(_17);
	return res3;
}
/* acquire-lock void(a lock) */
struct void_ acquire_lock(struct lock* a) {
	struct lock* _0 = a;
	uint64_t _1 = 0u;
	return acquire_lock_recur(_0, _1);
}
/* acquire-lock-recur void(a lock, n-tries nat) */
struct void_ acquire_lock_recur(struct lock* a, uint64_t n_tries) {
	top:;
	struct lock* _0 = a;
	uint8_t _1 = try_acquire_lock(_0);
	uint8_t _2 = !_1;
	if (_2) {
		uint64_t _3 = n_tries;
		uint64_t _4 = 1000u;
		uint8_t _5 = _op_equal_equal_0(_3, _4);
		if (_5) {
			return (assert(0),(struct void_) {});
		} else {
			yield_thread();
			struct lock* _6 = a;
			uint64_t _7 = n_tries;
			uint64_t _8 = noctx_incr(_7);
			a = _6;
			n_tries = _8;
			goto top;
		}
	} else {
		return (struct void_) {};
	}
}
/* try-acquire-lock bool(a lock) */
uint8_t try_acquire_lock(struct lock* a) {
	struct _atomic_bool* _0 = &a->is_locked;
	return try_set(_0);
}
/* try-set bool(a atomic-bool) */
uint8_t try_set(struct _atomic_bool* a) {
	struct _atomic_bool* _0 = a;
	uint8_t _1 = 0;
	return try_change(_0, _1);
}
/* try-change bool(a atomic-bool, old-value bool) */
uint8_t try_change(struct _atomic_bool* a, uint8_t old_value) {
	uint8_t* _0 = &a->value;
	uint8_t* _1 = &old_value;
	uint8_t _2 = old_value;
	uint8_t _3 = !_2;
	return atomic_compare_exchange_strong(_0, _1, _3);
}
/* yield-thread void() */
struct void_ yield_thread(void) {
	int32_t err0;
	err0 = pthread_yield();
	
	int32_t _0 = err0;
	int32_t _1 = 0;
	uint8_t _2 = _op_equal_equal_3(_0, _1);
	return hard_assert(_2);
}
/* ==<int32> bool(a int32, b int32) */
uint8_t _op_equal_equal_3(int32_t a, int32_t b) {
	int32_t _0 = a;
	int32_t _1 = b;
	struct comparison _2 = compare_104(_0, _1);
	switch (_2.kind) {
		case 0: {
			return 0;
		}
		case 1: {
			return 1;
		}
		case 2: {
			return 0;
		}
		default:
			return (assert(0),0);
	}
}
/* compare<int-32> (generated) (generated) */
struct comparison compare_104(int32_t a, int32_t b) {
	int32_t _0 = a;
	int32_t _1 = b;
	uint8_t _2 = _0 < _1;
	if (_2) {
		struct less _3 = (struct less) {};
		return (struct comparison) {0, .as0 = _3};
	} else {
		int32_t _4 = b;
		int32_t _5 = a;
		uint8_t _6 = _4 < _5;
		if (_6) {
			struct greater _7 = (struct greater) {};
			return (struct comparison) {2, .as2 = _7};
		} else {
			struct equal _8 = (struct equal) {};
			return (struct comparison) {1, .as1 = _8};
		}
	}
}
/* noctx-incr nat(n nat) */
uint64_t noctx_incr(uint64_t n) {
	uint64_t _0 = n;
	uint64_t _1 = max_nat();
	uint8_t _2 = _op_less(_0, _1);
	hard_assert(_2);
	uint64_t _3 = n;
	return wrap_incr(_3);
}
/* max-nat nat() */
uint64_t max_nat(void) {
	return 18446744073709551615u;
}
/* wrap-incr nat(a nat) */
uint64_t wrap_incr(uint64_t a) {
	uint64_t _0 = a;
	uint64_t _1 = 1u;
	return _0 + _1;
}
/* release-lock void(l lock) */
struct void_ release_lock(struct lock* l) {
	struct _atomic_bool* _0 = &l->is_locked;
	return must_unset(_0);
}
/* must-unset void(a atomic-bool) */
struct void_ must_unset(struct _atomic_bool* a) {
	uint8_t did_unset0;
	struct _atomic_bool* _0 = a;
	did_unset0 = try_unset(_0);
	
	uint8_t _1 = did_unset0;
	return hard_assert(_1);
}
/* try-unset bool(a atomic-bool) */
uint8_t try_unset(struct _atomic_bool* a) {
	struct _atomic_bool* _0 = a;
	uint8_t _1 = 1;
	return try_change(_0, _1);
}
/* add-first-task fut<int32>(all-args arr<ptr<char>>, main-ptr fun-ptr2<fut<int32>, ctx, arr<arr<char>>>) */
struct fut_0* add_first_task(struct ctx* ctx, struct arr_3 all_args, fun_ptr2 main_ptr) {
	struct ctx* _0 = ctx;
	struct ctx* _1 = ctx;
	struct fut_1* _2 = delay(_1);
	struct ctx* _3 = ctx;
	struct island_and_exclusion _4 = cur_island_and_exclusion(_3);
	struct add_first_task__lambda0* temp0;
	struct ctx* _5 = ctx;
	uint64_t _6 = sizeof(struct add_first_task__lambda0);
	uint8_t* _7 = alloc(_5, _6);
	temp0 = (struct add_first_task__lambda0*) _7;
	
	struct add_first_task__lambda0* _8 = temp0;
	struct arr_3 _9 = all_args;
	fun_ptr2 _10 = main_ptr;
	struct add_first_task__lambda0 _11 = (struct add_first_task__lambda0) {_9, _10};
	*_8 = _11;
	struct add_first_task__lambda0* _12 = temp0;
	struct fun_mut0_1 _13 = (struct fun_mut0_1) {0, .as0 = _12};
	struct fun_ref0 _14 = (struct fun_ref0) {_4, _13};
	return then2(_0, _2, _14);
}
/* then2<int32> fut<int32>(f fut<void>, cb fun-ref0<int32>) */
struct fut_0* then2(struct ctx* ctx, struct fut_1* f, struct fun_ref0 cb) {
	struct ctx* _0 = ctx;
	struct fut_1* _1 = f;
	struct ctx* _2 = ctx;
	struct island_and_exclusion _3 = cur_island_and_exclusion(_2);
	struct then2__lambda0* temp0;
	struct ctx* _4 = ctx;
	uint64_t _5 = sizeof(struct then2__lambda0);
	uint8_t* _6 = alloc(_4, _5);
	temp0 = (struct then2__lambda0*) _6;
	
	struct then2__lambda0* _7 = temp0;
	struct fun_ref0 _8 = cb;
	struct then2__lambda0 _9 = (struct then2__lambda0) {_8};
	*_7 = _9;
	struct then2__lambda0* _10 = temp0;
	struct fun_mut1_3 _11 = (struct fun_mut1_3) {0, .as0 = _10};
	struct fun_ref1 _12 = (struct fun_ref1) {_3, _11};
	return then(_0, _1, _12);
}
/* then<?out, void> fut<int32>(f fut<void>, cb fun-ref1<int32, void>) */
struct fut_0* then(struct ctx* ctx, struct fut_1* f, struct fun_ref1 cb) {
	struct fut_0* res0;
	struct ctx* _0 = ctx;
	res0 = new_unresolved_fut(_0);
	
	struct ctx* _1 = ctx;
	struct fut_1* _2 = f;
	struct then__lambda0* temp0;
	struct ctx* _3 = ctx;
	uint64_t _4 = sizeof(struct then__lambda0);
	uint8_t* _5 = alloc(_3, _4);
	temp0 = (struct then__lambda0*) _5;
	
	struct then__lambda0* _6 = temp0;
	struct fun_ref1 _7 = cb;
	struct fut_0* _8 = res0;
	struct then__lambda0 _9 = (struct then__lambda0) {_7, _8};
	*_6 = _9;
	struct then__lambda0* _10 = temp0;
	struct fun_mut1_2 _11 = (struct fun_mut1_2) {0, .as0 = _10};
	then_void_0(_1, _2, _11);
	return res0;
}
/* new-unresolved-fut<?out> fut<int32>() */
struct fut_0* new_unresolved_fut(struct ctx* ctx) {
	struct fut_0* temp0;
	struct ctx* _0 = ctx;
	uint64_t _1 = sizeof(struct fut_0);
	uint8_t* _2 = alloc(_0, _1);
	temp0 = (struct fut_0*) _2;
	
	struct fut_0* _3 = temp0;
	struct lock _4 = new_lock();
	struct none _5 = (struct none) {};
	struct opt_0 _6 = (struct opt_0) {0, .as0 = _5};
	struct fut_state_callbacks_0 _7 = (struct fut_state_callbacks_0) {_6};
	struct fut_state_0 _8 = (struct fut_state_0) {0, .as0 = _7};
	struct fut_0 _9 = (struct fut_0) {_4, _8};
	*_3 = _9;
	return temp0;
}
/* then-void<?in> void(f fut<void>, cb fun-mut1<void, result<void, exception>>) */
struct void_ then_void_0(struct ctx* ctx, struct fut_1* f, struct fun_mut1_2 cb) {
	struct lock* _0 = &f->lk;
	acquire_lock(_0);
	struct fut_1* _1 = f;
	struct fut_state_1 _2 = _1->state;
	switch (_2.kind) {
		case 0: {
			struct fut_state_callbacks_1 cbs0 = _2.as0;
			
			struct fut_1* _3 = f;
			struct fut_callback_node_1* temp0;
			struct ctx* _4 = ctx;
			uint64_t _5 = sizeof(struct fut_callback_node_1);
			uint8_t* _6 = alloc(_4, _5);
			temp0 = (struct fut_callback_node_1*) _6;
			
			struct fut_callback_node_1* _7 = temp0;
			struct fun_mut1_2 _8 = cb;
			struct fut_state_callbacks_1 _9 = cbs0;
			struct opt_4 _10 = _9.head;
			struct fut_callback_node_1 _11 = (struct fut_callback_node_1) {_8, _10};
			*_7 = _11;
			struct fut_callback_node_1* _12 = temp0;
			struct some_4 _13 = (struct some_4) {_12};
			struct opt_4 _14 = (struct opt_4) {1, .as1 = _13};
			struct fut_state_callbacks_1 _15 = (struct fut_state_callbacks_1) {_14};
			struct fut_state_1 _16 = (struct fut_state_1) {0, .as0 = _15};
			_3->state = _16;
			break;
		}
		case 1: {
			struct fut_state_resolved_1 r1 = _2.as1;
			
			struct ctx* _17 = ctx;
			struct fun_mut1_2 _18 = cb;
			struct fut_state_resolved_1 _19 = r1;
			struct void_ _20 = _19.value;
			struct ok_1 _21 = (struct ok_1) {_20};
			struct result_1 _22 = (struct result_1) {0, .as0 = _21};
			call_0(_17, _18, _22);
			break;
		}
		case 2: {
			struct exception e2 = _2.as2;
			
			struct ctx* _23 = ctx;
			struct fun_mut1_2 _24 = cb;
			struct exception _25 = e2;
			struct err_0 _26 = (struct err_0) {_25};
			struct result_1 _27 = (struct result_1) {1, .as1 = _26};
			call_0(_23, _24, _27);
			break;
		}
		default:
			(assert(0),(struct void_) {});
	}
	struct lock* _28 = &f->lk;
	return release_lock(_28);
}
/* call<void, result<?t, exception>> void(a fun-mut1<void, result<void, exception>>, p0 result<void, exception>) */
struct void_ call_0(struct ctx* ctx, struct fun_mut1_2 a, struct result_1 p0) {
	struct fun_mut1_2 _0 = a;
	struct ctx* _1 = ctx;
	struct result_1 _2 = p0;
	return call_w_ctx_117(_0, _1, _2);
}
/* call-w-ctx<void, result<void, exception>> (generated) (generated) */
struct void_ call_w_ctx_117(struct fun_mut1_2 a, struct ctx* ctx, struct result_1 p0) {
	struct fun_mut1_2 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct then__lambda0* closure0 = _0.as0;
			
			struct ctx* _1 = ctx;
			struct then__lambda0* _2 = closure0;
			struct result_1 _3 = p0;
			return then__lambda0(_1, _2, _3);
		}
		default:
			return (assert(0),(struct void_) {});
	}
}
/* forward-to<?out> void(from fut<int32>, to fut<int32>) */
struct void_ forward_to(struct ctx* ctx, struct fut_0* from, struct fut_0* to) {
	struct ctx* _0 = ctx;
	struct fut_0* _1 = from;
	struct forward_to__lambda0* temp0;
	struct ctx* _2 = ctx;
	uint64_t _3 = sizeof(struct forward_to__lambda0);
	uint8_t* _4 = alloc(_2, _3);
	temp0 = (struct forward_to__lambda0*) _4;
	
	struct forward_to__lambda0* _5 = temp0;
	struct fut_0* _6 = to;
	struct forward_to__lambda0 _7 = (struct forward_to__lambda0) {_6};
	*_5 = _7;
	struct forward_to__lambda0* _8 = temp0;
	struct fun_mut1_0 _9 = (struct fun_mut1_0) {0, .as0 = _8};
	return then_void_1(_0, _1, _9);
}
/* then-void<?t> void(f fut<int32>, cb fun-mut1<void, result<int32, exception>>) */
struct void_ then_void_1(struct ctx* ctx, struct fut_0* f, struct fun_mut1_0 cb) {
	struct lock* _0 = &f->lk;
	acquire_lock(_0);
	struct fut_0* _1 = f;
	struct fut_state_0 _2 = _1->state;
	switch (_2.kind) {
		case 0: {
			struct fut_state_callbacks_0 cbs0 = _2.as0;
			
			struct fut_0* _3 = f;
			struct fut_callback_node_0* temp0;
			struct ctx* _4 = ctx;
			uint64_t _5 = sizeof(struct fut_callback_node_0);
			uint8_t* _6 = alloc(_4, _5);
			temp0 = (struct fut_callback_node_0*) _6;
			
			struct fut_callback_node_0* _7 = temp0;
			struct fun_mut1_0 _8 = cb;
			struct fut_state_callbacks_0 _9 = cbs0;
			struct opt_0 _10 = _9.head;
			struct fut_callback_node_0 _11 = (struct fut_callback_node_0) {_8, _10};
			*_7 = _11;
			struct fut_callback_node_0* _12 = temp0;
			struct some_0 _13 = (struct some_0) {_12};
			struct opt_0 _14 = (struct opt_0) {1, .as1 = _13};
			struct fut_state_callbacks_0 _15 = (struct fut_state_callbacks_0) {_14};
			struct fut_state_0 _16 = (struct fut_state_0) {0, .as0 = _15};
			_3->state = _16;
			break;
		}
		case 1: {
			struct fut_state_resolved_0 r1 = _2.as1;
			
			struct ctx* _17 = ctx;
			struct fun_mut1_0 _18 = cb;
			struct fut_state_resolved_0 _19 = r1;
			int32_t _20 = _19.value;
			struct ok_0 _21 = (struct ok_0) {_20};
			struct result_0 _22 = (struct result_0) {0, .as0 = _21};
			call_1(_17, _18, _22);
			break;
		}
		case 2: {
			struct exception e2 = _2.as2;
			
			struct ctx* _23 = ctx;
			struct fun_mut1_0 _24 = cb;
			struct exception _25 = e2;
			struct err_0 _26 = (struct err_0) {_25};
			struct result_0 _27 = (struct result_0) {1, .as1 = _26};
			call_1(_23, _24, _27);
			break;
		}
		default:
			(assert(0),(struct void_) {});
	}
	struct lock* _28 = &f->lk;
	return release_lock(_28);
}
/* call<void, result<?t, exception>> void(a fun-mut1<void, result<int32, exception>>, p0 result<int32, exception>) */
struct void_ call_1(struct ctx* ctx, struct fun_mut1_0 a, struct result_0 p0) {
	struct fun_mut1_0 _0 = a;
	struct ctx* _1 = ctx;
	struct result_0 _2 = p0;
	return call_w_ctx_121(_0, _1, _2);
}
/* call-w-ctx<void, result<int32, exception>> (generated) (generated) */
struct void_ call_w_ctx_121(struct fun_mut1_0 a, struct ctx* ctx, struct result_0 p0) {
	struct fun_mut1_0 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct forward_to__lambda0* closure0 = _0.as0;
			
			struct ctx* _1 = ctx;
			struct forward_to__lambda0* _2 = closure0;
			struct result_0 _3 = p0;
			return forward_to__lambda0(_1, _2, _3);
		}
		default:
			return (assert(0),(struct void_) {});
	}
}
/* resolve-or-reject<?t> void(f fut<int32>, result result<int32, exception>) */
struct void_ resolve_or_reject(struct ctx* ctx, struct fut_0* f, struct result_0 result) {
	struct lock* _0 = &f->lk;
	acquire_lock(_0);
	struct fut_0* _1 = f;
	struct fut_state_0 _2 = _1->state;
	switch (_2.kind) {
		case 0: {
			struct fut_state_callbacks_0 cbs0 = _2.as0;
			
			struct ctx* _3 = ctx;
			struct fut_state_callbacks_0 _4 = cbs0;
			struct opt_0 _5 = _4.head;
			struct result_0 _6 = result;
			resolve_or_reject_recur(_3, _5, _6);
			break;
		}
		case 1: {
			(assert(0),(struct void_) {});
			break;
		}
		case 2: {
			(assert(0),(struct void_) {});
			break;
		}
		default:
			(assert(0),(struct void_) {});
	}
	struct fut_0* _7 = f;
	struct result_0 _8 = result;struct fut_state_0 _9;
	
	switch (_8.kind) {
		case 0: {
			struct ok_0 o1 = _8.as0;
			
			struct ok_0 _10 = o1;
			int32_t _11 = _10.value;
			struct fut_state_resolved_0 _12 = (struct fut_state_resolved_0) {_11};
			_9 = (struct fut_state_0) {1, .as1 = _12};
			break;
		}
		case 1: {
			struct err_0 e2 = _8.as1;
			
			struct exception ex3;
			struct err_0 _13 = e2;
			ex3 = _13.value;
			
			struct exception _14 = ex3;
			_9 = (struct fut_state_0) {2, .as2 = _14};
			break;
		}
		default:
			(assert(0),(struct fut_state_0) {0});
	}
	_7->state = _9;
	struct lock* _15 = &f->lk;
	return release_lock(_15);
}
/* resolve-or-reject-recur<?t> void(node opt<fut-callback-node<int32>>, value result<int32, exception>) */
struct void_ resolve_or_reject_recur(struct ctx* ctx, struct opt_0 node, struct result_0 value) {
	top:;
	struct opt_0 _0 = node;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct some_0 s0 = _0.as1;
			
			struct ctx* _1 = ctx;
			struct some_0 _2 = s0;
			struct fut_callback_node_0* _3 = _2.value;
			struct fun_mut1_0 _4 = _3->cb;
			struct result_0 _5 = value;
			struct void_ _6 = call_1(_1, _4, _5);
			drop_1(_6);
			struct some_0 _7 = s0;
			struct fut_callback_node_0* _8 = _7.value;
			struct opt_0 _9 = _8->next_node;
			struct result_0 _10 = value;
			node = _9;
			value = _10;
			goto top;
		}
		default:
			return (assert(0),(struct void_) {});
	}
}
/* drop<void> void(t void) */
struct void_ drop_1(struct void_ t) {
	return (struct void_) {};
}
/* forward-to<?out>.lambda0 void(it result<int32, exception>) */
struct void_ forward_to__lambda0(struct ctx* ctx, struct forward_to__lambda0* _closure, struct result_0 it) {
	struct ctx* _0 = ctx;
	struct forward_to__lambda0* _1 = _closure;
	struct fut_0* _2 = _1->to;
	struct result_0 _3 = it;
	return resolve_or_reject(_0, _2, _3);
}
/* call-ref<?out, ?in> fut<int32>(f fun-ref1<int32, void>, p0 void) */
struct fut_0* call_ref_0(struct ctx* ctx, struct fun_ref1 f, struct void_ p0) {
	struct island* island0;
	struct ctx* _0 = ctx;
	struct fun_ref1 _1 = f;
	struct island_and_exclusion _2 = _1.island_and_exclusion;
	uint64_t _3 = _2.island;
	island0 = get_island(_0, _3);
	
	struct fut_0* res1;
	struct ctx* _4 = ctx;
	res1 = new_unresolved_fut(_4);
	
	struct ctx* _5 = ctx;
	struct island* _6 = island0;
	struct fun_ref1 _7 = f;
	struct island_and_exclusion _8 = _7.island_and_exclusion;
	uint64_t _9 = _8.exclusion;
	struct call_ref_0__lambda0* temp0;
	struct ctx* _10 = ctx;
	uint64_t _11 = sizeof(struct call_ref_0__lambda0);
	uint8_t* _12 = alloc(_10, _11);
	temp0 = (struct call_ref_0__lambda0*) _12;
	
	struct call_ref_0__lambda0* _13 = temp0;
	struct fun_ref1 _14 = f;
	struct void_ _15 = p0;
	struct fut_0* _16 = res1;
	struct call_ref_0__lambda0 _17 = (struct call_ref_0__lambda0) {_14, _15, _16};
	*_13 = _17;
	struct call_ref_0__lambda0* _18 = temp0;
	struct fun_mut0_0 _19 = (struct fun_mut0_0) {1, .as1 = _18};
	struct task _20 = (struct task) {_9, _19};
	add_task(_5, _6, _20);
	return res1;
}
/* get-island island(island-id nat) */
struct island* get_island(struct ctx* ctx, uint64_t island_id) {
	struct ctx* _0 = ctx;
	struct ctx* _1 = ctx;
	struct global_ctx* _2 = get_gctx(_1);
	struct arr_2 _3 = _2->islands;
	uint64_t _4 = island_id;
	return at_0(_0, _3, _4);
}
/* at<island> island(a arr<island>, index nat) */
struct island* at_0(struct ctx* ctx, struct arr_2 a, uint64_t index) {
	struct ctx* _0 = ctx;
	uint64_t _1 = index;
	struct arr_2 _2 = a;
	uint64_t _3 = _2.size;
	uint8_t _4 = _op_less(_1, _3);
	assert_0(_0, _4);
	struct arr_2 _5 = a;
	uint64_t _6 = index;
	return noctx_at_0(_5, _6);
}
/* noctx-at<?t> island(a arr<island>, index nat) */
struct island* noctx_at_0(struct arr_2 a, uint64_t index) {
	uint64_t _0 = index;
	struct arr_2 _1 = a;
	uint64_t _2 = _1.size;
	uint8_t _3 = _op_less(_0, _2);
	hard_assert(_3);
	struct arr_2 _4 = a;
	struct island** _5 = _4.data;
	uint64_t _6 = index;
	struct island** _7 = _5 + _6;
	return *_7;
}
/* add-task void(a island, t task) */
struct void_ add_task(struct ctx* ctx, struct island* a, struct task t) {
	struct mut_bag_node* node0;
	struct ctx* _0 = ctx;
	struct task _1 = t;
	node0 = new_mut_bag_node(_0, _1);
	
	struct lock* _2 = &a->tasks_lock;
	acquire_lock(_2);
	struct island* _3 = a;
	struct mut_bag* _4 = tasks(_3);
	struct mut_bag_node* _5 = node0;
	add(_4, _5);
	struct lock* _6 = &a->tasks_lock;
	release_lock(_6);
	struct condition* _7 = &a->gctx->may_be_work_to_do;
	return broadcast(_7);
}
/* new-mut-bag-node<task> mut-bag-node<task>(value task) */
struct mut_bag_node* new_mut_bag_node(struct ctx* ctx, struct task value) {
	struct mut_bag_node* temp0;
	struct ctx* _0 = ctx;
	uint64_t _1 = sizeof(struct mut_bag_node);
	uint8_t* _2 = alloc(_0, _1);
	temp0 = (struct mut_bag_node*) _2;
	
	struct mut_bag_node* _3 = temp0;
	struct task _4 = value;
	struct none _5 = (struct none) {};
	struct opt_2 _6 = (struct opt_2) {0, .as0 = _5};
	struct mut_bag_node _7 = (struct mut_bag_node) {_4, _6};
	*_3 = _7;
	return temp0;
}
/* add<task> void(bag mut-bag<task>, node mut-bag-node<task>) */
struct void_ add(struct mut_bag* bag, struct mut_bag_node* node) {
	struct mut_bag_node* _0 = node;
	struct mut_bag* _1 = bag;
	struct opt_2 _2 = _1->head;
	_0->next_node = _2;
	struct mut_bag* _3 = bag;
	struct mut_bag_node* _4 = node;
	struct some_2 _5 = (struct some_2) {_4};
	struct opt_2 _6 = (struct opt_2) {1, .as1 = _5};
	return (_3->head = _6, (struct void_) {});
}
/* tasks mut-bag<task>(a island) */
struct mut_bag* tasks(struct island* a) {
	return &(&a->gc_root)->tasks;
}
/* broadcast void(c condition) */
struct void_ broadcast(struct condition* c) {
	struct lock* _0 = &c->lk;
	acquire_lock(_0);
	struct condition* _1 = c;
	struct condition* _2 = c;
	uint64_t _3 = _2->value;
	uint64_t _4 = noctx_incr(_3);
	_1->value = _4;
	struct lock* _5 = &c->lk;
	return release_lock(_5);
}
/* catch<void> void(try fun-mut0<void>, catcher fun-mut1<void, exception>) */
struct void_ catch(struct ctx* ctx, struct fun_mut0_0 try, struct fun_mut1_1 catcher) {
	struct ctx* _0 = ctx;
	struct ctx* _1 = ctx;
	struct exception_ctx* _2 = get_exception_ctx(_1);
	struct fun_mut0_0 _3 = try;
	struct fun_mut1_1 _4 = catcher;
	return catch_with_exception_ctx(_0, _2, _3, _4);
}
/* catch-with-exception-ctx<?t> void(ec exception-ctx, try fun-mut0<void>, catcher fun-mut1<void, exception>) */
struct void_ catch_with_exception_ctx(struct ctx* ctx, struct exception_ctx* ec, struct fun_mut0_0 try, struct fun_mut1_1 catcher) {
	struct exception old_thrown_exception0;
	struct exception_ctx* _0 = ec;
	old_thrown_exception0 = _0->thrown_exception;
	
	struct jmp_buf_tag* old_jmp_buf1;
	struct exception_ctx* _1 = ec;
	old_jmp_buf1 = _1->jmp_buf_ptr;
	
	struct jmp_buf_tag store2;
	struct bytes64 _2 = zero_0();
	int32_t _3 = 0;
	struct bytes128 _4 = zero_3();
	store2 = (struct jmp_buf_tag) {_2, _3, _4};
	
	struct exception_ctx* _5 = ec;
	struct jmp_buf_tag* _6 = &store2;
	_5->jmp_buf_ptr = _6;
	int32_t setjmp_result3;
	struct exception_ctx* _7 = ec;
	struct jmp_buf_tag* _8 = _7->jmp_buf_ptr;
	setjmp_result3 = setjmp(_8);
	
	int32_t _9 = setjmp_result3;
	int32_t _10 = 0;
	uint8_t _11 = _op_equal_equal_3(_9, _10);
	if (_11) {
		struct void_ res4;
		struct ctx* _12 = ctx;
		struct fun_mut0_0 _13 = try;
		res4 = call_2(_12, _13);
		
		struct exception_ctx* _14 = ec;
		struct jmp_buf_tag* _15 = old_jmp_buf1;
		_14->jmp_buf_ptr = _15;
		struct exception_ctx* _16 = ec;
		struct exception _17 = old_thrown_exception0;
		_16->thrown_exception = _17;
		return res4;
	} else {
		struct ctx* _18 = ctx;
		int32_t _19 = setjmp_result3;
		struct ctx* _20 = ctx;
		int32_t _21 = number_to_throw(_20);
		uint8_t _22 = _op_equal_equal_3(_19, _21);
		assert_0(_18, _22);
		struct exception thrown_exception5;
		struct exception_ctx* _23 = ec;
		thrown_exception5 = _23->thrown_exception;
		
		struct exception_ctx* _24 = ec;
		struct jmp_buf_tag* _25 = old_jmp_buf1;
		_24->jmp_buf_ptr = _25;
		struct exception_ctx* _26 = ec;
		struct exception _27 = old_thrown_exception0;
		_26->thrown_exception = _27;
		struct ctx* _28 = ctx;
		struct fun_mut1_1 _29 = catcher;
		struct exception _30 = thrown_exception5;
		return call_3(_28, _29, _30);
	}
}
/* zero bytes64() */
struct bytes64 zero_0(void) {
	struct bytes32 _0 = zero_1();
	struct bytes32 _1 = zero_1();
	return (struct bytes64) {_0, _1};
}
/* zero bytes32() */
struct bytes32 zero_1(void) {
	struct bytes16 _0 = zero_2();
	struct bytes16 _1 = zero_2();
	return (struct bytes32) {_0, _1};
}
/* zero bytes16() */
struct bytes16 zero_2(void) {
	uint64_t _0 = 0u;
	uint64_t _1 = 0u;
	return (struct bytes16) {_0, _1};
}
/* zero bytes128() */
struct bytes128 zero_3(void) {
	struct bytes64 _0 = zero_0();
	struct bytes64 _1 = zero_0();
	return (struct bytes128) {_0, _1};
}
/* call<?t> void(a fun-mut0<void>) */
struct void_ call_2(struct ctx* ctx, struct fun_mut0_0 a) {
	struct fun_mut0_0 _0 = a;
	struct ctx* _1 = ctx;
	return call_w_ctx_143(_0, _1);
}
/* call-w-ctx<void> (generated) (generated) */
struct void_ call_w_ctx_143(struct fun_mut0_0 a, struct ctx* ctx) {
	struct fun_mut0_0 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct call_ref_0__lambda0__lambda0* closure0 = _0.as0;
			
			struct ctx* _1 = ctx;
			struct call_ref_0__lambda0__lambda0* _2 = closure0;
			return call_ref_0__lambda0__lambda0(_1, _2);
		}
		case 1: {
			struct call_ref_0__lambda0* closure1 = _0.as1;
			
			struct ctx* _3 = ctx;
			struct call_ref_0__lambda0* _4 = closure1;
			return call_ref_0__lambda0(_3, _4);
		}
		case 2: {
			struct call_ref_1__lambda0__lambda0* closure2 = _0.as2;
			
			struct ctx* _5 = ctx;
			struct call_ref_1__lambda0__lambda0* _6 = closure2;
			return call_ref_1__lambda0__lambda0(_5, _6);
		}
		case 3: {
			struct call_ref_1__lambda0* closure3 = _0.as3;
			
			struct ctx* _7 = ctx;
			struct call_ref_1__lambda0* _8 = closure3;
			return call_ref_1__lambda0(_7, _8);
		}
		default:
			return (assert(0),(struct void_) {});
	}
}
/* call<?t, exception> void(a fun-mut1<void, exception>, p0 exception) */
struct void_ call_3(struct ctx* ctx, struct fun_mut1_1 a, struct exception p0) {
	struct fun_mut1_1 _0 = a;
	struct ctx* _1 = ctx;
	struct exception _2 = p0;
	return call_w_ctx_145(_0, _1, _2);
}
/* call-w-ctx<void, exception> (generated) (generated) */
struct void_ call_w_ctx_145(struct fun_mut1_1 a, struct ctx* ctx, struct exception p0) {
	struct fun_mut1_1 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			struct ctx* _1 = ctx;
			struct void_ _2 = closure0;
			struct exception _3 = p0;
			return new_island__lambda0(_1, _2, _3);
		}
		case 1: {
			struct call_ref_0__lambda0__lambda1* closure1 = _0.as1;
			
			struct ctx* _4 = ctx;
			struct call_ref_0__lambda0__lambda1* _5 = closure1;
			struct exception _6 = p0;
			return call_ref_0__lambda0__lambda1(_4, _5, _6);
		}
		case 2: {
			struct call_ref_1__lambda0__lambda1* closure2 = _0.as2;
			
			struct ctx* _7 = ctx;
			struct call_ref_1__lambda0__lambda1* _8 = closure2;
			struct exception _9 = p0;
			return call_ref_1__lambda0__lambda1(_7, _8, _9);
		}
		default:
			return (assert(0),(struct void_) {});
	}
}
/* call<fut<?r>, ?p0> fut<int32>(a fun-mut1<fut<int32>, void>, p0 void) */
struct fut_0* call_4(struct ctx* ctx, struct fun_mut1_3 a, struct void_ p0) {
	struct fun_mut1_3 _0 = a;
	struct ctx* _1 = ctx;
	struct void_ _2 = p0;
	return call_w_ctx_147(_0, _1, _2);
}
/* call-w-ctx<gc-ptr(fut<int32>), void> (generated) (generated) */
struct fut_0* call_w_ctx_147(struct fun_mut1_3 a, struct ctx* ctx, struct void_ p0) {
	struct fun_mut1_3 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct then2__lambda0* closure0 = _0.as0;
			
			struct ctx* _1 = ctx;
			struct then2__lambda0* _2 = closure0;
			struct void_ _3 = p0;
			return then2__lambda0(_1, _2, _3);
		}
		default:
			return (assert(0),NULL);
	}
}
/* call-ref<?out, ?in>.lambda0.lambda0 void() */
struct void_ call_ref_0__lambda0__lambda0(struct ctx* ctx, struct call_ref_0__lambda0__lambda0* _closure) {
	struct ctx* _0 = ctx;
	struct ctx* _1 = ctx;
	struct call_ref_0__lambda0__lambda0* _2 = _closure;
	struct fun_ref1 _3 = _2->f;
	struct fun_mut1_3 _4 = _3.fun;
	struct call_ref_0__lambda0__lambda0* _5 = _closure;
	struct void_ _6 = _5->p0;
	struct fut_0* _7 = call_4(_1, _4, _6);
	struct call_ref_0__lambda0__lambda0* _8 = _closure;
	struct fut_0* _9 = _8->res;
	return forward_to(_0, _7, _9);
}
/* reject<?r> void(f fut<int32>, e exception) */
struct void_ reject(struct ctx* ctx, struct fut_0* f, struct exception e) {
	struct ctx* _0 = ctx;
	struct fut_0* _1 = f;
	struct exception _2 = e;
	struct err_0 _3 = (struct err_0) {_2};
	struct result_0 _4 = (struct result_0) {1, .as1 = _3};
	return resolve_or_reject(_0, _1, _4);
}
/* call-ref<?out, ?in>.lambda0.lambda1 void(it exception) */
struct void_ call_ref_0__lambda0__lambda1(struct ctx* ctx, struct call_ref_0__lambda0__lambda1* _closure, struct exception it) {
	struct ctx* _0 = ctx;
	struct call_ref_0__lambda0__lambda1* _1 = _closure;
	struct fut_0* _2 = _1->res;
	struct exception _3 = it;
	return reject(_0, _2, _3);
}
/* call-ref<?out, ?in>.lambda0 void() */
struct void_ call_ref_0__lambda0(struct ctx* ctx, struct call_ref_0__lambda0* _closure) {
	struct ctx* _0 = ctx;
	struct call_ref_0__lambda0__lambda0* temp0;
	struct ctx* _1 = ctx;
	uint64_t _2 = sizeof(struct call_ref_0__lambda0__lambda0);
	uint8_t* _3 = alloc(_1, _2);
	temp0 = (struct call_ref_0__lambda0__lambda0*) _3;
	
	struct call_ref_0__lambda0__lambda0* _4 = temp0;
	struct call_ref_0__lambda0* _5 = _closure;
	struct fun_ref1 _6 = _5->f;
	struct call_ref_0__lambda0* _7 = _closure;
	struct void_ _8 = _7->p0;
	struct call_ref_0__lambda0* _9 = _closure;
	struct fut_0* _10 = _9->res;
	struct call_ref_0__lambda0__lambda0 _11 = (struct call_ref_0__lambda0__lambda0) {_6, _8, _10};
	*_4 = _11;
	struct call_ref_0__lambda0__lambda0* _12 = temp0;
	struct fun_mut0_0 _13 = (struct fun_mut0_0) {0, .as0 = _12};
	struct call_ref_0__lambda0__lambda1* temp1;
	struct ctx* _14 = ctx;
	uint64_t _15 = sizeof(struct call_ref_0__lambda0__lambda1);
	uint8_t* _16 = alloc(_14, _15);
	temp1 = (struct call_ref_0__lambda0__lambda1*) _16;
	
	struct call_ref_0__lambda0__lambda1* _17 = temp1;
	struct call_ref_0__lambda0* _18 = _closure;
	struct fut_0* _19 = _18->res;
	struct call_ref_0__lambda0__lambda1 _20 = (struct call_ref_0__lambda0__lambda1) {_19};
	*_17 = _20;
	struct call_ref_0__lambda0__lambda1* _21 = temp1;
	struct fun_mut1_1 _22 = (struct fun_mut1_1) {1, .as1 = _21};
	return catch(_0, _13, _22);
}
/* then<?out, void>.lambda0 void(result result<void, exception>) */
struct void_ then__lambda0(struct ctx* ctx, struct then__lambda0* _closure, struct result_1 result) {
	struct result_1 _0 = result;
	switch (_0.kind) {
		case 0: {
			struct ok_1 o0 = _0.as0;
			
			struct ctx* _1 = ctx;
			struct ctx* _2 = ctx;
			struct then__lambda0* _3 = _closure;
			struct fun_ref1 _4 = _3->cb;
			struct ok_1 _5 = o0;
			struct void_ _6 = _5.value;
			struct fut_0* _7 = call_ref_0(_2, _4, _6);
			struct then__lambda0* _8 = _closure;
			struct fut_0* _9 = _8->res;
			return forward_to(_1, _7, _9);
		}
		case 1: {
			struct err_0 e1 = _0.as1;
			
			struct ctx* _10 = ctx;
			struct then__lambda0* _11 = _closure;
			struct fut_0* _12 = _11->res;
			struct err_0 _13 = e1;
			struct exception _14 = _13.value;
			return reject(_10, _12, _14);
		}
		default:
			return (assert(0),(struct void_) {});
	}
}
/* call-ref<?out> fut<int32>(f fun-ref0<int32>) */
struct fut_0* call_ref_1(struct ctx* ctx, struct fun_ref0 f) {
	struct island* island0;
	struct ctx* _0 = ctx;
	struct fun_ref0 _1 = f;
	struct island_and_exclusion _2 = _1.island_and_exclusion;
	uint64_t _3 = _2.island;
	island0 = get_island(_0, _3);
	
	struct fut_0* res1;
	struct ctx* _4 = ctx;
	res1 = new_unresolved_fut(_4);
	
	struct ctx* _5 = ctx;
	struct island* _6 = island0;
	struct fun_ref0 _7 = f;
	struct island_and_exclusion _8 = _7.island_and_exclusion;
	uint64_t _9 = _8.exclusion;
	struct call_ref_1__lambda0* temp0;
	struct ctx* _10 = ctx;
	uint64_t _11 = sizeof(struct call_ref_1__lambda0);
	uint8_t* _12 = alloc(_10, _11);
	temp0 = (struct call_ref_1__lambda0*) _12;
	
	struct call_ref_1__lambda0* _13 = temp0;
	struct fun_ref0 _14 = f;
	struct fut_0* _15 = res1;
	struct call_ref_1__lambda0 _16 = (struct call_ref_1__lambda0) {_14, _15};
	*_13 = _16;
	struct call_ref_1__lambda0* _17 = temp0;
	struct fun_mut0_0 _18 = (struct fun_mut0_0) {3, .as3 = _17};
	struct task _19 = (struct task) {_9, _18};
	add_task(_5, _6, _19);
	return res1;
}
/* call<fut<?r>> fut<int32>(a fun-mut0<fut<int32>>) */
struct fut_0* call_5(struct ctx* ctx, struct fun_mut0_1 a) {
	struct fun_mut0_1 _0 = a;
	struct ctx* _1 = ctx;
	return call_w_ctx_155(_0, _1);
}
/* call-w-ctx<gc-ptr(fut<int32>)> (generated) (generated) */
struct fut_0* call_w_ctx_155(struct fun_mut0_1 a, struct ctx* ctx) {
	struct fun_mut0_1 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct add_first_task__lambda0* closure0 = _0.as0;
			
			struct ctx* _1 = ctx;
			struct add_first_task__lambda0* _2 = closure0;
			return add_first_task__lambda0(_1, _2);
		}
		default:
			return (assert(0),NULL);
	}
}
/* call-ref<?out>.lambda0.lambda0 void() */
struct void_ call_ref_1__lambda0__lambda0(struct ctx* ctx, struct call_ref_1__lambda0__lambda0* _closure) {
	struct ctx* _0 = ctx;
	struct ctx* _1 = ctx;
	struct call_ref_1__lambda0__lambda0* _2 = _closure;
	struct fun_ref0 _3 = _2->f;
	struct fun_mut0_1 _4 = _3.fun;
	struct fut_0* _5 = call_5(_1, _4);
	struct call_ref_1__lambda0__lambda0* _6 = _closure;
	struct fut_0* _7 = _6->res;
	return forward_to(_0, _5, _7);
}
/* call-ref<?out>.lambda0.lambda1 void(it exception) */
struct void_ call_ref_1__lambda0__lambda1(struct ctx* ctx, struct call_ref_1__lambda0__lambda1* _closure, struct exception it) {
	struct ctx* _0 = ctx;
	struct call_ref_1__lambda0__lambda1* _1 = _closure;
	struct fut_0* _2 = _1->res;
	struct exception _3 = it;
	return reject(_0, _2, _3);
}
/* call-ref<?out>.lambda0 void() */
struct void_ call_ref_1__lambda0(struct ctx* ctx, struct call_ref_1__lambda0* _closure) {
	struct ctx* _0 = ctx;
	struct call_ref_1__lambda0__lambda0* temp0;
	struct ctx* _1 = ctx;
	uint64_t _2 = sizeof(struct call_ref_1__lambda0__lambda0);
	uint8_t* _3 = alloc(_1, _2);
	temp0 = (struct call_ref_1__lambda0__lambda0*) _3;
	
	struct call_ref_1__lambda0__lambda0* _4 = temp0;
	struct call_ref_1__lambda0* _5 = _closure;
	struct fun_ref0 _6 = _5->f;
	struct call_ref_1__lambda0* _7 = _closure;
	struct fut_0* _8 = _7->res;
	struct call_ref_1__lambda0__lambda0 _9 = (struct call_ref_1__lambda0__lambda0) {_6, _8};
	*_4 = _9;
	struct call_ref_1__lambda0__lambda0* _10 = temp0;
	struct fun_mut0_0 _11 = (struct fun_mut0_0) {2, .as2 = _10};
	struct call_ref_1__lambda0__lambda1* temp1;
	struct ctx* _12 = ctx;
	uint64_t _13 = sizeof(struct call_ref_1__lambda0__lambda1);
	uint8_t* _14 = alloc(_12, _13);
	temp1 = (struct call_ref_1__lambda0__lambda1*) _14;
	
	struct call_ref_1__lambda0__lambda1* _15 = temp1;
	struct call_ref_1__lambda0* _16 = _closure;
	struct fut_0* _17 = _16->res;
	struct call_ref_1__lambda0__lambda1 _18 = (struct call_ref_1__lambda0__lambda1) {_17};
	*_15 = _18;
	struct call_ref_1__lambda0__lambda1* _19 = temp1;
	struct fun_mut1_1 _20 = (struct fun_mut1_1) {2, .as2 = _19};
	return catch(_0, _11, _20);
}
/* then2<int32>.lambda0 fut<int32>(ignore void) */
struct fut_0* then2__lambda0(struct ctx* ctx, struct then2__lambda0* _closure, struct void_ ignore) {
	struct ctx* _0 = ctx;
	struct then2__lambda0* _1 = _closure;
	struct fun_ref0 _2 = _1->cb;
	return call_ref_1(_0, _2);
}
/* cur-island-and-exclusion island-and-exclusion() */
struct island_and_exclusion cur_island_and_exclusion(struct ctx* ctx) {
	struct ctx* c0;
	c0 = ctx;
	
	struct ctx* _0 = c0;
	uint64_t _1 = _0->island_id;
	struct ctx* _2 = c0;
	uint64_t _3 = _2->exclusion;
	return (struct island_and_exclusion) {_1, _3};
}
/* delay fut<void>() */
struct fut_1* delay(struct ctx* ctx) {
	struct ctx* _0 = ctx;
	struct void_ _1 = (struct void_) {};
	return resolved_0(_0, _1);
}
/* resolved<void> fut<void>(value void) */
struct fut_1* resolved_0(struct ctx* ctx, struct void_ value) {
	struct fut_1* temp0;
	struct ctx* _0 = ctx;
	uint64_t _1 = sizeof(struct fut_1);
	uint8_t* _2 = alloc(_0, _1);
	temp0 = (struct fut_1*) _2;
	
	struct fut_1* _3 = temp0;
	struct lock _4 = new_lock();
	struct void_ _5 = value;
	struct fut_state_resolved_1 _6 = (struct fut_state_resolved_1) {_5};
	struct fut_state_1 _7 = (struct fut_state_1) {1, .as1 = _6};
	struct fut_1 _8 = (struct fut_1) {_4, _7};
	*_3 = _8;
	return temp0;
}
/* tail<ptr<char>> arr<ptr<char>>(a arr<ptr<char>>) */
struct arr_3 tail(struct ctx* ctx, struct arr_3 a) {
	struct ctx* _0 = ctx;
	struct arr_3 _1 = a;
	uint8_t _2 = empty__q_1(_1);
	forbid_0(_0, _2);
	struct ctx* _3 = ctx;
	struct arr_3 _4 = a;
	uint64_t _5 = 1u;
	return slice_starting_at(_3, _4, _5);
}
/* empty?<?t> bool(a arr<ptr<char>>) */
uint8_t empty__q_1(struct arr_3 a) {
	struct arr_3 _0 = a;
	uint64_t _1 = _0.size;
	uint64_t _2 = 0u;
	return _op_equal_equal_0(_1, _2);
}
/* slice-starting-at<?t> arr<ptr<char>>(a arr<ptr<char>>, begin nat) */
struct arr_3 slice_starting_at(struct ctx* ctx, struct arr_3 a, uint64_t begin) {
	struct ctx* _0 = ctx;
	uint64_t _1 = begin;
	struct arr_3 _2 = a;
	uint64_t _3 = _2.size;
	uint8_t _4 = _op_less_equal(_1, _3);
	assert_0(_0, _4);
	struct ctx* _5 = ctx;
	struct arr_3 _6 = a;
	uint64_t _7 = begin;
	struct ctx* _8 = ctx;
	struct arr_3 _9 = a;
	uint64_t _10 = _9.size;
	uint64_t _11 = begin;
	uint64_t _12 = _op_minus_3(_8, _10, _11);
	return slice(_5, _6, _7, _12);
}
/* slice<?t> arr<ptr<char>>(a arr<ptr<char>>, begin nat, size nat) */
struct arr_3 slice(struct ctx* ctx, struct arr_3 a, uint64_t begin, uint64_t size) {
	struct ctx* _0 = ctx;
	struct ctx* _1 = ctx;
	uint64_t _2 = begin;
	uint64_t _3 = size;
	uint64_t _4 = _op_plus_1(_1, _2, _3);
	struct arr_3 _5 = a;
	uint64_t _6 = _5.size;
	uint8_t _7 = _op_less_equal(_4, _6);
	assert_0(_0, _7);
	uint64_t _8 = size;
	struct arr_3 _9 = a;
	char** _10 = _9.data;
	uint64_t _11 = begin;
	char** _12 = _10 + _11;
	return (struct arr_3) {_8, _12};
}
/* map<arr<char>, ptr<char>> arr<arr<char>>(a arr<ptr<char>>, mapper fun-mut1<arr<char>, ptr<char>>) */
struct arr_1 map(struct ctx* ctx, struct arr_3 a, struct fun_mut1_4 mapper) {
	struct ctx* _0 = ctx;
	struct arr_3 _1 = a;
	uint64_t _2 = _1.size;
	struct map__lambda0* temp0;
	struct ctx* _3 = ctx;
	uint64_t _4 = sizeof(struct map__lambda0);
	uint8_t* _5 = alloc(_3, _4);
	temp0 = (struct map__lambda0*) _5;
	
	struct map__lambda0* _6 = temp0;
	struct fun_mut1_4 _7 = mapper;
	struct arr_3 _8 = a;
	struct map__lambda0 _9 = (struct map__lambda0) {_7, _8};
	*_6 = _9;
	struct map__lambda0* _10 = temp0;
	struct fun_mut1_5 _11 = (struct fun_mut1_5) {0, .as0 = _10};
	return make_arr(_0, _2, _11);
}
/* make-arr<?out> arr<arr<char>>(size nat, f fun-mut1<arr<char>, nat>) */
struct arr_1 make_arr(struct ctx* ctx, uint64_t size, struct fun_mut1_5 f) {
	struct ctx* _0 = ctx;
	uint64_t _1 = size;
	struct fun_mut1_5 _2 = f;
	struct mut_arr_1* _3 = make_mut_arr(_0, _1, _2);
	return freeze(_3);
}
/* freeze<?t> arr<arr<char>>(a mut-arr<arr<char>>) */
struct arr_1 freeze(struct mut_arr_1* a) {
	struct mut_arr_1* _0 = a;
	uint8_t _1 = 1;
	_0->frozen__q = _1;
	struct mut_arr_1* _2 = a;
	return unsafe_as_arr(_2);
}
/* unsafe-as-arr<?t> arr<arr<char>>(a mut-arr<arr<char>>) */
struct arr_1 unsafe_as_arr(struct mut_arr_1* a) {
	struct mut_arr_1* _0 = a;
	uint64_t _1 = _0->size;
	struct mut_arr_1* _2 = a;
	struct arr_0* _3 = _2->data;
	return (struct arr_1) {_1, _3};
}
/* make-mut-arr<?t> mut-arr<arr<char>>(size nat, f fun-mut1<arr<char>, nat>) */
struct mut_arr_1* make_mut_arr(struct ctx* ctx, uint64_t size, struct fun_mut1_5 f) {
	struct mut_arr_1* res0;
	struct ctx* _0 = ctx;
	uint64_t _1 = size;
	res0 = new_uninitialized_mut_arr(_0, _1);
	
	struct ctx* _2 = ctx;
	struct mut_arr_1* _3 = res0;
	uint64_t _4 = 0u;
	struct fun_mut1_5 _5 = f;
	make_mut_arr_worker(_2, _3, _4, _5);
	return res0;
}
/* new-uninitialized-mut-arr<?t> mut-arr<arr<char>>(size nat) */
struct mut_arr_1* new_uninitialized_mut_arr(struct ctx* ctx, uint64_t size) {
	struct mut_arr_1* temp0;
	struct ctx* _0 = ctx;
	uint64_t _1 = sizeof(struct mut_arr_1);
	uint8_t* _2 = alloc(_0, _1);
	temp0 = (struct mut_arr_1*) _2;
	
	struct mut_arr_1* _3 = temp0;
	uint8_t _4 = 0;
	uint64_t _5 = size;
	uint64_t _6 = size;
	struct ctx* _7 = ctx;
	uint64_t _8 = size;
	struct arr_0* _9 = uninitialized_data_1(_7, _8);
	struct mut_arr_1 _10 = (struct mut_arr_1) {_4, _5, _6, _9};
	*_3 = _10;
	return temp0;
}
/* uninitialized-data<?t> ptr<arr<char>>(size nat) */
struct arr_0* uninitialized_data_1(struct ctx* ctx, uint64_t size) {
	uint8_t* bptr0;
	struct ctx* _0 = ctx;
	uint64_t _1 = size;
	uint64_t _2 = sizeof(struct arr_0);
	uint64_t _3 = _1 * _2;
	bptr0 = alloc(_0, _3);
	
	uint8_t* _4 = bptr0;
	return (struct arr_0*) _4;
}
/* make-mut-arr-worker<?t> void(m mut-arr<arr<char>>, i nat, f fun-mut1<arr<char>, nat>) */
struct void_ make_mut_arr_worker(struct ctx* ctx, struct mut_arr_1* m, uint64_t i, struct fun_mut1_5 f) {
	top:;
	uint64_t _0 = i;
	struct mut_arr_1* _1 = m;
	uint64_t _2 = _1->size;
	uint8_t _3 = _op_bang_equal_1(_0, _2);
	if (_3) {
		struct ctx* _4 = ctx;
		struct mut_arr_1* _5 = m;
		uint64_t _6 = i;
		struct ctx* _7 = ctx;
		struct fun_mut1_5 _8 = f;
		uint64_t _9 = i;
		struct arr_0 _10 = call_6(_7, _8, _9);
		set_at(_4, _5, _6, _10);
		struct mut_arr_1* _11 = m;
		struct ctx* _12 = ctx;
		uint64_t _13 = i;
		uint64_t _14 = incr_3(_12, _13);
		struct fun_mut1_5 _15 = f;
		m = _11;
		i = _14;
		f = _15;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* set-at<?t> void(a mut-arr<arr<char>>, index nat, value arr<char>) */
struct void_ set_at(struct ctx* ctx, struct mut_arr_1* a, uint64_t index, struct arr_0 value) {
	struct ctx* _0 = ctx;
	uint64_t _1 = index;
	struct mut_arr_1* _2 = a;
	uint64_t _3 = _2->size;
	uint8_t _4 = _op_less(_1, _3);
	assert_0(_0, _4);
	struct mut_arr_1* _5 = a;
	uint64_t _6 = index;
	struct arr_0 _7 = value;
	return noctx_set_at_0(_5, _6, _7);
}
/* noctx-set-at<?t> void(a mut-arr<arr<char>>, index nat, value arr<char>) */
struct void_ noctx_set_at_0(struct mut_arr_1* a, uint64_t index, struct arr_0 value) {
	uint64_t _0 = index;
	struct mut_arr_1* _1 = a;
	uint64_t _2 = _1->size;
	uint8_t _3 = _op_less(_0, _2);
	hard_assert(_3);
	struct mut_arr_1* _4 = a;
	struct arr_0* _5 = _4->data;
	uint64_t _6 = index;
	struct arr_0* _7 = _5 + _6;
	struct arr_0 _8 = value;
	return (*_7 = _8, (struct void_) {});
}
/* call<?t, nat> arr<char>(a fun-mut1<arr<char>, nat>, p0 nat) */
struct arr_0 call_6(struct ctx* ctx, struct fun_mut1_5 a, uint64_t p0) {
	struct fun_mut1_5 _0 = a;
	struct ctx* _1 = ctx;
	uint64_t _2 = p0;
	return call_w_ctx_178(_0, _1, _2);
}
/* call-w-ctx<arr<char>, nat-64> (generated) (generated) */
struct arr_0 call_w_ctx_178(struct fun_mut1_5 a, struct ctx* ctx, uint64_t p0) {
	struct fun_mut1_5 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct map__lambda0* closure0 = _0.as0;
			
			struct ctx* _1 = ctx;
			struct map__lambda0* _2 = closure0;
			uint64_t _3 = p0;
			return map__lambda0(_1, _2, _3);
		}
		default:
			return (assert(0),(struct arr_0) {0, NULL});
	}
}
/* incr nat(n nat) */
uint64_t incr_3(struct ctx* ctx, uint64_t n) {
	struct ctx* _0 = ctx;
	uint64_t _1 = n;
	uint64_t _2 = max_nat();
	uint8_t _3 = _op_equal_equal_0(_1, _2);
	forbid_0(_0, _3);
	uint64_t _4 = n;
	uint64_t _5 = 1u;
	return _4 + _5;
}
/* call<?out, ?in> arr<char>(a fun-mut1<arr<char>, ptr<char>>, p0 ptr<char>) */
struct arr_0 call_7(struct ctx* ctx, struct fun_mut1_4 a, char* p0) {
	struct fun_mut1_4 _0 = a;
	struct ctx* _1 = ctx;
	char* _2 = p0;
	return call_w_ctx_181(_0, _1, _2);
}
/* call-w-ctx<arr<char>, raw-ptr(char)> (generated) (generated) */
struct arr_0 call_w_ctx_181(struct fun_mut1_4 a, struct ctx* ctx, char* p0) {
	struct fun_mut1_4 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			struct ctx* _1 = ctx;
			struct void_ _2 = closure0;
			char* _3 = p0;
			return add_first_task__lambda0__lambda0(_1, _2, _3);
		}
		default:
			return (assert(0),(struct arr_0) {0, NULL});
	}
}
/* at<?in> ptr<char>(a arr<ptr<char>>, index nat) */
char* at_1(struct ctx* ctx, struct arr_3 a, uint64_t index) {
	struct ctx* _0 = ctx;
	uint64_t _1 = index;
	struct arr_3 _2 = a;
	uint64_t _3 = _2.size;
	uint8_t _4 = _op_less(_1, _3);
	assert_0(_0, _4);
	struct arr_3 _5 = a;
	uint64_t _6 = index;
	return noctx_at_1(_5, _6);
}
/* noctx-at<?t> ptr<char>(a arr<ptr<char>>, index nat) */
char* noctx_at_1(struct arr_3 a, uint64_t index) {
	uint64_t _0 = index;
	struct arr_3 _1 = a;
	uint64_t _2 = _1.size;
	uint8_t _3 = _op_less(_0, _2);
	hard_assert(_3);
	struct arr_3 _4 = a;
	char** _5 = _4.data;
	uint64_t _6 = index;
	char** _7 = _5 + _6;
	return *_7;
}
/* map<arr<char>, ptr<char>>.lambda0 arr<char>(i nat) */
struct arr_0 map__lambda0(struct ctx* ctx, struct map__lambda0* _closure, uint64_t i) {
	struct ctx* _0 = ctx;
	struct map__lambda0* _1 = _closure;
	struct fun_mut1_4 _2 = _1->mapper;
	struct ctx* _3 = ctx;
	struct map__lambda0* _4 = _closure;
	struct arr_3 _5 = _4->a;
	uint64_t _6 = i;
	char* _7 = at_1(_3, _5, _6);
	return call_7(_0, _2, _7);
}
/* add-first-task.lambda0.lambda0 arr<char>(it ptr<char>) */
struct arr_0 add_first_task__lambda0__lambda0(struct ctx* ctx, struct void_ _closure, char* it) {
	char* _0 = it;
	return to_str_0(_0);
}
/* add-first-task.lambda0 fut<int32>() */
struct fut_0* add_first_task__lambda0(struct ctx* ctx, struct add_first_task__lambda0* _closure) {
	struct arr_3 args0;
	struct ctx* _0 = ctx;
	struct add_first_task__lambda0* _1 = _closure;
	struct arr_3 _2 = _1->all_args;
	args0 = tail(_0, _2);
	
	struct add_first_task__lambda0* _3 = _closure;
	fun_ptr2 _4 = _3->main_ptr;
	struct ctx* _5 = ctx;
	struct ctx* _6 = ctx;
	struct arr_3 _7 = args0;
	struct void_ _8 = (struct void_) {};
	struct fun_mut1_4 _9 = (struct fun_mut1_4) {0, .as0 = _8};
	struct arr_1 _10 = map(_6, _7, _9);
	return _4(_5, _10);
}
/* do-main.lambda0 fut<int32>(all-args arr<ptr<char>>, main-ptr fun-ptr2<fut<int32>, ctx, arr<arr<char>>>) */
struct fut_0* do_main__lambda0(struct ctx* ctx, struct void_ _closure, struct arr_3 all_args, fun_ptr2 main_ptr) {
	struct ctx* _0 = ctx;
	struct arr_3 _1 = all_args;
	fun_ptr2 _2 = main_ptr;
	return add_first_task(_0, _1, _2);
}
/* call-w-ctx<gc-ptr(fut<int32>), arr<ptr<char>>, some fun ptr type> (generated) (generated) */
struct fut_0* call_w_ctx_188(struct fun2 a, struct ctx* ctx, struct arr_3 p0, fun_ptr2 p1) {
	struct fun2 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			struct ctx* _1 = ctx;
			struct void_ _2 = closure0;
			struct arr_3 _3 = p0;
			fun_ptr2 _4 = p1;
			return do_main__lambda0(_1, _2, _3, _4);
		}
		default:
			return (assert(0),NULL);
	}
}
/* run-threads void(n-threads nat, gctx global-ctx) */
struct void_ run_threads(uint64_t n_threads, struct global_ctx* gctx) {
	uint64_t* threads0;
	uint64_t _0 = n_threads;
	threads0 = unmanaged_alloc_elements_0(_0);
	
	struct thread_args* thread_args1;
	uint64_t _1 = n_threads;
	thread_args1 = unmanaged_alloc_elements_1(_1);
	
	uint64_t actual_n_threads2;
	uint64_t _2 = n_threads;
	actual_n_threads2 = noctx_decr(_2);
	
	uint64_t _3 = 0u;
	uint64_t _4 = actual_n_threads2;
	uint64_t* _5 = threads0;
	struct thread_args* _6 = thread_args1;
	struct global_ctx* _7 = gctx;
	start_threads_recur(_3, _4, _5, _6, _7);
	uint64_t _8 = actual_n_threads2;
	struct global_ctx* _9 = gctx;
	thread_function(_8, _9);
	uint64_t _10 = 0u;
	uint64_t _11 = actual_n_threads2;
	uint64_t* _12 = threads0;
	join_threads_recur(_10, _11, _12);
	uint64_t* _13 = threads0;
	unmanaged_free_0(_13);
	struct thread_args* _14 = thread_args1;
	return unmanaged_free_1(_14);
}
/* unmanaged-alloc-elements<by-val<thread-args>> ptr<thread-args>(size-elements nat) */
struct thread_args* unmanaged_alloc_elements_1(uint64_t size_elements) {
	uint8_t* bytes0;
	uint64_t _0 = size_elements;
	uint64_t _1 = sizeof(struct thread_args);
	uint64_t _2 = _0 * _1;
	bytes0 = unmanaged_alloc_bytes(_2);
	
	uint8_t* _3 = bytes0;
	return (struct thread_args*) _3;
}
/* noctx-decr nat(n nat) */
uint64_t noctx_decr(uint64_t n) {
	uint64_t _0 = n;
	uint64_t _1 = 0u;
	uint8_t _2 = _op_equal_equal_0(_0, _1);
	hard_forbid(_2);
	uint64_t _3 = n;
	uint64_t _4 = 1u;
	return _3 - _4;
}
/* start-threads-recur void(i nat, n-threads nat, threads ptr<nat>, thread-args-begin ptr<thread-args>, gctx global-ctx) */
struct void_ start_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads, struct thread_args* thread_args_begin, struct global_ctx* gctx) {
	top:;
	uint64_t _0 = i;
	uint64_t _1 = n_threads;
	uint8_t _2 = _op_bang_equal_1(_0, _1);
	if (_2) {
		struct thread_args* thread_arg_ptr0;
		struct thread_args* _3 = thread_args_begin;
		uint64_t _4 = i;
		thread_arg_ptr0 = _3 + _4;
		
		struct thread_args* _5 = thread_arg_ptr0;
		uint64_t _6 = i;
		struct global_ctx* _7 = gctx;
		struct thread_args _8 = (struct thread_args) {_6, _7};
		*_5 = _8;
		uint64_t* thread_ptr1;
		uint64_t* _9 = threads;
		uint64_t _10 = i;
		thread_ptr1 = _9 + _10;
		
		int32_t err2;
		uint64_t* _11 = thread_ptr1;
		struct cell_0* _12 = as_cell(_11);
		uint8_t* _13 = NULL;
		fun_ptr1 _14 = thread_fun;
		struct thread_args* _15 = thread_arg_ptr0;
		uint8_t* _16 = (uint8_t*) _15;
		err2 = pthread_create(_12, _13, _14, _16);
		
		int32_t _17 = err2;
		int32_t _18 = 0;
		uint8_t _19 = _op_equal_equal_3(_17, _18);
		if (_19) {
			uint64_t _20 = i;
			uint64_t _21 = noctx_incr(_20);
			uint64_t _22 = n_threads;
			uint64_t* _23 = threads;
			struct thread_args* _24 = thread_args_begin;
			struct global_ctx* _25 = gctx;
			i = _21;
			n_threads = _22;
			threads = _23;
			thread_args_begin = _24;
			gctx = _25;
			goto top;
		} else {
			int32_t _26 = err2;
			int32_t _27 = eagain();
			uint8_t _28 = _op_equal_equal_3(_26, _27);
			if (_28) {
				return todo_1();
			} else {
				return todo_1();
			}
		}
	} else {
		return (struct void_) {};
	}
}
/* as-cell<nat> cell<nat>(p ptr<nat>) */
struct cell_0* as_cell(uint64_t* p) {
	uint64_t* _0 = p;
	uint8_t* _1 = (uint8_t*) _0;
	return (struct cell_0*) _1;
}
/* thread-fun ptr<nat8>(args-ptr ptr<nat8>) */
uint8_t* thread_fun(uint8_t* args_ptr) {
	struct thread_args* args0;
	uint8_t* _0 = args_ptr;
	args0 = (struct thread_args*) _0;
	
	struct thread_args* _1 = args0;
	uint64_t _2 = _1->thread_id;
	struct thread_args* _3 = args0;
	struct global_ctx* _4 = _3->gctx;
	thread_function(_2, _4);
	return NULL;
}
/* thread-function void(thread-id nat, gctx global-ctx) */
struct void_ thread_function(uint64_t thread_id, struct global_ctx* gctx) {
	struct exception_ctx ectx0;
	ectx0 = new_exception_ctx();
	
	struct log_ctx log_ctx1;
	log_ctx1 = new_log_ctx();
	
	struct thread_local_stuff tls2;
	struct exception_ctx* _0 = &ectx0;
	struct log_ctx* _1 = &log_ctx1;
	tls2 = (struct thread_local_stuff) {_0, _1};
	
	uint64_t _2 = thread_id;
	struct global_ctx* _3 = gctx;
	struct thread_local_stuff* _4 = &tls2;
	return thread_function_recur(_2, _3, _4);
}
/* thread-function-recur void(thread-id nat, gctx global-ctx, tls thread-local-stuff) */
struct void_ thread_function_recur(uint64_t thread_id, struct global_ctx* gctx, struct thread_local_stuff* tls) {
	top:;
	struct global_ctx* _0 = gctx;
	uint8_t _1 = _0->is_shut_down;
	if (_1) {
		struct lock* _2 = &gctx->lk;
		acquire_lock(_2);
		struct global_ctx* _3 = gctx;
		struct global_ctx* _4 = gctx;
		uint64_t _5 = _4->n_live_threads;
		uint64_t _6 = noctx_decr(_5);
		_3->n_live_threads = _6;
		uint64_t _7 = 0u;
		struct global_ctx* _8 = gctx;
		struct arr_2 _9 = _8->islands;
		assert_islands_are_shut_down(_7, _9);
		struct lock* _10 = &gctx->lk;
		return release_lock(_10);
	} else {
		struct global_ctx* _11 = gctx;
		uint64_t _12 = _11->n_live_threads;
		uint64_t _13 = 0u;
		uint8_t _14 = _op_greater(_12, _13);
		hard_assert(_14);
		uint64_t last_checked0;
		struct condition* _15 = &gctx->may_be_work_to_do;
		last_checked0 = get_last_checked(_15);
		
		struct global_ctx* _16 = gctx;
		struct result_2 _17 = choose_task(_16);
		switch (_17.kind) {
			case 0: {
				struct ok_2 ok_chosen_task1 = _17.as0;
				
				struct global_ctx* _18 = gctx;
				struct thread_local_stuff* _19 = tls;
				struct ok_2 _20 = ok_chosen_task1;
				struct chosen_task _21 = _20.value;
				do_task(_18, _19, _21);
				break;
			}
			case 1: {
				struct err_1 e2 = _17.as1;
				
				struct err_1 _22 = e2;
				struct no_chosen_task _23 = _22.value;
				uint8_t _24 = _23.last_thread_out;
				if (_24) {
					struct global_ctx* _25 = gctx;
					uint8_t _26 = _25->is_shut_down;
					hard_forbid(_26);
					struct global_ctx* _27 = gctx;
					uint8_t _28 = 1;
					_27->is_shut_down = _28;
					struct condition* _29 = &gctx->may_be_work_to_do;
					broadcast(_29);
				} else {
					struct condition* _30 = &gctx->may_be_work_to_do;
					uint64_t _31 = last_checked0;
					wait_on(_30, _31);
				}
				struct lock* _32 = &gctx->lk;
				acquire_lock(_32);
				struct global_ctx* _33 = gctx;
				struct global_ctx* _34 = gctx;
				uint64_t _35 = _34->n_live_threads;
				uint64_t _36 = noctx_incr(_35);
				_33->n_live_threads = _36;
				struct lock* _37 = &gctx->lk;
				release_lock(_37);
				break;
			}
			default:
				(assert(0),(struct void_) {});
		}
		uint64_t _38 = thread_id;
		struct global_ctx* _39 = gctx;
		struct thread_local_stuff* _40 = tls;
		thread_id = _38;
		gctx = _39;
		tls = _40;
		goto top;
	}
}
/* assert-islands-are-shut-down void(i nat, islands arr<island>) */
struct void_ assert_islands_are_shut_down(uint64_t i, struct arr_2 islands) {
	top:;
	uint64_t _0 = i;
	struct arr_2 _1 = islands;
	uint64_t _2 = _1.size;
	uint8_t _3 = _op_bang_equal_1(_0, _2);
	if (_3) {
		struct island* island0;
		struct arr_2 _4 = islands;
		uint64_t _5 = i;
		island0 = noctx_at_0(_4, _5);
		
		struct lock* _6 = &island0->tasks_lock;
		acquire_lock(_6);
		struct gc* _7 = &island0->gc;
		uint8_t _8 = _7->needs_gc__q;
		hard_forbid(_8);
		struct island* _9 = island0;
		uint64_t _10 = _9->n_threads_running;
		uint64_t _11 = 0u;
		uint8_t _12 = _op_equal_equal_0(_10, _11);
		hard_assert(_12);
		struct island* _13 = island0;
		struct mut_bag* _14 = tasks(_13);
		uint8_t _15 = empty__q_2(_14);
		hard_assert(_15);
		struct lock* _16 = &island0->tasks_lock;
		release_lock(_16);
		uint64_t _17 = i;
		uint64_t _18 = noctx_incr(_17);
		struct arr_2 _19 = islands;
		i = _18;
		islands = _19;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* empty?<task> bool(m mut-bag<task>) */
uint8_t empty__q_2(struct mut_bag* m) {
	struct mut_bag* _0 = m;
	struct opt_2 _1 = _0->head;
	return empty__q_3(_1);
}
/* empty?<mut-bag-node<?t>> bool(a opt<mut-bag-node<task>>) */
uint8_t empty__q_3(struct opt_2 a) {
	struct opt_2 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct none n0 = _0.as0;
			
			return 1;
		}
		case 1: {
			struct some_2 s1 = _0.as1;
			
			return 0;
		}
		default:
			return (assert(0),0);
	}
}
/* get-last-checked nat(c condition) */
uint64_t get_last_checked(struct condition* c) {
	struct condition* _0 = c;
	return _0->value;
}
/* choose-task result<chosen-task, no-chosen-task>(gctx global-ctx) */
struct result_2 choose_task(struct global_ctx* gctx) {
	struct lock* _0 = &gctx->lk;
	acquire_lock(_0);
	struct result_2 res1;
	struct global_ctx* _1 = gctx;
	struct arr_2 _2 = _1->islands;
	uint64_t _3 = 0u;
	struct opt_6 _4 = choose_task_recur(_2, _3);
	switch (_4.kind) {
		case 0: {
			struct global_ctx* _5 = gctx;
			struct global_ctx* _6 = gctx;
			uint64_t _7 = _6->n_live_threads;
			uint64_t _8 = noctx_decr(_7);
			_5->n_live_threads = _8;
			struct global_ctx* _9 = gctx;
			uint64_t _10 = _9->n_live_threads;
			uint64_t _11 = 0u;
			uint8_t _12 = _op_equal_equal_0(_10, _11);
			hard_assert(_12);
			struct global_ctx* _13 = gctx;
			uint64_t _14 = _13->n_live_threads;
			uint64_t _15 = 0u;
			uint8_t _16 = _op_equal_equal_0(_14, _15);
			struct no_chosen_task _17 = (struct no_chosen_task) {_16};
			struct err_1 _18 = (struct err_1) {_17};
			res1 = (struct result_2) {1, .as1 = _18};
			break;
		}
		case 1: {
			struct some_6 s0 = _4.as1;
			
			struct some_6 _19 = s0;
			struct chosen_task _20 = _19.value;
			struct ok_2 _21 = (struct ok_2) {_20};
			res1 = (struct result_2) {0, .as0 = _21};
			break;
		}
		default:
			(assert(0),(struct result_2) {0});
	}
	
	struct lock* _22 = &gctx->lk;
	release_lock(_22);
	return res1;
}
/* choose-task-recur opt<chosen-task>(islands arr<island>, i nat) */
struct opt_6 choose_task_recur(struct arr_2 islands, uint64_t i) {
	top:;
	uint64_t _0 = i;
	struct arr_2 _1 = islands;
	uint64_t _2 = _1.size;
	uint8_t _3 = _op_equal_equal_0(_0, _2);
	if (_3) {
		struct none _4 = (struct none) {};
		return (struct opt_6) {0, .as0 = _4};
	} else {
		struct island* island0;
		struct arr_2 _5 = islands;
		uint64_t _6 = i;
		island0 = noctx_at_0(_5, _6);
		
		struct island* _7 = island0;
		struct opt_7 _8 = choose_task_in_island(_7);
		switch (_8.kind) {
			case 0: {
				struct arr_2 _9 = islands;
				uint64_t _10 = i;
				uint64_t _11 = noctx_incr(_10);
				islands = _9;
				i = _11;
				goto top;
			}
			case 1: {
				struct some_7 s1 = _8.as1;
				
				struct island* _12 = island0;
				struct some_7 _13 = s1;
				struct opt_5 _14 = _13.value;
				struct chosen_task _15 = (struct chosen_task) {_12, _14};
				struct some_6 _16 = (struct some_6) {_15};
				return (struct opt_6) {1, .as1 = _16};
			}
			default:
				return (assert(0),(struct opt_6) {0});
		}
	}
}
/* choose-task-in-island opt<opt<task>>(island island) */
struct opt_7 choose_task_in_island(struct island* island) {
	struct lock* _0 = &island->tasks_lock;
	acquire_lock(_0);
	struct opt_7 res1;
	struct gc* _1 = &island->gc;
	uint8_t _2 = _1->needs_gc__q;
	if (_2) {
		struct island* _3 = island;
		uint64_t _4 = _3->n_threads_running;
		uint64_t _5 = 0u;
		uint8_t _6 = _op_equal_equal_0(_4, _5);
		if (_6) {
			struct none _7 = (struct none) {};
			struct opt_5 _8 = (struct opt_5) {0, .as0 = _7};
			struct some_7 _9 = (struct some_7) {_8};
			res1 = (struct opt_7) {1, .as1 = _9};
		} else {
			struct none _10 = (struct none) {};
			res1 = (struct opt_7) {0, .as0 = _10};
		}
	} else {
		struct island* _11 = island;
		struct opt_5 _12 = find_and_remove_first_doable_task(_11);
		switch (_12.kind) {
			case 0: {
				struct none _13 = (struct none) {};
				res1 = (struct opt_7) {0, .as0 = _13};
				break;
			}
			case 1: {
				struct some_5 s0 = _12.as1;
				
				struct some_5 _14 = s0;
				struct task _15 = _14.value;
				struct some_5 _16 = (struct some_5) {_15};
				struct opt_5 _17 = (struct opt_5) {1, .as1 = _16};
				struct some_7 _18 = (struct some_7) {_17};
				res1 = (struct opt_7) {1, .as1 = _18};
				break;
			}
			default:
				(assert(0),(struct opt_7) {0});
		}
	}
	
	struct opt_7 _19 = res1;
	uint8_t _20 = empty__q_4(_19);
	uint8_t _21 = !_20;
	if (_21) {
		struct island* _22 = island;
		struct island* _23 = island;
		uint64_t _24 = _23->n_threads_running;
		uint64_t _25 = noctx_incr(_24);
		_22->n_threads_running = _25;
	} else {
		(struct void_) {};
	}
	struct lock* _26 = &island->tasks_lock;
	release_lock(_26);
	return res1;
}
/* find-and-remove-first-doable-task opt<task>(island island) */
struct opt_5 find_and_remove_first_doable_task(struct island* island) {
	struct opt_8 res0;
	struct island* _0 = island;
	struct island* _1 = island;
	struct mut_bag* _2 = tasks(_1);
	struct opt_2 _3 = _2->head;
	res0 = find_and_remove_first_doable_task_recur(_0, _3);
	
	struct opt_8 _4 = res0;
	switch (_4.kind) {
		case 0: {
			struct none _5 = (struct none) {};
			return (struct opt_5) {0, .as0 = _5};
		}
		case 1: {
			struct some_8 s1 = _4.as1;
			
			struct island* _6 = island;
			struct mut_bag* _7 = tasks(_6);
			struct some_8 _8 = s1;
			struct task_and_nodes _9 = _8.value;
			struct opt_2 _10 = _9.nodes;
			_7->head = _10;
			struct some_8 _11 = s1;
			struct task_and_nodes _12 = _11.value;
			struct task _13 = _12.task;
			struct some_5 _14 = (struct some_5) {_13};
			return (struct opt_5) {1, .as1 = _14};
		}
		default:
			return (assert(0),(struct opt_5) {0});
	}
}
/* find-and-remove-first-doable-task-recur opt<task-and-nodes>(island island, opt-node opt<mut-bag-node<task>>) */
struct opt_8 find_and_remove_first_doable_task_recur(struct island* island, struct opt_2 opt_node) {
	struct opt_2 _0 = opt_node;
	switch (_0.kind) {
		case 0: {
			struct none _1 = (struct none) {};
			return (struct opt_8) {0, .as0 = _1};
		}
		case 1: {
			struct some_2 s0 = _0.as1;
			
			struct mut_bag_node* node1;
			struct some_2 _2 = s0;
			node1 = _2.value;
			
			struct task task2;
			struct mut_bag_node* _3 = node1;
			task2 = _3->value;
			
			struct mut_arr_0* exclusions3;
			exclusions3 = &island->currently_running_exclusions;
			
			uint8_t task_ok4;
			struct mut_arr_0* _4 = exclusions3;
			struct task _5 = task2;
			uint64_t _6 = _5.exclusion;
			uint8_t _7 = contains__q(_4, _6);
			if (_7) {
				task_ok4 = 0;
			} else {
				struct mut_arr_0* _8 = exclusions3;
				struct task _9 = task2;
				uint64_t _10 = _9.exclusion;
				push_capacity_must_be_sufficient(_8, _10);
				task_ok4 = 1;
			}
			
			uint8_t _11 = task_ok4;
			if (_11) {
				struct task _12 = task2;
				struct mut_bag_node* _13 = node1;
				struct opt_2 _14 = _13->next_node;
				struct task_and_nodes _15 = (struct task_and_nodes) {_12, _14};
				struct some_8 _16 = (struct some_8) {_15};
				return (struct opt_8) {1, .as1 = _16};
			} else {
				struct island* _17 = island;
				struct mut_bag_node* _18 = node1;
				struct opt_2 _19 = _18->next_node;
				struct opt_8 _20 = find_and_remove_first_doable_task_recur(_17, _19);
				switch (_20.kind) {
					case 0: {
						struct none _21 = (struct none) {};
						return (struct opt_8) {0, .as0 = _21};
					}
					case 1: {
						struct some_8 ss5 = _20.as1;
						
						struct task_and_nodes tn6;
						struct some_8 _22 = ss5;
						tn6 = _22.value;
						
						struct mut_bag_node* _23 = node1;
						struct task_and_nodes _24 = tn6;
						struct opt_2 _25 = _24.nodes;
						_23->next_node = _25;
						struct task_and_nodes _26 = tn6;
						struct task _27 = _26.task;
						struct mut_bag_node* _28 = node1;
						struct some_2 _29 = (struct some_2) {_28};
						struct opt_2 _30 = (struct opt_2) {1, .as1 = _29};
						struct task_and_nodes _31 = (struct task_and_nodes) {_27, _30};
						struct some_8 _32 = (struct some_8) {_31};
						return (struct opt_8) {1, .as1 = _32};
					}
					default:
						return (assert(0),(struct opt_8) {0});
				}
			}
		}
		default:
			return (assert(0),(struct opt_8) {0});
	}
}
/* contains?<nat> bool(a mut-arr<nat>, value nat) */
uint8_t contains__q(struct mut_arr_0* a, uint64_t value) {
	struct mut_arr_0* _0 = a;
	struct arr_4 _1 = temp_as_arr(_0);
	uint64_t _2 = value;
	uint64_t _3 = 0u;
	return contains_recur__q(_1, _2, _3);
}
/* contains-recur?<?t> bool(a arr<nat>, value nat, i nat) */
uint8_t contains_recur__q(struct arr_4 a, uint64_t value, uint64_t i) {
	top:;
	uint64_t _0 = i;
	struct arr_4 _1 = a;
	uint64_t _2 = _1.size;
	uint8_t _3 = _op_equal_equal_0(_0, _2);
	if (_3) {
		return 0;
	} else {
		struct arr_4 _4 = a;
		uint64_t _5 = i;
		uint64_t _6 = noctx_at_2(_4, _5);
		uint64_t _7 = value;
		uint8_t _8 = _op_equal_equal_0(_6, _7);
		if (_8) {
			return 1;
		} else {
			struct arr_4 _9 = a;
			uint64_t _10 = value;
			uint64_t _11 = i;
			uint64_t _12 = noctx_incr(_11);
			a = _9;
			value = _10;
			i = _12;
			goto top;
		}
	}
}
/* noctx-at<?t> nat(a arr<nat>, index nat) */
uint64_t noctx_at_2(struct arr_4 a, uint64_t index) {
	uint64_t _0 = index;
	struct arr_4 _1 = a;
	uint64_t _2 = _1.size;
	uint8_t _3 = _op_less(_0, _2);
	hard_assert(_3);
	struct arr_4 _4 = a;
	uint64_t* _5 = _4.data;
	uint64_t _6 = index;
	uint64_t* _7 = _5 + _6;
	return *_7;
}
/* temp-as-arr<?t> arr<nat>(a mut-arr<nat>) */
struct arr_4 temp_as_arr(struct mut_arr_0* a) {
	struct mut_arr_0* _0 = a;
	uint64_t _1 = _0->size;
	struct mut_arr_0* _2 = a;
	uint64_t* _3 = _2->data;
	return (struct arr_4) {_1, _3};
}
/* push-capacity-must-be-sufficient<nat> void(a mut-arr<nat>, value nat) */
struct void_ push_capacity_must_be_sufficient(struct mut_arr_0* a, uint64_t value) {
	struct mut_arr_0* _0 = a;
	uint64_t _1 = _0->size;
	struct mut_arr_0* _2 = a;
	uint64_t _3 = _2->capacity;
	uint8_t _4 = _op_less(_1, _3);
	hard_assert(_4);
	uint64_t old_size0;
	struct mut_arr_0* _5 = a;
	old_size0 = _5->size;
	
	struct mut_arr_0* _6 = a;
	uint64_t _7 = old_size0;
	uint64_t _8 = noctx_incr(_7);
	_6->size = _8;
	struct mut_arr_0* _9 = a;
	uint64_t _10 = old_size0;
	uint64_t _11 = value;
	return noctx_set_at_1(_9, _10, _11);
}
/* noctx-set-at<?t> void(a mut-arr<nat>, index nat, value nat) */
struct void_ noctx_set_at_1(struct mut_arr_0* a, uint64_t index, uint64_t value) {
	uint64_t _0 = index;
	struct mut_arr_0* _1 = a;
	uint64_t _2 = _1->size;
	uint8_t _3 = _op_less(_0, _2);
	hard_assert(_3);
	struct mut_arr_0* _4 = a;
	uint64_t* _5 = _4->data;
	uint64_t _6 = index;
	uint64_t* _7 = _5 + _6;
	uint64_t _8 = value;
	return (*_7 = _8, (struct void_) {});
}
/* empty?<opt<task>> bool(a opt<opt<task>>) */
uint8_t empty__q_4(struct opt_7 a) {
	struct opt_7 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct none n0 = _0.as0;
			
			return 1;
		}
		case 1: {
			struct some_7 s1 = _0.as1;
			
			return 0;
		}
		default:
			return (assert(0),0);
	}
}
/* do-task void(gctx global-ctx, tls thread-local-stuff, chosen-task chosen-task) */
struct void_ do_task(struct global_ctx* gctx, struct thread_local_stuff* tls, struct chosen_task chosen_task) {
	struct island* island0;
	struct chosen_task _0 = chosen_task;
	island0 = _0.island;
	
	struct chosen_task _1 = chosen_task;
	struct opt_5 _2 = _1.task_or_gc;
	switch (_2.kind) {
		case 0: {
			struct gc* _3 = &island0->gc;
			struct island* _4 = island0;
			struct island_gc_root _5 = _4->gc_root;
			run_garbage_collection(_3, _5);
			struct condition* _6 = &gctx->may_be_work_to_do;
			broadcast(_6);
			break;
		}
		case 1: {
			struct some_5 some_task1 = _2.as1;
			
			struct task task2;
			struct some_5 _7 = some_task1;
			task2 = _7.value;
			
			struct ctx ctx3;
			struct global_ctx* _8 = gctx;
			struct thread_local_stuff* _9 = tls;
			struct island* _10 = island0;
			struct task _11 = task2;
			uint64_t _12 = _11.exclusion;
			ctx3 = new_ctx(_8, _9, _10, _12);
			
			struct task _13 = task2;
			struct fun_mut0_0 _14 = _13.fun;
			struct ctx* _15 = &ctx3;
			call_w_ctx_143(_14, _15);
			struct lock* _16 = &island0->tasks_lock;
			acquire_lock(_16);
			struct mut_arr_0* _17 = &island0->currently_running_exclusions;
			struct task _18 = task2;
			uint64_t _19 = _18.exclusion;
			noctx_must_remove_unordered(_17, _19);
			struct lock* _20 = &island0->tasks_lock;
			release_lock(_20);
			struct ctx* _21 = &ctx3;
			return_ctx(_21);
			break;
		}
		default:
			(assert(0),(struct void_) {});
	}
	struct lock* _22 = &island0->tasks_lock;
	acquire_lock(_22);
	struct island* _23 = island0;
	struct island* _24 = island0;
	uint64_t _25 = _24->n_threads_running;
	uint64_t _26 = noctx_decr(_25);
	_23->n_threads_running = _26;
	struct lock* _27 = &island0->tasks_lock;
	return release_lock(_27);
}
/* run-garbage-collection<by-val<island-gc-root>> void(gc gc, gc-root island-gc-root) */
struct void_ run_garbage_collection(struct gc* gc, struct island_gc_root gc_root) {
	struct gc* _0 = gc;
	uint8_t _1 = _0->needs_gc__q;
	hard_assert(_1);
	struct gc* _2 = gc;
	uint8_t _3 = 0;
	_2->needs_gc__q = _3;
	struct gc* _4 = gc;
	struct gc* _5 = gc;
	uint64_t _6 = _5->gc_count;
	uint64_t _7 = wrap_incr(_6);
	_4->gc_count = _7;
	struct gc* _8 = gc;
	uint8_t* _9 = _8->mark_begin;
	uint8_t* _10 = (uint8_t*) _9;
	uint8_t _11 = 0u;
	struct gc* _12 = gc;
	uint64_t _13 = _12->size_words;
	(memset(_10, _11, _13), (struct void_) {});
	struct mark_ctx mark_ctx0;
	struct gc* _14 = gc;
	uint64_t _15 = _14->size_words;
	struct gc* _16 = gc;
	uint8_t* _17 = _16->mark_begin;
	struct gc* _18 = gc;
	uint64_t* _19 = _18->data_begin;
	mark_ctx0 = (struct mark_ctx) {_15, _17, _19};
	
	struct mark_ctx* _20 = &mark_ctx0;
	struct island_gc_root _21 = gc_root;
	mark_visit_216(_20, _21);
	struct gc* _22 = gc;
	struct gc* _23 = gc;
	uint8_t* _24 = _23->mark_begin;
	_22->mark_cur = _24;
	struct gc* _25 = gc;
	struct gc* _26 = gc;
	uint64_t* _27 = _26->data_begin;
	_25->data_cur = _27;
	struct gc* _28 = gc;
	return validate_gc(_28);
}
/* mark-visit<island-gc-root> (generated) (generated) */
struct void_ mark_visit_216(struct mark_ctx* mark_ctx, struct island_gc_root value) {
	struct mark_ctx* _0 = mark_ctx;
	struct island_gc_root _1 = value;
	struct mut_bag _2 = _1.tasks;
	mark_visit_217(_0, _2);
	struct mark_ctx* _3 = mark_ctx;
	struct island_gc_root _4 = value;
	struct fun_mut1_1 _5 = _4.exception_handler;
	return mark_visit_254(_3, _5);
}
/* mark-visit<mut-bag<task>> (generated) (generated) */
struct void_ mark_visit_217(struct mark_ctx* mark_ctx, struct mut_bag value) {
	struct mark_ctx* _0 = mark_ctx;
	struct mut_bag _1 = value;
	struct opt_2 _2 = _1.head;
	return mark_visit_218(_0, _2);
}
/* mark-visit<opt<mut-bag-node<task>>> (generated) (generated) */
struct void_ mark_visit_218(struct mark_ctx* mark_ctx, struct opt_2 value) {
	struct opt_2 _0 = value;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct some_2 value1 = _0.as1;
			
			struct mark_ctx* _1 = mark_ctx;
			struct some_2 _2 = value1;
			return mark_visit_219(_1, _2);
		}
		default:
			return (assert(0),(struct void_) {});
	}
}
/* mark-visit<some<mut-bag-node<task>>> (generated) (generated) */
struct void_ mark_visit_219(struct mark_ctx* mark_ctx, struct some_2 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct some_2 _1 = value;
	struct mut_bag_node* _2 = _1.value;
	return mark_visit_253(_0, _2);
}
/* mark-visit<mut-bag-node<task>> (generated) (generated) */
struct void_ mark_visit_220(struct mark_ctx* mark_ctx, struct mut_bag_node value) {
	struct mark_ctx* _0 = mark_ctx;
	struct mut_bag_node _1 = value;
	struct task _2 = _1.value;
	mark_visit_221(_0, _2);
	struct mark_ctx* _3 = mark_ctx;
	struct mut_bag_node _4 = value;
	struct opt_2 _5 = _4.next_node;
	return mark_visit_218(_3, _5);
}
/* mark-visit<task> (generated) (generated) */
struct void_ mark_visit_221(struct mark_ctx* mark_ctx, struct task value) {
	struct mark_ctx* _0 = mark_ctx;
	struct task _1 = value;
	struct fun_mut0_0 _2 = _1.fun;
	return mark_visit_222(_0, _2);
}
/* mark-visit<fun-mut0<void>> (generated) (generated) */
struct void_ mark_visit_222(struct mark_ctx* mark_ctx, struct fun_mut0_0 value) {
	struct fun_mut0_0 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct call_ref_0__lambda0__lambda0* value0 = _0.as0;
			
			struct mark_ctx* _1 = mark_ctx;
			struct call_ref_0__lambda0__lambda0* _2 = value0;
			return mark_visit_246(_1, _2);
		}
		case 1: {
			struct call_ref_0__lambda0* value1 = _0.as1;
			
			struct mark_ctx* _3 = mark_ctx;
			struct call_ref_0__lambda0* _4 = value1;
			return mark_visit_248(_3, _4);
		}
		case 2: {
			struct call_ref_1__lambda0__lambda0* value2 = _0.as2;
			
			struct mark_ctx* _5 = mark_ctx;
			struct call_ref_1__lambda0__lambda0* _6 = value2;
			return mark_visit_250(_5, _6);
		}
		case 3: {
			struct call_ref_1__lambda0* value3 = _0.as3;
			
			struct mark_ctx* _7 = mark_ctx;
			struct call_ref_1__lambda0* _8 = value3;
			return mark_visit_252(_7, _8);
		}
		default:
			return (assert(0),(struct void_) {});
	}
}
/* mark-visit<call-ref<?out, ?in>.lambda0.lambda0> (generated) (generated) */
struct void_ mark_visit_223(struct mark_ctx* mark_ctx, struct call_ref_0__lambda0__lambda0 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct call_ref_0__lambda0__lambda0 _1 = value;
	struct fun_ref1 _2 = _1.f;
	mark_visit_224(_0, _2);
	struct mark_ctx* _3 = mark_ctx;
	struct call_ref_0__lambda0__lambda0 _4 = value;
	struct fut_0* _5 = _4.res;
	return mark_visit_241(_3, _5);
}
/* mark-visit<fun-ref1<int32, void>> (generated) (generated) */
struct void_ mark_visit_224(struct mark_ctx* mark_ctx, struct fun_ref1 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct fun_ref1 _1 = value;
	struct fun_mut1_3 _2 = _1.fun;
	return mark_visit_225(_0, _2);
}
/* mark-visit<fun-mut1<fut<int32>, void>> (generated) (generated) */
struct void_ mark_visit_225(struct mark_ctx* mark_ctx, struct fun_mut1_3 value) {
	struct fun_mut1_3 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct then2__lambda0* value0 = _0.as0;
			
			struct mark_ctx* _1 = mark_ctx;
			struct then2__lambda0* _2 = value0;
			return mark_visit_232(_1, _2);
		}
		default:
			return (assert(0),(struct void_) {});
	}
}
/* mark-visit<then2<int32>.lambda0> (generated) (generated) */
struct void_ mark_visit_226(struct mark_ctx* mark_ctx, struct then2__lambda0 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct then2__lambda0 _1 = value;
	struct fun_ref0 _2 = _1.cb;
	return mark_visit_227(_0, _2);
}
/* mark-visit<fun-ref0<int32>> (generated) (generated) */
struct void_ mark_visit_227(struct mark_ctx* mark_ctx, struct fun_ref0 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct fun_ref0 _1 = value;
	struct fun_mut0_1 _2 = _1.fun;
	return mark_visit_228(_0, _2);
}
/* mark-visit<fun-mut0<fut<int32>>> (generated) (generated) */
struct void_ mark_visit_228(struct mark_ctx* mark_ctx, struct fun_mut0_1 value) {
	struct fun_mut0_1 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct add_first_task__lambda0* value0 = _0.as0;
			
			struct mark_ctx* _1 = mark_ctx;
			struct add_first_task__lambda0* _2 = value0;
			return mark_visit_231(_1, _2);
		}
		default:
			return (assert(0),(struct void_) {});
	}
}
/* mark-visit<add-first-task.lambda0> (generated) (generated) */
struct void_ mark_visit_229(struct mark_ctx* mark_ctx, struct add_first_task__lambda0 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct add_first_task__lambda0 _1 = value;
	struct arr_3 _2 = _1.all_args;
	return mark_arr_230(_0, _2);
}
/* mark-arr<raw-ptr(char)> (generated) (generated) */
struct void_ mark_arr_230(struct mark_ctx* mark_ctx, struct arr_3 a) {
	uint8_t dropped0;
	struct mark_ctx* _0 = mark_ctx;
	struct arr_3 _1 = a;
	char** _2 = _1.data;
	uint8_t* _3 = (uint8_t*) _2;
	struct arr_3 _4 = a;
	uint64_t _5 = _4.size;
	uint64_t _6 = sizeof(char*);
	uint64_t _7 = _5 * _6;
	dropped0 = mark(_0, _3, _7);
	
	return (struct void_) {};
}
/* mark-visit<gc-ptr(add-first-task.lambda0)> (generated) (generated) */
struct void_ mark_visit_231(struct mark_ctx* mark_ctx, struct add_first_task__lambda0* value) {
	struct mark_ctx* _0 = mark_ctx;
	struct add_first_task__lambda0* _1 = value;
	uint8_t* _2 = (uint8_t*) _1;
	uint64_t _3 = sizeof(struct add_first_task__lambda0);
	uint8_t _4 = mark(_0, _2, _3);
	if (_4) {
		struct mark_ctx* _5 = mark_ctx;
		struct add_first_task__lambda0* _6 = value;
		struct add_first_task__lambda0 _7 = *_6;
		return mark_visit_229(_5, _7);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(then2<int32>.lambda0)> (generated) (generated) */
struct void_ mark_visit_232(struct mark_ctx* mark_ctx, struct then2__lambda0* value) {
	struct mark_ctx* _0 = mark_ctx;
	struct then2__lambda0* _1 = value;
	uint8_t* _2 = (uint8_t*) _1;
	uint64_t _3 = sizeof(struct then2__lambda0);
	uint8_t _4 = mark(_0, _2, _3);
	if (_4) {
		struct mark_ctx* _5 = mark_ctx;
		struct then2__lambda0* _6 = value;
		struct then2__lambda0 _7 = *_6;
		return mark_visit_226(_5, _7);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<fut<int32>> (generated) (generated) */
struct void_ mark_visit_233(struct mark_ctx* mark_ctx, struct fut_0 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct fut_0 _1 = value;
	struct fut_state_0 _2 = _1.state;
	return mark_visit_234(_0, _2);
}
/* mark-visit<fut-state<int32>> (generated) (generated) */
struct void_ mark_visit_234(struct mark_ctx* mark_ctx, struct fut_state_0 value) {
	struct fut_state_0 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct fut_state_callbacks_0 value0 = _0.as0;
			
			struct mark_ctx* _1 = mark_ctx;
			struct fut_state_callbacks_0 _2 = value0;
			return mark_visit_235(_1, _2);
		}
		case 1: {
			return (struct void_) {};
		}
		case 2: {
			struct exception value2 = _0.as2;
			
			struct mark_ctx* _3 = mark_ctx;
			struct exception _4 = value2;
			return mark_visit_244(_3, _4);
		}
		default:
			return (assert(0),(struct void_) {});
	}
}
/* mark-visit<fut-state-callbacks<int32>> (generated) (generated) */
struct void_ mark_visit_235(struct mark_ctx* mark_ctx, struct fut_state_callbacks_0 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct fut_state_callbacks_0 _1 = value;
	struct opt_0 _2 = _1.head;
	return mark_visit_236(_0, _2);
}
/* mark-visit<opt<fut-callback-node<int32>>> (generated) (generated) */
struct void_ mark_visit_236(struct mark_ctx* mark_ctx, struct opt_0 value) {
	struct opt_0 _0 = value;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct some_0 value1 = _0.as1;
			
			struct mark_ctx* _1 = mark_ctx;
			struct some_0 _2 = value1;
			return mark_visit_237(_1, _2);
		}
		default:
			return (assert(0),(struct void_) {});
	}
}
/* mark-visit<some<fut-callback-node<int32>>> (generated) (generated) */
struct void_ mark_visit_237(struct mark_ctx* mark_ctx, struct some_0 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct some_0 _1 = value;
	struct fut_callback_node_0* _2 = _1.value;
	return mark_visit_243(_0, _2);
}
/* mark-visit<fut-callback-node<int32>> (generated) (generated) */
struct void_ mark_visit_238(struct mark_ctx* mark_ctx, struct fut_callback_node_0 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct fut_callback_node_0 _1 = value;
	struct fun_mut1_0 _2 = _1.cb;
	mark_visit_239(_0, _2);
	struct mark_ctx* _3 = mark_ctx;
	struct fut_callback_node_0 _4 = value;
	struct opt_0 _5 = _4.next_node;
	return mark_visit_236(_3, _5);
}
/* mark-visit<fun-mut1<void, result<int32, exception>>> (generated) (generated) */
struct void_ mark_visit_239(struct mark_ctx* mark_ctx, struct fun_mut1_0 value) {
	struct fun_mut1_0 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct forward_to__lambda0* value0 = _0.as0;
			
			struct mark_ctx* _1 = mark_ctx;
			struct forward_to__lambda0* _2 = value0;
			return mark_visit_242(_1, _2);
		}
		default:
			return (assert(0),(struct void_) {});
	}
}
/* mark-visit<forward-to<?out>.lambda0> (generated) (generated) */
struct void_ mark_visit_240(struct mark_ctx* mark_ctx, struct forward_to__lambda0 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct forward_to__lambda0 _1 = value;
	struct fut_0* _2 = _1.to;
	return mark_visit_241(_0, _2);
}
/* mark-visit<gc-ptr(fut<int32>)> (generated) (generated) */
struct void_ mark_visit_241(struct mark_ctx* mark_ctx, struct fut_0* value) {
	struct mark_ctx* _0 = mark_ctx;
	struct fut_0* _1 = value;
	uint8_t* _2 = (uint8_t*) _1;
	uint64_t _3 = sizeof(struct fut_0);
	uint8_t _4 = mark(_0, _2, _3);
	if (_4) {
		struct mark_ctx* _5 = mark_ctx;
		struct fut_0* _6 = value;
		struct fut_0 _7 = *_6;
		return mark_visit_233(_5, _7);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(forward-to<?out>.lambda0)> (generated) (generated) */
struct void_ mark_visit_242(struct mark_ctx* mark_ctx, struct forward_to__lambda0* value) {
	struct mark_ctx* _0 = mark_ctx;
	struct forward_to__lambda0* _1 = value;
	uint8_t* _2 = (uint8_t*) _1;
	uint64_t _3 = sizeof(struct forward_to__lambda0);
	uint8_t _4 = mark(_0, _2, _3);
	if (_4) {
		struct mark_ctx* _5 = mark_ctx;
		struct forward_to__lambda0* _6 = value;
		struct forward_to__lambda0 _7 = *_6;
		return mark_visit_240(_5, _7);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(fut-callback-node<int32>)> (generated) (generated) */
struct void_ mark_visit_243(struct mark_ctx* mark_ctx, struct fut_callback_node_0* value) {
	struct mark_ctx* _0 = mark_ctx;
	struct fut_callback_node_0* _1 = value;
	uint8_t* _2 = (uint8_t*) _1;
	uint64_t _3 = sizeof(struct fut_callback_node_0);
	uint8_t _4 = mark(_0, _2, _3);
	if (_4) {
		struct mark_ctx* _5 = mark_ctx;
		struct fut_callback_node_0* _6 = value;
		struct fut_callback_node_0 _7 = *_6;
		return mark_visit_238(_5, _7);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<exception> (generated) (generated) */
struct void_ mark_visit_244(struct mark_ctx* mark_ctx, struct exception value) {
	struct mark_ctx* _0 = mark_ctx;
	struct exception _1 = value;
	struct arr_0 _2 = _1.message;
	return mark_arr_245(_0, _2);
}
/* mark-arr<char> (generated) (generated) */
struct void_ mark_arr_245(struct mark_ctx* mark_ctx, struct arr_0 a) {
	uint8_t dropped0;
	struct mark_ctx* _0 = mark_ctx;
	struct arr_0 _1 = a;
	char* _2 = _1.data;
	uint8_t* _3 = (uint8_t*) _2;
	struct arr_0 _4 = a;
	uint64_t _5 = _4.size;
	uint64_t _6 = sizeof(char);
	uint64_t _7 = _5 * _6;
	dropped0 = mark(_0, _3, _7);
	
	return (struct void_) {};
}
/* mark-visit<gc-ptr(call-ref<?out, ?in>.lambda0.lambda0)> (generated) (generated) */
struct void_ mark_visit_246(struct mark_ctx* mark_ctx, struct call_ref_0__lambda0__lambda0* value) {
	struct mark_ctx* _0 = mark_ctx;
	struct call_ref_0__lambda0__lambda0* _1 = value;
	uint8_t* _2 = (uint8_t*) _1;
	uint64_t _3 = sizeof(struct call_ref_0__lambda0__lambda0);
	uint8_t _4 = mark(_0, _2, _3);
	if (_4) {
		struct mark_ctx* _5 = mark_ctx;
		struct call_ref_0__lambda0__lambda0* _6 = value;
		struct call_ref_0__lambda0__lambda0 _7 = *_6;
		return mark_visit_223(_5, _7);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<call-ref<?out, ?in>.lambda0> (generated) (generated) */
struct void_ mark_visit_247(struct mark_ctx* mark_ctx, struct call_ref_0__lambda0 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct call_ref_0__lambda0 _1 = value;
	struct fun_ref1 _2 = _1.f;
	mark_visit_224(_0, _2);
	struct mark_ctx* _3 = mark_ctx;
	struct call_ref_0__lambda0 _4 = value;
	struct fut_0* _5 = _4.res;
	return mark_visit_241(_3, _5);
}
/* mark-visit<gc-ptr(call-ref<?out, ?in>.lambda0)> (generated) (generated) */
struct void_ mark_visit_248(struct mark_ctx* mark_ctx, struct call_ref_0__lambda0* value) {
	struct mark_ctx* _0 = mark_ctx;
	struct call_ref_0__lambda0* _1 = value;
	uint8_t* _2 = (uint8_t*) _1;
	uint64_t _3 = sizeof(struct call_ref_0__lambda0);
	uint8_t _4 = mark(_0, _2, _3);
	if (_4) {
		struct mark_ctx* _5 = mark_ctx;
		struct call_ref_0__lambda0* _6 = value;
		struct call_ref_0__lambda0 _7 = *_6;
		return mark_visit_247(_5, _7);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<call-ref<?out>.lambda0.lambda0> (generated) (generated) */
struct void_ mark_visit_249(struct mark_ctx* mark_ctx, struct call_ref_1__lambda0__lambda0 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct call_ref_1__lambda0__lambda0 _1 = value;
	struct fun_ref0 _2 = _1.f;
	mark_visit_227(_0, _2);
	struct mark_ctx* _3 = mark_ctx;
	struct call_ref_1__lambda0__lambda0 _4 = value;
	struct fut_0* _5 = _4.res;
	return mark_visit_241(_3, _5);
}
/* mark-visit<gc-ptr(call-ref<?out>.lambda0.lambda0)> (generated) (generated) */
struct void_ mark_visit_250(struct mark_ctx* mark_ctx, struct call_ref_1__lambda0__lambda0* value) {
	struct mark_ctx* _0 = mark_ctx;
	struct call_ref_1__lambda0__lambda0* _1 = value;
	uint8_t* _2 = (uint8_t*) _1;
	uint64_t _3 = sizeof(struct call_ref_1__lambda0__lambda0);
	uint8_t _4 = mark(_0, _2, _3);
	if (_4) {
		struct mark_ctx* _5 = mark_ctx;
		struct call_ref_1__lambda0__lambda0* _6 = value;
		struct call_ref_1__lambda0__lambda0 _7 = *_6;
		return mark_visit_249(_5, _7);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<call-ref<?out>.lambda0> (generated) (generated) */
struct void_ mark_visit_251(struct mark_ctx* mark_ctx, struct call_ref_1__lambda0 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct call_ref_1__lambda0 _1 = value;
	struct fun_ref0 _2 = _1.f;
	mark_visit_227(_0, _2);
	struct mark_ctx* _3 = mark_ctx;
	struct call_ref_1__lambda0 _4 = value;
	struct fut_0* _5 = _4.res;
	return mark_visit_241(_3, _5);
}
/* mark-visit<gc-ptr(call-ref<?out>.lambda0)> (generated) (generated) */
struct void_ mark_visit_252(struct mark_ctx* mark_ctx, struct call_ref_1__lambda0* value) {
	struct mark_ctx* _0 = mark_ctx;
	struct call_ref_1__lambda0* _1 = value;
	uint8_t* _2 = (uint8_t*) _1;
	uint64_t _3 = sizeof(struct call_ref_1__lambda0);
	uint8_t _4 = mark(_0, _2, _3);
	if (_4) {
		struct mark_ctx* _5 = mark_ctx;
		struct call_ref_1__lambda0* _6 = value;
		struct call_ref_1__lambda0 _7 = *_6;
		return mark_visit_251(_5, _7);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(mut-bag-node<task>)> (generated) (generated) */
struct void_ mark_visit_253(struct mark_ctx* mark_ctx, struct mut_bag_node* value) {
	struct mark_ctx* _0 = mark_ctx;
	struct mut_bag_node* _1 = value;
	uint8_t* _2 = (uint8_t*) _1;
	uint64_t _3 = sizeof(struct mut_bag_node);
	uint8_t _4 = mark(_0, _2, _3);
	if (_4) {
		struct mark_ctx* _5 = mark_ctx;
		struct mut_bag_node* _6 = value;
		struct mut_bag_node _7 = *_6;
		return mark_visit_220(_5, _7);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<fun-mut1<void, exception>> (generated) (generated) */
struct void_ mark_visit_254(struct mark_ctx* mark_ctx, struct fun_mut1_1 value) {
	struct fun_mut1_1 _0 = value;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct call_ref_0__lambda0__lambda1* value1 = _0.as1;
			
			struct mark_ctx* _1 = mark_ctx;
			struct call_ref_0__lambda0__lambda1* _2 = value1;
			return mark_visit_256(_1, _2);
		}
		case 2: {
			struct call_ref_1__lambda0__lambda1* value2 = _0.as2;
			
			struct mark_ctx* _3 = mark_ctx;
			struct call_ref_1__lambda0__lambda1* _4 = value2;
			return mark_visit_258(_3, _4);
		}
		default:
			return (assert(0),(struct void_) {});
	}
}
/* mark-visit<call-ref<?out, ?in>.lambda0.lambda1> (generated) (generated) */
struct void_ mark_visit_255(struct mark_ctx* mark_ctx, struct call_ref_0__lambda0__lambda1 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct call_ref_0__lambda0__lambda1 _1 = value;
	struct fut_0* _2 = _1.res;
	return mark_visit_241(_0, _2);
}
/* mark-visit<gc-ptr(call-ref<?out, ?in>.lambda0.lambda1)> (generated) (generated) */
struct void_ mark_visit_256(struct mark_ctx* mark_ctx, struct call_ref_0__lambda0__lambda1* value) {
	struct mark_ctx* _0 = mark_ctx;
	struct call_ref_0__lambda0__lambda1* _1 = value;
	uint8_t* _2 = (uint8_t*) _1;
	uint64_t _3 = sizeof(struct call_ref_0__lambda0__lambda1);
	uint8_t _4 = mark(_0, _2, _3);
	if (_4) {
		struct mark_ctx* _5 = mark_ctx;
		struct call_ref_0__lambda0__lambda1* _6 = value;
		struct call_ref_0__lambda0__lambda1 _7 = *_6;
		return mark_visit_255(_5, _7);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<call-ref<?out>.lambda0.lambda1> (generated) (generated) */
struct void_ mark_visit_257(struct mark_ctx* mark_ctx, struct call_ref_1__lambda0__lambda1 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct call_ref_1__lambda0__lambda1 _1 = value;
	struct fut_0* _2 = _1.res;
	return mark_visit_241(_0, _2);
}
/* mark-visit<gc-ptr(call-ref<?out>.lambda0.lambda1)> (generated) (generated) */
struct void_ mark_visit_258(struct mark_ctx* mark_ctx, struct call_ref_1__lambda0__lambda1* value) {
	struct mark_ctx* _0 = mark_ctx;
	struct call_ref_1__lambda0__lambda1* _1 = value;
	uint8_t* _2 = (uint8_t*) _1;
	uint64_t _3 = sizeof(struct call_ref_1__lambda0__lambda1);
	uint8_t _4 = mark(_0, _2, _3);
	if (_4) {
		struct mark_ctx* _5 = mark_ctx;
		struct call_ref_1__lambda0__lambda1* _6 = value;
		struct call_ref_1__lambda0__lambda1 _7 = *_6;
		return mark_visit_257(_5, _7);
	} else {
		return (struct void_) {};
	}
}
/* noctx-must-remove-unordered<nat> void(a mut-arr<nat>, value nat) */
struct void_ noctx_must_remove_unordered(struct mut_arr_0* a, uint64_t value) {
	struct mut_arr_0* _0 = a;
	uint64_t _1 = 0u;
	uint64_t _2 = value;
	return noctx_must_remove_unordered_recur(_0, _1, _2);
}
/* noctx-must-remove-unordered-recur<?t> void(a mut-arr<nat>, index nat, value nat) */
struct void_ noctx_must_remove_unordered_recur(struct mut_arr_0* a, uint64_t index, uint64_t value) {
	top:;
	uint64_t _0 = index;
	struct mut_arr_0* _1 = a;
	uint64_t _2 = _1->size;
	uint8_t _3 = _op_equal_equal_0(_0, _2);
	if (_3) {
		return (assert(0),(struct void_) {});
	} else {
		struct mut_arr_0* _4 = a;
		uint64_t _5 = index;
		uint64_t _6 = noctx_at_3(_4, _5);
		uint64_t _7 = value;
		uint8_t _8 = _op_equal_equal_0(_6, _7);
		if (_8) {
			struct mut_arr_0* _9 = a;
			uint64_t _10 = index;
			uint64_t _11 = noctx_remove_unordered_at_index(_9, _10);
			return drop_2(_11);
		} else {
			struct mut_arr_0* _12 = a;
			uint64_t _13 = index;
			uint64_t _14 = noctx_incr(_13);
			uint64_t _15 = value;
			a = _12;
			index = _14;
			value = _15;
			goto top;
		}
	}
}
/* noctx-at<?t> nat(a mut-arr<nat>, index nat) */
uint64_t noctx_at_3(struct mut_arr_0* a, uint64_t index) {
	uint64_t _0 = index;
	struct mut_arr_0* _1 = a;
	uint64_t _2 = _1->size;
	uint8_t _3 = _op_less(_0, _2);
	hard_assert(_3);
	struct mut_arr_0* _4 = a;
	uint64_t* _5 = _4->data;
	uint64_t _6 = index;
	uint64_t* _7 = _5 + _6;
	return *_7;
}
/* drop<?t> void(t nat) */
struct void_ drop_2(uint64_t t) {
	return (struct void_) {};
}
/* noctx-remove-unordered-at-index<?t> nat(a mut-arr<nat>, index nat) */
uint64_t noctx_remove_unordered_at_index(struct mut_arr_0* a, uint64_t index) {
	uint64_t res0;
	struct mut_arr_0* _0 = a;
	uint64_t _1 = index;
	res0 = noctx_at_3(_0, _1);
	
	struct mut_arr_0* _2 = a;
	uint64_t _3 = index;
	struct mut_arr_0* _4 = a;
	uint64_t _5 = noctx_last(_4);
	noctx_set_at_1(_2, _3, _5);
	struct mut_arr_0* _6 = a;
	struct mut_arr_0* _7 = a;
	uint64_t _8 = _7->size;
	uint64_t _9 = noctx_decr(_8);
	_6->size = _9;
	return res0;
}
/* noctx-last<?t> nat(a mut-arr<nat>) */
uint64_t noctx_last(struct mut_arr_0* a) {
	struct mut_arr_0* _0 = a;
	uint8_t _1 = empty__q_5(_0);
	hard_forbid(_1);
	struct mut_arr_0* _2 = a;
	struct mut_arr_0* _3 = a;
	uint64_t _4 = _3->size;
	uint64_t _5 = noctx_decr(_4);
	return noctx_at_3(_2, _5);
}
/* empty?<?t> bool(a mut-arr<nat>) */
uint8_t empty__q_5(struct mut_arr_0* a) {
	struct mut_arr_0* _0 = a;
	uint64_t _1 = _0->size;
	uint64_t _2 = 0u;
	return _op_equal_equal_0(_1, _2);
}
/* return-ctx void(c ctx) */
struct void_ return_ctx(struct ctx* c) {
	struct ctx* _0 = c;
	uint8_t* _1 = _0->gc_ctx_ptr;
	struct gc_ctx* _2 = (struct gc_ctx*) _1;
	return return_gc_ctx(_2);
}
/* return-gc-ctx void(gc-ctx gc-ctx) */
struct void_ return_gc_ctx(struct gc_ctx* gc_ctx) {
	struct gc* gc0;
	struct gc_ctx* _0 = gc_ctx;
	gc0 = _0->gc;
	
	struct lock* _1 = &gc0->lk;
	acquire_lock(_1);
	struct gc_ctx* _2 = gc_ctx;
	struct gc* _3 = gc0;
	struct opt_1 _4 = _3->context_head;
	_2->next_ctx = _4;
	struct gc* _5 = gc0;
	struct gc_ctx* _6 = gc_ctx;
	struct some_1 _7 = (struct some_1) {_6};
	struct opt_1 _8 = (struct opt_1) {1, .as1 = _7};
	_5->context_head = _8;
	struct lock* _9 = &gc0->lk;
	return release_lock(_9);
}
/* wait-on void(c condition, last-checked nat) */
struct void_ wait_on(struct condition* c, uint64_t last_checked) {
	top:;
	struct condition* _0 = c;
	uint64_t _1 = _0->value;
	uint64_t _2 = last_checked;
	uint8_t _3 = _op_equal_equal_0(_1, _2);
	if (_3) {
		yield_thread();
		struct condition* _4 = c;
		uint64_t _5 = last_checked;
		c = _4;
		last_checked = _5;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* eagain int32() */
int32_t eagain(void) {
	return 11;
}
/* join-threads-recur void(i nat, n-threads nat, threads ptr<nat>) */
struct void_ join_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads) {
	top:;
	uint64_t _0 = i;
	uint64_t _1 = n_threads;
	uint8_t _2 = _op_bang_equal_1(_0, _1);
	if (_2) {
		uint64_t* _3 = threads;
		uint64_t _4 = i;
		uint64_t* _5 = _3 + _4;
		uint64_t _6 = *_5;
		join_one_thread(_6);
		uint64_t _7 = i;
		uint64_t _8 = noctx_incr(_7);
		uint64_t _9 = n_threads;
		uint64_t* _10 = threads;
		i = _8;
		n_threads = _9;
		threads = _10;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* join-one-thread void(tid nat) */
struct void_ join_one_thread(uint64_t tid) {
	struct cell_1 thread_return0;
	uint8_t* _0 = NULL;
	thread_return0 = (struct cell_1) {_0};
	
	int32_t err1;
	uint64_t _1 = tid;
	struct cell_1* _2 = &thread_return0;
	err1 = pthread_join(_1, _2);
	
	int32_t _3 = err1;
	int32_t _4 = 0;
	uint8_t _5 = _op_bang_equal_2(_3, _4);
	if (_5) {
		int32_t _6 = err1;
		int32_t _7 = einval();
		uint8_t _8 = _op_equal_equal_3(_6, _7);
		if (_8) {
			todo_1();
		} else {
			int32_t _9 = err1;
			int32_t _10 = esrch();
			uint8_t _11 = _op_equal_equal_3(_9, _10);
			if (_11) {
				todo_1();
			} else {
				todo_1();
			}
		}
	} else {
		(struct void_) {};
	}
	struct cell_1* _12 = &thread_return0;
	uint8_t* _13 = get(_12);
	uint8_t _14 = null__q_0(_13);
	return hard_assert(_14);
}
/* !=<int32> bool(a int32, b int32) */
uint8_t _op_bang_equal_2(int32_t a, int32_t b) {
	int32_t _0 = a;
	int32_t _1 = b;
	uint8_t _2 = _op_equal_equal_3(_0, _1);
	return !_2;
}
/* einval int32() */
int32_t einval(void) {
	return 22;
}
/* esrch int32() */
int32_t esrch(void) {
	return 3;
}
/* get<ptr<nat8>> ptr<nat8>(c cell<ptr<nat8>>) */
uint8_t* get(struct cell_1* c) {
	struct cell_1* _0 = c;
	return _0->value;
}
/* unmanaged-free<nat> void(p ptr<nat>) */
struct void_ unmanaged_free_0(uint64_t* p) {
	uint64_t* _0 = p;
	uint8_t* _1 = (uint8_t*) _0;
	return (free(_1), (struct void_) {});
}
/* unmanaged-free<by-val<thread-args>> void(p ptr<thread-args>) */
struct void_ unmanaged_free_1(struct thread_args* p) {
	struct thread_args* _0 = p;
	uint8_t* _1 = (uint8_t*) _0;
	return (free(_1), (struct void_) {});
}
/* must-be-resolved<int32> result<int32, exception>(f fut<int32>) */
struct result_0 must_be_resolved(struct fut_0* f) {
	struct fut_0* _0 = f;
	struct fut_state_0 _1 = _0->state;
	switch (_1.kind) {
		case 0: {
			return hard_unreachable();
		}
		case 1: {
			struct fut_state_resolved_0 r0 = _1.as1;
			
			struct fut_state_resolved_0 _2 = r0;
			int32_t _3 = _2.value;
			struct ok_0 _4 = (struct ok_0) {_3};
			return (struct result_0) {0, .as0 = _4};
		}
		case 2: {
			struct exception e1 = _1.as2;
			
			struct exception _5 = e1;
			struct err_0 _6 = (struct err_0) {_5};
			return (struct result_0) {1, .as1 = _6};
		}
		default:
			return (assert(0),(struct result_0) {0});
	}
}
/* hard-unreachable<result<?t, exception>> result<int32, exception>() */
struct result_0 hard_unreachable(void) {
	return (assert(0),(struct result_0) {0});
}
/* main fut<int32>(args arr<arr<char>>) */
struct fut_0* main_0(struct ctx* ctx, struct arr_1 args) {
	struct my_record* r0;
	struct my_record* temp0;
	struct ctx* _0 = ctx;
	uint64_t _1 = sizeof(struct my_record);
	uint8_t* _2 = alloc(_0, _1);
	temp0 = (struct my_record*) _2;
	
	struct my_record* _3 = temp0;
	struct arr_0 _4 = (struct arr_0) {1, constantarr_0_15};
	struct arr_0 _5 = (struct arr_0) {1, constantarr_0_16};
	struct my_record _6 = (struct my_record) {_4, _5};
	*_3 = _6;
	r0 = temp0;
	
	struct ctx* _7 = ctx;
	struct my_record* _8 = r0;
	foo(_7, _8);
	struct my_record* _9 = r0;
	struct arr_0 _10 = _9->a;
	print(_10);
	struct my_record* _11 = r0;
	struct arr_0 _12 = _11->b;
	print(_12);
	struct ctx* _13 = ctx;
	int32_t _14 = 0;
	return resolved_1(_13, _14);
}
/* foo void(r my-record) */
struct void_ foo(struct ctx* ctx, struct my_record* r) {
	struct my_record* _0 = r;
	struct arr_0 _1 = _0->a;
	print(_1);
	struct my_record* _2 = r;
	struct arr_0 _3 = _2->b;
	return print(_3);
}
/* resolved<int32> fut<int32>(value int32) */
struct fut_0* resolved_1(struct ctx* ctx, int32_t value) {
	struct fut_0* temp0;
	struct ctx* _0 = ctx;
	uint64_t _1 = sizeof(struct fut_0);
	uint8_t* _2 = alloc(_0, _1);
	temp0 = (struct fut_0*) _2;
	
	struct fut_0* _3 = temp0;
	struct lock _4 = new_lock();
	int32_t _5 = value;
	struct fut_state_resolved_0 _6 = (struct fut_state_resolved_0) {_5};
	struct fut_state_0 _7 = (struct fut_state_0) {1, .as1 = _6};
	struct fut_0 _8 = (struct fut_0) {_4, _7};
	*_3 = _8;
	return temp0;
}
/* main (generated) (generated) */
int32_t main(int32_t argc, char** argv) {
	int32_t _0 = argc;
	char** _1 = argv;
	fun_ptr2 _2 = main_0;
	return rt_main(_0, _1, _2);
}
