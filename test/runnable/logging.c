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
struct err {
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
struct task_queue;
struct task_queue_node;
struct task;
struct some_2 {
	struct task_queue_node* value;
};
struct mut_list;
struct mut_arr;
struct arr_2 {
	uint64_t size;
	uint64_t* data;
};
struct logged;
struct info {
};
struct warn {
};
struct thread_safe_counter;
struct arr_3 {
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
struct arr_4 {
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
struct map__lambda0;
struct thread_args {
	uint64_t thread_id;
	struct global_ctx* gctx;
};
struct cell_0 {
	uint64_t value;
};
struct chosen_task;
struct do_a_gc {
};
struct no_chosen_task;
struct some_5 {
	uint64_t value;
};
struct timespec {
	int64_t tv_sec;
	int64_t tv_nsec;
};
struct cell_1 {
	struct timespec value;
};
struct no_task;
struct cell_2 {
	uint8_t* value;
};
struct main_0__lambda0;
struct finally__lambda0;
struct with_log_handler__lambda0;
struct with_log_handler__lambda1;
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
		struct err as1;
	};
};
struct fun_act1_0 {
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
struct fun_act0_0 {
	uint64_t kind;
	union {
		struct call_ref_0__lambda0__lambda0* as0;
		struct call_ref_0__lambda0* as1;
		struct call_ref_1__lambda0__lambda0* as2;
		struct call_ref_1__lambda0* as3;
		struct with_log_handler__lambda0* as4;
		struct with_log_handler__lambda1* as5;
		struct void_ as6;
		struct void_ as7;
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
		struct main_0__lambda0* as1;
		struct void_ as2;
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
		struct err as1;
	};
};
struct fun_act1_1 {
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
struct fun_act0_1 {
	uint64_t kind;
	union {
		struct add_first_task__lambda0* as0;
	};
};
struct fun_act1_2 {
	uint64_t kind;
	union {
		struct then2__lambda0* as0;
	};
};
struct fun_act1_3 {
	uint64_t kind;
	union {
		struct call_ref_0__lambda0__lambda1* as0;
		struct call_ref_1__lambda0__lambda1* as1;
		struct finally__lambda0* as2;
	};
};
struct fun_act1_4 {
	uint64_t kind;
	union {
		struct void_ as0;
	};
};
struct fun_act1_5 {
	uint64_t kind;
	union {
		struct map__lambda0* as0;
	};
};
struct choose_task_result;
struct task_or_gc;
struct opt_5 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_5 as1;
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
	struct opt_0 head;
};
struct fut_callback_node_0 {
	struct fun_act1_0 cb;
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
struct task_queue;
struct task_queue_node;
struct task {
	uint64_t time;
	uint64_t exclusion;
	struct fun_act0_0 action;
};
struct mut_list;
struct mut_arr {
	struct arr_2 arr;
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
	struct fun1_1 handler;
};
struct fut_1;
struct fut_state_callbacks_1 {
	struct opt_4 head;
};
struct fut_callback_node_1 {
	struct fun_act1_1 cb;
	struct opt_4 next_node;
};
struct fun_ref0 {
	struct island_and_exclusion island_and_exclusion;
	struct fun_act0_1 fun;
};
struct fun_ref1 {
	struct island_and_exclusion island_and_exclusion;
	struct fun_act1_2 fun;
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
	struct arr_4 all_args;
	fun_ptr2 main_ptr;
};
struct map__lambda0 {
	struct fun_act1_4 mapper;
	struct arr_4 a;
};
struct chosen_task;
struct no_chosen_task {
	uint8_t no_tasks_and_last_thread_out__q;
	struct opt_5 first_task_time;
};
struct no_task {
	uint8_t any_tasks__q;
	struct opt_5 first_task_time;
};
struct main_0__lambda0 {
	struct fun1_1 lh;
};
struct finally__lambda0 {
	struct fun_act0_0 after;
};
struct with_log_handler__lambda0 {
	struct fun1_1 original_handler;
};
struct with_log_handler__lambda1 {
	struct fun1_1 handler;
	struct fun_act0_0 cb;
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
struct fut_0 {
	struct lock lk;
	struct fut_state_0 state;
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
struct mut_list {
	struct mut_arr backing;
	uint64_t size;
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
	struct island* task_island;
	struct task_or_gc task_or_gc;
};
struct choose_task_result {
	uint64_t kind;
	union {
		struct chosen_task as0;
		struct no_chosen_task as1;
	};
};
struct island;
struct island_gc_root;
struct task_queue {
	struct opt_2 head;
	struct mut_list currently_running_exclusions;
};
struct jmp_buf_tag {
	struct bytes64 jmp_buf;
	int32_t mask_was_saved;
	struct bytes128 saved_mask;
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
_Static_assert(sizeof(struct err) == 16, "");
_Static_assert(sizeof(struct none) == 0, "");
_Static_assert(sizeof(struct some_0) == 8, "");
_Static_assert(sizeof(struct fut_state_resolved_0) == 4, "");
_Static_assert(sizeof(struct arr_1) == 16, "");
_Static_assert(sizeof(struct global_ctx) == 56, "");
_Static_assert(sizeof(struct island) == 208, "");
_Static_assert(sizeof(struct gc) == 96, "");
_Static_assert(sizeof(struct gc_ctx) == 24, "");
_Static_assert(sizeof(struct some_1) == 8, "");
_Static_assert(sizeof(struct island_gc_root) == 64, "");
_Static_assert(sizeof(struct task_queue) == 40, "");
_Static_assert(sizeof(struct task_queue_node) == 48, "");
_Static_assert(sizeof(struct task) == 32, "");
_Static_assert(sizeof(struct some_2) == 8, "");
_Static_assert(sizeof(struct mut_list) == 24, "");
_Static_assert(sizeof(struct mut_arr) == 16, "");
_Static_assert(sizeof(struct arr_2) == 16, "");
_Static_assert(sizeof(struct logged) == 24, "");
_Static_assert(sizeof(struct info) == 0, "");
_Static_assert(sizeof(struct warn) == 0, "");
_Static_assert(sizeof(struct thread_safe_counter) == 16, "");
_Static_assert(sizeof(struct arr_3) == 16, "");
_Static_assert(sizeof(struct condition) == 16, "");
_Static_assert(sizeof(struct exception_ctx) == 24, "");
_Static_assert(sizeof(struct jmp_buf_tag) == 200, "");
_Static_assert(sizeof(struct bytes64) == 64, "");
_Static_assert(sizeof(struct bytes32) == 32, "");
_Static_assert(sizeof(struct bytes16) == 16, "");
_Static_assert(sizeof(struct bytes128) == 128, "");
_Static_assert(sizeof(struct some_3) == 8, "");
_Static_assert(sizeof(struct log_ctx) == 16, "");
_Static_assert(sizeof(struct thread_local_stuff) == 16, "");
_Static_assert(sizeof(struct arr_4) == 16, "");
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
_Static_assert(sizeof(struct map__lambda0) == 24, "");
_Static_assert(sizeof(struct thread_args) == 16, "");
_Static_assert(sizeof(struct cell_0) == 8, "");
_Static_assert(sizeof(struct chosen_task) == 48, "");
_Static_assert(sizeof(struct do_a_gc) == 0, "");
_Static_assert(sizeof(struct no_chosen_task) == 24, "");
_Static_assert(sizeof(struct some_5) == 8, "");
_Static_assert(sizeof(struct timespec) == 16, "");
_Static_assert(sizeof(struct cell_1) == 16, "");
_Static_assert(sizeof(struct no_task) == 24, "");
_Static_assert(sizeof(struct cell_2) == 8, "");
_Static_assert(sizeof(struct main_0__lambda0) == 16, "");
_Static_assert(sizeof(struct finally__lambda0) == 16, "");
_Static_assert(sizeof(struct with_log_handler__lambda0) == 16, "");
_Static_assert(sizeof(struct with_log_handler__lambda1) == 32, "");
_Static_assert(sizeof(struct comparison) == 8, "");
_Static_assert(sizeof(struct fut_state_0) == 24, "");
_Static_assert(sizeof(struct result_0) == 24, "");
_Static_assert(sizeof(struct fun_act1_0) == 16, "");
_Static_assert(sizeof(struct opt_0) == 16, "");
_Static_assert(sizeof(struct opt_1) == 16, "");
_Static_assert(sizeof(struct fun_act0_0) == 16, "");
_Static_assert(sizeof(struct opt_2) == 16, "");
_Static_assert(sizeof(struct fun1_0) == 8, "");
_Static_assert(sizeof(struct log_level) == 8, "");
_Static_assert(sizeof(struct fun1_1) == 16, "");
_Static_assert(sizeof(struct opt_3) == 16, "");
_Static_assert(sizeof(struct fun2) == 8, "");
_Static_assert(sizeof(struct fut_state_1) == 24, "");
_Static_assert(sizeof(struct result_1) == 24, "");
_Static_assert(sizeof(struct fun_act1_1) == 16, "");
_Static_assert(sizeof(struct opt_4) == 16, "");
_Static_assert(sizeof(struct fun_act0_1) == 16, "");
_Static_assert(sizeof(struct fun_act1_2) == 16, "");
_Static_assert(sizeof(struct fun_act1_3) == 16, "");
_Static_assert(sizeof(struct fun_act1_4) == 8, "");
_Static_assert(sizeof(struct fun_act1_5) == 16, "");
_Static_assert(sizeof(struct choose_task_result) == 56, "");
_Static_assert(sizeof(struct task_or_gc) == 40, "");
_Static_assert(sizeof(struct opt_5) == 16, "");
_Static_assert(sizeof(struct choose_task_in_island_result) == 40, "");
_Static_assert(sizeof(struct pop_task_result) == 40, "");
char constantarr_0_0[17];
char constantarr_0_1[4];
char constantarr_0_2[20];
char constantarr_0_3[1];
char constantarr_0_4[17];
char constantarr_0_5[13];
char constantarr_0_6[4];
char constantarr_0_7[4];
char constantarr_0_8[2];
char constantarr_0_9[38];
char constantarr_0_10[33];
char constantarr_0_11[13];
char constantarr_0_12[40];
char constantarr_0_13[11];
char constantarr_0_14[13];
char constantarr_0_15[11];
char constantarr_0_16[12];
char constantarr_0_17[12];
char constantarr_0_18[4];
char constantarr_0_19[14];
char constantarr_0_20[10];
char constantarr_0_21[25];
char constantarr_0_22[8];
char constantarr_0_23[8];
char constantarr_0_24[8];
char constantarr_0_25[12];
char constantarr_0_26[19];
char constantarr_0_27[11];
char constantarr_0_28[3];
char constantarr_0_29[15];
char constantarr_0_30[7];
char constantarr_0_31[7];
char constantarr_0_32[5];
char constantarr_0_33[4];
char constantarr_0_34[11];
char constantarr_0_35[6];
char constantarr_0_36[8];
char constantarr_0_37[11];
char constantarr_0_38[12];
char constantarr_0_39[6];
char constantarr_0_40[17];
char constantarr_0_41[7];
char constantarr_0_42[7];
char constantarr_0_43[5];
char constantarr_0_44[16];
char constantarr_0_45[13];
char constantarr_0_46[2];
char constantarr_0_47[11];
char constantarr_0_48[9];
char constantarr_0_49[10];
char constantarr_0_50[6];
char constantarr_0_51[7];
char constantarr_0_52[10];
char constantarr_0_53[22];
char constantarr_0_54[10];
char constantarr_0_55[8];
char constantarr_0_56[4];
char constantarr_0_57[15];
char constantarr_0_58[11];
char constantarr_0_59[17];
char constantarr_0_60[7];
char constantarr_0_61[8];
char constantarr_0_62[13];
char constantarr_0_63[9];
char constantarr_0_64[22];
char constantarr_0_65[10];
char constantarr_0_66[14];
char constantarr_0_67[10];
char constantarr_0_68[4];
char constantarr_0_69[60];
char constantarr_0_70[11];
char constantarr_0_71[35];
char constantarr_0_72[28];
char constantarr_0_73[21];
char constantarr_0_74[6];
char constantarr_0_75[11];
char constantarr_0_76[11];
char constantarr_0_77[10];
char constantarr_0_78[8];
char constantarr_0_79[18];
char constantarr_0_80[6];
char constantarr_0_81[19];
char constantarr_0_82[12];
char constantarr_0_83[26];
char constantarr_0_84[14];
char constantarr_0_85[25];
char constantarr_0_86[20];
char constantarr_0_87[16];
char constantarr_0_88[13];
char constantarr_0_89[13];
char constantarr_0_90[5];
char constantarr_0_91[21];
char constantarr_0_92[10];
char constantarr_0_93[10];
char constantarr_0_94[7];
char constantarr_0_95[6];
char constantarr_0_96[13];
char constantarr_0_97[10];
char constantarr_0_98[6];
char constantarr_0_99[9];
char constantarr_0_100[12];
char constantarr_0_101[12];
char constantarr_0_102[7];
char constantarr_0_103[29];
char constantarr_0_104[14];
char constantarr_0_105[18];
char constantarr_0_106[8];
char constantarr_0_107[7];
char constantarr_0_108[18];
char constantarr_0_109[19];
char constantarr_0_110[5];
char constantarr_0_111[16];
char constantarr_0_112[6];
char constantarr_0_113[7];
char constantarr_0_114[1];
char constantarr_0_115[6];
char constantarr_0_116[10];
char constantarr_0_117[9];
char constantarr_0_118[17];
char constantarr_0_119[21];
char constantarr_0_120[17];
char constantarr_0_121[18];
char constantarr_0_122[11];
char constantarr_0_123[20];
char constantarr_0_124[7];
char constantarr_0_125[15];
char constantarr_0_126[9];
char constantarr_0_127[3];
char constantarr_0_128[7];
char constantarr_0_129[22];
char constantarr_0_130[5];
char constantarr_0_131[8];
char constantarr_0_132[12];
char constantarr_0_133[11];
char constantarr_0_134[18];
char constantarr_0_135[13];
char constantarr_0_136[10];
char constantarr_0_137[8];
char constantarr_0_138[8];
char constantarr_0_139[17];
char constantarr_0_140[11];
char constantarr_0_141[10];
char constantarr_0_142[8];
char constantarr_0_143[8];
char constantarr_0_144[7];
char constantarr_0_145[10];
char constantarr_0_146[6];
char constantarr_0_147[11];
char constantarr_0_148[12];
char constantarr_0_149[12];
char constantarr_0_150[15];
char constantarr_0_151[19];
char constantarr_0_152[9];
char constantarr_0_153[15];
char constantarr_0_154[13];
char constantarr_0_155[16];
char constantarr_0_156[6];
char constantarr_0_157[2];
char constantarr_0_158[10];
char constantarr_0_159[14];
char constantarr_0_160[10];
char constantarr_0_161[18];
char constantarr_0_162[18];
char constantarr_0_163[6];
char constantarr_0_164[5];
char constantarr_0_165[6];
char constantarr_0_166[5];
char constantarr_0_167[18];
char constantarr_0_168[6];
char constantarr_0_169[6];
char constantarr_0_170[20];
char constantarr_0_171[21];
char constantarr_0_172[23];
char constantarr_0_173[19];
char constantarr_0_174[18];
char constantarr_0_175[11];
char constantarr_0_176[14];
char constantarr_0_177[7];
char constantarr_0_178[17];
char constantarr_0_179[13];
char constantarr_0_180[11];
char constantarr_0_181[7];
char constantarr_0_182[26];
char constantarr_0_183[30];
char constantarr_0_184[18];
char constantarr_0_185[25];
char constantarr_0_186[19];
char constantarr_0_187[7];
char constantarr_0_188[18];
char constantarr_0_189[12];
char constantarr_0_190[18];
char constantarr_0_191[16];
char constantarr_0_192[7];
char constantarr_0_193[10];
char constantarr_0_194[23];
char constantarr_0_195[12];
char constantarr_0_196[5];
char constantarr_0_197[23];
char constantarr_0_198[9];
char constantarr_0_199[12];
char constantarr_0_200[13];
char constantarr_0_201[9];
char constantarr_0_202[10];
char constantarr_0_203[7];
char constantarr_0_204[9];
char constantarr_0_205[16];
char constantarr_0_206[2];
char constantarr_0_207[12];
char constantarr_0_208[23];
char constantarr_0_209[6];
char constantarr_0_210[12];
char constantarr_0_211[13];
char constantarr_0_212[16];
char constantarr_0_213[8];
char constantarr_0_214[12];
char constantarr_0_215[10];
char constantarr_0_216[9];
char constantarr_0_217[14];
char constantarr_0_218[11];
char constantarr_0_219[11];
char constantarr_0_220[26];
char constantarr_0_221[7];
char constantarr_0_222[3];
char constantarr_0_223[22];
char constantarr_0_224[2];
char constantarr_0_225[25];
char constantarr_0_226[19];
char constantarr_0_227[30];
char constantarr_0_228[15];
char constantarr_0_229[79];
char constantarr_0_230[14];
char constantarr_0_231[12];
char constantarr_0_232[16];
char constantarr_0_233[24];
char constantarr_0_234[7];
char constantarr_0_235[23];
char constantarr_0_236[14];
char constantarr_0_237[6];
char constantarr_0_238[9];
char constantarr_0_239[13];
char constantarr_0_240[27];
char constantarr_0_241[21];
char constantarr_0_242[8];
char constantarr_0_243[33];
char constantarr_0_244[22];
char constantarr_0_245[6];
char constantarr_0_246[9];
char constantarr_0_247[14];
char constantarr_0_248[16];
char constantarr_0_249[13];
char constantarr_0_250[21];
char constantarr_0_251[27];
char constantarr_0_252[4];
char constantarr_0_253[10];
char constantarr_0_254[6];
char constantarr_0_255[28];
char constantarr_0_256[13];
char constantarr_0_257[22];
char constantarr_0_258[16];
char constantarr_0_259[24];
char constantarr_0_260[19];
char constantarr_0_261[10];
char constantarr_0_262[10];
char constantarr_0_263[8];
char constantarr_0_264[12];
char constantarr_0_265[9];
char constantarr_0_266[8];
char constantarr_0_267[7];
char constantarr_0_268[29];
char constantarr_0_269[8];
char constantarr_0_270[19];
char constantarr_0_271[15];
char constantarr_0_272[4];
char constantarr_0_273[10];
char constantarr_0_274[11];
char constantarr_0_275[4];
char constantarr_0_276[10];
char constantarr_0_277[4];
char constantarr_0_278[22];
char constantarr_0_279[4];
char constantarr_0_280[8];
char constantarr_0_281[21];
char constantarr_0_282[4];
char constantarr_0_283[12];
char constantarr_0_284[8];
char constantarr_0_285[5];
char constantarr_0_286[22];
char constantarr_0_287[9];
char constantarr_0_288[9];
char constantarr_0_289[21];
char constantarr_0_290[17];
char constantarr_0_291[4];
char constantarr_0_292[12];
char constantarr_0_293[9];
char constantarr_0_294[11];
char constantarr_0_295[28];
char constantarr_0_296[16];
char constantarr_0_297[11];
char constantarr_0_298[4];
char constantarr_0_299[7];
char constantarr_0_300[7];
char constantarr_0_301[7];
char constantarr_0_302[8];
char constantarr_0_303[15];
char constantarr_0_304[19];
char constantarr_0_305[6];
char constantarr_0_306[8];
char constantarr_0_307[17];
char constantarr_0_308[19];
char constantarr_0_309[18];
char constantarr_0_310[12];
char constantarr_0_311[35];
char constantarr_0_312[10];
char constantarr_0_313[35];
char constantarr_0_314[27];
char constantarr_0_315[10];
char constantarr_0_316[24];
char constantarr_0_317[14];
char constantarr_0_318[24];
char constantarr_0_319[13];
char constantarr_0_320[7];
char constantarr_0_321[30];
char constantarr_0_322[30];
char constantarr_0_323[22];
char constantarr_0_324[20];
char constantarr_0_325[24];
char constantarr_0_326[20];
char constantarr_0_327[9];
char constantarr_0_328[5];
char constantarr_0_329[14];
char constantarr_0_330[15];
char constantarr_0_331[6];
char constantarr_0_332[10];
char constantarr_0_333[21];
char constantarr_0_334[9];
char constantarr_0_335[1];
char constantarr_0_336[37];
char constantarr_0_337[25];
char constantarr_0_338[14];
char constantarr_0_339[18];
char constantarr_0_340[24];
char constantarr_0_341[7];
char constantarr_0_342[7];
char constantarr_0_343[13];
char constantarr_0_344[15];
char constantarr_0_345[7];
char constantarr_0_346[33];
char constantarr_0_347[24];
char constantarr_0_348[5];
char constantarr_0_349[13];
char constantarr_0_350[17];
char constantarr_0_351[8];
char constantarr_0_352[11];
char constantarr_0_353[15];
char constantarr_0_354[10];
char constantarr_0_355[30];
char constantarr_0_356[22];
char constantarr_0_357[15];
char constantarr_0_358[13];
char constantarr_0_359[6];
char constantarr_0_360[84];
char constantarr_0_361[11];
char constantarr_0_362[45];
char constantarr_0_363[10];
char constantarr_0_364[19];
char constantarr_0_365[22];
char constantarr_0_366[24];
char constantarr_0_367[11];
char constantarr_0_368[17];
char constantarr_0_369[14];
char constantarr_0_370[9];
char constantarr_0_371[6];
char constantarr_0_372[12];
char constantarr_0_373[16];
char constantarr_0_374[36];
char constantarr_0_375[10];
char constantarr_0_376[19];
char constantarr_0_377[15];
char constantarr_0_378[21];
char constantarr_0_379[10];
char constantarr_0_380[18];
char constantarr_0_381[14];
char constantarr_0_382[28];
char constantarr_0_383[9];
char constantarr_0_384[17];
char constantarr_0_385[6];
char constantarr_0_386[21];
char constantarr_0_387[16];
char constantarr_0_388[11];
char constantarr_0_389[17];
char constantarr_0_390[26];
char constantarr_0_391[14];
char constantarr_0_392[8];
char constantarr_0_393[13];
char constantarr_0_394[15];
char constantarr_0_395[26];
char constantarr_0_396[13];
char constantarr_0_397[6];
char constantarr_0_398[7];
char constantarr_0_399[9];
char constantarr_0_400[22];
char constantarr_0_401[17];
char constantarr_0_402[14];
char constantarr_0_403[21];
char constantarr_0_404[32];
char constantarr_0_405[7];
char constantarr_0_406[7];
char constantarr_0_407[8];
char constantarr_0_408[25];
char constantarr_0_409[28];
char constantarr_0_410[19];
char constantarr_0_411[14];
char constantarr_0_412[13];
char constantarr_0_413[19];
char constantarr_0_414[15];
char constantarr_0_415[19];
char constantarr_0_416[11];
char constantarr_0_417[9];
char constantarr_0_418[11];
char constantarr_0_419[9];
char constantarr_0_420[37];
char constantarr_0_421[12];
char constantarr_0_422[12];
char constantarr_0_423[16];
char constantarr_0_424[11];
char constantarr_0_425[21];
char constantarr_0_426[11];
char constantarr_0_427[10];
char constantarr_0_428[8];
char constantarr_0_429[8];
char constantarr_0_430[5];
char constantarr_0_431[10];
char constantarr_0_432[15];
char constantarr_0_433[29];
char constantarr_0_434[7];
char constantarr_0_435[11];
char constantarr_0_436[10];
char constantarr_0_437[6];
char constantarr_0_438[11];
char constantarr_0_439[32];
char constantarr_0_440[37];
char constantarr_0_441[8];
char constantarr_0_442[35];
char constantarr_0_443[14];
char constantarr_0_444[10];
char constantarr_0_445[13];
char constantarr_0_446[12];
char constantarr_0_447[46];
char constantarr_0_448[13];
char constantarr_0_449[12];
char constantarr_0_450[8];
char constantarr_0_451[20];
char constantarr_0_452[8];
char constantarr_0_453[14];
char constantarr_0_454[20];
char constantarr_0_455[14];
char constantarr_0_456[14];
char constantarr_0_457[7];
char constantarr_0_458[12];
char constantarr_0_459[9];
char constantarr_0_460[18];
char constantarr_0_461[15];
char constantarr_0_462[27];
char constantarr_0_463[15];
char constantarr_0_464[12];
char constantarr_0_465[27];
char constantarr_0_466[6];
char constantarr_0_467[5];
char constantarr_0_468[14];
char constantarr_0_469[19];
char constantarr_0_470[4];
char constantarr_0_471[35];
char constantarr_0_472[18];
char constantarr_0_473[23];
char constantarr_0_474[39];
char constantarr_0_475[8];
char constantarr_0_476[25];
char constantarr_0_477[4];
char constantarr_0_478[3];
char constantarr_0_479[18];
char constantarr_0_480[15];
char constantarr_0_481[7];
char constantarr_0_482[11];
char constantarr_0_483[15];
char constantarr_0_484[6];
char constantarr_0_485[22];
char constantarr_0_486[12];
char constantarr_0_487[22];
char constantarr_0_488[11];
char constantarr_0_489[19];
char constantarr_0_490[15];
char constantarr_0_491[30];
char constantarr_0_492[30];
char constantarr_0_493[12];
char constantarr_0_494[12];
char constantarr_0_495[12];
char constantarr_0_496[12];
char constantarr_0_497[15];
char constantarr_0_0[17] = "Assertion failed!";
char constantarr_0_1[4] = "TODO";
char constantarr_0_2[20] = "uncaught exception: ";
char constantarr_0_3[1] = "\n";
char constantarr_0_4[17] = "<<empty message>>";
char constantarr_0_5[13] = "assert failed";
char constantarr_0_6[4] = "info";
char constantarr_0_7[4] = "warn";
char constantarr_0_8[2] = ": ";
char constantarr_0_9[38] = "Couldn't acquire lock after 1000 tries";
char constantarr_0_10[33] = "resolving an already-resolved fut";
char constantarr_0_11[13] = "forbid failed";
char constantarr_0_12[40] = "Did not find the element in the mut-list";
char constantarr_0_13[11] = "unreachable";
char constantarr_0_14[13] = "main failed: ";
char constantarr_0_15[11] = "Logged once";
char constantarr_0_16[12] = "Logged twice";
char constantarr_0_17[12] = "Logged never";
char constantarr_0_18[4] = "mark";
char constantarr_0_19[14] = "words-of-bytes";
char constantarr_0_20[10] = "unsafe-div";
char constantarr_0_21[25] = "round-up-to-multiple-of-8";
char constantarr_0_22[8] = "bits-and";
char constantarr_0_23[8] = "wrap-add";
char constantarr_0_24[8] = "bits-not";
char constantarr_0_25[12] = "as<ptr<nat>>";
char constantarr_0_26[19] = "ptr-cast<nat, nat8>";
char constantarr_0_27[11] = "hard-assert";
char constantarr_0_28[3] = "not";
char constantarr_0_29[15] = "hard-fail<void>";
char constantarr_0_30[7] = "==<nat>";
char constantarr_0_31[7] = "<=><?t>";
char constantarr_0_32[5] = "false";
char constantarr_0_33[4] = "true";
char constantarr_0_34[11] = "to-nat<nat>";
char constantarr_0_35[6] = "-<nat>";
char constantarr_0_36[8] = "wrap-sub";
char constantarr_0_37[11] = "size-of<?t>";
char constantarr_0_38[12] = "memory-start";
char constantarr_0_39[6] = "<<nat>";
char constantarr_0_40[17] = "memory-size-words";
char constantarr_0_41[7] = "<=<nat>";
char constantarr_0_42[7] = "+<bool>";
char constantarr_0_43[5] = "marks";
char constantarr_0_44[16] = "mark-range-recur";
char constantarr_0_45[13] = "ptr-eq?<bool>";
char constantarr_0_46[2] = "or";
char constantarr_0_47[11] = "deref<bool>";
char constantarr_0_48[9] = "set<bool>";
char constantarr_0_49[10] = "incr<bool>";
char constantarr_0_50[6] = "><nat>";
char constantarr_0_51[7] = "rt-main";
char constantarr_0_52[10] = "get-nprocs";
char constantarr_0_53[22] = "as<by-val<global-ctx>>";
char constantarr_0_54[10] = "global-ctx";
char constantarr_0_55[8] = "new-lock";
char constantarr_0_56[4] = "lock";
char constantarr_0_57[15] = "new-atomic-bool";
char constantarr_0_58[11] = "atomic-bool";
char constantarr_0_59[17] = "empty-arr<island>";
char constantarr_0_60[7] = "arr<?t>";
char constantarr_0_61[8] = "null<?t>";
char constantarr_0_62[13] = "new-condition";
char constantarr_0_63[9] = "condition";
char constantarr_0_64[22] = "ref-of-val<global-ctx>";
char constantarr_0_65[10] = "new-island";
char constantarr_0_66[14] = "new-task-queue";
char constantarr_0_67[10] = "task-queue";
char constantarr_0_68[4] = "none";
char constantarr_0_69[60] = "new-mut-list-by-val-with-capacity-from-unmanaged-memory<nat>";
char constantarr_0_70[11] = "mut-arr<?t>";
char constantarr_0_71[35] = "unmanaged-alloc-zeroed-elements<?t>";
char constantarr_0_72[28] = "unmanaged-alloc-elements<?t>";
char constantarr_0_73[21] = "unmanaged-alloc-bytes";
char constantarr_0_74[6] = "malloc";
char constantarr_0_75[11] = "hard-forbid";
char constantarr_0_76[11] = "null?<nat8>";
char constantarr_0_77[10] = "to-nat<?t>";
char constantarr_0_78[8] = "wrap-mul";
char constantarr_0_79[18] = "set-zero-range<?t>";
char constantarr_0_80[6] = "memset";
char constantarr_0_81[19] = "as-any-ptr<ptr<?t>>";
char constantarr_0_82[12] = "mut-list<?t>";
char constantarr_0_83[26] = "as<by-val<island-gc-root>>";
char constantarr_0_84[14] = "island-gc-root";
char constantarr_0_85[25] = "default-exception-handler";
char constantarr_0_86[20] = "print-err-no-newline";
char constantarr_0_87[16] = "write-no-newline";
char constantarr_0_88[13] = "size-of<char>";
char constantarr_0_89[13] = "size-of<nat8>";
char constantarr_0_90[5] = "write";
char constantarr_0_91[21] = "as-any-ptr<ptr<char>>";
char constantarr_0_92[10] = "data<char>";
char constantarr_0_93[10] = "size<char>";
char constantarr_0_94[7] = "!=<int>";
char constantarr_0_95[6] = "==<?t>";
char constantarr_0_96[13] = "unsafe-to-int";
char constantarr_0_97[10] = "todo<void>";
char constantarr_0_98[6] = "stderr";
char constantarr_0_99[9] = "print-err";
char constantarr_0_100[12] = "?<arr<char>>";
char constantarr_0_101[12] = "empty?<char>";
char constantarr_0_102[7] = "message";
char constantarr_0_103[29] = "set-any-unhandled-exceptions?";
char constantarr_0_104[14] = "get-global-ctx";
char constantarr_0_105[18] = "as-ref<global-ctx>";
char constantarr_0_106[8] = "gctx-ptr";
char constantarr_0_107[7] = "get-ctx";
char constantarr_0_108[18] = "new-island.lambda0";
char constantarr_0_109[19] = "default-log-handler";
char constantarr_0_110[5] = "print";
char constantarr_0_111[16] = "print-no-newline";
char constantarr_0_112[6] = "stdout";
char constantarr_0_113[7] = "+<char>";
char constantarr_0_114[1] = "+";
char constantarr_0_115[6] = "assert";
char constantarr_0_116[10] = "fail<void>";
char constantarr_0_117[9] = "throw<?t>";
char constantarr_0_118[17] = "get-exception-ctx";
char constantarr_0_119[21] = "as-ref<exception-ctx>";
char constantarr_0_120[17] = "exception-ctx-ptr";
char constantarr_0_121[18] = "null?<jmp-buf-tag>";
char constantarr_0_122[11] = "jmp-buf-ptr";
char constantarr_0_123[20] = "set-thrown-exception";
char constantarr_0_124[7] = "longjmp";
char constantarr_0_125[15] = "number-to-throw";
char constantarr_0_126[9] = "exception";
char constantarr_0_127[3] = "and";
char constantarr_0_128[7] = ">=<nat>";
char constantarr_0_129[22] = "uninitialized-data<?t>";
char constantarr_0_130[5] = "alloc";
char constantarr_0_131[8] = "gc-alloc";
char constantarr_0_132[12] = "try-gc-alloc";
char constantarr_0_133[11] = "validate-gc";
char constantarr_0_134[18] = "ptr-less-eq?<bool>";
char constantarr_0_135[13] = "ptr-less?<?t>";
char constantarr_0_136[10] = "mark-begin";
char constantarr_0_137[8] = "mark-cur";
char constantarr_0_138[8] = "mark-end";
char constantarr_0_139[17] = "ptr-less-eq?<nat>";
char constantarr_0_140[11] = "ptr-eq?<?t>";
char constantarr_0_141[10] = "data-begin";
char constantarr_0_142[8] = "data-cur";
char constantarr_0_143[8] = "data-end";
char constantarr_0_144[7] = "-<bool>";
char constantarr_0_145[10] = "size-words";
char constantarr_0_146[6] = "+<nat>";
char constantarr_0_147[11] = "range-free?";
char constantarr_0_148[12] = "set-mark-cur";
char constantarr_0_149[12] = "set-data-cur";
char constantarr_0_150[15] = "some<ptr<nat8>>";
char constantarr_0_151[19] = "ptr-cast<nat8, nat>";
char constantarr_0_152[9] = "incr<nat>";
char constantarr_0_153[15] = "todo<ptr<nat8>>";
char constantarr_0_154[13] = "hard-fail<?t>";
char constantarr_0_155[16] = "value<ptr<nat8>>";
char constantarr_0_156[6] = "get-gc";
char constantarr_0_157[2] = "gc";
char constantarr_0_158[10] = "get-gc-ctx";
char constantarr_0_159[14] = "as-ref<gc-ctx>";
char constantarr_0_160[10] = "gc-ctx-ptr";
char constantarr_0_161[18] = "ptr-cast<?t, nat8>";
char constantarr_0_162[18] = "copy-data-from<?t>";
char constantarr_0_163[6] = "memcpy";
char constantarr_0_164[5] = "+<?t>";
char constantarr_0_165[6] = "to-str";
char constantarr_0_166[5] = "level";
char constantarr_0_167[18] = "new-island.lambda1";
char constantarr_0_168[6] = "island";
char constantarr_0_169[6] = "new-gc";
char constantarr_0_170[20] = "ptr-cast<bool, nat8>";
char constantarr_0_171[21] = "as-any-ptr<ptr<bool>>";
char constantarr_0_172[23] = "new-thread-safe-counter";
char constantarr_0_173[19] = "thread-safe-counter";
char constantarr_0_174[18] = "ref-of-val<island>";
char constantarr_0_175[11] = "set-islands";
char constantarr_0_176[14] = "ptr-to<island>";
char constantarr_0_177[7] = "do-main";
char constantarr_0_178[17] = "new-exception-ctx";
char constantarr_0_179[13] = "exception-ctx";
char constantarr_0_180[11] = "new-log-ctx";
char constantarr_0_181[7] = "log-ctx";
char constantarr_0_182[26] = "zeroed<fun1<void, logged>>";
char constantarr_0_183[30] = "as<by-val<thread-local-stuff>>";
char constantarr_0_184[18] = "thread-local-stuff";
char constantarr_0_185[25] = "ref-of-val<exception-ctx>";
char constantarr_0_186[19] = "ref-of-val<log-ctx>";
char constantarr_0_187[7] = "new-ctx";
char constantarr_0_188[18] = "as-any-ptr<gc-ctx>";
char constantarr_0_189[12] = "acquire-lock";
char constantarr_0_190[18] = "acquire-lock-recur";
char constantarr_0_191[16] = "try-acquire-lock";
char constantarr_0_192[7] = "try-set";
char constantarr_0_193[10] = "try-change";
char constantarr_0_194[23] = "compare-exchange-strong";
char constantarr_0_195[12] = "ptr-to<bool>";
char constantarr_0_196[5] = "value";
char constantarr_0_197[23] = "ref-of-val<atomic-bool>";
char constantarr_0_198[9] = "is-locked";
char constantarr_0_199[12] = "yield-thread";
char constantarr_0_200[13] = "pthread-yield";
char constantarr_0_201[9] = "==<int32>";
char constantarr_0_202[10] = "noctx-incr";
char constantarr_0_203[7] = "max-nat";
char constantarr_0_204[9] = "wrap-incr";
char constantarr_0_205[16] = "ref-of-val<lock>";
char constantarr_0_206[2] = "lk";
char constantarr_0_207[12] = "context-head";
char constantarr_0_208[23] = "size-of<by-val<gc-ctx>>";
char constantarr_0_209[6] = "set-gc";
char constantarr_0_210[12] = "set-next-ctx";
char constantarr_0_211[13] = "value<gc-ctx>";
char constantarr_0_212[16] = "set-context-head";
char constantarr_0_213[8] = "next-ctx";
char constantarr_0_214[12] = "release-lock";
char constantarr_0_215[10] = "must-unset";
char constantarr_0_216[9] = "try-unset";
char constantarr_0_217[14] = "ref-of-val<gc>";
char constantarr_0_218[11] = "set-handler";
char constantarr_0_219[11] = "log-handler";
char constantarr_0_220[26] = "ref-of-val<island-gc-root>";
char constantarr_0_221[7] = "gc-root";
char constantarr_0_222[3] = "ctx";
char constantarr_0_223[22] = "as-any-ptr<global-ctx>";
char constantarr_0_224[2] = "id";
char constantarr_0_225[25] = "as-any-ptr<exception-ctx>";
char constantarr_0_226[19] = "as-any-ptr<log-ctx>";
char constantarr_0_227[30] = "ref-of-val<thread-local-stuff>";
char constantarr_0_228[15] = "ref-of-val<ctx>";
char constantarr_0_229[79] = "as<fun2<fut<int32>, arr<ptr<char>>, fun-ptr2<fut<int32>, ctx, arr<arr<char>>>>>";
char constantarr_0_230[14] = "add-first-task";
char constantarr_0_231[12] = "then2<int32>";
char constantarr_0_232[16] = "then<?out, void>";
char constantarr_0_233[24] = "new-unresolved-fut<?out>";
char constantarr_0_234[7] = "fut<?t>";
char constantarr_0_235[23] = "fut-state-callbacks<?t>";
char constantarr_0_236[14] = "then-void<?in>";
char constantarr_0_237[6] = "lk<?t>";
char constantarr_0_238[9] = "state<?t>";
char constantarr_0_239[13] = "set-state<?t>";
char constantarr_0_240[27] = "some<fut-callback-node<?t>>";
char constantarr_0_241[21] = "fut-callback-node<?t>";
char constantarr_0_242[8] = "head<?t>";
char constantarr_0_243[33] = "call<void, result<?t, exception>>";
char constantarr_0_244[22] = "call-with-ctx<?r, ?p0>";
char constantarr_0_245[6] = "ok<?t>";
char constantarr_0_246[9] = "value<?t>";
char constantarr_0_247[14] = "err<exception>";
char constantarr_0_248[16] = "forward-to<?out>";
char constantarr_0_249[13] = "then-void<?t>";
char constantarr_0_250[21] = "resolve-or-reject<?t>";
char constantarr_0_251[27] = "resolve-or-reject-recur<?t>";
char constantarr_0_252[4] = "void";
char constantarr_0_253[10] = "drop<void>";
char constantarr_0_254[6] = "cb<?t>";
char constantarr_0_255[28] = "value<fut-callback-node<?t>>";
char constantarr_0_256[13] = "next-node<?t>";
char constantarr_0_257[22] = "fut-state-resolved<?t>";
char constantarr_0_258[16] = "value<exception>";
char constantarr_0_259[24] = "forward-to<?out>.lambda0";
char constantarr_0_260[19] = "call-ref<?out, ?in>";
char constantarr_0_261[10] = "get-island";
char constantarr_0_262[10] = "at<island>";
char constantarr_0_263[8] = "size<?t>";
char constantarr_0_264[12] = "noctx-at<?t>";
char constantarr_0_265[9] = "deref<?t>";
char constantarr_0_266[8] = "data<?t>";
char constantarr_0_267[7] = "islands";
char constantarr_0_268[29] = "island-and-exclusion<?r, ?p0>";
char constantarr_0_269[8] = "add-task";
char constantarr_0_270[19] = "new-task-queue-node";
char constantarr_0_271[15] = "task-queue-node";
char constantarr_0_272[4] = "task";
char constantarr_0_273[10] = "tasks-lock";
char constantarr_0_274[11] = "insert-task";
char constantarr_0_275[4] = "size";
char constantarr_0_276[10] = "size-recur";
char constantarr_0_277[4] = "next";
char constantarr_0_278[22] = "value<task-queue-node>";
char constantarr_0_279[4] = "head";
char constantarr_0_280[8] = "set-head";
char constantarr_0_281[21] = "some<task-queue-node>";
char constantarr_0_282[4] = "time";
char constantarr_0_283[12] = "insert-recur";
char constantarr_0_284[8] = "set-next";
char constantarr_0_285[5] = "tasks";
char constantarr_0_286[22] = "ref-of-val<task-queue>";
char constantarr_0_287[9] = "broadcast";
char constantarr_0_288[9] = "set-value";
char constantarr_0_289[21] = "ref-of-val<condition>";
char constantarr_0_290[17] = "may-be-work-to-do";
char constantarr_0_291[4] = "gctx";
char constantarr_0_292[12] = "no-timestamp";
char constantarr_0_293[9] = "exclusion";
char constantarr_0_294[11] = "catch<void>";
char constantarr_0_295[28] = "catch-with-exception-ctx<?t>";
char constantarr_0_296[16] = "thrown-exception";
char constantarr_0_297[11] = "jmp-buf-tag";
char constantarr_0_298[4] = "zero";
char constantarr_0_299[7] = "bytes64";
char constantarr_0_300[7] = "bytes32";
char constantarr_0_301[7] = "bytes16";
char constantarr_0_302[8] = "bytes128";
char constantarr_0_303[15] = "set-jmp-buf-ptr";
char constantarr_0_304[19] = "ptr-to<jmp-buf-tag>";
char constantarr_0_305[6] = "setjmp";
char constantarr_0_306[8] = "call<?t>";
char constantarr_0_307[17] = "call-with-ctx<?r>";
char constantarr_0_308[19] = "call<?t, exception>";
char constantarr_0_309[18] = "call<fut<?r>, ?p0>";
char constantarr_0_310[12] = "fun<?r, ?p0>";
char constantarr_0_311[35] = "call-ref<?out, ?in>.lambda0.lambda0";
char constantarr_0_312[10] = "reject<?r>";
char constantarr_0_313[35] = "call-ref<?out, ?in>.lambda0.lambda1";
char constantarr_0_314[27] = "call-ref<?out, ?in>.lambda0";
char constantarr_0_315[10] = "value<?in>";
char constantarr_0_316[24] = "then<?out, void>.lambda0";
char constantarr_0_317[14] = "call-ref<?out>";
char constantarr_0_318[24] = "island-and-exclusion<?r>";
char constantarr_0_319[13] = "call<fut<?r>>";
char constantarr_0_320[7] = "fun<?r>";
char constantarr_0_321[30] = "call-ref<?out>.lambda0.lambda0";
char constantarr_0_322[30] = "call-ref<?out>.lambda0.lambda1";
char constantarr_0_323[22] = "call-ref<?out>.lambda0";
char constantarr_0_324[20] = "then2<int32>.lambda0";
char constantarr_0_325[24] = "cur-island-and-exclusion";
char constantarr_0_326[20] = "island-and-exclusion";
char constantarr_0_327[9] = "island-id";
char constantarr_0_328[5] = "delay";
char constantarr_0_329[14] = "resolved<void>";
char constantarr_0_330[15] = "tail<ptr<char>>";
char constantarr_0_331[6] = "forbid";
char constantarr_0_332[10] = "empty?<?t>";
char constantarr_0_333[21] = "slice-starting-at<?t>";
char constantarr_0_334[9] = "slice<?t>";
char constantarr_0_335[1] = "-";
char constantarr_0_336[37] = "call<fut<int32>, ctx, arr<arr<char>>>";
char constantarr_0_337[25] = "map<arr<char>, ptr<char>>";
char constantarr_0_338[14] = "make-arr<?out>";
char constantarr_0_339[18] = "fill-ptr-range<?t>";
char constantarr_0_340[24] = "fill-ptr-range-recur<?t>";
char constantarr_0_341[7] = "!=<nat>";
char constantarr_0_342[7] = "set<?t>";
char constantarr_0_343[13] = "call<?t, nat>";
char constantarr_0_344[15] = "call<?out, ?in>";
char constantarr_0_345[7] = "at<?in>";
char constantarr_0_346[33] = "map<arr<char>, ptr<char>>.lambda0";
char constantarr_0_347[24] = "arr-from-begin-end<char>";
char constantarr_0_348[5] = "-<?t>";
char constantarr_0_349[13] = "find-cstr-end";
char constantarr_0_350[17] = "find-char-in-cstr";
char constantarr_0_351[8] = "==<char>";
char constantarr_0_352[11] = "deref<char>";
char constantarr_0_353[15] = "todo<ptr<char>>";
char constantarr_0_354[10] = "incr<char>";
char constantarr_0_355[30] = "add-first-task.lambda0.lambda0";
char constantarr_0_356[22] = "add-first-task.lambda0";
char constantarr_0_357[15] = "do-main.lambda0";
char constantarr_0_358[13] = "unsafe-to-nat";
char constantarr_0_359[6] = "to-int";
char constantarr_0_360[84] = "call-with-ctx<fut<int32>, arr<ptr<char>>, fun-ptr2<fut<int32>, ctx, arr<arr<char>>>>";
char constantarr_0_361[11] = "run-threads";
char constantarr_0_362[45] = "unmanaged-alloc-elements<by-val<thread-args>>";
char constantarr_0_363[10] = "noctx-decr";
char constantarr_0_364[19] = "start-threads-recur";
char constantarr_0_365[22] = "+<by-val<thread-args>>";
char constantarr_0_366[24] = "set<by-val<thread-args>>";
char constantarr_0_367[11] = "thread-args";
char constantarr_0_368[17] = "create-one-thread";
char constantarr_0_369[14] = "pthread-create";
char constantarr_0_370[9] = "!=<int32>";
char constantarr_0_371[6] = "eagain";
char constantarr_0_372[12] = "as-cell<nat>";
char constantarr_0_373[16] = "as-ref<cell<?t>>";
char constantarr_0_374[36] = "as-any-ptr<ptr<by-val<thread-args>>>";
char constantarr_0_375[10] = "thread-fun";
char constantarr_0_376[19] = "as-ref<thread-args>";
char constantarr_0_377[15] = "thread-function";
char constantarr_0_378[21] = "thread-function-recur";
char constantarr_0_379[10] = "shut-down?";
char constantarr_0_380[18] = "set-n-live-threads";
char constantarr_0_381[14] = "n-live-threads";
char constantarr_0_382[28] = "assert-islands-are-shut-down";
char constantarr_0_383[9] = "needs-gc?";
char constantarr_0_384[17] = "n-threads-running";
char constantarr_0_385[6] = "empty?";
char constantarr_0_386[21] = "has?<task-queue-node>";
char constantarr_0_387[16] = "get-last-checked";
char constantarr_0_388[11] = "choose-task";
char constantarr_0_389[17] = "get-monotime-nsec";
char constantarr_0_390[26] = "as<by-val<cell<timespec>>>";
char constantarr_0_391[14] = "cell<timespec>";
char constantarr_0_392[8] = "timespec";
char constantarr_0_393[13] = "clock-gettime";
char constantarr_0_394[15] = "clock-monotonic";
char constantarr_0_395[26] = "ref-of-val<cell<timespec>>";
char constantarr_0_396[13] = "get<timespec>";
char constantarr_0_397[6] = "tv-sec";
char constantarr_0_398[7] = "tv-nsec";
char constantarr_0_399[9] = "todo<nat>";
char constantarr_0_400[22] = "as<choose-task-result>";
char constantarr_0_401[17] = "choose-task-recur";
char constantarr_0_402[14] = "no-chosen-task";
char constantarr_0_403[21] = "choose-task-in-island";
char constantarr_0_404[32] = "as<choose-task-in-island-result>";
char constantarr_0_405[7] = "do-a-gc";
char constantarr_0_406[7] = "no-task";
char constantarr_0_407[8] = "pop-task";
char constantarr_0_408[25] = "ref-of-val<mut-list<nat>>";
char constantarr_0_409[28] = "currently-running-exclusions";
char constantarr_0_410[19] = "as<pop-task-result>";
char constantarr_0_411[14] = "contains?<nat>";
char constantarr_0_412[13] = "contains?<?t>";
char constantarr_0_413[19] = "contains-recur?<?t>";
char constantarr_0_414[15] = "temp-as-arr<?t>";
char constantarr_0_415[19] = "temp-as-mut-arr<?t>";
char constantarr_0_416[11] = "backing<?t>";
char constantarr_0_417[9] = "pop-recur";
char constantarr_0_418[11] = "to-opt-time";
char constantarr_0_419[9] = "some<nat>";
char constantarr_0_420[37] = "push-capacity-must-be-sufficient<nat>";
char constantarr_0_421[12] = "capacity<?t>";
char constantarr_0_422[12] = "set-size<?t>";
char constantarr_0_423[16] = "noctx-set-at<?t>";
char constantarr_0_424[11] = "is-no-task?";
char constantarr_0_425[21] = "set-n-threads-running";
char constantarr_0_426[11] = "chosen-task";
char constantarr_0_427[10] = "any-tasks?";
char constantarr_0_428[8] = "min-time";
char constantarr_0_429[8] = "min<nat>";
char constantarr_0_430[5] = "?<?t>";
char constantarr_0_431[10] = "value<nat>";
char constantarr_0_432[15] = "first-task-time";
char constantarr_0_433[29] = "no-tasks-and-last-thread-out?";
char constantarr_0_434[7] = "do-task";
char constantarr_0_435[11] = "task-island";
char constantarr_0_436[10] = "task-or-gc";
char constantarr_0_437[6] = "action";
char constantarr_0_438[11] = "return-task";
char constantarr_0_439[32] = "noctx-must-remove-unordered<nat>";
char constantarr_0_440[37] = "noctx-must-remove-unordered-recur<?t>";
char constantarr_0_441[8] = "drop<?t>";
char constantarr_0_442[35] = "noctx-remove-unordered-at-index<?t>";
char constantarr_0_443[14] = "noctx-last<?t>";
char constantarr_0_444[10] = "return-ctx";
char constantarr_0_445[13] = "return-gc-ctx";
char constantarr_0_446[12] = "some<gc-ctx>";
char constantarr_0_447[46] = "run-garbage-collection<by-val<island-gc-root>>";
char constantarr_0_448[13] = "set-needs-gc?";
char constantarr_0_449[12] = "set-gc-count";
char constantarr_0_450[8] = "gc-count";
char constantarr_0_451[20] = "as<by-val<mark-ctx>>";
char constantarr_0_452[8] = "mark-ctx";
char constantarr_0_453[14] = "mark-visit<?a>";
char constantarr_0_454[20] = "ref-of-val<mark-ctx>";
char constantarr_0_455[14] = "clear-free-mem";
char constantarr_0_456[14] = "set-shut-down?";
char constantarr_0_457[7] = "wait-on";
char constantarr_0_458[12] = "before-time?";
char constantarr_0_459[9] = "thread-id";
char constantarr_0_460[18] = "join-threads-recur";
char constantarr_0_461[15] = "join-one-thread";
char constantarr_0_462[27] = "as<by-val<cell<ptr<nat8>>>>";
char constantarr_0_463[15] = "cell<ptr<nat8>>";
char constantarr_0_464[12] = "pthread-join";
char constantarr_0_465[27] = "ref-of-val<cell<ptr<nat8>>>";
char constantarr_0_466[6] = "einval";
char constantarr_0_467[5] = "esrch";
char constantarr_0_468[14] = "get<ptr<nat8>>";
char constantarr_0_469[19] = "unmanaged-free<nat>";
char constantarr_0_470[4] = "free";
char constantarr_0_471[35] = "unmanaged-free<by-val<thread-args>>";
char constantarr_0_472[18] = "ptr-cast<nat8, ?t>";
char constantarr_0_473[23] = "must-be-resolved<int32>";
char constantarr_0_474[39] = "hard-unreachable<result<?t, exception>>";
char constantarr_0_475[8] = "?<int32>";
char constantarr_0_476[25] = "any-unhandled-exceptions?";
char constantarr_0_477[4] = "main";
char constantarr_0_478[3] = "log";
char constantarr_0_479[18] = "call<void, logged>";
char constantarr_0_480[15] = "get-log-handler";
char constantarr_0_481[7] = "handler";
char constantarr_0_482[11] = "get-log-ctx";
char constantarr_0_483[15] = "as-ref<log-ctx>";
char constantarr_0_484[6] = "logged";
char constantarr_0_485[22] = "as<fun1<void, logged>>";
char constantarr_0_486[12] = "main.lambda0";
char constantarr_0_487[22] = "with-log-handler<void>";
char constantarr_0_488[11] = "finally<?t>";
char constantarr_0_489[19] = "finally<?t>.lambda0";
char constantarr_0_490[15] = "set-log-handler";
char constantarr_0_491[30] = "with-log-handler<void>.lambda0";
char constantarr_0_492[30] = "with-log-handler<void>.lambda1";
char constantarr_0_493[12] = "main.lambda1";
char constantarr_0_494[12] = "drop<logged>";
char constantarr_0_495[12] = "main.lambda2";
char constantarr_0_496[12] = "main.lambda3";
char constantarr_0_497[15] = "resolved<int32>";
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
extern uint64_t get_nprocs(void);
struct lock new_lock(void);
struct _atomic_bool new_atomic_bool(void);
struct arr_3 empty_arr(void);
struct condition new_condition(void);
struct island new_island(struct global_ctx* gctx, uint64_t id, uint64_t max_threads);
struct task_queue new_task_queue(uint64_t max_threads);
struct mut_list new_mut_list_by_val_with_capacity_from_unmanaged_memory(uint64_t capacity);
struct mut_arr mut_arr(uint64_t size, uint64_t* data);
uint64_t* unmanaged_alloc_zeroed_elements(uint64_t size_elements);
uint64_t* unmanaged_alloc_elements_0(uint64_t size_elements);
uint8_t* unmanaged_alloc_bytes(uint64_t size);
extern uint8_t* malloc(uint64_t size);
struct void_ hard_forbid(uint8_t condition);
uint8_t null__q_0(uint8_t* a);
struct void_ set_zero_range(uint64_t* begin, uint64_t size);
extern void memset(uint8_t* begin, uint8_t value, uint64_t size);
struct void_ default_exception_handler(struct ctx* ctx, struct exception e);
struct void_ print_err_no_newline(struct arr_0 s);
struct void_ write_no_newline(int32_t fd, struct arr_0 a);
extern int64_t write(int32_t fd, uint8_t* buf, uint64_t n_bytes);
uint8_t _op_bang_equal_0(int64_t a, int64_t b);
uint8_t _op_equal_equal_1(int64_t a, int64_t b);
struct comparison compare_36(int64_t a, int64_t b);
struct void_ todo_0(void);
int32_t stderr(void);
struct void_ print_err(struct arr_0 s);
uint8_t empty__q_0(struct arr_0 a);
struct global_ctx* get_global_ctx(struct ctx* ctx);
struct void_ new_island__lambda0(struct ctx* ctx, struct void_ _closure, struct exception it);
struct void_ default_log_handler(struct ctx* ctx, struct logged* a);
struct void_ print(struct arr_0 a);
struct void_ print_no_newline(struct arr_0 a);
int32_t stdout(void);
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
uint64_t _op_minus_1(uint8_t* a, uint8_t* b);
uint8_t range_free__q(uint8_t* mark, uint8_t* end);
uint64_t* incr_1(uint64_t* p);
uint8_t* todo_1(void);
struct gc* get_gc(struct ctx* ctx);
struct gc_ctx* get_gc_ctx_0(struct ctx* ctx);
struct void_ copy_data_from(struct ctx* ctx, char* to, char* from, uint64_t len);
extern void memcpy(uint8_t* dest, uint8_t* src, uint64_t size);
struct arr_0 to_str_0(struct ctx* ctx, struct log_level a);
struct void_ new_island__lambda1(struct ctx* ctx, struct void_ _closure, struct logged* log);
struct gc new_gc(void);
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
uint8_t _op_equal_equal_2(int32_t a, int32_t b);
struct comparison compare_91(int32_t a, int32_t b);
uint64_t noctx_incr(uint64_t n);
uint64_t max_nat(void);
uint64_t wrap_incr(uint64_t a);
struct void_ release_lock(struct lock* l);
struct void_ must_unset(struct _atomic_bool* a);
uint8_t try_unset(struct _atomic_bool* a);
struct fut_0* add_first_task(struct ctx* ctx, struct arr_4 all_args, fun_ptr2 main_ptr);
struct fut_0* then2(struct ctx* ctx, struct fut_1* f, struct fun_ref0 cb);
struct fut_0* then(struct ctx* ctx, struct fut_1* f, struct fun_ref1 cb);
struct fut_0* new_unresolved_fut(struct ctx* ctx);
struct void_ then_void_0(struct ctx* ctx, struct fut_1* f, struct fun_act1_1 cb);
struct void_ call_0(struct ctx* ctx, struct fun_act1_1 a, struct result_1 p0);
struct void_ call_w_ctx_104(struct fun_act1_1 a, struct ctx* ctx, struct result_1 p0);
struct void_ forward_to(struct ctx* ctx, struct fut_0* from, struct fut_0* to);
struct void_ then_void_1(struct ctx* ctx, struct fut_0* f, struct fun_act1_0 cb);
struct void_ call_1(struct ctx* ctx, struct fun_act1_0 a, struct result_0 p0);
struct void_ call_w_ctx_108(struct fun_act1_0 a, struct ctx* ctx, struct result_0 p0);
struct void_ resolve_or_reject(struct ctx* ctx, struct fut_0* f, struct result_0 result);
struct void_ resolve_or_reject_recur(struct ctx* ctx, struct opt_0 node, struct result_0 value);
struct void_ drop_0(struct void_ _p0);
struct void_ forward_to__lambda0(struct ctx* ctx, struct forward_to__lambda0* _closure, struct result_0 it);
struct fut_0* call_ref_0(struct ctx* ctx, struct fun_ref1 f, struct void_ p0);
struct island* get_island(struct ctx* ctx, uint64_t island_id);
struct island* at_0(struct ctx* ctx, struct arr_3 a, uint64_t index);
struct island* noctx_at_0(struct arr_3 a, uint64_t index);
struct void_ add_task_0(struct ctx* ctx, struct island* a, uint64_t exclusion, struct fun_act0_0 action);
struct void_ add_task_1(struct ctx* ctx, struct island* a, uint64_t timestamp, uint64_t exclusion, struct fun_act0_0 action);
struct task_queue_node* new_task_queue_node(struct ctx* ctx, struct task task);
struct void_ insert_task(struct task_queue* a, struct task_queue_node* inserted);
uint64_t size_0(struct task_queue* a);
uint64_t size_recur(struct opt_2 node, uint64_t acc);
struct void_ insert_recur(struct task_queue_node* prev, struct task_queue_node* inserted);
struct task_queue* tasks(struct island* a);
struct void_ broadcast(struct condition* c);
uint64_t no_timestamp(void);
struct void_ catch(struct ctx* ctx, struct fun_act0_0 try, struct fun_act1_3 catcher);
struct void_ catch_with_exception_ctx(struct ctx* ctx, struct exception_ctx* ec, struct fun_act0_0 try, struct fun_act1_3 catcher);
struct bytes64 zero_0(void);
struct bytes32 zero_1(void);
struct bytes16 zero_2(void);
struct bytes128 zero_3(void);
extern int32_t setjmp(struct jmp_buf_tag* env);
struct void_ call_2(struct ctx* ctx, struct fun_act0_0 a);
struct void_ call_w_ctx_135(struct fun_act0_0 a, struct ctx* ctx);
struct void_ call_3(struct ctx* ctx, struct fun_act1_3 a, struct exception p0);
struct void_ call_w_ctx_137(struct fun_act1_3 a, struct ctx* ctx, struct exception p0);
struct fut_0* call_4(struct ctx* ctx, struct fun_act1_2 a, struct void_ p0);
struct fut_0* call_w_ctx_139(struct fun_act1_2 a, struct ctx* ctx, struct void_ p0);
struct void_ call_ref_0__lambda0__lambda0(struct ctx* ctx, struct call_ref_0__lambda0__lambda0* _closure);
struct void_ reject(struct ctx* ctx, struct fut_0* f, struct exception e);
struct void_ call_ref_0__lambda0__lambda1(struct ctx* ctx, struct call_ref_0__lambda0__lambda1* _closure, struct exception it);
struct void_ call_ref_0__lambda0(struct ctx* ctx, struct call_ref_0__lambda0* _closure);
struct void_ then__lambda0(struct ctx* ctx, struct then__lambda0* _closure, struct result_1 result);
struct fut_0* call_ref_1(struct ctx* ctx, struct fun_ref0 f);
struct fut_0* call_5(struct ctx* ctx, struct fun_act0_1 a);
struct fut_0* call_w_ctx_147(struct fun_act0_1 a, struct ctx* ctx);
struct void_ call_ref_1__lambda0__lambda0(struct ctx* ctx, struct call_ref_1__lambda0__lambda0* _closure);
struct void_ call_ref_1__lambda0__lambda1(struct ctx* ctx, struct call_ref_1__lambda0__lambda1* _closure, struct exception it);
struct void_ call_ref_1__lambda0(struct ctx* ctx, struct call_ref_1__lambda0* _closure);
struct fut_0* then2__lambda0(struct ctx* ctx, struct then2__lambda0* _closure, struct void_ ignore);
struct island_and_exclusion cur_island_and_exclusion(struct ctx* ctx);
struct fut_1* delay(struct ctx* ctx);
struct fut_1* resolved_0(struct ctx* ctx, struct void_ value);
struct arr_4 tail(struct ctx* ctx, struct arr_4 a);
struct void_ forbid_0(struct ctx* ctx, uint8_t condition);
struct void_ forbid_1(struct ctx* ctx, uint8_t condition, struct arr_0 message);
uint8_t empty__q_1(struct arr_4 a);
struct arr_4 slice_starting_at(struct ctx* ctx, struct arr_4 a, uint64_t begin);
struct arr_4 slice(struct ctx* ctx, struct arr_4 a, uint64_t begin, uint64_t size);
uint64_t _op_minus_2(struct ctx* ctx, uint64_t a, uint64_t b);
struct arr_1 map(struct ctx* ctx, struct arr_4 a, struct fun_act1_4 mapper);
struct arr_1 make_arr(struct ctx* ctx, uint64_t size, struct fun_act1_5 f);
struct arr_0* uninitialized_data_1(struct ctx* ctx, uint64_t size);
struct void_ fill_ptr_range(struct ctx* ctx, struct arr_0* begin, uint64_t size, struct fun_act1_5 f);
struct void_ fill_ptr_range_recur(struct ctx* ctx, struct arr_0* begin, uint64_t i, uint64_t size, struct fun_act1_5 f);
uint8_t _op_bang_equal_1(uint64_t a, uint64_t b);
struct arr_0 call_6(struct ctx* ctx, struct fun_act1_5 a, uint64_t p0);
struct arr_0 call_w_ctx_169(struct fun_act1_5 a, struct ctx* ctx, uint64_t p0);
struct arr_0 call_7(struct ctx* ctx, struct fun_act1_4 a, char* p0);
struct arr_0 call_w_ctx_171(struct fun_act1_4 a, struct ctx* ctx, char* p0);
char* at_1(struct ctx* ctx, struct arr_4 a, uint64_t index);
char* noctx_at_1(struct arr_4 a, uint64_t index);
struct arr_0 map__lambda0(struct ctx* ctx, struct map__lambda0* _closure, uint64_t i);
struct arr_0 to_str_1(char* a);
struct arr_0 arr_from_begin_end(char* begin, char* end);
uint64_t _op_minus_3(char* a, char* b);
char* find_cstr_end(char* a);
char* find_char_in_cstr(char* a, char c);
uint8_t _op_equal_equal_3(char a, char b);
struct comparison compare_181(char a, char b);
char* todo_2(void);
char* incr_2(char* p);
struct arr_0 add_first_task__lambda0__lambda0(struct ctx* ctx, struct void_ _closure, char* it);
struct fut_0* add_first_task__lambda0(struct ctx* ctx, struct add_first_task__lambda0* _closure);
struct fut_0* do_main__lambda0(struct ctx* ctx, struct void_ _closure, struct arr_4 all_args, fun_ptr2 main_ptr);
struct fut_0* call_w_ctx_187(struct fun2 a, struct ctx* ctx, struct arr_4 p0, fun_ptr2 p1);
struct void_ run_threads(uint64_t n_threads, struct global_ctx* gctx);
struct thread_args* unmanaged_alloc_elements_1(uint64_t size_elements);
uint64_t noctx_decr(uint64_t n);
struct void_ start_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads, struct thread_args* thread_args_begin, struct global_ctx* gctx);
struct void_ create_one_thread(struct cell_0* tid, uint8_t* thread_arg, fun_ptr1 thread_fun);
extern int32_t pthread_create(struct cell_0* thread, uint8_t* attr, fun_ptr1 start_routine, uint8_t* arg);
uint8_t _op_bang_equal_2(int32_t a, int32_t b);
int32_t eagain(void);
struct cell_0* as_cell(uint64_t* p);
uint8_t* thread_fun(uint8_t* args_ptr);
struct void_ thread_function(uint64_t thread_id, struct global_ctx* gctx);
struct void_ thread_function_recur(uint64_t thread_id, struct global_ctx* gctx, struct thread_local_stuff* tls);
struct void_ assert_islands_are_shut_down(uint64_t i, struct arr_3 islands);
uint8_t empty__q_2(struct task_queue* a);
uint8_t has__q(struct opt_2 a);
uint8_t empty__q_3(struct opt_2 a);
uint64_t get_last_checked(struct condition* c);
struct choose_task_result choose_task(struct global_ctx* gctx);
uint64_t get_monotime_nsec(void);
extern int32_t clock_gettime(int32_t clock_it, struct cell_1* tp);
int32_t clock_monotonic(void);
struct timespec get_0(struct cell_1* c);
uint64_t todo_3(void);
struct choose_task_result choose_task_recur(struct arr_3 islands, uint64_t i, uint64_t cur_time, uint8_t any_tasks__q, struct opt_5 first_task_time);
struct choose_task_in_island_result choose_task_in_island(struct island* island, uint64_t cur_time);
struct pop_task_result pop_task(struct task_queue* a, uint64_t cur_time);
uint8_t contains__q_0(struct mut_list* a, uint64_t value);
uint8_t contains__q_1(struct arr_2 a, uint64_t value);
uint8_t contains_recur__q(struct arr_2 a, uint64_t value, uint64_t i);
uint64_t noctx_at_2(struct arr_2 a, uint64_t index);
struct arr_2 temp_as_arr_0(struct mut_list* a);
struct arr_2 temp_as_arr_1(struct mut_arr a);
struct mut_arr temp_as_mut_arr(struct mut_list* a);
uint64_t* data_0(struct mut_list* a);
uint64_t* data_1(struct mut_arr a);
struct pop_task_result pop_recur(struct task_queue_node* prev, struct mut_list* exclusions, uint64_t cur_time, struct opt_5 first_task_time);
struct opt_5 to_opt_time(uint64_t a);
struct void_ push_capacity_must_be_sufficient(struct mut_list* a, uint64_t value);
uint64_t capacity(struct mut_list* a);
uint64_t size_1(struct mut_arr a);
struct void_ noctx_set_at(struct mut_list* a, uint64_t index, uint64_t value);
uint8_t is_no_task__q(struct choose_task_in_island_result a);
struct opt_5 min_time(struct opt_5 a, struct opt_5 b);
uint64_t min(uint64_t a, uint64_t b);
struct void_ do_task(struct global_ctx* gctx, struct thread_local_stuff* tls, struct chosen_task chosen_task);
struct void_ return_task(struct task_queue* a, struct task task);
struct void_ noctx_must_remove_unordered(struct mut_list* a, uint64_t value);
struct void_ noctx_must_remove_unordered_recur(struct mut_list* a, uint64_t index, uint64_t value);
uint64_t noctx_at_3(struct mut_list* a, uint64_t index);
struct void_ drop_1(uint64_t _p0);
uint64_t noctx_remove_unordered_at_index(struct mut_list* a, uint64_t index);
uint64_t noctx_last(struct mut_list* a);
uint8_t empty__q_4(struct mut_list* a);
struct void_ return_ctx(struct ctx* c);
struct void_ return_gc_ctx(struct gc_ctx* gc_ctx);
struct void_ run_garbage_collection(struct gc* gc, struct island_gc_root gc_root);
struct void_ mark_visit_244(struct mark_ctx* mark_ctx, struct island_gc_root value);
struct void_ mark_visit_245(struct mark_ctx* mark_ctx, struct task_queue value);
struct void_ mark_visit_246(struct mark_ctx* mark_ctx, struct opt_2 value);
struct void_ mark_visit_247(struct mark_ctx* mark_ctx, struct some_2 value);
struct void_ mark_visit_248(struct mark_ctx* mark_ctx, struct task_queue_node value);
struct void_ mark_visit_249(struct mark_ctx* mark_ctx, struct task value);
struct void_ mark_visit_250(struct mark_ctx* mark_ctx, struct fun_act0_0 value);
struct void_ mark_visit_251(struct mark_ctx* mark_ctx, struct call_ref_0__lambda0__lambda0 value);
struct void_ mark_visit_252(struct mark_ctx* mark_ctx, struct fun_ref1 value);
struct void_ mark_visit_253(struct mark_ctx* mark_ctx, struct fun_act1_2 value);
struct void_ mark_visit_254(struct mark_ctx* mark_ctx, struct then2__lambda0 value);
struct void_ mark_visit_255(struct mark_ctx* mark_ctx, struct fun_ref0 value);
struct void_ mark_visit_256(struct mark_ctx* mark_ctx, struct fun_act0_1 value);
struct void_ mark_visit_257(struct mark_ctx* mark_ctx, struct add_first_task__lambda0 value);
struct void_ mark_arr_258(struct mark_ctx* mark_ctx, struct arr_4 a);
struct void_ mark_visit_259(struct mark_ctx* mark_ctx, struct add_first_task__lambda0* value);
struct void_ mark_visit_260(struct mark_ctx* mark_ctx, struct then2__lambda0* value);
struct void_ mark_visit_261(struct mark_ctx* mark_ctx, struct fut_0 value);
struct void_ mark_visit_262(struct mark_ctx* mark_ctx, struct fut_state_0 value);
struct void_ mark_visit_263(struct mark_ctx* mark_ctx, struct fut_state_callbacks_0 value);
struct void_ mark_visit_264(struct mark_ctx* mark_ctx, struct opt_0 value);
struct void_ mark_visit_265(struct mark_ctx* mark_ctx, struct some_0 value);
struct void_ mark_visit_266(struct mark_ctx* mark_ctx, struct fut_callback_node_0 value);
struct void_ mark_visit_267(struct mark_ctx* mark_ctx, struct fun_act1_0 value);
struct void_ mark_visit_268(struct mark_ctx* mark_ctx, struct forward_to__lambda0 value);
struct void_ mark_visit_269(struct mark_ctx* mark_ctx, struct fut_0* value);
struct void_ mark_visit_270(struct mark_ctx* mark_ctx, struct forward_to__lambda0* value);
struct void_ mark_visit_271(struct mark_ctx* mark_ctx, struct fut_callback_node_0* value);
struct void_ mark_visit_272(struct mark_ctx* mark_ctx, struct exception value);
struct void_ mark_arr_273(struct mark_ctx* mark_ctx, struct arr_0 a);
struct void_ mark_visit_274(struct mark_ctx* mark_ctx, struct call_ref_0__lambda0__lambda0* value);
struct void_ mark_visit_275(struct mark_ctx* mark_ctx, struct call_ref_0__lambda0 value);
struct void_ mark_visit_276(struct mark_ctx* mark_ctx, struct call_ref_0__lambda0* value);
struct void_ mark_visit_277(struct mark_ctx* mark_ctx, struct call_ref_1__lambda0__lambda0 value);
struct void_ mark_visit_278(struct mark_ctx* mark_ctx, struct call_ref_1__lambda0__lambda0* value);
struct void_ mark_visit_279(struct mark_ctx* mark_ctx, struct call_ref_1__lambda0 value);
struct void_ mark_visit_280(struct mark_ctx* mark_ctx, struct call_ref_1__lambda0* value);
struct void_ mark_visit_281(struct mark_ctx* mark_ctx, struct with_log_handler__lambda0 value);
struct void_ mark_visit_282(struct mark_ctx* mark_ctx, struct fun1_1 value);
struct void_ mark_visit_283(struct mark_ctx* mark_ctx, struct main_0__lambda0 value);
struct void_ mark_visit_284(struct mark_ctx* mark_ctx, struct main_0__lambda0* value);
struct void_ mark_visit_285(struct mark_ctx* mark_ctx, struct with_log_handler__lambda0* value);
struct void_ mark_visit_286(struct mark_ctx* mark_ctx, struct with_log_handler__lambda1 value);
struct void_ mark_visit_287(struct mark_ctx* mark_ctx, struct with_log_handler__lambda1* value);
struct void_ mark_visit_288(struct mark_ctx* mark_ctx, struct task_queue_node* value);
struct void_ mark_visit_289(struct mark_ctx* mark_ctx, struct mut_list value);
struct void_ mark_visit_290(struct mark_ctx* mark_ctx, struct mut_arr value);
struct void_ mark_arr_291(struct mark_ctx* mark_ctx, struct arr_2 a);
struct void_ clear_free_mem(uint8_t* mark_ptr, uint8_t* mark_end, uint64_t* data_ptr);
struct void_ wait_on(struct condition* cond, struct opt_5 until_time, uint64_t last_checked);
uint8_t before_time__q(struct opt_5 until_time);
struct void_ join_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads);
struct void_ join_one_thread(uint64_t tid);
extern int32_t pthread_join(uint64_t thread, struct cell_2* thread_return);
int32_t einval(void);
int32_t esrch(void);
uint8_t* get_1(struct cell_2* c);
struct void_ unmanaged_free_0(uint64_t* p);
extern void free(uint8_t* p);
struct void_ unmanaged_free_1(struct thread_args* p);
struct result_0 must_be_resolved(struct fut_0* f);
struct result_0 hard_unreachable(void);
struct fut_0* main_0(struct ctx* ctx, struct arr_1 _p0);
struct void_ log(struct ctx* ctx, struct log_level level, struct arr_0 message);
struct void_ call_8(struct ctx* ctx, struct fun1_1 a, struct logged* p0);
struct void_ call_w_ctx_309(struct fun1_1 a, struct ctx* ctx, struct logged* p0);
struct fun1_1 get_log_handler(struct ctx* ctx);
struct log_ctx* get_log_ctx(struct ctx* ctx);
struct void_ main_0__lambda0(struct ctx* ctx, struct main_0__lambda0* _closure, struct logged* logged);
struct void_ with_log_handler(struct ctx* ctx, struct fun1_1 handler, struct fun_act0_0 cb);
struct void_ finally(struct ctx* ctx, struct fun_act0_0 after, struct fun_act0_0 try);
struct void_ finally__lambda0(struct ctx* ctx, struct finally__lambda0* _closure, struct exception err);
struct void_ set_log_handler(struct ctx* ctx, struct fun1_1 handler);
struct void_ with_log_handler__lambda0(struct ctx* ctx, struct with_log_handler__lambda0* _closure);
struct void_ with_log_handler__lambda1(struct ctx* ctx, struct with_log_handler__lambda1* _closure);
struct void_ main_0__lambda1(struct ctx* ctx, struct void_ _closure);
struct void_ drop_2(struct logged* _p0);
struct void_ main_0__lambda2(struct ctx* ctx, struct void_ _closure, struct logged* it);
struct void_ main_0__lambda3(struct ctx* ctx, struct void_ _closure);
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
	uint64_t n_threads0;
	n_threads0 = get_nprocs();
	
