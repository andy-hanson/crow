#include <errno.h>
#include <stdatomic.h>
#include <stddef.h>
#include <stdint.h>

struct void_ {};
typedef uint8_t* (*fun_ptr1)(uint8_t*);
struct ctx;
struct thread_local_stuff;
struct lock;
struct _atomic_bool {
	uint8_t value;
};
struct mark_ctx {
	uint64_t memory_size_words;
	uint8_t* marks;
	uint64_t* memory_start;
};
struct less {
};
struct equal {
};
struct greater {
};
struct fut_0;
struct fut_state_no_callbacks {
};
struct fut_state_callbacks_0;
struct exception;
struct str;
struct arr_0 {
	uint64_t size;
	char* begin_ptr;
};
struct backtrace;
struct arr_1 {
	uint64_t size;
	struct str* begin_ptr;
};
struct ok_0 {
	uint64_t value;
};
struct err;
struct none {
};
struct some_0 {
	struct fut_state_callbacks_0* value;
};
struct fut_state_resolved_0 {
	uint64_t value;
};
struct global_ctx;
struct island;
struct gc;
struct gc_ctx;
struct some_1 {
	struct gc_ctx* value;
};
struct island_gc_root;
struct task_queue;
struct task_queue_node;
struct task;
struct some_2 {
	struct task_queue_node* value;
};
struct mut_list_0;
struct mut_arr_0;
struct arr_2 {
	uint64_t size;
	uint64_t* begin_ptr;
};
struct logged;
struct info {
};
struct warn {
};
struct error {
};
struct thread_safe_counter;
struct arr_3 {
	uint64_t size;
	struct island** begin_ptr;
};
struct condition;
struct pthread_mutexattr_t {
	uint32_t sizer;
};
struct pthread_mutex_t;
struct bytes40;
struct bytes32;
struct bytes16 {
	uint64_t n0;
	uint64_t n1;
};
struct pthread_condattr_t {
	uint32_t sizer;
};
struct pthread_cond_t;
struct bytes48;
struct writer;
struct mut_list_1;
struct mut_arr_1 {
	struct void_ ignore;
	struct arr_0 inner;
};
struct _concatEquals_1__lambda0 {
	struct mut_list_1* a;
};
struct exception_ctx;
struct jmp_buf_tag;
struct bytes64;
struct bytes128;
struct backtrace_arrs {
	uint8_t** code_ptrs;
	struct str* code_names;
	uint8_t** fun_ptrs;
	struct str* fun_names;
};
struct some_3 {
	struct backtrace_arrs* value;
};
struct some_4 {
	uint8_t** value;
};
struct some_5 {
	uint8_t* value;
};
struct some_6 {
	struct str* value;
};
struct arrow {
	uint64_t from;
	uint64_t to;
};
struct to_str_0__lambda0;
struct log_ctx;
struct perf_ctx;
struct measure_value {
	uint64_t count;
	uint64_t total_ns;
};
struct mut_arr_2;
struct arr_4 {
	uint64_t size;
	struct measure_value* begin_ptr;
};
struct arr_5 {
	uint64_t size;
	char** begin_ptr;
};
struct fut_1;
struct fut_state_callbacks_1;
struct ok_1 {
	struct void_ value;
};
struct some_7 {
	struct fut_state_callbacks_1* value;
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
struct callback__e_0__lambda0;
struct then__lambda0;
struct callback__e_1__lambda0;
struct forward_to__e__lambda0 {
	struct fut_0* to;
};
struct resolve_or_reject__e__lambda0;
struct subscript_10__lambda0;
struct subscript_10__lambda0__lambda0;
struct subscript_10__lambda0__lambda1 {
	struct fut_0* res;
};
struct then_void__lambda0;
struct subscript_15__lambda0;
struct subscript_15__lambda0__lambda0;
struct subscript_15__lambda0__lambda1 {
	struct fut_0* res;
};
struct add_first_task__lambda0;
struct map__lambda0;
struct some_8 {
	char* value;
};
struct thread_args {
	uint64_t thread_id;
	struct global_ctx* gctx;
};
struct cell_0 {
	uint64_t subscript;
};
struct chosen_task;
struct do_a_gc {
};
struct no_chosen_task;
struct some_9 {
	uint64_t value;
};
struct timespec {
	int64_t tv_sec;
	int64_t tv_nsec;
};
struct cell_1 {
	struct timespec subscript;
};
struct no_task;
struct cell_2 {
	uint8_t* subscript;
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
struct result_0;
struct fun_act1_0 {
	uint64_t kind;
	union {
		struct forward_to__e__lambda0* as0;
		struct void_ as1;
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
struct fun_act0_0 {
	uint64_t kind;
	union {
		struct callback__e_0__lambda0* as0;
		struct callback__e_1__lambda0* as1;
		struct subscript_10__lambda0__lambda0* as2;
		struct subscript_10__lambda0* as3;
		struct subscript_15__lambda0__lambda0* as4;
		struct subscript_15__lambda0* as5;
	};
};
struct opt_2 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_2 as1;
	};
};
struct fun1_0 {
	uint64_t kind;
	union {
		struct void_ as0;
	};
};
struct log_level {
	uint64_t kind;
	union {
		struct info as0;
		struct warn as1;
		struct error as2;
	};
};
struct fun1_1 {
	uint64_t kind;
	union {
		struct void_ as0;
	};
};
struct fun_act1_1 {
	uint64_t kind;
	union {
		struct _concatEquals_1__lambda0* as0;
	};
};
struct opt_3 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_3 as1;
	};
};
struct opt_4 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_4 as1;
	};
};
struct opt_5 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_5 as1;
	};
};
struct opt_6 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_6 as1;
	};
};
struct fun_act1_2 {
	uint64_t kind;
	union {
		struct to_str_0__lambda0* as0;
	};
};
struct fun_act2 {
	uint64_t kind;
	union {
		struct void_ as0;
	};
};
struct fut_state_1;
struct result_1;
struct fun_act1_3 {
	uint64_t kind;
	union {
		struct then__lambda0* as0;
	};
};
struct opt_7 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_7 as1;
	};
};
struct fun_act0_1 {
	uint64_t kind;
	union {
		struct add_first_task__lambda0* as0;
	};
};
struct fun_act1_4 {
	uint64_t kind;
	union {
		struct then_void__lambda0* as0;
	};
};
struct fun_act0_2 {
	uint64_t kind;
	union {
		struct resolve_or_reject__e__lambda0* as0;
	};
};
struct fun_act1_5 {
	uint64_t kind;
	union {
		struct subscript_10__lambda0__lambda1* as0;
		struct subscript_15__lambda0__lambda1* as1;
	};
};
struct fun_act1_6 {
	uint64_t kind;
	union {
		struct void_ as0;
	};
};
struct fun_act1_7 {
	uint64_t kind;
	union {
		struct map__lambda0* as0;
	};
};
struct opt_8 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_8 as1;
	};
};
struct choose_task_result;
struct task_or_gc;
struct opt_9 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_9 as1;
	};
};
struct choose_task_in_island_result;
struct pop_task_result;
typedef struct fut_0* (*fun_ptr2)(struct ctx*, struct arr_1);
struct ctx {
	uint8_t* gctx_ptr;
	uint64_t island_id;
	uint64_t exclusion;
	uint8_t* gc_ctx_ptr;
	struct thread_local_stuff* thread_local_stuff;
};
struct thread_local_stuff {
	uint64_t thread_id;
	struct lock* print_lock;
	uint8_t* exception_ctx_ptr;
	uint8_t* log_ctx_ptr;
	uint8_t* perf_ctx_ptr;
};
struct lock {
	struct _atomic_bool is_locked;
};
struct fut_0;
struct fut_state_callbacks_0 {
	struct fun_act1_0 cb;
	struct opt_0 next;
};
struct exception;
struct str {
	struct arr_0 chars;
};
struct backtrace {
	struct arr_1 return_stack;
};
struct err;
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
struct task_queue;
struct task_queue_node;
struct task {
	uint64_t time;
	uint64_t exclusion;
	struct fun_act0_0 action;
};
struct mut_list_0;
struct mut_arr_0 {
	struct void_ ignore;
	struct arr_2 inner;
};
struct logged {
	struct log_level level;
	struct str message;
};
struct thread_safe_counter {
	struct lock lk;
	uint64_t value;
};
struct condition;
struct pthread_mutex_t;
struct bytes40;
struct bytes32 {
	struct bytes16 n0;
	struct bytes16 n1;
};
struct pthread_cond_t;
struct bytes48 {
	struct bytes32 n0;
	struct bytes16 n1;
};
struct writer {
	struct mut_list_1* chars;
};
struct mut_list_1 {
	struct mut_arr_1 backing;
	uint64_t size;
};
struct exception_ctx;
struct jmp_buf_tag;
struct bytes64 {
	struct bytes32 n0;
	struct bytes32 n1;
};
struct bytes128 {
	struct bytes64 n0;
	struct bytes64 n1;
};
struct to_str_0__lambda0 {
	struct writer res;
};
struct log_ctx {
	struct fun1_1 handler;
};
struct perf_ctx;
struct mut_arr_2 {
	struct void_ ignore;
	struct arr_4 inner;
};
struct fut_1;
struct fut_state_callbacks_1 {
	struct fun_act1_3 cb;
	struct opt_7 next;
};
struct fun_ref0 {
	struct island_and_exclusion island_and_exclusion;
	struct fun_act0_1 fun;
};
struct fun_ref1 {
	struct island_and_exclusion island_and_exclusion;
	struct fun_act1_4 fun;
};
struct callback__e_0__lambda0 {
	struct fut_1* f;
	struct fun_act1_3 cb;
};
struct then__lambda0 {
	struct fun_ref1 cb;
	struct fut_0* res;
};
struct callback__e_1__lambda0 {
	struct fut_0* f;
	struct fun_act1_0 cb;
};
struct resolve_or_reject__e__lambda0;
struct subscript_10__lambda0 {
	struct fun_ref1 f;
	struct void_ p0;
	struct fut_0* res;
};
struct subscript_10__lambda0__lambda0 {
	struct fun_ref1 f;
	struct void_ p0;
	struct fut_0* res;
};
struct then_void__lambda0 {
	struct fun_ref0 cb;
};
struct subscript_15__lambda0 {
	struct fun_ref0 f;
	struct fut_0* res;
};
struct subscript_15__lambda0__lambda0 {
	struct fun_ref0 f;
	struct fut_0* res;
};
struct add_first_task__lambda0 {
	struct arr_5 all_args;
	fun_ptr2 main_ptr;
};
struct map__lambda0 {
	struct fun_act1_6 f;
	struct arr_5 a;
};
struct chosen_task;
struct no_chosen_task {
	uint8_t no_tasks_and_last_thread_out__q;
	struct opt_9 first_task_time;
};
struct no_task {
	uint8_t any_tasks__q;
	struct opt_9 first_task_time;
};
struct fut_state_0;
struct result_0;
struct fut_state_1;
struct result_1;
struct choose_task_result;
struct task_or_gc {
	uint64_t kind;
	union {
		struct task as0;
		struct do_a_gc as1;
	};
};
struct choose_task_in_island_result {
	uint64_t kind;
	union {
		struct task as0;
		struct do_a_gc as1;
		struct no_task as2;
	};
};
struct pop_task_result {
	uint64_t kind;
	union {
		struct task as0;
		struct no_task as1;
	};
};
struct fut_0;
struct exception {
	struct str message;
	struct backtrace backtrace;
};
struct err {
	struct exception value;
};
struct global_ctx;
struct island;
struct island_gc_root;
struct task_queue;
struct task_queue_node {
	struct task task;
	struct opt_2 next;
};
struct mut_list_0 {
	struct mut_arr_0 backing;
	uint64_t size;
};
struct condition;
struct pthread_mutex_t;
struct bytes40 {
	struct bytes32 n0;
	uint64_t n1;
};
struct pthread_cond_t {
	struct bytes48 sizer;
};
struct exception_ctx {
	struct jmp_buf_tag* jmp_buf_ptr;
	struct exception thrown_exception;
};
struct jmp_buf_tag {
	struct bytes64 jmp_buf;
	int32_t mask_was_saved;
	struct bytes128 saved_mask;
};
struct perf_ctx {
	struct arr_1 measure_names;
	struct mut_arr_2 measure_values;
};
struct fut_1;
struct resolve_or_reject__e__lambda0;
struct chosen_task {
	struct island* task_island;
	struct task_or_gc task_or_gc;
};
struct fut_state_0 {
	uint64_t kind;
	union {
		struct fut_state_no_callbacks as0;
		struct fut_state_callbacks_0* as1;
		struct fut_state_resolved_0 as2;
		struct exception as3;
	};
};
struct result_0 {
	uint64_t kind;
	union {
		struct ok_0 as0;
		struct err as1;
	};
};
struct fut_state_1 {
	uint64_t kind;
	union {
		struct fut_state_no_callbacks as0;
		struct fut_state_callbacks_1* as1;
		struct fut_state_resolved_1 as2;
		struct exception as3;
	};
};
struct result_1 {
	uint64_t kind;
	union {
		struct ok_1 as0;
		struct err as1;
	};
};
struct choose_task_result {
	uint64_t kind;
	union {
		struct chosen_task as0;
		struct no_chosen_task as1;
	};
};
struct fut_0 {
	struct lock lk;
	struct fut_state_0 state;
};
struct global_ctx;
struct island;
struct island_gc_root;
struct task_queue {
	struct opt_2 head;
	struct mut_list_0 currently_running_exclusions;
};
struct condition;
struct pthread_mutex_t {
	struct bytes40 sizer;
};
struct fut_1 {
	struct lock lk;
	struct fut_state_1 state;
};
struct resolve_or_reject__e__lambda0 {
	struct fut_0* f;
	struct result_0 result;
};
struct global_ctx;
struct island;
struct island_gc_root {
	struct task_queue tasks;
	struct fun1_0 exception_handler;
	struct fun1_1 log_handler;
};
struct condition {
	struct pthread_mutexattr_t mutex_attr;
	struct pthread_mutex_t mutex;
	struct pthread_condattr_t cond_attr;
	struct pthread_cond_t cond;
	uint64_t sequence;
};
struct global_ctx {
	struct lock lk;
	struct lock print_lock;
	struct arr_3 islands;
	uint64_t n_live_threads;
	struct condition may_be_work_to_do;
	uint8_t shut_down__q;
	uint8_t any_unhandled_exceptions__q;
};
struct island {
	struct global_ctx* gctx;
	uint64_t id;
	struct gc gc;
	struct island_gc_root gc_root;
	struct lock tasks_lock;
	uint64_t n_threads_running;
	struct thread_safe_counter next_exclusion;
};

