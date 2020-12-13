#include <assert.h>
#include <errno.h>
#include <stdatomic.h>
#include <stddef.h>
#include <stdint.h>
typedef uint8_t* (*fun_ptr1)(uint8_t*);
struct ctx {
	uint8_t* gctx_ptr;
	uint64_t island_id;
	uint64_t exclusion;
	uint8_t* gc_ctx_ptr;
	uint8_t* exception_ctx_ptr;
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
	uint8_t __mustBeNonEmpty;
};
struct equal {
	uint8_t __mustBeNonEmpty;
};
struct greater {
	uint8_t __mustBeNonEmpty;
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
	uint8_t __mustBeNonEmpty;
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
struct task {
	uint64_t exclusion;
	uint64_t fun;
};
struct mut_bag;
struct mut_bag_node;
struct some_2 {
	struct mut_bag_node* value;
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
struct thread_local_stuff {
	struct exception_ctx* exception_ctx;
};
struct arr_3 {
	uint64_t size;
	char** data;
};
struct fut_1;
struct fut_state_callbacks_1;
struct fut_callback_node_1;
struct ok_1 {
	uint8_t value;
};
struct some_3 {
	struct fut_callback_node_1* value;
};
struct fut_state_resolved_1 {
	uint8_t value;
};
struct fun_ref0;
struct island_and_exclusion {
	uint64_t island;
	uint64_t exclusion;
};
struct fun_ref1 {
	struct island_and_exclusion island_and_exclusion;
	uint64_t fun;
};
struct then__lambda0 {
	struct fun_ref1 cb;
	struct fut_0* res;
};
struct forward_to__lambda0 {
	struct fut_0* to;
};
struct call_ref_0__lambda0 {
	struct fun_ref1 f;
	uint8_t p0;
	struct fut_0* res;
};
struct call_ref_0__lambda0__lambda0 {
	struct fun_ref1 f;
	uint8_t p0;
	struct fut_0* res;
};
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
struct some_4 {
	uint8_t* value;
};
struct map__lambda0 {
	uint64_t mapper;
	struct arr_3 a;
};
struct thread_args {
	uint64_t thread_id;
	struct global_ctx* gctx;
};
struct cell_0 {
	uint64_t value;
};
struct chosen_task;
struct some_5 {
	struct task value;
};
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
	int kind;
	union {
		struct less as0;
		struct equal as1;
		struct greater as2;
	};
};
struct fut_state_0;
struct result_0 {
	int kind;
	union {
		struct ok_0 as0;
		struct err_0 as1;
	};
};
struct opt_0 {
	int kind;
	union {
		struct none as0;
		struct some_0 as1;
	};
};
struct opt_1 {
	int kind;
	union {
		struct none as0;
		struct some_1 as1;
	};
};
struct opt_2 {
	int kind;
	union {
		struct none as0;
		struct some_2 as1;
	};
};
struct fut_state_1;
struct result_1 {
	int kind;
	union {
		struct ok_1 as0;
		struct err_0 as1;
	};
};
struct opt_3 {
	int kind;
	union {
		struct none as0;
		struct some_3 as1;
	};
};
struct opt_4 {
	int kind;
	union {
		struct none as0;
		struct some_4 as1;
	};
};
struct opt_5 {
	int kind;
	union {
		struct none as0;
		struct some_5 as1;
	};
};
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
	uint64_t cb;
	struct opt_0 next_node;
};
struct global_ctx;
struct island;
struct gc {
	struct lock lk;
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
struct mut_bag {
	struct opt_2 head;
};
struct mut_bag_node {
	struct task value;
	struct opt_2 next_node;
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
struct fut_1;
struct fut_state_callbacks_1 {
	struct opt_3 head;
};
struct fut_callback_node_1 {
	uint64_t cb;
	struct opt_3 next_node;
};
struct fun_ref0 {
	struct island_and_exclusion island_and_exclusion;
	uint64_t fun;
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
struct task_and_nodes {
	struct task task;
	struct opt_2 nodes;
};
struct some_8 {
	struct task_and_nodes value;
};
struct fut_state_0 {
	int kind;
	union {
		struct fut_state_callbacks_0 as0;
		struct fut_state_resolved_0 as1;
		struct exception as2;
	};
};
struct fut_state_1 {
	int kind;
	union {
		struct fut_state_callbacks_1 as0;
		struct fut_state_resolved_1 as1;
		struct exception as2;
	};
};
struct result_2 {
	int kind;
	union {
		struct ok_2 as0;
		struct err_1 as1;
	};
};
struct opt_6 {
	int kind;
	union {
		struct none as0;
		struct some_6 as1;
	};
};
struct opt_7 {
	int kind;
	union {
		struct none as0;
		struct some_7 as1;
	};
};
struct opt_8 {
	int kind;
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
	uint64_t exception_handler;
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

char constantarr_0_0[17];
char constantarr_0_1[4];
char constantarr_0_2[20];
char constantarr_0_3[1];
char constantarr_0_4[17];
char constantarr_0_5[38];
char constantarr_0_6[33];
char constantarr_0_7[13];
char constantarr_0_8[13];
char constantarr_0_9[39];
char constantarr_0_10[11];
char constantarr_0_11[13];
char constantarr_0_12[1];
char constantarr_0_13[1];
char constantarr_0_0[17] = "Assertion failed!";
char constantarr_0_1[4] = "TODO";
char constantarr_0_2[20] = "uncaught exception: ";
char constantarr_0_3[1] = "\n";
char constantarr_0_4[17] = "<<empty message>>";
char constantarr_0_5[38] = "Couldn't acquire lock after 1000 tries";
char constantarr_0_6[33] = "resolving an already-resolved fut";
char constantarr_0_7[13] = "assert failed";
char constantarr_0_8[13] = "forbid failed";
char constantarr_0_9[39] = "Did not find the element in the mut-arr";
char constantarr_0_10[11] = "unreachable";
char constantarr_0_11[13] = "main failed: ";
char constantarr_0_12[1] = "a";
char constantarr_0_13[1] = "b";
uint8_t mark(struct mark_ctx* ctx, uint8_t* ptr_any, uint64_t size_bytes);
uint64_t words_of_bytes(uint64_t size_bytes);
uint64_t round_up_to_multiple_of_8(uint64_t n);
uint8_t hard_assert(uint8_t condition);
uint8_t _op_equal_equal_0(uint64_t a, uint64_t b);
struct comparison compare_5(uint64_t a, uint64_t b);
uint64_t _op_minus_0(uint64_t* a, uint64_t* b);
uint8_t _op_less(uint64_t a, uint64_t b);
uint8_t _op_less_equal(uint64_t a, uint64_t b);
uint8_t mark_range_recur(uint8_t* p, uint64_t size);
uint8_t _op_bang_equal_0(uint64_t a, uint64_t b);
uint8_t* incr_0(uint8_t* p);
uint64_t noctx_decr(uint64_t n);
uint8_t hard_forbid(uint8_t condition);
int32_t rt_main(int32_t argc, char** argv, fun_ptr2 main_ptr);
uint8_t drop_0(struct arr_0 t);
struct arr_0 to_str(char* a);
struct arr_0 arr_from_begin_end(char* begin, char* end);
uint64_t _op_minus_1(char* a, char* b);
char* find_cstr_end(char* a);
char* find_char_in_cstr(char* a, char c);
uint8_t _op_equal_equal_1(char a, char b);
struct comparison compare_22(char a, char b);
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
uint8_t null__q_0(uint8_t* a);
struct mut_bag new_mut_bag(void);
uint8_t default_exception_handler(struct ctx* ctx, struct exception e);
uint8_t print_err_no_newline(struct arr_0 s);
uint8_t write_no_newline(int32_t fd, struct arr_0 a);
extern int64_t write(int32_t fd, uint8_t* buff, uint64_t n_bytes);
uint8_t _op_bang_equal_1(int64_t a, int64_t b);
uint8_t _op_equal_equal_2(int64_t a, int64_t b);
struct comparison compare_42(int64_t a, int64_t b);
uint8_t todo_1(void);
int32_t stderr_fd(void);
uint8_t print_err(struct arr_0 s);
uint8_t empty__q_0(struct arr_0 a);
struct global_ctx* get_gctx(struct ctx* ctx);
uint8_t new_island__lambda0(struct ctx* ctx, struct exception it);
struct gc new_gc(void);
extern void memset(uint8_t* begin, uint8_t value, uint64_t size);
struct thread_safe_counter new_thread_safe_counter_0(void);
struct thread_safe_counter new_thread_safe_counter_1(uint64_t init);
struct fut_0* do_main(struct global_ctx* gctx, struct island* island, int32_t argc, char** argv, fun_ptr2 main_ptr);
struct exception_ctx new_exception_ctx(void);
struct ctx new_ctx(struct global_ctx* gctx, struct thread_local_stuff* tls, struct island* island, uint64_t exclusion);
struct gc_ctx* get_gc_ctx_0(struct gc* gc);
uint8_t acquire_lock(struct lock* a);
uint8_t acquire_lock_recur(struct lock* a, uint64_t n_tries);
uint8_t try_acquire_lock(struct lock* a);
uint8_t try_set(struct _atomic_bool* a);
uint8_t try_change(struct _atomic_bool* a, uint8_t old_value);
uint8_t yield_thread(void);
extern int32_t pthread_yield(void);
uint8_t _op_equal_equal_3(int32_t a, int32_t b);
struct comparison compare_65(int32_t a, int32_t b);
uint64_t noctx_incr(uint64_t n);
uint64_t max_nat(void);
uint64_t wrap_incr(uint64_t a);
uint8_t release_lock(struct lock* l);
uint8_t must_unset(struct _atomic_bool* a);
uint8_t try_unset(struct _atomic_bool* a);
struct fut_0* add_first_task(struct ctx* ctx, struct arr_3 all_args, fun_ptr2 main_ptr);
struct fut_0* then2(struct ctx* ctx, struct fut_1* f, struct fun_ref0 cb);
struct fut_0* then(struct ctx* ctx, struct fut_1* f, struct fun_ref1 cb);
struct fut_0* new_unresolved_fut(struct ctx* ctx);
uint8_t then_void_0(struct ctx* ctx, struct fut_1* f, uint64_t cb);
uint8_t call_0(struct ctx* ctx, uint64_t a, struct result_1 p0);
uint8_t call_w_ctx_78(uint64_t a, struct ctx* ctx, struct result_1 p0);
uint8_t forward_to(struct ctx* ctx, struct fut_0* from, struct fut_0* to);
uint8_t then_void_1(struct ctx* ctx, struct fut_0* f, uint64_t cb);
uint8_t call_1(struct ctx* ctx, uint64_t a, struct result_0 p0);
uint8_t call_w_ctx_82(uint64_t a, struct ctx* ctx, struct result_0 p0);
uint8_t resolve_or_reject(struct ctx* ctx, struct fut_0* f, struct result_0 result);
uint8_t resolve_or_reject_recur(struct ctx* ctx, struct opt_0 node, struct result_0 value);
uint8_t drop_1(uint8_t t);
uint8_t forward_to__lambda0(struct ctx* ctx, struct forward_to__lambda0* _closure, struct result_0 it);
struct fut_0* call_ref_0(struct ctx* ctx, struct fun_ref1 f, uint8_t p0);
struct island* get_island(struct ctx* ctx, uint64_t island_id);
struct island* at_0(struct ctx* ctx, struct arr_2 a, uint64_t index);
uint8_t assert_0(struct ctx* ctx, uint8_t condition);
uint8_t assert_1(struct ctx* ctx, uint8_t condition, struct arr_0 message);
uint8_t fail(struct ctx* ctx, struct arr_0 reason);
uint8_t throw(struct ctx* ctx, struct exception e);
struct exception_ctx* get_exception_ctx(struct ctx* ctx);
uint8_t null__q_1(struct jmp_buf_tag* a);
extern void longjmp(struct jmp_buf_tag* env, int32_t val);
int32_t number_to_throw(struct ctx* ctx);
struct island* noctx_at_0(struct arr_2 a, uint64_t index);
uint8_t add_task(struct ctx* ctx, struct island* a, struct task t);
struct mut_bag_node* new_mut_bag_node(struct ctx* ctx, struct task value);
uint8_t add(struct mut_bag* bag, struct mut_bag_node* node);
struct mut_bag* tasks(struct island* a);
uint8_t broadcast(struct condition* c);
uint8_t catch(struct ctx* ctx, uint64_t try, uint64_t catcher);
uint8_t catch_with_exception_ctx(struct ctx* ctx, struct exception_ctx* ec, uint64_t try, uint64_t catcher);
struct bytes64 zero_0(void);
struct bytes32 zero_1(void);
struct bytes16 zero_2(void);
struct bytes128 zero_3(void);
extern int32_t setjmp(struct jmp_buf_tag* env);
uint8_t call_2(struct ctx* ctx, uint64_t a);
uint8_t call_w_ctx_112(uint64_t a, struct ctx* ctx);
uint8_t call_3(struct ctx* ctx, uint64_t a, struct exception p0);
uint8_t call_w_ctx_114(uint64_t a, struct ctx* ctx, struct exception p0);
struct fut_0* call_4(struct ctx* ctx, uint64_t a, uint8_t p0);
struct fut_0* call_w_ctx_116(uint64_t a, struct ctx* ctx, uint8_t p0);
uint8_t call_ref_0__lambda0__lambda0(struct ctx* ctx, struct call_ref_0__lambda0__lambda0* _closure);
uint8_t reject(struct ctx* ctx, struct fut_0* f, struct exception e);
uint8_t call_ref_0__lambda0__lambda1(struct ctx* ctx, struct call_ref_0__lambda0__lambda1* _closure, struct exception it);
uint8_t call_ref_0__lambda0(struct ctx* ctx, struct call_ref_0__lambda0* _closure);
uint8_t then__lambda0(struct ctx* ctx, struct then__lambda0* _closure, struct result_1 result);
struct fut_0* call_ref_1(struct ctx* ctx, struct fun_ref0 f);
struct fut_0* call_5(struct ctx* ctx, uint64_t a);
struct fut_0* call_w_ctx_124(uint64_t a, struct ctx* ctx);
uint8_t call_ref_1__lambda0__lambda0(struct ctx* ctx, struct call_ref_1__lambda0__lambda0* _closure);
uint8_t call_ref_1__lambda0__lambda1(struct ctx* ctx, struct call_ref_1__lambda0__lambda1* _closure, struct exception it);
uint8_t call_ref_1__lambda0(struct ctx* ctx, struct call_ref_1__lambda0* _closure);
struct fut_0* then2__lambda0(struct ctx* ctx, struct then2__lambda0* _closure, uint8_t ignore);
struct island_and_exclusion cur_island_and_exclusion(struct ctx* ctx);
struct fut_1* delay(struct ctx* ctx);
struct fut_1* resolved_0(struct ctx* ctx, uint8_t value);
struct arr_3 tail(struct ctx* ctx, struct arr_3 a);
uint8_t forbid_0(struct ctx* ctx, uint8_t condition);
uint8_t forbid_1(struct ctx* ctx, uint8_t condition, struct arr_0 message);
uint8_t empty__q_1(struct arr_3 a);
struct arr_3 slice_starting_at(struct ctx* ctx, struct arr_3 a, uint64_t begin);
struct arr_3 slice(struct ctx* ctx, struct arr_3 a, uint64_t begin, uint64_t size);
uint64_t _op_plus(struct ctx* ctx, uint64_t a, uint64_t b);
uint8_t _op_greater_equal(uint64_t a, uint64_t b);
uint64_t _op_minus_2(struct ctx* ctx, uint64_t a, uint64_t b);
struct arr_1 map(struct ctx* ctx, struct arr_3 a, uint64_t mapper);
struct arr_1 make_arr(struct ctx* ctx, uint64_t size, uint64_t f);
struct arr_1 freeze(struct mut_arr_1* a);
struct arr_1 unsafe_as_arr(struct mut_arr_1* a);
struct mut_arr_1* make_mut_arr(struct ctx* ctx, uint64_t size, uint64_t f);
struct mut_arr_1* new_uninitialized_mut_arr(struct ctx* ctx, uint64_t size);
struct arr_0* uninitialized_data(struct ctx* ctx, uint64_t size);
uint8_t* alloc(struct ctx* ctx, uint64_t size);
uint8_t* gc_alloc(struct ctx* ctx, struct gc* gc, uint64_t size);
struct opt_4 try_gc_alloc(struct gc* gc, uint64_t size_bytes);
uint8_t validate_gc(struct gc* gc);
uint8_t ptr_less_eq__q_0(uint8_t* a, uint8_t* b);
uint8_t ptr_less_eq__q_1(uint64_t* a, uint64_t* b);
uint64_t _op_minus_3(uint8_t* a, uint8_t* b);
uint8_t range_free__q(uint8_t* mark, uint64_t size);
uint64_t* incr_2(uint64_t* p);
uint8_t* todo_2(void);
struct gc* get_gc(struct ctx* ctx);
struct gc_ctx* get_gc_ctx_1(struct ctx* ctx);
uint8_t make_mut_arr_worker(struct ctx* ctx, struct mut_arr_1* m, uint64_t i, uint64_t f);
uint8_t set_at(struct ctx* ctx, struct mut_arr_1* a, uint64_t index, struct arr_0 value);
uint8_t noctx_set_at_0(struct mut_arr_1* a, uint64_t index, struct arr_0 value);
struct arr_0 call_6(struct ctx* ctx, uint64_t a, uint64_t p0);
struct arr_0 call_w_ctx_164(uint64_t a, struct ctx* ctx, uint64_t p0);
uint64_t incr_3(struct ctx* ctx, uint64_t n);
struct arr_0 call_7(struct ctx* ctx, uint64_t a, char* p0);
struct arr_0 call_w_ctx_167(uint64_t a, struct ctx* ctx, char* p0);
char* at_1(struct ctx* ctx, struct arr_3 a, uint64_t index);
char* noctx_at_1(struct arr_3 a, uint64_t index);
struct arr_0 map__lambda0(struct ctx* ctx, struct map__lambda0* _closure, uint64_t i);
struct arr_0 add_first_task__lambda0__lambda0(struct ctx* ctx, char* it);
struct fut_0* add_first_task__lambda0(struct ctx* ctx, struct add_first_task__lambda0* _closure);
struct fut_0* do_main__lambda0(struct ctx* ctx, struct arr_3 all_args, fun_ptr2 main_ptr);
struct fut_0* call_w_ctx_174(uint64_t a, struct ctx* ctx, struct arr_3 p0, fun_ptr2 p1);
uint8_t run_threads(uint64_t n_threads, struct global_ctx* gctx);
struct thread_args* unmanaged_alloc_elements_1(uint64_t size_elements);
uint8_t start_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads, struct thread_args* thread_args_begin, struct global_ctx* gctx);
extern int32_t pthread_create(struct cell_0* thread, uint8_t* attr, fun_ptr1 start_routine, uint8_t* arg);
struct cell_0* as_cell(uint64_t* p);
uint8_t* thread_fun(uint8_t* args_ptr);
uint8_t thread_function(uint64_t thread_id, struct global_ctx* gctx);
uint8_t thread_function_recur(uint64_t thread_id, struct global_ctx* gctx, struct thread_local_stuff* tls);
uint8_t assert_islands_are_shut_down(uint64_t i, struct arr_2 islands);
uint8_t empty__q_2(struct mut_bag* m);
uint8_t empty__q_3(struct opt_2 a);
uint8_t _op_greater(uint64_t a, uint64_t b);
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
uint8_t push_capacity_must_be_sufficient(struct mut_arr_0* a, uint64_t value);
uint8_t noctx_set_at_1(struct mut_arr_0* a, uint64_t index, uint64_t value);
uint8_t empty__q_4(struct opt_7 a);
uint8_t do_task(struct global_ctx* gctx, struct thread_local_stuff* tls, struct chosen_task chosen_task);
uint8_t run_garbage_collection(struct gc* gc, struct island_gc_root gc_root);
uint8_t noctx_must_remove_unordered(struct mut_arr_0* a, uint64_t value);
uint8_t noctx_must_remove_unordered_recur(struct mut_arr_0* a, uint64_t index, uint64_t value);
uint64_t noctx_at_3(struct mut_arr_0* a, uint64_t index);
uint8_t drop_2(uint64_t t);
uint64_t noctx_remove_unordered_at_index(struct mut_arr_0* a, uint64_t index);
uint64_t noctx_last(struct mut_arr_0* a);
uint8_t empty__q_5(struct mut_arr_0* a);
uint8_t return_ctx(struct ctx* c);
uint8_t return_gc_ctx(struct gc_ctx* gc_ctx);
uint8_t wait_on(struct condition* c, uint64_t last_checked);
int32_t eagain(void);
uint8_t join_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads);
uint8_t join_one_thread(uint64_t tid);
extern int32_t pthread_join(uint64_t thread, struct cell_1* thread_return);
uint8_t _op_bang_equal_2(int32_t a, int32_t b);
int32_t einval(void);
int32_t esrch(void);
uint8_t* get(struct cell_1* c);
uint8_t unmanaged_free_0(uint64_t* p);
extern void free(uint8_t* p);
uint8_t unmanaged_free_1(struct thread_args* p);
struct result_0 must_be_resolved(struct fut_0* f);
struct result_0 hard_unreachable(void);
struct fut_0* main_0(struct ctx* ctx, struct arr_1 args);
uint8_t foo(struct ctx* ctx, struct my_record* r);
uint8_t print(struct arr_0 a);
uint8_t print_no_newline(struct arr_0 a);
int32_t stdout_fd(void);
struct fut_0* resolved_1(struct ctx* ctx, int32_t value);
int32_t main(int32_t argc, char** argv);
/* mark bool(ctx mark-ctx, ptr-any ptr<nat8>, size-bytes nat) */
uint8_t mark(struct mark_ctx* ctx, uint8_t* ptr_any, uint64_t size_bytes) {
	uint64_t size0;
	uint64_t* ptr1;
	uint64_t index2;
	uint8_t gc_memory__q3;
	size0 = words_of_bytes(size_bytes);
	ptr1 = (uint64_t*) ptr_any;
	hard_assert(_op_equal_equal_0(((uint64_t) ptr1 & 7u), 0u));
	index2 = _op_minus_0(ptr1, ctx->memory_start);
	gc_memory__q3 = _op_less(index2, ctx->memory_size_words);
	if (gc_memory__q3) {
		hard_assert(_op_less_equal((index2 + size0), ctx->memory_size_words));
		mark_range_recur((ctx->marks + index2), size0);
	} else {
		0;
	}
	return gc_memory__q3;
}
/* words-of-bytes nat(size-bytes nat) */
uint64_t words_of_bytes(uint64_t size_bytes) {
	return (round_up_to_multiple_of_8(size_bytes) / 8u);
}
/* round-up-to-multiple-of-8 nat(n nat) */
uint64_t round_up_to_multiple_of_8(uint64_t n) {
	return ((n + 7u) & (~(7u)));
}
/* hard-assert void(condition bool) */
uint8_t hard_assert(uint8_t condition) {
	if (!condition) {
		return (assert(0),0);
	} else {
		return 0;
	}
}
/* ==<nat> bool(a nat, b nat) */
uint8_t _op_equal_equal_0(uint64_t a, uint64_t b) {
	struct comparison temp0;
	temp0 = compare_5(a, b);
	switch (temp0.kind) {
		case 0:
			return 0;
		case 1:
			return 1;
		case 2:
			return 0;
		default:
			return (assert(0),0);
	}
}
/* compare<nat-64> (generated) (generated) */
struct comparison compare_5(uint64_t a, uint64_t b) {
	if ((a < b)) {
		return (struct comparison) {0, .as0 = (struct less) {0}};
	} else {
		if ((b < a)) {
			return (struct comparison) {2, .as2 = (struct greater) {0}};
		} else {
			return (struct comparison) {1, .as1 = (struct equal) {0}};
		}
	}
}
/* -<nat> nat(a ptr<nat>, b ptr<nat>) */
uint64_t _op_minus_0(uint64_t* a, uint64_t* b) {
	return (((uint64_t) a - (uint64_t) b) / sizeof(uint64_t));
}
/* <<nat> bool(a nat, b nat) */
uint8_t _op_less(uint64_t a, uint64_t b) {
	struct comparison temp0;
	temp0 = compare_5(a, b);
	switch (temp0.kind) {
		case 0:
			return 1;
		case 1:
			return 0;
		case 2:
			return 0;
		default:
			return (assert(0),0);
	}
}
/* <=<nat> bool(a nat, b nat) */
uint8_t _op_less_equal(uint64_t a, uint64_t b) {
	return !_op_less(b, a);
}
/* mark-range-recur void(p ptr<bool>, size nat) */
uint8_t mark_range_recur(uint8_t* p, uint64_t size) {
	uint8_t* _tailCallp;
	uint64_t _tailCallsize;
	top:
	(*(p) = 1, 0);
	if (_op_bang_equal_0(size, 0u)) {
		_tailCallp = incr_0(p);
		_tailCallsize = noctx_decr(size);
		p = _tailCallp;
		size = _tailCallsize;
		goto top;
	} else {
		return 0;
	}
}
/* !=<nat> bool(a nat, b nat) */
uint8_t _op_bang_equal_0(uint64_t a, uint64_t b) {
	return !_op_equal_equal_0(a, b);
}
/* incr<bool> ptr<bool>(p ptr<bool>) */
uint8_t* incr_0(uint8_t* p) {
	return (p + 1u);
}
/* noctx-decr nat(n nat) */
uint64_t noctx_decr(uint64_t n) {
	hard_forbid(_op_equal_equal_0(n, 0u));
	return (n - 1u);
}
/* hard-forbid void(condition bool) */
uint8_t hard_forbid(uint8_t condition) {
	return hard_assert(!condition);
}
/* rt-main int32(argc int32, argv ptr<ptr<char>>, main-ptr fun-ptr2<fut<int32>, ctx, arr<arr<char>>>) */
int32_t rt_main(int32_t argc, char** argv, fun_ptr2 main_ptr) {
	struct global_ctx gctx_by_val0;
	struct global_ctx* gctx1;
	struct island island_by_val2;
	struct island* island3;
	struct fut_0* main_fut4;
	struct result_0 temp0;
	struct ok_0 o5;
	struct err_0 e6;
	drop_0(to_str((*(argv))));
	gctx_by_val0 = (struct global_ctx) {new_lock(), empty_arr(), 1u, new_condition(), 0, 0};
	gctx1 = (&(gctx_by_val0));
	island_by_val2 = new_island(gctx1, 0u, 1u);
	island3 = (&(island_by_val2));
	(gctx1->islands = (struct arr_2) {1u, (&(island3))}, 0);
	main_fut4 = do_main(gctx1, island3, argc, argv, main_ptr);
	run_threads(1u, gctx1);
	if (gctx1->any_unhandled_exceptions__q) {
		return 1;
	} else {
		temp0 = must_be_resolved(main_fut4);
		switch (temp0.kind) {
			case 0:
				o5 = temp0.as0;
				return o5.value;
			case 1:
				e6 = temp0.as1;
				print_err_no_newline((struct arr_0) {13, constantarr_0_11});
				print_err(e6.value.message);
				return 1;
			default:
				return (assert(0),0);
		}
	}
}
/* drop<arr<char>> void(t arr<char>) */
uint8_t drop_0(struct arr_0 t) {
	return 0;
}
/* to-str arr<char>(a ptr<char>) */
struct arr_0 to_str(char* a) {
	return arr_from_begin_end(a, find_cstr_end(a));
}
/* arr-from-begin-end<char> arr<char>(begin ptr<char>, end ptr<char>) */
struct arr_0 arr_from_begin_end(char* begin, char* end) {
	return (struct arr_0) {_op_minus_1(end, begin), begin};
}
/* -<?t> nat(a ptr<char>, b ptr<char>) */
uint64_t _op_minus_1(char* a, char* b) {
	return (((uint64_t) a - (uint64_t) b) / sizeof(char));
}
/* find-cstr-end ptr<char>(a ptr<char>) */
char* find_cstr_end(char* a) {
	return find_char_in_cstr(a, 0u);
}
/* find-char-in-cstr ptr<char>(a ptr<char>, c char) */
char* find_char_in_cstr(char* a, char c) {
	char* _tailCalla;
	char _tailCallc;
	top:
	if (_op_equal_equal_1((*(a)), c)) {
		return a;
	} else {
		if (_op_equal_equal_1((*(a)), 0u)) {
			return todo_0();
		} else {
			_tailCalla = incr_1(a);
			_tailCallc = c;
			a = _tailCalla;
			c = _tailCallc;
			goto top;
		}
	}
}
/* ==<char> bool(a char, b char) */
uint8_t _op_equal_equal_1(char a, char b) {
	struct comparison temp0;
	temp0 = compare_22(a, b);
	switch (temp0.kind) {
		case 0:
			return 0;
		case 1:
			return 1;
		case 2:
			return 0;
		default:
			return (assert(0),0);
	}
}
/* compare<char> (generated) (generated) */
struct comparison compare_22(char a, char b) {
	if ((a < b)) {
		return (struct comparison) {0, .as0 = (struct less) {0}};
	} else {
		if ((b < a)) {
			return (struct comparison) {2, .as2 = (struct greater) {0}};
		} else {
			return (struct comparison) {1, .as1 = (struct equal) {0}};
		}
	}
}
/* todo<ptr<char>> ptr<char>() */
char* todo_0(void) {
	return (assert(0),NULL);
}
/* incr<char> ptr<char>(p ptr<char>) */
char* incr_1(char* p) {
	return (p + 1u);
}
/* new-lock lock() */
struct lock new_lock(void) {
	return (struct lock) {new_atomic_bool()};
}
/* new-atomic-bool atomic-bool() */
struct _atomic_bool new_atomic_bool(void) {
	return (struct _atomic_bool) {0};
}
/* empty-arr<island> arr<island>() */
struct arr_2 empty_arr(void) {
	return (struct arr_2) {0u, NULL};
}
/* new-condition condition() */
struct condition new_condition(void) {
	return (struct condition) {new_lock(), 0u};
}
/* new-island island(gctx global-ctx, id nat, max-threads nat) */
struct island new_island(struct global_ctx* gctx, uint64_t id, uint64_t max_threads) {
	struct mut_arr_0 exclusions0;
	struct island_gc_root gc_root1;
	exclusions0 = new_mut_arr_by_val_with_capacity_from_unmanaged_memory(max_threads);
	gc_root1 = (struct island_gc_root) {new_mut_bag(), 0u};
	return (struct island) {gctx, id, new_gc(), gc_root1, new_lock(), exclusions0, 0u, new_thread_safe_counter_0()};
}
/* new-mut-arr-by-val-with-capacity-from-unmanaged-memory<nat> mut-arr<nat>(capacity nat) */
struct mut_arr_0 new_mut_arr_by_val_with_capacity_from_unmanaged_memory(uint64_t capacity) {
	return (struct mut_arr_0) {0, 0u, capacity, unmanaged_alloc_elements_0(capacity)};
}
/* unmanaged-alloc-elements<?t> ptr<nat>(size-elements nat) */
uint64_t* unmanaged_alloc_elements_0(uint64_t size_elements) {
	uint8_t* bytes0;
	bytes0 = unmanaged_alloc_bytes((size_elements * sizeof(uint64_t)));
	return (uint64_t*) bytes0;
}
/* unmanaged-alloc-bytes ptr<nat8>(size nat) */
uint8_t* unmanaged_alloc_bytes(uint64_t size) {
	uint8_t* res0;
	res0 = malloc(size);
	hard_forbid(null__q_0(res0));
	return res0;
}
/* null?<nat8> bool(a ptr<nat8>) */
uint8_t null__q_0(uint8_t* a) {
	return _op_equal_equal_0((uint64_t) a, (uint64_t) NULL);
}
/* new-mut-bag<task> mut-bag<task>() */
struct mut_bag new_mut_bag(void) {
	return (struct mut_bag) {(struct opt_2) {0, .as0 = (struct none) {0}}};
}
/* default-exception-handler void(e exception) */
uint8_t default_exception_handler(struct ctx* ctx, struct exception e) {
	print_err_no_newline((struct arr_0) {20, constantarr_0_2});
	print_err((empty__q_0(e.message) ? (struct arr_0) {17, constantarr_0_4} : e.message));
	return (get_gctx(ctx)->any_unhandled_exceptions__q = 1, 0);
}
/* print-err-no-newline void(s arr<char>) */
uint8_t print_err_no_newline(struct arr_0 s) {
	return write_no_newline(stderr_fd(), s);
}
/* write-no-newline void(fd int32, a arr<char>) */
uint8_t write_no_newline(int32_t fd, struct arr_0 a) {
	int64_t res0;
	hard_assert(_op_equal_equal_0(sizeof(char), sizeof(uint8_t)));
	res0 = write(fd, (uint8_t*) a.data, a.size);
	if (_op_bang_equal_1(res0, a.size)) {
		return todo_1();
	} else {
		return 0;
	}
}
/* !=<int> bool(a int, b int) */
uint8_t _op_bang_equal_1(int64_t a, int64_t b) {
	return !_op_equal_equal_2(a, b);
}
/* ==<?t> bool(a int, b int) */
uint8_t _op_equal_equal_2(int64_t a, int64_t b) {
	struct comparison temp0;
	temp0 = compare_42(a, b);
	switch (temp0.kind) {
		case 0:
			return 0;
		case 1:
			return 1;
		case 2:
			return 0;
		default:
			return (assert(0),0);
	}
}
/* compare<int-64> (generated) (generated) */
struct comparison compare_42(int64_t a, int64_t b) {
	if ((a < b)) {
		return (struct comparison) {0, .as0 = (struct less) {0}};
	} else {
		if ((b < a)) {
			return (struct comparison) {2, .as2 = (struct greater) {0}};
		} else {
			return (struct comparison) {1, .as1 = (struct equal) {0}};
		}
	}
}
/* todo<void> void() */
uint8_t todo_1(void) {
	return (assert(0),0);
}
/* stderr-fd int32() */
int32_t stderr_fd(void) {
	return 2;
}
/* print-err void(s arr<char>) */
uint8_t print_err(struct arr_0 s) {
	print_err_no_newline(s);
	return print_err_no_newline((struct arr_0) {1, constantarr_0_3});
}
/* empty?<char> bool(a arr<char>) */
uint8_t empty__q_0(struct arr_0 a) {
	return _op_equal_equal_0(a.size, 0u);
}
/* get-gctx global-ctx() */
struct global_ctx* get_gctx(struct ctx* ctx) {
	return (struct global_ctx*) ctx->gctx_ptr;
}
/* new-island.lambda0 void(it exception) */
uint8_t new_island__lambda0(struct ctx* ctx, struct exception it) {
	return default_exception_handler(ctx, it);
}
/* new-gc gc() */
struct gc new_gc(void) {
	uint8_t* mark_begin0;
	uint8_t* mark_end1;
	uint64_t* data_begin2;
	uint64_t* data_end3;
	mark_begin0 = (uint8_t*) malloc(16777216u);
	mark_end1 = (mark_begin0 + 16777216u);
	data_begin2 = (uint64_t*) malloc((16777216u * sizeof(uint64_t)));
	data_end3 = (data_begin2 + 16777216u);
	(memset((uint8_t*) mark_begin0, 0u, 16777216u), 0);
	return (struct gc) {new_lock(), (struct opt_1) {0, .as0 = (struct none) {0}}, 0, 16777216u, mark_begin0, mark_begin0, mark_end1, data_begin2, data_begin2, data_end3};
}
/* new-thread-safe-counter thread-safe-counter() */
struct thread_safe_counter new_thread_safe_counter_0(void) {
	return new_thread_safe_counter_1(0u);
}
/* new-thread-safe-counter thread-safe-counter(init nat) */
struct thread_safe_counter new_thread_safe_counter_1(uint64_t init) {
	return (struct thread_safe_counter) {new_lock(), init};
}
/* do-main fut<int32>(gctx global-ctx, island island, argc int32, argv ptr<ptr<char>>, main-ptr fun-ptr2<fut<int32>, ctx, arr<arr<char>>>) */
struct fut_0* do_main(struct global_ctx* gctx, struct island* island, int32_t argc, char** argv, fun_ptr2 main_ptr) {
	struct exception_ctx ectx0;
	struct thread_local_stuff tls1;
	struct ctx ctx_by_val2;
	struct ctx* ctx3;
	uint64_t add4;
	struct arr_3 all_args5;
	ectx0 = new_exception_ctx();
	tls1 = (struct thread_local_stuff) {(&(ectx0))};
	ctx_by_val2 = new_ctx(gctx, (&(tls1)), island, 0u);
	ctx3 = (&(ctx_by_val2));
	add4 = 0u;
	all_args5 = (struct arr_3) {argc, argv};
	return call_w_ctx_174(add4, ctx3, all_args5, main_ptr);
}
/* new-exception-ctx exception-ctx() */
struct exception_ctx new_exception_ctx(void) {
	return (struct exception_ctx) {NULL, (struct exception) {(struct arr_0) {0u, NULL}}};
}
/* new-ctx ctx(gctx global-ctx, tls thread-local-stuff, island island, exclusion nat) */
struct ctx new_ctx(struct global_ctx* gctx, struct thread_local_stuff* tls, struct island* island, uint64_t exclusion) {
	return (struct ctx) {(uint8_t*) gctx, island->id, exclusion, (uint8_t*) get_gc_ctx_0((&(island->gc))), (uint8_t*) tls->exception_ctx};
}
/* get-gc-ctx gc-ctx(gc gc) */
struct gc_ctx* get_gc_ctx_0(struct gc* gc) {
	struct gc_ctx* res3;
	struct opt_1 temp0;
	struct gc_ctx* c0;
	struct some_1 s1;
	struct gc_ctx* c2;
	acquire_lock((&(gc->lk)));
	res3 = (temp0 = gc->context_head, temp0.kind == 0 ? (c0 = (struct gc_ctx*) malloc(sizeof(struct gc_ctx)), (((c0->gc = gc, 0), (c0->next_ctx = (struct opt_1) {0, .as0 = (struct none) {0}}, 0)), c0)) : temp0.kind == 1 ? (s1 = temp0.as1, (c2 = s1.value, (((gc->context_head = c2->next_ctx, 0), (c2->next_ctx = (struct opt_1) {0, .as0 = (struct none) {0}}, 0)), c2))) : (assert(0),NULL));
	release_lock((&(gc->lk)));
	return res3;
}
/* acquire-lock void(a lock) */
uint8_t acquire_lock(struct lock* a) {
	return acquire_lock_recur(a, 0u);
}
/* acquire-lock-recur void(a lock, n-tries nat) */
uint8_t acquire_lock_recur(struct lock* a, uint64_t n_tries) {
	struct lock* _tailCalla;
	uint64_t _tailCalln_tries;
	top:
	if (!try_acquire_lock(a)) {
		if (_op_equal_equal_0(n_tries, 1000u)) {
			return (assert(0),0);
		} else {
			yield_thread();
			_tailCalla = a;
			_tailCalln_tries = noctx_incr(n_tries);
			a = _tailCalla;
			n_tries = _tailCalln_tries;
			goto top;
		}
	} else {
		return 0;
	}
}
/* try-acquire-lock bool(a lock) */
uint8_t try_acquire_lock(struct lock* a) {
	return try_set((&(a->is_locked)));
}
/* try-set bool(a atomic-bool) */
uint8_t try_set(struct _atomic_bool* a) {
	return try_change(a, 0);
}
/* try-change bool(a atomic-bool, old-value bool) */
uint8_t try_change(struct _atomic_bool* a, uint8_t old_value) {
	return atomic_compare_exchange_strong((&(a->value)), (&(old_value)), !old_value);
}
/* yield-thread void() */
uint8_t yield_thread(void) {
	int32_t err0;
	err0 = pthread_yield();
	return hard_assert(_op_equal_equal_3(err0, 0));
}
/* ==<int32> bool(a int32, b int32) */
uint8_t _op_equal_equal_3(int32_t a, int32_t b) {
	struct comparison temp0;
	temp0 = compare_65(a, b);
	switch (temp0.kind) {
		case 0:
			return 0;
		case 1:
			return 1;
		case 2:
			return 0;
		default:
			return (assert(0),0);
	}
}
/* compare<int-32> (generated) (generated) */
struct comparison compare_65(int32_t a, int32_t b) {
	if ((a < b)) {
		return (struct comparison) {0, .as0 = (struct less) {0}};
	} else {
		if ((b < a)) {
			return (struct comparison) {2, .as2 = (struct greater) {0}};
		} else {
			return (struct comparison) {1, .as1 = (struct equal) {0}};
		}
	}
}
/* noctx-incr nat(n nat) */
uint64_t noctx_incr(uint64_t n) {
	hard_assert(_op_less(n, max_nat()));
	return wrap_incr(n);
}
/* max-nat nat() */
uint64_t max_nat(void) {
	return 18446744073709551615u;
}
/* wrap-incr nat(a nat) */
uint64_t wrap_incr(uint64_t a) {
	return (a + 1u);
}
/* release-lock void(l lock) */
uint8_t release_lock(struct lock* l) {
	return must_unset((&(l->is_locked)));
}
/* must-unset void(a atomic-bool) */
uint8_t must_unset(struct _atomic_bool* a) {
	uint8_t did_unset0;
	did_unset0 = try_unset(a);
	return hard_assert(did_unset0);
}
/* try-unset bool(a atomic-bool) */
uint8_t try_unset(struct _atomic_bool* a) {
	return try_change(a, 1);
}
/* add-first-task fut<int32>(all-args arr<ptr<char>>, main-ptr fun-ptr2<fut<int32>, ctx, arr<arr<char>>>) */
struct fut_0* add_first_task(struct ctx* ctx, struct arr_3 all_args, fun_ptr2 main_ptr) {
	struct add_first_task__lambda0* temp0;
	return then2(ctx, delay(ctx), (struct fun_ref0) {cur_island_and_exclusion(ctx), (0u | (uint64_t) (uint8_t*) (temp0 = (struct add_first_task__lambda0*) alloc(ctx, sizeof(struct add_first_task__lambda0)), ((*(temp0) = (struct add_first_task__lambda0) {all_args, main_ptr}, 0), temp0)))});
}
/* then2<int32> fut<int32>(f fut<void>, cb fun-ref0<int32>) */
struct fut_0* then2(struct ctx* ctx, struct fut_1* f, struct fun_ref0 cb) {
	struct then2__lambda0* temp0;
	return then(ctx, f, (struct fun_ref1) {cur_island_and_exclusion(ctx), (0u | (uint64_t) (uint8_t*) (temp0 = (struct then2__lambda0*) alloc(ctx, sizeof(struct then2__lambda0)), ((*(temp0) = (struct then2__lambda0) {cb}, 0), temp0)))});
}
/* then<?out, void> fut<int32>(f fut<void>, cb fun-ref1<int32, void>) */
struct fut_0* then(struct ctx* ctx, struct fut_1* f, struct fun_ref1 cb) {
	struct fut_0* res0;
	struct then__lambda0* temp0;
	res0 = new_unresolved_fut(ctx);
	then_void_0(ctx, f, (0u | (uint64_t) (uint8_t*) (temp0 = (struct then__lambda0*) alloc(ctx, sizeof(struct then__lambda0)), ((*(temp0) = (struct then__lambda0) {cb, res0}, 0), temp0))));
	return res0;
}
/* new-unresolved-fut<?out> fut<int32>() */
struct fut_0* new_unresolved_fut(struct ctx* ctx) {
	struct fut_0* temp0;
	temp0 = (struct fut_0*) alloc(ctx, sizeof(struct fut_0));
	(*(temp0) = (struct fut_0) {new_lock(), (struct fut_state_0) {0, .as0 = (struct fut_state_callbacks_0) {(struct opt_0) {0, .as0 = (struct none) {0}}}}}, 0);
	return temp0;
}
/* then-void<?in> void(f fut<void>, cb fun-mut1<void, result<void, exception>>) */
uint8_t then_void_0(struct ctx* ctx, struct fut_1* f, uint64_t cb) {
	struct fut_state_1 temp0;
	struct fut_state_callbacks_1 cbs0;
	struct fut_callback_node_1* temp1;
	struct fut_state_resolved_1 r1;
	struct exception e2;
	acquire_lock((&(f->lk)));
	temp0 = f->state;
	switch (temp0.kind) {
		case 0:
			cbs0 = temp0.as0;
			(f->state = (struct fut_state_1) {0, .as0 = (struct fut_state_callbacks_1) {(struct opt_3) {1, .as1 = (struct some_3) {(temp1 = (struct fut_callback_node_1*) alloc(ctx, sizeof(struct fut_callback_node_1)), ((*(temp1) = (struct fut_callback_node_1) {cb, cbs0.head}, 0), temp1))}}}}, 0);
			break;
		case 1:
			r1 = temp0.as1;
			call_0(ctx, cb, (struct result_1) {0, .as0 = (struct ok_1) {r1.value}});
			break;
		case 2:
			e2 = temp0.as2;
			call_0(ctx, cb, (struct result_1) {1, .as1 = (struct err_0) {e2}});
			break;
		default:
			(assert(0),0);
	}
	return release_lock((&(f->lk)));
}
/* call<void, result<?t, exception>> void(a fun-mut1<void, result<void, exception>>, p0 result<void, exception>) */
uint8_t call_0(struct ctx* ctx, uint64_t a, struct result_1 p0) {
	return call_w_ctx_78(a, ctx, p0);
}
/* call-w-ctx<void, result<void, exception>> (generated) (generated) */
uint8_t call_w_ctx_78(uint64_t a, struct ctx* ctx, struct result_1 p0) {
	switch ((a >> 48u)) {
		case 0:
			return then__lambda0(ctx, (struct then__lambda0*) (a & 281474976710655u), p0);
		default:
			return (assert(0),0);
	}
}
/* forward-to<?out> void(from fut<int32>, to fut<int32>) */
uint8_t forward_to(struct ctx* ctx, struct fut_0* from, struct fut_0* to) {
	struct forward_to__lambda0* temp0;
	return then_void_1(ctx, from, (0u | (uint64_t) (uint8_t*) (temp0 = (struct forward_to__lambda0*) alloc(ctx, sizeof(struct forward_to__lambda0)), ((*(temp0) = (struct forward_to__lambda0) {to}, 0), temp0))));
}
/* then-void<?t> void(f fut<int32>, cb fun-mut1<void, result<int32, exception>>) */
uint8_t then_void_1(struct ctx* ctx, struct fut_0* f, uint64_t cb) {
	struct fut_state_0 temp0;
	struct fut_state_callbacks_0 cbs0;
	struct fut_callback_node_0* temp1;
	struct fut_state_resolved_0 r1;
	struct exception e2;
	acquire_lock((&(f->lk)));
	temp0 = f->state;
	switch (temp0.kind) {
		case 0:
			cbs0 = temp0.as0;
			(f->state = (struct fut_state_0) {0, .as0 = (struct fut_state_callbacks_0) {(struct opt_0) {1, .as1 = (struct some_0) {(temp1 = (struct fut_callback_node_0*) alloc(ctx, sizeof(struct fut_callback_node_0)), ((*(temp1) = (struct fut_callback_node_0) {cb, cbs0.head}, 0), temp1))}}}}, 0);
			break;
		case 1:
			r1 = temp0.as1;
			call_1(ctx, cb, (struct result_0) {0, .as0 = (struct ok_0) {r1.value}});
			break;
		case 2:
			e2 = temp0.as2;
			call_1(ctx, cb, (struct result_0) {1, .as1 = (struct err_0) {e2}});
			break;
		default:
			(assert(0),0);
	}
	return release_lock((&(f->lk)));
}
/* call<void, result<?t, exception>> void(a fun-mut1<void, result<int32, exception>>, p0 result<int32, exception>) */
uint8_t call_1(struct ctx* ctx, uint64_t a, struct result_0 p0) {
	return call_w_ctx_82(a, ctx, p0);
}
/* call-w-ctx<void, result<int32, exception>> (generated) (generated) */
uint8_t call_w_ctx_82(uint64_t a, struct ctx* ctx, struct result_0 p0) {
	switch ((a >> 48u)) {
		case 0:
			return forward_to__lambda0(ctx, (struct forward_to__lambda0*) (a & 281474976710655u), p0);
		default:
			return (assert(0),0);
	}
}
/* resolve-or-reject<?t> void(f fut<int32>, result result<int32, exception>) */
uint8_t resolve_or_reject(struct ctx* ctx, struct fut_0* f, struct result_0 result) {
	struct fut_state_0 temp0;
	struct fut_state_callbacks_0 cbs0;
	struct result_0 temp1;
	struct ok_0 o1;
	struct err_0 e2;
	struct exception ex3;
	acquire_lock((&(f->lk)));
	temp0 = f->state;
	switch (temp0.kind) {
		case 0:
			cbs0 = temp0.as0;
			resolve_or_reject_recur(ctx, cbs0.head, result);
			break;
		case 1:
			(assert(0),0);
			break;
		case 2:
			(assert(0),0);
			break;
		default:
			(assert(0),0);
	}
	(f->state = (temp1 = result, temp1.kind == 0 ? (o1 = temp1.as0, (struct fut_state_0) {1, .as1 = (struct fut_state_resolved_0) {o1.value}}) : temp1.kind == 1 ? (e2 = temp1.as1, (ex3 = e2.value, (struct fut_state_0) {2, .as2 = ex3})) : (assert(0),(struct fut_state_0) {0})), 0);
	return release_lock((&(f->lk)));
}
/* resolve-or-reject-recur<?t> void(node opt<fut-callback-node<int32>>, value result<int32, exception>) */
uint8_t resolve_or_reject_recur(struct ctx* ctx, struct opt_0 node, struct result_0 value) {
	struct opt_0 temp0;
	struct some_0 s0;
	struct opt_0 _tailCallnode;
	struct result_0 _tailCallvalue;
	top:
	temp0 = node;
	switch (temp0.kind) {
		case 0:
			return 0;
		case 1:
			s0 = temp0.as1;
			drop_1(call_1(ctx, s0.value->cb, value));
			_tailCallnode = s0.value->next_node;
			_tailCallvalue = value;
			node = _tailCallnode;
			value = _tailCallvalue;
			goto top;
		default:
			return (assert(0),0);
	}
}
/* drop<void> void(t void) */
uint8_t drop_1(uint8_t t) {
	return 0;
}
/* forward-to<?out>.lambda0 void(it result<int32, exception>) */
uint8_t forward_to__lambda0(struct ctx* ctx, struct forward_to__lambda0* _closure, struct result_0 it) {
	return resolve_or_reject(ctx, _closure->to, it);
}
/* call-ref<?out, ?in> fut<int32>(f fun-ref1<int32, void>, p0 void) */
struct fut_0* call_ref_0(struct ctx* ctx, struct fun_ref1 f, uint8_t p0) {
	struct island* island0;
	struct fut_0* res1;
	struct call_ref_0__lambda0* temp0;
	island0 = get_island(ctx, f.island_and_exclusion.island);
	res1 = new_unresolved_fut(ctx);
	add_task(ctx, island0, (struct task) {f.island_and_exclusion.exclusion, (281474976710656u | (uint64_t) (uint8_t*) (temp0 = (struct call_ref_0__lambda0*) alloc(ctx, sizeof(struct call_ref_0__lambda0)), ((*(temp0) = (struct call_ref_0__lambda0) {f, p0, res1}, 0), temp0)))});
	return res1;
}
/* get-island island(island-id nat) */
struct island* get_island(struct ctx* ctx, uint64_t island_id) {
	return at_0(ctx, get_gctx(ctx)->islands, island_id);
}
/* at<island> island(a arr<island>, index nat) */
struct island* at_0(struct ctx* ctx, struct arr_2 a, uint64_t index) {
	assert_0(ctx, _op_less(index, a.size));
	return noctx_at_0(a, index);
}
/* assert void(condition bool) */
uint8_t assert_0(struct ctx* ctx, uint8_t condition) {
	return assert_1(ctx, condition, (struct arr_0) {13, constantarr_0_7});
}
/* assert void(condition bool, message arr<char>) */
uint8_t assert_1(struct ctx* ctx, uint8_t condition, struct arr_0 message) {
	if (!condition) {
		return fail(ctx, message);
	} else {
		return 0;
	}
}
/* fail<void> void(reason arr<char>) */
uint8_t fail(struct ctx* ctx, struct arr_0 reason) {
	return throw(ctx, (struct exception) {reason});
}
/* throw<?t> void(e exception) */
uint8_t throw(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx0;
	exn_ctx0 = get_exception_ctx(ctx);
	hard_forbid(null__q_1(exn_ctx0->jmp_buf_ptr));
	(exn_ctx0->thrown_exception = e, 0);
	(longjmp(exn_ctx0->jmp_buf_ptr, number_to_throw(ctx)), 0);
	return todo_1();
}
/* get-exception-ctx exception-ctx() */
struct exception_ctx* get_exception_ctx(struct ctx* ctx) {
	return (struct exception_ctx*) ctx->exception_ctx_ptr;
}
/* null?<jmp-buf-tag> bool(a ptr<jmp-buf-tag>) */
uint8_t null__q_1(struct jmp_buf_tag* a) {
	return _op_equal_equal_0((uint64_t) a, (uint64_t) NULL);
}
/* number-to-throw int32() */
int32_t number_to_throw(struct ctx* ctx) {
	return 7;
}
/* noctx-at<?t> island(a arr<island>, index nat) */
struct island* noctx_at_0(struct arr_2 a, uint64_t index) {
	hard_assert(_op_less(index, a.size));
	return (*((a.data + index)));
}
/* add-task void(a island, t task) */
uint8_t add_task(struct ctx* ctx, struct island* a, struct task t) {
	struct mut_bag_node* node0;
	node0 = new_mut_bag_node(ctx, t);
	acquire_lock((&(a->tasks_lock)));
	add(tasks(a), node0);
	release_lock((&(a->tasks_lock)));
	return broadcast((&(a->gctx->may_be_work_to_do)));
}
/* new-mut-bag-node<task> mut-bag-node<task>(value task) */
struct mut_bag_node* new_mut_bag_node(struct ctx* ctx, struct task value) {
	struct mut_bag_node* temp0;
	temp0 = (struct mut_bag_node*) alloc(ctx, sizeof(struct mut_bag_node));
	(*(temp0) = (struct mut_bag_node) {value, (struct opt_2) {0, .as0 = (struct none) {0}}}, 0);
	return temp0;
}
/* add<task> void(bag mut-bag<task>, node mut-bag-node<task>) */
uint8_t add(struct mut_bag* bag, struct mut_bag_node* node) {
	(node->next_node = bag->head, 0);
	return (bag->head = (struct opt_2) {1, .as1 = (struct some_2) {node}}, 0);
}
/* tasks mut-bag<task>(a island) */
struct mut_bag* tasks(struct island* a) {
	return (&((&(a->gc_root))->tasks));
}
/* broadcast void(c condition) */
uint8_t broadcast(struct condition* c) {
	acquire_lock((&(c->lk)));
	(c->value = noctx_incr(c->value), 0);
	return release_lock((&(c->lk)));
}
/* catch<void> void(try fun-mut0<void>, catcher fun-mut1<void, exception>) */
uint8_t catch(struct ctx* ctx, uint64_t try, uint64_t catcher) {
	return catch_with_exception_ctx(ctx, get_exception_ctx(ctx), try, catcher);
}
/* catch-with-exception-ctx<?t> void(ec exception-ctx, try fun-mut0<void>, catcher fun-mut1<void, exception>) */
uint8_t catch_with_exception_ctx(struct ctx* ctx, struct exception_ctx* ec, uint64_t try, uint64_t catcher) {
	struct exception old_thrown_exception0;
	struct jmp_buf_tag* old_jmp_buf1;
	struct jmp_buf_tag store2;
	int32_t setjmp_result3;
	uint8_t res4;
	struct exception thrown_exception5;
	old_thrown_exception0 = ec->thrown_exception;
	old_jmp_buf1 = ec->jmp_buf_ptr;
	store2 = (struct jmp_buf_tag) {zero_0(), 0, zero_3()};
	(ec->jmp_buf_ptr = (&(store2)), 0);
	setjmp_result3 = setjmp(ec->jmp_buf_ptr);
	if (_op_equal_equal_3(setjmp_result3, 0)) {
		res4 = call_2(ctx, try);
		(ec->jmp_buf_ptr = old_jmp_buf1, 0);
		(ec->thrown_exception = old_thrown_exception0, 0);
		return res4;
	} else {
		assert_0(ctx, _op_equal_equal_3(setjmp_result3, number_to_throw(ctx)));
		thrown_exception5 = ec->thrown_exception;
		(ec->jmp_buf_ptr = old_jmp_buf1, 0);
		(ec->thrown_exception = old_thrown_exception0, 0);
		return call_3(ctx, catcher, thrown_exception5);
	}
}
/* zero bytes64() */
struct bytes64 zero_0(void) {
	return (struct bytes64) {zero_1(), zero_1()};
}
/* zero bytes32() */
struct bytes32 zero_1(void) {
	return (struct bytes32) {zero_2(), zero_2()};
}
/* zero bytes16() */
struct bytes16 zero_2(void) {
	return (struct bytes16) {0u, 0u};
}
/* zero bytes128() */
struct bytes128 zero_3(void) {
	return (struct bytes128) {zero_0(), zero_0()};
}
/* call<?t> void(a fun-mut0<void>) */
uint8_t call_2(struct ctx* ctx, uint64_t a) {
	return call_w_ctx_112(a, ctx);
}
/* call-w-ctx<void> (generated) (generated) */
uint8_t call_w_ctx_112(uint64_t a, struct ctx* ctx) {
	switch ((a >> 48u)) {
		case 0:
			return call_ref_0__lambda0__lambda0(ctx, (struct call_ref_0__lambda0__lambda0*) (a & 281474976710655u));
		case 1:
			return call_ref_0__lambda0(ctx, (struct call_ref_0__lambda0*) (a & 281474976710655u));
		case 2:
			return call_ref_1__lambda0__lambda0(ctx, (struct call_ref_1__lambda0__lambda0*) (a & 281474976710655u));
		case 3:
			return call_ref_1__lambda0(ctx, (struct call_ref_1__lambda0*) (a & 281474976710655u));
		default:
			return (assert(0),0);
	}
}
/* call<?t, exception> void(a fun-mut1<void, exception>, p0 exception) */
uint8_t call_3(struct ctx* ctx, uint64_t a, struct exception p0) {
	return call_w_ctx_114(a, ctx, p0);
}
/* call-w-ctx<void, exception> (generated) (generated) */
uint8_t call_w_ctx_114(uint64_t a, struct ctx* ctx, struct exception p0) {
	switch ((a >> 48u)) {
		case 0:
			return new_island__lambda0(ctx, p0);
		case 1:
			return call_ref_0__lambda0__lambda1(ctx, (struct call_ref_0__lambda0__lambda1*) (a & 281474976710655u), p0);
		case 2:
			return call_ref_1__lambda0__lambda1(ctx, (struct call_ref_1__lambda0__lambda1*) (a & 281474976710655u), p0);
		default:
			return (assert(0),0);
	}
}
/* call<fut<?r>, ?p0> fut<int32>(a fun-mut1<fut<int32>, void>, p0 void) */
struct fut_0* call_4(struct ctx* ctx, uint64_t a, uint8_t p0) {
	return call_w_ctx_116(a, ctx, p0);
}
/* call-w-ctx<ptr(fut<int32>), void> (generated) (generated) */
struct fut_0* call_w_ctx_116(uint64_t a, struct ctx* ctx, uint8_t p0) {
	switch ((a >> 48u)) {
		case 0:
			return then2__lambda0(ctx, (struct then2__lambda0*) (a & 281474976710655u), p0);
		default:
			return (assert(0),NULL);
	}
}
/* call-ref<?out, ?in>.lambda0.lambda0 void() */
uint8_t call_ref_0__lambda0__lambda0(struct ctx* ctx, struct call_ref_0__lambda0__lambda0* _closure) {
	return forward_to(ctx, call_4(ctx, _closure->f.fun, _closure->p0), _closure->res);
}
/* reject<?r> void(f fut<int32>, e exception) */
uint8_t reject(struct ctx* ctx, struct fut_0* f, struct exception e) {
	return resolve_or_reject(ctx, f, (struct result_0) {1, .as1 = (struct err_0) {e}});
}
/* call-ref<?out, ?in>.lambda0.lambda1 void(it exception) */
uint8_t call_ref_0__lambda0__lambda1(struct ctx* ctx, struct call_ref_0__lambda0__lambda1* _closure, struct exception it) {
	return reject(ctx, _closure->res, it);
}
/* call-ref<?out, ?in>.lambda0 void() */
uint8_t call_ref_0__lambda0(struct ctx* ctx, struct call_ref_0__lambda0* _closure) {
	struct call_ref_0__lambda0__lambda0* temp0;
	struct call_ref_0__lambda0__lambda1* temp1;
	return catch(ctx, (0u | (uint64_t) (uint8_t*) (temp0 = (struct call_ref_0__lambda0__lambda0*) alloc(ctx, sizeof(struct call_ref_0__lambda0__lambda0)), ((*(temp0) = (struct call_ref_0__lambda0__lambda0) {_closure->f, _closure->p0, _closure->res}, 0), temp0))), (281474976710656u | (uint64_t) (uint8_t*) (temp1 = (struct call_ref_0__lambda0__lambda1*) alloc(ctx, sizeof(struct call_ref_0__lambda0__lambda1)), ((*(temp1) = (struct call_ref_0__lambda0__lambda1) {_closure->res}, 0), temp1))));
}
/* then<?out, void>.lambda0 void(result result<void, exception>) */
uint8_t then__lambda0(struct ctx* ctx, struct then__lambda0* _closure, struct result_1 result) {
	struct result_1 temp0;
	struct ok_1 o0;
	struct err_0 e1;
	temp0 = result;
	switch (temp0.kind) {
		case 0:
			o0 = temp0.as0;
			return forward_to(ctx, call_ref_0(ctx, _closure->cb, o0.value), _closure->res);
		case 1:
			e1 = temp0.as1;
			return reject(ctx, _closure->res, e1.value);
		default:
			return (assert(0),0);
	}
}
/* call-ref<?out> fut<int32>(f fun-ref0<int32>) */
struct fut_0* call_ref_1(struct ctx* ctx, struct fun_ref0 f) {
	struct island* island0;
	struct fut_0* res1;
	struct call_ref_1__lambda0* temp0;
	island0 = get_island(ctx, f.island_and_exclusion.island);
	res1 = new_unresolved_fut(ctx);
	add_task(ctx, island0, (struct task) {f.island_and_exclusion.exclusion, (844424930131968u | (uint64_t) (uint8_t*) (temp0 = (struct call_ref_1__lambda0*) alloc(ctx, sizeof(struct call_ref_1__lambda0)), ((*(temp0) = (struct call_ref_1__lambda0) {f, res1}, 0), temp0)))});
	return res1;
}
/* call<fut<?r>> fut<int32>(a fun-mut0<fut<int32>>) */
struct fut_0* call_5(struct ctx* ctx, uint64_t a) {
	return call_w_ctx_124(a, ctx);
}
/* call-w-ctx<ptr(fut<int32>)> (generated) (generated) */
struct fut_0* call_w_ctx_124(uint64_t a, struct ctx* ctx) {
	switch ((a >> 48u)) {
		case 0:
			return add_first_task__lambda0(ctx, (struct add_first_task__lambda0*) (a & 281474976710655u));
		default:
			return (assert(0),NULL);
	}
}
/* call-ref<?out>.lambda0.lambda0 void() */
uint8_t call_ref_1__lambda0__lambda0(struct ctx* ctx, struct call_ref_1__lambda0__lambda0* _closure) {
	return forward_to(ctx, call_5(ctx, _closure->f.fun), _closure->res);
}
/* call-ref<?out>.lambda0.lambda1 void(it exception) */
uint8_t call_ref_1__lambda0__lambda1(struct ctx* ctx, struct call_ref_1__lambda0__lambda1* _closure, struct exception it) {
	return reject(ctx, _closure->res, it);
}
/* call-ref<?out>.lambda0 void() */
uint8_t call_ref_1__lambda0(struct ctx* ctx, struct call_ref_1__lambda0* _closure) {
	struct call_ref_1__lambda0__lambda0* temp0;
	struct call_ref_1__lambda0__lambda1* temp1;
	return catch(ctx, (562949953421312u | (uint64_t) (uint8_t*) (temp0 = (struct call_ref_1__lambda0__lambda0*) alloc(ctx, sizeof(struct call_ref_1__lambda0__lambda0)), ((*(temp0) = (struct call_ref_1__lambda0__lambda0) {_closure->f, _closure->res}, 0), temp0))), (562949953421312u | (uint64_t) (uint8_t*) (temp1 = (struct call_ref_1__lambda0__lambda1*) alloc(ctx, sizeof(struct call_ref_1__lambda0__lambda1)), ((*(temp1) = (struct call_ref_1__lambda0__lambda1) {_closure->res}, 0), temp1))));
}
/* then2<int32>.lambda0 fut<int32>(ignore void) */
struct fut_0* then2__lambda0(struct ctx* ctx, struct then2__lambda0* _closure, uint8_t ignore) {
	return call_ref_1(ctx, _closure->cb);
}
/* cur-island-and-exclusion island-and-exclusion() */
struct island_and_exclusion cur_island_and_exclusion(struct ctx* ctx) {
	struct ctx* c0;
	c0 = ctx;
	return (struct island_and_exclusion) {c0->island_id, c0->exclusion};
}
/* delay fut<void>() */
struct fut_1* delay(struct ctx* ctx) {
	return resolved_0(ctx, 0);
}
/* resolved<void> fut<void>(value void) */
struct fut_1* resolved_0(struct ctx* ctx, uint8_t value) {
	struct fut_1* temp0;
	temp0 = (struct fut_1*) alloc(ctx, sizeof(struct fut_1));
	(*(temp0) = (struct fut_1) {new_lock(), (struct fut_state_1) {1, .as1 = (struct fut_state_resolved_1) {value}}}, 0);
	return temp0;
}
/* tail<ptr<char>> arr<ptr<char>>(a arr<ptr<char>>) */
struct arr_3 tail(struct ctx* ctx, struct arr_3 a) {
	forbid_0(ctx, empty__q_1(a));
	return slice_starting_at(ctx, a, 1u);
}
/* forbid void(condition bool) */
uint8_t forbid_0(struct ctx* ctx, uint8_t condition) {
	return forbid_1(ctx, condition, (struct arr_0) {13, constantarr_0_8});
}
/* forbid void(condition bool, message arr<char>) */
uint8_t forbid_1(struct ctx* ctx, uint8_t condition, struct arr_0 message) {
	if (condition) {
		return fail(ctx, message);
	} else {
		return 0;
	}
}
/* empty?<?t> bool(a arr<ptr<char>>) */
uint8_t empty__q_1(struct arr_3 a) {
	return _op_equal_equal_0(a.size, 0u);
}
/* slice-starting-at<?t> arr<ptr<char>>(a arr<ptr<char>>, begin nat) */
struct arr_3 slice_starting_at(struct ctx* ctx, struct arr_3 a, uint64_t begin) {
	assert_0(ctx, _op_less_equal(begin, a.size));
	return slice(ctx, a, begin, _op_minus_2(ctx, a.size, begin));
}
/* slice<?t> arr<ptr<char>>(a arr<ptr<char>>, begin nat, size nat) */
struct arr_3 slice(struct ctx* ctx, struct arr_3 a, uint64_t begin, uint64_t size) {
	assert_0(ctx, _op_less_equal(_op_plus(ctx, begin, size), a.size));
	return (struct arr_3) {size, (a.data + begin)};
}
/* + nat(a nat, b nat) */
uint64_t _op_plus(struct ctx* ctx, uint64_t a, uint64_t b) {
	uint64_t res0;
	res0 = (a + b);
	assert_0(ctx, (_op_greater_equal(res0, a) && _op_greater_equal(res0, b)));
	return res0;
}
/* >=<nat> bool(a nat, b nat) */
uint8_t _op_greater_equal(uint64_t a, uint64_t b) {
	return !_op_less(a, b);
}
/* - nat(a nat, b nat) */
uint64_t _op_minus_2(struct ctx* ctx, uint64_t a, uint64_t b) {
	assert_0(ctx, _op_greater_equal(a, b));
	return (a - b);
}
/* map<arr<char>, ptr<char>> arr<arr<char>>(a arr<ptr<char>>, mapper fun-mut1<arr<char>, ptr<char>>) */
struct arr_1 map(struct ctx* ctx, struct arr_3 a, uint64_t mapper) {
	struct map__lambda0* temp0;
	return make_arr(ctx, a.size, (0u | (uint64_t) (uint8_t*) (temp0 = (struct map__lambda0*) alloc(ctx, sizeof(struct map__lambda0)), ((*(temp0) = (struct map__lambda0) {mapper, a}, 0), temp0))));
}
/* make-arr<?out> arr<arr<char>>(size nat, f fun-mut1<arr<char>, nat>) */
struct arr_1 make_arr(struct ctx* ctx, uint64_t size, uint64_t f) {
	return freeze(make_mut_arr(ctx, size, f));
}
/* freeze<?t> arr<arr<char>>(a mut-arr<arr<char>>) */
struct arr_1 freeze(struct mut_arr_1* a) {
	(a->frozen__q = 1, 0);
	return unsafe_as_arr(a);
}
/* unsafe-as-arr<?t> arr<arr<char>>(a mut-arr<arr<char>>) */
struct arr_1 unsafe_as_arr(struct mut_arr_1* a) {
	return (struct arr_1) {a->size, a->data};
}
/* make-mut-arr<?t> mut-arr<arr<char>>(size nat, f fun-mut1<arr<char>, nat>) */
struct mut_arr_1* make_mut_arr(struct ctx* ctx, uint64_t size, uint64_t f) {
	struct mut_arr_1* res0;
	res0 = new_uninitialized_mut_arr(ctx, size);
	make_mut_arr_worker(ctx, res0, 0u, f);
	return res0;
}
/* new-uninitialized-mut-arr<?t> mut-arr<arr<char>>(size nat) */
struct mut_arr_1* new_uninitialized_mut_arr(struct ctx* ctx, uint64_t size) {
	struct mut_arr_1* temp0;
	temp0 = (struct mut_arr_1*) alloc(ctx, sizeof(struct mut_arr_1));
	(*(temp0) = (struct mut_arr_1) {0, size, size, uninitialized_data(ctx, size)}, 0);
	return temp0;
}
/* uninitialized-data<?t> ptr<arr<char>>(size nat) */
struct arr_0* uninitialized_data(struct ctx* ctx, uint64_t size) {
	uint8_t* bptr0;
	bptr0 = alloc(ctx, (size * sizeof(struct arr_0)));
	return (struct arr_0*) bptr0;
}
/* alloc ptr<nat8>(size nat) */
uint8_t* alloc(struct ctx* ctx, uint64_t size) {
	return gc_alloc(ctx, get_gc(ctx), size);
}
/* gc-alloc ptr<nat8>(gc gc, size nat) */
uint8_t* gc_alloc(struct ctx* ctx, struct gc* gc, uint64_t size) {
	struct opt_4 temp0;
	struct some_4 s0;
	temp0 = try_gc_alloc(gc, size);
	switch (temp0.kind) {
		case 0:
			return todo_2();
		case 1:
			s0 = temp0.as1;
			return s0.value;
		default:
			return (assert(0),NULL);
	}
}
/* try-gc-alloc opt<ptr<nat8>>(gc gc, size-bytes nat) */
struct opt_4 try_gc_alloc(struct gc* gc, uint64_t size_bytes) {
	uint64_t size_words0;
	uint64_t* cur1;
	uint64_t* next2;
	struct gc* _tailCallgc;
	uint64_t _tailCallsize_bytes;
	top:
	validate_gc(gc);
	size_words0 = words_of_bytes(size_bytes);
	cur1 = gc->data_cur;
	next2 = (cur1 + size_words0);
	if ((next2 < gc->data_end)) {
		if (range_free__q(gc->mark_cur, size_words0)) {
			(gc->mark_cur = (gc->mark_cur + size_words0), 0);
			(gc->data_cur = next2, 0);
			return (struct opt_4) {1, .as1 = (struct some_4) {(uint8_t*) cur1}};
		} else {
			(gc->mark_cur = incr_0(gc->mark_cur), 0);
			(gc->data_cur = incr_2(gc->data_cur), 0);
			_tailCallgc = gc;
			_tailCallsize_bytes = size_bytes;
			gc = _tailCallgc;
			size_bytes = _tailCallsize_bytes;
			goto top;
		}
	} else {
		return (struct opt_4) {0, .as0 = (struct none) {0}};
	}
}
/* validate-gc void(gc gc) */
uint8_t validate_gc(struct gc* gc) {
	uint64_t mark_idx0;
	uint64_t data_idx1;
	hard_assert(ptr_less_eq__q_0(gc->mark_begin, gc->mark_cur));
	hard_assert(ptr_less_eq__q_0(gc->mark_cur, gc->mark_end));
	hard_assert(ptr_less_eq__q_1(gc->data_begin, gc->data_cur));
	hard_assert(ptr_less_eq__q_1(gc->data_cur, gc->data_end));
	mark_idx0 = _op_minus_3(gc->mark_cur, gc->mark_begin);
	data_idx1 = _op_minus_0(gc->data_cur, gc->data_begin);
	hard_assert(_op_equal_equal_0(_op_minus_3(gc->mark_end, gc->mark_begin), gc->size_words));
	hard_assert(_op_equal_equal_0(_op_minus_0(gc->data_end, gc->data_begin), gc->size_words));
	return hard_assert(_op_equal_equal_0(mark_idx0, data_idx1));
}
/* ptr-less-eq?<bool> bool(a ptr<bool>, b ptr<bool>) */
uint8_t ptr_less_eq__q_0(uint8_t* a, uint8_t* b) {
	return ((a < b) || (a == b));
}
/* ptr-less-eq?<nat> bool(a ptr<nat>, b ptr<nat>) */
uint8_t ptr_less_eq__q_1(uint64_t* a, uint64_t* b) {
	return ((a < b) || (a == b));
}
/* -<bool> nat(a ptr<bool>, b ptr<bool>) */
uint64_t _op_minus_3(uint8_t* a, uint8_t* b) {
	return (((uint64_t) a - (uint64_t) b) / sizeof(uint8_t));
}
/* range-free? bool(mark ptr<bool>, size nat) */
uint8_t range_free__q(uint8_t* mark, uint64_t size) {
	uint8_t* _tailCallmark;
	uint64_t _tailCallsize;
	top:
	if (_op_equal_equal_0(size, 0u)) {
		return 1;
	} else {
		if ((*(mark))) {
			return 0;
		} else {
			_tailCallmark = incr_0(mark);
			_tailCallsize = noctx_decr(size);
			mark = _tailCallmark;
			size = _tailCallsize;
			goto top;
		}
	}
}
/* incr<nat> ptr<nat>(p ptr<nat>) */
uint64_t* incr_2(uint64_t* p) {
	return (p + 1u);
}
/* todo<ptr<nat8>> ptr<nat8>() */
uint8_t* todo_2(void) {
	return (assert(0),NULL);
}
/* get-gc gc() */
struct gc* get_gc(struct ctx* ctx) {
	return get_gc_ctx_1(ctx)->gc;
}
/* get-gc-ctx gc-ctx() */
struct gc_ctx* get_gc_ctx_1(struct ctx* ctx) {
	return (struct gc_ctx*) ctx->gc_ctx_ptr;
}
/* make-mut-arr-worker<?t> void(m mut-arr<arr<char>>, i nat, f fun-mut1<arr<char>, nat>) */
uint8_t make_mut_arr_worker(struct ctx* ctx, struct mut_arr_1* m, uint64_t i, uint64_t f) {
	struct mut_arr_1* _tailCallm;
	uint64_t _tailCalli;
	uint64_t _tailCallf;
	top:
	if (_op_bang_equal_0(i, m->size)) {
		set_at(ctx, m, i, call_6(ctx, f, i));
		_tailCallm = m;
		_tailCalli = incr_3(ctx, i);
		_tailCallf = f;
		m = _tailCallm;
		i = _tailCalli;
		f = _tailCallf;
		goto top;
	} else {
		return 0;
	}
}
/* set-at<?t> void(a mut-arr<arr<char>>, index nat, value arr<char>) */
uint8_t set_at(struct ctx* ctx, struct mut_arr_1* a, uint64_t index, struct arr_0 value) {
	assert_0(ctx, _op_less(index, a->size));
	return noctx_set_at_0(a, index, value);
}
/* noctx-set-at<?t> void(a mut-arr<arr<char>>, index nat, value arr<char>) */
uint8_t noctx_set_at_0(struct mut_arr_1* a, uint64_t index, struct arr_0 value) {
	hard_assert(_op_less(index, a->size));
	return (*((a->data + index)) = value, 0);
}
/* call<?t, nat> arr<char>(a fun-mut1<arr<char>, nat>, p0 nat) */
struct arr_0 call_6(struct ctx* ctx, uint64_t a, uint64_t p0) {
	return call_w_ctx_164(a, ctx, p0);
}
/* call-w-ctx<arr<char>, nat-64> (generated) (generated) */
struct arr_0 call_w_ctx_164(uint64_t a, struct ctx* ctx, uint64_t p0) {
	switch ((a >> 48u)) {
		case 0:
			return map__lambda0(ctx, (struct map__lambda0*) (a & 281474976710655u), p0);
		default:
			return (assert(0),(struct arr_0) {0, NULL});
	}
}
/* incr nat(n nat) */
uint64_t incr_3(struct ctx* ctx, uint64_t n) {
	forbid_0(ctx, _op_equal_equal_0(n, max_nat()));
	return (n + 1u);
}
/* call<?out, ?in> arr<char>(a fun-mut1<arr<char>, ptr<char>>, p0 ptr<char>) */
struct arr_0 call_7(struct ctx* ctx, uint64_t a, char* p0) {
	return call_w_ctx_167(a, ctx, p0);
}
/* call-w-ctx<arr<char>, ptr(char)> (generated) (generated) */
struct arr_0 call_w_ctx_167(uint64_t a, struct ctx* ctx, char* p0) {
	switch ((a >> 48u)) {
		case 0:
			return add_first_task__lambda0__lambda0(ctx, p0);
		default:
			return (assert(0),(struct arr_0) {0, NULL});
	}
}
/* at<?in> ptr<char>(a arr<ptr<char>>, index nat) */
char* at_1(struct ctx* ctx, struct arr_3 a, uint64_t index) {
	assert_0(ctx, _op_less(index, a.size));
	return noctx_at_1(a, index);
}
/* noctx-at<?t> ptr<char>(a arr<ptr<char>>, index nat) */
char* noctx_at_1(struct arr_3 a, uint64_t index) {
	hard_assert(_op_less(index, a.size));
	return (*((a.data + index)));
}
/* map<arr<char>, ptr<char>>.lambda0 arr<char>(i nat) */
struct arr_0 map__lambda0(struct ctx* ctx, struct map__lambda0* _closure, uint64_t i) {
	return call_7(ctx, _closure->mapper, at_1(ctx, _closure->a, i));
}
/* add-first-task.lambda0.lambda0 arr<char>(it ptr<char>) */
struct arr_0 add_first_task__lambda0__lambda0(struct ctx* ctx, char* it) {
	return to_str(it);
}
/* add-first-task.lambda0 fut<int32>() */
struct fut_0* add_first_task__lambda0(struct ctx* ctx, struct add_first_task__lambda0* _closure) {
	struct arr_3 args0;
	args0 = tail(ctx, _closure->all_args);
	return _closure->main_ptr(ctx, map(ctx, args0, 0u));
}
/* do-main.lambda0 fut<int32>(all-args arr<ptr<char>>, main-ptr fun-ptr2<fut<int32>, ctx, arr<arr<char>>>) */
struct fut_0* do_main__lambda0(struct ctx* ctx, struct arr_3 all_args, fun_ptr2 main_ptr) {
	return add_first_task(ctx, all_args, main_ptr);
}
/* call-w-ctx<ptr(fut<int32>), arr<ptr<char>>, some fun ptr type> (generated) (generated) */
struct fut_0* call_w_ctx_174(uint64_t a, struct ctx* ctx, struct arr_3 p0, fun_ptr2 p1) {
	switch ((a >> 48u)) {
		case 0:
			return do_main__lambda0(ctx, p0, p1);
		default:
			return (assert(0),NULL);
	}
}
/* run-threads void(n-threads nat, gctx global-ctx) */
uint8_t run_threads(uint64_t n_threads, struct global_ctx* gctx) {
	uint64_t* threads0;
	struct thread_args* thread_args1;
	uint64_t actual_n_threads2;
	threads0 = unmanaged_alloc_elements_0(n_threads);
	thread_args1 = unmanaged_alloc_elements_1(n_threads);
	actual_n_threads2 = noctx_decr(n_threads);
	start_threads_recur(0u, actual_n_threads2, threads0, thread_args1, gctx);
	thread_function(actual_n_threads2, gctx);
	join_threads_recur(0u, actual_n_threads2, threads0);
	unmanaged_free_0(threads0);
	return unmanaged_free_1(thread_args1);
}
/* unmanaged-alloc-elements<by-val<thread-args>> ptr<thread-args>(size-elements nat) */
struct thread_args* unmanaged_alloc_elements_1(uint64_t size_elements) {
	uint8_t* bytes0;
	bytes0 = unmanaged_alloc_bytes((size_elements * sizeof(struct thread_args)));
	return (struct thread_args*) bytes0;
}
/* start-threads-recur void(i nat, n-threads nat, threads ptr<nat>, thread-args-begin ptr<thread-args>, gctx global-ctx) */
uint8_t start_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads, struct thread_args* thread_args_begin, struct global_ctx* gctx) {
	struct thread_args* thread_arg_ptr0;
	uint64_t* thread_ptr1;
	int32_t err2;
	uint64_t _tailCalli;
	uint64_t _tailCalln_threads;
	uint64_t* _tailCallthreads;
	struct thread_args* _tailCallthread_args_begin;
	struct global_ctx* _tailCallgctx;
	top:
	if (_op_bang_equal_0(i, n_threads)) {
		thread_arg_ptr0 = (thread_args_begin + i);
		(*(thread_arg_ptr0) = (struct thread_args) {i, gctx}, 0);
		thread_ptr1 = (threads + i);
		err2 = pthread_create(as_cell(thread_ptr1), NULL, thread_fun, (uint8_t*) thread_arg_ptr0);
		if (_op_equal_equal_3(err2, 0)) {
			_tailCalli = noctx_incr(i);
			_tailCalln_threads = n_threads;
			_tailCallthreads = threads;
			_tailCallthread_args_begin = thread_args_begin;
			_tailCallgctx = gctx;
			i = _tailCalli;
			n_threads = _tailCalln_threads;
			threads = _tailCallthreads;
			thread_args_begin = _tailCallthread_args_begin;
			gctx = _tailCallgctx;
			goto top;
		} else {
			if (_op_equal_equal_3(err2, eagain())) {
				return todo_1();
			} else {
				return todo_1();
			}
		}
	} else {
		return 0;
	}
}
/* as-cell<nat> cell<nat>(p ptr<nat>) */
struct cell_0* as_cell(uint64_t* p) {
	return (struct cell_0*) (uint8_t*) p;
}
/* thread-fun ptr<nat8>(args-ptr ptr<nat8>) */
uint8_t* thread_fun(uint8_t* args_ptr) {
	struct thread_args* args0;
	args0 = (struct thread_args*) args_ptr;
	thread_function(args0->thread_id, args0->gctx);
	return NULL;
}
/* thread-function void(thread-id nat, gctx global-ctx) */
uint8_t thread_function(uint64_t thread_id, struct global_ctx* gctx) {
	struct exception_ctx ectx0;
	struct thread_local_stuff tls1;
	ectx0 = new_exception_ctx();
	tls1 = (struct thread_local_stuff) {(&(ectx0))};
	return thread_function_recur(thread_id, gctx, (&(tls1)));
}
/* thread-function-recur void(thread-id nat, gctx global-ctx, tls thread-local-stuff) */
uint8_t thread_function_recur(uint64_t thread_id, struct global_ctx* gctx, struct thread_local_stuff* tls) {
	uint64_t last_checked0;
	struct result_2 temp0;
	struct ok_2 ok_chosen_task1;
	struct err_1 e2;
	uint64_t _tailCallthread_id;
	struct global_ctx* _tailCallgctx;
	struct thread_local_stuff* _tailCalltls;
	top:
	if (gctx->is_shut_down) {
		acquire_lock((&(gctx->lk)));
		(gctx->n_live_threads = noctx_decr(gctx->n_live_threads), 0);
		assert_islands_are_shut_down(0u, gctx->islands);
		return release_lock((&(gctx->lk)));
	} else {
		hard_assert(_op_greater(gctx->n_live_threads, 0u));
		last_checked0 = get_last_checked((&(gctx->may_be_work_to_do)));
		temp0 = choose_task(gctx);
		switch (temp0.kind) {
			case 0:
				ok_chosen_task1 = temp0.as0;
				do_task(gctx, tls, ok_chosen_task1.value);
				break;
			case 1:
				e2 = temp0.as1;
				if (e2.value.last_thread_out) {
					hard_forbid(gctx->is_shut_down);
					(gctx->is_shut_down = 1, 0);
					broadcast((&(gctx->may_be_work_to_do)));
				} else {
					wait_on((&(gctx->may_be_work_to_do)), last_checked0);
				}
				acquire_lock((&(gctx->lk)));
				(gctx->n_live_threads = noctx_incr(gctx->n_live_threads), 0);
				release_lock((&(gctx->lk)));
				break;
			default:
				(assert(0),0);
		}
		_tailCallthread_id = thread_id;
		_tailCallgctx = gctx;
		_tailCalltls = tls;
		thread_id = _tailCallthread_id;
		gctx = _tailCallgctx;
		tls = _tailCalltls;
		goto top;
	}
}
/* assert-islands-are-shut-down void(i nat, islands arr<island>) */
uint8_t assert_islands_are_shut_down(uint64_t i, struct arr_2 islands) {
	struct island* island0;
	uint64_t _tailCalli;
	struct arr_2 _tailCallislands;
	top:
	if (_op_bang_equal_0(i, islands.size)) {
		island0 = noctx_at_0(islands, i);
		acquire_lock((&(island0->tasks_lock)));
		hard_forbid((&(island0->gc))->needs_gc__q);
		hard_assert(_op_equal_equal_0(island0->n_threads_running, 0u));
		hard_assert(empty__q_2(tasks(island0)));
		release_lock((&(island0->tasks_lock)));
		_tailCalli = noctx_incr(i);
		_tailCallislands = islands;
		i = _tailCalli;
		islands = _tailCallislands;
		goto top;
	} else {
		return 0;
	}
}
/* empty?<task> bool(m mut-bag<task>) */
uint8_t empty__q_2(struct mut_bag* m) {
	return empty__q_3(m->head);
}
/* empty?<mut-bag-node<?t>> bool(a opt<mut-bag-node<task>>) */
uint8_t empty__q_3(struct opt_2 a) {
	struct opt_2 temp0;
	struct none n0;
	struct some_2 s1;
	temp0 = a;
	switch (temp0.kind) {
		case 0:
			n0 = temp0.as0;
			return 1;
		case 1:
			s1 = temp0.as1;
			return 0;
		default:
			return (assert(0),0);
	}
}
/* ><nat> bool(a nat, b nat) */
uint8_t _op_greater(uint64_t a, uint64_t b) {
	return !_op_less_equal(a, b);
}
/* get-last-checked nat(c condition) */
uint64_t get_last_checked(struct condition* c) {
	return c->value;
}
/* choose-task result<chosen-task, no-chosen-task>(gctx global-ctx) */
struct result_2 choose_task(struct global_ctx* gctx) {
	struct result_2 res1;
	struct opt_6 temp0;
	struct some_6 s0;
	acquire_lock((&(gctx->lk)));
	res1 = (temp0 = choose_task_recur(gctx->islands, 0u), temp0.kind == 0 ? (((gctx->n_live_threads = noctx_decr(gctx->n_live_threads), 0), hard_assert(_op_equal_equal_0(gctx->n_live_threads, 0u))), (struct result_2) {1, .as1 = (struct err_1) {(struct no_chosen_task) {_op_equal_equal_0(gctx->n_live_threads, 0u)}}}) : temp0.kind == 1 ? (s0 = temp0.as1, (struct result_2) {0, .as0 = (struct ok_2) {s0.value}}) : (assert(0),(struct result_2) {0}));
	release_lock((&(gctx->lk)));
	return res1;
}
/* choose-task-recur opt<chosen-task>(islands arr<island>, i nat) */
struct opt_6 choose_task_recur(struct arr_2 islands, uint64_t i) {
	struct island* island0;
	struct opt_7 temp0;
	struct some_7 s1;
	struct arr_2 _tailCallislands;
	uint64_t _tailCalli;
	top:
	if (_op_equal_equal_0(i, islands.size)) {
		return (struct opt_6) {0, .as0 = (struct none) {0}};
	} else {
		island0 = noctx_at_0(islands, i);
		temp0 = choose_task_in_island(island0);
		switch (temp0.kind) {
			case 0:
				_tailCallislands = islands;
				_tailCalli = noctx_incr(i);
				islands = _tailCallislands;
				i = _tailCalli;
				goto top;
			case 1:
				s1 = temp0.as1;
				return (struct opt_6) {1, .as1 = (struct some_6) {(struct chosen_task) {island0, s1.value}}};
			default:
				return (assert(0),(struct opt_6) {0});
		}
	}
}
/* choose-task-in-island opt<opt<task>>(island island) */
struct opt_7 choose_task_in_island(struct island* island) {
	struct opt_7 res1;
	struct opt_5 temp0;
	struct some_5 s0;
	acquire_lock((&(island->tasks_lock)));
	res1 = ((&(island->gc))->needs_gc__q ? (_op_equal_equal_0(island->n_threads_running, 0u) ? (struct opt_7) {1, .as1 = (struct some_7) {(struct opt_5) {0, .as0 = (struct none) {0}}}} : (struct opt_7) {0, .as0 = (struct none) {0}}) : (temp0 = find_and_remove_first_doable_task(island), temp0.kind == 0 ? (struct opt_7) {0, .as0 = (struct none) {0}} : temp0.kind == 1 ? (s0 = temp0.as1, (struct opt_7) {1, .as1 = (struct some_7) {(struct opt_5) {1, .as1 = (struct some_5) {s0.value}}}}) : (assert(0),(struct opt_7) {0})));
	if (!empty__q_4(res1)) {
		(island->n_threads_running = noctx_incr(island->n_threads_running), 0);
	} else {
		0;
	}
	release_lock((&(island->tasks_lock)));
	return res1;
}
/* find-and-remove-first-doable-task opt<task>(island island) */
struct opt_5 find_and_remove_first_doable_task(struct island* island) {
	struct opt_8 res0;
	struct opt_8 temp0;
	struct some_8 s1;
	res0 = find_and_remove_first_doable_task_recur(island, tasks(island)->head);
	temp0 = res0;
	switch (temp0.kind) {
		case 0:
			return (struct opt_5) {0, .as0 = (struct none) {0}};
		case 1:
			s1 = temp0.as1;
			(tasks(island)->head = s1.value.nodes, 0);
			return (struct opt_5) {1, .as1 = (struct some_5) {s1.value.task}};
		default:
			return (assert(0),(struct opt_5) {0});
	}
}
/* find-and-remove-first-doable-task-recur opt<task-and-nodes>(island island, opt-node opt<mut-bag-node<task>>) */
struct opt_8 find_and_remove_first_doable_task_recur(struct island* island, struct opt_2 opt_node) {
	struct opt_2 temp0;
	struct some_2 s0;
	struct mut_bag_node* node1;
	struct task task2;
	struct mut_arr_0* exclusions3;
	uint8_t task_ok4;
	struct opt_8 temp1;
	struct some_8 ss5;
	struct task_and_nodes tn6;
	temp0 = opt_node;
	switch (temp0.kind) {
		case 0:
			return (struct opt_8) {0, .as0 = (struct none) {0}};
		case 1:
			s0 = temp0.as1;
			node1 = s0.value;
			task2 = node1->value;
			exclusions3 = (&(island->currently_running_exclusions));
			task_ok4 = (contains__q(exclusions3, task2.exclusion) ? 0 : (push_capacity_must_be_sufficient(exclusions3, task2.exclusion), 1));
			if (task_ok4) {
				return (struct opt_8) {1, .as1 = (struct some_8) {(struct task_and_nodes) {task2, node1->next_node}}};
			} else {
				temp1 = find_and_remove_first_doable_task_recur(island, node1->next_node);
				switch (temp1.kind) {
					case 0:
						return (struct opt_8) {0, .as0 = (struct none) {0}};
					case 1:
						ss5 = temp1.as1;
						tn6 = ss5.value;
						(node1->next_node = tn6.nodes, 0);
						return (struct opt_8) {1, .as1 = (struct some_8) {(struct task_and_nodes) {tn6.task, (struct opt_2) {1, .as1 = (struct some_2) {node1}}}}};
					default:
						return (assert(0),(struct opt_8) {0});
				}
			}
		default:
			return (assert(0),(struct opt_8) {0});
	}
}
/* contains?<nat> bool(a mut-arr<nat>, value nat) */
uint8_t contains__q(struct mut_arr_0* a, uint64_t value) {
	return contains_recur__q(temp_as_arr(a), value, 0u);
}
/* contains-recur?<?t> bool(a arr<nat>, value nat, i nat) */
uint8_t contains_recur__q(struct arr_4 a, uint64_t value, uint64_t i) {
	struct arr_4 _tailCalla;
	uint64_t _tailCallvalue;
	uint64_t _tailCalli;
	top:
	if (_op_equal_equal_0(i, a.size)) {
		return 0;
	} else {
		if (_op_equal_equal_0(noctx_at_2(a, i), value)) {
			return 1;
		} else {
			_tailCalla = a;
			_tailCallvalue = value;
			_tailCalli = noctx_incr(i);
			a = _tailCalla;
			value = _tailCallvalue;
			i = _tailCalli;
			goto top;
		}
	}
}
/* noctx-at<?t> nat(a arr<nat>, index nat) */
uint64_t noctx_at_2(struct arr_4 a, uint64_t index) {
	hard_assert(_op_less(index, a.size));
	return (*((a.data + index)));
}
/* temp-as-arr<?t> arr<nat>(a mut-arr<nat>) */
struct arr_4 temp_as_arr(struct mut_arr_0* a) {
	return (struct arr_4) {a->size, a->data};
}
/* push-capacity-must-be-sufficient<nat> void(a mut-arr<nat>, value nat) */
uint8_t push_capacity_must_be_sufficient(struct mut_arr_0* a, uint64_t value) {
	uint64_t old_size0;
	hard_assert(_op_less(a->size, a->capacity));
	old_size0 = a->size;
	(a->size = noctx_incr(old_size0), 0);
	return noctx_set_at_1(a, old_size0, value);
}
/* noctx-set-at<?t> void(a mut-arr<nat>, index nat, value nat) */
uint8_t noctx_set_at_1(struct mut_arr_0* a, uint64_t index, uint64_t value) {
	hard_assert(_op_less(index, a->size));
	return (*((a->data + index)) = value, 0);
}
/* empty?<opt<task>> bool(a opt<opt<task>>) */
uint8_t empty__q_4(struct opt_7 a) {
	struct opt_7 temp0;
	struct none n0;
	struct some_7 s1;
	temp0 = a;
	switch (temp0.kind) {
		case 0:
			n0 = temp0.as0;
			return 1;
		case 1:
			s1 = temp0.as1;
			return 0;
		default:
			return (assert(0),0);
	}
}
/* do-task void(gctx global-ctx, tls thread-local-stuff, chosen-task chosen-task) */
uint8_t do_task(struct global_ctx* gctx, struct thread_local_stuff* tls, struct chosen_task chosen_task) {
	struct island* island0;
	struct opt_5 temp0;
	struct some_5 some_task1;
	struct task task2;
	struct ctx ctx3;
	island0 = chosen_task.island;
	temp0 = chosen_task.task_or_gc;
	switch (temp0.kind) {
		case 0:
			run_garbage_collection((&(island0->gc)), island0->gc_root);
			broadcast((&(gctx->may_be_work_to_do)));
			break;
		case 1:
			some_task1 = temp0.as1;
			task2 = some_task1.value;
			ctx3 = new_ctx(gctx, tls, island0, task2.exclusion);
			call_w_ctx_112(task2.fun, (&(ctx3)));
			acquire_lock((&(island0->tasks_lock)));
			noctx_must_remove_unordered((&(island0->currently_running_exclusions)), task2.exclusion);
			release_lock((&(island0->tasks_lock)));
			return_ctx((&(ctx3)));
			break;
		default:
			(assert(0),0);
	}
	acquire_lock((&(island0->tasks_lock)));
	(island0->n_threads_running = noctx_decr(island0->n_threads_running), 0);
	return release_lock((&(island0->tasks_lock)));
}
/* run-garbage-collection<by-val<island-gc-root>> void(gc gc, gc-root island-gc-root) */
uint8_t run_garbage_collection(struct gc* gc, struct island_gc_root gc_root) {
	struct mark_ctx mark_ctx0;
	hard_assert(gc->needs_gc__q);
	(memset((uint8_t*) gc->mark_begin, 0u, gc->size_words), 0);
	mark_ctx0 = (struct mark_ctx) {gc->size_words, gc->mark_begin, gc->data_begin};
	return todo_1();
}
/* noctx-must-remove-unordered<nat> void(a mut-arr<nat>, value nat) */
uint8_t noctx_must_remove_unordered(struct mut_arr_0* a, uint64_t value) {
	return noctx_must_remove_unordered_recur(a, 0u, value);
}
/* noctx-must-remove-unordered-recur<?t> void(a mut-arr<nat>, index nat, value nat) */
uint8_t noctx_must_remove_unordered_recur(struct mut_arr_0* a, uint64_t index, uint64_t value) {
	struct mut_arr_0* _tailCalla;
	uint64_t _tailCallindex;
	uint64_t _tailCallvalue;
	top:
	if (_op_equal_equal_0(index, a->size)) {
		return (assert(0),0);
	} else {
		if (_op_equal_equal_0(noctx_at_3(a, index), value)) {
			return drop_2(noctx_remove_unordered_at_index(a, index));
		} else {
			_tailCalla = a;
			_tailCallindex = noctx_incr(index);
			_tailCallvalue = value;
			a = _tailCalla;
			index = _tailCallindex;
			value = _tailCallvalue;
			goto top;
		}
	}
}
/* noctx-at<?t> nat(a mut-arr<nat>, index nat) */
uint64_t noctx_at_3(struct mut_arr_0* a, uint64_t index) {
	hard_assert(_op_less(index, a->size));
	return (*((a->data + index)));
}
/* drop<?t> void(t nat) */
uint8_t drop_2(uint64_t t) {
	return 0;
}
/* noctx-remove-unordered-at-index<?t> nat(a mut-arr<nat>, index nat) */
uint64_t noctx_remove_unordered_at_index(struct mut_arr_0* a, uint64_t index) {
	uint64_t res0;
	res0 = noctx_at_3(a, index);
	noctx_set_at_1(a, index, noctx_last(a));
	(a->size = noctx_decr(a->size), 0);
	return res0;
}
/* noctx-last<?t> nat(a mut-arr<nat>) */
uint64_t noctx_last(struct mut_arr_0* a) {
	hard_forbid(empty__q_5(a));
	return noctx_at_3(a, noctx_decr(a->size));
}
/* empty?<?t> bool(a mut-arr<nat>) */
uint8_t empty__q_5(struct mut_arr_0* a) {
	return _op_equal_equal_0(a->size, 0u);
}
/* return-ctx void(c ctx) */
uint8_t return_ctx(struct ctx* c) {
	return return_gc_ctx((struct gc_ctx*) c->gc_ctx_ptr);
}
/* return-gc-ctx void(gc-ctx gc-ctx) */
uint8_t return_gc_ctx(struct gc_ctx* gc_ctx) {
	struct gc* gc0;
	gc0 = gc_ctx->gc;
	acquire_lock((&(gc0->lk)));
	(gc_ctx->next_ctx = gc0->context_head, 0);
	(gc0->context_head = (struct opt_1) {1, .as1 = (struct some_1) {gc_ctx}}, 0);
	return release_lock((&(gc0->lk)));
}
/* wait-on void(c condition, last-checked nat) */
uint8_t wait_on(struct condition* c, uint64_t last_checked) {
	struct condition* _tailCallc;
	uint64_t _tailCalllast_checked;
	top:
	if (_op_equal_equal_0(c->value, last_checked)) {
		yield_thread();
		_tailCallc = c;
		_tailCalllast_checked = last_checked;
		c = _tailCallc;
		last_checked = _tailCalllast_checked;
		goto top;
	} else {
		return 0;
	}
}
/* eagain int32() */
int32_t eagain(void) {
	return 11;
}
/* join-threads-recur void(i nat, n-threads nat, threads ptr<nat>) */
uint8_t join_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads) {
	uint64_t _tailCalli;
	uint64_t _tailCalln_threads;
	uint64_t* _tailCallthreads;
	top:
	if (_op_bang_equal_0(i, n_threads)) {
		join_one_thread((*((threads + i))));
		_tailCalli = noctx_incr(i);
		_tailCalln_threads = n_threads;
		_tailCallthreads = threads;
		i = _tailCalli;
		n_threads = _tailCalln_threads;
		threads = _tailCallthreads;
		goto top;
	} else {
		return 0;
	}
}
/* join-one-thread void(tid nat) */
uint8_t join_one_thread(uint64_t tid) {
	struct cell_1 thread_return0;
	int32_t err1;
	thread_return0 = (struct cell_1) {NULL};
	err1 = pthread_join(tid, (&(thread_return0)));
	if (_op_bang_equal_2(err1, 0)) {
		if (_op_equal_equal_3(err1, einval())) {
			todo_1();
		} else {
			if (_op_equal_equal_3(err1, esrch())) {
				todo_1();
			} else {
				todo_1();
			}
		}
	} else {
		0;
	}
	return hard_assert(null__q_0(get((&(thread_return0)))));
}
/* !=<int32> bool(a int32, b int32) */
uint8_t _op_bang_equal_2(int32_t a, int32_t b) {
	return !_op_equal_equal_3(a, b);
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
	return c->value;
}
/* unmanaged-free<nat> void(p ptr<nat>) */
uint8_t unmanaged_free_0(uint64_t* p) {
	return (free((uint8_t*) p), 0);
}
/* unmanaged-free<by-val<thread-args>> void(p ptr<thread-args>) */
uint8_t unmanaged_free_1(struct thread_args* p) {
	return (free((uint8_t*) p), 0);
}
/* must-be-resolved<int32> result<int32, exception>(f fut<int32>) */
struct result_0 must_be_resolved(struct fut_0* f) {
	struct fut_state_0 temp0;
	struct fut_state_resolved_0 r0;
	struct exception e1;
	temp0 = f->state;
	switch (temp0.kind) {
		case 0:
			return hard_unreachable();
		case 1:
			r0 = temp0.as1;
			return (struct result_0) {0, .as0 = (struct ok_0) {r0.value}};
		case 2:
			e1 = temp0.as2;
			return (struct result_0) {1, .as1 = (struct err_0) {e1}};
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
	r0 = (temp0 = (struct my_record*) alloc(ctx, sizeof(struct my_record)), ((*(temp0) = (struct my_record) {(struct arr_0) {1, constantarr_0_12}, (struct arr_0) {1, constantarr_0_13}}, 0), temp0));
	foo(ctx, r0);
	print(r0->a);
	print(r0->b);
	return resolved_1(ctx, 0);
}
/* foo void(r my-record) */
uint8_t foo(struct ctx* ctx, struct my_record* r) {
	print(r->a);
	return print(r->b);
}
/* print void(a arr<char>) */
uint8_t print(struct arr_0 a) {
	print_no_newline(a);
	return print_no_newline((struct arr_0) {1, constantarr_0_3});
}
/* print-no-newline void(a arr<char>) */
uint8_t print_no_newline(struct arr_0 a) {
	return write_no_newline(stdout_fd(), a);
}
/* stdout-fd int32() */
int32_t stdout_fd(void) {
	return 1;
}
/* resolved<int32> fut<int32>(value int32) */
struct fut_0* resolved_1(struct ctx* ctx, int32_t value) {
	struct fut_0* temp0;
	temp0 = (struct fut_0*) alloc(ctx, sizeof(struct fut_0));
	(*(temp0) = (struct fut_0) {new_lock(), (struct fut_state_0) {1, .as1 = (struct fut_state_resolved_0) {value}}}, 0);
	return temp0;
}
/* main (generated) (generated) */
int32_t main(int32_t argc, char** argv) {
	return rt_main(argc, argv, main_0);
}
