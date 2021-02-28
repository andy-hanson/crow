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
struct fut_state_no_callbacks {
};
struct fut_state_callbacks_0;
struct exception;
struct arr_0 {
	uint64_t size;
	char* begin_ptr;
};
struct backtrace;
struct arr_1 {
	uint64_t size;
	struct arr_0* begin_ptr;
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
struct thread_safe_counter;
struct arr_3 {
	uint64_t size;
	struct island** begin_ptr;
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
struct backtrace_arrs {
	uint8_t** code_ptrs;
	struct arr_0* code_names;
	uint8_t** fun_ptrs;
	struct arr_0* fun_names;
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
	struct arr_0* value;
};
struct arrow {
	uint64_t from;
	uint64_t to;
};
struct interp;
struct mut_list_1;
struct mut_arr_1 {
	struct void_ ignore;
	struct arr_0 inner;
};
struct _concatEquals_0__lambda0 {
	struct mut_list_1* a;
};
struct log_ctx;
struct thread_local_stuff {
	struct exception_ctx* exception_ctx;
	struct log_ctx* log_ctx;
};
struct arr_4 {
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
struct subscript_11__lambda0;
struct subscript_11__lambda0__lambda0;
struct subscript_11__lambda0__lambda1 {
	struct fut_0* res;
};
struct then_void__lambda0;
struct subscript_16__lambda0;
struct subscript_16__lambda0__lambda0;
struct subscript_16__lambda0__lambda1 {
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
		struct subscript_11__lambda0__lambda0* as2;
		struct subscript_11__lambda0* as3;
		struct subscript_16__lambda0__lambda0* as4;
		struct subscript_16__lambda0* as5;
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
	};
};
struct fun1_1 {
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
struct fun_act1_1 {
	uint64_t kind;
	union {
		struct _concatEquals_0__lambda0* as0;
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
struct fun_act1_2 {
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
struct fun_act1_3 {
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
struct fun_act1_4 {
	uint64_t kind;
	union {
		struct subscript_11__lambda0__lambda1* as0;
		struct subscript_16__lambda0__lambda1* as1;
	};
};
struct fun_act1_5 {
	uint64_t kind;
	union {
		struct void_ as0;
	};
};
struct fun_act1_6 {
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
struct fut_0;
struct lock {
	struct _atomic_bool is_locked;
};
struct fut_state_callbacks_0 {
	struct fun_act1_0 cb;
	struct opt_0 next;
};
struct exception;
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
struct exception_ctx;
struct jmp_buf_tag;
struct bytes64;
struct bytes32 {
	struct bytes16 n0;
	struct bytes16 n1;
};
struct bytes128;
struct interp {
	struct mut_list_1* inner;
};
struct mut_list_1 {
	struct mut_arr_1 backing;
	uint64_t size;
};
struct log_ctx {
	struct fun1_1 handler;
};
struct fut_1;
struct fut_state_callbacks_1 {
	struct fun_act1_2 cb;
	struct opt_7 next;
};
struct fun_ref0 {
	struct island_and_exclusion island_and_exclusion;
	struct fun_act0_1 fun;
};
struct fun_ref1 {
	struct island_and_exclusion island_and_exclusion;
	struct fun_act1_3 fun;
};
struct callback__e_0__lambda0 {
	struct fut_1* f;
	struct fun_act1_2 cb;
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
struct subscript_11__lambda0 {
	struct fun_ref1 f;
	struct void_ p0;
	struct fut_0* res;
};
struct subscript_11__lambda0__lambda0 {
	struct fun_ref1 f;
	struct void_ p0;
	struct fut_0* res;
};
struct then_void__lambda0 {
	struct fun_ref0 cb;
};
struct subscript_16__lambda0 {
	struct fun_ref0 f;
	struct fut_0* res;
};
struct subscript_16__lambda0__lambda0 {
	struct fun_ref0 f;
	struct fut_0* res;
};
struct add_first_task__lambda0 {
	struct arr_4 all_args;
	fun_ptr2 main_ptr;
};
struct map__lambda0 {
	struct fun_act1_5 f;
	struct arr_4 a;
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
	struct arr_0 message;
	struct backtrace backtrace;
};
struct err {
	struct exception value;
};
struct global_ctx {
	struct lock lk;
	struct arr_3 islands;
	uint64_t n_live_threads;
	struct condition may_be_work_to_do;
	uint8_t shut_down__q;
	uint8_t any_unhandled_exceptions__q;
};
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
struct exception_ctx {
	struct jmp_buf_tag* jmp_buf_ptr;
	struct exception thrown_exception;
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
struct island;
struct island_gc_root;
struct task_queue {
	struct opt_2 head;
	struct mut_list_0 currently_running_exclusions;
};
struct jmp_buf_tag {
	struct bytes64 jmp_buf;
	int32_t mask_was_saved;
	struct bytes128 saved_mask;
};
struct fut_1 {
	struct lock lk;
	struct fut_state_1 state;
};
struct resolve_or_reject__e__lambda0 {
	struct fut_0* f;
	struct result_0 result;
};
struct island;
struct island_gc_root {
	struct task_queue tasks;
	struct fun1_0 exception_handler;
	struct fun1_1 log_handler;
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

_Static_assert(sizeof(struct ctx) == 48, "");
_Static_assert(sizeof(struct mark_ctx) == 24, "");
_Static_assert(sizeof(struct less) == 0, "");
_Static_assert(sizeof(struct equal) == 0, "");
_Static_assert(sizeof(struct greater) == 0, "");
_Static_assert(sizeof(struct fut_0) == 48, "");
_Static_assert(sizeof(struct lock) == 1, "");
_Static_assert(sizeof(struct _atomic_bool) == 1, "");
_Static_assert(sizeof(struct fut_state_no_callbacks) == 0, "");
_Static_assert(sizeof(struct fut_state_callbacks_0) == 32, "");
_Static_assert(sizeof(struct exception) == 32, "");
_Static_assert(sizeof(struct arr_0) == 16, "");
_Static_assert(sizeof(struct backtrace) == 16, "");
_Static_assert(sizeof(struct arr_1) == 16, "");
_Static_assert(sizeof(struct ok_0) == 8, "");
_Static_assert(sizeof(struct err) == 32, "");
_Static_assert(sizeof(struct none) == 0, "");
_Static_assert(sizeof(struct some_0) == 8, "");
_Static_assert(sizeof(struct fut_state_resolved_0) == 8, "");
_Static_assert(sizeof(struct global_ctx) == 56, "");
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
_Static_assert(sizeof(struct thread_safe_counter) == 16, "");
_Static_assert(sizeof(struct arr_3) == 16, "");
_Static_assert(sizeof(struct condition) == 16, "");
_Static_assert(sizeof(struct exception_ctx) == 40, "");
_Static_assert(sizeof(struct jmp_buf_tag) == 200, "");
_Static_assert(sizeof(struct bytes64) == 64, "");
_Static_assert(sizeof(struct bytes32) == 32, "");
_Static_assert(sizeof(struct bytes16) == 16, "");
_Static_assert(sizeof(struct bytes128) == 128, "");
_Static_assert(sizeof(struct backtrace_arrs) == 32, "");
_Static_assert(sizeof(struct some_3) == 8, "");
_Static_assert(sizeof(struct some_4) == 8, "");
_Static_assert(sizeof(struct some_5) == 8, "");
_Static_assert(sizeof(struct some_6) == 8, "");
_Static_assert(sizeof(struct arrow) == 16, "");
_Static_assert(sizeof(struct interp) == 8, "");
_Static_assert(sizeof(struct mut_list_1) == 24, "");
_Static_assert(sizeof(struct mut_arr_1) == 16, "");
_Static_assert(sizeof(struct _concatEquals_0__lambda0) == 8, "");
_Static_assert(sizeof(struct log_ctx) == 8, "");
_Static_assert(sizeof(struct thread_local_stuff) == 16, "");
_Static_assert(sizeof(struct arr_4) == 16, "");
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
_Static_assert(sizeof(struct subscript_11__lambda0) == 40, "");
_Static_assert(sizeof(struct subscript_11__lambda0__lambda0) == 40, "");
_Static_assert(sizeof(struct subscript_11__lambda0__lambda1) == 8, "");
_Static_assert(sizeof(struct then_void__lambda0) == 32, "");
_Static_assert(sizeof(struct subscript_16__lambda0) == 40, "");
_Static_assert(sizeof(struct subscript_16__lambda0__lambda0) == 40, "");
_Static_assert(sizeof(struct subscript_16__lambda0__lambda1) == 8, "");
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
_Static_assert(sizeof(struct opt_3) == 16, "");
_Static_assert(sizeof(struct opt_4) == 16, "");
_Static_assert(sizeof(struct opt_5) == 16, "");
_Static_assert(sizeof(struct opt_6) == 16, "");
_Static_assert(sizeof(struct fun_act1_1) == 16, "");
_Static_assert(sizeof(struct fun_act2) == 8, "");
_Static_assert(sizeof(struct fut_state_1) == 40, "");
_Static_assert(sizeof(struct result_1) == 40, "");
_Static_assert(sizeof(struct fun_act1_2) == 16, "");
_Static_assert(sizeof(struct opt_7) == 16, "");
_Static_assert(sizeof(struct fun_act0_1) == 16, "");
_Static_assert(sizeof(struct fun_act1_3) == 16, "");
_Static_assert(sizeof(struct fun_act0_2) == 16, "");
_Static_assert(sizeof(struct fun_act1_4) == 16, "");
_Static_assert(sizeof(struct fun_act1_5) == 8, "");
_Static_assert(sizeof(struct fun_act1_6) == 16, "");
_Static_assert(sizeof(struct opt_8) == 16, "");
_Static_assert(sizeof(struct choose_task_result) == 56, "");
_Static_assert(sizeof(struct task_or_gc) == 40, "");
_Static_assert(sizeof(struct opt_9) == 16, "");
_Static_assert(sizeof(struct choose_task_in_island_result) == 40, "");
_Static_assert(sizeof(struct pop_task_result) == 40, "");
char constantarr_0_0[20];
char constantarr_0_1[1];
char constantarr_0_2[17];
char constantarr_0_3[11];
char constantarr_0_4[13];
char constantarr_0_5[13];
char constantarr_0_6[5];
char constantarr_0_7[4];
char constantarr_0_8[4];
char constantarr_0_9[2];
char constantarr_0_10[13];
char constantarr_0_11[4];
char constantarr_0_12[11];
char constantarr_0_13[4];
char constantarr_0_14[6];
char constantarr_0_15[13];
char constantarr_0_16[7];
char constantarr_0_17[7];
char constantarr_0_18[5];
char constantarr_0_19[4];
char constantarr_0_20[8];
char constantarr_0_21[12];
char constantarr_0_22[14];
char constantarr_0_23[10];
char constantarr_0_24[25];
char constantarr_0_25[8];
char constantarr_0_26[8];
char constantarr_0_27[19];
char constantarr_0_28[6];
char constantarr_0_29[8];
char constantarr_0_30[10];
char constantarr_0_31[11];
char constantarr_0_32[12];
char constantarr_0_33[6];
char constantarr_0_34[17];
char constantarr_0_35[7];
char constantarr_0_36[3];
char constantarr_0_37[7];
char constantarr_0_38[5];
char constantarr_0_39[16];
char constantarr_0_40[13];
char constantarr_0_41[2];
char constantarr_0_42[15];
char constantarr_0_43[19];
char constantarr_0_44[6];
char constantarr_0_45[7];
char constantarr_0_46[10];
char constantarr_0_47[22];
char constantarr_0_48[10];
char constantarr_0_49[11];
char constantarr_0_50[4];
char constantarr_0_51[11];
char constantarr_0_52[9];
char constantarr_0_53[22];
char constantarr_0_54[6];
char constantarr_0_55[10];
char constantarr_0_56[4];
char constantarr_0_57[56];
char constantarr_0_58[11];
char constantarr_0_59[7];
char constantarr_0_60[35];
char constantarr_0_61[28];
char constantarr_0_62[21];
char constantarr_0_63[6];
char constantarr_0_64[11];
char constantarr_0_65[11];
char constantarr_0_66[8];
char constantarr_0_67[8];
char constantarr_0_68[18];
char constantarr_0_69[6];
char constantarr_0_70[19];
char constantarr_0_71[12];
char constantarr_0_72[26];
char constantarr_0_73[14];
char constantarr_0_74[25];
char constantarr_0_75[20];
char constantarr_0_76[16];
char constantarr_0_77[13];
char constantarr_0_78[13];
char constantarr_0_79[5];
char constantarr_0_80[21];
char constantarr_0_81[15];
char constantarr_0_82[10];
char constantarr_0_83[7];
char constantarr_0_84[6];
char constantarr_0_85[13];
char constantarr_0_86[10];
char constantarr_0_87[10];
char constantarr_0_88[6];
char constantarr_0_89[9];
char constantarr_0_90[14];
char constantarr_0_91[12];
char constantarr_0_92[12];
char constantarr_0_93[7];
char constantarr_0_94[13];
char constantarr_0_95[15];
char constantarr_0_96[8];
char constantarr_0_97[18];
char constantarr_0_98[6];
char constantarr_0_99[10];
char constantarr_0_100[9];
char constantarr_0_101[17];
char constantarr_0_102[21];
char constantarr_0_103[17];
char constantarr_0_104[7];
char constantarr_0_105[18];
char constantarr_0_106[11];
char constantarr_0_107[20];
char constantarr_0_108[7];
char constantarr_0_109[15];
char constantarr_0_110[20];
char constantarr_0_111[9];
char constantarr_0_112[13];
char constantarr_0_113[24];
char constantarr_0_114[34];
char constantarr_0_115[9];
char constantarr_0_116[12];
char constantarr_0_117[8];
char constantarr_0_118[14];
char constantarr_0_119[12];
char constantarr_0_120[8];
char constantarr_0_121[11];
char constantarr_0_122[23];
char constantarr_0_123[12];
char constantarr_0_124[5];
char constantarr_0_125[23];
char constantarr_0_126[9];
char constantarr_0_127[12];
char constantarr_0_128[13];
char constantarr_0_129[9];
char constantarr_0_130[10];
char constantarr_0_131[16];
char constantarr_0_132[2];
char constantarr_0_133[18];
char constantarr_0_134[11];
char constantarr_0_135[21];
char constantarr_0_136[10];
char constantarr_0_137[10];
char constantarr_0_138[8];
char constantarr_0_139[18];
char constantarr_0_140[13];
char constantarr_0_141[8];
char constantarr_0_142[8];
char constantarr_0_143[17];
char constantarr_0_144[11];
char constantarr_0_145[8];
char constantarr_0_146[7];
char constantarr_0_147[10];
char constantarr_0_148[6];
char constantarr_0_149[11];
char constantarr_0_150[12];
char constantarr_0_151[12];
char constantarr_0_152[15];
char constantarr_0_153[19];
char constantarr_0_154[8];
char constantarr_0_155[11];
char constantarr_0_156[10];
char constantarr_0_157[6];
char constantarr_0_158[2];
char constantarr_0_159[10];
char constantarr_0_160[14];
char constantarr_0_161[10];
char constantarr_0_162[13];
char constantarr_0_163[18];
char constantarr_0_164[16];
char constantarr_0_165[34];
char constantarr_0_166[10];
char constantarr_0_167[20];
char constantarr_0_168[14];
char constantarr_0_169[21];
char constantarr_0_170[21];
char constantarr_0_171[9];
char constantarr_0_172[18];
char constantarr_0_173[21];
char constantarr_0_174[13];
char constantarr_0_175[6];
char constantarr_0_176[9];
char constantarr_0_177[15];
char constantarr_0_178[14];
char constantarr_0_179[25];
char constantarr_0_180[7];
char constantarr_0_181[24];
char constantarr_0_182[17];
char constantarr_0_183[5];
char constantarr_0_184[11];
char constantarr_0_185[24];
char constantarr_0_186[12];
char constantarr_0_187[8];
char constantarr_0_188[9];
char constantarr_0_189[13];
char constantarr_0_190[15];
char constantarr_0_191[13];
char constantarr_0_192[15];
char constantarr_0_193[24];
char constantarr_0_194[15];
char constantarr_0_195[10];
char constantarr_0_196[10];
char constantarr_0_197[21];
char constantarr_0_198[20];
char constantarr_0_199[14];
char constantarr_0_200[12];
char constantarr_0_201[13];
char constantarr_0_202[5];
char constantarr_0_203[1];
char constantarr_0_204[3];
char constantarr_0_205[7];
char constantarr_0_206[23];
char constantarr_0_207[5];
char constantarr_0_208[8];
char constantarr_0_209[15];
char constantarr_0_210[18];
char constantarr_0_211[6];
char constantarr_0_212[13];
char constantarr_0_213[6];
char constantarr_0_214[14];
char constantarr_0_215[12];
char constantarr_0_216[1];
char constantarr_0_217[12];
char constantarr_0_218[13];
char constantarr_0_219[12];
char constantarr_0_220[6];
char constantarr_0_221[18];
char constantarr_0_222[9];
char constantarr_0_223[11];
char constantarr_0_224[15];
char constantarr_0_225[12];
char constantarr_0_226[5];
char constantarr_0_227[6];
char constantarr_0_228[21];
char constantarr_0_229[8];
char constantarr_0_230[8];
char constantarr_0_231[8];
char constantarr_0_232[14];
char constantarr_0_233[19];
char constantarr_0_234[22];
char constantarr_0_235[11];
char constantarr_0_236[6];
char constantarr_0_237[18];
char constantarr_0_238[19];
char constantarr_0_239[12];
char constantarr_0_240[25];
char constantarr_0_241[25];
char constantarr_0_242[21];
char constantarr_0_243[24];
char constantarr_0_244[30];
char constantarr_0_245[1];
char constantarr_0_246[1];
char constantarr_0_247[16];
char constantarr_0_248[6];
char constantarr_0_249[14];
char constantarr_0_250[29];
char constantarr_0_251[14];
char constantarr_0_252[18];
char constantarr_0_253[8];
char constantarr_0_254[14];
char constantarr_0_255[19];
char constantarr_0_256[5];
char constantarr_0_257[16];
char constantarr_0_258[6];
char constantarr_0_259[21];
char constantarr_0_260[5];
char constantarr_0_261[14];
char constantarr_0_262[20];
char constantarr_0_263[14];
char constantarr_0_264[14];
char constantarr_0_265[19];
char constantarr_0_266[18];
char constantarr_0_267[11];
char constantarr_0_268[11];
char constantarr_0_269[14];
char constantarr_0_270[7];
char constantarr_0_271[13];
char constantarr_0_272[7];
char constantarr_0_273[26];
char constantarr_0_274[30];
char constantarr_0_275[18];
char constantarr_0_276[25];
char constantarr_0_277[19];
char constantarr_0_278[3];
char constantarr_0_279[18];
char constantarr_0_280[12];
char constantarr_0_281[23];
char constantarr_0_282[6];
char constantarr_0_283[12];
char constantarr_0_284[13];
char constantarr_0_285[16];
char constantarr_0_286[8];
char constantarr_0_287[11];
char constantarr_0_288[11];
char constantarr_0_289[26];
char constantarr_0_290[7];
char constantarr_0_291[22];
char constantarr_0_292[2];
char constantarr_0_293[25];
char constantarr_0_294[19];
char constantarr_0_295[30];
char constantarr_0_296[15];
char constantarr_0_297[79];
char constantarr_0_298[14];
char constantarr_0_299[14];
char constantarr_0_300[16];
char constantarr_0_301[16];
char constantarr_0_302[7];
char constantarr_0_303[22];
char constantarr_0_304[14];
char constantarr_0_305[15];
char constantarr_0_306[17];
char constantarr_0_307[6];
char constantarr_0_308[9];
char constantarr_0_309[13];
char constantarr_0_310[23];
char constantarr_0_311[29];
char constantarr_0_312[38];
char constantarr_0_313[6];
char constantarr_0_314[9];
char constantarr_0_315[14];
char constantarr_0_316[22];
char constantarr_0_317[17];
char constantarr_0_318[13];
char constantarr_0_319[21];
char constantarr_0_320[22];
char constantarr_0_321[24];
char constantarr_0_322[22];
char constantarr_0_323[16];
char constantarr_0_324[30];
char constantarr_0_325[19];
char constantarr_0_326[6];
char constantarr_0_327[8];
char constantarr_0_328[30];
char constantarr_0_329[25];
char constantarr_0_330[20];
char constantarr_0_331[10];
char constantarr_0_332[17];
char constantarr_0_333[7];
char constantarr_0_334[29];
char constantarr_0_335[8];
char constantarr_0_336[15];
char constantarr_0_337[4];
char constantarr_0_338[10];
char constantarr_0_339[12];
char constantarr_0_340[4];
char constantarr_0_341[10];
char constantarr_0_342[4];
char constantarr_0_343[22];
char constantarr_0_344[4];
char constantarr_0_345[8];
char constantarr_0_346[21];
char constantarr_0_347[4];
char constantarr_0_348[12];
char constantarr_0_349[8];
char constantarr_0_350[5];
char constantarr_0_351[22];
char constantarr_0_352[10];
char constantarr_0_353[9];
char constantarr_0_354[21];
char constantarr_0_355[17];
char constantarr_0_356[4];
char constantarr_0_357[12];
char constantarr_0_358[9];
char constantarr_0_359[11];
char constantarr_0_360[28];
char constantarr_0_361[16];
char constantarr_0_362[11];
char constantarr_0_363[4];
char constantarr_0_364[7];
char constantarr_0_365[7];
char constantarr_0_366[7];
char constantarr_0_367[8];
char constantarr_0_368[15];
char constantarr_0_369[19];
char constantarr_0_370[6];
char constantarr_0_371[24];
char constantarr_0_372[23];
char constantarr_0_373[12];
char constantarr_0_374[36];
char constantarr_0_375[11];
char constantarr_0_376[36];
char constantarr_0_377[28];
char constantarr_0_378[10];
char constantarr_0_379[24];
char constantarr_0_380[15];
char constantarr_0_381[24];
char constantarr_0_382[18];
char constantarr_0_383[7];
char constantarr_0_384[31];
char constantarr_0_385[31];
char constantarr_0_386[23];
char constantarr_0_387[22];
char constantarr_0_388[24];
char constantarr_0_389[20];
char constantarr_0_390[9];
char constantarr_0_391[5];
char constantarr_0_392[14];
char constantarr_0_393[15];
char constantarr_0_394[10];
char constantarr_0_395[40];
char constantarr_0_396[25];
char constantarr_0_397[14];
char constantarr_0_398[18];
char constantarr_0_399[24];
char constantarr_0_400[18];
char constantarr_0_401[14];
char constantarr_0_402[33];
char constantarr_0_403[24];
char constantarr_0_404[16];
char constantarr_0_405[5];
char constantarr_0_406[13];
char constantarr_0_407[17];
char constantarr_0_408[8];
char constantarr_0_409[15];
char constantarr_0_410[27];
char constantarr_0_411[16];
char constantarr_0_412[30];
char constantarr_0_413[22];
char constantarr_0_414[22];
char constantarr_0_415[26];
char constantarr_0_416[17];
char constantarr_0_417[14];
char constantarr_0_418[30];
char constantarr_0_419[15];
char constantarr_0_420[80];
char constantarr_0_421[11];
char constantarr_0_422[45];
char constantarr_0_423[19];
char constantarr_0_424[22];
char constantarr_0_425[34];
char constantarr_0_426[11];
char constantarr_0_427[17];
char constantarr_0_428[14];
char constantarr_0_429[9];
char constantarr_0_430[6];
char constantarr_0_431[12];
char constantarr_0_432[16];
char constantarr_0_433[36];
char constantarr_0_434[10];
char constantarr_0_435[19];
char constantarr_0_436[15];
char constantarr_0_437[21];
char constantarr_0_438[10];
char constantarr_0_439[18];
char constantarr_0_440[14];
char constantarr_0_441[28];
char constantarr_0_442[9];
char constantarr_0_443[17];
char constantarr_0_444[6];
char constantarr_0_445[16];
char constantarr_0_446[11];
char constantarr_0_447[17];
char constantarr_0_448[26];
char constantarr_0_449[14];
char constantarr_0_450[8];
char constantarr_0_451[13];
char constantarr_0_452[15];
char constantarr_0_453[26];
char constantarr_0_454[19];
char constantarr_0_455[6];
char constantarr_0_456[7];
char constantarr_0_457[9];
char constantarr_0_458[22];
char constantarr_0_459[17];
char constantarr_0_460[14];
char constantarr_0_461[21];
char constantarr_0_462[32];
char constantarr_0_463[7];
char constantarr_0_464[7];
char constantarr_0_465[9];
char constantarr_0_466[25];
char constantarr_0_467[28];
char constantarr_0_468[19];
char constantarr_0_469[14];
char constantarr_0_470[13];
char constantarr_0_471[19];
char constantarr_0_472[15];
char constantarr_0_473[19];
char constantarr_0_474[10];
char constantarr_0_475[11];
char constantarr_0_476[9];
char constantarr_0_477[38];
char constantarr_0_478[11];
char constantarr_0_479[21];
char constantarr_0_480[11];
char constantarr_0_481[10];
char constantarr_0_482[8];
char constantarr_0_483[8];
char constantarr_0_484[5];
char constantarr_0_485[10];
char constantarr_0_486[15];
char constantarr_0_487[29];
char constantarr_0_488[7];
char constantarr_0_489[11];
char constantarr_0_490[10];
char constantarr_0_491[6];
char constantarr_0_492[12];
char constantarr_0_493[33];
char constantarr_0_494[38];
char constantarr_0_495[8];
char constantarr_0_496[30];
char constantarr_0_497[10];
char constantarr_0_498[13];
char constantarr_0_499[12];
char constantarr_0_500[46];
char constantarr_0_501[13];
char constantarr_0_502[12];
char constantarr_0_503[8];
char constantarr_0_504[20];
char constantarr_0_505[8];
char constantarr_0_506[14];
char constantarr_0_507[20];
char constantarr_0_508[14];
char constantarr_0_509[14];
char constantarr_0_510[7];
char constantarr_0_511[12];
char constantarr_0_512[9];
char constantarr_0_513[18];
char constantarr_0_514[15];
char constantarr_0_515[27];
char constantarr_0_516[15];
char constantarr_0_517[12];
char constantarr_0_518[27];
char constantarr_0_519[6];
char constantarr_0_520[5];
char constantarr_0_521[20];
char constantarr_0_522[19];
char constantarr_0_523[4];
char constantarr_0_524[35];
char constantarr_0_525[18];
char constantarr_0_526[8];
char constantarr_0_527[25];
char constantarr_0_528[4];
char constantarr_0_529[13];
char constantarr_0_0[20] = "uncaught exception: ";
char constantarr_0_1[1] = "\n";
char constantarr_0_2[17] = "<<empty message>>";
char constantarr_0_3[11] = "<<UNKNOWN>>";
char constantarr_0_4[13] = "assert failed";
char constantarr_0_5[13] = "forbid failed";
char constantarr_0_6[5] = "\n\tat ";
char constantarr_0_7[4] = "info";
char constantarr_0_8[4] = "warn";
char constantarr_0_9[2] = ": ";
char constantarr_0_10[13] = "Hello, world!";
char constantarr_0_11[4] = "mark";
char constantarr_0_12[11] = "hard-assert";
char constantarr_0_13[4] = "void";
char constantarr_0_14[6] = "abort!";
char constantarr_0_15[13] = "word-aligned?";
char constantarr_0_16[7] = "==<nat>";
char constantarr_0_17[7] = "<=><?a>";
char constantarr_0_18[5] = "false";
char constantarr_0_19[4] = "true";
char constantarr_0_20[8] = "bits-and";
char constantarr_0_21[12] = "to-nat<nat8>";
char constantarr_0_22[14] = "words-of-bytes";
char constantarr_0_23[10] = "unsafe-div";
char constantarr_0_24[25] = "round-up-to-multiple-of-8";
char constantarr_0_25[8] = "wrap-add";
char constantarr_0_26[8] = "bits-not";
char constantarr_0_27[19] = "ptr-cast<nat, nat8>";
char constantarr_0_28[6] = "-<nat>";
char constantarr_0_29[8] = "wrap-sub";
char constantarr_0_30[10] = "to-nat<?a>";
char constantarr_0_31[11] = "size-of<?a>";
char constantarr_0_32[12] = "memory-start";
char constantarr_0_33[6] = "<<nat>";
char constantarr_0_34[17] = "memory-size-words";
char constantarr_0_35[7] = "<=<nat>";
char constantarr_0_36[3] = "not";
char constantarr_0_37[7] = "+<bool>";
char constantarr_0_38[5] = "marks";
char constantarr_0_39[16] = "mark-range-recur";
char constantarr_0_40[13] = "ptr-eq?<bool>";
char constantarr_0_41[2] = "or";
char constantarr_0_42[15] = "subscript<bool>";
char constantarr_0_43[19] = "set-subscript<bool>";
char constantarr_0_44[6] = "><nat>";
char constantarr_0_45[7] = "rt-main";
char constantarr_0_46[10] = "get-nprocs";
char constantarr_0_47[22] = "as<by-val<global-ctx>>";
char constantarr_0_48[10] = "global-ctx";
char constantarr_0_49[11] = "lock-by-val";
char constantarr_0_50[4] = "lock";
char constantarr_0_51[11] = "atomic-bool";
char constantarr_0_52[9] = "condition";
char constantarr_0_53[22] = "ref-of-val<global-ctx>";
char constantarr_0_54[6] = "island";
char constantarr_0_55[10] = "task-queue";
char constantarr_0_56[4] = "none";
char constantarr_0_57[56] = "mut-list-by-val-with-capacity-from-unmanaged-memory<nat>";
char constantarr_0_58[11] = "mut-arr<?a>";
char constantarr_0_59[7] = "arr<?a>";
char constantarr_0_60[35] = "unmanaged-alloc-zeroed-elements<?a>";
char constantarr_0_61[28] = "unmanaged-alloc-elements<?a>";
char constantarr_0_62[21] = "unmanaged-alloc-bytes";
char constantarr_0_63[6] = "malloc";
char constantarr_0_64[11] = "hard-forbid";
char constantarr_0_65[11] = "null?<nat8>";
char constantarr_0_66[8] = "null<?a>";
char constantarr_0_67[8] = "wrap-mul";
char constantarr_0_68[18] = "set-zero-range<?a>";
char constantarr_0_69[6] = "memset";
char constantarr_0_70[19] = "as-any-ptr<ptr<?a>>";
char constantarr_0_71[12] = "mut-list<?a>";
char constantarr_0_72[26] = "as<by-val<island-gc-root>>";
char constantarr_0_73[14] = "island-gc-root";
char constantarr_0_74[25] = "default-exception-handler";
char constantarr_0_75[20] = "print-err-no-newline";
char constantarr_0_76[16] = "write-no-newline";
char constantarr_0_77[13] = "size-of<char>";
char constantarr_0_78[13] = "size-of<nat8>";
char constantarr_0_79[5] = "write";
char constantarr_0_80[21] = "as-any-ptr<ptr<char>>";
char constantarr_0_81[15] = "begin-ptr<char>";
char constantarr_0_82[10] = "size<char>";
char constantarr_0_83[7] = "!=<int>";
char constantarr_0_84[6] = "==<?a>";
char constantarr_0_85[13] = "unsafe-to-int";
char constantarr_0_86[10] = "todo<void>";
char constantarr_0_87[10] = "zeroed<?a>";
char constantarr_0_88[6] = "stderr";
char constantarr_0_89[9] = "print-err";
char constantarr_0_90[14] = "show-exception";
char constantarr_0_91[12] = "?<arr<char>>";
char constantarr_0_92[12] = "empty?<char>";
char constantarr_0_93[7] = "message";
char constantarr_0_94[13] = "flatten<char>";
char constantarr_0_95[15] = "empty?<arr<?a>>";
char constantarr_0_96[8] = "size<?a>";
char constantarr_0_97[18] = "subscript<arr<?a>>";
char constantarr_0_98[6] = "assert";
char constantarr_0_99[10] = "fail<void>";
char constantarr_0_100[9] = "throw<?a>";
char constantarr_0_101[17] = "get-exception-ctx";
char constantarr_0_102[21] = "as-ref<exception-ctx>";
char constantarr_0_103[17] = "exception-ctx-ptr";
char constantarr_0_104[7] = "get-ctx";
char constantarr_0_105[18] = "null?<jmp-buf-tag>";
char constantarr_0_106[11] = "jmp-buf-ptr";
char constantarr_0_107[20] = "set-thrown-exception";
char constantarr_0_108[7] = "longjmp";
char constantarr_0_109[15] = "number-to-throw";
char constantarr_0_110[20] = "hard-unreachable<?a>";
char constantarr_0_111[9] = "exception";
char constantarr_0_112[13] = "get-backtrace";
char constantarr_0_113[24] = "try-alloc-backtrace-arrs";
char constantarr_0_114[34] = "try-alloc-uninitialized<ptr<nat8>>";
char constantarr_0_115[9] = "try-alloc";
char constantarr_0_116[12] = "try-gc-alloc";
char constantarr_0_117[8] = "acquire!";
char constantarr_0_118[14] = "acquire-recur!";
char constantarr_0_119[12] = "try-acquire!";
char constantarr_0_120[8] = "try-set!";
char constantarr_0_121[11] = "try-change!";
char constantarr_0_122[23] = "compare-exchange-strong";
char constantarr_0_123[12] = "ptr-to<bool>";
char constantarr_0_124[5] = "value";
char constantarr_0_125[23] = "ref-of-val<atomic-bool>";
char constantarr_0_126[9] = "is-locked";
char constantarr_0_127[12] = "yield-thread";
char constantarr_0_128[13] = "pthread-yield";
char constantarr_0_129[9] = "==<int32>";
char constantarr_0_130[10] = "noctx-incr";
char constantarr_0_131[16] = "ref-of-val<lock>";
char constantarr_0_132[2] = "lk";
char constantarr_0_133[18] = "try-gc-alloc-recur";
char constantarr_0_134[11] = "validate-gc";
char constantarr_0_135[21] = "as-any-ptr<ptr<bool>>";
char constantarr_0_136[10] = "mark-begin";
char constantarr_0_137[10] = "data-begin";
char constantarr_0_138[8] = "data-cur";
char constantarr_0_139[18] = "ptr-less-eq?<bool>";
char constantarr_0_140[13] = "ptr-less?<?a>";
char constantarr_0_141[8] = "mark-cur";
char constantarr_0_142[8] = "mark-end";
char constantarr_0_143[17] = "ptr-less-eq?<nat>";
char constantarr_0_144[11] = "ptr-eq?<?a>";
char constantarr_0_145[8] = "data-end";
char constantarr_0_146[7] = "-<bool>";
char constantarr_0_147[10] = "size-words";
char constantarr_0_148[6] = "+<nat>";
char constantarr_0_149[11] = "range-free?";
char constantarr_0_150[12] = "set-mark-cur";
char constantarr_0_151[12] = "set-data-cur";
char constantarr_0_152[15] = "some<ptr<nat8>>";
char constantarr_0_153[19] = "ptr-cast<nat8, nat>";
char constantarr_0_154[8] = "release!";
char constantarr_0_155[11] = "must-unset!";
char constantarr_0_156[10] = "try-unset!";
char constantarr_0_157[6] = "get-gc";
char constantarr_0_158[2] = "gc";
char constantarr_0_159[10] = "get-gc-ctx";
char constantarr_0_160[14] = "as-ref<gc-ctx>";
char constantarr_0_161[10] = "gc-ctx-ptr";
char constantarr_0_162[13] = "some<ptr<?a>>";
char constantarr_0_163[18] = "ptr-cast<?a, nat8>";
char constantarr_0_164[16] = "value<ptr<nat8>>";
char constantarr_0_165[34] = "try-alloc-uninitialized<arr<char>>";
char constantarr_0_166[10] = "funs-count";
char constantarr_0_167[20] = "some<backtrace-arrs>";
char constantarr_0_168[14] = "backtrace-arrs";
char constantarr_0_169[21] = "value<ptr<ptr<nat8>>>";
char constantarr_0_170[21] = "value<ptr<arr<char>>>";
char constantarr_0_171[9] = "backtrace";
char constantarr_0_172[18] = "as<arr<arr<char>>>";
char constantarr_0_173[21] = "value<backtrace-arrs>";
char constantarr_0_174[13] = "unsafe-to-nat";
char constantarr_0_175[6] = "to-int";
char constantarr_0_176[9] = "code-ptrs";
char constantarr_0_177[15] = "unsafe-to-int32";
char constantarr_0_178[14] = "code-ptrs-size";
char constantarr_0_179[25] = "fill-fun-ptrs-names-recur";
char constantarr_0_180[7] = "!=<nat>";
char constantarr_0_181[24] = "set-subscript<ptr<nat8>>";
char constantarr_0_182[17] = "set-subscript<?a>";
char constantarr_0_183[5] = "+<?a>";
char constantarr_0_184[11] = "get-fun-ptr";
char constantarr_0_185[24] = "set-subscript<arr<char>>";
char constantarr_0_186[12] = "get-fun-name";
char constantarr_0_187[8] = "fun-ptrs";
char constantarr_0_188[9] = "fun-names";
char constantarr_0_189[13] = "sort-together";
char constantarr_0_190[15] = "swap<ptr<nat8>>";
char constantarr_0_191[13] = "subscript<?a>";
char constantarr_0_192[15] = "swap<arr<char>>";
char constantarr_0_193[24] = "partition-recur-together";
char constantarr_0_194[15] = "ptr-less?<nat8>";
char constantarr_0_195[10] = "noctx-decr";
char constantarr_0_196[10] = "code-names";
char constantarr_0_197[21] = "fill-code-names-recur";
char constantarr_0_198[20] = "ptr-less?<arr<char>>";
char constantarr_0_199[14] = "arr<arr<char>>";
char constantarr_0_200[12] = "noctx-at<?a>";
char constantarr_0_201[13] = "begin-ptr<?a>";
char constantarr_0_202[5] = "~<?a>";
char constantarr_0_203[1] = "+";
char constantarr_0_204[3] = "and";
char constantarr_0_205[7] = ">=<nat>";
char constantarr_0_206[23] = "alloc-uninitialized<?a>";
char constantarr_0_207[5] = "alloc";
char constantarr_0_208[8] = "gc-alloc";
char constantarr_0_209[15] = "todo<ptr<nat8>>";
char constantarr_0_210[18] = "copy-data-from<?a>";
char constantarr_0_211[6] = "memcpy";
char constantarr_0_212[13] = "tail<arr<?a>>";
char constantarr_0_213[6] = "forbid";
char constantarr_0_214[14] = "from<nat, nat>";
char constantarr_0_215[12] = "to<nat, nat>";
char constantarr_0_216[1] = "-";
char constantarr_0_217[12] = "-><nat, nat>";
char constantarr_0_218[13] = "arrow<?a, ?b>";
char constantarr_0_219[12] = "return-stack";
char constantarr_0_220[6] = "finish";
char constantarr_0_221[18] = "move-to-arr!<char>";
char constantarr_0_222[9] = "inner<?a>";
char constantarr_0_223[11] = "backing<?a>";
char constantarr_0_224[15] = "set-backing<?a>";
char constantarr_0_225[12] = "set-size<?a>";
char constantarr_0_226[5] = "inner";
char constantarr_0_227[6] = "to-str";
char constantarr_0_228[21] = "with-value<arr<char>>";
char constantarr_0_229[8] = "with-str";
char constantarr_0_230[8] = "~=<char>";
char constantarr_0_231[8] = "each<?a>";
char constantarr_0_232[14] = "each-recur<?a>";
char constantarr_0_233[19] = "subscript<void, ?a>";
char constantarr_0_234[22] = "call-with-ctx<?r, ?p0>";
char constantarr_0_235[11] = "end-ptr<?a>";
char constantarr_0_236[6] = "~=<?a>";
char constantarr_0_237[18] = "incr-capacity!<?a>";
char constantarr_0_238[19] = "ensure-capacity<?a>";
char constantarr_0_239[12] = "capacity<?a>";
char constantarr_0_240[25] = "increase-capacity-to!<?a>";
char constantarr_0_241[25] = "uninitialized-mut-arr<?a>";
char constantarr_0_242[21] = "set-zero-elements<?a>";
char constantarr_0_243[24] = "round-up-to-power-of-two";
char constantarr_0_244[30] = "round-up-to-power-of-two-recur";
char constantarr_0_245[1] = "*";
char constantarr_0_246[1] = "/";
char constantarr_0_247[16] = "~=<char>.lambda0";
char constantarr_0_248[6] = "interp";
char constantarr_0_249[14] = "mut-list<char>";
char constantarr_0_250[29] = "set-any-unhandled-exceptions?";
char constantarr_0_251[14] = "get-global-ctx";
char constantarr_0_252[18] = "as-ref<global-ctx>";
char constantarr_0_253[8] = "gctx-ptr";
char constantarr_0_254[14] = "island.lambda0";
char constantarr_0_255[19] = "default-log-handler";
char constantarr_0_256[5] = "print";
char constantarr_0_257[16] = "print-no-newline";
char constantarr_0_258[6] = "stdout";
char constantarr_0_259[21] = "with-value<log-level>";
char constantarr_0_260[5] = "level";
char constantarr_0_261[14] = "island.lambda1";
char constantarr_0_262[20] = "ptr-cast<bool, nat8>";
char constantarr_0_263[14] = "as<by-val<gc>>";
char constantarr_0_264[14] = "ref-of-val<gc>";
char constantarr_0_265[19] = "thread-safe-counter";
char constantarr_0_266[18] = "ref-of-val<island>";
char constantarr_0_267[11] = "set-islands";
char constantarr_0_268[11] = "arr<island>";
char constantarr_0_269[14] = "ptr-to<island>";
char constantarr_0_270[7] = "do-main";
char constantarr_0_271[13] = "exception-ctx";
char constantarr_0_272[7] = "log-ctx";
char constantarr_0_273[26] = "zeroed<fun1<void, logged>>";
char constantarr_0_274[30] = "as<by-val<thread-local-stuff>>";
char constantarr_0_275[18] = "thread-local-stuff";
char constantarr_0_276[25] = "ref-of-val<exception-ctx>";
char constantarr_0_277[19] = "ref-of-val<log-ctx>";
char constantarr_0_278[3] = "ctx";
char constantarr_0_279[18] = "as-any-ptr<gc-ctx>";
char constantarr_0_280[12] = "context-head";
char constantarr_0_281[23] = "size-of<by-val<gc-ctx>>";
char constantarr_0_282[6] = "set-gc";
char constantarr_0_283[12] = "set-next-ctx";
char constantarr_0_284[13] = "value<gc-ctx>";
char constantarr_0_285[16] = "set-context-head";
char constantarr_0_286[8] = "next-ctx";
char constantarr_0_287[11] = "set-handler";
char constantarr_0_288[11] = "log-handler";
char constantarr_0_289[26] = "ref-of-val<island-gc-root>";
char constantarr_0_290[7] = "gc-root";
char constantarr_0_291[22] = "as-any-ptr<global-ctx>";
char constantarr_0_292[2] = "id";
char constantarr_0_293[25] = "as-any-ptr<exception-ctx>";
char constantarr_0_294[19] = "as-any-ptr<log-ctx>";
char constantarr_0_295[30] = "ref-of-val<thread-local-stuff>";
char constantarr_0_296[15] = "ref-of-val<ctx>";
char constantarr_0_297[79] = "as<fun-act2<fut<nat>, arr<ptr<char>>, fun-ptr2<fut<nat>, ctx, arr<arr<char>>>>>";
char constantarr_0_298[14] = "add-first-task";
char constantarr_0_299[14] = "then-void<nat>";
char constantarr_0_300[16] = "then<?out, void>";
char constantarr_0_301[16] = "unresolved<?out>";
char constantarr_0_302[7] = "fut<?a>";
char constantarr_0_303[22] = "fut-state-no-callbacks";
char constantarr_0_304[14] = "callback!<?in>";
char constantarr_0_305[15] = "with-lock<void>";
char constantarr_0_306[17] = "call-with-ctx<?r>";
char constantarr_0_307[6] = "lk<?a>";
char constantarr_0_308[9] = "state<?a>";
char constantarr_0_309[13] = "set-state<?a>";
char constantarr_0_310[23] = "fut-state-callbacks<?a>";
char constantarr_0_311[29] = "some<fut-state-callbacks<?a>>";
char constantarr_0_312[38] = "subscript<void, result<?a, exception>>";
char constantarr_0_313[6] = "ok<?a>";
char constantarr_0_314[9] = "value<?a>";
char constantarr_0_315[14] = "err<exception>";
char constantarr_0_316[22] = "callback!<?in>.lambda0";
char constantarr_0_317[17] = "forward-to!<?out>";
char constantarr_0_318[13] = "callback!<?a>";
char constantarr_0_319[21] = "callback!<?a>.lambda0";
char constantarr_0_320[22] = "resolve-or-reject!<?a>";
char constantarr_0_321[24] = "with-lock<fut-state<?a>>";
char constantarr_0_322[22] = "fut-state-resolved<?a>";
char constantarr_0_323[16] = "value<exception>";
char constantarr_0_324[30] = "resolve-or-reject!<?a>.lambda0";
char constantarr_0_325[19] = "call-callbacks!<?a>";
char constantarr_0_326[6] = "cb<?a>";
char constantarr_0_327[8] = "next<?a>";
char constantarr_0_328[30] = "value<fut-state-callbacks<?a>>";
char constantarr_0_329[25] = "forward-to!<?out>.lambda0";
char constantarr_0_330[20] = "subscript<?out, ?in>";
char constantarr_0_331[10] = "get-island";
char constantarr_0_332[17] = "subscript<island>";
char constantarr_0_333[7] = "islands";
char constantarr_0_334[29] = "island-and-exclusion<?r, ?p0>";
char constantarr_0_335[8] = "add-task";
char constantarr_0_336[15] = "task-queue-node";
char constantarr_0_337[4] = "task";
char constantarr_0_338[10] = "tasks-lock";
char constantarr_0_339[12] = "insert-task!";
char constantarr_0_340[4] = "size";
char constantarr_0_341[10] = "size-recur";
char constantarr_0_342[4] = "next";
char constantarr_0_343[22] = "value<task-queue-node>";
char constantarr_0_344[4] = "head";
char constantarr_0_345[8] = "set-head";
char constantarr_0_346[21] = "some<task-queue-node>";
char constantarr_0_347[4] = "time";
char constantarr_0_348[12] = "insert-recur";
char constantarr_0_349[8] = "set-next";
char constantarr_0_350[5] = "tasks";
char constantarr_0_351[22] = "ref-of-val<task-queue>";
char constantarr_0_352[10] = "broadcast!";
char constantarr_0_353[9] = "set-value";
char constantarr_0_354[21] = "ref-of-val<condition>";
char constantarr_0_355[17] = "may-be-work-to-do";
char constantarr_0_356[4] = "gctx";
char constantarr_0_357[12] = "no-timestamp";
char constantarr_0_358[9] = "exclusion";
char constantarr_0_359[11] = "catch<void>";
char constantarr_0_360[28] = "catch-with-exception-ctx<?a>";
char constantarr_0_361[16] = "thrown-exception";
char constantarr_0_362[11] = "jmp-buf-tag";
char constantarr_0_363[4] = "zero";
char constantarr_0_364[7] = "bytes64";
char constantarr_0_365[7] = "bytes32";
char constantarr_0_366[7] = "bytes16";
char constantarr_0_367[8] = "bytes128";
char constantarr_0_368[15] = "set-jmp-buf-ptr";
char constantarr_0_369[19] = "ptr-to<jmp-buf-tag>";
char constantarr_0_370[6] = "setjmp";
char constantarr_0_371[24] = "subscript<?a, exception>";
char constantarr_0_372[23] = "subscript<fut<?r>, ?p0>";
char constantarr_0_373[12] = "fun<?r, ?p0>";
char constantarr_0_374[36] = "subscript<?out, ?in>.lambda0.lambda0";
char constantarr_0_375[11] = "reject!<?r>";
char constantarr_0_376[36] = "subscript<?out, ?in>.lambda0.lambda1";
char constantarr_0_377[28] = "subscript<?out, ?in>.lambda0";
char constantarr_0_378[10] = "value<?in>";
char constantarr_0_379[24] = "then<?out, void>.lambda0";
char constantarr_0_380[15] = "subscript<?out>";
char constantarr_0_381[24] = "island-and-exclusion<?r>";
char constantarr_0_382[18] = "subscript<fut<?r>>";
char constantarr_0_383[7] = "fun<?r>";
char constantarr_0_384[31] = "subscript<?out>.lambda0.lambda0";
char constantarr_0_385[31] = "subscript<?out>.lambda0.lambda1";
char constantarr_0_386[23] = "subscript<?out>.lambda0";
char constantarr_0_387[22] = "then-void<nat>.lambda0";
char constantarr_0_388[24] = "cur-island-and-exclusion";
char constantarr_0_389[20] = "island-and-exclusion";
char constantarr_0_390[9] = "island-id";
char constantarr_0_391[5] = "delay";
char constantarr_0_392[14] = "resolved<void>";
char constantarr_0_393[15] = "tail<ptr<char>>";
char constantarr_0_394[10] = "empty?<?a>";
char constantarr_0_395[40] = "subscript<fut<nat>, ctx, arr<arr<char>>>";
char constantarr_0_396[25] = "map<arr<char>, ptr<char>>";
char constantarr_0_397[14] = "make-arr<?out>";
char constantarr_0_398[18] = "fill-ptr-range<?a>";
char constantarr_0_399[24] = "fill-ptr-range-recur<?a>";
char constantarr_0_400[18] = "subscript<?a, nat>";
char constantarr_0_401[14] = "subscript<?in>";
char constantarr_0_402[33] = "map<arr<char>, ptr<char>>.lambda0";
char constantarr_0_403[24] = "arr-from-begin-end<char>";
char constantarr_0_404[16] = "ptr-less-eq?<?a>";
char constantarr_0_405[5] = "-<?a>";
char constantarr_0_406[13] = "find-cstr-end";
char constantarr_0_407[17] = "find-char-in-cstr";
char constantarr_0_408[8] = "==<char>";
char constantarr_0_409[15] = "some<ptr<char>>";
char constantarr_0_410[27] = "hard-unreachable<ptr<char>>";
char constantarr_0_411[16] = "value<ptr<char>>";
char constantarr_0_412[30] = "add-first-task.lambda0.lambda0";
char constantarr_0_413[22] = "add-first-task.lambda0";
char constantarr_0_414[22] = "handle-exceptions<nat>";
char constantarr_0_415[26] = "subscript<void, exception>";
char constantarr_0_416[17] = "exception-handler";
char constantarr_0_417[14] = "get-cur-island";
char constantarr_0_418[30] = "handle-exceptions<nat>.lambda0";
char constantarr_0_419[15] = "do-main.lambda0";
char constantarr_0_420[80] = "call-with-ctx<fut<nat>, arr<ptr<char>>, fun-ptr2<fut<nat>, ctx, arr<arr<char>>>>";
char constantarr_0_421[11] = "run-threads";
char constantarr_0_422[45] = "unmanaged-alloc-elements<by-val<thread-args>>";
char constantarr_0_423[19] = "start-threads-recur";
char constantarr_0_424[22] = "+<by-val<thread-args>>";
char constantarr_0_425[34] = "set-subscript<by-val<thread-args>>";
char constantarr_0_426[11] = "thread-args";
char constantarr_0_427[17] = "create-one-thread";
char constantarr_0_428[14] = "pthread-create";
char constantarr_0_429[9] = "!=<int32>";
char constantarr_0_430[6] = "eagain";
char constantarr_0_431[12] = "as-cell<nat>";
char constantarr_0_432[16] = "as-ref<cell<?a>>";
char constantarr_0_433[36] = "as-any-ptr<ptr<by-val<thread-args>>>";
char constantarr_0_434[10] = "thread-fun";
char constantarr_0_435[19] = "as-ref<thread-args>";
char constantarr_0_436[15] = "thread-function";
char constantarr_0_437[21] = "thread-function-recur";
char constantarr_0_438[10] = "shut-down?";
char constantarr_0_439[18] = "set-n-live-threads";
char constantarr_0_440[14] = "n-live-threads";
char constantarr_0_441[28] = "assert-islands-are-shut-down";
char constantarr_0_442[9] = "needs-gc?";
char constantarr_0_443[17] = "n-threads-running";
char constantarr_0_444[6] = "empty?";
char constantarr_0_445[16] = "get-last-checked";
char constantarr_0_446[11] = "choose-task";
char constantarr_0_447[17] = "get-monotime-nsec";
char constantarr_0_448[26] = "as<by-val<cell<timespec>>>";
char constantarr_0_449[14] = "cell<timespec>";
char constantarr_0_450[8] = "timespec";
char constantarr_0_451[13] = "clock-gettime";
char constantarr_0_452[15] = "clock-monotonic";
char constantarr_0_453[26] = "ref-of-val<cell<timespec>>";
char constantarr_0_454[19] = "subscript<timespec>";
char constantarr_0_455[6] = "tv-sec";
char constantarr_0_456[7] = "tv-nsec";
char constantarr_0_457[9] = "todo<nat>";
char constantarr_0_458[22] = "as<choose-task-result>";
char constantarr_0_459[17] = "choose-task-recur";
char constantarr_0_460[14] = "no-chosen-task";
char constantarr_0_461[21] = "choose-task-in-island";
char constantarr_0_462[32] = "as<choose-task-in-island-result>";
char constantarr_0_463[7] = "do-a-gc";
char constantarr_0_464[7] = "no-task";
char constantarr_0_465[9] = "pop-task!";
char constantarr_0_466[25] = "ref-of-val<mut-list<nat>>";
char constantarr_0_467[28] = "currently-running-exclusions";
char constantarr_0_468[19] = "as<pop-task-result>";
char constantarr_0_469[14] = "contains?<nat>";
char constantarr_0_470[13] = "contains?<?a>";
char constantarr_0_471[19] = "contains-recur?<?a>";
char constantarr_0_472[15] = "temp-as-arr<?a>";
char constantarr_0_473[19] = "temp-as-mut-arr<?a>";
char constantarr_0_474[10] = "pop-recur!";
char constantarr_0_475[11] = "to-opt-time";
char constantarr_0_476[9] = "some<nat>";
char constantarr_0_477[38] = "push-capacity-must-be-sufficient!<nat>";
char constantarr_0_478[11] = "is-no-task?";
char constantarr_0_479[21] = "set-n-threads-running";
char constantarr_0_480[11] = "chosen-task";
char constantarr_0_481[10] = "any-tasks?";
char constantarr_0_482[8] = "min-time";
char constantarr_0_483[8] = "min<nat>";
char constantarr_0_484[5] = "?<?a>";
char constantarr_0_485[10] = "value<nat>";
char constantarr_0_486[15] = "first-task-time";
char constantarr_0_487[29] = "no-tasks-and-last-thread-out?";
char constantarr_0_488[7] = "do-task";
char constantarr_0_489[11] = "task-island";
char constantarr_0_490[10] = "task-or-gc";
char constantarr_0_491[6] = "action";
char constantarr_0_492[12] = "return-task!";
char constantarr_0_493[33] = "noctx-must-remove-unordered!<nat>";
char constantarr_0_494[38] = "noctx-must-remove-unordered-recur!<?a>";
char constantarr_0_495[8] = "drop<?a>";
char constantarr_0_496[30] = "noctx-remove-unordered-at!<?a>";
char constantarr_0_497[10] = "return-ctx";
char constantarr_0_498[13] = "return-gc-ctx";
char constantarr_0_499[12] = "some<gc-ctx>";
char constantarr_0_500[46] = "run-garbage-collection<by-val<island-gc-root>>";
char constantarr_0_501[13] = "set-needs-gc?";
char constantarr_0_502[12] = "set-gc-count";
char constantarr_0_503[8] = "gc-count";
char constantarr_0_504[20] = "as<by-val<mark-ctx>>";
char constantarr_0_505[8] = "mark-ctx";
char constantarr_0_506[14] = "mark-visit<?a>";
char constantarr_0_507[20] = "ref-of-val<mark-ctx>";
char constantarr_0_508[14] = "clear-free-mem";
char constantarr_0_509[14] = "set-shut-down?";
char constantarr_0_510[7] = "wait-on";
char constantarr_0_511[12] = "before-time?";
char constantarr_0_512[9] = "thread-id";
char constantarr_0_513[18] = "join-threads-recur";
char constantarr_0_514[15] = "join-one-thread";
char constantarr_0_515[27] = "as<by-val<cell<ptr<nat8>>>>";
char constantarr_0_516[15] = "cell<ptr<nat8>>";
char constantarr_0_517[12] = "pthread-join";
char constantarr_0_518[27] = "ref-of-val<cell<ptr<nat8>>>";
char constantarr_0_519[6] = "einval";
char constantarr_0_520[5] = "esrch";
char constantarr_0_521[20] = "subscript<ptr<nat8>>";
char constantarr_0_522[19] = "unmanaged-free<nat>";
char constantarr_0_523[4] = "free";
char constantarr_0_524[35] = "unmanaged-free<by-val<thread-args>>";
char constantarr_0_525[18] = "ptr-cast<nat8, ?a>";
char constantarr_0_526[8] = "?<int32>";
char constantarr_0_527[25] = "any-unhandled-exceptions?";
char constantarr_0_528[4] = "main";
char constantarr_0_529[13] = "resolved<nat>";
uint8_t mark(struct mark_ctx* ctx, uint8_t* ptr_any, uint64_t size_bytes);
struct void_ hard_assert(uint8_t condition);
extern void abort(void);
uint8_t word_aligned__q(uint8_t* a);
uint8_t _equal_0(uint64_t a, uint64_t b);
struct comparison compare_5(uint64_t a, uint64_t b);
uint64_t words_of_bytes(uint64_t size_bytes);
uint64_t round_up_to_multiple_of_8(uint64_t n);
uint64_t _minus_0(uint64_t* a, uint64_t* b);
uint8_t _less(uint64_t a, uint64_t b);
uint8_t _lessOrEqual(uint64_t a, uint64_t b);
uint8_t not(uint8_t a);
uint8_t mark_range_recur(uint8_t marked_anything__q, uint8_t* cur, uint8_t* end);
uint8_t _greater(uint64_t a, uint64_t b);
int32_t rt_main(int32_t argc, char** argv, fun_ptr2 main_ptr);
extern uint64_t get_nprocs(void);
struct lock lock_by_val(void);
struct _atomic_bool _atomic_bool(void);
struct condition condition(void);
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
struct void_ print_err_no_newline(struct arr_0 s);
struct void_ write_no_newline(int32_t fd, struct arr_0 a);
extern int64_t write(int32_t fd, uint8_t* buf, uint64_t n_bytes);
uint8_t _notEqual_0(int64_t a, int64_t b);
uint8_t _equal_1(int64_t a, int64_t b);
struct comparison compare_37(int64_t a, int64_t b);
struct void_ todo_0(void);
int32_t stderr(void);
struct void_ print_err(struct arr_0 s);
struct arr_0 show_exception(struct ctx* ctx, struct exception a);
uint8_t empty__q_0(struct arr_0 a);
struct arr_0 flatten(struct ctx* ctx, struct arr_1 a, struct arr_0 joiner);
uint8_t empty__q_1(struct arr_1 a);
struct arr_0 subscript_0(struct ctx* ctx, struct arr_1 a, uint64_t index);
struct void_ assert(struct ctx* ctx, uint8_t condition);
struct void_ fail(struct ctx* ctx, struct arr_0 message);
struct void_ throw(struct ctx* ctx, struct exception e);
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
uint8_t _equal_2(int32_t a, int32_t b);
struct comparison compare_67(int32_t a, int32_t b);
uint64_t noctx_incr(uint64_t n);
struct opt_5 try_gc_alloc_recur(struct gc* gc, uint64_t size_bytes);
struct void_ validate_gc(struct gc* gc);
uint8_t ptr_less_eq__q_0(uint8_t* a, uint8_t* b);
uint8_t ptr_less_eq__q_1(uint64_t* a, uint64_t* b);
uint64_t _minus_1(uint8_t* a, uint8_t* b);
uint8_t range_free__q(uint8_t* mark, uint8_t* end);
struct void_ release__e(struct lock* a);
struct void_ must_unset__e(struct _atomic_bool* a);
uint8_t try_unset__e(struct _atomic_bool* a);
struct gc* get_gc(struct ctx* ctx);
struct gc_ctx* get_gc_ctx_0(struct ctx* ctx);
struct opt_6 try_alloc_uninitialized_1(struct ctx* ctx, uint64_t size);
uint64_t funs_count_81(void);
extern int32_t backtrace(uint8_t** array, int32_t size);
uint64_t code_ptrs_size(struct ctx* ctx);
struct void_ fill_fun_ptrs_names_recur(uint64_t i, uint8_t** fun_ptrs, struct arr_0* fun_names);
uint8_t _notEqual_1(uint64_t a, uint64_t b);
struct void_ set_subscript_0(uint8_t** a, uint64_t n, uint8_t* value);
uint8_t* get_fun_ptr_87(uint64_t fun_id);
struct void_ set_subscript_1(struct arr_0* a, uint64_t n, struct arr_0 value);
struct arr_0 get_fun_name_89(uint64_t fun_id);
struct void_ sort_together(struct ctx* ctx, uint8_t** a, struct arr_0* b, uint64_t size);
struct void_ swap_0(struct ctx* ctx, uint8_t** a, uint64_t lo, uint64_t hi);
uint8_t* subscript_1(uint8_t** a, uint64_t n);
struct void_ swap_1(struct ctx* ctx, struct arr_0* a, uint64_t lo, uint64_t hi);
struct arr_0 subscript_2(struct arr_0* a, uint64_t n);
uint64_t partition_recur_together(struct ctx* ctx, uint8_t** a, struct arr_0* b, uint8_t* pivot, uint64_t l, uint64_t r);
uint64_t noctx_decr(uint64_t n);
struct void_ fill_code_names_recur(struct ctx* ctx, struct arr_0* code_names, struct arr_0* end_code_names, uint8_t** code_ptrs, uint8_t** fun_ptrs, struct arr_0* fun_names);
struct arr_0 get_fun_name(uint8_t* code_ptr, uint8_t** fun_ptrs, struct arr_0* fun_names, uint64_t size);
struct arr_0 noctx_at_0(struct arr_1 a, uint64_t index);
struct arr_0 _concat(struct ctx* ctx, struct arr_0 a, struct arr_0 b);
uint64_t _plus(struct ctx* ctx, uint64_t a, uint64_t b);
uint8_t _greaterOrEqual(uint64_t a, uint64_t b);
char* alloc_uninitialized_0(struct ctx* ctx, uint64_t size);
uint8_t* alloc(struct ctx* ctx, uint64_t size_bytes);
uint8_t* gc_alloc(struct ctx* ctx, struct gc* gc, uint64_t size);
uint8_t* todo_1(void);
struct void_ copy_data_from(struct ctx* ctx, char* to, char* from, uint64_t len);
extern void memcpy(uint8_t* dest, uint8_t* src, uint64_t size);
struct arr_1 tail_0(struct ctx* ctx, struct arr_1 a);
struct void_ forbid_0(struct ctx* ctx, uint8_t condition);
struct void_ forbid_1(struct ctx* ctx, uint8_t condition, struct arr_0 message);
struct arr_1 subscript_3(struct ctx* ctx, struct arr_1 a, struct arrow range);
uint64_t _minus_2(struct ctx* ctx, uint64_t a, uint64_t b);
struct arrow _arrow(struct ctx* ctx, uint64_t from, uint64_t to);
struct arr_0 finish(struct ctx* ctx, struct interp a);
struct arr_0 move_to_arr__e(struct mut_list_1* a);
char* begin_ptr_0(struct mut_list_1* a);
char* begin_ptr_1(struct mut_arr_1 a);
struct mut_arr_1 mut_arr_1(void);
struct arr_0 to_str_0(struct ctx* ctx, struct arr_0 a);
struct interp with_value_0(struct ctx* ctx, struct interp a, struct arr_0 b);
struct interp with_str(struct ctx* ctx, struct interp a, struct arr_0 b);
struct void_ _concatEquals_0(struct ctx* ctx, struct mut_list_1* a, struct arr_0 values);
struct void_ each(struct ctx* ctx, struct arr_0 a, struct fun_act1_1 f);
struct void_ each_recur(struct ctx* ctx, char* cur, char* end, struct fun_act1_1 f);
struct void_ subscript_4(struct ctx* ctx, struct fun_act1_1 a, char p0);
struct void_ call_w_ctx_127(struct fun_act1_1 a, struct ctx* ctx, char p0);
char* end_ptr(struct arr_0 a);
struct void_ _concatEquals_1(struct ctx* ctx, struct mut_list_1* a, char value);
struct void_ incr_capacity__e(struct ctx* ctx, struct mut_list_1* a);
struct void_ ensure_capacity(struct ctx* ctx, struct mut_list_1* a, uint64_t min_capacity);
uint64_t capacity_0(struct mut_list_1* a);
uint64_t size_0(struct mut_arr_1 a);
struct void_ increase_capacity_to__e(struct ctx* ctx, struct mut_list_1* a, uint64_t new_capacity);
struct mut_arr_1 uninitialized_mut_arr(struct ctx* ctx, uint64_t size);
struct mut_arr_1 mut_arr_2(uint64_t size, char* begin_ptr);
struct void_ set_zero_elements(struct mut_arr_1 a);
struct void_ set_zero_range_1(char* begin, uint64_t size);
struct mut_arr_1 subscript_5(struct ctx* ctx, struct mut_arr_1 a, struct arrow range);
struct arr_0 subscript_6(struct ctx* ctx, struct arr_0 a, struct arrow range);
uint64_t round_up_to_power_of_two(struct ctx* ctx, uint64_t n);
uint64_t round_up_to_power_of_two_recur(struct ctx* ctx, uint64_t acc, uint64_t n);
uint64_t _times(struct ctx* ctx, uint64_t a, uint64_t b);
uint64_t _divide(struct ctx* ctx, uint64_t a, uint64_t b);
struct void_ set_subscript_2(char* a, uint64_t n, char value);
struct void_ _concatEquals_0__lambda0(struct ctx* ctx, struct _concatEquals_0__lambda0* _closure, char it);
struct interp interp(struct ctx* ctx);
struct mut_list_1* mut_list(struct ctx* ctx);
struct global_ctx* get_global_ctx(struct ctx* ctx);
struct void_ island__lambda0(struct ctx* ctx, struct void_ _closure, struct exception it);
struct void_ default_log_handler(struct ctx* ctx, struct logged* a);
struct void_ print(struct arr_0 a);
struct void_ print_no_newline(struct arr_0 a);
int32_t stdout(void);
struct arr_0 to_str_1(struct ctx* ctx, struct log_level a);
struct interp with_value_1(struct ctx* ctx, struct interp a, struct log_level b);
struct void_ island__lambda1(struct ctx* ctx, struct void_ _closure, struct logged* log);
struct gc gc(void);
struct thread_safe_counter thread_safe_counter_0(void);
struct thread_safe_counter thread_safe_counter_1(uint64_t init);
struct fut_0* do_main(struct global_ctx* gctx, struct island* island, int32_t argc, char** argv, fun_ptr2 main_ptr);
struct exception_ctx exception_ctx(void);
struct log_ctx log_ctx(void);
struct ctx ctx(struct global_ctx* gctx, struct thread_local_stuff* tls, struct island* island, uint64_t exclusion);
struct gc_ctx* get_gc_ctx_1(struct gc* gc);
struct fut_0* add_first_task(struct ctx* ctx, struct arr_4 all_args, fun_ptr2 main_ptr);
struct fut_0* then_void(struct ctx* ctx, struct fut_1* a, struct fun_ref0 cb);
struct fut_0* then(struct ctx* ctx, struct fut_1* a, struct fun_ref1 cb);
struct fut_0* unresolved(struct ctx* ctx);
struct void_ callback__e_0(struct ctx* ctx, struct fut_1* f, struct fun_act1_2 cb);
struct void_ with_lock_0(struct ctx* ctx, struct lock* a, struct fun_act0_0 f);
struct void_ subscript_7(struct ctx* ctx, struct fun_act0_0 a);
struct void_ call_w_ctx_173(struct fun_act0_0 a, struct ctx* ctx);
struct void_ subscript_8(struct ctx* ctx, struct fun_act1_2 a, struct result_1 p0);
struct void_ call_w_ctx_175(struct fun_act1_2 a, struct ctx* ctx, struct result_1 p0);
struct void_ callback__e_0__lambda0(struct ctx* ctx, struct callback__e_0__lambda0* _closure);
struct void_ forward_to__e(struct ctx* ctx, struct fut_0* from, struct fut_0* to);
struct void_ callback__e_1(struct ctx* ctx, struct fut_0* f, struct fun_act1_0 cb);
struct void_ subscript_9(struct ctx* ctx, struct fun_act1_0 a, struct result_0 p0);
struct void_ call_w_ctx_180(struct fun_act1_0 a, struct ctx* ctx, struct result_0 p0);
struct void_ callback__e_1__lambda0(struct ctx* ctx, struct callback__e_1__lambda0* _closure);
struct void_ resolve_or_reject__e(struct ctx* ctx, struct fut_0* f, struct result_0 result);
struct fut_state_0 with_lock_1(struct ctx* ctx, struct lock* a, struct fun_act0_2 f);
struct fut_state_0 subscript_10(struct ctx* ctx, struct fun_act0_2 a);
struct fut_state_0 call_w_ctx_185(struct fun_act0_2 a, struct ctx* ctx);
struct fut_state_0 resolve_or_reject__e__lambda0(struct ctx* ctx, struct resolve_or_reject__e__lambda0* _closure);
struct void_ call_callbacks__e(struct ctx* ctx, struct fut_state_callbacks_0* cbs, struct result_0 value);
struct void_ forward_to__e__lambda0(struct ctx* ctx, struct forward_to__e__lambda0* _closure, struct result_0 it);
struct fut_0* subscript_11(struct ctx* ctx, struct fun_ref1 f, struct void_ p0);
struct island* get_island(struct ctx* ctx, uint64_t island_id);
struct island* subscript_12(struct ctx* ctx, struct arr_3 a, uint64_t index);
struct island* noctx_at_1(struct arr_3 a, uint64_t index);
struct island* subscript_13(struct island** a, uint64_t n);
struct void_ add_task_0(struct ctx* ctx, struct island* a, uint64_t exclusion, struct fun_act0_0 action);
struct void_ add_task_1(struct ctx* ctx, struct island* a, uint64_t timestamp, uint64_t exclusion, struct fun_act0_0 action);
struct task_queue_node* task_queue_node(struct ctx* ctx, struct task task);
struct void_ insert_task__e(struct task_queue* a, struct task_queue_node* inserted);
uint64_t size_1(struct task_queue* a);
uint64_t size_recur(struct opt_2 node, uint64_t acc);
struct void_ insert_recur(struct task_queue_node* prev, struct task_queue_node* inserted);
struct task_queue* tasks(struct island* a);
struct void_ broadcast__e(struct condition* c);
uint64_t no_timestamp(void);
struct void_ catch(struct ctx* ctx, struct fun_act0_0 try, struct fun_act1_4 catcher);
struct void_ catch_with_exception_ctx(struct ctx* ctx, struct exception_ctx* ec, struct fun_act0_0 try, struct fun_act1_4 catcher);
struct bytes64 zero_0(void);
struct bytes32 zero_1(void);
struct bytes16 zero_2(void);
struct bytes128 zero_3(void);
extern int32_t setjmp(struct jmp_buf_tag* env);
struct void_ subscript_14(struct ctx* ctx, struct fun_act1_4 a, struct exception p0);
struct void_ call_w_ctx_212(struct fun_act1_4 a, struct ctx* ctx, struct exception p0);
struct fut_0* subscript_15(struct ctx* ctx, struct fun_act1_3 a, struct void_ p0);
struct fut_0* call_w_ctx_214(struct fun_act1_3 a, struct ctx* ctx, struct void_ p0);
struct void_ subscript_11__lambda0__lambda0(struct ctx* ctx, struct subscript_11__lambda0__lambda0* _closure);
struct void_ reject__e(struct ctx* ctx, struct fut_0* f, struct exception e);
struct void_ subscript_11__lambda0__lambda1(struct ctx* ctx, struct subscript_11__lambda0__lambda1* _closure, struct exception it);
struct void_ subscript_11__lambda0(struct ctx* ctx, struct subscript_11__lambda0* _closure);
struct void_ then__lambda0(struct ctx* ctx, struct then__lambda0* _closure, struct result_1 result);
struct fut_0* subscript_16(struct ctx* ctx, struct fun_ref0 f);
struct fut_0* subscript_17(struct ctx* ctx, struct fun_act0_1 a);
struct fut_0* call_w_ctx_222(struct fun_act0_1 a, struct ctx* ctx);
struct void_ subscript_16__lambda0__lambda0(struct ctx* ctx, struct subscript_16__lambda0__lambda0* _closure);
struct void_ subscript_16__lambda0__lambda1(struct ctx* ctx, struct subscript_16__lambda0__lambda1* _closure, struct exception it);
struct void_ subscript_16__lambda0(struct ctx* ctx, struct subscript_16__lambda0* _closure);
struct fut_0* then_void__lambda0(struct ctx* ctx, struct then_void__lambda0* _closure, struct void_ ignore);
struct island_and_exclusion cur_island_and_exclusion(struct ctx* ctx);
struct fut_1* delay(struct ctx* ctx);
struct fut_1* resolved_0(struct ctx* ctx, struct void_ value);
struct arr_4 tail_1(struct ctx* ctx, struct arr_4 a);
uint8_t empty__q_2(struct arr_4 a);
struct arr_4 subscript_18(struct ctx* ctx, struct arr_4 a, struct arrow range);
struct arr_1 map(struct ctx* ctx, struct arr_4 a, struct fun_act1_5 f);
struct arr_1 make_arr(struct ctx* ctx, uint64_t size, struct fun_act1_6 f);
struct arr_0* alloc_uninitialized_1(struct ctx* ctx, uint64_t size);
struct void_ fill_ptr_range(struct ctx* ctx, struct arr_0* begin, uint64_t size, struct fun_act1_6 f);
struct void_ fill_ptr_range_recur(struct ctx* ctx, struct arr_0* begin, uint64_t i, uint64_t size, struct fun_act1_6 f);
struct arr_0 subscript_19(struct ctx* ctx, struct fun_act1_6 a, uint64_t p0);
struct arr_0 call_w_ctx_239(struct fun_act1_6 a, struct ctx* ctx, uint64_t p0);
struct arr_0 subscript_20(struct ctx* ctx, struct fun_act1_5 a, char* p0);
struct arr_0 call_w_ctx_241(struct fun_act1_5 a, struct ctx* ctx, char* p0);
char* subscript_21(struct ctx* ctx, struct arr_4 a, uint64_t index);
char* noctx_at_2(struct arr_4 a, uint64_t index);
char* subscript_22(char** a, uint64_t n);
struct arr_0 map__lambda0(struct ctx* ctx, struct map__lambda0* _closure, uint64_t i);
struct arr_0 to_str_2(char* a);
struct arr_0 arr_from_begin_end(char* begin, char* end);
uint8_t ptr_less_eq__q_2(char* a, char* b);
uint64_t _minus_3(char* a, char* b);
char* find_cstr_end(char* a);
struct opt_8 find_char_in_cstr(char* a, char c);
uint8_t _equal_3(char a, char b);
struct comparison compare_253(char a, char b);
char* hard_unreachable_1(void);
struct arr_0 add_first_task__lambda0__lambda0(struct ctx* ctx, struct void_ _closure, char* it);
struct fut_0* add_first_task__lambda0(struct ctx* ctx, struct add_first_task__lambda0* _closure);
struct void_ handle_exceptions(struct ctx* ctx, struct fut_0* a);
struct void_ subscript_23(struct ctx* ctx, struct fun1_0 a, struct exception p0);
struct void_ call_w_ctx_259(struct fun1_0 a, struct ctx* ctx, struct exception p0);
struct fun1_0 exception_handler(struct ctx* ctx, struct island* a);
struct island* get_cur_island(struct ctx* ctx);
struct void_ handle_exceptions__lambda0(struct ctx* ctx, struct void_ _closure, struct result_0 result);
struct fut_0* do_main__lambda0(struct ctx* ctx, struct void_ _closure, struct arr_4 all_args, fun_ptr2 main_ptr);
struct fut_0* call_w_ctx_264(struct fun_act2 a, struct ctx* ctx, struct arr_4 p0, fun_ptr2 p1);
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
struct void_ thread_function_recur(uint64_t thread_id, struct global_ctx* gctx, struct thread_local_stuff* tls);
struct void_ assert_islands_are_shut_down(uint64_t i, struct arr_3 islands);
uint8_t empty__q_3(struct task_queue* a);
uint64_t get_last_checked(struct condition* a);
struct choose_task_result choose_task(struct global_ctx* gctx);
uint64_t get_monotime_nsec(void);
extern int32_t clock_gettime(int32_t clock_id, struct cell_1* timespec);
int32_t clock_monotonic(void);
uint64_t todo_2(void);
struct choose_task_result choose_task_recur(struct arr_3 islands, uint64_t i, uint64_t cur_time, uint8_t any_tasks__q, struct opt_9 first_task_time);
struct choose_task_in_island_result choose_task_in_island(struct island* island, uint64_t cur_time);
struct pop_task_result pop_task__e(struct task_queue* a, uint64_t cur_time);
uint8_t contains__q_0(struct mut_list_0* a, uint64_t value);
uint8_t contains__q_1(struct arr_2 a, uint64_t value);
uint8_t contains_recur__q(struct arr_2 a, uint64_t value, uint64_t i);
uint64_t noctx_at_3(struct arr_2 a, uint64_t index);
uint64_t subscript_24(uint64_t* a, uint64_t n);
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
struct void_ mark_visit_315(struct mark_ctx* mark_ctx, struct island_gc_root value);
struct void_ mark_visit_316(struct mark_ctx* mark_ctx, struct task_queue value);
struct void_ mark_visit_317(struct mark_ctx* mark_ctx, struct opt_2 value);
struct void_ mark_visit_318(struct mark_ctx* mark_ctx, struct some_2 value);
struct void_ mark_visit_319(struct mark_ctx* mark_ctx, struct task_queue_node value);
struct void_ mark_visit_320(struct mark_ctx* mark_ctx, struct task value);
struct void_ mark_visit_321(struct mark_ctx* mark_ctx, struct fun_act0_0 value);
struct void_ mark_visit_322(struct mark_ctx* mark_ctx, struct callback__e_0__lambda0 value);
struct void_ mark_visit_323(struct mark_ctx* mark_ctx, struct fut_1 value);
struct void_ mark_visit_324(struct mark_ctx* mark_ctx, struct fut_state_1 value);
struct void_ mark_visit_325(struct mark_ctx* mark_ctx, struct fut_state_callbacks_1 value);
struct void_ mark_visit_326(struct mark_ctx* mark_ctx, struct fun_act1_2 value);
struct void_ mark_visit_327(struct mark_ctx* mark_ctx, struct then__lambda0 value);
struct void_ mark_visit_328(struct mark_ctx* mark_ctx, struct fun_ref1 value);
struct void_ mark_visit_329(struct mark_ctx* mark_ctx, struct fun_act1_3 value);
struct void_ mark_visit_330(struct mark_ctx* mark_ctx, struct then_void__lambda0 value);
struct void_ mark_visit_331(struct mark_ctx* mark_ctx, struct fun_ref0 value);
struct void_ mark_visit_332(struct mark_ctx* mark_ctx, struct fun_act0_1 value);
struct void_ mark_visit_333(struct mark_ctx* mark_ctx, struct add_first_task__lambda0 value);
struct void_ mark_arr_334(struct mark_ctx* mark_ctx, struct arr_4 a);
struct void_ mark_visit_335(struct mark_ctx* mark_ctx, struct add_first_task__lambda0* value);
struct void_ mark_visit_336(struct mark_ctx* mark_ctx, struct then_void__lambda0* value);
struct void_ mark_visit_337(struct mark_ctx* mark_ctx, struct fut_0 value);
struct void_ mark_visit_338(struct mark_ctx* mark_ctx, struct fut_state_0 value);
struct void_ mark_visit_339(struct mark_ctx* mark_ctx, struct fut_state_callbacks_0 value);
struct void_ mark_visit_340(struct mark_ctx* mark_ctx, struct fun_act1_0 value);
struct void_ mark_visit_341(struct mark_ctx* mark_ctx, struct forward_to__e__lambda0 value);
struct void_ mark_visit_342(struct mark_ctx* mark_ctx, struct fut_0* value);
struct void_ mark_visit_343(struct mark_ctx* mark_ctx, struct forward_to__e__lambda0* value);
struct void_ mark_visit_344(struct mark_ctx* mark_ctx, struct opt_0 value);
struct void_ mark_visit_345(struct mark_ctx* mark_ctx, struct some_0 value);
struct void_ mark_visit_346(struct mark_ctx* mark_ctx, struct fut_state_callbacks_0* value);
struct void_ mark_visit_347(struct mark_ctx* mark_ctx, struct exception value);
struct void_ mark_arr_348(struct mark_ctx* mark_ctx, struct arr_0 a);
struct void_ mark_visit_349(struct mark_ctx* mark_ctx, struct backtrace value);
struct void_ mark_elems_350(struct mark_ctx* mark_ctx, struct arr_0* cur, struct arr_0* end);
struct void_ mark_arr_351(struct mark_ctx* mark_ctx, struct arr_1 a);
struct void_ mark_visit_352(struct mark_ctx* mark_ctx, struct then__lambda0* value);
struct void_ mark_visit_353(struct mark_ctx* mark_ctx, struct opt_7 value);
struct void_ mark_visit_354(struct mark_ctx* mark_ctx, struct some_7 value);
struct void_ mark_visit_355(struct mark_ctx* mark_ctx, struct fut_state_callbacks_1* value);
struct void_ mark_visit_356(struct mark_ctx* mark_ctx, struct fut_1* value);
struct void_ mark_visit_357(struct mark_ctx* mark_ctx, struct callback__e_0__lambda0* value);
struct void_ mark_visit_358(struct mark_ctx* mark_ctx, struct callback__e_1__lambda0 value);
struct void_ mark_visit_359(struct mark_ctx* mark_ctx, struct callback__e_1__lambda0* value);
struct void_ mark_visit_360(struct mark_ctx* mark_ctx, struct subscript_11__lambda0__lambda0 value);
struct void_ mark_visit_361(struct mark_ctx* mark_ctx, struct subscript_11__lambda0__lambda0* value);
struct void_ mark_visit_362(struct mark_ctx* mark_ctx, struct subscript_11__lambda0 value);
struct void_ mark_visit_363(struct mark_ctx* mark_ctx, struct subscript_11__lambda0* value);
struct void_ mark_visit_364(struct mark_ctx* mark_ctx, struct subscript_16__lambda0__lambda0 value);
struct void_ mark_visit_365(struct mark_ctx* mark_ctx, struct subscript_16__lambda0__lambda0* value);
struct void_ mark_visit_366(struct mark_ctx* mark_ctx, struct subscript_16__lambda0 value);
struct void_ mark_visit_367(struct mark_ctx* mark_ctx, struct subscript_16__lambda0* value);
struct void_ mark_visit_368(struct mark_ctx* mark_ctx, struct task_queue_node* value);
struct void_ mark_visit_369(struct mark_ctx* mark_ctx, struct mut_list_0 value);
struct void_ mark_visit_370(struct mark_ctx* mark_ctx, struct mut_arr_0 value);
struct void_ mark_arr_371(struct mark_ctx* mark_ctx, struct arr_2 a);
struct void_ clear_free_mem(uint8_t* mark_ptr, uint8_t* mark_end, uint64_t* data_ptr);
struct void_ wait_on(struct condition* cond, struct opt_9 until_time, uint64_t last_checked);
uint8_t before_time__q(struct opt_9 until_time);
struct void_ join_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads);
struct void_ join_one_thread(uint64_t tid);
extern int32_t pthread_join(uint64_t thread, struct cell_2* thread_return);
int32_t einval(void);
int32_t esrch(void);
struct void_ unmanaged_free_0(uint64_t* p);
extern void free(uint8_t* p);
struct void_ unmanaged_free_1(struct thread_args* p);
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
	ptr1 = (uint64_t*) ptr_any;
	
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
	return _equal_0(((uint64_t) a & 7u), 0u);
}
/* ==<nat> bool(a nat, b nat) */
uint8_t _equal_0(uint64_t a, uint64_t b) {
	struct comparison _0 = compare_5(a, b);
	switch (_0.kind) {
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
			return 0;
	}
}
/* compare<nat-64> (generated) (generated) */
struct comparison compare_5(uint64_t a, uint64_t b) {
	uint8_t _0 = (a < b);
	if (_0) {
		return (struct comparison) {0, .as0 = (struct less) {}};
	} else {
		uint8_t _1 = (b < a);
		if (_1) {
			return (struct comparison) {2, .as2 = (struct greater) {}};
		} else {
			return (struct comparison) {1, .as1 = (struct equal) {}};
		}
	}
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
	return (((uint64_t) a - (uint64_t) b) / sizeof(uint64_t));
}
/* <<nat> bool(a nat, b nat) */
uint8_t _less(uint64_t a, uint64_t b) {
	struct comparison _0 = compare_5(a, b);
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
			return 0;
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
/* rt-main int32(argc int32, argv ptr<ptr<char>>, main-ptr fun-ptr2<fut<nat>, ctx, arr<arr<char>>>) */
int32_t rt_main(int32_t argc, char** argv, fun_ptr2 main_ptr) {
	uint64_t n_threads0;
	n_threads0 = get_nprocs();
	
	struct global_ctx gctx_by_val1;
	struct lock _0 = lock_by_val();
	struct condition _1 = condition();
	gctx_by_val1 = (struct global_ctx) {_0, (struct arr_3) {0u, NULL}, n_threads0, _1, 0, 0};
	
	struct global_ctx* gctx2;
	gctx2 = (&gctx_by_val1);
	
	struct island island_by_val3;
	island_by_val3 = island(gctx2, 0u, n_threads0);
	
	struct island* island4;
	island4 = (&island_by_val3);
	
	gctx2->islands = (struct arr_3) {1u, (&island4)};
	struct fut_0* main_fut5;
	main_fut5 = do_main(gctx2, island4, argc, argv, main_ptr);
	
	run_threads(n_threads0, gctx2);
	struct fut_state_0 _2 = main_fut5->state;
	switch (_2.kind) {
		case 0: {
			return 1;
		}
		case 1: {
			return 1;
		}
		case 2: {
			struct fut_state_resolved_0 r6 = _2.as2;
			
			uint8_t _3 = gctx2->any_unhandled_exceptions__q;
			if (_3) {
				return 1;
			} else {
				return (int32_t) (int64_t) r6.value;
			}
		}
		case 3: {
			return 1;
		}
		default:
			return 0;
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
/* condition condition() */
struct condition condition(void) {
	struct lock _0 = lock_by_val();
	return (struct condition) {_0, 0u};
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
	return (uint64_t*) _0;
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
	return _equal_0((uint64_t) a, (uint64_t) NULL);
}
/* set-zero-range<?a> void(begin ptr<nat>, size nat) */
struct void_ set_zero_range_0(uint64_t* begin, uint64_t size) {
	return (memset(((uint8_t*) begin), 0u, (size * sizeof(uint64_t))), (struct void_) {});
}
/* default-exception-handler void(e exception) */
struct void_ default_exception_handler(struct ctx* ctx, struct exception e) {
	print_err_no_newline((struct arr_0) {20, constantarr_0_0});
	struct arr_0 _0 = show_exception(ctx, e);
	print_err(_0);
	struct global_ctx* _1 = get_global_ctx(ctx);
	return (_1->any_unhandled_exceptions__q = 1, (struct void_) {});
}
/* print-err-no-newline void(s arr<char>) */
struct void_ print_err_no_newline(struct arr_0 s) {
	int32_t _0 = stderr();
	return write_no_newline(_0, s);
}
/* write-no-newline void(fd int32, a arr<char>) */
struct void_ write_no_newline(int32_t fd, struct arr_0 a) {
	uint8_t _0 = _equal_0(sizeof(char), sizeof(uint8_t));
	hard_assert(_0);
	int64_t res0;
	res0 = write(fd, ((uint8_t*) a.begin_ptr), a.size);
	
	uint8_t _1 = _notEqual_0(res0, (int64_t) a.size);
	if (_1) {
		return todo_0();
	} else {
		return (struct void_) {};
	}
}
/* !=<int> bool(a int, b int) */
uint8_t _notEqual_0(int64_t a, int64_t b) {
	uint8_t _0 = _equal_1(a, b);
	return not(_0);
}
/* ==<?a> bool(a int, b int) */
uint8_t _equal_1(int64_t a, int64_t b) {
	struct comparison _0 = compare_37(a, b);
	switch (_0.kind) {
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
			return 0;
	}
}
/* compare<int-64> (generated) (generated) */
struct comparison compare_37(int64_t a, int64_t b) {
	uint8_t _0 = (a < b);
	if (_0) {
		return (struct comparison) {0, .as0 = (struct less) {}};
	} else {
		uint8_t _1 = (b < a);
		if (_1) {
			return (struct comparison) {2, .as2 = (struct greater) {}};
		} else {
			return (struct comparison) {1, .as1 = (struct equal) {}};
		}
	}
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
/* print-err void(s arr<char>) */
struct void_ print_err(struct arr_0 s) {
	print_err_no_newline(s);
	return print_err_no_newline((struct arr_0) {1, constantarr_0_1});
}
/* show-exception arr<char>(a exception) */
struct arr_0 show_exception(struct ctx* ctx, struct exception a) {
	struct arr_0 msg0;
	uint8_t _0 = empty__q_0(a.message);
	if (_0) {
		msg0 = (struct arr_0) {17, constantarr_0_2};
	} else {
		msg0 = a.message;
	}
	
	struct arr_0 bt1;
	bt1 = flatten(ctx, a.backtrace.return_stack, (struct arr_0) {5, constantarr_0_6});
	
	struct interp _1 = interp(ctx);
	struct interp _2 = with_value_0(ctx, _1, msg0);
	struct interp _3 = with_str(ctx, _2, (struct arr_0) {5, constantarr_0_6});
	struct interp _4 = with_value_0(ctx, _3, bt1);
	return finish(ctx, _4);
}
/* empty?<char> bool(a arr<char>) */
uint8_t empty__q_0(struct arr_0 a) {
	return _equal_0(a.size, 0u);
}
/* flatten<char> arr<char>(a arr<arr<char>>, joiner arr<char>) */
struct arr_0 flatten(struct ctx* ctx, struct arr_1 a, struct arr_0 joiner) {
	uint8_t _0 = empty__q_1(a);
	if (_0) {
		return (struct arr_0) {0u, NULL};
	} else {
		uint8_t _1 = _equal_0(a.size, 1u);
		if (_1) {
			return subscript_0(ctx, a, 0u);
		} else {
			struct arr_0 _2 = subscript_0(ctx, a, 0u);
			struct arr_0 _3 = _concat(ctx, _2, joiner);
			struct arr_1 _4 = tail_0(ctx, a);
			struct arr_0 _5 = flatten(ctx, _4, joiner);
			return _concat(ctx, _3, _5);
		}
	}
}
/* empty?<arr<?a>> bool(a arr<arr<char>>) */
uint8_t empty__q_1(struct arr_1 a) {
	return _equal_0(a.size, 0u);
}
/* subscript<arr<?a>> arr<char>(a arr<arr<char>>, index nat) */
struct arr_0 subscript_0(struct ctx* ctx, struct arr_1 a, uint64_t index) {
	uint8_t _0 = _less(index, a.size);
	assert(ctx, _0);
	return noctx_at_0(a, index);
}
/* assert void(condition bool) */
struct void_ assert(struct ctx* ctx, uint8_t condition) {
	uint8_t _0 = not(condition);
	if (_0) {
		return fail(ctx, (struct arr_0) {13, constantarr_0_4});
	} else {
		return (struct void_) {};
	}
}
/* fail<void> void(message arr<char>) */
struct void_ fail(struct ctx* ctx, struct arr_0 message) {
	struct backtrace _0 = get_backtrace(ctx);
	return throw(ctx, (struct exception) {message, _0});
}
/* throw<?a> void(e exception) */
struct void_ throw(struct ctx* ctx, struct exception e) {
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
	return (struct exception_ctx*) ctx->exception_ctx_ptr;
}
/* null?<jmp-buf-tag> bool(a ptr<jmp-buf-tag>) */
uint8_t null__q_1(struct jmp_buf_tag* a) {
	return _equal_0((uint64_t) a, (uint64_t) NULL);
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
			struct some_3 s0 = _0.as1;
			
			struct backtrace_arrs* arrs1;
			arrs1 = s0.value;
			
			uint64_t n_code_ptrs2;
			uint64_t _1 = code_ptrs_size(ctx);
			int32_t _2 = backtrace(arrs1->code_ptrs, (int32_t) (int64_t) _1);
			n_code_ptrs2 = (uint64_t) (int64_t) _2;
			
			uint64_t _3 = code_ptrs_size(ctx);
			uint8_t _4 = _lessOrEqual(n_code_ptrs2, _3);
			hard_assert(_4);
			fill_fun_ptrs_names_recur(0u, arrs1->fun_ptrs, arrs1->fun_names);
			uint64_t _5 = funs_count_81();
			sort_together(ctx, arrs1->fun_ptrs, arrs1->fun_names, _5);
			struct arr_0* end_code_names3;
			end_code_names3 = (arrs1->code_names + n_code_ptrs2);
			
			fill_code_names_recur(ctx, arrs1->code_names, end_code_names3, arrs1->code_ptrs, arrs1->fun_ptrs, arrs1->fun_names);
			return (struct backtrace) {(struct arr_1) {n_code_ptrs2, arrs1->code_names}};
		}
		default:
			return (struct backtrace) {(struct arr_1) {0, NULL}};
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
			struct some_4 code_ptrs0 = _0.as1;
			
			struct opt_6 _1 = try_alloc_uninitialized_1(ctx, 8u);
			switch (_1.kind) {
				case 0: {
					return (struct opt_3) {0, .as0 = (struct none) {}};
				}
				case 1: {
					struct some_6 code_names1 = _1.as1;
					
					uint64_t _2 = funs_count_81();
					struct opt_4 _3 = try_alloc_uninitialized_0(ctx, _2);
					switch (_3.kind) {
						case 0: {
							return (struct opt_3) {0, .as0 = (struct none) {}};
						}
						case 1: {
							struct some_4 fun_ptrs2 = _3.as1;
							
							uint64_t _4 = funs_count_81();
							struct opt_6 _5 = try_alloc_uninitialized_1(ctx, _4);
							switch (_5.kind) {
								case 0: {
									return (struct opt_3) {0, .as0 = (struct none) {}};
								}
								case 1: {
									struct some_6 fun_names3 = _5.as1;
									
									struct backtrace_arrs* temp0;
									uint8_t* _6 = alloc(ctx, sizeof(struct backtrace_arrs));
									temp0 = (struct backtrace_arrs*) _6;
									
									*temp0 = (struct backtrace_arrs) {code_ptrs0.value, code_names1.value, fun_ptrs2.value, fun_names3.value};
									return (struct opt_3) {1, .as1 = (struct some_3) {temp0}};
								}
								default:
									return (struct opt_3) {0};
							}
						}
						default:
							return (struct opt_3) {0};
					}
				}
				default:
					return (struct opt_3) {0};
			}
		}
		default:
			return (struct opt_3) {0};
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
			struct some_5 s0 = _0.as1;
			
			return (struct opt_4) {1, .as1 = (struct some_4) {(uint8_t**) s0.value}};
		}
		default:
			return (struct opt_4) {0};
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
		uint8_t _2 = _equal_0(n_tries, 10000u);
		if (_2) {
			return todo_0();
		} else {
			yield_thread();
			uint64_t _3 = noctx_incr(n_tries);
			a = a;
			n_tries = _3;
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
	
	uint8_t _0 = _equal_2(err0, 0);
	return hard_assert(_0);
}
/* ==<int32> bool(a int32, b int32) */
uint8_t _equal_2(int32_t a, int32_t b) {
	struct comparison _0 = compare_67(a, b);
	switch (_0.kind) {
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
			return 0;
	}
}
/* compare<int-32> (generated) (generated) */
struct comparison compare_67(int32_t a, int32_t b) {
	uint8_t _0 = (a < b);
	if (_0) {
		return (struct comparison) {0, .as0 = (struct less) {}};
	} else {
		uint8_t _1 = (b < a);
		if (_1) {
			return (struct comparison) {2, .as2 = (struct greater) {}};
		} else {
			return (struct comparison) {1, .as1 = (struct equal) {}};
		}
	}
}
/* noctx-incr nat(n nat) */
uint64_t noctx_incr(uint64_t n) {
	uint8_t _0 = _equal_0(n, 18446744073709551615u);
	hard_forbid(_0);
	return (n + 1u);
}
/* try-gc-alloc-recur opt<ptr<nat8>>(gc gc, size-bytes nat) */
struct opt_5 try_gc_alloc_recur(struct gc* gc, uint64_t size_bytes) {
	top:;
	validate_gc(gc);
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
			return (struct opt_5) {1, .as1 = (struct some_5) {(uint8_t*) cur1}};
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
	uint8_t _8 = _equal_0(_7, gc->size_words);
	hard_assert(_8);
	uint64_t _9 = _minus_0(gc->data_end, gc->data_begin);
	uint8_t _10 = _equal_0(_9, gc->size_words);
	hard_assert(_10);
	uint8_t _11 = _equal_0(mark_idx0, data_idx1);
	return hard_assert(_11);
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
	return (((uint64_t) a - (uint64_t) b) / sizeof(uint8_t));
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
	return (struct gc_ctx*) ctx->gc_ctx_ptr;
}
/* try-alloc-uninitialized<arr<char>> opt<ptr<arr<char>>>(size nat) */
struct opt_6 try_alloc_uninitialized_1(struct ctx* ctx, uint64_t size) {
	struct opt_5 _0 = try_alloc(ctx, (size * sizeof(struct arr_0)));
	switch (_0.kind) {
		case 0: {
			return (struct opt_6) {0, .as0 = (struct none) {}};
		}
		case 1: {
			struct some_5 s0 = _0.as1;
			
			return (struct opt_6) {1, .as1 = (struct some_6) {(struct arr_0*) s0.value}};
		}
		default:
			return (struct opt_6) {0};
	}
}
/* funs-count (generated) (generated) */
uint64_t funs_count_81(void) {
	return 385u;
}
/* code-ptrs-size nat() */
uint64_t code_ptrs_size(struct ctx* ctx) {
	return 8u;
}
/* fill-fun-ptrs-names-recur void(i nat, fun-ptrs ptr<ptr<nat8>>, fun-names ptr<arr<char>>) */
struct void_ fill_fun_ptrs_names_recur(uint64_t i, uint8_t** fun_ptrs, struct arr_0* fun_names) {
	top:;
	uint64_t _0 = funs_count_81();
	uint8_t _1 = _notEqual_1(i, _0);
	if (_1) {
		uint8_t* _2 = get_fun_ptr_87(i);
		set_subscript_0(fun_ptrs, i, _2);
		struct arr_0 _3 = get_fun_name_89(i);
		set_subscript_1(fun_names, i, _3);
		uint64_t _4 = noctx_incr(i);
		i = _4;
		fun_ptrs = fun_ptrs;
		fun_names = fun_names;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* !=<nat> bool(a nat, b nat) */
uint8_t _notEqual_1(uint64_t a, uint64_t b) {
	uint8_t _0 = _equal_0(a, b);
	return not(_0);
}
/* set-subscript<ptr<nat8>> void(a ptr<ptr<nat8>>, n nat, value ptr<nat8>) */
struct void_ set_subscript_0(uint8_t** a, uint64_t n, uint8_t* value) {
	return (*(a + n) = value, (struct void_) {});
}
/* get-fun-ptr (generated) (generated) */
uint8_t* get_fun_ptr_87(uint64_t fun_id) {switch (fun_id) {
		case 0: {
			return (uint8_t*) mark;
		}
		case 1: {
			return (uint8_t*) hard_assert;
		}
		case 2: {
			return (uint8_t*) abort;
		}
		case 3: {
			return (uint8_t*) word_aligned__q;
		}
		case 4: {
			return (uint8_t*) _equal_0;
		}
		case 5: {
			return (uint8_t*) compare_5;
		}
		case 6: {
			return (uint8_t*) words_of_bytes;
		}
		case 7: {
			return (uint8_t*) round_up_to_multiple_of_8;
		}
		case 8: {
			return (uint8_t*) _minus_0;
		}
		case 9: {
			return (uint8_t*) _less;
		}
		case 10: {
			return (uint8_t*) _lessOrEqual;
		}
		case 11: {
			return (uint8_t*) not;
		}
		case 12: {
			return (uint8_t*) mark_range_recur;
		}
		case 13: {
			return (uint8_t*) _greater;
		}
		case 14: {
			return (uint8_t*) rt_main;
		}
		case 15: {
			return (uint8_t*) get_nprocs;
		}
		case 16: {
			return (uint8_t*) lock_by_val;
		}
		case 17: {
			return (uint8_t*) _atomic_bool;
		}
		case 18: {
			return (uint8_t*) condition;
		}
		case 19: {
			return (uint8_t*) island;
		}
		case 20: {
			return (uint8_t*) task_queue;
		}
		case 21: {
			return (uint8_t*) mut_list_by_val_with_capacity_from_unmanaged_memory;
		}
		case 22: {
			return (uint8_t*) mut_arr_0;
		}
		case 23: {
			return (uint8_t*) unmanaged_alloc_zeroed_elements;
		}
		case 24: {
			return (uint8_t*) unmanaged_alloc_elements_0;
		}
		case 25: {
			return (uint8_t*) unmanaged_alloc_bytes;
		}
		case 26: {
			return (uint8_t*) malloc;
		}
		case 27: {
			return (uint8_t*) hard_forbid;
		}
		case 28: {
			return (uint8_t*) null__q_0;
		}
		case 29: {
			return (uint8_t*) set_zero_range_0;
		}
		case 30: {
			return (uint8_t*) memset;
		}
		case 31: {
			return (uint8_t*) default_exception_handler;
		}
		case 32: {
			return (uint8_t*) print_err_no_newline;
		}
		case 33: {
			return (uint8_t*) write_no_newline;
		}
		case 34: {
			return (uint8_t*) write;
		}
		case 35: {
			return (uint8_t*) _notEqual_0;
		}
		case 36: {
			return (uint8_t*) _equal_1;
		}
		case 37: {
			return (uint8_t*) compare_37;
		}
		case 38: {
			return (uint8_t*) todo_0;
		}
		case 39: {
			return (uint8_t*) stderr;
		}
		case 40: {
			return (uint8_t*) print_err;
		}
		case 41: {
			return (uint8_t*) show_exception;
		}
		case 42: {
			return (uint8_t*) empty__q_0;
		}
		case 43: {
			return (uint8_t*) flatten;
		}
		case 44: {
			return (uint8_t*) empty__q_1;
		}
		case 45: {
			return (uint8_t*) subscript_0;
		}
		case 46: {
			return (uint8_t*) assert;
		}
		case 47: {
			return (uint8_t*) fail;
		}
		case 48: {
			return (uint8_t*) throw;
		}
		case 49: {
			return (uint8_t*) get_exception_ctx;
		}
		case 50: {
			return (uint8_t*) null__q_1;
		}
		case 51: {
			return (uint8_t*) longjmp;
		}
		case 52: {
			return (uint8_t*) number_to_throw;
		}
		case 53: {
			return (uint8_t*) hard_unreachable_0;
		}
		case 54: {
			return (uint8_t*) get_backtrace;
		}
		case 55: {
			return (uint8_t*) try_alloc_backtrace_arrs;
		}
		case 56: {
			return (uint8_t*) try_alloc_uninitialized_0;
		}
		case 57: {
			return (uint8_t*) try_alloc;
		}
		case 58: {
			return (uint8_t*) try_gc_alloc;
		}
		case 59: {
			return (uint8_t*) acquire__e;
		}
		case 60: {
			return (uint8_t*) acquire_recur__e;
		}
		case 61: {
			return (uint8_t*) try_acquire__e;
		}
		case 62: {
			return (uint8_t*) try_set__e;
		}
		case 63: {
			return (uint8_t*) try_change__e;
		}
		case 64: {
			return (uint8_t*) yield_thread;
		}
		case 65: {
			return (uint8_t*) pthread_yield;
		}
		case 66: {
			return (uint8_t*) _equal_2;
		}
		case 67: {
			return (uint8_t*) compare_67;
		}
		case 68: {
			return (uint8_t*) noctx_incr;
		}
		case 69: {
			return (uint8_t*) try_gc_alloc_recur;
		}
		case 70: {
			return (uint8_t*) validate_gc;
		}
		case 71: {
			return (uint8_t*) ptr_less_eq__q_0;
		}
		case 72: {
			return (uint8_t*) ptr_less_eq__q_1;
		}
		case 73: {
			return (uint8_t*) _minus_1;
		}
		case 74: {
			return (uint8_t*) range_free__q;
		}
		case 75: {
			return (uint8_t*) release__e;
		}
		case 76: {
			return (uint8_t*) must_unset__e;
		}
		case 77: {
			return (uint8_t*) try_unset__e;
		}
		case 78: {
			return (uint8_t*) get_gc;
		}
		case 79: {
			return (uint8_t*) get_gc_ctx_0;
		}
		case 80: {
			return (uint8_t*) try_alloc_uninitialized_1;
		}
		case 81: {
			return (uint8_t*) funs_count_81;
		}
		case 82: {
			return (uint8_t*) backtrace;
		}
		case 83: {
			return (uint8_t*) code_ptrs_size;
		}
		case 84: {
			return (uint8_t*) fill_fun_ptrs_names_recur;
		}
		case 85: {
			return (uint8_t*) _notEqual_1;
		}
		case 86: {
			return (uint8_t*) set_subscript_0;
		}
		case 87: {
			return (uint8_t*) get_fun_ptr_87;
		}
		case 88: {
			return (uint8_t*) set_subscript_1;
		}
		case 89: {
			return (uint8_t*) get_fun_name_89;
		}
		case 90: {
			return (uint8_t*) sort_together;
		}
		case 91: {
			return (uint8_t*) swap_0;
		}
		case 92: {
			return (uint8_t*) subscript_1;
		}
		case 93: {
			return (uint8_t*) swap_1;
		}
		case 94: {
			return (uint8_t*) subscript_2;
		}
		case 95: {
			return (uint8_t*) partition_recur_together;
		}
		case 96: {
			return (uint8_t*) noctx_decr;
		}
		case 97: {
			return (uint8_t*) fill_code_names_recur;
		}
		case 98: {
			return (uint8_t*) get_fun_name;
		}
		case 99: {
			return (uint8_t*) noctx_at_0;
		}
		case 100: {
			return (uint8_t*) _concat;
		}
		case 101: {
			return (uint8_t*) _plus;
		}
		case 102: {
			return (uint8_t*) _greaterOrEqual;
		}
		case 103: {
			return (uint8_t*) alloc_uninitialized_0;
		}
		case 104: {
			return (uint8_t*) alloc;
		}
		case 105: {
			return (uint8_t*) gc_alloc;
		}
		case 106: {
			return (uint8_t*) todo_1;
		}
		case 107: {
			return (uint8_t*) copy_data_from;
		}
		case 108: {
			return (uint8_t*) memcpy;
		}
		case 109: {
			return (uint8_t*) tail_0;
		}
		case 110: {
			return (uint8_t*) forbid_0;
		}
		case 111: {
			return (uint8_t*) forbid_1;
		}
		case 112: {
			return (uint8_t*) subscript_3;
		}
		case 113: {
			return (uint8_t*) _minus_2;
		}
		case 114: {
			return (uint8_t*) _arrow;
		}
		case 115: {
			return (uint8_t*) finish;
		}
		case 116: {
			return (uint8_t*) move_to_arr__e;
		}
		case 117: {
			return (uint8_t*) begin_ptr_0;
		}
		case 118: {
			return (uint8_t*) begin_ptr_1;
		}
		case 119: {
			return (uint8_t*) mut_arr_1;
		}
		case 120: {
			return (uint8_t*) to_str_0;
		}
		case 121: {
			return (uint8_t*) with_value_0;
		}
		case 122: {
			return (uint8_t*) with_str;
		}
		case 123: {
			return (uint8_t*) _concatEquals_0;
		}
		case 124: {
			return (uint8_t*) each;
		}
		case 125: {
			return (uint8_t*) each_recur;
		}
		case 126: {
			return (uint8_t*) subscript_4;
		}
		case 127: {
			return (uint8_t*) call_w_ctx_127;
		}
		case 128: {
			return (uint8_t*) end_ptr;
		}
		case 129: {
			return (uint8_t*) _concatEquals_1;
		}
		case 130: {
			return (uint8_t*) incr_capacity__e;
		}
		case 131: {
			return (uint8_t*) ensure_capacity;
		}
		case 132: {
			return (uint8_t*) capacity_0;
		}
		case 133: {
			return (uint8_t*) size_0;
		}
		case 134: {
			return (uint8_t*) increase_capacity_to__e;
		}
		case 135: {
			return (uint8_t*) uninitialized_mut_arr;
		}
		case 136: {
			return (uint8_t*) mut_arr_2;
		}
		case 137: {
			return (uint8_t*) set_zero_elements;
		}
		case 138: {
			return (uint8_t*) set_zero_range_1;
		}
		case 139: {
			return (uint8_t*) subscript_5;
		}
		case 140: {
			return (uint8_t*) subscript_6;
		}
		case 141: {
			return (uint8_t*) round_up_to_power_of_two;
		}
		case 142: {
			return (uint8_t*) round_up_to_power_of_two_recur;
		}
		case 143: {
			return (uint8_t*) _times;
		}
		case 144: {
			return (uint8_t*) _divide;
		}
		case 145: {
			return (uint8_t*) set_subscript_2;
		}
		case 146: {
			return (uint8_t*) _concatEquals_0__lambda0;
		}
		case 147: {
			return (uint8_t*) interp;
		}
		case 148: {
			return (uint8_t*) mut_list;
		}
		case 149: {
			return (uint8_t*) get_global_ctx;
		}
		case 150: {
			return (uint8_t*) island__lambda0;
		}
		case 151: {
			return (uint8_t*) default_log_handler;
		}
		case 152: {
			return (uint8_t*) print;
		}
		case 153: {
			return (uint8_t*) print_no_newline;
		}
		case 154: {
			return (uint8_t*) stdout;
		}
		case 155: {
			return (uint8_t*) to_str_1;
		}
		case 156: {
			return (uint8_t*) with_value_1;
		}
		case 157: {
			return (uint8_t*) island__lambda1;
		}
		case 158: {
			return (uint8_t*) gc;
		}
		case 159: {
			return (uint8_t*) thread_safe_counter_0;
		}
		case 160: {
			return (uint8_t*) thread_safe_counter_1;
		}
		case 161: {
			return (uint8_t*) do_main;
		}
		case 162: {
			return (uint8_t*) exception_ctx;
		}
		case 163: {
			return (uint8_t*) log_ctx;
		}
		case 164: {
			return (uint8_t*) ctx;
		}
		case 165: {
			return (uint8_t*) get_gc_ctx_1;
		}
		case 166: {
			return (uint8_t*) add_first_task;
		}
		case 167: {
			return (uint8_t*) then_void;
		}
		case 168: {
			return (uint8_t*) then;
		}
		case 169: {
			return (uint8_t*) unresolved;
		}
		case 170: {
			return (uint8_t*) callback__e_0;
		}
		case 171: {
			return (uint8_t*) with_lock_0;
		}
		case 172: {
			return (uint8_t*) subscript_7;
		}
		case 173: {
			return (uint8_t*) call_w_ctx_173;
		}
		case 174: {
			return (uint8_t*) subscript_8;
		}
		case 175: {
			return (uint8_t*) call_w_ctx_175;
		}
		case 176: {
			return (uint8_t*) callback__e_0__lambda0;
		}
		case 177: {
			return (uint8_t*) forward_to__e;
		}
		case 178: {
			return (uint8_t*) callback__e_1;
		}
		case 179: {
			return (uint8_t*) subscript_9;
		}
		case 180: {
			return (uint8_t*) call_w_ctx_180;
		}
		case 181: {
			return (uint8_t*) callback__e_1__lambda0;
		}
		case 182: {
			return (uint8_t*) resolve_or_reject__e;
		}
		case 183: {
			return (uint8_t*) with_lock_1;
		}
		case 184: {
			return (uint8_t*) subscript_10;
		}
		case 185: {
			return (uint8_t*) call_w_ctx_185;
		}
		case 186: {
			return (uint8_t*) resolve_or_reject__e__lambda0;
		}
		case 187: {
			return (uint8_t*) call_callbacks__e;
		}
		case 188: {
			return (uint8_t*) forward_to__e__lambda0;
		}
		case 189: {
			return (uint8_t*) subscript_11;
		}
		case 190: {
			return (uint8_t*) get_island;
		}
		case 191: {
			return (uint8_t*) subscript_12;
		}
		case 192: {
			return (uint8_t*) noctx_at_1;
		}
		case 193: {
			return (uint8_t*) subscript_13;
		}
		case 194: {
			return (uint8_t*) add_task_0;
		}
		case 195: {
			return (uint8_t*) add_task_1;
		}
		case 196: {
			return (uint8_t*) task_queue_node;
		}
		case 197: {
			return (uint8_t*) insert_task__e;
		}
		case 198: {
			return (uint8_t*) size_1;
		}
		case 199: {
			return (uint8_t*) size_recur;
		}
		case 200: {
			return (uint8_t*) insert_recur;
		}
		case 201: {
			return (uint8_t*) tasks;
		}
		case 202: {
			return (uint8_t*) broadcast__e;
		}
		case 203: {
			return (uint8_t*) no_timestamp;
		}
		case 204: {
			return (uint8_t*) catch;
		}
		case 205: {
			return (uint8_t*) catch_with_exception_ctx;
		}
		case 206: {
			return (uint8_t*) zero_0;
		}
		case 207: {
			return (uint8_t*) zero_1;
		}
		case 208: {
			return (uint8_t*) zero_2;
		}
		case 209: {
			return (uint8_t*) zero_3;
		}
		case 210: {
			return (uint8_t*) setjmp;
		}
		case 211: {
			return (uint8_t*) subscript_14;
		}
		case 212: {
			return (uint8_t*) call_w_ctx_212;
		}
		case 213: {
			return (uint8_t*) subscript_15;
		}
		case 214: {
			return (uint8_t*) call_w_ctx_214;
		}
		case 215: {
			return (uint8_t*) subscript_11__lambda0__lambda0;
		}
		case 216: {
			return (uint8_t*) reject__e;
		}
		case 217: {
			return (uint8_t*) subscript_11__lambda0__lambda1;
		}
		case 218: {
			return (uint8_t*) subscript_11__lambda0;
		}
		case 219: {
			return (uint8_t*) then__lambda0;
		}
		case 220: {
			return (uint8_t*) subscript_16;
		}
		case 221: {
			return (uint8_t*) subscript_17;
		}
		case 222: {
			return (uint8_t*) call_w_ctx_222;
		}
		case 223: {
			return (uint8_t*) subscript_16__lambda0__lambda0;
		}
		case 224: {
			return (uint8_t*) subscript_16__lambda0__lambda1;
		}
		case 225: {
			return (uint8_t*) subscript_16__lambda0;
		}
		case 226: {
			return (uint8_t*) then_void__lambda0;
		}
		case 227: {
			return (uint8_t*) cur_island_and_exclusion;
		}
		case 228: {
			return (uint8_t*) delay;
		}
		case 229: {
			return (uint8_t*) resolved_0;
		}
		case 230: {
			return (uint8_t*) tail_1;
		}
		case 231: {
			return (uint8_t*) empty__q_2;
		}
		case 232: {
			return (uint8_t*) subscript_18;
		}
		case 233: {
			return (uint8_t*) map;
		}
		case 234: {
			return (uint8_t*) make_arr;
		}
		case 235: {
			return (uint8_t*) alloc_uninitialized_1;
		}
		case 236: {
			return (uint8_t*) fill_ptr_range;
		}
		case 237: {
			return (uint8_t*) fill_ptr_range_recur;
		}
		case 238: {
			return (uint8_t*) subscript_19;
		}
		case 239: {
			return (uint8_t*) call_w_ctx_239;
		}
		case 240: {
			return (uint8_t*) subscript_20;
		}
		case 241: {
			return (uint8_t*) call_w_ctx_241;
		}
		case 242: {
			return (uint8_t*) subscript_21;
		}
		case 243: {
			return (uint8_t*) noctx_at_2;
		}
		case 244: {
			return (uint8_t*) subscript_22;
		}
		case 245: {
			return (uint8_t*) map__lambda0;
		}
		case 246: {
			return (uint8_t*) to_str_2;
		}
		case 247: {
			return (uint8_t*) arr_from_begin_end;
		}
		case 248: {
			return (uint8_t*) ptr_less_eq__q_2;
		}
		case 249: {
			return (uint8_t*) _minus_3;
		}
		case 250: {
			return (uint8_t*) find_cstr_end;
		}
		case 251: {
			return (uint8_t*) find_char_in_cstr;
		}
		case 252: {
			return (uint8_t*) _equal_3;
		}
		case 253: {
			return (uint8_t*) compare_253;
		}
		case 254: {
			return (uint8_t*) hard_unreachable_1;
		}
		case 255: {
			return (uint8_t*) add_first_task__lambda0__lambda0;
		}
		case 256: {
			return (uint8_t*) add_first_task__lambda0;
		}
		case 257: {
			return (uint8_t*) handle_exceptions;
		}
		case 258: {
			return (uint8_t*) subscript_23;
		}
		case 259: {
			return (uint8_t*) call_w_ctx_259;
		}
		case 260: {
			return (uint8_t*) exception_handler;
		}
		case 261: {
			return (uint8_t*) get_cur_island;
		}
		case 262: {
			return (uint8_t*) handle_exceptions__lambda0;
		}
		case 263: {
			return (uint8_t*) do_main__lambda0;
		}
		case 264: {
			return (uint8_t*) call_w_ctx_264;
		}
		case 265: {
			return (uint8_t*) run_threads;
		}
		case 266: {
			return (uint8_t*) unmanaged_alloc_elements_1;
		}
		case 267: {
			return (uint8_t*) start_threads_recur;
		}
		case 268: {
			return (uint8_t*) create_one_thread;
		}
		case 269: {
			return (uint8_t*) pthread_create;
		}
		case 270: {
			return (uint8_t*) _notEqual_2;
		}
		case 271: {
			return (uint8_t*) eagain;
		}
		case 272: {
			return (uint8_t*) as_cell;
		}
		case 273: {
			return (uint8_t*) thread_fun;
		}
		case 274: {
			return (uint8_t*) thread_function;
		}
		case 275: {
			return (uint8_t*) thread_function_recur;
		}
		case 276: {
			return (uint8_t*) assert_islands_are_shut_down;
		}
		case 277: {
			return (uint8_t*) empty__q_3;
		}
		case 278: {
			return (uint8_t*) get_last_checked;
		}
		case 279: {
			return (uint8_t*) choose_task;
		}
		case 280: {
			return (uint8_t*) get_monotime_nsec;
		}
		case 281: {
			return (uint8_t*) clock_gettime;
		}
		case 282: {
			return (uint8_t*) clock_monotonic;
		}
		case 283: {
			return (uint8_t*) todo_2;
		}
		case 284: {
			return (uint8_t*) choose_task_recur;
		}
		case 285: {
			return (uint8_t*) choose_task_in_island;
		}
		case 286: {
			return (uint8_t*) pop_task__e;
		}
		case 287: {
			return (uint8_t*) contains__q_0;
		}
		case 288: {
			return (uint8_t*) contains__q_1;
		}
		case 289: {
			return (uint8_t*) contains_recur__q;
		}
		case 290: {
			return (uint8_t*) noctx_at_3;
		}
		case 291: {
			return (uint8_t*) subscript_24;
		}
		case 292: {
			return (uint8_t*) temp_as_arr_0;
		}
		case 293: {
			return (uint8_t*) temp_as_arr_1;
		}
		case 294: {
			return (uint8_t*) temp_as_mut_arr;
		}
		case 295: {
			return (uint8_t*) begin_ptr_2;
		}
		case 296: {
			return (uint8_t*) begin_ptr_3;
		}
		case 297: {
			return (uint8_t*) pop_recur__e;
		}
		case 298: {
			return (uint8_t*) to_opt_time;
		}
		case 299: {
			return (uint8_t*) push_capacity_must_be_sufficient__e;
		}
		case 300: {
			return (uint8_t*) capacity_1;
		}
		case 301: {
			return (uint8_t*) size_2;
		}
		case 302: {
			return (uint8_t*) set_subscript_3;
		}
		case 303: {
			return (uint8_t*) is_no_task__q;
		}
		case 304: {
			return (uint8_t*) min_time;
		}
		case 305: {
			return (uint8_t*) min;
		}
		case 306: {
			return (uint8_t*) do_task;
		}
		case 307: {
			return (uint8_t*) return_task__e;
		}
		case 308: {
			return (uint8_t*) noctx_must_remove_unordered__e;
		}
		case 309: {
			return (uint8_t*) noctx_must_remove_unordered_recur__e;
		}
		case 310: {
			return (uint8_t*) drop;
		}
		case 311: {
			return (uint8_t*) noctx_remove_unordered_at__e;
		}
		case 312: {
			return (uint8_t*) return_ctx;
		}
		case 313: {
			return (uint8_t*) return_gc_ctx;
		}
		case 314: {
			return (uint8_t*) run_garbage_collection;
		}
		case 315: {
			return (uint8_t*) mark_visit_315;
		}
		case 316: {
			return (uint8_t*) mark_visit_316;
		}
		case 317: {
			return (uint8_t*) mark_visit_317;
		}
		case 318: {
			return (uint8_t*) mark_visit_318;
		}
		case 319: {
			return (uint8_t*) mark_visit_319;
		}
		case 320: {
			return (uint8_t*) mark_visit_320;
		}
		case 321: {
			return (uint8_t*) mark_visit_321;
		}
		case 322: {
			return (uint8_t*) mark_visit_322;
		}
		case 323: {
			return (uint8_t*) mark_visit_323;
		}
		case 324: {
			return (uint8_t*) mark_visit_324;
		}
		case 325: {
			return (uint8_t*) mark_visit_325;
		}
		case 326: {
			return (uint8_t*) mark_visit_326;
		}
		case 327: {
			return (uint8_t*) mark_visit_327;
		}
		case 328: {
			return (uint8_t*) mark_visit_328;
		}
		case 329: {
			return (uint8_t*) mark_visit_329;
		}
		case 330: {
			return (uint8_t*) mark_visit_330;
		}
		case 331: {
			return (uint8_t*) mark_visit_331;
		}
		case 332: {
			return (uint8_t*) mark_visit_332;
		}
		case 333: {
			return (uint8_t*) mark_visit_333;
		}
		case 334: {
			return (uint8_t*) mark_arr_334;
		}
		case 335: {
			return (uint8_t*) mark_visit_335;
		}
		case 336: {
			return (uint8_t*) mark_visit_336;
		}
		case 337: {
			return (uint8_t*) mark_visit_337;
		}
		case 338: {
			return (uint8_t*) mark_visit_338;
		}
		case 339: {
			return (uint8_t*) mark_visit_339;
		}
		case 340: {
			return (uint8_t*) mark_visit_340;
		}
		case 341: {
			return (uint8_t*) mark_visit_341;
		}
		case 342: {
			return (uint8_t*) mark_visit_342;
		}
		case 343: {
			return (uint8_t*) mark_visit_343;
		}
		case 344: {
			return (uint8_t*) mark_visit_344;
		}
		case 345: {
			return (uint8_t*) mark_visit_345;
		}
		case 346: {
			return (uint8_t*) mark_visit_346;
		}
		case 347: {
			return (uint8_t*) mark_visit_347;
		}
		case 348: {
			return (uint8_t*) mark_arr_348;
		}
		case 349: {
			return (uint8_t*) mark_visit_349;
		}
		case 350: {
			return (uint8_t*) mark_elems_350;
		}
		case 351: {
			return (uint8_t*) mark_arr_351;
		}
		case 352: {
			return (uint8_t*) mark_visit_352;
		}
		case 353: {
			return (uint8_t*) mark_visit_353;
		}
		case 354: {
			return (uint8_t*) mark_visit_354;
		}
		case 355: {
			return (uint8_t*) mark_visit_355;
		}
		case 356: {
			return (uint8_t*) mark_visit_356;
		}
		case 357: {
			return (uint8_t*) mark_visit_357;
		}
		case 358: {
			return (uint8_t*) mark_visit_358;
		}
		case 359: {
			return (uint8_t*) mark_visit_359;
		}
		case 360: {
			return (uint8_t*) mark_visit_360;
		}
		case 361: {
			return (uint8_t*) mark_visit_361;
		}
		case 362: {
			return (uint8_t*) mark_visit_362;
		}
		case 363: {
			return (uint8_t*) mark_visit_363;
		}
		case 364: {
			return (uint8_t*) mark_visit_364;
		}
		case 365: {
			return (uint8_t*) mark_visit_365;
		}
		case 366: {
			return (uint8_t*) mark_visit_366;
		}
		case 367: {
			return (uint8_t*) mark_visit_367;
		}
		case 368: {
			return (uint8_t*) mark_visit_368;
		}
		case 369: {
			return (uint8_t*) mark_visit_369;
		}
		case 370: {
			return (uint8_t*) mark_visit_370;
		}
		case 371: {
			return (uint8_t*) mark_arr_371;
		}
		case 372: {
			return (uint8_t*) clear_free_mem;
		}
		case 373: {
			return (uint8_t*) wait_on;
		}
		case 374: {
			return (uint8_t*) before_time__q;
		}
		case 375: {
			return (uint8_t*) join_threads_recur;
		}
		case 376: {
			return (uint8_t*) join_one_thread;
		}
		case 377: {
			return (uint8_t*) pthread_join;
		}
		case 378: {
			return (uint8_t*) einval;
		}
		case 379: {
			return (uint8_t*) esrch;
		}
		case 380: {
			return (uint8_t*) unmanaged_free_0;
		}
		case 381: {
			return (uint8_t*) free;
		}
		case 382: {
			return (uint8_t*) unmanaged_free_1;
		}
		case 383: {
			return (uint8_t*) main_0;
		}
		case 384: {
			return (uint8_t*) resolved_1;
		}
		default:
			return NULL;
	}
}
/* set-subscript<arr<char>> void(a ptr<arr<char>>, n nat, value arr<char>) */
struct void_ set_subscript_1(struct arr_0* a, uint64_t n, struct arr_0 value) {
	return (*(a + n) = value, (struct void_) {});
}
/* get-fun-name (generated) (generated) */
struct arr_0 get_fun_name_89(uint64_t fun_id) {switch (fun_id) {
		case 0: {
			return (struct arr_0) {4, constantarr_0_11};
		}
		case 1: {
			return (struct arr_0) {11, constantarr_0_12};
		}
		case 2: {
			return (struct arr_0) {6, constantarr_0_14};
		}
		case 3: {
			return (struct arr_0) {13, constantarr_0_15};
		}
		case 4: {
			return (struct arr_0) {7, constantarr_0_16};
		}
		case 5: {
			return (struct arr_0) {0u, NULL};
		}
		case 6: {
			return (struct arr_0) {14, constantarr_0_22};
		}
		case 7: {
			return (struct arr_0) {25, constantarr_0_24};
		}
		case 8: {
			return (struct arr_0) {6, constantarr_0_28};
		}
		case 9: {
			return (struct arr_0) {6, constantarr_0_33};
		}
		case 10: {
			return (struct arr_0) {7, constantarr_0_35};
		}
		case 11: {
			return (struct arr_0) {3, constantarr_0_36};
		}
		case 12: {
			return (struct arr_0) {16, constantarr_0_39};
		}
		case 13: {
			return (struct arr_0) {6, constantarr_0_44};
		}
		case 14: {
			return (struct arr_0) {7, constantarr_0_45};
		}
		case 15: {
			return (struct arr_0) {10, constantarr_0_46};
		}
		case 16: {
			return (struct arr_0) {11, constantarr_0_49};
		}
		case 17: {
			return (struct arr_0) {11, constantarr_0_51};
		}
		case 18: {
			return (struct arr_0) {9, constantarr_0_52};
		}
		case 19: {
			return (struct arr_0) {6, constantarr_0_54};
		}
		case 20: {
			return (struct arr_0) {10, constantarr_0_55};
		}
		case 21: {
			return (struct arr_0) {56, constantarr_0_57};
		}
		case 22: {
			return (struct arr_0) {11, constantarr_0_58};
		}
		case 23: {
			return (struct arr_0) {35, constantarr_0_60};
		}
		case 24: {
			return (struct arr_0) {28, constantarr_0_61};
		}
		case 25: {
			return (struct arr_0) {21, constantarr_0_62};
		}
		case 26: {
			return (struct arr_0) {6, constantarr_0_63};
		}
		case 27: {
			return (struct arr_0) {11, constantarr_0_64};
		}
		case 28: {
			return (struct arr_0) {11, constantarr_0_65};
		}
		case 29: {
			return (struct arr_0) {18, constantarr_0_68};
		}
		case 30: {
			return (struct arr_0) {6, constantarr_0_69};
		}
		case 31: {
			return (struct arr_0) {25, constantarr_0_74};
		}
		case 32: {
			return (struct arr_0) {20, constantarr_0_75};
		}
		case 33: {
			return (struct arr_0) {16, constantarr_0_76};
		}
		case 34: {
			return (struct arr_0) {5, constantarr_0_79};
		}
		case 35: {
			return (struct arr_0) {7, constantarr_0_83};
		}
		case 36: {
			return (struct arr_0) {6, constantarr_0_84};
		}
		case 37: {
			return (struct arr_0) {0u, NULL};
		}
		case 38: {
			return (struct arr_0) {10, constantarr_0_86};
		}
		case 39: {
			return (struct arr_0) {6, constantarr_0_88};
		}
		case 40: {
			return (struct arr_0) {9, constantarr_0_89};
		}
		case 41: {
			return (struct arr_0) {14, constantarr_0_90};
		}
		case 42: {
			return (struct arr_0) {12, constantarr_0_92};
		}
		case 43: {
			return (struct arr_0) {13, constantarr_0_94};
		}
		case 44: {
			return (struct arr_0) {15, constantarr_0_95};
		}
		case 45: {
			return (struct arr_0) {18, constantarr_0_97};
		}
		case 46: {
			return (struct arr_0) {6, constantarr_0_98};
		}
		case 47: {
			return (struct arr_0) {10, constantarr_0_99};
		}
		case 48: {
			return (struct arr_0) {9, constantarr_0_100};
		}
		case 49: {
			return (struct arr_0) {17, constantarr_0_101};
		}
		case 50: {
			return (struct arr_0) {18, constantarr_0_105};
		}
		case 51: {
			return (struct arr_0) {7, constantarr_0_108};
		}
		case 52: {
			return (struct arr_0) {15, constantarr_0_109};
		}
		case 53: {
			return (struct arr_0) {20, constantarr_0_110};
		}
		case 54: {
			return (struct arr_0) {13, constantarr_0_112};
		}
		case 55: {
			return (struct arr_0) {24, constantarr_0_113};
		}
		case 56: {
			return (struct arr_0) {34, constantarr_0_114};
		}
		case 57: {
			return (struct arr_0) {9, constantarr_0_115};
		}
		case 58: {
			return (struct arr_0) {12, constantarr_0_116};
		}
		case 59: {
			return (struct arr_0) {8, constantarr_0_117};
		}
		case 60: {
			return (struct arr_0) {14, constantarr_0_118};
		}
		case 61: {
			return (struct arr_0) {12, constantarr_0_119};
		}
		case 62: {
			return (struct arr_0) {8, constantarr_0_120};
		}
		case 63: {
			return (struct arr_0) {11, constantarr_0_121};
		}
		case 64: {
			return (struct arr_0) {12, constantarr_0_127};
		}
		case 65: {
			return (struct arr_0) {13, constantarr_0_128};
		}
		case 66: {
			return (struct arr_0) {9, constantarr_0_129};
		}
		case 67: {
			return (struct arr_0) {0u, NULL};
		}
		case 68: {
			return (struct arr_0) {10, constantarr_0_130};
		}
		case 69: {
			return (struct arr_0) {18, constantarr_0_133};
		}
		case 70: {
			return (struct arr_0) {11, constantarr_0_134};
		}
		case 71: {
			return (struct arr_0) {18, constantarr_0_139};
		}
		case 72: {
			return (struct arr_0) {17, constantarr_0_143};
		}
		case 73: {
			return (struct arr_0) {7, constantarr_0_146};
		}
		case 74: {
			return (struct arr_0) {11, constantarr_0_149};
		}
		case 75: {
			return (struct arr_0) {8, constantarr_0_154};
		}
		case 76: {
			return (struct arr_0) {11, constantarr_0_155};
		}
		case 77: {
			return (struct arr_0) {10, constantarr_0_156};
		}
		case 78: {
			return (struct arr_0) {6, constantarr_0_157};
		}
		case 79: {
			return (struct arr_0) {10, constantarr_0_159};
		}
		case 80: {
			return (struct arr_0) {34, constantarr_0_165};
		}
		case 81: {
			return (struct arr_0) {0u, NULL};
		}
		case 82: {
			return (struct arr_0) {9, constantarr_0_171};
		}
		case 83: {
			return (struct arr_0) {14, constantarr_0_178};
		}
		case 84: {
			return (struct arr_0) {25, constantarr_0_179};
		}
		case 85: {
			return (struct arr_0) {7, constantarr_0_180};
		}
		case 86: {
			return (struct arr_0) {24, constantarr_0_181};
		}
		case 87: {
			return (struct arr_0) {0u, NULL};
		}
		case 88: {
			return (struct arr_0) {24, constantarr_0_185};
		}
		case 89: {
			return (struct arr_0) {0u, NULL};
		}
		case 90: {
			return (struct arr_0) {13, constantarr_0_189};
		}
		case 91: {
			return (struct arr_0) {15, constantarr_0_190};
		}
		case 92: {
			return (struct arr_0) {13, constantarr_0_191};
		}
		case 93: {
			return (struct arr_0) {15, constantarr_0_192};
		}
		case 94: {
			return (struct arr_0) {13, constantarr_0_191};
		}
		case 95: {
			return (struct arr_0) {24, constantarr_0_193};
		}
		case 96: {
			return (struct arr_0) {10, constantarr_0_195};
		}
		case 97: {
			return (struct arr_0) {21, constantarr_0_197};
		}
		case 98: {
			return (struct arr_0) {12, constantarr_0_186};
		}
		case 99: {
			return (struct arr_0) {12, constantarr_0_200};
		}
		case 100: {
			return (struct arr_0) {5, constantarr_0_202};
		}
		case 101: {
			return (struct arr_0) {1, constantarr_0_203};
		}
		case 102: {
			return (struct arr_0) {7, constantarr_0_205};
		}
		case 103: {
			return (struct arr_0) {23, constantarr_0_206};
		}
		case 104: {
			return (struct arr_0) {5, constantarr_0_207};
		}
		case 105: {
			return (struct arr_0) {8, constantarr_0_208};
		}
		case 106: {
			return (struct arr_0) {15, constantarr_0_209};
		}
		case 107: {
			return (struct arr_0) {18, constantarr_0_210};
		}
		case 108: {
			return (struct arr_0) {6, constantarr_0_211};
		}
		case 109: {
			return (struct arr_0) {13, constantarr_0_212};
		}
		case 110: {
			return (struct arr_0) {6, constantarr_0_213};
		}
		case 111: {
			return (struct arr_0) {6, constantarr_0_213};
		}
		case 112: {
			return (struct arr_0) {13, constantarr_0_191};
		}
		case 113: {
			return (struct arr_0) {1, constantarr_0_216};
		}
		case 114: {
			return (struct arr_0) {12, constantarr_0_217};
		}
		case 115: {
			return (struct arr_0) {6, constantarr_0_220};
		}
		case 116: {
			return (struct arr_0) {18, constantarr_0_221};
		}
		case 117: {
			return (struct arr_0) {13, constantarr_0_201};
		}
		case 118: {
			return (struct arr_0) {13, constantarr_0_201};
		}
		case 119: {
			return (struct arr_0) {11, constantarr_0_58};
		}
		case 120: {
			return (struct arr_0) {6, constantarr_0_227};
		}
		case 121: {
			return (struct arr_0) {21, constantarr_0_228};
		}
		case 122: {
			return (struct arr_0) {8, constantarr_0_229};
		}
		case 123: {
			return (struct arr_0) {8, constantarr_0_230};
		}
		case 124: {
			return (struct arr_0) {8, constantarr_0_231};
		}
		case 125: {
			return (struct arr_0) {14, constantarr_0_232};
		}
		case 126: {
			return (struct arr_0) {19, constantarr_0_233};
		}
		case 127: {
			return (struct arr_0) {0u, NULL};
		}
		case 128: {
			return (struct arr_0) {11, constantarr_0_235};
		}
		case 129: {
			return (struct arr_0) {6, constantarr_0_236};
		}
		case 130: {
			return (struct arr_0) {18, constantarr_0_237};
		}
		case 131: {
			return (struct arr_0) {19, constantarr_0_238};
		}
		case 132: {
			return (struct arr_0) {12, constantarr_0_239};
		}
		case 133: {
			return (struct arr_0) {8, constantarr_0_96};
		}
		case 134: {
			return (struct arr_0) {25, constantarr_0_240};
		}
		case 135: {
			return (struct arr_0) {25, constantarr_0_241};
		}
		case 136: {
			return (struct arr_0) {11, constantarr_0_58};
		}
		case 137: {
			return (struct arr_0) {21, constantarr_0_242};
		}
		case 138: {
			return (struct arr_0) {18, constantarr_0_68};
		}
		case 139: {
			return (struct arr_0) {13, constantarr_0_191};
		}
		case 140: {
			return (struct arr_0) {13, constantarr_0_191};
		}
		case 141: {
			return (struct arr_0) {24, constantarr_0_243};
		}
		case 142: {
			return (struct arr_0) {30, constantarr_0_244};
		}
		case 143: {
			return (struct arr_0) {1, constantarr_0_245};
		}
		case 144: {
			return (struct arr_0) {1, constantarr_0_246};
		}
		case 145: {
			return (struct arr_0) {17, constantarr_0_182};
		}
		case 146: {
			return (struct arr_0) {16, constantarr_0_247};
		}
		case 147: {
			return (struct arr_0) {6, constantarr_0_248};
		}
		case 148: {
			return (struct arr_0) {14, constantarr_0_249};
		}
		case 149: {
			return (struct arr_0) {14, constantarr_0_251};
		}
		case 150: {
			return (struct arr_0) {14, constantarr_0_254};
		}
		case 151: {
			return (struct arr_0) {19, constantarr_0_255};
		}
		case 152: {
			return (struct arr_0) {5, constantarr_0_256};
		}
		case 153: {
			return (struct arr_0) {16, constantarr_0_257};
		}
		case 154: {
			return (struct arr_0) {6, constantarr_0_258};
		}
		case 155: {
			return (struct arr_0) {6, constantarr_0_227};
		}
		case 156: {
			return (struct arr_0) {21, constantarr_0_259};
		}
		case 157: {
			return (struct arr_0) {14, constantarr_0_261};
		}
		case 158: {
			return (struct arr_0) {2, constantarr_0_158};
		}
		case 159: {
			return (struct arr_0) {19, constantarr_0_265};
		}
		case 160: {
			return (struct arr_0) {19, constantarr_0_265};
		}
		case 161: {
			return (struct arr_0) {7, constantarr_0_270};
		}
		case 162: {
			return (struct arr_0) {13, constantarr_0_271};
		}
		case 163: {
			return (struct arr_0) {7, constantarr_0_272};
		}
		case 164: {
			return (struct arr_0) {3, constantarr_0_278};
		}
		case 165: {
			return (struct arr_0) {10, constantarr_0_159};
		}
		case 166: {
			return (struct arr_0) {14, constantarr_0_298};
		}
		case 167: {
			return (struct arr_0) {14, constantarr_0_299};
		}
		case 168: {
			return (struct arr_0) {16, constantarr_0_300};
		}
		case 169: {
			return (struct arr_0) {16, constantarr_0_301};
		}
		case 170: {
			return (struct arr_0) {14, constantarr_0_304};
		}
		case 171: {
			return (struct arr_0) {15, constantarr_0_305};
		}
		case 172: {
			return (struct arr_0) {13, constantarr_0_191};
		}
		case 173: {
			return (struct arr_0) {0u, NULL};
		}
		case 174: {
			return (struct arr_0) {38, constantarr_0_312};
		}
		case 175: {
			return (struct arr_0) {0u, NULL};
		}
		case 176: {
			return (struct arr_0) {22, constantarr_0_316};
		}
		case 177: {
			return (struct arr_0) {17, constantarr_0_317};
		}
		case 178: {
			return (struct arr_0) {13, constantarr_0_318};
		}
		case 179: {
			return (struct arr_0) {38, constantarr_0_312};
		}
		case 180: {
			return (struct arr_0) {0u, NULL};
		}
		case 181: {
			return (struct arr_0) {21, constantarr_0_319};
		}
		case 182: {
			return (struct arr_0) {22, constantarr_0_320};
		}
		case 183: {
			return (struct arr_0) {24, constantarr_0_321};
		}
		case 184: {
			return (struct arr_0) {13, constantarr_0_191};
		}
		case 185: {
			return (struct arr_0) {0u, NULL};
		}
		case 186: {
			return (struct arr_0) {30, constantarr_0_324};
		}
		case 187: {
			return (struct arr_0) {19, constantarr_0_325};
		}
		case 188: {
			return (struct arr_0) {25, constantarr_0_329};
		}
		case 189: {
			return (struct arr_0) {20, constantarr_0_330};
		}
		case 190: {
			return (struct arr_0) {10, constantarr_0_331};
		}
		case 191: {
			return (struct arr_0) {17, constantarr_0_332};
		}
		case 192: {
			return (struct arr_0) {12, constantarr_0_200};
		}
		case 193: {
			return (struct arr_0) {13, constantarr_0_191};
		}
		case 194: {
			return (struct arr_0) {8, constantarr_0_335};
		}
		case 195: {
			return (struct arr_0) {8, constantarr_0_335};
		}
		case 196: {
			return (struct arr_0) {15, constantarr_0_336};
		}
		case 197: {
			return (struct arr_0) {12, constantarr_0_339};
		}
		case 198: {
			return (struct arr_0) {4, constantarr_0_340};
		}
		case 199: {
			return (struct arr_0) {10, constantarr_0_341};
		}
		case 200: {
			return (struct arr_0) {12, constantarr_0_348};
		}
		case 201: {
			return (struct arr_0) {5, constantarr_0_350};
		}
		case 202: {
			return (struct arr_0) {10, constantarr_0_352};
		}
		case 203: {
			return (struct arr_0) {12, constantarr_0_357};
		}
		case 204: {
			return (struct arr_0) {11, constantarr_0_359};
		}
		case 205: {
			return (struct arr_0) {28, constantarr_0_360};
		}
		case 206: {
			return (struct arr_0) {4, constantarr_0_363};
		}
		case 207: {
			return (struct arr_0) {4, constantarr_0_363};
		}
		case 208: {
			return (struct arr_0) {4, constantarr_0_363};
		}
		case 209: {
			return (struct arr_0) {4, constantarr_0_363};
		}
		case 210: {
			return (struct arr_0) {6, constantarr_0_370};
		}
		case 211: {
			return (struct arr_0) {24, constantarr_0_371};
		}
		case 212: {
			return (struct arr_0) {0u, NULL};
		}
		case 213: {
			return (struct arr_0) {23, constantarr_0_372};
		}
		case 214: {
			return (struct arr_0) {0u, NULL};
		}
		case 215: {
			return (struct arr_0) {36, constantarr_0_374};
		}
		case 216: {
			return (struct arr_0) {11, constantarr_0_375};
		}
		case 217: {
			return (struct arr_0) {36, constantarr_0_376};
		}
		case 218: {
			return (struct arr_0) {28, constantarr_0_377};
		}
		case 219: {
			return (struct arr_0) {24, constantarr_0_379};
		}
		case 220: {
			return (struct arr_0) {15, constantarr_0_380};
		}
		case 221: {
			return (struct arr_0) {18, constantarr_0_382};
		}
		case 222: {
			return (struct arr_0) {0u, NULL};
		}
		case 223: {
			return (struct arr_0) {31, constantarr_0_384};
		}
		case 224: {
			return (struct arr_0) {31, constantarr_0_385};
		}
		case 225: {
			return (struct arr_0) {23, constantarr_0_386};
		}
		case 226: {
			return (struct arr_0) {22, constantarr_0_387};
		}
		case 227: {
			return (struct arr_0) {24, constantarr_0_388};
		}
		case 228: {
			return (struct arr_0) {5, constantarr_0_391};
		}
		case 229: {
			return (struct arr_0) {14, constantarr_0_392};
		}
		case 230: {
			return (struct arr_0) {15, constantarr_0_393};
		}
		case 231: {
			return (struct arr_0) {10, constantarr_0_394};
		}
		case 232: {
			return (struct arr_0) {13, constantarr_0_191};
		}
		case 233: {
			return (struct arr_0) {25, constantarr_0_396};
		}
		case 234: {
			return (struct arr_0) {14, constantarr_0_397};
		}
		case 235: {
			return (struct arr_0) {23, constantarr_0_206};
		}
		case 236: {
			return (struct arr_0) {18, constantarr_0_398};
		}
		case 237: {
			return (struct arr_0) {24, constantarr_0_399};
		}
		case 238: {
			return (struct arr_0) {18, constantarr_0_400};
		}
		case 239: {
			return (struct arr_0) {0u, NULL};
		}
		case 240: {
			return (struct arr_0) {20, constantarr_0_330};
		}
		case 241: {
			return (struct arr_0) {0u, NULL};
		}
		case 242: {
			return (struct arr_0) {14, constantarr_0_401};
		}
		case 243: {
			return (struct arr_0) {12, constantarr_0_200};
		}
		case 244: {
			return (struct arr_0) {13, constantarr_0_191};
		}
		case 245: {
			return (struct arr_0) {33, constantarr_0_402};
		}
		case 246: {
			return (struct arr_0) {6, constantarr_0_227};
		}
		case 247: {
			return (struct arr_0) {24, constantarr_0_403};
		}
		case 248: {
			return (struct arr_0) {16, constantarr_0_404};
		}
		case 249: {
			return (struct arr_0) {5, constantarr_0_405};
		}
		case 250: {
			return (struct arr_0) {13, constantarr_0_406};
		}
		case 251: {
			return (struct arr_0) {17, constantarr_0_407};
		}
		case 252: {
			return (struct arr_0) {8, constantarr_0_408};
		}
		case 253: {
			return (struct arr_0) {0u, NULL};
		}
		case 254: {
			return (struct arr_0) {27, constantarr_0_410};
		}
		case 255: {
			return (struct arr_0) {30, constantarr_0_412};
		}
		case 256: {
			return (struct arr_0) {22, constantarr_0_413};
		}
		case 257: {
			return (struct arr_0) {22, constantarr_0_414};
		}
		case 258: {
			return (struct arr_0) {26, constantarr_0_415};
		}
		case 259: {
			return (struct arr_0) {0u, NULL};
		}
		case 260: {
			return (struct arr_0) {17, constantarr_0_416};
		}
		case 261: {
			return (struct arr_0) {14, constantarr_0_417};
		}
		case 262: {
			return (struct arr_0) {30, constantarr_0_418};
		}
		case 263: {
			return (struct arr_0) {15, constantarr_0_419};
		}
		case 264: {
			return (struct arr_0) {0u, NULL};
		}
		case 265: {
			return (struct arr_0) {11, constantarr_0_421};
		}
		case 266: {
			return (struct arr_0) {45, constantarr_0_422};
		}
		case 267: {
			return (struct arr_0) {19, constantarr_0_423};
		}
		case 268: {
			return (struct arr_0) {17, constantarr_0_427};
		}
		case 269: {
			return (struct arr_0) {14, constantarr_0_428};
		}
		case 270: {
			return (struct arr_0) {9, constantarr_0_429};
		}
		case 271: {
			return (struct arr_0) {6, constantarr_0_430};
		}
		case 272: {
			return (struct arr_0) {12, constantarr_0_431};
		}
		case 273: {
			return (struct arr_0) {10, constantarr_0_434};
		}
		case 274: {
			return (struct arr_0) {15, constantarr_0_436};
		}
		case 275: {
			return (struct arr_0) {21, constantarr_0_437};
		}
		case 276: {
			return (struct arr_0) {28, constantarr_0_441};
		}
		case 277: {
			return (struct arr_0) {6, constantarr_0_444};
		}
		case 278: {
			return (struct arr_0) {16, constantarr_0_445};
		}
		case 279: {
			return (struct arr_0) {11, constantarr_0_446};
		}
		case 280: {
			return (struct arr_0) {17, constantarr_0_447};
		}
		case 281: {
			return (struct arr_0) {13, constantarr_0_451};
		}
		case 282: {
			return (struct arr_0) {15, constantarr_0_452};
		}
		case 283: {
			return (struct arr_0) {9, constantarr_0_457};
		}
		case 284: {
			return (struct arr_0) {17, constantarr_0_459};
		}
		case 285: {
			return (struct arr_0) {21, constantarr_0_461};
		}
		case 286: {
			return (struct arr_0) {9, constantarr_0_465};
		}
		case 287: {
			return (struct arr_0) {14, constantarr_0_469};
		}
		case 288: {
			return (struct arr_0) {13, constantarr_0_470};
		}
		case 289: {
			return (struct arr_0) {19, constantarr_0_471};
		}
		case 290: {
			return (struct arr_0) {12, constantarr_0_200};
		}
		case 291: {
			return (struct arr_0) {13, constantarr_0_191};
		}
		case 292: {
			return (struct arr_0) {15, constantarr_0_472};
		}
		case 293: {
			return (struct arr_0) {15, constantarr_0_472};
		}
		case 294: {
			return (struct arr_0) {19, constantarr_0_473};
		}
		case 295: {
			return (struct arr_0) {13, constantarr_0_201};
		}
		case 296: {
			return (struct arr_0) {13, constantarr_0_201};
		}
		case 297: {
			return (struct arr_0) {10, constantarr_0_474};
		}
		case 298: {
			return (struct arr_0) {11, constantarr_0_475};
		}
		case 299: {
			return (struct arr_0) {38, constantarr_0_477};
		}
		case 300: {
			return (struct arr_0) {12, constantarr_0_239};
		}
		case 301: {
			return (struct arr_0) {8, constantarr_0_96};
		}
		case 302: {
			return (struct arr_0) {17, constantarr_0_182};
		}
		case 303: {
			return (struct arr_0) {11, constantarr_0_478};
		}
		case 304: {
			return (struct arr_0) {8, constantarr_0_482};
		}
		case 305: {
			return (struct arr_0) {8, constantarr_0_483};
		}
		case 306: {
			return (struct arr_0) {7, constantarr_0_488};
		}
		case 307: {
			return (struct arr_0) {12, constantarr_0_492};
		}
		case 308: {
			return (struct arr_0) {33, constantarr_0_493};
		}
		case 309: {
			return (struct arr_0) {38, constantarr_0_494};
		}
		case 310: {
			return (struct arr_0) {8, constantarr_0_495};
		}
		case 311: {
			return (struct arr_0) {30, constantarr_0_496};
		}
		case 312: {
			return (struct arr_0) {10, constantarr_0_497};
		}
		case 313: {
			return (struct arr_0) {13, constantarr_0_498};
		}
		case 314: {
			return (struct arr_0) {46, constantarr_0_500};
		}
		case 315: {
			return (struct arr_0) {0u, NULL};
		}
		case 316: {
			return (struct arr_0) {0u, NULL};
		}
		case 317: {
			return (struct arr_0) {0u, NULL};
		}
		case 318: {
			return (struct arr_0) {0u, NULL};
		}
		case 319: {
			return (struct arr_0) {0u, NULL};
		}
		case 320: {
			return (struct arr_0) {0u, NULL};
		}
		case 321: {
			return (struct arr_0) {0u, NULL};
		}
		case 322: {
			return (struct arr_0) {0u, NULL};
		}
		case 323: {
			return (struct arr_0) {0u, NULL};
		}
		case 324: {
			return (struct arr_0) {0u, NULL};
		}
		case 325: {
			return (struct arr_0) {0u, NULL};
		}
		case 326: {
			return (struct arr_0) {0u, NULL};
		}
		case 327: {
			return (struct arr_0) {0u, NULL};
		}
		case 328: {
			return (struct arr_0) {0u, NULL};
		}
		case 329: {
			return (struct arr_0) {0u, NULL};
		}
		case 330: {
			return (struct arr_0) {0u, NULL};
		}
		case 331: {
			return (struct arr_0) {0u, NULL};
		}
		case 332: {
			return (struct arr_0) {0u, NULL};
		}
		case 333: {
			return (struct arr_0) {0u, NULL};
		}
		case 334: {
			return (struct arr_0) {0u, NULL};
		}
		case 335: {
			return (struct arr_0) {0u, NULL};
		}
		case 336: {
			return (struct arr_0) {0u, NULL};
		}
		case 337: {
			return (struct arr_0) {0u, NULL};
		}
		case 338: {
			return (struct arr_0) {0u, NULL};
		}
		case 339: {
			return (struct arr_0) {0u, NULL};
		}
		case 340: {
			return (struct arr_0) {0u, NULL};
		}
		case 341: {
			return (struct arr_0) {0u, NULL};
		}
		case 342: {
			return (struct arr_0) {0u, NULL};
		}
		case 343: {
			return (struct arr_0) {0u, NULL};
		}
		case 344: {
			return (struct arr_0) {0u, NULL};
		}
		case 345: {
			return (struct arr_0) {0u, NULL};
		}
		case 346: {
			return (struct arr_0) {0u, NULL};
		}
		case 347: {
			return (struct arr_0) {0u, NULL};
		}
		case 348: {
			return (struct arr_0) {0u, NULL};
		}
		case 349: {
			return (struct arr_0) {0u, NULL};
		}
		case 350: {
			return (struct arr_0) {0u, NULL};
		}
		case 351: {
			return (struct arr_0) {0u, NULL};
		}
		case 352: {
			return (struct arr_0) {0u, NULL};
		}
		case 353: {
			return (struct arr_0) {0u, NULL};
		}
		case 354: {
			return (struct arr_0) {0u, NULL};
		}
		case 355: {
			return (struct arr_0) {0u, NULL};
		}
		case 356: {
			return (struct arr_0) {0u, NULL};
		}
		case 357: {
			return (struct arr_0) {0u, NULL};
		}
		case 358: {
			return (struct arr_0) {0u, NULL};
		}
		case 359: {
			return (struct arr_0) {0u, NULL};
		}
		case 360: {
			return (struct arr_0) {0u, NULL};
		}
		case 361: {
			return (struct arr_0) {0u, NULL};
		}
		case 362: {
			return (struct arr_0) {0u, NULL};
		}
		case 363: {
			return (struct arr_0) {0u, NULL};
		}
		case 364: {
			return (struct arr_0) {0u, NULL};
		}
		case 365: {
			return (struct arr_0) {0u, NULL};
		}
		case 366: {
			return (struct arr_0) {0u, NULL};
		}
		case 367: {
			return (struct arr_0) {0u, NULL};
		}
		case 368: {
			return (struct arr_0) {0u, NULL};
		}
		case 369: {
			return (struct arr_0) {0u, NULL};
		}
		case 370: {
			return (struct arr_0) {0u, NULL};
		}
		case 371: {
			return (struct arr_0) {0u, NULL};
		}
		case 372: {
			return (struct arr_0) {14, constantarr_0_508};
		}
		case 373: {
			return (struct arr_0) {7, constantarr_0_510};
		}
		case 374: {
			return (struct arr_0) {12, constantarr_0_511};
		}
		case 375: {
			return (struct arr_0) {18, constantarr_0_513};
		}
		case 376: {
			return (struct arr_0) {15, constantarr_0_514};
		}
		case 377: {
			return (struct arr_0) {12, constantarr_0_517};
		}
		case 378: {
			return (struct arr_0) {6, constantarr_0_519};
		}
		case 379: {
			return (struct arr_0) {5, constantarr_0_520};
		}
		case 380: {
			return (struct arr_0) {19, constantarr_0_522};
		}
		case 381: {
			return (struct arr_0) {4, constantarr_0_523};
		}
		case 382: {
			return (struct arr_0) {35, constantarr_0_524};
		}
		case 383: {
			return (struct arr_0) {4, constantarr_0_528};
		}
		case 384: {
			return (struct arr_0) {13, constantarr_0_529};
		}
		default:
			return (struct arr_0) {0, NULL};
	}
}
/* sort-together void(a ptr<ptr<nat8>>, b ptr<arr<char>>, size nat) */
struct void_ sort_together(struct ctx* ctx, uint8_t** a, struct arr_0* b, uint64_t size) {
	top:;
	uint8_t _0 = _greater(size, 1u);
	if (_0) {
		swap_0(ctx, a, 0u, (size / 2u));
		swap_1(ctx, b, 0u, (size / 2u));
		uint64_t after_pivot0;
		uint64_t _1 = noctx_decr(size);
		after_pivot0 = partition_recur_together(ctx, a, b, (*a), 1u, _1);
		
		uint64_t new_pivot_index1;
		new_pivot_index1 = noctx_decr(after_pivot0);
		
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
/* swap<arr<char>> void(a ptr<arr<char>>, lo nat, hi nat) */
struct void_ swap_1(struct ctx* ctx, struct arr_0* a, uint64_t lo, uint64_t hi) {
	struct arr_0 temp0;
	temp0 = subscript_2(a, lo);
	
	struct arr_0 _0 = subscript_2(a, hi);
	set_subscript_1(a, lo, _0);
	return set_subscript_1(a, hi, temp0);
}
/* subscript<?a> arr<char>(a ptr<arr<char>>, n nat) */
struct arr_0 subscript_2(struct arr_0* a, uint64_t n) {
	return (*(a + n));
}
/* partition-recur-together nat(a ptr<ptr<nat8>>, b ptr<arr<char>>, pivot ptr<nat8>, l nat, r nat) */
uint64_t partition_recur_together(struct ctx* ctx, uint8_t** a, struct arr_0* b, uint8_t* pivot, uint64_t l, uint64_t r) {
	top:;
	uint8_t _0 = _lessOrEqual(l, r);
	if (_0) {
		uint8_t* _1 = subscript_1(a, l);
		uint8_t _2 = (_1 < pivot);
		if (_2) {
			uint64_t _3 = noctx_incr(l);
			a = a;
			b = b;
			pivot = pivot;
			l = _3;
			r = r;
			goto top;
		} else {
			swap_0(ctx, a, l, r);
			swap_1(ctx, b, l, r);
			uint64_t _4 = noctx_decr(r);
			a = a;
			b = b;
			pivot = pivot;
			l = l;
			r = _4;
			goto top;
		}
	} else {
		return l;
	}
}
/* noctx-decr nat(n nat) */
uint64_t noctx_decr(uint64_t n) {
	uint8_t _0 = _equal_0(n, 0u);
	hard_forbid(_0);
	return (n - 1u);
}
/* fill-code-names-recur void(code-names ptr<arr<char>>, end-code-names ptr<arr<char>>, code-ptrs ptr<ptr<nat8>>, fun-ptrs ptr<ptr<nat8>>, fun-names ptr<arr<char>>) */
struct void_ fill_code_names_recur(struct ctx* ctx, struct arr_0* code_names, struct arr_0* end_code_names, uint8_t** code_ptrs, uint8_t** fun_ptrs, struct arr_0* fun_names) {
	top:;
	uint8_t _0 = (code_names < end_code_names);
	if (_0) {
		uint64_t _1 = funs_count_81();
		struct arr_0 _2 = get_fun_name((*code_ptrs), fun_ptrs, fun_names, _1);
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
/* get-fun-name arr<char>(code-ptr ptr<nat8>, fun-ptrs ptr<ptr<nat8>>, fun-names ptr<arr<char>>, size nat) */
struct arr_0 get_fun_name(uint8_t* code_ptr, uint8_t** fun_ptrs, struct arr_0* fun_names, uint64_t size) {
	top:;
	uint8_t _0 = _less(size, 2u);
	if (_0) {
		return (struct arr_0) {11, constantarr_0_3};
	} else {
		uint8_t* _1 = subscript_1(fun_ptrs, 1u);
		uint8_t _2 = (code_ptr < _1);
		if (_2) {
			return (*fun_names);
		} else {
			uint64_t _3 = noctx_decr(size);
			code_ptr = code_ptr;
			fun_ptrs = (fun_ptrs + 1u);
			fun_names = (fun_names + 1u);
			size = _3;
			goto top;
		}
	}
}
/* noctx-at<?a> arr<char>(a arr<arr<char>>, index nat) */
struct arr_0 noctx_at_0(struct arr_1 a, uint64_t index) {
	uint8_t _0 = _less(index, a.size);
	hard_assert(_0);
	return subscript_2(a.begin_ptr, index);
}
/* ~<?a> arr<char>(a arr<char>, b arr<char>) */
struct arr_0 _concat(struct ctx* ctx, struct arr_0 a, struct arr_0 b) {
	uint64_t res_size0;
	res_size0 = _plus(ctx, a.size, b.size);
	
	char* res1;
	res1 = alloc_uninitialized_0(ctx, res_size0);
	
	copy_data_from(ctx, res1, a.begin_ptr, a.size);
	copy_data_from(ctx, (res1 + a.size), b.begin_ptr, b.size);
	return (struct arr_0) {res_size0, res1};
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
/* alloc-uninitialized<?a> ptr<char>(size nat) */
char* alloc_uninitialized_0(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(char)));
	return (char*) _0;
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
			struct some_5 s0 = _0.as1;
			
			return s0.value;
		}
		default:
			return NULL;
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
/* tail<arr<?a>> arr<arr<char>>(a arr<arr<char>>) */
struct arr_1 tail_0(struct ctx* ctx, struct arr_1 a) {
	uint8_t _0 = empty__q_1(a);
	forbid_0(ctx, _0);
	struct arrow _1 = _arrow(ctx, 1u, a.size);
	return subscript_3(ctx, a, _1);
}
/* forbid void(condition bool) */
struct void_ forbid_0(struct ctx* ctx, uint8_t condition) {
	return forbid_1(ctx, condition, (struct arr_0) {13, constantarr_0_5});
}
/* forbid void(condition bool, message arr<char>) */
struct void_ forbid_1(struct ctx* ctx, uint8_t condition, struct arr_0 message) {
	uint8_t _0 = condition;
	if (_0) {
		return fail(ctx, message);
	} else {
		return (struct void_) {};
	}
}
/* subscript<?a> arr<arr<char>>(a arr<arr<char>>, range arrow<nat, nat>) */
struct arr_1 subscript_3(struct ctx* ctx, struct arr_1 a, struct arrow range) {
	uint8_t _0 = _lessOrEqual(range.from, range.to);
	assert(ctx, _0);
	uint8_t _1 = _lessOrEqual(range.to, a.size);
	assert(ctx, _1);
	uint64_t _2 = _minus_2(ctx, range.to, range.from);
	return (struct arr_1) {_2, (a.begin_ptr + range.from)};
}
/* - nat(a nat, b nat) */
uint64_t _minus_2(struct ctx* ctx, uint64_t a, uint64_t b) {
	uint8_t _0 = _greaterOrEqual(a, b);
	assert(ctx, _0);
	return (a - b);
}
/* -><nat, nat> arrow<nat, nat>(from nat, to nat) */
struct arrow _arrow(struct ctx* ctx, uint64_t from, uint64_t to) {
	return (struct arrow) {from, to};
}
/* finish arr<char>(a interp) */
struct arr_0 finish(struct ctx* ctx, struct interp a) {
	return move_to_arr__e(a.inner);
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
/* begin-ptr<?a> ptr<char>(a mut-list<char>) */
char* begin_ptr_0(struct mut_list_1* a) {
	return begin_ptr_1(a->backing);
}
/* begin-ptr<?a> ptr<char>(a mut-arr<char>) */
char* begin_ptr_1(struct mut_arr_1 a) {
	return a.inner.begin_ptr;
}
/* mut-arr<?a> mut-arr<char>() */
struct mut_arr_1 mut_arr_1(void) {
	return (struct mut_arr_1) {(struct void_) {}, (struct arr_0) {0u, NULL}};
}
/* to-str arr<char>(a arr<char>) */
struct arr_0 to_str_0(struct ctx* ctx, struct arr_0 a) {
	return a;
}
/* with-value<arr<char>> interp(a interp, b arr<char>) */
struct interp with_value_0(struct ctx* ctx, struct interp a, struct arr_0 b) {
	struct arr_0 _0 = to_str_0(ctx, b);
	return with_str(ctx, a, _0);
}
/* with-str interp(a interp, b arr<char>) */
struct interp with_str(struct ctx* ctx, struct interp a, struct arr_0 b) {
	_concatEquals_0(ctx, a.inner, b);
	return a;
}
/* ~=<char> void(a mut-list<char>, values arr<char>) */
struct void_ _concatEquals_0(struct ctx* ctx, struct mut_list_1* a, struct arr_0 values) {
	struct _concatEquals_0__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct _concatEquals_0__lambda0));
	temp0 = (struct _concatEquals_0__lambda0*) _0;
	
	*temp0 = (struct _concatEquals_0__lambda0) {a};
	return each(ctx, values, (struct fun_act1_1) {0, .as0 = temp0});
}
/* each<?a> void(a arr<char>, f fun-act1<void, char>) */
struct void_ each(struct ctx* ctx, struct arr_0 a, struct fun_act1_1 f) {
	char* _0 = end_ptr(a);
	return each_recur(ctx, a.begin_ptr, _0, f);
}
/* each-recur<?a> void(cur ptr<char>, end ptr<char>, f fun-act1<void, char>) */
struct void_ each_recur(struct ctx* ctx, char* cur, char* end, struct fun_act1_1 f) {
	top:;
	uint8_t _0 = not((cur == end));
	if (_0) {
		subscript_4(ctx, f, (*cur));
		cur = (cur + 1u);
		end = end;
		f = f;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* subscript<void, ?a> void(a fun-act1<void, char>, p0 char) */
struct void_ subscript_4(struct ctx* ctx, struct fun_act1_1 a, char p0) {
	return call_w_ctx_127(a, ctx, p0);
}
/* call-w-ctx<void, char> (generated) (generated) */
struct void_ call_w_ctx_127(struct fun_act1_1 a, struct ctx* ctx, char p0) {
	struct fun_act1_1 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct _concatEquals_0__lambda0* closure0 = _0.as0;
			
			return _concatEquals_0__lambda0(ctx, closure0, p0);
		}
		default:
			return (struct void_) {};
	}
}
/* end-ptr<?a> ptr<char>(a arr<char>) */
char* end_ptr(struct arr_0 a) {
	return (a.begin_ptr + a.size);
}
/* ~=<?a> void(a mut-list<char>, value char) */
struct void_ _concatEquals_1(struct ctx* ctx, struct mut_list_1* a, char value) {
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
	struct mut_arr_1 _7 = subscript_5(ctx, a->backing, _6);
	return set_zero_elements(_7);
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
struct mut_arr_1 subscript_5(struct ctx* ctx, struct mut_arr_1 a, struct arrow range) {
	uint8_t _0 = _lessOrEqual(range.from, range.to);
	assert(ctx, _0);
	uint64_t _1 = size_0(a);
	uint8_t _2 = _lessOrEqual(range.to, _1);
	assert(ctx, _2);
	struct arr_0 _3 = subscript_6(ctx, a.inner, range);
	return (struct mut_arr_1) {(struct void_) {}, _3};
}
/* subscript<?a> arr<char>(a arr<char>, range arrow<nat, nat>) */
struct arr_0 subscript_6(struct ctx* ctx, struct arr_0 a, struct arrow range) {
	uint8_t _0 = _lessOrEqual(range.from, range.to);
	assert(ctx, _0);
	uint8_t _1 = _lessOrEqual(range.to, a.size);
	assert(ctx, _1);
	uint64_t _2 = _minus_2(ctx, range.to, range.from);
	return (struct arr_0) {_2, (a.begin_ptr + range.from)};
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
uint64_t _times(struct ctx* ctx, uint64_t a, uint64_t b) {
	uint8_t _0 = _equal_0(a, 0u);uint8_t _1;
	
	if (_0) {
		_1 = 1;
	} else {
		_1 = _equal_0(b, 0u);
	}
	if (_1) {
		return 0u;
	} else {
		uint64_t res0;
		res0 = (a * b);
		
		uint64_t _2 = _divide(ctx, res0, b);
		uint8_t _3 = _equal_0(_2, a);
		assert(ctx, _3);
		uint64_t _4 = _divide(ctx, res0, a);
		uint8_t _5 = _equal_0(_4, b);
		assert(ctx, _5);
		return res0;
	}
}
/* / nat(a nat, b nat) */
uint64_t _divide(struct ctx* ctx, uint64_t a, uint64_t b) {
	uint8_t _0 = _equal_0(b, 0u);
	forbid_0(ctx, _0);
	return (a / b);
}
/* set-subscript<?a> void(a ptr<char>, n nat, value char) */
struct void_ set_subscript_2(char* a, uint64_t n, char value) {
	return (*(a + n) = value, (struct void_) {});
}
/* ~=<char>.lambda0 void(it char) */
struct void_ _concatEquals_0__lambda0(struct ctx* ctx, struct _concatEquals_0__lambda0* _closure, char it) {
	return _concatEquals_1(ctx, _closure->a, it);
}
/* interp interp() */
struct interp interp(struct ctx* ctx) {
	struct mut_list_1* _0 = mut_list(ctx);
	return (struct interp) {_0};
}
/* mut-list<char> mut-list<char>() */
struct mut_list_1* mut_list(struct ctx* ctx) {
	struct mut_list_1* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_list_1));
	temp0 = (struct mut_list_1*) _0;
	
	struct mut_arr_1 _1 = mut_arr_1();
	*temp0 = (struct mut_list_1) {_1, 0u};
	return temp0;
}
/* get-global-ctx global-ctx() */
struct global_ctx* get_global_ctx(struct ctx* ctx) {
	return (struct global_ctx*) ctx->gctx_ptr;
}
/* island.lambda0 void(it exception) */
struct void_ island__lambda0(struct ctx* ctx, struct void_ _closure, struct exception it) {
	return default_exception_handler(ctx, it);
}
/* default-log-handler void(a logged) */
struct void_ default_log_handler(struct ctx* ctx, struct logged* a) {
	struct interp _0 = interp(ctx);
	struct interp _1 = with_value_1(ctx, _0, a->level);
	struct interp _2 = with_str(ctx, _1, (struct arr_0) {2, constantarr_0_9});
	struct interp _3 = with_value_0(ctx, _2, a->message);
	struct arr_0 _4 = finish(ctx, _3);
	return print(_4);
}
/* print void(a arr<char>) */
struct void_ print(struct arr_0 a) {
	print_no_newline(a);
	return print_no_newline((struct arr_0) {1, constantarr_0_1});
}
/* print-no-newline void(a arr<char>) */
struct void_ print_no_newline(struct arr_0 a) {
	int32_t _0 = stdout();
	return write_no_newline(_0, a);
}
/* stdout int32() */
int32_t stdout(void) {
	return 1;
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
			return (struct arr_0) {0, NULL};
	}
}
/* with-value<log-level> interp(a interp, b log-level) */
struct interp with_value_1(struct ctx* ctx, struct interp a, struct log_level b) {
	struct arr_0 _0 = to_str_1(ctx, b);
	return with_str(ctx, a, _0);
}
/* island.lambda1 void(log logged) */
struct void_ island__lambda1(struct ctx* ctx, struct void_ _closure, struct logged* log) {
	return default_log_handler(ctx, log);
}
/* gc gc() */
struct gc gc(void) {
	uint8_t* mark0;
	uint8_t* _0 = malloc(16777216u);
	mark0 = (uint8_t*) _0;
	
	uint8_t* mark_end1;
	mark_end1 = (mark0 + 16777216u);
	
	uint64_t* data2;
	uint8_t* _1 = malloc((16777216u * sizeof(uint64_t)));
	data2 = (uint64_t*) _1;
	
	uint8_t _2 = word_aligned__q(((uint8_t*) data2));
	hard_assert(_2);
	uint64_t* data_end3;
	data_end3 = (data2 + 16777216u);
	
	(memset(((uint8_t*) mark0), 0u, 16777216u), (struct void_) {});
	struct gc res4;
	struct lock _3 = lock_by_val();
	res4 = (struct gc) {_3, 0u, (struct opt_1) {0, .as0 = (struct none) {}}, 0, 16777216u, mark0, mark0, mark_end1, data2, data2, data_end3};
	
	validate_gc((&res4));
	return res4;
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
/* do-main fut<nat>(gctx global-ctx, island island, argc int32, argv ptr<ptr<char>>, main-ptr fun-ptr2<fut<nat>, ctx, arr<arr<char>>>) */
struct fut_0* do_main(struct global_ctx* gctx, struct island* island, int32_t argc, char** argv, fun_ptr2 main_ptr) {
	struct exception_ctx ectx0;
	ectx0 = exception_ctx();
	
	struct log_ctx log_ctx1;
	log_ctx1 = log_ctx();
	
	struct thread_local_stuff tls2;
	tls2 = (struct thread_local_stuff) {(&ectx0), (&log_ctx1)};
	
	struct ctx ctx_by_val3;
	ctx_by_val3 = ctx(gctx, (&tls2), island, 0u);
	
	struct ctx* ctx4;
	ctx4 = (&ctx_by_val3);
	
	struct fun_act2 add5;
	add5 = (struct fun_act2) {0, .as0 = (struct void_) {}};
	
	struct arr_4 all_args6;
	all_args6 = (struct arr_4) {(uint64_t) (int64_t) argc, argv};
	
	return call_w_ctx_264(add5, ctx4, all_args6, main_ptr);
}
/* exception-ctx exception-ctx() */
struct exception_ctx exception_ctx(void) {
	return (struct exception_ctx) {NULL, (struct exception) {(struct arr_0) {0u, NULL}, (struct backtrace) {(struct arr_1) {0u, NULL}}}};
}
/* log-ctx log-ctx() */
struct log_ctx log_ctx(void) {
	return (struct log_ctx) {(struct fun1_1) {0}};
}
/* ctx ctx(gctx global-ctx, tls thread-local-stuff, island island, exclusion nat) */
struct ctx ctx(struct global_ctx* gctx, struct thread_local_stuff* tls, struct island* island, uint64_t exclusion) {
	uint8_t* gc_ctx0;
	struct gc_ctx* _0 = get_gc_ctx_1((&island->gc));
	gc_ctx0 = ((uint8_t*) _0);
	
	struct exception_ctx* exception_ctx1;
	exception_ctx1 = tls->exception_ctx;
	
	struct log_ctx* log_ctx2;
	log_ctx2 = tls->log_ctx;
	
	log_ctx2->handler = (&island->gc_root)->log_handler;
	return (struct ctx) {((uint8_t*) gctx), island->id, exclusion, gc_ctx0, ((uint8_t*) exception_ctx1), ((uint8_t*) log_ctx2)};
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
			c0 = (struct gc_ctx*) _1;
			
			c0->gc = gc;
			c0->next_ctx = (struct opt_1) {0, .as0 = (struct none) {}};
			res3 = c0;
			break;
		}
		case 1: {
			struct some_1 s1 = _0.as1;
			
			struct gc_ctx* c2;
			c2 = s1.value;
			
			gc->context_head = c2->next_ctx;
			c2->next_ctx = (struct opt_1) {0, .as0 = (struct none) {}};
			res3 = c2;
			break;
		}
		default:
			NULL;
	}
	
	release__e((&gc->lk));
	return res3;
}
/* add-first-task fut<nat>(all-args arr<ptr<char>>, main-ptr fun-ptr2<fut<nat>, ctx, arr<arr<char>>>) */
struct fut_0* add_first_task(struct ctx* ctx, struct arr_4 all_args, fun_ptr2 main_ptr) {
	struct fut_0* res0;
	struct fut_1* _0 = delay(ctx);
	struct island_and_exclusion _1 = cur_island_and_exclusion(ctx);
	struct add_first_task__lambda0* temp0;
	uint8_t* _2 = alloc(ctx, sizeof(struct add_first_task__lambda0));
	temp0 = (struct add_first_task__lambda0*) _2;
	
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
	temp0 = (struct then_void__lambda0*) _1;
	
	*temp0 = (struct then_void__lambda0) {cb};
	return then(ctx, a, (struct fun_ref1) {_0, (struct fun_act1_3) {0, .as0 = temp0}});
}
/* then<?out, void> fut<nat>(a fut<void>, cb fun-ref1<nat, void>) */
struct fut_0* then(struct ctx* ctx, struct fut_1* a, struct fun_ref1 cb) {
	struct fut_0* res0;
	res0 = unresolved(ctx);
	
	struct then__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct then__lambda0));
	temp0 = (struct then__lambda0*) _0;
	
	*temp0 = (struct then__lambda0) {cb, res0};
	callback__e_0(ctx, a, (struct fun_act1_2) {0, .as0 = temp0});
	return res0;
}
/* unresolved<?out> fut<nat>() */
struct fut_0* unresolved(struct ctx* ctx) {
	struct fut_0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct fut_0));
	temp0 = (struct fut_0*) _0;
	
	struct lock _1 = lock_by_val();
	*temp0 = (struct fut_0) {_1, (struct fut_state_0) {0, .as0 = (struct fut_state_no_callbacks) {}}};
	return temp0;
}
/* callback!<?in> void(f fut<void>, cb fun-act1<void, result<void, exception>>) */
struct void_ callback__e_0(struct ctx* ctx, struct fut_1* f, struct fun_act1_2 cb) {
	struct callback__e_0__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct callback__e_0__lambda0));
	temp0 = (struct callback__e_0__lambda0*) _0;
	
