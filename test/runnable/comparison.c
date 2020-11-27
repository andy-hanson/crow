#include <assert.h>
#include <errno.h>
#include <stdatomic.h>
#include <stddef.h>
#include <stdint.h>
typedef uint8_t* (*fun_ptr1)(uint8_t*);
struct ctx {
	uint8_t* gctx_ptr;
	uint64_t vat_id;
	uint64_t actor_id;
	uint8_t* gc_ctx_ptr;
	uint8_t* exception_ctx_ptr;
};
struct fut_0;
struct lock;
struct _atomic_bool {
	uint8_t value;
};
struct fut_state_callbacks_0;
struct fut_callback_node_0;
struct exception;
struct arr_0 {
	uint64_t size;
	char* data;
};
struct ok_0 {
	int32_t value;
};
struct err_0;
struct fun_mut1_0;
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
struct less {
	uint8_t __mustBeNonEmpty;
};
struct equal {
	uint8_t __mustBeNonEmpty;
};
struct greater {
	uint8_t __mustBeNonEmpty;
};
struct global_ctx;
struct vat;
struct gc;
struct gc_ctx;
struct some_1 {
	struct gc_ctx* value;
};
struct task;
struct fun_mut0_0;
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
struct fun_mut1_1;
struct arr_2 {
	uint64_t size;
	struct vat** data;
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
struct fun2;
struct fut_1;
struct fut_state_callbacks_1;
struct fut_callback_node_1;
struct ok_1 {
	uint8_t value;
};
struct fun_mut1_2;
struct some_3 {
	struct fut_callback_node_1* value;
};
struct fut_state_resolved_1 {
	uint8_t value;
};
struct fun_ref0;
struct vat_and_actor_id {
	uint64_t vat;
	uint64_t actor;
};
struct fun_mut0_1;
struct fun_ref1;
struct fun_mut1_3;
struct then__lambda0;
struct forward_to__lambda0 {
	struct fut_0* to;
};
struct call_2__lambda0;
struct call_2__lambda0__lambda0;
struct call_2__lambda0__lambda1 {
	struct fut_0* res;
};
struct then2__lambda0;
struct call_6__lambda0;
struct call_6__lambda0__lambda0;
struct call_6__lambda0__lambda1 {
	struct fut_0* res;
};
struct add_first_task__lambda0;
struct fun_mut1_4;
struct fun_mut1_5;
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
struct chosen_task;
struct some_4;
struct no_chosen_task {
	uint8_t last_thread_out;
};
struct ok_2;
struct err_1 {
	struct no_chosen_task value;
};
struct some_5;
struct some_6;
struct task_and_nodes;
struct some_7;
struct arr_4 {
	uint64_t size;
	uint64_t* data;
};
struct cell_0 {
	uint64_t value;
};
struct cell_1 {
	uint8_t* value;
};
struct my_record {
	uint64_t x;
	uint64_t y;
};
struct my_byref_record {
	uint64_t x;
	uint64_t y;
};
struct my_other_record {
	uint8_t __mustBeNonEmpty;
};
struct fut_state_0;
struct result_0;
struct opt_0 {
	int kind;
	union {
		struct none as0;
		struct some_0 as1;
	};
};
struct comparison {
	int kind;
	union {
		struct less as0;
		struct equal as1;
		struct greater as2;
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
struct result_1;
struct opt_3 {
	int kind;
	union {
		struct none as0;
		struct some_3 as1;
	};
};
struct opt_4;
struct result_2;
struct opt_5;
struct opt_6;
struct opt_7;
struct my_union {
	int kind;
	union {
		struct my_record as0;
		struct my_other_record as1;
	};
};
typedef uint8_t (*fun_ptr3_0)(struct ctx*, uint8_t*, struct result_0);
typedef struct fut_0* (*fun_ptr2_0)(struct ctx*, struct arr_1);
typedef uint8_t (*fun_ptr2_1)(struct ctx*, uint8_t*);
typedef uint8_t (*fun_ptr3_1)(struct ctx*, uint8_t*, struct exception);
typedef struct fut_0* (*fun_ptr4)(struct ctx*, uint8_t*, struct arr_3, fun_ptr2_0);
typedef uint8_t (*fun_ptr3_2)(struct ctx*, uint8_t*, struct result_1);
typedef struct fut_0* (*fun_ptr2_2)(struct ctx*, uint8_t*);
typedef struct fut_0* (*fun_ptr3_3)(struct ctx*, uint8_t*, uint8_t);
typedef struct arr_0 (*fun_ptr3_4)(struct ctx*, uint8_t*, char*);
typedef struct arr_0 (*fun_ptr3_5)(struct ctx*, uint8_t*, uint64_t);
struct fut_0;
struct lock {
	struct _atomic_bool is_locked;
};
struct fut_state_callbacks_0 {
	struct opt_0 head;
};
struct fut_callback_node_0;
struct exception {
	struct arr_0 message;
};
struct err_0 {
	struct exception value;
};
struct fun_mut1_0 {
	fun_ptr3_0 fun_ptr;
	uint8_t* closure;
};
struct global_ctx;
struct vat;
struct gc {
	struct lock lk;
	struct opt_1 context_head;
	uint8_t needs_gc;
	uint8_t is_doing_gc;
	uint8_t* begin;
	uint8_t* next_byte;
};
struct gc_ctx {
	struct gc* gc;
	struct opt_1 next_ctx;
};
struct task;
struct fun_mut0_0 {
	fun_ptr2_1 fun_ptr;
	uint8_t* closure;
};
struct mut_bag {
	struct opt_2 head;
};
struct mut_bag_node;
struct thread_safe_counter {
	struct lock lk;
	uint64_t value;
};
struct fun_mut1_1 {
	fun_ptr3_1 fun_ptr;
	uint8_t* closure;
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
struct fun2 {
	fun_ptr4 fun_ptr;
	uint8_t* closure;
};
struct fut_1;
struct fut_state_callbacks_1 {
	struct opt_3 head;
};
struct fut_callback_node_1;
struct fun_mut1_2 {
	fun_ptr3_2 fun_ptr;
	uint8_t* closure;
};
struct fun_ref0;
struct fun_mut0_1 {
	fun_ptr2_2 fun_ptr;
	uint8_t* closure;
};
struct fun_ref1;
struct fun_mut1_3 {
	fun_ptr3_3 fun_ptr;
	uint8_t* closure;
};
struct then__lambda0;
struct call_2__lambda0;
struct call_2__lambda0__lambda0;
struct then2__lambda0;
struct call_6__lambda0;
struct call_6__lambda0__lambda0;
struct add_first_task__lambda0 {
	struct arr_3 all_args;
	fun_ptr2_0 main_ptr;
};
struct fun_mut1_4 {
	fun_ptr3_4 fun_ptr;
	uint8_t* closure;
};
struct fun_mut1_5 {
	fun_ptr3_5 fun_ptr;
	uint8_t* closure;
};
struct map__lambda0 {
	struct fun_mut1_4 mapper;
	struct arr_3 a;
};
struct chosen_task;
struct some_4;
struct ok_2;
struct some_5;
struct some_6;
struct task_and_nodes;
struct some_7;
struct fut_state_0 {
	int kind;
	union {
		struct fut_state_callbacks_0 as0;
		struct fut_state_resolved_0 as1;
		struct exception as2;
	};
};
struct result_0 {
	int kind;
	union {
		struct ok_0 as0;
		struct err_0 as1;
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
struct result_1 {
	int kind;
	union {
		struct ok_1 as0;
		struct err_0 as1;
	};
};
struct opt_4;
struct result_2;
struct opt_5;
struct opt_6;
struct opt_7;
struct fut_0 {
	struct lock lk;
	struct fut_state_0 state;
};
struct fut_callback_node_0 {
	struct fun_mut1_0 cb;
	struct opt_0 next_node;
};
struct global_ctx {
	struct lock lk;
	struct arr_2 vats;
	uint64_t n_live_threads;
	struct condition may_be_work_to_do;
	uint8_t is_shut_down;
	uint8_t any_unhandled_exceptions__q;
};
struct vat {
	struct global_ctx* gctx;
	uint64_t id;
	struct gc gc;
	struct lock tasks_lock;
	struct mut_bag tasks;
	struct mut_arr_0 currently_running_actors;
	uint64_t n_threads_running;
	struct thread_safe_counter next_actor_id;
	struct fun_mut1_1 exception_handler;
};
struct task {
	uint64_t actor_id;
	struct fun_mut0_0 fun;
};
struct mut_bag_node {
	struct task value;
	struct opt_2 next_node;
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
struct fut_callback_node_1 {
	struct fun_mut1_2 cb;
	struct opt_3 next_node;
};
struct fun_ref0 {
	struct vat_and_actor_id vat_and_actor;
	struct fun_mut0_1 fun;
};
struct fun_ref1 {
	struct vat_and_actor_id vat_and_actor;
	struct fun_mut1_3 fun;
};
struct then__lambda0 {
	struct fun_ref1 cb;
	struct fut_0* res;
};
struct call_2__lambda0 {
	struct fun_ref1 f;
	uint8_t p0;
	struct fut_0* res;
};
struct call_2__lambda0__lambda0 {
	struct fun_ref1 f;
	uint8_t p0;
	struct fut_0* res;
};
struct then2__lambda0 {
	struct fun_ref0 cb;
};
struct call_6__lambda0 {
	struct fun_ref0 f;
	struct fut_0* res;
};
struct call_6__lambda0__lambda0 {
	struct fun_ref0 f;
	struct fut_0* res;
};
struct chosen_task;
struct some_4 {
	struct task value;
};
struct ok_2;
struct some_5;
struct some_6;
struct task_and_nodes {
	struct task task;
	struct opt_2 nodes;
};
struct some_7 {
	struct task_and_nodes value;
};
struct opt_4 {
	int kind;
	union {
		struct none as0;
		struct some_4 as1;
	};
};
struct result_2;
struct opt_5;
struct opt_6;
struct opt_7 {
	int kind;
	union {
		struct none as0;
		struct some_7 as1;
	};
};
struct jmp_buf_tag {
	struct bytes64 jmp_buf;
	int32_t mask_was_saved;
	struct bytes128 saved_mask;
};
struct chosen_task {
	struct vat* vat;
	struct opt_4 task_or_gc;
};
struct ok_2 {
	struct chosen_task value;
};
struct some_5 {
	struct chosen_task value;
};
struct some_6 {
	struct opt_4 value;
};
struct result_2 {
	int kind;
	union {
		struct ok_2 as0;
		struct err_1 as1;
	};
};
struct opt_5 {
	int kind;
	union {
		struct none as0;
		struct some_5 as1;
	};
};
struct opt_6 {
	int kind;
	union {
		struct none as0;
		struct some_6 as1;
	};
};

char constantarr_0_0[17];
char constantarr_0_1[1];
char constantarr_0_2[4];
char constantarr_0_3[20];
char constantarr_0_4[1];
char constantarr_0_5[17];
char constantarr_0_6[38];
char constantarr_0_7[33];
char constantarr_0_8[13];
char constantarr_0_9[13];
char constantarr_0_10[39];
char constantarr_0_11[11];
char constantarr_0_12[13];
char constantarr_0_13[1];
char constantarr_0_14[1];
char constantarr_0_15[1];
char constantarr_0_16[1];
char constantarr_0_17[1];
char constantarr_0_18[1];
char constantarr_0_19[1];
char constantarr_0_20[1];
char constantarr_0_21[1];
char constantarr_0_22[1];
char constantarr_0_23[4];
char constantarr_0_24[5];
char constantarr_0_25[7];
char constantarr_0_26[1];
char constantarr_0_27[1];
char constantarr_0_0[17] = "Assertion failed!";
char constantarr_0_1[1] = "\0";
char constantarr_0_2[4] = "TODO";
char constantarr_0_3[20] = "uncaught exception: ";
char constantarr_0_4[1] = "\n";
char constantarr_0_5[17] = "<<empty message>>";
char constantarr_0_6[38] = "Couldn't acquire lock after 1000 tries";
char constantarr_0_7[33] = "resolving an already-resolved fut";
char constantarr_0_8[13] = "assert failed";
char constantarr_0_9[13] = "forbid failed";
char constantarr_0_10[39] = "Did not find the element in the mut-arr";
char constantarr_0_11[11] = "unreachable";
char constantarr_0_12[13] = "main failed: ";
char constantarr_0_13[1] = "0";
char constantarr_0_14[1] = "1";
char constantarr_0_15[1] = "2";
char constantarr_0_16[1] = "3";
char constantarr_0_17[1] = "4";
char constantarr_0_18[1] = "5";
char constantarr_0_19[1] = "6";
char constantarr_0_20[1] = "7";
char constantarr_0_21[1] = "8";
char constantarr_0_22[1] = "9";
char constantarr_0_23[4] = "less";
char constantarr_0_24[5] = "equal";
char constantarr_0_25[7] = "greater";
char constantarr_0_26[1] = "-";
char constantarr_0_27[1] = "+";
int32_t rt_main(int32_t argc, char** argv, fun_ptr2_0 main_ptr);
uint8_t drop_0(struct arr_0 t);
struct arr_0 to_str_0(char* a);
struct arr_0 arr_from_begin_end(char* begin, char* end);
struct arr_0 arr_0(uint64_t size, char* data);
uint64_t _op_minus_0(char* a, char* b);
char* find_cstr_end(char* a);
char* find_char_in_cstr(char* a, char c);
uint8_t _op_equal_equal_0(char a, char b);
struct comparison compare_9(char a, char b);
char literal_0(struct arr_0 a);
char noctx_at_0(struct arr_0 a, uint64_t index);
uint8_t hard_assert(uint8_t condition);
uint8_t _op_less_0(uint64_t a, uint64_t b);
struct comparison compare_14(uint64_t a, uint64_t b);
char* todo_0();
char* incr_0(char* p);
struct global_ctx global_ctx(struct lock lk, struct arr_2 vats, uint64_t n_live_threads, struct condition may_be_work_to_do, uint8_t is_shut_down, uint8_t any_unhandled_exceptions__q);
struct lock new_lock();
struct lock lock(struct _atomic_bool is_locked);
struct _atomic_bool new_atomic_bool();
struct _atomic_bool _atomic_bool(uint8_t value);
struct arr_2 empty_arr();
struct arr_2 arr_1(uint64_t size, struct vat** data);
struct condition new_condition();
struct condition condition(struct lock lk, uint64_t value);
struct vat new_vat(struct global_ctx* gctx, uint64_t id, uint64_t max_threads);
struct mut_arr_0 new_mut_arr_by_val_with_capacity_from_unmanaged_memory(uint64_t capacity);
struct mut_arr_0 mut_arr_0(uint8_t frozen__q, uint64_t size, uint64_t capacity, uint64_t* data);
uint64_t* unmanaged_alloc_elements_0(uint64_t size_elements);
uint8_t* unmanaged_alloc_bytes(uint64_t size);
extern uint8_t* malloc(uint64_t size);
uint8_t hard_forbid(uint8_t condition);
uint8_t null__q_0(uint8_t* a);
uint8_t _op_equal_equal_1(uint64_t a, uint64_t b);
struct vat vat(struct global_ctx* gctx, uint64_t id, struct gc gc, struct lock tasks_lock, struct mut_bag tasks, struct mut_arr_0 currently_running_actors, uint64_t n_threads_running, struct thread_safe_counter next_actor_id, struct fun_mut1_1 exception_handler);
struct gc new_gc();
struct gc gc(struct lock lk, struct opt_1 context_head, uint8_t needs_gc, uint8_t is_doing_gc, uint8_t* begin, uint8_t* next_byte);
struct none none();
struct mut_bag new_mut_bag();
struct mut_bag mut_bag(struct opt_2 head);
struct thread_safe_counter new_thread_safe_counter_0();
struct thread_safe_counter new_thread_safe_counter_1(uint64_t init);
struct thread_safe_counter thread_safe_counter(struct lock lk, uint64_t value);
uint8_t default_exception_handler(struct ctx* ctx, struct exception e);
uint8_t print_err_sync_no_newline(struct arr_0 s);
uint8_t write_sync_no_newline(int32_t fd, struct arr_0 s);
extern int64_t write(int32_t fd, uint8_t* buff, uint64_t n_bytes);
uint8_t _op_equal_equal_2(int64_t a, int64_t b);
struct comparison compare_49(int64_t a, int64_t b);
uint8_t todo_1();
int32_t stderr_fd();
int32_t two_0();
int32_t wrap_incr_0(int32_t a);
uint8_t print_err_sync(struct arr_0 s);
uint8_t empty__q_0(struct arr_0 a);
uint8_t zero__q_0(uint64_t n);
struct global_ctx* get_gctx(struct ctx* ctx);
uint8_t new_vat__lambda0(struct ctx* ctx, uint8_t* _closure, struct exception it);
struct fut_0* do_main(struct global_ctx* gctx, struct vat* vat, int32_t argc, char** argv, fun_ptr2_0 main_ptr);
struct exception_ctx new_exception_ctx();
struct exception_ctx exception_ctx(struct jmp_buf_tag* jmp_buf_ptr, struct exception thrown_exception);
struct exception exception(struct arr_0 message);
struct thread_local_stuff thread_local_stuff(struct exception_ctx* exception_ctx);
struct ctx new_ctx(struct global_ctx* gctx, struct thread_local_stuff* tls, struct vat* vat, uint64_t actor_id);
struct ctx ctx(uint8_t* gctx_ptr, uint64_t vat_id, uint64_t actor_id, uint8_t* gc_ctx_ptr, uint8_t* exception_ctx_ptr);
struct gc_ctx* get_gc_ctx_0(struct gc* gc);
uint8_t acquire_lock(struct lock* a);
uint8_t acquire_lock_recur(struct lock* a, uint64_t n_tries);
uint8_t try_acquire_lock(struct lock* a);
uint8_t try_set(struct _atomic_bool* a);
uint8_t try_change(struct _atomic_bool* a, uint8_t old_value);
uint64_t thousand_0();
uint64_t hundred_0();
uint64_t ten_0();
uint64_t wrap_incr_1(uint64_t a);
uint64_t nine_0();
uint64_t eight_0();
uint64_t seven_0();
uint64_t six_0();
uint64_t five_0();
uint64_t four_0();
uint64_t three_0();
uint64_t two_1();
uint8_t yield_thread();
extern int32_t pthread_yield();
uint8_t zero__q_1(int32_t i);
uint8_t _op_equal_equal_3(int32_t a, int32_t b);
struct comparison compare_88(int32_t a, int32_t b);
uint64_t noctx_incr(uint64_t n);
uint64_t billion();
uint64_t million_0();
uint8_t release_lock(struct lock* l);
uint8_t must_unset(struct _atomic_bool* a);
uint8_t try_unset(struct _atomic_bool* a);
struct fut_0* add_first_task(struct ctx* ctx, struct arr_3 all_args, fun_ptr2_0 main_ptr);
struct fut_0* then2(struct ctx* ctx, struct fut_1* f, struct fun_ref0 cb);
struct fut_0* then(struct ctx* ctx, struct fut_1* f, struct fun_ref1 cb);
struct fut_0* new_unresolved_fut(struct ctx* ctx);
struct fut_0* fut_0(struct ctx* ctx, struct lock lk, struct fut_state_0 state);
struct fut_state_callbacks_0 fut_state_callbacks_0(struct ctx* ctx, struct opt_0 head);
uint8_t then_void_0(struct ctx* ctx, struct fut_1* f, struct fun_mut1_2 cb);
struct fut_state_callbacks_1 fut_state_callbacks_1(struct ctx* ctx, struct opt_3 head);
struct some_3 some_0(struct fut_callback_node_1* value);
struct fut_callback_node_1* fut_callback_node_0(struct ctx* ctx, struct fun_mut1_2 cb, struct opt_3 next_node);
uint8_t call_0(struct ctx* ctx, struct fun_mut1_2 f, struct result_1 p0);
uint8_t call_with_ctx_0(struct ctx* c, struct fun_mut1_2 f, struct result_1 p0);
struct ok_1 ok_0(uint8_t value);
struct err_0 err_0(struct exception value);
uint8_t forward_to(struct ctx* ctx, struct fut_0* from, struct fut_0* to);
uint8_t then_void_1(struct ctx* ctx, struct fut_0* f, struct fun_mut1_0 cb);
struct some_0 some_1(struct fut_callback_node_0* value);
struct fut_callback_node_0* fut_callback_node_1(struct ctx* ctx, struct fun_mut1_0 cb, struct opt_0 next_node);
uint8_t call_1(struct ctx* ctx, struct fun_mut1_0 f, struct result_0 p0);
uint8_t call_with_ctx_1(struct ctx* c, struct fun_mut1_0 f, struct result_0 p0);
struct ok_0 ok_1(int32_t value);
uint8_t resolve_or_reject(struct ctx* ctx, struct fut_0* f, struct result_0 result);
uint8_t resolve_or_reject_recur(struct ctx* ctx, struct opt_0 node, struct result_0 value);
uint8_t drop_1(uint8_t t);
struct fut_state_resolved_0 fut_state_resolved_0(struct ctx* ctx, int32_t value);
uint8_t forward_to__lambda0(struct ctx* ctx, struct forward_to__lambda0* _closure, struct result_0 it);
struct fut_0* call_2(struct ctx* ctx, struct fun_ref1 f, uint8_t p0);
struct vat* get_vat(struct ctx* ctx, uint64_t vat_id);
struct vat* at_0(struct ctx* ctx, struct arr_2 a, uint64_t index);
uint8_t assert_0(struct ctx* ctx, uint8_t condition);
uint8_t assert_1(struct ctx* ctx, uint8_t condition, struct arr_0 message);
uint8_t fail(struct ctx* ctx, struct arr_0 reason);
uint8_t throw(struct ctx* ctx, struct exception e);
struct exception_ctx* get_exception_ctx(struct ctx* ctx);
uint8_t null__q_1(struct jmp_buf_tag* a);
extern void longjmp(struct jmp_buf_tag* env, int32_t val);
int32_t number_to_throw(struct ctx* ctx);
int32_t seven_1();
int32_t six_1();
int32_t five_1();
int32_t four_1();
int32_t three_1();
struct vat* noctx_at_1(struct arr_2 a, uint64_t index);
uint8_t add_task(struct ctx* ctx, struct vat* v, struct task t);
struct mut_bag_node* new_mut_bag_node(struct ctx* ctx, struct task value);
struct mut_bag_node* mut_bag_node(struct ctx* ctx, struct task value, struct opt_2 next_node);
uint8_t add(struct mut_bag* bag, struct mut_bag_node* node);
struct some_2 some_2(struct mut_bag_node* value);
uint8_t broadcast(struct condition* c);
struct task task(uint64_t actor_id, struct fun_mut0_0 fun);
uint8_t catch(struct ctx* ctx, struct fun_mut0_0 try, struct fun_mut1_1 catcher);
uint8_t catch_with_exception_ctx(struct ctx* ctx, struct exception_ctx* ec, struct fun_mut0_0 try, struct fun_mut1_1 catcher);
struct jmp_buf_tag jmp_buf_tag(struct bytes64 jmp_buf, int32_t mask_was_saved, struct bytes128 saved_mask);
struct bytes64 zero_0();
struct bytes64 bytes64(struct bytes32 n0, struct bytes32 n1);
struct bytes32 zero_1();
struct bytes32 bytes32(struct bytes16 n0, struct bytes16 n1);
struct bytes16 zero_2();
struct bytes16 bytes16(uint64_t n0, uint64_t n1);
struct bytes128 zero_3();
struct bytes128 bytes128(struct bytes64 n0, struct bytes64 n1);
extern int32_t setjmp(struct jmp_buf_tag* env);
uint8_t call_3(struct ctx* ctx, struct fun_mut0_0 f);
uint8_t call_with_ctx_2(struct ctx* c, struct fun_mut0_0 f);
uint8_t call_4(struct ctx* ctx, struct fun_mut1_1 f, struct exception p0);
uint8_t call_with_ctx_3(struct ctx* c, struct fun_mut1_1 f, struct exception p0);
struct fut_0* call_5(struct ctx* ctx, struct fun_mut1_3 f, uint8_t p0);
struct fut_0* call_with_ctx_4(struct ctx* c, struct fun_mut1_3 f, uint8_t p0);
uint8_t call_2__lambda0__lambda0(struct ctx* ctx, struct call_2__lambda0__lambda0* _closure);
uint8_t reject(struct ctx* ctx, struct fut_0* f, struct exception e);
uint8_t call_2__lambda0__lambda1(struct ctx* ctx, struct call_2__lambda0__lambda1* _closure, struct exception it);
uint8_t call_2__lambda0(struct ctx* ctx, struct call_2__lambda0* _closure);
uint8_t then__lambda0(struct ctx* ctx, struct then__lambda0* _closure, struct result_1 result);
struct fut_0* call_6(struct ctx* ctx, struct fun_ref0 f);
struct fut_0* call_7(struct ctx* ctx, struct fun_mut0_1 f);
struct fut_0* call_with_ctx_5(struct ctx* c, struct fun_mut0_1 f);
uint8_t call_6__lambda0__lambda0(struct ctx* ctx, struct call_6__lambda0__lambda0* _closure);
uint8_t call_6__lambda0__lambda1(struct ctx* ctx, struct call_6__lambda0__lambda1* _closure, struct exception it);
uint8_t call_6__lambda0(struct ctx* ctx, struct call_6__lambda0* _closure);
struct fut_0* then2__lambda0(struct ctx* ctx, struct then2__lambda0* _closure, uint8_t ignore);
struct vat_and_actor_id cur_actor(struct ctx* ctx);
struct vat_and_actor_id vat_and_actor_id(uint64_t vat, uint64_t actor);
struct fut_1* resolved_0(struct ctx* ctx, uint8_t value);
struct fut_1* fut_1(struct ctx* ctx, struct lock lk, struct fut_state_1 state);
struct fut_state_resolved_1 fut_state_resolved_1(struct ctx* ctx, uint8_t value);
struct arr_3 tail_0(struct ctx* ctx, struct arr_3 a);
uint8_t forbid_0(struct ctx* ctx, uint8_t condition);
uint8_t forbid_1(struct ctx* ctx, uint8_t condition, struct arr_0 message);
uint8_t empty__q_1(struct arr_3 a);
struct arr_3 slice_starting_at_0(struct ctx* ctx, struct arr_3 a, uint64_t begin);
uint8_t _op_less_equal_0(uint64_t a, uint64_t b);
struct arr_3 slice_0(struct ctx* ctx, struct arr_3 a, uint64_t begin, uint64_t size);
uint64_t _op_plus(struct ctx* ctx, uint64_t a, uint64_t b);
uint8_t _op_greater_equal(uint64_t a, uint64_t b);
struct arr_3 arr_2(uint64_t size, char** data);
uint64_t _op_minus_1(struct ctx* ctx, uint64_t a, uint64_t b);
struct arr_1 map(struct ctx* ctx, struct arr_3 a, struct fun_mut1_4 mapper);
struct arr_1 make_arr(struct ctx* ctx, uint64_t size, struct fun_mut1_5 f);
struct arr_1 freeze(struct mut_arr_1* a);
struct arr_1 unsafe_as_arr(struct mut_arr_1* a);
struct arr_1 arr_3(uint64_t size, struct arr_0* data);
struct mut_arr_1* make_mut_arr(struct ctx* ctx, uint64_t size, struct fun_mut1_5 f);
struct mut_arr_1* new_uninitialized_mut_arr(struct ctx* ctx, uint64_t size);
struct mut_arr_1* mut_arr_1(struct ctx* ctx, uint8_t frozen__q, uint64_t size, uint64_t capacity, struct arr_0* data);
struct arr_0* uninitialized_data(struct ctx* ctx, uint64_t size);
uint8_t* alloc(struct ctx* ctx, uint64_t size);
uint8_t* gc_alloc(struct ctx* ctx, struct gc* gc, uint64_t size);
struct gc* get_gc(struct ctx* ctx);
struct gc_ctx* get_gc_ctx_1(struct ctx* ctx);
uint8_t make_mut_arr_worker(struct ctx* ctx, struct mut_arr_1* m, uint64_t i, struct fun_mut1_5 f);
uint8_t set_at(struct ctx* ctx, struct mut_arr_1* a, uint64_t index, struct arr_0 value);
uint8_t noctx_set_at_0(struct mut_arr_1* a, uint64_t index, struct arr_0 value);
struct arr_0 call_8(struct ctx* ctx, struct fun_mut1_5 f, uint64_t p0);
struct arr_0 call_with_ctx_6(struct ctx* c, struct fun_mut1_5 f, uint64_t p0);
uint64_t incr_1(struct ctx* ctx, uint64_t n);
struct arr_0 call_9(struct ctx* ctx, struct fun_mut1_4 f, char* p0);
struct arr_0 call_with_ctx_7(struct ctx* c, struct fun_mut1_4 f, char* p0);
char* at_1(struct ctx* ctx, struct arr_3 a, uint64_t index);
char* noctx_at_2(struct arr_3 a, uint64_t index);
struct arr_0 map__lambda0(struct ctx* ctx, struct map__lambda0* _closure, uint64_t i);
struct arr_0 add_first_task__lambda0__lambda0(struct ctx* ctx, uint8_t* _closure, char* it);
struct fut_0* add_first_task__lambda0(struct ctx* ctx, struct add_first_task__lambda0* _closure);
struct fut_0* do_main__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr_3 all_args, fun_ptr2_0 main_ptr);
struct fut_0* call_with_ctx_8(struct ctx* c, struct fun2 f, struct arr_3 p0, fun_ptr2_0 p1);
uint8_t run_threads(uint64_t n_threads, struct global_ctx* gctx);
struct thread_args* unmanaged_alloc_elements_1(uint64_t size_elements);
uint64_t noctx_decr(uint64_t n);
uint8_t start_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads, struct thread_args* thread_args_begin, struct global_ctx* gctx);
struct thread_args thread_args(uint64_t thread_id, struct global_ctx* gctx);
uint8_t* thread_fun(uint8_t* args_ptr);
uint8_t thread_function(uint64_t thread_id, struct global_ctx* gctx);
uint8_t thread_function_recur(uint64_t thread_id, struct global_ctx* gctx, struct thread_local_stuff* tls);
uint8_t assert_vats_are_shut_down(uint64_t i, struct arr_2 vats);
uint8_t empty__q_2(struct mut_bag* m);
uint8_t empty__q_3(struct opt_2 a);
uint8_t _op_greater_0(uint64_t a, uint64_t b);
uint64_t get_last_checked(struct condition* c);
struct result_2 choose_task(struct global_ctx* gctx);
struct opt_5 choose_task_recur(struct arr_2 vats, uint64_t i);
struct opt_6 choose_task_in_vat(struct vat* vat);
struct some_6 some_3(struct opt_4 value);
struct opt_4 find_and_remove_first_doable_task(struct vat* vat);
struct opt_7 find_and_remove_first_doable_task_recur(struct vat* vat, struct opt_2 opt_node);
uint8_t contains__q(struct mut_arr_0* a, uint64_t value);
uint8_t contains_recur__q(struct arr_4 a, uint64_t value, uint64_t i);
uint64_t noctx_at_3(struct arr_4 a, uint64_t index);
struct arr_4 temp_as_arr(struct mut_arr_0* a);
struct arr_4 arr_4(uint64_t size, uint64_t* data);
uint8_t push_capacity_must_be_sufficient(struct mut_arr_0* a, uint64_t value);
uint8_t noctx_set_at_1(struct mut_arr_0* a, uint64_t index, uint64_t value);
struct some_7 some_4(struct task_and_nodes value);
struct task_and_nodes task_and_nodes(struct task task, struct opt_2 nodes);
struct some_4 some_5(struct task value);
uint8_t empty__q_4(struct opt_6 a);
struct some_5 some_6(struct chosen_task value);
struct chosen_task chosen_task(struct vat* vat, struct opt_4 task_or_gc);
struct err_1 err_1(struct no_chosen_task value);
struct no_chosen_task no_chosen_task(uint8_t last_thread_out);
struct ok_2 ok_2(struct chosen_task value);
uint8_t do_task(struct global_ctx* gctx, struct thread_local_stuff* tls, struct chosen_task chosen_task);
uint8_t noctx_must_remove_unordered(struct mut_arr_0* a, uint64_t value);
uint8_t noctx_must_remove_unordered_recur(struct mut_arr_0* a, uint64_t index, uint64_t value);
uint64_t noctx_at_4(struct mut_arr_0* a, uint64_t index);
uint8_t drop_2(uint64_t t);
uint64_t noctx_remove_unordered_at_index(struct mut_arr_0* a, uint64_t index);
uint64_t noctx_last(struct mut_arr_0* a);
uint8_t empty__q_5(struct mut_arr_0* a);
uint8_t return_ctx(struct ctx* c);
uint8_t return_gc_ctx(struct gc_ctx* gc_ctx);
struct some_1 some_7(struct gc_ctx* value);
uint8_t wait_on(struct condition* c, uint64_t last_checked);
uint8_t* start_threads_recur__lambda0(uint8_t* args_ptr);
extern int32_t pthread_create(struct cell_0* thread, uint8_t* attr, fun_ptr1 start_routine, uint8_t* arg);
struct cell_0* as_cell(uint64_t* p);
int32_t eagain();
int32_t ten_1();
uint8_t join_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads);
uint8_t join_one_thread(uint64_t tid);
struct cell_1 cell(uint8_t* value);
extern int32_t pthread_join(uint64_t thread, struct cell_1* thread_return);
int32_t einval();
int32_t esrch();
uint8_t* get(struct cell_1* c);
uint8_t unmanaged_free_0(uint64_t* p);
extern void free(uint8_t* p);
uint8_t unmanaged_free_1(struct thread_args* p);
struct result_0 must_be_resolved(struct fut_0* f);
struct result_0 hard_unreachable();
struct fut_0* main_0(struct ctx* ctx, struct arr_1 args);
uint8_t test_compare_records(struct ctx* ctx);
struct my_record my_record(struct ctx* ctx, uint64_t x, uint64_t y);
uint64_t literal_1(struct ctx* ctx, struct arr_0 s);
struct arr_0 rtail(struct ctx* ctx, struct arr_0 a);
struct arr_0 slice_1(struct ctx* ctx, struct arr_0 a, uint64_t begin, uint64_t size);
uint64_t decr(struct ctx* ctx, uint64_t a);
uint64_t wrap_decr(uint64_t a);
uint64_t _op_times_0(struct ctx* ctx, uint64_t a, uint64_t b);
uint64_t _op_div(struct ctx* ctx, uint64_t a, uint64_t b);
uint64_t char_to_nat(char c);
uint64_t todo_2();
char last(struct ctx* ctx, struct arr_0 a);
char at_2(struct ctx* ctx, struct arr_0 a, uint64_t index);
uint8_t print_sync(struct arr_0 s);
uint8_t print_sync_no_newline(struct arr_0 s);
int32_t stdout_fd();
struct arr_0 to_str_1(struct ctx* ctx, struct comparison c);
struct comparison compare_301(struct my_record a, struct my_record b);
uint8_t test_compare_byref_records(struct ctx* ctx);
struct my_byref_record* my_byref_record(struct ctx* ctx, uint64_t x, uint64_t y);
struct comparison compare_304(struct my_byref_record* a, struct my_byref_record* b);
uint8_t test_compare_unions(struct ctx* ctx);
struct my_other_record my_other_record();
struct comparison compare_307(struct my_union a, struct my_union b);
struct comparison compare_308(struct my_other_record a, struct my_other_record b);
struct fut_0* resolved_1(struct ctx* ctx, int32_t value);
int32_t literal_2(struct ctx* ctx, struct arr_0 s);
int64_t literal_3(struct ctx* ctx, struct arr_0 s);
struct arr_0 tail_1(struct ctx* ctx, struct arr_0 a);
struct arr_0 slice_starting_at_1(struct ctx* ctx, struct arr_0 a, uint64_t begin);
int64_t neg_0(struct ctx* ctx, uint64_t n);
int64_t neg_1(struct ctx* ctx, int64_t i);
int64_t _op_times_1(struct ctx* ctx, int64_t a, int64_t b);
uint8_t _op_greater_1(int64_t a, int64_t b);
uint8_t _op_less_equal_1(int64_t a, int64_t b);
uint8_t _op_less_1(int64_t a, int64_t b);
int64_t neg_million();
int64_t million_1();
int64_t thousand_1();
int64_t hundred_1();
int64_t ten_2();
int64_t wrap_incr_2(int64_t a);
int64_t nine_1();
int64_t eight_1();
int64_t seven_2();
int64_t six_2();
int64_t five_2();
int64_t four_2();
int64_t three_2();
int64_t two_2();
int64_t neg_one();
int64_t to_int(struct ctx* ctx, uint64_t n);
int32_t main(int32_t argc, char** argv);
int32_t rt_main(int32_t argc, char** argv, fun_ptr2_0 main_ptr) {
	uint64_t n_threads0;
	struct global_ctx gctx_by_val1;
	struct global_ctx* gctx2;
	struct vat vat_by_val3;
	struct vat* vat4;
	struct fut_0* main_fut5;
	struct result_0 _matched8;
	struct ok_0 o6;
	struct err_0 e7;
	drop_0(to_str_0((*(argv))));
	n_threads0 = 1;
	gctx_by_val1 = global_ctx(new_lock(), empty_arr(), n_threads0, new_condition(), 0, 0);
	gctx2 = (&(gctx_by_val1));
	vat_by_val3 = new_vat(gctx2, 0, n_threads0);
	vat4 = (&(vat_by_val3));
	(gctx2->vats = arr_1(1, (&(vat4))), 0);
	main_fut5 = do_main(gctx2, vat4, argc, argv, main_ptr);
	run_threads(n_threads0, gctx2);
	if (gctx2->any_unhandled_exceptions__q) {
		return 1;
	} else {
		_matched8 = must_be_resolved(main_fut5);
		switch (_matched8.kind) {
			case 0:
				o6 = _matched8.as0;
				return o6.value;
			case 1:
				e7 = _matched8.as1;
				print_err_sync_no_newline((struct arr_0) {13, constantarr_0_12});
				print_err_sync(e7.value.message);
				return 1;
			default:
				return (assert(0),0);
		}
	}
}
uint8_t drop_0(struct arr_0 t) {
	return 0;
}
struct arr_0 to_str_0(char* a) {
	return arr_from_begin_end(a, find_cstr_end(a));
}
struct arr_0 arr_from_begin_end(char* begin, char* end) {
	return arr_0(_op_minus_0(end, begin), begin);
}
struct arr_0 arr_0(uint64_t size, char* data) {
	return (struct arr_0) {size, data};
}
uint64_t _op_minus_0(char* a, char* b) {
	return (uint64_t) (a - (uint64_t) b);
}
char* find_cstr_end(char* a) {
	return find_char_in_cstr(a, literal_0((struct arr_0) {1, constantarr_0_1}));
}
char* find_char_in_cstr(char* a, char c) {
	char* _tailCalla;
	char _tailCallc;
	top:
	if (_op_equal_equal_0((*(a)), c)) {
		return a;
	} else {
		if (_op_equal_equal_0((*(a)), literal_0((struct arr_0) {1, constantarr_0_1}))) {
			return todo_0();
		} else {
			_tailCalla = incr_0(a);
			_tailCallc = c;
			a = _tailCalla;
			c = _tailCallc;
			goto top;
		}
	}
}
uint8_t _op_equal_equal_0(char a, char b) {
	struct comparison _matched0;
	_matched0 = compare_9(a, b);
	switch (_matched0.kind) {
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
struct comparison compare_9(char a, char b) {
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
char literal_0(struct arr_0 a) {
	return noctx_at_0(a, 0);
}
char noctx_at_0(struct arr_0 a, uint64_t index) {
	hard_assert(_op_less_0(index, a.size));
	return (*((a.data + index)));
}
uint8_t hard_assert(uint8_t condition) {
	if (condition) {
		return 0;
	} else {
		return (assert(0),0);
	}
}
uint8_t _op_less_0(uint64_t a, uint64_t b) {
	struct comparison _matched0;
	_matched0 = compare_14(a, b);
	switch (_matched0.kind) {
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
struct comparison compare_14(uint64_t a, uint64_t b) {
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
char* todo_0() {
	return (assert(0),NULL);
}
char* incr_0(char* p) {
	return (p + 1);
}
struct global_ctx global_ctx(struct lock lk, struct arr_2 vats, uint64_t n_live_threads, struct condition may_be_work_to_do, uint8_t is_shut_down, uint8_t any_unhandled_exceptions__q) {
	return (struct global_ctx) {lk, vats, n_live_threads, may_be_work_to_do, is_shut_down, any_unhandled_exceptions__q};
}
struct lock new_lock() {
	return lock(new_atomic_bool());
}
struct lock lock(struct _atomic_bool is_locked) {
	return (struct lock) {is_locked};
}
struct _atomic_bool new_atomic_bool() {
	return _atomic_bool(0);
}
struct _atomic_bool _atomic_bool(uint8_t value) {
	return (struct _atomic_bool) {value};
}
struct arr_2 empty_arr() {
	return arr_1(0, NULL);
}
struct arr_2 arr_1(uint64_t size, struct vat** data) {
	return (struct arr_2) {size, data};
}
struct condition new_condition() {
	return condition(new_lock(), 0);
}
struct condition condition(struct lock lk, uint64_t value) {
	return (struct condition) {lk, value};
}
struct vat new_vat(struct global_ctx* gctx, uint64_t id, uint64_t max_threads) {
	struct mut_arr_0 actors0;
	actors0 = new_mut_arr_by_val_with_capacity_from_unmanaged_memory(max_threads);
	return vat(gctx, id, new_gc(), new_lock(), new_mut_bag(), actors0, 0, new_thread_safe_counter_0(), (struct fun_mut1_1) {(fun_ptr3_1) new_vat__lambda0, (uint8_t*) NULL});
}
struct mut_arr_0 new_mut_arr_by_val_with_capacity_from_unmanaged_memory(uint64_t capacity) {
	return mut_arr_0(0, 0, capacity, unmanaged_alloc_elements_0(capacity));
}
struct mut_arr_0 mut_arr_0(uint8_t frozen__q, uint64_t size, uint64_t capacity, uint64_t* data) {
	return (struct mut_arr_0) {frozen__q, size, capacity, data};
}
uint64_t* unmanaged_alloc_elements_0(uint64_t size_elements) {
	uint8_t* bytes0;
	bytes0 = unmanaged_alloc_bytes((size_elements * sizeof(uint64_t)));
	return (uint64_t*) bytes0;
}
uint8_t* unmanaged_alloc_bytes(uint64_t size) {
	uint8_t* res0;
	res0 = malloc(size);
	hard_forbid(null__q_0(res0));
	return res0;
}
uint8_t hard_forbid(uint8_t condition) {
	return hard_assert(!condition);
}
uint8_t null__q_0(uint8_t* a) {
	return _op_equal_equal_1((uint64_t) a, (uint64_t) NULL);
}
uint8_t _op_equal_equal_1(uint64_t a, uint64_t b) {
	struct comparison _matched0;
	_matched0 = compare_14(a, b);
	switch (_matched0.kind) {
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
struct vat vat(struct global_ctx* gctx, uint64_t id, struct gc gc, struct lock tasks_lock, struct mut_bag tasks, struct mut_arr_0 currently_running_actors, uint64_t n_threads_running, struct thread_safe_counter next_actor_id, struct fun_mut1_1 exception_handler) {
	return (struct vat) {gctx, id, gc, tasks_lock, tasks, currently_running_actors, n_threads_running, next_actor_id, exception_handler};
}
struct gc new_gc() {
	return gc(new_lock(), (struct opt_1) {0, .as0 = none()}, 0, 0, NULL, NULL);
}
struct gc gc(struct lock lk, struct opt_1 context_head, uint8_t needs_gc, uint8_t is_doing_gc, uint8_t* begin, uint8_t* next_byte) {
	return (struct gc) {lk, context_head, needs_gc, is_doing_gc, begin, next_byte};
}
struct none none() {
	return (struct none) {0};
}
struct mut_bag new_mut_bag() {
	return mut_bag((struct opt_2) {0, .as0 = none()});
}
struct mut_bag mut_bag(struct opt_2 head) {
	return (struct mut_bag) {head};
}
struct thread_safe_counter new_thread_safe_counter_0() {
	return new_thread_safe_counter_1(0);
}
struct thread_safe_counter new_thread_safe_counter_1(uint64_t init) {
	return thread_safe_counter(new_lock(), init);
}
struct thread_safe_counter thread_safe_counter(struct lock lk, uint64_t value) {
	return (struct thread_safe_counter) {lk, value};
}
uint8_t default_exception_handler(struct ctx* ctx, struct exception e) {
	print_err_sync_no_newline((struct arr_0) {20, constantarr_0_3});
	print_err_sync((empty__q_0(e.message) ? (struct arr_0) {17, constantarr_0_5} : e.message));
	return (get_gctx(ctx)->any_unhandled_exceptions__q = 1, 0);
}
uint8_t print_err_sync_no_newline(struct arr_0 s) {
	return write_sync_no_newline(stderr_fd(), s);
}
uint8_t write_sync_no_newline(int32_t fd, struct arr_0 s) {
	int64_t res0;
	hard_assert(_op_equal_equal_1(sizeof(char), sizeof(uint8_t)));
	res0 = write(fd, (uint8_t*) s.data, s.size);
	if (_op_equal_equal_2(res0, s.size)) {
		return 0;
	} else {
		return todo_1();
	}
}
uint8_t _op_equal_equal_2(int64_t a, int64_t b) {
	struct comparison _matched0;
	_matched0 = compare_49(a, b);
	switch (_matched0.kind) {
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
struct comparison compare_49(int64_t a, int64_t b) {
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
uint8_t todo_1() {
	return (assert(0),0);
}
int32_t stderr_fd() {
	return two_0();
}
int32_t two_0() {
	return wrap_incr_0(1);
}
int32_t wrap_incr_0(int32_t a) {
	return (a + 1);
}
uint8_t print_err_sync(struct arr_0 s) {
	print_err_sync_no_newline(s);
	return print_err_sync_no_newline((struct arr_0) {1, constantarr_0_4});
}
uint8_t empty__q_0(struct arr_0 a) {
	return zero__q_0(a.size);
}
uint8_t zero__q_0(uint64_t n) {
	return _op_equal_equal_1(n, 0);
}
struct global_ctx* get_gctx(struct ctx* ctx) {
	return (struct global_ctx*) ctx->gctx_ptr;
}
uint8_t new_vat__lambda0(struct ctx* ctx, uint8_t* _closure, struct exception it) {
	return default_exception_handler(ctx, it);
}
struct fut_0* do_main(struct global_ctx* gctx, struct vat* vat, int32_t argc, char** argv, fun_ptr2_0 main_ptr) {
	struct exception_ctx ectx0;
	struct thread_local_stuff tls1;
	struct ctx ctx_by_val2;
	struct ctx* ctx3;
	struct fun2 add4;
	struct arr_3 all_args5;
	ectx0 = new_exception_ctx();
	tls1 = thread_local_stuff((&(ectx0)));
	ctx_by_val2 = new_ctx(gctx, (&(tls1)), vat, 0);
	ctx3 = (&(ctx_by_val2));
	add4 = (struct fun2) {(fun_ptr4) do_main__lambda0, (uint8_t*) NULL};
	all_args5 = arr_2(argc, argv);
	return call_with_ctx_8(ctx3, add4, all_args5, main_ptr);
}
struct exception_ctx new_exception_ctx() {
	return exception_ctx(NULL, exception((struct arr_0) {0, NULL}));
}
struct exception_ctx exception_ctx(struct jmp_buf_tag* jmp_buf_ptr, struct exception thrown_exception) {
	return (struct exception_ctx) {jmp_buf_ptr, thrown_exception};
}
struct exception exception(struct arr_0 message) {
	return (struct exception) {message};
}
struct thread_local_stuff thread_local_stuff(struct exception_ctx* exception_ctx) {
	return (struct thread_local_stuff) {exception_ctx};
}
struct ctx new_ctx(struct global_ctx* gctx, struct thread_local_stuff* tls, struct vat* vat, uint64_t actor_id) {
	return ctx((uint8_t*) gctx, vat->id, actor_id, (uint8_t*) get_gc_ctx_0((&(vat->gc))), (uint8_t*) tls->exception_ctx);
}
struct ctx ctx(uint8_t* gctx_ptr, uint64_t vat_id, uint64_t actor_id, uint8_t* gc_ctx_ptr, uint8_t* exception_ctx_ptr) {
	return (struct ctx) {gctx_ptr, vat_id, actor_id, gc_ctx_ptr, exception_ctx_ptr};
}
struct gc_ctx* get_gc_ctx_0(struct gc* gc) {
	struct gc_ctx* res4;
	struct opt_1 _matched3;
	struct gc_ctx* c0;
	struct some_1 s1;
	struct gc_ctx* c2;
	acquire_lock((&(gc->lk)));
	res4 = (_matched3 = gc->context_head, _matched3.kind == 0 ? (c0 = (struct gc_ctx*) malloc(sizeof(struct gc_ctx)), (((c0->gc = gc, 0), (c0->next_ctx = (struct opt_1) {0, .as0 = none()}, 0)), c0)) : _matched3.kind == 1 ? (s1 = _matched3.as1, (c2 = s1.value, (((gc->context_head = c2->next_ctx, 0), (c2->next_ctx = (struct opt_1) {0, .as0 = none()}, 0)), c2))) : (assert(0),NULL));
	release_lock((&(gc->lk)));
	return res4;
}
uint8_t acquire_lock(struct lock* a) {
	return acquire_lock_recur(a, 0);
}
uint8_t acquire_lock_recur(struct lock* a, uint64_t n_tries) {
	struct lock* _tailCalla;
	uint64_t _tailCalln_tries;
	top:
	if (try_acquire_lock(a)) {
		return 0;
	} else {
		if (_op_equal_equal_1(n_tries, thousand_0())) {
			return (assert(0),0);
		} else {
			yield_thread();
			_tailCalla = a;
			_tailCalln_tries = noctx_incr(n_tries);
			a = _tailCalla;
			n_tries = _tailCalln_tries;
			goto top;
		}
	}
}
uint8_t try_acquire_lock(struct lock* a) {
	return try_set((&(a->is_locked)));
}
uint8_t try_set(struct _atomic_bool* a) {
	return try_change(a, 0);
}
uint8_t try_change(struct _atomic_bool* a, uint8_t old_value) {
	return atomic_compare_exchange_strong((&(a->value)), (&(old_value)), !old_value);
}
uint64_t thousand_0() {
	return (hundred_0() * ten_0());
}
uint64_t hundred_0() {
	return (ten_0() * ten_0());
}
uint64_t ten_0() {
	return wrap_incr_1(nine_0());
}
uint64_t wrap_incr_1(uint64_t a) {
	return (a + 1);
}
uint64_t nine_0() {
	return wrap_incr_1(eight_0());
}
uint64_t eight_0() {
	return wrap_incr_1(seven_0());
}
uint64_t seven_0() {
	return wrap_incr_1(six_0());
}
uint64_t six_0() {
	return wrap_incr_1(five_0());
}
uint64_t five_0() {
	return wrap_incr_1(four_0());
}
uint64_t four_0() {
	return wrap_incr_1(three_0());
}
uint64_t three_0() {
	return wrap_incr_1(two_1());
}
uint64_t two_1() {
	return wrap_incr_1(1);
}
uint8_t yield_thread() {
	int32_t err0;
	err0 = pthread_yield();
	return hard_assert(zero__q_1(err0));
}
uint8_t zero__q_1(int32_t i) {
	return _op_equal_equal_3(i, 0);
}
uint8_t _op_equal_equal_3(int32_t a, int32_t b) {
	struct comparison _matched0;
	_matched0 = compare_88(a, b);
	switch (_matched0.kind) {
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
struct comparison compare_88(int32_t a, int32_t b) {
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
uint64_t noctx_incr(uint64_t n) {
	hard_assert(_op_less_0(n, billion()));
	return wrap_incr_1(n);
}
uint64_t billion() {
	return (million_0() * thousand_0());
}
uint64_t million_0() {
	return (thousand_0() * thousand_0());
}
uint8_t release_lock(struct lock* l) {
	return must_unset((&(l->is_locked)));
}
uint8_t must_unset(struct _atomic_bool* a) {
	uint8_t did_unset0;
	did_unset0 = try_unset(a);
	return hard_assert(did_unset0);
}
uint8_t try_unset(struct _atomic_bool* a) {
	return try_change(a, 1);
}
struct fut_0* add_first_task(struct ctx* ctx, struct arr_3 all_args, fun_ptr2_0 main_ptr) {
	struct add_first_task__lambda0* temp0;
	return then2(ctx, resolved_0(ctx, 0), (struct fun_ref0) {cur_actor(ctx), (struct fun_mut0_1) {(fun_ptr2_2) add_first_task__lambda0, (uint8_t*) (temp0 = (struct add_first_task__lambda0*) alloc(ctx, sizeof(struct add_first_task__lambda0)), ((*(temp0) = (struct add_first_task__lambda0) {all_args, main_ptr}, 0), temp0))}});
}
struct fut_0* then2(struct ctx* ctx, struct fut_1* f, struct fun_ref0 cb) {
	struct then2__lambda0* temp0;
	return then(ctx, f, (struct fun_ref1) {cur_actor(ctx), (struct fun_mut1_3) {(fun_ptr3_3) then2__lambda0, (uint8_t*) (temp0 = (struct then2__lambda0*) alloc(ctx, sizeof(struct then2__lambda0)), ((*(temp0) = (struct then2__lambda0) {cb}, 0), temp0))}});
}
struct fut_0* then(struct ctx* ctx, struct fut_1* f, struct fun_ref1 cb) {
	struct fut_0* res0;
	struct then__lambda0* temp0;
	res0 = new_unresolved_fut(ctx);
	then_void_0(ctx, f, (struct fun_mut1_2) {(fun_ptr3_2) then__lambda0, (uint8_t*) (temp0 = (struct then__lambda0*) alloc(ctx, sizeof(struct then__lambda0)), ((*(temp0) = (struct then__lambda0) {cb, res0}, 0), temp0))});
	return res0;
}
struct fut_0* new_unresolved_fut(struct ctx* ctx) {
	return fut_0(ctx, new_lock(), (struct fut_state_0) {0, .as0 = fut_state_callbacks_0(ctx, (struct opt_0) {0, .as0 = none()})});
}
struct fut_0* fut_0(struct ctx* ctx, struct lock lk, struct fut_state_0 state) {
	struct fut_0* temp0;
	temp0 = (struct fut_0*) alloc(ctx, sizeof(struct fut_0));
	(*(temp0) = (struct fut_0) {lk, state}, 0);
	return temp0;
}
struct fut_state_callbacks_0 fut_state_callbacks_0(struct ctx* ctx, struct opt_0 head) {
	return (struct fut_state_callbacks_0) {head};
}
uint8_t then_void_0(struct ctx* ctx, struct fut_1* f, struct fun_mut1_2 cb) {
	struct fut_state_1 _matched3;
	struct fut_state_callbacks_1 cbs0;
	struct fut_state_resolved_1 r1;
	struct exception e2;
	acquire_lock((&(f->lk)));
	_matched3 = f->state;
	switch (_matched3.kind) {
		case 0:
			cbs0 = _matched3.as0;
			(f->state = (struct fut_state_1) {0, .as0 = fut_state_callbacks_1(ctx, (struct opt_3) {1, .as1 = some_0(fut_callback_node_0(ctx, cb, cbs0.head))})}, 0);
			break;
		case 1:
			r1 = _matched3.as1;
			call_0(ctx, cb, (struct result_1) {0, .as0 = ok_0(r1.value)});
			break;
		case 2:
			e2 = _matched3.as2;
			call_0(ctx, cb, (struct result_1) {1, .as1 = err_0(e2)});
			break;
		default:
			(assert(0),0);
	}
	return release_lock((&(f->lk)));
}
struct fut_state_callbacks_1 fut_state_callbacks_1(struct ctx* ctx, struct opt_3 head) {
	return (struct fut_state_callbacks_1) {head};
}
struct some_3 some_0(struct fut_callback_node_1* value) {
	return (struct some_3) {value};
}
struct fut_callback_node_1* fut_callback_node_0(struct ctx* ctx, struct fun_mut1_2 cb, struct opt_3 next_node) {
	struct fut_callback_node_1* temp0;
	temp0 = (struct fut_callback_node_1*) alloc(ctx, sizeof(struct fut_callback_node_1));
	(*(temp0) = (struct fut_callback_node_1) {cb, next_node}, 0);
	return temp0;
}
uint8_t call_0(struct ctx* ctx, struct fun_mut1_2 f, struct result_1 p0) {
	return call_with_ctx_0(ctx, f, p0);
}
uint8_t call_with_ctx_0(struct ctx* c, struct fun_mut1_2 f, struct result_1 p0) {
	return f.fun_ptr(c, f.closure, p0);
}
struct ok_1 ok_0(uint8_t value) {
	return (struct ok_1) {value};
}
struct err_0 err_0(struct exception value) {
	return (struct err_0) {value};
}
uint8_t forward_to(struct ctx* ctx, struct fut_0* from, struct fut_0* to) {
	struct forward_to__lambda0* temp0;
	return then_void_1(ctx, from, (struct fun_mut1_0) {(fun_ptr3_0) forward_to__lambda0, (uint8_t*) (temp0 = (struct forward_to__lambda0*) alloc(ctx, sizeof(struct forward_to__lambda0)), ((*(temp0) = (struct forward_to__lambda0) {to}, 0), temp0))});
}
uint8_t then_void_1(struct ctx* ctx, struct fut_0* f, struct fun_mut1_0 cb) {
	struct fut_state_0 _matched3;
	struct fut_state_callbacks_0 cbs0;
	struct fut_state_resolved_0 r1;
	struct exception e2;
	acquire_lock((&(f->lk)));
	_matched3 = f->state;
	switch (_matched3.kind) {
		case 0:
			cbs0 = _matched3.as0;
			(f->state = (struct fut_state_0) {0, .as0 = fut_state_callbacks_0(ctx, (struct opt_0) {1, .as1 = some_1(fut_callback_node_1(ctx, cb, cbs0.head))})}, 0);
			break;
		case 1:
			r1 = _matched3.as1;
			call_1(ctx, cb, (struct result_0) {0, .as0 = ok_1(r1.value)});
			break;
		case 2:
			e2 = _matched3.as2;
			call_1(ctx, cb, (struct result_0) {1, .as1 = err_0(e2)});
			break;
		default:
			(assert(0),0);
	}
	return release_lock((&(f->lk)));
}
struct some_0 some_1(struct fut_callback_node_0* value) {
	return (struct some_0) {value};
}
struct fut_callback_node_0* fut_callback_node_1(struct ctx* ctx, struct fun_mut1_0 cb, struct opt_0 next_node) {
	struct fut_callback_node_0* temp0;
	temp0 = (struct fut_callback_node_0*) alloc(ctx, sizeof(struct fut_callback_node_0));
	(*(temp0) = (struct fut_callback_node_0) {cb, next_node}, 0);
	return temp0;
}
uint8_t call_1(struct ctx* ctx, struct fun_mut1_0 f, struct result_0 p0) {
	return call_with_ctx_1(ctx, f, p0);
}
uint8_t call_with_ctx_1(struct ctx* c, struct fun_mut1_0 f, struct result_0 p0) {
	return f.fun_ptr(c, f.closure, p0);
}
struct ok_0 ok_1(int32_t value) {
	return (struct ok_0) {value};
}
uint8_t resolve_or_reject(struct ctx* ctx, struct fut_0* f, struct result_0 result) {
	struct fut_state_0 _matched1;
	struct fut_state_callbacks_0 cbs0;
	struct result_0 _matched4;
	struct ok_0 o2;
	struct err_0 e3;
	acquire_lock((&(f->lk)));
	_matched1 = f->state;
	switch (_matched1.kind) {
		case 0:
			cbs0 = _matched1.as0;
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
	(f->state = (_matched4 = result, _matched4.kind == 0 ? (o2 = _matched4.as0, (struct fut_state_0) {1, .as1 = fut_state_resolved_0(ctx, o2.value)}) : _matched4.kind == 1 ? (e3 = _matched4.as1, (struct fut_state_0) {2, .as2 = e3.value}) : (assert(0),(struct fut_state_0) {0})), 0);
	return release_lock((&(f->lk)));
}
uint8_t resolve_or_reject_recur(struct ctx* ctx, struct opt_0 node, struct result_0 value) {
	struct opt_0 _matched1;
	struct some_0 s0;
	struct opt_0 _tailCallnode;
	struct result_0 _tailCallvalue;
	top:
	_matched1 = node;
	switch (_matched1.kind) {
		case 0:
			return 0;
		case 1:
			s0 = _matched1.as1;
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
uint8_t drop_1(uint8_t t) {
	return 0;
}
struct fut_state_resolved_0 fut_state_resolved_0(struct ctx* ctx, int32_t value) {
	return (struct fut_state_resolved_0) {value};
}
uint8_t forward_to__lambda0(struct ctx* ctx, struct forward_to__lambda0* _closure, struct result_0 it) {
	return resolve_or_reject(ctx, _closure->to, it);
}
struct fut_0* call_2(struct ctx* ctx, struct fun_ref1 f, uint8_t p0) {
	struct vat* vat0;
	struct fut_0* res1;
	struct call_2__lambda0* temp0;
	vat0 = get_vat(ctx, f.vat_and_actor.vat);
	res1 = new_unresolved_fut(ctx);
	add_task(ctx, vat0, task(f.vat_and_actor.actor, (struct fun_mut0_0) {(fun_ptr2_1) call_2__lambda0, (uint8_t*) (temp0 = (struct call_2__lambda0*) alloc(ctx, sizeof(struct call_2__lambda0)), ((*(temp0) = (struct call_2__lambda0) {f, p0, res1}, 0), temp0))}));
	return res1;
}
struct vat* get_vat(struct ctx* ctx, uint64_t vat_id) {
	return at_0(ctx, get_gctx(ctx)->vats, vat_id);
}
struct vat* at_0(struct ctx* ctx, struct arr_2 a, uint64_t index) {
	assert_0(ctx, _op_less_0(index, a.size));
	return noctx_at_1(a, index);
}
uint8_t assert_0(struct ctx* ctx, uint8_t condition) {
	return assert_1(ctx, condition, (struct arr_0) {13, constantarr_0_8});
}
uint8_t assert_1(struct ctx* ctx, uint8_t condition, struct arr_0 message) {
	if (condition) {
		return 0;
	} else {
		return fail(ctx, message);
	}
}
uint8_t fail(struct ctx* ctx, struct arr_0 reason) {
	return throw(ctx, exception(reason));
}
uint8_t throw(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx0;
	exn_ctx0 = get_exception_ctx(ctx);
	hard_forbid(null__q_1(exn_ctx0->jmp_buf_ptr));
	(exn_ctx0->thrown_exception = e, 0);
	(longjmp(exn_ctx0->jmp_buf_ptr, number_to_throw(ctx)), 0);
	return todo_1();
}
struct exception_ctx* get_exception_ctx(struct ctx* ctx) {
	return (struct exception_ctx*) ctx->exception_ctx_ptr;
}
uint8_t null__q_1(struct jmp_buf_tag* a) {
	return _op_equal_equal_1((uint64_t) a, (uint64_t) NULL);
}
int32_t number_to_throw(struct ctx* ctx) {
	return seven_1();
}
int32_t seven_1() {
	return wrap_incr_0(six_1());
}
int32_t six_1() {
	return wrap_incr_0(five_1());
}
int32_t five_1() {
	return wrap_incr_0(four_1());
}
int32_t four_1() {
	return wrap_incr_0(three_1());
}
int32_t three_1() {
	return wrap_incr_0(two_0());
}
struct vat* noctx_at_1(struct arr_2 a, uint64_t index) {
	hard_assert(_op_less_0(index, a.size));
	return (*((a.data + index)));
}
uint8_t add_task(struct ctx* ctx, struct vat* v, struct task t) {
	struct mut_bag_node* node0;
	node0 = new_mut_bag_node(ctx, t);
	acquire_lock((&(v->tasks_lock)));
	add((&(v->tasks)), node0);
	release_lock((&(v->tasks_lock)));
	return broadcast((&(v->gctx->may_be_work_to_do)));
}
struct mut_bag_node* new_mut_bag_node(struct ctx* ctx, struct task value) {
	return mut_bag_node(ctx, value, (struct opt_2) {0, .as0 = none()});
}
struct mut_bag_node* mut_bag_node(struct ctx* ctx, struct task value, struct opt_2 next_node) {
	struct mut_bag_node* temp0;
	temp0 = (struct mut_bag_node*) alloc(ctx, sizeof(struct mut_bag_node));
	(*(temp0) = (struct mut_bag_node) {value, next_node}, 0);
	return temp0;
}
uint8_t add(struct mut_bag* bag, struct mut_bag_node* node) {
	(node->next_node = bag->head, 0);
	return (bag->head = (struct opt_2) {1, .as1 = some_2(node)}, 0);
}
struct some_2 some_2(struct mut_bag_node* value) {
	return (struct some_2) {value};
}
uint8_t broadcast(struct condition* c) {
	acquire_lock((&(c->lk)));
	(c->value = noctx_incr(c->value), 0);
	return release_lock((&(c->lk)));
}
struct task task(uint64_t actor_id, struct fun_mut0_0 fun) {
	return (struct task) {actor_id, fun};
}
uint8_t catch(struct ctx* ctx, struct fun_mut0_0 try, struct fun_mut1_1 catcher) {
	return catch_with_exception_ctx(ctx, get_exception_ctx(ctx), try, catcher);
}
uint8_t catch_with_exception_ctx(struct ctx* ctx, struct exception_ctx* ec, struct fun_mut0_0 try, struct fun_mut1_1 catcher) {
	struct exception old_thrown_exception0;
	struct jmp_buf_tag* old_jmp_buf1;
	struct jmp_buf_tag store2;
	int32_t setjmp_result3;
	uint8_t res4;
	struct exception thrown_exception5;
	old_thrown_exception0 = ec->thrown_exception;
	old_jmp_buf1 = ec->jmp_buf_ptr;
	store2 = jmp_buf_tag(zero_0(), 0, zero_3());
	(ec->jmp_buf_ptr = (&(store2)), 0);
	setjmp_result3 = setjmp(ec->jmp_buf_ptr);
	if (_op_equal_equal_3(setjmp_result3, 0)) {
		res4 = call_3(ctx, try);
		(ec->jmp_buf_ptr = old_jmp_buf1, 0);
		(ec->thrown_exception = old_thrown_exception0, 0);
		return res4;
	} else {
		assert_0(ctx, _op_equal_equal_3(setjmp_result3, number_to_throw(ctx)));
		thrown_exception5 = ec->thrown_exception;
		(ec->jmp_buf_ptr = old_jmp_buf1, 0);
		(ec->thrown_exception = old_thrown_exception0, 0);
		return call_4(ctx, catcher, thrown_exception5);
	}
}
struct jmp_buf_tag jmp_buf_tag(struct bytes64 jmp_buf, int32_t mask_was_saved, struct bytes128 saved_mask) {
	return (struct jmp_buf_tag) {jmp_buf, mask_was_saved, saved_mask};
}
struct bytes64 zero_0() {
	return bytes64(zero_1(), zero_1());
}
struct bytes64 bytes64(struct bytes32 n0, struct bytes32 n1) {
	return (struct bytes64) {n0, n1};
}
struct bytes32 zero_1() {
	return bytes32(zero_2(), zero_2());
}
struct bytes32 bytes32(struct bytes16 n0, struct bytes16 n1) {
	return (struct bytes32) {n0, n1};
}
struct bytes16 zero_2() {
	return bytes16(0, 0);
}
struct bytes16 bytes16(uint64_t n0, uint64_t n1) {
	return (struct bytes16) {n0, n1};
}
struct bytes128 zero_3() {
	return bytes128(zero_0(), zero_0());
}
struct bytes128 bytes128(struct bytes64 n0, struct bytes64 n1) {
	return (struct bytes128) {n0, n1};
}
uint8_t call_3(struct ctx* ctx, struct fun_mut0_0 f) {
	return call_with_ctx_2(ctx, f);
}
uint8_t call_with_ctx_2(struct ctx* c, struct fun_mut0_0 f) {
	return f.fun_ptr(c, f.closure);
}
uint8_t call_4(struct ctx* ctx, struct fun_mut1_1 f, struct exception p0) {
	return call_with_ctx_3(ctx, f, p0);
}
uint8_t call_with_ctx_3(struct ctx* c, struct fun_mut1_1 f, struct exception p0) {
	return f.fun_ptr(c, f.closure, p0);
}
struct fut_0* call_5(struct ctx* ctx, struct fun_mut1_3 f, uint8_t p0) {
	return call_with_ctx_4(ctx, f, p0);
}
struct fut_0* call_with_ctx_4(struct ctx* c, struct fun_mut1_3 f, uint8_t p0) {
	return f.fun_ptr(c, f.closure, p0);
}
uint8_t call_2__lambda0__lambda0(struct ctx* ctx, struct call_2__lambda0__lambda0* _closure) {
	return forward_to(ctx, call_5(ctx, _closure->f.fun, _closure->p0), _closure->res);
}
uint8_t reject(struct ctx* ctx, struct fut_0* f, struct exception e) {
	return resolve_or_reject(ctx, f, (struct result_0) {1, .as1 = err_0(e)});
}
uint8_t call_2__lambda0__lambda1(struct ctx* ctx, struct call_2__lambda0__lambda1* _closure, struct exception it) {
	return reject(ctx, _closure->res, it);
}
uint8_t call_2__lambda0(struct ctx* ctx, struct call_2__lambda0* _closure) {
	struct call_2__lambda0__lambda0* temp0;
	struct call_2__lambda0__lambda1* temp1;
	return catch(ctx, (struct fun_mut0_0) {(fun_ptr2_1) call_2__lambda0__lambda0, (uint8_t*) (temp0 = (struct call_2__lambda0__lambda0*) alloc(ctx, sizeof(struct call_2__lambda0__lambda0)), ((*(temp0) = (struct call_2__lambda0__lambda0) {_closure->f, _closure->p0, _closure->res}, 0), temp0))}, (struct fun_mut1_1) {(fun_ptr3_1) call_2__lambda0__lambda1, (uint8_t*) (temp1 = (struct call_2__lambda0__lambda1*) alloc(ctx, sizeof(struct call_2__lambda0__lambda1)), ((*(temp1) = (struct call_2__lambda0__lambda1) {_closure->res}, 0), temp1))});
}
uint8_t then__lambda0(struct ctx* ctx, struct then__lambda0* _closure, struct result_1 result) {
	struct result_1 _matched2;
	struct ok_1 o0;
	struct err_0 e1;
	_matched2 = result;
	switch (_matched2.kind) {
		case 0:
			o0 = _matched2.as0;
			return forward_to(ctx, call_2(ctx, _closure->cb, o0.value), _closure->res);
		case 1:
			e1 = _matched2.as1;
			return reject(ctx, _closure->res, e1.value);
		default:
			return (assert(0),0);
	}
}
struct fut_0* call_6(struct ctx* ctx, struct fun_ref0 f) {
	struct vat* vat0;
	struct fut_0* res1;
	struct call_6__lambda0* temp0;
	vat0 = get_vat(ctx, f.vat_and_actor.vat);
	res1 = new_unresolved_fut(ctx);
	add_task(ctx, vat0, task(f.vat_and_actor.actor, (struct fun_mut0_0) {(fun_ptr2_1) call_6__lambda0, (uint8_t*) (temp0 = (struct call_6__lambda0*) alloc(ctx, sizeof(struct call_6__lambda0)), ((*(temp0) = (struct call_6__lambda0) {f, res1}, 0), temp0))}));
	return res1;
}
struct fut_0* call_7(struct ctx* ctx, struct fun_mut0_1 f) {
	return call_with_ctx_5(ctx, f);
}
struct fut_0* call_with_ctx_5(struct ctx* c, struct fun_mut0_1 f) {
	return f.fun_ptr(c, f.closure);
}
uint8_t call_6__lambda0__lambda0(struct ctx* ctx, struct call_6__lambda0__lambda0* _closure) {
	return forward_to(ctx, call_7(ctx, _closure->f.fun), _closure->res);
}
uint8_t call_6__lambda0__lambda1(struct ctx* ctx, struct call_6__lambda0__lambda1* _closure, struct exception it) {
	return reject(ctx, _closure->res, it);
}
uint8_t call_6__lambda0(struct ctx* ctx, struct call_6__lambda0* _closure) {
	struct call_6__lambda0__lambda0* temp0;
	struct call_6__lambda0__lambda1* temp1;
	return catch(ctx, (struct fun_mut0_0) {(fun_ptr2_1) call_6__lambda0__lambda0, (uint8_t*) (temp0 = (struct call_6__lambda0__lambda0*) alloc(ctx, sizeof(struct call_6__lambda0__lambda0)), ((*(temp0) = (struct call_6__lambda0__lambda0) {_closure->f, _closure->res}, 0), temp0))}, (struct fun_mut1_1) {(fun_ptr3_1) call_6__lambda0__lambda1, (uint8_t*) (temp1 = (struct call_6__lambda0__lambda1*) alloc(ctx, sizeof(struct call_6__lambda0__lambda1)), ((*(temp1) = (struct call_6__lambda0__lambda1) {_closure->res}, 0), temp1))});
}
struct fut_0* then2__lambda0(struct ctx* ctx, struct then2__lambda0* _closure, uint8_t ignore) {
	return call_6(ctx, _closure->cb);
}
struct vat_and_actor_id cur_actor(struct ctx* ctx) {
	struct ctx* c0;
	c0 = ctx;
	return vat_and_actor_id(c0->vat_id, c0->actor_id);
}
struct vat_and_actor_id vat_and_actor_id(uint64_t vat, uint64_t actor) {
	return (struct vat_and_actor_id) {vat, actor};
}
struct fut_1* resolved_0(struct ctx* ctx, uint8_t value) {
	return fut_1(ctx, new_lock(), (struct fut_state_1) {1, .as1 = fut_state_resolved_1(ctx, value)});
}
struct fut_1* fut_1(struct ctx* ctx, struct lock lk, struct fut_state_1 state) {
	struct fut_1* temp0;
	temp0 = (struct fut_1*) alloc(ctx, sizeof(struct fut_1));
	(*(temp0) = (struct fut_1) {lk, state}, 0);
	return temp0;
}
struct fut_state_resolved_1 fut_state_resolved_1(struct ctx* ctx, uint8_t value) {
	return (struct fut_state_resolved_1) {value};
}
struct arr_3 tail_0(struct ctx* ctx, struct arr_3 a) {
	forbid_0(ctx, empty__q_1(a));
	return slice_starting_at_0(ctx, a, 1);
}
uint8_t forbid_0(struct ctx* ctx, uint8_t condition) {
	return forbid_1(ctx, condition, (struct arr_0) {13, constantarr_0_9});
}
uint8_t forbid_1(struct ctx* ctx, uint8_t condition, struct arr_0 message) {
	if (condition) {
		return fail(ctx, message);
	} else {
		return 0;
	}
}
uint8_t empty__q_1(struct arr_3 a) {
	return zero__q_0(a.size);
}
struct arr_3 slice_starting_at_0(struct ctx* ctx, struct arr_3 a, uint64_t begin) {
	assert_0(ctx, _op_less_equal_0(begin, a.size));
	return slice_0(ctx, a, begin, _op_minus_1(ctx, a.size, begin));
}
uint8_t _op_less_equal_0(uint64_t a, uint64_t b) {
	return !_op_less_0(b, a);
}
struct arr_3 slice_0(struct ctx* ctx, struct arr_3 a, uint64_t begin, uint64_t size) {
	assert_0(ctx, _op_less_equal_0(_op_plus(ctx, begin, size), a.size));
	return arr_2(size, (a.data + begin));
}
uint64_t _op_plus(struct ctx* ctx, uint64_t a, uint64_t b) {
	uint64_t res0;
	res0 = (a + b);
	assert_0(ctx, (_op_greater_equal(res0, a) && _op_greater_equal(res0, b)));
	return res0;
}
uint8_t _op_greater_equal(uint64_t a, uint64_t b) {
	return !_op_less_0(a, b);
}
struct arr_3 arr_2(uint64_t size, char** data) {
	return (struct arr_3) {size, data};
}
uint64_t _op_minus_1(struct ctx* ctx, uint64_t a, uint64_t b) {
	assert_0(ctx, _op_greater_equal(a, b));
	return (a - b);
}
struct arr_1 map(struct ctx* ctx, struct arr_3 a, struct fun_mut1_4 mapper) {
	struct map__lambda0* temp0;
	return make_arr(ctx, a.size, (struct fun_mut1_5) {(fun_ptr3_5) map__lambda0, (uint8_t*) (temp0 = (struct map__lambda0*) alloc(ctx, sizeof(struct map__lambda0)), ((*(temp0) = (struct map__lambda0) {mapper, a}, 0), temp0))});
}
struct arr_1 make_arr(struct ctx* ctx, uint64_t size, struct fun_mut1_5 f) {
	return freeze(make_mut_arr(ctx, size, f));
}
struct arr_1 freeze(struct mut_arr_1* a) {
	(a->frozen__q = 1, 0);
	return unsafe_as_arr(a);
}
struct arr_1 unsafe_as_arr(struct mut_arr_1* a) {
	return arr_3(a->size, a->data);
}
struct arr_1 arr_3(uint64_t size, struct arr_0* data) {
	return (struct arr_1) {size, data};
}
struct mut_arr_1* make_mut_arr(struct ctx* ctx, uint64_t size, struct fun_mut1_5 f) {
	struct mut_arr_1* res0;
	res0 = new_uninitialized_mut_arr(ctx, size);
	make_mut_arr_worker(ctx, res0, 0, f);
	return res0;
}
struct mut_arr_1* new_uninitialized_mut_arr(struct ctx* ctx, uint64_t size) {
	return mut_arr_1(ctx, 0, size, size, uninitialized_data(ctx, size));
}
struct mut_arr_1* mut_arr_1(struct ctx* ctx, uint8_t frozen__q, uint64_t size, uint64_t capacity, struct arr_0* data) {
	struct mut_arr_1* temp0;
	temp0 = (struct mut_arr_1*) alloc(ctx, sizeof(struct mut_arr_1));
	(*(temp0) = (struct mut_arr_1) {frozen__q, size, capacity, data}, 0);
	return temp0;
}
struct arr_0* uninitialized_data(struct ctx* ctx, uint64_t size) {
	uint8_t* bptr0;
	bptr0 = alloc(ctx, (size * sizeof(struct arr_0)));
	return (struct arr_0*) bptr0;
}
uint8_t* alloc(struct ctx* ctx, uint64_t size) {
	return gc_alloc(ctx, get_gc(ctx), size);
}
uint8_t* gc_alloc(struct ctx* ctx, struct gc* gc, uint64_t size) {
	return unmanaged_alloc_bytes(size);
}
struct gc* get_gc(struct ctx* ctx) {
	return get_gc_ctx_1(ctx)->gc;
}
struct gc_ctx* get_gc_ctx_1(struct ctx* ctx) {
	return (struct gc_ctx*) ctx->gc_ctx_ptr;
}
uint8_t make_mut_arr_worker(struct ctx* ctx, struct mut_arr_1* m, uint64_t i, struct fun_mut1_5 f) {
	struct mut_arr_1* _tailCallm;
	uint64_t _tailCalli;
	struct fun_mut1_5 _tailCallf;
	top:
	if (_op_equal_equal_1(i, m->size)) {
		return 0;
	} else {
		set_at(ctx, m, i, call_8(ctx, f, i));
		_tailCallm = m;
		_tailCalli = incr_1(ctx, i);
		_tailCallf = f;
		m = _tailCallm;
		i = _tailCalli;
		f = _tailCallf;
		goto top;
	}
}
uint8_t set_at(struct ctx* ctx, struct mut_arr_1* a, uint64_t index, struct arr_0 value) {
	assert_0(ctx, _op_less_0(index, a->size));
	return noctx_set_at_0(a, index, value);
}
uint8_t noctx_set_at_0(struct mut_arr_1* a, uint64_t index, struct arr_0 value) {
	hard_assert(_op_less_0(index, a->size));
	return (*((a->data + index)) = value, 0);
}
struct arr_0 call_8(struct ctx* ctx, struct fun_mut1_5 f, uint64_t p0) {
	return call_with_ctx_6(ctx, f, p0);
}
struct arr_0 call_with_ctx_6(struct ctx* c, struct fun_mut1_5 f, uint64_t p0) {
	return f.fun_ptr(c, f.closure, p0);
}
uint64_t incr_1(struct ctx* ctx, uint64_t n) {
	assert_0(ctx, _op_less_0(n, billion()));
	return (n + 1);
}
struct arr_0 call_9(struct ctx* ctx, struct fun_mut1_4 f, char* p0) {
	return call_with_ctx_7(ctx, f, p0);
}
struct arr_0 call_with_ctx_7(struct ctx* c, struct fun_mut1_4 f, char* p0) {
	return f.fun_ptr(c, f.closure, p0);
}
char* at_1(struct ctx* ctx, struct arr_3 a, uint64_t index) {
	assert_0(ctx, _op_less_0(index, a.size));
	return noctx_at_2(a, index);
}
char* noctx_at_2(struct arr_3 a, uint64_t index) {
	hard_assert(_op_less_0(index, a.size));
	return (*((a.data + index)));
}
struct arr_0 map__lambda0(struct ctx* ctx, struct map__lambda0* _closure, uint64_t i) {
	return call_9(ctx, _closure->mapper, at_1(ctx, _closure->a, i));
}
struct arr_0 add_first_task__lambda0__lambda0(struct ctx* ctx, uint8_t* _closure, char* it) {
	return to_str_0(it);
}
struct fut_0* add_first_task__lambda0(struct ctx* ctx, struct add_first_task__lambda0* _closure) {
	struct arr_3 args0;
	args0 = tail_0(ctx, _closure->all_args);
	return _closure->main_ptr(ctx, map(ctx, args0, (struct fun_mut1_4) {(fun_ptr3_4) add_first_task__lambda0__lambda0, (uint8_t*) NULL}));
}
struct fut_0* do_main__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr_3 all_args, fun_ptr2_0 main_ptr) {
	return add_first_task(ctx, all_args, main_ptr);
}
struct fut_0* call_with_ctx_8(struct ctx* c, struct fun2 f, struct arr_3 p0, fun_ptr2_0 p1) {
	return f.fun_ptr(c, f.closure, p0, p1);
}
uint8_t run_threads(uint64_t n_threads, struct global_ctx* gctx) {
	uint64_t* threads0;
	struct thread_args* thread_args1;
	uint64_t actual_n_threads2;
	threads0 = unmanaged_alloc_elements_0(n_threads);
	thread_args1 = unmanaged_alloc_elements_1(n_threads);
	actual_n_threads2 = noctx_decr(n_threads);
	start_threads_recur(0, actual_n_threads2, threads0, thread_args1, gctx);
	thread_function(actual_n_threads2, gctx);
	join_threads_recur(0, actual_n_threads2, threads0);
	unmanaged_free_0(threads0);
	return unmanaged_free_1(thread_args1);
}
struct thread_args* unmanaged_alloc_elements_1(uint64_t size_elements) {
	uint8_t* bytes0;
	bytes0 = unmanaged_alloc_bytes((size_elements * sizeof(struct thread_args)));
	return (struct thread_args*) bytes0;
}
uint64_t noctx_decr(uint64_t n) {
	hard_forbid(zero__q_0(n));
	return (n - 1);
}
uint8_t start_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads, struct thread_args* thread_args_begin, struct global_ctx* gctx) {
	struct thread_args* thread_arg_ptr0;
	uint64_t* thread_ptr1;
	fun_ptr1 fn2;
	int32_t err3;
	uint64_t _tailCalli;
	uint64_t _tailCalln_threads;
	uint64_t* _tailCallthreads;
	struct thread_args* _tailCallthread_args_begin;
	struct global_ctx* _tailCallgctx;
	top:
	if (_op_equal_equal_1(i, n_threads)) {
		return 0;
	} else {
		thread_arg_ptr0 = (thread_args_begin + i);
		(*(thread_arg_ptr0) = thread_args(i, gctx), 0);
		thread_ptr1 = (threads + i);
		fn2 = start_threads_recur__lambda0;
		err3 = pthread_create(as_cell(thread_ptr1), NULL, fn2, (uint8_t*) thread_arg_ptr0);
		if (zero__q_1(err3)) {
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
			if (_op_equal_equal_3(err3, eagain())) {
				return todo_1();
			} else {
				return todo_1();
			}
		}
	}
}
struct thread_args thread_args(uint64_t thread_id, struct global_ctx* gctx) {
	return (struct thread_args) {thread_id, gctx};
}
uint8_t* thread_fun(uint8_t* args_ptr) {
	struct thread_args* args0;
	args0 = (struct thread_args*) args_ptr;
	thread_function(args0->thread_id, args0->gctx);
	return NULL;
}
uint8_t thread_function(uint64_t thread_id, struct global_ctx* gctx) {
	struct exception_ctx ectx0;
	struct thread_local_stuff tls1;
	ectx0 = new_exception_ctx();
	tls1 = thread_local_stuff((&(ectx0)));
	return thread_function_recur(thread_id, gctx, (&(tls1)));
}
uint8_t thread_function_recur(uint64_t thread_id, struct global_ctx* gctx, struct thread_local_stuff* tls) {
	uint64_t last_checked0;
	struct result_2 _matched3;
	struct ok_2 ok_chosen_task1;
	struct err_1 e2;
	uint64_t _tailCallthread_id;
	struct global_ctx* _tailCallgctx;
	struct thread_local_stuff* _tailCalltls;
	top:
	if (gctx->is_shut_down) {
		acquire_lock((&(gctx->lk)));
		(gctx->n_live_threads = noctx_decr(gctx->n_live_threads), 0);
		assert_vats_are_shut_down(0, gctx->vats);
		return release_lock((&(gctx->lk)));
	} else {
		hard_assert(_op_greater_0(gctx->n_live_threads, 0));
		last_checked0 = get_last_checked((&(gctx->may_be_work_to_do)));
		_matched3 = choose_task(gctx);
		switch (_matched3.kind) {
			case 0:
				ok_chosen_task1 = _matched3.as0;
				do_task(gctx, tls, ok_chosen_task1.value);
				break;
			case 1:
				e2 = _matched3.as1;
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
uint8_t assert_vats_are_shut_down(uint64_t i, struct arr_2 vats) {
	struct vat* vat0;
	uint64_t _tailCalli;
	struct arr_2 _tailCallvats;
	top:
	if (_op_equal_equal_1(i, vats.size)) {
		return 0;
	} else {
		vat0 = noctx_at_1(vats, i);
		acquire_lock((&(vat0->tasks_lock)));
		hard_forbid((&(vat0->gc))->needs_gc);
		hard_assert(zero__q_0(vat0->n_threads_running));
		hard_assert(empty__q_2((&(vat0->tasks))));
		release_lock((&(vat0->tasks_lock)));
		_tailCalli = noctx_incr(i);
		_tailCallvats = vats;
		i = _tailCalli;
		vats = _tailCallvats;
		goto top;
	}
}
uint8_t empty__q_2(struct mut_bag* m) {
	return empty__q_3(m->head);
}
uint8_t empty__q_3(struct opt_2 a) {
	struct opt_2 _matched2;
	struct none n0;
	struct some_2 s1;
	_matched2 = a;
	switch (_matched2.kind) {
		case 0:
			n0 = _matched2.as0;
			return 1;
		case 1:
			s1 = _matched2.as1;
			return 0;
		default:
			return (assert(0),0);
	}
}
uint8_t _op_greater_0(uint64_t a, uint64_t b) {
	return !_op_less_equal_0(a, b);
}
uint64_t get_last_checked(struct condition* c) {
	return c->value;
}
struct result_2 choose_task(struct global_ctx* gctx) {
	struct result_2 res2;
	struct opt_5 _matched1;
	struct some_5 s0;
	acquire_lock((&(gctx->lk)));
	res2 = (_matched1 = choose_task_recur(gctx->vats, 0), _matched1.kind == 0 ? (((gctx->n_live_threads = noctx_decr(gctx->n_live_threads), 0), hard_assert(zero__q_0(gctx->n_live_threads))), (struct result_2) {1, .as1 = err_1(no_chosen_task(zero__q_0(gctx->n_live_threads)))}) : _matched1.kind == 1 ? (s0 = _matched1.as1, (struct result_2) {0, .as0 = ok_2(s0.value)}) : (assert(0),(struct result_2) {0}));
	release_lock((&(gctx->lk)));
	return res2;
}
struct opt_5 choose_task_recur(struct arr_2 vats, uint64_t i) {
	struct vat* vat0;
	struct opt_6 _matched2;
	struct some_6 s1;
	struct arr_2 _tailCallvats;
	uint64_t _tailCalli;
	top:
	if (_op_equal_equal_1(i, vats.size)) {
		return (struct opt_5) {0, .as0 = none()};
	} else {
		vat0 = noctx_at_1(vats, i);
		_matched2 = choose_task_in_vat(vat0);
		switch (_matched2.kind) {
			case 0:
				_tailCallvats = vats;
				_tailCalli = noctx_incr(i);
				vats = _tailCallvats;
				i = _tailCalli;
				goto top;
			case 1:
				s1 = _matched2.as1;
				return (struct opt_5) {1, .as1 = some_6(chosen_task(vat0, s1.value))};
			default:
				return (assert(0),(struct opt_5) {0});
		}
	}
}
struct opt_6 choose_task_in_vat(struct vat* vat) {
	struct opt_6 res2;
	struct opt_4 _matched1;
	struct some_4 s0;
	acquire_lock((&(vat->tasks_lock)));
	res2 = ((&(vat->gc))->needs_gc ? (zero__q_0(vat->n_threads_running) ? (struct opt_6) {1, .as1 = some_3((struct opt_4) {0, .as0 = none()})} : (struct opt_6) {0, .as0 = none()}) : (_matched1 = find_and_remove_first_doable_task(vat), _matched1.kind == 0 ? (struct opt_6) {0, .as0 = none()} : _matched1.kind == 1 ? (s0 = _matched1.as1, (struct opt_6) {1, .as1 = some_3((struct opt_4) {1, .as1 = some_5(s0.value)})}) : (assert(0),(struct opt_6) {0})));
	if (empty__q_4(res2)) {
		0;
	} else {
		(vat->n_threads_running = noctx_incr(vat->n_threads_running), 0);
	}
	release_lock((&(vat->tasks_lock)));
	return res2;
}
struct some_6 some_3(struct opt_4 value) {
	return (struct some_6) {value};
}
struct opt_4 find_and_remove_first_doable_task(struct vat* vat) {
	struct mut_bag* tasks0;
	struct opt_2 th1;
	struct opt_7 res2;
	struct opt_7 _matched4;
	struct some_7 s3;
	tasks0 = (&(vat->tasks));
	th1 = tasks0->head;
	res2 = find_and_remove_first_doable_task_recur(vat, tasks0->head);
	_matched4 = res2;
	switch (_matched4.kind) {
		case 0:
			return (struct opt_4) {0, .as0 = none()};
		case 1:
			s3 = _matched4.as1;
			(tasks0->head = s3.value.nodes, 0);
			return (struct opt_4) {1, .as1 = some_5(s3.value.task)};
		default:
			return (assert(0),(struct opt_4) {0});
	}
}
struct opt_7 find_and_remove_first_doable_task_recur(struct vat* vat, struct opt_2 opt_node) {
	struct opt_2 _matched8;
	struct some_2 s0;
	struct mut_bag_node* node1;
	struct task task2;
	struct mut_arr_0* actors3;
	uint8_t task_ok4;
	struct opt_7 _matched7;
	struct some_7 ss5;
	struct task_and_nodes tn6;
	_matched8 = opt_node;
	switch (_matched8.kind) {
		case 0:
			return (struct opt_7) {0, .as0 = none()};
		case 1:
			s0 = _matched8.as1;
			node1 = s0.value;
			task2 = node1->value;
			actors3 = (&(vat->currently_running_actors));
			task_ok4 = (contains__q(actors3, task2.actor_id) ? 0 : (push_capacity_must_be_sufficient(actors3, task2.actor_id), 1));
			if (task_ok4) {
				return (struct opt_7) {1, .as1 = some_4(task_and_nodes(task2, node1->next_node))};
			} else {
				_matched7 = find_and_remove_first_doable_task_recur(vat, node1->next_node);
				switch (_matched7.kind) {
					case 0:
						return (struct opt_7) {0, .as0 = none()};
					case 1:
						ss5 = _matched7.as1;
						tn6 = ss5.value;
						(node1->next_node = tn6.nodes, 0);
						return (struct opt_7) {1, .as1 = some_4(task_and_nodes(tn6.task, (struct opt_2) {1, .as1 = some_2(node1)}))};
					default:
						return (assert(0),(struct opt_7) {0});
				}
			}
		default:
			return (assert(0),(struct opt_7) {0});
	}
}
uint8_t contains__q(struct mut_arr_0* a, uint64_t value) {
	return contains_recur__q(temp_as_arr(a), value, 0);
}
uint8_t contains_recur__q(struct arr_4 a, uint64_t value, uint64_t i) {
	struct arr_4 _tailCalla;
	uint64_t _tailCallvalue;
	uint64_t _tailCalli;
	top:
	if (_op_equal_equal_1(i, a.size)) {
		return 0;
	} else {
		if (_op_equal_equal_1(noctx_at_3(a, i), value)) {
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
uint64_t noctx_at_3(struct arr_4 a, uint64_t index) {
	hard_assert(_op_less_0(index, a.size));
	return (*((a.data + index)));
}
struct arr_4 temp_as_arr(struct mut_arr_0* a) {
	return arr_4(a->size, a->data);
}
struct arr_4 arr_4(uint64_t size, uint64_t* data) {
	return (struct arr_4) {size, data};
}
uint8_t push_capacity_must_be_sufficient(struct mut_arr_0* a, uint64_t value) {
	uint64_t old_size0;
	hard_assert(_op_less_0(a->size, a->capacity));
	old_size0 = a->size;
	(a->size = noctx_incr(old_size0), 0);
	return noctx_set_at_1(a, old_size0, value);
}
uint8_t noctx_set_at_1(struct mut_arr_0* a, uint64_t index, uint64_t value) {
	hard_assert(_op_less_0(index, a->size));
	return (*((a->data + index)) = value, 0);
}
struct some_7 some_4(struct task_and_nodes value) {
	return (struct some_7) {value};
}
struct task_and_nodes task_and_nodes(struct task task, struct opt_2 nodes) {
	return (struct task_and_nodes) {task, nodes};
}
struct some_4 some_5(struct task value) {
	return (struct some_4) {value};
}
uint8_t empty__q_4(struct opt_6 a) {
	struct opt_6 _matched2;
	struct none n0;
	struct some_6 s1;
	_matched2 = a;
	switch (_matched2.kind) {
		case 0:
			n0 = _matched2.as0;
			return 1;
		case 1:
			s1 = _matched2.as1;
			return 0;
		default:
			return (assert(0),0);
	}
}
struct some_5 some_6(struct chosen_task value) {
	return (struct some_5) {value};
}
struct chosen_task chosen_task(struct vat* vat, struct opt_4 task_or_gc) {
	return (struct chosen_task) {vat, task_or_gc};
}
struct err_1 err_1(struct no_chosen_task value) {
	return (struct err_1) {value};
}
struct no_chosen_task no_chosen_task(uint8_t last_thread_out) {
	return (struct no_chosen_task) {last_thread_out};
}
struct ok_2 ok_2(struct chosen_task value) {
	return (struct ok_2) {value};
}
uint8_t do_task(struct global_ctx* gctx, struct thread_local_stuff* tls, struct chosen_task chosen_task) {
	struct vat* vat0;
	struct opt_4 _matched4;
	struct some_4 some_task1;
	struct task task2;
	struct ctx ctx3;
	vat0 = chosen_task.vat;
	_matched4 = chosen_task.task_or_gc;
	switch (_matched4.kind) {
		case 0:
			todo_1();
			broadcast((&(gctx->may_be_work_to_do)));
			break;
		case 1:
			some_task1 = _matched4.as1;
			task2 = some_task1.value;
			ctx3 = new_ctx(gctx, tls, vat0, task2.actor_id);
			call_with_ctx_2((&(ctx3)), task2.fun);
			acquire_lock((&(vat0->tasks_lock)));
			noctx_must_remove_unordered((&(vat0->currently_running_actors)), task2.actor_id);
			release_lock((&(vat0->tasks_lock)));
			return_ctx((&(ctx3)));
			break;
		default:
			(assert(0),0);
	}
	acquire_lock((&(vat0->tasks_lock)));
	(vat0->n_threads_running = noctx_decr(vat0->n_threads_running), 0);
	return release_lock((&(vat0->tasks_lock)));
}
uint8_t noctx_must_remove_unordered(struct mut_arr_0* a, uint64_t value) {
	return noctx_must_remove_unordered_recur(a, 0, value);
}
uint8_t noctx_must_remove_unordered_recur(struct mut_arr_0* a, uint64_t index, uint64_t value) {
	struct mut_arr_0* _tailCalla;
	uint64_t _tailCallindex;
	uint64_t _tailCallvalue;
	top:
	if (_op_equal_equal_1(index, a->size)) {
		return (assert(0),0);
	} else {
		if (_op_equal_equal_1(noctx_at_4(a, index), value)) {
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
uint64_t noctx_at_4(struct mut_arr_0* a, uint64_t index) {
	hard_assert(_op_less_0(index, a->size));
	return (*((a->data + index)));
}
uint8_t drop_2(uint64_t t) {
	return 0;
}
uint64_t noctx_remove_unordered_at_index(struct mut_arr_0* a, uint64_t index) {
	uint64_t res0;
	res0 = noctx_at_4(a, index);
	noctx_set_at_1(a, index, noctx_last(a));
	(a->size = noctx_decr(a->size), 0);
	return res0;
}
uint64_t noctx_last(struct mut_arr_0* a) {
	hard_forbid(empty__q_5(a));
	return noctx_at_4(a, noctx_decr(a->size));
}
uint8_t empty__q_5(struct mut_arr_0* a) {
	return zero__q_0(a->size);
}
uint8_t return_ctx(struct ctx* c) {
	return return_gc_ctx((struct gc_ctx*) c->gc_ctx_ptr);
}
uint8_t return_gc_ctx(struct gc_ctx* gc_ctx) {
	struct gc* gc0;
	gc0 = gc_ctx->gc;
	acquire_lock((&(gc0->lk)));
	(gc_ctx->next_ctx = gc0->context_head, 0);
	(gc0->context_head = (struct opt_1) {1, .as1 = some_7(gc_ctx)}, 0);
	return release_lock((&(gc0->lk)));
}
struct some_1 some_7(struct gc_ctx* value) {
	return (struct some_1) {value};
}
uint8_t wait_on(struct condition* c, uint64_t last_checked) {
	struct condition* _tailCallc;
	uint64_t _tailCalllast_checked;
	top:
	if (_op_equal_equal_1(c->value, last_checked)) {
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
uint8_t* start_threads_recur__lambda0(uint8_t* args_ptr) {
	return thread_fun(args_ptr);
}
struct cell_0* as_cell(uint64_t* p) {
	return (struct cell_0*) (uint8_t*) p;
}
int32_t eagain() {
	return (ten_1() + 1);
}
int32_t ten_1() {
	return (five_1() + five_1());
}
uint8_t join_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads) {
	uint64_t _tailCalli;
	uint64_t _tailCalln_threads;
	uint64_t* _tailCallthreads;
	top:
	if (_op_equal_equal_1(i, n_threads)) {
		return 0;
	} else {
		join_one_thread((*((threads + i))));
		_tailCalli = noctx_incr(i);
		_tailCalln_threads = n_threads;
		_tailCallthreads = threads;
		i = _tailCalli;
		n_threads = _tailCalln_threads;
		threads = _tailCallthreads;
		goto top;
	}
}
uint8_t join_one_thread(uint64_t tid) {
	struct cell_1 thread_return0;
	int32_t err1;
	thread_return0 = cell(NULL);
	err1 = pthread_join(tid, (&(thread_return0)));
	if (zero__q_1(err1)) {
		0;
	} else {
		if (_op_equal_equal_3(err1, einval())) {
			todo_1();
		} else {
			if (_op_equal_equal_3(err1, esrch())) {
				todo_1();
			} else {
				todo_1();
			}
		}
	}
	return hard_assert(null__q_0(get((&(thread_return0)))));
}
struct cell_1 cell(uint8_t* value) {
	return (struct cell_1) {value};
}
int32_t einval() {
	return ((ten_1() + ten_1()) + two_0());
}
int32_t esrch() {
	return three_1();
}
uint8_t* get(struct cell_1* c) {
	return c->value;
}
uint8_t unmanaged_free_0(uint64_t* p) {
	return (free((uint8_t*) p), 0);
}
uint8_t unmanaged_free_1(struct thread_args* p) {
	return (free((uint8_t*) p), 0);
}
struct result_0 must_be_resolved(struct fut_0* f) {
	struct fut_state_0 _matched2;
	struct fut_state_resolved_0 r0;
	struct exception e1;
	_matched2 = f->state;
	switch (_matched2.kind) {
		case 0:
			return hard_unreachable();
		case 1:
			r0 = _matched2.as1;
			return (struct result_0) {0, .as0 = ok_1(r0.value)};
		case 2:
			e1 = _matched2.as2;
			return (struct result_0) {1, .as1 = err_0(e1)};
		default:
			return (assert(0),(struct result_0) {0});
	}
}
struct result_0 hard_unreachable() {
	return (assert(0),(struct result_0) {0});
}
struct fut_0* main_0(struct ctx* ctx, struct arr_1 args) {
	test_compare_records(ctx);
	test_compare_byref_records(ctx);
	test_compare_unions(ctx);
	return resolved_1(ctx, literal_2(ctx, (struct arr_0) {1, constantarr_0_13}));
}
uint8_t test_compare_records(struct ctx* ctx) {
	struct my_record a0;
	struct my_record b1;
	struct my_record c2;
	struct my_record d3;
	a0 = my_record(ctx, literal_1(ctx, (struct arr_0) {1, constantarr_0_14}), literal_1(ctx, (struct arr_0) {1, constantarr_0_15}));
	b1 = my_record(ctx, literal_1(ctx, (struct arr_0) {1, constantarr_0_14}), literal_1(ctx, (struct arr_0) {1, constantarr_0_16}));
	c2 = my_record(ctx, literal_1(ctx, (struct arr_0) {1, constantarr_0_14}), literal_1(ctx, (struct arr_0) {1, constantarr_0_15}));
	d3 = my_record(ctx, literal_1(ctx, (struct arr_0) {1, constantarr_0_13}), literal_1(ctx, (struct arr_0) {1, constantarr_0_16}));
	print_sync(to_str_1(ctx, compare_301(a0, b1)));
	print_sync(to_str_1(ctx, compare_301(a0, c2)));
	return print_sync(to_str_1(ctx, compare_301(a0, d3)));
}
struct my_record my_record(struct ctx* ctx, uint64_t x, uint64_t y) {
	return (struct my_record) {x, y};
}
uint64_t literal_1(struct ctx* ctx, struct arr_0 s) {
	uint64_t higher_digits0;
	if (empty__q_0(s)) {
		return 0;
	} else {
		higher_digits0 = literal_1(ctx, rtail(ctx, s));
		return _op_plus(ctx, _op_times_0(ctx, higher_digits0, ten_0()), char_to_nat(last(ctx, s)));
	}
}
struct arr_0 rtail(struct ctx* ctx, struct arr_0 a) {
	forbid_0(ctx, empty__q_0(a));
	return slice_1(ctx, a, 0, decr(ctx, a.size));
}
struct arr_0 slice_1(struct ctx* ctx, struct arr_0 a, uint64_t begin, uint64_t size) {
	assert_0(ctx, _op_less_equal_0(_op_plus(ctx, begin, size), a.size));
	return arr_0(size, (a.data + begin));
}
uint64_t decr(struct ctx* ctx, uint64_t a) {
	forbid_0(ctx, zero__q_0(a));
	return wrap_decr(a);
}
uint64_t wrap_decr(uint64_t a) {
	return (a - 1);
}
uint64_t _op_times_0(struct ctx* ctx, uint64_t a, uint64_t b) {
	uint64_t res0;
	if ((zero__q_0(a) || zero__q_0(b))) {
		return 0;
	} else {
		res0 = (a * b);
		assert_0(ctx, _op_equal_equal_1(_op_div(ctx, res0, b), a));
		assert_0(ctx, _op_equal_equal_1(_op_div(ctx, res0, a), b));
		return res0;
	}
}
uint64_t _op_div(struct ctx* ctx, uint64_t a, uint64_t b) {
	forbid_0(ctx, zero__q_0(b));
	return (a / b);
}
uint64_t char_to_nat(char c) {
	if (_op_equal_equal_0(c, literal_0((struct arr_0) {1, constantarr_0_13}))) {
		return 0;
	} else {
		if (_op_equal_equal_0(c, literal_0((struct arr_0) {1, constantarr_0_14}))) {
			return 1;
		} else {
			if (_op_equal_equal_0(c, literal_0((struct arr_0) {1, constantarr_0_15}))) {
				return two_1();
			} else {
				if (_op_equal_equal_0(c, literal_0((struct arr_0) {1, constantarr_0_16}))) {
					return three_0();
				} else {
					if (_op_equal_equal_0(c, literal_0((struct arr_0) {1, constantarr_0_17}))) {
						return four_0();
					} else {
						if (_op_equal_equal_0(c, literal_0((struct arr_0) {1, constantarr_0_18}))) {
							return five_0();
						} else {
							if (_op_equal_equal_0(c, literal_0((struct arr_0) {1, constantarr_0_19}))) {
								return six_0();
							} else {
								if (_op_equal_equal_0(c, literal_0((struct arr_0) {1, constantarr_0_20}))) {
									return seven_0();
								} else {
									if (_op_equal_equal_0(c, literal_0((struct arr_0) {1, constantarr_0_21}))) {
										return eight_0();
									} else {
										if (_op_equal_equal_0(c, literal_0((struct arr_0) {1, constantarr_0_22}))) {
											return nine_0();
										} else {
											return todo_2();
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
}
uint64_t todo_2() {
	return (assert(0),0);
}
char last(struct ctx* ctx, struct arr_0 a) {
	forbid_0(ctx, empty__q_0(a));
	return at_2(ctx, a, decr(ctx, a.size));
}
char at_2(struct ctx* ctx, struct arr_0 a, uint64_t index) {
	assert_0(ctx, _op_less_0(index, a.size));
	return noctx_at_0(a, index);
}
uint8_t print_sync(struct arr_0 s) {
	print_sync_no_newline(s);
	return print_sync_no_newline((struct arr_0) {1, constantarr_0_4});
}
uint8_t print_sync_no_newline(struct arr_0 s) {
	return write_sync_no_newline(stdout_fd(), s);
}
int32_t stdout_fd() {
	return 1;
}
struct arr_0 to_str_1(struct ctx* ctx, struct comparison c) {
	struct comparison _matched0;
	_matched0 = c;
	switch (_matched0.kind) {
		case 0:
			return (struct arr_0) {4, constantarr_0_23};
		case 1:
			return (struct arr_0) {5, constantarr_0_24};
		case 2:
			return (struct arr_0) {7, constantarr_0_25};
		default:
			return (assert(0),(struct arr_0) {0, NULL});
	}
}
struct comparison compare_301(struct my_record a, struct my_record b) {
	struct comparison temp0;
	struct comparison temp1;
	temp0 = compare_14(a.x, b.x);
	switch (temp0.kind) {
		case 0:
			return (struct comparison) {0, .as0 = (struct less) {0}};
		case 1:
			temp1 = compare_14(a.y, b.y);
			switch (temp1.kind) {
				case 0:
					return (struct comparison) {0, .as0 = (struct less) {0}};
				case 1:
					return (struct comparison) {1, .as1 = (struct equal) {0}};
				case 2:
					return (struct comparison) {2, .as2 = (struct greater) {0}};
				default:
					return (assert(0),(struct comparison) {0});
			}
		case 2:
			return (struct comparison) {2, .as2 = (struct greater) {0}};
		default:
			return (assert(0),(struct comparison) {0});
	}
}
uint8_t test_compare_byref_records(struct ctx* ctx) {
	struct my_byref_record* a0;
	struct my_byref_record* b1;
	struct my_byref_record* c2;
	struct my_byref_record* d3;
	a0 = my_byref_record(ctx, literal_1(ctx, (struct arr_0) {1, constantarr_0_14}), literal_1(ctx, (struct arr_0) {1, constantarr_0_15}));
	b1 = my_byref_record(ctx, literal_1(ctx, (struct arr_0) {1, constantarr_0_14}), literal_1(ctx, (struct arr_0) {1, constantarr_0_16}));
	c2 = my_byref_record(ctx, literal_1(ctx, (struct arr_0) {1, constantarr_0_14}), literal_1(ctx, (struct arr_0) {1, constantarr_0_15}));
	d3 = my_byref_record(ctx, literal_1(ctx, (struct arr_0) {1, constantarr_0_13}), literal_1(ctx, (struct arr_0) {1, constantarr_0_16}));
	print_sync(to_str_1(ctx, compare_304(a0, b1)));
	print_sync(to_str_1(ctx, compare_304(a0, c2)));
	return print_sync(to_str_1(ctx, compare_304(a0, d3)));
}
struct my_byref_record* my_byref_record(struct ctx* ctx, uint64_t x, uint64_t y) {
	struct my_byref_record* temp0;
	temp0 = (struct my_byref_record*) alloc(ctx, sizeof(struct my_byref_record));
	(*(temp0) = (struct my_byref_record) {x, y}, 0);
	return temp0;
}
struct comparison compare_304(struct my_byref_record* a, struct my_byref_record* b) {
	struct comparison temp0;
	struct comparison temp1;
	temp0 = compare_14(a->x, b->x);
	switch (temp0.kind) {
		case 0:
			return (struct comparison) {0, .as0 = (struct less) {0}};
		case 1:
			temp1 = compare_14(a->y, b->y);
			switch (temp1.kind) {
				case 0:
					return (struct comparison) {0, .as0 = (struct less) {0}};
				case 1:
					return (struct comparison) {1, .as1 = (struct equal) {0}};
				case 2:
					return (struct comparison) {2, .as2 = (struct greater) {0}};
				default:
					return (assert(0),(struct comparison) {0});
			}
		case 2:
			return (struct comparison) {2, .as2 = (struct greater) {0}};
		default:
			return (assert(0),(struct comparison) {0});
	}
}
uint8_t test_compare_unions(struct ctx* ctx) {
	struct my_union a0;
	struct my_union b1;
	struct my_union c2;
	struct my_union d3;
	a0 = (struct my_union) {0, .as0 = my_record(ctx, literal_1(ctx, (struct arr_0) {1, constantarr_0_14}), literal_1(ctx, (struct arr_0) {1, constantarr_0_15}))};
	b1 = (struct my_union) {1, .as1 = my_other_record()};
	c2 = (struct my_union) {0, .as0 = my_record(ctx, literal_1(ctx, (struct arr_0) {1, constantarr_0_14}), literal_1(ctx, (struct arr_0) {1, constantarr_0_15}))};
	d3 = (struct my_union) {0, .as0 = my_record(ctx, literal_1(ctx, (struct arr_0) {1, constantarr_0_14}), literal_1(ctx, (struct arr_0) {1, constantarr_0_14}))};
	print_sync(to_str_1(ctx, compare_307(a0, b1)));
	print_sync(to_str_1(ctx, compare_307(a0, c2)));
	return print_sync(to_str_1(ctx, compare_307(a0, d3)));
}
struct my_other_record my_other_record() {
	return (struct my_other_record) {0};
}
struct comparison compare_307(struct my_union a, struct my_union b) {
	struct my_union match_a0;
	struct my_record a0;
	struct my_union match_b0;
	struct my_record b0;
	struct my_other_record a1;
	struct my_union match_b1;
	struct my_other_record b1;
	match_a0 = a;
	switch (match_a0.kind) {
		case 0:
			a0 = match_a0.as0;
			match_b0 = b;
			switch (match_b0.kind) {
				case 0:
					b0 = match_b0.as0;
					return compare_301(a0, b0);
				case 1:
					return (struct comparison) {0, .as0 = (struct less) {0}};
				default:
					return (assert(0),(struct comparison) {0});
			}
		case 1:
			a1 = match_a0.as1;
			match_b1 = b;
			switch (match_b1.kind) {
				case 0:
					return (struct comparison) {2, .as2 = (struct greater) {0}};
				case 1:
					b1 = match_b1.as1;
					return compare_308(a1, b1);
				default:
					return (assert(0),(struct comparison) {0});
			}
		default:
			return (assert(0),(struct comparison) {0});
	}
}
struct comparison compare_308(struct my_other_record a, struct my_other_record b) {
	return (struct comparison) {1, .as1 = (struct equal) {0}};
}
struct fut_0* resolved_1(struct ctx* ctx, int32_t value) {
	return fut_0(ctx, new_lock(), (struct fut_state_0) {1, .as1 = fut_state_resolved_0(ctx, value)});
}
int32_t literal_2(struct ctx* ctx, struct arr_0 s) {
	return literal_3(ctx, s);
}
int64_t literal_3(struct ctx* ctx, struct arr_0 s) {
	char fst0;
	uint64_t n1;
	fst0 = at_2(ctx, s, 0);
	if (_op_equal_equal_0(fst0, literal_0((struct arr_0) {1, constantarr_0_26}))) {
		n1 = literal_1(ctx, tail_1(ctx, s));
		return neg_0(ctx, n1);
	} else {
		if (_op_equal_equal_0(fst0, literal_0((struct arr_0) {1, constantarr_0_27}))) {
			return to_int(ctx, literal_1(ctx, tail_1(ctx, s)));
		} else {
			return to_int(ctx, literal_1(ctx, s));
		}
	}
}
struct arr_0 tail_1(struct ctx* ctx, struct arr_0 a) {
	forbid_0(ctx, empty__q_0(a));
	return slice_starting_at_1(ctx, a, 1);
}
struct arr_0 slice_starting_at_1(struct ctx* ctx, struct arr_0 a, uint64_t begin) {
	assert_0(ctx, _op_less_equal_0(begin, a.size));
	return slice_1(ctx, a, begin, _op_minus_1(ctx, a.size, begin));
}
int64_t neg_0(struct ctx* ctx, uint64_t n) {
	return neg_1(ctx, to_int(ctx, n));
}
int64_t neg_1(struct ctx* ctx, int64_t i) {
	return _op_times_1(ctx, i, neg_one());
}
int64_t _op_times_1(struct ctx* ctx, int64_t a, int64_t b) {
	assert_0(ctx, _op_greater_1(a, neg_million()));
	assert_0(ctx, _op_less_1(a, million_1()));
	assert_0(ctx, _op_greater_1(b, neg_million()));
	assert_0(ctx, _op_less_1(b, million_1()));
	return (a * b);
}
uint8_t _op_greater_1(int64_t a, int64_t b) {
	return !_op_less_equal_1(a, b);
}
uint8_t _op_less_equal_1(int64_t a, int64_t b) {
	return !_op_less_1(b, a);
}
uint8_t _op_less_1(int64_t a, int64_t b) {
	struct comparison _matched0;
	_matched0 = compare_49(a, b);
	switch (_matched0.kind) {
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
int64_t neg_million() {
	return (million_1() * neg_one());
}
int64_t million_1() {
	return (thousand_1() * thousand_1());
}
int64_t thousand_1() {
	return (hundred_1() * ten_2());
}
int64_t hundred_1() {
	return (ten_2() * ten_2());
}
int64_t ten_2() {
	return wrap_incr_2(nine_1());
}
int64_t wrap_incr_2(int64_t a) {
	return (a + 1);
}
int64_t nine_1() {
	return wrap_incr_2(eight_1());
}
int64_t eight_1() {
	return wrap_incr_2(seven_2());
}
int64_t seven_2() {
	return wrap_incr_2(six_2());
}
int64_t six_2() {
	return wrap_incr_2(five_2());
}
int64_t five_2() {
	return wrap_incr_2(four_2());
}
int64_t four_2() {
	return wrap_incr_2(three_2());
}
int64_t three_2() {
	return wrap_incr_2(two_2());
}
int64_t two_2() {
	return wrap_incr_2(1);
}
int64_t neg_one() {
	return (0 - 1);
}
int64_t to_int(struct ctx* ctx, uint64_t n) {
	assert_0(ctx, _op_less_0(n, million_0()));
	return n;
}
int32_t main(int32_t argc, char** argv) {
	return rt_main(argc, argv, main_0);
}