_Static_assert(sizeof(struct ctx) == 40, "");
_Static_assert(sizeof(struct thread_local_stuff) == 40, "");
_Static_assert(sizeof(struct lock) == 1, "");
_Static_assert(sizeof(struct _atomic_bool) == 1, "");
_Static_assert(sizeof(struct mark_ctx) == 24, "");
_Static_assert(sizeof(struct less) == 0, "");
_Static_assert(sizeof(struct equal) == 0, "");
_Static_assert(sizeof(struct greater) == 0, "");
_Static_assert(sizeof(struct fut_0) == 48, "");
_Static_assert(sizeof(struct fut_state_no_callbacks) == 0, "");
_Static_assert(sizeof(struct fut_state_callbacks_0) == 32, "");
_Static_assert(sizeof(struct exception) == 32, "");
_Static_assert(sizeof(struct str) == 16, "");
_Static_assert(sizeof(struct arr_0) == 16, "");
_Static_assert(sizeof(struct backtrace) == 16, "");
_Static_assert(sizeof(struct arr_1) == 16, "");
_Static_assert(sizeof(struct ok_0) == 8, "");
_Static_assert(sizeof(struct err) == 32, "");
_Static_assert(sizeof(struct none) == 0, "");
_Static_assert(sizeof(struct some_0) == 8, "");
_Static_assert(sizeof(struct fut_state_resolved_0) == 8, "");
_Static_assert(sizeof(struct global_ctx) == 152, "");
_Static_assert(sizeof(struct island) == 200, "");
_Static_assert(sizeof(struct gc) == 96, "");
_Static_assert(sizeof(struct gc_ctx) == 24, "");
_Static_assert(sizeof(struct some_1) == 8, "");
_Static_assert(sizeof(struct island_gc_root) == 56, "");
_Static_assert(sizeof(struct task_queue) == 40, "");
_Static_assert(sizeof(struct task_queue_node) == 48, "");
_Static_assert(sizeof(struct task) == 32, "");
_Static_assert(sizeof(struct some_2) == 8, "");
_Static_assert(sizeof(struct mut_list_0) == 24, "");
_Static_assert(sizeof(struct mut_arr_0) == 16, "");
_Static_assert(sizeof(struct arr_2) == 16, "");
_Static_assert(sizeof(struct logged) == 24, "");
_Static_assert(sizeof(struct info) == 0, "");
_Static_assert(sizeof(struct warn) == 0, "");
_Static_assert(sizeof(struct error) == 0, "");
_Static_assert(sizeof(struct thread_safe_counter) == 16, "");
_Static_assert(sizeof(struct arr_3) == 16, "");
_Static_assert(sizeof(struct condition) == 112, "");
_Static_assert(sizeof(struct pthread_mutexattr_t) == 4, "");
_Static_assert(sizeof(struct pthread_mutex_t) == 40, "");
_Static_assert(sizeof(struct bytes40) == 40, "");
_Static_assert(sizeof(struct bytes32) == 32, "");
_Static_assert(sizeof(struct bytes16) == 16, "");
_Static_assert(sizeof(struct pthread_condattr_t) == 4, "");
_Static_assert(sizeof(struct pthread_cond_t) == 48, "");
_Static_assert(sizeof(struct bytes48) == 48, "");
_Static_assert(sizeof(struct writer) == 8, "");
_Static_assert(sizeof(struct mut_list_1) == 24, "");
_Static_assert(sizeof(struct mut_arr_1) == 16, "");
_Static_assert(sizeof(struct _concatEquals_1__lambda0) == 8, "");
_Static_assert(sizeof(struct exception_ctx) == 40, "");
_Static_assert(sizeof(struct jmp_buf_tag) == 200, "");
_Static_assert(sizeof(struct bytes64) == 64, "");
_Static_assert(sizeof(struct bytes128) == 128, "");
_Static_assert(sizeof(struct backtrace_arrs) == 32, "");
_Static_assert(sizeof(struct some_3) == 8, "");
_Static_assert(sizeof(struct some_4) == 8, "");
_Static_assert(sizeof(struct some_5) == 8, "");
_Static_assert(sizeof(struct some_6) == 8, "");
_Static_assert(sizeof(struct arrow) == 16, "");
_Static_assert(sizeof(struct to_str_0__lambda0) == 8, "");
_Static_assert(sizeof(struct log_ctx) == 8, "");
_Static_assert(sizeof(struct perf_ctx) == 32, "");
_Static_assert(sizeof(struct measure_value) == 16, "");
_Static_assert(sizeof(struct mut_arr_2) == 16, "");
_Static_assert(sizeof(struct arr_4) == 16, "");
_Static_assert(sizeof(struct arr_5) == 16, "");
_Static_assert(sizeof(struct fut_1) == 48, "");
_Static_assert(sizeof(struct fut_state_callbacks_1) == 32, "");
_Static_assert(sizeof(struct ok_1) == 0, "");
_Static_assert(sizeof(struct some_7) == 8, "");
_Static_assert(sizeof(struct fut_state_resolved_1) == 0, "");
_Static_assert(sizeof(struct fun_ref0) == 32, "");
_Static_assert(sizeof(struct island_and_exclusion) == 16, "");
_Static_assert(sizeof(struct fun_ref1) == 32, "");
_Static_assert(sizeof(struct callback__e_0__lambda0) == 24, "");
_Static_assert(sizeof(struct then__lambda0) == 40, "");
_Static_assert(sizeof(struct callback__e_1__lambda0) == 24, "");
_Static_assert(sizeof(struct forward_to__e__lambda0) == 8, "");
_Static_assert(sizeof(struct resolve_or_reject__e__lambda0) == 48, "");
_Static_assert(sizeof(struct subscript_10__lambda0) == 40, "");
_Static_assert(sizeof(struct subscript_10__lambda0__lambda0) == 40, "");
_Static_assert(sizeof(struct subscript_10__lambda0__lambda1) == 8, "");
_Static_assert(sizeof(struct then_void__lambda0) == 32, "");
_Static_assert(sizeof(struct subscript_15__lambda0) == 40, "");
_Static_assert(sizeof(struct subscript_15__lambda0__lambda0) == 40, "");
_Static_assert(sizeof(struct subscript_15__lambda0__lambda1) == 8, "");
_Static_assert(sizeof(struct add_first_task__lambda0) == 24, "");
_Static_assert(sizeof(struct map__lambda0) == 24, "");
_Static_assert(sizeof(struct some_8) == 8, "");
_Static_assert(sizeof(struct thread_args) == 16, "");
_Static_assert(sizeof(struct cell_0) == 8, "");
_Static_assert(sizeof(struct chosen_task) == 48, "");
_Static_assert(sizeof(struct do_a_gc) == 0, "");
_Static_assert(sizeof(struct no_chosen_task) == 24, "");
_Static_assert(sizeof(struct some_9) == 8, "");
_Static_assert(sizeof(struct timespec) == 16, "");
_Static_assert(sizeof(struct cell_1) == 16, "");
_Static_assert(sizeof(struct no_task) == 24, "");
_Static_assert(sizeof(struct cell_2) == 8, "");
_Static_assert(sizeof(struct comparison) == 8, "");
_Static_assert(sizeof(struct fut_state_0) == 40, "");
_Static_assert(sizeof(struct result_0) == 40, "");
_Static_assert(sizeof(struct fun_act1_0) == 16, "");
_Static_assert(sizeof(struct opt_0) == 16, "");
_Static_assert(sizeof(struct opt_1) == 16, "");
_Static_assert(sizeof(struct fun_act0_0) == 16, "");
_Static_assert(sizeof(struct opt_2) == 16, "");
_Static_assert(sizeof(struct fun1_0) == 8, "");
_Static_assert(sizeof(struct log_level) == 8, "");
_Static_assert(sizeof(struct fun1_1) == 8, "");
_Static_assert(sizeof(struct fun_act1_1) == 16, "");
_Static_assert(sizeof(struct opt_3) == 16, "");
_Static_assert(sizeof(struct opt_4) == 16, "");
_Static_assert(sizeof(struct opt_5) == 16, "");
_Static_assert(sizeof(struct opt_6) == 16, "");
_Static_assert(sizeof(struct fun_act1_2) == 16, "");
_Static_assert(sizeof(struct fun_act2) == 8, "");
_Static_assert(sizeof(struct fut_state_1) == 40, "");
_Static_assert(sizeof(struct result_1) == 40, "");
_Static_assert(sizeof(struct fun_act1_3) == 16, "");
_Static_assert(sizeof(struct opt_7) == 16, "");
_Static_assert(sizeof(struct fun_act0_1) == 16, "");
_Static_assert(sizeof(struct fun_act1_4) == 16, "");
_Static_assert(sizeof(struct fun_act0_2) == 16, "");
_Static_assert(sizeof(struct fun_act1_5) == 16, "");
_Static_assert(sizeof(struct fun_act1_6) == 8, "");
_Static_assert(sizeof(struct fun_act1_7) == 16, "");
_Static_assert(sizeof(struct opt_8) == 16, "");
_Static_assert(sizeof(struct choose_task_result) == 56, "");
_Static_assert(sizeof(struct task_or_gc) == 40, "");
_Static_assert(sizeof(struct opt_9) == 16, "");
_Static_assert(sizeof(struct choose_task_in_island_result) == 40, "");
_Static_assert(sizeof(struct pop_task_result) == 40, "");
char constantarr_0_0[20];
char constantarr_0_1[1];
char constantarr_0_2[11];
char constantarr_0_3[13];
char constantarr_0_4[13];
char constantarr_0_5[17];
char constantarr_0_6[5];
char constantarr_0_7[4];
char constantarr_0_8[4];
char constantarr_0_9[5];
char constantarr_0_10[2];
char constantarr_0_11[13];
char constantarr_0_12[4];
char constantarr_0_13[11];
char constantarr_0_14[4];
char constantarr_0_15[6];
char constantarr_0_16[13];
char constantarr_0_17[2];
char constantarr_0_18[8];
char constantarr_0_19[12];
char constantarr_0_20[14];
char constantarr_0_21[10];
char constantarr_0_22[25];
char constantarr_0_23[8];
char constantarr_0_24[8];
char constantarr_0_25[19];
char constantarr_0_26[6];
char constantarr_0_27[8];
char constantarr_0_28[10];
char constantarr_0_29[11];
char constantarr_0_30[12];
char constantarr_0_31[3];
char constantarr_0_32[13];
char constantarr_0_33[5];
char constantarr_0_34[4];
char constantarr_0_35[5];
char constantarr_0_36[7];
char constantarr_0_37[6];
char constantarr_0_38[4];
char constantarr_0_39[5];
char constantarr_0_40[17];
char constantarr_0_41[7];
char constantarr_0_42[3];
char constantarr_0_43[7];
char constantarr_0_44[5];
char constantarr_0_45[16];
char constantarr_0_46[13];
char constantarr_0_47[2];
char constantarr_0_48[15];
char constantarr_0_49[19];
char constantarr_0_50[6];
char constantarr_0_51[7];
char constantarr_0_52[10];
char constantarr_0_53[22];
char constantarr_0_54[10];
char constantarr_0_55[11];
char constantarr_0_56[4];
char constantarr_0_57[11];
char constantarr_0_58[16];
char constantarr_0_59[21];
char constantarr_0_60[9];
char constantarr_0_61[35];
char constantarr_0_62[31];
char constantarr_0_63[34];
char constantarr_0_64[30];
char constantarr_0_65[23];
char constantarr_0_66[22];
char constantarr_0_67[31];
char constantarr_0_68[10];
char constantarr_0_69[21];
char constantarr_0_70[18];
char constantarr_0_71[27];
char constantarr_0_72[5];
char constantarr_0_73[21];
char constantarr_0_74[30];
char constantarr_0_75[9];
char constantarr_0_76[25];
char constantarr_0_77[15];
char constantarr_0_78[17];
char constantarr_0_79[26];
char constantarr_0_80[4];
char constantarr_0_81[22];
char constantarr_0_82[6];
char constantarr_0_83[10];
char constantarr_0_84[4];
char constantarr_0_85[56];
char constantarr_0_86[11];
char constantarr_0_87[7];
char constantarr_0_88[35];
char constantarr_0_89[28];
char constantarr_0_90[21];
char constantarr_0_91[6];
char constantarr_0_92[11];
char constantarr_0_93[11];
char constantarr_0_94[11];
char constantarr_0_95[8];
char constantarr_0_96[8];
char constantarr_0_97[18];
char constantarr_0_98[6];
char constantarr_0_99[19];
char constantarr_0_100[12];
char constantarr_0_101[26];
char constantarr_0_102[14];
char constantarr_0_103[25];
char constantarr_0_104[20];
char constantarr_0_105[16];
char constantarr_0_106[13];
char constantarr_0_107[13];
char constantarr_0_108[5];
char constantarr_0_109[21];
char constantarr_0_110[15];
char constantarr_0_111[5];
char constantarr_0_112[10];
char constantarr_0_113[10];
char constantarr_0_114[7];
char constantarr_0_115[13];
char constantarr_0_116[10];
char constantarr_0_117[10];
char constantarr_0_118[6];
char constantarr_0_119[9];
char constantarr_0_120[6];
char constantarr_0_121[6];
char constantarr_0_122[14];
char constantarr_0_123[2];
char constantarr_0_124[8];
char constantarr_0_125[8];
char constantarr_0_126[14];
char constantarr_0_127[19];
char constantarr_0_128[22];
char constantarr_0_129[7];
char constantarr_0_130[13];
char constantarr_0_131[5];
char constantarr_0_132[11];
char constantarr_0_133[6];
char constantarr_0_134[18];
char constantarr_0_135[19];
char constantarr_0_136[12];
char constantarr_0_137[8];
char constantarr_0_138[9];
char constantarr_0_139[11];
char constantarr_0_140[25];
char constantarr_0_141[6];
char constantarr_0_142[11];
char constantarr_0_143[9];
char constantarr_0_144[17];
char constantarr_0_145[21];
char constantarr_0_146[17];
char constantarr_0_147[18];
char constantarr_0_148[18];
char constantarr_0_149[11];
char constantarr_0_150[20];
char constantarr_0_151[7];
char constantarr_0_152[15];
char constantarr_0_153[20];
char constantarr_0_154[9];
char constantarr_0_155[13];
char constantarr_0_156[24];
char constantarr_0_157[34];
char constantarr_0_158[9];
char constantarr_0_159[12];
char constantarr_0_160[8];
char constantarr_0_161[14];
char constantarr_0_162[12];
char constantarr_0_163[8];
char constantarr_0_164[11];
char constantarr_0_165[23];
char constantarr_0_166[12];
char constantarr_0_167[5];
char constantarr_0_168[23];
char constantarr_0_169[9];
char constantarr_0_170[12];
char constantarr_0_171[13];
char constantarr_0_172[16];
char constantarr_0_173[2];
char constantarr_0_174[18];
char constantarr_0_175[8];
char constantarr_0_176[6];
char constantarr_0_177[14];
char constantarr_0_178[8];
char constantarr_0_179[11];
char constantarr_0_180[8];
char constantarr_0_181[12];
char constantarr_0_182[12];
char constantarr_0_183[15];
char constantarr_0_184[19];
char constantarr_0_185[8];
char constantarr_0_186[11];
char constantarr_0_187[10];
char constantarr_0_188[6];
char constantarr_0_189[2];
char constantarr_0_190[10];
char constantarr_0_191[14];
char constantarr_0_192[10];
char constantarr_0_193[13];
char constantarr_0_194[18];
char constantarr_0_195[28];
char constantarr_0_196[10];
char constantarr_0_197[20];
char constantarr_0_198[14];
char constantarr_0_199[9];
char constantarr_0_200[12];
char constantarr_0_201[13];
char constantarr_0_202[6];
char constantarr_0_203[9];
char constantarr_0_204[15];
char constantarr_0_205[14];
char constantarr_0_206[25];
char constantarr_0_207[7];
char constantarr_0_208[24];
char constantarr_0_209[17];
char constantarr_0_210[11];
char constantarr_0_211[18];
char constantarr_0_212[12];
char constantarr_0_213[8];
char constantarr_0_214[9];
char constantarr_0_215[13];
char constantarr_0_216[15];
char constantarr_0_217[9];
char constantarr_0_218[24];
char constantarr_0_219[15];
char constantarr_0_220[10];
char constantarr_0_221[21];
char constantarr_0_222[14];
char constantarr_0_223[8];
char constantarr_0_224[13];
char constantarr_0_225[15];
char constantarr_0_226[25];
char constantarr_0_227[23];
char constantarr_0_228[5];
char constantarr_0_229[8];
char constantarr_0_230[15];
char constantarr_0_231[18];
char constantarr_0_232[6];
char constantarr_0_233[21];
char constantarr_0_234[14];
char constantarr_0_235[12];
char constantarr_0_236[12];
char constantarr_0_237[13];
char constantarr_0_238[1];
char constantarr_0_239[3];
char constantarr_0_240[7];
char constantarr_0_241[24];
char constantarr_0_242[30];
char constantarr_0_243[1];
char constantarr_0_244[1];
char constantarr_0_245[6];
char constantarr_0_246[12];
char constantarr_0_247[16];
char constantarr_0_248[6];
char constantarr_0_249[6];
char constantarr_0_250[12];
char constantarr_0_251[7];
char constantarr_0_252[9];
char constantarr_0_253[12];
char constantarr_0_254[14];
char constantarr_0_255[12];
char constantarr_0_256[3];
char constantarr_0_257[18];
char constantarr_0_258[29];
char constantarr_0_259[14];
char constantarr_0_260[18];
char constantarr_0_261[8];
char constantarr_0_262[14];
char constantarr_0_263[19];
char constantarr_0_264[5];
char constantarr_0_265[16];
char constantarr_0_266[6];
char constantarr_0_267[1];
char constantarr_0_268[7];
char constantarr_0_269[5];
char constantarr_0_270[14];
char constantarr_0_271[20];
char constantarr_0_272[21];
char constantarr_0_273[14];
char constantarr_0_274[11];
char constantarr_0_275[10];
char constantarr_0_276[10];
char constantarr_0_277[18];
char constantarr_0_278[13];
char constantarr_0_279[8];
char constantarr_0_280[17];
char constantarr_0_281[7];
char constantarr_0_282[10];
char constantarr_0_283[14];
char constantarr_0_284[19];
char constantarr_0_285[18];
char constantarr_0_286[11];
char constantarr_0_287[11];
char constantarr_0_288[14];
char constantarr_0_289[13];
char constantarr_0_290[13];
char constantarr_0_291[7];
char constantarr_0_292[26];
char constantarr_0_293[8];
char constantarr_0_294[22];
char constantarr_0_295[25];
char constantarr_0_296[25];
char constantarr_0_297[19];
char constantarr_0_298[19];
char constantarr_0_299[20];
char constantarr_0_300[20];
char constantarr_0_301[10];
char constantarr_0_302[30];
char constantarr_0_303[3];
char constantarr_0_304[12];
char constantarr_0_305[23];
char constantarr_0_306[6];
char constantarr_0_307[12];
char constantarr_0_308[16];
char constantarr_0_309[8];
char constantarr_0_310[11];
char constantarr_0_311[15];
char constantarr_0_312[11];
char constantarr_0_313[11];
char constantarr_0_314[26];
char constantarr_0_315[7];
char constantarr_0_316[22];
char constantarr_0_317[2];
char constantarr_0_318[18];
char constantarr_0_319[30];
char constantarr_0_320[15];
char constantarr_0_321[73];
char constantarr_0_322[14];
char constantarr_0_323[14];
char constantarr_0_324[16];
char constantarr_0_325[16];
char constantarr_0_326[7];
char constantarr_0_327[22];
char constantarr_0_328[14];
char constantarr_0_329[15];
char constantarr_0_330[17];
char constantarr_0_331[6];
char constantarr_0_332[9];
char constantarr_0_333[13];
char constantarr_0_334[23];
char constantarr_0_335[29];
char constantarr_0_336[38];
char constantarr_0_337[6];
char constantarr_0_338[9];
char constantarr_0_339[14];
char constantarr_0_340[22];
char constantarr_0_341[17];
char constantarr_0_342[13];
char constantarr_0_343[21];
char constantarr_0_344[22];
char constantarr_0_345[24];
char constantarr_0_346[22];
char constantarr_0_347[16];
char constantarr_0_348[30];
char constantarr_0_349[19];
char constantarr_0_350[6];
char constantarr_0_351[8];
char constantarr_0_352[25];
char constantarr_0_353[20];
char constantarr_0_354[10];
char constantarr_0_355[17];
char constantarr_0_356[13];
char constantarr_0_357[7];
char constantarr_0_358[29];
char constantarr_0_359[8];
char constantarr_0_360[15];
char constantarr_0_361[4];
char constantarr_0_362[10];
char constantarr_0_363[12];
char constantarr_0_364[4];
char constantarr_0_365[10];
char constantarr_0_366[4];
char constantarr_0_367[4];
char constantarr_0_368[8];
char constantarr_0_369[21];
char constantarr_0_370[4];
char constantarr_0_371[12];
char constantarr_0_372[8];
char constantarr_0_373[5];
char constantarr_0_374[22];
char constantarr_0_375[10];
char constantarr_0_376[18];
char constantarr_0_377[22];
char constantarr_0_378[12];
char constantarr_0_379[8];
char constantarr_0_380[20];
char constantarr_0_381[17];
char constantarr_0_382[4];
char constantarr_0_383[12];
char constantarr_0_384[9];
char constantarr_0_385[11];
char constantarr_0_386[28];
char constantarr_0_387[16];
char constantarr_0_388[11];
char constantarr_0_389[4];
char constantarr_0_390[7];
char constantarr_0_391[7];
char constantarr_0_392[7];
char constantarr_0_393[8];
char constantarr_0_394[15];
char constantarr_0_395[19];
char constantarr_0_396[6];
char constantarr_0_397[24];
char constantarr_0_398[23];
char constantarr_0_399[12];
char constantarr_0_400[36];
char constantarr_0_401[11];
char constantarr_0_402[36];
char constantarr_0_403[28];
char constantarr_0_404[10];
char constantarr_0_405[24];
char constantarr_0_406[15];
char constantarr_0_407[24];
char constantarr_0_408[18];
char constantarr_0_409[7];
char constantarr_0_410[31];
char constantarr_0_411[31];
char constantarr_0_412[23];
char constantarr_0_413[22];
char constantarr_0_414[24];
char constantarr_0_415[20];
char constantarr_0_416[9];
char constantarr_0_417[5];
char constantarr_0_418[14];
char constantarr_0_419[15];
char constantarr_0_420[10];
char constantarr_0_421[34];
char constantarr_0_422[19];
char constantarr_0_423[14];
char constantarr_0_424[18];
char constantarr_0_425[24];
char constantarr_0_426[18];
char constantarr_0_427[14];
char constantarr_0_428[27];
char constantarr_0_429[24];
char constantarr_0_430[16];
char constantarr_0_431[5];
char constantarr_0_432[13];
char constantarr_0_433[17];
char constantarr_0_434[6];
char constantarr_0_435[15];
char constantarr_0_436[27];
char constantarr_0_437[30];
char constantarr_0_438[22];
char constantarr_0_439[22];
char constantarr_0_440[26];
char constantarr_0_441[17];
char constantarr_0_442[14];
char constantarr_0_443[30];
char constantarr_0_444[21];
char constantarr_0_445[74];
char constantarr_0_446[11];
char constantarr_0_447[45];
char constantarr_0_448[19];
char constantarr_0_449[22];
char constantarr_0_450[34];
char constantarr_0_451[11];
char constantarr_0_452[17];
char constantarr_0_453[14];
char constantarr_0_454[9];
char constantarr_0_455[6];
char constantarr_0_456[12];
char constantarr_0_457[16];
char constantarr_0_458[36];
char constantarr_0_459[10];
char constantarr_0_460[19];
char constantarr_0_461[15];
char constantarr_0_462[21];
char constantarr_0_463[10];
char constantarr_0_464[18];
char constantarr_0_465[14];
char constantarr_0_466[28];
char constantarr_0_467[16];
char constantarr_0_468[9];
char constantarr_0_469[17];
char constantarr_0_470[23];
char constantarr_0_471[12];
char constantarr_0_472[11];
char constantarr_0_473[17];
char constantarr_0_474[26];
char constantarr_0_475[14];
char constantarr_0_476[8];
char constantarr_0_477[13];
char constantarr_0_478[26];
char constantarr_0_479[19];
char constantarr_0_480[6];
char constantarr_0_481[7];
char constantarr_0_482[9];
char constantarr_0_483[22];
char constantarr_0_484[17];
char constantarr_0_485[14];
char constantarr_0_486[21];
char constantarr_0_487[32];
char constantarr_0_488[7];
char constantarr_0_489[7];
char constantarr_0_490[9];
char constantarr_0_491[25];
char constantarr_0_492[28];
char constantarr_0_493[19];
char constantarr_0_494[14];
char constantarr_0_495[13];
char constantarr_0_496[19];
char constantarr_0_497[12];
char constantarr_0_498[15];
char constantarr_0_499[19];
char constantarr_0_500[10];
char constantarr_0_501[11];
char constantarr_0_502[9];
char constantarr_0_503[38];
char constantarr_0_504[11];
char constantarr_0_505[21];
char constantarr_0_506[11];
char constantarr_0_507[10];
char constantarr_0_508[8];
char constantarr_0_509[8];
char constantarr_0_510[5];
char constantarr_0_511[15];
char constantarr_0_512[29];
char constantarr_0_513[7];
char constantarr_0_514[11];
char constantarr_0_515[10];
char constantarr_0_516[6];
char constantarr_0_517[12];
char constantarr_0_518[33];
char constantarr_0_519[38];
char constantarr_0_520[8];
char constantarr_0_521[30];
char constantarr_0_522[10];
char constantarr_0_523[13];
char constantarr_0_524[12];
char constantarr_0_525[46];
char constantarr_0_526[12];
char constantarr_0_527[8];
char constantarr_0_528[20];
char constantarr_0_529[8];
char constantarr_0_530[14];
char constantarr_0_531[20];
char constantarr_0_532[14];
char constantarr_0_533[13];
char constantarr_0_534[14];
char constantarr_0_535[7];
char constantarr_0_536[17];
char constantarr_0_537[11];
char constantarr_0_538[10];
char constantarr_0_539[22];
char constantarr_0_540[16];
char constantarr_0_541[8];
char constantarr_0_542[9];
char constantarr_0_543[9];
char constantarr_0_544[18];
char constantarr_0_545[15];
char constantarr_0_546[27];
char constantarr_0_547[15];
char constantarr_0_548[12];
char constantarr_0_549[27];
char constantarr_0_550[6];
char constantarr_0_551[5];
char constantarr_0_552[20];
char constantarr_0_553[19];
char constantarr_0_554[4];
char constantarr_0_555[35];
char constantarr_0_556[18];
char constantarr_0_557[17];
char constantarr_0_558[25];
char constantarr_0_559[21];
char constantarr_0_560[24];
char constantarr_0_561[20];
char constantarr_0_562[25];
char constantarr_0_563[4];
char constantarr_0_564[13];
char constantarr_0_0[20] = "uncaught exception: ";
char constantarr_0_1[1] = "\n";
char constantarr_0_2[11] = "<<UNKNOWN>>";
char constantarr_0_3[13] = "assert failed";
char constantarr_0_4[13] = "forbid failed";
char constantarr_0_5[17] = "<<empty message>>";
char constantarr_0_6[5] = "\n\tat ";
char constantarr_0_7[4] = "info";
char constantarr_0_8[4] = "warn";
char constantarr_0_9[5] = "error";
char constantarr_0_10[2] = ": ";
char constantarr_0_11[13] = "Hello, world!";
char constantarr_0_12[4] = "mark";
char constantarr_0_13[11] = "hard-assert";
char constantarr_0_14[4] = "void";
char constantarr_0_15[6] = "abort!";
char constantarr_0_16[13] = "word-aligned?";
char constantarr_0_17[2] = "==";
char constantarr_0_18[8] = "bits-and";
char constantarr_0_19[12] = "to-nat<nat8>";
char constantarr_0_20[14] = "words-of-bytes";
char constantarr_0_21[10] = "unsafe-div";
char constantarr_0_22[25] = "round-up-to-multiple-of-8";
char constantarr_0_23[8] = "wrap-add";
char constantarr_0_24[8] = "bits-not";
char constantarr_0_25[19] = "ptr-cast<nat, nat8>";
char constantarr_0_26[6] = "-<nat>";
char constantarr_0_27[8] = "wrap-sub";
char constantarr_0_28[10] = "to-nat<?a>";
char constantarr_0_29[11] = "size-of<?a>";
char constantarr_0_30[12] = "memory-start";
char constantarr_0_31[3] = "<=>";
char constantarr_0_32[13] = "?<comparison>";
char constantarr_0_33[5] = "less?";
char constantarr_0_34[4] = "less";
char constantarr_0_35[5] = "equal";
char constantarr_0_36[7] = "greater";
char constantarr_0_37[6] = "<<nat>";
char constantarr_0_38[4] = "true";
char constantarr_0_39[5] = "false";
char constantarr_0_40[17] = "memory-size-words";
char constantarr_0_41[7] = "<=<nat>";
char constantarr_0_42[3] = "not";
char constantarr_0_43[7] = "+<bool>";
char constantarr_0_44[5] = "marks";
char constantarr_0_45[16] = "mark-range-recur";
char constantarr_0_46[13] = "ptr-eq?<bool>";
char constantarr_0_47[2] = "or";
char constantarr_0_48[15] = "subscript<bool>";
char constantarr_0_49[19] = "set-subscript<bool>";
char constantarr_0_50[6] = "><nat>";
char constantarr_0_51[7] = "rt-main";
char constantarr_0_52[10] = "get-nprocs";
char constantarr_0_53[22] = "as<by-val<global-ctx>>";
char constantarr_0_54[10] = "global-ctx";
char constantarr_0_55[11] = "lock-by-val";
char constantarr_0_56[4] = "lock";
char constantarr_0_57[11] = "atomic-bool";
char constantarr_0_58[16] = "create-condition";
char constantarr_0_59[21] = "as<by-val<condition>>";
char constantarr_0_60[9] = "condition";
char constantarr_0_61[35] = "zeroed<by-val<pthread-mutexattr-t>>";
char constantarr_0_62[31] = "zeroed<by-val<pthread-mutex-t>>";
char constantarr_0_63[34] = "zeroed<by-val<pthread-condattr-t>>";
char constantarr_0_64[30] = "zeroed<by-val<pthread-cond-t>>";
char constantarr_0_65[23] = "hard-assert-posix-error";
char constantarr_0_66[22] = "pthread-mutexattr-init";
char constantarr_0_67[31] = "ref-of-val<pthread-mutexattr-t>";
char constantarr_0_68[10] = "mutex-attr";
char constantarr_0_69[21] = "ref-of-val<condition>";
char constantarr_0_70[18] = "pthread-mutex-init";
char constantarr_0_71[27] = "ref-of-val<pthread-mutex-t>";
char constantarr_0_72[5] = "mutex";
char constantarr_0_73[21] = "pthread-condattr-init";
char constantarr_0_74[30] = "ref-of-val<pthread-condattr-t>";
char constantarr_0_75[9] = "cond-attr";
char constantarr_0_76[25] = "pthread-condattr-setclock";
char constantarr_0_77[15] = "clock-monotonic";
char constantarr_0_78[17] = "pthread-cond-init";
char constantarr_0_79[26] = "ref-of-val<pthread-cond-t>";
char constantarr_0_80[4] = "cond";
char constantarr_0_81[22] = "ref-of-val<global-ctx>";
char constantarr_0_82[6] = "island";
char constantarr_0_83[10] = "task-queue";
char constantarr_0_84[4] = "none";
char constantarr_0_85[56] = "mut-list-by-val-with-capacity-from-unmanaged-memory<nat>";
char constantarr_0_86[11] = "mut-arr<?a>";
char constantarr_0_87[7] = "arr<?a>";
char constantarr_0_88[35] = "unmanaged-alloc-zeroed-elements<?a>";
char constantarr_0_89[28] = "unmanaged-alloc-elements<?a>";
char constantarr_0_90[21] = "unmanaged-alloc-bytes";
char constantarr_0_91[6] = "malloc";
char constantarr_0_92[11] = "hard-forbid";
char constantarr_0_93[11] = "null?<nat8>";
char constantarr_0_94[11] = "ptr-eq?<?a>";
char constantarr_0_95[8] = "null<?a>";
char constantarr_0_96[8] = "wrap-mul";
char constantarr_0_97[18] = "set-zero-range<?a>";
char constantarr_0_98[6] = "memset";
char constantarr_0_99[19] = "as-any-ptr<ptr<?a>>";
char constantarr_0_100[12] = "mut-list<?a>";
char constantarr_0_101[26] = "as<by-val<island-gc-root>>";
char constantarr_0_102[14] = "island-gc-root";
char constantarr_0_103[25] = "default-exception-handler";
char constantarr_0_104[20] = "print-err-no-newline";
char constantarr_0_105[16] = "write-no-newline";
char constantarr_0_106[13] = "size-of<char>";
char constantarr_0_107[13] = "size-of<nat8>";
char constantarr_0_108[5] = "write";
char constantarr_0_109[21] = "as-any-ptr<ptr<char>>";
char constantarr_0_110[15] = "begin-ptr<char>";
char constantarr_0_111[5] = "chars";
char constantarr_0_112[10] = "size-bytes";
char constantarr_0_113[10] = "size<char>";
char constantarr_0_114[7] = "!=<int>";
char constantarr_0_115[13] = "unsafe-to-int";
char constantarr_0_116[10] = "todo<void>";
char constantarr_0_117[10] = "zeroed<?a>";
char constantarr_0_118[6] = "stderr";
char constantarr_0_119[9] = "print-err";
char constantarr_0_120[6] = "to-str";
char constantarr_0_121[6] = "writer";
char constantarr_0_122[14] = "mut-list<char>";
char constantarr_0_123[2] = "~=";
char constantarr_0_124[8] = "~=<char>";
char constantarr_0_125[8] = "each<?a>";
char constantarr_0_126[14] = "each-recur<?a>";
char constantarr_0_127[19] = "subscript<void, ?a>";
char constantarr_0_128[22] = "call-with-ctx<?r, ?p0>";
char constantarr_0_129[7] = "get-ctx";
char constantarr_0_130[13] = "subscript<?a>";
char constantarr_0_131[5] = "+<?a>";
char constantarr_0_132[11] = "end-ptr<?a>";
char constantarr_0_133[6] = "~=<?a>";
char constantarr_0_134[18] = "incr-capacity!<?a>";
char constantarr_0_135[19] = "ensure-capacity<?a>";
char constantarr_0_136[12] = "capacity<?a>";
char constantarr_0_137[8] = "size<?a>";
char constantarr_0_138[9] = "inner<?a>";
char constantarr_0_139[11] = "backing<?a>";
char constantarr_0_140[25] = "increase-capacity-to!<?a>";
char constantarr_0_141[6] = "assert";
char constantarr_0_142[11] = "throw<void>";
char constantarr_0_143[9] = "throw<?a>";
char constantarr_0_144[17] = "get-exception-ctx";
char constantarr_0_145[21] = "as-ref<exception-ctx>";
char constantarr_0_146[17] = "exception-ctx-ptr";
char constantarr_0_147[18] = "thread-local-stuff";
char constantarr_0_148[18] = "null?<jmp-buf-tag>";
char constantarr_0_149[11] = "jmp-buf-ptr";
char constantarr_0_150[20] = "set-thrown-exception";
char constantarr_0_151[7] = "longjmp";
char constantarr_0_152[15] = "number-to-throw";
char constantarr_0_153[20] = "hard-unreachable<?a>";
char constantarr_0_154[9] = "exception";
char constantarr_0_155[13] = "get-backtrace";
char constantarr_0_156[24] = "try-alloc-backtrace-arrs";
char constantarr_0_157[34] = "try-alloc-uninitialized<ptr<nat8>>";
char constantarr_0_158[9] = "try-alloc";
char constantarr_0_159[12] = "try-gc-alloc";
char constantarr_0_160[8] = "acquire!";
char constantarr_0_161[14] = "acquire-recur!";
char constantarr_0_162[12] = "try-acquire!";
char constantarr_0_163[8] = "try-set!";
char constantarr_0_164[11] = "try-change!";
char constantarr_0_165[23] = "compare-exchange-strong";
char constantarr_0_166[12] = "ptr-to<bool>";
char constantarr_0_167[5] = "value";
char constantarr_0_168[23] = "ref-of-val<atomic-bool>";
char constantarr_0_169[9] = "is-locked";
char constantarr_0_170[12] = "yield-thread";
char constantarr_0_171[13] = "pthread-yield";
char constantarr_0_172[16] = "ref-of-val<lock>";
char constantarr_0_173[2] = "lk";
char constantarr_0_174[18] = "try-gc-alloc-recur";
char constantarr_0_175[8] = "data-cur";
char constantarr_0_176[6] = "+<nat>";
char constantarr_0_177[14] = "ptr-less?<nat>";
char constantarr_0_178[8] = "data-end";
char constantarr_0_179[11] = "range-free?";
char constantarr_0_180[8] = "mark-cur";
char constantarr_0_181[12] = "set-mark-cur";
char constantarr_0_182[12] = "set-data-cur";
char constantarr_0_183[15] = "some<ptr<nat8>>";
char constantarr_0_184[19] = "ptr-cast<nat8, nat>";
char constantarr_0_185[8] = "release!";
char constantarr_0_186[11] = "must-unset!";
char constantarr_0_187[10] = "try-unset!";
char constantarr_0_188[6] = "get-gc";
char constantarr_0_189[2] = "gc";
char constantarr_0_190[10] = "get-gc-ctx";
char constantarr_0_191[14] = "as-ref<gc-ctx>";
char constantarr_0_192[10] = "gc-ctx-ptr";
char constantarr_0_193[13] = "some<ptr<?a>>";
char constantarr_0_194[18] = "ptr-cast<?a, nat8>";
char constantarr_0_195[28] = "try-alloc-uninitialized<str>";
char constantarr_0_196[10] = "funs-count";
char constantarr_0_197[20] = "some<backtrace-arrs>";
char constantarr_0_198[14] = "backtrace-arrs";
char constantarr_0_199[9] = "backtrace";
char constantarr_0_200[12] = "as<arr<str>>";
char constantarr_0_201[13] = "unsafe-to-nat";
char constantarr_0_202[6] = "to-int";
char constantarr_0_203[9] = "code-ptrs";
char constantarr_0_204[15] = "unsafe-to-int32";
char constantarr_0_205[14] = "code-ptrs-size";
char constantarr_0_206[25] = "fill-fun-ptrs-names-recur";
char constantarr_0_207[7] = "!=<nat>";
char constantarr_0_208[24] = "set-subscript<ptr<nat8>>";
char constantarr_0_209[17] = "set-subscript<?a>";
char constantarr_0_210[11] = "get-fun-ptr";
char constantarr_0_211[18] = "set-subscript<str>";
char constantarr_0_212[12] = "get-fun-name";
char constantarr_0_213[8] = "fun-ptrs";
char constantarr_0_214[9] = "fun-names";
char constantarr_0_215[13] = "sort-together";
char constantarr_0_216[15] = "swap<ptr<nat8>>";
char constantarr_0_217[9] = "swap<str>";
char constantarr_0_218[24] = "partition-recur-together";
char constantarr_0_219[15] = "ptr-less?<nat8>";
char constantarr_0_220[10] = "code-names";
char constantarr_0_221[21] = "fill-code-names-recur";
char constantarr_0_222[14] = "ptr-less?<str>";
char constantarr_0_223[8] = "arr<str>";
char constantarr_0_224[13] = "begin-ptr<?a>";
char constantarr_0_225[15] = "set-backing<?a>";
char constantarr_0_226[25] = "uninitialized-mut-arr<?a>";
char constantarr_0_227[23] = "alloc-uninitialized<?a>";
char constantarr_0_228[5] = "alloc";
char constantarr_0_229[8] = "gc-alloc";
char constantarr_0_230[15] = "todo<ptr<nat8>>";
char constantarr_0_231[18] = "copy-data-from<?a>";
char constantarr_0_232[6] = "memcpy";
char constantarr_0_233[21] = "set-zero-elements<?a>";
char constantarr_0_234[14] = "from<nat, nat>";
char constantarr_0_235[12] = "to<nat, nat>";
char constantarr_0_236[12] = "-><nat, nat>";
char constantarr_0_237[13] = "arrow<?a, ?b>";
char constantarr_0_238[1] = "+";
char constantarr_0_239[3] = "and";
char constantarr_0_240[7] = ">=<nat>";
char constantarr_0_241[24] = "round-up-to-power-of-two";
char constantarr_0_242[30] = "round-up-to-power-of-two-recur";
char constantarr_0_243[1] = "*";
char constantarr_0_244[1] = "/";
char constantarr_0_245[6] = "forbid";
char constantarr_0_246[12] = "set-size<?a>";
char constantarr_0_247[16] = "~=<char>.lambda0";
char constantarr_0_248[6] = "?<str>";
char constantarr_0_249[6] = "empty?";
char constantarr_0_250[12] = "empty?<char>";
char constantarr_0_251[7] = "message";
char constantarr_0_252[9] = "each<str>";
char constantarr_0_253[12] = "return-stack";
char constantarr_0_254[14] = "to-str.lambda0";
char constantarr_0_255[12] = "move-to-str!";
char constantarr_0_256[3] = "str";
char constantarr_0_257[18] = "move-to-arr!<char>";
char constantarr_0_258[29] = "set-any-unhandled-exceptions?";
char constantarr_0_259[14] = "get-global-ctx";
char constantarr_0_260[18] = "as-ref<global-ctx>";
char constantarr_0_261[8] = "gctx-ptr";
char constantarr_0_262[14] = "island.lambda0";
char constantarr_0_263[19] = "default-log-handler";
char constantarr_0_264[5] = "print";
char constantarr_0_265[16] = "print-no-newline";
char constantarr_0_266[6] = "stdout";
char constantarr_0_267[1] = "~";
char constantarr_0_268[7] = "~<char>";
char constantarr_0_269[5] = "level";
char constantarr_0_270[14] = "island.lambda1";
char constantarr_0_271[20] = "ptr-cast<bool, nat8>";
char constantarr_0_272[21] = "as-any-ptr<ptr<bool>>";
char constantarr_0_273[14] = "as<by-val<gc>>";
char constantarr_0_274[11] = "validate-gc";
char constantarr_0_275[10] = "mark-begin";
char constantarr_0_276[10] = "data-begin";
char constantarr_0_277[18] = "ptr-less-eq?<bool>";
char constantarr_0_278[13] = "ptr-less?<?a>";
char constantarr_0_279[8] = "mark-end";
char constantarr_0_280[17] = "ptr-less-eq?<nat>";
char constantarr_0_281[7] = "-<bool>";
char constantarr_0_282[10] = "size-words";
char constantarr_0_283[14] = "ref-of-val<gc>";
char constantarr_0_284[19] = "thread-safe-counter";
char constantarr_0_285[18] = "ref-of-val<island>";
char constantarr_0_286[11] = "set-islands";
char constantarr_0_287[11] = "arr<island>";
char constantarr_0_288[14] = "ptr-to<island>";
char constantarr_0_289[13] = "add-main-task";
char constantarr_0_290[13] = "exception-ctx";
char constantarr_0_291[7] = "log-ctx";
char constantarr_0_292[26] = "zeroed<fun1<void, logged>>";
char constantarr_0_293[8] = "perf-ctx";
char constantarr_0_294[22] = "mut-arr<measure-value>";
char constantarr_0_295[25] = "as-any-ptr<exception-ctx>";
char constantarr_0_296[25] = "ref-of-val<exception-ctx>";
char constantarr_0_297[19] = "as-any-ptr<log-ctx>";
char constantarr_0_298[19] = "ref-of-val<log-ctx>";
char constantarr_0_299[20] = "as-any-ptr<perf-ctx>";
char constantarr_0_300[20] = "ref-of-val<perf-ctx>";
char constantarr_0_301[10] = "print-lock";
char constantarr_0_302[30] = "as<by-val<thread-local-stuff>>";
char constantarr_0_303[3] = "ctx";
char constantarr_0_304[12] = "context-head";
char constantarr_0_305[23] = "size-of<by-val<gc-ctx>>";
char constantarr_0_306[6] = "set-gc";
char constantarr_0_307[12] = "set-next-ctx";
char constantarr_0_308[16] = "set-context-head";
char constantarr_0_309[8] = "next-ctx";
char constantarr_0_310[11] = "set-handler";
char constantarr_0_311[15] = "as-ref<log-ctx>";
char constantarr_0_312[11] = "log-ctx-ptr";
char constantarr_0_313[11] = "log-handler";
char constantarr_0_314[26] = "ref-of-val<island-gc-root>";
char constantarr_0_315[7] = "gc-root";
char constantarr_0_316[22] = "as-any-ptr<global-ctx>";
char constantarr_0_317[2] = "id";
char constantarr_0_318[18] = "as-any-ptr<gc-ctx>";
char constantarr_0_319[30] = "ref-of-val<thread-local-stuff>";
char constantarr_0_320[15] = "ref-of-val<ctx>";
char constantarr_0_321[73] = "as<fun-act2<fut<nat>, arr<ptr<char>>, fun-ptr2<fut<nat>, ctx, arr<str>>>>";
char constantarr_0_322[14] = "add-first-task";
char constantarr_0_323[14] = "then-void<nat>";
char constantarr_0_324[16] = "then<?out, void>";
char constantarr_0_325[16] = "unresolved<?out>";
char constantarr_0_326[7] = "fut<?a>";
char constantarr_0_327[22] = "fut-state-no-callbacks";
char constantarr_0_328[14] = "callback!<?in>";
char constantarr_0_329[15] = "with-lock<void>";
char constantarr_0_330[17] = "call-with-ctx<?r>";
char constantarr_0_331[6] = "lk<?a>";
char constantarr_0_332[9] = "state<?a>";
char constantarr_0_333[13] = "set-state<?a>";
char constantarr_0_334[23] = "fut-state-callbacks<?a>";
char constantarr_0_335[29] = "some<fut-state-callbacks<?a>>";
char constantarr_0_336[38] = "subscript<void, result<?a, exception>>";
char constantarr_0_337[6] = "ok<?a>";
char constantarr_0_338[9] = "value<?a>";
char constantarr_0_339[14] = "err<exception>";
char constantarr_0_340[22] = "callback!<?in>.lambda0";
char constantarr_0_341[17] = "forward-to!<?out>";
char constantarr_0_342[13] = "callback!<?a>";
char constantarr_0_343[21] = "callback!<?a>.lambda0";
char constantarr_0_344[22] = "resolve-or-reject!<?a>";
char constantarr_0_345[24] = "with-lock<fut-state<?a>>";
char constantarr_0_346[22] = "fut-state-resolved<?a>";
char constantarr_0_347[16] = "value<exception>";
char constantarr_0_348[30] = "resolve-or-reject!<?a>.lambda0";
char constantarr_0_349[19] = "call-callbacks!<?a>";
char constantarr_0_350[6] = "cb<?a>";
char constantarr_0_351[8] = "next<?a>";
char constantarr_0_352[25] = "forward-to!<?out>.lambda0";
char constantarr_0_353[20] = "subscript<?out, ?in>";
char constantarr_0_354[10] = "get-island";
char constantarr_0_355[17] = "subscript<island>";
char constantarr_0_356[13] = "unsafe-at<?a>";
char constantarr_0_357[7] = "islands";
char constantarr_0_358[29] = "island-and-exclusion<?r, ?p0>";
char constantarr_0_359[8] = "add-task";
char constantarr_0_360[15] = "task-queue-node";
char constantarr_0_361[4] = "task";
char constantarr_0_362[10] = "tasks-lock";
char constantarr_0_363[12] = "insert-task!";
char constantarr_0_364[4] = "size";
char constantarr_0_365[10] = "size-recur";
char constantarr_0_366[4] = "next";
char constantarr_0_367[4] = "head";
char constantarr_0_368[8] = "set-head";
char constantarr_0_369[21] = "some<task-queue-node>";
char constantarr_0_370[4] = "time";
char constantarr_0_371[12] = "insert-recur";
char constantarr_0_372[8] = "set-next";
char constantarr_0_373[5] = "tasks";
char constantarr_0_374[22] = "ref-of-val<task-queue>";
char constantarr_0_375[10] = "broadcast!";
char constantarr_0_376[18] = "pthread-mutex-lock";
char constantarr_0_377[22] = "pthread-cond-broadcast";
char constantarr_0_378[12] = "set-sequence";
char constantarr_0_379[8] = "sequence";
char constantarr_0_380[20] = "pthread-mutex-unlock";
char constantarr_0_381[17] = "may-be-work-to-do";
char constantarr_0_382[4] = "gctx";
char constantarr_0_383[12] = "no-timestamp";
char constantarr_0_384[9] = "exclusion";
char constantarr_0_385[11] = "catch<void>";
char constantarr_0_386[28] = "catch-with-exception-ctx<?a>";
char constantarr_0_387[16] = "thrown-exception";
char constantarr_0_388[11] = "jmp-buf-tag";
char constantarr_0_389[4] = "zero";
char constantarr_0_390[7] = "bytes64";
char constantarr_0_391[7] = "bytes32";
char constantarr_0_392[7] = "bytes16";
char constantarr_0_393[8] = "bytes128";
char constantarr_0_394[15] = "set-jmp-buf-ptr";
char constantarr_0_395[19] = "ptr-to<jmp-buf-tag>";
char constantarr_0_396[6] = "setjmp";
char constantarr_0_397[24] = "subscript<?a, exception>";
char constantarr_0_398[23] = "subscript<fut<?r>, ?p0>";
char constantarr_0_399[12] = "fun<?r, ?p0>";
char constantarr_0_400[36] = "subscript<?out, ?in>.lambda0.lambda0";
char constantarr_0_401[11] = "reject!<?r>";
char constantarr_0_402[36] = "subscript<?out, ?in>.lambda0.lambda1";
char constantarr_0_403[28] = "subscript<?out, ?in>.lambda0";
char constantarr_0_404[10] = "value<?in>";
char constantarr_0_405[24] = "then<?out, void>.lambda0";
char constantarr_0_406[15] = "subscript<?out>";
char constantarr_0_407[24] = "island-and-exclusion<?r>";
char constantarr_0_408[18] = "subscript<fut<?r>>";
char constantarr_0_409[7] = "fun<?r>";
char constantarr_0_410[31] = "subscript<?out>.lambda0.lambda0";
char constantarr_0_411[31] = "subscript<?out>.lambda0.lambda1";
char constantarr_0_412[23] = "subscript<?out>.lambda0";
char constantarr_0_413[22] = "then-void<nat>.lambda0";
char constantarr_0_414[24] = "cur-island-and-exclusion";
char constantarr_0_415[20] = "island-and-exclusion";
char constantarr_0_416[9] = "island-id";
char constantarr_0_417[5] = "delay";
char constantarr_0_418[14] = "resolved<void>";
char constantarr_0_419[15] = "tail<ptr<char>>";
char constantarr_0_420[10] = "empty?<?a>";
char constantarr_0_421[34] = "subscript<fut<nat>, ctx, arr<str>>";
char constantarr_0_422[19] = "map<str, ptr<char>>";
char constantarr_0_423[14] = "make-arr<?out>";
char constantarr_0_424[18] = "fill-ptr-range<?a>";
char constantarr_0_425[24] = "fill-ptr-range-recur<?a>";
char constantarr_0_426[18] = "subscript<?a, nat>";
char constantarr_0_427[14] = "subscript<?in>";
char constantarr_0_428[27] = "map<str, ptr<char>>.lambda0";
char constantarr_0_429[24] = "arr-from-begin-end<char>";
char constantarr_0_430[16] = "ptr-less-eq?<?a>";
char constantarr_0_431[5] = "-<?a>";
char constantarr_0_432[13] = "find-cstr-end";
char constantarr_0_433[17] = "find-char-in-cstr";
char constantarr_0_434[6] = "to-nat";
char constantarr_0_435[15] = "some<ptr<char>>";
char constantarr_0_436[27] = "hard-unreachable<ptr<char>>";
char constantarr_0_437[30] = "add-first-task.lambda0.lambda0";
char constantarr_0_438[22] = "add-first-task.lambda0";
char constantarr_0_439[22] = "handle-exceptions<nat>";
char constantarr_0_440[26] = "subscript<void, exception>";
char constantarr_0_441[17] = "exception-handler";
char constantarr_0_442[14] = "get-cur-island";
char constantarr_0_443[30] = "handle-exceptions<nat>.lambda0";
char constantarr_0_444[21] = "add-main-task.lambda0";
char constantarr_0_445[74] = "call-with-ctx<fut<nat>, arr<ptr<char>>, fun-ptr2<fut<nat>, ctx, arr<str>>>";
char constantarr_0_446[11] = "run-threads";
char constantarr_0_447[45] = "unmanaged-alloc-elements<by-val<thread-args>>";
char constantarr_0_448[19] = "start-threads-recur";
char constantarr_0_449[22] = "+<by-val<thread-args>>";
char constantarr_0_450[34] = "set-subscript<by-val<thread-args>>";
char constantarr_0_451[11] = "thread-args";
char constantarr_0_452[17] = "create-one-thread";
char constantarr_0_453[14] = "pthread-create";
char constantarr_0_454[9] = "!=<int32>";
char constantarr_0_455[6] = "eagain";
char constantarr_0_456[12] = "as-cell<nat>";
char constantarr_0_457[16] = "as-ref<cell<?a>>";
char constantarr_0_458[36] = "as-any-ptr<ptr<by-val<thread-args>>>";
char constantarr_0_459[10] = "thread-fun";
char constantarr_0_460[19] = "as-ref<thread-args>";
char constantarr_0_461[15] = "thread-function";
char constantarr_0_462[21] = "thread-function-recur";
char constantarr_0_463[10] = "shut-down?";
char constantarr_0_464[18] = "set-n-live-threads";
char constantarr_0_465[14] = "n-live-threads";
char constantarr_0_466[28] = "assert-islands-are-shut-down";
char constantarr_0_467[16] = "noctx-at<island>";
char constantarr_0_468[9] = "needs-gc?";
char constantarr_0_469[17] = "n-threads-running";
char constantarr_0_470[23] = "empty?<task-queue-node>";
char constantarr_0_471[12] = "get-sequence";
char constantarr_0_472[11] = "choose-task";
char constantarr_0_473[17] = "get-monotime-nsec";
char constantarr_0_474[26] = "as<by-val<cell<timespec>>>";
char constantarr_0_475[14] = "cell<timespec>";
char constantarr_0_476[8] = "timespec";
char constantarr_0_477[13] = "clock-gettime";
char constantarr_0_478[26] = "ref-of-val<cell<timespec>>";
char constantarr_0_479[19] = "subscript<timespec>";
char constantarr_0_480[6] = "tv-sec";
char constantarr_0_481[7] = "tv-nsec";
char constantarr_0_482[9] = "todo<nat>";
char constantarr_0_483[22] = "as<choose-task-result>";
char constantarr_0_484[17] = "choose-task-recur";
char constantarr_0_485[14] = "no-chosen-task";
char constantarr_0_486[21] = "choose-task-in-island";
char constantarr_0_487[32] = "as<choose-task-in-island-result>";
char constantarr_0_488[7] = "do-a-gc";
char constantarr_0_489[7] = "no-task";
char constantarr_0_490[9] = "pop-task!";
char constantarr_0_491[25] = "ref-of-val<mut-list<nat>>";
char constantarr_0_492[28] = "currently-running-exclusions";
char constantarr_0_493[19] = "as<pop-task-result>";
char constantarr_0_494[14] = "contains?<nat>";
char constantarr_0_495[13] = "contains?<?a>";
char constantarr_0_496[19] = "contains-recur?<?a>";
char constantarr_0_497[12] = "noctx-at<?a>";
char constantarr_0_498[15] = "temp-as-arr<?a>";
char constantarr_0_499[19] = "temp-as-mut-arr<?a>";
char constantarr_0_500[10] = "pop-recur!";
char constantarr_0_501[11] = "to-opt-time";
char constantarr_0_502[9] = "some<nat>";
char constantarr_0_503[38] = "push-capacity-must-be-sufficient!<nat>";
char constantarr_0_504[11] = "is-no-task?";
char constantarr_0_505[21] = "set-n-threads-running";
char constantarr_0_506[11] = "chosen-task";
char constantarr_0_507[10] = "any-tasks?";
char constantarr_0_508[8] = "min-time";
char constantarr_0_509[8] = "min<nat>";
char constantarr_0_510[5] = "?<?a>";
char constantarr_0_511[15] = "first-task-time";
char constantarr_0_512[29] = "no-tasks-and-last-thread-out?";
char constantarr_0_513[7] = "do-task";
char constantarr_0_514[11] = "task-island";
char constantarr_0_515[10] = "task-or-gc";
char constantarr_0_516[6] = "action";
char constantarr_0_517[12] = "return-task!";
char constantarr_0_518[33] = "noctx-must-remove-unordered!<nat>";
char constantarr_0_519[38] = "noctx-must-remove-unordered-recur!<?a>";
char constantarr_0_520[8] = "drop<?a>";
char constantarr_0_521[30] = "noctx-remove-unordered-at!<?a>";
char constantarr_0_522[10] = "return-ctx";
char constantarr_0_523[13] = "return-gc-ctx";
char constantarr_0_524[12] = "some<gc-ctx>";
char constantarr_0_525[46] = "run-garbage-collection<by-val<island-gc-root>>";
char constantarr_0_526[12] = "set-gc-count";
char constantarr_0_527[8] = "gc-count";
char constantarr_0_528[20] = "as<by-val<mark-ctx>>";
char constantarr_0_529[8] = "mark-ctx";
char constantarr_0_530[14] = "mark-visit<?a>";
char constantarr_0_531[20] = "ref-of-val<mark-ctx>";
char constantarr_0_532[14] = "clear-free-mem";
char constantarr_0_533[13] = "set-needs-gc?";
char constantarr_0_534[14] = "set-shut-down?";
char constantarr_0_535[7] = "wait-on";
char constantarr_0_536[17] = "pthread-cond-wait";
char constantarr_0_537[11] = "to-timespec";
char constantarr_0_538[10] = "unsafe-mod";
char constantarr_0_539[22] = "pthread-cond-timedwait";
char constantarr_0_540[16] = "ptr-to<timespec>";
char constantarr_0_541[8] = "?<int32>";
char constantarr_0_542[9] = "etimedout";
char constantarr_0_543[9] = "thread-id";
char constantarr_0_544[18] = "join-threads-recur";
char constantarr_0_545[15] = "join-one-thread";
char constantarr_0_546[27] = "as<by-val<cell<ptr<nat8>>>>";
char constantarr_0_547[15] = "cell<ptr<nat8>>";
char constantarr_0_548[12] = "pthread-join";
char constantarr_0_549[27] = "ref-of-val<cell<ptr<nat8>>>";
char constantarr_0_550[6] = "einval";
char constantarr_0_551[5] = "esrch";
char constantarr_0_552[20] = "subscript<ptr<nat8>>";
char constantarr_0_553[19] = "unmanaged-free<nat>";
char constantarr_0_554[4] = "free";
char constantarr_0_555[35] = "unmanaged-free<by-val<thread-args>>";
char constantarr_0_556[18] = "ptr-cast<nat8, ?a>";
char constantarr_0_557[17] = "destroy-condition";
char constantarr_0_558[25] = "pthread-mutexattr-destroy";
char constantarr_0_559[21] = "pthread-mutex-destroy";
char constantarr_0_560[24] = "pthread-condattr-destroy";
char constantarr_0_561[20] = "pthread-cond-destroy";
char constantarr_0_562[25] = "any-unhandled-exceptions?";
char constantarr_0_563[4] = "main";
char constantarr_0_564[13] = "resolved<nat>";
uint8_t mark(struct mark_ctx* ctx, uint8_t* ptr_any, uint64_t size_bytes);
struct void_ hard_assert(uint8_t condition);
extern void abort(void);
uint8_t word_aligned__q(uint8_t* a);
uint64_t words_of_bytes(uint64_t size_bytes);
uint64_t round_up_to_multiple_of_8(uint64_t n);
uint64_t _minus_0(uint64_t* a, uint64_t* b);
struct comparison _compare(uint64_t a, uint64_t b);
uint8_t _less(uint64_t a, uint64_t b);
uint8_t _lessOrEqual(uint64_t a, uint64_t b);
uint8_t not(uint8_t a);
uint8_t mark_range_recur(uint8_t marked_anything__q, uint8_t* cur, uint8_t* end);
uint8_t _greater(uint64_t a, uint64_t b);
int32_t rt_main(int32_t argc, char** argv, fun_ptr2 main_ptr);
extern uint64_t get_nprocs(void);
struct lock lock_by_val(void);
struct _atomic_bool _atomic_bool(void);
struct condition create_condition(void);
struct void_ hard_assert_posix_error(int32_t err);
extern int32_t pthread_mutexattr_init(struct pthread_mutexattr_t* attr);
extern int32_t pthread_mutex_init(struct pthread_mutex_t* mutex, struct pthread_mutexattr_t* attr);
extern int32_t pthread_condattr_init(struct pthread_condattr_t* attr);
extern int32_t pthread_condattr_setclock(struct pthread_condattr_t* attr, int32_t clock_id);
int32_t clock_monotonic(void);
extern int32_t pthread_cond_init(struct pthread_cond_t* cond, struct pthread_condattr_t* cond_attr);
struct island island(struct global_ctx* gctx, uint64_t id, uint64_t max_threads);
struct task_queue task_queue(uint64_t max_threads);
struct mut_list_0 mut_list_by_val_with_capacity_from_unmanaged_memory(uint64_t capacity);
struct mut_arr_0 mut_arr_0(uint64_t size, uint64_t* begin_ptr);
uint64_t* unmanaged_alloc_zeroed_elements(uint64_t size_elements);
uint64_t* unmanaged_alloc_elements_0(uint64_t size_elements);
uint8_t* unmanaged_alloc_bytes(uint64_t size);
extern uint8_t* malloc(uint64_t size);
struct void_ hard_forbid(uint8_t condition);
uint8_t null__q_0(uint8_t* a);
struct void_ set_zero_range_0(uint64_t* begin, uint64_t size);
extern void memset(uint8_t* begin, uint8_t value, uint64_t size);
struct void_ default_exception_handler(struct ctx* ctx, struct exception e);
struct void_ print_err_no_newline(struct str s);
struct void_ write_no_newline(int32_t fd, struct str a);
extern int64_t write(int32_t fd, uint8_t* buf, uint64_t n_bytes);
uint64_t size_bytes(struct str a);
uint8_t _notEqual_0(int64_t a, int64_t b);
struct void_ todo_0(void);
int32_t stderr(void);
struct void_ print_err(struct str s);
struct str to_str_0(struct ctx* ctx, struct exception a);
struct writer writer(struct ctx* ctx);
struct mut_list_1* mut_list(struct ctx* ctx);
struct mut_arr_1 mut_arr_1(void);
struct void_ _concatEquals_0(struct ctx* ctx, struct writer a, struct str b);
struct void_ _concatEquals_1(struct ctx* ctx, struct mut_list_1* a, struct arr_0 values);
struct void_ each_0(struct ctx* ctx, struct arr_0 a, struct fun_act1_1 f);
struct void_ each_recur_0(struct ctx* ctx, char* cur, char* end, struct fun_act1_1 f);
struct void_ subscript_0(struct ctx* ctx, struct fun_act1_1 a, char p0);
struct void_ call_w_ctx_55(struct fun_act1_1 a, struct ctx* ctx, char p0);
char* end_ptr_0(struct arr_0 a);
struct void_ _concatEquals_2(struct ctx* ctx, struct mut_list_1* a, char value);
struct void_ incr_capacity__e(struct ctx* ctx, struct mut_list_1* a);
struct void_ ensure_capacity(struct ctx* ctx, struct mut_list_1* a, uint64_t min_capacity);
uint64_t capacity_0(struct mut_list_1* a);
uint64_t size_0(struct mut_arr_1 a);
struct void_ increase_capacity_to__e(struct ctx* ctx, struct mut_list_1* a, uint64_t new_capacity);
struct void_ assert(struct ctx* ctx, uint8_t condition);
struct void_ throw_0(struct ctx* ctx, struct str message);
struct void_ throw_1(struct ctx* ctx, struct exception e);
struct exception_ctx* get_exception_ctx(struct ctx* ctx);
uint8_t null__q_1(struct jmp_buf_tag* a);
extern void longjmp(struct jmp_buf_tag* env, int32_t val);
int32_t number_to_throw(struct ctx* ctx);
struct void_ hard_unreachable_0(void);
struct backtrace get_backtrace(struct ctx* ctx);
struct opt_3 try_alloc_backtrace_arrs(struct ctx* ctx);
struct opt_4 try_alloc_uninitialized_0(struct ctx* ctx, uint64_t size);
struct opt_5 try_alloc(struct ctx* ctx, uint64_t size_bytes);
struct opt_5 try_gc_alloc(struct gc* gc, uint64_t size_bytes);
struct void_ acquire__e(struct lock* a);
struct void_ acquire_recur__e(struct lock* a, uint64_t n_tries);
uint8_t try_acquire__e(struct lock* a);
uint8_t try_set__e(struct _atomic_bool* a);
uint8_t try_change__e(struct _atomic_bool* a, uint8_t old_value);
struct void_ yield_thread(void);
extern int32_t pthread_yield(void);
struct opt_5 try_gc_alloc_recur(struct gc* gc, uint64_t size_bytes);
uint8_t range_free__q(uint8_t* mark, uint8_t* end);
struct void_ release__e(struct lock* a);
struct void_ must_unset__e(struct _atomic_bool* a);
uint8_t try_unset__e(struct _atomic_bool* a);
struct gc* get_gc(struct ctx* ctx);
struct gc_ctx* get_gc_ctx_0(struct ctx* ctx);
struct opt_6 try_alloc_uninitialized_1(struct ctx* ctx, uint64_t size);
uint64_t funs_count_91(void);
extern int32_t backtrace(uint8_t** array, int32_t size);
uint64_t code_ptrs_size(struct ctx* ctx);
struct void_ fill_fun_ptrs_names_recur(uint64_t i, uint8_t** fun_ptrs, struct str* fun_names);
uint8_t _notEqual_1(uint64_t a, uint64_t b);
struct void_ set_subscript_0(uint8_t** a, uint64_t n, uint8_t* value);
uint8_t* get_fun_ptr_97(uint64_t fun_id);
struct void_ set_subscript_1(struct str* a, uint64_t n, struct str value);
struct str get_fun_name_99(uint64_t fun_id);
struct void_ sort_together(struct ctx* ctx, uint8_t** a, struct str* b, uint64_t size);
struct void_ swap_0(struct ctx* ctx, uint8_t** a, uint64_t lo, uint64_t hi);
uint8_t* subscript_1(uint8_t** a, uint64_t n);
struct void_ swap_1(struct ctx* ctx, struct str* a, uint64_t lo, uint64_t hi);
struct str subscript_2(struct str* a, uint64_t n);
uint64_t partition_recur_together(struct ctx* ctx, uint8_t** a, struct str* b, uint8_t* pivot, uint64_t l, uint64_t r);
struct void_ fill_code_names_recur(struct ctx* ctx, struct str* code_names, struct str* end_code_names, uint8_t** code_ptrs, uint8_t** fun_ptrs, struct str* fun_names);
struct str get_fun_name(uint8_t* code_ptr, uint8_t** fun_ptrs, struct str* fun_names, uint64_t size);
char* begin_ptr_0(struct mut_list_1* a);
char* begin_ptr_1(struct mut_arr_1 a);
struct mut_arr_1 uninitialized_mut_arr(struct ctx* ctx, uint64_t size);
struct mut_arr_1 mut_arr_2(uint64_t size, char* begin_ptr);
char* alloc_uninitialized_0(struct ctx* ctx, uint64_t size);
uint8_t* alloc(struct ctx* ctx, uint64_t size_bytes);
uint8_t* gc_alloc(struct ctx* ctx, struct gc* gc, uint64_t size);
uint8_t* todo_1(void);
struct void_ copy_data_from(struct ctx* ctx, char* to, char* from, uint64_t len);
extern void memcpy(uint8_t* dest, uint8_t* src, uint64_t size);
struct void_ set_zero_elements(struct mut_arr_1 a);
struct void_ set_zero_range_1(char* begin, uint64_t size);
struct mut_arr_1 subscript_3(struct ctx* ctx, struct mut_arr_1 a, struct arrow range);
struct arr_0 subscript_4(struct ctx* ctx, struct arr_0 a, struct arrow range);
struct arrow _arrow(struct ctx* ctx, uint64_t from, uint64_t to);
uint64_t _plus(struct ctx* ctx, uint64_t a, uint64_t b);
uint8_t _greaterOrEqual(uint64_t a, uint64_t b);
uint64_t round_up_to_power_of_two(struct ctx* ctx, uint64_t n);
uint64_t round_up_to_power_of_two_recur(struct ctx* ctx, uint64_t acc, uint64_t n);
uint64_t _times(struct ctx* ctx, uint64_t a, uint64_t b);
uint64_t _divide(struct ctx* ctx, uint64_t a, uint64_t b);
struct void_ forbid(struct ctx* ctx, uint8_t condition);
struct void_ set_subscript_2(char* a, uint64_t n, char value);
struct void_ _concatEquals_1__lambda0(struct ctx* ctx, struct _concatEquals_1__lambda0* _closure, char it);
uint8_t empty__q_0(struct str a);
uint8_t empty__q_1(struct arr_0 a);
struct void_ each_1(struct ctx* ctx, struct arr_1 a, struct fun_act1_2 f);
struct void_ each_recur_1(struct ctx* ctx, struct str* cur, struct str* end, struct fun_act1_2 f);
struct void_ subscript_5(struct ctx* ctx, struct fun_act1_2 a, struct str p0);
struct void_ call_w_ctx_137(struct fun_act1_2 a, struct ctx* ctx, struct str p0);
struct str* end_ptr_1(struct arr_1 a);
struct void_ to_str_0__lambda0(struct ctx* ctx, struct to_str_0__lambda0* _closure, struct str x);
struct str move_to_str__e(struct ctx* ctx, struct writer a);
struct arr_0 move_to_arr__e(struct mut_list_1* a);
struct global_ctx* get_global_ctx(struct ctx* ctx);
struct void_ island__lambda0(struct ctx* ctx, struct void_ _closure, struct exception it);
struct void_ default_log_handler(struct ctx* ctx, struct logged* a);
struct void_ print(struct str a);
struct void_ print_no_newline(struct str a);
int32_t stdout(void);
struct str _concat_0(struct ctx* ctx, struct str a, struct str b);
struct arr_0 _concat_1(struct ctx* ctx, struct arr_0 a, struct arr_0 b);
struct str to_str_1(struct ctx* ctx, struct log_level a);
struct void_ island__lambda1(struct ctx* ctx, struct void_ _closure, struct logged* log);
struct gc gc(void);
struct void_ validate_gc(struct gc* gc);
uint8_t ptr_less_eq__q_0(uint8_t* a, uint8_t* b);
uint8_t ptr_less_eq__q_1(uint64_t* a, uint64_t* b);
uint64_t _minus_1(uint8_t* a, uint8_t* b);
struct thread_safe_counter thread_safe_counter_0(void);
struct thread_safe_counter thread_safe_counter_1(uint64_t init);
struct fut_0* add_main_task(struct global_ctx* gctx, uint64_t thread_id, struct island* island, int32_t argc, char** argv, fun_ptr2 main_ptr);
struct exception_ctx exception_ctx(void);
struct log_ctx log_ctx(void);
struct perf_ctx perf_ctx(void);
struct mut_arr_2 mut_arr_3(void);
struct ctx ctx(struct global_ctx* gctx, struct thread_local_stuff* tls, struct island* island, uint64_t exclusion);
struct gc_ctx* get_gc_ctx_1(struct gc* gc);
struct fut_0* add_first_task(struct ctx* ctx, struct arr_5 all_args, fun_ptr2 main_ptr);
struct fut_0* then_void(struct ctx* ctx, struct fut_1* a, struct fun_ref0 cb);
struct fut_0* then(struct ctx* ctx, struct fut_1* a, struct fun_ref1 cb);
struct fut_0* unresolved(struct ctx* ctx);
struct void_ callback__e_0(struct ctx* ctx, struct fut_1* f, struct fun_act1_3 cb);
struct void_ with_lock_0(struct ctx* ctx, struct lock* a, struct fun_act0_0 f);
struct void_ subscript_6(struct ctx* ctx, struct fun_act0_0 a);
struct void_ call_w_ctx_173(struct fun_act0_0 a, struct ctx* ctx);
struct void_ subscript_7(struct ctx* ctx, struct fun_act1_3 a, struct result_1 p0);
struct void_ call_w_ctx_175(struct fun_act1_3 a, struct ctx* ctx, struct result_1 p0);
struct void_ callback__e_0__lambda0(struct ctx* ctx, struct callback__e_0__lambda0* _closure);
struct void_ forward_to__e(struct ctx* ctx, struct fut_0* from, struct fut_0* to);
struct void_ callback__e_1(struct ctx* ctx, struct fut_0* f, struct fun_act1_0 cb);
struct void_ subscript_8(struct ctx* ctx, struct fun_act1_0 a, struct result_0 p0);
struct void_ call_w_ctx_180(struct fun_act1_0 a, struct ctx* ctx, struct result_0 p0);
struct void_ callback__e_1__lambda0(struct ctx* ctx, struct callback__e_1__lambda0* _closure);
struct void_ resolve_or_reject__e(struct ctx* ctx, struct fut_0* f, struct result_0 result);
struct fut_state_0 with_lock_1(struct ctx* ctx, struct lock* a, struct fun_act0_2 f);
struct fut_state_0 subscript_9(struct ctx* ctx, struct fun_act0_2 a);
struct fut_state_0 call_w_ctx_185(struct fun_act0_2 a, struct ctx* ctx);
struct fut_state_0 resolve_or_reject__e__lambda0(struct ctx* ctx, struct resolve_or_reject__e__lambda0* _closure);
struct void_ call_callbacks__e(struct ctx* ctx, struct fut_state_callbacks_0* cbs, struct result_0 value);
struct void_ forward_to__e__lambda0(struct ctx* ctx, struct forward_to__e__lambda0* _closure, struct result_0 it);
struct fut_0* subscript_10(struct ctx* ctx, struct fun_ref1 f, struct void_ p0);
struct island* get_island(struct ctx* ctx, uint64_t island_id);
struct island* subscript_11(struct ctx* ctx, struct arr_3 a, uint64_t index);
struct island* unsafe_at_0(struct arr_3 a, uint64_t index);
struct island* subscript_12(struct island** a, uint64_t n);
struct void_ add_task_0(struct ctx* ctx, struct island* a, uint64_t exclusion, struct fun_act0_0 action);
struct void_ add_task_1(struct ctx* ctx, struct island* a, uint64_t timestamp, uint64_t exclusion, struct fun_act0_0 action);
struct task_queue_node* task_queue_node(struct ctx* ctx, struct task task);
struct void_ insert_task__e(struct task_queue* a, struct task_queue_node* inserted);
uint64_t size_1(struct task_queue* a);
uint64_t size_recur(struct opt_2 node, uint64_t acc);
struct void_ insert_recur(struct task_queue_node* prev, struct task_queue_node* inserted);
struct task_queue* tasks(struct island* a);
struct void_ broadcast__e(struct condition* a);
extern int32_t pthread_mutex_lock(struct pthread_mutex_t* mutex);
extern int32_t pthread_cond_broadcast(struct pthread_cond_t* cond);
extern int32_t pthread_mutex_unlock(struct pthread_mutex_t* mutex);
uint64_t no_timestamp(void);
struct void_ catch(struct ctx* ctx, struct fun_act0_0 try, struct fun_act1_5 catcher);
struct void_ catch_with_exception_ctx(struct ctx* ctx, struct exception_ctx* ec, struct fun_act0_0 try, struct fun_act1_5 catcher);
struct bytes64 zero_0(void);
struct bytes32 zero_1(void);
struct bytes16 zero_2(void);
struct bytes128 zero_3(void);
extern int32_t setjmp(struct jmp_buf_tag* env);
struct void_ subscript_13(struct ctx* ctx, struct fun_act1_5 a, struct exception p0);
struct void_ call_w_ctx_215(struct fun_act1_5 a, struct ctx* ctx, struct exception p0);
struct fut_0* subscript_14(struct ctx* ctx, struct fun_act1_4 a, struct void_ p0);
struct fut_0* call_w_ctx_217(struct fun_act1_4 a, struct ctx* ctx, struct void_ p0);
struct void_ subscript_10__lambda0__lambda0(struct ctx* ctx, struct subscript_10__lambda0__lambda0* _closure);
struct void_ reject__e(struct ctx* ctx, struct fut_0* f, struct exception e);
struct void_ subscript_10__lambda0__lambda1(struct ctx* ctx, struct subscript_10__lambda0__lambda1* _closure, struct exception it);
struct void_ subscript_10__lambda0(struct ctx* ctx, struct subscript_10__lambda0* _closure);
struct void_ then__lambda0(struct ctx* ctx, struct then__lambda0* _closure, struct result_1 result);
struct fut_0* subscript_15(struct ctx* ctx, struct fun_ref0 f);
struct fut_0* subscript_16(struct ctx* ctx, struct fun_act0_1 a);
struct fut_0* call_w_ctx_225(struct fun_act0_1 a, struct ctx* ctx);
struct void_ subscript_15__lambda0__lambda0(struct ctx* ctx, struct subscript_15__lambda0__lambda0* _closure);
struct void_ subscript_15__lambda0__lambda1(struct ctx* ctx, struct subscript_15__lambda0__lambda1* _closure, struct exception it);
struct void_ subscript_15__lambda0(struct ctx* ctx, struct subscript_15__lambda0* _closure);
struct fut_0* then_void__lambda0(struct ctx* ctx, struct then_void__lambda0* _closure, struct void_ ignore);
struct island_and_exclusion cur_island_and_exclusion(struct ctx* ctx);
struct fut_1* delay(struct ctx* ctx);
struct fut_1* resolved_0(struct ctx* ctx, struct void_ value);
struct arr_5 tail(struct ctx* ctx, struct arr_5 a);
uint8_t empty__q_2(struct arr_5 a);
struct arr_5 subscript_17(struct ctx* ctx, struct arr_5 a, struct arrow range);
struct arr_1 map(struct ctx* ctx, struct arr_5 a, struct fun_act1_6 f);
struct arr_1 make_arr(struct ctx* ctx, uint64_t size, struct fun_act1_7 f);
struct str* alloc_uninitialized_1(struct ctx* ctx, uint64_t size);
struct void_ fill_ptr_range(struct ctx* ctx, struct str* begin, uint64_t size, struct fun_act1_7 f);
struct void_ fill_ptr_range_recur(struct ctx* ctx, struct str* begin, uint64_t i, uint64_t size, struct fun_act1_7 f);
struct str subscript_18(struct ctx* ctx, struct fun_act1_7 a, uint64_t p0);
struct str call_w_ctx_242(struct fun_act1_7 a, struct ctx* ctx, uint64_t p0);
struct str subscript_19(struct ctx* ctx, struct fun_act1_6 a, char* p0);
struct str call_w_ctx_244(struct fun_act1_6 a, struct ctx* ctx, char* p0);
char* subscript_20(struct ctx* ctx, struct arr_5 a, uint64_t index);
char* unsafe_at_1(struct arr_5 a, uint64_t index);
char* subscript_21(char** a, uint64_t n);
struct str map__lambda0(struct ctx* ctx, struct map__lambda0* _closure, uint64_t i);
struct str to_str_2(char* a);
struct arr_0 arr_from_begin_end(char* begin, char* end);
uint8_t ptr_less_eq__q_2(char* a, char* b);
uint64_t _minus_2(char* a, char* b);
char* find_cstr_end(char* a);
struct opt_8 find_char_in_cstr(char* a, char c);
uint8_t _equal(char a, char b);
char* hard_unreachable_1(void);
struct str add_first_task__lambda0__lambda0(struct ctx* ctx, struct void_ _closure, char* it);
struct fut_0* add_first_task__lambda0(struct ctx* ctx, struct add_first_task__lambda0* _closure);
struct void_ handle_exceptions(struct ctx* ctx, struct fut_0* a);
struct void_ subscript_22(struct ctx* ctx, struct fun1_0 a, struct exception p0);
struct void_ call_w_ctx_261(struct fun1_0 a, struct ctx* ctx, struct exception p0);
struct fun1_0 exception_handler(struct ctx* ctx, struct island* a);
struct island* get_cur_island(struct ctx* ctx);
struct void_ handle_exceptions__lambda0(struct ctx* ctx, struct void_ _closure, struct result_0 result);
struct fut_0* add_main_task__lambda0(struct ctx* ctx, struct void_ _closure, struct arr_5 all_args, fun_ptr2 main_ptr);
struct fut_0* call_w_ctx_266(struct fun_act2 a, struct ctx* ctx, struct arr_5 p0, fun_ptr2 p1);
struct void_ run_threads(uint64_t n_threads, struct global_ctx* gctx);
struct thread_args* unmanaged_alloc_elements_1(uint64_t size_elements);
struct void_ start_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads, struct thread_args* thread_args_begin, struct global_ctx* gctx);
struct void_ create_one_thread(struct cell_0* tid, uint8_t* thread_arg, fun_ptr1 thread_fun);
extern int32_t pthread_create(struct cell_0* thread, uint8_t* attr, fun_ptr1 start_routine, uint8_t* arg);
uint8_t _notEqual_2(int32_t a, int32_t b);
int32_t eagain(void);
struct cell_0* as_cell(uint64_t* p);
uint8_t* thread_fun(uint8_t* args_ptr);
struct void_ thread_function(uint64_t thread_id, struct global_ctx* gctx);
struct void_ thread_function_recur(struct global_ctx* gctx, struct thread_local_stuff* tls);
struct void_ assert_islands_are_shut_down(uint64_t i, struct arr_3 islands);
struct island* noctx_at_0(struct arr_3 a, uint64_t index);
uint8_t empty__q_3(struct task_queue* a);
uint8_t empty__q_4(struct opt_2 a);
uint64_t get_sequence(struct condition* a);
struct choose_task_result choose_task(struct global_ctx* gctx);
uint64_t get_monotime_nsec(void);
extern int32_t clock_gettime(int32_t clock_id, struct cell_1* timespec);
uint64_t todo_2(void);
struct choose_task_result choose_task_recur(struct arr_3 islands, uint64_t i, uint64_t cur_time, uint8_t any_tasks__q, struct opt_9 first_task_time);
struct choose_task_in_island_result choose_task_in_island(struct island* island, uint64_t cur_time);
struct pop_task_result pop_task__e(struct task_queue* a, uint64_t cur_time);
uint8_t contains__q_0(struct mut_list_0* a, uint64_t value);
uint8_t contains__q_1(struct arr_2 a, uint64_t value);
uint8_t contains_recur__q(struct arr_2 a, uint64_t value, uint64_t i);
uint64_t noctx_at_1(struct arr_2 a, uint64_t index);
uint64_t unsafe_at_2(struct arr_2 a, uint64_t index);
uint64_t subscript_23(uint64_t* a, uint64_t n);
struct arr_2 temp_as_arr_0(struct mut_list_0* a);
struct arr_2 temp_as_arr_1(struct mut_arr_0 a);
struct mut_arr_0 temp_as_mut_arr(struct mut_list_0* a);
uint64_t* begin_ptr_2(struct mut_list_0* a);
uint64_t* begin_ptr_3(struct mut_arr_0 a);
struct pop_task_result pop_recur__e(struct task_queue_node* prev, struct mut_list_0* exclusions, uint64_t cur_time, struct opt_9 first_task_time);
struct opt_9 to_opt_time(uint64_t a);
struct void_ push_capacity_must_be_sufficient__e(struct mut_list_0* a, uint64_t value);
uint64_t capacity_1(struct mut_list_0* a);
uint64_t size_2(struct mut_arr_0 a);
struct void_ set_subscript_3(uint64_t* a, uint64_t n, uint64_t value);
uint8_t is_no_task__q(struct choose_task_in_island_result a);
struct opt_9 min_time(struct opt_9 a, struct opt_9 b);
uint64_t min(uint64_t a, uint64_t b);
struct void_ do_task(struct global_ctx* gctx, struct thread_local_stuff* tls, struct chosen_task chosen_task);
struct void_ return_task__e(struct task_queue* a, struct task task);
struct void_ noctx_must_remove_unordered__e(struct mut_list_0* a, uint64_t value);
struct void_ noctx_must_remove_unordered_recur__e(struct mut_list_0* a, uint64_t index, uint64_t value);
struct void_ drop(uint64_t _p0);
uint64_t noctx_remove_unordered_at__e(struct mut_list_0* a, uint64_t index);
struct void_ return_ctx(struct ctx* c);
struct void_ return_gc_ctx(struct gc_ctx* gc_ctx);
struct void_ run_garbage_collection(struct gc* gc, struct island_gc_root gc_root);
struct void_ mark_visit_319(struct mark_ctx* mark_ctx, struct island_gc_root value);
struct void_ mark_visit_320(struct mark_ctx* mark_ctx, struct task_queue value);
struct void_ mark_visit_321(struct mark_ctx* mark_ctx, struct opt_2 value);
struct void_ mark_visit_322(struct mark_ctx* mark_ctx, struct some_2 value);
struct void_ mark_visit_323(struct mark_ctx* mark_ctx, struct task_queue_node value);
struct void_ mark_visit_324(struct mark_ctx* mark_ctx, struct task value);
struct void_ mark_visit_325(struct mark_ctx* mark_ctx, struct fun_act0_0 value);
struct void_ mark_visit_326(struct mark_ctx* mark_ctx, struct callback__e_0__lambda0 value);
struct void_ mark_visit_327(struct mark_ctx* mark_ctx, struct fut_1 value);
struct void_ mark_visit_328(struct mark_ctx* mark_ctx, struct fut_state_1 value);
struct void_ mark_visit_329(struct mark_ctx* mark_ctx, struct fut_state_callbacks_1 value);
struct void_ mark_visit_330(struct mark_ctx* mark_ctx, struct fun_act1_3 value);
struct void_ mark_visit_331(struct mark_ctx* mark_ctx, struct then__lambda0 value);
struct void_ mark_visit_332(struct mark_ctx* mark_ctx, struct fun_ref1 value);
struct void_ mark_visit_333(struct mark_ctx* mark_ctx, struct fun_act1_4 value);
struct void_ mark_visit_334(struct mark_ctx* mark_ctx, struct then_void__lambda0 value);
struct void_ mark_visit_335(struct mark_ctx* mark_ctx, struct fun_ref0 value);
struct void_ mark_visit_336(struct mark_ctx* mark_ctx, struct fun_act0_1 value);
struct void_ mark_visit_337(struct mark_ctx* mark_ctx, struct add_first_task__lambda0 value);
struct void_ mark_arr_338(struct mark_ctx* mark_ctx, struct arr_5 a);
struct void_ mark_visit_339(struct mark_ctx* mark_ctx, struct add_first_task__lambda0* value);
struct void_ mark_visit_340(struct mark_ctx* mark_ctx, struct then_void__lambda0* value);
struct void_ mark_visit_341(struct mark_ctx* mark_ctx, struct fut_0 value);
struct void_ mark_visit_342(struct mark_ctx* mark_ctx, struct fut_state_0 value);
struct void_ mark_visit_343(struct mark_ctx* mark_ctx, struct fut_state_callbacks_0 value);
struct void_ mark_visit_344(struct mark_ctx* mark_ctx, struct fun_act1_0 value);
struct void_ mark_visit_345(struct mark_ctx* mark_ctx, struct forward_to__e__lambda0 value);
struct void_ mark_visit_346(struct mark_ctx* mark_ctx, struct fut_0* value);
struct void_ mark_visit_347(struct mark_ctx* mark_ctx, struct forward_to__e__lambda0* value);
struct void_ mark_visit_348(struct mark_ctx* mark_ctx, struct opt_0 value);
struct void_ mark_visit_349(struct mark_ctx* mark_ctx, struct some_0 value);
struct void_ mark_visit_350(struct mark_ctx* mark_ctx, struct fut_state_callbacks_0* value);
struct void_ mark_visit_351(struct mark_ctx* mark_ctx, struct exception value);
struct void_ mark_visit_352(struct mark_ctx* mark_ctx, struct str value);
struct void_ mark_arr_353(struct mark_ctx* mark_ctx, struct arr_0 a);
struct void_ mark_visit_354(struct mark_ctx* mark_ctx, struct backtrace value);
struct void_ mark_elems_355(struct mark_ctx* mark_ctx, struct str* cur, struct str* end);
struct void_ mark_arr_356(struct mark_ctx* mark_ctx, struct arr_1 a);
struct void_ mark_visit_357(struct mark_ctx* mark_ctx, struct then__lambda0* value);
struct void_ mark_visit_358(struct mark_ctx* mark_ctx, struct opt_7 value);
struct void_ mark_visit_359(struct mark_ctx* mark_ctx, struct some_7 value);
struct void_ mark_visit_360(struct mark_ctx* mark_ctx, struct fut_state_callbacks_1* value);
struct void_ mark_visit_361(struct mark_ctx* mark_ctx, struct fut_1* value);
struct void_ mark_visit_362(struct mark_ctx* mark_ctx, struct callback__e_0__lambda0* value);
struct void_ mark_visit_363(struct mark_ctx* mark_ctx, struct callback__e_1__lambda0 value);
struct void_ mark_visit_364(struct mark_ctx* mark_ctx, struct callback__e_1__lambda0* value);
struct void_ mark_visit_365(struct mark_ctx* mark_ctx, struct subscript_10__lambda0__lambda0 value);
struct void_ mark_visit_366(struct mark_ctx* mark_ctx, struct subscript_10__lambda0__lambda0* value);
struct void_ mark_visit_367(struct mark_ctx* mark_ctx, struct subscript_10__lambda0 value);
struct void_ mark_visit_368(struct mark_ctx* mark_ctx, struct subscript_10__lambda0* value);
struct void_ mark_visit_369(struct mark_ctx* mark_ctx, struct subscript_15__lambda0__lambda0 value);
struct void_ mark_visit_370(struct mark_ctx* mark_ctx, struct subscript_15__lambda0__lambda0* value);
struct void_ mark_visit_371(struct mark_ctx* mark_ctx, struct subscript_15__lambda0 value);
struct void_ mark_visit_372(struct mark_ctx* mark_ctx, struct subscript_15__lambda0* value);
struct void_ mark_visit_373(struct mark_ctx* mark_ctx, struct task_queue_node* value);
struct void_ mark_visit_374(struct mark_ctx* mark_ctx, struct mut_list_0 value);
struct void_ mark_visit_375(struct mark_ctx* mark_ctx, struct mut_arr_0 value);
struct void_ mark_arr_376(struct mark_ctx* mark_ctx, struct arr_2 a);
struct void_ clear_free_mem(uint8_t* mark_ptr, uint8_t* mark_end, uint64_t* data_ptr);
struct void_ wait_on(struct condition* a, struct opt_9 until_time, uint64_t last_sequence);
extern int32_t pthread_cond_wait(struct pthread_cond_t* cond, struct pthread_mutex_t* mutex);
struct timespec to_timespec(uint64_t a);
extern int32_t pthread_cond_timedwait(struct pthread_cond_t* cond, struct pthread_mutex_t* mutex, struct timespec* abstime);
int32_t etimedout(void);
struct void_ join_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads);
struct void_ join_one_thread(uint64_t tid);
extern int32_t pthread_join(uint64_t thread, struct cell_2* thread_return);
int32_t einval(void);
int32_t esrch(void);
struct void_ unmanaged_free_0(uint64_t* p);
extern void free(uint8_t* p);
struct void_ unmanaged_free_1(struct thread_args* p);
struct void_ destroy_condition(struct condition* a);
extern int32_t pthread_mutexattr_destroy(struct pthread_mutexattr_t* attr);
extern int32_t pthread_mutex_destroy(struct pthread_mutex_t* mutex);
extern int32_t pthread_condattr_destroy(struct pthread_condattr_t* attr);
extern int32_t pthread_cond_destroy(struct pthread_cond_t* cond);
struct fut_0* main_0(struct ctx* ctx, struct arr_1 _p0);
struct fut_0* resolved_1(struct ctx* ctx, uint64_t value);
int32_t main(int32_t argc, char** argv);
/* mark bool(ctx mark-ctx, ptr-any ptr<nat8>, size-bytes nat) */
uint8_t mark(struct mark_ctx* ctx, uint8_t* ptr_any, uint64_t size_bytes) {
	uint8_t _0 = word_aligned__q(ptr_any);
	hard_assert(_0);
	uint64_t size_words0;
	size_words0 = words_of_bytes(size_bytes);
	
	uint64_t* ptr1;
	ptr1 = ((uint64_t*) ptr_any);
	
	uint64_t index2;
	index2 = _minus_0(ptr1, ctx->memory_start);
	
	uint8_t gc_memory__q3;
	gc_memory__q3 = _less(index2, ctx->memory_size_words);
	
	uint8_t _1 = gc_memory__q3;
	if (_1) {
		uint8_t _2 = _lessOrEqual((index2 + size_words0), ctx->memory_size_words);
		hard_assert(_2);
		uint8_t* mark_start4;
		mark_start4 = (ctx->marks + index2);
		
		uint8_t* mark_end5;
		mark_end5 = (mark_start4 + size_words0);
		
		return mark_range_recur(0, mark_start4, mark_end5);
	} else {
		uint8_t _3 = _greater((index2 + size_words0), ctx->memory_size_words);
		hard_assert(_3);
		return 0;
	}
}
/* hard-assert void(condition bool) */
struct void_ hard_assert(uint8_t condition) {
	uint8_t _0 = condition;
	if (_0) {
		return (struct void_) {};
	} else {
		return (abort(), (struct void_) {});
	}
}
/* word-aligned? bool(a ptr<nat8>) */
uint8_t word_aligned__q(uint8_t* a) {
	return ((((uint64_t) a) & 7u) == 0u);
}
/* words-of-bytes nat(size-bytes nat) */
uint64_t words_of_bytes(uint64_t size_bytes) {
	uint64_t _0 = round_up_to_multiple_of_8(size_bytes);
	return (_0 / 8u);
}
/* round-up-to-multiple-of-8 nat(n nat) */
uint64_t round_up_to_multiple_of_8(uint64_t n) {
	return ((n + 7u) & (~7u));
}
/* -<nat> nat(a ptr<nat>, b ptr<nat>) */
uint64_t _minus_0(uint64_t* a, uint64_t* b) {
	return ((((uint64_t) a) - ((uint64_t) b)) / sizeof(uint64_t));
}
/* <=> comparison(a nat, b nat) */
struct comparison _compare(uint64_t a, uint64_t b) {
	uint8_t _0 = (a < b);
	if (_0) {
		return (struct comparison) {0, .as0 = (struct less) {}};
	} else {
		uint8_t _1 = (a == b);
		if (_1) {
			return (struct comparison) {1, .as1 = (struct equal) {}};
		} else {
			return (struct comparison) {2, .as2 = (struct greater) {}};
		}
	}
}
/* <<nat> bool(a nat, b nat) */
uint8_t _less(uint64_t a, uint64_t b) {
	struct comparison _0 = _compare(a, b);
	switch (_0.kind) {
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
			
	return 0;;
	}
}
/* <=<nat> bool(a nat, b nat) */
uint8_t _lessOrEqual(uint64_t a, uint64_t b) {
	uint8_t _0 = _less(b, a);
	return not(_0);
}
/* not bool(a bool) */
uint8_t not(uint8_t a) {
	uint8_t _0 = a;
	if (_0) {
		return 0;
	} else {
		return 1;
	}
}
/* mark-range-recur bool(marked-anything? bool, cur ptr<bool>, end ptr<bool>) */
uint8_t mark_range_recur(uint8_t marked_anything__q, uint8_t* cur, uint8_t* end) {
	top:;
	uint8_t _0 = (cur == end);
	if (_0) {
		return marked_anything__q;
	} else {
		uint8_t new_marked_anything__q0;
		if (marked_anything__q) {
			new_marked_anything__q0 = 1;
		} else {
			new_marked_anything__q0 = not((*cur));
		}
		
		*cur = 1;
		marked_anything__q = new_marked_anything__q0;
		cur = (cur + 1u);
		end = end;
		goto top;
	}
}
/* ><nat> bool(a nat, b nat) */
uint8_t _greater(uint64_t a, uint64_t b) {
	return _less(b, a);
}
/* rt-main int32(argc int32, argv ptr<ptr<char>>, main-ptr fun-ptr2<fut<nat>, ctx, arr<str>>) */
int32_t rt_main(int32_t argc, char** argv, fun_ptr2 main_ptr) {
	uint64_t n_threads0;
	n_threads0 = get_nprocs();
	
	uint8_t f1;
	f1 = 0;
	
	struct global_ctx gctx_by_val2;
	struct lock _0 = lock_by_val();
	struct lock _1 = lock_by_val();
	struct condition _2 = create_condition();
	gctx_by_val2 = (struct global_ctx) {_0, _1, (struct arr_3) {0u, NULL}, n_threads0, _2, f1, f1};
	
	struct global_ctx* gctx3;
	gctx3 = (&gctx_by_val2);
	
	struct island island_by_val4;
	island_by_val4 = island(gctx3, 0u, n_threads0);
	
	struct island* island5;
	island5 = (&island_by_val4);
	
	gctx3->islands = (struct arr_3) {1u, (&island5)};
	struct fut_0* main_fut6;
	main_fut6 = add_main_task(gctx3, (n_threads0 - 1u), island5, argc, argv, main_ptr);
	
	run_threads(n_threads0, gctx3);
	destroy_condition((&(&gctx_by_val2)->may_be_work_to_do));
	struct fut_state_0 _3 = main_fut6->state;
	switch (_3.kind) {
		case 0: {
			return 1;
		}
		case 1: {
			return 1;
		}
		case 2: {
			struct fut_state_resolved_0 r7 = _3.as2;
			
			uint8_t _4 = gctx3->any_unhandled_exceptions__q;
			if (_4) {
				return 1;
			} else {
				return ((int32_t) ((int64_t) r7.value));
			}
		}
		case 3: {
			return 1;
		}
		default:
			
	return 0;;
	}
}
/* lock-by-val lock() */
struct lock lock_by_val(void) {
	struct _atomic_bool _0 = _atomic_bool();
	return (struct lock) {_0};
}
/* atomic-bool atomic-bool() */
struct _atomic_bool _atomic_bool(void) {
	return (struct _atomic_bool) {0};
}
/* create-condition condition() */
struct condition create_condition(void) {
	struct condition res0;
	res0 = (struct condition) {(struct pthread_mutexattr_t) {0}, (struct pthread_mutex_t) {(struct bytes40) {(struct bytes32) {(struct bytes16) {0, 0}, (struct bytes16) {0, 0}}, 0}}, (struct pthread_condattr_t) {0}, (struct pthread_cond_t) {(struct bytes48) {(struct bytes32) {(struct bytes16) {0, 0}, (struct bytes16) {0, 0}}, (struct bytes16) {0, 0}}}, 0u};
	