	*temp0 = (struct callback__e_0__lambda0) {f, cb};
	return with_lock_0(ctx, (&f->lk), (struct fun_act0_0) {0, .as0 = temp0});
}
/* with-lock<void> void(a lock, f fun-act0<void>) */
struct void_ with_lock_0(struct ctx* ctx, struct lock* a, struct fun_act0_0 f) {
	acquire__e(a);
	struct void_ res0;
	res0 = subscript_7(ctx, f);
	
	release__e(a);
	return res0;
}
/* subscript<?a> void(a fun-act0<void>) */
struct void_ subscript_7(struct ctx* ctx, struct fun_act0_0 a) {
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
			struct subscript_11__lambda0__lambda0* closure2 = _0.as2;
			
			return subscript_11__lambda0__lambda0(ctx, closure2);
		}
		case 3: {
			struct subscript_11__lambda0* closure3 = _0.as3;
			
			return subscript_11__lambda0(ctx, closure3);
		}
		case 4: {
			struct subscript_16__lambda0__lambda0* closure4 = _0.as4;
			
			return subscript_16__lambda0__lambda0(ctx, closure4);
		}
		case 5: {
			struct subscript_16__lambda0* closure5 = _0.as5;
			
			return subscript_16__lambda0(ctx, closure5);
		}
		default:
			return (struct void_) {};
	}
}
/* subscript<void, result<?a, exception>> void(a fun-act1<void, result<void, exception>>, p0 result<void, exception>) */
struct void_ subscript_8(struct ctx* ctx, struct fun_act1_2 a, struct result_1 p0) {
	return call_w_ctx_175(a, ctx, p0);
}
/* call-w-ctx<void, result<void, exception>> (generated) (generated) */
struct void_ call_w_ctx_175(struct fun_act1_2 a, struct ctx* ctx, struct result_1 p0) {
	struct fun_act1_2 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct then__lambda0* closure0 = _0.as0;
			
