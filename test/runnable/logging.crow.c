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
struct fut_0;
struct fut_state_callbacks_0;
struct exception;
struct str;
struct arr_0 {
	uint64_t size;
	char* begin_ptr;
};
struct backtrace;
struct sym {
	char* to_c_str;
};
struct arr_1 {
	uint64_t size;
	struct sym* begin_ptr;
};
struct arr_2 {
	uint64_t size;
	struct str* begin_ptr;
};
struct global_ctx;
struct dynamic_sym_node;
struct island;
struct gc;
struct gc_ctx;
struct island_gc_root;
struct task_queue;
struct task_queue_node;
struct task;
struct mut_arr_0;
struct fix_arr_0;
struct arr_3 {
	uint64_t size;
	uint64_t* begin_ptr;
};
struct logged;
struct thread_safe_counter;
struct arr_4 {
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
struct mut_arr_1;
struct fix_arr_1 {
	struct void_ ignore;
	struct arr_0 inner;
};
struct _concatEquals_1__lambda0 {
	struct mut_arr_1* a;
};
struct exception_ctx;
struct __jmp_buf_tag;
struct bytes64;
struct bytes128;
struct backtrace_arrs;
struct named_val {
	struct sym name;
	uint8_t* val;
};
struct arr_5 {
	uint64_t size;
	struct named_val* begin_ptr;
};
struct range {
	struct void_ ignore;
	uint64_t low;
	uint64_t high;
};
struct to_str_0__lambda0;
struct log_ctx;
struct perf_ctx;
struct measure_value {
	uint64_t count;
	uint64_t total_ns;
};
struct fix_arr_2;
struct arr_6 {
	uint64_t size;
	struct measure_value* begin_ptr;
};
struct arr_7 {
	uint64_t size;
	char** begin_ptr;
};
struct fut_1;
struct fut_state_callbacks_1;
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
struct thread_args {
	uint64_t thread_id;
	struct global_ctx* gctx;
};
struct cell_0 {
	uint64_t inner_value;
};
struct chosen_task;
struct no_chosen_task;
struct timespec {
	int64_t tv_sec;
	int64_t tv_nsec;
};
struct cell_1 {
	struct timespec inner_value;
};
struct no_task;
struct cell_2 {
	uint8_t* inner_value;
};
struct main_0__lambda0;
struct with_log_handler__lambda0;
struct with_log_handler__lambda1;
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
		struct void_ as0;
		struct fut_state_callbacks_0* as1;
	};
};
struct opt_1 {
	uint64_t kind;
	union {
		struct void_ as0;
		struct dynamic_sym_node* as1;
	};
};
struct opt_2 {
	uint64_t kind;
	union {
		struct void_ as0;
		struct gc_ctx* as1;
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
		struct with_log_handler__lambda0* as6;
		struct void_ as7;
		struct void_ as8;
	};
};
struct opt_3 {
	uint64_t kind;
	union {
		struct void_ as0;
		struct task_queue_node* as1;
	};
};
struct fun1_0 {
	uint64_t kind;
	union {
		struct void_ as0;
		uint64_t __ensureSizeIs16;
	};
};
struct fun1_1 {
	uint64_t kind;
	union {
		struct void_ as0;
		struct main_0__lambda0* as1;
		struct void_ as2;
	};
};
struct fun_act1_1 {
	uint64_t kind;
	union {
		struct _concatEquals_1__lambda0* as0;
	};
};
struct opt_4 {
	uint64_t kind;
	union {
		struct void_ as0;
		struct backtrace_arrs* as1;
	};
};
struct opt_5 {
	uint64_t kind;
	union {
		struct void_ as0;
		uint8_t** as1;
	};
};
struct opt_6 {
	uint64_t kind;
	union {
		struct void_ as0;
		uint8_t* as1;
	};
};
struct opt_7 {
	uint64_t kind;
	union {
		struct void_ as0;
		struct sym* as1;
	};
};
struct opt_8 {
	uint64_t kind;
	union {
		struct void_ as0;
		struct named_val* as1;
	};
};
struct fun_act1_2 {
	uint64_t kind;
	union {
		struct to_str_0__lambda0* as0;
	};
};
struct opt_9 {
	uint64_t kind;
	union {
		struct void_ as0;
		char* as1;
	};
};
struct fun_act2 {
	uint64_t kind;
	union {
		struct void_ as0;
		uint64_t __ensureSizeIs16;
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
struct opt_10 {
	uint64_t kind;
	union {
		struct void_ as0;
		struct fut_state_callbacks_1* as1;
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
		struct with_log_handler__lambda1* as2;
	};
};
struct fun_act1_6 {
	uint64_t kind;
	union {
		struct void_ as0;
		uint64_t __ensureSizeIs16;
	};
};
struct fun_act1_7 {
	uint64_t kind;
	union {
		struct map__lambda0* as0;
	};
};
struct choose_task_result;
struct task_or_gc;
struct opt_11 {
	uint64_t kind;
	union {
		struct void_ as0;
		uint64_t as1;
	};
};
struct choose_task_in_island_result;
struct pop_task_result;
typedef struct fut_0* (*fun_ptr2)(struct ctx*, struct arr_2);
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
struct global_ctx;
struct dynamic_sym_node {
	struct sym sym;
	struct opt_1 next;
};
struct island;
struct gc {
	struct lock lk;
	uint64_t gc_count;
	struct opt_2 context_head;
	uint8_t needs_gc;
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
	struct opt_2 next_ctx;
};
struct island_gc_root;
struct task_queue;
struct task_queue_node;
struct task {
	uint64_t time;
	uint64_t exclusion;
	struct fun_act0_0 action;
};
struct mut_arr_0;
struct fix_arr_0 {
	struct void_ ignore;
	struct arr_3 inner;
};
struct logged {
	uint32_t level;
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
	struct mut_arr_1* chars;
};
struct mut_arr_1 {
	struct fix_arr_1 backing;
	uint64_t size;
};
struct exception_ctx;
struct __jmp_buf_tag;
struct bytes64 {
	struct bytes32 n0;
	struct bytes32 n1;
};
struct bytes128 {
	struct bytes64 n0;
	struct bytes64 n1;
};
struct backtrace_arrs {
	uint8_t** code_ptrs;
	struct sym* code_names;
	struct named_val* funs;
};
struct to_str_0__lambda0 {
	struct writer res;
};
struct log_ctx {
	struct fun1_1 handler;
};
struct perf_ctx;
struct fix_arr_2 {
	struct void_ ignore;
	struct arr_6 inner;
};
struct fut_1;
struct fut_state_callbacks_1 {
	struct fun_act1_3 cb;
	struct opt_10 next;
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
	struct arr_7 all_args;
	fun_ptr2 main_ptr;
};
struct map__lambda0 {
	struct fun_act1_6 f;
	struct arr_7 a;
};
struct chosen_task;
struct no_chosen_task {
	uint8_t no_tasks_and_last_thread_out;
	struct opt_11 first_task_time;
};
struct no_task {
	uint8_t any_tasks;
	struct opt_11 first_task_time;
};
struct main_0__lambda0 {
	struct fun1_1 lh;
};
struct with_log_handler__lambda0 {
	struct fun1_1 handler;
	struct fun_act0_0 cb;
	struct fun1_1 original_handler;
};
struct with_log_handler__lambda1 {
	struct fun1_1 original_handler;
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
		struct void_ as1;
	};
};
struct choose_task_in_island_result {
	uint64_t kind;
	union {
		struct task as0;
		struct void_ as1;
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
struct global_ctx;
struct island;
struct island_gc_root;
struct task_queue;
struct task_queue_node {
	struct task task;
	struct opt_3 next;
};
struct mut_arr_0 {
	struct fix_arr_0 backing;
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
	struct __jmp_buf_tag* jmp_buf_ptr;
	struct exception thrown_exception;
};
struct __jmp_buf_tag {
	struct bytes64 __jmpbuf;
	int32_t __mask_was_saved;
	struct bytes128 __saved_mask;
};
struct perf_ctx {
	struct arr_2 measure_names;
	struct fix_arr_2 measure_values;
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
		struct void_ as0;
		struct fut_state_callbacks_0* as1;
		uint64_t as2;
		struct exception as3;
	};
};
struct result_0 {
	uint64_t kind;
	union {
		uint64_t as0;
		struct exception as1;
	};
};
struct fut_state_1 {
	uint64_t kind;
	union {
		struct void_ as0;
		struct fut_state_callbacks_1* as1;
		struct void_ as2;
		struct exception as3;
	};
};
struct result_1 {
	uint64_t kind;
	union {
		struct void_ as0;
		struct exception as1;
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
	struct opt_3 head;
	struct mut_arr_0 currently_running_exclusions;
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
	struct lock syms_lock;
	struct opt_1 dynamic_syms;
	struct arr_4 islands;
	uint64_t n_live_threads;
	struct condition may_be_work_to_do;
	uint8_t is_shut_down;
	uint8_t any_unhandled_exceptions;
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
_Static_assert(_Alignof(struct ctx) == 8, "");
_Static_assert(sizeof(struct thread_local_stuff) == 40, "");
_Static_assert(_Alignof(struct thread_local_stuff) == 8, "");
_Static_assert(sizeof(struct lock) == 1, "");
_Static_assert(_Alignof(struct lock) == 1, "");
_Static_assert(sizeof(struct _atomic_bool) == 1, "");
_Static_assert(_Alignof(struct _atomic_bool) == 1, "");
_Static_assert(sizeof(struct mark_ctx) == 24, "");
_Static_assert(_Alignof(struct mark_ctx) == 8, "");
_Static_assert(sizeof(struct fut_0) == 48, "");
_Static_assert(_Alignof(struct fut_0) == 8, "");
_Static_assert(sizeof(struct fut_state_callbacks_0) == 32, "");
_Static_assert(_Alignof(struct fut_state_callbacks_0) == 8, "");
_Static_assert(sizeof(struct exception) == 32, "");
_Static_assert(_Alignof(struct exception) == 8, "");
_Static_assert(sizeof(struct str) == 16, "");
_Static_assert(_Alignof(struct str) == 8, "");
_Static_assert(sizeof(struct arr_0) == 16, "");
_Static_assert(_Alignof(struct arr_0) == 8, "");
_Static_assert(sizeof(struct backtrace) == 16, "");
_Static_assert(_Alignof(struct backtrace) == 8, "");
_Static_assert(sizeof(struct sym) == 8, "");
_Static_assert(_Alignof(struct sym) == 8, "");
_Static_assert(sizeof(struct arr_1) == 16, "");
_Static_assert(_Alignof(struct arr_1) == 8, "");
_Static_assert(sizeof(struct arr_2) == 16, "");
_Static_assert(_Alignof(struct arr_2) == 8, "");
_Static_assert(sizeof(struct global_ctx) == 168, "");
_Static_assert(_Alignof(struct global_ctx) == 8, "");
_Static_assert(sizeof(struct dynamic_sym_node) == 24, "");
_Static_assert(_Alignof(struct dynamic_sym_node) == 8, "");
_Static_assert(sizeof(struct island) == 216, "");
_Static_assert(_Alignof(struct island) == 8, "");
_Static_assert(sizeof(struct gc) == 96, "");
_Static_assert(_Alignof(struct gc) == 8, "");
_Static_assert(sizeof(struct gc_ctx) == 24, "");
_Static_assert(_Alignof(struct gc_ctx) == 8, "");
_Static_assert(sizeof(struct island_gc_root) == 72, "");
_Static_assert(_Alignof(struct island_gc_root) == 8, "");
_Static_assert(sizeof(struct task_queue) == 40, "");
_Static_assert(_Alignof(struct task_queue) == 8, "");
_Static_assert(sizeof(struct task_queue_node) == 48, "");
_Static_assert(_Alignof(struct task_queue_node) == 8, "");
_Static_assert(sizeof(struct task) == 32, "");
_Static_assert(_Alignof(struct task) == 8, "");
_Static_assert(sizeof(struct mut_arr_0) == 24, "");
_Static_assert(_Alignof(struct mut_arr_0) == 8, "");
_Static_assert(sizeof(struct fix_arr_0) == 16, "");
_Static_assert(_Alignof(struct fix_arr_0) == 8, "");
_Static_assert(sizeof(struct arr_3) == 16, "");
_Static_assert(_Alignof(struct arr_3) == 8, "");
_Static_assert(sizeof(struct logged) == 24, "");
_Static_assert(_Alignof(struct logged) == 8, "");
_Static_assert(sizeof(struct thread_safe_counter) == 16, "");
_Static_assert(_Alignof(struct thread_safe_counter) == 8, "");
_Static_assert(sizeof(struct arr_4) == 16, "");
_Static_assert(_Alignof(struct arr_4) == 8, "");
_Static_assert(sizeof(struct condition) == 112, "");
_Static_assert(_Alignof(struct condition) == 8, "");
_Static_assert(sizeof(struct pthread_mutexattr_t) == 4, "");
_Static_assert(_Alignof(struct pthread_mutexattr_t) == 4, "");
_Static_assert(sizeof(struct pthread_mutex_t) == 40, "");
_Static_assert(_Alignof(struct pthread_mutex_t) == 8, "");
_Static_assert(sizeof(struct bytes40) == 40, "");
_Static_assert(_Alignof(struct bytes40) == 8, "");
_Static_assert(sizeof(struct bytes32) == 32, "");
_Static_assert(_Alignof(struct bytes32) == 8, "");
_Static_assert(sizeof(struct bytes16) == 16, "");
_Static_assert(_Alignof(struct bytes16) == 8, "");
_Static_assert(sizeof(struct pthread_condattr_t) == 4, "");
_Static_assert(_Alignof(struct pthread_condattr_t) == 4, "");
_Static_assert(sizeof(struct pthread_cond_t) == 48, "");
_Static_assert(_Alignof(struct pthread_cond_t) == 8, "");
_Static_assert(sizeof(struct bytes48) == 48, "");
_Static_assert(_Alignof(struct bytes48) == 8, "");
_Static_assert(sizeof(struct writer) == 8, "");
_Static_assert(_Alignof(struct writer) == 8, "");
_Static_assert(sizeof(struct mut_arr_1) == 24, "");
_Static_assert(_Alignof(struct mut_arr_1) == 8, "");
_Static_assert(sizeof(struct fix_arr_1) == 16, "");
_Static_assert(_Alignof(struct fix_arr_1) == 8, "");
_Static_assert(sizeof(struct _concatEquals_1__lambda0) == 8, "");
_Static_assert(_Alignof(struct _concatEquals_1__lambda0) == 8, "");
_Static_assert(sizeof(struct exception_ctx) == 40, "");
_Static_assert(_Alignof(struct exception_ctx) == 8, "");
_Static_assert(sizeof(struct __jmp_buf_tag) == 200, "");
_Static_assert(_Alignof(struct __jmp_buf_tag) == 8, "");
_Static_assert(sizeof(struct bytes64) == 64, "");
_Static_assert(_Alignof(struct bytes64) == 8, "");
_Static_assert(sizeof(struct bytes128) == 128, "");
_Static_assert(_Alignof(struct bytes128) == 8, "");
_Static_assert(sizeof(struct backtrace_arrs) == 24, "");
_Static_assert(_Alignof(struct backtrace_arrs) == 8, "");
_Static_assert(sizeof(struct named_val) == 16, "");
_Static_assert(_Alignof(struct named_val) == 8, "");
_Static_assert(sizeof(struct arr_5) == 16, "");
_Static_assert(_Alignof(struct arr_5) == 8, "");
_Static_assert(sizeof(struct range) == 16, "");
_Static_assert(_Alignof(struct range) == 8, "");
_Static_assert(sizeof(struct to_str_0__lambda0) == 8, "");
_Static_assert(_Alignof(struct to_str_0__lambda0) == 8, "");
_Static_assert(sizeof(struct log_ctx) == 16, "");
_Static_assert(_Alignof(struct log_ctx) == 8, "");
_Static_assert(sizeof(struct perf_ctx) == 32, "");
_Static_assert(_Alignof(struct perf_ctx) == 8, "");
_Static_assert(sizeof(struct measure_value) == 16, "");
_Static_assert(_Alignof(struct measure_value) == 8, "");
_Static_assert(sizeof(struct fix_arr_2) == 16, "");
_Static_assert(_Alignof(struct fix_arr_2) == 8, "");
_Static_assert(sizeof(struct arr_6) == 16, "");
_Static_assert(_Alignof(struct arr_6) == 8, "");
_Static_assert(sizeof(struct arr_7) == 16, "");
_Static_assert(_Alignof(struct arr_7) == 8, "");
_Static_assert(sizeof(struct fut_1) == 48, "");
_Static_assert(_Alignof(struct fut_1) == 8, "");
_Static_assert(sizeof(struct fut_state_callbacks_1) == 32, "");
_Static_assert(_Alignof(struct fut_state_callbacks_1) == 8, "");
_Static_assert(sizeof(struct fun_ref0) == 32, "");
_Static_assert(_Alignof(struct fun_ref0) == 8, "");
_Static_assert(sizeof(struct island_and_exclusion) == 16, "");
_Static_assert(_Alignof(struct island_and_exclusion) == 8, "");
_Static_assert(sizeof(struct fun_ref1) == 32, "");
_Static_assert(_Alignof(struct fun_ref1) == 8, "");
_Static_assert(sizeof(struct callback__e_0__lambda0) == 24, "");
_Static_assert(_Alignof(struct callback__e_0__lambda0) == 8, "");
_Static_assert(sizeof(struct then__lambda0) == 40, "");
_Static_assert(_Alignof(struct then__lambda0) == 8, "");
_Static_assert(sizeof(struct callback__e_1__lambda0) == 24, "");
_Static_assert(_Alignof(struct callback__e_1__lambda0) == 8, "");
_Static_assert(sizeof(struct forward_to__e__lambda0) == 8, "");
_Static_assert(_Alignof(struct forward_to__e__lambda0) == 8, "");
_Static_assert(sizeof(struct resolve_or_reject__e__lambda0) == 48, "");
_Static_assert(_Alignof(struct resolve_or_reject__e__lambda0) == 8, "");
_Static_assert(sizeof(struct subscript_10__lambda0) == 40, "");
_Static_assert(_Alignof(struct subscript_10__lambda0) == 8, "");
_Static_assert(sizeof(struct subscript_10__lambda0__lambda0) == 40, "");
_Static_assert(_Alignof(struct subscript_10__lambda0__lambda0) == 8, "");
_Static_assert(sizeof(struct subscript_10__lambda0__lambda1) == 8, "");
_Static_assert(_Alignof(struct subscript_10__lambda0__lambda1) == 8, "");
_Static_assert(sizeof(struct then_void__lambda0) == 32, "");
_Static_assert(_Alignof(struct then_void__lambda0) == 8, "");
_Static_assert(sizeof(struct subscript_15__lambda0) == 40, "");
_Static_assert(_Alignof(struct subscript_15__lambda0) == 8, "");
_Static_assert(sizeof(struct subscript_15__lambda0__lambda0) == 40, "");
_Static_assert(_Alignof(struct subscript_15__lambda0__lambda0) == 8, "");
_Static_assert(sizeof(struct subscript_15__lambda0__lambda1) == 8, "");
_Static_assert(_Alignof(struct subscript_15__lambda0__lambda1) == 8, "");
_Static_assert(sizeof(struct add_first_task__lambda0) == 24, "");
_Static_assert(_Alignof(struct add_first_task__lambda0) == 8, "");
_Static_assert(sizeof(struct map__lambda0) == 32, "");
_Static_assert(_Alignof(struct map__lambda0) == 8, "");
_Static_assert(sizeof(struct thread_args) == 16, "");
_Static_assert(_Alignof(struct thread_args) == 8, "");
_Static_assert(sizeof(struct cell_0) == 8, "");
_Static_assert(_Alignof(struct cell_0) == 8, "");
_Static_assert(sizeof(struct chosen_task) == 48, "");
_Static_assert(_Alignof(struct chosen_task) == 8, "");
_Static_assert(sizeof(struct no_chosen_task) == 24, "");
_Static_assert(_Alignof(struct no_chosen_task) == 8, "");
_Static_assert(sizeof(struct timespec) == 16, "");
_Static_assert(_Alignof(struct timespec) == 8, "");
_Static_assert(sizeof(struct cell_1) == 16, "");
_Static_assert(_Alignof(struct cell_1) == 8, "");
_Static_assert(sizeof(struct no_task) == 24, "");
_Static_assert(_Alignof(struct no_task) == 8, "");
_Static_assert(sizeof(struct cell_2) == 8, "");
_Static_assert(_Alignof(struct cell_2) == 8, "");
_Static_assert(sizeof(struct main_0__lambda0) == 16, "");
_Static_assert(_Alignof(struct main_0__lambda0) == 8, "");
_Static_assert(sizeof(struct with_log_handler__lambda0) == 48, "");
_Static_assert(_Alignof(struct with_log_handler__lambda0) == 8, "");
_Static_assert(sizeof(struct with_log_handler__lambda1) == 16, "");
_Static_assert(_Alignof(struct with_log_handler__lambda1) == 8, "");
_Static_assert(sizeof(struct fut_state_0) == 40, "");
_Static_assert(_Alignof(struct fut_state_0) == 8, "");
_Static_assert(sizeof(struct result_0) == 40, "");
_Static_assert(_Alignof(struct result_0) == 8, "");
_Static_assert(sizeof(struct fun_act1_0) == 16, "");
_Static_assert(_Alignof(struct fun_act1_0) == 8, "");
_Static_assert(sizeof(struct opt_0) == 16, "");
_Static_assert(_Alignof(struct opt_0) == 8, "");
_Static_assert(sizeof(struct opt_1) == 16, "");
_Static_assert(_Alignof(struct opt_1) == 8, "");
_Static_assert(sizeof(struct opt_2) == 16, "");
_Static_assert(_Alignof(struct opt_2) == 8, "");
_Static_assert(sizeof(struct fun_act0_0) == 16, "");
_Static_assert(_Alignof(struct fun_act0_0) == 8, "");
_Static_assert(sizeof(struct opt_3) == 16, "");
_Static_assert(_Alignof(struct opt_3) == 8, "");
_Static_assert(sizeof(struct fun1_0) == 16, "");
_Static_assert(_Alignof(struct fun1_0) == 8, "");
_Static_assert(sizeof(struct fun1_1) == 16, "");
_Static_assert(_Alignof(struct fun1_1) == 8, "");
_Static_assert(sizeof(struct fun_act1_1) == 16, "");
_Static_assert(_Alignof(struct fun_act1_1) == 8, "");
_Static_assert(sizeof(struct opt_4) == 16, "");
_Static_assert(_Alignof(struct opt_4) == 8, "");
_Static_assert(sizeof(struct opt_5) == 16, "");
_Static_assert(_Alignof(struct opt_5) == 8, "");
_Static_assert(sizeof(struct opt_6) == 16, "");
_Static_assert(_Alignof(struct opt_6) == 8, "");
_Static_assert(sizeof(struct opt_7) == 16, "");
_Static_assert(_Alignof(struct opt_7) == 8, "");
_Static_assert(sizeof(struct opt_8) == 16, "");
_Static_assert(_Alignof(struct opt_8) == 8, "");
_Static_assert(sizeof(struct fun_act1_2) == 16, "");
_Static_assert(_Alignof(struct fun_act1_2) == 8, "");
_Static_assert(sizeof(struct opt_9) == 16, "");
_Static_assert(_Alignof(struct opt_9) == 8, "");
_Static_assert(sizeof(struct fun_act2) == 16, "");
_Static_assert(_Alignof(struct fun_act2) == 8, "");
_Static_assert(sizeof(struct fut_state_1) == 40, "");
_Static_assert(_Alignof(struct fut_state_1) == 8, "");
_Static_assert(sizeof(struct result_1) == 40, "");
_Static_assert(_Alignof(struct result_1) == 8, "");
_Static_assert(sizeof(struct fun_act1_3) == 16, "");
_Static_assert(_Alignof(struct fun_act1_3) == 8, "");
_Static_assert(sizeof(struct opt_10) == 16, "");
_Static_assert(_Alignof(struct opt_10) == 8, "");
_Static_assert(sizeof(struct fun_act0_1) == 16, "");
_Static_assert(_Alignof(struct fun_act0_1) == 8, "");
_Static_assert(sizeof(struct fun_act1_4) == 16, "");
_Static_assert(_Alignof(struct fun_act1_4) == 8, "");
_Static_assert(sizeof(struct fun_act0_2) == 16, "");
_Static_assert(_Alignof(struct fun_act0_2) == 8, "");
_Static_assert(sizeof(struct fun_act1_5) == 16, "");
_Static_assert(_Alignof(struct fun_act1_5) == 8, "");
_Static_assert(sizeof(struct fun_act1_6) == 16, "");
_Static_assert(_Alignof(struct fun_act1_6) == 8, "");
_Static_assert(sizeof(struct fun_act1_7) == 16, "");
_Static_assert(_Alignof(struct fun_act1_7) == 8, "");
_Static_assert(sizeof(struct choose_task_result) == 56, "");
_Static_assert(_Alignof(struct choose_task_result) == 8, "");
_Static_assert(sizeof(struct task_or_gc) == 40, "");
_Static_assert(_Alignof(struct task_or_gc) == 8, "");
_Static_assert(sizeof(struct opt_11) == 16, "");
_Static_assert(_Alignof(struct opt_11) == 8, "");
_Static_assert(sizeof(struct choose_task_in_island_result) == 40, "");
_Static_assert(_Alignof(struct choose_task_in_island_result) == 8, "");
_Static_assert(sizeof(struct pop_task_result) == 40, "");
_Static_assert(_Alignof(struct pop_task_result) == 8, "");
uint8_t mark(struct mark_ctx* ctx, uint8_t* ptr_any, uint64_t size_bytes);
struct void_ hard_assert(uint8_t condition);
extern void abort(void);
uint8_t is_word_aligned_0(uint8_t* a);
uint8_t is_word_aligned_1(uint8_t* a);
uint64_t words_of_bytes(uint64_t size_bytes);
uint64_t round_up_to_multiple_of_8(uint64_t n);
uint64_t* ptr_cast(uint8_t* a);
uint64_t _minus_0(uint64_t* a, uint64_t* b);
uint64_t _minus_1(uint64_t* a, uint64_t* b);
uint32_t _compare_0(uint64_t a, uint64_t b);
uint32_t cmp(uint64_t a, uint64_t b);
uint8_t _less_0(uint64_t a, uint64_t b);
uint8_t _lessOrEqual_0(uint64_t a, uint64_t b);
uint8_t _not(uint8_t a);
uint8_t mark_range_recur(uint8_t marked_anything, uint8_t* cur, uint8_t* end);
uint8_t _greater(uint64_t a, uint64_t b);
int32_t rt_main(int32_t argc, char** argv, fun_ptr2 main_ptr);
extern uint64_t get_nprocs(void);
struct lock lbv(void);
struct lock lock_by_val(void);
struct _atomic_bool _atomic_bool(void);
struct condition create_condition(void);
struct void_ hard_assert_posix_error(int32_t err);
extern int32_t pthread_mutexattr_init(struct pthread_mutexattr_t* attr);
extern int32_t pthread_mutex_init(struct pthread_mutex_t* mutex, struct pthread_mutexattr_t* attr);
extern int32_t pthread_condattr_init(struct pthread_condattr_t* attr);
extern int32_t pthread_condattr_setclock(struct pthread_condattr_t* attr, int32_t clock_id);
int32_t CLOCK_MONOTONIC(void);
extern int32_t pthread_cond_init(struct pthread_cond_t* cond, struct pthread_condattr_t* cond_attr);
struct island island(struct global_ctx* gctx, uint64_t id, uint64_t max_threads);
struct task_queue task_queue(uint64_t max_threads);
struct mut_arr_0 mut_arr_by_val_with_capacity_from_unmanaged_memory(uint64_t capacity);
struct fix_arr_0 fix_arr_0(uint64_t size, uint64_t* begin_ptr);
uint64_t* unmanaged_alloc_zeroed_elements(uint64_t size_elements);
uint64_t* unmanaged_alloc_elements_0(uint64_t size_elements);
uint8_t* unmanaged_alloc_bytes(uint64_t size);
extern uint8_t* malloc(uint64_t size);
uint8_t _notEqual_0(uint8_t* a, uint8_t* b);
struct void_ set_zero_range_0(uint64_t* begin, uint64_t size);
struct void_ drop_0(uint8_t* _p0);
extern uint8_t* memset(uint8_t* begin, int32_t value, uint64_t size);
struct void_ default_exception_handler(struct ctx* ctx, struct exception e);
struct void_ print_err_no_newline(struct str s);
struct void_ write_no_newline(int32_t fd, struct str a);
extern int64_t write(int32_t fd, uint8_t* buf, uint64_t n_bytes);
uint8_t* as_any_const_ptr_0(char* ref);
uint64_t size_bytes(struct str a);
uint8_t _notEqual_1(int64_t a, int64_t b);
struct void_ todo_0(void);
int32_t stderr(void);
struct void_ print_err(struct str s);
struct str to_str_0(struct ctx* ctx, struct exception a);
struct writer writer(struct ctx* ctx);
struct mut_arr_1* mut_arr(struct ctx* ctx);
struct fix_arr_1 fix_arr_1(void);
struct void_ _concatEquals_0(struct ctx* ctx, struct writer a, struct str b);
struct void_ _concatEquals_1(struct ctx* ctx, struct mut_arr_1* a, struct arr_0 values);
struct void_ each_0(struct ctx* ctx, struct arr_0 a, struct fun_act1_1 f);
struct void_ each_recur_0(struct ctx* ctx, char* cur, char* end, struct fun_act1_1 f);
uint8_t _equal_0(char* a, char* b);
uint8_t _notEqual_2(char* a, char* b);
struct void_ subscript_0(struct ctx* ctx, struct fun_act1_1 a, char p0);
struct void_ call_w_ctx_63(struct fun_act1_1 a, struct ctx* ctx, char p0);
char _times_0(char* a);
char* _plus_0(char* a, uint64_t offset);
char* end_ptr_0(struct arr_0 a);
struct void_ _concatEquals_2(struct ctx* ctx, struct mut_arr_1* a, char value);
struct void_ incr_capacity__e(struct ctx* ctx, struct mut_arr_1* a);
struct void_ ensure_capacity(struct ctx* ctx, struct mut_arr_1* a, uint64_t min_capacity);
uint64_t capacity_0(struct mut_arr_1* a);
uint64_t size_0(struct fix_arr_1 a);
struct void_ increase_capacity_to__e(struct ctx* ctx, struct mut_arr_1* a, uint64_t new_capacity);
struct void_ assert(struct ctx* ctx, uint8_t condition);
struct void_ throw_0(struct ctx* ctx, struct str message);
struct void_ throw_1(struct ctx* ctx, struct exception e);
struct exception_ctx* get_exception_ctx(struct ctx* ctx);
uint8_t _notEqual_3(struct __jmp_buf_tag* a, struct __jmp_buf_tag* b);
extern void longjmp(struct __jmp_buf_tag* env, int32_t val);
int32_t number_to_throw(struct ctx* ctx);
struct void_ hard_unreachable_0(void);
struct backtrace get_backtrace(struct ctx* ctx);
struct opt_4 try_alloc_backtrace_arrs(struct ctx* ctx);
struct opt_5 try_alloc_uninitialized_0(struct ctx* ctx, uint64_t size);
struct opt_6 try_alloc(struct ctx* ctx, uint64_t size_bytes);
struct opt_6 try_gc_alloc(struct gc* gc, uint64_t size_bytes);
struct void_ acquire__e(struct lock* a);
struct void_ acquire_recur__e(struct lock* a, uint64_t n_tries);
uint8_t try_acquire__e(struct lock* a);
uint8_t try_set__e(struct _atomic_bool* a);
uint8_t try_change__e(struct _atomic_bool* a, uint8_t old_value);
struct void_ yield_thread(void);
extern int32_t sched_yield(void);
struct opt_6 try_gc_alloc_recur(struct gc* gc, uint64_t size_bytes);
uint32_t _compare_1(uint64_t* a, uint64_t* b);
uint8_t _less_1(uint64_t* a, uint64_t* b);
uint8_t range_free(uint8_t* mark, uint8_t* end);
struct void_ maybe_set_needs_gc__e(struct gc* gc);
uint64_t _minus_2(uint8_t* a, uint8_t* b);
struct void_ release__e(struct lock* a);
struct void_ must_unset__e(struct _atomic_bool* a);
uint8_t try_unset__e(struct _atomic_bool* a);
struct gc* get_gc(struct ctx* ctx);
struct gc_ctx* get_gc_ctx_0(struct ctx* ctx);
struct opt_7 try_alloc_uninitialized_1(struct ctx* ctx, uint64_t size);
struct opt_8 try_alloc_uninitialized_2(struct ctx* ctx, uint64_t size);
extern int32_t backtrace(uint8_t** array, int32_t size);
uint64_t code_ptrs_size(struct ctx* ctx);
struct void_ copy_data_from__e_0(struct ctx* ctx, struct named_val* to, struct named_val* from, uint64_t len);
extern uint8_t* memcpy(uint8_t* dest, uint8_t* src, uint64_t size);
uint8_t* as_any_const_ptr_1(struct named_val* ref);
struct void_ sort__e(struct named_val* a, uint64_t size);
struct void_ swap__e(struct named_val* a, uint64_t lo, uint64_t hi);
struct named_val subscript_1(struct named_val* a, uint64_t n);
struct void_ set_subscript_0(struct named_val* a, uint64_t n, struct named_val value);
uint64_t partition__e(struct named_val* a, uint8_t* pivot, uint64_t l, uint64_t r);
uint8_t _equal_1(uint8_t* a, uint8_t* b);
uint32_t _compare_2(uint8_t* a, uint8_t* b);
uint32_t _compare_3(uint8_t* a, uint8_t* b);
uint8_t _less_2(uint8_t* a, uint8_t* b);
struct void_ fill_code_names__e(struct ctx* ctx, struct sym* code_names, struct sym* end_code_names, uint8_t** code_ptrs, struct named_val* funs);
uint32_t _compare_4(struct sym* a, struct sym* b);
uint8_t _less_3(struct sym* a, struct sym* b);
struct sym get_fun_name(uint8_t* code_ptr, struct named_val* funs, uint64_t size);
struct named_val subscript_2(struct named_val* a, uint64_t n);
struct named_val _times_1(struct named_val* a);
struct named_val* _plus_1(struct named_val* a, uint64_t offset);
uint8_t* _times_2(uint8_t** a);
uint8_t** _plus_2(uint8_t** a, uint64_t offset);
char* begin_ptr_0(struct mut_arr_1* a);
char* begin_ptr_1(struct fix_arr_1 a);
struct fix_arr_1 uninitialized_fix_arr(struct ctx* ctx, uint64_t size);
struct fix_arr_1 fix_arr_2(uint64_t size, char* begin_ptr);
char* alloc_uninitialized_0(struct ctx* ctx, uint64_t size);
uint8_t* alloc(struct ctx* ctx, uint64_t size_bytes);
uint8_t* gc_alloc(struct ctx* ctx, struct gc* gc, uint64_t size);
uint8_t* todo_1(void);
struct void_ copy_data_from__e_1(struct ctx* ctx, char* to, char* from, uint64_t len);
struct void_ set_zero_elements(struct fix_arr_1 a);
struct void_ set_zero_range_1(char* begin, uint64_t size);
struct fix_arr_1 subscript_3(struct ctx* ctx, struct fix_arr_1 a, struct range range);
struct arr_0 subscript_4(struct ctx* ctx, struct arr_0 a, struct range range);
struct range _range(struct ctx* ctx, uint64_t low, uint64_t high);
uint64_t _plus_3(struct ctx* ctx, uint64_t a, uint64_t b);
uint8_t _greaterOrEqual(uint64_t a, uint64_t b);
uint64_t round_up_to_power_of_two(struct ctx* ctx, uint64_t n);
uint64_t round_up_to_power_of_two_recur(struct ctx* ctx, uint64_t acc, uint64_t n);
uint64_t _times_3(struct ctx* ctx, uint64_t a, uint64_t b);
uint64_t _divide(struct ctx* ctx, uint64_t a, uint64_t b);
struct void_ forbid(struct ctx* ctx, uint8_t condition);
struct void_ set_subscript_1(char* a, uint64_t n, char value);
struct void_ _concatEquals_1__lambda0(struct ctx* ctx, struct _concatEquals_1__lambda0* _closure, char x);
uint8_t is_empty_0(struct str a);
uint8_t is_empty_1(struct arr_0 a);
struct void_ each_1(struct ctx* ctx, struct arr_1 a, struct fun_act1_2 f);
struct void_ each_recur_1(struct ctx* ctx, struct sym* cur, struct sym* end, struct fun_act1_2 f);
uint8_t _equal_2(struct sym* a, struct sym* b);
uint8_t _notEqual_4(struct sym* a, struct sym* b);
struct void_ subscript_5(struct ctx* ctx, struct fun_act1_2 a, struct sym p0);
struct void_ call_w_ctx_159(struct fun_act1_2 a, struct ctx* ctx, struct sym p0);
struct sym _times_4(struct sym* a);
struct sym* _plus_4(struct sym* a, uint64_t offset);
struct sym* end_ptr_1(struct arr_1 a);
struct void_ _concatEquals_3(struct ctx* ctx, struct writer a, char* b);
struct str to_str_1(char* a);
struct arr_0 arr_from_begin_end(char* begin, char* end);
uint32_t _compare_5(char* a, char* b);
uint32_t _compare_6(char* a, char* b);
uint8_t _lessOrEqual_1(char* a, char* b);
uint8_t _less_4(char* a, char* b);
uint64_t _minus_3(char* a, char* b);
uint64_t _minus_4(char* a, char* b);
char* find_cstr_end(char* a);
struct opt_9 find_char_in_cstr(char* a, char c);
uint8_t _equal_3(char a, char b);
char* hard_unreachable_1(void);
struct void_ to_str_0__lambda0(struct ctx* ctx, struct to_str_0__lambda0* _closure, struct sym x);
struct str move_to_str__e(struct ctx* ctx, struct writer a);
struct arr_0 move_to_arr__e(struct mut_arr_1* a);
struct arr_0 cast_immutable(struct fix_arr_1 a);
struct fix_arr_1 move_to_fix_arr__e(struct mut_arr_1* a);
struct global_ctx* get_global_ctx(struct ctx* ctx);
struct void_ island__lambda0(struct ctx* ctx, struct void_ _closure, struct exception exn);
struct void_ default_log_handler(struct ctx* ctx, struct logged* a);
struct void_ print(struct str a);
struct void_ print_no_newline(struct str a);
int32_t stdout(void);
struct str _tilde_0(struct ctx* ctx, struct str a, struct str b);
struct arr_0 _tilde_1(struct ctx* ctx, struct arr_0 a, struct arr_0 b);
struct str to_str_2(struct ctx* ctx, uint32_t a);
struct void_ island__lambda1(struct ctx* ctx, struct void_ _closure, struct logged* log);
struct gc gc(void);
struct void_ validate_gc(struct gc* gc);
uint32_t _compare_7(uint8_t* a, uint8_t* b);
uint8_t _lessOrEqual_2(uint8_t* a, uint8_t* b);
uint8_t _less_5(uint8_t* a, uint8_t* b);
uint8_t _lessOrEqual_3(uint64_t* a, uint64_t* b);
struct thread_safe_counter thread_safe_counter_0(void);
struct thread_safe_counter thread_safe_counter_1(uint64_t init);
struct fut_0* add_main_task(struct global_ctx* gctx, uint64_t thread_id, struct island* island, int32_t argc, char** argv, fun_ptr2 main_ptr);
struct exception_ctx exception_ctx(void);
struct log_ctx log_ctx(void);
struct perf_ctx perf_ctx(void);
struct fix_arr_2 fix_arr_3(void);
struct ctx ctx(struct global_ctx* gctx, struct thread_local_stuff* tls, struct island* island, uint64_t exclusion);
struct gc_ctx* get_gc_ctx_1(struct gc* gc);
struct fut_0* add_first_task(struct ctx* ctx, struct arr_7 all_args, fun_ptr2 main_ptr);
struct fut_0* then_void(struct ctx* ctx, struct fut_1* a, struct fun_ref0 cb);
struct fut_0* then(struct ctx* ctx, struct fut_1* a, struct fun_ref1 cb);
struct fut_0* unresolved(struct ctx* ctx);
struct void_ callback__e_0(struct ctx* ctx, struct fut_1* f, struct fun_act1_3 cb);
struct void_ with_lock_0(struct ctx* ctx, struct lock* a, struct fun_act0_0 f);
struct void_ subscript_6(struct ctx* ctx, struct fun_act0_0 a);
struct void_ call_w_ctx_213(struct fun_act0_0 a, struct ctx* ctx);
struct void_ subscript_7(struct ctx* ctx, struct fun_act1_3 a, struct result_1 p0);
struct void_ call_w_ctx_215(struct fun_act1_3 a, struct ctx* ctx, struct result_1 p0);
struct void_ callback__e_0__lambda0(struct ctx* ctx, struct callback__e_0__lambda0* _closure);
struct void_ forward_to__e(struct ctx* ctx, struct fut_0* from, struct fut_0* to);
struct void_ callback__e_1(struct ctx* ctx, struct fut_0* f, struct fun_act1_0 cb);
struct void_ subscript_8(struct ctx* ctx, struct fun_act1_0 a, struct result_0 p0);
struct void_ call_w_ctx_220(struct fun_act1_0 a, struct ctx* ctx, struct result_0 p0);
struct void_ callback__e_1__lambda0(struct ctx* ctx, struct callback__e_1__lambda0* _closure);
struct void_ resolve_or_reject__e(struct ctx* ctx, struct fut_0* f, struct result_0 result);
struct fut_state_0 with_lock_1(struct ctx* ctx, struct lock* a, struct fun_act0_2 f);
struct fut_state_0 subscript_9(struct ctx* ctx, struct fun_act0_2 a);
struct fut_state_0 call_w_ctx_225(struct fun_act0_2 a, struct ctx* ctx);
struct fut_state_0 resolve_or_reject__e__lambda0(struct ctx* ctx, struct resolve_or_reject__e__lambda0* _closure);
struct void_ call_callbacks__e(struct ctx* ctx, struct fut_state_callbacks_0* cbs, struct result_0 value);
struct void_ forward_to__e__lambda0(struct ctx* ctx, struct forward_to__e__lambda0* _closure, struct result_0 it);
struct fut_0* subscript_10(struct ctx* ctx, struct fun_ref1 f, struct void_ p0);
struct island* get_island(struct ctx* ctx, uint64_t island_id);
struct island* subscript_11(struct ctx* ctx, struct arr_4 a, uint64_t index);
struct island* unsafe_at_0(struct arr_4 a, uint64_t index);
struct island* subscript_12(struct island** a, uint64_t n);
struct island* _times_5(struct island** a);
struct island** _plus_5(struct island** a, uint64_t offset);
struct void_ add_task_0(struct ctx* ctx, struct island* a, uint64_t exclusion, struct fun_act0_0 action);
struct void_ add_task_1(struct ctx* ctx, struct island* a, uint64_t timestamp, uint64_t exclusion, struct fun_act0_0 action);
struct task_queue_node* task_queue_node(struct ctx* ctx, struct task task);
struct void_ insert_task__e(struct task_queue* a, struct task_queue_node* inserted);
uint64_t size_1(struct task_queue* a);
uint64_t size_recur(struct opt_3 node, uint64_t acc);
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
extern int32_t setjmp(struct __jmp_buf_tag* env);
struct void_ subscript_13(struct ctx* ctx, struct fun_act1_5 a, struct exception p0);
struct void_ call_w_ctx_257(struct fun_act1_5 a, struct ctx* ctx, struct exception p0);
struct fut_0* subscript_14(struct ctx* ctx, struct fun_act1_4 a, struct void_ p0);
struct fut_0* call_w_ctx_259(struct fun_act1_4 a, struct ctx* ctx, struct void_ p0);
struct void_ subscript_10__lambda0__lambda0(struct ctx* ctx, struct subscript_10__lambda0__lambda0* _closure);
struct void_ reject__e(struct ctx* ctx, struct fut_0* f, struct exception e);
struct void_ subscript_10__lambda0__lambda1(struct ctx* ctx, struct subscript_10__lambda0__lambda1* _closure, struct exception err);
struct void_ subscript_10__lambda0(struct ctx* ctx, struct subscript_10__lambda0* _closure);
struct void_ then__lambda0(struct ctx* ctx, struct then__lambda0* _closure, struct result_1 result);
struct fut_0* subscript_15(struct ctx* ctx, struct fun_ref0 f);
struct fut_0* subscript_16(struct ctx* ctx, struct fun_act0_1 a);
struct fut_0* call_w_ctx_267(struct fun_act0_1 a, struct ctx* ctx);
struct void_ subscript_15__lambda0__lambda0(struct ctx* ctx, struct subscript_15__lambda0__lambda0* _closure);
struct void_ subscript_15__lambda0__lambda1(struct ctx* ctx, struct subscript_15__lambda0__lambda1* _closure, struct exception err);
struct void_ subscript_15__lambda0(struct ctx* ctx, struct subscript_15__lambda0* _closure);
struct fut_0* then_void__lambda0(struct ctx* ctx, struct then_void__lambda0* _closure, struct void_ ignore);
struct island_and_exclusion cur_island_and_exclusion(struct ctx* ctx);
struct fut_1* delay(struct ctx* ctx);
struct fut_1* resolved_0(struct ctx* ctx, struct void_ value);
struct arr_7 tail(struct ctx* ctx, struct arr_7 a);
uint8_t is_empty_2(struct arr_7 a);
struct arr_7 subscript_17(struct ctx* ctx, struct arr_7 a, struct range range);
char** _plus_6(char** a, uint64_t offset);
struct arr_2 map(struct ctx* ctx, struct arr_7 a, struct fun_act1_6 f);
struct arr_2 make_arr(struct ctx* ctx, uint64_t size, struct fun_act1_7 f);
struct str* alloc_uninitialized_1(struct ctx* ctx, uint64_t size);
struct void_ fill_ptr_range(struct ctx* ctx, struct str* begin, uint64_t size, struct fun_act1_7 f);
struct void_ fill_ptr_range_recur(struct ctx* ctx, struct str* begin, uint64_t i, uint64_t size, struct fun_act1_7 f);
uint8_t _notEqual_5(uint64_t a, uint64_t b);
struct void_ set_subscript_2(struct str* a, uint64_t n, struct str value);
struct str subscript_18(struct ctx* ctx, struct fun_act1_7 a, uint64_t p0);
struct str call_w_ctx_287(struct fun_act1_7 a, struct ctx* ctx, uint64_t p0);
struct str subscript_19(struct ctx* ctx, struct fun_act1_6 a, char* p0);
struct str call_w_ctx_289(struct fun_act1_6 a, struct ctx* ctx, char* p0);
char* subscript_20(struct ctx* ctx, struct arr_7 a, uint64_t index);
char* unsafe_at_1(struct arr_7 a, uint64_t index);
char* subscript_21(char** a, uint64_t n);
char* _times_6(char** a);
struct str map__lambda0(struct ctx* ctx, struct map__lambda0* _closure, uint64_t i);
struct str add_first_task__lambda0__lambda0(struct ctx* ctx, struct void_ _closure, char* arg);
struct fut_0* add_first_task__lambda0(struct ctx* ctx, struct add_first_task__lambda0* _closure);
struct void_ handle_exceptions(struct ctx* ctx, struct fut_0* a);
struct void_ subscript_22(struct ctx* ctx, struct fun1_0 a, struct exception p0);
struct void_ call_w_ctx_299(struct fun1_0 a, struct ctx* ctx, struct exception p0);
struct fun1_0 exception_handler(struct ctx* ctx, struct island* a);
struct island* get_cur_island(struct ctx* ctx);
struct void_ handle_exceptions__lambda0(struct ctx* ctx, struct void_ _closure, struct result_0 result);
struct fut_0* add_main_task__lambda0(struct ctx* ctx, struct void_ _closure, struct arr_7 all_args, fun_ptr2 main_ptr);
struct fut_0* call_w_ctx_304(struct fun_act2 a, struct ctx* ctx, struct arr_7 p0, fun_ptr2 p1);
struct void_ run_threads(uint64_t n_threads, struct global_ctx* gctx);
struct thread_args* unmanaged_alloc_elements_1(uint64_t size_elements);
struct void_ start_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads, struct thread_args* thread_args_begin, struct global_ctx* gctx);
struct void_ create_one_thread(struct cell_0* tid, uint8_t* thread_arg, fun_ptr1 thread_fun);
extern int32_t pthread_create(struct cell_0* thread, uint8_t* attr, fun_ptr1 start_routine, uint8_t* arg);
uint8_t* null(void);
uint8_t _notEqual_6(int32_t a, int32_t b);
int32_t EAGAIN(void);
struct cell_0* as_cell(uint64_t* a);
uint8_t* thread_fun(uint8_t* args_ptr);
struct void_ thread_function(uint64_t thread_id, struct global_ctx* gctx);
struct void_ thread_function_recur(struct global_ctx* gctx, struct thread_local_stuff* tls);
struct void_ assert_islands_are_shut_down(uint64_t i, struct arr_4 islands);
struct island* noctx_at_0(struct arr_4 a, uint64_t index);
struct void_ hard_forbid(uint8_t condition);
uint8_t is_empty_3(struct task_queue* a);
uint8_t is_empty_4(struct opt_3 a);
struct void_ drop_1(struct task_queue_node* _p0);
uint64_t get_sequence(struct condition* a);
struct choose_task_result choose_task(struct global_ctx* gctx);
uint64_t get_monotime_nsec(void);
extern int32_t clock_gettime(int32_t clock_id, struct cell_1* timespec);
struct timespec _times_7(struct cell_1* a);
uint64_t todo_2(void);
struct choose_task_result choose_task_recur(struct arr_4 islands, uint64_t i, uint64_t cur_time, uint8_t any_tasks, struct opt_11 first_task_time);
struct choose_task_in_island_result choose_task_in_island(struct island* island, uint64_t cur_time);
struct pop_task_result pop_task__e(struct task_queue* a, uint64_t cur_time);
uint8_t in_0(uint64_t value, struct mut_arr_0* a);
uint8_t in_1(uint64_t value, struct arr_3 a);
uint8_t in_recur(uint64_t value, struct arr_3 a, uint64_t i);
uint64_t noctx_at_1(struct arr_3 a, uint64_t index);
uint64_t unsafe_at_2(struct arr_3 a, uint64_t index);
uint64_t subscript_23(uint64_t* a, uint64_t n);
uint64_t _times_8(uint64_t* a);
uint64_t* _plus_7(uint64_t* a, uint64_t offset);
struct arr_3 temp_as_arr_0(struct mut_arr_0* a);
struct arr_3 temp_as_arr_1(struct fix_arr_0 a);
struct fix_arr_0 temp_as_fix_arr(struct mut_arr_0* a);
uint64_t* begin_ptr_2(struct mut_arr_0* a);
uint64_t* begin_ptr_3(struct fix_arr_0 a);
struct pop_task_result pop_recur__e(struct task_queue_node* prev, struct mut_arr_0* exclusions, uint64_t cur_time, struct opt_11 first_task_time);
struct opt_11 to_opt_time(uint64_t a);
struct void_ push_capacity_must_be_sufficient__e(struct mut_arr_0* a, uint64_t value);
uint64_t capacity_1(struct mut_arr_0* a);
uint64_t size_2(struct fix_arr_0 a);
struct void_ set_subscript_3(uint64_t* a, uint64_t n, uint64_t value);
uint8_t is_no_task(struct choose_task_in_island_result a);
struct opt_11 min_time(struct opt_11 a, struct opt_11 b);
uint64_t min(uint64_t a, uint64_t b);
struct void_ do_task(struct global_ctx* gctx, struct thread_local_stuff* tls, struct chosen_task chosen_task);
struct void_ return_task__e(struct task_queue* a, struct task task);
struct void_ noctx_must_remove_unordered__e(struct mut_arr_0* a, uint64_t value);
struct void_ noctx_must_remove_unordered_recur__e(struct mut_arr_0* a, uint64_t index, uint64_t value);
uint64_t subscript_24(uint64_t* a, uint64_t n);
struct void_ drop_2(uint64_t _p0);
uint64_t noctx_remove_unordered_at__e(struct mut_arr_0* a, uint64_t index);
struct void_ return_ctx(struct ctx* c);
struct void_ return_gc_ctx(struct gc_ctx* gc_ctx);
struct void_ run_garbage_collection(struct gc* gc, struct island_gc_root gc_root);
struct void_ mark_visit_364(struct mark_ctx* mark_ctx, struct island_gc_root value);
struct void_ mark_visit_365(struct mark_ctx* mark_ctx, struct task_queue value);
struct void_ mark_visit_366(struct mark_ctx* mark_ctx, struct opt_3 value);
struct void_ mark_visit_367(struct mark_ctx* mark_ctx, struct task_queue_node value);
struct void_ mark_visit_368(struct mark_ctx* mark_ctx, struct task value);
struct void_ mark_visit_369(struct mark_ctx* mark_ctx, struct fun_act0_0 value);
struct void_ mark_visit_370(struct mark_ctx* mark_ctx, struct callback__e_0__lambda0 value);
struct void_ mark_visit_371(struct mark_ctx* mark_ctx, struct fut_1 value);
struct void_ mark_visit_372(struct mark_ctx* mark_ctx, struct fut_state_1 value);
struct void_ mark_visit_373(struct mark_ctx* mark_ctx, struct fut_state_callbacks_1 value);
struct void_ mark_visit_374(struct mark_ctx* mark_ctx, struct fun_act1_3 value);
struct void_ mark_visit_375(struct mark_ctx* mark_ctx, struct then__lambda0 value);
struct void_ mark_visit_376(struct mark_ctx* mark_ctx, struct fun_ref1 value);
struct void_ mark_visit_377(struct mark_ctx* mark_ctx, struct fun_act1_4 value);
struct void_ mark_visit_378(struct mark_ctx* mark_ctx, struct then_void__lambda0 value);
struct void_ mark_visit_379(struct mark_ctx* mark_ctx, struct fun_ref0 value);
struct void_ mark_visit_380(struct mark_ctx* mark_ctx, struct fun_act0_1 value);
struct void_ mark_visit_381(struct mark_ctx* mark_ctx, struct add_first_task__lambda0 value);
struct void_ mark_arr_382(struct mark_ctx* mark_ctx, struct arr_7 a);
struct void_ mark_visit_383(struct mark_ctx* mark_ctx, struct add_first_task__lambda0* value);
struct void_ mark_visit_384(struct mark_ctx* mark_ctx, struct then_void__lambda0* value);
struct void_ mark_visit_385(struct mark_ctx* mark_ctx, struct fut_0 value);
struct void_ mark_visit_386(struct mark_ctx* mark_ctx, struct fut_state_0 value);
struct void_ mark_visit_387(struct mark_ctx* mark_ctx, struct fut_state_callbacks_0 value);
struct void_ mark_visit_388(struct mark_ctx* mark_ctx, struct fun_act1_0 value);
struct void_ mark_visit_389(struct mark_ctx* mark_ctx, struct forward_to__e__lambda0 value);
struct void_ mark_visit_390(struct mark_ctx* mark_ctx, struct fut_0* value);
struct void_ mark_visit_391(struct mark_ctx* mark_ctx, struct forward_to__e__lambda0* value);
struct void_ mark_visit_392(struct mark_ctx* mark_ctx, struct opt_0 value);
struct void_ mark_visit_393(struct mark_ctx* mark_ctx, struct fut_state_callbacks_0* value);
struct void_ mark_visit_394(struct mark_ctx* mark_ctx, struct exception value);
struct void_ mark_visit_395(struct mark_ctx* mark_ctx, struct str value);
struct void_ mark_arr_396(struct mark_ctx* mark_ctx, struct arr_0 a);
struct void_ mark_visit_397(struct mark_ctx* mark_ctx, struct backtrace value);
struct void_ mark_arr_398(struct mark_ctx* mark_ctx, struct arr_1 a);
struct void_ mark_visit_399(struct mark_ctx* mark_ctx, struct then__lambda0* value);
struct void_ mark_visit_400(struct mark_ctx* mark_ctx, struct opt_10 value);
struct void_ mark_visit_401(struct mark_ctx* mark_ctx, struct fut_state_callbacks_1* value);
struct void_ mark_visit_402(struct mark_ctx* mark_ctx, struct fut_1* value);
struct void_ mark_visit_403(struct mark_ctx* mark_ctx, struct callback__e_0__lambda0* value);
struct void_ mark_visit_404(struct mark_ctx* mark_ctx, struct callback__e_1__lambda0 value);
struct void_ mark_visit_405(struct mark_ctx* mark_ctx, struct callback__e_1__lambda0* value);
struct void_ mark_visit_406(struct mark_ctx* mark_ctx, struct subscript_10__lambda0__lambda0 value);
struct void_ mark_visit_407(struct mark_ctx* mark_ctx, struct subscript_10__lambda0__lambda0* value);
struct void_ mark_visit_408(struct mark_ctx* mark_ctx, struct subscript_10__lambda0 value);
struct void_ mark_visit_409(struct mark_ctx* mark_ctx, struct subscript_10__lambda0* value);
struct void_ mark_visit_410(struct mark_ctx* mark_ctx, struct subscript_15__lambda0__lambda0 value);
struct void_ mark_visit_411(struct mark_ctx* mark_ctx, struct subscript_15__lambda0__lambda0* value);
struct void_ mark_visit_412(struct mark_ctx* mark_ctx, struct subscript_15__lambda0 value);
struct void_ mark_visit_413(struct mark_ctx* mark_ctx, struct subscript_15__lambda0* value);
struct void_ mark_visit_414(struct mark_ctx* mark_ctx, struct with_log_handler__lambda0 value);
struct void_ mark_visit_415(struct mark_ctx* mark_ctx, struct fun1_1 value);
struct void_ mark_visit_416(struct mark_ctx* mark_ctx, struct main_0__lambda0 value);
struct void_ mark_visit_417(struct mark_ctx* mark_ctx, struct main_0__lambda0* value);
struct void_ mark_visit_418(struct mark_ctx* mark_ctx, struct with_log_handler__lambda0* value);
struct void_ mark_visit_419(struct mark_ctx* mark_ctx, struct task_queue_node* value);
struct void_ mark_visit_420(struct mark_ctx* mark_ctx, struct mut_arr_0 value);
struct void_ mark_visit_421(struct mark_ctx* mark_ctx, struct fix_arr_0 value);
struct void_ mark_arr_422(struct mark_ctx* mark_ctx, struct arr_3 a);
struct void_ clear_free_mem__e(uint8_t* mark_ptr, uint8_t* mark_end, uint64_t* data_ptr);
uint8_t _notEqual_7(uint8_t* a, uint8_t* b);
struct void_ wait_on(struct condition* a, struct opt_11 until_time, uint64_t last_sequence);
extern int32_t pthread_cond_wait(struct pthread_cond_t* cond, struct pthread_mutex_t* mutex);
struct timespec to_timespec(uint64_t a);
extern int32_t pthread_cond_timedwait(struct pthread_cond_t* cond, struct pthread_mutex_t* mutex, struct timespec* abstime);
int32_t ETIMEDOUT(void);
struct void_ join_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads);
struct void_ join_one_thread(uint64_t tid);
extern int32_t pthread_join(uint64_t thread, struct cell_2* thread_return);
int32_t EINVAL(void);
int32_t ESRCH(void);
uint8_t* _times_9(struct cell_2* a);
struct void_ unmanaged_free_0(uint64_t* p);
extern void free(uint8_t* p);
struct void_ unmanaged_free_1(struct thread_args* p);
struct void_ destroy_condition(struct condition* a);
extern int32_t pthread_mutexattr_destroy(struct pthread_mutexattr_t* attr);
extern int32_t pthread_mutex_destroy(struct pthread_mutex_t* mutex);
extern int32_t pthread_condattr_destroy(struct pthread_condattr_t* attr);
extern int32_t pthread_cond_destroy(struct pthread_cond_t* cond);
struct fut_0* main_0(struct ctx* ctx, struct arr_2 _p0);
struct void_ log(struct ctx* ctx, uint32_t level, struct str message);
struct void_ subscript_25(struct ctx* ctx, struct fun1_1 a, struct logged* p0);
struct void_ call_w_ctx_447(struct fun1_1 a, struct ctx* ctx, struct logged* p0);
struct fun1_1 get_log_handler(struct ctx* ctx);
struct log_ctx* get_log_ctx(struct ctx* ctx);
struct void_ main_0__lambda0(struct ctx* ctx, struct main_0__lambda0* _closure, struct logged* logged);
struct void_ with_log_handler(struct ctx* ctx, struct fun1_1 handler, struct fun_act0_0 cb);
struct void_ set_log_handler(struct ctx* ctx, struct fun1_1 handler);
struct void_ with_log_handler__lambda0(struct ctx* ctx, struct with_log_handler__lambda0* _closure);
struct void_ with_log_handler__lambda1(struct ctx* ctx, struct with_log_handler__lambda1* _closure, struct exception err);
struct void_ main_0__lambda1(struct ctx* ctx, struct void_ _closure);
struct void_ main_0__lambda2(struct ctx* ctx, struct void_ _closure, struct logged* ignore);
struct void_ main_0__lambda3(struct ctx* ctx, struct void_ _closure);
struct fut_0* resolved_1(struct ctx* ctx, uint64_t value);
int32_t main(int32_t argc, char** argv);
char constantarr_0_0[20];
char constantarr_0_1[1];
char constantarr_0_2[13];
char constantarr_0_3[13];
char constantarr_0_4[17];
char constantarr_0_5[5];
char constantarr_0_6[4];
char constantarr_0_7[4];
char constantarr_0_8[5];
char constantarr_0_9[2];
char constantarr_0_10[11];
char constantarr_0_11[12];
char constantarr_0_12[12];
char constantarr_0_13[4];
char constantarr_0_14[11];
char constantarr_0_15[4];
char constantarr_0_16[5];
char constantarr_0_17[15];
char constantarr_0_18[2];
char constantarr_0_19[1];
char constantarr_0_20[14];
char constantarr_0_21[12];
char constantarr_0_22[14];
char constantarr_0_23[10];
char constantarr_0_24[25];
char constantarr_0_25[8];
char constantarr_0_26[1];
char constantarr_0_27[21];
char constantarr_0_28[13];
char constantarr_0_29[17];
char constantarr_0_30[8];
char constantarr_0_31[4];
char constantarr_0_32[8];
char constantarr_0_33[11];
char constantarr_0_34[10];
char constantarr_0_35[9];
char constantarr_0_36[12];
char constantarr_0_37[3];
char constantarr_0_38[7];
char constantarr_0_39[10];
char constantarr_0_40[4];
char constantarr_0_41[5];
char constantarr_0_42[7];
char constantarr_0_43[8];
char constantarr_0_44[4];
char constantarr_0_45[5];
char constantarr_0_46[17];
char constantarr_0_47[9];
char constantarr_0_48[1];
char constantarr_0_49[7];
char constantarr_0_50[5];
char constantarr_0_51[16];
char constantarr_0_52[8];
char constantarr_0_53[2];
char constantarr_0_54[7];
char constantarr_0_55[15];
char constantarr_0_56[8];
char constantarr_0_57[7];
char constantarr_0_58[10];
char constantarr_0_59[10];
char constantarr_0_60[3];
char constantarr_0_61[11];
char constantarr_0_62[4];
char constantarr_0_63[11];
char constantarr_0_64[22];
char constantarr_0_65[16];
char constantarr_0_66[9];
char constantarr_0_67[35];
char constantarr_0_68[31];
char constantarr_0_69[34];
char constantarr_0_70[30];
char constantarr_0_71[23];
char constantarr_0_72[22];
char constantarr_0_73[31];
char constantarr_0_74[10];
char constantarr_0_75[21];
char constantarr_0_76[18];
char constantarr_0_77[27];
char constantarr_0_78[5];
char constantarr_0_79[21];
char constantarr_0_80[30];
char constantarr_0_81[9];
char constantarr_0_82[25];
char constantarr_0_83[15];
char constantarr_0_84[17];
char constantarr_0_85[26];
char constantarr_0_86[4];
char constantarr_0_87[22];
char constantarr_0_88[6];
char constantarr_0_89[10];
char constantarr_0_90[21];
char constantarr_0_91[57];
char constantarr_0_92[10];
char constantarr_0_93[6];
char constantarr_0_94[34];
char constantarr_0_95[27];
char constantarr_0_96[21];
char constantarr_0_97[6];
char constantarr_0_98[8];
char constantarr_0_99[17];
char constantarr_0_100[10];
char constantarr_0_101[8];
char constantarr_0_102[17];
char constantarr_0_103[19];
char constantarr_0_104[6];
char constantarr_0_105[26];
char constantarr_0_106[10];
char constantarr_0_107[14];
char constantarr_0_108[25];
char constantarr_0_109[20];
char constantarr_0_110[16];
char constantarr_0_111[13];
char constantarr_0_112[13];
char constantarr_0_113[5];
char constantarr_0_114[33];
char constantarr_0_115[14];
char constantarr_0_116[17];
char constantarr_0_117[15];
char constantarr_0_118[5];
char constantarr_0_119[10];
char constantarr_0_120[10];
char constantarr_0_121[9];
char constantarr_0_122[15];
char constantarr_0_123[10];
char constantarr_0_124[9];
char constantarr_0_125[6];
char constantarr_0_126[9];
char constantarr_0_127[6];
char constantarr_0_128[6];
char constantarr_0_129[13];
char constantarr_0_130[2];
char constantarr_0_131[8];
char constantarr_0_132[7];
char constantarr_0_133[13];
char constantarr_0_134[5];
char constantarr_0_135[16];
char constantarr_0_136[18];
char constantarr_0_137[20];
char constantarr_0_138[7];
char constantarr_0_139[4];
char constantarr_0_140[4];
char constantarr_0_141[11];
char constantarr_0_142[10];
char constantarr_0_143[5];
char constantarr_0_144[17];
char constantarr_0_145[18];
char constantarr_0_146[11];
char constantarr_0_147[7];
char constantarr_0_148[8];
char constantarr_0_149[10];
char constantarr_0_150[24];
char constantarr_0_151[6];
char constantarr_0_152[11];
char constantarr_0_153[8];
char constantarr_0_154[17];
char constantarr_0_155[21];
char constantarr_0_156[17];
char constantarr_0_157[18];
char constantarr_0_158[17];
char constantarr_0_159[26];
char constantarr_0_160[11];
char constantarr_0_161[19];
char constantarr_0_162[20];
char constantarr_0_163[7];
char constantarr_0_164[15];
char constantarr_0_165[19];
char constantarr_0_166[9];
char constantarr_0_167[13];
char constantarr_0_168[24];
char constantarr_0_169[40];
char constantarr_0_170[9];
char constantarr_0_171[12];
char constantarr_0_172[8];
char constantarr_0_173[14];
char constantarr_0_174[12];
char constantarr_0_175[8];
char constantarr_0_176[11];
char constantarr_0_177[23];
char constantarr_0_178[12];
char constantarr_0_179[5];
char constantarr_0_180[23];
char constantarr_0_181[9];
char constantarr_0_182[12];
char constantarr_0_183[11];
char constantarr_0_184[16];
char constantarr_0_185[2];
char constantarr_0_186[18];
char constantarr_0_187[8];
char constantarr_0_188[8];
char constantarr_0_189[9];
char constantarr_0_190[10];
char constantarr_0_191[10];
char constantarr_0_192[17];
char constantarr_0_193[8];
char constantarr_0_194[10];
char constantarr_0_195[8];
char constantarr_0_196[12];
char constantarr_0_197[12];
char constantarr_0_198[19];
char constantarr_0_199[21];
char constantarr_0_200[19];
char constantarr_0_201[19];
char constantarr_0_202[7];
char constantarr_0_203[10];
char constantarr_0_204[10];
char constantarr_0_205[12];
char constantarr_0_206[8];
char constantarr_0_207[11];
char constantarr_0_208[10];
char constantarr_0_209[6];
char constantarr_0_210[2];
char constantarr_0_211[10];
char constantarr_0_212[14];
char constantarr_0_213[10];
char constantarr_0_214[16];
char constantarr_0_215[16];
char constantarr_0_216[17];
char constantarr_0_217[20];
char constantarr_0_218[28];
char constantarr_0_219[51];
char constantarr_0_220[32];
char constantarr_0_221[8];
char constantarr_0_222[20];
char constantarr_0_223[14];
char constantarr_0_224[9];
char constantarr_0_225[12];
char constantarr_0_226[15];
char constantarr_0_227[8];
char constantarr_0_228[9];
char constantarr_0_229[15];
char constantarr_0_230[14];
char constantarr_0_231[43];
char constantarr_0_232[6];
char constantarr_0_233[30];
char constantarr_0_234[4];
char constantarr_0_235[37];
char constantarr_0_236[5];
char constantarr_0_237[33];
char constantarr_0_238[12];
char constantarr_0_239[16];
char constantarr_0_240[12];
char constantarr_0_241[10];
char constantarr_0_242[9];
char constantarr_0_243[6];
char constantarr_0_244[18];
char constantarr_0_245[20];
char constantarr_0_246[6];
char constantarr_0_247[10];
char constantarr_0_248[16];
char constantarr_0_249[7];
char constantarr_0_250[8];
char constantarr_0_251[15];
char constantarr_0_252[14];
char constantarr_0_253[12];
char constantarr_0_254[37];
char constantarr_0_255[21];
char constantarr_0_256[18];
char constantarr_0_257[18];
char constantarr_0_258[8];
char constantarr_0_259[13];
char constantarr_0_260[12];
char constantarr_0_261[14];
char constantarr_0_262[24];
char constantarr_0_263[22];
char constantarr_0_264[5];
char constantarr_0_265[8];
char constantarr_0_266[19];
char constantarr_0_267[18];
char constantarr_0_268[20];
char constantarr_0_269[11];
char constantarr_0_270[10];
char constantarr_0_271[9];
char constantarr_0_272[8];
char constantarr_0_273[1];
char constantarr_0_274[2];
char constantarr_0_275[9];
char constantarr_0_276[24];
char constantarr_0_277[30];
char constantarr_0_278[1];
char constantarr_0_279[1];
char constantarr_0_280[6];
char constantarr_0_281[11];
char constantarr_0_282[16];
char constantarr_0_283[8];
char constantarr_0_284[14];
char constantarr_0_285[7];
char constantarr_0_286[9];
char constantarr_0_287[12];
char constantarr_0_288[3];
char constantarr_0_289[24];
char constantarr_0_290[16];
char constantarr_0_291[4];
char constantarr_0_292[13];
char constantarr_0_293[17];
char constantarr_0_294[7];
char constantarr_0_295[21];
char constantarr_0_296[21];
char constantarr_0_297[33];
char constantarr_0_298[8];
char constantarr_0_299[14];
char constantarr_0_300[12];
char constantarr_0_301[18];
char constantarr_0_302[17];
char constantarr_0_303[19];
char constantarr_0_304[28];
char constantarr_0_305[14];
char constantarr_0_306[18];
char constantarr_0_307[8];
char constantarr_0_308[14];
char constantarr_0_309[19];
char constantarr_0_310[5];
char constantarr_0_311[16];
char constantarr_0_312[6];
char constantarr_0_313[7];
char constantarr_0_314[5];
char constantarr_0_315[14];
char constantarr_0_316[20];
char constantarr_0_317[29];
char constantarr_0_318[12];
char constantarr_0_319[11];
char constantarr_0_320[10];
char constantarr_0_321[9];
char constantarr_0_322[17];
char constantarr_0_323[8];
char constantarr_0_324[18];
char constantarr_0_325[14];
char constantarr_0_326[19];
char constantarr_0_327[18];
char constantarr_0_328[11];
char constantarr_0_329[11];
char constantarr_0_330[14];
char constantarr_0_331[13];
char constantarr_0_332[13];
char constantarr_0_333[7];
char constantarr_0_334[26];
char constantarr_0_335[8];
char constantarr_0_336[22];
char constantarr_0_337[29];
char constantarr_0_338[25];
char constantarr_0_339[23];
char constantarr_0_340[19];
char constantarr_0_341[24];
char constantarr_0_342[20];
char constantarr_0_343[10];
char constantarr_0_344[3];
char constantarr_0_345[12];
char constantarr_0_346[23];
char constantarr_0_347[6];
char constantarr_0_348[12];
char constantarr_0_349[16];
char constantarr_0_350[8];
char constantarr_0_351[11];
char constantarr_0_352[15];
char constantarr_0_353[11];
char constantarr_0_354[11];
char constantarr_0_355[26];
char constantarr_0_356[7];
char constantarr_0_357[26];
char constantarr_0_358[2];
char constantarr_0_359[22];
char constantarr_0_360[30];
char constantarr_0_361[15];
char constantarr_0_362[14];
char constantarr_0_363[16];
char constantarr_0_364[15];
char constantarr_0_365[15];
char constantarr_0_366[6];
char constantarr_0_367[25];
char constantarr_0_368[13];
char constantarr_0_369[15];
char constantarr_0_370[16];
char constantarr_0_371[5];
char constantarr_0_372[8];
char constantarr_0_373[12];
char constantarr_0_374[22];
char constantarr_0_375[28];
char constantarr_0_376[28];
char constantarr_0_377[37];
char constantarr_0_378[16];
char constantarr_0_379[17];
char constantarr_0_380[21];
char constantarr_0_381[16];
char constantarr_0_382[12];
char constantarr_0_383[20];
char constantarr_0_384[21];
char constantarr_0_385[23];
char constantarr_0_386[21];
char constantarr_0_387[22];
char constantarr_0_388[29];
char constantarr_0_389[18];
char constantarr_0_390[5];
char constantarr_0_391[7];
char constantarr_0_392[24];
char constantarr_0_393[18];
char constantarr_0_394[10];
char constantarr_0_395[17];
char constantarr_0_396[12];
char constantarr_0_397[7];
char constantarr_0_398[27];
char constantarr_0_399[8];
char constantarr_0_400[15];
char constantarr_0_401[4];
char constantarr_0_402[10];
char constantarr_0_403[12];
char constantarr_0_404[4];
char constantarr_0_405[10];
char constantarr_0_406[4];
char constantarr_0_407[4];
char constantarr_0_408[8];
char constantarr_0_409[21];
char constantarr_0_410[4];
char constantarr_0_411[12];
char constantarr_0_412[8];
char constantarr_0_413[5];
char constantarr_0_414[22];
char constantarr_0_415[10];
char constantarr_0_416[18];
char constantarr_0_417[22];
char constantarr_0_418[12];
char constantarr_0_419[8];
char constantarr_0_420[20];
char constantarr_0_421[17];
char constantarr_0_422[4];
char constantarr_0_423[12];
char constantarr_0_424[9];
char constantarr_0_425[11];
char constantarr_0_426[27];
char constantarr_0_427[16];
char constantarr_0_428[13];
char constantarr_0_429[4];
char constantarr_0_430[7];
char constantarr_0_431[7];
char constantarr_0_432[7];
char constantarr_0_433[8];
char constantarr_0_434[15];
char constantarr_0_435[21];
char constantarr_0_436[6];
char constantarr_0_437[23];
char constantarr_0_438[21];
char constantarr_0_439[10];
char constantarr_0_440[34];
char constantarr_0_441[10];
char constantarr_0_442[34];
char constantarr_0_443[26];
char constantarr_0_444[23];
char constantarr_0_445[14];
char constantarr_0_446[23];
char constantarr_0_447[17];
char constantarr_0_448[6];
char constantarr_0_449[30];
char constantarr_0_450[30];
char constantarr_0_451[22];
char constantarr_0_452[24];
char constantarr_0_453[24];
char constantarr_0_454[20];
char constantarr_0_455[9];
char constantarr_0_456[5];
char constantarr_0_457[14];
char constantarr_0_458[21];
char constantarr_0_459[11];
char constantarr_0_460[36];
char constantarr_0_461[25];
char constantarr_0_462[13];
char constantarr_0_463[17];
char constantarr_0_464[23];
char constantarr_0_465[9];
char constantarr_0_466[19];
char constantarr_0_467[13];
char constantarr_0_468[33];
char constantarr_0_469[30];
char constantarr_0_470[22];
char constantarr_0_471[24];
char constantarr_0_472[26];
char constantarr_0_473[17];
char constantarr_0_474[14];
char constantarr_0_475[32];
char constantarr_0_476[21];
char constantarr_0_477[84];
char constantarr_0_478[11];
char constantarr_0_479[45];
char constantarr_0_480[19];
char constantarr_0_481[22];
char constantarr_0_482[30];
char constantarr_0_483[11];
char constantarr_0_484[17];
char constantarr_0_485[14];
char constantarr_0_486[9];
char constantarr_0_487[6];
char constantarr_0_488[14];
char constantarr_0_489[15];
char constantarr_0_490[44];
char constantarr_0_491[10];
char constantarr_0_492[19];
char constantarr_0_493[15];
char constantarr_0_494[21];
char constantarr_0_495[12];
char constantarr_0_496[18];
char constantarr_0_497[14];
char constantarr_0_498[28];
char constantarr_0_499[16];
char constantarr_0_500[11];
char constantarr_0_501[8];
char constantarr_0_502[17];
char constantarr_0_503[25];
char constantarr_0_504[7];
char constantarr_0_505[12];
char constantarr_0_506[11];
char constantarr_0_507[17];
char constantarr_0_508[14];
char constantarr_0_509[8];
char constantarr_0_510[13];
char constantarr_0_511[26];
char constantarr_0_512[11];
char constantarr_0_513[14];
char constantarr_0_514[6];
char constantarr_0_515[7];
char constantarr_0_516[11];
char constantarr_0_517[17];
char constantarr_0_518[19];
char constantarr_0_519[14];
char constantarr_0_520[21];
char constantarr_0_521[7];
char constantarr_0_522[11];
char constantarr_0_523[7];
char constantarr_0_524[11];
char constantarr_0_525[9];
char constantarr_0_526[26];
char constantarr_0_527[28];
char constantarr_0_528[11];
char constantarr_0_529[9];
char constantarr_0_530[5];
char constantarr_0_531[11];
char constantarr_0_532[11];
char constantarr_0_533[14];
char constantarr_0_534[18];
char constantarr_0_535[10];
char constantarr_0_536[11];
char constantarr_0_537[11];
char constantarr_0_538[8];
char constantarr_0_539[40];
char constantarr_0_540[8];
char constantarr_0_541[10];
char constantarr_0_542[21];
char constantarr_0_543[16];
char constantarr_0_544[11];
char constantarr_0_545[9];
char constantarr_0_546[9];
char constantarr_0_547[8];
char constantarr_0_548[10];
char constantarr_0_549[15];
char constantarr_0_550[28];
char constantarr_0_551[7];
char constantarr_0_552[11];
char constantarr_0_553[10];
char constantarr_0_554[6];
char constantarr_0_555[12];
char constantarr_0_556[35];
char constantarr_0_557[37];
char constantarr_0_558[29];
char constantarr_0_559[10];
char constantarr_0_560[13];
char constantarr_0_561[12];
char constantarr_0_562[46];
char constantarr_0_563[12];
char constantarr_0_564[8];
char constantarr_0_565[8];
char constantarr_0_566[13];
char constantarr_0_567[20];
char constantarr_0_568[15];
char constantarr_0_569[17];
char constantarr_0_570[16];
char constantarr_0_571[7];
char constantarr_0_572[17];
char constantarr_0_573[11];
char constantarr_0_574[10];
char constantarr_0_575[22];
char constantarr_0_576[16];
char constantarr_0_577[9];
char constantarr_0_578[9];
char constantarr_0_579[18];
char constantarr_0_580[15];
char constantarr_0_581[19];
char constantarr_0_582[12];
char constantarr_0_583[31];
char constantarr_0_584[6];
char constantarr_0_585[5];
char constantarr_0_586[16];
char constantarr_0_587[21];
char constantarr_0_588[4];
char constantarr_0_589[35];
char constantarr_0_590[17];
char constantarr_0_591[25];
char constantarr_0_592[21];
char constantarr_0_593[24];
char constantarr_0_594[20];
char constantarr_0_595[24];
char constantarr_0_596[4];
char constantarr_0_597[3];
char constantarr_0_598[23];
char constantarr_0_599[15];
char constantarr_0_600[7];
char constantarr_0_601[11];
char constantarr_0_602[6];
char constantarr_0_603[12];
char constantarr_0_604[22];
char constantarr_0_605[15];
char constantarr_0_606[30];
char constantarr_0_607[30];
char constantarr_0_608[12];
char constantarr_0_609[12];
char constantarr_0_610[12];
char constantarr_0_611[15];
char constantarr_0_612[11];
struct named_val constantarr_5_0[346];
struct sym constantarr_1_0[210];
char constantarr_0_0[20] = "uncaught exception: ";
char constantarr_0_1[1] = "\n";
char constantarr_0_2[13] = "assert failed";
char constantarr_0_3[13] = "forbid failed";
char constantarr_0_4[17] = "<<empty message>>";
char constantarr_0_5[5] = "\n\tat ";
char constantarr_0_6[4] = "info";
char constantarr_0_7[4] = "warn";
char constantarr_0_8[5] = "error";
char constantarr_0_9[2] = ": ";
char constantarr_0_10[11] = "Logged once";
char constantarr_0_11[12] = "Logged twice";
char constantarr_0_12[12] = "Logged never";
char constantarr_0_13[4] = "mark";
char constantarr_0_14[11] = "hard-assert";
char constantarr_0_15[4] = "void";
char constantarr_0_16[5] = "abort";
char constantarr_0_17[15] = "is-word-aligned";
char constantarr_0_18[2] = "==";
char constantarr_0_19[1] = "&";
char constantarr_0_20[14] = "to-nat64<nat8>";
char constantarr_0_21[12] = "as-mut<nat8>";
char constantarr_0_22[14] = "words-of-bytes";
char constantarr_0_23[10] = "unsafe-div";
char constantarr_0_24[25] = "round-up-to-multiple-of-8";
char constantarr_0_25[8] = "wrap-add";
char constantarr_0_26[1] = "~";
char constantarr_0_27[21] = "ptr-cast<nat64, nat8>";
char constantarr_0_28[13] = "as-const<out>";
char constantarr_0_29[17] = "ptr-cast<out, in>";
char constantarr_0_30[8] = "-<nat64>";
char constantarr_0_31[4] = "-<a>";
char constantarr_0_32[8] = "wrap-sub";
char constantarr_0_33[11] = "to-nat64<a>";
char constantarr_0_34[10] = "size-of<a>";
char constantarr_0_35[9] = "as-mut<a>";
char constantarr_0_36[12] = "memory-start";
char constantarr_0_37[3] = "<=>";
char constantarr_0_38[7] = "is-less";
char constantarr_0_39[10] = "cmp<nat64>";
char constantarr_0_40[4] = "less";
char constantarr_0_41[5] = "equal";
char constantarr_0_42[7] = "greater";
char constantarr_0_43[8] = "<<nat64>";
char constantarr_0_44[4] = "true";
char constantarr_0_45[5] = "false";
char constantarr_0_46[17] = "memory-size-words";
char constantarr_0_47[9] = "<=<nat64>";
char constantarr_0_48[1] = "!";
char constantarr_0_49[7] = "+<bool>";
char constantarr_0_50[5] = "marks";
char constantarr_0_51[16] = "mark-range-recur";
char constantarr_0_52[8] = "==<bool>";
char constantarr_0_53[2] = "||";
char constantarr_0_54[7] = "*<bool>";
char constantarr_0_55[15] = "set-deref<bool>";
char constantarr_0_56[8] = "><nat64>";
char constantarr_0_57[7] = "rt-main";
char constantarr_0_58[10] = "get_nprocs";
char constantarr_0_59[10] = "global-ctx";
char constantarr_0_60[3] = "lbv";
char constantarr_0_61[11] = "lock-by-val";
char constantarr_0_62[4] = "lock";
char constantarr_0_63[11] = "atomic-bool";
char constantarr_0_64[22] = "none<dynamic-sym-node>";
char constantarr_0_65[16] = "create-condition";
char constantarr_0_66[9] = "condition";
char constantarr_0_67[35] = "zeroed<by-val<pthread_mutexattr_t>>";
char constantarr_0_68[31] = "zeroed<by-val<pthread_mutex_t>>";
char constantarr_0_69[34] = "zeroed<by-val<pthread_condattr_t>>";
char constantarr_0_70[30] = "zeroed<by-val<pthread_cond_t>>";
char constantarr_0_71[23] = "hard-assert-posix-error";
char constantarr_0_72[22] = "pthread_mutexattr_init";
char constantarr_0_73[31] = "ref-of-val<pthread_mutexattr_t>";
char constantarr_0_74[10] = "mutex-attr";
char constantarr_0_75[21] = "ref-of-val<condition>";
char constantarr_0_76[18] = "pthread_mutex_init";
char constantarr_0_77[27] = "ref-of-val<pthread_mutex_t>";
char constantarr_0_78[5] = "mutex";
char constantarr_0_79[21] = "pthread_condattr_init";
char constantarr_0_80[30] = "ref-of-val<pthread_condattr_t>";
char constantarr_0_81[9] = "cond-attr";
char constantarr_0_82[25] = "pthread_condattr_setclock";
char constantarr_0_83[15] = "CLOCK_MONOTONIC";
char constantarr_0_84[17] = "pthread_cond_init";
char constantarr_0_85[26] = "ref-of-val<pthread_cond_t>";
char constantarr_0_86[4] = "cond";
char constantarr_0_87[22] = "ref-of-val<global-ctx>";
char constantarr_0_88[6] = "island";
char constantarr_0_89[10] = "task-queue";
char constantarr_0_90[21] = "none<task-queue-node>";
char constantarr_0_91[57] = "mut-arr-by-val-with-capacity-from-unmanaged-memory<nat64>";
char constantarr_0_92[10] = "fix-arr<a>";
char constantarr_0_93[6] = "arr<a>";
char constantarr_0_94[34] = "unmanaged-alloc-zeroed-elements<a>";
char constantarr_0_95[27] = "unmanaged-alloc-elements<a>";
char constantarr_0_96[21] = "unmanaged-alloc-bytes";
char constantarr_0_97[6] = "malloc";
char constantarr_0_98[8] = "==<nat8>";
char constantarr_0_99[17] = "!=<mut-ptr<nat8>>";
char constantarr_0_100[10] = "null<nat8>";
char constantarr_0_101[8] = "wrap-mul";
char constantarr_0_102[17] = "set-zero-range<a>";
char constantarr_0_103[19] = "drop<mut-ptr<nat8>>";
char constantarr_0_104[6] = "memset";
char constantarr_0_105[26] = "as-any-mut-ptr<mut-ptr<a>>";
char constantarr_0_106[10] = "mut-arr<a>";
char constantarr_0_107[14] = "island-gc-root";
char constantarr_0_108[25] = "default-exception-handler";
char constantarr_0_109[20] = "print-err-no-newline";
char constantarr_0_110[16] = "write-no-newline";
char constantarr_0_111[13] = "size-of<char>";
char constantarr_0_112[13] = "size-of<nat8>";
char constantarr_0_113[5] = "write";
char constantarr_0_114[33] = "as-any-const-ptr<const-ptr<char>>";
char constantarr_0_115[14] = "as-const<nat8>";
char constantarr_0_116[17] = "as-any-mut-ptr<a>";
char constantarr_0_117[15] = "begin-ptr<char>";
char constantarr_0_118[5] = "chars";
char constantarr_0_119[10] = "size-bytes";
char constantarr_0_120[10] = "size<char>";
char constantarr_0_121[9] = "!=<int64>";
char constantarr_0_122[15] = "unsafe-to-int64";
char constantarr_0_123[10] = "todo<void>";
char constantarr_0_124[9] = "zeroed<a>";
char constantarr_0_125[6] = "stderr";
char constantarr_0_126[9] = "print-err";
char constantarr_0_127[6] = "to-str";
char constantarr_0_128[6] = "writer";
char constantarr_0_129[13] = "mut-arr<char>";
char constantarr_0_130[2] = "~=";
char constantarr_0_131[8] = "~=<char>";
char constantarr_0_132[7] = "each<a>";
char constantarr_0_133[13] = "each-recur<a>";
char constantarr_0_134[5] = "==<a>";
char constantarr_0_135[16] = "!=<const-ptr<a>>";
char constantarr_0_136[18] = "subscript<void, a>";
char constantarr_0_137[20] = "call-with-ctx<r, p0>";
char constantarr_0_138[7] = "get-ctx";
char constantarr_0_139[4] = "*<a>";
char constantarr_0_140[4] = "+<a>";
char constantarr_0_141[11] = "as-const<a>";
char constantarr_0_142[10] = "end-ptr<a>";
char constantarr_0_143[5] = "~=<a>";
char constantarr_0_144[17] = "incr-capacity!<a>";
char constantarr_0_145[18] = "ensure-capacity<a>";
char constantarr_0_146[11] = "capacity<a>";
char constantarr_0_147[7] = "size<a>";
char constantarr_0_148[8] = "inner<a>";
char constantarr_0_149[10] = "backing<a>";
char constantarr_0_150[24] = "increase-capacity-to!<a>";
char constantarr_0_151[6] = "assert";
char constantarr_0_152[11] = "throw<void>";
char constantarr_0_153[8] = "throw<a>";
char constantarr_0_154[17] = "get-exception-ctx";
char constantarr_0_155[21] = "as-ref<exception-ctx>";
char constantarr_0_156[17] = "exception-ctx-ptr";
char constantarr_0_157[18] = "thread-local-stuff";
char constantarr_0_158[17] = "==<__jmp_buf_tag>";
char constantarr_0_159[26] = "!=<mut-ptr<__jmp_buf_tag>>";
char constantarr_0_160[11] = "jmp-buf-ptr";
char constantarr_0_161[19] = "null<__jmp_buf_tag>";
char constantarr_0_162[20] = "set-thrown-exception";
char constantarr_0_163[7] = "longjmp";
char constantarr_0_164[15] = "number-to-throw";
char constantarr_0_165[19] = "hard-unreachable<a>";
char constantarr_0_166[9] = "exception";
char constantarr_0_167[13] = "get-backtrace";
char constantarr_0_168[24] = "try-alloc-backtrace-arrs";
char constantarr_0_169[40] = "try-alloc-uninitialized<const-ptr<nat8>>";
char constantarr_0_170[9] = "try-alloc";
char constantarr_0_171[12] = "try-gc-alloc";
char constantarr_0_172[8] = "acquire!";
char constantarr_0_173[14] = "acquire-recur!";
char constantarr_0_174[12] = "try-acquire!";
char constantarr_0_175[8] = "try-set!";
char constantarr_0_176[11] = "try-change!";
char constantarr_0_177[23] = "compare-exchange-strong";
char constantarr_0_178[12] = "ptr-to<bool>";
char constantarr_0_179[5] = "value";
char constantarr_0_180[23] = "ref-of-val<atomic-bool>";
char constantarr_0_181[9] = "is-locked";
char constantarr_0_182[12] = "yield-thread";
char constantarr_0_183[11] = "sched_yield";
char constantarr_0_184[16] = "ref-of-val<lock>";
char constantarr_0_185[2] = "lk";
char constantarr_0_186[18] = "try-gc-alloc-recur";
char constantarr_0_187[8] = "data-cur";
char constantarr_0_188[8] = "+<nat64>";
char constantarr_0_189[9] = "==<nat64>";
char constantarr_0_190[10] = "<=><nat64>";
char constantarr_0_191[10] = "is-less<a>";
char constantarr_0_192[17] = "<<mut-ptr<nat64>>";
char constantarr_0_193[8] = "data-end";
char constantarr_0_194[10] = "range-free";
char constantarr_0_195[8] = "mark-cur";
char constantarr_0_196[12] = "set-mark-cur";
char constantarr_0_197[12] = "set-data-cur";
char constantarr_0_198[19] = "some<mut-ptr<nat8>>";
char constantarr_0_199[21] = "ptr-cast<nat8, nat64>";
char constantarr_0_200[19] = "none<mut-ptr<nat8>>";
char constantarr_0_201[19] = "maybe-set-needs-gc!";
char constantarr_0_202[7] = "-<bool>";
char constantarr_0_203[10] = "mark-begin";
char constantarr_0_204[10] = "size-words";
char constantarr_0_205[12] = "set-needs-gc";
char constantarr_0_206[8] = "release!";
char constantarr_0_207[11] = "must-unset!";
char constantarr_0_208[10] = "try-unset!";
char constantarr_0_209[6] = "get-gc";
char constantarr_0_210[2] = "gc";
char constantarr_0_211[10] = "get-gc-ctx";
char constantarr_0_212[14] = "as-ref<gc-ctx>";
char constantarr_0_213[10] = "gc-ctx-ptr";
char constantarr_0_214[16] = "none<mut-ptr<a>>";
char constantarr_0_215[16] = "some<mut-ptr<a>>";
char constantarr_0_216[17] = "ptr-cast<a, nat8>";
char constantarr_0_217[20] = "none<backtrace-arrs>";
char constantarr_0_218[28] = "try-alloc-uninitialized<sym>";
char constantarr_0_219[51] = "try-alloc-uninitialized<named-val<const-ptr<nat8>>>";
char constantarr_0_220[32] = "size<named-val<const-ptr<nat8>>>";
char constantarr_0_221[8] = "all-funs";
char constantarr_0_222[20] = "some<backtrace-arrs>";
char constantarr_0_223[14] = "backtrace-arrs";
char constantarr_0_224[9] = "backtrace";
char constantarr_0_225[12] = "as<arr<sym>>";
char constantarr_0_226[15] = "unsafe-to-nat64";
char constantarr_0_227[8] = "to-int64";
char constantarr_0_228[9] = "code-ptrs";
char constantarr_0_229[15] = "unsafe-to-int32";
char constantarr_0_230[14] = "code-ptrs-size";
char constantarr_0_231[43] = "copy-data-from!<named-val<const-ptr<nat8>>>";
char constantarr_0_232[6] = "memcpy";
char constantarr_0_233[30] = "as-any-const-ptr<const-ptr<a>>";
char constantarr_0_234[4] = "funs";
char constantarr_0_235[37] = "begin-ptr<named-val<const-ptr<nat8>>>";
char constantarr_0_236[5] = "sort!";
char constantarr_0_237[33] = "swap!<named-val<const-ptr<nat8>>>";
char constantarr_0_238[12] = "subscript<a>";
char constantarr_0_239[16] = "set-subscript<a>";
char constantarr_0_240[12] = "set-deref<a>";
char constantarr_0_241[10] = "partition!";
char constantarr_0_242[9] = "<=><nat8>";
char constantarr_0_243[6] = "<=><a>";
char constantarr_0_244[18] = "<<const-ptr<nat8>>";
char constantarr_0_245[20] = "val<const-ptr<nat8>>";
char constantarr_0_246[6] = "+<sym>";
char constantarr_0_247[10] = "code-names";
char constantarr_0_248[16] = "fill-code-names!";
char constantarr_0_249[7] = "==<sym>";
char constantarr_0_250[8] = "<=><sym>";
char constantarr_0_251[15] = "<<mut-ptr<sym>>";
char constantarr_0_252[14] = "set-deref<sym>";
char constantarr_0_253[12] = "get-fun-name";
char constantarr_0_254[37] = "subscript<named-val<const-ptr<nat8>>>";
char constantarr_0_255[21] = "name<const-ptr<nat8>>";
char constantarr_0_256[18] = "*<const-ptr<nat8>>";
char constantarr_0_257[18] = "+<const-ptr<nat8>>";
char constantarr_0_258[8] = "arr<sym>";
char constantarr_0_259[13] = "as-const<sym>";
char constantarr_0_260[12] = "begin-ptr<a>";
char constantarr_0_261[14] = "set-backing<a>";
char constantarr_0_262[24] = "uninitialized-fix-arr<a>";
char constantarr_0_263[22] = "alloc-uninitialized<a>";
char constantarr_0_264[5] = "alloc";
char constantarr_0_265[8] = "gc-alloc";
char constantarr_0_266[19] = "todo<mut-ptr<nat8>>";
char constantarr_0_267[18] = "copy-data-from!<a>";
char constantarr_0_268[20] = "set-zero-elements<a>";
char constantarr_0_269[11] = "high<nat64>";
char constantarr_0_270[10] = "low<nat64>";
char constantarr_0_271[9] = "..<nat64>";
char constantarr_0_272[8] = "range<a>";
char constantarr_0_273[1] = "+";
char constantarr_0_274[2] = "&&";
char constantarr_0_275[9] = ">=<nat64>";
char constantarr_0_276[24] = "round-up-to-power-of-two";
char constantarr_0_277[30] = "round-up-to-power-of-two-recur";
char constantarr_0_278[1] = "*";
char constantarr_0_279[1] = "/";
char constantarr_0_280[6] = "forbid";
char constantarr_0_281[11] = "set-size<a>";
char constantarr_0_282[16] = "~=<char>.lambda0";
char constantarr_0_283[8] = "is-empty";
char constantarr_0_284[14] = "is-empty<char>";
char constantarr_0_285[7] = "message";
char constantarr_0_286[9] = "each<sym>";
char constantarr_0_287[12] = "return-stack";
char constantarr_0_288[3] = "str";
char constantarr_0_289[24] = "arr-from-begin-end<char>";
char constantarr_0_290[16] = "<=<const-ptr<a>>";
char constantarr_0_291[4] = "<<a>";
char constantarr_0_292[13] = "find-cstr-end";
char constantarr_0_293[17] = "find-char-in-cstr";
char constantarr_0_294[7] = "to-nat8";
char constantarr_0_295[21] = "some<const-ptr<char>>";
char constantarr_0_296[21] = "none<const-ptr<char>>";
char constantarr_0_297[33] = "hard-unreachable<const-ptr<char>>";
char constantarr_0_298[8] = "to-c-str";
char constantarr_0_299[14] = "to-str.lambda0";
char constantarr_0_300[12] = "move-to-str!";
char constantarr_0_301[18] = "move-to-arr!<char>";
char constantarr_0_302[17] = "cast-immutable<a>";
char constantarr_0_303[19] = "move-to-fix-arr!<a>";
char constantarr_0_304[28] = "set-any-unhandled-exceptions";
char constantarr_0_305[14] = "get-global-ctx";
char constantarr_0_306[18] = "as-ref<global-ctx>";
char constantarr_0_307[8] = "gctx-ptr";
char constantarr_0_308[14] = "island.lambda0";
char constantarr_0_309[19] = "default-log-handler";
char constantarr_0_310[5] = "print";
char constantarr_0_311[16] = "print-no-newline";
char constantarr_0_312[6] = "stdout";
char constantarr_0_313[7] = "~<char>";
char constantarr_0_314[5] = "level";
char constantarr_0_315[14] = "island.lambda1";
char constantarr_0_316[20] = "ptr-cast<bool, nat8>";
char constantarr_0_317[29] = "as-any-mut-ptr<mut-ptr<bool>>";
char constantarr_0_318[12] = "none<gc-ctx>";
char constantarr_0_319[11] = "validate-gc";
char constantarr_0_320[10] = "data-begin";
char constantarr_0_321[9] = "<=><bool>";
char constantarr_0_322[17] = "<=<mut-ptr<bool>>";
char constantarr_0_323[8] = "mark-end";
char constantarr_0_324[18] = "<=<mut-ptr<nat64>>";
char constantarr_0_325[14] = "ref-of-val<gc>";
char constantarr_0_326[19] = "thread-safe-counter";
char constantarr_0_327[18] = "ref-of-val<island>";
char constantarr_0_328[11] = "set-islands";
char constantarr_0_329[11] = "arr<island>";
char constantarr_0_330[14] = "ptr-to<island>";
char constantarr_0_331[13] = "add-main-task";
char constantarr_0_332[13] = "exception-ctx";
char constantarr_0_333[7] = "log-ctx";
char constantarr_0_334[26] = "zeroed<fun1<void, logged>>";
char constantarr_0_335[8] = "perf-ctx";
char constantarr_0_336[22] = "fix-arr<measure-value>";
char constantarr_0_337[29] = "as-any-mut-ptr<exception-ctx>";
char constantarr_0_338[25] = "ref-of-val<exception-ctx>";
char constantarr_0_339[23] = "as-any-mut-ptr<log-ctx>";
char constantarr_0_340[19] = "ref-of-val<log-ctx>";
char constantarr_0_341[24] = "as-any-mut-ptr<perf-ctx>";
char constantarr_0_342[20] = "ref-of-val<perf-ctx>";
char constantarr_0_343[10] = "print-lock";
char constantarr_0_344[3] = "ctx";
char constantarr_0_345[12] = "context-head";
char constantarr_0_346[23] = "size-of<by-val<gc-ctx>>";
char constantarr_0_347[6] = "set-gc";
char constantarr_0_348[12] = "set-next-ctx";
char constantarr_0_349[16] = "set-context-head";
char constantarr_0_350[8] = "next-ctx";
char constantarr_0_351[11] = "set-handler";
char constantarr_0_352[15] = "as-ref<log-ctx>";
char constantarr_0_353[11] = "log-ctx-ptr";
char constantarr_0_354[11] = "log-handler";
char constantarr_0_355[26] = "ref-of-val<island-gc-root>";
char constantarr_0_356[7] = "gc-root";
char constantarr_0_357[26] = "as-any-mut-ptr<global-ctx>";
char constantarr_0_358[2] = "id";
char constantarr_0_359[22] = "as-any-mut-ptr<gc-ctx>";
char constantarr_0_360[30] = "ref-of-val<thread-local-stuff>";
char constantarr_0_361[15] = "ref-of-val<ctx>";
char constantarr_0_362[14] = "add-first-task";
char constantarr_0_363[16] = "then-void<nat64>";
char constantarr_0_364[15] = "then<out, void>";
char constantarr_0_365[15] = "unresolved<out>";
char constantarr_0_366[6] = "fut<a>";
char constantarr_0_367[25] = "fut-state-no-callbacks<a>";
char constantarr_0_368[13] = "callback!<in>";
char constantarr_0_369[15] = "with-lock<void>";
char constantarr_0_370[16] = "call-with-ctx<r>";
char constantarr_0_371[5] = "lk<a>";
char constantarr_0_372[8] = "state<a>";
char constantarr_0_373[12] = "set-state<a>";
char constantarr_0_374[22] = "fut-state-callbacks<a>";
char constantarr_0_375[28] = "none<fut-state-callbacks<a>>";
char constantarr_0_376[28] = "some<fut-state-callbacks<a>>";
char constantarr_0_377[37] = "subscript<void, result<a, exception>>";
char constantarr_0_378[16] = "ok<a, exception>";
char constantarr_0_379[17] = "err<a, exception>";
char constantarr_0_380[21] = "callback!<in>.lambda0";
char constantarr_0_381[16] = "forward-to!<out>";
char constantarr_0_382[12] = "callback!<a>";
char constantarr_0_383[20] = "callback!<a>.lambda0";
char constantarr_0_384[21] = "resolve-or-reject!<a>";
char constantarr_0_385[23] = "with-lock<fut-state<a>>";
char constantarr_0_386[21] = "fut-state-resolved<a>";
char constantarr_0_387[22] = "fut-state-exception<a>";
char constantarr_0_388[29] = "resolve-or-reject!<a>.lambda0";
char constantarr_0_389[18] = "call-callbacks!<a>";
char constantarr_0_390[5] = "cb<a>";
char constantarr_0_391[7] = "next<a>";
char constantarr_0_392[24] = "forward-to!<out>.lambda0";
char constantarr_0_393[18] = "subscript<out, in>";
char constantarr_0_394[10] = "get-island";
char constantarr_0_395[17] = "subscript<island>";
char constantarr_0_396[12] = "unsafe-at<a>";
char constantarr_0_397[7] = "islands";
char constantarr_0_398[27] = "island-and-exclusion<r, p0>";
char constantarr_0_399[8] = "add-task";
char constantarr_0_400[15] = "task-queue-node";
char constantarr_0_401[4] = "task";
char constantarr_0_402[10] = "tasks-lock";
char constantarr_0_403[12] = "insert-task!";
char constantarr_0_404[4] = "size";
char constantarr_0_405[10] = "size-recur";
char constantarr_0_406[4] = "next";
char constantarr_0_407[4] = "head";
char constantarr_0_408[8] = "set-head";
char constantarr_0_409[21] = "some<task-queue-node>";
char constantarr_0_410[4] = "time";
char constantarr_0_411[12] = "insert-recur";
char constantarr_0_412[8] = "set-next";
char constantarr_0_413[5] = "tasks";
char constantarr_0_414[22] = "ref-of-val<task-queue>";
char constantarr_0_415[10] = "broadcast!";
char constantarr_0_416[18] = "pthread_mutex_lock";
char constantarr_0_417[22] = "pthread_cond_broadcast";
char constantarr_0_418[12] = "set-sequence";
char constantarr_0_419[8] = "sequence";
char constantarr_0_420[20] = "pthread_mutex_unlock";
char constantarr_0_421[17] = "may-be-work-to-do";
char constantarr_0_422[4] = "gctx";
char constantarr_0_423[12] = "no-timestamp";
char constantarr_0_424[9] = "exclusion";
char constantarr_0_425[11] = "catch<void>";
char constantarr_0_426[27] = "catch-with-exception-ctx<a>";
char constantarr_0_427[16] = "thrown-exception";
char constantarr_0_428[13] = "__jmp_buf_tag";
char constantarr_0_429[4] = "zero";
char constantarr_0_430[7] = "bytes64";
char constantarr_0_431[7] = "bytes32";
char constantarr_0_432[7] = "bytes16";
char constantarr_0_433[8] = "bytes128";
char constantarr_0_434[15] = "set-jmp-buf-ptr";
char constantarr_0_435[21] = "ptr-to<__jmp_buf_tag>";
char constantarr_0_436[6] = "setjmp";
char constantarr_0_437[23] = "subscript<a, exception>";
char constantarr_0_438[21] = "subscript<fut<r>, p0>";
char constantarr_0_439[10] = "fun<r, p0>";
char constantarr_0_440[34] = "subscript<out, in>.lambda0.lambda0";
char constantarr_0_441[10] = "reject!<r>";
char constantarr_0_442[34] = "subscript<out, in>.lambda0.lambda1";
char constantarr_0_443[26] = "subscript<out, in>.lambda0";
char constantarr_0_444[23] = "then<out, void>.lambda0";
char constantarr_0_445[14] = "subscript<out>";
char constantarr_0_446[23] = "island-and-exclusion<r>";
char constantarr_0_447[17] = "subscript<fut<r>>";
char constantarr_0_448[6] = "fun<r>";
char constantarr_0_449[30] = "subscript<out>.lambda0.lambda0";
char constantarr_0_450[30] = "subscript<out>.lambda0.lambda1";
char constantarr_0_451[22] = "subscript<out>.lambda0";
char constantarr_0_452[24] = "then-void<nat64>.lambda0";
char constantarr_0_453[24] = "cur-island-and-exclusion";
char constantarr_0_454[20] = "island-and-exclusion";
char constantarr_0_455[9] = "island-id";
char constantarr_0_456[5] = "delay";
char constantarr_0_457[14] = "resolved<void>";
char constantarr_0_458[21] = "tail<const-ptr<char>>";
char constantarr_0_459[11] = "is-empty<a>";
char constantarr_0_460[36] = "subscript<fut<nat64>, ctx, arr<str>>";
char constantarr_0_461[25] = "map<str, const-ptr<char>>";
char constantarr_0_462[13] = "make-arr<out>";
char constantarr_0_463[17] = "fill-ptr-range<a>";
char constantarr_0_464[23] = "fill-ptr-range-recur<a>";
char constantarr_0_465[9] = "!=<nat64>";
char constantarr_0_466[19] = "subscript<a, nat64>";
char constantarr_0_467[13] = "subscript<in>";
char constantarr_0_468[33] = "map<str, const-ptr<char>>.lambda0";
char constantarr_0_469[30] = "add-first-task.lambda0.lambda0";
char constantarr_0_470[22] = "add-first-task.lambda0";
char constantarr_0_471[24] = "handle-exceptions<nat64>";
char constantarr_0_472[26] = "subscript<void, exception>";
char constantarr_0_473[17] = "exception-handler";
char constantarr_0_474[14] = "get-cur-island";
char constantarr_0_475[32] = "handle-exceptions<nat64>.lambda0";
char constantarr_0_476[21] = "add-main-task.lambda0";
char constantarr_0_477[84] = "call-with-ctx<fut<nat64>, arr<const-ptr<char>>, fun-ptr2<fut<nat64>, ctx, arr<str>>>";
char constantarr_0_478[11] = "run-threads";
char constantarr_0_479[45] = "unmanaged-alloc-elements<by-val<thread-args>>";
char constantarr_0_480[19] = "start-threads-recur";
char constantarr_0_481[22] = "+<by-val<thread-args>>";
char constantarr_0_482[30] = "set-deref<by-val<thread-args>>";
char constantarr_0_483[11] = "thread-args";
char constantarr_0_484[17] = "create-one-thread";
char constantarr_0_485[14] = "pthread_create";
char constantarr_0_486[9] = "!=<int32>";
char constantarr_0_487[6] = "EAGAIN";
char constantarr_0_488[14] = "as-cell<nat64>";
char constantarr_0_489[15] = "as-ref<cell<a>>";
char constantarr_0_490[44] = "as-any-mut-ptr<mut-ptr<by-val<thread-args>>>";
char constantarr_0_491[10] = "thread-fun";
char constantarr_0_492[19] = "as-ref<thread-args>";
char constantarr_0_493[15] = "thread-function";
char constantarr_0_494[21] = "thread-function-recur";
char constantarr_0_495[12] = "is-shut-down";
char constantarr_0_496[18] = "set-n-live-threads";
char constantarr_0_497[14] = "n-live-threads";
char constantarr_0_498[28] = "assert-islands-are-shut-down";
char constantarr_0_499[16] = "noctx-at<island>";
char constantarr_0_500[11] = "hard-forbid";
char constantarr_0_501[8] = "needs-gc";
char constantarr_0_502[17] = "n-threads-running";
char constantarr_0_503[25] = "is-empty<task-queue-node>";
char constantarr_0_504[7] = "drop<a>";
char constantarr_0_505[12] = "get-sequence";
char constantarr_0_506[11] = "choose-task";
char constantarr_0_507[17] = "get-monotime-nsec";
char constantarr_0_508[14] = "cell<timespec>";
char constantarr_0_509[8] = "timespec";
char constantarr_0_510[13] = "clock_gettime";
char constantarr_0_511[26] = "ref-of-val<cell<timespec>>";
char constantarr_0_512[11] = "*<timespec>";
char constantarr_0_513[14] = "inner-value<a>";
char constantarr_0_514[6] = "tv-sec";
char constantarr_0_515[7] = "tv-nsec";
char constantarr_0_516[11] = "todo<nat64>";
char constantarr_0_517[17] = "choose-task-recur";
char constantarr_0_518[19] = "rslt-no-chosen-task";
char constantarr_0_519[14] = "no-chosen-task";
char constantarr_0_520[21] = "choose-task-in-island";
char constantarr_0_521[7] = "do-a-gc";
char constantarr_0_522[11] = "tii-no-task";
char constantarr_0_523[7] = "no-task";
char constantarr_0_524[11] = "none<nat64>";
char constantarr_0_525[9] = "pop-task!";
char constantarr_0_526[26] = "ref-of-val<mut-arr<nat64>>";
char constantarr_0_527[28] = "currently-running-exclusions";
char constantarr_0_528[11] = "ptr-no-task";
char constantarr_0_529[9] = "in<nat64>";
char constantarr_0_530[5] = "in<a>";
char constantarr_0_531[11] = "in-recur<a>";
char constantarr_0_532[11] = "noctx-at<a>";
char constantarr_0_533[14] = "temp-as-arr<a>";
char constantarr_0_534[18] = "temp-as-fix-arr<a>";
char constantarr_0_535[10] = "pop-recur!";
char constantarr_0_536[11] = "to-opt-time";
char constantarr_0_537[11] = "some<nat64>";
char constantarr_0_538[8] = "ptr-task";
char constantarr_0_539[40] = "push-capacity-must-be-sufficient!<nat64>";
char constantarr_0_540[8] = "tii-task";
char constantarr_0_541[10] = "is-no-task";
char constantarr_0_542[21] = "set-n-threads-running";
char constantarr_0_543[16] = "rslt-chosen-task";
char constantarr_0_544[11] = "chosen-task";
char constantarr_0_545[9] = "togc-task";
char constantarr_0_546[9] = "any-tasks";
char constantarr_0_547[8] = "min-time";
char constantarr_0_548[10] = "min<nat64>";
char constantarr_0_549[15] = "first-task-time";
char constantarr_0_550[28] = "no-tasks-and-last-thread-out";
char constantarr_0_551[7] = "do-task";
char constantarr_0_552[11] = "task-island";
char constantarr_0_553[10] = "task-or-gc";
char constantarr_0_554[6] = "action";
char constantarr_0_555[12] = "return-task!";
char constantarr_0_556[35] = "noctx-must-remove-unordered!<nat64>";
char constantarr_0_557[37] = "noctx-must-remove-unordered-recur!<a>";
char constantarr_0_558[29] = "noctx-remove-unordered-at!<a>";
char constantarr_0_559[10] = "return-ctx";
char constantarr_0_560[13] = "return-gc-ctx";
char constantarr_0_561[12] = "some<gc-ctx>";
char constantarr_0_562[46] = "run-garbage-collection<by-val<island-gc-root>>";
char constantarr_0_563[12] = "set-gc-count";
char constantarr_0_564[8] = "gc-count";
char constantarr_0_565[8] = "mark-ctx";
char constantarr_0_566[13] = "mark-visit<a>";
char constantarr_0_567[20] = "ref-of-val<mark-ctx>";
char constantarr_0_568[15] = "clear-free-mem!";
char constantarr_0_569[17] = "!=<mut-ptr<bool>>";
char constantarr_0_570[16] = "set-is-shut-down";
char constantarr_0_571[7] = "wait-on";
char constantarr_0_572[17] = "pthread_cond_wait";
char constantarr_0_573[11] = "to-timespec";
char constantarr_0_574[10] = "unsafe-mod";
char constantarr_0_575[22] = "pthread_cond_timedwait";
char constantarr_0_576[16] = "ptr-to<timespec>";
char constantarr_0_577[9] = "ETIMEDOUT";
char constantarr_0_578[9] = "thread-id";
char constantarr_0_579[18] = "join-threads-recur";
char constantarr_0_580[15] = "join-one-thread";
char constantarr_0_581[19] = "cell<mut-ptr<nat8>>";
char constantarr_0_582[12] = "pthread_join";
char constantarr_0_583[31] = "ref-of-val<cell<mut-ptr<nat8>>>";
char constantarr_0_584[6] = "EINVAL";
char constantarr_0_585[5] = "ESRCH";
char constantarr_0_586[16] = "*<mut-ptr<nat8>>";
char constantarr_0_587[21] = "unmanaged-free<nat64>";
char constantarr_0_588[4] = "free";
char constantarr_0_589[35] = "unmanaged-free<by-val<thread-args>>";
char constantarr_0_590[17] = "destroy-condition";
char constantarr_0_591[25] = "pthread_mutexattr_destroy";
char constantarr_0_592[21] = "pthread_mutex_destroy";
char constantarr_0_593[24] = "pthread_condattr_destroy";
char constantarr_0_594[20] = "pthread_cond_destroy";
char constantarr_0_595[24] = "any-unhandled-exceptions";
char constantarr_0_596[4] = "main";
char constantarr_0_597[3] = "log";
char constantarr_0_598[23] = "subscript<void, logged>";
char constantarr_0_599[15] = "get-log-handler";
char constantarr_0_600[7] = "handler";
char constantarr_0_601[11] = "get-log-ctx";
char constantarr_0_602[6] = "logged";
char constantarr_0_603[12] = "main.lambda0";
char constantarr_0_604[22] = "with-log-handler<void>";
char constantarr_0_605[15] = "set-log-handler";
char constantarr_0_606[30] = "with-log-handler<void>.lambda0";
char constantarr_0_607[30] = "with-log-handler<void>.lambda1";
char constantarr_0_608[12] = "main.lambda1";
char constantarr_0_609[12] = "main.lambda2";
char constantarr_0_610[12] = "main.lambda3";
char constantarr_0_611[15] = "resolved<nat64>";
char constantarr_0_612[11] = "static-syms";
struct named_val constantarr_5_0[346] = {{{"mark"}, ((uint8_t*)mark)}, {{"hard-assert"}, ((uint8_t*)hard_assert)}, {{"is-word-aligned"}, ((uint8_t*)is_word_aligned_0)}, {{"is-word-aligned"}, ((uint8_t*)is_word_aligned_1)}, {{"words-of-bytes"}, ((uint8_t*)words_of_bytes)}, {{"round-up-to-multiple-of-8"}, ((uint8_t*)round_up_to_multiple_of_8)}, {{"ptr-cast"}, ((uint8_t*)ptr_cast)}, {{"-"}, ((uint8_t*)_minus_0)}, {{"-"}, ((uint8_t*)_minus_1)}, {{"<=>"}, ((uint8_t*)_compare_0)}, {{"cmp"}, ((uint8_t*)cmp)}, {{"<"}, ((uint8_t*)_less_0)}, {{"<="}, ((uint8_t*)_lessOrEqual_0)}, {{"!"}, ((uint8_t*)_not)}, {{"mark-range-recur"}, ((uint8_t*)mark_range_recur)}, {{">"}, ((uint8_t*)_greater)}, {{"rt-main"}, ((uint8_t*)rt_main)}, {{"lbv"}, ((uint8_t*)lbv)}, {{"lock-by-val"}, ((uint8_t*)lock_by_val)}, {{"atomic-bool"}, ((uint8_t*)_atomic_bool)}, {{"create-condition"}, ((uint8_t*)create_condition)}, {{"hard-assert-posix-error"}, ((uint8_t*)hard_assert_posix_error)}, {{"CLOCK_MONOTONIC"}, ((uint8_t*)CLOCK_MONOTONIC)}, {{"island"}, ((uint8_t*)island)}, {{"task-queue"}, ((uint8_t*)task_queue)}, {{"mut-arr-by-val-with-capacity-from-unmanaged-memory"}, ((uint8_t*)mut_arr_by_val_with_capacity_from_unmanaged_memory)}, {{"fix-arr"}, ((uint8_t*)fix_arr_0)}, {{"unmanaged-alloc-zeroed-elements"}, ((uint8_t*)unmanaged_alloc_zeroed_elements)}, {{"unmanaged-alloc-elements"}, ((uint8_t*)unmanaged_alloc_elements_0)}, {{"unmanaged-alloc-bytes"}, ((uint8_t*)unmanaged_alloc_bytes)}, {{"!="}, ((uint8_t*)_notEqual_0)}, {{"set-zero-range"}, ((uint8_t*)set_zero_range_0)}, {{"drop"}, ((uint8_t*)drop_0)}, {{"default-exception-handler"}, ((uint8_t*)default_exception_handler)}, {{"print-err-no-newline"}, ((uint8_t*)print_err_no_newline)}, {{"write-no-newline"}, ((uint8_t*)write_no_newline)}, {{"as-any-const-ptr"}, ((uint8_t*)as_any_const_ptr_0)}, {{"size-bytes"}, ((uint8_t*)size_bytes)}, {{"!="}, ((uint8_t*)_notEqual_1)}, {{"todo"}, ((uint8_t*)todo_0)}, {{"stderr"}, ((uint8_t*)stderr)}, {{"print-err"}, ((uint8_t*)print_err)}, {{"to-str"}, ((uint8_t*)to_str_0)}, {{"writer"}, ((uint8_t*)writer)}, {{"mut-arr"}, ((uint8_t*)mut_arr)}, {{"fix-arr"}, ((uint8_t*)fix_arr_1)}, {{"~="}, ((uint8_t*)_concatEquals_0)}, {{"~="}, ((uint8_t*)_concatEquals_1)}, {{"each"}, ((uint8_t*)each_0)}, {{"each-recur"}, ((uint8_t*)each_recur_0)}, {{"=="}, ((uint8_t*)_equal_0)}, {{"!="}, ((uint8_t*)_notEqual_2)}, {{"subscript"}, ((uint8_t*)subscript_0)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_63)}, {{"*"}, ((uint8_t*)_times_0)}, {{"+"}, ((uint8_t*)_plus_0)}, {{"end-ptr"}, ((uint8_t*)end_ptr_0)}, {{"~="}, ((uint8_t*)_concatEquals_2)}, {{"incr-capacity!"}, ((uint8_t*)incr_capacity__e)}, {{"ensure-capacity"}, ((uint8_t*)ensure_capacity)}, {{"capacity"}, ((uint8_t*)capacity_0)}, {{"size"}, ((uint8_t*)size_0)}, {{"increase-capacity-to!"}, ((uint8_t*)increase_capacity_to__e)}, {{"assert"}, ((uint8_t*)assert)}, {{"throw"}, ((uint8_t*)throw_0)}, {{"throw"}, ((uint8_t*)throw_1)}, {{"get-exception-ctx"}, ((uint8_t*)get_exception_ctx)}, {{"!="}, ((uint8_t*)_notEqual_3)}, {{"number-to-throw"}, ((uint8_t*)number_to_throw)}, {{"hard-unreachable"}, ((uint8_t*)hard_unreachable_0)}, {{"get-backtrace"}, ((uint8_t*)get_backtrace)}, {{"try-alloc-backtrace-arrs"}, ((uint8_t*)try_alloc_backtrace_arrs)}, {{"try-alloc-uninitialized"}, ((uint8_t*)try_alloc_uninitialized_0)}, {{"try-alloc"}, ((uint8_t*)try_alloc)}, {{"try-gc-alloc"}, ((uint8_t*)try_gc_alloc)}, {{"acquire!"}, ((uint8_t*)acquire__e)}, {{"acquire-recur!"}, ((uint8_t*)acquire_recur__e)}, {{"try-acquire!"}, ((uint8_t*)try_acquire__e)}, {{"try-set!"}, ((uint8_t*)try_set__e)}, {{"try-change!"}, ((uint8_t*)try_change__e)}, {{"yield-thread"}, ((uint8_t*)yield_thread)}, {{"try-gc-alloc-recur"}, ((uint8_t*)try_gc_alloc_recur)}, {{"<=>"}, ((uint8_t*)_compare_1)}, {{"<"}, ((uint8_t*)_less_1)}, {{"range-free"}, ((uint8_t*)range_free)}, {{"maybe-set-needs-gc!"}, ((uint8_t*)maybe_set_needs_gc__e)}, {{"-"}, ((uint8_t*)_minus_2)}, {{"release!"}, ((uint8_t*)release__e)}, {{"must-unset!"}, ((uint8_t*)must_unset__e)}, {{"try-unset!"}, ((uint8_t*)try_unset__e)}, {{"get-gc"}, ((uint8_t*)get_gc)}, {{"get-gc-ctx"}, ((uint8_t*)get_gc_ctx_0)}, {{"try-alloc-uninitialized"}, ((uint8_t*)try_alloc_uninitialized_1)}, {{"try-alloc-uninitialized"}, ((uint8_t*)try_alloc_uninitialized_2)}, {{"code-ptrs-size"}, ((uint8_t*)code_ptrs_size)}, {{"copy-data-from!"}, ((uint8_t*)copy_data_from__e_0)}, {{"as-any-const-ptr"}, ((uint8_t*)as_any_const_ptr_1)}, {{"sort!"}, ((uint8_t*)sort__e)}, {{"swap!"}, ((uint8_t*)swap__e)}, {{"subscript"}, ((uint8_t*)subscript_1)}, {{"set-subscript"}, ((uint8_t*)set_subscript_0)}, {{"partition!"}, ((uint8_t*)partition__e)}, {{"=="}, ((uint8_t*)_equal_1)}, {{"<=>"}, ((uint8_t*)_compare_2)}, {{"<=>"}, ((uint8_t*)_compare_3)}, {{"<"}, ((uint8_t*)_less_2)}, {{"fill-code-names!"}, ((uint8_t*)fill_code_names__e)}, {{"<=>"}, ((uint8_t*)_compare_4)}, {{"<"}, ((uint8_t*)_less_3)}, {{"get-fun-name"}, ((uint8_t*)get_fun_name)}, {{"subscript"}, ((uint8_t*)subscript_2)}, {{"*"}, ((uint8_t*)_times_1)}, {{"+"}, ((uint8_t*)_plus_1)}, {{"*"}, ((uint8_t*)_times_2)}, {{"+"}, ((uint8_t*)_plus_2)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_0)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_1)}, {{"uninitialized-fix-arr"}, ((uint8_t*)uninitialized_fix_arr)}, {{"fix-arr"}, ((uint8_t*)fix_arr_2)}, {{"alloc-uninitialized"}, ((uint8_t*)alloc_uninitialized_0)}, {{"alloc"}, ((uint8_t*)alloc)}, {{"gc-alloc"}, ((uint8_t*)gc_alloc)}, {{"todo"}, ((uint8_t*)todo_1)}, {{"copy-data-from!"}, ((uint8_t*)copy_data_from__e_1)}, {{"set-zero-elements"}, ((uint8_t*)set_zero_elements)}, {{"set-zero-range"}, ((uint8_t*)set_zero_range_1)}, {{"subscript"}, ((uint8_t*)subscript_3)}, {{"subscript"}, ((uint8_t*)subscript_4)}, {{".."}, ((uint8_t*)_range)}, {{"+"}, ((uint8_t*)_plus_3)}, {{">="}, ((uint8_t*)_greaterOrEqual)}, {{"round-up-to-power-of-two"}, ((uint8_t*)round_up_to_power_of_two)}, {{"round-up-to-power-of-two-recur"}, ((uint8_t*)round_up_to_power_of_two_recur)}, {{"*"}, ((uint8_t*)_times_3)}, {{"/"}, ((uint8_t*)_divide)}, {{"forbid"}, ((uint8_t*)forbid)}, {{"set-subscript"}, ((uint8_t*)set_subscript_1)}, {{"is-empty"}, ((uint8_t*)is_empty_0)}, {{"is-empty"}, ((uint8_t*)is_empty_1)}, {{"each"}, ((uint8_t*)each_1)}, {{"each-recur"}, ((uint8_t*)each_recur_1)}, {{"=="}, ((uint8_t*)_equal_2)}, {{"!="}, ((uint8_t*)_notEqual_4)}, {{"subscript"}, ((uint8_t*)subscript_5)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_159)}, {{"*"}, ((uint8_t*)_times_4)}, {{"+"}, ((uint8_t*)_plus_4)}, {{"end-ptr"}, ((uint8_t*)end_ptr_1)}, {{"~="}, ((uint8_t*)_concatEquals_3)}, {{"to-str"}, ((uint8_t*)to_str_1)}, {{"arr-from-begin-end"}, ((uint8_t*)arr_from_begin_end)}, {{"<=>"}, ((uint8_t*)_compare_5)}, {{"<=>"}, ((uint8_t*)_compare_6)}, {{"<="}, ((uint8_t*)_lessOrEqual_1)}, {{"<"}, ((uint8_t*)_less_4)}, {{"-"}, ((uint8_t*)_minus_3)}, {{"-"}, ((uint8_t*)_minus_4)}, {{"find-cstr-end"}, ((uint8_t*)find_cstr_end)}, {{"find-char-in-cstr"}, ((uint8_t*)find_char_in_cstr)}, {{"=="}, ((uint8_t*)_equal_3)}, {{"hard-unreachable"}, ((uint8_t*)hard_unreachable_1)}, {{"move-to-str!"}, ((uint8_t*)move_to_str__e)}, {{"move-to-arr!"}, ((uint8_t*)move_to_arr__e)}, {{"cast-immutable"}, ((uint8_t*)cast_immutable)}, {{"move-to-fix-arr!"}, ((uint8_t*)move_to_fix_arr__e)}, {{"get-global-ctx"}, ((uint8_t*)get_global_ctx)}, {{"default-log-handler"}, ((uint8_t*)default_log_handler)}, {{"print"}, ((uint8_t*)print)}, {{"print-no-newline"}, ((uint8_t*)print_no_newline)}, {{"stdout"}, ((uint8_t*)stdout)}, {{"~"}, ((uint8_t*)_tilde_0)}, {{"~"}, ((uint8_t*)_tilde_1)}, {{"to-str"}, ((uint8_t*)to_str_2)}, {{"gc"}, ((uint8_t*)gc)}, {{"validate-gc"}, ((uint8_t*)validate_gc)}, {{"<=>"}, ((uint8_t*)_compare_7)}, {{"<="}, ((uint8_t*)_lessOrEqual_2)}, {{"<"}, ((uint8_t*)_less_5)}, {{"<="}, ((uint8_t*)_lessOrEqual_3)}, {{"thread-safe-counter"}, ((uint8_t*)thread_safe_counter_0)}, {{"thread-safe-counter"}, ((uint8_t*)thread_safe_counter_1)}, {{"add-main-task"}, ((uint8_t*)add_main_task)}, {{"exception-ctx"}, ((uint8_t*)exception_ctx)}, {{"log-ctx"}, ((uint8_t*)log_ctx)}, {{"perf-ctx"}, ((uint8_t*)perf_ctx)}, {{"fix-arr"}, ((uint8_t*)fix_arr_3)}, {{"ctx"}, ((uint8_t*)ctx)}, {{"get-gc-ctx"}, ((uint8_t*)get_gc_ctx_1)}, {{"add-first-task"}, ((uint8_t*)add_first_task)}, {{"then-void"}, ((uint8_t*)then_void)}, {{"then"}, ((uint8_t*)then)}, {{"unresolved"}, ((uint8_t*)unresolved)}, {{"callback!"}, ((uint8_t*)callback__e_0)}, {{"with-lock"}, ((uint8_t*)with_lock_0)}, {{"subscript"}, ((uint8_t*)subscript_6)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_213)}, {{"subscript"}, ((uint8_t*)subscript_7)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_215)}, {{"forward-to!"}, ((uint8_t*)forward_to__e)}, {{"callback!"}, ((uint8_t*)callback__e_1)}, {{"subscript"}, ((uint8_t*)subscript_8)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_220)}, {{"resolve-or-reject!"}, ((uint8_t*)resolve_or_reject__e)}, {{"with-lock"}, ((uint8_t*)with_lock_1)}, {{"subscript"}, ((uint8_t*)subscript_9)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_225)}, {{"call-callbacks!"}, ((uint8_t*)call_callbacks__e)}, {{"subscript"}, ((uint8_t*)subscript_10)}, {{"get-island"}, ((uint8_t*)get_island)}, {{"subscript"}, ((uint8_t*)subscript_11)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_0)}, {{"subscript"}, ((uint8_t*)subscript_12)}, {{"*"}, ((uint8_t*)_times_5)}, {{"+"}, ((uint8_t*)_plus_5)}, {{"add-task"}, ((uint8_t*)add_task_0)}, {{"add-task"}, ((uint8_t*)add_task_1)}, {{"task-queue-node"}, ((uint8_t*)task_queue_node)}, {{"insert-task!"}, ((uint8_t*)insert_task__e)}, {{"size"}, ((uint8_t*)size_1)}, {{"size-recur"}, ((uint8_t*)size_recur)}, {{"insert-recur"}, ((uint8_t*)insert_recur)}, {{"tasks"}, ((uint8_t*)tasks)}, {{"broadcast!"}, ((uint8_t*)broadcast__e)}, {{"no-timestamp"}, ((uint8_t*)no_timestamp)}, {{"catch"}, ((uint8_t*)catch)}, {{"catch-with-exception-ctx"}, ((uint8_t*)catch_with_exception_ctx)}, {{"zero"}, ((uint8_t*)zero_0)}, {{"zero"}, ((uint8_t*)zero_1)}, {{"zero"}, ((uint8_t*)zero_2)}, {{"zero"}, ((uint8_t*)zero_3)}, {{"subscript"}, ((uint8_t*)subscript_13)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_257)}, {{"subscript"}, ((uint8_t*)subscript_14)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_259)}, {{"reject!"}, ((uint8_t*)reject__e)}, {{"subscript"}, ((uint8_t*)subscript_15)}, {{"subscript"}, ((uint8_t*)subscript_16)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_267)}, {{"cur-island-and-exclusion"}, ((uint8_t*)cur_island_and_exclusion)}, {{"delay"}, ((uint8_t*)delay)}, {{"resolved"}, ((uint8_t*)resolved_0)}, {{"tail"}, ((uint8_t*)tail)}, {{"is-empty"}, ((uint8_t*)is_empty_2)}, {{"subscript"}, ((uint8_t*)subscript_17)}, {{"+"}, ((uint8_t*)_plus_6)}, {{"map"}, ((uint8_t*)map)}, {{"make-arr"}, ((uint8_t*)make_arr)}, {{"alloc-uninitialized"}, ((uint8_t*)alloc_uninitialized_1)}, {{"fill-ptr-range"}, ((uint8_t*)fill_ptr_range)}, {{"fill-ptr-range-recur"}, ((uint8_t*)fill_ptr_range_recur)}, {{"!="}, ((uint8_t*)_notEqual_5)}, {{"set-subscript"}, ((uint8_t*)set_subscript_2)}, {{"subscript"}, ((uint8_t*)subscript_18)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_287)}, {{"subscript"}, ((uint8_t*)subscript_19)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_289)}, {{"subscript"}, ((uint8_t*)subscript_20)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_1)}, {{"subscript"}, ((uint8_t*)subscript_21)}, {{"*"}, ((uint8_t*)_times_6)}, {{"handle-exceptions"}, ((uint8_t*)handle_exceptions)}, {{"subscript"}, ((uint8_t*)subscript_22)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_299)}, {{"exception-handler"}, ((uint8_t*)exception_handler)}, {{"get-cur-island"}, ((uint8_t*)get_cur_island)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_304)}, {{"run-threads"}, ((uint8_t*)run_threads)}, {{"unmanaged-alloc-elements"}, ((uint8_t*)unmanaged_alloc_elements_1)}, {{"start-threads-recur"}, ((uint8_t*)start_threads_recur)}, {{"create-one-thread"}, ((uint8_t*)create_one_thread)}, {{"null"}, ((uint8_t*)null)}, {{"!="}, ((uint8_t*)_notEqual_6)}, {{"EAGAIN"}, ((uint8_t*)EAGAIN)}, {{"as-cell"}, ((uint8_t*)as_cell)}, {{"thread-fun"}, ((uint8_t*)thread_fun)}, {{"thread-function"}, ((uint8_t*)thread_function)}, {{"thread-function-recur"}, ((uint8_t*)thread_function_recur)}, {{"assert-islands-are-shut-down"}, ((uint8_t*)assert_islands_are_shut_down)}, {{"noctx-at"}, ((uint8_t*)noctx_at_0)}, {{"hard-forbid"}, ((uint8_t*)hard_forbid)}, {{"is-empty"}, ((uint8_t*)is_empty_3)}, {{"is-empty"}, ((uint8_t*)is_empty_4)}, {{"drop"}, ((uint8_t*)drop_1)}, {{"get-sequence"}, ((uint8_t*)get_sequence)}, {{"choose-task"}, ((uint8_t*)choose_task)}, {{"get-monotime-nsec"}, ((uint8_t*)get_monotime_nsec)}, {{"*"}, ((uint8_t*)_times_7)}, {{"todo"}, ((uint8_t*)todo_2)}, {{"choose-task-recur"}, ((uint8_t*)choose_task_recur)}, {{"choose-task-in-island"}, ((uint8_t*)choose_task_in_island)}, {{"pop-task!"}, ((uint8_t*)pop_task__e)}, {{"in"}, ((uint8_t*)in_0)}, {{"in"}, ((uint8_t*)in_1)}, {{"in-recur"}, ((uint8_t*)in_recur)}, {{"noctx-at"}, ((uint8_t*)noctx_at_1)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_2)}, {{"subscript"}, ((uint8_t*)subscript_23)}, {{"*"}, ((uint8_t*)_times_8)}, {{"+"}, ((uint8_t*)_plus_7)}, {{"temp-as-arr"}, ((uint8_t*)temp_as_arr_0)}, {{"temp-as-arr"}, ((uint8_t*)temp_as_arr_1)}, {{"temp-as-fix-arr"}, ((uint8_t*)temp_as_fix_arr)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_2)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_3)}, {{"pop-recur!"}, ((uint8_t*)pop_recur__e)}, {{"to-opt-time"}, ((uint8_t*)to_opt_time)}, {{"push-capacity-must-be-sufficient!"}, ((uint8_t*)push_capacity_must_be_sufficient__e)}, {{"capacity"}, ((uint8_t*)capacity_1)}, {{"size"}, ((uint8_t*)size_2)}, {{"set-subscript"}, ((uint8_t*)set_subscript_3)}, {{"is-no-task"}, ((uint8_t*)is_no_task)}, {{"min-time"}, ((uint8_t*)min_time)}, {{"min"}, ((uint8_t*)min)}, {{"do-task"}, ((uint8_t*)do_task)}, {{"return-task!"}, ((uint8_t*)return_task__e)}, {{"noctx-must-remove-unordered!"}, ((uint8_t*)noctx_must_remove_unordered__e)}, {{"noctx-must-remove-unordered-recur!"}, ((uint8_t*)noctx_must_remove_unordered_recur__e)}, {{"subscript"}, ((uint8_t*)subscript_24)}, {{"drop"}, ((uint8_t*)drop_2)}, {{"noctx-remove-unordered-at!"}, ((uint8_t*)noctx_remove_unordered_at__e)}, {{"return-ctx"}, ((uint8_t*)return_ctx)}, {{"return-gc-ctx"}, ((uint8_t*)return_gc_ctx)}, {{"run-garbage-collection"}, ((uint8_t*)run_garbage_collection)}, {{"mark-visit"}, ((uint8_t*)mark_visit_364)}, {{"clear-free-mem!"}, ((uint8_t*)clear_free_mem__e)}, {{"!="}, ((uint8_t*)_notEqual_7)}, {{"wait-on"}, ((uint8_t*)wait_on)}, {{"to-timespec"}, ((uint8_t*)to_timespec)}, {{"ETIMEDOUT"}, ((uint8_t*)ETIMEDOUT)}, {{"join-threads-recur"}, ((uint8_t*)join_threads_recur)}, {{"join-one-thread"}, ((uint8_t*)join_one_thread)}, {{"EINVAL"}, ((uint8_t*)EINVAL)}, {{"ESRCH"}, ((uint8_t*)ESRCH)}, {{"*"}, ((uint8_t*)_times_9)}, {{"unmanaged-free"}, ((uint8_t*)unmanaged_free_0)}, {{"unmanaged-free"}, ((uint8_t*)unmanaged_free_1)}, {{"destroy-condition"}, ((uint8_t*)destroy_condition)}, {{"main"}, ((uint8_t*)main_0)}, {{"log"}, ((uint8_t*)log)}, {{"subscript"}, ((uint8_t*)subscript_25)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_447)}, {{"get-log-handler"}, ((uint8_t*)get_log_handler)}, {{"get-log-ctx"}, ((uint8_t*)get_log_ctx)}, {{"with-log-handler"}, ((uint8_t*)with_log_handler)}, {{"set-log-handler"}, ((uint8_t*)set_log_handler)}, {{"resolved"}, ((uint8_t*)resolved_1)}};
struct sym constantarr_1_0[210] = {{"<<UNKNOWN>>"}, {"mark"}, {"hard-assert"}, {"is-word-aligned"}, {"words-of-bytes"}, {"round-up-to-multiple-of-8"}, {"ptr-cast"}, {"-"}, {"<=>"}, {"cmp"}, {"<"}, {"<="}, {"!"}, {"mark-range-recur"}, {">"}, {"rt-main"}, {"lbv"}, {"lock-by-val"}, {"atomic-bool"}, {"create-condition"}, {"hard-assert-posix-error"}, {"CLOCK_MONOTONIC"}, {"island"}, {"task-queue"}, {"mut-arr-by-val-with-capacity-from-unmanaged-memory"}, {"fix-arr"}, {"unmanaged-alloc-zeroed-elements"}, {"unmanaged-alloc-elements"}, {"unmanaged-alloc-bytes"}, {"!="}, {"set-zero-range"}, {"drop"}, {"default-exception-handler"}, {"print-err-no-newline"}, {"write-no-newline"}, {"as-any-const-ptr"}, {"size-bytes"}, {"todo"}, {"stderr"}, {"print-err"}, {"to-str"}, {"writer"}, {"mut-arr"}, {"~="}, {"each"}, {"each-recur"}, {"=="}, {"subscript"}, {"call-with-ctx"}, {"*"}, {"+"}, {"end-ptr"}, {"incr-capacity!"}, {"ensure-capacity"}, {"capacity"}, {"size"}, {"increase-capacity-to!"}, {"assert"}, {"throw"}, {"get-exception-ctx"}, {"number-to-throw"}, {"hard-unreachable"}, {"get-backtrace"}, {"try-alloc-backtrace-arrs"}, {"try-alloc-uninitialized"}, {"try-alloc"}, {"try-gc-alloc"}, {"acquire!"}, {"acquire-recur!"}, {"try-acquire!"}, {"try-set!"}, {"try-change!"}, {"yield-thread"}, {"try-gc-alloc-recur"}, {"range-free"}, {"maybe-set-needs-gc!"}, {"release!"}, {"must-unset!"}, {"try-unset!"}, {"get-gc"}, {"get-gc-ctx"}, {"code-ptrs-size"}, {"copy-data-from!"}, {"sort!"}, {"swap!"}, {"set-subscript"}, {"partition!"}, {"fill-code-names!"}, {"get-fun-name"}, {"begin-ptr"}, {"uninitialized-fix-arr"}, {"alloc-uninitialized"}, {"alloc"}, {"gc-alloc"}, {"set-zero-elements"}, {".."}, {">="}, {"round-up-to-power-of-two"}, {"round-up-to-power-of-two-recur"}, {"/"}, {"forbid"}, {"is-empty"}, {"arr-from-begin-end"}, {"find-cstr-end"}, {"find-char-in-cstr"}, {"move-to-str!"}, {"move-to-arr!"}, {"cast-immutable"}, {"move-to-fix-arr!"}, {"get-global-ctx"}, {"default-log-handler"}, {"print"}, {"print-no-newline"}, {"stdout"}, {"~"}, {"gc"}, {"validate-gc"}, {"thread-safe-counter"}, {"add-main-task"}, {"exception-ctx"}, {"log-ctx"}, {"perf-ctx"}, {"ctx"}, {"add-first-task"}, {"then-void"}, {"then"}, {"unresolved"}, {"callback!"}, {"with-lock"}, {"forward-to!"}, {"resolve-or-reject!"}, {"call-callbacks!"}, {"get-island"}, {"unsafe-at"}, {"add-task"}, {"task-queue-node"}, {"insert-task!"}, {"size-recur"}, {"insert-recur"}, {"tasks"}, {"broadcast!"}, {"no-timestamp"}, {"catch"}, {"catch-with-exception-ctx"}, {"zero"}, {"reject!"}, {"cur-island-and-exclusion"}, {"delay"}, {"resolved"}, {"tail"}, {"map"}, {"make-arr"}, {"fill-ptr-range"}, {"fill-ptr-range-recur"}, {"handle-exceptions"}, {"exception-handler"}, {"get-cur-island"}, {"run-threads"}, {"start-threads-recur"}, {"create-one-thread"}, {"null"}, {"EAGAIN"}, {"as-cell"}, {"thread-fun"}, {"thread-function"}, {"thread-function-recur"}, {"assert-islands-are-shut-down"}, {"noctx-at"}, {"hard-forbid"}, {"get-sequence"}, {"choose-task"}, {"get-monotime-nsec"}, {"choose-task-recur"}, {"choose-task-in-island"}, {"pop-task!"}, {"in"}, {"in-recur"}, {"temp-as-arr"}, {"temp-as-fix-arr"}, {"pop-recur!"}, {"to-opt-time"}, {"push-capacity-must-be-sufficient!"}, {"is-no-task"}, {"min-time"}, {"min"}, {"do-task"}, {"return-task!"}, {"noctx-must-remove-unordered!"}, {"noctx-must-remove-unordered-recur!"}, {"noctx-remove-unordered-at!"}, {"return-ctx"}, {"return-gc-ctx"}, {"run-garbage-collection"}, {"mark-visit"}, {"clear-free-mem!"}, {"wait-on"}, {"to-timespec"}, {"ETIMEDOUT"}, {"join-threads-recur"}, {"join-one-thread"}, {"EINVAL"}, {"ESRCH"}, {"unmanaged-free"}, {"destroy-condition"}, {"main"}, {"log"}, {"get-log-handler"}, {"get-log-ctx"}, {"with-log-handler"}, {"set-log-handler"}};
/* mark bool(ctx mark-ctx, ptr-any const-ptr<nat8>, size-bytes nat64) */
uint8_t mark(struct mark_ctx* ctx, uint8_t* ptr_any, uint64_t size_bytes) {
	uint8_t _0 = is_word_aligned_0(ptr_any);
	hard_assert(_0);
	uint64_t size_words0;
	size_words0 = words_of_bytes(size_bytes);
	
	uint64_t* ptr1;
	ptr1 = ptr_cast(ptr_any);
	
	uint64_t index2;
	index2 = _minus_0(ptr1, ((uint64_t*) ctx->memory_start));
	
	uint8_t _1 = _less_0(index2, ctx->memory_size_words);
	if (_1) {
		uint8_t _2 = _lessOrEqual_0((index2 + size_words0), ctx->memory_size_words);
		hard_assert(_2);
		uint8_t* mark_start3;
		mark_start3 = (ctx->marks + index2);
		
		uint8_t* mark_end4;
		mark_end4 = (mark_start3 + size_words0);
		
		return mark_range_recur(0, mark_start3, mark_end4);
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
/* is-word-aligned bool(a const-ptr<nat8>) */
uint8_t is_word_aligned_0(uint8_t* a) {
	return is_word_aligned_1(((uint8_t*) a));
}
/* is-word-aligned bool(a mut-ptr<nat8>) */
uint8_t is_word_aligned_1(uint8_t* a) {
	return ((((uint64_t) a) & 7u) == 0u);
}
/* words-of-bytes nat64(size-bytes nat64) */
uint64_t words_of_bytes(uint64_t size_bytes) {
	uint64_t _0 = round_up_to_multiple_of_8(size_bytes);
	return (_0 / 8u);
}
/* round-up-to-multiple-of-8 nat64(n nat64) */
uint64_t round_up_to_multiple_of_8(uint64_t n) {
	return ((n + 7u) & (~7u));
}
/* ptr-cast<nat64, nat8> const-ptr<nat64>(a const-ptr<nat8>) */
uint64_t* ptr_cast(uint8_t* a) {
	return ((uint64_t*) ((uint64_t*) ((uint8_t*) a)));
}
/* -<nat64> nat64(a const-ptr<nat64>, b const-ptr<nat64>) */
uint64_t _minus_0(uint64_t* a, uint64_t* b) {
	return _minus_1(((uint64_t*) a), ((uint64_t*) b));
}
/* -<a> nat64(a mut-ptr<nat64>, b mut-ptr<nat64>) */
uint64_t _minus_1(uint64_t* a, uint64_t* b) {
	return ((((uint64_t) a) - ((uint64_t) b)) / sizeof(uint64_t));
}
/* <=> comparison(a nat64, b nat64) */
uint32_t _compare_0(uint64_t a, uint64_t b) {
	return cmp(a, b);
}
/* cmp<nat64> comparison(a nat64, b nat64) */
uint32_t cmp(uint64_t a, uint64_t b) {
	uint8_t _0 = (a < b);
	if (_0) {
		return 0u;
	} else {
		uint8_t _1 = (a == b);
		if (_1) {
			return 1u;
		} else {
			return 2u;
		}
	}
}
/* <<nat64> bool(a nat64, b nat64) */
uint8_t _less_0(uint64_t a, uint64_t b) {
	uint32_t _0 = _compare_0(a, b);switch (_0) {
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
			return 0;
	}
}
/* <=<nat64> bool(a nat64, b nat64) */
uint8_t _lessOrEqual_0(uint64_t a, uint64_t b) {
	uint8_t _0 = _less_0(b, a);
	return _not(_0);
}
/* ! bool(a bool) */
uint8_t _not(uint8_t a) {
	uint8_t _0 = a;
	if (_0) {
		return 0;
	} else {
		return 1;
	}
}
/* mark-range-recur bool(marked-anything bool, cur mut-ptr<bool>, end mut-ptr<bool>) */
uint8_t mark_range_recur(uint8_t marked_anything, uint8_t* cur, uint8_t* end) {
	top:;
	uint8_t _0 = (cur == end);
	if (_0) {
		return marked_anything;
	} else {
		uint8_t new_marked_anything0;
		if (marked_anything) {
			new_marked_anything0 = 1;
		} else {
			new_marked_anything0 = _not((*cur));
		}
		
		*cur = 1;
		marked_anything = new_marked_anything0;
		cur = (cur + 1u);
		end = end;
		goto top;
	}
}
/* ><nat64> bool(a nat64, b nat64) */
uint8_t _greater(uint64_t a, uint64_t b) {
	return _less_0(b, a);
}
/* rt-main int32(argc int32, argv const-ptr<const-ptr<char>>, main-ptr fun-ptr2<fut<nat64>, ctx, arr<str>>) */
int32_t rt_main(int32_t argc, char** argv, fun_ptr2 main_ptr) {
	uint64_t n_threads0;
	n_threads0 = get_nprocs();
	
	uint8_t f1;
	f1 = 0;
	
	struct global_ctx gctx_by_val2;
	struct lock _0 = lbv();
	struct lock _1 = lbv();
	struct lock _2 = lbv();
	struct condition _3 = create_condition();
	gctx_by_val2 = (struct global_ctx) {_0, _1, _2, (struct opt_1) {0, .as0 = (struct void_) {}}, (struct arr_4) {0u, NULL}, n_threads0, _3, f1, f1};
	
	struct global_ctx* gctx3;
	gctx3 = (&gctx_by_val2);
	
	struct island island_by_val4;
	island_by_val4 = island(gctx3, 0u, n_threads0);
	
	struct island* island5;
	island5 = (&island_by_val4);
	
	gctx3->islands = (struct arr_4) {1u, (&island5)};
	struct fut_0* main_fut6;
	main_fut6 = add_main_task(gctx3, (n_threads0 - 1u), island5, argc, argv, main_ptr);
	
	run_threads(n_threads0, gctx3);
	destroy_condition((&(&gctx_by_val2)->may_be_work_to_do));
	struct fut_state_0 _4 = main_fut6->state;
	switch (_4.kind) {
		case 0: {
			return 1;
		}
		case 1: {
			return 1;
		}
		case 2: {
			uint64_t r7 = _4.as2;
			
			uint8_t _5 = gctx3->any_unhandled_exceptions;
			if (_5) {
				return 1;
			} else {
				return ((int32_t) ((int64_t) r7));
			}
		}
		case 3: {
			return 1;
		}
		default:
			
	return 0;;
	}
}
/* lbv lock() */
struct lock lbv(void) {
	return lock_by_val();
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
	int32_t _3 = CLOCK_MONOTONIC();
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
/* CLOCK_MONOTONIC int32() */
int32_t CLOCK_MONOTONIC(void) {
	return 1;
}
/* island island(gctx global-ctx, id nat64, max-threads nat64) */
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
/* task-queue task-queue(max-threads nat64) */
struct task_queue task_queue(uint64_t max_threads) {
	struct mut_arr_0 _0 = mut_arr_by_val_with_capacity_from_unmanaged_memory(max_threads);
	return (struct task_queue) {(struct opt_3) {0, .as0 = (struct void_) {}}, _0};
}
/* mut-arr-by-val-with-capacity-from-unmanaged-memory<nat64> mut-arr<nat64>(capacity nat64) */
struct mut_arr_0 mut_arr_by_val_with_capacity_from_unmanaged_memory(uint64_t capacity) {
	struct fix_arr_0 backing0;
	uint64_t* _0 = unmanaged_alloc_zeroed_elements(capacity);
	backing0 = fix_arr_0(capacity, _0);
	
	return (struct mut_arr_0) {backing0, 0u};
}
/* fix-arr<a> fix-arr<nat64>(size nat64, begin-ptr mut-ptr<nat64>) */
struct fix_arr_0 fix_arr_0(uint64_t size, uint64_t* begin_ptr) {
	return (struct fix_arr_0) {(struct void_) {}, (struct arr_3) {size, ((uint64_t*) begin_ptr)}};
}
/* unmanaged-alloc-zeroed-elements<a> mut-ptr<nat64>(size-elements nat64) */
uint64_t* unmanaged_alloc_zeroed_elements(uint64_t size_elements) {
	uint64_t* res0;
	res0 = unmanaged_alloc_elements_0(size_elements);
	
	set_zero_range_0(res0, size_elements);
	return res0;
}
/* unmanaged-alloc-elements<a> mut-ptr<nat64>(size-elements nat64) */
uint64_t* unmanaged_alloc_elements_0(uint64_t size_elements) {
	uint8_t* _0 = unmanaged_alloc_bytes((size_elements * sizeof(uint64_t)));
	return ((uint64_t*) _0);
}
/* unmanaged-alloc-bytes mut-ptr<nat8>(size nat64) */
uint8_t* unmanaged_alloc_bytes(uint64_t size) {
	uint8_t* res0;
	res0 = malloc(size);
	
	uint8_t _0 = _notEqual_0(res0, NULL);
	hard_assert(_0);
	return res0;
}
/* !=<mut-ptr<nat8>> bool(a mut-ptr<nat8>, b mut-ptr<nat8>) */
uint8_t _notEqual_0(uint8_t* a, uint8_t* b) {
	return _not((a == b));
}
/* set-zero-range<a> void(begin mut-ptr<nat64>, size nat64) */
struct void_ set_zero_range_0(uint64_t* begin, uint64_t size) {
	uint8_t* _0 = memset(((uint8_t*) begin), 0, (size * sizeof(uint64_t)));
	return drop_0(_0);
}
/* drop<mut-ptr<nat8>> void(_ mut-ptr<nat8>) */
struct void_ drop_0(uint8_t* _p0) {
	return (struct void_) {};
}
/* default-exception-handler void(e exception) */
struct void_ default_exception_handler(struct ctx* ctx, struct exception e) {
	print_err_no_newline((struct str) {{20, constantarr_0_0}});
	struct str _0 = to_str_0(ctx, e);
	print_err(_0);
	struct global_ctx* _1 = get_global_ctx(ctx);
	return (_1->any_unhandled_exceptions = 1, (struct void_) {});
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
	uint8_t* _0 = as_any_const_ptr_0(a.chars.begin_ptr);
	uint64_t _1 = size_bytes(a);
	res0 = write(fd, _0, _1);
	
	uint64_t _2 = size_bytes(a);
	uint8_t _3 = _notEqual_1(res0, ((int64_t) _2));
	if (_3) {
		return todo_0();
	} else {
		return (struct void_) {};
	}
}
/* as-any-const-ptr<const-ptr<char>> const-ptr<nat8>(ref const-ptr<char>) */
uint8_t* as_any_const_ptr_0(char* ref) {
	return ((uint8_t*) ((uint8_t*) ref));
}
/* size-bytes nat64(a str) */
uint64_t size_bytes(struct str a) {
	return a.chars.size;
}
/* !=<int64> bool(a int64, b int64) */
uint8_t _notEqual_1(int64_t a, int64_t b) {
	return _not((a == b));
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
	
	uint8_t _0 = is_empty_0(a.message);struct str _1;
	
	if (_0) {
		_1 = (struct str) {{17, constantarr_0_4}};
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
	struct mut_arr_1* _0 = mut_arr(ctx);
	return (struct writer) {_0};
}
/* mut-arr<char> mut-arr<char>() */
struct mut_arr_1* mut_arr(struct ctx* ctx) {
	struct mut_arr_1* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_arr_1));
	temp0 = ((struct mut_arr_1*) _0);
	
	struct fix_arr_1 _1 = fix_arr_1();
	*temp0 = (struct mut_arr_1) {_1, 0u};
	return temp0;
}
/* fix-arr<a> fix-arr<char>() */
struct fix_arr_1 fix_arr_1(void) {
	return (struct fix_arr_1) {(struct void_) {}, (struct arr_0) {0u, NULL}};
}
/* ~= void(a writer, b str) */
struct void_ _concatEquals_0(struct ctx* ctx, struct writer a, struct str b) {
	return _concatEquals_1(ctx, a.chars, b.chars);
}
/* ~=<char> void(a mut-arr<char>, values arr<char>) */
struct void_ _concatEquals_1(struct ctx* ctx, struct mut_arr_1* a, struct arr_0 values) {
	struct _concatEquals_1__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct _concatEquals_1__lambda0));
	temp0 = ((struct _concatEquals_1__lambda0*) _0);
	
	*temp0 = (struct _concatEquals_1__lambda0) {a};
	return each_0(ctx, values, (struct fun_act1_1) {0, .as0 = temp0});
}
/* each<a> void(a arr<char>, f fun-act1<void, char>) */
struct void_ each_0(struct ctx* ctx, struct arr_0 a, struct fun_act1_1 f) {
	char* _0 = end_ptr_0(a);
	return each_recur_0(ctx, a.begin_ptr, _0, f);
}
/* each-recur<a> void(cur const-ptr<char>, end const-ptr<char>, f fun-act1<void, char>) */
struct void_ each_recur_0(struct ctx* ctx, char* cur, char* end, struct fun_act1_1 f) {
	top:;
	uint8_t _0 = _notEqual_2(cur, end);
	if (_0) {
		char _1 = _times_0(cur);
		subscript_0(ctx, f, _1);
		char* _2 = _plus_0(cur, 1u);
		cur = _2;
		end = end;
		f = f;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* ==<a> bool(a const-ptr<char>, b const-ptr<char>) */
uint8_t _equal_0(char* a, char* b) {
	return (((char*) a) == ((char*) b));
}
/* !=<const-ptr<a>> bool(a const-ptr<char>, b const-ptr<char>) */
uint8_t _notEqual_2(char* a, char* b) {
	uint8_t _0 = _equal_0(a, b);
	return _not(_0);
}
/* subscript<void, a> void(a fun-act1<void, char>, p0 char) */
struct void_ subscript_0(struct ctx* ctx, struct fun_act1_1 a, char p0) {
	return call_w_ctx_63(a, ctx, p0);
}
/* call-w-ctx<void, char> (generated) (generated) */
struct void_ call_w_ctx_63(struct fun_act1_1 a, struct ctx* ctx, char p0) {
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
/* *<a> char(a const-ptr<char>) */
char _times_0(char* a) {
	return (*((char*) a));
}
/* +<a> const-ptr<char>(a const-ptr<char>, offset nat64) */
char* _plus_0(char* a, uint64_t offset) {
	return ((char*) (((char*) a) + offset));
}
/* end-ptr<a> const-ptr<char>(a arr<char>) */
char* end_ptr_0(struct arr_0 a) {
	return _plus_0(a.begin_ptr, a.size);
}
/* ~=<a> void(a mut-arr<char>, value char) */
struct void_ _concatEquals_2(struct ctx* ctx, struct mut_arr_1* a, char value) {
	incr_capacity__e(ctx, a);
	uint64_t _0 = capacity_0(a);
	uint8_t _1 = _less_0(a->size, _0);
	assert(ctx, _1);
	char* _2 = begin_ptr_0(a);
	set_subscript_1(_2, a->size, value);
	uint64_t _3 = _plus_3(ctx, a->size, 1u);
	return (a->size = _3, (struct void_) {});
}
/* incr-capacity!<a> void(a mut-arr<char>) */
struct void_ incr_capacity__e(struct ctx* ctx, struct mut_arr_1* a) {
	uint64_t _0 = _plus_3(ctx, a->size, 1u);
	uint64_t _1 = round_up_to_power_of_two(ctx, _0);
	return ensure_capacity(ctx, a, _1);
}
/* ensure-capacity<a> void(a mut-arr<char>, min-capacity nat64) */
struct void_ ensure_capacity(struct ctx* ctx, struct mut_arr_1* a, uint64_t min_capacity) {
	uint64_t _0 = capacity_0(a);
	uint8_t _1 = _less_0(_0, min_capacity);
	if (_1) {
		return increase_capacity_to__e(ctx, a, min_capacity);
	} else {
		return (struct void_) {};
	}
}
/* capacity<a> nat64(a mut-arr<char>) */
uint64_t capacity_0(struct mut_arr_1* a) {
	return size_0(a->backing);
}
/* size<a> nat64(a fix-arr<char>) */
uint64_t size_0(struct fix_arr_1 a) {
	return a.inner.size;
}
/* increase-capacity-to!<a> void(a mut-arr<char>, new-capacity nat64) */
struct void_ increase_capacity_to__e(struct ctx* ctx, struct mut_arr_1* a, uint64_t new_capacity) {
	uint64_t _0 = capacity_0(a);
	uint8_t _1 = _greater(new_capacity, _0);
	assert(ctx, _1);
	char* old_begin0;
	old_begin0 = begin_ptr_0(a);
	
	struct fix_arr_1 _2 = uninitialized_fix_arr(ctx, new_capacity);
	a->backing = _2;
	char* _3 = begin_ptr_0(a);
	copy_data_from__e_1(ctx, _3, ((char*) old_begin0), a->size);
	uint64_t _4 = _plus_3(ctx, a->size, 1u);
	uint64_t _5 = size_0(a->backing);
	struct range _6 = _range(ctx, _4, _5);
	struct fix_arr_1 _7 = subscript_3(ctx, a->backing, _6);
	return set_zero_elements(_7);
}
/* assert void(condition bool) */
struct void_ assert(struct ctx* ctx, uint8_t condition) {
	uint8_t _0 = _not(condition);
	if (_0) {
		return throw_0(ctx, (struct str) {{13, constantarr_0_2}});
	} else {
		return (struct void_) {};
	}
}
/* throw<void> void(message str) */
struct void_ throw_0(struct ctx* ctx, struct str message) {
	struct backtrace _0 = get_backtrace(ctx);
	return throw_1(ctx, (struct exception) {message, _0});
}
/* throw<a> void(e exception) */
struct void_ throw_1(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx0;
	exn_ctx0 = get_exception_ctx(ctx);
	
	uint8_t _0 = _notEqual_3(exn_ctx0->jmp_buf_ptr, NULL);
	hard_assert(_0);
	exn_ctx0->thrown_exception = e;
	int32_t _1 = number_to_throw(ctx);
	(longjmp(exn_ctx0->jmp_buf_ptr, _1), (struct void_) {});
	return hard_unreachable_0();
}
/* get-exception-ctx exception-ctx() */
struct exception_ctx* get_exception_ctx(struct ctx* ctx) {
	return ((struct exception_ctx*) ctx->thread_local_stuff->exception_ctx_ptr);
}
/* !=<mut-ptr<__jmp_buf_tag>> bool(a mut-ptr<__jmp_buf_tag>, b mut-ptr<__jmp_buf_tag>) */
uint8_t _notEqual_3(struct __jmp_buf_tag* a, struct __jmp_buf_tag* b) {
	return _not((a == b));
}
/* number-to-throw int32() */
int32_t number_to_throw(struct ctx* ctx) {
	return 7;
}
/* hard-unreachable<a> void() */
struct void_ hard_unreachable_0(void) {
	(abort(), (struct void_) {});
	return (struct void_) {};
}
/* get-backtrace backtrace() */
struct backtrace get_backtrace(struct ctx* ctx) {
	struct opt_4 _0 = try_alloc_backtrace_arrs(ctx);
	switch (_0.kind) {
		case 0: {
			return (struct backtrace) {(struct arr_1) {0u, NULL}};
		}
		case 1: {
			struct backtrace_arrs* _matched0 = _0.as1;
			
			uint64_t n_code_ptrs1;
			uint64_t _1 = code_ptrs_size(ctx);
			int32_t _2 = backtrace(_matched0->code_ptrs, ((int32_t) ((int64_t) _1)));
			n_code_ptrs1 = ((uint64_t) ((int64_t) _2));
			
			uint64_t _3 = code_ptrs_size(ctx);
			uint8_t _4 = _lessOrEqual_0(n_code_ptrs1, _3);
			hard_assert(_4);
			copy_data_from__e_0(ctx, _matched0->funs, (struct arr_5) {346, constantarr_5_0}.begin_ptr, (struct arr_5) {346, constantarr_5_0}.size);
			sort__e(_matched0->funs, (struct arr_5) {346, constantarr_5_0}.size);
			struct sym* end_code_names2;
			end_code_names2 = (_matched0->code_names + n_code_ptrs1);
			
			fill_code_names__e(ctx, _matched0->code_names, end_code_names2, ((uint8_t**) _matched0->code_ptrs), ((struct named_val*) _matched0->funs));
			return (struct backtrace) {(struct arr_1) {n_code_ptrs1, ((struct sym*) _matched0->code_names)}};
		}
		default:
			
	return (struct backtrace) {(struct arr_1) {0, NULL}};;
	}
}
/* try-alloc-backtrace-arrs opt<backtrace-arrs>() */
struct opt_4 try_alloc_backtrace_arrs(struct ctx* ctx) {
	struct opt_5 _0 = try_alloc_uninitialized_0(ctx, 8u);
	switch (_0.kind) {
		case 0: {
			return (struct opt_4) {0, .as0 = (struct void_) {}};
		}
		case 1: {
			uint8_t** _matched0 = _0.as1;
			
			struct opt_7 _1 = try_alloc_uninitialized_1(ctx, 8u);
			switch (_1.kind) {
				case 0: {
					return (struct opt_4) {0, .as0 = (struct void_) {}};
				}
				case 1: {
					struct sym* _matched1 = _1.as1;
					
					struct opt_8 _2 = try_alloc_uninitialized_2(ctx, (struct arr_5) {346, constantarr_5_0}.size);
					switch (_2.kind) {
						case 0: {
							return (struct opt_4) {0, .as0 = (struct void_) {}};
						}
						case 1: {
							struct named_val* _matched2 = _2.as1;
							
							struct backtrace_arrs* temp0;
							uint8_t* _3 = alloc(ctx, sizeof(struct backtrace_arrs));
							temp0 = ((struct backtrace_arrs*) _3);
							
							*temp0 = (struct backtrace_arrs) {_matched0, _matched1, _matched2};
							return (struct opt_4) {1, .as1 = temp0};
						}
						default:
							
					return (struct opt_4) {0};;
					}
				}
				default:
					
			return (struct opt_4) {0};;
			}
		}
		default:
			
	return (struct opt_4) {0};;
	}
}
/* try-alloc-uninitialized<const-ptr<nat8>> opt<mut-ptr<const-ptr<nat8>>>(size nat64) */
struct opt_5 try_alloc_uninitialized_0(struct ctx* ctx, uint64_t size) {
	struct opt_6 _0 = try_alloc(ctx, (size * sizeof(uint8_t*)));
	switch (_0.kind) {
		case 0: {
			return (struct opt_5) {0, .as0 = (struct void_) {}};
		}
		case 1: {
			uint8_t* _matched0 = _0.as1;
			
			return (struct opt_5) {1, .as1 = ((uint8_t**) _matched0)};
		}
		default:
			
	return (struct opt_5) {0};;
	}
}
/* try-alloc opt<mut-ptr<nat8>>(size-bytes nat64) */
struct opt_6 try_alloc(struct ctx* ctx, uint64_t size_bytes) {
	struct gc* _0 = get_gc(ctx);
	return try_gc_alloc(_0, size_bytes);
}
/* try-gc-alloc opt<mut-ptr<nat8>>(gc gc, size-bytes nat64) */
struct opt_6 try_gc_alloc(struct gc* gc, uint64_t size_bytes) {
	acquire__e((&gc->lk));
	struct opt_6 res0;
	res0 = try_gc_alloc_recur(gc, size_bytes);
	
	maybe_set_needs_gc__e(gc);
	release__e((&gc->lk));
	return res0;
}
/* acquire! void(a lock) */
struct void_ acquire__e(struct lock* a) {
	return acquire_recur__e(a, 0u);
}
/* acquire-recur! void(a lock, n-tries nat64) */
struct void_ acquire_recur__e(struct lock* a, uint64_t n_tries) {
	top:;
	uint8_t _0 = try_acquire__e(a);
	uint8_t _1 = _not(_0);
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
	uint8_t _2 = _not(old_value);
	return atomic_compare_exchange_strong(_0, _1, _2);
}
/* yield-thread void() */
struct void_ yield_thread(void) {
	int32_t err0;
	err0 = sched_yield();
	
	return hard_assert((err0 == 0));
}
/* try-gc-alloc-recur opt<mut-ptr<nat8>>(gc gc, size-bytes nat64) */
struct opt_6 try_gc_alloc_recur(struct gc* gc, uint64_t size_bytes) {
	top:;
	uint64_t size_words0;
	size_words0 = words_of_bytes(size_bytes);
	
	uint64_t* cur1;
	cur1 = gc->data_cur;
	
	uint64_t* next2;
	next2 = (cur1 + size_words0);
	
	uint8_t _0 = _less_1(next2, gc->data_end);
	if (_0) {
		uint8_t _1 = range_free(gc->mark_cur, (gc->mark_cur + size_words0));
		if (_1) {
			gc->mark_cur = (gc->mark_cur + size_words0);
			gc->data_cur = next2;
			return (struct opt_6) {1, .as1 = ((uint8_t*) cur1)};
		} else {
			gc->mark_cur = (gc->mark_cur + 1u);
			gc->data_cur = (gc->data_cur + 1u);
			gc = gc;
			size_bytes = size_bytes;
			goto top;
		}
	} else {
		return (struct opt_6) {0, .as0 = (struct void_) {}};
	}
}
/* <=><nat64> comparison(a mut-ptr<nat64>, b mut-ptr<nat64>) */
uint32_t _compare_1(uint64_t* a, uint64_t* b) {
	uint8_t _0 = (a < b);
	if (_0) {
		return 0u;
	} else {
		uint8_t _1 = (a == b);
		if (_1) {
			return 1u;
		} else {
			return 2u;
		}
	}
}
/* <<mut-ptr<nat64>> bool(a mut-ptr<nat64>, b mut-ptr<nat64>) */
uint8_t _less_1(uint64_t* a, uint64_t* b) {
	uint32_t _0 = _compare_1(a, b);switch (_0) {
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
			return 0;
	}
}
/* range-free bool(mark mut-ptr<bool>, end mut-ptr<bool>) */
uint8_t range_free(uint8_t* mark, uint8_t* end) {
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
/* maybe-set-needs-gc! void(gc gc) */
struct void_ maybe_set_needs_gc__e(struct gc* gc) {
	uint64_t cur_word0;
	cur_word0 = _minus_2(gc->mark_cur, gc->mark_begin);
	
	uint8_t _0 = _greater(cur_word0, (gc->size_words / 2u));
	if (_0) {
		return (gc->needs_gc = 1, (struct void_) {});
	} else {
		return (struct void_) {};
	}
}
/* -<bool> nat64(a mut-ptr<bool>, b mut-ptr<bool>) */
uint64_t _minus_2(uint8_t* a, uint8_t* b) {
	return ((((uint64_t) a) - ((uint64_t) b)) / sizeof(uint8_t));
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
/* try-alloc-uninitialized<sym> opt<mut-ptr<sym>>(size nat64) */
struct opt_7 try_alloc_uninitialized_1(struct ctx* ctx, uint64_t size) {
	struct opt_6 _0 = try_alloc(ctx, (size * sizeof(struct sym)));
	switch (_0.kind) {
		case 0: {
			return (struct opt_7) {0, .as0 = (struct void_) {}};
		}
		case 1: {
			uint8_t* _matched0 = _0.as1;
			
			return (struct opt_7) {1, .as1 = ((struct sym*) _matched0)};
		}
		default:
			
	return (struct opt_7) {0};;
	}
}
/* try-alloc-uninitialized<named-val<const-ptr<nat8>>> opt<mut-ptr<named-val<const-ptr<nat8>>>>(size nat64) */
struct opt_8 try_alloc_uninitialized_2(struct ctx* ctx, uint64_t size) {
	struct opt_6 _0 = try_alloc(ctx, (size * sizeof(struct named_val)));
	switch (_0.kind) {
		case 0: {
			return (struct opt_8) {0, .as0 = (struct void_) {}};
		}
		case 1: {
			uint8_t* _matched0 = _0.as1;
			
			return (struct opt_8) {1, .as1 = ((struct named_val*) _matched0)};
		}
		default:
			
	return (struct opt_8) {0};;
	}
}
/* code-ptrs-size nat64() */
uint64_t code_ptrs_size(struct ctx* ctx) {
	return 8u;
}
/* copy-data-from!<named-val<const-ptr<nat8>>> void(to mut-ptr<named-val<const-ptr<nat8>>>, from const-ptr<named-val<const-ptr<nat8>>>, len nat64) */
struct void_ copy_data_from__e_0(struct ctx* ctx, struct named_val* to, struct named_val* from, uint64_t len) {
	uint8_t* _0 = as_any_const_ptr_1(from);
	uint8_t* _1 = memcpy(((uint8_t*) to), _0, (len * sizeof(struct named_val)));
	return drop_0(_1);
}
/* as-any-const-ptr<const-ptr<a>> const-ptr<nat8>(ref const-ptr<named-val<const-ptr<nat8>>>) */
uint8_t* as_any_const_ptr_1(struct named_val* ref) {
	return ((uint8_t*) ((uint8_t*) ref));
}
/* sort! void(a mut-ptr<named-val<const-ptr<nat8>>>, size nat64) */
struct void_ sort__e(struct named_val* a, uint64_t size) {
	top:;
	uint8_t _0 = _greater(size, 1u);
	if (_0) {
		swap__e(a, 0u, (size / 2u));
		uint64_t after_pivot0;
		after_pivot0 = partition__e(a, (*a).val, 1u, (size - 1u));
		
		uint64_t new_pivot_index1;
		new_pivot_index1 = (after_pivot0 - 1u);
		
		swap__e(a, 0u, new_pivot_index1);
		sort__e(a, new_pivot_index1);
		a = (a + after_pivot0);
		size = (size - after_pivot0);
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* swap!<named-val<const-ptr<nat8>>> void(a mut-ptr<named-val<const-ptr<nat8>>>, lo nat64, hi nat64) */
struct void_ swap__e(struct named_val* a, uint64_t lo, uint64_t hi) {
	struct named_val temp0;
	temp0 = subscript_1(a, lo);
	
	struct named_val _0 = subscript_1(a, hi);
	set_subscript_0(a, lo, _0);
	return set_subscript_0(a, hi, temp0);
}
/* subscript<a> named-val<const-ptr<nat8>>(a mut-ptr<named-val<const-ptr<nat8>>>, n nat64) */
struct named_val subscript_1(struct named_val* a, uint64_t n) {
	return (*(a + n));
}
/* set-subscript<a> void(a mut-ptr<named-val<const-ptr<nat8>>>, n nat64, value named-val<const-ptr<nat8>>) */
struct void_ set_subscript_0(struct named_val* a, uint64_t n, struct named_val value) {
	return (*(a + n) = value, (struct void_) {});
}
/* partition! nat64(a mut-ptr<named-val<const-ptr<nat8>>>, pivot const-ptr<nat8>, l nat64, r nat64) */
uint64_t partition__e(struct named_val* a, uint8_t* pivot, uint64_t l, uint64_t r) {
	top:;
	uint8_t _0 = _lessOrEqual_0(l, r);
	if (_0) {
		struct named_val _1 = subscript_1(a, l);
		uint8_t _2 = _less_2(_1.val, pivot);
		if (_2) {
			a = a;
			pivot = pivot;
			l = (l + 1u);
			r = r;
			goto top;
		} else {
			swap__e(a, l, r);
			a = a;
			pivot = pivot;
			l = l;
			r = (r - 1u);
			goto top;
		}
	} else {
		return l;
	}
}
/* ==<nat8> bool(a const-ptr<nat8>, b const-ptr<nat8>) */
uint8_t _equal_1(uint8_t* a, uint8_t* b) {
	return (((uint8_t*) a) == ((uint8_t*) b));
}
/* <=><nat8> comparison(a const-ptr<nat8>, b const-ptr<nat8>) */
uint32_t _compare_2(uint8_t* a, uint8_t* b) {
	return _compare_3(((uint8_t*) a), ((uint8_t*) b));
}
/* <=><a> comparison(a mut-ptr<nat8>, b mut-ptr<nat8>) */
uint32_t _compare_3(uint8_t* a, uint8_t* b) {
	uint8_t _0 = (a < b);
	if (_0) {
		return 0u;
	} else {
		uint8_t _1 = (a == b);
		if (_1) {
			return 1u;
		} else {
			return 2u;
		}
	}
}
/* <<const-ptr<nat8>> bool(a const-ptr<nat8>, b const-ptr<nat8>) */
uint8_t _less_2(uint8_t* a, uint8_t* b) {
	uint32_t _0 = _compare_2(a, b);switch (_0) {
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
			return 0;
	}
}
/* fill-code-names! void(code-names mut-ptr<sym>, end-code-names mut-ptr<sym>, code-ptrs const-ptr<const-ptr<nat8>>, funs const-ptr<named-val<const-ptr<nat8>>>) */
struct void_ fill_code_names__e(struct ctx* ctx, struct sym* code_names, struct sym* end_code_names, uint8_t** code_ptrs, struct named_val* funs) {
	top:;
	uint8_t _0 = _less_3(code_names, end_code_names);
	if (_0) {
		uint8_t* _1 = _times_2(code_ptrs);
		struct sym _2 = get_fun_name(_1, funs, (struct arr_5) {346, constantarr_5_0}.size);
		*code_names = _2;
		uint8_t** _3 = _plus_2(code_ptrs, 1u);
		code_names = (code_names + 1u);
		end_code_names = end_code_names;
		code_ptrs = _3;
		funs = funs;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* <=><sym> comparison(a mut-ptr<sym>, b mut-ptr<sym>) */
uint32_t _compare_4(struct sym* a, struct sym* b) {
	uint8_t _0 = (a < b);
	if (_0) {
		return 0u;
	} else {
		uint8_t _1 = (a == b);
		if (_1) {
			return 1u;
		} else {
			return 2u;
		}
	}
}
/* <<mut-ptr<sym>> bool(a mut-ptr<sym>, b mut-ptr<sym>) */
uint8_t _less_3(struct sym* a, struct sym* b) {
	uint32_t _0 = _compare_4(a, b);switch (_0) {
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
			return 0;
	}
}
/* get-fun-name sym(code-ptr const-ptr<nat8>, funs const-ptr<named-val<const-ptr<nat8>>>, size nat64) */
struct sym get_fun_name(uint8_t* code_ptr, struct named_val* funs, uint64_t size) {
	top:;
	uint8_t _0 = _less_0(size, 2u);
	if (_0) {
		return (struct sym) {"<<UNKNOWN>>"};
	} else {
		struct named_val _1 = subscript_2(funs, 1u);
		uint8_t _2 = _less_2(code_ptr, _1.val);
		if (_2) {
			struct named_val _3 = _times_1(funs);
			return _3.name;
		} else {
			struct named_val* _4 = _plus_1(funs, 1u);
			code_ptr = code_ptr;
			funs = _4;
			size = (size - 1u);
			goto top;
		}
	}
}
/* subscript<named-val<const-ptr<nat8>>> named-val<const-ptr<nat8>>(a const-ptr<named-val<const-ptr<nat8>>>, n nat64) */
struct named_val subscript_2(struct named_val* a, uint64_t n) {
	struct named_val* _0 = _plus_1(a, n);
	return _times_1(_0);
}
/* *<a> named-val<const-ptr<nat8>>(a const-ptr<named-val<const-ptr<nat8>>>) */
struct named_val _times_1(struct named_val* a) {
	return (*((struct named_val*) a));
}
/* +<a> const-ptr<named-val<const-ptr<nat8>>>(a const-ptr<named-val<const-ptr<nat8>>>, offset nat64) */
struct named_val* _plus_1(struct named_val* a, uint64_t offset) {
	return ((struct named_val*) (((struct named_val*) a) + offset));
}
/* *<const-ptr<nat8>> const-ptr<nat8>(a const-ptr<const-ptr<nat8>>) */
uint8_t* _times_2(uint8_t** a) {
	return (*((uint8_t**) a));
}
/* +<const-ptr<nat8>> const-ptr<const-ptr<nat8>>(a const-ptr<const-ptr<nat8>>, offset nat64) */
uint8_t** _plus_2(uint8_t** a, uint64_t offset) {
	return ((uint8_t**) (((uint8_t**) a) + offset));
}
/* begin-ptr<a> mut-ptr<char>(a mut-arr<char>) */
char* begin_ptr_0(struct mut_arr_1* a) {
	return begin_ptr_1(a->backing);
}
/* begin-ptr<a> mut-ptr<char>(a fix-arr<char>) */
char* begin_ptr_1(struct fix_arr_1 a) {
	return ((char*) a.inner.begin_ptr);
}
/* uninitialized-fix-arr<a> fix-arr<char>(size nat64) */
struct fix_arr_1 uninitialized_fix_arr(struct ctx* ctx, uint64_t size) {
	char* _0 = alloc_uninitialized_0(ctx, size);
	return fix_arr_2(size, _0);
}
/* fix-arr<a> fix-arr<char>(size nat64, begin-ptr mut-ptr<char>) */
struct fix_arr_1 fix_arr_2(uint64_t size, char* begin_ptr) {
	return (struct fix_arr_1) {(struct void_) {}, (struct arr_0) {size, ((char*) begin_ptr)}};
}
/* alloc-uninitialized<a> mut-ptr<char>(size nat64) */
char* alloc_uninitialized_0(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(char)));
	return ((char*) _0);
}
/* alloc mut-ptr<nat8>(size-bytes nat64) */
uint8_t* alloc(struct ctx* ctx, uint64_t size_bytes) {
	struct gc* _0 = get_gc(ctx);
	return gc_alloc(ctx, _0, size_bytes);
}
/* gc-alloc mut-ptr<nat8>(gc gc, size nat64) */
uint8_t* gc_alloc(struct ctx* ctx, struct gc* gc, uint64_t size) {
	struct opt_6 _0 = try_gc_alloc(gc, size);
	switch (_0.kind) {
		case 0: {
			return todo_1();
		}
		case 1: {
			uint8_t* _matched0 = _0.as1;
			
			return _matched0;
		}
		default:
			
	return NULL;;
	}
}
/* todo<mut-ptr<nat8>> mut-ptr<nat8>() */
uint8_t* todo_1(void) {
	(abort(), (struct void_) {});
	return NULL;
}
/* copy-data-from!<a> void(to mut-ptr<char>, from const-ptr<char>, len nat64) */
struct void_ copy_data_from__e_1(struct ctx* ctx, char* to, char* from, uint64_t len) {
	uint8_t* _0 = as_any_const_ptr_0(from);
	uint8_t* _1 = memcpy(((uint8_t*) to), _0, (len * sizeof(char)));
	return drop_0(_1);
}
/* set-zero-elements<a> void(a fix-arr<char>) */
struct void_ set_zero_elements(struct fix_arr_1 a) {
	char* _0 = begin_ptr_1(a);
	uint64_t _1 = size_0(a);
	return set_zero_range_1(_0, _1);
}
/* set-zero-range<a> void(begin mut-ptr<char>, size nat64) */
struct void_ set_zero_range_1(char* begin, uint64_t size) {
	uint8_t* _0 = memset(((uint8_t*) begin), 0, (size * sizeof(char)));
	return drop_0(_0);
}
/* subscript<a> fix-arr<char>(a fix-arr<char>, range range<nat64>) */
struct fix_arr_1 subscript_3(struct ctx* ctx, struct fix_arr_1 a, struct range range) {
	struct arr_0 _0 = subscript_4(ctx, a.inner, range);
	return (struct fix_arr_1) {(struct void_) {}, _0};
}
/* subscript<a> arr<char>(a arr<char>, range range<nat64>) */
struct arr_0 subscript_4(struct ctx* ctx, struct arr_0 a, struct range range) {
	uint8_t _0 = _lessOrEqual_0(range.high, a.size);
	assert(ctx, _0);
	char* _1 = _plus_0(a.begin_ptr, range.low);
	return (struct arr_0) {(range.high - range.low), _1};
}
/* ..<nat64> range<nat64>(low nat64, high nat64) */
struct range _range(struct ctx* ctx, uint64_t low, uint64_t high) {
	uint8_t _0 = _less_0(low, high);
	if (_0) {
		return (struct range) {(struct void_) {}, low, high};
	} else {
		return (struct range) {(struct void_) {}, high, high};
	}
}
/* + nat64(a nat64, b nat64) */
uint64_t _plus_3(struct ctx* ctx, uint64_t a, uint64_t b) {
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
/* >=<nat64> bool(a nat64, b nat64) */
uint8_t _greaterOrEqual(uint64_t a, uint64_t b) {
	uint8_t _0 = _less_0(a, b);
	return _not(_0);
}
/* round-up-to-power-of-two nat64(n nat64) */
uint64_t round_up_to_power_of_two(struct ctx* ctx, uint64_t n) {
	return round_up_to_power_of_two_recur(ctx, 1u, n);
}
/* round-up-to-power-of-two-recur nat64(acc nat64, n nat64) */
uint64_t round_up_to_power_of_two_recur(struct ctx* ctx, uint64_t acc, uint64_t n) {
	top:;
	uint8_t _0 = _greaterOrEqual(acc, n);
	if (_0) {
		return acc;
	} else {
		uint64_t _1 = _times_3(ctx, acc, 2u);
		acc = _1;
		n = n;
		goto top;
	}
}
/* * nat64(a nat64, b nat64) */
uint64_t _times_3(struct ctx* ctx, uint64_t a, uint64_t b) {uint8_t _0;
	
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
/* / nat64(a nat64, b nat64) */
uint64_t _divide(struct ctx* ctx, uint64_t a, uint64_t b) {
	forbid(ctx, (b == 0u));
	return (a / b);
}
/* forbid void(condition bool) */
struct void_ forbid(struct ctx* ctx, uint8_t condition) {
	uint8_t _0 = condition;
	if (_0) {
		return throw_0(ctx, (struct str) {{13, constantarr_0_3}});
	} else {
		return (struct void_) {};
	}
}
/* set-subscript<a> void(a mut-ptr<char>, n nat64, value char) */
struct void_ set_subscript_1(char* a, uint64_t n, char value) {
	return (*(a + n) = value, (struct void_) {});
}
/* ~=<char>.lambda0 void(x char) */
struct void_ _concatEquals_1__lambda0(struct ctx* ctx, struct _concatEquals_1__lambda0* _closure, char x) {
	return _concatEquals_2(ctx, _closure->a, x);
}
/* is-empty bool(a str) */
uint8_t is_empty_0(struct str a) {
	return is_empty_1(a.chars);
}
/* is-empty<char> bool(a arr<char>) */
uint8_t is_empty_1(struct arr_0 a) {
	return (a.size == 0u);
}
/* each<sym> void(a arr<sym>, f fun-act1<void, sym>) */
struct void_ each_1(struct ctx* ctx, struct arr_1 a, struct fun_act1_2 f) {
	struct sym* _0 = end_ptr_1(a);
	return each_recur_1(ctx, a.begin_ptr, _0, f);
}
/* each-recur<a> void(cur const-ptr<sym>, end const-ptr<sym>, f fun-act1<void, sym>) */
struct void_ each_recur_1(struct ctx* ctx, struct sym* cur, struct sym* end, struct fun_act1_2 f) {
	top:;
	uint8_t _0 = _notEqual_4(cur, end);
	if (_0) {
		struct sym _1 = _times_4(cur);
		subscript_5(ctx, f, _1);
		struct sym* _2 = _plus_4(cur, 1u);
		cur = _2;
		end = end;
		f = f;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* ==<a> bool(a const-ptr<sym>, b const-ptr<sym>) */
uint8_t _equal_2(struct sym* a, struct sym* b) {
	return (((struct sym*) a) == ((struct sym*) b));
}
/* !=<const-ptr<a>> bool(a const-ptr<sym>, b const-ptr<sym>) */
uint8_t _notEqual_4(struct sym* a, struct sym* b) {
	uint8_t _0 = _equal_2(a, b);
	return _not(_0);
}
/* subscript<void, a> void(a fun-act1<void, sym>, p0 sym) */
struct void_ subscript_5(struct ctx* ctx, struct fun_act1_2 a, struct sym p0) {
	return call_w_ctx_159(a, ctx, p0);
}
/* call-w-ctx<void, sym> (generated) (generated) */
struct void_ call_w_ctx_159(struct fun_act1_2 a, struct ctx* ctx, struct sym p0) {
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
/* *<a> sym(a const-ptr<sym>) */
struct sym _times_4(struct sym* a) {
	return (*((struct sym*) a));
}
/* +<a> const-ptr<sym>(a const-ptr<sym>, offset nat64) */
struct sym* _plus_4(struct sym* a, uint64_t offset) {
	return ((struct sym*) (((struct sym*) a) + offset));
}
/* end-ptr<a> const-ptr<sym>(a arr<sym>) */
struct sym* end_ptr_1(struct arr_1 a) {
	return _plus_4(a.begin_ptr, a.size);
}
/* ~= void(a writer, b const-ptr<char>) */
struct void_ _concatEquals_3(struct ctx* ctx, struct writer a, char* b) {
	struct str _0 = to_str_1(b);
	return _concatEquals_0(ctx, a, _0);
}
/* to-str str(a const-ptr<char>) */
struct str to_str_1(char* a) {
	char* _0 = find_cstr_end(a);
	struct arr_0 _1 = arr_from_begin_end(a, _0);
	return (struct str) {_1};
}
/* arr-from-begin-end<char> arr<char>(begin const-ptr<char>, end const-ptr<char>) */
struct arr_0 arr_from_begin_end(char* begin, char* end) {
	uint8_t _0 = _lessOrEqual_1(begin, end);
	hard_assert(_0);
	uint64_t _1 = _minus_3(end, begin);
	return (struct arr_0) {_1, begin};
}
/* <=><a> comparison(a const-ptr<char>, b const-ptr<char>) */
uint32_t _compare_5(char* a, char* b) {
	return _compare_6(((char*) a), ((char*) b));
}
/* <=><a> comparison(a mut-ptr<char>, b mut-ptr<char>) */
uint32_t _compare_6(char* a, char* b) {
	uint8_t _0 = (a < b);
	if (_0) {
		return 0u;
	} else {
		uint8_t _1 = (a == b);
		if (_1) {
			return 1u;
		} else {
			return 2u;
		}
	}
}
/* <=<const-ptr<a>> bool(a const-ptr<char>, b const-ptr<char>) */
uint8_t _lessOrEqual_1(char* a, char* b) {
	uint8_t _0 = _less_4(b, a);
	return _not(_0);
}
/* <<a> bool(a const-ptr<char>, b const-ptr<char>) */
uint8_t _less_4(char* a, char* b) {
	uint32_t _0 = _compare_5(a, b);switch (_0) {
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
			return 0;
	}
}
/* -<a> nat64(a const-ptr<char>, b const-ptr<char>) */
uint64_t _minus_3(char* a, char* b) {
	return _minus_4(((char*) a), ((char*) b));
}
/* -<a> nat64(a mut-ptr<char>, b mut-ptr<char>) */
uint64_t _minus_4(char* a, char* b) {
	return ((((uint64_t) a) - ((uint64_t) b)) / sizeof(char));
}
/* find-cstr-end const-ptr<char>(a const-ptr<char>) */
char* find_cstr_end(char* a) {
	struct opt_9 _0 = find_char_in_cstr(a, 0u);
	switch (_0.kind) {
		case 0: {
			return hard_unreachable_1();
		}
		case 1: {
			char* _matched0 = _0.as1;
			
			return _matched0;
		}
		default:
			
	return NULL;;
	}
}
/* find-char-in-cstr opt<const-ptr<char>>(a const-ptr<char>, c char) */
struct opt_9 find_char_in_cstr(char* a, char c) {
	top:;
	char _0 = _times_0(a);
	uint8_t _1 = _equal_3(_0, c);
	if (_1) {
		return (struct opt_9) {1, .as1 = a};
	} else {
		char _2 = _times_0(a);
		uint8_t _3 = _equal_3(_2, 0u);
		if (_3) {
			return (struct opt_9) {0, .as0 = (struct void_) {}};
		} else {
			char* _4 = _plus_0(a, 1u);
			a = _4;
			c = c;
			goto top;
		}
	}
}
/* == bool(a char, b char) */
uint8_t _equal_3(char a, char b) {
	return (((uint8_t) a) == ((uint8_t) b));
}
/* hard-unreachable<const-ptr<char>> const-ptr<char>() */
char* hard_unreachable_1(void) {
	(abort(), (struct void_) {});
	return NULL;
}
/* to-str.lambda0 void(x sym) */
struct void_ to_str_0__lambda0(struct ctx* ctx, struct to_str_0__lambda0* _closure, struct sym x) {
	_concatEquals_0(ctx, _closure->res, (struct str) {{5, constantarr_0_5}});
	return _concatEquals_3(ctx, _closure->res, x.to_c_str);
}
/* move-to-str! str(a writer) */
struct str move_to_str__e(struct ctx* ctx, struct writer a) {
	struct arr_0 _0 = move_to_arr__e(a.chars);
	return (struct str) {_0};
}
/* move-to-arr!<char> arr<char>(a mut-arr<char>) */
struct arr_0 move_to_arr__e(struct mut_arr_1* a) {
	struct fix_arr_1 _0 = move_to_fix_arr__e(a);
	return cast_immutable(_0);
}
/* cast-immutable<a> arr<char>(a fix-arr<char>) */
struct arr_0 cast_immutable(struct fix_arr_1 a) {
	return a.inner;
}
/* move-to-fix-arr!<a> fix-arr<char>(a mut-arr<char>) */
struct fix_arr_1 move_to_fix_arr__e(struct mut_arr_1* a) {
	struct fix_arr_1 res0;
	char* _0 = begin_ptr_0(a);
	res0 = fix_arr_2(a->size, _0);
	
	struct fix_arr_1 _1 = fix_arr_1();
	a->backing = _1;
	a->size = 0u;
	return res0;
}
/* get-global-ctx global-ctx() */
struct global_ctx* get_global_ctx(struct ctx* ctx) {
	return ((struct global_ctx*) ctx->gctx_ptr);
}
/* island.lambda0 void(exn exception) */
struct void_ island__lambda0(struct ctx* ctx, struct void_ _closure, struct exception exn) {
	return default_exception_handler(ctx, exn);
}
/* default-log-handler void(a logged) */
struct void_ default_log_handler(struct ctx* ctx, struct logged* a) {
	struct str _0 = to_str_2(ctx, a->level);
	struct str _1 = _tilde_0(ctx, _0, (struct str) {{2, constantarr_0_9}});
	struct str _2 = _tilde_0(ctx, _1, a->message);
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
struct str _tilde_0(struct ctx* ctx, struct str a, struct str b) {
	struct arr_0 _0 = _tilde_1(ctx, a.chars, b.chars);
	return (struct str) {_0};
}
/* ~<char> arr<char>(a arr<char>, b arr<char>) */
struct arr_0 _tilde_1(struct ctx* ctx, struct arr_0 a, struct arr_0 b) {
	uint64_t res_size0;
	res_size0 = (a.size + b.size);
	
	char* res1;
	res1 = alloc_uninitialized_0(ctx, res_size0);
	
	copy_data_from__e_1(ctx, res1, a.begin_ptr, a.size);
	copy_data_from__e_1(ctx, (res1 + a.size), b.begin_ptr, b.size);
	return (struct arr_0) {res_size0, ((char*) res1)};
}
/* to-str str(a log-level) */
struct str to_str_2(struct ctx* ctx, uint32_t a) {switch (a) {
		case 0: {
			return (struct str) {{4, constantarr_0_6}};
		}
		case 1: {
			return (struct str) {{4, constantarr_0_7}};
		}
		case 2: {
			return (struct str) {{5, constantarr_0_8}};
		}
		default:
			return (struct str) {(struct arr_0) {0, NULL}};
	}
}
/* island.lambda1 void(log logged) */
struct void_ island__lambda1(struct ctx* ctx, struct void_ _closure, struct logged* log) {
	return default_log_handler(ctx, log);
}
/* gc gc() */
struct gc gc(void) {
	uint8_t* mark0;
	uint8_t* _0 = malloc(50331648u);
	mark0 = ((uint8_t*) _0);
	
	uint8_t* mark_end1;
	mark_end1 = (mark0 + 50331648u);
	
	uint64_t* data2;
	uint8_t* _1 = malloc((50331648u * sizeof(uint64_t)));
	data2 = ((uint64_t*) _1);
	
	uint8_t _2 = is_word_aligned_1(((uint8_t*) data2));
	hard_assert(_2);
	uint64_t* data_end3;
	data_end3 = (data2 + 50331648u);
	
	uint8_t* _3 = memset(((uint8_t*) mark0), 0, 50331648u);
	drop_0(_3);
	struct gc res4;
	struct lock _4 = lock_by_val();
	res4 = (struct gc) {_4, 0u, (struct opt_2) {0, .as0 = (struct void_) {}}, 0, 50331648u, mark0, mark0, mark_end1, data2, data2, data_end3};
	
	validate_gc((&res4));
	return res4;
}
/* validate-gc void(gc gc) */
struct void_ validate_gc(struct gc* gc) {
	uint8_t _0 = is_word_aligned_1(((uint8_t*) gc->mark_begin));
	hard_assert(_0);
	uint8_t _1 = is_word_aligned_1(((uint8_t*) gc->data_begin));
	hard_assert(_1);
	uint8_t _2 = is_word_aligned_1(((uint8_t*) gc->data_cur));
	hard_assert(_2);
	uint8_t _3 = _lessOrEqual_2(gc->mark_begin, gc->mark_cur);
	hard_assert(_3);
	uint8_t _4 = _lessOrEqual_2(gc->mark_cur, gc->mark_end);
	hard_assert(_4);
	uint8_t _5 = _lessOrEqual_3(gc->data_begin, gc->data_cur);
	hard_assert(_5);
	uint8_t _6 = _lessOrEqual_3(gc->data_cur, gc->data_end);
	hard_assert(_6);
	uint64_t mark_idx0;
	mark_idx0 = _minus_2(gc->mark_cur, gc->mark_begin);
	
	uint64_t data_idx1;
	data_idx1 = _minus_1(gc->data_cur, gc->data_begin);
	
	uint64_t _7 = _minus_2(gc->mark_end, gc->mark_begin);
	hard_assert((_7 == gc->size_words));
	uint64_t _8 = _minus_1(gc->data_end, gc->data_begin);
	hard_assert((_8 == gc->size_words));
	return hard_assert((mark_idx0 == data_idx1));
}
/* <=><bool> comparison(a mut-ptr<bool>, b mut-ptr<bool>) */
uint32_t _compare_7(uint8_t* a, uint8_t* b) {
	uint8_t _0 = (a < b);
	if (_0) {
		return 0u;
	} else {
		uint8_t _1 = (a == b);
		if (_1) {
			return 1u;
		} else {
			return 2u;
		}
	}
}
/* <=<mut-ptr<bool>> bool(a mut-ptr<bool>, b mut-ptr<bool>) */
uint8_t _lessOrEqual_2(uint8_t* a, uint8_t* b) {
	uint8_t _0 = _less_5(b, a);
	return _not(_0);
}
/* <<a> bool(a mut-ptr<bool>, b mut-ptr<bool>) */
uint8_t _less_5(uint8_t* a, uint8_t* b) {
	uint32_t _0 = _compare_7(a, b);switch (_0) {
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
			return 0;
	}
}
/* <=<mut-ptr<nat64>> bool(a mut-ptr<nat64>, b mut-ptr<nat64>) */
uint8_t _lessOrEqual_3(uint64_t* a, uint64_t* b) {
	uint8_t _0 = _less_1(b, a);
	return _not(_0);
}
/* thread-safe-counter thread-safe-counter() */
struct thread_safe_counter thread_safe_counter_0(void) {
	return thread_safe_counter_1(0u);
}
/* thread-safe-counter thread-safe-counter(init nat64) */
struct thread_safe_counter thread_safe_counter_1(uint64_t init) {
	struct lock _0 = lock_by_val();
	return (struct thread_safe_counter) {_0, init};
}
/* add-main-task fut<nat64>(gctx global-ctx, thread-id nat64, island island, argc int32, argv const-ptr<const-ptr<char>>, main-ptr fun-ptr2<fut<nat64>, ctx, arr<str>>) */
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
	
	struct arr_7 all_args11;
	all_args11 = (struct arr_7) {((uint64_t) ((int64_t) argc)), argv};
	
	return call_w_ctx_304(add10, ctx9, all_args11, main_ptr);
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
	struct fix_arr_2 _0 = fix_arr_3();
	return (struct perf_ctx) {(struct arr_2) {0u, NULL}, _0};
}
/* fix-arr<measure-value> fix-arr<measure-value>() */
struct fix_arr_2 fix_arr_3(void) {
	return (struct fix_arr_2) {(struct void_) {}, (struct arr_6) {0u, NULL}};
}
/* ctx ctx(gctx global-ctx, tls thread-local-stuff, island island, exclusion nat64) */
struct ctx ctx(struct global_ctx* gctx, struct thread_local_stuff* tls, struct island* island, uint64_t exclusion) {
	struct gc_ctx* gc_ctx0;
	gc_ctx0 = get_gc_ctx_1((&island->gc));
	
	((struct log_ctx*) tls->log_ctx_ptr)->handler = (&island->gc_root)->log_handler;
	return (struct ctx) {((uint8_t*) gctx), island->id, exclusion, ((uint8_t*) gc_ctx0), tls};
}
/* get-gc-ctx gc-ctx(gc gc) */
struct gc_ctx* get_gc_ctx_1(struct gc* gc) {
	acquire__e((&gc->lk));
	struct gc_ctx* res2;
	struct opt_2 _0 = gc->context_head;
	switch (_0.kind) {
		case 0: {
			struct gc_ctx* c0;
			uint8_t* _1 = malloc(sizeof(struct gc_ctx));
			c0 = ((struct gc_ctx*) _1);
			
			c0->gc = gc;
			c0->next_ctx = (struct opt_2) {0, .as0 = (struct void_) {}};
			res2 = c0;
			break;
		}
		case 1: {
			struct gc_ctx* _matched1 = _0.as1;
			
			gc->context_head = _matched1->next_ctx;
			_matched1->next_ctx = (struct opt_2) {0, .as0 = (struct void_) {}};
			res2 = _matched1;
			break;
		}
		default:
			
	res2 = NULL;;
	}
	
	release__e((&gc->lk));
	return res2;
}
/* add-first-task fut<nat64>(all-args arr<const-ptr<char>>, main-ptr fun-ptr2<fut<nat64>, ctx, arr<str>>) */
struct fut_0* add_first_task(struct ctx* ctx, struct arr_7 all_args, fun_ptr2 main_ptr) {
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
/* then-void<nat64> fut<nat64>(a fut<void>, cb fun-ref0<nat64>) */
struct fut_0* then_void(struct ctx* ctx, struct fut_1* a, struct fun_ref0 cb) {
	struct island_and_exclusion _0 = cur_island_and_exclusion(ctx);
	struct then_void__lambda0* temp0;
	uint8_t* _1 = alloc(ctx, sizeof(struct then_void__lambda0));
	temp0 = ((struct then_void__lambda0*) _1);
	
	*temp0 = (struct then_void__lambda0) {cb};
	return then(ctx, a, (struct fun_ref1) {_0, (struct fun_act1_4) {0, .as0 = temp0}});
}
/* then<out, void> fut<nat64>(a fut<void>, cb fun-ref1<nat64, void>) */
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
/* unresolved<out> fut<nat64>() */
struct fut_0* unresolved(struct ctx* ctx) {
	struct fut_0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct fut_0));
	temp0 = ((struct fut_0*) _0);
	
	struct lock _1 = lock_by_val();
	*temp0 = (struct fut_0) {_1, (struct fut_state_0) {0, .as0 = (struct void_) {}}};
	return temp0;
}
/* callback!<in> void(f fut<void>, cb fun-act1<void, result<void, exception>>) */
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
/* subscript<a> void(a fun-act0<void>) */
struct void_ subscript_6(struct ctx* ctx, struct fun_act0_0 a) {
	return call_w_ctx_213(a, ctx);
}
/* call-w-ctx<void> (generated) (generated) */
struct void_ call_w_ctx_213(struct fun_act0_0 a, struct ctx* ctx) {
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
		case 6: {
			struct with_log_handler__lambda0* closure6 = _0.as6;
			
			return with_log_handler__lambda0(ctx, closure6);
		}
		case 7: {
			struct void_ closure7 = _0.as7;
			
			return main_0__lambda1(ctx, closure7);
		}
		case 8: {
			struct void_ closure8 = _0.as8;
			
			return main_0__lambda3(ctx, closure8);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* subscript<void, result<a, exception>> void(a fun-act1<void, result<void, exception>>, p0 result<void, exception>) */
struct void_ subscript_7(struct ctx* ctx, struct fun_act1_3 a, struct result_1 p0) {
	return call_w_ctx_215(a, ctx, p0);
}
/* call-w-ctx<void, result<void, exception>> (generated) (generated) */
struct void_ call_w_ctx_215(struct fun_act1_3 a, struct ctx* ctx, struct result_1 p0) {
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
/* callback!<in>.lambda0 void() */
struct void_ callback__e_0__lambda0(struct ctx* ctx, struct callback__e_0__lambda0* _closure) {
	struct fut_state_1 _0 = _closure->f->state;
	switch (_0.kind) {
		case 0: {
			struct fut_state_callbacks_1* temp0;
			uint8_t* _1 = alloc(ctx, sizeof(struct fut_state_callbacks_1));
			temp0 = ((struct fut_state_callbacks_1*) _1);
			
			*temp0 = (struct fut_state_callbacks_1) {_closure->cb, (struct opt_10) {0, .as0 = (struct void_) {}}};
			return (_closure->f->state = (struct fut_state_1) {1, .as1 = temp0}, (struct void_) {});
		}
		case 1: {
			struct fut_state_callbacks_1* cbs0 = _0.as1;
			
			struct fut_state_callbacks_1* temp1;
			uint8_t* _2 = alloc(ctx, sizeof(struct fut_state_callbacks_1));
			temp1 = ((struct fut_state_callbacks_1*) _2);
			
			*temp1 = (struct fut_state_callbacks_1) {_closure->cb, (struct opt_10) {1, .as1 = cbs0}};
			return (_closure->f->state = (struct fut_state_1) {1, .as1 = temp1}, (struct void_) {});
		}
		case 2: {
			struct void_ r1 = _0.as2;
			
			return subscript_7(ctx, _closure->cb, (struct result_1) {0, .as0 = r1});
		}
		case 3: {
			struct exception e2 = _0.as3;
			
			return subscript_7(ctx, _closure->cb, (struct result_1) {1, .as1 = e2});
		}
		default:
			
	return (struct void_) {};;
	}
}
/* forward-to!<out> void(from fut<nat64>, to fut<nat64>) */
struct void_ forward_to__e(struct ctx* ctx, struct fut_0* from, struct fut_0* to) {
	struct forward_to__e__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct forward_to__e__lambda0));
	temp0 = ((struct forward_to__e__lambda0*) _0);
	
	*temp0 = (struct forward_to__e__lambda0) {to};
	return callback__e_1(ctx, from, (struct fun_act1_0) {0, .as0 = temp0});
}
/* callback!<a> void(f fut<nat64>, cb fun-act1<void, result<nat64, exception>>) */
struct void_ callback__e_1(struct ctx* ctx, struct fut_0* f, struct fun_act1_0 cb) {
	struct callback__e_1__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct callback__e_1__lambda0));
	temp0 = ((struct callback__e_1__lambda0*) _0);
	
	*temp0 = (struct callback__e_1__lambda0) {f, cb};
	return with_lock_0(ctx, (&f->lk), (struct fun_act0_0) {1, .as1 = temp0});
}
/* subscript<void, result<a, exception>> void(a fun-act1<void, result<nat64, exception>>, p0 result<nat64, exception>) */
struct void_ subscript_8(struct ctx* ctx, struct fun_act1_0 a, struct result_0 p0) {
	return call_w_ctx_220(a, ctx, p0);
}
/* call-w-ctx<void, result<nat64, exception>> (generated) (generated) */
struct void_ call_w_ctx_220(struct fun_act1_0 a, struct ctx* ctx, struct result_0 p0) {
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
/* callback!<a>.lambda0 void() */
struct void_ callback__e_1__lambda0(struct ctx* ctx, struct callback__e_1__lambda0* _closure) {
	struct fut_state_0 _0 = _closure->f->state;
	switch (_0.kind) {
		case 0: {
			struct fut_state_callbacks_0* temp0;
			uint8_t* _1 = alloc(ctx, sizeof(struct fut_state_callbacks_0));
			temp0 = ((struct fut_state_callbacks_0*) _1);
			
			*temp0 = (struct fut_state_callbacks_0) {_closure->cb, (struct opt_0) {0, .as0 = (struct void_) {}}};
			return (_closure->f->state = (struct fut_state_0) {1, .as1 = temp0}, (struct void_) {});
		}
		case 1: {
			struct fut_state_callbacks_0* cbs0 = _0.as1;
			
			struct fut_state_callbacks_0* temp1;
			uint8_t* _2 = alloc(ctx, sizeof(struct fut_state_callbacks_0));
			temp1 = ((struct fut_state_callbacks_0*) _2);
			
			*temp1 = (struct fut_state_callbacks_0) {_closure->cb, (struct opt_0) {1, .as1 = cbs0}};
			return (_closure->f->state = (struct fut_state_0) {1, .as1 = temp1}, (struct void_) {});
		}
		case 2: {
			uint64_t r1 = _0.as2;
			
			return subscript_8(ctx, _closure->cb, (struct result_0) {0, .as0 = r1});
		}
		case 3: {
			struct exception e2 = _0.as3;
			
			return subscript_8(ctx, _closure->cb, (struct result_0) {1, .as1 = e2});
		}
		default:
			
	return (struct void_) {};;
	}
}
/* resolve-or-reject!<a> void(f fut<nat64>, result result<nat64, exception>) */
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
/* with-lock<fut-state<a>> fut-state<nat64>(a lock, f fun-act0<fut-state<nat64>>) */
struct fut_state_0 with_lock_1(struct ctx* ctx, struct lock* a, struct fun_act0_2 f) {
	acquire__e(a);
	struct fut_state_0 res0;
	res0 = subscript_9(ctx, f);
	
	release__e(a);
	return res0;
}
/* subscript<a> fut-state<nat64>(a fun-act0<fut-state<nat64>>) */
struct fut_state_0 subscript_9(struct ctx* ctx, struct fun_act0_2 a) {
	return call_w_ctx_225(a, ctx);
}
/* call-w-ctx<fut-state<nat64>> (generated) (generated) */
struct fut_state_0 call_w_ctx_225(struct fun_act0_2 a, struct ctx* ctx) {
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
/* resolve-or-reject!<a>.lambda0 fut-state<nat64>() */
struct fut_state_0 resolve_or_reject__e__lambda0(struct ctx* ctx, struct resolve_or_reject__e__lambda0* _closure) {
	struct fut_state_0 old0;
	old0 = _closure->f->state;
	
	struct result_0 _0 = _closure->result;struct fut_state_0 _1;
	
	switch (_0.kind) {
		case 0: {
			uint64_t o1 = _0.as0;
			
			_1 = (struct fut_state_0) {2, .as2 = o1};
			break;
		}
		case 1: {
			struct exception e2 = _0.as1;
			
			_1 = (struct fut_state_0) {3, .as3 = e2};
			break;
		}
		default:
			
	_1 = (struct fut_state_0) {0};;
	}
	_closure->f->state = _1;
	return old0;
}
/* call-callbacks!<a> void(cbs fut-state-callbacks<nat64>, value result<nat64, exception>) */
struct void_ call_callbacks__e(struct ctx* ctx, struct fut_state_callbacks_0* cbs, struct result_0 value) {
	top:;
	subscript_8(ctx, cbs->cb, value);
	struct opt_0 _0 = cbs->next;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct fut_state_callbacks_0* _matched0 = _0.as1;
			
			cbs = _matched0;
			value = value;
			goto top;
		}
		default:
			
	return (struct void_) {};;
	}
}
/* forward-to!<out>.lambda0 void(it result<nat64, exception>) */
struct void_ forward_to__e__lambda0(struct ctx* ctx, struct forward_to__e__lambda0* _closure, struct result_0 it) {
	return resolve_or_reject__e(ctx, _closure->to, it);
}
/* subscript<out, in> fut<nat64>(f fun-ref1<nat64, void>, p0 void) */
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
/* get-island island(island-id nat64) */
struct island* get_island(struct ctx* ctx, uint64_t island_id) {
	struct global_ctx* _0 = get_global_ctx(ctx);
	return subscript_11(ctx, _0->islands, island_id);
}
/* subscript<island> island(a arr<island>, index nat64) */
struct island* subscript_11(struct ctx* ctx, struct arr_4 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert(ctx, _0);
	return unsafe_at_0(a, index);
}
/* unsafe-at<a> island(a arr<island>, index nat64) */
struct island* unsafe_at_0(struct arr_4 a, uint64_t index) {
	return subscript_12(a.begin_ptr, index);
}
/* subscript<a> island(a const-ptr<island>, n nat64) */
struct island* subscript_12(struct island** a, uint64_t n) {
	struct island** _0 = _plus_5(a, n);
	return _times_5(_0);
}
/* *<a> island(a const-ptr<island>) */
struct island* _times_5(struct island** a) {
	return (*((struct island**) a));
}
/* +<a> const-ptr<island>(a const-ptr<island>, offset nat64) */
struct island** _plus_5(struct island** a, uint64_t offset) {
	return ((struct island**) (((struct island**) a) + offset));
}
/* add-task void(a island, exclusion nat64, action fun-act0<void>) */
struct void_ add_task_0(struct ctx* ctx, struct island* a, uint64_t exclusion, struct fun_act0_0 action) {
	uint64_t _0 = no_timestamp();
	return add_task_1(ctx, a, _0, exclusion, action);
}
/* add-task void(a island, timestamp nat64, exclusion nat64, action fun-act0<void>) */
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
	
	*temp0 = (struct task_queue_node) {task, (struct opt_3) {0, .as0 = (struct void_) {}}};
	return temp0;
}
/* insert-task! void(a task-queue, inserted task-queue-node) */
struct void_ insert_task__e(struct task_queue* a, struct task_queue_node* inserted) {
	uint64_t size_before0;
	size_before0 = size_1(a);
	
	struct opt_3 _0 = a->head;
	switch (_0.kind) {
		case 0: {
			a->head = (struct opt_3) {1, .as1 = inserted};
			break;
		}
		case 1: {
			struct task_queue_node* _matched1 = _0.as1;
			
			uint8_t _1 = _lessOrEqual_0(_matched1->task.time, inserted->task.time);
			if (_1) {
				insert_recur(_matched1, inserted);
			} else {
				inserted->next = (struct opt_3) {1, .as1 = _matched1};
				a->head = (struct opt_3) {1, .as1 = inserted};
			}
			break;
		}
		default:
			
	(struct void_) {};;
	}
	uint64_t size_after2;
	size_after2 = size_1(a);
	
	return hard_assert(((size_before0 + 1u) == size_after2));
}
/* size nat64(a task-queue) */
uint64_t size_1(struct task_queue* a) {
	return size_recur(a->head, 0u);
}
/* size-recur nat64(node opt<task-queue-node>, acc nat64) */
uint64_t size_recur(struct opt_3 node, uint64_t acc) {
	top:;
	struct opt_3 _0 = node;
	switch (_0.kind) {
		case 0: {
			return acc;
		}
		case 1: {
			struct task_queue_node* _matched0 = _0.as1;
			
			node = _matched0->next;
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
	struct opt_3 _0 = prev->next;
	switch (_0.kind) {
		case 0: {
			return (prev->next = (struct opt_3) {1, .as1 = inserted}, (struct void_) {});
		}
		case 1: {
			struct task_queue_node* _matched0 = _0.as1;
			
			uint8_t _1 = _lessOrEqual_0(_matched0->task.time, inserted->task.time);
			if (_1) {
				prev = _matched0;
				inserted = inserted;
				goto top;
			} else {
				inserted->next = (struct opt_3) {1, .as1 = _matched0};
				return (prev->next = (struct opt_3) {1, .as1 = inserted}, (struct void_) {});
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
/* no-timestamp nat64() */
uint64_t no_timestamp(void) {
	return 0u;
}
/* catch<void> void(try fun-act0<void>, catcher fun-act1<void, exception>) */
struct void_ catch(struct ctx* ctx, struct fun_act0_0 try, struct fun_act1_5 catcher) {
	struct exception_ctx* _0 = get_exception_ctx(ctx);
	return catch_with_exception_ctx(ctx, _0, try, catcher);
}
/* catch-with-exception-ctx<a> void(ec exception-ctx, try fun-act0<void>, catcher fun-act1<void, exception>) */
struct void_ catch_with_exception_ctx(struct ctx* ctx, struct exception_ctx* ec, struct fun_act0_0 try, struct fun_act1_5 catcher) {
	struct exception old_thrown_exception0;
	old_thrown_exception0 = ec->thrown_exception;
	
	struct __jmp_buf_tag* old_jmp_buf1;
	old_jmp_buf1 = ec->jmp_buf_ptr;
	
	struct __jmp_buf_tag store2;
	struct bytes64 _0 = zero_0();
	struct bytes128 _1 = zero_3();
	store2 = (struct __jmp_buf_tag) {_0, 0, _1};
	
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
/* subscript<a, exception> void(a fun-act1<void, exception>, p0 exception) */
struct void_ subscript_13(struct ctx* ctx, struct fun_act1_5 a, struct exception p0) {
	return call_w_ctx_257(a, ctx, p0);
}
/* call-w-ctx<void, exception> (generated) (generated) */
struct void_ call_w_ctx_257(struct fun_act1_5 a, struct ctx* ctx, struct exception p0) {
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
		case 2: {
			struct with_log_handler__lambda1* closure2 = _0.as2;
			
			return with_log_handler__lambda1(ctx, closure2, p0);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* subscript<fut<r>, p0> fut<nat64>(a fun-act1<fut<nat64>, void>, p0 void) */
struct fut_0* subscript_14(struct ctx* ctx, struct fun_act1_4 a, struct void_ p0) {
	return call_w_ctx_259(a, ctx, p0);
}
/* call-w-ctx<gc-ptr(fut<nat64>), void> (generated) (generated) */
struct fut_0* call_w_ctx_259(struct fun_act1_4 a, struct ctx* ctx, struct void_ p0) {
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
/* subscript<out, in>.lambda0.lambda0 void() */
struct void_ subscript_10__lambda0__lambda0(struct ctx* ctx, struct subscript_10__lambda0__lambda0* _closure) {
	struct fut_0* _0 = subscript_14(ctx, _closure->f.fun, _closure->p0);
	return forward_to__e(ctx, _0, _closure->res);
}
/* reject!<r> void(f fut<nat64>, e exception) */
struct void_ reject__e(struct ctx* ctx, struct fut_0* f, struct exception e) {
	return resolve_or_reject__e(ctx, f, (struct result_0) {1, .as1 = e});
}
/* subscript<out, in>.lambda0.lambda1 void(err exception) */
struct void_ subscript_10__lambda0__lambda1(struct ctx* ctx, struct subscript_10__lambda0__lambda1* _closure, struct exception err) {
	return reject__e(ctx, _closure->res, err);
}
/* subscript<out, in>.lambda0 void() */
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
/* then<out, void>.lambda0 void(result result<void, exception>) */
struct void_ then__lambda0(struct ctx* ctx, struct then__lambda0* _closure, struct result_1 result) {
	struct result_1 _0 = result;
	switch (_0.kind) {
		case 0: {
			struct void_ o0 = _0.as0;
			
			struct fut_0* _1 = subscript_10(ctx, _closure->cb, o0);
			return forward_to__e(ctx, _1, _closure->res);
		}
		case 1: {
			struct exception e1 = _0.as1;
			
			return reject__e(ctx, _closure->res, e1);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* subscript<out> fut<nat64>(f fun-ref0<nat64>) */
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
/* subscript<fut<r>> fut<nat64>(a fun-act0<fut<nat64>>) */
struct fut_0* subscript_16(struct ctx* ctx, struct fun_act0_1 a) {
	return call_w_ctx_267(a, ctx);
}
/* call-w-ctx<gc-ptr(fut<nat64>)> (generated) (generated) */
struct fut_0* call_w_ctx_267(struct fun_act0_1 a, struct ctx* ctx) {
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
/* subscript<out>.lambda0.lambda0 void() */
struct void_ subscript_15__lambda0__lambda0(struct ctx* ctx, struct subscript_15__lambda0__lambda0* _closure) {
	struct fut_0* _0 = subscript_16(ctx, _closure->f.fun);
	return forward_to__e(ctx, _0, _closure->res);
}
/* subscript<out>.lambda0.lambda1 void(err exception) */
struct void_ subscript_15__lambda0__lambda1(struct ctx* ctx, struct subscript_15__lambda0__lambda1* _closure, struct exception err) {
	return reject__e(ctx, _closure->res, err);
}
/* subscript<out>.lambda0 void() */
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
/* then-void<nat64>.lambda0 fut<nat64>(ignore void) */
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
	*temp0 = (struct fut_1) {_1, (struct fut_state_1) {2, .as2 = value}};
	return temp0;
}
/* tail<const-ptr<char>> arr<const-ptr<char>>(a arr<const-ptr<char>>) */
struct arr_7 tail(struct ctx* ctx, struct arr_7 a) {
	uint8_t _0 = is_empty_2(a);
	forbid(ctx, _0);
	struct range _1 = _range(ctx, 1u, a.size);
	return subscript_17(ctx, a, _1);
}
/* is-empty<a> bool(a arr<const-ptr<char>>) */
uint8_t is_empty_2(struct arr_7 a) {
	return (a.size == 0u);
}
/* subscript<a> arr<const-ptr<char>>(a arr<const-ptr<char>>, range range<nat64>) */
struct arr_7 subscript_17(struct ctx* ctx, struct arr_7 a, struct range range) {
	uint8_t _0 = _lessOrEqual_0(range.high, a.size);
	assert(ctx, _0);
	char** _1 = _plus_6(a.begin_ptr, range.low);
	return (struct arr_7) {(range.high - range.low), _1};
}
/* +<a> const-ptr<const-ptr<char>>(a const-ptr<const-ptr<char>>, offset nat64) */
char** _plus_6(char** a, uint64_t offset) {
	return ((char**) (((char**) a) + offset));
}
/* map<str, const-ptr<char>> arr<str>(a arr<const-ptr<char>>, f fun-act1<str, const-ptr<char>>) */
struct arr_2 map(struct ctx* ctx, struct arr_7 a, struct fun_act1_6 f) {
	struct map__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct map__lambda0));
	temp0 = ((struct map__lambda0*) _0);
	
	*temp0 = (struct map__lambda0) {f, a};
	return make_arr(ctx, a.size, (struct fun_act1_7) {0, .as0 = temp0});
}
/* make-arr<out> arr<str>(size nat64, f fun-act1<str, nat64>) */
struct arr_2 make_arr(struct ctx* ctx, uint64_t size, struct fun_act1_7 f) {
	struct str* res0;
	res0 = alloc_uninitialized_1(ctx, size);
	
	fill_ptr_range(ctx, res0, size, f);
	return (struct arr_2) {size, ((struct str*) res0)};
}
/* alloc-uninitialized<a> mut-ptr<str>(size nat64) */
struct str* alloc_uninitialized_1(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(struct str)));
	return ((struct str*) _0);
}
/* fill-ptr-range<a> void(begin mut-ptr<str>, size nat64, f fun-act1<str, nat64>) */
struct void_ fill_ptr_range(struct ctx* ctx, struct str* begin, uint64_t size, struct fun_act1_7 f) {
	return fill_ptr_range_recur(ctx, begin, 0u, size, f);
}
/* fill-ptr-range-recur<a> void(begin mut-ptr<str>, i nat64, size nat64, f fun-act1<str, nat64>) */
struct void_ fill_ptr_range_recur(struct ctx* ctx, struct str* begin, uint64_t i, uint64_t size, struct fun_act1_7 f) {
	top:;
	uint8_t _0 = _notEqual_5(i, size);
	if (_0) {
		struct str _1 = subscript_18(ctx, f, i);
		set_subscript_2(begin, i, _1);
		begin = begin;
		i = (i + 1u);
		size = size;
		f = f;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* !=<nat64> bool(a nat64, b nat64) */
uint8_t _notEqual_5(uint64_t a, uint64_t b) {
	return _not((a == b));
}
/* set-subscript<a> void(a mut-ptr<str>, n nat64, value str) */
struct void_ set_subscript_2(struct str* a, uint64_t n, struct str value) {
	return (*(a + n) = value, (struct void_) {});
}
/* subscript<a, nat64> str(a fun-act1<str, nat64>, p0 nat64) */
struct str subscript_18(struct ctx* ctx, struct fun_act1_7 a, uint64_t p0) {
	return call_w_ctx_287(a, ctx, p0);
}
/* call-w-ctx<str, nat-64> (generated) (generated) */
struct str call_w_ctx_287(struct fun_act1_7 a, struct ctx* ctx, uint64_t p0) {
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
/* subscript<out, in> str(a fun-act1<str, const-ptr<char>>, p0 const-ptr<char>) */
struct str subscript_19(struct ctx* ctx, struct fun_act1_6 a, char* p0) {
	return call_w_ctx_289(a, ctx, p0);
}
/* call-w-ctx<str, raw-ptr-const(char)> (generated) (generated) */
struct str call_w_ctx_289(struct fun_act1_6 a, struct ctx* ctx, char* p0) {
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
/* subscript<in> const-ptr<char>(a arr<const-ptr<char>>, index nat64) */
char* subscript_20(struct ctx* ctx, struct arr_7 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert(ctx, _0);
	return unsafe_at_1(a, index);
}
/* unsafe-at<a> const-ptr<char>(a arr<const-ptr<char>>, index nat64) */
char* unsafe_at_1(struct arr_7 a, uint64_t index) {
	return subscript_21(a.begin_ptr, index);
}
/* subscript<a> const-ptr<char>(a const-ptr<const-ptr<char>>, n nat64) */
char* subscript_21(char** a, uint64_t n) {
	char** _0 = _plus_6(a, n);
	return _times_6(_0);
}
/* *<a> const-ptr<char>(a const-ptr<const-ptr<char>>) */
char* _times_6(char** a) {
	return (*((char**) a));
}
/* map<str, const-ptr<char>>.lambda0 str(i nat64) */
struct str map__lambda0(struct ctx* ctx, struct map__lambda0* _closure, uint64_t i) {
	char* _0 = subscript_20(ctx, _closure->a, i);
	return subscript_19(ctx, _closure->f, _0);
}
/* add-first-task.lambda0.lambda0 str(arg const-ptr<char>) */
struct str add_first_task__lambda0__lambda0(struct ctx* ctx, struct void_ _closure, char* arg) {
	return to_str_1(arg);
}
/* add-first-task.lambda0 fut<nat64>() */
struct fut_0* add_first_task__lambda0(struct ctx* ctx, struct add_first_task__lambda0* _closure) {
	struct arr_7 args0;
	args0 = tail(ctx, _closure->all_args);
	
	struct arr_2 _0 = map(ctx, args0, (struct fun_act1_6) {0, .as0 = (struct void_) {}});
	return _closure->main_ptr(ctx, _0);
}
/* handle-exceptions<nat64> void(a fut<nat64>) */
struct void_ handle_exceptions(struct ctx* ctx, struct fut_0* a) {
	return callback__e_1(ctx, a, (struct fun_act1_0) {1, .as1 = (struct void_) {}});
}
/* subscript<void, exception> void(a fun1<void, exception>, p0 exception) */
struct void_ subscript_22(struct ctx* ctx, struct fun1_0 a, struct exception p0) {
	return call_w_ctx_299(a, ctx, p0);
}
/* call-w-ctx<void, exception> (generated) (generated) */
struct void_ call_w_ctx_299(struct fun1_0 a, struct ctx* ctx, struct exception p0) {
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
/* handle-exceptions<nat64>.lambda0 void(result result<nat64, exception>) */
struct void_ handle_exceptions__lambda0(struct ctx* ctx, struct void_ _closure, struct result_0 result) {
	struct result_0 _0 = result;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct exception e0 = _0.as1;
			
			struct island* _1 = get_cur_island(ctx);
			struct fun1_0 _2 = exception_handler(ctx, _1);
			return subscript_22(ctx, _2, e0);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* add-main-task.lambda0 fut<nat64>(all-args arr<const-ptr<char>>, main-ptr fun-ptr2<fut<nat64>, ctx, arr<str>>) */
struct fut_0* add_main_task__lambda0(struct ctx* ctx, struct void_ _closure, struct arr_7 all_args, fun_ptr2 main_ptr) {
	return add_first_task(ctx, all_args, main_ptr);
}
/* call-w-ctx<gc-ptr(fut<nat64>), arr<const-ptr<char>>, some fun ptr type> (generated) (generated) */
struct fut_0* call_w_ctx_304(struct fun_act2 a, struct ctx* ctx, struct arr_7 p0, fun_ptr2 p1) {
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
/* run-threads void(n-threads nat64, gctx global-ctx) */
struct void_ run_threads(uint64_t n_threads, struct global_ctx* gctx) {
	uint64_t* threads0;
	threads0 = unmanaged_alloc_elements_0(n_threads);
	
	struct thread_args* thread_args1;
	thread_args1 = unmanaged_alloc_elements_1(n_threads);
	
	uint64_t actual_n_threads2;
	actual_n_threads2 = (n_threads - 1u);
	
	start_threads_recur(0u, actual_n_threads2, threads0, thread_args1, gctx);
	thread_function(actual_n_threads2, gctx);
	join_threads_recur(0u, actual_n_threads2, ((uint64_t*) threads0));
	unmanaged_free_0(threads0);
	return unmanaged_free_1(thread_args1);
}
/* unmanaged-alloc-elements<by-val<thread-args>> mut-ptr<thread-args>(size-elements nat64) */
struct thread_args* unmanaged_alloc_elements_1(uint64_t size_elements) {
	uint8_t* _0 = unmanaged_alloc_bytes((size_elements * sizeof(struct thread_args)));
	return ((struct thread_args*) _0);
}
/* start-threads-recur void(i nat64, n-threads nat64, threads mut-ptr<nat64>, thread-args-begin mut-ptr<thread-args>, gctx global-ctx) */
struct void_ start_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads, struct thread_args* thread_args_begin, struct global_ctx* gctx) {
	top:;
	uint8_t _0 = _notEqual_5(i, n_threads);
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
/* create-one-thread void(tid cell<nat64>, thread-arg mut-ptr<nat8>, thread-fun fun-ptr1<mut-ptr<nat8>, mut-ptr<nat8>>) */
struct void_ create_one_thread(struct cell_0* tid, uint8_t* thread_arg, fun_ptr1 thread_fun) {
	int32_t err0;
	uint8_t* _0 = null();
	err0 = pthread_create(tid, _0, thread_fun, thread_arg);
	
	uint8_t _1 = _notEqual_6(err0, 0);
	if (_1) {
		int32_t _2 = EAGAIN();
		uint8_t _3 = (err0 == _2);
		if (_3) {
			return todo_0();
		} else {
			return todo_0();
		}
	} else {
		return (struct void_) {};
	}
}
/* null<nat8> const-ptr<nat8>() */
uint8_t* null(void) {
	return ((uint8_t*) NULL);
}
/* !=<int32> bool(a int32, b int32) */
uint8_t _notEqual_6(int32_t a, int32_t b) {
	return _not((a == b));
}
/* EAGAIN int32() */
int32_t EAGAIN(void) {
	return 11;
}
/* as-cell<nat64> cell<nat64>(a mut-ptr<nat64>) */
struct cell_0* as_cell(uint64_t* a) {
	return ((struct cell_0*) ((uint8_t*) a));
}
/* thread-fun mut-ptr<nat8>(args-ptr mut-ptr<nat8>) */
uint8_t* thread_fun(uint8_t* args_ptr) {
	struct thread_args* args0;
	args0 = ((struct thread_args*) args_ptr);
	
	thread_function(args0->thread_id, args0->gctx);
	return NULL;
}
/* thread-function void(thread-id nat64, gctx global-ctx) */
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
	uint8_t _0 = gctx->is_shut_down;
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
				
				uint8_t _3 = n2.no_tasks_and_last_thread_out;
				if (_3) {
					hard_forbid(gctx->is_shut_down);
					gctx->is_shut_down = 1;
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
/* assert-islands-are-shut-down void(i nat64, islands arr<island>) */
struct void_ assert_islands_are_shut_down(uint64_t i, struct arr_4 islands) {
	top:;
	uint8_t _0 = _notEqual_5(i, islands.size);
	if (_0) {
		struct island* island0;
		island0 = noctx_at_0(islands, i);
		
		acquire__e((&island0->tasks_lock));
		hard_forbid((&island0->gc)->needs_gc);
		hard_assert((island0->n_threads_running == 0u));
		struct task_queue* _1 = tasks(island0);
		uint8_t _2 = is_empty_3(_1);
		hard_assert(_2);
		release__e((&island0->tasks_lock));
		i = (i + 1u);
		islands = islands;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* noctx-at<island> island(a arr<island>, index nat64) */
struct island* noctx_at_0(struct arr_4 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	hard_assert(_0);
	return unsafe_at_0(a, index);
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
/* is-empty bool(a task-queue) */
uint8_t is_empty_3(struct task_queue* a) {
	return is_empty_4(a->head);
}
/* is-empty<task-queue-node> bool(a opt<task-queue-node>) */
uint8_t is_empty_4(struct opt_3 a) {
	struct opt_3 _0 = a;
	switch (_0.kind) {
		case 0: {
			return 1;
		}
		case 1: {
			struct task_queue_node* _matched0 = _0.as1;
			
			drop_1(_matched0);
			return 0;
		}
		default:
			
	return 0;;
	}
}
/* drop<a> void(_ task-queue-node) */
struct void_ drop_1(struct task_queue_node* _p0) {
	return (struct void_) {};
}
/* get-sequence nat64(a condition) */
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
	struct choose_task_result _0 = choose_task_recur(gctx->islands, 0u, cur_time0, 0, (struct opt_11) {0, .as0 = (struct void_) {}});
	switch (_0.kind) {
		case 0: {
			struct chosen_task c1 = _0.as0;
			
			res4 = (struct choose_task_result) {0, .as0 = c1};
			break;
		}
		case 1: {
			struct no_chosen_task n2 = _0.as1;
			
			gctx->n_live_threads = (gctx->n_live_threads - 1u);
			uint8_t no_task_and_last_thread_out3;
			if (n2.no_tasks_and_last_thread_out) {
				no_task_and_last_thread_out3 = (gctx->n_live_threads == 0u);
			} else {
				no_task_and_last_thread_out3 = 0;
			}
			
			res4 = (struct choose_task_result) {1, .as1 = (struct no_chosen_task) {no_task_and_last_thread_out3, n2.first_task_time}};
			break;
		}
		default:
			
	res4 = (struct choose_task_result) {0};;
	}
	
	release__e((&gctx->lk));
	return res4;
}
/* get-monotime-nsec nat64() */
uint64_t get_monotime_nsec(void) {
	struct cell_1 time_cell0;
	time_cell0 = (struct cell_1) {(struct timespec) {0, 0}};
	
	int32_t err1;
	int32_t _0 = CLOCK_MONOTONIC();
	err1 = clock_gettime(_0, (&time_cell0));
	
	uint8_t _1 = (err1 == 0);
	if (_1) {
		struct timespec time2;
		time2 = _times_7((&time_cell0));
		
		return ((uint64_t) ((time2.tv_sec * 1000000000) + time2.tv_nsec));
	} else {
		return todo_2();
	}
}
/* *<timespec> timespec(a cell<timespec>) */
struct timespec _times_7(struct cell_1* a) {
	return a->inner_value;
}
/* todo<nat64> nat64() */
uint64_t todo_2(void) {
	(abort(), (struct void_) {});
	return 0;
}
/* choose-task-recur choose-task-result(islands arr<island>, i nat64, cur-time nat64, any-tasks bool, first-task-time opt<nat64>) */
struct choose_task_result choose_task_recur(struct arr_4 islands, uint64_t i, uint64_t cur_time, uint8_t any_tasks, struct opt_11 first_task_time) {
	top:;
	uint8_t _0 = (i == islands.size);
	if (_0) {
		uint8_t _1 = _not(any_tasks);
		return (struct choose_task_result) {1, .as1 = (struct no_chosen_task) {_1, first_task_time}};
	} else {
		struct island* island0;
		island0 = noctx_at_0(islands, i);
		
		struct choose_task_in_island_result chose1;
		chose1 = choose_task_in_island(island0, cur_time);
		
		struct choose_task_in_island_result _2 = chose1;
		switch (_2.kind) {
			case 0: {
				struct task t2 = _2.as0;
				
				return (struct choose_task_result) {0, .as0 = (struct chosen_task) {island0, (struct task_or_gc) {0, .as0 = t2}}};
			}
			case 1: {
				return (struct choose_task_result) {0, .as0 = (struct chosen_task) {island0, (struct task_or_gc) {1, .as1 = (struct void_) {}}}};
			}
			case 2: {
				struct no_task n3 = _2.as2;
				
				uint8_t new_any_tasks4;
				if (any_tasks) {
					new_any_tasks4 = 1;
				} else {
					new_any_tasks4 = n3.any_tasks;
				}
				
				struct opt_11 new_first_task_time5;
				new_first_task_time5 = min_time(first_task_time, n3.first_task_time);
				
				islands = islands;
				i = (i + 1u);
				cur_time = cur_time;
				any_tasks = new_any_tasks4;
				first_task_time = new_first_task_time5;
				goto top;
			}
			default:
				
		return (struct choose_task_result) {0};;
		}
	}
}
/* choose-task-in-island choose-task-in-island-result(island island, cur-time nat64) */
struct choose_task_in_island_result choose_task_in_island(struct island* island, uint64_t cur_time) {
	acquire__e((&island->tasks_lock));
	struct choose_task_in_island_result res2;
	uint8_t _0 = (&island->gc)->needs_gc;
	if (_0) {
		uint8_t _1 = (island->n_threads_running == 0u);
		if (_1) {
			res2 = (struct choose_task_in_island_result) {1, .as1 = (struct void_) {}};
		} else {
			res2 = (struct choose_task_in_island_result) {2, .as2 = (struct no_task) {1, (struct opt_11) {0, .as0 = (struct void_) {}}}};
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
	
	uint8_t _4 = is_no_task(res2);
	uint8_t _5 = _not(_4);
	if (_5) {
		island->n_threads_running = (island->n_threads_running + 1u);
	} else {
		(struct void_) {};
	}
	release__e((&island->tasks_lock));
	return res2;
}
/* pop-task! pop-task-result(a task-queue, cur-time nat64) */
struct pop_task_result pop_task__e(struct task_queue* a, uint64_t cur_time) {
	struct mut_arr_0* exclusions0;
	exclusions0 = (&a->currently_running_exclusions);
	
	struct pop_task_result res3;
	struct opt_3 _0 = a->head;
	switch (_0.kind) {
		case 0: {
			res3 = (struct pop_task_result) {1, .as1 = (struct no_task) {0, (struct opt_11) {0, .as0 = (struct void_) {}}}};
			break;
		}
		case 1: {
			struct task_queue_node* _matched1 = _0.as1;
			
			struct task task2;
			task2 = _matched1->task;
			
			uint8_t _1 = _lessOrEqual_0(task2.time, cur_time);
			if (_1) {
				uint8_t _2 = in_0(task2.exclusion, exclusions0);
				if (_2) {
					struct opt_11 _3 = to_opt_time(task2.time);
					res3 = pop_recur__e(_matched1, exclusions0, cur_time, _3);
				} else {
					a->head = _matched1->next;
					res3 = (struct pop_task_result) {0, .as0 = _matched1->task};
				}
			} else {
				res3 = (struct pop_task_result) {1, .as1 = (struct no_task) {1, (struct opt_11) {1, .as1 = task2.time}}};
			}
			break;
		}
		default:
			
	res3 = (struct pop_task_result) {0};;
	}
	
	struct pop_task_result _4 = res3;
	switch (_4.kind) {
		case 0: {
			struct task t4 = _4.as0;
			
			push_capacity_must_be_sufficient__e(exclusions0, t4.exclusion);
			break;
		}
		case 1: {
			(struct void_) {};
			break;
		}
		default:
			
	(struct void_) {};;
	}
	return res3;
}
/* in<nat64> bool(value nat64, a mut-arr<nat64>) */
uint8_t in_0(uint64_t value, struct mut_arr_0* a) {
	struct arr_3 _0 = temp_as_arr_0(a);
	return in_1(value, _0);
}
/* in<a> bool(value nat64, a arr<nat64>) */
uint8_t in_1(uint64_t value, struct arr_3 a) {
	return in_recur(value, a, 0u);
}
/* in-recur<a> bool(value nat64, a arr<nat64>, i nat64) */
uint8_t in_recur(uint64_t value, struct arr_3 a, uint64_t i) {
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
			value = value;
			a = a;
			i = (i + 1u);
			goto top;
		}
	}
}
/* noctx-at<a> nat64(a arr<nat64>, index nat64) */
uint64_t noctx_at_1(struct arr_3 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	hard_assert(_0);
	return unsafe_at_2(a, index);
}
/* unsafe-at<a> nat64(a arr<nat64>, index nat64) */
uint64_t unsafe_at_2(struct arr_3 a, uint64_t index) {
	return subscript_23(a.begin_ptr, index);
}
/* subscript<a> nat64(a const-ptr<nat64>, n nat64) */
uint64_t subscript_23(uint64_t* a, uint64_t n) {
	uint64_t* _0 = _plus_7(a, n);
	return _times_8(_0);
}
/* *<a> nat64(a const-ptr<nat64>) */
uint64_t _times_8(uint64_t* a) {
	return (*((uint64_t*) a));
}
/* +<a> const-ptr<nat64>(a const-ptr<nat64>, offset nat64) */
uint64_t* _plus_7(uint64_t* a, uint64_t offset) {
	return ((uint64_t*) (((uint64_t*) a) + offset));
}
/* temp-as-arr<a> arr<nat64>(a mut-arr<nat64>) */
struct arr_3 temp_as_arr_0(struct mut_arr_0* a) {
	struct fix_arr_0 _0 = temp_as_fix_arr(a);
	return temp_as_arr_1(_0);
}
/* temp-as-arr<a> arr<nat64>(a fix-arr<nat64>) */
struct arr_3 temp_as_arr_1(struct fix_arr_0 a) {
	return a.inner;
}
/* temp-as-fix-arr<a> fix-arr<nat64>(a mut-arr<nat64>) */
struct fix_arr_0 temp_as_fix_arr(struct mut_arr_0* a) {
	uint64_t* _0 = begin_ptr_2(a);
	return fix_arr_0(a->size, _0);
}
/* begin-ptr<a> mut-ptr<nat64>(a mut-arr<nat64>) */
uint64_t* begin_ptr_2(struct mut_arr_0* a) {
	return begin_ptr_3(a->backing);
}
/* begin-ptr<a> mut-ptr<nat64>(a fix-arr<nat64>) */
uint64_t* begin_ptr_3(struct fix_arr_0 a) {
	return ((uint64_t*) a.inner.begin_ptr);
}
/* pop-recur! pop-task-result(prev task-queue-node, exclusions mut-arr<nat64>, cur-time nat64, first-task-time opt<nat64>) */
struct pop_task_result pop_recur__e(struct task_queue_node* prev, struct mut_arr_0* exclusions, uint64_t cur_time, struct opt_11 first_task_time) {
	top:;
	struct opt_3 _0 = prev->next;
	switch (_0.kind) {
		case 0: {
			return (struct pop_task_result) {1, .as1 = (struct no_task) {1, first_task_time}};
		}
		case 1: {
			struct task_queue_node* _matched0 = _0.as1;
			
			struct task task1;
			task1 = _matched0->task;
			
			uint8_t _1 = _lessOrEqual_0(task1.time, cur_time);
			if (_1) {
				uint8_t _2 = in_0(task1.exclusion, exclusions);
				if (_2) {
					struct opt_11 _3 = first_task_time;struct opt_11 _4;
					
					switch (_3.kind) {
						case 0: {
							_4 = to_opt_time(task1.time);
							break;
						}
						case 1: {
							uint64_t _matched2 = _3.as1;
							
							_4 = (struct opt_11) {1, .as1 = _matched2};
							break;
						}
						default:
							
					_4 = (struct opt_11) {0};;
					}
					prev = _matched0;
					exclusions = exclusions;
					cur_time = cur_time;
					first_task_time = _4;
					goto top;
				} else {
					prev->next = _matched0->next;
					return (struct pop_task_result) {0, .as0 = task1};
				}
			} else {
				return (struct pop_task_result) {1, .as1 = (struct no_task) {1, (struct opt_11) {1, .as1 = task1.time}}};
			}
		}
		default:
			
	return (struct pop_task_result) {0};;
	}
}
/* to-opt-time opt<nat64>(a nat64) */
struct opt_11 to_opt_time(uint64_t a) {
	uint64_t _0 = no_timestamp();
	uint8_t _1 = _notEqual_5(a, _0);
	if (_1) {
		return (struct opt_11) {1, .as1 = a};
	} else {
		return (struct opt_11) {0, .as0 = (struct void_) {}};
	}
}
/* push-capacity-must-be-sufficient!<nat64> void(a mut-arr<nat64>, value nat64) */
struct void_ push_capacity_must_be_sufficient__e(struct mut_arr_0* a, uint64_t value) {
	uint64_t _0 = capacity_1(a);
	uint8_t _1 = _less_0(a->size, _0);
	hard_assert(_1);
	uint64_t* _2 = begin_ptr_2(a);
	set_subscript_3(_2, a->size, value);
	return (a->size = (a->size + 1u), (struct void_) {});
}
/* capacity<a> nat64(a mut-arr<nat64>) */
uint64_t capacity_1(struct mut_arr_0* a) {
	return size_2(a->backing);
}
/* size<a> nat64(a fix-arr<nat64>) */
uint64_t size_2(struct fix_arr_0 a) {
	return a.inner.size;
}
/* set-subscript<a> void(a mut-ptr<nat64>, n nat64, value nat64) */
struct void_ set_subscript_3(uint64_t* a, uint64_t n, uint64_t value) {
	return (*(a + n) = value, (struct void_) {});
}
/* is-no-task bool(a choose-task-in-island-result) */
uint8_t is_no_task(struct choose_task_in_island_result a) {
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
/* min-time opt<nat64>(a opt<nat64>, b opt<nat64>) */
struct opt_11 min_time(struct opt_11 a, struct opt_11 b) {
	struct opt_11 _0 = a;
	switch (_0.kind) {
		case 0: {
			return b;
		}
		case 1: {
			uint64_t _matched0 = _0.as1;
			
			struct opt_11 _1 = b;
			switch (_1.kind) {
				case 0: {
					return (struct opt_11) {0, .as0 = (struct void_) {}};
				}
				case 1: {
					uint64_t _matched1 = _1.as1;
					
					uint64_t _2 = min(_matched0, _matched1);
					return (struct opt_11) {1, .as1 = _2};
				}
				default:
					
			return (struct opt_11) {0};;
			}
		}
		default:
			
	return (struct opt_11) {0};;
	}
}
/* min<nat64> nat64(a nat64, b nat64) */
uint64_t min(uint64_t a, uint64_t b) {
	uint8_t _0 = _less_0(a, b);
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
			
			call_w_ctx_213(task1.action, (&ctx2));
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
/* noctx-must-remove-unordered!<nat64> void(a mut-arr<nat64>, value nat64) */
struct void_ noctx_must_remove_unordered__e(struct mut_arr_0* a, uint64_t value) {
	return noctx_must_remove_unordered_recur__e(a, 0u, value);
}
/* noctx-must-remove-unordered-recur!<a> void(a mut-arr<nat64>, index nat64, value nat64) */
struct void_ noctx_must_remove_unordered_recur__e(struct mut_arr_0* a, uint64_t index, uint64_t value) {
	top:;
	uint8_t _0 = (index == a->size);
	if (_0) {
		return todo_0();
	} else {
		uint64_t* _1 = begin_ptr_2(a);
		uint64_t _2 = subscript_24(_1, index);
		uint8_t _3 = (_2 == value);
		if (_3) {
			uint64_t _4 = noctx_remove_unordered_at__e(a, index);
			return drop_2(_4);
		} else {
			a = a;
			index = (index + 1u);
			value = value;
			goto top;
		}
	}
}
/* subscript<a> nat64(a mut-ptr<nat64>, n nat64) */
uint64_t subscript_24(uint64_t* a, uint64_t n) {
	return (*(a + n));
}
/* drop<a> void(_ nat64) */
struct void_ drop_2(uint64_t _p0) {
	return (struct void_) {};
}
/* noctx-remove-unordered-at!<a> nat64(a mut-arr<nat64>, index nat64) */
uint64_t noctx_remove_unordered_at__e(struct mut_arr_0* a, uint64_t index) {
	uint8_t _0 = _less_0(index, a->size);
	hard_assert(_0);
	uint64_t res0;
	uint64_t* _1 = begin_ptr_2(a);
	res0 = subscript_24(_1, index);
	
	uint64_t new_size1;
	new_size1 = (a->size - 1u);
	
	uint64_t* _2 = begin_ptr_2(a);
	uint64_t* _3 = begin_ptr_2(a);
	uint64_t _4 = subscript_24(_3, new_size1);
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
	gc0->context_head = (struct opt_2) {1, .as1 = gc_ctx};
	return release__e((&gc0->lk));
}
/* run-garbage-collection<by-val<island-gc-root>> void(gc gc, gc-root island-gc-root) */
struct void_ run_garbage_collection(struct gc* gc, struct island_gc_root gc_root) {
	hard_assert(gc->needs_gc);
	gc->gc_count = (gc->gc_count + 1u);
	uint8_t* _0 = memset(((uint8_t*) gc->mark_begin), 0, gc->size_words);
	drop_0(_0);
	struct mark_ctx mark_ctx0;
	mark_ctx0 = (struct mark_ctx) {gc->size_words, gc->mark_begin, gc->data_begin};
	
	mark_visit_364((&mark_ctx0), gc_root);
	uint8_t* prev_mark_cur1;
	prev_mark_cur1 = gc->mark_cur;
	
	gc->mark_cur = gc->mark_begin;
	gc->data_cur = gc->data_begin;
	clear_free_mem__e(gc->mark_begin, prev_mark_cur1, gc->data_begin);
	validate_gc(gc);
	return (gc->needs_gc = 0, (struct void_) {});
}
/* mark-visit<island-gc-root> (generated) (generated) */
struct void_ mark_visit_364(struct mark_ctx* mark_ctx, struct island_gc_root value) {
	mark_visit_365(mark_ctx, value.tasks);
	return mark_visit_415(mark_ctx, value.log_handler);
}
/* mark-visit<task-queue> (generated) (generated) */
struct void_ mark_visit_365(struct mark_ctx* mark_ctx, struct task_queue value) {
	mark_visit_366(mark_ctx, value.head);
	return mark_visit_420(mark_ctx, value.currently_running_exclusions);
}
/* mark-visit<opt<task-queue-node>> (generated) (generated) */
struct void_ mark_visit_366(struct mark_ctx* mark_ctx, struct opt_3 value) {
	struct opt_3 _0 = value;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct task_queue_node* value1 = _0.as1;
			
			return mark_visit_419(mark_ctx, value1);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* mark-visit<task-queue-node> (generated) (generated) */
struct void_ mark_visit_367(struct mark_ctx* mark_ctx, struct task_queue_node value) {
	mark_visit_368(mark_ctx, value.task);
	return mark_visit_366(mark_ctx, value.next);
}
/* mark-visit<task> (generated) (generated) */
struct void_ mark_visit_368(struct mark_ctx* mark_ctx, struct task value) {
	return mark_visit_369(mark_ctx, value.action);
}
/* mark-visit<fun-act0<void>> (generated) (generated) */
struct void_ mark_visit_369(struct mark_ctx* mark_ctx, struct fun_act0_0 value) {
	struct fun_act0_0 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct callback__e_0__lambda0* value0 = _0.as0;
			
			return mark_visit_403(mark_ctx, value0);
		}
		case 1: {
			struct callback__e_1__lambda0* value1 = _0.as1;
			
			return mark_visit_405(mark_ctx, value1);
		}
		case 2: {
			struct subscript_10__lambda0__lambda0* value2 = _0.as2;
			
			return mark_visit_407(mark_ctx, value2);
		}
		case 3: {
			struct subscript_10__lambda0* value3 = _0.as3;
			
			return mark_visit_409(mark_ctx, value3);
		}
		case 4: {
			struct subscript_15__lambda0__lambda0* value4 = _0.as4;
			
			return mark_visit_411(mark_ctx, value4);
		}
		case 5: {
			struct subscript_15__lambda0* value5 = _0.as5;
			
			return mark_visit_413(mark_ctx, value5);
		}
		case 6: {
			struct with_log_handler__lambda0* value6 = _0.as6;
			
			return mark_visit_418(mark_ctx, value6);
		}
		case 7: {
			return (struct void_) {};
		}
		case 8: {
			return (struct void_) {};
		}
		default:
			
	return (struct void_) {};;
	}
}
/* mark-visit<callback!<in>.lambda0> (generated) (generated) */
struct void_ mark_visit_370(struct mark_ctx* mark_ctx, struct callback__e_0__lambda0 value) {
	mark_visit_402(mark_ctx, value.f);
	return mark_visit_374(mark_ctx, value.cb);
}
/* mark-visit<fut<void>> (generated) (generated) */
struct void_ mark_visit_371(struct mark_ctx* mark_ctx, struct fut_1 value) {
	return mark_visit_372(mark_ctx, value.state);
}
/* mark-visit<fut-state<void>> (generated) (generated) */
struct void_ mark_visit_372(struct mark_ctx* mark_ctx, struct fut_state_1 value) {
	struct fut_state_1 _0 = value;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct fut_state_callbacks_1* value1 = _0.as1;
			
			return mark_visit_401(mark_ctx, value1);
		}
		case 2: {
			return (struct void_) {};
		}
		case 3: {
			struct exception value3 = _0.as3;
			
			return mark_visit_394(mark_ctx, value3);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* mark-visit<fut-state-callbacks<void>> (generated) (generated) */
struct void_ mark_visit_373(struct mark_ctx* mark_ctx, struct fut_state_callbacks_1 value) {
	mark_visit_374(mark_ctx, value.cb);
	return mark_visit_400(mark_ctx, value.next);
}
/* mark-visit<fun-act1<void, result<void, exception>>> (generated) (generated) */
struct void_ mark_visit_374(struct mark_ctx* mark_ctx, struct fun_act1_3 value) {
	struct fun_act1_3 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct then__lambda0* value0 = _0.as0;
			
			return mark_visit_399(mark_ctx, value0);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* mark-visit<then<out, void>.lambda0> (generated) (generated) */
struct void_ mark_visit_375(struct mark_ctx* mark_ctx, struct then__lambda0 value) {
	mark_visit_376(mark_ctx, value.cb);
	return mark_visit_390(mark_ctx, value.res);
}
/* mark-visit<fun-ref1<nat64, void>> (generated) (generated) */
struct void_ mark_visit_376(struct mark_ctx* mark_ctx, struct fun_ref1 value) {
	return mark_visit_377(mark_ctx, value.fun);
}
/* mark-visit<fun-act1<fut<nat64>, void>> (generated) (generated) */
struct void_ mark_visit_377(struct mark_ctx* mark_ctx, struct fun_act1_4 value) {
	struct fun_act1_4 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct then_void__lambda0* value0 = _0.as0;
			
			return mark_visit_384(mark_ctx, value0);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* mark-visit<then-void<nat64>.lambda0> (generated) (generated) */
struct void_ mark_visit_378(struct mark_ctx* mark_ctx, struct then_void__lambda0 value) {
	return mark_visit_379(mark_ctx, value.cb);
}
/* mark-visit<fun-ref0<nat64>> (generated) (generated) */
struct void_ mark_visit_379(struct mark_ctx* mark_ctx, struct fun_ref0 value) {
	return mark_visit_380(mark_ctx, value.fun);
}
/* mark-visit<fun-act0<fut<nat64>>> (generated) (generated) */
struct void_ mark_visit_380(struct mark_ctx* mark_ctx, struct fun_act0_1 value) {
	struct fun_act0_1 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct add_first_task__lambda0* value0 = _0.as0;
			
			return mark_visit_383(mark_ctx, value0);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* mark-visit<add-first-task.lambda0> (generated) (generated) */
struct void_ mark_visit_381(struct mark_ctx* mark_ctx, struct add_first_task__lambda0 value) {
	return mark_arr_382(mark_ctx, value.all_args);
}
/* mark-arr<raw-ptr-const(char)> (generated) (generated) */
struct void_ mark_arr_382(struct mark_ctx* mark_ctx, struct arr_7 a) {
	uint8_t dropped0;
	dropped0 = mark(mark_ctx, ((uint8_t*) a.begin_ptr), (a.size * sizeof(char*)));
	
	return (struct void_) {};
}
/* mark-visit<gc-ptr(add-first-task.lambda0)> (generated) (generated) */
struct void_ mark_visit_383(struct mark_ctx* mark_ctx, struct add_first_task__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct add_first_task__lambda0));
	if (_0) {
		return mark_visit_381(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(then-void<nat64>.lambda0)> (generated) (generated) */
struct void_ mark_visit_384(struct mark_ctx* mark_ctx, struct then_void__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct then_void__lambda0));
	if (_0) {
		return mark_visit_378(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<fut<nat64>> (generated) (generated) */
struct void_ mark_visit_385(struct mark_ctx* mark_ctx, struct fut_0 value) {
	return mark_visit_386(mark_ctx, value.state);
}
/* mark-visit<fut-state<nat64>> (generated) (generated) */
struct void_ mark_visit_386(struct mark_ctx* mark_ctx, struct fut_state_0 value) {
	struct fut_state_0 _0 = value;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct fut_state_callbacks_0* value1 = _0.as1;
			
			return mark_visit_393(mark_ctx, value1);
		}
		case 2: {
			return (struct void_) {};
		}
		case 3: {
			struct exception value3 = _0.as3;
			
			return mark_visit_394(mark_ctx, value3);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* mark-visit<fut-state-callbacks<nat64>> (generated) (generated) */
struct void_ mark_visit_387(struct mark_ctx* mark_ctx, struct fut_state_callbacks_0 value) {
	mark_visit_388(mark_ctx, value.cb);
	return mark_visit_392(mark_ctx, value.next);
}
/* mark-visit<fun-act1<void, result<nat64, exception>>> (generated) (generated) */
struct void_ mark_visit_388(struct mark_ctx* mark_ctx, struct fun_act1_0 value) {
	struct fun_act1_0 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct forward_to__e__lambda0* value0 = _0.as0;
			
			return mark_visit_391(mark_ctx, value0);
		}
		case 1: {
			return (struct void_) {};
		}
		default:
			
	return (struct void_) {};;
	}
}
/* mark-visit<forward-to!<out>.lambda0> (generated) (generated) */
struct void_ mark_visit_389(struct mark_ctx* mark_ctx, struct forward_to__e__lambda0 value) {
	return mark_visit_390(mark_ctx, value.to);
}
/* mark-visit<gc-ptr(fut<nat64>)> (generated) (generated) */
struct void_ mark_visit_390(struct mark_ctx* mark_ctx, struct fut_0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct fut_0));
	if (_0) {
		return mark_visit_385(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(forward-to!<out>.lambda0)> (generated) (generated) */
struct void_ mark_visit_391(struct mark_ctx* mark_ctx, struct forward_to__e__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct forward_to__e__lambda0));
	if (_0) {
		return mark_visit_389(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<opt<fut-state-callbacks<nat64>>> (generated) (generated) */
struct void_ mark_visit_392(struct mark_ctx* mark_ctx, struct opt_0 value) {
	struct opt_0 _0 = value;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct fut_state_callbacks_0* value1 = _0.as1;
			
			return mark_visit_393(mark_ctx, value1);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* mark-visit<gc-ptr(fut-state-callbacks<nat64>)> (generated) (generated) */
struct void_ mark_visit_393(struct mark_ctx* mark_ctx, struct fut_state_callbacks_0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct fut_state_callbacks_0));
	if (_0) {
		return mark_visit_387(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<exception> (generated) (generated) */
struct void_ mark_visit_394(struct mark_ctx* mark_ctx, struct exception value) {
	mark_visit_395(mark_ctx, value.message);
	return mark_visit_397(mark_ctx, value.backtrace);
}
/* mark-visit<str> (generated) (generated) */
struct void_ mark_visit_395(struct mark_ctx* mark_ctx, struct str value) {
	return mark_arr_396(mark_ctx, value.chars);
}
/* mark-arr<char> (generated) (generated) */
struct void_ mark_arr_396(struct mark_ctx* mark_ctx, struct arr_0 a) {
	uint8_t dropped0;
	dropped0 = mark(mark_ctx, ((uint8_t*) a.begin_ptr), (a.size * sizeof(char)));
	
	return (struct void_) {};
}
/* mark-visit<backtrace> (generated) (generated) */
struct void_ mark_visit_397(struct mark_ctx* mark_ctx, struct backtrace value) {
	return mark_arr_398(mark_ctx, value.return_stack);
}
/* mark-arr<sym> (generated) (generated) */
struct void_ mark_arr_398(struct mark_ctx* mark_ctx, struct arr_1 a) {
	uint8_t dropped0;
	dropped0 = mark(mark_ctx, ((uint8_t*) a.begin_ptr), (a.size * sizeof(struct sym)));
	
	return (struct void_) {};
}
/* mark-visit<gc-ptr(then<out, void>.lambda0)> (generated) (generated) */
struct void_ mark_visit_399(struct mark_ctx* mark_ctx, struct then__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct then__lambda0));
	if (_0) {
		return mark_visit_375(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<opt<fut-state-callbacks<void>>> (generated) (generated) */
struct void_ mark_visit_400(struct mark_ctx* mark_ctx, struct opt_10 value) {
	struct opt_10 _0 = value;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct fut_state_callbacks_1* value1 = _0.as1;
			
			return mark_visit_401(mark_ctx, value1);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* mark-visit<gc-ptr(fut-state-callbacks<void>)> (generated) (generated) */
struct void_ mark_visit_401(struct mark_ctx* mark_ctx, struct fut_state_callbacks_1* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct fut_state_callbacks_1));
	if (_0) {
		return mark_visit_373(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(fut<void>)> (generated) (generated) */
struct void_ mark_visit_402(struct mark_ctx* mark_ctx, struct fut_1* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct fut_1));
	if (_0) {
		return mark_visit_371(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(callback!<in>.lambda0)> (generated) (generated) */
struct void_ mark_visit_403(struct mark_ctx* mark_ctx, struct callback__e_0__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct callback__e_0__lambda0));
	if (_0) {
		return mark_visit_370(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<callback!<a>.lambda0> (generated) (generated) */
struct void_ mark_visit_404(struct mark_ctx* mark_ctx, struct callback__e_1__lambda0 value) {
	mark_visit_390(mark_ctx, value.f);
	return mark_visit_388(mark_ctx, value.cb);
}
/* mark-visit<gc-ptr(callback!<a>.lambda0)> (generated) (generated) */
struct void_ mark_visit_405(struct mark_ctx* mark_ctx, struct callback__e_1__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct callback__e_1__lambda0));
	if (_0) {
		return mark_visit_404(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<subscript<out, in>.lambda0.lambda0> (generated) (generated) */
struct void_ mark_visit_406(struct mark_ctx* mark_ctx, struct subscript_10__lambda0__lambda0 value) {
	mark_visit_376(mark_ctx, value.f);
	return mark_visit_390(mark_ctx, value.res);
}
/* mark-visit<gc-ptr(subscript<out, in>.lambda0.lambda0)> (generated) (generated) */
struct void_ mark_visit_407(struct mark_ctx* mark_ctx, struct subscript_10__lambda0__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct subscript_10__lambda0__lambda0));
	if (_0) {
		return mark_visit_406(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<subscript<out, in>.lambda0> (generated) (generated) */
struct void_ mark_visit_408(struct mark_ctx* mark_ctx, struct subscript_10__lambda0 value) {
	mark_visit_376(mark_ctx, value.f);
	return mark_visit_390(mark_ctx, value.res);
}
/* mark-visit<gc-ptr(subscript<out, in>.lambda0)> (generated) (generated) */
struct void_ mark_visit_409(struct mark_ctx* mark_ctx, struct subscript_10__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct subscript_10__lambda0));
	if (_0) {
		return mark_visit_408(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<subscript<out>.lambda0.lambda0> (generated) (generated) */
struct void_ mark_visit_410(struct mark_ctx* mark_ctx, struct subscript_15__lambda0__lambda0 value) {
	mark_visit_379(mark_ctx, value.f);
	return mark_visit_390(mark_ctx, value.res);
}
/* mark-visit<gc-ptr(subscript<out>.lambda0.lambda0)> (generated) (generated) */
struct void_ mark_visit_411(struct mark_ctx* mark_ctx, struct subscript_15__lambda0__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct subscript_15__lambda0__lambda0));
	if (_0) {
		return mark_visit_410(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<subscript<out>.lambda0> (generated) (generated) */
struct void_ mark_visit_412(struct mark_ctx* mark_ctx, struct subscript_15__lambda0 value) {
	mark_visit_379(mark_ctx, value.f);
	return mark_visit_390(mark_ctx, value.res);
}
/* mark-visit<gc-ptr(subscript<out>.lambda0)> (generated) (generated) */
struct void_ mark_visit_413(struct mark_ctx* mark_ctx, struct subscript_15__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct subscript_15__lambda0));
	if (_0) {
		return mark_visit_412(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<with-log-handler<void>.lambda0> (generated) (generated) */
struct void_ mark_visit_414(struct mark_ctx* mark_ctx, struct with_log_handler__lambda0 value) {
	mark_visit_415(mark_ctx, value.handler);
	mark_visit_369(mark_ctx, value.cb);
	return mark_visit_415(mark_ctx, value.original_handler);
}
/* mark-visit<fun1<void, logged>> (generated) (generated) */
struct void_ mark_visit_415(struct mark_ctx* mark_ctx, struct fun1_1 value) {
	struct fun1_1 _0 = value;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct main_0__lambda0* value1 = _0.as1;
			
			return mark_visit_417(mark_ctx, value1);
		}
		case 2: {
			return (struct void_) {};
		}
		default:
			
	return (struct void_) {};;
	}
}
/* mark-visit<main.lambda0> (generated) (generated) */
struct void_ mark_visit_416(struct mark_ctx* mark_ctx, struct main_0__lambda0 value) {
	return mark_visit_415(mark_ctx, value.lh);
}
/* mark-visit<gc-ptr(main.lambda0)> (generated) (generated) */
struct void_ mark_visit_417(struct mark_ctx* mark_ctx, struct main_0__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct main_0__lambda0));
	if (_0) {
		return mark_visit_416(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(with-log-handler<void>.lambda0)> (generated) (generated) */
struct void_ mark_visit_418(struct mark_ctx* mark_ctx, struct with_log_handler__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct with_log_handler__lambda0));
	if (_0) {
		return mark_visit_414(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(task-queue-node)> (generated) (generated) */
struct void_ mark_visit_419(struct mark_ctx* mark_ctx, struct task_queue_node* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct task_queue_node));
	if (_0) {
		return mark_visit_367(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<mut-arr<nat64>> (generated) (generated) */
struct void_ mark_visit_420(struct mark_ctx* mark_ctx, struct mut_arr_0 value) {
	return mark_visit_421(mark_ctx, value.backing);
}
/* mark-visit<fix-arr<nat64>> (generated) (generated) */
struct void_ mark_visit_421(struct mark_ctx* mark_ctx, struct fix_arr_0 value) {
	return mark_arr_422(mark_ctx, value.inner);
}
/* mark-arr<nat-64> (generated) (generated) */
struct void_ mark_arr_422(struct mark_ctx* mark_ctx, struct arr_3 a) {
	uint8_t dropped0;
	dropped0 = mark(mark_ctx, ((uint8_t*) a.begin_ptr), (a.size * sizeof(uint64_t)));
	
	return (struct void_) {};
}
/* clear-free-mem! void(mark-ptr mut-ptr<bool>, mark-end mut-ptr<bool>, data-ptr mut-ptr<nat64>) */
struct void_ clear_free_mem__e(uint8_t* mark_ptr, uint8_t* mark_end, uint64_t* data_ptr) {
	top:;
	uint8_t _0 = _notEqual_7(mark_ptr, mark_end);
	if (_0) {
		uint8_t _1 = _not((*mark_ptr));
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
/* !=<mut-ptr<bool>> bool(a mut-ptr<bool>, b mut-ptr<bool>) */
uint8_t _notEqual_7(uint8_t* a, uint8_t* b) {
	return _not((a == b));
}
/* wait-on void(a condition, until-time opt<nat64>, last-sequence nat64) */
struct void_ wait_on(struct condition* a, struct opt_11 until_time, uint64_t last_sequence) {
	int32_t _0 = pthread_mutex_lock((&a->mutex));
	hard_assert_posix_error(_0);
	uint8_t _1 = (a->sequence == last_sequence);
	if (_1) {
		struct opt_11 _2 = until_time;int32_t _3;
		
		switch (_2.kind) {
			case 0: {
				_3 = pthread_cond_wait((&a->cond), (&a->mutex));
				break;
			}
			case 1: {
				uint64_t _matched0 = _2.as1;
				
				struct timespec abstime1;
				abstime1 = to_timespec(_matched0);
				
				int32_t err2;
				err2 = pthread_cond_timedwait((&a->cond), (&a->mutex), (&abstime1));
				
				int32_t _4 = ETIMEDOUT();
				uint8_t _5 = (err2 == _4);
				if (_5) {
					_3 = 0;
				} else {
					_3 = err2;
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
/* to-timespec timespec(a nat64) */
struct timespec to_timespec(uint64_t a) {
	int64_t seconds0;
	seconds0 = ((int64_t) (a / 1000000000u));
	
	int64_t ns1;
	ns1 = ((int64_t) (a % 1000000000u));
	
	return (struct timespec) {seconds0, ns1};
}
/* ETIMEDOUT int32() */
int32_t ETIMEDOUT(void) {
	return 110;
}
/* join-threads-recur void(i nat64, n-threads nat64, threads const-ptr<nat64>) */
struct void_ join_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads) {
	top:;
	uint8_t _0 = _notEqual_5(i, n_threads);
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
/* join-one-thread void(tid nat64) */
struct void_ join_one_thread(uint64_t tid) {
	struct cell_2 thread_return0;
	thread_return0 = (struct cell_2) {NULL};
	
	int32_t err1;
	err1 = pthread_join(tid, (&thread_return0));
	
	uint8_t _0 = _notEqual_6(err1, 0);
	if (_0) {
		int32_t _1 = EINVAL();
		uint8_t _2 = (err1 == _1);
		if (_2) {
			todo_0();
		} else {
			int32_t _3 = ESRCH();
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
	uint8_t* _5 = _times_9((&thread_return0));
	return hard_assert((_5 == NULL));
}
/* EINVAL int32() */
int32_t EINVAL(void) {
	return 22;
}
/* ESRCH int32() */
int32_t ESRCH(void) {
	return 3;
}
/* *<mut-ptr<nat8>> mut-ptr<nat8>(a cell<mut-ptr<nat8>>) */
uint8_t* _times_9(struct cell_2* a) {
	return a->inner_value;
}
/* unmanaged-free<nat64> void(p mut-ptr<nat64>) */
struct void_ unmanaged_free_0(uint64_t* p) {
	return (free(((uint8_t*) p)), (struct void_) {});
}
/* unmanaged-free<by-val<thread-args>> void(p mut-ptr<thread-args>) */
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
/* main fut<nat64>(_ arr<str>) */
struct fut_0* main_0(struct ctx* ctx, struct arr_2 _p0) {
	log(ctx, 0u, (struct str) {{11, constantarr_0_10}});
	struct fun1_1 lh0;
	lh0 = get_log_handler(ctx);
	
	struct fun1_1 doubler1;
	struct main_0__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct main_0__lambda0));
	temp0 = ((struct main_0__lambda0*) _0);
	
	*temp0 = (struct main_0__lambda0) {lh0};
	doubler1 = (struct fun1_1) {1, .as1 = temp0};
	
	with_log_handler(ctx, doubler1, (struct fun_act0_0) {7, .as7 = (struct void_) {}});
	with_log_handler(ctx, (struct fun1_1) {2, .as2 = (struct void_) {}}, (struct fun_act0_0) {8, .as8 = (struct void_) {}});
	return resolved_1(ctx, 0u);
}
/* log void(level log-level, message str) */
struct void_ log(struct ctx* ctx, uint32_t level, struct str message) {
	struct fun1_1 _0 = get_log_handler(ctx);
	struct logged* temp0;
	uint8_t* _1 = alloc(ctx, sizeof(struct logged));
	temp0 = ((struct logged*) _1);
	
	*temp0 = (struct logged) {level, message};
	return subscript_25(ctx, _0, temp0);
}
/* subscript<void, logged> void(a fun1<void, logged>, p0 logged) */
struct void_ subscript_25(struct ctx* ctx, struct fun1_1 a, struct logged* p0) {
	return call_w_ctx_447(a, ctx, p0);
}
/* call-w-ctx<void, gc-ptr(logged)> (generated) (generated) */
struct void_ call_w_ctx_447(struct fun1_1 a, struct ctx* ctx, struct logged* p0) {
	struct fun1_1 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return island__lambda1(ctx, closure0, p0);
		}
		case 1: {
			struct main_0__lambda0* closure1 = _0.as1;
			
			return main_0__lambda0(ctx, closure1, p0);
		}
		case 2: {
			struct void_ closure2 = _0.as2;
			
			return main_0__lambda2(ctx, closure2, p0);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* get-log-handler fun1<void, logged>() */
struct fun1_1 get_log_handler(struct ctx* ctx) {
	struct log_ctx* _0 = get_log_ctx(ctx);
	return _0->handler;
}
/* get-log-ctx log-ctx() */
struct log_ctx* get_log_ctx(struct ctx* ctx) {
	return ((struct log_ctx*) ctx->thread_local_stuff->log_ctx_ptr);
}
/* main.lambda0 void(logged logged) */
struct void_ main_0__lambda0(struct ctx* ctx, struct main_0__lambda0* _closure, struct logged* logged) {
	subscript_25(ctx, _closure->lh, logged);
	return subscript_25(ctx, _closure->lh, logged);
}
/* with-log-handler<void> void(handler fun1<void, logged>, cb fun-act0<void>) */
struct void_ with_log_handler(struct ctx* ctx, struct fun1_1 handler, struct fun_act0_0 cb) {
	struct fun1_1 original_handler0;
	original_handler0 = get_log_handler(ctx);
	
	struct fun_act0_0 action1;
	struct with_log_handler__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct with_log_handler__lambda0));
	temp0 = ((struct with_log_handler__lambda0*) _0);
	
	*temp0 = (struct with_log_handler__lambda0) {handler, cb, original_handler0};
	action1 = (struct fun_act0_0) {6, .as6 = temp0};
	
	struct with_log_handler__lambda1* temp1;
	uint8_t* _1 = alloc(ctx, sizeof(struct with_log_handler__lambda1));
	temp1 = ((struct with_log_handler__lambda1*) _1);
	
	*temp1 = (struct with_log_handler__lambda1) {original_handler0};
	return catch(ctx, action1, (struct fun_act1_5) {2, .as2 = temp1});
}
/* set-log-handler void(handler fun1<void, logged>) */
struct void_ set_log_handler(struct ctx* ctx, struct fun1_1 handler) {
	struct log_ctx* _0 = get_log_ctx(ctx);
	return (_0->handler = handler, (struct void_) {});
}
/* with-log-handler<void>.lambda0 void() */
struct void_ with_log_handler__lambda0(struct ctx* ctx, struct with_log_handler__lambda0* _closure) {
	set_log_handler(ctx, _closure->handler);
	struct void_ res0;
	res0 = subscript_6(ctx, _closure->cb);
	
	set_log_handler(ctx, _closure->original_handler);
	return res0;
}
/* with-log-handler<void>.lambda1 void(err exception) */
struct void_ with_log_handler__lambda1(struct ctx* ctx, struct with_log_handler__lambda1* _closure, struct exception err) {
	set_log_handler(ctx, _closure->original_handler);
	return throw_1(ctx, err);
}
/* main.lambda1 void() */
struct void_ main_0__lambda1(struct ctx* ctx, struct void_ _closure) {
	return log(ctx, 1u, (struct str) {{12, constantarr_0_11}});
}
/* main.lambda2 void(ignore logged) */
struct void_ main_0__lambda2(struct ctx* ctx, struct void_ _closure, struct logged* ignore) {
	return (struct void_) {};
}
/* main.lambda3 void() */
struct void_ main_0__lambda3(struct ctx* ctx, struct void_ _closure) {
	return log(ctx, 1u, (struct str) {{12, constantarr_0_12}});
}
/* resolved<nat64> fut<nat64>(value nat64) */
struct fut_0* resolved_1(struct ctx* ctx, uint64_t value) {
	struct fut_0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct fut_0));
	temp0 = ((struct fut_0*) _0);
	
	struct lock _1 = lock_by_val();
	*temp0 = (struct fut_0) {_1, (struct fut_state_0) {2, .as2 = value}};
	return temp0;
}
/* main (generated) (generated) */
int32_t main(int32_t argc, char** argv) {
	return rt_main(argc, argv, main_0);
}