	struct global_ctx gctx_by_val1;
	struct lock _0 = new_lock();
	struct arr_3 _1 = empty_arr();
	uint64_t _2 = n_threads0;
	struct condition _3 = new_condition();
	uint8_t _4 = 0;
	uint8_t _5 = 0;
	gctx_by_val1 = (struct global_ctx) {_0, _1, _2, _3, _4, _5};
	
	struct global_ctx* gctx2;
	gctx2 = &gctx_by_val1;
	
	struct island island_by_val3;
	struct global_ctx* _6 = gctx2;
	uint64_t _7 = 0u;
	uint64_t _8 = n_threads0;
	island_by_val3 = new_island(_6, _7, _8);
	
	struct island* island4;
	island4 = &island_by_val3;
	
	struct global_ctx* _9 = gctx2;
	uint64_t _10 = 1u;
	struct island** _11 = &island4;
	struct arr_3 _12 = (struct arr_3) {_10, _11};
	_9->islands = _12;
	struct fut_0* main_fut5;
	struct global_ctx* _13 = gctx2;
	struct island* _14 = island4;
	int32_t _15 = argc;
	char** _16 = argv;
	fun_ptr2 _17 = main_ptr;
	main_fut5 = do_main(_13, _14, _15, _16, _17);
	
	uint64_t _18 = n_threads0;
	struct global_ctx* _19 = gctx2;
	run_threads(_18, _19);
	struct fut_0* _20 = main_fut5;
	struct result_0 _21 = must_be_resolved(_20);
	switch (_21.kind) {
		case 0: {
			struct ok_0 o6 = _21.as0;
			
			struct global_ctx* _22 = gctx2;
			uint8_t _23 = _22->any_unhandled_exceptions__q;
			if (_23) {
				return 1;
			} else {
				struct ok_0 _24 = o6;
				return _24.value;
			}
		}
		case 1: {
			struct err e7 = _21.as1;
			
			struct arr_0 _25 = (struct arr_0) {13, constantarr_0_14};
			print_err_no_newline(_25);
			struct err _26 = e7;
			struct exception _27 = _26.value;
			struct arr_0 _28 = _27.message;
			print_err(_28);
			return 1;
		}
		default:
			return (assert(0),0);
	}
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
struct arr_3 empty_arr(void) {
	uint64_t _0 = 0u;
	struct island** _1 = NULL;
	return (struct arr_3) {_0, _1};
}
/* new-condition condition() */
struct condition new_condition(void) {
	struct lock _0 = new_lock();
	uint64_t _1 = 0u;
	return (struct condition) {_0, _1};
}
/* new-island island(gctx global-ctx, id nat, max-threads nat) */
struct island new_island(struct global_ctx* gctx, uint64_t id, uint64_t max_threads) {
	struct task_queue q0;
	uint64_t _0 = max_threads;
	q0 = new_task_queue(_0);
	