			return then__lambda0(ctx, closure0, p0);
		}
		default:
			return (struct void_) {};
	}
}
/* callback!<?in>.lambda0 void() */
struct void_ callback__e_0__lambda0(struct ctx* ctx, struct callback__e_0__lambda0* _closure) {
	struct fut_state_1 _0 = _closure->f->state;
	switch (_0.kind) {
		case 0: {
			struct fut_state_callbacks_1* temp0;
			uint8_t* _1 = alloc(ctx, sizeof(struct fut_state_callbacks_1));
			temp0 = (struct fut_state_callbacks_1*) _1;
			
			*temp0 = (struct fut_state_callbacks_1) {_closure->cb, (struct opt_7) {0, .as0 = (struct none) {}}};
			return (_closure->f->state = (struct fut_state_1) {1, .as1 = temp0}, (struct void_) {});
		}
		case 1: {
			struct fut_state_callbacks_1* cbs0 = _0.as1;
			
			struct fut_state_callbacks_1* temp1;
			uint8_t* _2 = alloc(ctx, sizeof(struct fut_state_callbacks_1));
			temp1 = (struct fut_state_callbacks_1*) _2;
			
			*temp1 = (struct fut_state_callbacks_1) {_closure->cb, (struct opt_7) {1, .as1 = (struct some_7) {cbs0}}};
			return (_closure->f->state = (struct fut_state_1) {1, .as1 = temp1}, (struct void_) {});
		}
		case 2: {
			struct fut_state_resolved_1 r1 = _0.as2;
			
			return subscript_8(ctx, _closure->cb, (struct result_1) {0, .as0 = (struct ok_1) {r1.value}});
		}
		case 3: {
			struct exception e2 = _0.as3;
			
			return subscript_8(ctx, _closure->cb, (struct result_1) {1, .as1 = (struct err) {e2}});
		}
		default:
			return (struct void_) {};
	}
}
/* forward-to!<?out> void(from fut<nat>, to fut<nat>) */
struct void_ forward_to__e(struct ctx* ctx, struct fut_0* from, struct fut_0* to) {
	struct forward_to__e__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct forward_to__e__lambda0));
	temp0 = (struct forward_to__e__lambda0*) _0;
	
