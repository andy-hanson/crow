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
struct mut_list_0;
struct mut_arr_0;
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
struct mut_list_1;
struct mut_arr_1 {
	struct void_ ignore;
	struct arr_0 inner;
};
struct _concatEquals_1__lambda0 {
	struct mut_list_1* a;
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
struct arrow_0 {
	uint64_t from;
	uint64_t to;
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
struct mut_arr_2;
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
struct overlay_0;
struct arrow_1;
struct arr_9 {
	uint64_t size;
	struct arrow_1* begin_ptr;
};
struct end_node_0;
struct arrow_2;
struct arr_10 {
	uint64_t size;
	struct arrow_2* begin_ptr;
};
struct mut_arr_3 {
	struct void_ ignore;
	struct arr_10 inner;
};
struct mut_arr_4__lambda0 {
	struct arr_10 a;
};
struct sort_by_0__lambda0;
struct mut_dict_0;
struct mut_list_2;
struct mut_arr_4 {
	struct void_ ignore;
	struct arr_9 inner;
};
struct some_14 {
	struct mut_dict_0* value;
};
struct some_15;
struct some_16 {
	struct arr_0 value;
};
struct find_insert_ptr_0__lambda0;
struct map_to_mut_arr_0__lambda0;
struct map_to_arr_0__lambda0;
struct mut_list_3;
struct mut_arr_5;
struct fill_mut_arr__lambda0;
struct cell_3 {
	uint8_t inner_value;
};
struct iters_0;
struct mut_arr_6;
struct arr_11 {
	uint64_t size;
	struct arr_9* begin_ptr;
};
struct fold_recur_0__lambda0;
struct took_key_0;
struct each_2__lambda0;
struct parse_named_args_0__lambda0 {
	struct arr_2 arg_names;
	struct mut_list_3* values;
	struct cell_3* help;
};
struct some_17 {
	struct str* value;
};
struct interp {
	struct mut_list_1* inner;
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
struct overlay_1;
struct arrow_3;
struct arr_12 {
	uint64_t size;
	struct arrow_3* begin_ptr;
};
struct end_node_1;
struct arrow_4;
struct arr_13 {
	uint64_t size;
	struct arrow_4* begin_ptr;
};
struct mut_dict_1;
struct mut_list_4;
struct mut_arr_7 {
	struct void_ ignore;
	struct arr_12 inner;
};
struct some_18 {
	struct mut_dict_1* value;
};
struct find_insert_ptr_1__lambda0;
struct mut_arr_8 {
	struct void_ ignore;
	struct arr_13 inner;
};
struct mut_arr_13__lambda0 {
	struct arr_13 a;
};
struct sort_by_1__lambda0;
struct map_to_mut_arr_1__lambda0;
struct map_to_arr_2__lambda0;
struct failure;
struct arr_14 {
	uint64_t size;
	struct failure** begin_ptr;
};
struct ok_2;
struct err_1 {
	struct arr_14 value;
};
struct mut_list_5;
struct mut_arr_9 {
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
struct some_19 {
	struct stat* value;
};
struct dirent;
struct bytes256;
struct cell_4 {
	struct dirent* inner_value;
};
struct mut_arr_17__lambda0 {
	struct arr_2 a;
};
struct each_child_recursive_1__lambda0;
struct list_tests__lambda0;
struct some_20 {
	char value;
};
struct mut_list_6;
struct mut_arr_10 {
	struct void_ ignore;
	struct arr_14 inner;
};
struct flat_map_with_max_size__lambda0;
struct _concatEquals_7__lambda0 {
	struct mut_list_6* a;
};
struct some_21 {
	struct failure* value;
};
struct run_crow_tests__lambda0;
struct some_22 {
	struct arr_14 value;
};
struct run_single_crow_test__lambda0;
struct print_test_result {
	uint8_t should_stop;
	struct arr_14 failures;
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
struct mut_arr_11;
struct arr_15 {
	uint64_t size;
	struct pollfd* begin_ptr;
};
struct mut_arr_20__lambda0 {
	struct arr_15 a;
};
struct handle_revents_result {
	uint8_t had_POLLIN;
	uint8_t hung_up;
};
struct map_1__lambda0;
struct mut_list_7;
struct mut_arr_12 {
	struct void_ ignore;
	struct arr_7 inner;
};
struct iters_1;
struct mut_arr_13;
struct arr_16 {
	uint64_t size;
	struct arr_12* begin_ptr;
};
struct fold_recur_4__lambda0;
struct took_key_1;
struct each_5__lambda0;
struct convert_environ__lambda0 {
	struct mut_list_7* res;
};
struct do_test__lambda0;
struct do_test__lambda0__lambda0;
struct do_test__lambda1;
struct excluded_from_lint__lambda0;
struct list_lintable_files__lambda1 {
	struct mut_list_5* res;
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
		struct mut_arr_17__lambda0* as1;
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
struct dict_impl_0;
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
		struct void_ as0;
		uint64_t __ensureSizeIs16;
	};
};
struct fun_act2_1 {
	uint64_t kind;
	union {
		struct sort_by_0__lambda0* as0;
	};
};
struct fun_act1_10 {
	uint64_t kind;
	union {
		struct mut_arr_4__lambda0* as0;
		struct map_to_mut_arr_0__lambda0* as1;
	};
};
struct opt_14 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_14 as1;
	};
};
struct opt_15;
struct opt_16 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_16 as1;
	};
};
struct fun_act1_11 {
	uint64_t kind;
	union {
		struct find_insert_ptr_0__lambda0* as0;
	};
};
struct fun_act1_12 {
	uint64_t kind;
	union {
		struct void_ as0;
		uint64_t __ensureSizeIs16;
	};
};
struct unique_comparison {
	uint64_t kind;
	union {
		struct less as0;
		struct greater as1;
	};
};
struct fun_act2_2 {
	uint64_t kind;
	union {
		struct void_ as0;
		uint64_t __ensureSizeIs16;
	};
};
struct fun_act2_3 {
	uint64_t kind;
	union {
		struct void_ as0;
		uint64_t __ensureSizeIs16;
	};
};
struct fun_act1_13 {
	uint64_t kind;
	union {
		struct map_to_arr_0__lambda0* as0;
	};
};
struct fun_act1_14 {
	uint64_t kind;
	union {
		struct fill_mut_arr__lambda0* as0;
	};
};
struct fun_act2_4 {
	uint64_t kind;
	union {
		struct parse_named_args_0__lambda0* as0;
	};
};
struct fun_act3_0 {
	uint64_t kind;
	union {
		struct each_2__lambda0* as0;
	};
};
struct fun_act2_5 {
	uint64_t kind;
	union {
		struct fold_recur_0__lambda0* as0;
	};
};
struct fun_act2_6 {
	uint64_t kind;
	union {
		struct void_ as0;
		uint64_t __ensureSizeIs16;
	};
};
struct opt_17 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_17 as1;
	};
};
struct fun_act1_15 {
	uint64_t kind;
	union {
		struct void_ as0;
		uint64_t __ensureSizeIs16;
	};
};
struct fun_act1_16 {
	uint64_t kind;
	union {
		struct r_index_of__lambda0* as0;
	};
};
struct dict_impl_1;
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
		struct find_insert_ptr_1__lambda0* as0;
	};
};
struct fun_act1_18 {
	uint64_t kind;
	union {
		struct void_ as0;
		uint64_t __ensureSizeIs16;
	};
};
struct fun_act2_7 {
	uint64_t kind;
	union {
		struct void_ as0;
		uint64_t __ensureSizeIs16;
	};
};
struct fun_act1_19 {
	uint64_t kind;
	union {
		struct void_ as0;
		uint64_t __ensureSizeIs16;
	};
};
struct fun_act2_8 {
	uint64_t kind;
	union {
		struct sort_by_1__lambda0* as0;
	};
};
struct fun_act1_20 {
	uint64_t kind;
	union {
		struct mut_arr_13__lambda0* as0;
		struct map_to_mut_arr_1__lambda0* as1;
	};
};
struct fun_act2_9 {
	uint64_t kind;
	union {
		struct void_ as0;
		uint64_t __ensureSizeIs16;
	};
};
struct fun_act1_21 {
	uint64_t kind;
	union {
		struct map_to_arr_2__lambda0* as0;
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
struct fun_act1_22 {
	uint64_t kind;
	union {
		struct each_child_recursive_1__lambda0* as0;
		struct list_tests__lambda0* as1;
		struct flat_map_with_max_size__lambda0* as2;
		struct list_lintable_files__lambda1* as3;
	};
};
struct opt_19 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_19 as1;
	};
};
struct fun_act2_10 {
	uint64_t kind;
	union {
		struct void_ as0;
		uint64_t __ensureSizeIs16;
	};
};
struct opt_20 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_20 as1;
	};
};
struct fun_act1_23 {
	uint64_t kind;
	union {
		struct run_crow_tests__lambda0* as0;
		struct lint__lambda0* as1;
	};
};
struct fun_act1_24 {
	uint64_t kind;
	union {
		struct _concatEquals_7__lambda0* as0;
		struct void_ as1;
	};
};
struct opt_21 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_21 as1;
	};
};
struct opt_22 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_22 as1;
	};
};
struct fun_act1_25 {
	uint64_t kind;
	union {
		struct run_single_crow_test__lambda0* as0;
	};
};
struct fun_act2_11 {
	uint64_t kind;
	union {
		struct void_ as0;
		uint64_t __ensureSizeIs16;
	};
};
struct fun_act1_26 {
	uint64_t kind;
	union {
		struct mut_arr_20__lambda0* as0;
	};
};
struct fun_act1_27 {
	uint64_t kind;
	union {
		struct void_ as0;
		uint64_t __ensureSizeIs16;
	};
};
struct fun_act1_28 {
	uint64_t kind;
	union {
		struct map_1__lambda0* as0;
	};
};
struct fun_act2_12 {
	uint64_t kind;
	union {
		struct convert_environ__lambda0* as0;
	};
};
struct fun_act3_1 {
	uint64_t kind;
	union {
		struct each_5__lambda0* as0;
	};
};
struct fun_act2_13 {
	uint64_t kind;
	union {
		struct fold_recur_4__lambda0* as0;
	};
};
struct fun_act2_14 {
	uint64_t kind;
	union {
		struct void_ as0;
		uint64_t __ensureSizeIs16;
	};
};
struct fun_act2_15 {
	uint64_t kind;
	union {
		struct lint_file__lambda0* as0;
	};
};
struct fun_act2_16 {
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
struct mut_list_0;
struct mut_arr_0 {
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
	struct mut_list_1* chars;
};
struct mut_list_1 {
	struct mut_arr_1 backing;
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
struct mut_arr_2 {
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
struct overlay_0;
struct arrow_1 {
	struct str from;
	struct opt_12 to;
};
struct end_node_0 {
	struct arr_10 pairs;
};
struct arrow_2 {
	struct str from;
	struct arr_2 to;
};
struct sort_by_0__lambda0 {
	struct fun_act1_9 f;
};
struct mut_dict_0 {
	struct mut_list_2* pairs;
	uint64_t node_size;
	struct opt_14 next;
};
struct mut_list_2 {
	struct mut_arr_4 backing;
	uint64_t size;
};
struct some_15 {
	struct str value;
};
struct find_insert_ptr_0__lambda0 {
	struct str key;
};
struct map_to_mut_arr_0__lambda0 {
	struct fun_act1_13 f;
	struct mut_list_2* a;
};
struct map_to_arr_0__lambda0 {
	struct fun_act2_3 f;
};
struct mut_list_3;
struct mut_arr_5 {
	struct void_ ignore;
	struct arr_8 inner;
};
struct fill_mut_arr__lambda0 {
	struct opt_12 value;
};
struct iters_0;
struct mut_arr_6 {
	struct void_ ignore;
	struct arr_11 inner;
};
struct fold_recur_0__lambda0 {
	struct fun_act3_0 f;
};
struct took_key_0 {
	struct opt_12 rightmost_value;
	struct mut_arr_6 overlays;
};
struct each_2__lambda0 {
	struct fun_act2_4 f;
};
struct test_options {
	uint8_t print_tests;
	uint8_t overwrite_output;
	uint64_t max_failures;
	struct str match_test;
};
struct dict_1;
struct overlay_1;
struct arrow_3;
struct end_node_1 {
	struct arr_13 pairs;
};
struct arrow_4 {
	struct str from;
	struct str to;
};
struct mut_dict_1 {
	struct mut_list_4* pairs;
	uint64_t node_size;
	struct opt_18 next;
};
struct mut_list_4 {
	struct mut_arr_7 backing;
	uint64_t size;
};
struct find_insert_ptr_1__lambda0 {
	struct str key;
};
struct sort_by_1__lambda0 {
	struct fun_act1_19 f;
};
struct map_to_mut_arr_1__lambda0 {
	struct fun_act1_21 f;
	struct mut_list_4* a;
};
struct map_to_arr_2__lambda0 {
	struct fun_act2_9 f;
};
struct failure {
	struct str path;
	struct str message;
};
struct ok_2 {
	struct str value;
};
struct mut_list_5 {
	struct mut_arr_9 backing;
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
	struct fun_act1_22 f;
};
struct list_tests__lambda0 {
	struct str match_test;
	struct mut_list_5* res;
};
struct mut_list_6 {
	struct mut_arr_10 backing;
	uint64_t size;
};
struct flat_map_with_max_size__lambda0 {
	struct mut_list_6* res;
	uint64_t max_size;
	struct fun_act1_23 mapper;
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
struct mut_arr_11 {
	struct void_ ignore;
	struct arr_15 inner;
};
struct map_1__lambda0 {
	struct fun_act1_27 f;
	struct arr_2 a;
};
struct mut_list_7 {
	struct mut_arr_12 backing;
	uint64_t size;
};
struct iters_1;
struct mut_arr_13 {
	struct void_ ignore;
	struct arr_16 inner;
};
struct fold_recur_4__lambda0 {
	struct fun_act3_1 f;
};
struct took_key_1;
struct each_5__lambda0 {
	struct fun_act2_12 f;
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
	struct mut_list_5* res;
	struct str s;
};
struct lint_file__lambda0 {
	uint8_t allow_double_space;
	struct mut_list_6* res;
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
struct dict_impl_0 {
	uint64_t kind;
	union {
		struct overlay_0* as0;
		struct end_node_0 as1;
	};
};
struct opt_15 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_15 as1;
	};
};
struct dict_impl_1 {
	uint64_t kind;
	union {
		struct overlay_1* as0;
		struct end_node_1 as1;
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
	struct mut_arr_2 measure_values;
};
struct fut_1;
struct resolve_or_reject__e__lambda0;
struct chosen_task {
	struct island* task_island;
	struct task_or_gc task_or_gc;
};
struct parsed_command;
struct dict_0 {
	struct void_ ignore;
	struct dict_impl_0 impl;
};
struct overlay_0 {
	struct arr_9 pairs;
	struct dict_impl_0 prev;
};
struct mut_list_3 {
	struct mut_arr_5 backing;
	uint64_t size;
};
struct iters_0 {
	struct arr_10 end_pairs;
	struct mut_arr_6 overlays;
};
struct dict_1 {
	struct void_ ignore;
	struct dict_impl_1 impl;
};
struct overlay_1 {
	struct arr_12 pairs;
	struct dict_impl_1 prev;
};
struct arrow_3 {
	struct str from;
	struct opt_15 to;
};
struct dirent {
	uint64_t d_ino;
	int64_t d_off;
	uint16_t d_reclen;
	char d_type;
	struct bytes256 d_name;
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
struct iters_1 {
	struct arr_13 end_pairs;
	struct mut_arr_13 overlays;
};
struct took_key_1 {
	struct opt_15 rightmost_value;
	struct mut_arr_13 overlays;
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
struct fut_0 {
	struct lock lk;
	struct fut_state_0 state;
};
struct global_ctx;
struct island;
struct island_gc_root;
struct task_queue {
	struct opt_3 head;
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
struct parsed_command {
	struct arr_2 nameless;
	struct dict_0 named;
	struct arr_2 after;
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
_Static_assert(sizeof(struct mut_list_0) == 24, "");
_Static_assert(_Alignof(struct mut_list_0) == 8, "");
_Static_assert(sizeof(struct mut_arr_0) == 16, "");
_Static_assert(_Alignof(struct mut_arr_0) == 8, "");
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
_Static_assert(sizeof(struct mut_list_1) == 24, "");
_Static_assert(_Alignof(struct mut_list_1) == 8, "");
_Static_assert(sizeof(struct mut_arr_1) == 16, "");
_Static_assert(_Alignof(struct mut_arr_1) == 8, "");
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
_Static_assert(sizeof(struct arrow_0) == 16, "");
_Static_assert(_Alignof(struct arrow_0) == 8, "");
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
_Static_assert(sizeof(struct mut_arr_2) == 16, "");
_Static_assert(_Alignof(struct mut_arr_2) == 8, "");
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
_Static_assert(sizeof(struct overlay_0) == 40, "");
_Static_assert(_Alignof(struct overlay_0) == 8, "");
_Static_assert(sizeof(struct arrow_1) == 40, "");
_Static_assert(_Alignof(struct arrow_1) == 8, "");
_Static_assert(sizeof(struct arr_9) == 16, "");
_Static_assert(_Alignof(struct arr_9) == 8, "");
_Static_assert(sizeof(struct end_node_0) == 16, "");
_Static_assert(_Alignof(struct end_node_0) == 8, "");
_Static_assert(sizeof(struct arrow_2) == 32, "");
_Static_assert(_Alignof(struct arrow_2) == 8, "");
_Static_assert(sizeof(struct arr_10) == 16, "");
_Static_assert(_Alignof(struct arr_10) == 8, "");
_Static_assert(sizeof(struct mut_arr_3) == 16, "");
_Static_assert(_Alignof(struct mut_arr_3) == 8, "");
_Static_assert(sizeof(struct mut_arr_4__lambda0) == 16, "");
_Static_assert(_Alignof(struct mut_arr_4__lambda0) == 8, "");
_Static_assert(sizeof(struct sort_by_0__lambda0) == 16, "");
_Static_assert(_Alignof(struct sort_by_0__lambda0) == 8, "");
_Static_assert(sizeof(struct mut_dict_0) == 32, "");
_Static_assert(_Alignof(struct mut_dict_0) == 8, "");
_Static_assert(sizeof(struct mut_list_2) == 24, "");
_Static_assert(_Alignof(struct mut_list_2) == 8, "");
_Static_assert(sizeof(struct mut_arr_4) == 16, "");
_Static_assert(_Alignof(struct mut_arr_4) == 8, "");
_Static_assert(sizeof(struct some_14) == 8, "");
_Static_assert(_Alignof(struct some_14) == 8, "");
_Static_assert(sizeof(struct some_15) == 16, "");
_Static_assert(_Alignof(struct some_15) == 8, "");
_Static_assert(sizeof(struct some_16) == 16, "");
_Static_assert(_Alignof(struct some_16) == 8, "");
_Static_assert(sizeof(struct find_insert_ptr_0__lambda0) == 16, "");
_Static_assert(_Alignof(struct find_insert_ptr_0__lambda0) == 8, "");
_Static_assert(sizeof(struct map_to_mut_arr_0__lambda0) == 24, "");
_Static_assert(_Alignof(struct map_to_mut_arr_0__lambda0) == 8, "");
_Static_assert(sizeof(struct map_to_arr_0__lambda0) == 16, "");
_Static_assert(_Alignof(struct map_to_arr_0__lambda0) == 8, "");
_Static_assert(sizeof(struct mut_list_3) == 24, "");
_Static_assert(_Alignof(struct mut_list_3) == 8, "");
_Static_assert(sizeof(struct mut_arr_5) == 16, "");
_Static_assert(_Alignof(struct mut_arr_5) == 8, "");
_Static_assert(sizeof(struct fill_mut_arr__lambda0) == 24, "");
_Static_assert(_Alignof(struct fill_mut_arr__lambda0) == 8, "");
_Static_assert(sizeof(struct cell_3) == 1, "");
_Static_assert(_Alignof(struct cell_3) == 1, "");
_Static_assert(sizeof(struct iters_0) == 32, "");
_Static_assert(_Alignof(struct iters_0) == 8, "");
_Static_assert(sizeof(struct mut_arr_6) == 16, "");
_Static_assert(_Alignof(struct mut_arr_6) == 8, "");
_Static_assert(sizeof(struct arr_11) == 16, "");
_Static_assert(_Alignof(struct arr_11) == 8, "");
_Static_assert(sizeof(struct fold_recur_0__lambda0) == 16, "");
_Static_assert(_Alignof(struct fold_recur_0__lambda0) == 8, "");
_Static_assert(sizeof(struct took_key_0) == 40, "");
_Static_assert(_Alignof(struct took_key_0) == 8, "");
_Static_assert(sizeof(struct each_2__lambda0) == 16, "");
_Static_assert(_Alignof(struct each_2__lambda0) == 8, "");
_Static_assert(sizeof(struct parse_named_args_0__lambda0) == 32, "");
_Static_assert(_Alignof(struct parse_named_args_0__lambda0) == 8, "");
_Static_assert(sizeof(struct some_17) == 8, "");
_Static_assert(_Alignof(struct some_17) == 8, "");
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
_Static_assert(sizeof(struct overlay_1) == 40, "");
_Static_assert(_Alignof(struct overlay_1) == 8, "");
_Static_assert(sizeof(struct arrow_3) == 40, "");
_Static_assert(_Alignof(struct arrow_3) == 8, "");
_Static_assert(sizeof(struct arr_12) == 16, "");
_Static_assert(_Alignof(struct arr_12) == 8, "");
_Static_assert(sizeof(struct end_node_1) == 16, "");
_Static_assert(_Alignof(struct end_node_1) == 8, "");
_Static_assert(sizeof(struct arrow_4) == 32, "");
_Static_assert(_Alignof(struct arrow_4) == 8, "");
_Static_assert(sizeof(struct arr_13) == 16, "");
_Static_assert(_Alignof(struct arr_13) == 8, "");
_Static_assert(sizeof(struct mut_dict_1) == 32, "");
_Static_assert(_Alignof(struct mut_dict_1) == 8, "");
_Static_assert(sizeof(struct mut_list_4) == 24, "");
_Static_assert(_Alignof(struct mut_list_4) == 8, "");
_Static_assert(sizeof(struct mut_arr_7) == 16, "");
_Static_assert(_Alignof(struct mut_arr_7) == 8, "");
_Static_assert(sizeof(struct some_18) == 8, "");
_Static_assert(_Alignof(struct some_18) == 8, "");
_Static_assert(sizeof(struct find_insert_ptr_1__lambda0) == 16, "");
_Static_assert(_Alignof(struct find_insert_ptr_1__lambda0) == 8, "");
_Static_assert(sizeof(struct mut_arr_8) == 16, "");
_Static_assert(_Alignof(struct mut_arr_8) == 8, "");
_Static_assert(sizeof(struct mut_arr_13__lambda0) == 16, "");
_Static_assert(_Alignof(struct mut_arr_13__lambda0) == 8, "");
_Static_assert(sizeof(struct sort_by_1__lambda0) == 16, "");
_Static_assert(_Alignof(struct sort_by_1__lambda0) == 8, "");
_Static_assert(sizeof(struct map_to_mut_arr_1__lambda0) == 24, "");
_Static_assert(_Alignof(struct map_to_mut_arr_1__lambda0) == 8, "");
_Static_assert(sizeof(struct map_to_arr_2__lambda0) == 16, "");
_Static_assert(_Alignof(struct map_to_arr_2__lambda0) == 8, "");
_Static_assert(sizeof(struct failure) == 32, "");
_Static_assert(_Alignof(struct failure) == 8, "");
_Static_assert(sizeof(struct arr_14) == 16, "");
_Static_assert(_Alignof(struct arr_14) == 8, "");
_Static_assert(sizeof(struct ok_2) == 16, "");
_Static_assert(_Alignof(struct ok_2) == 8, "");
_Static_assert(sizeof(struct err_1) == 16, "");
_Static_assert(_Alignof(struct err_1) == 8, "");
_Static_assert(sizeof(struct mut_list_5) == 24, "");
_Static_assert(_Alignof(struct mut_list_5) == 8, "");
_Static_assert(sizeof(struct mut_arr_9) == 16, "");
_Static_assert(_Alignof(struct mut_arr_9) == 8, "");
_Static_assert(sizeof(struct stat) == 152, "");
_Static_assert(_Alignof(struct stat) == 8, "");
_Static_assert(sizeof(struct some_19) == 8, "");
_Static_assert(_Alignof(struct some_19) == 8, "");
_Static_assert(sizeof(struct dirent) == 280, "");
_Static_assert(_Alignof(struct dirent) == 8, "");
_Static_assert(sizeof(struct bytes256) == 256, "");
_Static_assert(_Alignof(struct bytes256) == 8, "");
_Static_assert(sizeof(struct cell_4) == 8, "");
_Static_assert(_Alignof(struct cell_4) == 8, "");
_Static_assert(sizeof(struct mut_arr_17__lambda0) == 16, "");
_Static_assert(_Alignof(struct mut_arr_17__lambda0) == 8, "");
_Static_assert(sizeof(struct each_child_recursive_1__lambda0) == 48, "");
_Static_assert(_Alignof(struct each_child_recursive_1__lambda0) == 8, "");
_Static_assert(sizeof(struct list_tests__lambda0) == 24, "");
_Static_assert(_Alignof(struct list_tests__lambda0) == 8, "");
_Static_assert(sizeof(struct some_20) == 1, "");
_Static_assert(_Alignof(struct some_20) == 1, "");
_Static_assert(sizeof(struct mut_list_6) == 24, "");
_Static_assert(_Alignof(struct mut_list_6) == 8, "");
_Static_assert(sizeof(struct mut_arr_10) == 16, "");
_Static_assert(_Alignof(struct mut_arr_10) == 8, "");
_Static_assert(sizeof(struct flat_map_with_max_size__lambda0) == 32, "");
_Static_assert(_Alignof(struct flat_map_with_max_size__lambda0) == 8, "");
_Static_assert(sizeof(struct _concatEquals_7__lambda0) == 8, "");
_Static_assert(_Alignof(struct _concatEquals_7__lambda0) == 8, "");
_Static_assert(sizeof(struct some_21) == 8, "");
_Static_assert(_Alignof(struct some_21) == 8, "");
_Static_assert(sizeof(struct run_crow_tests__lambda0) == 48, "");
_Static_assert(_Alignof(struct run_crow_tests__lambda0) == 8, "");
_Static_assert(sizeof(struct some_22) == 16, "");
_Static_assert(_Alignof(struct some_22) == 8, "");
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
_Static_assert(sizeof(struct mut_arr_11) == 16, "");
_Static_assert(_Alignof(struct mut_arr_11) == 8, "");
_Static_assert(sizeof(struct arr_15) == 16, "");
_Static_assert(_Alignof(struct arr_15) == 8, "");
_Static_assert(sizeof(struct mut_arr_20__lambda0) == 16, "");
_Static_assert(_Alignof(struct mut_arr_20__lambda0) == 8, "");
_Static_assert(sizeof(struct handle_revents_result) == 2, "");
_Static_assert(_Alignof(struct handle_revents_result) == 1, "");
_Static_assert(sizeof(struct map_1__lambda0) == 32, "");
_Static_assert(_Alignof(struct map_1__lambda0) == 8, "");
_Static_assert(sizeof(struct mut_list_7) == 24, "");
_Static_assert(_Alignof(struct mut_list_7) == 8, "");
_Static_assert(sizeof(struct mut_arr_12) == 16, "");
_Static_assert(_Alignof(struct mut_arr_12) == 8, "");
_Static_assert(sizeof(struct iters_1) == 32, "");
_Static_assert(_Alignof(struct iters_1) == 8, "");
_Static_assert(sizeof(struct mut_arr_13) == 16, "");
_Static_assert(_Alignof(struct mut_arr_13) == 8, "");
_Static_assert(sizeof(struct arr_16) == 16, "");
_Static_assert(_Alignof(struct arr_16) == 8, "");
_Static_assert(sizeof(struct fold_recur_4__lambda0) == 16, "");
_Static_assert(_Alignof(struct fold_recur_4__lambda0) == 8, "");
_Static_assert(sizeof(struct took_key_1) == 40, "");
_Static_assert(_Alignof(struct took_key_1) == 8, "");
_Static_assert(sizeof(struct each_5__lambda0) == 16, "");
_Static_assert(_Alignof(struct each_5__lambda0) == 8, "");
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
_Static_assert(sizeof(struct dict_impl_0) == 24, "");
_Static_assert(_Alignof(struct dict_impl_0) == 8, "");
_Static_assert(sizeof(struct fun_act1_8) == 16, "");
_Static_assert(_Alignof(struct fun_act1_8) == 8, "");
_Static_assert(sizeof(struct fun_act1_9) == 16, "");
_Static_assert(_Alignof(struct fun_act1_9) == 8, "");
_Static_assert(sizeof(struct fun_act2_1) == 16, "");
_Static_assert(_Alignof(struct fun_act2_1) == 8, "");
_Static_assert(sizeof(struct fun_act1_10) == 16, "");
_Static_assert(_Alignof(struct fun_act1_10) == 8, "");
_Static_assert(sizeof(struct opt_14) == 16, "");
_Static_assert(_Alignof(struct opt_14) == 8, "");
_Static_assert(sizeof(struct opt_15) == 24, "");
_Static_assert(_Alignof(struct opt_15) == 8, "");
_Static_assert(sizeof(struct opt_16) == 24, "");
_Static_assert(_Alignof(struct opt_16) == 8, "");
_Static_assert(sizeof(struct fun_act1_11) == 16, "");
_Static_assert(_Alignof(struct fun_act1_11) == 8, "");
_Static_assert(sizeof(struct fun_act1_12) == 16, "");
_Static_assert(_Alignof(struct fun_act1_12) == 8, "");
_Static_assert(sizeof(struct unique_comparison) == 8, "");
_Static_assert(_Alignof(struct unique_comparison) == 8, "");
_Static_assert(sizeof(struct fun_act2_2) == 16, "");
_Static_assert(_Alignof(struct fun_act2_2) == 8, "");
_Static_assert(sizeof(struct fun_act2_3) == 16, "");
_Static_assert(_Alignof(struct fun_act2_3) == 8, "");
_Static_assert(sizeof(struct fun_act1_13) == 16, "");
_Static_assert(_Alignof(struct fun_act1_13) == 8, "");
_Static_assert(sizeof(struct fun_act1_14) == 16, "");
_Static_assert(_Alignof(struct fun_act1_14) == 8, "");
_Static_assert(sizeof(struct fun_act2_4) == 16, "");
_Static_assert(_Alignof(struct fun_act2_4) == 8, "");
_Static_assert(sizeof(struct fun_act3_0) == 16, "");
_Static_assert(_Alignof(struct fun_act3_0) == 8, "");
_Static_assert(sizeof(struct fun_act2_5) == 16, "");
_Static_assert(_Alignof(struct fun_act2_5) == 8, "");
_Static_assert(sizeof(struct fun_act2_6) == 16, "");
_Static_assert(_Alignof(struct fun_act2_6) == 8, "");
_Static_assert(sizeof(struct opt_17) == 16, "");
_Static_assert(_Alignof(struct opt_17) == 8, "");
_Static_assert(sizeof(struct fun_act1_15) == 16, "");
_Static_assert(_Alignof(struct fun_act1_15) == 8, "");
_Static_assert(sizeof(struct fun_act1_16) == 16, "");
_Static_assert(_Alignof(struct fun_act1_16) == 8, "");
_Static_assert(sizeof(struct dict_impl_1) == 24, "");
_Static_assert(_Alignof(struct dict_impl_1) == 8, "");
_Static_assert(sizeof(struct opt_18) == 16, "");
_Static_assert(_Alignof(struct opt_18) == 8, "");
_Static_assert(sizeof(struct fun_act1_17) == 16, "");
_Static_assert(_Alignof(struct fun_act1_17) == 8, "");
_Static_assert(sizeof(struct fun_act1_18) == 16, "");
_Static_assert(_Alignof(struct fun_act1_18) == 8, "");
_Static_assert(sizeof(struct fun_act2_7) == 16, "");
_Static_assert(_Alignof(struct fun_act2_7) == 8, "");
_Static_assert(sizeof(struct fun_act1_19) == 16, "");
_Static_assert(_Alignof(struct fun_act1_19) == 8, "");
_Static_assert(sizeof(struct fun_act2_8) == 16, "");
_Static_assert(_Alignof(struct fun_act2_8) == 8, "");
_Static_assert(sizeof(struct fun_act1_20) == 16, "");
_Static_assert(_Alignof(struct fun_act1_20) == 8, "");
_Static_assert(sizeof(struct fun_act2_9) == 16, "");
_Static_assert(_Alignof(struct fun_act2_9) == 8, "");
_Static_assert(sizeof(struct fun_act1_21) == 16, "");
_Static_assert(_Alignof(struct fun_act1_21) == 8, "");
_Static_assert(sizeof(struct result_2) == 24, "");
_Static_assert(_Alignof(struct result_2) == 8, "");
_Static_assert(sizeof(struct fun0) == 16, "");
_Static_assert(_Alignof(struct fun0) == 8, "");
_Static_assert(sizeof(struct fun_act1_22) == 16, "");
_Static_assert(_Alignof(struct fun_act1_22) == 8, "");
_Static_assert(sizeof(struct opt_19) == 16, "");
_Static_assert(_Alignof(struct opt_19) == 8, "");
_Static_assert(sizeof(struct fun_act2_10) == 16, "");
_Static_assert(_Alignof(struct fun_act2_10) == 8, "");
_Static_assert(sizeof(struct opt_20) == 16, "");
_Static_assert(_Alignof(struct opt_20) == 8, "");
_Static_assert(sizeof(struct fun_act1_23) == 16, "");
_Static_assert(_Alignof(struct fun_act1_23) == 8, "");
_Static_assert(sizeof(struct fun_act1_24) == 16, "");
_Static_assert(_Alignof(struct fun_act1_24) == 8, "");
_Static_assert(sizeof(struct opt_21) == 16, "");
_Static_assert(_Alignof(struct opt_21) == 8, "");
_Static_assert(sizeof(struct opt_22) == 24, "");
_Static_assert(_Alignof(struct opt_22) == 8, "");
_Static_assert(sizeof(struct fun_act1_25) == 16, "");
_Static_assert(_Alignof(struct fun_act1_25) == 8, "");
_Static_assert(sizeof(struct fun_act2_11) == 16, "");
_Static_assert(_Alignof(struct fun_act2_11) == 8, "");
_Static_assert(sizeof(struct fun_act1_26) == 16, "");
_Static_assert(_Alignof(struct fun_act1_26) == 8, "");
_Static_assert(sizeof(struct fun_act1_27) == 16, "");
_Static_assert(_Alignof(struct fun_act1_27) == 8, "");
_Static_assert(sizeof(struct fun_act1_28) == 16, "");
_Static_assert(_Alignof(struct fun_act1_28) == 8, "");
_Static_assert(sizeof(struct fun_act2_12) == 16, "");
_Static_assert(_Alignof(struct fun_act2_12) == 8, "");
_Static_assert(sizeof(struct fun_act3_1) == 16, "");
_Static_assert(_Alignof(struct fun_act3_1) == 8, "");
_Static_assert(sizeof(struct fun_act2_13) == 16, "");
_Static_assert(_Alignof(struct fun_act2_13) == 8, "");
_Static_assert(sizeof(struct fun_act2_14) == 16, "");
_Static_assert(_Alignof(struct fun_act2_14) == 8, "");
_Static_assert(sizeof(struct fun_act2_15) == 16, "");
_Static_assert(_Alignof(struct fun_act2_15) == 8, "");
_Static_assert(sizeof(struct fun_act2_16) == 16, "");
_Static_assert(_Alignof(struct fun_act2_16) == 8, "");
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
uint8_t _greater_0(uint64_t a, uint64_t b);
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
struct mut_list_0 mut_list_by_val_with_capacity_from_unmanaged_memory(uint64_t capacity);
struct mut_arr_0 mut_arr_0(uint64_t size, uint64_t* begin_ptr);
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
struct mut_list_1* mut_list_0(struct ctx* ctx);
struct mut_arr_1 mut_arr_1(void);
struct void_ _concatEquals_0(struct ctx* ctx, struct writer a, struct str b);
struct void_ _concatEquals_1(struct ctx* ctx, struct mut_list_1* a, struct arr_0 values);
struct void_ each_0(struct ctx* ctx, struct arr_0 a, struct fun_act1_1 f);
struct void_ each_recur_0(struct ctx* ctx, char* cur, char* end, struct fun_act1_1 f);
uint8_t _equal_0(char* a, char* b);
uint8_t _notEqual_2(char* a, char* b);
struct void_ subscript_0(struct ctx* ctx, struct fun_act1_1 a, char p0);
struct void_ call_w_ctx_63(struct fun_act1_1 a, struct ctx* ctx, char p0);
char _times_0(char* a);
char* _plus_0(char* a, uint64_t offset);
char* end_ptr_0(struct arr_0 a);
struct void_ _concatEquals_2(struct ctx* ctx, struct mut_list_1* a, char value);
struct void_ incr_capacity__e_0(struct ctx* ctx, struct mut_list_1* a);
struct void_ ensure_capacity_0(struct ctx* ctx, struct mut_list_1* a, uint64_t min_capacity);
uint64_t capacity_0(struct mut_list_1* a);
uint64_t size_0(struct mut_arr_1 a);
struct void_ increase_capacity_to__e_0(struct ctx* ctx, struct mut_list_1* a, uint64_t new_capacity);
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
char* begin_ptr_0(struct mut_list_1* a);
char* begin_ptr_1(struct mut_arr_1 a);
struct mut_arr_1 uninitialized_mut_arr_0(struct ctx* ctx, uint64_t size);
struct mut_arr_1 mut_arr_2(uint64_t size, char* begin_ptr);
char* alloc_uninitialized_0(struct ctx* ctx, uint64_t size);
uint8_t* alloc(struct ctx* ctx, uint64_t size_bytes);
uint8_t* gc_alloc(struct ctx* ctx, struct gc* gc, uint64_t size);
uint8_t* todo_1(void);
struct void_ copy_data_from__e_1(struct ctx* ctx, char* to, char* from, uint64_t len);
struct void_ set_zero_elements_0(struct mut_arr_1 a);
struct void_ set_zero_range_1(char* begin, uint64_t size);
struct mut_arr_1 subscript_3(struct ctx* ctx, struct mut_arr_1 a, struct arrow_0 range);
struct arr_0 subscript_4(struct ctx* ctx, struct arr_0 a, struct arrow_0 range);
struct arrow_0 _arrow_0(uint64_t from, uint64_t to);
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
struct arr_0 arr_from_begin_end_0(char* begin, char* end);
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
struct arr_0 move_to_arr__e_0(struct mut_list_1* a);
struct arr_0 cast_immutable_0(struct mut_arr_1 a);
struct mut_arr_1 move_to_mut_arr__e_0(struct mut_list_1* a);
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
struct mut_arr_2 mut_arr_3(void);
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
struct arr_7 subscript_17(struct ctx* ctx, struct arr_7 a, struct arrow_0 range);
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
uint8_t in_0(uint64_t value, struct mut_list_0* a);
uint8_t in_1(uint64_t value, struct arr_3 a);
uint8_t in_recur_0(uint64_t value, struct arr_3 a, uint64_t i);
uint64_t noctx_at_1(struct arr_3 a, uint64_t index);
uint64_t unsafe_at_2(struct arr_3 a, uint64_t index);
uint64_t subscript_23(uint64_t* a, uint64_t n);
uint64_t _times_8(uint64_t* a);
uint64_t* _plus_7(uint64_t* a, uint64_t offset);
struct arr_3 temp_as_arr_0(struct mut_list_0* a);
struct arr_3 temp_as_arr_1(struct mut_arr_0 a);
struct mut_arr_0 temp_as_mut_arr_0(struct mut_list_0* a);
uint64_t* begin_ptr_2(struct mut_list_0* a);
uint64_t* begin_ptr_3(struct mut_arr_0 a);
struct pop_task_result pop_recur__e(struct task_queue_node* prev, struct mut_list_0* exclusions, uint64_t cur_time, struct opt_11 first_task_time);
struct opt_11 to_opt_time(uint64_t a);
struct void_ push_capacity_must_be_sufficient__e(struct mut_list_0* a, uint64_t value);
uint64_t capacity_1(struct mut_list_0* a);
uint64_t size_2(struct mut_arr_0 a);
struct void_ set_subscript_3(uint64_t* a, uint64_t n, uint64_t value);
uint8_t is_no_task(struct choose_task_in_island_result a);
struct opt_11 min_time(struct opt_11 a, struct opt_11 b);
uint64_t min_0(uint64_t a, uint64_t b);
struct void_ do_task(struct global_ctx* gctx, struct thread_local_stuff* tls, struct chosen_task chosen_task);
struct void_ return_task__e(struct task_queue* a, struct task task);
struct void_ noctx_must_remove_unordered__e(struct mut_list_0* a, uint64_t value);
struct void_ noctx_must_remove_unordered_recur__e(struct mut_list_0* a, uint64_t index, uint64_t value);
uint64_t subscript_24(uint64_t* a, uint64_t n);
struct void_ drop_1(uint64_t _p0);
uint64_t noctx_remove_unordered_at__e(struct mut_list_0* a, uint64_t index);
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
struct void_ mark_visit_417(struct mark_ctx* mark_ctx, struct mut_list_0 value);
struct void_ mark_visit_418(struct mark_ctx* mark_ctx, struct mut_arr_0 value);
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
struct opt_11 find_index(struct ctx* ctx, struct arr_2 a, struct fun_act1_8 f);
struct opt_11 find_index_recur(struct ctx* ctx, struct arr_2 a, uint64_t index, struct fun_act1_8 f);
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
struct dict_0 dict_0(struct ctx* ctx, struct arr_10 a);
struct arr_10 sort_by_0(struct ctx* ctx, struct arr_10 a, struct fun_act1_9 f);
struct arr_10 sort_0(struct ctx* ctx, struct arr_10 a, struct fun_act2_1 comparer);
struct mut_arr_3 mut_arr_4(struct ctx* ctx, struct arr_10 a);
struct mut_arr_3 make_mut_arr_0(struct ctx* ctx, uint64_t size, struct fun_act1_10 f);
struct mut_arr_3 uninitialized_mut_arr_1(struct ctx* ctx, uint64_t size);
struct mut_arr_3 mut_arr_5(uint64_t size, struct arrow_2* begin_ptr);
struct arrow_2* alloc_uninitialized_2(struct ctx* ctx, uint64_t size);
struct void_ fill_ptr_range_1(struct ctx* ctx, struct arrow_2* begin, uint64_t size, struct fun_act1_10 f);
struct void_ fill_ptr_range_recur_1(struct ctx* ctx, struct arrow_2* begin, uint64_t i, uint64_t size, struct fun_act1_10 f);
struct void_ set_subscript_4(struct arrow_2* a, uint64_t n, struct arrow_2 value);
struct arrow_2 subscript_28(struct ctx* ctx, struct fun_act1_10 a, uint64_t p0);
struct arrow_2 call_w_ctx_479(struct fun_act1_10 a, struct ctx* ctx, uint64_t p0);
struct arrow_2* begin_ptr_4(struct mut_arr_3 a);
struct arrow_2 subscript_29(struct ctx* ctx, struct arr_10 a, uint64_t index);
struct arrow_2 unsafe_at_4(struct arr_10 a, uint64_t index);
struct arrow_2 subscript_30(struct arrow_2* a, uint64_t n);
struct arrow_2 _times_11(struct arrow_2* a);
struct arrow_2* _plus_9(struct arrow_2* a, uint64_t offset);
struct arrow_2 mut_arr_4__lambda0(struct ctx* ctx, struct mut_arr_4__lambda0* _closure, uint64_t i);
struct void_ sort__e_1(struct ctx* ctx, struct mut_arr_3 a, struct fun_act2_1 comparer);
uint8_t is_empty_5(struct mut_arr_3 a);
uint64_t size_3(struct mut_arr_3 a);
struct void_ insertion_sort_recur__e_0(struct ctx* ctx, struct arrow_2* begin, struct arrow_2* cur, struct arrow_2* end, struct fun_act2_1 comparer);
uint8_t _notEqual_8(struct arrow_2* a, struct arrow_2* b);
struct void_ insert__e_0(struct ctx* ctx, struct arrow_2* begin, struct arrow_2* cur, struct arrow_2 value, struct fun_act2_1 comparer);
uint8_t _equal_6(struct comparison a, struct comparison b);
struct comparison subscript_31(struct ctx* ctx, struct fun_act2_1 a, struct arrow_2 p0, struct arrow_2 p1);
struct comparison call_w_ctx_495(struct fun_act2_1 a, struct ctx* ctx, struct arrow_2 p0, struct arrow_2 p1);
struct arrow_2* end_ptr_2(struct mut_arr_3 a);
struct arr_10 cast_immutable_1(struct mut_arr_3 a);
struct str subscript_32(struct ctx* ctx, struct fun_act1_9 a, struct arrow_2 p0);
struct str call_w_ctx_499(struct fun_act1_9 a, struct ctx* ctx, struct arrow_2 p0);
struct comparison sort_by_0__lambda0(struct ctx* ctx, struct sort_by_0__lambda0* _closure, struct arrow_2 x, struct arrow_2 y);
struct str dict_0__lambda0(struct ctx* ctx, struct void_ _closure, struct arrow_2 pair);
struct arr_2 subscript_33(struct ctx* ctx, struct arr_2 a, struct arrow_0 range);
uint8_t parse_command_dynamic__lambda1(struct ctx* ctx, struct void_ _closure, struct str arg);
struct dict_0 parse_named_args_1(struct ctx* ctx, struct arr_2 args);
struct mut_dict_0* mut_dict_0(struct ctx* ctx);
struct mut_list_2* mut_list_1(struct ctx* ctx);
struct mut_arr_4 mut_arr_6(void);
struct void_ parse_named_args_recur(struct ctx* ctx, struct arr_2 args, struct mut_dict_0* builder);
struct str force_0(struct ctx* ctx, struct opt_15 a);
struct str force_1(struct ctx* ctx, struct opt_15 a, struct str message);
struct str throw_2(struct ctx* ctx, struct str message);
struct str throw_3(struct ctx* ctx, struct exception e);
struct str hard_unreachable_2(void);
struct opt_15 try_remove_start_0(struct ctx* ctx, struct str a, struct str b);
struct opt_16 try_remove_start_1(struct ctx* ctx, struct arr_0 a, struct arr_0 start);
struct arr_2 tail_1(struct ctx* ctx, struct arr_2 a);
uint8_t is_empty_6(struct arr_2 a);
uint8_t parse_named_args_recur__lambda0(struct ctx* ctx, struct void_ _closure, struct str arg);
struct void_ set_subscript_5(struct ctx* ctx, struct mut_dict_0* a, struct str key, struct arr_2 value);
uint8_t insert_into_key_match_or_empty_slot__e_0(struct ctx* ctx, struct mut_dict_0* a, struct str key, struct arr_2 value);
struct arrow_1* find_insert_ptr_0(struct ctx* ctx, struct mut_dict_0* a, struct str key);
struct arrow_1* binary_search_insert_ptr_0(struct ctx* ctx, struct mut_list_2* a, struct fun_act1_11 compare);
struct arrow_1* binary_search_insert_ptr_1(struct ctx* ctx, struct mut_arr_4 a, struct fun_act1_11 compare);
struct arrow_1* binary_search_compare_recur_0(struct ctx* ctx, struct arrow_1* left, struct arrow_1* right, struct fun_act1_11 compare);
uint8_t _equal_7(struct arrow_1* a, struct arrow_1* b);
struct arrow_1* _plus_10(struct arrow_1* a, uint64_t offset);
uint64_t _minus_5(struct arrow_1* a, struct arrow_1* b);
uint64_t _minus_6(struct arrow_1* a, struct arrow_1* b);
struct comparison subscript_34(struct ctx* ctx, struct fun_act1_11 a, struct arrow_1 p0);
struct comparison call_w_ctx_530(struct fun_act1_11 a, struct ctx* ctx, struct arrow_1 p0);
struct arrow_1 _times_12(struct arrow_1* a);
struct arrow_1* begin_ptr_5(struct mut_arr_4 a);
struct arrow_1* end_ptr_3(struct mut_arr_4 a);
uint64_t size_4(struct mut_arr_4 a);
struct mut_arr_4 temp_as_mut_arr_1(struct mut_list_2* a);
struct mut_arr_4 mut_arr_7(uint64_t size, struct arrow_1* begin_ptr);
struct arrow_1* begin_ptr_6(struct mut_list_2* a);
struct comparison find_insert_ptr_0__lambda0(struct ctx* ctx, struct find_insert_ptr_0__lambda0* _closure, struct arrow_1 pair);
uint8_t _notEqual_9(struct arrow_1* a, struct arrow_1* b);
struct arrow_1* end_ptr_4(struct mut_list_2* a);
uint8_t is_empty_7(struct opt_12 a);
struct arrow_1 _arrow_1(struct str from, struct opt_12 to);
uint8_t _less_6(struct str a, struct str b);
struct void_ add_pair__e_0(struct ctx* ctx, struct mut_dict_0* a, struct str key, struct arr_2 value);
uint8_t is_empty_8(struct mut_list_2* a);
struct void_ _concatEquals_4(struct ctx* ctx, struct mut_list_2* a, struct arrow_1 value);
struct void_ incr_capacity__e_1(struct ctx* ctx, struct mut_list_2* a);
struct void_ ensure_capacity_1(struct ctx* ctx, struct mut_list_2* a, uint64_t min_capacity);
uint64_t capacity_2(struct mut_list_2* a);
struct void_ increase_capacity_to__e_1(struct ctx* ctx, struct mut_list_2* a, uint64_t new_capacity);
struct mut_arr_4 uninitialized_mut_arr_2(struct ctx* ctx, uint64_t size);
struct arrow_1* alloc_uninitialized_3(struct ctx* ctx, uint64_t size);
struct void_ copy_data_from__e_2(struct ctx* ctx, struct arrow_1* to, struct arrow_1* from, uint64_t len);
uint8_t* as_any_const_ptr_2(struct arrow_1* ref);
struct void_ set_zero_elements_1(struct mut_arr_4 a);
struct void_ set_zero_range_2(struct arrow_1* begin, uint64_t size);
struct mut_arr_4 subscript_35(struct ctx* ctx, struct mut_arr_4 a, struct arrow_0 range);
struct arr_9 subscript_36(struct ctx* ctx, struct arr_9 a, struct arrow_0 range);
struct void_ set_subscript_6(struct arrow_1* a, uint64_t n, struct arrow_1 value);
struct void_ insert_linear__e_0(struct ctx* ctx, struct mut_list_2* a, uint64_t index, struct str key, struct arr_2 value);
struct arrow_1 subscript_37(struct ctx* ctx, struct mut_list_2* a, uint64_t index);
struct arrow_1 subscript_38(struct arrow_1* a, uint64_t n);
struct void_ move_right__e_0(struct ctx* ctx, struct mut_list_2* a, uint64_t index);
uint64_t _minus_7(struct ctx* ctx, uint64_t a, uint64_t b);
struct void_ set_subscript_7(struct ctx* ctx, struct mut_list_2* a, uint64_t index, struct arrow_1 value);
uint8_t _greater_1(struct str a, struct str b);
struct void_ compact_if_needed__e_0(struct ctx* ctx, struct mut_dict_0* a);
uint64_t total_pairs_size_0(struct ctx* ctx, struct mut_dict_0* a);
uint64_t total_pairs_size_recur_0(struct ctx* ctx, uint64_t acc, struct mut_dict_0* a);
struct void_ compact__e_0(struct ctx* ctx, struct mut_dict_0* a);
struct void_ filter__e_0(struct ctx* ctx, struct mut_list_2* a, struct fun_act1_12 f);
struct arrow_1* filter_recur__e_0(struct ctx* ctx, struct arrow_1* out, struct arrow_1* in, struct arrow_1* end, struct fun_act1_12 f);
uint8_t subscript_39(struct ctx* ctx, struct fun_act1_12 a, struct arrow_1 p0);
uint8_t call_w_ctx_574(struct fun_act1_12 a, struct ctx* ctx, struct arrow_1 p0);
uint8_t compact__e_0__lambda0(struct ctx* ctx, struct void_ _closure, struct arrow_1 pair);
struct void_ merge_no_duplicates__e_0(struct ctx* ctx, struct mut_list_2* a, struct mut_list_2* b, struct fun_act2_2 compare);
struct void_ swap__e_1(struct ctx* ctx, struct mut_list_2* a, struct mut_list_2* b);
struct void_ unsafe_set_size__e_0(struct ctx* ctx, struct mut_list_2* a, uint64_t new_size);
struct void_ reserve_0(struct ctx* ctx, struct mut_list_2* a, uint64_t reserved);
struct arrow_1* _minus_8(struct arrow_1* a, uint64_t offset);
struct void_ merge_reverse_recur__e_0(struct ctx* ctx, struct arrow_1* a_begin, struct arrow_1* a_read, struct arrow_1* a_write, struct arrow_1* b_begin, struct arrow_1* b_read, struct fun_act2_2 compare);
struct unique_comparison subscript_40(struct ctx* ctx, struct fun_act2_2 a, struct arrow_1 p0, struct arrow_1 p1);
struct unique_comparison call_w_ctx_583(struct fun_act2_2 a, struct ctx* ctx, struct arrow_1 p0, struct arrow_1 p1);
uint8_t _notEqual_10(struct arrow_1* a, struct arrow_1* b);
struct mut_arr_4 mut_arr_from_begin_end_0(struct arrow_1* begin, struct arrow_1* end);
struct comparison _compare_11(struct arrow_1* a, struct arrow_1* b);
uint8_t _lessOrEqual_4(struct arrow_1* a, struct arrow_1* b);
uint8_t _less_7(struct arrow_1* a, struct arrow_1* b);
struct arr_9 arr_from_begin_end_1(struct arrow_1* begin, struct arrow_1* end);
struct comparison _compare_12(struct arrow_1* a, struct arrow_1* b);
uint8_t _lessOrEqual_5(struct arrow_1* a, struct arrow_1* b);
uint8_t _less_8(struct arrow_1* a, struct arrow_1* b);
struct void_ copy_from__e_0(struct ctx* ctx, struct mut_arr_4 dest, struct arr_9 source);
struct void_ empty__e_0(struct ctx* ctx, struct mut_list_2* a);
struct void_ pop_n__e_0(struct ctx* ctx, struct mut_list_2* a, uint64_t n);
struct unique_comparison assert_comparison_not_equal(struct ctx* ctx, struct comparison a);
struct unique_comparison unreachable(struct ctx* ctx);
struct unique_comparison throw_4(struct ctx* ctx, struct str message);
struct unique_comparison throw_5(struct ctx* ctx, struct exception e);
struct unique_comparison hard_unreachable_3(void);
struct unique_comparison compact__e_0__lambda1(struct ctx* ctx, struct void_ _closure, struct arrow_1 x, struct arrow_1 y);
struct dict_0 move_to_dict__e_0(struct ctx* ctx, struct mut_dict_0* a);
struct arr_10 move_to_arr__e_1(struct ctx* ctx, struct mut_dict_0* a);
struct arr_10 map_to_arr_0(struct ctx* ctx, struct mut_dict_0* a, struct fun_act2_3 f);
struct arr_10 map_to_arr_1(struct ctx* ctx, struct mut_list_2* a, struct fun_act1_13 f);
struct mut_arr_3 map_to_mut_arr_0(struct ctx* ctx, struct mut_list_2* a, struct fun_act1_13 f);
struct arrow_2 subscript_41(struct ctx* ctx, struct fun_act1_13 a, struct arrow_1 p0);
struct arrow_2 call_w_ctx_608(struct fun_act1_13 a, struct ctx* ctx, struct arrow_1 p0);
struct arrow_2 map_to_mut_arr_0__lambda0(struct ctx* ctx, struct map_to_mut_arr_0__lambda0* _closure, uint64_t i);
struct arrow_2 subscript_42(struct ctx* ctx, struct fun_act2_3 a, struct str p0, struct arr_2 p1);
struct arrow_2 call_w_ctx_611(struct fun_act2_3 a, struct ctx* ctx, struct str p0, struct arr_2 p1);
struct arr_2 force_2(struct ctx* ctx, struct opt_12 a);
struct arr_2 force_3(struct ctx* ctx, struct opt_12 a, struct str message);
struct arr_2 throw_6(struct ctx* ctx, struct str message);
struct arr_2 throw_7(struct ctx* ctx, struct exception e);
struct arr_2 hard_unreachable_4(void);
struct arrow_2 map_to_arr_0__lambda0(struct ctx* ctx, struct map_to_arr_0__lambda0* _closure, struct arrow_1 pair);
struct arrow_2 _arrow_2(struct str from, struct arr_2 to);
struct arrow_2 move_to_arr__e_1__lambda0(struct ctx* ctx, struct void_ _closure, struct str key, struct arr_2 value);
struct void_ empty__e_1(struct ctx* ctx, struct mut_dict_0* a);
struct void_ assert_1(struct ctx* ctx, uint8_t condition, struct str message);
struct mut_list_3* fill_mut_list(struct ctx* ctx, uint64_t size, struct opt_12 value);
struct mut_arr_5 fill_mut_arr(struct ctx* ctx, uint64_t size, struct opt_12 value);
struct mut_arr_5 make_mut_arr_1(struct ctx* ctx, uint64_t size, struct fun_act1_14 f);
struct mut_arr_5 uninitialized_mut_arr_3(struct ctx* ctx, uint64_t size);
struct mut_arr_5 mut_arr_8(uint64_t size, struct opt_12* begin_ptr);
struct opt_12* alloc_uninitialized_4(struct ctx* ctx, uint64_t size);
struct void_ fill_ptr_range_2(struct ctx* ctx, struct opt_12* begin, uint64_t size, struct fun_act1_14 f);
struct void_ fill_ptr_range_recur_2(struct ctx* ctx, struct opt_12* begin, uint64_t i, uint64_t size, struct fun_act1_14 f);
struct void_ set_subscript_8(struct opt_12* a, uint64_t n, struct opt_12 value);
struct opt_12 subscript_43(struct ctx* ctx, struct fun_act1_14 a, uint64_t p0);
struct opt_12 call_w_ctx_632(struct fun_act1_14 a, struct ctx* ctx, uint64_t p0);
struct opt_12* begin_ptr_7(struct mut_arr_5 a);
struct opt_12 fill_mut_arr__lambda0(struct ctx* ctx, struct fill_mut_arr__lambda0* _closure, uint64_t ignore);
struct void_ each_2(struct ctx* ctx, struct dict_0 a, struct fun_act2_4 f);
struct void_ fold_0(struct ctx* ctx, struct void_ acc, struct dict_0 a, struct fun_act3_0 f);
struct iters_0* init_iters_0(struct ctx* ctx, struct dict_0 a);
struct mut_arr_6 uninitialized_mut_arr_4(struct ctx* ctx, uint64_t size);
struct mut_arr_6 mut_arr_9(uint64_t size, struct arr_9* begin_ptr);
struct arr_9* alloc_uninitialized_5(struct ctx* ctx, uint64_t size);
uint64_t overlay_count_0(uint64_t acc, struct dict_impl_0 a);
struct arr_10 init_overlay_iters_recur__e_0(struct arr_9* out, struct dict_impl_0 a);
struct arr_9* begin_ptr_8(struct mut_arr_6 a);
struct void_ fold_recur_0(struct ctx* ctx, struct void_ acc, struct arr_10 end_node, struct mut_arr_6 overlays, struct fun_act3_0 f);
uint8_t is_empty_9(struct mut_arr_6 a);
uint64_t size_5(struct mut_arr_6 a);
struct void_ fold_1(struct ctx* ctx, struct void_ acc, struct arr_10 a, struct fun_act2_5 f);
struct void_ fold_recur_1(struct ctx* ctx, struct void_ acc, struct arrow_2* cur, struct arrow_2* end, struct fun_act2_5 f);
uint8_t _equal_8(struct arrow_2* a, struct arrow_2* b);
struct void_ subscript_44(struct ctx* ctx, struct fun_act2_5 a, struct void_ p0, struct arrow_2 p1);
struct void_ call_w_ctx_651(struct fun_act2_5 a, struct ctx* ctx, struct void_ p0, struct arrow_2 p1);
struct arrow_2* end_ptr_5(struct arr_10 a);
struct void_ subscript_45(struct ctx* ctx, struct fun_act3_0 a, struct void_ p0, struct str p1, struct arr_2 p2);
struct void_ call_w_ctx_654(struct fun_act3_0 a, struct ctx* ctx, struct void_ p0, struct str p1, struct arr_2 p2);
struct void_ fold_recur_0__lambda0(struct ctx* ctx, struct fold_recur_0__lambda0* _closure, struct void_ cur, struct arrow_2 pair);
uint8_t is_empty_10(struct arr_10 a);
struct str find_least_key_0(struct ctx* ctx, struct str current_least_key, struct mut_arr_6 overlays);
struct str fold_2(struct ctx* ctx, struct str acc, struct mut_arr_6 a, struct fun_act2_6 f);
struct str fold_3(struct ctx* ctx, struct str acc, struct arr_11 a, struct fun_act2_6 f);
struct str fold_recur_2(struct ctx* ctx, struct str acc, struct arr_9* cur, struct arr_9* end, struct fun_act2_6 f);
uint8_t _equal_9(struct arr_9* a, struct arr_9* b);
struct str subscript_46(struct ctx* ctx, struct fun_act2_6 a, struct str p0, struct arr_9 p1);
struct str call_w_ctx_663(struct fun_act2_6 a, struct ctx* ctx, struct str p0, struct arr_9 p1);
struct arr_9 _times_13(struct arr_9* a);
struct arr_9* _plus_11(struct arr_9* a, uint64_t offset);
struct arr_9* end_ptr_6(struct arr_11 a);
struct arr_11 temp_as_arr_2(struct mut_arr_6 a);
struct str min_1(struct str a, struct str b);
struct arrow_1 subscript_47(struct ctx* ctx, struct arr_9 a, uint64_t index);
struct arrow_1 unsafe_at_5(struct arr_9 a, uint64_t index);
struct arrow_1 subscript_48(struct arrow_1* a, uint64_t n);
struct str find_least_key_0__lambda0(struct ctx* ctx, struct void_ _closure, struct str cur, struct arr_9 overlay);
struct arr_9 subscript_49(struct ctx* ctx, struct mut_arr_6 a, uint64_t index);
struct arr_9 unsafe_at_6(struct ctx* ctx, struct mut_arr_6 a, uint64_t index);
struct arr_9 subscript_50(struct arr_9* a, uint64_t n);
struct mut_arr_6 tail_2(struct ctx* ctx, struct mut_arr_6 a);
struct mut_arr_6 subscript_51(struct ctx* ctx, struct mut_arr_6 a, struct arrow_0 range);
struct arr_11 subscript_52(struct ctx* ctx, struct arr_11 a, struct arrow_0 range);
struct arr_10 tail_3(struct ctx* ctx, struct arr_10 a);
struct arr_10 subscript_53(struct ctx* ctx, struct arr_10 a, struct arrow_0 range);
struct took_key_0* take_key_0(struct ctx* ctx, struct mut_arr_6 overlays, struct str key);
struct took_key_0* take_key_recur_0(struct ctx* ctx, struct mut_arr_6 overlays, struct str key, uint64_t index, struct opt_12 rightmost_value);
struct arr_9 tail_4(struct ctx* ctx, struct arr_9 a);
uint8_t is_empty_11(struct arr_9 a);
struct void_ set_subscript_9(struct ctx* ctx, struct mut_arr_6 a, uint64_t index, struct arr_9 value);
struct void_ unsafe_set_at__e_0(struct ctx* ctx, struct mut_arr_6 a, uint64_t index, struct arr_9 value);
struct void_ set_subscript_10(struct arr_9* a, uint64_t n, struct arr_9 value);
struct opt_12 opt_or_0(struct ctx* ctx, struct opt_12 a, struct opt_12 b);
struct void_ subscript_54(struct ctx* ctx, struct fun_act2_4 a, struct str p0, struct arr_2 p1);
struct void_ call_w_ctx_690(struct fun_act2_4 a, struct ctx* ctx, struct str p0, struct arr_2 p1);
struct void_ each_2__lambda0(struct ctx* ctx, struct each_2__lambda0* _closure, struct void_ ignore, struct str k, struct arr_2 v);
struct opt_11 index_of(struct ctx* ctx, struct arr_2 a, struct str value);
struct opt_17 ptr_of(struct ctx* ctx, struct arr_2 a, struct str value);
struct opt_17 ptr_of_recur(struct ctx* ctx, struct str* cur, struct str* end, struct str value);
uint8_t _equal_10(struct str* a, struct str* b);
struct str* end_ptr_7(struct arr_2 a);
uint64_t _minus_9(struct str* a, struct str* b);
uint64_t _minus_10(struct str* a, struct str* b);
struct void_ set_deref_0(struct cell_3* a, uint8_t value);
struct str finish(struct ctx* ctx, struct interp a);
struct str to_str_3(struct ctx* ctx, struct str a);
struct interp with_value_0(struct ctx* ctx, struct interp a, struct str b);
struct interp with_str(struct ctx* ctx, struct interp a, struct str b);
struct interp interp(struct ctx* ctx);
struct opt_12 subscript_55(struct ctx* ctx, struct mut_list_3* a, uint64_t index);
struct opt_12 subscript_56(struct opt_12* a, uint64_t n);
struct opt_12* begin_ptr_9(struct mut_list_3* a);
struct void_ set_subscript_11(struct ctx* ctx, struct mut_list_3* a, uint64_t index, struct opt_12 value);
struct void_ parse_named_args_0__lambda0(struct ctx* ctx, struct parse_named_args_0__lambda0* _closure, struct str key, struct arr_2 value);
uint8_t _times_14(struct cell_3* a);
struct arr_8 move_to_arr__e_2(struct mut_list_3* a);
struct arr_8 cast_immutable_2(struct mut_arr_5 a);
struct mut_arr_5 move_to_mut_arr__e_1(struct mut_list_3* a);
struct mut_arr_5 mut_arr_10(void);
struct void_ print_help(struct ctx* ctx);
struct opt_12 subscript_57(struct ctx* ctx, struct arr_8 a, uint64_t index);
struct opt_12 unsafe_at_7(struct arr_8 a, uint64_t index);
struct opt_12 subscript_58(struct opt_12* a, uint64_t n);
struct opt_12 _times_15(struct opt_12* a);
struct opt_12* _plus_12(struct opt_12* a, uint64_t offset);
uint64_t force_4(struct ctx* ctx, struct opt_11 a);
uint64_t force_5(struct ctx* ctx, struct opt_11 a, struct str message);
uint64_t throw_8(struct ctx* ctx, struct str message);
uint64_t throw_9(struct ctx* ctx, struct exception e);
uint64_t hard_unreachable_5(void);
struct opt_11 parse_nat(struct ctx* ctx, struct str a);
struct opt_11 with_reader(struct ctx* ctx, struct str a, struct fun_act1_15 f);
struct reader* reader(struct ctx* ctx, struct str a);
struct opt_11 subscript_59(struct ctx* ctx, struct fun_act1_15 a, struct reader* p0);
struct opt_11 call_w_ctx_730(struct fun_act1_15 a, struct ctx* ctx, struct reader* p0);
uint8_t is_empty_12(struct opt_11 a);
uint8_t is_empty_13(struct ctx* ctx, struct reader* a);
struct opt_11 take_nat__e(struct ctx* ctx, struct reader* a);
struct opt_11 char_to_nat64(struct ctx* ctx, char c);
char peek(struct ctx* ctx, struct reader* a);
struct void_ drop_2(char _p0);
char next__e(struct ctx* ctx, struct reader* a);
uint64_t take_nat_recur__e(struct ctx* ctx, uint64_t acc, struct reader* a);
struct opt_11 parse_nat__lambda0(struct ctx* ctx, struct void_ _closure, struct reader* r);
uint64_t do_test(struct ctx* ctx, struct test_options* options);
struct str parent_path(struct ctx* ctx, struct str a);
struct opt_11 r_index_of(struct ctx* ctx, struct arr_0 a, char value);
struct opt_11 find_rindex(struct ctx* ctx, struct arr_0 a, struct fun_act1_16 f);
struct opt_11 find_rindex_recur(struct ctx* ctx, struct arr_0 a, uint64_t index, struct fun_act1_16 f);
uint8_t subscript_60(struct ctx* ctx, struct fun_act1_16 a, char p0);
uint8_t call_w_ctx_746(struct fun_act1_16 a, struct ctx* ctx, char p0);
char subscript_61(struct ctx* ctx, struct arr_0 a, uint64_t index);
char unsafe_at_8(struct arr_0 a, uint64_t index);
char subscript_62(char* a, uint64_t n);
uint8_t r_index_of__lambda0(struct ctx* ctx, struct r_index_of__lambda0* _closure, char it);
struct str child_path(struct ctx* ctx, struct str a, struct str child_name);
struct dict_1 get_environ(struct ctx* ctx);
struct mut_dict_1* mut_dict_1(struct ctx* ctx);
struct mut_list_4* mut_list_2(struct ctx* ctx);
struct mut_arr_7 mut_arr_11(void);
struct void_ get_environ_recur(struct ctx* ctx, char** env, struct mut_dict_1* res);
char* null_1(void);
struct arrow_4 parse_environ_entry(struct ctx* ctx, char* entry);
struct arrow_4 todo_3(void);
struct arrow_4 _arrow_3(struct str from, struct str to);
struct void_ set_subscript_12(struct ctx* ctx, struct mut_dict_1* a, struct str key, struct str value);
uint8_t insert_into_key_match_or_empty_slot__e_1(struct ctx* ctx, struct mut_dict_1* a, struct str key, struct str value);
struct arrow_3* find_insert_ptr_1(struct ctx* ctx, struct mut_dict_1* a, struct str key);
struct arrow_3* binary_search_insert_ptr_2(struct ctx* ctx, struct mut_list_4* a, struct fun_act1_17 compare);
struct arrow_3* binary_search_insert_ptr_3(struct ctx* ctx, struct mut_arr_7 a, struct fun_act1_17 compare);
struct arrow_3* binary_search_compare_recur_1(struct ctx* ctx, struct arrow_3* left, struct arrow_3* right, struct fun_act1_17 compare);
uint8_t _equal_11(struct arrow_3* a, struct arrow_3* b);
struct arrow_3* _plus_13(struct arrow_3* a, uint64_t offset);
uint64_t _minus_11(struct arrow_3* a, struct arrow_3* b);
uint64_t _minus_12(struct arrow_3* a, struct arrow_3* b);
struct comparison subscript_63(struct ctx* ctx, struct fun_act1_17 a, struct arrow_3 p0);
struct comparison call_w_ctx_772(struct fun_act1_17 a, struct ctx* ctx, struct arrow_3 p0);
struct arrow_3 _times_16(struct arrow_3* a);
struct arrow_3* begin_ptr_10(struct mut_arr_7 a);
struct arrow_3* end_ptr_8(struct mut_arr_7 a);
uint64_t size_6(struct mut_arr_7 a);
struct mut_arr_7 temp_as_mut_arr_2(struct mut_list_4* a);
struct mut_arr_7 mut_arr_12(uint64_t size, struct arrow_3* begin_ptr);
struct arrow_3* begin_ptr_11(struct mut_list_4* a);
struct comparison find_insert_ptr_1__lambda0(struct ctx* ctx, struct find_insert_ptr_1__lambda0* _closure, struct arrow_3 pair);
uint8_t _notEqual_11(struct arrow_3* a, struct arrow_3* b);
struct arrow_3* end_ptr_9(struct mut_list_4* a);
uint8_t is_empty_14(struct opt_15 a);
struct arrow_3 _arrow_4(struct str from, struct opt_15 to);
struct void_ add_pair__e_1(struct ctx* ctx, struct mut_dict_1* a, struct str key, struct str value);
uint8_t is_empty_15(struct mut_list_4* a);
struct void_ _concatEquals_5(struct ctx* ctx, struct mut_list_4* a, struct arrow_3 value);
struct void_ incr_capacity__e_2(struct ctx* ctx, struct mut_list_4* a);
struct void_ ensure_capacity_2(struct ctx* ctx, struct mut_list_4* a, uint64_t min_capacity);
uint64_t capacity_3(struct mut_list_4* a);
struct void_ increase_capacity_to__e_2(struct ctx* ctx, struct mut_list_4* a, uint64_t new_capacity);
struct mut_arr_7 uninitialized_mut_arr_5(struct ctx* ctx, uint64_t size);
struct arrow_3* alloc_uninitialized_6(struct ctx* ctx, uint64_t size);
struct void_ copy_data_from__e_3(struct ctx* ctx, struct arrow_3* to, struct arrow_3* from, uint64_t len);
uint8_t* as_any_const_ptr_3(struct arrow_3* ref);
struct void_ set_zero_elements_2(struct mut_arr_7 a);
struct void_ set_zero_range_3(struct arrow_3* begin, uint64_t size);
struct mut_arr_7 subscript_64(struct ctx* ctx, struct mut_arr_7 a, struct arrow_0 range);
struct arr_12 subscript_65(struct ctx* ctx, struct arr_12 a, struct arrow_0 range);
struct void_ set_subscript_13(struct arrow_3* a, uint64_t n, struct arrow_3 value);
struct void_ insert_linear__e_1(struct ctx* ctx, struct mut_list_4* a, uint64_t index, struct str key, struct str value);
struct arrow_3 subscript_66(struct ctx* ctx, struct mut_list_4* a, uint64_t index);
struct arrow_3 subscript_67(struct arrow_3* a, uint64_t n);
struct void_ move_right__e_1(struct ctx* ctx, struct mut_list_4* a, uint64_t index);
struct void_ set_subscript_14(struct ctx* ctx, struct mut_list_4* a, uint64_t index, struct arrow_3 value);
struct void_ compact_if_needed__e_1(struct ctx* ctx, struct mut_dict_1* a);
uint64_t total_pairs_size_1(struct ctx* ctx, struct mut_dict_1* a);
uint64_t total_pairs_size_recur_1(struct ctx* ctx, uint64_t acc, struct mut_dict_1* a);
struct void_ compact__e_1(struct ctx* ctx, struct mut_dict_1* a);
struct void_ filter__e_1(struct ctx* ctx, struct mut_list_4* a, struct fun_act1_18 f);
struct arrow_3* filter_recur__e_1(struct ctx* ctx, struct arrow_3* out, struct arrow_3* in, struct arrow_3* end, struct fun_act1_18 f);
uint8_t subscript_68(struct ctx* ctx, struct fun_act1_18 a, struct arrow_3 p0);
uint8_t call_w_ctx_813(struct fun_act1_18 a, struct ctx* ctx, struct arrow_3 p0);
uint8_t compact__e_1__lambda0(struct ctx* ctx, struct void_ _closure, struct arrow_3 pair);
struct void_ merge_no_duplicates__e_1(struct ctx* ctx, struct mut_list_4* a, struct mut_list_4* b, struct fun_act2_7 compare);
struct void_ swap__e_2(struct ctx* ctx, struct mut_list_4* a, struct mut_list_4* b);
struct void_ unsafe_set_size__e_1(struct ctx* ctx, struct mut_list_4* a, uint64_t new_size);
struct void_ reserve_1(struct ctx* ctx, struct mut_list_4* a, uint64_t reserved);
struct arrow_3* _minus_13(struct arrow_3* a, uint64_t offset);
struct void_ merge_reverse_recur__e_1(struct ctx* ctx, struct arrow_3* a_begin, struct arrow_3* a_read, struct arrow_3* a_write, struct arrow_3* b_begin, struct arrow_3* b_read, struct fun_act2_7 compare);
struct unique_comparison subscript_69(struct ctx* ctx, struct fun_act2_7 a, struct arrow_3 p0, struct arrow_3 p1);
struct unique_comparison call_w_ctx_822(struct fun_act2_7 a, struct ctx* ctx, struct arrow_3 p0, struct arrow_3 p1);
uint8_t _notEqual_12(struct arrow_3* a, struct arrow_3* b);
struct mut_arr_7 mut_arr_from_begin_end_1(struct arrow_3* begin, struct arrow_3* end);
struct comparison _compare_13(struct arrow_3* a, struct arrow_3* b);
uint8_t _lessOrEqual_6(struct arrow_3* a, struct arrow_3* b);
uint8_t _less_9(struct arrow_3* a, struct arrow_3* b);
struct arr_12 arr_from_begin_end_2(struct arrow_3* begin, struct arrow_3* end);
struct comparison _compare_14(struct arrow_3* a, struct arrow_3* b);
uint8_t _lessOrEqual_7(struct arrow_3* a, struct arrow_3* b);
uint8_t _less_10(struct arrow_3* a, struct arrow_3* b);
struct void_ copy_from__e_1(struct ctx* ctx, struct mut_arr_7 dest, struct arr_12 source);
struct void_ empty__e_2(struct ctx* ctx, struct mut_list_4* a);
struct void_ pop_n__e_1(struct ctx* ctx, struct mut_list_4* a, uint64_t n);
struct unique_comparison compact__e_1__lambda1(struct ctx* ctx, struct void_ _closure, struct arrow_3 x, struct arrow_3 y);
extern char** environ;
struct dict_1 move_to_dict__e_1(struct ctx* ctx, struct mut_dict_1* a);
struct dict_1 dict_1(struct ctx* ctx, struct arr_13 a);
struct arr_13 sort_by_1(struct ctx* ctx, struct arr_13 a, struct fun_act1_19 f);
struct arr_13 sort_1(struct ctx* ctx, struct arr_13 a, struct fun_act2_8 comparer);
struct mut_arr_8 mut_arr_13(struct ctx* ctx, struct arr_13 a);
struct mut_arr_8 make_mut_arr_2(struct ctx* ctx, uint64_t size, struct fun_act1_20 f);
struct mut_arr_8 uninitialized_mut_arr_6(struct ctx* ctx, uint64_t size);
struct mut_arr_8 mut_arr_14(uint64_t size, struct arrow_4* begin_ptr);
struct arrow_4* alloc_uninitialized_7(struct ctx* ctx, uint64_t size);
struct void_ fill_ptr_range_3(struct ctx* ctx, struct arrow_4* begin, uint64_t size, struct fun_act1_20 f);
struct void_ fill_ptr_range_recur_3(struct ctx* ctx, struct arrow_4* begin, uint64_t i, uint64_t size, struct fun_act1_20 f);
struct void_ set_subscript_15(struct arrow_4* a, uint64_t n, struct arrow_4 value);
struct arrow_4 subscript_70(struct ctx* ctx, struct fun_act1_20 a, uint64_t p0);
struct arrow_4 call_w_ctx_850(struct fun_act1_20 a, struct ctx* ctx, uint64_t p0);
struct arrow_4* begin_ptr_12(struct mut_arr_8 a);
struct arrow_4 subscript_71(struct ctx* ctx, struct arr_13 a, uint64_t index);
struct arrow_4 unsafe_at_9(struct arr_13 a, uint64_t index);
struct arrow_4 subscript_72(struct arrow_4* a, uint64_t n);
struct arrow_4 _times_17(struct arrow_4* a);
struct arrow_4* _plus_14(struct arrow_4* a, uint64_t offset);
struct arrow_4 mut_arr_13__lambda0(struct ctx* ctx, struct mut_arr_13__lambda0* _closure, uint64_t i);
struct void_ sort__e_2(struct ctx* ctx, struct mut_arr_8 a, struct fun_act2_8 comparer);
uint8_t is_empty_16(struct mut_arr_8 a);
uint64_t size_7(struct mut_arr_8 a);
struct void_ insertion_sort_recur__e_1(struct ctx* ctx, struct arrow_4* begin, struct arrow_4* cur, struct arrow_4* end, struct fun_act2_8 comparer);
uint8_t _notEqual_13(struct arrow_4* a, struct arrow_4* b);
struct void_ insert__e_1(struct ctx* ctx, struct arrow_4* begin, struct arrow_4* cur, struct arrow_4 value, struct fun_act2_8 comparer);
struct comparison subscript_73(struct ctx* ctx, struct fun_act2_8 a, struct arrow_4 p0, struct arrow_4 p1);
struct comparison call_w_ctx_865(struct fun_act2_8 a, struct ctx* ctx, struct arrow_4 p0, struct arrow_4 p1);
struct arrow_4* end_ptr_10(struct mut_arr_8 a);
struct arr_13 cast_immutable_3(struct mut_arr_8 a);
struct str subscript_74(struct ctx* ctx, struct fun_act1_19 a, struct arrow_4 p0);
struct str call_w_ctx_869(struct fun_act1_19 a, struct ctx* ctx, struct arrow_4 p0);
struct comparison sort_by_1__lambda0(struct ctx* ctx, struct sort_by_1__lambda0* _closure, struct arrow_4 x, struct arrow_4 y);
struct str dict_1__lambda0(struct ctx* ctx, struct void_ _closure, struct arrow_4 pair);
struct arr_13 move_to_arr__e_3(struct ctx* ctx, struct mut_dict_1* a);
struct arr_13 map_to_arr_2(struct ctx* ctx, struct mut_dict_1* a, struct fun_act2_9 f);
struct arr_13 map_to_arr_3(struct ctx* ctx, struct mut_list_4* a, struct fun_act1_21 f);
struct mut_arr_8 map_to_mut_arr_1(struct ctx* ctx, struct mut_list_4* a, struct fun_act1_21 f);
struct arrow_4 subscript_75(struct ctx* ctx, struct fun_act1_21 a, struct arrow_3 p0);
struct arrow_4 call_w_ctx_877(struct fun_act1_21 a, struct ctx* ctx, struct arrow_3 p0);
struct arrow_4 map_to_mut_arr_1__lambda0(struct ctx* ctx, struct map_to_mut_arr_1__lambda0* _closure, uint64_t i);
struct arrow_4 subscript_76(struct ctx* ctx, struct fun_act2_9 a, struct str p0, struct str p1);
struct arrow_4 call_w_ctx_880(struct fun_act2_9 a, struct ctx* ctx, struct str p0, struct str p1);
struct arrow_4 map_to_arr_2__lambda0(struct ctx* ctx, struct map_to_arr_2__lambda0* _closure, struct arrow_3 pair);
struct arrow_4 move_to_arr__e_3__lambda0(struct ctx* ctx, struct void_ _closure, struct str key, struct str value);
struct void_ empty__e_3(struct ctx* ctx, struct mut_dict_1* a);
struct result_2 first_failures(struct ctx* ctx, struct result_2 a, struct fun0 b);
struct result_2 subscript_77(struct ctx* ctx, struct fun0 a);
struct result_2 call_w_ctx_886(struct fun0 a, struct ctx* ctx);
struct result_2 run_crow_tests(struct ctx* ctx, struct str path, struct str path_to_crow, struct dict_1 env, struct test_options* options);
struct arr_2 list_tests(struct ctx* ctx, struct str path, struct str match_test);
struct mut_list_5* mut_list_3(struct ctx* ctx);
struct mut_arr_9 mut_arr_15(void);
struct void_ each_child_recursive_0(struct ctx* ctx, struct str path, struct fun_act1_22 f);
uint8_t each_child_recursive_0__lambda0(struct ctx* ctx, struct void_ _closure, struct str ignore);
struct void_ each_child_recursive_1(struct ctx* ctx, struct str path, struct fun_act1_8 filter, struct fun_act1_22 f);
uint8_t is_dir_0(struct ctx* ctx, struct str path);
uint8_t is_dir_1(struct ctx* ctx, char* path);
struct opt_19 get_stat(struct ctx* ctx, char* path);
struct stat* stat_0(struct ctx* ctx);
extern int32_t stat(char* path, struct stat* buf);
int32_t errno(void);
extern int32_t* __errno_location(void);
int32_t ENOENT(void);
struct opt_19 todo_4(void);
uint8_t throw_10(struct ctx* ctx, struct str message);
uint8_t throw_11(struct ctx* ctx, struct exception e);
uint8_t hard_unreachable_6(void);
struct interp with_value_1(struct ctx* ctx, struct interp a, char* b);
uint32_t S_IFMT(void);
uint32_t S_IFDIR(void);
char* to_c_str(struct ctx* ctx, struct str a);
struct void_ each_3(struct ctx* ctx, struct arr_2 a, struct fun_act1_22 f);
struct void_ each_recur_2(struct ctx* ctx, struct str* cur, struct str* end, struct fun_act1_22 f);
uint8_t _notEqual_14(struct str* a, struct str* b);
struct void_ subscript_78(struct ctx* ctx, struct fun_act1_22 a, struct str p0);
struct void_ call_w_ctx_914(struct fun_act1_22 a, struct ctx* ctx, struct str p0);
struct arr_2 read_dir_0(struct ctx* ctx, struct str path);
struct arr_2 read_dir_1(struct ctx* ctx, char* path);
extern struct dir* opendir(char* name);
uint8_t _notEqual_15(uint8_t** a, uint8_t** b);
struct void_ read_dir_recur(struct ctx* ctx, struct dir* dirp, struct mut_list_5* res);
struct bytes256 zero_4(void);
extern int32_t readdir_r(struct dir* dirp, struct dirent* entry, struct cell_4* result);
uint8_t _notEqual_16(uint8_t* a, uint8_t* b);
uint8_t* as_any_const_ptr_4(struct dirent* ref);
struct dirent* _times_18(struct cell_4* a);
uint8_t ref_eq(struct dirent* a, struct dirent* b);
struct str get_dirent_name(struct ctx* ctx, struct dirent* d);
uint8_t* _plus_15(uint8_t* a, uint64_t offset);
char* ptr_cast_1(uint8_t* a);
uint8_t _notEqual_17(struct str a, struct str b);
struct void_ _concatEquals_6(struct ctx* ctx, struct mut_list_5* a, struct str value);
struct void_ incr_capacity__e_3(struct ctx* ctx, struct mut_list_5* a);
struct void_ ensure_capacity_3(struct ctx* ctx, struct mut_list_5* a, uint64_t min_capacity);
uint64_t capacity_4(struct mut_list_5* a);
uint64_t size_8(struct mut_arr_9 a);
struct void_ increase_capacity_to__e_3(struct ctx* ctx, struct mut_list_5* a, uint64_t new_capacity);
struct str* begin_ptr_13(struct mut_list_5* a);
struct str* begin_ptr_14(struct mut_arr_9 a);
struct mut_arr_9 uninitialized_mut_arr_7(struct ctx* ctx, uint64_t size);
struct mut_arr_9 mut_arr_16(uint64_t size, struct str* begin_ptr);
struct void_ copy_data_from__e_4(struct ctx* ctx, struct str* to, struct str* from, uint64_t len);
uint8_t* as_any_const_ptr_5(struct str* ref);
struct void_ set_zero_elements_3(struct mut_arr_9 a);
struct void_ set_zero_range_4(struct str* begin, uint64_t size);
struct mut_arr_9 subscript_79(struct ctx* ctx, struct mut_arr_9 a, struct arrow_0 range);
struct arr_2 sort_2(struct ctx* ctx, struct arr_2 a);
struct arr_2 sort_3(struct ctx* ctx, struct arr_2 a, struct fun_act2_10 comparer);
struct mut_arr_9 mut_arr_17(struct ctx* ctx, struct arr_2 a);
struct mut_arr_9 make_mut_arr_3(struct ctx* ctx, uint64_t size, struct fun_act1_7 f);
struct str mut_arr_17__lambda0(struct ctx* ctx, struct mut_arr_17__lambda0* _closure, uint64_t i);
struct void_ sort__e_3(struct ctx* ctx, struct mut_arr_9 a, struct fun_act2_10 comparer);
uint8_t is_empty_17(struct mut_arr_9 a);
struct void_ insertion_sort_recur__e_2(struct ctx* ctx, struct str* begin, struct str* cur, struct str* end, struct fun_act2_10 comparer);
uint8_t _notEqual_18(struct str* a, struct str* b);
struct void_ insert__e_2(struct ctx* ctx, struct str* begin, struct str* cur, struct str value, struct fun_act2_10 comparer);
struct comparison subscript_80(struct ctx* ctx, struct fun_act2_10 a, struct str p0, struct str p1);
struct comparison call_w_ctx_956(struct fun_act2_10 a, struct ctx* ctx, struct str p0, struct str p1);
struct str* end_ptr_11(struct mut_arr_9 a);
struct arr_2 cast_immutable_4(struct mut_arr_9 a);
struct comparison sort_2__lambda0(struct ctx* ctx, struct void_ _closure, struct str x, struct str y);
struct arr_2 move_to_arr__e_4(struct mut_list_5* a);
struct mut_arr_9 move_to_mut_arr__e_2(struct mut_list_5* a);
struct void_ each_child_recursive_1__lambda0(struct ctx* ctx, struct each_child_recursive_1__lambda0* _closure, struct str child_name);
uint8_t has_substr(struct ctx* ctx, struct str a, struct str b);
uint8_t contains_subseq(struct ctx* ctx, struct arr_0 a, struct arr_0 subseq);
struct opt_11 index_of_subseq(struct ctx* ctx, struct arr_0 a, struct arr_0 subseq);
struct opt_11 index_of_subseq_recur(struct ctx* ctx, struct arr_0 a, struct arr_0 subseq, uint64_t i);
uint8_t ext_is_crow(struct ctx* ctx, struct str a);
uint8_t _equal_12(struct opt_15 a, struct opt_15 b);
uint8_t opt_equal(struct opt_15 a, struct opt_15 b);
struct opt_15 get_extension(struct ctx* ctx, struct str name);
struct opt_11 last_index_of(struct ctx* ctx, struct str a, char c);
struct opt_20 last(struct ctx* ctx, struct arr_0 a);
struct arr_0 rtail(struct ctx* ctx, struct arr_0 a);
struct str base_name(struct ctx* ctx, struct str path);
struct void_ list_tests__lambda0(struct ctx* ctx, struct list_tests__lambda0* _closure, struct str child);
struct arr_14 flat_map_with_max_size(struct ctx* ctx, struct arr_2 a, uint64_t max_size, struct fun_act1_23 mapper);
struct mut_list_6* mut_list_4(struct ctx* ctx);
struct mut_arr_10 mut_arr_18(void);
struct void_ _concatEquals_7(struct ctx* ctx, struct mut_list_6* a, struct arr_14 values);
struct void_ each_4(struct ctx* ctx, struct arr_14 a, struct fun_act1_24 f);
struct void_ each_recur_3(struct ctx* ctx, struct failure** cur, struct failure** end, struct fun_act1_24 f);
uint8_t _equal_13(struct failure** a, struct failure** b);
uint8_t _notEqual_19(struct failure** a, struct failure** b);
struct void_ subscript_81(struct ctx* ctx, struct fun_act1_24 a, struct failure* p0);
struct void_ call_w_ctx_985(struct fun_act1_24 a, struct ctx* ctx, struct failure* p0);
struct failure* _times_19(struct failure** a);
struct failure** _plus_16(struct failure** a, uint64_t offset);
struct failure** end_ptr_12(struct arr_14 a);
struct void_ _concatEquals_8(struct ctx* ctx, struct mut_list_6* a, struct failure* value);
struct void_ incr_capacity__e_4(struct ctx* ctx, struct mut_list_6* a);
struct void_ ensure_capacity_4(struct ctx* ctx, struct mut_list_6* a, uint64_t min_capacity);
uint64_t capacity_5(struct mut_list_6* a);
uint64_t size_9(struct mut_arr_10 a);
struct void_ increase_capacity_to__e_4(struct ctx* ctx, struct mut_list_6* a, uint64_t new_capacity);
struct failure** begin_ptr_15(struct mut_list_6* a);
struct failure** begin_ptr_16(struct mut_arr_10 a);
struct mut_arr_10 uninitialized_mut_arr_8(struct ctx* ctx, uint64_t size);
struct mut_arr_10 mut_arr_19(uint64_t size, struct failure** begin_ptr);
struct failure** alloc_uninitialized_8(struct ctx* ctx, uint64_t size);
struct void_ copy_data_from__e_5(struct ctx* ctx, struct failure** to, struct failure** from, uint64_t len);
uint8_t* as_any_const_ptr_6(struct failure** ref);
struct void_ set_zero_elements_4(struct mut_arr_10 a);
struct void_ set_zero_range_5(struct failure** begin, uint64_t size);
struct mut_arr_10 subscript_82(struct ctx* ctx, struct mut_arr_10 a, struct arrow_0 range);
struct arr_14 subscript_83(struct ctx* ctx, struct arr_14 a, struct arrow_0 range);
struct void_ set_subscript_16(struct failure** a, uint64_t n, struct failure* value);
struct void_ _concatEquals_7__lambda0(struct ctx* ctx, struct _concatEquals_7__lambda0* _closure, struct failure* x);
struct arr_14 subscript_84(struct ctx* ctx, struct fun_act1_23 a, struct str p0);
struct arr_14 call_w_ctx_1009(struct fun_act1_23 a, struct ctx* ctx, struct str p0);
struct void_ reduce_size_if_more_than__e(struct ctx* ctx, struct mut_list_6* a, uint64_t new_size);
struct void_ drop_3(struct opt_21 _p0);
struct opt_21 pop__e(struct ctx* ctx, struct mut_list_6* a);
uint8_t is_empty_18(struct mut_list_6* a);
struct failure* subscript_85(struct ctx* ctx, struct mut_list_6* a, uint64_t index);
struct failure* subscript_86(struct failure** a, uint64_t n);
struct void_ set_subscript_17(struct ctx* ctx, struct mut_list_6* a, uint64_t index, struct failure* value);
struct void_ flat_map_with_max_size__lambda0(struct ctx* ctx, struct flat_map_with_max_size__lambda0* _closure, struct str x);
struct arr_14 move_to_arr__e_5(struct mut_list_6* a);
struct arr_14 cast_immutable_5(struct mut_arr_10 a);
struct mut_arr_10 move_to_mut_arr__e_3(struct mut_list_6* a);
struct arr_14 run_single_crow_test(struct ctx* ctx, struct str path_to_crow, struct dict_1 env, struct str path, struct test_options* options);
struct opt_22 first_some(struct ctx* ctx, struct arr_2 a, struct fun_act1_25 f);
struct opt_22 subscript_87(struct ctx* ctx, struct fun_act1_25 a, struct str p0);
struct opt_22 call_w_ctx_1024(struct fun_act1_25 a, struct ctx* ctx, struct str p0);
uint8_t is_empty_19(struct opt_22 a);
struct print_test_result* run_print_test(struct ctx* ctx, struct str print_kind, struct str path_to_crow, struct dict_1 env, struct str path, uint8_t overwrite_output);
struct process_result* spawn_and_wait_result_0(struct ctx* ctx, struct str exe, struct arr_2 args, struct dict_1 environ);
struct str fold_4(struct ctx* ctx, struct str acc, struct arr_2 a, struct fun_act2_11 f);
struct str fold_recur_3(struct ctx* ctx, struct str acc, struct str* cur, struct str* end, struct fun_act2_11 f);
struct str subscript_88(struct ctx* ctx, struct fun_act2_11 a, struct str p0, struct str p1);
struct str call_w_ctx_1031(struct fun_act2_11 a, struct ctx* ctx, struct str p0, struct str p1);
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
int32_t _times_20(struct cell_5* a);
extern int32_t close(int32_t fd);
struct void_ keep_POLLINg(struct ctx* ctx, int32_t stdout_pipe, int32_t stderr_pipe, struct mut_list_1* stdout_builder, struct mut_list_1* stderr_builder);
struct mut_arr_11 mut_arr_20(struct ctx* ctx, struct arr_15 a);
struct mut_arr_11 make_mut_arr_4(struct ctx* ctx, uint64_t size, struct fun_act1_26 f);
struct mut_arr_11 uninitialized_mut_arr_9(struct ctx* ctx, uint64_t size);
struct mut_arr_11 mut_arr_21(uint64_t size, struct pollfd* begin_ptr);
struct pollfd* alloc_uninitialized_9(struct ctx* ctx, uint64_t size);
struct void_ fill_ptr_range_4(struct ctx* ctx, struct pollfd* begin, uint64_t size, struct fun_act1_26 f);
struct void_ fill_ptr_range_recur_4(struct ctx* ctx, struct pollfd* begin, uint64_t i, uint64_t size, struct fun_act1_26 f);
struct void_ set_subscript_18(struct pollfd* a, uint64_t n, struct pollfd value);
struct pollfd subscript_89(struct ctx* ctx, struct fun_act1_26 a, uint64_t p0);
struct pollfd call_w_ctx_1056(struct fun_act1_26 a, struct ctx* ctx, uint64_t p0);
struct pollfd* begin_ptr_17(struct mut_arr_11 a);
struct pollfd subscript_90(struct ctx* ctx, struct arr_15 a, uint64_t index);
struct pollfd unsafe_at_10(struct arr_15 a, uint64_t index);
struct pollfd subscript_91(struct pollfd* a, uint64_t n);
struct pollfd _times_21(struct pollfd* a);
struct pollfd* _plus_17(struct pollfd* a, uint64_t offset);
struct pollfd mut_arr_20__lambda0(struct ctx* ctx, struct mut_arr_20__lambda0* _closure, uint64_t i);
int16_t POLLIN(struct ctx* ctx);
struct pollfd* ref_of_val_at(struct ctx* ctx, struct mut_arr_11 a, uint64_t index);
uint64_t size_10(struct mut_arr_11 a);
struct pollfd* ref_of_ptr(struct pollfd* p);
extern int32_t poll(struct pollfd* fds, uint64_t nfds, int32_t timeout);
struct handle_revents_result handle_revents(struct ctx* ctx, struct pollfd* pollfd, struct mut_list_1* builder);
uint8_t has_POLLIN(struct ctx* ctx, int16_t revents);
uint8_t bits_intersect(int16_t a, int16_t b);
uint8_t _notEqual_20(int16_t a, int16_t b);
struct void_ read_to_buffer_until_eof(struct ctx* ctx, int32_t fd, struct mut_list_1* buffer);
struct void_ unsafe_set_size__e_2(struct ctx* ctx, struct mut_list_1* a, uint64_t new_size);
struct void_ reserve_2(struct ctx* ctx, struct mut_list_1* a, uint64_t reserved);
extern int64_t read(int32_t fd, uint8_t* buff, uint64_t n_bytes);
uint64_t to_nat64_0(struct ctx* ctx, int64_t a);
struct comparison _compare_15(int64_t a, int64_t b);
struct comparison cmp_2(int64_t a, int64_t b);
uint8_t _less_11(int64_t a, int64_t b);
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
struct comparison _compare_16(int32_t a, int32_t b);
struct comparison cmp_3(int32_t a, int32_t b);
uint8_t _less_12(int32_t a, int32_t b);
int32_t todo_5(void);
uint8_t WIFSIGNALED(struct ctx* ctx, int32_t status);
struct str to_str_4(struct ctx* ctx, int32_t a);
struct str to_str_5(struct ctx* ctx, int64_t a);
struct str to_str_6(struct ctx* ctx, uint64_t a);
struct str to_base(struct ctx* ctx, uint64_t a, uint64_t base);
struct str digit_to_str(struct ctx* ctx, uint64_t a);
uint64_t mod(struct ctx* ctx, uint64_t a, uint64_t b);
uint64_t abs(struct ctx* ctx, int64_t a);
int64_t _minus_14(struct ctx* ctx, int64_t a);
int64_t _times_22(struct ctx* ctx, int64_t a, int64_t b);
struct interp with_value_2(struct ctx* ctx, struct interp a, int32_t b);
uint8_t WIFSTOPPED(struct ctx* ctx, int32_t status);
uint8_t WIFCONTINUED(struct ctx* ctx, int32_t status);
char** convert_args(struct ctx* ctx, char* exe_c_str, struct arr_2 args);
struct arr_7 _tilde_2(struct ctx* ctx, struct arr_7 a, struct arr_7 b);
char** alloc_uninitialized_10(struct ctx* ctx, uint64_t size);
struct void_ copy_data_from__e_6(struct ctx* ctx, char** to, char** from, uint64_t len);
uint8_t* as_any_const_ptr_7(char** ref);
struct arr_7 map_1(struct ctx* ctx, struct arr_2 a, struct fun_act1_27 f);
struct arr_7 make_arr_1(struct ctx* ctx, uint64_t size, struct fun_act1_28 f);
struct void_ fill_ptr_range_5(struct ctx* ctx, char** begin, uint64_t size, struct fun_act1_28 f);
struct void_ fill_ptr_range_recur_5(struct ctx* ctx, char** begin, uint64_t i, uint64_t size, struct fun_act1_28 f);
struct void_ set_subscript_19(char** a, uint64_t n, char* value);
char* subscript_92(struct ctx* ctx, struct fun_act1_28 a, uint64_t p0);
char* call_w_ctx_1127(struct fun_act1_28 a, struct ctx* ctx, uint64_t p0);
char* subscript_93(struct ctx* ctx, struct fun_act1_27 a, struct str p0);
char* call_w_ctx_1129(struct fun_act1_27 a, struct ctx* ctx, struct str p0);
char* map_1__lambda0(struct ctx* ctx, struct map_1__lambda0* _closure, uint64_t i);
char* convert_args__lambda0(struct ctx* ctx, struct void_ _closure, struct str x);
char** convert_environ(struct ctx* ctx, struct dict_1 environ);
struct mut_list_7* mut_list_5(struct ctx* ctx);
struct mut_arr_12 mut_arr_22(void);
struct void_ each_5(struct ctx* ctx, struct dict_1 a, struct fun_act2_12 f);
struct void_ fold_5(struct ctx* ctx, struct void_ acc, struct dict_1 a, struct fun_act3_1 f);
struct iters_1* init_iters_1(struct ctx* ctx, struct dict_1 a);
struct mut_arr_13 uninitialized_mut_arr_10(struct ctx* ctx, uint64_t size);
struct mut_arr_13 mut_arr_23(uint64_t size, struct arr_12* begin_ptr);
struct arr_12* alloc_uninitialized_11(struct ctx* ctx, uint64_t size);
uint64_t overlay_count_1(uint64_t acc, struct dict_impl_1 a);
struct arr_13 init_overlay_iters_recur__e_1(struct arr_12* out, struct dict_impl_1 a);
struct arr_12* begin_ptr_18(struct mut_arr_13 a);
struct void_ fold_recur_4(struct ctx* ctx, struct void_ acc, struct arr_13 end_node, struct mut_arr_13 overlays, struct fun_act3_1 f);
uint8_t is_empty_20(struct mut_arr_13 a);
uint64_t size_11(struct mut_arr_13 a);
struct void_ fold_6(struct ctx* ctx, struct void_ acc, struct arr_13 a, struct fun_act2_13 f);
struct void_ fold_recur_5(struct ctx* ctx, struct void_ acc, struct arrow_4* cur, struct arrow_4* end, struct fun_act2_13 f);
uint8_t _equal_14(struct arrow_4* a, struct arrow_4* b);
struct void_ subscript_94(struct ctx* ctx, struct fun_act2_13 a, struct void_ p0, struct arrow_4 p1);
struct void_ call_w_ctx_1151(struct fun_act2_13 a, struct ctx* ctx, struct void_ p0, struct arrow_4 p1);
struct arrow_4* end_ptr_13(struct arr_13 a);
struct void_ subscript_95(struct ctx* ctx, struct fun_act3_1 a, struct void_ p0, struct str p1, struct str p2);
struct void_ call_w_ctx_1154(struct fun_act3_1 a, struct ctx* ctx, struct void_ p0, struct str p1, struct str p2);
struct void_ fold_recur_4__lambda0(struct ctx* ctx, struct fold_recur_4__lambda0* _closure, struct void_ cur, struct arrow_4 pair);
uint8_t is_empty_21(struct arr_13 a);
struct str find_least_key_1(struct ctx* ctx, struct str current_least_key, struct mut_arr_13 overlays);
struct str fold_7(struct ctx* ctx, struct str acc, struct mut_arr_13 a, struct fun_act2_14 f);
struct str fold_8(struct ctx* ctx, struct str acc, struct arr_16 a, struct fun_act2_14 f);
struct str fold_recur_6(struct ctx* ctx, struct str acc, struct arr_12* cur, struct arr_12* end, struct fun_act2_14 f);
uint8_t _equal_15(struct arr_12* a, struct arr_12* b);
struct str subscript_96(struct ctx* ctx, struct fun_act2_14 a, struct str p0, struct arr_12 p1);
struct str call_w_ctx_1163(struct fun_act2_14 a, struct ctx* ctx, struct str p0, struct arr_12 p1);
struct arr_12 _times_23(struct arr_12* a);
struct arr_12* _plus_18(struct arr_12* a, uint64_t offset);
struct arr_12* end_ptr_14(struct arr_16 a);
struct arr_16 temp_as_arr_3(struct mut_arr_13 a);
struct arrow_3 subscript_97(struct ctx* ctx, struct arr_12 a, uint64_t index);
struct arrow_3 unsafe_at_11(struct arr_12 a, uint64_t index);
struct arrow_3 subscript_98(struct arrow_3* a, uint64_t n);
struct str find_least_key_1__lambda0(struct ctx* ctx, struct void_ _closure, struct str cur, struct arr_12 overlay);
struct arr_12 subscript_99(struct ctx* ctx, struct mut_arr_13 a, uint64_t index);
struct arr_12 unsafe_at_12(struct ctx* ctx, struct mut_arr_13 a, uint64_t index);
struct arr_12 subscript_100(struct arr_12* a, uint64_t n);
struct mut_arr_13 tail_5(struct ctx* ctx, struct mut_arr_13 a);
struct mut_arr_13 subscript_101(struct ctx* ctx, struct mut_arr_13 a, struct arrow_0 range);
struct arr_16 subscript_102(struct ctx* ctx, struct arr_16 a, struct arrow_0 range);
struct arr_13 tail_6(struct ctx* ctx, struct arr_13 a);
struct arr_13 subscript_103(struct ctx* ctx, struct arr_13 a, struct arrow_0 range);
struct took_key_1* take_key_1(struct ctx* ctx, struct mut_arr_13 overlays, struct str key);
struct took_key_1* take_key_recur_1(struct ctx* ctx, struct mut_arr_13 overlays, struct str key, uint64_t index, struct opt_15 rightmost_value);
struct arr_12 tail_7(struct ctx* ctx, struct arr_12 a);
uint8_t is_empty_22(struct arr_12 a);
struct void_ set_subscript_20(struct ctx* ctx, struct mut_arr_13 a, uint64_t index, struct arr_12 value);
struct void_ unsafe_set_at__e_1(struct ctx* ctx, struct mut_arr_13 a, uint64_t index, struct arr_12 value);
struct void_ set_subscript_21(struct arr_12* a, uint64_t n, struct arr_12 value);
struct opt_15 opt_or_1(struct ctx* ctx, struct opt_15 a, struct opt_15 b);
struct void_ subscript_104(struct ctx* ctx, struct fun_act2_12 a, struct str p0, struct str p1);
struct void_ call_w_ctx_1189(struct fun_act2_12 a, struct ctx* ctx, struct str p0, struct str p1);
struct void_ each_5__lambda0(struct ctx* ctx, struct each_5__lambda0* _closure, struct void_ ignore, struct str k, struct str v);
struct void_ _concatEquals_9(struct ctx* ctx, struct mut_list_7* a, char* value);
struct void_ incr_capacity__e_5(struct ctx* ctx, struct mut_list_7* a);
struct void_ ensure_capacity_5(struct ctx* ctx, struct mut_list_7* a, uint64_t min_capacity);
uint64_t capacity_6(struct mut_list_7* a);
uint64_t size_12(struct mut_arr_12 a);
struct void_ increase_capacity_to__e_5(struct ctx* ctx, struct mut_list_7* a, uint64_t new_capacity);
char** begin_ptr_19(struct mut_list_7* a);
char** begin_ptr_20(struct mut_arr_12 a);
struct mut_arr_12 uninitialized_mut_arr_11(struct ctx* ctx, uint64_t size);
struct mut_arr_12 mut_arr_24(uint64_t size, char** begin_ptr);
struct void_ set_zero_elements_5(struct mut_arr_12 a);
struct void_ set_zero_range_6(char** begin, uint64_t size);
struct mut_arr_12 subscript_105(struct ctx* ctx, struct mut_arr_12 a, struct arrow_0 range);
struct void_ convert_environ__lambda0(struct ctx* ctx, struct convert_environ__lambda0* _closure, struct str key, struct str value);
struct arr_7 move_to_arr__e_6(struct mut_list_7* a);
struct arr_7 cast_immutable_6(struct mut_arr_12 a);
struct mut_arr_12 move_to_mut_arr__e_4(struct mut_list_7* a);
struct process_result* throw_12(struct ctx* ctx, struct str message);
struct process_result* throw_13(struct ctx* ctx, struct exception e);
struct process_result* hard_unreachable_7(void);
struct arr_14 handle_output(struct ctx* ctx, struct str original_path, struct str output_path, struct str actual, uint8_t overwrite_output);
struct opt_15 try_read_file_0(struct ctx* ctx, struct str path);
struct opt_15 try_read_file_1(struct ctx* ctx, char* path);
extern int32_t open(char* path, int32_t oflag, uint32_t permission);
int32_t O_RDONLY(void);
struct opt_15 todo_6(void);
extern int64_t lseek(int32_t f, int64_t offset, int32_t whence);
int32_t seek_end(struct ctx* ctx);
int32_t seek_set(struct ctx* ctx);
struct void_ write_file_0(struct ctx* ctx, struct str path, struct str content);
struct void_ write_file_1(struct ctx* ctx, char* path, struct str content);
uint32_t _shiftLeft(uint32_t a, uint32_t b);
struct comparison _compare_17(uint32_t a, uint32_t b);
struct comparison cmp_4(uint32_t a, uint32_t b);
uint8_t _less_13(uint32_t a, uint32_t b);
int32_t O_CREAT(void);
int32_t O_WRONLY(void);
int32_t O_TRUNC(void);
struct str to_str_7(struct ctx* ctx, uint32_t a);
struct interp with_value_3(struct ctx* ctx, struct interp a, uint32_t b);
uint8_t* ptr_cast_2(char* a);
int64_t to_int64(struct ctx* ctx, uint64_t a);
int64_t max_int64(void);
uint8_t is_empty_23(struct arr_14 a);
struct str remove_colors(struct ctx* ctx, struct str s);
struct void_ remove_colors_recur__e(struct ctx* ctx, struct str s, struct writer out);
struct void_ _concatEquals_10(struct ctx* ctx, struct writer a, char b);
struct arr_0 tail_8(struct ctx* ctx, struct arr_0 a);
struct void_ remove_colors_recur_2__e(struct ctx* ctx, struct str s, struct writer out);
struct opt_22 run_single_crow_test__lambda0(struct ctx* ctx, struct run_single_crow_test__lambda0* _closure, struct str print_kind);
struct arr_14 run_single_runnable_test(struct ctx* ctx, struct str path_to_crow, struct dict_1 env, struct str path, uint8_t interpret, uint8_t overwrite_output);
struct arr_14 _tilde_3(struct ctx* ctx, struct arr_14 a, struct arr_14 b);
struct arr_14 run_crow_tests__lambda0(struct ctx* ctx, struct run_crow_tests__lambda0* _closure, struct str test);
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
struct arr_14 lint_file(struct ctx* ctx, struct str path);
struct str read_file(struct ctx* ctx, struct str path);
struct void_ each_with_index_0(struct ctx* ctx, struct arr_2 a, struct fun_act2_15 f);
struct void_ each_with_index_recur_0(struct ctx* ctx, struct arr_2 a, struct fun_act2_15 f, uint64_t n);
struct void_ subscript_106(struct ctx* ctx, struct fun_act2_15 a, struct str p0, uint64_t p1);
struct void_ call_w_ctx_1267(struct fun_act2_15 a, struct ctx* ctx, struct str p0, uint64_t p1);
struct arr_2 lines(struct ctx* ctx, struct str s);
struct void_ each_with_index_1(struct ctx* ctx, struct arr_0 a, struct fun_act2_16 f);
struct void_ each_with_index_recur_1(struct ctx* ctx, struct arr_0 a, struct fun_act2_16 f, uint64_t n);
struct void_ subscript_107(struct ctx* ctx, struct fun_act2_16 a, char p0, uint64_t p1);
struct void_ call_w_ctx_1272(struct fun_act2_16 a, struct ctx* ctx, char p0, uint64_t p1);
uint64_t swap(struct cell_0* c, uint64_t v);
uint64_t _times_24(struct cell_0* a);
struct void_ set_deref_1(struct cell_0* a, uint64_t value);
struct void_ lines__lambda0(struct ctx* ctx, struct lines__lambda0* _closure, char c, uint64_t index);
uint64_t line_len(struct ctx* ctx, struct str line);
uint64_t n_tabs(struct ctx* ctx, struct str line);
uint64_t tab_size(struct ctx* ctx);
uint64_t max_line_length(struct ctx* ctx);
struct void_ lint_file__lambda0(struct ctx* ctx, struct lint_file__lambda0* _closure, struct str line, uint64_t line_num);
struct arr_14 lint__lambda0(struct ctx* ctx, struct lint__lambda0* _closure, struct str file);
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
char constantarr_0_15[27];
char constantarr_0_16[21];
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
char constantarr_0_166[22];
char constantarr_0_167[10];
char constantarr_0_168[3];
char constantarr_0_169[11];
char constantarr_0_170[4];
char constantarr_0_171[11];
char constantarr_0_172[4];
char constantarr_0_173[16];
char constantarr_0_174[21];
char constantarr_0_175[9];
char constantarr_0_176[35];
char constantarr_0_177[31];
char constantarr_0_178[34];
char constantarr_0_179[30];
char constantarr_0_180[23];
char constantarr_0_181[22];
char constantarr_0_182[31];
char constantarr_0_183[10];
char constantarr_0_184[21];
char constantarr_0_185[18];
char constantarr_0_186[27];
char constantarr_0_187[5];
char constantarr_0_188[21];
char constantarr_0_189[30];
char constantarr_0_190[9];
char constantarr_0_191[25];
char constantarr_0_192[15];
char constantarr_0_193[17];
char constantarr_0_194[26];
char constantarr_0_195[4];
char constantarr_0_196[22];
char constantarr_0_197[6];
char constantarr_0_198[10];
char constantarr_0_199[58];
char constantarr_0_200[10];
char constantarr_0_201[6];
char constantarr_0_202[34];
char constantarr_0_203[27];
char constantarr_0_204[21];
char constantarr_0_205[6];
char constantarr_0_206[8];
char constantarr_0_207[17];
char constantarr_0_208[10];
char constantarr_0_209[8];
char constantarr_0_210[17];
char constantarr_0_211[19];
char constantarr_0_212[6];
char constantarr_0_213[26];
char constantarr_0_214[11];
char constantarr_0_215[26];
char constantarr_0_216[14];
char constantarr_0_217[25];
char constantarr_0_218[20];
char constantarr_0_219[16];
char constantarr_0_220[13];
char constantarr_0_221[13];
char constantarr_0_222[5];
char constantarr_0_223[33];
char constantarr_0_224[14];
char constantarr_0_225[17];
char constantarr_0_226[15];
char constantarr_0_227[5];
char constantarr_0_228[10];
char constantarr_0_229[10];
char constantarr_0_230[9];
char constantarr_0_231[15];
char constantarr_0_232[10];
char constantarr_0_233[9];
char constantarr_0_234[6];
char constantarr_0_235[9];
char constantarr_0_236[6];
char constantarr_0_237[6];
char constantarr_0_238[14];
char constantarr_0_239[2];
char constantarr_0_240[8];
char constantarr_0_241[7];
char constantarr_0_242[13];
char constantarr_0_243[5];
char constantarr_0_244[16];
char constantarr_0_245[18];
char constantarr_0_246[20];
char constantarr_0_247[7];
char constantarr_0_248[4];
char constantarr_0_249[4];
char constantarr_0_250[11];
char constantarr_0_251[10];
char constantarr_0_252[5];
char constantarr_0_253[17];
char constantarr_0_254[18];
char constantarr_0_255[11];
char constantarr_0_256[7];
char constantarr_0_257[8];
char constantarr_0_258[10];
char constantarr_0_259[24];
char constantarr_0_260[6];
char constantarr_0_261[11];
char constantarr_0_262[8];
char constantarr_0_263[17];
char constantarr_0_264[21];
char constantarr_0_265[17];
char constantarr_0_266[18];
char constantarr_0_267[17];
char constantarr_0_268[26];
char constantarr_0_269[11];
char constantarr_0_270[19];
char constantarr_0_271[20];
char constantarr_0_272[7];
char constantarr_0_273[15];
char constantarr_0_274[19];
char constantarr_0_275[9];
char constantarr_0_276[13];
char constantarr_0_277[24];
char constantarr_0_278[40];
char constantarr_0_279[9];
char constantarr_0_280[12];
char constantarr_0_281[8];
char constantarr_0_282[14];
char constantarr_0_283[12];
char constantarr_0_284[8];
char constantarr_0_285[11];
char constantarr_0_286[23];
char constantarr_0_287[12];
char constantarr_0_288[5];
char constantarr_0_289[23];
char constantarr_0_290[9];
char constantarr_0_291[12];
char constantarr_0_292[11];
char constantarr_0_293[16];
char constantarr_0_294[2];
char constantarr_0_295[18];
char constantarr_0_296[8];
char constantarr_0_297[8];
char constantarr_0_298[9];
char constantarr_0_299[10];
char constantarr_0_300[10];
char constantarr_0_301[17];
char constantarr_0_302[8];
char constantarr_0_303[10];
char constantarr_0_304[8];
char constantarr_0_305[12];
char constantarr_0_306[12];
char constantarr_0_307[19];
char constantarr_0_308[21];
char constantarr_0_309[19];
char constantarr_0_310[7];
char constantarr_0_311[10];
char constantarr_0_312[10];
char constantarr_0_313[12];
char constantarr_0_314[8];
char constantarr_0_315[11];
char constantarr_0_316[10];
char constantarr_0_317[6];
char constantarr_0_318[2];
char constantarr_0_319[10];
char constantarr_0_320[14];
char constantarr_0_321[10];
char constantarr_0_322[16];
char constantarr_0_323[17];
char constantarr_0_324[28];
char constantarr_0_325[51];
char constantarr_0_326[32];
char constantarr_0_327[8];
char constantarr_0_328[20];
char constantarr_0_329[14];
char constantarr_0_330[9];
char constantarr_0_331[12];
char constantarr_0_332[15];
char constantarr_0_333[8];
char constantarr_0_334[9];
char constantarr_0_335[15];
char constantarr_0_336[14];
char constantarr_0_337[43];
char constantarr_0_338[6];
char constantarr_0_339[30];
char constantarr_0_340[4];
char constantarr_0_341[37];
char constantarr_0_342[5];
char constantarr_0_343[33];
char constantarr_0_344[12];
char constantarr_0_345[16];
char constantarr_0_346[12];
char constantarr_0_347[10];
char constantarr_0_348[9];
char constantarr_0_349[6];
char constantarr_0_350[18];
char constantarr_0_351[20];
char constantarr_0_352[6];
char constantarr_0_353[10];
char constantarr_0_354[16];
char constantarr_0_355[7];
char constantarr_0_356[8];
char constantarr_0_357[15];
char constantarr_0_358[14];
char constantarr_0_359[12];
char constantarr_0_360[37];
char constantarr_0_361[21];
char constantarr_0_362[18];
char constantarr_0_363[18];
char constantarr_0_364[8];
char constantarr_0_365[13];
char constantarr_0_366[12];
char constantarr_0_367[14];
char constantarr_0_368[24];
char constantarr_0_369[22];
char constantarr_0_370[5];
char constantarr_0_371[8];
char constantarr_0_372[19];
char constantarr_0_373[18];
char constantarr_0_374[20];
char constantarr_0_375[18];
char constantarr_0_376[16];
char constantarr_0_377[16];
char constantarr_0_378[11];
char constantarr_0_379[1];
char constantarr_0_380[2];
char constantarr_0_381[9];
char constantarr_0_382[24];
char constantarr_0_383[30];
char constantarr_0_384[1];
char constantarr_0_385[6];
char constantarr_0_386[11];
char constantarr_0_387[16];
char constantarr_0_388[8];
char constantarr_0_389[14];
char constantarr_0_390[7];
char constantarr_0_391[9];
char constantarr_0_392[12];
char constantarr_0_393[3];
char constantarr_0_394[24];
char constantarr_0_395[16];
char constantarr_0_396[4];
char constantarr_0_397[13];
char constantarr_0_398[17];
char constantarr_0_399[7];
char constantarr_0_400[21];
char constantarr_0_401[33];
char constantarr_0_402[8];
char constantarr_0_403[14];
char constantarr_0_404[12];
char constantarr_0_405[18];
char constantarr_0_406[17];
char constantarr_0_407[19];
char constantarr_0_408[28];
char constantarr_0_409[14];
char constantarr_0_410[18];
char constantarr_0_411[8];
char constantarr_0_412[14];
char constantarr_0_413[19];
char constantarr_0_414[16];
char constantarr_0_415[6];
char constantarr_0_416[7];
char constantarr_0_417[5];
char constantarr_0_418[14];
char constantarr_0_419[20];
char constantarr_0_420[29];
char constantarr_0_421[14];
char constantarr_0_422[11];
char constantarr_0_423[10];
char constantarr_0_424[9];
char constantarr_0_425[17];
char constantarr_0_426[8];
char constantarr_0_427[18];
char constantarr_0_428[14];
char constantarr_0_429[19];
char constantarr_0_430[18];
char constantarr_0_431[11];
char constantarr_0_432[11];
char constantarr_0_433[14];
char constantarr_0_434[13];
char constantarr_0_435[13];
char constantarr_0_436[7];
char constantarr_0_437[26];
char constantarr_0_438[8];
char constantarr_0_439[22];
char constantarr_0_440[29];
char constantarr_0_441[25];
char constantarr_0_442[23];
char constantarr_0_443[19];
char constantarr_0_444[24];
char constantarr_0_445[20];
char constantarr_0_446[10];
char constantarr_0_447[30];
char constantarr_0_448[3];
char constantarr_0_449[12];
char constantarr_0_450[23];
char constantarr_0_451[6];
char constantarr_0_452[12];
char constantarr_0_453[16];
char constantarr_0_454[8];
char constantarr_0_455[11];
char constantarr_0_456[15];
char constantarr_0_457[11];
char constantarr_0_458[11];
char constantarr_0_459[26];
char constantarr_0_460[7];
char constantarr_0_461[26];
char constantarr_0_462[2];
char constantarr_0_463[22];
char constantarr_0_464[30];
char constantarr_0_465[15];
char constantarr_0_466[83];
char constantarr_0_467[14];
char constantarr_0_468[16];
char constantarr_0_469[15];
char constantarr_0_470[15];
char constantarr_0_471[6];
char constantarr_0_472[22];
char constantarr_0_473[13];
char constantarr_0_474[15];
char constantarr_0_475[16];
char constantarr_0_476[5];
char constantarr_0_477[8];
char constantarr_0_478[12];
char constantarr_0_479[22];
char constantarr_0_480[28];
char constantarr_0_481[37];
char constantarr_0_482[5];
char constantarr_0_483[8];
char constantarr_0_484[14];
char constantarr_0_485[21];
char constantarr_0_486[16];
char constantarr_0_487[12];
char constantarr_0_488[20];
char constantarr_0_489[21];
char constantarr_0_490[23];
char constantarr_0_491[21];
char constantarr_0_492[16];
char constantarr_0_493[29];
char constantarr_0_494[18];
char constantarr_0_495[5];
char constantarr_0_496[7];
char constantarr_0_497[24];
char constantarr_0_498[18];
char constantarr_0_499[10];
char constantarr_0_500[17];
char constantarr_0_501[12];
char constantarr_0_502[7];
char constantarr_0_503[27];
char constantarr_0_504[8];
char constantarr_0_505[15];
char constantarr_0_506[4];
char constantarr_0_507[10];
char constantarr_0_508[12];
char constantarr_0_509[4];
char constantarr_0_510[10];
char constantarr_0_511[4];
char constantarr_0_512[4];
char constantarr_0_513[8];
char constantarr_0_514[21];
char constantarr_0_515[4];
char constantarr_0_516[12];
char constantarr_0_517[8];
char constantarr_0_518[5];
char constantarr_0_519[22];
char constantarr_0_520[10];
char constantarr_0_521[18];
char constantarr_0_522[22];
char constantarr_0_523[12];
char constantarr_0_524[8];
char constantarr_0_525[20];
char constantarr_0_526[17];
char constantarr_0_527[4];
char constantarr_0_528[12];
char constantarr_0_529[9];
char constantarr_0_530[11];
char constantarr_0_531[27];
char constantarr_0_532[16];
char constantarr_0_533[13];
char constantarr_0_534[4];
char constantarr_0_535[7];
char constantarr_0_536[7];
char constantarr_0_537[7];
char constantarr_0_538[8];
char constantarr_0_539[15];
char constantarr_0_540[21];
char constantarr_0_541[6];
char constantarr_0_542[23];
char constantarr_0_543[21];
char constantarr_0_544[10];
char constantarr_0_545[34];
char constantarr_0_546[10];
char constantarr_0_547[34];
char constantarr_0_548[26];
char constantarr_0_549[9];
char constantarr_0_550[23];
char constantarr_0_551[14];
char constantarr_0_552[23];
char constantarr_0_553[17];
char constantarr_0_554[6];
char constantarr_0_555[30];
char constantarr_0_556[30];
char constantarr_0_557[22];
char constantarr_0_558[24];
char constantarr_0_559[24];
char constantarr_0_560[20];
char constantarr_0_561[9];
char constantarr_0_562[5];
char constantarr_0_563[14];
char constantarr_0_564[21];
char constantarr_0_565[11];
char constantarr_0_566[36];
char constantarr_0_567[25];
char constantarr_0_568[13];
char constantarr_0_569[17];
char constantarr_0_570[23];
char constantarr_0_571[9];
char constantarr_0_572[19];
char constantarr_0_573[13];
char constantarr_0_574[33];
char constantarr_0_575[30];
char constantarr_0_576[22];
char constantarr_0_577[24];
char constantarr_0_578[26];
char constantarr_0_579[17];
char constantarr_0_580[14];
char constantarr_0_581[32];
char constantarr_0_582[21];
char constantarr_0_583[84];
char constantarr_0_584[11];
char constantarr_0_585[45];
char constantarr_0_586[19];
char constantarr_0_587[22];
char constantarr_0_588[30];
char constantarr_0_589[11];
char constantarr_0_590[17];
char constantarr_0_591[14];
char constantarr_0_592[9];
char constantarr_0_593[6];
char constantarr_0_594[14];
char constantarr_0_595[15];
char constantarr_0_596[44];
char constantarr_0_597[10];
char constantarr_0_598[19];
char constantarr_0_599[15];
char constantarr_0_600[21];
char constantarr_0_601[12];
char constantarr_0_602[18];
char constantarr_0_603[14];
char constantarr_0_604[28];
char constantarr_0_605[16];
char constantarr_0_606[11];
char constantarr_0_607[8];
char constantarr_0_608[17];
char constantarr_0_609[25];
char constantarr_0_610[12];
char constantarr_0_611[11];
char constantarr_0_612[17];
char constantarr_0_613[26];
char constantarr_0_614[14];
char constantarr_0_615[8];
char constantarr_0_616[13];
char constantarr_0_617[26];
char constantarr_0_618[11];
char constantarr_0_619[14];
char constantarr_0_620[6];
char constantarr_0_621[7];
char constantarr_0_622[11];
char constantarr_0_623[22];
char constantarr_0_624[17];
char constantarr_0_625[14];
char constantarr_0_626[21];
char constantarr_0_627[32];
char constantarr_0_628[7];
char constantarr_0_629[7];
char constantarr_0_630[9];
char constantarr_0_631[27];
char constantarr_0_632[28];
char constantarr_0_633[19];
char constantarr_0_634[9];
char constantarr_0_635[5];
char constantarr_0_636[11];
char constantarr_0_637[11];
char constantarr_0_638[14];
char constantarr_0_639[18];
char constantarr_0_640[10];
char constantarr_0_641[11];
char constantarr_0_642[11];
char constantarr_0_643[40];
char constantarr_0_644[10];
char constantarr_0_645[21];
char constantarr_0_646[11];
char constantarr_0_647[9];
char constantarr_0_648[8];
char constantarr_0_649[10];
char constantarr_0_650[15];
char constantarr_0_651[28];
char constantarr_0_652[7];
char constantarr_0_653[11];
char constantarr_0_654[10];
char constantarr_0_655[6];
char constantarr_0_656[12];
char constantarr_0_657[35];
char constantarr_0_658[37];
char constantarr_0_659[7];
char constantarr_0_660[29];
char constantarr_0_661[10];
char constantarr_0_662[13];
char constantarr_0_663[12];
char constantarr_0_664[46];
char constantarr_0_665[12];
char constantarr_0_666[8];
char constantarr_0_667[20];
char constantarr_0_668[8];
char constantarr_0_669[13];
char constantarr_0_670[20];
char constantarr_0_671[15];
char constantarr_0_672[17];
char constantarr_0_673[16];
char constantarr_0_674[7];
char constantarr_0_675[17];
char constantarr_0_676[11];
char constantarr_0_677[10];
char constantarr_0_678[22];
char constantarr_0_679[16];
char constantarr_0_680[9];
char constantarr_0_681[9];
char constantarr_0_682[18];
char constantarr_0_683[15];
char constantarr_0_684[31];
char constantarr_0_685[19];
char constantarr_0_686[12];
char constantarr_0_687[31];
char constantarr_0_688[6];
char constantarr_0_689[5];
char constantarr_0_690[16];
char constantarr_0_691[21];
char constantarr_0_692[4];
char constantarr_0_693[35];
char constantarr_0_694[17];
char constantarr_0_695[25];
char constantarr_0_696[21];
char constantarr_0_697[24];
char constantarr_0_698[20];
char constantarr_0_699[24];
char constantarr_0_700[4];
char constantarr_0_701[15];
char constantarr_0_702[16];
char constantarr_0_703[21];
char constantarr_0_704[15];
char constantarr_0_705[19];
char constantarr_0_706[18];
char constantarr_0_707[11];
char constantarr_0_708[15];
char constantarr_0_709[14];
char constantarr_0_710[17];
char constantarr_0_711[29];
char constantarr_0_712[14];
char constantarr_0_713[9];
char constantarr_0_714[17];
char constantarr_0_715[16];
char constantarr_0_716[19];
char constantarr_0_717[10];
char constantarr_0_718[14];
char constantarr_0_719[23];
char constantarr_0_720[7];
char constantarr_0_721[15];
char constantarr_0_722[18];
char constantarr_0_723[8];
char constantarr_0_724[24];
char constantarr_0_725[14];
char constantarr_0_726[10];
char constantarr_0_727[27];
char constantarr_0_728[24];
char constantarr_0_729[15];
char constantarr_0_730[31];
char constantarr_0_731[10];
char constantarr_0_732[27];
char constantarr_0_733[14];
char constantarr_0_734[29];
char constantarr_0_735[23];
char constantarr_0_736[14];
char constantarr_0_737[26];
char constantarr_0_738[22];
char constantarr_0_739[10];
char constantarr_0_740[8];
char constantarr_0_741[16];
char constantarr_0_742[22];
char constantarr_0_743[12];
char constantarr_0_744[9];
char constantarr_0_745[9];
char constantarr_0_746[30];
char constantarr_0_747[28];
char constantarr_0_748[42];
char constantarr_0_749[21];
char constantarr_0_750[42];
char constantarr_0_751[27];
char constantarr_0_752[30];
char constantarr_0_753[24];
char constantarr_0_754[11];
char constantarr_0_755[15];
char constantarr_0_756[29];
char constantarr_0_757[29];
char constantarr_0_758[25];
char constantarr_0_759[11];
char constantarr_0_760[13];
char constantarr_0_761[19];
char constantarr_0_762[15];
char constantarr_0_763[27];
char constantarr_0_764[13];
char constantarr_0_765[7];
char constantarr_0_766[10];
char constantarr_0_767[4];
char constantarr_0_768[19];
char constantarr_0_769[15];
char constantarr_0_770[26];
char constantarr_0_771[20];
char constantarr_0_772[10];
char constantarr_0_773[20];
char constantarr_0_774[27];
char constantarr_0_775[17];
char constantarr_0_776[31];
char constantarr_0_777[4];
char constantarr_0_778[14];
char constantarr_0_779[20];
char constantarr_0_780[24];
char constantarr_0_781[22];
char constantarr_0_782[28];
char constantarr_0_783[14];
char constantarr_0_784[25];
char constantarr_0_785[16];
char constantarr_0_786[22];
char constantarr_0_787[38];
char constantarr_0_788[8];
char constantarr_0_789[19];
char constantarr_0_790[10];
char constantarr_0_791[23];
char constantarr_0_792[34];
char constantarr_0_793[25];
char constantarr_0_794[14];
char constantarr_0_795[21];
char constantarr_0_796[13];
char constantarr_0_797[9];
char constantarr_0_798[9];
char constantarr_0_799[27];
char constantarr_0_800[30];
char constantarr_0_801[22];
char constantarr_0_802[28];
char constantarr_0_803[18];
char constantarr_0_804[29];
char constantarr_0_805[33];
char constantarr_0_806[23];
char constantarr_0_807[31];
char constantarr_0_808[20];
char constantarr_0_809[8];
char constantarr_0_810[37];
char constantarr_0_811[8];
char constantarr_0_812[26];
char constantarr_0_813[12];
char constantarr_0_814[8];
char constantarr_0_815[5];
char constantarr_0_816[28];
char constantarr_0_817[15];
char constantarr_0_818[23];
char constantarr_0_819[10];
char constantarr_0_820[19];
char constantarr_0_821[16];
char constantarr_0_822[16];
char constantarr_0_823[44];
char constantarr_0_824[19];
char constantarr_0_825[10];
char constantarr_0_826[10];
char constantarr_0_827[31];
char constantarr_0_828[32];
char constantarr_0_829[24];
char constantarr_0_830[32];
char constantarr_0_831[11];
char constantarr_0_832[19];
char constantarr_0_833[31];
char constantarr_0_834[20];
char constantarr_0_835[16];
char constantarr_0_836[5];
char constantarr_0_837[18];
char constantarr_0_838[10];
char constantarr_0_839[21];
char constantarr_0_840[28];
char constantarr_0_841[8];
char constantarr_0_842[27];
char constantarr_0_843[21];
char constantarr_0_844[25];
char constantarr_0_845[25];
char constantarr_0_846[10];
char constantarr_0_847[4];
char constantarr_0_848[4];
char constantarr_0_849[14];
char constantarr_0_850[6];
char constantarr_0_851[22];
char constantarr_0_852[33];
char constantarr_0_853[32];
char constantarr_0_854[27];
char constantarr_0_855[17];
char constantarr_0_856[14];
char constantarr_0_857[20];
char constantarr_0_858[14];
char constantarr_0_859[22];
char constantarr_0_860[36];
char constantarr_0_861[17];
char constantarr_0_862[9];
char constantarr_0_863[21];
char constantarr_0_864[14];
char constantarr_0_865[15];
char constantarr_0_866[21];
char constantarr_0_867[27];
char constantarr_0_868[5];
char constantarr_0_869[13];
char constantarr_0_870[9];
char constantarr_0_871[15];
char constantarr_0_872[18];
char constantarr_0_873[18];
char constantarr_0_874[6];
char constantarr_0_875[5];
char constantarr_0_876[15];
char constantarr_0_877[8];
char constantarr_0_878[6];
char constantarr_0_879[24];
char constantarr_0_880[28];
char constantarr_0_881[24];
char constantarr_0_882[24];
char constantarr_0_883[27];
char constantarr_0_884[10];
char constantarr_0_885[12];
char constantarr_0_886[9];
char constantarr_0_887[18];
char constantarr_0_888[6];
char constantarr_0_889[25];
char constantarr_0_890[3];
char constantarr_0_891[3];
char constantarr_0_892[9];
char constantarr_0_893[13];
char constantarr_0_894[4];
char constantarr_0_895[10];
char constantarr_0_896[5];
char constantarr_0_897[7];
char constantarr_0_898[15];
char constantarr_0_899[17];
char constantarr_0_900[7];
char constantarr_0_901[11];
char constantarr_0_902[16];
char constantarr_0_903[14];
char constantarr_0_904[20];
char constantarr_0_905[24];
char constantarr_0_906[10];
char constantarr_0_907[11];
char constantarr_0_908[18];
char constantarr_0_909[17];
char constantarr_0_910[10];
char constantarr_0_911[7];
char constantarr_0_912[19];
char constantarr_0_913[21];
char constantarr_0_914[12];
char constantarr_0_915[23];
char constantarr_0_916[14];
char constantarr_0_917[12];
char constantarr_0_918[7];
char constantarr_0_919[23];
char constantarr_0_920[18];
char constantarr_0_921[14];
char constantarr_0_922[36];
char constantarr_0_923[7];
char constantarr_0_924[10];
char constantarr_0_925[14];
char constantarr_0_926[10];
char constantarr_0_927[13];
char constantarr_0_928[20];
char constantarr_0_929[23];
char constantarr_0_930[28];
char constantarr_0_931[6];
char constantarr_0_932[8];
char constantarr_0_933[4];
char constantarr_0_934[10];
char constantarr_0_935[5];
char constantarr_0_936[8];
char constantarr_0_937[16];
char constantarr_0_938[6];
char constantarr_0_939[15];
char constantarr_0_940[11];
char constantarr_0_941[27];
char constantarr_0_942[7];
char constantarr_0_943[6];
char constantarr_0_944[7];
char constantarr_0_945[9];
char constantarr_0_946[8];
char constantarr_0_947[7];
char constantarr_0_948[19];
char constantarr_0_949[28];
char constantarr_0_950[42];
char constantarr_0_951[21];
char constantarr_0_952[14];
char constantarr_0_953[6];
char constantarr_0_954[8];
char constantarr_0_955[12];
char constantarr_0_956[9];
char constantarr_0_957[19];
char constantarr_0_958[24];
char constantarr_0_959[9];
char constantarr_0_960[14];
char constantarr_0_961[15];
char constantarr_0_962[14];
char constantarr_0_963[14];
char constantarr_0_964[7];
char constantarr_0_965[20];
char constantarr_0_966[7];
char constantarr_0_967[7];
char constantarr_0_968[9];
char constantarr_0_969[17];
char constantarr_0_970[17];
char constantarr_0_971[10];
char constantarr_0_972[21];
char constantarr_0_973[18];
char constantarr_0_974[24];
char constantarr_0_975[11];
char constantarr_0_976[14];
char constantarr_0_977[13];
char constantarr_0_978[13];
char constantarr_0_979[10];
char constantarr_0_980[7];
char constantarr_0_981[11];
char constantarr_0_982[9];
char constantarr_0_983[18];
char constantarr_0_984[10];
char constantarr_0_985[36];
char constantarr_0_986[13];
char constantarr_0_987[9];
char constantarr_0_988[7];
char constantarr_0_989[15];
char constantarr_0_990[23];
char constantarr_0_991[30];
char constantarr_0_992[12];
char constantarr_0_993[7];
char constantarr_0_994[44];
char constantarr_0_995[17];
char constantarr_0_996[20];
char constantarr_0_997[29];
char constantarr_0_998[23];
char constantarr_0_999[13];
char constantarr_0_1000[14];
char constantarr_0_1001[21];
char constantarr_0_1002[14];
char constantarr_0_1003[29];
char constantarr_0_1004[7];
char constantarr_0_1005[7];
char constantarr_0_1006[10];
char constantarr_0_1007[5];
char constantarr_0_1008[17];
char constantarr_0_1009[4];
char constantarr_0_1010[26];
char constantarr_0_1011[29];
char constantarr_0_1012[33];
char constantarr_0_1013[10];
char constantarr_0_1014[32];
char constantarr_0_1015[9];
char constantarr_0_1016[11];
char constantarr_0_1017[11];
char constantarr_0_1018[5];
char constantarr_0_1019[12];
char constantarr_0_1020[23];
char constantarr_0_1021[31];
char constantarr_0_1022[23];
char constantarr_0_1023[6];
char constantarr_0_1024[6];
char constantarr_0_1025[21];
char constantarr_0_1026[15];
char constantarr_0_1027[13];
char constantarr_0_1028[13];
char constantarr_0_1029[4];
char constantarr_0_1030[14];
char constantarr_0_1031[7];
char constantarr_0_1032[10];
char constantarr_0_1033[14];
char constantarr_0_1034[9];
char constantarr_0_1035[24];
char constantarr_0_1036[22];
char constantarr_0_1037[4];
char constantarr_0_1038[8];
char constantarr_0_1039[10];
char constantarr_0_1040[8];
char constantarr_0_1041[2];
char constantarr_0_1042[11];
char constantarr_0_1043[7];
char constantarr_0_1044[11];
char constantarr_0_1045[7];
char constantarr_0_1046[11];
char constantarr_0_1047[7];
char constantarr_0_1048[11];
char constantarr_0_1049[7];
char constantarr_0_1050[12];
char constantarr_0_1051[8];
char constantarr_0_1052[21];
char constantarr_0_1053[3];
char constantarr_0_1054[10];
char constantarr_0_1055[7];
char constantarr_0_1056[22];
char constantarr_0_1057[7];
char constantarr_0_1058[9];
char constantarr_0_1059[8];
char constantarr_0_1060[11];
char constantarr_0_1061[2];
char constantarr_0_1062[10];
char constantarr_0_1063[8];
char constantarr_0_1064[11];
char constantarr_0_1065[22];
char constantarr_0_1066[11];
char constantarr_0_1067[7];
char constantarr_0_1068[12];
char constantarr_0_1069[3];
char constantarr_0_1070[3];
char constantarr_0_1071[17];
char constantarr_0_1072[10];
char constantarr_0_1073[12];
char constantarr_0_1074[14];
char constantarr_0_1075[12];
char constantarr_0_1076[18];
char constantarr_0_1077[25];
char constantarr_0_1078[33];
char constantarr_0_1079[20];
char constantarr_0_1080[15];
char constantarr_0_1081[25];
char constantarr_0_1082[14];
char constantarr_0_1083[22];
char constantarr_0_1084[19];
char constantarr_0_1085[23];
char constantarr_0_1086[19];
char constantarr_0_1087[29];
char constantarr_0_1088[21];
char constantarr_0_1089[9];
char constantarr_0_1090[16];
char constantarr_0_1091[13];
char constantarr_0_1092[13];
char constantarr_0_1093[4];
char constantarr_0_1094[8];
char constantarr_0_1095[14];
char constantarr_0_1096[5];
char constantarr_0_1097[8];
char constantarr_0_1098[8];
char constantarr_0_1099[20];
char constantarr_0_1100[10];
char constantarr_0_1101[9];
char constantarr_0_1102[1];
char constantarr_0_1103[2];
char constantarr_0_1104[10];
char constantarr_0_1105[8];
char constantarr_0_1106[15];
char constantarr_0_1107[21];
char constantarr_0_1108[7];
char constantarr_0_1109[8];
char constantarr_0_1110[7];
char constantarr_0_1111[17];
char constantarr_0_1112[9];
char constantarr_0_1113[7];
char constantarr_0_1114[17];
char constantarr_0_1115[17];
char constantarr_0_1116[13];
char constantarr_0_1117[20];
char constantarr_0_1118[10];
char constantarr_0_1119[22];
char constantarr_0_1120[11];
char constantarr_0_1121[18];
char constantarr_0_1122[8];
char constantarr_0_1123[28];
char constantarr_0_1124[24];
char constantarr_0_1125[10];
char constantarr_0_1126[22];
char constantarr_0_1127[17];
char constantarr_0_1128[17];
char constantarr_0_1129[23];
char constantarr_0_1130[15];
char constantarr_0_1131[4];
char constantarr_0_1132[19];
char constantarr_0_1133[18];
char constantarr_0_1134[7];
char constantarr_0_1135[11];
char constantarr_0_1136[9];
char constantarr_0_1137[15];
char constantarr_0_1138[26];
char constantarr_0_1139[27];
char constantarr_0_1140[31];
char constantarr_0_1141[23];
char constantarr_0_1142[18];
char constantarr_0_1143[27];
char constantarr_0_1144[9];
char constantarr_0_1145[9];
char constantarr_0_1146[20];
char constantarr_0_1147[24];
char constantarr_0_1148[25];
char constantarr_0_1149[5];
char constantarr_0_1150[11];
char constantarr_0_1151[21];
char constantarr_0_1152[11];
char constantarr_0_1153[13];
char constantarr_0_1154[8];
char constantarr_0_1155[6];
char constantarr_0_1156[8];
char constantarr_0_1157[15];
char constantarr_0_1158[17];
char constantarr_0_1159[12];
char constantarr_0_1160[15];
char constantarr_0_1161[14];
char constantarr_0_1162[19];
char constantarr_0_1163[13];
char constantarr_0_1164[10];
char constantarr_0_1165[4];
char constantarr_0_1166[11];
char constantarr_0_1167[22];
char constantarr_0_1168[12];
char constantarr_0_1169[11];
struct str constantarr_2_0[4];
struct str constantarr_2_1[4];
struct str constantarr_2_2[11];
struct str constantarr_2_3[5];
struct str constantarr_2_4[6];
struct named_val constantarr_5_0[1113];
struct sym constantarr_1_0[398];
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
char constantarr_0_15[27] = "tried to force empty option";
char constantarr_0_16[21] = "should be unreachable";
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
char constantarr_0_166[22] = "as<by-val<global-ctx>>";
char constantarr_0_167[10] = "global-ctx";
char constantarr_0_168[3] = "lbv";
char constantarr_0_169[11] = "lock-by-val";
char constantarr_0_170[4] = "lock";
char constantarr_0_171[11] = "atomic-bool";
char constantarr_0_172[4] = "none";
char constantarr_0_173[16] = "create-condition";
char constantarr_0_174[21] = "as<by-val<condition>>";
char constantarr_0_175[9] = "condition";
char constantarr_0_176[35] = "zeroed<by-val<pthread_mutexattr_t>>";
char constantarr_0_177[31] = "zeroed<by-val<pthread_mutex_t>>";
char constantarr_0_178[34] = "zeroed<by-val<pthread_condattr_t>>";
char constantarr_0_179[30] = "zeroed<by-val<pthread_cond_t>>";
char constantarr_0_180[23] = "hard-assert-posix-error";
char constantarr_0_181[22] = "pthread_mutexattr_init";
char constantarr_0_182[31] = "ref-of-val<pthread_mutexattr_t>";
char constantarr_0_183[10] = "mutex-attr";
char constantarr_0_184[21] = "ref-of-val<condition>";
char constantarr_0_185[18] = "pthread_mutex_init";
char constantarr_0_186[27] = "ref-of-val<pthread_mutex_t>";
char constantarr_0_187[5] = "mutex";
char constantarr_0_188[21] = "pthread_condattr_init";
char constantarr_0_189[30] = "ref-of-val<pthread_condattr_t>";
char constantarr_0_190[9] = "cond-attr";
char constantarr_0_191[25] = "pthread_condattr_setclock";
char constantarr_0_192[15] = "CLOCK_MONOTONIC";
char constantarr_0_193[17] = "pthread_cond_init";
char constantarr_0_194[26] = "ref-of-val<pthread_cond_t>";
char constantarr_0_195[4] = "cond";
char constantarr_0_196[22] = "ref-of-val<global-ctx>";
char constantarr_0_197[6] = "island";
char constantarr_0_198[10] = "task-queue";
char constantarr_0_199[58] = "mut-list-by-val-with-capacity-from-unmanaged-memory<nat64>";
char constantarr_0_200[10] = "mut-arr<a>";
char constantarr_0_201[6] = "arr<a>";
char constantarr_0_202[34] = "unmanaged-alloc-zeroed-elements<a>";
char constantarr_0_203[27] = "unmanaged-alloc-elements<a>";
char constantarr_0_204[21] = "unmanaged-alloc-bytes";
char constantarr_0_205[6] = "malloc";
char constantarr_0_206[8] = "==<nat8>";
char constantarr_0_207[17] = "!=<mut-ptr<nat8>>";
char constantarr_0_208[10] = "null<nat8>";
char constantarr_0_209[8] = "wrap-mul";
char constantarr_0_210[17] = "set-zero-range<a>";
char constantarr_0_211[19] = "drop<mut-ptr<nat8>>";
char constantarr_0_212[6] = "memset";
char constantarr_0_213[26] = "as-any-mut-ptr<mut-ptr<a>>";
char constantarr_0_214[11] = "mut-list<a>";
char constantarr_0_215[26] = "as<by-val<island-gc-root>>";
char constantarr_0_216[14] = "island-gc-root";
char constantarr_0_217[25] = "default-exception-handler";
char constantarr_0_218[20] = "print-err-no-newline";
char constantarr_0_219[16] = "write-no-newline";
char constantarr_0_220[13] = "size-of<char>";
char constantarr_0_221[13] = "size-of<nat8>";
char constantarr_0_222[5] = "write";
char constantarr_0_223[33] = "as-any-const-ptr<const-ptr<char>>";
char constantarr_0_224[14] = "as-const<nat8>";
char constantarr_0_225[17] = "as-any-mut-ptr<a>";
char constantarr_0_226[15] = "begin-ptr<char>";
char constantarr_0_227[5] = "chars";
char constantarr_0_228[10] = "size-bytes";
char constantarr_0_229[10] = "size<char>";
char constantarr_0_230[9] = "!=<int64>";
char constantarr_0_231[15] = "unsafe-to-int64";
char constantarr_0_232[10] = "todo<void>";
char constantarr_0_233[9] = "zeroed<a>";
char constantarr_0_234[6] = "stderr";
char constantarr_0_235[9] = "print-err";
char constantarr_0_236[6] = "to-str";
char constantarr_0_237[6] = "writer";
char constantarr_0_238[14] = "mut-list<char>";
char constantarr_0_239[2] = "~=";
char constantarr_0_240[8] = "~=<char>";
char constantarr_0_241[7] = "each<a>";
char constantarr_0_242[13] = "each-recur<a>";
char constantarr_0_243[5] = "==<a>";
char constantarr_0_244[16] = "!=<const-ptr<a>>";
char constantarr_0_245[18] = "subscript<void, a>";
char constantarr_0_246[20] = "call-with-ctx<r, p0>";
char constantarr_0_247[7] = "get-ctx";
char constantarr_0_248[4] = "*<a>";
char constantarr_0_249[4] = "+<a>";
char constantarr_0_250[11] = "as-const<a>";
char constantarr_0_251[10] = "end-ptr<a>";
char constantarr_0_252[5] = "~=<a>";
char constantarr_0_253[17] = "incr-capacity!<a>";
char constantarr_0_254[18] = "ensure-capacity<a>";
char constantarr_0_255[11] = "capacity<a>";
char constantarr_0_256[7] = "size<a>";
char constantarr_0_257[8] = "inner<a>";
char constantarr_0_258[10] = "backing<a>";
char constantarr_0_259[24] = "increase-capacity-to!<a>";
char constantarr_0_260[6] = "assert";
char constantarr_0_261[11] = "throw<void>";
char constantarr_0_262[8] = "throw<a>";
char constantarr_0_263[17] = "get-exception-ctx";
char constantarr_0_264[21] = "as-ref<exception-ctx>";
char constantarr_0_265[17] = "exception-ctx-ptr";
char constantarr_0_266[18] = "thread-local-stuff";
char constantarr_0_267[17] = "==<__jmp_buf_tag>";
char constantarr_0_268[26] = "!=<mut-ptr<__jmp_buf_tag>>";
char constantarr_0_269[11] = "jmp-buf-ptr";
char constantarr_0_270[19] = "null<__jmp_buf_tag>";
char constantarr_0_271[20] = "set-thrown-exception";
char constantarr_0_272[7] = "longjmp";
char constantarr_0_273[15] = "number-to-throw";
char constantarr_0_274[19] = "hard-unreachable<a>";
char constantarr_0_275[9] = "exception";
char constantarr_0_276[13] = "get-backtrace";
char constantarr_0_277[24] = "try-alloc-backtrace-arrs";
char constantarr_0_278[40] = "try-alloc-uninitialized<const-ptr<nat8>>";
char constantarr_0_279[9] = "try-alloc";
char constantarr_0_280[12] = "try-gc-alloc";
char constantarr_0_281[8] = "acquire!";
char constantarr_0_282[14] = "acquire-recur!";
char constantarr_0_283[12] = "try-acquire!";
char constantarr_0_284[8] = "try-set!";
char constantarr_0_285[11] = "try-change!";
char constantarr_0_286[23] = "compare-exchange-strong";
char constantarr_0_287[12] = "ptr-to<bool>";
char constantarr_0_288[5] = "value";
char constantarr_0_289[23] = "ref-of-val<atomic-bool>";
char constantarr_0_290[9] = "is-locked";
char constantarr_0_291[12] = "yield-thread";
char constantarr_0_292[11] = "sched_yield";
char constantarr_0_293[16] = "ref-of-val<lock>";
char constantarr_0_294[2] = "lk";
char constantarr_0_295[18] = "try-gc-alloc-recur";
char constantarr_0_296[8] = "data-cur";
char constantarr_0_297[8] = "+<nat64>";
char constantarr_0_298[9] = "==<nat64>";
char constantarr_0_299[10] = "<=><nat64>";
char constantarr_0_300[10] = "is-less<a>";
char constantarr_0_301[17] = "<<mut-ptr<nat64>>";
char constantarr_0_302[8] = "data-end";
char constantarr_0_303[10] = "range-free";
char constantarr_0_304[8] = "mark-cur";
char constantarr_0_305[12] = "set-mark-cur";
char constantarr_0_306[12] = "set-data-cur";
char constantarr_0_307[19] = "some<mut-ptr<nat8>>";
char constantarr_0_308[21] = "ptr-cast<nat8, nat64>";
char constantarr_0_309[19] = "maybe-set-needs-gc!";
char constantarr_0_310[7] = "-<bool>";
char constantarr_0_311[10] = "mark-begin";
char constantarr_0_312[10] = "size-words";
char constantarr_0_313[12] = "set-needs-gc";
char constantarr_0_314[8] = "release!";
char constantarr_0_315[11] = "must-unset!";
char constantarr_0_316[10] = "try-unset!";
char constantarr_0_317[6] = "get-gc";
char constantarr_0_318[2] = "gc";
char constantarr_0_319[10] = "get-gc-ctx";
char constantarr_0_320[14] = "as-ref<gc-ctx>";
char constantarr_0_321[10] = "gc-ctx-ptr";
char constantarr_0_322[16] = "some<mut-ptr<a>>";
char constantarr_0_323[17] = "ptr-cast<a, nat8>";
char constantarr_0_324[28] = "try-alloc-uninitialized<sym>";
char constantarr_0_325[51] = "try-alloc-uninitialized<named-val<const-ptr<nat8>>>";
char constantarr_0_326[32] = "size<named-val<const-ptr<nat8>>>";
char constantarr_0_327[8] = "all-funs";
char constantarr_0_328[20] = "some<backtrace-arrs>";
char constantarr_0_329[14] = "backtrace-arrs";
char constantarr_0_330[9] = "backtrace";
char constantarr_0_331[12] = "as<arr<sym>>";
char constantarr_0_332[15] = "unsafe-to-nat64";
char constantarr_0_333[8] = "to-int64";
char constantarr_0_334[9] = "code-ptrs";
char constantarr_0_335[15] = "unsafe-to-int32";
char constantarr_0_336[14] = "code-ptrs-size";
char constantarr_0_337[43] = "copy-data-from!<named-val<const-ptr<nat8>>>";
char constantarr_0_338[6] = "memcpy";
char constantarr_0_339[30] = "as-any-const-ptr<const-ptr<a>>";
char constantarr_0_340[4] = "funs";
char constantarr_0_341[37] = "begin-ptr<named-val<const-ptr<nat8>>>";
char constantarr_0_342[5] = "sort!";
char constantarr_0_343[33] = "swap!<named-val<const-ptr<nat8>>>";
char constantarr_0_344[12] = "subscript<a>";
char constantarr_0_345[16] = "set-subscript<a>";
char constantarr_0_346[12] = "set-deref<a>";
char constantarr_0_347[10] = "partition!";
char constantarr_0_348[9] = "<=><nat8>";
char constantarr_0_349[6] = "<=><a>";
char constantarr_0_350[18] = "<<const-ptr<nat8>>";
char constantarr_0_351[20] = "val<const-ptr<nat8>>";
char constantarr_0_352[6] = "+<sym>";
char constantarr_0_353[10] = "code-names";
char constantarr_0_354[16] = "fill-code-names!";
char constantarr_0_355[7] = "==<sym>";
char constantarr_0_356[8] = "<=><sym>";
char constantarr_0_357[15] = "<<mut-ptr<sym>>";
char constantarr_0_358[14] = "set-deref<sym>";
char constantarr_0_359[12] = "get-fun-name";
char constantarr_0_360[37] = "subscript<named-val<const-ptr<nat8>>>";
char constantarr_0_361[21] = "name<const-ptr<nat8>>";
char constantarr_0_362[18] = "*<const-ptr<nat8>>";
char constantarr_0_363[18] = "+<const-ptr<nat8>>";
char constantarr_0_364[8] = "arr<sym>";
char constantarr_0_365[13] = "as-const<sym>";
char constantarr_0_366[12] = "begin-ptr<a>";
char constantarr_0_367[14] = "set-backing<a>";
char constantarr_0_368[24] = "uninitialized-mut-arr<a>";
char constantarr_0_369[22] = "alloc-uninitialized<a>";
char constantarr_0_370[5] = "alloc";
char constantarr_0_371[8] = "gc-alloc";
char constantarr_0_372[19] = "todo<mut-ptr<nat8>>";
char constantarr_0_373[18] = "copy-data-from!<a>";
char constantarr_0_374[20] = "set-zero-elements<a>";
char constantarr_0_375[18] = "from<nat64, nat64>";
char constantarr_0_376[16] = "to<nat64, nat64>";
char constantarr_0_377[16] = "-><nat64, nat64>";
char constantarr_0_378[11] = "arrow<a, b>";
char constantarr_0_379[1] = "+";
char constantarr_0_380[2] = "&&";
char constantarr_0_381[9] = ">=<nat64>";
char constantarr_0_382[24] = "round-up-to-power-of-two";
char constantarr_0_383[30] = "round-up-to-power-of-two-recur";
char constantarr_0_384[1] = "*";
char constantarr_0_385[6] = "forbid";
char constantarr_0_386[11] = "set-size<a>";
char constantarr_0_387[16] = "~=<char>.lambda0";
char constantarr_0_388[8] = "is-empty";
char constantarr_0_389[14] = "is-empty<char>";
char constantarr_0_390[7] = "message";
char constantarr_0_391[9] = "each<sym>";
char constantarr_0_392[12] = "return-stack";
char constantarr_0_393[3] = "str";
char constantarr_0_394[24] = "arr-from-begin-end<char>";
char constantarr_0_395[16] = "<=<const-ptr<a>>";
char constantarr_0_396[4] = "<<a>";
char constantarr_0_397[13] = "find-cstr-end";
char constantarr_0_398[17] = "find-char-in-cstr";
char constantarr_0_399[7] = "to-nat8";
char constantarr_0_400[21] = "some<const-ptr<char>>";
char constantarr_0_401[33] = "hard-unreachable<const-ptr<char>>";
char constantarr_0_402[8] = "to-c-str";
char constantarr_0_403[14] = "to-str.lambda0";
char constantarr_0_404[12] = "move-to-str!";
char constantarr_0_405[18] = "move-to-arr!<char>";
char constantarr_0_406[17] = "cast-immutable<a>";
char constantarr_0_407[19] = "move-to-mut-arr!<a>";
char constantarr_0_408[28] = "set-any-unhandled-exceptions";
char constantarr_0_409[14] = "get-global-ctx";
char constantarr_0_410[18] = "as-ref<global-ctx>";
char constantarr_0_411[8] = "gctx-ptr";
char constantarr_0_412[14] = "island.lambda0";
char constantarr_0_413[19] = "default-log-handler";
char constantarr_0_414[16] = "print-no-newline";
char constantarr_0_415[6] = "stdout";
char constantarr_0_416[7] = "~<char>";
char constantarr_0_417[5] = "level";
char constantarr_0_418[14] = "island.lambda1";
char constantarr_0_419[20] = "ptr-cast<bool, nat8>";
char constantarr_0_420[29] = "as-any-mut-ptr<mut-ptr<bool>>";
char constantarr_0_421[14] = "as<by-val<gc>>";
char constantarr_0_422[11] = "validate-gc";
char constantarr_0_423[10] = "data-begin";
char constantarr_0_424[9] = "<=><bool>";
char constantarr_0_425[17] = "<=<mut-ptr<bool>>";
char constantarr_0_426[8] = "mark-end";
char constantarr_0_427[18] = "<=<mut-ptr<nat64>>";
char constantarr_0_428[14] = "ref-of-val<gc>";
char constantarr_0_429[19] = "thread-safe-counter";
char constantarr_0_430[18] = "ref-of-val<island>";
char constantarr_0_431[11] = "set-islands";
char constantarr_0_432[11] = "arr<island>";
char constantarr_0_433[14] = "ptr-to<island>";
char constantarr_0_434[13] = "add-main-task";
char constantarr_0_435[13] = "exception-ctx";
char constantarr_0_436[7] = "log-ctx";
char constantarr_0_437[26] = "zeroed<fun1<void, logged>>";
char constantarr_0_438[8] = "perf-ctx";
char constantarr_0_439[22] = "mut-arr<measure-value>";
char constantarr_0_440[29] = "as-any-mut-ptr<exception-ctx>";
char constantarr_0_441[25] = "ref-of-val<exception-ctx>";
char constantarr_0_442[23] = "as-any-mut-ptr<log-ctx>";
char constantarr_0_443[19] = "ref-of-val<log-ctx>";
char constantarr_0_444[24] = "as-any-mut-ptr<perf-ctx>";
char constantarr_0_445[20] = "ref-of-val<perf-ctx>";
char constantarr_0_446[10] = "print-lock";
char constantarr_0_447[30] = "as<by-val<thread-local-stuff>>";
char constantarr_0_448[3] = "ctx";
char constantarr_0_449[12] = "context-head";
char constantarr_0_450[23] = "size-of<by-val<gc-ctx>>";
char constantarr_0_451[6] = "set-gc";
char constantarr_0_452[12] = "set-next-ctx";
char constantarr_0_453[16] = "set-context-head";
char constantarr_0_454[8] = "next-ctx";
char constantarr_0_455[11] = "set-handler";
char constantarr_0_456[15] = "as-ref<log-ctx>";
char constantarr_0_457[11] = "log-ctx-ptr";
char constantarr_0_458[11] = "log-handler";
char constantarr_0_459[26] = "ref-of-val<island-gc-root>";
char constantarr_0_460[7] = "gc-root";
char constantarr_0_461[26] = "as-any-mut-ptr<global-ctx>";
char constantarr_0_462[2] = "id";
char constantarr_0_463[22] = "as-any-mut-ptr<gc-ctx>";
char constantarr_0_464[30] = "ref-of-val<thread-local-stuff>";
char constantarr_0_465[15] = "ref-of-val<ctx>";
char constantarr_0_466[83] = "as<fun-act2<fut<nat64>, arr<const-ptr<char>>, fun-ptr2<fut<nat64>, ctx, arr<str>>>>";
char constantarr_0_467[14] = "add-first-task";
char constantarr_0_468[16] = "then-void<nat64>";
char constantarr_0_469[15] = "then<out, void>";
char constantarr_0_470[15] = "unresolved<out>";
char constantarr_0_471[6] = "fut<a>";
char constantarr_0_472[22] = "fut-state-no-callbacks";
char constantarr_0_473[13] = "callback!<in>";
char constantarr_0_474[15] = "with-lock<void>";
char constantarr_0_475[16] = "call-with-ctx<r>";
char constantarr_0_476[5] = "lk<a>";
char constantarr_0_477[8] = "state<a>";
char constantarr_0_478[12] = "set-state<a>";
char constantarr_0_479[22] = "fut-state-callbacks<a>";
char constantarr_0_480[28] = "some<fut-state-callbacks<a>>";
char constantarr_0_481[37] = "subscript<void, result<a, exception>>";
char constantarr_0_482[5] = "ok<a>";
char constantarr_0_483[8] = "value<a>";
char constantarr_0_484[14] = "err<exception>";
char constantarr_0_485[21] = "callback!<in>.lambda0";
char constantarr_0_486[16] = "forward-to!<out>";
char constantarr_0_487[12] = "callback!<a>";
char constantarr_0_488[20] = "callback!<a>.lambda0";
char constantarr_0_489[21] = "resolve-or-reject!<a>";
char constantarr_0_490[23] = "with-lock<fut-state<a>>";
char constantarr_0_491[21] = "fut-state-resolved<a>";
char constantarr_0_492[16] = "value<exception>";
char constantarr_0_493[29] = "resolve-or-reject!<a>.lambda0";
char constantarr_0_494[18] = "call-callbacks!<a>";
char constantarr_0_495[5] = "cb<a>";
char constantarr_0_496[7] = "next<a>";
char constantarr_0_497[24] = "forward-to!<out>.lambda0";
char constantarr_0_498[18] = "subscript<out, in>";
char constantarr_0_499[10] = "get-island";
char constantarr_0_500[17] = "subscript<island>";
char constantarr_0_501[12] = "unsafe-at<a>";
char constantarr_0_502[7] = "islands";
char constantarr_0_503[27] = "island-and-exclusion<r, p0>";
char constantarr_0_504[8] = "add-task";
char constantarr_0_505[15] = "task-queue-node";
char constantarr_0_506[4] = "task";
char constantarr_0_507[10] = "tasks-lock";
char constantarr_0_508[12] = "insert-task!";
char constantarr_0_509[4] = "size";
char constantarr_0_510[10] = "size-recur";
char constantarr_0_511[4] = "next";
char constantarr_0_512[4] = "head";
char constantarr_0_513[8] = "set-head";
char constantarr_0_514[21] = "some<task-queue-node>";
char constantarr_0_515[4] = "time";
char constantarr_0_516[12] = "insert-recur";
char constantarr_0_517[8] = "set-next";
char constantarr_0_518[5] = "tasks";
char constantarr_0_519[22] = "ref-of-val<task-queue>";
char constantarr_0_520[10] = "broadcast!";
char constantarr_0_521[18] = "pthread_mutex_lock";
char constantarr_0_522[22] = "pthread_cond_broadcast";
char constantarr_0_523[12] = "set-sequence";
char constantarr_0_524[8] = "sequence";
char constantarr_0_525[20] = "pthread_mutex_unlock";
char constantarr_0_526[17] = "may-be-work-to-do";
char constantarr_0_527[4] = "gctx";
char constantarr_0_528[12] = "no-timestamp";
char constantarr_0_529[9] = "exclusion";
char constantarr_0_530[11] = "catch<void>";
char constantarr_0_531[27] = "catch-with-exception-ctx<a>";
char constantarr_0_532[16] = "thrown-exception";
char constantarr_0_533[13] = "__jmp_buf_tag";
char constantarr_0_534[4] = "zero";
char constantarr_0_535[7] = "bytes64";
char constantarr_0_536[7] = "bytes32";
char constantarr_0_537[7] = "bytes16";
char constantarr_0_538[8] = "bytes128";
char constantarr_0_539[15] = "set-jmp-buf-ptr";
char constantarr_0_540[21] = "ptr-to<__jmp_buf_tag>";
char constantarr_0_541[6] = "setjmp";
char constantarr_0_542[23] = "subscript<a, exception>";
char constantarr_0_543[21] = "subscript<fut<r>, p0>";
char constantarr_0_544[10] = "fun<r, p0>";
char constantarr_0_545[34] = "subscript<out, in>.lambda0.lambda0";
char constantarr_0_546[10] = "reject!<r>";
char constantarr_0_547[34] = "subscript<out, in>.lambda0.lambda1";
char constantarr_0_548[26] = "subscript<out, in>.lambda0";
char constantarr_0_549[9] = "value<in>";
char constantarr_0_550[23] = "then<out, void>.lambda0";
char constantarr_0_551[14] = "subscript<out>";
char constantarr_0_552[23] = "island-and-exclusion<r>";
char constantarr_0_553[17] = "subscript<fut<r>>";
char constantarr_0_554[6] = "fun<r>";
char constantarr_0_555[30] = "subscript<out>.lambda0.lambda0";
char constantarr_0_556[30] = "subscript<out>.lambda0.lambda1";
char constantarr_0_557[22] = "subscript<out>.lambda0";
char constantarr_0_558[24] = "then-void<nat64>.lambda0";
char constantarr_0_559[24] = "cur-island-and-exclusion";
char constantarr_0_560[20] = "island-and-exclusion";
char constantarr_0_561[9] = "island-id";
char constantarr_0_562[5] = "delay";
char constantarr_0_563[14] = "resolved<void>";
char constantarr_0_564[21] = "tail<const-ptr<char>>";
char constantarr_0_565[11] = "is-empty<a>";
char constantarr_0_566[36] = "subscript<fut<nat64>, ctx, arr<str>>";
char constantarr_0_567[25] = "map<str, const-ptr<char>>";
char constantarr_0_568[13] = "make-arr<out>";
char constantarr_0_569[17] = "fill-ptr-range<a>";
char constantarr_0_570[23] = "fill-ptr-range-recur<a>";
char constantarr_0_571[9] = "!=<nat64>";
char constantarr_0_572[19] = "subscript<a, nat64>";
char constantarr_0_573[13] = "subscript<in>";
char constantarr_0_574[33] = "map<str, const-ptr<char>>.lambda0";
char constantarr_0_575[30] = "add-first-task.lambda0.lambda0";
char constantarr_0_576[22] = "add-first-task.lambda0";
char constantarr_0_577[24] = "handle-exceptions<nat64>";
char constantarr_0_578[26] = "subscript<void, exception>";
char constantarr_0_579[17] = "exception-handler";
char constantarr_0_580[14] = "get-cur-island";
char constantarr_0_581[32] = "handle-exceptions<nat64>.lambda0";
char constantarr_0_582[21] = "add-main-task.lambda0";
char constantarr_0_583[84] = "call-with-ctx<fut<nat64>, arr<const-ptr<char>>, fun-ptr2<fut<nat64>, ctx, arr<str>>>";
char constantarr_0_584[11] = "run-threads";
char constantarr_0_585[45] = "unmanaged-alloc-elements<by-val<thread-args>>";
char constantarr_0_586[19] = "start-threads-recur";
char constantarr_0_587[22] = "+<by-val<thread-args>>";
char constantarr_0_588[30] = "set-deref<by-val<thread-args>>";
char constantarr_0_589[11] = "thread-args";
char constantarr_0_590[17] = "create-one-thread";
char constantarr_0_591[14] = "pthread_create";
char constantarr_0_592[9] = "!=<int32>";
char constantarr_0_593[6] = "EAGAIN";
char constantarr_0_594[14] = "as-cell<nat64>";
char constantarr_0_595[15] = "as-ref<cell<a>>";
char constantarr_0_596[44] = "as-any-mut-ptr<mut-ptr<by-val<thread-args>>>";
char constantarr_0_597[10] = "thread-fun";
char constantarr_0_598[19] = "as-ref<thread-args>";
char constantarr_0_599[15] = "thread-function";
char constantarr_0_600[21] = "thread-function-recur";
char constantarr_0_601[12] = "is-shut-down";
char constantarr_0_602[18] = "set-n-live-threads";
char constantarr_0_603[14] = "n-live-threads";
char constantarr_0_604[28] = "assert-islands-are-shut-down";
char constantarr_0_605[16] = "noctx-at<island>";
char constantarr_0_606[11] = "hard-forbid";
char constantarr_0_607[8] = "needs-gc";
char constantarr_0_608[17] = "n-threads-running";
char constantarr_0_609[25] = "is-empty<task-queue-node>";
char constantarr_0_610[12] = "get-sequence";
char constantarr_0_611[11] = "choose-task";
char constantarr_0_612[17] = "get-monotime-nsec";
char constantarr_0_613[26] = "as<by-val<cell<timespec>>>";
char constantarr_0_614[14] = "cell<timespec>";
char constantarr_0_615[8] = "timespec";
char constantarr_0_616[13] = "clock_gettime";
char constantarr_0_617[26] = "ref-of-val<cell<timespec>>";
char constantarr_0_618[11] = "*<timespec>";
char constantarr_0_619[14] = "inner-value<a>";
char constantarr_0_620[6] = "tv-sec";
char constantarr_0_621[7] = "tv-nsec";
char constantarr_0_622[11] = "todo<nat64>";
char constantarr_0_623[22] = "as<choose-task-result>";
char constantarr_0_624[17] = "choose-task-recur";
char constantarr_0_625[14] = "no-chosen-task";
char constantarr_0_626[21] = "choose-task-in-island";
char constantarr_0_627[32] = "as<choose-task-in-island-result>";
char constantarr_0_628[7] = "do-a-gc";
char constantarr_0_629[7] = "no-task";
char constantarr_0_630[9] = "pop-task!";
char constantarr_0_631[27] = "ref-of-val<mut-list<nat64>>";
char constantarr_0_632[28] = "currently-running-exclusions";
char constantarr_0_633[19] = "as<pop-task-result>";
char constantarr_0_634[9] = "in<nat64>";
char constantarr_0_635[5] = "in<a>";
char constantarr_0_636[11] = "in-recur<a>";
char constantarr_0_637[11] = "noctx-at<a>";
char constantarr_0_638[14] = "temp-as-arr<a>";
char constantarr_0_639[18] = "temp-as-mut-arr<a>";
char constantarr_0_640[10] = "pop-recur!";
char constantarr_0_641[11] = "to-opt-time";
char constantarr_0_642[11] = "some<nat64>";
char constantarr_0_643[40] = "push-capacity-must-be-sufficient!<nat64>";
char constantarr_0_644[10] = "is-no-task";
char constantarr_0_645[21] = "set-n-threads-running";
char constantarr_0_646[11] = "chosen-task";
char constantarr_0_647[9] = "any-tasks";
char constantarr_0_648[8] = "min-time";
char constantarr_0_649[10] = "min<nat64>";
char constantarr_0_650[15] = "first-task-time";
char constantarr_0_651[28] = "no-tasks-and-last-thread-out";
char constantarr_0_652[7] = "do-task";
char constantarr_0_653[11] = "task-island";
char constantarr_0_654[10] = "task-or-gc";
char constantarr_0_655[6] = "action";
char constantarr_0_656[12] = "return-task!";
char constantarr_0_657[35] = "noctx-must-remove-unordered!<nat64>";
char constantarr_0_658[37] = "noctx-must-remove-unordered-recur!<a>";
char constantarr_0_659[7] = "drop<a>";
char constantarr_0_660[29] = "noctx-remove-unordered-at!<a>";
char constantarr_0_661[10] = "return-ctx";
char constantarr_0_662[13] = "return-gc-ctx";
char constantarr_0_663[12] = "some<gc-ctx>";
char constantarr_0_664[46] = "run-garbage-collection<by-val<island-gc-root>>";
char constantarr_0_665[12] = "set-gc-count";
char constantarr_0_666[8] = "gc-count";
char constantarr_0_667[20] = "as<by-val<mark-ctx>>";
char constantarr_0_668[8] = "mark-ctx";
char constantarr_0_669[13] = "mark-visit<a>";
char constantarr_0_670[20] = "ref-of-val<mark-ctx>";
char constantarr_0_671[15] = "clear-free-mem!";
char constantarr_0_672[17] = "!=<mut-ptr<bool>>";
char constantarr_0_673[16] = "set-is-shut-down";
char constantarr_0_674[7] = "wait-on";
char constantarr_0_675[17] = "pthread_cond_wait";
char constantarr_0_676[11] = "to-timespec";
char constantarr_0_677[10] = "unsafe-mod";
char constantarr_0_678[22] = "pthread_cond_timedwait";
char constantarr_0_679[16] = "ptr-to<timespec>";
char constantarr_0_680[9] = "ETIMEDOUT";
char constantarr_0_681[9] = "thread-id";
char constantarr_0_682[18] = "join-threads-recur";
char constantarr_0_683[15] = "join-one-thread";
char constantarr_0_684[31] = "as<by-val<cell<mut-ptr<nat8>>>>";
char constantarr_0_685[19] = "cell<mut-ptr<nat8>>";
char constantarr_0_686[12] = "pthread_join";
char constantarr_0_687[31] = "ref-of-val<cell<mut-ptr<nat8>>>";
char constantarr_0_688[6] = "EINVAL";
char constantarr_0_689[5] = "ESRCH";
char constantarr_0_690[16] = "*<mut-ptr<nat8>>";
char constantarr_0_691[21] = "unmanaged-free<nat64>";
char constantarr_0_692[4] = "free";
char constantarr_0_693[35] = "unmanaged-free<by-val<thread-args>>";
char constantarr_0_694[17] = "destroy-condition";
char constantarr_0_695[25] = "pthread_mutexattr_destroy";
char constantarr_0_696[21] = "pthread_mutex_destroy";
char constantarr_0_697[24] = "pthread_condattr_destroy";
char constantarr_0_698[20] = "pthread_cond_destroy";
char constantarr_0_699[24] = "any-unhandled-exceptions";
char constantarr_0_700[4] = "main";
char constantarr_0_701[15] = "resolved<nat64>";
char constantarr_0_702[16] = "parse-named-args";
char constantarr_0_703[21] = "parse-command-dynamic";
char constantarr_0_704[15] = "find-index<str>";
char constantarr_0_705[19] = "find-index-recur<a>";
char constantarr_0_706[18] = "subscript<bool, a>";
char constantarr_0_707[11] = "starts-with";
char constantarr_0_708[15] = "arr-equal<char>";
char constantarr_0_709[14] = "equal-recur<a>";
char constantarr_0_710[17] = "starts-with<char>";
char constantarr_0_711[29] = "parse-command-dynamic.lambda0";
char constantarr_0_712[14] = "parsed-command";
char constantarr_0_713[9] = "cmp<nat8>";
char constantarr_0_714[17] = "arr-compare<char>";
char constantarr_0_715[16] = "compare-recur<a>";
char constantarr_0_716[19] = "dict<str, arr<str>>";
char constantarr_0_717[10] = "dict<k, v>";
char constantarr_0_718[14] = "end-node<k, v>";
char constantarr_0_719[23] = "sort-by<arrow<k, v>, k>";
char constantarr_0_720[7] = "sort<a>";
char constantarr_0_721[15] = "make-mut-arr<a>";
char constantarr_0_722[18] = "mut-arr<a>.lambda0";
char constantarr_0_723[8] = "sort!<a>";
char constantarr_0_724[24] = "insertion-sort-recur!<a>";
char constantarr_0_725[14] = "!=<mut-ptr<a>>";
char constantarr_0_726[10] = "insert!<a>";
char constantarr_0_727[27] = "subscript<comparison, a, a>";
char constantarr_0_728[24] = "call-with-ctx<r, p0, p1>";
char constantarr_0_729[15] = "subscript<b, a>";
char constantarr_0_730[31] = "sort-by<arrow<k, v>, k>.lambda0";
char constantarr_0_731[10] = "from<k, v>";
char constantarr_0_732[27] = "dict<str, arr<str>>.lambda0";
char constantarr_0_733[14] = "subscript<str>";
char constantarr_0_734[29] = "parse-command-dynamic.lambda1";
char constantarr_0_735[23] = "mut-dict<str, arr<str>>";
char constantarr_0_736[14] = "mut-dict<k, v>";
char constantarr_0_737[26] = "mut-list<arrow<k, opt<v>>>";
char constantarr_0_738[22] = "parse-named-args-recur";
char constantarr_0_739[10] = "force<str>";
char constantarr_0_740[8] = "force<a>";
char constantarr_0_741[16] = "try-remove-start";
char constantarr_0_742[22] = "try-remove-start<char>";
char constantarr_0_743[12] = "some<arr<a>>";
char constantarr_0_744[9] = "some<str>";
char constantarr_0_745[9] = "tail<str>";
char constantarr_0_746[30] = "parse-named-args-recur.lambda0";
char constantarr_0_747[28] = "set-subscript<str, arr<str>>";
char constantarr_0_748[42] = "insert-into-key-match-or-empty-slot!<k, v>";
char constantarr_0_749[21] = "find-insert-ptr<k, v>";
char constantarr_0_750[42] = "binary-search-insert-ptr<arrow<k, opt<v>>>";
char constantarr_0_751[27] = "binary-search-insert-ptr<a>";
char constantarr_0_752[30] = "binary-search-compare-recur<a>";
char constantarr_0_753[24] = "subscript<comparison, a>";
char constantarr_0_754[11] = "pairs<k, v>";
char constantarr_0_755[15] = "from<k, opt<v>>";
char constantarr_0_756[29] = "find-insert-ptr<k, v>.lambda0";
char constantarr_0_757[29] = "!=<mut-ptr<arrow<k, opt<v>>>>";
char constantarr_0_758[25] = "end-ptr<arrow<k, opt<v>>>";
char constantarr_0_759[11] = "is-empty<v>";
char constantarr_0_760[13] = "to<k, opt<v>>";
char constantarr_0_761[19] = "set-node-size<k, v>";
char constantarr_0_762[15] = "node-size<k, v>";
char constantarr_0_763[27] = "set-deref<arrow<k, opt<v>>>";
char constantarr_0_764[13] = "-><k, opt<v>>";
char constantarr_0_765[7] = "some<v>";
char constantarr_0_766[10] = "next<k, v>";
char constantarr_0_767[4] = "<<k>";
char constantarr_0_768[19] = "-<arrow<k, opt<v>>>";
char constantarr_0_769[15] = "add-pair!<k, v>";
char constantarr_0_770[26] = "is-empty<arrow<k, opt<v>>>";
char constantarr_0_771[20] = "~=<arrow<k, opt<v>>>";
char constantarr_0_772[10] = "as<opt<v>>";
char constantarr_0_773[20] = "insert-linear!<k, v>";
char constantarr_0_774[27] = "subscript<arrow<k, opt<v>>>";
char constantarr_0_775[17] = "move-right!<k, v>";
char constantarr_0_776[31] = "set-subscript<arrow<k, opt<v>>>";
char constantarr_0_777[4] = "><k>";
char constantarr_0_778[14] = "set-next<k, v>";
char constantarr_0_779[20] = "some<mut-dict<k, v>>";
char constantarr_0_780[24] = "compact-if-needed!<k, v>";
char constantarr_0_781[22] = "total-pairs-size<k, v>";
char constantarr_0_782[28] = "total-pairs-size-recur<k, v>";
char constantarr_0_783[14] = "compact!<k, v>";
char constantarr_0_784[25] = "filter!<arrow<k, opt<v>>>";
char constantarr_0_785[16] = "filter-recur!<a>";
char constantarr_0_786[22] = "compact!<k, v>.lambda0";
char constantarr_0_787[38] = "merge-no-duplicates!<arrow<k, opt<v>>>";
char constantarr_0_788[8] = "swap!<a>";
char constantarr_0_789[19] = "unsafe-set-size!<a>";
char constantarr_0_790[10] = "reserve<a>";
char constantarr_0_791[23] = "merge-reverse-recur!<a>";
char constantarr_0_792[34] = "subscript<unique-comparison, a, a>";
char constantarr_0_793[25] = "mut-arr-from-begin-end<a>";
char constantarr_0_794[14] = "<=<mut-ptr<a>>";
char constantarr_0_795[21] = "arr-from-begin-end<a>";
char constantarr_0_796[13] = "copy-from!<a>";
char constantarr_0_797[9] = "empty!<a>";
char constantarr_0_798[9] = "pop-n!<a>";
char constantarr_0_799[27] = "assert-comparison-not-equal";
char constantarr_0_800[30] = "unreachable<unique-comparison>";
char constantarr_0_801[22] = "compact!<k, v>.lambda1";
char constantarr_0_802[28] = "move-to-dict!<str, arr<str>>";
char constantarr_0_803[18] = "move-to-arr!<k, v>";
char constantarr_0_804[29] = "map-to-arr<arrow<k, v>, k, v>";
char constantarr_0_805[33] = "map-to-arr<out, arrow<k, opt<v>>>";
char constantarr_0_806[23] = "map-to-mut-arr<out, in>";
char constantarr_0_807[31] = "map-to-mut-arr<out, in>.lambda0";
char constantarr_0_808[20] = "subscript<out, k, v>";
char constantarr_0_809[8] = "force<v>";
char constantarr_0_810[37] = "map-to-arr<arrow<k, v>, k, v>.lambda0";
char constantarr_0_811[8] = "-><k, v>";
char constantarr_0_812[26] = "move-to-arr!<k, v>.lambda0";
char constantarr_0_813[12] = "empty!<k, v>";
char constantarr_0_814[8] = "nameless";
char constantarr_0_815[5] = "after";
char constantarr_0_816[28] = "fill-mut-list<opt<arr<str>>>";
char constantarr_0_817[15] = "fill-mut-arr<a>";
char constantarr_0_818[23] = "fill-mut-arr<a>.lambda0";
char constantarr_0_819[10] = "cell<bool>";
char constantarr_0_820[19] = "each<str, arr<str>>";
char constantarr_0_821[16] = "fold<void, k, v>";
char constantarr_0_822[16] = "init-iters<k, v>";
char constantarr_0_823[44] = "uninitialized-mut-arr<arr<arrow<k, opt<v>>>>";
char constantarr_0_824[19] = "overlay-count<k, v>";
char constantarr_0_825[10] = "prev<k, v>";
char constantarr_0_826[10] = "impl<k, v>";
char constantarr_0_827[31] = "init-overlay-iters-recur!<k, v>";
char constantarr_0_828[32] = "set-deref<arr<arrow<k, opt<v>>>>";
char constantarr_0_829[24] = "+<arr<arrow<k, opt<v>>>>";
char constantarr_0_830[32] = "begin-ptr<arr<arrow<k, opt<v>>>>";
char constantarr_0_831[11] = "iters<k, v>";
char constantarr_0_832[19] = "fold-recur<a, k, v>";
char constantarr_0_833[31] = "is-empty<arr<arrow<k, opt<v>>>>";
char constantarr_0_834[20] = "fold<a, arrow<k, v>>";
char constantarr_0_835[16] = "fold-recur<a, b>";
char constantarr_0_836[5] = "==<b>";
char constantarr_0_837[18] = "subscript<a, a, b>";
char constantarr_0_838[10] = "end-ptr<b>";
char constantarr_0_839[21] = "subscript<a, a, k, v>";
char constantarr_0_840[28] = "call-with-ctx<r, p0, p1, p2>";
char constantarr_0_841[8] = "to<k, v>";
char constantarr_0_842[27] = "fold-recur<a, k, v>.lambda0";
char constantarr_0_843[21] = "is-empty<arrow<k, v>>";
char constantarr_0_844[25] = "find-least-key<k, opt<v>>";
char constantarr_0_845[25] = "fold<k, arr<arrow<k, v>>>";
char constantarr_0_846[10] = "fold<a, b>";
char constantarr_0_847[4] = "*<b>";
char constantarr_0_848[4] = "+<b>";
char constantarr_0_849[14] = "temp-as-arr<b>";
char constantarr_0_850[6] = "min<k>";
char constantarr_0_851[22] = "subscript<arrow<k, v>>";
char constantarr_0_852[33] = "find-least-key<k, opt<v>>.lambda0";
char constantarr_0_853[32] = "subscript<arr<arrow<k, opt<v>>>>";
char constantarr_0_854[27] = "tail<arr<arrow<k, opt<v>>>>";
char constantarr_0_855[17] = "tail<arrow<k, v>>";
char constantarr_0_856[14] = "take-key<k, v>";
char constantarr_0_857[20] = "take-key-recur<k, v>";
char constantarr_0_858[14] = "took-key<k, v>";
char constantarr_0_859[22] = "tail<arrow<k, opt<v>>>";
char constantarr_0_860[36] = "set-subscript<arr<arrow<k, opt<v>>>>";
char constantarr_0_861[17] = "unsafe-set-at!<a>";
char constantarr_0_862[9] = "opt-or<v>";
char constantarr_0_863[21] = "rightmost-value<k, v>";
char constantarr_0_864[14] = "overlays<k, v>";
char constantarr_0_865[15] = "end-pairs<k, v>";
char constantarr_0_866[21] = "subscript<void, k, v>";
char constantarr_0_867[27] = "each<str, arr<str>>.lambda0";
char constantarr_0_868[5] = "named";
char constantarr_0_869[13] = "index-of<str>";
char constantarr_0_870[9] = "ptr-of<a>";
char constantarr_0_871[15] = "ptr-of-recur<a>";
char constantarr_0_872[18] = "some<const-ptr<a>>";
char constantarr_0_873[18] = "set-inner-value<a>";
char constantarr_0_874[6] = "finish";
char constantarr_0_875[5] = "inner";
char constantarr_0_876[15] = "with-value<str>";
char constantarr_0_877[8] = "with-str";
char constantarr_0_878[6] = "interp";
char constantarr_0_879[24] = "subscript<opt<arr<str>>>";
char constantarr_0_880[28] = "set-subscript<opt<arr<str>>>";
char constantarr_0_881[24] = "parse-named-args.lambda0";
char constantarr_0_882[24] = "some<arr<opt<arr<str>>>>";
char constantarr_0_883[27] = "move-to-arr!<opt<arr<str>>>";
char constantarr_0_884[10] = "print-help";
char constantarr_0_885[12] = "force<nat64>";
char constantarr_0_886[9] = "parse-nat";
char constantarr_0_887[18] = "with-reader<nat64>";
char constantarr_0_888[6] = "reader";
char constantarr_0_889[25] = "subscript<opt<a>, reader>";
char constantarr_0_890[3] = "cur";
char constantarr_0_891[3] = "end";
char constantarr_0_892[9] = "take-nat!";
char constantarr_0_893[13] = "char-to-nat64";
char constantarr_0_894[4] = "peek";
char constantarr_0_895[10] = "drop<char>";
char constantarr_0_896[5] = "next!";
char constantarr_0_897[7] = "set-cur";
char constantarr_0_898[15] = "take-nat-recur!";
char constantarr_0_899[17] = "parse-nat.lambda0";
char constantarr_0_900[7] = "do-test";
char constantarr_0_901[11] = "parent-path";
char constantarr_0_902[16] = "r-index-of<char>";
char constantarr_0_903[14] = "find-rindex<a>";
char constantarr_0_904[20] = "find-rindex-recur<a>";
char constantarr_0_905[24] = "r-index-of<char>.lambda0";
char constantarr_0_906[10] = "child-path";
char constantarr_0_907[11] = "get-environ";
char constantarr_0_908[18] = "mut-dict<str, str>";
char constantarr_0_909[17] = "get-environ-recur";
char constantarr_0_910[10] = "null<char>";
char constantarr_0_911[7] = "null<a>";
char constantarr_0_912[19] = "parse-environ-entry";
char constantarr_0_913[21] = "todo<arrow<str, str>>";
char constantarr_0_914[12] = "-><str, str>";
char constantarr_0_915[23] = "set-subscript<str, str>";
char constantarr_0_916[14] = "from<str, str>";
char constantarr_0_917[12] = "to<str, str>";
char constantarr_0_918[7] = "environ";
char constantarr_0_919[23] = "move-to-dict!<str, str>";
char constantarr_0_920[18] = "dict<k, v>.lambda0";
char constantarr_0_921[14] = "first-failures";
char constantarr_0_922[36] = "subscript<result<str, arr<failure>>>";
char constantarr_0_923[7] = "ok<str>";
char constantarr_0_924[10] = "value<str>";
char constantarr_0_925[14] = "run-crow-tests";
char constantarr_0_926[10] = "list-tests";
char constantarr_0_927[13] = "mut-list<str>";
char constantarr_0_928[20] = "each-child-recursive";
char constantarr_0_929[23] = "as<fun-act1<bool, str>>";
char constantarr_0_930[28] = "each-child-recursive.lambda0";
char constantarr_0_931[6] = "is-dir";
char constantarr_0_932[8] = "get-stat";
char constantarr_0_933[4] = "stat";
char constantarr_0_934[10] = "some<stat>";
char constantarr_0_935[5] = "errno";
char constantarr_0_936[8] = "*<int32>";
char constantarr_0_937[16] = "__errno_location";
char constantarr_0_938[6] = "ENOENT";
char constantarr_0_939[15] = "todo<opt<stat>>";
char constantarr_0_940[11] = "throw<bool>";
char constantarr_0_941[27] = "with-value<const-ptr<char>>";
char constantarr_0_942[7] = "st_mode";
char constantarr_0_943[6] = "S_IFMT";
char constantarr_0_944[7] = "S_IFDIR";
char constantarr_0_945[9] = "each<str>";
char constantarr_0_946[8] = "read-dir";
char constantarr_0_947[7] = "opendir";
char constantarr_0_948[19] = "==<const-ptr<nat8>>";
char constantarr_0_949[28] = "!=<mut-ptr<const-ptr<nat8>>>";
char constantarr_0_950[42] = "ptr-cast-from-extern<const-ptr<nat8>, dir>";
char constantarr_0_951[21] = "null<const-ptr<nat8>>";
char constantarr_0_952[14] = "read-dir-recur";
char constantarr_0_953[6] = "dirent";
char constantarr_0_954[8] = "bytes256";
char constantarr_0_955[12] = "cell<dirent>";
char constantarr_0_956[9] = "readdir_r";
char constantarr_0_957[19] = "!=<const-ptr<nat8>>";
char constantarr_0_958[24] = "as-any-const-ptr<dirent>";
char constantarr_0_959[9] = "*<dirent>";
char constantarr_0_960[14] = "ref-eq<dirent>";
char constantarr_0_961[15] = "get-dirent-name";
char constantarr_0_962[14] = "size-of<int64>";
char constantarr_0_963[14] = "size-of<nat16>";
char constantarr_0_964[7] = "+<nat8>";
char constantarr_0_965[20] = "ptr-cast<char, nat8>";
char constantarr_0_966[7] = "!=<str>";
char constantarr_0_967[7] = "~=<str>";
char constantarr_0_968[9] = "sort<str>";
char constantarr_0_969[17] = "sort<str>.lambda0";
char constantarr_0_970[17] = "move-to-arr!<str>";
char constantarr_0_971[10] = "has-substr";
char constantarr_0_972[21] = "contains-subseq<char>";
char constantarr_0_973[18] = "index-of-subseq<a>";
char constantarr_0_974[24] = "index-of-subseq-recur<a>";
char constantarr_0_975[11] = "ext-is-crow";
char constantarr_0_976[14] = "opt-equal<str>";
char constantarr_0_977[13] = "get-extension";
char constantarr_0_978[13] = "last-index-of";
char constantarr_0_979[10] = "last<char>";
char constantarr_0_980[7] = "some<a>";
char constantarr_0_981[11] = "rtail<char>";
char constantarr_0_982[9] = "base-name";
char constantarr_0_983[18] = "list-tests.lambda0";
char constantarr_0_984[10] = "match-test";
char constantarr_0_985[36] = "flat-map-with-max-size<failure, str>";
char constantarr_0_986[13] = "mut-list<out>";
char constantarr_0_987[9] = "size<out>";
char constantarr_0_988[7] = "~=<out>";
char constantarr_0_989[15] = "~=<out>.lambda0";
char constantarr_0_990[23] = "subscript<arr<out>, in>";
char constantarr_0_991[30] = "reduce-size-if-more-than!<out>";
char constantarr_0_992[12] = "drop<opt<a>>";
char constantarr_0_993[7] = "pop!<a>";
char constantarr_0_994[44] = "flat-map-with-max-size<failure, str>.lambda0";
char constantarr_0_995[17] = "move-to-arr!<out>";
char constantarr_0_996[20] = "run-single-crow-test";
char constantarr_0_997[29] = "first-some<arr<failure>, str>";
char constantarr_0_998[23] = "subscript<opt<out>, in>";
char constantarr_0_999[13] = "is-empty<out>";
char constantarr_0_1000[14] = "run-print-test";
char constantarr_0_1001[21] = "spawn-and-wait-result";
char constantarr_0_1002[14] = "fold<str, str>";
char constantarr_0_1003[29] = "spawn-and-wait-result.lambda0";
char constantarr_0_1004[7] = "is-file";
char constantarr_0_1005[7] = "S_IFREG";
char constantarr_0_1006[10] = "make-pipes";
char constantarr_0_1007[5] = "pipes";
char constantarr_0_1008[17] = "check-posix-error";
char constantarr_0_1009[4] = "pipe";
char constantarr_0_1010[26] = "posix_spawn_file_actions_t";
char constantarr_0_1011[29] = "posix_spawn_file_actions_init";
char constantarr_0_1012[33] = "posix_spawn_file_actions_addclose";
char constantarr_0_1013[10] = "write-pipe";
char constantarr_0_1014[32] = "posix_spawn_file_actions_adddup2";
char constantarr_0_1015[9] = "read-pipe";
char constantarr_0_1016[11] = "cell<int32>";
char constantarr_0_1017[11] = "posix_spawn";
char constantarr_0_1018[5] = "close";
char constantarr_0_1019[12] = "keep-POLLINg";
char constantarr_0_1020[23] = "mut-arr<by-val<pollfd>>";
char constantarr_0_1021[31] = "mut-arr<by-val<pollfd>>.lambda0";
char constantarr_0_1022[23] = "as<arr<by-val<pollfd>>>";
char constantarr_0_1023[6] = "pollfd";
char constantarr_0_1024[6] = "POLLIN";
char constantarr_0_1025[21] = "ref-of-val-at<pollfd>";
char constantarr_0_1026[15] = "size<by-val<a>>";
char constantarr_0_1027[13] = "ref-of-ptr<a>";
char constantarr_0_1028[13] = "ref-of-val<a>";
char constantarr_0_1029[4] = "poll";
char constantarr_0_1030[14] = "handle-revents";
char constantarr_0_1031[7] = "revents";
char constantarr_0_1032[10] = "has-POLLIN";
char constantarr_0_1033[14] = "bits-intersect";
char constantarr_0_1034[9] = "!=<int16>";
char constantarr_0_1035[24] = "read-to-buffer-until-eof";
char constantarr_0_1036[22] = "unsafe-set-size!<char>";
char constantarr_0_1037[4] = "read";
char constantarr_0_1038[8] = "to-nat64";
char constantarr_0_1039[10] = "cmp<int64>";
char constantarr_0_1040[8] = "<<int64>";
char constantarr_0_1041[2] = "fd";
char constantarr_0_1042[11] = "has-POLLHUP";
char constantarr_0_1043[7] = "POLLHUP";
char constantarr_0_1044[11] = "has-POLLPRI";
char constantarr_0_1045[7] = "POLLPRI";
char constantarr_0_1046[11] = "has-POLLOUT";
char constantarr_0_1047[7] = "POLLOUT";
char constantarr_0_1048[11] = "has-POLLERR";
char constantarr_0_1049[7] = "POLLERR";
char constantarr_0_1050[12] = "has-POLLNVAL";
char constantarr_0_1051[8] = "POLLNVAL";
char constantarr_0_1052[21] = "handle-revents-result";
char constantarr_0_1053[3] = "any";
char constantarr_0_1054[10] = "had-POLLIN";
char constantarr_0_1055[7] = "hung-up";
char constantarr_0_1056[22] = "wait-and-get-exit-code";
char constantarr_0_1057[7] = "waitpid";
char constantarr_0_1058[9] = "WIFEXITED";
char constantarr_0_1059[8] = "WTERMSIG";
char constantarr_0_1060[11] = "WEXITSTATUS";
char constantarr_0_1061[2] = ">>";
char constantarr_0_1062[10] = "cmp<int32>";
char constantarr_0_1063[8] = "<<int32>";
char constantarr_0_1064[11] = "todo<int32>";
char constantarr_0_1065[22] = "unsafe-bit-shift-right";
char constantarr_0_1066[11] = "WIFSIGNALED";
char constantarr_0_1067[7] = "to-base";
char constantarr_0_1068[12] = "digit-to-str";
char constantarr_0_1069[3] = "mod";
char constantarr_0_1070[3] = "abs";
char constantarr_0_1071[17] = "with-value<int32>";
char constantarr_0_1072[10] = "WIFSTOPPED";
char constantarr_0_1073[12] = "WIFCONTINUED";
char constantarr_0_1074[14] = "process-result";
char constantarr_0_1075[12] = "convert-args";
char constantarr_0_1076[18] = "~<const-ptr<char>>";
char constantarr_0_1077[25] = "map<const-ptr<char>, str>";
char constantarr_0_1078[33] = "map<const-ptr<char>, str>.lambda0";
char constantarr_0_1079[20] = "convert-args.lambda0";
char constantarr_0_1080[15] = "convert-environ";
char constantarr_0_1081[25] = "mut-list<const-ptr<char>>";
char constantarr_0_1082[14] = "each<str, str>";
char constantarr_0_1083[22] = "each<str, str>.lambda0";
char constantarr_0_1084[19] = "~=<const-ptr<char>>";
char constantarr_0_1085[23] = "convert-environ.lambda0";
char constantarr_0_1086[19] = "as<const-ptr<char>>";
char constantarr_0_1087[29] = "move-to-arr!<const-ptr<char>>";
char constantarr_0_1088[21] = "throw<process-result>";
char constantarr_0_1089[9] = "exit-code";
char constantarr_0_1090[16] = "as<arr<failure>>";
char constantarr_0_1091[13] = "handle-output";
char constantarr_0_1092[13] = "try-read-file";
char constantarr_0_1093[4] = "open";
char constantarr_0_1094[8] = "O_RDONLY";
char constantarr_0_1095[14] = "todo<opt<str>>";
char constantarr_0_1096[5] = "lseek";
char constantarr_0_1097[8] = "seek-end";
char constantarr_0_1098[8] = "seek-set";
char constantarr_0_1099[20] = "ptr-cast<nat8, char>";
char constantarr_0_1100[10] = "write-file";
char constantarr_0_1101[9] = "as<nat32>";
char constantarr_0_1102[1] = "|";
char constantarr_0_1103[2] = "<<";
char constantarr_0_1104[10] = "cmp<nat32>";
char constantarr_0_1105[8] = "<<nat32>";
char constantarr_0_1106[15] = "unsafe-to-nat32";
char constantarr_0_1107[21] = "unsafe-bit-shift-left";
char constantarr_0_1108[7] = "O_CREAT";
char constantarr_0_1109[8] = "O_WRONLY";
char constantarr_0_1110[7] = "O_TRUNC";
char constantarr_0_1111[17] = "with-value<nat32>";
char constantarr_0_1112[9] = "max-int64";
char constantarr_0_1113[7] = "failure";
char constantarr_0_1114[17] = "is-empty<failure>";
char constantarr_0_1115[17] = "print-test-result";
char constantarr_0_1116[13] = "remove-colors";
char constantarr_0_1117[20] = "remove-colors-recur!";
char constantarr_0_1118[10] = "tail<char>";
char constantarr_0_1119[22] = "remove-colors-recur-2!";
char constantarr_0_1120[11] = "should-stop";
char constantarr_0_1121[18] = "some<arr<failure>>";
char constantarr_0_1122[8] = "failures";
char constantarr_0_1123[28] = "run-single-crow-test.lambda0";
char constantarr_0_1124[24] = "run-single-runnable-test";
char constantarr_0_1125[10] = "~<failure>";
char constantarr_0_1126[22] = "run-crow-tests.lambda0";
char constantarr_0_1127[17] = "with-value<nat64>";
char constantarr_0_1128[17] = "err<arr<failure>>";
char constantarr_0_1129[23] = "do-test.lambda0.lambda0";
char constantarr_0_1130[15] = "do-test.lambda0";
char constantarr_0_1131[4] = "lint";
char constantarr_0_1132[19] = "list-lintable-files";
char constantarr_0_1133[18] = "excluded-from-lint";
char constantarr_0_1134[7] = "in<str>";
char constantarr_0_1135[11] = "exists<str>";
char constantarr_0_1136[9] = "ends-with";
char constantarr_0_1137[15] = "ends-with<char>";
char constantarr_0_1138[26] = "excluded-from-lint.lambda0";
char constantarr_0_1139[27] = "list-lintable-files.lambda0";
char constantarr_0_1140[31] = "should-ignore-extension-of-name";
char constantarr_0_1141[23] = "should-ignore-extension";
char constantarr_0_1142[18] = "ignored-extensions";
char constantarr_0_1143[27] = "list-lintable-files.lambda1";
char constantarr_0_1144[9] = "lint-file";
char constantarr_0_1145[9] = "read-file";
char constantarr_0_1146[20] = "each-with-index<str>";
char constantarr_0_1147[24] = "each-with-index-recur<a>";
char constantarr_0_1148[25] = "subscript<void, a, nat64>";
char constantarr_0_1149[5] = "lines";
char constantarr_0_1150[11] = "cell<nat64>";
char constantarr_0_1151[21] = "each-with-index<char>";
char constantarr_0_1152[11] = "swap<nat64>";
char constantarr_0_1153[13] = "lines.lambda0";
char constantarr_0_1154[8] = "line-len";
char constantarr_0_1155[6] = "n-tabs";
char constantarr_0_1156[8] = "tab-size";
char constantarr_0_1157[15] = "max-line-length";
char constantarr_0_1158[17] = "lint-file.lambda0";
char constantarr_0_1159[12] = "lint.lambda0";
char constantarr_0_1160[15] = "do-test.lambda1";
char constantarr_0_1161[14] = "print-failures";
char constantarr_0_1162[19] = "value<arr<failure>>";
char constantarr_0_1163[13] = "print-failure";
char constantarr_0_1164[10] = "print-bold";
char constantarr_0_1165[4] = "path";
char constantarr_0_1166[11] = "print-reset";
char constantarr_0_1167[22] = "print-failures.lambda0";
char constantarr_0_1168[12] = "test-options";
char constantarr_0_1169[11] = "static-syms";
struct str constantarr_2_0[4] = {{{11, constantarr_0_10}}, {{16, constantarr_0_11}}, {{12, constantarr_0_12}}, {{5, constantarr_0_13}}};
struct str constantarr_2_1[4] = {{{3, constantarr_0_32}}, {{5, constantarr_0_33}}, {{14, constantarr_0_34}}, {{9, constantarr_0_35}}};
struct str constantarr_2_2[11] = {{{4, constantarr_0_86}}, {{4, constantarr_0_72}}, {{5, constantarr_0_87}}, {{4, constantarr_0_88}}, {{4, constantarr_0_89}}, {{5, constantarr_0_62}}, {{4, constantarr_0_90}}, {{4, constantarr_0_91}}, {{5, constantarr_0_92}}, {{5, constantarr_0_93}}, {{3, constantarr_0_94}}};
struct str constantarr_2_3[5] = {{{13, constantarr_0_95}}, {{7, constantarr_0_96}}, {{7, constantarr_0_97}}, {{12, constantarr_0_98}}, {{17, constantarr_0_99}}};
struct str constantarr_2_4[6] = {{{1, constantarr_0_51}}, {{4, constantarr_0_100}}, {{1, constantarr_0_101}}, {{3, constantarr_0_102}}, {{4, constantarr_0_103}}, {{10, constantarr_0_104}}};
struct named_val constantarr_5_0[1113] = {{{"mark"}, ((uint8_t*)mark)}, {{"hard-assert"}, ((uint8_t*)hard_assert)}, {{"is-word-aligned"}, ((uint8_t*)is_word_aligned_0)}, {{"is-word-aligned"}, ((uint8_t*)is_word_aligned_1)}, {{"words-of-bytes"}, ((uint8_t*)words_of_bytes)}, {{"round-up-to-multiple-of-8"}, ((uint8_t*)round_up_to_multiple_of_8)}, {{"ptr-cast"}, ((uint8_t*)ptr_cast_0)}, {{"-"}, ((uint8_t*)_minus_0)}, {{"-"}, ((uint8_t*)_minus_1)}, {{"<=>"}, ((uint8_t*)_compare_0)}, {{"cmp"}, ((uint8_t*)cmp_0)}, {{"<"}, ((uint8_t*)_less_0)}, {{"<="}, ((uint8_t*)_lessOrEqual_0)}, {{"!"}, ((uint8_t*)_not)}, {{"mark-range-recur"}, ((uint8_t*)mark_range_recur)}, {{">"}, ((uint8_t*)_greater_0)}, {{"rt-main"}, ((uint8_t*)rt_main)}, {{"lbv"}, ((uint8_t*)lbv)}, {{"lock-by-val"}, ((uint8_t*)lock_by_val)}, {{"atomic-bool"}, ((uint8_t*)_atomic_bool)}, {{"create-condition"}, ((uint8_t*)create_condition)}, {{"hard-assert-posix-error"}, ((uint8_t*)hard_assert_posix_error)}, {{"CLOCK_MONOTONIC"}, ((uint8_t*)CLOCK_MONOTONIC)}, {{"island"}, ((uint8_t*)island)}, {{"task-queue"}, ((uint8_t*)task_queue)}, {{"mut-list-by-val-with-capacity-from-unmanaged-memory"}, ((uint8_t*)mut_list_by_val_with_capacity_from_unmanaged_memory)}, {{"mut-arr"}, ((uint8_t*)mut_arr_0)}, {{"unmanaged-alloc-zeroed-elements"}, ((uint8_t*)unmanaged_alloc_zeroed_elements)}, {{"unmanaged-alloc-elements"}, ((uint8_t*)unmanaged_alloc_elements_0)}, {{"unmanaged-alloc-bytes"}, ((uint8_t*)unmanaged_alloc_bytes)}, {{"!="}, ((uint8_t*)_notEqual_0)}, {{"set-zero-range"}, ((uint8_t*)set_zero_range_0)}, {{"drop"}, ((uint8_t*)drop_0)}, {{"default-exception-handler"}, ((uint8_t*)default_exception_handler)}, {{"print-err-no-newline"}, ((uint8_t*)print_err_no_newline)}, {{"write-no-newline"}, ((uint8_t*)write_no_newline)}, {{"as-any-const-ptr"}, ((uint8_t*)as_any_const_ptr_0)}, {{"size-bytes"}, ((uint8_t*)size_bytes)}, {{"!="}, ((uint8_t*)_notEqual_1)}, {{"todo"}, ((uint8_t*)todo_0)}, {{"stderr"}, ((uint8_t*)stderr)}, {{"print-err"}, ((uint8_t*)print_err)}, {{"to-str"}, ((uint8_t*)to_str_0)}, {{"writer"}, ((uint8_t*)writer)}, {{"mut-list"}, ((uint8_t*)mut_list_0)}, {{"mut-arr"}, ((uint8_t*)mut_arr_1)}, {{"~="}, ((uint8_t*)_concatEquals_0)}, {{"~="}, ((uint8_t*)_concatEquals_1)}, {{"each"}, ((uint8_t*)each_0)}, {{"each-recur"}, ((uint8_t*)each_recur_0)}, {{"=="}, ((uint8_t*)_equal_0)}, {{"!="}, ((uint8_t*)_notEqual_2)}, {{"subscript"}, ((uint8_t*)subscript_0)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_63)}, {{"*"}, ((uint8_t*)_times_0)}, {{"+"}, ((uint8_t*)_plus_0)}, {{"end-ptr"}, ((uint8_t*)end_ptr_0)}, {{"~="}, ((uint8_t*)_concatEquals_2)}, {{"incr-capacity!"}, ((uint8_t*)incr_capacity__e_0)}, {{"ensure-capacity"}, ((uint8_t*)ensure_capacity_0)}, {{"capacity"}, ((uint8_t*)capacity_0)}, {{"size"}, ((uint8_t*)size_0)}, {{"increase-capacity-to!"}, ((uint8_t*)increase_capacity_to__e_0)}, {{"assert"}, ((uint8_t*)assert_0)}, {{"throw"}, ((uint8_t*)throw_0)}, {{"throw"}, ((uint8_t*)throw_1)}, {{"get-exception-ctx"}, ((uint8_t*)get_exception_ctx)}, {{"!="}, ((uint8_t*)_notEqual_3)}, {{"number-to-throw"}, ((uint8_t*)number_to_throw)}, {{"hard-unreachable"}, ((uint8_t*)hard_unreachable_0)}, {{"get-backtrace"}, ((uint8_t*)get_backtrace)}, {{"try-alloc-backtrace-arrs"}, ((uint8_t*)try_alloc_backtrace_arrs)}, {{"try-alloc-uninitialized"}, ((uint8_t*)try_alloc_uninitialized_0)}, {{"try-alloc"}, ((uint8_t*)try_alloc)}, {{"try-gc-alloc"}, ((uint8_t*)try_gc_alloc)}, {{"acquire!"}, ((uint8_t*)acquire__e)}, {{"acquire-recur!"}, ((uint8_t*)acquire_recur__e)}, {{"try-acquire!"}, ((uint8_t*)try_acquire__e)}, {{"try-set!"}, ((uint8_t*)try_set__e)}, {{"try-change!"}, ((uint8_t*)try_change__e)}, {{"yield-thread"}, ((uint8_t*)yield_thread)}, {{"try-gc-alloc-recur"}, ((uint8_t*)try_gc_alloc_recur)}, {{"<=>"}, ((uint8_t*)_compare_1)}, {{"<"}, ((uint8_t*)_less_1)}, {{"range-free"}, ((uint8_t*)range_free)}, {{"maybe-set-needs-gc!"}, ((uint8_t*)maybe_set_needs_gc__e)}, {{"-"}, ((uint8_t*)_minus_2)}, {{"release!"}, ((uint8_t*)release__e)}, {{"must-unset!"}, ((uint8_t*)must_unset__e)}, {{"try-unset!"}, ((uint8_t*)try_unset__e)}, {{"get-gc"}, ((uint8_t*)get_gc)}, {{"get-gc-ctx"}, ((uint8_t*)get_gc_ctx_0)}, {{"try-alloc-uninitialized"}, ((uint8_t*)try_alloc_uninitialized_1)}, {{"try-alloc-uninitialized"}, ((uint8_t*)try_alloc_uninitialized_2)}, {{"code-ptrs-size"}, ((uint8_t*)code_ptrs_size)}, {{"copy-data-from!"}, ((uint8_t*)copy_data_from__e_0)}, {{"as-any-const-ptr"}, ((uint8_t*)as_any_const_ptr_1)}, {{"sort!"}, ((uint8_t*)sort__e_0)}, {{"swap!"}, ((uint8_t*)swap__e_0)}, {{"subscript"}, ((uint8_t*)subscript_1)}, {{"set-subscript"}, ((uint8_t*)set_subscript_0)}, {{"partition!"}, ((uint8_t*)partition__e)}, {{"=="}, ((uint8_t*)_equal_1)}, {{"<=>"}, ((uint8_t*)_compare_2)}, {{"<=>"}, ((uint8_t*)_compare_3)}, {{"<"}, ((uint8_t*)_less_2)}, {{"fill-code-names!"}, ((uint8_t*)fill_code_names__e)}, {{"<=>"}, ((uint8_t*)_compare_4)}, {{"<"}, ((uint8_t*)_less_3)}, {{"get-fun-name"}, ((uint8_t*)get_fun_name)}, {{"subscript"}, ((uint8_t*)subscript_2)}, {{"*"}, ((uint8_t*)_times_1)}, {{"+"}, ((uint8_t*)_plus_1)}, {{"*"}, ((uint8_t*)_times_2)}, {{"+"}, ((uint8_t*)_plus_2)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_0)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_1)}, {{"uninitialized-mut-arr"}, ((uint8_t*)uninitialized_mut_arr_0)}, {{"mut-arr"}, ((uint8_t*)mut_arr_2)}, {{"alloc-uninitialized"}, ((uint8_t*)alloc_uninitialized_0)}, {{"alloc"}, ((uint8_t*)alloc)}, {{"gc-alloc"}, ((uint8_t*)gc_alloc)}, {{"todo"}, ((uint8_t*)todo_1)}, {{"copy-data-from!"}, ((uint8_t*)copy_data_from__e_1)}, {{"set-zero-elements"}, ((uint8_t*)set_zero_elements_0)}, {{"set-zero-range"}, ((uint8_t*)set_zero_range_1)}, {{"subscript"}, ((uint8_t*)subscript_3)}, {{"subscript"}, ((uint8_t*)subscript_4)}, {{"->"}, ((uint8_t*)_arrow_0)}, {{"+"}, ((uint8_t*)_plus_3)}, {{">="}, ((uint8_t*)_greaterOrEqual)}, {{"round-up-to-power-of-two"}, ((uint8_t*)round_up_to_power_of_two)}, {{"round-up-to-power-of-two-recur"}, ((uint8_t*)round_up_to_power_of_two_recur)}, {{"*"}, ((uint8_t*)_times_3)}, {{"/"}, ((uint8_t*)_divide)}, {{"forbid"}, ((uint8_t*)forbid)}, {{"set-subscript"}, ((uint8_t*)set_subscript_1)}, {{"is-empty"}, ((uint8_t*)is_empty_0)}, {{"is-empty"}, ((uint8_t*)is_empty_1)}, {{"each"}, ((uint8_t*)each_1)}, {{"each-recur"}, ((uint8_t*)each_recur_1)}, {{"=="}, ((uint8_t*)_equal_2)}, {{"!="}, ((uint8_t*)_notEqual_4)}, {{"subscript"}, ((uint8_t*)subscript_5)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_159)}, {{"*"}, ((uint8_t*)_times_4)}, {{"+"}, ((uint8_t*)_plus_4)}, {{"end-ptr"}, ((uint8_t*)end_ptr_1)}, {{"~="}, ((uint8_t*)_concatEquals_3)}, {{"to-str"}, ((uint8_t*)to_str_1)}, {{"arr-from-begin-end"}, ((uint8_t*)arr_from_begin_end_0)}, {{"<=>"}, ((uint8_t*)_compare_5)}, {{"<=>"}, ((uint8_t*)_compare_6)}, {{"<="}, ((uint8_t*)_lessOrEqual_1)}, {{"<"}, ((uint8_t*)_less_4)}, {{"-"}, ((uint8_t*)_minus_3)}, {{"-"}, ((uint8_t*)_minus_4)}, {{"find-cstr-end"}, ((uint8_t*)find_cstr_end)}, {{"find-char-in-cstr"}, ((uint8_t*)find_char_in_cstr)}, {{"=="}, ((uint8_t*)_equal_3)}, {{"hard-unreachable"}, ((uint8_t*)hard_unreachable_1)}, {{"move-to-str!"}, ((uint8_t*)move_to_str__e)}, {{"move-to-arr!"}, ((uint8_t*)move_to_arr__e_0)}, {{"cast-immutable"}, ((uint8_t*)cast_immutable_0)}, {{"move-to-mut-arr!"}, ((uint8_t*)move_to_mut_arr__e_0)}, {{"get-global-ctx"}, ((uint8_t*)get_global_ctx)}, {{"default-log-handler"}, ((uint8_t*)default_log_handler)}, {{"print"}, ((uint8_t*)print)}, {{"print-no-newline"}, ((uint8_t*)print_no_newline)}, {{"stdout"}, ((uint8_t*)stdout)}, {{"~"}, ((uint8_t*)_tilde_0)}, {{"~"}, ((uint8_t*)_tilde_1)}, {{"to-str"}, ((uint8_t*)to_str_2)}, {{"gc"}, ((uint8_t*)gc)}, {{"validate-gc"}, ((uint8_t*)validate_gc)}, {{"<=>"}, ((uint8_t*)_compare_7)}, {{"<="}, ((uint8_t*)_lessOrEqual_2)}, {{"<"}, ((uint8_t*)_less_5)}, {{"<="}, ((uint8_t*)_lessOrEqual_3)}, {{"thread-safe-counter"}, ((uint8_t*)thread_safe_counter_0)}, {{"thread-safe-counter"}, ((uint8_t*)thread_safe_counter_1)}, {{"add-main-task"}, ((uint8_t*)add_main_task)}, {{"exception-ctx"}, ((uint8_t*)exception_ctx)}, {{"log-ctx"}, ((uint8_t*)log_ctx)}, {{"perf-ctx"}, ((uint8_t*)perf_ctx)}, {{"mut-arr"}, ((uint8_t*)mut_arr_3)}, {{"ctx"}, ((uint8_t*)ctx)}, {{"get-gc-ctx"}, ((uint8_t*)get_gc_ctx_1)}, {{"add-first-task"}, ((uint8_t*)add_first_task)}, {{"then-void"}, ((uint8_t*)then_void)}, {{"then"}, ((uint8_t*)then)}, {{"unresolved"}, ((uint8_t*)unresolved)}, {{"callback!"}, ((uint8_t*)callback__e_0)}, {{"with-lock"}, ((uint8_t*)with_lock_0)}, {{"subscript"}, ((uint8_t*)subscript_6)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_213)}, {{"subscript"}, ((uint8_t*)subscript_7)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_215)}, {{"forward-to!"}, ((uint8_t*)forward_to__e)}, {{"callback!"}, ((uint8_t*)callback__e_1)}, {{"subscript"}, ((uint8_t*)subscript_8)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_220)}, {{"resolve-or-reject!"}, ((uint8_t*)resolve_or_reject__e)}, {{"with-lock"}, ((uint8_t*)with_lock_1)}, {{"subscript"}, ((uint8_t*)subscript_9)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_225)}, {{"call-callbacks!"}, ((uint8_t*)call_callbacks__e)}, {{"subscript"}, ((uint8_t*)subscript_10)}, {{"get-island"}, ((uint8_t*)get_island)}, {{"subscript"}, ((uint8_t*)subscript_11)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_0)}, {{"subscript"}, ((uint8_t*)subscript_12)}, {{"*"}, ((uint8_t*)_times_5)}, {{"+"}, ((uint8_t*)_plus_5)}, {{"add-task"}, ((uint8_t*)add_task_0)}, {{"add-task"}, ((uint8_t*)add_task_1)}, {{"task-queue-node"}, ((uint8_t*)task_queue_node)}, {{"insert-task!"}, ((uint8_t*)insert_task__e)}, {{"size"}, ((uint8_t*)size_1)}, {{"size-recur"}, ((uint8_t*)size_recur)}, {{"insert-recur"}, ((uint8_t*)insert_recur)}, {{"tasks"}, ((uint8_t*)tasks)}, {{"broadcast!"}, ((uint8_t*)broadcast__e)}, {{"no-timestamp"}, ((uint8_t*)no_timestamp)}, {{"catch"}, ((uint8_t*)catch)}, {{"catch-with-exception-ctx"}, ((uint8_t*)catch_with_exception_ctx)}, {{"zero"}, ((uint8_t*)zero_0)}, {{"zero"}, ((uint8_t*)zero_1)}, {{"zero"}, ((uint8_t*)zero_2)}, {{"zero"}, ((uint8_t*)zero_3)}, {{"subscript"}, ((uint8_t*)subscript_13)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_257)}, {{"subscript"}, ((uint8_t*)subscript_14)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_259)}, {{"reject!"}, ((uint8_t*)reject__e)}, {{"subscript"}, ((uint8_t*)subscript_15)}, {{"subscript"}, ((uint8_t*)subscript_16)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_267)}, {{"cur-island-and-exclusion"}, ((uint8_t*)cur_island_and_exclusion)}, {{"delay"}, ((uint8_t*)delay)}, {{"resolved"}, ((uint8_t*)resolved_0)}, {{"tail"}, ((uint8_t*)tail_0)}, {{"is-empty"}, ((uint8_t*)is_empty_2)}, {{"subscript"}, ((uint8_t*)subscript_17)}, {{"+"}, ((uint8_t*)_plus_6)}, {{"map"}, ((uint8_t*)map_0)}, {{"make-arr"}, ((uint8_t*)make_arr_0)}, {{"alloc-uninitialized"}, ((uint8_t*)alloc_uninitialized_1)}, {{"fill-ptr-range"}, ((uint8_t*)fill_ptr_range_0)}, {{"fill-ptr-range-recur"}, ((uint8_t*)fill_ptr_range_recur_0)}, {{"!="}, ((uint8_t*)_notEqual_5)}, {{"set-subscript"}, ((uint8_t*)set_subscript_2)}, {{"subscript"}, ((uint8_t*)subscript_18)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_287)}, {{"subscript"}, ((uint8_t*)subscript_19)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_289)}, {{"subscript"}, ((uint8_t*)subscript_20)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_1)}, {{"subscript"}, ((uint8_t*)subscript_21)}, {{"*"}, ((uint8_t*)_times_6)}, {{"handle-exceptions"}, ((uint8_t*)handle_exceptions)}, {{"subscript"}, ((uint8_t*)subscript_22)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_299)}, {{"exception-handler"}, ((uint8_t*)exception_handler)}, {{"get-cur-island"}, ((uint8_t*)get_cur_island)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_304)}, {{"run-threads"}, ((uint8_t*)run_threads)}, {{"unmanaged-alloc-elements"}, ((uint8_t*)unmanaged_alloc_elements_1)}, {{"start-threads-recur"}, ((uint8_t*)start_threads_recur)}, {{"create-one-thread"}, ((uint8_t*)create_one_thread)}, {{"null"}, ((uint8_t*)null_0)}, {{"!="}, ((uint8_t*)_notEqual_6)}, {{"EAGAIN"}, ((uint8_t*)EAGAIN)}, {{"as-cell"}, ((uint8_t*)as_cell)}, {{"thread-fun"}, ((uint8_t*)thread_fun)}, {{"thread-function"}, ((uint8_t*)thread_function)}, {{"thread-function-recur"}, ((uint8_t*)thread_function_recur)}, {{"assert-islands-are-shut-down"}, ((uint8_t*)assert_islands_are_shut_down)}, {{"noctx-at"}, ((uint8_t*)noctx_at_0)}, {{"hard-forbid"}, ((uint8_t*)hard_forbid)}, {{"is-empty"}, ((uint8_t*)is_empty_3)}, {{"is-empty"}, ((uint8_t*)is_empty_4)}, {{"get-sequence"}, ((uint8_t*)get_sequence)}, {{"choose-task"}, ((uint8_t*)choose_task)}, {{"get-monotime-nsec"}, ((uint8_t*)get_monotime_nsec)}, {{"*"}, ((uint8_t*)_times_7)}, {{"todo"}, ((uint8_t*)todo_2)}, {{"choose-task-recur"}, ((uint8_t*)choose_task_recur)}, {{"choose-task-in-island"}, ((uint8_t*)choose_task_in_island)}, {{"pop-task!"}, ((uint8_t*)pop_task__e)}, {{"in"}, ((uint8_t*)in_0)}, {{"in"}, ((uint8_t*)in_1)}, {{"in-recur"}, ((uint8_t*)in_recur_0)}, {{"noctx-at"}, ((uint8_t*)noctx_at_1)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_2)}, {{"subscript"}, ((uint8_t*)subscript_23)}, {{"*"}, ((uint8_t*)_times_8)}, {{"+"}, ((uint8_t*)_plus_7)}, {{"temp-as-arr"}, ((uint8_t*)temp_as_arr_0)}, {{"temp-as-arr"}, ((uint8_t*)temp_as_arr_1)}, {{"temp-as-mut-arr"}, ((uint8_t*)temp_as_mut_arr_0)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_2)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_3)}, {{"pop-recur!"}, ((uint8_t*)pop_recur__e)}, {{"to-opt-time"}, ((uint8_t*)to_opt_time)}, {{"push-capacity-must-be-sufficient!"}, ((uint8_t*)push_capacity_must_be_sufficient__e)}, {{"capacity"}, ((uint8_t*)capacity_1)}, {{"size"}, ((uint8_t*)size_2)}, {{"set-subscript"}, ((uint8_t*)set_subscript_3)}, {{"is-no-task"}, ((uint8_t*)is_no_task)}, {{"min-time"}, ((uint8_t*)min_time)}, {{"min"}, ((uint8_t*)min_0)}, {{"do-task"}, ((uint8_t*)do_task)}, {{"return-task!"}, ((uint8_t*)return_task__e)}, {{"noctx-must-remove-unordered!"}, ((uint8_t*)noctx_must_remove_unordered__e)}, {{"noctx-must-remove-unordered-recur!"}, ((uint8_t*)noctx_must_remove_unordered_recur__e)}, {{"subscript"}, ((uint8_t*)subscript_24)}, {{"drop"}, ((uint8_t*)drop_1)}, {{"noctx-remove-unordered-at!"}, ((uint8_t*)noctx_remove_unordered_at__e)}, {{"return-ctx"}, ((uint8_t*)return_ctx)}, {{"return-gc-ctx"}, ((uint8_t*)return_gc_ctx)}, {{"run-garbage-collection"}, ((uint8_t*)run_garbage_collection)}, {{"mark-visit"}, ((uint8_t*)mark_visit_363)}, {{"clear-free-mem!"}, ((uint8_t*)clear_free_mem__e)}, {{"!="}, ((uint8_t*)_notEqual_7)}, {{"wait-on"}, ((uint8_t*)wait_on)}, {{"to-timespec"}, ((uint8_t*)to_timespec)}, {{"ETIMEDOUT"}, ((uint8_t*)ETIMEDOUT)}, {{"join-threads-recur"}, ((uint8_t*)join_threads_recur)}, {{"join-one-thread"}, ((uint8_t*)join_one_thread)}, {{"EINVAL"}, ((uint8_t*)EINVAL)}, {{"ESRCH"}, ((uint8_t*)ESRCH)}, {{"*"}, ((uint8_t*)_times_9)}, {{"unmanaged-free"}, ((uint8_t*)unmanaged_free_0)}, {{"unmanaged-free"}, ((uint8_t*)unmanaged_free_1)}, {{"destroy-condition"}, ((uint8_t*)destroy_condition)}, {{"main"}, ((uint8_t*)main_0)}, {{"resolved"}, ((uint8_t*)resolved_1)}, {{"parse-named-args"}, ((uint8_t*)parse_named_args_0)}, {{"parse-command-dynamic"}, ((uint8_t*)parse_command_dynamic)}, {{"find-index"}, ((uint8_t*)find_index)}, {{"find-index-recur"}, ((uint8_t*)find_index_recur)}, {{"subscript"}, ((uint8_t*)subscript_25)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_448)}, {{"subscript"}, ((uint8_t*)subscript_26)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_3)}, {{"subscript"}, ((uint8_t*)subscript_27)}, {{"*"}, ((uint8_t*)_times_10)}, {{"+"}, ((uint8_t*)_plus_8)}, {{"starts-with"}, ((uint8_t*)starts_with_0)}, {{"=="}, ((uint8_t*)_equal_4)}, {{"arr-equal"}, ((uint8_t*)arr_equal)}, {{"equal-recur"}, ((uint8_t*)equal_recur)}, {{"starts-with"}, ((uint8_t*)starts_with_1)}, {{"=="}, ((uint8_t*)_equal_5)}, {{"<=>"}, ((uint8_t*)_compare_8)}, {{"<=>"}, ((uint8_t*)_compare_9)}, {{"<=>"}, ((uint8_t*)_compare_10)}, {{"cmp"}, ((uint8_t*)cmp_1)}, {{"arr-compare"}, ((uint8_t*)arr_compare)}, {{"compare-recur"}, ((uint8_t*)compare_recur)}, {{"dict"}, ((uint8_t*)dict_0)}, {{"sort-by"}, ((uint8_t*)sort_by_0)}, {{"sort"}, ((uint8_t*)sort_0)}, {{"mut-arr"}, ((uint8_t*)mut_arr_4)}, {{"make-mut-arr"}, ((uint8_t*)make_mut_arr_0)}, {{"uninitialized-mut-arr"}, ((uint8_t*)uninitialized_mut_arr_1)}, {{"mut-arr"}, ((uint8_t*)mut_arr_5)}, {{"alloc-uninitialized"}, ((uint8_t*)alloc_uninitialized_2)}, {{"fill-ptr-range"}, ((uint8_t*)fill_ptr_range_1)}, {{"fill-ptr-range-recur"}, ((uint8_t*)fill_ptr_range_recur_1)}, {{"set-subscript"}, ((uint8_t*)set_subscript_4)}, {{"subscript"}, ((uint8_t*)subscript_28)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_479)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_4)}, {{"subscript"}, ((uint8_t*)subscript_29)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_4)}, {{"subscript"}, ((uint8_t*)subscript_30)}, {{"*"}, ((uint8_t*)_times_11)}, {{"+"}, ((uint8_t*)_plus_9)}, {{"sort!"}, ((uint8_t*)sort__e_1)}, {{"is-empty"}, ((uint8_t*)is_empty_5)}, {{"size"}, ((uint8_t*)size_3)}, {{"insertion-sort-recur!"}, ((uint8_t*)insertion_sort_recur__e_0)}, {{"!="}, ((uint8_t*)_notEqual_8)}, {{"insert!"}, ((uint8_t*)insert__e_0)}, {{"=="}, ((uint8_t*)_equal_6)}, {{"subscript"}, ((uint8_t*)subscript_31)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_495)}, {{"end-ptr"}, ((uint8_t*)end_ptr_2)}, {{"cast-immutable"}, ((uint8_t*)cast_immutable_1)}, {{"subscript"}, ((uint8_t*)subscript_32)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_499)}, {{"subscript"}, ((uint8_t*)subscript_33)}, {{"parse-named-args"}, ((uint8_t*)parse_named_args_1)}, {{"mut-dict"}, ((uint8_t*)mut_dict_0)}, {{"mut-list"}, ((uint8_t*)mut_list_1)}, {{"mut-arr"}, ((uint8_t*)mut_arr_6)}, {{"parse-named-args-recur"}, ((uint8_t*)parse_named_args_recur)}, {{"force"}, ((uint8_t*)force_0)}, {{"force"}, ((uint8_t*)force_1)}, {{"throw"}, ((uint8_t*)throw_2)}, {{"throw"}, ((uint8_t*)throw_3)}, {{"hard-unreachable"}, ((uint8_t*)hard_unreachable_2)}, {{"try-remove-start"}, ((uint8_t*)try_remove_start_0)}, {{"try-remove-start"}, ((uint8_t*)try_remove_start_1)}, {{"tail"}, ((uint8_t*)tail_1)}, {{"is-empty"}, ((uint8_t*)is_empty_6)}, {{"set-subscript"}, ((uint8_t*)set_subscript_5)}, {{"insert-into-key-match-or-empty-slot!"}, ((uint8_t*)insert_into_key_match_or_empty_slot__e_0)}, {{"find-insert-ptr"}, ((uint8_t*)find_insert_ptr_0)}, {{"binary-search-insert-ptr"}, ((uint8_t*)binary_search_insert_ptr_0)}, {{"binary-search-insert-ptr"}, ((uint8_t*)binary_search_insert_ptr_1)}, {{"binary-search-compare-recur"}, ((uint8_t*)binary_search_compare_recur_0)}, {{"=="}, ((uint8_t*)_equal_7)}, {{"+"}, ((uint8_t*)_plus_10)}, {{"-"}, ((uint8_t*)_minus_5)}, {{"-"}, ((uint8_t*)_minus_6)}, {{"subscript"}, ((uint8_t*)subscript_34)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_530)}, {{"*"}, ((uint8_t*)_times_12)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_5)}, {{"end-ptr"}, ((uint8_t*)end_ptr_3)}, {{"size"}, ((uint8_t*)size_4)}, {{"temp-as-mut-arr"}, ((uint8_t*)temp_as_mut_arr_1)}, {{"mut-arr"}, ((uint8_t*)mut_arr_7)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_6)}, {{"!="}, ((uint8_t*)_notEqual_9)}, {{"end-ptr"}, ((uint8_t*)end_ptr_4)}, {{"is-empty"}, ((uint8_t*)is_empty_7)}, {{"->"}, ((uint8_t*)_arrow_1)}, {{"<"}, ((uint8_t*)_less_6)}, {{"add-pair!"}, ((uint8_t*)add_pair__e_0)}, {{"is-empty"}, ((uint8_t*)is_empty_8)}, {{"~="}, ((uint8_t*)_concatEquals_4)}, {{"incr-capacity!"}, ((uint8_t*)incr_capacity__e_1)}, {{"ensure-capacity"}, ((uint8_t*)ensure_capacity_1)}, {{"capacity"}, ((uint8_t*)capacity_2)}, {{"increase-capacity-to!"}, ((uint8_t*)increase_capacity_to__e_1)}, {{"uninitialized-mut-arr"}, ((uint8_t*)uninitialized_mut_arr_2)}, {{"alloc-uninitialized"}, ((uint8_t*)alloc_uninitialized_3)}, {{"copy-data-from!"}, ((uint8_t*)copy_data_from__e_2)}, {{"as-any-const-ptr"}, ((uint8_t*)as_any_const_ptr_2)}, {{"set-zero-elements"}, ((uint8_t*)set_zero_elements_1)}, {{"set-zero-range"}, ((uint8_t*)set_zero_range_2)}, {{"subscript"}, ((uint8_t*)subscript_35)}, {{"subscript"}, ((uint8_t*)subscript_36)}, {{"set-subscript"}, ((uint8_t*)set_subscript_6)}, {{"insert-linear!"}, ((uint8_t*)insert_linear__e_0)}, {{"subscript"}, ((uint8_t*)subscript_37)}, {{"subscript"}, ((uint8_t*)subscript_38)}, {{"move-right!"}, ((uint8_t*)move_right__e_0)}, {{"-"}, ((uint8_t*)_minus_7)}, {{"set-subscript"}, ((uint8_t*)set_subscript_7)}, {{">"}, ((uint8_t*)_greater_1)}, {{"compact-if-needed!"}, ((uint8_t*)compact_if_needed__e_0)}, {{"total-pairs-size"}, ((uint8_t*)total_pairs_size_0)}, {{"total-pairs-size-recur"}, ((uint8_t*)total_pairs_size_recur_0)}, {{"compact!"}, ((uint8_t*)compact__e_0)}, {{"filter!"}, ((uint8_t*)filter__e_0)}, {{"filter-recur!"}, ((uint8_t*)filter_recur__e_0)}, {{"subscript"}, ((uint8_t*)subscript_39)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_574)}, {{"merge-no-duplicates!"}, ((uint8_t*)merge_no_duplicates__e_0)}, {{"swap!"}, ((uint8_t*)swap__e_1)}, {{"unsafe-set-size!"}, ((uint8_t*)unsafe_set_size__e_0)}, {{"reserve"}, ((uint8_t*)reserve_0)}, {{"-"}, ((uint8_t*)_minus_8)}, {{"merge-reverse-recur!"}, ((uint8_t*)merge_reverse_recur__e_0)}, {{"subscript"}, ((uint8_t*)subscript_40)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_583)}, {{"!="}, ((uint8_t*)_notEqual_10)}, {{"mut-arr-from-begin-end"}, ((uint8_t*)mut_arr_from_begin_end_0)}, {{"<=>"}, ((uint8_t*)_compare_11)}, {{"<="}, ((uint8_t*)_lessOrEqual_4)}, {{"<"}, ((uint8_t*)_less_7)}, {{"arr-from-begin-end"}, ((uint8_t*)arr_from_begin_end_1)}, {{"<=>"}, ((uint8_t*)_compare_12)}, {{"<="}, ((uint8_t*)_lessOrEqual_5)}, {{"<"}, ((uint8_t*)_less_8)}, {{"copy-from!"}, ((uint8_t*)copy_from__e_0)}, {{"empty!"}, ((uint8_t*)empty__e_0)}, {{"pop-n!"}, ((uint8_t*)pop_n__e_0)}, {{"assert-comparison-not-equal"}, ((uint8_t*)assert_comparison_not_equal)}, {{"unreachable"}, ((uint8_t*)unreachable)}, {{"throw"}, ((uint8_t*)throw_4)}, {{"throw"}, ((uint8_t*)throw_5)}, {{"hard-unreachable"}, ((uint8_t*)hard_unreachable_3)}, {{"move-to-dict!"}, ((uint8_t*)move_to_dict__e_0)}, {{"move-to-arr!"}, ((uint8_t*)move_to_arr__e_1)}, {{"map-to-arr"}, ((uint8_t*)map_to_arr_0)}, {{"map-to-arr"}, ((uint8_t*)map_to_arr_1)}, {{"map-to-mut-arr"}, ((uint8_t*)map_to_mut_arr_0)}, {{"subscript"}, ((uint8_t*)subscript_41)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_608)}, {{"subscript"}, ((uint8_t*)subscript_42)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_611)}, {{"force"}, ((uint8_t*)force_2)}, {{"force"}, ((uint8_t*)force_3)}, {{"throw"}, ((uint8_t*)throw_6)}, {{"throw"}, ((uint8_t*)throw_7)}, {{"hard-unreachable"}, ((uint8_t*)hard_unreachable_4)}, {{"->"}, ((uint8_t*)_arrow_2)}, {{"empty!"}, ((uint8_t*)empty__e_1)}, {{"assert"}, ((uint8_t*)assert_1)}, {{"fill-mut-list"}, ((uint8_t*)fill_mut_list)}, {{"fill-mut-arr"}, ((uint8_t*)fill_mut_arr)}, {{"make-mut-arr"}, ((uint8_t*)make_mut_arr_1)}, {{"uninitialized-mut-arr"}, ((uint8_t*)uninitialized_mut_arr_3)}, {{"mut-arr"}, ((uint8_t*)mut_arr_8)}, {{"alloc-uninitialized"}, ((uint8_t*)alloc_uninitialized_4)}, {{"fill-ptr-range"}, ((uint8_t*)fill_ptr_range_2)}, {{"fill-ptr-range-recur"}, ((uint8_t*)fill_ptr_range_recur_2)}, {{"set-subscript"}, ((uint8_t*)set_subscript_8)}, {{"subscript"}, ((uint8_t*)subscript_43)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_632)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_7)}, {{"each"}, ((uint8_t*)each_2)}, {{"fold"}, ((uint8_t*)fold_0)}, {{"init-iters"}, ((uint8_t*)init_iters_0)}, {{"uninitialized-mut-arr"}, ((uint8_t*)uninitialized_mut_arr_4)}, {{"mut-arr"}, ((uint8_t*)mut_arr_9)}, {{"alloc-uninitialized"}, ((uint8_t*)alloc_uninitialized_5)}, {{"overlay-count"}, ((uint8_t*)overlay_count_0)}, {{"init-overlay-iters-recur!"}, ((uint8_t*)init_overlay_iters_recur__e_0)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_8)}, {{"fold-recur"}, ((uint8_t*)fold_recur_0)}, {{"is-empty"}, ((uint8_t*)is_empty_9)}, {{"size"}, ((uint8_t*)size_5)}, {{"fold"}, ((uint8_t*)fold_1)}, {{"fold-recur"}, ((uint8_t*)fold_recur_1)}, {{"=="}, ((uint8_t*)_equal_8)}, {{"subscript"}, ((uint8_t*)subscript_44)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_651)}, {{"end-ptr"}, ((uint8_t*)end_ptr_5)}, {{"subscript"}, ((uint8_t*)subscript_45)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_654)}, {{"is-empty"}, ((uint8_t*)is_empty_10)}, {{"find-least-key"}, ((uint8_t*)find_least_key_0)}, {{"fold"}, ((uint8_t*)fold_2)}, {{"fold"}, ((uint8_t*)fold_3)}, {{"fold-recur"}, ((uint8_t*)fold_recur_2)}, {{"=="}, ((uint8_t*)_equal_9)}, {{"subscript"}, ((uint8_t*)subscript_46)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_663)}, {{"*"}, ((uint8_t*)_times_13)}, {{"+"}, ((uint8_t*)_plus_11)}, {{"end-ptr"}, ((uint8_t*)end_ptr_6)}, {{"temp-as-arr"}, ((uint8_t*)temp_as_arr_2)}, {{"min"}, ((uint8_t*)min_1)}, {{"subscript"}, ((uint8_t*)subscript_47)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_5)}, {{"subscript"}, ((uint8_t*)subscript_48)}, {{"subscript"}, ((uint8_t*)subscript_49)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_6)}, {{"subscript"}, ((uint8_t*)subscript_50)}, {{"tail"}, ((uint8_t*)tail_2)}, {{"subscript"}, ((uint8_t*)subscript_51)}, {{"subscript"}, ((uint8_t*)subscript_52)}, {{"tail"}, ((uint8_t*)tail_3)}, {{"subscript"}, ((uint8_t*)subscript_53)}, {{"take-key"}, ((uint8_t*)take_key_0)}, {{"take-key-recur"}, ((uint8_t*)take_key_recur_0)}, {{"tail"}, ((uint8_t*)tail_4)}, {{"is-empty"}, ((uint8_t*)is_empty_11)}, {{"set-subscript"}, ((uint8_t*)set_subscript_9)}, {{"unsafe-set-at!"}, ((uint8_t*)unsafe_set_at__e_0)}, {{"set-subscript"}, ((uint8_t*)set_subscript_10)}, {{"opt-or"}, ((uint8_t*)opt_or_0)}, {{"subscript"}, ((uint8_t*)subscript_54)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_690)}, {{"index-of"}, ((uint8_t*)index_of)}, {{"ptr-of"}, ((uint8_t*)ptr_of)}, {{"ptr-of-recur"}, ((uint8_t*)ptr_of_recur)}, {{"=="}, ((uint8_t*)_equal_10)}, {{"end-ptr"}, ((uint8_t*)end_ptr_7)}, {{"-"}, ((uint8_t*)_minus_9)}, {{"-"}, ((uint8_t*)_minus_10)}, {{"set-deref"}, ((uint8_t*)set_deref_0)}, {{"finish"}, ((uint8_t*)finish)}, {{"to-str"}, ((uint8_t*)to_str_3)}, {{"with-value"}, ((uint8_t*)with_value_0)}, {{"with-str"}, ((uint8_t*)with_str)}, {{"interp"}, ((uint8_t*)interp)}, {{"subscript"}, ((uint8_t*)subscript_55)}, {{"subscript"}, ((uint8_t*)subscript_56)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_9)}, {{"set-subscript"}, ((uint8_t*)set_subscript_11)}, {{"*"}, ((uint8_t*)_times_14)}, {{"move-to-arr!"}, ((uint8_t*)move_to_arr__e_2)}, {{"cast-immutable"}, ((uint8_t*)cast_immutable_2)}, {{"move-to-mut-arr!"}, ((uint8_t*)move_to_mut_arr__e_1)}, {{"mut-arr"}, ((uint8_t*)mut_arr_10)}, {{"print-help"}, ((uint8_t*)print_help)}, {{"subscript"}, ((uint8_t*)subscript_57)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_7)}, {{"subscript"}, ((uint8_t*)subscript_58)}, {{"*"}, ((uint8_t*)_times_15)}, {{"+"}, ((uint8_t*)_plus_12)}, {{"force"}, ((uint8_t*)force_4)}, {{"force"}, ((uint8_t*)force_5)}, {{"throw"}, ((uint8_t*)throw_8)}, {{"throw"}, ((uint8_t*)throw_9)}, {{"hard-unreachable"}, ((uint8_t*)hard_unreachable_5)}, {{"parse-nat"}, ((uint8_t*)parse_nat)}, {{"with-reader"}, ((uint8_t*)with_reader)}, {{"reader"}, ((uint8_t*)reader)}, {{"subscript"}, ((uint8_t*)subscript_59)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_730)}, {{"is-empty"}, ((uint8_t*)is_empty_12)}, {{"is-empty"}, ((uint8_t*)is_empty_13)}, {{"take-nat!"}, ((uint8_t*)take_nat__e)}, {{"char-to-nat64"}, ((uint8_t*)char_to_nat64)}, {{"peek"}, ((uint8_t*)peek)}, {{"drop"}, ((uint8_t*)drop_2)}, {{"next!"}, ((uint8_t*)next__e)}, {{"take-nat-recur!"}, ((uint8_t*)take_nat_recur__e)}, {{"do-test"}, ((uint8_t*)do_test)}, {{"parent-path"}, ((uint8_t*)parent_path)}, {{"r-index-of"}, ((uint8_t*)r_index_of)}, {{"find-rindex"}, ((uint8_t*)find_rindex)}, {{"find-rindex-recur"}, ((uint8_t*)find_rindex_recur)}, {{"subscript"}, ((uint8_t*)subscript_60)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_746)}, {{"subscript"}, ((uint8_t*)subscript_61)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_8)}, {{"subscript"}, ((uint8_t*)subscript_62)}, {{"child-path"}, ((uint8_t*)child_path)}, {{"get-environ"}, ((uint8_t*)get_environ)}, {{"mut-dict"}, ((uint8_t*)mut_dict_1)}, {{"mut-list"}, ((uint8_t*)mut_list_2)}, {{"mut-arr"}, ((uint8_t*)mut_arr_11)}, {{"get-environ-recur"}, ((uint8_t*)get_environ_recur)}, {{"null"}, ((uint8_t*)null_1)}, {{"parse-environ-entry"}, ((uint8_t*)parse_environ_entry)}, {{"todo"}, ((uint8_t*)todo_3)}, {{"->"}, ((uint8_t*)_arrow_3)}, {{"set-subscript"}, ((uint8_t*)set_subscript_12)}, {{"insert-into-key-match-or-empty-slot!"}, ((uint8_t*)insert_into_key_match_or_empty_slot__e_1)}, {{"find-insert-ptr"}, ((uint8_t*)find_insert_ptr_1)}, {{"binary-search-insert-ptr"}, ((uint8_t*)binary_search_insert_ptr_2)}, {{"binary-search-insert-ptr"}, ((uint8_t*)binary_search_insert_ptr_3)}, {{"binary-search-compare-recur"}, ((uint8_t*)binary_search_compare_recur_1)}, {{"=="}, ((uint8_t*)_equal_11)}, {{"+"}, ((uint8_t*)_plus_13)}, {{"-"}, ((uint8_t*)_minus_11)}, {{"-"}, ((uint8_t*)_minus_12)}, {{"subscript"}, ((uint8_t*)subscript_63)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_772)}, {{"*"}, ((uint8_t*)_times_16)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_10)}, {{"end-ptr"}, ((uint8_t*)end_ptr_8)}, {{"size"}, ((uint8_t*)size_6)}, {{"temp-as-mut-arr"}, ((uint8_t*)temp_as_mut_arr_2)}, {{"mut-arr"}, ((uint8_t*)mut_arr_12)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_11)}, {{"!="}, ((uint8_t*)_notEqual_11)}, {{"end-ptr"}, ((uint8_t*)end_ptr_9)}, {{"is-empty"}, ((uint8_t*)is_empty_14)}, {{"->"}, ((uint8_t*)_arrow_4)}, {{"add-pair!"}, ((uint8_t*)add_pair__e_1)}, {{"is-empty"}, ((uint8_t*)is_empty_15)}, {{"~="}, ((uint8_t*)_concatEquals_5)}, {{"incr-capacity!"}, ((uint8_t*)incr_capacity__e_2)}, {{"ensure-capacity"}, ((uint8_t*)ensure_capacity_2)}, {{"capacity"}, ((uint8_t*)capacity_3)}, {{"increase-capacity-to!"}, ((uint8_t*)increase_capacity_to__e_2)}, {{"uninitialized-mut-arr"}, ((uint8_t*)uninitialized_mut_arr_5)}, {{"alloc-uninitialized"}, ((uint8_t*)alloc_uninitialized_6)}, {{"copy-data-from!"}, ((uint8_t*)copy_data_from__e_3)}, {{"as-any-const-ptr"}, ((uint8_t*)as_any_const_ptr_3)}, {{"set-zero-elements"}, ((uint8_t*)set_zero_elements_2)}, {{"set-zero-range"}, ((uint8_t*)set_zero_range_3)}, {{"subscript"}, ((uint8_t*)subscript_64)}, {{"subscript"}, ((uint8_t*)subscript_65)}, {{"set-subscript"}, ((uint8_t*)set_subscript_13)}, {{"insert-linear!"}, ((uint8_t*)insert_linear__e_1)}, {{"subscript"}, ((uint8_t*)subscript_66)}, {{"subscript"}, ((uint8_t*)subscript_67)}, {{"move-right!"}, ((uint8_t*)move_right__e_1)}, {{"set-subscript"}, ((uint8_t*)set_subscript_14)}, {{"compact-if-needed!"}, ((uint8_t*)compact_if_needed__e_1)}, {{"total-pairs-size"}, ((uint8_t*)total_pairs_size_1)}, {{"total-pairs-size-recur"}, ((uint8_t*)total_pairs_size_recur_1)}, {{"compact!"}, ((uint8_t*)compact__e_1)}, {{"filter!"}, ((uint8_t*)filter__e_1)}, {{"filter-recur!"}, ((uint8_t*)filter_recur__e_1)}, {{"subscript"}, ((uint8_t*)subscript_68)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_813)}, {{"merge-no-duplicates!"}, ((uint8_t*)merge_no_duplicates__e_1)}, {{"swap!"}, ((uint8_t*)swap__e_2)}, {{"unsafe-set-size!"}, ((uint8_t*)unsafe_set_size__e_1)}, {{"reserve"}, ((uint8_t*)reserve_1)}, {{"-"}, ((uint8_t*)_minus_13)}, {{"merge-reverse-recur!"}, ((uint8_t*)merge_reverse_recur__e_1)}, {{"subscript"}, ((uint8_t*)subscript_69)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_822)}, {{"!="}, ((uint8_t*)_notEqual_12)}, {{"mut-arr-from-begin-end"}, ((uint8_t*)mut_arr_from_begin_end_1)}, {{"<=>"}, ((uint8_t*)_compare_13)}, {{"<="}, ((uint8_t*)_lessOrEqual_6)}, {{"<"}, ((uint8_t*)_less_9)}, {{"arr-from-begin-end"}, ((uint8_t*)arr_from_begin_end_2)}, {{"<=>"}, ((uint8_t*)_compare_14)}, {{"<="}, ((uint8_t*)_lessOrEqual_7)}, {{"<"}, ((uint8_t*)_less_10)}, {{"copy-from!"}, ((uint8_t*)copy_from__e_1)}, {{"empty!"}, ((uint8_t*)empty__e_2)}, {{"pop-n!"}, ((uint8_t*)pop_n__e_1)}, {{"move-to-dict!"}, ((uint8_t*)move_to_dict__e_1)}, {{"dict"}, ((uint8_t*)dict_1)}, {{"sort-by"}, ((uint8_t*)sort_by_1)}, {{"sort"}, ((uint8_t*)sort_1)}, {{"mut-arr"}, ((uint8_t*)mut_arr_13)}, {{"make-mut-arr"}, ((uint8_t*)make_mut_arr_2)}, {{"uninitialized-mut-arr"}, ((uint8_t*)uninitialized_mut_arr_6)}, {{"mut-arr"}, ((uint8_t*)mut_arr_14)}, {{"alloc-uninitialized"}, ((uint8_t*)alloc_uninitialized_7)}, {{"fill-ptr-range"}, ((uint8_t*)fill_ptr_range_3)}, {{"fill-ptr-range-recur"}, ((uint8_t*)fill_ptr_range_recur_3)}, {{"set-subscript"}, ((uint8_t*)set_subscript_15)}, {{"subscript"}, ((uint8_t*)subscript_70)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_850)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_12)}, {{"subscript"}, ((uint8_t*)subscript_71)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_9)}, {{"subscript"}, ((uint8_t*)subscript_72)}, {{"*"}, ((uint8_t*)_times_17)}, {{"+"}, ((uint8_t*)_plus_14)}, {{"sort!"}, ((uint8_t*)sort__e_2)}, {{"is-empty"}, ((uint8_t*)is_empty_16)}, {{"size"}, ((uint8_t*)size_7)}, {{"insertion-sort-recur!"}, ((uint8_t*)insertion_sort_recur__e_1)}, {{"!="}, ((uint8_t*)_notEqual_13)}, {{"insert!"}, ((uint8_t*)insert__e_1)}, {{"subscript"}, ((uint8_t*)subscript_73)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_865)}, {{"end-ptr"}, ((uint8_t*)end_ptr_10)}, {{"cast-immutable"}, ((uint8_t*)cast_immutable_3)}, {{"subscript"}, ((uint8_t*)subscript_74)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_869)}, {{"move-to-arr!"}, ((uint8_t*)move_to_arr__e_3)}, {{"map-to-arr"}, ((uint8_t*)map_to_arr_2)}, {{"map-to-arr"}, ((uint8_t*)map_to_arr_3)}, {{"map-to-mut-arr"}, ((uint8_t*)map_to_mut_arr_1)}, {{"subscript"}, ((uint8_t*)subscript_75)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_877)}, {{"subscript"}, ((uint8_t*)subscript_76)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_880)}, {{"empty!"}, ((uint8_t*)empty__e_3)}, {{"first-failures"}, ((uint8_t*)first_failures)}, {{"subscript"}, ((uint8_t*)subscript_77)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_886)}, {{"run-crow-tests"}, ((uint8_t*)run_crow_tests)}, {{"list-tests"}, ((uint8_t*)list_tests)}, {{"mut-list"}, ((uint8_t*)mut_list_3)}, {{"mut-arr"}, ((uint8_t*)mut_arr_15)}, {{"each-child-recursive"}, ((uint8_t*)each_child_recursive_0)}, {{"each-child-recursive"}, ((uint8_t*)each_child_recursive_1)}, {{"is-dir"}, ((uint8_t*)is_dir_0)}, {{"is-dir"}, ((uint8_t*)is_dir_1)}, {{"get-stat"}, ((uint8_t*)get_stat)}, {{"stat"}, ((uint8_t*)stat_0)}, {{"errno"}, ((uint8_t*)errno)}, {{"ENOENT"}, ((uint8_t*)ENOENT)}, {{"todo"}, ((uint8_t*)todo_4)}, {{"throw"}, ((uint8_t*)throw_10)}, {{"throw"}, ((uint8_t*)throw_11)}, {{"hard-unreachable"}, ((uint8_t*)hard_unreachable_6)}, {{"with-value"}, ((uint8_t*)with_value_1)}, {{"S_IFMT"}, ((uint8_t*)S_IFMT)}, {{"S_IFDIR"}, ((uint8_t*)S_IFDIR)}, {{"to-c-str"}, ((uint8_t*)to_c_str)}, {{"each"}, ((uint8_t*)each_3)}, {{"each-recur"}, ((uint8_t*)each_recur_2)}, {{"!="}, ((uint8_t*)_notEqual_14)}, {{"subscript"}, ((uint8_t*)subscript_78)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_914)}, {{"read-dir"}, ((uint8_t*)read_dir_0)}, {{"read-dir"}, ((uint8_t*)read_dir_1)}, {{"!="}, ((uint8_t*)_notEqual_15)}, {{"read-dir-recur"}, ((uint8_t*)read_dir_recur)}, {{"zero"}, ((uint8_t*)zero_4)}, {{"!="}, ((uint8_t*)_notEqual_16)}, {{"as-any-const-ptr"}, ((uint8_t*)as_any_const_ptr_4)}, {{"*"}, ((uint8_t*)_times_18)}, {{"ref-eq"}, ((uint8_t*)ref_eq)}, {{"get-dirent-name"}, ((uint8_t*)get_dirent_name)}, {{"+"}, ((uint8_t*)_plus_15)}, {{"ptr-cast"}, ((uint8_t*)ptr_cast_1)}, {{"!="}, ((uint8_t*)_notEqual_17)}, {{"~="}, ((uint8_t*)_concatEquals_6)}, {{"incr-capacity!"}, ((uint8_t*)incr_capacity__e_3)}, {{"ensure-capacity"}, ((uint8_t*)ensure_capacity_3)}, {{"capacity"}, ((uint8_t*)capacity_4)}, {{"size"}, ((uint8_t*)size_8)}, {{"increase-capacity-to!"}, ((uint8_t*)increase_capacity_to__e_3)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_13)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_14)}, {{"uninitialized-mut-arr"}, ((uint8_t*)uninitialized_mut_arr_7)}, {{"mut-arr"}, ((uint8_t*)mut_arr_16)}, {{"copy-data-from!"}, ((uint8_t*)copy_data_from__e_4)}, {{"as-any-const-ptr"}, ((uint8_t*)as_any_const_ptr_5)}, {{"set-zero-elements"}, ((uint8_t*)set_zero_elements_3)}, {{"set-zero-range"}, ((uint8_t*)set_zero_range_4)}, {{"subscript"}, ((uint8_t*)subscript_79)}, {{"sort"}, ((uint8_t*)sort_2)}, {{"sort"}, ((uint8_t*)sort_3)}, {{"mut-arr"}, ((uint8_t*)mut_arr_17)}, {{"make-mut-arr"}, ((uint8_t*)make_mut_arr_3)}, {{"sort!"}, ((uint8_t*)sort__e_3)}, {{"is-empty"}, ((uint8_t*)is_empty_17)}, {{"insertion-sort-recur!"}, ((uint8_t*)insertion_sort_recur__e_2)}, {{"!="}, ((uint8_t*)_notEqual_18)}, {{"insert!"}, ((uint8_t*)insert__e_2)}, {{"subscript"}, ((uint8_t*)subscript_80)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_956)}, {{"end-ptr"}, ((uint8_t*)end_ptr_11)}, {{"cast-immutable"}, ((uint8_t*)cast_immutable_4)}, {{"move-to-arr!"}, ((uint8_t*)move_to_arr__e_4)}, {{"move-to-mut-arr!"}, ((uint8_t*)move_to_mut_arr__e_2)}, {{"has-substr"}, ((uint8_t*)has_substr)}, {{"contains-subseq"}, ((uint8_t*)contains_subseq)}, {{"index-of-subseq"}, ((uint8_t*)index_of_subseq)}, {{"index-of-subseq-recur"}, ((uint8_t*)index_of_subseq_recur)}, {{"ext-is-crow"}, ((uint8_t*)ext_is_crow)}, {{"=="}, ((uint8_t*)_equal_12)}, {{"opt-equal"}, ((uint8_t*)opt_equal)}, {{"get-extension"}, ((uint8_t*)get_extension)}, {{"last-index-of"}, ((uint8_t*)last_index_of)}, {{"last"}, ((uint8_t*)last)}, {{"rtail"}, ((uint8_t*)rtail)}, {{"base-name"}, ((uint8_t*)base_name)}, {{"flat-map-with-max-size"}, ((uint8_t*)flat_map_with_max_size)}, {{"mut-list"}, ((uint8_t*)mut_list_4)}, {{"mut-arr"}, ((uint8_t*)mut_arr_18)}, {{"~="}, ((uint8_t*)_concatEquals_7)}, {{"each"}, ((uint8_t*)each_4)}, {{"each-recur"}, ((uint8_t*)each_recur_3)}, {{"=="}, ((uint8_t*)_equal_13)}, {{"!="}, ((uint8_t*)_notEqual_19)}, {{"subscript"}, ((uint8_t*)subscript_81)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_985)}, {{"*"}, ((uint8_t*)_times_19)}, {{"+"}, ((uint8_t*)_plus_16)}, {{"end-ptr"}, ((uint8_t*)end_ptr_12)}, {{"~="}, ((uint8_t*)_concatEquals_8)}, {{"incr-capacity!"}, ((uint8_t*)incr_capacity__e_4)}, {{"ensure-capacity"}, ((uint8_t*)ensure_capacity_4)}, {{"capacity"}, ((uint8_t*)capacity_5)}, {{"size"}, ((uint8_t*)size_9)}, {{"increase-capacity-to!"}, ((uint8_t*)increase_capacity_to__e_4)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_15)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_16)}, {{"uninitialized-mut-arr"}, ((uint8_t*)uninitialized_mut_arr_8)}, {{"mut-arr"}, ((uint8_t*)mut_arr_19)}, {{"alloc-uninitialized"}, ((uint8_t*)alloc_uninitialized_8)}, {{"copy-data-from!"}, ((uint8_t*)copy_data_from__e_5)}, {{"as-any-const-ptr"}, ((uint8_t*)as_any_const_ptr_6)}, {{"set-zero-elements"}, ((uint8_t*)set_zero_elements_4)}, {{"set-zero-range"}, ((uint8_t*)set_zero_range_5)}, {{"subscript"}, ((uint8_t*)subscript_82)}, {{"subscript"}, ((uint8_t*)subscript_83)}, {{"set-subscript"}, ((uint8_t*)set_subscript_16)}, {{"subscript"}, ((uint8_t*)subscript_84)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1009)}, {{"reduce-size-if-more-than!"}, ((uint8_t*)reduce_size_if_more_than__e)}, {{"drop"}, ((uint8_t*)drop_3)}, {{"pop!"}, ((uint8_t*)pop__e)}, {{"is-empty"}, ((uint8_t*)is_empty_18)}, {{"subscript"}, ((uint8_t*)subscript_85)}, {{"subscript"}, ((uint8_t*)subscript_86)}, {{"set-subscript"}, ((uint8_t*)set_subscript_17)}, {{"move-to-arr!"}, ((uint8_t*)move_to_arr__e_5)}, {{"cast-immutable"}, ((uint8_t*)cast_immutable_5)}, {{"move-to-mut-arr!"}, ((uint8_t*)move_to_mut_arr__e_3)}, {{"run-single-crow-test"}, ((uint8_t*)run_single_crow_test)}, {{"first-some"}, ((uint8_t*)first_some)}, {{"subscript"}, ((uint8_t*)subscript_87)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1024)}, {{"is-empty"}, ((uint8_t*)is_empty_19)}, {{"run-print-test"}, ((uint8_t*)run_print_test)}, {{"spawn-and-wait-result"}, ((uint8_t*)spawn_and_wait_result_0)}, {{"fold"}, ((uint8_t*)fold_4)}, {{"fold-recur"}, ((uint8_t*)fold_recur_3)}, {{"subscript"}, ((uint8_t*)subscript_88)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1031)}, {{"is-file"}, ((uint8_t*)is_file_0)}, {{"is-file"}, ((uint8_t*)is_file_1)}, {{"S_IFREG"}, ((uint8_t*)S_IFREG)}, {{"spawn-and-wait-result"}, ((uint8_t*)spawn_and_wait_result_1)}, {{"make-pipes"}, ((uint8_t*)make_pipes)}, {{"check-posix-error"}, ((uint8_t*)check_posix_error)}, {{"*"}, ((uint8_t*)_times_20)}, {{"keep-POLLINg"}, ((uint8_t*)keep_POLLINg)}, {{"mut-arr"}, ((uint8_t*)mut_arr_20)}, {{"make-mut-arr"}, ((uint8_t*)make_mut_arr_4)}, {{"uninitialized-mut-arr"}, ((uint8_t*)uninitialized_mut_arr_9)}, {{"mut-arr"}, ((uint8_t*)mut_arr_21)}, {{"alloc-uninitialized"}, ((uint8_t*)alloc_uninitialized_9)}, {{"fill-ptr-range"}, ((uint8_t*)fill_ptr_range_4)}, {{"fill-ptr-range-recur"}, ((uint8_t*)fill_ptr_range_recur_4)}, {{"set-subscript"}, ((uint8_t*)set_subscript_18)}, {{"subscript"}, ((uint8_t*)subscript_89)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1056)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_17)}, {{"subscript"}, ((uint8_t*)subscript_90)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_10)}, {{"subscript"}, ((uint8_t*)subscript_91)}, {{"*"}, ((uint8_t*)_times_21)}, {{"+"}, ((uint8_t*)_plus_17)}, {{"POLLIN"}, ((uint8_t*)POLLIN)}, {{"ref-of-val-at"}, ((uint8_t*)ref_of_val_at)}, {{"size"}, ((uint8_t*)size_10)}, {{"ref-of-ptr"}, ((uint8_t*)ref_of_ptr)}, {{"handle-revents"}, ((uint8_t*)handle_revents)}, {{"has-POLLIN"}, ((uint8_t*)has_POLLIN)}, {{"bits-intersect"}, ((uint8_t*)bits_intersect)}, {{"!="}, ((uint8_t*)_notEqual_20)}, {{"read-to-buffer-until-eof"}, ((uint8_t*)read_to_buffer_until_eof)}, {{"unsafe-set-size!"}, ((uint8_t*)unsafe_set_size__e_2)}, {{"reserve"}, ((uint8_t*)reserve_2)}, {{"to-nat64"}, ((uint8_t*)to_nat64_0)}, {{"<=>"}, ((uint8_t*)_compare_15)}, {{"cmp"}, ((uint8_t*)cmp_2)}, {{"<"}, ((uint8_t*)_less_11)}, {{"has-POLLHUP"}, ((uint8_t*)has_POLLHUP)}, {{"POLLHUP"}, ((uint8_t*)POLLHUP)}, {{"has-POLLPRI"}, ((uint8_t*)has_POLLPRI)}, {{"POLLPRI"}, ((uint8_t*)POLLPRI)}, {{"has-POLLOUT"}, ((uint8_t*)has_POLLOUT)}, {{"POLLOUT"}, ((uint8_t*)POLLOUT)}, {{"has-POLLERR"}, ((uint8_t*)has_POLLERR)}, {{"POLLERR"}, ((uint8_t*)POLLERR)}, {{"has-POLLNVAL"}, ((uint8_t*)has_POLLNVAL)}, {{"POLLNVAL"}, ((uint8_t*)POLLNVAL)}, {{"to-nat64"}, ((uint8_t*)to_nat64_1)}, {{"any"}, ((uint8_t*)any)}, {{"wait-and-get-exit-code"}, ((uint8_t*)wait_and_get_exit_code)}, {{"WIFEXITED"}, ((uint8_t*)WIFEXITED)}, {{"WTERMSIG"}, ((uint8_t*)WTERMSIG)}, {{"WEXITSTATUS"}, ((uint8_t*)WEXITSTATUS)}, {{">>"}, ((uint8_t*)_shiftRight)}, {{"<=>"}, ((uint8_t*)_compare_16)}, {{"cmp"}, ((uint8_t*)cmp_3)}, {{"<"}, ((uint8_t*)_less_12)}, {{"todo"}, ((uint8_t*)todo_5)}, {{"WIFSIGNALED"}, ((uint8_t*)WIFSIGNALED)}, {{"to-str"}, ((uint8_t*)to_str_4)}, {{"to-str"}, ((uint8_t*)to_str_5)}, {{"to-str"}, ((uint8_t*)to_str_6)}, {{"to-base"}, ((uint8_t*)to_base)}, {{"digit-to-str"}, ((uint8_t*)digit_to_str)}, {{"mod"}, ((uint8_t*)mod)}, {{"abs"}, ((uint8_t*)abs)}, {{"-"}, ((uint8_t*)_minus_14)}, {{"*"}, ((uint8_t*)_times_22)}, {{"with-value"}, ((uint8_t*)with_value_2)}, {{"WIFSTOPPED"}, ((uint8_t*)WIFSTOPPED)}, {{"WIFCONTINUED"}, ((uint8_t*)WIFCONTINUED)}, {{"convert-args"}, ((uint8_t*)convert_args)}, {{"~"}, ((uint8_t*)_tilde_2)}, {{"alloc-uninitialized"}, ((uint8_t*)alloc_uninitialized_10)}, {{"copy-data-from!"}, ((uint8_t*)copy_data_from__e_6)}, {{"as-any-const-ptr"}, ((uint8_t*)as_any_const_ptr_7)}, {{"map"}, ((uint8_t*)map_1)}, {{"make-arr"}, ((uint8_t*)make_arr_1)}, {{"fill-ptr-range"}, ((uint8_t*)fill_ptr_range_5)}, {{"fill-ptr-range-recur"}, ((uint8_t*)fill_ptr_range_recur_5)}, {{"set-subscript"}, ((uint8_t*)set_subscript_19)}, {{"subscript"}, ((uint8_t*)subscript_92)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1127)}, {{"subscript"}, ((uint8_t*)subscript_93)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1129)}, {{"convert-environ"}, ((uint8_t*)convert_environ)}, {{"mut-list"}, ((uint8_t*)mut_list_5)}, {{"mut-arr"}, ((uint8_t*)mut_arr_22)}, {{"each"}, ((uint8_t*)each_5)}, {{"fold"}, ((uint8_t*)fold_5)}, {{"init-iters"}, ((uint8_t*)init_iters_1)}, {{"uninitialized-mut-arr"}, ((uint8_t*)uninitialized_mut_arr_10)}, {{"mut-arr"}, ((uint8_t*)mut_arr_23)}, {{"alloc-uninitialized"}, ((uint8_t*)alloc_uninitialized_11)}, {{"overlay-count"}, ((uint8_t*)overlay_count_1)}, {{"init-overlay-iters-recur!"}, ((uint8_t*)init_overlay_iters_recur__e_1)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_18)}, {{"fold-recur"}, ((uint8_t*)fold_recur_4)}, {{"is-empty"}, ((uint8_t*)is_empty_20)}, {{"size"}, ((uint8_t*)size_11)}, {{"fold"}, ((uint8_t*)fold_6)}, {{"fold-recur"}, ((uint8_t*)fold_recur_5)}, {{"=="}, ((uint8_t*)_equal_14)}, {{"subscript"}, ((uint8_t*)subscript_94)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1151)}, {{"end-ptr"}, ((uint8_t*)end_ptr_13)}, {{"subscript"}, ((uint8_t*)subscript_95)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1154)}, {{"is-empty"}, ((uint8_t*)is_empty_21)}, {{"find-least-key"}, ((uint8_t*)find_least_key_1)}, {{"fold"}, ((uint8_t*)fold_7)}, {{"fold"}, ((uint8_t*)fold_8)}, {{"fold-recur"}, ((uint8_t*)fold_recur_6)}, {{"=="}, ((uint8_t*)_equal_15)}, {{"subscript"}, ((uint8_t*)subscript_96)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1163)}, {{"*"}, ((uint8_t*)_times_23)}, {{"+"}, ((uint8_t*)_plus_18)}, {{"end-ptr"}, ((uint8_t*)end_ptr_14)}, {{"temp-as-arr"}, ((uint8_t*)temp_as_arr_3)}, {{"subscript"}, ((uint8_t*)subscript_97)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_11)}, {{"subscript"}, ((uint8_t*)subscript_98)}, {{"subscript"}, ((uint8_t*)subscript_99)}, {{"unsafe-at"}, ((uint8_t*)unsafe_at_12)}, {{"subscript"}, ((uint8_t*)subscript_100)}, {{"tail"}, ((uint8_t*)tail_5)}, {{"subscript"}, ((uint8_t*)subscript_101)}, {{"subscript"}, ((uint8_t*)subscript_102)}, {{"tail"}, ((uint8_t*)tail_6)}, {{"subscript"}, ((uint8_t*)subscript_103)}, {{"take-key"}, ((uint8_t*)take_key_1)}, {{"take-key-recur"}, ((uint8_t*)take_key_recur_1)}, {{"tail"}, ((uint8_t*)tail_7)}, {{"is-empty"}, ((uint8_t*)is_empty_22)}, {{"set-subscript"}, ((uint8_t*)set_subscript_20)}, {{"unsafe-set-at!"}, ((uint8_t*)unsafe_set_at__e_1)}, {{"set-subscript"}, ((uint8_t*)set_subscript_21)}, {{"opt-or"}, ((uint8_t*)opt_or_1)}, {{"subscript"}, ((uint8_t*)subscript_104)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1189)}, {{"~="}, ((uint8_t*)_concatEquals_9)}, {{"incr-capacity!"}, ((uint8_t*)incr_capacity__e_5)}, {{"ensure-capacity"}, ((uint8_t*)ensure_capacity_5)}, {{"capacity"}, ((uint8_t*)capacity_6)}, {{"size"}, ((uint8_t*)size_12)}, {{"increase-capacity-to!"}, ((uint8_t*)increase_capacity_to__e_5)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_19)}, {{"begin-ptr"}, ((uint8_t*)begin_ptr_20)}, {{"uninitialized-mut-arr"}, ((uint8_t*)uninitialized_mut_arr_11)}, {{"mut-arr"}, ((uint8_t*)mut_arr_24)}, {{"set-zero-elements"}, ((uint8_t*)set_zero_elements_5)}, {{"set-zero-range"}, ((uint8_t*)set_zero_range_6)}, {{"subscript"}, ((uint8_t*)subscript_105)}, {{"move-to-arr!"}, ((uint8_t*)move_to_arr__e_6)}, {{"cast-immutable"}, ((uint8_t*)cast_immutable_6)}, {{"move-to-mut-arr!"}, ((uint8_t*)move_to_mut_arr__e_4)}, {{"throw"}, ((uint8_t*)throw_12)}, {{"throw"}, ((uint8_t*)throw_13)}, {{"hard-unreachable"}, ((uint8_t*)hard_unreachable_7)}, {{"handle-output"}, ((uint8_t*)handle_output)}, {{"try-read-file"}, ((uint8_t*)try_read_file_0)}, {{"try-read-file"}, ((uint8_t*)try_read_file_1)}, {{"O_RDONLY"}, ((uint8_t*)O_RDONLY)}, {{"todo"}, ((uint8_t*)todo_6)}, {{"seek-end"}, ((uint8_t*)seek_end)}, {{"seek-set"}, ((uint8_t*)seek_set)}, {{"write-file"}, ((uint8_t*)write_file_0)}, {{"write-file"}, ((uint8_t*)write_file_1)}, {{"<<"}, ((uint8_t*)_shiftLeft)}, {{"<=>"}, ((uint8_t*)_compare_17)}, {{"cmp"}, ((uint8_t*)cmp_4)}, {{"<"}, ((uint8_t*)_less_13)}, {{"O_CREAT"}, ((uint8_t*)O_CREAT)}, {{"O_WRONLY"}, ((uint8_t*)O_WRONLY)}, {{"O_TRUNC"}, ((uint8_t*)O_TRUNC)}, {{"to-str"}, ((uint8_t*)to_str_7)}, {{"with-value"}, ((uint8_t*)with_value_3)}, {{"ptr-cast"}, ((uint8_t*)ptr_cast_2)}, {{"to-int64"}, ((uint8_t*)to_int64)}, {{"max-int64"}, ((uint8_t*)max_int64)}, {{"is-empty"}, ((uint8_t*)is_empty_23)}, {{"remove-colors"}, ((uint8_t*)remove_colors)}, {{"remove-colors-recur!"}, ((uint8_t*)remove_colors_recur__e)}, {{"~="}, ((uint8_t*)_concatEquals_10)}, {{"tail"}, ((uint8_t*)tail_8)}, {{"remove-colors-recur-2!"}, ((uint8_t*)remove_colors_recur_2__e)}, {{"run-single-runnable-test"}, ((uint8_t*)run_single_runnable_test)}, {{"~"}, ((uint8_t*)_tilde_3)}, {{"with-value"}, ((uint8_t*)with_value_4)}, {{"lint"}, ((uint8_t*)lint)}, {{"list-lintable-files"}, ((uint8_t*)list_lintable_files)}, {{"excluded-from-lint"}, ((uint8_t*)excluded_from_lint)}, {{"in"}, ((uint8_t*)in_2)}, {{"in-recur"}, ((uint8_t*)in_recur_1)}, {{"noctx-at"}, ((uint8_t*)noctx_at_2)}, {{"exists"}, ((uint8_t*)exists)}, {{"ends-with"}, ((uint8_t*)ends_with_0)}, {{"ends-with"}, ((uint8_t*)ends_with_1)}, {{"should-ignore-extension-of-name"}, ((uint8_t*)should_ignore_extension_of_name)}, {{"should-ignore-extension"}, ((uint8_t*)should_ignore_extension)}, {{"ignored-extensions"}, ((uint8_t*)ignored_extensions)}, {{"lint-file"}, ((uint8_t*)lint_file)}, {{"read-file"}, ((uint8_t*)read_file)}, {{"each-with-index"}, ((uint8_t*)each_with_index_0)}, {{"each-with-index-recur"}, ((uint8_t*)each_with_index_recur_0)}, {{"subscript"}, ((uint8_t*)subscript_106)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1267)}, {{"lines"}, ((uint8_t*)lines)}, {{"each-with-index"}, ((uint8_t*)each_with_index_1)}, {{"each-with-index-recur"}, ((uint8_t*)each_with_index_recur_1)}, {{"subscript"}, ((uint8_t*)subscript_107)}, {{"call-with-ctx"}, ((uint8_t*)call_w_ctx_1272)}, {{"swap"}, ((uint8_t*)swap)}, {{"*"}, ((uint8_t*)_times_24)}, {{"set-deref"}, ((uint8_t*)set_deref_1)}, {{"line-len"}, ((uint8_t*)line_len)}, {{"n-tabs"}, ((uint8_t*)n_tabs)}, {{"tab-size"}, ((uint8_t*)tab_size)}, {{"max-line-length"}, ((uint8_t*)max_line_length)}, {{"print-failures"}, ((uint8_t*)print_failures)}, {{"print-failure"}, ((uint8_t*)print_failure)}, {{"print-bold"}, ((uint8_t*)print_bold)}, {{"print-reset"}, ((uint8_t*)print_reset)}};
struct sym constantarr_1_0[398] = {{"<<UNKNOWN>>"}, {"mark"}, {"hard-assert"}, {"is-word-aligned"}, {"words-of-bytes"}, {"round-up-to-multiple-of-8"}, {"ptr-cast"}, {"-"}, {"<=>"}, {"cmp"}, {"<"}, {"<="}, {"!"}, {"mark-range-recur"}, {">"}, {"rt-main"}, {"lbv"}, {"lock-by-val"}, {"atomic-bool"}, {"create-condition"}, {"hard-assert-posix-error"}, {"CLOCK_MONOTONIC"}, {"island"}, {"task-queue"}, {"mut-list-by-val-with-capacity-from-unmanaged-memory"}, {"mut-arr"}, {"unmanaged-alloc-zeroed-elements"}, {"unmanaged-alloc-elements"}, {"unmanaged-alloc-bytes"}, {"!="}, {"set-zero-range"}, {"drop"}, {"default-exception-handler"}, {"print-err-no-newline"}, {"write-no-newline"}, {"as-any-const-ptr"}, {"size-bytes"}, {"todo"}, {"stderr"}, {"print-err"}, {"to-str"}, {"writer"}, {"mut-list"}, {"~="}, {"each"}, {"each-recur"}, {"=="}, {"subscript"}, {"call-with-ctx"}, {"*"}, {"+"}, {"end-ptr"}, {"incr-capacity!"}, {"ensure-capacity"}, {"capacity"}, {"size"}, {"increase-capacity-to!"}, {"assert"}, {"throw"}, {"get-exception-ctx"}, {"number-to-throw"}, {"hard-unreachable"}, {"get-backtrace"}, {"try-alloc-backtrace-arrs"}, {"try-alloc-uninitialized"}, {"try-alloc"}, {"try-gc-alloc"}, {"acquire!"}, {"acquire-recur!"}, {"try-acquire!"}, {"try-set!"}, {"try-change!"}, {"yield-thread"}, {"try-gc-alloc-recur"}, {"range-free"}, {"maybe-set-needs-gc!"}, {"release!"}, {"must-unset!"}, {"try-unset!"}, {"get-gc"}, {"get-gc-ctx"}, {"code-ptrs-size"}, {"copy-data-from!"}, {"sort!"}, {"swap!"}, {"set-subscript"}, {"partition!"}, {"fill-code-names!"}, {"get-fun-name"}, {"begin-ptr"}, {"uninitialized-mut-arr"}, {"alloc-uninitialized"}, {"alloc"}, {"gc-alloc"}, {"set-zero-elements"}, {"->"}, {">="}, {"round-up-to-power-of-two"}, {"round-up-to-power-of-two-recur"}, {"/"}, {"forbid"}, {"is-empty"}, {"arr-from-begin-end"}, {"find-cstr-end"}, {"find-char-in-cstr"}, {"move-to-str!"}, {"move-to-arr!"}, {"cast-immutable"}, {"move-to-mut-arr!"}, {"get-global-ctx"}, {"default-log-handler"}, {"print"}, {"print-no-newline"}, {"stdout"}, {"~"}, {"gc"}, {"validate-gc"}, {"thread-safe-counter"}, {"add-main-task"}, {"exception-ctx"}, {"log-ctx"}, {"perf-ctx"}, {"ctx"}, {"add-first-task"}, {"then-void"}, {"then"}, {"unresolved"}, {"callback!"}, {"with-lock"}, {"forward-to!"}, {"resolve-or-reject!"}, {"call-callbacks!"}, {"get-island"}, {"unsafe-at"}, {"add-task"}, {"task-queue-node"}, {"insert-task!"}, {"size-recur"}, {"insert-recur"}, {"tasks"}, {"broadcast!"}, {"no-timestamp"}, {"catch"}, {"catch-with-exception-ctx"}, {"zero"}, {"reject!"}, {"cur-island-and-exclusion"}, {"delay"}, {"resolved"}, {"tail"}, {"map"}, {"make-arr"}, {"fill-ptr-range"}, {"fill-ptr-range-recur"}, {"handle-exceptions"}, {"exception-handler"}, {"get-cur-island"}, {"run-threads"}, {"start-threads-recur"}, {"create-one-thread"}, {"null"}, {"EAGAIN"}, {"as-cell"}, {"thread-fun"}, {"thread-function"}, {"thread-function-recur"}, {"assert-islands-are-shut-down"}, {"noctx-at"}, {"hard-forbid"}, {"get-sequence"}, {"choose-task"}, {"get-monotime-nsec"}, {"choose-task-recur"}, {"choose-task-in-island"}, {"pop-task!"}, {"in"}, {"in-recur"}, {"temp-as-arr"}, {"temp-as-mut-arr"}, {"pop-recur!"}, {"to-opt-time"}, {"push-capacity-must-be-sufficient!"}, {"is-no-task"}, {"min-time"}, {"min"}, {"do-task"}, {"return-task!"}, {"noctx-must-remove-unordered!"}, {"noctx-must-remove-unordered-recur!"}, {"noctx-remove-unordered-at!"}, {"return-ctx"}, {"return-gc-ctx"}, {"run-garbage-collection"}, {"mark-visit"}, {"clear-free-mem!"}, {"wait-on"}, {"to-timespec"}, {"ETIMEDOUT"}, {"join-threads-recur"}, {"join-one-thread"}, {"EINVAL"}, {"ESRCH"}, {"unmanaged-free"}, {"destroy-condition"}, {"main"}, {"parse-named-args"}, {"parse-command-dynamic"}, {"find-index"}, {"find-index-recur"}, {"starts-with"}, {"arr-equal"}, {"equal-recur"}, {"arr-compare"}, {"compare-recur"}, {"dict"}, {"sort-by"}, {"sort"}, {"make-mut-arr"}, {"insertion-sort-recur!"}, {"insert!"}, {"mut-dict"}, {"parse-named-args-recur"}, {"force"}, {"try-remove-start"}, {"insert-into-key-match-or-empty-slot!"}, {"find-insert-ptr"}, {"binary-search-insert-ptr"}, {"binary-search-compare-recur"}, {"add-pair!"}, {"insert-linear!"}, {"move-right!"}, {"compact-if-needed!"}, {"total-pairs-size"}, {"total-pairs-size-recur"}, {"compact!"}, {"filter!"}, {"filter-recur!"}, {"merge-no-duplicates!"}, {"unsafe-set-size!"}, {"reserve"}, {"merge-reverse-recur!"}, {"mut-arr-from-begin-end"}, {"copy-from!"}, {"empty!"}, {"pop-n!"}, {"assert-comparison-not-equal"}, {"unreachable"}, {"move-to-dict!"}, {"map-to-arr"}, {"map-to-mut-arr"}, {"fill-mut-list"}, {"fill-mut-arr"}, {"fold"}, {"init-iters"}, {"overlay-count"}, {"init-overlay-iters-recur!"}, {"fold-recur"}, {"find-least-key"}, {"take-key"}, {"take-key-recur"}, {"unsafe-set-at!"}, {"opt-or"}, {"index-of"}, {"ptr-of"}, {"ptr-of-recur"}, {"set-deref"}, {"finish"}, {"with-value"}, {"with-str"}, {"interp"}, {"print-help"}, {"parse-nat"}, {"with-reader"}, {"reader"}, {"take-nat!"}, {"char-to-nat64"}, {"peek"}, {"next!"}, {"take-nat-recur!"}, {"do-test"}, {"parent-path"}, {"r-index-of"}, {"find-rindex"}, {"find-rindex-recur"}, {"child-path"}, {"get-environ"}, {"get-environ-recur"}, {"parse-environ-entry"}, {"first-failures"}, {"run-crow-tests"}, {"list-tests"}, {"each-child-recursive"}, {"is-dir"}, {"get-stat"}, {"stat"}, {"errno"}, {"ENOENT"}, {"S_IFMT"}, {"S_IFDIR"}, {"to-c-str"}, {"read-dir"}, {"read-dir-recur"}, {"ref-eq"}, {"get-dirent-name"}, {"has-substr"}, {"contains-subseq"}, {"index-of-subseq"}, {"index-of-subseq-recur"}, {"ext-is-crow"}, {"opt-equal"}, {"get-extension"}, {"last-index-of"}, {"last"}, {"rtail"}, {"base-name"}, {"flat-map-with-max-size"}, {"reduce-size-if-more-than!"}, {"pop!"}, {"run-single-crow-test"}, {"first-some"}, {"run-print-test"}, {"spawn-and-wait-result"}, {"is-file"}, {"S_IFREG"}, {"make-pipes"}, {"check-posix-error"}, {"keep-POLLINg"}, {"POLLIN"}, {"ref-of-val-at"}, {"ref-of-ptr"}, {"handle-revents"}, {"has-POLLIN"}, {"bits-intersect"}, {"read-to-buffer-until-eof"}, {"to-nat64"}, {"has-POLLHUP"}, {"POLLHUP"}, {"has-POLLPRI"}, {"POLLPRI"}, {"has-POLLOUT"}, {"POLLOUT"}, {"has-POLLERR"}, {"POLLERR"}, {"has-POLLNVAL"}, {"POLLNVAL"}, {"any"}, {"wait-and-get-exit-code"}, {"WIFEXITED"}, {"WTERMSIG"}, {"WEXITSTATUS"}, {">>"}, {"WIFSIGNALED"}, {"to-base"}, {"digit-to-str"}, {"mod"}, {"abs"}, {"WIFSTOPPED"}, {"WIFCONTINUED"}, {"convert-args"}, {"convert-environ"}, {"handle-output"}, {"try-read-file"}, {"O_RDONLY"}, {"seek-end"}, {"seek-set"}, {"write-file"}, {"<<"}, {"O_CREAT"}, {"O_WRONLY"}, {"O_TRUNC"}, {"to-int64"}, {"max-int64"}, {"remove-colors"}, {"remove-colors-recur!"}, {"remove-colors-recur-2!"}, {"run-single-runnable-test"}, {"lint"}, {"list-lintable-files"}, {"excluded-from-lint"}, {"exists"}, {"ends-with"}, {"should-ignore-extension-of-name"}, {"should-ignore-extension"}, {"ignored-extensions"}, {"lint-file"}, {"read-file"}, {"each-with-index"}, {"each-with-index-recur"}, {"lines"}, {"swap"}, {"line-len"}, {"n-tabs"}, {"tab-size"}, {"max-line-length"}, {"print-failures"}, {"print-failure"}, {"print-bold"}, {"print-reset"}};
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
		uint8_t _3 = _greater_0((index2 + size_words0), ctx->memory_size_words);
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
uint8_t _greater_0(uint64_t a, uint64_t b) {
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
	struct mut_list_0 _0 = mut_list_by_val_with_capacity_from_unmanaged_memory(max_threads);
	return (struct task_queue) {(struct opt_3) {0, .as0 = (struct none) {}}, _0};
}
/* mut-list-by-val-with-capacity-from-unmanaged-memory<nat64> mut-list<nat64>(capacity nat64) */
struct mut_list_0 mut_list_by_val_with_capacity_from_unmanaged_memory(uint64_t capacity) {
	struct mut_arr_0 backing0;
	uint64_t* _0 = unmanaged_alloc_zeroed_elements(capacity);
	backing0 = mut_arr_0(capacity, _0);
	
	return (struct mut_list_0) {backing0, 0u};
}
/* mut-arr<a> mut-arr<nat64>(size nat64, begin-ptr mut-ptr<nat64>) */
struct mut_arr_0 mut_arr_0(uint64_t size, uint64_t* begin_ptr) {
	return (struct mut_arr_0) {(struct void_) {}, (struct arr_3) {size, ((uint64_t*) begin_ptr)}};
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
	struct mut_list_1* _0 = mut_list_0(ctx);
	return (struct writer) {_0};
}
/* mut-list<char> mut-list<char>() */
struct mut_list_1* mut_list_0(struct ctx* ctx) {
	struct mut_list_1* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_list_1));
	temp0 = ((struct mut_list_1*) _0);
	
	struct mut_arr_1 _1 = mut_arr_1();
	*temp0 = (struct mut_list_1) {_1, 0u};
	return temp0;
}
/* mut-arr<a> mut-arr<char>() */
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
/* ~=<a> void(a mut-list<char>, value char) */
struct void_ _concatEquals_2(struct ctx* ctx, struct mut_list_1* a, char value) {
	incr_capacity__e_0(ctx, a);
	uint64_t _0 = capacity_0(a);
	uint8_t _1 = _less_0(a->size, _0);
	assert_0(ctx, _1);
	char* _2 = begin_ptr_0(a);
	set_subscript_1(_2, a->size, value);
	uint64_t _3 = _plus_3(ctx, a->size, 1u);
	return (a->size = _3, (struct void_) {});
}
/* incr-capacity!<a> void(a mut-list<char>) */
struct void_ incr_capacity__e_0(struct ctx* ctx, struct mut_list_1* a) {
	uint64_t _0 = _plus_3(ctx, a->size, 1u);
	uint64_t _1 = round_up_to_power_of_two(ctx, _0);
	return ensure_capacity_0(ctx, a, _1);
}
/* ensure-capacity<a> void(a mut-list<char>, min-capacity nat64) */
struct void_ ensure_capacity_0(struct ctx* ctx, struct mut_list_1* a, uint64_t min_capacity) {
	uint64_t _0 = capacity_0(a);
	uint8_t _1 = _less_0(_0, min_capacity);
	if (_1) {
		return increase_capacity_to__e_0(ctx, a, min_capacity);
	} else {
		return (struct void_) {};
	}
}
/* capacity<a> nat64(a mut-list<char>) */
uint64_t capacity_0(struct mut_list_1* a) {
	return size_0(a->backing);
}
/* size<a> nat64(a mut-arr<char>) */
uint64_t size_0(struct mut_arr_1 a) {
	return a.inner.size;
}
/* increase-capacity-to!<a> void(a mut-list<char>, new-capacity nat64) */
struct void_ increase_capacity_to__e_0(struct ctx* ctx, struct mut_list_1* a, uint64_t new_capacity) {
	uint64_t _0 = capacity_0(a);
	uint8_t _1 = _greater_0(new_capacity, _0);
	assert_0(ctx, _1);
	char* old_begin0;
	old_begin0 = begin_ptr_0(a);
	
	struct mut_arr_1 _2 = uninitialized_mut_arr_0(ctx, new_capacity);
	a->backing = _2;
	char* _3 = begin_ptr_0(a);
	copy_data_from__e_1(ctx, _3, ((char*) old_begin0), a->size);
	uint64_t _4 = _plus_3(ctx, a->size, 1u);
	uint64_t _5 = size_0(a->backing);
	struct arrow_0 _6 = _arrow_0(_4, _5);
	struct mut_arr_1 _7 = subscript_3(ctx, a->backing, _6);
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
			copy_data_from__e_0(ctx, arrs1->funs, (struct arr_5) {1113, constantarr_5_0}.begin_ptr, (struct arr_5) {1113, constantarr_5_0}.size);
			sort__e_0(arrs1->funs, (struct arr_5) {1113, constantarr_5_0}.size);
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
					
					struct opt_8 _2 = try_alloc_uninitialized_2(ctx, (struct arr_5) {1113, constantarr_5_0}.size);
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
	
	uint8_t _0 = _greater_0(cur_word0, (gc->size_words / 2u));
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
	uint8_t _0 = _greater_0(size, 1u);
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
		struct sym _2 = get_fun_name(_1, funs, (struct arr_5) {1113, constantarr_5_0}.size);
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
/* begin-ptr<a> mut-ptr<char>(a mut-list<char>) */
char* begin_ptr_0(struct mut_list_1* a) {
	return begin_ptr_1(a->backing);
}
/* begin-ptr<a> mut-ptr<char>(a mut-arr<char>) */
char* begin_ptr_1(struct mut_arr_1 a) {
	return ((char*) a.inner.begin_ptr);
}
/* uninitialized-mut-arr<a> mut-arr<char>(size nat64) */
struct mut_arr_1 uninitialized_mut_arr_0(struct ctx* ctx, uint64_t size) {
	char* _0 = alloc_uninitialized_0(ctx, size);
	return mut_arr_2(size, _0);
}
/* mut-arr<a> mut-arr<char>(size nat64, begin-ptr mut-ptr<char>) */
struct mut_arr_1 mut_arr_2(uint64_t size, char* begin_ptr) {
	return (struct mut_arr_1) {(struct void_) {}, (struct arr_0) {size, ((char*) begin_ptr)}};
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
/* set-zero-elements<a> void(a mut-arr<char>) */
struct void_ set_zero_elements_0(struct mut_arr_1 a) {
	char* _0 = begin_ptr_1(a);
	uint64_t _1 = size_0(a);
	return set_zero_range_1(_0, _1);
}
/* set-zero-range<a> void(begin mut-ptr<char>, size nat64) */
struct void_ set_zero_range_1(char* begin, uint64_t size) {
	uint8_t* _0 = memset(((uint8_t*) begin), 0, (size * sizeof(char)));
	return drop_0(_0);
}
/* subscript<a> mut-arr<char>(a mut-arr<char>, range arrow<nat64, nat64>) */
struct mut_arr_1 subscript_3(struct ctx* ctx, struct mut_arr_1 a, struct arrow_0 range) {
	uint8_t _0 = _lessOrEqual_0(range.from, range.to);
	assert_0(ctx, _0);
	uint64_t _1 = size_0(a);
	uint8_t _2 = _lessOrEqual_0(range.to, _1);
	assert_0(ctx, _2);
	struct arr_0 _3 = subscript_4(ctx, a.inner, range);
	return (struct mut_arr_1) {(struct void_) {}, _3};
}
/* subscript<a> arr<char>(a arr<char>, range arrow<nat64, nat64>) */
struct arr_0 subscript_4(struct ctx* ctx, struct arr_0 a, struct arrow_0 range) {
	uint8_t _0 = _lessOrEqual_0(range.from, range.to);
	assert_0(ctx, _0);
	uint8_t _1 = _lessOrEqual_0(range.to, a.size);
	assert_0(ctx, _1);
	char* _2 = _plus_0(a.begin_ptr, range.from);
	return (struct arr_0) {(range.to - range.from), _2};
}
/* -><nat64, nat64> arrow<nat64, nat64>(from nat64, to nat64) */
struct arrow_0 _arrow_0(uint64_t from, uint64_t to) {
	return (struct arrow_0) {from, to};
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
	struct arr_0 _1 = arr_from_begin_end_0(a, _0);
	return (struct str) {_1};
}
/* arr-from-begin-end<char> arr<char>(begin const-ptr<char>, end const-ptr<char>) */
struct arr_0 arr_from_begin_end_0(char* begin, char* end) {
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
/* move-to-arr!<char> arr<char>(a mut-list<char>) */
struct arr_0 move_to_arr__e_0(struct mut_list_1* a) {
	struct mut_arr_1 _0 = move_to_mut_arr__e_0(a);
	return cast_immutable_0(_0);
}
/* cast-immutable<a> arr<char>(a mut-arr<char>) */
struct arr_0 cast_immutable_0(struct mut_arr_1 a) {
	return a.inner;
}
/* move-to-mut-arr!<a> mut-arr<char>(a mut-list<char>) */
struct mut_arr_1 move_to_mut_arr__e_0(struct mut_list_1* a) {
	struct mut_arr_1 res0;
	char* _0 = begin_ptr_0(a);
	res0 = mut_arr_2(a->size, _0);
	
	struct mut_arr_1 _1 = mut_arr_1();
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
	struct mut_arr_2 _0 = mut_arr_3();
	return (struct perf_ctx) {(struct arr_2) {0u, NULL}, _0};
}
/* mut-arr<measure-value> mut-arr<measure-value>() */
struct mut_arr_2 mut_arr_3(void) {
	return (struct mut_arr_2) {(struct void_) {}, (struct arr_6) {0u, NULL}};
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
	struct arrow_0 _1 = _arrow_0(1u, a.size);
	return subscript_17(ctx, a, _1);
}
/* is-empty<a> bool(a arr<const-ptr<char>>) */
uint8_t is_empty_2(struct arr_7 a) {
	return (a.size == 0u);
}
/* subscript<a> arr<const-ptr<char>>(a arr<const-ptr<char>>, range arrow<nat64, nat64>) */
struct arr_7 subscript_17(struct ctx* ctx, struct arr_7 a, struct arrow_0 range) {
	uint8_t _0 = _lessOrEqual_0(range.from, range.to);
	assert_0(ctx, _0);
	uint8_t _1 = _lessOrEqual_0(range.to, a.size);
	assert_0(ctx, _1);
	char** _2 = _plus_6(a.begin_ptr, range.from);
	return (struct arr_7) {(range.to - range.from), _2};
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
			struct mut_arr_17__lambda0* closure1 = _0.as1;
			
			return mut_arr_17__lambda0(ctx, closure1, p0);
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
		uint8_t _1 = _greater_0(gctx->n_live_threads, 0u);
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
	struct mut_list_0* exclusions0;
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
/* in<nat64> bool(value nat64, a mut-list<nat64>) */
uint8_t in_0(uint64_t value, struct mut_list_0* a) {
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
/* temp-as-arr<a> arr<nat64>(a mut-list<nat64>) */
struct arr_3 temp_as_arr_0(struct mut_list_0* a) {
	struct mut_arr_0 _0 = temp_as_mut_arr_0(a);
	return temp_as_arr_1(_0);
}
/* temp-as-arr<a> arr<nat64>(a mut-arr<nat64>) */
struct arr_3 temp_as_arr_1(struct mut_arr_0 a) {
	return a.inner;
}
/* temp-as-mut-arr<a> mut-arr<nat64>(a mut-list<nat64>) */
struct mut_arr_0 temp_as_mut_arr_0(struct mut_list_0* a) {
	uint64_t* _0 = begin_ptr_2(a);
	return mut_arr_0(a->size, _0);
}
/* begin-ptr<a> mut-ptr<nat64>(a mut-list<nat64>) */
uint64_t* begin_ptr_2(struct mut_list_0* a) {
	return begin_ptr_3(a->backing);
}
/* begin-ptr<a> mut-ptr<nat64>(a mut-arr<nat64>) */
uint64_t* begin_ptr_3(struct mut_arr_0 a) {
	return ((uint64_t*) a.inner.begin_ptr);
}
/* pop-recur! pop-task-result(prev task-queue-node, exclusions mut-list<nat64>, cur-time nat64, first-task-time opt<nat64>) */
struct pop_task_result pop_recur__e(struct task_queue_node* prev, struct mut_list_0* exclusions, uint64_t cur_time, struct opt_11 first_task_time) {
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
/* push-capacity-must-be-sufficient!<nat64> void(a mut-list<nat64>, value nat64) */
struct void_ push_capacity_must_be_sufficient__e(struct mut_list_0* a, uint64_t value) {
	uint64_t _0 = capacity_1(a);
	uint8_t _1 = _less_0(a->size, _0);
	hard_assert(_1);
	uint64_t* _2 = begin_ptr_2(a);
	set_subscript_3(_2, a->size, value);
	return (a->size = (a->size + 1u), (struct void_) {});
}
/* capacity<a> nat64(a mut-list<nat64>) */
uint64_t capacity_1(struct mut_list_0* a) {
	return size_2(a->backing);
}
/* size<a> nat64(a mut-arr<nat64>) */
uint64_t size_2(struct mut_arr_0 a) {
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
					
					uint64_t _2 = min_0(ta1, tb3);
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
uint64_t min_0(uint64_t a, uint64_t b) {
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
/* noctx-must-remove-unordered!<nat64> void(a mut-list<nat64>, value nat64) */
struct void_ noctx_must_remove_unordered__e(struct mut_list_0* a, uint64_t value) {
	return noctx_must_remove_unordered_recur__e(a, 0u, value);
}
/* noctx-must-remove-unordered-recur!<a> void(a mut-list<nat64>, index nat64, value nat64) */
struct void_ noctx_must_remove_unordered_recur__e(struct mut_list_0* a, uint64_t index, uint64_t value) {
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
/* noctx-remove-unordered-at!<a> nat64(a mut-list<nat64>, index nat64) */
uint64_t noctx_remove_unordered_at__e(struct mut_list_0* a, uint64_t index) {
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
/* mark-visit<mut-list<nat64>> (generated) (generated) */
struct void_ mark_visit_417(struct mark_ctx* mark_ctx, struct mut_list_0 value) {
	return mark_visit_418(mark_ctx, value.backing);
}
/* mark-visit<mut-arr<nat64>> (generated) (generated) */
struct void_ mark_visit_418(struct mark_ctx* mark_ctx, struct mut_arr_0 value) {
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
			print_tests_strs2 = subscript_57(ctx, values1, 0u);
			
			struct opt_12 overwrite_output_strs3;
			overwrite_output_strs3 = subscript_57(ctx, values1, 1u);
			
			struct opt_12 max_failures_strs4;
			max_failures_strs4 = subscript_57(ctx, values1, 2u);
			
			struct opt_12 match_test_strs5;
			match_test_strs5 = subscript_57(ctx, values1, 3u);
			
			uint8_t should_print_tests6;
			uint8_t _2 = is_empty_7(print_tests_strs2);
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
					
					uint8_t _4 = is_empty_6(strs8);
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
					max_failures12 = force_4(ctx, _7);
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
	
	uint8_t _0 = is_empty_6(parsed0->nameless);
	assert_1(ctx, _0, (struct str) {{26, constantarr_0_17}});
	uint8_t _1 = is_empty_6(parsed0->after);
	assert_0(ctx, _1);
	struct mut_list_3* values1;
	values1 = fill_mut_list(ctx, arg_names.size, (struct opt_12) {0, .as0 = (struct none) {}});
	
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
	each_2(ctx, parsed0->named, (struct fun_act2_4) {0, .as0 = temp1});
	uint8_t _4 = _times_14(help2);
	uint8_t _5 = _not(_4);
	if (_5) {
		struct arr_8 _6 = move_to_arr__e_2(values1);
		return (struct opt_13) {1, .as1 = (struct some_13) {_6}};
	} else {
		return (struct opt_13) {0, .as0 = (struct none) {}};
	}
}
/* parse-command-dynamic parsed-command(args arr<str>) */
struct parsed_command* parse_command_dynamic(struct ctx* ctx, struct arr_2 args) {
	struct opt_11 _0 = find_index(ctx, args, (struct fun_act1_8) {0, .as0 = (struct void_) {}});
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
			struct arrow_0 _3 = _arrow_0(0u, first_named_arg_index1);
			nameless2 = subscript_33(ctx, args, _3);
			
			struct arr_2 rest3;
			struct arrow_0 _4 = _arrow_0(first_named_arg_index1, args.size);
			rest3 = subscript_33(ctx, args, _4);
			
			struct opt_11 _5 = find_index(ctx, rest3, (struct fun_act1_8) {1, .as1 = (struct void_) {}});
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
					struct arrow_0 _8 = _arrow_0(0u, sep_index5);
					struct arr_2 _9 = subscript_33(ctx, rest3, _8);
					named_args6 = parse_named_args_1(ctx, _9);
					
					struct parsed_command* temp2;
					uint8_t* _10 = alloc(ctx, sizeof(struct parsed_command));
					temp2 = ((struct parsed_command*) _10);
					
					uint64_t _11 = _plus_3(ctx, sep_index5, 1u);
					struct arrow_0 _12 = _arrow_0(_11, rest3.size);
					struct arr_2 _13 = subscript_33(ctx, rest3, _12);
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
struct opt_11 find_index(struct ctx* ctx, struct arr_2 a, struct fun_act1_8 f) {
	return find_index_recur(ctx, a, 0u, f);
}
/* find-index-recur<a> opt<nat64>(a arr<str>, index nat64, f fun-act1<bool, str>) */
struct opt_11 find_index_recur(struct ctx* ctx, struct arr_2 a, uint64_t index, struct fun_act1_8 f) {
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
		struct arrow_0 _1 = _arrow_0(0u, start.size);
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
/* dict<str, arr<str>> dict<str, arr<str>>(a arr<arrow<str, arr<str>>>) */
struct dict_0 dict_0(struct ctx* ctx, struct arr_10 a) {
	struct arr_10 _0 = sort_by_0(ctx, a, (struct fun_act1_9) {0, .as0 = (struct void_) {}});
	return (struct dict_0) {(struct void_) {}, (struct dict_impl_0) {1, .as1 = (struct end_node_0) {_0}}};
}
/* sort-by<arrow<k, v>, k> arr<arrow<str, arr<str>>>(a arr<arrow<str, arr<str>>>, f fun-act1<str, arrow<str, arr<str>>>) */
struct arr_10 sort_by_0(struct ctx* ctx, struct arr_10 a, struct fun_act1_9 f) {
	struct sort_by_0__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct sort_by_0__lambda0));
	temp0 = ((struct sort_by_0__lambda0*) _0);
	
	*temp0 = (struct sort_by_0__lambda0) {f};
	return sort_0(ctx, a, (struct fun_act2_1) {0, .as0 = temp0});
}
/* sort<a> arr<arrow<str, arr<str>>>(a arr<arrow<str, arr<str>>>, comparer fun-act2<comparison, arrow<str, arr<str>>, arrow<str, arr<str>>>) */
struct arr_10 sort_0(struct ctx* ctx, struct arr_10 a, struct fun_act2_1 comparer) {
	struct mut_arr_3 res0;
	res0 = mut_arr_4(ctx, a);
	
	sort__e_1(ctx, res0, comparer);
	return cast_immutable_1(res0);
}
/* mut-arr<a> mut-arr<arrow<str, arr<str>>>(a arr<arrow<str, arr<str>>>) */
struct mut_arr_3 mut_arr_4(struct ctx* ctx, struct arr_10 a) {
	struct mut_arr_4__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_arr_4__lambda0));
	temp0 = ((struct mut_arr_4__lambda0*) _0);
	
	*temp0 = (struct mut_arr_4__lambda0) {a};
	return make_mut_arr_0(ctx, a.size, (struct fun_act1_10) {0, .as0 = temp0});
}
/* make-mut-arr<a> mut-arr<arrow<str, arr<str>>>(size nat64, f fun-act1<arrow<str, arr<str>>, nat64>) */
struct mut_arr_3 make_mut_arr_0(struct ctx* ctx, uint64_t size, struct fun_act1_10 f) {
	struct mut_arr_3 res0;
	res0 = uninitialized_mut_arr_1(ctx, size);
	
	struct arrow_2* _0 = begin_ptr_4(res0);
	fill_ptr_range_1(ctx, _0, size, f);
	return res0;
}
/* uninitialized-mut-arr<a> mut-arr<arrow<str, arr<str>>>(size nat64) */
struct mut_arr_3 uninitialized_mut_arr_1(struct ctx* ctx, uint64_t size) {
	struct arrow_2* _0 = alloc_uninitialized_2(ctx, size);
	return mut_arr_5(size, _0);
}
/* mut-arr<a> mut-arr<arrow<str, arr<str>>>(size nat64, begin-ptr mut-ptr<arrow<str, arr<str>>>) */
struct mut_arr_3 mut_arr_5(uint64_t size, struct arrow_2* begin_ptr) {
	return (struct mut_arr_3) {(struct void_) {}, (struct arr_10) {size, ((struct arrow_2*) begin_ptr)}};
}
/* alloc-uninitialized<a> mut-ptr<arrow<str, arr<str>>>(size nat64) */
struct arrow_2* alloc_uninitialized_2(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(struct arrow_2)));
	return ((struct arrow_2*) _0);
}
/* fill-ptr-range<a> void(begin mut-ptr<arrow<str, arr<str>>>, size nat64, f fun-act1<arrow<str, arr<str>>, nat64>) */
struct void_ fill_ptr_range_1(struct ctx* ctx, struct arrow_2* begin, uint64_t size, struct fun_act1_10 f) {
	return fill_ptr_range_recur_1(ctx, begin, 0u, size, f);
}
/* fill-ptr-range-recur<a> void(begin mut-ptr<arrow<str, arr<str>>>, i nat64, size nat64, f fun-act1<arrow<str, arr<str>>, nat64>) */
struct void_ fill_ptr_range_recur_1(struct ctx* ctx, struct arrow_2* begin, uint64_t i, uint64_t size, struct fun_act1_10 f) {
	top:;
	uint8_t _0 = _notEqual_5(i, size);
	if (_0) {
		struct arrow_2 _1 = subscript_28(ctx, f, i);
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
/* set-subscript<a> void(a mut-ptr<arrow<str, arr<str>>>, n nat64, value arrow<str, arr<str>>) */
struct void_ set_subscript_4(struct arrow_2* a, uint64_t n, struct arrow_2 value) {
	return (*(a + n) = value, (struct void_) {});
}
/* subscript<a, nat64> arrow<str, arr<str>>(a fun-act1<arrow<str, arr<str>>, nat64>, p0 nat64) */
struct arrow_2 subscript_28(struct ctx* ctx, struct fun_act1_10 a, uint64_t p0) {
	return call_w_ctx_479(a, ctx, p0);
}
/* call-w-ctx<arrow<str, arr<str>>, nat-64> (generated) (generated) */
struct arrow_2 call_w_ctx_479(struct fun_act1_10 a, struct ctx* ctx, uint64_t p0) {
	struct fun_act1_10 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct mut_arr_4__lambda0* closure0 = _0.as0;
			
			return mut_arr_4__lambda0(ctx, closure0, p0);
		}
		case 1: {
			struct map_to_mut_arr_0__lambda0* closure1 = _0.as1;
			
			return map_to_mut_arr_0__lambda0(ctx, closure1, p0);
		}
		default:
			
	return (struct arrow_2) {(struct str) {(struct arr_0) {0, NULL}}, (struct arr_2) {0, NULL}};;
	}
}
/* begin-ptr<a> mut-ptr<arrow<str, arr<str>>>(a mut-arr<arrow<str, arr<str>>>) */
struct arrow_2* begin_ptr_4(struct mut_arr_3 a) {
	return ((struct arrow_2*) a.inner.begin_ptr);
}
/* subscript<a> arrow<str, arr<str>>(a arr<arrow<str, arr<str>>>, index nat64) */
struct arrow_2 subscript_29(struct ctx* ctx, struct arr_10 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	return unsafe_at_4(a, index);
}
/* unsafe-at<a> arrow<str, arr<str>>(a arr<arrow<str, arr<str>>>, index nat64) */
struct arrow_2 unsafe_at_4(struct arr_10 a, uint64_t index) {
	return subscript_30(a.begin_ptr, index);
}
/* subscript<a> arrow<str, arr<str>>(a const-ptr<arrow<str, arr<str>>>, n nat64) */
struct arrow_2 subscript_30(struct arrow_2* a, uint64_t n) {
	struct arrow_2* _0 = _plus_9(a, n);
	return _times_11(_0);
}
/* *<a> arrow<str, arr<str>>(a const-ptr<arrow<str, arr<str>>>) */
struct arrow_2 _times_11(struct arrow_2* a) {
	return (*((struct arrow_2*) a));
}
/* +<a> const-ptr<arrow<str, arr<str>>>(a const-ptr<arrow<str, arr<str>>>, offset nat64) */
struct arrow_2* _plus_9(struct arrow_2* a, uint64_t offset) {
	return ((struct arrow_2*) (((struct arrow_2*) a) + offset));
}
/* mut-arr<a>.lambda0 arrow<str, arr<str>>(i nat64) */
struct arrow_2 mut_arr_4__lambda0(struct ctx* ctx, struct mut_arr_4__lambda0* _closure, uint64_t i) {
	return subscript_29(ctx, _closure->a, i);
}
/* sort!<a> void(a mut-arr<arrow<str, arr<str>>>, comparer fun-act2<comparison, arrow<str, arr<str>>, arrow<str, arr<str>>>) */
struct void_ sort__e_1(struct ctx* ctx, struct mut_arr_3 a, struct fun_act2_1 comparer) {
	uint8_t _0 = is_empty_5(a);
	uint8_t _1 = _not(_0);
	if (_1) {
		struct arrow_2* _2 = begin_ptr_4(a);
		struct arrow_2* _3 = begin_ptr_4(a);
		struct arrow_2* _4 = end_ptr_2(a);
		return insertion_sort_recur__e_0(ctx, _2, (_3 + 1u), _4, comparer);
	} else {
		return (struct void_) {};
	}
}
/* is-empty<a> bool(a mut-arr<arrow<str, arr<str>>>) */
uint8_t is_empty_5(struct mut_arr_3 a) {
	uint64_t _0 = size_3(a);
	return (_0 == 0u);
}
/* size<a> nat64(a mut-arr<arrow<str, arr<str>>>) */
uint64_t size_3(struct mut_arr_3 a) {
	return a.inner.size;
}
/* insertion-sort-recur!<a> void(begin mut-ptr<arrow<str, arr<str>>>, cur mut-ptr<arrow<str, arr<str>>>, end mut-ptr<arrow<str, arr<str>>>, comparer fun-act2<comparison, arrow<str, arr<str>>, arrow<str, arr<str>>>) */
struct void_ insertion_sort_recur__e_0(struct ctx* ctx, struct arrow_2* begin, struct arrow_2* cur, struct arrow_2* end, struct fun_act2_1 comparer) {
	top:;
	uint8_t _0 = _notEqual_8(cur, end);
	if (_0) {
		insert__e_0(ctx, begin, cur, (*cur), comparer);
		begin = begin;
		cur = (cur + 1u);
		end = end;
		comparer = comparer;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* !=<mut-ptr<a>> bool(a mut-ptr<arrow<str, arr<str>>>, b mut-ptr<arrow<str, arr<str>>>) */
uint8_t _notEqual_8(struct arrow_2* a, struct arrow_2* b) {
	return _not((a == b));
}
/* insert!<a> void(begin mut-ptr<arrow<str, arr<str>>>, cur mut-ptr<arrow<str, arr<str>>>, value arrow<str, arr<str>>, comparer fun-act2<comparison, arrow<str, arr<str>>, arrow<str, arr<str>>>) */
struct void_ insert__e_0(struct ctx* ctx, struct arrow_2* begin, struct arrow_2* cur, struct arrow_2 value, struct fun_act2_1 comparer) {
	top:;
	forbid(ctx, (begin == cur));
	struct arrow_2* prev0;
	prev0 = (cur - 1u);
	
	struct comparison _0 = subscript_31(ctx, comparer, value, (*prev0));
	uint8_t _1 = _equal_6(_0, (struct comparison) {0, .as0 = (struct less) {}});
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
uint8_t _equal_6(struct comparison a, struct comparison b) {
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
/* subscript<comparison, a, a> comparison(a fun-act2<comparison, arrow<str, arr<str>>, arrow<str, arr<str>>>, p0 arrow<str, arr<str>>, p1 arrow<str, arr<str>>) */
struct comparison subscript_31(struct ctx* ctx, struct fun_act2_1 a, struct arrow_2 p0, struct arrow_2 p1) {
	return call_w_ctx_495(a, ctx, p0, p1);
}
/* call-w-ctx<comparison, arrow<str, arr<str>>, arrow<str, arr<str>>> (generated) (generated) */
struct comparison call_w_ctx_495(struct fun_act2_1 a, struct ctx* ctx, struct arrow_2 p0, struct arrow_2 p1) {
	struct fun_act2_1 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct sort_by_0__lambda0* closure0 = _0.as0;
			
			return sort_by_0__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return (struct comparison) {0};;
	}
}
/* end-ptr<a> mut-ptr<arrow<str, arr<str>>>(a mut-arr<arrow<str, arr<str>>>) */
struct arrow_2* end_ptr_2(struct mut_arr_3 a) {
	struct arrow_2* _0 = begin_ptr_4(a);
	uint64_t _1 = size_3(a);
	return (_0 + _1);
}
/* cast-immutable<a> arr<arrow<str, arr<str>>>(a mut-arr<arrow<str, arr<str>>>) */
struct arr_10 cast_immutable_1(struct mut_arr_3 a) {
	return a.inner;
}
/* subscript<b, a> str(a fun-act1<str, arrow<str, arr<str>>>, p0 arrow<str, arr<str>>) */
struct str subscript_32(struct ctx* ctx, struct fun_act1_9 a, struct arrow_2 p0) {
	return call_w_ctx_499(a, ctx, p0);
}
/* call-w-ctx<str, arrow<str, arr<str>>> (generated) (generated) */
struct str call_w_ctx_499(struct fun_act1_9 a, struct ctx* ctx, struct arrow_2 p0) {
	struct fun_act1_9 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return dict_0__lambda0(ctx, closure0, p0);
		}
		default:
			
	return (struct str) {(struct arr_0) {0, NULL}};;
	}
}
/* sort-by<arrow<k, v>, k>.lambda0 comparison(x arrow<str, arr<str>>, y arrow<str, arr<str>>) */
struct comparison sort_by_0__lambda0(struct ctx* ctx, struct sort_by_0__lambda0* _closure, struct arrow_2 x, struct arrow_2 y) {
	struct str _0 = subscript_32(ctx, _closure->f, x);
	struct str _1 = subscript_32(ctx, _closure->f, y);
	return _compare_8(_0, _1);
}
/* dict<str, arr<str>>.lambda0 str(pair arrow<str, arr<str>>) */
struct str dict_0__lambda0(struct ctx* ctx, struct void_ _closure, struct arrow_2 pair) {
	return pair.from;
}
/* subscript<str> arr<str>(a arr<str>, range arrow<nat64, nat64>) */
struct arr_2 subscript_33(struct ctx* ctx, struct arr_2 a, struct arrow_0 range) {
	uint8_t _0 = _lessOrEqual_0(range.from, range.to);
	assert_0(ctx, _0);
	uint8_t _1 = _lessOrEqual_0(range.to, a.size);
	assert_0(ctx, _1);
	struct str* _2 = _plus_8(a.begin_ptr, range.from);
	return (struct arr_2) {(range.to - range.from), _2};
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
	
	struct mut_list_2* _1 = mut_list_1(ctx);
	*temp0 = (struct mut_dict_0) {_1, 0u, (struct opt_14) {0, .as0 = (struct none) {}}};
	return temp0;
}
/* mut-list<arrow<k, opt<v>>> mut-list<arrow<str, opt<arr<str>>>>() */
struct mut_list_2* mut_list_1(struct ctx* ctx) {
	struct mut_list_2* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_list_2));
	temp0 = ((struct mut_list_2*) _0);
	
	struct mut_arr_4 _1 = mut_arr_6();
	*temp0 = (struct mut_list_2) {_1, 0u};
	return temp0;
}
/* mut-arr<a> mut-arr<arrow<str, opt<arr<str>>>>() */
struct mut_arr_4 mut_arr_6(void) {
	return (struct mut_arr_4) {(struct void_) {}, (struct arr_9) {0u, NULL}};
}
/* parse-named-args-recur void(args arr<str>, builder mut-dict<str, arr<str>>) */
struct void_ parse_named_args_recur(struct ctx* ctx, struct arr_2 args, struct mut_dict_0* builder) {
	top:;
	struct str first_name0;
	struct str _0 = subscript_26(ctx, args, 0u);
	struct opt_15 _1 = try_remove_start_0(ctx, _0, (struct str) {{2, constantarr_0_14}});
	first_name0 = force_0(ctx, _1);
	
	struct arr_2 tl1;
	tl1 = tail_1(ctx, args);
	
	struct opt_11 _2 = find_index(ctx, tl1, (struct fun_act1_8) {2, .as2 = (struct void_) {}});
	switch (_2.kind) {
		case 0: {
			return set_subscript_5(ctx, builder, first_name0, tl1);
		}
		case 1: {
			struct some_11 _matched2 = _2.as1;
			
			uint64_t next_named_arg_index3;
			next_named_arg_index3 = _matched2.value;
			
			struct arrow_0 _3 = _arrow_0(0u, next_named_arg_index3);
			struct arr_2 _4 = subscript_33(ctx, tl1, _3);
			set_subscript_5(ctx, builder, first_name0, _4);
			struct arrow_0 _5 = _arrow_0(next_named_arg_index3, tl1.size);
			struct arr_2 _6 = subscript_33(ctx, tl1, _5);
			args = _6;
			builder = builder;
			goto top;
		}
		default:
			
	return (struct void_) {};;
	}
}
/* force<str> str(a opt<str>) */
struct str force_0(struct ctx* ctx, struct opt_15 a) {
	return force_1(ctx, a, (struct str) {{27, constantarr_0_15}});
}
/* force<a> str(a opt<str>, message str) */
struct str force_1(struct ctx* ctx, struct opt_15 a, struct str message) {
	struct opt_15 _0 = a;
	switch (_0.kind) {
		case 0: {
			return throw_2(ctx, message);
		}
		case 1: {
			struct some_15 _matched0 = _0.as1;
			
			struct str v1;
			v1 = _matched0.value;
			
			return v1;
		}
		default:
			
	return (struct str) {(struct arr_0) {0, NULL}};;
	}
}
/* throw<a> str(message str) */
struct str throw_2(struct ctx* ctx, struct str message) {
	struct backtrace _0 = get_backtrace(ctx);
	return throw_3(ctx, (struct exception) {message, _0});
}
/* throw<a> str(e exception) */
struct str throw_3(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx0;
	exn_ctx0 = get_exception_ctx(ctx);
	
	uint8_t _0 = _notEqual_3(exn_ctx0->jmp_buf_ptr, NULL);
	hard_assert(_0);
	exn_ctx0->thrown_exception = e;
	int32_t _1 = number_to_throw(ctx);
	(longjmp(exn_ctx0->jmp_buf_ptr, _1), (struct void_) {});
	return hard_unreachable_2();
}
/* hard-unreachable<a> str() */
struct str hard_unreachable_2(void) {
	(abort(), (struct void_) {});
	return (struct str) {(struct arr_0) {0, NULL}};
}
/* try-remove-start opt<str>(a str, b str) */
struct opt_15 try_remove_start_0(struct ctx* ctx, struct str a, struct str b) {
	struct opt_16 _0 = try_remove_start_1(ctx, a.chars, b.chars);
	switch (_0.kind) {
		case 0: {
			return (struct opt_15) {0, .as0 = (struct none) {}};
		}
		case 1: {
			struct some_16 _matched0 = _0.as1;
			
			struct arr_0 res1;
			res1 = _matched0.value;
			
			return (struct opt_15) {1, .as1 = (struct some_15) {(struct str) {res1}}};
		}
		default:
			
	return (struct opt_15) {0};;
	}
}
/* try-remove-start<char> opt<arr<char>>(a arr<char>, start arr<char>) */
struct opt_16 try_remove_start_1(struct ctx* ctx, struct arr_0 a, struct arr_0 start) {
	uint8_t _0 = starts_with_1(ctx, a, start);
	if (_0) {
		struct arrow_0 _1 = _arrow_0(start.size, a.size);
		struct arr_0 _2 = subscript_4(ctx, a, _1);
		return (struct opt_16) {1, .as1 = (struct some_16) {_2}};
	} else {
		return (struct opt_16) {0, .as0 = (struct none) {}};
	}
}
/* tail<str> arr<str>(a arr<str>) */
struct arr_2 tail_1(struct ctx* ctx, struct arr_2 a) {
	uint8_t _0 = is_empty_6(a);
	forbid(ctx, _0);
	struct arrow_0 _1 = _arrow_0(1u, a.size);
	return subscript_33(ctx, a, _1);
}
/* is-empty<a> bool(a arr<str>) */
uint8_t is_empty_6(struct arr_2 a) {
	return (a.size == 0u);
}
/* parse-named-args-recur.lambda0 bool(arg str) */
uint8_t parse_named_args_recur__lambda0(struct ctx* ctx, struct void_ _closure, struct str arg) {
	return starts_with_0(ctx, arg, (struct str) {{2, constantarr_0_14}});
}
/* set-subscript<str, arr<str>> void(a mut-dict<str, arr<str>>, key str, value arr<str>) */
struct void_ set_subscript_5(struct ctx* ctx, struct mut_dict_0* a, struct str key, struct arr_2 value) {
	uint8_t _0 = insert_into_key_match_or_empty_slot__e_0(ctx, a, key, value);
	uint8_t _1 = _not(_0);
	if (_1) {
		return add_pair__e_0(ctx, a, key, value);
	} else {
		return (struct void_) {};
	}
}
/* insert-into-key-match-or-empty-slot!<k, v> bool(a mut-dict<str, arr<str>>, key str, value arr<str>) */
uint8_t insert_into_key_match_or_empty_slot__e_0(struct ctx* ctx, struct mut_dict_0* a, struct str key, struct arr_2 value) {
	struct arrow_1* insert_ptr0;
	insert_ptr0 = find_insert_ptr_0(ctx, a, key);
	
	uint8_t can_insert1;
	struct arrow_1* _0 = end_ptr_4(a->pairs);
	can_insert1 = _notEqual_9(insert_ptr0, _0);
	uint8_t _1;
	
	if (can_insert1) {
		_1 = _equal_5((*insert_ptr0).from, key);
	} else {
		_1 = 0;
	}
	if (_1) {
		uint8_t _2 = is_empty_7((*insert_ptr0).to);
		if (_2) {
			uint64_t _3 = _plus_3(ctx, a->node_size, 1u);
			a->node_size = _3;
		} else {
			(struct void_) {};
		}
		struct arrow_1 _4 = _arrow_1(key, (struct opt_12) {1, .as1 = (struct some_12) {value}});
		*insert_ptr0 = _4;
		return 1;
	} else {
		uint8_t inserted4;
		struct opt_14 _5 = a->next;
		switch (_5.kind) {
			case 0: {
				inserted4 = 0;
				break;
			}
			case 1: {
				struct some_14 _matched2 = _5.as1;
				
				struct mut_dict_0* next3;
				next3 = _matched2.value;
				
				inserted4 = insert_into_key_match_or_empty_slot__e_0(ctx, next3, key, value);
				break;
			}
			default:
				
		inserted4 = 0;;
		}
		
		uint8_t _6 = inserted4;
		if (_6) {
			return 1;
		} else {uint8_t _7;
			
			if (can_insert1) {
				_7 = is_empty_7((*insert_ptr0).to);
			} else {
				_7 = 0;
			}
			if (_7) {
				uint8_t _8 = _less_6(key, (*insert_ptr0).from);
				assert_0(ctx, _8);
				uint64_t _9 = _plus_3(ctx, a->node_size, 1u);
				a->node_size = _9;
				struct arrow_1 _10 = _arrow_1(key, (struct opt_12) {1, .as1 = (struct some_12) {value}});
				*insert_ptr0 = _10;
				return 1;
			} else {uint8_t _11;
				
				if (can_insert1) {
					struct arrow_1* _12 = begin_ptr_6(a->pairs);
					_11 = _notEqual_9(insert_ptr0, _12);
				} else {
					_11 = 0;
				}uint8_t _13;
				
				if (_11) {
					_13 = is_empty_7((*(insert_ptr0 - 1u)).to);
				} else {
					_13 = 0;
				}
				if (_13) {
					uint8_t _14 = _less_6(key, (*insert_ptr0).from);
					assert_0(ctx, _14);
					uint64_t _15 = _plus_3(ctx, a->node_size, 1u);
					a->node_size = _15;
					struct arrow_1 _16 = _arrow_1(key, (struct opt_12) {1, .as1 = (struct some_12) {value}});
					*(insert_ptr0 - 1u) = _16;
					return 1;
				} else {
					return 0;
				}
			}
		}
	}
}
/* find-insert-ptr<k, v> mut-ptr<arrow<str, opt<arr<str>>>>(a mut-dict<str, arr<str>>, key str) */
struct arrow_1* find_insert_ptr_0(struct ctx* ctx, struct mut_dict_0* a, struct str key) {
	struct find_insert_ptr_0__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct find_insert_ptr_0__lambda0));
	temp0 = ((struct find_insert_ptr_0__lambda0*) _0);
	
	*temp0 = (struct find_insert_ptr_0__lambda0) {key};
	return binary_search_insert_ptr_0(ctx, a->pairs, (struct fun_act1_11) {0, .as0 = temp0});
}
/* binary-search-insert-ptr<arrow<k, opt<v>>> mut-ptr<arrow<str, opt<arr<str>>>>(a mut-list<arrow<str, opt<arr<str>>>>, compare fun-act1<comparison, arrow<str, opt<arr<str>>>>) */
struct arrow_1* binary_search_insert_ptr_0(struct ctx* ctx, struct mut_list_2* a, struct fun_act1_11 compare) {
	struct mut_arr_4 _0 = temp_as_mut_arr_1(a);
	return binary_search_insert_ptr_1(ctx, _0, compare);
}
/* binary-search-insert-ptr<a> mut-ptr<arrow<str, opt<arr<str>>>>(a mut-arr<arrow<str, opt<arr<str>>>>, compare fun-act1<comparison, arrow<str, opt<arr<str>>>>) */
struct arrow_1* binary_search_insert_ptr_1(struct ctx* ctx, struct mut_arr_4 a, struct fun_act1_11 compare) {
	struct arrow_1* _0 = begin_ptr_5(a);
	struct arrow_1* _1 = end_ptr_3(a);
	struct arrow_1* _2 = binary_search_compare_recur_0(ctx, ((struct arrow_1*) _0), ((struct arrow_1*) _1), compare);
	return ((struct arrow_1*) _2);
}
/* binary-search-compare-recur<a> const-ptr<arrow<str, opt<arr<str>>>>(left const-ptr<arrow<str, opt<arr<str>>>>, right const-ptr<arrow<str, opt<arr<str>>>>, compare fun-act1<comparison, arrow<str, opt<arr<str>>>>) */
struct arrow_1* binary_search_compare_recur_0(struct ctx* ctx, struct arrow_1* left, struct arrow_1* right, struct fun_act1_11 compare) {
	top:;
	uint8_t _0 = _equal_7(left, right);
	if (_0) {
		return left;
	} else {
		struct arrow_1* mid0;
		uint64_t _1 = _minus_5(right, left);
		mid0 = _plus_10(left, (_1 / 2u));
		
		struct arrow_1 _2 = _times_12(mid0);
		struct comparison _3 = subscript_34(ctx, compare, _2);
		switch (_3.kind) {
			case 0: {
				left = left;
				right = mid0;
				compare = compare;
				goto top;
			}
			case 1: {
				return mid0;
			}
			case 2: {
				struct arrow_1* _4 = _plus_10(mid0, 1u);
				left = _4;
				right = right;
				compare = compare;
				goto top;
			}
			default:
				
		return NULL;;
		}
	}
}
/* ==<a> bool(a const-ptr<arrow<str, opt<arr<str>>>>, b const-ptr<arrow<str, opt<arr<str>>>>) */
uint8_t _equal_7(struct arrow_1* a, struct arrow_1* b) {
	return (((struct arrow_1*) a) == ((struct arrow_1*) b));
}
/* +<a> const-ptr<arrow<str, opt<arr<str>>>>(a const-ptr<arrow<str, opt<arr<str>>>>, offset nat64) */
struct arrow_1* _plus_10(struct arrow_1* a, uint64_t offset) {
	return ((struct arrow_1*) (((struct arrow_1*) a) + offset));
}
/* -<a> nat64(a const-ptr<arrow<str, opt<arr<str>>>>, b const-ptr<arrow<str, opt<arr<str>>>>) */
uint64_t _minus_5(struct arrow_1* a, struct arrow_1* b) {
	return _minus_6(((struct arrow_1*) a), ((struct arrow_1*) b));
}
/* -<a> nat64(a mut-ptr<arrow<str, opt<arr<str>>>>, b mut-ptr<arrow<str, opt<arr<str>>>>) */
uint64_t _minus_6(struct arrow_1* a, struct arrow_1* b) {
	return ((((uint64_t) a) - ((uint64_t) b)) / sizeof(struct arrow_1));
}
/* subscript<comparison, a> comparison(a fun-act1<comparison, arrow<str, opt<arr<str>>>>, p0 arrow<str, opt<arr<str>>>) */
struct comparison subscript_34(struct ctx* ctx, struct fun_act1_11 a, struct arrow_1 p0) {
	return call_w_ctx_530(a, ctx, p0);
}
/* call-w-ctx<comparison, arrow<str, opt<arr<str>>>> (generated) (generated) */
struct comparison call_w_ctx_530(struct fun_act1_11 a, struct ctx* ctx, struct arrow_1 p0) {
	struct fun_act1_11 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct find_insert_ptr_0__lambda0* closure0 = _0.as0;
			
			return find_insert_ptr_0__lambda0(ctx, closure0, p0);
		}
		default:
			
	return (struct comparison) {0};;
	}
}
/* *<a> arrow<str, opt<arr<str>>>(a const-ptr<arrow<str, opt<arr<str>>>>) */
struct arrow_1 _times_12(struct arrow_1* a) {
	return (*((struct arrow_1*) a));
}
/* begin-ptr<a> mut-ptr<arrow<str, opt<arr<str>>>>(a mut-arr<arrow<str, opt<arr<str>>>>) */
struct arrow_1* begin_ptr_5(struct mut_arr_4 a) {
	return ((struct arrow_1*) a.inner.begin_ptr);
}
/* end-ptr<a> mut-ptr<arrow<str, opt<arr<str>>>>(a mut-arr<arrow<str, opt<arr<str>>>>) */
struct arrow_1* end_ptr_3(struct mut_arr_4 a) {
	struct arrow_1* _0 = begin_ptr_5(a);
	uint64_t _1 = size_4(a);
	return (_0 + _1);
}
/* size<a> nat64(a mut-arr<arrow<str, opt<arr<str>>>>) */
uint64_t size_4(struct mut_arr_4 a) {
	return a.inner.size;
}
/* temp-as-mut-arr<a> mut-arr<arrow<str, opt<arr<str>>>>(a mut-list<arrow<str, opt<arr<str>>>>) */
struct mut_arr_4 temp_as_mut_arr_1(struct mut_list_2* a) {
	struct arrow_1* _0 = begin_ptr_6(a);
	return mut_arr_7(a->size, _0);
}
/* mut-arr<a> mut-arr<arrow<str, opt<arr<str>>>>(size nat64, begin-ptr mut-ptr<arrow<str, opt<arr<str>>>>) */
struct mut_arr_4 mut_arr_7(uint64_t size, struct arrow_1* begin_ptr) {
	return (struct mut_arr_4) {(struct void_) {}, (struct arr_9) {size, ((struct arrow_1*) begin_ptr)}};
}
/* begin-ptr<a> mut-ptr<arrow<str, opt<arr<str>>>>(a mut-list<arrow<str, opt<arr<str>>>>) */
struct arrow_1* begin_ptr_6(struct mut_list_2* a) {
	return begin_ptr_5(a->backing);
}
/* find-insert-ptr<k, v>.lambda0 comparison(pair arrow<str, opt<arr<str>>>) */
struct comparison find_insert_ptr_0__lambda0(struct ctx* ctx, struct find_insert_ptr_0__lambda0* _closure, struct arrow_1 pair) {
	return _compare_8(_closure->key, pair.from);
}
/* !=<mut-ptr<arrow<k, opt<v>>>> bool(a mut-ptr<arrow<str, opt<arr<str>>>>, b mut-ptr<arrow<str, opt<arr<str>>>>) */
uint8_t _notEqual_9(struct arrow_1* a, struct arrow_1* b) {
	return _not((a == b));
}
/* end-ptr<arrow<k, opt<v>>> mut-ptr<arrow<str, opt<arr<str>>>>(a mut-list<arrow<str, opt<arr<str>>>>) */
struct arrow_1* end_ptr_4(struct mut_list_2* a) {
	struct arrow_1* _0 = begin_ptr_6(a);
	return (_0 + a->size);
}
/* is-empty<v> bool(a opt<arr<str>>) */
uint8_t is_empty_7(struct opt_12 a) {
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
/* -><k, opt<v>> arrow<str, opt<arr<str>>>(from str, to opt<arr<str>>) */
struct arrow_1 _arrow_1(struct str from, struct opt_12 to) {
	return (struct arrow_1) {from, to};
}
/* <<k> bool(a str, b str) */
uint8_t _less_6(struct str a, struct str b) {
	struct comparison _0 = _compare_8(a, b);
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
/* add-pair!<k, v> void(a mut-dict<str, arr<str>>, key str, value arr<str>) */
struct void_ add_pair__e_0(struct ctx* ctx, struct mut_dict_0* a, struct str key, struct arr_2 value) {
	uint8_t _0 = _less_0(a->node_size, 4u);
	if (_0) {
		uint8_t _1 = is_empty_8(a->pairs);
		if (_1) {
			struct arrow_1 _2 = _arrow_1(key, (struct opt_12) {1, .as1 = (struct some_12) {value}});
			_concatEquals_4(ctx, a->pairs, _2);
		} else {
			insert_linear__e_0(ctx, a->pairs, 0u, key, value);
		}
		uint64_t _3 = _plus_3(ctx, a->node_size, 1u);
		return (a->node_size = _3, (struct void_) {});
	} else {
		uint64_t _4 = _minus_7(ctx, a->pairs->size, 4u);
		struct arrow_1 _5 = subscript_37(ctx, a->pairs, _4);
		uint8_t _6 = _greater_1(key, _5.from);
		if (_6) {
			uint64_t _7 = _minus_7(ctx, a->pairs->size, 4u);
			insert_linear__e_0(ctx, a->pairs, _7, key, value);
			uint64_t _8 = _plus_3(ctx, a->node_size, 1u);
			return (a->node_size = _8, (struct void_) {});
		} else {
			struct opt_14 _9 = a->next;
			switch (_9.kind) {
				case 0: {
					struct mut_list_2* new_pairs0;
					new_pairs0 = mut_list_1(ctx);
					
					struct arrow_1 _10 = _arrow_1(key, (struct opt_12) {1, .as1 = (struct some_12) {value}});
					_concatEquals_4(ctx, new_pairs0, _10);
					struct mut_dict_0* temp0;
					uint8_t* _11 = alloc(ctx, sizeof(struct mut_dict_0));
					temp0 = ((struct mut_dict_0*) _11);
					
					*temp0 = (struct mut_dict_0) {new_pairs0, 1u, (struct opt_14) {0, .as0 = (struct none) {}}};
					return (a->next = (struct opt_14) {1, .as1 = (struct some_14) {temp0}}, (struct void_) {});
				}
				case 1: {
					struct some_14 _matched1 = _9.as1;
					
					struct mut_dict_0* next2;
					next2 = _matched1.value;
					
					add_pair__e_0(ctx, next2, key, value);
					return compact_if_needed__e_0(ctx, a);
				}
				default:
					
			return (struct void_) {};;
			}
		}
	}
}
/* is-empty<arrow<k, opt<v>>> bool(a mut-list<arrow<str, opt<arr<str>>>>) */
uint8_t is_empty_8(struct mut_list_2* a) {
	return (a->size == 0u);
}
/* ~=<arrow<k, opt<v>>> void(a mut-list<arrow<str, opt<arr<str>>>>, value arrow<str, opt<arr<str>>>) */
struct void_ _concatEquals_4(struct ctx* ctx, struct mut_list_2* a, struct arrow_1 value) {
	incr_capacity__e_1(ctx, a);
	uint64_t _0 = capacity_2(a);
	uint8_t _1 = _less_0(a->size, _0);
	assert_0(ctx, _1);
	struct arrow_1* _2 = begin_ptr_6(a);
	set_subscript_6(_2, a->size, value);
	uint64_t _3 = _plus_3(ctx, a->size, 1u);
	return (a->size = _3, (struct void_) {});
}
/* incr-capacity!<a> void(a mut-list<arrow<str, opt<arr<str>>>>) */
struct void_ incr_capacity__e_1(struct ctx* ctx, struct mut_list_2* a) {
	uint64_t _0 = _plus_3(ctx, a->size, 1u);
	uint64_t _1 = round_up_to_power_of_two(ctx, _0);
	return ensure_capacity_1(ctx, a, _1);
}
/* ensure-capacity<a> void(a mut-list<arrow<str, opt<arr<str>>>>, min-capacity nat64) */
struct void_ ensure_capacity_1(struct ctx* ctx, struct mut_list_2* a, uint64_t min_capacity) {
	uint64_t _0 = capacity_2(a);
	uint8_t _1 = _less_0(_0, min_capacity);
	if (_1) {
		return increase_capacity_to__e_1(ctx, a, min_capacity);
	} else {
		return (struct void_) {};
	}
}
/* capacity<a> nat64(a mut-list<arrow<str, opt<arr<str>>>>) */
uint64_t capacity_2(struct mut_list_2* a) {
	return size_4(a->backing);
}
/* increase-capacity-to!<a> void(a mut-list<arrow<str, opt<arr<str>>>>, new-capacity nat64) */
struct void_ increase_capacity_to__e_1(struct ctx* ctx, struct mut_list_2* a, uint64_t new_capacity) {
	uint64_t _0 = capacity_2(a);
	uint8_t _1 = _greater_0(new_capacity, _0);
	assert_0(ctx, _1);
	struct arrow_1* old_begin0;
	old_begin0 = begin_ptr_6(a);
	
	struct mut_arr_4 _2 = uninitialized_mut_arr_2(ctx, new_capacity);
	a->backing = _2;
	struct arrow_1* _3 = begin_ptr_6(a);
	copy_data_from__e_2(ctx, _3, ((struct arrow_1*) old_begin0), a->size);
	uint64_t _4 = _plus_3(ctx, a->size, 1u);
	uint64_t _5 = size_4(a->backing);
	struct arrow_0 _6 = _arrow_0(_4, _5);
	struct mut_arr_4 _7 = subscript_35(ctx, a->backing, _6);
	return set_zero_elements_1(_7);
}
/* uninitialized-mut-arr<a> mut-arr<arrow<str, opt<arr<str>>>>(size nat64) */
struct mut_arr_4 uninitialized_mut_arr_2(struct ctx* ctx, uint64_t size) {
	struct arrow_1* _0 = alloc_uninitialized_3(ctx, size);
	return mut_arr_7(size, _0);
}
/* alloc-uninitialized<a> mut-ptr<arrow<str, opt<arr<str>>>>(size nat64) */
struct arrow_1* alloc_uninitialized_3(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(struct arrow_1)));
	return ((struct arrow_1*) _0);
}
/* copy-data-from!<a> void(to mut-ptr<arrow<str, opt<arr<str>>>>, from const-ptr<arrow<str, opt<arr<str>>>>, len nat64) */
struct void_ copy_data_from__e_2(struct ctx* ctx, struct arrow_1* to, struct arrow_1* from, uint64_t len) {
	uint8_t* _0 = as_any_const_ptr_2(from);
	uint8_t* _1 = memcpy(((uint8_t*) to), _0, (len * sizeof(struct arrow_1)));
	return drop_0(_1);
}
/* as-any-const-ptr<const-ptr<a>> const-ptr<nat8>(ref const-ptr<arrow<str, opt<arr<str>>>>) */
uint8_t* as_any_const_ptr_2(struct arrow_1* ref) {
	return ((uint8_t*) ((uint8_t*) ref));
}
/* set-zero-elements<a> void(a mut-arr<arrow<str, opt<arr<str>>>>) */
struct void_ set_zero_elements_1(struct mut_arr_4 a) {
	struct arrow_1* _0 = begin_ptr_5(a);
	uint64_t _1 = size_4(a);
	return set_zero_range_2(_0, _1);
}
/* set-zero-range<a> void(begin mut-ptr<arrow<str, opt<arr<str>>>>, size nat64) */
struct void_ set_zero_range_2(struct arrow_1* begin, uint64_t size) {
	uint8_t* _0 = memset(((uint8_t*) begin), 0, (size * sizeof(struct arrow_1)));
	return drop_0(_0);
}
/* subscript<a> mut-arr<arrow<str, opt<arr<str>>>>(a mut-arr<arrow<str, opt<arr<str>>>>, range arrow<nat64, nat64>) */
struct mut_arr_4 subscript_35(struct ctx* ctx, struct mut_arr_4 a, struct arrow_0 range) {
	uint8_t _0 = _lessOrEqual_0(range.from, range.to);
	assert_0(ctx, _0);
	uint64_t _1 = size_4(a);
	uint8_t _2 = _lessOrEqual_0(range.to, _1);
	assert_0(ctx, _2);
	struct arr_9 _3 = subscript_36(ctx, a.inner, range);
	return (struct mut_arr_4) {(struct void_) {}, _3};
}
/* subscript<a> arr<arrow<str, opt<arr<str>>>>(a arr<arrow<str, opt<arr<str>>>>, range arrow<nat64, nat64>) */
struct arr_9 subscript_36(struct ctx* ctx, struct arr_9 a, struct arrow_0 range) {
	uint8_t _0 = _lessOrEqual_0(range.from, range.to);
	assert_0(ctx, _0);
	uint8_t _1 = _lessOrEqual_0(range.to, a.size);
	assert_0(ctx, _1);
	struct arrow_1* _2 = _plus_10(a.begin_ptr, range.from);
	return (struct arr_9) {(range.to - range.from), _2};
}
/* set-subscript<a> void(a mut-ptr<arrow<str, opt<arr<str>>>>, n nat64, value arrow<str, opt<arr<str>>>) */
struct void_ set_subscript_6(struct arrow_1* a, uint64_t n, struct arrow_1 value) {
	return (*(a + n) = value, (struct void_) {});
}
/* insert-linear!<k, v> void(a mut-list<arrow<str, opt<arr<str>>>>, index nat64, key str, value arr<str>) */
struct void_ insert_linear__e_0(struct ctx* ctx, struct mut_list_2* a, uint64_t index, struct str key, struct arr_2 value) {
	top:;
	struct arrow_1 _0 = subscript_37(ctx, a, index);
	uint8_t _1 = _less_6(key, _0.from);
	if (_1) {
		move_right__e_0(ctx, a, index);
		struct arrow_1 _2 = _arrow_1(key, (struct opt_12) {1, .as1 = (struct some_12) {value}});
		return set_subscript_7(ctx, a, index, _2);
	} else {
		uint64_t _3 = _minus_7(ctx, a->size, 1u);
		uint8_t _4 = (index == _3);
		if (_4) {
			struct arrow_1 _5 = _arrow_1(key, (struct opt_12) {1, .as1 = (struct some_12) {value}});
			return _concatEquals_4(ctx, a, _5);
		} else {
			uint64_t _6 = _plus_3(ctx, index, 1u);
			a = a;
			index = _6;
			key = key;
			value = value;
			goto top;
		}
	}
}
/* subscript<arrow<k, opt<v>>> arrow<str, opt<arr<str>>>(a mut-list<arrow<str, opt<arr<str>>>>, index nat64) */
struct arrow_1 subscript_37(struct ctx* ctx, struct mut_list_2* a, uint64_t index) {
	uint8_t _0 = _less_0(index, a->size);
	assert_0(ctx, _0);
	struct arrow_1* _1 = begin_ptr_6(a);
	return subscript_38(_1, index);
}
/* subscript<a> arrow<str, opt<arr<str>>>(a mut-ptr<arrow<str, opt<arr<str>>>>, n nat64) */
struct arrow_1 subscript_38(struct arrow_1* a, uint64_t n) {
	return (*(a + n));
}
/* move-right!<k, v> void(a mut-list<arrow<str, opt<arr<str>>>>, index nat64) */
struct void_ move_right__e_0(struct ctx* ctx, struct mut_list_2* a, uint64_t index) {
	struct arrow_1 _0 = subscript_37(ctx, a, index);
	uint8_t _1 = is_empty_7(_0.to);
	uint8_t _2 = _not(_1);
	if (_2) {
		uint64_t _3 = _minus_7(ctx, a->size, 1u);
		uint8_t _4 = (index == _3);
		if (_4) {
			struct arrow_1 _5 = subscript_37(ctx, a, index);
			return _concatEquals_4(ctx, a, _5);
		} else {
			uint64_t _6 = _plus_3(ctx, index, 1u);
			move_right__e_0(ctx, a, _6);
			uint64_t _7 = _plus_3(ctx, index, 1u);
			struct arrow_1 _8 = subscript_37(ctx, a, index);
			return set_subscript_7(ctx, a, _7, _8);
		}
	} else {
		return (struct void_) {};
	}
}
/* - nat64(a nat64, b nat64) */
uint64_t _minus_7(struct ctx* ctx, uint64_t a, uint64_t b) {
	uint8_t _0 = _greaterOrEqual(a, b);
	assert_0(ctx, _0);
	return (a - b);
}
/* set-subscript<arrow<k, opt<v>>> void(a mut-list<arrow<str, opt<arr<str>>>>, index nat64, value arrow<str, opt<arr<str>>>) */
struct void_ set_subscript_7(struct ctx* ctx, struct mut_list_2* a, uint64_t index, struct arrow_1 value) {
	uint8_t _0 = _less_0(index, a->size);
	assert_0(ctx, _0);
	struct arrow_1* _1 = begin_ptr_6(a);
	return set_subscript_6(_1, index, value);
}
/* ><k> bool(a str, b str) */
uint8_t _greater_1(struct str a, struct str b) {
	return _less_6(b, a);
}
/* compact-if-needed!<k, v> void(a mut-dict<str, arr<str>>) */
struct void_ compact_if_needed__e_0(struct ctx* ctx, struct mut_dict_0* a) {
	uint64_t physical_size0;
	physical_size0 = total_pairs_size_0(ctx, a);
	
	uint64_t _0 = _times_3(ctx, a->node_size, 2u);
	uint8_t _1 = _lessOrEqual_0(_0, physical_size0);
	if (_1) {
		compact__e_0(ctx, a);
		uint64_t _2 = total_pairs_size_0(ctx, a);
		return assert_0(ctx, (a->node_size == _2));
	} else {
		return (struct void_) {};
	}
}
/* total-pairs-size<k, v> nat64(a mut-dict<str, arr<str>>) */
uint64_t total_pairs_size_0(struct ctx* ctx, struct mut_dict_0* a) {
	return total_pairs_size_recur_0(ctx, 0u, a);
}
/* total-pairs-size-recur<k, v> nat64(acc nat64, a mut-dict<str, arr<str>>) */
uint64_t total_pairs_size_recur_0(struct ctx* ctx, uint64_t acc, struct mut_dict_0* a) {
	top:;
	uint64_t mid0;
	mid0 = _plus_3(ctx, acc, a->pairs->size);
	
	struct opt_14 _0 = a->next;
	switch (_0.kind) {
		case 0: {
			return mid0;
		}
		case 1: {
			struct some_14 _matched1 = _0.as1;
			
			struct mut_dict_0* next2;
			next2 = _matched1.value;
			
			acc = mid0;
			a = next2;
			goto top;
		}
		default:
			
	return 0;;
	}
}
/* compact!<k, v> void(a mut-dict<str, arr<str>>) */
struct void_ compact__e_0(struct ctx* ctx, struct mut_dict_0* a) {
	struct opt_14 _0 = a->next;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct some_14 _matched0 = _0.as1;
			
			struct mut_dict_0* next1;
			next1 = _matched0.value;
			
			compact__e_0(ctx, next1);
			filter__e_0(ctx, a->pairs, (struct fun_act1_12) {0, .as0 = (struct void_) {}});
			merge_no_duplicates__e_0(ctx, a->pairs, next1->pairs, (struct fun_act2_2) {0, .as0 = (struct void_) {}});
			a->next = (struct opt_14) {0, .as0 = (struct none) {}};
			return (a->node_size = a->pairs->size, (struct void_) {});
		}
		default:
			
	return (struct void_) {};;
	}
}
/* filter!<arrow<k, opt<v>>> void(a mut-list<arrow<str, opt<arr<str>>>>, f fun-act1<bool, arrow<str, opt<arr<str>>>>) */
struct void_ filter__e_0(struct ctx* ctx, struct mut_list_2* a, struct fun_act1_12 f) {
	struct arrow_1* new_end0;
	struct arrow_1* _0 = begin_ptr_6(a);
	struct arrow_1* _1 = begin_ptr_6(a);
	struct arrow_1* _2 = end_ptr_4(a);
	new_end0 = filter_recur__e_0(ctx, _0, ((struct arrow_1*) _1), ((struct arrow_1*) _2), f);
	
	uint64_t new_size1;
	struct arrow_1* _3 = begin_ptr_6(a);
	new_size1 = _minus_6(new_end0, _3);
	
	struct arrow_0 _4 = _arrow_0(new_size1, a->size);
	struct mut_arr_4 _5 = subscript_35(ctx, a->backing, _4);
	set_zero_elements_1(_5);
	return (a->size = new_size1, (struct void_) {});
}
/* filter-recur!<a> mut-ptr<arrow<str, opt<arr<str>>>>(out mut-ptr<arrow<str, opt<arr<str>>>>, in const-ptr<arrow<str, opt<arr<str>>>>, end const-ptr<arrow<str, opt<arr<str>>>>, f fun-act1<bool, arrow<str, opt<arr<str>>>>) */
struct arrow_1* filter_recur__e_0(struct ctx* ctx, struct arrow_1* out, struct arrow_1* in, struct arrow_1* end, struct fun_act1_12 f) {
	top:;
	uint8_t _0 = _equal_7(in, end);
	if (_0) {
		return out;
	} else {
		struct arrow_1* new_out0;
		struct arrow_1 _1 = _times_12(in);
		uint8_t _2 = subscript_39(ctx, f, _1);
		if (_2) {
			struct arrow_1 _3 = _times_12(in);
			*out = _3;
			new_out0 = (out + 1u);
		} else {
			new_out0 = out;
		}
		
		struct arrow_1* _4 = _plus_10(in, 1u);
		out = new_out0;
		in = _4;
		end = end;
		f = f;
		goto top;
	}
}
/* subscript<bool, a> bool(a fun-act1<bool, arrow<str, opt<arr<str>>>>, p0 arrow<str, opt<arr<str>>>) */
uint8_t subscript_39(struct ctx* ctx, struct fun_act1_12 a, struct arrow_1 p0) {
	return call_w_ctx_574(a, ctx, p0);
}
/* call-w-ctx<bool, arrow<str, opt<arr<str>>>> (generated) (generated) */
uint8_t call_w_ctx_574(struct fun_act1_12 a, struct ctx* ctx, struct arrow_1 p0) {
	struct fun_act1_12 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return compact__e_0__lambda0(ctx, closure0, p0);
		}
		default:
			
	return 0;;
	}
}
/* compact!<k, v>.lambda0 bool(pair arrow<str, opt<arr<str>>>) */
uint8_t compact__e_0__lambda0(struct ctx* ctx, struct void_ _closure, struct arrow_1 pair) {
	uint8_t _0 = is_empty_7(pair.to);
	return _not(_0);
}
/* merge-no-duplicates!<arrow<k, opt<v>>> void(a mut-list<arrow<str, opt<arr<str>>>>, b mut-list<arrow<str, opt<arr<str>>>>, compare fun-act2<unique-comparison, arrow<str, opt<arr<str>>>, arrow<str, opt<arr<str>>>>) */
struct void_ merge_no_duplicates__e_0(struct ctx* ctx, struct mut_list_2* a, struct mut_list_2* b, struct fun_act2_2 compare) {
	uint8_t _0 = _less_0(a->size, b->size);
	if (_0) {
		swap__e_1(ctx, a, b);
	} else {
		(struct void_) {};
	}
	uint8_t _1 = _greaterOrEqual(a->size, b->size);
	assert_0(ctx, _1);
	uint8_t _2 = is_empty_8(b);
	uint8_t _3 = _not(_2);
	if (_3) {
		uint64_t a_old_size0;
		a_old_size0 = a->size;
		
		unsafe_set_size__e_0(ctx, a, (a_old_size0 + b->size));
		struct arrow_1* a_read1;
		struct arrow_1* _4 = begin_ptr_6(a);
		struct arrow_1* _5 = _plus_10(((struct arrow_1*) _4), a_old_size0);
		a_read1 = _minus_8(_5, 1u);
		
		struct arrow_1* a_write2;
		struct arrow_1* _6 = end_ptr_4(a);
		a_write2 = (_6 - 1u);
		
		struct arrow_1* _7 = begin_ptr_6(a);
		struct arrow_1* _8 = begin_ptr_6(b);
		struct arrow_1* _9 = end_ptr_4(b);
		struct arrow_1* _10 = _minus_8(((struct arrow_1*) _9), 1u);
		merge_reverse_recur__e_0(ctx, _7, a_read1, a_write2, ((struct arrow_1*) _8), _10, compare);
		return empty__e_0(ctx, b);
	} else {
		return (struct void_) {};
	}
}
/* swap!<a> void(a mut-list<arrow<str, opt<arr<str>>>>, b mut-list<arrow<str, opt<arr<str>>>>) */
struct void_ swap__e_1(struct ctx* ctx, struct mut_list_2* a, struct mut_list_2* b) {
	struct mut_arr_4 a_backing0;
	a_backing0 = a->backing;
	
	uint64_t a_size1;
	a_size1 = a->size;
	
	a->backing = b->backing;
	a->size = b->size;
	b->backing = a_backing0;
	return (b->size = a_size1, (struct void_) {});
}
/* unsafe-set-size!<a> void(a mut-list<arrow<str, opt<arr<str>>>>, new-size nat64) */
struct void_ unsafe_set_size__e_0(struct ctx* ctx, struct mut_list_2* a, uint64_t new_size) {
	reserve_0(ctx, a, new_size);
	return (a->size = new_size, (struct void_) {});
}
/* reserve<a> void(a mut-list<arrow<str, opt<arr<str>>>>, reserved nat64) */
struct void_ reserve_0(struct ctx* ctx, struct mut_list_2* a, uint64_t reserved) {
	uint64_t _0 = round_up_to_power_of_two(ctx, reserved);
	return ensure_capacity_1(ctx, a, _0);
}
/* -<a> const-ptr<arrow<str, opt<arr<str>>>>(a const-ptr<arrow<str, opt<arr<str>>>>, offset nat64) */
struct arrow_1* _minus_8(struct arrow_1* a, uint64_t offset) {
	return ((struct arrow_1*) (((struct arrow_1*) a) - offset));
}
/* merge-reverse-recur!<a> void(a-begin mut-ptr<arrow<str, opt<arr<str>>>>, a-read const-ptr<arrow<str, opt<arr<str>>>>, a-write mut-ptr<arrow<str, opt<arr<str>>>>, b-begin const-ptr<arrow<str, opt<arr<str>>>>, b-read const-ptr<arrow<str, opt<arr<str>>>>, compare fun-act2<unique-comparison, arrow<str, opt<arr<str>>>, arrow<str, opt<arr<str>>>>) */
struct void_ merge_reverse_recur__e_0(struct ctx* ctx, struct arrow_1* a_begin, struct arrow_1* a_read, struct arrow_1* a_write, struct arrow_1* b_begin, struct arrow_1* b_read, struct fun_act2_2 compare) {
	top:;
	struct arrow_1 _0 = _times_12(a_read);
	struct arrow_1 _1 = _times_12(b_read);
	struct unique_comparison _2 = subscript_40(ctx, compare, _0, _1);
	switch (_2.kind) {
		case 0: {
			struct arrow_1 _3 = _times_12(b_read);
			*a_write = _3;
			uint8_t _4 = _notEqual_10(b_read, b_begin);
			if (_4) {
				struct arrow_1* _5 = _minus_8(b_read, 1u);
				a_begin = a_begin;
				a_read = a_read;
				a_write = (a_write - 1u);
				b_begin = b_begin;
				b_read = _5;
				compare = compare;
				goto top;
			} else {
				return (struct void_) {};
			}
		}
		case 1: {
			struct arrow_1 _6 = _times_12(a_read);
			*a_write = _6;
			uint8_t _7 = _equal_7(a_read, ((struct arrow_1*) a_begin));
			if (_7) {
				struct mut_arr_4 dest0;
				dest0 = mut_arr_from_begin_end_0(a_begin, a_write);
				
				struct arr_9 src1;
				struct arrow_1* _8 = _plus_10(b_read, 1u);
				src1 = arr_from_begin_end_1(b_begin, _8);
				
				return copy_from__e_0(ctx, dest0, src1);
			} else {
				struct arrow_1* _9 = _minus_8(a_read, 1u);
				a_begin = a_begin;
				a_read = _9;
				a_write = (a_write - 1u);
				b_begin = b_begin;
				b_read = b_read;
				compare = compare;
				goto top;
			}
		}
		default:
			
	return (struct void_) {};;
	}
}
/* subscript<unique-comparison, a, a> unique-comparison(a fun-act2<unique-comparison, arrow<str, opt<arr<str>>>, arrow<str, opt<arr<str>>>>, p0 arrow<str, opt<arr<str>>>, p1 arrow<str, opt<arr<str>>>) */
struct unique_comparison subscript_40(struct ctx* ctx, struct fun_act2_2 a, struct arrow_1 p0, struct arrow_1 p1) {
	return call_w_ctx_583(a, ctx, p0, p1);
}
/* call-w-ctx<unique-comparison, arrow<str, opt<arr<str>>>, arrow<str, opt<arr<str>>>> (generated) (generated) */
struct unique_comparison call_w_ctx_583(struct fun_act2_2 a, struct ctx* ctx, struct arrow_1 p0, struct arrow_1 p1) {
	struct fun_act2_2 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return compact__e_0__lambda1(ctx, closure0, p0, p1);
		}
		default:
			
	return (struct unique_comparison) {0};;
	}
}
/* !=<const-ptr<a>> bool(a const-ptr<arrow<str, opt<arr<str>>>>, b const-ptr<arrow<str, opt<arr<str>>>>) */
uint8_t _notEqual_10(struct arrow_1* a, struct arrow_1* b) {
	uint8_t _0 = _equal_7(a, b);
	return _not(_0);
}
/* mut-arr-from-begin-end<a> mut-arr<arrow<str, opt<arr<str>>>>(begin mut-ptr<arrow<str, opt<arr<str>>>>, end mut-ptr<arrow<str, opt<arr<str>>>>) */
struct mut_arr_4 mut_arr_from_begin_end_0(struct arrow_1* begin, struct arrow_1* end) {
	uint8_t _0 = _lessOrEqual_4(begin, end);
	hard_assert(_0);
	struct arr_9 _1 = arr_from_begin_end_1(((struct arrow_1*) begin), ((struct arrow_1*) end));
	return (struct mut_arr_4) {(struct void_) {}, _1};
}
/* <=><a> comparison(a mut-ptr<arrow<str, opt<arr<str>>>>, b mut-ptr<arrow<str, opt<arr<str>>>>) */
struct comparison _compare_11(struct arrow_1* a, struct arrow_1* b) {
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
/* <=<mut-ptr<a>> bool(a mut-ptr<arrow<str, opt<arr<str>>>>, b mut-ptr<arrow<str, opt<arr<str>>>>) */
uint8_t _lessOrEqual_4(struct arrow_1* a, struct arrow_1* b) {
	uint8_t _0 = _less_7(b, a);
	return _not(_0);
}
/* <<a> bool(a mut-ptr<arrow<str, opt<arr<str>>>>, b mut-ptr<arrow<str, opt<arr<str>>>>) */
uint8_t _less_7(struct arrow_1* a, struct arrow_1* b) {
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
/* arr-from-begin-end<a> arr<arrow<str, opt<arr<str>>>>(begin const-ptr<arrow<str, opt<arr<str>>>>, end const-ptr<arrow<str, opt<arr<str>>>>) */
struct arr_9 arr_from_begin_end_1(struct arrow_1* begin, struct arrow_1* end) {
	uint8_t _0 = _lessOrEqual_5(begin, end);
	hard_assert(_0);
	uint64_t _1 = _minus_5(end, begin);
	return (struct arr_9) {_1, begin};
}
/* <=><a> comparison(a const-ptr<arrow<str, opt<arr<str>>>>, b const-ptr<arrow<str, opt<arr<str>>>>) */
struct comparison _compare_12(struct arrow_1* a, struct arrow_1* b) {
	return _compare_11(((struct arrow_1*) a), ((struct arrow_1*) b));
}
/* <=<const-ptr<a>> bool(a const-ptr<arrow<str, opt<arr<str>>>>, b const-ptr<arrow<str, opt<arr<str>>>>) */
uint8_t _lessOrEqual_5(struct arrow_1* a, struct arrow_1* b) {
	uint8_t _0 = _less_8(b, a);
	return _not(_0);
}
/* <<a> bool(a const-ptr<arrow<str, opt<arr<str>>>>, b const-ptr<arrow<str, opt<arr<str>>>>) */
uint8_t _less_8(struct arrow_1* a, struct arrow_1* b) {
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
/* copy-from!<a> void(dest mut-arr<arrow<str, opt<arr<str>>>>, source arr<arrow<str, opt<arr<str>>>>) */
struct void_ copy_from__e_0(struct ctx* ctx, struct mut_arr_4 dest, struct arr_9 source) {
	uint64_t _0 = size_4(dest);
	assert_0(ctx, (_0 == source.size));
	struct arrow_1* _1 = begin_ptr_5(dest);
	uint8_t* _2 = as_any_const_ptr_2(source.begin_ptr);
	uint64_t _3 = size_4(dest);
	uint8_t* _4 = memcpy(((uint8_t*) _1), _2, (_3 * sizeof(struct arrow_1)));
	return drop_0(_4);
}
/* empty!<a> void(a mut-list<arrow<str, opt<arr<str>>>>) */
struct void_ empty__e_0(struct ctx* ctx, struct mut_list_2* a) {
	return pop_n__e_0(ctx, a, a->size);
}
/* pop-n!<a> void(a mut-list<arrow<str, opt<arr<str>>>>, n nat64) */
struct void_ pop_n__e_0(struct ctx* ctx, struct mut_list_2* a, uint64_t n) {
	uint8_t _0 = _lessOrEqual_0(n, a->size);
	assert_0(ctx, _0);
	uint64_t new_size0;
	new_size0 = _minus_7(ctx, a->size, n);
	
	struct arrow_1* _1 = begin_ptr_6(a);
	set_zero_range_2((_1 + new_size0), n);
	return (a->size = new_size0, (struct void_) {});
}
/* assert-comparison-not-equal unique-comparison(a comparison) */
struct unique_comparison assert_comparison_not_equal(struct ctx* ctx, struct comparison a) {
	struct comparison _0 = a;
	switch (_0.kind) {
		case 0: {
			return (struct unique_comparison) {0, .as0 = (struct less) {}};
		}
		case 1: {
			return unreachable(ctx);
		}
		case 2: {
			return (struct unique_comparison) {1, .as1 = (struct greater) {}};
		}
		default:
			
	return (struct unique_comparison) {0};;
	}
}
/* unreachable<unique-comparison> unique-comparison() */
struct unique_comparison unreachable(struct ctx* ctx) {
	return throw_4(ctx, (struct str) {{21, constantarr_0_16}});
}
/* throw<a> unique-comparison(message str) */
struct unique_comparison throw_4(struct ctx* ctx, struct str message) {
	struct backtrace _0 = get_backtrace(ctx);
	return throw_5(ctx, (struct exception) {message, _0});
}
/* throw<a> unique-comparison(e exception) */
struct unique_comparison throw_5(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx0;
	exn_ctx0 = get_exception_ctx(ctx);
	
	uint8_t _0 = _notEqual_3(exn_ctx0->jmp_buf_ptr, NULL);
	hard_assert(_0);
	exn_ctx0->thrown_exception = e;
	int32_t _1 = number_to_throw(ctx);
	(longjmp(exn_ctx0->jmp_buf_ptr, _1), (struct void_) {});
	return hard_unreachable_3();
}
/* hard-unreachable<a> unique-comparison() */
struct unique_comparison hard_unreachable_3(void) {
	(abort(), (struct void_) {});
	return (struct unique_comparison) {0};
}
/* compact!<k, v>.lambda1 unique-comparison(x arrow<str, opt<arr<str>>>, y arrow<str, opt<arr<str>>>) */
struct unique_comparison compact__e_0__lambda1(struct ctx* ctx, struct void_ _closure, struct arrow_1 x, struct arrow_1 y) {
	struct comparison _0 = _compare_8(x.from, y.from);
	return assert_comparison_not_equal(ctx, _0);
}
/* move-to-dict!<str, arr<str>> dict<str, arr<str>>(a mut-dict<str, arr<str>>) */
struct dict_0 move_to_dict__e_0(struct ctx* ctx, struct mut_dict_0* a) {
	struct arr_10 _0 = move_to_arr__e_1(ctx, a);
	return dict_0(ctx, _0);
}
/* move-to-arr!<k, v> arr<arrow<str, arr<str>>>(a mut-dict<str, arr<str>>) */
struct arr_10 move_to_arr__e_1(struct ctx* ctx, struct mut_dict_0* a) {
	struct arr_10 res0;
	res0 = map_to_arr_0(ctx, a, (struct fun_act2_3) {0, .as0 = (struct void_) {}});
	
	empty__e_1(ctx, a);
	return res0;
}
/* map-to-arr<arrow<k, v>, k, v> arr<arrow<str, arr<str>>>(a mut-dict<str, arr<str>>, f fun-act2<arrow<str, arr<str>>, str, arr<str>>) */
struct arr_10 map_to_arr_0(struct ctx* ctx, struct mut_dict_0* a, struct fun_act2_3 f) {
	compact__e_0(ctx, a);
	struct map_to_arr_0__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct map_to_arr_0__lambda0));
	temp0 = ((struct map_to_arr_0__lambda0*) _0);
	
	*temp0 = (struct map_to_arr_0__lambda0) {f};
	return map_to_arr_1(ctx, a->pairs, (struct fun_act1_13) {0, .as0 = temp0});
}
/* map-to-arr<out, arrow<k, opt<v>>> arr<arrow<str, arr<str>>>(a mut-list<arrow<str, opt<arr<str>>>>, f fun-act1<arrow<str, arr<str>>, arrow<str, opt<arr<str>>>>) */
struct arr_10 map_to_arr_1(struct ctx* ctx, struct mut_list_2* a, struct fun_act1_13 f) {
	struct mut_arr_3 _0 = map_to_mut_arr_0(ctx, a, f);
	return cast_immutable_1(_0);
}
/* map-to-mut-arr<out, in> mut-arr<arrow<str, arr<str>>>(a mut-list<arrow<str, opt<arr<str>>>>, f fun-act1<arrow<str, arr<str>>, arrow<str, opt<arr<str>>>>) */
struct mut_arr_3 map_to_mut_arr_0(struct ctx* ctx, struct mut_list_2* a, struct fun_act1_13 f) {
	struct map_to_mut_arr_0__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct map_to_mut_arr_0__lambda0));
	temp0 = ((struct map_to_mut_arr_0__lambda0*) _0);
	
	*temp0 = (struct map_to_mut_arr_0__lambda0) {f, a};
	return make_mut_arr_0(ctx, a->size, (struct fun_act1_10) {1, .as1 = temp0});
}
/* subscript<out, in> arrow<str, arr<str>>(a fun-act1<arrow<str, arr<str>>, arrow<str, opt<arr<str>>>>, p0 arrow<str, opt<arr<str>>>) */
struct arrow_2 subscript_41(struct ctx* ctx, struct fun_act1_13 a, struct arrow_1 p0) {
	return call_w_ctx_608(a, ctx, p0);
}
/* call-w-ctx<arrow<str, arr<str>>, arrow<str, opt<arr<str>>>> (generated) (generated) */
struct arrow_2 call_w_ctx_608(struct fun_act1_13 a, struct ctx* ctx, struct arrow_1 p0) {
	struct fun_act1_13 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct map_to_arr_0__lambda0* closure0 = _0.as0;
			
			return map_to_arr_0__lambda0(ctx, closure0, p0);
		}
		default:
			
	return (struct arrow_2) {(struct str) {(struct arr_0) {0, NULL}}, (struct arr_2) {0, NULL}};;
	}
}
/* map-to-mut-arr<out, in>.lambda0 arrow<str, arr<str>>(i nat64) */
struct arrow_2 map_to_mut_arr_0__lambda0(struct ctx* ctx, struct map_to_mut_arr_0__lambda0* _closure, uint64_t i) {
	struct arrow_1 _0 = subscript_37(ctx, _closure->a, i);
	return subscript_41(ctx, _closure->f, _0);
}
/* subscript<out, k, v> arrow<str, arr<str>>(a fun-act2<arrow<str, arr<str>>, str, arr<str>>, p0 str, p1 arr<str>) */
struct arrow_2 subscript_42(struct ctx* ctx, struct fun_act2_3 a, struct str p0, struct arr_2 p1) {
	return call_w_ctx_611(a, ctx, p0, p1);
}
/* call-w-ctx<arrow<str, arr<str>>, str, arr<str>> (generated) (generated) */
struct arrow_2 call_w_ctx_611(struct fun_act2_3 a, struct ctx* ctx, struct str p0, struct arr_2 p1) {
	struct fun_act2_3 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return move_to_arr__e_1__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return (struct arrow_2) {(struct str) {(struct arr_0) {0, NULL}}, (struct arr_2) {0, NULL}};;
	}
}
/* force<v> arr<str>(a opt<arr<str>>) */
struct arr_2 force_2(struct ctx* ctx, struct opt_12 a) {
	return force_3(ctx, a, (struct str) {{27, constantarr_0_15}});
}
/* force<a> arr<str>(a opt<arr<str>>, message str) */
struct arr_2 force_3(struct ctx* ctx, struct opt_12 a, struct str message) {
	struct opt_12 _0 = a;
	switch (_0.kind) {
		case 0: {
			return throw_6(ctx, message);
		}
		case 1: {
			struct some_12 _matched0 = _0.as1;
			
			struct arr_2 v1;
			v1 = _matched0.value;
			
			return v1;
		}
		default:
			
	return (struct arr_2) {0, NULL};;
	}
}
/* throw<a> arr<str>(message str) */
struct arr_2 throw_6(struct ctx* ctx, struct str message) {
	struct backtrace _0 = get_backtrace(ctx);
	return throw_7(ctx, (struct exception) {message, _0});
}
/* throw<a> arr<str>(e exception) */
struct arr_2 throw_7(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx0;
	exn_ctx0 = get_exception_ctx(ctx);
	
	uint8_t _0 = _notEqual_3(exn_ctx0->jmp_buf_ptr, NULL);
	hard_assert(_0);
	exn_ctx0->thrown_exception = e;
	int32_t _1 = number_to_throw(ctx);
	(longjmp(exn_ctx0->jmp_buf_ptr, _1), (struct void_) {});
	return hard_unreachable_4();
}
/* hard-unreachable<a> arr<str>() */
struct arr_2 hard_unreachable_4(void) {
	(abort(), (struct void_) {});
	return (struct arr_2) {0, NULL};
}
/* map-to-arr<arrow<k, v>, k, v>.lambda0 arrow<str, arr<str>>(pair arrow<str, opt<arr<str>>>) */
struct arrow_2 map_to_arr_0__lambda0(struct ctx* ctx, struct map_to_arr_0__lambda0* _closure, struct arrow_1 pair) {
	struct arr_2 _0 = force_2(ctx, pair.to);
	return subscript_42(ctx, _closure->f, pair.from, _0);
}
/* -><k, v> arrow<str, arr<str>>(from str, to arr<str>) */
struct arrow_2 _arrow_2(struct str from, struct arr_2 to) {
	return (struct arrow_2) {from, to};
}
/* move-to-arr!<k, v>.lambda0 arrow<str, arr<str>>(key str, value arr<str>) */
struct arrow_2 move_to_arr__e_1__lambda0(struct ctx* ctx, struct void_ _closure, struct str key, struct arr_2 value) {
	return _arrow_2(key, value);
}
/* empty!<k, v> void(a mut-dict<str, arr<str>>) */
struct void_ empty__e_1(struct ctx* ctx, struct mut_dict_0* a) {
	a->next = (struct opt_14) {0, .as0 = (struct none) {}};
	return empty__e_0(ctx, a->pairs);
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
/* fill-mut-list<opt<arr<str>>> mut-list<opt<arr<str>>>(size nat64, value opt<arr<str>>) */
struct mut_list_3* fill_mut_list(struct ctx* ctx, uint64_t size, struct opt_12 value) {
	struct mut_arr_5 backing0;
	backing0 = fill_mut_arr(ctx, size, value);
	
	struct mut_list_3* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_list_3));
	temp0 = ((struct mut_list_3*) _0);
	
	*temp0 = (struct mut_list_3) {backing0, size};
	return temp0;
}
/* fill-mut-arr<a> mut-arr<opt<arr<str>>>(size nat64, value opt<arr<str>>) */
struct mut_arr_5 fill_mut_arr(struct ctx* ctx, uint64_t size, struct opt_12 value) {
	struct fill_mut_arr__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct fill_mut_arr__lambda0));
	temp0 = ((struct fill_mut_arr__lambda0*) _0);
	
	*temp0 = (struct fill_mut_arr__lambda0) {value};
	return make_mut_arr_1(ctx, size, (struct fun_act1_14) {0, .as0 = temp0});
}
/* make-mut-arr<a> mut-arr<opt<arr<str>>>(size nat64, f fun-act1<opt<arr<str>>, nat64>) */
struct mut_arr_5 make_mut_arr_1(struct ctx* ctx, uint64_t size, struct fun_act1_14 f) {
	struct mut_arr_5 res0;
	res0 = uninitialized_mut_arr_3(ctx, size);
	
	struct opt_12* _0 = begin_ptr_7(res0);
	fill_ptr_range_2(ctx, _0, size, f);
	return res0;
}
/* uninitialized-mut-arr<a> mut-arr<opt<arr<str>>>(size nat64) */
struct mut_arr_5 uninitialized_mut_arr_3(struct ctx* ctx, uint64_t size) {
	struct opt_12* _0 = alloc_uninitialized_4(ctx, size);
	return mut_arr_8(size, _0);
}
/* mut-arr<a> mut-arr<opt<arr<str>>>(size nat64, begin-ptr mut-ptr<opt<arr<str>>>) */
struct mut_arr_5 mut_arr_8(uint64_t size, struct opt_12* begin_ptr) {
	return (struct mut_arr_5) {(struct void_) {}, (struct arr_8) {size, ((struct opt_12*) begin_ptr)}};
}
/* alloc-uninitialized<a> mut-ptr<opt<arr<str>>>(size nat64) */
struct opt_12* alloc_uninitialized_4(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(struct opt_12)));
	return ((struct opt_12*) _0);
}
/* fill-ptr-range<a> void(begin mut-ptr<opt<arr<str>>>, size nat64, f fun-act1<opt<arr<str>>, nat64>) */
struct void_ fill_ptr_range_2(struct ctx* ctx, struct opt_12* begin, uint64_t size, struct fun_act1_14 f) {
	return fill_ptr_range_recur_2(ctx, begin, 0u, size, f);
}
/* fill-ptr-range-recur<a> void(begin mut-ptr<opt<arr<str>>>, i nat64, size nat64, f fun-act1<opt<arr<str>>, nat64>) */
struct void_ fill_ptr_range_recur_2(struct ctx* ctx, struct opt_12* begin, uint64_t i, uint64_t size, struct fun_act1_14 f) {
	top:;
	uint8_t _0 = _notEqual_5(i, size);
	if (_0) {
		struct opt_12 _1 = subscript_43(ctx, f, i);
		set_subscript_8(begin, i, _1);
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
struct void_ set_subscript_8(struct opt_12* a, uint64_t n, struct opt_12 value) {
	return (*(a + n) = value, (struct void_) {});
}
/* subscript<a, nat64> opt<arr<str>>(a fun-act1<opt<arr<str>>, nat64>, p0 nat64) */
struct opt_12 subscript_43(struct ctx* ctx, struct fun_act1_14 a, uint64_t p0) {
	return call_w_ctx_632(a, ctx, p0);
}
/* call-w-ctx<opt<arr<str>>, nat-64> (generated) (generated) */
struct opt_12 call_w_ctx_632(struct fun_act1_14 a, struct ctx* ctx, uint64_t p0) {
	struct fun_act1_14 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct fill_mut_arr__lambda0* closure0 = _0.as0;
			
			return fill_mut_arr__lambda0(ctx, closure0, p0);
		}
		default:
			
	return (struct opt_12) {0};;
	}
}
/* begin-ptr<a> mut-ptr<opt<arr<str>>>(a mut-arr<opt<arr<str>>>) */
struct opt_12* begin_ptr_7(struct mut_arr_5 a) {
	return ((struct opt_12*) a.inner.begin_ptr);
}
/* fill-mut-arr<a>.lambda0 opt<arr<str>>(ignore nat64) */
struct opt_12 fill_mut_arr__lambda0(struct ctx* ctx, struct fill_mut_arr__lambda0* _closure, uint64_t ignore) {
	return _closure->value;
}
/* each<str, arr<str>> void(a dict<str, arr<str>>, f fun-act2<void, str, arr<str>>) */
struct void_ each_2(struct ctx* ctx, struct dict_0 a, struct fun_act2_4 f) {
	struct each_2__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct each_2__lambda0));
	temp0 = ((struct each_2__lambda0*) _0);
	
	*temp0 = (struct each_2__lambda0) {f};
	return fold_0(ctx, (struct void_) {}, a, (struct fun_act3_0) {0, .as0 = temp0});
}
/* fold<void, k, v> void(acc void, a dict<str, arr<str>>, f fun-act3<void, void, str, arr<str>>) */
struct void_ fold_0(struct ctx* ctx, struct void_ acc, struct dict_0 a, struct fun_act3_0 f) {
	struct iters_0* iters0;
	iters0 = init_iters_0(ctx, a);
	
	return fold_recur_0(ctx, acc, iters0->end_pairs, iters0->overlays, f);
}
/* init-iters<k, v> iters<str, arr<str>>(a dict<str, arr<str>>) */
struct iters_0* init_iters_0(struct ctx* ctx, struct dict_0 a) {
	struct mut_arr_6 overlay_iters0;
	uint64_t _0 = overlay_count_0(0u, a.impl);
	overlay_iters0 = uninitialized_mut_arr_4(ctx, _0);
	
	struct arr_10 end_pairs1;
	struct arr_9* _1 = begin_ptr_8(overlay_iters0);
	end_pairs1 = init_overlay_iters_recur__e_0(_1, a.impl);
	
	struct iters_0* temp0;
	uint8_t* _2 = alloc(ctx, sizeof(struct iters_0));
	temp0 = ((struct iters_0*) _2);
	
	*temp0 = (struct iters_0) {end_pairs1, overlay_iters0};
	return temp0;
}
/* uninitialized-mut-arr<arr<arrow<k, opt<v>>>> mut-arr<arr<arrow<str, opt<arr<str>>>>>(size nat64) */
struct mut_arr_6 uninitialized_mut_arr_4(struct ctx* ctx, uint64_t size) {
	struct arr_9* _0 = alloc_uninitialized_5(ctx, size);
	return mut_arr_9(size, _0);
}
/* mut-arr<a> mut-arr<arr<arrow<str, opt<arr<str>>>>>(size nat64, begin-ptr mut-ptr<arr<arrow<str, opt<arr<str>>>>>) */
struct mut_arr_6 mut_arr_9(uint64_t size, struct arr_9* begin_ptr) {
	return (struct mut_arr_6) {(struct void_) {}, (struct arr_11) {size, ((struct arr_9*) begin_ptr)}};
}
/* alloc-uninitialized<a> mut-ptr<arr<arrow<str, opt<arr<str>>>>>(size nat64) */
struct arr_9* alloc_uninitialized_5(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(struct arr_9)));
	return ((struct arr_9*) _0);
}
/* overlay-count<k, v> nat64(acc nat64, a dict-impl<str, arr<str>>) */
uint64_t overlay_count_0(uint64_t acc, struct dict_impl_0 a) {
	top:;
	struct dict_impl_0 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct overlay_0* o0 = _0.as0;
			
			acc = (acc + 1u);
			a = o0->prev;
			goto top;
		}
		case 1: {
			return acc;
		}
		default:
			
	return 0;;
	}
}
/* init-overlay-iters-recur!<k, v> arr<arrow<str, arr<str>>>(out mut-ptr<arr<arrow<str, opt<arr<str>>>>>, a dict-impl<str, arr<str>>) */
struct arr_10 init_overlay_iters_recur__e_0(struct arr_9* out, struct dict_impl_0 a) {
	top:;
	struct dict_impl_0 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct overlay_0* o0 = _0.as0;
			
			*out = o0->pairs;
			out = (out + 1u);
			a = o0->prev;
			goto top;
		}
		case 1: {
			struct end_node_0 e1 = _0.as1;
			
			return e1.pairs;
		}
		default:
			
	return (struct arr_10) {0, NULL};;
	}
}
/* begin-ptr<arr<arrow<k, opt<v>>>> mut-ptr<arr<arrow<str, opt<arr<str>>>>>(a mut-arr<arr<arrow<str, opt<arr<str>>>>>) */
struct arr_9* begin_ptr_8(struct mut_arr_6 a) {
	return ((struct arr_9*) a.inner.begin_ptr);
}
/* fold-recur<a, k, v> void(acc void, end-node arr<arrow<str, arr<str>>>, overlays mut-arr<arr<arrow<str, opt<arr<str>>>>>, f fun-act3<void, void, str, arr<str>>) */
struct void_ fold_recur_0(struct ctx* ctx, struct void_ acc, struct arr_10 end_node, struct mut_arr_6 overlays, struct fun_act3_0 f) {
	top:;
	uint8_t _0 = is_empty_9(overlays);
	if (_0) {
		struct fold_recur_0__lambda0* temp0;
		uint8_t* _1 = alloc(ctx, sizeof(struct fold_recur_0__lambda0));
		temp0 = ((struct fold_recur_0__lambda0*) _1);
		
		*temp0 = (struct fold_recur_0__lambda0) {f};
		return fold_1(ctx, acc, end_node, (struct fun_act2_5) {0, .as0 = temp0});
	} else {
		struct str least_key0;
		uint8_t _2 = is_empty_10(end_node);
		if (_2) {
			struct arr_9 _3 = subscript_49(ctx, overlays, 0u);
			struct arrow_1 _4 = subscript_47(ctx, _3, 0u);
			struct mut_arr_6 _5 = tail_2(ctx, overlays);
			least_key0 = find_least_key_0(ctx, _4.from, _5);
		} else {
			struct arrow_2 _6 = subscript_29(ctx, end_node, 0u);
			least_key0 = find_least_key_0(ctx, _6.from, overlays);
		}
		
		uint8_t take_from_end_node1;
		uint8_t _7 = is_empty_10(end_node);
		uint8_t _8 = _not(_7);
		if (_8) {
			struct arrow_2 _9 = subscript_29(ctx, end_node, 0u);
			take_from_end_node1 = _equal_5(least_key0, _9.from);
		} else {
			take_from_end_node1 = 0;
		}
		
		struct opt_12 val_from_end_node2;
		uint8_t _10 = take_from_end_node1;
		if (_10) {
			struct arrow_2 _11 = subscript_29(ctx, end_node, 0u);
			val_from_end_node2 = (struct opt_12) {1, .as1 = (struct some_12) {_11.to}};
		} else {
			val_from_end_node2 = (struct opt_12) {0, .as0 = (struct none) {}};
		}
		
		struct arr_10 new_end_node3;
		uint8_t _12 = take_from_end_node1;
		if (_12) {
			new_end_node3 = tail_3(ctx, end_node);
		} else {
			new_end_node3 = end_node;
		}
		
		struct took_key_0* took_from_overlays4;
		took_from_overlays4 = take_key_0(ctx, overlays, least_key0);
		
		struct void_ new_acc7;
		struct opt_12 _13 = opt_or_0(ctx, took_from_overlays4->rightmost_value, val_from_end_node2);
		switch (_13.kind) {
			case 0: {
				new_acc7 = acc;
				break;
			}
			case 1: {
				struct some_12 _matched5 = _13.as1;
				
				struct arr_2 val6;
				val6 = _matched5.value;
				
				new_acc7 = subscript_45(ctx, f, acc, least_key0, val6);
				break;
			}
			default:
				
		new_acc7 = (struct void_) {};;
		}
		
		acc = new_acc7;
		end_node = new_end_node3;
		overlays = took_from_overlays4->overlays;
		f = f;
		goto top;
	}
}
/* is-empty<arr<arrow<k, opt<v>>>> bool(a mut-arr<arr<arrow<str, opt<arr<str>>>>>) */
uint8_t is_empty_9(struct mut_arr_6 a) {
	uint64_t _0 = size_5(a);
	return (_0 == 0u);
}
/* size<a> nat64(a mut-arr<arr<arrow<str, opt<arr<str>>>>>) */
uint64_t size_5(struct mut_arr_6 a) {
	return a.inner.size;
}
/* fold<a, arrow<k, v>> void(acc void, a arr<arrow<str, arr<str>>>, f fun-act2<void, void, arrow<str, arr<str>>>) */
struct void_ fold_1(struct ctx* ctx, struct void_ acc, struct arr_10 a, struct fun_act2_5 f) {
	struct arrow_2* _0 = end_ptr_5(a);
	return fold_recur_1(ctx, acc, a.begin_ptr, _0, f);
}
/* fold-recur<a, b> void(acc void, cur const-ptr<arrow<str, arr<str>>>, end const-ptr<arrow<str, arr<str>>>, f fun-act2<void, void, arrow<str, arr<str>>>) */
struct void_ fold_recur_1(struct ctx* ctx, struct void_ acc, struct arrow_2* cur, struct arrow_2* end, struct fun_act2_5 f) {
	top:;
	uint8_t _0 = _equal_8(cur, end);
	if (_0) {
		return acc;
	} else {
		struct arrow_2 _1 = _times_11(cur);
		struct void_ _2 = subscript_44(ctx, f, acc, _1);
		struct arrow_2* _3 = _plus_9(cur, 1u);
		acc = _2;
		cur = _3;
		end = end;
		f = f;
		goto top;
	}
}
/* ==<b> bool(a const-ptr<arrow<str, arr<str>>>, b const-ptr<arrow<str, arr<str>>>) */
uint8_t _equal_8(struct arrow_2* a, struct arrow_2* b) {
	return (((struct arrow_2*) a) == ((struct arrow_2*) b));
}
/* subscript<a, a, b> void(a fun-act2<void, void, arrow<str, arr<str>>>, p0 void, p1 arrow<str, arr<str>>) */
struct void_ subscript_44(struct ctx* ctx, struct fun_act2_5 a, struct void_ p0, struct arrow_2 p1) {
	return call_w_ctx_651(a, ctx, p0, p1);
}
/* call-w-ctx<void, void, arrow<str, arr<str>>> (generated) (generated) */
struct void_ call_w_ctx_651(struct fun_act2_5 a, struct ctx* ctx, struct void_ p0, struct arrow_2 p1) {
	struct fun_act2_5 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct fold_recur_0__lambda0* closure0 = _0.as0;
			
			return fold_recur_0__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* end-ptr<b> const-ptr<arrow<str, arr<str>>>(a arr<arrow<str, arr<str>>>) */
struct arrow_2* end_ptr_5(struct arr_10 a) {
	return _plus_9(a.begin_ptr, a.size);
}
/* subscript<a, a, k, v> void(a fun-act3<void, void, str, arr<str>>, p0 void, p1 str, p2 arr<str>) */
struct void_ subscript_45(struct ctx* ctx, struct fun_act3_0 a, struct void_ p0, struct str p1, struct arr_2 p2) {
	return call_w_ctx_654(a, ctx, p0, p1, p2);
}
/* call-w-ctx<void, void, str, arr<str>> (generated) (generated) */
struct void_ call_w_ctx_654(struct fun_act3_0 a, struct ctx* ctx, struct void_ p0, struct str p1, struct arr_2 p2) {
	struct fun_act3_0 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct each_2__lambda0* closure0 = _0.as0;
			
			return each_2__lambda0(ctx, closure0, p0, p1, p2);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* fold-recur<a, k, v>.lambda0 void(cur void, pair arrow<str, arr<str>>) */
struct void_ fold_recur_0__lambda0(struct ctx* ctx, struct fold_recur_0__lambda0* _closure, struct void_ cur, struct arrow_2 pair) {
	return subscript_45(ctx, _closure->f, cur, pair.from, pair.to);
}
/* is-empty<arrow<k, v>> bool(a arr<arrow<str, arr<str>>>) */
uint8_t is_empty_10(struct arr_10 a) {
	return (a.size == 0u);
}
/* find-least-key<k, opt<v>> str(current-least-key str, overlays mut-arr<arr<arrow<str, opt<arr<str>>>>>) */
struct str find_least_key_0(struct ctx* ctx, struct str current_least_key, struct mut_arr_6 overlays) {
	return fold_2(ctx, current_least_key, overlays, (struct fun_act2_6) {0, .as0 = (struct void_) {}});
}
/* fold<k, arr<arrow<k, v>>> str(acc str, a mut-arr<arr<arrow<str, opt<arr<str>>>>>, f fun-act2<str, str, arr<arrow<str, opt<arr<str>>>>>) */
struct str fold_2(struct ctx* ctx, struct str acc, struct mut_arr_6 a, struct fun_act2_6 f) {
	struct arr_11 _0 = temp_as_arr_2(a);
	return fold_3(ctx, acc, _0, f);
}
/* fold<a, b> str(acc str, a arr<arr<arrow<str, opt<arr<str>>>>>, f fun-act2<str, str, arr<arrow<str, opt<arr<str>>>>>) */
struct str fold_3(struct ctx* ctx, struct str acc, struct arr_11 a, struct fun_act2_6 f) {
	struct arr_9* _0 = end_ptr_6(a);
	return fold_recur_2(ctx, acc, a.begin_ptr, _0, f);
}
/* fold-recur<a, b> str(acc str, cur const-ptr<arr<arrow<str, opt<arr<str>>>>>, end const-ptr<arr<arrow<str, opt<arr<str>>>>>, f fun-act2<str, str, arr<arrow<str, opt<arr<str>>>>>) */
struct str fold_recur_2(struct ctx* ctx, struct str acc, struct arr_9* cur, struct arr_9* end, struct fun_act2_6 f) {
	top:;
	uint8_t _0 = _equal_9(cur, end);
	if (_0) {
		return acc;
	} else {
		struct arr_9 _1 = _times_13(cur);
		struct str _2 = subscript_46(ctx, f, acc, _1);
		struct arr_9* _3 = _plus_11(cur, 1u);
		acc = _2;
		cur = _3;
		end = end;
		f = f;
		goto top;
	}
}
/* ==<b> bool(a const-ptr<arr<arrow<str, opt<arr<str>>>>>, b const-ptr<arr<arrow<str, opt<arr<str>>>>>) */
uint8_t _equal_9(struct arr_9* a, struct arr_9* b) {
	return (((struct arr_9*) a) == ((struct arr_9*) b));
}
/* subscript<a, a, b> str(a fun-act2<str, str, arr<arrow<str, opt<arr<str>>>>>, p0 str, p1 arr<arrow<str, opt<arr<str>>>>) */
struct str subscript_46(struct ctx* ctx, struct fun_act2_6 a, struct str p0, struct arr_9 p1) {
	return call_w_ctx_663(a, ctx, p0, p1);
}
/* call-w-ctx<str, str, arr<arrow<str, opt<arr<str>>>>> (generated) (generated) */
struct str call_w_ctx_663(struct fun_act2_6 a, struct ctx* ctx, struct str p0, struct arr_9 p1) {
	struct fun_act2_6 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return find_least_key_0__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return (struct str) {(struct arr_0) {0, NULL}};;
	}
}
/* *<b> arr<arrow<str, opt<arr<str>>>>(a const-ptr<arr<arrow<str, opt<arr<str>>>>>) */
struct arr_9 _times_13(struct arr_9* a) {
	return (*((struct arr_9*) a));
}
/* +<b> const-ptr<arr<arrow<str, opt<arr<str>>>>>(a const-ptr<arr<arrow<str, opt<arr<str>>>>>, offset nat64) */
struct arr_9* _plus_11(struct arr_9* a, uint64_t offset) {
	return ((struct arr_9*) (((struct arr_9*) a) + offset));
}
/* end-ptr<b> const-ptr<arr<arrow<str, opt<arr<str>>>>>(a arr<arr<arrow<str, opt<arr<str>>>>>) */
struct arr_9* end_ptr_6(struct arr_11 a) {
	return _plus_11(a.begin_ptr, a.size);
}
/* temp-as-arr<b> arr<arr<arrow<str, opt<arr<str>>>>>(a mut-arr<arr<arrow<str, opt<arr<str>>>>>) */
struct arr_11 temp_as_arr_2(struct mut_arr_6 a) {
	return a.inner;
}
/* min<k> str(a str, b str) */
struct str min_1(struct str a, struct str b) {
	uint8_t _0 = _less_6(a, b);
	if (_0) {
		return a;
	} else {
		return b;
	}
}
/* subscript<arrow<k, v>> arrow<str, opt<arr<str>>>(a arr<arrow<str, opt<arr<str>>>>, index nat64) */
struct arrow_1 subscript_47(struct ctx* ctx, struct arr_9 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	return unsafe_at_5(a, index);
}
/* unsafe-at<a> arrow<str, opt<arr<str>>>(a arr<arrow<str, opt<arr<str>>>>, index nat64) */
struct arrow_1 unsafe_at_5(struct arr_9 a, uint64_t index) {
	return subscript_48(a.begin_ptr, index);
}
/* subscript<a> arrow<str, opt<arr<str>>>(a const-ptr<arrow<str, opt<arr<str>>>>, n nat64) */
struct arrow_1 subscript_48(struct arrow_1* a, uint64_t n) {
	struct arrow_1* _0 = _plus_10(a, n);
	return _times_12(_0);
}
/* find-least-key<k, opt<v>>.lambda0 str(cur str, overlay arr<arrow<str, opt<arr<str>>>>) */
struct str find_least_key_0__lambda0(struct ctx* ctx, struct void_ _closure, struct str cur, struct arr_9 overlay) {
	struct arrow_1 _0 = subscript_47(ctx, overlay, 0u);
	return min_1(cur, _0.from);
}
/* subscript<arr<arrow<k, opt<v>>>> arr<arrow<str, opt<arr<str>>>>(a mut-arr<arr<arrow<str, opt<arr<str>>>>>, index nat64) */
struct arr_9 subscript_49(struct ctx* ctx, struct mut_arr_6 a, uint64_t index) {
	uint64_t _0 = size_5(a);
	uint8_t _1 = _less_0(index, _0);
	assert_0(ctx, _1);
	return unsafe_at_6(ctx, a, index);
}
/* unsafe-at<a> arr<arrow<str, opt<arr<str>>>>(a mut-arr<arr<arrow<str, opt<arr<str>>>>>, index nat64) */
struct arr_9 unsafe_at_6(struct ctx* ctx, struct mut_arr_6 a, uint64_t index) {
	struct arr_9* _0 = begin_ptr_8(a);
	return subscript_50(_0, index);
}
/* subscript<a> arr<arrow<str, opt<arr<str>>>>(a mut-ptr<arr<arrow<str, opt<arr<str>>>>>, n nat64) */
struct arr_9 subscript_50(struct arr_9* a, uint64_t n) {
	return (*(a + n));
}
/* tail<arr<arrow<k, opt<v>>>> mut-arr<arr<arrow<str, opt<arr<str>>>>>(a mut-arr<arr<arrow<str, opt<arr<str>>>>>) */
struct mut_arr_6 tail_2(struct ctx* ctx, struct mut_arr_6 a) {
	uint8_t _0 = is_empty_9(a);
	forbid(ctx, _0);
	uint64_t _1 = size_5(a);
	struct arrow_0 _2 = _arrow_0(1u, _1);
	return subscript_51(ctx, a, _2);
}
/* subscript<a> mut-arr<arr<arrow<str, opt<arr<str>>>>>(a mut-arr<arr<arrow<str, opt<arr<str>>>>>, range arrow<nat64, nat64>) */
struct mut_arr_6 subscript_51(struct ctx* ctx, struct mut_arr_6 a, struct arrow_0 range) {
	uint8_t _0 = _lessOrEqual_0(range.from, range.to);
	assert_0(ctx, _0);
	uint64_t _1 = size_5(a);
	uint8_t _2 = _lessOrEqual_0(range.to, _1);
	assert_0(ctx, _2);
	struct arr_11 _3 = subscript_52(ctx, a.inner, range);
	return (struct mut_arr_6) {(struct void_) {}, _3};
}
/* subscript<a> arr<arr<arrow<str, opt<arr<str>>>>>(a arr<arr<arrow<str, opt<arr<str>>>>>, range arrow<nat64, nat64>) */
struct arr_11 subscript_52(struct ctx* ctx, struct arr_11 a, struct arrow_0 range) {
	uint8_t _0 = _lessOrEqual_0(range.from, range.to);
	assert_0(ctx, _0);
	uint8_t _1 = _lessOrEqual_0(range.to, a.size);
	assert_0(ctx, _1);
	struct arr_9* _2 = _plus_11(a.begin_ptr, range.from);
	return (struct arr_11) {(range.to - range.from), _2};
}
/* tail<arrow<k, v>> arr<arrow<str, arr<str>>>(a arr<arrow<str, arr<str>>>) */
struct arr_10 tail_3(struct ctx* ctx, struct arr_10 a) {
	uint8_t _0 = is_empty_10(a);
	forbid(ctx, _0);
	struct arrow_0 _1 = _arrow_0(1u, a.size);
	return subscript_53(ctx, a, _1);
}
/* subscript<a> arr<arrow<str, arr<str>>>(a arr<arrow<str, arr<str>>>, range arrow<nat64, nat64>) */
struct arr_10 subscript_53(struct ctx* ctx, struct arr_10 a, struct arrow_0 range) {
	uint8_t _0 = _lessOrEqual_0(range.from, range.to);
	assert_0(ctx, _0);
	uint8_t _1 = _lessOrEqual_0(range.to, a.size);
	assert_0(ctx, _1);
	struct arrow_2* _2 = _plus_9(a.begin_ptr, range.from);
	return (struct arr_10) {(range.to - range.from), _2};
}
/* take-key<k, v> took-key<str, arr<str>>(overlays mut-arr<arr<arrow<str, opt<arr<str>>>>>, key str) */
struct took_key_0* take_key_0(struct ctx* ctx, struct mut_arr_6 overlays, struct str key) {
	return take_key_recur_0(ctx, overlays, key, 0u, (struct opt_12) {0, .as0 = (struct none) {}});
}
/* take-key-recur<k, v> took-key<str, arr<str>>(overlays mut-arr<arr<arrow<str, opt<arr<str>>>>>, key str, index nat64, rightmost-value opt<arr<str>>) */
struct took_key_0* take_key_recur_0(struct ctx* ctx, struct mut_arr_6 overlays, struct str key, uint64_t index, struct opt_12 rightmost_value) {
	top:;
	uint64_t _0 = size_5(overlays);
	uint8_t _1 = _greaterOrEqual(index, _0);
	if (_1) {
		struct took_key_0* temp0;
		uint8_t* _2 = alloc(ctx, sizeof(struct took_key_0));
		temp0 = ((struct took_key_0*) _2);
		
		*temp0 = (struct took_key_0) {rightmost_value, overlays};
		return temp0;
	} else {
		struct arr_9 _3 = subscript_49(ctx, overlays, index);
		struct arrow_1 _4 = subscript_47(ctx, _3, 0u);
		uint8_t _5 = _equal_5(_4.from, key);
		if (_5) {
			struct opt_12 new_rightmost_value0;
			struct arr_9 _6 = subscript_49(ctx, overlays, index);
			struct arrow_1 _7 = subscript_47(ctx, _6, 0u);
			new_rightmost_value0 = _7.to;
			
			struct arr_9 new_overlay1;
			struct arr_9 _8 = subscript_49(ctx, overlays, index);
			new_overlay1 = tail_4(ctx, _8);
			
			uint8_t _9 = is_empty_11(new_overlay1);
			if (_9) {
				uint64_t _10 = size_5(overlays);
				uint64_t _11 = _minus_7(ctx, _10, 1u);
				struct arr_9 _12 = subscript_49(ctx, overlays, _11);
				set_subscript_9(ctx, overlays, index, _12);
				uint64_t _13 = size_5(overlays);
				uint64_t _14 = _minus_7(ctx, _13, 1u);
				struct arrow_0 _15 = _arrow_0(0u, _14);
				struct mut_arr_6 _16 = subscript_51(ctx, overlays, _15);
				uint64_t _17 = _plus_3(ctx, index, 1u);
				overlays = _16;
				key = key;
				index = _17;
				rightmost_value = new_rightmost_value0;
				goto top;
			} else {
				set_subscript_9(ctx, overlays, index, new_overlay1);
				uint64_t _18 = _plus_3(ctx, index, 1u);
				overlays = overlays;
				key = key;
				index = _18;
				rightmost_value = new_rightmost_value0;
				goto top;
			}
		} else {
			uint64_t _19 = _plus_3(ctx, index, 1u);
			overlays = overlays;
			key = key;
			index = _19;
			rightmost_value = rightmost_value;
			goto top;
		}
	}
}
/* tail<arrow<k, opt<v>>> arr<arrow<str, opt<arr<str>>>>(a arr<arrow<str, opt<arr<str>>>>) */
struct arr_9 tail_4(struct ctx* ctx, struct arr_9 a) {
	uint8_t _0 = is_empty_11(a);
	forbid(ctx, _0);
	struct arrow_0 _1 = _arrow_0(1u, a.size);
	return subscript_36(ctx, a, _1);
}
/* is-empty<a> bool(a arr<arrow<str, opt<arr<str>>>>) */
uint8_t is_empty_11(struct arr_9 a) {
	return (a.size == 0u);
}
/* set-subscript<arr<arrow<k, opt<v>>>> void(a mut-arr<arr<arrow<str, opt<arr<str>>>>>, index nat64, value arr<arrow<str, opt<arr<str>>>>) */
struct void_ set_subscript_9(struct ctx* ctx, struct mut_arr_6 a, uint64_t index, struct arr_9 value) {
	uint64_t _0 = size_5(a);
	uint8_t _1 = _less_0(index, _0);
	assert_0(ctx, _1);
	return unsafe_set_at__e_0(ctx, a, index, value);
}
/* unsafe-set-at!<a> void(a mut-arr<arr<arrow<str, opt<arr<str>>>>>, index nat64, value arr<arrow<str, opt<arr<str>>>>) */
struct void_ unsafe_set_at__e_0(struct ctx* ctx, struct mut_arr_6 a, uint64_t index, struct arr_9 value) {
	struct arr_9* _0 = begin_ptr_8(a);
	return set_subscript_10(_0, index, value);
}
/* set-subscript<a> void(a mut-ptr<arr<arrow<str, opt<arr<str>>>>>, n nat64, value arr<arrow<str, opt<arr<str>>>>) */
struct void_ set_subscript_10(struct arr_9* a, uint64_t n, struct arr_9 value) {
	return (*(a + n) = value, (struct void_) {});
}
/* opt-or<v> opt<arr<str>>(a opt<arr<str>>, b opt<arr<str>>) */
struct opt_12 opt_or_0(struct ctx* ctx, struct opt_12 a, struct opt_12 b) {
	uint8_t _0 = is_empty_7(a);
	if (_0) {
		return b;
	} else {
		return a;
	}
}
/* subscript<void, k, v> void(a fun-act2<void, str, arr<str>>, p0 str, p1 arr<str>) */
struct void_ subscript_54(struct ctx* ctx, struct fun_act2_4 a, struct str p0, struct arr_2 p1) {
	return call_w_ctx_690(a, ctx, p0, p1);
}
/* call-w-ctx<void, str, arr<str>> (generated) (generated) */
struct void_ call_w_ctx_690(struct fun_act2_4 a, struct ctx* ctx, struct str p0, struct arr_2 p1) {
	struct fun_act2_4 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct parse_named_args_0__lambda0* closure0 = _0.as0;
			
			return parse_named_args_0__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* each<str, arr<str>>.lambda0 void(ignore void, k str, v arr<str>) */
struct void_ each_2__lambda0(struct ctx* ctx, struct each_2__lambda0* _closure, struct void_ ignore, struct str k, struct arr_2 v) {
	return subscript_54(ctx, _closure->f, k, v);
}
/* index-of<str> opt<nat64>(a arr<str>, value str) */
struct opt_11 index_of(struct ctx* ctx, struct arr_2 a, struct str value) {
	struct opt_17 _0 = ptr_of(ctx, a, value);
	switch (_0.kind) {
		case 0: {
			return (struct opt_11) {0, .as0 = (struct none) {}};
		}
		case 1: {
			struct some_17 _matched0 = _0.as1;
			
			struct str* v1;
			v1 = _matched0.value;
			
			uint64_t _1 = _minus_9(v1, a.begin_ptr);
			return (struct opt_11) {1, .as1 = (struct some_11) {_1}};
		}
		default:
			
	return (struct opt_11) {0};;
	}
}
/* ptr-of<a> opt<const-ptr<str>>(a arr<str>, value str) */
struct opt_17 ptr_of(struct ctx* ctx, struct arr_2 a, struct str value) {
	struct str* _0 = end_ptr_7(a);
	return ptr_of_recur(ctx, a.begin_ptr, _0, value);
}
/* ptr-of-recur<a> opt<const-ptr<str>>(cur const-ptr<str>, end const-ptr<str>, value str) */
struct opt_17 ptr_of_recur(struct ctx* ctx, struct str* cur, struct str* end, struct str value) {
	top:;
	uint8_t _0 = _equal_10(cur, end);
	if (_0) {
		return (struct opt_17) {0, .as0 = (struct none) {}};
	} else {
		struct str _1 = _times_10(cur);
		uint8_t _2 = _equal_5(_1, value);
		if (_2) {
			return (struct opt_17) {1, .as1 = (struct some_17) {cur}};
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
uint8_t _equal_10(struct str* a, struct str* b) {
	return (((struct str*) a) == ((struct str*) b));
}
/* end-ptr<a> const-ptr<str>(a arr<str>) */
struct str* end_ptr_7(struct arr_2 a) {
	return _plus_8(a.begin_ptr, a.size);
}
/* -<a> nat64(a const-ptr<str>, b const-ptr<str>) */
uint64_t _minus_9(struct str* a, struct str* b) {
	return _minus_10(((struct str*) a), ((struct str*) b));
}
/* -<a> nat64(a mut-ptr<str>, b mut-ptr<str>) */
uint64_t _minus_10(struct str* a, struct str* b) {
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
	struct mut_list_1* _0 = mut_list_0(ctx);
	return (struct interp) {_0};
}
/* subscript<opt<arr<str>>> opt<arr<str>>(a mut-list<opt<arr<str>>>, index nat64) */
struct opt_12 subscript_55(struct ctx* ctx, struct mut_list_3* a, uint64_t index) {
	uint8_t _0 = _less_0(index, a->size);
	assert_0(ctx, _0);
	struct opt_12* _1 = begin_ptr_9(a);
	return subscript_56(_1, index);
}
/* subscript<a> opt<arr<str>>(a mut-ptr<opt<arr<str>>>, n nat64) */
struct opt_12 subscript_56(struct opt_12* a, uint64_t n) {
	return (*(a + n));
}
/* begin-ptr<a> mut-ptr<opt<arr<str>>>(a mut-list<opt<arr<str>>>) */
struct opt_12* begin_ptr_9(struct mut_list_3* a) {
	return begin_ptr_7(a->backing);
}
/* set-subscript<opt<arr<str>>> void(a mut-list<opt<arr<str>>>, index nat64, value opt<arr<str>>) */
struct void_ set_subscript_11(struct ctx* ctx, struct mut_list_3* a, uint64_t index, struct opt_12 value) {
	uint8_t _0 = _less_0(index, a->size);
	assert_0(ctx, _0);
	struct opt_12* _1 = begin_ptr_9(a);
	return set_subscript_8(_1, index, value);
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
			
			struct opt_12 _6 = subscript_55(ctx, _closure->values, index1);
			uint8_t _7 = is_empty_7(_6);
			assert_0(ctx, _7);
			return set_subscript_11(ctx, _closure->values, index1, (struct opt_12) {1, .as1 = (struct some_12) {value}});
		}
		default:
			
	return (struct void_) {};;
	}
}
/* *<bool> bool(a cell<bool>) */
uint8_t _times_14(struct cell_3* a) {
	return a->inner_value;
}
/* move-to-arr!<opt<arr<str>>> arr<opt<arr<str>>>(a mut-list<opt<arr<str>>>) */
struct arr_8 move_to_arr__e_2(struct mut_list_3* a) {
	struct mut_arr_5 _0 = move_to_mut_arr__e_1(a);
	return cast_immutable_2(_0);
}
/* cast-immutable<a> arr<opt<arr<str>>>(a mut-arr<opt<arr<str>>>) */
struct arr_8 cast_immutable_2(struct mut_arr_5 a) {
	return a.inner;
}
/* move-to-mut-arr!<a> mut-arr<opt<arr<str>>>(a mut-list<opt<arr<str>>>) */
struct mut_arr_5 move_to_mut_arr__e_1(struct mut_list_3* a) {
	struct mut_arr_5 res0;
	struct opt_12* _0 = begin_ptr_9(a);
	res0 = mut_arr_8(a->size, _0);
	
	struct mut_arr_5 _1 = mut_arr_10();
	a->backing = _1;
	a->size = 0u;
	return res0;
}
/* mut-arr<a> mut-arr<opt<arr<str>>>() */
struct mut_arr_5 mut_arr_10(void) {
	return (struct mut_arr_5) {(struct void_) {}, (struct arr_8) {0u, NULL}};
}
/* print-help void() */
struct void_ print_help(struct ctx* ctx) {
	print((struct str) {{18, constantarr_0_20}});
	print((struct str) {{8, constantarr_0_21}});
	print((struct str) {{36, constantarr_0_22}});
	return print((struct str) {{63, constantarr_0_23}});
}
/* subscript<opt<arr<str>>> opt<arr<str>>(a arr<opt<arr<str>>>, index nat64) */
struct opt_12 subscript_57(struct ctx* ctx, struct arr_8 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	return unsafe_at_7(a, index);
}
/* unsafe-at<a> opt<arr<str>>(a arr<opt<arr<str>>>, index nat64) */
struct opt_12 unsafe_at_7(struct arr_8 a, uint64_t index) {
	return subscript_58(a.begin_ptr, index);
}
/* subscript<a> opt<arr<str>>(a const-ptr<opt<arr<str>>>, n nat64) */
struct opt_12 subscript_58(struct opt_12* a, uint64_t n) {
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
/* force<nat64> nat64(a opt<nat64>) */
uint64_t force_4(struct ctx* ctx, struct opt_11 a) {
	return force_5(ctx, a, (struct str) {{27, constantarr_0_15}});
}
/* force<a> nat64(a opt<nat64>, message str) */
uint64_t force_5(struct ctx* ctx, struct opt_11 a, struct str message) {
	struct opt_11 _0 = a;
	switch (_0.kind) {
		case 0: {
			return throw_8(ctx, message);
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
/* throw<a> nat64(message str) */
uint64_t throw_8(struct ctx* ctx, struct str message) {
	struct backtrace _0 = get_backtrace(ctx);
	return throw_9(ctx, (struct exception) {message, _0});
}
/* throw<a> nat64(e exception) */
uint64_t throw_9(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx0;
	exn_ctx0 = get_exception_ctx(ctx);
	
	uint8_t _0 = _notEqual_3(exn_ctx0->jmp_buf_ptr, NULL);
	hard_assert(_0);
	exn_ctx0->thrown_exception = e;
	int32_t _1 = number_to_throw(ctx);
	(longjmp(exn_ctx0->jmp_buf_ptr, _1), (struct void_) {});
	return hard_unreachable_5();
}
/* hard-unreachable<a> nat64() */
uint64_t hard_unreachable_5(void) {
	(abort(), (struct void_) {});
	return 0;
}
/* parse-nat opt<nat64>(a str) */
struct opt_11 parse_nat(struct ctx* ctx, struct str a) {
	return with_reader(ctx, a, (struct fun_act1_15) {0, .as0 = (struct void_) {}});
}
/* with-reader<nat64> opt<nat64>(a str, f fun-act1<opt<nat64>, reader>) */
struct opt_11 with_reader(struct ctx* ctx, struct str a, struct fun_act1_15 f) {
	struct reader* reader0;
	reader0 = reader(ctx, a);
	
	struct opt_11 res1;
	res1 = subscript_59(ctx, f, reader0);
	
	uint8_t _0 = is_empty_12(res1);
	uint8_t _1 = _not(_0);uint8_t _2;
	
	if (_1) {
		_2 = is_empty_13(ctx, reader0);
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
struct opt_11 subscript_59(struct ctx* ctx, struct fun_act1_15 a, struct reader* p0) {
	return call_w_ctx_730(a, ctx, p0);
}
/* call-w-ctx<opt<nat64>, gc-ptr(reader)> (generated) (generated) */
struct opt_11 call_w_ctx_730(struct fun_act1_15 a, struct ctx* ctx, struct reader* p0) {
	struct fun_act1_15 _0 = a;
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
uint8_t is_empty_12(struct opt_11 a) {
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
uint8_t is_empty_13(struct ctx* ctx, struct reader* a) {
	uint8_t _0 = _lessOrEqual_1(a->cur, a->end);
	assert_0(ctx, _0);
	return _equal_0(a->cur, a->end);
}
/* take-nat! opt<nat64>(a reader) */
struct opt_11 take_nat__e(struct ctx* ctx, struct reader* a) {
	uint8_t _0 = is_empty_13(ctx, a);
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
				drop_2(_4);
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
	uint8_t _0 = is_empty_13(ctx, a);
	forbid(ctx, _0);
	return _times_0(a->cur);
}
/* drop<char> void(_ char) */
struct void_ drop_2(char _p0) {
	return (struct void_) {};
}
/* next! char(a reader) */
char next__e(struct ctx* ctx, struct reader* a) {
	uint8_t _0 = is_empty_13(ctx, a);
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
	uint8_t _0 = is_empty_13(ctx, a);
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
				drop_2(_3);
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
			
			struct arrow_0 _1 = _arrow_0(0u, index1);
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
	return find_rindex(ctx, a, (struct fun_act1_16) {0, .as0 = temp0});
}
/* find-rindex<a> opt<nat64>(a arr<char>, f fun-act1<bool, char>) */
struct opt_11 find_rindex(struct ctx* ctx, struct arr_0 a, struct fun_act1_16 f) {
	uint8_t _0 = is_empty_1(a);
	uint8_t _1 = _not(_0);
	if (_1) {
		uint64_t _2 = _minus_7(ctx, a.size, 1u);
		return find_rindex_recur(ctx, a, _2, f);
	} else {
		return (struct opt_11) {0, .as0 = (struct none) {}};
	}
}
/* find-rindex-recur<a> opt<nat64>(a arr<char>, index nat64, f fun-act1<bool, char>) */
struct opt_11 find_rindex_recur(struct ctx* ctx, struct arr_0 a, uint64_t index, struct fun_act1_16 f) {
	top:;
	char _0 = subscript_61(ctx, a, index);
	uint8_t _1 = subscript_60(ctx, f, _0);
	if (_1) {
		return (struct opt_11) {1, .as1 = (struct some_11) {index}};
	} else {
		uint8_t _2 = _notEqual_5(index, 0u);
		if (_2) {
			uint64_t _3 = _minus_7(ctx, index, 1u);
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
uint8_t subscript_60(struct ctx* ctx, struct fun_act1_16 a, char p0) {
	return call_w_ctx_746(a, ctx, p0);
}
/* call-w-ctx<bool, char> (generated) (generated) */
uint8_t call_w_ctx_746(struct fun_act1_16 a, struct ctx* ctx, char p0) {
	struct fun_act1_16 _0 = a;
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
char subscript_61(struct ctx* ctx, struct arr_0 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	return unsafe_at_8(a, index);
}
/* unsafe-at<a> char(a arr<char>, index nat64) */
char unsafe_at_8(struct arr_0 a, uint64_t index) {
	return subscript_62(a.begin_ptr, index);
}
/* subscript<a> char(a const-ptr<char>, n nat64) */
char subscript_62(char* a, uint64_t n) {
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
	
	struct mut_list_4* _1 = mut_list_2(ctx);
	*temp0 = (struct mut_dict_1) {_1, 0u, (struct opt_18) {0, .as0 = (struct none) {}}};
	return temp0;
}
/* mut-list<arrow<k, opt<v>>> mut-list<arrow<str, opt<str>>>() */
struct mut_list_4* mut_list_2(struct ctx* ctx) {
	struct mut_list_4* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_list_4));
	temp0 = ((struct mut_list_4*) _0);
	
	struct mut_arr_7 _1 = mut_arr_11();
	*temp0 = (struct mut_list_4) {_1, 0u};
	return temp0;
}
/* mut-arr<a> mut-arr<arrow<str, opt<str>>>() */
struct mut_arr_7 mut_arr_11(void) {
	return (struct mut_arr_7) {(struct void_) {}, (struct arr_12) {0u, NULL}};
}
/* get-environ-recur void(env const-ptr<const-ptr<char>>, res mut-dict<str, str>) */
struct void_ get_environ_recur(struct ctx* ctx, char** env, struct mut_dict_1* res) {
	top:;
	char* _0 = _times_6(env);
	char* _1 = null_1();
	uint8_t _2 = _notEqual_2(_0, _1);
	if (_2) {
		struct arrow_4 entry0;
		char* _3 = _times_6(env);
		entry0 = parse_environ_entry(ctx, _3);
		
		set_subscript_12(ctx, res, entry0.from, entry0.to);
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
struct arrow_4 parse_environ_entry(struct ctx* ctx, char* entry) {
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
			struct arr_0 _1 = arr_from_begin_end_0(entry, key_end1);
			key2 = (struct str) {_1};
			
			char* value_begin3;
			value_begin3 = _plus_0(key_end1, 1u);
			
			char* value_end4;
			value_end4 = find_cstr_end(value_begin3);
			
			struct str value5;
			struct arr_0 _2 = arr_from_begin_end_0(value_begin3, value_end4);
			value5 = (struct str) {_2};
			
			return _arrow_3(key2, value5);
		}
		default:
			
	return (struct arrow_4) {(struct str) {(struct arr_0) {0, NULL}}, (struct str) {(struct arr_0) {0, NULL}}};;
	}
}
/* todo<arrow<str, str>> arrow<str, str>() */
struct arrow_4 todo_3(void) {
	(abort(), (struct void_) {});
	return (struct arrow_4) {(struct str) {(struct arr_0) {0, NULL}}, (struct str) {(struct arr_0) {0, NULL}}};
}
/* -><str, str> arrow<str, str>(from str, to str) */
struct arrow_4 _arrow_3(struct str from, struct str to) {
	return (struct arrow_4) {from, to};
}
/* set-subscript<str, str> void(a mut-dict<str, str>, key str, value str) */
struct void_ set_subscript_12(struct ctx* ctx, struct mut_dict_1* a, struct str key, struct str value) {
	uint8_t _0 = insert_into_key_match_or_empty_slot__e_1(ctx, a, key, value);
	uint8_t _1 = _not(_0);
	if (_1) {
		return add_pair__e_1(ctx, a, key, value);
	} else {
		return (struct void_) {};
	}
}
/* insert-into-key-match-or-empty-slot!<k, v> bool(a mut-dict<str, str>, key str, value str) */
uint8_t insert_into_key_match_or_empty_slot__e_1(struct ctx* ctx, struct mut_dict_1* a, struct str key, struct str value) {
	struct arrow_3* insert_ptr0;
	insert_ptr0 = find_insert_ptr_1(ctx, a, key);
	
	uint8_t can_insert1;
	struct arrow_3* _0 = end_ptr_9(a->pairs);
	can_insert1 = _notEqual_11(insert_ptr0, _0);
	uint8_t _1;
	
	if (can_insert1) {
		_1 = _equal_5((*insert_ptr0).from, key);
	} else {
		_1 = 0;
	}
	if (_1) {
		uint8_t _2 = is_empty_14((*insert_ptr0).to);
		if (_2) {
			uint64_t _3 = _plus_3(ctx, a->node_size, 1u);
			a->node_size = _3;
		} else {
			(struct void_) {};
		}
		struct arrow_3 _4 = _arrow_4(key, (struct opt_15) {1, .as1 = (struct some_15) {value}});
		*insert_ptr0 = _4;
		return 1;
	} else {
		uint8_t inserted4;
		struct opt_18 _5 = a->next;
		switch (_5.kind) {
			case 0: {
				inserted4 = 0;
				break;
			}
			case 1: {
				struct some_18 _matched2 = _5.as1;
				
				struct mut_dict_1* next3;
				next3 = _matched2.value;
				
				inserted4 = insert_into_key_match_or_empty_slot__e_1(ctx, next3, key, value);
				break;
			}
			default:
				
		inserted4 = 0;;
		}
		
		uint8_t _6 = inserted4;
		if (_6) {
			return 1;
		} else {uint8_t _7;
			
			if (can_insert1) {
				_7 = is_empty_14((*insert_ptr0).to);
			} else {
				_7 = 0;
			}
			if (_7) {
				uint8_t _8 = _less_6(key, (*insert_ptr0).from);
				assert_0(ctx, _8);
				uint64_t _9 = _plus_3(ctx, a->node_size, 1u);
				a->node_size = _9;
				struct arrow_3 _10 = _arrow_4(key, (struct opt_15) {1, .as1 = (struct some_15) {value}});
				*insert_ptr0 = _10;
				return 1;
			} else {uint8_t _11;
				
				if (can_insert1) {
					struct arrow_3* _12 = begin_ptr_11(a->pairs);
					_11 = _notEqual_11(insert_ptr0, _12);
				} else {
					_11 = 0;
				}uint8_t _13;
				
				if (_11) {
					_13 = is_empty_14((*(insert_ptr0 - 1u)).to);
				} else {
					_13 = 0;
				}
				if (_13) {
					uint8_t _14 = _less_6(key, (*insert_ptr0).from);
					assert_0(ctx, _14);
					uint64_t _15 = _plus_3(ctx, a->node_size, 1u);
					a->node_size = _15;
					struct arrow_3 _16 = _arrow_4(key, (struct opt_15) {1, .as1 = (struct some_15) {value}});
					*(insert_ptr0 - 1u) = _16;
					return 1;
				} else {
					return 0;
				}
			}
		}
	}
}
/* find-insert-ptr<k, v> mut-ptr<arrow<str, opt<str>>>(a mut-dict<str, str>, key str) */
struct arrow_3* find_insert_ptr_1(struct ctx* ctx, struct mut_dict_1* a, struct str key) {
	struct find_insert_ptr_1__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct find_insert_ptr_1__lambda0));
	temp0 = ((struct find_insert_ptr_1__lambda0*) _0);
	
	*temp0 = (struct find_insert_ptr_1__lambda0) {key};
	return binary_search_insert_ptr_2(ctx, a->pairs, (struct fun_act1_17) {0, .as0 = temp0});
}
/* binary-search-insert-ptr<arrow<k, opt<v>>> mut-ptr<arrow<str, opt<str>>>(a mut-list<arrow<str, opt<str>>>, compare fun-act1<comparison, arrow<str, opt<str>>>) */
struct arrow_3* binary_search_insert_ptr_2(struct ctx* ctx, struct mut_list_4* a, struct fun_act1_17 compare) {
	struct mut_arr_7 _0 = temp_as_mut_arr_2(a);
	return binary_search_insert_ptr_3(ctx, _0, compare);
}
/* binary-search-insert-ptr<a> mut-ptr<arrow<str, opt<str>>>(a mut-arr<arrow<str, opt<str>>>, compare fun-act1<comparison, arrow<str, opt<str>>>) */
struct arrow_3* binary_search_insert_ptr_3(struct ctx* ctx, struct mut_arr_7 a, struct fun_act1_17 compare) {
	struct arrow_3* _0 = begin_ptr_10(a);
	struct arrow_3* _1 = end_ptr_8(a);
	struct arrow_3* _2 = binary_search_compare_recur_1(ctx, ((struct arrow_3*) _0), ((struct arrow_3*) _1), compare);
	return ((struct arrow_3*) _2);
}
/* binary-search-compare-recur<a> const-ptr<arrow<str, opt<str>>>(left const-ptr<arrow<str, opt<str>>>, right const-ptr<arrow<str, opt<str>>>, compare fun-act1<comparison, arrow<str, opt<str>>>) */
struct arrow_3* binary_search_compare_recur_1(struct ctx* ctx, struct arrow_3* left, struct arrow_3* right, struct fun_act1_17 compare) {
	top:;
	uint8_t _0 = _equal_11(left, right);
	if (_0) {
		return left;
	} else {
		struct arrow_3* mid0;
		uint64_t _1 = _minus_11(right, left);
		mid0 = _plus_13(left, (_1 / 2u));
		
		struct arrow_3 _2 = _times_16(mid0);
		struct comparison _3 = subscript_63(ctx, compare, _2);
		switch (_3.kind) {
			case 0: {
				left = left;
				right = mid0;
				compare = compare;
				goto top;
			}
			case 1: {
				return mid0;
			}
			case 2: {
				struct arrow_3* _4 = _plus_13(mid0, 1u);
				left = _4;
				right = right;
				compare = compare;
				goto top;
			}
			default:
				
		return NULL;;
		}
	}
}
/* ==<a> bool(a const-ptr<arrow<str, opt<str>>>, b const-ptr<arrow<str, opt<str>>>) */
uint8_t _equal_11(struct arrow_3* a, struct arrow_3* b) {
	return (((struct arrow_3*) a) == ((struct arrow_3*) b));
}
/* +<a> const-ptr<arrow<str, opt<str>>>(a const-ptr<arrow<str, opt<str>>>, offset nat64) */
struct arrow_3* _plus_13(struct arrow_3* a, uint64_t offset) {
	return ((struct arrow_3*) (((struct arrow_3*) a) + offset));
}
/* -<a> nat64(a const-ptr<arrow<str, opt<str>>>, b const-ptr<arrow<str, opt<str>>>) */
uint64_t _minus_11(struct arrow_3* a, struct arrow_3* b) {
	return _minus_12(((struct arrow_3*) a), ((struct arrow_3*) b));
}
/* -<a> nat64(a mut-ptr<arrow<str, opt<str>>>, b mut-ptr<arrow<str, opt<str>>>) */
uint64_t _minus_12(struct arrow_3* a, struct arrow_3* b) {
	return ((((uint64_t) a) - ((uint64_t) b)) / sizeof(struct arrow_3));
}
/* subscript<comparison, a> comparison(a fun-act1<comparison, arrow<str, opt<str>>>, p0 arrow<str, opt<str>>) */
struct comparison subscript_63(struct ctx* ctx, struct fun_act1_17 a, struct arrow_3 p0) {
	return call_w_ctx_772(a, ctx, p0);
}
/* call-w-ctx<comparison, arrow<str, opt<str>>> (generated) (generated) */
struct comparison call_w_ctx_772(struct fun_act1_17 a, struct ctx* ctx, struct arrow_3 p0) {
	struct fun_act1_17 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct find_insert_ptr_1__lambda0* closure0 = _0.as0;
			
			return find_insert_ptr_1__lambda0(ctx, closure0, p0);
		}
		default:
			
	return (struct comparison) {0};;
	}
}
/* *<a> arrow<str, opt<str>>(a const-ptr<arrow<str, opt<str>>>) */
struct arrow_3 _times_16(struct arrow_3* a) {
	return (*((struct arrow_3*) a));
}
/* begin-ptr<a> mut-ptr<arrow<str, opt<str>>>(a mut-arr<arrow<str, opt<str>>>) */
struct arrow_3* begin_ptr_10(struct mut_arr_7 a) {
	return ((struct arrow_3*) a.inner.begin_ptr);
}
/* end-ptr<a> mut-ptr<arrow<str, opt<str>>>(a mut-arr<arrow<str, opt<str>>>) */
struct arrow_3* end_ptr_8(struct mut_arr_7 a) {
	struct arrow_3* _0 = begin_ptr_10(a);
	uint64_t _1 = size_6(a);
	return (_0 + _1);
}
/* size<a> nat64(a mut-arr<arrow<str, opt<str>>>) */
uint64_t size_6(struct mut_arr_7 a) {
	return a.inner.size;
}
/* temp-as-mut-arr<a> mut-arr<arrow<str, opt<str>>>(a mut-list<arrow<str, opt<str>>>) */
struct mut_arr_7 temp_as_mut_arr_2(struct mut_list_4* a) {
	struct arrow_3* _0 = begin_ptr_11(a);
	return mut_arr_12(a->size, _0);
}
/* mut-arr<a> mut-arr<arrow<str, opt<str>>>(size nat64, begin-ptr mut-ptr<arrow<str, opt<str>>>) */
struct mut_arr_7 mut_arr_12(uint64_t size, struct arrow_3* begin_ptr) {
	return (struct mut_arr_7) {(struct void_) {}, (struct arr_12) {size, ((struct arrow_3*) begin_ptr)}};
}
/* begin-ptr<a> mut-ptr<arrow<str, opt<str>>>(a mut-list<arrow<str, opt<str>>>) */
struct arrow_3* begin_ptr_11(struct mut_list_4* a) {
	return begin_ptr_10(a->backing);
}
/* find-insert-ptr<k, v>.lambda0 comparison(pair arrow<str, opt<str>>) */
struct comparison find_insert_ptr_1__lambda0(struct ctx* ctx, struct find_insert_ptr_1__lambda0* _closure, struct arrow_3 pair) {
	return _compare_8(_closure->key, pair.from);
}
/* !=<mut-ptr<arrow<k, opt<v>>>> bool(a mut-ptr<arrow<str, opt<str>>>, b mut-ptr<arrow<str, opt<str>>>) */
uint8_t _notEqual_11(struct arrow_3* a, struct arrow_3* b) {
	return _not((a == b));
}
/* end-ptr<arrow<k, opt<v>>> mut-ptr<arrow<str, opt<str>>>(a mut-list<arrow<str, opt<str>>>) */
struct arrow_3* end_ptr_9(struct mut_list_4* a) {
	struct arrow_3* _0 = begin_ptr_11(a);
	return (_0 + a->size);
}
/* is-empty<v> bool(a opt<str>) */
uint8_t is_empty_14(struct opt_15 a) {
	struct opt_15 _0 = a;
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
/* -><k, opt<v>> arrow<str, opt<str>>(from str, to opt<str>) */
struct arrow_3 _arrow_4(struct str from, struct opt_15 to) {
	return (struct arrow_3) {from, to};
}
/* add-pair!<k, v> void(a mut-dict<str, str>, key str, value str) */
struct void_ add_pair__e_1(struct ctx* ctx, struct mut_dict_1* a, struct str key, struct str value) {
	uint8_t _0 = _less_0(a->node_size, 4u);
	if (_0) {
		uint8_t _1 = is_empty_15(a->pairs);
		if (_1) {
			struct arrow_3 _2 = _arrow_4(key, (struct opt_15) {1, .as1 = (struct some_15) {value}});
			_concatEquals_5(ctx, a->pairs, _2);
		} else {
			insert_linear__e_1(ctx, a->pairs, 0u, key, value);
		}
		uint64_t _3 = _plus_3(ctx, a->node_size, 1u);
		return (a->node_size = _3, (struct void_) {});
	} else {
		uint64_t _4 = _minus_7(ctx, a->pairs->size, 4u);
		struct arrow_3 _5 = subscript_66(ctx, a->pairs, _4);
		uint8_t _6 = _greater_1(key, _5.from);
		if (_6) {
			uint64_t _7 = _minus_7(ctx, a->pairs->size, 4u);
			insert_linear__e_1(ctx, a->pairs, _7, key, value);
			uint64_t _8 = _plus_3(ctx, a->node_size, 1u);
			return (a->node_size = _8, (struct void_) {});
		} else {
			struct opt_18 _9 = a->next;
			switch (_9.kind) {
				case 0: {
					struct mut_list_4* new_pairs0;
					new_pairs0 = mut_list_2(ctx);
					
					struct arrow_3 _10 = _arrow_4(key, (struct opt_15) {1, .as1 = (struct some_15) {value}});
					_concatEquals_5(ctx, new_pairs0, _10);
					struct mut_dict_1* temp0;
					uint8_t* _11 = alloc(ctx, sizeof(struct mut_dict_1));
					temp0 = ((struct mut_dict_1*) _11);
					
					*temp0 = (struct mut_dict_1) {new_pairs0, 1u, (struct opt_18) {0, .as0 = (struct none) {}}};
					return (a->next = (struct opt_18) {1, .as1 = (struct some_18) {temp0}}, (struct void_) {});
				}
				case 1: {
					struct some_18 _matched1 = _9.as1;
					
					struct mut_dict_1* next2;
					next2 = _matched1.value;
					
					add_pair__e_1(ctx, next2, key, value);
					return compact_if_needed__e_1(ctx, a);
				}
				default:
					
			return (struct void_) {};;
			}
		}
	}
}
/* is-empty<arrow<k, opt<v>>> bool(a mut-list<arrow<str, opt<str>>>) */
uint8_t is_empty_15(struct mut_list_4* a) {
	return (a->size == 0u);
}
/* ~=<arrow<k, opt<v>>> void(a mut-list<arrow<str, opt<str>>>, value arrow<str, opt<str>>) */
struct void_ _concatEquals_5(struct ctx* ctx, struct mut_list_4* a, struct arrow_3 value) {
	incr_capacity__e_2(ctx, a);
	uint64_t _0 = capacity_3(a);
	uint8_t _1 = _less_0(a->size, _0);
	assert_0(ctx, _1);
	struct arrow_3* _2 = begin_ptr_11(a);
	set_subscript_13(_2, a->size, value);
	uint64_t _3 = _plus_3(ctx, a->size, 1u);
	return (a->size = _3, (struct void_) {});
}
/* incr-capacity!<a> void(a mut-list<arrow<str, opt<str>>>) */
struct void_ incr_capacity__e_2(struct ctx* ctx, struct mut_list_4* a) {
	uint64_t _0 = _plus_3(ctx, a->size, 1u);
	uint64_t _1 = round_up_to_power_of_two(ctx, _0);
	return ensure_capacity_2(ctx, a, _1);
}
/* ensure-capacity<a> void(a mut-list<arrow<str, opt<str>>>, min-capacity nat64) */
struct void_ ensure_capacity_2(struct ctx* ctx, struct mut_list_4* a, uint64_t min_capacity) {
	uint64_t _0 = capacity_3(a);
	uint8_t _1 = _less_0(_0, min_capacity);
	if (_1) {
		return increase_capacity_to__e_2(ctx, a, min_capacity);
	} else {
		return (struct void_) {};
	}
}
/* capacity<a> nat64(a mut-list<arrow<str, opt<str>>>) */
uint64_t capacity_3(struct mut_list_4* a) {
	return size_6(a->backing);
}
/* increase-capacity-to!<a> void(a mut-list<arrow<str, opt<str>>>, new-capacity nat64) */
struct void_ increase_capacity_to__e_2(struct ctx* ctx, struct mut_list_4* a, uint64_t new_capacity) {
	uint64_t _0 = capacity_3(a);
	uint8_t _1 = _greater_0(new_capacity, _0);
	assert_0(ctx, _1);
	struct arrow_3* old_begin0;
	old_begin0 = begin_ptr_11(a);
	
	struct mut_arr_7 _2 = uninitialized_mut_arr_5(ctx, new_capacity);
	a->backing = _2;
	struct arrow_3* _3 = begin_ptr_11(a);
	copy_data_from__e_3(ctx, _3, ((struct arrow_3*) old_begin0), a->size);
	uint64_t _4 = _plus_3(ctx, a->size, 1u);
	uint64_t _5 = size_6(a->backing);
	struct arrow_0 _6 = _arrow_0(_4, _5);
	struct mut_arr_7 _7 = subscript_64(ctx, a->backing, _6);
	return set_zero_elements_2(_7);
}
/* uninitialized-mut-arr<a> mut-arr<arrow<str, opt<str>>>(size nat64) */
struct mut_arr_7 uninitialized_mut_arr_5(struct ctx* ctx, uint64_t size) {
	struct arrow_3* _0 = alloc_uninitialized_6(ctx, size);
	return mut_arr_12(size, _0);
}
/* alloc-uninitialized<a> mut-ptr<arrow<str, opt<str>>>(size nat64) */
struct arrow_3* alloc_uninitialized_6(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(struct arrow_3)));
	return ((struct arrow_3*) _0);
}
/* copy-data-from!<a> void(to mut-ptr<arrow<str, opt<str>>>, from const-ptr<arrow<str, opt<str>>>, len nat64) */
struct void_ copy_data_from__e_3(struct ctx* ctx, struct arrow_3* to, struct arrow_3* from, uint64_t len) {
	uint8_t* _0 = as_any_const_ptr_3(from);
	uint8_t* _1 = memcpy(((uint8_t*) to), _0, (len * sizeof(struct arrow_3)));
	return drop_0(_1);
}
/* as-any-const-ptr<const-ptr<a>> const-ptr<nat8>(ref const-ptr<arrow<str, opt<str>>>) */
uint8_t* as_any_const_ptr_3(struct arrow_3* ref) {
	return ((uint8_t*) ((uint8_t*) ref));
}
/* set-zero-elements<a> void(a mut-arr<arrow<str, opt<str>>>) */
struct void_ set_zero_elements_2(struct mut_arr_7 a) {
	struct arrow_3* _0 = begin_ptr_10(a);
	uint64_t _1 = size_6(a);
	return set_zero_range_3(_0, _1);
}
/* set-zero-range<a> void(begin mut-ptr<arrow<str, opt<str>>>, size nat64) */
struct void_ set_zero_range_3(struct arrow_3* begin, uint64_t size) {
	uint8_t* _0 = memset(((uint8_t*) begin), 0, (size * sizeof(struct arrow_3)));
	return drop_0(_0);
}
/* subscript<a> mut-arr<arrow<str, opt<str>>>(a mut-arr<arrow<str, opt<str>>>, range arrow<nat64, nat64>) */
struct mut_arr_7 subscript_64(struct ctx* ctx, struct mut_arr_7 a, struct arrow_0 range) {
	uint8_t _0 = _lessOrEqual_0(range.from, range.to);
	assert_0(ctx, _0);
	uint64_t _1 = size_6(a);
	uint8_t _2 = _lessOrEqual_0(range.to, _1);
	assert_0(ctx, _2);
	struct arr_12 _3 = subscript_65(ctx, a.inner, range);
	return (struct mut_arr_7) {(struct void_) {}, _3};
}
/* subscript<a> arr<arrow<str, opt<str>>>(a arr<arrow<str, opt<str>>>, range arrow<nat64, nat64>) */
struct arr_12 subscript_65(struct ctx* ctx, struct arr_12 a, struct arrow_0 range) {
	uint8_t _0 = _lessOrEqual_0(range.from, range.to);
	assert_0(ctx, _0);
	uint8_t _1 = _lessOrEqual_0(range.to, a.size);
	assert_0(ctx, _1);
	struct arrow_3* _2 = _plus_13(a.begin_ptr, range.from);
	return (struct arr_12) {(range.to - range.from), _2};
}
/* set-subscript<a> void(a mut-ptr<arrow<str, opt<str>>>, n nat64, value arrow<str, opt<str>>) */
struct void_ set_subscript_13(struct arrow_3* a, uint64_t n, struct arrow_3 value) {
	return (*(a + n) = value, (struct void_) {});
}
/* insert-linear!<k, v> void(a mut-list<arrow<str, opt<str>>>, index nat64, key str, value str) */
struct void_ insert_linear__e_1(struct ctx* ctx, struct mut_list_4* a, uint64_t index, struct str key, struct str value) {
	top:;
	struct arrow_3 _0 = subscript_66(ctx, a, index);
	uint8_t _1 = _less_6(key, _0.from);
	if (_1) {
		move_right__e_1(ctx, a, index);
		struct arrow_3 _2 = _arrow_4(key, (struct opt_15) {1, .as1 = (struct some_15) {value}});
		return set_subscript_14(ctx, a, index, _2);
	} else {
		uint64_t _3 = _minus_7(ctx, a->size, 1u);
		uint8_t _4 = (index == _3);
		if (_4) {
			struct arrow_3 _5 = _arrow_4(key, (struct opt_15) {1, .as1 = (struct some_15) {value}});
			return _concatEquals_5(ctx, a, _5);
		} else {
			uint64_t _6 = _plus_3(ctx, index, 1u);
			a = a;
			index = _6;
			key = key;
			value = value;
			goto top;
		}
	}
}
/* subscript<arrow<k, opt<v>>> arrow<str, opt<str>>(a mut-list<arrow<str, opt<str>>>, index nat64) */
struct arrow_3 subscript_66(struct ctx* ctx, struct mut_list_4* a, uint64_t index) {
	uint8_t _0 = _less_0(index, a->size);
	assert_0(ctx, _0);
	struct arrow_3* _1 = begin_ptr_11(a);
	return subscript_67(_1, index);
}
/* subscript<a> arrow<str, opt<str>>(a mut-ptr<arrow<str, opt<str>>>, n nat64) */
struct arrow_3 subscript_67(struct arrow_3* a, uint64_t n) {
	return (*(a + n));
}
/* move-right!<k, v> void(a mut-list<arrow<str, opt<str>>>, index nat64) */
struct void_ move_right__e_1(struct ctx* ctx, struct mut_list_4* a, uint64_t index) {
	struct arrow_3 _0 = subscript_66(ctx, a, index);
	uint8_t _1 = is_empty_14(_0.to);
	uint8_t _2 = _not(_1);
	if (_2) {
		uint64_t _3 = _minus_7(ctx, a->size, 1u);
		uint8_t _4 = (index == _3);
		if (_4) {
			struct arrow_3 _5 = subscript_66(ctx, a, index);
			return _concatEquals_5(ctx, a, _5);
		} else {
			uint64_t _6 = _plus_3(ctx, index, 1u);
			move_right__e_1(ctx, a, _6);
			uint64_t _7 = _plus_3(ctx, index, 1u);
			struct arrow_3 _8 = subscript_66(ctx, a, index);
			return set_subscript_14(ctx, a, _7, _8);
		}
	} else {
		return (struct void_) {};
	}
}
/* set-subscript<arrow<k, opt<v>>> void(a mut-list<arrow<str, opt<str>>>, index nat64, value arrow<str, opt<str>>) */
struct void_ set_subscript_14(struct ctx* ctx, struct mut_list_4* a, uint64_t index, struct arrow_3 value) {
	uint8_t _0 = _less_0(index, a->size);
	assert_0(ctx, _0);
	struct arrow_3* _1 = begin_ptr_11(a);
	return set_subscript_13(_1, index, value);
}
/* compact-if-needed!<k, v> void(a mut-dict<str, str>) */
struct void_ compact_if_needed__e_1(struct ctx* ctx, struct mut_dict_1* a) {
	uint64_t physical_size0;
	physical_size0 = total_pairs_size_1(ctx, a);
	
	uint64_t _0 = _times_3(ctx, a->node_size, 2u);
	uint8_t _1 = _lessOrEqual_0(_0, physical_size0);
	if (_1) {
		compact__e_1(ctx, a);
		uint64_t _2 = total_pairs_size_1(ctx, a);
		return assert_0(ctx, (a->node_size == _2));
	} else {
		return (struct void_) {};
	}
}
/* total-pairs-size<k, v> nat64(a mut-dict<str, str>) */
uint64_t total_pairs_size_1(struct ctx* ctx, struct mut_dict_1* a) {
	return total_pairs_size_recur_1(ctx, 0u, a);
}
/* total-pairs-size-recur<k, v> nat64(acc nat64, a mut-dict<str, str>) */
uint64_t total_pairs_size_recur_1(struct ctx* ctx, uint64_t acc, struct mut_dict_1* a) {
	top:;
	uint64_t mid0;
	mid0 = _plus_3(ctx, acc, a->pairs->size);
	
	struct opt_18 _0 = a->next;
	switch (_0.kind) {
		case 0: {
			return mid0;
		}
		case 1: {
			struct some_18 _matched1 = _0.as1;
			
			struct mut_dict_1* next2;
			next2 = _matched1.value;
			
			acc = mid0;
			a = next2;
			goto top;
		}
		default:
			
	return 0;;
	}
}
/* compact!<k, v> void(a mut-dict<str, str>) */
struct void_ compact__e_1(struct ctx* ctx, struct mut_dict_1* a) {
	struct opt_18 _0 = a->next;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct some_18 _matched0 = _0.as1;
			
			struct mut_dict_1* next1;
			next1 = _matched0.value;
			
			compact__e_1(ctx, next1);
			filter__e_1(ctx, a->pairs, (struct fun_act1_18) {0, .as0 = (struct void_) {}});
			merge_no_duplicates__e_1(ctx, a->pairs, next1->pairs, (struct fun_act2_7) {0, .as0 = (struct void_) {}});
			a->next = (struct opt_18) {0, .as0 = (struct none) {}};
			return (a->node_size = a->pairs->size, (struct void_) {});
		}
		default:
			
	return (struct void_) {};;
	}
}
/* filter!<arrow<k, opt<v>>> void(a mut-list<arrow<str, opt<str>>>, f fun-act1<bool, arrow<str, opt<str>>>) */
struct void_ filter__e_1(struct ctx* ctx, struct mut_list_4* a, struct fun_act1_18 f) {
	struct arrow_3* new_end0;
	struct arrow_3* _0 = begin_ptr_11(a);
	struct arrow_3* _1 = begin_ptr_11(a);
	struct arrow_3* _2 = end_ptr_9(a);
	new_end0 = filter_recur__e_1(ctx, _0, ((struct arrow_3*) _1), ((struct arrow_3*) _2), f);
	
	uint64_t new_size1;
	struct arrow_3* _3 = begin_ptr_11(a);
	new_size1 = _minus_12(new_end0, _3);
	
	struct arrow_0 _4 = _arrow_0(new_size1, a->size);
	struct mut_arr_7 _5 = subscript_64(ctx, a->backing, _4);
	set_zero_elements_2(_5);
	return (a->size = new_size1, (struct void_) {});
}
/* filter-recur!<a> mut-ptr<arrow<str, opt<str>>>(out mut-ptr<arrow<str, opt<str>>>, in const-ptr<arrow<str, opt<str>>>, end const-ptr<arrow<str, opt<str>>>, f fun-act1<bool, arrow<str, opt<str>>>) */
struct arrow_3* filter_recur__e_1(struct ctx* ctx, struct arrow_3* out, struct arrow_3* in, struct arrow_3* end, struct fun_act1_18 f) {
	top:;
	uint8_t _0 = _equal_11(in, end);
	if (_0) {
		return out;
	} else {
		struct arrow_3* new_out0;
		struct arrow_3 _1 = _times_16(in);
		uint8_t _2 = subscript_68(ctx, f, _1);
		if (_2) {
			struct arrow_3 _3 = _times_16(in);
			*out = _3;
			new_out0 = (out + 1u);
		} else {
			new_out0 = out;
		}
		
		struct arrow_3* _4 = _plus_13(in, 1u);
		out = new_out0;
		in = _4;
		end = end;
		f = f;
		goto top;
	}
}
/* subscript<bool, a> bool(a fun-act1<bool, arrow<str, opt<str>>>, p0 arrow<str, opt<str>>) */
uint8_t subscript_68(struct ctx* ctx, struct fun_act1_18 a, struct arrow_3 p0) {
	return call_w_ctx_813(a, ctx, p0);
}
/* call-w-ctx<bool, arrow<str, opt<str>>> (generated) (generated) */
uint8_t call_w_ctx_813(struct fun_act1_18 a, struct ctx* ctx, struct arrow_3 p0) {
	struct fun_act1_18 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return compact__e_1__lambda0(ctx, closure0, p0);
		}
		default:
			
	return 0;;
	}
}
/* compact!<k, v>.lambda0 bool(pair arrow<str, opt<str>>) */
uint8_t compact__e_1__lambda0(struct ctx* ctx, struct void_ _closure, struct arrow_3 pair) {
	uint8_t _0 = is_empty_14(pair.to);
	return _not(_0);
}
/* merge-no-duplicates!<arrow<k, opt<v>>> void(a mut-list<arrow<str, opt<str>>>, b mut-list<arrow<str, opt<str>>>, compare fun-act2<unique-comparison, arrow<str, opt<str>>, arrow<str, opt<str>>>) */
struct void_ merge_no_duplicates__e_1(struct ctx* ctx, struct mut_list_4* a, struct mut_list_4* b, struct fun_act2_7 compare) {
	uint8_t _0 = _less_0(a->size, b->size);
	if (_0) {
		swap__e_2(ctx, a, b);
	} else {
		(struct void_) {};
	}
	uint8_t _1 = _greaterOrEqual(a->size, b->size);
	assert_0(ctx, _1);
	uint8_t _2 = is_empty_15(b);
	uint8_t _3 = _not(_2);
	if (_3) {
		uint64_t a_old_size0;
		a_old_size0 = a->size;
		
		unsafe_set_size__e_1(ctx, a, (a_old_size0 + b->size));
		struct arrow_3* a_read1;
		struct arrow_3* _4 = begin_ptr_11(a);
		struct arrow_3* _5 = _plus_13(((struct arrow_3*) _4), a_old_size0);
		a_read1 = _minus_13(_5, 1u);
		
		struct arrow_3* a_write2;
		struct arrow_3* _6 = end_ptr_9(a);
		a_write2 = (_6 - 1u);
		
		struct arrow_3* _7 = begin_ptr_11(a);
		struct arrow_3* _8 = begin_ptr_11(b);
		struct arrow_3* _9 = end_ptr_9(b);
		struct arrow_3* _10 = _minus_13(((struct arrow_3*) _9), 1u);
		merge_reverse_recur__e_1(ctx, _7, a_read1, a_write2, ((struct arrow_3*) _8), _10, compare);
		return empty__e_2(ctx, b);
	} else {
		return (struct void_) {};
	}
}
/* swap!<a> void(a mut-list<arrow<str, opt<str>>>, b mut-list<arrow<str, opt<str>>>) */
struct void_ swap__e_2(struct ctx* ctx, struct mut_list_4* a, struct mut_list_4* b) {
	struct mut_arr_7 a_backing0;
	a_backing0 = a->backing;
	
	uint64_t a_size1;
	a_size1 = a->size;
	
	a->backing = b->backing;
	a->size = b->size;
	b->backing = a_backing0;
	return (b->size = a_size1, (struct void_) {});
}
/* unsafe-set-size!<a> void(a mut-list<arrow<str, opt<str>>>, new-size nat64) */
struct void_ unsafe_set_size__e_1(struct ctx* ctx, struct mut_list_4* a, uint64_t new_size) {
	reserve_1(ctx, a, new_size);
	return (a->size = new_size, (struct void_) {});
}
/* reserve<a> void(a mut-list<arrow<str, opt<str>>>, reserved nat64) */
struct void_ reserve_1(struct ctx* ctx, struct mut_list_4* a, uint64_t reserved) {
	uint64_t _0 = round_up_to_power_of_two(ctx, reserved);
	return ensure_capacity_2(ctx, a, _0);
}
/* -<a> const-ptr<arrow<str, opt<str>>>(a const-ptr<arrow<str, opt<str>>>, offset nat64) */
struct arrow_3* _minus_13(struct arrow_3* a, uint64_t offset) {
	return ((struct arrow_3*) (((struct arrow_3*) a) - offset));
}
/* merge-reverse-recur!<a> void(a-begin mut-ptr<arrow<str, opt<str>>>, a-read const-ptr<arrow<str, opt<str>>>, a-write mut-ptr<arrow<str, opt<str>>>, b-begin const-ptr<arrow<str, opt<str>>>, b-read const-ptr<arrow<str, opt<str>>>, compare fun-act2<unique-comparison, arrow<str, opt<str>>, arrow<str, opt<str>>>) */
struct void_ merge_reverse_recur__e_1(struct ctx* ctx, struct arrow_3* a_begin, struct arrow_3* a_read, struct arrow_3* a_write, struct arrow_3* b_begin, struct arrow_3* b_read, struct fun_act2_7 compare) {
	top:;
	struct arrow_3 _0 = _times_16(a_read);
	struct arrow_3 _1 = _times_16(b_read);
	struct unique_comparison _2 = subscript_69(ctx, compare, _0, _1);
	switch (_2.kind) {
		case 0: {
			struct arrow_3 _3 = _times_16(b_read);
			*a_write = _3;
			uint8_t _4 = _notEqual_12(b_read, b_begin);
			if (_4) {
				struct arrow_3* _5 = _minus_13(b_read, 1u);
				a_begin = a_begin;
				a_read = a_read;
				a_write = (a_write - 1u);
				b_begin = b_begin;
				b_read = _5;
				compare = compare;
				goto top;
			} else {
				return (struct void_) {};
			}
		}
		case 1: {
			struct arrow_3 _6 = _times_16(a_read);
			*a_write = _6;
			uint8_t _7 = _equal_11(a_read, ((struct arrow_3*) a_begin));
			if (_7) {
				struct mut_arr_7 dest0;
				dest0 = mut_arr_from_begin_end_1(a_begin, a_write);
				
				struct arr_12 src1;
				struct arrow_3* _8 = _plus_13(b_read, 1u);
				src1 = arr_from_begin_end_2(b_begin, _8);
				
				return copy_from__e_1(ctx, dest0, src1);
			} else {
				struct arrow_3* _9 = _minus_13(a_read, 1u);
				a_begin = a_begin;
				a_read = _9;
				a_write = (a_write - 1u);
				b_begin = b_begin;
				b_read = b_read;
				compare = compare;
				goto top;
			}
		}
		default:
			
	return (struct void_) {};;
	}
}
/* subscript<unique-comparison, a, a> unique-comparison(a fun-act2<unique-comparison, arrow<str, opt<str>>, arrow<str, opt<str>>>, p0 arrow<str, opt<str>>, p1 arrow<str, opt<str>>) */
struct unique_comparison subscript_69(struct ctx* ctx, struct fun_act2_7 a, struct arrow_3 p0, struct arrow_3 p1) {
	return call_w_ctx_822(a, ctx, p0, p1);
}
/* call-w-ctx<unique-comparison, arrow<str, opt<str>>, arrow<str, opt<str>>> (generated) (generated) */
struct unique_comparison call_w_ctx_822(struct fun_act2_7 a, struct ctx* ctx, struct arrow_3 p0, struct arrow_3 p1) {
	struct fun_act2_7 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return compact__e_1__lambda1(ctx, closure0, p0, p1);
		}
		default:
			
	return (struct unique_comparison) {0};;
	}
}
/* !=<const-ptr<a>> bool(a const-ptr<arrow<str, opt<str>>>, b const-ptr<arrow<str, opt<str>>>) */
uint8_t _notEqual_12(struct arrow_3* a, struct arrow_3* b) {
	uint8_t _0 = _equal_11(a, b);
	return _not(_0);
}
/* mut-arr-from-begin-end<a> mut-arr<arrow<str, opt<str>>>(begin mut-ptr<arrow<str, opt<str>>>, end mut-ptr<arrow<str, opt<str>>>) */
struct mut_arr_7 mut_arr_from_begin_end_1(struct arrow_3* begin, struct arrow_3* end) {
	uint8_t _0 = _lessOrEqual_6(begin, end);
	hard_assert(_0);
	struct arr_12 _1 = arr_from_begin_end_2(((struct arrow_3*) begin), ((struct arrow_3*) end));
	return (struct mut_arr_7) {(struct void_) {}, _1};
}
/* <=><a> comparison(a mut-ptr<arrow<str, opt<str>>>, b mut-ptr<arrow<str, opt<str>>>) */
struct comparison _compare_13(struct arrow_3* a, struct arrow_3* b) {
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
/* <=<mut-ptr<a>> bool(a mut-ptr<arrow<str, opt<str>>>, b mut-ptr<arrow<str, opt<str>>>) */
uint8_t _lessOrEqual_6(struct arrow_3* a, struct arrow_3* b) {
	uint8_t _0 = _less_9(b, a);
	return _not(_0);
}
/* <<a> bool(a mut-ptr<arrow<str, opt<str>>>, b mut-ptr<arrow<str, opt<str>>>) */
uint8_t _less_9(struct arrow_3* a, struct arrow_3* b) {
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
/* arr-from-begin-end<a> arr<arrow<str, opt<str>>>(begin const-ptr<arrow<str, opt<str>>>, end const-ptr<arrow<str, opt<str>>>) */
struct arr_12 arr_from_begin_end_2(struct arrow_3* begin, struct arrow_3* end) {
	uint8_t _0 = _lessOrEqual_7(begin, end);
	hard_assert(_0);
	uint64_t _1 = _minus_11(end, begin);
	return (struct arr_12) {_1, begin};
}
/* <=><a> comparison(a const-ptr<arrow<str, opt<str>>>, b const-ptr<arrow<str, opt<str>>>) */
struct comparison _compare_14(struct arrow_3* a, struct arrow_3* b) {
	return _compare_13(((struct arrow_3*) a), ((struct arrow_3*) b));
}
/* <=<const-ptr<a>> bool(a const-ptr<arrow<str, opt<str>>>, b const-ptr<arrow<str, opt<str>>>) */
uint8_t _lessOrEqual_7(struct arrow_3* a, struct arrow_3* b) {
	uint8_t _0 = _less_10(b, a);
	return _not(_0);
}
/* <<a> bool(a const-ptr<arrow<str, opt<str>>>, b const-ptr<arrow<str, opt<str>>>) */
uint8_t _less_10(struct arrow_3* a, struct arrow_3* b) {
	struct comparison _0 = _compare_14(a, b);
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
/* copy-from!<a> void(dest mut-arr<arrow<str, opt<str>>>, source arr<arrow<str, opt<str>>>) */
struct void_ copy_from__e_1(struct ctx* ctx, struct mut_arr_7 dest, struct arr_12 source) {
	uint64_t _0 = size_6(dest);
	assert_0(ctx, (_0 == source.size));
	struct arrow_3* _1 = begin_ptr_10(dest);
	uint8_t* _2 = as_any_const_ptr_3(source.begin_ptr);
	uint64_t _3 = size_6(dest);
	uint8_t* _4 = memcpy(((uint8_t*) _1), _2, (_3 * sizeof(struct arrow_3)));
	return drop_0(_4);
}
/* empty!<a> void(a mut-list<arrow<str, opt<str>>>) */
struct void_ empty__e_2(struct ctx* ctx, struct mut_list_4* a) {
	return pop_n__e_1(ctx, a, a->size);
}
/* pop-n!<a> void(a mut-list<arrow<str, opt<str>>>, n nat64) */
struct void_ pop_n__e_1(struct ctx* ctx, struct mut_list_4* a, uint64_t n) {
	uint8_t _0 = _lessOrEqual_0(n, a->size);
	assert_0(ctx, _0);
	uint64_t new_size0;
	new_size0 = _minus_7(ctx, a->size, n);
	
	struct arrow_3* _1 = begin_ptr_11(a);
	set_zero_range_3((_1 + new_size0), n);
	return (a->size = new_size0, (struct void_) {});
}
/* compact!<k, v>.lambda1 unique-comparison(x arrow<str, opt<str>>, y arrow<str, opt<str>>) */
struct unique_comparison compact__e_1__lambda1(struct ctx* ctx, struct void_ _closure, struct arrow_3 x, struct arrow_3 y) {
	struct comparison _0 = _compare_8(x.from, y.from);
	return assert_comparison_not_equal(ctx, _0);
}
/* move-to-dict!<str, str> dict<str, str>(a mut-dict<str, str>) */
struct dict_1 move_to_dict__e_1(struct ctx* ctx, struct mut_dict_1* a) {
	struct arr_13 _0 = move_to_arr__e_3(ctx, a);
	return dict_1(ctx, _0);
}
/* dict<k, v> dict<str, str>(a arr<arrow<str, str>>) */
struct dict_1 dict_1(struct ctx* ctx, struct arr_13 a) {
	struct arr_13 _0 = sort_by_1(ctx, a, (struct fun_act1_19) {0, .as0 = (struct void_) {}});
	return (struct dict_1) {(struct void_) {}, (struct dict_impl_1) {1, .as1 = (struct end_node_1) {_0}}};
}
/* sort-by<arrow<k, v>, k> arr<arrow<str, str>>(a arr<arrow<str, str>>, f fun-act1<str, arrow<str, str>>) */
struct arr_13 sort_by_1(struct ctx* ctx, struct arr_13 a, struct fun_act1_19 f) {
	struct sort_by_1__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct sort_by_1__lambda0));
	temp0 = ((struct sort_by_1__lambda0*) _0);
	
	*temp0 = (struct sort_by_1__lambda0) {f};
	return sort_1(ctx, a, (struct fun_act2_8) {0, .as0 = temp0});
}
/* sort<a> arr<arrow<str, str>>(a arr<arrow<str, str>>, comparer fun-act2<comparison, arrow<str, str>, arrow<str, str>>) */
struct arr_13 sort_1(struct ctx* ctx, struct arr_13 a, struct fun_act2_8 comparer) {
	struct mut_arr_8 res0;
	res0 = mut_arr_13(ctx, a);
	
	sort__e_2(ctx, res0, comparer);
	return cast_immutable_3(res0);
}
/* mut-arr<a> mut-arr<arrow<str, str>>(a arr<arrow<str, str>>) */
struct mut_arr_8 mut_arr_13(struct ctx* ctx, struct arr_13 a) {
	struct mut_arr_13__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_arr_13__lambda0));
	temp0 = ((struct mut_arr_13__lambda0*) _0);
	
	*temp0 = (struct mut_arr_13__lambda0) {a};
	return make_mut_arr_2(ctx, a.size, (struct fun_act1_20) {0, .as0 = temp0});
}
/* make-mut-arr<a> mut-arr<arrow<str, str>>(size nat64, f fun-act1<arrow<str, str>, nat64>) */
struct mut_arr_8 make_mut_arr_2(struct ctx* ctx, uint64_t size, struct fun_act1_20 f) {
	struct mut_arr_8 res0;
	res0 = uninitialized_mut_arr_6(ctx, size);
	
	struct arrow_4* _0 = begin_ptr_12(res0);
	fill_ptr_range_3(ctx, _0, size, f);
	return res0;
}
/* uninitialized-mut-arr<a> mut-arr<arrow<str, str>>(size nat64) */
struct mut_arr_8 uninitialized_mut_arr_6(struct ctx* ctx, uint64_t size) {
	struct arrow_4* _0 = alloc_uninitialized_7(ctx, size);
	return mut_arr_14(size, _0);
}
/* mut-arr<a> mut-arr<arrow<str, str>>(size nat64, begin-ptr mut-ptr<arrow<str, str>>) */
struct mut_arr_8 mut_arr_14(uint64_t size, struct arrow_4* begin_ptr) {
	return (struct mut_arr_8) {(struct void_) {}, (struct arr_13) {size, ((struct arrow_4*) begin_ptr)}};
}
/* alloc-uninitialized<a> mut-ptr<arrow<str, str>>(size nat64) */
struct arrow_4* alloc_uninitialized_7(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(struct arrow_4)));
	return ((struct arrow_4*) _0);
}
/* fill-ptr-range<a> void(begin mut-ptr<arrow<str, str>>, size nat64, f fun-act1<arrow<str, str>, nat64>) */
struct void_ fill_ptr_range_3(struct ctx* ctx, struct arrow_4* begin, uint64_t size, struct fun_act1_20 f) {
	return fill_ptr_range_recur_3(ctx, begin, 0u, size, f);
}
/* fill-ptr-range-recur<a> void(begin mut-ptr<arrow<str, str>>, i nat64, size nat64, f fun-act1<arrow<str, str>, nat64>) */
struct void_ fill_ptr_range_recur_3(struct ctx* ctx, struct arrow_4* begin, uint64_t i, uint64_t size, struct fun_act1_20 f) {
	top:;
	uint8_t _0 = _notEqual_5(i, size);
	if (_0) {
		struct arrow_4 _1 = subscript_70(ctx, f, i);
		set_subscript_15(begin, i, _1);
		begin = begin;
		i = (i + 1u);
		size = size;
		f = f;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* set-subscript<a> void(a mut-ptr<arrow<str, str>>, n nat64, value arrow<str, str>) */
struct void_ set_subscript_15(struct arrow_4* a, uint64_t n, struct arrow_4 value) {
	return (*(a + n) = value, (struct void_) {});
}
/* subscript<a, nat64> arrow<str, str>(a fun-act1<arrow<str, str>, nat64>, p0 nat64) */
struct arrow_4 subscript_70(struct ctx* ctx, struct fun_act1_20 a, uint64_t p0) {
	return call_w_ctx_850(a, ctx, p0);
}
/* call-w-ctx<arrow<str, str>, nat-64> (generated) (generated) */
struct arrow_4 call_w_ctx_850(struct fun_act1_20 a, struct ctx* ctx, uint64_t p0) {
	struct fun_act1_20 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct mut_arr_13__lambda0* closure0 = _0.as0;
			
			return mut_arr_13__lambda0(ctx, closure0, p0);
		}
		case 1: {
			struct map_to_mut_arr_1__lambda0* closure1 = _0.as1;
			
			return map_to_mut_arr_1__lambda0(ctx, closure1, p0);
		}
		default:
			
	return (struct arrow_4) {(struct str) {(struct arr_0) {0, NULL}}, (struct str) {(struct arr_0) {0, NULL}}};;
	}
}
/* begin-ptr<a> mut-ptr<arrow<str, str>>(a mut-arr<arrow<str, str>>) */
struct arrow_4* begin_ptr_12(struct mut_arr_8 a) {
	return ((struct arrow_4*) a.inner.begin_ptr);
}
/* subscript<a> arrow<str, str>(a arr<arrow<str, str>>, index nat64) */
struct arrow_4 subscript_71(struct ctx* ctx, struct arr_13 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	return unsafe_at_9(a, index);
}
/* unsafe-at<a> arrow<str, str>(a arr<arrow<str, str>>, index nat64) */
struct arrow_4 unsafe_at_9(struct arr_13 a, uint64_t index) {
	return subscript_72(a.begin_ptr, index);
}
/* subscript<a> arrow<str, str>(a const-ptr<arrow<str, str>>, n nat64) */
struct arrow_4 subscript_72(struct arrow_4* a, uint64_t n) {
	struct arrow_4* _0 = _plus_14(a, n);
	return _times_17(_0);
}
/* *<a> arrow<str, str>(a const-ptr<arrow<str, str>>) */
struct arrow_4 _times_17(struct arrow_4* a) {
	return (*((struct arrow_4*) a));
}
/* +<a> const-ptr<arrow<str, str>>(a const-ptr<arrow<str, str>>, offset nat64) */
struct arrow_4* _plus_14(struct arrow_4* a, uint64_t offset) {
	return ((struct arrow_4*) (((struct arrow_4*) a) + offset));
}
/* mut-arr<a>.lambda0 arrow<str, str>(i nat64) */
struct arrow_4 mut_arr_13__lambda0(struct ctx* ctx, struct mut_arr_13__lambda0* _closure, uint64_t i) {
	return subscript_71(ctx, _closure->a, i);
}
/* sort!<a> void(a mut-arr<arrow<str, str>>, comparer fun-act2<comparison, arrow<str, str>, arrow<str, str>>) */
struct void_ sort__e_2(struct ctx* ctx, struct mut_arr_8 a, struct fun_act2_8 comparer) {
	uint8_t _0 = is_empty_16(a);
	uint8_t _1 = _not(_0);
	if (_1) {
		struct arrow_4* _2 = begin_ptr_12(a);
		struct arrow_4* _3 = begin_ptr_12(a);
		struct arrow_4* _4 = end_ptr_10(a);
		return insertion_sort_recur__e_1(ctx, _2, (_3 + 1u), _4, comparer);
	} else {
		return (struct void_) {};
	}
}
/* is-empty<a> bool(a mut-arr<arrow<str, str>>) */
uint8_t is_empty_16(struct mut_arr_8 a) {
	uint64_t _0 = size_7(a);
	return (_0 == 0u);
}
/* size<a> nat64(a mut-arr<arrow<str, str>>) */
uint64_t size_7(struct mut_arr_8 a) {
	return a.inner.size;
}
/* insertion-sort-recur!<a> void(begin mut-ptr<arrow<str, str>>, cur mut-ptr<arrow<str, str>>, end mut-ptr<arrow<str, str>>, comparer fun-act2<comparison, arrow<str, str>, arrow<str, str>>) */
struct void_ insertion_sort_recur__e_1(struct ctx* ctx, struct arrow_4* begin, struct arrow_4* cur, struct arrow_4* end, struct fun_act2_8 comparer) {
	top:;
	uint8_t _0 = _notEqual_13(cur, end);
	if (_0) {
		insert__e_1(ctx, begin, cur, (*cur), comparer);
		begin = begin;
		cur = (cur + 1u);
		end = end;
		comparer = comparer;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* !=<mut-ptr<a>> bool(a mut-ptr<arrow<str, str>>, b mut-ptr<arrow<str, str>>) */
uint8_t _notEqual_13(struct arrow_4* a, struct arrow_4* b) {
	return _not((a == b));
}
/* insert!<a> void(begin mut-ptr<arrow<str, str>>, cur mut-ptr<arrow<str, str>>, value arrow<str, str>, comparer fun-act2<comparison, arrow<str, str>, arrow<str, str>>) */
struct void_ insert__e_1(struct ctx* ctx, struct arrow_4* begin, struct arrow_4* cur, struct arrow_4 value, struct fun_act2_8 comparer) {
	top:;
	forbid(ctx, (begin == cur));
	struct arrow_4* prev0;
	prev0 = (cur - 1u);
	
	struct comparison _0 = subscript_73(ctx, comparer, value, (*prev0));
	uint8_t _1 = _equal_6(_0, (struct comparison) {0, .as0 = (struct less) {}});
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
/* subscript<comparison, a, a> comparison(a fun-act2<comparison, arrow<str, str>, arrow<str, str>>, p0 arrow<str, str>, p1 arrow<str, str>) */
struct comparison subscript_73(struct ctx* ctx, struct fun_act2_8 a, struct arrow_4 p0, struct arrow_4 p1) {
	return call_w_ctx_865(a, ctx, p0, p1);
}
/* call-w-ctx<comparison, arrow<str, str>, arrow<str, str>> (generated) (generated) */
struct comparison call_w_ctx_865(struct fun_act2_8 a, struct ctx* ctx, struct arrow_4 p0, struct arrow_4 p1) {
	struct fun_act2_8 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct sort_by_1__lambda0* closure0 = _0.as0;
			
			return sort_by_1__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return (struct comparison) {0};;
	}
}
/* end-ptr<a> mut-ptr<arrow<str, str>>(a mut-arr<arrow<str, str>>) */
struct arrow_4* end_ptr_10(struct mut_arr_8 a) {
	struct arrow_4* _0 = begin_ptr_12(a);
	uint64_t _1 = size_7(a);
	return (_0 + _1);
}
/* cast-immutable<a> arr<arrow<str, str>>(a mut-arr<arrow<str, str>>) */
struct arr_13 cast_immutable_3(struct mut_arr_8 a) {
	return a.inner;
}
/* subscript<b, a> str(a fun-act1<str, arrow<str, str>>, p0 arrow<str, str>) */
struct str subscript_74(struct ctx* ctx, struct fun_act1_19 a, struct arrow_4 p0) {
	return call_w_ctx_869(a, ctx, p0);
}
/* call-w-ctx<str, arrow<str, str>> (generated) (generated) */
struct str call_w_ctx_869(struct fun_act1_19 a, struct ctx* ctx, struct arrow_4 p0) {
	struct fun_act1_19 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return dict_1__lambda0(ctx, closure0, p0);
		}
		default:
			
	return (struct str) {(struct arr_0) {0, NULL}};;
	}
}
/* sort-by<arrow<k, v>, k>.lambda0 comparison(x arrow<str, str>, y arrow<str, str>) */
struct comparison sort_by_1__lambda0(struct ctx* ctx, struct sort_by_1__lambda0* _closure, struct arrow_4 x, struct arrow_4 y) {
	struct str _0 = subscript_74(ctx, _closure->f, x);
	struct str _1 = subscript_74(ctx, _closure->f, y);
	return _compare_8(_0, _1);
}
/* dict<k, v>.lambda0 str(pair arrow<str, str>) */
struct str dict_1__lambda0(struct ctx* ctx, struct void_ _closure, struct arrow_4 pair) {
	return pair.from;
}
/* move-to-arr!<k, v> arr<arrow<str, str>>(a mut-dict<str, str>) */
struct arr_13 move_to_arr__e_3(struct ctx* ctx, struct mut_dict_1* a) {
	struct arr_13 res0;
	res0 = map_to_arr_2(ctx, a, (struct fun_act2_9) {0, .as0 = (struct void_) {}});
	
	empty__e_3(ctx, a);
	return res0;
}
/* map-to-arr<arrow<k, v>, k, v> arr<arrow<str, str>>(a mut-dict<str, str>, f fun-act2<arrow<str, str>, str, str>) */
struct arr_13 map_to_arr_2(struct ctx* ctx, struct mut_dict_1* a, struct fun_act2_9 f) {
	compact__e_1(ctx, a);
	struct map_to_arr_2__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct map_to_arr_2__lambda0));
	temp0 = ((struct map_to_arr_2__lambda0*) _0);
	
	*temp0 = (struct map_to_arr_2__lambda0) {f};
	return map_to_arr_3(ctx, a->pairs, (struct fun_act1_21) {0, .as0 = temp0});
}
/* map-to-arr<out, arrow<k, opt<v>>> arr<arrow<str, str>>(a mut-list<arrow<str, opt<str>>>, f fun-act1<arrow<str, str>, arrow<str, opt<str>>>) */
struct arr_13 map_to_arr_3(struct ctx* ctx, struct mut_list_4* a, struct fun_act1_21 f) {
	struct mut_arr_8 _0 = map_to_mut_arr_1(ctx, a, f);
	return cast_immutable_3(_0);
}
/* map-to-mut-arr<out, in> mut-arr<arrow<str, str>>(a mut-list<arrow<str, opt<str>>>, f fun-act1<arrow<str, str>, arrow<str, opt<str>>>) */
struct mut_arr_8 map_to_mut_arr_1(struct ctx* ctx, struct mut_list_4* a, struct fun_act1_21 f) {
	struct map_to_mut_arr_1__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct map_to_mut_arr_1__lambda0));
	temp0 = ((struct map_to_mut_arr_1__lambda0*) _0);
	
	*temp0 = (struct map_to_mut_arr_1__lambda0) {f, a};
	return make_mut_arr_2(ctx, a->size, (struct fun_act1_20) {1, .as1 = temp0});
}
/* subscript<out, in> arrow<str, str>(a fun-act1<arrow<str, str>, arrow<str, opt<str>>>, p0 arrow<str, opt<str>>) */
struct arrow_4 subscript_75(struct ctx* ctx, struct fun_act1_21 a, struct arrow_3 p0) {
	return call_w_ctx_877(a, ctx, p0);
}
/* call-w-ctx<arrow<str, str>, arrow<str, opt<str>>> (generated) (generated) */
struct arrow_4 call_w_ctx_877(struct fun_act1_21 a, struct ctx* ctx, struct arrow_3 p0) {
	struct fun_act1_21 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct map_to_arr_2__lambda0* closure0 = _0.as0;
			
			return map_to_arr_2__lambda0(ctx, closure0, p0);
		}
		default:
			
	return (struct arrow_4) {(struct str) {(struct arr_0) {0, NULL}}, (struct str) {(struct arr_0) {0, NULL}}};;
	}
}
/* map-to-mut-arr<out, in>.lambda0 arrow<str, str>(i nat64) */
struct arrow_4 map_to_mut_arr_1__lambda0(struct ctx* ctx, struct map_to_mut_arr_1__lambda0* _closure, uint64_t i) {
	struct arrow_3 _0 = subscript_66(ctx, _closure->a, i);
	return subscript_75(ctx, _closure->f, _0);
}
/* subscript<out, k, v> arrow<str, str>(a fun-act2<arrow<str, str>, str, str>, p0 str, p1 str) */
struct arrow_4 subscript_76(struct ctx* ctx, struct fun_act2_9 a, struct str p0, struct str p1) {
	return call_w_ctx_880(a, ctx, p0, p1);
}
/* call-w-ctx<arrow<str, str>, str, str> (generated) (generated) */
struct arrow_4 call_w_ctx_880(struct fun_act2_9 a, struct ctx* ctx, struct str p0, struct str p1) {
	struct fun_act2_9 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return move_to_arr__e_3__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return (struct arrow_4) {(struct str) {(struct arr_0) {0, NULL}}, (struct str) {(struct arr_0) {0, NULL}}};;
	}
}
/* map-to-arr<arrow<k, v>, k, v>.lambda0 arrow<str, str>(pair arrow<str, opt<str>>) */
struct arrow_4 map_to_arr_2__lambda0(struct ctx* ctx, struct map_to_arr_2__lambda0* _closure, struct arrow_3 pair) {
	struct str _0 = force_0(ctx, pair.to);
	return subscript_76(ctx, _closure->f, pair.from, _0);
}
/* move-to-arr!<k, v>.lambda0 arrow<str, str>(key str, value str) */
struct arrow_4 move_to_arr__e_3__lambda0(struct ctx* ctx, struct void_ _closure, struct str key, struct str value) {
	return _arrow_3(key, value);
}
/* empty!<k, v> void(a mut-dict<str, str>) */
struct void_ empty__e_3(struct ctx* ctx, struct mut_dict_1* a) {
	a->next = (struct opt_18) {0, .as0 = (struct none) {}};
	return empty__e_2(ctx, a->pairs);
}
/* first-failures result<str, arr<failure>>(a result<str, arr<failure>>, b fun0<result<str, arr<failure>>>) */
struct result_2 first_failures(struct ctx* ctx, struct result_2 a, struct fun0 b) {
	struct result_2 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct ok_2 ok_a0 = _0.as0;
			
			struct result_2 _1 = subscript_77(ctx, b);
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
struct result_2 subscript_77(struct ctx* ctx, struct fun0 a) {
	return call_w_ctx_886(a, ctx);
}
/* call-w-ctx<result<str, arr<failure>>> (generated) (generated) */
struct result_2 call_w_ctx_886(struct fun0 a, struct ctx* ctx) {
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
	
	struct arr_14 failures1;
	struct run_crow_tests__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct run_crow_tests__lambda0));
	temp0 = ((struct run_crow_tests__lambda0*) _0);
	
	*temp0 = (struct run_crow_tests__lambda0) {path_to_crow, env, options};
	failures1 = flat_map_with_max_size(ctx, tests0, options->max_failures, (struct fun_act1_23) {0, .as0 = temp0});
	
	uint8_t _1 = is_empty_23(failures1);
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
	struct mut_list_5* res0;
	res0 = mut_list_3(ctx);
	
	struct list_tests__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct list_tests__lambda0));
	temp0 = ((struct list_tests__lambda0*) _0);
	
	*temp0 = (struct list_tests__lambda0) {match_test, res0};
	each_child_recursive_0(ctx, path, (struct fun_act1_22) {1, .as1 = temp0});
	return move_to_arr__e_4(res0);
}
/* mut-list<str> mut-list<str>() */
struct mut_list_5* mut_list_3(struct ctx* ctx) {
	struct mut_list_5* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_list_5));
	temp0 = ((struct mut_list_5*) _0);
	
	struct mut_arr_9 _1 = mut_arr_15();
	*temp0 = (struct mut_list_5) {_1, 0u};
	return temp0;
}
/* mut-arr<a> mut-arr<str>() */
struct mut_arr_9 mut_arr_15(void) {
	return (struct mut_arr_9) {(struct void_) {}, (struct arr_2) {0u, NULL}};
}
/* each-child-recursive void(path str, f fun-act1<void, str>) */
struct void_ each_child_recursive_0(struct ctx* ctx, struct str path, struct fun_act1_22 f) {
	struct fun_act1_8 filter0;
	filter0 = (struct fun_act1_8) {3, .as3 = (struct void_) {}};
	
	return each_child_recursive_1(ctx, path, filter0, f);
}
/* each-child-recursive.lambda0 bool(ignore str) */
uint8_t each_child_recursive_0__lambda0(struct ctx* ctx, struct void_ _closure, struct str ignore) {
	return 1;
}
/* each-child-recursive void(path str, filter fun-act1<bool, str>, f fun-act1<void, str>) */
struct void_ each_child_recursive_1(struct ctx* ctx, struct str path, struct fun_act1_8 filter, struct fun_act1_22 f) {
	uint8_t _0 = is_dir_0(ctx, path);
	if (_0) {
		struct arr_2 _1 = read_dir_0(ctx, path);
		struct each_child_recursive_1__lambda0* temp0;
		uint8_t* _2 = alloc(ctx, sizeof(struct each_child_recursive_1__lambda0));
		temp0 = ((struct each_child_recursive_1__lambda0*) _2);
		
		*temp0 = (struct each_child_recursive_1__lambda0) {filter, path, f};
		return each_3(ctx, _1, (struct fun_act1_22) {0, .as0 = temp0});
	} else {
		return subscript_78(ctx, f, path);
	}
}
/* is-dir bool(path str) */
uint8_t is_dir_0(struct ctx* ctx, struct str path) {
	char* _0 = to_c_str(ctx, path);
	return is_dir_1(ctx, _0);
}
/* is-dir bool(path const-ptr<char>) */
uint8_t is_dir_1(struct ctx* ctx, char* path) {
	struct opt_19 _0 = get_stat(ctx, path);
	switch (_0.kind) {
		case 0: {
			struct interp _1 = interp(ctx);
			struct interp _2 = with_str(ctx, _1, (struct str) {{21, constantarr_0_28}});
			struct interp _3 = with_value_1(ctx, _2, path);
			struct str _4 = finish(ctx, _3);
			return throw_10(ctx, _4);
		}
		case 1: {
			struct some_19 _matched0 = _0.as1;
			
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
struct opt_19 get_stat(struct ctx* ctx, char* path) {
	struct stat* s0;
	s0 = stat_0(ctx);
	
	int32_t err1;
	err1 = stat(path, s0);
	
	uint8_t _0 = (err1 == 0);
	if (_0) {
		return (struct opt_19) {1, .as1 = (struct some_19) {s0}};
	} else {
		assert_0(ctx, (err1 == -1));
		int32_t _1 = errno();
		int32_t _2 = ENOENT();
		uint8_t _3 = _notEqual_6(_1, _2);
		if (_3) {
			return todo_4();
		} else {
			return (struct opt_19) {0, .as0 = (struct none) {}};
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
struct opt_19 todo_4(void) {
	(abort(), (struct void_) {});
	return (struct opt_19) {0};
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
struct void_ each_3(struct ctx* ctx, struct arr_2 a, struct fun_act1_22 f) {
	struct str* _0 = end_ptr_7(a);
	return each_recur_2(ctx, a.begin_ptr, _0, f);
}
/* each-recur<a> void(cur const-ptr<str>, end const-ptr<str>, f fun-act1<void, str>) */
struct void_ each_recur_2(struct ctx* ctx, struct str* cur, struct str* end, struct fun_act1_22 f) {
	top:;
	uint8_t _0 = _notEqual_14(cur, end);
	if (_0) {
		struct str _1 = _times_10(cur);
		subscript_78(ctx, f, _1);
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
uint8_t _notEqual_14(struct str* a, struct str* b) {
	uint8_t _0 = _equal_10(a, b);
	return _not(_0);
}
/* subscript<void, a> void(a fun-act1<void, str>, p0 str) */
struct void_ subscript_78(struct ctx* ctx, struct fun_act1_22 a, struct str p0) {
	return call_w_ctx_914(a, ctx, p0);
}
/* call-w-ctx<void, str> (generated) (generated) */
struct void_ call_w_ctx_914(struct fun_act1_22 a, struct ctx* ctx, struct str p0) {
	struct fun_act1_22 _0 = a;
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
	
	uint8_t _0 = _notEqual_15(((uint8_t**) dirp0), NULL);
	assert_0(ctx, _0);
	struct mut_list_5* res1;
	res1 = mut_list_3(ctx);
	
	read_dir_recur(ctx, dirp0, res1);
	struct arr_2 _1 = move_to_arr__e_4(res1);
	return sort_2(ctx, _1);
}
/* !=<mut-ptr<const-ptr<nat8>>> bool(a mut-ptr<const-ptr<nat8>>, b mut-ptr<const-ptr<nat8>>) */
uint8_t _notEqual_15(uint8_t** a, uint8_t** b) {
	return _not((a == b));
}
/* read-dir-recur void(dirp dir, res mut-list<str>) */
struct void_ read_dir_recur(struct ctx* ctx, struct dir* dirp, struct mut_list_5* res) {
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
	struct dirent* _3 = _times_18(result1);
	uint8_t* _4 = as_any_const_ptr_4(_3);
	uint8_t* _5 = null_0();
	uint8_t _6 = _notEqual_16(_4, _5);
	if (_6) {
		struct dirent* _7 = _times_18(result1);
		uint8_t _8 = ref_eq(_7, entry0);
		assert_0(ctx, _8);
		struct str name3;
		name3 = get_dirent_name(ctx, entry0);
		
		uint8_t _9 = _notEqual_17(name3, (struct str) {{1, constantarr_0_30}});uint8_t _10;
		
		if (_9) {
			_10 = _notEqual_17(name3, (struct str) {{2, constantarr_0_31}});
		} else {
			_10 = 0;
		}
		if (_10) {
			struct str _11 = get_dirent_name(ctx, entry0);
			_concatEquals_6(ctx, res, _11);
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
uint8_t _notEqual_16(uint8_t* a, uint8_t* b) {
	uint8_t _0 = _equal_1(a, b);
	return _not(_0);
}
/* as-any-const-ptr<dirent> const-ptr<nat8>(ref dirent) */
uint8_t* as_any_const_ptr_4(struct dirent* ref) {
	return ((uint8_t*) ((uint8_t*) ref));
}
/* *<dirent> dirent(a cell<dirent>) */
struct dirent* _times_18(struct cell_4* a) {
	return a->inner_value;
}
/* ref-eq<dirent> bool(a dirent, b dirent) */
uint8_t ref_eq(struct dirent* a, struct dirent* b) {
	uint8_t* _0 = as_any_const_ptr_4(a);
	uint8_t* _1 = as_any_const_ptr_4(b);
	return _equal_1(_0, _1);
}
/* get-dirent-name str(d dirent) */
struct str get_dirent_name(struct ctx* ctx, struct dirent* d) {
	uint64_t name_offset0;
	uint64_t _0 = _plus_3(ctx, sizeof(uint64_t), sizeof(int64_t));
	uint64_t _1 = _plus_3(ctx, _0, sizeof(uint16_t));
	name_offset0 = _plus_3(ctx, _1, sizeof(char));
	
	uint8_t* name_ptr1;
	uint8_t* _2 = as_any_const_ptr_4(d);
	name_ptr1 = _plus_15(_2, name_offset0);
	
	char* _3 = ptr_cast_1(name_ptr1);
	return to_str_1(_3);
}
/* +<nat8> const-ptr<nat8>(a const-ptr<nat8>, offset nat64) */
uint8_t* _plus_15(uint8_t* a, uint64_t offset) {
	return ((uint8_t*) (((uint8_t*) a) + offset));
}
/* ptr-cast<char, nat8> const-ptr<char>(a const-ptr<nat8>) */
char* ptr_cast_1(uint8_t* a) {
	return ((char*) ((char*) ((uint8_t*) a)));
}
/* !=<str> bool(a str, b str) */
uint8_t _notEqual_17(struct str a, struct str b) {
	uint8_t _0 = _equal_5(a, b);
	return _not(_0);
}
/* ~=<str> void(a mut-list<str>, value str) */
struct void_ _concatEquals_6(struct ctx* ctx, struct mut_list_5* a, struct str value) {
	incr_capacity__e_3(ctx, a);
	uint64_t _0 = capacity_4(a);
	uint8_t _1 = _less_0(a->size, _0);
	assert_0(ctx, _1);
	struct str* _2 = begin_ptr_13(a);
	set_subscript_2(_2, a->size, value);
	uint64_t _3 = _plus_3(ctx, a->size, 1u);
	return (a->size = _3, (struct void_) {});
}
/* incr-capacity!<a> void(a mut-list<str>) */
struct void_ incr_capacity__e_3(struct ctx* ctx, struct mut_list_5* a) {
	uint64_t _0 = _plus_3(ctx, a->size, 1u);
	uint64_t _1 = round_up_to_power_of_two(ctx, _0);
	return ensure_capacity_3(ctx, a, _1);
}
/* ensure-capacity<a> void(a mut-list<str>, min-capacity nat64) */
struct void_ ensure_capacity_3(struct ctx* ctx, struct mut_list_5* a, uint64_t min_capacity) {
	uint64_t _0 = capacity_4(a);
	uint8_t _1 = _less_0(_0, min_capacity);
	if (_1) {
		return increase_capacity_to__e_3(ctx, a, min_capacity);
	} else {
		return (struct void_) {};
	}
}
/* capacity<a> nat64(a mut-list<str>) */
uint64_t capacity_4(struct mut_list_5* a) {
	return size_8(a->backing);
}
/* size<a> nat64(a mut-arr<str>) */
uint64_t size_8(struct mut_arr_9 a) {
	return a.inner.size;
}
/* increase-capacity-to!<a> void(a mut-list<str>, new-capacity nat64) */
struct void_ increase_capacity_to__e_3(struct ctx* ctx, struct mut_list_5* a, uint64_t new_capacity) {
	uint64_t _0 = capacity_4(a);
	uint8_t _1 = _greater_0(new_capacity, _0);
	assert_0(ctx, _1);
	struct str* old_begin0;
	old_begin0 = begin_ptr_13(a);
	
	struct mut_arr_9 _2 = uninitialized_mut_arr_7(ctx, new_capacity);
	a->backing = _2;
	struct str* _3 = begin_ptr_13(a);
	copy_data_from__e_4(ctx, _3, ((struct str*) old_begin0), a->size);
	uint64_t _4 = _plus_3(ctx, a->size, 1u);
	uint64_t _5 = size_8(a->backing);
	struct arrow_0 _6 = _arrow_0(_4, _5);
	struct mut_arr_9 _7 = subscript_79(ctx, a->backing, _6);
	return set_zero_elements_3(_7);
}
/* begin-ptr<a> mut-ptr<str>(a mut-list<str>) */
struct str* begin_ptr_13(struct mut_list_5* a) {
	return begin_ptr_14(a->backing);
}
/* begin-ptr<a> mut-ptr<str>(a mut-arr<str>) */
struct str* begin_ptr_14(struct mut_arr_9 a) {
	return ((struct str*) a.inner.begin_ptr);
}
/* uninitialized-mut-arr<a> mut-arr<str>(size nat64) */
struct mut_arr_9 uninitialized_mut_arr_7(struct ctx* ctx, uint64_t size) {
	struct str* _0 = alloc_uninitialized_1(ctx, size);
	return mut_arr_16(size, _0);
}
/* mut-arr<a> mut-arr<str>(size nat64, begin-ptr mut-ptr<str>) */
struct mut_arr_9 mut_arr_16(uint64_t size, struct str* begin_ptr) {
	return (struct mut_arr_9) {(struct void_) {}, (struct arr_2) {size, ((struct str*) begin_ptr)}};
}
/* copy-data-from!<a> void(to mut-ptr<str>, from const-ptr<str>, len nat64) */
struct void_ copy_data_from__e_4(struct ctx* ctx, struct str* to, struct str* from, uint64_t len) {
	uint8_t* _0 = as_any_const_ptr_5(from);
	uint8_t* _1 = memcpy(((uint8_t*) to), _0, (len * sizeof(struct str)));
	return drop_0(_1);
}
/* as-any-const-ptr<const-ptr<a>> const-ptr<nat8>(ref const-ptr<str>) */
uint8_t* as_any_const_ptr_5(struct str* ref) {
	return ((uint8_t*) ((uint8_t*) ref));
}
/* set-zero-elements<a> void(a mut-arr<str>) */
struct void_ set_zero_elements_3(struct mut_arr_9 a) {
	struct str* _0 = begin_ptr_14(a);
	uint64_t _1 = size_8(a);
	return set_zero_range_4(_0, _1);
}
/* set-zero-range<a> void(begin mut-ptr<str>, size nat64) */
struct void_ set_zero_range_4(struct str* begin, uint64_t size) {
	uint8_t* _0 = memset(((uint8_t*) begin), 0, (size * sizeof(struct str)));
	return drop_0(_0);
}
/* subscript<a> mut-arr<str>(a mut-arr<str>, range arrow<nat64, nat64>) */
struct mut_arr_9 subscript_79(struct ctx* ctx, struct mut_arr_9 a, struct arrow_0 range) {
	uint8_t _0 = _lessOrEqual_0(range.from, range.to);
	assert_0(ctx, _0);
	uint64_t _1 = size_8(a);
	uint8_t _2 = _lessOrEqual_0(range.to, _1);
	assert_0(ctx, _2);
	struct arr_2 _3 = subscript_33(ctx, a.inner, range);
	return (struct mut_arr_9) {(struct void_) {}, _3};
}
/* sort<str> arr<str>(a arr<str>) */
struct arr_2 sort_2(struct ctx* ctx, struct arr_2 a) {
	return sort_3(ctx, a, (struct fun_act2_10) {0, .as0 = (struct void_) {}});
}
/* sort<a> arr<str>(a arr<str>, comparer fun-act2<comparison, str, str>) */
struct arr_2 sort_3(struct ctx* ctx, struct arr_2 a, struct fun_act2_10 comparer) {
	struct mut_arr_9 res0;
	res0 = mut_arr_17(ctx, a);
	
	sort__e_3(ctx, res0, comparer);
	return cast_immutable_4(res0);
}
/* mut-arr<a> mut-arr<str>(a arr<str>) */
struct mut_arr_9 mut_arr_17(struct ctx* ctx, struct arr_2 a) {
	struct mut_arr_17__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_arr_17__lambda0));
	temp0 = ((struct mut_arr_17__lambda0*) _0);
	
	*temp0 = (struct mut_arr_17__lambda0) {a};
	return make_mut_arr_3(ctx, a.size, (struct fun_act1_7) {1, .as1 = temp0});
}
/* make-mut-arr<a> mut-arr<str>(size nat64, f fun-act1<str, nat64>) */
struct mut_arr_9 make_mut_arr_3(struct ctx* ctx, uint64_t size, struct fun_act1_7 f) {
	struct mut_arr_9 res0;
	res0 = uninitialized_mut_arr_7(ctx, size);
	
	struct str* _0 = begin_ptr_14(res0);
	fill_ptr_range_0(ctx, _0, size, f);
	return res0;
}
/* mut-arr<a>.lambda0 str(i nat64) */
struct str mut_arr_17__lambda0(struct ctx* ctx, struct mut_arr_17__lambda0* _closure, uint64_t i) {
	return subscript_26(ctx, _closure->a, i);
}
/* sort!<a> void(a mut-arr<str>, comparer fun-act2<comparison, str, str>) */
struct void_ sort__e_3(struct ctx* ctx, struct mut_arr_9 a, struct fun_act2_10 comparer) {
	uint8_t _0 = is_empty_17(a);
	uint8_t _1 = _not(_0);
	if (_1) {
		struct str* _2 = begin_ptr_14(a);
		struct str* _3 = begin_ptr_14(a);
		struct str* _4 = end_ptr_11(a);
		return insertion_sort_recur__e_2(ctx, _2, (_3 + 1u), _4, comparer);
	} else {
		return (struct void_) {};
	}
}
/* is-empty<a> bool(a mut-arr<str>) */
uint8_t is_empty_17(struct mut_arr_9 a) {
	uint64_t _0 = size_8(a);
	return (_0 == 0u);
}
/* insertion-sort-recur!<a> void(begin mut-ptr<str>, cur mut-ptr<str>, end mut-ptr<str>, comparer fun-act2<comparison, str, str>) */
struct void_ insertion_sort_recur__e_2(struct ctx* ctx, struct str* begin, struct str* cur, struct str* end, struct fun_act2_10 comparer) {
	top:;
	uint8_t _0 = _notEqual_18(cur, end);
	if (_0) {
		insert__e_2(ctx, begin, cur, (*cur), comparer);
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
uint8_t _notEqual_18(struct str* a, struct str* b) {
	return _not((a == b));
}
/* insert!<a> void(begin mut-ptr<str>, cur mut-ptr<str>, value str, comparer fun-act2<comparison, str, str>) */
struct void_ insert__e_2(struct ctx* ctx, struct str* begin, struct str* cur, struct str value, struct fun_act2_10 comparer) {
	top:;
	forbid(ctx, (begin == cur));
	struct str* prev0;
	prev0 = (cur - 1u);
	
	struct comparison _0 = subscript_80(ctx, comparer, value, (*prev0));
	uint8_t _1 = _equal_6(_0, (struct comparison) {0, .as0 = (struct less) {}});
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
/* subscript<comparison, a, a> comparison(a fun-act2<comparison, str, str>, p0 str, p1 str) */
struct comparison subscript_80(struct ctx* ctx, struct fun_act2_10 a, struct str p0, struct str p1) {
	return call_w_ctx_956(a, ctx, p0, p1);
}
/* call-w-ctx<comparison, str, str> (generated) (generated) */
struct comparison call_w_ctx_956(struct fun_act2_10 a, struct ctx* ctx, struct str p0, struct str p1) {
	struct fun_act2_10 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return sort_2__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return (struct comparison) {0};;
	}
}
/* end-ptr<a> mut-ptr<str>(a mut-arr<str>) */
struct str* end_ptr_11(struct mut_arr_9 a) {
	struct str* _0 = begin_ptr_14(a);
	uint64_t _1 = size_8(a);
	return (_0 + _1);
}
/* cast-immutable<a> arr<str>(a mut-arr<str>) */
struct arr_2 cast_immutable_4(struct mut_arr_9 a) {
	return a.inner;
}
/* sort<str>.lambda0 comparison(x str, y str) */
struct comparison sort_2__lambda0(struct ctx* ctx, struct void_ _closure, struct str x, struct str y) {
	return _compare_8(x, y);
}
/* move-to-arr!<str> arr<str>(a mut-list<str>) */
struct arr_2 move_to_arr__e_4(struct mut_list_5* a) {
	struct mut_arr_9 _0 = move_to_mut_arr__e_2(a);
	return cast_immutable_4(_0);
}
/* move-to-mut-arr!<a> mut-arr<str>(a mut-list<str>) */
struct mut_arr_9 move_to_mut_arr__e_2(struct mut_list_5* a) {
	struct mut_arr_9 res0;
	struct str* _0 = begin_ptr_13(a);
	res0 = mut_arr_16(a->size, _0);
	
	struct mut_arr_9 _1 = mut_arr_15();
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
	uint8_t _1 = is_empty_12(_0);
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
		struct arrow_0 _1 = _arrow_0(i, a.size);
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
	struct opt_15 _1 = get_extension(ctx, _0);
	return _equal_12(_1, (struct opt_15) {1, .as1 = (struct some_15) {(struct str) {{4, constantarr_0_27}}}});
}
/* == bool(a opt<str>, b opt<str>) */
uint8_t _equal_12(struct opt_15 a, struct opt_15 b) {
	return opt_equal(a, b);
}
/* opt-equal<str> bool(a opt<str>, b opt<str>) */
uint8_t opt_equal(struct opt_15 a, struct opt_15 b) {
	struct opt_15 _0 = a;
	switch (_0.kind) {
		case 0: {
			return is_empty_14(b);
		}
		case 1: {
			struct some_15 _matched0 = _0.as1;
			
			struct str va1;
			va1 = _matched0.value;
			
			struct opt_15 _1 = b;
			switch (_1.kind) {
				case 0: {
					return 0;
				}
				case 1: {
					struct some_15 _matched2 = _1.as1;
					
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
/* get-extension opt<str>(name str) */
struct opt_15 get_extension(struct ctx* ctx, struct str name) {
	struct opt_11 _0 = last_index_of(ctx, name, 46u);
	switch (_0.kind) {
		case 0: {
			return (struct opt_15) {0, .as0 = (struct none) {}};
		}
		case 1: {
			struct some_11 _matched0 = _0.as1;
			
			uint64_t index1;
			index1 = _matched0.value;
			
			uint64_t _1 = _plus_3(ctx, index1, 1u);
			uint64_t _2 = size_bytes(name);
			struct arrow_0 _3 = _arrow_0(_1, _2);
			struct arr_0 _4 = subscript_4(ctx, name.chars, _3);
			return (struct opt_15) {1, .as1 = (struct some_15) {(struct str) {_4}}};
		}
		default:
			
	return (struct opt_15) {0};;
	}
}
/* last-index-of opt<nat64>(a str, c char) */
struct opt_11 last_index_of(struct ctx* ctx, struct str a, char c) {
	top:;
	struct opt_20 _0 = last(ctx, a.chars);
	switch (_0.kind) {
		case 0: {
			return (struct opt_11) {0, .as0 = (struct none) {}};
		}
		case 1: {
			struct some_20 _matched0 = _0.as1;
			
			char last_char1;
			last_char1 = _matched0.value;
			
			uint8_t _1 = _equal_3(last_char1, c);
			if (_1) {
				uint64_t _2 = size_bytes(a);
				uint64_t _3 = _minus_7(ctx, _2, 1u);
				return (struct opt_11) {1, .as1 = (struct some_11) {_3}};
			} else {
				struct arr_0 _4 = rtail(ctx, a.chars);
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
struct opt_20 last(struct ctx* ctx, struct arr_0 a) {
	uint8_t _0 = is_empty_1(a);
	uint8_t _1 = _not(_0);
	if (_1) {
		uint64_t _2 = _minus_7(ctx, a.size, 1u);
		char _3 = subscript_61(ctx, a, _2);
		return (struct opt_20) {1, .as1 = (struct some_20) {_3}};
	} else {
		return (struct opt_20) {0, .as0 = (struct none) {}};
	}
}
/* rtail<char> arr<char>(a arr<char>) */
struct arr_0 rtail(struct ctx* ctx, struct arr_0 a) {
	uint8_t _0 = is_empty_1(a);
	forbid(ctx, _0);
	uint64_t _1 = _minus_7(ctx, a.size, 1u);
	struct arrow_0 _2 = _arrow_0(0u, _1);
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
			struct arrow_0 _3 = _arrow_0(_1, _2);
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
		return _concatEquals_6(ctx, _closure->res, child);
	} else {
		return (struct void_) {};
	}
}
/* flat-map-with-max-size<failure, str> arr<failure>(a arr<str>, max-size nat64, mapper fun-act1<arr<failure>, str>) */
struct arr_14 flat_map_with_max_size(struct ctx* ctx, struct arr_2 a, uint64_t max_size, struct fun_act1_23 mapper) {
	struct mut_list_6* res0;
	res0 = mut_list_4(ctx);
	
	struct flat_map_with_max_size__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct flat_map_with_max_size__lambda0));
	temp0 = ((struct flat_map_with_max_size__lambda0*) _0);
	
	*temp0 = (struct flat_map_with_max_size__lambda0) {res0, max_size, mapper};
	each_3(ctx, a, (struct fun_act1_22) {2, .as2 = temp0});
	return move_to_arr__e_5(res0);
}
/* mut-list<out> mut-list<failure>() */
struct mut_list_6* mut_list_4(struct ctx* ctx) {
	struct mut_list_6* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_list_6));
	temp0 = ((struct mut_list_6*) _0);
	
	struct mut_arr_10 _1 = mut_arr_18();
	*temp0 = (struct mut_list_6) {_1, 0u};
	return temp0;
}
/* mut-arr<a> mut-arr<failure>() */
struct mut_arr_10 mut_arr_18(void) {
	return (struct mut_arr_10) {(struct void_) {}, (struct arr_14) {0u, NULL}};
}
/* ~=<out> void(a mut-list<failure>, values arr<failure>) */
struct void_ _concatEquals_7(struct ctx* ctx, struct mut_list_6* a, struct arr_14 values) {
	struct _concatEquals_7__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct _concatEquals_7__lambda0));
	temp0 = ((struct _concatEquals_7__lambda0*) _0);
	
	*temp0 = (struct _concatEquals_7__lambda0) {a};
	return each_4(ctx, values, (struct fun_act1_24) {0, .as0 = temp0});
}
/* each<a> void(a arr<failure>, f fun-act1<void, failure>) */
struct void_ each_4(struct ctx* ctx, struct arr_14 a, struct fun_act1_24 f) {
	struct failure** _0 = end_ptr_12(a);
	return each_recur_3(ctx, a.begin_ptr, _0, f);
}
/* each-recur<a> void(cur const-ptr<failure>, end const-ptr<failure>, f fun-act1<void, failure>) */
struct void_ each_recur_3(struct ctx* ctx, struct failure** cur, struct failure** end, struct fun_act1_24 f) {
	top:;
	uint8_t _0 = _notEqual_19(cur, end);
	if (_0) {
		struct failure* _1 = _times_19(cur);
		subscript_81(ctx, f, _1);
		struct failure** _2 = _plus_16(cur, 1u);
		cur = _2;
		end = end;
		f = f;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* ==<a> bool(a const-ptr<failure>, b const-ptr<failure>) */
uint8_t _equal_13(struct failure** a, struct failure** b) {
	return (((struct failure**) a) == ((struct failure**) b));
}
/* !=<const-ptr<a>> bool(a const-ptr<failure>, b const-ptr<failure>) */
uint8_t _notEqual_19(struct failure** a, struct failure** b) {
	uint8_t _0 = _equal_13(a, b);
	return _not(_0);
}
/* subscript<void, a> void(a fun-act1<void, failure>, p0 failure) */
struct void_ subscript_81(struct ctx* ctx, struct fun_act1_24 a, struct failure* p0) {
	return call_w_ctx_985(a, ctx, p0);
}
/* call-w-ctx<void, gc-ptr(failure)> (generated) (generated) */
struct void_ call_w_ctx_985(struct fun_act1_24 a, struct ctx* ctx, struct failure* p0) {
	struct fun_act1_24 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct _concatEquals_7__lambda0* closure0 = _0.as0;
			
			return _concatEquals_7__lambda0(ctx, closure0, p0);
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
struct failure* _times_19(struct failure** a) {
	return (*((struct failure**) a));
}
/* +<a> const-ptr<failure>(a const-ptr<failure>, offset nat64) */
struct failure** _plus_16(struct failure** a, uint64_t offset) {
	return ((struct failure**) (((struct failure**) a) + offset));
}
/* end-ptr<a> const-ptr<failure>(a arr<failure>) */
struct failure** end_ptr_12(struct arr_14 a) {
	return _plus_16(a.begin_ptr, a.size);
}
/* ~=<a> void(a mut-list<failure>, value failure) */
struct void_ _concatEquals_8(struct ctx* ctx, struct mut_list_6* a, struct failure* value) {
	incr_capacity__e_4(ctx, a);
	uint64_t _0 = capacity_5(a);
	uint8_t _1 = _less_0(a->size, _0);
	assert_0(ctx, _1);
	struct failure** _2 = begin_ptr_15(a);
	set_subscript_16(_2, a->size, value);
	uint64_t _3 = _plus_3(ctx, a->size, 1u);
	return (a->size = _3, (struct void_) {});
}
/* incr-capacity!<a> void(a mut-list<failure>) */
struct void_ incr_capacity__e_4(struct ctx* ctx, struct mut_list_6* a) {
	uint64_t _0 = _plus_3(ctx, a->size, 1u);
	uint64_t _1 = round_up_to_power_of_two(ctx, _0);
	return ensure_capacity_4(ctx, a, _1);
}
/* ensure-capacity<a> void(a mut-list<failure>, min-capacity nat64) */
struct void_ ensure_capacity_4(struct ctx* ctx, struct mut_list_6* a, uint64_t min_capacity) {
	uint64_t _0 = capacity_5(a);
	uint8_t _1 = _less_0(_0, min_capacity);
	if (_1) {
		return increase_capacity_to__e_4(ctx, a, min_capacity);
	} else {
		return (struct void_) {};
	}
}
/* capacity<a> nat64(a mut-list<failure>) */
uint64_t capacity_5(struct mut_list_6* a) {
	return size_9(a->backing);
}
/* size<a> nat64(a mut-arr<failure>) */
uint64_t size_9(struct mut_arr_10 a) {
	return a.inner.size;
}
/* increase-capacity-to!<a> void(a mut-list<failure>, new-capacity nat64) */
struct void_ increase_capacity_to__e_4(struct ctx* ctx, struct mut_list_6* a, uint64_t new_capacity) {
	uint64_t _0 = capacity_5(a);
	uint8_t _1 = _greater_0(new_capacity, _0);
	assert_0(ctx, _1);
	struct failure** old_begin0;
	old_begin0 = begin_ptr_15(a);
	
	struct mut_arr_10 _2 = uninitialized_mut_arr_8(ctx, new_capacity);
	a->backing = _2;
	struct failure** _3 = begin_ptr_15(a);
	copy_data_from__e_5(ctx, _3, ((struct failure**) old_begin0), a->size);
	uint64_t _4 = _plus_3(ctx, a->size, 1u);
	uint64_t _5 = size_9(a->backing);
	struct arrow_0 _6 = _arrow_0(_4, _5);
	struct mut_arr_10 _7 = subscript_82(ctx, a->backing, _6);
	return set_zero_elements_4(_7);
}
/* begin-ptr<a> mut-ptr<failure>(a mut-list<failure>) */
struct failure** begin_ptr_15(struct mut_list_6* a) {
	return begin_ptr_16(a->backing);
}
/* begin-ptr<a> mut-ptr<failure>(a mut-arr<failure>) */
struct failure** begin_ptr_16(struct mut_arr_10 a) {
	return ((struct failure**) a.inner.begin_ptr);
}
/* uninitialized-mut-arr<a> mut-arr<failure>(size nat64) */
struct mut_arr_10 uninitialized_mut_arr_8(struct ctx* ctx, uint64_t size) {
	struct failure** _0 = alloc_uninitialized_8(ctx, size);
	return mut_arr_19(size, _0);
}
/* mut-arr<a> mut-arr<failure>(size nat64, begin-ptr mut-ptr<failure>) */
struct mut_arr_10 mut_arr_19(uint64_t size, struct failure** begin_ptr) {
	return (struct mut_arr_10) {(struct void_) {}, (struct arr_14) {size, ((struct failure**) begin_ptr)}};
}
/* alloc-uninitialized<a> mut-ptr<failure>(size nat64) */
struct failure** alloc_uninitialized_8(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(struct failure*)));
	return ((struct failure**) _0);
}
/* copy-data-from!<a> void(to mut-ptr<failure>, from const-ptr<failure>, len nat64) */
struct void_ copy_data_from__e_5(struct ctx* ctx, struct failure** to, struct failure** from, uint64_t len) {
	uint8_t* _0 = as_any_const_ptr_6(from);
	uint8_t* _1 = memcpy(((uint8_t*) to), _0, (len * sizeof(struct failure*)));
	return drop_0(_1);
}
/* as-any-const-ptr<const-ptr<a>> const-ptr<nat8>(ref const-ptr<failure>) */
uint8_t* as_any_const_ptr_6(struct failure** ref) {
	return ((uint8_t*) ((uint8_t*) ref));
}
/* set-zero-elements<a> void(a mut-arr<failure>) */
struct void_ set_zero_elements_4(struct mut_arr_10 a) {
	struct failure** _0 = begin_ptr_16(a);
	uint64_t _1 = size_9(a);
	return set_zero_range_5(_0, _1);
}
/* set-zero-range<a> void(begin mut-ptr<failure>, size nat64) */
struct void_ set_zero_range_5(struct failure** begin, uint64_t size) {
	uint8_t* _0 = memset(((uint8_t*) begin), 0, (size * sizeof(struct failure*)));
	return drop_0(_0);
}
/* subscript<a> mut-arr<failure>(a mut-arr<failure>, range arrow<nat64, nat64>) */
struct mut_arr_10 subscript_82(struct ctx* ctx, struct mut_arr_10 a, struct arrow_0 range) {
	uint8_t _0 = _lessOrEqual_0(range.from, range.to);
	assert_0(ctx, _0);
	uint64_t _1 = size_9(a);
	uint8_t _2 = _lessOrEqual_0(range.to, _1);
	assert_0(ctx, _2);
	struct arr_14 _3 = subscript_83(ctx, a.inner, range);
	return (struct mut_arr_10) {(struct void_) {}, _3};
}
/* subscript<a> arr<failure>(a arr<failure>, range arrow<nat64, nat64>) */
struct arr_14 subscript_83(struct ctx* ctx, struct arr_14 a, struct arrow_0 range) {
	uint8_t _0 = _lessOrEqual_0(range.from, range.to);
	assert_0(ctx, _0);
	uint8_t _1 = _lessOrEqual_0(range.to, a.size);
	assert_0(ctx, _1);
	struct failure** _2 = _plus_16(a.begin_ptr, range.from);
	return (struct arr_14) {(range.to - range.from), _2};
}
/* set-subscript<a> void(a mut-ptr<failure>, n nat64, value failure) */
struct void_ set_subscript_16(struct failure** a, uint64_t n, struct failure* value) {
	return (*(a + n) = value, (struct void_) {});
}
/* ~=<out>.lambda0 void(x failure) */
struct void_ _concatEquals_7__lambda0(struct ctx* ctx, struct _concatEquals_7__lambda0* _closure, struct failure* x) {
	return _concatEquals_8(ctx, _closure->a, x);
}
/* subscript<arr<out>, in> arr<failure>(a fun-act1<arr<failure>, str>, p0 str) */
struct arr_14 subscript_84(struct ctx* ctx, struct fun_act1_23 a, struct str p0) {
	return call_w_ctx_1009(a, ctx, p0);
}
/* call-w-ctx<arr<failure>, str> (generated) (generated) */
struct arr_14 call_w_ctx_1009(struct fun_act1_23 a, struct ctx* ctx, struct str p0) {
	struct fun_act1_23 _0 = a;
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
			
	return (struct arr_14) {0, NULL};;
	}
}
/* reduce-size-if-more-than!<out> void(a mut-list<failure>, new-size nat64) */
struct void_ reduce_size_if_more_than__e(struct ctx* ctx, struct mut_list_6* a, uint64_t new_size) {
	top:;
	uint8_t _0 = _less_0(new_size, a->size);
	if (_0) {
		struct opt_21 _1 = pop__e(ctx, a);
		drop_3(_1);
		a = a;
		new_size = new_size;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* drop<opt<a>> void(_ opt<failure>) */
struct void_ drop_3(struct opt_21 _p0) {
	return (struct void_) {};
}
/* pop!<a> opt<failure>(a mut-list<failure>) */
struct opt_21 pop__e(struct ctx* ctx, struct mut_list_6* a) {
	uint8_t _0 = is_empty_18(a);
	uint8_t _1 = _not(_0);
	if (_1) {
		uint64_t new_size0;
		new_size0 = (a->size - 1u);
		
		struct failure* res1;
		res1 = subscript_85(ctx, a, new_size0);
		
		set_subscript_17(ctx, a, new_size0, NULL);
		a->size = new_size0;
		return (struct opt_21) {1, .as1 = (struct some_21) {res1}};
	} else {
		return (struct opt_21) {0, .as0 = (struct none) {}};
	}
}
/* is-empty<a> bool(a mut-list<failure>) */
uint8_t is_empty_18(struct mut_list_6* a) {
	return (a->size == 0u);
}
/* subscript<a> failure(a mut-list<failure>, index nat64) */
struct failure* subscript_85(struct ctx* ctx, struct mut_list_6* a, uint64_t index) {
	uint8_t _0 = _less_0(index, a->size);
	assert_0(ctx, _0);
	struct failure** _1 = begin_ptr_15(a);
	return subscript_86(_1, index);
}
/* subscript<a> failure(a mut-ptr<failure>, n nat64) */
struct failure* subscript_86(struct failure** a, uint64_t n) {
	return (*(a + n));
}
/* set-subscript<a> void(a mut-list<failure>, index nat64, value failure) */
struct void_ set_subscript_17(struct ctx* ctx, struct mut_list_6* a, uint64_t index, struct failure* value) {
	uint8_t _0 = _less_0(index, a->size);
	assert_0(ctx, _0);
	struct failure** _1 = begin_ptr_15(a);
	return set_subscript_16(_1, index, value);
}
/* flat-map-with-max-size<failure, str>.lambda0 void(x str) */
struct void_ flat_map_with_max_size__lambda0(struct ctx* ctx, struct flat_map_with_max_size__lambda0* _closure, struct str x) {
	uint8_t _0 = _less_0(_closure->res->size, _closure->max_size);
	if (_0) {
		struct arr_14 _1 = subscript_84(ctx, _closure->mapper, x);
		_concatEquals_7(ctx, _closure->res, _1);
		return reduce_size_if_more_than__e(ctx, _closure->res, _closure->max_size);
	} else {
		return (struct void_) {};
	}
}
/* move-to-arr!<out> arr<failure>(a mut-list<failure>) */
struct arr_14 move_to_arr__e_5(struct mut_list_6* a) {
	struct mut_arr_10 _0 = move_to_mut_arr__e_3(a);
	return cast_immutable_5(_0);
}
/* cast-immutable<a> arr<failure>(a mut-arr<failure>) */
struct arr_14 cast_immutable_5(struct mut_arr_10 a) {
	return a.inner;
}
/* move-to-mut-arr!<a> mut-arr<failure>(a mut-list<failure>) */
struct mut_arr_10 move_to_mut_arr__e_3(struct mut_list_6* a) {
	struct mut_arr_10 res0;
	struct failure** _0 = begin_ptr_15(a);
	res0 = mut_arr_19(a->size, _0);
	
	struct mut_arr_10 _1 = mut_arr_18();
	a->backing = _1;
	a->size = 0u;
	return res0;
}
/* run-single-crow-test arr<failure>(path-to-crow str, env dict<str, str>, path str, options test-options) */
struct arr_14 run_single_crow_test(struct ctx* ctx, struct str path_to_crow, struct dict_1 env, struct str path, struct test_options* options) {
	struct opt_22 op0;
	struct run_single_crow_test__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct run_single_crow_test__lambda0));
	temp0 = ((struct run_single_crow_test__lambda0*) _0);
	
	*temp0 = (struct run_single_crow_test__lambda0) {options, path, path_to_crow, env};
	op0 = first_some(ctx, (struct arr_2) {4, constantarr_2_1}, (struct fun_act1_25) {0, .as0 = temp0});
	
	struct opt_22 _1 = op0;
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
			struct arr_14 interpret_failures1;
			interpret_failures1 = run_single_runnable_test(ctx, path_to_crow, env, path, 1, options->overwrite_output);
			
			uint8_t _7 = is_empty_23(interpret_failures1);
			if (_7) {
				return run_single_runnable_test(ctx, path_to_crow, env, path, 0, options->overwrite_output);
			} else {
				return interpret_failures1;
			}
		}
		case 1: {
			struct some_22 _matched2 = _1.as1;
			
			struct arr_14 res3;
			res3 = _matched2.value;
			
			return res3;
		}
		default:
			
	return (struct arr_14) {0, NULL};;
	}
}
/* first-some<arr<failure>, str> opt<arr<failure>>(a arr<str>, f fun-act1<opt<arr<failure>>, str>) */
struct opt_22 first_some(struct ctx* ctx, struct arr_2 a, struct fun_act1_25 f) {
	top:;
	uint8_t _0 = is_empty_6(a);
	uint8_t _1 = _not(_0);
	if (_1) {
		struct opt_22 res0;
		struct str _2 = subscript_26(ctx, a, 0u);
		res0 = subscript_87(ctx, f, _2);
		
		uint8_t _3 = is_empty_19(res0);
		if (_3) {
			struct arr_2 _4 = tail_1(ctx, a);
			a = _4;
			f = f;
			goto top;
		} else {
			return res0;
		}
	} else {
		return (struct opt_22) {0, .as0 = (struct none) {}};
	}
}
/* subscript<opt<out>, in> opt<arr<failure>>(a fun-act1<opt<arr<failure>>, str>, p0 str) */
struct opt_22 subscript_87(struct ctx* ctx, struct fun_act1_25 a, struct str p0) {
	return call_w_ctx_1024(a, ctx, p0);
}
/* call-w-ctx<opt<arr<failure>>, str> (generated) (generated) */
struct opt_22 call_w_ctx_1024(struct fun_act1_25 a, struct ctx* ctx, struct str p0) {
	struct fun_act1_25 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct run_single_crow_test__lambda0* closure0 = _0.as0;
			
			return run_single_crow_test__lambda0(ctx, closure0, p0);
		}
		default:
			
	return (struct opt_22) {0};;
	}
}
/* is-empty<out> bool(a opt<arr<failure>>) */
uint8_t is_empty_19(struct opt_22 a) {
	struct opt_22 _0 = a;
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
	
	struct arr_14 output_failures2;
	uint8_t _6 = is_empty_0(res0->stdout);uint8_t _7;
	
	if (_6) {
		_7 = _notEqual_6(res0->exit_code, 0);
	} else {
		_7 = 0;
	}
	if (_7) {
		output_failures2 = (struct arr_14) {0u, NULL};
	} else {
		output_failures2 = handle_output(ctx, path, output_path1, res0->stdout, overwrite_output);
	}
	
	uint8_t _8 = is_empty_23(output_failures2);
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
			
			*temp2 = (struct print_test_result) {0, (struct arr_14) {0u, NULL}};
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
				struct arr_14 _20 = handle_output(ctx, path, _19, stderr_no_color3, overwrite_output);
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
				*temp6 = (struct print_test_result) {1, (struct arr_14) {1u, temp4}};
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
	struct str _4 = fold_4(ctx, _3, args, (struct fun_act2_11) {0, .as0 = (struct void_) {}});
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
struct str fold_4(struct ctx* ctx, struct str acc, struct arr_2 a, struct fun_act2_11 f) {
	struct str* _0 = end_ptr_7(a);
	return fold_recur_3(ctx, acc, a.begin_ptr, _0, f);
}
/* fold-recur<a, b> str(acc str, cur const-ptr<str>, end const-ptr<str>, f fun-act2<str, str, str>) */
struct str fold_recur_3(struct ctx* ctx, struct str acc, struct str* cur, struct str* end, struct fun_act2_11 f) {
	top:;
	uint8_t _0 = _equal_10(cur, end);
	if (_0) {
		return acc;
	} else {
		struct str _1 = _times_10(cur);
		struct str _2 = subscript_88(ctx, f, acc, _1);
		struct str* _3 = _plus_8(cur, 1u);
		acc = _2;
		cur = _3;
		end = end;
		f = f;
		goto top;
	}
}
/* subscript<a, a, b> str(a fun-act2<str, str, str>, p0 str, p1 str) */
struct str subscript_88(struct ctx* ctx, struct fun_act2_11 a, struct str p0, struct str p1) {
	return call_w_ctx_1031(a, ctx, p0, p1);
}
/* call-w-ctx<str, str, str> (generated) (generated) */
struct str call_w_ctx_1031(struct fun_act2_11 a, struct ctx* ctx, struct str p0, struct str p1) {
	struct fun_act2_11 _0 = a;
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
	struct opt_19 _0 = get_stat(ctx, path);
	switch (_0.kind) {
		case 0: {
			return 0;
		}
		case 1: {
			struct some_19 _matched0 = _0.as1;
			
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
	pid4 = _times_20(pid_cell3);
	
	int32_t _14 = close(stdout_pipes0->read_pipe);
	check_posix_error(ctx, _14);
	int32_t _15 = close(stderr_pipes1->read_pipe);
	check_posix_error(ctx, _15);
	struct mut_list_1* stdout_builder5;
	stdout_builder5 = mut_list_0(ctx);
	
	struct mut_list_1* stderr_builder6;
	stderr_builder6 = mut_list_0(ctx);
	
	keep_POLLINg(ctx, stdout_pipes0->write_pipe, stderr_pipes1->write_pipe, stdout_builder5, stderr_builder6);
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
int32_t _times_20(struct cell_5* a) {
	return a->inner_value;
}
/* keep-POLLINg void(stdout-pipe int32, stderr-pipe int32, stdout-builder mut-list<char>, stderr-builder mut-list<char>) */
struct void_ keep_POLLINg(struct ctx* ctx, int32_t stdout_pipe, int32_t stderr_pipe, struct mut_list_1* stdout_builder, struct mut_list_1* stderr_builder) {
	top:;
	struct mut_arr_11 poll_fds0;
	struct pollfd* temp0;
	uint8_t* _0 = alloc(ctx, (sizeof(struct pollfd) * 2u));
	temp0 = ((struct pollfd*) _0);
	
	int16_t _1 = POLLIN(ctx);
	*(temp0 + 0u) = (struct pollfd) {stdout_pipe, _1, 0};
	int16_t _2 = POLLIN(ctx);
	*(temp0 + 1u) = (struct pollfd) {stderr_pipe, _2, 0};
	poll_fds0 = mut_arr_20(ctx, (struct arr_15) {2u, temp0});
	
	struct pollfd* stdout_pollfd1;
	stdout_pollfd1 = ref_of_val_at(ctx, poll_fds0, 0u);
	
	struct pollfd* stderr_pollfd2;
	stderr_pollfd2 = ref_of_val_at(ctx, poll_fds0, 1u);
	
	int64_t n_pollfds_with_events3;
	struct pollfd* _3 = begin_ptr_17(poll_fds0);
	uint64_t _4 = size_10(poll_fds0);
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
/* mut-arr<by-val<pollfd>> mut-arr<pollfd>(a arr<pollfd>) */
struct mut_arr_11 mut_arr_20(struct ctx* ctx, struct arr_15 a) {
	struct mut_arr_20__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_arr_20__lambda0));
	temp0 = ((struct mut_arr_20__lambda0*) _0);
	
	*temp0 = (struct mut_arr_20__lambda0) {a};
	return make_mut_arr_4(ctx, a.size, (struct fun_act1_26) {0, .as0 = temp0});
}
/* make-mut-arr<a> mut-arr<pollfd>(size nat64, f fun-act1<pollfd, nat64>) */
struct mut_arr_11 make_mut_arr_4(struct ctx* ctx, uint64_t size, struct fun_act1_26 f) {
	struct mut_arr_11 res0;
	res0 = uninitialized_mut_arr_9(ctx, size);
	
	struct pollfd* _0 = begin_ptr_17(res0);
	fill_ptr_range_4(ctx, _0, size, f);
	return res0;
}
/* uninitialized-mut-arr<a> mut-arr<pollfd>(size nat64) */
struct mut_arr_11 uninitialized_mut_arr_9(struct ctx* ctx, uint64_t size) {
	struct pollfd* _0 = alloc_uninitialized_9(ctx, size);
	return mut_arr_21(size, _0);
}
/* mut-arr<a> mut-arr<pollfd>(size nat64, begin-ptr mut-ptr<pollfd>) */
struct mut_arr_11 mut_arr_21(uint64_t size, struct pollfd* begin_ptr) {
	return (struct mut_arr_11) {(struct void_) {}, (struct arr_15) {size, ((struct pollfd*) begin_ptr)}};
}
/* alloc-uninitialized<a> mut-ptr<pollfd>(size nat64) */
struct pollfd* alloc_uninitialized_9(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(struct pollfd)));
	return ((struct pollfd*) _0);
}
/* fill-ptr-range<a> void(begin mut-ptr<pollfd>, size nat64, f fun-act1<pollfd, nat64>) */
struct void_ fill_ptr_range_4(struct ctx* ctx, struct pollfd* begin, uint64_t size, struct fun_act1_26 f) {
	return fill_ptr_range_recur_4(ctx, begin, 0u, size, f);
}
/* fill-ptr-range-recur<a> void(begin mut-ptr<pollfd>, i nat64, size nat64, f fun-act1<pollfd, nat64>) */
struct void_ fill_ptr_range_recur_4(struct ctx* ctx, struct pollfd* begin, uint64_t i, uint64_t size, struct fun_act1_26 f) {
	top:;
	uint8_t _0 = _notEqual_5(i, size);
	if (_0) {
		struct pollfd _1 = subscript_89(ctx, f, i);
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
/* set-subscript<a> void(a mut-ptr<pollfd>, n nat64, value pollfd) */
struct void_ set_subscript_18(struct pollfd* a, uint64_t n, struct pollfd value) {
	return (*(a + n) = value, (struct void_) {});
}
/* subscript<a, nat64> pollfd(a fun-act1<pollfd, nat64>, p0 nat64) */
struct pollfd subscript_89(struct ctx* ctx, struct fun_act1_26 a, uint64_t p0) {
	return call_w_ctx_1056(a, ctx, p0);
}
/* call-w-ctx<pollfd, nat-64> (generated) (generated) */
struct pollfd call_w_ctx_1056(struct fun_act1_26 a, struct ctx* ctx, uint64_t p0) {
	struct fun_act1_26 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct mut_arr_20__lambda0* closure0 = _0.as0;
			
			return mut_arr_20__lambda0(ctx, closure0, p0);
		}
		default:
			
	return (struct pollfd) {0, 0, 0};;
	}
}
/* begin-ptr<a> mut-ptr<pollfd>(a mut-arr<pollfd>) */
struct pollfd* begin_ptr_17(struct mut_arr_11 a) {
	return ((struct pollfd*) a.inner.begin_ptr);
}
/* subscript<a> pollfd(a arr<pollfd>, index nat64) */
struct pollfd subscript_90(struct ctx* ctx, struct arr_15 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	return unsafe_at_10(a, index);
}
/* unsafe-at<a> pollfd(a arr<pollfd>, index nat64) */
struct pollfd unsafe_at_10(struct arr_15 a, uint64_t index) {
	return subscript_91(a.begin_ptr, index);
}
/* subscript<a> pollfd(a const-ptr<pollfd>, n nat64) */
struct pollfd subscript_91(struct pollfd* a, uint64_t n) {
	struct pollfd* _0 = _plus_17(a, n);
	return _times_21(_0);
}
/* *<a> pollfd(a const-ptr<pollfd>) */
struct pollfd _times_21(struct pollfd* a) {
	return (*((struct pollfd*) a));
}
/* +<a> const-ptr<pollfd>(a const-ptr<pollfd>, offset nat64) */
struct pollfd* _plus_17(struct pollfd* a, uint64_t offset) {
	return ((struct pollfd*) (((struct pollfd*) a) + offset));
}
/* mut-arr<by-val<pollfd>>.lambda0 pollfd(i nat64) */
struct pollfd mut_arr_20__lambda0(struct ctx* ctx, struct mut_arr_20__lambda0* _closure, uint64_t i) {
	return subscript_90(ctx, _closure->a, i);
}
/* POLLIN int16() */
int16_t POLLIN(struct ctx* ctx) {
	return 1;
}
/* ref-of-val-at<pollfd> pollfd(a mut-arr<pollfd>, index nat64) */
struct pollfd* ref_of_val_at(struct ctx* ctx, struct mut_arr_11 a, uint64_t index) {
	uint64_t _0 = size_10(a);
	uint8_t _1 = _less_0(index, _0);
	assert_0(ctx, _1);
	struct pollfd* _2 = begin_ptr_17(a);
	return ref_of_ptr((_2 + index));
}
/* size<by-val<a>> nat64(a mut-arr<pollfd>) */
uint64_t size_10(struct mut_arr_11 a) {
	return a.inner.size;
}
/* ref-of-ptr<a> pollfd(p mut-ptr<pollfd>) */
struct pollfd* ref_of_ptr(struct pollfd* p) {
	return (&(*p));
}
/* handle-revents handle-revents-result(pollfd pollfd, builder mut-list<char>) */
struct handle_revents_result handle_revents(struct ctx* ctx, struct pollfd* pollfd, struct mut_list_1* builder) {
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
	return _notEqual_20((a & b), 0);
}
/* !=<int16> bool(a int16, b int16) */
uint8_t _notEqual_20(int16_t a, int16_t b) {
	return _not((a == b));
}
/* read-to-buffer-until-eof void(fd int32, buffer mut-list<char>) */
struct void_ read_to_buffer_until_eof(struct ctx* ctx, int32_t fd, struct mut_list_1* buffer) {
	top:;
	uint64_t old_size0;
	old_size0 = buffer->size;
	
	unsafe_set_size__e_2(ctx, buffer, (old_size0 + 1024u));
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
			unsafe_set_size__e_2(ctx, buffer, old_size0);
			return (struct void_) {};
		} else {
			uint64_t _3 = to_nat64_0(ctx, n_bytes_read2);
			uint8_t _4 = _lessOrEqual_0(_3, 1024u);
			assert_0(ctx, _4);
			uint64_t new_size3;
			uint64_t _5 = to_nat64_0(ctx, n_bytes_read2);
			new_size3 = (old_size0 + _5);
			
			unsafe_set_size__e_2(ctx, buffer, new_size3);
			fd = fd;
			buffer = buffer;
			goto top;
		}
	}
}
/* unsafe-set-size!<char> void(a mut-list<char>, new-size nat64) */
struct void_ unsafe_set_size__e_2(struct ctx* ctx, struct mut_list_1* a, uint64_t new_size) {
	reserve_2(ctx, a, new_size);
	return (a->size = new_size, (struct void_) {});
}
/* reserve<a> void(a mut-list<char>, reserved nat64) */
struct void_ reserve_2(struct ctx* ctx, struct mut_list_1* a, uint64_t reserved) {
	uint64_t _0 = round_up_to_power_of_two(ctx, reserved);
	return ensure_capacity_0(ctx, a, _0);
}
/* to-nat64 nat64(a int64) */
uint64_t to_nat64_0(struct ctx* ctx, int64_t a) {
	uint8_t _0 = _less_11(a, 0);
	forbid(ctx, _0);
	return ((uint64_t) a);
}
/* <=> comparison(a int64, b int64) */
struct comparison _compare_15(int64_t a, int64_t b) {
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
uint8_t _less_11(int64_t a, int64_t b) {
	struct comparison _0 = _compare_15(a, b);
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
	wait_status2 = _times_20(wait_status_cell0);
	
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
	uint8_t _0 = _less_12(a, 0);
	if (_0) {
		return todo_5();
	} else {
		uint8_t _1 = _less_12(b, 0);
		if (_1) {
			return todo_5();
		} else {
			uint8_t _2 = _less_12(b, 32);
			if (_2) {
				return ((int32_t) ((int64_t) (((uint64_t) ((int64_t) a)) >> ((uint64_t) ((int64_t) b)))));
			} else {
				return todo_5();
			}
		}
	}
}
/* <=> comparison(a int32, b int32) */
struct comparison _compare_16(int32_t a, int32_t b) {
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
uint8_t _less_12(int32_t a, int32_t b) {
	struct comparison _0 = _compare_16(a, b);
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
	
	uint8_t _1 = _less_11(a, 0);
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
	uint8_t _0 = _less_11(a, 0);int64_t _1;
	
	if (_0) {
		_1 = _minus_14(ctx, a);
	} else {
		_1 = a;
	}
	return to_nat64_0(ctx, _1);
}
/* - int64(a int64) */
int64_t _minus_14(struct ctx* ctx, int64_t a) {
	return _times_22(ctx, a, -1);
}
/* * int64(a int64, b int64) */
int64_t _times_22(struct ctx* ctx, int64_t a, int64_t b) {
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
	struct arr_7 _1 = map_1(ctx, args, (struct fun_act1_27) {0, .as0 = (struct void_) {}});
	struct arr_7 _2 = _tilde_2(ctx, (struct arr_7) {1u, temp0}, _1);
	char** temp1;
	uint8_t* _3 = alloc(ctx, (sizeof(char*) * 1u));
	temp1 = ((char**) _3);
	
	char* _4 = null_1();
	*(temp1 + 0u) = _4;
	struct arr_7 _5 = _tilde_2(ctx, _2, (struct arr_7) {1u, temp1});
	return _5.begin_ptr;
}
/* ~<const-ptr<char>> arr<const-ptr<char>>(a arr<const-ptr<char>>, b arr<const-ptr<char>>) */
struct arr_7 _tilde_2(struct ctx* ctx, struct arr_7 a, struct arr_7 b) {
	uint64_t res_size0;
	res_size0 = (a.size + b.size);
	
	char** res1;
	res1 = alloc_uninitialized_10(ctx, res_size0);
	
	copy_data_from__e_6(ctx, res1, a.begin_ptr, a.size);
	copy_data_from__e_6(ctx, (res1 + a.size), b.begin_ptr, b.size);
	return (struct arr_7) {res_size0, ((char**) res1)};
}
/* alloc-uninitialized<a> mut-ptr<const-ptr<char>>(size nat64) */
char** alloc_uninitialized_10(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(char*)));
	return ((char**) _0);
}
/* copy-data-from!<a> void(to mut-ptr<const-ptr<char>>, from const-ptr<const-ptr<char>>, len nat64) */
struct void_ copy_data_from__e_6(struct ctx* ctx, char** to, char** from, uint64_t len) {
	uint8_t* _0 = as_any_const_ptr_7(from);
	uint8_t* _1 = memcpy(((uint8_t*) to), _0, (len * sizeof(char*)));
	return drop_0(_1);
}
/* as-any-const-ptr<const-ptr<a>> const-ptr<nat8>(ref const-ptr<const-ptr<char>>) */
uint8_t* as_any_const_ptr_7(char** ref) {
	return ((uint8_t*) ((uint8_t*) ref));
}
/* map<const-ptr<char>, str> arr<const-ptr<char>>(a arr<str>, f fun-act1<const-ptr<char>, str>) */
struct arr_7 map_1(struct ctx* ctx, struct arr_2 a, struct fun_act1_27 f) {
	struct map_1__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct map_1__lambda0));
	temp0 = ((struct map_1__lambda0*) _0);
	
	*temp0 = (struct map_1__lambda0) {f, a};
	return make_arr_1(ctx, a.size, (struct fun_act1_28) {0, .as0 = temp0});
}
/* make-arr<out> arr<const-ptr<char>>(size nat64, f fun-act1<const-ptr<char>, nat64>) */
struct arr_7 make_arr_1(struct ctx* ctx, uint64_t size, struct fun_act1_28 f) {
	char** res0;
	res0 = alloc_uninitialized_10(ctx, size);
	
	fill_ptr_range_5(ctx, res0, size, f);
	return (struct arr_7) {size, ((char**) res0)};
}
/* fill-ptr-range<a> void(begin mut-ptr<const-ptr<char>>, size nat64, f fun-act1<const-ptr<char>, nat64>) */
struct void_ fill_ptr_range_5(struct ctx* ctx, char** begin, uint64_t size, struct fun_act1_28 f) {
	return fill_ptr_range_recur_5(ctx, begin, 0u, size, f);
}
/* fill-ptr-range-recur<a> void(begin mut-ptr<const-ptr<char>>, i nat64, size nat64, f fun-act1<const-ptr<char>, nat64>) */
struct void_ fill_ptr_range_recur_5(struct ctx* ctx, char** begin, uint64_t i, uint64_t size, struct fun_act1_28 f) {
	top:;
	uint8_t _0 = _notEqual_5(i, size);
	if (_0) {
		char* _1 = subscript_92(ctx, f, i);
		set_subscript_19(begin, i, _1);
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
struct void_ set_subscript_19(char** a, uint64_t n, char* value) {
	return (*(a + n) = value, (struct void_) {});
}
/* subscript<a, nat64> const-ptr<char>(a fun-act1<const-ptr<char>, nat64>, p0 nat64) */
char* subscript_92(struct ctx* ctx, struct fun_act1_28 a, uint64_t p0) {
	return call_w_ctx_1127(a, ctx, p0);
}
/* call-w-ctx<raw-ptr-const(char), nat-64> (generated) (generated) */
char* call_w_ctx_1127(struct fun_act1_28 a, struct ctx* ctx, uint64_t p0) {
	struct fun_act1_28 _0 = a;
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
char* subscript_93(struct ctx* ctx, struct fun_act1_27 a, struct str p0) {
	return call_w_ctx_1129(a, ctx, p0);
}
/* call-w-ctx<raw-ptr-const(char), str> (generated) (generated) */
char* call_w_ctx_1129(struct fun_act1_27 a, struct ctx* ctx, struct str p0) {
	struct fun_act1_27 _0 = a;
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
	return subscript_93(ctx, _closure->f, _0);
}
/* convert-args.lambda0 const-ptr<char>(x str) */
char* convert_args__lambda0(struct ctx* ctx, struct void_ _closure, struct str x) {
	return to_c_str(ctx, x);
}
/* convert-environ const-ptr<const-ptr<char>>(environ dict<str, str>) */
char** convert_environ(struct ctx* ctx, struct dict_1 environ) {
	struct mut_list_7* res0;
	res0 = mut_list_5(ctx);
	
	struct convert_environ__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct convert_environ__lambda0));
	temp0 = ((struct convert_environ__lambda0*) _0);
	
	*temp0 = (struct convert_environ__lambda0) {res0};
	each_5(ctx, environ, (struct fun_act2_12) {0, .as0 = temp0});
	char* _1 = null_1();
	_concatEquals_9(ctx, res0, _1);
	struct arr_7 _2 = move_to_arr__e_6(res0);
	return _2.begin_ptr;
}
/* mut-list<const-ptr<char>> mut-list<const-ptr<char>>() */
struct mut_list_7* mut_list_5(struct ctx* ctx) {
	struct mut_list_7* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_list_7));
	temp0 = ((struct mut_list_7*) _0);
	
	struct mut_arr_12 _1 = mut_arr_22();
	*temp0 = (struct mut_list_7) {_1, 0u};
	return temp0;
}
/* mut-arr<a> mut-arr<const-ptr<char>>() */
struct mut_arr_12 mut_arr_22(void) {
	return (struct mut_arr_12) {(struct void_) {}, (struct arr_7) {0u, NULL}};
}
/* each<str, str> void(a dict<str, str>, f fun-act2<void, str, str>) */
struct void_ each_5(struct ctx* ctx, struct dict_1 a, struct fun_act2_12 f) {
	struct each_5__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct each_5__lambda0));
	temp0 = ((struct each_5__lambda0*) _0);
	
	*temp0 = (struct each_5__lambda0) {f};
	return fold_5(ctx, (struct void_) {}, a, (struct fun_act3_1) {0, .as0 = temp0});
}
/* fold<void, k, v> void(acc void, a dict<str, str>, f fun-act3<void, void, str, str>) */
struct void_ fold_5(struct ctx* ctx, struct void_ acc, struct dict_1 a, struct fun_act3_1 f) {
	struct iters_1* iters0;
	iters0 = init_iters_1(ctx, a);
	
	return fold_recur_4(ctx, acc, iters0->end_pairs, iters0->overlays, f);
}
/* init-iters<k, v> iters<str, str>(a dict<str, str>) */
struct iters_1* init_iters_1(struct ctx* ctx, struct dict_1 a) {
	struct mut_arr_13 overlay_iters0;
	uint64_t _0 = overlay_count_1(0u, a.impl);
	overlay_iters0 = uninitialized_mut_arr_10(ctx, _0);
	
	struct arr_13 end_pairs1;
	struct arr_12* _1 = begin_ptr_18(overlay_iters0);
	end_pairs1 = init_overlay_iters_recur__e_1(_1, a.impl);
	
	struct iters_1* temp0;
	uint8_t* _2 = alloc(ctx, sizeof(struct iters_1));
	temp0 = ((struct iters_1*) _2);
	
	*temp0 = (struct iters_1) {end_pairs1, overlay_iters0};
	return temp0;
}
/* uninitialized-mut-arr<arr<arrow<k, opt<v>>>> mut-arr<arr<arrow<str, opt<str>>>>(size nat64) */
struct mut_arr_13 uninitialized_mut_arr_10(struct ctx* ctx, uint64_t size) {
	struct arr_12* _0 = alloc_uninitialized_11(ctx, size);
	return mut_arr_23(size, _0);
}
/* mut-arr<a> mut-arr<arr<arrow<str, opt<str>>>>(size nat64, begin-ptr mut-ptr<arr<arrow<str, opt<str>>>>) */
struct mut_arr_13 mut_arr_23(uint64_t size, struct arr_12* begin_ptr) {
	return (struct mut_arr_13) {(struct void_) {}, (struct arr_16) {size, ((struct arr_12*) begin_ptr)}};
}
/* alloc-uninitialized<a> mut-ptr<arr<arrow<str, opt<str>>>>(size nat64) */
struct arr_12* alloc_uninitialized_11(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(struct arr_12)));
	return ((struct arr_12*) _0);
}
/* overlay-count<k, v> nat64(acc nat64, a dict-impl<str, str>) */
uint64_t overlay_count_1(uint64_t acc, struct dict_impl_1 a) {
	top:;
	struct dict_impl_1 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct overlay_1* o0 = _0.as0;
			
			acc = (acc + 1u);
			a = o0->prev;
			goto top;
		}
		case 1: {
			return acc;
		}
		default:
			
	return 0;;
	}
}
/* init-overlay-iters-recur!<k, v> arr<arrow<str, str>>(out mut-ptr<arr<arrow<str, opt<str>>>>, a dict-impl<str, str>) */
struct arr_13 init_overlay_iters_recur__e_1(struct arr_12* out, struct dict_impl_1 a) {
	top:;
	struct dict_impl_1 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct overlay_1* o0 = _0.as0;
			
			*out = o0->pairs;
			out = (out + 1u);
			a = o0->prev;
			goto top;
		}
		case 1: {
			struct end_node_1 e1 = _0.as1;
			
			return e1.pairs;
		}
		default:
			
	return (struct arr_13) {0, NULL};;
	}
}
/* begin-ptr<arr<arrow<k, opt<v>>>> mut-ptr<arr<arrow<str, opt<str>>>>(a mut-arr<arr<arrow<str, opt<str>>>>) */
struct arr_12* begin_ptr_18(struct mut_arr_13 a) {
	return ((struct arr_12*) a.inner.begin_ptr);
}
/* fold-recur<a, k, v> void(acc void, end-node arr<arrow<str, str>>, overlays mut-arr<arr<arrow<str, opt<str>>>>, f fun-act3<void, void, str, str>) */
struct void_ fold_recur_4(struct ctx* ctx, struct void_ acc, struct arr_13 end_node, struct mut_arr_13 overlays, struct fun_act3_1 f) {
	top:;
	uint8_t _0 = is_empty_20(overlays);
	if (_0) {
		struct fold_recur_4__lambda0* temp0;
		uint8_t* _1 = alloc(ctx, sizeof(struct fold_recur_4__lambda0));
		temp0 = ((struct fold_recur_4__lambda0*) _1);
		
		*temp0 = (struct fold_recur_4__lambda0) {f};
		return fold_6(ctx, acc, end_node, (struct fun_act2_13) {0, .as0 = temp0});
	} else {
		struct str least_key0;
		uint8_t _2 = is_empty_21(end_node);
		if (_2) {
			struct arr_12 _3 = subscript_99(ctx, overlays, 0u);
			struct arrow_3 _4 = subscript_97(ctx, _3, 0u);
			struct mut_arr_13 _5 = tail_5(ctx, overlays);
			least_key0 = find_least_key_1(ctx, _4.from, _5);
		} else {
			struct arrow_4 _6 = subscript_71(ctx, end_node, 0u);
			least_key0 = find_least_key_1(ctx, _6.from, overlays);
		}
		
		uint8_t take_from_end_node1;
		uint8_t _7 = is_empty_21(end_node);
		uint8_t _8 = _not(_7);
		if (_8) {
			struct arrow_4 _9 = subscript_71(ctx, end_node, 0u);
			take_from_end_node1 = _equal_5(least_key0, _9.from);
		} else {
			take_from_end_node1 = 0;
		}
		
		struct opt_15 val_from_end_node2;
		uint8_t _10 = take_from_end_node1;
		if (_10) {
			struct arrow_4 _11 = subscript_71(ctx, end_node, 0u);
			val_from_end_node2 = (struct opt_15) {1, .as1 = (struct some_15) {_11.to}};
		} else {
			val_from_end_node2 = (struct opt_15) {0, .as0 = (struct none) {}};
		}
		
		struct arr_13 new_end_node3;
		uint8_t _12 = take_from_end_node1;
		if (_12) {
			new_end_node3 = tail_6(ctx, end_node);
		} else {
			new_end_node3 = end_node;
		}
		
		struct took_key_1* took_from_overlays4;
		took_from_overlays4 = take_key_1(ctx, overlays, least_key0);
		
		struct void_ new_acc7;
		struct opt_15 _13 = opt_or_1(ctx, took_from_overlays4->rightmost_value, val_from_end_node2);
		switch (_13.kind) {
			case 0: {
				new_acc7 = acc;
				break;
			}
			case 1: {
				struct some_15 _matched5 = _13.as1;
				
				struct str val6;
				val6 = _matched5.value;
				
				new_acc7 = subscript_95(ctx, f, acc, least_key0, val6);
				break;
			}
			default:
				
		new_acc7 = (struct void_) {};;
		}
		
		acc = new_acc7;
		end_node = new_end_node3;
		overlays = took_from_overlays4->overlays;
		f = f;
		goto top;
	}
}
/* is-empty<arr<arrow<k, opt<v>>>> bool(a mut-arr<arr<arrow<str, opt<str>>>>) */
uint8_t is_empty_20(struct mut_arr_13 a) {
	uint64_t _0 = size_11(a);
	return (_0 == 0u);
}
/* size<a> nat64(a mut-arr<arr<arrow<str, opt<str>>>>) */
uint64_t size_11(struct mut_arr_13 a) {
	return a.inner.size;
}
/* fold<a, arrow<k, v>> void(acc void, a arr<arrow<str, str>>, f fun-act2<void, void, arrow<str, str>>) */
struct void_ fold_6(struct ctx* ctx, struct void_ acc, struct arr_13 a, struct fun_act2_13 f) {
	struct arrow_4* _0 = end_ptr_13(a);
	return fold_recur_5(ctx, acc, a.begin_ptr, _0, f);
}
/* fold-recur<a, b> void(acc void, cur const-ptr<arrow<str, str>>, end const-ptr<arrow<str, str>>, f fun-act2<void, void, arrow<str, str>>) */
struct void_ fold_recur_5(struct ctx* ctx, struct void_ acc, struct arrow_4* cur, struct arrow_4* end, struct fun_act2_13 f) {
	top:;
	uint8_t _0 = _equal_14(cur, end);
	if (_0) {
		return acc;
	} else {
		struct arrow_4 _1 = _times_17(cur);
		struct void_ _2 = subscript_94(ctx, f, acc, _1);
		struct arrow_4* _3 = _plus_14(cur, 1u);
		acc = _2;
		cur = _3;
		end = end;
		f = f;
		goto top;
	}
}
/* ==<b> bool(a const-ptr<arrow<str, str>>, b const-ptr<arrow<str, str>>) */
uint8_t _equal_14(struct arrow_4* a, struct arrow_4* b) {
	return (((struct arrow_4*) a) == ((struct arrow_4*) b));
}
/* subscript<a, a, b> void(a fun-act2<void, void, arrow<str, str>>, p0 void, p1 arrow<str, str>) */
struct void_ subscript_94(struct ctx* ctx, struct fun_act2_13 a, struct void_ p0, struct arrow_4 p1) {
	return call_w_ctx_1151(a, ctx, p0, p1);
}
/* call-w-ctx<void, void, arrow<str, str>> (generated) (generated) */
struct void_ call_w_ctx_1151(struct fun_act2_13 a, struct ctx* ctx, struct void_ p0, struct arrow_4 p1) {
	struct fun_act2_13 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct fold_recur_4__lambda0* closure0 = _0.as0;
			
			return fold_recur_4__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* end-ptr<b> const-ptr<arrow<str, str>>(a arr<arrow<str, str>>) */
struct arrow_4* end_ptr_13(struct arr_13 a) {
	return _plus_14(a.begin_ptr, a.size);
}
/* subscript<a, a, k, v> void(a fun-act3<void, void, str, str>, p0 void, p1 str, p2 str) */
struct void_ subscript_95(struct ctx* ctx, struct fun_act3_1 a, struct void_ p0, struct str p1, struct str p2) {
	return call_w_ctx_1154(a, ctx, p0, p1, p2);
}
/* call-w-ctx<void, void, str, str> (generated) (generated) */
struct void_ call_w_ctx_1154(struct fun_act3_1 a, struct ctx* ctx, struct void_ p0, struct str p1, struct str p2) {
	struct fun_act3_1 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct each_5__lambda0* closure0 = _0.as0;
			
			return each_5__lambda0(ctx, closure0, p0, p1, p2);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* fold-recur<a, k, v>.lambda0 void(cur void, pair arrow<str, str>) */
struct void_ fold_recur_4__lambda0(struct ctx* ctx, struct fold_recur_4__lambda0* _closure, struct void_ cur, struct arrow_4 pair) {
	return subscript_95(ctx, _closure->f, cur, pair.from, pair.to);
}
/* is-empty<arrow<k, v>> bool(a arr<arrow<str, str>>) */
uint8_t is_empty_21(struct arr_13 a) {
	return (a.size == 0u);
}
/* find-least-key<k, opt<v>> str(current-least-key str, overlays mut-arr<arr<arrow<str, opt<str>>>>) */
struct str find_least_key_1(struct ctx* ctx, struct str current_least_key, struct mut_arr_13 overlays) {
	return fold_7(ctx, current_least_key, overlays, (struct fun_act2_14) {0, .as0 = (struct void_) {}});
}
/* fold<k, arr<arrow<k, v>>> str(acc str, a mut-arr<arr<arrow<str, opt<str>>>>, f fun-act2<str, str, arr<arrow<str, opt<str>>>>) */
struct str fold_7(struct ctx* ctx, struct str acc, struct mut_arr_13 a, struct fun_act2_14 f) {
	struct arr_16 _0 = temp_as_arr_3(a);
	return fold_8(ctx, acc, _0, f);
}
/* fold<a, b> str(acc str, a arr<arr<arrow<str, opt<str>>>>, f fun-act2<str, str, arr<arrow<str, opt<str>>>>) */
struct str fold_8(struct ctx* ctx, struct str acc, struct arr_16 a, struct fun_act2_14 f) {
	struct arr_12* _0 = end_ptr_14(a);
	return fold_recur_6(ctx, acc, a.begin_ptr, _0, f);
}
/* fold-recur<a, b> str(acc str, cur const-ptr<arr<arrow<str, opt<str>>>>, end const-ptr<arr<arrow<str, opt<str>>>>, f fun-act2<str, str, arr<arrow<str, opt<str>>>>) */
struct str fold_recur_6(struct ctx* ctx, struct str acc, struct arr_12* cur, struct arr_12* end, struct fun_act2_14 f) {
	top:;
	uint8_t _0 = _equal_15(cur, end);
	if (_0) {
		return acc;
	} else {
		struct arr_12 _1 = _times_23(cur);
		struct str _2 = subscript_96(ctx, f, acc, _1);
		struct arr_12* _3 = _plus_18(cur, 1u);
		acc = _2;
		cur = _3;
		end = end;
		f = f;
		goto top;
	}
}
/* ==<b> bool(a const-ptr<arr<arrow<str, opt<str>>>>, b const-ptr<arr<arrow<str, opt<str>>>>) */
uint8_t _equal_15(struct arr_12* a, struct arr_12* b) {
	return (((struct arr_12*) a) == ((struct arr_12*) b));
}
/* subscript<a, a, b> str(a fun-act2<str, str, arr<arrow<str, opt<str>>>>, p0 str, p1 arr<arrow<str, opt<str>>>) */
struct str subscript_96(struct ctx* ctx, struct fun_act2_14 a, struct str p0, struct arr_12 p1) {
	return call_w_ctx_1163(a, ctx, p0, p1);
}
/* call-w-ctx<str, str, arr<arrow<str, opt<str>>>> (generated) (generated) */
struct str call_w_ctx_1163(struct fun_act2_14 a, struct ctx* ctx, struct str p0, struct arr_12 p1) {
	struct fun_act2_14 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return find_least_key_1__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return (struct str) {(struct arr_0) {0, NULL}};;
	}
}
/* *<b> arr<arrow<str, opt<str>>>(a const-ptr<arr<arrow<str, opt<str>>>>) */
struct arr_12 _times_23(struct arr_12* a) {
	return (*((struct arr_12*) a));
}
/* +<b> const-ptr<arr<arrow<str, opt<str>>>>(a const-ptr<arr<arrow<str, opt<str>>>>, offset nat64) */
struct arr_12* _plus_18(struct arr_12* a, uint64_t offset) {
	return ((struct arr_12*) (((struct arr_12*) a) + offset));
}
/* end-ptr<b> const-ptr<arr<arrow<str, opt<str>>>>(a arr<arr<arrow<str, opt<str>>>>) */
struct arr_12* end_ptr_14(struct arr_16 a) {
	return _plus_18(a.begin_ptr, a.size);
}
/* temp-as-arr<b> arr<arr<arrow<str, opt<str>>>>(a mut-arr<arr<arrow<str, opt<str>>>>) */
struct arr_16 temp_as_arr_3(struct mut_arr_13 a) {
	return a.inner;
}
/* subscript<arrow<k, v>> arrow<str, opt<str>>(a arr<arrow<str, opt<str>>>, index nat64) */
struct arrow_3 subscript_97(struct ctx* ctx, struct arr_12 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	return unsafe_at_11(a, index);
}
/* unsafe-at<a> arrow<str, opt<str>>(a arr<arrow<str, opt<str>>>, index nat64) */
struct arrow_3 unsafe_at_11(struct arr_12 a, uint64_t index) {
	return subscript_98(a.begin_ptr, index);
}
/* subscript<a> arrow<str, opt<str>>(a const-ptr<arrow<str, opt<str>>>, n nat64) */
struct arrow_3 subscript_98(struct arrow_3* a, uint64_t n) {
	struct arrow_3* _0 = _plus_13(a, n);
	return _times_16(_0);
}
/* find-least-key<k, opt<v>>.lambda0 str(cur str, overlay arr<arrow<str, opt<str>>>) */
struct str find_least_key_1__lambda0(struct ctx* ctx, struct void_ _closure, struct str cur, struct arr_12 overlay) {
	struct arrow_3 _0 = subscript_97(ctx, overlay, 0u);
	return min_1(cur, _0.from);
}
/* subscript<arr<arrow<k, opt<v>>>> arr<arrow<str, opt<str>>>(a mut-arr<arr<arrow<str, opt<str>>>>, index nat64) */
struct arr_12 subscript_99(struct ctx* ctx, struct mut_arr_13 a, uint64_t index) {
	uint64_t _0 = size_11(a);
	uint8_t _1 = _less_0(index, _0);
	assert_0(ctx, _1);
	return unsafe_at_12(ctx, a, index);
}
/* unsafe-at<a> arr<arrow<str, opt<str>>>(a mut-arr<arr<arrow<str, opt<str>>>>, index nat64) */
struct arr_12 unsafe_at_12(struct ctx* ctx, struct mut_arr_13 a, uint64_t index) {
	struct arr_12* _0 = begin_ptr_18(a);
	return subscript_100(_0, index);
}
/* subscript<a> arr<arrow<str, opt<str>>>(a mut-ptr<arr<arrow<str, opt<str>>>>, n nat64) */
struct arr_12 subscript_100(struct arr_12* a, uint64_t n) {
	return (*(a + n));
}
/* tail<arr<arrow<k, opt<v>>>> mut-arr<arr<arrow<str, opt<str>>>>(a mut-arr<arr<arrow<str, opt<str>>>>) */
struct mut_arr_13 tail_5(struct ctx* ctx, struct mut_arr_13 a) {
	uint8_t _0 = is_empty_20(a);
	forbid(ctx, _0);
	uint64_t _1 = size_11(a);
	struct arrow_0 _2 = _arrow_0(1u, _1);
	return subscript_101(ctx, a, _2);
}
/* subscript<a> mut-arr<arr<arrow<str, opt<str>>>>(a mut-arr<arr<arrow<str, opt<str>>>>, range arrow<nat64, nat64>) */
struct mut_arr_13 subscript_101(struct ctx* ctx, struct mut_arr_13 a, struct arrow_0 range) {
	uint8_t _0 = _lessOrEqual_0(range.from, range.to);
	assert_0(ctx, _0);
	uint64_t _1 = size_11(a);
	uint8_t _2 = _lessOrEqual_0(range.to, _1);
	assert_0(ctx, _2);
	struct arr_16 _3 = subscript_102(ctx, a.inner, range);
	return (struct mut_arr_13) {(struct void_) {}, _3};
}
/* subscript<a> arr<arr<arrow<str, opt<str>>>>(a arr<arr<arrow<str, opt<str>>>>, range arrow<nat64, nat64>) */
struct arr_16 subscript_102(struct ctx* ctx, struct arr_16 a, struct arrow_0 range) {
	uint8_t _0 = _lessOrEqual_0(range.from, range.to);
	assert_0(ctx, _0);
	uint8_t _1 = _lessOrEqual_0(range.to, a.size);
	assert_0(ctx, _1);
	struct arr_12* _2 = _plus_18(a.begin_ptr, range.from);
	return (struct arr_16) {(range.to - range.from), _2};
}
/* tail<arrow<k, v>> arr<arrow<str, str>>(a arr<arrow<str, str>>) */
struct arr_13 tail_6(struct ctx* ctx, struct arr_13 a) {
	uint8_t _0 = is_empty_21(a);
	forbid(ctx, _0);
	struct arrow_0 _1 = _arrow_0(1u, a.size);
	return subscript_103(ctx, a, _1);
}
/* subscript<a> arr<arrow<str, str>>(a arr<arrow<str, str>>, range arrow<nat64, nat64>) */
struct arr_13 subscript_103(struct ctx* ctx, struct arr_13 a, struct arrow_0 range) {
	uint8_t _0 = _lessOrEqual_0(range.from, range.to);
	assert_0(ctx, _0);
	uint8_t _1 = _lessOrEqual_0(range.to, a.size);
	assert_0(ctx, _1);
	struct arrow_4* _2 = _plus_14(a.begin_ptr, range.from);
	return (struct arr_13) {(range.to - range.from), _2};
}
/* take-key<k, v> took-key<str, str>(overlays mut-arr<arr<arrow<str, opt<str>>>>, key str) */
struct took_key_1* take_key_1(struct ctx* ctx, struct mut_arr_13 overlays, struct str key) {
	return take_key_recur_1(ctx, overlays, key, 0u, (struct opt_15) {0, .as0 = (struct none) {}});
}
/* take-key-recur<k, v> took-key<str, str>(overlays mut-arr<arr<arrow<str, opt<str>>>>, key str, index nat64, rightmost-value opt<str>) */
struct took_key_1* take_key_recur_1(struct ctx* ctx, struct mut_arr_13 overlays, struct str key, uint64_t index, struct opt_15 rightmost_value) {
	top:;
	uint64_t _0 = size_11(overlays);
	uint8_t _1 = _greaterOrEqual(index, _0);
	if (_1) {
		struct took_key_1* temp0;
		uint8_t* _2 = alloc(ctx, sizeof(struct took_key_1));
		temp0 = ((struct took_key_1*) _2);
		
		*temp0 = (struct took_key_1) {rightmost_value, overlays};
		return temp0;
	} else {
		struct arr_12 _3 = subscript_99(ctx, overlays, index);
		struct arrow_3 _4 = subscript_97(ctx, _3, 0u);
		uint8_t _5 = _equal_5(_4.from, key);
		if (_5) {
			struct opt_15 new_rightmost_value0;
			struct arr_12 _6 = subscript_99(ctx, overlays, index);
			struct arrow_3 _7 = subscript_97(ctx, _6, 0u);
			new_rightmost_value0 = _7.to;
			
			struct arr_12 new_overlay1;
			struct arr_12 _8 = subscript_99(ctx, overlays, index);
			new_overlay1 = tail_7(ctx, _8);
			
			uint8_t _9 = is_empty_22(new_overlay1);
			if (_9) {
				uint64_t _10 = size_11(overlays);
				uint64_t _11 = _minus_7(ctx, _10, 1u);
				struct arr_12 _12 = subscript_99(ctx, overlays, _11);
				set_subscript_20(ctx, overlays, index, _12);
				uint64_t _13 = size_11(overlays);
				uint64_t _14 = _minus_7(ctx, _13, 1u);
				struct arrow_0 _15 = _arrow_0(0u, _14);
				struct mut_arr_13 _16 = subscript_101(ctx, overlays, _15);
				uint64_t _17 = _plus_3(ctx, index, 1u);
				overlays = _16;
				key = key;
				index = _17;
				rightmost_value = new_rightmost_value0;
				goto top;
			} else {
				set_subscript_20(ctx, overlays, index, new_overlay1);
				uint64_t _18 = _plus_3(ctx, index, 1u);
				overlays = overlays;
				key = key;
				index = _18;
				rightmost_value = new_rightmost_value0;
				goto top;
			}
		} else {
			uint64_t _19 = _plus_3(ctx, index, 1u);
			overlays = overlays;
			key = key;
			index = _19;
			rightmost_value = rightmost_value;
			goto top;
		}
	}
}
/* tail<arrow<k, opt<v>>> arr<arrow<str, opt<str>>>(a arr<arrow<str, opt<str>>>) */
struct arr_12 tail_7(struct ctx* ctx, struct arr_12 a) {
	uint8_t _0 = is_empty_22(a);
	forbid(ctx, _0);
	struct arrow_0 _1 = _arrow_0(1u, a.size);
	return subscript_65(ctx, a, _1);
}
/* is-empty<a> bool(a arr<arrow<str, opt<str>>>) */
uint8_t is_empty_22(struct arr_12 a) {
	return (a.size == 0u);
}
/* set-subscript<arr<arrow<k, opt<v>>>> void(a mut-arr<arr<arrow<str, opt<str>>>>, index nat64, value arr<arrow<str, opt<str>>>) */
struct void_ set_subscript_20(struct ctx* ctx, struct mut_arr_13 a, uint64_t index, struct arr_12 value) {
	uint64_t _0 = size_11(a);
	uint8_t _1 = _less_0(index, _0);
	assert_0(ctx, _1);
	return unsafe_set_at__e_1(ctx, a, index, value);
}
/* unsafe-set-at!<a> void(a mut-arr<arr<arrow<str, opt<str>>>>, index nat64, value arr<arrow<str, opt<str>>>) */
struct void_ unsafe_set_at__e_1(struct ctx* ctx, struct mut_arr_13 a, uint64_t index, struct arr_12 value) {
	struct arr_12* _0 = begin_ptr_18(a);
	return set_subscript_21(_0, index, value);
}
/* set-subscript<a> void(a mut-ptr<arr<arrow<str, opt<str>>>>, n nat64, value arr<arrow<str, opt<str>>>) */
struct void_ set_subscript_21(struct arr_12* a, uint64_t n, struct arr_12 value) {
	return (*(a + n) = value, (struct void_) {});
}
/* opt-or<v> opt<str>(a opt<str>, b opt<str>) */
struct opt_15 opt_or_1(struct ctx* ctx, struct opt_15 a, struct opt_15 b) {
	uint8_t _0 = is_empty_14(a);
	if (_0) {
		return b;
	} else {
		return a;
	}
}
/* subscript<void, k, v> void(a fun-act2<void, str, str>, p0 str, p1 str) */
struct void_ subscript_104(struct ctx* ctx, struct fun_act2_12 a, struct str p0, struct str p1) {
	return call_w_ctx_1189(a, ctx, p0, p1);
}
/* call-w-ctx<void, str, str> (generated) (generated) */
struct void_ call_w_ctx_1189(struct fun_act2_12 a, struct ctx* ctx, struct str p0, struct str p1) {
	struct fun_act2_12 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct convert_environ__lambda0* closure0 = _0.as0;
			
			return convert_environ__lambda0(ctx, closure0, p0, p1);
		}
		default:
			
	return (struct void_) {};;
	}
}
/* each<str, str>.lambda0 void(ignore void, k str, v str) */
struct void_ each_5__lambda0(struct ctx* ctx, struct each_5__lambda0* _closure, struct void_ ignore, struct str k, struct str v) {
	return subscript_104(ctx, _closure->f, k, v);
}
/* ~=<const-ptr<char>> void(a mut-list<const-ptr<char>>, value const-ptr<char>) */
struct void_ _concatEquals_9(struct ctx* ctx, struct mut_list_7* a, char* value) {
	incr_capacity__e_5(ctx, a);
	uint64_t _0 = capacity_6(a);
	uint8_t _1 = _less_0(a->size, _0);
	assert_0(ctx, _1);
	char** _2 = begin_ptr_19(a);
	set_subscript_19(_2, a->size, value);
	uint64_t _3 = _plus_3(ctx, a->size, 1u);
	return (a->size = _3, (struct void_) {});
}
/* incr-capacity!<a> void(a mut-list<const-ptr<char>>) */
struct void_ incr_capacity__e_5(struct ctx* ctx, struct mut_list_7* a) {
	uint64_t _0 = _plus_3(ctx, a->size, 1u);
	uint64_t _1 = round_up_to_power_of_two(ctx, _0);
	return ensure_capacity_5(ctx, a, _1);
}
/* ensure-capacity<a> void(a mut-list<const-ptr<char>>, min-capacity nat64) */
struct void_ ensure_capacity_5(struct ctx* ctx, struct mut_list_7* a, uint64_t min_capacity) {
	uint64_t _0 = capacity_6(a);
	uint8_t _1 = _less_0(_0, min_capacity);
	if (_1) {
		return increase_capacity_to__e_5(ctx, a, min_capacity);
	} else {
		return (struct void_) {};
	}
}
/* capacity<a> nat64(a mut-list<const-ptr<char>>) */
uint64_t capacity_6(struct mut_list_7* a) {
	return size_12(a->backing);
}
/* size<a> nat64(a mut-arr<const-ptr<char>>) */
uint64_t size_12(struct mut_arr_12 a) {
	return a.inner.size;
}
/* increase-capacity-to!<a> void(a mut-list<const-ptr<char>>, new-capacity nat64) */
struct void_ increase_capacity_to__e_5(struct ctx* ctx, struct mut_list_7* a, uint64_t new_capacity) {
	uint64_t _0 = capacity_6(a);
	uint8_t _1 = _greater_0(new_capacity, _0);
	assert_0(ctx, _1);
	char** old_begin0;
	old_begin0 = begin_ptr_19(a);
	
	struct mut_arr_12 _2 = uninitialized_mut_arr_11(ctx, new_capacity);
	a->backing = _2;
	char** _3 = begin_ptr_19(a);
	copy_data_from__e_6(ctx, _3, ((char**) old_begin0), a->size);
	uint64_t _4 = _plus_3(ctx, a->size, 1u);
	uint64_t _5 = size_12(a->backing);
	struct arrow_0 _6 = _arrow_0(_4, _5);
	struct mut_arr_12 _7 = subscript_105(ctx, a->backing, _6);
	return set_zero_elements_5(_7);
}
/* begin-ptr<a> mut-ptr<const-ptr<char>>(a mut-list<const-ptr<char>>) */
char** begin_ptr_19(struct mut_list_7* a) {
	return begin_ptr_20(a->backing);
}
/* begin-ptr<a> mut-ptr<const-ptr<char>>(a mut-arr<const-ptr<char>>) */
char** begin_ptr_20(struct mut_arr_12 a) {
	return ((char**) a.inner.begin_ptr);
}
/* uninitialized-mut-arr<a> mut-arr<const-ptr<char>>(size nat64) */
struct mut_arr_12 uninitialized_mut_arr_11(struct ctx* ctx, uint64_t size) {
	char** _0 = alloc_uninitialized_10(ctx, size);
	return mut_arr_24(size, _0);
}
/* mut-arr<a> mut-arr<const-ptr<char>>(size nat64, begin-ptr mut-ptr<const-ptr<char>>) */
struct mut_arr_12 mut_arr_24(uint64_t size, char** begin_ptr) {
	return (struct mut_arr_12) {(struct void_) {}, (struct arr_7) {size, ((char**) begin_ptr)}};
}
/* set-zero-elements<a> void(a mut-arr<const-ptr<char>>) */
struct void_ set_zero_elements_5(struct mut_arr_12 a) {
	char** _0 = begin_ptr_20(a);
	uint64_t _1 = size_12(a);
	return set_zero_range_6(_0, _1);
}
/* set-zero-range<a> void(begin mut-ptr<const-ptr<char>>, size nat64) */
struct void_ set_zero_range_6(char** begin, uint64_t size) {
	uint8_t* _0 = memset(((uint8_t*) begin), 0, (size * sizeof(char*)));
	return drop_0(_0);
}
/* subscript<a> mut-arr<const-ptr<char>>(a mut-arr<const-ptr<char>>, range arrow<nat64, nat64>) */
struct mut_arr_12 subscript_105(struct ctx* ctx, struct mut_arr_12 a, struct arrow_0 range) {
	uint8_t _0 = _lessOrEqual_0(range.from, range.to);
	assert_0(ctx, _0);
	uint64_t _1 = size_12(a);
	uint8_t _2 = _lessOrEqual_0(range.to, _1);
	assert_0(ctx, _2);
	struct arr_7 _3 = subscript_17(ctx, a.inner, range);
	return (struct mut_arr_12) {(struct void_) {}, _3};
}
/* convert-environ.lambda0 void(key str, value str) */
struct void_ convert_environ__lambda0(struct ctx* ctx, struct convert_environ__lambda0* _closure, struct str key, struct str value) {
	struct str _0 = _tilde_0(ctx, key, (struct str) {{1, constantarr_0_59}});
	struct str _1 = _tilde_0(ctx, _0, value);
	char* _2 = to_c_str(ctx, _1);
	return _concatEquals_9(ctx, _closure->res, _2);
}
/* move-to-arr!<const-ptr<char>> arr<const-ptr<char>>(a mut-list<const-ptr<char>>) */
struct arr_7 move_to_arr__e_6(struct mut_list_7* a) {
	struct mut_arr_12 _0 = move_to_mut_arr__e_4(a);
	return cast_immutable_6(_0);
}
/* cast-immutable<a> arr<const-ptr<char>>(a mut-arr<const-ptr<char>>) */
struct arr_7 cast_immutable_6(struct mut_arr_12 a) {
	return a.inner;
}
/* move-to-mut-arr!<a> mut-arr<const-ptr<char>>(a mut-list<const-ptr<char>>) */
struct mut_arr_12 move_to_mut_arr__e_4(struct mut_list_7* a) {
	struct mut_arr_12 res0;
	char** _0 = begin_ptr_19(a);
	res0 = mut_arr_24(a->size, _0);
	
	struct mut_arr_12 _1 = mut_arr_22();
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
struct arr_14 handle_output(struct ctx* ctx, struct str original_path, struct str output_path, struct str actual, uint8_t overwrite_output) {
	struct opt_15 _0 = try_read_file_0(ctx, output_path);
	switch (_0.kind) {
		case 0: {
			uint8_t _1 = overwrite_output;
			if (_1) {
				write_file_0(ctx, output_path, actual);
				return (struct arr_14) {0u, NULL};
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
				return (struct arr_14) {1u, temp0};
			}
		}
		case 1: {
			struct some_15 _matched0 = _0.as1;
			
			struct str text1;
			text1 = _matched0.value;
			
			uint8_t _10 = _equal_5(text1, actual);
			if (_10) {
				return (struct arr_14) {0u, NULL};
			} else {
				uint8_t _11 = overwrite_output;
				if (_11) {
					write_file_0(ctx, output_path, actual);
					return (struct arr_14) {0u, NULL};
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
					return (struct arr_14) {1u, temp2};
				}
			}
		}
		default:
			
	return (struct arr_14) {0, NULL};;
	}
}
/* try-read-file opt<str>(path str) */
struct opt_15 try_read_file_0(struct ctx* ctx, struct str path) {
	char* _0 = to_c_str(ctx, path);
	return try_read_file_1(ctx, _0);
}
/* try-read-file opt<str>(path const-ptr<char>) */
struct opt_15 try_read_file_1(struct ctx* ctx, char* path) {
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
				return (struct opt_15) {0, .as0 = (struct none) {}};
			}
		} else {
			int64_t file_size1;
			int32_t _10 = seek_end(ctx);
			file_size1 = lseek(fd0, 0, _10);
			
			forbid(ctx, (file_size1 == -1));
			uint8_t _11 = _less_11(file_size1, 1000000000);
			assert_0(ctx, _11);
			uint8_t _12 = (file_size1 == 0);
			if (_12) {
				return (struct opt_15) {1, .as1 = (struct some_15) {(struct str) {{0u, NULL}}}};
			} else {
				int64_t off2;
				int32_t _13 = seek_set(ctx);
				off2 = lseek(fd0, 0, _13);
				
				assert_0(ctx, (off2 == 0));
				uint64_t file_size_nat3;
				file_size_nat3 = to_nat64_0(ctx, file_size1);
				
				struct mut_arr_1 res4;
				res4 = uninitialized_mut_arr_0(ctx, file_size_nat3);
				
				int64_t n_bytes_read5;
				char* _14 = begin_ptr_1(res4);
				n_bytes_read5 = read(fd0, ((uint8_t*) _14), file_size_nat3);
				
				forbid(ctx, (n_bytes_read5 == -1));
				assert_0(ctx, (n_bytes_read5 == file_size1));
				int32_t _15 = close(fd0);
				check_posix_error(ctx, _15);
				struct arr_0 _16 = cast_immutable_0(res4);
				return (struct opt_15) {1, .as1 = (struct some_15) {(struct str) {_16}}};
			}
		}
	} else {
		return (struct opt_15) {0, .as0 = (struct none) {}};
	}
}
/* O_RDONLY int32() */
int32_t O_RDONLY(void) {
	return 0;
}
/* todo<opt<str>> opt<str>() */
struct opt_15 todo_6(void) {
	(abort(), (struct void_) {});
	return (struct opt_15) {0};
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
	uint32_t permission_rdwr0;
	permission_rdwr0 = 6u;
	
	uint32_t permission_rd1;
	permission_rd1 = 4u;
	
	uint32_t permission2;
	uint32_t _0 = _shiftLeft(permission_rdwr0, 6u);
	uint32_t _1 = _shiftLeft(permission_rd1, 3u);
	permission2 = ((_0 | _1) | permission_rd1);
	
	int32_t flags3;
	int32_t _2 = O_CREAT();
	int32_t _3 = O_WRONLY();
	int32_t _4 = O_TRUNC();
	flags3 = ((_2 | _3) | _4);
	
	int32_t fd4;
	fd4 = open(path, flags3, permission2);
	
	uint8_t _5 = (fd4 == -1);
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
		struct interp _17 = with_value_2(ctx, _16, flags3);
		struct str _18 = finish(ctx, _17);
		print(_18);
		struct interp _19 = interp(ctx);
		struct interp _20 = with_str(ctx, _19, (struct str) {{12, constantarr_0_67}});
		struct interp _21 = with_value_3(ctx, _20, permission2);
		struct str _22 = finish(ctx, _21);
		print(_22);
		return todo_0();
	} else {
		int64_t wrote_bytes5;
		uint8_t* _23 = ptr_cast_2(content.chars.begin_ptr);
		uint64_t _24 = size_bytes(content);
		wrote_bytes5 = write(fd4, _23, _24);
		
		uint64_t _25 = size_bytes(content);
		int64_t _26 = to_int64(ctx, _25);
		uint8_t _27 = _notEqual_1(wrote_bytes5, _26);
		if (_27) {
			uint8_t _28 = (wrote_bytes5 == -1);
			if (_28) {
				todo_0();
			} else {
				todo_0();
			}
		} else {
			(struct void_) {};
		}
		int32_t err6;
		err6 = close(fd4);
		
		uint8_t _29 = _notEqual_6(err6, 0);
		if (_29) {
			return todo_0();
		} else {
			return (struct void_) {};
		}
	}
}
/* << nat32(a nat32, b nat32) */
uint32_t _shiftLeft(uint32_t a, uint32_t b) {
	uint8_t _0 = _less_13(b, 32u);
	if (_0) {
		return ((uint32_t) (((uint64_t) a) << ((uint64_t) b)));
	} else {
		return 0u;
	}
}
/* <=> comparison(a nat32, b nat32) */
struct comparison _compare_17(uint32_t a, uint32_t b) {
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
uint8_t _less_13(uint32_t a, uint32_t b) {
	struct comparison _0 = _compare_17(a, b);
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
uint8_t is_empty_23(struct arr_14 a) {
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
		struct opt_15 _1 = try_remove_start_0(ctx, s, (struct str) {{1, constantarr_0_70}});
		switch (_1.kind) {
			case 0: {
				char _2 = subscript_61(ctx, s.chars, 0u);
				_concatEquals_10(ctx, out, _2);
				struct arr_0 _3 = tail_8(ctx, s.chars);
				s = (struct str) {_3};
				out = out;
				goto top;
			}
			case 1: {
				struct some_15 _matched0 = _1.as1;
				
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
struct void_ _concatEquals_10(struct ctx* ctx, struct writer a, char b) {
	return _concatEquals_2(ctx, a.chars, b);
}
/* tail<char> arr<char>(a arr<char>) */
struct arr_0 tail_8(struct ctx* ctx, struct arr_0 a) {
	uint8_t _0 = is_empty_1(a);
	forbid(ctx, _0);
	struct arrow_0 _1 = _arrow_0(1u, a.size);
	return subscript_4(ctx, a, _1);
}
/* remove-colors-recur-2! void(s str, out writer) */
struct void_ remove_colors_recur_2__e(struct ctx* ctx, struct str s, struct writer out) {
	top:;
	uint8_t _0 = is_empty_0(s);
	if (_0) {
		return (struct void_) {};
	} else {
		struct opt_15 _1 = try_remove_start_0(ctx, s, (struct str) {{1, constantarr_0_71}});
		switch (_1.kind) {
			case 0: {
				struct arr_0 _2 = tail_8(ctx, s.chars);
				s = (struct str) {_2};
				out = out;
				goto top;
			}
			case 1: {
				struct some_15 _matched0 = _1.as1;
				
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
struct opt_22 run_single_crow_test__lambda0(struct ctx* ctx, struct run_single_crow_test__lambda0* _closure, struct str print_kind) {
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
		return (struct opt_22) {1, .as1 = (struct some_22) {res0->failures}};
	} else {
		return (struct opt_22) {0, .as0 = (struct none) {}};
	}
}
/* run-single-runnable-test arr<failure>(path-to-crow str, env dict<str, str>, path str, interpret bool, overwrite-output bool) */
struct arr_14 run_single_runnable_test(struct ctx* ctx, struct str path_to_crow, struct dict_1 env, struct str path, uint8_t interpret, uint8_t overwrite_output) {
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
	
	struct arr_14 stdout_failures2;
	struct interp _7 = interp(ctx);
	struct interp _8 = with_value_0(ctx, _7, path);
	struct interp _9 = with_str(ctx, _8, (struct str) {{7, constantarr_0_79}});
	struct str _10 = finish(ctx, _9);
	stdout_failures2 = handle_output(ctx, path, _10, res1->stdout, overwrite_output);
	
	struct arr_14 stderr_failures3;uint8_t _11;
	
	if ((res1->exit_code == 0)) {
		_11 = _equal_5(res1->stderr, (struct str) {{0u, NULL}});
	} else {
		_11 = 0;
	}
	if (_11) {
		stderr_failures3 = (struct arr_14) {0u, NULL};
	} else {
		struct interp _12 = interp(ctx);
		struct interp _13 = with_value_0(ctx, _12, path);
		struct interp _14 = with_str(ctx, _13, (struct str) {{7, constantarr_0_80}});
		struct str _15 = finish(ctx, _14);
		stderr_failures3 = handle_output(ctx, path, _15, res1->stderr, overwrite_output);
	}
	
	return _tilde_3(ctx, stdout_failures2, stderr_failures3);
}
/* ~<failure> arr<failure>(a arr<failure>, b arr<failure>) */
struct arr_14 _tilde_3(struct ctx* ctx, struct arr_14 a, struct arr_14 b) {
	uint64_t res_size0;
	res_size0 = (a.size + b.size);
	
	struct failure** res1;
	res1 = alloc_uninitialized_8(ctx, res_size0);
	
	copy_data_from__e_5(ctx, res1, a.begin_ptr, a.size);
	copy_data_from__e_5(ctx, (res1 + a.size), b.begin_ptr, b.size);
	return (struct arr_14) {res_size0, ((struct failure**) res1)};
}
/* run-crow-tests.lambda0 arr<failure>(test str) */
struct arr_14 run_crow_tests__lambda0(struct ctx* ctx, struct run_crow_tests__lambda0* _closure, struct str test) {
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
	
	struct arr_14 failures1;
	struct lint__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct lint__lambda0));
	temp0 = ((struct lint__lambda0*) _0);
	
	*temp0 = (struct lint__lambda0) {options};
	failures1 = flat_map_with_max_size(ctx, files0, options->max_failures, (struct fun_act1_23) {1, .as1 = temp0});
	
	uint8_t _1 = is_empty_23(failures1);
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
	struct mut_list_5* res0;
	res0 = mut_list_3(ctx);
	
	struct list_lintable_files__lambda1* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct list_lintable_files__lambda1));
	temp0 = ((struct list_lintable_files__lambda1*) _0);
	
	*temp0 = (struct list_lintable_files__lambda1) {res0};
	each_child_recursive_1(ctx, path, (struct fun_act1_8) {5, .as5 = (struct void_) {}}, (struct fun_act1_22) {3, .as3 = temp0});
	return move_to_arr__e_4(res0);
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
	uint8_t _0 = is_empty_6(a);
	if (_0) {
		return 0;
	} else {
		struct str _1 = subscript_26(ctx, a, 0u);
		uint8_t _2 = subscript_25(ctx, f, _1);
		if (_2) {
			return 1;
		} else {
			struct arr_2 _3 = tail_1(ctx, a);
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
		uint64_t _1 = _minus_7(ctx, a.size, end.size);
		struct arrow_0 _2 = _arrow_0(_1, a.size);
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
	struct opt_15 _0 = get_extension(ctx, name);
	switch (_0.kind) {
		case 0: {
			return 1;
		}
		case 1: {
			struct some_15 _matched0 = _0.as1;
			
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
		return _concatEquals_6(ctx, _closure->res, child);
	} else {
		return (struct void_) {};
	}
}
/* lint-file arr<failure>(path str) */
struct arr_14 lint_file(struct ctx* ctx, struct str path) {
	struct str text0;
	text0 = read_file(ctx, path);
	
	struct mut_list_6* res1;
	res1 = mut_list_4(ctx);
	
	struct str ext2;
	struct opt_15 _0 = get_extension(ctx, path);
	ext2 = force_0(ctx, _0);
	
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
	each_with_index_0(ctx, _2, (struct fun_act2_15) {0, .as0 = temp0});
	return move_to_arr__e_5(res1);
}
/* read-file str(path str) */
struct str read_file(struct ctx* ctx, struct str path) {
	struct opt_15 _0 = try_read_file_0(ctx, path);
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
			struct some_15 _matched0 = _0.as1;
			
			struct str res1;
			res1 = _matched0.value;
			
			return res1;
		}
		default:
			
	return (struct str) {(struct arr_0) {0, NULL}};;
	}
}
/* each-with-index<str> void(a arr<str>, f fun-act2<void, str, nat64>) */
struct void_ each_with_index_0(struct ctx* ctx, struct arr_2 a, struct fun_act2_15 f) {
	return each_with_index_recur_0(ctx, a, f, 0u);
}
/* each-with-index-recur<a> void(a arr<str>, f fun-act2<void, str, nat64>, n nat64) */
struct void_ each_with_index_recur_0(struct ctx* ctx, struct arr_2 a, struct fun_act2_15 f, uint64_t n) {
	top:;
	uint8_t _0 = _notEqual_5(n, a.size);
	if (_0) {
		struct str _1 = subscript_26(ctx, a, n);
		subscript_106(ctx, f, _1, n);
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
struct void_ subscript_106(struct ctx* ctx, struct fun_act2_15 a, struct str p0, uint64_t p1) {
	return call_w_ctx_1267(a, ctx, p0, p1);
}
/* call-w-ctx<void, str, nat-64> (generated) (generated) */
struct void_ call_w_ctx_1267(struct fun_act2_15 a, struct ctx* ctx, struct str p0, uint64_t p1) {
	struct fun_act2_15 _0 = a;
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
	struct mut_list_5* res0;
	res0 = mut_list_3(ctx);
	
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
	each_with_index_1(ctx, s.chars, (struct fun_act2_16) {0, .as0 = temp1});
	uint64_t _2 = _times_24(last_nl1);
	uint64_t _3 = size_bytes(s);
	struct arrow_0 _4 = _arrow_0(_2, _3);
	struct arr_0 _5 = subscript_4(ctx, s.chars, _4);
	_concatEquals_6(ctx, res0, (struct str) {_5});
	return move_to_arr__e_4(res0);
}
/* each-with-index<char> void(a arr<char>, f fun-act2<void, char, nat64>) */
struct void_ each_with_index_1(struct ctx* ctx, struct arr_0 a, struct fun_act2_16 f) {
	return each_with_index_recur_1(ctx, a, f, 0u);
}
/* each-with-index-recur<a> void(a arr<char>, f fun-act2<void, char, nat64>, n nat64) */
struct void_ each_with_index_recur_1(struct ctx* ctx, struct arr_0 a, struct fun_act2_16 f, uint64_t n) {
	top:;
	uint8_t _0 = _notEqual_5(n, a.size);
	if (_0) {
		char _1 = subscript_61(ctx, a, n);
		subscript_107(ctx, f, _1, n);
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
struct void_ subscript_107(struct ctx* ctx, struct fun_act2_16 a, char p0, uint64_t p1) {
	return call_w_ctx_1272(a, ctx, p0, p1);
}
/* call-w-ctx<void, char, nat-64> (generated) (generated) */
struct void_ call_w_ctx_1272(struct fun_act2_16 a, struct ctx* ctx, char p0, uint64_t p1) {
	struct fun_act2_16 _0 = a;
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
		
		struct arrow_0 _2 = _arrow_0(nl0, index);
		struct arr_0 _3 = subscript_4(ctx, _closure->s.chars, _2);
		return _concatEquals_6(ctx, _closure->res, (struct str) {_3});
	} else {
		return (struct void_) {};
	}
}
/* line-len nat64(line str) */
uint64_t line_len(struct ctx* ctx, struct str line) {
	uint64_t _0 = n_tabs(ctx, line);
	uint64_t _1 = tab_size(ctx);
	uint64_t _2 = _minus_7(ctx, _1, 1u);
	uint64_t _3 = _times_3(ctx, _0, _2);
	uint64_t _4 = size_bytes(line);
	return _plus_3(ctx, _3, _4);
}
/* n-tabs nat64(line str) */
uint64_t n_tabs(struct ctx* ctx, struct str line) {
	struct opt_15 _0 = try_remove_start_0(ctx, line, (struct str) {{1, constantarr_0_111}});
	switch (_0.kind) {
		case 0: {
			return 0u;
		}
		case 1: {
			struct some_15 _matched0 = _0.as1;
			
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
		_concatEquals_8(ctx, _closure->res, temp0);
	} else {
		(struct void_) {};
	}
	uint64_t width3;
	width3 = line_len(ctx, line);
	
	uint64_t _8 = max_line_length(ctx);
	uint8_t _9 = _greater_0(width3, _8);
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
		return _concatEquals_8(ctx, _closure->res, temp1);
	} else {
		return (struct void_) {};
	}
}
/* lint.lambda0 arr<failure>(file str) */
struct arr_14 lint__lambda0(struct ctx* ctx, struct lint__lambda0* _closure, struct str file) {
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
			
			each_4(ctx, e1.value, (struct fun_act1_24) {1, .as1 = (struct void_) {}});
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
