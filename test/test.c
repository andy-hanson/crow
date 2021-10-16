#include <stdatomic.h>
#include <stddef.h>
#include <stdint.h>

struct void_ {};
struct dir;
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
struct sym {
	char* to_c_str;
};
struct arr_1 {
	uint64_t size;
	struct sym* begin_ptr;
};
struct ok_0 {
	uint64_t value;
};
struct err_0;
struct none {
};
struct some_0 {
	struct fut_state_callbacks_0* value;
};
struct fut_state_resolved_0 {
	uint64_t value;
};
struct arr_2 {
	uint64_t size;
	struct str* begin_ptr;
};
struct global_ctx;
struct dynamic_sym_node;
struct some_1 {
	struct dynamic_sym_node* value;
};
struct island;
struct gc;
struct gc_ctx;
struct some_2 {
	struct gc_ctx* value;
};
struct island_gc_root;
struct task_queue;
struct task_queue_node;
struct task;
struct some_3 {
	struct task_queue_node* value;
};
struct mut_arr_0;
struct fix_arr_0;
struct arr_3 {
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
struct some_4 {
	struct backtrace_arrs* value;
};
struct some_5 {
	uint8_t** value;
};
struct some_6 {
	uint8_t* value;
};
struct some_7 {
	struct sym* value;
};
struct some_8 {
	struct named_val* value;
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
struct some_9 {
	char* value;
};
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
struct ok_1 {
	struct void_ value;
};
struct some_10 {
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
struct map_0__lambda0;
struct thread_args {
	uint64_t thread_id;
	struct global_ctx* gctx;
};
struct cell_0 {
	uint64_t inner_value;
};
struct chosen_task;
struct do_a_gc {
};
struct no_chosen_task;
struct some_11 {
	uint64_t value;
};
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
struct some_12 {
	struct arr_2 value;
};
struct arr_8;
struct some_13;
struct parsed_command;
struct dict_0;
struct inner_node_0;
struct arr_9;
struct leaf_node_0;
struct arrow_0;
struct arr_10 {
	uint64_t size;
	struct arrow_0* begin_ptr;
};
struct hasher {
	uint64_t cur;
};
struct hash_mix_0__lambda0 {
	struct hasher* hasher;
};
struct no_duplicate_keys_0__lambda0;
struct get_or_update_result_0;
struct some_14;
struct no_change {
};
struct remove {
};
struct insert_0 {
	struct arr_2 value;
};
struct some_15;
struct inner_node_to_leaf_0__lambda0;
struct fix_arr_3 {
	struct void_ ignore;
	struct arr_10 inner;
};
struct inner_node_to_leaf_0__lambda1;
struct update_with_default_0__lambda0;
struct get_or_update_leaf_0__lambda0;
struct new_inner_node_0__lambda0 {
	uint64_t hash_shift;
};
struct fix_arr_4;
struct fill_fix_arr_0__lambda0;
struct new_inner_node_0__lambda1;
struct _tilde_2__lambda0;
struct mut_dict_0;
struct mut_arr_2 {
	struct fix_arr_3 backing;
	uint64_t size;
};
struct fix_arr_5;
struct arr_11;
struct some_16;
struct some_17 {
	struct arr_0 value;
};
struct fix_arr_7__lambda0;
struct fill_fix_arr_1__lambda0;
struct fold_2__lambda0;
struct fold_2__lambda0__lambda0;
struct each_3__lambda0;
struct expand__e_0__lambda0 {
	struct mut_dict_0* bigger;
};
struct _concatEquals_4__lambda0 {
	struct mut_arr_2* a;
};
struct update__e_0__lambda0;
struct fold_7__lambda0;
struct fold_7__lambda0__lambda0;
struct map_to_arr_0__lambda0;
struct fill__e_0__lambda0;
struct mut_arr_3;
struct fix_arr_6;
struct fill_fix_arr_2__lambda0;
struct cell_3 {
	uint8_t inner_value;
};
struct fold_recur_6__lambda0;
struct fold_recur_6__lambda1;
struct each_4__lambda0;
struct parse_named_args_0__lambda0 {
	struct arr_2 arg_names;
	struct mut_arr_3* values;
	struct cell_3* help;
};
struct some_18 {
	struct str* value;
};
struct interp {
	struct mut_arr_1* inner;
};
struct reader {
	char* cur;
	char* end;
};
struct test_options;
struct r_index_of__lambda0 {
	char value;
};
struct dict_1;
struct inner_node_1;
struct arr_12;
struct leaf_node_1;
struct arrow_1;
struct arr_13 {
	uint64_t size;
	struct arrow_1* begin_ptr;
};
struct mut_dict_1;
struct mut_arr_4;
struct fix_arr_7 {
	struct void_ ignore;
	struct arr_13 inner;
};
struct fix_arr_8;
struct arr_14;
struct fix_arr_13__lambda0;
struct fill_fix_arr_3__lambda0;
struct fold_14__lambda0;
struct fold_14__lambda0__lambda0;
struct each_5__lambda0;
struct expand__e_1__lambda0 {
	struct mut_dict_1* bigger;
};
struct _concatEquals_6__lambda0 {
	struct mut_arr_4* a;
};
struct update__e_1__lambda0;
struct no_duplicate_keys_1__lambda0;
struct get_or_update_result_1;
struct some_19;
struct insert_1;
struct some_20;
struct inner_node_to_leaf_1__lambda0;
struct inner_node_to_leaf_1__lambda1;
struct update_with_default_1__lambda0;
struct get_or_update_leaf_1__lambda0;
struct new_inner_node_1__lambda0 {
	uint64_t hash_shift;
};
struct fix_arr_9;
struct fill_fix_arr_4__lambda0;
struct new_inner_node_1__lambda1;
struct _tilde_5__lambda0;
struct fold_21__lambda0;
struct fold_21__lambda0__lambda0;
struct map_to_arr_1__lambda0;
struct fill__e_1__lambda0;
struct failure;
struct arr_15 {
	uint64_t size;
	struct failure** begin_ptr;
};
struct ok_2;
struct err_1 {
	struct arr_15 value;
};
struct mut_arr_5;
struct fix_arr_10 {
	struct void_ ignore;
	struct arr_2 inner;
};
struct stat {
	uint64_t st_dev;
	uint32_t pad0;
	uint64_t st_ino_unused;
	uint32_t st_mode;
	uint32_t st_nlink;
	uint64_t st_uid;
	uint64_t st_gid;
	uint64_t st_rdev;
	uint32_t pad1;
	int64_t sts_ize;
	uint64_t st_blksize;
	uint64_t st_blocks;
	uint64_t st_atime;
	uint64_t st_atime_nsec;
	uint64_t st_mtime;
	uint64_t st_mtime_nsec;
	uint64_t st_ctime;
	uint64_t st_ctime_nsec;
	uint64_t st_ino;
	uint64_t unused;
};
struct some_21 {
	struct stat* value;
};
struct dirent;
struct bytes256;
struct cell_4 {
	struct dirent* inner_value;
};
struct fix_arr_20__lambda0 {
	struct arr_2 a;
};
struct each_child_recursive_1__lambda0;
struct list_tests__lambda0;
struct some_22 {
	char value;
};
struct mut_arr_6;
struct fix_arr_11 {
	struct void_ ignore;
	struct arr_15 inner;
};
struct flat_map_with_max_size__lambda0;
struct _concatEquals_9__lambda0 {
	struct mut_arr_6* a;
};
struct some_23 {
	struct failure* value;
};
struct run_crow_tests__lambda0;
struct some_24 {
	struct arr_15 value;
};
struct run_single_crow_test__lambda0;
struct print_test_result {
	uint8_t should_stop;
	struct arr_15 failures;
};
struct process_result;
struct pipes {
	int32_t write_pipe;
	int32_t read_pipe;
};
struct posix_spawn_file_actions_t;
struct cell_5 {
	int32_t inner_value;
};
struct pollfd {
	int32_t fd;
	int16_t events;
	int16_t revents;
};
struct fix_arr_12;
struct arr_16 {
	uint64_t size;
	struct pollfd* begin_ptr;
};
struct fix_arr_23__lambda0 {
	struct arr_16 a;
};
struct handle_revents_result {
	uint8_t had_POLLIN;
	uint8_t hung_up;
};
struct map_1__lambda0;
struct mut_arr_7;
struct fix_arr_13 {
	struct void_ ignore;
	struct arr_7 inner;
};
struct fold_recur_15__lambda0;
struct fold_recur_15__lambda1;
struct each_9__lambda0;
struct convert_environ__lambda0 {
	struct mut_arr_7* res;
};
struct do_test__lambda0;
struct do_test__lambda0__lambda0;
struct do_test__lambda1;
struct excluded_from_lint__lambda0;
struct list_lintable_files__lambda1 {
	struct mut_arr_5* res;
};
struct lint__lambda0 {
	struct test_options* options;
};
struct lines__lambda0;
struct lint_file__lambda0;
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
struct opt_2 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_2 as1;
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
struct opt_3 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_3 as1;
	};
};
struct fun1_0 {
	uint64_t kind;
	union {
		struct void_ as0;
		uint64_t __ensureSizeIs16;
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
		uint64_t __ensureSizeIs16;
	};
};
struct fun_act1_1 {
	uint64_t kind;
	union {
		struct _concatEquals_1__lambda0* as0;
		struct hash_mix_0__lambda0* as1;
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
struct opt_7 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_7 as1;
	};
};
struct opt_8 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_8 as1;
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
		struct none as0;
		struct some_9 as1;
	};
};
struct fun_act2_0 {
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
		struct none as0;
		struct some_10 as1;
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
		uint64_t __ensureSizeIs16;
	};
};
struct fun_act1_7 {
	uint64_t kind;
	union {
		struct map_0__lambda0* as0;
		struct fix_arr_20__lambda0* as1;
	};
};
struct choose_task_result;
struct task_or_gc;
struct opt_11 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_11 as1;
	};
};
struct choose_task_in_island_result;
struct pop_task_result;
struct opt_12 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_12 as1;
	};
};
struct opt_13;
struct node_0;
struct fun_act1_8 {
	uint64_t kind;
	union {
		struct void_ as0;
		struct void_ as1;
		struct void_ as2;
		struct void_ as3;
		struct excluded_from_lint__lambda0* as4;
		struct void_ as5;
	};
};
struct fun_act1_9 {
	uint64_t kind;
	union {
		struct no_duplicate_keys_0__lambda0* as0;
		struct get_or_update_leaf_0__lambda0* as1;
		struct update__e_0__lambda0* as2;
	};
};
struct fun_act2_1 {
	uint64_t kind;
	union {
		struct void_ as0;
		uint64_t __ensureSizeIs16;
	};
};
struct opt_14;
struct get_or_update_action_0 {
	uint64_t kind;
	union {
		struct no_change as0;
		struct remove as1;
		struct insert_0 as2;
	};
};
struct fun_act1_10 {
	uint64_t kind;
	union {
		struct _tilde_2__lambda0* as0;
	};
};
struct opt_15;
struct fun_act3_0 {
	uint64_t kind;
	union {
		struct inner_node_to_leaf_0__lambda0* as0;
		struct inner_node_to_leaf_0__lambda1* as1;
	};
};
struct fun_act1_11 {
	uint64_t kind;
	union {
		struct void_ as0;
		struct void_ as1;
		uint64_t __ensureSizeIs16;
	};
};
struct fun_act1_12 {
	uint64_t kind;
	union {
		struct update_with_default_0__lambda0* as0;
		struct fill_fix_arr_0__lambda0* as1;
	};
};
struct fun_act2_2 {
	uint64_t kind;
	union {
		struct new_inner_node_0__lambda0* as0;
	};
};
struct fun_act1_13 {
	uint64_t kind;
	union {
		struct new_inner_node_0__lambda1* as0;
		struct _concatEquals_4__lambda0* as1;
	};
};
struct entry_0;
struct opt_16;
struct opt_17 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_17 as1;
	};
};
struct fun_act1_14 {
	uint64_t kind;
	union {
		struct fix_arr_7__lambda0* as0;
		struct fill_fix_arr_1__lambda0* as1;
	};
};
struct fun_act2_3 {
	uint64_t kind;
	union {
		struct expand__e_0__lambda0* as0;
		struct parse_named_args_0__lambda0* as1;
	};
};
struct fun_act3_1 {
	uint64_t kind;
	union {
		struct each_3__lambda0* as0;
		struct each_4__lambda0* as1;
	};
};
struct fun_act2_4 {
	uint64_t kind;
	union {
		struct fold_2__lambda0* as0;
	};
};
struct fun_act2_5 {
	uint64_t kind;
	union {
		struct fold_2__lambda0__lambda0* as0;
		struct fold_recur_6__lambda1* as1;
	};
};
struct fun_act2_6 {
	uint64_t kind;
	union {
		struct void_ as0;
		uint64_t __ensureSizeIs16;
	};
};
struct fun_act3_2 {
	uint64_t kind;
	union {
		struct map_to_arr_0__lambda0* as0;
	};
};
struct fun_act2_7 {
	uint64_t kind;
	union {
		struct fold_7__lambda0* as0;
	};
};
struct fun_act2_8 {
	uint64_t kind;
	union {
		struct fold_7__lambda0__lambda0* as0;
	};
};
struct fun_act1_15 {
	uint64_t kind;
	union {
		struct fill__e_0__lambda0* as0;
	};
};
struct fun_act1_16 {
	uint64_t kind;
	union {
		struct fill_fix_arr_2__lambda0* as0;
	};
};
struct fun_act2_9 {
	uint64_t kind;
	union {
		struct fold_recur_6__lambda0* as0;
	};
};
struct opt_18 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_18 as1;
	};
};
struct fun_act1_17 {
	uint64_t kind;
	union {
		struct void_ as0;
		uint64_t __ensureSizeIs16;
	};
};
struct fun_act1_18 {
	uint64_t kind;
	union {
		struct r_index_of__lambda0* as0;
	};
};
struct node_1;
struct entry_1;
struct fun_act1_19 {
	uint64_t kind;
	union {
		struct fix_arr_13__lambda0* as0;
		struct fill_fix_arr_3__lambda0* as1;
	};
};
struct fun_act2_10 {
	uint64_t kind;
	union {
		struct expand__e_1__lambda0* as0;
		struct convert_environ__lambda0* as1;
	};
};
struct fun_act3_3 {
	uint64_t kind;
	union {
		struct each_5__lambda0* as0;
		struct each_9__lambda0* as1;
	};
};
struct fun_act2_11 {
	uint64_t kind;
	union {
		struct fold_14__lambda0* as0;
	};
};
struct fun_act2_12 {
	uint64_t kind;
	union {
		struct fold_14__lambda0__lambda0* as0;
		struct fold_recur_15__lambda1* as1;
	};
};
struct fun_act1_20 {
	uint64_t kind;
	union {
		struct _concatEquals_6__lambda0* as0;
		struct new_inner_node_1__lambda1* as1;
	};
};
struct fun_act1_21 {
	uint64_t kind;
	union {
		struct update__e_1__lambda0* as0;
		struct no_duplicate_keys_1__lambda0* as1;
		struct get_or_update_leaf_1__lambda0* as2;
	};
};
struct fun_act2_13 {
	uint64_t kind;
	union {
		struct void_ as0;
		uint64_t __ensureSizeIs16;
	};
};
struct opt_19;
struct get_or_update_action_1;
struct fun_act1_22 {
	uint64_t kind;
	union {
		struct _tilde_5__lambda0* as0;
	};
};
struct opt_20;
struct fun_act3_4 {
	uint64_t kind;
	union {
		struct inner_node_to_leaf_1__lambda0* as0;
		struct inner_node_to_leaf_1__lambda1* as1;
	};
};
struct fun_act1_23 {
	uint64_t kind;
	union {
		struct void_ as0;
		struct void_ as1;
		uint64_t __ensureSizeIs16;
	};
};
struct fun_act1_24 {
	uint64_t kind;
	union {
		struct update_with_default_1__lambda0* as0;
		struct fill_fix_arr_4__lambda0* as1;
	};
};
struct fun_act2_14 {
	uint64_t kind;
	union {
		struct new_inner_node_1__lambda0* as0;
	};
};
struct fun_act2_15 {
	uint64_t kind;
	union {
		struct void_ as0;
		uint64_t __ensureSizeIs16;
	};
};
struct fun_act3_5 {
	uint64_t kind;
	union {
		struct map_to_arr_1__lambda0* as0;
	};
};
struct fun_act2_16 {
	uint64_t kind;
	union {
		struct fold_21__lambda0* as0;
	};
};
struct fun_act2_17 {
	uint64_t kind;
	union {
		struct fold_21__lambda0__lambda0* as0;
	};
};
struct fun_act1_25 {
	uint64_t kind;
	union {
		struct fill__e_1__lambda0* as0;
	};
};
struct result_2;
struct fun0 {
	uint64_t kind;
	union {
		struct do_test__lambda0__lambda0* as0;
		struct do_test__lambda0* as1;
		struct do_test__lambda1* as2;
	};
};
struct fun_act1_26 {
	uint64_t kind;
	union {
		struct each_child_recursive_1__lambda0* as0;
		struct list_tests__lambda0* as1;
		struct flat_map_with_max_size__lambda0* as2;
		struct list_lintable_files__lambda1* as3;
	};
};
struct opt_21 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_21 as1;
	};
};
struct fun_act2_18 {
	uint64_t kind;
	union {
		struct void_ as0;
		uint64_t __ensureSizeIs16;
	};
};
struct opt_22 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_22 as1;
	};
};
struct fun_act1_27 {
	uint64_t kind;
	union {
		struct run_crow_tests__lambda0* as0;
		struct lint__lambda0* as1;
	};
};
struct fun_act1_28 {
	uint64_t kind;
	union {
		struct _concatEquals_9__lambda0* as0;
		struct void_ as1;
	};
};
struct opt_23 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_23 as1;
	};
};
struct opt_24 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_24 as1;
	};
};
struct fun_act1_29 {
	uint64_t kind;
	union {
		struct run_single_crow_test__lambda0* as0;
	};
};
struct fun_act2_19 {
	uint64_t kind;
	union {
		struct void_ as0;
		uint64_t __ensureSizeIs16;
	};
};
struct fun_act1_30 {
	uint64_t kind;
	union {
		struct fix_arr_23__lambda0* as0;
	};
};
struct fun_act1_31 {
	uint64_t kind;
	union {
		struct void_ as0;
		uint64_t __ensureSizeIs16;
	};
};
struct fun_act1_32 {
	uint64_t kind;
	union {
		struct map_1__lambda0* as0;
	};
};
struct fun_act2_20 {
	uint64_t kind;
	union {
		struct fold_recur_15__lambda0* as0;
	};
};
struct fun_act2_21 {
	uint64_t kind;
	union {
		struct lint_file__lambda0* as0;
	};
};
struct fun_act2_22 {
	uint64_t kind;
	union {
		struct lines__lambda0* as0;
	};
};
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
struct err_0;
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
struct map_0__lambda0 {
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
struct arr_8 {
	uint64_t size;
	struct opt_12* begin_ptr;
};
struct some_13 {
	struct arr_8 value;
};
struct parsed_command;
struct dict_0;
struct inner_node_0;
struct arr_9 {
	uint64_t size;
	struct node_0* begin_ptr;
};
struct leaf_node_0 {
	struct arr_10 pairs;
};
struct arrow_0 {
	struct str from;
	struct arr_2 to;
};
struct no_duplicate_keys_0__lambda0 {
	struct str key;
};
struct get_or_update_result_0;
struct some_14;
struct some_15 {
	struct leaf_node_0 value;
};
struct inner_node_to_leaf_0__lambda0;
struct inner_node_to_leaf_0__lambda1;
struct update_with_default_0__lambda0;
struct get_or_update_leaf_0__lambda0 {
	struct str key;
};
struct fix_arr_4 {
	struct void_ ignore;
	struct arr_9 inner;
};
struct fill_fix_arr_0__lambda0;
struct new_inner_node_0__lambda1 {
	uint64_t hash_shift;
	struct fix_arr_4 res;
};
struct _tilde_2__lambda0 {
	struct arrow_0 pair;
};
struct mut_dict_0;
struct fix_arr_5;
struct arr_11 {
	uint64_t size;
	struct entry_0* begin_ptr;
};
struct some_16 {
	struct str value;
};
struct fix_arr_7__lambda0 {
	struct arr_11 a;
};
struct fill_fix_arr_1__lambda0;
struct fold_2__lambda0 {
	struct fun_act3_1 f;
};
struct fold_2__lambda0__lambda0 {
	struct fun_act3_1 f;
};
struct each_3__lambda0 {
	struct fun_act2_3 f;
};
struct update__e_0__lambda0 {
	struct str key;
};
struct fold_7__lambda0 {
	struct fun_act3_2 f;
};
struct fold_7__lambda0__lambda0 {
	struct fun_act3_2 f;
};
struct map_to_arr_0__lambda0 {
	struct fun_act2_6 f;
};
struct fill__e_0__lambda0;
struct mut_arr_3;
struct fix_arr_6 {
	struct void_ ignore;
	struct arr_8 inner;
};
struct fill_fix_arr_2__lambda0 {
	struct opt_12 value;
};
struct fold_recur_6__lambda0 {
	struct fun_act3_1 f;
};
struct fold_recur_6__lambda1 {
	struct fun_act3_1 f;
};
struct each_4__lambda0 {
	struct fun_act2_3 f;
};
struct test_options {
	uint8_t print_tests;
	uint8_t overwrite_output;
	uint64_t max_failures;
	struct str match_test;
};
struct dict_1;
struct inner_node_1;
struct arr_12 {
	uint64_t size;
	struct node_1* begin_ptr;
};
struct leaf_node_1 {
	struct arr_13 pairs;
};
struct arrow_1 {
	struct str from;
	struct str to;
};
struct mut_dict_1;
struct mut_arr_4 {
	struct fix_arr_7 backing;
	uint64_t size;
};
struct fix_arr_8;
struct arr_14 {
	uint64_t size;
	struct entry_1* begin_ptr;
};
struct fix_arr_13__lambda0 {
	struct arr_14 a;
};
struct fill_fix_arr_3__lambda0;
struct fold_14__lambda0 {
	struct fun_act3_3 f;
};
struct fold_14__lambda0__lambda0 {
	struct fun_act3_3 f;
};
struct each_5__lambda0 {
	struct fun_act2_10 f;
};
struct update__e_1__lambda0 {
	struct str key;
};
struct no_duplicate_keys_1__lambda0 {
	struct str key;
};
struct get_or_update_result_1;
struct some_19;
struct insert_1 {
	struct str value;
};
struct some_20 {
	struct leaf_node_1 value;
};
struct inner_node_to_leaf_1__lambda0;
struct inner_node_to_leaf_1__lambda1;
struct update_with_default_1__lambda0;
struct get_or_update_leaf_1__lambda0 {
	struct str key;
};
struct fix_arr_9 {
	struct void_ ignore;
	struct arr_12 inner;
};
struct fill_fix_arr_4__lambda0;
struct new_inner_node_1__lambda1 {
	uint64_t hash_shift;
	struct fix_arr_9 res;
};
struct _tilde_5__lambda0 {
	struct arrow_1 pair;
};
struct fold_21__lambda0 {
	struct fun_act3_5 f;
};
struct fold_21__lambda0__lambda0 {
	struct fun_act3_5 f;
};
struct map_to_arr_1__lambda0 {
	struct fun_act2_15 f;
};
struct fill__e_1__lambda0;
struct failure {
	struct str path;
	struct str message;
};
struct ok_2 {
	struct str value;
};
struct mut_arr_5 {
	struct fix_arr_10 backing;
	uint64_t size;
};
struct dirent;
struct bytes256 {
	struct bytes128 n0;
	struct bytes128 n1;
};
struct each_child_recursive_1__lambda0 {
	struct fun_act1_8 filter;
	struct str path;
	struct fun_act1_26 f;
};
struct list_tests__lambda0 {
	struct str match_test;
	struct mut_arr_5* res;
};
struct mut_arr_6 {
	struct fix_arr_11 backing;
	uint64_t size;
};
struct flat_map_with_max_size__lambda0 {
	struct mut_arr_6* res;
	uint64_t max_size;
	struct fun_act1_27 mapper;
};
struct run_crow_tests__lambda0;
struct run_single_crow_test__lambda0;
struct process_result {
	int32_t exit_code;
	struct str stdout;
	struct str stderr;
};
struct posix_spawn_file_actions_t {
	int32_t allocated;
	int32_t used;
	uint8_t* actions;
	struct bytes64 pad;
};
struct fix_arr_12 {
	struct void_ ignore;
	struct arr_16 inner;
};
struct map_1__lambda0 {
	struct fun_act1_31 f;
	struct arr_2 a;
};
struct mut_arr_7 {
	struct fix_arr_13 backing;
	uint64_t size;
};
struct fold_recur_15__lambda0 {
	struct fun_act3_3 f;
};
struct fold_recur_15__lambda1 {
	struct fun_act3_3 f;
};
struct each_9__lambda0 {
	struct fun_act2_10 f;
};
struct do_test__lambda0;
struct do_test__lambda0__lambda0;
struct do_test__lambda1 {
	struct str crow_path;
	struct test_options* options;
};
struct excluded_from_lint__lambda0 {
	struct str name;
};
struct lines__lambda0 {
	struct cell_0* last_nl;
	struct mut_arr_5* res;
	struct str s;
};
struct lint_file__lambda0 {
	uint8_t allow_double_space;
	struct mut_arr_6* res;
	struct str path;
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
struct opt_13 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_13 as1;
	};
};
struct node_0;
struct opt_14;
struct opt_15 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_15 as1;
	};
};
struct entry_0 {
	uint64_t kind;
	union {
		struct none as0;
		struct arrow_0 as1;
		struct mut_arr_2* as2;
	};
};
struct opt_16 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_16 as1;
	};
};
struct node_1;
struct entry_1 {
	uint64_t kind;
	union {
		struct none as0;
		struct arrow_1 as1;
		struct mut_arr_4* as2;
	};
};
struct opt_19;
struct get_or_update_action_1 {
	uint64_t kind;
	union {
		struct no_change as0;
		struct remove as1;
		struct insert_1 as2;
	};
};
struct opt_20 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_20 as1;
	};
};
struct result_2 {
	uint64_t kind;
	union {
		struct ok_2 as0;
		struct err_1 as1;
	};
};
struct fut_0;
struct exception {
	struct str message;
	struct backtrace backtrace;
};
struct err_0 {
	struct exception value;
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
struct parsed_command;
struct dict_0;
struct inner_node_0 {
	struct arr_9 children;
};
struct get_or_update_result_0;
struct some_14;
struct inner_node_to_leaf_0__lambda0;
struct inner_node_to_leaf_0__lambda1;
struct update_with_default_0__lambda0;
struct fill_fix_arr_0__lambda0;
struct mut_dict_0;
struct fix_arr_5 {
	struct void_ ignore;
	struct arr_11 inner;
};
struct fill_fix_arr_1__lambda0 {
	struct entry_0 value;
};
struct fill__e_0__lambda0 {
	struct entry_0 value;
};
struct mut_arr_3 {
	struct fix_arr_6 backing;
	uint64_t size;
};
struct dict_1;
struct inner_node_1 {
	struct arr_12 children;
};
struct mut_dict_1;
struct fix_arr_8 {
	struct void_ ignore;
	struct arr_14 inner;
};
struct fill_fix_arr_3__lambda0 {
	struct entry_1 value;
};
struct get_or_update_result_1;
struct some_19;
struct inner_node_to_leaf_1__lambda0;
struct inner_node_to_leaf_1__lambda1;
struct update_with_default_1__lambda0;
struct fill_fix_arr_4__lambda0;
struct fill__e_1__lambda0 {
	struct entry_1 value;
};
struct dirent {
	uint64_t d_ino;
	int64_t d_off;
	uint16_t d_reclen;
	char d_type;
	struct bytes256 d_name;
};
struct run_crow_tests__lambda0;
struct run_single_crow_test__lambda0;
struct do_test__lambda0;
struct do_test__lambda0__lambda0;
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
		struct err_0 as1;
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
		struct err_0 as1;
	};
};
struct choose_task_result {
	uint64_t kind;
	union {
		struct chosen_task as0;
		struct no_chosen_task as1;
	};
};
struct node_0 {
	uint64_t kind;
	union {
		struct inner_node_0 as0;
		struct leaf_node_0 as1;
	};
};
struct opt_14;
struct node_1 {
	uint64_t kind;
	union {
		struct inner_node_1 as0;
		struct leaf_node_1 as1;
	};
};
struct opt_19;
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
struct parsed_command;
struct dict_0 {
	struct void_ ignore;
	struct node_0 root;
};
struct get_or_update_result_0;
struct some_14 {
	struct node_0 value;
};
struct inner_node_to_leaf_0__lambda0 {
	uint64_t which;
	struct node_0 new_child;
};
struct inner_node_to_leaf_0__lambda1 {
	uint64_t which;
	struct node_0 new_child;
	struct fix_arr_3 out;
};
struct update_with_default_0__lambda0 {
	struct arr_9 a;
	uint64_t index;
	struct node_0 new_value;
	struct node_0 _default;
};
struct fill_fix_arr_0__lambda0 {
	struct node_0 value;
};
struct mut_dict_0 {
	struct void_ ignore;
	struct fix_arr_5 entries;
	uint64_t total_size;
};
struct dict_1 {
	struct void_ ignore;
	struct node_1 root;
};
struct mut_dict_1 {
	struct void_ ignore;
	struct fix_arr_8 entries;
	uint64_t total_size;
};
struct get_or_update_result_1;
struct some_19 {
	struct node_1 value;
};
struct inner_node_to_leaf_1__lambda0 {
	uint64_t which;
	struct node_1 new_child;
};
struct inner_node_to_leaf_1__lambda1 {
	uint64_t which;
	struct node_1 new_child;
	struct fix_arr_7 out;
};
struct update_with_default_1__lambda0 {
	struct arr_12 a;
	uint64_t index;
	struct node_1 new_value;
	struct node_1 _default;
};
struct fill_fix_arr_4__lambda0 {
	struct node_1 value;
};
struct run_crow_tests__lambda0 {
	struct str path_to_crow;
	struct dict_1 env;
	struct test_options* options;
};
struct run_single_crow_test__lambda0 {
	struct test_options* options;
	struct str path;
	struct str path_to_crow;
	struct dict_1 env;
};
struct do_test__lambda0 {
	struct str test_path;
	struct str crow_exe;
	struct dict_1 env;
	struct test_options* options;
};
struct do_test__lambda0__lambda0 {
	struct str test_path;
	struct str crow_exe;
	struct dict_1 env;
	struct test_options* options;
};
struct opt_14 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_14 as1;
	};
};
struct opt_19 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_19 as1;
	};
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
struct parsed_command {
	struct arr_2 nameless;
	struct dict_0 named;
	struct arr_2 after;
};
struct get_or_update_result_0 {
	struct opt_14 new_node;
	struct opt_12 old_value;
};
struct get_or_update_result_1 {
	struct opt_19 new_node;
	struct opt_16 old_value;
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
_Static_assert(sizeof(struct less) == 0, "");
_Static_assert(_Alignof(struct less) == 1, "");
_Static_assert(sizeof(struct equal) == 0, "");
_Static_assert(_Alignof(struct equal) == 1, "");
_Static_assert(sizeof(struct greater) == 0, "");
_Static_assert(_Alignof(struct greater) == 1, "");
_Static_assert(sizeof(struct fut_0) == 48, "");
_Static_assert(_Alignof(struct fut_0) == 8, "");
_Static_assert(sizeof(struct fut_state_no_callbacks) == 0, "");
_Static_assert(_Alignof(struct fut_state_no_callbacks) == 1, "");
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
_Static_assert(sizeof(struct ok_0) == 8, "");
_Static_assert(_Alignof(struct ok_0) == 8, "");
_Static_assert(sizeof(struct err_0) == 32, "");
_Static_assert(_Alignof(struct err_0) == 8, "");
_Static_assert(sizeof(struct none) == 0, "");
_Static_assert(_Alignof(struct none) == 1, "");
_Static_assert(sizeof(struct some_0) == 8, "");
_Static_assert(_Alignof(struct some_0) == 8, "");
_Static_assert(sizeof(struct fut_state_resolved_0) == 8, "");
_Static_assert(_Alignof(struct fut_state_resolved_0) == 8, "");
_Static_assert(sizeof(struct arr_2) == 16, "");
_Static_assert(_Alignof(struct arr_2) == 8, "");
_Static_assert(sizeof(struct global_ctx) == 168, "");
_Static_assert(_Alignof(struct global_ctx) == 8, "");
_Static_assert(sizeof(struct dynamic_sym_node) == 24, "");
_Static_assert(_Alignof(struct dynamic_sym_node) == 8, "");
_Static_assert(sizeof(struct some_1) == 8, "");
_Static_assert(_Alignof(struct some_1) == 8, "");
_Static_assert(sizeof(struct island) == 216, "");
_Static_assert(_Alignof(struct island) == 8, "");
_Static_assert(sizeof(struct gc) == 96, "");
_Static_assert(_Alignof(struct gc) == 8, "");
_Static_assert(sizeof(struct gc_ctx) == 24, "");
_Static_assert(_Alignof(struct gc_ctx) == 8, "");
_Static_assert(sizeof(struct some_2) == 8, "");
_Static_assert(_Alignof(struct some_2) == 8, "");
_Static_assert(sizeof(struct island_gc_root) == 72, "");
_Static_assert(_Alignof(struct island_gc_root) == 8, "");
_Static_assert(sizeof(struct task_queue) == 40, "");
_Static_assert(_Alignof(struct task_queue) == 8, "");
_Static_assert(sizeof(struct task_queue_node) == 48, "");
_Static_assert(_Alignof(struct task_queue_node) == 8, "");
_Static_assert(sizeof(struct task) == 32, "");
_Static_assert(_Alignof(struct task) == 8, "");
_Static_assert(sizeof(struct some_3) == 8, "");
_Static_assert(_Alignof(struct some_3) == 8, "");
_Static_assert(sizeof(struct mut_arr_0) == 24, "");
_Static_assert(_Alignof(struct mut_arr_0) == 8, "");
_Static_assert(sizeof(struct fix_arr_0) == 16, "");
_Static_assert(_Alignof(struct fix_arr_0) == 8, "");
_Static_assert(sizeof(struct arr_3) == 16, "");
_Static_assert(_Alignof(struct arr_3) == 8, "");
_Static_assert(sizeof(struct logged) == 24, "");
_Static_assert(_Alignof(struct logged) == 8, "");
_Static_assert(sizeof(struct info) == 0, "");
_Static_assert(_Alignof(struct info) == 1, "");
_Static_assert(sizeof(struct warn) == 0, "");
_Static_assert(_Alignof(struct warn) == 1, "");
_Static_assert(sizeof(struct error) == 0, "");
_Static_assert(_Alignof(struct error) == 1, "");
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
_Static_assert(sizeof(struct some_4) == 8, "");
_Static_assert(_Alignof(struct some_4) == 8, "");
_Static_assert(sizeof(struct some_5) == 8, "");
_Static_assert(_Alignof(struct some_5) == 8, "");
_Static_assert(sizeof(struct some_6) == 8, "");
_Static_assert(_Alignof(struct some_6) == 8, "");
_Static_assert(sizeof(struct some_7) == 8, "");
_Static_assert(_Alignof(struct some_7) == 8, "");
_Static_assert(sizeof(struct some_8) == 8, "");
_Static_assert(_Alignof(struct some_8) == 8, "");
_Static_assert(sizeof(struct arr_5) == 16, "");
_Static_assert(_Alignof(struct arr_5) == 8, "");
_Static_assert(sizeof(struct range) == 16, "");
_Static_assert(_Alignof(struct range) == 8, "");
_Static_assert(sizeof(struct to_str_0__lambda0) == 8, "");
_Static_assert(_Alignof(struct to_str_0__lambda0) == 8, "");
_Static_assert(sizeof(struct some_9) == 8, "");
_Static_assert(_Alignof(struct some_9) == 8, "");
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
_Static_assert(sizeof(struct ok_1) == 0, "");
_Static_assert(_Alignof(struct ok_1) == 1, "");
_Static_assert(sizeof(struct some_10) == 8, "");
_Static_assert(_Alignof(struct some_10) == 8, "");
_Static_assert(sizeof(struct fut_state_resolved_1) == 0, "");
_Static_assert(_Alignof(struct fut_state_resolved_1) == 1, "");
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
_Static_assert(sizeof(struct map_0__lambda0) == 32, "");
_Static_assert(_Alignof(struct map_0__lambda0) == 8, "");
_Static_assert(sizeof(struct thread_args) == 16, "");
_Static_assert(_Alignof(struct thread_args) == 8, "");
_Static_assert(sizeof(struct cell_0) == 8, "");
_Static_assert(_Alignof(struct cell_0) == 8, "");
_Static_assert(sizeof(struct chosen_task) == 48, "");
_Static_assert(_Alignof(struct chosen_task) == 8, "");
_Static_assert(sizeof(struct do_a_gc) == 0, "");
_Static_assert(_Alignof(struct do_a_gc) == 1, "");
_Static_assert(sizeof(struct no_chosen_task) == 24, "");
_Static_assert(_Alignof(struct no_chosen_task) == 8, "");
_Static_assert(sizeof(struct some_11) == 8, "");
_Static_assert(_Alignof(struct some_11) == 8, "");
_Static_assert(sizeof(struct timespec) == 16, "");
_Static_assert(_Alignof(struct timespec) == 8, "");
_Static_assert(sizeof(struct cell_1) == 16, "");
_Static_assert(_Alignof(struct cell_1) == 8, "");
_Static_assert(sizeof(struct no_task) == 24, "");
_Static_assert(_Alignof(struct no_task) == 8, "");
_Static_assert(sizeof(struct cell_2) == 8, "");
_Static_assert(_Alignof(struct cell_2) == 8, "");
_Static_assert(sizeof(struct some_12) == 16, "");
_Static_assert(_Alignof(struct some_12) == 8, "");
_Static_assert(sizeof(struct arr_8) == 16, "");
_Static_assert(_Alignof(struct arr_8) == 8, "");
_Static_assert(sizeof(struct some_13) == 16, "");
_Static_assert(_Alignof(struct some_13) == 8, "");
_Static_assert(sizeof(struct parsed_command) == 56, "");
_Static_assert(_Alignof(struct parsed_command) == 8, "");
_Static_assert(sizeof(struct dict_0) == 24, "");
_Static_assert(_Alignof(struct dict_0) == 8, "");
_Static_assert(sizeof(struct inner_node_0) == 16, "");
_Static_assert(_Alignof(struct inner_node_0) == 8, "");
_Static_assert(sizeof(struct arr_9) == 16, "");
_Static_assert(_Alignof(struct arr_9) == 8, "");
_Static_assert(sizeof(struct leaf_node_0) == 16, "");
_Static_assert(_Alignof(struct leaf_node_0) == 8, "");
_Static_assert(sizeof(struct arrow_0) == 32, "");
_Static_assert(_Alignof(struct arrow_0) == 8, "");
_Static_assert(sizeof(struct arr_10) == 16, "");
_Static_assert(_Alignof(struct arr_10) == 8, "");
_Static_assert(sizeof(struct hasher) == 8, "");
_Static_assert(_Alignof(struct hasher) == 8, "");
_Static_assert(sizeof(struct hash_mix_0__lambda0) == 8, "");
_Static_assert(_Alignof(struct hash_mix_0__lambda0) == 8, "");
_Static_assert(sizeof(struct no_duplicate_keys_0__lambda0) == 16, "");
_Static_assert(_Alignof(struct no_duplicate_keys_0__lambda0) == 8, "");
_Static_assert(sizeof(struct get_or_update_result_0) == 56, "");
_Static_assert(_Alignof(struct get_or_update_result_0) == 8, "");
_Static_assert(sizeof(struct some_14) == 24, "");
_Static_assert(_Alignof(struct some_14) == 8, "");
_Static_assert(sizeof(struct no_change) == 0, "");
_Static_assert(_Alignof(struct no_change) == 1, "");
_Static_assert(sizeof(struct remove) == 0, "");
_Static_assert(_Alignof(struct remove) == 1, "");
_Static_assert(sizeof(struct insert_0) == 16, "");
_Static_assert(_Alignof(struct insert_0) == 8, "");
_Static_assert(sizeof(struct some_15) == 16, "");
_Static_assert(_Alignof(struct some_15) == 8, "");
_Static_assert(sizeof(struct inner_node_to_leaf_0__lambda0) == 32, "");
_Static_assert(_Alignof(struct inner_node_to_leaf_0__lambda0) == 8, "");
_Static_assert(sizeof(struct fix_arr_3) == 16, "");
_Static_assert(_Alignof(struct fix_arr_3) == 8, "");
_Static_assert(sizeof(struct inner_node_to_leaf_0__lambda1) == 48, "");
_Static_assert(_Alignof(struct inner_node_to_leaf_0__lambda1) == 8, "");
_Static_assert(sizeof(struct update_with_default_0__lambda0) == 72, "");
_Static_assert(_Alignof(struct update_with_default_0__lambda0) == 8, "");
_Static_assert(sizeof(struct get_or_update_leaf_0__lambda0) == 16, "");
_Static_assert(_Alignof(struct get_or_update_leaf_0__lambda0) == 8, "");
_Static_assert(sizeof(struct new_inner_node_0__lambda0) == 8, "");
_Static_assert(_Alignof(struct new_inner_node_0__lambda0) == 8, "");
_Static_assert(sizeof(struct fix_arr_4) == 16, "");
_Static_assert(_Alignof(struct fix_arr_4) == 8, "");
_Static_assert(sizeof(struct fill_fix_arr_0__lambda0) == 24, "");
_Static_assert(_Alignof(struct fill_fix_arr_0__lambda0) == 8, "");
_Static_assert(sizeof(struct new_inner_node_0__lambda1) == 24, "");
_Static_assert(_Alignof(struct new_inner_node_0__lambda1) == 8, "");
_Static_assert(sizeof(struct _tilde_2__lambda0) == 32, "");
_Static_assert(_Alignof(struct _tilde_2__lambda0) == 8, "");
_Static_assert(sizeof(struct mut_dict_0) == 24, "");
_Static_assert(_Alignof(struct mut_dict_0) == 8, "");
_Static_assert(sizeof(struct mut_arr_2) == 24, "");
_Static_assert(_Alignof(struct mut_arr_2) == 8, "");
_Static_assert(sizeof(struct fix_arr_5) == 16, "");
_Static_assert(_Alignof(struct fix_arr_5) == 8, "");
_Static_assert(sizeof(struct arr_11) == 16, "");
_Static_assert(_Alignof(struct arr_11) == 8, "");
_Static_assert(sizeof(struct some_16) == 16, "");
_Static_assert(_Alignof(struct some_16) == 8, "");
_Static_assert(sizeof(struct some_17) == 16, "");
_Static_assert(_Alignof(struct some_17) == 8, "");
_Static_assert(sizeof(struct fix_arr_7__lambda0) == 16, "");
_Static_assert(_Alignof(struct fix_arr_7__lambda0) == 8, "");
_Static_assert(sizeof(struct fill_fix_arr_1__lambda0) == 40, "");
_Static_assert(_Alignof(struct fill_fix_arr_1__lambda0) == 8, "");
_Static_assert(sizeof(struct fold_2__lambda0) == 16, "");
_Static_assert(_Alignof(struct fold_2__lambda0) == 8, "");
_Static_assert(sizeof(struct fold_2__lambda0__lambda0) == 16, "");
_Static_assert(_Alignof(struct fold_2__lambda0__lambda0) == 8, "");
_Static_assert(sizeof(struct each_3__lambda0) == 16, "");
_Static_assert(_Alignof(struct each_3__lambda0) == 8, "");
_Static_assert(sizeof(struct expand__e_0__lambda0) == 8, "");
_Static_assert(_Alignof(struct expand__e_0__lambda0) == 8, "");
_Static_assert(sizeof(struct _concatEquals_4__lambda0) == 8, "");
_Static_assert(_Alignof(struct _concatEquals_4__lambda0) == 8, "");
_Static_assert(sizeof(struct update__e_0__lambda0) == 16, "");
_Static_assert(_Alignof(struct update__e_0__lambda0) == 8, "");
_Static_assert(sizeof(struct fold_7__lambda0) == 16, "");
_Static_assert(_Alignof(struct fold_7__lambda0) == 8, "");
_Static_assert(sizeof(struct fold_7__lambda0__lambda0) == 16, "");
_Static_assert(_Alignof(struct fold_7__lambda0__lambda0) == 8, "");
_Static_assert(sizeof(struct map_to_arr_0__lambda0) == 16, "");
_Static_assert(_Alignof(struct map_to_arr_0__lambda0) == 8, "");
_Static_assert(sizeof(struct fill__e_0__lambda0) == 40, "");
_Static_assert(_Alignof(struct fill__e_0__lambda0) == 8, "");
_Static_assert(sizeof(struct mut_arr_3) == 24, "");
_Static_assert(_Alignof(struct mut_arr_3) == 8, "");
_Static_assert(sizeof(struct fix_arr_6) == 16, "");
_Static_assert(_Alignof(struct fix_arr_6) == 8, "");
_Static_assert(sizeof(struct fill_fix_arr_2__lambda0) == 24, "");
_Static_assert(_Alignof(struct fill_fix_arr_2__lambda0) == 8, "");
_Static_assert(sizeof(struct cell_3) == 1, "");
_Static_assert(_Alignof(struct cell_3) == 1, "");
_Static_assert(sizeof(struct fold_recur_6__lambda0) == 16, "");
_Static_assert(_Alignof(struct fold_recur_6__lambda0) == 8, "");
_Static_assert(sizeof(struct fold_recur_6__lambda1) == 16, "");
_Static_assert(_Alignof(struct fold_recur_6__lambda1) == 8, "");
_Static_assert(sizeof(struct each_4__lambda0) == 16, "");
_Static_assert(_Alignof(struct each_4__lambda0) == 8, "");
_Static_assert(sizeof(struct parse_named_args_0__lambda0) == 32, "");
_Static_assert(_Alignof(struct parse_named_args_0__lambda0) == 8, "");
_Static_assert(sizeof(struct some_18) == 8, "");
_Static_assert(_Alignof(struct some_18) == 8, "");
_Static_assert(sizeof(struct interp) == 8, "");
_Static_assert(_Alignof(struct interp) == 8, "");
_Static_assert(sizeof(struct reader) == 16, "");
_Static_assert(_Alignof(struct reader) == 8, "");
_Static_assert(sizeof(struct test_options) == 32, "");
_Static_assert(_Alignof(struct test_options) == 8, "");
_Static_assert(sizeof(struct r_index_of__lambda0) == 1, "");
_Static_assert(_Alignof(struct r_index_of__lambda0) == 1, "");
_Static_assert(sizeof(struct dict_1) == 24, "");
_Static_assert(_Alignof(struct dict_1) == 8, "");
_Static_assert(sizeof(struct inner_node_1) == 16, "");
_Static_assert(_Alignof(struct inner_node_1) == 8, "");
_Static_assert(sizeof(struct arr_12) == 16, "");
_Static_assert(_Alignof(struct arr_12) == 8, "");
_Static_assert(sizeof(struct leaf_node_1) == 16, "");
_Static_assert(_Alignof(struct leaf_node_1) == 8, "");
_Static_assert(sizeof(struct arrow_1) == 32, "");
_Static_assert(_Alignof(struct arrow_1) == 8, "");
_Static_assert(sizeof(struct arr_13) == 16, "");
_Static_assert(_Alignof(struct arr_13) == 8, "");
_Static_assert(sizeof(struct mut_dict_1) == 24, "");
_Static_assert(_Alignof(struct mut_dict_1) == 8, "");
_Static_assert(sizeof(struct mut_arr_4) == 24, "");
_Static_assert(_Alignof(struct mut_arr_4) == 8, "");
_Static_assert(sizeof(struct fix_arr_7) == 16, "");
_Static_assert(_Alignof(struct fix_arr_7) == 8, "");
_Static_assert(sizeof(struct fix_arr_8) == 16, "");
_Static_assert(_Alignof(struct fix_arr_8) == 8, "");
_Static_assert(sizeof(struct arr_14) == 16, "");
_Static_assert(_Alignof(struct arr_14) == 8, "");
_Static_assert(sizeof(struct fix_arr_13__lambda0) == 16, "");
_Static_assert(_Alignof(struct fix_arr_13__lambda0) == 8, "");
_Static_assert(sizeof(struct fill_fix_arr_3__lambda0) == 40, "");
_Static_assert(_Alignof(struct fill_fix_arr_3__lambda0) == 8, "");
_Static_assert(sizeof(struct fold_14__lambda0) == 16, "");
_Static_assert(_Alignof(struct fold_14__lambda0) == 8, "");
_Static_assert(sizeof(struct fold_14__lambda0__lambda0) == 16, "");
_Static_assert(_Alignof(struct fold_14__lambda0__lambda0) == 8, "");
_Static_assert(sizeof(struct each_5__lambda0) == 16, "");
_Static_assert(_Alignof(struct each_5__lambda0) == 8, "");
_Static_assert(sizeof(struct expand__e_1__lambda0) == 8, "");
_Static_assert(_Alignof(struct expand__e_1__lambda0) == 8, "");
_Static_assert(sizeof(struct _concatEquals_6__lambda0) == 8, "");
_Static_assert(_Alignof(struct _concatEquals_6__lambda0) == 8, "");
_Static_assert(sizeof(struct update__e_1__lambda0) == 16, "");
_Static_assert(_Alignof(struct update__e_1__lambda0) == 8, "");
_Static_assert(sizeof(struct no_duplicate_keys_1__lambda0) == 16, "");
_Static_assert(_Alignof(struct no_duplicate_keys_1__lambda0) == 8, "");
_Static_assert(sizeof(struct get_or_update_result_1) == 56, "");
_Static_assert(_Alignof(struct get_or_update_result_1) == 8, "");
_Static_assert(sizeof(struct some_19) == 24, "");
_Static_assert(_Alignof(struct some_19) == 8, "");
_Static_assert(sizeof(struct insert_1) == 16, "");
_Static_assert(_Alignof(struct insert_1) == 8, "");
_Static_assert(sizeof(struct some_20) == 16, "");
_Static_assert(_Alignof(struct some_20) == 8, "");
_Static_assert(sizeof(struct inner_node_to_leaf_1__lambda0) == 32, "");
_Static_assert(_Alignof(struct inner_node_to_leaf_1__lambda0) == 8, "");
_Static_assert(sizeof(struct inner_node_to_leaf_1__lambda1) == 48, "");
_Static_assert(_Alignof(struct inner_node_to_leaf_1__lambda1) == 8, "");
_Static_assert(sizeof(struct update_with_default_1__lambda0) == 72, "");
_Static_assert(_Alignof(struct update_with_default_1__lambda0) == 8, "");
_Static_assert(sizeof(struct get_or_update_leaf_1__lambda0) == 16, "");
_Static_assert(_Alignof(struct get_or_update_leaf_1__lambda0) == 8, "");
_Static_assert(sizeof(struct new_inner_node_1__lambda0) == 8, "");
_Static_assert(_Alignof(struct new_inner_node_1__lambda0) == 8, "");
_Static_assert(sizeof(struct fix_arr_9) == 16, "");
_Static_assert(_Alignof(struct fix_arr_9) == 8, "");
_Static_assert(sizeof(struct fill_fix_arr_4__lambda0) == 24, "");
_Static_assert(_Alignof(struct fill_fix_arr_4__lambda0) == 8, "");
_Static_assert(sizeof(struct new_inner_node_1__lambda1) == 24, "");
_Static_assert(_Alignof(struct new_inner_node_1__lambda1) == 8, "");
_Static_assert(sizeof(struct _tilde_5__lambda0) == 32, "");
_Static_assert(_Alignof(struct _tilde_5__lambda0) == 8, "");
_Static_assert(sizeof(struct fold_21__lambda0) == 16, "");
_Static_assert(_Alignof(struct fold_21__lambda0) == 8, "");
_Static_assert(sizeof(struct fold_21__lambda0__lambda0) == 16, "");
_Static_assert(_Alignof(struct fold_21__lambda0__lambda0) == 8, "");
_Static_assert(sizeof(struct map_to_arr_1__lambda0) == 16, "");
_Static_assert(_Alignof(struct map_to_arr_1__lambda0) == 8, "");
_Static_assert(sizeof(struct fill__e_1__lambda0) == 40, "");
_Static_assert(_Alignof(struct fill__e_1__lambda0) == 8, "");
_Static_assert(sizeof(struct failure) == 32, "");
_Static_assert(_Alignof(struct failure) == 8, "");
_Static_assert(sizeof(struct arr_15) == 16, "");
_Static_assert(_Alignof(struct arr_15) == 8, "");
_Static_assert(sizeof(struct ok_2) == 16, "");
_Static_assert(_Alignof(struct ok_2) == 8, "");
_Static_assert(sizeof(struct err_1) == 16, "");
_Static_assert(_Alignof(struct err_1) == 8, "");
_Static_assert(sizeof(struct mut_arr_5) == 24, "");
_Static_assert(_Alignof(struct mut_arr_5) == 8, "");
_Static_assert(sizeof(struct fix_arr_10) == 16, "");
_Static_assert(_Alignof(struct fix_arr_10) == 8, "");
_Static_assert(sizeof(struct stat) == 152, "");
_Static_assert(_Alignof(struct stat) == 8, "");
_Static_assert(sizeof(struct some_21) == 8, "");
_Static_assert(_Alignof(struct some_21) == 8, "");
_Static_assert(sizeof(struct dirent) == 280, "");
_Static_assert(_Alignof(struct dirent) == 8, "");
_Static_assert(sizeof(struct bytes256) == 256, "");
_Static_assert(_Alignof(struct bytes256) == 8, "");
_Static_assert(sizeof(struct cell_4) == 8, "");
_Static_assert(_Alignof(struct cell_4) == 8, "");
_Static_assert(sizeof(struct fix_arr_20__lambda0) == 16, "");
_Static_assert(_Alignof(struct fix_arr_20__lambda0) == 8, "");
_Static_assert(sizeof(struct each_child_recursive_1__lambda0) == 48, "");
_Static_assert(_Alignof(struct each_child_recursive_1__lambda0) == 8, "");
_Static_assert(sizeof(struct list_tests__lambda0) == 24, "");
_Static_assert(_Alignof(struct list_tests__lambda0) == 8, "");
_Static_assert(sizeof(struct some_22) == 1, "");
_Static_assert(_Alignof(struct some_22) == 1, "");
_Static_assert(sizeof(struct mut_arr_6) == 24, "");
_Static_assert(_Alignof(struct mut_arr_6) == 8, "");
_Static_assert(sizeof(struct fix_arr_11) == 16, "");
_Static_assert(_Alignof(struct fix_arr_11) == 8, "");
_Static_assert(sizeof(struct flat_map_with_max_size__lambda0) == 32, "");
_Static_assert(_Alignof(struct flat_map_with_max_size__lambda0) == 8, "");
_Static_assert(sizeof(struct _concatEquals_9__lambda0) == 8, "");
_Static_assert(_Alignof(struct _concatEquals_9__lambda0) == 8, "");
_Static_assert(sizeof(struct some_23) == 8, "");
_Static_assert(_Alignof(struct some_23) == 8, "");
_Static_assert(sizeof(struct run_crow_tests__lambda0) == 48, "");
_Static_assert(_Alignof(struct run_crow_tests__lambda0) == 8, "");
_Static_assert(sizeof(struct some_24) == 16, "");
_Static_assert(_Alignof(struct some_24) == 8, "");
_Static_assert(sizeof(struct run_single_crow_test__lambda0) == 64, "");
_Static_assert(_Alignof(struct run_single_crow_test__lambda0) == 8, "");
_Static_assert(sizeof(struct print_test_result) == 24, "");
_Static_assert(_Alignof(struct print_test_result) == 8, "");
_Static_assert(sizeof(struct process_result) == 40, "");
_Static_assert(_Alignof(struct process_result) == 8, "");
_Static_assert(sizeof(struct pipes) == 8, "");
_Static_assert(_Alignof(struct pipes) == 4, "");
_Static_assert(sizeof(struct posix_spawn_file_actions_t) == 80, "");
_Static_assert(_Alignof(struct posix_spawn_file_actions_t) == 8, "");
_Static_assert(sizeof(struct cell_5) == 4, "");
_Static_assert(_Alignof(struct cell_5) == 4, "");
_Static_assert(sizeof(struct pollfd) == 8, "");
_Static_assert(_Alignof(struct pollfd) == 4, "");
_Static_assert(sizeof(struct fix_arr_12) == 16, "");
_Static_assert(_Alignof(struct fix_arr_12) == 8, "");
_Static_assert(sizeof(struct arr_16) == 16, "");
_Static_assert(_Alignof(struct arr_16) == 8, "");
_Static_assert(sizeof(struct fix_arr_23__lambda0) == 16, "");
_Static_assert(_Alignof(struct fix_arr_23__lambda0) == 8, "");
_Static_assert(sizeof(struct handle_revents_result) == 2, "");
_Static_assert(_Alignof(struct handle_revents_result) == 1, "");
_Static_assert(sizeof(struct map_1__lambda0) == 32, "");
_Static_assert(_Alignof(struct map_1__lambda0) == 8, "");
_Static_assert(sizeof(struct mut_arr_7) == 24, "");
_Static_assert(_Alignof(struct mut_arr_7) == 8, "");
_Static_assert(sizeof(struct fix_arr_13) == 16, "");
_Static_assert(_Alignof(struct fix_arr_13) == 8, "");
_Static_assert(sizeof(struct fold_recur_15__lambda0) == 16, "");
_Static_assert(_Alignof(struct fold_recur_15__lambda0) == 8, "");
_Static_assert(sizeof(struct fold_recur_15__lambda1) == 16, "");
_Static_assert(_Alignof(struct fold_recur_15__lambda1) == 8, "");
_Static_assert(sizeof(struct each_9__lambda0) == 16, "");
_Static_assert(_Alignof(struct each_9__lambda0) == 8, "");
_Static_assert(sizeof(struct convert_environ__lambda0) == 8, "");
_Static_assert(_Alignof(struct convert_environ__lambda0) == 8, "");
_Static_assert(sizeof(struct do_test__lambda0) == 64, "");
_Static_assert(_Alignof(struct do_test__lambda0) == 8, "");
_Static_assert(sizeof(struct do_test__lambda0__lambda0) == 64, "");
_Static_assert(_Alignof(struct do_test__lambda0__lambda0) == 8, "");
_Static_assert(sizeof(struct do_test__lambda1) == 24, "");
_Static_assert(_Alignof(struct do_test__lambda1) == 8, "");
_Static_assert(sizeof(struct excluded_from_lint__lambda0) == 16, "");
_Static_assert(_Alignof(struct excluded_from_lint__lambda0) == 8, "");
_Static_assert(sizeof(struct list_lintable_files__lambda1) == 8, "");
_Static_assert(_Alignof(struct list_lintable_files__lambda1) == 8, "");
_Static_assert(sizeof(struct lint__lambda0) == 8, "");
_Static_assert(_Alignof(struct lint__lambda0) == 8, "");
_Static_assert(sizeof(struct lines__lambda0) == 32, "");
_Static_assert(_Alignof(struct lines__lambda0) == 8, "");
_Static_assert(sizeof(struct lint_file__lambda0) == 32, "");
_Static_assert(_Alignof(struct lint_file__lambda0) == 8, "");
_Static_assert(sizeof(struct comparison) == 8, "");
_Static_assert(_Alignof(struct comparison) == 8, "");
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
_Static_assert(sizeof(struct log_level) == 8, "");
_Static_assert(_Alignof(struct log_level) == 8, "");
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
_Static_assert(sizeof(struct fun_act2_0) == 16, "");
_Static_assert(_Alignof(struct fun_act2_0) == 8, "");
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
_Static_assert(sizeof(struct opt_12) == 24, "");
_Static_assert(_Alignof(struct opt_12) == 8, "");
_Static_assert(sizeof(struct opt_13) == 24, "");
_Static_assert(_Alignof(struct opt_13) == 8, "");
_Static_assert(sizeof(struct node_0) == 24, "");
_Static_assert(_Alignof(struct node_0) == 8, "");
_Static_assert(sizeof(struct fun_act1_8) == 16, "");
_Static_assert(_Alignof(struct fun_act1_8) == 8, "");
_Static_assert(sizeof(struct fun_act1_9) == 16, "");
_Static_assert(_Alignof(struct fun_act1_9) == 8, "");
_Static_assert(sizeof(struct fun_act2_1) == 16, "");
_Static_assert(_Alignof(struct fun_act2_1) == 8, "");
_Static_assert(sizeof(struct opt_14) == 32, "");
_Static_assert(_Alignof(struct opt_14) == 8, "");
_Static_assert(sizeof(struct get_or_update_action_0) == 24, "");
_Static_assert(_Alignof(struct get_or_update_action_0) == 8, "");
_Static_assert(sizeof(struct fun_act1_10) == 16, "");
_Static_assert(_Alignof(struct fun_act1_10) == 8, "");
_Static_assert(sizeof(struct opt_15) == 24, "");
_Static_assert(_Alignof(struct opt_15) == 8, "");
_Static_assert(sizeof(struct fun_act3_0) == 16, "");
_Static_assert(_Alignof(struct fun_act3_0) == 8, "");
_Static_assert(sizeof(struct fun_act1_11) == 16, "");
_Static_assert(_Alignof(struct fun_act1_11) == 8, "");
_Static_assert(sizeof(struct fun_act1_12) == 16, "");
_Static_assert(_Alignof(struct fun_act1_12) == 8, "");
_Static_assert(sizeof(struct fun_act2_2) == 16, "");
_Static_assert(_Alignof(struct fun_act2_2) == 8, "");
_Static_assert(sizeof(struct fun_act1_13) == 16, "");
_Static_assert(_Alignof(struct fun_act1_13) == 8, "");
_Static_assert(sizeof(struct entry_0) == 40, "");
_Static_assert(_Alignof(struct entry_0) == 8, "");
_Static_assert(sizeof(struct opt_16) == 24, "");
_Static_assert(_Alignof(struct opt_16) == 8, "");
_Static_assert(sizeof(struct opt_17) == 24, "");
_Static_assert(_Alignof(struct opt_17) == 8, "");
_Static_assert(sizeof(struct fun_act1_14) == 16, "");
_Static_assert(_Alignof(struct fun_act1_14) == 8, "");
_Static_assert(sizeof(struct fun_act2_3) == 16, "");
_Static_assert(_Alignof(struct fun_act2_3) == 8, "");
_Static_assert(sizeof(struct fun_act3_1) == 16, "");
_Static_assert(_Alignof(struct fun_act3_1) == 8, "");
_Static_assert(sizeof(struct fun_act2_4) == 16, "");
_Static_assert(_Alignof(struct fun_act2_4) == 8, "");
_Static_assert(sizeof(struct fun_act2_5) == 16, "");
_Static_assert(_Alignof(struct fun_act2_5) == 8, "");
_Static_assert(sizeof(struct fun_act2_6) == 16, "");
_Static_assert(_Alignof(struct fun_act2_6) == 8, "");
_Static_assert(sizeof(struct fun_act3_2) == 16, "");
_Static_assert(_Alignof(struct fun_act3_2) == 8, "");
_Static_assert(sizeof(struct fun_act2_7) == 16, "");
_Static_assert(_Alignof(struct fun_act2_7) == 8, "");
_Static_assert(sizeof(struct fun_act2_8) == 16, "");
_Static_assert(_Alignof(struct fun_act2_8) == 8, "");
_Static_assert(sizeof(struct fun_act1_15) == 16, "");
_Static_assert(_Alignof(struct fun_act1_15) == 8, "");
_Static_assert(sizeof(struct fun_act1_16) == 16, "");
_Static_assert(_Alignof(struct fun_act1_16) == 8, "");
_Static_assert(sizeof(struct fun_act2_9) == 16, "");
_Static_assert(_Alignof(struct fun_act2_9) == 8, "");
_Static_assert(sizeof(struct opt_18) == 16, "");
_Static_assert(_Alignof(struct opt_18) == 8, "");
_Static_assert(sizeof(struct fun_act1_17) == 16, "");
_Static_assert(_Alignof(struct fun_act1_17) == 8, "");
_Static_assert(sizeof(struct fun_act1_18) == 16, "");
_Static_assert(_Alignof(struct fun_act1_18) == 8, "");
_Static_assert(sizeof(struct node_1) == 24, "");
_Static_assert(_Alignof(struct node_1) == 8, "");
_Static_assert(sizeof(struct entry_1) == 40, "");
_Static_assert(_Alignof(struct entry_1) == 8, "");
_Static_assert(sizeof(struct fun_act1_19) == 16, "");
_Static_assert(_Alignof(struct fun_act1_19) == 8, "");
_Static_assert(sizeof(struct fun_act2_10) == 16, "");
_Static_assert(_Alignof(struct fun_act2_10) == 8, "");
_Static_assert(sizeof(struct fun_act3_3) == 16, "");
_Static_assert(_Alignof(struct fun_act3_3) == 8, "");
_Static_assert(sizeof(struct fun_act2_11) == 16, "");
_Static_assert(_Alignof(struct fun_act2_11) == 8, "");
_Static_assert(sizeof(struct fun_act2_12) == 16, "");
_Static_assert(_Alignof(struct fun_act2_12) == 8, "");
_Static_assert(sizeof(struct fun_act1_20) == 16, "");
_Static_assert(_Alignof(struct fun_act1_20) == 8, "");
_Static_assert(sizeof(struct fun_act1_21) == 16, "");
_Static_assert(_Alignof(struct fun_act1_21) == 8, "");
_Static_assert(sizeof(struct fun_act2_13) == 16, "");
_Static_assert(_Alignof(struct fun_act2_13) == 8, "");
_Static_assert(sizeof(struct opt_19) == 32, "");
_Static_assert(_Alignof(struct opt_19) == 8, "");
_Static_assert(sizeof(struct get_or_update_action_1) == 24, "");
_Static_assert(_Alignof(struct get_or_update_action_1) == 8, "");
_Static_assert(sizeof(struct fun_act1_22) == 16, "");
_Static_assert(_Alignof(struct fun_act1_22) == 8, "");
_Static_assert(sizeof(struct opt_20) == 24, "");
_Static_assert(_Alignof(struct opt_20) == 8, "");
_Static_assert(sizeof(struct fun_act3_4) == 16, "");
_Static_assert(_Alignof(struct fun_act3_4) == 8, "");
_Static_assert(sizeof(struct fun_act1_23) == 16, "");
_Static_assert(_Alignof(struct fun_act1_23) == 8, "");
_Static_assert(sizeof(struct fun_act1_24) == 16, "");
_Static_assert(_Alignof(struct fun_act1_24) == 8, "");
_Static_assert(sizeof(struct fun_act2_14) == 16, "");
_Static_assert(_Alignof(struct fun_act2_14) == 8, "");
_Static_assert(sizeof(struct fun_act2_15) == 16, "");
_Static_assert(_Alignof(struct fun_act2_15) == 8, "");
_Static_assert(sizeof(struct fun_act3_5) == 16, "");
_Static_assert(_Alignof(struct fun_act3_5) == 8, "");
_Static_assert(sizeof(struct fun_act2_16) == 16, "");
_Static_assert(_Alignof(struct fun_act2_16) == 8, "");
_Static_assert(sizeof(struct fun_act2_17) == 16, "");
_Static_assert(_Alignof(struct fun_act2_17) == 8, "");
_Static_assert(sizeof(struct fun_act1_25) == 16, "");
_Static_assert(_Alignof(struct fun_act1_25) == 8, "");
_Static_assert(sizeof(struct result_2) == 24, "");
_Static_assert(_Alignof(struct result_2) == 8, "");
_Static_assert(sizeof(struct fun0) == 16, "");
_Static_assert(_Alignof(struct fun0) == 8, "");
_Static_assert(sizeof(struct fun_act1_26) == 16, "");
_Static_assert(_Alignof(struct fun_act1_26) == 8, "");
_Static_assert(sizeof(struct opt_21) == 16, "");
_Static_assert(_Alignof(struct opt_21) == 8, "");
_Static_assert(sizeof(struct fun_act2_18) == 16, "");
_Static_assert(_Alignof(struct fun_act2_18) == 8, "");
_Static_assert(sizeof(struct opt_22) == 16, "");
_Static_assert(_Alignof(struct opt_22) == 8, "");
_Static_assert(sizeof(struct fun_act1_27) == 16, "");
_Static_assert(_Alignof(struct fun_act1_27) == 8, "");
_Static_assert(sizeof(struct fun_act1_28) == 16, "");
_Static_assert(_Alignof(struct fun_act1_28) == 8, "");
_Static_assert(sizeof(struct opt_23) == 16, "");
_Static_assert(_Alignof(struct opt_23) == 8, "");
_Static_assert(sizeof(struct opt_24) == 24, "");
_Static_assert(_Alignof(struct opt_24) == 8, "");
_Static_assert(sizeof(struct fun_act1_29) == 16, "");
_Static_assert(_Alignof(struct fun_act1_29) == 8, "");
_Static_assert(sizeof(struct fun_act2_19) == 16, "");
_Static_assert(_Alignof(struct fun_act2_19) == 8, "");
_Static_assert(sizeof(struct fun_act1_30) == 16, "");
_Static_assert(_Alignof(struct fun_act1_30) == 8, "");
_Static_assert(sizeof(struct fun_act1_31) == 16, "");
_Static_assert(_Alignof(struct fun_act1_31) == 8, "");
_Static_assert(sizeof(struct fun_act1_32) == 16, "");
_Static_assert(_Alignof(struct fun_act1_32) == 8, "");
_Static_assert(sizeof(struct fun_act2_20) == 16, "");
_Static_assert(_Alignof(struct fun_act2_20) == 8, "");
_Static_assert(sizeof(struct fun_act2_21) == 16, "");
_Static_assert(_Alignof(struct fun_act2_21) == 8, "");
_Static_assert(sizeof(struct fun_act2_22) == 16, "");
_Static_assert(_Alignof(struct fun_act2_22) == 8, "");
uint8_t mark(struct mark_ctx* ctx, uint8_t* ptr_any, uint64_t size_bytes);
struct void_ hard_assert(uint8_t condition);
extern void abort(void);
uint8_t is_word_aligned_0(uint8_t* a);
uint8_t is_word_aligned_1(uint8_t* a);
uint64_t words_of_bytes(uint64_t size_bytes);
uint64_t round_up_to_multiple_of_8(uint64_t n);
uint64_t* ptr_cast_0(uint8_t* a);
uint64_t _minus_0(uint64_t* a, uint64_t* b);
uint64_t _minus_1(uint64_t* a, uint64_t* b);
struct comparison _compare_0(uint64_t a, uint64_t b);
struct comparison cmp_0(uint64_t a, uint64_t b);
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
struct mut_arr_1* mut_arr_0(struct ctx* ctx);
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
struct void_ incr_capacity__e_0(struct ctx* ctx, struct mut_arr_1* a);
struct void_ ensure_capacity_0(struct ctx* ctx, struct mut_arr_1* a, uint64_t min_capacity);
uint64_t capacity_0(struct mut_arr_1* a);
uint64_t size_0(struct fix_arr_1 a);
struct void_ increase_capacity_to__e_0(struct ctx* ctx, struct mut_arr_1* a, uint64_t new_capacity);
struct void_ assert_0(struct ctx* ctx, uint8_t condition);
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
struct comparison _compare_1(uint64_t* a, uint64_t* b);
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
struct void_ sort__e_0(struct named_val* a, uint64_t size);
struct void_ swap__e_0(struct named_val* a, uint64_t lo, uint64_t hi);
struct named_val subscript_1(struct named_val* a, uint64_t n);
struct void_ set_subscript_0(struct named_val* a, uint64_t n, struct named_val value);
uint64_t partition__e(struct named_val* a, uint8_t* pivot, uint64_t l, uint64_t r);
uint8_t _equal_1(uint8_t* a, uint8_t* b);
struct comparison _compare_2(uint8_t* a, uint8_t* b);
struct comparison _compare_3(uint8_t* a, uint8_t* b);
uint8_t _less_2(uint8_t* a, uint8_t* b);
struct void_ fill_code_names__e(struct ctx* ctx, struct sym* code_names, struct sym* end_code_names, uint8_t** code_ptrs, struct named_val* funs);
struct comparison _compare_4(struct sym* a, struct sym* b);
uint8_t _less_3(struct sym* a, struct sym* b);
struct sym get_fun_name(uint8_t* code_ptr, struct named_val* funs, uint64_t size);
struct named_val subscript_2(struct named_val* a, uint64_t n);
struct named_val _times_1(struct named_val* a);
struct named_val* _plus_1(struct named_val* a, uint64_t offset);
uint8_t* _times_2(uint8_t** a);
uint8_t** _plus_2(uint8_t** a, uint64_t offset);
char* begin_ptr_0(struct mut_arr_1* a);
char* begin_ptr_1(struct fix_arr_1 a);
struct fix_arr_1 uninitialized_fix_arr_0(struct ctx* ctx, uint64_t size);
struct fix_arr_1 fix_arr_2(uint64_t size, char* begin_ptr);
char* alloc_uninitialized_0(struct ctx* ctx, uint64_t size);
uint8_t* alloc(struct ctx* ctx, uint64_t size_bytes);
uint8_t* gc_alloc(struct ctx* ctx, struct gc* gc, uint64_t size);
uint8_t* todo_1(void);
struct void_ copy_data_from__e_1(struct ctx* ctx, char* to, char* from, uint64_t len);
struct void_ set_zero_elements_0(struct fix_arr_1 a);
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
struct comparison _compare_5(char* a, char* b);
struct comparison _compare_6(char* a, char* b);
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
struct arr_0 move_to_arr__e_0(struct mut_arr_1* a);
struct arr_0 cast_immutable_0(struct fix_arr_1 a);
struct fix_arr_1 move_to_fix_arr__e_0(struct mut_arr_1* a);
struct global_ctx* get_global_ctx(struct ctx* ctx);
struct void_ island__lambda0(struct ctx* ctx, struct void_ _closure, struct exception exn);
struct void_ default_log_handler(struct ctx* ctx, struct logged* a);
struct void_ print(struct str a);
struct void_ print_no_newline(struct str a);
int32_t stdout(void);
struct str _tilde_0(struct ctx* ctx, struct str a, struct str b);
struct arr_0 _tilde_1(struct ctx* ctx, struct arr_0 a, struct arr_0 b);
struct str to_str_2(struct ctx* ctx, struct log_level a);
struct void_ island__lambda1(struct ctx* ctx, struct void_ _closure, struct logged* log);
struct gc gc(void);
struct void_ validate_gc(struct gc* gc);
struct comparison _compare_7(uint8_t* a, uint8_t* b);
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
struct arr_7 tail_0(struct ctx* ctx, struct arr_7 a);
uint8_t is_empty_2(struct arr_7 a);
struct arr_7 subscript_17(struct ctx* ctx, struct arr_7 a, struct range range);
char** _plus_6(char** a, uint64_t offset);
struct arr_2 map_0(struct ctx* ctx, struct arr_7 a, struct fun_act1_6 f);
struct arr_2 make_arr_0(struct ctx* ctx, uint64_t size, struct fun_act1_7 f);
struct str* alloc_uninitialized_1(struct ctx* ctx, uint64_t size);
struct void_ fill_ptr_range_0(struct ctx* ctx, struct str* begin, uint64_t size, struct fun_act1_7 f);
struct void_ fill_ptr_range_recur_0(struct ctx* ctx, struct str* begin, uint64_t i, uint64_t size, struct fun_act1_7 f);
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
struct str map_0__lambda0(struct ctx* ctx, struct map_0__lambda0* _closure, uint64_t i);
struct str add_first_task__lambda0__lambda0(struct ctx* ctx, struct void_ _closure, char* arg);
struct fut_0* add_first_task__lambda0(struct ctx* ctx, struct add_first_task__lambda0* _closure);
struct void_ handle_exceptions(struct ctx* ctx, struct fut_0* a);
struct void_ subscript_22(struct ctx* ctx, struct fun1_0 a, struct exception p0);
struct void_ call_w_ctx_299(struct fun1_0 a, struct ctx* ctx, struct exception p0);
struct fun1_0 exception_handler(struct ctx* ctx, struct island* a);
struct island* get_cur_island(struct ctx* ctx);
struct void_ handle_exceptions__lambda0(struct ctx* ctx, struct void_ _closure, struct result_0 result);
struct fut_0* add_main_task__lambda0(struct ctx* ctx, struct void_ _closure, struct arr_7 all_args, fun_ptr2 main_ptr);
struct fut_0* call_w_ctx_304(struct fun_act2_0 a, struct ctx* ctx, struct arr_7 p0, fun_ptr2 p1);
struct void_ run_threads(uint64_t n_threads, struct global_ctx* gctx);
struct thread_args* unmanaged_alloc_elements_1(uint64_t size_elements);
struct void_ start_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads, struct thread_args* thread_args_begin, struct global_ctx* gctx);
struct void_ create_one_thread(struct cell_0* tid, uint8_t* thread_arg, fun_ptr1 thread_fun);
extern int32_t pthread_create(struct cell_0* thread, uint8_t* attr, fun_ptr1 start_routine, uint8_t* arg);
uint8_t* null_0(void);
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
uint8_t in_recur_0(uint64_t value, struct arr_3 a, uint64_t i);
uint64_t noctx_at_1(struct arr_3 a, uint64_t index);
uint64_t unsafe_at_2(struct arr_3 a, uint64_t index);
uint64_t subscript_23(uint64_t* a, uint64_t n);
uint64_t _times_8(uint64_t* a);
uint64_t* _plus_7(uint64_t* a, uint64_t offset);
struct arr_3 temp_as_arr_0(struct mut_arr_0* a);
struct arr_3 temp_as_arr_1(struct fix_arr_0 a);
struct fix_arr_0 temp_as_fix_arr_0(struct mut_arr_0* a);
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
struct void_ drop_1(uint64_t _p0);
uint64_t noctx_remove_unordered_at__e_0(struct mut_arr_0* a, uint64_t index);
struct void_ return_ctx(struct ctx* c);
struct void_ return_gc_ctx(struct gc_ctx* gc_ctx);
struct void_ run_garbage_collection(struct gc* gc, struct island_gc_root gc_root);
struct void_ mark_visit_363(struct mark_ctx* mark_ctx, struct island_gc_root value);
struct void_ mark_visit_364(struct mark_ctx* mark_ctx, struct task_queue value);
struct void_ mark_visit_365(struct mark_ctx* mark_ctx, struct opt_3 value);
struct void_ mark_visit_366(struct mark_ctx* mark_ctx, struct some_3 value);
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
struct void_ mark_visit_393(struct mark_ctx* mark_ctx, struct some_0 value);
struct void_ mark_visit_394(struct mark_ctx* mark_ctx, struct fut_state_callbacks_0* value);
struct void_ mark_visit_395(struct mark_ctx* mark_ctx, struct exception value);
struct void_ mark_visit_396(struct mark_ctx* mark_ctx, struct str value);
struct void_ mark_arr_397(struct mark_ctx* mark_ctx, struct arr_0 a);
struct void_ mark_visit_398(struct mark_ctx* mark_ctx, struct backtrace value);
struct void_ mark_arr_399(struct mark_ctx* mark_ctx, struct arr_1 a);
struct void_ mark_visit_400(struct mark_ctx* mark_ctx, struct then__lambda0* value);
struct void_ mark_visit_401(struct mark_ctx* mark_ctx, struct opt_10 value);
struct void_ mark_visit_402(struct mark_ctx* mark_ctx, struct some_10 value);
struct void_ mark_visit_403(struct mark_ctx* mark_ctx, struct fut_state_callbacks_1* value);
struct void_ mark_visit_404(struct mark_ctx* mark_ctx, struct fut_1* value);
struct void_ mark_visit_405(struct mark_ctx* mark_ctx, struct callback__e_0__lambda0* value);
struct void_ mark_visit_406(struct mark_ctx* mark_ctx, struct callback__e_1__lambda0 value);
struct void_ mark_visit_407(struct mark_ctx* mark_ctx, struct callback__e_1__lambda0* value);
struct void_ mark_visit_408(struct mark_ctx* mark_ctx, struct subscript_10__lambda0__lambda0 value);
struct void_ mark_visit_409(struct mark_ctx* mark_ctx, struct subscript_10__lambda0__lambda0* value);
struct void_ mark_visit_410(struct mark_ctx* mark_ctx, struct subscript_10__lambda0 value);
struct void_ mark_visit_411(struct mark_ctx* mark_ctx, struct subscript_10__lambda0* value);
struct void_ mark_visit_412(struct mark_ctx* mark_ctx, struct subscript_15__lambda0__lambda0 value);
struct void_ mark_visit_413(struct mark_ctx* mark_ctx, struct subscript_15__lambda0__lambda0* value);
struct void_ mark_visit_414(struct mark_ctx* mark_ctx, struct subscript_15__lambda0 value);
struct void_ mark_visit_415(struct mark_ctx* mark_ctx, struct subscript_15__lambda0* value);
struct void_ mark_visit_416(struct mark_ctx* mark_ctx, struct task_queue_node* value);
struct void_ mark_visit_417(struct mark_ctx* mark_ctx, struct mut_arr_0 value);
struct void_ mark_visit_418(struct mark_ctx* mark_ctx, struct fix_arr_0 value);
struct void_ mark_arr_419(struct mark_ctx* mark_ctx, struct arr_3 a);
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
struct fut_0* main_0(struct ctx* ctx, struct arr_2 args);
struct fut_0* resolved_1(struct ctx* ctx, uint64_t value);
struct opt_13 parse_named_args_0(struct ctx* ctx, struct arr_2 args, struct arr_2 arg_names);
struct parsed_command* parse_command_dynamic(struct ctx* ctx, struct arr_2 args);
struct opt_11 find_index_0(struct ctx* ctx, struct arr_2 a, struct fun_act1_8 f);
struct opt_11 find_index_recur_0(struct ctx* ctx, struct arr_2 a, uint64_t index, struct fun_act1_8 f);
uint8_t subscript_25(struct ctx* ctx, struct fun_act1_8 a, struct str p0);
uint8_t call_w_ctx_448(struct fun_act1_8 a, struct ctx* ctx, struct str p0);
struct str subscript_26(struct ctx* ctx, struct arr_2 a, uint64_t index);
struct str unsafe_at_3(struct arr_2 a, uint64_t index);
struct str subscript_27(struct str* a, uint64_t n);
struct str _times_10(struct str* a);
struct str* _plus_8(struct str* a, uint64_t offset);
uint8_t starts_with_0(struct ctx* ctx, struct str a, struct str b);
uint8_t _equal_4(struct arr_0 a, struct arr_0 b);
uint8_t arr_equal(struct arr_0 a, struct arr_0 b);
uint8_t equal_recur(char* a, char* a_end, char* b, char* b_end);
uint8_t starts_with_1(struct ctx* ctx, struct arr_0 a, struct arr_0 start);
uint8_t parse_command_dynamic__lambda0(struct ctx* ctx, struct void_ _closure, struct str arg);
uint8_t _equal_5(struct str a, struct str b);
struct comparison _compare_8(struct str a, struct str b);
struct comparison _compare_9(char a, char b);
struct comparison _compare_10(uint8_t a, uint8_t b);
struct comparison cmp_1(uint8_t a, uint8_t b);
struct comparison arr_compare(struct arr_0 a, struct arr_0 b);
struct comparison compare_recur(char* a, char* a_end, char* b, char* b_end);
struct void_ hash_mix_0(struct ctx* ctx, struct hasher* hasher, struct str a);
struct void_ hash_mix_1(struct ctx* ctx, struct hasher* hasher, uint64_t a);
struct void_ hash_mix_0__lambda0(struct ctx* ctx, struct hash_mix_0__lambda0* _closure, char c);
struct dict_0 dict_0(struct ctx* ctx, struct arr_10 a);
uint8_t no_duplicate_keys_0(struct ctx* ctx, struct arr_10 a);
struct arrow_0 subscript_28(struct ctx* ctx, struct arr_10 a, uint64_t index);
struct arrow_0 unsafe_at_4(struct arr_10 a, uint64_t index);
struct arrow_0 subscript_29(struct arrow_0* a, uint64_t n);
struct arrow_0 _times_11(struct arrow_0* a);
struct arrow_0* _plus_9(struct arrow_0* a, uint64_t offset);
uint8_t every_0(struct ctx* ctx, struct arr_10 a, struct fun_act1_9 f);
uint8_t is_empty_5(struct arr_10 a);
uint8_t subscript_30(struct ctx* ctx, struct fun_act1_9 a, struct arrow_0 p0);
uint8_t call_w_ctx_480(struct fun_act1_9 a, struct ctx* ctx, struct arrow_0 p0);
struct arr_10 tail_1(struct ctx* ctx, struct arr_10 a);
struct arr_10 subscript_31(struct ctx* ctx, struct arr_10 a, struct range range);
uint8_t _notEqual_8(struct str a, struct str b);
uint8_t no_duplicate_keys_0__lambda0(struct ctx* ctx, struct no_duplicate_keys_0__lambda0* _closure, struct arrow_0 it);
struct dict_0 fold_0(struct ctx* ctx, struct dict_0 acc, struct arr_10 a, struct fun_act2_1 f);
struct dict_0 fold_recur_0(struct ctx* ctx, struct dict_0 acc, struct arrow_0* cur, struct arrow_0* end, struct fun_act2_1 f);
uint8_t _equal_6(struct arrow_0* a, struct arrow_0* b);
struct dict_0 subscript_32(struct ctx* ctx, struct fun_act2_1 a, struct dict_0 p0, struct arrow_0 p1);
struct dict_0 call_w_ctx_489(struct fun_act2_1 a, struct ctx* ctx, struct dict_0 p0, struct arrow_0 p1);
struct arrow_0* end_ptr_2(struct arr_10 a);
struct dict_0 dict_1(struct ctx* ctx);
struct leaf_node_0 empty_leaf_node_0(struct ctx* ctx);
struct dict_0 _tilde_2(struct ctx* ctx, struct dict_0 a, struct arrow_0 pair);
struct get_or_update_result_0 get_or_update_0(struct ctx* ctx, struct dict_0 a, struct str key, struct fun_act1_10 f);
uint64_t hash(struct ctx* ctx, struct str a);
struct get_or_update_result_0 get_or_update_recur_0(struct ctx* ctx, struct node_0 a, struct str key, uint64_t remaining_hash, uint64_t hash_shift, struct fun_act1_10 f);
uint64_t low_bits(struct ctx* ctx, uint64_t a);
struct node_0 subscript_33(struct ctx* ctx, struct arr_9 a, uint64_t index);
struct node_0 unsafe_at_5(struct arr_9 a, uint64_t index);
struct node_0 subscript_34(struct node_0* a, uint64_t n);
struct node_0 _times_12(struct node_0* a);
struct node_0* _plus_10(struct node_0* a, uint64_t offset);
struct node_0 update_child_0(struct ctx* ctx, struct inner_node_0 a, uint64_t which, struct node_0 new_child);
struct opt_15 inner_node_to_leaf_0(struct ctx* ctx, struct inner_node_0 a, uint64_t which, struct node_0 new_child);
uint64_t fold_with_index_0(struct ctx* ctx, uint64_t acc, struct arr_9 a, struct fun_act3_0 f);
uint64_t fold_with_index_recur_0(struct ctx* ctx, uint64_t acc, uint64_t index, struct node_0* cur, struct node_0* end, struct fun_act3_0 f);
uint8_t _equal_7(struct node_0* a, struct node_0* b);
uint64_t subscript_35(struct ctx* ctx, struct fun_act3_0 a, uint64_t p0, struct node_0 p1, uint64_t p2);
uint64_t call_w_ctx_509(struct fun_act3_0 a, struct ctx* ctx, uint64_t p0, struct node_0 p1, uint64_t p2);
struct node_0* end_ptr_3(struct arr_9 a);
uint64_t inner_node_to_leaf_0__lambda0(struct ctx* ctx, struct inner_node_to_leaf_0__lambda0* _closure, uint64_t cur, struct node_0 child, uint64_t child_index);
uint64_t leaf_max_size(struct ctx* ctx);
struct fix_arr_3 uninitialized_fix_arr_1(struct ctx* ctx, uint64_t size);
struct fix_arr_3 fix_arr_4(uint64_t size, struct arrow_0* begin_ptr);
struct arrow_0* alloc_uninitialized_2(struct ctx* ctx, uint64_t size);
uint64_t unreachable_0(struct ctx* ctx);
uint64_t throw_2(struct ctx* ctx, struct str message);
uint64_t throw_3(struct ctx* ctx, struct exception e);
uint64_t hard_unreachable_2(void);
struct void_ copy_from__e_0(struct ctx* ctx, struct fix_arr_3 dest, struct arr_10 source);
uint64_t size_3(struct fix_arr_3 a);
struct arrow_0* begin_ptr_4(struct fix_arr_3 a);
uint8_t* as_any_const_ptr_2(struct arrow_0* ref);
struct fix_arr_3 subscript_36(struct ctx* ctx, struct fix_arr_3 a, struct range range);
uint64_t inner_node_to_leaf_0__lambda1(struct ctx* ctx, struct inner_node_to_leaf_0__lambda1* _closure, uint64_t out_index, struct node_0 child, uint64_t child_index);
struct arr_10 cast_immutable_1(struct fix_arr_3 a);
uint8_t node_is_empty_0(struct ctx* ctx, struct node_0 a);
struct arr_9 rtail_0(struct ctx* ctx, struct arr_9 a);
uint8_t is_empty_6(struct arr_9 a);
struct arr_9 subscript_37(struct ctx* ctx, struct arr_9 a, struct range range);
uint64_t _minus_5(struct ctx* ctx, uint64_t a, uint64_t b);
struct arr_9 update_0(struct ctx* ctx, struct arr_9 a, uint64_t index, struct node_0 new_value);
struct arr_9 _tilde_3(struct ctx* ctx, struct arr_9 a, struct arr_9 b);
struct node_0* alloc_uninitialized_3(struct ctx* ctx, uint64_t size);
struct void_ copy_data_from__e_2(struct ctx* ctx, struct node_0* to, struct node_0* from, uint64_t len);
uint8_t* as_any_const_ptr_3(struct node_0* ref);
struct opt_14 find_only_non_empty_child_0(struct ctx* ctx, struct arr_9 children);
uint64_t force_0(struct ctx* ctx, struct opt_11 a);
uint64_t force_1(struct ctx* ctx, struct opt_11 a, struct str message);
struct opt_11 find_index_1(struct ctx* ctx, struct arr_9 a, struct fun_act1_11 f);
struct opt_11 find_index_recur_1(struct ctx* ctx, struct arr_9 a, uint64_t index, struct fun_act1_11 f);
uint8_t subscript_38(struct ctx* ctx, struct fun_act1_11 a, struct node_0 p0);
uint8_t call_w_ctx_543(struct fun_act1_11 a, struct ctx* ctx, struct node_0 p0);
uint8_t find_only_non_empty_child_0__lambda0(struct ctx* ctx, struct void_ _closure, struct node_0 it);
uint8_t every_1(struct ctx* ctx, struct arr_9 a, struct fun_act1_11 f);
struct arr_9 tail_2(struct ctx* ctx, struct arr_9 a);
uint8_t find_only_non_empty_child_0__lambda1(struct ctx* ctx, struct void_ _closure, struct node_0 it);
struct get_or_update_action_0 subscript_39(struct ctx* ctx, struct fun_act1_10 a, struct opt_12 p0);
struct get_or_update_action_0 call_w_ctx_549(struct fun_act1_10 a, struct ctx* ctx, struct opt_12 p0);
struct arrow_0 _arrow_0(struct str from, struct arr_2 to);
struct arr_9 update_with_default_0(struct ctx* ctx, struct arr_9 a, uint64_t index, struct node_0 new_value, struct node_0 _default);
struct arr_9 make_arr_1(struct ctx* ctx, uint64_t size, struct fun_act1_12 f);
struct void_ fill_ptr_range_1(struct ctx* ctx, struct node_0* begin, uint64_t size, struct fun_act1_12 f);
struct void_ fill_ptr_range_recur_1(struct ctx* ctx, struct node_0* begin, uint64_t i, uint64_t size, struct fun_act1_12 f);
struct void_ set_subscript_4(struct node_0* a, uint64_t n, struct node_0 value);
struct node_0 subscript_40(struct ctx* ctx, struct fun_act1_12 a, uint64_t p0);
struct node_0 call_w_ctx_557(struct fun_act1_12 a, struct ctx* ctx, uint64_t p0);
struct node_0 update_with_default_0__lambda0(struct ctx* ctx, struct update_with_default_0__lambda0* _closure, uint64_t i);
struct get_or_update_result_0 get_or_update_leaf_0(struct ctx* ctx, struct leaf_node_0 a, struct str key, uint64_t remaining_hash, uint64_t hash_shift, struct fun_act1_10 f);
struct opt_11 find_index_2(struct ctx* ctx, struct arr_10 a, struct fun_act1_9 f);
struct opt_11 find_index_recur_2(struct ctx* ctx, struct arr_10 a, uint64_t index, struct fun_act1_9 f);
uint8_t get_or_update_leaf_0__lambda0(struct ctx* ctx, struct get_or_update_leaf_0__lambda0* _closure, struct arrow_0 it);
struct inner_node_0 new_inner_node_0(struct ctx* ctx, struct leaf_node_0 a, struct str key, struct arr_2 value, uint64_t hash, uint64_t hash_shift);
uint64_t fold_1(struct ctx* ctx, uint64_t acc, struct arr_10 a, struct fun_act2_2 f);
uint64_t fold_recur_1(struct ctx* ctx, uint64_t acc, struct arrow_0* cur, struct arrow_0* end, struct fun_act2_2 f);
uint64_t subscript_41(struct ctx* ctx, struct fun_act2_2 a, uint64_t p0, struct arrow_0 p1);
uint64_t call_w_ctx_567(struct fun_act2_2 a, struct ctx* ctx, uint64_t p0, struct arrow_0 p1);
uint64_t max(uint64_t a, uint64_t b);
uint64_t new_inner_node_0__lambda0(struct ctx* ctx, struct new_inner_node_0__lambda0* _closure, uint64_t cur, struct arrow_0 pair);
struct fix_arr_4 fill_fix_arr_0(struct ctx* ctx, uint64_t size, struct node_0 value);
struct fix_arr_4 make_fix_arr_0(struct ctx* ctx, uint64_t size, struct fun_act1_12 f);
struct fix_arr_4 uninitialized_fix_arr_2(struct ctx* ctx, uint64_t size);
struct fix_arr_4 fix_arr_5(uint64_t size, struct node_0* begin_ptr);
struct node_0* begin_ptr_5(struct fix_arr_4 a);
struct node_0 fill_fix_arr_0__lambda0(struct ctx* ctx, struct fill_fix_arr_0__lambda0* _closure, uint64_t ignore);
struct void_ set_subscript_5(struct ctx* ctx, struct fix_arr_4 a, uint64_t index, struct node_0 value);
uint64_t size_4(struct fix_arr_4 a);
struct void_ unsafe_set_at__e_0(struct ctx* ctx, struct fix_arr_4 a, uint64_t index, struct node_0 value);
struct void_ each_2(struct ctx* ctx, struct arr_10 a, struct fun_act1_13 f);
struct void_ each_recur_2(struct ctx* ctx, struct arrow_0* cur, struct arrow_0* end, struct fun_act1_13 f);
uint8_t _notEqual_9(struct arrow_0* a, struct arrow_0* b);
struct void_ subscript_42(struct ctx* ctx, struct fun_act1_13 a, struct arrow_0 p0);
struct void_ call_w_ctx_583(struct fun_act1_13 a, struct ctx* ctx, struct arrow_0 p0);
struct node_0 subscript_43(struct ctx* ctx, struct fix_arr_4 a, uint64_t index);
struct node_0 unsafe_at_6(struct ctx* ctx, struct fix_arr_4 a, uint64_t index);
struct node_0 subscript_44(struct node_0* a, uint64_t n);
struct node_0 unreachable_1(struct ctx* ctx);
struct node_0 throw_4(struct ctx* ctx, struct str message);
struct node_0 throw_5(struct ctx* ctx, struct exception e);
struct node_0 hard_unreachable_3(void);
struct arr_10 _tilde_4(struct ctx* ctx, struct arr_10 a, struct arr_10 b);
struct void_ copy_data_from__e_3(struct ctx* ctx, struct arrow_0* to, struct arrow_0* from, uint64_t len);
struct void_ new_inner_node_0__lambda1(struct ctx* ctx, struct new_inner_node_0__lambda1* _closure, struct arrow_0 pair);
struct arr_9 cast_immutable_2(struct fix_arr_4 a);
struct arr_10 remove_at_0(struct ctx* ctx, struct arr_10 a, uint64_t index);
struct arr_10 update_1(struct ctx* ctx, struct arr_10 a, uint64_t index, struct arrow_0 new_value);
struct get_or_update_action_0 _tilde_2__lambda0(struct ctx* ctx, struct _tilde_2__lambda0* _closure, struct opt_12 old_value);
struct dict_0 dict_0__lambda0(struct ctx* ctx, struct void_ _closure, struct dict_0 cur, struct arrow_0 x);
struct arr_2 subscript_45(struct ctx* ctx, struct arr_2 a, struct range range);
uint8_t parse_command_dynamic__lambda1(struct ctx* ctx, struct void_ _closure, struct str arg);
struct dict_0 parse_named_args_1(struct ctx* ctx, struct arr_2 args);
struct mut_dict_0* mut_dict_0(struct ctx* ctx);
struct fix_arr_5 fix_arr_6(void);
struct void_ parse_named_args_recur(struct ctx* ctx, struct arr_2 args, struct mut_dict_0* builder);
struct str force_2(struct ctx* ctx, struct opt_16 a);
struct str force_3(struct ctx* ctx, struct opt_16 a, struct str message);
struct str throw_6(struct ctx* ctx, struct str message);
struct str throw_7(struct ctx* ctx, struct exception e);
struct str hard_unreachable_4(void);
struct opt_16 try_remove_start_0(struct ctx* ctx, struct str a, struct str b);
struct opt_17 try_remove_start_1(struct ctx* ctx, struct arr_0 a, struct arr_0 start);
struct arr_2 tail_3(struct ctx* ctx, struct arr_2 a);
uint8_t is_empty_7(struct arr_2 a);
uint8_t parse_named_args_recur__lambda0(struct ctx* ctx, struct void_ _closure, struct str arg);
struct void_ set_subscript_6(struct ctx* ctx, struct mut_dict_0* a, struct str key, struct arr_2 value);
struct void_ drop_2(struct opt_12 _p0);
struct opt_12 update__e_0(struct ctx* ctx, struct mut_dict_0* a, struct str key, struct opt_12 new_value);
uint8_t is_empty_8(struct fix_arr_5 a);
uint64_t size_5(struct fix_arr_5 a);
struct fix_arr_5 fix_arr_7(struct ctx* ctx, struct arr_11 a);
struct fix_arr_5 make_fix_arr_1(struct ctx* ctx, uint64_t size, struct fun_act1_14 f);
struct fix_arr_5 uninitialized_fix_arr_3(struct ctx* ctx, uint64_t size);
struct fix_arr_5 fix_arr_8(uint64_t size, struct entry_0* begin_ptr);
struct entry_0* alloc_uninitialized_4(struct ctx* ctx, uint64_t size);
struct void_ fill_ptr_range_2(struct ctx* ctx, struct entry_0* begin, uint64_t size, struct fun_act1_14 f);
struct void_ fill_ptr_range_recur_2(struct ctx* ctx, struct entry_0* begin, uint64_t i, uint64_t size, struct fun_act1_14 f);
struct void_ set_subscript_7(struct entry_0* a, uint64_t n, struct entry_0 value);
struct entry_0 subscript_46(struct ctx* ctx, struct fun_act1_14 a, uint64_t p0);
struct entry_0 call_w_ctx_629(struct fun_act1_14 a, struct ctx* ctx, uint64_t p0);
struct entry_0* begin_ptr_6(struct fix_arr_5 a);
struct entry_0 subscript_47(struct ctx* ctx, struct arr_11 a, uint64_t index);
struct entry_0 unsafe_at_7(struct arr_11 a, uint64_t index);
struct entry_0 subscript_48(struct entry_0* a, uint64_t n);
struct entry_0 _times_13(struct entry_0* a);
struct entry_0* _plus_11(struct entry_0* a, uint64_t offset);
struct entry_0 fix_arr_7__lambda0(struct ctx* ctx, struct fix_arr_7__lambda0* _closure, uint64_t i);
struct entry_0 subscript_49(struct ctx* ctx, struct fix_arr_5 a, uint64_t index);
struct entry_0 unsafe_at_8(struct ctx* ctx, struct fix_arr_5 a, uint64_t index);
struct entry_0 subscript_50(struct entry_0* a, uint64_t n);
struct void_ set_subscript_8(struct ctx* ctx, struct fix_arr_5 a, uint64_t index, struct entry_0 value);
struct void_ unsafe_set_at__e_1(struct ctx* ctx, struct fix_arr_5 a, uint64_t index, struct entry_0 value);
uint8_t should_expand_0(struct ctx* ctx, struct mut_dict_0* a);
struct void_ expand__e_0(struct ctx* ctx, struct mut_dict_0* a);
struct mut_dict_0* mut_dict_with_capacity_0(struct ctx* ctx, uint64_t capacity);
struct fix_arr_5 fill_fix_arr_1(struct ctx* ctx, uint64_t size, struct entry_0 value);
struct entry_0 fill_fix_arr_1__lambda0(struct ctx* ctx, struct fill_fix_arr_1__lambda0* _closure, uint64_t ignore);
struct void_ each_3(struct ctx* ctx, struct mut_dict_0* a, struct fun_act2_3 f);
struct void_ fold_2(struct ctx* ctx, struct void_ acc, struct mut_dict_0* a, struct fun_act3_1 f);
struct void_ fold_3(struct ctx* ctx, struct void_ acc, struct fix_arr_5 a, struct fun_act2_4 f);
struct void_ fold_4(struct ctx* ctx, struct void_ acc, struct arr_11 a, struct fun_act2_4 f);
struct void_ fold_recur_2(struct ctx* ctx, struct void_ acc, struct entry_0* cur, struct entry_0* end, struct fun_act2_4 f);
uint8_t _equal_8(struct entry_0* a, struct entry_0* b);
struct void_ subscript_51(struct ctx* ctx, struct fun_act2_4 a, struct void_ p0, struct entry_0 p1);
struct void_ call_w_ctx_654(struct fun_act2_4 a, struct ctx* ctx, struct void_ p0, struct entry_0 p1);
struct entry_0* end_ptr_4(struct arr_11 a);
struct arr_11 temp_as_arr_2(struct fix_arr_5 a);
struct void_ subscript_52(struct ctx* ctx, struct fun_act3_1 a, struct void_ p0, struct str p1, struct arr_2 p2);
struct void_ call_w_ctx_658(struct fun_act3_1 a, struct ctx* ctx, struct void_ p0, struct str p1, struct arr_2 p2);
struct void_ fold_5(struct ctx* ctx, struct void_ acc, struct mut_arr_2* a, struct fun_act2_5 f);
struct void_ fold_6(struct ctx* ctx, struct void_ acc, struct arr_10 a, struct fun_act2_5 f);
struct void_ fold_recur_3(struct ctx* ctx, struct void_ acc, struct arrow_0* cur, struct arrow_0* end, struct fun_act2_5 f);
struct void_ subscript_53(struct ctx* ctx, struct fun_act2_5 a, struct void_ p0, struct arrow_0 p1);
struct void_ call_w_ctx_663(struct fun_act2_5 a, struct ctx* ctx, struct void_ p0, struct arrow_0 p1);
struct arr_10 temp_as_arr_3(struct mut_arr_2* a);
struct arr_10 temp_as_arr_4(struct fix_arr_3 a);
struct fix_arr_3 temp_as_fix_arr_1(struct mut_arr_2* a);
struct arrow_0* begin_ptr_7(struct mut_arr_2* a);
struct void_ fold_2__lambda0__lambda0(struct ctx* ctx, struct fold_2__lambda0__lambda0* _closure, struct void_ cur2, struct arrow_0 pair);
struct void_ fold_2__lambda0(struct ctx* ctx, struct fold_2__lambda0* _closure, struct void_ cur, struct entry_0 entry);
struct void_ subscript_54(struct ctx* ctx, struct fun_act2_3 a, struct str p0, struct arr_2 p1);
struct void_ call_w_ctx_671(struct fun_act2_3 a, struct ctx* ctx, struct str p0, struct arr_2 p1);
struct void_ each_3__lambda0(struct ctx* ctx, struct each_3__lambda0* _closure, struct void_ ignore, struct str key, struct arr_2 value);
struct void_ expand__e_0__lambda0(struct ctx* ctx, struct expand__e_0__lambda0* _closure, struct str key, struct arr_2 value);
struct void_ swap__e_1(struct ctx* ctx, struct mut_dict_0* a, struct mut_dict_0* b);
struct mut_arr_2* mut_arr_1(struct ctx* ctx, struct arr_10 a);
struct mut_arr_2* mut_arr_2(struct ctx* ctx);
struct fix_arr_3 fix_arr_9(void);
struct void_ _concatEquals_4(struct ctx* ctx, struct mut_arr_2* a, struct arr_10 values);
struct void_ _concatEquals_5(struct ctx* ctx, struct mut_arr_2* a, struct arrow_0 value);
struct void_ incr_capacity__e_1(struct ctx* ctx, struct mut_arr_2* a);
struct void_ ensure_capacity_1(struct ctx* ctx, struct mut_arr_2* a, uint64_t min_capacity);
uint64_t capacity_2(struct mut_arr_2* a);
struct void_ increase_capacity_to__e_1(struct ctx* ctx, struct mut_arr_2* a, uint64_t new_capacity);
struct void_ set_zero_elements_1(struct fix_arr_3 a);
struct void_ set_zero_range_2(struct arrow_0* begin, uint64_t size);
struct void_ set_subscript_9(struct arrow_0* a, uint64_t n, struct arrow_0 value);
struct void_ _concatEquals_4__lambda0(struct ctx* ctx, struct _concatEquals_4__lambda0* _closure, struct arrow_0 x);
struct opt_11 find_index_3(struct ctx* ctx, struct mut_arr_2* a, struct fun_act1_9 f);
uint8_t update__e_0__lambda0(struct ctx* ctx, struct update__e_0__lambda0* _closure, struct arrow_0 pair);
uint8_t is_at_capacity_0(struct mut_arr_2* a);
struct arrow_0 subscript_55(struct ctx* ctx, struct mut_arr_2* a, uint64_t index);
struct arrow_0 subscript_56(struct arrow_0* a, uint64_t n);
struct void_ drop_3(struct arrow_0 _p0);
struct arrow_0 remove_unordered_at__e_0(struct ctx* ctx, struct mut_arr_2* a, uint64_t index);
struct arrow_0 noctx_remove_unordered_at__e_1(struct mut_arr_2* a, uint64_t index);
uint8_t is_empty_9(struct mut_arr_2* a);
struct void_ set_subscript_10(struct ctx* ctx, struct mut_arr_2* a, uint64_t index, struct arrow_0 value);
struct dict_0 move_to_dict__e_0(struct ctx* ctx, struct mut_dict_0* a);
struct arr_10 map_to_arr_0(struct ctx* ctx, struct mut_dict_0* a, struct fun_act2_6 f);
uint64_t size_6(struct ctx* ctx, struct mut_dict_0* a);
struct arrow_0* fold_7(struct ctx* ctx, struct arrow_0* acc, struct mut_dict_0* a, struct fun_act3_2 f);
struct arrow_0* fold_8(struct ctx* ctx, struct arrow_0* acc, struct fix_arr_5 a, struct fun_act2_7 f);
struct arrow_0* fold_9(struct ctx* ctx, struct arrow_0* acc, struct arr_11 a, struct fun_act2_7 f);
struct arrow_0* fold_recur_4(struct ctx* ctx, struct arrow_0* acc, struct entry_0* cur, struct entry_0* end, struct fun_act2_7 f);
struct arrow_0* subscript_57(struct ctx* ctx, struct fun_act2_7 a, struct arrow_0* p0, struct entry_0 p1);
struct arrow_0* call_w_ctx_706(struct fun_act2_7 a, struct ctx* ctx, struct arrow_0* p0, struct entry_0 p1);
struct arrow_0* subscript_58(struct ctx* ctx, struct fun_act3_2 a, struct arrow_0* p0, struct str p1, struct arr_2 p2);
struct arrow_0* call_w_ctx_708(struct fun_act3_2 a, struct ctx* ctx, struct arrow_0* p0, struct str p1, struct arr_2 p2);
struct arrow_0* fold_10(struct ctx* ctx, struct arrow_0* acc, struct mut_arr_2* a, struct fun_act2_8 f);
struct arrow_0* fold_11(struct ctx* ctx, struct arrow_0* acc, struct arr_10 a, struct fun_act2_8 f);
struct arrow_0* fold_recur_5(struct ctx* ctx, struct arrow_0* acc, struct arrow_0* cur, struct arrow_0* end, struct fun_act2_8 f);
struct arrow_0* subscript_59(struct ctx* ctx, struct fun_act2_8 a, struct arrow_0* p0, struct arrow_0 p1);
struct arrow_0* call_w_ctx_713(struct fun_act2_8 a, struct ctx* ctx, struct arrow_0* p0, struct arrow_0 p1);
struct arrow_0* fold_7__lambda0__lambda0(struct ctx* ctx, struct fold_7__lambda0__lambda0* _closure, struct arrow_0* cur2, struct arrow_0 pair);
struct arrow_0* fold_7__lambda0(struct ctx* ctx, struct fold_7__lambda0* _closure, struct arrow_0* cur, struct entry_0 entry);
struct arrow_0 subscript_60(struct ctx* ctx, struct fun_act2_6 a, struct str p0, struct arr_2 p1);
struct arrow_0 call_w_ctx_717(struct fun_act2_6 a, struct ctx* ctx, struct str p0, struct arr_2 p1);
struct arrow_0* map_to_arr_0__lambda0(struct ctx* ctx, struct map_to_arr_0__lambda0* _closure, struct arrow_0* cur, struct str key, struct arr_2 value);
struct arrow_0* end_ptr_5(struct fix_arr_3 a);
struct arrow_0 move_to_dict__e_0__lambda0(struct ctx* ctx, struct void_ _closure, struct str k, struct arr_2 v);
struct void_ empty__e_0(struct ctx* ctx, struct mut_dict_0* a);
struct void_ fill__e_0(struct ctx* ctx, struct fix_arr_5 a, struct entry_0 value);
struct void_ map__e_0(struct ctx* ctx, struct fix_arr_5 a, struct fun_act1_15 f);
struct void_ map_recur__e_0(struct ctx* ctx, struct entry_0* cur, struct entry_0* end, struct fun_act1_15 f);
uint8_t _notEqual_10(struct entry_0* a, struct entry_0* b);
struct entry_0 subscript_61(struct ctx* ctx, struct fun_act1_15 a, struct entry_0 p0);
struct entry_0 call_w_ctx_727(struct fun_act1_15 a, struct ctx* ctx, struct entry_0 p0);
struct entry_0* end_ptr_6(struct fix_arr_5 a);
struct entry_0 fill__e_0__lambda0(struct ctx* ctx, struct fill__e_0__lambda0* _closure, struct entry_0 ignore);
struct void_ assert_1(struct ctx* ctx, uint8_t condition, struct str message);
struct mut_arr_3* fill_mut_arr(struct ctx* ctx, uint64_t size, struct opt_12 value);
struct fix_arr_6 fill_fix_arr_2(struct ctx* ctx, uint64_t size, struct opt_12 value);
struct fix_arr_6 make_fix_arr_2(struct ctx* ctx, uint64_t size, struct fun_act1_16 f);
struct fix_arr_6 uninitialized_fix_arr_4(struct ctx* ctx, uint64_t size);
struct fix_arr_6 fix_arr_10(uint64_t size, struct opt_12* begin_ptr);
struct opt_12* alloc_uninitialized_5(struct ctx* ctx, uint64_t size);
struct void_ fill_ptr_range_3(struct ctx* ctx, struct opt_12* begin, uint64_t size, struct fun_act1_16 f);
struct void_ fill_ptr_range_recur_3(struct ctx* ctx, struct opt_12* begin, uint64_t i, uint64_t size, struct fun_act1_16 f);
struct void_ set_subscript_11(struct opt_12* a, uint64_t n, struct opt_12 value);
struct opt_12 subscript_62(struct ctx* ctx, struct fun_act1_16 a, uint64_t p0);
struct opt_12 call_w_ctx_741(struct fun_act1_16 a, struct ctx* ctx, uint64_t p0);
struct opt_12* begin_ptr_8(struct fix_arr_6 a);
struct opt_12 fill_fix_arr_2__lambda0(struct ctx* ctx, struct fill_fix_arr_2__lambda0* _closure, uint64_t ignore);
struct void_ each_4(struct ctx* ctx, struct dict_0 a, struct fun_act2_3 f);
struct void_ fold_12(struct ctx* ctx, struct void_ acc, struct dict_0 a, struct fun_act3_1 f);
struct void_ fold_recur_6(struct ctx* ctx, struct void_ acc, struct node_0 a, struct fun_act3_1 f);
struct void_ fold_13(struct ctx* ctx, struct void_ acc, struct arr_9 a, struct fun_act2_9 f);
struct void_ fold_recur_7(struct ctx* ctx, struct void_ acc, struct node_0* cur, struct node_0* end, struct fun_act2_9 f);
struct void_ subscript_63(struct ctx* ctx, struct fun_act2_9 a, struct void_ p0, struct node_0 p1);
struct void_ call_w_ctx_750(struct fun_act2_9 a, struct ctx* ctx, struct void_ p0, struct node_0 p1);
struct void_ fold_recur_6__lambda0(struct ctx* ctx, struct fold_recur_6__lambda0* _closure, struct void_ cur, struct node_0 child);
struct void_ fold_recur_6__lambda1(struct ctx* ctx, struct fold_recur_6__lambda1* _closure, struct void_ cur, struct arrow_0 pair);
struct void_ each_4__lambda0(struct ctx* ctx, struct each_4__lambda0* _closure, struct void_ ignore, struct str key, struct arr_2 value);
struct opt_11 index_of(struct ctx* ctx, struct arr_2 a, struct str value);
struct opt_18 ptr_of(struct ctx* ctx, struct arr_2 a, struct str value);
struct opt_18 ptr_of_recur(struct ctx* ctx, struct str* cur, struct str* end, struct str value);
uint8_t _equal_9(struct str* a, struct str* b);
struct str* end_ptr_7(struct arr_2 a);
uint64_t _minus_6(struct str* a, struct str* b);
uint64_t _minus_7(struct str* a, struct str* b);
struct void_ set_deref_0(struct cell_3* a, uint8_t value);
struct str finish(struct ctx* ctx, struct interp a);
struct str to_str_3(struct ctx* ctx, struct str a);
struct interp with_value_0(struct ctx* ctx, struct interp a, struct str b);
struct interp with_str(struct ctx* ctx, struct interp a, struct str b);
struct interp interp(struct ctx* ctx);
uint8_t is_empty_10(struct opt_12 a);
struct opt_12 subscript_64(struct ctx* ctx, struct mut_arr_3* a, uint64_t index);
struct opt_12 subscript_65(struct opt_12* a, uint64_t n);
struct opt_12* begin_ptr_9(struct mut_arr_3* a);
struct void_ set_subscript_12(struct ctx* ctx, struct mut_arr_3* a, uint64_t index, struct opt_12 value);
struct void_ parse_named_args_0__lambda0(struct ctx* ctx, struct parse_named_args_0__lambda0* _closure, struct str key, struct arr_2 value);
uint8_t _times_14(struct cell_3* a);
struct arr_8 move_to_arr__e_1(struct mut_arr_3* a);
struct arr_8 cast_immutable_3(struct fix_arr_6 a);
struct fix_arr_6 move_to_fix_arr__e_1(struct mut_arr_3* a);
struct fix_arr_6 fix_arr_11(void);
struct void_ print_help(struct ctx* ctx);
struct opt_12 subscript_66(struct ctx* ctx, struct arr_8 a, uint64_t index);
struct opt_12 unsafe_at_9(struct arr_8 a, uint64_t index);
struct opt_12 subscript_67(struct opt_12* a, uint64_t n);
struct opt_12 _times_15(struct opt_12* a);
struct opt_12* _plus_12(struct opt_12* a, uint64_t offset);
struct opt_11 parse_nat(struct ctx* ctx, struct str a);
struct opt_11 with_reader(struct ctx* ctx, struct str a, struct fun_act1_17 f);
struct reader* reader(struct ctx* ctx, struct str a);
struct opt_11 subscript_68(struct ctx* ctx, struct fun_act1_17 a, struct reader* p0);
struct opt_11 call_w_ctx_788(struct fun_act1_17 a, struct ctx* ctx, struct reader* p0);
uint8_t is_empty_11(struct opt_11 a);
uint8_t is_empty_12(struct ctx* ctx, struct reader* a);
struct opt_11 take_nat__e(struct ctx* ctx, struct reader* a);
struct opt_11 char_to_nat64(struct ctx* ctx, char c);
char peek(struct ctx* ctx, struct reader* a);
struct void_ drop_4(char _p0);
char next__e(struct ctx* ctx, struct reader* a);
uint64_t take_nat_recur__e(struct ctx* ctx, uint64_t acc, struct reader* a);
struct opt_11 parse_nat__lambda0(struct ctx* ctx, struct void_ _closure, struct reader* r);
uint64_t do_test(struct ctx* ctx, struct test_options* options);
struct str parent_path(struct ctx* ctx, struct str a);
struct opt_11 r_index_of(struct ctx* ctx, struct arr_0 a, char value);
struct opt_11 find_rindex(struct ctx* ctx, struct arr_0 a, struct fun_act1_18 f);
struct opt_11 find_rindex_recur(struct ctx* ctx, struct arr_0 a, uint64_t index, struct fun_act1_18 f);
uint8_t subscript_69(struct ctx* ctx, struct fun_act1_18 a, char p0);
uint8_t call_w_ctx_804(struct fun_act1_18 a, struct ctx* ctx, char p0);
char subscript_70(struct ctx* ctx, struct arr_0 a, uint64_t index);
char unsafe_at_10(struct arr_0 a, uint64_t index);
char subscript_71(char* a, uint64_t n);
uint8_t r_index_of__lambda0(struct ctx* ctx, struct r_index_of__lambda0* _closure, char it);
struct str child_path(struct ctx* ctx, struct str a, struct str child_name);
struct dict_1 get_environ(struct ctx* ctx);
struct mut_dict_1* mut_dict_1(struct ctx* ctx);
struct fix_arr_8 fix_arr_12(void);
struct void_ get_environ_recur(struct ctx* ctx, char** env, struct mut_dict_1* res);
char* null_1(void);
struct arrow_1 parse_environ_entry(struct ctx* ctx, char* entry);
struct arrow_1 todo_3(void);
struct arrow_1 _arrow_1(struct str from, struct str to);
struct void_ set_subscript_13(struct ctx* ctx, struct mut_dict_1* a, struct str key, struct str value);
struct void_ drop_5(struct opt_16 _p0);
struct opt_16 update__e_1(struct ctx* ctx, struct mut_dict_1* a, struct str key, struct opt_16 new_value);
uint8_t is_empty_13(struct fix_arr_8 a);
uint64_t size_7(struct fix_arr_8 a);
struct fix_arr_8 fix_arr_13(struct ctx* ctx, struct arr_14 a);
struct fix_arr_8 make_fix_arr_3(struct ctx* ctx, uint64_t size, struct fun_act1_19 f);
struct fix_arr_8 uninitialized_fix_arr_5(struct ctx* ctx, uint64_t size);
struct fix_arr_8 fix_arr_14(uint64_t size, struct entry_1* begin_ptr);
struct entry_1* alloc_uninitialized_6(struct ctx* ctx, uint64_t size);
struct void_ fill_ptr_range_4(struct ctx* ctx, struct entry_1* begin, uint64_t size, struct fun_act1_19 f);
struct void_ fill_ptr_range_recur_4(struct ctx* ctx, struct entry_1* begin, uint64_t i, uint64_t size, struct fun_act1_19 f);
struct void_ set_subscript_14(struct entry_1* a, uint64_t n, struct entry_1 value);
struct entry_1 subscript_72(struct ctx* ctx, struct fun_act1_19 a, uint64_t p0);
struct entry_1 call_w_ctx_832(struct fun_act1_19 a, struct ctx* ctx, uint64_t p0);
struct entry_1* begin_ptr_10(struct fix_arr_8 a);
struct entry_1 subscript_73(struct ctx* ctx, struct arr_14 a, uint64_t index);
struct entry_1 unsafe_at_11(struct arr_14 a, uint64_t index);
struct entry_1 subscript_74(struct entry_1* a, uint64_t n);
struct entry_1 _times_16(struct entry_1* a);
struct entry_1* _plus_13(struct entry_1* a, uint64_t offset);
struct entry_1 fix_arr_13__lambda0(struct ctx* ctx, struct fix_arr_13__lambda0* _closure, uint64_t i);
struct entry_1 subscript_75(struct ctx* ctx, struct fix_arr_8 a, uint64_t index);
struct entry_1 unsafe_at_12(struct ctx* ctx, struct fix_arr_8 a, uint64_t index);
struct entry_1 subscript_76(struct entry_1* a, uint64_t n);
struct void_ set_subscript_15(struct ctx* ctx, struct fix_arr_8 a, uint64_t index, struct entry_1 value);
struct void_ unsafe_set_at__e_2(struct ctx* ctx, struct fix_arr_8 a, uint64_t index, struct entry_1 value);
uint8_t should_expand_1(struct ctx* ctx, struct mut_dict_1* a);
struct void_ expand__e_1(struct ctx* ctx, struct mut_dict_1* a);
struct mut_dict_1* mut_dict_with_capacity_1(struct ctx* ctx, uint64_t capacity);
struct fix_arr_8 fill_fix_arr_3(struct ctx* ctx, uint64_t size, struct entry_1 value);
struct entry_1 fill_fix_arr_3__lambda0(struct ctx* ctx, struct fill_fix_arr_3__lambda0* _closure, uint64_t ignore);
struct void_ each_5(struct ctx* ctx, struct mut_dict_1* a, struct fun_act2_10 f);
struct void_ fold_14(struct ctx* ctx, struct void_ acc, struct mut_dict_1* a, struct fun_act3_3 f);
struct void_ fold_15(struct ctx* ctx, struct void_ acc, struct fix_arr_8 a, struct fun_act2_11 f);
struct void_ fold_16(struct ctx* ctx, struct void_ acc, struct arr_14 a, struct fun_act2_11 f);
struct void_ fold_recur_8(struct ctx* ctx, struct void_ acc, struct entry_1* cur, struct entry_1* end, struct fun_act2_11 f);
uint8_t _equal_10(struct entry_1* a, struct entry_1* b);
struct void_ subscript_77(struct ctx* ctx, struct fun_act2_11 a, struct void_ p0, struct entry_1 p1);
struct void_ call_w_ctx_857(struct fun_act2_11 a, struct ctx* ctx, struct void_ p0, struct entry_1 p1);
struct entry_1* end_ptr_8(struct arr_14 a);
struct arr_14 temp_as_arr_5(struct fix_arr_8 a);
struct void_ subscript_78(struct ctx* ctx, struct fun_act3_3 a, struct void_ p0, struct str p1, struct str p2);
struct void_ call_w_ctx_861(struct fun_act3_3 a, struct ctx* ctx, struct void_ p0, struct str p1, struct str p2);
struct void_ fold_17(struct ctx* ctx, struct void_ acc, struct mut_arr_4* a, struct fun_act2_12 f);
struct void_ fold_18(struct ctx* ctx, struct void_ acc, struct arr_13 a, struct fun_act2_12 f);
struct void_ fold_recur_9(struct ctx* ctx, struct void_ acc, struct arrow_1* cur, struct arrow_1* end, struct fun_act2_12 f);
uint8_t _equal_11(struct arrow_1* a, struct arrow_1* b);
struct void_ subscript_79(struct ctx* ctx, struct fun_act2_12 a, struct void_ p0, struct arrow_1 p1);
struct void_ call_w_ctx_867(struct fun_act2_12 a, struct ctx* ctx, struct void_ p0, struct arrow_1 p1);
struct arrow_1 _times_17(struct arrow_1* a);
struct arrow_1* _plus_14(struct arrow_1* a, uint64_t offset);
struct arrow_1* end_ptr_9(struct arr_13 a);
struct arr_13 temp_as_arr_6(struct mut_arr_4* a);
struct arr_13 temp_as_arr_7(struct fix_arr_7 a);
struct fix_arr_7 temp_as_fix_arr_2(struct mut_arr_4* a);
struct fix_arr_7 fix_arr_15(uint64_t size, struct arrow_1* begin_ptr);
struct arrow_1* begin_ptr_11(struct mut_arr_4* a);
struct arrow_1* begin_ptr_12(struct fix_arr_7 a);
struct void_ fold_14__lambda0__lambda0(struct ctx* ctx, struct fold_14__lambda0__lambda0* _closure, struct void_ cur2, struct arrow_1 pair);
struct void_ fold_14__lambda0(struct ctx* ctx, struct fold_14__lambda0* _closure, struct void_ cur, struct entry_1 entry);
struct void_ subscript_80(struct ctx* ctx, struct fun_act2_10 a, struct str p0, struct str p1);
struct void_ call_w_ctx_880(struct fun_act2_10 a, struct ctx* ctx, struct str p0, struct str p1);
struct void_ each_5__lambda0(struct ctx* ctx, struct each_5__lambda0* _closure, struct void_ ignore, struct str key, struct str value);
struct void_ expand__e_1__lambda0(struct ctx* ctx, struct expand__e_1__lambda0* _closure, struct str key, struct str value);
struct void_ swap__e_2(struct ctx* ctx, struct mut_dict_1* a, struct mut_dict_1* b);
struct mut_arr_4* mut_arr_3(struct ctx* ctx, struct arr_13 a);
struct mut_arr_4* mut_arr_4(struct ctx* ctx);
struct fix_arr_7 fix_arr_16(void);
struct void_ _concatEquals_6(struct ctx* ctx, struct mut_arr_4* a, struct arr_13 values);
struct void_ each_6(struct ctx* ctx, struct arr_13 a, struct fun_act1_20 f);
struct void_ each_recur_3(struct ctx* ctx, struct arrow_1* cur, struct arrow_1* end, struct fun_act1_20 f);
uint8_t _notEqual_11(struct arrow_1* a, struct arrow_1* b);
struct void_ subscript_81(struct ctx* ctx, struct fun_act1_20 a, struct arrow_1 p0);
struct void_ call_w_ctx_892(struct fun_act1_20 a, struct ctx* ctx, struct arrow_1 p0);
struct void_ _concatEquals_7(struct ctx* ctx, struct mut_arr_4* a, struct arrow_1 value);
struct void_ incr_capacity__e_2(struct ctx* ctx, struct mut_arr_4* a);
struct void_ ensure_capacity_2(struct ctx* ctx, struct mut_arr_4* a, uint64_t min_capacity);
uint64_t capacity_3(struct mut_arr_4* a);
uint64_t size_8(struct fix_arr_7 a);
struct void_ increase_capacity_to__e_2(struct ctx* ctx, struct mut_arr_4* a, uint64_t new_capacity);
struct fix_arr_7 uninitialized_fix_arr_6(struct ctx* ctx, uint64_t size);
struct arrow_1* alloc_uninitialized_7(struct ctx* ctx, uint64_t size);
struct void_ copy_data_from__e_4(struct ctx* ctx, struct arrow_1* to, struct arrow_1* from, uint64_t len);
uint8_t* as_any_const_ptr_4(struct arrow_1* ref);
struct void_ set_zero_elements_2(struct fix_arr_7 a);
struct void_ set_zero_range_3(struct arrow_1* begin, uint64_t size);
struct fix_arr_7 subscript_82(struct ctx* ctx, struct fix_arr_7 a, struct range range);
struct arr_13 subscript_83(struct ctx* ctx, struct arr_13 a, struct range range);
struct void_ set_subscript_16(struct arrow_1* a, uint64_t n, struct arrow_1 value);
struct void_ _concatEquals_6__lambda0(struct ctx* ctx, struct _concatEquals_6__lambda0* _closure, struct arrow_1 x);
struct opt_11 find_index_4(struct ctx* ctx, struct mut_arr_4* a, struct fun_act1_21 f);
struct opt_11 find_index_5(struct ctx* ctx, struct arr_13 a, struct fun_act1_21 f);
struct opt_11 find_index_recur_3(struct ctx* ctx, struct arr_13 a, uint64_t index, struct fun_act1_21 f);
uint8_t subscript_84(struct ctx* ctx, struct fun_act1_21 a, struct arrow_1 p0);
uint8_t call_w_ctx_913(struct fun_act1_21 a, struct ctx* ctx, struct arrow_1 p0);
struct arrow_1 subscript_85(struct ctx* ctx, struct arr_13 a, uint64_t index);
struct arrow_1 unsafe_at_13(struct arr_13 a, uint64_t index);
struct arrow_1 subscript_86(struct arrow_1* a, uint64_t n);
uint8_t update__e_1__lambda0(struct ctx* ctx, struct update__e_1__lambda0* _closure, struct arrow_1 pair);
uint8_t is_at_capacity_1(struct mut_arr_4* a);
struct arrow_1 subscript_87(struct ctx* ctx, struct mut_arr_4* a, uint64_t index);
struct arrow_1 subscript_88(struct arrow_1* a, uint64_t n);
struct void_ drop_6(struct arrow_1 _p0);
struct arrow_1 remove_unordered_at__e_1(struct ctx* ctx, struct mut_arr_4* a, uint64_t index);
struct arrow_1 noctx_remove_unordered_at__e_2(struct mut_arr_4* a, uint64_t index);
uint8_t is_empty_14(struct mut_arr_4* a);
struct void_ set_subscript_17(struct ctx* ctx, struct mut_arr_4* a, uint64_t index, struct arrow_1 value);
extern char** environ;
struct dict_1 move_to_dict__e_1(struct ctx* ctx, struct mut_dict_1* a);
struct dict_1 dict_2(struct ctx* ctx, struct arr_13 a);
uint8_t no_duplicate_keys_1(struct ctx* ctx, struct arr_13 a);
uint8_t every_2(struct ctx* ctx, struct arr_13 a, struct fun_act1_21 f);
uint8_t is_empty_15(struct arr_13 a);
struct arr_13 tail_4(struct ctx* ctx, struct arr_13 a);
uint8_t no_duplicate_keys_1__lambda0(struct ctx* ctx, struct no_duplicate_keys_1__lambda0* _closure, struct arrow_1 it);
struct dict_1 fold_19(struct ctx* ctx, struct dict_1 acc, struct arr_13 a, struct fun_act2_13 f);
struct dict_1 fold_recur_10(struct ctx* ctx, struct dict_1 acc, struct arrow_1* cur, struct arrow_1* end, struct fun_act2_13 f);
struct dict_1 subscript_89(struct ctx* ctx, struct fun_act2_13 a, struct dict_1 p0, struct arrow_1 p1);
struct dict_1 call_w_ctx_937(struct fun_act2_13 a, struct ctx* ctx, struct dict_1 p0, struct arrow_1 p1);
struct dict_1 dict_3(struct ctx* ctx);
struct leaf_node_1 empty_leaf_node_1(struct ctx* ctx);
struct dict_1 _tilde_5(struct ctx* ctx, struct dict_1 a, struct arrow_1 pair);
struct get_or_update_result_1 get_or_update_1(struct ctx* ctx, struct dict_1 a, struct str key, struct fun_act1_22 f);
struct get_or_update_result_1 get_or_update_recur_1(struct ctx* ctx, struct node_1 a, struct str key, uint64_t remaining_hash, uint64_t hash_shift, struct fun_act1_22 f);
struct node_1 subscript_90(struct ctx* ctx, struct arr_12 a, uint64_t index);
struct node_1 unsafe_at_14(struct arr_12 a, uint64_t index);
struct node_1 subscript_91(struct node_1* a, uint64_t n);
struct node_1 _times_18(struct node_1* a);
struct node_1* _plus_15(struct node_1* a, uint64_t offset);
struct node_1 update_child_1(struct ctx* ctx, struct inner_node_1 a, uint64_t which, struct node_1 new_child);
struct opt_20 inner_node_to_leaf_1(struct ctx* ctx, struct inner_node_1 a, uint64_t which, struct node_1 new_child);
uint64_t fold_with_index_1(struct ctx* ctx, uint64_t acc, struct arr_12 a, struct fun_act3_4 f);
uint64_t fold_with_index_recur_1(struct ctx* ctx, uint64_t acc, uint64_t index, struct node_1* cur, struct node_1* end, struct fun_act3_4 f);
uint8_t _equal_12(struct node_1* a, struct node_1* b);
uint64_t subscript_92(struct ctx* ctx, struct fun_act3_4 a, uint64_t p0, struct node_1 p1, uint64_t p2);
uint64_t call_w_ctx_954(struct fun_act3_4 a, struct ctx* ctx, uint64_t p0, struct node_1 p1, uint64_t p2);
struct node_1* end_ptr_10(struct arr_12 a);
uint64_t inner_node_to_leaf_1__lambda0(struct ctx* ctx, struct inner_node_to_leaf_1__lambda0* _closure, uint64_t cur, struct node_1 child, uint64_t child_index);
struct void_ copy_from__e_1(struct ctx* ctx, struct fix_arr_7 dest, struct arr_13 source);
uint64_t inner_node_to_leaf_1__lambda1(struct ctx* ctx, struct inner_node_to_leaf_1__lambda1* _closure, uint64_t out_index, struct node_1 child, uint64_t child_index);
struct arr_13 cast_immutable_4(struct fix_arr_7 a);
uint8_t node_is_empty_1(struct ctx* ctx, struct node_1 a);
struct arr_12 rtail_1(struct ctx* ctx, struct arr_12 a);
uint8_t is_empty_16(struct arr_12 a);
struct arr_12 subscript_93(struct ctx* ctx, struct arr_12 a, struct range range);
struct arr_12 update_2(struct ctx* ctx, struct arr_12 a, uint64_t index, struct node_1 new_value);
struct arr_12 _tilde_6(struct ctx* ctx, struct arr_12 a, struct arr_12 b);
struct node_1* alloc_uninitialized_8(struct ctx* ctx, uint64_t size);
struct void_ copy_data_from__e_5(struct ctx* ctx, struct node_1* to, struct node_1* from, uint64_t len);
uint8_t* as_any_const_ptr_5(struct node_1* ref);
struct opt_19 find_only_non_empty_child_1(struct ctx* ctx, struct arr_12 children);
struct opt_11 find_index_6(struct ctx* ctx, struct arr_12 a, struct fun_act1_23 f);
struct opt_11 find_index_recur_4(struct ctx* ctx, struct arr_12 a, uint64_t index, struct fun_act1_23 f);
uint8_t subscript_94(struct ctx* ctx, struct fun_act1_23 a, struct node_1 p0);
uint8_t call_w_ctx_973(struct fun_act1_23 a, struct ctx* ctx, struct node_1 p0);
uint8_t find_only_non_empty_child_1__lambda0(struct ctx* ctx, struct void_ _closure, struct node_1 it);
uint8_t every_3(struct ctx* ctx, struct arr_12 a, struct fun_act1_23 f);
struct arr_12 tail_5(struct ctx* ctx, struct arr_12 a);
uint8_t find_only_non_empty_child_1__lambda1(struct ctx* ctx, struct void_ _closure, struct node_1 it);
struct get_or_update_action_1 subscript_95(struct ctx* ctx, struct fun_act1_22 a, struct opt_16 p0);
struct get_or_update_action_1 call_w_ctx_979(struct fun_act1_22 a, struct ctx* ctx, struct opt_16 p0);
struct arr_12 update_with_default_1(struct ctx* ctx, struct arr_12 a, uint64_t index, struct node_1 new_value, struct node_1 _default);
struct arr_12 make_arr_2(struct ctx* ctx, uint64_t size, struct fun_act1_24 f);
struct void_ fill_ptr_range_5(struct ctx* ctx, struct node_1* begin, uint64_t size, struct fun_act1_24 f);
struct void_ fill_ptr_range_recur_5(struct ctx* ctx, struct node_1* begin, uint64_t i, uint64_t size, struct fun_act1_24 f);
struct void_ set_subscript_18(struct node_1* a, uint64_t n, struct node_1 value);
struct node_1 subscript_96(struct ctx* ctx, struct fun_act1_24 a, uint64_t p0);
struct node_1 call_w_ctx_986(struct fun_act1_24 a, struct ctx* ctx, uint64_t p0);
struct node_1 update_with_default_1__lambda0(struct ctx* ctx, struct update_with_default_1__lambda0* _closure, uint64_t i);
struct get_or_update_result_1 get_or_update_leaf_1(struct ctx* ctx, struct leaf_node_1 a, struct str key, uint64_t remaining_hash, uint64_t hash_shift, struct fun_act1_22 f);
uint8_t get_or_update_leaf_1__lambda0(struct ctx* ctx, struct get_or_update_leaf_1__lambda0* _closure, struct arrow_1 it);
struct inner_node_1 new_inner_node_1(struct ctx* ctx, struct leaf_node_1 a, struct str key, struct str value, uint64_t hash, uint64_t hash_shift);
uint64_t fold_20(struct ctx* ctx, uint64_t acc, struct arr_13 a, struct fun_act2_14 f);
uint64_t fold_recur_11(struct ctx* ctx, uint64_t acc, struct arrow_1* cur, struct arrow_1* end, struct fun_act2_14 f);
uint64_t subscript_97(struct ctx* ctx, struct fun_act2_14 a, uint64_t p0, struct arrow_1 p1);
uint64_t call_w_ctx_994(struct fun_act2_14 a, struct ctx* ctx, uint64_t p0, struct arrow_1 p1);
uint64_t new_inner_node_1__lambda0(struct ctx* ctx, struct new_inner_node_1__lambda0* _closure, uint64_t cur, struct arrow_1 pair);
struct fix_arr_9 fill_fix_arr_4(struct ctx* ctx, uint64_t size, struct node_1 value);
struct fix_arr_9 make_fix_arr_4(struct ctx* ctx, uint64_t size, struct fun_act1_24 f);
struct fix_arr_9 uninitialized_fix_arr_7(struct ctx* ctx, uint64_t size);
struct fix_arr_9 fix_arr_17(uint64_t size, struct node_1* begin_ptr);
struct node_1* begin_ptr_13(struct fix_arr_9 a);
struct node_1 fill_fix_arr_4__lambda0(struct ctx* ctx, struct fill_fix_arr_4__lambda0* _closure, uint64_t ignore);
struct void_ set_subscript_19(struct ctx* ctx, struct fix_arr_9 a, uint64_t index, struct node_1 value);
uint64_t size_9(struct fix_arr_9 a);
struct void_ unsafe_set_at__e_3(struct ctx* ctx, struct fix_arr_9 a, uint64_t index, struct node_1 value);
struct node_1 subscript_98(struct ctx* ctx, struct fix_arr_9 a, uint64_t index);
struct node_1 unsafe_at_15(struct ctx* ctx, struct fix_arr_9 a, uint64_t index);
struct node_1 subscript_99(struct node_1* a, uint64_t n);
struct node_1 unreachable_2(struct ctx* ctx);
struct node_1 throw_8(struct ctx* ctx, struct str message);
struct node_1 throw_9(struct ctx* ctx, struct exception e);
struct node_1 hard_unreachable_5(void);
struct arr_13 _tilde_7(struct ctx* ctx, struct arr_13 a, struct arr_13 b);
struct void_ new_inner_node_1__lambda1(struct ctx* ctx, struct new_inner_node_1__lambda1* _closure, struct arrow_1 pair);
struct arr_12 cast_immutable_5(struct fix_arr_9 a);
struct arr_13 remove_at_1(struct ctx* ctx, struct arr_13 a, uint64_t index);
struct arr_13 update_3(struct ctx* ctx, struct arr_13 a, uint64_t index, struct arrow_1 new_value);
struct get_or_update_action_1 _tilde_5__lambda0(struct ctx* ctx, struct _tilde_5__lambda0* _closure, struct opt_16 old_value);
struct dict_1 dict_2__lambda0(struct ctx* ctx, struct void_ _closure, struct dict_1 cur, struct arrow_1 x);
struct arr_13 map_to_arr_1(struct ctx* ctx, struct mut_dict_1* a, struct fun_act2_15 f);
uint64_t size_10(struct ctx* ctx, struct mut_dict_1* a);
struct arrow_1* fold_21(struct ctx* ctx, struct arrow_1* acc, struct mut_dict_1* a, struct fun_act3_5 f);
struct arrow_1* fold_22(struct ctx* ctx, struct arrow_1* acc, struct fix_arr_8 a, struct fun_act2_16 f);
struct arrow_1* fold_23(struct ctx* ctx, struct arrow_1* acc, struct arr_14 a, struct fun_act2_16 f);
struct arrow_1* fold_recur_12(struct ctx* ctx, struct arrow_1* acc, struct entry_1* cur, struct entry_1* end, struct fun_act2_16 f);
struct arrow_1* subscript_100(struct ctx* ctx, struct fun_act2_16 a, struct arrow_1* p0, struct entry_1 p1);
struct arrow_1* call_w_ctx_1026(struct fun_act2_16 a, struct ctx* ctx, struct arrow_1* p0, struct entry_1 p1);
struct arrow_1* subscript_101(struct ctx* ctx, struct fun_act3_5 a, struct arrow_1* p0, struct str p1, struct str p2);
struct arrow_1* call_w_ctx_1028(struct fun_act3_5 a, struct ctx* ctx, struct arrow_1* p0, struct str p1, struct str p2);
struct arrow_1* fold_24(struct ctx* ctx, struct arrow_1* acc, struct mut_arr_4* a, struct fun_act2_17 f);
struct arrow_1* fold_25(struct ctx* ctx, struct arrow_1* acc, struct arr_13 a, struct fun_act2_17 f);
struct arrow_1* fold_recur_13(struct ctx* ctx, struct arrow_1* acc, struct arrow_1* cur, struct arrow_1* end, struct fun_act2_17 f);
struct arrow_1* subscript_102(struct ctx* ctx, struct fun_act2_17 a, struct arrow_1* p0, struct arrow_1 p1);
struct arrow_1* call_w_ctx_1033(struct fun_act2_17 a, struct ctx* ctx, struct arrow_1* p0, struct arrow_1 p1);
struct arrow_1* fold_21__lambda0__lambda0(struct ctx* ctx, struct fold_21__lambda0__lambda0* _closure, struct arrow_1* cur2, struct arrow_1 pair);
struct arrow_1* fold_21__lambda0(struct ctx* ctx, struct fold_21__lambda0* _closure, struct arrow_1* cur, struct entry_1 entry);
struct arrow_1 subscript_103(struct ctx* ctx, struct fun_act2_15 a, struct str p0, struct str p1);
struct arrow_1 call_w_ctx_1037(struct fun_act2_15 a, struct ctx* ctx, struct str p0, struct str p1);
struct arrow_1* map_to_arr_1__lambda0(struct ctx* ctx, struct map_to_arr_1__lambda0* _closure, struct arrow_1* cur, struct str key, struct str value);
struct arrow_1* end_ptr_11(struct fix_arr_7 a);
struct arrow_1 move_to_dict__e_1__lambda0(struct ctx* ctx, struct void_ _closure, struct str k, struct str v);
struct void_ empty__e_1(struct ctx* ctx, struct mut_dict_1* a);
struct void_ fill__e_1(struct ctx* ctx, struct fix_arr_8 a, struct entry_1 value);
struct void_ map__e_1(struct ctx* ctx, struct fix_arr_8 a, struct fun_act1_25 f);
struct void_ map_recur__e_1(struct ctx* ctx, struct entry_1* cur, struct entry_1* end, struct fun_act1_25 f);
uint8_t _notEqual_12(struct entry_1* a, struct entry_1* b);
struct entry_1 subscript_104(struct ctx* ctx, struct fun_act1_25 a, struct entry_1 p0);
struct entry_1 call_w_ctx_1047(struct fun_act1_25 a, struct ctx* ctx, struct entry_1 p0);
struct entry_1* end_ptr_12(struct fix_arr_8 a);
struct entry_1 fill__e_1__lambda0(struct ctx* ctx, struct fill__e_1__lambda0* _closure, struct entry_1 ignore);
struct result_2 first_failures(struct ctx* ctx, struct result_2 a, struct fun0 b);
struct result_2 subscript_105(struct ctx* ctx, struct fun0 a);
struct result_2 call_w_ctx_1052(struct fun0 a, struct ctx* ctx);
struct result_2 run_crow_tests(struct ctx* ctx, struct str path, struct str path_to_crow, struct dict_1 env, struct test_options* options);
struct arr_2 list_tests(struct ctx* ctx, struct str path, struct str match_test);
struct mut_arr_5* mut_arr_5(struct ctx* ctx);
struct fix_arr_10 fix_arr_18(void);
struct void_ each_child_recursive_0(struct ctx* ctx, struct str path, struct fun_act1_26 f);
uint8_t each_child_recursive_0__lambda0(struct ctx* ctx, struct void_ _closure, struct str ignore);
struct void_ each_child_recursive_1(struct ctx* ctx, struct str path, struct fun_act1_8 filter, struct fun_act1_26 f);
uint8_t is_dir_0(struct ctx* ctx, struct str path);
uint8_t is_dir_1(struct ctx* ctx, char* path);
struct opt_21 get_stat(struct ctx* ctx, char* path);
struct stat* stat_0(struct ctx* ctx);
extern int32_t stat(char* path, struct stat* buf);
int32_t errno(void);
extern int32_t* __errno_location(void);
int32_t ENOENT(void);
struct opt_21 todo_4(void);
uint8_t throw_10(struct ctx* ctx, struct str message);
uint8_t throw_11(struct ctx* ctx, struct exception e);
uint8_t hard_unreachable_6(void);
struct interp with_value_1(struct ctx* ctx, struct interp a, char* b);
uint32_t S_IFMT(void);
uint32_t S_IFDIR(void);
char* to_c_str(struct ctx* ctx, struct str a);
struct void_ each_7(struct ctx* ctx, struct arr_2 a, struct fun_act1_26 f);
struct void_ each_recur_4(struct ctx* ctx, struct str* cur, struct str* end, struct fun_act1_26 f);
uint8_t _notEqual_13(struct str* a, struct str* b);
struct void_ subscript_106(struct ctx* ctx, struct fun_act1_26 a, struct str p0);
struct void_ call_w_ctx_1080(struct fun_act1_26 a, struct ctx* ctx, struct str p0);
struct arr_2 read_dir_0(struct ctx* ctx, struct str path);
struct arr_2 read_dir_1(struct ctx* ctx, char* path);
extern struct dir* opendir(char* name);
uint8_t _notEqual_14(uint8_t** a, uint8_t** b);
struct void_ read_dir_recur(struct ctx* ctx, struct dir* dirp, struct mut_arr_5* res);
struct bytes256 zero_4(void);
extern int32_t readdir_r(struct dir* dirp, struct dirent* entry, struct cell_4* result);
uint8_t _notEqual_15(uint8_t* a, uint8_t* b);
uint8_t* as_any_const_ptr_6(struct dirent* ref);
struct dirent* _times_19(struct cell_4* a);
uint8_t ref_eq(struct dirent* a, struct dirent* b);
struct str get_dirent_name(struct ctx* ctx, struct dirent* d);
uint8_t* _plus_16(uint8_t* a, uint64_t offset);
char* ptr_cast_1(uint8_t* a);
struct void_ _concatEquals_8(struct ctx* ctx, struct mut_arr_5* a, struct str value);
struct void_ incr_capacity__e_3(struct ctx* ctx, struct mut_arr_5* a);
struct void_ ensure_capacity_3(struct ctx* ctx, struct mut_arr_5* a, uint64_t min_capacity);
uint64_t capacity_4(struct mut_arr_5* a);
uint64_t size_11(struct fix_arr_10 a);
struct void_ increase_capacity_to__e_3(struct ctx* ctx, struct mut_arr_5* a, uint64_t new_capacity);
struct str* begin_ptr_14(struct mut_arr_5* a);
struct str* begin_ptr_15(struct fix_arr_10 a);
struct fix_arr_10 uninitialized_fix_arr_8(struct ctx* ctx, uint64_t size);
struct fix_arr_10 fix_arr_19(uint64_t size, struct str* begin_ptr);
struct void_ copy_data_from__e_6(struct ctx* ctx, struct str* to, struct str* from, uint64_t len);
uint8_t* as_any_const_ptr_7(struct str* ref);
struct void_ set_zero_elements_3(struct fix_arr_10 a);
struct void_ set_zero_range_4(struct str* begin, uint64_t size);
struct fix_arr_10 subscript_107(struct ctx* ctx, struct fix_arr_10 a, struct range range);
struct arr_2 sort_0(struct ctx* ctx, struct arr_2 a);
struct arr_2 sort_1(struct ctx* ctx, struct arr_2 a, struct fun_act2_18 comparer);
struct fix_arr_10 fix_arr_20(struct ctx* ctx, struct arr_2 a);
struct fix_arr_10 make_fix_arr_5(struct ctx* ctx, uint64_t size, struct fun_act1_7 f);
struct str fix_arr_20__lambda0(struct ctx* ctx, struct fix_arr_20__lambda0* _closure, uint64_t i);
struct void_ sort__e_1(struct ctx* ctx, struct fix_arr_10 a, struct fun_act2_18 comparer);
uint8_t is_empty_17(struct fix_arr_10 a);
struct void_ insertion_sort_recur__e(struct ctx* ctx, struct str* begin, struct str* cur, struct str* end, struct fun_act2_18 comparer);
uint8_t _notEqual_16(struct str* a, struct str* b);
struct void_ insert__e(struct ctx* ctx, struct str* begin, struct str* cur, struct str value, struct fun_act2_18 comparer);
uint8_t _equal_13(struct comparison a, struct comparison b);
struct comparison subscript_108(struct ctx* ctx, struct fun_act2_18 a, struct str p0, struct str p1);
struct comparison call_w_ctx_1122(struct fun_act2_18 a, struct ctx* ctx, struct str p0, struct str p1);
struct str* end_ptr_13(struct fix_arr_10 a);
struct arr_2 cast_immutable_6(struct fix_arr_10 a);
struct comparison sort_0__lambda0(struct ctx* ctx, struct void_ _closure, struct str x, struct str y);
struct arr_2 move_to_arr__e_2(struct mut_arr_5* a);
struct fix_arr_10 move_to_fix_arr__e_2(struct mut_arr_5* a);
struct void_ each_child_recursive_1__lambda0(struct ctx* ctx, struct each_child_recursive_1__lambda0* _closure, struct str child_name);
uint8_t has_substr(struct ctx* ctx, struct str a, struct str b);
uint8_t contains_subseq(struct ctx* ctx, struct arr_0 a, struct arr_0 subseq);
struct opt_11 index_of_subseq(struct ctx* ctx, struct arr_0 a, struct arr_0 subseq);
struct opt_11 index_of_subseq_recur(struct ctx* ctx, struct arr_0 a, struct arr_0 subseq, uint64_t i);
uint8_t ext_is_crow(struct ctx* ctx, struct str a);
uint8_t _equal_14(struct opt_16 a, struct opt_16 b);
uint8_t opt_equal(struct opt_16 a, struct opt_16 b);
uint8_t is_empty_18(struct opt_16 a);
struct opt_16 get_extension(struct ctx* ctx, struct str name);
struct opt_11 last_index_of(struct ctx* ctx, struct str a, char c);
struct opt_22 last(struct ctx* ctx, struct arr_0 a);
struct arr_0 rtail_2(struct ctx* ctx, struct arr_0 a);
struct str base_name(struct ctx* ctx, struct str path);
struct void_ list_tests__lambda0(struct ctx* ctx, struct list_tests__lambda0* _closure, struct str child);
struct arr_15 flat_map_with_max_size(struct ctx* ctx, struct arr_2 a, uint64_t max_size, struct fun_act1_27 mapper);
struct mut_arr_6* mut_arr_6(struct ctx* ctx);
struct fix_arr_11 fix_arr_21(void);
struct void_ _concatEquals_9(struct ctx* ctx, struct mut_arr_6* a, struct arr_15 values);
struct void_ each_8(struct ctx* ctx, struct arr_15 a, struct fun_act1_28 f);
struct void_ each_recur_5(struct ctx* ctx, struct failure** cur, struct failure** end, struct fun_act1_28 f);
uint8_t _equal_15(struct failure** a, struct failure** b);
uint8_t _notEqual_17(struct failure** a, struct failure** b);
struct void_ subscript_109(struct ctx* ctx, struct fun_act1_28 a, struct failure* p0);
struct void_ call_w_ctx_1152(struct fun_act1_28 a, struct ctx* ctx, struct failure* p0);
struct failure* _times_20(struct failure** a);
struct failure** _plus_17(struct failure** a, uint64_t offset);
struct failure** end_ptr_14(struct arr_15 a);
struct void_ _concatEquals_10(struct ctx* ctx, struct mut_arr_6* a, struct failure* value);
struct void_ incr_capacity__e_4(struct ctx* ctx, struct mut_arr_6* a);
struct void_ ensure_capacity_4(struct ctx* ctx, struct mut_arr_6* a, uint64_t min_capacity);
uint64_t capacity_5(struct mut_arr_6* a);
uint64_t size_12(struct fix_arr_11 a);
struct void_ increase_capacity_to__e_4(struct ctx* ctx, struct mut_arr_6* a, uint64_t new_capacity);
struct failure** begin_ptr_16(struct mut_arr_6* a);
struct failure** begin_ptr_17(struct fix_arr_11 a);
struct fix_arr_11 uninitialized_fix_arr_9(struct ctx* ctx, uint64_t size);
struct fix_arr_11 fix_arr_22(uint64_t size, struct failure** begin_ptr);
struct failure** alloc_uninitialized_9(struct ctx* ctx, uint64_t size);
struct void_ copy_data_from__e_7(struct ctx* ctx, struct failure** to, struct failure** from, uint64_t len);
uint8_t* as_any_const_ptr_8(struct failure** ref);
struct void_ set_zero_elements_4(struct fix_arr_11 a);
struct void_ set_zero_range_5(struct failure** begin, uint64_t size);
struct fix_arr_11 subscript_110(struct ctx* ctx, struct fix_arr_11 a, struct range range);
struct arr_15 subscript_111(struct ctx* ctx, struct arr_15 a, struct range range);
struct void_ set_subscript_20(struct failure** a, uint64_t n, struct failure* value);
struct void_ _concatEquals_9__lambda0(struct ctx* ctx, struct _concatEquals_9__lambda0* _closure, struct failure* x);
struct arr_15 subscript_112(struct ctx* ctx, struct fun_act1_27 a, struct str p0);
struct arr_15 call_w_ctx_1176(struct fun_act1_27 a, struct ctx* ctx, struct str p0);
struct void_ reduce_size_if_more_than__e(struct ctx* ctx, struct mut_arr_6* a, uint64_t new_size);
struct void_ drop_7(struct opt_23 _p0);
struct opt_23 pop__e(struct ctx* ctx, struct mut_arr_6* a);
uint8_t is_empty_19(struct mut_arr_6* a);
struct failure* subscript_113(struct ctx* ctx, struct mut_arr_6* a, uint64_t index);
struct failure* subscript_114(struct failure** a, uint64_t n);
struct void_ set_subscript_21(struct ctx* ctx, struct mut_arr_6* a, uint64_t index, struct failure* value);
struct void_ flat_map_with_max_size__lambda0(struct ctx* ctx, struct flat_map_with_max_size__lambda0* _closure, struct str x);
struct arr_15 move_to_arr__e_3(struct mut_arr_6* a);
struct arr_15 cast_immutable_7(struct fix_arr_11 a);
struct fix_arr_11 move_to_fix_arr__e_3(struct mut_arr_6* a);
struct arr_15 run_single_crow_test(struct ctx* ctx, struct str path_to_crow, struct dict_1 env, struct str path, struct test_options* options);
struct opt_24 first_some(struct ctx* ctx, struct arr_2 a, struct fun_act1_29 f);
struct opt_24 subscript_115(struct ctx* ctx, struct fun_act1_29 a, struct str p0);
struct opt_24 call_w_ctx_1191(struct fun_act1_29 a, struct ctx* ctx, struct str p0);
uint8_t is_empty_20(struct opt_24 a);
struct print_test_result* run_print_test(struct ctx* ctx, struct str print_kind, struct str path_to_crow, struct dict_1 env, struct str path, uint8_t overwrite_output);
struct process_result* spawn_and_wait_result_0(struct ctx* ctx, struct str exe, struct arr_2 args, struct dict_1 environ);
struct str fold_26(struct ctx* ctx, struct str acc, struct arr_2 a, struct fun_act2_19 f);
struct str fold_recur_14(struct ctx* ctx, struct str acc, struct str* cur, struct str* end, struct fun_act2_19 f);
struct str subscript_116(struct ctx* ctx, struct fun_act2_19 a, struct str p0, struct str p1);
struct str call_w_ctx_1198(struct fun_act2_19 a, struct ctx* ctx, struct str p0, struct str p1);
struct str spawn_and_wait_result_0__lambda0(struct ctx* ctx, struct void_ _closure, struct str a, struct str b);
uint8_t is_file_0(struct ctx* ctx, struct str path);
uint8_t is_file_1(struct ctx* ctx, char* path);
uint32_t S_IFREG(void);
struct process_result* spawn_and_wait_result_1(struct ctx* ctx, char* exe, char** args, char** environ);
struct pipes* make_pipes(struct ctx* ctx);
struct void_ check_posix_error(struct ctx* ctx, int32_t e);
extern int32_t pipe(struct pipes* pipes);
extern int32_t posix_spawn_file_actions_init(struct posix_spawn_file_actions_t* file_actions);
extern int32_t posix_spawn_file_actions_addclose(struct posix_spawn_file_actions_t* file_actions, int32_t fd);
extern int32_t posix_spawn_file_actions_adddup2(struct posix_spawn_file_actions_t* file_actions, int32_t fd, int32_t new_fd);
extern int32_t posix_spawn(struct cell_5* pid, char* executable_path, struct posix_spawn_file_actions_t* file_actions, uint8_t* attrp, char** argv, char** environ);
int32_t _times_21(struct cell_5* a);
extern int32_t close(int32_t fd);
struct void_ keep_polling(struct ctx* ctx, int32_t stdout_pipe, int32_t stderr_pipe, struct mut_arr_1* stdout_builder, struct mut_arr_1* stderr_builder);
struct fix_arr_12 fix_arr_23(struct ctx* ctx, struct arr_16 a);
struct fix_arr_12 make_fix_arr_6(struct ctx* ctx, uint64_t size, struct fun_act1_30 f);
struct fix_arr_12 uninitialized_fix_arr_10(struct ctx* ctx, uint64_t size);
struct fix_arr_12 fix_arr_24(uint64_t size, struct pollfd* begin_ptr);
struct pollfd* alloc_uninitialized_10(struct ctx* ctx, uint64_t size);
struct void_ fill_ptr_range_6(struct ctx* ctx, struct pollfd* begin, uint64_t size, struct fun_act1_30 f);
struct void_ fill_ptr_range_recur_6(struct ctx* ctx, struct pollfd* begin, uint64_t i, uint64_t size, struct fun_act1_30 f);
struct void_ set_subscript_22(struct pollfd* a, uint64_t n, struct pollfd value);
struct pollfd subscript_117(struct ctx* ctx, struct fun_act1_30 a, uint64_t p0);
struct pollfd call_w_ctx_1223(struct fun_act1_30 a, struct ctx* ctx, uint64_t p0);
struct pollfd* begin_ptr_18(struct fix_arr_12 a);
struct pollfd subscript_118(struct ctx* ctx, struct arr_16 a, uint64_t index);
struct pollfd unsafe_at_16(struct arr_16 a, uint64_t index);
struct pollfd subscript_119(struct pollfd* a, uint64_t n);
struct pollfd _times_22(struct pollfd* a);
struct pollfd* _plus_18(struct pollfd* a, uint64_t offset);
struct pollfd fix_arr_23__lambda0(struct ctx* ctx, struct fix_arr_23__lambda0* _closure, uint64_t i);
int16_t POLLIN(struct ctx* ctx);
struct pollfd* ref_of_val_at(struct ctx* ctx, struct fix_arr_12 a, uint64_t index);
uint64_t size_13(struct fix_arr_12 a);
struct pollfd* ref_of_ptr(struct pollfd* p);
extern int32_t poll(struct pollfd* fds, uint64_t nfds, int32_t timeout);
struct handle_revents_result handle_revents(struct ctx* ctx, struct pollfd* pollfd, struct mut_arr_1* builder);
uint8_t has_POLLIN(struct ctx* ctx, int16_t revents);
uint8_t bits_intersect(int16_t a, int16_t b);
uint8_t _notEqual_18(int16_t a, int16_t b);
struct void_ read_to_buffer_until_eof(struct ctx* ctx, int32_t fd, struct mut_arr_1* buffer);
struct void_ unsafe_set_size__e(struct ctx* ctx, struct mut_arr_1* a, uint64_t new_size);
struct void_ reserve(struct ctx* ctx, struct mut_arr_1* a, uint64_t reserved);
extern int64_t read(int32_t fd, uint8_t* buff, uint64_t n_bytes);
uint64_t to_nat64_0(struct ctx* ctx, int64_t a);
struct comparison _compare_11(int64_t a, int64_t b);
struct comparison cmp_2(int64_t a, int64_t b);
uint8_t _less_6(int64_t a, int64_t b);
uint8_t has_POLLHUP(struct ctx* ctx, int16_t revents);
int16_t POLLHUP(struct ctx* ctx);
uint8_t has_POLLPRI(struct ctx* ctx, int16_t revents);
int16_t POLLPRI(struct ctx* ctx);
uint8_t has_POLLOUT(struct ctx* ctx, int16_t revents);
int16_t POLLOUT(struct ctx* ctx);
uint8_t has_POLLERR(struct ctx* ctx, int16_t revents);
int16_t POLLERR(struct ctx* ctx);
uint8_t has_POLLNVAL(struct ctx* ctx, int16_t revents);
int16_t POLLNVAL(struct ctx* ctx);
uint64_t to_nat64_1(uint8_t a);
uint8_t any(struct ctx* ctx, struct handle_revents_result r);
int32_t wait_and_get_exit_code(struct ctx* ctx, int32_t pid);
extern int32_t waitpid(int32_t pid, struct cell_5* wait_status, int32_t options);
uint8_t WIFEXITED(struct ctx* ctx, int32_t status);
int32_t WTERMSIG(struct ctx* ctx, int32_t status);
int32_t WEXITSTATUS(struct ctx* ctx, int32_t status);
int32_t _shiftRight(int32_t a, int32_t b);
struct comparison _compare_12(int32_t a, int32_t b);
struct comparison cmp_3(int32_t a, int32_t b);
uint8_t _less_7(int32_t a, int32_t b);
int32_t todo_5(void);
uint8_t WIFSIGNALED(struct ctx* ctx, int32_t status);
struct str to_str_4(struct ctx* ctx, int32_t a);
struct str to_str_5(struct ctx* ctx, int64_t a);
struct str to_str_6(struct ctx* ctx, uint64_t a);
struct str to_base(struct ctx* ctx, uint64_t a, uint64_t base);
struct str digit_to_str(struct ctx* ctx, uint64_t a);
uint64_t mod(struct ctx* ctx, uint64_t a, uint64_t b);
uint64_t abs(struct ctx* ctx, int64_t a);
int64_t _minus_8(struct ctx* ctx, int64_t a);
int64_t _times_23(struct ctx* ctx, int64_t a, int64_t b);
struct interp with_value_2(struct ctx* ctx, struct interp a, int32_t b);
uint8_t WIFSTOPPED(struct ctx* ctx, int32_t status);
uint8_t WIFCONTINUED(struct ctx* ctx, int32_t status);
char** convert_args(struct ctx* ctx, char* exe_c_str, struct arr_2 args);
struct arr_7 _tilde_8(struct ctx* ctx, struct arr_7 a, struct arr_7 b);
char** alloc_uninitialized_11(struct ctx* ctx, uint64_t size);
struct void_ copy_data_from__e_8(struct ctx* ctx, char** to, char** from, uint64_t len);
uint8_t* as_any_const_ptr_9(char** ref);
struct arr_7 map_1(struct ctx* ctx, struct arr_2 a, struct fun_act1_31 f);
struct arr_7 make_arr_3(struct ctx* ctx, uint64_t size, struct fun_act1_32 f);
struct void_ fill_ptr_range_7(struct ctx* ctx, char** begin, uint64_t size, struct fun_act1_32 f);
struct void_ fill_ptr_range_recur_7(struct ctx* ctx, char** begin, uint64_t i, uint64_t size, struct fun_act1_32 f);
struct void_ set_subscript_23(char** a, uint64_t n, char* value);
char* subscript_120(struct ctx* ctx, struct fun_act1_32 a, uint64_t p0);
char* call_w_ctx_1294(struct fun_act1_32 a, struct ctx* ctx, uint64_t p0);
char* subscript_121(struct ctx* ctx, struct fun_act1_31 a, struct str p0);
char* call_w_ctx_1296(struct fun_act1_31 a, struct ctx* ctx, struct str p0);
char* map_1__lambda0(struct ctx* ctx, struct map_1__lambda0* _closure, uint64_t i);
char* convert_args__lambda0(struct ctx* ctx, struct void_ _closure, struct str x);
char** convert_environ(struct ctx* ctx, struct dict_1 environ);
struct mut_arr_7* mut_arr_7(struct ctx* ctx);
struct fix_arr_13 fix_arr_25(void);
struct void_ each_9(struct ctx* ctx, struct dict_1 a, struct fun_act2_10 f);
struct void_ fold_27(struct ctx* ctx, struct void_ acc, struct dict_1 a, struct fun_act3_3 f);
struct void_ fold_recur_15(struct ctx* ctx, struct void_ acc, struct node_1 a, struct fun_act3_3 f);
struct void_ fold_28(struct ctx* ctx, struct void_ acc, struct arr_12 a, struct fun_act2_20 f);
struct void_ fold_recur_16(struct ctx* ctx, struct void_ acc, struct node_1* cur, struct node_1* end, struct fun_act2_20 f);
struct void_ subscript_122(struct ctx* ctx, struct fun_act2_20 a, struct void_ p0, struct node_1 p1);
struct void_ call_w_ctx_1308(struct fun_act2_20 a, struct ctx* ctx, struct void_ p0, struct node_1 p1);
struct void_ fold_recur_15__lambda0(struct ctx* ctx, struct fold_recur_15__lambda0* _closure, struct void_ cur, struct node_1 child);
struct void_ fold_recur_15__lambda1(struct ctx* ctx, struct fold_recur_15__lambda1* _closure, struct void_ cur, struct arrow_1 pair);
struct void_ each_9__lambda0(struct ctx* ctx, struct each_9__lambda0* _closure, struct void_ ignore, struct str key, struct str value);
struct void_ _concatEquals_11(struct ctx* ctx, struct mut_arr_7* a, char* value);
struct void_ incr_capacity__e_5(struct ctx* ctx, struct mut_arr_7* a);
struct void_ ensure_capacity_5(struct ctx* ctx, struct mut_arr_7* a, uint64_t min_capacity);
uint64_t capacity_6(struct mut_arr_7* a);
uint64_t size_14(struct fix_arr_13 a);
struct void_ increase_capacity_to__e_5(struct ctx* ctx, struct mut_arr_7* a, uint64_t new_capacity);
char** begin_ptr_19(struct mut_arr_7* a);
char** begin_ptr_20(struct fix_arr_13 a);
struct fix_arr_13 uninitialized_fix_arr_11(struct ctx* ctx, uint64_t size);
struct fix_arr_13 fix_arr_26(uint64_t size, char** begin_ptr);
struct void_ set_zero_elements_5(struct fix_arr_13 a);
struct void_ set_zero_range_6(char** begin, uint64_t size);
struct fix_arr_13 subscript_123(struct ctx* ctx, struct fix_arr_13 a, struct range range);
struct void_ convert_environ__lambda0(struct ctx* ctx, struct convert_environ__lambda0* _closure, struct str key, struct str value);
struct arr_7 move_to_arr__e_4(struct mut_arr_7* a);
struct arr_7 cast_immutable_8(struct fix_arr_13 a);
struct fix_arr_13 move_to_fix_arr__e_4(struct mut_arr_7* a);
struct process_result* throw_12(struct ctx* ctx, struct str message);
struct process_result* throw_13(struct ctx* ctx, struct exception e);
struct process_result* hard_unreachable_7(void);
struct arr_15 handle_output(struct ctx* ctx, struct str original_path, struct str output_path, struct str actual, uint8_t overwrite_output);
struct opt_16 try_read_file_0(struct ctx* ctx, struct str path);
struct opt_16 try_read_file_1(struct ctx* ctx, char* path);
extern int32_t open(char* path, int32_t oflag, uint32_t permission);
int32_t O_RDONLY(void);
struct opt_16 todo_6(void);
extern int64_t lseek(int32_t f, int64_t offset, int32_t whence);
int32_t seek_end(struct ctx* ctx);
int32_t seek_set(struct ctx* ctx);
struct void_ write_file_0(struct ctx* ctx, struct str path, struct str content);
struct void_ write_file_1(struct ctx* ctx, char* path, struct str content);
uint32_t _shiftLeft(uint32_t a, uint32_t b);
struct comparison _compare_13(uint32_t a, uint32_t b);
struct comparison cmp_4(uint32_t a, uint32_t b);
uint8_t _less_8(uint32_t a, uint32_t b);
int32_t O_CREAT(void);
int32_t O_WRONLY(void);
int32_t O_TRUNC(void);
struct str to_str_7(struct ctx* ctx, uint32_t a);
struct interp with_value_3(struct ctx* ctx, struct interp a, uint32_t b);
uint8_t* ptr_cast_2(char* a);
int64_t to_int64(struct ctx* ctx, uint64_t a);
int64_t max_int64(void);
uint8_t is_empty_21(struct arr_15 a);
struct str remove_colors(struct ctx* ctx, struct str s);
struct void_ remove_colors_recur__e(struct ctx* ctx, struct str s, struct writer out);
struct void_ _concatEquals_12(struct ctx* ctx, struct writer a, char b);
struct arr_0 tail_6(struct ctx* ctx, struct arr_0 a);
struct void_ remove_colors_recur_2__e(struct ctx* ctx, struct str s, struct writer out);
struct opt_24 run_single_crow_test__lambda0(struct ctx* ctx, struct run_single_crow_test__lambda0* _closure, struct str print_kind);
struct arr_15 run_single_runnable_test(struct ctx* ctx, struct str path_to_crow, struct dict_1 env, struct str path, uint8_t interpret, uint8_t overwrite_output);
struct arr_15 _tilde_9(struct ctx* ctx, struct arr_15 a, struct arr_15 b);
struct arr_15 run_crow_tests__lambda0(struct ctx* ctx, struct run_crow_tests__lambda0* _closure, struct str test);
struct interp with_value_4(struct ctx* ctx, struct interp a, uint64_t b);
struct result_2 do_test__lambda0__lambda0(struct ctx* ctx, struct do_test__lambda0__lambda0* _closure);
struct result_2 do_test__lambda0(struct ctx* ctx, struct do_test__lambda0* _closure);
struct result_2 lint(struct ctx* ctx, struct str path, struct test_options* options);
struct arr_2 list_lintable_files(struct ctx* ctx, struct str path);
uint8_t excluded_from_lint(struct ctx* ctx, struct str name);
uint8_t in_2(struct str value, struct arr_2 a);
uint8_t in_recur_1(struct str value, struct arr_2 a, uint64_t i);
struct str noctx_at_2(struct arr_2 a, uint64_t index);
uint8_t exists(struct ctx* ctx, struct arr_2 a, struct fun_act1_8 f);
uint8_t ends_with_0(struct ctx* ctx, struct str a, struct str b);
uint8_t ends_with_1(struct ctx* ctx, struct arr_0 a, struct arr_0 end);
uint8_t excluded_from_lint__lambda0(struct ctx* ctx, struct excluded_from_lint__lambda0* _closure, struct str ext);
uint8_t list_lintable_files__lambda0(struct ctx* ctx, struct void_ _closure, struct str child);
uint8_t should_ignore_extension_of_name(struct ctx* ctx, struct str name);
uint8_t should_ignore_extension(struct ctx* ctx, struct str ext);
struct arr_2 ignored_extensions(struct ctx* ctx);
struct void_ list_lintable_files__lambda1(struct ctx* ctx, struct list_lintable_files__lambda1* _closure, struct str child);
struct arr_15 lint_file(struct ctx* ctx, struct str path);
struct str read_file(struct ctx* ctx, struct str path);
struct void_ each_with_index_0(struct ctx* ctx, struct arr_2 a, struct fun_act2_21 f);
struct void_ each_with_index_recur_0(struct ctx* ctx, struct arr_2 a, struct fun_act2_21 f, uint64_t n);
struct void_ subscript_124(struct ctx* ctx, struct fun_act2_21 a, struct str p0, uint64_t p1);
struct void_ call_w_ctx_1388(struct fun_act2_21 a, struct ctx* ctx, struct str p0, uint64_t p1);
struct arr_2 lines(struct ctx* ctx, struct str s);
struct void_ each_with_index_1(struct ctx* ctx, struct arr_0 a, struct fun_act2_22 f);
struct void_ each_with_index_recur_1(struct ctx* ctx, struct arr_0 a, struct fun_act2_22 f, uint64_t n);
struct void_ subscript_125(struct ctx* ctx, struct fun_act2_22 a, char p0, uint64_t p1);
struct void_ call_w_ctx_1393(struct fun_act2_22 a, struct ctx* ctx, char p0, uint64_t p1);
uint64_t swap(struct cell_0* c, uint64_t v);
uint64_t _times_24(struct cell_0* a);
struct void_ set_deref_1(struct cell_0* a, uint64_t value);
struct void_ lines__lambda0(struct ctx* ctx, struct lines__lambda0* _closure, char c, uint64_t index);
uint64_t line_len(struct ctx* ctx, struct str line);
uint64_t n_tabs(struct ctx* ctx, struct str line);
uint64_t tab_size(struct ctx* ctx);
uint64_t max_line_length(struct ctx* ctx);
struct void_ lint_file__lambda0(struct ctx* ctx, struct lint_file__lambda0* _closure, struct str line, uint64_t line_num);
struct arr_15 lint__lambda0(struct ctx* ctx, struct lint__lambda0* _closure, struct str file);
struct result_2 do_test__lambda1(struct ctx* ctx, struct do_test__lambda1* _closure);
uint64_t print_failures(struct ctx* ctx, struct result_2 failures, struct test_options* options);
struct void_ print_failure(struct ctx* ctx, struct failure* failure);
struct void_ print_bold(struct ctx* ctx);
struct void_ print_reset(struct ctx* ctx);
struct void_ print_failures__lambda0(struct ctx* ctx, struct void_ _closure, struct failure* failure);
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
char constantarr_0_11[16];
char constantarr_0_12[12];
char constantarr_0_13[5];
char constantarr_0_14[2];
char constantarr_0_15[21];
char constantarr_0_16[27];
char constantarr_0_17[26];
char constantarr_0_18[4];
char constantarr_0_19[15];
char constantarr_0_20[18];
char constantarr_0_21[8];
char constantarr_0_22[36];
char constantarr_0_23[63];
char constantarr_0_24[6];
char constantarr_0_25[1];
char constantarr_0_26[3];
char constantarr_0_27[4];
char constantarr_0_28[21];
char constantarr_0_29[1];
char constantarr_0_30[1];
char constantarr_0_31[2];
char constantarr_0_32[3];
char constantarr_0_33[5];
char constantarr_0_34[14];
char constantarr_0_35[9];
char constantarr_0_36[11];
char constantarr_0_37[1];
char constantarr_0_38[23];
char constantarr_0_39[1];
char constantarr_0_40[1];
char constantarr_0_41[1];
char constantarr_0_42[1];
char constantarr_0_43[1];
char constantarr_0_44[1];
char constantarr_0_45[1];
char constantarr_0_46[1];
char constantarr_0_47[1];
char constantarr_0_48[1];
char constantarr_0_49[1];
char constantarr_0_50[1];
char constantarr_0_51[1];
char constantarr_0_52[1];
char constantarr_0_53[1];
char constantarr_0_54[1];
char constantarr_0_55[1];
char constantarr_0_56[1];
char constantarr_0_57[31];
char constantarr_0_58[12];
char constantarr_0_59[1];
char constantarr_0_60[14];
char constantarr_0_61[5];
char constantarr_0_62[5];
char constantarr_0_63[20];
char constantarr_0_64[31];
char constantarr_0_65[7];
char constantarr_0_66[7];
char constantarr_0_67[12];
char constantarr_0_68[29];
char constantarr_0_69[30];
char constantarr_0_70[1];
char constantarr_0_71[1];
char constantarr_0_72[4];
char constantarr_0_73[22];
char constantarr_0_74[9];
char constantarr_0_75[3];
char constantarr_0_76[11];
char constantarr_0_77[5];
char constantarr_0_78[2];
char constantarr_0_79[7];
char constantarr_0_80[7];
char constantarr_0_81[4];
char constantarr_0_82[10];
char constantarr_0_83[12];
char constantarr_0_84[14];
char constantarr_0_85[8];
char constantarr_0_86[4];
char constantarr_0_87[5];
char constantarr_0_88[4];
char constantarr_0_89[4];
char constantarr_0_90[4];
char constantarr_0_91[4];
char constantarr_0_92[5];
char constantarr_0_93[5];
char constantarr_0_94[3];
char constantarr_0_95[13];
char constantarr_0_96[7];
char constantarr_0_97[7];
char constantarr_0_98[12];
char constantarr_0_99[17];
char constantarr_0_100[4];
char constantarr_0_101[1];
char constantarr_0_102[3];
char constantarr_0_103[4];
char constantarr_0_104[10];
char constantarr_0_105[5];
char constantarr_0_106[21];
char constantarr_0_107[3];
char constantarr_0_108[14];
char constantarr_0_109[5];
char constantarr_0_110[24];
char constantarr_0_111[1];
char constantarr_0_112[4];
char constantarr_0_113[28];
char constantarr_0_114[7];
char constantarr_0_115[6];
char constantarr_0_116[4];
char constantarr_0_117[3];
char constantarr_0_118[15];
char constantarr_0_119[9];
char constantarr_0_120[4];
char constantarr_0_121[11];
char constantarr_0_122[4];
char constantarr_0_123[5];
char constantarr_0_124[15];
char constantarr_0_125[2];
char constantarr_0_126[1];
char constantarr_0_127[14];
char constantarr_0_128[12];
char constantarr_0_129[14];
char constantarr_0_130[10];
char constantarr_0_131[25];
char constantarr_0_132[8];
char constantarr_0_133[1];
char constantarr_0_134[21];
char constantarr_0_135[13];
char constantarr_0_136[17];
char constantarr_0_137[8];
char constantarr_0_138[4];
char constantarr_0_139[8];
char constantarr_0_140[11];
char constantarr_0_141[10];
char constantarr_0_142[9];
char constantarr_0_143[12];
char constantarr_0_144[3];
char constantarr_0_145[7];
char constantarr_0_146[10];
char constantarr_0_147[4];
char constantarr_0_148[5];
char constantarr_0_149[7];
char constantarr_0_150[8];
char constantarr_0_151[4];
char constantarr_0_152[5];
char constantarr_0_153[17];
char constantarr_0_154[9];
char constantarr_0_155[1];
char constantarr_0_156[7];
char constantarr_0_157[5];
char constantarr_0_158[16];
char constantarr_0_159[8];
char constantarr_0_160[2];
char constantarr_0_161[7];
char constantarr_0_162[15];
char constantarr_0_163[8];
char constantarr_0_164[7];
char constantarr_0_165[10];
char constantarr_0_166[10];
char constantarr_0_167[3];
char constantarr_0_168[11];
char constantarr_0_169[4];
char constantarr_0_170[11];
char constantarr_0_171[4];
char constantarr_0_172[16];
char constantarr_0_173[9];
char constantarr_0_174[35];
char constantarr_0_175[31];
char constantarr_0_176[34];
char constantarr_0_177[30];
char constantarr_0_178[23];
char constantarr_0_179[22];
char constantarr_0_180[31];
char constantarr_0_181[10];
char constantarr_0_182[21];
char constantarr_0_183[18];
char constantarr_0_184[27];
char constantarr_0_185[5];
char constantarr_0_186[21];
char constantarr_0_187[30];
char constantarr_0_188[9];
char constantarr_0_189[25];
char constantarr_0_190[15];
char constantarr_0_191[17];
char constantarr_0_192[26];
char constantarr_0_193[4];
char constantarr_0_194[22];
char constantarr_0_195[6];
char constantarr_0_196[10];
char constantarr_0_197[57];
char constantarr_0_198[10];
char constantarr_0_199[6];
char constantarr_0_200[34];
char constantarr_0_201[27];
char constantarr_0_202[21];
char constantarr_0_203[6];
char constantarr_0_204[8];
char constantarr_0_205[17];
char constantarr_0_206[10];
char constantarr_0_207[8];
char constantarr_0_208[17];
char constantarr_0_209[19];
char constantarr_0_210[6];
char constantarr_0_211[26];
char constantarr_0_212[10];
char constantarr_0_213[14];
char constantarr_0_214[25];
char constantarr_0_215[20];
char constantarr_0_216[16];
char constantarr_0_217[13];
char constantarr_0_218[13];
char constantarr_0_219[5];
char constantarr_0_220[33];
char constantarr_0_221[14];
char constantarr_0_222[17];
char constantarr_0_223[15];
char constantarr_0_224[5];
char constantarr_0_225[10];
char constantarr_0_226[10];
char constantarr_0_227[9];
char constantarr_0_228[15];
char constantarr_0_229[10];
char constantarr_0_230[9];
char constantarr_0_231[6];
char constantarr_0_232[9];
char constantarr_0_233[6];
char constantarr_0_234[6];
char constantarr_0_235[13];
char constantarr_0_236[2];
char constantarr_0_237[8];
char constantarr_0_238[7];
char constantarr_0_239[13];
char constantarr_0_240[5];
char constantarr_0_241[16];
char constantarr_0_242[18];
char constantarr_0_243[20];
char constantarr_0_244[7];
char constantarr_0_245[4];
char constantarr_0_246[4];
char constantarr_0_247[11];
char constantarr_0_248[10];
char constantarr_0_249[5];
char constantarr_0_250[17];
char constantarr_0_251[18];
char constantarr_0_252[11];
char constantarr_0_253[7];
char constantarr_0_254[8];
char constantarr_0_255[10];
char constantarr_0_256[24];
char constantarr_0_257[6];
char constantarr_0_258[11];
char constantarr_0_259[8];
char constantarr_0_260[17];
char constantarr_0_261[21];
char constantarr_0_262[17];
char constantarr_0_263[18];
char constantarr_0_264[17];
char constantarr_0_265[26];
char constantarr_0_266[11];
char constantarr_0_267[19];
char constantarr_0_268[20];
char constantarr_0_269[7];
char constantarr_0_270[15];
char constantarr_0_271[19];
char constantarr_0_272[9];
char constantarr_0_273[13];
char constantarr_0_274[24];
char constantarr_0_275[40];
char constantarr_0_276[9];
char constantarr_0_277[12];
char constantarr_0_278[8];
char constantarr_0_279[14];
char constantarr_0_280[12];
char constantarr_0_281[8];
char constantarr_0_282[11];
char constantarr_0_283[23];
char constantarr_0_284[12];
char constantarr_0_285[5];
char constantarr_0_286[23];
char constantarr_0_287[9];
char constantarr_0_288[12];
char constantarr_0_289[11];
char constantarr_0_290[16];
char constantarr_0_291[2];
char constantarr_0_292[18];
char constantarr_0_293[8];
char constantarr_0_294[8];
char constantarr_0_295[9];
char constantarr_0_296[10];
char constantarr_0_297[10];
char constantarr_0_298[17];
char constantarr_0_299[8];
char constantarr_0_300[10];
char constantarr_0_301[8];
char constantarr_0_302[12];
char constantarr_0_303[12];
char constantarr_0_304[19];
char constantarr_0_305[21];
char constantarr_0_306[19];
char constantarr_0_307[7];
char constantarr_0_308[10];
char constantarr_0_309[10];
char constantarr_0_310[12];
char constantarr_0_311[8];
char constantarr_0_312[11];
char constantarr_0_313[10];
char constantarr_0_314[6];
char constantarr_0_315[2];
char constantarr_0_316[10];
char constantarr_0_317[14];
char constantarr_0_318[10];
char constantarr_0_319[16];
char constantarr_0_320[17];
char constantarr_0_321[28];
char constantarr_0_322[51];
char constantarr_0_323[32];
char constantarr_0_324[8];
char constantarr_0_325[20];
char constantarr_0_326[14];
char constantarr_0_327[9];
char constantarr_0_328[12];
char constantarr_0_329[15];
char constantarr_0_330[8];
char constantarr_0_331[9];
char constantarr_0_332[15];
char constantarr_0_333[14];
char constantarr_0_334[43];
char constantarr_0_335[6];
char constantarr_0_336[30];
char constantarr_0_337[4];
char constantarr_0_338[37];
char constantarr_0_339[5];
char constantarr_0_340[33];
char constantarr_0_341[12];
char constantarr_0_342[16];
char constantarr_0_343[12];
char constantarr_0_344[10];
char constantarr_0_345[9];
char constantarr_0_346[6];
char constantarr_0_347[18];
char constantarr_0_348[20];
char constantarr_0_349[6];
char constantarr_0_350[10];
char constantarr_0_351[16];
char constantarr_0_352[7];
char constantarr_0_353[8];
char constantarr_0_354[15];
char constantarr_0_355[14];
char constantarr_0_356[12];
char constantarr_0_357[37];
char constantarr_0_358[21];
char constantarr_0_359[18];
char constantarr_0_360[18];
char constantarr_0_361[8];
char constantarr_0_362[13];
char constantarr_0_363[12];
char constantarr_0_364[14];
char constantarr_0_365[24];
char constantarr_0_366[22];
char constantarr_0_367[5];
char constantarr_0_368[8];
char constantarr_0_369[19];
char constantarr_0_370[18];
char constantarr_0_371[20];
char constantarr_0_372[11];
char constantarr_0_373[10];
char constantarr_0_374[9];
char constantarr_0_375[8];
char constantarr_0_376[1];
char constantarr_0_377[2];
char constantarr_0_378[9];
char constantarr_0_379[24];
char constantarr_0_380[30];
char constantarr_0_381[1];
char constantarr_0_382[6];
char constantarr_0_383[11];
char constantarr_0_384[16];
char constantarr_0_385[8];
char constantarr_0_386[14];
char constantarr_0_387[7];
char constantarr_0_388[9];
char constantarr_0_389[12];
char constantarr_0_390[3];
char constantarr_0_391[24];
char constantarr_0_392[16];
char constantarr_0_393[4];
char constantarr_0_394[13];
char constantarr_0_395[17];
char constantarr_0_396[7];
char constantarr_0_397[21];
char constantarr_0_398[33];
char constantarr_0_399[8];
char constantarr_0_400[14];
char constantarr_0_401[12];
char constantarr_0_402[18];
char constantarr_0_403[17];
char constantarr_0_404[19];
char constantarr_0_405[28];
char constantarr_0_406[14];
char constantarr_0_407[18];
char constantarr_0_408[8];
char constantarr_0_409[14];
char constantarr_0_410[19];
char constantarr_0_411[16];
char constantarr_0_412[6];
char constantarr_0_413[7];
char constantarr_0_414[5];
char constantarr_0_415[14];
char constantarr_0_416[20];
char constantarr_0_417[29];
char constantarr_0_418[11];
char constantarr_0_419[10];
char constantarr_0_420[9];
char constantarr_0_421[17];
char constantarr_0_422[8];
char constantarr_0_423[18];
char constantarr_0_424[14];
char constantarr_0_425[19];
char constantarr_0_426[18];
char constantarr_0_427[11];
char constantarr_0_428[11];
char constantarr_0_429[14];
char constantarr_0_430[13];
char constantarr_0_431[13];
char constantarr_0_432[7];
char constantarr_0_433[26];
char constantarr_0_434[8];
char constantarr_0_435[22];
char constantarr_0_436[29];
char constantarr_0_437[25];
char constantarr_0_438[23];
char constantarr_0_439[19];
char constantarr_0_440[24];
char constantarr_0_441[20];
char constantarr_0_442[10];
char constantarr_0_443[3];
char constantarr_0_444[12];
char constantarr_0_445[23];
char constantarr_0_446[6];
char constantarr_0_447[12];
char constantarr_0_448[16];
char constantarr_0_449[8];
char constantarr_0_450[11];
char constantarr_0_451[15];
char constantarr_0_452[11];
char constantarr_0_453[11];
char constantarr_0_454[26];
char constantarr_0_455[7];
char constantarr_0_456[26];
char constantarr_0_457[2];
char constantarr_0_458[22];
char constantarr_0_459[30];
char constantarr_0_460[15];
char constantarr_0_461[14];
char constantarr_0_462[16];
char constantarr_0_463[15];
char constantarr_0_464[15];
char constantarr_0_465[6];
char constantarr_0_466[22];
char constantarr_0_467[13];
char constantarr_0_468[15];
char constantarr_0_469[16];
char constantarr_0_470[5];
char constantarr_0_471[8];
char constantarr_0_472[12];
char constantarr_0_473[22];
char constantarr_0_474[28];
char constantarr_0_475[37];
char constantarr_0_476[5];
char constantarr_0_477[8];
char constantarr_0_478[14];
char constantarr_0_479[21];
char constantarr_0_480[16];
char constantarr_0_481[12];
char constantarr_0_482[20];
char constantarr_0_483[21];
char constantarr_0_484[23];
char constantarr_0_485[21];
char constantarr_0_486[16];
char constantarr_0_487[29];
char constantarr_0_488[18];
char constantarr_0_489[5];
char constantarr_0_490[7];
char constantarr_0_491[24];
char constantarr_0_492[18];
char constantarr_0_493[10];
char constantarr_0_494[17];
char constantarr_0_495[12];
char constantarr_0_496[7];
char constantarr_0_497[27];
char constantarr_0_498[8];
char constantarr_0_499[15];
char constantarr_0_500[4];
char constantarr_0_501[10];
char constantarr_0_502[12];
char constantarr_0_503[4];
char constantarr_0_504[10];
char constantarr_0_505[4];
char constantarr_0_506[4];
char constantarr_0_507[8];
char constantarr_0_508[21];
char constantarr_0_509[4];
char constantarr_0_510[12];
char constantarr_0_511[8];
char constantarr_0_512[5];
char constantarr_0_513[22];
char constantarr_0_514[10];
char constantarr_0_515[18];
char constantarr_0_516[22];
char constantarr_0_517[12];
char constantarr_0_518[8];
char constantarr_0_519[20];
char constantarr_0_520[17];
char constantarr_0_521[4];
char constantarr_0_522[12];
char constantarr_0_523[9];
char constantarr_0_524[11];
char constantarr_0_525[27];
char constantarr_0_526[16];
char constantarr_0_527[13];
char constantarr_0_528[4];
char constantarr_0_529[7];
char constantarr_0_530[7];
char constantarr_0_531[7];
char constantarr_0_532[8];
char constantarr_0_533[15];
char constantarr_0_534[21];
char constantarr_0_535[6];
char constantarr_0_536[23];
char constantarr_0_537[21];
char constantarr_0_538[10];
char constantarr_0_539[34];
char constantarr_0_540[10];
char constantarr_0_541[34];
char constantarr_0_542[26];
char constantarr_0_543[9];
char constantarr_0_544[23];
char constantarr_0_545[14];
char constantarr_0_546[23];
char constantarr_0_547[17];
char constantarr_0_548[6];
char constantarr_0_549[30];
char constantarr_0_550[30];
char constantarr_0_551[22];
char constantarr_0_552[24];
char constantarr_0_553[24];
char constantarr_0_554[20];
char constantarr_0_555[9];
char constantarr_0_556[5];
char constantarr_0_557[14];
char constantarr_0_558[21];
char constantarr_0_559[11];
char constantarr_0_560[36];
char constantarr_0_561[25];
char constantarr_0_562[13];
char constantarr_0_563[17];
char constantarr_0_564[23];
char constantarr_0_565[9];
char constantarr_0_566[19];
char constantarr_0_567[13];
char constantarr_0_568[33];
char constantarr_0_569[30];
char constantarr_0_570[22];
char constantarr_0_571[24];
char constantarr_0_572[26];
char constantarr_0_573[17];
char constantarr_0_574[14];
char constantarr_0_575[32];
char constantarr_0_576[21];
char constantarr_0_577[84];
char constantarr_0_578[11];
char constantarr_0_579[45];
char constantarr_0_580[19];
char constantarr_0_581[22];
char constantarr_0_582[30];
char constantarr_0_583[11];
char constantarr_0_584[17];
char constantarr_0_585[14];
char constantarr_0_586[9];
char constantarr_0_587[6];
char constantarr_0_588[14];
char constantarr_0_589[15];
char constantarr_0_590[44];
char constantarr_0_591[10];
char constantarr_0_592[19];
char constantarr_0_593[15];
char constantarr_0_594[21];
char constantarr_0_595[12];
char constantarr_0_596[18];
char constantarr_0_597[14];
char constantarr_0_598[28];
char constantarr_0_599[16];
char constantarr_0_600[11];
char constantarr_0_601[8];
char constantarr_0_602[17];
char constantarr_0_603[25];
char constantarr_0_604[12];
char constantarr_0_605[11];
char constantarr_0_606[17];
char constantarr_0_607[14];
char constantarr_0_608[8];
char constantarr_0_609[13];
char constantarr_0_610[26];
char constantarr_0_611[11];
char constantarr_0_612[14];
char constantarr_0_613[6];
char constantarr_0_614[7];
char constantarr_0_615[11];
char constantarr_0_616[17];
char constantarr_0_617[14];
char constantarr_0_618[21];
char constantarr_0_619[7];
char constantarr_0_620[7];
char constantarr_0_621[9];
char constantarr_0_622[26];
char constantarr_0_623[28];
char constantarr_0_624[9];
char constantarr_0_625[5];
char constantarr_0_626[11];
char constantarr_0_627[11];
char constantarr_0_628[14];
char constantarr_0_629[18];
char constantarr_0_630[10];
char constantarr_0_631[11];
char constantarr_0_632[11];
char constantarr_0_633[40];
char constantarr_0_634[10];
char constantarr_0_635[21];
char constantarr_0_636[11];
char constantarr_0_637[9];
char constantarr_0_638[8];
char constantarr_0_639[10];
char constantarr_0_640[15];
char constantarr_0_641[28];
char constantarr_0_642[7];
char constantarr_0_643[11];
char constantarr_0_644[10];
char constantarr_0_645[6];
char constantarr_0_646[12];
char constantarr_0_647[35];
char constantarr_0_648[37];
char constantarr_0_649[7];
char constantarr_0_650[29];
char constantarr_0_651[10];
char constantarr_0_652[13];
char constantarr_0_653[12];
char constantarr_0_654[46];
char constantarr_0_655[12];
char constantarr_0_656[8];
char constantarr_0_657[8];
char constantarr_0_658[13];
char constantarr_0_659[20];
char constantarr_0_660[15];
char constantarr_0_661[17];
char constantarr_0_662[16];
char constantarr_0_663[7];
char constantarr_0_664[17];
char constantarr_0_665[11];
char constantarr_0_666[10];
char constantarr_0_667[22];
char constantarr_0_668[16];
char constantarr_0_669[9];
char constantarr_0_670[9];
char constantarr_0_671[18];
char constantarr_0_672[15];
char constantarr_0_673[19];
char constantarr_0_674[12];
char constantarr_0_675[31];
char constantarr_0_676[6];
char constantarr_0_677[5];
char constantarr_0_678[16];
char constantarr_0_679[21];
char constantarr_0_680[4];
char constantarr_0_681[35];
char constantarr_0_682[17];
char constantarr_0_683[25];
char constantarr_0_684[21];
char constantarr_0_685[24];
char constantarr_0_686[20];
char constantarr_0_687[24];
char constantarr_0_688[4];
char constantarr_0_689[15];
char constantarr_0_690[16];
char constantarr_0_691[21];
char constantarr_0_692[15];
char constantarr_0_693[19];
char constantarr_0_694[18];
char constantarr_0_695[11];
char constantarr_0_696[15];
char constantarr_0_697[14];
char constantarr_0_698[17];
char constantarr_0_699[29];
char constantarr_0_700[14];
char constantarr_0_701[9];
char constantarr_0_702[17];
char constantarr_0_703[16];
char constantarr_0_704[8];
char constantarr_0_705[7];
char constantarr_0_706[3];
char constantarr_0_707[8];
char constantarr_0_708[16];
char constantarr_0_709[19];
char constantarr_0_710[17];
char constantarr_0_711[23];
char constantarr_0_712[10];
char constantarr_0_713[22];
char constantarr_0_714[18];
char constantarr_0_715[7];
char constantarr_0_716[5];
char constantarr_0_717[31];
char constantarr_0_718[10];
char constantarr_0_719[15];
char constantarr_0_720[29];
char constantarr_0_721[16];
char constantarr_0_722[5];
char constantarr_0_723[18];
char constantarr_0_724[24];
char constantarr_0_725[10];
char constantarr_0_726[21];
char constantarr_0_727[7];
char constantarr_0_728[19];
char constantarr_0_729[7];
char constantarr_0_730[6];
char constantarr_0_731[18];
char constantarr_0_732[10];
char constantarr_0_733[25];
char constantarr_0_734[8];
char constantarr_0_735[16];
char constantarr_0_736[14];
char constantarr_0_737[22];
char constantarr_0_738[21];
char constantarr_0_739[14];
char constantarr_0_740[18];
char constantarr_0_741[24];
char constantarr_0_742[34];
char constantarr_0_743[27];
char constantarr_0_744[25];
char constantarr_0_745[28];
char constantarr_0_746[11];
char constantarr_0_747[32];
char constantarr_0_748[13];
char constantarr_0_749[34];
char constantarr_0_750[18];
char constantarr_0_751[23];
char constantarr_0_752[32];
char constantarr_0_753[21];
char constantarr_0_754[27];
char constantarr_0_755[19];
char constantarr_0_756[17];
char constantarr_0_757[16];
char constantarr_0_758[18];
char constantarr_0_759[4];
char constantarr_0_760[31];
char constantarr_0_761[12];
char constantarr_0_762[8];
char constantarr_0_763[22];
char constantarr_0_764[39];
char constantarr_0_765[17];
char constantarr_0_766[39];
char constantarr_0_767[16];
char constantarr_0_768[26];
char constantarr_0_769[15];
char constantarr_0_770[42];
char constantarr_0_771[8];
char constantarr_0_772[11];
char constantarr_0_773[8];
char constantarr_0_774[31];
char constantarr_0_775[11];
char constantarr_0_776[39];
char constantarr_0_777[24];
char constantarr_0_778[23];
char constantarr_0_779[32];
char constantarr_0_780[20];
char constantarr_0_781[24];
char constantarr_0_782[10];
char constantarr_0_783[28];
char constantarr_0_784[24];
char constantarr_0_785[15];
char constantarr_0_786[32];
char constantarr_0_787[25];
char constantarr_0_788[17];
char constantarr_0_789[17];
char constantarr_0_790[23];
char constantarr_0_791[14];
char constantarr_0_792[28];
char constantarr_0_793[26];
char constantarr_0_794[8];
char constantarr_0_795[7];
char constantarr_0_796[22];
char constantarr_0_797[19];
char constantarr_0_798[9];
char constantarr_0_799[15];
char constantarr_0_800[27];
char constantarr_0_801[14];
char constantarr_0_802[29];
char constantarr_0_803[23];
char constantarr_0_804[14];
char constantarr_0_805[20];
char constantarr_0_806[22];
char constantarr_0_807[10];
char constantarr_0_808[16];
char constantarr_0_809[22];
char constantarr_0_810[12];
char constantarr_0_811[9];
char constantarr_0_812[9];
char constantarr_0_813[30];
char constantarr_0_814[28];
char constantarr_0_815[12];
char constantarr_0_816[13];
char constantarr_0_817[21];
char constantarr_0_818[13];
char constantarr_0_819[17];
char constantarr_0_820[28];
char constantarr_0_821[20];
char constantarr_0_822[22];
char constantarr_0_823[26];
char constantarr_0_824[16];
char constantarr_0_825[19];
char constantarr_0_826[13];
char constantarr_0_827[28];
char constantarr_0_828[25];
char constantarr_0_829[33];
char constantarr_0_830[10];
char constantarr_0_831[16];
char constantarr_0_832[20];
char constantarr_0_833[10];
char constantarr_0_834[14];
char constantarr_0_835[21];
char constantarr_0_836[20];
char constantarr_0_837[32];
char constantarr_0_838[24];
char constantarr_0_839[21];
char constantarr_0_840[18];
char constantarr_0_841[21];
char constantarr_0_842[11];
char constantarr_0_843[20];
char constantarr_0_844[13];
char constantarr_0_845[21];
char constantarr_0_846[27];
char constantarr_0_847[17];
char constantarr_0_848[33];
char constantarr_0_849[21];
char constantarr_0_850[26];
char constantarr_0_851[28];
char constantarr_0_852[29];
char constantarr_0_853[10];
char constantarr_0_854[24];
char constantarr_0_855[40];
char constantarr_0_856[32];
char constantarr_0_857[20];
char constantarr_0_858[37];
char constantarr_0_859[12];
char constantarr_0_860[36];
char constantarr_0_861[12];
char constantarr_0_862[18];
char constantarr_0_863[7];
char constantarr_0_864[13];
char constantarr_0_865[14];
char constantarr_0_866[15];
char constantarr_0_867[26];
char constantarr_0_868[8];
char constantarr_0_869[5];
char constantarr_0_870[27];
char constantarr_0_871[15];
char constantarr_0_872[23];
char constantarr_0_873[10];
char constantarr_0_874[19];
char constantarr_0_875[19];
char constantarr_0_876[19];
char constantarr_0_877[27];
char constantarr_0_878[27];
char constantarr_0_879[27];
char constantarr_0_880[5];
char constantarr_0_881[13];
char constantarr_0_882[9];
char constantarr_0_883[15];
char constantarr_0_884[18];
char constantarr_0_885[18];
char constantarr_0_886[6];
char constantarr_0_887[5];
char constantarr_0_888[15];
char constantarr_0_889[8];
char constantarr_0_890[6];
char constantarr_0_891[18];
char constantarr_0_892[24];
char constantarr_0_893[28];
char constantarr_0_894[24];
char constantarr_0_895[24];
char constantarr_0_896[27];
char constantarr_0_897[10];
char constantarr_0_898[9];
char constantarr_0_899[18];
char constantarr_0_900[6];
char constantarr_0_901[25];
char constantarr_0_902[3];
char constantarr_0_903[9];
char constantarr_0_904[13];
char constantarr_0_905[4];
char constantarr_0_906[10];
char constantarr_0_907[5];
char constantarr_0_908[15];
char constantarr_0_909[17];
char constantarr_0_910[7];
char constantarr_0_911[11];
char constantarr_0_912[16];
char constantarr_0_913[14];
char constantarr_0_914[20];
char constantarr_0_915[24];
char constantarr_0_916[10];
char constantarr_0_917[11];
char constantarr_0_918[18];
char constantarr_0_919[17];
char constantarr_0_920[10];
char constantarr_0_921[7];
char constantarr_0_922[19];
char constantarr_0_923[21];
char constantarr_0_924[12];
char constantarr_0_925[23];
char constantarr_0_926[4];
char constantarr_0_927[4];
char constantarr_0_928[12];
char constantarr_0_929[13];
char constantarr_0_930[7];
char constantarr_0_931[23];
char constantarr_0_932[18];
char constantarr_0_933[31];
char constantarr_0_934[14];
char constantarr_0_935[36];
char constantarr_0_936[7];
char constantarr_0_937[10];
char constantarr_0_938[14];
char constantarr_0_939[10];
char constantarr_0_940[12];
char constantarr_0_941[20];
char constantarr_0_942[28];
char constantarr_0_943[6];
char constantarr_0_944[8];
char constantarr_0_945[4];
char constantarr_0_946[10];
char constantarr_0_947[5];
char constantarr_0_948[8];
char constantarr_0_949[16];
char constantarr_0_950[6];
char constantarr_0_951[15];
char constantarr_0_952[11];
char constantarr_0_953[27];
char constantarr_0_954[7];
char constantarr_0_955[6];
char constantarr_0_956[7];
char constantarr_0_957[9];
char constantarr_0_958[8];
char constantarr_0_959[7];
char constantarr_0_960[19];
char constantarr_0_961[28];
char constantarr_0_962[42];
char constantarr_0_963[21];
char constantarr_0_964[14];
char constantarr_0_965[6];
char constantarr_0_966[8];
char constantarr_0_967[12];
char constantarr_0_968[9];
char constantarr_0_969[19];
char constantarr_0_970[24];
char constantarr_0_971[9];
char constantarr_0_972[14];
char constantarr_0_973[15];
char constantarr_0_974[14];
char constantarr_0_975[14];
char constantarr_0_976[7];
char constantarr_0_977[20];
char constantarr_0_978[7];
char constantarr_0_979[9];
char constantarr_0_980[7];
char constantarr_0_981[18];
char constantarr_0_982[8];
char constantarr_0_983[24];
char constantarr_0_984[10];
char constantarr_0_985[27];
char constantarr_0_986[17];
char constantarr_0_987[17];
char constantarr_0_988[10];
char constantarr_0_989[21];
char constantarr_0_990[18];
char constantarr_0_991[24];
char constantarr_0_992[11];
char constantarr_0_993[14];
char constantarr_0_994[13];
char constantarr_0_995[13];
char constantarr_0_996[10];
char constantarr_0_997[7];
char constantarr_0_998[11];
char constantarr_0_999[9];
char constantarr_0_1000[18];
char constantarr_0_1001[10];
char constantarr_0_1002[36];
char constantarr_0_1003[12];
char constantarr_0_1004[9];
char constantarr_0_1005[7];
char constantarr_0_1006[15];
char constantarr_0_1007[23];
char constantarr_0_1008[30];
char constantarr_0_1009[12];
char constantarr_0_1010[7];
char constantarr_0_1011[44];
char constantarr_0_1012[17];
char constantarr_0_1013[20];
char constantarr_0_1014[29];
char constantarr_0_1015[23];
char constantarr_0_1016[13];
char constantarr_0_1017[14];
char constantarr_0_1018[21];
char constantarr_0_1019[14];
char constantarr_0_1020[29];
char constantarr_0_1021[7];
char constantarr_0_1022[7];
char constantarr_0_1023[10];
char constantarr_0_1024[5];
char constantarr_0_1025[17];
char constantarr_0_1026[4];
char constantarr_0_1027[26];
char constantarr_0_1028[29];
char constantarr_0_1029[33];
char constantarr_0_1030[10];
char constantarr_0_1031[32];
char constantarr_0_1032[9];
char constantarr_0_1033[11];
char constantarr_0_1034[11];
char constantarr_0_1035[5];
char constantarr_0_1036[12];
char constantarr_0_1037[23];
char constantarr_0_1038[31];
char constantarr_0_1039[6];
char constantarr_0_1040[6];
char constantarr_0_1041[21];
char constantarr_0_1042[15];
char constantarr_0_1043[13];
char constantarr_0_1044[13];
char constantarr_0_1045[4];
char constantarr_0_1046[14];
char constantarr_0_1047[7];
char constantarr_0_1048[10];
char constantarr_0_1049[14];
char constantarr_0_1050[9];
char constantarr_0_1051[24];
char constantarr_0_1052[22];
char constantarr_0_1053[10];
char constantarr_0_1054[4];
char constantarr_0_1055[10];
char constantarr_0_1056[8];
char constantarr_0_1057[2];
char constantarr_0_1058[11];
char constantarr_0_1059[7];
char constantarr_0_1060[11];
char constantarr_0_1061[7];
char constantarr_0_1062[11];
char constantarr_0_1063[7];
char constantarr_0_1064[11];
char constantarr_0_1065[7];
char constantarr_0_1066[12];
char constantarr_0_1067[8];
char constantarr_0_1068[21];
char constantarr_0_1069[3];
char constantarr_0_1070[10];
char constantarr_0_1071[7];
char constantarr_0_1072[22];
char constantarr_0_1073[7];
char constantarr_0_1074[9];
char constantarr_0_1075[8];
char constantarr_0_1076[11];
char constantarr_0_1077[2];
char constantarr_0_1078[10];
char constantarr_0_1079[8];
char constantarr_0_1080[11];
char constantarr_0_1081[11];
char constantarr_0_1082[7];
char constantarr_0_1083[12];
char constantarr_0_1084[3];
char constantarr_0_1085[3];
char constantarr_0_1086[17];
char constantarr_0_1087[10];
char constantarr_0_1088[12];
char constantarr_0_1089[14];
char constantarr_0_1090[12];
char constantarr_0_1091[18];
char constantarr_0_1092[25];
char constantarr_0_1093[33];
char constantarr_0_1094[20];
char constantarr_0_1095[15];
char constantarr_0_1096[24];
char constantarr_0_1097[14];
char constantarr_0_1098[22];
char constantarr_0_1099[19];
char constantarr_0_1100[23];
char constantarr_0_1101[19];
char constantarr_0_1102[29];
char constantarr_0_1103[21];
char constantarr_0_1104[9];
char constantarr_0_1105[13];
char constantarr_0_1106[13];
char constantarr_0_1107[4];
char constantarr_0_1108[8];
char constantarr_0_1109[14];
char constantarr_0_1110[5];
char constantarr_0_1111[8];
char constantarr_0_1112[8];
char constantarr_0_1113[20];
char constantarr_0_1114[10];
char constantarr_0_1115[1];
char constantarr_0_1116[2];
char constantarr_0_1117[10];
char constantarr_0_1118[8];
char constantarr_0_1119[15];
char constantarr_0_1120[21];
char constantarr_0_1121[7];
char constantarr_0_1122[8];
char constantarr_0_1123[7];
char constantarr_0_1124[17];
char constantarr_0_1125[9];
char constantarr_0_1126[7];
char constantarr_0_1127[17];
char constantarr_0_1128[17];
char constantarr_0_1129[13];
char constantarr_0_1130[20];
char constantarr_0_1131[10];
char constantarr_0_1132[22];
char constantarr_0_1133[11];
char constantarr_0_1134[18];
char constantarr_0_1135[8];
char constantarr_0_1136[28];
char constantarr_0_1137[24];
char constantarr_0_1138[10];
char constantarr_0_1139[22];
char constantarr_0_1140[17];
char constantarr_0_1141[17];
char constantarr_0_1142[23];
char constantarr_0_1143[15];
char constantarr_0_1144[4];
char constantarr_0_1145[19];
char constantarr_0_1146[18];
char constantarr_0_1147[7];
char constantarr_0_1148[11];
char constantarr_0_1149[9];
char constantarr_0_1150[15];
char constantarr_0_1151[26];
char constantarr_0_1152[27];
char constantarr_0_1153[31];
char constantarr_0_1154[23];
char constantarr_0_1155[18];
char constantarr_0_1156[27];
char constantarr_0_1157[9];
char constantarr_0_1158[9];
char constantarr_0_1159[20];
char constantarr_0_1160[24];
char constantarr_0_1161[25];
char constantarr_0_1162[5];
char constantarr_0_1163[11];
char constantarr_0_1164[21];
char constantarr_0_1165[11];
char constantarr_0_1166[13];
char constantarr_0_1167[8];
char constantarr_0_1168[6];
char constantarr_0_1169[8];
char constantarr_0_1170[15];
char constantarr_0_1171[17];
char constantarr_0_1172[12];
char constantarr_0_1173[15];
char constantarr_0_1174[14];
char constantarr_0_1175[19];
char constantarr_0_1176[13];
char constantarr_0_1177[10];
char constantarr_0_1178[4];
char constantarr_0_1179[11];
char constantarr_0_1180[22];
char constantarr_0_1181[12];
char constantarr_0_1182[11];
struct str constantarr_2_0[4];
struct str constantarr_2_1[4];
struct str constantarr_2_2[11];
struct str constantarr_2_3[5];
struct str constantarr_2_4[6];
struct named_val constantarr_5_0[1201];
struct sym constantarr_1_0[402];
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
char constantarr_0_10[11] = "print-tests";
char constantarr_0_11[16] = "overwrite-output";
char constantarr_0_12[12] = "max-failures";
char constantarr_0_13[5] = "match";
char constantarr_0_14[2] = "--";
char constantarr_0_15[21] = "should be unreachable";
char constantarr_0_16[27] = "tried to force empty option";
char constantarr_0_17[26] = "Should be no nameless args";
char constantarr_0_18[4] = "help";
char constantarr_0_19[15] = "Unexpected arg ";
char constantarr_0_20[18] = "test -- runs tests";
char constantarr_0_21[8] = "options:";
char constantarr_0_22[36] = "\t--print-tests: print every test run";
char constantarr_0_23[63] = "\t--max-failures: stop after this many failures. Defaults to 10.";
char constantarr_0_24[6] = "./test";
char constantarr_0_25[1] = "/";
char constantarr_0_26[3] = "bin";
char constantarr_0_27[4] = "crow";
char constantarr_0_28[21] = "path does not exist: ";
char constantarr_0_29[1] = "\0";
char constantarr_0_30[1] = ".";
char constantarr_0_31[2] = "..";
char constantarr_0_32[3] = "ast";
char constantarr_0_33[5] = "model";
char constantarr_0_34[14] = "concrete-model";
char constantarr_0_35[9] = "low-model";
char constantarr_0_36[11] = "crow print ";
char constantarr_0_37[1] = " ";
char constantarr_0_38[23] = "spawn-and-wait-result: ";
char constantarr_0_39[1] = "0";
char constantarr_0_40[1] = "1";
char constantarr_0_41[1] = "2";
char constantarr_0_42[1] = "3";
char constantarr_0_43[1] = "4";
char constantarr_0_44[1] = "5";
char constantarr_0_45[1] = "6";
char constantarr_0_46[1] = "7";
char constantarr_0_47[1] = "8";
char constantarr_0_48[1] = "9";
char constantarr_0_49[1] = "a";
char constantarr_0_50[1] = "b";
char constantarr_0_51[1] = "c";
char constantarr_0_52[1] = "d";
char constantarr_0_53[1] = "e";
char constantarr_0_54[1] = "f";
char constantarr_0_55[1] = "?";
char constantarr_0_56[1] = "-";
char constantarr_0_57[31] = "Process terminated with signal ";
char constantarr_0_58[12] = "WAIT STOPPED";
char constantarr_0_59[1] = "=";
char constantarr_0_60[14] = " is not a file";
char constantarr_0_61[5] = "print";
char constantarr_0_62[5] = ".repr";
char constantarr_0_63[20] = "failed to open file ";
char constantarr_0_64[31] = "failed to open file for write: ";
char constantarr_0_65[7] = "errno: ";
char constantarr_0_66[7] = "flags: ";
char constantarr_0_67[12] = "permission: ";
char constantarr_0_68[29] = " does not exist. actual was:\n";
char constantarr_0_69[30] = " was not as expected. actual:\n";
char constantarr_0_70[1] = "\x1b""";
char constantarr_0_71[1] = "m";
char constantarr_0_72[4] = ".err";
char constantarr_0_73[22] = "unexpected exit code: ";
char constantarr_0_74[9] = "crow run ";
char constantarr_0_75[3] = "run";
char constantarr_0_76[11] = "--interpret";
char constantarr_0_77[5] = "--out";
char constantarr_0_78[2] = ".c";
char constantarr_0_79[7] = ".stdout";
char constantarr_0_80[7] = ".stderr";
char constantarr_0_81[4] = "ran ";
char constantarr_0_82[10] = " tests in ";
char constantarr_0_83[12] = "parse-errors";
char constantarr_0_84[14] = "compile-errors";
char constantarr_0_85[8] = "runnable";
char constantarr_0_86[4] = ".bmp";
char constantarr_0_87[5] = ".html";
char constantarr_0_88[4] = ".mdb";
char constantarr_0_89[4] = ".png";
char constantarr_0_90[4] = ".svg";
char constantarr_0_91[4] = ".ttf";
char constantarr_0_92[5] = ".wasm";
char constantarr_0_93[5] = ".webp";
char constantarr_0_94[3] = ".xz";
char constantarr_0_95[13] = "documentation";
char constantarr_0_96[7] = "dyncall";
char constantarr_0_97[7] = "libfirm";
char constantarr_0_98[12] = "node_modules";
char constantarr_0_99[17] = "package-lock.json";
char constantarr_0_100[4] = "data";
char constantarr_0_101[1] = "o";
char constantarr_0_102[3] = "out";
char constantarr_0_103[4] = "repr";
char constantarr_0_104[10] = "tmLanguage";
char constantarr_0_105[5] = "lint ";
char constantarr_0_106[21] = "file does not exist: ";
char constantarr_0_107[3] = "err";
char constantarr_0_108[14] = "sublime-syntax";
char constantarr_0_109[5] = "line ";
char constantarr_0_110[24] = " contains a double space";
char constantarr_0_111[1] = "\t";
char constantarr_0_112[4] = " is ";
char constantarr_0_113[28] = " columns long, should be <= ";
char constantarr_0_114[7] = "linted ";
char constantarr_0_115[6] = " files";
char constantarr_0_116[4] = "\x1b""[1m";
char constantarr_0_117[3] = "\x1b""[m";
char constantarr_0_118[15] = "hit maximum of ";
char constantarr_0_119[9] = " failures";
char constantarr_0_120[4] = "mark";
char constantarr_0_121[11] = "hard-assert";
char constantarr_0_122[4] = "void";
char constantarr_0_123[5] = "abort";
char constantarr_0_124[15] = "is-word-aligned";
char constantarr_0_125[2] = "==";
char constantarr_0_126[1] = "&";
char constantarr_0_127[14] = "to-nat64<nat8>";
char constantarr_0_128[12] = "as-mut<nat8>";
char constantarr_0_129[14] = "words-of-bytes";
char constantarr_0_130[10] = "unsafe-div";
char constantarr_0_131[25] = "round-up-to-multiple-of-8";
char constantarr_0_132[8] = "wrap-add";
char constantarr_0_133[1] = "~";
char constantarr_0_134[21] = "ptr-cast<nat64, nat8>";
char constantarr_0_135[13] = "as-const<out>";
char constantarr_0_136[17] = "ptr-cast<out, in>";
char constantarr_0_137[8] = "-<nat64>";
char constantarr_0_138[4] = "-<a>";
char constantarr_0_139[8] = "wrap-sub";
char constantarr_0_140[11] = "to-nat64<a>";
char constantarr_0_141[10] = "size-of<a>";
char constantarr_0_142[9] = "as-mut<a>";
char constantarr_0_143[12] = "memory-start";
char constantarr_0_144[3] = "<=>";
char constantarr_0_145[7] = "is-less";
char constantarr_0_146[10] = "cmp<nat64>";
char constantarr_0_147[4] = "less";
char constantarr_0_148[5] = "equal";
char constantarr_0_149[7] = "greater";
char constantarr_0_150[8] = "<<nat64>";
char constantarr_0_151[4] = "true";
char constantarr_0_152[5] = "false";
char constantarr_0_153[17] = "memory-size-words";
char constantarr_0_154[9] = "<=<nat64>";
char constantarr_0_155[1] = "!";
char constantarr_0_156[7] = "+<bool>";
char constantarr_0_157[5] = "marks";
char constantarr_0_158[16] = "mark-range-recur";
char constantarr_0_159[8] = "==<bool>";
char constantarr_0_160[2] = "||";
char constantarr_0_161[7] = "*<bool>";
char constantarr_0_162[15] = "set-deref<bool>";
char constantarr_0_163[8] = "><nat64>";
char constantarr_0_164[7] = "rt-main";
char constantarr_0_165[10] = "get_nprocs";
char constantarr_0_166[10] = "global-ctx";
char constantarr_0_167[3] = "lbv";
char constantarr_0_168[11] = "lock-by-val";
char constantarr_0_169[4] = "lock";
char constantarr_0_170[11] = "atomic-bool";
char constantarr_0_171[4] = "none";
char constantarr_0_172[16] = "create-condition";
char constantarr_0_173[9] = "condition";
char constantarr_0_174[35] = "zeroed<by-val<pthread_mutexattr_t>>";
char constantarr_0_175[31] = "zeroed<by-val<pthread_mutex_t>>";
char constantarr_0_176[34] = "zeroed<by-val<pthread_condattr_t>>";
char constantarr_0_177[30] = "zeroed<by-val<pthread_cond_t>>";
char constantarr_0_178[23] = "hard-assert-posix-error";
char constantarr_0_179[22] = "pthread_mutexattr_init";
char constantarr_0_180[31] = "ref-of-val<pthread_mutexattr_t>";
char constantarr_0_181[10] = "mutex-attr";
char constantarr_0_182[21] = "ref-of-val<condition>";
char constantarr_0_183[18] = "pthread_mutex_init";
char constantarr_0_184[27] = "ref-of-val<pthread_mutex_t>";
char constantarr_0_185[5] = "mutex";
char constantarr_0_186[21] = "pthread_condattr_init";
char constantarr_0_187[30] = "ref-of-val<pthread_condattr_t>";
char constantarr_0_188[9] = "cond-attr";
char constantarr_0_189[25] = "pthread_condattr_setclock";
char constantarr_0_190[15] = "CLOCK_MONOTONIC";
char constantarr_0_191[17] = "pthread_cond_init";
char constantarr_0_192[26] = "ref-of-val<pthread_cond_t>";
char constantarr_0_193[4] = "cond";
char constantarr_0_194[22] = "ref-of-val<global-ctx>";
char constantarr_0_195[6] = "island";
char constantarr_0_196[10] = "task-queue";
char constantarr_0_197[57] = "mut-arr-by-val-with-capacity-from-unmanaged-memory<nat64>";
char constantarr_0_198[10] = "fix-arr<a>";
char constantarr_0_199[6] = "arr<a>";
char constantarr_0_200[34] = "unmanaged-alloc-zeroed-elements<a>";
char constantarr_0_201[27] = "unmanaged-alloc-elements<a>";
char constantarr_0_202[21] = "unmanaged-alloc-bytes";
char constantarr_0_203[6] = "malloc";
char constantarr_0_204[8] = "==<nat8>";
char constantarr_0_205[17] = "!=<mut-ptr<nat8>>";
char constantarr_0_206[10] = "null<nat8>";
char constantarr_0_207[8] = "wrap-mul";
char constantarr_0_208[17] = "set-zero-range<a>";
char constantarr_0_209[19] = "drop<mut-ptr<nat8>>";
char constantarr_0_210[6] = "memset";
char constantarr_0_211[26] = "as-any-mut-ptr<mut-ptr<a>>";
char constantarr_0_212[10] = "mut-arr<a>";
char constantarr_0_213[14] = "island-gc-root";
char constantarr_0_214[25] = "default-exception-handler";
char constantarr_0_215[20] = "print-err-no-newline";
char constantarr_0_216[16] = "write-no-newline";
char constantarr_0_217[13] = "size-of<char>";
char constantarr_0_218[13] = "size-of<nat8>";
char constantarr_0_219[5] = "write";
char constantarr_0_220[33] = "as-any-const-ptr<const-ptr<char>>";
char constantarr_0_221[14] = "as-const<nat8>";
char constantarr_0_222[17] = "as-any-mut-ptr<a>";
char constantarr_0_223[15] = "begin-ptr<char>";
char constantarr_0_224[5] = "chars";
char constantarr_0_225[10] = "size-bytes";
char constantarr_0_226[10] = "size<char>";
char constantarr_0_227[9] = "!=<int64>";
char constantarr_0_228[15] = "unsafe-to-int64";
char constantarr_0_229[10] = "todo<void>";
char constantarr_0_230[9] = "zeroed<a>";
char constantarr_0_231[6] = "stderr";
char constantarr_0_232[9] = "print-err";
char constantarr_0_233[6] = "to-str";
char constantarr_0_234[6] = "writer";
char constantarr_0_235[13] = "mut-arr<char>";
char constantarr_0_236[2] = "~=";
char constantarr_0_237[8] = "~=<char>";
char constantarr_0_238[7] = "each<a>";
char constantarr_0_239[13] = "each-recur<a>";
char constantarr_0_240[5] = "==<a>";
char constantarr_0_241[16] = "!=<const-ptr<a>>";
char constantarr_0_242[18] = "subscript<void, a>";
char constantarr_0_243[20] = "call-with-ctx<r, p0>";
char constantarr_0_244[7] = "get-ctx";
char constantarr_0_245[4] = "*<a>";
char constantarr_0_246[4] = "+<a>";
char constantarr_0_247[11] = "as-const<a>";
char constantarr_0_248[10] = "end-ptr<a>";
char constantarr_0_249[5] = "~=<a>";
char constantarr_0_250[17] = "incr-capacity!<a>";
char constantarr_0_251[18] = "ensure-capacity<a>";
char constantarr_0_252[11] = "capacity<a>";
char constantarr_0_253[7] = "size<a>";
char constantarr_0_254[8] = "inner<a>";
char constantarr_0_255[10] = "backing<a>";
char constantarr_0_256[24] = "increase-capacity-to!<a>";
char constantarr_0_257[6] = "assert";
char constantarr_0_258[11] = "throw<void>";
char constantarr_0_259[8] = "throw<a>";
char constantarr_0_260[17] = "get-exception-ctx";
char constantarr_0_261[21] = "as-ref<exception-ctx>";
char constantarr_0_262[17] = "exception-ctx-ptr";
char constantarr_0_263[18] = "thread-local-stuff";
char constantarr_0_264[17] = "==<__jmp_buf_tag>";
char constantarr_0_265[26] = "!=<mut-ptr<__jmp_buf_tag>>";
char constantarr_0_266[11] = "jmp-buf-ptr";
char constantarr_0_267[19] = "null<__jmp_buf_tag>";
char constantarr_0_268[20] = "set-thrown-exception";
char constantarr_0_269[7] = "longjmp";
char constantarr_0_270[15] = "number-to-throw";
char constantarr_0_271[19] = "hard-unreachable<a>";
char constantarr_0_272[9] = "exception";
char constantarr_0_273[13] = "get-backtrace";
char constantarr_0_274[24] = "try-alloc-backtrace-arrs";
char constantarr_0_275[40] = "try-alloc-uninitialized<const-ptr<nat8>>";
char constantarr_0_276[9] = "try-alloc";
char constantarr_0_277[12] = "try-gc-alloc";
char constantarr_0_278[8] = "acquire!";
char constantarr_0_279[14] = "acquire-recur!";
char constantarr_0_280[12] = "try-acquire!";
char constantarr_0_281[8] = "try-set!";
char constantarr_0_282[11] = "try-change!";
char constantarr_0_283[23] = "compare-exchange-strong";
char constantarr_0_284[12] = "ptr-to<bool>";
char constantarr_0_285[5] = "value";
char constantarr_0_286[23] = "ref-of-val<atomic-bool>";
char constantarr_0_287[9] = "is-locked";
char constantarr_0_288[12] = "yield-thread";
char constantarr_0_289[11] = "sched_yield";
char constantarr_0_290[16] = "ref-of-val<lock>";
char constantarr_0_291[2] = "lk";
char constantarr_0_292[18] = "try-gc-alloc-recur";
char constantarr_0_293[8] = "data-cur";
char constantarr_0_294[8] = "+<nat64>";
char constantarr_0_295[9] = "==<nat64>";
char constantarr_0_296[10] = "<=><nat64>";
char constantarr_0_297[10] = "is-less<a>";
char constantarr_0_298[17] = "<<mut-ptr<nat64>>";
char constantarr_0_299[8] = "data-end";
char constantarr_0_300[10] = "range-free";
char constantarr_0_301[8] = "mark-cur";
char constantarr_0_302[12] = "set-mark-cur";
char constantarr_0_303[12] = "set-data-cur";
char constantarr_0_304[19] = "some<mut-ptr<nat8>>";
char constantarr_0_305[21] = "ptr-cast<nat8, nat64>";
char constantarr_0_306[19] = "maybe-set-needs-gc!";
char constantarr_0_307[7] = "-<bool>";
char constantarr_0_308[10] = "mark-begin";
char constantarr_0_309[10] = "size-words";
char constantarr_0_310[12] = "set-needs-gc";
char constantarr_0_311[8] = "release!";
char constantarr_0_312[11] = "must-unset!";
char constantarr_0_313[10] = "try-unset!";
char constantarr_0_314[6] = "get-gc";
char constantarr_0_315[2] = "gc";
char constantarr_0_316[10] = "get-gc-ctx";
char constantarr_0_317[14] = "as-ref<gc-ctx>";
char constantarr_0_318[10] = "gc-ctx-ptr";
char constantarr_0_319[16] = "some<mut-ptr<a>>";
char constantarr_0_320[17] = "ptr-cast<a, nat8>";
char constantarr_0_321[28] = "try-alloc-uninitialized<sym>";
char constantarr_0_322[51] = "try-alloc-uninitialized<named-val<const-ptr<nat8>>>";
char constantarr_0_323[32] = "size<named-val<const-ptr<nat8>>>";
char constantarr_0_324[8] = "all-funs";
char constantarr_0_325[20] = "some<backtrace-arrs>";
char constantarr_0_326[14] = "backtrace-arrs";
char constantarr_0_327[9] = "backtrace";
char constantarr_0_328[12] = "as<arr<sym>>";
char constantarr_0_329[15] = "unsafe-to-nat64";
char constantarr_0_330[8] = "to-int64";
char constantarr_0_331[9] = "code-ptrs";
char constantarr_0_332[15] = "unsafe-to-int32";
char constantarr_0_333[14] = "code-ptrs-size";
char constantarr_0_334[43] = "copy-data-from!<named-val<const-ptr<nat8>>>";
char constantarr_0_335[6] = "memcpy";
char constantarr_0_336[30] = "as-any-const-ptr<const-ptr<a>>";
char constantarr_0_337[4] = "funs";
char constantarr_0_338[37] = "begin-ptr<named-val<const-ptr<nat8>>>";
char constantarr_0_339[5] = "sort!";
char constantarr_0_340[33] = "swap!<named-val<const-ptr<nat8>>>";
char constantarr_0_341[12] = "subscript<a>";
char constantarr_0_342[16] = "set-subscript<a>";
char constantarr_0_343[12] = "set-deref<a>";
char constantarr_0_344[10] = "partition!";
char constantarr_0_345[9] = "<=><nat8>";
char constantarr_0_346[6] = "<=><a>";
char constantarr_0_347[18] = "<<const-ptr<nat8>>";
char constantarr_0_348[20] = "val<const-ptr<nat8>>";
char constantarr_0_349[6] = "+<sym>";
char constantarr_0_350[10] = "code-names";
char constantarr_0_351[16] = "fill-code-names!";
char constantarr_0_352[7] = "==<sym>";
char constantarr_0_353[8] = "<=><sym>";
char constantarr_0_354[15] = "<<mut-ptr<sym>>";
char constantarr_0_355[14] = "set-deref<sym>";
char constantarr_0_356[12] = "get-fun-name";
char constantarr_0_357[37] = "subscript<named-val<const-ptr<nat8>>>";
char constantarr_0_358[21] = "name<const-ptr<nat8>>";
char constantarr_0_359[18] = "*<const-ptr<nat8>>";
char constantarr_0_360[18] = "+<const-ptr<nat8>>";
char constantarr_0_361[8] = "arr<sym>";
char constantarr_0_362[13] = "as-const<sym>";
char constantarr_0_363[12] = "begin-ptr<a>";
char constantarr_0_364[14] = "set-backing<a>";
char constantarr_0_365[24] = "uninitialized-fix-arr<a>";
char constantarr_0_366[22] = "alloc-uninitialized<a>";
char constantarr_0_367[5] = "alloc";
char constantarr_0_368[8] = "gc-alloc";
char constantarr_0_369[19] = "todo<mut-ptr<nat8>>";
char constantarr_0_370[18] = "copy-data-from!<a>";
char constantarr_0_371[20] = "set-zero-elements<a>";
char constantarr_0_372[11] = "high<nat64>";
char constantarr_0_373[10] = "low<nat64>";
char constantarr_0_374[9] = "..<nat64>";
char constantarr_0_375[8] = "range<a>";
char constantarr_0_376[1] = "+";
char constantarr_0_377[2] = "&&";
char constantarr_0_378[9] = ">=<nat64>";
char constantarr_0_379[24] = "round-up-to-power-of-two";
char constantarr_0_380[30] = "round-up-to-power-of-two-recur";
char constantarr_0_381[1] = "*";
char constantarr_0_382[6] = "forbid";
char constantarr_0_383[11] = "set-size<a>";
char constantarr_0_384[16] = "~=<char>.lambda0";
char constantarr_0_385[8] = "is-empty";
char constantarr_0_386[14] = "is-empty<char>";
char constantarr_0_387[7] = "message";
char constantarr_0_388[9] = "each<sym>";
char constantarr_0_389[12] = "return-stack";
char constantarr_0_390[3] = "str";
char constantarr_0_391[24] = "arr-from-begin-end<char>";
char constantarr_0_392[16] = "<=<const-ptr<a>>";
char constantarr_0_393[4] = "<<a>";
char constantarr_0_394[13] = "find-cstr-end";
char constantarr_0_395[17] = "find-char-in-cstr";
char constantarr_0_396[7] = "to-nat8";
char constantarr_0_397[21] = "some<const-ptr<char>>";
char constantarr_0_398[33] = "hard-unreachable<const-ptr<char>>";
char constantarr_0_399[8] = "to-c-str";
char constantarr_0_400[14] = "to-str.lambda0";
char constantarr_0_401[12] = "move-to-str!";
char constantarr_0_402[18] = "move-to-arr!<char>";
char constantarr_0_403[17] = "cast-immutable<a>";
char constantarr_0_404[19] = "move-to-fix-arr!<a>";
char constantarr_0_405[28] = "set-any-unhandled-exceptions";
char constantarr_0_406[14] = "get-global-ctx";
char constantarr_0_407[18] = "as-ref<global-ctx>";
char constantarr_0_408[8] = "gctx-ptr";
char constantarr_0_409[14] = "island.lambda0";
char constantarr_0_410[19] = "default-log-handler";
char constantarr_0_411[16] = "print-no-newline";
char constantarr_0_412[6] = "stdout";
char constantarr_0_413[7] = "~<char>";
char constantarr_0_414[5] = "level";
char constantarr_0_415[14] = "island.lambda1";
char constantarr_0_416[20] = "ptr-cast<bool, nat8>";
char constantarr_0_417[29] = "as-any-mut-ptr<mut-ptr<bool>>";
char constantarr_0_418[11] = "validate-gc";
char constantarr_0_419[10] = "data-begin";
char constantarr_0_420[9] = "<=><bool>";
char constantarr_0_421[17] = "<=<mut-ptr<bool>>";
char constantarr_0_422[8] = "mark-end";
char constantarr_0_423[18] = "<=<mut-ptr<nat64>>";
char constantarr_0_424[14] = "ref-of-val<gc>";
char constantarr_0_425[19] = "thread-safe-counter";
char constantarr_0_426[18] = "ref-of-val<island>";
char constantarr_0_427[11] = "set-islands";
char constantarr_0_428[11] = "arr<island>";
char constantarr_0_429[14] = "ptr-to<island>";
char constantarr_0_430[13] = "add-main-task";
char constantarr_0_431[13] = "exception-ctx";
char constantarr_0_432[7] = "log-ctx";
char constantarr_0_433[26] = "zeroed<fun1<void, logged>>";
char constantarr_0_434[8] = "perf-ctx";
char constantarr_0_435[22] = "fix-arr<measure-value>";
char constantarr_0_436[29] = "as-any-mut-ptr<exception-ctx>";
char constantarr_0_437[25] = "ref-of-val<exception-ctx>";
char constantarr_0_438[23] = "as-any-mut-ptr<log-ctx>";
char constantarr_0_439[19] = "ref-of-val<log-ctx>";
char constantarr_0_440[24] = "as-any-mut-ptr<perf-ctx>";
char constantarr_0_441[20] = "ref-of-val<perf-ctx>";
char constantarr_0_442[10] = "print-lock";
char constantarr_0_443[3] = "ctx";
char constantarr_0_444[12] = "context-head";
char constantarr_0_445[23] = "size-of<by-val<gc-ctx>>";
char constantarr_0_446[6] = "set-gc";
char constantarr_0_447[12] = "set-next-ctx";
char constantarr_0_448[16] = "set-context-head";
char constantarr_0_449[8] = "next-ctx";
char constantarr_0_450[11] = "set-handler";
char constantarr_0_451[15] = "as-ref<log-ctx>";
char constantarr_0_452[11] = "log-ctx-ptr";
char constantarr_0_453[11] = "log-handler";
char constantarr_0_454[26] = "ref-of-val<island-gc-root>";
char constantarr_0_455[7] = "gc-root";
char constantarr_0_456[26] = "as-any-mut-ptr<global-ctx>";
char constantarr_0_457[2] = "id";
char constantarr_0_458[22] = "as-any-mut-ptr<gc-ctx>";
char constantarr_0_459[30] = "ref-of-val<thread-local-stuff>";
char constantarr_0_460[15] = "ref-of-val<ctx>";
char constantarr_0_461[14] = "add-first-task";
char constantarr_0_462[16] = "then-void<nat64>";
char constantarr_0_463[15] = "then<out, void>";
char constantarr_0_464[15] = "unresolved<out>";
char constantarr_0_465[6] = "fut<a>";
char constantarr_0_466[22] = "fut-state-no-callbacks";
char constantarr_0_467[13] = "callback!<in>";
char constantarr_0_468[15] = "with-lock<void>";
char constantarr_0_469[16] = "call-with-ctx<r>";
char constantarr_0_470[5] = "lk<a>";
char constantarr_0_471[8] = "state<a>";
char constantarr_0_472[12] = "set-state<a>";
char constantarr_0_473[22] = "fut-state-callbacks<a>";
char constantarr_0_474[28] = "some<fut-state-callbacks<a>>";
char constantarr_0_475[37] = "subscript<void, result<a, exception>>";
char constantarr_0_476[5] = "ok<a>";
char constantarr_0_477[8] = "value<a>";
char constantarr_0_478[14] = "err<exception>";
char constantarr_0_479[21] = "callback!<in>.lambda0";
char constantarr_0_480[16] = "forward-to!<out>";
char constantarr_0_481[12] = "callback!<a>";
char constantarr_0_482[20] = "callback!<a>.lambda0";
char constantarr_0_483[21] = "resolve-or-reject!<a>";
char constantarr_0_484[23] = "with-lock<fut-state<a>>";
char constantarr_0_485[21] = "fut-state-resolved<a>";
char constantarr_0_486[16] = "value<exception>";
char constantarr_0_487[29] = "resolve-or-reject!<a>.lambda0";
char constantarr_0_488[18] = "call-callbacks!<a>";
char constantarr_0_489[5] = "cb<a>";
char constantarr_0_490[7] = "next<a>";
char constantarr_0_491[24] = "forward-to!<out>.lambda0";
char constantarr_0_492[18] = "subscript<out, in>";
char constantarr_0_493[10] = "get-island";
char constantarr_0_494[17] = "subscript<island>";
char constantarr_0_495[12] = "unsafe-at<a>";
char constantarr_0_496[7] = "islands";
char constantarr_0_497[27] = "island-and-exclusion<r, p0>";
char constantarr_0_498[8] = "add-task";
char constantarr_0_499[15] = "task-queue-node";
char constantarr_0_500[4] = "task";
char constantarr_0_501[10] = "tasks-lock";
char constantarr_0_502[12] = "insert-task!";
char constantarr_0_503[4] = "size";
char constantarr_0_504[10] = "size-recur";
char constantarr_0_505[4] = "next";
char constantarr_0_506[4] = "head";
char constantarr_0_507[8] = "set-head";
char constantarr_0_508[21] = "some<task-queue-node>";
char constantarr_0_509[4] = "time";
char constantarr_0_510[12] = "insert-recur";
char constantarr_0_511[8] = "set-next";
char constantarr_0_512[5] = "tasks";
char constantarr_0_513[22] = "ref-of-val<task-queue>";
char constantarr_0_514[10] = "broadcast!";
char constantarr_0_515[18] = "pthread_mutex_lock";
char constantarr_0_516[22] = "pthread_cond_broadcast";
char constantarr_0_517[12] = "set-sequence";
char constantarr_0_518[8] = "sequence";
char constantarr_0_519[20] = "pthread_mutex_unlock";
char constantarr_0_520[17] = "may-be-work-to-do";
char constantarr_0_521[4] = "gctx";
char constantarr_0_522[12] = "no-timestamp";
char constantarr_0_523[9] = "exclusion";
char constantarr_0_524[11] = "catch<void>";
char constantarr_0_525[27] = "catch-with-exception-ctx<a>";
char constantarr_0_526[16] = "thrown-exception";
char constantarr_0_527[13] = "__jmp_buf_tag";
char constantarr_0_528[4] = "zero";
char constantarr_0_529[7] = "bytes64";
char constantarr_0_530[7] = "bytes32";
char constantarr_0_531[7] = "bytes16";
char constantarr_0_532[8] = "bytes128";
char constantarr_0_533[15] = "set-jmp-buf-ptr";
char constantarr_0_534[21] = "ptr-to<__jmp_buf_tag>";
char constantarr_0_535[6] = "setjmp";
char constantarr_0_536[23] = "subscript<a, exception>";
char constantarr_0_537[21] = "subscript<fut<r>, p0>";
char constantarr_0_538[10] = "fun<r, p0>";
char constantarr_0_539[34] = "subscript<out, in>.lambda0.lambda0";
char constantarr_0_540[10] = "reject!<r>";
char constantarr_0_541[34] = "subscript<out, in>.lambda0.lambda1";
char constantarr_0_542[26] = "subscript<out, in>.lambda0";
char constantarr_0_543[9] = "value<in>";
char constantarr_0_544[23] = "then<out, void>.lambda0";
char constantarr_0_545[14] = "subscript<out>";
char constantarr_0_546[23] = "island-and-exclusion<r>";
char constantarr_0_547[17] = "subscript<fut<r>>";
char constantarr_0_548[6] = "fun<r>";
char constantarr_0_549[30] = "subscript<out>.lambda0.lambda0";
char constantarr_0_550[30] = "subscript<out>.lambda0.lambda1";
char constantarr_0_551[22] = "subscript<out>.lambda0";
char constantarr_0_552[24] = "then-void<nat64>.lambda0";
char constantarr_0_553[24] = "cur-island-and-exclusion";
char constantarr_0_554[20] = "island-and-exclusion";
char constantarr_0_555[9] = "island-id";
char constantarr_0_556[5] = "delay";
char constantarr_0_557[14] = "resolved<void>";
char constantarr_0_558[21] = "tail<const-ptr<char>>";
char constantarr_0_559[11] = "is-empty<a>";
char constantarr_0_560[36] = "subscript<fut<nat64>, ctx, arr<str>>";
char constantarr_0_561[25] = "map<str, const-ptr<char>>";
char constantarr_0_562[13] = "make-arr<out>";
char constantarr_0_563[17] = "fill-ptr-range<a>";
char constantarr_0_564[23] = "fill-ptr-range-recur<a>";
char constantarr_0_565[9] = "!=<nat64>";
char constantarr_0_566[19] = "subscript<a, nat64>";
char constantarr_0_567[13] = "subscript<in>";
char constantarr_0_568[33] = "map<str, const-ptr<char>>.lambda0";
char constantarr_0_569[30] = "add-first-task.lambda0.lambda0";
char constantarr_0_570[22] = "add-first-task.lambda0";
char constantarr_0_571[24] = "handle-exceptions<nat64>";
char constantarr_0_572[26] = "subscript<void, exception>";
char constantarr_0_573[17] = "exception-handler";
char constantarr_0_574[14] = "get-cur-island";
char constantarr_0_575[32] = "handle-exceptions<nat64>.lambda0";
char constantarr_0_576[21] = "add-main-task.lambda0";
char constantarr_0_577[84] = "call-with-ctx<fut<nat64>, arr<const-ptr<char>>, fun-ptr2<fut<nat64>, ctx, arr<str>>>";
char constantarr_0_578[11] = "run-threads";
char constantarr_0_579[45] = "unmanaged-alloc-elements<by-val<thread-args>>";
char constantarr_0_580[19] = "start-threads-recur";
char constantarr_0_581[22] = "+<by-val<thread-args>>";
char constantarr_0_582[30] = "set-deref<by-val<thread-args>>";
char constantarr_0_583[11] = "thread-args";
char constantarr_0_584[17] = "create-one-thread";
char constantarr_0_585[14] = "pthread_create";
char constantarr_0_586[9] = "!=<int32>";
char constantarr_0_587[6] = "EAGAIN";
char constantarr_0_588[14] = "as-cell<nat64>";
char constantarr_0_589[15] = "as-ref<cell<a>>";
char constantarr_0_590[44] = "as-any-mut-ptr<mut-ptr<by-val<thread-args>>>";
char constantarr_0_591[10] = "thread-fun";
char constantarr_0_592[19] = "as-ref<thread-args>";
char constantarr_0_593[15] = "thread-function";
char constantarr_0_594[21] = "thread-function-recur";
char constantarr_0_595[12] = "is-shut-down";
char constantarr_0_596[18] = "set-n-live-threads";
char constantarr_0_597[14] = "n-live-threads";
char constantarr_0_598[28] = "assert-islands-are-shut-down";
char constantarr_0_599[16] = "noctx-at<island>";
char constantarr_0_600[11] = "hard-forbid";
char constantarr_0_601[8] = "needs-gc";
char constantarr_0_602[17] = "n-threads-running";
char constantarr_0_603[25] = "is-empty<task-queue-node>";
char constantarr_0_604[12] = "get-sequence";
char constantarr_0_605[11] = "choose-task";
char constantarr_0_606[17] = "get-monotime-nsec";
char constantarr_0_607[14] = "cell<timespec>";
char constantarr_0_608[8] = "timespec";
char constantarr_0_609[13] = "clock_gettime";
char constantarr_0_610[26] = "ref-of-val<cell<timespec>>";
char constantarr_0_611[11] = "*<timespec>";
char constantarr_0_612[14] = "inner-value<a>";
char constantarr_0_613[6] = "tv-sec";
char constantarr_0_614[7] = "tv-nsec";
char constantarr_0_615[11] = "todo<nat64>";
char constantarr_0_616[17] = "choose-task-recur";
char constantarr_0_617[14] = "no-chosen-task";
char constantarr_0_618[21] = "choose-task-in-island";
char constantarr_0_619[7] = "do-a-gc";
char constantarr_0_620[7] = "no-task";
char constantarr_0_621[9] = "pop-task!";
char constantarr_0_622[26] = "ref-of-val<mut-arr<nat64>>";
char constantarr_0_623[28] = "currently-running-exclusions";
char constantarr_0_624[9] = "in<nat64>";
char constantarr_0_625[5] = "in<a>";
char constantarr_0_626[11] = "in-recur<a>";
char constantarr_0_627[11] = "noctx-at<a>";
char constantarr_0_628[14] = "temp-as-arr<a>";
char constantarr_0_629[18] = "temp-as-fix-arr<a>";
char constantarr_0_630[10] = "pop-recur!";
char constantarr_0_631[11] = "to-opt-time";
char constantarr_0_632[11] = "some<nat64>";
char constantarr_0_633[40] = "push-capacity-must-be-sufficient!<nat64>";
char constantarr_0_634[10] = "is-no-task";
char constantarr_0_635[21] = "set-n-threads-running";
char constantarr_0_636[11] = "chosen-task";
char constantarr_0_637[9] = "any-tasks";
char constantarr_0_638[8] = "min-time";
char constantarr_0_639[10] = "min<nat64>";
char constantarr_0_640[15] = "first-task-time";
char constantarr_0_641[28] = "no-tasks-and-last-thread-out";
char constantarr_0_642[7] = "do-task";
char constantarr_0_643[11] = "task-island";
char constantarr_0_644[10] = "task-or-gc";
char constantarr_0_645[6] = "action";
char constantarr_0_646[12] = "return-task!";
char constantarr_0_647[35] = "noctx-must-remove-unordered!<nat64>";
char constantarr_0_648[37] = "noctx-must-remove-unordered-recur!<a>";
char constantarr_0_649[7] = "drop<a>";
char constantarr_0_650[29] = "noctx-remove-unordered-at!<a>";
char constantarr_0_651[10] = "return-ctx";
char constantarr_0_652[13] = "return-gc-ctx";
char constantarr_0_653[12] = "some<gc-ctx>";
char constantarr_0_654[46] = "run-garbage-collection<by-val<island-gc-root>>";
char constantarr_0_655[12] = "set-gc-count";
char constantarr_0_656[8] = "gc-count";
char constantarr_0_657[8] = "mark-ctx";
char constantarr_0_658[13] = "mark-visit<a>";
char constantarr_0_659[20] = "ref-of-val<mark-ctx>";
char constantarr_0_660[15] = "clear-free-mem!";
char constantarr_0_661[17] = "!=<mut-ptr<bool>>";
char constantarr_0_662[16] = "set-is-shut-down";
char constantarr_0_663[7] = "wait-on";
char constantarr_0_664[17] = "pthread_cond_wait";
char constantarr_0_665[11] = "to-timespec";
char constantarr_0_666[10] = "unsafe-mod";
char constantarr_0_667[22] = "pthread_cond_timedwait";
char constantarr_0_668[16] = "ptr-to<timespec>";
char constantarr_0_669[9] = "ETIMEDOUT";
char constantarr_0_670[9] = "thread-id";
char constantarr_0_671[18] = "join-threads-recur";
char constantarr_0_672[15] = "join-one-thread";
char constantarr_0_673[19] = "cell<mut-ptr<nat8>>";
char constantarr_0_674[12] = "pthread_join";
char constantarr_0_675[31] = "ref-of-val<cell<mut-ptr<nat8>>>";
char constantarr_0_676[6] = "EINVAL";
char constantarr_0_677[5] = "ESRCH";
char constantarr_0_678[16] = "*<mut-ptr<nat8>>";
char constantarr_0_679[21] = "unmanaged-free<nat64>";
char constantarr_0_680[4] = "free";
char constantarr_0_681[35] = "unmanaged-free<by-val<thread-args>>";
char constantarr_0_682[17] = "destroy-condition";
char constantarr_0_683[25] = "pthread_mutexattr_destroy";
char constantarr_0_684[21] = "pthread_mutex_destroy";
char constantarr_0_685[24] = "pthread_condattr_destroy";
char constantarr_0_686[20] = "pthread_cond_destroy";
char constantarr_0_687[24] = "any-unhandled-exceptions";
char constantarr_0_688[4] = "main";
char constantarr_0_689[15] = "resolved<nat64>";
char constantarr_0_690[16] = "parse-named-args";
char constantarr_0_691[21] = "parse-command-dynamic";
char constantarr_0_692[15] = "find-index<str>";
char constantarr_0_693[19] = "find-index-recur<a>";
char constantarr_0_694[18] = "subscript<bool, a>";
char constantarr_0_695[11] = "starts-with";
char constantarr_0_696[15] = "arr-equal<char>";
char constantarr_0_697[14] = "equal-recur<a>";
char constantarr_0_698[17] = "starts-with<char>";
char constantarr_0_699[29] = "parse-command-dynamic.lambda0";
char constantarr_0_700[14] = "parsed-command";
char constantarr_0_701[9] = "cmp<nat8>";
char constantarr_0_702[17] = "arr-compare<char>";
char constantarr_0_703[16] = "compare-recur<a>";
char constantarr_0_704[8] = "hash-mix";
char constantarr_0_705[7] = "set-cur";
char constantarr_0_706[3] = "cur";
char constantarr_0_707[8] = "to-nat64";
char constantarr_0_708[16] = "hash-mix.lambda0";
char constantarr_0_709[19] = "dict<str, arr<str>>";
char constantarr_0_710[17] = "size<arrow<k, v>>";
char constantarr_0_711[23] = "no-duplicate-keys<k, v>";
char constantarr_0_712[10] = "from<k, v>";
char constantarr_0_713[22] = "subscript<arrow<k, v>>";
char constantarr_0_714[18] = "every<arrow<k, v>>";
char constantarr_0_715[7] = "tail<a>";
char constantarr_0_716[5] = "!=<k>";
char constantarr_0_717[31] = "no-duplicate-keys<k, v>.lambda0";
char constantarr_0_718[10] = "dict<k, v>";
char constantarr_0_719[15] = "leaf-node<k, v>";
char constantarr_0_720[29] = "fold<dict<k, v>, arrow<k, v>>";
char constantarr_0_721[16] = "fold-recur<a, b>";
char constantarr_0_722[5] = "==<b>";
char constantarr_0_723[18] = "subscript<a, a, b>";
char constantarr_0_724[24] = "call-with-ctx<r, p0, p1>";
char constantarr_0_725[10] = "end-ptr<b>";
char constantarr_0_726[21] = "empty-leaf-node<k, v>";
char constantarr_0_727[7] = "~<k, v>";
char constantarr_0_728[19] = "get-or-update<k, v>";
char constantarr_0_729[7] = "hash<k>";
char constantarr_0_730[6] = "hasher";
char constantarr_0_731[18] = "ref-of-val<hasher>";
char constantarr_0_732[10] = "root<k, v>";
char constantarr_0_733[25] = "get-or-update-recur<k, v>";
char constantarr_0_734[8] = "low-bits";
char constantarr_0_735[16] = "size<node<k, v>>";
char constantarr_0_736[14] = "children<k, v>";
char constantarr_0_737[22] = "unsafe-bit-shift-right";
char constantarr_0_738[21] = "subscript<node<k, v>>";
char constantarr_0_739[14] = "new-node<k, v>";
char constantarr_0_740[18] = "update-child<k, v>";
char constantarr_0_741[24] = "inner-node-to-leaf<k, v>";
char constantarr_0_742[34] = "fold-with-index<nat64, node<k, v>>";
char constantarr_0_743[27] = "fold-with-index-recur<a, b>";
char constantarr_0_744[25] = "subscript<a, a, b, nat64>";
char constantarr_0_745[28] = "call-with-ctx<r, p0, p1, p2>";
char constantarr_0_746[11] = "pairs<k, v>";
char constantarr_0_747[32] = "inner-node-to-leaf<k, v>.lambda0";
char constantarr_0_748[13] = "leaf-max-size";
char constantarr_0_749[34] = "uninitialized-fix-arr<arrow<k, v>>";
char constantarr_0_750[18] = "unreachable<nat64>";
char constantarr_0_751[23] = "copy-from!<arrow<k, v>>";
char constantarr_0_752[32] = "inner-node-to-leaf<k, v>.lambda1";
char constantarr_0_753[21] = "some<leaf-node<k, v>>";
char constantarr_0_754[27] = "cast-immutable<arrow<k, v>>";
char constantarr_0_755[19] = "node-is-empty<k, v>";
char constantarr_0_756[17] = "rtail<node<k, v>>";
char constantarr_0_757[16] = "inner-node<k, v>";
char constantarr_0_758[18] = "update<node<k, v>>";
char constantarr_0_759[4] = "~<a>";
char constantarr_0_760[31] = "find-only-non-empty-child<k, v>";
char constantarr_0_761[12] = "force<nat64>";
char constantarr_0_762[8] = "force<a>";
char constantarr_0_763[22] = "find-index<node<k, v>>";
char constantarr_0_764[39] = "find-only-non-empty-child<k, v>.lambda0";
char constantarr_0_765[17] = "every<node<k, v>>";
char constantarr_0_766[39] = "find-only-non-empty-child<k, v>.lambda1";
char constantarr_0_767[16] = "some<node<k, v>>";
char constantarr_0_768[26] = "get-or-update-result<k, v>";
char constantarr_0_769[15] = "old-value<k, v>";
char constantarr_0_770[42] = "subscript<get-or-update-action<v>, opt<v>>";
char constantarr_0_771[8] = "-><k, v>";
char constantarr_0_772[11] = "arrow<a, b>";
char constantarr_0_773[8] = "value<v>";
char constantarr_0_774[31] = "update-with-default<node<k, v>>";
char constantarr_0_775[11] = "make-arr<a>";
char constantarr_0_776[39] = "update-with-default<node<k, v>>.lambda0";
char constantarr_0_777[24] = "get-or-update-leaf<k, v>";
char constantarr_0_778[23] = "find-index<arrow<k, v>>";
char constantarr_0_779[32] = "get-or-update-leaf<k, v>.lambda0";
char constantarr_0_780[20] = "new-inner-node<k, v>";
char constantarr_0_781[24] = "fold<nat64, arrow<k, v>>";
char constantarr_0_782[10] = "max<nat64>";
char constantarr_0_783[28] = "new-inner-node<k, v>.lambda0";
char constantarr_0_784[24] = "fill-fix-arr<node<k, v>>";
char constantarr_0_785[15] = "make-fix-arr<a>";
char constantarr_0_786[32] = "fill-fix-arr<node<k, v>>.lambda0";
char constantarr_0_787[25] = "set-subscript<node<k, v>>";
char constantarr_0_788[17] = "unsafe-set-at!<a>";
char constantarr_0_789[17] = "each<arrow<k, v>>";
char constantarr_0_790[23] = "unreachable<node<k, v>>";
char constantarr_0_791[14] = "~<arrow<k, v>>";
char constantarr_0_792[28] = "new-inner-node<k, v>.lambda1";
char constantarr_0_793[26] = "cast-immutable<node<k, v>>";
char constantarr_0_794[8] = "to<k, v>";
char constantarr_0_795[7] = "some<v>";
char constantarr_0_796[22] = "remove-at<arrow<k, v>>";
char constantarr_0_797[19] = "update<arrow<k, v>>";
char constantarr_0_798[9] = "insert<v>";
char constantarr_0_799[15] = "~<k, v>.lambda0";
char constantarr_0_800[27] = "dict<str, arr<str>>.lambda0";
char constantarr_0_801[14] = "subscript<str>";
char constantarr_0_802[29] = "parse-command-dynamic.lambda1";
char constantarr_0_803[23] = "mut-dict<str, arr<str>>";
char constantarr_0_804[14] = "mut-dict<k, v>";
char constantarr_0_805[20] = "fix-arr<entry<k, v>>";
char constantarr_0_806[22] = "parse-named-args-recur";
char constantarr_0_807[10] = "force<str>";
char constantarr_0_808[16] = "try-remove-start";
char constantarr_0_809[22] = "try-remove-start<char>";
char constantarr_0_810[12] = "some<arr<a>>";
char constantarr_0_811[9] = "some<str>";
char constantarr_0_812[9] = "tail<str>";
char constantarr_0_813[30] = "parse-named-args-recur.lambda0";
char constantarr_0_814[28] = "set-subscript<str, arr<str>>";
char constantarr_0_815[12] = "drop<opt<v>>";
char constantarr_0_816[13] = "update!<k, v>";
char constantarr_0_817[21] = "is-empty<entry<k, v>>";
char constantarr_0_818[13] = "entries<k, v>";
char constantarr_0_819[17] = "set-entries<k, v>";
char constantarr_0_820[28] = "fix-arr<entry<k, v>>.lambda0";
char constantarr_0_821[20] = "set-total-size<k, v>";
char constantarr_0_822[22] = "subscript<entry<k, v>>";
char constantarr_0_823[26] = "set-subscript<entry<k, v>>";
char constantarr_0_824[16] = "total-size<k, v>";
char constantarr_0_825[19] = "should-expand<k, v>";
char constantarr_0_826[13] = "expand!<k, v>";
char constantarr_0_827[28] = "mut-dict-with-capacity<k, v>";
char constantarr_0_828[25] = "fill-fix-arr<entry<k, v>>";
char constantarr_0_829[33] = "fill-fix-arr<entry<k, v>>.lambda0";
char constantarr_0_830[10] = "each<k, v>";
char constantarr_0_831[16] = "fold<void, k, v>";
char constantarr_0_832[20] = "fold<a, entry<k, v>>";
char constantarr_0_833[10] = "fold<a, b>";
char constantarr_0_834[14] = "temp-as-arr<b>";
char constantarr_0_835[21] = "subscript<a, a, k, v>";
char constantarr_0_836[20] = "fold<a, arrow<k, v>>";
char constantarr_0_837[32] = "fold<void, k, v>.lambda0.lambda0";
char constantarr_0_838[24] = "fold<void, k, v>.lambda0";
char constantarr_0_839[21] = "subscript<void, k, v>";
char constantarr_0_840[18] = "each<k, v>.lambda0";
char constantarr_0_841[21] = "expand!<k, v>.lambda0";
char constantarr_0_842[11] = "swap!<k, v>";
char constantarr_0_843[20] = "mut-arr<arrow<k, v>>";
char constantarr_0_844[13] = "~=<a>.lambda0";
char constantarr_0_845[21] = "update!<k, v>.lambda0";
char constantarr_0_846[27] = "is-at-capacity<arrow<k, v>>";
char constantarr_0_847[17] = "drop<arrow<k, v>>";
char constantarr_0_848[33] = "remove-unordered-at!<arrow<k, v>>";
char constantarr_0_849[21] = "is-empty<arrow<k, v>>";
char constantarr_0_850[26] = "set-subscript<arrow<k, v>>";
char constantarr_0_851[28] = "move-to-dict!<str, arr<str>>";
char constantarr_0_852[29] = "map-to-arr<arrow<k, v>, k, v>";
char constantarr_0_853[10] = "size<k, v>";
char constantarr_0_854[24] = "fold<mut-ptr<out>, k, v>";
char constantarr_0_855[40] = "fold<mut-ptr<out>, k, v>.lambda0.lambda0";
char constantarr_0_856[32] = "fold<mut-ptr<out>, k, v>.lambda0";
char constantarr_0_857[20] = "subscript<out, k, v>";
char constantarr_0_858[37] = "map-to-arr<arrow<k, v>, k, v>.lambda0";
char constantarr_0_859[12] = "end-ptr<out>";
char constantarr_0_860[36] = "move-to-dict!<str, arr<str>>.lambda0";
char constantarr_0_861[12] = "empty!<k, v>";
char constantarr_0_862[18] = "fill!<entry<k, v>>";
char constantarr_0_863[7] = "map!<a>";
char constantarr_0_864[13] = "map-recur!<a>";
char constantarr_0_865[14] = "!=<mut-ptr<a>>";
char constantarr_0_866[15] = "subscript<a, a>";
char constantarr_0_867[26] = "fill!<entry<k, v>>.lambda0";
char constantarr_0_868[8] = "nameless";
char constantarr_0_869[5] = "after";
char constantarr_0_870[27] = "fill-mut-arr<opt<arr<str>>>";
char constantarr_0_871[15] = "fill-fix-arr<a>";
char constantarr_0_872[23] = "fill-fix-arr<a>.lambda0";
char constantarr_0_873[10] = "cell<bool>";
char constantarr_0_874[19] = "each<str, arr<str>>";
char constantarr_0_875[19] = "fold-recur<a, k, v>";
char constantarr_0_876[19] = "fold<a, node<k, v>>";
char constantarr_0_877[27] = "fold-recur<a, k, v>.lambda0";
char constantarr_0_878[27] = "fold-recur<a, k, v>.lambda1";
char constantarr_0_879[27] = "each<str, arr<str>>.lambda0";
char constantarr_0_880[5] = "named";
char constantarr_0_881[13] = "index-of<str>";
char constantarr_0_882[9] = "ptr-of<a>";
char constantarr_0_883[15] = "ptr-of-recur<a>";
char constantarr_0_884[18] = "some<const-ptr<a>>";
char constantarr_0_885[18] = "set-inner-value<a>";
char constantarr_0_886[6] = "finish";
char constantarr_0_887[5] = "inner";
char constantarr_0_888[15] = "with-value<str>";
char constantarr_0_889[8] = "with-str";
char constantarr_0_890[6] = "interp";
char constantarr_0_891[18] = "is-empty<arr<str>>";
char constantarr_0_892[24] = "subscript<opt<arr<str>>>";
char constantarr_0_893[28] = "set-subscript<opt<arr<str>>>";
char constantarr_0_894[24] = "parse-named-args.lambda0";
char constantarr_0_895[24] = "some<arr<opt<arr<str>>>>";
char constantarr_0_896[27] = "move-to-arr!<opt<arr<str>>>";
char constantarr_0_897[10] = "print-help";
char constantarr_0_898[9] = "parse-nat";
char constantarr_0_899[18] = "with-reader<nat64>";
char constantarr_0_900[6] = "reader";
char constantarr_0_901[25] = "subscript<opt<a>, reader>";
char constantarr_0_902[3] = "end";
char constantarr_0_903[9] = "take-nat!";
char constantarr_0_904[13] = "char-to-nat64";
char constantarr_0_905[4] = "peek";
char constantarr_0_906[10] = "drop<char>";
char constantarr_0_907[5] = "next!";
char constantarr_0_908[15] = "take-nat-recur!";
char constantarr_0_909[17] = "parse-nat.lambda0";
char constantarr_0_910[7] = "do-test";
char constantarr_0_911[11] = "parent-path";
char constantarr_0_912[16] = "r-index-of<char>";
char constantarr_0_913[14] = "find-rindex<a>";
char constantarr_0_914[20] = "find-rindex-recur<a>";
char constantarr_0_915[24] = "r-index-of<char>.lambda0";
char constantarr_0_916[10] = "child-path";
char constantarr_0_917[11] = "get-environ";
char constantarr_0_918[18] = "mut-dict<str, str>";
char constantarr_0_919[17] = "get-environ-recur";
char constantarr_0_920[10] = "null<char>";
char constantarr_0_921[7] = "null<a>";
char constantarr_0_922[19] = "parse-environ-entry";
char constantarr_0_923[21] = "todo<arrow<str, str>>";
char constantarr_0_924[12] = "-><str, str>";
char constantarr_0_925[23] = "set-subscript<str, str>";
char constantarr_0_926[4] = "*<b>";
char constantarr_0_927[4] = "+<b>";
char constantarr_0_928[12] = "begin-ptr<b>";
char constantarr_0_929[13] = "find-index<a>";
char constantarr_0_930[7] = "environ";
char constantarr_0_931[23] = "move-to-dict!<str, str>";
char constantarr_0_932[18] = "dict<k, v>.lambda0";
char constantarr_0_933[31] = "move-to-dict!<str, str>.lambda0";
char constantarr_0_934[14] = "first-failures";
char constantarr_0_935[36] = "subscript<result<str, arr<failure>>>";
char constantarr_0_936[7] = "ok<str>";
char constantarr_0_937[10] = "value<str>";
char constantarr_0_938[14] = "run-crow-tests";
char constantarr_0_939[10] = "list-tests";
char constantarr_0_940[12] = "mut-arr<str>";
char constantarr_0_941[20] = "each-child-recursive";
char constantarr_0_942[28] = "each-child-recursive.lambda0";
char constantarr_0_943[6] = "is-dir";
char constantarr_0_944[8] = "get-stat";
char constantarr_0_945[4] = "stat";
char constantarr_0_946[10] = "some<stat>";
char constantarr_0_947[5] = "errno";
char constantarr_0_948[8] = "*<int32>";
char constantarr_0_949[16] = "__errno_location";
char constantarr_0_950[6] = "ENOENT";
char constantarr_0_951[15] = "todo<opt<stat>>";
char constantarr_0_952[11] = "throw<bool>";
char constantarr_0_953[27] = "with-value<const-ptr<char>>";
char constantarr_0_954[7] = "st_mode";
char constantarr_0_955[6] = "S_IFMT";
char constantarr_0_956[7] = "S_IFDIR";
char constantarr_0_957[9] = "each<str>";
char constantarr_0_958[8] = "read-dir";
char constantarr_0_959[7] = "opendir";
char constantarr_0_960[19] = "==<const-ptr<nat8>>";
char constantarr_0_961[28] = "!=<mut-ptr<const-ptr<nat8>>>";
char constantarr_0_962[42] = "ptr-cast-from-extern<const-ptr<nat8>, dir>";
char constantarr_0_963[21] = "null<const-ptr<nat8>>";
char constantarr_0_964[14] = "read-dir-recur";
char constantarr_0_965[6] = "dirent";
char constantarr_0_966[8] = "bytes256";
char constantarr_0_967[12] = "cell<dirent>";
char constantarr_0_968[9] = "readdir_r";
char constantarr_0_969[19] = "!=<const-ptr<nat8>>";
char constantarr_0_970[24] = "as-any-const-ptr<dirent>";
char constantarr_0_971[9] = "*<dirent>";
char constantarr_0_972[14] = "ref-eq<dirent>";
char constantarr_0_973[15] = "get-dirent-name";
char constantarr_0_974[14] = "size-of<int64>";
char constantarr_0_975[14] = "size-of<nat16>";
char constantarr_0_976[7] = "+<nat8>";
char constantarr_0_977[20] = "ptr-cast<char, nat8>";
char constantarr_0_978[7] = "~=<str>";
char constantarr_0_979[9] = "sort<str>";
char constantarr_0_980[7] = "sort<a>";
char constantarr_0_981[18] = "fix-arr<a>.lambda0";
char constantarr_0_982[8] = "sort!<a>";
char constantarr_0_983[24] = "insertion-sort-recur!<a>";
char constantarr_0_984[10] = "insert!<a>";
char constantarr_0_985[27] = "subscript<comparison, a, a>";
char constantarr_0_986[17] = "sort<str>.lambda0";
char constantarr_0_987[17] = "move-to-arr!<str>";
char constantarr_0_988[10] = "has-substr";
char constantarr_0_989[21] = "contains-subseq<char>";
char constantarr_0_990[18] = "index-of-subseq<a>";
char constantarr_0_991[24] = "index-of-subseq-recur<a>";
char constantarr_0_992[11] = "ext-is-crow";
char constantarr_0_993[14] = "opt-equal<str>";
char constantarr_0_994[13] = "get-extension";
char constantarr_0_995[13] = "last-index-of";
char constantarr_0_996[10] = "last<char>";
char constantarr_0_997[7] = "some<a>";
char constantarr_0_998[11] = "rtail<char>";
char constantarr_0_999[9] = "base-name";
char constantarr_0_1000[18] = "list-tests.lambda0";
char constantarr_0_1001[10] = "match-test";
char constantarr_0_1002[36] = "flat-map-with-max-size<failure, str>";
char constantarr_0_1003[12] = "mut-arr<out>";
char constantarr_0_1004[9] = "size<out>";
char constantarr_0_1005[7] = "~=<out>";
char constantarr_0_1006[15] = "~=<out>.lambda0";
char constantarr_0_1007[23] = "subscript<arr<out>, in>";
char constantarr_0_1008[30] = "reduce-size-if-more-than!<out>";
char constantarr_0_1009[12] = "drop<opt<a>>";
char constantarr_0_1010[7] = "pop!<a>";
char constantarr_0_1011[44] = "flat-map-with-max-size<failure, str>.lambda0";
char constantarr_0_1012[17] = "move-to-arr!<out>";
char constantarr_0_1013[20] = "run-single-crow-test";
char constantarr_0_1014[29] = "first-some<arr<failure>, str>";
char constantarr_0_1015[23] = "subscript<opt<out>, in>";
char constantarr_0_1016[13] = "is-empty<out>";
char constantarr_0_1017[14] = "run-print-test";
char constantarr_0_1018[21] = "spawn-and-wait-result";
char constantarr_0_1019[14] = "fold<str, str>";
char constantarr_0_1020[29] = "spawn-and-wait-result.lambda0";
char constantarr_0_1021[7] = "is-file";
char constantarr_0_1022[7] = "S_IFREG";
char constantarr_0_1023[10] = "make-pipes";
char constantarr_0_1024[5] = "pipes";
char constantarr_0_1025[17] = "check-posix-error";
char constantarr_0_1026[4] = "pipe";
char constantarr_0_1027[26] = "posix_spawn_file_actions_t";
char constantarr_0_1028[29] = "posix_spawn_file_actions_init";
char constantarr_0_1029[33] = "posix_spawn_file_actions_addclose";
char constantarr_0_1030[10] = "write-pipe";
char constantarr_0_1031[32] = "posix_spawn_file_actions_adddup2";
char constantarr_0_1032[9] = "read-pipe";
char constantarr_0_1033[11] = "cell<int32>";
char constantarr_0_1034[11] = "posix_spawn";
char constantarr_0_1035[5] = "close";
char constantarr_0_1036[12] = "keep-polling";
char constantarr_0_1037[23] = "fix-arr<by-val<pollfd>>";
char constantarr_0_1038[31] = "fix-arr<by-val<pollfd>>.lambda0";
char constantarr_0_1039[6] = "pollfd";
char constantarr_0_1040[6] = "POLLIN";
char constantarr_0_1041[21] = "ref-of-val-at<pollfd>";
char constantarr_0_1042[15] = "size<by-val<a>>";
char constantarr_0_1043[13] = "ref-of-ptr<a>";
char constantarr_0_1044[13] = "ref-of-val<a>";
char constantarr_0_1045[4] = "poll";
char constantarr_0_1046[14] = "handle-revents";
char constantarr_0_1047[7] = "revents";
char constantarr_0_1048[10] = "has-POLLIN";
char constantarr_0_1049[14] = "bits-intersect";
char constantarr_0_1050[9] = "!=<int16>";
char constantarr_0_1051[24] = "read-to-buffer-until-eof";
char constantarr_0_1052[22] = "unsafe-set-size!<char>";
char constantarr_0_1053[10] = "reserve<a>";
char constantarr_0_1054[4] = "read";
char constantarr_0_1055[10] = "cmp<int64>";
char constantarr_0_1056[8] = "<<int64>";
char constantarr_0_1057[2] = "fd";
char constantarr_0_1058[11] = "has-POLLHUP";
char constantarr_0_1059[7] = "POLLHUP";
char constantarr_0_1060[11] = "has-POLLPRI";
char constantarr_0_1061[7] = "POLLPRI";
char constantarr_0_1062[11] = "has-POLLOUT";
char constantarr_0_1063[7] = "POLLOUT";
char constantarr_0_1064[11] = "has-POLLERR";
char constantarr_0_1065[7] = "POLLERR";
char constantarr_0_1066[12] = "has-POLLNVAL";
char constantarr_0_1067[8] = "POLLNVAL";
char constantarr_0_1068[21] = "handle-revents-result";
char constantarr_0_1069[3] = "any";
char constantarr_0_1070[10] = "had-POLLIN";
char constantarr_0_1071[7] = "hung-up";
char constantarr_0_1072[22] = "wait-and-get-exit-code";
char constantarr_0_1073[7] = "waitpid";
char constantarr_0_1074[9] = "WIFEXITED";
char constantarr_0_1075[8] = "WTERMSIG";
char constantarr_0_1076[11] = "WEXITSTATUS";
char constantarr_0_1077[2] = ">>";
char constantarr_0_1078[10] = "cmp<int32>";
char constantarr_0_1079[8] = "<<int32>";
char constantarr_0_1080[11] = "todo<int32>";
char constantarr_0_1081[11] = "WIFSIGNALED";
char constantarr_0_1082[7] = "to-base";
char constantarr_0_1083[12] = "digit-to-str";
char constantarr_0_1084[3] = "mod";
char constantarr_0_1085[3] = "abs";
char constantarr_0_1086[17] = "with-value<int32>";
char constantarr_0_1087[10] = "WIFSTOPPED";
char constantarr_0_1088[12] = "WIFCONTINUED";
char constantarr_0_1089[14] = "process-result";
char constantarr_0_1090[12] = "convert-args";
char constantarr_0_1091[18] = "~<const-ptr<char>>";
char constantarr_0_1092[25] = "map<const-ptr<char>, str>";
char constantarr_0_1093[33] = "map<const-ptr<char>, str>.lambda0";
char constantarr_0_1094[20] = "convert-args.lambda0";
char constantarr_0_1095[15] = "convert-environ";
char constantarr_0_1096[24] = "mut-arr<const-ptr<char>>";
char constantarr_0_1097[14] = "each<str, str>";
char constantarr_0_1098[22] = "each<str, str>.lambda0";
char constantarr_0_1099[19] = "~=<const-ptr<char>>";
char constantarr_0_1100[23] = "convert-environ.lambda0";
char constantarr_0_1101[19] = "as<const-ptr<char>>";
char constantarr_0_1102[29] = "move-to-arr!<const-ptr<char>>";
char constantarr_0_1103[21] = "throw<process-result>";
char constantarr_0_1104[9] = "exit-code";
char constantarr_0_1105[13] = "handle-output";
char constantarr_0_1106[13] = "try-read-file";
char constantarr_0_1107[4] = "open";
char constantarr_0_1108[8] = "O_RDONLY";
char constantarr_0_1109[14] = "todo<opt<str>>";
char constantarr_0_1110[5] = "lseek";
char constantarr_0_1111[8] = "seek-end";
char constantarr_0_1112[8] = "seek-set";
char constantarr_0_1113[20] = "ptr-cast<nat8, char>";
char constantarr_0_1114[10] = "write-file";
char constantarr_0_1115[1] = "|";
char constantarr_0_1116[2] = "<<";
char constantarr_0_1117[10] = "cmp<nat32>";
char constantarr_0_1118[8] = "<<nat32>";
char constantarr_0_1119[15] = "unsafe-to-nat32";
char constantarr_0_1120[21] = "unsafe-bit-shift-left";
char constantarr_0_1121[7] = "O_CREAT";
char constantarr_0_1122[8] = "O_WRONLY";
char constantarr_0_1123[7] = "O_TRUNC";
char constantarr_0_1124[17] = "with-value<nat32>";
char constantarr_0_1125[9] = "max-int64";
char constantarr_0_1126[7] = "failure";
char constantarr_0_1127[17] = "is-empty<failure>";
char constantarr_0_1128[17] = "print-test-result";
char constantarr_0_1129[13] = "remove-colors";
char constantarr_0_1130[20] = "remove-colors-recur!";
char constantarr_0_1131[10] = "tail<char>";
char constantarr_0_1132[22] = "remove-colors-recur-2!";
char constantarr_0_1133[11] = "should-stop";
char constantarr_0_1134[18] = "some<arr<failure>>";
char constantarr_0_1135[8] = "failures";
char constantarr_0_1136[28] = "run-single-crow-test.lambda0";
char constantarr_0_1137[24] = "run-single-runnable-test";
char constantarr_0_1138[10] = "~<failure>";
char constantarr_0_1139[22] = "run-crow-tests.lambda0";
char constantarr_0_1140[17] = "with-value<nat64>";
char constantarr_0_1141[17] = "err<arr<failure>>";
char constantarr_0_1142[23] = "do-test.lambda0.lambda0";
char constantarr_0_1143[15] = "do-test.lambda0";
char constantarr_0_1144[4] = "lint";
char constantarr_0_1145[19] = "list-lintable-files";
char constantarr_0_1146[18] = "excluded-from-lint";
char constantarr_0_1147[7] = "in<str>";
char constantarr_0_1148[11] = "exists<str>";
char constantarr_0_1149[9] = "ends-with";
char constantarr_0_1150[15] = "ends-with<char>";
char constantarr_0_1151[26] = "excluded-from-lint.lambda0";
char constantarr_0_1152[27] = "list-lintable-files.lambda0";
char constantarr_0_1153[31] = "should-ignore-extension-of-name";
char constantarr_0_1154[23] = "should-ignore-extension";
char constantarr_0_1155[18] = "ignored-extensions";
char constantarr_0_1156[27] = "list-lintable-files.lambda1";
char constantarr_0_1157[9] = "lint-file";
char constantarr_0_1158[9] = "read-file";
char constantarr_0_1159[20] = "each-with-index<str>";
char constantarr_0_1160[24] = "each-with-index-recur<a>";
char constantarr_0_1161[25] = "subscript<void, a, nat64>";
char constantarr_0_1162[5] = "lines";
char constantarr_0_1163[11] = "cell<nat64>";
char constantarr_0_1164[21] = "each-with-index<char>";
char constantarr_0_1165[11] = "swap<nat64>";
char constantarr_0_1166[13] = "lines.lambda0";
char constantarr_0_1167[8] = "line-len";
char constantarr_0_1168[6] = "n-tabs";
char constantarr_0_1169[8] = "tab-size";
char constantarr_0_1170[15] = "max-line-length";
char constantarr_0_1171[17] = "lint-file.lambda0";
char constantarr_0_1172[12] = "lint.lambda0";
char constantarr_0_1173[15] = "do-test.lambda1";
char constantarr_0_1174[14] = "print-failures";
char constantarr_0_1175[19] = "value<arr<failure>>";
char constantarr_0_1176[13] = "print-failure";
char constantarr_0_1177[10] = "print-bold";
char constantarr_0_1178[4] = "path";
char constantarr_0_1179[11] = "print-reset";
char constantarr_0_1180[22] = "print-failures.lambda0";
char constantarr_0_1181[12] = "test-options";
char constantarr_0_1182[11] = "static-syms";
struct str constantarr_2_0[4] = {{{11, constantarr_0_10}}, {{16, constantarr_0_11}}, {{12, constantarr_0_12}}, {{5, constantarr_0_13}}};
struct str constantarr_2_1[4] = {{{3, constantarr_0_32}}, {{5, constantarr_0_33}}, {{14, constantarr_0_34}}, {{9, constantarr_0_35}}};
struct str constantarr_2_2[11] = {{{4, constantarr_0_86}}, {{4, constantarr_0_72}}, {{5, constantarr_0_87}}, {{4, constantarr_0_88}}, {{4, constantarr_0_89}}, {{5, constantarr_0_62}}, {{4, constantarr_0_90}}, {{4, constantarr_0_91}}, {{5, constantarr_0_92}}, {{5, constantarr_0_93}}, {{3, constantarr_0_94}}};
struct str constantarr_2_3[5] = {{{13, constantarr_0_95}}, {{7, constantarr_0_96}}, {{7, constantarr_0_97}}, {{12, constantarr_0_98}}, {{17, constantarr_0_99}}};
struct str constantarr_2_4[6] = {{{1, constantarr_0_51}}, {{4, constantarr_0_100}}, {{1, constantarr_0_101}}, {{3, constantarr_0_102}}, {{4, constantarr_0_103}}, {{10, constantarr_0_104}}};
struct named_val constantarr_5_0[1201] = {{{"mark"}, ((uint8_t*)mark)}, {{"hard-assert"}, ((uint8_t*)hard_assert)}, {{"is-word-aligned"}, ((uint8_t*)is_word_aligned_0)}, {{"is-word-aligned"}, ((uint8_t*)is_word_aligned_1)}, {{"words-of-bytes"}, ((uint8_t*)words_of_bytes)}, {{"round-up-to-multiple-of-8"}, ((uint8_t*)round_up_to_multiple_of_8)}, {{"ptr-cast"}, ((uint8_t*)ptr_cast_0)}, {{"-"}, ((uint8_t*)_minus_0)}, {{"-"}, ((uint8_t*)_minus_1)}, {{"<=>"}, ((uint8_t*)_compare_0)}, {{"cmp"}, ((uint8_t*)cmp_0)}, {{"<"}, ((uint8_t*)_less_0)}, {{"<="}, ((uint8_t*)_lessOrEqual_0)}, {{"!"}, ((uint8_t*)_not)}, {{"mark-range-recur"}, ((uint8_t*)mark_range_recur)}, {{">"}, ((uint8_t*)_greater)}, {{"rt-main"}, ((uint8_t*)rt_main)}, {{"lbv"}, ((uint8_t*)lbv)}, {{"lock-by-val"}, ((uint8_t*)lock_by_val)}, {{"atomic-bool"}, ((uint8_t*)_atomic_bool)}, {{"create-condition"}, ((uint8_t*)create_condition)}, {{"hard-assert-posix-error"}, ((uint8_t*)hard_assert_posix_error)}, {{"CLOCK_MONOTONIC"}, ((uint8_t*)CLOCK_MONOTONIC)}, {{"island"}, ((uint8_t*)island)}, {{"task-queue"}, ((uint8_t*)task_queue)}, {{"mut-arr-by-val-with-capacity-from-unmanaged-memory"}, ((uint8_t*)mut_arr_by_val_with_capacity_from_unmanaged_memory)}, {{"fix-arr"}, ((uint8_t*)fix_arr_0)}, {{"unmanaged-alloc-zeroed-elements"}, ((uint8_t*)unmanaged_alloc_zeroed_elements)}, {{"unmanaged-alloc-elements"}, ((uint8_t*)unmanaged_alloc_elements_0)}, {{"unmanaged-alloc-bytes"}, ((uint8_t*)unmanaged_alloc_bytes)}, {{"!="}, ((uint8_t*)_notEqual_0)}, {{"set-zero-range"}, ((uint8_t*)set_zero_range_0)}, {{"drop"}, ((uint8_t*)drop_0)}, {{"default-exception-handler"}, ((uint8_t*)default_exception_handler)}, {{"print-err-no-newline"}, ((uint8_t*)print_err_no_newline)}, {{"write-no-newline"}, ((uint8_t*)write_no_newline)}, {{"as-any-const-ptr"}, ((uint8_t*)as_any_const_ptr_0)}, {{"size-bytes"}, ((uint8_t*)size_bytes)}, {{"!="}, ((uint8_t*)_notEqual_1)}, {{"todo"}, ((uint8_t*)todo_0)}, {{"stderr"}, ((uint8_t*)stderr)}, {{"print-err"}, ((uint8_t*)print_err)}, {{"to-str"}, ((uint8_t*)to_str_0)}, {{"writer"}, ((uint8_t*)writer)}, {{"mut-arr"}, ((uint8_t*)mut_arr_0)}, {{"fix-arr"}, ((uint8_t*)fix_arr_1)}, {{"~="}, ((uint8_t*)_concatEquals_0)}, {{"~="}, ((uint8_t*)_concatEquals_1)}, {{"each"}, ((uint8_t*)each_0)}, {{"each-recur"}, ((uint8_t*)each_recur_0)}, {{"=="}, ((uint8_t*)_equal_0)}, {{"!="}, ((uint8_t*)_notEqual_2)}, {{"subscript"}, ((uint8_t*)subscript_0)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_63)}, {{"*"}, ((uint8_t*)_times_0)}, {{"+"}, ((uint8_t*)_plus_0)}, {{"end-ptr"}, ((uint8_t*)end_ptr_0)}, {{"~="}, ((uint8_t*)_concatEquals_2)}, {{"incr-capacity!"}, ((uint8_t*)incr_capacity__e_0)}, {{"ensure-capacity"}, ((uint8_t*)ensure_capacity_0)}, {{"capacity"}, ((uint8_t*)capacity_0)}, {{"size"}, ((uint8_t*)size_0)}, {{"increase-capacity-to!"}, ((uint8_t*)increase_capacity_to__e_0)}, {{"assert"}, ((uint8_t*)assert_0)}, {{"throw"}, ((uint8_t*)throw_0)}, {{"throw"}, ((uint8_t*)throw_1)}, {{"get-exception-ctx"}, ((uint8_t*)get_exception_ctx)}, {{"!="}, ((uint8_t*)_notEqual_3)}, {{"number-to-throw"}, ((uint8_t*)number_to_throw)}, {{"hard-unreachable"}, ((uint8_t*)hard_unreachable_0)}, {{"get-backtrace"}, ((uint8_t*)get_backtrace)}, {{"try-alloc-backtrace-arrs"}, ((uint8_t*)try_alloc_backtrace_arrs)}, {{"try-alloc-uninitialized"}, ((uint8_t*)try_alloc_uninitialized_0)}, {{"try-alloc"}, ((uint8_t*)try_alloc)}, {{"try-gc-alloc"}, ((uint8_t*)try_gc_alloc)}, {{"acquire!"}, ((uint8_t*)acquire__e)}, {{"acquire-recur!"}, ((uint8_t*)acquire_recur__e)}, {{"try-acquire!"}, ((uint8_t*)try_acquire__e)}, {{"try-set!"}, ((uint8_t*)try_set__e)}, {{"try-change!"}, ((uint8_t*)try_change__e)}, {{"yield-thread"}, ((uint8_t*)yield_thread)}, {{"try-gc-alloc-recur"}, ((uint8_t*)try_gc_alloc_recur)}, {{"<=>"}, ((uint8_t*)_compare_1)}, {{"<"}, ((uint8_t*)_less_1)}, {{"range-free"}, ((uint8_t*)range_free)}, {{"maybe-set-needs-gc!"}, ((uint8_t*)maybe_set_needs_gc__e)}, {{"-"}, ((uint8_t*)_minus_2)}, {{"release!"}, ((uint8_t*)release__e)}, {{"must-unset!"}, ((uint8_t*)must_unset__e)}, {{"try-unset!"}, ((uint8_t*)try_unset__e)}, {{"get-gc"}, ((uint8_t*)get_gc)}, {{"get-gc-ctx"}, ((uint8_t*)get_gc_ctx_0)}, {{"try-alloc-uninitialized"}, ((uint8_t*)try_alloc_uninitialized_1)}, {{"try-alloc-uninitialized"}, ((uint8_t*)try_alloc_uninitialized_2)}, {{"code-ptrs-size"}, ((uint8_t*)code_ptrs_size)}, {{"copy-data-from!"}, ((uint8_t*)copy_data_from__e_0)}, {{"as-any-const-ptr"}, ((uint8_t*)as_any_const_ptr_1)}, {{"sort!"}, ((uint8_t*)sort__e_0)}, {{"swap!"}, ((uint8_t*)swap__e_0)}, {{"subscript"}, ((uint8_t*)subscript_1)}, {{"set-subscript"}, ((uint8_t*)set_subscript_0)}, {{"partition!"}, ((uint8_t*)partition__e)}, {{"=="}, ((uint8_t*)_equal_1)}, {{"<=>"}, ((uint8_t*)_compare_2)}, {{"<=>"}, ((uint8_t*)_compare_3)}, {{"<"}, ((uint8_t*)_less_2)}, {{"fill-code-names!"}, ((uint8_t*)fill_code_names__e)}, {{"<=>"}, ((uint8_t*)_compare_4)}, {{"<"}, ((uint8_t*)_less_3)}, {{"get-fun-name"}, ((uint8_t*)get_fun_name)}, {{"subscript"}, ((uint8_t*)subscript_2)}, {{"*"}, ((uint8_t*)_times_1)}, {{"+"}, ((uint8_t*)_plus_1)}, {{"*"}, ((uint8_t*)_times_2)}, {{"+"}, ((uint8_t*)_plus_2)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_0)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_1)}, {{"uninitialized-fix-arr"}, ((uint8_t*)uninitialized_fix_arr_0)}, {{"fix-arr"}, ((uint8_t*)fix_arr_2)}, {{"alloc-uninitialized"}, ((uint8_t*)alloc_uninitialized_0)}, {{"alloc"}, ((uint8_t*)alloc)}, {{"gc-alloc"}, ((uint8_t*)gc_alloc)}, {{"todo"}, ((uint8_t*)todo_1)}, {{"copy-data-from!"}, ((uint8_t*)copy_data_from__e_1)}, {{"set-zero-elements"}, ((uint8_t*)set_zero_elements_0)}, {{"set-zero-range"}, ((uint8_t*)set_zero_range_1)}, {{"subscript"}, ((uint8_t*)subscript_3)}, {{"subscript"}, ((uint8_t*)subscript_4)}, {{".."}, ((uint8_t*)_range)}, {{"+"}, ((uint8_t*)_plus_3)}, {{">="}, ((uint8_t*)_greaterOrEqual)}, {{"round-up-to-power-of-two"}, ((uint8_t*)round_up_to_power_of_two)}, {{"round-up-to-power-of-two-recur"}, ((uint8_t*)round_up_to_power_of_two_recur)}, {{"*"}, ((uint8_t*)_times_3)}, {{"/"}, ((uint8_t*)_divide)}, {{"forbid"}, ((uint8_t*)forbid)}, {{"set-subscript"}, ((uint8_t*)set_subscript_1)}, {{"is-empty"}, ((uint8_t*)is_empty_0)}, {{"is-empty"}, ((uint8_t*)is_empty_1)}, {{"each"}, ((uint8_t*)each_1)}, {{"each-recur"}, ((uint8_t*)each_recur_1)}, {{"=="}, ((uint8_t*)_equal_2)}, {{"!="}, ((uint8_t*)_notEqual_4)}, {{"subscript"}, ((uint8_t*)subscript_5)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_159)}, {{"*"}, ((uint8_t*)_times_4)}, {{"+"}, ((uint8_t*)_plus_4)}, {{"end-ptr"}, ((uint8_t*)end_ptr_1)}, {{"~="}, ((uint8_t*)_concatEquals_3)}, {{"to-str"}, ((uint8_t*)to_str_1)}, {{"arr-from-begin-end"}, ((uint8_t*)arr_from_begin_end)}, {{"<=>"}, ((uint8_t*)_compare_5)}, {{"<=>"}, ((uint8_t*)_compare_6)}, {{"<="}, ((uint8_t*)_lessOrEqual_1)}, {{"<"}, ((uint8_t*)_less_4)}, {{"-"}, ((uint8_t*)_minus_3)}, {{"-"}, ((uint8_t*)_minus_4)}, {{"find-cstr-end"}, ((uint8_t*)find_cstr_end)}, {{"find-char-in-cstr"}, ((uint8_t*)find_char_in_cstr)}, {{"=="}, ((uint8_t*)_equal_3)}, {{"hard-unreachable"}, ((uint8_t*)hard_unreachable_1)}, {{"move-to-str!"}, ((uint8_t*)move_to_str__e)}, {{"move-to-arr!"}, ((uint8_t*)move_to_arr__e_0)}, {{"cast-immutable"}, ((uint8_t*)cast_immutable_0)}, {{"move-to-fix-arr!"}, ((uint8_t*)move_to_fix_arr__e_0)}, {{"get-global-ctx"}, ((uint8_t*)get_global_ctx)}, {{"default-log-handler"}, ((uint8_t*)default_log_handler)}, {{"print"}, ((uint8_t*)print)}, {{"print-no-newline"}, ((uint8_t*)print_no_newline)}, {{"stdout"}, ((uint8_t*)stdout)}, {{"~"}, ((uint8_t*)_tilde_0)}, {{"~"}, ((uint8_t*)_tilde_1)}, {{"to-str"}, ((uint8_t*)to_str_2)}, {{"gc"}, ((uint8_t*)gc)}, {{"validate-gc"}, ((uint8_t*)validate_gc)}, {{"<=>"}, ((uint8_t*)_compare_7)}, {{"<="}, ((uint8_t*)_lessOrEqual_2)}, {{"<"}, ((uint8_t*)_less_5)}, {{"<="}, ((uint8_t*)_lessOrEqual_3)}, {{"thread-safe-counter"}, ((uint8_t*)thread_safe_counter_0)}, {{"thread-safe-counter"}, ((uint8_t*)thread_safe_counter_1)}, {{"add-main-task"}, ((uint8_t*)add_main_task)}, {{"exception-ctx"}, ((uint8_t*)exception_ctx)}, {{"log-ctx"}, ((uint8_t*)log_ctx)}, {{"perf-ctx"}, ((uint8_t*)perf_ctx)}, {{"fix-arr"}, ((uint8_t*)fix_arr_3)}, {{"ctx"}, ((uint8_t*)ctx)}, {{"get-gc-ctx"}, ((uint8_t*)get_gc_ctx_1)}, {{"add-first-task"}, ((uint8_t*)add_first_task)}, {{"then-void"}, ((uint8_t*)then_void)}, {{"then"}, ((uint8_t*)then)}, {{"unresolved"}, ((uint8_t*)unresolved)}, {{"callback!"}, ((uint8_t*)callback__e_0)}, {{"with-lock"}, ((uint8_t*)with_lock_0)}, {{"subscript"}, ((uint8_t*)subscript_6)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_213)}, {{"subscript"}, ((uint8_t*)subscript_7)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_215)}, {{"forward-to!"}, ((uint8_t*)forward_to__e)}, {{"callback!"}, ((uint8_t*)callback__e_1)}, {{"subscript"}, ((uint8_t*)subscript_8)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_220)}, {{"resolve-or-reject!"}, ((uint8_t*)resolve_or_reject__e)}, {{"with-lock"}, ((uint8_t*)with_lock_1)}, {{"subscript"}, ((uint8_t*)subscript_9)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_225)}, {{"call-callbacks!"}, ((uint8_t*)call_callbacks__e)}, {{"subscript"}, ((uint8_t*)subscript_10)}, {{"get-island"}, ((uint8_t*)get_island)}, {{"subscript"}, ((uint8_t*)subscript_11)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_0)}, {{"subscript"}, ((uint8_t*)subscript_12)}, {{"*"}, ((uint8_t*)_times_5)}, {{"+"}, ((uint8_t*)_plus_5)}, {{"add-task"}, ((uint8_t*)add_task_0)}, {{"add-task"}, ((uint8_t*)add_task_1)}, {{"task-queue-node"}, ((uint8_t*)task_queue_node)}, {{"insert-task!"}, ((uint8_t*)insert_task__e)}, {{"size"}, ((uint8_t*)size_1)}, {{"size-recur"}, ((uint8_t*)size_recur)}, {{"insert-recur"}, ((uint8_t*)insert_recur)}, {{"tasks"}, ((uint8_t*)tasks)}, {{"broadcast!"}, ((uint8_t*)broadcast__e)}, {{"no-timestamp"}, ((uint8_t*)no_timestamp)}, {{"catch"}, ((uint8_t*)catch)}, {{"catch-with-exception-ctx"}, ((uint8_t*)catch_with_exception_ctx)}, {{"zero"}, ((uint8_t*)zero_0)}, {{"zero"}, ((uint8_t*)zero_1)}, {{"zero"}, ((uint8_t*)zero_2)}, {{"zero"}, ((uint8_t*)zero_3)}, {{"subscript"}, ((uint8_t*)subscript_13)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_257)}, {{"subscript"}, ((uint8_t*)subscript_14)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_259)}, {{"reject!"}, ((uint8_t*)reject__e)}, {{"subscript"}, ((uint8_t*)subscript_15)}, {{"subscript"}, ((uint8_t*)subscript_16)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_267)}, {{"cur-island-and-exclusion"}, ((uint8_t*)cur_island_and_exclusion)}, {{"delay"}, ((uint8_t*)delay)}, {{"resolved"}, ((uint8_t*)resolved_0)}, {{"tail"}, ((uint8_t*)tail_0)}, {{"is-empty"}, ((uint8_t*)is_empty_2)}, {{"subscript"}, ((uint8_t*)subscript_17)}, {{"+"}, ((uint8_t*)_plus_6)}, {{"map"}, ((uint8_t*)map_0)}, {{"make-arr"}, ((uint8_t*)make_arr_0)}, {{"alloc-uninitialized"}, ((uint8_t*)alloc_uninitialized_1)}, {{"fill-ptr-range"}, ((uint8_t*)fill_ptr_range_0)}, {{"fill-ptr-range-recur"}, ((uint8_t*)fill_ptr_range_recur_0)}, {{"!="}, ((uint8_t*)_notEqual_5)}, {{"set-subscript"}, ((uint8_t*)set_subscript_2)}, {{"subscript"}, ((uint8_t*)subscript_18)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_287)}, {{"subscript"}, ((uint8_t*)subscript_19)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_289)}, {{"subscript"}, ((uint8_t*)subscript_20)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_1)}, {{"subscript"}, ((uint8_t*)subscript_21)}, {{"*"}, ((uint8_t*)_times_6)}, {{"handle-exceptions"}, ((uint8_t*)handle_exceptions)}, {{"subscript"}, ((uint8_t*)subscript_22)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_299)}, {{"exception-handler"}, ((uint8_t*)exception_handler)}, {{"get-cur-island"}, ((uint8_t*)get_cur_island)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_304)}, {{"run-threads"}, ((uint8_t*)run_threads)}, {{"unmanaged-alloc-elements"}, ((uint8_t*)unmanaged_alloc_elements_1)}, {{"start-threads-recur"}, ((uint8_t*)start_threads_recur)}, {{"create-one-thread"}, ((uint8_t*)create_one_thread)}, {{"null"}, ((uint8_t*)null_0)}, {{"!="}, ((uint8_t*)_notEqual_6)}, {{"EAGAIN"}, ((uint8_t*)EAGAIN)}, {{"as-cell"}, ((uint8_t*)as_cell)}, {{"thread-fun"}, ((uint8_t*)thread_fun)}, {{"thread-function"}, ((uint8_t*)thread_function)}, {{"thread-function-recur"}, ((uint8_t*)thread_function_recur)}, {{"assert-islands-are-shut-down"}, ((uint8_t*)assert_islands_are_shut_down)}, {{"noctx-at"}, ((uint8_t*)noctx_at_0)}, {{"hard-forbid"}, ((uint8_t*)hard_forbid)}, {{"is-empty"}, ((uint8_t*)is_empty_3)}, {{"is-empty"}, ((uint8_t*)is_empty_4)}, {{"get-sequence"}, ((uint8_t*)get_sequence)}, {{"choose-task"}, ((uint8_t*)choose_task)}, {{"get-monotime-nsec"}, ((uint8_t*)get_monotime_nsec)}, {{"*"}, ((uint8_t*)_times_7)}, {{"todo"}, ((uint8_t*)todo_2)}, {{"choose-task-recur"}, ((uint8_t*)choose_task_recur)}, {{"choose-task-in-island"}, ((uint8_t*)choose_task_in_island)}, {{"pop-task!"}, ((uint8_t*)pop_task__e)}, {{"in"}, ((uint8_t*)in_0)}, {{"in"}, ((uint8_t*)in_1)}, {{"in-recur"}, ((uint8_t*)in_recur_0)}, {{"noctx-at"}, ((uint8_t*)noctx_at_1)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_2)}, {{"subscript"}, ((uint8_t*)subscript_23)}, {{"*"}, ((uint8_t*)_times_8)}, {{"+"}, ((uint8_t*)_plus_7)}, {{"temp-as-arr"}, ((uint8_t*)temp_as_arr_0)}, {{"temp-as-arr"}, ((uint8_t*)temp_as_arr_1)}, {{"temp-as-fix-arr"}, ((uint8_t*)temp_as_fix_arr_0)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_2)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_3)}, {{"pop-recur!"}, ((uint8_t*)pop_recur__e)}, {{"to-opt-time"}, ((uint8_t*)to_opt_time)}, {{"push-capacity-must-be-sufficient!"}, ((uint8_t*)push_capacity_must_be_sufficient__e)}, {{"capacity"}, ((uint8_t*)capacity_1)}, {{"size"}, ((uint8_t*)size_2)}, {{"set-subscript"}, ((uint8_t*)set_subscript_3)}, {{"is-no-task"}, ((uint8_t*)is_no_task)}, {{"min-time"}, ((uint8_t*)min_time)}, {{"min"}, ((uint8_t*)min)}, {{"do-task"}, ((uint8_t*)do_task)}, {{"return-task!"}, ((uint8_t*)return_task__e)}, {{"noctx-must-remove-unordered!"}, ((uint8_t*)noctx_must_remove_unordered__e)}, {{"noctx-must-remove-unordered-recur!"}, ((uint8_t*)noctx_must_remove_unordered_recur__e)}, {{"subscript"}, ((uint8_t*)subscript_24)}, {{"drop"}, ((uint8_t*)drop_1)}, {{"noctx-remove-unordered-at!"}, ((uint8_t*)noctx_remove_unordered_at__e_0)}, {{"return-ctx"}, ((uint8_t*)return_ctx)}, {{"return-gc-ctx"}, ((uint8_t*)return_gc_ctx)}, {{"run-garbage-collection"}, ((uint8_t*)run_garbage_collection)}, {{"mark-visit"}, ((uint8_t*)mark_visit_363)}, {{"clear-free-mem!"}, ((uint8_t*)clear_free_mem__e)}, {{"!="}, ((uint8_t*)_notEqual_7)}, {{"wait-on"}, ((uint8_t*)wait_on)}, {{"to-timespec"}, ((uint8_t*)to_timespec)}, {{"ETIMEDOUT"}, ((uint8_t*)ETIMEDOUT)}, {{"join-threads-recur"}, ((uint8_t*)join_threads_recur)}, {{"join-one-thread"}, ((uint8_t*)join_one_thread)}, {{"EINVAL"}, ((uint8_t*)EINVAL)}, {{"ESRCH"}, ((uint8_t*)ESRCH)}, {{"*"}, ((uint8_t*)_times_9)}, {{"unmanaged-free"}, ((uint8_t*)unmanaged_free_0)}, {{"unmanaged-free"}, ((uint8_t*)unmanaged_free_1)}, {{"destroy-condition"}, ((uint8_t*)destroy_condition)}, {{"main"}, ((uint8_t*)main_0)}, {{"resolved"}, ((uint8_t*)resolved_1)}, {{"parse-named-args"}, ((uint8_t*)parse_named_args_0)}, {{"parse-command-dynamic"}, ((uint8_t*)parse_command_dynamic)}, {{"find-index"}, ((uint8_t*)find_index_0)}, {{"find-index-recur"}, ((uint8_t*)find_index_recur_0)}, {{"subscript"}, ((uint8_t*)subscript_25)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_448)}, {{"subscript"}, ((uint8_t*)subscript_26)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_3)}, {{"subscript"}, ((uint8_t*)subscript_27)}, {{"*"}, ((uint8_t*)_times_10)}, {{"+"}, ((uint8_t*)_plus_8)}, {{"starts-with"}, ((uint8_t*)starts_with_0)}, {{"=="}, ((uint8_t*)_equal_4)}, {{"arr-equal"}, ((uint8_t*)arr_equal)}, {{"equal-recur"}, ((uint8_t*)equal_recur)}, {{"starts-with"}, ((uint8_t*)starts_with_1)}, {{"=="}, ((uint8_t*)_equal_5)}, {{"<=>"}, ((uint8_t*)_compare_8)}, {{"<=>"}, ((uint8_t*)_compare_9)}, {{"<=>"}, ((uint8_t*)_compare_10)}, {{"cmp"}, ((uint8_t*)cmp_1)}, {{"arr-compare"}, ((uint8_t*)arr_compare)}, {{"compare-recur"}, ((uint8_t*)compare_recur)}, {{"hash-mix"}, ((uint8_t*)hash_mix_0)}, {{"hash-mix"}, ((uint8_t*)hash_mix_1)}, {{"dict"}, ((uint8_t*)dict_0)}, {{"no-duplicate-keys"}, ((uint8_t*)no_duplicate_keys_0)}, {{"subscript"}, ((uint8_t*)subscript_28)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_4)}, {{"subscript"}, ((uint8_t*)subscript_29)}, {{"*"}, ((uint8_t*)_times_11)}, {{"+"}, ((uint8_t*)_plus_9)}, {{"every"}, ((uint8_t*)every_0)}, {{"is-empty"}, ((uint8_t*)is_empty_5)}, {{"subscript"}, ((uint8_t*)subscript_30)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_480)}, {{"tail"}, ((uint8_t*)tail_1)}, {{"subscript"}, ((uint8_t*)subscript_31)}, {{"!="}, ((uint8_t*)_notEqual_8)}, {{"fold"}, ((uint8_t*)fold_0)}, {{"fold-recur"}, ((uint8_t*)fold_recur_0)}, {{"=="}, ((uint8_t*)_equal_6)}, {{"subscript"}, ((uint8_t*)subscript_32)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_489)}, {{"end-ptr"}, ((uint8_t*)end_ptr_2)}, {{"dict"}, ((uint8_t*)dict_1)}, {{"empty-leaf-node"}, ((uint8_t*)empty_leaf_node_0)}, {{"~"}, ((uint8_t*)_tilde_2)}, {{"get-or-update"}, ((uint8_t*)get_or_update_0)}, {{"hash"}, ((uint8_t*)hash)}, {{"get-or-update-recur"}, ((uint8_t*)get_or_update_recur_0)}, {{"low-bits"}, ((uint8_t*)low_bits)}, {{"subscript"}, ((uint8_t*)subscript_33)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_5)}, {{"subscript"}, ((uint8_t*)subscript_34)}, {{"*"}, ((uint8_t*)_times_12)}, {{"+"}, ((uint8_t*)_plus_10)}, {{"update-child"}, ((uint8_t*)update_child_0)}, {{"inner-node-to-leaf"}, ((uint8_t*)inner_node_to_leaf_0)}, {{"fold-with-index"}, ((uint8_t*)fold_with_index_0)}, {{"fold-with-index-recur"}, ((uint8_t*)fold_with_index_recur_0)}, {{"=="}, ((uint8_t*)_equal_7)}, {{"subscript"}, ((uint8_t*)subscript_35)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_509)}, {{"end-ptr"}, ((uint8_t*)end_ptr_3)}, {{"leaf-max-size"}, ((uint8_t*)leaf_max_size)}, {{"uninitialized-fix-arr"}, ((uint8_t*)uninitialized_fix_arr_1)}, {{"fix-arr"}, ((uint8_t*)fix_arr_4)}, {{"alloc-uninitialized"}, ((uint8_t*)alloc_uninitialized_2)}, {{"unreachable"}, ((uint8_t*)unreachable_0)}, {{"throw"}, ((uint8_t*)throw_2)}, {{"throw"}, ((uint8_t*)throw_3)}, {{"hard-unreachable"}, ((uint8_t*)hard_unreachable_2)}, {{"copy-from!"}, ((uint8_t*)copy_from__e_0)}, {{"size"}, ((uint8_t*)size_3)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_4)}, {{"as-any-const-ptr"}, ((uint8_t*)as_any_const_ptr_2)}, {{"subscript"}, ((uint8_t*)subscript_36)}, {{"cast-immutable"}, ((uint8_t*)cast_immutable_1)}, {{"node-is-empty"}, ((uint8_t*)node_is_empty_0)}, {{"rtail"}, ((uint8_t*)rtail_0)}, {{"is-empty"}, ((uint8_t*)is_empty_6)}, {{"subscript"}, ((uint8_t*)subscript_37)}, {{"-"}, ((uint8_t*)_minus_5)}, {{"update"}, ((uint8_t*)update_0)}, {{"~"}, ((uint8_t*)_tilde_3)}, {{"alloc-uninitialized"}, ((uint8_t*)alloc_uninitialized_3)}, {{"copy-data-from!"}, ((uint8_t*)copy_data_from__e_2)}, {{"as-any-const-ptr"}, ((uint8_t*)as_any_const_ptr_3)}, {{"find-only-non-empty-child"}, ((uint8_t*)find_only_non_empty_child_0)}, {{"force"}, ((uint8_t*)force_0)}, {{"force"}, ((uint8_t*)force_1)}, {{"find-index"}, ((uint8_t*)find_index_1)}, {{"find-index-recur"}, ((uint8_t*)find_index_recur_1)}, {{"subscript"}, ((uint8_t*)subscript_38)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_543)}, {{"every"}, ((uint8_t*)every_1)}, {{"tail"}, ((uint8_t*)tail_2)}, {{"subscript"}, ((uint8_t*)subscript_39)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_549)}, {{"->"}, ((uint8_t*)_arrow_0)}, {{"update-with-default"}, ((uint8_t*)update_with_default_0)}, {{"make-arr"}, ((uint8_t*)make_arr_1)}, {{"fill-ptr-range"}, ((uint8_t*)fill_ptr_range_1)}, {{"fill-ptr-range-recur"}, ((uint8_t*)fill_ptr_range_recur_1)}, {{"set-subscript"}, ((uint8_t*)set_subscript_4)}, {{"subscript"}, ((uint8_t*)subscript_40)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_557)}, {{"get-or-update-leaf"}, ((uint8_t*)get_or_update_leaf_0)}, {{"find-index"}, ((uint8_t*)find_index_2)}, {{"find-index-recur"}, ((uint8_t*)find_index_recur_2)}, {{"new-inner-node"}, ((uint8_t*)new_inner_node_0)}, {{"fold"}, ((uint8_t*)fold_1)}, {{"fold-recur"}, ((uint8_t*)fold_recur_1)}, {{"subscript"}, ((uint8_t*)subscript_41)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_567)}, {{"max"}, ((uint8_t*)max)}, {{"fill-fix-arr"}, ((uint8_t*)fill_fix_arr_0)}, {{"make-fix-arr"}, ((uint8_t*)make_fix_arr_0)}, {{"uninitialized-fix-arr"}, ((uint8_t*)uninitialized_fix_arr_2)}, {{"fix-arr"}, ((uint8_t*)fix_arr_5)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_5)}, {{"set-subscript"}, ((uint8_t*)set_subscript_5)}, {{"size"}, ((uint8_t*)size_4)}, {{"unsafe-set-at!"}, ((uint8_t*)unsafe_set_at__e_0)}, {{"each"}, ((uint8_t*)each_2)}, {{"each-recur"}, ((uint8_t*)each_recur_2)}, {{"!="}, ((uint8_t*)_notEqual_9)}, {{"subscript"}, ((uint8_t*)subscript_42)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_583)}, {{"subscript"}, ((uint8_t*)subscript_43)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_6)}, {{"subscript"}, ((uint8_t*)subscript_44)}, {{"unreachable"}, ((uint8_t*)unreachable_1)}, {{"throw"}, ((uint8_t*)throw_4)}, {{"throw"}, ((uint8_t*)throw_5)}, {{"hard-unreachable"}, ((uint8_t*)hard_unreachable_3)}, {{"~"}, ((uint8_t*)_tilde_4)}, {{"copy-data-from!"}, ((uint8_t*)copy_data_from__e_3)}, {{"cast-immutable"}, ((uint8_t*)cast_immutable_2)}, {{"remove-at"}, ((uint8_t*)remove_at_0)}, {{"update"}, ((uint8_t*)update_1)}, {{"subscript"}, ((uint8_t*)subscript_45)}, {{"parse-named-args"}, ((uint8_t*)parse_named_args_1)}, {{"mut-dict"}, ((uint8_t*)mut_dict_0)}, {{"fix-arr"}, ((uint8_t*)fix_arr_6)}, {{"parse-named-args-recur"}, ((uint8_t*)parse_named_args_recur)}, {{"force"}, ((uint8_t*)force_2)}, {{"force"}, ((uint8_t*)force_3)}, {{"throw"}, ((uint8_t*)throw_6)}, {{"throw"}, ((uint8_t*)throw_7)}, {{"hard-unreachable"}, ((uint8_t*)hard_unreachable_4)}, {{"try-remove-start"}, ((uint8_t*)try_remove_start_0)}, {{"try-remove-start"}, ((uint8_t*)try_remove_start_1)}, {{"tail"}, ((uint8_t*)tail_3)}, {{"is-empty"}, ((uint8_t*)is_empty_7)}, {{"set-subscript"}, ((uint8_t*)set_subscript_6)}, {{"drop"}, ((uint8_t*)drop_2)}, {{"update!"}, ((uint8_t*)update__e_0)}, {{"is-empty"}, ((uint8_t*)is_empty_8)}, {{"size"}, ((uint8_t*)size_5)}, {{"fix-arr"}, ((uint8_t*)fix_arr_7)}, {{"make-fix-arr"}, ((uint8_t*)make_fix_arr_1)}, {{"uninitialized-fix-arr"}, ((uint8_t*)uninitialized_fix_arr_3)}, {{"fix-arr"}, ((uint8_t*)fix_arr_8)}, {{"alloc-uninitialized"}, ((uint8_t*)alloc_uninitialized_4)}, {{"fill-ptr-range"}, ((uint8_t*)fill_ptr_range_2)}, {{"fill-ptr-range-recur"}, ((uint8_t*)fill_ptr_range_recur_2)}, {{"set-subscript"}, ((uint8_t*)set_subscript_7)}, {{"subscript"}, ((uint8_t*)subscript_46)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_629)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_6)}, {{"subscript"}, ((uint8_t*)subscript_47)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_7)}, {{"subscript"}, ((uint8_t*)subscript_48)}, {{"*"}, ((uint8_t*)_times_13)}, {{"+"}, ((uint8_t*)_plus_11)}, {{"subscript"}, ((uint8_t*)subscript_49)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_8)}, {{"subscript"}, ((uint8_t*)subscript_50)}, {{"set-subscript"}, ((uint8_t*)set_subscript_8)}, {{"unsafe-set-at!"}, ((uint8_t*)unsafe_set_at__e_1)}, {{"should-expand"}, ((uint8_t*)should_expand_0)}, {{"expand!"}, ((uint8_t*)expand__e_0)}, {{"mut-dict-with-capacity"}, ((uint8_t*)mut_dict_with_capacity_0)}, {{"fill-fix-arr"}, ((uint8_t*)fill_fix_arr_1)}, {{"each"}, ((uint8_t*)each_3)}, {{"fold"}, ((uint8_t*)fold_2)}, {{"fold"}, ((uint8_t*)fold_3)}, {{"fold"}, ((uint8_t*)fold_4)}, {{"fold-recur"}, ((uint8_t*)fold_recur_2)}, {{"=="}, ((uint8_t*)_equal_8)}, {{"subscript"}, ((uint8_t*)subscript_51)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_654)}, {{"end-ptr"}, ((uint8_t*)end_ptr_4)}, {{"temp-as-arr"}, ((uint8_t*)temp_as_arr_2)}, {{"subscript"}, ((uint8_t*)subscript_52)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_658)}, {{"fold"}, ((uint8_t*)fold_5)}, {{"fold"}, ((uint8_t*)fold_6)}, {{"fold-recur"}, ((uint8_t*)fold_recur_3)}, {{"subscript"}, ((uint8_t*)subscript_53)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_663)}, {{"temp-as-arr"}, ((uint8_t*)temp_as_arr_3)}, {{"temp-as-arr"}, ((uint8_t*)temp_as_arr_4)}, {{"temp-as-fix-arr"}, ((uint8_t*)temp_as_fix_arr_1)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_7)}, {{"subscript"}, ((uint8_t*)subscript_54)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_671)}, {{"swap!"}, ((uint8_t*)swap__e_1)}, {{"mut-arr"}, ((uint8_t*)mut_arr_1)}, {{"mut-arr"}, ((uint8_t*)mut_arr_2)}, {{"fix-arr"}, ((uint8_t*)fix_arr_9)}, {{"~="}, ((uint8_t*)_concatEquals_4)}, {{"~="}, ((uint8_t*)_concatEquals_5)}, {{"incr-capacity!"}, ((uint8_t*)incr_capacity__e_1)}, {{"ensure-capacity"}, ((uint8_t*)ensure_capacity_1)}, {{"capacity"}, ((uint8_t*)capacity_2)}, {{"increase-capacity-to!"}, ((uint8_t*)increase_capacity_to__e_1)}, {{"set-zero-elements"}, ((uint8_t*)set_zero_elements_1)}, {{"set-zero-range"}, ((uint8_t*)set_zero_range_2)}, {{"set-subscript"}, ((uint8_t*)set_subscript_9)}, {{"find-index"}, ((uint8_t*)find_index_3)}, {{"is-at-capacity"}, ((uint8_t*)is_at_capacity_0)}, {{"subscript"}, ((uint8_t*)subscript_55)}, {{"subscript"}, ((uint8_t*)subscript_56)}, {{"drop"}, ((uint8_t*)drop_3)}, {{"remove-unordered-at!"}, ((uint8_t*)remove_unordered_at__e_0)}, {{"noctx-remove-unordered-at!"}, ((uint8_t*)noctx_remove_unordered_at__e_1)}, {{"is-empty"}, ((uint8_t*)is_empty_9)}, {{"set-subscript"}, ((uint8_t*)set_subscript_10)}, {{"move-to-dict!"}, ((uint8_t*)move_to_dict__e_0)}, {{"map-to-arr"}, ((uint8_t*)map_to_arr_0)}, {{"size"}, ((uint8_t*)size_6)}, {{"fold"}, ((uint8_t*)fold_7)}, {{"fold"}, ((uint8_t*)fold_8)}, {{"fold"}, ((uint8_t*)fold_9)}, {{"fold-recur"}, ((uint8_t*)fold_recur_4)}, {{"subscript"}, ((uint8_t*)subscript_57)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_706)}, {{"subscript"}, ((uint8_t*)subscript_58)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_708)}, {{"fold"}, ((uint8_t*)fold_10)}, {{"fold"}, ((uint8_t*)fold_11)}, {{"fold-recur"}, ((uint8_t*)fold_recur_5)}, {{"subscript"}, ((uint8_t*)subscript_59)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_713)}, {{"subscript"}, ((uint8_t*)subscript_60)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_717)}, {{"end-ptr"}, ((uint8_t*)end_ptr_5)}, {{"empty!"}, ((uint8_t*)empty__e_0)}, {{"fill!"}, ((uint8_t*)fill__e_0)}, {{"map!"}, ((uint8_t*)map__e_0)}, {{"map-recur!"}, ((uint8_t*)map_recur__e_0)}, {{"!="}, ((uint8_t*)_notEqual_10)}, {{"subscript"}, ((uint8_t*)subscript_61)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_727)}, {{"end-ptr"}, ((uint8_t*)end_ptr_6)}, {{"assert"}, ((uint8_t*)assert_1)}, {{"fill-mut-arr"}, ((uint8_t*)fill_mut_arr)}, {{"fill-fix-arr"}, ((uint8_t*)fill_fix_arr_2)}, {{"make-fix-arr"}, ((uint8_t*)make_fix_arr_2)}, {{"uninitialized-fix-arr"}, ((uint8_t*)uninitialized_fix_arr_4)}, {{"fix-arr"}, ((uint8_t*)fix_arr_10)}, {{"alloc-uninitialized"}, ((uint8_t*)alloc_uninitialized_5)}, {{"fill-ptr-range"}, ((uint8_t*)fill_ptr_range_3)}, {{"fill-ptr-range-recur"}, ((uint8_t*)fill_ptr_range_recur_3)}, {{"set-subscript"}, ((uint8_t*)set_subscript_11)}, {{"subscript"}, ((uint8_t*)subscript_62)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_741)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_8)}, {{"each"}, ((uint8_t*)each_4)}, {{"fold"}, ((uint8_t*)fold_12)}, {{"fold-recur"}, ((uint8_t*)fold_recur_6)}, {{"fold"}, ((uint8_t*)fold_13)}, {{"fold-recur"}, ((uint8_t*)fold_recur_7)}, {{"subscript"}, ((uint8_t*)subscript_63)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_750)}, {{"index-of"}, ((uint8_t*)index_of)}, {{"ptr-of"}, ((uint8_t*)ptr_of)}, {{"ptr-of-recur"}, ((uint8_t*)ptr_of_recur)}, {{"=="}, ((uint8_t*)_equal_9)}, {{"end-ptr"}, ((uint8_t*)end_ptr_7)}, {{"-"}, ((uint8_t*)_minus_6)}, {{"-"}, ((uint8_t*)_minus_7)}, {{"set-deref"}, ((uint8_t*)set_deref_0)}, {{"finish"}, ((uint8_t*)finish)}, {{"to-str"}, ((uint8_t*)to_str_3)}, {{"with-value"}, ((uint8_t*)with_value_0)}, {{"with-str"}, ((uint8_t*)with_str)}, {{"interp"}, ((uint8_t*)interp)}, {{"is-empty"}, ((uint8_t*)is_empty_10)}, {{"subscript"}, ((uint8_t*)subscript_64)}, {{"subscript"}, ((uint8_t*)subscript_65)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_9)}, {{"set-subscript"}, ((uint8_t*)set_subscript_12)}, {{"*"}, ((uint8_t*)_times_14)}, {{"move-to-arr!"}, ((uint8_t*)move_to_arr__e_1)}, {{"cast-immutable"}, ((uint8_t*)cast_immutable_3)}, {{"move-to-fix-arr!"}, ((uint8_t*)move_to_fix_arr__e_1)}, {{"fix-arr"}, ((uint8_t*)fix_arr_11)}, {{"print-help"}, ((uint8_t*)print_help)}, {{"subscript"}, ((uint8_t*)subscript_66)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_9)}, {{"subscript"}, ((uint8_t*)subscript_67)}, {{"*"}, ((uint8_t*)_times_15)}, {{"+"}, ((uint8_t*)_plus_12)}, {{"parse-nat"}, ((uint8_t*)parse_nat)}, {{"with-reader"}, ((uint8_t*)with_reader)}, {{"reader"}, ((uint8_t*)reader)}, {{"subscript"}, ((uint8_t*)subscript_68)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_788)}, {{"is-empty"}, ((uint8_t*)is_empty_11)}, {{"is-empty"}, ((uint8_t*)is_empty_12)}, {{"take-nat!"}, ((uint8_t*)take_nat__e)}, {{"char-to-nat64"}, ((uint8_t*)char_to_nat64)}, {{"peek"}, ((uint8_t*)peek)}, {{"drop"}, ((uint8_t*)drop_4)}, {{"next!"}, ((uint8_t*)next__e)}, {{"take-nat-recur!"}, ((uint8_t*)take_nat_recur__e)}, {{"do-test"}, ((uint8_t*)do_test)}, {{"parent-path"}, ((uint8_t*)parent_path)}, {{"r-index-of"}, ((uint8_t*)r_index_of)}, {{"find-rindex"}, ((uint8_t*)find_rindex)}, {{"find-rindex-recur"}, ((uint8_t*)find_rindex_recur)}, {{"subscript"}, ((uint8_t*)subscript_69)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_804)}, {{"subscript"}, ((uint8_t*)subscript_70)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_10)}, {{"subscript"}, ((uint8_t*)subscript_71)}, {{"child-path"}, ((uint8_t*)child_path)}, {{"get-environ"}, ((uint8_t*)get_environ)}, {{"mut-dict"}, ((uint8_t*)mut_dict_1)}, {{"fix-arr"}, ((uint8_t*)fix_arr_12)}, {{"get-environ-recur"}, ((uint8_t*)get_environ_recur)}, {{"null"}, ((uint8_t*)null_1)}, {{"parse-environ-entry"}, ((uint8_t*)parse_environ_entry)}, {{"todo"}, ((uint8_t*)todo_3)}, {{"->"}, ((uint8_t*)_arrow_1)}, {{"set-subscript"}, ((uint8_t*)set_subscript_13)}, {{"drop"}, ((uint8_t*)drop_5)}, {{"update!"}, ((uint8_t*)update__e_1)}, {{"is-empty"}, ((uint8_t*)is_empty_13)}, {{"size"}, ((uint8_t*)size_7)}, {{"fix-arr"}, ((uint8_t*)fix_arr_13)}, {{"make-fix-arr"}, ((uint8_t*)make_fix_arr_3)}, {{"uninitialized-fix-arr"}, ((uint8_t*)uninitialized_fix_arr_5)}, {{"fix-arr"}, ((uint8_t*)fix_arr_14)}, {{"alloc-uninitialized"}, ((uint8_t*)alloc_uninitialized_6)}, {{"fill-ptr-range"}, ((uint8_t*)fill_ptr_range_4)}, {{"fill-ptr-range-recur"}, ((uint8_t*)fill_ptr_range_recur_4)}, {{"set-subscript"}, ((uint8_t*)set_subscript_14)}, {{"subscript"}, ((uint8_t*)subscript_72)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_832)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_10)}, {{"subscript"}, ((uint8_t*)subscript_73)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_11)}, {{"subscript"}, ((uint8_t*)subscript_74)}, {{"*"}, ((uint8_t*)_times_16)}, {{"+"}, ((uint8_t*)_plus_13)}, {{"subscript"}, ((uint8_t*)subscript_75)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_12)}, {{"subscript"}, ((uint8_t*)subscript_76)}, {{"set-subscript"}, ((uint8_t*)set_subscript_15)}, {{"unsafe-set-at!"}, ((uint8_t*)unsafe_set_at__e_2)}, {{"should-expand"}, ((uint8_t*)should_expand_1)}, {{"expand!"}, ((uint8_t*)expand__e_1)}, {{"mut-dict-with-capacity"}, ((uint8_t*)mut_dict_with_capacity_1)}, {{"fill-fix-arr"}, ((uint8_t*)fill_fix_arr_3)}, {{"each"}, ((uint8_t*)each_5)}, {{"fold"}, ((uint8_t*)fold_14)}, {{"fold"}, ((uint8_t*)fold_15)}, {{"fold"}, ((uint8_t*)fold_16)}, {{"fold-recur"}, ((uint8_t*)fold_recur_8)}, {{"=="}, ((uint8_t*)_equal_10)}, {{"subscript"}, ((uint8_t*)subscript_77)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_857)}, {{"end-ptr"}, ((uint8_t*)end_ptr_8)}, {{"temp-as-arr"}, ((uint8_t*)temp_as_arr_5)}, {{"subscript"}, ((uint8_t*)subscript_78)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_861)}, {{"fold"}, ((uint8_t*)fold_17)}, {{"fold"}, ((uint8_t*)fold_18)}, {{"fold-recur"}, ((uint8_t*)fold_recur_9)}, {{"=="}, ((uint8_t*)_equal_11)}, {{"subscript"}, ((uint8_t*)subscript_79)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_867)}, {{"*"}, ((uint8_t*)_times_17)}, {{"+"}, ((uint8_t*)_plus_14)}, {{"end-ptr"}, ((uint8_t*)end_ptr_9)}, {{"temp-as-arr"}, ((uint8_t*)temp_as_arr_6)}, {{"temp-as-arr"}, ((uint8_t*)temp_as_arr_7)}, {{"temp-as-fix-arr"}, ((uint8_t*)temp_as_fix_arr_2)}, {{"fix-arr"}, ((uint8_t*)fix_arr_15)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_11)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_12)}, {{"subscript"}, ((uint8_t*)subscript_80)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_880)}, {{"swap!"}, ((uint8_t*)swap__e_2)}, {{"mut-arr"}, ((uint8_t*)mut_arr_3)}, {{"mut-arr"}, ((uint8_t*)mut_arr_4)}, {{"fix-arr"}, ((uint8_t*)fix_arr_16)}, {{"~="}, ((uint8_t*)_concatEquals_6)}, {{"each"}, ((uint8_t*)each_6)}, {{"each-recur"}, ((uint8_t*)each_recur_3)}, {{"!="}, ((uint8_t*)_notEqual_11)}, {{"subscript"}, ((uint8_t*)subscript_81)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_892)}, {{"~="}, ((uint8_t*)_concatEquals_7)}, {{"incr-capacity!"}, ((uint8_t*)incr_capacity__e_2)}, {{"ensure-capacity"}, ((uint8_t*)ensure_capacity_2)}, {{"capacity"}, ((uint8_t*)capacity_3)}, {{"size"}, ((uint8_t*)size_8)}, {{"increase-capacity-to!"}, ((uint8_t*)increase_capacity_to__e_2)}, {{"uninitialized-fix-arr"}, ((uint8_t*)uninitialized_fix_arr_6)}, {{"alloc-uninitialized"}, ((uint8_t*)alloc_uninitialized_7)}, {{"copy-data-from!"}, ((uint8_t*)copy_data_from__e_4)}, {{"as-any-const-ptr"}, ((uint8_t*)as_any_const_ptr_4)}, {{"set-zero-elements"}, ((uint8_t*)set_zero_elements_2)}, {{"set-zero-range"}, ((uint8_t*)set_zero_range_3)}, {{"subscript"}, ((uint8_t*)subscript_82)}, {{"subscript"}, ((uint8_t*)subscript_83)}, {{"set-subscript"}, ((uint8_t*)set_subscript_16)}, {{"find-index"}, ((uint8_t*)find_index_4)}, {{"find-index"}, ((uint8_t*)find_index_5)}, {{"find-index-recur"}, ((uint8_t*)find_index_recur_3)}, {{"subscript"}, ((uint8_t*)subscript_84)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_913)}, {{"subscript"}, ((uint8_t*)subscript_85)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_13)}, {{"subscript"}, ((uint8_t*)subscript_86)}, {{"is-at-capacity"}, ((uint8_t*)is_at_capacity_1)}, {{"subscript"}, ((uint8_t*)subscript_87)}, {{"subscript"}, ((uint8_t*)subscript_88)}, {{"drop"}, ((uint8_t*)drop_6)}, {{"remove-unordered-at!"}, ((uint8_t*)remove_unordered_at__e_1)}, {{"noctx-remove-unordered-at!"}, ((uint8_t*)noctx_remove_unordered_at__e_2)}, {{"is-empty"}, ((uint8_t*)is_empty_14)}, {{"set-subscript"}, ((uint8_t*)set_subscript_17)}, {{"move-to-dict!"}, ((uint8_t*)move_to_dict__e_1)}, {{"dict"}, ((uint8_t*)dict_2)}, {{"no-duplicate-keys"}, ((uint8_t*)no_duplicate_keys_1)}, {{"every"}, ((uint8_t*)every_2)}, {{"is-empty"}, ((uint8_t*)is_empty_15)}, {{"tail"}, ((uint8_t*)tail_4)}, {{"fold"}, ((uint8_t*)fold_19)}, {{"fold-recur"}, ((uint8_t*)fold_recur_10)}, {{"subscript"}, ((uint8_t*)subscript_89)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_937)}, {{"dict"}, ((uint8_t*)dict_3)}, {{"empty-leaf-node"}, ((uint8_t*)empty_leaf_node_1)}, {{"~"}, ((uint8_t*)_tilde_5)}, {{"get-or-update"}, ((uint8_t*)get_or_update_1)}, {{"get-or-update-recur"}, ((uint8_t*)get_or_update_recur_1)}, {{"subscript"}, ((uint8_t*)subscript_90)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_14)}, {{"subscript"}, ((uint8_t*)subscript_91)}, {{"*"}, ((uint8_t*)_times_18)}, {{"+"}, ((uint8_t*)_plus_15)}, {{"update-child"}, ((uint8_t*)update_child_1)}, {{"inner-node-to-leaf"}, ((uint8_t*)inner_node_to_leaf_1)}, {{"fold-with-index"}, ((uint8_t*)fold_with_index_1)}, {{"fold-with-index-recur"}, ((uint8_t*)fold_with_index_recur_1)}, {{"=="}, ((uint8_t*)_equal_12)}, {{"subscript"}, ((uint8_t*)subscript_92)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_954)}, {{"end-ptr"}, ((uint8_t*)end_ptr_10)}, {{"copy-from!"}, ((uint8_t*)copy_from__e_1)}, {{"cast-immutable"}, ((uint8_t*)cast_immutable_4)}, {{"node-is-empty"}, ((uint8_t*)node_is_empty_1)}, {{"rtail"}, ((uint8_t*)rtail_1)}, {{"is-empty"}, ((uint8_t*)is_empty_16)}, {{"subscript"}, ((uint8_t*)subscript_93)}, {{"update"}, ((uint8_t*)update_2)}, {{"~"}, ((uint8_t*)_tilde_6)}, {{"alloc-uninitialized"}, ((uint8_t*)alloc_uninitialized_8)}, {{"copy-data-from!"}, ((uint8_t*)copy_data_from__e_5)}, {{"as-any-const-ptr"}, ((uint8_t*)as_any_const_ptr_5)}, {{"find-only-non-empty-child"}, ((uint8_t*)find_only_non_empty_child_1)}, {{"find-index"}, ((uint8_t*)find_index_6)}, {{"find-index-recur"}, ((uint8_t*)find_index_recur_4)}, {{"subscript"}, ((uint8_t*)subscript_94)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_973)}, {{"every"}, ((uint8_t*)every_3)}, {{"tail"}, ((uint8_t*)tail_5)}, {{"subscript"}, ((uint8_t*)subscript_95)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_979)}, {{"update-with-default"}, ((uint8_t*)update_with_default_1)}, {{"make-arr"}, ((uint8_t*)make_arr_2)}, {{"fill-ptr-range"}, ((uint8_t*)fill_ptr_range_5)}, {{"fill-ptr-range-recur"}, ((uint8_t*)fill_ptr_range_recur_5)}, {{"set-subscript"}, ((uint8_t*)set_subscript_18)}, {{"subscript"}, ((uint8_t*)subscript_96)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_986)}, {{"get-or-update-leaf"}, ((uint8_t*)get_or_update_leaf_1)}, {{"new-inner-node"}, ((uint8_t*)new_inner_node_1)}, {{"fold"}, ((uint8_t*)fold_20)}, {{"fold-recur"}, ((uint8_t*)fold_recur_11)}, {{"subscript"}, ((uint8_t*)subscript_97)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_994)}, {{"fill-fix-arr"}, ((uint8_t*)fill_fix_arr_4)}, {{"make-fix-arr"}, ((uint8_t*)make_fix_arr_4)}, {{"uninitialized-fix-arr"}, ((uint8_t*)uninitialized_fix_arr_7)}, {{"fix-arr"}, ((uint8_t*)fix_arr_17)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_13)}, {{"set-subscript"}, ((uint8_t*)set_subscript_19)}, {{"size"}, ((uint8_t*)size_9)}, {{"unsafe-set-at!"}, ((uint8_t*)unsafe_set_at__e_3)}, {{"subscript"}, ((uint8_t*)subscript_98)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_15)}, {{"subscript"}, ((uint8_t*)subscript_99)}, {{"unreachable"}, ((uint8_t*)unreachable_2)}, {{"throw"}, ((uint8_t*)throw_8)}, {{"throw"}, ((uint8_t*)throw_9)}, {{"hard-unreachable"}, ((uint8_t*)hard_unreachable_5)}, {{"~"}, ((uint8_t*)_tilde_7)}, {{"cast-immutable"}, ((uint8_t*)cast_immutable_5)}, {{"remove-at"}, ((uint8_t*)remove_at_1)}, {{"update"}, ((uint8_t*)update_3)}, {{"map-to-arr"}, ((uint8_t*)map_to_arr_1)}, {{"size"}, ((uint8_t*)size_10)}, {{"fold"}, ((uint8_t*)fold_21)}, {{"fold"}, ((uint8_t*)fold_22)}, {{"fold"}, ((uint8_t*)fold_23)}, {{"fold-recur"}, ((uint8_t*)fold_recur_12)}, {{"subscript"}, ((uint8_t*)subscript_100)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1026)}, {{"subscript"}, ((uint8_t*)subscript_101)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1028)}, {{"fold"}, ((uint8_t*)fold_24)}, {{"fold"}, ((uint8_t*)fold_25)}, {{"fold-recur"}, ((uint8_t*)fold_recur_13)}, {{"subscript"}, ((uint8_t*)subscript_102)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1033)}, {{"subscript"}, ((uint8_t*)subscript_103)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1037)}, {{"end-ptr"}, ((uint8_t*)end_ptr_11)}, {{"empty!"}, ((uint8_t*)empty__e_1)}, {{"fill!"}, ((uint8_t*)fill__e_1)}, {{"map!"}, ((uint8_t*)map__e_1)}, {{"map-recur!"}, ((uint8_t*)map_recur__e_1)}, {{"!="}, ((uint8_t*)_notEqual_12)}, {{"subscript"}, ((uint8_t*)subscript_104)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1047)}, {{"end-ptr"}, ((uint8_t*)end_ptr_12)}, {{"first-failures"}, ((uint8_t*)first_failures)}, {{"subscript"}, ((uint8_t*)subscript_105)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1052)}, {{"run-crow-tests"}, ((uint8_t*)run_crow_tests)}, {{"list-tests"}, ((uint8_t*)list_tests)}, {{"mut-arr"}, ((uint8_t*)mut_arr_5)}, {{"fix-arr"}, ((uint8_t*)fix_arr_18)}, {{"each-child-recursive"}, ((uint8_t*)each_child_recursive_0)}, {{"each-child-recursive"}, ((uint8_t*)each_child_recursive_1)}, {{"is-dir"}, ((uint8_t*)is_dir_0)}, {{"is-dir"}, ((uint8_t*)is_dir_1)}, {{"get-stat"}, ((uint8_t*)get_stat)}, {{"stat"}, ((uint8_t*)stat_0)}, {{"errno"}, ((uint8_t*)errno)}, {{"ENOENT"}, ((uint8_t*)ENOENT)}, {{"todo"}, ((uint8_t*)todo_4)}, {{"throw"}, ((uint8_t*)throw_10)}, {{"throw"}, ((uint8_t*)throw_11)}, {{"hard-unreachable"}, ((uint8_t*)hard_unreachable_6)}, {{"with-value"}, ((uint8_t*)with_value_1)}, {{"S_IFMT"}, ((uint8_t*)S_IFMT)}, {{"S_IFDIR"}, ((uint8_t*)S_IFDIR)}, {{"to-c-str"}, ((uint8_t*)to_c_str)}, {{"each"}, ((uint8_t*)each_7)}, {{"each-recur"}, ((uint8_t*)each_recur_4)}, {{"!="}, ((uint8_t*)_notEqual_13)}, {{"subscript"}, ((uint8_t*)subscript_106)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1080)}, {{"read-dir"}, ((uint8_t*)read_dir_0)}, {{"read-dir"}, ((uint8_t*)read_dir_1)}, {{"!="}, ((uint8_t*)_notEqual_14)}, {{"read-dir-recur"}, ((uint8_t*)read_dir_recur)}, {{"zero"}, ((uint8_t*)zero_4)}, {{"!="}, ((uint8_t*)_notEqual_15)}, {{"as-any-const-ptr"}, ((uint8_t*)as_any_const_ptr_6)}, {{"*"}, ((uint8_t*)_times_19)}, {{"ref-eq"}, ((uint8_t*)ref_eq)}, {{"get-dirent-name"}, ((uint8_t*)get_dirent_name)}, {{"+"}, ((uint8_t*)_plus_16)}, {{"ptr-cast"}, ((uint8_t*)ptr_cast_1)}, {{"~="}, ((uint8_t*)_concatEquals_8)}, {{"incr-capacity!"}, ((uint8_t*)incr_capacity__e_3)}, {{"ensure-capacity"}, ((uint8_t*)ensure_capacity_3)}, {{"capacity"}, ((uint8_t*)capacity_4)}, {{"size"}, ((uint8_t*)size_11)}, {{"increase-capacity-to!"}, ((uint8_t*)increase_capacity_to__e_3)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_14)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_15)}, {{"uninitialized-fix-arr"}, ((uint8_t*)uninitialized_fix_arr_8)}, {{"fix-arr"}, ((uint8_t*)fix_arr_19)}, {{"copy-data-from!"}, ((uint8_t*)copy_data_from__e_6)}, {{"as-any-const-ptr"}, ((uint8_t*)as_any_const_ptr_7)}, {{"set-zero-elements"}, ((uint8_t*)set_zero_elements_3)}, {{"set-zero-range"}, ((uint8_t*)set_zero_range_4)}, {{"subscript"}, ((uint8_t*)subscript_107)}, {{"sort"}, ((uint8_t*)sort_0)}, {{"sort"}, ((uint8_t*)sort_1)}, {{"fix-arr"}, ((uint8_t*)fix_arr_20)}, {{"make-fix-arr"}, ((uint8_t*)make_fix_arr_5)}, {{"sort!"}, ((uint8_t*)sort__e_1)}, {{"is-empty"}, ((uint8_t*)is_empty_17)}, {{"insertion-sort-recur!"}, ((uint8_t*)insertion_sort_recur__e)}, {{"!="}, ((uint8_t*)_notEqual_16)}, {{"insert!"}, ((uint8_t*)insert__e)}, {{"=="}, ((uint8_t*)_equal_13)}, {{"subscript"}, ((uint8_t*)subscript_108)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1122)}, {{"end-ptr"}, ((uint8_t*)end_ptr_13)}, {{"cast-immutable"}, ((uint8_t*)cast_immutable_6)}, {{"move-to-arr!"}, ((uint8_t*)move_to_arr__e_2)}, {{"move-to-fix-arr!"}, ((uint8_t*)move_to_fix_arr__e_2)}, {{"has-substr"}, ((uint8_t*)has_substr)}, {{"contains-subseq"}, ((uint8_t*)contains_subseq)}, {{"index-of-subseq"}, ((uint8_t*)index_of_subseq)}, {{"index-of-subseq-recur"}, ((uint8_t*)index_of_subseq_recur)}, {{"ext-is-crow"}, ((uint8_t*)ext_is_crow)}, {{"=="}, ((uint8_t*)_equal_14)}, {{"opt-equal"}, ((uint8_t*)opt_equal)}, {{"is-empty"}, ((uint8_t*)is_empty_18)}, {{"get-extension"}, ((uint8_t*)get_extension)}, {{"last-index-of"}, ((uint8_t*)last_index_of)}, {{"last"}, ((uint8_t*)last)}, {{"rtail"}, ((uint8_t*)rtail_2)}, {{"base-name"}, ((uint8_t*)base_name)}, {{"flat-map-with-max-size"}, ((uint8_t*)flat_map_with_max_size)}, {{"mut-arr"}, ((uint8_t*)mut_arr_6)}, {{"fix-arr"}, ((uint8_t*)fix_arr_21)}, {{"~="}, ((uint8_t*)_concatEquals_9)}, {{"each"}, ((uint8_t*)each_8)}, {{"each-recur"}, ((uint8_t*)each_recur_5)}, {{"=="}, ((uint8_t*)_equal_15)}, {{"!="}, ((uint8_t*)_notEqual_17)}, {{"subscript"}, ((uint8_t*)subscript_109)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1152)}, {{"*"}, ((uint8_t*)_times_20)}, {{"+"}, ((uint8_t*)_plus_17)}, {{"end-ptr"}, ((uint8_t*)end_ptr_14)}, {{"~="}, ((uint8_t*)_concatEquals_10)}, {{"incr-capacity!"}, ((uint8_t*)incr_capacity__e_4)}, {{"ensure-capacity"}, ((uint8_t*)ensure_capacity_4)}, {{"capacity"}, ((uint8_t*)capacity_5)}, {{"size"}, ((uint8_t*)size_12)}, {{"increase-capacity-to!"}, ((uint8_t*)increase_capacity_to__e_4)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_16)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_17)}, {{"uninitialized-fix-arr"}, ((uint8_t*)uninitialized_fix_arr_9)}, {{"fix-arr"}, ((uint8_t*)fix_arr_22)}, {{"alloc-uninitialized"}, ((uint8_t*)alloc_uninitialized_9)}, {{"copy-data-from!"}, ((uint8_t*)copy_data_from__e_7)}, {{"as-any-const-ptr"}, ((uint8_t*)as_any_const_ptr_8)}, {{"set-zero-elements"}, ((uint8_t*)set_zero_elements_4)}, {{"set-zero-range"}, ((uint8_t*)set_zero_range_5)}, {{"subscript"}, ((uint8_t*)subscript_110)}, {{"subscript"}, ((uint8_t*)subscript_111)}, {{"set-subscript"}, ((uint8_t*)set_subscript_20)}, {{"subscript"}, ((uint8_t*)subscript_112)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1176)}, {{"reduce-size-if-more-than!"}, ((uint8_t*)reduce_size_if_more_than__e)}, {{"drop"}, ((uint8_t*)drop_7)}, {{"pop!"}, ((uint8_t*)pop__e)}, {{"is-empty"}, ((uint8_t*)is_empty_19)}, {{"subscript"}, ((uint8_t*)subscript_113)}, {{"subscript"}, ((uint8_t*)subscript_114)}, {{"set-subscript"}, ((uint8_t*)set_subscript_21)}, {{"move-to-arr!"}, ((uint8_t*)move_to_arr__e_3)}, {{"cast-immutable"}, ((uint8_t*)cast_immutable_7)}, {{"move-to-fix-arr!"}, ((uint8_t*)move_to_fix_arr__e_3)}, {{"run-single-crow-test"}, ((uint8_t*)run_single_crow_test)}, {{"first-some"}, ((uint8_t*)first_some)}, {{"subscript"}, ((uint8_t*)subscript_115)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1191)}, {{"is-empty"}, ((uint8_t*)is_empty_20)}, {{"run-print-test"}, ((uint8_t*)run_print_test)}, {{"spawn-and-wait-result"}, ((uint8_t*)spawn_and_wait_result_0)}, {{"fold"}, ((uint8_t*)fold_26)}, {{"fold-recur"}, ((uint8_t*)fold_recur_14)}, {{"subscript"}, ((uint8_t*)subscript_116)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1198)}, {{"is-file"}, ((uint8_t*)is_file_0)}, {{"is-file"}, ((uint8_t*)is_file_1)}, {{"S_IFREG"}, ((uint8_t*)S_IFREG)}, {{"spawn-and-wait-result"}, ((uint8_t*)spawn_and_wait_result_1)}, {{"make-pipes"}, ((uint8_t*)make_pipes)}, {{"check-posix-error"}, ((uint8_t*)check_posix_error)}, {{"*"}, ((uint8_t*)_times_21)}, {{"keep-polling"}, ((uint8_t*)keep_polling)}, {{"fix-arr"}, ((uint8_t*)fix_arr_23)}, {{"make-fix-arr"}, ((uint8_t*)make_fix_arr_6)}, {{"uninitialized-fix-arr"}, ((uint8_t*)uninitialized_fix_arr_10)}, {{"fix-arr"}, ((uint8_t*)fix_arr_24)}, {{"alloc-uninitialized"}, ((uint8_t*)alloc_uninitialized_10)}, {{"fill-ptr-range"}, ((uint8_t*)fill_ptr_range_6)}, {{"fill-ptr-range-recur"}, ((uint8_t*)fill_ptr_range_recur_6)}, {{"set-subscript"}, ((uint8_t*)set_subscript_22)}, {{"subscript"}, ((uint8_t*)subscript_117)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1223)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_18)}, {{"subscript"}, ((uint8_t*)subscript_118)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_16)}, {{"subscript"}, ((uint8_t*)subscript_119)}, {{"*"}, ((uint8_t*)_times_22)}, {{"+"}, ((uint8_t*)_plus_18)}, {{"POLLIN"}, ((uint8_t*)POLLIN)}, {{"ref-of-val-at"}, ((uint8_t*)ref_of_val_at)}, {{"size"}, ((uint8_t*)size_13)}, {{"ref-of-ptr"}, ((uint8_t*)ref_of_ptr)}, {{"handle-revents"}, ((uint8_t*)handle_revents)}, {{"has-POLLIN"}, ((uint8_t*)has_POLLIN)}, {{"bits-intersect"}, ((uint8_t*)bits_intersect)}, {{"!="}, ((uint8_t*)_notEqual_18)}, {{"read-to-buffer-until-eof"}, ((uint8_t*)read_to_buffer_until_eof)}, {{"unsafe-set-size!"}, ((uint8_t*)unsafe_set_size__e)}, {{"reserve"}, ((uint8_t*)reserve)}, {{"to-nat64"}, ((uint8_t*)to_nat64_0)}, {{"<=>"}, ((uint8_t*)_compare_11)}, {{"cmp"}, ((uint8_t*)cmp_2)}, {{"<"}, ((uint8_t*)_less_6)}, {{"has-POLLHUP"}, ((uint8_t*)has_POLLHUP)}, {{"POLLHUP"}, ((uint8_t*)POLLHUP)}, {{"has-POLLPRI"}, ((uint8_t*)has_POLLPRI)}, {{"POLLPRI"}, ((uint8_t*)POLLPRI)}, {{"has-POLLOUT"}, ((uint8_t*)has_POLLOUT)}, {{"POLLOUT"}, ((uint8_t*)POLLOUT)}, {{"has-POLLERR"}, ((uint8_t*)has_POLLERR)}, {{"POLLERR"}, ((uint8_t*)POLLERR)}, {{"has-POLLNVAL"}, ((uint8_t*)has_POLLNVAL)}, {{"POLLNVAL"}, ((uint8_t*)POLLNVAL)}, {{"to-nat64"}, ((uint8_t*)to_nat64_1)}, {{"any"}, ((uint8_t*)any)}, {{"wait-and-get-exit-code"}, ((uint8_t*)wait_and_get_exit_code)}, {{"WIFEXITED"}, ((uint8_t*)WIFEXITED)}, {{"WTERMSIG"}, ((uint8_t*)WTERMSIG)}, {{"WEXITSTATUS"}, ((uint8_t*)WEXITSTATUS)}, {{">>"}, ((uint8_t*)_shiftRight)}, {{"<=>"}, ((uint8_t*)_compare_12)}, {{"cmp"}, ((uint8_t*)cmp_3)}, {{"<"}, ((uint8_t*)_less_7)}, {{"todo"}, ((uint8_t*)todo_5)}, {{"WIFSIGNALED"}, ((uint8_t*)WIFSIGNALED)}, {{"to-str"}, ((uint8_t*)to_str_4)}, {{"to-str"}, ((uint8_t*)to_str_5)}, {{"to-str"}, ((uint8_t*)to_str_6)}, {{"to-base"}, ((uint8_t*)to_base)}, {{"digit-to-str"}, ((uint8_t*)digit_to_str)}, {{"mod"}, ((uint8_t*)mod)}, {{"abs"}, ((uint8_t*)abs)}, {{"-"}, ((uint8_t*)_minus_8)}, {{"*"}, ((uint8_t*)_times_23)}, {{"with-value"}, ((uint8_t*)with_value_2)}, {{"WIFSTOPPED"}, ((uint8_t*)WIFSTOPPED)}, {{"WIFCONTINUED"}, ((uint8_t*)WIFCONTINUED)}, {{"convert-args"}, ((uint8_t*)convert_args)}, {{"~"}, ((uint8_t*)_tilde_8)}, {{"alloc-uninitialized"}, ((uint8_t*)alloc_uninitialized_11)}, {{"copy-data-from!"}, ((uint8_t*)copy_data_from__e_8)}, {{"as-any-const-ptr"}, ((uint8_t*)as_any_const_ptr_9)}, {{"map"}, ((uint8_t*)map_1)}, {{"make-arr"}, ((uint8_t*)make_arr_3)}, {{"fill-ptr-range"}, ((uint8_t*)fill_ptr_range_7)}, {{"fill-ptr-range-recur"}, ((uint8_t*)fill_ptr_range_recur_7)}, {{"set-subscript"}, ((uint8_t*)set_subscript_23)}, {{"subscript"}, ((uint8_t*)subscript_120)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1294)}, {{"subscript"}, ((uint8_t*)subscript_121)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1296)}, {{"convert-environ"}, ((uint8_t*)convert_environ)}, {{"mut-arr"}, ((uint8_t*)mut_arr_7)}, {{"fix-arr"}, ((uint8_t*)fix_arr_25)}, {{"each"}, ((uint8_t*)each_9)}, {{"fold"}, ((uint8_t*)fold_27)}, {{"fold-recur"}, ((uint8_t*)fold_recur_15)}, {{"fold"}, ((uint8_t*)fold_28)}, {{"fold-recur"}, ((uint8_t*)fold_recur_16)}, {{"subscript"}, ((uint8_t*)subscript_122)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1308)}, {{"~="}, ((uint8_t*)_concatEquals_11)}, {{"incr-capacity!"}, ((uint8_t*)incr_capacity__e_5)}, {{"ensure-capacity"}, ((uint8_t*)ensure_capacity_5)}, {{"capacity"}, ((uint8_t*)capacity_6)}, {{"size"}, ((uint8_t*)size_14)}, {{"increase-capacity-to!"}, ((uint8_t*)increase_capacity_to__e_5)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_19)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_20)}, {{"uninitialized-fix-arr"}, ((uint8_t*)uninitialized_fix_arr_11)}, {{"fix-arr"}, ((uint8_t*)fix_arr_26)}, {{"set-zero-elements"}, ((uint8_t*)set_zero_elements_5)}, {{"set-zero-range"}, ((uint8_t*)set_zero_range_6)}, {{"subscript"}, ((uint8_t*)subscript_123)}, {{"move-to-arr!"}, ((uint8_t*)move_to_arr__e_4)}, {{"cast-immutable"}, ((uint8_t*)cast_immutable_8)}, {{"move-to-fix-arr!"}, ((uint8_t*)move_to_fix_arr__e_4)}, {{"throw"}, ((uint8_t*)throw_12)}, {{"throw"}, ((uint8_t*)throw_13)}, {{"hard-unreachable"}, ((uint8_t*)hard_unreachable_7)}, {{"handle-output"}, ((uint8_t*)handle_output)}, {{"try-read-file"}, ((uint8_t*)try_read_file_0)}, {{"try-read-file"}, ((uint8_t*)try_read_file_1)}, {{"O_RDONLY"}, ((uint8_t*)O_RDONLY)}, {{"todo"}, ((uint8_t*)todo_6)}, {{"seek-end"}, ((uint8_t*)seek_end)}, {{"seek-set"}, ((uint8_t*)seek_set)}, {{"write-file"}, ((uint8_t*)write_file_0)}, {{"write-file"}, ((uint8_t*)write_file_1)}, {{"<<"}, ((uint8_t*)_shiftLeft)}, {{"<=>"}, ((uint8_t*)_compare_13)}, {{"cmp"}, ((uint8_t*)cmp_4)}, {{"<"}, ((uint8_t*)_less_8)}, {{"O_CREAT"}, ((uint8_t*)O_CREAT)}, {{"O_WRONLY"}, ((uint8_t*)O_WRONLY)}, {{"O_TRUNC"}, ((uint8_t*)O_TRUNC)}, {{"to-str"}, ((uint8_t*)to_str_7)}, {{"with-value"}, ((uint8_t*)with_value_3)}, {{"ptr-cast"}, ((uint8_t*)ptr_cast_2)}, {{"to-int64"}, ((uint8_t*)to_int64)}, {{"max-int64"}, ((uint8_t*)max_int64)}, {{"is-empty"}, ((uint8_t*)is_empty_21)}, {{"remove-colors"}, ((uint8_t*)remove_colors)}, {{"remove-colors-recur!"}, ((uint8_t*)remove_colors_recur__e)}, {{"~="}, ((uint8_t*)_concatEquals_12)}, {{"tail"}, ((uint8_t*)tail_6)}, {{"remove-colors-recur-2!"}, ((uint8_t*)remove_colors_recur_2__e)}, {{"run-single-runnable-test"}, ((uint8_t*)run_single_runnable_test)}, {{"~"}, ((uint8_t*)_tilde_9)}, {{"with-value"}, ((uint8_t*)with_value_4)}, {{"lint"}, ((uint8_t*)lint)}, {{"list-lintable-files"}, ((uint8_t*)list_lintable_files)}, {{"excluded-from-lint"}, ((uint8_t*)excluded_from_lint)}, {{"in"}, ((uint8_t*)in_2)}, {{"in-recur"}, ((uint8_t*)in_recur_1)}, {{"noctx-at"}, ((uint8_t*)noctx_at_2)}, {{"exists"}, ((uint8_t*)exists)}, {{"ends-with"}, ((uint8_t*)ends_with_0)}, {{"ends-with"}, ((uint8_t*)ends_with_1)}, {{"should-ignore-extension-of-name"}, ((uint8_t*)should_ignore_extension_of_name)}, {{"should-ignore-extension"}, ((uint8_t*)should_ignore_extension)}, {{"ignored-extensions"}, ((uint8_t*)ignored_extensions)}, {{"lint-file"}, ((uint8_t*)lint_file)}, {{"read-file"}, ((uint8_t*)read_file)}, {{"each-with-index"}, ((uint8_t*)each_with_index_0)}, {{"each-with-index-recur"}, ((uint8_t*)each_with_index_recur_0)}, {{"subscript"}, ((uint8_t*)subscript_124)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1388)}, {{"lines"}, ((uint8_t*)lines)}, {{"each-with-index"}, ((uint8_t*)each_with_index_1)}, {{"each-with-index-recur"}, ((uint8_t*)each_with_index_recur_1)}, {{"subscript"}, ((uint8_t*)subscript_125)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1393)}, {{"swap"}, ((uint8_t*)swap)}, {{"*"}, ((uint8_t*)_times_24)}, {{"set-deref"}, ((uint8_t*)set_deref_1)}, {{"line-len"}, ((uint8_t*)line_len)}, {{"n-tabs"}, ((uint8_t*)n_tabs)}, {{"tab-size"}, ((uint8_t*)tab_size)}, {{"max-line-length"}, ((uint8_t*)max_line_length)}, {{"print-failures"}, ((uint8_t*)print_failures)}, {{"print-failure"}, ((uint8_t*)print_failure)}, {{"print-bold"}, ((uint8_t*)print_bold)}, {{"print-reset"}, ((uint8_t*)print_reset)}};
struct sym constantarr_1_0[402] = {{"<<UNKNOWN>>"}, {"mark"}, {"hard-assert"}, {"is-word-aligned"}, {"words-of-bytes"}, {"round-up-to-multiple-of-8"}, {"ptr-cast"}, {"-"}, {"<=>"}, {"cmp"}, {"<"}, {"<="}, {"!"}, {"mark-range-recur"}, {">"}, {"rt-main"}, {"lbv"}, {"lock-by-val"}, {"atomic-bool"}, {"create-condition"}, {"hard-assert-posix-error"}, {"CLOCK_MONOTONIC"}, {"island"}, {"task-queue"}, {"mut-arr-by-val-with-capacity-from-unmanaged-memory"}, {"fix-arr"}, {"unmanaged-alloc-zeroed-elements"}, {"unmanaged-alloc-elements"}, {"unmanaged-alloc-bytes"}, {"!="}, {"set-zero-range"}, {"drop"}, {"default-exception-handler"}, {"print-err-no-newline"}, {"write-no-newline"}, {"as-any-const-ptr"}, {"size-bytes"}, {"todo"}, {"stderr"}, {"print-err"}, {"to-str"}, {"writer"}, {"mut-arr"}, {"~="}, {"each"}, {"each-recur"}, {"=="}, {"subscript"}, {"call-with-ctx"}, {"*"}, {"+"}, {"end-ptr"}, {"incr-capacity!"}, {"ensure-capacity"}, {"capacity"}, {"size"}, {"increase-capacity-to!"}, {"assert"}, {"throw"}, {"get-exception-ctx"}, {"number-to-throw"}, {"hard-unreachable"}, {"get-backtrace"}, {"try-alloc-backtrace-arrs"}, {"try-alloc-uninitialized"}, {"try-alloc"}, {"try-gc-alloc"}, {"acquire!"}, {"acquire-recur!"}, {"try-acquire!"}, {"try-set!"}, {"try-change!"}, {"yield-thread"}, {"try-gc-alloc-recur"}, {"range-free"}, {"maybe-set-needs-gc!"}, {"release!"}, {"must-unset!"}, {"try-unset!"}, {"get-gc"}, {"get-gc-ctx"}, {"code-ptrs-size"}, {"copy-data-from!"}, {"sort!"}, {"swap!"}, {"set-subscript"}, {"partition!"}, {"fill-code-names!"}, {"get-fun-name"}, {"begin-ptr"}, {"uninitialized-fix-arr"}, {"alloc-uninitialized"}, {"alloc"}, {"gc-alloc"}, {"set-zero-elements"}, {".."}, {">="}, {"round-up-to-power-of-two"}, {"round-up-to-power-of-two-recur"}, {"/"}, {"forbid"}, {"is-empty"}, {"arr-from-begin-end"}, {"find-cstr-end"}, {"find-char-in-cstr"}, {"move-to-str!"}, {"move-to-arr!"}, {"cast-immutable"}, {"move-to-fix-arr!"}, {"get-global-ctx"}, {"default-log-handler"}, {"print"}, {"print-no-newline"}, {"stdout"}, {"~"}, {"gc"}, {"validate-gc"}, {"thread-safe-counter"}, {"add-main-task"}, {"exception-ctx"}, {"log-ctx"}, {"perf-ctx"}, {"ctx"}, {"add-first-task"}, {"then-void"}, {"then"}, {"unresolved"}, {"callback!"}, {"with-lock"}, {"forward-to!"}, {"resolve-or-reject!"}, {"call-callbacks!"}, {"get-island"}, {"unsafe-at"}, {"add-task"}, {"task-queue-node"}, {"insert-task!"}, {"size-recur"}, {"insert-recur"}, {"tasks"}, {"broadcast!"}, {"no-timestamp"}, {"catch"}, {"catch-with-exception-ctx"}, {"zero"}, {"reject!"}, {"cur-island-and-exclusion"}, {"delay"}, {"resolved"}, {"tail"}, {"map"}, {"make-arr"}, {"fill-ptr-range"}, {"fill-ptr-range-recur"}, {"handle-exceptions"}, {"exception-handler"}, {"get-cur-island"}, {"run-threads"}, {"start-threads-recur"}, {"create-one-thread"}, {"null"}, {"EAGAIN"}, {"as-cell"}, {"thread-fun"}, {"thread-function"}, {"thread-function-recur"}, {"assert-islands-are-shut-down"}, {"noctx-at"}, {"hard-forbid"}, {"get-sequence"}, {"choose-task"}, {"get-monotime-nsec"}, {"choose-task-recur"}, {"choose-task-in-island"}, {"pop-task!"}, {"in"}, {"in-recur"}, {"temp-as-arr"}, {"temp-as-fix-arr"}, {"pop-recur!"}, {"to-opt-time"}, {"push-capacity-must-be-sufficient!"}, {"is-no-task"}, {"min-time"}, {"min"}, {"do-task"}, {"return-task!"}, {"noctx-must-remove-unordered!"}, {"noctx-must-remove-unordered-recur!"}, {"noctx-remove-unordered-at!"}, {"return-ctx"}, {"return-gc-ctx"}, {"run-garbage-collection"}, {"mark-visit"}, {"clear-free-mem!"}, {"wait-on"}, {"to-timespec"}, {"ETIMEDOUT"}, {"join-threads-recur"}, {"join-one-thread"}, {"EINVAL"}, {"ESRCH"}, {"unmanaged-free"}, {"destroy-condition"}, {"main"}, {"parse-named-args"}, {"parse-command-dynamic"}, {"find-index"}, {"find-index-recur"}, {"starts-with"}, {"arr-equal"}, {"equal-recur"}, {"arr-compare"}, {"compare-recur"}, {"hash-mix"}, {"dict"}, {"no-duplicate-keys"}, {"every"}, {"fold"}, {"fold-recur"}, {"empty-leaf-node"}, {"get-or-update"}, {"hash"}, {"get-or-update-recur"}, {"low-bits"}, {"update-child"}, {"inner-node-to-leaf"}, {"fold-with-index"}, {"fold-with-index-recur"}, {"leaf-max-size"}, {"unreachable"}, {"copy-from!"}, {"node-is-empty"}, {"rtail"}, {"update"}, {"find-only-non-empty-child"}, {"force"}, {"->"}, {"update-with-default"}, {"get-or-update-leaf"}, {"new-inner-node"}, {"max"}, {"fill-fix-arr"}, {"make-fix-arr"}, {"unsafe-set-at!"}, {"remove-at"}, {"mut-dict"}, {"parse-named-args-recur"}, {"try-remove-start"}, {"update!"}, {"should-expand"}, {"expand!"}, {"mut-dict-with-capacity"}, {"is-at-capacity"}, {"remove-unordered-at!"}, {"move-to-dict!"}, {"map-to-arr"}, {"empty!"}, {"fill!"}, {"map!"}, {"map-recur!"}, {"fill-mut-arr"}, {"index-of"}, {"ptr-of"}, {"ptr-of-recur"}, {"set-deref"}, {"finish"}, {"with-value"}, {"with-str"}, {"interp"}, {"print-help"}, {"parse-nat"}, {"with-reader"}, {"reader"}, {"take-nat!"}, {"char-to-nat64"}, {"peek"}, {"next!"}, {"take-nat-recur!"}, {"do-test"}, {"parent-path"}, {"r-index-of"}, {"find-rindex"}, {"find-rindex-recur"}, {"child-path"}, {"get-environ"}, {"get-environ-recur"}, {"parse-environ-entry"}, {"first-failures"}, {"run-crow-tests"}, {"list-tests"}, {"each-child-recursive"}, {"is-dir"}, {"get-stat"}, {"stat"}, {"errno"}, {"ENOENT"}, {"S_IFMT"}, {"S_IFDIR"}, {"to-c-str"}, {"read-dir"}, {"read-dir-recur"}, {"ref-eq"}, {"get-dirent-name"}, {"sort"}, {"insertion-sort-recur!"}, {"insert!"}, {"has-substr"}, {"contains-subseq"}, {"index-of-subseq"}, {"index-of-subseq-recur"}, {"ext-is-crow"}, {"opt-equal"}, {"get-extension"}, {"last-index-of"}, {"last"}, {"base-name"}, {"flat-map-with-max-size"}, {"reduce-size-if-more-than!"}, {"pop!"}, {"run-single-crow-test"}, {"first-some"}, {"run-print-test"}, {"spawn-and-wait-result"}, {"is-file"}, {"S_IFREG"}, {"make-pipes"}, {"check-posix-error"}, {"keep-polling"}, {"POLLIN"}, {"ref-of-val-at"}, {"ref-of-ptr"}, {"handle-revents"}, {"has-POLLIN"}, {"bits-intersect"}, {"read-to-buffer-until-eof"}, {"unsafe-set-size!"}, {"reserve"}, {"to-nat64"}, {"has-POLLHUP"}, {"POLLHUP"}, {"has-POLLPRI"}, {"POLLPRI"}, {"has-POLLOUT"}, {"POLLOUT"}, {"has-POLLERR"}, {"POLLERR"}, {"has-POLLNVAL"}, {"POLLNVAL"}, {"any"}, {"wait-and-get-exit-code"}, {"WIFEXITED"}, {"WTERMSIG"}, {"WEXITSTATUS"}, {">>"}, {"WIFSIGNALED"}, {"to-base"}, {"digit-to-str"}, {"mod"}, {"abs"}, {"WIFSTOPPED"}, {"WIFCONTINUED"}, {"convert-args"}, {"convert-environ"}, {"handle-output"}, {"try-read-file"}, {"O_RDONLY"}, {"seek-end"}, {"seek-set"}, {"write-file"}, {"<<"}, {"O_CREAT"}, {"O_WRONLY"}, {"O_TRUNC"}, {"to-int64"}, {"max-int64"}, {"remove-colors"}, {"remove-colors-recur!"}, {"remove-colors-recur-2!"}, {"run-single-runnable-test"}, {"lint"}, {"list-lintable-files"}, {"excluded-from-lint"}, {"exists"}, {"ends-with"}, {"should-ignore-extension-of-name"}, {"should-ignore-extension"}, {"ignored-extensions"}, {"lint-file"}, {"read-file"}, {"each-with-index"}, {"each-with-index-recur"}, {"lines"}, {"swap"}, {"line-len"}, {"n-tabs"}, {"tab-size"}, {"max-line-length"}, {"print-failures"}, {"print-failure"}, {"print-bold"}, {"print-reset"}};
/* mark bool(ctx mark-ctx, ptr-any const-ptr<nat8>, size-bytes nat64) */
uint8_t mark(struct mark_ctx* ctx, uint8_t* ptr_any, uint64_t size_bytes) {
	uint8_t _0 = is_word_aligned_0(ptr_any);
	hard_assert(_0);
	uint64_t size_words0;
	size_words0 = words_of_bytes(size_bytes);
	
	uint64_t* ptr1;
	ptr1 = ptr_cast_0(ptr_any);
	
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
uint64_t* ptr_cast_0(uint8_t* a) {
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
struct comparison _compare_0(uint64_t a, uint64_t b) {
	return cmp_0(a, b);
}
/* cmp<nat64> comparison(a nat64, b nat64) */
struct comparison cmp_0(uint64_t a, uint64_t b) {
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
/* <<nat64> bool(a nat64, b nat64) */
uint8_t _less_0(uint64_t a, uint64_t b) {
	struct comparison _0 = _compare_0(a, b);
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
	gctx_by_val2 = (struct global_ctx) {_0, _1, _2, (struct opt_1) {0, .as0 = (struct none) {}}, (struct arr_4) {0u, NULL}, n_threads0, _3, f1, f1};
	
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
			struct fut_state_resolved_0 r7 = _4.as2;
			
			uint8_t _5 = gctx3->any_unhandled_exceptions;
			if (_5) {
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
	return (struct task_queue) {(struct opt_3) {0, .as0 = (struct none) {}}, _0};
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
	struct mut_arr_1* _0 = mut_arr_0(ctx);
	return (struct writer) {_0};
}
/* mut-arr<char> mut-arr<char>() */
struct mut_arr_1* mut_arr_0(struct ctx* ctx) {
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
		case 1: {
			struct hash_mix_0__lambda0* closure1 = _0.as1;
			
			return hash_mix_0__lambda0(ctx, closure1, p0);
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
	incr_capacity__e_0(ctx, a);
	uint64_t _0 = capacity_0(a);
	uint8_t _1 = _less_0(a->size, _0);
	assert_0(ctx, _1);
	char* _2 = begin_ptr_0(a);
	set_subscript_1(_2, a->size, value);
	uint64_t _3 = _plus_3(ctx, a->size, 1u);
	return (a->size = _3, (struct void_) {});
}
/* incr-capacity!<a> void(a mut-arr<char>) */
struct void_ incr_capacity__e_0(struct ctx* ctx, struct mut_arr_1* a) {
	uint64_t _0 = _plus_3(ctx, a->size, 1u);
	uint64_t _1 = round_up_to_power_of_two(ctx, _0);
	return ensure_capacity_0(ctx, a, _1);
}
/* ensure-capacity<a> void(a mut-arr<char>, min-capacity nat64) */
struct void_ ensure_capacity_0(struct ctx* ctx, struct mut_arr_1* a, uint64_t min_capacity) {
	uint64_t _0 = capacity_0(a);
	uint8_t _1 = _less_0(_0, min_capacity);
	if (_1) {
		return increase_capacity_to__e_0(ctx, a, min_capacity);
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
struct void_ increase_capacity_to__e_0(struct ctx* ctx, struct mut_arr_1* a, uint64_t new_capacity) {
	uint64_t _0 = capacity_0(a);
	uint8_t _1 = _greater(new_capacity, _0);
	assert_0(ctx, _1);
	char* old_begin0;
	old_begin0 = begin_ptr_0(a);
	
	struct fix_arr_1 _2 = uninitialized_fix_arr_0(ctx, new_capacity);
	a->backing = _2;
	char* _3 = begin_ptr_0(a);
	copy_data_from__e_1(ctx, _3, ((char*) old_begin0), a->size);
	uint64_t _4 = _plus_3(ctx, a->size, 1u);
	uint64_t _5 = size_0(a->backing);
	struct range _6 = _range(ctx, _4, _5);
	struct fix_arr_1 _7 = subscript_3(ctx, a->backing, _6);
	return set_zero_elements_0(_7);
}
/* assert void(condition bool) */
struct void_ assert_0(struct ctx* ctx, uint8_t condition) {
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
			struct some_4 _matched0 = _0.as1;
			
			struct backtrace_arrs* arrs1;
			arrs1 = _matched0.value;
			
			uint64_t n_code_ptrs2;
			uint64_t _1 = code_ptrs_size(ctx);
			int32_t _2 = backtrace(arrs1->code_ptrs, ((int32_t) ((int64_t) _1)));
			n_code_ptrs2 = ((uint64_t) ((int64_t) _2));
			
			uint64_t _3 = code_ptrs_size(ctx);
			uint8_t _4 = _lessOrEqual_0(n_code_ptrs2, _3);
			hard_assert(_4);
			copy_data_from__e_0(ctx, arrs1->funs, (struct arr_5) {1201, constantarr_5_0}.begin_ptr, (struct arr_5) {1201, constantarr_5_0}.size);
			sort__e_0(arrs1->funs, (struct arr_5) {1201, constantarr_5_0}.size);
			struct sym* end_code_names3;
			end_code_names3 = (arrs1->code_names + n_code_ptrs2);
			
			fill_code_names__e(ctx, arrs1->code_names, end_code_names3, ((uint8_t**) arrs1->code_ptrs), ((struct named_val*) arrs1->funs));
			return (struct backtrace) {(struct arr_1) {n_code_ptrs2, ((struct sym*) arrs1->code_names)}};
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
			return (struct opt_4) {0, .as0 = (struct none) {}};
		}
		case 1: {
			struct some_5 _matched0 = _0.as1;
			
			uint8_t** code_ptrs1;
			code_ptrs1 = _matched0.value;
			
			struct opt_7 _1 = try_alloc_uninitialized_1(ctx, 8u);
			switch (_1.kind) {
				case 0: {
					return (struct opt_4) {0, .as0 = (struct none) {}};
				}
				case 1: {
					struct some_7 _matched2 = _1.as1;
					
					struct sym* code_names3;
					code_names3 = _matched2.value;
					
					struct opt_8 _2 = try_alloc_uninitialized_2(ctx, (struct arr_5) {1201, constantarr_5_0}.size);
					switch (_2.kind) {
						case 0: {
							return (struct opt_4) {0, .as0 = (struct none) {}};
						}
						case 1: {
							struct some_8 _matched4 = _2.as1;
							
							struct named_val* funs5;
							funs5 = _matched4.value;
							
							struct backtrace_arrs* temp0;
							uint8_t* _3 = alloc(ctx, sizeof(struct backtrace_arrs));
							temp0 = ((struct backtrace_arrs*) _3);
							
							*temp0 = (struct backtrace_arrs) {code_ptrs1, code_names3, funs5};
							return (struct opt_4) {1, .as1 = (struct some_4) {temp0}};
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
			return (struct opt_5) {0, .as0 = (struct none) {}};
		}
		case 1: {
			struct some_6 _matched0 = _0.as1;
			
			uint8_t* res1;
			res1 = _matched0.value;
			
			return (struct opt_5) {1, .as1 = (struct some_5) {((uint8_t**) res1)}};
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
			return (struct opt_6) {1, .as1 = (struct some_6) {((uint8_t*) cur1)}};
		} else {
			gc->mark_cur = (gc->mark_cur + 1u);
			gc->data_cur = (gc->data_cur + 1u);
			gc = gc;
			size_bytes = size_bytes;
			goto top;
		}
	} else {
		return (struct opt_6) {0, .as0 = (struct none) {}};
	}
}
/* <=><nat64> comparison(a mut-ptr<nat64>, b mut-ptr<nat64>) */
struct comparison _compare_1(uint64_t* a, uint64_t* b) {
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
/* <<mut-ptr<nat64>> bool(a mut-ptr<nat64>, b mut-ptr<nat64>) */
uint8_t _less_1(uint64_t* a, uint64_t* b) {
	struct comparison _0 = _compare_1(a, b);
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
			return (struct opt_7) {0, .as0 = (struct none) {}};
		}
		case 1: {
			struct some_6 _matched0 = _0.as1;
			
			uint8_t* res1;
			res1 = _matched0.value;
			
			return (struct opt_7) {1, .as1 = (struct some_7) {((struct sym*) res1)}};
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
			return (struct opt_8) {0, .as0 = (struct none) {}};
		}
		case 1: {
			struct some_6 _matched0 = _0.as1;
			
			uint8_t* res1;
			res1 = _matched0.value;
			
			return (struct opt_8) {1, .as1 = (struct some_8) {((struct named_val*) res1)}};
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
struct void_ sort__e_0(struct named_val* a, uint64_t size) {
	top:;
	uint8_t _0 = _greater(size, 1u);
	if (_0) {
		swap__e_0(a, 0u, (size / 2u));
		uint64_t after_pivot0;
		after_pivot0 = partition__e(a, (*a).val, 1u, (size - 1u));
		
		uint64_t new_pivot_index1;
		new_pivot_index1 = (after_pivot0 - 1u);
		
		swap__e_0(a, 0u, new_pivot_index1);
		sort__e_0(a, new_pivot_index1);
		a = (a + after_pivot0);
		size = (size - after_pivot0);
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* swap!<named-val<const-ptr<nat8>>> void(a mut-ptr<named-val<const-ptr<nat8>>>, lo nat64, hi nat64) */
struct void_ swap__e_0(struct named_val* a, uint64_t lo, uint64_t hi) {
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
			swap__e_0(a, l, r);
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
struct comparison _compare_2(uint8_t* a, uint8_t* b) {
	return _compare_3(((uint8_t*) a), ((uint8_t*) b));
}
/* <=><a> comparison(a mut-ptr<nat8>, b mut-ptr<nat8>) */
struct comparison _compare_3(uint8_t* a, uint8_t* b) {
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
/* <<const-ptr<nat8>> bool(a const-ptr<nat8>, b const-ptr<nat8>) */
uint8_t _less_2(uint8_t* a, uint8_t* b) {
	struct comparison _0 = _compare_2(a, b);
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
/* fill-code-names! void(code-names mut-ptr<sym>, end-code-names mut-ptr<sym>, code-ptrs const-ptr<const-ptr<nat8>>, funs const-ptr<named-val<const-ptr<nat8>>>) */
struct void_ fill_code_names__e(struct ctx* ctx, struct sym* code_names, struct sym* end_code_names, uint8_t** code_ptrs, struct named_val* funs) {
	top:;
	uint8_t _0 = _less_3(code_names, end_code_names);
	if (_0) {
		uint8_t* _1 = _times_2(code_ptrs);
		struct sym _2 = get_fun_name(_1, funs, (struct arr_5) {1201, constantarr_5_0}.size);
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
struct comparison _compare_4(struct sym* a, struct sym* b) {
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
/* <<mut-ptr<sym>> bool(a mut-ptr<sym>, b mut-ptr<sym>) */
uint8_t _less_3(struct sym* a, struct sym* b) {
	struct comparison _0 = _compare_4(a, b);
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
struct fix_arr_1 uninitialized_fix_arr_0(struct ctx* ctx, uint64_t size) {
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
			struct some_6 _matched0 = _0.as1;
			
			uint8_t* res1;
			res1 = _matched0.value;
			
			return res1;
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
struct void_ set_zero_elements_0(struct fix_arr_1 a) {
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
	assert_0(ctx, _0);
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
	assert_0(ctx, _1);
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
		assert_0(ctx, (_1 == a));
		uint64_t _2 = _divide(ctx, res0, a);
		assert_0(ctx, (_2 == b));
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
struct comparison _compare_5(char* a, char* b) {
	return _compare_6(((char*) a), ((char*) b));
}
/* <=><a> comparison(a mut-ptr<char>, b mut-ptr<char>) */
struct comparison _compare_6(char* a, char* b) {
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
/* <=<const-ptr<a>> bool(a const-ptr<char>, b const-ptr<char>) */
uint8_t _lessOrEqual_1(char* a, char* b) {
	uint8_t _0 = _less_4(b, a);
	return _not(_0);
}
/* <<a> bool(a const-ptr<char>, b const-ptr<char>) */
uint8_t _less_4(char* a, char* b) {
	struct comparison _0 = _compare_5(a, b);
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
			struct some_9 _matched0 = _0.as1;
			
			char* v1;
			v1 = _matched0.value;
			
			return v1;
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
		return (struct opt_9) {1, .as1 = (struct some_9) {a}};
	} else {
		char _2 = _times_0(a);
		uint8_t _3 = _equal_3(_2, 0u);
		if (_3) {
			return (struct opt_9) {0, .as0 = (struct none) {}};
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
	struct arr_0 _0 = move_to_arr__e_0(a.chars);
	return (struct str) {_0};
}
/* move-to-arr!<char> arr<char>(a mut-arr<char>) */
struct arr_0 move_to_arr__e_0(struct mut_arr_1* a) {
	struct fix_arr_1 _0 = move_to_fix_arr__e_0(a);
	return cast_immutable_0(_0);
}
/* cast-immutable<a> arr<char>(a fix-arr<char>) */
struct arr_0 cast_immutable_0(struct fix_arr_1 a) {
	return a.inner;
}
/* move-to-fix-arr!<a> fix-arr<char>(a mut-arr<char>) */
struct fix_arr_1 move_to_fix_arr__e_0(struct mut_arr_1* a) {
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
struct str to_str_2(struct ctx* ctx, struct log_level a) {
	struct log_level _0 = a;
	switch (_0.kind) {
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
	res4 = (struct gc) {_4, 0u, (struct opt_2) {0, .as0 = (struct none) {}}, 0, 50331648u, mark0, mark0, mark_end1, data2, data2, data_end3};
	
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
struct comparison _compare_7(uint8_t* a, uint8_t* b) {
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
/* <=<mut-ptr<bool>> bool(a mut-ptr<bool>, b mut-ptr<bool>) */
uint8_t _lessOrEqual_2(uint8_t* a, uint8_t* b) {
	uint8_t _0 = _less_5(b, a);
	return _not(_0);
}
/* <<a> bool(a mut-ptr<bool>, b mut-ptr<bool>) */
uint8_t _less_5(uint8_t* a, uint8_t* b) {
	struct comparison _0 = _compare_7(a, b);
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
	
	struct fun_act2_0 add10;
	add10 = (struct fun_act2_0) {0, .as0 = (struct void_) {}};
	
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
	struct gc_ctx* res3;
	struct opt_2 _0 = gc->context_head;
	switch (_0.kind) {
		case 0: {
			struct gc_ctx* c0;
			uint8_t* _1 = malloc(sizeof(struct gc_ctx));
			c0 = ((struct gc_ctx*) _1);
			
			c0->gc = gc;
			c0->next_ctx = (struct opt_2) {0, .as0 = (struct none) {}};
			res3 = c0;
			break;
		}
		case 1: {
			struct some_2 _matched1 = _0.as1;
			
			struct gc_ctx* c2;
			c2 = _matched1.value;
			
			gc->context_head = c2->next_ctx;
			c2->next_ctx = (struct opt_2) {0, .as0 = (struct none) {}};
			res3 = c2;
			break;
		}
		default:
			
	res3 = NULL;;
	}
	
	release__e((&gc->lk));
	return res3;
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
	*temp0 = (struct fut_0) {_1, (struct fut_state_0) {0, .as0 = (struct fut_state_no_callbacks) {}}};
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
			
			*temp0 = (struct fut_state_callbacks_1) {_closure->cb, (struct opt_10) {0, .as0 = (struct none) {}}};
			return (_closure->f->state = (struct fut_state_1) {1, .as1 = temp0}, (struct void_) {});
		}
		case 1: {
			struct fut_state_callbacks_1* cbs0 = _0.as1;
			
			struct fut_state_callbacks_1* temp1;
			uint8_t* _2 = alloc(ctx, sizeof(struct fut_state_callbacks_1));
			temp1 = ((struct fut_state_callbacks_1*) _2);
			
			*temp1 = (struct fut_state_callbacks_1) {_closure->cb, (struct opt_10) {1, .as1 = (struct some_10) {cbs0}}};
			return (_closure->f->state = (struct fut_state_1) {1, .as1 = temp1}, (struct void_) {});
		}
		case 2: {
			struct fut_state_resolved_1 r1 = _0.as2;
			
			return subscript_7(ctx, _closure->cb, (struct result_1) {0, .as0 = (struct ok_1) {r1.value}});
		}
		case 3: {
			struct exception e2 = _0.as3;
			
			return subscript_7(ctx, _closure->cb, (struct result_1) {1, .as1 = (struct err_0) {e2}});
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
			
			return subscript_8(ctx, _closure->cb, (struct result_0) {1, .as1 = (struct err_0) {e2}});
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
			struct ok_0 o1 = _0.as0;
			
			_1 = (struct fut_state_0) {2, .as2 = (struct fut_state_resolved_0) {o1.value}};
			break;
		}
		case 1: {
			struct err_0 e2 = _0.as1;
			
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
	assert_0(ctx, _0);
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
	
	*temp0 = (struct task_queue_node) {task, (struct opt_3) {0, .as0 = (struct none) {}}};
	return temp0;
}
/* insert-task! void(a task-queue, inserted task-queue-node) */
struct void_ insert_task__e(struct task_queue* a, struct task_queue_node* inserted) {
	uint64_t size_before0;
	size_before0 = size_1(a);
	
	struct opt_3 _0 = a->head;
	switch (_0.kind) {
		case 0: {
			a->head = (struct opt_3) {1, .as1 = (struct some_3) {inserted}};
			break;
		}
		case 1: {
			struct some_3 _matched1 = _0.as1;
			
			struct task_queue_node* head2;
			head2 = _matched1.value;
			
			uint8_t _1 = _lessOrEqual_0(head2->task.time, inserted->task.time);
			if (_1) {
				insert_recur(head2, inserted);
			} else {
				inserted->next = (struct opt_3) {1, .as1 = (struct some_3) {head2}};
				a->head = (struct opt_3) {1, .as1 = (struct some_3) {inserted}};
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
			struct some_3 _matched0 = _0.as1;
			
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
	struct opt_3 _0 = prev->next;
	switch (_0.kind) {
		case 0: {
			return (prev->next = (struct opt_3) {1, .as1 = (struct some_3) {inserted}}, (struct void_) {});
		}
		case 1: {
			struct some_3 _matched0 = _0.as1;
			
			struct task_queue_node* cur1;
			cur1 = _matched0.value;
			
			uint8_t _1 = _lessOrEqual_0(cur1->task.time, inserted->task.time);
			if (_1) {
				prev = cur1;
				inserted = inserted;
				goto top;
			} else {
				inserted->next = (struct opt_3) {1, .as1 = (struct some_3) {cur1}};
				return (prev->next = (struct opt_3) {1, .as1 = (struct some_3) {inserted}}, (struct void_) {});
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
	return resolve_or_reject__e(ctx, f, (struct result_0) {1, .as1 = (struct err_0) {e}});
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
			struct ok_1 o0 = _0.as0;
			
			struct fut_0* _1 = subscript_10(ctx, _closure->cb, o0.value);
			return forward_to__e(ctx, _1, _closure->res);
		}
		case 1: {
			struct err_0 e1 = _0.as1;
			
			return reject__e(ctx, _closure->res, e1.value);
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
	*temp0 = (struct fut_1) {_1, (struct fut_state_1) {2, .as2 = (struct fut_state_resolved_1) {value}}};
	return temp0;
}
/* tail<const-ptr<char>> arr<const-ptr<char>>(a arr<const-ptr<char>>) */
struct arr_7 tail_0(struct ctx* ctx, struct arr_7 a) {
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
	assert_0(ctx, _0);
	char** _1 = _plus_6(a.begin_ptr, range.low);
	return (struct arr_7) {(range.high - range.low), _1};
}
/* +<a> const-ptr<const-ptr<char>>(a const-ptr<const-ptr<char>>, offset nat64) */
char** _plus_6(char** a, uint64_t offset) {
	return ((char**) (((char**) a) + offset));
}
/* map<str, const-ptr<char>> arr<str>(a arr<const-ptr<char>>, f fun-act1<str, const-ptr<char>>) */
struct arr_2 map_0(struct ctx* ctx, struct arr_7 a, struct fun_act1_6 f) {
	struct map_0__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct map_0__lambda0));
	temp0 = ((struct map_0__lambda0*) _0);
	
	*temp0 = (struct map_0__lambda0) {f, a};
	return make_arr_0(ctx, a.size, (struct fun_act1_7) {0, .as0 = temp0});
}
/* make-arr<out> arr<str>(size nat64, f fun-act1<str, nat64>) */
struct arr_2 make_arr_0(struct ctx* ctx, uint64_t size, struct fun_act1_7 f) {
	struct str* res0;
	res0 = alloc_uninitialized_1(ctx, size);
	
	fill_ptr_range_0(ctx, res0, size, f);
	return (struct arr_2) {size, ((struct str*) res0)};
}
/* alloc-uninitialized<a> mut-ptr<str>(size nat64) */
struct str* alloc_uninitialized_1(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(struct str)));
	return ((struct str*) _0);
}
/* fill-ptr-range<a> void(begin mut-ptr<str>, size nat64, f fun-act1<str, nat64>) */
struct void_ fill_ptr_range_0(struct ctx* ctx, struct str* begin, uint64_t size, struct fun_act1_7 f) {
	return fill_ptr_range_recur_0(ctx, begin, 0u, size, f);
}
/* fill-ptr-range-recur<a> void(begin mut-ptr<str>, i nat64, size nat64, f fun-act1<str, nat64>) */
struct void_ fill_ptr_range_recur_0(struct ctx* ctx, struct str* begin, uint64_t i, uint64_t size, struct fun_act1_7 f) {
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
			struct map_0__lambda0* closure0 = _0.as0;
			
			return map_0__lambda0(ctx, closure0, p0);
		}
		case 1: {
			struct fix_arr_20__lambda0* closure1 = _0.as1;
			
			return fix_arr_20__lambda0(ctx, closure1, p0);
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
	assert_0(ctx, _0);
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
struct str map_0__lambda0(struct ctx* ctx, struct map_0__lambda0* _closure, uint64_t i) {
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
	args0 = tail_0(ctx, _closure->all_args);
	
	struct arr_2 _0 = map_0(ctx, args0, (struct fun_act1_6) {0, .as0 = (struct void_) {}});
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
			struct err_0 e0 = _0.as1;
			
			struct island* _1 = get_cur_island(ctx);
			struct fun1_0 _2 = exception_handler(ctx, _1);
			return subscript_22(ctx, _2, e0.value);
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
struct fut_0* call_w_ctx_304(struct fun_act2_0 a, struct ctx* ctx, struct arr_7 p0, fun_ptr2 p1) {
	struct fun_act2_0 _0 = a;
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
	uint8_t* _0 = null_0();
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
uint8_t* null_0(void) {
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
			return 0;
		}
		default:
			
	return 0;;
	}
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
	struct choose_task_result _0 = choose_task_recur(gctx->islands, 0u, cur_time0, 0, (struct opt_11) {0, .as0 = (struct none) {}});
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
			res2 = (struct choose_task_in_island_result) {1, .as1 = (struct do_a_gc) {}};
		} else {
			res2 = (struct choose_task_in_island_result) {2, .as2 = (struct no_task) {1, (struct opt_11) {0, .as0 = (struct none) {}}}};
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
	
	struct pop_task_result res4;
	struct opt_3 _0 = a->head;
	switch (_0.kind) {
		case 0: {
			res4 = (struct pop_task_result) {1, .as1 = (struct no_task) {0, (struct opt_11) {0, .as0 = (struct none) {}}}};
			break;
		}
		case 1: {
			struct some_3 _matched1 = _0.as1;
			
			struct task_queue_node* head2;
			head2 = _matched1.value;
			
			struct task task3;
			task3 = head2->task;
			
			uint8_t _1 = _lessOrEqual_0(task3.time, cur_time);
			if (_1) {
				uint8_t _2 = in_0(task3.exclusion, exclusions0);
				if (_2) {
					struct opt_11 _3 = to_opt_time(task3.time);
					res4 = pop_recur__e(head2, exclusions0, cur_time, _3);
				} else {
					a->head = head2->next;
					res4 = (struct pop_task_result) {0, .as0 = head2->task};
				}
			} else {
				res4 = (struct pop_task_result) {1, .as1 = (struct no_task) {1, (struct opt_11) {1, .as1 = (struct some_11) {task3.time}}}};
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
/* in<nat64> bool(value nat64, a mut-arr<nat64>) */
uint8_t in_0(uint64_t value, struct mut_arr_0* a) {
	struct arr_3 _0 = temp_as_arr_0(a);
	return in_1(value, _0);
}
/* in<a> bool(value nat64, a arr<nat64>) */
uint8_t in_1(uint64_t value, struct arr_3 a) {
	return in_recur_0(value, a, 0u);
}
/* in-recur<a> bool(value nat64, a arr<nat64>, i nat64) */
uint8_t in_recur_0(uint64_t value, struct arr_3 a, uint64_t i) {
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
	struct fix_arr_0 _0 = temp_as_fix_arr_0(a);
	return temp_as_arr_1(_0);
}
/* temp-as-arr<a> arr<nat64>(a fix-arr<nat64>) */
struct arr_3 temp_as_arr_1(struct fix_arr_0 a) {
	return a.inner;
}
/* temp-as-fix-arr<a> fix-arr<nat64>(a mut-arr<nat64>) */
struct fix_arr_0 temp_as_fix_arr_0(struct mut_arr_0* a) {
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
			struct some_3 _matched0 = _0.as1;
			
			struct task_queue_node* cur1;
			cur1 = _matched0.value;
			
			struct task task2;
			task2 = cur1->task;
			
			uint8_t _1 = _lessOrEqual_0(task2.time, cur_time);
			if (_1) {
				uint8_t _2 = in_0(task2.exclusion, exclusions);
				if (_2) {
					struct opt_11 _3 = first_task_time;struct opt_11 _4;
					
					switch (_3.kind) {
						case 0: {
							_4 = to_opt_time(task2.time);
							break;
						}
						case 1: {
							struct some_11 _matched3 = _3.as1;
							
							uint64_t t4;
							t4 = _matched3.value;
							
							_4 = (struct opt_11) {1, .as1 = (struct some_11) {t4}};
							break;
						}
						default:
							
					_4 = (struct opt_11) {0};;
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
				return (struct pop_task_result) {1, .as1 = (struct no_task) {1, (struct opt_11) {1, .as1 = (struct some_11) {task2.time}}}};
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
		return (struct opt_11) {1, .as1 = (struct some_11) {a}};
	} else {
		return (struct opt_11) {0, .as0 = (struct none) {}};
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
			struct some_11 _matched0 = _0.as1;
			
			uint64_t ta1;
			ta1 = _matched0.value;
			
			struct opt_11 _1 = b;
			switch (_1.kind) {
				case 0: {
					return (struct opt_11) {0, .as0 = (struct none) {}};
				}
				case 1: {
					struct some_11 _matched2 = _1.as1;
					
					uint64_t tb3;
					tb3 = _matched2.value;
					
					uint64_t _2 = min(ta1, tb3);
					return (struct opt_11) {1, .as1 = (struct some_11) {_2}};
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
			uint64_t _4 = noctx_remove_unordered_at__e_0(a, index);
			return drop_1(_4);
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
struct void_ drop_1(uint64_t _p0) {
	return (struct void_) {};
}
/* noctx-remove-unordered-at!<a> nat64(a mut-arr<nat64>, index nat64) */
uint64_t noctx_remove_unordered_at__e_0(struct mut_arr_0* a, uint64_t index) {
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
	gc0->context_head = (struct opt_2) {1, .as1 = (struct some_2) {gc_ctx}};
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
	
	mark_visit_363((&mark_ctx0), gc_root);
	uint8_t* prev_mark_cur1;
	prev_mark_cur1 = gc->mark_cur;
	
	gc->mark_cur = gc->mark_begin;
	gc->data_cur = gc->data_begin;
	clear_free_mem__e(gc->mark_begin, prev_mark_cur1, gc->data_begin);
	validate_gc(gc);
	return (gc->needs_gc = 0, (struct void_) {});
}
/* mark-visit<island-gc-root> (generated) (generated) */
struct void_ mark_visit_363(struct mark_ctx* mark_ctx, struct island_gc_root value) {
	return mark_visit_364(mark_ctx, value.tasks);
}
/* mark-visit<task-queue> (generated) (generated) */
struct void_ mark_visit_364(struct mark_ctx* mark_ctx, struct task_queue value) {
	mark_visit_365(mark_ctx, value.head);
	return mark_visit_417(mark_ctx, value.currently_running_exclusions);
}
/* mark-visit<opt<task-queue-node>> (generated) (generated) */
struct void_ mark_visit_365(struct mark_ctx* mark_ctx, struct opt_3 value) {
	struct opt_3 _0 = value;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct some_3 value1 = _0.as1;
			
			return mark_visit_366(mark_ctx, value1);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* mark-visit<some<task-queue-node>> (generated) (generated) */
struct void_ mark_visit_366(struct mark_ctx* mark_ctx, struct some_3 value) {
	return mark_visit_416(mark_ctx, value.value);
}
/* mark-visit<task-queue-node> (generated) (generated) */
struct void_ mark_visit_367(struct mark_ctx* mark_ctx, struct task_queue_node value) {
	mark_visit_368(mark_ctx, value.task);
	return mark_visit_365(mark_ctx, value.next);
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
			
			return mark_visit_405(mark_ctx, value0);
		}
		case 1: {
			struct callback__e_1__lambda0* value1 = _0.as1;
			
			return mark_visit_407(mark_ctx, value1);
		}
		case 2: {
			struct subscript_10__lambda0__lambda0* value2 = _0.as2;
			
			return mark_visit_409(mark_ctx, value2);
		}
		case 3: {
			struct subscript_10__lambda0* value3 = _0.as3;
			
			return mark_visit_411(mark_ctx, value3);
		}
		case 4: {
			struct subscript_15__lambda0__lambda0* value4 = _0.as4;
			
			return mark_visit_413(mark_ctx, value4);
		}
		case 5: {
			struct subscript_15__lambda0* value5 = _0.as5;
			
			return mark_visit_415(mark_ctx, value5);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* mark-visit<callback!<in>.lambda0> (generated) (generated) */
struct void_ mark_visit_370(struct mark_ctx* mark_ctx, struct callback__e_0__lambda0 value) {
	mark_visit_404(mark_ctx, value.f);
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
			
			return mark_visit_403(mark_ctx, value1);
		}
		case 2: {
			return (struct void_) {};
		}
		case 3: {
			struct exception value3 = _0.as3;
			
			return mark_visit_395(mark_ctx, value3);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* mark-visit<fut-state-callbacks<void>> (generated) (generated) */
struct void_ mark_visit_373(struct mark_ctx* mark_ctx, struct fut_state_callbacks_1 value) {
	mark_visit_374(mark_ctx, value.cb);
	return mark_visit_401(mark_ctx, value.next);
}
/* mark-visit<fun-act1<void, result<void, exception>>> (generated) (generated) */
struct void_ mark_visit_374(struct mark_ctx* mark_ctx, struct fun_act1_3 value) {
	struct fun_act1_3 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct then__lambda0* value0 = _0.as0;
			
			return mark_visit_400(mark_ctx, value0);
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
			
			return mark_visit_394(mark_ctx, value1);
		}
		case 2: {
			return (struct void_) {};
		}
		case 3: {
			struct exception value3 = _0.as3;
			
			return mark_visit_395(mark_ctx, value3);
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
			struct some_0 value1 = _0.as1;
			
			return mark_visit_393(mark_ctx, value1);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* mark-visit<some<fut-state-callbacks<nat64>>> (generated) (generated) */
struct void_ mark_visit_393(struct mark_ctx* mark_ctx, struct some_0 value) {
	return mark_visit_394(mark_ctx, value.value);
}
/* mark-visit<gc-ptr(fut-state-callbacks<nat64>)> (generated) (generated) */
struct void_ mark_visit_394(struct mark_ctx* mark_ctx, struct fut_state_callbacks_0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct fut_state_callbacks_0));
	if (_0) {
		return mark_visit_387(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<exception> (generated) (generated) */
struct void_ mark_visit_395(struct mark_ctx* mark_ctx, struct exception value) {
	mark_visit_396(mark_ctx, value.message);
	return mark_visit_398(mark_ctx, value.backtrace);
}
/* mark-visit<str> (generated) (generated) */
struct void_ mark_visit_396(struct mark_ctx* mark_ctx, struct str value) {
	return mark_arr_397(mark_ctx, value.chars);
}
/* mark-arr<char> (generated) (generated) */
struct void_ mark_arr_397(struct mark_ctx* mark_ctx, struct arr_0 a) {
	uint8_t dropped0;
	dropped0 = mark(mark_ctx, ((uint8_t*) a.begin_ptr), (a.size * sizeof(char)));
	
	return (struct void_) {};
}
/* mark-visit<backtrace> (generated) (generated) */
struct void_ mark_visit_398(struct mark_ctx* mark_ctx, struct backtrace value) {
	return mark_arr_399(mark_ctx, value.return_stack);
}
/* mark-arr<sym> (generated) (generated) */
struct void_ mark_arr_399(struct mark_ctx* mark_ctx, struct arr_1 a) {
	uint8_t dropped0;
	dropped0 = mark(mark_ctx, ((uint8_t*) a.begin_ptr), (a.size * sizeof(struct sym)));
	
	return (struct void_) {};
}
/* mark-visit<gc-ptr(then<out, void>.lambda0)> (generated) (generated) */
struct void_ mark_visit_400(struct mark_ctx* mark_ctx, struct then__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct then__lambda0));
	if (_0) {
		return mark_visit_375(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<opt<fut-state-callbacks<void>>> (generated) (generated) */
struct void_ mark_visit_401(struct mark_ctx* mark_ctx, struct opt_10 value) {
	struct opt_10 _0 = value;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct some_10 value1 = _0.as1;
			
			return mark_visit_402(mark_ctx, value1);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* mark-visit<some<fut-state-callbacks<void>>> (generated) (generated) */
struct void_ mark_visit_402(struct mark_ctx* mark_ctx, struct some_10 value) {
	return mark_visit_403(mark_ctx, value.value);
}
/* mark-visit<gc-ptr(fut-state-callbacks<void>)> (generated) (generated) */
struct void_ mark_visit_403(struct mark_ctx* mark_ctx, struct fut_state_callbacks_1* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct fut_state_callbacks_1));
	if (_0) {
		return mark_visit_373(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(fut<void>)> (generated) (generated) */
struct void_ mark_visit_404(struct mark_ctx* mark_ctx, struct fut_1* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct fut_1));
	if (_0) {
		return mark_visit_371(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(callback!<in>.lambda0)> (generated) (generated) */
struct void_ mark_visit_405(struct mark_ctx* mark_ctx, struct callback__e_0__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct callback__e_0__lambda0));
	if (_0) {
		return mark_visit_370(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<callback!<a>.lambda0> (generated) (generated) */
struct void_ mark_visit_406(struct mark_ctx* mark_ctx, struct callback__e_1__lambda0 value) {
	mark_visit_390(mark_ctx, value.f);
	return mark_visit_388(mark_ctx, value.cb);
}
/* mark-visit<gc-ptr(callback!<a>.lambda0)> (generated) (generated) */
struct void_ mark_visit_407(struct mark_ctx* mark_ctx, struct callback__e_1__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct callback__e_1__lambda0));
	if (_0) {
		return mark_visit_406(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<subscript<out, in>.lambda0.lambda0> (generated) (generated) */
struct void_ mark_visit_408(struct mark_ctx* mark_ctx, struct subscript_10__lambda0__lambda0 value) {
	mark_visit_376(mark_ctx, value.f);
	return mark_visit_390(mark_ctx, value.res);
}
/* mark-visit<gc-ptr(subscript<out, in>.lambda0.lambda0)> (generated) (generated) */
struct void_ mark_visit_409(struct mark_ctx* mark_ctx, struct subscript_10__lambda0__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct subscript_10__lambda0__lambda0));
	if (_0) {
		return mark_visit_408(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<subscript<out, in>.lambda0> (generated) (generated) */
struct void_ mark_visit_410(struct mark_ctx* mark_ctx, struct subscript_10__lambda0 value) {
	mark_visit_376(mark_ctx, value.f);
	return mark_visit_390(mark_ctx, value.res);
}
/* mark-visit<gc-ptr(subscript<out, in>.lambda0)> (generated) (generated) */
struct void_ mark_visit_411(struct mark_ctx* mark_ctx, struct subscript_10__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct subscript_10__lambda0));
	if (_0) {
		return mark_visit_410(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<subscript<out>.lambda0.lambda0> (generated) (generated) */
struct void_ mark_visit_412(struct mark_ctx* mark_ctx, struct subscript_15__lambda0__lambda0 value) {
	mark_visit_379(mark_ctx, value.f);
	return mark_visit_390(mark_ctx, value.res);
}
/* mark-visit<gc-ptr(subscript<out>.lambda0.lambda0)> (generated) (generated) */
struct void_ mark_visit_413(struct mark_ctx* mark_ctx, struct subscript_15__lambda0__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct subscript_15__lambda0__lambda0));
	if (_0) {
		return mark_visit_412(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<subscript<out>.lambda0> (generated) (generated) */
struct void_ mark_visit_414(struct mark_ctx* mark_ctx, struct subscript_15__lambda0 value) {
	mark_visit_379(mark_ctx, value.f);
	return mark_visit_390(mark_ctx, value.res);
}
/* mark-visit<gc-ptr(subscript<out>.lambda0)> (generated) (generated) */
struct void_ mark_visit_415(struct mark_ctx* mark_ctx, struct subscript_15__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct subscript_15__lambda0));
	if (_0) {
		return mark_visit_414(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(task-queue-node)> (generated) (generated) */
struct void_ mark_visit_416(struct mark_ctx* mark_ctx, struct task_queue_node* value) {
	uint8_t _0 = mark(mark_ctx, ((uint8_t*) value), sizeof(struct task_queue_node));
	if (_0) {
		return mark_visit_367(mark_ctx, (*value));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<mut-arr<nat64>> (generated) (generated) */
struct void_ mark_visit_417(struct mark_ctx* mark_ctx, struct mut_arr_0 value) {
	return mark_visit_418(mark_ctx, value.backing);
}
/* mark-visit<fix-arr<nat64>> (generated) (generated) */
struct void_ mark_visit_418(struct mark_ctx* mark_ctx, struct fix_arr_0 value) {
	return mark_arr_419(mark_ctx, value.inner);
}
/* mark-arr<nat-64> (generated) (generated) */
struct void_ mark_arr_419(struct mark_ctx* mark_ctx, struct arr_3 a) {
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
				struct some_11 _matched0 = _2.as1;
				
				uint64_t t1;
				t1 = _matched0.value;
				
				struct timespec abstime2;
				abstime2 = to_timespec(t1);
				
				int32_t err3;
				err3 = pthread_cond_timedwait((&a->cond), (&a->mutex), (&abstime2));
				
				int32_t _4 = ETIMEDOUT();
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
/* main fut<nat64>(args arr<str>) */
struct fut_0* main_0(struct ctx* ctx, struct arr_2 args) {
	struct opt_13 _0 = parse_named_args_0(ctx, args, (struct arr_2) {4, constantarr_2_0});uint64_t _1;
	
	switch (_0.kind) {
		case 0: {
			print_help(ctx);
			_1 = 1u;
			break;
		}
		case 1: {
			struct some_13 _matched0 = _0.as1;
			
			struct arr_8 values1;
			values1 = _matched0.value;
			
			struct opt_12 print_tests_strs2;
			print_tests_strs2 = subscript_66(ctx, values1, 0u);
			
			struct opt_12 overwrite_output_strs3;
			overwrite_output_strs3 = subscript_66(ctx, values1, 1u);
			
			struct opt_12 max_failures_strs4;
			max_failures_strs4 = subscript_66(ctx, values1, 2u);
			
			struct opt_12 match_test_strs5;
			match_test_strs5 = subscript_66(ctx, values1, 3u);
			
			uint8_t should_print_tests6;
			uint8_t _2 = is_empty_10(print_tests_strs2);
			should_print_tests6 = _not(_2);
			
			uint8_t overwrite_output9;
			struct opt_12 _3 = overwrite_output_strs3;
			switch (_3.kind) {
				case 0: {
					overwrite_output9 = 0;
					break;
				}
				case 1: {
					struct some_12 _matched7 = _3.as1;
					
					struct arr_2 strs8;
					strs8 = _matched7.value;
					
					uint8_t _4 = is_empty_7(strs8);
					assert_0(ctx, _4);
					overwrite_output9 = 1;
					break;
				}
				default:
					
			overwrite_output9 = 0;;
			}
			
			uint64_t max_failures12;
			struct opt_12 _5 = max_failures_strs4;
			switch (_5.kind) {
				case 0: {
					max_failures12 = 100u;
					break;
				}
				case 1: {
					struct some_12 _matched10 = _5.as1;
					
					struct arr_2 strs11;
					strs11 = _matched10.value;
					
					assert_0(ctx, (strs11.size == 1u));
					struct str _6 = subscript_26(ctx, strs11, 0u);
					struct opt_11 _7 = parse_nat(ctx, _6);
					max_failures12 = force_0(ctx, _7);
					break;
				}
				default:
					
			max_failures12 = 0;;
			}
			
			struct str match_test15;
			struct opt_12 _8 = match_test_strs5;
			switch (_8.kind) {
				case 0: {
					match_test15 = (struct str) {{0u, NULL}};
					break;
				}
				case 1: {
					struct some_12 _matched13 = _8.as1;
					
					struct arr_2 strs14;
					strs14 = _matched13.value;
					
					assert_0(ctx, (strs14.size == 1u));
					match_test15 = subscript_26(ctx, strs14, 0u);
					break;
				}
				default:
					
			match_test15 = (struct str) {(struct arr_0) {0, NULL}};;
			}
			
			struct test_options* temp0;
			uint8_t* _9 = alloc(ctx, sizeof(struct test_options));
			temp0 = ((struct test_options*) _9);
			
			*temp0 = (struct test_options) {should_print_tests6, overwrite_output9, max_failures12, match_test15};
			_1 = do_test(ctx, temp0);
			break;
		}
		default:
			
	_1 = 0;;
	}
	return resolved_1(ctx, _1);
}
/* resolved<nat64> fut<nat64>(value nat64) */
struct fut_0* resolved_1(struct ctx* ctx, uint64_t value) {
	struct fut_0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct fut_0));
	temp0 = ((struct fut_0*) _0);
	
	struct lock _1 = lock_by_val();
	*temp0 = (struct fut_0) {_1, (struct fut_state_0) {2, .as2 = (struct fut_state_resolved_0) {value}}};
	return temp0;
}
/* parse-named-args opt<arr<opt<arr<str>>>>(args arr<str>, arg-names arr<str>) */
struct opt_13 parse_named_args_0(struct ctx* ctx, struct arr_2 args, struct arr_2 arg_names) {
	struct parsed_command* parsed0;
	parsed0 = parse_command_dynamic(ctx, args);
	
	uint8_t _0 = is_empty_7(parsed0->nameless);
	assert_1(ctx, _0, (struct str) {{26, constantarr_0_17}});
	uint8_t _1 = is_empty_7(parsed0->after);
	assert_0(ctx, _1);
	struct mut_arr_3* values1;
	values1 = fill_mut_arr(ctx, arg_names.size, (struct opt_12) {0, .as0 = (struct none) {}});
	
	struct cell_3* help2;
	struct cell_3* temp0;
	uint8_t* _2 = alloc(ctx, sizeof(struct cell_3));
	temp0 = ((struct cell_3*) _2);
	
	*temp0 = (struct cell_3) {0};
	help2 = temp0;
	
	struct parse_named_args_0__lambda0* temp1;
	uint8_t* _3 = alloc(ctx, sizeof(struct parse_named_args_0__lambda0));
	temp1 = ((struct parse_named_args_0__lambda0*) _3);
	
	*temp1 = (struct parse_named_args_0__lambda0) {arg_names, values1, help2};
	each_4(ctx, parsed0->named, (struct fun_act2_3) {1, .as1 = temp1});
	uint8_t _4 = _times_14(help2);
	uint8_t _5 = _not(_4);
	if (_5) {
		struct arr_8 _6 = move_to_arr__e_1(values1);
		return (struct opt_13) {1, .as1 = (struct some_13) {_6}};
	} else {
		return (struct opt_13) {0, .as0 = (struct none) {}};
	}
}
/* parse-command-dynamic parsed-command(args arr<str>) */
struct parsed_command* parse_command_dynamic(struct ctx* ctx, struct arr_2 args) {
	struct opt_11 _0 = find_index_0(ctx, args, (struct fun_act1_8) {0, .as0 = (struct void_) {}});
	switch (_0.kind) {
		case 0: {
			struct parsed_command* temp0;
			uint8_t* _1 = alloc(ctx, sizeof(struct parsed_command));
			temp0 = ((struct parsed_command*) _1);
			
			struct dict_0 _2 = dict_0(ctx, (struct arr_10) {0u, NULL});
			*temp0 = (struct parsed_command) {args, _2, (struct arr_2) {0u, NULL}};
			return temp0;
		}
		case 1: {
			struct some_11 _matched0 = _0.as1;
			
			uint64_t first_named_arg_index1;
			first_named_arg_index1 = _matched0.value;
			
			struct arr_2 nameless2;
			struct range _3 = _range(ctx, 0u, first_named_arg_index1);
			nameless2 = subscript_45(ctx, args, _3);
			
			struct arr_2 rest3;
			struct range _4 = _range(ctx, first_named_arg_index1, args.size);
			rest3 = subscript_45(ctx, args, _4);
			
			struct opt_11 _5 = find_index_0(ctx, rest3, (struct fun_act1_8) {1, .as1 = (struct void_) {}});
			switch (_5.kind) {
				case 0: {
					struct parsed_command* temp1;
					uint8_t* _6 = alloc(ctx, sizeof(struct parsed_command));
					temp1 = ((struct parsed_command*) _6);
					
					struct dict_0 _7 = parse_named_args_1(ctx, rest3);
					*temp1 = (struct parsed_command) {nameless2, _7, (struct arr_2) {0u, NULL}};
					return temp1;
				}
				case 1: {
					struct some_11 _matched4 = _5.as1;
					
					uint64_t sep_index5;
					sep_index5 = _matched4.value;
					
					struct dict_0 named_args6;
					struct range _8 = _range(ctx, 0u, sep_index5);
					struct arr_2 _9 = subscript_45(ctx, rest3, _8);
					named_args6 = parse_named_args_1(ctx, _9);
					
					struct parsed_command* temp2;
					uint8_t* _10 = alloc(ctx, sizeof(struct parsed_command));
					temp2 = ((struct parsed_command*) _10);
					
					uint64_t _11 = _plus_3(ctx, sep_index5, 1u);
					struct range _12 = _range(ctx, _11, rest3.size);
					struct arr_2 _13 = subscript_45(ctx, rest3, _12);
					*temp2 = (struct parsed_command) {nameless2, named_args6, _13};
					return temp2;
				}
				default:
					
			return NULL;;
			}
		}
		default:
			
	return NULL;;
	}
}
/* find-index<str> opt<nat64>(a arr<str>, f fun-act1<bool, str>) */
struct opt_11 find_index_0(struct ctx* ctx, struct arr_2 a, struct fun_act1_8 f) {
	return find_index_recur_0(ctx, a, 0u, f);
}
/* find-index-recur<a> opt<nat64>(a arr<str>, index nat64, f fun-act1<bool, str>) */
struct opt_11 find_index_recur_0(struct ctx* ctx, struct arr_2 a, uint64_t index, struct fun_act1_8 f) {
	top:;
	uint8_t _0 = (index == a.size);
	if (_0) {
		return (struct opt_11) {0, .as0 = (struct none) {}};
	} else {
		struct str _1 = subscript_26(ctx, a, index);
		uint8_t _2 = subscript_25(ctx, f, _1);
		if (_2) {
			return (struct opt_11) {1, .as1 = (struct some_11) {index}};
		} else {
			uint64_t _3 = _plus_3(ctx, index, 1u);
			a = a;
			index = _3;
			f = f;
			goto top;
		}
	}
}
/* subscript<bool, a> bool(a fun-act1<bool, str>, p0 str) */
uint8_t subscript_25(struct ctx* ctx, struct fun_act1_8 a, struct str p0) {
	return call_w_ctx_448(a, ctx, p0);
}
/* call-w-ctx<bool, str> (generated) (generated) */
uint8_t call_w_ctx_448(struct fun_act1_8 a, struct ctx* ctx, struct str p0) {
	struct fun_act1_8 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return parse_command_dynamic__lambda0(ctx, closure0, p0);
		}
		case 1: {
			struct void_ closure1 = _0.as1;
			
			return parse_command_dynamic__lambda1(ctx, closure1, p0);
		}
		case 2: {
			struct void_ closure2 = _0.as2;
			
			return parse_named_args_recur__lambda0(ctx, closure2, p0);
		}
		case 3: {
			struct void_ closure3 = _0.as3;
			
			return each_child_recursive_0__lambda0(ctx, closure3, p0);
		}
		case 4: {
			struct excluded_from_lint__lambda0* closure4 = _0.as4;
			
			return excluded_from_lint__lambda0(ctx, closure4, p0);
		}
		case 5: {
			struct void_ closure5 = _0.as5;
			
			return list_lintable_files__lambda0(ctx, closure5, p0);
		}
		default:
			
	return 0;;
	}
}
/* subscript<a> str(a arr<str>, index nat64) */
struct str subscript_26(struct ctx* ctx, struct arr_2 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	return unsafe_at_3(a, index);
}
/* unsafe-at<a> str(a arr<str>, index nat64) */
struct str unsafe_at_3(struct arr_2 a, uint64_t index) {
	return subscript_27(a.begin_ptr, index);
}
/* subscript<a> str(a const-ptr<str>, n nat64) */
struct str subscript_27(struct str* a, uint64_t n) {
	struct str* _0 = _plus_8(a, n);
	return _times_10(_0);
}
/* *<a> str(a const-ptr<str>) */
struct str _times_10(struct str* a) {
	return (*((struct str*) a));
}
/* +<a> const-ptr<str>(a const-ptr<str>, offset nat64) */
struct str* _plus_8(struct str* a, uint64_t offset) {
	return ((struct str*) (((struct str*) a) + offset));
}
/* starts-with bool(a str, b str) */
uint8_t starts_with_0(struct ctx* ctx, struct str a, struct str b) {
	return starts_with_1(ctx, a.chars, b.chars);
}
/* == bool(a arr<char>, b arr<char>) */
uint8_t _equal_4(struct arr_0 a, struct arr_0 b) {
	return arr_equal(a, b);
}
/* arr-equal<char> bool(a arr<char>, b arr<char>) */
uint8_t arr_equal(struct arr_0 a, struct arr_0 b) {
	char* _0 = end_ptr_0(a);
	char* _1 = end_ptr_0(b);
	return equal_recur(a.begin_ptr, _0, b.begin_ptr, _1);
}
/* equal-recur<a> bool(a const-ptr<char>, a-end const-ptr<char>, b const-ptr<char>, b-end const-ptr<char>) */
uint8_t equal_recur(char* a, char* a_end, char* b, char* b_end) {
	top:;
	uint8_t _0 = _equal_0(a, a_end);
	if (_0) {
		return _equal_0(b, b_end);
	} else {
		uint8_t _1 = _notEqual_2(b, b_end);uint8_t _2;
		
		if (_1) {
			char _3 = _times_0(a);
			char _4 = _times_0(b);
			_2 = _equal_3(_3, _4);
		} else {
			_2 = 0;
		}
		if (_2) {
			char* _5 = _plus_0(a, 1u);
			char* _6 = _plus_0(b, 1u);
			a = _5;
			a_end = a_end;
			b = _6;
			b_end = b_end;
			goto top;
		} else {
			return 0;
		}
	}
}
/* starts-with<char> bool(a arr<char>, start arr<char>) */
uint8_t starts_with_1(struct ctx* ctx, struct arr_0 a, struct arr_0 start) {
	uint8_t _0 = _greaterOrEqual(a.size, start.size);
	if (_0) {
		struct range _1 = _range(ctx, 0u, start.size);
		struct arr_0 _2 = subscript_4(ctx, a, _1);
		return _equal_4(_2, start);
	} else {
		return 0;
	}
}
/* parse-command-dynamic.lambda0 bool(arg str) */
uint8_t parse_command_dynamic__lambda0(struct ctx* ctx, struct void_ _closure, struct str arg) {
	return starts_with_0(ctx, arg, (struct str) {{2, constantarr_0_14}});
}
/* == bool(a str, b str) */
uint8_t _equal_5(struct str a, struct str b) {
	return arr_equal(a.chars, b.chars);
}
/* <=> comparison(a str, b str) */
struct comparison _compare_8(struct str a, struct str b) {
	return arr_compare(a.chars, b.chars);
}
/* <=> comparison(a char, b char) */
struct comparison _compare_9(char a, char b) {
	return _compare_10(((uint8_t) a), ((uint8_t) b));
}
/* <=> comparison(a nat8, b nat8) */
struct comparison _compare_10(uint8_t a, uint8_t b) {
	return cmp_1(a, b);
}
/* cmp<nat8> comparison(a nat8, b nat8) */
struct comparison cmp_1(uint8_t a, uint8_t b) {
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
/* arr-compare<char> comparison(a arr<char>, b arr<char>) */
struct comparison arr_compare(struct arr_0 a, struct arr_0 b) {
	char* _0 = end_ptr_0(a);
	char* _1 = end_ptr_0(b);
	return compare_recur(a.begin_ptr, _0, b.begin_ptr, _1);
}
/* compare-recur<a> comparison(a const-ptr<char>, a-end const-ptr<char>, b const-ptr<char>, b-end const-ptr<char>) */
struct comparison compare_recur(char* a, char* a_end, char* b, char* b_end) {
	top:;
	uint8_t _0 = _equal_0(a, a_end);
	if (_0) {
		uint8_t _1 = _equal_0(b, b_end);
		if (_1) {
			return (struct comparison) {1, .as1 = (struct equal) {}};
		} else {
			return (struct comparison) {0, .as0 = (struct less) {}};
		}
	} else {
		uint8_t _2 = _equal_0(b, b_end);
		if (_2) {
			return (struct comparison) {2, .as2 = (struct greater) {}};
		} else {
			char _3 = _times_0(a);
			char _4 = _times_0(b);
			struct comparison _5 = _compare_9(_3, _4);
			switch (_5.kind) {
				case 0: {
					return (struct comparison) {0, .as0 = (struct less) {}};
				}
				case 1: {
					char* _6 = _plus_0(a, 1u);
					char* _7 = _plus_0(b, 1u);
					a = _6;
					a_end = a_end;
					b = _7;
					b_end = b_end;
					goto top;
				}
				case 2: {
					return (struct comparison) {2, .as2 = (struct greater) {}};
				}
				default:
					
			return (struct comparison) {0};;
			}
		}
	}
}
/* hash-mix void(hasher hasher, a str) */
struct void_ hash_mix_0(struct ctx* ctx, struct hasher* hasher, struct str a) {
	struct hash_mix_0__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct hash_mix_0__lambda0));
	temp0 = ((struct hash_mix_0__lambda0*) _0);
	
	*temp0 = (struct hash_mix_0__lambda0) {hasher};
	return each_0(ctx, a.chars, (struct fun_act1_1) {1, .as1 = temp0});
}
/* hash-mix void(hasher hasher, a nat64) */
struct void_ hash_mix_1(struct ctx* ctx, struct hasher* hasher, uint64_t a) {
	return (hasher->cur = (hasher->cur + a), (struct void_) {});
}
/* hash-mix.lambda0 void(c char) */
struct void_ hash_mix_0__lambda0(struct ctx* ctx, struct hash_mix_0__lambda0* _closure, char c) {
	return hash_mix_1(ctx, _closure->hasher, ((uint64_t) ((uint8_t) c)));
}
/* dict<str, arr<str>> dict<str, arr<str>>(a arr<arrow<str, arr<str>>>) */
struct dict_0 dict_0(struct ctx* ctx, struct arr_10 a) {
	uint8_t _0 = _lessOrEqual_0(a.size, 4u);uint8_t _1;
	
	if (_0) {
		_1 = no_duplicate_keys_0(ctx, a);
	} else {
		_1 = 0;
	}
	if (_1) {
		return (struct dict_0) {(struct void_) {}, (struct node_0) {1, .as1 = (struct leaf_node_0) {a}}};
	} else {
		struct dict_0 _2 = dict_1(ctx);
		return fold_0(ctx, _2, a, (struct fun_act2_1) {0, .as0 = (struct void_) {}});
	}
}
/* no-duplicate-keys<k, v> bool(a arr<arrow<str, arr<str>>>) */
uint8_t no_duplicate_keys_0(struct ctx* ctx, struct arr_10 a) {
	top:;
	uint8_t _0 = _lessOrEqual_0(a.size, 1u);
	if (_0) {
		return 1;
	} else {
		struct str key0;
		struct arrow_0 _1 = subscript_28(ctx, a, 0u);
		key0 = _1.from;
		
		struct arr_10 _2 = tail_1(ctx, a);
		struct no_duplicate_keys_0__lambda0* temp0;
		uint8_t* _3 = alloc(ctx, sizeof(struct no_duplicate_keys_0__lambda0));
		temp0 = ((struct no_duplicate_keys_0__lambda0*) _3);
		
		*temp0 = (struct no_duplicate_keys_0__lambda0) {key0};
		uint8_t _4 = every_0(ctx, _2, (struct fun_act1_9) {0, .as0 = temp0});
		if (_4) {
			struct arr_10 _5 = tail_1(ctx, a);
			a = _5;
			goto top;
		} else {
			return 0;
		}
	}
}
/* subscript<arrow<k, v>> arrow<str, arr<str>>(a arr<arrow<str, arr<str>>>, index nat64) */
struct arrow_0 subscript_28(struct ctx* ctx, struct arr_10 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	return unsafe_at_4(a, index);
}
/* unsafe-at<a> arrow<str, arr<str>>(a arr<arrow<str, arr<str>>>, index nat64) */
struct arrow_0 unsafe_at_4(struct arr_10 a, uint64_t index) {
	return subscript_29(a.begin_ptr, index);
}
/* subscript<a> arrow<str, arr<str>>(a const-ptr<arrow<str, arr<str>>>, n nat64) */
struct arrow_0 subscript_29(struct arrow_0* a, uint64_t n) {
	struct arrow_0* _0 = _plus_9(a, n);
	return _times_11(_0);
}
/* *<a> arrow<str, arr<str>>(a const-ptr<arrow<str, arr<str>>>) */
struct arrow_0 _times_11(struct arrow_0* a) {
	return (*((struct arrow_0*) a));
}
/* +<a> const-ptr<arrow<str, arr<str>>>(a const-ptr<arrow<str, arr<str>>>, offset nat64) */
struct arrow_0* _plus_9(struct arrow_0* a, uint64_t offset) {
	return ((struct arrow_0*) (((struct arrow_0*) a) + offset));
}
/* every<arrow<k, v>> bool(a arr<arrow<str, arr<str>>>, f fun-act1<bool, arrow<str, arr<str>>>) */
uint8_t every_0(struct ctx* ctx, struct arr_10 a, struct fun_act1_9 f) {
	top:;
	uint8_t _0 = is_empty_5(a);
	if (_0) {
		return 1;
	} else {
		struct arrow_0 _1 = subscript_28(ctx, a, 0u);
		uint8_t _2 = subscript_30(ctx, f, _1);
		if (_2) {
			struct arr_10 _3 = tail_1(ctx, a);
			a = _3;
			f = f;
			goto top;
		} else {
			return 0;
		}
	}
}
/* is-empty<a> bool(a arr<arrow<str, arr<str>>>) */
uint8_t is_empty_5(struct arr_10 a) {
	return (a.size == 0u);
}
/* subscript<bool, a> bool(a fun-act1<bool, arrow<str, arr<str>>>, p0 arrow<str, arr<str>>) */
uint8_t subscript_30(struct ctx* ctx, struct fun_act1_9 a, struct arrow_0 p0) {
	return call_w_ctx_480(a, ctx, p0);
}
/* call-w-ctx<bool, arrow<str, arr<str>>> (generated) (generated) */
uint8_t call_w_ctx_480(struct fun_act1_9 a, struct ctx* ctx, struct arrow_0 p0) {
	struct fun_act1_9 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct no_duplicate_keys_0__lambda0* closure0 = _0.as0;
			
			return no_duplicate_keys_0__lambda0(ctx, closure0, p0);
		}
		case 1: {
			struct get_or_update_leaf_0__lambda0* closure1 = _0.as1;
			
			return get_or_update_leaf_0__lambda0(ctx, closure1, p0);
		}
		case 2: {
			struct update__e_0__lambda0* closure2 = _0.as2;
			
			return update__e_0__lambda0(ctx, closure2, p0);
		}
		default:
			
	return 0;;
	}
}
/* tail<a> arr<arrow<str, arr<str>>>(a arr<arrow<str, arr<str>>>) */
struct arr_10 tail_1(struct ctx* ctx, struct arr_10 a) {
	uint8_t _0 = is_empty_5(a);
	forbid(ctx, _0);
	struct range _1 = _range(ctx, 1u, a.size);
	return subscript_31(ctx, a, _1);
}
/* subscript<a> arr<arrow<str, arr<str>>>(a arr<arrow<str, arr<str>>>, range range<nat64>) */
struct arr_10 subscript_31(struct ctx* ctx, struct arr_10 a, struct range range) {
	uint8_t _0 = _lessOrEqual_0(range.high, a.size);
	assert_0(ctx, _0);
	struct arrow_0* _1 = _plus_9(a.begin_ptr, range.low);
	return (struct arr_10) {(range.high - range.low), _1};
}
/* !=<k> bool(a str, b str) */
uint8_t _notEqual_8(struct str a, struct str b) {
	uint8_t _0 = _equal_5(a, b);
	return _not(_0);
}
/* no-duplicate-keys<k, v>.lambda0 bool(it arrow<str, arr<str>>) */
uint8_t no_duplicate_keys_0__lambda0(struct ctx* ctx, struct no_duplicate_keys_0__lambda0* _closure, struct arrow_0 it) {
	return _notEqual_8(it.from, _closure->key);
}
/* fold<dict<k, v>, arrow<k, v>> dict<str, arr<str>>(acc dict<str, arr<str>>, a arr<arrow<str, arr<str>>>, f fun-act2<dict<str, arr<str>>, dict<str, arr<str>>, arrow<str, arr<str>>>) */
struct dict_0 fold_0(struct ctx* ctx, struct dict_0 acc, struct arr_10 a, struct fun_act2_1 f) {
	struct arrow_0* _0 = end_ptr_2(a);
	return fold_recur_0(ctx, acc, a.begin_ptr, _0, f);
}
/* fold-recur<a, b> dict<str, arr<str>>(acc dict<str, arr<str>>, cur const-ptr<arrow<str, arr<str>>>, end const-ptr<arrow<str, arr<str>>>, f fun-act2<dict<str, arr<str>>, dict<str, arr<str>>, arrow<str, arr<str>>>) */
struct dict_0 fold_recur_0(struct ctx* ctx, struct dict_0 acc, struct arrow_0* cur, struct arrow_0* end, struct fun_act2_1 f) {
	top:;
	uint8_t _0 = _equal_6(cur, end);
	if (_0) {
		return acc;
	} else {
		struct arrow_0 _1 = _times_11(cur);
		struct dict_0 _2 = subscript_32(ctx, f, acc, _1);
		struct arrow_0* _3 = _plus_9(cur, 1u);
		acc = _2;
		cur = _3;
		end = end;
		f = f;
		goto top;
	}
}
/* ==<b> bool(a const-ptr<arrow<str, arr<str>>>, b const-ptr<arrow<str, arr<str>>>) */
uint8_t _equal_6(struct arrow_0* a, struct arrow_0* b) {
	return (((struct arrow_0*) a) == ((struct arrow_0*) b));
}
/* subscript<a, a, b> dict<str, arr<str>>(a fun-act2<dict<str, arr<str>>, dict<str, arr<str>>, arrow<str, arr<str>>>, p0 dict<str, arr<str>>, p1 arrow<str, arr<str>>) */
struct dict_0 subscript_32(struct ctx* ctx, struct fun_act2_1 a, struct dict_0 p0, struct arrow_0 p1) {
	return call_w_ctx_489(a, ctx, p0, p1);
}
/* call-w-ctx<dict<str, arr<str>>, dict<str, arr<str>>, arrow<str, arr<str>>> (generated) (generated) */
struct dict_0 call_w_ctx_489(struct fun_act2_1 a, struct ctx* ctx, struct dict_0 p0, struct arrow_0 p1) {
	struct fun_act2_1 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return dict_0__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return (struct dict_0) {(struct void_) {}, (struct node_0) {0}};;
	}
}
/* end-ptr<b> const-ptr<arrow<str, arr<str>>>(a arr<arrow<str, arr<str>>>) */
struct arrow_0* end_ptr_2(struct arr_10 a) {
	return _plus_9(a.begin_ptr, a.size);
}
/* dict<k, v> dict<str, arr<str>>() */
struct dict_0 dict_1(struct ctx* ctx) {
	struct leaf_node_0 _0 = empty_leaf_node_0(ctx);
	return (struct dict_0) {(struct void_) {}, (struct node_0) {1, .as1 = _0}};
}
/* empty-leaf-node<k, v> leaf-node<str, arr<str>>() */
struct leaf_node_0 empty_leaf_node_0(struct ctx* ctx) {
	return (struct leaf_node_0) {(struct arr_10) {0u, NULL}};
}
/* ~<k, v> dict<str, arr<str>>(a dict<str, arr<str>>, pair arrow<str, arr<str>>) */
struct dict_0 _tilde_2(struct ctx* ctx, struct dict_0 a, struct arrow_0 pair) {
	struct get_or_update_result_0 res0;
	struct _tilde_2__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct _tilde_2__lambda0));
	temp0 = ((struct _tilde_2__lambda0*) _0);
	
	*temp0 = (struct _tilde_2__lambda0) {pair};
	res0 = get_or_update_0(ctx, a, pair.from, (struct fun_act1_10) {0, .as0 = temp0});
	
	struct opt_14 _1 = res0.new_node;
	switch (_1.kind) {
		case 0: {
			return a;
		}
		case 1: {
			struct some_14 _matched1 = _1.as1;
			
			struct node_0 node2;
			node2 = _matched1.value;
			
			return (struct dict_0) {(struct void_) {}, node2};
		}
		default:
			
	return (struct dict_0) {(struct void_) {}, (struct node_0) {0}};;
	}
}
/* get-or-update<k, v> get-or-update-result<str, arr<str>>(a dict<str, arr<str>>, key str, f fun-act1<get-or-update-action<arr<str>>, opt<arr<str>>>) */
struct get_or_update_result_0 get_or_update_0(struct ctx* ctx, struct dict_0 a, struct str key, struct fun_act1_10 f) {
	uint64_t hash0;
	hash0 = hash(ctx, key);
	
	struct node_0 _0 = a.root;
	switch (_0.kind) {
		case 0: {
			return get_or_update_recur_0(ctx, a.root, key, hash0, 0u, f);
		}
		case 1: {
			struct leaf_node_0 l1 = _0.as1;
			
			return get_or_update_leaf_0(ctx, l1, key, hash0, 0u, f);
		}
		default:
			
	return (struct get_or_update_result_0) {(struct opt_14) {0}, (struct opt_12) {0}};;
	}
}
/* hash<k> nat64(a str) */
uint64_t hash(struct ctx* ctx, struct str a) {
	struct hasher hasher0;
	hasher0 = (struct hasher) {0u};
	
	hash_mix_0(ctx, (&hasher0), a);
	return (&hasher0)->cur;
}
/* get-or-update-recur<k, v> get-or-update-result<str, arr<str>>(a node<str, arr<str>>, key str, remaining-hash nat64, hash-shift nat64, f fun-act1<get-or-update-action<arr<str>>, opt<arr<str>>>) */
struct get_or_update_result_0 get_or_update_recur_0(struct ctx* ctx, struct node_0 a, struct str key, uint64_t remaining_hash, uint64_t hash_shift, struct fun_act1_10 f) {
	struct node_0 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct inner_node_0 i0 = _0.as0;
			
			uint64_t which1;
			which1 = low_bits(ctx, remaining_hash);
			
			uint8_t _1 = _less_0(which1, i0.children.size);
			if (_1) {
				uint64_t next_hash2;
				next_hash2 = (remaining_hash >> 3u);
				
				struct get_or_update_result_0 child_res3;
				struct node_0 _2 = subscript_33(ctx, i0.children, which1);
				child_res3 = get_or_update_recur_0(ctx, _2, key, next_hash2, (hash_shift + 3u), f);
				
				struct opt_14 _3 = child_res3.new_node;
				switch (_3.kind) {
					case 0: {
						return child_res3;
					}
					case 1: {
						struct some_14 _matched4 = _3.as1;
						
						struct node_0 node5;
						node5 = _matched4.value;
						
						struct node_0 new_inner6;
						new_inner6 = update_child_0(ctx, i0, which1, node5);
						
						return (struct get_or_update_result_0) {(struct opt_14) {1, .as1 = (struct some_14) {new_inner6}}, child_res3.old_value};
					}
					default:
						
				return (struct get_or_update_result_0) {(struct opt_14) {0}, (struct opt_12) {0}};;
				}
			} else {
				struct get_or_update_action_0 _4 = subscript_39(ctx, f, (struct opt_12) {0, .as0 = (struct none) {}});
				switch (_4.kind) {
					case 0: {
						return (struct get_or_update_result_0) {(struct opt_14) {0, .as0 = (struct none) {}}, (struct opt_12) {0, .as0 = (struct none) {}}};
					}
					case 1: {
						return (struct get_or_update_result_0) {(struct opt_14) {0, .as0 = (struct none) {}}, (struct opt_12) {0, .as0 = (struct none) {}}};
					}
					case 2: {
						struct insert_0 ins7 = _4.as2;
						
						struct arrow_0 pair8;
						pair8 = _arrow_0(key, ins7.value);
						
						struct leaf_node_0 new_leaf9;
						struct arrow_0* temp0;
						uint8_t* _5 = alloc(ctx, (sizeof(struct arrow_0) * 1u));
						temp0 = ((struct arrow_0*) _5);
						
						*(temp0 + 0u) = pair8;
						new_leaf9 = (struct leaf_node_0) {(struct arr_10) {1u, temp0}};
						
						struct inner_node_0 new_node10;
						struct leaf_node_0 _6 = empty_leaf_node_0(ctx);
						struct arr_9 _7 = update_with_default_0(ctx, i0.children, which1, (struct node_0) {1, .as1 = new_leaf9}, (struct node_0) {1, .as1 = _6});
						new_node10 = (struct inner_node_0) {_7};
						
						return (struct get_or_update_result_0) {(struct opt_14) {1, .as1 = (struct some_14) {(struct node_0) {0, .as0 = new_node10}}}, (struct opt_12) {0, .as0 = (struct none) {}}};
					}
					default:
						
				return (struct get_or_update_result_0) {(struct opt_14) {0}, (struct opt_12) {0}};;
				}
			}
		}
		case 1: {
			struct leaf_node_0 l11 = _0.as1;
			
			return get_or_update_leaf_0(ctx, l11, key, remaining_hash, hash_shift, f);
		}
		default:
			
	return (struct get_or_update_result_0) {(struct opt_14) {0}, (struct opt_12) {0}};;
	}
}
/* low-bits nat64(a nat64) */
uint64_t low_bits(struct ctx* ctx, uint64_t a) {
	return (a & 7u);
}
/* subscript<node<k, v>> node<str, arr<str>>(a arr<node<str, arr<str>>>, index nat64) */
struct node_0 subscript_33(struct ctx* ctx, struct arr_9 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	return unsafe_at_5(a, index);
}
/* unsafe-at<a> node<str, arr<str>>(a arr<node<str, arr<str>>>, index nat64) */
struct node_0 unsafe_at_5(struct arr_9 a, uint64_t index) {
	return subscript_34(a.begin_ptr, index);
}
/* subscript<a> node<str, arr<str>>(a const-ptr<node<str, arr<str>>>, n nat64) */
struct node_0 subscript_34(struct node_0* a, uint64_t n) {
	struct node_0* _0 = _plus_10(a, n);
	return _times_12(_0);
}
/* *<a> node<str, arr<str>>(a const-ptr<node<str, arr<str>>>) */
struct node_0 _times_12(struct node_0* a) {
	return (*((struct node_0*) a));
}
/* +<a> const-ptr<node<str, arr<str>>>(a const-ptr<node<str, arr<str>>>, offset nat64) */
struct node_0* _plus_10(struct node_0* a, uint64_t offset) {
	return ((struct node_0*) (((struct node_0*) a) + offset));
}
/* update-child<k, v> node<str, arr<str>>(a inner-node<str, arr<str>>, which nat64, new-child node<str, arr<str>>) */
struct node_0 update_child_0(struct ctx* ctx, struct inner_node_0 a, uint64_t which, struct node_0 new_child) {
	struct opt_15 _0 = inner_node_to_leaf_0(ctx, a, which, new_child);
	switch (_0.kind) {
		case 0: {
			uint8_t _1 = node_is_empty_0(ctx, new_child);
			if (_1) {
				uint8_t _2 = (which == (a.children.size - 1u));
				if (_2) {
					struct arr_9 new_children0;
					new_children0 = rtail_0(ctx, a.children);
					
					uint8_t _3 = (new_children0.size == 1u);
					if (_3) {
						return subscript_33(ctx, new_children0, 0u);
					} else {
						return (struct node_0) {0, .as0 = (struct inner_node_0) {new_children0}};
					}
				} else {
					struct arr_9 new_children1;
					new_children1 = update_0(ctx, a.children, which, new_child);
					
					struct opt_14 _4 = find_only_non_empty_child_0(ctx, new_children1);
					switch (_4.kind) {
						case 0: {
							return (struct node_0) {0, .as0 = (struct inner_node_0) {new_children1}};
						}
						case 1: {
							struct some_14 _matched2 = _4.as1;
							
							struct node_0 child3;
							child3 = _matched2.value;
							
							return child3;
						}
						default:
							
					return (struct node_0) {0};;
					}
				}
			} else {
				struct arr_9 _5 = update_0(ctx, a.children, which, new_child);
				return (struct node_0) {0, .as0 = (struct inner_node_0) {_5}};
			}
		}
		case 1: {
			struct some_15 _matched4 = _0.as1;
			
			struct leaf_node_0 leaf5;
			leaf5 = _matched4.value;
			
			return (struct node_0) {1, .as1 = leaf5};
		}
		default:
			
	return (struct node_0) {0};;
	}
}
/* inner-node-to-leaf<k, v> opt<leaf-node<str, arr<str>>>(a inner-node<str, arr<str>>, which nat64, new-child node<str, arr<str>>) */
struct opt_15 inner_node_to_leaf_0(struct ctx* ctx, struct inner_node_0 a, uint64_t which, struct node_0 new_child) {
	uint64_t total_size0;
	struct inner_node_to_leaf_0__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct inner_node_to_leaf_0__lambda0));
	temp0 = ((struct inner_node_to_leaf_0__lambda0*) _0);
	
	*temp0 = (struct inner_node_to_leaf_0__lambda0) {which, new_child};
	total_size0 = fold_with_index_0(ctx, 0u, a.children, (struct fun_act3_0) {0, .as0 = temp0});
	
	uint64_t _1 = leaf_max_size(ctx);
	uint8_t _2 = _lessOrEqual_0(total_size0, _1);
	if (_2) {
		struct fix_arr_3 out1;
		out1 = uninitialized_fix_arr_1(ctx, total_size0);
		
		uint64_t end2;
		struct inner_node_to_leaf_0__lambda1* temp1;
		uint8_t* _3 = alloc(ctx, sizeof(struct inner_node_to_leaf_0__lambda1));
		temp1 = ((struct inner_node_to_leaf_0__lambda1*) _3);
		
		*temp1 = (struct inner_node_to_leaf_0__lambda1) {which, new_child, out1};
		end2 = fold_with_index_0(ctx, 0u, a.children, (struct fun_act3_0) {1, .as1 = temp1});
		
		uint64_t _4 = size_3(out1);
		assert_0(ctx, (end2 == _4));
		struct arr_10 _5 = cast_immutable_1(out1);
		return (struct opt_15) {1, .as1 = (struct some_15) {(struct leaf_node_0) {_5}}};
	} else {
		return (struct opt_15) {0, .as0 = (struct none) {}};
	}
}
/* fold-with-index<nat64, node<k, v>> nat64(acc nat64, a arr<node<str, arr<str>>>, f fun-act3<nat64, nat64, node<str, arr<str>>, nat64>) */
uint64_t fold_with_index_0(struct ctx* ctx, uint64_t acc, struct arr_9 a, struct fun_act3_0 f) {
	struct node_0* _0 = end_ptr_3(a);
	return fold_with_index_recur_0(ctx, acc, 0u, a.begin_ptr, _0, f);
}
/* fold-with-index-recur<a, b> nat64(acc nat64, index nat64, cur const-ptr<node<str, arr<str>>>, end const-ptr<node<str, arr<str>>>, f fun-act3<nat64, nat64, node<str, arr<str>>, nat64>) */
uint64_t fold_with_index_recur_0(struct ctx* ctx, uint64_t acc, uint64_t index, struct node_0* cur, struct node_0* end, struct fun_act3_0 f) {
	top:;
	uint8_t _0 = _equal_7(cur, end);
	if (_0) {
		return acc;
	} else {
		struct node_0 _1 = _times_12(cur);
		uint64_t _2 = subscript_35(ctx, f, acc, _1, index);
		uint64_t _3 = _plus_3(ctx, index, 1u);
		struct node_0* _4 = _plus_10(cur, 1u);
		acc = _2;
		index = _3;
		cur = _4;
		end = end;
		f = f;
		goto top;
	}
}
/* ==<b> bool(a const-ptr<node<str, arr<str>>>, b const-ptr<node<str, arr<str>>>) */
uint8_t _equal_7(struct node_0* a, struct node_0* b) {
	return (((struct node_0*) a) == ((struct node_0*) b));
}
/* subscript<a, a, b, nat64> nat64(a fun-act3<nat64, nat64, node<str, arr<str>>, nat64>, p0 nat64, p1 node<str, arr<str>>, p2 nat64) */
uint64_t subscript_35(struct ctx* ctx, struct fun_act3_0 a, uint64_t p0, struct node_0 p1, uint64_t p2) {
	return call_w_ctx_509(a, ctx, p0, p1, p2);
}
/* call-w-ctx<nat-64, nat-64, node<str, arr<str>>, nat-64> (generated) (generated) */
uint64_t call_w_ctx_509(struct fun_act3_0 a, struct ctx* ctx, uint64_t p0, struct node_0 p1, uint64_t p2) {
	struct fun_act3_0 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct inner_node_to_leaf_0__lambda0* closure0 = _0.as0;
			
			return inner_node_to_leaf_0__lambda0(ctx, closure0, p0, p1, p2);
		}
		case 1: {
			struct inner_node_to_leaf_0__lambda1* closure1 = _0.as1;
			
			return inner_node_to_leaf_0__lambda1(ctx, closure1, p0, p1, p2);
		}
		default:
			
	return 0;;
	}
}
/* end-ptr<b> const-ptr<node<str, arr<str>>>(a arr<node<str, arr<str>>>) */
struct node_0* end_ptr_3(struct arr_9 a) {
	return _plus_10(a.begin_ptr, a.size);
}
/* inner-node-to-leaf<k, v>.lambda0 nat64(cur nat64, child node<str, arr<str>>, child-index nat64) */
uint64_t inner_node_to_leaf_0__lambda0(struct ctx* ctx, struct inner_node_to_leaf_0__lambda0* _closure, uint64_t cur, struct node_0 child, uint64_t child_index) {
	struct node_0 new_child_here0;
	uint8_t _0 = (child_index == _closure->which);
	if (_0) {
		new_child_here0 = _closure->new_child;
	} else {
		new_child_here0 = child;
	}
	
	struct node_0 _1 = new_child_here0;
	switch (_1.kind) {
		case 0: {
			return 99u;
		}
		case 1: {
			struct leaf_node_0 l1 = _1.as1;
			
			return (cur + l1.pairs.size);
		}
		default:
			
	return 0;;
	}
}
/* leaf-max-size nat64() */
uint64_t leaf_max_size(struct ctx* ctx) {
	return 8u;
}
/* uninitialized-fix-arr<arrow<k, v>> fix-arr<arrow<str, arr<str>>>(size nat64) */
struct fix_arr_3 uninitialized_fix_arr_1(struct ctx* ctx, uint64_t size) {
	struct arrow_0* _0 = alloc_uninitialized_2(ctx, size);
	return fix_arr_4(size, _0);
}
/* fix-arr<a> fix-arr<arrow<str, arr<str>>>(size nat64, begin-ptr mut-ptr<arrow<str, arr<str>>>) */
struct fix_arr_3 fix_arr_4(uint64_t size, struct arrow_0* begin_ptr) {
	return (struct fix_arr_3) {(struct void_) {}, (struct arr_10) {size, ((struct arrow_0*) begin_ptr)}};
}
/* alloc-uninitialized<a> mut-ptr<arrow<str, arr<str>>>(size nat64) */
struct arrow_0* alloc_uninitialized_2(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(struct arrow_0)));
	return ((struct arrow_0*) _0);
}
/* unreachable<nat64> nat64() */
uint64_t unreachable_0(struct ctx* ctx) {
	return throw_2(ctx, (struct str) {{21, constantarr_0_15}});
}
/* throw<a> nat64(message str) */
uint64_t throw_2(struct ctx* ctx, struct str message) {
	struct backtrace _0 = get_backtrace(ctx);
	return throw_3(ctx, (struct exception) {message, _0});
}
/* throw<a> nat64(e exception) */
uint64_t throw_3(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx0;
	exn_ctx0 = get_exception_ctx(ctx);
	
	uint8_t _0 = _notEqual_3(exn_ctx0->jmp_buf_ptr, NULL);
	hard_assert(_0);
	exn_ctx0->thrown_exception = e;
	int32_t _1 = number_to_throw(ctx);
	(longjmp(exn_ctx0->jmp_buf_ptr, _1), (struct void_) {});
	return hard_unreachable_2();
}
/* hard-unreachable<a> nat64() */
uint64_t hard_unreachable_2(void) {
	(abort(), (struct void_) {});
	return 0;
}
/* copy-from!<arrow<k, v>> void(dest fix-arr<arrow<str, arr<str>>>, source arr<arrow<str, arr<str>>>) */
struct void_ copy_from__e_0(struct ctx* ctx, struct fix_arr_3 dest, struct arr_10 source) {
	uint64_t _0 = size_3(dest);
	assert_0(ctx, (_0 == source.size));
	struct arrow_0* _1 = begin_ptr_4(dest);
	uint8_t* _2 = as_any_const_ptr_2(source.begin_ptr);
	uint64_t _3 = size_3(dest);
	uint8_t* _4 = memcpy(((uint8_t*) _1), _2, (_3 * sizeof(struct arrow_0)));
	return drop_0(_4);
}
/* size<a> nat64(a fix-arr<arrow<str, arr<str>>>) */
uint64_t size_3(struct fix_arr_3 a) {
	return a.inner.size;
}
/* begin-ptr<a> mut-ptr<arrow<str, arr<str>>>(a fix-arr<arrow<str, arr<str>>>) */
struct arrow_0* begin_ptr_4(struct fix_arr_3 a) {
	return ((struct arrow_0*) a.inner.begin_ptr);
}
/* as-any-const-ptr<const-ptr<a>> const-ptr<nat8>(ref const-ptr<arrow<str, arr<str>>>) */
uint8_t* as_any_const_ptr_2(struct arrow_0* ref) {
	return ((uint8_t*) ((uint8_t*) ref));
}
/* subscript<arrow<k, v>> fix-arr<arrow<str, arr<str>>>(a fix-arr<arrow<str, arr<str>>>, range range<nat64>) */
struct fix_arr_3 subscript_36(struct ctx* ctx, struct fix_arr_3 a, struct range range) {
	struct arr_10 _0 = subscript_31(ctx, a.inner, range);
	return (struct fix_arr_3) {(struct void_) {}, _0};
}
/* inner-node-to-leaf<k, v>.lambda1 nat64(out-index nat64, child node<str, arr<str>>, child-index nat64) */
uint64_t inner_node_to_leaf_0__lambda1(struct ctx* ctx, struct inner_node_to_leaf_0__lambda1* _closure, uint64_t out_index, struct node_0 child, uint64_t child_index) {
	struct node_0 new_child_here0;
	uint8_t _0 = (child_index == _closure->which);
	if (_0) {
		new_child_here0 = _closure->new_child;
	} else {
		new_child_here0 = child;
	}
	
	struct node_0 _1 = new_child_here0;
	switch (_1.kind) {
		case 0: {
			return unreachable_0(ctx);
		}
		case 1: {
			struct leaf_node_0 l1 = _1.as1;
			
			uint64_t new_out_index2;
			new_out_index2 = (out_index + l1.pairs.size);
			
			struct range _2 = _range(ctx, out_index, new_out_index2);
			struct fix_arr_3 _3 = subscript_36(ctx, _closure->out, _2);
			copy_from__e_0(ctx, _3, l1.pairs);
			return new_out_index2;
		}
		default:
			
	return 0;;
	}
}
/* cast-immutable<arrow<k, v>> arr<arrow<str, arr<str>>>(a fix-arr<arrow<str, arr<str>>>) */
struct arr_10 cast_immutable_1(struct fix_arr_3 a) {
	return a.inner;
}
/* node-is-empty<k, v> bool(a node<str, arr<str>>) */
uint8_t node_is_empty_0(struct ctx* ctx, struct node_0 a) {
	struct node_0 _0 = a;
	switch (_0.kind) {
		case 0: {
			return 0;
		}
		case 1: {
			struct leaf_node_0 l0 = _0.as1;
			
			return is_empty_5(l0.pairs);
		}
		default:
			
	return 0;;
	}
}
/* rtail<node<k, v>> arr<node<str, arr<str>>>(a arr<node<str, arr<str>>>) */
struct arr_9 rtail_0(struct ctx* ctx, struct arr_9 a) {
	uint8_t _0 = is_empty_6(a);
	forbid(ctx, _0);
	uint64_t _1 = _minus_5(ctx, a.size, 1u);
	struct range _2 = _range(ctx, 0u, _1);
	return subscript_37(ctx, a, _2);
}
/* is-empty<a> bool(a arr<node<str, arr<str>>>) */
uint8_t is_empty_6(struct arr_9 a) {
	return (a.size == 0u);
}
/* subscript<a> arr<node<str, arr<str>>>(a arr<node<str, arr<str>>>, range range<nat64>) */
struct arr_9 subscript_37(struct ctx* ctx, struct arr_9 a, struct range range) {
	uint8_t _0 = _lessOrEqual_0(range.high, a.size);
	assert_0(ctx, _0);
	struct node_0* _1 = _plus_10(a.begin_ptr, range.low);
	return (struct arr_9) {(range.high - range.low), _1};
}
/* - nat64(a nat64, b nat64) */
uint64_t _minus_5(struct ctx* ctx, uint64_t a, uint64_t b) {
	uint8_t _0 = _greaterOrEqual(a, b);
	assert_0(ctx, _0);
	return (a - b);
}
/* update<node<k, v>> arr<node<str, arr<str>>>(a arr<node<str, arr<str>>>, index nat64, new-value node<str, arr<str>>) */
struct arr_9 update_0(struct ctx* ctx, struct arr_9 a, uint64_t index, struct node_0 new_value) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	struct range _1 = _range(ctx, 0u, index);
	struct arr_9 _2 = subscript_37(ctx, a, _1);
	struct node_0* temp0;
	uint8_t* _3 = alloc(ctx, (sizeof(struct node_0) * 1u));
	temp0 = ((struct node_0*) _3);
	
	*(temp0 + 0u) = new_value;
	struct arr_9 _4 = _tilde_3(ctx, _2, (struct arr_9) {1u, temp0});
	uint64_t _5 = _plus_3(ctx, index, 1u);
	struct range _6 = _range(ctx, _5, a.size);
	struct arr_9 _7 = subscript_37(ctx, a, _6);
	return _tilde_3(ctx, _4, _7);
}
/* ~<a> arr<node<str, arr<str>>>(a arr<node<str, arr<str>>>, b arr<node<str, arr<str>>>) */
struct arr_9 _tilde_3(struct ctx* ctx, struct arr_9 a, struct arr_9 b) {
	uint64_t res_size0;
	res_size0 = (a.size + b.size);
	
	struct node_0* res1;
	res1 = alloc_uninitialized_3(ctx, res_size0);
	
	copy_data_from__e_2(ctx, res1, a.begin_ptr, a.size);
	copy_data_from__e_2(ctx, (res1 + a.size), b.begin_ptr, b.size);
	return (struct arr_9) {res_size0, ((struct node_0*) res1)};
}
/* alloc-uninitialized<a> mut-ptr<node<str, arr<str>>>(size nat64) */
struct node_0* alloc_uninitialized_3(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(struct node_0)));
	return ((struct node_0*) _0);
}
/* copy-data-from!<a> void(to mut-ptr<node<str, arr<str>>>, from const-ptr<node<str, arr<str>>>, len nat64) */
struct void_ copy_data_from__e_2(struct ctx* ctx, struct node_0* to, struct node_0* from, uint64_t len) {
	uint8_t* _0 = as_any_const_ptr_3(from);
	uint8_t* _1 = memcpy(((uint8_t*) to), _0, (len * sizeof(struct node_0)));
	return drop_0(_1);
}
/* as-any-const-ptr<const-ptr<a>> const-ptr<nat8>(ref const-ptr<node<str, arr<str>>>) */
uint8_t* as_any_const_ptr_3(struct node_0* ref) {
	return ((uint8_t*) ((uint8_t*) ref));
}
/* find-only-non-empty-child<k, v> opt<node<str, arr<str>>>(children arr<node<str, arr<str>>>) */
struct opt_14 find_only_non_empty_child_0(struct ctx* ctx, struct arr_9 children) {
	uint64_t first_non_empty_index0;
	struct opt_11 _0 = find_index_1(ctx, children, (struct fun_act1_11) {0, .as0 = (struct void_) {}});
	first_non_empty_index0 = force_0(ctx, _0);
	
	struct range _1 = _range(ctx, (first_non_empty_index0 + 1u), children.size);
	struct arr_9 _2 = subscript_37(ctx, children, _1);
	uint8_t _3 = every_1(ctx, _2, (struct fun_act1_11) {1, .as1 = (struct void_) {}});
	if (_3) {
		struct node_0 _4 = subscript_33(ctx, children, first_non_empty_index0);
		return (struct opt_14) {1, .as1 = (struct some_14) {_4}};
	} else {
		return (struct opt_14) {0, .as0 = (struct none) {}};
	}
}
/* force<nat64> nat64(a opt<nat64>) */
uint64_t force_0(struct ctx* ctx, struct opt_11 a) {
	return force_1(ctx, a, (struct str) {{27, constantarr_0_16}});
}
/* force<a> nat64(a opt<nat64>, message str) */
uint64_t force_1(struct ctx* ctx, struct opt_11 a, struct str message) {
	struct opt_11 _0 = a;
	switch (_0.kind) {
		case 0: {
			return throw_2(ctx, message);
		}
		case 1: {
			struct some_11 _matched0 = _0.as1;
			
			uint64_t v1;
			v1 = _matched0.value;
			
			return v1;
		}
		default:
			
	return 0;;
	}
}
/* find-index<node<k, v>> opt<nat64>(a arr<node<str, arr<str>>>, f fun-act1<bool, node<str, arr<str>>>) */
struct opt_11 find_index_1(struct ctx* ctx, struct arr_9 a, struct fun_act1_11 f) {
	return find_index_recur_1(ctx, a, 0u, f);
}
/* find-index-recur<a> opt<nat64>(a arr<node<str, arr<str>>>, index nat64, f fun-act1<bool, node<str, arr<str>>>) */
struct opt_11 find_index_recur_1(struct ctx* ctx, struct arr_9 a, uint64_t index, struct fun_act1_11 f) {
	top:;
	uint8_t _0 = (index == a.size);
	if (_0) {
		return (struct opt_11) {0, .as0 = (struct none) {}};
	} else {
		struct node_0 _1 = subscript_33(ctx, a, index);
		uint8_t _2 = subscript_38(ctx, f, _1);
		if (_2) {
			return (struct opt_11) {1, .as1 = (struct some_11) {index}};
		} else {
			uint64_t _3 = _plus_3(ctx, index, 1u);
			a = a;
			index = _3;
			f = f;
			goto top;
		}
	}
}
/* subscript<bool, a> bool(a fun-act1<bool, node<str, arr<str>>>, p0 node<str, arr<str>>) */
uint8_t subscript_38(struct ctx* ctx, struct fun_act1_11 a, struct node_0 p0) {
	return call_w_ctx_543(a, ctx, p0);
}
/* call-w-ctx<bool, node<str, arr<str>>> (generated) (generated) */
uint8_t call_w_ctx_543(struct fun_act1_11 a, struct ctx* ctx, struct node_0 p0) {
	struct fun_act1_11 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return find_only_non_empty_child_0__lambda0(ctx, closure0, p0);
		}
		case 1: {
			struct void_ closure1 = _0.as1;
			
			return find_only_non_empty_child_0__lambda1(ctx, closure1, p0);
		}
		default:
			
	return 0;;
	}
}
/* find-only-non-empty-child<k, v>.lambda0 bool(it node<str, arr<str>>) */
uint8_t find_only_non_empty_child_0__lambda0(struct ctx* ctx, struct void_ _closure, struct node_0 it) {
	uint8_t _0 = node_is_empty_0(ctx, it);
	return _not(_0);
}
/* every<node<k, v>> bool(a arr<node<str, arr<str>>>, f fun-act1<bool, node<str, arr<str>>>) */
uint8_t every_1(struct ctx* ctx, struct arr_9 a, struct fun_act1_11 f) {
	top:;
	uint8_t _0 = is_empty_6(a);
	if (_0) {
		return 1;
	} else {
		struct node_0 _1 = subscript_33(ctx, a, 0u);
		uint8_t _2 = subscript_38(ctx, f, _1);
		if (_2) {
			struct arr_9 _3 = tail_2(ctx, a);
			a = _3;
			f = f;
			goto top;
		} else {
			return 0;
		}
	}
}
/* tail<a> arr<node<str, arr<str>>>(a arr<node<str, arr<str>>>) */
struct arr_9 tail_2(struct ctx* ctx, struct arr_9 a) {
	uint8_t _0 = is_empty_6(a);
	forbid(ctx, _0);
	struct range _1 = _range(ctx, 1u, a.size);
	return subscript_37(ctx, a, _1);
}
/* find-only-non-empty-child<k, v>.lambda1 bool(it node<str, arr<str>>) */
uint8_t find_only_non_empty_child_0__lambda1(struct ctx* ctx, struct void_ _closure, struct node_0 it) {
	return node_is_empty_0(ctx, it);
}
/* subscript<get-or-update-action<v>, opt<v>> get-or-update-action<arr<str>>(a fun-act1<get-or-update-action<arr<str>>, opt<arr<str>>>, p0 opt<arr<str>>) */
struct get_or_update_action_0 subscript_39(struct ctx* ctx, struct fun_act1_10 a, struct opt_12 p0) {
	return call_w_ctx_549(a, ctx, p0);
}
/* call-w-ctx<get-or-update-action<arr<str>>, opt<arr<str>>> (generated) (generated) */
struct get_or_update_action_0 call_w_ctx_549(struct fun_act1_10 a, struct ctx* ctx, struct opt_12 p0) {
	struct fun_act1_10 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct _tilde_2__lambda0* closure0 = _0.as0;
			
			return _tilde_2__lambda0(ctx, closure0, p0);
		}
		default:
			
	return (struct get_or_update_action_0) {0};;
	}
}
/* -><k, v> arrow<str, arr<str>>(from str, to arr<str>) */
struct arrow_0 _arrow_0(struct str from, struct arr_2 to) {
	return (struct arrow_0) {from, to};
}
/* update-with-default<node<k, v>> arr<node<str, arr<str>>>(a arr<node<str, arr<str>>>, index nat64, new-value node<str, arr<str>>, default node<str, arr<str>>) */
struct arr_9 update_with_default_0(struct ctx* ctx, struct arr_9 a, uint64_t index, struct node_0 new_value, struct node_0 _default) {
	uint8_t _0 = _less_0(index, a.size);
	if (_0) {
		return update_0(ctx, a, index, new_value);
	} else {
		uint64_t _1 = _plus_3(ctx, index, 1u);
		struct update_with_default_0__lambda0* temp0;
		uint8_t* _2 = alloc(ctx, sizeof(struct update_with_default_0__lambda0));
		temp0 = ((struct update_with_default_0__lambda0*) _2);
		
		*temp0 = (struct update_with_default_0__lambda0) {a, index, new_value, _default};
		return make_arr_1(ctx, _1, (struct fun_act1_12) {0, .as0 = temp0});
	}
}
/* make-arr<a> arr<node<str, arr<str>>>(size nat64, f fun-act1<node<str, arr<str>>, nat64>) */
struct arr_9 make_arr_1(struct ctx* ctx, uint64_t size, struct fun_act1_12 f) {
	struct node_0* res0;
	res0 = alloc_uninitialized_3(ctx, size);
	
	fill_ptr_range_1(ctx, res0, size, f);
	return (struct arr_9) {size, ((struct node_0*) res0)};
}
/* fill-ptr-range<a> void(begin mut-ptr<node<str, arr<str>>>, size nat64, f fun-act1<node<str, arr<str>>, nat64>) */
struct void_ fill_ptr_range_1(struct ctx* ctx, struct node_0* begin, uint64_t size, struct fun_act1_12 f) {
	return fill_ptr_range_recur_1(ctx, begin, 0u, size, f);
}
/* fill-ptr-range-recur<a> void(begin mut-ptr<node<str, arr<str>>>, i nat64, size nat64, f fun-act1<node<str, arr<str>>, nat64>) */
struct void_ fill_ptr_range_recur_1(struct ctx* ctx, struct node_0* begin, uint64_t i, uint64_t size, struct fun_act1_12 f) {
	top:;
	uint8_t _0 = _notEqual_5(i, size);
	if (_0) {
		struct node_0 _1 = subscript_40(ctx, f, i);
		set_subscript_4(begin, i, _1);
		begin = begin;
		i = (i + 1u);
		size = size;
		f = f;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* set-subscript<a> void(a mut-ptr<node<str, arr<str>>>, n nat64, value node<str, arr<str>>) */
struct void_ set_subscript_4(struct node_0* a, uint64_t n, struct node_0 value) {
	return (*(a + n) = value, (struct void_) {});
}
/* subscript<a, nat64> node<str, arr<str>>(a fun-act1<node<str, arr<str>>, nat64>, p0 nat64) */
struct node_0 subscript_40(struct ctx* ctx, struct fun_act1_12 a, uint64_t p0) {
	return call_w_ctx_557(a, ctx, p0);
}
/* call-w-ctx<node<str, arr<str>>, nat-64> (generated) (generated) */
struct node_0 call_w_ctx_557(struct fun_act1_12 a, struct ctx* ctx, uint64_t p0) {
	struct fun_act1_12 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct update_with_default_0__lambda0* closure0 = _0.as0;
			
			return update_with_default_0__lambda0(ctx, closure0, p0);
		}
		case 1: {
			struct fill_fix_arr_0__lambda0* closure1 = _0.as1;
			
			return fill_fix_arr_0__lambda0(ctx, closure1, p0);
		}
		default:
			
	return (struct node_0) {0};;
	}
}
/* update-with-default<node<k, v>>.lambda0 node<str, arr<str>>(i nat64) */
struct node_0 update_with_default_0__lambda0(struct ctx* ctx, struct update_with_default_0__lambda0* _closure, uint64_t i) {
	uint8_t _0 = _less_0(i, _closure->a.size);
	if (_0) {
		return subscript_33(ctx, _closure->a, i);
	} else {
		uint8_t _1 = (i == _closure->index);
		if (_1) {
			return _closure->new_value;
		} else {
			return _closure->_default;
		}
	}
}
/* get-or-update-leaf<k, v> get-or-update-result<str, arr<str>>(a leaf-node<str, arr<str>>, key str, remaining-hash nat64, hash-shift nat64, f fun-act1<get-or-update-action<arr<str>>, opt<arr<str>>>) */
struct get_or_update_result_0 get_or_update_leaf_0(struct ctx* ctx, struct leaf_node_0 a, struct str key, uint64_t remaining_hash, uint64_t hash_shift, struct fun_act1_10 f) {
	struct get_or_update_leaf_0__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct get_or_update_leaf_0__lambda0));
	temp0 = ((struct get_or_update_leaf_0__lambda0*) _0);
	
	*temp0 = (struct get_or_update_leaf_0__lambda0) {key};
	struct opt_11 _1 = find_index_2(ctx, a.pairs, (struct fun_act1_9) {1, .as1 = temp0});
	switch (_1.kind) {
		case 0: {
			struct opt_14 new_node1;
			struct get_or_update_action_0 _2 = subscript_39(ctx, f, (struct opt_12) {0, .as0 = (struct none) {}});
			switch (_2.kind) {
				case 0: {
					new_node1 = (struct opt_14) {0, .as0 = (struct none) {}};
					break;
				}
				case 1: {
					new_node1 = (struct opt_14) {0, .as0 = (struct none) {}};
					break;
				}
				case 2: {
					struct insert_0 ins0 = _2.as2;
					
					uint64_t _3 = leaf_max_size(ctx);
					uint8_t _4 = _greaterOrEqual(a.pairs.size, _3);struct node_0 _5;
					
					if (_4) {
						uint8_t _6 = _greaterOrEqual(hash_shift, 64u);
						if (_6) {
							todo_0();
						} else {
							(struct void_) {};
						}
						struct inner_node_0 _7 = new_inner_node_0(ctx, a, key, ins0.value, remaining_hash, hash_shift);
						_5 = (struct node_0) {0, .as0 = _7};
					} else {
						struct arrow_0* temp1;
						uint8_t* _8 = alloc(ctx, (sizeof(struct arrow_0) * 1u));
						temp1 = ((struct arrow_0*) _8);
						
						struct arrow_0 _9 = _arrow_0(key, ins0.value);
						*(temp1 + 0u) = _9;
						struct arr_10 _10 = _tilde_4(ctx, a.pairs, (struct arr_10) {1u, temp1});
						_5 = (struct node_0) {1, .as1 = (struct leaf_node_0) {_10}};
					}
					new_node1 = (struct opt_14) {1, .as1 = (struct some_14) {_5}};
					break;
				}
				default:
					
			new_node1 = (struct opt_14) {0};;
			}
			
			return (struct get_or_update_result_0) {new_node1, (struct opt_12) {0, .as0 = (struct none) {}}};
		}
		case 1: {
			struct some_11 _matched2 = _1.as1;
			
			uint64_t index3;
			index3 = _matched2.value;
			
			struct arr_2 old_value4;
			struct arrow_0 _11 = subscript_28(ctx, a.pairs, index3);
			old_value4 = _11.to;
			
			struct opt_14 new_node6;
			struct get_or_update_action_0 _12 = subscript_39(ctx, f, (struct opt_12) {1, .as1 = (struct some_12) {old_value4}});
			switch (_12.kind) {
				case 0: {
					new_node6 = (struct opt_14) {0, .as0 = (struct none) {}};
					break;
				}
				case 1: {
					struct arr_10 _13 = remove_at_0(ctx, a.pairs, index3);
					new_node6 = (struct opt_14) {1, .as1 = (struct some_14) {(struct node_0) {1, .as1 = (struct leaf_node_0) {_13}}}};
					break;
				}
				case 2: {
					struct insert_0 ins5 = _12.as2;
					
					struct arrow_0 _14 = _arrow_0(key, ins5.value);
					struct arr_10 _15 = update_1(ctx, a.pairs, index3, _14);
					new_node6 = (struct opt_14) {1, .as1 = (struct some_14) {(struct node_0) {1, .as1 = (struct leaf_node_0) {_15}}}};
					break;
				}
				default:
					
			new_node6 = (struct opt_14) {0};;
			}
			
			return (struct get_or_update_result_0) {new_node6, (struct opt_12) {1, .as1 = (struct some_12) {old_value4}}};
		}
		default:
			
	return (struct get_or_update_result_0) {(struct opt_14) {0}, (struct opt_12) {0}};;
	}
}
/* find-index<arrow<k, v>> opt<nat64>(a arr<arrow<str, arr<str>>>, f fun-act1<bool, arrow<str, arr<str>>>) */
struct opt_11 find_index_2(struct ctx* ctx, struct arr_10 a, struct fun_act1_9 f) {
	return find_index_recur_2(ctx, a, 0u, f);
}
/* find-index-recur<a> opt<nat64>(a arr<arrow<str, arr<str>>>, index nat64, f fun-act1<bool, arrow<str, arr<str>>>) */
struct opt_11 find_index_recur_2(struct ctx* ctx, struct arr_10 a, uint64_t index, struct fun_act1_9 f) {
	top:;
	uint8_t _0 = (index == a.size);
	if (_0) {
		return (struct opt_11) {0, .as0 = (struct none) {}};
	} else {
		struct arrow_0 _1 = subscript_28(ctx, a, index);
		uint8_t _2 = subscript_30(ctx, f, _1);
		if (_2) {
			return (struct opt_11) {1, .as1 = (struct some_11) {index}};
		} else {
			uint64_t _3 = _plus_3(ctx, index, 1u);
			a = a;
			index = _3;
			f = f;
			goto top;
		}
	}
}
/* get-or-update-leaf<k, v>.lambda0 bool(it arrow<str, arr<str>>) */
uint8_t get_or_update_leaf_0__lambda0(struct ctx* ctx, struct get_or_update_leaf_0__lambda0* _closure, struct arrow_0 it) {
	return _equal_5(it.from, _closure->key);
}
/* new-inner-node<k, v> inner-node<str, arr<str>>(a leaf-node<str, arr<str>>, key str, value arr<str>, hash nat64, hash-shift nat64) */
struct inner_node_0 new_inner_node_0(struct ctx* ctx, struct leaf_node_0 a, struct str key, struct arr_2 value, uint64_t hash, uint64_t hash_shift) {
	uint64_t key_hash0;
	key_hash0 = low_bits(ctx, hash);
	
	uint64_t max_hash1;
	struct new_inner_node_0__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct new_inner_node_0__lambda0));
	temp0 = ((struct new_inner_node_0__lambda0*) _0);
	
	*temp0 = (struct new_inner_node_0__lambda0) {hash_shift};
	max_hash1 = fold_1(ctx, key_hash0, a.pairs, (struct fun_act2_2) {0, .as0 = temp0});
	
	struct fix_arr_4 res2;
	struct leaf_node_0 _1 = empty_leaf_node_0(ctx);
	res2 = fill_fix_arr_0(ctx, (max_hash1 + 1u), (struct node_0) {1, .as1 = _1});
	
	struct arrow_0* temp1;
	uint8_t* _2 = alloc(ctx, (sizeof(struct arrow_0) * 1u));
	temp1 = ((struct arrow_0*) _2);
	
	struct arrow_0 _3 = _arrow_0(key, value);
	*(temp1 + 0u) = _3;
	set_subscript_5(ctx, res2, key_hash0, (struct node_0) {1, .as1 = (struct leaf_node_0) {(struct arr_10) {1u, temp1}}});
	struct new_inner_node_0__lambda1* temp2;
	uint8_t* _4 = alloc(ctx, sizeof(struct new_inner_node_0__lambda1));
	temp2 = ((struct new_inner_node_0__lambda1*) _4);
	
	*temp2 = (struct new_inner_node_0__lambda1) {hash_shift, res2};
	each_2(ctx, a.pairs, (struct fun_act1_13) {0, .as0 = temp2});
	struct arr_9 _5 = cast_immutable_2(res2);
	return (struct inner_node_0) {_5};
}
/* fold<nat64, arrow<k, v>> nat64(acc nat64, a arr<arrow<str, arr<str>>>, f fun-act2<nat64, nat64, arrow<str, arr<str>>>) */
uint64_t fold_1(struct ctx* ctx, uint64_t acc, struct arr_10 a, struct fun_act2_2 f) {
	struct arrow_0* _0 = end_ptr_2(a);
	return fold_recur_1(ctx, acc, a.begin_ptr, _0, f);
}
/* fold-recur<a, b> nat64(acc nat64, cur const-ptr<arrow<str, arr<str>>>, end const-ptr<arrow<str, arr<str>>>, f fun-act2<nat64, nat64, arrow<str, arr<str>>>) */
uint64_t fold_recur_1(struct ctx* ctx, uint64_t acc, struct arrow_0* cur, struct arrow_0* end, struct fun_act2_2 f) {
	top:;
	uint8_t _0 = _equal_6(cur, end);
	if (_0) {
		return acc;
	} else {
		struct arrow_0 _1 = _times_11(cur);
		uint64_t _2 = subscript_41(ctx, f, acc, _1);
		struct arrow_0* _3 = _plus_9(cur, 1u);
		acc = _2;
		cur = _3;
		end = end;
		f = f;
		goto top;
	}
}
/* subscript<a, a, b> nat64(a fun-act2<nat64, nat64, arrow<str, arr<str>>>, p0 nat64, p1 arrow<str, arr<str>>) */
uint64_t subscript_41(struct ctx* ctx, struct fun_act2_2 a, uint64_t p0, struct arrow_0 p1) {
	return call_w_ctx_567(a, ctx, p0, p1);
}
/* call-w-ctx<nat-64, nat-64, arrow<str, arr<str>>> (generated) (generated) */
uint64_t call_w_ctx_567(struct fun_act2_2 a, struct ctx* ctx, uint64_t p0, struct arrow_0 p1) {
	struct fun_act2_2 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct new_inner_node_0__lambda0* closure0 = _0.as0;
			
			return new_inner_node_0__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return 0;;
	}
}
/* max<nat64> nat64(a nat64, b nat64) */
uint64_t max(uint64_t a, uint64_t b) {
	uint8_t _0 = _less_0(a, b);
	if (_0) {
		return b;
	} else {
		return a;
	}
}
/* new-inner-node<k, v>.lambda0 nat64(cur nat64, pair arrow<str, arr<str>>) */
uint64_t new_inner_node_0__lambda0(struct ctx* ctx, struct new_inner_node_0__lambda0* _closure, uint64_t cur, struct arrow_0 pair) {
	uint64_t _0 = hash(ctx, pair.from);
	uint64_t _1 = low_bits(ctx, (_0 >> _closure->hash_shift));
	return max(cur, _1);
}
/* fill-fix-arr<node<k, v>> fix-arr<node<str, arr<str>>>(size nat64, value node<str, arr<str>>) */
struct fix_arr_4 fill_fix_arr_0(struct ctx* ctx, uint64_t size, struct node_0 value) {
	struct fill_fix_arr_0__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct fill_fix_arr_0__lambda0));
	temp0 = ((struct fill_fix_arr_0__lambda0*) _0);
	
	*temp0 = (struct fill_fix_arr_0__lambda0) {value};
	return make_fix_arr_0(ctx, size, (struct fun_act1_12) {1, .as1 = temp0});
}
/* make-fix-arr<a> fix-arr<node<str, arr<str>>>(size nat64, f fun-act1<node<str, arr<str>>, nat64>) */
struct fix_arr_4 make_fix_arr_0(struct ctx* ctx, uint64_t size, struct fun_act1_12 f) {
	struct fix_arr_4 res0;
	res0 = uninitialized_fix_arr_2(ctx, size);
	
	struct node_0* _0 = begin_ptr_5(res0);
	fill_ptr_range_1(ctx, _0, size, f);
	return res0;
}
/* uninitialized-fix-arr<a> fix-arr<node<str, arr<str>>>(size nat64) */
struct fix_arr_4 uninitialized_fix_arr_2(struct ctx* ctx, uint64_t size) {
	struct node_0* _0 = alloc_uninitialized_3(ctx, size);
	return fix_arr_5(size, _0);
}
/* fix-arr<a> fix-arr<node<str, arr<str>>>(size nat64, begin-ptr mut-ptr<node<str, arr<str>>>) */
struct fix_arr_4 fix_arr_5(uint64_t size, struct node_0* begin_ptr) {
	return (struct fix_arr_4) {(struct void_) {}, (struct arr_9) {size, ((struct node_0*) begin_ptr)}};
}
/* begin-ptr<a> mut-ptr<node<str, arr<str>>>(a fix-arr<node<str, arr<str>>>) */
struct node_0* begin_ptr_5(struct fix_arr_4 a) {
	return ((struct node_0*) a.inner.begin_ptr);
}
/* fill-fix-arr<node<k, v>>.lambda0 node<str, arr<str>>(ignore nat64) */
struct node_0 fill_fix_arr_0__lambda0(struct ctx* ctx, struct fill_fix_arr_0__lambda0* _closure, uint64_t ignore) {
	return _closure->value;
}
/* set-subscript<node<k, v>> void(a fix-arr<node<str, arr<str>>>, index nat64, value node<str, arr<str>>) */
struct void_ set_subscript_5(struct ctx* ctx, struct fix_arr_4 a, uint64_t index, struct node_0 value) {
	uint64_t _0 = size_4(a);
	uint8_t _1 = _less_0(index, _0);
	assert_0(ctx, _1);
	return unsafe_set_at__e_0(ctx, a, index, value);
}
/* size<a> nat64(a fix-arr<node<str, arr<str>>>) */
uint64_t size_4(struct fix_arr_4 a) {
	return a.inner.size;
}
/* unsafe-set-at!<a> void(a fix-arr<node<str, arr<str>>>, index nat64, value node<str, arr<str>>) */
struct void_ unsafe_set_at__e_0(struct ctx* ctx, struct fix_arr_4 a, uint64_t index, struct node_0 value) {
	struct node_0* _0 = begin_ptr_5(a);
	return set_subscript_4(_0, index, value);
}
/* each<arrow<k, v>> void(a arr<arrow<str, arr<str>>>, f fun-act1<void, arrow<str, arr<str>>>) */
struct void_ each_2(struct ctx* ctx, struct arr_10 a, struct fun_act1_13 f) {
	struct arrow_0* _0 = end_ptr_2(a);
	return each_recur_2(ctx, a.begin_ptr, _0, f);
}
/* each-recur<a> void(cur const-ptr<arrow<str, arr<str>>>, end const-ptr<arrow<str, arr<str>>>, f fun-act1<void, arrow<str, arr<str>>>) */
struct void_ each_recur_2(struct ctx* ctx, struct arrow_0* cur, struct arrow_0* end, struct fun_act1_13 f) {
	top:;
	uint8_t _0 = _notEqual_9(cur, end);
	if (_0) {
		struct arrow_0 _1 = _times_11(cur);
		subscript_42(ctx, f, _1);
		struct arrow_0* _2 = _plus_9(cur, 1u);
		cur = _2;
		end = end;
		f = f;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* !=<const-ptr<a>> bool(a const-ptr<arrow<str, arr<str>>>, b const-ptr<arrow<str, arr<str>>>) */
uint8_t _notEqual_9(struct arrow_0* a, struct arrow_0* b) {
	uint8_t _0 = _equal_6(a, b);
	return _not(_0);
}
/* subscript<void, a> void(a fun-act1<void, arrow<str, arr<str>>>, p0 arrow<str, arr<str>>) */
struct void_ subscript_42(struct ctx* ctx, struct fun_act1_13 a, struct arrow_0 p0) {
	return call_w_ctx_583(a, ctx, p0);
}
/* call-w-ctx<void, arrow<str, arr<str>>> (generated) (generated) */
struct void_ call_w_ctx_583(struct fun_act1_13 a, struct ctx* ctx, struct arrow_0 p0) {
	struct fun_act1_13 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct new_inner_node_0__lambda1* closure0 = _0.as0;
			
			return new_inner_node_0__lambda1(ctx, closure0, p0);
		}
		case 1: {
			struct _concatEquals_4__lambda0* closure1 = _0.as1;
			
			return _concatEquals_4__lambda0(ctx, closure1, p0);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* subscript<node<k, v>> node<str, arr<str>>(a fix-arr<node<str, arr<str>>>, index nat64) */
struct node_0 subscript_43(struct ctx* ctx, struct fix_arr_4 a, uint64_t index) {
	uint64_t _0 = size_4(a);
	uint8_t _1 = _less_0(index, _0);
	assert_0(ctx, _1);
	return unsafe_at_6(ctx, a, index);
}
/* unsafe-at<a> node<str, arr<str>>(a fix-arr<node<str, arr<str>>>, index nat64) */
struct node_0 unsafe_at_6(struct ctx* ctx, struct fix_arr_4 a, uint64_t index) {
	struct node_0* _0 = begin_ptr_5(a);
	return subscript_44(_0, index);
}
/* subscript<a> node<str, arr<str>>(a mut-ptr<node<str, arr<str>>>, n nat64) */
struct node_0 subscript_44(struct node_0* a, uint64_t n) {
	return (*(a + n));
}
/* unreachable<node<k, v>> node<str, arr<str>>() */
struct node_0 unreachable_1(struct ctx* ctx) {
	return throw_4(ctx, (struct str) {{21, constantarr_0_15}});
}
/* throw<a> node<str, arr<str>>(message str) */
struct node_0 throw_4(struct ctx* ctx, struct str message) {
	struct backtrace _0 = get_backtrace(ctx);
	return throw_5(ctx, (struct exception) {message, _0});
}
/* throw<a> node<str, arr<str>>(e exception) */
struct node_0 throw_5(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx0;
	exn_ctx0 = get_exception_ctx(ctx);
	
	uint8_t _0 = _notEqual_3(exn_ctx0->jmp_buf_ptr, NULL);
	hard_assert(_0);
	exn_ctx0->thrown_exception = e;
	int32_t _1 = number_to_throw(ctx);
	(longjmp(exn_ctx0->jmp_buf_ptr, _1), (struct void_) {});
	return hard_unreachable_3();
}
/* hard-unreachable<a> node<str, arr<str>>() */
struct node_0 hard_unreachable_3(void) {
	(abort(), (struct void_) {});
	return (struct node_0) {0};
}
/* ~<arrow<k, v>> arr<arrow<str, arr<str>>>(a arr<arrow<str, arr<str>>>, b arr<arrow<str, arr<str>>>) */
struct arr_10 _tilde_4(struct ctx* ctx, struct arr_10 a, struct arr_10 b) {
	uint64_t res_size0;
	res_size0 = (a.size + b.size);
	
	struct arrow_0* res1;
	res1 = alloc_uninitialized_2(ctx, res_size0);
	
	copy_data_from__e_3(ctx, res1, a.begin_ptr, a.size);
	copy_data_from__e_3(ctx, (res1 + a.size), b.begin_ptr, b.size);
	return (struct arr_10) {res_size0, ((struct arrow_0*) res1)};
}
/* copy-data-from!<a> void(to mut-ptr<arrow<str, arr<str>>>, from const-ptr<arrow<str, arr<str>>>, len nat64) */
struct void_ copy_data_from__e_3(struct ctx* ctx, struct arrow_0* to, struct arrow_0* from, uint64_t len) {
	uint8_t* _0 = as_any_const_ptr_2(from);
	uint8_t* _1 = memcpy(((uint8_t*) to), _0, (len * sizeof(struct arrow_0)));
	return drop_0(_1);
}
/* new-inner-node<k, v>.lambda1 void(pair arrow<str, arr<str>>) */
struct void_ new_inner_node_0__lambda1(struct ctx* ctx, struct new_inner_node_0__lambda1* _closure, struct arrow_0 pair) {
	uint64_t x0;
	uint64_t _0 = hash(ctx, pair.from);
	x0 = low_bits(ctx, (_0 >> _closure->hash_shift));
	
	struct node_0 _1 = subscript_43(ctx, _closure->res, x0);struct node_0 _2;
	
	switch (_1.kind) {
		case 0: {
			_2 = unreachable_1(ctx);
			break;
		}
		case 1: {
			struct leaf_node_0 l1 = _1.as1;
			
			struct arrow_0* temp0;
			uint8_t* _3 = alloc(ctx, (sizeof(struct arrow_0) * 1u));
			temp0 = ((struct arrow_0*) _3);
			
			*(temp0 + 0u) = pair;
			struct arr_10 _4 = _tilde_4(ctx, l1.pairs, (struct arr_10) {1u, temp0});
			_2 = (struct node_0) {1, .as1 = (struct leaf_node_0) {_4}};
			break;
		}
		default:
			
	_2 = (struct node_0) {0};;
	}
	return set_subscript_5(ctx, _closure->res, x0, _2);
}
/* cast-immutable<node<k, v>> arr<node<str, arr<str>>>(a fix-arr<node<str, arr<str>>>) */
struct arr_9 cast_immutable_2(struct fix_arr_4 a) {
	return a.inner;
}
/* remove-at<arrow<k, v>> arr<arrow<str, arr<str>>>(a arr<arrow<str, arr<str>>>, index nat64) */
struct arr_10 remove_at_0(struct ctx* ctx, struct arr_10 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	struct range _1 = _range(ctx, 0u, index);
	struct arr_10 _2 = subscript_31(ctx, a, _1);
	uint64_t _3 = _plus_3(ctx, index, 1u);
	struct range _4 = _range(ctx, _3, a.size);
	struct arr_10 _5 = subscript_31(ctx, a, _4);
	return _tilde_4(ctx, _2, _5);
}
/* update<arrow<k, v>> arr<arrow<str, arr<str>>>(a arr<arrow<str, arr<str>>>, index nat64, new-value arrow<str, arr<str>>) */
struct arr_10 update_1(struct ctx* ctx, struct arr_10 a, uint64_t index, struct arrow_0 new_value) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	struct range _1 = _range(ctx, 0u, index);
	struct arr_10 _2 = subscript_31(ctx, a, _1);
	struct arrow_0* temp0;
	uint8_t* _3 = alloc(ctx, (sizeof(struct arrow_0) * 1u));
	temp0 = ((struct arrow_0*) _3);
	
	*(temp0 + 0u) = new_value;
	struct arr_10 _4 = _tilde_4(ctx, _2, (struct arr_10) {1u, temp0});
	uint64_t _5 = _plus_3(ctx, index, 1u);
	struct range _6 = _range(ctx, _5, a.size);
	struct arr_10 _7 = subscript_31(ctx, a, _6);
	return _tilde_4(ctx, _4, _7);
}
/* ~<k, v>.lambda0 get-or-update-action<arr<str>>(old-value opt<arr<str>>) */
struct get_or_update_action_0 _tilde_2__lambda0(struct ctx* ctx, struct _tilde_2__lambda0* _closure, struct opt_12 old_value) {
	return (struct get_or_update_action_0) {2, .as2 = (struct insert_0) {_closure->pair.to}};
}
/* dict<str, arr<str>>.lambda0 dict<str, arr<str>>(cur dict<str, arr<str>>, x arrow<str, arr<str>>) */
struct dict_0 dict_0__lambda0(struct ctx* ctx, struct void_ _closure, struct dict_0 cur, struct arrow_0 x) {
	return _tilde_2(ctx, cur, x);
}
/* subscript<str> arr<str>(a arr<str>, range range<nat64>) */
struct arr_2 subscript_45(struct ctx* ctx, struct arr_2 a, struct range range) {
	uint8_t _0 = _lessOrEqual_0(range.high, a.size);
	assert_0(ctx, _0);
	struct str* _1 = _plus_8(a.begin_ptr, range.low);
	return (struct arr_2) {(range.high - range.low), _1};
}
/* parse-command-dynamic.lambda1 bool(arg str) */
uint8_t parse_command_dynamic__lambda1(struct ctx* ctx, struct void_ _closure, struct str arg) {
	return _equal_5(arg, (struct str) {{2, constantarr_0_14}});
}
/* parse-named-args dict<str, arr<str>>(args arr<str>) */
struct dict_0 parse_named_args_1(struct ctx* ctx, struct arr_2 args) {
	struct mut_dict_0* res0;
	res0 = mut_dict_0(ctx);
	
	parse_named_args_recur(ctx, args, res0);
	return move_to_dict__e_0(ctx, res0);
}
/* mut-dict<str, arr<str>> mut-dict<str, arr<str>>() */
struct mut_dict_0* mut_dict_0(struct ctx* ctx) {
	struct mut_dict_0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_dict_0));
	temp0 = ((struct mut_dict_0*) _0);
	
	struct fix_arr_5 _1 = fix_arr_6();
	*temp0 = (struct mut_dict_0) {(struct void_) {}, _1, 0u};
	return temp0;
}
/* fix-arr<entry<k, v>> fix-arr<entry<str, arr<str>>>() */
struct fix_arr_5 fix_arr_6(void) {
	return (struct fix_arr_5) {(struct void_) {}, (struct arr_11) {0u, NULL}};
}
/* parse-named-args-recur void(args arr<str>, builder mut-dict<str, arr<str>>) */
struct void_ parse_named_args_recur(struct ctx* ctx, struct arr_2 args, struct mut_dict_0* builder) {
	top:;
	struct str first_name0;
	struct str _0 = subscript_26(ctx, args, 0u);
	struct opt_16 _1 = try_remove_start_0(ctx, _0, (struct str) {{2, constantarr_0_14}});
	first_name0 = force_2(ctx, _1);
	
	struct arr_2 tl1;
	tl1 = tail_3(ctx, args);
	
	struct opt_11 _2 = find_index_0(ctx, tl1, (struct fun_act1_8) {2, .as2 = (struct void_) {}});
	switch (_2.kind) {
		case 0: {
			return set_subscript_6(ctx, builder, first_name0, tl1);
		}
		case 1: {
			struct some_11 _matched2 = _2.as1;
			
			uint64_t next_named_arg_index3;
			next_named_arg_index3 = _matched2.value;
			
			struct range _3 = _range(ctx, 0u, next_named_arg_index3);
			struct arr_2 _4 = subscript_45(ctx, tl1, _3);
			set_subscript_6(ctx, builder, first_name0, _4);
			struct range _5 = _range(ctx, next_named_arg_index3, tl1.size);
			struct arr_2 _6 = subscript_45(ctx, tl1, _5);
			args = _6;
			builder = builder;
			goto top;
		}
		default:
			
	return (struct void_) {};;
	}
}
/* force<str> str(a opt<str>) */
struct str force_2(struct ctx* ctx, struct opt_16 a) {
	return force_3(ctx, a, (struct str) {{27, constantarr_0_16}});
}
/* force<a> str(a opt<str>, message str) */
struct str force_3(struct ctx* ctx, struct opt_16 a, struct str message) {
	struct opt_16 _0 = a;
	switch (_0.kind) {
		case 0: {
			return throw_6(ctx, message);
		}
		case 1: {
			struct some_16 _matched0 = _0.as1;
			
			struct str v1;
			v1 = _matched0.value;
			
			return v1;
		}
		default:
			
	return (struct str) {(struct arr_0) {0, NULL}};;
	}
}
/* throw<a> str(message str) */
struct str throw_6(struct ctx* ctx, struct str message) {
	struct backtrace _0 = get_backtrace(ctx);
	return throw_7(ctx, (struct exception) {message, _0});
}
/* throw<a> str(e exception) */
struct str throw_7(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx0;
	exn_ctx0 = get_exception_ctx(ctx);
	
	uint8_t _0 = _notEqual_3(exn_ctx0->jmp_buf_ptr, NULL);
	hard_assert(_0);
	exn_ctx0->thrown_exception = e;
	int32_t _1 = number_to_throw(ctx);
	(longjmp(exn_ctx0->jmp_buf_ptr, _1), (struct void_) {});
	return hard_unreachable_4();
}
/* hard-unreachable<a> str() */
struct str hard_unreachable_4(void) {
	(abort(), (struct void_) {});
	return (struct str) {(struct arr_0) {0, NULL}};
}
/* try-remove-start opt<str>(a str, b str) */
struct opt_16 try_remove_start_0(struct ctx* ctx, struct str a, struct str b) {
	struct opt_17 _0 = try_remove_start_1(ctx, a.chars, b.chars);
	switch (_0.kind) {
		case 0: {
			return (struct opt_16) {0, .as0 = (struct none) {}};
		}
		case 1: {
			struct some_17 _matched0 = _0.as1;
			
			struct arr_0 res1;
			res1 = _matched0.value;
			
			return (struct opt_16) {1, .as1 = (struct some_16) {(struct str) {res1}}};
		}
		default:
			
	return (struct opt_16) {0};;
	}
}
/* try-remove-start<char> opt<arr<char>>(a arr<char>, start arr<char>) */
struct opt_17 try_remove_start_1(struct ctx* ctx, struct arr_0 a, struct arr_0 start) {
	uint8_t _0 = starts_with_1(ctx, a, start);
	if (_0) {
		struct range _1 = _range(ctx, start.size, a.size);
		struct arr_0 _2 = subscript_4(ctx, a, _1);
		return (struct opt_17) {1, .as1 = (struct some_17) {_2}};
	} else {
		return (struct opt_17) {0, .as0 = (struct none) {}};
	}
}
/* tail<str> arr<str>(a arr<str>) */
struct arr_2 tail_3(struct ctx* ctx, struct arr_2 a) {
	uint8_t _0 = is_empty_7(a);
	forbid(ctx, _0);
	struct range _1 = _range(ctx, 1u, a.size);
	return subscript_45(ctx, a, _1);
}
/* is-empty<a> bool(a arr<str>) */
uint8_t is_empty_7(struct arr_2 a) {
	return (a.size == 0u);
}
/* parse-named-args-recur.lambda0 bool(arg str) */
uint8_t parse_named_args_recur__lambda0(struct ctx* ctx, struct void_ _closure, struct str arg) {
	return starts_with_0(ctx, arg, (struct str) {{2, constantarr_0_14}});
}
/* set-subscript<str, arr<str>> void(a mut-dict<str, arr<str>>, key str, value arr<str>) */
struct void_ set_subscript_6(struct ctx* ctx, struct mut_dict_0* a, struct str key, struct arr_2 value) {
	struct opt_12 _0 = update__e_0(ctx, a, key, (struct opt_12) {1, .as1 = (struct some_12) {value}});
	return drop_2(_0);
}
/* drop<opt<v>> void(_ opt<arr<str>>) */
struct void_ drop_2(struct opt_12 _p0) {
	return (struct void_) {};
}
/* update!<k, v> opt<arr<str>>(a mut-dict<str, arr<str>>, key str, new-value opt<arr<str>>) */
struct opt_12 update__e_0(struct ctx* ctx, struct mut_dict_0* a, struct str key, struct opt_12 new_value) {
	uint8_t _0 = is_empty_8(a->entries);
	if (_0) {
		struct opt_12 _1 = new_value;
		switch (_1.kind) {
			case 0: {
				(struct void_) {};
				break;
			}
			case 1: {
				struct some_12 _matched0 = _1.as1;
				
				struct arr_2 value1;
				value1 = _matched0.value;
				
				struct entry_0* temp0;
				uint8_t* _2 = alloc(ctx, (sizeof(struct entry_0) * 1u));
				temp0 = ((struct entry_0*) _2);
				
				struct arrow_0 _3 = _arrow_0(key, value1);
				*(temp0 + 0u) = (struct entry_0) {1, .as1 = _3};
				struct fix_arr_5 _4 = fix_arr_7(ctx, (struct arr_11) {1u, temp0});
				a->entries = _4;
				a->total_size = 1u;
				break;
			}
			default:
				
		(struct void_) {};;
		}
		return (struct opt_12) {0, .as0 = (struct none) {}};
	} else {
		uint64_t entry_index2;
		uint64_t _5 = hash(ctx, key);
		uint64_t _6 = size_5(a->entries);
		entry_index2 = (_5 % _6);
		
		struct entry_0 _7 = subscript_49(ctx, a->entries, entry_index2);
		switch (_7.kind) {
			case 0: {
				struct opt_12 _8 = new_value;
				switch (_8.kind) {
					case 0: {
						(struct void_) {};
						break;
					}
					case 1: {
						struct some_12 _matched3 = _8.as1;
						
						struct arr_2 value4;
						value4 = _matched3.value;
						
						struct arrow_0 _9 = _arrow_0(key, value4);
						set_subscript_8(ctx, a->entries, entry_index2, (struct entry_0) {1, .as1 = _9});
						a->total_size = (a->total_size + 1u);
						break;
					}
					default:
						
				(struct void_) {};;
				}
				return (struct opt_12) {0, .as0 = (struct none) {}};
			}
			case 1: {
				struct arrow_0 ar5 = _7.as1;
				
				uint8_t _10 = _equal_5(ar5.from, key);
				if (_10) {
					struct opt_12 _11 = new_value;struct entry_0 _12;
					
					switch (_11.kind) {
						case 0: {
							a->total_size = (a->total_size - 1u);
							_12 = (struct entry_0) {0, .as0 = (struct none) {}};
							break;
						}
						case 1: {
							struct some_12 _matched6 = _11.as1;
							
							struct arr_2 value7;
							value7 = _matched6.value;
							
							struct arrow_0 _13 = _arrow_0(key, value7);
							_12 = (struct entry_0) {1, .as1 = _13};
							break;
						}
						default:
							
					_12 = (struct entry_0) {0};;
					}
					set_subscript_8(ctx, a->entries, entry_index2, _12);
					return (struct opt_12) {1, .as1 = (struct some_12) {ar5.to}};
				} else {
					struct opt_12 _14 = new_value;
					switch (_14.kind) {
						case 0: {
							(struct void_) {};
							break;
						}
						case 1: {
							struct some_12 _matched8 = _14.as1;
							
							struct arr_2 value9;
							value9 = _matched8.value;
							
							uint8_t _15 = should_expand_0(ctx, a);
							if (_15) {
								expand__e_0(ctx, a);
								set_subscript_6(ctx, a, key, value9);
							} else {
								struct arrow_0* temp1;
								uint8_t* _16 = alloc(ctx, (sizeof(struct arrow_0) * 2u));
								temp1 = ((struct arrow_0*) _16);
								
								*(temp1 + 0u) = ar5;
								struct arrow_0 _17 = _arrow_0(key, value9);
								*(temp1 + 1u) = _17;
								struct mut_arr_2* _18 = mut_arr_1(ctx, (struct arr_10) {2u, temp1});
								set_subscript_8(ctx, a->entries, entry_index2, (struct entry_0) {2, .as2 = _18});
								a->total_size = (a->total_size + 1u);
							}
							break;
						}
						default:
							
					(struct void_) {};;
					}
					return (struct opt_12) {0, .as0 = (struct none) {}};
				}
			}
			case 2: {
				struct mut_arr_2* m10 = _7.as2;
				
				struct update__e_0__lambda0* temp2;
				uint8_t* _19 = alloc(ctx, sizeof(struct update__e_0__lambda0));
				temp2 = ((struct update__e_0__lambda0*) _19);
				
				*temp2 = (struct update__e_0__lambda0) {key};
				struct opt_11 _20 = find_index_3(ctx, m10, (struct fun_act1_9) {2, .as2 = temp2});
				switch (_20.kind) {
					case 0: {
						struct opt_12 _21 = new_value;
						switch (_21.kind) {
							case 0: {
								(struct void_) {};
								break;
							}
							case 1: {
								struct some_12 _matched11 = _21.as1;
								
								struct arr_2 value12;
								value12 = _matched11.value;
								
								uint8_t _22 = is_at_capacity_0(m10);uint8_t _23;
								
								if (_22) {
									_23 = should_expand_0(ctx, a);
								} else {
									_23 = 0;
								}
								if (_23) {
									expand__e_0(ctx, a);
									set_subscript_6(ctx, a, key, value12);
								} else {
									struct arrow_0 _24 = _arrow_0(key, value12);
									_concatEquals_5(ctx, m10, _24);
									a->total_size = (a->total_size + 1u);
								}
								break;
							}
							default:
								
						(struct void_) {};;
						}
						return (struct opt_12) {0, .as0 = (struct none) {}};
					}
					case 1: {
						struct some_11 _matched13 = _20.as1;
						
						uint64_t index14;
						index14 = _matched13.value;
						
						struct arr_2 old_value15;
						struct arrow_0 _25 = subscript_55(ctx, m10, index14);
						old_value15 = _25.to;
						
						struct opt_12 _26 = new_value;
						switch (_26.kind) {
							case 0: {
								struct arrow_0 _27 = remove_unordered_at__e_0(ctx, m10, index14);
								drop_3(_27);
								uint8_t _28 = is_empty_9(m10);
								if (_28) {
									set_subscript_8(ctx, a->entries, entry_index2, (struct entry_0) {0, .as0 = (struct none) {}});
								} else {
									uint8_t _29 = (m10->size == 1u);
									if (_29) {
										struct arrow_0 z16;
										z16 = subscript_55(ctx, m10, 0u);
										
										set_subscript_8(ctx, a->entries, entry_index2, (struct entry_0) {1, .as1 = z16});
									} else {
										(struct void_) {};
									}
								}
								a->total_size = (a->total_size - 1u);
								break;
							}
							case 1: {
								struct some_12 _matched17 = _26.as1;
								
								struct arr_2 value18;
								value18 = _matched17.value;
								
								struct arrow_0 _30 = _arrow_0(key, value18);
								set_subscript_10(ctx, m10, index14, _30);
								break;
							}
							default:
								
						(struct void_) {};;
						}
						return (struct opt_12) {1, .as1 = (struct some_12) {old_value15}};
					}
					default:
						
				return (struct opt_12) {0};;
				}
			}
			default:
				
		return (struct opt_12) {0};;
		}
	}
}
/* is-empty<entry<k, v>> bool(a fix-arr<entry<str, arr<str>>>) */
uint8_t is_empty_8(struct fix_arr_5 a) {
	uint64_t _0 = size_5(a);
	return (_0 == 0u);
}
/* size<a> nat64(a fix-arr<entry<str, arr<str>>>) */
uint64_t size_5(struct fix_arr_5 a) {
	return a.inner.size;
}
/* fix-arr<entry<k, v>> fix-arr<entry<str, arr<str>>>(a arr<entry<str, arr<str>>>) */
struct fix_arr_5 fix_arr_7(struct ctx* ctx, struct arr_11 a) {
	struct fix_arr_7__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct fix_arr_7__lambda0));
	temp0 = ((struct fix_arr_7__lambda0*) _0);
	
	*temp0 = (struct fix_arr_7__lambda0) {a};
	return make_fix_arr_1(ctx, a.size, (struct fun_act1_14) {0, .as0 = temp0});
}
/* make-fix-arr<a> fix-arr<entry<str, arr<str>>>(size nat64, f fun-act1<entry<str, arr<str>>, nat64>) */
struct fix_arr_5 make_fix_arr_1(struct ctx* ctx, uint64_t size, struct fun_act1_14 f) {
	struct fix_arr_5 res0;
	res0 = uninitialized_fix_arr_3(ctx, size);
	
	struct entry_0* _0 = begin_ptr_6(res0);
	fill_ptr_range_2(ctx, _0, size, f);
	return res0;
}
/* uninitialized-fix-arr<a> fix-arr<entry<str, arr<str>>>(size nat64) */
struct fix_arr_5 uninitialized_fix_arr_3(struct ctx* ctx, uint64_t size) {
	struct entry_0* _0 = alloc_uninitialized_4(ctx, size);
	return fix_arr_8(size, _0);
}
/* fix-arr<a> fix-arr<entry<str, arr<str>>>(size nat64, begin-ptr mut-ptr<entry<str, arr<str>>>) */
struct fix_arr_5 fix_arr_8(uint64_t size, struct entry_0* begin_ptr) {
	return (struct fix_arr_5) {(struct void_) {}, (struct arr_11) {size, ((struct entry_0*) begin_ptr)}};
}
/* alloc-uninitialized<a> mut-ptr<entry<str, arr<str>>>(size nat64) */
struct entry_0* alloc_uninitialized_4(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(struct entry_0)));
	return ((struct entry_0*) _0);
}
/* fill-ptr-range<a> void(begin mut-ptr<entry<str, arr<str>>>, size nat64, f fun-act1<entry<str, arr<str>>, nat64>) */
struct void_ fill_ptr_range_2(struct ctx* ctx, struct entry_0* begin, uint64_t size, struct fun_act1_14 f) {
	return fill_ptr_range_recur_2(ctx, begin, 0u, size, f);
}
/* fill-ptr-range-recur<a> void(begin mut-ptr<entry<str, arr<str>>>, i nat64, size nat64, f fun-act1<entry<str, arr<str>>, nat64>) */
struct void_ fill_ptr_range_recur_2(struct ctx* ctx, struct entry_0* begin, uint64_t i, uint64_t size, struct fun_act1_14 f) {
	top:;
	uint8_t _0 = _notEqual_5(i, size);
	if (_0) {
		struct entry_0 _1 = subscript_46(ctx, f, i);
		set_subscript_7(begin, i, _1);
		begin = begin;
		i = (i + 1u);
		size = size;
		f = f;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* set-subscript<a> void(a mut-ptr<entry<str, arr<str>>>, n nat64, value entry<str, arr<str>>) */
struct void_ set_subscript_7(struct entry_0* a, uint64_t n, struct entry_0 value) {
	return (*(a + n) = value, (struct void_) {});
}
/* subscript<a, nat64> entry<str, arr<str>>(a fun-act1<entry<str, arr<str>>, nat64>, p0 nat64) */
struct entry_0 subscript_46(struct ctx* ctx, struct fun_act1_14 a, uint64_t p0) {
	return call_w_ctx_629(a, ctx, p0);
}
/* call-w-ctx<entry<str, arr<str>>, nat-64> (generated) (generated) */
struct entry_0 call_w_ctx_629(struct fun_act1_14 a, struct ctx* ctx, uint64_t p0) {
	struct fun_act1_14 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct fix_arr_7__lambda0* closure0 = _0.as0;
			
			return fix_arr_7__lambda0(ctx, closure0, p0);
		}
		case 1: {
			struct fill_fix_arr_1__lambda0* closure1 = _0.as1;
			
			return fill_fix_arr_1__lambda0(ctx, closure1, p0);
		}
		default:
			
	return (struct entry_0) {0};;
	}
}
/* begin-ptr<a> mut-ptr<entry<str, arr<str>>>(a fix-arr<entry<str, arr<str>>>) */
struct entry_0* begin_ptr_6(struct fix_arr_5 a) {
	return ((struct entry_0*) a.inner.begin_ptr);
}
/* subscript<a> entry<str, arr<str>>(a arr<entry<str, arr<str>>>, index nat64) */
struct entry_0 subscript_47(struct ctx* ctx, struct arr_11 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	return unsafe_at_7(a, index);
}
/* unsafe-at<a> entry<str, arr<str>>(a arr<entry<str, arr<str>>>, index nat64) */
struct entry_0 unsafe_at_7(struct arr_11 a, uint64_t index) {
	return subscript_48(a.begin_ptr, index);
}
/* subscript<a> entry<str, arr<str>>(a const-ptr<entry<str, arr<str>>>, n nat64) */
struct entry_0 subscript_48(struct entry_0* a, uint64_t n) {
	struct entry_0* _0 = _plus_11(a, n);
	return _times_13(_0);
}
/* *<a> entry<str, arr<str>>(a const-ptr<entry<str, arr<str>>>) */
struct entry_0 _times_13(struct entry_0* a) {
	return (*((struct entry_0*) a));
}
/* +<a> const-ptr<entry<str, arr<str>>>(a const-ptr<entry<str, arr<str>>>, offset nat64) */
struct entry_0* _plus_11(struct entry_0* a, uint64_t offset) {
	return ((struct entry_0*) (((struct entry_0*) a) + offset));
}
/* fix-arr<entry<k, v>>.lambda0 entry<str, arr<str>>(i nat64) */
struct entry_0 fix_arr_7__lambda0(struct ctx* ctx, struct fix_arr_7__lambda0* _closure, uint64_t i) {
	return subscript_47(ctx, _closure->a, i);
}
/* subscript<entry<k, v>> entry<str, arr<str>>(a fix-arr<entry<str, arr<str>>>, index nat64) */
struct entry_0 subscript_49(struct ctx* ctx, struct fix_arr_5 a, uint64_t index) {
	uint64_t _0 = size_5(a);
	uint8_t _1 = _less_0(index, _0);
	assert_0(ctx, _1);
	return unsafe_at_8(ctx, a, index);
}
/* unsafe-at<a> entry<str, arr<str>>(a fix-arr<entry<str, arr<str>>>, index nat64) */
struct entry_0 unsafe_at_8(struct ctx* ctx, struct fix_arr_5 a, uint64_t index) {
	struct entry_0* _0 = begin_ptr_6(a);
	return subscript_50(_0, index);
}
/* subscript<a> entry<str, arr<str>>(a mut-ptr<entry<str, arr<str>>>, n nat64) */
struct entry_0 subscript_50(struct entry_0* a, uint64_t n) {
	return (*(a + n));
}
/* set-subscript<entry<k, v>> void(a fix-arr<entry<str, arr<str>>>, index nat64, value entry<str, arr<str>>) */
struct void_ set_subscript_8(struct ctx* ctx, struct fix_arr_5 a, uint64_t index, struct entry_0 value) {
	uint64_t _0 = size_5(a);
	uint8_t _1 = _less_0(index, _0);
	assert_0(ctx, _1);
	return unsafe_set_at__e_1(ctx, a, index, value);
}
/* unsafe-set-at!<a> void(a fix-arr<entry<str, arr<str>>>, index nat64, value entry<str, arr<str>>) */
struct void_ unsafe_set_at__e_1(struct ctx* ctx, struct fix_arr_5 a, uint64_t index, struct entry_0 value) {
	struct entry_0* _0 = begin_ptr_6(a);
	return set_subscript_7(_0, index, value);
}
/* should-expand<k, v> bool(a mut-dict<str, arr<str>>) */
uint8_t should_expand_0(struct ctx* ctx, struct mut_dict_0* a) {
	uint64_t _0 = size_5(a->entries);
	return _greaterOrEqual(a->total_size, _0);
}
/* expand!<k, v> void(a mut-dict<str, arr<str>>) */
struct void_ expand__e_0(struct ctx* ctx, struct mut_dict_0* a) {
	uint64_t _0 = size_5(a->entries);
	forbid(ctx, (_0 == 0u));
	uint64_t new_size0;
	uint64_t _1 = size_5(a->entries);
	new_size0 = (_1 * 2u);
	
	struct mut_dict_0* bigger1;
	bigger1 = mut_dict_with_capacity_0(ctx, new_size0);
	
	struct expand__e_0__lambda0* temp0;
	uint8_t* _2 = alloc(ctx, sizeof(struct expand__e_0__lambda0));
	temp0 = ((struct expand__e_0__lambda0*) _2);
	
	*temp0 = (struct expand__e_0__lambda0) {bigger1};
	each_3(ctx, a, (struct fun_act2_3) {0, .as0 = temp0});
	swap__e_1(ctx, a, bigger1);
	uint64_t _3 = size_5(a->entries);
	return assert_0(ctx, (_3 == new_size0));
}
/* mut-dict-with-capacity<k, v> mut-dict<str, arr<str>>(capacity nat64) */
struct mut_dict_0* mut_dict_with_capacity_0(struct ctx* ctx, uint64_t capacity) {
	struct mut_dict_0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_dict_0));
	temp0 = ((struct mut_dict_0*) _0);
	
	struct fix_arr_5 _1 = fill_fix_arr_1(ctx, capacity, (struct entry_0) {0, .as0 = (struct none) {}});
	*temp0 = (struct mut_dict_0) {(struct void_) {}, _1, 0u};
	return temp0;
}
/* fill-fix-arr<entry<k, v>> fix-arr<entry<str, arr<str>>>(size nat64, value entry<str, arr<str>>) */
struct fix_arr_5 fill_fix_arr_1(struct ctx* ctx, uint64_t size, struct entry_0 value) {
	struct fill_fix_arr_1__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct fill_fix_arr_1__lambda0));
	temp0 = ((struct fill_fix_arr_1__lambda0*) _0);
	
	*temp0 = (struct fill_fix_arr_1__lambda0) {value};
	return make_fix_arr_1(ctx, size, (struct fun_act1_14) {1, .as1 = temp0});
}
/* fill-fix-arr<entry<k, v>>.lambda0 entry<str, arr<str>>(ignore nat64) */
struct entry_0 fill_fix_arr_1__lambda0(struct ctx* ctx, struct fill_fix_arr_1__lambda0* _closure, uint64_t ignore) {
	return _closure->value;
}
/* each<k, v> void(a mut-dict<str, arr<str>>, f fun-act2<void, str, arr<str>>) */
struct void_ each_3(struct ctx* ctx, struct mut_dict_0* a, struct fun_act2_3 f) {
	struct each_3__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct each_3__lambda0));
	temp0 = ((struct each_3__lambda0*) _0);
	
	*temp0 = (struct each_3__lambda0) {f};
	return fold_2(ctx, (struct void_) {}, a, (struct fun_act3_1) {0, .as0 = temp0});
}
/* fold<void, k, v> void(acc void, a mut-dict<str, arr<str>>, f fun-act3<void, void, str, arr<str>>) */
struct void_ fold_2(struct ctx* ctx, struct void_ acc, struct mut_dict_0* a, struct fun_act3_1 f) {
	struct fold_2__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct fold_2__lambda0));
	temp0 = ((struct fold_2__lambda0*) _0);
	
	*temp0 = (struct fold_2__lambda0) {f};
	return fold_3(ctx, acc, a->entries, (struct fun_act2_4) {0, .as0 = temp0});
}
/* fold<a, entry<k, v>> void(acc void, a fix-arr<entry<str, arr<str>>>, f fun-act2<void, void, entry<str, arr<str>>>) */
struct void_ fold_3(struct ctx* ctx, struct void_ acc, struct fix_arr_5 a, struct fun_act2_4 f) {
	struct arr_11 _0 = temp_as_arr_2(a);
	return fold_4(ctx, acc, _0, f);
}
/* fold<a, b> void(acc void, a arr<entry<str, arr<str>>>, f fun-act2<void, void, entry<str, arr<str>>>) */
struct void_ fold_4(struct ctx* ctx, struct void_ acc, struct arr_11 a, struct fun_act2_4 f) {
	struct entry_0* _0 = end_ptr_4(a);
	return fold_recur_2(ctx, acc, a.begin_ptr, _0, f);
}
/* fold-recur<a, b> void(acc void, cur const-ptr<entry<str, arr<str>>>, end const-ptr<entry<str, arr<str>>>, f fun-act2<void, void, entry<str, arr<str>>>) */
struct void_ fold_recur_2(struct ctx* ctx, struct void_ acc, struct entry_0* cur, struct entry_0* end, struct fun_act2_4 f) {
	top:;
	uint8_t _0 = _equal_8(cur, end);
	if (_0) {
		return acc;
	} else {
		struct entry_0 _1 = _times_13(cur);
		struct void_ _2 = subscript_51(ctx, f, acc, _1);
		struct entry_0* _3 = _plus_11(cur, 1u);
		acc = _2;
		cur = _3;
		end = end;
		f = f;
		goto top;
	}
}
/* ==<b> bool(a const-ptr<entry<str, arr<str>>>, b const-ptr<entry<str, arr<str>>>) */
uint8_t _equal_8(struct entry_0* a, struct entry_0* b) {
	return (((struct entry_0*) a) == ((struct entry_0*) b));
}
/* subscript<a, a, b> void(a fun-act2<void, void, entry<str, arr<str>>>, p0 void, p1 entry<str, arr<str>>) */
struct void_ subscript_51(struct ctx* ctx, struct fun_act2_4 a, struct void_ p0, struct entry_0 p1) {
	return call_w_ctx_654(a, ctx, p0, p1);
}
/* call-w-ctx<void, void, entry<str, arr<str>>> (generated) (generated) */
struct void_ call_w_ctx_654(struct fun_act2_4 a, struct ctx* ctx, struct void_ p0, struct entry_0 p1) {
	struct fun_act2_4 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct fold_2__lambda0* closure0 = _0.as0;
			
			return fold_2__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* end-ptr<b> const-ptr<entry<str, arr<str>>>(a arr<entry<str, arr<str>>>) */
struct entry_0* end_ptr_4(struct arr_11 a) {
	return _plus_11(a.begin_ptr, a.size);
}
/* temp-as-arr<b> arr<entry<str, arr<str>>>(a fix-arr<entry<str, arr<str>>>) */
struct arr_11 temp_as_arr_2(struct fix_arr_5 a) {
	return a.inner;
}
/* subscript<a, a, k, v> void(a fun-act3<void, void, str, arr<str>>, p0 void, p1 str, p2 arr<str>) */
struct void_ subscript_52(struct ctx* ctx, struct fun_act3_1 a, struct void_ p0, struct str p1, struct arr_2 p2) {
	return call_w_ctx_658(a, ctx, p0, p1, p2);
}
/* call-w-ctx<void, void, str, arr<str>> (generated) (generated) */
struct void_ call_w_ctx_658(struct fun_act3_1 a, struct ctx* ctx, struct void_ p0, struct str p1, struct arr_2 p2) {
	struct fun_act3_1 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct each_3__lambda0* closure0 = _0.as0;
			
			return each_3__lambda0(ctx, closure0, p0, p1, p2);
		}
		case 1: {
			struct each_4__lambda0* closure1 = _0.as1;
			
			return each_4__lambda0(ctx, closure1, p0, p1, p2);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* fold<a, arrow<k, v>> void(acc void, a mut-arr<arrow<str, arr<str>>>, f fun-act2<void, void, arrow<str, arr<str>>>) */
struct void_ fold_5(struct ctx* ctx, struct void_ acc, struct mut_arr_2* a, struct fun_act2_5 f) {
	struct arr_10 _0 = temp_as_arr_3(a);
	return fold_6(ctx, acc, _0, f);
}
/* fold<a, b> void(acc void, a arr<arrow<str, arr<str>>>, f fun-act2<void, void, arrow<str, arr<str>>>) */
struct void_ fold_6(struct ctx* ctx, struct void_ acc, struct arr_10 a, struct fun_act2_5 f) {
	struct arrow_0* _0 = end_ptr_2(a);
	return fold_recur_3(ctx, acc, a.begin_ptr, _0, f);
}
/* fold-recur<a, b> void(acc void, cur const-ptr<arrow<str, arr<str>>>, end const-ptr<arrow<str, arr<str>>>, f fun-act2<void, void, arrow<str, arr<str>>>) */
struct void_ fold_recur_3(struct ctx* ctx, struct void_ acc, struct arrow_0* cur, struct arrow_0* end, struct fun_act2_5 f) {
	top:;
	uint8_t _0 = _equal_6(cur, end);
	if (_0) {
		return acc;
	} else {
		struct arrow_0 _1 = _times_11(cur);
		struct void_ _2 = subscript_53(ctx, f, acc, _1);
		struct arrow_0* _3 = _plus_9(cur, 1u);
		acc = _2;
		cur = _3;
		end = end;
		f = f;
		goto top;
	}
}
/* subscript<a, a, b> void(a fun-act2<void, void, arrow<str, arr<str>>>, p0 void, p1 arrow<str, arr<str>>) */
struct void_ subscript_53(struct ctx* ctx, struct fun_act2_5 a, struct void_ p0, struct arrow_0 p1) {
	return call_w_ctx_663(a, ctx, p0, p1);
}
/* call-w-ctx<void, void, arrow<str, arr<str>>> (generated) (generated) */
struct void_ call_w_ctx_663(struct fun_act2_5 a, struct ctx* ctx, struct void_ p0, struct arrow_0 p1) {
	struct fun_act2_5 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct fold_2__lambda0__lambda0* closure0 = _0.as0;
			
			return fold_2__lambda0__lambda0(ctx, closure0, p0, p1);
		}
		case 1: {
			struct fold_recur_6__lambda1* closure1 = _0.as1;
			
			return fold_recur_6__lambda1(ctx, closure1, p0, p1);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* temp-as-arr<b> arr<arrow<str, arr<str>>>(a mut-arr<arrow<str, arr<str>>>) */
struct arr_10 temp_as_arr_3(struct mut_arr_2* a) {
	struct fix_arr_3 _0 = temp_as_fix_arr_1(a);
	return temp_as_arr_4(_0);
}
/* temp-as-arr<a> arr<arrow<str, arr<str>>>(a fix-arr<arrow<str, arr<str>>>) */
struct arr_10 temp_as_arr_4(struct fix_arr_3 a) {
	return a.inner;
}
/* temp-as-fix-arr<a> fix-arr<arrow<str, arr<str>>>(a mut-arr<arrow<str, arr<str>>>) */
struct fix_arr_3 temp_as_fix_arr_1(struct mut_arr_2* a) {
	struct arrow_0* _0 = begin_ptr_7(a);
	return fix_arr_4(a->size, _0);
}
/* begin-ptr<a> mut-ptr<arrow<str, arr<str>>>(a mut-arr<arrow<str, arr<str>>>) */
struct arrow_0* begin_ptr_7(struct mut_arr_2* a) {
	return begin_ptr_4(a->backing);
}
/* fold<void, k, v>.lambda0.lambda0 void(cur2 void, pair arrow<str, arr<str>>) */
struct void_ fold_2__lambda0__lambda0(struct ctx* ctx, struct fold_2__lambda0__lambda0* _closure, struct void_ cur2, struct arrow_0 pair) {
	return subscript_52(ctx, _closure->f, cur2, pair.from, pair.to);
}
/* fold<void, k, v>.lambda0 void(cur void, entry entry<str, arr<str>>) */
struct void_ fold_2__lambda0(struct ctx* ctx, struct fold_2__lambda0* _closure, struct void_ cur, struct entry_0 entry) {
	struct entry_0 _0 = entry;
	switch (_0.kind) {
		case 0: {
			return cur;
		}
		case 1: {
			struct arrow_0 ar0 = _0.as1;
			
			return subscript_52(ctx, _closure->f, cur, ar0.from, ar0.to);
		}
		case 2: {
			struct mut_arr_2* m1 = _0.as2;
			
			struct fold_2__lambda0__lambda0* temp0;
			uint8_t* _1 = alloc(ctx, sizeof(struct fold_2__lambda0__lambda0));
			temp0 = ((struct fold_2__lambda0__lambda0*) _1);
			
			*temp0 = (struct fold_2__lambda0__lambda0) {_closure->f};
			return fold_5(ctx, cur, m1, (struct fun_act2_5) {0, .as0 = temp0});
		}
		default:
			
	return (struct void_) {};;
	}
}
/* subscript<void, k, v> void(a fun-act2<void, str, arr<str>>, p0 str, p1 arr<str>) */
struct void_ subscript_54(struct ctx* ctx, struct fun_act2_3 a, struct str p0, struct arr_2 p1) {
	return call_w_ctx_671(a, ctx, p0, p1);
}
/* call-w-ctx<void, str, arr<str>> (generated) (generated) */
struct void_ call_w_ctx_671(struct fun_act2_3 a, struct ctx* ctx, struct str p0, struct arr_2 p1) {
	struct fun_act2_3 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct expand__e_0__lambda0* closure0 = _0.as0;
			
			return expand__e_0__lambda0(ctx, closure0, p0, p1);
		}
		case 1: {
			struct parse_named_args_0__lambda0* closure1 = _0.as1;
			
			return parse_named_args_0__lambda0(ctx, closure1, p0, p1);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* each<k, v>.lambda0 void(ignore void, key str, value arr<str>) */
struct void_ each_3__lambda0(struct ctx* ctx, struct each_3__lambda0* _closure, struct void_ ignore, struct str key, struct arr_2 value) {
	return subscript_54(ctx, _closure->f, key, value);
}
/* expand!<k, v>.lambda0 void(key str, value arr<str>) */
struct void_ expand__e_0__lambda0(struct ctx* ctx, struct expand__e_0__lambda0* _closure, struct str key, struct arr_2 value) {
	return set_subscript_6(ctx, _closure->bigger, key, value);
}
/* swap!<k, v> void(a mut-dict<str, arr<str>>, b mut-dict<str, arr<str>>) */
struct void_ swap__e_1(struct ctx* ctx, struct mut_dict_0* a, struct mut_dict_0* b) {
	struct fix_arr_5 temp_entries0;
	temp_entries0 = a->entries;
	
	a->entries = b->entries;
	b->entries = temp_entries0;
	uint64_t temp_size1;
	temp_size1 = a->total_size;
	
	a->total_size = b->total_size;
	return (b->total_size = temp_size1, (struct void_) {});
}
/* mut-arr<arrow<k, v>> mut-arr<arrow<str, arr<str>>>(a arr<arrow<str, arr<str>>>) */
struct mut_arr_2* mut_arr_1(struct ctx* ctx, struct arr_10 a) {
	struct mut_arr_2* res0;
	res0 = mut_arr_2(ctx);
	
	_concatEquals_4(ctx, res0, a);
	return res0;
}
/* mut-arr<a> mut-arr<arrow<str, arr<str>>>() */
struct mut_arr_2* mut_arr_2(struct ctx* ctx) {
	struct mut_arr_2* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_arr_2));
	temp0 = ((struct mut_arr_2*) _0);
	
	struct fix_arr_3 _1 = fix_arr_9();
	*temp0 = (struct mut_arr_2) {_1, 0u};
	return temp0;
}
/* fix-arr<a> fix-arr<arrow<str, arr<str>>>() */
struct fix_arr_3 fix_arr_9(void) {
	return (struct fix_arr_3) {(struct void_) {}, (struct arr_10) {0u, NULL}};
}
/* ~=<a> void(a mut-arr<arrow<str, arr<str>>>, values arr<arrow<str, arr<str>>>) */
struct void_ _concatEquals_4(struct ctx* ctx, struct mut_arr_2* a, struct arr_10 values) {
	struct _concatEquals_4__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct _concatEquals_4__lambda0));
	temp0 = ((struct _concatEquals_4__lambda0*) _0);
	
	*temp0 = (struct _concatEquals_4__lambda0) {a};
	return each_2(ctx, values, (struct fun_act1_13) {1, .as1 = temp0});
}
/* ~=<a> void(a mut-arr<arrow<str, arr<str>>>, value arrow<str, arr<str>>) */
struct void_ _concatEquals_5(struct ctx* ctx, struct mut_arr_2* a, struct arrow_0 value) {
	incr_capacity__e_1(ctx, a);
	uint64_t _0 = capacity_2(a);
	uint8_t _1 = _less_0(a->size, _0);
	assert_0(ctx, _1);
	struct arrow_0* _2 = begin_ptr_7(a);
	set_subscript_9(_2, a->size, value);
	uint64_t _3 = _plus_3(ctx, a->size, 1u);
	return (a->size = _3, (struct void_) {});
}
/* incr-capacity!<a> void(a mut-arr<arrow<str, arr<str>>>) */
struct void_ incr_capacity__e_1(struct ctx* ctx, struct mut_arr_2* a) {
	uint64_t _0 = _plus_3(ctx, a->size, 1u);
	uint64_t _1 = round_up_to_power_of_two(ctx, _0);
	return ensure_capacity_1(ctx, a, _1);
}
/* ensure-capacity<a> void(a mut-arr<arrow<str, arr<str>>>, min-capacity nat64) */
struct void_ ensure_capacity_1(struct ctx* ctx, struct mut_arr_2* a, uint64_t min_capacity) {
	uint64_t _0 = capacity_2(a);
	uint8_t _1 = _less_0(_0, min_capacity);
	if (_1) {
		return increase_capacity_to__e_1(ctx, a, min_capacity);
	} else {
		return (struct void_) {};
	}
}
/* capacity<a> nat64(a mut-arr<arrow<str, arr<str>>>) */
uint64_t capacity_2(struct mut_arr_2* a) {
	return size_3(a->backing);
}
/* increase-capacity-to!<a> void(a mut-arr<arrow<str, arr<str>>>, new-capacity nat64) */
struct void_ increase_capacity_to__e_1(struct ctx* ctx, struct mut_arr_2* a, uint64_t new_capacity) {
	uint64_t _0 = capacity_2(a);
	uint8_t _1 = _greater(new_capacity, _0);
	assert_0(ctx, _1);
	struct arrow_0* old_begin0;
	old_begin0 = begin_ptr_7(a);
	
	struct fix_arr_3 _2 = uninitialized_fix_arr_1(ctx, new_capacity);
	a->backing = _2;
	struct arrow_0* _3 = begin_ptr_7(a);
	copy_data_from__e_3(ctx, _3, ((struct arrow_0*) old_begin0), a->size);
	uint64_t _4 = _plus_3(ctx, a->size, 1u);
	uint64_t _5 = size_3(a->backing);
	struct range _6 = _range(ctx, _4, _5);
	struct fix_arr_3 _7 = subscript_36(ctx, a->backing, _6);
	return set_zero_elements_1(_7);
}
/* set-zero-elements<a> void(a fix-arr<arrow<str, arr<str>>>) */
struct void_ set_zero_elements_1(struct fix_arr_3 a) {
	struct arrow_0* _0 = begin_ptr_4(a);
	uint64_t _1 = size_3(a);
	return set_zero_range_2(_0, _1);
}
/* set-zero-range<a> void(begin mut-ptr<arrow<str, arr<str>>>, size nat64) */
struct void_ set_zero_range_2(struct arrow_0* begin, uint64_t size) {
	uint8_t* _0 = memset(((uint8_t*) begin), 0, (size * sizeof(struct arrow_0)));
	return drop_0(_0);
}
/* set-subscript<a> void(a mut-ptr<arrow<str, arr<str>>>, n nat64, value arrow<str, arr<str>>) */
struct void_ set_subscript_9(struct arrow_0* a, uint64_t n, struct arrow_0 value) {
	return (*(a + n) = value, (struct void_) {});
}
/* ~=<a>.lambda0 void(x arrow<str, arr<str>>) */
struct void_ _concatEquals_4__lambda0(struct ctx* ctx, struct _concatEquals_4__lambda0* _closure, struct arrow_0 x) {
	return _concatEquals_5(ctx, _closure->a, x);
}
/* find-index<arrow<k, v>> opt<nat64>(a mut-arr<arrow<str, arr<str>>>, f fun-act1<bool, arrow<str, arr<str>>>) */
struct opt_11 find_index_3(struct ctx* ctx, struct mut_arr_2* a, struct fun_act1_9 f) {
	struct arr_10 _0 = temp_as_arr_3(a);
	return find_index_2(ctx, _0, f);
}
/* update!<k, v>.lambda0 bool(pair arrow<str, arr<str>>) */
uint8_t update__e_0__lambda0(struct ctx* ctx, struct update__e_0__lambda0* _closure, struct arrow_0 pair) {
	return _equal_5(pair.from, _closure->key);
}
/* is-at-capacity<arrow<k, v>> bool(a mut-arr<arrow<str, arr<str>>>) */
uint8_t is_at_capacity_0(struct mut_arr_2* a) {
	uint64_t _0 = capacity_2(a);
	return (_0 == a->size);
}
/* subscript<arrow<k, v>> arrow<str, arr<str>>(a mut-arr<arrow<str, arr<str>>>, index nat64) */
struct arrow_0 subscript_55(struct ctx* ctx, struct mut_arr_2* a, uint64_t index) {
	uint8_t _0 = _less_0(index, a->size);
	assert_0(ctx, _0);
	struct arrow_0* _1 = begin_ptr_7(a);
	return subscript_56(_1, index);
}
/* subscript<a> arrow<str, arr<str>>(a mut-ptr<arrow<str, arr<str>>>, n nat64) */
struct arrow_0 subscript_56(struct arrow_0* a, uint64_t n) {
	return (*(a + n));
}
/* drop<arrow<k, v>> void(_ arrow<str, arr<str>>) */
struct void_ drop_3(struct arrow_0 _p0) {
	return (struct void_) {};
}
/* remove-unordered-at!<arrow<k, v>> arrow<str, arr<str>>(a mut-arr<arrow<str, arr<str>>>, index nat64) */
struct arrow_0 remove_unordered_at__e_0(struct ctx* ctx, struct mut_arr_2* a, uint64_t index) {
	uint8_t _0 = _less_0(index, a->size);
	assert_0(ctx, _0);
	return noctx_remove_unordered_at__e_1(a, index);
}
/* noctx-remove-unordered-at!<a> arrow<str, arr<str>>(a mut-arr<arrow<str, arr<str>>>, index nat64) */
struct arrow_0 noctx_remove_unordered_at__e_1(struct mut_arr_2* a, uint64_t index) {
	uint8_t _0 = _less_0(index, a->size);
	hard_assert(_0);
	struct arrow_0 res0;
	struct arrow_0* _1 = begin_ptr_7(a);
	res0 = subscript_56(_1, index);
	
	uint64_t new_size1;
	new_size1 = (a->size - 1u);
	
	struct arrow_0* _2 = begin_ptr_7(a);
	struct arrow_0* _3 = begin_ptr_7(a);
	struct arrow_0 _4 = subscript_56(_3, new_size1);
	set_subscript_9(_2, index, _4);
	a->size = new_size1;
	return res0;
}
/* is-empty<arrow<k, v>> bool(a mut-arr<arrow<str, arr<str>>>) */
uint8_t is_empty_9(struct mut_arr_2* a) {
	return (a->size == 0u);
}
/* set-subscript<arrow<k, v>> void(a mut-arr<arrow<str, arr<str>>>, index nat64, value arrow<str, arr<str>>) */
struct void_ set_subscript_10(struct ctx* ctx, struct mut_arr_2* a, uint64_t index, struct arrow_0 value) {
	uint8_t _0 = _less_0(index, a->size);
	assert_0(ctx, _0);
	struct arrow_0* _1 = begin_ptr_7(a);
	return set_subscript_9(_1, index, value);
}
/* move-to-dict!<str, arr<str>> dict<str, arr<str>>(a mut-dict<str, arr<str>>) */
struct dict_0 move_to_dict__e_0(struct ctx* ctx, struct mut_dict_0* a) {
	struct dict_0 res0;
	struct arr_10 _0 = map_to_arr_0(ctx, a, (struct fun_act2_6) {0, .as0 = (struct void_) {}});
	res0 = dict_0(ctx, _0);
	
	empty__e_0(ctx, a);
	return res0;
}
/* map-to-arr<arrow<k, v>, k, v> arr<arrow<str, arr<str>>>(a mut-dict<str, arr<str>>, f fun-act2<arrow<str, arr<str>>, str, arr<str>>) */
struct arr_10 map_to_arr_0(struct ctx* ctx, struct mut_dict_0* a, struct fun_act2_6 f) {
	struct fix_arr_3 out0;
	uint64_t _0 = size_6(ctx, a);
	out0 = uninitialized_fix_arr_1(ctx, _0);
	
	struct arrow_0* end1;
	struct arrow_0* _1 = begin_ptr_4(out0);
	struct map_to_arr_0__lambda0* temp0;
	uint8_t* _2 = alloc(ctx, sizeof(struct map_to_arr_0__lambda0));
	temp0 = ((struct map_to_arr_0__lambda0*) _2);
	
	*temp0 = (struct map_to_arr_0__lambda0) {f};
	end1 = fold_7(ctx, _1, a, (struct fun_act3_2) {0, .as0 = temp0});
	
	struct arrow_0* _3 = end_ptr_5(out0);
	assert_0(ctx, (end1 == _3));
	return cast_immutable_1(out0);
}
/* size<k, v> nat64(a mut-dict<str, arr<str>>) */
uint64_t size_6(struct ctx* ctx, struct mut_dict_0* a) {
	return a->total_size;
}
/* fold<mut-ptr<out>, k, v> mut-ptr<arrow<str, arr<str>>>(acc mut-ptr<arrow<str, arr<str>>>, a mut-dict<str, arr<str>>, f fun-act3<mut-ptr<arrow<str, arr<str>>>, mut-ptr<arrow<str, arr<str>>>, str, arr<str>>) */
struct arrow_0* fold_7(struct ctx* ctx, struct arrow_0* acc, struct mut_dict_0* a, struct fun_act3_2 f) {
	struct fold_7__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct fold_7__lambda0));
	temp0 = ((struct fold_7__lambda0*) _0);
	
	*temp0 = (struct fold_7__lambda0) {f};
	return fold_8(ctx, acc, a->entries, (struct fun_act2_7) {0, .as0 = temp0});
}
/* fold<a, entry<k, v>> mut-ptr<arrow<str, arr<str>>>(acc mut-ptr<arrow<str, arr<str>>>, a fix-arr<entry<str, arr<str>>>, f fun-act2<mut-ptr<arrow<str, arr<str>>>, mut-ptr<arrow<str, arr<str>>>, entry<str, arr<str>>>) */
struct arrow_0* fold_8(struct ctx* ctx, struct arrow_0* acc, struct fix_arr_5 a, struct fun_act2_7 f) {
	struct arr_11 _0 = temp_as_arr_2(a);
	return fold_9(ctx, acc, _0, f);
}
/* fold<a, b> mut-ptr<arrow<str, arr<str>>>(acc mut-ptr<arrow<str, arr<str>>>, a arr<entry<str, arr<str>>>, f fun-act2<mut-ptr<arrow<str, arr<str>>>, mut-ptr<arrow<str, arr<str>>>, entry<str, arr<str>>>) */
struct arrow_0* fold_9(struct ctx* ctx, struct arrow_0* acc, struct arr_11 a, struct fun_act2_7 f) {
	struct entry_0* _0 = end_ptr_4(a);
	return fold_recur_4(ctx, acc, a.begin_ptr, _0, f);
}
/* fold-recur<a, b> mut-ptr<arrow<str, arr<str>>>(acc mut-ptr<arrow<str, arr<str>>>, cur const-ptr<entry<str, arr<str>>>, end const-ptr<entry<str, arr<str>>>, f fun-act2<mut-ptr<arrow<str, arr<str>>>, mut-ptr<arrow<str, arr<str>>>, entry<str, arr<str>>>) */
struct arrow_0* fold_recur_4(struct ctx* ctx, struct arrow_0* acc, struct entry_0* cur, struct entry_0* end, struct fun_act2_7 f) {
	top:;
	uint8_t _0 = _equal_8(cur, end);
	if (_0) {
		return acc;
	} else {
		struct entry_0 _1 = _times_13(cur);
		struct arrow_0* _2 = subscript_57(ctx, f, acc, _1);
		struct entry_0* _3 = _plus_11(cur, 1u);
		acc = _2;
		cur = _3;
		end = end;
		f = f;
		goto top;
	}
}
/* subscript<a, a, b> mut-ptr<arrow<str, arr<str>>>(a fun-act2<mut-ptr<arrow<str, arr<str>>>, mut-ptr<arrow<str, arr<str>>>, entry<str, arr<str>>>, p0 mut-ptr<arrow<str, arr<str>>>, p1 entry<str, arr<str>>) */
struct arrow_0* subscript_57(struct ctx* ctx, struct fun_act2_7 a, struct arrow_0* p0, struct entry_0 p1) {
	return call_w_ctx_706(a, ctx, p0, p1);
}
/* call-w-ctx<raw-ptr-mut(arrow<str, arr<str>>), raw-ptr-mut(arrow<str, arr<str>>), entry<str, arr<str>>> (generated) (generated) */
struct arrow_0* call_w_ctx_706(struct fun_act2_7 a, struct ctx* ctx, struct arrow_0* p0, struct entry_0 p1) {
	struct fun_act2_7 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct fold_7__lambda0* closure0 = _0.as0;
			
			return fold_7__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return NULL;;
	}
}
/* subscript<a, a, k, v> mut-ptr<arrow<str, arr<str>>>(a fun-act3<mut-ptr<arrow<str, arr<str>>>, mut-ptr<arrow<str, arr<str>>>, str, arr<str>>, p0 mut-ptr<arrow<str, arr<str>>>, p1 str, p2 arr<str>) */
struct arrow_0* subscript_58(struct ctx* ctx, struct fun_act3_2 a, struct arrow_0* p0, struct str p1, struct arr_2 p2) {
	return call_w_ctx_708(a, ctx, p0, p1, p2);
}
/* call-w-ctx<raw-ptr-mut(arrow<str, arr<str>>), raw-ptr-mut(arrow<str, arr<str>>), str, arr<str>> (generated) (generated) */
struct arrow_0* call_w_ctx_708(struct fun_act3_2 a, struct ctx* ctx, struct arrow_0* p0, struct str p1, struct arr_2 p2) {
	struct fun_act3_2 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct map_to_arr_0__lambda0* closure0 = _0.as0;
			
			return map_to_arr_0__lambda0(ctx, closure0, p0, p1, p2);
		}
		default:
			
	return NULL;;
	}
}
/* fold<a, arrow<k, v>> mut-ptr<arrow<str, arr<str>>>(acc mut-ptr<arrow<str, arr<str>>>, a mut-arr<arrow<str, arr<str>>>, f fun-act2<mut-ptr<arrow<str, arr<str>>>, mut-ptr<arrow<str, arr<str>>>, arrow<str, arr<str>>>) */
struct arrow_0* fold_10(struct ctx* ctx, struct arrow_0* acc, struct mut_arr_2* a, struct fun_act2_8 f) {
	struct arr_10 _0 = temp_as_arr_3(a);
	return fold_11(ctx, acc, _0, f);
}
/* fold<a, b> mut-ptr<arrow<str, arr<str>>>(acc mut-ptr<arrow<str, arr<str>>>, a arr<arrow<str, arr<str>>>, f fun-act2<mut-ptr<arrow<str, arr<str>>>, mut-ptr<arrow<str, arr<str>>>, arrow<str, arr<str>>>) */
struct arrow_0* fold_11(struct ctx* ctx, struct arrow_0* acc, struct arr_10 a, struct fun_act2_8 f) {
	struct arrow_0* _0 = end_ptr_2(a);
	return fold_recur_5(ctx, acc, a.begin_ptr, _0, f);
}
/* fold-recur<a, b> mut-ptr<arrow<str, arr<str>>>(acc mut-ptr<arrow<str, arr<str>>>, cur const-ptr<arrow<str, arr<str>>>, end const-ptr<arrow<str, arr<str>>>, f fun-act2<mut-ptr<arrow<str, arr<str>>>, mut-ptr<arrow<str, arr<str>>>, arrow<str, arr<str>>>) */
struct arrow_0* fold_recur_5(struct ctx* ctx, struct arrow_0* acc, struct arrow_0* cur, struct arrow_0* end, struct fun_act2_8 f) {
	top:;
	uint8_t _0 = _equal_6(cur, end);
	if (_0) {
		return acc;
	} else {
		struct arrow_0 _1 = _times_11(cur);
		struct arrow_0* _2 = subscript_59(ctx, f, acc, _1);
		struct arrow_0* _3 = _plus_9(cur, 1u);
		acc = _2;
		cur = _3;
		end = end;
		f = f;
		goto top;
	}
}
/* subscript<a, a, b> mut-ptr<arrow<str, arr<str>>>(a fun-act2<mut-ptr<arrow<str, arr<str>>>, mut-ptr<arrow<str, arr<str>>>, arrow<str, arr<str>>>, p0 mut-ptr<arrow<str, arr<str>>>, p1 arrow<str, arr<str>>) */
struct arrow_0* subscript_59(struct ctx* ctx, struct fun_act2_8 a, struct arrow_0* p0, struct arrow_0 p1) {
	return call_w_ctx_713(a, ctx, p0, p1);
}
/* call-w-ctx<raw-ptr-mut(arrow<str, arr<str>>), raw-ptr-mut(arrow<str, arr<str>>), arrow<str, arr<str>>> (generated) (generated) */
struct arrow_0* call_w_ctx_713(struct fun_act2_8 a, struct ctx* ctx, struct arrow_0* p0, struct arrow_0 p1) {
	struct fun_act2_8 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct fold_7__lambda0__lambda0* closure0 = _0.as0;
			
			return fold_7__lambda0__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return NULL;;
	}
}
/* fold<mut-ptr<out>, k, v>.lambda0.lambda0 mut-ptr<arrow<str, arr<str>>>(cur2 mut-ptr<arrow<str, arr<str>>>, pair arrow<str, arr<str>>) */
struct arrow_0* fold_7__lambda0__lambda0(struct ctx* ctx, struct fold_7__lambda0__lambda0* _closure, struct arrow_0* cur2, struct arrow_0 pair) {
	return subscript_58(ctx, _closure->f, cur2, pair.from, pair.to);
}
/* fold<mut-ptr<out>, k, v>.lambda0 mut-ptr<arrow<str, arr<str>>>(cur mut-ptr<arrow<str, arr<str>>>, entry entry<str, arr<str>>) */
struct arrow_0* fold_7__lambda0(struct ctx* ctx, struct fold_7__lambda0* _closure, struct arrow_0* cur, struct entry_0 entry) {
	struct entry_0 _0 = entry;
	switch (_0.kind) {
		case 0: {
			return cur;
		}
		case 1: {
			struct arrow_0 ar0 = _0.as1;
			
			return subscript_58(ctx, _closure->f, cur, ar0.from, ar0.to);
		}
		case 2: {
			struct mut_arr_2* m1 = _0.as2;
			
			struct fold_7__lambda0__lambda0* temp0;
			uint8_t* _1 = alloc(ctx, sizeof(struct fold_7__lambda0__lambda0));
			temp0 = ((struct fold_7__lambda0__lambda0*) _1);
			
			*temp0 = (struct fold_7__lambda0__lambda0) {_closure->f};
			return fold_10(ctx, cur, m1, (struct fun_act2_8) {0, .as0 = temp0});
		}
		default:
			
	return NULL;;
	}
}
/* subscript<out, k, v> arrow<str, arr<str>>(a fun-act2<arrow<str, arr<str>>, str, arr<str>>, p0 str, p1 arr<str>) */
struct arrow_0 subscript_60(struct ctx* ctx, struct fun_act2_6 a, struct str p0, struct arr_2 p1) {
	return call_w_ctx_717(a, ctx, p0, p1);
}
/* call-w-ctx<arrow<str, arr<str>>, str, arr<str>> (generated) (generated) */
struct arrow_0 call_w_ctx_717(struct fun_act2_6 a, struct ctx* ctx, struct str p0, struct arr_2 p1) {
	struct fun_act2_6 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return move_to_dict__e_0__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return (struct arrow_0) {(struct str) {(struct arr_0) {0, NULL}}, (struct arr_2) {0, NULL}};;
	}
}
/* map-to-arr<arrow<k, v>, k, v>.lambda0 mut-ptr<arrow<str, arr<str>>>(cur mut-ptr<arrow<str, arr<str>>>, key str, value arr<str>) */
struct arrow_0* map_to_arr_0__lambda0(struct ctx* ctx, struct map_to_arr_0__lambda0* _closure, struct arrow_0* cur, struct str key, struct arr_2 value) {
	struct arrow_0 _0 = subscript_60(ctx, _closure->f, key, value);
	*cur = _0;
	return (cur + 1u);
}
/* end-ptr<out> mut-ptr<arrow<str, arr<str>>>(a fix-arr<arrow<str, arr<str>>>) */
struct arrow_0* end_ptr_5(struct fix_arr_3 a) {
	struct arrow_0* _0 = begin_ptr_4(a);
	uint64_t _1 = size_3(a);
	return (_0 + _1);
}
/* move-to-dict!<str, arr<str>>.lambda0 arrow<str, arr<str>>(k str, v arr<str>) */
struct arrow_0 move_to_dict__e_0__lambda0(struct ctx* ctx, struct void_ _closure, struct str k, struct arr_2 v) {
	return _arrow_0(k, v);
}
/* empty!<k, v> void(a mut-dict<str, arr<str>>) */
struct void_ empty__e_0(struct ctx* ctx, struct mut_dict_0* a) {
	fill__e_0(ctx, a->entries, (struct entry_0) {0, .as0 = (struct none) {}});
	return (a->total_size = 0u, (struct void_) {});
}
/* fill!<entry<k, v>> void(a fix-arr<entry<str, arr<str>>>, value entry<str, arr<str>>) */
struct void_ fill__e_0(struct ctx* ctx, struct fix_arr_5 a, struct entry_0 value) {
	struct fill__e_0__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct fill__e_0__lambda0));
	temp0 = ((struct fill__e_0__lambda0*) _0);
	
	*temp0 = (struct fill__e_0__lambda0) {value};
	return map__e_0(ctx, a, (struct fun_act1_15) {0, .as0 = temp0});
}
/* map!<a> void(a fix-arr<entry<str, arr<str>>>, f fun-act1<entry<str, arr<str>>, entry<str, arr<str>>>) */
struct void_ map__e_0(struct ctx* ctx, struct fix_arr_5 a, struct fun_act1_15 f) {
	struct entry_0* _0 = begin_ptr_6(a);
	struct entry_0* _1 = end_ptr_6(a);
	return map_recur__e_0(ctx, _0, _1, f);
}
/* map-recur!<a> void(cur mut-ptr<entry<str, arr<str>>>, end mut-ptr<entry<str, arr<str>>>, f fun-act1<entry<str, arr<str>>, entry<str, arr<str>>>) */
struct void_ map_recur__e_0(struct ctx* ctx, struct entry_0* cur, struct entry_0* end, struct fun_act1_15 f) {
	top:;
	uint8_t _0 = _notEqual_10(cur, end);
	if (_0) {
		struct entry_0 _1 = subscript_61(ctx, f, (*cur));
		*cur = _1;
		cur = (cur + 1u);
		end = end;
		f = f;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* !=<mut-ptr<a>> bool(a mut-ptr<entry<str, arr<str>>>, b mut-ptr<entry<str, arr<str>>>) */
uint8_t _notEqual_10(struct entry_0* a, struct entry_0* b) {
	return _not((a == b));
}
/* subscript<a, a> entry<str, arr<str>>(a fun-act1<entry<str, arr<str>>, entry<str, arr<str>>>, p0 entry<str, arr<str>>) */
struct entry_0 subscript_61(struct ctx* ctx, struct fun_act1_15 a, struct entry_0 p0) {
	return call_w_ctx_727(a, ctx, p0);
}
/* call-w-ctx<entry<str, arr<str>>, entry<str, arr<str>>> (generated) (generated) */
struct entry_0 call_w_ctx_727(struct fun_act1_15 a, struct ctx* ctx, struct entry_0 p0) {
	struct fun_act1_15 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct fill__e_0__lambda0* closure0 = _0.as0;
			
			return fill__e_0__lambda0(ctx, closure0, p0);
		}
		default:
			
	return (struct entry_0) {0};;
	}
}
/* end-ptr<a> mut-ptr<entry<str, arr<str>>>(a fix-arr<entry<str, arr<str>>>) */
struct entry_0* end_ptr_6(struct fix_arr_5 a) {
	struct entry_0* _0 = begin_ptr_6(a);
	uint64_t _1 = size_5(a);
	return (_0 + _1);
}
/* fill!<entry<k, v>>.lambda0 entry<str, arr<str>>(ignore entry<str, arr<str>>) */
struct entry_0 fill__e_0__lambda0(struct ctx* ctx, struct fill__e_0__lambda0* _closure, struct entry_0 ignore) {
	return _closure->value;
}
/* assert void(condition bool, message str) */
struct void_ assert_1(struct ctx* ctx, uint8_t condition, struct str message) {
	uint8_t _0 = _not(condition);
	if (_0) {
		return throw_0(ctx, message);
	} else {
		return (struct void_) {};
	}
}
/* fill-mut-arr<opt<arr<str>>> mut-arr<opt<arr<str>>>(size nat64, value opt<arr<str>>) */
struct mut_arr_3* fill_mut_arr(struct ctx* ctx, uint64_t size, struct opt_12 value) {
	struct fix_arr_6 backing0;
	backing0 = fill_fix_arr_2(ctx, size, value);
	
	struct mut_arr_3* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_arr_3));
	temp0 = ((struct mut_arr_3*) _0);
	
	*temp0 = (struct mut_arr_3) {backing0, size};
	return temp0;
}
/* fill-fix-arr<a> fix-arr<opt<arr<str>>>(size nat64, value opt<arr<str>>) */
struct fix_arr_6 fill_fix_arr_2(struct ctx* ctx, uint64_t size, struct opt_12 value) {
	struct fill_fix_arr_2__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct fill_fix_arr_2__lambda0));
	temp0 = ((struct fill_fix_arr_2__lambda0*) _0);
	
	*temp0 = (struct fill_fix_arr_2__lambda0) {value};
	return make_fix_arr_2(ctx, size, (struct fun_act1_16) {0, .as0 = temp0});
}
/* make-fix-arr<a> fix-arr<opt<arr<str>>>(size nat64, f fun-act1<opt<arr<str>>, nat64>) */
struct fix_arr_6 make_fix_arr_2(struct ctx* ctx, uint64_t size, struct fun_act1_16 f) {
	struct fix_arr_6 res0;
	res0 = uninitialized_fix_arr_4(ctx, size);
	
	struct opt_12* _0 = begin_ptr_8(res0);
	fill_ptr_range_3(ctx, _0, size, f);
	return res0;
}
/* uninitialized-fix-arr<a> fix-arr<opt<arr<str>>>(size nat64) */
struct fix_arr_6 uninitialized_fix_arr_4(struct ctx* ctx, uint64_t size) {
	struct opt_12* _0 = alloc_uninitialized_5(ctx, size);
	return fix_arr_10(size, _0);
}
/* fix-arr<a> fix-arr<opt<arr<str>>>(size nat64, begin-ptr mut-ptr<opt<arr<str>>>) */
struct fix_arr_6 fix_arr_10(uint64_t size, struct opt_12* begin_ptr) {
	return (struct fix_arr_6) {(struct void_) {}, (struct arr_8) {size, ((struct opt_12*) begin_ptr)}};
}
/* alloc-uninitialized<a> mut-ptr<opt<arr<str>>>(size nat64) */
struct opt_12* alloc_uninitialized_5(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(struct opt_12)));
	return ((struct opt_12*) _0);
}
/* fill-ptr-range<a> void(begin mut-ptr<opt<arr<str>>>, size nat64, f fun-act1<opt<arr<str>>, nat64>) */
struct void_ fill_ptr_range_3(struct ctx* ctx, struct opt_12* begin, uint64_t size, struct fun_act1_16 f) {
	return fill_ptr_range_recur_3(ctx, begin, 0u, size, f);
}
/* fill-ptr-range-recur<a> void(begin mut-ptr<opt<arr<str>>>, i nat64, size nat64, f fun-act1<opt<arr<str>>, nat64>) */
struct void_ fill_ptr_range_recur_3(struct ctx* ctx, struct opt_12* begin, uint64_t i, uint64_t size, struct fun_act1_16 f) {
	top:;
	uint8_t _0 = _notEqual_5(i, size);
	if (_0) {
		struct opt_12 _1 = subscript_62(ctx, f, i);
		set_subscript_11(begin, i, _1);
		begin = begin;
		i = (i + 1u);
		size = size;
		f = f;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* set-subscript<a> void(a mut-ptr<opt<arr<str>>>, n nat64, value opt<arr<str>>) */
struct void_ set_subscript_11(struct opt_12* a, uint64_t n, struct opt_12 value) {
	return (*(a + n) = value, (struct void_) {});
}
/* subscript<a, nat64> opt<arr<str>>(a fun-act1<opt<arr<str>>, nat64>, p0 nat64) */
struct opt_12 subscript_62(struct ctx* ctx, struct fun_act1_16 a, uint64_t p0) {
	return call_w_ctx_741(a, ctx, p0);
}
/* call-w-ctx<opt<arr<str>>, nat-64> (generated) (generated) */
struct opt_12 call_w_ctx_741(struct fun_act1_16 a, struct ctx* ctx, uint64_t p0) {
	struct fun_act1_16 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct fill_fix_arr_2__lambda0* closure0 = _0.as0;
			
			return fill_fix_arr_2__lambda0(ctx, closure0, p0);
		}
		default:
			
	return (struct opt_12) {0};;
	}
}
/* begin-ptr<a> mut-ptr<opt<arr<str>>>(a fix-arr<opt<arr<str>>>) */
struct opt_12* begin_ptr_8(struct fix_arr_6 a) {
	return ((struct opt_12*) a.inner.begin_ptr);
}
/* fill-fix-arr<a>.lambda0 opt<arr<str>>(ignore nat64) */
struct opt_12 fill_fix_arr_2__lambda0(struct ctx* ctx, struct fill_fix_arr_2__lambda0* _closure, uint64_t ignore) {
	return _closure->value;
}
/* each<str, arr<str>> void(a dict<str, arr<str>>, f fun-act2<void, str, arr<str>>) */
struct void_ each_4(struct ctx* ctx, struct dict_0 a, struct fun_act2_3 f) {
	struct each_4__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct each_4__lambda0));
	temp0 = ((struct each_4__lambda0*) _0);
	
	*temp0 = (struct each_4__lambda0) {f};
	return fold_12(ctx, (struct void_) {}, a, (struct fun_act3_1) {1, .as1 = temp0});
}
/* fold<void, k, v> void(acc void, a dict<str, arr<str>>, f fun-act3<void, void, str, arr<str>>) */
struct void_ fold_12(struct ctx* ctx, struct void_ acc, struct dict_0 a, struct fun_act3_1 f) {
	return fold_recur_6(ctx, acc, a.root, f);
}
/* fold-recur<a, k, v> void(acc void, a node<str, arr<str>>, f fun-act3<void, void, str, arr<str>>) */
struct void_ fold_recur_6(struct ctx* ctx, struct void_ acc, struct node_0 a, struct fun_act3_1 f) {
	struct node_0 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct inner_node_0 i0 = _0.as0;
			
			struct fold_recur_6__lambda0* temp0;
			uint8_t* _1 = alloc(ctx, sizeof(struct fold_recur_6__lambda0));
			temp0 = ((struct fold_recur_6__lambda0*) _1);
			
			*temp0 = (struct fold_recur_6__lambda0) {f};
			return fold_13(ctx, acc, i0.children, (struct fun_act2_9) {0, .as0 = temp0});
		}
		case 1: {
			struct leaf_node_0 l1 = _0.as1;
			
			struct fold_recur_6__lambda1* temp1;
			uint8_t* _2 = alloc(ctx, sizeof(struct fold_recur_6__lambda1));
			temp1 = ((struct fold_recur_6__lambda1*) _2);
			
			*temp1 = (struct fold_recur_6__lambda1) {f};
			return fold_6(ctx, acc, l1.pairs, (struct fun_act2_5) {1, .as1 = temp1});
		}
		default:
			
	return (struct void_) {};;
	}
}
/* fold<a, node<k, v>> void(acc void, a arr<node<str, arr<str>>>, f fun-act2<void, void, node<str, arr<str>>>) */
struct void_ fold_13(struct ctx* ctx, struct void_ acc, struct arr_9 a, struct fun_act2_9 f) {
	struct node_0* _0 = end_ptr_3(a);
	return fold_recur_7(ctx, acc, a.begin_ptr, _0, f);
}
/* fold-recur<a, b> void(acc void, cur const-ptr<node<str, arr<str>>>, end const-ptr<node<str, arr<str>>>, f fun-act2<void, void, node<str, arr<str>>>) */
struct void_ fold_recur_7(struct ctx* ctx, struct void_ acc, struct node_0* cur, struct node_0* end, struct fun_act2_9 f) {
	top:;
	uint8_t _0 = _equal_7(cur, end);
	if (_0) {
		return acc;
	} else {
		struct node_0 _1 = _times_12(cur);
		struct void_ _2 = subscript_63(ctx, f, acc, _1);
		struct node_0* _3 = _plus_10(cur, 1u);
		acc = _2;
		cur = _3;
		end = end;
		f = f;
		goto top;
	}
}
/* subscript<a, a, b> void(a fun-act2<void, void, node<str, arr<str>>>, p0 void, p1 node<str, arr<str>>) */
struct void_ subscript_63(struct ctx* ctx, struct fun_act2_9 a, struct void_ p0, struct node_0 p1) {
	return call_w_ctx_750(a, ctx, p0, p1);
}
/* call-w-ctx<void, void, node<str, arr<str>>> (generated) (generated) */
struct void_ call_w_ctx_750(struct fun_act2_9 a, struct ctx* ctx, struct void_ p0, struct node_0 p1) {
	struct fun_act2_9 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct fold_recur_6__lambda0* closure0 = _0.as0;
			
			return fold_recur_6__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* fold-recur<a, k, v>.lambda0 void(cur void, child node<str, arr<str>>) */
struct void_ fold_recur_6__lambda0(struct ctx* ctx, struct fold_recur_6__lambda0* _closure, struct void_ cur, struct node_0 child) {
	return fold_recur_6(ctx, cur, child, _closure->f);
}
/* fold-recur<a, k, v>.lambda1 void(cur void, pair arrow<str, arr<str>>) */
struct void_ fold_recur_6__lambda1(struct ctx* ctx, struct fold_recur_6__lambda1* _closure, struct void_ cur, struct arrow_0 pair) {
	return subscript_52(ctx, _closure->f, cur, pair.from, pair.to);
}
/* each<str, arr<str>>.lambda0 void(ignore void, key str, value arr<str>) */
struct void_ each_4__lambda0(struct ctx* ctx, struct each_4__lambda0* _closure, struct void_ ignore, struct str key, struct arr_2 value) {
	return subscript_54(ctx, _closure->f, key, value);
}
/* index-of<str> opt<nat64>(a arr<str>, value str) */
struct opt_11 index_of(struct ctx* ctx, struct arr_2 a, struct str value) {
	struct opt_18 _0 = ptr_of(ctx, a, value);
	switch (_0.kind) {
		case 0: {
			return (struct opt_11) {0, .as0 = (struct none) {}};
		}
		case 1: {
			struct some_18 _matched0 = _0.as1;
			
			struct str* v1;
			v1 = _matched0.value;
			
			uint64_t _1 = _minus_6(v1, a.begin_ptr);
			return (struct opt_11) {1, .as1 = (struct some_11) {_1}};
		}
		default:
			
	return (struct opt_11) {0};;
	}
}
/* ptr-of<a> opt<const-ptr<str>>(a arr<str>, value str) */
struct opt_18 ptr_of(struct ctx* ctx, struct arr_2 a, struct str value) {
	struct str* _0 = end_ptr_7(a);
	return ptr_of_recur(ctx, a.begin_ptr, _0, value);
}
/* ptr-of-recur<a> opt<const-ptr<str>>(cur const-ptr<str>, end const-ptr<str>, value str) */
struct opt_18 ptr_of_recur(struct ctx* ctx, struct str* cur, struct str* end, struct str value) {
	top:;
	uint8_t _0 = _equal_9(cur, end);
	if (_0) {
		return (struct opt_18) {0, .as0 = (struct none) {}};
	} else {
		struct str _1 = _times_10(cur);
		uint8_t _2 = _equal_5(_1, value);
		if (_2) {
			return (struct opt_18) {1, .as1 = (struct some_18) {cur}};
		} else {
			struct str* _3 = _plus_8(cur, 1u);
			cur = _3;
			end = end;
			value = value;
			goto top;
		}
	}
}
/* ==<a> bool(a const-ptr<str>, b const-ptr<str>) */
uint8_t _equal_9(struct str* a, struct str* b) {
	return (((struct str*) a) == ((struct str*) b));
}
/* end-ptr<a> const-ptr<str>(a arr<str>) */
struct str* end_ptr_7(struct arr_2 a) {
	return _plus_8(a.begin_ptr, a.size);
}
/* -<a> nat64(a const-ptr<str>, b const-ptr<str>) */
uint64_t _minus_6(struct str* a, struct str* b) {
	return _minus_7(((struct str*) a), ((struct str*) b));
}
/* -<a> nat64(a mut-ptr<str>, b mut-ptr<str>) */
uint64_t _minus_7(struct str* a, struct str* b) {
	return ((((uint64_t) a) - ((uint64_t) b)) / sizeof(struct str));
}
/* set-deref<bool> void(a cell<bool>, value bool) */
struct void_ set_deref_0(struct cell_3* a, uint8_t value) {
	return (a->inner_value = value, (struct void_) {});
}
/* finish str(a interp) */
struct str finish(struct ctx* ctx, struct interp a) {
	struct arr_0 _0 = move_to_arr__e_0(a.inner);
	return (struct str) {_0};
}
/* to-str str(a str) */
struct str to_str_3(struct ctx* ctx, struct str a) {
	return a;
}
/* with-value<str> interp(a interp, b str) */
struct interp with_value_0(struct ctx* ctx, struct interp a, struct str b) {
	struct str _0 = to_str_3(ctx, b);
	return with_str(ctx, a, _0);
}
/* with-str interp(a interp, b str) */
struct interp with_str(struct ctx* ctx, struct interp a, struct str b) {
	_concatEquals_1(ctx, a.inner, b.chars);
	return a;
}
/* interp interp() */
struct interp interp(struct ctx* ctx) {
	struct mut_arr_1* _0 = mut_arr_0(ctx);
	return (struct interp) {_0};
}
/* is-empty<arr<str>> bool(a opt<arr<str>>) */
uint8_t is_empty_10(struct opt_12 a) {
	struct opt_12 _0 = a;
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
/* subscript<opt<arr<str>>> opt<arr<str>>(a mut-arr<opt<arr<str>>>, index nat64) */
struct opt_12 subscript_64(struct ctx* ctx, struct mut_arr_3* a, uint64_t index) {
	uint8_t _0 = _less_0(index, a->size);
	assert_0(ctx, _0);
	struct opt_12* _1 = begin_ptr_9(a);
	return subscript_65(_1, index);
}
/* subscript<a> opt<arr<str>>(a mut-ptr<opt<arr<str>>>, n nat64) */
struct opt_12 subscript_65(struct opt_12* a, uint64_t n) {
	return (*(a + n));
}
/* begin-ptr<a> mut-ptr<opt<arr<str>>>(a mut-arr<opt<arr<str>>>) */
struct opt_12* begin_ptr_9(struct mut_arr_3* a) {
	return begin_ptr_8(a->backing);
}
/* set-subscript<opt<arr<str>>> void(a mut-arr<opt<arr<str>>>, index nat64, value opt<arr<str>>) */
struct void_ set_subscript_12(struct ctx* ctx, struct mut_arr_3* a, uint64_t index, struct opt_12 value) {
	uint8_t _0 = _less_0(index, a->size);
	assert_0(ctx, _0);
	struct opt_12* _1 = begin_ptr_9(a);
	return set_subscript_11(_1, index, value);
}
/* parse-named-args.lambda0 void(key str, value arr<str>) */
struct void_ parse_named_args_0__lambda0(struct ctx* ctx, struct parse_named_args_0__lambda0* _closure, struct str key, struct arr_2 value) {
	struct opt_11 _0 = index_of(ctx, _closure->arg_names, key);
	switch (_0.kind) {
		case 0: {
			uint8_t _1 = _equal_5(key, (struct str) {{4, constantarr_0_18}});
			if (_1) {
				return set_deref_0(_closure->help, 1);
			} else {
				struct interp _2 = interp(ctx);
				struct interp _3 = with_str(ctx, _2, (struct str) {{15, constantarr_0_19}});
				struct interp _4 = with_value_0(ctx, _3, key);
				struct str _5 = finish(ctx, _4);
				return throw_0(ctx, _5);
			}
		}
		case 1: {
			struct some_11 _matched0 = _0.as1;
			
			uint64_t index1;
			index1 = _matched0.value;
			
			struct opt_12 _6 = subscript_64(ctx, _closure->values, index1);
			uint8_t _7 = is_empty_10(_6);
			assert_0(ctx, _7);
			return set_subscript_12(ctx, _closure->values, index1, (struct opt_12) {1, .as1 = (struct some_12) {value}});
		}
		default:
			
	return (struct void_) {};;
	}
}
/* *<bool> bool(a cell<bool>) */
uint8_t _times_14(struct cell_3* a) {
	return a->inner_value;
}
/* move-to-arr!<opt<arr<str>>> arr<opt<arr<str>>>(a mut-arr<opt<arr<str>>>) */
struct arr_8 move_to_arr__e_1(struct mut_arr_3* a) {
	struct fix_arr_6 _0 = move_to_fix_arr__e_1(a);
	return cast_immutable_3(_0);
}
/* cast-immutable<a> arr<opt<arr<str>>>(a fix-arr<opt<arr<str>>>) */
struct arr_8 cast_immutable_3(struct fix_arr_6 a) {
	return a.inner;
}
/* move-to-fix-arr!<a> fix-arr<opt<arr<str>>>(a mut-arr<opt<arr<str>>>) */
struct fix_arr_6 move_to_fix_arr__e_1(struct mut_arr_3* a) {
	struct fix_arr_6 res0;
	struct opt_12* _0 = begin_ptr_9(a);
	res0 = fix_arr_10(a->size, _0);
	
	struct fix_arr_6 _1 = fix_arr_11();
	a->backing = _1;
	a->size = 0u;
	return res0;
}
/* fix-arr<a> fix-arr<opt<arr<str>>>() */
struct fix_arr_6 fix_arr_11(void) {
	return (struct fix_arr_6) {(struct void_) {}, (struct arr_8) {0u, NULL}};
}
/* print-help void() */
struct void_ print_help(struct ctx* ctx) {
	print((struct str) {{18, constantarr_0_20}});
	print((struct str) {{8, constantarr_0_21}});
	print((struct str) {{36, constantarr_0_22}});
	return print((struct str) {{63, constantarr_0_23}});
}
/* subscript<opt<arr<str>>> opt<arr<str>>(a arr<opt<arr<str>>>, index nat64) */
struct opt_12 subscript_66(struct ctx* ctx, struct arr_8 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	return unsafe_at_9(a, index);
}
/* unsafe-at<a> opt<arr<str>>(a arr<opt<arr<str>>>, index nat64) */
struct opt_12 unsafe_at_9(struct arr_8 a, uint64_t index) {
	return subscript_67(a.begin_ptr, index);
}
/* subscript<a> opt<arr<str>>(a const-ptr<opt<arr<str>>>, n nat64) */
struct opt_12 subscript_67(struct opt_12* a, uint64_t n) {
	struct opt_12* _0 = _plus_12(a, n);
	return _times_15(_0);
}
/* *<a> opt<arr<str>>(a const-ptr<opt<arr<str>>>) */
struct opt_12 _times_15(struct opt_12* a) {
	return (*((struct opt_12*) a));
}
/* +<a> const-ptr<opt<arr<str>>>(a const-ptr<opt<arr<str>>>, offset nat64) */
struct opt_12* _plus_12(struct opt_12* a, uint64_t offset) {
	return ((struct opt_12*) (((struct opt_12*) a) + offset));
}
/* parse-nat opt<nat64>(a str) */
struct opt_11 parse_nat(struct ctx* ctx, struct str a) {
	return with_reader(ctx, a, (struct fun_act1_17) {0, .as0 = (struct void_) {}});
}
/* with-reader<nat64> opt<nat64>(a str, f fun-act1<opt<nat64>, reader>) */
struct opt_11 with_reader(struct ctx* ctx, struct str a, struct fun_act1_17 f) {
	struct reader* reader0;
	reader0 = reader(ctx, a);
	
	struct opt_11 res1;
	res1 = subscript_68(ctx, f, reader0);
	
	uint8_t _0 = is_empty_11(res1);
	uint8_t _1 = _not(_0);uint8_t _2;
	
	if (_1) {
		_2 = is_empty_12(ctx, reader0);
	} else {
		_2 = 0;
	}
	if (_2) {
		return res1;
	} else {
		return (struct opt_11) {0, .as0 = (struct none) {}};
	}
}
/* reader reader(a str) */
struct reader* reader(struct ctx* ctx, struct str a) {
	struct reader* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct reader));
	temp0 = ((struct reader*) _0);
	
	char* _1 = end_ptr_0(a.chars);
	*temp0 = (struct reader) {a.chars.begin_ptr, _1};
	return temp0;
}
/* subscript<opt<a>, reader> opt<nat64>(a fun-act1<opt<nat64>, reader>, p0 reader) */
struct opt_11 subscript_68(struct ctx* ctx, struct fun_act1_17 a, struct reader* p0) {
	return call_w_ctx_788(a, ctx, p0);
}
/* call-w-ctx<opt<nat64>, gc-ptr(reader)> (generated) (generated) */
struct opt_11 call_w_ctx_788(struct fun_act1_17 a, struct ctx* ctx, struct reader* p0) {
	struct fun_act1_17 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return parse_nat__lambda0(ctx, closure0, p0);
		}
		default:
			
	return (struct opt_11) {0};;
	}
}
/* is-empty<a> bool(a opt<nat64>) */
uint8_t is_empty_11(struct opt_11 a) {
	struct opt_11 _0 = a;
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
/* is-empty bool(a reader) */
uint8_t is_empty_12(struct ctx* ctx, struct reader* a) {
	uint8_t _0 = _lessOrEqual_1(a->cur, a->end);
	assert_0(ctx, _0);
	return _equal_0(a->cur, a->end);
}
/* take-nat! opt<nat64>(a reader) */
struct opt_11 take_nat__e(struct ctx* ctx, struct reader* a) {
	uint8_t _0 = is_empty_12(ctx, a);
	uint8_t _1 = _not(_0);
	if (_1) {
		char _2 = peek(ctx, a);
		struct opt_11 _3 = char_to_nat64(ctx, _2);
		switch (_3.kind) {
			case 0: {
				return (struct opt_11) {0, .as0 = (struct none) {}};
			}
			case 1: {
				struct some_11 _matched0 = _3.as1;
				
				uint64_t first_digit1;
				first_digit1 = _matched0.value;
				
				char _4 = next__e(ctx, a);
				drop_4(_4);
				uint64_t _5 = take_nat_recur__e(ctx, first_digit1, a);
				return (struct opt_11) {1, .as1 = (struct some_11) {_5}};
			}
			default:
				
		return (struct opt_11) {0};;
		}
	} else {
		return (struct opt_11) {0, .as0 = (struct none) {}};
	}
}
/* char-to-nat64 opt<nat64>(c char) */
struct opt_11 char_to_nat64(struct ctx* ctx, char c) {
	uint8_t _0 = _equal_3(c, 48u);
	if (_0) {
		return (struct opt_11) {1, .as1 = (struct some_11) {0u}};
	} else {
		uint8_t _1 = _equal_3(c, 49u);
		if (_1) {
			return (struct opt_11) {1, .as1 = (struct some_11) {1u}};
		} else {
			uint8_t _2 = _equal_3(c, 50u);
			if (_2) {
				return (struct opt_11) {1, .as1 = (struct some_11) {2u}};
			} else {
				uint8_t _3 = _equal_3(c, 51u);
				if (_3) {
					return (struct opt_11) {1, .as1 = (struct some_11) {3u}};
				} else {
					uint8_t _4 = _equal_3(c, 52u);
					if (_4) {
						return (struct opt_11) {1, .as1 = (struct some_11) {4u}};
					} else {
						uint8_t _5 = _equal_3(c, 53u);
						if (_5) {
							return (struct opt_11) {1, .as1 = (struct some_11) {5u}};
						} else {
							uint8_t _6 = _equal_3(c, 54u);
							if (_6) {
								return (struct opt_11) {1, .as1 = (struct some_11) {6u}};
							} else {
								uint8_t _7 = _equal_3(c, 55u);
								if (_7) {
									return (struct opt_11) {1, .as1 = (struct some_11) {7u}};
								} else {
									uint8_t _8 = _equal_3(c, 56u);
									if (_8) {
										return (struct opt_11) {1, .as1 = (struct some_11) {8u}};
									} else {
										uint8_t _9 = _equal_3(c, 57u);
										if (_9) {
											return (struct opt_11) {1, .as1 = (struct some_11) {9u}};
										} else {
											return (struct opt_11) {0, .as0 = (struct none) {}};
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
/* peek char(a reader) */
char peek(struct ctx* ctx, struct reader* a) {
	uint8_t _0 = is_empty_12(ctx, a);
	forbid(ctx, _0);
	return _times_0(a->cur);
}
/* drop<char> void(_ char) */
struct void_ drop_4(char _p0) {
	return (struct void_) {};
}
/* next! char(a reader) */
char next__e(struct ctx* ctx, struct reader* a) {
	uint8_t _0 = is_empty_12(ctx, a);
	forbid(ctx, _0);
	char res0;
	res0 = _times_0(a->cur);
	
	char* _1 = _plus_0(a->cur, 1u);
	a->cur = _1;
	return res0;
}
/* take-nat-recur! nat64(acc nat64, a reader) */
uint64_t take_nat_recur__e(struct ctx* ctx, uint64_t acc, struct reader* a) {
	top:;
	uint8_t _0 = is_empty_12(ctx, a);
	if (_0) {
		return acc;
	} else {
		char _1 = peek(ctx, a);
		struct opt_11 _2 = char_to_nat64(ctx, _1);
		switch (_2.kind) {
			case 0: {
				return acc;
			}
			case 1: {
				struct some_11 _matched0 = _2.as1;
				
				uint64_t v1;
				v1 = _matched0.value;
				
				char _3 = next__e(ctx, a);
				drop_4(_3);
				uint64_t _4 = _times_3(ctx, acc, 10u);
				uint64_t _5 = _plus_3(ctx, _4, v1);
				acc = _5;
				a = a;
				goto top;
			}
			default:
				
		return 0;;
		}
	}
}
/* parse-nat.lambda0 opt<nat64>(r reader) */
struct opt_11 parse_nat__lambda0(struct ctx* ctx, struct void_ _closure, struct reader* r) {
	return take_nat__e(ctx, r);
}
/* do-test nat64(options test-options) */
uint64_t do_test(struct ctx* ctx, struct test_options* options) {
	struct str crow_path0;
	crow_path0 = parent_path(ctx, (struct str) {{6, constantarr_0_24}});
	
	struct str crow_exe1;
	struct str _0 = child_path(ctx, crow_path0, (struct str) {{3, constantarr_0_26}});
	crow_exe1 = child_path(ctx, _0, (struct str) {{4, constantarr_0_27}});
	
	struct dict_1 env2;
	env2 = get_environ(ctx);
	
	struct result_2 crow_failures3;
	struct str _1 = child_path(ctx, (struct str) {{6, constantarr_0_24}}, (struct str) {{12, constantarr_0_83}});
	struct result_2 _2 = run_crow_tests(ctx, _1, crow_exe1, env2, options);
	struct do_test__lambda0* temp0;
	uint8_t* _3 = alloc(ctx, sizeof(struct do_test__lambda0));
	temp0 = ((struct do_test__lambda0*) _3);
	
	*temp0 = (struct do_test__lambda0) {(struct str) {{6, constantarr_0_24}}, crow_exe1, env2, options};
	crow_failures3 = first_failures(ctx, _2, (struct fun0) {1, .as1 = temp0});
	
	struct result_2 all_failures4;
	struct do_test__lambda1* temp1;
	uint8_t* _4 = alloc(ctx, sizeof(struct do_test__lambda1));
	temp1 = ((struct do_test__lambda1*) _4);
	
	*temp1 = (struct do_test__lambda1) {crow_path0, options};
	all_failures4 = first_failures(ctx, crow_failures3, (struct fun0) {2, .as2 = temp1});
	
	return print_failures(ctx, all_failures4, options);
}
/* parent-path str(a str) */
struct str parent_path(struct ctx* ctx, struct str a) {
	struct opt_11 _0 = r_index_of(ctx, a.chars, 47u);
	switch (_0.kind) {
		case 0: {
			return (struct str) {{0u, NULL}};
		}
		case 1: {
			struct some_11 _matched0 = _0.as1;
			
			uint64_t index1;
			index1 = _matched0.value;
			
			struct range _1 = _range(ctx, 0u, index1);
			struct arr_0 _2 = subscript_4(ctx, a.chars, _1);
			return (struct str) {_2};
		}
		default:
			
	return (struct str) {(struct arr_0) {0, NULL}};;
	}
}
/* r-index-of<char> opt<nat64>(a arr<char>, value char) */
struct opt_11 r_index_of(struct ctx* ctx, struct arr_0 a, char value) {
	struct r_index_of__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct r_index_of__lambda0));
	temp0 = ((struct r_index_of__lambda0*) _0);
	
	*temp0 = (struct r_index_of__lambda0) {value};
	return find_rindex(ctx, a, (struct fun_act1_18) {0, .as0 = temp0});
}
/* find-rindex<a> opt<nat64>(a arr<char>, f fun-act1<bool, char>) */
struct opt_11 find_rindex(struct ctx* ctx, struct arr_0 a, struct fun_act1_18 f) {
	uint8_t _0 = is_empty_1(a);
	uint8_t _1 = _not(_0);
	if (_1) {
		uint64_t _2 = _minus_5(ctx, a.size, 1u);
		return find_rindex_recur(ctx, a, _2, f);
	} else {
		return (struct opt_11) {0, .as0 = (struct none) {}};
	}
}
/* find-rindex-recur<a> opt<nat64>(a arr<char>, index nat64, f fun-act1<bool, char>) */
struct opt_11 find_rindex_recur(struct ctx* ctx, struct arr_0 a, uint64_t index, struct fun_act1_18 f) {
	top:;
	char _0 = subscript_70(ctx, a, index);
	uint8_t _1 = subscript_69(ctx, f, _0);
	if (_1) {
		return (struct opt_11) {1, .as1 = (struct some_11) {index}};
	} else {
		uint8_t _2 = _notEqual_5(index, 0u);
		if (_2) {
			uint64_t _3 = _minus_5(ctx, index, 1u);
			a = a;
			index = _3;
			f = f;
			goto top;
		} else {
			return (struct opt_11) {0, .as0 = (struct none) {}};
		}
	}
}
/* subscript<bool, a> bool(a fun-act1<bool, char>, p0 char) */
uint8_t subscript_69(struct ctx* ctx, struct fun_act1_18 a, char p0) {
	return call_w_ctx_804(a, ctx, p0);
}
/* call-w-ctx<bool, char> (generated) (generated) */
uint8_t call_w_ctx_804(struct fun_act1_18 a, struct ctx* ctx, char p0) {
	struct fun_act1_18 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct r_index_of__lambda0* closure0 = _0.as0;
			
			return r_index_of__lambda0(ctx, closure0, p0);
		}
		default:
			
	return 0;;
	}
}
/* subscript<a> char(a arr<char>, index nat64) */
char subscript_70(struct ctx* ctx, struct arr_0 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	return unsafe_at_10(a, index);
}
/* unsafe-at<a> char(a arr<char>, index nat64) */
char unsafe_at_10(struct arr_0 a, uint64_t index) {
	return subscript_71(a.begin_ptr, index);
}
/* subscript<a> char(a const-ptr<char>, n nat64) */
char subscript_71(char* a, uint64_t n) {
	char* _0 = _plus_0(a, n);
	return _times_0(_0);
}
/* r-index-of<char>.lambda0 bool(it char) */
uint8_t r_index_of__lambda0(struct ctx* ctx, struct r_index_of__lambda0* _closure, char it) {
	return _equal_3(it, _closure->value);
}
/* child-path str(a str, child_name str) */
struct str child_path(struct ctx* ctx, struct str a, struct str child_name) {
	struct interp _0 = interp(ctx);
	struct interp _1 = with_value_0(ctx, _0, a);
	struct interp _2 = with_str(ctx, _1, (struct str) {{1, constantarr_0_25}});
	struct interp _3 = with_value_0(ctx, _2, child_name);
	return finish(ctx, _3);
}
/* get-environ dict<str, str>() */
struct dict_1 get_environ(struct ctx* ctx) {
	struct mut_dict_1* res0;
	res0 = mut_dict_1(ctx);
	
	char** _0 = environ;
	get_environ_recur(ctx, _0, res0);
	return move_to_dict__e_1(ctx, res0);
}
/* mut-dict<str, str> mut-dict<str, str>() */
struct mut_dict_1* mut_dict_1(struct ctx* ctx) {
	struct mut_dict_1* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_dict_1));
	temp0 = ((struct mut_dict_1*) _0);
	
	struct fix_arr_8 _1 = fix_arr_12();
	*temp0 = (struct mut_dict_1) {(struct void_) {}, _1, 0u};
	return temp0;
}
/* fix-arr<entry<k, v>> fix-arr<entry<str, str>>() */
struct fix_arr_8 fix_arr_12(void) {
	return (struct fix_arr_8) {(struct void_) {}, (struct arr_14) {0u, NULL}};
}
/* get-environ-recur void(env const-ptr<const-ptr<char>>, res mut-dict<str, str>) */
struct void_ get_environ_recur(struct ctx* ctx, char** env, struct mut_dict_1* res) {
	top:;
	char* _0 = _times_6(env);
	char* _1 = null_1();
	uint8_t _2 = _notEqual_2(_0, _1);
	if (_2) {
		struct arrow_1 entry0;
		char* _3 = _times_6(env);
		entry0 = parse_environ_entry(ctx, _3);
		
		set_subscript_13(ctx, res, entry0.from, entry0.to);
		char** _4 = _plus_6(env, 1u);
		env = _4;
		res = res;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* null<char> const-ptr<char>() */
char* null_1(void) {
	return ((char*) NULL);
}
/* parse-environ-entry arrow<str, str>(entry const-ptr<char>) */
struct arrow_1 parse_environ_entry(struct ctx* ctx, char* entry) {
	struct opt_9 _0 = find_char_in_cstr(entry, 61u);
	switch (_0.kind) {
		case 0: {
			return todo_3();
		}
		case 1: {
			struct some_9 _matched0 = _0.as1;
			
			char* key_end1;
			key_end1 = _matched0.value;
			
			struct str key2;
			struct arr_0 _1 = arr_from_begin_end(entry, key_end1);
			key2 = (struct str) {_1};
			
			char* value_begin3;
			value_begin3 = _plus_0(key_end1, 1u);
			
			char* value_end4;
			value_end4 = find_cstr_end(value_begin3);
			
			struct str value5;
			struct arr_0 _2 = arr_from_begin_end(value_begin3, value_end4);
			value5 = (struct str) {_2};
			
			return _arrow_1(key2, value5);
		}
		default:
			
	return (struct arrow_1) {(struct str) {(struct arr_0) {0, NULL}}, (struct str) {(struct arr_0) {0, NULL}}};;
	}
}
/* todo<arrow<str, str>> arrow<str, str>() */
struct arrow_1 todo_3(void) {
	(abort(), (struct void_) {});
	return (struct arrow_1) {(struct str) {(struct arr_0) {0, NULL}}, (struct str) {(struct arr_0) {0, NULL}}};
}
/* -><str, str> arrow<str, str>(from str, to str) */
struct arrow_1 _arrow_1(struct str from, struct str to) {
	return (struct arrow_1) {from, to};
}
/* set-subscript<str, str> void(a mut-dict<str, str>, key str, value str) */
struct void_ set_subscript_13(struct ctx* ctx, struct mut_dict_1* a, struct str key, struct str value) {
	struct opt_16 _0 = update__e_1(ctx, a, key, (struct opt_16) {1, .as1 = (struct some_16) {value}});
	return drop_5(_0);
}
/* drop<opt<v>> void(_ opt<str>) */
struct void_ drop_5(struct opt_16 _p0) {
	return (struct void_) {};
}
/* update!<k, v> opt<str>(a mut-dict<str, str>, key str, new-value opt<str>) */
struct opt_16 update__e_1(struct ctx* ctx, struct mut_dict_1* a, struct str key, struct opt_16 new_value) {
	uint8_t _0 = is_empty_13(a->entries);
	if (_0) {
		struct opt_16 _1 = new_value;
		switch (_1.kind) {
			case 0: {
				(struct void_) {};
				break;
			}
			case 1: {
				struct some_16 _matched0 = _1.as1;
				
				struct str value1;
				value1 = _matched0.value;
				
				struct entry_1* temp0;
				uint8_t* _2 = alloc(ctx, (sizeof(struct entry_1) * 1u));
				temp0 = ((struct entry_1*) _2);
				
				struct arrow_1 _3 = _arrow_1(key, value1);
				*(temp0 + 0u) = (struct entry_1) {1, .as1 = _3};
				struct fix_arr_8 _4 = fix_arr_13(ctx, (struct arr_14) {1u, temp0});
				a->entries = _4;
				a->total_size = 1u;
				break;
			}
			default:
				
		(struct void_) {};;
		}
		return (struct opt_16) {0, .as0 = (struct none) {}};
	} else {
		uint64_t entry_index2;
		uint64_t _5 = hash(ctx, key);
		uint64_t _6 = size_7(a->entries);
		entry_index2 = (_5 % _6);
		
		struct entry_1 _7 = subscript_75(ctx, a->entries, entry_index2);
		switch (_7.kind) {
			case 0: {
				struct opt_16 _8 = new_value;
				switch (_8.kind) {
					case 0: {
						(struct void_) {};
						break;
					}
					case 1: {
						struct some_16 _matched3 = _8.as1;
						
						struct str value4;
						value4 = _matched3.value;
						
						struct arrow_1 _9 = _arrow_1(key, value4);
						set_subscript_15(ctx, a->entries, entry_index2, (struct entry_1) {1, .as1 = _9});
						a->total_size = (a->total_size + 1u);
						break;
					}
					default:
						
				(struct void_) {};;
				}
				return (struct opt_16) {0, .as0 = (struct none) {}};
			}
			case 1: {
				struct arrow_1 ar5 = _7.as1;
				
				uint8_t _10 = _equal_5(ar5.from, key);
				if (_10) {
					struct opt_16 _11 = new_value;struct entry_1 _12;
					
					switch (_11.kind) {
						case 0: {
							a->total_size = (a->total_size - 1u);
							_12 = (struct entry_1) {0, .as0 = (struct none) {}};
							break;
						}
						case 1: {
							struct some_16 _matched6 = _11.as1;
							
							struct str value7;
							value7 = _matched6.value;
							
							struct arrow_1 _13 = _arrow_1(key, value7);
							_12 = (struct entry_1) {1, .as1 = _13};
							break;
						}
						default:
							
					_12 = (struct entry_1) {0};;
					}
					set_subscript_15(ctx, a->entries, entry_index2, _12);
					return (struct opt_16) {1, .as1 = (struct some_16) {ar5.to}};
				} else {
					struct opt_16 _14 = new_value;
					switch (_14.kind) {
						case 0: {
							(struct void_) {};
							break;
						}
						case 1: {
							struct some_16 _matched8 = _14.as1;
							
							struct str value9;
							value9 = _matched8.value;
							
							uint8_t _15 = should_expand_1(ctx, a);
							if (_15) {
								expand__e_1(ctx, a);
								set_subscript_13(ctx, a, key, value9);
							} else {
								struct arrow_1* temp1;
								uint8_t* _16 = alloc(ctx, (sizeof(struct arrow_1) * 2u));
								temp1 = ((struct arrow_1*) _16);
								
								*(temp1 + 0u) = ar5;
								struct arrow_1 _17 = _arrow_1(key, value9);
								*(temp1 + 1u) = _17;
								struct mut_arr_4* _18 = mut_arr_3(ctx, (struct arr_13) {2u, temp1});
								set_subscript_15(ctx, a->entries, entry_index2, (struct entry_1) {2, .as2 = _18});
								a->total_size = (a->total_size + 1u);
							}
							break;
						}
						default:
							
					(struct void_) {};;
					}
					return (struct opt_16) {0, .as0 = (struct none) {}};
				}
			}
			case 2: {
				struct mut_arr_4* m10 = _7.as2;
				
				struct update__e_1__lambda0* temp2;
				uint8_t* _19 = alloc(ctx, sizeof(struct update__e_1__lambda0));
				temp2 = ((struct update__e_1__lambda0*) _19);
				
				*temp2 = (struct update__e_1__lambda0) {key};
				struct opt_11 _20 = find_index_4(ctx, m10, (struct fun_act1_21) {0, .as0 = temp2});
				switch (_20.kind) {
					case 0: {
						struct opt_16 _21 = new_value;
						switch (_21.kind) {
							case 0: {
								(struct void_) {};
								break;
							}
							case 1: {
								struct some_16 _matched11 = _21.as1;
								
								struct str value12;
								value12 = _matched11.value;
								
								uint8_t _22 = is_at_capacity_1(m10);uint8_t _23;
								
								if (_22) {
									_23 = should_expand_1(ctx, a);
								} else {
									_23 = 0;
								}
								if (_23) {
									expand__e_1(ctx, a);
									set_subscript_13(ctx, a, key, value12);
								} else {
									struct arrow_1 _24 = _arrow_1(key, value12);
									_concatEquals_7(ctx, m10, _24);
									a->total_size = (a->total_size + 1u);
								}
								break;
							}
							default:
								
						(struct void_) {};;
						}
						return (struct opt_16) {0, .as0 = (struct none) {}};
					}
					case 1: {
						struct some_11 _matched13 = _20.as1;
						
						uint64_t index14;
						index14 = _matched13.value;
						
						struct str old_value15;
						struct arrow_1 _25 = subscript_87(ctx, m10, index14);
						old_value15 = _25.to;
						
						struct opt_16 _26 = new_value;
						switch (_26.kind) {
							case 0: {
								struct arrow_1 _27 = remove_unordered_at__e_1(ctx, m10, index14);
								drop_6(_27);
								uint8_t _28 = is_empty_14(m10);
								if (_28) {
									set_subscript_15(ctx, a->entries, entry_index2, (struct entry_1) {0, .as0 = (struct none) {}});
								} else {
									uint8_t _29 = (m10->size == 1u);
									if (_29) {
										struct arrow_1 z16;
										z16 = subscript_87(ctx, m10, 0u);
										
										set_subscript_15(ctx, a->entries, entry_index2, (struct entry_1) {1, .as1 = z16});
									} else {
										(struct void_) {};
									}
								}
								a->total_size = (a->total_size - 1u);
								break;
							}
							case 1: {
								struct some_16 _matched17 = _26.as1;
								
								struct str value18;
								value18 = _matched17.value;
								
								struct arrow_1 _30 = _arrow_1(key, value18);
								set_subscript_17(ctx, m10, index14, _30);
								break;
							}
							default:
								
						(struct void_) {};;
						}
						return (struct opt_16) {1, .as1 = (struct some_16) {old_value15}};
					}
					default:
						
				return (struct opt_16) {0};;
				}
			}
			default:
				
		return (struct opt_16) {0};;
		}
	}
}
/* is-empty<entry<k, v>> bool(a fix-arr<entry<str, str>>) */
uint8_t is_empty_13(struct fix_arr_8 a) {
	uint64_t _0 = size_7(a);
	return (_0 == 0u);
}
/* size<a> nat64(a fix-arr<entry<str, str>>) */
uint64_t size_7(struct fix_arr_8 a) {
	return a.inner.size;
}
/* fix-arr<entry<k, v>> fix-arr<entry<str, str>>(a arr<entry<str, str>>) */
struct fix_arr_8 fix_arr_13(struct ctx* ctx, struct arr_14 a) {
	struct fix_arr_13__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct fix_arr_13__lambda0));
	temp0 = ((struct fix_arr_13__lambda0*) _0);
	
	*temp0 = (struct fix_arr_13__lambda0) {a};
	return make_fix_arr_3(ctx, a.size, (struct fun_act1_19) {0, .as0 = temp0});
}
/* make-fix-arr<a> fix-arr<entry<str, str>>(size nat64, f fun-act1<entry<str, str>, nat64>) */
struct fix_arr_8 make_fix_arr_3(struct ctx* ctx, uint64_t size, struct fun_act1_19 f) {
	struct fix_arr_8 res0;
	res0 = uninitialized_fix_arr_5(ctx, size);
	
	struct entry_1* _0 = begin_ptr_10(res0);
	fill_ptr_range_4(ctx, _0, size, f);
	return res0;
}
/* uninitialized-fix-arr<a> fix-arr<entry<str, str>>(size nat64) */
struct fix_arr_8 uninitialized_fix_arr_5(struct ctx* ctx, uint64_t size) {
	struct entry_1* _0 = alloc_uninitialized_6(ctx, size);
	return fix_arr_14(size, _0);
}
/* fix-arr<a> fix-arr<entry<str, str>>(size nat64, begin-ptr mut-ptr<entry<str, str>>) */
struct fix_arr_8 fix_arr_14(uint64_t size, struct entry_1* begin_ptr) {
	return (struct fix_arr_8) {(struct void_) {}, (struct arr_14) {size, ((struct entry_1*) begin_ptr)}};
}
/* alloc-uninitialized<a> mut-ptr<entry<str, str>>(size nat64) */
struct entry_1* alloc_uninitialized_6(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(struct entry_1)));
	return ((struct entry_1*) _0);
}
/* fill-ptr-range<a> void(begin mut-ptr<entry<str, str>>, size nat64, f fun-act1<entry<str, str>, nat64>) */
struct void_ fill_ptr_range_4(struct ctx* ctx, struct entry_1* begin, uint64_t size, struct fun_act1_19 f) {
	return fill_ptr_range_recur_4(ctx, begin, 0u, size, f);
}
/* fill-ptr-range-recur<a> void(begin mut-ptr<entry<str, str>>, i nat64, size nat64, f fun-act1<entry<str, str>, nat64>) */
struct void_ fill_ptr_range_recur_4(struct ctx* ctx, struct entry_1* begin, uint64_t i, uint64_t size, struct fun_act1_19 f) {
	top:;
	uint8_t _0 = _notEqual_5(i, size);
	if (_0) {
		struct entry_1 _1 = subscript_72(ctx, f, i);
		set_subscript_14(begin, i, _1);
		begin = begin;
		i = (i + 1u);
		size = size;
		f = f;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* set-subscript<a> void(a mut-ptr<entry<str, str>>, n nat64, value entry<str, str>) */
struct void_ set_subscript_14(struct entry_1* a, uint64_t n, struct entry_1 value) {
	return (*(a + n) = value, (struct void_) {});
}
/* subscript<a, nat64> entry<str, str>(a fun-act1<entry<str, str>, nat64>, p0 nat64) */
struct entry_1 subscript_72(struct ctx* ctx, struct fun_act1_19 a, uint64_t p0) {
	return call_w_ctx_832(a, ctx, p0);
}
/* call-w-ctx<entry<str, str>, nat-64> (generated) (generated) */
struct entry_1 call_w_ctx_832(struct fun_act1_19 a, struct ctx* ctx, uint64_t p0) {
	struct fun_act1_19 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct fix_arr_13__lambda0* closure0 = _0.as0;
			
			return fix_arr_13__lambda0(ctx, closure0, p0);
		}
		case 1: {
			struct fill_fix_arr_3__lambda0* closure1 = _0.as1;
			
			return fill_fix_arr_3__lambda0(ctx, closure1, p0);
		}
		default:
			
	return (struct entry_1) {0};;
	}
}
/* begin-ptr<a> mut-ptr<entry<str, str>>(a fix-arr<entry<str, str>>) */
struct entry_1* begin_ptr_10(struct fix_arr_8 a) {
	return ((struct entry_1*) a.inner.begin_ptr);
}
/* subscript<a> entry<str, str>(a arr<entry<str, str>>, index nat64) */
struct entry_1 subscript_73(struct ctx* ctx, struct arr_14 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	return unsafe_at_11(a, index);
}
/* unsafe-at<a> entry<str, str>(a arr<entry<str, str>>, index nat64) */
struct entry_1 unsafe_at_11(struct arr_14 a, uint64_t index) {
	return subscript_74(a.begin_ptr, index);
}
/* subscript<a> entry<str, str>(a const-ptr<entry<str, str>>, n nat64) */
struct entry_1 subscript_74(struct entry_1* a, uint64_t n) {
	struct entry_1* _0 = _plus_13(a, n);
	return _times_16(_0);
}
/* *<a> entry<str, str>(a const-ptr<entry<str, str>>) */
struct entry_1 _times_16(struct entry_1* a) {
	return (*((struct entry_1*) a));
}
/* +<a> const-ptr<entry<str, str>>(a const-ptr<entry<str, str>>, offset nat64) */
struct entry_1* _plus_13(struct entry_1* a, uint64_t offset) {
	return ((struct entry_1*) (((struct entry_1*) a) + offset));
}
/* fix-arr<entry<k, v>>.lambda0 entry<str, str>(i nat64) */
struct entry_1 fix_arr_13__lambda0(struct ctx* ctx, struct fix_arr_13__lambda0* _closure, uint64_t i) {
	return subscript_73(ctx, _closure->a, i);
}
/* subscript<entry<k, v>> entry<str, str>(a fix-arr<entry<str, str>>, index nat64) */
struct entry_1 subscript_75(struct ctx* ctx, struct fix_arr_8 a, uint64_t index) {
	uint64_t _0 = size_7(a);
	uint8_t _1 = _less_0(index, _0);
	assert_0(ctx, _1);
	return unsafe_at_12(ctx, a, index);
}
/* unsafe-at<a> entry<str, str>(a fix-arr<entry<str, str>>, index nat64) */
struct entry_1 unsafe_at_12(struct ctx* ctx, struct fix_arr_8 a, uint64_t index) {
	struct entry_1* _0 = begin_ptr_10(a);
	return subscript_76(_0, index);
}
/* subscript<a> entry<str, str>(a mut-ptr<entry<str, str>>, n nat64) */
struct entry_1 subscript_76(struct entry_1* a, uint64_t n) {
	return (*(a + n));
}
/* set-subscript<entry<k, v>> void(a fix-arr<entry<str, str>>, index nat64, value entry<str, str>) */
struct void_ set_subscript_15(struct ctx* ctx, struct fix_arr_8 a, uint64_t index, struct entry_1 value) {
	uint64_t _0 = size_7(a);
	uint8_t _1 = _less_0(index, _0);
	assert_0(ctx, _1);
	return unsafe_set_at__e_2(ctx, a, index, value);
}
/* unsafe-set-at!<a> void(a fix-arr<entry<str, str>>, index nat64, value entry<str, str>) */
struct void_ unsafe_set_at__e_2(struct ctx* ctx, struct fix_arr_8 a, uint64_t index, struct entry_1 value) {
	struct entry_1* _0 = begin_ptr_10(a);
	return set_subscript_14(_0, index, value);
}
/* should-expand<k, v> bool(a mut-dict<str, str>) */
uint8_t should_expand_1(struct ctx* ctx, struct mut_dict_1* a) {
	uint64_t _0 = size_7(a->entries);
	return _greaterOrEqual(a->total_size, _0);
}
/* expand!<k, v> void(a mut-dict<str, str>) */
struct void_ expand__e_1(struct ctx* ctx, struct mut_dict_1* a) {
	uint64_t _0 = size_7(a->entries);
	forbid(ctx, (_0 == 0u));
	uint64_t new_size0;
	uint64_t _1 = size_7(a->entries);
	new_size0 = (_1 * 2u);
	
	struct mut_dict_1* bigger1;
	bigger1 = mut_dict_with_capacity_1(ctx, new_size0);
	
	struct expand__e_1__lambda0* temp0;
	uint8_t* _2 = alloc(ctx, sizeof(struct expand__e_1__lambda0));
	temp0 = ((struct expand__e_1__lambda0*) _2);
	
	*temp0 = (struct expand__e_1__lambda0) {bigger1};
	each_5(ctx, a, (struct fun_act2_10) {0, .as0 = temp0});
	swap__e_2(ctx, a, bigger1);
	uint64_t _3 = size_7(a->entries);
	return assert_0(ctx, (_3 == new_size0));
}
/* mut-dict-with-capacity<k, v> mut-dict<str, str>(capacity nat64) */
struct mut_dict_1* mut_dict_with_capacity_1(struct ctx* ctx, uint64_t capacity) {
	struct mut_dict_1* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_dict_1));
	temp0 = ((struct mut_dict_1*) _0);
	
	struct fix_arr_8 _1 = fill_fix_arr_3(ctx, capacity, (struct entry_1) {0, .as0 = (struct none) {}});
	*temp0 = (struct mut_dict_1) {(struct void_) {}, _1, 0u};
	return temp0;
}
/* fill-fix-arr<entry<k, v>> fix-arr<entry<str, str>>(size nat64, value entry<str, str>) */
struct fix_arr_8 fill_fix_arr_3(struct ctx* ctx, uint64_t size, struct entry_1 value) {
	struct fill_fix_arr_3__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct fill_fix_arr_3__lambda0));
	temp0 = ((struct fill_fix_arr_3__lambda0*) _0);
	
	*temp0 = (struct fill_fix_arr_3__lambda0) {value};
	return make_fix_arr_3(ctx, size, (struct fun_act1_19) {1, .as1 = temp0});
}
/* fill-fix-arr<entry<k, v>>.lambda0 entry<str, str>(ignore nat64) */
struct entry_1 fill_fix_arr_3__lambda0(struct ctx* ctx, struct fill_fix_arr_3__lambda0* _closure, uint64_t ignore) {
	return _closure->value;
}
/* each<k, v> void(a mut-dict<str, str>, f fun-act2<void, str, str>) */
struct void_ each_5(struct ctx* ctx, struct mut_dict_1* a, struct fun_act2_10 f) {
	struct each_5__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct each_5__lambda0));
	temp0 = ((struct each_5__lambda0*) _0);
	
	*temp0 = (struct each_5__lambda0) {f};
	return fold_14(ctx, (struct void_) {}, a, (struct fun_act3_3) {0, .as0 = temp0});
}
/* fold<void, k, v> void(acc void, a mut-dict<str, str>, f fun-act3<void, void, str, str>) */
struct void_ fold_14(struct ctx* ctx, struct void_ acc, struct mut_dict_1* a, struct fun_act3_3 f) {
	struct fold_14__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct fold_14__lambda0));
	temp0 = ((struct fold_14__lambda0*) _0);
	
	*temp0 = (struct fold_14__lambda0) {f};
	return fold_15(ctx, acc, a->entries, (struct fun_act2_11) {0, .as0 = temp0});
}
/* fold<a, entry<k, v>> void(acc void, a fix-arr<entry<str, str>>, f fun-act2<void, void, entry<str, str>>) */
struct void_ fold_15(struct ctx* ctx, struct void_ acc, struct fix_arr_8 a, struct fun_act2_11 f) {
	struct arr_14 _0 = temp_as_arr_5(a);
	return fold_16(ctx, acc, _0, f);
}
/* fold<a, b> void(acc void, a arr<entry<str, str>>, f fun-act2<void, void, entry<str, str>>) */
struct void_ fold_16(struct ctx* ctx, struct void_ acc, struct arr_14 a, struct fun_act2_11 f) {
	struct entry_1* _0 = end_ptr_8(a);
	return fold_recur_8(ctx, acc, a.begin_ptr, _0, f);
}
/* fold-recur<a, b> void(acc void, cur const-ptr<entry<str, str>>, end const-ptr<entry<str, str>>, f fun-act2<void, void, entry<str, str>>) */
struct void_ fold_recur_8(struct ctx* ctx, struct void_ acc, struct entry_1* cur, struct entry_1* end, struct fun_act2_11 f) {
	top:;
	uint8_t _0 = _equal_10(cur, end);
	if (_0) {
		return acc;
	} else {
		struct entry_1 _1 = _times_16(cur);
		struct void_ _2 = subscript_77(ctx, f, acc, _1);
		struct entry_1* _3 = _plus_13(cur, 1u);
		acc = _2;
		cur = _3;
		end = end;
		f = f;
		goto top;
	}
}
/* ==<b> bool(a const-ptr<entry<str, str>>, b const-ptr<entry<str, str>>) */
uint8_t _equal_10(struct entry_1* a, struct entry_1* b) {
	return (((struct entry_1*) a) == ((struct entry_1*) b));
}
/* subscript<a, a, b> void(a fun-act2<void, void, entry<str, str>>, p0 void, p1 entry<str, str>) */
struct void_ subscript_77(struct ctx* ctx, struct fun_act2_11 a, struct void_ p0, struct entry_1 p1) {
	return call_w_ctx_857(a, ctx, p0, p1);
}
/* call-w-ctx<void, void, entry<str, str>> (generated) (generated) */
struct void_ call_w_ctx_857(struct fun_act2_11 a, struct ctx* ctx, struct void_ p0, struct entry_1 p1) {
	struct fun_act2_11 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct fold_14__lambda0* closure0 = _0.as0;
			
			return fold_14__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* end-ptr<b> const-ptr<entry<str, str>>(a arr<entry<str, str>>) */
struct entry_1* end_ptr_8(struct arr_14 a) {
	return _plus_13(a.begin_ptr, a.size);
}
/* temp-as-arr<b> arr<entry<str, str>>(a fix-arr<entry<str, str>>) */
struct arr_14 temp_as_arr_5(struct fix_arr_8 a) {
	return a.inner;
}
/* subscript<a, a, k, v> void(a fun-act3<void, void, str, str>, p0 void, p1 str, p2 str) */
struct void_ subscript_78(struct ctx* ctx, struct fun_act3_3 a, struct void_ p0, struct str p1, struct str p2) {
	return call_w_ctx_861(a, ctx, p0, p1, p2);
}
/* call-w-ctx<void, void, str, str> (generated) (generated) */
struct void_ call_w_ctx_861(struct fun_act3_3 a, struct ctx* ctx, struct void_ p0, struct str p1, struct str p2) {
	struct fun_act3_3 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct each_5__lambda0* closure0 = _0.as0;
			
			return each_5__lambda0(ctx, closure0, p0, p1, p2);
		}
		case 1: {
			struct each_9__lambda0* closure1 = _0.as1;
			
			return each_9__lambda0(ctx, closure1, p0, p1, p2);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* fold<a, arrow<k, v>> void(acc void, a mut-arr<arrow<str, str>>, f fun-act2<void, void, arrow<str, str>>) */
struct void_ fold_17(struct ctx* ctx, struct void_ acc, struct mut_arr_4* a, struct fun_act2_12 f) {
	struct arr_13 _0 = temp_as_arr_6(a);
	return fold_18(ctx, acc, _0, f);
}
/* fold<a, b> void(acc void, a arr<arrow<str, str>>, f fun-act2<void, void, arrow<str, str>>) */
struct void_ fold_18(struct ctx* ctx, struct void_ acc, struct arr_13 a, struct fun_act2_12 f) {
	struct arrow_1* _0 = end_ptr_9(a);
	return fold_recur_9(ctx, acc, a.begin_ptr, _0, f);
}
/* fold-recur<a, b> void(acc void, cur const-ptr<arrow<str, str>>, end const-ptr<arrow<str, str>>, f fun-act2<void, void, arrow<str, str>>) */
struct void_ fold_recur_9(struct ctx* ctx, struct void_ acc, struct arrow_1* cur, struct arrow_1* end, struct fun_act2_12 f) {
	top:;
	uint8_t _0 = _equal_11(cur, end);
	if (_0) {
		return acc;
	} else {
		struct arrow_1 _1 = _times_17(cur);
		struct void_ _2 = subscript_79(ctx, f, acc, _1);
		struct arrow_1* _3 = _plus_14(cur, 1u);
		acc = _2;
		cur = _3;
		end = end;
		f = f;
		goto top;
	}
}
/* ==<b> bool(a const-ptr<arrow<str, str>>, b const-ptr<arrow<str, str>>) */
uint8_t _equal_11(struct arrow_1* a, struct arrow_1* b) {
	return (((struct arrow_1*) a) == ((struct arrow_1*) b));
}
/* subscript<a, a, b> void(a fun-act2<void, void, arrow<str, str>>, p0 void, p1 arrow<str, str>) */
struct void_ subscript_79(struct ctx* ctx, struct fun_act2_12 a, struct void_ p0, struct arrow_1 p1) {
	return call_w_ctx_867(a, ctx, p0, p1);
}
/* call-w-ctx<void, void, arrow<str, str>> (generated) (generated) */
struct void_ call_w_ctx_867(struct fun_act2_12 a, struct ctx* ctx, struct void_ p0, struct arrow_1 p1) {
	struct fun_act2_12 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct fold_14__lambda0__lambda0* closure0 = _0.as0;
			
			return fold_14__lambda0__lambda0(ctx, closure0, p0, p1);
		}
		case 1: {
			struct fold_recur_15__lambda1* closure1 = _0.as1;
			
			return fold_recur_15__lambda1(ctx, closure1, p0, p1);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* *<b> arrow<str, str>(a const-ptr<arrow<str, str>>) */
struct arrow_1 _times_17(struct arrow_1* a) {
	return (*((struct arrow_1*) a));
}
/* +<b> const-ptr<arrow<str, str>>(a const-ptr<arrow<str, str>>, offset nat64) */
struct arrow_1* _plus_14(struct arrow_1* a, uint64_t offset) {
	return ((struct arrow_1*) (((struct arrow_1*) a) + offset));
}
/* end-ptr<b> const-ptr<arrow<str, str>>(a arr<arrow<str, str>>) */
struct arrow_1* end_ptr_9(struct arr_13 a) {
	return _plus_14(a.begin_ptr, a.size);
}
/* temp-as-arr<b> arr<arrow<str, str>>(a mut-arr<arrow<str, str>>) */
struct arr_13 temp_as_arr_6(struct mut_arr_4* a) {
	struct fix_arr_7 _0 = temp_as_fix_arr_2(a);
	return temp_as_arr_7(_0);
}
/* temp-as-arr<a> arr<arrow<str, str>>(a fix-arr<arrow<str, str>>) */
struct arr_13 temp_as_arr_7(struct fix_arr_7 a) {
	return a.inner;
}
/* temp-as-fix-arr<a> fix-arr<arrow<str, str>>(a mut-arr<arrow<str, str>>) */
struct fix_arr_7 temp_as_fix_arr_2(struct mut_arr_4* a) {
	struct arrow_1* _0 = begin_ptr_11(a);
	return fix_arr_15(a->size, _0);
}
/* fix-arr<a> fix-arr<arrow<str, str>>(size nat64, begin-ptr mut-ptr<arrow<str, str>>) */
struct fix_arr_7 fix_arr_15(uint64_t size, struct arrow_1* begin_ptr) {
	return (struct fix_arr_7) {(struct void_) {}, (struct arr_13) {size, ((struct arrow_1*) begin_ptr)}};
}
/* begin-ptr<a> mut-ptr<arrow<str, str>>(a mut-arr<arrow<str, str>>) */
struct arrow_1* begin_ptr_11(struct mut_arr_4* a) {
	return begin_ptr_12(a->backing);
}
/* begin-ptr<a> mut-ptr<arrow<str, str>>(a fix-arr<arrow<str, str>>) */
struct arrow_1* begin_ptr_12(struct fix_arr_7 a) {
	return ((struct arrow_1*) a.inner.begin_ptr);
}
/* fold<void, k, v>.lambda0.lambda0 void(cur2 void, pair arrow<str, str>) */
struct void_ fold_14__lambda0__lambda0(struct ctx* ctx, struct fold_14__lambda0__lambda0* _closure, struct void_ cur2, struct arrow_1 pair) {
	return subscript_78(ctx, _closure->f, cur2, pair.from, pair.to);
}
/* fold<void, k, v>.lambda0 void(cur void, entry entry<str, str>) */
struct void_ fold_14__lambda0(struct ctx* ctx, struct fold_14__lambda0* _closure, struct void_ cur, struct entry_1 entry) {
	struct entry_1 _0 = entry;
	switch (_0.kind) {
		case 0: {
			return cur;
		}
		case 1: {
			struct arrow_1 ar0 = _0.as1;
			
			return subscript_78(ctx, _closure->f, cur, ar0.from, ar0.to);
		}
		case 2: {
			struct mut_arr_4* m1 = _0.as2;
			
			struct fold_14__lambda0__lambda0* temp0;
			uint8_t* _1 = alloc(ctx, sizeof(struct fold_14__lambda0__lambda0));
			temp0 = ((struct fold_14__lambda0__lambda0*) _1);
			
			*temp0 = (struct fold_14__lambda0__lambda0) {_closure->f};
			return fold_17(ctx, cur, m1, (struct fun_act2_12) {0, .as0 = temp0});
		}
		default:
			
	return (struct void_) {};;
	}
}
/* subscript<void, k, v> void(a fun-act2<void, str, str>, p0 str, p1 str) */
struct void_ subscript_80(struct ctx* ctx, struct fun_act2_10 a, struct str p0, struct str p1) {
	return call_w_ctx_880(a, ctx, p0, p1);
}
/* call-w-ctx<void, str, str> (generated) (generated) */
struct void_ call_w_ctx_880(struct fun_act2_10 a, struct ctx* ctx, struct str p0, struct str p1) {
	struct fun_act2_10 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct expand__e_1__lambda0* closure0 = _0.as0;
			
			return expand__e_1__lambda0(ctx, closure0, p0, p1);
		}
		case 1: {
			struct convert_environ__lambda0* closure1 = _0.as1;
			
			return convert_environ__lambda0(ctx, closure1, p0, p1);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* each<k, v>.lambda0 void(ignore void, key str, value str) */
struct void_ each_5__lambda0(struct ctx* ctx, struct each_5__lambda0* _closure, struct void_ ignore, struct str key, struct str value) {
	return subscript_80(ctx, _closure->f, key, value);
}
/* expand!<k, v>.lambda0 void(key str, value str) */
struct void_ expand__e_1__lambda0(struct ctx* ctx, struct expand__e_1__lambda0* _closure, struct str key, struct str value) {
	return set_subscript_13(ctx, _closure->bigger, key, value);
}
/* swap!<k, v> void(a mut-dict<str, str>, b mut-dict<str, str>) */
struct void_ swap__e_2(struct ctx* ctx, struct mut_dict_1* a, struct mut_dict_1* b) {
	struct fix_arr_8 temp_entries0;
	temp_entries0 = a->entries;
	
	a->entries = b->entries;
	b->entries = temp_entries0;
	uint64_t temp_size1;
	temp_size1 = a->total_size;
	
	a->total_size = b->total_size;
	return (b->total_size = temp_size1, (struct void_) {});
}
/* mut-arr<arrow<k, v>> mut-arr<arrow<str, str>>(a arr<arrow<str, str>>) */
struct mut_arr_4* mut_arr_3(struct ctx* ctx, struct arr_13 a) {
	struct mut_arr_4* res0;
	res0 = mut_arr_4(ctx);
	
	_concatEquals_6(ctx, res0, a);
	return res0;
}
/* mut-arr<a> mut-arr<arrow<str, str>>() */
struct mut_arr_4* mut_arr_4(struct ctx* ctx) {
	struct mut_arr_4* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_arr_4));
	temp0 = ((struct mut_arr_4*) _0);
	
	struct fix_arr_7 _1 = fix_arr_16();
	*temp0 = (struct mut_arr_4) {_1, 0u};
	return temp0;
}
/* fix-arr<a> fix-arr<arrow<str, str>>() */
struct fix_arr_7 fix_arr_16(void) {
	return (struct fix_arr_7) {(struct void_) {}, (struct arr_13) {0u, NULL}};
}
/* ~=<a> void(a mut-arr<arrow<str, str>>, values arr<arrow<str, str>>) */
struct void_ _concatEquals_6(struct ctx* ctx, struct mut_arr_4* a, struct arr_13 values) {
	struct _concatEquals_6__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct _concatEquals_6__lambda0));
	temp0 = ((struct _concatEquals_6__lambda0*) _0);
	
	*temp0 = (struct _concatEquals_6__lambda0) {a};
	return each_6(ctx, values, (struct fun_act1_20) {0, .as0 = temp0});
}
/* each<a> void(a arr<arrow<str, str>>, f fun-act1<void, arrow<str, str>>) */
struct void_ each_6(struct ctx* ctx, struct arr_13 a, struct fun_act1_20 f) {
	struct arrow_1* _0 = end_ptr_9(a);
	return each_recur_3(ctx, a.begin_ptr, _0, f);
}
/* each-recur<a> void(cur const-ptr<arrow<str, str>>, end const-ptr<arrow<str, str>>, f fun-act1<void, arrow<str, str>>) */
struct void_ each_recur_3(struct ctx* ctx, struct arrow_1* cur, struct arrow_1* end, struct fun_act1_20 f) {
	top:;
	uint8_t _0 = _notEqual_11(cur, end);
	if (_0) {
		struct arrow_1 _1 = _times_17(cur);
		subscript_81(ctx, f, _1);
		struct arrow_1* _2 = _plus_14(cur, 1u);
		cur = _2;
		end = end;
		f = f;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* !=<const-ptr<a>> bool(a const-ptr<arrow<str, str>>, b const-ptr<arrow<str, str>>) */
uint8_t _notEqual_11(struct arrow_1* a, struct arrow_1* b) {
	uint8_t _0 = _equal_11(a, b);
	return _not(_0);
}
/* subscript<void, a> void(a fun-act1<void, arrow<str, str>>, p0 arrow<str, str>) */
struct void_ subscript_81(struct ctx* ctx, struct fun_act1_20 a, struct arrow_1 p0) {
	return call_w_ctx_892(a, ctx, p0);
}
/* call-w-ctx<void, arrow<str, str>> (generated) (generated) */
struct void_ call_w_ctx_892(struct fun_act1_20 a, struct ctx* ctx, struct arrow_1 p0) {
	struct fun_act1_20 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct _concatEquals_6__lambda0* closure0 = _0.as0;
			
			return _concatEquals_6__lambda0(ctx, closure0, p0);
		}
		case 1: {
			struct new_inner_node_1__lambda1* closure1 = _0.as1;
			
			return new_inner_node_1__lambda1(ctx, closure1, p0);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* ~=<a> void(a mut-arr<arrow<str, str>>, value arrow<str, str>) */
struct void_ _concatEquals_7(struct ctx* ctx, struct mut_arr_4* a, struct arrow_1 value) {
	incr_capacity__e_2(ctx, a);
	uint64_t _0 = capacity_3(a);
	uint8_t _1 = _less_0(a->size, _0);
	assert_0(ctx, _1);
	struct arrow_1* _2 = begin_ptr_11(a);
	set_subscript_16(_2, a->size, value);
	uint64_t _3 = _plus_3(ctx, a->size, 1u);
	return (a->size = _3, (struct void_) {});
}
/* incr-capacity!<a> void(a mut-arr<arrow<str, str>>) */
struct void_ incr_capacity__e_2(struct ctx* ctx, struct mut_arr_4* a) {
	uint64_t _0 = _plus_3(ctx, a->size, 1u);
	uint64_t _1 = round_up_to_power_of_two(ctx, _0);
	return ensure_capacity_2(ctx, a, _1);
}
/* ensure-capacity<a> void(a mut-arr<arrow<str, str>>, min-capacity nat64) */
struct void_ ensure_capacity_2(struct ctx* ctx, struct mut_arr_4* a, uint64_t min_capacity) {
	uint64_t _0 = capacity_3(a);
	uint8_t _1 = _less_0(_0, min_capacity);
	if (_1) {
		return increase_capacity_to__e_2(ctx, a, min_capacity);
	} else {
		return (struct void_) {};
	}
}
/* capacity<a> nat64(a mut-arr<arrow<str, str>>) */
uint64_t capacity_3(struct mut_arr_4* a) {
	return size_8(a->backing);
}
/* size<a> nat64(a fix-arr<arrow<str, str>>) */
uint64_t size_8(struct fix_arr_7 a) {
	return a.inner.size;
}
/* increase-capacity-to!<a> void(a mut-arr<arrow<str, str>>, new-capacity nat64) */
struct void_ increase_capacity_to__e_2(struct ctx* ctx, struct mut_arr_4* a, uint64_t new_capacity) {
	uint64_t _0 = capacity_3(a);
	uint8_t _1 = _greater(new_capacity, _0);
	assert_0(ctx, _1);
	struct arrow_1* old_begin0;
	old_begin0 = begin_ptr_11(a);
	
	struct fix_arr_7 _2 = uninitialized_fix_arr_6(ctx, new_capacity);
	a->backing = _2;
	struct arrow_1* _3 = begin_ptr_11(a);
	copy_data_from__e_4(ctx, _3, ((struct arrow_1*) old_begin0), a->size);
	uint64_t _4 = _plus_3(ctx, a->size, 1u);
	uint64_t _5 = size_8(a->backing);
	struct range _6 = _range(ctx, _4, _5);
	struct fix_arr_7 _7 = subscript_82(ctx, a->backing, _6);
	return set_zero_elements_2(_7);
}
/* uninitialized-fix-arr<a> fix-arr<arrow<str, str>>(size nat64) */
struct fix_arr_7 uninitialized_fix_arr_6(struct ctx* ctx, uint64_t size) {
	struct arrow_1* _0 = alloc_uninitialized_7(ctx, size);
	return fix_arr_15(size, _0);
}
/* alloc-uninitialized<a> mut-ptr<arrow<str, str>>(size nat64) */
struct arrow_1* alloc_uninitialized_7(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(struct arrow_1)));
	return ((struct arrow_1*) _0);
}
/* copy-data-from!<a> void(to mut-ptr<arrow<str, str>>, from const-ptr<arrow<str, str>>, len nat64) */
struct void_ copy_data_from__e_4(struct ctx* ctx, struct arrow_1* to, struct arrow_1* from, uint64_t len) {
	uint8_t* _0 = as_any_const_ptr_4(from);
	uint8_t* _1 = memcpy(((uint8_t*) to), _0, (len * sizeof(struct arrow_1)));
	return drop_0(_1);
}
/* as-any-const-ptr<const-ptr<a>> const-ptr<nat8>(ref const-ptr<arrow<str, str>>) */
uint8_t* as_any_const_ptr_4(struct arrow_1* ref) {
	return ((uint8_t*) ((uint8_t*) ref));
}
/* set-zero-elements<a> void(a fix-arr<arrow<str, str>>) */
struct void_ set_zero_elements_2(struct fix_arr_7 a) {
	struct arrow_1* _0 = begin_ptr_12(a);
	uint64_t _1 = size_8(a);
	return set_zero_range_3(_0, _1);
}
/* set-zero-range<a> void(begin mut-ptr<arrow<str, str>>, size nat64) */
struct void_ set_zero_range_3(struct arrow_1* begin, uint64_t size) {
	uint8_t* _0 = memset(((uint8_t*) begin), 0, (size * sizeof(struct arrow_1)));
	return drop_0(_0);
}
/* subscript<a> fix-arr<arrow<str, str>>(a fix-arr<arrow<str, str>>, range range<nat64>) */
struct fix_arr_7 subscript_82(struct ctx* ctx, struct fix_arr_7 a, struct range range) {
	struct arr_13 _0 = subscript_83(ctx, a.inner, range);
	return (struct fix_arr_7) {(struct void_) {}, _0};
}
/* subscript<a> arr<arrow<str, str>>(a arr<arrow<str, str>>, range range<nat64>) */
struct arr_13 subscript_83(struct ctx* ctx, struct arr_13 a, struct range range) {
	uint8_t _0 = _lessOrEqual_0(range.high, a.size);
	assert_0(ctx, _0);
	struct arrow_1* _1 = _plus_14(a.begin_ptr, range.low);
	return (struct arr_13) {(range.high - range.low), _1};
}
/* set-subscript<a> void(a mut-ptr<arrow<str, str>>, n nat64, value arrow<str, str>) */
struct void_ set_subscript_16(struct arrow_1* a, uint64_t n, struct arrow_1 value) {
	return (*(a + n) = value, (struct void_) {});
}
/* ~=<a>.lambda0 void(x arrow<str, str>) */
struct void_ _concatEquals_6__lambda0(struct ctx* ctx, struct _concatEquals_6__lambda0* _closure, struct arrow_1 x) {
	return _concatEquals_7(ctx, _closure->a, x);
}
/* find-index<arrow<k, v>> opt<nat64>(a mut-arr<arrow<str, str>>, f fun-act1<bool, arrow<str, str>>) */
struct opt_11 find_index_4(struct ctx* ctx, struct mut_arr_4* a, struct fun_act1_21 f) {
	struct arr_13 _0 = temp_as_arr_6(a);
	return find_index_5(ctx, _0, f);
}
/* find-index<a> opt<nat64>(a arr<arrow<str, str>>, f fun-act1<bool, arrow<str, str>>) */
struct opt_11 find_index_5(struct ctx* ctx, struct arr_13 a, struct fun_act1_21 f) {
	return find_index_recur_3(ctx, a, 0u, f);
}
/* find-index-recur<a> opt<nat64>(a arr<arrow<str, str>>, index nat64, f fun-act1<bool, arrow<str, str>>) */
struct opt_11 find_index_recur_3(struct ctx* ctx, struct arr_13 a, uint64_t index, struct fun_act1_21 f) {
	top:;
	uint8_t _0 = (index == a.size);
	if (_0) {
		return (struct opt_11) {0, .as0 = (struct none) {}};
	} else {
		struct arrow_1 _1 = subscript_85(ctx, a, index);
		uint8_t _2 = subscript_84(ctx, f, _1);
		if (_2) {
			return (struct opt_11) {1, .as1 = (struct some_11) {index}};
		} else {
			uint64_t _3 = _plus_3(ctx, index, 1u);
			a = a;
			index = _3;
			f = f;
			goto top;
		}
	}
}
/* subscript<bool, a> bool(a fun-act1<bool, arrow<str, str>>, p0 arrow<str, str>) */
uint8_t subscript_84(struct ctx* ctx, struct fun_act1_21 a, struct arrow_1 p0) {
	return call_w_ctx_913(a, ctx, p0);
}
/* call-w-ctx<bool, arrow<str, str>> (generated) (generated) */
uint8_t call_w_ctx_913(struct fun_act1_21 a, struct ctx* ctx, struct arrow_1 p0) {
	struct fun_act1_21 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct update__e_1__lambda0* closure0 = _0.as0;
			
			return update__e_1__lambda0(ctx, closure0, p0);
		}
		case 1: {
			struct no_duplicate_keys_1__lambda0* closure1 = _0.as1;
			
			return no_duplicate_keys_1__lambda0(ctx, closure1, p0);
		}
		case 2: {
			struct get_or_update_leaf_1__lambda0* closure2 = _0.as2;
			
			return get_or_update_leaf_1__lambda0(ctx, closure2, p0);
		}
		default:
			
	return 0;;
	}
}
/* subscript<a> arrow<str, str>(a arr<arrow<str, str>>, index nat64) */
struct arrow_1 subscript_85(struct ctx* ctx, struct arr_13 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	return unsafe_at_13(a, index);
}
/* unsafe-at<a> arrow<str, str>(a arr<arrow<str, str>>, index nat64) */
struct arrow_1 unsafe_at_13(struct arr_13 a, uint64_t index) {
	return subscript_86(a.begin_ptr, index);
}
/* subscript<a> arrow<str, str>(a const-ptr<arrow<str, str>>, n nat64) */
struct arrow_1 subscript_86(struct arrow_1* a, uint64_t n) {
	struct arrow_1* _0 = _plus_14(a, n);
	return _times_17(_0);
}
/* update!<k, v>.lambda0 bool(pair arrow<str, str>) */
uint8_t update__e_1__lambda0(struct ctx* ctx, struct update__e_1__lambda0* _closure, struct arrow_1 pair) {
	return _equal_5(pair.from, _closure->key);
}
/* is-at-capacity<arrow<k, v>> bool(a mut-arr<arrow<str, str>>) */
uint8_t is_at_capacity_1(struct mut_arr_4* a) {
	uint64_t _0 = capacity_3(a);
	return (_0 == a->size);
}
/* subscript<arrow<k, v>> arrow<str, str>(a mut-arr<arrow<str, str>>, index nat64) */
struct arrow_1 subscript_87(struct ctx* ctx, struct mut_arr_4* a, uint64_t index) {
	uint8_t _0 = _less_0(index, a->size);
	assert_0(ctx, _0);
	struct arrow_1* _1 = begin_ptr_11(a);
	return subscript_88(_1, index);
}
/* subscript<a> arrow<str, str>(a mut-ptr<arrow<str, str>>, n nat64) */
struct arrow_1 subscript_88(struct arrow_1* a, uint64_t n) {
	return (*(a + n));
}
/* drop<arrow<k, v>> void(_ arrow<str, str>) */
struct void_ drop_6(struct arrow_1 _p0) {
	return (struct void_) {};
}
/* remove-unordered-at!<arrow<k, v>> arrow<str, str>(a mut-arr<arrow<str, str>>, index nat64) */
struct arrow_1 remove_unordered_at__e_1(struct ctx* ctx, struct mut_arr_4* a, uint64_t index) {
	uint8_t _0 = _less_0(index, a->size);
	assert_0(ctx, _0);
	return noctx_remove_unordered_at__e_2(a, index);
}
/* noctx-remove-unordered-at!<a> arrow<str, str>(a mut-arr<arrow<str, str>>, index nat64) */
struct arrow_1 noctx_remove_unordered_at__e_2(struct mut_arr_4* a, uint64_t index) {
	uint8_t _0 = _less_0(index, a->size);
	hard_assert(_0);
	struct arrow_1 res0;
	struct arrow_1* _1 = begin_ptr_11(a);
	res0 = subscript_88(_1, index);
	
	uint64_t new_size1;
	new_size1 = (a->size - 1u);
	
	struct arrow_1* _2 = begin_ptr_11(a);
	struct arrow_1* _3 = begin_ptr_11(a);
	struct arrow_1 _4 = subscript_88(_3, new_size1);
	set_subscript_16(_2, index, _4);
	a->size = new_size1;
	return res0;
}
/* is-empty<arrow<k, v>> bool(a mut-arr<arrow<str, str>>) */
uint8_t is_empty_14(struct mut_arr_4* a) {
	return (a->size == 0u);
}
/* set-subscript<arrow<k, v>> void(a mut-arr<arrow<str, str>>, index nat64, value arrow<str, str>) */
struct void_ set_subscript_17(struct ctx* ctx, struct mut_arr_4* a, uint64_t index, struct arrow_1 value) {
	uint8_t _0 = _less_0(index, a->size);
	assert_0(ctx, _0);
	struct arrow_1* _1 = begin_ptr_11(a);
	return set_subscript_16(_1, index, value);
}
/* move-to-dict!<str, str> dict<str, str>(a mut-dict<str, str>) */
struct dict_1 move_to_dict__e_1(struct ctx* ctx, struct mut_dict_1* a) {
	struct dict_1 res0;
	struct arr_13 _0 = map_to_arr_1(ctx, a, (struct fun_act2_15) {0, .as0 = (struct void_) {}});
	res0 = dict_2(ctx, _0);
	
	empty__e_1(ctx, a);
	return res0;
}
/* dict<k, v> dict<str, str>(a arr<arrow<str, str>>) */
struct dict_1 dict_2(struct ctx* ctx, struct arr_13 a) {
	uint8_t _0 = _lessOrEqual_0(a.size, 4u);uint8_t _1;
	
	if (_0) {
		_1 = no_duplicate_keys_1(ctx, a);
	} else {
		_1 = 0;
	}
	if (_1) {
		return (struct dict_1) {(struct void_) {}, (struct node_1) {1, .as1 = (struct leaf_node_1) {a}}};
	} else {
		struct dict_1 _2 = dict_3(ctx);
		return fold_19(ctx, _2, a, (struct fun_act2_13) {0, .as0 = (struct void_) {}});
	}
}
/* no-duplicate-keys<k, v> bool(a arr<arrow<str, str>>) */
uint8_t no_duplicate_keys_1(struct ctx* ctx, struct arr_13 a) {
	top:;
	uint8_t _0 = _lessOrEqual_0(a.size, 1u);
	if (_0) {
		return 1;
	} else {
		struct str key0;
		struct arrow_1 _1 = subscript_85(ctx, a, 0u);
		key0 = _1.from;
		
		struct arr_13 _2 = tail_4(ctx, a);
		struct no_duplicate_keys_1__lambda0* temp0;
		uint8_t* _3 = alloc(ctx, sizeof(struct no_duplicate_keys_1__lambda0));
		temp0 = ((struct no_duplicate_keys_1__lambda0*) _3);
		
		*temp0 = (struct no_duplicate_keys_1__lambda0) {key0};
		uint8_t _4 = every_2(ctx, _2, (struct fun_act1_21) {1, .as1 = temp0});
		if (_4) {
			struct arr_13 _5 = tail_4(ctx, a);
			a = _5;
			goto top;
		} else {
			return 0;
		}
	}
}
/* every<arrow<k, v>> bool(a arr<arrow<str, str>>, f fun-act1<bool, arrow<str, str>>) */
uint8_t every_2(struct ctx* ctx, struct arr_13 a, struct fun_act1_21 f) {
	top:;
	uint8_t _0 = is_empty_15(a);
	if (_0) {
		return 1;
	} else {
		struct arrow_1 _1 = subscript_85(ctx, a, 0u);
		uint8_t _2 = subscript_84(ctx, f, _1);
		if (_2) {
			struct arr_13 _3 = tail_4(ctx, a);
			a = _3;
			f = f;
			goto top;
		} else {
			return 0;
		}
	}
}
/* is-empty<a> bool(a arr<arrow<str, str>>) */
uint8_t is_empty_15(struct arr_13 a) {
	return (a.size == 0u);
}
/* tail<a> arr<arrow<str, str>>(a arr<arrow<str, str>>) */
struct arr_13 tail_4(struct ctx* ctx, struct arr_13 a) {
	uint8_t _0 = is_empty_15(a);
	forbid(ctx, _0);
	struct range _1 = _range(ctx, 1u, a.size);
	return subscript_83(ctx, a, _1);
}
/* no-duplicate-keys<k, v>.lambda0 bool(it arrow<str, str>) */
uint8_t no_duplicate_keys_1__lambda0(struct ctx* ctx, struct no_duplicate_keys_1__lambda0* _closure, struct arrow_1 it) {
	return _notEqual_8(it.from, _closure->key);
}
/* fold<dict<k, v>, arrow<k, v>> dict<str, str>(acc dict<str, str>, a arr<arrow<str, str>>, f fun-act2<dict<str, str>, dict<str, str>, arrow<str, str>>) */
struct dict_1 fold_19(struct ctx* ctx, struct dict_1 acc, struct arr_13 a, struct fun_act2_13 f) {
	struct arrow_1* _0 = end_ptr_9(a);
	return fold_recur_10(ctx, acc, a.begin_ptr, _0, f);
}
/* fold-recur<a, b> dict<str, str>(acc dict<str, str>, cur const-ptr<arrow<str, str>>, end const-ptr<arrow<str, str>>, f fun-act2<dict<str, str>, dict<str, str>, arrow<str, str>>) */
struct dict_1 fold_recur_10(struct ctx* ctx, struct dict_1 acc, struct arrow_1* cur, struct arrow_1* end, struct fun_act2_13 f) {
	top:;
	uint8_t _0 = _equal_11(cur, end);
	if (_0) {
		return acc;
	} else {
		struct arrow_1 _1 = _times_17(cur);
		struct dict_1 _2 = subscript_89(ctx, f, acc, _1);
		struct arrow_1* _3 = _plus_14(cur, 1u);
		acc = _2;
		cur = _3;
		end = end;
		f = f;
		goto top;
	}
}
/* subscript<a, a, b> dict<str, str>(a fun-act2<dict<str, str>, dict<str, str>, arrow<str, str>>, p0 dict<str, str>, p1 arrow<str, str>) */
struct dict_1 subscript_89(struct ctx* ctx, struct fun_act2_13 a, struct dict_1 p0, struct arrow_1 p1) {
	return call_w_ctx_937(a, ctx, p0, p1);
}
/* call-w-ctx<dict<str, str>, dict<str, str>, arrow<str, str>> (generated) (generated) */
struct dict_1 call_w_ctx_937(struct fun_act2_13 a, struct ctx* ctx, struct dict_1 p0, struct arrow_1 p1) {
	struct fun_act2_13 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return dict_2__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return (struct dict_1) {(struct void_) {}, (struct node_1) {0}};;
	}
}
/* dict<k, v> dict<str, str>() */
struct dict_1 dict_3(struct ctx* ctx) {
	struct leaf_node_1 _0 = empty_leaf_node_1(ctx);
	return (struct dict_1) {(struct void_) {}, (struct node_1) {1, .as1 = _0}};
}
/* empty-leaf-node<k, v> leaf-node<str, str>() */
struct leaf_node_1 empty_leaf_node_1(struct ctx* ctx) {
	return (struct leaf_node_1) {(struct arr_13) {0u, NULL}};
}
/* ~<k, v> dict<str, str>(a dict<str, str>, pair arrow<str, str>) */
struct dict_1 _tilde_5(struct ctx* ctx, struct dict_1 a, struct arrow_1 pair) {
	struct get_or_update_result_1 res0;
	struct _tilde_5__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct _tilde_5__lambda0));
	temp0 = ((struct _tilde_5__lambda0*) _0);
	
	*temp0 = (struct _tilde_5__lambda0) {pair};
	res0 = get_or_update_1(ctx, a, pair.from, (struct fun_act1_22) {0, .as0 = temp0});
	
	struct opt_19 _1 = res0.new_node;
	switch (_1.kind) {
		case 0: {
			return a;
		}
		case 1: {
			struct some_19 _matched1 = _1.as1;
			
			struct node_1 node2;
			node2 = _matched1.value;
			
			return (struct dict_1) {(struct void_) {}, node2};
		}
		default:
			
	return (struct dict_1) {(struct void_) {}, (struct node_1) {0}};;
	}
}
/* get-or-update<k, v> get-or-update-result<str, str>(a dict<str, str>, key str, f fun-act1<get-or-update-action<str>, opt<str>>) */
struct get_or_update_result_1 get_or_update_1(struct ctx* ctx, struct dict_1 a, struct str key, struct fun_act1_22 f) {
	uint64_t hash0;
	hash0 = hash(ctx, key);
	
	struct node_1 _0 = a.root;
	switch (_0.kind) {
		case 0: {
			return get_or_update_recur_1(ctx, a.root, key, hash0, 0u, f);
		}
		case 1: {
			struct leaf_node_1 l1 = _0.as1;
			
			return get_or_update_leaf_1(ctx, l1, key, hash0, 0u, f);
		}
		default:
			
	return (struct get_or_update_result_1) {(struct opt_19) {0}, (struct opt_16) {0}};;
	}
}
/* get-or-update-recur<k, v> get-or-update-result<str, str>(a node<str, str>, key str, remaining-hash nat64, hash-shift nat64, f fun-act1<get-or-update-action<str>, opt<str>>) */
struct get_or_update_result_1 get_or_update_recur_1(struct ctx* ctx, struct node_1 a, struct str key, uint64_t remaining_hash, uint64_t hash_shift, struct fun_act1_22 f) {
	struct node_1 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct inner_node_1 i0 = _0.as0;
			
			uint64_t which1;
			which1 = low_bits(ctx, remaining_hash);
			
			uint8_t _1 = _less_0(which1, i0.children.size);
			if (_1) {
				uint64_t next_hash2;
				next_hash2 = (remaining_hash >> 3u);
				
				struct get_or_update_result_1 child_res3;
				struct node_1 _2 = subscript_90(ctx, i0.children, which1);
				child_res3 = get_or_update_recur_1(ctx, _2, key, next_hash2, (hash_shift + 3u), f);
				
				struct opt_19 _3 = child_res3.new_node;
				switch (_3.kind) {
					case 0: {
						return child_res3;
					}
					case 1: {
						struct some_19 _matched4 = _3.as1;
						
						struct node_1 node5;
						node5 = _matched4.value;
						
						struct node_1 new_inner6;
						new_inner6 = update_child_1(ctx, i0, which1, node5);
						
						return (struct get_or_update_result_1) {(struct opt_19) {1, .as1 = (struct some_19) {new_inner6}}, child_res3.old_value};
					}
					default:
						
				return (struct get_or_update_result_1) {(struct opt_19) {0}, (struct opt_16) {0}};;
				}
			} else {
				struct get_or_update_action_1 _4 = subscript_95(ctx, f, (struct opt_16) {0, .as0 = (struct none) {}});
				switch (_4.kind) {
					case 0: {
						return (struct get_or_update_result_1) {(struct opt_19) {0, .as0 = (struct none) {}}, (struct opt_16) {0, .as0 = (struct none) {}}};
					}
					case 1: {
						return (struct get_or_update_result_1) {(struct opt_19) {0, .as0 = (struct none) {}}, (struct opt_16) {0, .as0 = (struct none) {}}};
					}
					case 2: {
						struct insert_1 ins7 = _4.as2;
						
						struct arrow_1 pair8;
						pair8 = _arrow_1(key, ins7.value);
						
						struct leaf_node_1 new_leaf9;
						struct arrow_1* temp0;
						uint8_t* _5 = alloc(ctx, (sizeof(struct arrow_1) * 1u));
						temp0 = ((struct arrow_1*) _5);
						
						*(temp0 + 0u) = pair8;
						new_leaf9 = (struct leaf_node_1) {(struct arr_13) {1u, temp0}};
						
						struct inner_node_1 new_node10;
						struct leaf_node_1 _6 = empty_leaf_node_1(ctx);
						struct arr_12 _7 = update_with_default_1(ctx, i0.children, which1, (struct node_1) {1, .as1 = new_leaf9}, (struct node_1) {1, .as1 = _6});
						new_node10 = (struct inner_node_1) {_7};
						
						return (struct get_or_update_result_1) {(struct opt_19) {1, .as1 = (struct some_19) {(struct node_1) {0, .as0 = new_node10}}}, (struct opt_16) {0, .as0 = (struct none) {}}};
					}
					default:
						
				return (struct get_or_update_result_1) {(struct opt_19) {0}, (struct opt_16) {0}};;
				}
			}
		}
		case 1: {
			struct leaf_node_1 l11 = _0.as1;
			
			return get_or_update_leaf_1(ctx, l11, key, remaining_hash, hash_shift, f);
		}
		default:
			
	return (struct get_or_update_result_1) {(struct opt_19) {0}, (struct opt_16) {0}};;
	}
}
/* subscript<node<k, v>> node<str, str>(a arr<node<str, str>>, index nat64) */
struct node_1 subscript_90(struct ctx* ctx, struct arr_12 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	return unsafe_at_14(a, index);
}
/* unsafe-at<a> node<str, str>(a arr<node<str, str>>, index nat64) */
struct node_1 unsafe_at_14(struct arr_12 a, uint64_t index) {
	return subscript_91(a.begin_ptr, index);
}
/* subscript<a> node<str, str>(a const-ptr<node<str, str>>, n nat64) */
struct node_1 subscript_91(struct node_1* a, uint64_t n) {
	struct node_1* _0 = _plus_15(a, n);
	return _times_18(_0);
}
/* *<a> node<str, str>(a const-ptr<node<str, str>>) */
struct node_1 _times_18(struct node_1* a) {
	return (*((struct node_1*) a));
}
/* +<a> const-ptr<node<str, str>>(a const-ptr<node<str, str>>, offset nat64) */
struct node_1* _plus_15(struct node_1* a, uint64_t offset) {
	return ((struct node_1*) (((struct node_1*) a) + offset));
}
/* update-child<k, v> node<str, str>(a inner-node<str, str>, which nat64, new-child node<str, str>) */
struct node_1 update_child_1(struct ctx* ctx, struct inner_node_1 a, uint64_t which, struct node_1 new_child) {
	struct opt_20 _0 = inner_node_to_leaf_1(ctx, a, which, new_child);
	switch (_0.kind) {
		case 0: {
			uint8_t _1 = node_is_empty_1(ctx, new_child);
			if (_1) {
				uint8_t _2 = (which == (a.children.size - 1u));
				if (_2) {
					struct arr_12 new_children0;
					new_children0 = rtail_1(ctx, a.children);
					
					uint8_t _3 = (new_children0.size == 1u);
					if (_3) {
						return subscript_90(ctx, new_children0, 0u);
					} else {
						return (struct node_1) {0, .as0 = (struct inner_node_1) {new_children0}};
					}
				} else {
					struct arr_12 new_children1;
					new_children1 = update_2(ctx, a.children, which, new_child);
					
					struct opt_19 _4 = find_only_non_empty_child_1(ctx, new_children1);
					switch (_4.kind) {
						case 0: {
							return (struct node_1) {0, .as0 = (struct inner_node_1) {new_children1}};
						}
						case 1: {
							struct some_19 _matched2 = _4.as1;
							
							struct node_1 child3;
							child3 = _matched2.value;
							
							return child3;
						}
						default:
							
					return (struct node_1) {0};;
					}
				}
			} else {
				struct arr_12 _5 = update_2(ctx, a.children, which, new_child);
				return (struct node_1) {0, .as0 = (struct inner_node_1) {_5}};
			}
		}
		case 1: {
			struct some_20 _matched4 = _0.as1;
			
			struct leaf_node_1 leaf5;
			leaf5 = _matched4.value;
			
			return (struct node_1) {1, .as1 = leaf5};
		}
		default:
			
	return (struct node_1) {0};;
	}
}
/* inner-node-to-leaf<k, v> opt<leaf-node<str, str>>(a inner-node<str, str>, which nat64, new-child node<str, str>) */
struct opt_20 inner_node_to_leaf_1(struct ctx* ctx, struct inner_node_1 a, uint64_t which, struct node_1 new_child) {
	uint64_t total_size0;
	struct inner_node_to_leaf_1__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct inner_node_to_leaf_1__lambda0));
	temp0 = ((struct inner_node_to_leaf_1__lambda0*) _0);
	
	*temp0 = (struct inner_node_to_leaf_1__lambda0) {which, new_child};
	total_size0 = fold_with_index_1(ctx, 0u, a.children, (struct fun_act3_4) {0, .as0 = temp0});
	
	uint64_t _1 = leaf_max_size(ctx);
	uint8_t _2 = _lessOrEqual_0(total_size0, _1);
	if (_2) {
		struct fix_arr_7 out1;
		out1 = uninitialized_fix_arr_6(ctx, total_size0);
		
		uint64_t end2;
		struct inner_node_to_leaf_1__lambda1* temp1;
		uint8_t* _3 = alloc(ctx, sizeof(struct inner_node_to_leaf_1__lambda1));
		temp1 = ((struct inner_node_to_leaf_1__lambda1*) _3);
		
		*temp1 = (struct inner_node_to_leaf_1__lambda1) {which, new_child, out1};
		end2 = fold_with_index_1(ctx, 0u, a.children, (struct fun_act3_4) {1, .as1 = temp1});
		
		uint64_t _4 = size_8(out1);
		assert_0(ctx, (end2 == _4));
		struct arr_13 _5 = cast_immutable_4(out1);
		return (struct opt_20) {1, .as1 = (struct some_20) {(struct leaf_node_1) {_5}}};
	} else {
		return (struct opt_20) {0, .as0 = (struct none) {}};
	}
}
/* fold-with-index<nat64, node<k, v>> nat64(acc nat64, a arr<node<str, str>>, f fun-act3<nat64, nat64, node<str, str>, nat64>) */
uint64_t fold_with_index_1(struct ctx* ctx, uint64_t acc, struct arr_12 a, struct fun_act3_4 f) {
	struct node_1* _0 = end_ptr_10(a);
	return fold_with_index_recur_1(ctx, acc, 0u, a.begin_ptr, _0, f);
}
/* fold-with-index-recur<a, b> nat64(acc nat64, index nat64, cur const-ptr<node<str, str>>, end const-ptr<node<str, str>>, f fun-act3<nat64, nat64, node<str, str>, nat64>) */
uint64_t fold_with_index_recur_1(struct ctx* ctx, uint64_t acc, uint64_t index, struct node_1* cur, struct node_1* end, struct fun_act3_4 f) {
	top:;
	uint8_t _0 = _equal_12(cur, end);
	if (_0) {
		return acc;
	} else {
		struct node_1 _1 = _times_18(cur);
		uint64_t _2 = subscript_92(ctx, f, acc, _1, index);
		uint64_t _3 = _plus_3(ctx, index, 1u);
		struct node_1* _4 = _plus_15(cur, 1u);
		acc = _2;
		index = _3;
		cur = _4;
		end = end;
		f = f;
		goto top;
	}
}
/* ==<b> bool(a const-ptr<node<str, str>>, b const-ptr<node<str, str>>) */
uint8_t _equal_12(struct node_1* a, struct node_1* b) {
	return (((struct node_1*) a) == ((struct node_1*) b));
}
/* subscript<a, a, b, nat64> nat64(a fun-act3<nat64, nat64, node<str, str>, nat64>, p0 nat64, p1 node<str, str>, p2 nat64) */
uint64_t subscript_92(struct ctx* ctx, struct fun_act3_4 a, uint64_t p0, struct node_1 p1, uint64_t p2) {
	return call_w_ctx_954(a, ctx, p0, p1, p2);
}
/* call-w-ctx<nat-64, nat-64, node<str, str>, nat-64> (generated) (generated) */
uint64_t call_w_ctx_954(struct fun_act3_4 a, struct ctx* ctx, uint64_t p0, struct node_1 p1, uint64_t p2) {
	struct fun_act3_4 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct inner_node_to_leaf_1__lambda0* closure0 = _0.as0;
			
			return inner_node_to_leaf_1__lambda0(ctx, closure0, p0, p1, p2);
		}
		case 1: {
			struct inner_node_to_leaf_1__lambda1* closure1 = _0.as1;
			
			return inner_node_to_leaf_1__lambda1(ctx, closure1, p0, p1, p2);
		}
		default:
			
	return 0;;
	}
}
/* end-ptr<b> const-ptr<node<str, str>>(a arr<node<str, str>>) */
struct node_1* end_ptr_10(struct arr_12 a) {
	return _plus_15(a.begin_ptr, a.size);
}
/* inner-node-to-leaf<k, v>.lambda0 nat64(cur nat64, child node<str, str>, child-index nat64) */
uint64_t inner_node_to_leaf_1__lambda0(struct ctx* ctx, struct inner_node_to_leaf_1__lambda0* _closure, uint64_t cur, struct node_1 child, uint64_t child_index) {
	struct node_1 new_child_here0;
	uint8_t _0 = (child_index == _closure->which);
	if (_0) {
		new_child_here0 = _closure->new_child;
	} else {
		new_child_here0 = child;
	}
	
	struct node_1 _1 = new_child_here0;
	switch (_1.kind) {
		case 0: {
			return 99u;
		}
		case 1: {
			struct leaf_node_1 l1 = _1.as1;
			
			return (cur + l1.pairs.size);
		}
		default:
			
	return 0;;
	}
}
/* copy-from!<arrow<k, v>> void(dest fix-arr<arrow<str, str>>, source arr<arrow<str, str>>) */
struct void_ copy_from__e_1(struct ctx* ctx, struct fix_arr_7 dest, struct arr_13 source) {
	uint64_t _0 = size_8(dest);
	assert_0(ctx, (_0 == source.size));
	struct arrow_1* _1 = begin_ptr_12(dest);
	uint8_t* _2 = as_any_const_ptr_4(source.begin_ptr);
	uint64_t _3 = size_8(dest);
	uint8_t* _4 = memcpy(((uint8_t*) _1), _2, (_3 * sizeof(struct arrow_1)));
	return drop_0(_4);
}
/* inner-node-to-leaf<k, v>.lambda1 nat64(out-index nat64, child node<str, str>, child-index nat64) */
uint64_t inner_node_to_leaf_1__lambda1(struct ctx* ctx, struct inner_node_to_leaf_1__lambda1* _closure, uint64_t out_index, struct node_1 child, uint64_t child_index) {
	struct node_1 new_child_here0;
	uint8_t _0 = (child_index == _closure->which);
	if (_0) {
		new_child_here0 = _closure->new_child;
	} else {
		new_child_here0 = child;
	}
	
	struct node_1 _1 = new_child_here0;
	switch (_1.kind) {
		case 0: {
			return unreachable_0(ctx);
		}
		case 1: {
			struct leaf_node_1 l1 = _1.as1;
			
			uint64_t new_out_index2;
			new_out_index2 = (out_index + l1.pairs.size);
			
			struct range _2 = _range(ctx, out_index, new_out_index2);
			struct fix_arr_7 _3 = subscript_82(ctx, _closure->out, _2);
			copy_from__e_1(ctx, _3, l1.pairs);
			return new_out_index2;
		}
		default:
			
	return 0;;
	}
}
/* cast-immutable<arrow<k, v>> arr<arrow<str, str>>(a fix-arr<arrow<str, str>>) */
struct arr_13 cast_immutable_4(struct fix_arr_7 a) {
	return a.inner;
}
/* node-is-empty<k, v> bool(a node<str, str>) */
uint8_t node_is_empty_1(struct ctx* ctx, struct node_1 a) {
	struct node_1 _0 = a;
	switch (_0.kind) {
		case 0: {
			return 0;
		}
		case 1: {
			struct leaf_node_1 l0 = _0.as1;
			
			return is_empty_15(l0.pairs);
		}
		default:
			
	return 0;;
	}
}
/* rtail<node<k, v>> arr<node<str, str>>(a arr<node<str, str>>) */
struct arr_12 rtail_1(struct ctx* ctx, struct arr_12 a) {
	uint8_t _0 = is_empty_16(a);
	forbid(ctx, _0);
	uint64_t _1 = _minus_5(ctx, a.size, 1u);
	struct range _2 = _range(ctx, 0u, _1);
	return subscript_93(ctx, a, _2);
}
/* is-empty<a> bool(a arr<node<str, str>>) */
uint8_t is_empty_16(struct arr_12 a) {
	return (a.size == 0u);
}
/* subscript<a> arr<node<str, str>>(a arr<node<str, str>>, range range<nat64>) */
struct arr_12 subscript_93(struct ctx* ctx, struct arr_12 a, struct range range) {
	uint8_t _0 = _lessOrEqual_0(range.high, a.size);
	assert_0(ctx, _0);
	struct node_1* _1 = _plus_15(a.begin_ptr, range.low);
	return (struct arr_12) {(range.high - range.low), _1};
}
/* update<node<k, v>> arr<node<str, str>>(a arr<node<str, str>>, index nat64, new-value node<str, str>) */
struct arr_12 update_2(struct ctx* ctx, struct arr_12 a, uint64_t index, struct node_1 new_value) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	struct range _1 = _range(ctx, 0u, index);
	struct arr_12 _2 = subscript_93(ctx, a, _1);
	struct node_1* temp0;
	uint8_t* _3 = alloc(ctx, (sizeof(struct node_1) * 1u));
	temp0 = ((struct node_1*) _3);
	
	*(temp0 + 0u) = new_value;
	struct arr_12 _4 = _tilde_6(ctx, _2, (struct arr_12) {1u, temp0});
	uint64_t _5 = _plus_3(ctx, index, 1u);
	struct range _6 = _range(ctx, _5, a.size);
	struct arr_12 _7 = subscript_93(ctx, a, _6);
	return _tilde_6(ctx, _4, _7);
}
/* ~<a> arr<node<str, str>>(a arr<node<str, str>>, b arr<node<str, str>>) */
struct arr_12 _tilde_6(struct ctx* ctx, struct arr_12 a, struct arr_12 b) {
	uint64_t res_size0;
	res_size0 = (a.size + b.size);
	
	struct node_1* res1;
	res1 = alloc_uninitialized_8(ctx, res_size0);
	
	copy_data_from__e_5(ctx, res1, a.begin_ptr, a.size);
	copy_data_from__e_5(ctx, (res1 + a.size), b.begin_ptr, b.size);
	return (struct arr_12) {res_size0, ((struct node_1*) res1)};
}
/* alloc-uninitialized<a> mut-ptr<node<str, str>>(size nat64) */
struct node_1* alloc_uninitialized_8(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(struct node_1)));
	return ((struct node_1*) _0);
}
/* copy-data-from!<a> void(to mut-ptr<node<str, str>>, from const-ptr<node<str, str>>, len nat64) */
struct void_ copy_data_from__e_5(struct ctx* ctx, struct node_1* to, struct node_1* from, uint64_t len) {
	uint8_t* _0 = as_any_const_ptr_5(from);
	uint8_t* _1 = memcpy(((uint8_t*) to), _0, (len * sizeof(struct node_1)));
	return drop_0(_1);
}
/* as-any-const-ptr<const-ptr<a>> const-ptr<nat8>(ref const-ptr<node<str, str>>) */
uint8_t* as_any_const_ptr_5(struct node_1* ref) {
	return ((uint8_t*) ((uint8_t*) ref));
}
/* find-only-non-empty-child<k, v> opt<node<str, str>>(children arr<node<str, str>>) */
struct opt_19 find_only_non_empty_child_1(struct ctx* ctx, struct arr_12 children) {
	uint64_t first_non_empty_index0;
	struct opt_11 _0 = find_index_6(ctx, children, (struct fun_act1_23) {0, .as0 = (struct void_) {}});
	first_non_empty_index0 = force_0(ctx, _0);
	
	struct range _1 = _range(ctx, (first_non_empty_index0 + 1u), children.size);
	struct arr_12 _2 = subscript_93(ctx, children, _1);
	uint8_t _3 = every_3(ctx, _2, (struct fun_act1_23) {1, .as1 = (struct void_) {}});
	if (_3) {
		struct node_1 _4 = subscript_90(ctx, children, first_non_empty_index0);
		return (struct opt_19) {1, .as1 = (struct some_19) {_4}};
	} else {
		return (struct opt_19) {0, .as0 = (struct none) {}};
	}
}
/* find-index<node<k, v>> opt<nat64>(a arr<node<str, str>>, f fun-act1<bool, node<str, str>>) */
struct opt_11 find_index_6(struct ctx* ctx, struct arr_12 a, struct fun_act1_23 f) {
	return find_index_recur_4(ctx, a, 0u, f);
}
/* find-index-recur<a> opt<nat64>(a arr<node<str, str>>, index nat64, f fun-act1<bool, node<str, str>>) */
struct opt_11 find_index_recur_4(struct ctx* ctx, struct arr_12 a, uint64_t index, struct fun_act1_23 f) {
	top:;
	uint8_t _0 = (index == a.size);
	if (_0) {
		return (struct opt_11) {0, .as0 = (struct none) {}};
	} else {
		struct node_1 _1 = subscript_90(ctx, a, index);
		uint8_t _2 = subscript_94(ctx, f, _1);
		if (_2) {
			return (struct opt_11) {1, .as1 = (struct some_11) {index}};
		} else {
			uint64_t _3 = _plus_3(ctx, index, 1u);
			a = a;
			index = _3;
			f = f;
			goto top;
		}
	}
}
/* subscript<bool, a> bool(a fun-act1<bool, node<str, str>>, p0 node<str, str>) */
uint8_t subscript_94(struct ctx* ctx, struct fun_act1_23 a, struct node_1 p0) {
	return call_w_ctx_973(a, ctx, p0);
}
/* call-w-ctx<bool, node<str, str>> (generated) (generated) */
uint8_t call_w_ctx_973(struct fun_act1_23 a, struct ctx* ctx, struct node_1 p0) {
	struct fun_act1_23 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return find_only_non_empty_child_1__lambda0(ctx, closure0, p0);
		}
		case 1: {
			struct void_ closure1 = _0.as1;
			
			return find_only_non_empty_child_1__lambda1(ctx, closure1, p0);
		}
		default:
			
	return 0;;
	}
}
/* find-only-non-empty-child<k, v>.lambda0 bool(it node<str, str>) */
uint8_t find_only_non_empty_child_1__lambda0(struct ctx* ctx, struct void_ _closure, struct node_1 it) {
	uint8_t _0 = node_is_empty_1(ctx, it);
	return _not(_0);
}
/* every<node<k, v>> bool(a arr<node<str, str>>, f fun-act1<bool, node<str, str>>) */
uint8_t every_3(struct ctx* ctx, struct arr_12 a, struct fun_act1_23 f) {
	top:;
	uint8_t _0 = is_empty_16(a);
	if (_0) {
		return 1;
	} else {
		struct node_1 _1 = subscript_90(ctx, a, 0u);
		uint8_t _2 = subscript_94(ctx, f, _1);
		if (_2) {
			struct arr_12 _3 = tail_5(ctx, a);
			a = _3;
			f = f;
			goto top;
		} else {
			return 0;
		}
	}
}
/* tail<a> arr<node<str, str>>(a arr<node<str, str>>) */
struct arr_12 tail_5(struct ctx* ctx, struct arr_12 a) {
	uint8_t _0 = is_empty_16(a);
	forbid(ctx, _0);
	struct range _1 = _range(ctx, 1u, a.size);
	return subscript_93(ctx, a, _1);
}
/* find-only-non-empty-child<k, v>.lambda1 bool(it node<str, str>) */
uint8_t find_only_non_empty_child_1__lambda1(struct ctx* ctx, struct void_ _closure, struct node_1 it) {
	return node_is_empty_1(ctx, it);
}
/* subscript<get-or-update-action<v>, opt<v>> get-or-update-action<str>(a fun-act1<get-or-update-action<str>, opt<str>>, p0 opt<str>) */
struct get_or_update_action_1 subscript_95(struct ctx* ctx, struct fun_act1_22 a, struct opt_16 p0) {
	return call_w_ctx_979(a, ctx, p0);
}
/* call-w-ctx<get-or-update-action<str>, opt<str>> (generated) (generated) */
struct get_or_update_action_1 call_w_ctx_979(struct fun_act1_22 a, struct ctx* ctx, struct opt_16 p0) {
	struct fun_act1_22 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct _tilde_5__lambda0* closure0 = _0.as0;
			
			return _tilde_5__lambda0(ctx, closure0, p0);
		}
		default:
			
	return (struct get_or_update_action_1) {0};;
	}
}
/* update-with-default<node<k, v>> arr<node<str, str>>(a arr<node<str, str>>, index nat64, new-value node<str, str>, default node<str, str>) */
struct arr_12 update_with_default_1(struct ctx* ctx, struct arr_12 a, uint64_t index, struct node_1 new_value, struct node_1 _default) {
	uint8_t _0 = _less_0(index, a.size);
	if (_0) {
		return update_2(ctx, a, index, new_value);
	} else {
		uint64_t _1 = _plus_3(ctx, index, 1u);
		struct update_with_default_1__lambda0* temp0;
		uint8_t* _2 = alloc(ctx, sizeof(struct update_with_default_1__lambda0));
		temp0 = ((struct update_with_default_1__lambda0*) _2);
		
		*temp0 = (struct update_with_default_1__lambda0) {a, index, new_value, _default};
		return make_arr_2(ctx, _1, (struct fun_act1_24) {0, .as0 = temp0});
	}
}
/* make-arr<a> arr<node<str, str>>(size nat64, f fun-act1<node<str, str>, nat64>) */
struct arr_12 make_arr_2(struct ctx* ctx, uint64_t size, struct fun_act1_24 f) {
	struct node_1* res0;
	res0 = alloc_uninitialized_8(ctx, size);
	
	fill_ptr_range_5(ctx, res0, size, f);
	return (struct arr_12) {size, ((struct node_1*) res0)};
}
/* fill-ptr-range<a> void(begin mut-ptr<node<str, str>>, size nat64, f fun-act1<node<str, str>, nat64>) */
struct void_ fill_ptr_range_5(struct ctx* ctx, struct node_1* begin, uint64_t size, struct fun_act1_24 f) {
	return fill_ptr_range_recur_5(ctx, begin, 0u, size, f);
}
/* fill-ptr-range-recur<a> void(begin mut-ptr<node<str, str>>, i nat64, size nat64, f fun-act1<node<str, str>, nat64>) */
struct void_ fill_ptr_range_recur_5(struct ctx* ctx, struct node_1* begin, uint64_t i, uint64_t size, struct fun_act1_24 f) {
	top:;
	uint8_t _0 = _notEqual_5(i, size);
	if (_0) {
		struct node_1 _1 = subscript_96(ctx, f, i);
		set_subscript_18(begin, i, _1);
		begin = begin;
		i = (i + 1u);
		size = size;
		f = f;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* set-subscript<a> void(a mut-ptr<node<str, str>>, n nat64, value node<str, str>) */
struct void_ set_subscript_18(struct node_1* a, uint64_t n, struct node_1 value) {
	return (*(a + n) = value, (struct void_) {});
}
/* subscript<a, nat64> node<str, str>(a fun-act1<node<str, str>, nat64>, p0 nat64) */
struct node_1 subscript_96(struct ctx* ctx, struct fun_act1_24 a, uint64_t p0) {
	return call_w_ctx_986(a, ctx, p0);
}
/* call-w-ctx<node<str, str>, nat-64> (generated) (generated) */
struct node_1 call_w_ctx_986(struct fun_act1_24 a, struct ctx* ctx, uint64_t p0) {
	struct fun_act1_24 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct update_with_default_1__lambda0* closure0 = _0.as0;
			
			return update_with_default_1__lambda0(ctx, closure0, p0);
		}
		case 1: {
			struct fill_fix_arr_4__lambda0* closure1 = _0.as1;
			
			return fill_fix_arr_4__lambda0(ctx, closure1, p0);
		}
		default:
			
	return (struct node_1) {0};;
	}
}
/* update-with-default<node<k, v>>.lambda0 node<str, str>(i nat64) */
struct node_1 update_with_default_1__lambda0(struct ctx* ctx, struct update_with_default_1__lambda0* _closure, uint64_t i) {
	uint8_t _0 = _less_0(i, _closure->a.size);
	if (_0) {
		return subscript_90(ctx, _closure->a, i);
	} else {
		uint8_t _1 = (i == _closure->index);
		if (_1) {
			return _closure->new_value;
		} else {
			return _closure->_default;
		}
	}
}
/* get-or-update-leaf<k, v> get-or-update-result<str, str>(a leaf-node<str, str>, key str, remaining-hash nat64, hash-shift nat64, f fun-act1<get-or-update-action<str>, opt<str>>) */
struct get_or_update_result_1 get_or_update_leaf_1(struct ctx* ctx, struct leaf_node_1 a, struct str key, uint64_t remaining_hash, uint64_t hash_shift, struct fun_act1_22 f) {
	struct get_or_update_leaf_1__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct get_or_update_leaf_1__lambda0));
	temp0 = ((struct get_or_update_leaf_1__lambda0*) _0);
	
	*temp0 = (struct get_or_update_leaf_1__lambda0) {key};
	struct opt_11 _1 = find_index_5(ctx, a.pairs, (struct fun_act1_21) {2, .as2 = temp0});
	switch (_1.kind) {
		case 0: {
			struct opt_19 new_node1;
			struct get_or_update_action_1 _2 = subscript_95(ctx, f, (struct opt_16) {0, .as0 = (struct none) {}});
			switch (_2.kind) {
				case 0: {
					new_node1 = (struct opt_19) {0, .as0 = (struct none) {}};
					break;
				}
				case 1: {
					new_node1 = (struct opt_19) {0, .as0 = (struct none) {}};
					break;
				}
				case 2: {
					struct insert_1 ins0 = _2.as2;
					
					uint64_t _3 = leaf_max_size(ctx);
					uint8_t _4 = _greaterOrEqual(a.pairs.size, _3);struct node_1 _5;
					
					if (_4) {
						uint8_t _6 = _greaterOrEqual(hash_shift, 64u);
						if (_6) {
							todo_0();
						} else {
							(struct void_) {};
						}
						struct inner_node_1 _7 = new_inner_node_1(ctx, a, key, ins0.value, remaining_hash, hash_shift);
						_5 = (struct node_1) {0, .as0 = _7};
					} else {
						struct arrow_1* temp1;
						uint8_t* _8 = alloc(ctx, (sizeof(struct arrow_1) * 1u));
						temp1 = ((struct arrow_1*) _8);
						
						struct arrow_1 _9 = _arrow_1(key, ins0.value);
						*(temp1 + 0u) = _9;
						struct arr_13 _10 = _tilde_7(ctx, a.pairs, (struct arr_13) {1u, temp1});
						_5 = (struct node_1) {1, .as1 = (struct leaf_node_1) {_10}};
					}
					new_node1 = (struct opt_19) {1, .as1 = (struct some_19) {_5}};
					break;
				}
				default:
					
			new_node1 = (struct opt_19) {0};;
			}
			
			return (struct get_or_update_result_1) {new_node1, (struct opt_16) {0, .as0 = (struct none) {}}};
		}
		case 1: {
			struct some_11 _matched2 = _1.as1;
			
			uint64_t index3;
			index3 = _matched2.value;
			
			struct str old_value4;
			struct arrow_1 _11 = subscript_85(ctx, a.pairs, index3);
			old_value4 = _11.to;
			
			struct opt_19 new_node6;
			struct get_or_update_action_1 _12 = subscript_95(ctx, f, (struct opt_16) {1, .as1 = (struct some_16) {old_value4}});
			switch (_12.kind) {
				case 0: {
					new_node6 = (struct opt_19) {0, .as0 = (struct none) {}};
					break;
				}
				case 1: {
					struct arr_13 _13 = remove_at_1(ctx, a.pairs, index3);
					new_node6 = (struct opt_19) {1, .as1 = (struct some_19) {(struct node_1) {1, .as1 = (struct leaf_node_1) {_13}}}};
					break;
				}
				case 2: {
					struct insert_1 ins5 = _12.as2;
					
					struct arrow_1 _14 = _arrow_1(key, ins5.value);
					struct arr_13 _15 = update_3(ctx, a.pairs, index3, _14);
					new_node6 = (struct opt_19) {1, .as1 = (struct some_19) {(struct node_1) {1, .as1 = (struct leaf_node_1) {_15}}}};
					break;
				}
				default:
					
			new_node6 = (struct opt_19) {0};;
			}
			
			return (struct get_or_update_result_1) {new_node6, (struct opt_16) {1, .as1 = (struct some_16) {old_value4}}};
		}
		default:
			
	return (struct get_or_update_result_1) {(struct opt_19) {0}, (struct opt_16) {0}};;
	}
}
/* get-or-update-leaf<k, v>.lambda0 bool(it arrow<str, str>) */
uint8_t get_or_update_leaf_1__lambda0(struct ctx* ctx, struct get_or_update_leaf_1__lambda0* _closure, struct arrow_1 it) {
	return _equal_5(it.from, _closure->key);
}
/* new-inner-node<k, v> inner-node<str, str>(a leaf-node<str, str>, key str, value str, hash nat64, hash-shift nat64) */
struct inner_node_1 new_inner_node_1(struct ctx* ctx, struct leaf_node_1 a, struct str key, struct str value, uint64_t hash, uint64_t hash_shift) {
	uint64_t key_hash0;
	key_hash0 = low_bits(ctx, hash);
	
	uint64_t max_hash1;
	struct new_inner_node_1__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct new_inner_node_1__lambda0));
	temp0 = ((struct new_inner_node_1__lambda0*) _0);
	
	*temp0 = (struct new_inner_node_1__lambda0) {hash_shift};
	max_hash1 = fold_20(ctx, key_hash0, a.pairs, (struct fun_act2_14) {0, .as0 = temp0});
	
	struct fix_arr_9 res2;
	struct leaf_node_1 _1 = empty_leaf_node_1(ctx);
	res2 = fill_fix_arr_4(ctx, (max_hash1 + 1u), (struct node_1) {1, .as1 = _1});
	
	struct arrow_1* temp1;
	uint8_t* _2 = alloc(ctx, (sizeof(struct arrow_1) * 1u));
	temp1 = ((struct arrow_1*) _2);
	
	struct arrow_1 _3 = _arrow_1(key, value);
	*(temp1 + 0u) = _3;
	set_subscript_19(ctx, res2, key_hash0, (struct node_1) {1, .as1 = (struct leaf_node_1) {(struct arr_13) {1u, temp1}}});
	struct new_inner_node_1__lambda1* temp2;
	uint8_t* _4 = alloc(ctx, sizeof(struct new_inner_node_1__lambda1));
	temp2 = ((struct new_inner_node_1__lambda1*) _4);
	
	*temp2 = (struct new_inner_node_1__lambda1) {hash_shift, res2};
	each_6(ctx, a.pairs, (struct fun_act1_20) {1, .as1 = temp2});
	struct arr_12 _5 = cast_immutable_5(res2);
	return (struct inner_node_1) {_5};
}
/* fold<nat64, arrow<k, v>> nat64(acc nat64, a arr<arrow<str, str>>, f fun-act2<nat64, nat64, arrow<str, str>>) */
uint64_t fold_20(struct ctx* ctx, uint64_t acc, struct arr_13 a, struct fun_act2_14 f) {
	struct arrow_1* _0 = end_ptr_9(a);
	return fold_recur_11(ctx, acc, a.begin_ptr, _0, f);
}
/* fold-recur<a, b> nat64(acc nat64, cur const-ptr<arrow<str, str>>, end const-ptr<arrow<str, str>>, f fun-act2<nat64, nat64, arrow<str, str>>) */
uint64_t fold_recur_11(struct ctx* ctx, uint64_t acc, struct arrow_1* cur, struct arrow_1* end, struct fun_act2_14 f) {
	top:;
	uint8_t _0 = _equal_11(cur, end);
	if (_0) {
		return acc;
	} else {
		struct arrow_1 _1 = _times_17(cur);
		uint64_t _2 = subscript_97(ctx, f, acc, _1);
		struct arrow_1* _3 = _plus_14(cur, 1u);
		acc = _2;
		cur = _3;
		end = end;
		f = f;
		goto top;
	}
}
/* subscript<a, a, b> nat64(a fun-act2<nat64, nat64, arrow<str, str>>, p0 nat64, p1 arrow<str, str>) */
uint64_t subscript_97(struct ctx* ctx, struct fun_act2_14 a, uint64_t p0, struct arrow_1 p1) {
	return call_w_ctx_994(a, ctx, p0, p1);
}
/* call-w-ctx<nat-64, nat-64, arrow<str, str>> (generated) (generated) */
uint64_t call_w_ctx_994(struct fun_act2_14 a, struct ctx* ctx, uint64_t p0, struct arrow_1 p1) {
	struct fun_act2_14 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct new_inner_node_1__lambda0* closure0 = _0.as0;
			
			return new_inner_node_1__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return 0;;
	}
}
/* new-inner-node<k, v>.lambda0 nat64(cur nat64, pair arrow<str, str>) */
uint64_t new_inner_node_1__lambda0(struct ctx* ctx, struct new_inner_node_1__lambda0* _closure, uint64_t cur, struct arrow_1 pair) {
	uint64_t _0 = hash(ctx, pair.from);
	uint64_t _1 = low_bits(ctx, (_0 >> _closure->hash_shift));
	return max(cur, _1);
}
/* fill-fix-arr<node<k, v>> fix-arr<node<str, str>>(size nat64, value node<str, str>) */
struct fix_arr_9 fill_fix_arr_4(struct ctx* ctx, uint64_t size, struct node_1 value) {
	struct fill_fix_arr_4__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct fill_fix_arr_4__lambda0));
	temp0 = ((struct fill_fix_arr_4__lambda0*) _0);
	
	*temp0 = (struct fill_fix_arr_4__lambda0) {value};
	return make_fix_arr_4(ctx, size, (struct fun_act1_24) {1, .as1 = temp0});
}
/* make-fix-arr<a> fix-arr<node<str, str>>(size nat64, f fun-act1<node<str, str>, nat64>) */
struct fix_arr_9 make_fix_arr_4(struct ctx* ctx, uint64_t size, struct fun_act1_24 f) {
	struct fix_arr_9 res0;
	res0 = uninitialized_fix_arr_7(ctx, size);
	
	struct node_1* _0 = begin_ptr_13(res0);
	fill_ptr_range_5(ctx, _0, size, f);
	return res0;
}
/* uninitialized-fix-arr<a> fix-arr<node<str, str>>(size nat64) */
struct fix_arr_9 uninitialized_fix_arr_7(struct ctx* ctx, uint64_t size) {
	struct node_1* _0 = alloc_uninitialized_8(ctx, size);
	return fix_arr_17(size, _0);
}
/* fix-arr<a> fix-arr<node<str, str>>(size nat64, begin-ptr mut-ptr<node<str, str>>) */
struct fix_arr_9 fix_arr_17(uint64_t size, struct node_1* begin_ptr) {
	return (struct fix_arr_9) {(struct void_) {}, (struct arr_12) {size, ((struct node_1*) begin_ptr)}};
}
/* begin-ptr<a> mut-ptr<node<str, str>>(a fix-arr<node<str, str>>) */
struct node_1* begin_ptr_13(struct fix_arr_9 a) {
	return ((struct node_1*) a.inner.begin_ptr);
}
/* fill-fix-arr<node<k, v>>.lambda0 node<str, str>(ignore nat64) */
struct node_1 fill_fix_arr_4__lambda0(struct ctx* ctx, struct fill_fix_arr_4__lambda0* _closure, uint64_t ignore) {
	return _closure->value;
}
/* set-subscript<node<k, v>> void(a fix-arr<node<str, str>>, index nat64, value node<str, str>) */
struct void_ set_subscript_19(struct ctx* ctx, struct fix_arr_9 a, uint64_t index, struct node_1 value) {
	uint64_t _0 = size_9(a);
	uint8_t _1 = _less_0(index, _0);
	assert_0(ctx, _1);
	return unsafe_set_at__e_3(ctx, a, index, value);
}
/* size<a> nat64(a fix-arr<node<str, str>>) */
uint64_t size_9(struct fix_arr_9 a) {
	return a.inner.size;
}
/* unsafe-set-at!<a> void(a fix-arr<node<str, str>>, index nat64, value node<str, str>) */
struct void_ unsafe_set_at__e_3(struct ctx* ctx, struct fix_arr_9 a, uint64_t index, struct node_1 value) {
	struct node_1* _0 = begin_ptr_13(a);
	return set_subscript_18(_0, index, value);
}
/* subscript<node<k, v>> node<str, str>(a fix-arr<node<str, str>>, index nat64) */
struct node_1 subscript_98(struct ctx* ctx, struct fix_arr_9 a, uint64_t index) {
	uint64_t _0 = size_9(a);
	uint8_t _1 = _less_0(index, _0);
	assert_0(ctx, _1);
	return unsafe_at_15(ctx, a, index);
}
/* unsafe-at<a> node<str, str>(a fix-arr<node<str, str>>, index nat64) */
struct node_1 unsafe_at_15(struct ctx* ctx, struct fix_arr_9 a, uint64_t index) {
	struct node_1* _0 = begin_ptr_13(a);
	return subscript_99(_0, index);
}
/* subscript<a> node<str, str>(a mut-ptr<node<str, str>>, n nat64) */
struct node_1 subscript_99(struct node_1* a, uint64_t n) {
	return (*(a + n));
}
/* unreachable<node<k, v>> node<str, str>() */
struct node_1 unreachable_2(struct ctx* ctx) {
	return throw_8(ctx, (struct str) {{21, constantarr_0_15}});
}
/* throw<a> node<str, str>(message str) */
struct node_1 throw_8(struct ctx* ctx, struct str message) {
	struct backtrace _0 = get_backtrace(ctx);
	return throw_9(ctx, (struct exception) {message, _0});
}
/* throw<a> node<str, str>(e exception) */
struct node_1 throw_9(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx0;
	exn_ctx0 = get_exception_ctx(ctx);
	
	uint8_t _0 = _notEqual_3(exn_ctx0->jmp_buf_ptr, NULL);
	hard_assert(_0);
	exn_ctx0->thrown_exception = e;
	int32_t _1 = number_to_throw(ctx);
	(longjmp(exn_ctx0->jmp_buf_ptr, _1), (struct void_) {});
	return hard_unreachable_5();
}
/* hard-unreachable<a> node<str, str>() */
struct node_1 hard_unreachable_5(void) {
	(abort(), (struct void_) {});
	return (struct node_1) {0};
}
/* ~<arrow<k, v>> arr<arrow<str, str>>(a arr<arrow<str, str>>, b arr<arrow<str, str>>) */
struct arr_13 _tilde_7(struct ctx* ctx, struct arr_13 a, struct arr_13 b) {
	uint64_t res_size0;
	res_size0 = (a.size + b.size);
	
	struct arrow_1* res1;
	res1 = alloc_uninitialized_7(ctx, res_size0);
	
	copy_data_from__e_4(ctx, res1, a.begin_ptr, a.size);
	copy_data_from__e_4(ctx, (res1 + a.size), b.begin_ptr, b.size);
	return (struct arr_13) {res_size0, ((struct arrow_1*) res1)};
}
/* new-inner-node<k, v>.lambda1 void(pair arrow<str, str>) */
struct void_ new_inner_node_1__lambda1(struct ctx* ctx, struct new_inner_node_1__lambda1* _closure, struct arrow_1 pair) {
	uint64_t x0;
	uint64_t _0 = hash(ctx, pair.from);
	x0 = low_bits(ctx, (_0 >> _closure->hash_shift));
	
	struct node_1 _1 = subscript_98(ctx, _closure->res, x0);struct node_1 _2;
	
	switch (_1.kind) {
		case 0: {
			_2 = unreachable_2(ctx);
			break;
		}
		case 1: {
			struct leaf_node_1 l1 = _1.as1;
			
			struct arrow_1* temp0;
			uint8_t* _3 = alloc(ctx, (sizeof(struct arrow_1) * 1u));
			temp0 = ((struct arrow_1*) _3);
			
			*(temp0 + 0u) = pair;
			struct arr_13 _4 = _tilde_7(ctx, l1.pairs, (struct arr_13) {1u, temp0});
			_2 = (struct node_1) {1, .as1 = (struct leaf_node_1) {_4}};
			break;
		}
		default:
			
	_2 = (struct node_1) {0};;
	}
	return set_subscript_19(ctx, _closure->res, x0, _2);
}
/* cast-immutable<node<k, v>> arr<node<str, str>>(a fix-arr<node<str, str>>) */
struct arr_12 cast_immutable_5(struct fix_arr_9 a) {
	return a.inner;
}
/* remove-at<arrow<k, v>> arr<arrow<str, str>>(a arr<arrow<str, str>>, index nat64) */
struct arr_13 remove_at_1(struct ctx* ctx, struct arr_13 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	struct range _1 = _range(ctx, 0u, index);
	struct arr_13 _2 = subscript_83(ctx, a, _1);
	uint64_t _3 = _plus_3(ctx, index, 1u);
	struct range _4 = _range(ctx, _3, a.size);
	struct arr_13 _5 = subscript_83(ctx, a, _4);
	return _tilde_7(ctx, _2, _5);
}
/* update<arrow<k, v>> arr<arrow<str, str>>(a arr<arrow<str, str>>, index nat64, new-value arrow<str, str>) */
struct arr_13 update_3(struct ctx* ctx, struct arr_13 a, uint64_t index, struct arrow_1 new_value) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	struct range _1 = _range(ctx, 0u, index);
	struct arr_13 _2 = subscript_83(ctx, a, _1);
	struct arrow_1* temp0;
	uint8_t* _3 = alloc(ctx, (sizeof(struct arrow_1) * 1u));
	temp0 = ((struct arrow_1*) _3);
	
	*(temp0 + 0u) = new_value;
	struct arr_13 _4 = _tilde_7(ctx, _2, (struct arr_13) {1u, temp0});
	uint64_t _5 = _plus_3(ctx, index, 1u);
	struct range _6 = _range(ctx, _5, a.size);
	struct arr_13 _7 = subscript_83(ctx, a, _6);
	return _tilde_7(ctx, _4, _7);
}
/* ~<k, v>.lambda0 get-or-update-action<str>(old-value opt<str>) */
struct get_or_update_action_1 _tilde_5__lambda0(struct ctx* ctx, struct _tilde_5__lambda0* _closure, struct opt_16 old_value) {
	return (struct get_or_update_action_1) {2, .as2 = (struct insert_1) {_closure->pair.to}};
}
/* dict<k, v>.lambda0 dict<str, str>(cur dict<str, str>, x arrow<str, str>) */
struct dict_1 dict_2__lambda0(struct ctx* ctx, struct void_ _closure, struct dict_1 cur, struct arrow_1 x) {
	return _tilde_5(ctx, cur, x);
}
/* map-to-arr<arrow<k, v>, k, v> arr<arrow<str, str>>(a mut-dict<str, str>, f fun-act2<arrow<str, str>, str, str>) */
struct arr_13 map_to_arr_1(struct ctx* ctx, struct mut_dict_1* a, struct fun_act2_15 f) {
	struct fix_arr_7 out0;
	uint64_t _0 = size_10(ctx, a);
	out0 = uninitialized_fix_arr_6(ctx, _0);
	
	struct arrow_1* end1;
	struct arrow_1* _1 = begin_ptr_12(out0);
	struct map_to_arr_1__lambda0* temp0;
	uint8_t* _2 = alloc(ctx, sizeof(struct map_to_arr_1__lambda0));
	temp0 = ((struct map_to_arr_1__lambda0*) _2);
	
	*temp0 = (struct map_to_arr_1__lambda0) {f};
	end1 = fold_21(ctx, _1, a, (struct fun_act3_5) {0, .as0 = temp0});
	
	struct arrow_1* _3 = end_ptr_11(out0);
	assert_0(ctx, (end1 == _3));
	return cast_immutable_4(out0);
}
/* size<k, v> nat64(a mut-dict<str, str>) */
uint64_t size_10(struct ctx* ctx, struct mut_dict_1* a) {
	return a->total_size;
}
/* fold<mut-ptr<out>, k, v> mut-ptr<arrow<str, str>>(acc mut-ptr<arrow<str, str>>, a mut-dict<str, str>, f fun-act3<mut-ptr<arrow<str, str>>, mut-ptr<arrow<str, str>>, str, str>) */
struct arrow_1* fold_21(struct ctx* ctx, struct arrow_1* acc, struct mut_dict_1* a, struct fun_act3_5 f) {
	struct fold_21__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct fold_21__lambda0));
	temp0 = ((struct fold_21__lambda0*) _0);
	
	*temp0 = (struct fold_21__lambda0) {f};
	return fold_22(ctx, acc, a->entries, (struct fun_act2_16) {0, .as0 = temp0});
}
/* fold<a, entry<k, v>> mut-ptr<arrow<str, str>>(acc mut-ptr<arrow<str, str>>, a fix-arr<entry<str, str>>, f fun-act2<mut-ptr<arrow<str, str>>, mut-ptr<arrow<str, str>>, entry<str, str>>) */
struct arrow_1* fold_22(struct ctx* ctx, struct arrow_1* acc, struct fix_arr_8 a, struct fun_act2_16 f) {
	struct arr_14 _0 = temp_as_arr_5(a);
	return fold_23(ctx, acc, _0, f);
}
/* fold<a, b> mut-ptr<arrow<str, str>>(acc mut-ptr<arrow<str, str>>, a arr<entry<str, str>>, f fun-act2<mut-ptr<arrow<str, str>>, mut-ptr<arrow<str, str>>, entry<str, str>>) */
struct arrow_1* fold_23(struct ctx* ctx, struct arrow_1* acc, struct arr_14 a, struct fun_act2_16 f) {
	struct entry_1* _0 = end_ptr_8(a);
	return fold_recur_12(ctx, acc, a.begin_ptr, _0, f);
}
/* fold-recur<a, b> mut-ptr<arrow<str, str>>(acc mut-ptr<arrow<str, str>>, cur const-ptr<entry<str, str>>, end const-ptr<entry<str, str>>, f fun-act2<mut-ptr<arrow<str, str>>, mut-ptr<arrow<str, str>>, entry<str, str>>) */
struct arrow_1* fold_recur_12(struct ctx* ctx, struct arrow_1* acc, struct entry_1* cur, struct entry_1* end, struct fun_act2_16 f) {
	top:;
	uint8_t _0 = _equal_10(cur, end);
	if (_0) {
		return acc;
	} else {
		struct entry_1 _1 = _times_16(cur);
		struct arrow_1* _2 = subscript_100(ctx, f, acc, _1);
		struct entry_1* _3 = _plus_13(cur, 1u);
		acc = _2;
		cur = _3;
		end = end;
		f = f;
		goto top;
	}
}
/* subscript<a, a, b> mut-ptr<arrow<str, str>>(a fun-act2<mut-ptr<arrow<str, str>>, mut-ptr<arrow<str, str>>, entry<str, str>>, p0 mut-ptr<arrow<str, str>>, p1 entry<str, str>) */
struct arrow_1* subscript_100(struct ctx* ctx, struct fun_act2_16 a, struct arrow_1* p0, struct entry_1 p1) {
	return call_w_ctx_1026(a, ctx, p0, p1);
}
/* call-w-ctx<raw-ptr-mut(arrow<str, str>), raw-ptr-mut(arrow<str, str>), entry<str, str>> (generated) (generated) */
struct arrow_1* call_w_ctx_1026(struct fun_act2_16 a, struct ctx* ctx, struct arrow_1* p0, struct entry_1 p1) {
	struct fun_act2_16 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct fold_21__lambda0* closure0 = _0.as0;
			
			return fold_21__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return NULL;;
	}
}
/* subscript<a, a, k, v> mut-ptr<arrow<str, str>>(a fun-act3<mut-ptr<arrow<str, str>>, mut-ptr<arrow<str, str>>, str, str>, p0 mut-ptr<arrow<str, str>>, p1 str, p2 str) */
struct arrow_1* subscript_101(struct ctx* ctx, struct fun_act3_5 a, struct arrow_1* p0, struct str p1, struct str p2) {
	return call_w_ctx_1028(a, ctx, p0, p1, p2);
}
/* call-w-ctx<raw-ptr-mut(arrow<str, str>), raw-ptr-mut(arrow<str, str>), str, str> (generated) (generated) */
struct arrow_1* call_w_ctx_1028(struct fun_act3_5 a, struct ctx* ctx, struct arrow_1* p0, struct str p1, struct str p2) {
	struct fun_act3_5 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct map_to_arr_1__lambda0* closure0 = _0.as0;
			
			return map_to_arr_1__lambda0(ctx, closure0, p0, p1, p2);
		}
		default:
			
	return NULL;;
	}
}
/* fold<a, arrow<k, v>> mut-ptr<arrow<str, str>>(acc mut-ptr<arrow<str, str>>, a mut-arr<arrow<str, str>>, f fun-act2<mut-ptr<arrow<str, str>>, mut-ptr<arrow<str, str>>, arrow<str, str>>) */
struct arrow_1* fold_24(struct ctx* ctx, struct arrow_1* acc, struct mut_arr_4* a, struct fun_act2_17 f) {
	struct arr_13 _0 = temp_as_arr_6(a);
	return fold_25(ctx, acc, _0, f);
}
/* fold<a, b> mut-ptr<arrow<str, str>>(acc mut-ptr<arrow<str, str>>, a arr<arrow<str, str>>, f fun-act2<mut-ptr<arrow<str, str>>, mut-ptr<arrow<str, str>>, arrow<str, str>>) */
struct arrow_1* fold_25(struct ctx* ctx, struct arrow_1* acc, struct arr_13 a, struct fun_act2_17 f) {
	struct arrow_1* _0 = end_ptr_9(a);
	return fold_recur_13(ctx, acc, a.begin_ptr, _0, f);
}
/* fold-recur<a, b> mut-ptr<arrow<str, str>>(acc mut-ptr<arrow<str, str>>, cur const-ptr<arrow<str, str>>, end const-ptr<arrow<str, str>>, f fun-act2<mut-ptr<arrow<str, str>>, mut-ptr<arrow<str, str>>, arrow<str, str>>) */
struct arrow_1* fold_recur_13(struct ctx* ctx, struct arrow_1* acc, struct arrow_1* cur, struct arrow_1* end, struct fun_act2_17 f) {
	top:;
	uint8_t _0 = _equal_11(cur, end);
	if (_0) {
		return acc;
	} else {
		struct arrow_1 _1 = _times_17(cur);
		struct arrow_1* _2 = subscript_102(ctx, f, acc, _1);
		struct arrow_1* _3 = _plus_14(cur, 1u);
		acc = _2;
		cur = _3;
		end = end;
		f = f;
		goto top;
	}
}
/* subscript<a, a, b> mut-ptr<arrow<str, str>>(a fun-act2<mut-ptr<arrow<str, str>>, mut-ptr<arrow<str, str>>, arrow<str, str>>, p0 mut-ptr<arrow<str, str>>, p1 arrow<str, str>) */
struct arrow_1* subscript_102(struct ctx* ctx, struct fun_act2_17 a, struct arrow_1* p0, struct arrow_1 p1) {
	return call_w_ctx_1033(a, ctx, p0, p1);
}
/* call-w-ctx<raw-ptr-mut(arrow<str, str>), raw-ptr-mut(arrow<str, str>), arrow<str, str>> (generated) (generated) */
struct arrow_1* call_w_ctx_1033(struct fun_act2_17 a, struct ctx* ctx, struct arrow_1* p0, struct arrow_1 p1) {
	struct fun_act2_17 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct fold_21__lambda0__lambda0* closure0 = _0.as0;
			
			return fold_21__lambda0__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return NULL;;
	}
}
/* fold<mut-ptr<out>, k, v>.lambda0.lambda0 mut-ptr<arrow<str, str>>(cur2 mut-ptr<arrow<str, str>>, pair arrow<str, str>) */
struct arrow_1* fold_21__lambda0__lambda0(struct ctx* ctx, struct fold_21__lambda0__lambda0* _closure, struct arrow_1* cur2, struct arrow_1 pair) {
	return subscript_101(ctx, _closure->f, cur2, pair.from, pair.to);
}
/* fold<mut-ptr<out>, k, v>.lambda0 mut-ptr<arrow<str, str>>(cur mut-ptr<arrow<str, str>>, entry entry<str, str>) */
struct arrow_1* fold_21__lambda0(struct ctx* ctx, struct fold_21__lambda0* _closure, struct arrow_1* cur, struct entry_1 entry) {
	struct entry_1 _0 = entry;
	switch (_0.kind) {
		case 0: {
			return cur;
		}
		case 1: {
			struct arrow_1 ar0 = _0.as1;
			
			return subscript_101(ctx, _closure->f, cur, ar0.from, ar0.to);
		}
		case 2: {
			struct mut_arr_4* m1 = _0.as2;
			
			struct fold_21__lambda0__lambda0* temp0;
			uint8_t* _1 = alloc(ctx, sizeof(struct fold_21__lambda0__lambda0));
			temp0 = ((struct fold_21__lambda0__lambda0*) _1);
			
			*temp0 = (struct fold_21__lambda0__lambda0) {_closure->f};
			return fold_24(ctx, cur, m1, (struct fun_act2_17) {0, .as0 = temp0});
		}
		default:
			
	return NULL;;
	}
}
/* subscript<out, k, v> arrow<str, str>(a fun-act2<arrow<str, str>, str, str>, p0 str, p1 str) */
struct arrow_1 subscript_103(struct ctx* ctx, struct fun_act2_15 a, struct str p0, struct str p1) {
	return call_w_ctx_1037(a, ctx, p0, p1);
}
/* call-w-ctx<arrow<str, str>, str, str> (generated) (generated) */
struct arrow_1 call_w_ctx_1037(struct fun_act2_15 a, struct ctx* ctx, struct str p0, struct str p1) {
	struct fun_act2_15 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return move_to_dict__e_1__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return (struct arrow_1) {(struct str) {(struct arr_0) {0, NULL}}, (struct str) {(struct arr_0) {0, NULL}}};;
	}
}
/* map-to-arr<arrow<k, v>, k, v>.lambda0 mut-ptr<arrow<str, str>>(cur mut-ptr<arrow<str, str>>, key str, value str) */
struct arrow_1* map_to_arr_1__lambda0(struct ctx* ctx, struct map_to_arr_1__lambda0* _closure, struct arrow_1* cur, struct str key, struct str value) {
	struct arrow_1 _0 = subscript_103(ctx, _closure->f, key, value);
	*cur = _0;
	return (cur + 1u);
}
/* end-ptr<out> mut-ptr<arrow<str, str>>(a fix-arr<arrow<str, str>>) */
struct arrow_1* end_ptr_11(struct fix_arr_7 a) {
	struct arrow_1* _0 = begin_ptr_12(a);
	uint64_t _1 = size_8(a);
	return (_0 + _1);
}
/* move-to-dict!<str, str>.lambda0 arrow<str, str>(k str, v str) */
struct arrow_1 move_to_dict__e_1__lambda0(struct ctx* ctx, struct void_ _closure, struct str k, struct str v) {
	return _arrow_1(k, v);
}
/* empty!<k, v> void(a mut-dict<str, str>) */
struct void_ empty__e_1(struct ctx* ctx, struct mut_dict_1* a) {
	fill__e_1(ctx, a->entries, (struct entry_1) {0, .as0 = (struct none) {}});
	return (a->total_size = 0u, (struct void_) {});
}
/* fill!<entry<k, v>> void(a fix-arr<entry<str, str>>, value entry<str, str>) */
struct void_ fill__e_1(struct ctx* ctx, struct fix_arr_8 a, struct entry_1 value) {
	struct fill__e_1__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct fill__e_1__lambda0));
	temp0 = ((struct fill__e_1__lambda0*) _0);
	
	*temp0 = (struct fill__e_1__lambda0) {value};
	return map__e_1(ctx, a, (struct fun_act1_25) {0, .as0 = temp0});
}
/* map!<a> void(a fix-arr<entry<str, str>>, f fun-act1<entry<str, str>, entry<str, str>>) */
struct void_ map__e_1(struct ctx* ctx, struct fix_arr_8 a, struct fun_act1_25 f) {
	struct entry_1* _0 = begin_ptr_10(a);
	struct entry_1* _1 = end_ptr_12(a);
	return map_recur__e_1(ctx, _0, _1, f);
}
/* map-recur!<a> void(cur mut-ptr<entry<str, str>>, end mut-ptr<entry<str, str>>, f fun-act1<entry<str, str>, entry<str, str>>) */
struct void_ map_recur__e_1(struct ctx* ctx, struct entry_1* cur, struct entry_1* end, struct fun_act1_25 f) {
	top:;
	uint8_t _0 = _notEqual_12(cur, end);
	if (_0) {
		struct entry_1 _1 = subscript_104(ctx, f, (*cur));
		*cur = _1;
		cur = (cur + 1u);
		end = end;
		f = f;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* !=<mut-ptr<a>> bool(a mut-ptr<entry<str, str>>, b mut-ptr<entry<str, str>>) */
uint8_t _notEqual_12(struct entry_1* a, struct entry_1* b) {
	return _not((a == b));
}
/* subscript<a, a> entry<str, str>(a fun-act1<entry<str, str>, entry<str, str>>, p0 entry<str, str>) */
struct entry_1 subscript_104(struct ctx* ctx, struct fun_act1_25 a, struct entry_1 p0) {
	return call_w_ctx_1047(a, ctx, p0);
}
/* call-w-ctx<entry<str, str>, entry<str, str>> (generated) (generated) */
struct entry_1 call_w_ctx_1047(struct fun_act1_25 a, struct ctx* ctx, struct entry_1 p0) {
	struct fun_act1_25 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct fill__e_1__lambda0* closure0 = _0.as0;
			
			return fill__e_1__lambda0(ctx, closure0, p0);
		}
		default:
			
	return (struct entry_1) {0};;
	}
}
/* end-ptr<a> mut-ptr<entry<str, str>>(a fix-arr<entry<str, str>>) */
struct entry_1* end_ptr_12(struct fix_arr_8 a) {
	struct entry_1* _0 = begin_ptr_10(a);
	uint64_t _1 = size_7(a);
	return (_0 + _1);
}
/* fill!<entry<k, v>>.lambda0 entry<str, str>(ignore entry<str, str>) */
struct entry_1 fill__e_1__lambda0(struct ctx* ctx, struct fill__e_1__lambda0* _closure, struct entry_1 ignore) {
	return _closure->value;
}
/* first-failures result<str, arr<failure>>(a result<str, arr<failure>>, b fun0<result<str, arr<failure>>>) */
struct result_2 first_failures(struct ctx* ctx, struct result_2 a, struct fun0 b) {
	struct result_2 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct ok_2 ok_a0 = _0.as0;
			
			struct result_2 _1 = subscript_105(ctx, b);
			switch (_1.kind) {
				case 0: {
					struct ok_2 ok_b1 = _1.as0;
					
					struct interp _2 = interp(ctx);
					struct interp _3 = with_value_0(ctx, _2, ok_a0.value);
					struct interp _4 = with_str(ctx, _3, (struct str) {{1, constantarr_0_1}});
					struct interp _5 = with_value_0(ctx, _4, ok_b1.value);
					struct str _6 = finish(ctx, _5);
					return (struct result_2) {0, .as0 = (struct ok_2) {_6}};
				}
				case 1: {
					struct err_1 e2 = _1.as1;
					
					return (struct result_2) {1, .as1 = e2};
				}
				default:
					
			return (struct result_2) {0};;
			}
		}
		case 1: {
			struct err_1 e3 = _0.as1;
			
			return (struct result_2) {1, .as1 = e3};
		}
		default:
			
	return (struct result_2) {0};;
	}
}
/* subscript<result<str, arr<failure>>> result<str, arr<failure>>(a fun0<result<str, arr<failure>>>) */
struct result_2 subscript_105(struct ctx* ctx, struct fun0 a) {
	return call_w_ctx_1052(a, ctx);
}
/* call-w-ctx<result<str, arr<failure>>> (generated) (generated) */
struct result_2 call_w_ctx_1052(struct fun0 a, struct ctx* ctx) {
	struct fun0 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct do_test__lambda0__lambda0* closure0 = _0.as0;
			
			return do_test__lambda0__lambda0(ctx, closure0);
		}
		case 1: {
			struct do_test__lambda0* closure1 = _0.as1;
			
			return do_test__lambda0(ctx, closure1);
		}
		case 2: {
			struct do_test__lambda1* closure2 = _0.as2;
			
			return do_test__lambda1(ctx, closure2);
		}
		default:
			
	return (struct result_2) {0};;
	}
}
/* run-crow-tests result<str, arr<failure>>(path str, path-to-crow str, env dict<str, str>, options test-options) */
struct result_2 run_crow_tests(struct ctx* ctx, struct str path, struct str path_to_crow, struct dict_1 env, struct test_options* options) {
	struct arr_2 tests0;
	tests0 = list_tests(ctx, path, options->match_test);
	
	struct arr_15 failures1;
	struct run_crow_tests__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct run_crow_tests__lambda0));
	temp0 = ((struct run_crow_tests__lambda0*) _0);
	
	*temp0 = (struct run_crow_tests__lambda0) {path_to_crow, env, options};
	failures1 = flat_map_with_max_size(ctx, tests0, options->max_failures, (struct fun_act1_27) {0, .as0 = temp0});
	
	uint8_t _1 = is_empty_21(failures1);
	if (_1) {
		struct interp _2 = interp(ctx);
		struct interp _3 = with_str(ctx, _2, (struct str) {{4, constantarr_0_81}});
		struct interp _4 = with_value_4(ctx, _3, tests0.size);
		struct interp _5 = with_str(ctx, _4, (struct str) {{10, constantarr_0_82}});
		struct interp _6 = with_value_0(ctx, _5, path);
		struct str _7 = finish(ctx, _6);
		return (struct result_2) {0, .as0 = (struct ok_2) {_7}};
	} else {
		return (struct result_2) {1, .as1 = (struct err_1) {failures1}};
	}
}
/* list-tests arr<str>(path str, match-test str) */
struct arr_2 list_tests(struct ctx* ctx, struct str path, struct str match_test) {
	struct mut_arr_5* res0;
	res0 = mut_arr_5(ctx);
	
	struct list_tests__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct list_tests__lambda0));
	temp0 = ((struct list_tests__lambda0*) _0);
	
	*temp0 = (struct list_tests__lambda0) {match_test, res0};
	each_child_recursive_0(ctx, path, (struct fun_act1_26) {1, .as1 = temp0});
	return move_to_arr__e_2(res0);
}
/* mut-arr<str> mut-arr<str>() */
struct mut_arr_5* mut_arr_5(struct ctx* ctx) {
	struct mut_arr_5* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_arr_5));
	temp0 = ((struct mut_arr_5*) _0);
	
	struct fix_arr_10 _1 = fix_arr_18();
	*temp0 = (struct mut_arr_5) {_1, 0u};
	return temp0;
}
/* fix-arr<a> fix-arr<str>() */
struct fix_arr_10 fix_arr_18(void) {
	return (struct fix_arr_10) {(struct void_) {}, (struct arr_2) {0u, NULL}};
}
/* each-child-recursive void(path str, f fun-act1<void, str>) */
struct void_ each_child_recursive_0(struct ctx* ctx, struct str path, struct fun_act1_26 f) {
	struct fun_act1_8 filter0;
	filter0 = (struct fun_act1_8) {3, .as3 = (struct void_) {}};
	
	return each_child_recursive_1(ctx, path, filter0, f);
}
/* each-child-recursive.lambda0 bool(ignore str) */
uint8_t each_child_recursive_0__lambda0(struct ctx* ctx, struct void_ _closure, struct str ignore) {
	return 1;
}
/* each-child-recursive void(path str, filter fun-act1<bool, str>, f fun-act1<void, str>) */
struct void_ each_child_recursive_1(struct ctx* ctx, struct str path, struct fun_act1_8 filter, struct fun_act1_26 f) {
	uint8_t _0 = is_dir_0(ctx, path);
	if (_0) {
		struct arr_2 _1 = read_dir_0(ctx, path);
		struct each_child_recursive_1__lambda0* temp0;
		uint8_t* _2 = alloc(ctx, sizeof(struct each_child_recursive_1__lambda0));
		temp0 = ((struct each_child_recursive_1__lambda0*) _2);
		
		*temp0 = (struct each_child_recursive_1__lambda0) {filter, path, f};
		return each_7(ctx, _1, (struct fun_act1_26) {0, .as0 = temp0});
	} else {
		return subscript_106(ctx, f, path);
	}
}
/* is-dir bool(path str) */
uint8_t is_dir_0(struct ctx* ctx, struct str path) {
	char* _0 = to_c_str(ctx, path);
	return is_dir_1(ctx, _0);
}
/* is-dir bool(path const-ptr<char>) */
uint8_t is_dir_1(struct ctx* ctx, char* path) {
	struct opt_21 _0 = get_stat(ctx, path);
	switch (_0.kind) {
		case 0: {
			struct interp _1 = interp(ctx);
			struct interp _2 = with_str(ctx, _1, (struct str) {{21, constantarr_0_28}});
			struct interp _3 = with_value_1(ctx, _2, path);
			struct str _4 = finish(ctx, _3);
			return throw_10(ctx, _4);
		}
		case 1: {
			struct some_21 _matched0 = _0.as1;
			
			struct stat* stat1;
			stat1 = _matched0.value;
			
			uint32_t _5 = S_IFMT();
			uint32_t _6 = S_IFDIR();
			return ((stat1->st_mode & _5) == _6);
		}
		default:
			
	return 0;;
	}
}
/* get-stat opt<stat>(path const-ptr<char>) */
struct opt_21 get_stat(struct ctx* ctx, char* path) {
	struct stat* s0;
	s0 = stat_0(ctx);
	
	int32_t err1;
	err1 = stat(path, s0);
	
	uint8_t _0 = (err1 == 0);
	if (_0) {
		return (struct opt_21) {1, .as1 = (struct some_21) {s0}};
	} else {
		assert_0(ctx, (err1 == -1));
		int32_t _1 = errno();
		int32_t _2 = ENOENT();
		uint8_t _3 = _notEqual_6(_1, _2);
		if (_3) {
			return todo_4();
		} else {
			return (struct opt_21) {0, .as0 = (struct none) {}};
		}
	}
}
/* stat stat() */
struct stat* stat_0(struct ctx* ctx) {
	struct stat* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct stat));
	temp0 = ((struct stat*) _0);
	
	*temp0 = (struct stat) {0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u};
	return temp0;
}
/* errno int32() */
int32_t errno(void) {
	int32_t* _0 = __errno_location();
	return (*_0);
}
/* ENOENT int32() */
int32_t ENOENT(void) {
	return 2;
}
/* todo<opt<stat>> opt<stat>() */
struct opt_21 todo_4(void) {
	(abort(), (struct void_) {});
	return (struct opt_21) {0};
}
/* throw<bool> bool(message str) */
uint8_t throw_10(struct ctx* ctx, struct str message) {
	struct backtrace _0 = get_backtrace(ctx);
	return throw_11(ctx, (struct exception) {message, _0});
}
/* throw<a> bool(e exception) */
uint8_t throw_11(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx0;
	exn_ctx0 = get_exception_ctx(ctx);
	
	uint8_t _0 = _notEqual_3(exn_ctx0->jmp_buf_ptr, NULL);
	hard_assert(_0);
	exn_ctx0->thrown_exception = e;
	int32_t _1 = number_to_throw(ctx);
	(longjmp(exn_ctx0->jmp_buf_ptr, _1), (struct void_) {});
	return hard_unreachable_6();
}
/* hard-unreachable<a> bool() */
uint8_t hard_unreachable_6(void) {
	(abort(), (struct void_) {});
	return 0;
}
/* with-value<const-ptr<char>> interp(a interp, b const-ptr<char>) */
struct interp with_value_1(struct ctx* ctx, struct interp a, char* b) {
	struct str _0 = to_str_1(b);
	return with_str(ctx, a, _0);
}
/* S_IFMT nat32() */
uint32_t S_IFMT(void) {
	return 61440u;
}
/* S_IFDIR nat32() */
uint32_t S_IFDIR(void) {
	return 16384u;
}
/* to-c-str const-ptr<char>(a str) */
char* to_c_str(struct ctx* ctx, struct str a) {
	struct str _0 = _tilde_0(ctx, a, (struct str) {{1, constantarr_0_29}});
	return _0.chars.begin_ptr;
}
/* each<str> void(a arr<str>, f fun-act1<void, str>) */
struct void_ each_7(struct ctx* ctx, struct arr_2 a, struct fun_act1_26 f) {
	struct str* _0 = end_ptr_7(a);
	return each_recur_4(ctx, a.begin_ptr, _0, f);
}
/* each-recur<a> void(cur const-ptr<str>, end const-ptr<str>, f fun-act1<void, str>) */
struct void_ each_recur_4(struct ctx* ctx, struct str* cur, struct str* end, struct fun_act1_26 f) {
	top:;
	uint8_t _0 = _notEqual_13(cur, end);
	if (_0) {
		struct str _1 = _times_10(cur);
		subscript_106(ctx, f, _1);
		struct str* _2 = _plus_8(cur, 1u);
		cur = _2;
		end = end;
		f = f;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* !=<const-ptr<a>> bool(a const-ptr<str>, b const-ptr<str>) */
uint8_t _notEqual_13(struct str* a, struct str* b) {
	uint8_t _0 = _equal_9(a, b);
	return _not(_0);
}
/* subscript<void, a> void(a fun-act1<void, str>, p0 str) */
struct void_ subscript_106(struct ctx* ctx, struct fun_act1_26 a, struct str p0) {
	return call_w_ctx_1080(a, ctx, p0);
}
/* call-w-ctx<void, str> (generated) (generated) */
struct void_ call_w_ctx_1080(struct fun_act1_26 a, struct ctx* ctx, struct str p0) {
	struct fun_act1_26 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct each_child_recursive_1__lambda0* closure0 = _0.as0;
			
			return each_child_recursive_1__lambda0(ctx, closure0, p0);
		}
		case 1: {
			struct list_tests__lambda0* closure1 = _0.as1;
			
			return list_tests__lambda0(ctx, closure1, p0);
		}
		case 2: {
			struct flat_map_with_max_size__lambda0* closure2 = _0.as2;
			
			return flat_map_with_max_size__lambda0(ctx, closure2, p0);
		}
		case 3: {
			struct list_lintable_files__lambda1* closure3 = _0.as3;
			
			return list_lintable_files__lambda1(ctx, closure3, p0);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* read-dir arr<str>(path str) */
struct arr_2 read_dir_0(struct ctx* ctx, struct str path) {
	char* _0 = to_c_str(ctx, path);
	return read_dir_1(ctx, _0);
}
/* read-dir arr<str>(path const-ptr<char>) */
struct arr_2 read_dir_1(struct ctx* ctx, char* path) {
	struct dir* dirp0;
	dirp0 = opendir(path);
	
	uint8_t _0 = _notEqual_14(((uint8_t**) dirp0), NULL);
	assert_0(ctx, _0);
	struct mut_arr_5* res1;
	res1 = mut_arr_5(ctx);
	
	read_dir_recur(ctx, dirp0, res1);
	struct arr_2 _1 = move_to_arr__e_2(res1);
	return sort_0(ctx, _1);
}
/* !=<mut-ptr<const-ptr<nat8>>> bool(a mut-ptr<const-ptr<nat8>>, b mut-ptr<const-ptr<nat8>>) */
uint8_t _notEqual_14(uint8_t** a, uint8_t** b) {
	return _not((a == b));
}
/* read-dir-recur void(dirp dir, res mut-arr<str>) */
struct void_ read_dir_recur(struct ctx* ctx, struct dir* dirp, struct mut_arr_5* res) {
	top:;
	struct dirent* entry0;
	struct dirent* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct dirent));
	temp0 = ((struct dirent*) _0);
	
	struct bytes256 _1 = zero_4();
	*temp0 = (struct dirent) {0u, 0, 0u, 0u, _1};
	entry0 = temp0;
	
	struct cell_4* result1;
	struct cell_4* temp1;
	uint8_t* _2 = alloc(ctx, sizeof(struct cell_4));
	temp1 = ((struct cell_4*) _2);
	
	*temp1 = (struct cell_4) {entry0};
	result1 = temp1;
	
	int32_t err2;
	err2 = readdir_r(dirp, entry0, result1);
	
	assert_0(ctx, (err2 == 0));
	struct dirent* _3 = _times_19(result1);
	uint8_t* _4 = as_any_const_ptr_6(_3);
	uint8_t* _5 = null_0();
	uint8_t _6 = _notEqual_15(_4, _5);
	if (_6) {
		struct dirent* _7 = _times_19(result1);
		uint8_t _8 = ref_eq(_7, entry0);
		assert_0(ctx, _8);
		struct str name3;
		name3 = get_dirent_name(ctx, entry0);
		
		uint8_t _9 = _notEqual_8(name3, (struct str) {{1, constantarr_0_30}});uint8_t _10;
		
		if (_9) {
			_10 = _notEqual_8(name3, (struct str) {{2, constantarr_0_31}});
		} else {
			_10 = 0;
		}
		if (_10) {
			struct str _11 = get_dirent_name(ctx, entry0);
			_concatEquals_8(ctx, res, _11);
		} else {
			(struct void_) {};
		}
		dirp = dirp;
		res = res;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* zero bytes256() */
struct bytes256 zero_4(void) {
	struct bytes128 _0 = zero_3();
	struct bytes128 _1 = zero_3();
	return (struct bytes256) {_0, _1};
}
/* !=<const-ptr<nat8>> bool(a const-ptr<nat8>, b const-ptr<nat8>) */
uint8_t _notEqual_15(uint8_t* a, uint8_t* b) {
	uint8_t _0 = _equal_1(a, b);
	return _not(_0);
}
/* as-any-const-ptr<dirent> const-ptr<nat8>(ref dirent) */
uint8_t* as_any_const_ptr_6(struct dirent* ref) {
	return ((uint8_t*) ((uint8_t*) ref));
}
/* *<dirent> dirent(a cell<dirent>) */
struct dirent* _times_19(struct cell_4* a) {
	return a->inner_value;
}
/* ref-eq<dirent> bool(a dirent, b dirent) */
uint8_t ref_eq(struct dirent* a, struct dirent* b) {
	uint8_t* _0 = as_any_const_ptr_6(a);
	uint8_t* _1 = as_any_const_ptr_6(b);
	return _equal_1(_0, _1);
}
/* get-dirent-name str(d dirent) */
struct str get_dirent_name(struct ctx* ctx, struct dirent* d) {
	uint64_t name_offset0;
	uint64_t _0 = _plus_3(ctx, sizeof(uint64_t), sizeof(int64_t));
	uint64_t _1 = _plus_3(ctx, _0, sizeof(uint16_t));
	name_offset0 = _plus_3(ctx, _1, sizeof(char));
	
	uint8_t* name_ptr1;
	uint8_t* _2 = as_any_const_ptr_6(d);
	name_ptr1 = _plus_16(_2, name_offset0);
	
	char* _3 = ptr_cast_1(name_ptr1);
	return to_str_1(_3);
}
/* +<nat8> const-ptr<nat8>(a const-ptr<nat8>, offset nat64) */
uint8_t* _plus_16(uint8_t* a, uint64_t offset) {
	return ((uint8_t*) (((uint8_t*) a) + offset));
}
/* ptr-cast<char, nat8> const-ptr<char>(a const-ptr<nat8>) */
char* ptr_cast_1(uint8_t* a) {
	return ((char*) ((char*) ((uint8_t*) a)));
}
/* ~=<str> void(a mut-arr<str>, value str) */
struct void_ _concatEquals_8(struct ctx* ctx, struct mut_arr_5* a, struct str value) {
	incr_capacity__e_3(ctx, a);
	uint64_t _0 = capacity_4(a);
	uint8_t _1 = _less_0(a->size, _0);
	assert_0(ctx, _1);
	struct str* _2 = begin_ptr_14(a);
	set_subscript_2(_2, a->size, value);
	uint64_t _3 = _plus_3(ctx, a->size, 1u);
	return (a->size = _3, (struct void_) {});
}
/* incr-capacity!<a> void(a mut-arr<str>) */
struct void_ incr_capacity__e_3(struct ctx* ctx, struct mut_arr_5* a) {
	uint64_t _0 = _plus_3(ctx, a->size, 1u);
	uint64_t _1 = round_up_to_power_of_two(ctx, _0);
	return ensure_capacity_3(ctx, a, _1);
}
/* ensure-capacity<a> void(a mut-arr<str>, min-capacity nat64) */
struct void_ ensure_capacity_3(struct ctx* ctx, struct mut_arr_5* a, uint64_t min_capacity) {
	uint64_t _0 = capacity_4(a);
	uint8_t _1 = _less_0(_0, min_capacity);
	if (_1) {
		return increase_capacity_to__e_3(ctx, a, min_capacity);
	} else {
		return (struct void_) {};
	}
}
/* capacity<a> nat64(a mut-arr<str>) */
uint64_t capacity_4(struct mut_arr_5* a) {
	return size_11(a->backing);
}
/* size<a> nat64(a fix-arr<str>) */
uint64_t size_11(struct fix_arr_10 a) {
	return a.inner.size;
}
/* increase-capacity-to!<a> void(a mut-arr<str>, new-capacity nat64) */
struct void_ increase_capacity_to__e_3(struct ctx* ctx, struct mut_arr_5* a, uint64_t new_capacity) {
	uint64_t _0 = capacity_4(a);
	uint8_t _1 = _greater(new_capacity, _0);
	assert_0(ctx, _1);
	struct str* old_begin0;
	old_begin0 = begin_ptr_14(a);
	
	struct fix_arr_10 _2 = uninitialized_fix_arr_8(ctx, new_capacity);
	a->backing = _2;
	struct str* _3 = begin_ptr_14(a);
	copy_data_from__e_6(ctx, _3, ((struct str*) old_begin0), a->size);
	uint64_t _4 = _plus_3(ctx, a->size, 1u);
	uint64_t _5 = size_11(a->backing);
	struct range _6 = _range(ctx, _4, _5);
	struct fix_arr_10 _7 = subscript_107(ctx, a->backing, _6);
	return set_zero_elements_3(_7);
}
/* begin-ptr<a> mut-ptr<str>(a mut-arr<str>) */
struct str* begin_ptr_14(struct mut_arr_5* a) {
	return begin_ptr_15(a->backing);
}
/* begin-ptr<a> mut-ptr<str>(a fix-arr<str>) */
struct str* begin_ptr_15(struct fix_arr_10 a) {
	return ((struct str*) a.inner.begin_ptr);
}
/* uninitialized-fix-arr<a> fix-arr<str>(size nat64) */
struct fix_arr_10 uninitialized_fix_arr_8(struct ctx* ctx, uint64_t size) {
	struct str* _0 = alloc_uninitialized_1(ctx, size);
	return fix_arr_19(size, _0);
}
/* fix-arr<a> fix-arr<str>(size nat64, begin-ptr mut-ptr<str>) */
struct fix_arr_10 fix_arr_19(uint64_t size, struct str* begin_ptr) {
	return (struct fix_arr_10) {(struct void_) {}, (struct arr_2) {size, ((struct str*) begin_ptr)}};
}
/* copy-data-from!<a> void(to mut-ptr<str>, from const-ptr<str>, len nat64) */
struct void_ copy_data_from__e_6(struct ctx* ctx, struct str* to, struct str* from, uint64_t len) {
	uint8_t* _0 = as_any_const_ptr_7(from);
	uint8_t* _1 = memcpy(((uint8_t*) to), _0, (len * sizeof(struct str)));
	return drop_0(_1);
}
/* as-any-const-ptr<const-ptr<a>> const-ptr<nat8>(ref const-ptr<str>) */
uint8_t* as_any_const_ptr_7(struct str* ref) {
	return ((uint8_t*) ((uint8_t*) ref));
}
/* set-zero-elements<a> void(a fix-arr<str>) */
struct void_ set_zero_elements_3(struct fix_arr_10 a) {
	struct str* _0 = begin_ptr_15(a);
	uint64_t _1 = size_11(a);
	return set_zero_range_4(_0, _1);
}
/* set-zero-range<a> void(begin mut-ptr<str>, size nat64) */
struct void_ set_zero_range_4(struct str* begin, uint64_t size) {
	uint8_t* _0 = memset(((uint8_t*) begin), 0, (size * sizeof(struct str)));
	return drop_0(_0);
}
/* subscript<a> fix-arr<str>(a fix-arr<str>, range range<nat64>) */
struct fix_arr_10 subscript_107(struct ctx* ctx, struct fix_arr_10 a, struct range range) {
	struct arr_2 _0 = subscript_45(ctx, a.inner, range);
	return (struct fix_arr_10) {(struct void_) {}, _0};
}
/* sort<str> arr<str>(a arr<str>) */
struct arr_2 sort_0(struct ctx* ctx, struct arr_2 a) {
	return sort_1(ctx, a, (struct fun_act2_18) {0, .as0 = (struct void_) {}});
}
/* sort<a> arr<str>(a arr<str>, comparer fun-act2<comparison, str, str>) */
struct arr_2 sort_1(struct ctx* ctx, struct arr_2 a, struct fun_act2_18 comparer) {
	struct fix_arr_10 res0;
	res0 = fix_arr_20(ctx, a);
	
	sort__e_1(ctx, res0, comparer);
	return cast_immutable_6(res0);
}
/* fix-arr<a> fix-arr<str>(a arr<str>) */
struct fix_arr_10 fix_arr_20(struct ctx* ctx, struct arr_2 a) {
	struct fix_arr_20__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct fix_arr_20__lambda0));
	temp0 = ((struct fix_arr_20__lambda0*) _0);
	
	*temp0 = (struct fix_arr_20__lambda0) {a};
	return make_fix_arr_5(ctx, a.size, (struct fun_act1_7) {1, .as1 = temp0});
}
/* make-fix-arr<a> fix-arr<str>(size nat64, f fun-act1<str, nat64>) */
struct fix_arr_10 make_fix_arr_5(struct ctx* ctx, uint64_t size, struct fun_act1_7 f) {
	struct fix_arr_10 res0;
	res0 = uninitialized_fix_arr_8(ctx, size);
	
	struct str* _0 = begin_ptr_15(res0);
	fill_ptr_range_0(ctx, _0, size, f);
	return res0;
}
/* fix-arr<a>.lambda0 str(i nat64) */
struct str fix_arr_20__lambda0(struct ctx* ctx, struct fix_arr_20__lambda0* _closure, uint64_t i) {
	return subscript_26(ctx, _closure->a, i);
}
/* sort!<a> void(a fix-arr<str>, comparer fun-act2<comparison, str, str>) */
struct void_ sort__e_1(struct ctx* ctx, struct fix_arr_10 a, struct fun_act2_18 comparer) {
	uint8_t _0 = is_empty_17(a);
	uint8_t _1 = _not(_0);
	if (_1) {
		struct str* _2 = begin_ptr_15(a);
		struct str* _3 = begin_ptr_15(a);
		struct str* _4 = end_ptr_13(a);
		return insertion_sort_recur__e(ctx, _2, (_3 + 1u), _4, comparer);
	} else {
		return (struct void_) {};
	}
}
/* is-empty<a> bool(a fix-arr<str>) */
uint8_t is_empty_17(struct fix_arr_10 a) {
	uint64_t _0 = size_11(a);
	return (_0 == 0u);
}
/* insertion-sort-recur!<a> void(begin mut-ptr<str>, cur mut-ptr<str>, end mut-ptr<str>, comparer fun-act2<comparison, str, str>) */
struct void_ insertion_sort_recur__e(struct ctx* ctx, struct str* begin, struct str* cur, struct str* end, struct fun_act2_18 comparer) {
	top:;
	uint8_t _0 = _notEqual_16(cur, end);
	if (_0) {
		insert__e(ctx, begin, cur, (*cur), comparer);
		begin = begin;
		cur = (cur + 1u);
		end = end;
		comparer = comparer;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* !=<mut-ptr<a>> bool(a mut-ptr<str>, b mut-ptr<str>) */
uint8_t _notEqual_16(struct str* a, struct str* b) {
	return _not((a == b));
}
/* insert!<a> void(begin mut-ptr<str>, cur mut-ptr<str>, value str, comparer fun-act2<comparison, str, str>) */
struct void_ insert__e(struct ctx* ctx, struct str* begin, struct str* cur, struct str value, struct fun_act2_18 comparer) {
	top:;
	forbid(ctx, (begin == cur));
	struct str* prev0;
	prev0 = (cur - 1u);
	
	struct comparison _0 = subscript_108(ctx, comparer, value, (*prev0));
	uint8_t _1 = _equal_13(_0, (struct comparison) {0, .as0 = (struct less) {}});
	if (_1) {
		*cur = (*prev0);
		uint8_t _2 = (begin == prev0);
		if (_2) {
			return (*prev0 = value, (struct void_) {});
		} else {
			begin = begin;
			cur = prev0;
			value = value;
			comparer = comparer;
			goto top;
		}
	} else {
		return (*cur = value, (struct void_) {});
	}
}
/* == bool(a comparison, b comparison) */
uint8_t _equal_13(struct comparison a, struct comparison b) {
	struct comparison _0 = a;
	switch (_0.kind) {
		case 0: {
			struct comparison _1 = b;
			switch (_1.kind) {
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
		case 1: {
			struct comparison _2 = b;
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
					
			return 0;;
			}
		}
		case 2: {
			struct comparison _3 = b;
			switch (_3.kind) {
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
		default:
			
	return 0;;
	}
}
/* subscript<comparison, a, a> comparison(a fun-act2<comparison, str, str>, p0 str, p1 str) */
struct comparison subscript_108(struct ctx* ctx, struct fun_act2_18 a, struct str p0, struct str p1) {
	return call_w_ctx_1122(a, ctx, p0, p1);
}
/* call-w-ctx<comparison, str, str> (generated) (generated) */
struct comparison call_w_ctx_1122(struct fun_act2_18 a, struct ctx* ctx, struct str p0, struct str p1) {
	struct fun_act2_18 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return sort_0__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return (struct comparison) {0};;
	}
}
/* end-ptr<a> mut-ptr<str>(a fix-arr<str>) */
struct str* end_ptr_13(struct fix_arr_10 a) {
	struct str* _0 = begin_ptr_15(a);
	uint64_t _1 = size_11(a);
	return (_0 + _1);
}
/* cast-immutable<a> arr<str>(a fix-arr<str>) */
struct arr_2 cast_immutable_6(struct fix_arr_10 a) {
	return a.inner;
}
/* sort<str>.lambda0 comparison(x str, y str) */
struct comparison sort_0__lambda0(struct ctx* ctx, struct void_ _closure, struct str x, struct str y) {
	return _compare_8(x, y);
}
/* move-to-arr!<str> arr<str>(a mut-arr<str>) */
struct arr_2 move_to_arr__e_2(struct mut_arr_5* a) {
	struct fix_arr_10 _0 = move_to_fix_arr__e_2(a);
	return cast_immutable_6(_0);
}
/* move-to-fix-arr!<a> fix-arr<str>(a mut-arr<str>) */
struct fix_arr_10 move_to_fix_arr__e_2(struct mut_arr_5* a) {
	struct fix_arr_10 res0;
	struct str* _0 = begin_ptr_14(a);
	res0 = fix_arr_19(a->size, _0);
	
	struct fix_arr_10 _1 = fix_arr_18();
	a->backing = _1;
	a->size = 0u;
	return res0;
}
/* each-child-recursive.lambda0 void(child_name str) */
struct void_ each_child_recursive_1__lambda0(struct ctx* ctx, struct each_child_recursive_1__lambda0* _closure, struct str child_name) {
	uint8_t _0 = subscript_25(ctx, _closure->filter, child_name);
	if (_0) {
		struct str _1 = child_path(ctx, _closure->path, child_name);
		return each_child_recursive_1(ctx, _1, _closure->filter, _closure->f);
	} else {
		return (struct void_) {};
	}
}
/* has-substr bool(a str, b str) */
uint8_t has_substr(struct ctx* ctx, struct str a, struct str b) {
	return contains_subseq(ctx, a.chars, b.chars);
}
/* contains-subseq<char> bool(a arr<char>, subseq arr<char>) */
uint8_t contains_subseq(struct ctx* ctx, struct arr_0 a, struct arr_0 subseq) {
	struct opt_11 _0 = index_of_subseq(ctx, a, subseq);
	uint8_t _1 = is_empty_11(_0);
	return _not(_1);
}
/* index-of-subseq<a> opt<nat64>(a arr<char>, subseq arr<char>) */
struct opt_11 index_of_subseq(struct ctx* ctx, struct arr_0 a, struct arr_0 subseq) {
	return index_of_subseq_recur(ctx, a, subseq, 0u);
}
/* index-of-subseq-recur<a> opt<nat64>(a arr<char>, subseq arr<char>, i nat64) */
struct opt_11 index_of_subseq_recur(struct ctx* ctx, struct arr_0 a, struct arr_0 subseq, uint64_t i) {
	top:;
	uint8_t _0 = (i == a.size);
	if (_0) {
		return (struct opt_11) {0, .as0 = (struct none) {}};
	} else {
		struct range _1 = _range(ctx, i, a.size);
		struct arr_0 _2 = subscript_4(ctx, a, _1);
		uint8_t _3 = starts_with_1(ctx, _2, subseq);
		if (_3) {
			return (struct opt_11) {1, .as1 = (struct some_11) {i}};
		} else {
			uint64_t _4 = _plus_3(ctx, i, 1u);
			a = a;
			subseq = subseq;
			i = _4;
			goto top;
		}
	}
}
/* ext-is-crow bool(a str) */
uint8_t ext_is_crow(struct ctx* ctx, struct str a) {
	struct str _0 = base_name(ctx, a);
	struct opt_16 _1 = get_extension(ctx, _0);
	return _equal_14(_1, (struct opt_16) {1, .as1 = (struct some_16) {(struct str) {{4, constantarr_0_27}}}});
}
/* == bool(a opt<str>, b opt<str>) */
uint8_t _equal_14(struct opt_16 a, struct opt_16 b) {
	return opt_equal(a, b);
}
/* opt-equal<str> bool(a opt<str>, b opt<str>) */
uint8_t opt_equal(struct opt_16 a, struct opt_16 b) {
	struct opt_16 _0 = a;
	switch (_0.kind) {
		case 0: {
			return is_empty_18(b);
		}
		case 1: {
			struct some_16 _matched0 = _0.as1;
			
			struct str va1;
			va1 = _matched0.value;
			
			struct opt_16 _1 = b;
			switch (_1.kind) {
				case 0: {
					return 0;
				}
				case 1: {
					struct some_16 _matched2 = _1.as1;
					
					struct str vb3;
					vb3 = _matched2.value;
					
					return _equal_5(va1, vb3);
				}
				default:
					
			return 0;;
			}
		}
		default:
			
	return 0;;
	}
}
/* is-empty<a> bool(a opt<str>) */
uint8_t is_empty_18(struct opt_16 a) {
	struct opt_16 _0 = a;
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
/* get-extension opt<str>(name str) */
struct opt_16 get_extension(struct ctx* ctx, struct str name) {
	struct opt_11 _0 = last_index_of(ctx, name, 46u);
	switch (_0.kind) {
		case 0: {
			return (struct opt_16) {0, .as0 = (struct none) {}};
		}
		case 1: {
			struct some_11 _matched0 = _0.as1;
			
			uint64_t index1;
			index1 = _matched0.value;
			
			uint64_t _1 = _plus_3(ctx, index1, 1u);
			uint64_t _2 = size_bytes(name);
			struct range _3 = _range(ctx, _1, _2);
			struct arr_0 _4 = subscript_4(ctx, name.chars, _3);
			return (struct opt_16) {1, .as1 = (struct some_16) {(struct str) {_4}}};
		}
		default:
			
	return (struct opt_16) {0};;
	}
}
/* last-index-of opt<nat64>(a str, c char) */
struct opt_11 last_index_of(struct ctx* ctx, struct str a, char c) {
	top:;
	struct opt_22 _0 = last(ctx, a.chars);
	switch (_0.kind) {
		case 0: {
			return (struct opt_11) {0, .as0 = (struct none) {}};
		}
		case 1: {
			struct some_22 _matched0 = _0.as1;
			
			char last_char1;
			last_char1 = _matched0.value;
			
			uint8_t _1 = _equal_3(last_char1, c);
			if (_1) {
				uint64_t _2 = size_bytes(a);
				uint64_t _3 = _minus_5(ctx, _2, 1u);
				return (struct opt_11) {1, .as1 = (struct some_11) {_3}};
			} else {
				struct arr_0 _4 = rtail_2(ctx, a.chars);
				a = (struct str) {_4};
				c = c;
				goto top;
			}
		}
		default:
			
	return (struct opt_11) {0};;
	}
}
/* last<char> opt<char>(a arr<char>) */
struct opt_22 last(struct ctx* ctx, struct arr_0 a) {
	uint8_t _0 = is_empty_1(a);
	uint8_t _1 = _not(_0);
	if (_1) {
		uint64_t _2 = _minus_5(ctx, a.size, 1u);
		char _3 = subscript_70(ctx, a, _2);
		return (struct opt_22) {1, .as1 = (struct some_22) {_3}};
	} else {
		return (struct opt_22) {0, .as0 = (struct none) {}};
	}
}
/* rtail<char> arr<char>(a arr<char>) */
struct arr_0 rtail_2(struct ctx* ctx, struct arr_0 a) {
	uint8_t _0 = is_empty_1(a);
	forbid(ctx, _0);
	uint64_t _1 = _minus_5(ctx, a.size, 1u);
	struct range _2 = _range(ctx, 0u, _1);
	return subscript_4(ctx, a, _2);
}
/* base-name str(path str) */
struct str base_name(struct ctx* ctx, struct str path) {
	struct opt_11 _0 = last_index_of(ctx, path, 47u);
	switch (_0.kind) {
		case 0: {
			return path;
		}
		case 1: {
			struct some_11 _matched0 = _0.as1;
			
			uint64_t index1;
			index1 = _matched0.value;
			
			uint64_t _1 = _plus_3(ctx, index1, 1u);
			uint64_t _2 = size_bytes(path);
			struct range _3 = _range(ctx, _1, _2);
			struct arr_0 _4 = subscript_4(ctx, path.chars, _3);
			return (struct str) {_4};
		}
		default:
			
	return (struct str) {(struct arr_0) {0, NULL}};;
	}
}
/* list-tests.lambda0 void(child str) */
struct void_ list_tests__lambda0(struct ctx* ctx, struct list_tests__lambda0* _closure, struct str child) {
	uint8_t _0 = has_substr(ctx, child, _closure->match_test);uint8_t _1;
	
	if (_0) {
		_1 = ext_is_crow(ctx, child);
	} else {
		_1 = 0;
	}
	if (_1) {
		return _concatEquals_8(ctx, _closure->res, child);
	} else {
		return (struct void_) {};
	}
}
/* flat-map-with-max-size<failure, str> arr<failure>(a arr<str>, max-size nat64, mapper fun-act1<arr<failure>, str>) */
struct arr_15 flat_map_with_max_size(struct ctx* ctx, struct arr_2 a, uint64_t max_size, struct fun_act1_27 mapper) {
	struct mut_arr_6* res0;
	res0 = mut_arr_6(ctx);
	
	struct flat_map_with_max_size__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct flat_map_with_max_size__lambda0));
	temp0 = ((struct flat_map_with_max_size__lambda0*) _0);
	
	*temp0 = (struct flat_map_with_max_size__lambda0) {res0, max_size, mapper};
	each_7(ctx, a, (struct fun_act1_26) {2, .as2 = temp0});
	return move_to_arr__e_3(res0);
}
/* mut-arr<out> mut-arr<failure>() */
struct mut_arr_6* mut_arr_6(struct ctx* ctx) {
	struct mut_arr_6* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_arr_6));
	temp0 = ((struct mut_arr_6*) _0);
	
	struct fix_arr_11 _1 = fix_arr_21();
	*temp0 = (struct mut_arr_6) {_1, 0u};
	return temp0;
}
/* fix-arr<a> fix-arr<failure>() */
struct fix_arr_11 fix_arr_21(void) {
	return (struct fix_arr_11) {(struct void_) {}, (struct arr_15) {0u, NULL}};
}
/* ~=<out> void(a mut-arr<failure>, values arr<failure>) */
struct void_ _concatEquals_9(struct ctx* ctx, struct mut_arr_6* a, struct arr_15 values) {
	struct _concatEquals_9__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct _concatEquals_9__lambda0));
	temp0 = ((struct _concatEquals_9__lambda0*) _0);
	
	*temp0 = (struct _concatEquals_9__lambda0) {a};
	return each_8(ctx, values, (struct fun_act1_28) {0, .as0 = temp0});
}
/* each<a> void(a arr<failure>, f fun-act1<void, failure>) */
struct void_ each_8(struct ctx* ctx, struct arr_15 a, struct fun_act1_28 f) {
	struct failure** _0 = end_ptr_14(a);
	return each_recur_5(ctx, a.begin_ptr, _0, f);
}
/* each-recur<a> void(cur const-ptr<failure>, end const-ptr<failure>, f fun-act1<void, failure>) */
struct void_ each_recur_5(struct ctx* ctx, struct failure** cur, struct failure** end, struct fun_act1_28 f) {
	top:;
	uint8_t _0 = _notEqual_17(cur, end);
	if (_0) {
		struct failure* _1 = _times_20(cur);
		subscript_109(ctx, f, _1);
		struct failure** _2 = _plus_17(cur, 1u);
		cur = _2;
		end = end;
		f = f;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* ==<a> bool(a const-ptr<failure>, b const-ptr<failure>) */
uint8_t _equal_15(struct failure** a, struct failure** b) {
	return (((struct failure**) a) == ((struct failure**) b));
}
/* !=<const-ptr<a>> bool(a const-ptr<failure>, b const-ptr<failure>) */
uint8_t _notEqual_17(struct failure** a, struct failure** b) {
	uint8_t _0 = _equal_15(a, b);
	return _not(_0);
}
/* subscript<void, a> void(a fun-act1<void, failure>, p0 failure) */
struct void_ subscript_109(struct ctx* ctx, struct fun_act1_28 a, struct failure* p0) {
	return call_w_ctx_1152(a, ctx, p0);
}
/* call-w-ctx<void, gc-ptr(failure)> (generated) (generated) */
struct void_ call_w_ctx_1152(struct fun_act1_28 a, struct ctx* ctx, struct failure* p0) {
	struct fun_act1_28 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct _concatEquals_9__lambda0* closure0 = _0.as0;
			
			return _concatEquals_9__lambda0(ctx, closure0, p0);
		}
		case 1: {
			struct void_ closure1 = _0.as1;
			
			return print_failures__lambda0(ctx, closure1, p0);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* *<a> failure(a const-ptr<failure>) */
struct failure* _times_20(struct failure** a) {
	return (*((struct failure**) a));
}
/* +<a> const-ptr<failure>(a const-ptr<failure>, offset nat64) */
struct failure** _plus_17(struct failure** a, uint64_t offset) {
	return ((struct failure**) (((struct failure**) a) + offset));
}
/* end-ptr<a> const-ptr<failure>(a arr<failure>) */
struct failure** end_ptr_14(struct arr_15 a) {
	return _plus_17(a.begin_ptr, a.size);
}
/* ~=<a> void(a mut-arr<failure>, value failure) */
struct void_ _concatEquals_10(struct ctx* ctx, struct mut_arr_6* a, struct failure* value) {
	incr_capacity__e_4(ctx, a);
	uint64_t _0 = capacity_5(a);
	uint8_t _1 = _less_0(a->size, _0);
	assert_0(ctx, _1);
	struct failure** _2 = begin_ptr_16(a);
	set_subscript_20(_2, a->size, value);
	uint64_t _3 = _plus_3(ctx, a->size, 1u);
	return (a->size = _3, (struct void_) {});
}
/* incr-capacity!<a> void(a mut-arr<failure>) */
struct void_ incr_capacity__e_4(struct ctx* ctx, struct mut_arr_6* a) {
	uint64_t _0 = _plus_3(ctx, a->size, 1u);
	uint64_t _1 = round_up_to_power_of_two(ctx, _0);
	return ensure_capacity_4(ctx, a, _1);
}
/* ensure-capacity<a> void(a mut-arr<failure>, min-capacity nat64) */
struct void_ ensure_capacity_4(struct ctx* ctx, struct mut_arr_6* a, uint64_t min_capacity) {
	uint64_t _0 = capacity_5(a);
	uint8_t _1 = _less_0(_0, min_capacity);
	if (_1) {
		return increase_capacity_to__e_4(ctx, a, min_capacity);
	} else {
		return (struct void_) {};
	}
}
/* capacity<a> nat64(a mut-arr<failure>) */
uint64_t capacity_5(struct mut_arr_6* a) {
	return size_12(a->backing);
}
/* size<a> nat64(a fix-arr<failure>) */
uint64_t size_12(struct fix_arr_11 a) {
	return a.inner.size;
}
/* increase-capacity-to!<a> void(a mut-arr<failure>, new-capacity nat64) */
struct void_ increase_capacity_to__e_4(struct ctx* ctx, struct mut_arr_6* a, uint64_t new_capacity) {
	uint64_t _0 = capacity_5(a);
	uint8_t _1 = _greater(new_capacity, _0);
	assert_0(ctx, _1);
	struct failure** old_begin0;
	old_begin0 = begin_ptr_16(a);
	
	struct fix_arr_11 _2 = uninitialized_fix_arr_9(ctx, new_capacity);
	a->backing = _2;
	struct failure** _3 = begin_ptr_16(a);
	copy_data_from__e_7(ctx, _3, ((struct failure**) old_begin0), a->size);
	uint64_t _4 = _plus_3(ctx, a->size, 1u);
	uint64_t _5 = size_12(a->backing);
	struct range _6 = _range(ctx, _4, _5);
	struct fix_arr_11 _7 = subscript_110(ctx, a->backing, _6);
	return set_zero_elements_4(_7);
}
/* begin-ptr<a> mut-ptr<failure>(a mut-arr<failure>) */
struct failure** begin_ptr_16(struct mut_arr_6* a) {
	return begin_ptr_17(a->backing);
}
/* begin-ptr<a> mut-ptr<failure>(a fix-arr<failure>) */
struct failure** begin_ptr_17(struct fix_arr_11 a) {
	return ((struct failure**) a.inner.begin_ptr);
}
/* uninitialized-fix-arr<a> fix-arr<failure>(size nat64) */
struct fix_arr_11 uninitialized_fix_arr_9(struct ctx* ctx, uint64_t size) {
	struct failure** _0 = alloc_uninitialized_9(ctx, size);
	return fix_arr_22(size, _0);
}
/* fix-arr<a> fix-arr<failure>(size nat64, begin-ptr mut-ptr<failure>) */
struct fix_arr_11 fix_arr_22(uint64_t size, struct failure** begin_ptr) {
	return (struct fix_arr_11) {(struct void_) {}, (struct arr_15) {size, ((struct failure**) begin_ptr)}};
}
/* alloc-uninitialized<a> mut-ptr<failure>(size nat64) */
struct failure** alloc_uninitialized_9(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(struct failure*)));
	return ((struct failure**) _0);
}
/* copy-data-from!<a> void(to mut-ptr<failure>, from const-ptr<failure>, len nat64) */
struct void_ copy_data_from__e_7(struct ctx* ctx, struct failure** to, struct failure** from, uint64_t len) {
	uint8_t* _0 = as_any_const_ptr_8(from);
	uint8_t* _1 = memcpy(((uint8_t*) to), _0, (len * sizeof(struct failure*)));
	return drop_0(_1);
}
/* as-any-const-ptr<const-ptr<a>> const-ptr<nat8>(ref const-ptr<failure>) */
uint8_t* as_any_const_ptr_8(struct failure** ref) {
	return ((uint8_t*) ((uint8_t*) ref));
}
/* set-zero-elements<a> void(a fix-arr<failure>) */
struct void_ set_zero_elements_4(struct fix_arr_11 a) {
	struct failure** _0 = begin_ptr_17(a);
	uint64_t _1 = size_12(a);
	return set_zero_range_5(_0, _1);
}
/* set-zero-range<a> void(begin mut-ptr<failure>, size nat64) */
struct void_ set_zero_range_5(struct failure** begin, uint64_t size) {
	uint8_t* _0 = memset(((uint8_t*) begin), 0, (size * sizeof(struct failure*)));
	return drop_0(_0);
}
/* subscript<a> fix-arr<failure>(a fix-arr<failure>, range range<nat64>) */
struct fix_arr_11 subscript_110(struct ctx* ctx, struct fix_arr_11 a, struct range range) {
	struct arr_15 _0 = subscript_111(ctx, a.inner, range);
	return (struct fix_arr_11) {(struct void_) {}, _0};
}
/* subscript<a> arr<failure>(a arr<failure>, range range<nat64>) */
struct arr_15 subscript_111(struct ctx* ctx, struct arr_15 a, struct range range) {
	uint8_t _0 = _lessOrEqual_0(range.high, a.size);
	assert_0(ctx, _0);
	struct failure** _1 = _plus_17(a.begin_ptr, range.low);
	return (struct arr_15) {(range.high - range.low), _1};
}
/* set-subscript<a> void(a mut-ptr<failure>, n nat64, value failure) */
struct void_ set_subscript_20(struct failure** a, uint64_t n, struct failure* value) {
	return (*(a + n) = value, (struct void_) {});
}
/* ~=<out>.lambda0 void(x failure) */
struct void_ _concatEquals_9__lambda0(struct ctx* ctx, struct _concatEquals_9__lambda0* _closure, struct failure* x) {
	return _concatEquals_10(ctx, _closure->a, x);
}
/* subscript<arr<out>, in> arr<failure>(a fun-act1<arr<failure>, str>, p0 str) */
struct arr_15 subscript_112(struct ctx* ctx, struct fun_act1_27 a, struct str p0) {
	return call_w_ctx_1176(a, ctx, p0);
}
/* call-w-ctx<arr<failure>, str> (generated) (generated) */
struct arr_15 call_w_ctx_1176(struct fun_act1_27 a, struct ctx* ctx, struct str p0) {
	struct fun_act1_27 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct run_crow_tests__lambda0* closure0 = _0.as0;
			
			return run_crow_tests__lambda0(ctx, closure0, p0);
		}
		case 1: {
			struct lint__lambda0* closure1 = _0.as1;
			
			return lint__lambda0(ctx, closure1, p0);
		}
		default:
			
	return (struct arr_15) {0, NULL};;
	}
}
/* reduce-size-if-more-than!<out> void(a mut-arr<failure>, new-size nat64) */
struct void_ reduce_size_if_more_than__e(struct ctx* ctx, struct mut_arr_6* a, uint64_t new_size) {
	top:;
	uint8_t _0 = _less_0(new_size, a->size);
	if (_0) {
		struct opt_23 _1 = pop__e(ctx, a);
		drop_7(_1);
		a = a;
		new_size = new_size;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* drop<opt<a>> void(_ opt<failure>) */
struct void_ drop_7(struct opt_23 _p0) {
	return (struct void_) {};
}
/* pop!<a> opt<failure>(a mut-arr<failure>) */
struct opt_23 pop__e(struct ctx* ctx, struct mut_arr_6* a) {
	uint8_t _0 = is_empty_19(a);
	uint8_t _1 = _not(_0);
	if (_1) {
		uint64_t new_size0;
		new_size0 = (a->size - 1u);
		
		struct failure* res1;
		res1 = subscript_113(ctx, a, new_size0);
		
		set_subscript_21(ctx, a, new_size0, NULL);
		a->size = new_size0;
		return (struct opt_23) {1, .as1 = (struct some_23) {res1}};
	} else {
		return (struct opt_23) {0, .as0 = (struct none) {}};
	}
}
/* is-empty<a> bool(a mut-arr<failure>) */
uint8_t is_empty_19(struct mut_arr_6* a) {
	return (a->size == 0u);
}
/* subscript<a> failure(a mut-arr<failure>, index nat64) */
struct failure* subscript_113(struct ctx* ctx, struct mut_arr_6* a, uint64_t index) {
	uint8_t _0 = _less_0(index, a->size);
	assert_0(ctx, _0);
	struct failure** _1 = begin_ptr_16(a);
	return subscript_114(_1, index);
}
/* subscript<a> failure(a mut-ptr<failure>, n nat64) */
struct failure* subscript_114(struct failure** a, uint64_t n) {
	return (*(a + n));
}
/* set-subscript<a> void(a mut-arr<failure>, index nat64, value failure) */
struct void_ set_subscript_21(struct ctx* ctx, struct mut_arr_6* a, uint64_t index, struct failure* value) {
	uint8_t _0 = _less_0(index, a->size);
	assert_0(ctx, _0);
	struct failure** _1 = begin_ptr_16(a);
	return set_subscript_20(_1, index, value);
}
/* flat-map-with-max-size<failure, str>.lambda0 void(x str) */
struct void_ flat_map_with_max_size__lambda0(struct ctx* ctx, struct flat_map_with_max_size__lambda0* _closure, struct str x) {
	uint8_t _0 = _less_0(_closure->res->size, _closure->max_size);
	if (_0) {
		struct arr_15 _1 = subscript_112(ctx, _closure->mapper, x);
		_concatEquals_9(ctx, _closure->res, _1);
		return reduce_size_if_more_than__e(ctx, _closure->res, _closure->max_size);
	} else {
		return (struct void_) {};
	}
}
/* move-to-arr!<out> arr<failure>(a mut-arr<failure>) */
struct arr_15 move_to_arr__e_3(struct mut_arr_6* a) {
	struct fix_arr_11 _0 = move_to_fix_arr__e_3(a);
	return cast_immutable_7(_0);
}
/* cast-immutable<a> arr<failure>(a fix-arr<failure>) */
struct arr_15 cast_immutable_7(struct fix_arr_11 a) {
	return a.inner;
}
/* move-to-fix-arr!<a> fix-arr<failure>(a mut-arr<failure>) */
struct fix_arr_11 move_to_fix_arr__e_3(struct mut_arr_6* a) {
	struct fix_arr_11 res0;
	struct failure** _0 = begin_ptr_16(a);
	res0 = fix_arr_22(a->size, _0);
	
	struct fix_arr_11 _1 = fix_arr_21();
	a->backing = _1;
	a->size = 0u;
	return res0;
}
/* run-single-crow-test arr<failure>(path-to-crow str, env dict<str, str>, path str, options test-options) */
struct arr_15 run_single_crow_test(struct ctx* ctx, struct str path_to_crow, struct dict_1 env, struct str path, struct test_options* options) {
	struct opt_24 op0;
	struct run_single_crow_test__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct run_single_crow_test__lambda0));
	temp0 = ((struct run_single_crow_test__lambda0*) _0);
	
	*temp0 = (struct run_single_crow_test__lambda0) {options, path, path_to_crow, env};
	op0 = first_some(ctx, (struct arr_2) {4, constantarr_2_1}, (struct fun_act1_29) {0, .as0 = temp0});
	
	struct opt_24 _1 = op0;
	switch (_1.kind) {
		case 0: {
			uint8_t _2 = options->print_tests;
			if (_2) {
				struct interp _3 = interp(ctx);
				struct interp _4 = with_str(ctx, _3, (struct str) {{9, constantarr_0_74}});
				struct interp _5 = with_value_0(ctx, _4, path);
				struct str _6 = finish(ctx, _5);
				print(_6);
			} else {
				(struct void_) {};
			}
			struct arr_15 interpret_failures1;
			interpret_failures1 = run_single_runnable_test(ctx, path_to_crow, env, path, 1, options->overwrite_output);
			
			uint8_t _7 = is_empty_21(interpret_failures1);
			if (_7) {
				return run_single_runnable_test(ctx, path_to_crow, env, path, 0, options->overwrite_output);
			} else {
				return interpret_failures1;
			}
		}
		case 1: {
			struct some_24 _matched2 = _1.as1;
			
			struct arr_15 res3;
			res3 = _matched2.value;
			
			return res3;
		}
		default:
			
	return (struct arr_15) {0, NULL};;
	}
}
/* first-some<arr<failure>, str> opt<arr<failure>>(a arr<str>, f fun-act1<opt<arr<failure>>, str>) */
struct opt_24 first_some(struct ctx* ctx, struct arr_2 a, struct fun_act1_29 f) {
	top:;
	uint8_t _0 = is_empty_7(a);
	uint8_t _1 = _not(_0);
	if (_1) {
		struct opt_24 res0;
		struct str _2 = subscript_26(ctx, a, 0u);
		res0 = subscript_115(ctx, f, _2);
		
		uint8_t _3 = is_empty_20(res0);
		if (_3) {
			struct arr_2 _4 = tail_3(ctx, a);
			a = _4;
			f = f;
			goto top;
		} else {
			return res0;
		}
	} else {
		return (struct opt_24) {0, .as0 = (struct none) {}};
	}
}
/* subscript<opt<out>, in> opt<arr<failure>>(a fun-act1<opt<arr<failure>>, str>, p0 str) */
struct opt_24 subscript_115(struct ctx* ctx, struct fun_act1_29 a, struct str p0) {
	return call_w_ctx_1191(a, ctx, p0);
}
/* call-w-ctx<opt<arr<failure>>, str> (generated) (generated) */
struct opt_24 call_w_ctx_1191(struct fun_act1_29 a, struct ctx* ctx, struct str p0) {
	struct fun_act1_29 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct run_single_crow_test__lambda0* closure0 = _0.as0;
			
			return run_single_crow_test__lambda0(ctx, closure0, p0);
		}
		default:
			
	return (struct opt_24) {0};;
	}
}
/* is-empty<out> bool(a opt<arr<failure>>) */
uint8_t is_empty_20(struct opt_24 a) {
	struct opt_24 _0 = a;
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
/* run-print-test print-test-result(print-kind str, path-to-crow str, env dict<str, str>, path str, overwrite-output bool) */
struct print_test_result* run_print_test(struct ctx* ctx, struct str print_kind, struct str path_to_crow, struct dict_1 env, struct str path, uint8_t overwrite_output) {
	struct process_result* res0;
	struct str* temp0;
	uint8_t* _0 = alloc(ctx, (sizeof(struct str) * 3u));
	temp0 = ((struct str*) _0);
	
	*(temp0 + 0u) = (struct str) {{5, constantarr_0_61}};
	*(temp0 + 1u) = print_kind;
	*(temp0 + 2u) = path;
	res0 = spawn_and_wait_result_0(ctx, path_to_crow, (struct arr_2) {3u, temp0}, env);
	
	struct str output_path1;
	struct interp _1 = interp(ctx);
	struct interp _2 = with_value_0(ctx, _1, path);
	struct interp _3 = with_str(ctx, _2, (struct str) {{1, constantarr_0_30}});
	struct interp _4 = with_value_0(ctx, _3, print_kind);
	struct interp _5 = with_str(ctx, _4, (struct str) {{5, constantarr_0_62}});
	output_path1 = finish(ctx, _5);
	
	struct arr_15 output_failures2;
	uint8_t _6 = is_empty_0(res0->stdout);uint8_t _7;
	
	if (_6) {
		_7 = _notEqual_6(res0->exit_code, 0);
	} else {
		_7 = 0;
	}
	if (_7) {
		output_failures2 = (struct arr_15) {0u, NULL};
	} else {
		output_failures2 = handle_output(ctx, path, output_path1, res0->stdout, overwrite_output);
	}
	
	uint8_t _8 = is_empty_21(output_failures2);
	uint8_t _9 = _not(_8);
	if (_9) {
		struct print_test_result* temp1;
		uint8_t* _10 = alloc(ctx, sizeof(struct print_test_result));
		temp1 = ((struct print_test_result*) _10);
		
		*temp1 = (struct print_test_result) {1, output_failures2};
		return temp1;
	} else {
		uint8_t _11 = (res0->exit_code == 0);
		if (_11) {
			uint8_t _12 = _equal_5(res0->stderr, (struct str) {{0u, NULL}});
			assert_0(ctx, _12);
			struct print_test_result* temp2;
			uint8_t* _13 = alloc(ctx, sizeof(struct print_test_result));
			temp2 = ((struct print_test_result*) _13);
			
			*temp2 = (struct print_test_result) {0, (struct arr_15) {0u, NULL}};
			return temp2;
		} else {
			uint8_t _14 = (res0->exit_code == 1);
			if (_14) {
				struct str stderr_no_color3;
				stderr_no_color3 = remove_colors(ctx, res0->stderr);
				
				struct print_test_result* temp3;
				uint8_t* _15 = alloc(ctx, sizeof(struct print_test_result));
				temp3 = ((struct print_test_result*) _15);
				
				struct interp _16 = interp(ctx);
				struct interp _17 = with_value_0(ctx, _16, output_path1);
				struct interp _18 = with_str(ctx, _17, (struct str) {{4, constantarr_0_72}});
				struct str _19 = finish(ctx, _18);
				struct arr_15 _20 = handle_output(ctx, path, _19, stderr_no_color3, overwrite_output);
				*temp3 = (struct print_test_result) {1, _20};
				return temp3;
			} else {
				struct str message4;
				struct interp _21 = interp(ctx);
				struct interp _22 = with_str(ctx, _21, (struct str) {{22, constantarr_0_73}});
				struct interp _23 = with_value_2(ctx, _22, res0->exit_code);
				message4 = finish(ctx, _23);
				
				struct print_test_result* temp6;
				uint8_t* _24 = alloc(ctx, sizeof(struct print_test_result));
				temp6 = ((struct print_test_result*) _24);
				
				struct failure** temp4;
				uint8_t* _25 = alloc(ctx, (sizeof(struct failure*) * 1u));
				temp4 = ((struct failure**) _25);
				
				struct failure* temp5;
				uint8_t* _26 = alloc(ctx, sizeof(struct failure));
				temp5 = ((struct failure*) _26);
				
				*temp5 = (struct failure) {path, message4};
				*(temp4 + 0u) = temp5;
				*temp6 = (struct print_test_result) {1, (struct arr_15) {1u, temp4}};
				return temp6;
			}
		}
	}
}
/* spawn-and-wait-result process-result(exe str, args arr<str>, environ dict<str, str>) */
struct process_result* spawn_and_wait_result_0(struct ctx* ctx, struct str exe, struct arr_2 args, struct dict_1 environ) {
	struct interp _0 = interp(ctx);
	struct interp _1 = with_str(ctx, _0, (struct str) {{23, constantarr_0_38}});
	struct interp _2 = with_value_0(ctx, _1, exe);
	struct str _3 = finish(ctx, _2);
	struct str _4 = fold_26(ctx, _3, args, (struct fun_act2_19) {0, .as0 = (struct void_) {}});
	print(_4);
	uint8_t _5 = is_file_0(ctx, exe);
	if (_5) {
		char* exe_c_str0;
		exe_c_str0 = to_c_str(ctx, exe);
		
		char** _6 = convert_args(ctx, exe_c_str0, args);
		char** _7 = convert_environ(ctx, environ);
		return spawn_and_wait_result_1(ctx, exe_c_str0, _6, _7);
	} else {
		struct interp _8 = interp(ctx);
		struct interp _9 = with_value_0(ctx, _8, exe);
		struct interp _10 = with_str(ctx, _9, (struct str) {{14, constantarr_0_60}});
		struct str _11 = finish(ctx, _10);
		return throw_12(ctx, _11);
	}
}
/* fold<str, str> str(acc str, a arr<str>, f fun-act2<str, str, str>) */
struct str fold_26(struct ctx* ctx, struct str acc, struct arr_2 a, struct fun_act2_19 f) {
	struct str* _0 = end_ptr_7(a);
	return fold_recur_14(ctx, acc, a.begin_ptr, _0, f);
}
/* fold-recur<a, b> str(acc str, cur const-ptr<str>, end const-ptr<str>, f fun-act2<str, str, str>) */
struct str fold_recur_14(struct ctx* ctx, struct str acc, struct str* cur, struct str* end, struct fun_act2_19 f) {
	top:;
	uint8_t _0 = _equal_9(cur, end);
	if (_0) {
		return acc;
	} else {
		struct str _1 = _times_10(cur);
		struct str _2 = subscript_116(ctx, f, acc, _1);
		struct str* _3 = _plus_8(cur, 1u);
		acc = _2;
		cur = _3;
		end = end;
		f = f;
		goto top;
	}
}
/* subscript<a, a, b> str(a fun-act2<str, str, str>, p0 str, p1 str) */
struct str subscript_116(struct ctx* ctx, struct fun_act2_19 a, struct str p0, struct str p1) {
	return call_w_ctx_1198(a, ctx, p0, p1);
}
/* call-w-ctx<str, str, str> (generated) (generated) */
struct str call_w_ctx_1198(struct fun_act2_19 a, struct ctx* ctx, struct str p0, struct str p1) {
	struct fun_act2_19 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return spawn_and_wait_result_0__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return (struct str) {(struct arr_0) {0, NULL}};;
	}
}
/* spawn-and-wait-result.lambda0 str(a str, b str) */
struct str spawn_and_wait_result_0__lambda0(struct ctx* ctx, struct void_ _closure, struct str a, struct str b) {
	struct interp _0 = interp(ctx);
	struct interp _1 = with_value_0(ctx, _0, a);
	struct interp _2 = with_str(ctx, _1, (struct str) {{1, constantarr_0_37}});
	struct interp _3 = with_value_0(ctx, _2, b);
	return finish(ctx, _3);
}
/* is-file bool(path str) */
uint8_t is_file_0(struct ctx* ctx, struct str path) {
	char* _0 = to_c_str(ctx, path);
	return is_file_1(ctx, _0);
}
/* is-file bool(path const-ptr<char>) */
uint8_t is_file_1(struct ctx* ctx, char* path) {
	struct opt_21 _0 = get_stat(ctx, path);
	switch (_0.kind) {
		case 0: {
			return 0;
		}
		case 1: {
			struct some_21 _matched0 = _0.as1;
			
			struct stat* stat1;
			stat1 = _matched0.value;
			
			uint32_t _1 = S_IFMT();
			uint32_t _2 = S_IFREG();
			return ((stat1->st_mode & _1) == _2);
		}
		default:
			
	return 0;;
	}
}
/* S_IFREG nat32() */
uint32_t S_IFREG(void) {
	return 32768u;
}
/* spawn-and-wait-result process-result(exe const-ptr<char>, args const-ptr<const-ptr<char>>, environ const-ptr<const-ptr<char>>) */
struct process_result* spawn_and_wait_result_1(struct ctx* ctx, char* exe, char** args, char** environ) {
	struct pipes* stdout_pipes0;
	stdout_pipes0 = make_pipes(ctx);
	
	struct pipes* stderr_pipes1;
	stderr_pipes1 = make_pipes(ctx);
	
	struct posix_spawn_file_actions_t* actions2;
	struct posix_spawn_file_actions_t* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct posix_spawn_file_actions_t));
	temp0 = ((struct posix_spawn_file_actions_t*) _0);
	
	struct bytes64 _1 = zero_0();
	*temp0 = (struct posix_spawn_file_actions_t) {0, 0, NULL, _1};
	actions2 = temp0;
	
	int32_t _2 = posix_spawn_file_actions_init(actions2);
	check_posix_error(ctx, _2);
	int32_t _3 = posix_spawn_file_actions_addclose(actions2, stdout_pipes0->write_pipe);
	check_posix_error(ctx, _3);
	int32_t _4 = posix_spawn_file_actions_addclose(actions2, stderr_pipes1->write_pipe);
	check_posix_error(ctx, _4);
	int32_t _5 = stdout();
	int32_t _6 = posix_spawn_file_actions_adddup2(actions2, stdout_pipes0->read_pipe, _5);
	check_posix_error(ctx, _6);
	int32_t _7 = stderr();
	int32_t _8 = posix_spawn_file_actions_adddup2(actions2, stderr_pipes1->read_pipe, _7);
	check_posix_error(ctx, _8);
	int32_t _9 = posix_spawn_file_actions_addclose(actions2, stdout_pipes0->read_pipe);
	check_posix_error(ctx, _9);
	int32_t _10 = posix_spawn_file_actions_addclose(actions2, stderr_pipes1->read_pipe);
	check_posix_error(ctx, _10);
	struct cell_5* pid_cell3;
	struct cell_5* temp1;
	uint8_t* _11 = alloc(ctx, sizeof(struct cell_5));
	temp1 = ((struct cell_5*) _11);
	
	*temp1 = (struct cell_5) {0};
	pid_cell3 = temp1;
	
	uint8_t* _12 = null_0();
	int32_t _13 = posix_spawn(pid_cell3, exe, actions2, _12, args, environ);
	check_posix_error(ctx, _13);
	int32_t pid4;
	pid4 = _times_21(pid_cell3);
	
	int32_t _14 = close(stdout_pipes0->read_pipe);
	check_posix_error(ctx, _14);
	int32_t _15 = close(stderr_pipes1->read_pipe);
	check_posix_error(ctx, _15);
	struct mut_arr_1* stdout_builder5;
	stdout_builder5 = mut_arr_0(ctx);
	
	struct mut_arr_1* stderr_builder6;
	stderr_builder6 = mut_arr_0(ctx);
	
	keep_polling(ctx, stdout_pipes0->write_pipe, stderr_pipes1->write_pipe, stdout_builder5, stderr_builder6);
	int32_t exit_code7;
	exit_code7 = wait_and_get_exit_code(ctx, pid4);
	
	struct process_result* temp2;
	uint8_t* _16 = alloc(ctx, sizeof(struct process_result));
	temp2 = ((struct process_result*) _16);
	
	struct arr_0 _17 = move_to_arr__e_0(stdout_builder5);
	struct arr_0 _18 = move_to_arr__e_0(stderr_builder6);
	*temp2 = (struct process_result) {exit_code7, (struct str) {_17}, (struct str) {_18}};
	return temp2;
}
/* make-pipes pipes() */
struct pipes* make_pipes(struct ctx* ctx) {
	struct pipes* res0;
	struct pipes* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct pipes));
	temp0 = ((struct pipes*) _0);
	
	*temp0 = (struct pipes) {0, 0};
	res0 = temp0;
	
	int32_t _1 = pipe(res0);
	check_posix_error(ctx, _1);
	return res0;
}
/* check-posix-error void(e int32) */
struct void_ check_posix_error(struct ctx* ctx, int32_t e) {
	return assert_0(ctx, (e == 0));
}
/* *<int32> int32(a cell<int32>) */
int32_t _times_21(struct cell_5* a) {
	return a->inner_value;
}
/* keep-polling void(stdout-pipe int32, stderr-pipe int32, stdout-builder mut-arr<char>, stderr-builder mut-arr<char>) */
struct void_ keep_polling(struct ctx* ctx, int32_t stdout_pipe, int32_t stderr_pipe, struct mut_arr_1* stdout_builder, struct mut_arr_1* stderr_builder) {
	top:;
	struct fix_arr_12 poll_fds0;
	struct pollfd* temp0;
	uint8_t* _0 = alloc(ctx, (sizeof(struct pollfd) * 2u));
	temp0 = ((struct pollfd*) _0);
	
	int16_t _1 = POLLIN(ctx);
	*(temp0 + 0u) = (struct pollfd) {stdout_pipe, _1, 0};
	int16_t _2 = POLLIN(ctx);
	*(temp0 + 1u) = (struct pollfd) {stderr_pipe, _2, 0};
	poll_fds0 = fix_arr_23(ctx, (struct arr_16) {2u, temp0});
	
	struct pollfd* stdout_pollfd1;
	stdout_pollfd1 = ref_of_val_at(ctx, poll_fds0, 0u);
	
	struct pollfd* stderr_pollfd2;
	stderr_pollfd2 = ref_of_val_at(ctx, poll_fds0, 1u);
	
	int64_t n_pollfds_with_events3;
	struct pollfd* _3 = begin_ptr_18(poll_fds0);
	uint64_t _4 = size_13(poll_fds0);
	int32_t _5 = poll(_3, _4, -1);
	n_pollfds_with_events3 = ((int64_t) _5);
	
	uint8_t _6 = (n_pollfds_with_events3 == 0);
	if (_6) {
		return (struct void_) {};
	} else {
		struct handle_revents_result a4;
		a4 = handle_revents(ctx, stdout_pollfd1, stdout_builder);
		
		struct handle_revents_result b5;
		b5 = handle_revents(ctx, stderr_pollfd2, stderr_builder);
		
		uint8_t _7 = any(ctx, a4);
		uint64_t _8 = to_nat64_1(_7);
		uint8_t _9 = any(ctx, b5);
		uint64_t _10 = to_nat64_1(_9);
		uint64_t _11 = to_nat64_0(ctx, n_pollfds_with_events3);
		assert_0(ctx, ((_8 + _10) == _11));uint8_t _12;
		
		if (a4.hung_up) {
			_12 = b5.hung_up;
		} else {
			_12 = 0;
		}
		uint8_t _13 = _not(_12);
		if (_13) {
			stdout_pipe = stdout_pipe;
			stderr_pipe = stderr_pipe;
			stdout_builder = stdout_builder;
			stderr_builder = stderr_builder;
			goto top;
		} else {
			return (struct void_) {};
		}
	}
}
/* fix-arr<by-val<pollfd>> fix-arr<pollfd>(a arr<pollfd>) */
struct fix_arr_12 fix_arr_23(struct ctx* ctx, struct arr_16 a) {
	struct fix_arr_23__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct fix_arr_23__lambda0));
	temp0 = ((struct fix_arr_23__lambda0*) _0);
	
	*temp0 = (struct fix_arr_23__lambda0) {a};
	return make_fix_arr_6(ctx, a.size, (struct fun_act1_30) {0, .as0 = temp0});
}
/* make-fix-arr<a> fix-arr<pollfd>(size nat64, f fun-act1<pollfd, nat64>) */
struct fix_arr_12 make_fix_arr_6(struct ctx* ctx, uint64_t size, struct fun_act1_30 f) {
	struct fix_arr_12 res0;
	res0 = uninitialized_fix_arr_10(ctx, size);
	
	struct pollfd* _0 = begin_ptr_18(res0);
	fill_ptr_range_6(ctx, _0, size, f);
	return res0;
}
/* uninitialized-fix-arr<a> fix-arr<pollfd>(size nat64) */
struct fix_arr_12 uninitialized_fix_arr_10(struct ctx* ctx, uint64_t size) {
	struct pollfd* _0 = alloc_uninitialized_10(ctx, size);
	return fix_arr_24(size, _0);
}
/* fix-arr<a> fix-arr<pollfd>(size nat64, begin-ptr mut-ptr<pollfd>) */
struct fix_arr_12 fix_arr_24(uint64_t size, struct pollfd* begin_ptr) {
	return (struct fix_arr_12) {(struct void_) {}, (struct arr_16) {size, ((struct pollfd*) begin_ptr)}};
}
/* alloc-uninitialized<a> mut-ptr<pollfd>(size nat64) */
struct pollfd* alloc_uninitialized_10(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(struct pollfd)));
	return ((struct pollfd*) _0);
}
/* fill-ptr-range<a> void(begin mut-ptr<pollfd>, size nat64, f fun-act1<pollfd, nat64>) */
struct void_ fill_ptr_range_6(struct ctx* ctx, struct pollfd* begin, uint64_t size, struct fun_act1_30 f) {
	return fill_ptr_range_recur_6(ctx, begin, 0u, size, f);
}
/* fill-ptr-range-recur<a> void(begin mut-ptr<pollfd>, i nat64, size nat64, f fun-act1<pollfd, nat64>) */
struct void_ fill_ptr_range_recur_6(struct ctx* ctx, struct pollfd* begin, uint64_t i, uint64_t size, struct fun_act1_30 f) {
	top:;
	uint8_t _0 = _notEqual_5(i, size);
	if (_0) {
		struct pollfd _1 = subscript_117(ctx, f, i);
		set_subscript_22(begin, i, _1);
		begin = begin;
		i = (i + 1u);
		size = size;
		f = f;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* set-subscript<a> void(a mut-ptr<pollfd>, n nat64, value pollfd) */
struct void_ set_subscript_22(struct pollfd* a, uint64_t n, struct pollfd value) {
	return (*(a + n) = value, (struct void_) {});
}
/* subscript<a, nat64> pollfd(a fun-act1<pollfd, nat64>, p0 nat64) */
struct pollfd subscript_117(struct ctx* ctx, struct fun_act1_30 a, uint64_t p0) {
	return call_w_ctx_1223(a, ctx, p0);
}
/* call-w-ctx<pollfd, nat-64> (generated) (generated) */
struct pollfd call_w_ctx_1223(struct fun_act1_30 a, struct ctx* ctx, uint64_t p0) {
	struct fun_act1_30 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct fix_arr_23__lambda0* closure0 = _0.as0;
			
			return fix_arr_23__lambda0(ctx, closure0, p0);
		}
		default:
			
	return (struct pollfd) {0, 0, 0};;
	}
}
/* begin-ptr<a> mut-ptr<pollfd>(a fix-arr<pollfd>) */
struct pollfd* begin_ptr_18(struct fix_arr_12 a) {
	return ((struct pollfd*) a.inner.begin_ptr);
}
/* subscript<a> pollfd(a arr<pollfd>, index nat64) */
struct pollfd subscript_118(struct ctx* ctx, struct arr_16 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	return unsafe_at_16(a, index);
}
/* unsafe-at<a> pollfd(a arr<pollfd>, index nat64) */
struct pollfd unsafe_at_16(struct arr_16 a, uint64_t index) {
	return subscript_119(a.begin_ptr, index);
}
/* subscript<a> pollfd(a const-ptr<pollfd>, n nat64) */
struct pollfd subscript_119(struct pollfd* a, uint64_t n) {
	struct pollfd* _0 = _plus_18(a, n);
	return _times_22(_0);
}
/* *<a> pollfd(a const-ptr<pollfd>) */
struct pollfd _times_22(struct pollfd* a) {
	return (*((struct pollfd*) a));
}
/* +<a> const-ptr<pollfd>(a const-ptr<pollfd>, offset nat64) */
struct pollfd* _plus_18(struct pollfd* a, uint64_t offset) {
	return ((struct pollfd*) (((struct pollfd*) a) + offset));
}
/* fix-arr<by-val<pollfd>>.lambda0 pollfd(i nat64) */
struct pollfd fix_arr_23__lambda0(struct ctx* ctx, struct fix_arr_23__lambda0* _closure, uint64_t i) {
	return subscript_118(ctx, _closure->a, i);
}
/* POLLIN int16() */
int16_t POLLIN(struct ctx* ctx) {
	return 1;
}
/* ref-of-val-at<pollfd> pollfd(a fix-arr<pollfd>, index nat64) */
struct pollfd* ref_of_val_at(struct ctx* ctx, struct fix_arr_12 a, uint64_t index) {
	uint64_t _0 = size_13(a);
	uint8_t _1 = _less_0(index, _0);
	assert_0(ctx, _1);
	struct pollfd* _2 = begin_ptr_18(a);
	return ref_of_ptr((_2 + index));
}
/* size<by-val<a>> nat64(a fix-arr<pollfd>) */
uint64_t size_13(struct fix_arr_12 a) {
	return a.inner.size;
}
/* ref-of-ptr<a> pollfd(p mut-ptr<pollfd>) */
struct pollfd* ref_of_ptr(struct pollfd* p) {
	return (&(*p));
}
/* handle-revents handle-revents-result(pollfd pollfd, builder mut-arr<char>) */
struct handle_revents_result handle_revents(struct ctx* ctx, struct pollfd* pollfd, struct mut_arr_1* builder) {
	int16_t revents0;
	revents0 = pollfd->revents;
	
	uint8_t had_POLLIN1;
	had_POLLIN1 = has_POLLIN(ctx, revents0);
	
	uint8_t _0 = had_POLLIN1;
	if (_0) {
		read_to_buffer_until_eof(ctx, pollfd->fd, builder);
	} else {
		(struct void_) {};
	}
	uint8_t hung_up2;
	hung_up2 = has_POLLHUP(ctx, revents0);
	
	uint8_t _1 = has_POLLPRI(ctx, revents0);uint8_t _2;
	
	if (_1) {
		_2 = 1;
	} else {
		_2 = has_POLLOUT(ctx, revents0);
	}uint8_t _3;
	
	if (_2) {
		_3 = 1;
	} else {
		_3 = has_POLLERR(ctx, revents0);
	}uint8_t _4;
	
	if (_3) {
		_4 = 1;
	} else {
		_4 = has_POLLNVAL(ctx, revents0);
	}
	if (_4) {
		todo_0();
	} else {
		(struct void_) {};
	}
	return (struct handle_revents_result) {had_POLLIN1, hung_up2};
}
/* has-POLLIN bool(revents int16) */
uint8_t has_POLLIN(struct ctx* ctx, int16_t revents) {
	int16_t _0 = POLLIN(ctx);
	return bits_intersect(revents, _0);
}
/* bits-intersect bool(a int16, b int16) */
uint8_t bits_intersect(int16_t a, int16_t b) {
	return _notEqual_18((a & b), 0);
}
/* !=<int16> bool(a int16, b int16) */
uint8_t _notEqual_18(int16_t a, int16_t b) {
	return _not((a == b));
}
/* read-to-buffer-until-eof void(fd int32, buffer mut-arr<char>) */
struct void_ read_to_buffer_until_eof(struct ctx* ctx, int32_t fd, struct mut_arr_1* buffer) {
	top:;
	uint64_t old_size0;
	old_size0 = buffer->size;
	
	unsafe_set_size__e(ctx, buffer, (old_size0 + 1024u));
	char* add_data_to1;
	char* _0 = begin_ptr_0(buffer);
	add_data_to1 = (_0 + old_size0);
	
	int64_t n_bytes_read2;
	n_bytes_read2 = read(fd, ((uint8_t*) add_data_to1), 1024u);
	
	uint8_t _1 = (n_bytes_read2 == -1);
	if (_1) {
		return todo_0();
	} else {
		uint8_t _2 = (n_bytes_read2 == 0);
		if (_2) {
			unsafe_set_size__e(ctx, buffer, old_size0);
			return (struct void_) {};
		} else {
			uint64_t _3 = to_nat64_0(ctx, n_bytes_read2);
			uint8_t _4 = _lessOrEqual_0(_3, 1024u);
			assert_0(ctx, _4);
			uint64_t new_size3;
			uint64_t _5 = to_nat64_0(ctx, n_bytes_read2);
			new_size3 = (old_size0 + _5);
			
			unsafe_set_size__e(ctx, buffer, new_size3);
			fd = fd;
			buffer = buffer;
			goto top;
		}
	}
}
/* unsafe-set-size!<char> void(a mut-arr<char>, new-size nat64) */
struct void_ unsafe_set_size__e(struct ctx* ctx, struct mut_arr_1* a, uint64_t new_size) {
	reserve(ctx, a, new_size);
	return (a->size = new_size, (struct void_) {});
}
/* reserve<a> void(a mut-arr<char>, reserved nat64) */
struct void_ reserve(struct ctx* ctx, struct mut_arr_1* a, uint64_t reserved) {
	uint64_t _0 = round_up_to_power_of_two(ctx, reserved);
	return ensure_capacity_0(ctx, a, _0);
}
/* to-nat64 nat64(a int64) */
uint64_t to_nat64_0(struct ctx* ctx, int64_t a) {
	uint8_t _0 = _less_6(a, 0);
	forbid(ctx, _0);
	return ((uint64_t) a);
}
/* <=> comparison(a int64, b int64) */
struct comparison _compare_11(int64_t a, int64_t b) {
	return cmp_2(a, b);
}
/* cmp<int64> comparison(a int64, b int64) */
struct comparison cmp_2(int64_t a, int64_t b) {
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
/* <<int64> bool(a int64, b int64) */
uint8_t _less_6(int64_t a, int64_t b) {
	struct comparison _0 = _compare_11(a, b);
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
/* has-POLLHUP bool(revents int16) */
uint8_t has_POLLHUP(struct ctx* ctx, int16_t revents) {
	int16_t _0 = POLLHUP(ctx);
	return bits_intersect(revents, _0);
}
/* POLLHUP int16() */
int16_t POLLHUP(struct ctx* ctx) {
	return 16;
}
/* has-POLLPRI bool(revents int16) */
uint8_t has_POLLPRI(struct ctx* ctx, int16_t revents) {
	int16_t _0 = POLLPRI(ctx);
	return bits_intersect(revents, _0);
}
/* POLLPRI int16() */
int16_t POLLPRI(struct ctx* ctx) {
	return 2;
}
/* has-POLLOUT bool(revents int16) */
uint8_t has_POLLOUT(struct ctx* ctx, int16_t revents) {
	int16_t _0 = POLLOUT(ctx);
	return bits_intersect(revents, _0);
}
/* POLLOUT int16() */
int16_t POLLOUT(struct ctx* ctx) {
	return 4;
}
/* has-POLLERR bool(revents int16) */
uint8_t has_POLLERR(struct ctx* ctx, int16_t revents) {
	int16_t _0 = POLLERR(ctx);
	return bits_intersect(revents, _0);
}
/* POLLERR int16() */
int16_t POLLERR(struct ctx* ctx) {
	return 8;
}
/* has-POLLNVAL bool(revents int16) */
uint8_t has_POLLNVAL(struct ctx* ctx, int16_t revents) {
	int16_t _0 = POLLNVAL(ctx);
	return bits_intersect(revents, _0);
}
/* POLLNVAL int16() */
int16_t POLLNVAL(struct ctx* ctx) {
	return 32;
}
/* to-nat64 nat64(a bool) */
uint64_t to_nat64_1(uint8_t a) {
	uint8_t _0 = a;
	if (_0) {
		return 1u;
	} else {
		return 0u;
	}
}
/* any bool(r handle-revents-result) */
uint8_t any(struct ctx* ctx, struct handle_revents_result r) {
	if (r.had_POLLIN) {
		return 1;
	} else {
		return r.hung_up;
	}
}
/* wait-and-get-exit-code int32(pid int32) */
int32_t wait_and_get_exit_code(struct ctx* ctx, int32_t pid) {
	struct cell_5* wait_status_cell0;
	struct cell_5* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct cell_5));
	temp0 = ((struct cell_5*) _0);
	
	*temp0 = (struct cell_5) {0};
	wait_status_cell0 = temp0;
	
	int32_t res_pid1;
	res_pid1 = waitpid(pid, wait_status_cell0, 0);
	
	int32_t wait_status2;
	wait_status2 = _times_21(wait_status_cell0);
	
	assert_0(ctx, (res_pid1 == pid));
	uint8_t _1 = WIFEXITED(ctx, wait_status2);
	if (_1) {
		return WEXITSTATUS(ctx, wait_status2);
	} else {
		uint8_t _2 = WIFSIGNALED(ctx, wait_status2);
		if (_2) {
			int32_t signal3;
			signal3 = WTERMSIG(ctx, wait_status2);
			
			struct interp _3 = interp(ctx);
			struct interp _4 = with_str(ctx, _3, (struct str) {{31, constantarr_0_57}});
			struct interp _5 = with_value_2(ctx, _4, signal3);
			struct str _6 = finish(ctx, _5);
			print(_6);
			return todo_5();
		} else {
			uint8_t _7 = WIFSTOPPED(ctx, wait_status2);
			if (_7) {
				print((struct str) {{12, constantarr_0_58}});
				return todo_5();
			} else {
				uint8_t _8 = WIFCONTINUED(ctx, wait_status2);
				if (_8) {
					return todo_5();
				} else {
					return todo_5();
				}
			}
		}
	}
}
/* WIFEXITED bool(status int32) */
uint8_t WIFEXITED(struct ctx* ctx, int32_t status) {
	int32_t _0 = WTERMSIG(ctx, status);
	return (_0 == 0);
}
/* WTERMSIG int32(status int32) */
int32_t WTERMSIG(struct ctx* ctx, int32_t status) {
	return (status & 127);
}
/* WEXITSTATUS int32(status int32) */
int32_t WEXITSTATUS(struct ctx* ctx, int32_t status) {
	return _shiftRight((status & 65280), 8);
}
/* >> int32(a int32, b int32) */
int32_t _shiftRight(int32_t a, int32_t b) {
	uint8_t _0 = _less_7(a, 0);
	if (_0) {
		return todo_5();
	} else {
		uint8_t _1 = _less_7(b, 0);
		if (_1) {
			return todo_5();
		} else {
			uint8_t _2 = _less_7(b, 32);
			if (_2) {
				return ((int32_t) ((int64_t) (((uint64_t) ((int64_t) a)) >> ((uint64_t) ((int64_t) b)))));
			} else {
				return todo_5();
			}
		}
	}
}
/* <=> comparison(a int32, b int32) */
struct comparison _compare_12(int32_t a, int32_t b) {
	return cmp_3(a, b);
}
/* cmp<int32> comparison(a int32, b int32) */
struct comparison cmp_3(int32_t a, int32_t b) {
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
/* <<int32> bool(a int32, b int32) */
uint8_t _less_7(int32_t a, int32_t b) {
	struct comparison _0 = _compare_12(a, b);
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
/* todo<int32> int32() */
int32_t todo_5(void) {
	(abort(), (struct void_) {});
	return 0;
}
/* WIFSIGNALED bool(status int32) */
uint8_t WIFSIGNALED(struct ctx* ctx, int32_t status) {
	int32_t ts0;
	ts0 = WTERMSIG(ctx, status);
	
	uint8_t _0 = _notEqual_6(ts0, 0);
	if (_0) {
		return _notEqual_6(ts0, 127);
	} else {
		return 0;
	}
}
/* to-str str(a int32) */
struct str to_str_4(struct ctx* ctx, int32_t a) {
	return to_str_5(ctx, ((int64_t) a));
}
/* to-str str(a int64) */
struct str to_str_5(struct ctx* ctx, int64_t a) {
	struct str s0;
	uint64_t _0 = abs(ctx, a);
	s0 = to_str_6(ctx, _0);
	
	uint8_t _1 = _less_6(a, 0);
	if (_1) {
		struct interp _2 = interp(ctx);
		struct interp _3 = with_str(ctx, _2, (struct str) {{1, constantarr_0_56}});
		struct interp _4 = with_value_0(ctx, _3, s0);
		return finish(ctx, _4);
	} else {
		return s0;
	}
}
/* to-str str(a nat64) */
struct str to_str_6(struct ctx* ctx, uint64_t a) {
	return to_base(ctx, a, 10u);
}
/* to-base str(a nat64, base nat64) */
struct str to_base(struct ctx* ctx, uint64_t a, uint64_t base) {
	uint8_t _0 = _less_0(a, base);
	if (_0) {
		return digit_to_str(ctx, a);
	} else {
		uint64_t _1 = _divide(ctx, a, base);
		struct str _2 = to_base(ctx, _1, base);
		uint64_t _3 = mod(ctx, a, base);
		struct str _4 = digit_to_str(ctx, _3);
		return _tilde_0(ctx, _2, _4);
	}
}
/* digit-to-str str(a nat64) */
struct str digit_to_str(struct ctx* ctx, uint64_t a) {
	uint8_t _0 = (a == 0u);
	if (_0) {
		return (struct str) {{1, constantarr_0_39}};
	} else {
		uint8_t _1 = (a == 1u);
		if (_1) {
			return (struct str) {{1, constantarr_0_40}};
		} else {
			uint8_t _2 = (a == 2u);
			if (_2) {
				return (struct str) {{1, constantarr_0_41}};
			} else {
				uint8_t _3 = (a == 3u);
				if (_3) {
					return (struct str) {{1, constantarr_0_42}};
				} else {
					uint8_t _4 = (a == 4u);
					if (_4) {
						return (struct str) {{1, constantarr_0_43}};
					} else {
						uint8_t _5 = (a == 5u);
						if (_5) {
							return (struct str) {{1, constantarr_0_44}};
						} else {
							uint8_t _6 = (a == 6u);
							if (_6) {
								return (struct str) {{1, constantarr_0_45}};
							} else {
								uint8_t _7 = (a == 7u);
								if (_7) {
									return (struct str) {{1, constantarr_0_46}};
								} else {
									uint8_t _8 = (a == 8u);
									if (_8) {
										return (struct str) {{1, constantarr_0_47}};
									} else {
										uint8_t _9 = (a == 9u);
										if (_9) {
											return (struct str) {{1, constantarr_0_48}};
										} else {
											uint8_t _10 = (a == 10u);
											if (_10) {
												return (struct str) {{1, constantarr_0_49}};
											} else {
												uint8_t _11 = (a == 11u);
												if (_11) {
													return (struct str) {{1, constantarr_0_50}};
												} else {
													uint8_t _12 = (a == 12u);
													if (_12) {
														return (struct str) {{1, constantarr_0_51}};
													} else {
														uint8_t _13 = (a == 13u);
														if (_13) {
															return (struct str) {{1, constantarr_0_52}};
														} else {
															uint8_t _14 = (a == 14u);
															if (_14) {
																return (struct str) {{1, constantarr_0_53}};
															} else {
																uint8_t _15 = (a == 15u);
																if (_15) {
																	return (struct str) {{1, constantarr_0_54}};
																} else {
																	return (struct str) {{1, constantarr_0_55}};
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
					}
				}
			}
		}
	}
}
/* mod nat64(a nat64, b nat64) */
uint64_t mod(struct ctx* ctx, uint64_t a, uint64_t b) {
	forbid(ctx, (b == 0u));
	return (a % b);
}
/* abs nat64(a int64) */
uint64_t abs(struct ctx* ctx, int64_t a) {
	uint8_t _0 = _less_6(a, 0);int64_t _1;
	
	if (_0) {
		_1 = _minus_8(ctx, a);
	} else {
		_1 = a;
	}
	return to_nat64_0(ctx, _1);
}
/* - int64(a int64) */
int64_t _minus_8(struct ctx* ctx, int64_t a) {
	return _times_23(ctx, a, -1);
}
/* * int64(a int64, b int64) */
int64_t _times_23(struct ctx* ctx, int64_t a, int64_t b) {
	return (a * b);
}
/* with-value<int32> interp(a interp, b int32) */
struct interp with_value_2(struct ctx* ctx, struct interp a, int32_t b) {
	struct str _0 = to_str_4(ctx, b);
	return with_str(ctx, a, _0);
}
/* WIFSTOPPED bool(status int32) */
uint8_t WIFSTOPPED(struct ctx* ctx, int32_t status) {
	return ((status & 255) == 127);
}
/* WIFCONTINUED bool(status int32) */
uint8_t WIFCONTINUED(struct ctx* ctx, int32_t status) {
	return (status == 65535);
}
/* convert-args const-ptr<const-ptr<char>>(exe-c-str const-ptr<char>, args arr<str>) */
char** convert_args(struct ctx* ctx, char* exe_c_str, struct arr_2 args) {
	char** temp0;
	uint8_t* _0 = alloc(ctx, (sizeof(char*) * 1u));
	temp0 = ((char**) _0);
	
	*(temp0 + 0u) = exe_c_str;
	struct arr_7 _1 = map_1(ctx, args, (struct fun_act1_31) {0, .as0 = (struct void_) {}});
	struct arr_7 _2 = _tilde_8(ctx, (struct arr_7) {1u, temp0}, _1);
	char** temp1;
	uint8_t* _3 = alloc(ctx, (sizeof(char*) * 1u));
	temp1 = ((char**) _3);
	
	char* _4 = null_1();
	*(temp1 + 0u) = _4;
	struct arr_7 _5 = _tilde_8(ctx, _2, (struct arr_7) {1u, temp1});
	return _5.begin_ptr;
}
/* ~<const-ptr<char>> arr<const-ptr<char>>(a arr<const-ptr<char>>, b arr<const-ptr<char>>) */
struct arr_7 _tilde_8(struct ctx* ctx, struct arr_7 a, struct arr_7 b) {
	uint64_t res_size0;
	res_size0 = (a.size + b.size);
	
	char** res1;
	res1 = alloc_uninitialized_11(ctx, res_size0);
	
	copy_data_from__e_8(ctx, res1, a.begin_ptr, a.size);
	copy_data_from__e_8(ctx, (res1 + a.size), b.begin_ptr, b.size);
	return (struct arr_7) {res_size0, ((char**) res1)};
}
/* alloc-uninitialized<a> mut-ptr<const-ptr<char>>(size nat64) */
char** alloc_uninitialized_11(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(char*)));
	return ((char**) _0);
}
/* copy-data-from!<a> void(to mut-ptr<const-ptr<char>>, from const-ptr<const-ptr<char>>, len nat64) */
struct void_ copy_data_from__e_8(struct ctx* ctx, char** to, char** from, uint64_t len) {
	uint8_t* _0 = as_any_const_ptr_9(from);
	uint8_t* _1 = memcpy(((uint8_t*) to), _0, (len * sizeof(char*)));
	return drop_0(_1);
}
/* as-any-const-ptr<const-ptr<a>> const-ptr<nat8>(ref const-ptr<const-ptr<char>>) */
uint8_t* as_any_const_ptr_9(char** ref) {
	return ((uint8_t*) ((uint8_t*) ref));
}
/* map<const-ptr<char>, str> arr<const-ptr<char>>(a arr<str>, f fun-act1<const-ptr<char>, str>) */
struct arr_7 map_1(struct ctx* ctx, struct arr_2 a, struct fun_act1_31 f) {
	struct map_1__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct map_1__lambda0));
	temp0 = ((struct map_1__lambda0*) _0);
	
	*temp0 = (struct map_1__lambda0) {f, a};
	return make_arr_3(ctx, a.size, (struct fun_act1_32) {0, .as0 = temp0});
}
/* make-arr<out> arr<const-ptr<char>>(size nat64, f fun-act1<const-ptr<char>, nat64>) */
struct arr_7 make_arr_3(struct ctx* ctx, uint64_t size, struct fun_act1_32 f) {
	char** res0;
	res0 = alloc_uninitialized_11(ctx, size);
	
	fill_ptr_range_7(ctx, res0, size, f);
	return (struct arr_7) {size, ((char**) res0)};
}
/* fill-ptr-range<a> void(begin mut-ptr<const-ptr<char>>, size nat64, f fun-act1<const-ptr<char>, nat64>) */
struct void_ fill_ptr_range_7(struct ctx* ctx, char** begin, uint64_t size, struct fun_act1_32 f) {
	return fill_ptr_range_recur_7(ctx, begin, 0u, size, f);
}
/* fill-ptr-range-recur<a> void(begin mut-ptr<const-ptr<char>>, i nat64, size nat64, f fun-act1<const-ptr<char>, nat64>) */
struct void_ fill_ptr_range_recur_7(struct ctx* ctx, char** begin, uint64_t i, uint64_t size, struct fun_act1_32 f) {
	top:;
	uint8_t _0 = _notEqual_5(i, size);
	if (_0) {
		char* _1 = subscript_120(ctx, f, i);
		set_subscript_23(begin, i, _1);
		begin = begin;
		i = (i + 1u);
		size = size;
		f = f;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* set-subscript<a> void(a mut-ptr<const-ptr<char>>, n nat64, value const-ptr<char>) */
struct void_ set_subscript_23(char** a, uint64_t n, char* value) {
	return (*(a + n) = value, (struct void_) {});
}
/* subscript<a, nat64> const-ptr<char>(a fun-act1<const-ptr<char>, nat64>, p0 nat64) */
char* subscript_120(struct ctx* ctx, struct fun_act1_32 a, uint64_t p0) {
	return call_w_ctx_1294(a, ctx, p0);
}
/* call-w-ctx<raw-ptr-const(char), nat-64> (generated) (generated) */
char* call_w_ctx_1294(struct fun_act1_32 a, struct ctx* ctx, uint64_t p0) {
	struct fun_act1_32 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct map_1__lambda0* closure0 = _0.as0;
			
			return map_1__lambda0(ctx, closure0, p0);
		}
		default:
			
	return NULL;;
	}
}
/* subscript<out, in> const-ptr<char>(a fun-act1<const-ptr<char>, str>, p0 str) */
char* subscript_121(struct ctx* ctx, struct fun_act1_31 a, struct str p0) {
	return call_w_ctx_1296(a, ctx, p0);
}
/* call-w-ctx<raw-ptr-const(char), str> (generated) (generated) */
char* call_w_ctx_1296(struct fun_act1_31 a, struct ctx* ctx, struct str p0) {
	struct fun_act1_31 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return convert_args__lambda0(ctx, closure0, p0);
		}
		default:
			
	return NULL;;
	}
}
/* map<const-ptr<char>, str>.lambda0 const-ptr<char>(i nat64) */
char* map_1__lambda0(struct ctx* ctx, struct map_1__lambda0* _closure, uint64_t i) {
	struct str _0 = subscript_26(ctx, _closure->a, i);
	return subscript_121(ctx, _closure->f, _0);
}
/* convert-args.lambda0 const-ptr<char>(x str) */
char* convert_args__lambda0(struct ctx* ctx, struct void_ _closure, struct str x) {
	return to_c_str(ctx, x);
}
/* convert-environ const-ptr<const-ptr<char>>(environ dict<str, str>) */
char** convert_environ(struct ctx* ctx, struct dict_1 environ) {
	struct mut_arr_7* res0;
	res0 = mut_arr_7(ctx);
	
	struct convert_environ__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct convert_environ__lambda0));
	temp0 = ((struct convert_environ__lambda0*) _0);
	
	*temp0 = (struct convert_environ__lambda0) {res0};
	each_9(ctx, environ, (struct fun_act2_10) {1, .as1 = temp0});
	char* _1 = null_1();
	_concatEquals_11(ctx, res0, _1);
	struct arr_7 _2 = move_to_arr__e_4(res0);
	return _2.begin_ptr;
}
/* mut-arr<const-ptr<char>> mut-arr<const-ptr<char>>() */
struct mut_arr_7* mut_arr_7(struct ctx* ctx) {
	struct mut_arr_7* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_arr_7));
	temp0 = ((struct mut_arr_7*) _0);
	
	struct fix_arr_13 _1 = fix_arr_25();
	*temp0 = (struct mut_arr_7) {_1, 0u};
	return temp0;
}
/* fix-arr<a> fix-arr<const-ptr<char>>() */
struct fix_arr_13 fix_arr_25(void) {
	return (struct fix_arr_13) {(struct void_) {}, (struct arr_7) {0u, NULL}};
}
/* each<str, str> void(a dict<str, str>, f fun-act2<void, str, str>) */
struct void_ each_9(struct ctx* ctx, struct dict_1 a, struct fun_act2_10 f) {
	struct each_9__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct each_9__lambda0));
	temp0 = ((struct each_9__lambda0*) _0);
	
	*temp0 = (struct each_9__lambda0) {f};
	return fold_27(ctx, (struct void_) {}, a, (struct fun_act3_3) {1, .as1 = temp0});
}
/* fold<void, k, v> void(acc void, a dict<str, str>, f fun-act3<void, void, str, str>) */
struct void_ fold_27(struct ctx* ctx, struct void_ acc, struct dict_1 a, struct fun_act3_3 f) {
	return fold_recur_15(ctx, acc, a.root, f);
}
/* fold-recur<a, k, v> void(acc void, a node<str, str>, f fun-act3<void, void, str, str>) */
struct void_ fold_recur_15(struct ctx* ctx, struct void_ acc, struct node_1 a, struct fun_act3_3 f) {
	struct node_1 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct inner_node_1 i0 = _0.as0;
			
			struct fold_recur_15__lambda0* temp0;
			uint8_t* _1 = alloc(ctx, sizeof(struct fold_recur_15__lambda0));
			temp0 = ((struct fold_recur_15__lambda0*) _1);
			
			*temp0 = (struct fold_recur_15__lambda0) {f};
			return fold_28(ctx, acc, i0.children, (struct fun_act2_20) {0, .as0 = temp0});
		}
		case 1: {
			struct leaf_node_1 l1 = _0.as1;
			
			struct fold_recur_15__lambda1* temp1;
			uint8_t* _2 = alloc(ctx, sizeof(struct fold_recur_15__lambda1));
			temp1 = ((struct fold_recur_15__lambda1*) _2);
			
			*temp1 = (struct fold_recur_15__lambda1) {f};
			return fold_18(ctx, acc, l1.pairs, (struct fun_act2_12) {1, .as1 = temp1});
		}
		default:
			
	return (struct void_) {};;
	}
}
/* fold<a, node<k, v>> void(acc void, a arr<node<str, str>>, f fun-act2<void, void, node<str, str>>) */
struct void_ fold_28(struct ctx* ctx, struct void_ acc, struct arr_12 a, struct fun_act2_20 f) {
	struct node_1* _0 = end_ptr_10(a);
	return fold_recur_16(ctx, acc, a.begin_ptr, _0, f);
}
/* fold-recur<a, b> void(acc void, cur const-ptr<node<str, str>>, end const-ptr<node<str, str>>, f fun-act2<void, void, node<str, str>>) */
struct void_ fold_recur_16(struct ctx* ctx, struct void_ acc, struct node_1* cur, struct node_1* end, struct fun_act2_20 f) {
	top:;
	uint8_t _0 = _equal_12(cur, end);
	if (_0) {
		return acc;
	} else {
		struct node_1 _1 = _times_18(cur);
		struct void_ _2 = subscript_122(ctx, f, acc, _1);
		struct node_1* _3 = _plus_15(cur, 1u);
		acc = _2;
		cur = _3;
		end = end;
		f = f;
		goto top;
	}
}
/* subscript<a, a, b> void(a fun-act2<void, void, node<str, str>>, p0 void, p1 node<str, str>) */
struct void_ subscript_122(struct ctx* ctx, struct fun_act2_20 a, struct void_ p0, struct node_1 p1) {
	return call_w_ctx_1308(a, ctx, p0, p1);
}
/* call-w-ctx<void, void, node<str, str>> (generated) (generated) */
struct void_ call_w_ctx_1308(struct fun_act2_20 a, struct ctx* ctx, struct void_ p0, struct node_1 p1) {
	struct fun_act2_20 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct fold_recur_15__lambda0* closure0 = _0.as0;
			
			return fold_recur_15__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* fold-recur<a, k, v>.lambda0 void(cur void, child node<str, str>) */
struct void_ fold_recur_15__lambda0(struct ctx* ctx, struct fold_recur_15__lambda0* _closure, struct void_ cur, struct node_1 child) {
	return fold_recur_15(ctx, cur, child, _closure->f);
}
/* fold-recur<a, k, v>.lambda1 void(cur void, pair arrow<str, str>) */
struct void_ fold_recur_15__lambda1(struct ctx* ctx, struct fold_recur_15__lambda1* _closure, struct void_ cur, struct arrow_1 pair) {
	return subscript_78(ctx, _closure->f, cur, pair.from, pair.to);
}
/* each<str, str>.lambda0 void(ignore void, key str, value str) */
struct void_ each_9__lambda0(struct ctx* ctx, struct each_9__lambda0* _closure, struct void_ ignore, struct str key, struct str value) {
	return subscript_80(ctx, _closure->f, key, value);
}
/* ~=<const-ptr<char>> void(a mut-arr<const-ptr<char>>, value const-ptr<char>) */
struct void_ _concatEquals_11(struct ctx* ctx, struct mut_arr_7* a, char* value) {
	incr_capacity__e_5(ctx, a);
	uint64_t _0 = capacity_6(a);
	uint8_t _1 = _less_0(a->size, _0);
	assert_0(ctx, _1);
	char** _2 = begin_ptr_19(a);
	set_subscript_23(_2, a->size, value);
	uint64_t _3 = _plus_3(ctx, a->size, 1u);
	return (a->size = _3, (struct void_) {});
}
/* incr-capacity!<a> void(a mut-arr<const-ptr<char>>) */
struct void_ incr_capacity__e_5(struct ctx* ctx, struct mut_arr_7* a) {
	uint64_t _0 = _plus_3(ctx, a->size, 1u);
	uint64_t _1 = round_up_to_power_of_two(ctx, _0);
	return ensure_capacity_5(ctx, a, _1);
}
/* ensure-capacity<a> void(a mut-arr<const-ptr<char>>, min-capacity nat64) */
struct void_ ensure_capacity_5(struct ctx* ctx, struct mut_arr_7* a, uint64_t min_capacity) {
	uint64_t _0 = capacity_6(a);
	uint8_t _1 = _less_0(_0, min_capacity);
	if (_1) {
		return increase_capacity_to__e_5(ctx, a, min_capacity);
	} else {
		return (struct void_) {};
	}
}
/* capacity<a> nat64(a mut-arr<const-ptr<char>>) */
uint64_t capacity_6(struct mut_arr_7* a) {
	return size_14(a->backing);
}
/* size<a> nat64(a fix-arr<const-ptr<char>>) */
uint64_t size_14(struct fix_arr_13 a) {
	return a.inner.size;
}
/* increase-capacity-to!<a> void(a mut-arr<const-ptr<char>>, new-capacity nat64) */
struct void_ increase_capacity_to__e_5(struct ctx* ctx, struct mut_arr_7* a, uint64_t new_capacity) {
	uint64_t _0 = capacity_6(a);
	uint8_t _1 = _greater(new_capacity, _0);
	assert_0(ctx, _1);
	char** old_begin0;
	old_begin0 = begin_ptr_19(a);
	
	struct fix_arr_13 _2 = uninitialized_fix_arr_11(ctx, new_capacity);
	a->backing = _2;
	char** _3 = begin_ptr_19(a);
	copy_data_from__e_8(ctx, _3, ((char**) old_begin0), a->size);
	uint64_t _4 = _plus_3(ctx, a->size, 1u);
	uint64_t _5 = size_14(a->backing);
	struct range _6 = _range(ctx, _4, _5);
	struct fix_arr_13 _7 = subscript_123(ctx, a->backing, _6);
	return set_zero_elements_5(_7);
}
/* begin-ptr<a> mut-ptr<const-ptr<char>>(a mut-arr<const-ptr<char>>) */
char** begin_ptr_19(struct mut_arr_7* a) {
	return begin_ptr_20(a->backing);
}
/* begin-ptr<a> mut-ptr<const-ptr<char>>(a fix-arr<const-ptr<char>>) */
char** begin_ptr_20(struct fix_arr_13 a) {
	return ((char**) a.inner.begin_ptr);
}
/* uninitialized-fix-arr<a> fix-arr<const-ptr<char>>(size nat64) */
struct fix_arr_13 uninitialized_fix_arr_11(struct ctx* ctx, uint64_t size) {
	char** _0 = alloc_uninitialized_11(ctx, size);
	return fix_arr_26(size, _0);
}
/* fix-arr<a> fix-arr<const-ptr<char>>(size nat64, begin-ptr mut-ptr<const-ptr<char>>) */
struct fix_arr_13 fix_arr_26(uint64_t size, char** begin_ptr) {
	return (struct fix_arr_13) {(struct void_) {}, (struct arr_7) {size, ((char**) begin_ptr)}};
}
/* set-zero-elements<a> void(a fix-arr<const-ptr<char>>) */
struct void_ set_zero_elements_5(struct fix_arr_13 a) {
	char** _0 = begin_ptr_20(a);
	uint64_t _1 = size_14(a);
	return set_zero_range_6(_0, _1);
}
/* set-zero-range<a> void(begin mut-ptr<const-ptr<char>>, size nat64) */
struct void_ set_zero_range_6(char** begin, uint64_t size) {
	uint8_t* _0 = memset(((uint8_t*) begin), 0, (size * sizeof(char*)));
	return drop_0(_0);
}
/* subscript<a> fix-arr<const-ptr<char>>(a fix-arr<const-ptr<char>>, range range<nat64>) */
struct fix_arr_13 subscript_123(struct ctx* ctx, struct fix_arr_13 a, struct range range) {
	struct arr_7 _0 = subscript_17(ctx, a.inner, range);
	return (struct fix_arr_13) {(struct void_) {}, _0};
}
/* convert-environ.lambda0 void(key str, value str) */
struct void_ convert_environ__lambda0(struct ctx* ctx, struct convert_environ__lambda0* _closure, struct str key, struct str value) {
	struct str _0 = _tilde_0(ctx, key, (struct str) {{1, constantarr_0_59}});
	struct str _1 = _tilde_0(ctx, _0, value);
	char* _2 = to_c_str(ctx, _1);
	return _concatEquals_11(ctx, _closure->res, _2);
}
/* move-to-arr!<const-ptr<char>> arr<const-ptr<char>>(a mut-arr<const-ptr<char>>) */
struct arr_7 move_to_arr__e_4(struct mut_arr_7* a) {
	struct fix_arr_13 _0 = move_to_fix_arr__e_4(a);
	return cast_immutable_8(_0);
}
/* cast-immutable<a> arr<const-ptr<char>>(a fix-arr<const-ptr<char>>) */
struct arr_7 cast_immutable_8(struct fix_arr_13 a) {
	return a.inner;
}
/* move-to-fix-arr!<a> fix-arr<const-ptr<char>>(a mut-arr<const-ptr<char>>) */
struct fix_arr_13 move_to_fix_arr__e_4(struct mut_arr_7* a) {
	struct fix_arr_13 res0;
	char** _0 = begin_ptr_19(a);
	res0 = fix_arr_26(a->size, _0);
	
	struct fix_arr_13 _1 = fix_arr_25();
	a->backing = _1;
	a->size = 0u;
	return res0;
}
/* throw<process-result> process-result(message str) */
struct process_result* throw_12(struct ctx* ctx, struct str message) {
	struct backtrace _0 = get_backtrace(ctx);
	return throw_13(ctx, (struct exception) {message, _0});
}
/* throw<a> process-result(e exception) */
struct process_result* throw_13(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx0;
	exn_ctx0 = get_exception_ctx(ctx);
	
	uint8_t _0 = _notEqual_3(exn_ctx0->jmp_buf_ptr, NULL);
	hard_assert(_0);
	exn_ctx0->thrown_exception = e;
	int32_t _1 = number_to_throw(ctx);
	(longjmp(exn_ctx0->jmp_buf_ptr, _1), (struct void_) {});
	return hard_unreachable_7();
}
/* hard-unreachable<a> process-result() */
struct process_result* hard_unreachable_7(void) {
	(abort(), (struct void_) {});
	return NULL;
}
/* handle-output arr<failure>(original-path str, output-path str, actual str, overwrite-output bool) */
struct arr_15 handle_output(struct ctx* ctx, struct str original_path, struct str output_path, struct str actual, uint8_t overwrite_output) {
	struct opt_16 _0 = try_read_file_0(ctx, output_path);
	switch (_0.kind) {
		case 0: {
			uint8_t _1 = overwrite_output;
			if (_1) {
				write_file_0(ctx, output_path, actual);
				return (struct arr_15) {0u, NULL};
			} else {
				struct failure** temp0;
				uint8_t* _2 = alloc(ctx, (sizeof(struct failure*) * 1u));
				temp0 = ((struct failure**) _2);
				
				struct failure* temp1;
				uint8_t* _3 = alloc(ctx, sizeof(struct failure));
				temp1 = ((struct failure*) _3);
				
				struct interp _4 = interp(ctx);
				struct str _5 = base_name(ctx, output_path);
				struct interp _6 = with_value_0(ctx, _4, _5);
				struct interp _7 = with_str(ctx, _6, (struct str) {{29, constantarr_0_68}});
				struct interp _8 = with_value_0(ctx, _7, actual);
				struct str _9 = finish(ctx, _8);
				*temp1 = (struct failure) {original_path, _9};
				*(temp0 + 0u) = temp1;
				return (struct arr_15) {1u, temp0};
			}
		}
		case 1: {
			struct some_16 _matched0 = _0.as1;
			
			struct str text1;
			text1 = _matched0.value;
			
			uint8_t _10 = _equal_5(text1, actual);
			if (_10) {
				return (struct arr_15) {0u, NULL};
			} else {
				uint8_t _11 = overwrite_output;
				if (_11) {
					write_file_0(ctx, output_path, actual);
					return (struct arr_15) {0u, NULL};
				} else {
					struct str message2;
					struct interp _12 = interp(ctx);
					struct str _13 = base_name(ctx, output_path);
					struct interp _14 = with_value_0(ctx, _12, _13);
					struct interp _15 = with_str(ctx, _14, (struct str) {{30, constantarr_0_69}});
					struct interp _16 = with_value_0(ctx, _15, actual);
					message2 = finish(ctx, _16);
					
					struct failure** temp2;
					uint8_t* _17 = alloc(ctx, (sizeof(struct failure*) * 1u));
					temp2 = ((struct failure**) _17);
					
					struct failure* temp3;
					uint8_t* _18 = alloc(ctx, sizeof(struct failure));
					temp3 = ((struct failure*) _18);
					
					*temp3 = (struct failure) {original_path, message2};
					*(temp2 + 0u) = temp3;
					return (struct arr_15) {1u, temp2};
				}
			}
		}
		default:
			
	return (struct arr_15) {0, NULL};;
	}
}
/* try-read-file opt<str>(path str) */
struct opt_16 try_read_file_0(struct ctx* ctx, struct str path) {
	char* _0 = to_c_str(ctx, path);
	return try_read_file_1(ctx, _0);
}
/* try-read-file opt<str>(path const-ptr<char>) */
struct opt_16 try_read_file_1(struct ctx* ctx, char* path) {
	uint8_t _0 = is_file_1(ctx, path);
	if (_0) {
		int32_t fd0;
		int32_t _1 = O_RDONLY();
		fd0 = open(path, _1, 0u);
		
		uint8_t _2 = (fd0 == -1);
		if (_2) {
			int32_t _3 = errno();
			int32_t _4 = ENOENT();
			uint8_t _5 = _notEqual_6(_3, _4);
			if (_5) {
				struct interp _6 = interp(ctx);
				struct interp _7 = with_str(ctx, _6, (struct str) {{20, constantarr_0_63}});
				struct interp _8 = with_value_1(ctx, _7, path);
				struct str _9 = finish(ctx, _8);
				print(_9);
				return todo_6();
			} else {
				return (struct opt_16) {0, .as0 = (struct none) {}};
			}
		} else {
			int64_t file_size1;
			int32_t _10 = seek_end(ctx);
			file_size1 = lseek(fd0, 0, _10);
			
			forbid(ctx, (file_size1 == -1));
			uint8_t _11 = _less_6(file_size1, 1000000000);
			assert_0(ctx, _11);
			uint8_t _12 = (file_size1 == 0);
			if (_12) {
				return (struct opt_16) {1, .as1 = (struct some_16) {(struct str) {{0u, NULL}}}};
			} else {
				int64_t off2;
				int32_t _13 = seek_set(ctx);
				off2 = lseek(fd0, 0, _13);
				
				assert_0(ctx, (off2 == 0));
				uint64_t file_size_nat3;
				file_size_nat3 = to_nat64_0(ctx, file_size1);
				
				struct fix_arr_1 res4;
				res4 = uninitialized_fix_arr_0(ctx, file_size_nat3);
				
				int64_t n_bytes_read5;
				char* _14 = begin_ptr_1(res4);
				n_bytes_read5 = read(fd0, ((uint8_t*) _14), file_size_nat3);
				
				forbid(ctx, (n_bytes_read5 == -1));
				assert_0(ctx, (n_bytes_read5 == file_size1));
				int32_t _15 = close(fd0);
				check_posix_error(ctx, _15);
				struct arr_0 _16 = cast_immutable_0(res4);
				return (struct opt_16) {1, .as1 = (struct some_16) {(struct str) {_16}}};
			}
		}
	} else {
		return (struct opt_16) {0, .as0 = (struct none) {}};
	}
}
/* O_RDONLY int32() */
int32_t O_RDONLY(void) {
	return 0;
}
/* todo<opt<str>> opt<str>() */
struct opt_16 todo_6(void) {
	(abort(), (struct void_) {});
	return (struct opt_16) {0};
}
/* seek-end int32() */
int32_t seek_end(struct ctx* ctx) {
	return 2;
}
/* seek-set int32() */
int32_t seek_set(struct ctx* ctx) {
	return 0;
}
/* write-file void(path str, content str) */
struct void_ write_file_0(struct ctx* ctx, struct str path, struct str content) {
	char* _0 = to_c_str(ctx, path);
	return write_file_1(ctx, _0, content);
}
/* write-file void(path const-ptr<char>, content str) */
struct void_ write_file_1(struct ctx* ctx, char* path, struct str content) {
	uint32_t permission0;
	uint32_t _0 = _shiftLeft(6u, 6u);
	uint32_t _1 = _shiftLeft(4u, 3u);
	permission0 = ((_0 | _1) | 4u);
	
	int32_t flags1;
	int32_t _2 = O_CREAT();
	int32_t _3 = O_WRONLY();
	int32_t _4 = O_TRUNC();
	flags1 = ((_2 | _3) | _4);
	
	int32_t fd2;
	fd2 = open(path, flags1, permission0);
	
	uint8_t _5 = (fd2 == -1);
	if (_5) {
		struct interp _6 = interp(ctx);
		struct interp _7 = with_str(ctx, _6, (struct str) {{31, constantarr_0_64}});
		struct interp _8 = with_value_1(ctx, _7, path);
		struct str _9 = finish(ctx, _8);
		print(_9);
		struct interp _10 = interp(ctx);
		struct interp _11 = with_str(ctx, _10, (struct str) {{7, constantarr_0_65}});
		int32_t _12 = errno();
		struct interp _13 = with_value_2(ctx, _11, _12);
		struct str _14 = finish(ctx, _13);
		print(_14);
		struct interp _15 = interp(ctx);
		struct interp _16 = with_str(ctx, _15, (struct str) {{7, constantarr_0_66}});
		struct interp _17 = with_value_2(ctx, _16, flags1);
		struct str _18 = finish(ctx, _17);
		print(_18);
		struct interp _19 = interp(ctx);
		struct interp _20 = with_str(ctx, _19, (struct str) {{12, constantarr_0_67}});
		struct interp _21 = with_value_3(ctx, _20, permission0);
		struct str _22 = finish(ctx, _21);
		print(_22);
		return todo_0();
	} else {
		int64_t wrote_bytes3;
		uint8_t* _23 = ptr_cast_2(content.chars.begin_ptr);
		uint64_t _24 = size_bytes(content);
		wrote_bytes3 = write(fd2, _23, _24);
		
		uint64_t _25 = size_bytes(content);
		int64_t _26 = to_int64(ctx, _25);
		uint8_t _27 = _notEqual_1(wrote_bytes3, _26);
		if (_27) {
			uint8_t _28 = (wrote_bytes3 == -1);
			if (_28) {
				todo_0();
			} else {
				todo_0();
			}
		} else {
			(struct void_) {};
		}
		int32_t err4;
		err4 = close(fd2);
		
		uint8_t _29 = _notEqual_6(err4, 0);
		if (_29) {
			return todo_0();
		} else {
			return (struct void_) {};
		}
	}
}
/* << nat32(a nat32, b nat32) */
uint32_t _shiftLeft(uint32_t a, uint32_t b) {
	uint8_t _0 = _less_8(b, 32u);
	if (_0) {
		return ((uint32_t) (((uint64_t) a) << ((uint64_t) b)));
	} else {
		return 0u;
	}
}
/* <=> comparison(a nat32, b nat32) */
struct comparison _compare_13(uint32_t a, uint32_t b) {
	return cmp_4(a, b);
}
/* cmp<nat32> comparison(a nat32, b nat32) */
struct comparison cmp_4(uint32_t a, uint32_t b) {
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
/* <<nat32> bool(a nat32, b nat32) */
uint8_t _less_8(uint32_t a, uint32_t b) {
	struct comparison _0 = _compare_13(a, b);
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
/* O_CREAT int32() */
int32_t O_CREAT(void) {
	return 64;
}
/* O_WRONLY int32() */
int32_t O_WRONLY(void) {
	return 1;
}
/* O_TRUNC int32() */
int32_t O_TRUNC(void) {
	return 512;
}
/* to-str str(a nat32) */
struct str to_str_7(struct ctx* ctx, uint32_t a) {
	return to_str_6(ctx, ((uint64_t) a));
}
/* with-value<nat32> interp(a interp, b nat32) */
struct interp with_value_3(struct ctx* ctx, struct interp a, uint32_t b) {
	struct str _0 = to_str_7(ctx, b);
	return with_str(ctx, a, _0);
}
/* ptr-cast<nat8, char> const-ptr<nat8>(a const-ptr<char>) */
uint8_t* ptr_cast_2(char* a) {
	return ((uint8_t*) ((uint8_t*) ((char*) a)));
}
/* to-int64 int64(a nat64) */
int64_t to_int64(struct ctx* ctx, uint64_t a) {
	int64_t _0 = max_int64();
	uint64_t _1 = to_nat64_0(ctx, _0);
	uint8_t _2 = _less_0(a, _1);
	assert_0(ctx, _2);
	return ((int64_t) a);
}
/* max-int64 int64() */
int64_t max_int64(void) {
	return 9223372036854775807;
}
/* is-empty<failure> bool(a arr<failure>) */
uint8_t is_empty_21(struct arr_15 a) {
	return (a.size == 0u);
}
/* remove-colors str(s str) */
struct str remove_colors(struct ctx* ctx, struct str s) {
	struct writer res0;
	res0 = writer(ctx);
	
	remove_colors_recur__e(ctx, s, res0);
	return move_to_str__e(ctx, res0);
}
/* remove-colors-recur! void(s str, out writer) */
struct void_ remove_colors_recur__e(struct ctx* ctx, struct str s, struct writer out) {
	top:;
	uint8_t _0 = is_empty_0(s);
	if (_0) {
		return (struct void_) {};
	} else {
		struct opt_16 _1 = try_remove_start_0(ctx, s, (struct str) {{1, constantarr_0_70}});
		switch (_1.kind) {
			case 0: {
				char _2 = subscript_70(ctx, s.chars, 0u);
				_concatEquals_12(ctx, out, _2);
				struct arr_0 _3 = tail_6(ctx, s.chars);
				s = (struct str) {_3};
				out = out;
				goto top;
			}
			case 1: {
				struct some_16 _matched0 = _1.as1;
				
				struct str rest1;
				rest1 = _matched0.value;
				
				return remove_colors_recur_2__e(ctx, rest1, out);
			}
			default:
				
		return (struct void_) {};;
		}
	}
}
/* ~= void(a writer, b char) */
struct void_ _concatEquals_12(struct ctx* ctx, struct writer a, char b) {
	return _concatEquals_2(ctx, a.chars, b);
}
/* tail<char> arr<char>(a arr<char>) */
struct arr_0 tail_6(struct ctx* ctx, struct arr_0 a) {
	uint8_t _0 = is_empty_1(a);
	forbid(ctx, _0);
	struct range _1 = _range(ctx, 1u, a.size);
	return subscript_4(ctx, a, _1);
}
/* remove-colors-recur-2! void(s str, out writer) */
struct void_ remove_colors_recur_2__e(struct ctx* ctx, struct str s, struct writer out) {
	top:;
	uint8_t _0 = is_empty_0(s);
	if (_0) {
		return (struct void_) {};
	} else {
		struct opt_16 _1 = try_remove_start_0(ctx, s, (struct str) {{1, constantarr_0_71}});
		switch (_1.kind) {
			case 0: {
				struct arr_0 _2 = tail_6(ctx, s.chars);
				s = (struct str) {_2};
				out = out;
				goto top;
			}
			case 1: {
				struct some_16 _matched0 = _1.as1;
				
				struct str rest1;
				rest1 = _matched0.value;
				
				return remove_colors_recur__e(ctx, rest1, out);
			}
			default:
				
		return (struct void_) {};;
		}
	}
}
/* run-single-crow-test.lambda0 opt<arr<failure>>(print-kind str) */
struct opt_24 run_single_crow_test__lambda0(struct ctx* ctx, struct run_single_crow_test__lambda0* _closure, struct str print_kind) {
	uint8_t _0 = _closure->options->print_tests;
	if (_0) {
		struct interp _1 = interp(ctx);
		struct interp _2 = with_str(ctx, _1, (struct str) {{11, constantarr_0_36}});
		struct interp _3 = with_value_0(ctx, _2, print_kind);
		struct interp _4 = with_str(ctx, _3, (struct str) {{1, constantarr_0_37}});
		struct interp _5 = with_value_0(ctx, _4, _closure->path);
		struct str _6 = finish(ctx, _5);
		print(_6);
	} else {
		(struct void_) {};
	}
	struct print_test_result* res0;
	res0 = run_print_test(ctx, print_kind, _closure->path_to_crow, _closure->env, _closure->path, _closure->options->overwrite_output);
	
	uint8_t _7 = res0->should_stop;
	if (_7) {
		return (struct opt_24) {1, .as1 = (struct some_24) {res0->failures}};
	} else {
		return (struct opt_24) {0, .as0 = (struct none) {}};
	}
}
/* run-single-runnable-test arr<failure>(path-to-crow str, env dict<str, str>, path str, interpret bool, overwrite-output bool) */
struct arr_15 run_single_runnable_test(struct ctx* ctx, struct str path_to_crow, struct dict_1 env, struct str path, uint8_t interpret, uint8_t overwrite_output) {
	struct arr_2 args0;
	uint8_t _0 = interpret;
	if (_0) {
		struct str* temp0;
		uint8_t* _1 = alloc(ctx, (sizeof(struct str) * 3u));
		temp0 = ((struct str*) _1);
		
		*(temp0 + 0u) = (struct str) {{3, constantarr_0_75}};
		*(temp0 + 1u) = path;
		*(temp0 + 2u) = (struct str) {{11, constantarr_0_76}};
		args0 = (struct arr_2) {3u, temp0};
	} else {
		struct str* temp1;
		uint8_t* _2 = alloc(ctx, (sizeof(struct str) * 4u));
		temp1 = ((struct str*) _2);
		
		*(temp1 + 0u) = (struct str) {{3, constantarr_0_75}};
		*(temp1 + 1u) = path;
		*(temp1 + 2u) = (struct str) {{5, constantarr_0_77}};
		struct interp _3 = interp(ctx);
		struct interp _4 = with_value_0(ctx, _3, path);
		struct interp _5 = with_str(ctx, _4, (struct str) {{2, constantarr_0_78}});
		struct str _6 = finish(ctx, _5);
		*(temp1 + 3u) = _6;
		args0 = (struct arr_2) {4u, temp1};
	}
	
	struct process_result* res1;
	res1 = spawn_and_wait_result_0(ctx, path_to_crow, args0, env);
	
	struct arr_15 stdout_failures2;
	struct interp _7 = interp(ctx);
	struct interp _8 = with_value_0(ctx, _7, path);
	struct interp _9 = with_str(ctx, _8, (struct str) {{7, constantarr_0_79}});
	struct str _10 = finish(ctx, _9);
	stdout_failures2 = handle_output(ctx, path, _10, res1->stdout, overwrite_output);
	
	struct arr_15 stderr_failures3;uint8_t _11;
	
	if ((res1->exit_code == 0)) {
		_11 = _equal_5(res1->stderr, (struct str) {{0u, NULL}});
	} else {
		_11 = 0;
	}
	if (_11) {
		stderr_failures3 = (struct arr_15) {0u, NULL};
	} else {
		struct interp _12 = interp(ctx);
		struct interp _13 = with_value_0(ctx, _12, path);
		struct interp _14 = with_str(ctx, _13, (struct str) {{7, constantarr_0_80}});
		struct str _15 = finish(ctx, _14);
		stderr_failures3 = handle_output(ctx, path, _15, res1->stderr, overwrite_output);
	}
	
	return _tilde_9(ctx, stdout_failures2, stderr_failures3);
}
/* ~<failure> arr<failure>(a arr<failure>, b arr<failure>) */
struct arr_15 _tilde_9(struct ctx* ctx, struct arr_15 a, struct arr_15 b) {
	uint64_t res_size0;
	res_size0 = (a.size + b.size);
	
	struct failure** res1;
	res1 = alloc_uninitialized_9(ctx, res_size0);
	
	copy_data_from__e_7(ctx, res1, a.begin_ptr, a.size);
	copy_data_from__e_7(ctx, (res1 + a.size), b.begin_ptr, b.size);
	return (struct arr_15) {res_size0, ((struct failure**) res1)};
}
/* run-crow-tests.lambda0 arr<failure>(test str) */
struct arr_15 run_crow_tests__lambda0(struct ctx* ctx, struct run_crow_tests__lambda0* _closure, struct str test) {
	return run_single_crow_test(ctx, _closure->path_to_crow, _closure->env, test, _closure->options);
}
/* with-value<nat64> interp(a interp, b nat64) */
struct interp with_value_4(struct ctx* ctx, struct interp a, uint64_t b) {
	struct str _0 = to_str_6(ctx, b);
	return with_str(ctx, a, _0);
}
/* do-test.lambda0.lambda0 result<str, arr<failure>>() */
struct result_2 do_test__lambda0__lambda0(struct ctx* ctx, struct do_test__lambda0__lambda0* _closure) {
	struct str _0 = child_path(ctx, _closure->test_path, (struct str) {{8, constantarr_0_85}});
	return run_crow_tests(ctx, _0, _closure->crow_exe, _closure->env, _closure->options);
}
/* do-test.lambda0 result<str, arr<failure>>() */
struct result_2 do_test__lambda0(struct ctx* ctx, struct do_test__lambda0* _closure) {
	struct str _0 = child_path(ctx, _closure->test_path, (struct str) {{14, constantarr_0_84}});
	struct result_2 _1 = run_crow_tests(ctx, _0, _closure->crow_exe, _closure->env, _closure->options);
	struct do_test__lambda0__lambda0* temp0;
	uint8_t* _2 = alloc(ctx, sizeof(struct do_test__lambda0__lambda0));
	temp0 = ((struct do_test__lambda0__lambda0*) _2);
	
	*temp0 = (struct do_test__lambda0__lambda0) {_closure->test_path, _closure->crow_exe, _closure->env, _closure->options};
	return first_failures(ctx, _1, (struct fun0) {0, .as0 = temp0});
}
/* lint result<str, arr<failure>>(path str, options test-options) */
struct result_2 lint(struct ctx* ctx, struct str path, struct test_options* options) {
	struct arr_2 files0;
	files0 = list_lintable_files(ctx, path);
	
	struct arr_15 failures1;
	struct lint__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct lint__lambda0));
	temp0 = ((struct lint__lambda0*) _0);
	
	*temp0 = (struct lint__lambda0) {options};
	failures1 = flat_map_with_max_size(ctx, files0, options->max_failures, (struct fun_act1_27) {1, .as1 = temp0});
	
	uint8_t _1 = is_empty_21(failures1);
	if (_1) {
		struct interp _2 = interp(ctx);
		struct interp _3 = with_str(ctx, _2, (struct str) {{7, constantarr_0_114}});
		struct interp _4 = with_value_4(ctx, _3, files0.size);
		struct interp _5 = with_str(ctx, _4, (struct str) {{6, constantarr_0_115}});
		struct str _6 = finish(ctx, _5);
		return (struct result_2) {0, .as0 = (struct ok_2) {_6}};
	} else {
		return (struct result_2) {1, .as1 = (struct err_1) {failures1}};
	}
}
/* list-lintable-files arr<str>(path str) */
struct arr_2 list_lintable_files(struct ctx* ctx, struct str path) {
	struct mut_arr_5* res0;
	res0 = mut_arr_5(ctx);
	
	struct list_lintable_files__lambda1* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct list_lintable_files__lambda1));
	temp0 = ((struct list_lintable_files__lambda1*) _0);
	
	*temp0 = (struct list_lintable_files__lambda1) {res0};
	each_child_recursive_1(ctx, path, (struct fun_act1_8) {5, .as5 = (struct void_) {}}, (struct fun_act1_26) {3, .as3 = temp0});
	return move_to_arr__e_2(res0);
}
/* excluded-from-lint bool(name str) */
uint8_t excluded_from_lint(struct ctx* ctx, struct str name) {
	uint8_t _0 = starts_with_0(ctx, name, (struct str) {{1, constantarr_0_30}});uint8_t _1;
	
	if (_0) {
		_1 = 1;
	} else {
		_1 = in_2(name, (struct arr_2) {5, constantarr_2_3});
	}
	if (_1) {
		return 1;
	} else {
		struct excluded_from_lint__lambda0* temp0;
		uint8_t* _2 = alloc(ctx, sizeof(struct excluded_from_lint__lambda0));
		temp0 = ((struct excluded_from_lint__lambda0*) _2);
		
		*temp0 = (struct excluded_from_lint__lambda0) {name};
		return exists(ctx, (struct arr_2) {11, constantarr_2_2}, (struct fun_act1_8) {4, .as4 = temp0});
	}
}
/* in<str> bool(value str, a arr<str>) */
uint8_t in_2(struct str value, struct arr_2 a) {
	return in_recur_1(value, a, 0u);
}
/* in-recur<a> bool(value str, a arr<str>, i nat64) */
uint8_t in_recur_1(struct str value, struct arr_2 a, uint64_t i) {
	top:;
	uint8_t _0 = (i == a.size);
	if (_0) {
		return 0;
	} else {
		struct str _1 = noctx_at_2(a, i);
		uint8_t _2 = _equal_5(_1, value);
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
/* noctx-at<a> str(a arr<str>, index nat64) */
struct str noctx_at_2(struct arr_2 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	hard_assert(_0);
	return unsafe_at_3(a, index);
}
/* exists<str> bool(a arr<str>, f fun-act1<bool, str>) */
uint8_t exists(struct ctx* ctx, struct arr_2 a, struct fun_act1_8 f) {
	top:;
	uint8_t _0 = is_empty_7(a);
	if (_0) {
		return 0;
	} else {
		struct str _1 = subscript_26(ctx, a, 0u);
		uint8_t _2 = subscript_25(ctx, f, _1);
		if (_2) {
			return 1;
		} else {
			struct arr_2 _3 = tail_3(ctx, a);
			a = _3;
			f = f;
			goto top;
		}
	}
}
/* ends-with bool(a str, b str) */
uint8_t ends_with_0(struct ctx* ctx, struct str a, struct str b) {
	return ends_with_1(ctx, a.chars, b.chars);
}
/* ends-with<char> bool(a arr<char>, end arr<char>) */
uint8_t ends_with_1(struct ctx* ctx, struct arr_0 a, struct arr_0 end) {
	uint8_t _0 = _greaterOrEqual(a.size, end.size);
	if (_0) {
		uint64_t _1 = _minus_5(ctx, a.size, end.size);
		struct range _2 = _range(ctx, _1, a.size);
		struct arr_0 _3 = subscript_4(ctx, a, _2);
		return _equal_4(_3, end);
	} else {
		return 0;
	}
}
/* excluded-from-lint.lambda0 bool(ext str) */
uint8_t excluded_from_lint__lambda0(struct ctx* ctx, struct excluded_from_lint__lambda0* _closure, struct str ext) {
	return ends_with_0(ctx, _closure->name, ext);
}
/* list-lintable-files.lambda0 bool(child str) */
uint8_t list_lintable_files__lambda0(struct ctx* ctx, struct void_ _closure, struct str child) {
	uint8_t _0 = excluded_from_lint(ctx, child);
	return _not(_0);
}
/* should-ignore-extension-of-name bool(name str) */
uint8_t should_ignore_extension_of_name(struct ctx* ctx, struct str name) {
	struct opt_16 _0 = get_extension(ctx, name);
	switch (_0.kind) {
		case 0: {
			return 1;
		}
		case 1: {
			struct some_16 _matched0 = _0.as1;
			
			struct str ext1;
			ext1 = _matched0.value;
			
			return should_ignore_extension(ctx, ext1);
		}
		default:
			
	return 0;;
	}
}
/* should-ignore-extension bool(ext str) */
uint8_t should_ignore_extension(struct ctx* ctx, struct str ext) {
	struct arr_2 _0 = ignored_extensions(ctx);
	return in_2(ext, _0);
}
/* ignored-extensions arr<str>() */
struct arr_2 ignored_extensions(struct ctx* ctx) {
	return (struct arr_2) {6, constantarr_2_4};
}
/* list-lintable-files.lambda1 void(child str) */
struct void_ list_lintable_files__lambda1(struct ctx* ctx, struct list_lintable_files__lambda1* _closure, struct str child) {
	struct str _0 = base_name(ctx, child);
	uint8_t _1 = should_ignore_extension_of_name(ctx, _0);
	uint8_t _2 = _not(_1);
	if (_2) {
		return _concatEquals_8(ctx, _closure->res, child);
	} else {
		return (struct void_) {};
	}
}
/* lint-file arr<failure>(path str) */
struct arr_15 lint_file(struct ctx* ctx, struct str path) {
	struct str text0;
	text0 = read_file(ctx, path);
	
	struct mut_arr_6* res1;
	res1 = mut_arr_6(ctx);
	
	struct str ext2;
	struct opt_16 _0 = get_extension(ctx, path);
	ext2 = force_2(ctx, _0);
	
	uint8_t allow_double_space3;
	uint8_t _1 = _equal_5(ext2, (struct str) {{3, constantarr_0_107}});
	if (_1) {
		allow_double_space3 = 1;
	} else {
		allow_double_space3 = _equal_5(ext2, (struct str) {{14, constantarr_0_108}});
	}
	
	struct arr_2 _2 = lines(ctx, text0);
	struct lint_file__lambda0* temp0;
	uint8_t* _3 = alloc(ctx, sizeof(struct lint_file__lambda0));
	temp0 = ((struct lint_file__lambda0*) _3);
	
	*temp0 = (struct lint_file__lambda0) {allow_double_space3, res1, path};
	each_with_index_0(ctx, _2, (struct fun_act2_21) {0, .as0 = temp0});
	return move_to_arr__e_3(res1);
}
/* read-file str(path str) */
struct str read_file(struct ctx* ctx, struct str path) {
	struct opt_16 _0 = try_read_file_0(ctx, path);
	switch (_0.kind) {
		case 0: {
			struct interp _1 = interp(ctx);
			struct interp _2 = with_str(ctx, _1, (struct str) {{21, constantarr_0_106}});
			struct interp _3 = with_value_0(ctx, _2, path);
			struct str _4 = finish(ctx, _3);
			print(_4);
			return (struct str) {{0u, NULL}};
		}
		case 1: {
			struct some_16 _matched0 = _0.as1;
			
			struct str res1;
			res1 = _matched0.value;
			
			return res1;
		}
		default:
			
	return (struct str) {(struct arr_0) {0, NULL}};;
	}
}
/* each-with-index<str> void(a arr<str>, f fun-act2<void, str, nat64>) */
struct void_ each_with_index_0(struct ctx* ctx, struct arr_2 a, struct fun_act2_21 f) {
	return each_with_index_recur_0(ctx, a, f, 0u);
}
/* each-with-index-recur<a> void(a arr<str>, f fun-act2<void, str, nat64>, n nat64) */
struct void_ each_with_index_recur_0(struct ctx* ctx, struct arr_2 a, struct fun_act2_21 f, uint64_t n) {
	top:;
	uint8_t _0 = _notEqual_5(n, a.size);
	if (_0) {
		struct str _1 = subscript_26(ctx, a, n);
		subscript_124(ctx, f, _1, n);
		uint64_t _2 = _plus_3(ctx, n, 1u);
		a = a;
		f = f;
		n = _2;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* subscript<void, a, nat64> void(a fun-act2<void, str, nat64>, p0 str, p1 nat64) */
struct void_ subscript_124(struct ctx* ctx, struct fun_act2_21 a, struct str p0, uint64_t p1) {
	return call_w_ctx_1388(a, ctx, p0, p1);
}
/* call-w-ctx<void, str, nat-64> (generated) (generated) */
struct void_ call_w_ctx_1388(struct fun_act2_21 a, struct ctx* ctx, struct str p0, uint64_t p1) {
	struct fun_act2_21 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct lint_file__lambda0* closure0 = _0.as0;
			
			return lint_file__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* lines arr<str>(s str) */
struct arr_2 lines(struct ctx* ctx, struct str s) {
	struct mut_arr_5* res0;
	res0 = mut_arr_5(ctx);
	
	struct cell_0* last_nl1;
	struct cell_0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct cell_0));
	temp0 = ((struct cell_0*) _0);
	
	*temp0 = (struct cell_0) {0u};
	last_nl1 = temp0;
	
	struct lines__lambda0* temp1;
	uint8_t* _1 = alloc(ctx, sizeof(struct lines__lambda0));
	temp1 = ((struct lines__lambda0*) _1);
	
	*temp1 = (struct lines__lambda0) {last_nl1, res0, s};
	each_with_index_1(ctx, s.chars, (struct fun_act2_22) {0, .as0 = temp1});
	uint64_t _2 = _times_24(last_nl1);
	uint64_t _3 = size_bytes(s);
	struct range _4 = _range(ctx, _2, _3);
	struct arr_0 _5 = subscript_4(ctx, s.chars, _4);
	_concatEquals_8(ctx, res0, (struct str) {_5});
	return move_to_arr__e_2(res0);
}
/* each-with-index<char> void(a arr<char>, f fun-act2<void, char, nat64>) */
struct void_ each_with_index_1(struct ctx* ctx, struct arr_0 a, struct fun_act2_22 f) {
	return each_with_index_recur_1(ctx, a, f, 0u);
}
/* each-with-index-recur<a> void(a arr<char>, f fun-act2<void, char, nat64>, n nat64) */
struct void_ each_with_index_recur_1(struct ctx* ctx, struct arr_0 a, struct fun_act2_22 f, uint64_t n) {
	top:;
	uint8_t _0 = _notEqual_5(n, a.size);
	if (_0) {
		char _1 = subscript_70(ctx, a, n);
		subscript_125(ctx, f, _1, n);
		uint64_t _2 = _plus_3(ctx, n, 1u);
		a = a;
		f = f;
		n = _2;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* subscript<void, a, nat64> void(a fun-act2<void, char, nat64>, p0 char, p1 nat64) */
struct void_ subscript_125(struct ctx* ctx, struct fun_act2_22 a, char p0, uint64_t p1) {
	return call_w_ctx_1393(a, ctx, p0, p1);
}
/* call-w-ctx<void, char, nat-64> (generated) (generated) */
struct void_ call_w_ctx_1393(struct fun_act2_22 a, struct ctx* ctx, char p0, uint64_t p1) {
	struct fun_act2_22 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct lines__lambda0* closure0 = _0.as0;
			
			return lines__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* swap<nat64> nat64(c cell<nat64>, v nat64) */
uint64_t swap(struct cell_0* c, uint64_t v) {
	uint64_t res0;
	res0 = _times_24(c);
	
	set_deref_1(c, v);
	return res0;
}
/* *<a> nat64(a cell<nat64>) */
uint64_t _times_24(struct cell_0* a) {
	return a->inner_value;
}
/* set-deref<a> void(a cell<nat64>, value nat64) */
struct void_ set_deref_1(struct cell_0* a, uint64_t value) {
	return (a->inner_value = value, (struct void_) {});
}
/* lines.lambda0 void(c char, index nat64) */
struct void_ lines__lambda0(struct ctx* ctx, struct lines__lambda0* _closure, char c, uint64_t index) {
	uint8_t _0 = _equal_3(c, 10u);
	if (_0) {
		uint64_t nl0;
		uint64_t _1 = _plus_3(ctx, index, 1u);
		nl0 = swap(_closure->last_nl, _1);
		
		struct range _2 = _range(ctx, nl0, index);
		struct arr_0 _3 = subscript_4(ctx, _closure->s.chars, _2);
		return _concatEquals_8(ctx, _closure->res, (struct str) {_3});
	} else {
		return (struct void_) {};
	}
}
/* line-len nat64(line str) */
uint64_t line_len(struct ctx* ctx, struct str line) {
	uint64_t _0 = n_tabs(ctx, line);
	uint64_t _1 = tab_size(ctx);
	uint64_t _2 = _minus_5(ctx, _1, 1u);
	uint64_t _3 = _times_3(ctx, _0, _2);
	uint64_t _4 = size_bytes(line);
	return _plus_3(ctx, _3, _4);
}
/* n-tabs nat64(line str) */
uint64_t n_tabs(struct ctx* ctx, struct str line) {
	struct opt_16 _0 = try_remove_start_0(ctx, line, (struct str) {{1, constantarr_0_111}});
	switch (_0.kind) {
		case 0: {
			return 0u;
		}
		case 1: {
			struct some_16 _matched0 = _0.as1;
			
			struct str rest1;
			rest1 = _matched0.value;
			
			uint64_t _1 = n_tabs(ctx, rest1);
			return _plus_3(ctx, _1, 1u);
		}
		default:
			
	return 0;;
	}
}
/* tab-size nat64() */
uint64_t tab_size(struct ctx* ctx) {
	return 4u;
}
/* max-line-length nat64() */
uint64_t max_line_length(struct ctx* ctx) {
	return 120u;
}
/* lint-file.lambda0 void(line str, line-num nat64) */
struct void_ lint_file__lambda0(struct ctx* ctx, struct lint_file__lambda0* _closure, struct str line, uint64_t line_num) {
	struct str ln0;
	uint64_t _0 = _plus_3(ctx, line_num, 1u);
	ln0 = to_str_6(ctx, _0);
	
	struct str space_space1;
	space_space1 = _tilde_0(ctx, (struct str) {{1, constantarr_0_37}}, (struct str) {{1, constantarr_0_37}});
	
	uint8_t _1 = _not(_closure->allow_double_space);uint8_t _2;
	
	if (_1) {
		_2 = has_substr(ctx, line, space_space1);
	} else {
		_2 = 0;
	}
	if (_2) {
		struct str message2;
		struct interp _3 = interp(ctx);
		struct interp _4 = with_str(ctx, _3, (struct str) {{5, constantarr_0_109}});
		struct interp _5 = with_value_0(ctx, _4, ln0);
		struct interp _6 = with_str(ctx, _5, (struct str) {{24, constantarr_0_110}});
		message2 = finish(ctx, _6);
		
		struct failure* temp0;
		uint8_t* _7 = alloc(ctx, sizeof(struct failure));
		temp0 = ((struct failure*) _7);
		
		*temp0 = (struct failure) {_closure->path, message2};
		_concatEquals_10(ctx, _closure->res, temp0);
	} else {
		(struct void_) {};
	}
	uint64_t width3;
	width3 = line_len(ctx, line);
	
	uint64_t _8 = max_line_length(ctx);
	uint8_t _9 = _greater(width3, _8);
	if (_9) {
		struct str message4;
		struct interp _10 = interp(ctx);
		struct interp _11 = with_str(ctx, _10, (struct str) {{5, constantarr_0_109}});
		struct interp _12 = with_value_0(ctx, _11, ln0);
		struct interp _13 = with_str(ctx, _12, (struct str) {{4, constantarr_0_112}});
		struct interp _14 = with_value_4(ctx, _13, width3);
		struct interp _15 = with_str(ctx, _14, (struct str) {{28, constantarr_0_113}});
		uint64_t _16 = max_line_length(ctx);
		struct interp _17 = with_value_4(ctx, _15, _16);
		message4 = finish(ctx, _17);
		
		struct failure* temp1;
		uint8_t* _18 = alloc(ctx, sizeof(struct failure));
		temp1 = ((struct failure*) _18);
		
		*temp1 = (struct failure) {_closure->path, message4};
		return _concatEquals_10(ctx, _closure->res, temp1);
	} else {
		return (struct void_) {};
	}
}
/* lint.lambda0 arr<failure>(file str) */
struct arr_15 lint__lambda0(struct ctx* ctx, struct lint__lambda0* _closure, struct str file) {
	uint8_t _0 = _closure->options->print_tests;
	if (_0) {
		struct interp _1 = interp(ctx);
		struct interp _2 = with_str(ctx, _1, (struct str) {{5, constantarr_0_105}});
		struct interp _3 = with_value_0(ctx, _2, file);
		struct str _4 = finish(ctx, _3);
		print(_4);
	} else {
		(struct void_) {};
	}
	return lint_file(ctx, file);
}
/* do-test.lambda1 result<str, arr<failure>>() */
struct result_2 do_test__lambda1(struct ctx* ctx, struct do_test__lambda1* _closure) {
	return lint(ctx, _closure->crow_path, _closure->options);
}
/* print-failures nat64(failures result<str, arr<failure>>, options test-options) */
uint64_t print_failures(struct ctx* ctx, struct result_2 failures, struct test_options* options) {
	struct result_2 _0 = failures;
	switch (_0.kind) {
		case 0: {
			struct ok_2 o0 = _0.as0;
			
			print(o0.value);
			return 0u;
		}
		case 1: {
			struct err_1 e1 = _0.as1;
			
			each_8(ctx, e1.value, (struct fun_act1_28) {1, .as1 = (struct void_) {}});
			uint64_t n_failures2;
			n_failures2 = e1.value.size;
			
			uint8_t _1 = (n_failures2 == options->max_failures);struct str _2;
			
			if (_1) {
				struct interp _3 = interp(ctx);
				struct interp _4 = with_str(ctx, _3, (struct str) {{15, constantarr_0_118}});
				struct interp _5 = with_value_4(ctx, _4, options->max_failures);
				struct interp _6 = with_str(ctx, _5, (struct str) {{9, constantarr_0_119}});
				_2 = finish(ctx, _6);
			} else {
				struct interp _7 = interp(ctx);
				struct interp _8 = with_value_4(ctx, _7, n_failures2);
				struct interp _9 = with_str(ctx, _8, (struct str) {{9, constantarr_0_119}});
				_2 = finish(ctx, _9);
			}
			print(_2);
			return n_failures2;
		}
		default:
			
	return 0;;
	}
}
/* print-failure void(failure failure) */
struct void_ print_failure(struct ctx* ctx, struct failure* failure) {
	print_bold(ctx);
	print_no_newline(failure->path);
	print_reset(ctx);
	print_no_newline((struct str) {{1, constantarr_0_37}});
	return print(failure->message);
}
/* print-bold void() */
struct void_ print_bold(struct ctx* ctx) {
	return print_no_newline((struct str) {{4, constantarr_0_116}});
}
/* print-reset void() */
struct void_ print_reset(struct ctx* ctx) {
	return print_no_newline((struct str) {{3, constantarr_0_117}});
}
/* print-failures.lambda0 void(failure failure) */
struct void_ print_failures__lambda0(struct ctx* ctx, struct void_ _closure, struct failure* failure) {
	return print_failure(ctx, failure);
}
/* main (generated) (generated) */
int32_t main(int32_t argc, char** argv) {
	return rt_main(argc, argv, main_0);
}