	struct island_gc_root gc_root1;
	struct task_queue _1 = q0;
	struct void_ _2 = (struct void_) {};
	struct fun1_0 _3 = (struct fun1_0) {0, .as0 = _2};
	struct void_ _4 = (struct void_) {};
	struct fun1_1 _5 = (struct fun1_1) {0, .as0 = _4};
	gc_root1 = (struct island_gc_root) {_1, _3, _5};
	
	struct global_ctx* _6 = gctx;
	uint64_t _7 = id;
	struct gc _8 = new_gc();
	struct island_gc_root _9 = gc_root1;
	struct lock _10 = new_lock();
	uint64_t _11 = 0u;
	struct thread_safe_counter _12 = new_thread_safe_counter_0();
	return (struct island) {_6, _7, _8, _9, _10, _11, _12};
}
/* new-task-queue task-queue(max-threads nat) */
struct task_queue new_task_queue(uint64_t max_threads) {
	struct none _0 = (struct none) {};
	struct opt_2 _1 = (struct opt_2) {0, .as0 = _0};
	uint64_t _2 = max_threads;
	struct mut_list _3 = new_mut_list_by_val_with_capacity_from_unmanaged_memory(_2);
	return (struct task_queue) {_1, _3};
}
/* new-mut-list-by-val-with-capacity-from-unmanaged-memory<nat> mut-list<nat>(capacity nat) */
struct mut_list new_mut_list_by_val_with_capacity_from_unmanaged_memory(uint64_t capacity) {
	struct mut_arr backing0;
	uint64_t _0 = capacity;
	uint64_t _1 = capacity;
	uint64_t* _2 = unmanaged_alloc_zeroed_elements(_1);
	backing0 = mut_arr(_0, _2);
	