	*temp0 = (struct forward_to__e__lambda0) {to};
	return callback__e_1(ctx, from, (struct fun_act1_0) {0, .as0 = temp0});
}
/* callback!<?a> void(f fut<nat>, cb fun-act1<void, result<nat, exception>>) */
struct void_ callback__e_1(struct ctx* ctx, struct fut_0* f, struct fun_act1_0 cb) {
	struct callback__e_1__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct callback__e_1__lambda0));
	temp0 = (struct callback__e_1__lambda0*) _0;
	
	*temp0 = (struct callback__e_1__lambda0) {f, cb};
	return with_lock_0(ctx, (&f->lk), (struct fun_act0_0) {1, .as1 = temp0});
}
/* subscript<void, result<?a, exception>> void(a fun-act1<void, result<nat, exception>>, p0 result<nat, exception>) */
struct void_ subscript_9(struct ctx* ctx, struct fun_act1_0 a, struct result_0 p0) {
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
			return (struct void_) {};
	}
}
/* callback!<?a>.lambda0 void() */
struct void_ callback__e_1__lambda0(struct ctx* ctx, struct callback__e_1__lambda0* _closure) {
	struct fut_state_0 _0 = _closure->f->state;
	switch (_0.kind) {
		case 0: {
			struct fut_state_callbacks_0* temp0;
			uint8_t* _1 = alloc(ctx, sizeof(struct fut_state_callbacks_0));
			temp0 = (struct fut_state_callbacks_0*) _1;
			
			*temp0 = (struct fut_state_callbacks_0) {_closure->cb, (struct opt_0) {0, .as0 = (struct none) {}}};
			return (_closure->f->state = (struct fut_state_0) {1, .as1 = temp0}, (struct void_) {});
		}
		case 1: {
			struct fut_state_callbacks_0* cbs0 = _0.as1;
			
			struct fut_state_callbacks_0* temp1;
			uint8_t* _2 = alloc(ctx, sizeof(struct fut_state_callbacks_0));
			temp1 = (struct fut_state_callbacks_0*) _2;
			
			*temp1 = (struct fut_state_callbacks_0) {_closure->cb, (struct opt_0) {1, .as1 = (struct some_0) {cbs0}}};
			return (_closure->f->state = (struct fut_state_0) {1, .as1 = temp1}, (struct void_) {});
		}
		case 2: {
			struct fut_state_resolved_0 r1 = _0.as2;
			
			return subscript_9(ctx, _closure->cb, (struct result_0) {0, .as0 = (struct ok_0) {r1.value}});
		}
		case 3: {
			struct exception e2 = _0.as3;
			
			return subscript_9(ctx, _closure->cb, (struct result_0) {1, .as1 = (struct err) {e2}});
		}
		default:
			return (struct void_) {};
	}
}
/* resolve-or-reject!<?a> void(f fut<nat>, result result<nat, exception>) */
struct void_ resolve_or_reject__e(struct ctx* ctx, struct fut_0* f, struct result_0 result) {
	struct fut_state_0 old_state0;
	struct resolve_or_reject__e__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct resolve_or_reject__e__lambda0));
	temp0 = (struct resolve_or_reject__e__lambda0*) _0;
	
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
			return (struct void_) {};
	}
}
/* with-lock<fut-state<?a>> fut-state<nat>(a lock, f fun-act0<fut-state<nat>>) */
struct fut_state_0 with_lock_1(struct ctx* ctx, struct lock* a, struct fun_act0_2 f) {
	acquire__e(a);
	struct fut_state_0 res0;
	res0 = subscript_10(ctx, f);
	