	int32_t _0 = pthread_mutexattr_init((&(&res0)->mutex_attr));
	hard_assert_posix_error(_0);
	int32_t _1 = pthread_mutex_init((&(&res0)->mutex), (&(&res0)->mutex_attr));
	hard_assert_posix_error(_1);
	int32_t _2 = pthread_condattr_init((&(&res0)->cond_attr));
	hard_assert_posix_error(_2);
	int32_t _3 = clock_monotonic();
	int32_t _4 = pthread_condattr_setclock((&(&res0)->cond_attr), _3);
	hard_assert_posix_error(_4);
	int32_t _5 = pthread_cond_init((&(&res0)->cond), (&(&res0)->cond_attr));
	hard_assert_posix_error(_5);
	return res0;
}
/* hard-assert-posix-error void(err int32) */
struct void_ hard_assert_posix_error(int32_t err) {
	return hard_assert((err == 0));
}
/* clock-monotonic int32() */
int32_t clock_monotonic(void) {
	return 1;
}
/* island island(gctx global-ctx, id nat, max-threads nat) */
struct island island(struct global_ctx* gctx, uint64_t id, uint64_t max_threads) {
	struct task_queue q0;
	q0 = task_queue(max_threads);
	
	struct island_gc_root gc_root1;
	gc_root1 = (struct island_gc_root) {q0, (struct fun1_0) {0, .as0 = (struct void_) {}}, (struct fun1_1) {0, .as0 = (struct void_) {}}};
	
	struct gc _0 = gc();
	struct lock _1 = lock_by_val();
	struct thread_safe_counter _2 = thread_safe_counter_0();
	return (struct island) {gctx, id, _0, gc_root1, _1, 0u, _2};
}
/* task-queue task-queue(max-threads nat) */
struct task_queue task_queue(uint64_t max_threads) {
	struct mut_list_0 _0 = mut_list_by_val_with_capacity_from_unmanaged_memory(max_threads);
	return (struct task_queue) {(struct opt_2) {0, .as0 = (struct none) {}}, _0};
}
/* mut-list-by-val-with-capacity-from-unmanaged-memory<nat> mut-list<nat>(capacity nat) */
struct mut_list_0 mut_list_by_val_with_capacity_from_unmanaged_memory(uint64_t capacity) {
	struct mut_arr_0 backing0;
	uint64_t* _0 = unmanaged_alloc_zeroed_elements(capacity);
	backing0 = mut_arr_0(capacity, _0);
	