	struct mut_arr _3 = backing0;
	uint64_t _4 = 0u;
	return (struct mut_list) {_3, _4};
}
/* mut-arr<?t> mut-arr<nat>(size nat, data ptr<nat>) */
struct mut_arr mut_arr(uint64_t size, uint64_t* data) {
	uint64_t _0 = size;
	uint64_t* _1 = data;
	struct arr_2 _2 = (struct arr_2) {_0, _1};
	return (struct mut_arr) {_2};
}
/* unmanaged-alloc-zeroed-elements<?t> ptr<nat>(size-elements nat) */
uint64_t* unmanaged_alloc_zeroed_elements(uint64_t size_elements) {
	uint64_t* res0;
	uint64_t _0 = size_elements;
	res0 = unmanaged_alloc_elements_0(_0);
	
	uint64_t* _1 = res0;
	uint64_t _2 = size_elements;
	set_zero_range(_1, _2);
	return res0;
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
/* set-zero-range<?t> void(begin ptr<nat>, size nat) */
struct void_ set_zero_range(uint64_t* begin, uint64_t size) {
	uint64_t* _0 = begin;
	uint8_t* _1 = (uint8_t*) _0;
	uint8_t _2 = 0u;
	uint64_t _3 = size;
	uint64_t _4 = sizeof(uint64_t);
	uint64_t _5 = _3 * _4;
	return (memset(_1, _2, _5), (struct void_) {});
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
	struct global_ctx* _7 = get_global_ctx(_6);
	uint8_t _8 = 1;
	return (_7->any_unhandled_exceptions__q = _8, (struct void_) {});
}
/* print-err-no-newline void(s arr<char>) */
struct void_ print_err_no_newline(struct arr_0 s) {
	int32_t _0 = stderr();
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
		return todo_0();
	} else {
		return (struct void_) {};
	}
}
/* !=<int> bool(a int, b int) */
uint8_t _op_bang_equal_0(int64_t a, int64_t b) {
	int64_t _0 = a;
	int64_t _1 = b;
	uint8_t _2 = _op_equal_equal_1(_0, _1);
	return !_2;
}
/* ==<?t> bool(a int, b int) */
uint8_t _op_equal_equal_1(int64_t a, int64_t b) {
	int64_t _0 = a;
	int64_t _1 = b;
	struct comparison _2 = compare_36(_0, _1);
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
struct comparison compare_36(int64_t a, int64_t b) {
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
struct void_ todo_0(void) {
	return (assert(0),(struct void_) {});
}
/* stderr int32() */
int32_t stderr(void) {
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
/* get-global-ctx global-ctx() */
struct global_ctx* get_global_ctx(struct ctx* ctx) {
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
	struct arr_0 _5 = to_str_0(_2, _4);
	struct arr_0 _6 = (struct arr_0) {2, constantarr_0_8};
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
	int32_t _0 = stdout();
	struct arr_0 _1 = a;
	return write_no_newline(_0, _1);
}
/* stdout int32() */
int32_t stdout(void) {
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
	return todo_0();
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
			return todo_1();
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
			uint64_t* _33 = incr_1(_32);
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
	mark_idx0 = _op_minus_1(_21, _23);
	
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
	uint64_t _32 = _op_minus_1(_29, _31);
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
uint64_t _op_minus_1(uint8_t* a, uint8_t* b) {
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
uint64_t* incr_1(uint64_t* p) {
	uint64_t* _0 = p;
	uint64_t _1 = 1u;
	return _0 + _1;
}
/* todo<ptr<nat8>> ptr<nat8>() */
uint8_t* todo_1(void) {
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
	char* _0 = to;
	uint8_t* _1 = (uint8_t*) _0;
	char* _2 = from;
	uint8_t* _3 = (uint8_t*) _2;
	uint64_t _4 = len;
	uint64_t _5 = sizeof(char);
	uint64_t _6 = _4 * _5;
	return (memcpy(_1, _3, _6), (struct void_) {});
}
/* to-str arr<char>(a log-level) */
struct arr_0 to_str_0(struct ctx* ctx, struct log_level a) {
	struct log_level _0 = a;
	switch (_0.kind) {
		case 0: {
			return (struct arr_0) {4, constantarr_0_6};
		}
		case 1: {
			return (struct arr_0) {4, constantarr_0_7};
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
	
	struct arr_4 all_args6;
	int32_t _7 = argc;
	int64_t _8 = (int64_t) _7;
	uint64_t _9 = (uint64_t) _8;
	char** _10 = argv;
	all_args6 = (struct arr_4) {_9, _10};
	
	struct fun2 _11 = add5;
	struct ctx* _12 = ctx4;
	struct arr_4 _13 = all_args6;
	fun_ptr2 _14 = main_ptr;
	return call_w_ctx_187(_11, _12, _13, _14);
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
	struct fun1_1 _0 = (struct fun1_1) {0};
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
	struct fun1_1 _6 = _5->log_handler;
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
	uint8_t _2 = _op_equal_equal_2(_0, _1);
	return hard_assert(_2);
}
/* ==<int32> bool(a int32, b int32) */
uint8_t _op_equal_equal_2(int32_t a, int32_t b) {
	int32_t _0 = a;
	int32_t _1 = b;
	struct comparison _2 = compare_91(_0, _1);
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
struct comparison compare_91(int32_t a, int32_t b) {
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
struct fut_0* add_first_task(struct ctx* ctx, struct arr_4 all_args, fun_ptr2 main_ptr) {
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
	struct arr_4 _9 = all_args;
	fun_ptr2 _10 = main_ptr;
	struct add_first_task__lambda0 _11 = (struct add_first_task__lambda0) {_9, _10};
	*_8 = _11;
	struct add_first_task__lambda0* _12 = temp0;
	struct fun_act0_1 _13 = (struct fun_act0_1) {0, .as0 = _12};
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
	struct fun_act1_2 _11 = (struct fun_act1_2) {0, .as0 = _10};
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
	struct fun_act1_1 _11 = (struct fun_act1_1) {0, .as0 = _10};
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
/* then-void<?in> void(f fut<void>, cb fun-act1<void, result<void, exception>>) */
struct void_ then_void_0(struct ctx* ctx, struct fut_1* f, struct fun_act1_1 cb) {
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
			struct fun_act1_1 _8 = cb;
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
			struct fun_act1_1 _18 = cb;
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
			struct fun_act1_1 _24 = cb;
			struct exception _25 = e2;
			struct err _26 = (struct err) {_25};
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
/* call<void, result<?t, exception>> void(a fun-act1<void, result<void, exception>>, p0 result<void, exception>) */
struct void_ call_0(struct ctx* ctx, struct fun_act1_1 a, struct result_1 p0) {
	struct fun_act1_1 _0 = a;
	struct ctx* _1 = ctx;
	struct result_1 _2 = p0;
	return call_w_ctx_104(_0, _1, _2);
}
/* call-w-ctx<void, result<void, exception>> (generated) (generated) */
struct void_ call_w_ctx_104(struct fun_act1_1 a, struct ctx* ctx, struct result_1 p0) {
	struct fun_act1_1 _0 = a;
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
	struct fun_act1_0 _9 = (struct fun_act1_0) {0, .as0 = _8};
	return then_void_1(_0, _1, _9);
}
/* then-void<?t> void(f fut<int32>, cb fun-act1<void, result<int32, exception>>) */
struct void_ then_void_1(struct ctx* ctx, struct fut_0* f, struct fun_act1_0 cb) {
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
			struct fun_act1_0 _8 = cb;
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
			struct fun_act1_0 _18 = cb;
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
			struct fun_act1_0 _24 = cb;
			struct exception _25 = e2;
			struct err _26 = (struct err) {_25};
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
/* call<void, result<?t, exception>> void(a fun-act1<void, result<int32, exception>>, p0 result<int32, exception>) */
struct void_ call_1(struct ctx* ctx, struct fun_act1_0 a, struct result_0 p0) {
	struct fun_act1_0 _0 = a;
	struct ctx* _1 = ctx;
	struct result_0 _2 = p0;
	return call_w_ctx_108(_0, _1, _2);
}
/* call-w-ctx<void, result<int32, exception>> (generated) (generated) */
struct void_ call_w_ctx_108(struct fun_act1_0 a, struct ctx* ctx, struct result_0 p0) {
	struct fun_act1_0 _0 = a;
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
			struct err e2 = _8.as1;
			
			struct exception ex3;
			struct err _13 = e2;
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
			struct fun_act1_0 _4 = _3->cb;
			struct result_0 _5 = value;
			struct void_ _6 = call_1(_1, _4, _5);
			drop_0(_6);
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
/* drop<void> void(_ void) */
struct void_ drop_0(struct void_ _p0) {
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
	struct fun_act0_0 _19 = (struct fun_act0_0) {1, .as1 = _18};
	add_task_0(_5, _6, _9, _19);
	return res1;
}
/* get-island island(island-id nat) */
struct island* get_island(struct ctx* ctx, uint64_t island_id) {
	struct ctx* _0 = ctx;
	struct ctx* _1 = ctx;
	struct global_ctx* _2 = get_global_ctx(_1);
	struct arr_3 _3 = _2->islands;
	uint64_t _4 = island_id;
	return at_0(_0, _3, _4);
}
/* at<island> island(a arr<island>, index nat) */
struct island* at_0(struct ctx* ctx, struct arr_3 a, uint64_t index) {
	struct ctx* _0 = ctx;
	uint64_t _1 = index;
	struct arr_3 _2 = a;
	uint64_t _3 = _2.size;
	uint8_t _4 = _op_less(_1, _3);
	assert_0(_0, _4);
	struct arr_3 _5 = a;
	uint64_t _6 = index;
	return noctx_at_0(_5, _6);
}
/* noctx-at<?t> island(a arr<island>, index nat) */
struct island* noctx_at_0(struct arr_3 a, uint64_t index) {
	uint64_t _0 = index;
	struct arr_3 _1 = a;
	uint64_t _2 = _1.size;
	uint8_t _3 = _op_less(_0, _2);
	hard_assert(_3);
	struct arr_3 _4 = a;
	struct island** _5 = _4.data;
	uint64_t _6 = index;
	struct island** _7 = _5 + _6;
	return *_7;
}
/* add-task void(a island, exclusion nat, action fun-act0<void>) */
struct void_ add_task_0(struct ctx* ctx, struct island* a, uint64_t exclusion, struct fun_act0_0 action) {
	struct ctx* _0 = ctx;
	struct island* _1 = a;
	uint64_t _2 = no_timestamp();
	uint64_t _3 = exclusion;
	struct fun_act0_0 _4 = action;
	return add_task_1(_0, _1, _2, _3, _4);
}
/* add-task void(a island, timestamp nat, exclusion nat, action fun-act0<void>) */
struct void_ add_task_1(struct ctx* ctx, struct island* a, uint64_t timestamp, uint64_t exclusion, struct fun_act0_0 action) {
	struct task_queue_node* node0;
	struct ctx* _0 = ctx;
	uint64_t _1 = timestamp;
	uint64_t _2 = exclusion;
	struct fun_act0_0 _3 = action;
	struct task _4 = (struct task) {_1, _2, _3};
	node0 = new_task_queue_node(_0, _4);
	
	struct lock* _5 = &a->tasks_lock;
	acquire_lock(_5);
	struct island* _6 = a;
	struct task_queue* _7 = tasks(_6);
	struct task_queue_node* _8 = node0;
	insert_task(_7, _8);
	struct lock* _9 = &a->tasks_lock;
	release_lock(_9);
	struct condition* _10 = &a->gctx->may_be_work_to_do;
	return broadcast(_10);
}
/* new-task-queue-node task-queue-node(task task) */
struct task_queue_node* new_task_queue_node(struct ctx* ctx, struct task task) {
	struct task_queue_node* temp0;
	struct ctx* _0 = ctx;
	uint64_t _1 = sizeof(struct task_queue_node);
	uint8_t* _2 = alloc(_0, _1);
	temp0 = (struct task_queue_node*) _2;
	
	struct task_queue_node* _3 = temp0;
	struct task _4 = task;
	struct none _5 = (struct none) {};
	struct opt_2 _6 = (struct opt_2) {0, .as0 = _5};
	struct task_queue_node _7 = (struct task_queue_node) {_4, _6};
	*_3 = _7;
	return temp0;
}
/* insert-task void(a task-queue, inserted task-queue-node) */
struct void_ insert_task(struct task_queue* a, struct task_queue_node* inserted) {
	uint64_t size_before0;
	struct task_queue* _0 = a;
	size_before0 = size_0(_0);
	
	struct task_queue* _1 = a;
	struct opt_2 _2 = _1->head;
	switch (_2.kind) {
		case 0: {
			struct task_queue* _3 = a;
			struct task_queue_node* _4 = inserted;
			struct some_2 _5 = (struct some_2) {_4};
			struct opt_2 _6 = (struct opt_2) {1, .as1 = _5};
			_3->head = _6;
			break;
		}
		case 1: {
			struct some_2 s1 = _2.as1;
			
			struct task_queue_node* head2;
			struct some_2 _7 = s1;
			head2 = _7.value;
			
			struct task_queue_node* _8 = head2;
			struct task _9 = _8->task;
			uint64_t _10 = _9.time;
			struct task_queue_node* _11 = inserted;
			struct task _12 = _11->task;
			uint64_t _13 = _12.time;
			uint8_t _14 = _op_less_equal(_10, _13);
			if (_14) {
				struct task_queue_node* _15 = head2;
				struct task_queue_node* _16 = inserted;
				insert_recur(_15, _16);
			} else {
				struct task_queue_node* _17 = inserted;
				struct task_queue_node* _18 = head2;
				struct some_2 _19 = (struct some_2) {_18};
				struct opt_2 _20 = (struct opt_2) {1, .as1 = _19};
				_17->next = _20;
				struct task_queue* _21 = a;
				struct task_queue_node* _22 = inserted;
				struct some_2 _23 = (struct some_2) {_22};
				struct opt_2 _24 = (struct opt_2) {1, .as1 = _23};
				_21->head = _24;
			}
			break;
		}
		default:
			(assert(0),(struct void_) {});
	}
	uint64_t size_after3;
	struct task_queue* _25 = a;
	size_after3 = size_0(_25);
	
	uint64_t _26 = size_before0;
	uint64_t _27 = 1u;
	uint64_t _28 = _26 + _27;
	uint64_t _29 = size_after3;
	uint8_t _30 = _op_equal_equal_0(_28, _29);
	return hard_assert(_30);
}
/* size nat(a task-queue) */
uint64_t size_0(struct task_queue* a) {
	struct task_queue* _0 = a;
	struct opt_2 _1 = _0->head;
	uint64_t _2 = 0u;
	return size_recur(_1, _2);
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
			
			struct some_2 _1 = s0;
			struct task_queue_node* _2 = _1.value;
			struct opt_2 _3 = _2->next;
			uint64_t _4 = acc;
			uint64_t _5 = 1u;
			uint64_t _6 = _4 + _5;
			node = _3;
			acc = _6;
			goto top;
		}
		default:
			return (assert(0),0);
	}
}
/* insert-recur void(prev task-queue-node, inserted task-queue-node) */
struct void_ insert_recur(struct task_queue_node* prev, struct task_queue_node* inserted) {
	top:;
	struct task_queue_node* _0 = prev;
	struct opt_2 _1 = _0->next;
	switch (_1.kind) {
		case 0: {
			struct task_queue_node* _2 = prev;
			struct task_queue_node* _3 = inserted;
			struct some_2 _4 = (struct some_2) {_3};
			struct opt_2 _5 = (struct opt_2) {1, .as1 = _4};
			return (_2->next = _5, (struct void_) {});
		}
		case 1: {
			struct some_2 s0 = _1.as1;
			
			struct task_queue_node* cur1;
			struct some_2 _6 = s0;
			cur1 = _6.value;
			
			struct task_queue_node* _7 = cur1;
			struct task _8 = _7->task;
			uint64_t _9 = _8.time;
			struct task_queue_node* _10 = inserted;
			struct task _11 = _10->task;
			uint64_t _12 = _11.time;
			uint8_t _13 = _op_less_equal(_9, _12);
			if (_13) {
				struct task_queue_node* _14 = cur1;
				struct task_queue_node* _15 = inserted;
				prev = _14;
				inserted = _15;
				goto top;
			} else {
				struct task_queue_node* _16 = inserted;
				struct task_queue_node* _17 = cur1;
				struct some_2 _18 = (struct some_2) {_17};
				struct opt_2 _19 = (struct opt_2) {1, .as1 = _18};
				_16->next = _19;
				struct task_queue_node* _20 = prev;
				struct task_queue_node* _21 = inserted;
				struct some_2 _22 = (struct some_2) {_21};
				struct opt_2 _23 = (struct opt_2) {1, .as1 = _22};
				return (_20->next = _23, (struct void_) {});
			}
		}
		default:
			return (assert(0),(struct void_) {});
	}
}
/* tasks task-queue(a island) */
struct task_queue* tasks(struct island* a) {
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
/* no-timestamp nat() */
uint64_t no_timestamp(void) {
	return 0u;
}
/* catch<void> void(try fun-act0<void>, catcher fun-act1<void, exception>) */
struct void_ catch(struct ctx* ctx, struct fun_act0_0 try, struct fun_act1_3 catcher) {
	struct ctx* _0 = ctx;
	struct ctx* _1 = ctx;
	struct exception_ctx* _2 = get_exception_ctx(_1);
	struct fun_act0_0 _3 = try;
	struct fun_act1_3 _4 = catcher;
	return catch_with_exception_ctx(_0, _2, _3, _4);
}
/* catch-with-exception-ctx<?t> void(ec exception-ctx, try fun-act0<void>, catcher fun-act1<void, exception>) */
struct void_ catch_with_exception_ctx(struct ctx* ctx, struct exception_ctx* ec, struct fun_act0_0 try, struct fun_act1_3 catcher) {
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
	uint8_t _11 = _op_equal_equal_2(_9, _10);
	if (_11) {
		struct void_ res4;
		struct ctx* _12 = ctx;
		struct fun_act0_0 _13 = try;
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
		uint8_t _22 = _op_equal_equal_2(_19, _21);
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
		struct fun_act1_3 _29 = catcher;
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
/* call<?t> void(a fun-act0<void>) */
struct void_ call_2(struct ctx* ctx, struct fun_act0_0 a) {
	struct fun_act0_0 _0 = a;
	struct ctx* _1 = ctx;
	return call_w_ctx_135(_0, _1);
}
/* call-w-ctx<void> (generated) (generated) */
struct void_ call_w_ctx_135(struct fun_act0_0 a, struct ctx* ctx) {
	struct fun_act0_0 _0 = a;
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
		case 4: {
			struct with_log_handler__lambda0* closure4 = _0.as4;
			
			struct ctx* _9 = ctx;
			struct with_log_handler__lambda0* _10 = closure4;
			return with_log_handler__lambda0(_9, _10);
		}
		case 5: {
			struct with_log_handler__lambda1* closure5 = _0.as5;
			
			struct ctx* _11 = ctx;
			struct with_log_handler__lambda1* _12 = closure5;
			return with_log_handler__lambda1(_11, _12);
		}
		case 6: {
			struct void_ closure6 = _0.as6;
			
			struct ctx* _13 = ctx;
			struct void_ _14 = closure6;
			return main_0__lambda1(_13, _14);
		}
		case 7: {
			struct void_ closure7 = _0.as7;
			
			struct ctx* _15 = ctx;
			struct void_ _16 = closure7;
			return main_0__lambda3(_15, _16);
		}
		default:
			return (assert(0),(struct void_) {});
	}
}
/* call<?t, exception> void(a fun-act1<void, exception>, p0 exception) */
struct void_ call_3(struct ctx* ctx, struct fun_act1_3 a, struct exception p0) {
	struct fun_act1_3 _0 = a;
	struct ctx* _1 = ctx;
	struct exception _2 = p0;
	return call_w_ctx_137(_0, _1, _2);
}
/* call-w-ctx<void, exception> (generated) (generated) */
struct void_ call_w_ctx_137(struct fun_act1_3 a, struct ctx* ctx, struct exception p0) {
	struct fun_act1_3 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct call_ref_0__lambda0__lambda1* closure0 = _0.as0;
			
			struct ctx* _1 = ctx;
			struct call_ref_0__lambda0__lambda1* _2 = closure0;
			struct exception _3 = p0;
			return call_ref_0__lambda0__lambda1(_1, _2, _3);
		}
		case 1: {
			struct call_ref_1__lambda0__lambda1* closure1 = _0.as1;
			
			struct ctx* _4 = ctx;
			struct call_ref_1__lambda0__lambda1* _5 = closure1;
			struct exception _6 = p0;
			return call_ref_1__lambda0__lambda1(_4, _5, _6);
		}
		case 2: {
			struct finally__lambda0* closure2 = _0.as2;
			
			struct ctx* _7 = ctx;
			struct finally__lambda0* _8 = closure2;
			struct exception _9 = p0;
			return finally__lambda0(_7, _8, _9);
		}
		default:
			return (assert(0),(struct void_) {});
	}
}
/* call<fut<?r>, ?p0> fut<int32>(a fun-act1<fut<int32>, void>, p0 void) */
struct fut_0* call_4(struct ctx* ctx, struct fun_act1_2 a, struct void_ p0) {
	struct fun_act1_2 _0 = a;
	struct ctx* _1 = ctx;
	struct void_ _2 = p0;
	return call_w_ctx_139(_0, _1, _2);
}
/* call-w-ctx<gc-ptr(fut<int32>), void> (generated) (generated) */
struct fut_0* call_w_ctx_139(struct fun_act1_2 a, struct ctx* ctx, struct void_ p0) {
	struct fun_act1_2 _0 = a;
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
	struct fun_act1_2 _4 = _3.fun;
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
	struct err _3 = (struct err) {_2};
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
	struct fun_act0_0 _13 = (struct fun_act0_0) {0, .as0 = _12};
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
	struct fun_act1_3 _22 = (struct fun_act1_3) {0, .as0 = _21};
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
			struct err e1 = _0.as1;
			
			struct ctx* _10 = ctx;
			struct then__lambda0* _11 = _closure;
			struct fut_0* _12 = _11->res;
			struct err _13 = e1;
			struct exception _14 = _13.value;
			return reject(_10, _12, _14);
		}
		default:
			return (assert(0),(struct void_) {});
	}
}
/* call-ref<?out> fut<int32>(f fun-ref0<int32>) */
struct fut_0* call_ref_1(struct ctx* ctx, struct fun_ref0 f) {
	struct fut_0* res0;
	struct ctx* _0 = ctx;
	res0 = new_unresolved_fut(_0);
	
	struct ctx* _1 = ctx;
	struct ctx* _2 = ctx;
	struct fun_ref0 _3 = f;
	struct island_and_exclusion _4 = _3.island_and_exclusion;
	uint64_t _5 = _4.island;
	struct island* _6 = get_island(_2, _5);
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
	struct fut_0* _15 = res0;
	struct call_ref_1__lambda0 _16 = (struct call_ref_1__lambda0) {_14, _15};
	*_13 = _16;
	struct call_ref_1__lambda0* _17 = temp0;
	struct fun_act0_0 _18 = (struct fun_act0_0) {3, .as3 = _17};
	add_task_0(_1, _6, _9, _18);
	return res0;
}
/* call<fut<?r>> fut<int32>(a fun-act0<fut<int32>>) */
struct fut_0* call_5(struct ctx* ctx, struct fun_act0_1 a) {
	struct fun_act0_1 _0 = a;
	struct ctx* _1 = ctx;
	return call_w_ctx_147(_0, _1);
}
/* call-w-ctx<gc-ptr(fut<int32>)> (generated) (generated) */
struct fut_0* call_w_ctx_147(struct fun_act0_1 a, struct ctx* ctx) {
	struct fun_act0_1 _0 = a;
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
	struct fun_act0_1 _4 = _3.fun;
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
	struct fun_act0_0 _11 = (struct fun_act0_0) {2, .as2 = _10};
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
	struct fun_act1_3 _20 = (struct fun_act1_3) {1, .as1 = _19};
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
struct arr_4 tail(struct ctx* ctx, struct arr_4 a) {
	struct ctx* _0 = ctx;
	struct arr_4 _1 = a;
	uint8_t _2 = empty__q_1(_1);
	forbid_0(_0, _2);
	struct ctx* _3 = ctx;
	struct arr_4 _4 = a;
	uint64_t _5 = 1u;
	return slice_starting_at(_3, _4, _5);
}
/* forbid void(condition bool) */
struct void_ forbid_0(struct ctx* ctx, uint8_t condition) {
	struct ctx* _0 = ctx;
	uint8_t _1 = condition;
	struct arr_0 _2 = (struct arr_0) {13, constantarr_0_11};
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
/* empty?<?t> bool(a arr<ptr<char>>) */
uint8_t empty__q_1(struct arr_4 a) {
	struct arr_4 _0 = a;
	uint64_t _1 = _0.size;
	uint64_t _2 = 0u;
	return _op_equal_equal_0(_1, _2);
}
/* slice-starting-at<?t> arr<ptr<char>>(a arr<ptr<char>>, begin nat) */
struct arr_4 slice_starting_at(struct ctx* ctx, struct arr_4 a, uint64_t begin) {
	struct ctx* _0 = ctx;
	uint64_t _1 = begin;
	struct arr_4 _2 = a;
	uint64_t _3 = _2.size;
	uint8_t _4 = _op_less_equal(_1, _3);
	assert_0(_0, _4);
	struct ctx* _5 = ctx;
	struct arr_4 _6 = a;
	uint64_t _7 = begin;
	struct ctx* _8 = ctx;
	struct arr_4 _9 = a;
	uint64_t _10 = _9.size;
	uint64_t _11 = begin;
	uint64_t _12 = _op_minus_2(_8, _10, _11);
	return slice(_5, _6, _7, _12);
}
/* slice<?t> arr<ptr<char>>(a arr<ptr<char>>, begin nat, size nat) */
struct arr_4 slice(struct ctx* ctx, struct arr_4 a, uint64_t begin, uint64_t size) {
	struct ctx* _0 = ctx;
	struct ctx* _1 = ctx;
	uint64_t _2 = begin;
	uint64_t _3 = size;
	uint64_t _4 = _op_plus_1(_1, _2, _3);
	struct arr_4 _5 = a;
	uint64_t _6 = _5.size;
	uint8_t _7 = _op_less_equal(_4, _6);
	assert_0(_0, _7);
	uint64_t _8 = size;
	struct arr_4 _9 = a;
	char** _10 = _9.data;
	uint64_t _11 = begin;
	char** _12 = _10 + _11;
	return (struct arr_4) {_8, _12};
}
/* - nat(a nat, b nat) */
uint64_t _op_minus_2(struct ctx* ctx, uint64_t a, uint64_t b) {
	struct ctx* _0 = ctx;
	uint64_t _1 = a;
	uint64_t _2 = b;
	uint8_t _3 = _op_greater_equal(_1, _2);
	assert_0(_0, _3);
	uint64_t _4 = a;
	uint64_t _5 = b;
	return _4 - _5;
}
/* map<arr<char>, ptr<char>> arr<arr<char>>(a arr<ptr<char>>, mapper fun-act1<arr<char>, ptr<char>>) */
struct arr_1 map(struct ctx* ctx, struct arr_4 a, struct fun_act1_4 mapper) {
	struct ctx* _0 = ctx;
	struct arr_4 _1 = a;
	uint64_t _2 = _1.size;
	struct map__lambda0* temp0;
	struct ctx* _3 = ctx;
	uint64_t _4 = sizeof(struct map__lambda0);
	uint8_t* _5 = alloc(_3, _4);
	temp0 = (struct map__lambda0*) _5;
	
	struct map__lambda0* _6 = temp0;
	struct fun_act1_4 _7 = mapper;
	struct arr_4 _8 = a;
	struct map__lambda0 _9 = (struct map__lambda0) {_7, _8};
	*_6 = _9;
	struct map__lambda0* _10 = temp0;
	struct fun_act1_5 _11 = (struct fun_act1_5) {0, .as0 = _10};
	return make_arr(_0, _2, _11);
}
/* make-arr<?out> arr<arr<char>>(size nat, f fun-act1<arr<char>, nat>) */
struct arr_1 make_arr(struct ctx* ctx, uint64_t size, struct fun_act1_5 f) {
	struct arr_0* data0;
	struct ctx* _0 = ctx;
	uint64_t _1 = size;
	data0 = uninitialized_data_1(_0, _1);
	
	struct ctx* _2 = ctx;
	struct arr_0* _3 = data0;
	uint64_t _4 = size;
	struct fun_act1_5 _5 = f;
	fill_ptr_range(_2, _3, _4, _5);
	uint64_t _6 = size;
	struct arr_0* _7 = data0;
	return (struct arr_1) {_6, _7};
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
/* fill-ptr-range<?t> void(begin ptr<arr<char>>, size nat, f fun-act1<arr<char>, nat>) */
struct void_ fill_ptr_range(struct ctx* ctx, struct arr_0* begin, uint64_t size, struct fun_act1_5 f) {
	struct ctx* _0 = ctx;
	struct arr_0* _1 = begin;
	uint64_t _2 = 0u;
	uint64_t _3 = size;
	struct fun_act1_5 _4 = f;
	return fill_ptr_range_recur(_0, _1, _2, _3, _4);
}
/* fill-ptr-range-recur<?t> void(begin ptr<arr<char>>, i nat, size nat, f fun-act1<arr<char>, nat>) */
struct void_ fill_ptr_range_recur(struct ctx* ctx, struct arr_0* begin, uint64_t i, uint64_t size, struct fun_act1_5 f) {
	top:;
	uint64_t _0 = i;
	uint64_t _1 = size;
	uint8_t _2 = _op_bang_equal_1(_0, _1);
	if (_2) {
		struct arr_0* _3 = begin;
		uint64_t _4 = i;
		struct arr_0* _5 = _3 + _4;
		struct ctx* _6 = ctx;
		struct fun_act1_5 _7 = f;
		uint64_t _8 = i;
		struct arr_0 _9 = call_6(_6, _7, _8);
		*_5 = _9;
		struct arr_0* _10 = begin;
		uint64_t _11 = i;
		uint64_t _12 = wrap_incr(_11);
		uint64_t _13 = size;
		struct fun_act1_5 _14 = f;
		begin = _10;
		i = _12;
		size = _13;
		f = _14;
		goto top;
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
/* call<?t, nat> arr<char>(a fun-act1<arr<char>, nat>, p0 nat) */
struct arr_0 call_6(struct ctx* ctx, struct fun_act1_5 a, uint64_t p0) {
	struct fun_act1_5 _0 = a;
	struct ctx* _1 = ctx;
	uint64_t _2 = p0;
	return call_w_ctx_169(_0, _1, _2);
}
/* call-w-ctx<arr<char>, nat-64> (generated) (generated) */
struct arr_0 call_w_ctx_169(struct fun_act1_5 a, struct ctx* ctx, uint64_t p0) {
	struct fun_act1_5 _0 = a;
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
/* call<?out, ?in> arr<char>(a fun-act1<arr<char>, ptr<char>>, p0 ptr<char>) */
struct arr_0 call_7(struct ctx* ctx, struct fun_act1_4 a, char* p0) {
	struct fun_act1_4 _0 = a;
	struct ctx* _1 = ctx;
	char* _2 = p0;
	return call_w_ctx_171(_0, _1, _2);
}
/* call-w-ctx<arr<char>, raw-ptr(char)> (generated) (generated) */
struct arr_0 call_w_ctx_171(struct fun_act1_4 a, struct ctx* ctx, char* p0) {
	struct fun_act1_4 _0 = a;
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
char* at_1(struct ctx* ctx, struct arr_4 a, uint64_t index) {
	struct ctx* _0 = ctx;
	uint64_t _1 = index;
	struct arr_4 _2 = a;
	uint64_t _3 = _2.size;
	uint8_t _4 = _op_less(_1, _3);
	assert_0(_0, _4);
	struct arr_4 _5 = a;
	uint64_t _6 = index;
	return noctx_at_1(_5, _6);
}
/* noctx-at<?t> ptr<char>(a arr<ptr<char>>, index nat) */
char* noctx_at_1(struct arr_4 a, uint64_t index) {
	uint64_t _0 = index;
	struct arr_4 _1 = a;
	uint64_t _2 = _1.size;
	uint8_t _3 = _op_less(_0, _2);
	hard_assert(_3);
	struct arr_4 _4 = a;
	char** _5 = _4.data;
	uint64_t _6 = index;
	char** _7 = _5 + _6;
	return *_7;
}
/* map<arr<char>, ptr<char>>.lambda0 arr<char>(i nat) */
struct arr_0 map__lambda0(struct ctx* ctx, struct map__lambda0* _closure, uint64_t i) {
	struct ctx* _0 = ctx;
	struct map__lambda0* _1 = _closure;
	struct fun_act1_4 _2 = _1->mapper;
	struct ctx* _3 = ctx;
	struct map__lambda0* _4 = _closure;
	struct arr_4 _5 = _4->a;
	uint64_t _6 = i;
	char* _7 = at_1(_3, _5, _6);
	return call_7(_0, _2, _7);
}
/* to-str arr<char>(a ptr<char>) */
struct arr_0 to_str_1(char* a) {
	char* _0 = a;
	char* _1 = a;
	char* _2 = find_cstr_end(_1);
	return arr_from_begin_end(_0, _2);
}
/* arr-from-begin-end<char> arr<char>(begin ptr<char>, end ptr<char>) */
struct arr_0 arr_from_begin_end(char* begin, char* end) {
	char* _0 = end;
	char* _1 = begin;
	uint64_t _2 = _op_minus_3(_0, _1);
	char* _3 = begin;
	return (struct arr_0) {_2, _3};
}
/* -<?t> nat(a ptr<char>, b ptr<char>) */
uint64_t _op_minus_3(char* a, char* b) {
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
	uint8_t _3 = _op_equal_equal_3(_1, _2);
	if (_3) {
		return a;
	} else {
		char* _4 = a;
		char _5 = *_4;
		char _6 = 0u;
		uint8_t _7 = _op_equal_equal_3(_5, _6);
		if (_7) {
			return todo_2();
		} else {
			char* _8 = a;
			char* _9 = incr_2(_8);
			char _10 = c;
			a = _9;
			c = _10;
			goto top;
		}
	}
}
/* ==<char> bool(a char, b char) */
uint8_t _op_equal_equal_3(char a, char b) {
	char _0 = a;
	char _1 = b;
	struct comparison _2 = compare_181(_0, _1);
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
struct comparison compare_181(char a, char b) {
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
char* todo_2(void) {
	return (assert(0),NULL);
}
/* incr<char> ptr<char>(p ptr<char>) */
char* incr_2(char* p) {
	char* _0 = p;
	uint64_t _1 = 1u;
	return _0 + _1;
}
/* add-first-task.lambda0.lambda0 arr<char>(it ptr<char>) */
struct arr_0 add_first_task__lambda0__lambda0(struct ctx* ctx, struct void_ _closure, char* it) {
	char* _0 = it;
	return to_str_1(_0);
}
/* add-first-task.lambda0 fut<int32>() */
struct fut_0* add_first_task__lambda0(struct ctx* ctx, struct add_first_task__lambda0* _closure) {
	struct arr_4 args0;
	struct ctx* _0 = ctx;
	struct add_first_task__lambda0* _1 = _closure;
	struct arr_4 _2 = _1->all_args;
	args0 = tail(_0, _2);
	
	struct add_first_task__lambda0* _3 = _closure;
	fun_ptr2 _4 = _3->main_ptr;
	struct ctx* _5 = ctx;
	struct ctx* _6 = ctx;
	struct arr_4 _7 = args0;
	struct void_ _8 = (struct void_) {};
	struct fun_act1_4 _9 = (struct fun_act1_4) {0, .as0 = _8};
	struct arr_1 _10 = map(_6, _7, _9);
	return _4(_5, _10);
}
/* do-main.lambda0 fut<int32>(all-args arr<ptr<char>>, main-ptr fun-ptr2<fut<int32>, ctx, arr<arr<char>>>) */
struct fut_0* do_main__lambda0(struct ctx* ctx, struct void_ _closure, struct arr_4 all_args, fun_ptr2 main_ptr) {
	struct ctx* _0 = ctx;
	struct arr_4 _1 = all_args;
	fun_ptr2 _2 = main_ptr;
	return add_first_task(_0, _1, _2);
}
/* call-w-ctx<gc-ptr(fut<int32>), arr<ptr<char>>, some fun ptr type> (generated) (generated) */
struct fut_0* call_w_ctx_187(struct fun2 a, struct ctx* ctx, struct arr_4 p0, fun_ptr2 p1) {
	struct fun2 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			struct ctx* _1 = ctx;
			struct void_ _2 = closure0;
			struct arr_4 _3 = p0;
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
		
		uint64_t* _11 = thread_ptr1;
		struct cell_0* _12 = as_cell(_11);
		struct thread_args* _13 = thread_arg_ptr0;
		uint8_t* _14 = (uint8_t*) _13;
		create_one_thread(_12, _14, thread_fun);
		uint64_t _15 = i;
		uint64_t _16 = noctx_incr(_15);
		uint64_t _17 = n_threads;
		uint64_t* _18 = threads;
		struct thread_args* _19 = thread_args_begin;
		struct global_ctx* _20 = gctx;
		i = _16;
		n_threads = _17;
		threads = _18;
		thread_args_begin = _19;
		gctx = _20;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* create-one-thread void(tid cell<nat>, thread-arg ptr<nat8>, thread-fun fun-ptr1<ptr<nat8>, ptr<nat8>>) */
struct void_ create_one_thread(struct cell_0* tid, uint8_t* thread_arg, fun_ptr1 thread_fun) {
	int32_t err0;
	struct cell_0* _0 = tid;
	uint8_t* _1 = NULL;
	fun_ptr1 _2 = thread_fun;
	uint8_t* _3 = thread_arg;
	err0 = pthread_create(_0, _1, _2, _3);
	
	int32_t _4 = err0;
	int32_t _5 = 0;
	uint8_t _6 = _op_bang_equal_2(_4, _5);
	if (_6) {
		int32_t _7 = err0;
		int32_t _8 = eagain();
		uint8_t _9 = _op_equal_equal_2(_7, _8);
		if (_9) {
			return todo_0();
		} else {
			return todo_0();
		}
	} else {
		return (struct void_) {};
	}
}
/* !=<int32> bool(a int32, b int32) */
uint8_t _op_bang_equal_2(int32_t a, int32_t b) {
	int32_t _0 = a;
	int32_t _1 = b;
	uint8_t _2 = _op_equal_equal_2(_0, _1);
	return !_2;
}
/* eagain int32() */
int32_t eagain(void) {
	return 11;
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
	uint8_t _1 = _0->shut_down__q;
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
		struct arr_3 _9 = _8->islands;
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
		struct choose_task_result _17 = choose_task(_16);
		switch (_17.kind) {
			case 0: {
				struct chosen_task t1 = _17.as0;
				
				struct global_ctx* _18 = gctx;
				struct thread_local_stuff* _19 = tls;
				struct chosen_task _20 = t1;
				do_task(_18, _19, _20);
				break;
			}
			case 1: {
				struct no_chosen_task n2 = _17.as1;
				
				struct no_chosen_task _21 = n2;
				uint8_t _22 = _21.no_tasks_and_last_thread_out__q;
				if (_22) {
					struct global_ctx* _23 = gctx;
					uint8_t _24 = _23->shut_down__q;
					hard_forbid(_24);
					struct global_ctx* _25 = gctx;
					uint8_t _26 = 1;
					_25->shut_down__q = _26;
					struct condition* _27 = &gctx->may_be_work_to_do;
					broadcast(_27);
				} else {
					struct condition* _28 = &gctx->may_be_work_to_do;
					struct no_chosen_task _29 = n2;
					struct opt_5 _30 = _29.first_task_time;
					uint64_t _31 = last_checked0;
					wait_on(_28, _30, _31);
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
struct void_ assert_islands_are_shut_down(uint64_t i, struct arr_3 islands) {
	top:;
	uint64_t _0 = i;
	struct arr_3 _1 = islands;
	uint64_t _2 = _1.size;
	uint8_t _3 = _op_bang_equal_1(_0, _2);
	if (_3) {
		struct island* island0;
		struct arr_3 _4 = islands;
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
		struct task_queue* _14 = tasks(_13);
		uint8_t _15 = empty__q_2(_14);
		hard_assert(_15);
		struct lock* _16 = &island0->tasks_lock;
		release_lock(_16);
		uint64_t _17 = i;
		uint64_t _18 = noctx_incr(_17);
		struct arr_3 _19 = islands;
		i = _18;
		islands = _19;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* empty? bool(a task-queue) */
uint8_t empty__q_2(struct task_queue* a) {
	struct task_queue* _0 = a;
	struct opt_2 _1 = _0->head;
	uint8_t _2 = has__q(_1);
	return !_2;
}
/* has?<task-queue-node> bool(a opt<task-queue-node>) */
uint8_t has__q(struct opt_2 a) {
	struct opt_2 _0 = a;
	uint8_t _1 = empty__q_3(_0);
	return !_1;
}
/* empty?<?t> bool(a opt<task-queue-node>) */
uint8_t empty__q_3(struct opt_2 a) {
	struct opt_2 _0 = a;
	switch (_0.kind) {
		case 0: {
			return 1;
		}
		case 1: {
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
/* choose-task choose-task-result(gctx global-ctx) */
struct choose_task_result choose_task(struct global_ctx* gctx) {
	struct lock* _0 = &gctx->lk;
	acquire_lock(_0);
	uint64_t cur_time0;
	cur_time0 = get_monotime_nsec();
	
	struct choose_task_result res4;
	struct global_ctx* _1 = gctx;
	struct arr_3 _2 = _1->islands;
	uint64_t _3 = 0u;
	uint64_t _4 = cur_time0;
	uint8_t _5 = 0;
	struct none _6 = (struct none) {};
	struct opt_5 _7 = (struct opt_5) {0, .as0 = _6};
	struct choose_task_result _8 = choose_task_recur(_2, _3, _4, _5, _7);
	switch (_8.kind) {
		case 0: {
			struct chosen_task c1 = _8.as0;
			
			struct chosen_task _9 = c1;
			res4 = (struct choose_task_result) {0, .as0 = _9};
			break;
		}
		case 1: {
			struct no_chosen_task n2 = _8.as1;
			
			struct global_ctx* _10 = gctx;
			struct global_ctx* _11 = gctx;
			uint64_t _12 = _11->n_live_threads;
			uint64_t _13 = noctx_decr(_12);
			_10->n_live_threads = _13;
			uint8_t no_task_and_last_thread_out__q3;
			struct no_chosen_task _14 = n2;
			uint8_t _15 = _14.no_tasks_and_last_thread_out__q;
			if (_15) {
				struct global_ctx* _16 = gctx;
				uint64_t _17 = _16->n_live_threads;
				uint64_t _18 = 0u;
				no_task_and_last_thread_out__q3 = _op_equal_equal_0(_17, _18);
			} else {
				no_task_and_last_thread_out__q3 = 0;
			}
			
			uint8_t _19 = no_task_and_last_thread_out__q3;
			struct no_chosen_task _20 = n2;
			struct opt_5 _21 = _20.first_task_time;
			struct no_chosen_task _22 = (struct no_chosen_task) {_19, _21};
			res4 = (struct choose_task_result) {1, .as1 = _22};
			break;
		}
		default:
			(assert(0),(struct choose_task_result) {0});
	}
	
	struct lock* _23 = &gctx->lk;
	release_lock(_23);
	return res4;
}
/* get-monotime-nsec nat() */
uint64_t get_monotime_nsec(void) {
	struct cell_1 time_cell0;
	int64_t _0 = 0;
	int64_t _1 = 0;
	struct timespec _2 = (struct timespec) {_0, _1};
	time_cell0 = (struct cell_1) {_2};
	
	int32_t err1;
	int32_t _3 = clock_monotonic();
	struct cell_1* _4 = &time_cell0;
	err1 = clock_gettime(_3, _4);
	
	int32_t _5 = err1;
	int32_t _6 = 0;
	uint8_t _7 = _op_equal_equal_2(_5, _6);
	if (_7) {
		struct timespec time2;
		struct cell_1* _8 = &time_cell0;
		time2 = get_0(_8);
		
		struct timespec _9 = time2;
		int64_t _10 = _9.tv_sec;
		int64_t _11 = 1000000000;
		int64_t _12 = _10 * _11;
		struct timespec _13 = time2;
		int64_t _14 = _13.tv_nsec;
		int64_t _15 = _12 + _14;
		return (uint64_t) _15;
	} else {
		return todo_3();
	}
}
/* clock-monotonic int32() */
int32_t clock_monotonic(void) {
	return 1;
}
/* get<timespec> timespec(c cell<timespec>) */
struct timespec get_0(struct cell_1* c) {
	struct cell_1* _0 = c;
	return _0->value;
}
/* todo<nat> nat() */
uint64_t todo_3(void) {
	return (assert(0),0);
}
/* choose-task-recur choose-task-result(islands arr<island>, i nat, cur-time nat, any-tasks? bool, first-task-time opt<nat>) */
struct choose_task_result choose_task_recur(struct arr_3 islands, uint64_t i, uint64_t cur_time, uint8_t any_tasks__q, struct opt_5 first_task_time) {
	top:;
	uint64_t _0 = i;
	struct arr_3 _1 = islands;
	uint64_t _2 = _1.size;
	uint8_t _3 = _op_equal_equal_0(_0, _2);
	if (_3) {
		uint8_t _4 = any_tasks__q;
		uint8_t _5 = !_4;
		struct opt_5 _6 = first_task_time;
		struct no_chosen_task _7 = (struct no_chosen_task) {_5, _6};
		return (struct choose_task_result) {1, .as1 = _7};
	} else {
		struct island* island0;
		struct arr_3 _8 = islands;
		uint64_t _9 = i;
		island0 = noctx_at_0(_8, _9);
		
		struct island* _10 = island0;
		uint64_t _11 = cur_time;
		struct choose_task_in_island_result _12 = choose_task_in_island(_10, _11);
		switch (_12.kind) {
			case 0: {
				struct task t1 = _12.as0;
				
				struct island* _13 = island0;
				struct task _14 = t1;
				struct task_or_gc _15 = (struct task_or_gc) {0, .as0 = _14};
				struct chosen_task _16 = (struct chosen_task) {_13, _15};
				return (struct choose_task_result) {0, .as0 = _16};
			}
			case 1: {
				struct do_a_gc g2 = _12.as1;
				
				struct island* _17 = island0;
				struct do_a_gc _18 = g2;
				struct task_or_gc _19 = (struct task_or_gc) {1, .as1 = _18};
				struct chosen_task _20 = (struct chosen_task) {_17, _19};
				return (struct choose_task_result) {0, .as0 = _20};
			}
			case 2: {
				struct no_task n3 = _12.as2;
				
				uint8_t new_any_tasks__q4;
				uint8_t _21 = any_tasks__q;
				if (_21) {
					new_any_tasks__q4 = 1;
				} else {
					struct no_task _22 = n3;
					new_any_tasks__q4 = _22.any_tasks__q;
				}
				
				struct opt_5 new_first_task_time5;
				struct opt_5 _23 = first_task_time;
				struct no_task _24 = n3;
				struct opt_5 _25 = _24.first_task_time;
				new_first_task_time5 = min_time(_23, _25);
				
				struct arr_3 _26 = islands;
				uint64_t _27 = i;
				uint64_t _28 = noctx_incr(_27);
				uint64_t _29 = cur_time;
				uint8_t _30 = new_any_tasks__q4;
				struct opt_5 _31 = new_first_task_time5;
				islands = _26;
				i = _28;
				cur_time = _29;
				any_tasks__q = _30;
				first_task_time = _31;
				goto top;
			}
			default:
				return (assert(0),(struct choose_task_result) {0});
		}
	}
}
/* choose-task-in-island choose-task-in-island-result(island island, cur-time nat) */
struct choose_task_in_island_result choose_task_in_island(struct island* island, uint64_t cur_time) {
	struct lock* _0 = &island->tasks_lock;
	acquire_lock(_0);
	struct choose_task_in_island_result res2;
	struct gc* _1 = &island->gc;
	uint8_t _2 = _1->needs_gc__q;
	if (_2) {
		struct island* _3 = island;
		uint64_t _4 = _3->n_threads_running;
		uint64_t _5 = 0u;
		uint8_t _6 = _op_equal_equal_0(_4, _5);
		if (_6) {
			struct do_a_gc _7 = (struct do_a_gc) {};
			res2 = (struct choose_task_in_island_result) {1, .as1 = _7};
		} else {
			uint8_t _8 = 1;
			struct none _9 = (struct none) {};
			struct opt_5 _10 = (struct opt_5) {0, .as0 = _9};
			struct no_task _11 = (struct no_task) {_8, _10};
			res2 = (struct choose_task_in_island_result) {2, .as2 = _11};
		}
	} else {
		struct island* _12 = island;
		struct task_queue* _13 = tasks(_12);
		uint64_t _14 = cur_time;
		struct pop_task_result _15 = pop_task(_13, _14);
		switch (_15.kind) {
			case 0: {
				struct task t0 = _15.as0;
				
				struct task _16 = t0;
				res2 = (struct choose_task_in_island_result) {0, .as0 = _16};
				break;
			}
			case 1: {
				struct no_task n1 = _15.as1;
				
				struct no_task _17 = n1;
				res2 = (struct choose_task_in_island_result) {2, .as2 = _17};
				break;
			}
			default:
				(assert(0),(struct choose_task_in_island_result) {0});
		}
	}
	
	struct choose_task_in_island_result _18 = res2;
	uint8_t _19 = is_no_task__q(_18);
	uint8_t _20 = !_19;
	if (_20) {
		struct island* _21 = island;
		struct island* _22 = island;
		uint64_t _23 = _22->n_threads_running;
		uint64_t _24 = noctx_incr(_23);
		_21->n_threads_running = _24;
	} else {
		(struct void_) {};
	}
	struct lock* _25 = &island->tasks_lock;
	release_lock(_25);
	return res2;
}
/* pop-task pop-task-result(a task-queue, cur-time nat) */
struct pop_task_result pop_task(struct task_queue* a, uint64_t cur_time) {
	struct mut_list* exclusions0;
	exclusions0 = &a->currently_running_exclusions;
	
	struct pop_task_result res4;
	struct task_queue* _0 = a;
	struct opt_2 _1 = _0->head;
	switch (_1.kind) {
		case 0: {
			uint8_t _2 = 0;
			struct none _3 = (struct none) {};
			struct opt_5 _4 = (struct opt_5) {0, .as0 = _3};
			struct no_task _5 = (struct no_task) {_2, _4};
			res4 = (struct pop_task_result) {1, .as1 = _5};
			break;
		}
		case 1: {
			struct some_2 s1 = _1.as1;
			
			struct task_queue_node* head2;
			struct some_2 _6 = s1;
			head2 = _6.value;
			
			struct task task3;
			struct task_queue_node* _7 = head2;
			task3 = _7->task;
			
			struct task _8 = task3;
			uint64_t _9 = _8.time;
			uint64_t _10 = cur_time;
			uint8_t _11 = _op_less_equal(_9, _10);
			if (_11) {
				struct mut_list* _12 = exclusions0;
				struct task _13 = task3;
				uint64_t _14 = _13.exclusion;
				uint8_t _15 = contains__q_0(_12, _14);
				if (_15) {
					struct task_queue_node* _16 = head2;
					struct mut_list* _17 = exclusions0;
					uint64_t _18 = cur_time;
					struct task _19 = task3;
					uint64_t _20 = _19.time;
					struct opt_5 _21 = to_opt_time(_20);
					res4 = pop_recur(_16, _17, _18, _21);
				} else {
					struct task_queue* _22 = a;
					struct task_queue_node* _23 = head2;
					struct opt_2 _24 = _23->next;
					_22->head = _24;
					struct task_queue_node* _25 = head2;
					struct task _26 = _25->task;
					res4 = (struct pop_task_result) {0, .as0 = _26};
				}
			} else {
				uint8_t _27 = 1;
				struct task _28 = task3;
				uint64_t _29 = _28.time;
				struct some_5 _30 = (struct some_5) {_29};
				struct opt_5 _31 = (struct opt_5) {1, .as1 = _30};
				struct no_task _32 = (struct no_task) {_27, _31};
				res4 = (struct pop_task_result) {1, .as1 = _32};
			}
			break;
		}
		default:
			(assert(0),(struct pop_task_result) {0});
	}
	
	struct pop_task_result _33 = res4;
	switch (_33.kind) {
		case 0: {
			struct task t5 = _33.as0;
			
			struct mut_list* _34 = exclusions0;
			struct task _35 = t5;
			uint64_t _36 = _35.exclusion;
			push_capacity_must_be_sufficient(_34, _36);
			break;
		}
		case 1: {
			(struct void_) {};
			break;
		}
		default:
			(assert(0),(struct void_) {});
	}
	return res4;
}
/* contains?<nat> bool(a mut-list<nat>, value nat) */
uint8_t contains__q_0(struct mut_list* a, uint64_t value) {
	struct mut_list* _0 = a;
	struct arr_2 _1 = temp_as_arr_0(_0);
	uint64_t _2 = value;
	return contains__q_1(_1, _2);
}
/* contains?<?t> bool(a arr<nat>, value nat) */
uint8_t contains__q_1(struct arr_2 a, uint64_t value) {
	struct arr_2 _0 = a;
	uint64_t _1 = value;
	uint64_t _2 = 0u;
	return contains_recur__q(_0, _1, _2);
}
/* contains-recur?<?t> bool(a arr<nat>, value nat, i nat) */
uint8_t contains_recur__q(struct arr_2 a, uint64_t value, uint64_t i) {
	top:;
	uint64_t _0 = i;
	struct arr_2 _1 = a;
	uint64_t _2 = _1.size;
	uint8_t _3 = _op_equal_equal_0(_0, _2);
	if (_3) {
		return 0;
	} else {
		struct arr_2 _4 = a;
		uint64_t _5 = i;
		uint64_t _6 = noctx_at_2(_4, _5);
		uint64_t _7 = value;
		uint8_t _8 = _op_equal_equal_0(_6, _7);
		if (_8) {
			return 1;
		} else {
			struct arr_2 _9 = a;
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
uint64_t noctx_at_2(struct arr_2 a, uint64_t index) {
	uint64_t _0 = index;
	struct arr_2 _1 = a;
	uint64_t _2 = _1.size;
	uint8_t _3 = _op_less(_0, _2);
	hard_assert(_3);
	struct arr_2 _4 = a;
	uint64_t* _5 = _4.data;
	uint64_t _6 = index;
	uint64_t* _7 = _5 + _6;
	return *_7;
}
/* temp-as-arr<?t> arr<nat>(a mut-list<nat>) */
struct arr_2 temp_as_arr_0(struct mut_list* a) {
	struct mut_list* _0 = a;
	struct mut_arr _1 = temp_as_mut_arr(_0);
	return temp_as_arr_1(_1);
}
/* temp-as-arr<?t> arr<nat>(a mut-arr<nat>) */
struct arr_2 temp_as_arr_1(struct mut_arr a) {
	struct mut_arr _0 = a;
	return _0.arr;
}
/* temp-as-mut-arr<?t> mut-arr<nat>(a mut-list<nat>) */
struct mut_arr temp_as_mut_arr(struct mut_list* a) {
	struct mut_list* _0 = a;
	uint64_t _1 = _0->size;
	struct mut_list* _2 = a;
	uint64_t* _3 = data_0(_2);
	struct arr_2 _4 = (struct arr_2) {_1, _3};
	return (struct mut_arr) {_4};
}
/* data<?t> ptr<nat>(a mut-list<nat>) */
uint64_t* data_0(struct mut_list* a) {
	struct mut_list* _0 = a;
	struct mut_arr _1 = _0->backing;
	return data_1(_1);
}
/* data<?t> ptr<nat>(a mut-arr<nat>) */
uint64_t* data_1(struct mut_arr a) {
	struct mut_arr _0 = a;
	struct arr_2 _1 = _0.arr;
	return _1.data;
}
/* pop-recur pop-task-result(prev task-queue-node, exclusions mut-list<nat>, cur-time nat, first-task-time opt<nat>) */
struct pop_task_result pop_recur(struct task_queue_node* prev, struct mut_list* exclusions, uint64_t cur_time, struct opt_5 first_task_time) {
	top:;
	struct task_queue_node* _0 = prev;
	struct opt_2 _1 = _0->next;
	switch (_1.kind) {
		case 0: {
			uint8_t _2 = 1;
			struct opt_5 _3 = first_task_time;
			struct no_task _4 = (struct no_task) {_2, _3};
			return (struct pop_task_result) {1, .as1 = _4};
		}
		case 1: {
			struct some_2 s0 = _1.as1;
			
			struct task_queue_node* cur1;
			struct some_2 _5 = s0;
			cur1 = _5.value;
			
			struct task task2;
			struct task_queue_node* _6 = cur1;
			task2 = _6->task;
			
			struct task _7 = task2;
			uint64_t _8 = _7.time;
			uint64_t _9 = cur_time;
			uint8_t _10 = _op_less_equal(_8, _9);
			if (_10) {
				struct mut_list* _11 = exclusions;
				struct task _12 = task2;
				uint64_t _13 = _12.exclusion;
				uint8_t _14 = contains__q_0(_11, _13);
				if (_14) {
					struct task_queue_node* _15 = cur1;
					struct mut_list* _16 = exclusions;
					uint64_t _17 = cur_time;
					struct opt_5 _18 = first_task_time;struct opt_5 _19;
					
					switch (_18.kind) {
						case 0: {
							struct task _20 = task2;
							uint64_t _21 = _20.time;
							_19 = to_opt_time(_21);
							break;
						}
						case 1: {
							_19 = first_task_time;
							break;
						}
						default:
							(assert(0),(struct opt_5) {0});
					}
					prev = _15;
					exclusions = _16;
					cur_time = _17;
					first_task_time = _19;
					goto top;
				} else {
					struct task_queue_node* _22 = prev;
					struct task_queue_node* _23 = cur1;
					struct opt_2 _24 = _23->next;
					_22->next = _24;
					struct mut_list* _25 = exclusions;
					struct task _26 = task2;
					uint64_t _27 = _26.exclusion;
					push_capacity_must_be_sufficient(_25, _27);
					struct task _28 = task2;
					return (struct pop_task_result) {0, .as0 = _28};
				}
			} else {
				uint8_t _29 = 1;
				struct task _30 = task2;
				uint64_t _31 = _30.time;
				struct some_5 _32 = (struct some_5) {_31};
				struct opt_5 _33 = (struct opt_5) {1, .as1 = _32};
				struct no_task _34 = (struct no_task) {_29, _33};
				return (struct pop_task_result) {1, .as1 = _34};
			}
		}
		default:
			return (assert(0),(struct pop_task_result) {0});
	}
}
/* to-opt-time opt<nat>(a nat) */
struct opt_5 to_opt_time(uint64_t a) {
	uint64_t _0 = a;
	uint64_t _1 = no_timestamp();
	uint8_t _2 = _op_equal_equal_0(_0, _1);
	if (_2) {
		struct none _3 = (struct none) {};
		return (struct opt_5) {0, .as0 = _3};
	} else {
		uint64_t _4 = a;
		struct some_5 _5 = (struct some_5) {_4};
		return (struct opt_5) {1, .as1 = _5};
	}
}
/* push-capacity-must-be-sufficient<nat> void(a mut-list<nat>, value nat) */
struct void_ push_capacity_must_be_sufficient(struct mut_list* a, uint64_t value) {
	struct mut_list* _0 = a;
	uint64_t _1 = _0->size;
	struct mut_list* _2 = a;
	uint64_t _3 = capacity(_2);
	uint8_t _4 = _op_less(_1, _3);
	hard_assert(_4);
	uint64_t old_size0;
	struct mut_list* _5 = a;
	old_size0 = _5->size;
	
	struct mut_list* _6 = a;
	uint64_t _7 = old_size0;
	uint64_t _8 = noctx_incr(_7);
	_6->size = _8;
	struct mut_list* _9 = a;
	uint64_t _10 = old_size0;
	uint64_t _11 = value;
	return noctx_set_at(_9, _10, _11);
}
/* capacity<?t> nat(a mut-list<nat>) */
uint64_t capacity(struct mut_list* a) {
	struct mut_list* _0 = a;
	struct mut_arr _1 = _0->backing;
	return size_1(_1);
}
/* size<?t> nat(a mut-arr<nat>) */
uint64_t size_1(struct mut_arr a) {
	struct mut_arr _0 = a;
	struct arr_2 _1 = _0.arr;
	return _1.size;
}
/* noctx-set-at<?t> void(a mut-list<nat>, index nat, value nat) */
struct void_ noctx_set_at(struct mut_list* a, uint64_t index, uint64_t value) {
	uint64_t _0 = index;
	struct mut_list* _1 = a;
	uint64_t _2 = _1->size;
	uint8_t _3 = _op_less(_0, _2);
	hard_assert(_3);
	struct mut_list* _4 = a;
	uint64_t* _5 = data_0(_4);
	uint64_t _6 = index;
	uint64_t* _7 = _5 + _6;
	uint64_t _8 = value;
	return (*_7 = _8, (struct void_) {});
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
			return (assert(0),0);
	}
}
/* min-time opt<nat>(a opt<nat>, b opt<nat>) */
struct opt_5 min_time(struct opt_5 a, struct opt_5 b) {
	struct opt_5 _0 = a;
	switch (_0.kind) {
		case 0: {
			return b;
		}
		case 1: {
			struct some_5 sa0 = _0.as1;
			
			struct opt_5 _1 = b;
			switch (_1.kind) {
				case 0: {
					return a;
				}
				case 1: {
					struct some_5 sb1 = _1.as1;
					
					struct some_5 _2 = sa0;
					uint64_t _3 = _2.value;
					struct some_5 _4 = sb1;
					uint64_t _5 = _4.value;
					uint64_t _6 = min(_3, _5);
					struct some_5 _7 = (struct some_5) {_6};
					return (struct opt_5) {1, .as1 = _7};
				}
				default:
					return (assert(0),(struct opt_5) {0});
			}
		}
		default:
			return (assert(0),(struct opt_5) {0});
	}
}
/* min<nat> nat(a nat, b nat) */
uint64_t min(uint64_t a, uint64_t b) {
	uint64_t _0 = a;
	uint64_t _1 = b;
	uint8_t _2 = _op_less(_0, _1);
	if (_2) {
		return a;
	} else {
		return b;
	}
}
/* do-task void(gctx global-ctx, tls thread-local-stuff, chosen-task chosen-task) */
struct void_ do_task(struct global_ctx* gctx, struct thread_local_stuff* tls, struct chosen_task chosen_task) {
	struct island* island0;
	struct chosen_task _0 = chosen_task;
	island0 = _0.task_island;
	
	struct chosen_task _1 = chosen_task;
	struct task_or_gc _2 = _1.task_or_gc;
	switch (_2.kind) {
		case 0: {
			struct task task1 = _2.as0;
			
			struct ctx ctx2;
			struct global_ctx* _3 = gctx;
			struct thread_local_stuff* _4 = tls;
			struct island* _5 = island0;
			struct task _6 = task1;
			uint64_t _7 = _6.exclusion;
			ctx2 = new_ctx(_3, _4, _5, _7);
			
			struct task _8 = task1;
			struct fun_act0_0 _9 = _8.action;
			struct ctx* _10 = &ctx2;
			call_w_ctx_135(_9, _10);
			struct lock* _11 = &island0->tasks_lock;
			acquire_lock(_11);
			struct island* _12 = island0;
			struct task_queue* _13 = tasks(_12);
			struct task _14 = task1;
			return_task(_13, _14);
			struct lock* _15 = &island0->tasks_lock;
			release_lock(_15);
			struct ctx* _16 = &ctx2;
			return_ctx(_16);
			break;
		}
		case 1: {
			struct gc* _17 = &island0->gc;
			struct island* _18 = island0;
			struct island_gc_root _19 = _18->gc_root;
			run_garbage_collection(_17, _19);
			struct condition* _20 = &gctx->may_be_work_to_do;
			broadcast(_20);
			break;
		}
		default:
			(assert(0),(struct void_) {});
	}
	struct lock* _21 = &island0->tasks_lock;
	acquire_lock(_21);
	struct island* _22 = island0;
	struct island* _23 = island0;
	uint64_t _24 = _23->n_threads_running;
	uint64_t _25 = noctx_decr(_24);
	_22->n_threads_running = _25;
	struct lock* _26 = &island0->tasks_lock;
	return release_lock(_26);
}
/* return-task void(a task-queue, task task) */
struct void_ return_task(struct task_queue* a, struct task task) {
	struct mut_list* _0 = &a->currently_running_exclusions;
	struct task _1 = task;
	uint64_t _2 = _1.exclusion;
	return noctx_must_remove_unordered(_0, _2);
}
/* noctx-must-remove-unordered<nat> void(a mut-list<nat>, value nat) */
struct void_ noctx_must_remove_unordered(struct mut_list* a, uint64_t value) {
	struct mut_list* _0 = a;
	uint64_t _1 = 0u;
	uint64_t _2 = value;
	return noctx_must_remove_unordered_recur(_0, _1, _2);
}
/* noctx-must-remove-unordered-recur<?t> void(a mut-list<nat>, index nat, value nat) */
struct void_ noctx_must_remove_unordered_recur(struct mut_list* a, uint64_t index, uint64_t value) {
	top:;
	uint64_t _0 = index;
	struct mut_list* _1 = a;
	uint64_t _2 = _1->size;
	uint8_t _3 = _op_equal_equal_0(_0, _2);
	if (_3) {
		return (assert(0),(struct void_) {});
	} else {
		struct mut_list* _4 = a;
		uint64_t _5 = index;
		uint64_t _6 = noctx_at_3(_4, _5);
		uint64_t _7 = value;
		uint8_t _8 = _op_equal_equal_0(_6, _7);
		if (_8) {
			struct mut_list* _9 = a;
			uint64_t _10 = index;
			uint64_t _11 = noctx_remove_unordered_at_index(_9, _10);
			return drop_1(_11);
		} else {
			struct mut_list* _12 = a;
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
/* noctx-at<?t> nat(a mut-list<nat>, index nat) */
uint64_t noctx_at_3(struct mut_list* a, uint64_t index) {
	uint64_t _0 = index;
	struct mut_list* _1 = a;
	uint64_t _2 = _1->size;
	uint8_t _3 = _op_less(_0, _2);
	hard_assert(_3);
	struct mut_list* _4 = a;
	uint64_t* _5 = data_0(_4);
	uint64_t _6 = index;
	uint64_t* _7 = _5 + _6;
	return *_7;
}
/* drop<?t> void(_ nat) */
struct void_ drop_1(uint64_t _p0) {
	return (struct void_) {};
}
/* noctx-remove-unordered-at-index<?t> nat(a mut-list<nat>, index nat) */
uint64_t noctx_remove_unordered_at_index(struct mut_list* a, uint64_t index) {
	uint64_t res0;
	struct mut_list* _0 = a;
	uint64_t _1 = index;
	res0 = noctx_at_3(_0, _1);
	
	struct mut_list* _2 = a;
	uint64_t _3 = index;
	struct mut_list* _4 = a;
	uint64_t _5 = noctx_last(_4);
	noctx_set_at(_2, _3, _5);
	struct mut_list* _6 = a;
	struct mut_list* _7 = a;
	uint64_t _8 = _7->size;
	uint64_t _9 = noctx_decr(_8);
	_6->size = _9;
	return res0;
}
/* noctx-last<?t> nat(a mut-list<nat>) */
uint64_t noctx_last(struct mut_list* a) {
	struct mut_list* _0 = a;
	uint8_t _1 = empty__q_4(_0);
	hard_forbid(_1);
	struct mut_list* _2 = a;
	struct mut_list* _3 = a;
	uint64_t _4 = _3->size;
	uint64_t _5 = noctx_decr(_4);
	return noctx_at_3(_2, _5);
}
/* empty?<?t> bool(a mut-list<nat>) */
uint8_t empty__q_4(struct mut_list* a) {
	struct mut_list* _0 = a;
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
	mark_visit_244(_20, _21);
	struct gc* _22 = gc;
	struct gc* _23 = gc;
	uint8_t* _24 = _23->mark_begin;
	_22->mark_cur = _24;
	struct gc* _25 = gc;
	struct gc* _26 = gc;
	uint64_t* _27 = _26->data_begin;
	_25->data_cur = _27;
	struct gc* _28 = gc;
	uint8_t* _29 = _28->mark_begin;
	struct gc* _30 = gc;
	uint8_t* _31 = _30->mark_end;
	struct gc* _32 = gc;
	uint64_t* _33 = _32->data_begin;
	clear_free_mem(_29, _31, _33);
	struct gc* _34 = gc;
	return validate_gc(_34);
}
/* mark-visit<island-gc-root> (generated) (generated) */
struct void_ mark_visit_244(struct mark_ctx* mark_ctx, struct island_gc_root value) {
	struct mark_ctx* _0 = mark_ctx;
	struct island_gc_root _1 = value;
	struct task_queue _2 = _1.tasks;
	mark_visit_245(_0, _2);
	struct mark_ctx* _3 = mark_ctx;
	struct island_gc_root _4 = value;
	struct fun1_1 _5 = _4.log_handler;
	return mark_visit_282(_3, _5);
}
/* mark-visit<task-queue> (generated) (generated) */
struct void_ mark_visit_245(struct mark_ctx* mark_ctx, struct task_queue value) {
	struct mark_ctx* _0 = mark_ctx;
	struct task_queue _1 = value;
	struct opt_2 _2 = _1.head;
	mark_visit_246(_0, _2);
	struct mark_ctx* _3 = mark_ctx;
	struct task_queue _4 = value;
	struct mut_list _5 = _4.currently_running_exclusions;
	return mark_visit_289(_3, _5);
}
/* mark-visit<opt<task-queue-node>> (generated) (generated) */
struct void_ mark_visit_246(struct mark_ctx* mark_ctx, struct opt_2 value) {
	struct opt_2 _0 = value;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct some_2 value1 = _0.as1;
			
			struct mark_ctx* _1 = mark_ctx;
			struct some_2 _2 = value1;
			return mark_visit_247(_1, _2);
		}
		default:
			return (assert(0),(struct void_) {});
	}
}
/* mark-visit<some<task-queue-node>> (generated) (generated) */
struct void_ mark_visit_247(struct mark_ctx* mark_ctx, struct some_2 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct some_2 _1 = value;
	struct task_queue_node* _2 = _1.value;
	return mark_visit_288(_0, _2);
}
/* mark-visit<task-queue-node> (generated) (generated) */
struct void_ mark_visit_248(struct mark_ctx* mark_ctx, struct task_queue_node value) {
	struct mark_ctx* _0 = mark_ctx;
	struct task_queue_node _1 = value;
	struct task _2 = _1.task;
	mark_visit_249(_0, _2);
	struct mark_ctx* _3 = mark_ctx;
	struct task_queue_node _4 = value;
	struct opt_2 _5 = _4.next;
	return mark_visit_246(_3, _5);
}
/* mark-visit<task> (generated) (generated) */
struct void_ mark_visit_249(struct mark_ctx* mark_ctx, struct task value) {
	struct mark_ctx* _0 = mark_ctx;
	struct task _1 = value;
	struct fun_act0_0 _2 = _1.action;
	return mark_visit_250(_0, _2);
}
/* mark-visit<fun-act0<void>> (generated) (generated) */
struct void_ mark_visit_250(struct mark_ctx* mark_ctx, struct fun_act0_0 value) {
	struct fun_act0_0 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct call_ref_0__lambda0__lambda0* value0 = _0.as0;
			
			struct mark_ctx* _1 = mark_ctx;
			struct call_ref_0__lambda0__lambda0* _2 = value0;
			return mark_visit_274(_1, _2);
		}
		case 1: {
			struct call_ref_0__lambda0* value1 = _0.as1;
			
			struct mark_ctx* _3 = mark_ctx;
			struct call_ref_0__lambda0* _4 = value1;
			return mark_visit_276(_3, _4);
		}
		case 2: {
			struct call_ref_1__lambda0__lambda0* value2 = _0.as2;
			
			struct mark_ctx* _5 = mark_ctx;
			struct call_ref_1__lambda0__lambda0* _6 = value2;
			return mark_visit_278(_5, _6);
		}
		case 3: {
			struct call_ref_1__lambda0* value3 = _0.as3;
			
			struct mark_ctx* _7 = mark_ctx;
			struct call_ref_1__lambda0* _8 = value3;
			return mark_visit_280(_7, _8);
		}
		case 4: {
			struct with_log_handler__lambda0* value4 = _0.as4;
			
			struct mark_ctx* _9 = mark_ctx;
			struct with_log_handler__lambda0* _10 = value4;
			return mark_visit_285(_9, _10);
		}
		case 5: {
			struct with_log_handler__lambda1* value5 = _0.as5;
			
			struct mark_ctx* _11 = mark_ctx;
			struct with_log_handler__lambda1* _12 = value5;
			return mark_visit_287(_11, _12);
		}
		case 6: {
			return (struct void_) {};
		}
		case 7: {
			return (struct void_) {};
		}
		default:
			return (assert(0),(struct void_) {});
	}
}
/* mark-visit<call-ref<?out, ?in>.lambda0.lambda0> (generated) (generated) */
struct void_ mark_visit_251(struct mark_ctx* mark_ctx, struct call_ref_0__lambda0__lambda0 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct call_ref_0__lambda0__lambda0 _1 = value;
	struct fun_ref1 _2 = _1.f;
	mark_visit_252(_0, _2);
	struct mark_ctx* _3 = mark_ctx;
	struct call_ref_0__lambda0__lambda0 _4 = value;
	struct fut_0* _5 = _4.res;
	return mark_visit_269(_3, _5);
}
/* mark-visit<fun-ref1<int32, void>> (generated) (generated) */
struct void_ mark_visit_252(struct mark_ctx* mark_ctx, struct fun_ref1 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct fun_ref1 _1 = value;
	struct fun_act1_2 _2 = _1.fun;
	return mark_visit_253(_0, _2);
}
/* mark-visit<fun-act1<fut<int32>, void>> (generated) (generated) */
struct void_ mark_visit_253(struct mark_ctx* mark_ctx, struct fun_act1_2 value) {
	struct fun_act1_2 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct then2__lambda0* value0 = _0.as0;
			
			struct mark_ctx* _1 = mark_ctx;
			struct then2__lambda0* _2 = value0;
			return mark_visit_260(_1, _2);
		}
		default:
			return (assert(0),(struct void_) {});
	}
}
/* mark-visit<then2<int32>.lambda0> (generated) (generated) */
struct void_ mark_visit_254(struct mark_ctx* mark_ctx, struct then2__lambda0 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct then2__lambda0 _1 = value;
	struct fun_ref0 _2 = _1.cb;
	return mark_visit_255(_0, _2);
}
/* mark-visit<fun-ref0<int32>> (generated) (generated) */
struct void_ mark_visit_255(struct mark_ctx* mark_ctx, struct fun_ref0 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct fun_ref0 _1 = value;
	struct fun_act0_1 _2 = _1.fun;
	return mark_visit_256(_0, _2);
}
/* mark-visit<fun-act0<fut<int32>>> (generated) (generated) */
struct void_ mark_visit_256(struct mark_ctx* mark_ctx, struct fun_act0_1 value) {
	struct fun_act0_1 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct add_first_task__lambda0* value0 = _0.as0;
			
			struct mark_ctx* _1 = mark_ctx;
			struct add_first_task__lambda0* _2 = value0;
			return mark_visit_259(_1, _2);
		}
		default:
			return (assert(0),(struct void_) {});
	}
}
/* mark-visit<add-first-task.lambda0> (generated) (generated) */
struct void_ mark_visit_257(struct mark_ctx* mark_ctx, struct add_first_task__lambda0 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct add_first_task__lambda0 _1 = value;
	struct arr_4 _2 = _1.all_args;
	return mark_arr_258(_0, _2);
}
/* mark-arr<raw-ptr(char)> (generated) (generated) */
struct void_ mark_arr_258(struct mark_ctx* mark_ctx, struct arr_4 a) {
	uint8_t dropped0;
	struct mark_ctx* _0 = mark_ctx;
	struct arr_4 _1 = a;
	char** _2 = _1.data;
	uint8_t* _3 = (uint8_t*) _2;
	struct arr_4 _4 = a;
	uint64_t _5 = _4.size;
	uint64_t _6 = sizeof(char*);
	uint64_t _7 = _5 * _6;
	dropped0 = mark(_0, _3, _7);
	
	return (struct void_) {};
}
/* mark-visit<gc-ptr(add-first-task.lambda0)> (generated) (generated) */
struct void_ mark_visit_259(struct mark_ctx* mark_ctx, struct add_first_task__lambda0* value) {
	struct mark_ctx* _0 = mark_ctx;
	struct add_first_task__lambda0* _1 = value;
	uint8_t* _2 = (uint8_t*) _1;
	uint64_t _3 = sizeof(struct add_first_task__lambda0);
	uint8_t _4 = mark(_0, _2, _3);
	if (_4) {
		struct mark_ctx* _5 = mark_ctx;
		struct add_first_task__lambda0* _6 = value;
		struct add_first_task__lambda0 _7 = *_6;
		return mark_visit_257(_5, _7);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(then2<int32>.lambda0)> (generated) (generated) */
struct void_ mark_visit_260(struct mark_ctx* mark_ctx, struct then2__lambda0* value) {
	struct mark_ctx* _0 = mark_ctx;
	struct then2__lambda0* _1 = value;
	uint8_t* _2 = (uint8_t*) _1;
	uint64_t _3 = sizeof(struct then2__lambda0);
	uint8_t _4 = mark(_0, _2, _3);
	if (_4) {
		struct mark_ctx* _5 = mark_ctx;
		struct then2__lambda0* _6 = value;
		struct then2__lambda0 _7 = *_6;
		return mark_visit_254(_5, _7);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<fut<int32>> (generated) (generated) */
struct void_ mark_visit_261(struct mark_ctx* mark_ctx, struct fut_0 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct fut_0 _1 = value;
	struct fut_state_0 _2 = _1.state;
	return mark_visit_262(_0, _2);
}
/* mark-visit<fut-state<int32>> (generated) (generated) */
struct void_ mark_visit_262(struct mark_ctx* mark_ctx, struct fut_state_0 value) {
	struct fut_state_0 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct fut_state_callbacks_0 value0 = _0.as0;
			
			struct mark_ctx* _1 = mark_ctx;
			struct fut_state_callbacks_0 _2 = value0;
			return mark_visit_263(_1, _2);
		}
		case 1: {
			return (struct void_) {};
		}
		case 2: {
			struct exception value2 = _0.as2;
			
			struct mark_ctx* _3 = mark_ctx;
			struct exception _4 = value2;
			return mark_visit_272(_3, _4);
		}
		default:
			return (assert(0),(struct void_) {});
	}
}
/* mark-visit<fut-state-callbacks<int32>> (generated) (generated) */
struct void_ mark_visit_263(struct mark_ctx* mark_ctx, struct fut_state_callbacks_0 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct fut_state_callbacks_0 _1 = value;
	struct opt_0 _2 = _1.head;
	return mark_visit_264(_0, _2);
}
/* mark-visit<opt<fut-callback-node<int32>>> (generated) (generated) */
struct void_ mark_visit_264(struct mark_ctx* mark_ctx, struct opt_0 value) {
	struct opt_0 _0 = value;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct some_0 value1 = _0.as1;
			
			struct mark_ctx* _1 = mark_ctx;
			struct some_0 _2 = value1;
			return mark_visit_265(_1, _2);
		}
		default:
			return (assert(0),(struct void_) {});
	}
}
/* mark-visit<some<fut-callback-node<int32>>> (generated) (generated) */
struct void_ mark_visit_265(struct mark_ctx* mark_ctx, struct some_0 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct some_0 _1 = value;
	struct fut_callback_node_0* _2 = _1.value;
	return mark_visit_271(_0, _2);
}
/* mark-visit<fut-callback-node<int32>> (generated) (generated) */
struct void_ mark_visit_266(struct mark_ctx* mark_ctx, struct fut_callback_node_0 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct fut_callback_node_0 _1 = value;
	struct fun_act1_0 _2 = _1.cb;
	mark_visit_267(_0, _2);
	struct mark_ctx* _3 = mark_ctx;
	struct fut_callback_node_0 _4 = value;
	struct opt_0 _5 = _4.next_node;
	return mark_visit_264(_3, _5);
}
/* mark-visit<fun-act1<void, result<int32, exception>>> (generated) (generated) */
struct void_ mark_visit_267(struct mark_ctx* mark_ctx, struct fun_act1_0 value) {
	struct fun_act1_0 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct forward_to__lambda0* value0 = _0.as0;
			
			struct mark_ctx* _1 = mark_ctx;
			struct forward_to__lambda0* _2 = value0;
			return mark_visit_270(_1, _2);
		}
		default:
			return (assert(0),(struct void_) {});
	}
}
/* mark-visit<forward-to<?out>.lambda0> (generated) (generated) */
struct void_ mark_visit_268(struct mark_ctx* mark_ctx, struct forward_to__lambda0 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct forward_to__lambda0 _1 = value;
	struct fut_0* _2 = _1.to;
	return mark_visit_269(_0, _2);
}
/* mark-visit<gc-ptr(fut<int32>)> (generated) (generated) */
struct void_ mark_visit_269(struct mark_ctx* mark_ctx, struct fut_0* value) {
	struct mark_ctx* _0 = mark_ctx;
	struct fut_0* _1 = value;
	uint8_t* _2 = (uint8_t*) _1;
	uint64_t _3 = sizeof(struct fut_0);
	uint8_t _4 = mark(_0, _2, _3);
	if (_4) {
		struct mark_ctx* _5 = mark_ctx;
		struct fut_0* _6 = value;
		struct fut_0 _7 = *_6;
		return mark_visit_261(_5, _7);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(forward-to<?out>.lambda0)> (generated) (generated) */
struct void_ mark_visit_270(struct mark_ctx* mark_ctx, struct forward_to__lambda0* value) {
	struct mark_ctx* _0 = mark_ctx;
	struct forward_to__lambda0* _1 = value;
	uint8_t* _2 = (uint8_t*) _1;
	uint64_t _3 = sizeof(struct forward_to__lambda0);
	uint8_t _4 = mark(_0, _2, _3);
	if (_4) {
		struct mark_ctx* _5 = mark_ctx;
		struct forward_to__lambda0* _6 = value;
		struct forward_to__lambda0 _7 = *_6;
		return mark_visit_268(_5, _7);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(fut-callback-node<int32>)> (generated) (generated) */
struct void_ mark_visit_271(struct mark_ctx* mark_ctx, struct fut_callback_node_0* value) {
	struct mark_ctx* _0 = mark_ctx;
	struct fut_callback_node_0* _1 = value;
	uint8_t* _2 = (uint8_t*) _1;
	uint64_t _3 = sizeof(struct fut_callback_node_0);
	uint8_t _4 = mark(_0, _2, _3);
	if (_4) {
		struct mark_ctx* _5 = mark_ctx;
		struct fut_callback_node_0* _6 = value;
		struct fut_callback_node_0 _7 = *_6;
		return mark_visit_266(_5, _7);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<exception> (generated) (generated) */
struct void_ mark_visit_272(struct mark_ctx* mark_ctx, struct exception value) {
	struct mark_ctx* _0 = mark_ctx;
	struct exception _1 = value;
	struct arr_0 _2 = _1.message;
	return mark_arr_273(_0, _2);
}
/* mark-arr<char> (generated) (generated) */
struct void_ mark_arr_273(struct mark_ctx* mark_ctx, struct arr_0 a) {
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
struct void_ mark_visit_274(struct mark_ctx* mark_ctx, struct call_ref_0__lambda0__lambda0* value) {
	struct mark_ctx* _0 = mark_ctx;
	struct call_ref_0__lambda0__lambda0* _1 = value;
	uint8_t* _2 = (uint8_t*) _1;
	uint64_t _3 = sizeof(struct call_ref_0__lambda0__lambda0);
	uint8_t _4 = mark(_0, _2, _3);
	if (_4) {
		struct mark_ctx* _5 = mark_ctx;
		struct call_ref_0__lambda0__lambda0* _6 = value;
		struct call_ref_0__lambda0__lambda0 _7 = *_6;
		return mark_visit_251(_5, _7);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<call-ref<?out, ?in>.lambda0> (generated) (generated) */
struct void_ mark_visit_275(struct mark_ctx* mark_ctx, struct call_ref_0__lambda0 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct call_ref_0__lambda0 _1 = value;
	struct fun_ref1 _2 = _1.f;
	mark_visit_252(_0, _2);
	struct mark_ctx* _3 = mark_ctx;
	struct call_ref_0__lambda0 _4 = value;
	struct fut_0* _5 = _4.res;
	return mark_visit_269(_3, _5);
}
/* mark-visit<gc-ptr(call-ref<?out, ?in>.lambda0)> (generated) (generated) */
struct void_ mark_visit_276(struct mark_ctx* mark_ctx, struct call_ref_0__lambda0* value) {
	struct mark_ctx* _0 = mark_ctx;
	struct call_ref_0__lambda0* _1 = value;
	uint8_t* _2 = (uint8_t*) _1;
	uint64_t _3 = sizeof(struct call_ref_0__lambda0);
	uint8_t _4 = mark(_0, _2, _3);
	if (_4) {
		struct mark_ctx* _5 = mark_ctx;
		struct call_ref_0__lambda0* _6 = value;
		struct call_ref_0__lambda0 _7 = *_6;
		return mark_visit_275(_5, _7);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<call-ref<?out>.lambda0.lambda0> (generated) (generated) */
struct void_ mark_visit_277(struct mark_ctx* mark_ctx, struct call_ref_1__lambda0__lambda0 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct call_ref_1__lambda0__lambda0 _1 = value;
	struct fun_ref0 _2 = _1.f;
	mark_visit_255(_0, _2);
	struct mark_ctx* _3 = mark_ctx;
	struct call_ref_1__lambda0__lambda0 _4 = value;
	struct fut_0* _5 = _4.res;
	return mark_visit_269(_3, _5);
}
/* mark-visit<gc-ptr(call-ref<?out>.lambda0.lambda0)> (generated) (generated) */
struct void_ mark_visit_278(struct mark_ctx* mark_ctx, struct call_ref_1__lambda0__lambda0* value) {
	struct mark_ctx* _0 = mark_ctx;
	struct call_ref_1__lambda0__lambda0* _1 = value;
	uint8_t* _2 = (uint8_t*) _1;
	uint64_t _3 = sizeof(struct call_ref_1__lambda0__lambda0);
	uint8_t _4 = mark(_0, _2, _3);
	if (_4) {
		struct mark_ctx* _5 = mark_ctx;
		struct call_ref_1__lambda0__lambda0* _6 = value;
		struct call_ref_1__lambda0__lambda0 _7 = *_6;
		return mark_visit_277(_5, _7);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<call-ref<?out>.lambda0> (generated) (generated) */
struct void_ mark_visit_279(struct mark_ctx* mark_ctx, struct call_ref_1__lambda0 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct call_ref_1__lambda0 _1 = value;
	struct fun_ref0 _2 = _1.f;
	mark_visit_255(_0, _2);
	struct mark_ctx* _3 = mark_ctx;
	struct call_ref_1__lambda0 _4 = value;
	struct fut_0* _5 = _4.res;
	return mark_visit_269(_3, _5);
}
/* mark-visit<gc-ptr(call-ref<?out>.lambda0)> (generated) (generated) */
struct void_ mark_visit_280(struct mark_ctx* mark_ctx, struct call_ref_1__lambda0* value) {
	struct mark_ctx* _0 = mark_ctx;
	struct call_ref_1__lambda0* _1 = value;
	uint8_t* _2 = (uint8_t*) _1;
	uint64_t _3 = sizeof(struct call_ref_1__lambda0);
	uint8_t _4 = mark(_0, _2, _3);
	if (_4) {
		struct mark_ctx* _5 = mark_ctx;
		struct call_ref_1__lambda0* _6 = value;
		struct call_ref_1__lambda0 _7 = *_6;
		return mark_visit_279(_5, _7);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<with-log-handler<void>.lambda0> (generated) (generated) */
struct void_ mark_visit_281(struct mark_ctx* mark_ctx, struct with_log_handler__lambda0 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct with_log_handler__lambda0 _1 = value;
	struct fun1_1 _2 = _1.original_handler;
	return mark_visit_282(_0, _2);
}
/* mark-visit<fun1<void, logged>> (generated) (generated) */
struct void_ mark_visit_282(struct mark_ctx* mark_ctx, struct fun1_1 value) {
	struct fun1_1 _0 = value;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct main_0__lambda0* value1 = _0.as1;
			
			struct mark_ctx* _1 = mark_ctx;
			struct main_0__lambda0* _2 = value1;
			return mark_visit_284(_1, _2);
		}
		case 2: {
			return (struct void_) {};
		}
		default:
			return (assert(0),(struct void_) {});
	}
}
/* mark-visit<main.lambda0> (generated) (generated) */
struct void_ mark_visit_283(struct mark_ctx* mark_ctx, struct main_0__lambda0 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct main_0__lambda0 _1 = value;
	struct fun1_1 _2 = _1.lh;
	return mark_visit_282(_0, _2);
}
/* mark-visit<gc-ptr(main.lambda0)> (generated) (generated) */
struct void_ mark_visit_284(struct mark_ctx* mark_ctx, struct main_0__lambda0* value) {
	struct mark_ctx* _0 = mark_ctx;
	struct main_0__lambda0* _1 = value;
	uint8_t* _2 = (uint8_t*) _1;
	uint64_t _3 = sizeof(struct main_0__lambda0);
	uint8_t _4 = mark(_0, _2, _3);
	if (_4) {
		struct mark_ctx* _5 = mark_ctx;
		struct main_0__lambda0* _6 = value;
		struct main_0__lambda0 _7 = *_6;
		return mark_visit_283(_5, _7);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(with-log-handler<void>.lambda0)> (generated) (generated) */
struct void_ mark_visit_285(struct mark_ctx* mark_ctx, struct with_log_handler__lambda0* value) {
	struct mark_ctx* _0 = mark_ctx;
	struct with_log_handler__lambda0* _1 = value;
	uint8_t* _2 = (uint8_t*) _1;
	uint64_t _3 = sizeof(struct with_log_handler__lambda0);
	uint8_t _4 = mark(_0, _2, _3);
	if (_4) {
		struct mark_ctx* _5 = mark_ctx;
		struct with_log_handler__lambda0* _6 = value;
		struct with_log_handler__lambda0 _7 = *_6;
		return mark_visit_281(_5, _7);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<with-log-handler<void>.lambda1> (generated) (generated) */
struct void_ mark_visit_286(struct mark_ctx* mark_ctx, struct with_log_handler__lambda1 value) {
	struct mark_ctx* _0 = mark_ctx;
	struct with_log_handler__lambda1 _1 = value;
	struct fun1_1 _2 = _1.handler;
	mark_visit_282(_0, _2);
	struct mark_ctx* _3 = mark_ctx;
	struct with_log_handler__lambda1 _4 = value;
	struct fun_act0_0 _5 = _4.cb;
	return mark_visit_250(_3, _5);
}
/* mark-visit<gc-ptr(with-log-handler<void>.lambda1)> (generated) (generated) */
struct void_ mark_visit_287(struct mark_ctx* mark_ctx, struct with_log_handler__lambda1* value) {
	struct mark_ctx* _0 = mark_ctx;
	struct with_log_handler__lambda1* _1 = value;
	uint8_t* _2 = (uint8_t*) _1;
	uint64_t _3 = sizeof(struct with_log_handler__lambda1);
	uint8_t _4 = mark(_0, _2, _3);
	if (_4) {
		struct mark_ctx* _5 = mark_ctx;
		struct with_log_handler__lambda1* _6 = value;
		struct with_log_handler__lambda1 _7 = *_6;
		return mark_visit_286(_5, _7);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(task-queue-node)> (generated) (generated) */
struct void_ mark_visit_288(struct mark_ctx* mark_ctx, struct task_queue_node* value) {
	struct mark_ctx* _0 = mark_ctx;
	struct task_queue_node* _1 = value;
	uint8_t* _2 = (uint8_t*) _1;
	uint64_t _3 = sizeof(struct task_queue_node);
	uint8_t _4 = mark(_0, _2, _3);
	if (_4) {
		struct mark_ctx* _5 = mark_ctx;
		struct task_queue_node* _6 = value;
		struct task_queue_node _7 = *_6;
		return mark_visit_248(_5, _7);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<mut-list<nat>> (generated) (generated) */
struct void_ mark_visit_289(struct mark_ctx* mark_ctx, struct mut_list value) {
	struct mark_ctx* _0 = mark_ctx;
	struct mut_list _1 = value;
	struct mut_arr _2 = _1.backing;
	return mark_visit_290(_0, _2);
}
/* mark-visit<mut-arr<nat>> (generated) (generated) */
struct void_ mark_visit_290(struct mark_ctx* mark_ctx, struct mut_arr value) {
	struct mark_ctx* _0 = mark_ctx;
	struct mut_arr _1 = value;
	struct arr_2 _2 = _1.arr;
	return mark_arr_291(_0, _2);
}
/* mark-arr<nat-64> (generated) (generated) */
struct void_ mark_arr_291(struct mark_ctx* mark_ctx, struct arr_2 a) {
	uint8_t dropped0;
	struct mark_ctx* _0 = mark_ctx;
	struct arr_2 _1 = a;
	uint64_t* _2 = _1.data;
	uint8_t* _3 = (uint8_t*) _2;
	struct arr_2 _4 = a;
	uint64_t _5 = _4.size;
	uint64_t _6 = sizeof(uint64_t);
	uint64_t _7 = _5 * _6;
	dropped0 = mark(_0, _3, _7);
	
	return (struct void_) {};
}
/* clear-free-mem void(mark-ptr ptr<bool>, mark-end ptr<bool>, data-ptr ptr<nat>) */
struct void_ clear_free_mem(uint8_t* mark_ptr, uint8_t* mark_end, uint64_t* data_ptr) {
	top:;
	uint8_t* _0 = mark_ptr;
	uint8_t* _1 = mark_end;
	uint8_t _2 = _0 == _1;
	uint8_t _3 = !_2;
	if (_3) {
		uint8_t* _4 = mark_ptr;
		uint8_t _5 = *_4;
		uint8_t _6 = !_5;
		if (_6) {
			uint64_t* _7 = data_ptr;
			uint64_t _8 = 18077161789910350558u;
			*_7 = _8;
		} else {
			(struct void_) {};
		}
		uint8_t* _9 = mark_ptr;
		uint8_t* _10 = incr_0(_9);
		uint8_t* _11 = mark_end;
		uint64_t* _12 = data_ptr;
		mark_ptr = _10;
		mark_end = _11;
		data_ptr = _12;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* wait-on void(cond condition, until-time opt<nat>, last-checked nat) */
struct void_ wait_on(struct condition* cond, struct opt_5 until_time, uint64_t last_checked) {
	top:;
	struct condition* _0 = cond;
	uint64_t _1 = _0->value;
	uint64_t _2 = last_checked;
	uint8_t _3 = _op_equal_equal_0(_1, _2);
	if (_3) {
		yield_thread();
		struct opt_5 _4 = until_time;
		uint8_t _5 = before_time__q(_4);
		if (_5) {
			struct condition* _6 = cond;
			struct opt_5 _7 = until_time;
			uint64_t _8 = last_checked;
			cond = _6;
			until_time = _7;
			last_checked = _8;
			goto top;
		} else {
			return (struct void_) {};
		}
	} else {
		return (struct void_) {};
	}
}
/* before-time? bool(until-time opt<nat>) */
uint8_t before_time__q(struct opt_5 until_time) {
	struct opt_5 _0 = until_time;
	switch (_0.kind) {
		case 0: {
			return 1;
		}
		case 1: {
			struct some_5 s0 = _0.as1;
			
			uint64_t _1 = get_monotime_nsec();
			struct some_5 _2 = s0;
			uint64_t _3 = _2.value;
			return _op_less(_1, _3);
		}
		default:
			return (assert(0),0);
	}
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
	struct cell_2 thread_return0;
	uint8_t* _0 = NULL;
	thread_return0 = (struct cell_2) {_0};
	
	int32_t err1;
	uint64_t _1 = tid;
	struct cell_2* _2 = &thread_return0;
	err1 = pthread_join(_1, _2);
	
	int32_t _3 = err1;
	int32_t _4 = 0;
	uint8_t _5 = _op_bang_equal_2(_3, _4);
	if (_5) {
		int32_t _6 = err1;
		int32_t _7 = einval();
		uint8_t _8 = _op_equal_equal_2(_6, _7);
		if (_8) {
			todo_0();
		} else {
			int32_t _9 = err1;
			int32_t _10 = esrch();
			uint8_t _11 = _op_equal_equal_2(_9, _10);
			if (_11) {
				todo_0();
			} else {
				todo_0();
			}
		}
	} else {
		(struct void_) {};
	}
	struct cell_2* _12 = &thread_return0;
	uint8_t* _13 = get_1(_12);
	uint8_t _14 = null__q_0(_13);
	return hard_assert(_14);
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
uint8_t* get_1(struct cell_2* c) {
	struct cell_2* _0 = c;
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
			struct err _6 = (struct err) {_5};
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
/* main fut<int32>(_ arr<arr<char>>) */
struct fut_0* main_0(struct ctx* ctx, struct arr_1 _p0) {
	struct ctx* _0 = ctx;
	struct info _1 = (struct info) {};
	struct log_level _2 = (struct log_level) {0, .as0 = _1};
	struct arr_0 _3 = (struct arr_0) {11, constantarr_0_15};
	log(_0, _2, _3);
	struct fun1_1 lh0;
	struct ctx* _4 = ctx;
	lh0 = get_log_handler(_4);
	
	struct fun1_1 doubler1;
	struct main_0__lambda0* temp0;
	struct ctx* _5 = ctx;
	uint64_t _6 = sizeof(struct main_0__lambda0);
	uint8_t* _7 = alloc(_5, _6);
	temp0 = (struct main_0__lambda0*) _7;
	
	struct main_0__lambda0* _8 = temp0;
	struct fun1_1 _9 = lh0;
	struct main_0__lambda0 _10 = (struct main_0__lambda0) {_9};
	*_8 = _10;
	struct main_0__lambda0* _11 = temp0;
	doubler1 = (struct fun1_1) {1, .as1 = _11};
	
	struct ctx* _12 = ctx;
	struct fun1_1 _13 = doubler1;
	struct void_ _14 = (struct void_) {};
	struct fun_act0_0 _15 = (struct fun_act0_0) {6, .as6 = _14};
	with_log_handler(_12, _13, _15);
	struct ctx* _16 = ctx;
	struct void_ _17 = (struct void_) {};
	struct fun1_1 _18 = (struct fun1_1) {2, .as2 = _17};
	struct void_ _19 = (struct void_) {};
	struct fun_act0_0 _20 = (struct fun_act0_0) {7, .as7 = _19};
	with_log_handler(_16, _18, _20);
	struct ctx* _21 = ctx;
	int32_t _22 = 0;
	return resolved_1(_21, _22);
}
/* log void(level log-level, message arr<char>) */
struct void_ log(struct ctx* ctx, struct log_level level, struct arr_0 message) {
	struct ctx* _0 = ctx;
	struct ctx* _1 = ctx;
	struct fun1_1 _2 = get_log_handler(_1);
	struct logged* temp0;
	struct ctx* _3 = ctx;
	uint64_t _4 = sizeof(struct logged);
	uint8_t* _5 = alloc(_3, _4);
	temp0 = (struct logged*) _5;
	
	struct logged* _6 = temp0;
	struct log_level _7 = level;
	struct arr_0 _8 = message;
	struct logged _9 = (struct logged) {_7, _8};
	*_6 = _9;
	struct logged* _10 = temp0;
	return call_8(_0, _2, _10);
}
/* call<void, logged> void(a fun1<void, logged>, p0 logged) */
struct void_ call_8(struct ctx* ctx, struct fun1_1 a, struct logged* p0) {
	struct fun1_1 _0 = a;
	struct ctx* _1 = ctx;
	struct logged* _2 = p0;
	return call_w_ctx_309(_0, _1, _2);
}
/* call-w-ctx<void, gc-ptr(logged)> (generated) (generated) */
struct void_ call_w_ctx_309(struct fun1_1 a, struct ctx* ctx, struct logged* p0) {
	struct fun1_1 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			struct ctx* _1 = ctx;
			struct void_ _2 = closure0;
			struct logged* _3 = p0;
			return new_island__lambda1(_1, _2, _3);
		}
		case 1: {
			struct main_0__lambda0* closure1 = _0.as1;
			
			struct ctx* _4 = ctx;
			struct main_0__lambda0* _5 = closure1;
			struct logged* _6 = p0;
			return main_0__lambda0(_4, _5, _6);
		}
		case 2: {
			struct void_ closure2 = _0.as2;
			
			struct ctx* _7 = ctx;
			struct void_ _8 = closure2;
			struct logged* _9 = p0;
			return main_0__lambda2(_7, _8, _9);
		}
		default:
			return (assert(0),(struct void_) {});
	}
}
/* get-log-handler fun1<void, logged>() */
struct fun1_1 get_log_handler(struct ctx* ctx) {
	struct ctx* _0 = ctx;
	struct log_ctx* _1 = get_log_ctx(_0);
	return _1->handler;
}
/* get-log-ctx log-ctx() */
struct log_ctx* get_log_ctx(struct ctx* ctx) {
	struct ctx* _0 = ctx;
	uint8_t* _1 = _0->log_ctx;
	return (struct log_ctx*) _1;
}
/* main.lambda0 void(logged logged) */
struct void_ main_0__lambda0(struct ctx* ctx, struct main_0__lambda0* _closure, struct logged* logged) {
	struct ctx* _0 = ctx;
	struct main_0__lambda0* _1 = _closure;
	struct fun1_1 _2 = _1->lh;
	struct logged* _3 = logged;
	call_8(_0, _2, _3);
	struct ctx* _4 = ctx;
	struct main_0__lambda0* _5 = _closure;
	struct fun1_1 _6 = _5->lh;
	struct logged* _7 = logged;
	return call_8(_4, _6, _7);
}
/* with-log-handler<void> void(handler fun1<void, logged>, cb fun-act0<void>) */
struct void_ with_log_handler(struct ctx* ctx, struct fun1_1 handler, struct fun_act0_0 cb) {
	struct fun1_1 original_handler0;
	struct ctx* _0 = ctx;
	original_handler0 = get_log_handler(_0);
	
	struct ctx* _1 = ctx;
	struct with_log_handler__lambda0* temp0;
	struct ctx* _2 = ctx;
	uint64_t _3 = sizeof(struct with_log_handler__lambda0);
	uint8_t* _4 = alloc(_2, _3);
	temp0 = (struct with_log_handler__lambda0*) _4;
	
	struct with_log_handler__lambda0* _5 = temp0;
	struct fun1_1 _6 = original_handler0;
	struct with_log_handler__lambda0 _7 = (struct with_log_handler__lambda0) {_6};
	*_5 = _7;
	struct with_log_handler__lambda0* _8 = temp0;
	struct fun_act0_0 _9 = (struct fun_act0_0) {4, .as4 = _8};
	struct with_log_handler__lambda1* temp1;
	struct ctx* _10 = ctx;
	uint64_t _11 = sizeof(struct with_log_handler__lambda1);
	uint8_t* _12 = alloc(_10, _11);
	temp1 = (struct with_log_handler__lambda1*) _12;
	
	struct with_log_handler__lambda1* _13 = temp1;
	struct fun1_1 _14 = handler;
	struct fun_act0_0 _15 = cb;
	struct with_log_handler__lambda1 _16 = (struct with_log_handler__lambda1) {_14, _15};
	*_13 = _16;
	struct with_log_handler__lambda1* _17 = temp1;
	struct fun_act0_0 _18 = (struct fun_act0_0) {5, .as5 = _17};
	return finally(_1, _9, _18);
}
/* finally<?t> void(after fun-act0<void>, try fun-act0<void>) */
struct void_ finally(struct ctx* ctx, struct fun_act0_0 after, struct fun_act0_0 try) {
	struct void_ res0;
	struct ctx* _0 = ctx;
	struct fun_act0_0 _1 = try;
	struct finally__lambda0* temp0;
	struct ctx* _2 = ctx;
	uint64_t _3 = sizeof(struct finally__lambda0);
	uint8_t* _4 = alloc(_2, _3);
	temp0 = (struct finally__lambda0*) _4;
	
	struct finally__lambda0* _5 = temp0;
	struct fun_act0_0 _6 = after;
	struct finally__lambda0 _7 = (struct finally__lambda0) {_6};
	*_5 = _7;
	struct finally__lambda0* _8 = temp0;
	struct fun_act1_3 _9 = (struct fun_act1_3) {2, .as2 = _8};
	res0 = catch(_0, _1, _9);
	
	struct ctx* _10 = ctx;
	struct fun_act0_0 _11 = after;
	call_2(_10, _11);
	return res0;
}
/* finally<?t>.lambda0 void(err exception) */
struct void_ finally__lambda0(struct ctx* ctx, struct finally__lambda0* _closure, struct exception err) {
	struct ctx* _0 = ctx;
	struct finally__lambda0* _1 = _closure;
	struct fun_act0_0 _2 = _1->after;
	call_2(_0, _2);
	struct ctx* _3 = ctx;
	struct exception _4 = err;
	return throw(_3, _4);
}
/* set-log-handler void(handler fun1<void, logged>) */
struct void_ set_log_handler(struct ctx* ctx, struct fun1_1 handler) {
	struct ctx* _0 = ctx;
	struct log_ctx* _1 = get_log_ctx(_0);
	struct fun1_1 _2 = handler;
	return (_1->handler = _2, (struct void_) {});
}
/* with-log-handler<void>.lambda0 void() */
struct void_ with_log_handler__lambda0(struct ctx* ctx, struct with_log_handler__lambda0* _closure) {
	struct ctx* _0 = ctx;
	struct with_log_handler__lambda0* _1 = _closure;
	struct fun1_1 _2 = _1->original_handler;
	return set_log_handler(_0, _2);
}
/* with-log-handler<void>.lambda1 void() */
struct void_ with_log_handler__lambda1(struct ctx* ctx, struct with_log_handler__lambda1* _closure) {
	struct ctx* _0 = ctx;
	struct with_log_handler__lambda1* _1 = _closure;
	struct fun1_1 _2 = _1->handler;
	set_log_handler(_0, _2);
	struct ctx* _3 = ctx;
	struct with_log_handler__lambda1* _4 = _closure;
	struct fun_act0_0 _5 = _4->cb;
	return call_2(_3, _5);
}
/* main.lambda1 void() */
struct void_ main_0__lambda1(struct ctx* ctx, struct void_ _closure) {
	struct ctx* _0 = ctx;
	struct warn _1 = (struct warn) {};
	struct log_level _2 = (struct log_level) {1, .as1 = _1};
	struct arr_0 _3 = (struct arr_0) {12, constantarr_0_16};
	return log(_0, _2, _3);
}
/* drop<logged> void(_ logged) */
struct void_ drop_2(struct logged* _p0) {
	return (struct void_) {};
}
/* main.lambda2 void(it logged) */
struct void_ main_0__lambda2(struct ctx* ctx, struct void_ _closure, struct logged* it) {
	struct logged* _0 = it;
	return drop_2(_0);
}
/* main.lambda3 void() */
struct void_ main_0__lambda3(struct ctx* ctx, struct void_ _closure) {
	struct ctx* _0 = ctx;
	struct warn _1 = (struct warn) {};
	struct log_level _2 = (struct log_level) {1, .as1 = _1};
	struct arr_0 _3 = (struct arr_0) {12, constantarr_0_17};
	return log(_0, _2, _3);
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
	return rt_main(_0, _1, main_0);
}