	release__e(a);
	return res0;
}
/* subscript<?a> fut-state<nat>(a fun-act0<fut-state<nat>>) */
struct fut_state_0 subscript_10(struct ctx* ctx, struct fun_act0_2 a) {
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
			return (struct fut_state_0) {0};
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
			(struct fut_state_0) {0};
	}
	_closure->f->state = _1;
	return old0;
}
/* call-callbacks!<?a> void(cbs fut-state-callbacks<nat>, value result<nat, exception>) */
struct void_ call_callbacks__e(struct ctx* ctx, struct fut_state_callbacks_0* cbs, struct result_0 value) {
	top:;
	subscript_9(ctx, cbs->cb, value);
	struct opt_0 _0 = cbs->next;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct some_0 s0 = _0.as1;
			
			cbs = s0.value;
			value = value;
			goto top;
		}
		default:
			return (struct void_) {};
	}
}
/* forward-to!<?out>.lambda0 void(it result<nat, exception>) */
struct void_ forward_to__e__lambda0(struct ctx* ctx, struct forward_to__e__lambda0* _closure, struct result_0 it) {
	return resolve_or_reject__e(ctx, _closure->to, it);
}
/* subscript<?out, ?in> fut<nat>(f fun-ref1<nat, void>, p0 void) */
struct fut_0* subscript_11(struct ctx* ctx, struct fun_ref1 f, struct void_ p0) {
	struct island* island0;
	island0 = get_island(ctx, f.island_and_exclusion.island);
	