	return (struct mut_list_0) {backing0, 0u};
}
/* mut-arr<?a> mut-arr<nat>(size nat, begin-ptr ptr<nat>) */
struct mut_arr_0 mut_arr_0(uint64_t size, uint64_t* begin_ptr) {
	return (struct mut_arr_0) {(struct void_) {}, (struct arr_2) {size, begin_ptr}};
}
/* unmanaged-alloc-zeroed-elements<?a> ptr<nat>(size-elements nat) */
uint64_t* unmanaged_alloc_zeroed_elements(uint64_t size_elements) {
	uint64_t* res0;
	res0 = unmanaged_alloc_elements_0(size_elements);
	
	set_zero_range_0(res0, size_elements);
	return res0;
}
/* unmanaged-alloc-elements<?a> ptr<nat>(size-elements nat) */
uint64_t* unmanaged_alloc_elements_0(uint64_t size_elements) {
	uint8_t* _0 = unmanaged_alloc_bytes((size_elements * sizeof(uint64_t)));
	return ((uint64_t*) _0);
}
/* unmanaged-alloc-bytes ptr<nat8>(size nat) */
uint8_t* unmanaged_alloc_bytes(uint64_t size) {
	uint8_t* res0;
	res0 = malloc(size);
	
	uint8_t _0 = null__q_0(res0);
	hard_forbid(_0);
	return res0;
}
/* hard-forbid void(condition bool) */
struct void_ hard_forbid(uint8_t condition) {
	uint8_t _0 = condition;
	if (_0) {
		return (abort(), (struct void_) {});
	} else {
		return (struct void_) {};
	}
}
/* null?<nat8> bool(a ptr<nat8>) */
uint8_t null__q_0(uint8_t* a) {
	return (a == NULL);
}
/* set-zero-range<?a> void(begin ptr<nat>, size nat) */
struct void_ set_zero_range_0(uint64_t* begin, uint64_t size) {
	return (memset(((uint8_t*) begin), 0u, (size * sizeof(uint64_t))), (struct void_) {});
}
/* default-exception-handler void(e exception) */
struct void_ default_exception_handler(struct ctx* ctx, struct exception e) {
	print_err_no_newline((struct str) {{20, constantarr_0_0}});
	struct str _0 = to_str_0(ctx, e);
	print_err(_0);
	struct global_ctx* _1 = get_global_ctx(ctx);
	return (_1->any_unhandled_exceptions__q = 1, (struct void_) {});
}
/* print-err-no-newline void(s str) */
struct void_ print_err_no_newline(struct str s) {
	int32_t _0 = stderr();
	return write_no_newline(_0, s);
}
/* write-no-newline void(fd int32, a str) */
struct void_ write_no_newline(int32_t fd, struct str a) {
	hard_assert((sizeof(char) == sizeof(uint8_t)));
	int64_t res0;
	uint64_t _0 = size_bytes(a);
	res0 = write(fd, ((uint8_t*) a.chars.begin_ptr), _0);
	
	uint64_t _1 = size_bytes(a);
	uint8_t _2 = _notEqual_0(res0, ((int64_t) _1));
	if (_2) {
		return todo_0();
	} else {
		return (struct void_) {};
	}
}
/* size-bytes nat(a str) */
uint64_t size_bytes(struct str a) {
	return a.chars.size;
}
/* !=<int> bool(a int, b int) */
uint8_t _notEqual_0(int64_t a, int64_t b) {
	return not((a == b));
}
/* todo<void> void() */
struct void_ todo_0(void) {
	(abort(), (struct void_) {});
	return (struct void_) {};
}
/* stderr int32() */
int32_t stderr(void) {
	return 2;
}
/* print-err void(s str) */
struct void_ print_err(struct str s) {
	print_err_no_newline(s);
	return print_err_no_newline((struct str) {{1, constantarr_0_1}});
}
/* to-str str(a exception) */
struct str to_str_0(struct ctx* ctx, struct exception a) {
	struct writer res0;
	res0 = writer(ctx);
	
	uint8_t _0 = empty__q_0(a.message);struct str _1;
	
	if (_0) {
		_1 = (struct str) {{17, constantarr_0_5}};
	} else {
		_1 = a.message;
	}
	_concatEquals_0(ctx, res0, _1);
	struct to_str_0__lambda0* temp0;
	uint8_t* _2 = alloc(ctx, sizeof(struct to_str_0__lambda0));
	temp0 = ((struct to_str_0__lambda0*) _2);
	