	struct fut_0* res1;
	res1 = unresolved(ctx);
	
	struct subscript_11__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct subscript_11__lambda0));
	temp0 = (struct subscript_11__lambda0*) _0;
	
	*temp0 = (struct subscript_11__lambda0) {f, p0, res1};
	add_task_0(ctx, island0, f.island_and_exclusion.exclusion, (struct fun_act0_0) {3, .as3 = temp0});
	return res1;
}
/* get-island island(island-id nat) */
struct island* get_island(struct ctx* ctx, uint64_t island_id) {
	struct global_ctx* _0 = get_global_ctx(ctx);
	return subscript_12(ctx, _0->islands, island_id);
}
/* subscript<island> island(a arr<island>, index nat) */
struct island* subscript_12(struct ctx* ctx, struct arr_3 a, uint64_t index) {
	uint8_t _0 = _less(index, a.size);
	assert(ctx, _0);
	return noctx_at_1(a, index);
}
/* noctx-at<?a> island(a arr<island>, index nat) */
struct island* noctx_at_1(struct arr_3 a, uint64_t index) {
	uint8_t _0 = _less(index, a.size);
	hard_assert(_0);
	return subscript_13(a.begin_ptr, index);
}
/* subscript<?a> island(a ptr<island>, n nat) */
struct island* subscript_13(struct island** a, uint64_t n) {
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
	temp0 = (struct task_queue_node*) _0;
	
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
			struct some_2 s1 = _0.as1;
			