	*temp0 = (struct to_str_0__lambda0) {res0};
	each_1(ctx, a.backtrace.return_stack, (struct fun_act1_2) {0, .as0 = temp0});
	return move_to_str__e(ctx, res0);
}
/* writer writer() */
struct writer writer(struct ctx* ctx) {
	struct mut_list_1* _0 = mut_list(ctx);
	return (struct writer) {_0};
}
/* mut-list<char> mut-list<char>() */
struct mut_list_1* mut_list(struct ctx* ctx) {
	struct mut_list_1* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_list_1));
	temp0 = ((struct mut_list_1*) _0);
	
	struct mut_arr_1 _1 = mut_arr_1();
	*temp0 = (struct mut_list_1) {_1, 0u};
	return temp0;
}
/* mut-arr<?a> mut-arr<char>() */
struct mut_arr_1 mut_arr_1(void) {
	return (struct mut_arr_1) {(struct void_) {}, (struct arr_0) {0u, NULL}};
}
/* ~= void(a writer, b str) */
struct void_ _concatEquals_0(struct ctx* ctx, struct writer a, struct str b) {
	return _concatEquals_1(ctx, a.chars, b.chars);
}
/* ~=<char> void(a mut-list<char>, values arr<char>) */
struct void_ _concatEquals_1(struct ctx* ctx, struct mut_list_1* a, struct arr_0 values) {
	struct _concatEquals_1__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct _concatEquals_1__lambda0));
	temp0 = ((struct _concatEquals_1__lambda0*) _0);
	
	*temp0 = (struct _concatEquals_1__lambda0) {a};
	return each_0(ctx, values, (struct fun_act1_1) {0, .as0 = temp0});
}
/* each<?a> void(a arr<char>, f fun-act1<void, char>) */
struct void_ each_0(struct ctx* ctx, struct arr_0 a, struct fun_act1_1 f) {
	char* _0 = end_ptr_0(a);
	return each_recur_0(ctx, a.begin_ptr, _0, f);
}
/* each-recur<?a> void(cur ptr<char>, end ptr<char>, f fun-act1<void, char>) */
struct void_ each_recur_0(struct ctx* ctx, char* cur, char* end, struct fun_act1_1 f) {
	top:;
	uint8_t _0 = not((cur == end));
	if (_0) {
		subscript_0(ctx, f, (*cur));
		cur = (cur + 1u);
		end = end;
		f = f;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* subscript<void, ?a> void(a fun-act1<void, char>, p0 char) */
struct void_ subscript_0(struct ctx* ctx, struct fun_act1_1 a, char p0) {
	return call_w_ctx_55(a, ctx, p0);
}
/* call-w-ctx<void, char> (generated) (generated) */
struct void_ call_w_ctx_55(struct fun_act1_1 a, struct ctx* ctx, char p0) {
	struct fun_act1_1 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct _concatEquals_1__lambda0* closure0 = _0.as0;
			
			return _concatEquals_1__lambda0(ctx, closure0, p0);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* end-ptr<?a> ptr<char>(a arr<char>) */
char* end_ptr_0(struct arr_0 a) {
	return (a.begin_ptr + a.size);
}
/* ~=<?a> void(a mut-list<char>, value char) */
struct void_ _concatEquals_2(struct ctx* ctx, struct mut_list_1* a, char value) {
	incr_capacity__e(ctx, a);
	uint64_t _0 = capacity_0(a);
	uint8_t _1 = _less(a->size, _0);
	assert(ctx, _1);
	char* _2 = begin_ptr_0(a);
	set_subscript_2(_2, a->size, value);
	uint64_t _3 = _plus(ctx, a->size, 1u);
	return (a->size = _3, (struct void_) {});
}
/* incr-capacity!<?a> void(a mut-list<char>) */
struct void_ incr_capacity__e(struct ctx* ctx, struct mut_list_1* a) {
	uint64_t _0 = _plus(ctx, a->size, 1u);
	uint64_t _1 = round_up_to_power_of_two(ctx, _0);
	return ensure_capacity(ctx, a, _1);
}
/* ensure-capacity<?a> void(a mut-list<char>, min-capacity nat) */
struct void_ ensure_capacity(struct ctx* ctx, struct mut_list_1* a, uint64_t min_capacity) {
	uint64_t _0 = capacity_0(a);
	uint8_t _1 = _less(_0, min_capacity);
	if (_1) {
		return increase_capacity_to__e(ctx, a, min_capacity);
	} else {
		return (struct void_) {};
	}
}
/* capacity<?a> nat(a mut-list<char>) */
uint64_t capacity_0(struct mut_list_1* a) {
	return size_0(a->backing);
}
/* size<?a> nat(a mut-arr<char>) */
uint64_t size_0(struct mut_arr_1 a) {
	return a.inner.size;
}
/* increase-capacity-to!<?a> void(a mut-list<char>, new-capacity nat) */
struct void_ increase_capacity_to__e(struct ctx* ctx, struct mut_list_1* a, uint64_t new_capacity) {
	uint64_t _0 = capacity_0(a);
	uint8_t _1 = _greater(new_capacity, _0);
	assert(ctx, _1);
	char* old_begin0;
	old_begin0 = begin_ptr_0(a);
	
	struct mut_arr_1 _2 = uninitialized_mut_arr(ctx, new_capacity);
	a->backing = _2;
	char* _3 = begin_ptr_0(a);
	copy_data_from(ctx, _3, old_begin0, a->size);
	uint64_t _4 = _plus(ctx, a->size, 1u);
	uint64_t _5 = size_0(a->backing);
	struct arrow _6 = _arrow(ctx, _4, _5);
	struct mut_arr_1 _7 = subscript_3(ctx, a->backing, _6);
	return set_zero_elements(_7);
}
/* assert void(condition bool) */
struct void_ assert(struct ctx* ctx, uint8_t condition) {
	uint8_t _0 = not(condition);
	if (_0) {
		return throw_0(ctx, (struct str) {{13, constantarr_0_3}});
	} else {
		return (struct void_) {};
	}
}
/* throw<void> void(message str) */
struct void_ throw_0(struct ctx* ctx, struct str message) {
	struct backtrace _0 = get_backtrace(ctx);
	return throw_1(ctx, (struct exception) {message, _0});
}
/* throw<?a> void(e exception) */
struct void_ throw_1(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx0;
	exn_ctx0 = get_exception_ctx(ctx);
	
	uint8_t _0 = null__q_1(exn_ctx0->jmp_buf_ptr);
	hard_forbid(_0);
	exn_ctx0->thrown_exception = e;
	int32_t _1 = number_to_throw(ctx);
	(longjmp(exn_ctx0->jmp_buf_ptr, _1), (struct void_) {});
	return hard_unreachable_0();
}
/* get-exception-ctx exception-ctx() */
struct exception_ctx* get_exception_ctx(struct ctx* ctx) {
	return ((struct exception_ctx*) ctx->thread_local_stuff->exception_ctx_ptr);
}
/* null?<jmp-buf-tag> bool(a ptr<jmp-buf-tag>) */
uint8_t null__q_1(struct jmp_buf_tag* a) {
	return (a == NULL);
}
/* number-to-throw int32() */
int32_t number_to_throw(struct ctx* ctx) {
	return 7;
}
/* hard-unreachable<?a> void() */
struct void_ hard_unreachable_0(void) {
	(abort(), (struct void_) {});
	return (struct void_) {};
}
/* get-backtrace backtrace() */
struct backtrace get_backtrace(struct ctx* ctx) {
	struct opt_3 _0 = try_alloc_backtrace_arrs(ctx);
	switch (_0.kind) {
		case 0: {
			return (struct backtrace) {(struct arr_1) {0u, NULL}};
		}
		case 1: {
			struct some_3 _matched0 = _0.as1;
			
			struct backtrace_arrs* arrs1;
			arrs1 = _matched0.value;
			
			uint64_t n_code_ptrs2;
			uint64_t _1 = code_ptrs_size(ctx);
			int32_t _2 = backtrace(arrs1->code_ptrs, ((int32_t) ((int64_t) _1)));
			n_code_ptrs2 = ((uint64_t) ((int64_t) _2));
			
			uint64_t _3 = code_ptrs_size(ctx);
			uint8_t _4 = _lessOrEqual(n_code_ptrs2, _3);
			hard_assert(_4);
			fill_fun_ptrs_names_recur(0u, arrs1->fun_ptrs, arrs1->fun_names);
			uint64_t _5 = funs_count_91();
			sort_together(ctx, arrs1->fun_ptrs, arrs1->fun_names, _5);
			struct str* end_code_names3;
			end_code_names3 = (arrs1->code_names + n_code_ptrs2);
			
			fill_code_names_recur(ctx, arrs1->code_names, end_code_names3, arrs1->code_ptrs, arrs1->fun_ptrs, arrs1->fun_names);
			return (struct backtrace) {(struct arr_1) {n_code_ptrs2, arrs1->code_names}};
		}
		default:
			
	return (struct backtrace) {(struct arr_1) {0, NULL}};;
	}
}
/* try-alloc-backtrace-arrs opt<backtrace-arrs>() */
struct opt_3 try_alloc_backtrace_arrs(struct ctx* ctx) {
	struct opt_4 _0 = try_alloc_uninitialized_0(ctx, 8u);
	switch (_0.kind) {
		case 0: {
			return (struct opt_3) {0, .as0 = (struct none) {}};
		}
		case 1: {
			struct some_4 _matched0 = _0.as1;
			
			uint8_t** code_ptrs1;
			code_ptrs1 = _matched0.value;
			
			struct opt_6 _1 = try_alloc_uninitialized_1(ctx, 8u);
			switch (_1.kind) {
				case 0: {
					return (struct opt_3) {0, .as0 = (struct none) {}};
				}
				case 1: {
					struct some_6 _matched2 = _1.as1;
					
					struct str* code_names3;
					code_names3 = _matched2.value;
					
					uint64_t _2 = funs_count_91();
					struct opt_4 _3 = try_alloc_uninitialized_0(ctx, _2);
					switch (_3.kind) {
						case 0: {
							return (struct opt_3) {0, .as0 = (struct none) {}};
						}
						case 1: {
							struct some_4 _matched4 = _3.as1;
							
							uint8_t** fun_ptrs5;
							fun_ptrs5 = _matched4.value;
							
							uint64_t _4 = funs_count_91();
							struct opt_6 _5 = try_alloc_uninitialized_1(ctx, _4);
							switch (_5.kind) {
								case 0: {
									return (struct opt_3) {0, .as0 = (struct none) {}};
								}
								case 1: {
									struct some_6 _matched6 = _5.as1;
									
									struct str* fun_names7;
									fun_names7 = _matched6.value;
									
									struct backtrace_arrs* temp0;
									uint8_t* _6 = alloc(ctx, sizeof(struct backtrace_arrs));
									temp0 = ((struct backtrace_arrs*) _6);
									
									*temp0 = (struct backtrace_arrs) {code_ptrs1, code_names3, fun_ptrs5, fun_names7};
									return (struct opt_3) {1, .as1 = (struct some_3) {temp0}};
								}
								default:
									
							return (struct opt_3) {0};;
							}
						}
						default:
							
					return (struct opt_3) {0};;
					}
				}
				default:
					
			return (struct opt_3) {0};;
			}
		}
		default:
			
	return (struct opt_3) {0};;
	}
}
/* try-alloc-uninitialized<ptr<nat8>> opt<ptr<ptr<nat8>>>(size nat) */
struct opt_4 try_alloc_uninitialized_0(struct ctx* ctx, uint64_t size) {
	struct opt_5 _0 = try_alloc(ctx, (size * sizeof(uint8_t*)));
	switch (_0.kind) {
		case 0: {
			return (struct opt_4) {0, .as0 = (struct none) {}};
		}
		case 1: {
			struct some_5 _matched0 = _0.as1;
			
			uint8_t* res1;
			res1 = _matched0.value;
			
			return (struct opt_4) {1, .as1 = (struct some_4) {((uint8_t**) res1)}};
		}
		default:
			
	return (struct opt_4) {0};;
	}
}
/* try-alloc opt<ptr<nat8>>(size-bytes nat) */
struct opt_5 try_alloc(struct ctx* ctx, uint64_t size_bytes) {
	struct gc* _0 = get_gc(ctx);
	return try_gc_alloc(_0, size_bytes);
}
/* try-gc-alloc opt<ptr<nat8>>(gc gc, size-bytes nat) */
struct opt_5 try_gc_alloc(struct gc* gc, uint64_t size_bytes) {
	acquire__e((&gc->lk));
	struct opt_5 res0;
	res0 = try_gc_alloc_recur(gc, size_bytes);
	
	release__e((&gc->lk));
	return res0;
}
/* acquire! void(a lock) */
struct void_ acquire__e(struct lock* a) {
	return acquire_recur__e(a, 0u);
}
/* acquire-recur! void(a lock, n-tries nat) */
struct void_ acquire_recur__e(struct lock* a, uint64_t n_tries) {
	top:;
	uint8_t _0 = try_acquire__e(a);
	uint8_t _1 = not(_0);
	if (_1) {
		uint8_t _2 = (n_tries == 10000u);
		if (_2) {
			return todo_0();
		} else {
			yield_thread();
			a = a;
			n_tries = (n_tries + 1u);
			goto top;
		}
	} else {
		return (struct void_) {};
	}
}
/* try-acquire! bool(a lock) */
uint8_t try_acquire__e(struct lock* a) {
	return try_set__e((&a->is_locked));
}
/* try-set! bool(a atomic-bool) */
uint8_t try_set__e(struct _atomic_bool* a) {
	return try_change__e(a, 0);
}
/* try-change! bool(a atomic-bool, old-value bool) */
uint8_t try_change__e(struct _atomic_bool* a, uint8_t old_value) {
	uint8_t* _0 = (&a->value);
	uint8_t* _1 = (&old_value);
	uint8_t _2 = not(old_value);
	return atomic_compare_exchange_strong(_0, _1, _2);
}
/* yield-thread void() */
struct void_ yield_thread(void) {
	int32_t err0;
	err0 = pthread_yield();
	
	return hard_assert((err0 == 0));
}
/* try-gc-alloc-recur opt<ptr<nat8>>(gc gc, size-bytes nat) */
struct opt_5 try_gc_alloc_recur(struct gc* gc, uint64_t size_bytes) {
	top:;
	uint64_t size_words0;
	size_words0 = words_of_bytes(size_bytes);
	
	uint64_t* cur1;
	cur1 = gc->data_cur;
	
	uint64_t* next2;
	next2 = (cur1 + size_words0);
	
	uint8_t _0 = (next2 < gc->data_end);
	if (_0) {
		uint8_t _1 = range_free__q(gc->mark_cur, (gc->mark_cur + size_words0));
		if (_1) {
			gc->mark_cur = (gc->mark_cur + size_words0);
			gc->data_cur = next2;
			return (struct opt_5) {1, .as1 = (struct some_5) {((uint8_t*) cur1)}};
		} else {
			gc->mark_cur = (gc->mark_cur + 1u);
			gc->data_cur = (gc->data_cur + 1u);
			gc = gc;
			size_bytes = size_bytes;
			goto top;
		}
	} else {
		return (struct opt_5) {0, .as0 = (struct none) {}};
	}
}
/* range-free? bool(mark ptr<bool>, end ptr<bool>) */
uint8_t range_free__q(uint8_t* mark, uint8_t* end) {
	top:;
	uint8_t _0 = (mark == end);
	if (_0) {
		return 1;
	} else {
		uint8_t _1 = (*mark);
		if (_1) {
			return 0;
		} else {
			mark = (mark + 1u);
			end = end;
			goto top;
		}
	}
}
/* release! void(a lock) */
struct void_ release__e(struct lock* a) {
	return must_unset__e((&a->is_locked));
}
/* must-unset! void(a atomic-bool) */
struct void_ must_unset__e(struct _atomic_bool* a) {
	uint8_t did_unset0;
	did_unset0 = try_unset__e(a);
	
	return hard_assert(did_unset0);
}
/* try-unset! bool(a atomic-bool) */
uint8_t try_unset__e(struct _atomic_bool* a) {
	return try_change__e(a, 1);
}
/* get-gc gc() */
struct gc* get_gc(struct ctx* ctx) {
	struct gc_ctx* _0 = get_gc_ctx_0(ctx);
	return _0->gc;
}
/* get-gc-ctx gc-ctx() */
struct gc_ctx* get_gc_ctx_0(struct ctx* ctx) {
	return ((struct gc_ctx*) ctx->gc_ctx_ptr);
}
/* try-alloc-uninitialized<str> opt<ptr<str>>(size nat) */
struct opt_6 try_alloc_uninitialized_1(struct ctx* ctx, uint64_t size) {
	struct opt_5 _0 = try_alloc(ctx, (size * sizeof(struct str)));
	switch (_0.kind) {
		case 0: {
			return (struct opt_6) {0, .as0 = (struct none) {}};
		}
		case 1: {
			struct some_5 _matched0 = _0.as1;
			
			uint8_t* res1;
			res1 = _matched0.value;
			
			return (struct opt_6) {1, .as1 = (struct some_6) {((struct str*) res1)}};
		}
		default:
			
	return (struct opt_6) {0};;
	}
}
/* funs-count (generated) (generated) */
uint64_t funs_count_91(void) {
	return 398u;
}
/* code-ptrs-size nat() */
uint64_t code_ptrs_size(struct ctx* ctx) {
	return 8u;
}
/* fill-fun-ptrs-names-recur void(i nat, fun-ptrs ptr<ptr<nat8>>, fun-names ptr<str>) */
struct void_ fill_fun_ptrs_names_recur(uint64_t i, uint8_t** fun_ptrs, struct str* fun_names) {
	top:;
	uint64_t _0 = funs_count_91();
	uint8_t _1 = _notEqual_1(i, _0);
	if (_1) {
		uint8_t* _2 = get_fun_ptr_97(i);
		set_subscript_0(fun_ptrs, i, _2);
		struct str _3 = get_fun_name_99(i);
		set_subscript_1(fun_names, i, _3);
		i = (i + 1u);
		fun_ptrs = fun_ptrs;
		fun_names = fun_names;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* !=<nat> bool(a nat, b nat) */
uint8_t _notEqual_1(uint64_t a, uint64_t b) {
	return not((a == b));
}
/* set-subscript<ptr<nat8>> void(a ptr<ptr<nat8>>, n nat, value ptr<nat8>) */
struct void_ set_subscript_0(uint8_t** a, uint64_t n, uint8_t* value) {
	return (*(a + n) = value, (struct void_) {});
}
/* get-fun-ptr (generated) (generated) */
uint8_t* get_fun_ptr_97(uint64_t fun_id) {switch (fun_id) {
		case 0: {
			return ((uint8_t*) mark);
		}
		case 1: {
			return ((uint8_t*) hard_assert);
		}
		case 2: {
			return ((uint8_t*) abort);
		}
		case 3: {
			return ((uint8_t*) word_aligned__q);
		}
		case 4: {
			return ((uint8_t*) words_of_bytes);
		}
		case 5: {
			return ((uint8_t*) round_up_to_multiple_of_8);
		}
		case 6: {
			return ((uint8_t*) _minus_0);
		}
		case 7: {
			return ((uint8_t*) _compare);
		}
		case 8: {
			return ((uint8_t*) _less);
		}
		case 9: {
			return ((uint8_t*) _lessOrEqual);
		}
		case 10: {
			return ((uint8_t*) not);
		}
		case 11: {
			return ((uint8_t*) mark_range_recur);
		}
		case 12: {
			return ((uint8_t*) _greater);
		}
		case 13: {
			return ((uint8_t*) rt_main);
		}
		case 14: {
			return ((uint8_t*) get_nprocs);
		}
		case 15: {
			return ((uint8_t*) lock_by_val);
		}
		case 16: {
			return ((uint8_t*) _atomic_bool);
		}
		case 17: {
			return ((uint8_t*) create_condition);
		}
		case 18: {
			return ((uint8_t*) hard_assert_posix_error);
		}
		case 19: {
			return ((uint8_t*) pthread_mutexattr_init);
		}
		case 20: {
			return ((uint8_t*) pthread_mutex_init);
		}
		case 21: {
			return ((uint8_t*) pthread_condattr_init);
		}
		case 22: {
			return ((uint8_t*) pthread_condattr_setclock);
		}
		case 23: {
			return ((uint8_t*) clock_monotonic);
		}
		case 24: {
			return ((uint8_t*) pthread_cond_init);
		}
		case 25: {
			return ((uint8_t*) island);
		}
		case 26: {
			return ((uint8_t*) task_queue);
		}
		case 27: {
			return ((uint8_t*) mut_list_by_val_with_capacity_from_unmanaged_memory);
		}
		case 28: {
			return ((uint8_t*) mut_arr_0);
		}
		case 29: {
			return ((uint8_t*) unmanaged_alloc_zeroed_elements);
		}
		case 30: {
			return ((uint8_t*) unmanaged_alloc_elements_0);
		}
		case 31: {
			return ((uint8_t*) unmanaged_alloc_bytes);
		}
		case 32: {
			return ((uint8_t*) malloc);
		}
		case 33: {
			return ((uint8_t*) hard_forbid);
		}
		case 34: {
			return ((uint8_t*) null__q_0);
		}
		case 35: {
			return ((uint8_t*) set_zero_range_0);
		}
		case 36: {
			return ((uint8_t*) memset);
		}
		case 37: {
			return ((uint8_t*) default_exception_handler);
		}
		case 38: {
			return ((uint8_t*) print_err_no_newline);
		}
		case 39: {
			return ((uint8_t*) write_no_newline);
		}
		case 40: {
			return ((uint8_t*) write);
		}
		case 41: {
			return ((uint8_t*) size_bytes);
		}
		case 42: {
			return ((uint8_t*) _notEqual_0);
		}
		case 43: {
			return ((uint8_t*) todo_0);
		}
		case 44: {
			return ((uint8_t*) stderr);
		}
		case 45: {
			return ((uint8_t*) print_err);
		}
		case 46: {
			return ((uint8_t*) to_str_0);
		}
		case 47: {
			return ((uint8_t*) writer);
		}
		case 48: {
			return ((uint8_t*) mut_list);
		}
		case 49: {
			return ((uint8_t*) mut_arr_1);
		}
		case 50: {
			return ((uint8_t*) _concatEquals_0);
		}
		case 51: {
			return ((uint8_t*) _concatEquals_1);
		}
		case 52: {
			return ((uint8_t*) each_0);
		}
		case 53: {
			return ((uint8_t*) each_recur_0);
		}
		case 54: {
			return ((uint8_t*) subscript_0);
		}
		case 55: {
			return ((uint8_t*) call_w_ctx_55);
		}
		case 56: {
			return ((uint8_t*) end_ptr_0);
		}
		case 57: {
			return ((uint8_t*) _concatEquals_2);
		}
		case 58: {
			return ((uint8_t*) incr_capacity__e);
		}
		case 59: {
			return ((uint8_t*) ensure_capacity);
		}
		case 60: {
			return ((uint8_t*) capacity_0);
		}
		case 61: {
			return ((uint8_t*) size_0);
		}
		case 62: {
			return ((uint8_t*) increase_capacity_to__e);
		}
		case 63: {
			return ((uint8_t*) assert);
		}
		case 64: {
			return ((uint8_t*) throw_0);
		}
		case 65: {
			return ((uint8_t*) throw_1);
		}
		case 66: {
			return ((uint8_t*) get_exception_ctx);
		}
		case 67: {
			return ((uint8_t*) null__q_1);
		}
		case 68: {
			return ((uint8_t*) longjmp);
		}
		case 69: {
			return ((uint8_t*) number_to_throw);
		}
		case 70: {
			return ((uint8_t*) hard_unreachable_0);
		}
		case 71: {
			return ((uint8_t*) get_backtrace);
		}
		case 72: {
			return ((uint8_t*) try_alloc_backtrace_arrs);
		}
		case 73: {
			return ((uint8_t*) try_alloc_uninitialized_0);
		}
		case 74: {
			return ((uint8_t*) try_alloc);
		}
		case 75: {
			return ((uint8_t*) try_gc_alloc);
		}
		case 76: {
			return ((uint8_t*) acquire__e);
		}
		case 77: {
			return ((uint8_t*) acquire_recur__e);
		}
		case 78: {
			return ((uint8_t*) try_acquire__e);
		}
		case 79: {
			return ((uint8_t*) try_set__e);
		}
		case 80: {
			return ((uint8_t*) try_change__e);
		}
		case 81: {
			return ((uint8_t*) yield_thread);
		}
		case 82: {
			return ((uint8_t*) pthread_yield);
		}
		case 83: {
			return ((uint8_t*) try_gc_alloc_recur);
		}
		case 84: {
			return ((uint8_t*) range_free__q);
		}
		case 85: {
			return ((uint8_t*) release__e);
		}
		case 86: {
			return ((uint8_t*) must_unset__e);
		}
		case 87: {
			return ((uint8_t*) try_unset__e);
		}
		case 88: {
			return ((uint8_t*) get_gc);
		}
		case 89: {
			return ((uint8_t*) get_gc_ctx_0);
		}
		case 90: {
			return ((uint8_t*) try_alloc_uninitialized_1);
		}
		case 91: {
			return ((uint8_t*) funs_count_91);
		}
		case 92: {
			return ((uint8_t*) backtrace);
		}
		case 93: {
			return ((uint8_t*) code_ptrs_size);
		}
		case 94: {
			return ((uint8_t*) fill_fun_ptrs_names_recur);
		}
		case 95: {
			return ((uint8_t*) _notEqual_1);
		}
		case 96: {
			return ((uint8_t*) set_subscript_0);
		}
		case 97: {
			return ((uint8_t*) get_fun_ptr_97);
		}
		case 98: {
			return ((uint8_t*) set_subscript_1);
		}
		case 99: {
			return ((uint8_t*) get_fun_name_99);
		}
		case 100: {
			return ((uint8_t*) sort_together);
		}
		case 101: {
			return ((uint8_t*) swap_0);
		}
		case 102: {
			return ((uint8_t*) subscript_1);
		}
		case 103: {
			return ((uint8_t*) swap_1);
		}
		case 104: {
			return ((uint8_t*) subscript_2);
		}
		case 105: {
			return ((uint8_t*) partition_recur_together);
		}
		case 106: {
			return ((uint8_t*) fill_code_names_recur);
		}
		case 107: {
			return ((uint8_t*) get_fun_name);
		}
		case 108: {
			return ((uint8_t*) begin_ptr_0);
		}
		case 109: {
			return ((uint8_t*) begin_ptr_1);
		}
		case 110: {
			return ((uint8_t*) uninitialized_mut_arr);
		}
		case 111: {
			return ((uint8_t*) mut_arr_2);
		}
		case 112: {
			return ((uint8_t*) alloc_uninitialized_0);
		}
		case 113: {
			return ((uint8_t*) alloc);
		}
		case 114: {
			return ((uint8_t*) gc_alloc);
		}
		case 115: {
			return ((uint8_t*) todo_1);
		}
		case 116: {
			return ((uint8_t*) copy_data_from);
		}
		case 117: {
			return ((uint8_t*) memcpy);
		}
		case 118: {
			return ((uint8_t*) set_zero_elements);
		}
		case 119: {
			return ((uint8_t*) set_zero_range_1);
		}
		case 120: {
			return ((uint8_t*) subscript_3);
		}
		case 121: {
			return ((uint8_t*) subscript_4);
		}
		case 122: {
			return ((uint8_t*) _arrow);
		}
		case 123: {
			return ((uint8_t*) _plus);
		}
		case 124: {
			return ((uint8_t*) _greaterOrEqual);
		}
		case 125: {
			return ((uint8_t*) round_up_to_power_of_two);
		}
		case 126: {
			return ((uint8_t*) round_up_to_power_of_two_recur);
		}
		case 127: {
			return ((uint8_t*) _times);
		}
		case 128: {
			return ((uint8_t*) _divide);
		}
		case 129: {
			return ((uint8_t*) forbid);
		}
		case 130: {
			return ((uint8_t*) set_subscript_2);
		}
		case 131: {
			return ((uint8_t*) _concatEquals_1__lambda0);
		}
		case 132: {
			return ((uint8_t*) empty__q_0);
		}
		case 133: {
			return ((uint8_t*) empty__q_1);
		}
		case 134: {
			return ((uint8_t*) each_1);
		}
		case 135: {
			return ((uint8_t*) each_recur_1);
		}
		case 136: {
			return ((uint8_t*) subscript_5);
		}
		case 137: {
			return ((uint8_t*) call_w_ctx_137);
		}
		case 138: {
			return ((uint8_t*) end_ptr_1);
		}
		case 139: {
			return ((uint8_t*) to_str_0__lambda0);
		}
		case 140: {
			return ((uint8_t*) move_to_str__e);
		}
		case 141: {
			return ((uint8_t*) move_to_arr__e);
		}
		case 142: {
			return ((uint8_t*) get_global_ctx);
		}
		case 143: {
			return ((uint8_t*) island__lambda0);
		}
		case 144: {
			return ((uint8_t*) default_log_handler);
		}
		case 145: {
			return ((uint8_t*) print);
		}
		case 146: {
			return ((uint8_t*) print_no_newline);
		}
		case 147: {
			return ((uint8_t*) stdout);
		}
		case 148: {
			return ((uint8_t*) _concat_0);
		}
		case 149: {
			return ((uint8_t*) _concat_1);
		}
		case 150: {
			return ((uint8_t*) to_str_1);
		}
		case 151: {
			return ((uint8_t*) island__lambda1);
		}
		case 152: {
			return ((uint8_t*) gc);
		}
		case 153: {
			return ((uint8_t*) validate_gc);
		}
		case 154: {
			return ((uint8_t*) ptr_less_eq__q_0);
		}
		case 155: {
			return ((uint8_t*) ptr_less_eq__q_1);
		}
		case 156: {
			return ((uint8_t*) _minus_1);
		}
		case 157: {
			return ((uint8_t*) thread_safe_counter_0);
		}
		case 158: {
			return ((uint8_t*) thread_safe_counter_1);
		}
		case 159: {
			return ((uint8_t*) add_main_task);
		}
		case 160: {
			return ((uint8_t*) exception_ctx);
		}
		case 161: {
			return ((uint8_t*) log_ctx);
		}
		case 162: {
			return ((uint8_t*) perf_ctx);
		}
		case 163: {
			return ((uint8_t*) mut_arr_3);
		}
		case 164: {
			return ((uint8_t*) ctx);
		}
		case 165: {
			return ((uint8_t*) get_gc_ctx_1);
		}
		case 166: {
			return ((uint8_t*) add_first_task);
		}
		case 167: {
			return ((uint8_t*) then_void);
		}
		case 168: {
			return ((uint8_t*) then);
		}
		case 169: {
			return ((uint8_t*) unresolved);
		}
		case 170: {
			return ((uint8_t*) callback__e_0);
		}
		case 171: {
			return ((uint8_t*) with_lock_0);
		}
		case 172: {
			return ((uint8_t*) subscript_6);
		}
		case 173: {
			return ((uint8_t*) call_w_ctx_173);
		}
		case 174: {
			return ((uint8_t*) subscript_7);
		}
		case 175: {
			return ((uint8_t*) call_w_ctx_175);
		}
		case 176: {
			return ((uint8_t*) callback__e_0__lambda0);
		}
		case 177: {
			return ((uint8_t*) forward_to__e);
		}
		case 178: {
			return ((uint8_t*) callback__e_1);
		}
		case 179: {
			return ((uint8_t*) subscript_8);
		}
		case 180: {
			return ((uint8_t*) call_w_ctx_180);
		}
		case 181: {
			return ((uint8_t*) callback__e_1__lambda0);
		}
		case 182: {
			return ((uint8_t*) resolve_or_reject__e);
		}
		case 183: {
			return ((uint8_t*) with_lock_1);
		}
		case 184: {
			return ((uint8_t*) subscript_9);
		}
		case 185: {
			return ((uint8_t*) call_w_ctx_185);
		}
		case 186: {
			return ((uint8_t*) resolve_or_reject__e__lambda0);
		}
		case 187: {
			return ((uint8_t*) call_callbacks__e);
		}
		case 188: {
			return ((uint8_t*) forward_to__e__lambda0);
		}
		case 189: {
			return ((uint8_t*) subscript_10);
		}
		case 190: {
			return ((uint8_t*) get_island);
		}
		case 191: {
			return ((uint8_t*) subscript_11);
		}
		case 192: {
			return ((uint8_t*) unsafe_at_0);
		}
		case 193: {
			return ((uint8_t*) subscript_12);
		}
		case 194: {
			return ((uint8_t*) add_task_0);
		}
		case 195: {
			return ((uint8_t*) add_task_1);
		}
		case 196: {
			return ((uint8_t*) task_queue_node);
		}
		case 197: {
			return ((uint8_t*) insert_task__e);
		}
		case 198: {
			return ((uint8_t*) size_1);
		}
		case 199: {
			return ((uint8_t*) size_recur);
		}
		case 200: {
			return ((uint8_t*) insert_recur);
		}
		case 201: {
			return ((uint8_t*) tasks);
		}
		case 202: {
			return ((uint8_t*) broadcast__e);
		}
		case 203: {
			return ((uint8_t*) pthread_mutex_lock);
		}
		case 204: {
			return ((uint8_t*) pthread_cond_broadcast);
		}
		case 205: {
			return ((uint8_t*) pthread_mutex_unlock);
		}
		case 206: {
			return ((uint8_t*) no_timestamp);
		}
		case 207: {
			return ((uint8_t*) catch);
		}
		case 208: {
			return ((uint8_t*) catch_with_exception_ctx);
		}
		case 209: {
			return ((uint8_t*) zero_0);
		}
		case 210: {
			return ((uint8_t*) zero_1);
		}
		case 211: {
			return ((uint8_t*) zero_2);
		}
		case 212: {
			return ((uint8_t*) zero_3);
		}
		case 213: {
			return ((uint8_t*) setjmp);
		}
		case 214: {
			return ((uint8_t*) subscript_13);
		}
		case 215: {
			return ((uint8_t*) call_w_ctx_215);
		}
		case 216: {
			return ((uint8_t*) subscript_14);
		}
		case 217: {
			return ((uint8_t*) call_w_ctx_217);
		}
		case 218: {
			return ((uint8_t*) subscript_10__lambda0__lambda0);
		}
		case 219: {
			return ((uint8_t*) reject__e);
		}
		case 220: {
			return ((uint8_t*) subscript_10__lambda0__lambda1);
		}
		case 221: {
			return ((uint8_t*) subscript_10__lambda0);
		}
		case 222: {
			return ((uint8_t*) then__lambda0);
		}
		case 223: {
			return ((uint8_t*) subscript_15);
		}
		case 224: {
			return ((uint8_t*) subscript_16);
		}
		case 225: {
			return ((uint8_t*) call_w_ctx_225);
		}
		case 226: {
			return ((uint8_t*) subscript_15__lambda0__lambda0);
		}
		case 227: {
			return ((uint8_t*) subscript_15__lambda0__lambda1);
		}
		case 228: {
			return ((uint8_t*) subscript_15__lambda0);
		}
		case 229: {
			return ((uint8_t*) then_void__lambda0);
		}
		case 230: {
			return ((uint8_t*) cur_island_and_exclusion);
		}
		case 231: {
			return ((uint8_t*) delay);
		}
		case 232: {
			return ((uint8_t*) resolved_0);
		}
		case 233: {
			return ((uint8_t*) tail);
		}
		case 234: {
			return ((uint8_t*) empty__q_2);
		}
		case 235: {
			return ((uint8_t*) subscript_17);
		}
		case 236: {
			return ((uint8_t*) map);
		}
		case 237: {
			return ((uint8_t*) make_arr);
		}
		case 238: {
			return ((uint8_t*) alloc_uninitialized_1);
		}
		case 239: {
			return ((uint8_t*) fill_ptr_range);
		}
		case 240: {
			return ((uint8_t*) fill_ptr_range_recur);
		}
		case 241: {
			return ((uint8_t*) subscript_18);
		}
		case 242: {
			return ((uint8_t*) call_w_ctx_242);
		}
		case 243: {
			return ((uint8_t*) subscript_19);
		}
		case 244: {
			return ((uint8_t*) call_w_ctx_244);
		}
		case 245: {
			return ((uint8_t*) subscript_20);
		}
		case 246: {
			return ((uint8_t*) unsafe_at_1);
		}
		case 247: {
			return ((uint8_t*) subscript_21);
		}
		case 248: {
			return ((uint8_t*) map__lambda0);
		}
		case 249: {
			return ((uint8_t*) to_str_2);
		}
		case 250: {
			return ((uint8_t*) arr_from_begin_end);
		}
		case 251: {
			return ((uint8_t*) ptr_less_eq__q_2);
		}
		case 252: {
			return ((uint8_t*) _minus_2);
		}
		case 253: {
			return ((uint8_t*) find_cstr_end);
		}
		case 254: {
			return ((uint8_t*) find_char_in_cstr);
		}
		case 255: {
			return ((uint8_t*) _equal);
		}
		case 256: {
			return ((uint8_t*) hard_unreachable_1);
		}
		case 257: {
			return ((uint8_t*) add_first_task__lambda0__lambda0);
		}
		case 258: {
			return ((uint8_t*) add_first_task__lambda0);
		}
		case 259: {
			return ((uint8_t*) handle_exceptions);
		}
		case 260: {
			return ((uint8_t*) subscript_22);
		}
		case 261: {
			return ((uint8_t*) call_w_ctx_261);
		}
		case 262: {
			return ((uint8_t*) exception_handler);
		}
		case 263: {
			return ((uint8_t*) get_cur_island);
		}
		case 264: {
			return ((uint8_t*) handle_exceptions__lambda0);
		}
		case 265: {
			return ((uint8_t*) add_main_task__lambda0);
		}
		case 266: {
			return ((uint8_t*) call_w_ctx_266);
		}
		case 267: {
			return ((uint8_t*) run_threads);
		}
		case 268: {
			return ((uint8_t*) unmanaged_alloc_elements_1);
		}
		case 269: {
			return ((uint8_t*) start_threads_recur);
		}
		case 270: {
			return ((uint8_t*) create_one_thread);
		}
		case 271: {
			return ((uint8_t*) pthread_create);
		}
		case 272: {
			return ((uint8_t*) _notEqual_2);
		}
		case 273: {
			return ((uint8_t*) eagain);
		}
		case 274: {
			return ((uint8_t*) as_cell);
		}
		case 275: {
			return ((uint8_t*) thread_fun);
		}
		case 276: {
			return ((uint8_t*) thread_function);
		}
		case 277: {
			return ((uint8_t*) thread_function_recur);
		}
		case 278: {
			return ((uint8_t*) assert_islands_are_shut_down);
		}
		case 279: {
			return ((uint8_t*) noctx_at_0);
		}
		case 280: {
			return ((uint8_t*) empty__q_3);
		}
		case 281: {
			return ((uint8_t*) empty__q_4);
		}
		case 282: {
			return ((uint8_t*) get_sequence);
		}
		case 283: {
			return ((uint8_t*) choose_task);
		}
		case 284: {
			return ((uint8_t*) get_monotime_nsec);
		}
		case 285: {
			return ((uint8_t*) clock_gettime);
		}
		case 286: {
			return ((uint8_t*) todo_2);
		}
		case 287: {
			return ((uint8_t*) choose_task_recur);
		}
		case 288: {
			return ((uint8_t*) choose_task_in_island);
		}
		case 289: {
			return ((uint8_t*) pop_task__e);
		}
		case 290: {
			return ((uint8_t*) contains__q_0);
		}
		case 291: {
			return ((uint8_t*) contains__q_1);
		}
		case 292: {
			return ((uint8_t*) contains_recur__q);
		}
		case 293: {
			return ((uint8_t*) noctx_at_1);
		}
		case 294: {
			return ((uint8_t*) unsafe_at_2);
		}
		case 295: {
			return ((uint8_t*) subscript_23);
		}
		case 296: {
			return ((uint8_t*) temp_as_arr_0);
		}
		case 297: {
			return ((uint8_t*) temp_as_arr_1);
		}
		case 298: {
			return ((uint8_t*) temp_as_mut_arr);
		}
		case 299: {
			return ((uint8_t*) begin_ptr_2);
		}
		case 300: {
			return ((uint8_t*) begin_ptr_3);
		}
		case 301: {
			return ((uint8_t*) pop_recur__e);
		}
		case 302: {
			return ((uint8_t*) to_opt_time);
		}
		case 303: {
			return ((uint8_t*) push_capacity_must_be_sufficient__e);
		}
		case 304: {
			return ((uint8_t*) capacity_1);
		}
		case 305: {
			return ((uint8_t*) size_2);
		}
		case 306: {
			return ((uint8_t*) set_subscript_3);
		}
		case 307: {
			return ((uint8_t*) is_no_task__q);
		}
		case 308: {
			return ((uint8_t*) min_time);
		}
		case 309: {
			return ((uint8_t*) min);
		}
		case 310: {
			return ((uint8_t*) do_task);
		}
		case 311: {
			return ((uint8_t*) return_task__e);
		}
		case 312: {
			return ((uint8_t*) noctx_must_remove_unordered__e);
		}
		case 313: {
			return ((uint8_t*) noctx_must_remove_unordered_recur__e);
		}
		case 314: {
			return ((uint8_t*) drop);
		}
		case 315: {
			return ((uint8_t*) noctx_remove_unordered_at__e);
		}
		case 316: {
			return ((uint8_t*) return_ctx);
		}
		case 317: {
			return ((uint8_t*) return_gc_ctx);
		}
		case 318: {
			return ((uint8_t*) run_garbage_collection);
		}
		case 319: {
			return ((uint8_t*) mark_visit_319);
		}
		case 320: {
			return ((uint8_t*) mark_visit_320);
		}
		case 321: {
			return ((uint8_t*) mark_visit_321);
		}
		case 322: {
			return ((uint8_t*) mark_visit_322);
		}
		case 323: {
			return ((uint8_t*) mark_visit_323);
		}
		case 324: {
			return ((uint8_t*) mark_visit_324);
		}
		case 325: {
			return ((uint8_t*) mark_visit_325);
		}
		case 326: {
			return ((uint8_t*) mark_visit_326);
		}
		case 327: {
			return ((uint8_t*) mark_visit_327);
		}
		case 328: {
			return ((uint8_t*) mark_visit_328);
		}
		case 329: {
			return ((uint8_t*) mark_visit_329);
		}
		case 330: {
			return ((uint8_t*) mark_visit_330);
		}
		case 331: {
			return ((uint8_t*) mark_visit_331);
		}
		case 332: {
			return ((uint8_t*) mark_visit_332);
		}
		case 333: {
			return ((uint8_t*) mark_visit_333);
		}
		case 334: {
			return ((uint8_t*) mark_visit_334);
		}
		case 335: {
			return ((uint8_t*) mark_visit_335);
		}
		case 336: {
			return ((uint8_t*) mark_visit_336);
		}
		case 337: {
			return ((uint8_t*) mark_visit_337);
		}
		case 338: {
			return ((uint8_t*) mark_arr_338);
		}
		case 339: {
			return ((uint8_t*) mark_visit_339);
		}
		case 340: {
			return ((uint8_t*) mark_visit_340);
		}
		case 341: {
			return ((uint8_t*) mark_visit_341);
		}
		case 342: {
			return ((uint8_t*) mark_visit_342);
		}
		case 343: {
			return ((uint8_t*) mark_visit_343);
		}
		case 344: {
			return ((uint8_t*) mark_visit_344);
		}
		case 345: {
			return ((uint8_t*) mark_visit_345);
		}
		case 346: {
			return ((uint8_t*) mark_visit_346);
		}
		case 347: {
			return ((uint8_t*) mark_visit_347);
		}
		case 348: {
			return ((uint8_t*) mark_visit_348);
		}
		case 349: {
			return ((uint8_t*) mark_visit_349);
		}
		case 350: {
			return ((uint8_t*) mark_visit_350);
		}
		case 351: {
			return ((uint8_t*) mark_visit_351);
		}
		case 352: {
			return ((uint8_t*) mark_visit_352);
		}
		case 353: {
			return ((uint8_t*) mark_arr_353);
		}
		case 354: {
			return ((uint8_t*) mark_visit_354);
		}
		case 355: {
			return ((uint8_t*) mark_elems_355);
		}
		case 356: {
			return ((uint8_t*) mark_arr_356);
		}
		case 357: {
			return ((uint8_t*) mark_visit_357);
		}
		case 358: {
			return ((uint8_t*) mark_visit_358);
		}
		case 359: {
			return ((uint8_t*) mark_visit_359);
		}
		case 360: {
			return ((uint8_t*) mark_visit_360);
		}
		case 361: {
			return ((uint8_t*) mark_visit_361);
		}
		case 362: {
			return ((uint8_t*) mark_visit_362);
		}
		case 363: {
			return ((uint8_t*) mark_visit_363);
		}
		case 364: {
			return ((uint8_t*) mark_visit_364);
		}
		case 365: {
			return ((uint8_t*) mark_visit_365);
		}
		case 366: {
			return ((uint8_t*) mark_visit_366);
		}
		case 367: {
			return ((uint8_t*) mark_visit_367);
		}
		case 368: {
			return ((uint8_t*) mark_visit_368);
		}
		case 369: {
			return ((uint8_t*) mark_visit_369);
		}
		case 370: {
			return ((uint8_t*) mark_visit_370);
		}
		case 371: {
			return ((uint8_t*) mark_visit_371);
		}
		case 372: {
			return ((uint8_t*) mark_visit_372);
		}
		case 373: {
			return ((uint8_t*) mark_visit_373);
		}
		case 374: {
			return ((uint8_t*) mark_visit_374);
		}
		case 375: {
			return ((uint8_t*) mark_visit_375);
		}
		case 376: {
			return ((uint8_t*) mark_arr_376);
		}
		case 377: {
			return ((uint8_t*) clear_free_mem);
		}
		case 378: {
			return ((uint8_t*) wait_on);
		}
		case 379: {
			return ((uint8_t*) pthread_cond_wait);
		}
		case 380: {
			return ((uint8_t*) to_timespec);
		}
		case 381: {
			return ((uint8_t*) pthread_cond_timedwait);
		}
		case 382: {
			return ((uint8_t*) etimedout);
		}
		case 383: {
			return ((uint8_t*) join_threads_recur);
		}
		case 384: {
			return ((uint8_t*) join_one_thread);
		}
		case 385: {
			return ((uint8_t*) pthread_join);
		}
		case 386: {
			return ((uint8_t*) einval);
		}
		case 387: {
			return ((uint8_t*) esrch);
		}
		case 388: {
			return ((uint8_t*) unmanaged_free_0);
		}
		case 389: {
			return ((uint8_t*) free);
		}
		case 390: {
			return ((uint8_t*) unmanaged_free_1);
		}
		case 391: {
			return ((uint8_t*) destroy_condition);
		}
		case 392: {
			return ((uint8_t*) pthread_mutexattr_destroy);
		}
		case 393: {
			return ((uint8_t*) pthread_mutex_destroy);
		}
		case 394: {
			return ((uint8_t*) pthread_condattr_destroy);
		}
		case 395: {
			return ((uint8_t*) pthread_cond_destroy);
		}
		case 396: {
			return ((uint8_t*) main_0);
		}
		case 397: {
			return ((uint8_t*) resolved_1);
		}
		default:
			return NULL;
	}
}
/* set-subscript<str> void(a ptr<str>, n nat, value str) */
struct void_ set_subscript_1(struct str* a, uint64_t n, struct str value) {
	return (*(a + n) = value, (struct void_) {});
}
/* get-fun-name (generated) (generated) */
struct str get_fun_name_99(uint64_t fun_id) {switch (fun_id) {
		case 0: {
			return (struct str) {{4, constantarr_0_12}};
		}
		case 1: {
			return (struct str) {{11, constantarr_0_13}};
		}
		case 2: {
			return (struct str) {{6, constantarr_0_15}};
		}
		case 3: {
			return (struct str) {{13, constantarr_0_16}};
		}
		case 4: {
			return (struct str) {{14, constantarr_0_20}};
		}
		case 5: {
			return (struct str) {{25, constantarr_0_22}};
		}
		case 6: {
			return (struct str) {{6, constantarr_0_26}};
		}
		case 7: {
			return (struct str) {{3, constantarr_0_31}};
		}
		case 8: {
			return (struct str) {{6, constantarr_0_37}};
		}
		case 9: {
			return (struct str) {{7, constantarr_0_41}};
		}
		case 10: {
			return (struct str) {{3, constantarr_0_42}};
		}
		case 11: {
			return (struct str) {{16, constantarr_0_45}};
		}
		case 12: {
			return (struct str) {{6, constantarr_0_50}};
		}
		case 13: {
			return (struct str) {{7, constantarr_0_51}};
		}
		case 14: {
			return (struct str) {{10, constantarr_0_52}};
		}
		case 15: {
			return (struct str) {{11, constantarr_0_55}};
		}
		case 16: {
			return (struct str) {{11, constantarr_0_57}};
		}
		case 17: {
			return (struct str) {{16, constantarr_0_58}};
		}
		case 18: {
			return (struct str) {{23, constantarr_0_65}};
		}
		case 19: {
			return (struct str) {{22, constantarr_0_66}};
		}
		case 20: {
			return (struct str) {{18, constantarr_0_70}};
		}
		case 21: {
			return (struct str) {{21, constantarr_0_73}};
		}
		case 22: {
			return (struct str) {{25, constantarr_0_76}};
		}
		case 23: {
			return (struct str) {{15, constantarr_0_77}};
		}
		case 24: {
			return (struct str) {{17, constantarr_0_78}};
		}
		case 25: {
			return (struct str) {{6, constantarr_0_82}};
		}
		case 26: {
			return (struct str) {{10, constantarr_0_83}};
		}
		case 27: {
			return (struct str) {{56, constantarr_0_85}};
		}
		case 28: {
			return (struct str) {{11, constantarr_0_86}};
		}
		case 29: {
			return (struct str) {{35, constantarr_0_88}};
		}
		case 30: {
			return (struct str) {{28, constantarr_0_89}};
		}
		case 31: {
			return (struct str) {{21, constantarr_0_90}};
		}
		case 32: {
			return (struct str) {{6, constantarr_0_91}};
		}
		case 33: {
			return (struct str) {{11, constantarr_0_92}};
		}
		case 34: {
			return (struct str) {{11, constantarr_0_93}};
		}
		case 35: {
			return (struct str) {{18, constantarr_0_97}};
		}
		case 36: {
			return (struct str) {{6, constantarr_0_98}};
		}
		case 37: {
			return (struct str) {{25, constantarr_0_103}};
		}
		case 38: {
			return (struct str) {{20, constantarr_0_104}};
		}
		case 39: {
			return (struct str) {{16, constantarr_0_105}};
		}
		case 40: {
			return (struct str) {{5, constantarr_0_108}};
		}
		case 41: {
			return (struct str) {{10, constantarr_0_112}};
		}
		case 42: {
			return (struct str) {{7, constantarr_0_114}};
		}
		case 43: {
			return (struct str) {{10, constantarr_0_116}};
		}
		case 44: {
			return (struct str) {{6, constantarr_0_118}};
		}
		case 45: {
			return (struct str) {{9, constantarr_0_119}};
		}
		case 46: {
			return (struct str) {{6, constantarr_0_120}};
		}
		case 47: {
			return (struct str) {{6, constantarr_0_121}};
		}
		case 48: {
			return (struct str) {{14, constantarr_0_122}};
		}
		case 49: {
			return (struct str) {{11, constantarr_0_86}};
		}
		case 50: {
			return (struct str) {{2, constantarr_0_123}};
		}
		case 51: {
			return (struct str) {{8, constantarr_0_124}};
		}
		case 52: {
			return (struct str) {{8, constantarr_0_125}};
		}
		case 53: {
			return (struct str) {{14, constantarr_0_126}};
		}
		case 54: {
			return (struct str) {{19, constantarr_0_127}};
		}
		case 55: {
			return (struct str) {{0u, NULL}};
		}
		case 56: {
			return (struct str) {{11, constantarr_0_132}};
		}
		case 57: {
			return (struct str) {{6, constantarr_0_133}};
		}
		case 58: {
			return (struct str) {{18, constantarr_0_134}};
		}
		case 59: {
			return (struct str) {{19, constantarr_0_135}};
		}
		case 60: {
			return (struct str) {{12, constantarr_0_136}};
		}
		case 61: {
			return (struct str) {{8, constantarr_0_137}};
		}
		case 62: {
			return (struct str) {{25, constantarr_0_140}};
		}
		case 63: {
			return (struct str) {{6, constantarr_0_141}};
		}
		case 64: {
			return (struct str) {{11, constantarr_0_142}};
		}
		case 65: {
			return (struct str) {{9, constantarr_0_143}};
		}
		case 66: {
			return (struct str) {{17, constantarr_0_144}};
		}
		case 67: {
			return (struct str) {{18, constantarr_0_148}};
		}
		case 68: {
			return (struct str) {{7, constantarr_0_151}};
		}
		case 69: {
			return (struct str) {{15, constantarr_0_152}};
		}
		case 70: {
			return (struct str) {{20, constantarr_0_153}};
		}
		case 71: {
			return (struct str) {{13, constantarr_0_155}};
		}
		case 72: {
			return (struct str) {{24, constantarr_0_156}};
		}
		case 73: {
			return (struct str) {{34, constantarr_0_157}};
		}
		case 74: {
			return (struct str) {{9, constantarr_0_158}};
		}
		case 75: {
			return (struct str) {{12, constantarr_0_159}};
		}
		case 76: {
			return (struct str) {{8, constantarr_0_160}};
		}
		case 77: {
			return (struct str) {{14, constantarr_0_161}};
		}
		case 78: {
			return (struct str) {{12, constantarr_0_162}};
		}
		case 79: {
			return (struct str) {{8, constantarr_0_163}};
		}
		case 80: {
			return (struct str) {{11, constantarr_0_164}};
		}
		case 81: {
			return (struct str) {{12, constantarr_0_170}};
		}
		case 82: {
			return (struct str) {{13, constantarr_0_171}};
		}
		case 83: {
			return (struct str) {{18, constantarr_0_174}};
		}
		case 84: {
			return (struct str) {{11, constantarr_0_179}};
		}
		case 85: {
			return (struct str) {{8, constantarr_0_185}};
		}
		case 86: {
			return (struct str) {{11, constantarr_0_186}};
		}
		case 87: {
			return (struct str) {{10, constantarr_0_187}};
		}
		case 88: {
			return (struct str) {{6, constantarr_0_188}};
		}
		case 89: {
			return (struct str) {{10, constantarr_0_190}};
		}
		case 90: {
			return (struct str) {{28, constantarr_0_195}};
		}
		case 91: {
			return (struct str) {{0u, NULL}};
		}
		case 92: {
			return (struct str) {{9, constantarr_0_199}};
		}
		case 93: {
			return (struct str) {{14, constantarr_0_205}};
		}
		case 94: {
			return (struct str) {{25, constantarr_0_206}};
		}
		case 95: {
			return (struct str) {{7, constantarr_0_207}};
		}
		case 96: {
			return (struct str) {{24, constantarr_0_208}};
		}
		case 97: {
			return (struct str) {{0u, NULL}};
		}
		case 98: {
			return (struct str) {{18, constantarr_0_211}};
		}
		case 99: {
			return (struct str) {{0u, NULL}};
		}
		case 100: {
			return (struct str) {{13, constantarr_0_215}};
		}
		case 101: {
			return (struct str) {{15, constantarr_0_216}};
		}
		case 102: {
			return (struct str) {{13, constantarr_0_130}};
		}
		case 103: {
			return (struct str) {{9, constantarr_0_217}};
		}
		case 104: {
			return (struct str) {{13, constantarr_0_130}};
		}
		case 105: {
			return (struct str) {{24, constantarr_0_218}};
		}
		case 106: {
			return (struct str) {{21, constantarr_0_221}};
		}
		case 107: {
			return (struct str) {{12, constantarr_0_212}};
		}
		case 108: {
			return (struct str) {{13, constantarr_0_224}};
		}
		case 109: {
			return (struct str) {{13, constantarr_0_224}};
		}
		case 110: {
			return (struct str) {{25, constantarr_0_226}};
		}
		case 111: {
			return (struct str) {{11, constantarr_0_86}};
		}
		case 112: {
			return (struct str) {{23, constantarr_0_227}};
		}
		case 113: {
			return (struct str) {{5, constantarr_0_228}};
		}
		case 114: {
			return (struct str) {{8, constantarr_0_229}};
		}
		case 115: {
			return (struct str) {{15, constantarr_0_230}};
		}
		case 116: {
			return (struct str) {{18, constantarr_0_231}};
		}
		case 117: {
			return (struct str) {{6, constantarr_0_232}};
		}
		case 118: {
			return (struct str) {{21, constantarr_0_233}};
		}
		case 119: {
			return (struct str) {{18, constantarr_0_97}};
		}
		case 120: {
			return (struct str) {{13, constantarr_0_130}};
		}
		case 121: {
			return (struct str) {{13, constantarr_0_130}};
		}
		case 122: {
			return (struct str) {{12, constantarr_0_236}};
		}
		case 123: {
			return (struct str) {{1, constantarr_0_238}};
		}
		case 124: {
			return (struct str) {{7, constantarr_0_240}};
		}
		case 125: {
			return (struct str) {{24, constantarr_0_241}};
		}
		case 126: {
			return (struct str) {{30, constantarr_0_242}};
		}
		case 127: {
			return (struct str) {{1, constantarr_0_243}};
		}
		case 128: {
			return (struct str) {{1, constantarr_0_244}};
		}
		case 129: {
			return (struct str) {{6, constantarr_0_245}};
		}
		case 130: {
			return (struct str) {{17, constantarr_0_209}};
		}
		case 131: {
			return (struct str) {{16, constantarr_0_247}};
		}
		case 132: {
			return (struct str) {{6, constantarr_0_249}};
		}
		case 133: {
			return (struct str) {{12, constantarr_0_250}};
		}
		case 134: {
			return (struct str) {{9, constantarr_0_252}};
		}
		case 135: {
			return (struct str) {{14, constantarr_0_126}};
		}
		case 136: {
			return (struct str) {{19, constantarr_0_127}};
		}
		case 137: {
			return (struct str) {{0u, NULL}};
		}
		case 138: {
			return (struct str) {{11, constantarr_0_132}};
		}
		case 139: {
			return (struct str) {{14, constantarr_0_254}};
		}
		case 140: {
			return (struct str) {{12, constantarr_0_255}};
		}
		case 141: {
			return (struct str) {{18, constantarr_0_257}};
		}
		case 142: {
			return (struct str) {{14, constantarr_0_259}};
		}
		case 143: {
			return (struct str) {{14, constantarr_0_262}};
		}
		case 144: {
			return (struct str) {{19, constantarr_0_263}};
		}
		case 145: {
			return (struct str) {{5, constantarr_0_264}};
		}
		case 146: {
			return (struct str) {{16, constantarr_0_265}};
		}
		case 147: {
			return (struct str) {{6, constantarr_0_266}};
		}
		case 148: {
			return (struct str) {{1, constantarr_0_267}};
		}
		case 149: {
			return (struct str) {{7, constantarr_0_268}};
		}
		case 150: {
			return (struct str) {{6, constantarr_0_120}};
		}
		case 151: {
			return (struct str) {{14, constantarr_0_270}};
		}
		case 152: {
			return (struct str) {{2, constantarr_0_189}};
		}
		case 153: {
			return (struct str) {{11, constantarr_0_274}};
		}
		case 154: {
			return (struct str) {{18, constantarr_0_277}};
		}
		case 155: {
			return (struct str) {{17, constantarr_0_280}};
		}
		case 156: {
			return (struct str) {{7, constantarr_0_281}};
		}
		case 157: {
			return (struct str) {{19, constantarr_0_284}};
		}
		case 158: {
			return (struct str) {{19, constantarr_0_284}};
		}
		case 159: {
			return (struct str) {{13, constantarr_0_289}};
		}
		case 160: {
			return (struct str) {{13, constantarr_0_290}};
		}
		case 161: {
			return (struct str) {{7, constantarr_0_291}};
		}
		case 162: {
			return (struct str) {{8, constantarr_0_293}};
		}
		case 163: {
			return (struct str) {{22, constantarr_0_294}};
		}
		case 164: {
			return (struct str) {{3, constantarr_0_303}};
		}
		case 165: {
			return (struct str) {{10, constantarr_0_190}};
		}
		case 166: {
			return (struct str) {{14, constantarr_0_322}};
		}
		case 167: {
			return (struct str) {{14, constantarr_0_323}};
		}
		case 168: {
			return (struct str) {{16, constantarr_0_324}};
		}
		case 169: {
			return (struct str) {{16, constantarr_0_325}};
		}
		case 170: {
			return (struct str) {{14, constantarr_0_328}};
		}
		case 171: {
			return (struct str) {{15, constantarr_0_329}};
		}
		case 172: {
			return (struct str) {{13, constantarr_0_130}};
		}
		case 173: {
			return (struct str) {{0u, NULL}};
		}
		case 174: {
			return (struct str) {{38, constantarr_0_336}};
		}
		case 175: {
			return (struct str) {{0u, NULL}};
		}
		case 176: {
			return (struct str) {{22, constantarr_0_340}};
		}
		case 177: {
			return (struct str) {{17, constantarr_0_341}};
		}
		case 178: {
			return (struct str) {{13, constantarr_0_342}};
		}
		case 179: {
			return (struct str) {{38, constantarr_0_336}};
		}
		case 180: {
			return (struct str) {{0u, NULL}};
		}
		case 181: {
			return (struct str) {{21, constantarr_0_343}};
		}
		case 182: {
			return (struct str) {{22, constantarr_0_344}};
		}
		case 183: {
			return (struct str) {{24, constantarr_0_345}};
		}
		case 184: {
			return (struct str) {{13, constantarr_0_130}};
		}
		case 185: {
			return (struct str) {{0u, NULL}};
		}
		case 186: {
			return (struct str) {{30, constantarr_0_348}};
		}
		case 187: {
			return (struct str) {{19, constantarr_0_349}};
		}
		case 188: {
			return (struct str) {{25, constantarr_0_352}};
		}
		case 189: {
			return (struct str) {{20, constantarr_0_353}};
		}
		case 190: {
			return (struct str) {{10, constantarr_0_354}};
		}
		case 191: {
			return (struct str) {{17, constantarr_0_355}};
		}
		case 192: {
			return (struct str) {{13, constantarr_0_356}};
		}
		case 193: {
			return (struct str) {{13, constantarr_0_130}};
		}
		case 194: {
			return (struct str) {{8, constantarr_0_359}};
		}
		case 195: {
			return (struct str) {{8, constantarr_0_359}};
		}
		case 196: {
			return (struct str) {{15, constantarr_0_360}};
		}
		case 197: {
			return (struct str) {{12, constantarr_0_363}};
		}
		case 198: {
			return (struct str) {{4, constantarr_0_364}};
		}
		case 199: {
			return (struct str) {{10, constantarr_0_365}};
		}
		case 200: {
			return (struct str) {{12, constantarr_0_371}};
		}
		case 201: {
			return (struct str) {{5, constantarr_0_373}};
		}
		case 202: {
			return (struct str) {{10, constantarr_0_375}};
		}
		case 203: {
			return (struct str) {{18, constantarr_0_376}};
		}
		case 204: {
			return (struct str) {{22, constantarr_0_377}};
		}
		case 205: {
			return (struct str) {{20, constantarr_0_380}};
		}
		case 206: {
			return (struct str) {{12, constantarr_0_383}};
		}
		case 207: {
			return (struct str) {{11, constantarr_0_385}};
		}
		case 208: {
			return (struct str) {{28, constantarr_0_386}};
		}
		case 209: {
			return (struct str) {{4, constantarr_0_389}};
		}
		case 210: {
			return (struct str) {{4, constantarr_0_389}};
		}
		case 211: {
			return (struct str) {{4, constantarr_0_389}};
		}
		case 212: {
			return (struct str) {{4, constantarr_0_389}};
		}
		case 213: {
			return (struct str) {{6, constantarr_0_396}};
		}
		case 214: {
			return (struct str) {{24, constantarr_0_397}};
		}
		case 215: {
			return (struct str) {{0u, NULL}};
		}
		case 216: {
			return (struct str) {{23, constantarr_0_398}};
		}
		case 217: {
			return (struct str) {{0u, NULL}};
		}
		case 218: {
			return (struct str) {{36, constantarr_0_400}};
		}
		case 219: {
			return (struct str) {{11, constantarr_0_401}};
		}
		case 220: {
			return (struct str) {{36, constantarr_0_402}};
		}
		case 221: {
			return (struct str) {{28, constantarr_0_403}};
		}
		case 222: {
			return (struct str) {{24, constantarr_0_405}};
		}
		case 223: {
			return (struct str) {{15, constantarr_0_406}};
		}
		case 224: {
			return (struct str) {{18, constantarr_0_408}};
		}
		case 225: {
			return (struct str) {{0u, NULL}};
		}
		case 226: {
			return (struct str) {{31, constantarr_0_410}};
		}
		case 227: {
			return (struct str) {{31, constantarr_0_411}};
		}
		case 228: {
			return (struct str) {{23, constantarr_0_412}};
		}
		case 229: {
			return (struct str) {{22, constantarr_0_413}};
		}
		case 230: {
			return (struct str) {{24, constantarr_0_414}};
		}
		case 231: {
			return (struct str) {{5, constantarr_0_417}};
		}
		case 232: {
			return (struct str) {{14, constantarr_0_418}};
		}
		case 233: {
			return (struct str) {{15, constantarr_0_419}};
		}
		case 234: {
			return (struct str) {{10, constantarr_0_420}};
		}
		case 235: {
			return (struct str) {{13, constantarr_0_130}};
		}
		case 236: {
			return (struct str) {{19, constantarr_0_422}};
		}
		case 237: {
			return (struct str) {{14, constantarr_0_423}};
		}
		case 238: {
			return (struct str) {{23, constantarr_0_227}};
		}
		case 239: {
			return (struct str) {{18, constantarr_0_424}};
		}
		case 240: {
			return (struct str) {{24, constantarr_0_425}};
		}
		case 241: {
			return (struct str) {{18, constantarr_0_426}};
		}
		case 242: {
			return (struct str) {{0u, NULL}};
		}
		case 243: {
			return (struct str) {{20, constantarr_0_353}};
		}
		case 244: {
			return (struct str) {{0u, NULL}};
		}
		case 245: {
			return (struct str) {{14, constantarr_0_427}};
		}
		case 246: {
			return (struct str) {{13, constantarr_0_356}};
		}
		case 247: {
			return (struct str) {{13, constantarr_0_130}};
		}
		case 248: {
			return (struct str) {{27, constantarr_0_428}};
		}
		case 249: {
			return (struct str) {{6, constantarr_0_120}};
		}
		case 250: {
			return (struct str) {{24, constantarr_0_429}};
		}
		case 251: {
			return (struct str) {{16, constantarr_0_430}};
		}
		case 252: {
			return (struct str) {{5, constantarr_0_431}};
		}
		case 253: {
			return (struct str) {{13, constantarr_0_432}};
		}
		case 254: {
			return (struct str) {{17, constantarr_0_433}};
		}
		case 255: {
			return (struct str) {{2, constantarr_0_17}};
		}
		case 256: {
			return (struct str) {{27, constantarr_0_436}};
		}
		case 257: {
			return (struct str) {{30, constantarr_0_437}};
		}
		case 258: {
			return (struct str) {{22, constantarr_0_438}};
		}
		case 259: {
			return (struct str) {{22, constantarr_0_439}};
		}
		case 260: {
			return (struct str) {{26, constantarr_0_440}};
		}
		case 261: {
			return (struct str) {{0u, NULL}};
		}
		case 262: {
			return (struct str) {{17, constantarr_0_441}};
		}
		case 263: {
			return (struct str) {{14, constantarr_0_442}};
		}
		case 264: {
			return (struct str) {{30, constantarr_0_443}};
		}
		case 265: {
			return (struct str) {{21, constantarr_0_444}};
		}
		case 266: {
			return (struct str) {{0u, NULL}};
		}
		case 267: {
			return (struct str) {{11, constantarr_0_446}};
		}
		case 268: {
			return (struct str) {{45, constantarr_0_447}};
		}
		case 269: {
			return (struct str) {{19, constantarr_0_448}};
		}
		case 270: {
			return (struct str) {{17, constantarr_0_452}};
		}
		case 271: {
			return (struct str) {{14, constantarr_0_453}};
		}
		case 272: {
			return (struct str) {{9, constantarr_0_454}};
		}
		case 273: {
			return (struct str) {{6, constantarr_0_455}};
		}
		case 274: {
			return (struct str) {{12, constantarr_0_456}};
		}
		case 275: {
			return (struct str) {{10, constantarr_0_459}};
		}
		case 276: {
			return (struct str) {{15, constantarr_0_461}};
		}
		case 277: {
			return (struct str) {{21, constantarr_0_462}};
		}
		case 278: {
			return (struct str) {{28, constantarr_0_466}};
		}
		case 279: {
			return (struct str) {{16, constantarr_0_467}};
		}
		case 280: {
			return (struct str) {{6, constantarr_0_249}};
		}
		case 281: {
			return (struct str) {{23, constantarr_0_470}};
		}
		case 282: {
			return (struct str) {{12, constantarr_0_471}};
		}
		case 283: {
			return (struct str) {{11, constantarr_0_472}};
		}
		case 284: {
			return (struct str) {{17, constantarr_0_473}};
		}
		case 285: {
			return (struct str) {{13, constantarr_0_477}};
		}
		case 286: {
			return (struct str) {{9, constantarr_0_482}};
		}
		case 287: {
			return (struct str) {{17, constantarr_0_484}};
		}
		case 288: {
			return (struct str) {{21, constantarr_0_486}};
		}
		case 289: {
			return (struct str) {{9, constantarr_0_490}};
		}
		case 290: {
			return (struct str) {{14, constantarr_0_494}};
		}
		case 291: {
			return (struct str) {{13, constantarr_0_495}};
		}
		case 292: {
			return (struct str) {{19, constantarr_0_496}};
		}
		case 293: {
			return (struct str) {{12, constantarr_0_497}};
		}
		case 294: {
			return (struct str) {{13, constantarr_0_356}};
		}
		case 295: {
			return (struct str) {{13, constantarr_0_130}};
		}
		case 296: {
			return (struct str) {{15, constantarr_0_498}};
		}
		case 297: {
			return (struct str) {{15, constantarr_0_498}};
		}
		case 298: {
			return (struct str) {{19, constantarr_0_499}};
		}
		case 299: {
			return (struct str) {{13, constantarr_0_224}};
		}
		case 300: {
			return (struct str) {{13, constantarr_0_224}};
		}
		case 301: {
			return (struct str) {{10, constantarr_0_500}};
		}
		case 302: {
			return (struct str) {{11, constantarr_0_501}};
		}
		case 303: {
			return (struct str) {{38, constantarr_0_503}};
		}
		case 304: {
			return (struct str) {{12, constantarr_0_136}};
		}
		case 305: {
			return (struct str) {{8, constantarr_0_137}};
		}
		case 306: {
			return (struct str) {{17, constantarr_0_209}};
		}
		case 307: {
			return (struct str) {{11, constantarr_0_504}};
		}
		case 308: {
			return (struct str) {{8, constantarr_0_508}};
		}
		case 309: {
			return (struct str) {{8, constantarr_0_509}};
		}
		case 310: {
			return (struct str) {{7, constantarr_0_513}};
		}
		case 311: {
			return (struct str) {{12, constantarr_0_517}};
		}
		case 312: {
			return (struct str) {{33, constantarr_0_518}};
		}
		case 313: {
			return (struct str) {{38, constantarr_0_519}};
		}
		case 314: {
			return (struct str) {{8, constantarr_0_520}};
		}
		case 315: {
			return (struct str) {{30, constantarr_0_521}};
		}
		case 316: {
			return (struct str) {{10, constantarr_0_522}};
		}
		case 317: {
			return (struct str) {{13, constantarr_0_523}};
		}
		case 318: {
			return (struct str) {{46, constantarr_0_525}};
		}
		case 319: {
			return (struct str) {{0u, NULL}};
		}
		case 320: {
			return (struct str) {{0u, NULL}};
		}
		case 321: {
			return (struct str) {{0u, NULL}};
		}
		case 322: {
			return (struct str) {{0u, NULL}};
		}
		case 323: {
			return (struct str) {{0u, NULL}};
		}
		case 324: {
			return (struct str) {{0u, NULL}};
		}
		case 325: {
			return (struct str) {{0u, NULL}};
		}
		case 326: {
			return (struct str) {{0u, NULL}};
		}
		case 327: {
			return (struct str) {{0u, NULL}};
		}
		case 328: {
			return (struct str) {{0u, NULL}};
		}
		case 329: {
			return (struct str) {{0u, NULL}};
		}
		case 330: {
			return (struct str) {{0u, NULL}};
		}
		case 331: {
			return (struct str) {{0u, NULL}};
		}
		case 332: {
			return (struct str) {{0u, NULL}};
		}
		case 333: {
			return (struct str) {{0u, NULL}};
		}
		case 334: {
			return (struct str) {{0u, NULL}};
		}
		case 335: {
			return (struct str) {{0u, NULL}};
		}
		case 336: {
			return (struct str) {{0u, NULL}};
		}
		case 337: {
			return (struct str) {{0u, NULL}};
		}
		case 338: {
			return (struct str) {{0u, NULL}};
		}
		case 339: {
			return (struct str) {{0u, NULL}};
		}
		case 340: {
			return (struct str) {{0u, NULL}};
		}
		case 341: {
			return (struct str) {{0u, NULL}};
		}
		case 342: {
			return (struct str) {{0u, NULL}};
		}
		case 343: {
			return (struct str) {{0u, NULL}};
		}
		case 344: {
			return (struct str) {{0u, NULL}};
		}
		case 345: {
			return (struct str) {{0u, NULL}};
		}
		case 346: {
			return (struct str) {{0u, NULL}};
		}
		case 347: {
			return (struct str) {{0u, NULL}};
		}
		case 348: {
			return (struct str) {{0u, NULL}};
		}
		case 349: {
			return (struct str) {{0u, NULL}};
		}
		case 350: {
			return (struct str) {{0u, NULL}};
		}
		case 351: {
			return (struct str) {{0u, NULL}};
		}
		case 352: {
			return (struct str) {{0u, NULL}};
		}
		case 353: {
			return (struct str) {{0u, NULL}};
		}
		case 354: {
			return (struct str) {{0u, NULL}};
		}
		case 355: {
			return (struct str) {{0u, NULL}};
		}
		case 356: {
			return (struct str) {{0u, NULL}};
		}
		case 357: {
			return (struct str) {{0u, NULL}};
		}
		case 358: {
			return (struct str) {{0u, NULL}};
		}
		case 359: {
			return (struct str) {{0u, NULL}};
		}
		case 360: {
			return (struct str) {{0u, NULL}};
		}
		case 361: {
			return (struct str) {{0u, NULL}};
		}
		case 362: {
			return (struct str) {{0u, NULL}};
		}
		case 363: {
			return (struct str) {{0u, NULL}};
		}
		case 364: {
			return (struct str) {{0u, NULL}};
		}
		case 365: {
			return (struct str) {{0u, NULL}};
		}
		case 366: {
			return (struct str) {{0u, NULL}};
		}
		case 367: {
			return (struct str) {{0u, NULL}};
		}
		case 368: {
			return (struct str) {{0u, NULL}};
		}
		case 369: {
			return (struct str) {{0u, NULL}};
		}
		case 370: {
			return (struct str) {{0u, NULL}};
		}
		case 371: {
			return (struct str) {{0u, NULL}};
		}
		case 372: {
			return (struct str) {{0u, NULL}};
		}
		case 373: {
			return (struct str) {{0u, NULL}};
		}
		case 374: {
			return (struct str) {{0u, NULL}};
		}
		case 375: {
			return (struct str) {{0u, NULL}};
		}
		case 376: {
			return (struct str) {{0u, NULL}};
		}
		case 377: {
			return (struct str) {{14, constantarr_0_532}};
		}
		case 378: {
			return (struct str) {{7, constantarr_0_535}};
		}
		case 379: {
			return (struct str) {{17, constantarr_0_536}};
		}
		case 380: {
			return (struct str) {{11, constantarr_0_537}};
		}
		case 381: {
			return (struct str) {{22, constantarr_0_539}};
		}
		case 382: {
			return (struct str) {{9, constantarr_0_542}};
		}
		case 383: {
			return (struct str) {{18, constantarr_0_544}};
		}
		case 384: {
			return (struct str) {{15, constantarr_0_545}};
		}
		case 385: {
			return (struct str) {{12, constantarr_0_548}};
		}
		case 386: {
			return (struct str) {{6, constantarr_0_550}};
		}
		case 387: {
			return (struct str) {{5, constantarr_0_551}};
		}
		case 388: {
			return (struct str) {{19, constantarr_0_553}};
		}
		case 389: {
			return (struct str) {{4, constantarr_0_554}};
		}
		case 390: {
			return (struct str) {{35, constantarr_0_555}};
		}
		case 391: {
			return (struct str) {{17, constantarr_0_557}};
		}
		case 392: {
			return (struct str) {{25, constantarr_0_558}};
		}
		case 393: {
			return (struct str) {{21, constantarr_0_559}};
		}
		case 394: {
			return (struct str) {{24, constantarr_0_560}};
		}
		case 395: {
			return (struct str) {{20, constantarr_0_561}};
		}
		case 396: {
			return (struct str) {{4, constantarr_0_563}};
		}
		case 397: {
			return (struct str) {{13, constantarr_0_564}};
		}
		default:
			return (struct str) {(struct arr_0) {0, NULL}};
	}
}
/* sort-together void(a ptr<ptr<nat8>>, b ptr<str>, size nat) */
struct void_ sort_together(struct ctx* ctx, uint8_t** a, struct str* b, uint64_t size) {
	top:;
	uint8_t _0 = _greater(size, 1u);
	if (_0) {
		swap_0(ctx, a, 0u, (size / 2u));
		swap_1(ctx, b, 0u, (size / 2u));
		uint64_t after_pivot0;
		after_pivot0 = partition_recur_together(ctx, a, b, (*a), 1u, (size - 1u));
		
		uint64_t new_pivot_index1;
		new_pivot_index1 = (after_pivot0 - 1u);
		
		swap_0(ctx, a, 0u, new_pivot_index1);
		swap_1(ctx, b, 0u, new_pivot_index1);
		sort_together(ctx, a, b, new_pivot_index1);
		a = (a + after_pivot0);
		b = (b + after_pivot0);
		size = (size - after_pivot0);
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* swap<ptr<nat8>> void(a ptr<ptr<nat8>>, lo nat, hi nat) */
struct void_ swap_0(struct ctx* ctx, uint8_t** a, uint64_t lo, uint64_t hi) {
	uint8_t* temp0;
	temp0 = subscript_1(a, lo);
	
	uint8_t* _0 = subscript_1(a, hi);
	set_subscript_0(a, lo, _0);
	return set_subscript_0(a, hi, temp0);
}
/* subscript<?a> ptr<nat8>(a ptr<ptr<nat8>>, n nat) */
uint8_t* subscript_1(uint8_t** a, uint64_t n) {
	return (*(a + n));
}
/* swap<str> void(a ptr<str>, lo nat, hi nat) */
struct void_ swap_1(struct ctx* ctx, struct str* a, uint64_t lo, uint64_t hi) {
	struct str temp0;
	temp0 = subscript_2(a, lo);
	
	struct str _0 = subscript_2(a, hi);
	set_subscript_1(a, lo, _0);
	return set_subscript_1(a, hi, temp0);
}
/* subscript<?a> str(a ptr<str>, n nat) */
struct str subscript_2(struct str* a, uint64_t n) {
	return (*(a + n));
}
/* partition-recur-together nat(a ptr<ptr<nat8>>, b ptr<str>, pivot ptr<nat8>, l nat, r nat) */
uint64_t partition_recur_together(struct ctx* ctx, uint8_t** a, struct str* b, uint8_t* pivot, uint64_t l, uint64_t r) {
	top:;
	uint8_t _0 = _lessOrEqual(l, r);
	if (_0) {
		uint8_t* _1 = subscript_1(a, l);
		uint8_t _2 = (_1 < pivot);
		if (_2) {
			a = a;
			b = b;
			pivot = pivot;
			l = (l + 1u);
			r = r;
			goto top;
		} else {
			swap_0(ctx, a, l, r);
			swap_1(ctx, b, l, r);
			a = a;
			b = b;
			pivot = pivot;
			l = l;
			r = (r - 1u);
			goto top;
		}
	} else {
		return l;
	}
}
/* fill-code-names-recur void(code-names ptr<str>, end-code-names ptr<str>, code-ptrs ptr<ptr<nat8>>, fun-ptrs ptr<ptr<nat8>>, fun-names ptr<str>) */
struct void_ fill_code_names_recur(struct ctx* ctx, struct str* code_names, struct str* end_code_names, uint8_t** code_ptrs, uint8_t** fun_ptrs, struct str* fun_names) {
	top:;
	uint8_t _0 = (code_names < end_code_names);
	if (_0) {
		uint64_t _1 = funs_count_91();
		struct str _2 = get_fun_name((*code_ptrs), fun_ptrs, fun_names, _1);
		*code_names = _2;
		code_names = (code_names + 1u);
		end_code_names = end_code_names;
		code_ptrs = (code_ptrs + 1u);
		fun_ptrs = fun_ptrs;
		fun_names = fun_names;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* get-fun-name str(code-ptr ptr<nat8>, fun-ptrs ptr<ptr<nat8>>, fun-names ptr<str>, size nat) */
struct str get_fun_name(uint8_t* code_ptr, uint8_t** fun_ptrs, struct str* fun_names, uint64_t size) {
	top:;
	uint8_t _0 = _less(size, 2u);
	if (_0) {
		return (struct str) {{11, constantarr_0_2}};
	} else {
		uint8_t* _1 = subscript_1(fun_ptrs, 1u);
		uint8_t _2 = (code_ptr < _1);
		if (_2) {
			return (*fun_names);
		} else {
			code_ptr = code_ptr;
			fun_ptrs = (fun_ptrs + 1u);
			fun_names = (fun_names + 1u);
			size = (size - 1u);
			goto top;
		}
	}
}
/* begin-ptr<?a> ptr<char>(a mut-list<char>) */
char* begin_ptr_0(struct mut_list_1* a) {
	return begin_ptr_1(a->backing);
}
/* begin-ptr<?a> ptr<char>(a mut-arr<char>) */
char* begin_ptr_1(struct mut_arr_1 a) {
	return a.inner.begin_ptr;
}
/* uninitialized-mut-arr<?a> mut-arr<char>(size nat) */
struct mut_arr_1 uninitialized_mut_arr(struct ctx* ctx, uint64_t size) {
	char* _0 = alloc_uninitialized_0(ctx, size);
	return mut_arr_2(size, _0);
}
/* mut-arr<?a> mut-arr<char>(size nat, begin-ptr ptr<char>) */
struct mut_arr_1 mut_arr_2(uint64_t size, char* begin_ptr) {
	return (struct mut_arr_1) {(struct void_) {}, (struct arr_0) {size, begin_ptr}};
}
/* alloc-uninitialized<?a> ptr<char>(size nat) */
char* alloc_uninitialized_0(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(char)));
	return ((char*) _0);
}
/* alloc ptr<nat8>(size-bytes nat) */
uint8_t* alloc(struct ctx* ctx, uint64_t size_bytes) {
	struct gc* _0 = get_gc(ctx);
	return gc_alloc(ctx, _0, size_bytes);
}
/* gc-alloc ptr<nat8>(gc gc, size nat) */
uint8_t* gc_alloc(struct ctx* ctx, struct gc* gc, uint64_t size) {
	struct opt_5 _0 = try_gc_alloc(gc, size);
	switch (_0.kind) {
		case 0: {
			return todo_1();
		}
		case 1: {
			struct some_5 _matched0 = _0.as1;
			
			uint8_t* res1;
			res1 = _matched0.value;
			
			return res1;
		}
		default:
			
	return NULL;;
	}
}
/* todo<ptr<nat8>> ptr<nat8>() */
uint8_t* todo_1(void) {
	(abort(), (struct void_) {});
	return NULL;
}
/* copy-data-from<?a> void(to ptr<char>, from ptr<char>, len nat) */
struct void_ copy_data_from(struct ctx* ctx, char* to, char* from, uint64_t len) {
	return (memcpy(((uint8_t*) to), ((uint8_t*) from), (len * sizeof(char))), (struct void_) {});
}
/* set-zero-elements<?a> void(a mut-arr<char>) */
struct void_ set_zero_elements(struct mut_arr_1 a) {
	char* _0 = begin_ptr_1(a);
	uint64_t _1 = size_0(a);
	return set_zero_range_1(_0, _1);
}
/* set-zero-range<?a> void(begin ptr<char>, size nat) */
struct void_ set_zero_range_1(char* begin, uint64_t size) {
	return (memset(((uint8_t*) begin), 0u, (size * sizeof(char))), (struct void_) {});
}
/* subscript<?a> mut-arr<char>(a mut-arr<char>, range arrow<nat, nat>) */
struct mut_arr_1 subscript_3(struct ctx* ctx, struct mut_arr_1 a, struct arrow range) {
	uint8_t _0 = _lessOrEqual(range.from, range.to);
	assert(ctx, _0);
	uint64_t _1 = size_0(a);
	uint8_t _2 = _lessOrEqual(range.to, _1);
	assert(ctx, _2);
	struct arr_0 _3 = subscript_4(ctx, a.inner, range);
	return (struct mut_arr_1) {(struct void_) {}, _3};
}
/* subscript<?a> arr<char>(a arr<char>, range arrow<nat, nat>) */
struct arr_0 subscript_4(struct ctx* ctx, struct arr_0 a, struct arrow range) {
	uint8_t _0 = _lessOrEqual(range.from, range.to);
	assert(ctx, _0);
	uint8_t _1 = _lessOrEqual(range.to, a.size);
	assert(ctx, _1);
	return (struct arr_0) {(range.to - range.from), (a.begin_ptr + range.from)};
}
/* -><nat, nat> arrow<nat, nat>(from nat, to nat) */
struct arrow _arrow(struct ctx* ctx, uint64_t from, uint64_t to) {
	return (struct arrow) {from, to};
}
/* + nat(a nat, b nat) */
uint64_t _plus(struct ctx* ctx, uint64_t a, uint64_t b) {
	uint64_t res0;
	res0 = (a + b);
	
	uint8_t _0 = _greaterOrEqual(res0, a);uint8_t _1;
	
	if (_0) {
		_1 = _greaterOrEqual(res0, b);
	} else {
		_1 = 0;
	}
	assert(ctx, _1);
	return res0;
}
/* >=<nat> bool(a nat, b nat) */
uint8_t _greaterOrEqual(uint64_t a, uint64_t b) {
	uint8_t _0 = _less(a, b);
	return not(_0);
}
/* round-up-to-power-of-two nat(n nat) */
uint64_t round_up_to_power_of_two(struct ctx* ctx, uint64_t n) {
	return round_up_to_power_of_two_recur(ctx, 1u, n);
}
/* round-up-to-power-of-two-recur nat(acc nat, n nat) */
uint64_t round_up_to_power_of_two_recur(struct ctx* ctx, uint64_t acc, uint64_t n) {
	top:;
	uint8_t _0 = _greaterOrEqual(acc, n);
	if (_0) {
		return acc;
	} else {
		uint64_t _1 = _times(ctx, acc, 2u);
		acc = _1;
		n = n;
		goto top;
	}
}
/* * nat(a nat, b nat) */
uint64_t _times(struct ctx* ctx, uint64_t a, uint64_t b) {uint8_t _0;
	
	if ((a == 0u)) {
		_0 = 1;
	} else {
		_0 = (b == 0u);
	}
	if (_0) {
		return 0u;
	} else {
		uint64_t res0;
		res0 = (a * b);
		
		uint64_t _1 = _divide(ctx, res0, b);
		assert(ctx, (_1 == a));
		uint64_t _2 = _divide(ctx, res0, a);
		assert(ctx, (_2 == b));
		return res0;
	}
}
/* / nat(a nat, b nat) */
uint64_t _divide(struct ctx* ctx, uint64_t a, uint64_t b) {
	forbid(ctx, (b == 0u));
	return (a / b);
}
/* forbid void(condition bool) */
struct void_ forbid(struct ctx* ctx, uint8_t condition) {
	uint8_t _0 = condition;
	if (_0) {
		return throw_0(ctx, (struct str) {{13, constantarr_0_4}});
	} else {
		return (struct void_) {};
	}
}
/* set-subscript<?a> void(a ptr<char>, n nat, value char) */
struct void_ set_subscript_2(char* a, uint64_t n, char value) {
	return (*(a + n) = value, (struct void_) {});
}
/* ~=<char>.lambda0 void(it char) */
struct void_ _concatEquals_1__lambda0(struct ctx* ctx, struct _concatEquals_1__lambda0* _closure, char it) {
	return _concatEquals_2(ctx, _closure->a, it);
}
/* empty? bool(a str) */
uint8_t empty__q_0(struct str a) {
	return empty__q_1(a.chars);
}
/* empty?<char> bool(a arr<char>) */
uint8_t empty__q_1(struct arr_0 a) {
	return (a.size == 0u);
}
/* each<str> void(a arr<str>, f fun-act1<void, str>) */
struct void_ each_1(struct ctx* ctx, struct arr_1 a, struct fun_act1_2 f) {
	struct str* _0 = end_ptr_1(a);
	return each_recur_1(ctx, a.begin_ptr, _0, f);
}
/* each-recur<?a> void(cur ptr<str>, end ptr<str>, f fun-act1<void, str>) */
struct void_ each_recur_1(struct ctx* ctx, struct str* cur, struct str* end, struct fun_act1_2 f) {
	top:;
	uint8_t _0 = not((cur == end));
	if (_0) {
		subscript_5(ctx, f, (*cur));
		cur = (cur + 1u);
		end = end;
		f = f;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* subscript<void, ?a> void(a fun-act1<void, str>, p0 str) */
struct void_ subscript_5(struct ctx* ctx, struct fun_act1_2 a, struct str p0) {
	return call_w_ctx_137(a, ctx, p0);
}
/* call-w-ctx<void, str> (generated) (generated) */
struct void_ call_w_ctx_137(struct fun_act1_2 a, struct ctx* ctx, struct str p0) {
	struct fun_act1_2 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct to_str_0__lambda0* closure0 = _0.as0;
			
			return to_str_0__lambda0(ctx, closure0, p0);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* end-ptr<?a> ptr<str>(a arr<str>) */
struct str* end_ptr_1(struct arr_1 a) {
	return (a.begin_ptr + a.size);
}
/* to-str.lambda0 void(x str) */
struct void_ to_str_0__lambda0(struct ctx* ctx, struct to_str_0__lambda0* _closure, struct str x) {
	_concatEquals_0(ctx, _closure->res, (struct str) {{5, constantarr_0_6}});
	return _concatEquals_0(ctx, _closure->res, x);
}
/* move-to-str! str(a writer) */
struct str move_to_str__e(struct ctx* ctx, struct writer a) {
	struct arr_0 _0 = move_to_arr__e(a.chars);
	return (struct str) {_0};
}
/* move-to-arr!<char> arr<char>(a mut-list<char>) */
struct arr_0 move_to_arr__e(struct mut_list_1* a) {
	struct arr_0 res0;
	char* _0 = begin_ptr_0(a);
	res0 = (struct arr_0) {a->size, _0};
	
	struct mut_arr_1 _1 = mut_arr_1();
	a->backing = _1;
	a->size = 0u;
	return res0;
}
/* get-global-ctx global-ctx() */
struct global_ctx* get_global_ctx(struct ctx* ctx) {
	return ((struct global_ctx*) ctx->gctx_ptr);
}
/* island.lambda0 void(it exception) */
struct void_ island__lambda0(struct ctx* ctx, struct void_ _closure, struct exception it) {
	return default_exception_handler(ctx, it);
}
/* default-log-handler void(a logged) */
struct void_ default_log_handler(struct ctx* ctx, struct logged* a) {
	struct str _0 = to_str_1(ctx, a->level);
	struct str _1 = _concat_0(ctx, _0, (struct str) {{2, constantarr_0_10}});
	struct str _2 = _concat_0(ctx, _1, a->message);
	return print(_2);
}
/* print void(a str) */
struct void_ print(struct str a) {
	print_no_newline(a);
	return print_no_newline((struct str) {{1, constantarr_0_1}});
}
/* print-no-newline void(a str) */
struct void_ print_no_newline(struct str a) {
	int32_t _0 = stdout();
	return write_no_newline(_0, a);
}
/* stdout int32() */
int32_t stdout(void) {
	return 1;
}
/* ~ str(a str, b str) */
struct str _concat_0(struct ctx* ctx, struct str a, struct str b) {
	struct arr_0 _0 = _concat_1(ctx, a.chars, b.chars);
	return (struct str) {_0};
}
/* ~<char> arr<char>(a arr<char>, b arr<char>) */
struct arr_0 _concat_1(struct ctx* ctx, struct arr_0 a, struct arr_0 b) {
	uint64_t res_size0;
	res_size0 = (a.size + b.size);
	
	char* res1;
	res1 = alloc_uninitialized_0(ctx, res_size0);
	
	copy_data_from(ctx, res1, a.begin_ptr, a.size);
	copy_data_from(ctx, (res1 + a.size), b.begin_ptr, b.size);
	return (struct arr_0) {res_size0, res1};
}
/* to-str str(a log-level) */
struct str to_str_1(struct ctx* ctx, struct log_level a) {
	struct log_level _0 = a;
	switch (_0.kind) {
		case 0: {
			return (struct str) {{4, constantarr_0_7}};
		}
		case 1: {
			return (struct str) {{4, constantarr_0_8}};
		}
		case 2: {
			return (struct str) {{5, constantarr_0_9}};
		}
		default:
			
	return (struct str) {(struct arr_0) {0, NULL}};;
	}
}
/* island.lambda1 void(log logged) */
struct void_ island__lambda1(struct ctx* ctx, struct void_ _closure, struct logged* log) {
	return default_log_handler(ctx, log);
}
/* gc gc() */
struct gc gc(void) {
	uint8_t* mark0;
	uint8_t* _0 = malloc(33554432u);
	mark0 = ((uint8_t*) _0);
	
	uint8_t* mark_end1;
	mark_end1 = (mark0 + 33554432u);
	
	uint64_t* data2;
	uint8_t* _1 = malloc((33554432u * sizeof(uint64_t)));
	data2 = ((uint64_t*) _1);
	
	uint8_t _2 = word_aligned__q(((uint8_t*) data2));
	hard_assert(_2);
	uint64_t* data_end3;
	data_end3 = (data2 + 33554432u);
	
	(memset(((uint8_t*) mark0), 0u, 33554432u), (struct void_) {});
	struct gc res4;
	struct lock _3 = lock_by_val();
	res4 = (struct gc) {_3, 0u, (struct opt_1) {0, .as0 = (struct none) {}}, 0, 33554432u, mark0, mark0, mark_end1, data2, data2, data_end3};
	
	validate_gc((&res4));
	return res4;
}
/* validate-gc void(gc gc) */
struct void_ validate_gc(struct gc* gc) {
	uint8_t _0 = word_aligned__q(((uint8_t*) gc->mark_begin));
	hard_assert(_0);
	uint8_t _1 = word_aligned__q(((uint8_t*) gc->data_begin));
	hard_assert(_1);
	uint8_t _2 = word_aligned__q(((uint8_t*) gc->data_cur));
	hard_assert(_2);
	uint8_t _3 = ptr_less_eq__q_0(gc->mark_begin, gc->mark_cur);
	hard_assert(_3);
	uint8_t _4 = ptr_less_eq__q_0(gc->mark_cur, gc->mark_end);
	hard_assert(_4);
	uint8_t _5 = ptr_less_eq__q_1(gc->data_begin, gc->data_cur);
	hard_assert(_5);
	uint8_t _6 = ptr_less_eq__q_1(gc->data_cur, gc->data_end);
	hard_assert(_6);
	uint64_t mark_idx0;
	mark_idx0 = _minus_1(gc->mark_cur, gc->mark_begin);
	
	uint64_t data_idx1;
	data_idx1 = _minus_0(gc->data_cur, gc->data_begin);
	
	uint64_t _7 = _minus_1(gc->mark_end, gc->mark_begin);
	hard_assert((_7 == gc->size_words));
	uint64_t _8 = _minus_0(gc->data_end, gc->data_begin);
	hard_assert((_8 == gc->size_words));
	return hard_assert((mark_idx0 == data_idx1));
}
/* ptr-less-eq?<bool> bool(a ptr<bool>, b ptr<bool>) */
uint8_t ptr_less_eq__q_0(uint8_t* a, uint8_t* b) {
	if ((a < b)) {
		return 1;
	} else {
		return (a == b);
	}
}
/* ptr-less-eq?<nat> bool(a ptr<nat>, b ptr<nat>) */
uint8_t ptr_less_eq__q_1(uint64_t* a, uint64_t* b) {
	if ((a < b)) {
		return 1;
	} else {
		return (a == b);
	}
}
/* -<bool> nat(a ptr<bool>, b ptr<bool>) */
uint64_t _minus_1(uint8_t* a, uint8_t* b) {
	return ((((uint64_t) a) - ((uint64_t) b)) / sizeof(uint8_t));
}
/* thread-safe-counter thread-safe-counter() */
struct thread_safe_counter thread_safe_counter_0(void) {
	return thread_safe_counter_1(0u);
}
/* thread-safe-counter thread-safe-counter(init nat) */
struct thread_safe_counter thread_safe_counter_1(uint64_t init) {
	struct lock _0 = lock_by_val();
	return (struct thread_safe_counter) {_0, init};
}
/* add-main-task fut<nat>(gctx global-ctx, thread-id nat, island island, argc int32, argv ptr<ptr<char>>, main-ptr fun-ptr2<fut<nat>, ctx, arr<str>>) */
struct fut_0* add_main_task(struct global_ctx* gctx, uint64_t thread_id, struct island* island, int32_t argc, char** argv, fun_ptr2 main_ptr) {
	struct exception_ctx ectx0;
	ectx0 = exception_ctx();
	
	struct log_ctx log_ctx1;
	log_ctx1 = log_ctx();
	
	struct perf_ctx perf_ctx2;
	perf_ctx2 = perf_ctx();
	
	uint8_t* ectx_ptr3;
	ectx_ptr3 = ((uint8_t*) (&ectx0));
	
	uint8_t* log_ctx_ptr4;
	log_ctx_ptr4 = ((uint8_t*) (&log_ctx1));
	
	uint8_t* perf_ptr5;
	perf_ptr5 = ((uint8_t*) (&perf_ctx2));
	
	struct lock* print_lock6;
	print_lock6 = (&gctx->print_lock);
	
	struct thread_local_stuff tls7;
	tls7 = (struct thread_local_stuff) {thread_id, print_lock6, ectx_ptr3, log_ctx_ptr4, perf_ptr5};
	
	struct ctx ctx_by_val8;
	ctx_by_val8 = ctx(gctx, (&tls7), island, 0u);
	
	struct ctx* ctx9;
	ctx9 = (&ctx_by_val8);
	
	struct fun_act2 add10;
	add10 = (struct fun_act2) {0, .as0 = (struct void_) {}};
	
	struct arr_5 all_args11;
	all_args11 = (struct arr_5) {((uint64_t) ((int64_t) argc)), argv};
	
	return call_w_ctx_266(add10, ctx9, all_args11, main_ptr);
}
/* exception-ctx exception-ctx() */
struct exception_ctx exception_ctx(void) {
	return (struct exception_ctx) {NULL, (struct exception) {(struct str) {{0u, NULL}}, (struct backtrace) {(struct arr_1) {0u, NULL}}}};
}
/* log-ctx log-ctx() */
struct log_ctx log_ctx(void) {
	return (struct log_ctx) {(struct fun1_1) {0}};
}
/* perf-ctx perf-ctx() */
struct perf_ctx perf_ctx(void) {
	struct mut_arr_2 _0 = mut_arr_3();
	return (struct perf_ctx) {(struct arr_1) {0u, NULL}, _0};
}
/* mut-arr<measure-value> mut-arr<measure-value>() */
struct mut_arr_2 mut_arr_3(void) {
	return (struct mut_arr_2) {(struct void_) {}, (struct arr_4) {0u, NULL}};
}
/* ctx ctx(gctx global-ctx, tls thread-local-stuff, island island, exclusion nat) */
struct ctx ctx(struct global_ctx* gctx, struct thread_local_stuff* tls, struct island* island, uint64_t exclusion) {
	struct gc_ctx* gc_ctx0;
	gc_ctx0 = get_gc_ctx_1((&island->gc));
	
	((struct log_ctx*) tls->log_ctx_ptr)->handler = (&island->gc_root)->log_handler;
	return (struct ctx) {((uint8_t*) gctx), island->id, exclusion, ((uint8_t*) gc_ctx0), tls};
}
/* get-gc-ctx gc-ctx(gc gc) */
struct gc_ctx* get_gc_ctx_1(struct gc* gc) {
	acquire__e((&gc->lk));
	struct gc_ctx* res3;
	struct opt_1 _0 = gc->context_head;
	switch (_0.kind) {
		case 0: {
			struct gc_ctx* c0;
			uint8_t* _1 = malloc(sizeof(struct gc_ctx));
			c0 = ((struct gc_ctx*) _1);
			
			c0->gc = gc;
			c0->next_ctx = (struct opt_1) {0, .as0 = (struct none) {}};
			res3 = c0;
			break;
		}
		case 1: {
			struct some_1 _matched1 = _0.as1;
			
			struct gc_ctx* c2;
			c2 = _matched1.value;
			
			gc->context_head = c2->next_ctx;
			c2->next_ctx = (struct opt_1) {0, .as0 = (struct none) {}};
			res3 = c2;
			break;
		}
		default:
			
	res3 = NULL;;
	}
	
	release__e((&gc->lk));
	return res3;
}
/* add-first-task fut<nat>(all-args arr<ptr<char>>, main-ptr fun-ptr2<fut<nat>, ctx, arr<str>>) */
struct fut_0* add_first_task(struct ctx* ctx, struct arr_5 all_args, fun_ptr2 main_ptr) {
	struct fut_0* res0;
	struct fut_1* _0 = delay(ctx);
	struct island_and_exclusion _1 = cur_island_and_exclusion(ctx);
	struct add_first_task__lambda0* temp0;
	uint8_t* _2 = alloc(ctx, sizeof(struct add_first_task__lambda0));
	temp0 = ((struct add_first_task__lambda0*) _2);
	
	*temp0 = (struct add_first_task__lambda0) {all_args, main_ptr};
	res0 = then_void(ctx, _0, (struct fun_ref0) {_1, (struct fun_act0_1) {0, .as0 = temp0}});
	
	handle_exceptions(ctx, res0);
	return res0;
}
/* then-void<nat> fut<nat>(a fut<void>, cb fun-ref0<nat>) */
struct fut_0* then_void(struct ctx* ctx, struct fut_1* a, struct fun_ref0 cb) {
	struct island_and_exclusion _0 = cur_island_and_exclusion(ctx);
	struct then_void__lambda0* temp0;
	uint8_t* _1 = alloc(ctx, sizeof(struct then_void__lambda0));
	temp0 = ((struct then_void__lambda0*) _1);
	
	*temp0 = (struct then_void__lambda0) {cb};
	return then(ctx, a, (struct fun_ref1) {_0, (struct fun_act1_4) {0, .as0 = temp0}});
}
/* then<?out, void> fut<nat>(a fut<void>, cb fun-ref1<nat, void>) */
struct fut_0* then(struct ctx* ctx, struct fut_1* a, struct fun_ref1 cb) {
	struct fut_0* res0;
	res0 = unresolved(ctx);
	
	struct then__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct then__lambda0));
	temp0 = ((struct then__lambda0*) _0);
	
	*temp0 = (struct then__lambda0) {cb, res0};
	callback__e_0(ctx, a, (struct fun_act1_3) {0, .as0 = temp0});
	return res0;
}
/* unresolved<?out> fut<nat>() */
struct fut_0* unresolved(struct ctx* ctx) {
	struct fut_0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct fut_0));
	temp0 = ((struct fut_0*) _0);
	
	struct lock _1 = lock_by_val();
	*temp0 = (struct fut_0) {_1, (struct fut_state_0) {0, .as0 = (struct fut_state_no_callbacks) {}}};
	return temp0;
}
/* callback!<?in> void(f fut<void>, cb fun-act1<void, result<void, exception>>) */
struct void_ callback__e_0(struct ctx* ctx, struct fut_1* f, struct fun_act1_3 cb) {
	struct callback__e_0__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct callback__e_0__lambda0));
	temp0 = ((struct callback__e_0__lambda0*) _0);
	
	*temp0 = (struct callback__e_0__lambda0) {f, cb};
	return with_lock_0(ctx, (&f->lk), (struct fun_act0_0) {0, .as0 = temp0});
}
/* with-lock<void> void(a lock, f fun-act0<void>) */
struct void_ with_lock_0(struct ctx* ctx, struct lock* a, struct fun_act0_0 f) {
	acquire__e(a);
	struct void_ res0;
	res0 = subscript_6(ctx, f);
	
	release__e(a);
	return res0;
}
/* subscript<?a> void(a fun-act0<void>) */
struct void_ subscript_6(struct ctx* ctx, struct fun_act0_0 a) {
	return call_w_ctx_173(a, ctx);
}
/* call-w-ctx<void> (generated) (generated) */
struct void_ call_w_ctx_173(struct fun_act0_0 a, struct ctx* ctx) {
	struct fun_act0_0 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct callback__e_0__lambda0* closure0 = _0.as0;
			
			return callback__e_0__lambda0(ctx, closure0);
		}
		case 1: {
			struct callback__e_1__lambda0* closure1 = _0.as1;
			
			return callback__e_1__lambda0(ctx, closure1);
		}
		case 2: {
			struct subscript_10__lambda0__lambda0* closure2 = _0.as2;
			
			return subscript_10__lambda0__lambda0(ctx, closure2);
		}
		case 3: {
			struct subscript_10__lambda0* closure3 = _0.as3;
			
			return subscript_10__lambda0(ctx, closure3);
		}
		case 4: {
			struct subscript_15__lambda0__lambda0* closure4 = _0.as4;
			
			return subscript_15__lambda0__lambda0(ctx, closure4);
		}
		case 5: {
			struct subscript_15__lambda0* closure5 = _0.as5;
			
			return subscript_15__lambda0(ctx, closure5);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* subscript<void, result<?a, exception>> void(a fun-act1<void, result<void, exception>>, p0 result<void, exception>) */
struct void_ subscript_7(struct ctx* ctx, struct fun_act1_3 a, struct result_1 p0) {
	return call_w_ctx_175(a, ctx, p0);
}
/* call-w-ctx<void, result<void, exception>> (generated) (generated) */
struct void_ call_w_ctx_175(struct fun_act1_3 a, struct ctx* ctx, struct result_1 p0) {
	struct fun_act1_3 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct then__lambda0* closure0 = _0.as0;
			
			return then__lambda0(ctx, closure0, p0);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* callback!<?in>.lambda0 void() */
struct void_ callback__e_0__lambda0(struct ctx* ctx, struct callback__e_0__lambda0* _closure) {
	struct fut_state_1 _0 = _closure->f->state;
	switch (_0.kind) {
		case 0: {
			struct fut_state_callbacks_1* temp0;
			uint8_t* _1 = alloc(ctx, sizeof(struct fut_state_callbacks_1));
			temp0 = ((struct fut_state_callbacks_1*) _1);
			
			*temp0 = (struct fut_state_callbacks_1) {_closure->cb, (struct opt_7) {0, .as0 = (struct none) {}}};
			return (_closure->f->state = (struct fut_state_1) {1, .as1 = temp0}, (struct void_) {});
		}
		case 1: {
			struct fut_state_callbacks_1* cbs0 = _0.as1;
			
			struct fut_state_callbacks_1* temp1;
			uint8_t* _2 = alloc(ctx, sizeof(struct fut_state_callbacks_1));
			temp1 = ((struct fut_state_callbacks_1*) _2);
			
			*temp1 = (struct fut_state_callbacks_1) {_closure->cb, (struct opt_7) {1, .as1 = (struct some_7) {cbs0}}};
			return (_closure->f->state = (struct fut_state_1) {1, .as1 = temp1}, (struct void_) {});
		}
		case 2: {
			struct fut_state_resolved_1 r1 = _0.as2;
			
			return subscript_7(ctx, _closure->cb, (struct result_1) {0, .as0 = (struct ok_1) {r1.value}});
		}
		case 3: {
			struct exception e2 = _0.as3;
			
			return subscript_7(ctx, _closure->cb, (struct result_1) {1, .as1 = (struct err) {e2}});
		}
		default:
			
	return (struct void_) {};;
	}
}
/* forward-to!<?out> void(from fut<nat>, to fut<nat>) */
struct void_ forward_to__e(struct ctx* ctx, struct fut_0* from, struct fut_0* to) {
	struct forward_to__e__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct forward_to__e__lambda0));
	temp0 = ((struct forward_to__e__lambda0*) _0);
	
	*temp0 = (struct forward_to__e__lambda0) {to};
	return callback__e_1(ctx, from, (struct fun_act1_0) {0, .as0 = temp0});
}
/* callback!<?a> void(f fut<nat>, cb fun-act1<void, result<nat, exception>>) */
struct void_ callback__e_1(struct ctx* ctx, struct fut_0* f, struct fun_act1_0 cb) {
	struct callback__e_1__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct callback__e_1__lambda0));
	temp0 = ((struct callback__e_1__lambda0*) _0);
	
	*temp0 = (struct callback__e_1__lambda0) {f, cb};
	return with_lock_0(ctx, (&f->lk), (struct fun_act0_0) {1, .as1 = temp0});
}
/* subscript<void, result<?a, exception>> void(a fun-act1<void, result<nat, exception>>, p0 result<nat, exception>) */
struct void_ subscript_8(struct ctx* ctx, struct fun_act1_0 a, struct result_0 p0) {
	return call_w_ctx_180(a, ctx, p0);
}
/* call-w-ctx<void, result<nat, exception>> (generated) (generated) */
struct void_ call_w_ctx_180(struct fun_act1_0 a, struct ctx* ctx, struct result_0 p0) {
	struct fun_act1_0 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct forward_to__e__lambda0* closure0 = _0.as0;
			
			return forward_to__e__lambda0(ctx, closure0, p0);
		}
		case 1: {
			struct void_ closure1 = _0.as1;
			
			return handle_exceptions__lambda0(ctx, closure1, p0);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* callback!<?a>.lambda0 void() */
struct void_ callback__e_1__lambda0(struct ctx* ctx, struct callback__e_1__lambda0* _closure) {
	struct fut_state_0 _0 = _closure->f->state;
	switch (_0.kind) {
		case 0: {
			struct fut_state_callbacks_0* temp0;
			uint8_t* _1 = alloc(ctx, sizeof(struct fut_state_callbacks_0));
			temp0 = ((struct fut_state_callbacks_0*) _1);
			
			*temp0 = (struct fut_state_callbacks_0) {_closure->cb, (struct opt_0) {0, .as0 = (struct none) {}}};
			return (_closure->f->state = (struct fut_state_0) {1, .as1 = temp0}, (struct void_) {});
		}
		case 1: {
			struct fut_state_callbacks_0* cbs0 = _0.as1;
			
			struct fut_state_callbacks_0* temp1;
			uint8_t* _2 = alloc(ctx, sizeof(struct fut_state_callbacks_0));
			temp1 = ((struct fut_state_callbacks_0*) _2);
			
			*temp1 = (struct fut_state_callbacks_0) {_closure->cb, (struct opt_0) {1, .as1 = (struct some_0) {cbs0}}};
			return (_closure->f->state = (struct fut_state_0) {1, .as1 = temp1}, (struct void_) {});
		}
		case 2: {
			struct fut_state_resolved_0 r1 = _0.as2;
			
			return subscript_8(ctx, _closure->cb, (struct result_0) {0, .as0 = (struct ok_0) {r1.value}});
		}
		case 3: {
			struct exception e2 = _0.as3;
			
			return subscript_8(ctx, _closure->cb, (struct result_0) {1, .as1 = (struct err) {e2}});
		}
		default:
			
	return (struct void_) {};;
	}
}
/* resolve-or-reject!<?a> void(f fut<nat>, result result<nat, exception>) */
struct void_ resolve_or_reject__e(struct ctx* ctx, struct fut_0* f, struct result_0 result) {
	struct fut_state_0 old_state0;
	struct resolve_or_reject__e__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct resolve_or_reject__e__lambda0));
	temp0 = ((struct resolve_or_reject__e__lambda0*) _0);
	
	*temp0 = (struct resolve_or_reject__e__lambda0) {f, result};
	old_state0 = with_lock_1(ctx, (&f->lk), (struct fun_act0_2) {0, .as0 = temp0});
	
	struct fut_state_0 _1 = old_state0;
	switch (_1.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct fut_state_callbacks_0* cbs1 = _1.as1;
			
			return call_callbacks__e(ctx, cbs1, result);
		}
		case 2: {
			return hard_unreachable_0();
		}
		case 3: {
			return hard_unreachable_0();
		}
		default:
			
	return (struct void_) {};;
	}
}
/* with-lock<fut-state<?a>> fut-state<nat>(a lock, f fun-act0<fut-state<nat>>) */
struct fut_state_0 with_lock_1(struct ctx* ctx, struct lock* a, struct fun_act0_2 f) {
	acquire__e(a);
	struct fut_state_0 res0;
	res0 = subscript_9(ctx, f);
	
	release__e(a);
	return res0;
}
/* subscript<?a> fut-state<nat>(a fun-act0<fut-state<nat>>) */
struct fut_state_0 subscript_9(struct ctx* ctx, struct fun_act0_2 a) {
	return call_w_ctx_185(a, ctx);
}
/* call-w-ctx<fut-state<nat>> (generated) (generated) */
struct fut_state_0 call_w_ctx_185(struct fun_act0_2 a, struct ctx* ctx) {
	struct fun_act0_2 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct resolve_or_reject__e__lambda0* closure0 = _0.as0;
			
			return resolve_or_reject__e__lambda0(ctx, closure0);
		}
		default:
			
	return (struct fut_state_0) {0};;
	}
}
/* resolve-or-reject!<?a>.lambda0 fut-state<nat>() */
struct fut_state_0 resolve_or_reject__e__lambda0(struct ctx* ctx, struct resolve_or_reject__e__lambda0* _closure) {
	struct fut_state_0 old0;
	old0 = _closure->f->state;
	
	struct result_0 _0 = _closure->result;struct fut_state_0 _1;
	
	switch (_0.kind) {
		case 0: {
			struct ok_0 o1 = _0.as0;
			
			_1 = (struct fut_state_0) {2, .as2 = (struct fut_state_resolved_0) {o1.value}};
			break;
		}
		case 1: {
			struct err e2 = _0.as1;
			
			struct exception ex3;
			ex3 = e2.value;
			
			_1 = (struct fut_state_0) {3, .as3 = ex3};
			break;
		}
		default:
			
	_1 = (struct fut_state_0) {0};;
	}
	_closure->f->state = _1;
	return old0;
}
/* call-callbacks!<?a> void(cbs fut-state-callbacks<nat>, value result<nat, exception>) */
struct void_ call_callbacks__e(struct ctx* ctx, struct fut_state_callbacks_0* cbs, struct result_0 value) {
	top:;
	subscript_8(ctx, cbs->cb, value);
	struct opt_0 _0 = cbs->next;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct some_0 _matched0 = _0.as1;
			