			struct task_queue_node* head2;
			head2 = s1.value;
			
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
			(struct void_) {};
	}
	uint64_t size_after3;
	size_after3 = size_1(a);
	
	uint8_t _2 = _equal_0((size_before0 + 1u), size_after3);
	return hard_assert(_2);
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
			struct some_2 s0 = _0.as1;
			
			node = s0.value->next;
			acc = (acc + 1u);
			goto top;
		}
		default:
			return 0;
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
			struct some_2 s0 = _0.as1;
			
			struct task_queue_node* cur1;
			cur1 = s0.value;
			
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
			return (struct void_) {};
	}
}
/* tasks task-queue(a island) */
struct task_queue* tasks(struct island* a) {
	return (&(&a->gc_root)->tasks);
}
/* broadcast! void(c condition) */
struct void_ broadcast__e(struct condition* c) {
	acquire__e((&c->lk));
	uint64_t _0 = noctx_incr(c->value);
	c->value = _0;
	return release__e((&c->lk));
}
/* no-timestamp nat() */
uint64_t no_timestamp(void) {
	return 0u;
}
/* catch<void> void(try fun-act0<void>, catcher fun-act1<void, exception>) */
struct void_ catch(struct ctx* ctx, struct fun_act0_0 try, struct fun_act1_4 catcher) {
	struct exception_ctx* _0 = get_exception_ctx(ctx);
	return catch_with_exception_ctx(ctx, _0, try, catcher);
}
/* catch-with-exception-ctx<?a> void(ec exception-ctx, try fun-act0<void>, catcher fun-act1<void, exception>) */
struct void_ catch_with_exception_ctx(struct ctx* ctx, struct exception_ctx* ec, struct fun_act0_0 try, struct fun_act1_4 catcher) {
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
	
	uint8_t _2 = _equal_2(setjmp_result3, 0);
	if (_2) {
		struct void_ res4;
		res4 = subscript_7(ctx, try);
		
		ec->jmp_buf_ptr = old_jmp_buf1;
		ec->thrown_exception = old_thrown_exception0;
		return res4;
	} else {
		int32_t _3 = number_to_throw(ctx);
		uint8_t _4 = _equal_2(setjmp_result3, _3);
		hard_assert(_4);
		struct exception thrown_exception5;
		thrown_exception5 = ec->thrown_exception;
		
		ec->jmp_buf_ptr = old_jmp_buf1;
		ec->thrown_exception = old_thrown_exception0;
		return subscript_14(ctx, catcher, thrown_exception5);
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
struct void_ subscript_14(struct ctx* ctx, struct fun_act1_4 a, struct exception p0) {
	return call_w_ctx_212(a, ctx, p0);
}
/* call-w-ctx<void, exception> (generated) (generated) */
struct void_ call_w_ctx_212(struct fun_act1_4 a, struct ctx* ctx, struct exception p0) {
	struct fun_act1_4 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct subscript_11__lambda0__lambda1* closure0 = _0.as0;
			
			return subscript_11__lambda0__lambda1(ctx, closure0, p0);
		}
		case 1: {
			struct subscript_16__lambda0__lambda1* closure1 = _0.as1;
			
			return subscript_16__lambda0__lambda1(ctx, closure1, p0);
		}
		default:
			return (struct void_) {};
	}
}
/* subscript<fut<?r>, ?p0> fut<nat>(a fun-act1<fut<nat>, void>, p0 void) */
struct fut_0* subscript_15(struct ctx* ctx, struct fun_act1_3 a, struct void_ p0) {
	return call_w_ctx_214(a, ctx, p0);
}
/* call-w-ctx<gc-ptr(fut<nat>), void> (generated) (generated) */
struct fut_0* call_w_ctx_214(struct fun_act1_3 a, struct ctx* ctx, struct void_ p0) {
	struct fun_act1_3 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct then_void__lambda0* closure0 = _0.as0;
			
			return then_void__lambda0(ctx, closure0, p0);
		}
		default:
			return NULL;
	}
}
/* subscript<?out, ?in>.lambda0.lambda0 void() */
struct void_ subscript_11__lambda0__lambda0(struct ctx* ctx, struct subscript_11__lambda0__lambda0* _closure) {
	struct fut_0* _0 = subscript_15(ctx, _closure->f.fun, _closure->p0);
	return forward_to__e(ctx, _0, _closure->res);
}
/* reject!<?r> void(f fut<nat>, e exception) */
struct void_ reject__e(struct ctx* ctx, struct fut_0* f, struct exception e) {
	return resolve_or_reject__e(ctx, f, (struct result_0) {1, .as1 = (struct err) {e}});
}
/* subscript<?out, ?in>.lambda0.lambda1 void(it exception) */
struct void_ subscript_11__lambda0__lambda1(struct ctx* ctx, struct subscript_11__lambda0__lambda1* _closure, struct exception it) {
	return reject__e(ctx, _closure->res, it);
}
/* subscript<?out, ?in>.lambda0 void() */
struct void_ subscript_11__lambda0(struct ctx* ctx, struct subscript_11__lambda0* _closure) {
	struct subscript_11__lambda0__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct subscript_11__lambda0__lambda0));
	temp0 = (struct subscript_11__lambda0__lambda0*) _0;
	
	*temp0 = (struct subscript_11__lambda0__lambda0) {_closure->f, _closure->p0, _closure->res};
	struct subscript_11__lambda0__lambda1* temp1;
	uint8_t* _1 = alloc(ctx, sizeof(struct subscript_11__lambda0__lambda1));
	temp1 = (struct subscript_11__lambda0__lambda1*) _1;
	
	*temp1 = (struct subscript_11__lambda0__lambda1) {_closure->res};
	return catch(ctx, (struct fun_act0_0) {2, .as2 = temp0}, (struct fun_act1_4) {0, .as0 = temp1});
}
/* then<?out, void>.lambda0 void(result result<void, exception>) */
struct void_ then__lambda0(struct ctx* ctx, struct then__lambda0* _closure, struct result_1 result) {
	struct result_1 _0 = result;
	switch (_0.kind) {
		case 0: {
			struct ok_1 o0 = _0.as0;
			
			struct fut_0* _1 = subscript_11(ctx, _closure->cb, o0.value);
			return forward_to__e(ctx, _1, _closure->res);
		}
		case 1: {
			struct err e1 = _0.as1;
			
			return reject__e(ctx, _closure->res, e1.value);
		}
		default:
			return (struct void_) {};
	}
}
/* subscript<?out> fut<nat>(f fun-ref0<nat>) */
struct fut_0* subscript_16(struct ctx* ctx, struct fun_ref0 f) {
	struct fut_0* res0;
	res0 = unresolved(ctx);
	
	struct island* _0 = get_island(ctx, f.island_and_exclusion.island);
	struct subscript_16__lambda0* temp0;
	uint8_t* _1 = alloc(ctx, sizeof(struct subscript_16__lambda0));
	temp0 = (struct subscript_16__lambda0*) _1;
	
	*temp0 = (struct subscript_16__lambda0) {f, res0};
	add_task_0(ctx, _0, f.island_and_exclusion.exclusion, (struct fun_act0_0) {5, .as5 = temp0});
	return res0;
}
/* subscript<fut<?r>> fut<nat>(a fun-act0<fut<nat>>) */
struct fut_0* subscript_17(struct ctx* ctx, struct fun_act0_1 a) {
	return call_w_ctx_222(a, ctx);
}
/* call-w-ctx<gc-ptr(fut<nat>)> (generated) (generated) */
struct fut_0* call_w_ctx_222(struct fun_act0_1 a, struct ctx* ctx) {
	struct fun_act0_1 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct add_first_task__lambda0* closure0 = _0.as0;
			
			return add_first_task__lambda0(ctx, closure0);
		}
		default:
			return NULL;
	}
}
/* subscript<?out>.lambda0.lambda0 void() */
struct void_ subscript_16__lambda0__lambda0(struct ctx* ctx, struct subscript_16__lambda0__lambda0* _closure) {
	struct fut_0* _0 = subscript_17(ctx, _closure->f.fun);
	return forward_to__e(ctx, _0, _closure->res);
}
/* subscript<?out>.lambda0.lambda1 void(it exception) */
struct void_ subscript_16__lambda0__lambda1(struct ctx* ctx, struct subscript_16__lambda0__lambda1* _closure, struct exception it) {
	return reject__e(ctx, _closure->res, it);
}
/* subscript<?out>.lambda0 void() */
struct void_ subscript_16__lambda0(struct ctx* ctx, struct subscript_16__lambda0* _closure) {
	struct subscript_16__lambda0__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct subscript_16__lambda0__lambda0));
	temp0 = (struct subscript_16__lambda0__lambda0*) _0;
	
	*temp0 = (struct subscript_16__lambda0__lambda0) {_closure->f, _closure->res};
	struct subscript_16__lambda0__lambda1* temp1;
	uint8_t* _1 = alloc(ctx, sizeof(struct subscript_16__lambda0__lambda1));
	temp1 = (struct subscript_16__lambda0__lambda1*) _1;
	
	*temp1 = (struct subscript_16__lambda0__lambda1) {_closure->res};
	return catch(ctx, (struct fun_act0_0) {4, .as4 = temp0}, (struct fun_act1_4) {1, .as1 = temp1});
}
/* then-void<nat>.lambda0 fut<nat>(ignore void) */
struct fut_0* then_void__lambda0(struct ctx* ctx, struct then_void__lambda0* _closure, struct void_ ignore) {
	return subscript_16(ctx, _closure->cb);
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
	temp0 = (struct fut_1*) _0;
	
	struct lock _1 = lock_by_val();
	*temp0 = (struct fut_1) {_1, (struct fut_state_1) {2, .as2 = (struct fut_state_resolved_1) {value}}};
	return temp0;
}
/* tail<ptr<char>> arr<ptr<char>>(a arr<ptr<char>>) */
struct arr_4 tail_1(struct ctx* ctx, struct arr_4 a) {
	uint8_t _0 = empty__q_2(a);
	forbid_0(ctx, _0);
	struct arrow _1 = _arrow(ctx, 1u, a.size);
	return subscript_18(ctx, a, _1);
}
/* empty?<?a> bool(a arr<ptr<char>>) */
uint8_t empty__q_2(struct arr_4 a) {
	return _equal_0(a.size, 0u);
}
/* subscript<?a> arr<ptr<char>>(a arr<ptr<char>>, range arrow<nat, nat>) */
struct arr_4 subscript_18(struct ctx* ctx, struct arr_4 a, struct arrow range) {
	uint8_t _0 = _lessOrEqual(range.from, range.to);
	assert(ctx, _0);
	uint8_t _1 = _lessOrEqual(range.to, a.size);
	assert(ctx, _1);
	uint64_t _2 = _minus_2(ctx, range.to, range.from);
	return (struct arr_4) {_2, (a.begin_ptr + range.from)};
}
/* map<arr<char>, ptr<char>> arr<arr<char>>(a arr<ptr<char>>, f fun-act1<arr<char>, ptr<char>>) */
struct arr_1 map(struct ctx* ctx, struct arr_4 a, struct fun_act1_5 f) {
	struct map__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct map__lambda0));
	temp0 = (struct map__lambda0*) _0;
	
	*temp0 = (struct map__lambda0) {f, a};
	return make_arr(ctx, a.size, (struct fun_act1_6) {0, .as0 = temp0});
}
/* make-arr<?out> arr<arr<char>>(size nat, f fun-act1<arr<char>, nat>) */
struct arr_1 make_arr(struct ctx* ctx, uint64_t size, struct fun_act1_6 f) {
	struct arr_0* res0;
	res0 = alloc_uninitialized_1(ctx, size);
	
	fill_ptr_range(ctx, res0, size, f);
	return (struct arr_1) {size, res0};
}
/* alloc-uninitialized<?a> ptr<arr<char>>(size nat) */
struct arr_0* alloc_uninitialized_1(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(struct arr_0)));
	return (struct arr_0*) _0;
}
/* fill-ptr-range<?a> void(begin ptr<arr<char>>, size nat, f fun-act1<arr<char>, nat>) */
struct void_ fill_ptr_range(struct ctx* ctx, struct arr_0* begin, uint64_t size, struct fun_act1_6 f) {
	return fill_ptr_range_recur(ctx, begin, 0u, size, f);
}
/* fill-ptr-range-recur<?a> void(begin ptr<arr<char>>, i nat, size nat, f fun-act1<arr<char>, nat>) */
struct void_ fill_ptr_range_recur(struct ctx* ctx, struct arr_0* begin, uint64_t i, uint64_t size, struct fun_act1_6 f) {
	top:;
	uint8_t _0 = _notEqual_1(i, size);
	if (_0) {
		struct arr_0 _1 = subscript_19(ctx, f, i);
		set_subscript_1(begin, i, _1);
		uint64_t _2 = noctx_incr(i);
		begin = begin;
		i = _2;
		size = size;
		f = f;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* subscript<?a, nat> arr<char>(a fun-act1<arr<char>, nat>, p0 nat) */
struct arr_0 subscript_19(struct ctx* ctx, struct fun_act1_6 a, uint64_t p0) {
	return call_w_ctx_239(a, ctx, p0);
}
/* call-w-ctx<arr<char>, nat-64> (generated) (generated) */
struct arr_0 call_w_ctx_239(struct fun_act1_6 a, struct ctx* ctx, uint64_t p0) {
	struct fun_act1_6 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct map__lambda0* closure0 = _0.as0;
			
			return map__lambda0(ctx, closure0, p0);
		}
		default:
			return (struct arr_0) {0, NULL};
	}
}
/* subscript<?out, ?in> arr<char>(a fun-act1<arr<char>, ptr<char>>, p0 ptr<char>) */
struct arr_0 subscript_20(struct ctx* ctx, struct fun_act1_5 a, char* p0) {
	return call_w_ctx_241(a, ctx, p0);
}
/* call-w-ctx<arr<char>, raw-ptr(char)> (generated) (generated) */
struct arr_0 call_w_ctx_241(struct fun_act1_5 a, struct ctx* ctx, char* p0) {
	struct fun_act1_5 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return add_first_task__lambda0__lambda0(ctx, closure0, p0);
		}
		default:
			return (struct arr_0) {0, NULL};
	}
}
/* subscript<?in> ptr<char>(a arr<ptr<char>>, index nat) */
char* subscript_21(struct ctx* ctx, struct arr_4 a, uint64_t index) {
	uint8_t _0 = _less(index, a.size);
	assert(ctx, _0);
	return noctx_at_2(a, index);
}
/* noctx-at<?a> ptr<char>(a arr<ptr<char>>, index nat) */
char* noctx_at_2(struct arr_4 a, uint64_t index) {
	uint8_t _0 = _less(index, a.size);
	hard_assert(_0);
	return subscript_22(a.begin_ptr, index);
}
/* subscript<?a> ptr<char>(a ptr<ptr<char>>, n nat) */
char* subscript_22(char** a, uint64_t n) {
	return (*(a + n));
}
/* map<arr<char>, ptr<char>>.lambda0 arr<char>(i nat) */
struct arr_0 map__lambda0(struct ctx* ctx, struct map__lambda0* _closure, uint64_t i) {
	char* _0 = subscript_21(ctx, _closure->a, i);
	return subscript_20(ctx, _closure->f, _0);
}
/* to-str arr<char>(a ptr<char>) */
struct arr_0 to_str_2(char* a) {
	char* _0 = find_cstr_end(a);
	return arr_from_begin_end(a, _0);
}
/* arr-from-begin-end<char> arr<char>(begin ptr<char>, end ptr<char>) */
struct arr_0 arr_from_begin_end(char* begin, char* end) {
	uint8_t _0 = ptr_less_eq__q_2(begin, end);
	hard_assert(_0);
	uint64_t _1 = _minus_3(end, begin);
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
uint64_t _minus_3(char* a, char* b) {
	return (((uint64_t) a - (uint64_t) b) / sizeof(char));
}
/* find-cstr-end ptr<char>(a ptr<char>) */
char* find_cstr_end(char* a) {
	struct opt_8 _0 = find_char_in_cstr(a, 0u);
	switch (_0.kind) {
		case 0: {
			return hard_unreachable_1();
		}
		case 1: {
			struct some_8 s0 = _0.as1;
			
			return s0.value;
		}
		default:
			return NULL;
	}
}
/* find-char-in-cstr opt<ptr<char>>(a ptr<char>, c char) */
struct opt_8 find_char_in_cstr(char* a, char c) {
	top:;
	uint8_t _0 = _equal_3((*a), c);
	if (_0) {
		return (struct opt_8) {1, .as1 = (struct some_8) {a}};
	} else {
		uint8_t _1 = _equal_3((*a), 0u);
		if (_1) {
			return (struct opt_8) {0, .as0 = (struct none) {}};
		} else {
			a = (a + 1u);
			c = c;
			goto top;
		}
	}
}
/* ==<char> bool(a char, b char) */
uint8_t _equal_3(char a, char b) {
	struct comparison _0 = compare_253(a, b);
	switch (_0.kind) {
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
			return 0;
	}
}
/* compare<char> (generated) (generated) */
struct comparison compare_253(char a, char b) {
	uint8_t _0 = (a < b);
	if (_0) {
		return (struct comparison) {0, .as0 = (struct less) {}};
	} else {
		uint8_t _1 = (b < a);
		if (_1) {
			return (struct comparison) {2, .as2 = (struct greater) {}};
		} else {
			return (struct comparison) {1, .as1 = (struct equal) {}};
		}
	}
}
/* hard-unreachable<ptr<char>> ptr<char>() */
char* hard_unreachable_1(void) {
	(abort(), (struct void_) {});
	return NULL;
}
/* add-first-task.lambda0.lambda0 arr<char>(it ptr<char>) */
struct arr_0 add_first_task__lambda0__lambda0(struct ctx* ctx, struct void_ _closure, char* it) {
	return to_str_2(it);
}
/* add-first-task.lambda0 fut<nat>() */
struct fut_0* add_first_task__lambda0(struct ctx* ctx, struct add_first_task__lambda0* _closure) {
	struct arr_4 args0;
	args0 = tail_1(ctx, _closure->all_args);
	
	struct arr_1 _0 = map(ctx, args0, (struct fun_act1_5) {0, .as0 = (struct void_) {}});
	return _closure->main_ptr(ctx, _0);
}
/* handle-exceptions<nat> void(a fut<nat>) */
struct void_ handle_exceptions(struct ctx* ctx, struct fut_0* a) {
	return callback__e_1(ctx, a, (struct fun_act1_0) {1, .as1 = (struct void_) {}});
}
/* subscript<void, exception> void(a fun1<void, exception>, p0 exception) */
struct void_ subscript_23(struct ctx* ctx, struct fun1_0 a, struct exception p0) {
	return call_w_ctx_259(a, ctx, p0);
}
/* call-w-ctx<void, exception> (generated) (generated) */
struct void_ call_w_ctx_259(struct fun1_0 a, struct ctx* ctx, struct exception p0) {
	struct fun1_0 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return island__lambda0(ctx, closure0, p0);
		}
		default:
			return (struct void_) {};
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
			return subscript_23(ctx, _2, e0.value);
		}
		default:
			return (struct void_) {};
	}
}
/* do-main.lambda0 fut<nat>(all-args arr<ptr<char>>, main-ptr fun-ptr2<fut<nat>, ctx, arr<arr<char>>>) */
struct fut_0* do_main__lambda0(struct ctx* ctx, struct void_ _closure, struct arr_4 all_args, fun_ptr2 main_ptr) {
	return add_first_task(ctx, all_args, main_ptr);
}
/* call-w-ctx<gc-ptr(fut<nat>), arr<ptr<char>>, some fun ptr type> (generated) (generated) */
struct fut_0* call_w_ctx_264(struct fun_act2 a, struct ctx* ctx, struct arr_4 p0, fun_ptr2 p1) {
	struct fun_act2 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return do_main__lambda0(ctx, closure0, p0, p1);
		}
		default:
			return NULL;
	}
}
/* run-threads void(n-threads nat, gctx global-ctx) */
struct void_ run_threads(uint64_t n_threads, struct global_ctx* gctx) {
	uint64_t* threads0;
	threads0 = unmanaged_alloc_elements_0(n_threads);
	
	struct thread_args* thread_args1;
	thread_args1 = unmanaged_alloc_elements_1(n_threads);
	
	uint64_t actual_n_threads2;
	actual_n_threads2 = noctx_decr(n_threads);
	
	start_threads_recur(0u, actual_n_threads2, threads0, thread_args1, gctx);
	thread_function(actual_n_threads2, gctx);
	join_threads_recur(0u, actual_n_threads2, threads0);
	unmanaged_free_0(threads0);
	return unmanaged_free_1(thread_args1);
}
/* unmanaged-alloc-elements<by-val<thread-args>> ptr<thread-args>(size-elements nat) */
struct thread_args* unmanaged_alloc_elements_1(uint64_t size_elements) {
	uint8_t* _0 = unmanaged_alloc_bytes((size_elements * sizeof(struct thread_args)));
	return (struct thread_args*) _0;
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
		uint64_t _2 = noctx_incr(i);
		i = _2;
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
		uint8_t _2 = _equal_2(err0, _1);
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
	uint8_t _0 = _equal_2(a, b);
	return not(_0);
}
/* eagain int32() */
int32_t eagain(void) {
	return 11;
}
/* as-cell<nat> cell<nat>(p ptr<nat>) */
struct cell_0* as_cell(uint64_t* p) {
	return (struct cell_0*) ((uint8_t*) p);
}
/* thread-fun ptr<nat8>(args-ptr ptr<nat8>) */
uint8_t* thread_fun(uint8_t* args_ptr) {
	struct thread_args* args0;
	args0 = (struct thread_args*) args_ptr;
	
	thread_function(args0->thread_id, args0->gctx);
	return NULL;
}
/* thread-function void(thread-id nat, gctx global-ctx) */
struct void_ thread_function(uint64_t thread_id, struct global_ctx* gctx) {
	struct exception_ctx ectx0;
	ectx0 = exception_ctx();
	