			struct fut_state_callbacks_0* next1;
			next1 = _matched0.value;
			
			cbs = next1;
			value = value;
			goto top;
		}
		default:
			
	return (struct void_) {};;
	}
}
/* forward-to!<?out>.lambda0 void(it result<nat, exception>) */
struct void_ forward_to__e__lambda0(struct ctx* ctx, struct forward_to__e__lambda0* _closure, struct result_0 it) {
	return resolve_or_reject__e(ctx, _closure->to, it);
}
/* subscript<?out, ?in> fut<nat>(f fun-ref1<nat, void>, p0 void) */
struct fut_0* subscript_10(struct ctx* ctx, struct fun_ref1 f, struct void_ p0) {
	struct island* island0;
	island0 = get_island(ctx, f.island_and_exclusion.island);
	
	struct fut_0* res1;
	res1 = unresolved(ctx);
	
	struct subscript_10__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct subscript_10__lambda0));
	temp0 = ((struct subscript_10__lambda0*) _0);
	
	*temp0 = (struct subscript_10__lambda0) {f, p0, res1};
	add_task_0(ctx, island0, f.island_and_exclusion.exclusion, (struct fun_act0_0) {3, .as3 = temp0});
	return res1;
}
/* get-island island(island-id nat) */
struct island* get_island(struct ctx* ctx, uint64_t island_id) {
	struct global_ctx* _0 = get_global_ctx(ctx);
	return subscript_11(ctx, _0->islands, island_id);
}
/* subscript<island> island(a arr<island>, index nat) */
struct island* subscript_11(struct ctx* ctx, struct arr_3 a, uint64_t index) {
	uint8_t _0 = _less(index, a.size);
	assert(ctx, _0);
	return unsafe_at_0(a, index);
}
/* unsafe-at<?a> island(a arr<island>, index nat) */
struct island* unsafe_at_0(struct arr_3 a, uint64_t index) {
	return subscript_12(a.begin_ptr, index);
}
/* subscript<?a> island(a ptr<island>, n nat) */
struct island* subscript_12(struct island** a, uint64_t n) {
	return (*(a + n));
}
/* add-task void(a island, exclusion nat, action fun-act0<void>) */
struct void_ add_task_0(struct ctx* ctx, struct island* a, uint64_t exclusion, struct fun_act0_0 action) {
	uint64_t _0 = no_timestamp();
	return add_task_1(ctx, a, _0, exclusion, action);
}
/* add-task void(a island, timestamp nat, exclusion nat, action fun-act0<void>) */
struct void_ add_task_1(struct ctx* ctx, struct island* a, uint64_t timestamp, uint64_t exclusion, struct fun_act0_0 action) {
	struct task_queue_node* node0;
	node0 = task_queue_node(ctx, (struct task) {timestamp, exclusion, action});
	
	acquire__e((&a->tasks_lock));
	struct task_queue* _0 = tasks(a);
	insert_task__e(_0, node0);
	release__e((&a->tasks_lock));
	return broadcast__e((&a->gctx->may_be_work_to_do));
}
/* task-queue-node task-queue-node(task task) */
struct task_queue_node* task_queue_node(struct ctx* ctx, struct task task) {
	struct task_queue_node* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct task_queue_node));
	temp0 = ((struct task_queue_node*) _0);
	
	*temp0 = (struct task_queue_node) {task, (struct opt_2) {0, .as0 = (struct none) {}}};
	return temp0;
}
/* insert-task! void(a task-queue, inserted task-queue-node) */
struct void_ insert_task__e(struct task_queue* a, struct task_queue_node* inserted) {
	uint64_t size_before0;
	size_before0 = size_1(a);
	
	struct opt_2 _0 = a->head;
	switch (_0.kind) {
		case 0: {
			a->head = (struct opt_2) {1, .as1 = (struct some_2) {inserted}};
			break;
		}
		case 1: {
			struct some_2 _matched1 = _0.as1;
			
			struct task_queue_node* head2;
			head2 = _matched1.value;
			
			uint8_t _1 = _lessOrEqual(head2->task.time, inserted->task.time);
			if (_1) {
				insert_recur(head2, inserted);
			} else {
				inserted->next = (struct opt_2) {1, .as1 = (struct some_2) {head2}};
				a->head = (struct opt_2) {1, .as1 = (struct some_2) {inserted}};
			}
			break;
		}
		default:
			
	(struct void_) {};;
	}
	uint64_t size_after3;
	size_after3 = size_1(a);
	
	return hard_assert(((size_before0 + 1u) == size_after3));
}
/* size nat(a task-queue) */
uint64_t size_1(struct task_queue* a) {
	return size_recur(a->head, 0u);
}
/* size-recur nat(node opt<task-queue-node>, acc nat) */
uint64_t size_recur(struct opt_2 node, uint64_t acc) {
	top:;
	struct opt_2 _0 = node;
	switch (_0.kind) {
		case 0: {
			return acc;
		}
		case 1: {
			struct some_2 _matched0 = _0.as1;
			
			struct task_queue_node* n1;
			n1 = _matched0.value;
			
			node = n1->next;
			acc = (acc + 1u);
			goto top;
		}
		default:
			
	return 0;;
	}
}
/* insert-recur void(prev task-queue-node, inserted task-queue-node) */
struct void_ insert_recur(struct task_queue_node* prev, struct task_queue_node* inserted) {
	top:;
	struct opt_2 _0 = prev->next;
	switch (_0.kind) {
		case 0: {
			return (prev->next = (struct opt_2) {1, .as1 = (struct some_2) {inserted}}, (struct void_) {});
		}
		case 1: {
			struct some_2 _matched0 = _0.as1;
			
			struct task_queue_node* cur1;
			cur1 = _matched0.value;
			
			uint8_t _1 = _lessOrEqual(cur1->task.time, inserted->task.time);
			if (_1) {
				prev = cur1;
				inserted = inserted;
				goto top;
			} else {
				inserted->next = (struct opt_2) {1, .as1 = (struct some_2) {cur1}};
				return (prev->next = (struct opt_2) {1, .as1 = (struct some_2) {inserted}}, (struct void_) {});
			}
		}
		default:
			
	return (struct void_) {};;
	}
}
/* tasks task-queue(a island) */
struct task_queue* tasks(struct island* a) {
	return (&(&a->gc_root)->tasks);
}
/* broadcast! void(a condition) */
struct void_ broadcast__e(struct condition* a) {
	int32_t _0 = pthread_mutex_lock((&a->mutex));
	hard_assert_posix_error(_0);
	int32_t _1 = pthread_cond_broadcast((&a->cond));
	hard_assert_posix_error(_1);
	a->sequence = (a->sequence + 1u);
	int32_t _2 = pthread_mutex_unlock((&a->mutex));
	return hard_assert_posix_error(_2);
}
/* no-timestamp nat() */
uint64_t no_timestamp(void) {
	return 0u;
}
/* catch<void> void(try fun-act0<void>, catcher fun-act1<void, exception>) */
struct void_ catch(struct ctx* ctx, struct fun_act0_0 try, struct fun_act1_5 catcher) {
	struct exception_ctx* _0 = get_exception_ctx(ctx);
	return catch_with_exception_ctx(ctx, _0, try, catcher);
}
/* catch-with-exception-ctx<?a> void(ec exception-ctx, try fun-act0<void>, catcher fun-act1<void, exception>) */
struct void_ catch_with_exception_ctx(struct ctx* ctx, struct exception_ctx* ec, struct fun_act0_0 try, struct fun_act1_5 catcher) {
	struct exception old_thrown_exception0;
	old_thrown_exception0 = ec->thrown_exception;
	
	struct jmp_buf_tag* old_jmp_buf1;
	old_jmp_buf1 = ec->jmp_buf_ptr;
	
	struct jmp_buf_tag store2;
	struct bytes64 _0 = zero_0();
	struct bytes128 _1 = zero_3();
	store2 = (struct jmp_buf_tag) {_0, 0, _1};
	
	ec->jmp_buf_ptr = (&store2);
	int32_t setjmp_result3;
	setjmp_result3 = setjmp(ec->jmp_buf_ptr);
	
	uint8_t _2 = (setjmp_result3 == 0);
	if (_2) {
		struct void_ res4;
		res4 = subscript_6(ctx, try);
		
		ec->jmp_buf_ptr = old_jmp_buf1;
		ec->thrown_exception = old_thrown_exception0;
		return res4;
	} else {
		int32_t _3 = number_to_throw(ctx);
		hard_assert((setjmp_result3 == _3));
		struct exception thrown_exception5;
		thrown_exception5 = ec->thrown_exception;
		
		ec->jmp_buf_ptr = old_jmp_buf1;
		ec->thrown_exception = old_thrown_exception0;
		return subscript_13(ctx, catcher, thrown_exception5);
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
	return (struct bytes16) {0u, 0u};
}
/* zero bytes128() */
struct bytes128 zero_3(void) {
	struct bytes64 _0 = zero_0();
	struct bytes64 _1 = zero_0();
	return (struct bytes128) {_0, _1};
}
/* subscript<?a, exception> void(a fun-act1<void, exception>, p0 exception) */
struct void_ subscript_13(struct ctx* ctx, struct fun_act1_5 a, struct exception p0) {
	return call_w_ctx_215(a, ctx, p0);
}
/* call-w-ctx<void, exception> (generated) (generated) */
struct void_ call_w_ctx_215(struct fun_act1_5 a, struct ctx* ctx, struct exception p0) {
	struct fun_act1_5 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct subscript_10__lambda0__lambda1* closure0 = _0.as0;
			
			return subscript_10__lambda0__lambda1(ctx, closure0, p0);
		}
		case 1: {
			struct subscript_15__lambda0__lambda1* closure1 = _0.as1;
			
			return subscript_15__lambda0__lambda1(ctx, closure1, p0);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* subscript<fut<?r>, ?p0> fut<nat>(a fun-act1<fut<nat>, void>, p0 void) */
struct fut_0* subscript_14(struct ctx* ctx, struct fun_act1_4 a, struct void_ p0) {
	return call_w_ctx_217(a, ctx, p0);
}
/* call-w-ctx<gc-ptr(fut<nat>), void> (generated) (generated) */
struct fut_0* call_w_ctx_217(struct fun_act1_4 a, struct ctx* ctx, struct void_ p0) {
	struct fun_act1_4 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct then_void__lambda0* closure0 = _0.as0;
			
			return then_void__lambda0(ctx, closure0, p0);
		}
		default:
			
	return NULL;;
	}
}
/* subscript<?out, ?in>.lambda0.lambda0 void() */
struct void_ subscript_10__lambda0__lambda0(struct ctx* ctx, struct subscript_10__lambda0__lambda0* _closure) {
	struct fut_0* _0 = subscript_14(ctx, _closure->f.fun, _closure->p0);
	return forward_to__e(ctx, _0, _closure->res);
}
/* reject!<?r> void(f fut<nat>, e exception) */
struct void_ reject__e(struct ctx* ctx, struct fut_0* f, struct exception e) {
	return resolve_or_reject__e(ctx, f, (struct result_0) {1, .as1 = (struct err) {e}});
}
/* subscript<?out, ?in>.lambda0.lambda1 void(it exception) */
struct void_ subscript_10__lambda0__lambda1(struct ctx* ctx, struct subscript_10__lambda0__lambda1* _closure, struct exception it) {
	return reject__e(ctx, _closure->res, it);
}
/* subscript<?out, ?in>.lambda0 void() */
struct void_ subscript_10__lambda0(struct ctx* ctx, struct subscript_10__lambda0* _closure) {
	struct subscript_10__lambda0__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct subscript_10__lambda0__lambda0));
	temp0 = ((struct subscript_10__lambda0__lambda0*) _0);
	
	*temp0 = (struct subscript_10__lambda0__lambda0) {_closure->f, _closure->p0, _closure->res};
	struct subscript_10__lambda0__lambda1* temp1;
	uint8_t* _1 = alloc(ctx, sizeof(struct subscript_10__lambda0__lambda1));
	temp1 = ((struct subscript_10__lambda0__lambda1*) _1);
	
	*temp1 = (struct subscript_10__lambda0__lambda1) {_closure->res};
	return catch(ctx, (struct fun_act0_0) {2, .as2 = temp0}, (struct fun_act1_5) {0, .as0 = temp1});
}
/* then<?out, void>.lambda0 void(result result<void, exception>) */
struct void_ then__lambda0(struct ctx* ctx, struct then__lambda0* _closure, struct result_1 result) {
	struct result_1 _0 = result;
	switch (_0.kind) {
		case 0: {
			struct ok_1 o0 = _0.as0;
			
			struct fut_0* _1 = subscript_10(ctx, _closure->cb, o0.value);
			return forward_to__e(ctx, _1, _closure->res);
		}
		case 1: {
			struct err e1 = _0.as1;
			
			return reject__e(ctx, _closure->res, e1.value);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* subscript<?out> fut<nat>(f fun-ref0<nat>) */
struct fut_0* subscript_15(struct ctx* ctx, struct fun_ref0 f) {
	struct fut_0* res0;
	res0 = unresolved(ctx);
	
	struct island* _0 = get_island(ctx, f.island_and_exclusion.island);
	struct subscript_15__lambda0* temp0;
	uint8_t* _1 = alloc(ctx, sizeof(struct subscript_15__lambda0));
	temp0 = ((struct subscript_15__lambda0*) _1);
	
	*temp0 = (struct subscript_15__lambda0) {f, res0};
	add_task_0(ctx, _0, f.island_and_exclusion.exclusion, (struct fun_act0_0) {5, .as5 = temp0});
	return res0;
}
/* subscript<fut<?r>> fut<nat>(a fun-act0<fut<nat>>) */
struct fut_0* subscript_16(struct ctx* ctx, struct fun_act0_1 a) {
	return call_w_ctx_225(a, ctx);
}
/* call-w-ctx<gc-ptr(fut<nat>)> (generated) (generated) */
struct fut_0* call_w_ctx_225(struct fun_act0_1 a, struct ctx* ctx) {
	struct fun_act0_1 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct add_first_task__lambda0* closure0 = _0.as0;
			
			return add_first_task__lambda0(ctx, closure0);
		}
		default:
			
	return NULL;;
	}
}
/* subscript<?out>.lambda0.lambda0 void() */
struct void_ subscript_15__lambda0__lambda0(struct ctx* ctx, struct subscript_15__lambda0__lambda0* _closure) {
	struct fut_0* _0 = subscript_16(ctx, _closure->f.fun);
	return forward_to__e(ctx, _0, _closure->res);
}
/* subscript<?out>.lambda0.lambda1 void(it exception) */
struct void_ subscript_15__lambda0__lambda1(struct ctx* ctx, struct subscript_15__lambda0__lambda1* _closure, struct exception it) {
	return reject__e(ctx, _closure->res, it);
}
/* subscript<?out>.lambda0 void() */
struct void_ subscript_15__lambda0(struct ctx* ctx, struct subscript_15__lambda0* _closure) {
	struct subscript_15__lambda0__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct subscript_15__lambda0__lambda0));
	temp0 = ((struct subscript_15__lambda0__lambda0*) _0);
	
	*temp0 = (struct subscript_15__lambda0__lambda0) {_closure->f, _closure->res};
	struct subscript_15__lambda0__lambda1* temp1;
	uint8_t* _1 = alloc(ctx, sizeof(struct subscript_15__lambda0__lambda1));
	temp1 = ((struct subscript_15__lambda0__lambda1*) _1);
	
	*temp1 = (struct subscript_15__lambda0__lambda1) {_closure->res};
	return catch(ctx, (struct fun_act0_0) {4, .as4 = temp0}, (struct fun_act1_5) {1, .as1 = temp1});
}
/* then-void<nat>.lambda0 fut<nat>(ignore void) */
struct fut_0* then_void__lambda0(struct ctx* ctx, struct then_void__lambda0* _closure, struct void_ ignore) {
	return subscript_15(ctx, _closure->cb);
}
/* cur-island-and-exclusion island-and-exclusion() */
struct island_and_exclusion cur_island_and_exclusion(struct ctx* ctx) {
	struct ctx* c0;
	c0 = ctx;
	
	return (struct island_and_exclusion) {c0->island_id, c0->exclusion};
}
/* delay fut<void>() */
struct fut_1* delay(struct ctx* ctx) {
	return resolved_0(ctx, (struct void_) {});
}
/* resolved<void> fut<void>(value void) */
struct fut_1* resolved_0(struct ctx* ctx, struct void_ value) {
	struct fut_1* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct fut_1));
	temp0 = ((struct fut_1*) _0);
	
	struct lock _1 = lock_by_val();
	*temp0 = (struct fut_1) {_1, (struct fut_state_1) {2, .as2 = (struct fut_state_resolved_1) {value}}};
	return temp0;
}
/* tail<ptr<char>> arr<ptr<char>>(a arr<ptr<char>>) */
struct arr_5 tail(struct ctx* ctx, struct arr_5 a) {
	uint8_t _0 = empty__q_2(a);
	forbid(ctx, _0);
	struct arrow _1 = _arrow(ctx, 1u, a.size);
	return subscript_17(ctx, a, _1);
}
/* empty?<?a> bool(a arr<ptr<char>>) */
uint8_t empty__q_2(struct arr_5 a) {
	return (a.size == 0u);
}
/* subscript<?a> arr<ptr<char>>(a arr<ptr<char>>, range arrow<nat, nat>) */
struct arr_5 subscript_17(struct ctx* ctx, struct arr_5 a, struct arrow range) {
	uint8_t _0 = _lessOrEqual(range.from, range.to);
	assert(ctx, _0);
	uint8_t _1 = _lessOrEqual(range.to, a.size);
	assert(ctx, _1);
	return (struct arr_5) {(range.to - range.from), (a.begin_ptr + range.from)};
}
/* map<str, ptr<char>> arr<str>(a arr<ptr<char>>, f fun-act1<str, ptr<char>>) */
struct arr_1 map(struct ctx* ctx, struct arr_5 a, struct fun_act1_6 f) {
	struct map__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct map__lambda0));
	temp0 = ((struct map__lambda0*) _0);
	
	*temp0 = (struct map__lambda0) {f, a};
	return make_arr(ctx, a.size, (struct fun_act1_7) {0, .as0 = temp0});
}
/* make-arr<?out> arr<str>(size nat, f fun-act1<str, nat>) */
struct arr_1 make_arr(struct ctx* ctx, uint64_t size, struct fun_act1_7 f) {
	struct str* res0;
	res0 = alloc_uninitialized_1(ctx, size);
	
	fill_ptr_range(ctx, res0, size, f);
	return (struct arr_1) {size, res0};
}
/* alloc-uninitialized<?a> ptr<str>(size nat) */
struct str* alloc_uninitialized_1(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(struct str)));
	return ((struct str*) _0);
}
/* fill-ptr-range<?a> void(begin ptr<str>, size nat, f fun-act1<str, nat>) */
struct void_ fill_ptr_range(struct ctx* ctx, struct str* begin, uint64_t size, struct fun_act1_7 f) {
	return fill_ptr_range_recur(ctx, begin, 0u, size, f);
}
/* fill-ptr-range-recur<?a> void(begin ptr<str>, i nat, size nat, f fun-act1<str, nat>) */
struct void_ fill_ptr_range_recur(struct ctx* ctx, struct str* begin, uint64_t i, uint64_t size, struct fun_act1_7 f) {
	top:;
	uint8_t _0 = _notEqual_1(i, size);
	if (_0) {
		struct str _1 = subscript_18(ctx, f, i);
		set_subscript_1(begin, i, _1);
		begin = begin;
		i = (i + 1u);
		size = size;
		f = f;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* subscript<?a, nat> str(a fun-act1<str, nat>, p0 nat) */
struct str subscript_18(struct ctx* ctx, struct fun_act1_7 a, uint64_t p0) {
	return call_w_ctx_242(a, ctx, p0);
}
/* call-w-ctx<str, nat-64> (generated) (generated) */
struct str call_w_ctx_242(struct fun_act1_7 a, struct ctx* ctx, uint64_t p0) {
	struct fun_act1_7 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct map__lambda0* closure0 = _0.as0;
			
			return map__lambda0(ctx, closure0, p0);
		}
		default:
			
	return (struct str) {(struct arr_0) {0, NULL}};;
	}
}
/* subscript<?out, ?in> str(a fun-act1<str, ptr<char>>, p0 ptr<char>) */
struct str subscript_19(struct ctx* ctx, struct fun_act1_6 a, char* p0) {
	return call_w_ctx_244(a, ctx, p0);
}
/* call-w-ctx<str, raw-ptr(char)> (generated) (generated) */
struct str call_w_ctx_244(struct fun_act1_6 a, struct ctx* ctx, char* p0) {
	struct fun_act1_6 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return add_first_task__lambda0__lambda0(ctx, closure0, p0);
		}
		default:
			
	return (struct str) {(struct arr_0) {0, NULL}};;
	}
}
/* subscript<?in> ptr<char>(a arr<ptr<char>>, index nat) */
char* subscript_20(struct ctx* ctx, struct arr_5 a, uint64_t index) {
	uint8_t _0 = _less(index, a.size);
	assert(ctx, _0);
	return unsafe_at_1(a, index);
}
/* unsafe-at<?a> ptr<char>(a arr<ptr<char>>, index nat) */
char* unsafe_at_1(struct arr_5 a, uint64_t index) {
	return subscript_21(a.begin_ptr, index);
}
/* subscript<?a> ptr<char>(a ptr<ptr<char>>, n nat) */
char* subscript_21(char** a, uint64_t n) {
	return (*(a + n));
}
/* map<str, ptr<char>>.lambda0 str(i nat) */
struct str map__lambda0(struct ctx* ctx, struct map__lambda0* _closure, uint64_t i) {
	char* _0 = subscript_20(ctx, _closure->a, i);
	return subscript_19(ctx, _closure->f, _0);
}
/* to-str str(a ptr<char>) */
struct str to_str_2(char* a) {
	char* _0 = find_cstr_end(a);
	struct arr_0 _1 = arr_from_begin_end(a, _0);
	return (struct str) {_1};
}
/* arr-from-begin-end<char> arr<char>(begin ptr<char>, end ptr<char>) */
struct arr_0 arr_from_begin_end(char* begin, char* end) {
	uint8_t _0 = ptr_less_eq__q_2(begin, end);
	hard_assert(_0);
	uint64_t _1 = _minus_2(end, begin);
	return (struct arr_0) {_1, begin};
}
/* ptr-less-eq?<?a> bool(a ptr<char>, b ptr<char>) */
uint8_t ptr_less_eq__q_2(char* a, char* b) {
	if ((a < b)) {
		return 1;
	} else {
		return (a == b);
	}
}
/* -<?a> nat(a ptr<char>, b ptr<char>) */
uint64_t _minus_2(char* a, char* b) {
	return ((((uint64_t) a) - ((uint64_t) b)) / sizeof(char));
}
/* find-cstr-end ptr<char>(a ptr<char>) */
char* find_cstr_end(char* a) {
	struct opt_8 _0 = find_char_in_cstr(a, 0u);
	switch (_0.kind) {
		case 0: {
			return hard_unreachable_1();
		}
		case 1: {
			struct some_8 _matched0 = _0.as1;
			
			char* v1;
			v1 = _matched0.value;
			
			return v1;
		}
		default:
			
	return NULL;;
	}
}
/* find-char-in-cstr opt<ptr<char>>(a ptr<char>, c char) */
struct opt_8 find_char_in_cstr(char* a, char c) {
	top:;
	uint8_t _0 = _equal((*a), c);
	if (_0) {
		return (struct opt_8) {1, .as1 = (struct some_8) {a}};
	} else {
		uint8_t _1 = _equal((*a), 0u);
		if (_1) {
			return (struct opt_8) {0, .as0 = (struct none) {}};
		} else {
			a = (a + 1u);
			c = c;
			goto top;
		}
	}
}
/* == bool(a char, b char) */
uint8_t _equal(char a, char b) {
	return (((uint64_t) a) == ((uint64_t) b));
}
/* hard-unreachable<ptr<char>> ptr<char>() */
char* hard_unreachable_1(void) {
	(abort(), (struct void_) {});
	return NULL;
}
/* add-first-task.lambda0.lambda0 str(it ptr<char>) */
struct str add_first_task__lambda0__lambda0(struct ctx* ctx, struct void_ _closure, char* it) {
	return to_str_2(it);
}
/* add-first-task.lambda0 fut<nat>() */
struct fut_0* add_first_task__lambda0(struct ctx* ctx, struct add_first_task__lambda0* _closure) {
	struct arr_5 args0;
	args0 = tail(ctx, _closure->all_args);
	
	struct arr_1 _0 = map(ctx, args0, (struct fun_act1_6) {0, .as0 = (struct void_) {}});
	return _closure->main_ptr(ctx, _0);
}
/* handle-exceptions<nat> void(a fut<nat>) */
struct void_ handle_exceptions(struct ctx* ctx, struct fut_0* a) {
	return callback__e_1(ctx, a, (struct fun_act1_0) {1, .as1 = (struct void_) {}});
}
/* subscript<void, exception> void(a fun1<void, exception>, p0 exception) */
struct void_ subscript_22(struct ctx* ctx, struct fun1_0 a, struct exception p0) {
	return call_w_ctx_261(a, ctx, p0);
}
/* call-w-ctx<void, exception> (generated) (generated) */
struct void_ call_w_ctx_261(struct fun1_0 a, struct ctx* ctx, struct exception p0) {
	struct fun1_0 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return island__lambda0(ctx, closure0, p0);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* exception-handler fun1<void, exception>(a island) */
struct fun1_0 exception_handler(struct ctx* ctx, struct island* a) {
	return (&a->gc_root)->exception_handler;
}
/* get-cur-island island() */
struct island* get_cur_island(struct ctx* ctx) {
	return get_island(ctx, ctx->island_id);
}
/* handle-exceptions<nat>.lambda0 void(result result<nat, exception>) */
struct void_ handle_exceptions__lambda0(struct ctx* ctx, struct void_ _closure, struct result_0 result) {
	struct result_0 _0 = result;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct err e0 = _0.as1;
			
			struct island* _1 = get_cur_island(ctx);
			struct fun1_0 _2 = exception_handler(ctx, _1);
			return subscript_22(ctx, _2, e0.value);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* add-main-task.lambda0 fut<nat>(all-args arr<ptr<char>>, main-ptr fun-ptr2<fut<nat>, ctx, arr<str>>) */
struct fut_0* add_main_task__lambda0(struct ctx* ctx, struct void_ _closure, struct arr_5 all_args, fun_ptr2 main_ptr) {
	return add_first_task(ctx, all_args, main_ptr);
}
/* call-w-ctx<gc-ptr(fut<nat>), arr<ptr<char>>, some fun ptr type> (generated) (generated) */
struct fut_0* call_w_ctx_266(struct fun_act2 a, struct ctx* ctx, struct arr_5 p0, fun_ptr2 p1) {
	struct fun_act2 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return add_main_task__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return NULL;;
	}
}
/* run-threads void(n-threads nat, gctx global-ctx) */
struct void_ run_threads(uint64_t n_threads, struct global_ctx* gctx) {
	uint64_t* threads0;
	threads0 = unmanaged_alloc_elements_0(n_threads);
	
	struct thread_args* thread_args1;
	thread_args1 = unmanaged_alloc_elements_1(n_threads);
	
	uint64_t actual_n_threads2;
	actual_n_threads2 = (n_threads - 1u);
	
	start_threads_recur(0u, actual_n_threads2, threads0, thread_args1, gctx);
	thread_function(actual_n_threads2, gctx);
	join_threads_recur(0u, actual_n_threads2, threads0);
	unmanaged_free_0(threads0);
	return unmanaged_free_1(thread_args1);
}
/* unmanaged-alloc-elements<by-val<thread-args>> ptr<thread-args>(size-elements nat) */
struct thread_args* unmanaged_alloc_elements_1(uint64_t size_elements) {
	uint8_t* _0 = unmanaged_alloc_bytes((size_elements * sizeof(struct thread_args)));
	return ((struct thread_args*) _0);
}
/* start-threads-recur void(i nat, n-threads nat, threads ptr<nat>, thread-args-begin ptr<thread-args>, gctx global-ctx) */
struct void_ start_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads, struct thread_args* thread_args_begin, struct global_ctx* gctx) {
	top:;
	uint8_t _0 = _notEqual_1(i, n_threads);
	if (_0) {
		struct thread_args* thread_arg_ptr0;
		thread_arg_ptr0 = (thread_args_begin + i);
		
		*thread_arg_ptr0 = (struct thread_args) {i, gctx};
		uint64_t* thread_ptr1;
		thread_ptr1 = (threads + i);
		
		struct cell_0* _1 = as_cell(thread_ptr1);
		create_one_thread(_1, ((uint8_t*) thread_arg_ptr0), thread_fun);
		i = (i + 1u);
		n_threads = n_threads;
		threads = threads;
		thread_args_begin = thread_args_begin;
		gctx = gctx;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* create-one-thread void(tid cell<nat>, thread-arg ptr<nat8>, thread-fun fun-ptr1<ptr<nat8>, ptr<nat8>>) */
struct void_ create_one_thread(struct cell_0* tid, uint8_t* thread_arg, fun_ptr1 thread_fun) {
	int32_t err0;
	err0 = pthread_create(tid, NULL, thread_fun, thread_arg);
	
	uint8_t _0 = _notEqual_2(err0, 0);
	if (_0) {
		int32_t _1 = eagain();
		uint8_t _2 = (err0 == _1);
		if (_2) {
			return todo_0();
		} else {
			return todo_0();
		}
	} else {
		return (struct void_) {};
	}
}
/* !=<int32> bool(a int32, b int32) */
uint8_t _notEqual_2(int32_t a, int32_t b) {
	return not((a == b));
}
/* eagain int32() */
int32_t eagain(void) {
	return 11;
}
/* as-cell<nat> cell<nat>(p ptr<nat>) */
struct cell_0* as_cell(uint64_t* p) {
	return ((struct cell_0*) ((uint8_t*) p));
}
/* thread-fun ptr<nat8>(args-ptr ptr<nat8>) */
uint8_t* thread_fun(uint8_t* args_ptr) {
	struct thread_args* args0;
	args0 = ((struct thread_args*) args_ptr);
	
	thread_function(args0->thread_id, args0->gctx);
	return NULL;
}
/* thread-function void(thread-id nat, gctx global-ctx) */
struct void_ thread_function(uint64_t thread_id, struct global_ctx* gctx) {
	struct exception_ctx ectx0;
	ectx0 = exception_ctx();
	
	struct log_ctx log_ctx1;
	log_ctx1 = log_ctx();
	
	struct perf_ctx perf_ctx2;
	perf_ctx2 = perf_ctx();
	
	struct lock* print_lock3;
	print_lock3 = (&gctx->print_lock);
	
	uint8_t* ectx_ptr4;
	ectx_ptr4 = ((uint8_t*) (&ectx0));
	
	uint8_t* log_ctx_ptr5;
	log_ctx_ptr5 = ((uint8_t*) (&log_ctx1));
	
	uint8_t* perf_ptr6;
	perf_ptr6 = ((uint8_t*) (&perf_ctx2));
	
	struct thread_local_stuff tls7;
	tls7 = (struct thread_local_stuff) {thread_id, print_lock3, ectx_ptr4, log_ctx_ptr5, perf_ptr6};
	
	return thread_function_recur(gctx, (&tls7));
}
/* thread-function-recur void(gctx global-ctx, tls thread-local-stuff) */
struct void_ thread_function_recur(struct global_ctx* gctx, struct thread_local_stuff* tls) {
	top:;
	uint8_t _0 = gctx->shut_down__q;
	if (_0) {
		acquire__e((&gctx->lk));
		gctx->n_live_threads = (gctx->n_live_threads - 1u);
		assert_islands_are_shut_down(0u, gctx->islands);
		return release__e((&gctx->lk));
	} else {
		uint8_t _1 = _greater(gctx->n_live_threads, 0u);
		hard_assert(_1);
		uint64_t last_checked0;
		last_checked0 = get_sequence((&gctx->may_be_work_to_do));
		
		struct choose_task_result _2 = choose_task(gctx);
		switch (_2.kind) {
			case 0: {
				struct chosen_task t1 = _2.as0;
				
				do_task(gctx, tls, t1);
				break;
			}
			case 1: {
				struct no_chosen_task n2 = _2.as1;
				
				uint8_t _3 = n2.no_tasks_and_last_thread_out__q;
				if (_3) {
					hard_forbid(gctx->shut_down__q);
					gctx->shut_down__q = 1;
					broadcast__e((&gctx->may_be_work_to_do));
				} else {
					wait_on((&gctx->may_be_work_to_do), n2.first_task_time, last_checked0);
				}
				acquire__e((&gctx->lk));
				gctx->n_live_threads = (gctx->n_live_threads + 1u);
				release__e((&gctx->lk));
				break;
			}
			default:
				
		(struct void_) {};;
		}
		gctx = gctx;
		tls = tls;
		goto top;
	}
}
/* assert-islands-are-shut-down void(i nat, islands arr<island>) */
struct void_ assert_islands_are_shut_down(uint64_t i, struct arr_3 islands) {
	top:;
	uint8_t _0 = _notEqual_1(i, islands.size);
	if (_0) {
		struct island* island0;
		island0 = noctx_at_0(islands, i);
		
		acquire__e((&island0->tasks_lock));
		hard_forbid((&island0->gc)->needs_gc__q);
		hard_assert((island0->n_threads_running == 0u));
		struct task_queue* _1 = tasks(island0);
		uint8_t _2 = empty__q_3(_1);
		hard_assert(_2);
		release__e((&island0->tasks_lock));
		i = (i + 1u);
		islands = islands;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* noctx-at<island> island(a arr<island>, index nat) */
struct island* noctx_at_0(struct arr_3 a, uint64_t index) {
	uint8_t _0 = _less(index, a.size);
	hard_assert(_0);
	return unsafe_at_0(a, index);
}
/* empty? bool(a task-queue) */
uint8_t empty__q_3(struct task_queue* a) {
	return empty__q_4(a->head);
}
/* empty?<task-queue-node> bool(a opt<task-queue-node>) */
uint8_t empty__q_4(struct opt_2 a) {
	struct opt_2 _0 = a;
	switch (_0.kind) {
		case 0: {
			return 1;
		}
		case 1: {
			return 0;
		}
		default:
			
	return 0;;
	}
}
/* get-sequence nat(a condition) */
uint64_t get_sequence(struct condition* a) {
	int32_t _0 = pthread_mutex_lock((&a->mutex));
	hard_assert_posix_error(_0);
	uint64_t res0;
	res0 = a->sequence;
	
	int32_t _1 = pthread_mutex_unlock((&a->mutex));
	hard_assert_posix_error(_1);
	return res0;
}
/* choose-task choose-task-result(gctx global-ctx) */
struct choose_task_result choose_task(struct global_ctx* gctx) {
	acquire__e((&gctx->lk));
	uint64_t cur_time0;
	cur_time0 = get_monotime_nsec();
	
	struct choose_task_result res4;
	struct choose_task_result _0 = choose_task_recur(gctx->islands, 0u, cur_time0, 0, (struct opt_9) {0, .as0 = (struct none) {}});
	switch (_0.kind) {
		case 0: {
			struct chosen_task c1 = _0.as0;
			
			res4 = (struct choose_task_result) {0, .as0 = c1};
			break;
		}
		case 1: {
			struct no_chosen_task n2 = _0.as1;
			
			gctx->n_live_threads = (gctx->n_live_threads - 1u);
			uint8_t no_task_and_last_thread_out__q3;
			if (n2.no_tasks_and_last_thread_out__q) {
				no_task_and_last_thread_out__q3 = (gctx->n_live_threads == 0u);
			} else {
				no_task_and_last_thread_out__q3 = 0;
			}
			
			res4 = (struct choose_task_result) {1, .as1 = (struct no_chosen_task) {no_task_and_last_thread_out__q3, n2.first_task_time}};
			break;
		}
		default:
			
	res4 = (struct choose_task_result) {0};;
	}
	
	release__e((&gctx->lk));
	return res4;
}
/* get-monotime-nsec nat() */
uint64_t get_monotime_nsec(void) {
	struct cell_1 time_cell0;
	time_cell0 = (struct cell_1) {(struct timespec) {0, 0}};
	
	int32_t err1;
	int32_t _0 = clock_monotonic();
	err1 = clock_gettime(_0, (&time_cell0));
	
	uint8_t _1 = (err1 == 0);
	if (_1) {
		struct timespec time2;
		time2 = (&time_cell0)->subscript;
		
		return ((uint64_t) ((time2.tv_sec * 1000000000) + time2.tv_nsec));
	} else {
		return todo_2();
	}
}
/* todo<nat> nat() */
uint64_t todo_2(void) {
	(abort(), (struct void_) {});
	return 0;
}
/* choose-task-recur choose-task-result(islands arr<island>, i nat, cur-time nat, any-tasks? bool, first-task-time opt<nat>) */
struct choose_task_result choose_task_recur(struct arr_3 islands, uint64_t i, uint64_t cur_time, uint8_t any_tasks__q, struct opt_9 first_task_time) {
	top:;
	uint8_t _0 = (i == islands.size);
	if (_0) {
		uint8_t _1 = not(any_tasks__q);
		return (struct choose_task_result) {1, .as1 = (struct no_chosen_task) {_1, first_task_time}};
	} else {
		struct island* island0;
		island0 = noctx_at_0(islands, i);
		
		struct choose_task_in_island_result _2 = choose_task_in_island(island0, cur_time);
		switch (_2.kind) {
			case 0: {
				struct task t1 = _2.as0;
				
				return (struct choose_task_result) {0, .as0 = (struct chosen_task) {island0, (struct task_or_gc) {0, .as0 = t1}}};
			}
			case 1: {
				struct do_a_gc g2 = _2.as1;
				
				return (struct choose_task_result) {0, .as0 = (struct chosen_task) {island0, (struct task_or_gc) {1, .as1 = g2}}};
			}
			case 2: {
				struct no_task n3 = _2.as2;
				
				uint8_t new_any_tasks__q4;
				if (any_tasks__q) {
					new_any_tasks__q4 = 1;
				} else {
					new_any_tasks__q4 = n3.any_tasks__q;
				}
				
				struct opt_9 new_first_task_time5;
				new_first_task_time5 = min_time(first_task_time, n3.first_task_time);
				
				islands = islands;
				i = (i + 1u);
				cur_time = cur_time;
				any_tasks__q = new_any_tasks__q4;
				first_task_time = new_first_task_time5;
				goto top;
			}
			default:
				
		return (struct choose_task_result) {0};;
		}
	}
}
/* choose-task-in-island choose-task-in-island-result(island island, cur-time nat) */
struct choose_task_in_island_result choose_task_in_island(struct island* island, uint64_t cur_time) {
	acquire__e((&island->tasks_lock));
	struct choose_task_in_island_result res2;
	uint8_t _0 = (&island->gc)->needs_gc__q;
	if (_0) {
		uint8_t _1 = (island->n_threads_running == 0u);
		if (_1) {
			res2 = (struct choose_task_in_island_result) {1, .as1 = (struct do_a_gc) {}};
		} else {
			res2 = (struct choose_task_in_island_result) {2, .as2 = (struct no_task) {1, (struct opt_9) {0, .as0 = (struct none) {}}}};
		}
	} else {
		struct task_queue* _2 = tasks(island);
		struct pop_task_result _3 = pop_task__e(_2, cur_time);
		switch (_3.kind) {
			case 0: {
				struct task t0 = _3.as0;
				
				res2 = (struct choose_task_in_island_result) {0, .as0 = t0};
				break;
			}
			case 1: {
				struct no_task n1 = _3.as1;
				
				res2 = (struct choose_task_in_island_result) {2, .as2 = n1};
				break;
			}
			default:
				
		res2 = (struct choose_task_in_island_result) {0};;
		}
	}
	
	uint8_t _4 = is_no_task__q(res2);
	uint8_t _5 = not(_4);
	if (_5) {
		island->n_threads_running = (island->n_threads_running + 1u);
	} else {
		(struct void_) {};
	}
	release__e((&island->tasks_lock));
	return res2;
}
/* pop-task! pop-task-result(a task-queue, cur-time nat) */
struct pop_task_result pop_task__e(struct task_queue* a, uint64_t cur_time) {
	struct mut_list_0* exclusions0;
	exclusions0 = (&a->currently_running_exclusions);
	
	struct pop_task_result res4;
	struct opt_2 _0 = a->head;
	switch (_0.kind) {
		case 0: {
			res4 = (struct pop_task_result) {1, .as1 = (struct no_task) {0, (struct opt_9) {0, .as0 = (struct none) {}}}};
			break;
		}
		case 1: {
			struct some_2 _matched1 = _0.as1;
			
			struct task_queue_node* head2;
			head2 = _matched1.value;
			
			struct task task3;
			task3 = head2->task;
			
			uint8_t _1 = _lessOrEqual(task3.time, cur_time);
			if (_1) {
				uint8_t _2 = contains__q_0(exclusions0, task3.exclusion);
				if (_2) {
					struct opt_9 _3 = to_opt_time(task3.time);
					res4 = pop_recur__e(head2, exclusions0, cur_time, _3);
				} else {
					a->head = head2->next;
					res4 = (struct pop_task_result) {0, .as0 = head2->task};
				}
			} else {
				res4 = (struct pop_task_result) {1, .as1 = (struct no_task) {1, (struct opt_9) {1, .as1 = (struct some_9) {task3.time}}}};
			}
			break;
		}
		default:
			
	res4 = (struct pop_task_result) {0};;
	}
	
	struct pop_task_result _4 = res4;
	switch (_4.kind) {
		case 0: {
			struct task t5 = _4.as0;
			
			push_capacity_must_be_sufficient__e(exclusions0, t5.exclusion);
			break;
		}
		case 1: {
			(struct void_) {};
			break;
		}
		default:
			
	(struct void_) {};;
	}
	return res4;
}
/* contains?<nat> bool(a mut-list<nat>, value nat) */
uint8_t contains__q_0(struct mut_list_0* a, uint64_t value) {
	struct arr_2 _0 = temp_as_arr_0(a);
	return contains__q_1(_0, value);
}
/* contains?<?a> bool(a arr<nat>, value nat) */
uint8_t contains__q_1(struct arr_2 a, uint64_t value) {
	return contains_recur__q(a, value, 0u);
}
/* contains-recur?<?a> bool(a arr<nat>, value nat, i nat) */
uint8_t contains_recur__q(struct arr_2 a, uint64_t value, uint64_t i) {
	top:;
	uint8_t _0 = (i == a.size);
	if (_0) {
		return 0;
	} else {
		uint64_t _1 = noctx_at_1(a, i);
		uint8_t _2 = (_1 == value);
		if (_2) {
			return 1;
		} else {
			a = a;
			value = value;
			i = (i + 1u);
			goto top;
		}
	}
}
/* noctx-at<?a> nat(a arr<nat>, index nat) */
uint64_t noctx_at_1(struct arr_2 a, uint64_t index) {
	uint8_t _0 = _less(index, a.size);
	hard_assert(_0);
	return unsafe_at_2(a, index);
}
/* unsafe-at<?a> nat(a arr<nat>, index nat) */
uint64_t unsafe_at_2(struct arr_2 a, uint64_t index) {
	return subscript_23(a.begin_ptr, index);
}
/* subscript<?a> nat(a ptr<nat>, n nat) */
uint64_t subscript_23(uint64_t* a, uint64_t n) {
	return (*(a + n));
}
/* temp-as-arr<?a> arr<nat>(a mut-list<nat>) */
struct arr_2 temp_as_arr_0(struct mut_list_0* a) {
	struct mut_arr_0 _0 = temp_as_mut_arr(a);
	return temp_as_arr_1(_0);
}
/* temp-as-arr<?a> arr<nat>(a mut-arr<nat>) */
struct arr_2 temp_as_arr_1(struct mut_arr_0 a) {
	return a.inner;
}
/* temp-as-mut-arr<?a> mut-arr<nat>(a mut-list<nat>) */
struct mut_arr_0 temp_as_mut_arr(struct mut_list_0* a) {
	uint64_t* _0 = begin_ptr_2(a);
	return mut_arr_0(a->size, _0);
}
/* begin-ptr<?a> ptr<nat>(a mut-list<nat>) */
uint64_t* begin_ptr_2(struct mut_list_0* a) {
	return begin_ptr_3(a->backing);
}
/* begin-ptr<?a> ptr<nat>(a mut-arr<nat>) */
uint64_t* begin_ptr_3(struct mut_arr_0 a) {
	return a.inner.begin_ptr;
}
/* pop-recur! pop-task-result(prev task-queue-node, exclusions mut-list<nat>, cur-time nat, first-task-time opt<nat>) */
struct pop_task_result pop_recur__e(struct task_queue_node* prev, struct mut_list_0* exclusions, uint64_t cur_time, struct opt_9 first_task_time) {
	top:;
	struct opt_2 _0 = prev->next;
	switch (_0.kind) {
		case 0: {
			return (struct pop_task_result) {1, .as1 = (struct no_task) {1, first_task_time}};
		}
		case 1: {
			struct some_2 _matched0 = _0.as1;
			
			struct task_queue_node* cur1;
			cur1 = _matched0.value;
			
			struct task task2;
			task2 = cur1->task;
			
			uint8_t _1 = _lessOrEqual(task2.time, cur_time);
			if (_1) {
				uint8_t _2 = contains__q_0(exclusions, task2.exclusion);
				if (_2) {
					struct opt_9 _3 = first_task_time;struct opt_9 _4;
					
					switch (_3.kind) {
						case 0: {
							_4 = to_opt_time(task2.time);
							break;
						}
						case 1: {
							struct some_9 _matched3 = _3.as1;
							
							uint64_t t4;
							t4 = _matched3.value;
							
							_4 = (struct opt_9) {1, .as1 = (struct some_9) {t4}};
							break;
						}
						default:
							
					_4 = (struct opt_9) {0};;
					}
					prev = cur1;
					exclusions = exclusions;
					cur_time = cur_time;
					first_task_time = _4;
					goto top;
				} else {
					prev->next = cur1->next;
					return (struct pop_task_result) {0, .as0 = task2};
				}
			} else {
				return (struct pop_task_result) {1, .as1 = (struct no_task) {1, (struct opt_9) {1, .as1 = (struct some_9) {task2.time}}}};
			}
		}
		default:
			
	return (struct pop_task_result) {0};;
	}
}
/* to-opt-time opt<nat>(a nat) */
struct opt_9 to_opt_time(uint64_t a) {
	uint64_t _0 = no_timestamp();
	uint8_t _1 = (a == _0);
	if (_1) {
		return (struct opt_9) {0, .as0 = (struct none) {}};
	} else {
		return (struct opt_9) {1, .as1 = (struct some_9) {a}};
	}
}
/* push-capacity-must-be-sufficient!<nat> void(a mut-list<nat>, value nat) */
struct void_ push_capacity_must_be_sufficient__e(struct mut_list_0* a, uint64_t value) {
	uint64_t _0 = capacity_1(a);
	uint8_t _1 = _less(a->size, _0);
	hard_assert(_1);
	uint64_t* _2 = begin_ptr_2(a);
	set_subscript_3(_2, a->size, value);
	return (a->size = (a->size + 1u), (struct void_) {});
}
/* capacity<?a> nat(a mut-list<nat>) */
uint64_t capacity_1(struct mut_list_0* a) {
	return size_2(a->backing);
}
/* size<?a> nat(a mut-arr<nat>) */
uint64_t size_2(struct mut_arr_0 a) {
	return a.inner.size;
}
/* set-subscript<?a> void(a ptr<nat>, n nat, value nat) */
struct void_ set_subscript_3(uint64_t* a, uint64_t n, uint64_t value) {
	return (*(a + n) = value, (struct void_) {});
}
/* is-no-task? bool(a choose-task-in-island-result) */
uint8_t is_no_task__q(struct choose_task_in_island_result a) {
	struct choose_task_in_island_result _0 = a;
	switch (_0.kind) {
		case 0: {
			return 0;
		}
		case 1: {
			return 0;
		}
		case 2: {
			return 1;
		}
		default:
			
	return 0;;
	}
}
/* min-time opt<nat>(a opt<nat>, b opt<nat>) */
struct opt_9 min_time(struct opt_9 a, struct opt_9 b) {
	struct opt_9 _0 = a;
	switch (_0.kind) {
		case 0: {
			return b;
		}
		case 1: {
			struct some_9 _matched0 = _0.as1;
			
			uint64_t ta1;
			ta1 = _matched0.value;
			
			struct opt_9 _1 = b;
			switch (_1.kind) {
				case 0: {
					return (struct opt_9) {0, .as0 = (struct none) {}};
				}
				case 1: {
					struct some_9 _matched2 = _1.as1;
					
					uint64_t tb3;
					tb3 = _matched2.value;
					
					uint64_t _2 = min(ta1, tb3);
					return (struct opt_9) {1, .as1 = (struct some_9) {_2}};
				}
				default:
					
			return (struct opt_9) {0};;
			}
		}
		default:
			
	return (struct opt_9) {0};;
	}
}
/* min<nat> nat(a nat, b nat) */
uint64_t min(uint64_t a, uint64_t b) {
	uint8_t _0 = _less(a, b);
	if (_0) {
		return a;
	} else {
		return b;
	}
}
/* do-task void(gctx global-ctx, tls thread-local-stuff, chosen-task chosen-task) */
struct void_ do_task(struct global_ctx* gctx, struct thread_local_stuff* tls, struct chosen_task chosen_task) {
	struct island* island0;
	island0 = chosen_task.task_island;
	
	struct task_or_gc _0 = chosen_task.task_or_gc;
	switch (_0.kind) {
		case 0: {
			struct task task1 = _0.as0;
			
			struct ctx ctx2;
			ctx2 = ctx(gctx, tls, island0, task1.exclusion);
			
			call_w_ctx_173(task1.action, (&ctx2));
			acquire__e((&island0->tasks_lock));
			struct task_queue* _1 = tasks(island0);
			return_task__e(_1, task1);
			release__e((&island0->tasks_lock));
			return_ctx((&ctx2));
			break;
		}
		case 1: {
			run_garbage_collection((&island0->gc), island0->gc_root);
			broadcast__e((&gctx->may_be_work_to_do));
			break;
		}
		default:
			
	(struct void_) {};;
	}
	acquire__e((&island0->tasks_lock));
	island0->n_threads_running = (island0->n_threads_running - 1u);
	return release__e((&island0->tasks_lock));
}
/* return-task! void(a task-queue, task task) */
struct void_ return_task__e(struct task_queue* a, struct task task) {
	return noctx_must_remove_unordered__e((&a->currently_running_exclusions), task.exclusion);
}
/* noctx-must-remove-unordered!<nat> void(a mut-list<nat>, value nat) */
struct void_ noctx_must_remove_unordered__e(struct mut_list_0* a, uint64_t value) {
	return noctx_must_remove_unordered_recur__e(a, 0u, value);
}
/* noctx-must-remove-unordered-recur!<?a> void(a mut-list<nat>, index nat, value nat) */
struct void_ noctx_must_remove_unordered_recur__e(struct mut_list_0* a, uint64_t index, uint64_t value) {
	top:;
	uint8_t _0 = (index == a->size);
	if (_0) {
		return todo_0();
	} else {
		uint64_t* _1 = begin_ptr_2(a);
		uint64_t _2 = subscript_23(_1, index);
		uint8_t _3 = (_2 == value);
		if (_3) {
			uint64_t _4 = noctx_remove_unordered_at__e(a, index);
			return drop(_4);
		} else {
			a = a;
			index = (index + 1u);
			value = value;
			goto top;
		}
	}
}
/* drop<?a> void(_ nat) */
struct void_ drop(uint64_t _p0) {
	return (struct void_) {};
}
/* noctx-remove-unordered-at!<?a> nat(a mut-list<nat>, index nat) */
uint64_t noctx_remove_unordered_at__e(struct mut_list_0* a, uint64_t index) {
	uint8_t _0 = _less(index, a->size);
	hard_assert(_0);
	uint64_t res0;
	uint64_t* _1 = begin_ptr_2(a);
	res0 = subscript_23(_1, index);
	
	uint64_t new_size1;
	new_size1 = (a->size - 1u);
	
	uint64_t* _2 = begin_ptr_2(a);
	uint64_t* _3 = begin_ptr_2(a);
	uint64_t _4 = subscript_23(_3, new_size1);
	set_subscript_3(_2, index, _4);
	a->size = new_size1;
	return res0;
}
/* return-ctx void(c ctx) */
struct void_ return_ctx(struct ctx* c) {
	return return_gc_ctx(((struct gc_ctx*) c->gc_ctx_ptr));
}
/* return-gc-ctx void(gc-ctx gc-ctx) */
struct void_ return_gc_ctx(struct gc_ctx* gc_ctx) {
	struct gc* gc0;
	gc0 = gc_ctx->gc;
	
	acquire__e((&gc0->lk));
	gc_ctx->next_ctx = gc0->context_head;
	gc0->context_head = (struct opt_1) {1, .as1 = (struct some_1) {gc_ctx}};
	return release__e((&gc0->lk));
}
/* run-garbage-collection<by-val<island-gc-root>> void(gc gc, gc-root island-gc-root) */
struct void_ run_garbage_collection(struct gc* gc, struct island_gc_root gc_root) {
	hard_assert(gc->needs_gc__q);
	gc->gc_count = (gc->gc_count + 1u);
	(memset(((uint8_t*) gc->mark_begin), 0u, gc->size_words), (struct void_) {});
	struct mark_ctx mark_ctx0;
	mark_ctx0 = (struct mark_ctx) {gc->size_words, gc->mark_begin, gc->data_begin};
	
	mark_visit_319((&mark_ctx0), gc_root);
	gc->mark_cur = gc->mark_begin;
	gc->data_cur = gc->data_begin;
	clear_free_mem(gc->mark_begin, gc->mark_end, gc->data_begin);
	validate_gc(gc);
	return (gc->needs_gc__q = 0, (struct void_) {});
}
/* mark-visit<island-gc-root> (generated) (generated) */
struct void_ mark_visit_319(struct mark_ctx* mark_ctx, struct island_gc_root value) {
	return mark_visit_320(mark_ctx, value.tasks);
}
/* mark-visit<task-queue> (generated) (generated) */
struct void_ mark_visit_320(struct mark_ctx* mark_ctx, struct task_queue value) {
	mark_visit_321(mark_ctx, value.head);
	return mark_visit_374(mark_ctx, value.currently_running_exclusions);
}
/* mark-visit<opt<task-queue-node>> (generated) (generated) */
struct void_ mark_visit_321(struct mark_ctx* mark_ctx, struct opt_2 value) {
	struct opt_2 _0 = value;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct some_2 value1 = _0.as1;
			
			return mark_visit_322(mark_ctx, value1);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* mark-visit<some<task-queue-node>> (generated) (generated) */
struct void_ mark_visit_322(struct mark_ctx* mark_ctx, struct some_2 value) {
	return mark_visit_373(mark_ctx, value.value);
}
/* mark-visit<task-queue-node> (generated) (generated) */
struct void_ mark_visit_323(struct mark_ctx* mark_ctx, struct task_queue_node value) {
	mark_visit_324(mark_ctx, value.task);
	return mark_visit_321(mark_ctx, value.next);
}
/* mark-visit<task> (generated) (generated) */
struct void_ mark_visit_324(struct mark_ctx* mark_ctx, struct task value) {
	return mark_visit_325(mark_ctx, value.action);
}
/* mark-visit<fun-act0<void>> (generated) (generated) */
struct void_ mark_visit_325(struct mark_ctx* mark_ctx, struct fun_act0_0 value) {
	struct fun_act0_0 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct callback__e_0__lambda0* value0 = _0.as0;
			
			return mark_visit_362(mark_ctx, value0);
		}
		case 1: {
			struct callback__e_1__lambda0* value1 = _0.as1;
			
			return mark_visit_364(mark_ctx, value1);
		}
		case 2: {
			struct subscript_10__lambda0__lambda0* value2 = _0.as2;
			
			return mark_visit_366(mark_ctx, value2);
		}
		case 3: {
			struct subscript_10__lambda0* value3 = _0.as3;
			
			return mark_visit_368(mark_ctx, value3);
		}
		case 4: {
			struct subscript_15__lambda0__lambda0* value4 = _0.as4;
			
			return mark_visit_370(mark_ctx, value4);
		}
		case 5: {
			struct subscript_15__lambda0* value5 = _0.as5;
			
			return mark_visit_372(mark_ctx, value5);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* mark-visit<callback!<?in>.lambda0> (generated) (generated) */
struct void_ mark_visit_326(struct mark_ctx* mark_ctx, struct callback__e_0__lambda0 value) {
	mark_visit_361(mark_ctx, value.f);
	return mark_visit_330(mark_ctx, value.cb);
}
/* mark-visit<fut<void>> (generated) (generated) */
struct void_ mark_visit_327(struct mark_ctx* mark_ctx, struct fut_1 value) {
	return mark_visit_328(mark_ctx, value.state);
}
/* mark-visit<fut-state<void>> (generated) (generated) */
struct void_ mark_visit_328(struct mark_ctx* mark_ctx, struct fut_state_1 value) {
	struct fut_state_1 _0 = value;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct fut_state_callbacks_1* value1 = _0.as1;
			
			return mark_visit_360(mark_ctx, value1);
		}
		case 2: {
			return (struct void_) {};
		}
		case 3: {
			struct exception value3 = _0.as3;
			
			return mark_visit_351(mark_ctx, value3);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* mark-visit<fut-state-callbacks<void>> (generated) (generated) */
struct void_ mark_visit_329(struct mark_ctx* mark_ctx, struct fut_state_callbacks_1 value) {
	mark_visit_330(mark_ctx, value.cb);
	return mark_visit_358(mark_ctx, value.next);
}
/* mark-visit<fun-act1<void, result<void, exception>>> (generated) (generated) */
struct void_ mark_visit_330(struct mark_ctx* mark_ctx, struct fun_act1_3 value) {
	struct fun_act1_3 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct then__lambda0* value0 = _0.as0;
			
			return mark_visit_357(mark_ctx, value0);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* mark-visit<then<?out, void>.lambda0> (generated) (generated) */
struct void_ mark_visit_331(struct mark_ctx* mark_ctx, struct then__lambda0 value) {
	mark_visit_332(mark_ctx, value.cb);
	return mark_visit_346(mark_ctx, value.res);
}
/* mark-visit<fun-ref1<nat, void>> (generated) (generated) */
struct void_ mark_visit_332(struct mark_ctx* mark_ctx, struct fun_ref1 value) {
	return mark_visit_333(mark_ctx, value.fun);
}
/* mark-visit<fun-act1<fut<nat>, void>> (generated) (generated) */
struct void_ mark_visit_333(struct mark_ctx* mark_ctx, struct fun_act1_4 value) {
	struct fun_act1_4 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct then_void__lambda0* value0 = _0.as0;
			
			return mark_visit_340(mark_ctx, value0);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* mark-visit<then-void<nat>.lambda0> (generated) (generated) */
struct void_ mark_visit_334(struct mark_ctx* mark_ctx, struct then_void__lambda0 value) {
	return mark_visit_335(mark_ctx, value.cb);
}
/* mark-visit<fun-ref0<nat>> (generated) (generated) */
struct void_ mark_visit_335(struct mark_ctx* mark_ctx, struct fun_ref0 value) {
	return mark_visit_336(mark_ctx, value.fun);
}
/* mark-visit<fun-act0<fut<nat>>> (generated) (generated) */
struct void_ mark_visit_336(struct mark_ctx* mark_ctx, struct fun_act0_1 value) {
	struct fun_act0_1 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct add_first_task__lambda0* value0 = _0.as0;
			
			return mark_visit_339(mark_ctx, value0);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* mark-visit<add-first-task.lambda0> (generated) (generated) */
struct void_ mark_visit_337(struct mark_ctx* mark_ctx, struct add_first_task__lambda0 value) {
	return mark_arr_338(mark_ctx, value.all_args);
}
/* mark-arr<raw-ptr(char)> (generated) (generated) */
struct void_ mark_arr_338(struct mark_ctx* mark_ctx, struct arr_5 a) {
	uint8_t dropped0;
	dropped0 = mark(mark_ctx, ((uint8_t*) a.begin_ptr), (a.size * sizeof(char*)));
	
	return (struct void_) {};
}
/* mark-visit<gc-ptr(add-first-task.lambda0)> (generated) (generated) */
struct void_ mark_visit_339(struct mark_ctx* mark_ctx, struct add_first_task__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct add_first_task__lambda0));
	if (_0) {
		return mark_visit_337(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(then-void<nat>.lambda0)> (generated) (generated) */
struct void_ mark_visit_340(struct mark_ctx* mark_ctx, struct then_void__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct then_void__lambda0));
	if (_0) {
		return mark_visit_334(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<fut<nat>> (generated) (generated) */
struct void_ mark_visit_341(struct mark_ctx* mark_ctx, struct fut_0 value) {
	return mark_visit_342(mark_ctx, value.state);
}
/* mark-visit<fut-state<nat>> (generated) (generated) */
struct void_ mark_visit_342(struct mark_ctx* mark_ctx, struct fut_state_0 value) {
	struct fut_state_0 _0 = value;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct fut_state_callbacks_0* value1 = _0.as1;
			
			return mark_visit_350(mark_ctx, value1);
		}
		case 2: {
			return (struct void_) {};
		}
		case 3: {
			struct exception value3 = _0.as3;
			
			return mark_visit_351(mark_ctx, value3);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* mark-visit<fut-state-callbacks<nat>> (generated) (generated) */
struct void_ mark_visit_343(struct mark_ctx* mark_ctx, struct fut_state_callbacks_0 value) {
	mark_visit_344(mark_ctx, value.cb);
	return mark_visit_348(mark_ctx, value.next);
}
/* mark-visit<fun-act1<void, result<nat, exception>>> (generated) (generated) */
struct void_ mark_visit_344(struct mark_ctx* mark_ctx, struct fun_act1_0 value) {
	struct fun_act1_0 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct forward_to__e__lambda0* value0 = _0.as0;
			
			return mark_visit_347(mark_ctx, value0);
		}
		case 1: {
			return (struct void_) {};
		}
		default:
			
	return (struct void_) {};;
	}
}
/* mark-visit<forward-to!<?out>.lambda0> (generated) (generated) */
struct void_ mark_visit_345(struct mark_ctx* mark_ctx, struct forward_to__e__lambda0 value) {
	return mark_visit_346(mark_ctx, value.to);
}
/* mark-visit<gc-ptr(fut<nat>)> (generated) (generated) */
struct void_ mark_visit_346(struct mark_ctx* mark_ctx, struct fut_0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct fut_0));
	if (_0) {
		return mark_visit_341(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(forward-to!<?out>.lambda0)> (generated) (generated) */
struct void_ mark_visit_347(struct mark_ctx* mark_ctx, struct forward_to__e__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct forward_to__e__lambda0));
	if (_0) {
		return mark_visit_345(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<opt<fut-state-callbacks<nat>>> (generated) (generated) */
struct void_ mark_visit_348(struct mark_ctx* mark_ctx, struct opt_0 value) {
	struct opt_0 _0 = value;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct some_0 value1 = _0.as1;
			
			return mark_visit_349(mark_ctx, value1);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* mark-visit<some<fut-state-callbacks<nat>>> (generated) (generated) */
struct void_ mark_visit_349(struct mark_ctx* mark_ctx, struct some_0 value) {
	return mark_visit_350(mark_ctx, value.value);
}
/* mark-visit<gc-ptr(fut-state-callbacks<nat>)> (generated) (generated) */
struct void_ mark_visit_350(struct mark_ctx* mark_ctx, struct fut_state_callbacks_0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct fut_state_callbacks_0));
	if (_0) {
		return mark_visit_343(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<exception> (generated) (generated) */
struct void_ mark_visit_351(struct mark_ctx* mark_ctx, struct exception value) {
	mark_visit_352(mark_ctx, value.message);
	return mark_visit_354(mark_ctx, value.backtrace);
}
/* mark-visit<str> (generated) (generated) */
struct void_ mark_visit_352(struct mark_ctx* mark_ctx, struct str value) {
	return mark_arr_353(mark_ctx, value.chars);
}
/* mark-arr<char> (generated) (generated) */
struct void_ mark_arr_353(struct mark_ctx* mark_ctx, struct arr_0 a) {
	uint8_t dropped0;
	dropped0 = mark(mark_ctx, ((uint8_t*) a.begin_ptr), (a.size * sizeof(char)));
	
	return (struct void_) {};
}
/* mark-visit<backtrace> (generated) (generated) */
struct void_ mark_visit_354(struct mark_ctx* mark_ctx, struct backtrace value) {
	return mark_arr_356(mark_ctx, value.return_stack);
}
/* mark-elems<str> (generated) (generated) */
struct void_ mark_elems_355(struct mark_ctx* mark_ctx, struct str* cur, struct str* end) {
	top:;
	uint8_t _0 = (cur == end);
	if (_0) {
		return (struct void_) {};
	} else {
		mark_visit_352(mark_ctx, (*cur));
		mark_ctx = mark_ctx;
		cur = (cur + 1u);
		end = end;
		goto top;
	}
}
/* mark-arr<str> (generated) (generated) */
struct void_ mark_arr_356(struct mark_ctx* mark_ctx, struct arr_1 a) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) a.begin_ptr), (a.size * sizeof(struct str)));
	if (_0) {
		return mark_elems_355(mark_ctx, a.begin_ptr, (a.begin_ptr + a.size));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(then<?out, void>.lambda0)> (generated) (generated) */
struct void_ mark_visit_357(struct mark_ctx* mark_ctx, struct then__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct then__lambda0));
	if (_0) {
		return mark_visit_331(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<opt<fut-state-callbacks<void>>> (generated) (generated) */
struct void_ mark_visit_358(struct mark_ctx* mark_ctx, struct opt_7 value) {
	struct opt_7 _0 = value;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct some_7 value1 = _0.as1;
			
			return mark_visit_359(mark_ctx, value1);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* mark-visit<some<fut-state-callbacks<void>>> (generated) (generated) */
struct void_ mark_visit_359(struct mark_ctx* mark_ctx, struct some_7 value) {
	return mark_visit_360(mark_ctx, value.value);
}
/* mark-visit<gc-ptr(fut-state-callbacks<void>)> (generated) (generated) */
struct void_ mark_visit_360(struct mark_ctx* mark_ctx, struct fut_state_callbacks_1* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct fut_state_callbacks_1));
	if (_0) {
		return mark_visit_329(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(fut<void>)> (generated) (generated) */
struct void_ mark_visit_361(struct mark_ctx* mark_ctx, struct fut_1* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct fut_1));
	if (_0) {
		return mark_visit_327(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(callback!<?in>.lambda0)> (generated) (generated) */
struct void_ mark_visit_362(struct mark_ctx* mark_ctx, struct callback__e_0__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct callback__e_0__lambda0));
	if (_0) {
		return mark_visit_326(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<callback!<?a>.lambda0> (generated) (generated) */
struct void_ mark_visit_363(struct mark_ctx* mark_ctx, struct callback__e_1__lambda0 value) {
	mark_visit_346(mark_ctx, value.f);
	return mark_visit_344(mark_ctx, value.cb);
}
/* mark-visit<gc-ptr(callback!<?a>.lambda0)> (generated) (generated) */
struct void_ mark_visit_364(struct mark_ctx* mark_ctx, struct callback__e_1__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct callback__e_1__lambda0));
	if (_0) {
		return mark_visit_363(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<subscript<?out, ?in>.lambda0.lambda0> (generated) (generated) */
struct void_ mark_visit_365(struct mark_ctx* mark_ctx, struct subscript_10__lambda0__lambda0 value) {
	mark_visit_332(mark_ctx, value.f);
	return mark_visit_346(mark_ctx, value.res);
}
/* mark-visit<gc-ptr(subscript<?out, ?in>.lambda0.lambda0)> (generated) (generated) */
struct void_ mark_visit_366(struct mark_ctx* mark_ctx, struct subscript_10__lambda0__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct subscript_10__lambda0__lambda0));
	if (_0) {
		return mark_visit_365(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<subscript<?out, ?in>.lambda0> (generated) (generated) */
struct void_ mark_visit_367(struct mark_ctx* mark_ctx, struct subscript_10__lambda0 value) {
	mark_visit_332(mark_ctx, value.f);
	return mark_visit_346(mark_ctx, value.res);
}
/* mark-visit<gc-ptr(subscript<?out, ?in>.lambda0)> (generated) (generated) */
struct void_ mark_visit_368(struct mark_ctx* mark_ctx, struct subscript_10__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct subscript_10__lambda0));
	if (_0) {
		return mark_visit_367(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<subscript<?out>.lambda0.lambda0> (generated) (generated) */
struct void_ mark_visit_369(struct mark_ctx* mark_ctx, struct subscript_15__lambda0__lambda0 value) {
	mark_visit_335(mark_ctx, value.f);
	return mark_visit_346(mark_ctx, value.res);
}
/* mark-visit<gc-ptr(subscript<?out>.lambda0.lambda0)> (generated) (generated) */
struct void_ mark_visit_370(struct mark_ctx* mark_ctx, struct subscript_15__lambda0__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct subscript_15__lambda0__lambda0));
	if (_0) {
		return mark_visit_369(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<subscript<?out>.lambda0> (generated) (generated) */
struct void_ mark_visit_371(struct mark_ctx* mark_ctx, struct subscript_15__lambda0 value) {
	mark_visit_335(mark_ctx, value.f);
	return mark_visit_346(mark_ctx, value.res);
}
/* mark-visit<gc-ptr(subscript<?out>.lambda0)> (generated) (generated) */
struct void_ mark_visit_372(struct mark_ctx* mark_ctx, struct subscript_15__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct subscript_15__lambda0));
	if (_0) {
		return mark_visit_371(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(task-queue-node)> (generated) (generated) */
struct void_ mark_visit_373(struct mark_ctx* mark_ctx, struct task_queue_node* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct task_queue_node));
	if (_0) {
		return mark_visit_323(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<mut-list<nat>> (generated) (generated) */
struct void_ mark_visit_374(struct mark_ctx* mark_ctx, struct mut_list_0 value) {
	return mark_visit_375(mark_ctx, value.backing);
}
/* mark-visit<mut-arr<nat>> (generated) (generated) */
struct void_ mark_visit_375(struct mark_ctx* mark_ctx, struct mut_arr_0 value) {
	return mark_arr_376(mark_ctx, value.inner);
}
/* mark-arr<nat-64> (generated) (generated) */
struct void_ mark_arr_376(struct mark_ctx* mark_ctx, struct arr_2 a) {
	uint8_t dropped0;
	dropped0 = mark(mark_ctx, ((uint8_t*) a.begin_ptr), (a.size * sizeof(uint64_t)));
	
	return (struct void_) {};
}
/* clear-free-mem void(mark-ptr ptr<bool>, mark-end ptr<bool>, data-ptr ptr<nat>) */
struct void_ clear_free_mem(uint8_t* mark_ptr, uint8_t* mark_end, uint64_t* data_ptr) {
	top:;
	uint8_t _0 = not((mark_ptr == mark_end));
	if (_0) {
		uint8_t _1 = not((*mark_ptr));
		if (_1) {
			*data_ptr = 18077161789910350558u;
		} else {
			(struct void_) {};
		}
		mark_ptr = (mark_ptr + 1u);
		mark_end = mark_end;
		data_ptr = data_ptr;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* wait-on void(a condition, until-time opt<nat>, last-sequence nat) */
struct void_ wait_on(struct condition* a, struct opt_9 until_time, uint64_t last_sequence) {
	int32_t _0 = pthread_mutex_lock((&a->mutex));
	hard_assert_posix_error(_0);
	uint8_t _1 = (a->sequence == last_sequence);
	if (_1) {
		struct opt_9 _2 = until_time;int32_t _3;
		
		switch (_2.kind) {
			case 0: {
				_3 = pthread_cond_wait((&a->cond), (&a->mutex));
				break;
			}
			case 1: {
				struct some_9 _matched0 = _2.as1;
				
				uint64_t t1;
				t1 = _matched0.value;
				
				struct timespec abstime2;
				abstime2 = to_timespec(t1);
				
				int32_t err3;
				err3 = pthread_cond_timedwait((&a->cond), (&a->mutex), (&abstime2));
				
				int32_t _4 = etimedout();
				uint8_t _5 = (err3 == _4);
				if (_5) {
					_3 = 0;
				} else {
					_3 = err3;
				}
				break;
			}
			default:
				
		_3 = 0;;
		}
		hard_assert_posix_error(_3);
	} else {
		(struct void_) {};
	}
	int32_t _6 = pthread_mutex_unlock((&a->mutex));
	return hard_assert_posix_error(_6);
}
/* to-timespec timespec(a nat) */
struct timespec to_timespec(uint64_t a) {
	int64_t seconds0;
	seconds0 = ((int64_t) (a / 1000000000u));
	
	int64_t ns1;
	ns1 = ((int64_t) (a % 1000000000u));
	
	return (struct timespec) {seconds0, ns1};
}
/* etimedout int32() */
int32_t etimedout(void) {
	return 110;
}
/* join-threads-recur void(i nat, n-threads nat, threads ptr<nat>) */
struct void_ join_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads) {
	top:;
	uint8_t _0 = _notEqual_1(i, n_threads);
	if (_0) {
		uint64_t _1 = subscript_23(threads, i);
		join_one_thread(_1);
		i = (i + 1u);
		n_threads = n_threads;
		threads = threads;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* join-one-thread void(tid nat) */
struct void_ join_one_thread(uint64_t tid) {
	struct cell_2 thread_return0;
	thread_return0 = (struct cell_2) {NULL};
	
	int32_t err1;
	err1 = pthread_join(tid, (&thread_return0));
	
	uint8_t _0 = _notEqual_2(err1, 0);
	if (_0) {
		int32_t _1 = einval();
		uint8_t _2 = (err1 == _1);
		if (_2) {
			todo_0();
		} else {
			int32_t _3 = esrch();
			uint8_t _4 = (err1 == _3);
			if (_4) {
				todo_0();
			} else {
				todo_0();
			}
		}
	} else {
		(struct void_) {};
	}
	uint8_t _5 = null__q_0((&thread_return0)->subscript);
	return hard_assert(_5);
}
/* einval int32() */
int32_t einval(void) {
	return 22;
}
/* esrch int32() */
int32_t esrch(void) {
	return 3;
}
/* unmanaged-free<nat> void(p ptr<nat>) */
struct void_ unmanaged_free_0(uint64_t* p) {
	return (free(((uint8_t*) p)), (struct void_) {});
}
/* unmanaged-free<by-val<thread-args>> void(p ptr<thread-args>) */
struct void_ unmanaged_free_1(struct thread_args* p) {
	return (free(((uint8_t*) p)), (struct void_) {});
}
/* destroy-condition void(a condition) */
struct void_ destroy_condition(struct condition* a) {
	int32_t _0 = pthread_mutexattr_destroy((&a->mutex_attr));
	hard_assert_posix_error(_0);
	int32_t _1 = pthread_mutex_destroy((&a->mutex));
	hard_assert_posix_error(_1);
	int32_t _2 = pthread_condattr_destroy((&a->cond_attr));
	hard_assert_posix_error(_2);
	int32_t _3 = pthread_cond_destroy((&a->cond));
	return hard_assert_posix_error(_3);
}
/* main fut<nat>(_ arr<str>) */
struct fut_0* main_0(struct ctx* ctx, struct arr_1 _p0) {
	print((struct str) {{13, constantarr_0_11}});
	return resolved_1(ctx, 0u);
}
/* resolved<nat> fut<nat>(value nat) */
struct fut_0* resolved_1(struct ctx* ctx, uint64_t value) {
	struct fut_0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct fut_0));
	temp0 = ((struct fut_0*) _0);
	
	struct lock _1 = lock_by_val();
	*temp0 = (struct fut_0) {_1, (struct fut_state_0) {2, .as2 = (struct fut_state_resolved_0) {value}}};
	return temp0;
}
/* main (generated) (generated) */
int32_t main(int32_t argc, char** argv) {
	return rt_main(argc, argv, main_0);
}