	struct log_ctx log_ctx1;
	log_ctx1 = log_ctx();
	
	struct thread_local_stuff tls2;
	tls2 = (struct thread_local_stuff) {(&ectx0), (&log_ctx1)};
	
	return thread_function_recur(thread_id, gctx, (&tls2));
}
/* thread-function-recur void(thread-id nat, gctx global-ctx, tls thread-local-stuff) */
struct void_ thread_function_recur(uint64_t thread_id, struct global_ctx* gctx, struct thread_local_stuff* tls) {
	top:;
	uint8_t _0 = gctx->shut_down__q;
	if (_0) {
		acquire__e((&gctx->lk));
		uint64_t _1 = noctx_decr(gctx->n_live_threads);
		gctx->n_live_threads = _1;
		assert_islands_are_shut_down(0u, gctx->islands);
		return release__e((&gctx->lk));
	} else {
		uint8_t _2 = _greater(gctx->n_live_threads, 0u);
		hard_assert(_2);
		uint64_t last_checked0;
		last_checked0 = get_last_checked((&gctx->may_be_work_to_do));
		
		struct choose_task_result _3 = choose_task(gctx);
		switch (_3.kind) {
			case 0: {
				struct chosen_task t1 = _3.as0;
				
				do_task(gctx, tls, t1);
				break;
			}
			case 1: {
				struct no_chosen_task n2 = _3.as1;
				
				uint8_t _4 = n2.no_tasks_and_last_thread_out__q;
				if (_4) {
					hard_forbid(gctx->shut_down__q);
					gctx->shut_down__q = 1;
					broadcast__e((&gctx->may_be_work_to_do));
				} else {
					wait_on((&gctx->may_be_work_to_do), n2.first_task_time, last_checked0);
				}
				acquire__e((&gctx->lk));
				uint64_t _5 = noctx_incr(gctx->n_live_threads);
				gctx->n_live_threads = _5;
				release__e((&gctx->lk));
				break;
			}
			default:
				(struct void_) {};
		}
		thread_id = thread_id;
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
		island0 = noctx_at_1(islands, i);
		
		acquire__e((&island0->tasks_lock));
		hard_forbid((&island0->gc)->needs_gc__q);
		uint8_t _1 = _equal_0(island0->n_threads_running, 0u);
		hard_assert(_1);
		struct task_queue* _2 = tasks(island0);
		uint8_t _3 = empty__q_3(_2);
		hard_assert(_3);
		release__e((&island0->tasks_lock));
		uint64_t _4 = noctx_incr(i);
		i = _4;
		islands = islands;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* empty? bool(a task-queue) */
uint8_t empty__q_3(struct task_queue* a) {
	struct opt_2 _0 = a->head;
	switch (_0.kind) {
		case 0: {
			return 1;
		}
		case 1: {
			return 0;
		}
		default:
			return 0;
	}
}
/* get-last-checked nat(a condition) */
uint64_t get_last_checked(struct condition* a) {
	return a->value;
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
			
			uint64_t _1 = noctx_decr(gctx->n_live_threads);
			gctx->n_live_threads = _1;
			uint8_t no_task_and_last_thread_out__q3;
			if (n2.no_tasks_and_last_thread_out__q) {
				no_task_and_last_thread_out__q3 = _equal_0(gctx->n_live_threads, 0u);
			} else {
				no_task_and_last_thread_out__q3 = 0;
			}
			
			res4 = (struct choose_task_result) {1, .as1 = (struct no_chosen_task) {no_task_and_last_thread_out__q3, n2.first_task_time}};
			break;
		}
		default:
			(struct choose_task_result) {0};
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
	
	uint8_t _1 = _equal_2(err1, 0);
	if (_1) {
		struct timespec time2;
		time2 = (&time_cell0)->subscript;
		
		return (uint64_t) ((time2.tv_sec * 1000000000) + time2.tv_nsec);
	} else {
		return todo_2();
	}
}
/* clock-monotonic int32() */
int32_t clock_monotonic(void) {
	return 1;
}
/* todo<nat> nat() */
uint64_t todo_2(void) {
	(abort(), (struct void_) {});
	return 0;
}
/* choose-task-recur choose-task-result(islands arr<island>, i nat, cur-time nat, any-tasks? bool, first-task-time opt<nat>) */
struct choose_task_result choose_task_recur(struct arr_3 islands, uint64_t i, uint64_t cur_time, uint8_t any_tasks__q, struct opt_9 first_task_time) {
	top:;
	uint8_t _0 = _equal_0(i, islands.size);
	if (_0) {
		uint8_t _1 = not(any_tasks__q);
		return (struct choose_task_result) {1, .as1 = (struct no_chosen_task) {_1, first_task_time}};
	} else {
		struct island* island0;
		island0 = noctx_at_1(islands, i);
		
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
				
				uint64_t _3 = noctx_incr(i);
				islands = islands;
				i = _3;
				cur_time = cur_time;
				any_tasks__q = new_any_tasks__q4;
				first_task_time = new_first_task_time5;
				goto top;
			}
			default:
				return (struct choose_task_result) {0};
		}
	}
}
/* choose-task-in-island choose-task-in-island-result(island island, cur-time nat) */
struct choose_task_in_island_result choose_task_in_island(struct island* island, uint64_t cur_time) {
	acquire__e((&island->tasks_lock));
	struct choose_task_in_island_result res2;
	uint8_t _0 = (&island->gc)->needs_gc__q;
	if (_0) {
		uint8_t _1 = _equal_0(island->n_threads_running, 0u);
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
				(struct choose_task_in_island_result) {0};
		}
	}
	
	uint8_t _4 = is_no_task__q(res2);
	uint8_t _5 = not(_4);
	if (_5) {
		uint64_t _6 = noctx_incr(island->n_threads_running);
		island->n_threads_running = _6;
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
			struct some_2 s1 = _0.as1;
			
			struct task_queue_node* head2;
			head2 = s1.value;
			
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
			(struct pop_task_result) {0};
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
			(struct void_) {};
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
	uint8_t _0 = _equal_0(i, a.size);
	if (_0) {
		return 0;
	} else {
		uint64_t _1 = noctx_at_3(a, i);
		uint8_t _2 = _equal_0(_1, value);
		if (_2) {
			return 1;
		} else {
			uint64_t _3 = noctx_incr(i);
			a = a;
			value = value;
			i = _3;
			goto top;
		}
	}
}
/* noctx-at<?a> nat(a arr<nat>, index nat) */
uint64_t noctx_at_3(struct arr_2 a, uint64_t index) {
	uint8_t _0 = _less(index, a.size);
	hard_assert(_0);
	return subscript_24(a.begin_ptr, index);
}
/* subscript<?a> nat(a ptr<nat>, n nat) */
uint64_t subscript_24(uint64_t* a, uint64_t n) {
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
			struct some_2 s0 = _0.as1;
			
			struct task_queue_node* cur1;
			cur1 = s0.value;
			
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
							_4 = first_task_time;
							break;
						}
						default:
							(struct opt_9) {0};
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
			return (struct pop_task_result) {0};
	}
}
/* to-opt-time opt<nat>(a nat) */
struct opt_9 to_opt_time(uint64_t a) {
	uint64_t _0 = no_timestamp();
	uint8_t _1 = _equal_0(a, _0);
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
	uint64_t _3 = noctx_incr(a->size);
	return (a->size = _3, (struct void_) {});
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
			return 0;
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
			struct some_9 sa0 = _0.as1;
			
			struct opt_9 _1 = b;
			switch (_1.kind) {
				case 0: {
					return a;
				}
				case 1: {
					struct some_9 sb1 = _1.as1;
					
					uint64_t _2 = min(sa0.value, sb1.value);
					return (struct opt_9) {1, .as1 = (struct some_9) {_2}};
				}
				default:
					return (struct opt_9) {0};
			}
		}
		default:
			return (struct opt_9) {0};
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
			(struct void_) {};
	}
	acquire__e((&island0->tasks_lock));
	uint64_t _2 = noctx_decr(island0->n_threads_running);
	island0->n_threads_running = _2;
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
	uint8_t _0 = _equal_0(index, a->size);
	if (_0) {
		return todo_0();
	} else {
		uint64_t* _1 = begin_ptr_2(a);
		uint64_t _2 = subscript_24(_1, index);
		uint8_t _3 = _equal_0(_2, value);
		if (_3) {
			uint64_t _4 = noctx_remove_unordered_at__e(a, index);
			return drop(_4);
		} else {
			uint64_t _5 = noctx_incr(index);
			a = a;
			index = _5;
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
	res0 = subscript_24(_1, index);
	
	uint64_t new_size1;
	new_size1 = noctx_decr(a->size);
	
	uint64_t* _2 = begin_ptr_2(a);
	uint64_t* _3 = begin_ptr_2(a);
	uint64_t _4 = subscript_24(_3, new_size1);
	set_subscript_3(_2, index, _4);
	a->size = new_size1;
	return res0;
}
/* return-ctx void(c ctx) */
struct void_ return_ctx(struct ctx* c) {
	return return_gc_ctx((struct gc_ctx*) c->gc_ctx_ptr);
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
	gc->needs_gc__q = 0;
	uint64_t _0 = noctx_incr(gc->gc_count);
	gc->gc_count = _0;
	(memset(((uint8_t*) gc->mark_begin), 0u, gc->size_words), (struct void_) {});
	struct mark_ctx mark_ctx0;
	mark_ctx0 = (struct mark_ctx) {gc->size_words, gc->mark_begin, gc->data_begin};
	
	mark_visit_315((&mark_ctx0), gc_root);
	gc->mark_cur = gc->mark_begin;
	gc->data_cur = gc->data_begin;
	clear_free_mem(gc->mark_begin, gc->mark_end, gc->data_begin);
	return validate_gc(gc);
}
/* mark-visit<island-gc-root> (generated) (generated) */
struct void_ mark_visit_315(struct mark_ctx* mark_ctx, struct island_gc_root value) {
	return mark_visit_316(mark_ctx, value.tasks);
}
/* mark-visit<task-queue> (generated) (generated) */
struct void_ mark_visit_316(struct mark_ctx* mark_ctx, struct task_queue value) {
	mark_visit_317(mark_ctx, value.head);
	return mark_visit_369(mark_ctx, value.currently_running_exclusions);
}
/* mark-visit<opt<task-queue-node>> (generated) (generated) */
struct void_ mark_visit_317(struct mark_ctx* mark_ctx, struct opt_2 value) {
	struct opt_2 _0 = value;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct some_2 value1 = _0.as1;
			
			return mark_visit_318(mark_ctx, value1);
		}
		default:
			return (struct void_) {};
	}
}
/* mark-visit<some<task-queue-node>> (generated) (generated) */
struct void_ mark_visit_318(struct mark_ctx* mark_ctx, struct some_2 value) {
	return mark_visit_368(mark_ctx, value.value);
}
/* mark-visit<task-queue-node> (generated) (generated) */
struct void_ mark_visit_319(struct mark_ctx* mark_ctx, struct task_queue_node value) {
	mark_visit_320(mark_ctx, value.task);
	return mark_visit_317(mark_ctx, value.next);
}
/* mark-visit<task> (generated) (generated) */
struct void_ mark_visit_320(struct mark_ctx* mark_ctx, struct task value) {
	return mark_visit_321(mark_ctx, value.action);
}
/* mark-visit<fun-act0<void>> (generated) (generated) */
struct void_ mark_visit_321(struct mark_ctx* mark_ctx, struct fun_act0_0 value) {
	struct fun_act0_0 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct callback__e_0__lambda0* value0 = _0.as0;
			
			return mark_visit_357(mark_ctx, value0);
		}
		case 1: {
			struct callback__e_1__lambda0* value1 = _0.as1;
			
			return mark_visit_359(mark_ctx, value1);
		}
		case 2: {
			struct subscript_11__lambda0__lambda0* value2 = _0.as2;
			
			return mark_visit_361(mark_ctx, value2);
		}
		case 3: {
			struct subscript_11__lambda0* value3 = _0.as3;
			
			return mark_visit_363(mark_ctx, value3);
		}
		case 4: {
			struct subscript_16__lambda0__lambda0* value4 = _0.as4;
			
			return mark_visit_365(mark_ctx, value4);
		}
		case 5: {
			struct subscript_16__lambda0* value5 = _0.as5;
			
			return mark_visit_367(mark_ctx, value5);
		}
		default:
			return (struct void_) {};
	}
}
/* mark-visit<callback!<?in>.lambda0> (generated) (generated) */
struct void_ mark_visit_322(struct mark_ctx* mark_ctx, struct callback__e_0__lambda0 value) {
	mark_visit_356(mark_ctx, value.f);
	return mark_visit_326(mark_ctx, value.cb);
}
/* mark-visit<fut<void>> (generated) (generated) */
struct void_ mark_visit_323(struct mark_ctx* mark_ctx, struct fut_1 value) {
	return mark_visit_324(mark_ctx, value.state);
}
/* mark-visit<fut-state<void>> (generated) (generated) */
struct void_ mark_visit_324(struct mark_ctx* mark_ctx, struct fut_state_1 value) {
	struct fut_state_1 _0 = value;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct fut_state_callbacks_1* value1 = _0.as1;
			
			return mark_visit_355(mark_ctx, value1);
		}
		case 2: {
			return (struct void_) {};
		}
		case 3: {
			struct exception value3 = _0.as3;
			
			return mark_visit_347(mark_ctx, value3);
		}
		default:
			return (struct void_) {};
	}
}
/* mark-visit<fut-state-callbacks<void>> (generated) (generated) */
struct void_ mark_visit_325(struct mark_ctx* mark_ctx, struct fut_state_callbacks_1 value) {
	mark_visit_326(mark_ctx, value.cb);
	return mark_visit_353(mark_ctx, value.next);
}
/* mark-visit<fun-act1<void, result<void, exception>>> (generated) (generated) */
struct void_ mark_visit_326(struct mark_ctx* mark_ctx, struct fun_act1_2 value) {
	struct fun_act1_2 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct then__lambda0* value0 = _0.as0;
			
			return mark_visit_352(mark_ctx, value0);
		}
		default:
			return (struct void_) {};
	}
}
/* mark-visit<then<?out, void>.lambda0> (generated) (generated) */
struct void_ mark_visit_327(struct mark_ctx* mark_ctx, struct then__lambda0 value) {
	mark_visit_328(mark_ctx, value.cb);
	return mark_visit_342(mark_ctx, value.res);
}
/* mark-visit<fun-ref1<nat, void>> (generated) (generated) */
struct void_ mark_visit_328(struct mark_ctx* mark_ctx, struct fun_ref1 value) {
	return mark_visit_329(mark_ctx, value.fun);
}
/* mark-visit<fun-act1<fut<nat>, void>> (generated) (generated) */
struct void_ mark_visit_329(struct mark_ctx* mark_ctx, struct fun_act1_3 value) {
	struct fun_act1_3 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct then_void__lambda0* value0 = _0.as0;
			
			return mark_visit_336(mark_ctx, value0);
		}
		default:
			return (struct void_) {};
	}
}
/* mark-visit<then-void<nat>.lambda0> (generated) (generated) */
struct void_ mark_visit_330(struct mark_ctx* mark_ctx, struct then_void__lambda0 value) {
	return mark_visit_331(mark_ctx, value.cb);
}
/* mark-visit<fun-ref0<nat>> (generated) (generated) */
struct void_ mark_visit_331(struct mark_ctx* mark_ctx, struct fun_ref0 value) {
	return mark_visit_332(mark_ctx, value.fun);
}
/* mark-visit<fun-act0<fut<nat>>> (generated) (generated) */
struct void_ mark_visit_332(struct mark_ctx* mark_ctx, struct fun_act0_1 value) {
	struct fun_act0_1 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct add_first_task__lambda0* value0 = _0.as0;
			
			return mark_visit_335(mark_ctx, value0);
		}
		default:
			return (struct void_) {};
	}
}
/* mark-visit<add-first-task.lambda0> (generated) (generated) */
struct void_ mark_visit_333(struct mark_ctx* mark_ctx, struct add_first_task__lambda0 value) {
	return mark_arr_334(mark_ctx, value.all_args);
}
/* mark-arr<raw-ptr(char)> (generated) (generated) */
struct void_ mark_arr_334(struct mark_ctx* mark_ctx, struct arr_4 a) {
	uint8_t dropped0;
	dropped0 = mark(mark_ctx, ((uint8_t*) a.begin_ptr), (a.size * sizeof(char*)));
	
	return (struct void_) {};
}
/* mark-visit<gc-ptr(add-first-task.lambda0)> (generated) (generated) */
struct void_ mark_visit_335(struct mark_ctx* mark_ctx, struct add_first_task__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct add_first_task__lambda0));
	if (_0) {
		return mark_visit_333(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(then-void<nat>.lambda0)> (generated) (generated) */
struct void_ mark_visit_336(struct mark_ctx* mark_ctx, struct then_void__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct then_void__lambda0));
	if (_0) {
		return mark_visit_330(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<fut<nat>> (generated) (generated) */
struct void_ mark_visit_337(struct mark_ctx* mark_ctx, struct fut_0 value) {
	return mark_visit_338(mark_ctx, value.state);
}
/* mark-visit<fut-state<nat>> (generated) (generated) */
struct void_ mark_visit_338(struct mark_ctx* mark_ctx, struct fut_state_0 value) {
	struct fut_state_0 _0 = value;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct fut_state_callbacks_0* value1 = _0.as1;
			
			return mark_visit_346(mark_ctx, value1);
		}
		case 2: {
			return (struct void_) {};
		}
		case 3: {
			struct exception value3 = _0.as3;
			
			return mark_visit_347(mark_ctx, value3);
		}
		default:
			return (struct void_) {};
	}
}
/* mark-visit<fut-state-callbacks<nat>> (generated) (generated) */
struct void_ mark_visit_339(struct mark_ctx* mark_ctx, struct fut_state_callbacks_0 value) {
	mark_visit_340(mark_ctx, value.cb);
	return mark_visit_344(mark_ctx, value.next);
}
/* mark-visit<fun-act1<void, result<nat, exception>>> (generated) (generated) */
struct void_ mark_visit_340(struct mark_ctx* mark_ctx, struct fun_act1_0 value) {
	struct fun_act1_0 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct forward_to__e__lambda0* value0 = _0.as0;
			
			return mark_visit_343(mark_ctx, value0);
		}
		case 1: {
			return (struct void_) {};
		}
		default:
			return (struct void_) {};
	}
}
/* mark-visit<forward-to!<?out>.lambda0> (generated) (generated) */
struct void_ mark_visit_341(struct mark_ctx* mark_ctx, struct forward_to__e__lambda0 value) {
	return mark_visit_342(mark_ctx, value.to);
}
/* mark-visit<gc-ptr(fut<nat>)> (generated) (generated) */
struct void_ mark_visit_342(struct mark_ctx* mark_ctx, struct fut_0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct fut_0));
	if (_0) {
		return mark_visit_337(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(forward-to!<?out>.lambda0)> (generated) (generated) */
struct void_ mark_visit_343(struct mark_ctx* mark_ctx, struct forward_to__e__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct forward_to__e__lambda0));
	if (_0) {
		return mark_visit_341(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<opt<fut-state-callbacks<nat>>> (generated) (generated) */
struct void_ mark_visit_344(struct mark_ctx* mark_ctx, struct opt_0 value) {
	struct opt_0 _0 = value;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct some_0 value1 = _0.as1;
			
			return mark_visit_345(mark_ctx, value1);
		}
		default:
			return (struct void_) {};
	}
}
/* mark-visit<some<fut-state-callbacks<nat>>> (generated) (generated) */
struct void_ mark_visit_345(struct mark_ctx* mark_ctx, struct some_0 value) {
	return mark_visit_346(mark_ctx, value.value);
}
/* mark-visit<gc-ptr(fut-state-callbacks<nat>)> (generated) (generated) */
struct void_ mark_visit_346(struct mark_ctx* mark_ctx, struct fut_state_callbacks_0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct fut_state_callbacks_0));
	if (_0) {
		return mark_visit_339(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<exception> (generated) (generated) */
struct void_ mark_visit_347(struct mark_ctx* mark_ctx, struct exception value) {
	mark_arr_348(mark_ctx, value.message);
	return mark_visit_349(mark_ctx, value.backtrace);
}
/* mark-arr<char> (generated) (generated) */
struct void_ mark_arr_348(struct mark_ctx* mark_ctx, struct arr_0 a) {
	uint8_t dropped0;
	dropped0 = mark(mark_ctx, ((uint8_t*) a.begin_ptr), (a.size * sizeof(char)));
	
	return (struct void_) {};
}
/* mark-visit<backtrace> (generated) (generated) */
struct void_ mark_visit_349(struct mark_ctx* mark_ctx, struct backtrace value) {
	return mark_arr_351(mark_ctx, value.return_stack);
}
/* mark-elems<arr<char>> (generated) (generated) */
struct void_ mark_elems_350(struct mark_ctx* mark_ctx, struct arr_0* cur, struct arr_0* end) {
	top:;
	uint8_t _0 = (cur == end);
	if (_0) {
		return (struct void_) {};
	} else {
		mark_arr_348(mark_ctx, (*cur));
		mark_ctx = mark_ctx;
		cur = (cur + 1u);
		end = end;
		goto top;
	}
}
/* mark-arr<arr<char>> (generated) (generated) */
struct void_ mark_arr_351(struct mark_ctx* mark_ctx, struct arr_1 a) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) a.begin_ptr), (a.size * sizeof(struct arr_0)));
	if (_0) {
		return mark_elems_350(mark_ctx, a.begin_ptr, (a.begin_ptr + a.size));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(then<?out, void>.lambda0)> (generated) (generated) */
struct void_ mark_visit_352(struct mark_ctx* mark_ctx, struct then__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct then__lambda0));
	if (_0) {
		return mark_visit_327(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<opt<fut-state-callbacks<void>>> (generated) (generated) */
struct void_ mark_visit_353(struct mark_ctx* mark_ctx, struct opt_7 value) {
	struct opt_7 _0 = value;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct some_7 value1 = _0.as1;
			
			return mark_visit_354(mark_ctx, value1);
		}
		default:
			return (struct void_) {};
	}
}
/* mark-visit<some<fut-state-callbacks<void>>> (generated) (generated) */
struct void_ mark_visit_354(struct mark_ctx* mark_ctx, struct some_7 value) {
	return mark_visit_355(mark_ctx, value.value);
}
/* mark-visit<gc-ptr(fut-state-callbacks<void>)> (generated) (generated) */
struct void_ mark_visit_355(struct mark_ctx* mark_ctx, struct fut_state_callbacks_1* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct fut_state_callbacks_1));
	if (_0) {
		return mark_visit_325(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(fut<void>)> (generated) (generated) */
struct void_ mark_visit_356(struct mark_ctx* mark_ctx, struct fut_1* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct fut_1));
	if (_0) {
		return mark_visit_323(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(callback!<?in>.lambda0)> (generated) (generated) */
struct void_ mark_visit_357(struct mark_ctx* mark_ctx, struct callback__e_0__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct callback__e_0__lambda0));
	if (_0) {
		return mark_visit_322(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<callback!<?a>.lambda0> (generated) (generated) */
struct void_ mark_visit_358(struct mark_ctx* mark_ctx, struct callback__e_1__lambda0 value) {
	mark_visit_342(mark_ctx, value.f);
	return mark_visit_340(mark_ctx, value.cb);
}
/* mark-visit<gc-ptr(callback!<?a>.lambda0)> (generated) (generated) */
struct void_ mark_visit_359(struct mark_ctx* mark_ctx, struct callback__e_1__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct callback__e_1__lambda0));
	if (_0) {
		return mark_visit_358(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<subscript<?out, ?in>.lambda0.lambda0> (generated) (generated) */
struct void_ mark_visit_360(struct mark_ctx* mark_ctx, struct subscript_11__lambda0__lambda0 value) {
	mark_visit_328(mark_ctx, value.f);
	return mark_visit_342(mark_ctx, value.res);
}
/* mark-visit<gc-ptr(subscript<?out, ?in>.lambda0.lambda0)> (generated) (generated) */
struct void_ mark_visit_361(struct mark_ctx* mark_ctx, struct subscript_11__lambda0__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct subscript_11__lambda0__lambda0));
	if (_0) {
		return mark_visit_360(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<subscript<?out, ?in>.lambda0> (generated) (generated) */
struct void_ mark_visit_362(struct mark_ctx* mark_ctx, struct subscript_11__lambda0 value) {
	mark_visit_328(mark_ctx, value.f);
	return mark_visit_342(mark_ctx, value.res);
}
/* mark-visit<gc-ptr(subscript<?out, ?in>.lambda0)> (generated) (generated) */
struct void_ mark_visit_363(struct mark_ctx* mark_ctx, struct subscript_11__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct subscript_11__lambda0));
	if (_0) {
		return mark_visit_362(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<subscript<?out>.lambda0.lambda0> (generated) (generated) */
struct void_ mark_visit_364(struct mark_ctx* mark_ctx, struct subscript_16__lambda0__lambda0 value) {
	mark_visit_331(mark_ctx, value.f);
	return mark_visit_342(mark_ctx, value.res);
}
/* mark-visit<gc-ptr(subscript<?out>.lambda0.lambda0)> (generated) (generated) */
struct void_ mark_visit_365(struct mark_ctx* mark_ctx, struct subscript_16__lambda0__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct subscript_16__lambda0__lambda0));
	if (_0) {
		return mark_visit_364(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<subscript<?out>.lambda0> (generated) (generated) */
struct void_ mark_visit_366(struct mark_ctx* mark_ctx, struct subscript_16__lambda0 value) {
	mark_visit_331(mark_ctx, value.f);
	return mark_visit_342(mark_ctx, value.res);
}
/* mark-visit<gc-ptr(subscript<?out>.lambda0)> (generated) (generated) */
struct void_ mark_visit_367(struct mark_ctx* mark_ctx, struct subscript_16__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct subscript_16__lambda0));
	if (_0) {
		return mark_visit_366(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(task-queue-node)> (generated) (generated) */
struct void_ mark_visit_368(struct mark_ctx* mark_ctx, struct task_queue_node* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct task_queue_node));
	if (_0) {
		return mark_visit_319(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<mut-list<nat>> (generated) (generated) */
struct void_ mark_visit_369(struct mark_ctx* mark_ctx, struct mut_list_0 value) {
	return mark_visit_370(mark_ctx, value.backing);
}
/* mark-visit<mut-arr<nat>> (generated) (generated) */
struct void_ mark_visit_370(struct mark_ctx* mark_ctx, struct mut_arr_0 value) {
	return mark_arr_371(mark_ctx, value.inner);
}
/* mark-arr<nat-64> (generated) (generated) */
struct void_ mark_arr_371(struct mark_ctx* mark_ctx, struct arr_2 a) {
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
/* wait-on void(cond condition, until-time opt<nat>, last-checked nat) */
struct void_ wait_on(struct condition* cond, struct opt_9 until_time, uint64_t last_checked) {
	top:;
	uint8_t _0 = _equal_0(cond->value, last_checked);
	if (_0) {
		yield_thread();
		uint8_t _1 = before_time__q(until_time);
		if (_1) {
			cond = cond;
			until_time = until_time;
			last_checked = last_checked;
			goto top;
		} else {
			return (struct void_) {};
		}
	} else {
		return (struct void_) {};
	}
}
/* before-time? bool(until-time opt<nat>) */
uint8_t before_time__q(struct opt_9 until_time) {
	struct opt_9 _0 = until_time;
	switch (_0.kind) {
		case 0: {
			return 1;
		}
		case 1: {
			struct some_9 s0 = _0.as1;
			
			uint64_t _1 = get_monotime_nsec();
			return _less(_1, s0.value);
		}
		default:
			return 0;
	}
}
/* join-threads-recur void(i nat, n-threads nat, threads ptr<nat>) */
struct void_ join_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads) {
	top:;
	uint8_t _0 = _notEqual_1(i, n_threads);
	if (_0) {
		uint64_t _1 = subscript_24(threads, i);
		join_one_thread(_1);
		uint64_t _2 = noctx_incr(i);
		i = _2;
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
		uint8_t _2 = _equal_2(err1, _1);
		if (_2) {
			todo_0();
		} else {
			int32_t _3 = esrch();
			uint8_t _4 = _equal_2(err1, _3);
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
	return (free((uint8_t*) p), (struct void_) {});
}
/* unmanaged-free<by-val<thread-args>> void(p ptr<thread-args>) */
struct void_ unmanaged_free_1(struct thread_args* p) {
	return (free((uint8_t*) p), (struct void_) {});
}
/* main fut<nat>(_ arr<arr<char>>) */
struct fut_0* main_0(struct ctx* ctx, struct arr_1 _p0) {
	print((struct arr_0) {13, constantarr_0_10});
	return resolved_1(ctx, 0u);
}
/* resolved<nat> fut<nat>(value nat) */
struct fut_0* resolved_1(struct ctx* ctx, uint64_t value) {
	struct fut_0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct fut_0));
	temp0 = (struct fut_0*) _0;
	
	struct lock _1 = lock_by_val();
	*temp0 = (struct fut_0) {_1, (struct fut_state_0) {2, .as2 = (struct fut_state_resolved_0) {value}}};
	return temp0;
}
/* main (generated) (generated) */
int32_t main(int32_t argc, char** argv) {
	return rt_main(argc, argv, main_0);
}
