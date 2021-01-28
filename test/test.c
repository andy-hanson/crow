#include <errno.h>
#include <stdatomic.h>
#include <stddef.h>
#include <stdint.h>

struct void_ {};
struct dir;
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
struct fut_state_callbacks_0;
struct fut_callback_node_0;
struct exception;
struct arr_0 {
	uint64_t size;
	char* data;
};
struct backtrace;
struct arr_1 {
	uint64_t size;
	struct arr_0* data;
};
struct ok_0 {
	uint64_t value;
};
struct err_0;
struct none {
};
struct some_0 {
	struct fut_callback_node_0* value;
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
struct arrow_0 {
	uint64_t from;
	uint64_t to;
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
struct some_7 {
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
struct callback__e_0__lambda0;
struct then__lambda0;
struct callback__e_1__lambda0;
struct forward_to__e__lambda0 {
	struct fut_0* to;
};
struct resolve_or_reject__e__lambda0;
struct subscript_8__lambda0;
struct subscript_8__lambda0__lambda0;
struct subscript_8__lambda0__lambda1 {
	struct fut_0* res;
};
struct then2__lambda0;
struct subscript_13__lambda0;
struct subscript_13__lambda0__lambda0;
struct subscript_13__lambda0__lambda1 {
	struct fut_0* res;
};
struct add_first_task__lambda0;
struct map_0__lambda0;
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
struct some_8 {
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
struct test_options {
	uint8_t print_tests__q;
	uint8_t overwrite_output__q;
	uint64_t max_failures;
};
struct some_9 {
	struct test_options value;
};
struct some_10 {
	struct arr_1 value;
};
struct arr_5;
struct parsed_cmd_line_args;
struct dict_0;
struct arr_6 {
	uint64_t size;
	struct arr_1* data;
};
struct arrow_1 {
	struct arr_0 from;
	struct arr_1 to;
};
struct arr_7 {
	uint64_t size;
	struct arrow_1** data;
};
struct map_1__lambda0;
struct map_2__lambda0;
struct sorted_by_first_0 {
	struct arr_1 a;
	struct arr_6 b;
};
struct mut_arr_1 {
	struct void_ ignore;
	struct arr_1 inner;
};
struct mut_arr_1__lambda0 {
	struct arr_1 a;
};
struct mut_arr_2 {
	struct void_ ignore;
	struct arr_6 inner;
};
struct mut_arr_3__lambda0 {
	struct arr_6 a;
};
struct mut_dict_0;
struct mut_list_1 {
	struct mut_arr_1 backing;
	uint64_t size;
};
struct mut_list_2 {
	struct mut_arr_2 backing;
	uint64_t size;
};
struct some_11 {
	struct arr_0 value;
};
struct mut_list_3;
struct mut_arr_3;
struct fill_mut_arr__lambda0;
struct cell_3 {
	uint8_t subscript;
};
struct parse_cmd_line_args__lambda0 {
	struct arr_1 t_names;
	struct cell_3* help;
	struct mut_list_3* values;
};
struct index_of__lambda0 {
	struct arr_0 value;
};
struct r_index_of__lambda0 {
	char value;
};
struct mut_arr_4 {
	struct void_ ignore;
	struct arr_0 inner;
};
struct dict_1 {
	struct void_ ignore;
	struct arr_1 keys;
	struct arr_1 values;
};
struct mut_dict_1 {
	struct void_ ignore;
	struct mut_list_1* keys;
	struct mut_list_1* values;
};
struct arrow_2 {
	struct arr_0 from;
	struct arr_0 to;
};
struct sorted_by_first_1 {
	struct arr_1 a;
	struct arr_1 b;
};
struct failure {
	struct arr_0 path;
	struct arr_0 message;
};
struct arr_8 {
	uint64_t size;
	struct failure** data;
};
struct ok_2 {
	struct arr_0 value;
};
struct err_1 {
	struct arr_8 value;
};
struct stat_t {
	uint64_t st_dev;
	uint32_t pad0;
	uint64_t st_ino_unused;
	uint32_t st_mode;
	uint32_t st_nlink;
	uint64_t st_uid;
	uint64_t st_gid;
	uint64_t st_rdev;
	uint32_t pad1;
	int64_t st_size;
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
struct some_12 {
	struct stat_t* value;
};
struct dirent;
struct bytes256;
struct cell_4 {
	struct dirent* subscript;
};
struct each_child_recursive__lambda0;
struct list_tests__lambda1 {
	struct mut_list_1* res;
};
struct mut_list_4;
struct mut_arr_5 {
	struct void_ ignore;
	struct arr_8 inner;
};
struct flat_map_with_max_size__lambda0;
struct _concatEquals_2__lambda0 {
	struct mut_list_4* a;
};
struct some_13 {
	struct failure* value;
};
struct run_crow_tests__lambda0 {
	struct arr_0 path_to_crow;
	struct dict_1* env;
	struct test_options options;
};
struct some_14 {
	struct arr_8 value;
};
struct run_single_crow_test__lambda0 {
	struct test_options options;
	struct arr_0 path;
	struct arr_0 path_to_crow;
	struct dict_1* env;
};
struct print_test_result {
	uint8_t should_stop__q;
	struct arr_8 failures;
};
struct process_result {
	int32_t exit_code;
	struct arr_0 stdout;
	struct arr_0 stderr;
};
struct pipes {
	int32_t write_pipe;
	int32_t read_pipe;
};
struct posix_spawn_file_actions_t;
struct cell_5 {
	int32_t subscript;
};
struct mut_list_5 {
	struct mut_arr_4 backing;
	uint64_t size;
};
struct pollfd {
	int32_t fd;
	int16_t events;
	int16_t revents;
};
struct arr_9 {
	uint64_t size;
	struct pollfd* data;
};
struct handle_revents_result {
	uint8_t had_pollin__q;
	uint8_t hung_up__q;
};
struct map_3__lambda0;
struct mut_list_6;
struct mut_arr_6 {
	struct void_ ignore;
	struct arr_4 inner;
};
struct convert_environ__lambda0 {
	struct mut_list_6* res;
};
struct do_test__lambda0 {
	struct arr_0 test_path;
	struct arr_0 crow_exe;
	struct dict_1* env;
	struct test_options options;
};
struct do_test__lambda0__lambda0 {
	struct arr_0 test_path;
	struct arr_0 crow_exe;
	struct dict_1* env;
	struct test_options options;
};
struct do_test__lambda1 {
	struct arr_0 crow_path;
	struct test_options options;
};
struct excluded_from_lint__q__lambda0 {
	struct arr_0 name;
};
struct list_lintable_files__lambda1 {
	struct mut_list_1* res;
};
struct lint__lambda0 {
	struct test_options options;
};
struct lines__lambda0 {
	struct cell_0* last_nl;
	struct mut_list_1* res;
	struct arr_0 s;
};
struct lint_file__lambda0 {
	uint8_t allow_double_space__q;
	struct mut_list_4* res;
	struct arr_0 path;
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
		struct subscript_8__lambda0__lambda0* as2;
		struct subscript_8__lambda0* as3;
		struct subscript_13__lambda0__lambda0* as4;
		struct subscript_13__lambda0* as5;
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
struct fun_act2_0 {
	uint64_t kind;
	union {
		struct void_ as0;
	};
};
struct fut_state_1;
struct result_1;
struct fun_act1_1 {
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
struct fun_act1_2 {
	uint64_t kind;
	union {
		struct then2__lambda0* as0;
	};
};
struct fun_act0_2 {
	uint64_t kind;
	union {
		struct resolve_or_reject__e__lambda0* as0;
	};
};
struct fun_act1_3 {
	uint64_t kind;
	union {
		struct subscript_8__lambda0__lambda1* as0;
		struct subscript_13__lambda0__lambda1* as1;
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
		struct map_0__lambda0* as0;
		struct map_1__lambda0* as1;
		struct mut_arr_1__lambda0* as2;
	};
};
struct choose_task_result;
struct task_or_gc;
struct opt_8 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_8 as1;
	};
};
struct choose_task_in_island_result;
struct pop_task_result;
struct opt_9 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_9 as1;
	};
};
struct opt_10 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_10 as1;
	};
};
struct fun1_2 {
	uint64_t kind;
	union {
		struct void_ as0;
	};
};
struct fun_act1_6 {
	uint64_t kind;
	union {
		struct void_ as0;
		struct void_ as1;
		struct void_ as2;
		struct index_of__lambda0* as3;
		struct void_ as4;
		struct excluded_from_lint__q__lambda0* as5;
		struct void_ as6;
	};
};
struct fun_act1_7 {
	uint64_t kind;
	union {
		struct void_ as0;
	};
};
struct fun_act1_8 {
	uint64_t kind;
	union {
		struct void_ as0;
	};
};
struct fun_act1_9 {
	uint64_t kind;
	union {
		struct map_2__lambda0* as0;
		struct mut_arr_3__lambda0* as1;
	};
};
struct opt_11 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_11 as1;
	};
};
struct fun_act1_10 {
	uint64_t kind;
	union {
		struct fill_mut_arr__lambda0* as0;
	};
};
struct fun_act2_1 {
	uint64_t kind;
	union {
		struct parse_cmd_line_args__lambda0* as0;
	};
};
struct fun_act1_11 {
	uint64_t kind;
	union {
		struct r_index_of__lambda0* as0;
	};
};
struct result_2 {
	uint64_t kind;
	union {
		struct ok_2 as0;
		struct err_1 as1;
	};
};
struct fun0 {
	uint64_t kind;
	union {
		struct do_test__lambda0__lambda0* as0;
		struct do_test__lambda0* as1;
		struct do_test__lambda1* as2;
	};
};
struct fun_act1_12 {
	uint64_t kind;
	union {
		struct each_child_recursive__lambda0* as0;
		struct list_tests__lambda1* as1;
		struct flat_map_with_max_size__lambda0* as2;
		struct list_lintable_files__lambda1* as3;
	};
};
struct opt_12 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_12 as1;
	};
};
struct fun_act1_13 {
	uint64_t kind;
	union {
		struct run_crow_tests__lambda0* as0;
		struct lint__lambda0* as1;
	};
};
struct fun_act1_14 {
	uint64_t kind;
	union {
		struct _concatEquals_2__lambda0* as0;
		struct void_ as1;
	};
};
struct opt_13 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_13 as1;
	};
};
struct opt_14 {
	uint64_t kind;
	union {
		struct none as0;
		struct some_14 as1;
	};
};
struct fun_act1_15 {
	uint64_t kind;
	union {
		struct run_single_crow_test__lambda0* as0;
	};
};
struct fun_act2_2 {
	uint64_t kind;
	union {
		struct void_ as0;
	};
};
struct fun_act1_16 {
	uint64_t kind;
	union {
		struct void_ as0;
	};
};
struct fun_act1_17 {
	uint64_t kind;
	union {
		struct map_3__lambda0* as0;
	};
};
struct fun_act2_3 {
	uint64_t kind;
	union {
		struct convert_environ__lambda0* as0;
	};
};
struct fun_act2_4 {
	uint64_t kind;
	union {
		struct lint_file__lambda0* as0;
	};
};
struct fun_act2_5 {
	uint64_t kind;
	union {
		struct lines__lambda0* as0;
	};
};
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
struct exception;
struct backtrace {
	struct arr_1 return_stack;
};
struct err_0;
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
struct log_ctx {
	struct fun1_1 handler;
};
struct fut_1;
struct fut_state_callbacks_1 {
	struct opt_7 head;
};
struct fut_callback_node_1 {
	struct fun_act1_1 cb;
	struct opt_7 next_node;
};
struct fun_ref0 {
	struct island_and_exclusion island_and_exclusion;
	struct fun_act0_1 fun;
};
struct fun_ref1 {
	struct island_and_exclusion island_and_exclusion;
	struct fun_act1_2 fun;
};
struct callback__e_0__lambda0 {
	struct fut_1* f;
	struct fun_act1_1 cb;
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
struct subscript_8__lambda0 {
	struct fun_ref1 f;
	struct void_ p0;
	struct fut_0* res;
};
struct subscript_8__lambda0__lambda0 {
	struct fun_ref1 f;
	struct void_ p0;
	struct fut_0* res;
};
struct then2__lambda0 {
	struct fun_ref0 cb;
};
struct subscript_13__lambda0 {
	struct fun_ref0 f;
	struct fut_0* res;
};
struct subscript_13__lambda0__lambda0 {
	struct fun_ref0 f;
	struct fut_0* res;
};
struct add_first_task__lambda0 {
	struct arr_4 all_args;
	fun_ptr2 main_ptr;
};
struct map_0__lambda0 {
	struct fun_act1_4 mapper;
	struct arr_4 a;
};
struct chosen_task;
struct no_chosen_task {
	uint8_t no_tasks_and_last_thread_out__q;
	struct opt_8 first_task_time;
};
struct no_task {
	uint8_t any_tasks__q;
	struct opt_8 first_task_time;
};
struct arr_5 {
	uint64_t size;
	struct opt_10* data;
};
struct parsed_cmd_line_args {
	struct arr_1 nameless;
	struct dict_0* named;
	struct arr_1 after;
};
struct dict_0 {
	struct void_ ignore;
	struct arr_1 keys;
	struct arr_6 values;
};
struct map_1__lambda0 {
	struct fun_act1_7 mapper;
	struct arr_7 a;
};
struct map_2__lambda0 {
	struct fun_act1_8 mapper;
	struct arr_7 a;
};
struct mut_dict_0 {
	struct void_ ignore;
	struct mut_list_1* keys;
	struct mut_list_2* values;
};
struct mut_list_3;
struct mut_arr_3 {
	struct void_ ignore;
	struct arr_5 inner;
};
struct fill_mut_arr__lambda0 {
	struct opt_10 value;
};
struct dirent;
struct bytes256;
struct each_child_recursive__lambda0 {
	struct fun_act1_6 filter;
	struct arr_0 path;
	struct fun_act1_12 f;
};
struct mut_list_4 {
	struct mut_arr_5 backing;
	uint64_t size;
};
struct flat_map_with_max_size__lambda0 {
	struct mut_list_4* res;
	uint64_t max_size;
	struct fun_act1_13 mapper;
};
struct posix_spawn_file_actions_t;
struct map_3__lambda0 {
	struct fun_act1_16 mapper;
	struct arr_1 a;
};
struct mut_list_6 {
	struct mut_arr_6 backing;
	uint64_t size;
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
struct err_0 {
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
struct mut_list_3 {
	struct mut_arr_3 backing;
	uint64_t size;
};
struct dirent;
struct bytes256 {
	struct bytes128 n0;
	struct bytes128 n1;
};
struct posix_spawn_file_actions_t {
	int32_t allocated;
	int32_t used;
	uint8_t* actions;
	struct bytes64 pad;
};
struct fut_state_0 {
	uint64_t kind;
	union {
		struct fut_state_callbacks_0 as0;
		struct fut_state_resolved_0 as1;
		struct exception as2;
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
		struct fut_state_callbacks_1 as0;
		struct fut_state_resolved_1 as1;
		struct exception as2;
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
struct dirent {
	uint64_t d_ino;
	int64_t d_off;
	uint16_t d_reclen;
	char d_type;
	struct bytes256 d_name;
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
_Static_assert(sizeof(struct fut_state_callbacks_0) == 16, "");
_Static_assert(sizeof(struct fut_callback_node_0) == 32, "");
_Static_assert(sizeof(struct exception) == 32, "");
_Static_assert(sizeof(struct arr_0) == 16, "");
_Static_assert(sizeof(struct backtrace) == 16, "");
_Static_assert(sizeof(struct arr_1) == 16, "");
_Static_assert(sizeof(struct ok_0) == 8, "");
_Static_assert(sizeof(struct err_0) == 32, "");
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
_Static_assert(sizeof(struct arrow_0) == 16, "");
_Static_assert(sizeof(struct log_ctx) == 8, "");
_Static_assert(sizeof(struct thread_local_stuff) == 16, "");
_Static_assert(sizeof(struct arr_4) == 16, "");
_Static_assert(sizeof(struct fut_1) == 48, "");
_Static_assert(sizeof(struct fut_state_callbacks_1) == 16, "");
_Static_assert(sizeof(struct fut_callback_node_1) == 32, "");
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
_Static_assert(sizeof(struct subscript_8__lambda0) == 40, "");
_Static_assert(sizeof(struct subscript_8__lambda0__lambda0) == 40, "");
_Static_assert(sizeof(struct subscript_8__lambda0__lambda1) == 8, "");
_Static_assert(sizeof(struct then2__lambda0) == 32, "");
_Static_assert(sizeof(struct subscript_13__lambda0) == 40, "");
_Static_assert(sizeof(struct subscript_13__lambda0__lambda0) == 40, "");
_Static_assert(sizeof(struct subscript_13__lambda0__lambda1) == 8, "");
_Static_assert(sizeof(struct add_first_task__lambda0) == 24, "");
_Static_assert(sizeof(struct map_0__lambda0) == 24, "");
_Static_assert(sizeof(struct thread_args) == 16, "");
_Static_assert(sizeof(struct cell_0) == 8, "");
_Static_assert(sizeof(struct chosen_task) == 48, "");
_Static_assert(sizeof(struct do_a_gc) == 0, "");
_Static_assert(sizeof(struct no_chosen_task) == 24, "");
_Static_assert(sizeof(struct some_8) == 8, "");
_Static_assert(sizeof(struct timespec) == 16, "");
_Static_assert(sizeof(struct cell_1) == 16, "");
_Static_assert(sizeof(struct no_task) == 24, "");
_Static_assert(sizeof(struct cell_2) == 8, "");
_Static_assert(sizeof(struct test_options) == 16, "");
_Static_assert(sizeof(struct some_9) == 16, "");
_Static_assert(sizeof(struct some_10) == 16, "");
_Static_assert(sizeof(struct arr_5) == 16, "");
_Static_assert(sizeof(struct parsed_cmd_line_args) == 40, "");
_Static_assert(sizeof(struct dict_0) == 32, "");
_Static_assert(sizeof(struct arr_6) == 16, "");
_Static_assert(sizeof(struct arrow_1) == 32, "");
_Static_assert(sizeof(struct arr_7) == 16, "");
_Static_assert(sizeof(struct map_1__lambda0) == 24, "");
_Static_assert(sizeof(struct map_2__lambda0) == 24, "");
_Static_assert(sizeof(struct sorted_by_first_0) == 32, "");
_Static_assert(sizeof(struct mut_arr_1) == 16, "");
_Static_assert(sizeof(struct mut_arr_1__lambda0) == 16, "");
_Static_assert(sizeof(struct mut_arr_2) == 16, "");
_Static_assert(sizeof(struct mut_arr_3__lambda0) == 16, "");
_Static_assert(sizeof(struct mut_dict_0) == 16, "");
_Static_assert(sizeof(struct mut_list_1) == 24, "");
_Static_assert(sizeof(struct mut_list_2) == 24, "");
_Static_assert(sizeof(struct some_11) == 16, "");
_Static_assert(sizeof(struct mut_list_3) == 24, "");
_Static_assert(sizeof(struct mut_arr_3) == 16, "");
_Static_assert(sizeof(struct fill_mut_arr__lambda0) == 24, "");
_Static_assert(sizeof(struct cell_3) == 1, "");
_Static_assert(sizeof(struct parse_cmd_line_args__lambda0) == 32, "");
_Static_assert(sizeof(struct index_of__lambda0) == 16, "");
_Static_assert(sizeof(struct r_index_of__lambda0) == 1, "");
_Static_assert(sizeof(struct mut_arr_4) == 16, "");
_Static_assert(sizeof(struct dict_1) == 32, "");
_Static_assert(sizeof(struct mut_dict_1) == 16, "");
_Static_assert(sizeof(struct arrow_2) == 32, "");
_Static_assert(sizeof(struct sorted_by_first_1) == 32, "");
_Static_assert(sizeof(struct failure) == 32, "");
_Static_assert(sizeof(struct arr_8) == 16, "");
_Static_assert(sizeof(struct ok_2) == 16, "");
_Static_assert(sizeof(struct err_1) == 16, "");
_Static_assert(sizeof(struct stat_t) == 152, "");
_Static_assert(sizeof(struct some_12) == 8, "");
_Static_assert(sizeof(struct dirent) == 280, "");
_Static_assert(sizeof(struct bytes256) == 256, "");
_Static_assert(sizeof(struct cell_4) == 8, "");
_Static_assert(sizeof(struct each_child_recursive__lambda0) == 48, "");
_Static_assert(sizeof(struct list_tests__lambda1) == 8, "");
_Static_assert(sizeof(struct mut_list_4) == 24, "");
_Static_assert(sizeof(struct mut_arr_5) == 16, "");
_Static_assert(sizeof(struct flat_map_with_max_size__lambda0) == 32, "");
_Static_assert(sizeof(struct _concatEquals_2__lambda0) == 8, "");
_Static_assert(sizeof(struct some_13) == 8, "");
_Static_assert(sizeof(struct run_crow_tests__lambda0) == 40, "");
_Static_assert(sizeof(struct some_14) == 16, "");
_Static_assert(sizeof(struct run_single_crow_test__lambda0) == 56, "");
_Static_assert(sizeof(struct print_test_result) == 24, "");
_Static_assert(sizeof(struct process_result) == 40, "");
_Static_assert(sizeof(struct pipes) == 8, "");
_Static_assert(sizeof(struct posix_spawn_file_actions_t) == 80, "");
_Static_assert(sizeof(struct cell_5) == 4, "");
_Static_assert(sizeof(struct mut_list_5) == 24, "");
_Static_assert(sizeof(struct pollfd) == 8, "");
_Static_assert(sizeof(struct arr_9) == 16, "");
_Static_assert(sizeof(struct handle_revents_result) == 2, "");
_Static_assert(sizeof(struct map_3__lambda0) == 24, "");
_Static_assert(sizeof(struct mut_list_6) == 24, "");
_Static_assert(sizeof(struct mut_arr_6) == 16, "");
_Static_assert(sizeof(struct convert_environ__lambda0) == 8, "");
_Static_assert(sizeof(struct do_test__lambda0) == 56, "");
_Static_assert(sizeof(struct do_test__lambda0__lambda0) == 56, "");
_Static_assert(sizeof(struct do_test__lambda1) == 32, "");
_Static_assert(sizeof(struct excluded_from_lint__q__lambda0) == 16, "");
_Static_assert(sizeof(struct list_lintable_files__lambda1) == 8, "");
_Static_assert(sizeof(struct lint__lambda0) == 16, "");
_Static_assert(sizeof(struct lines__lambda0) == 32, "");
_Static_assert(sizeof(struct lint_file__lambda0) == 32, "");
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
_Static_assert(sizeof(struct fun_act2_0) == 8, "");
_Static_assert(sizeof(struct fut_state_1) == 40, "");
_Static_assert(sizeof(struct result_1) == 40, "");
_Static_assert(sizeof(struct fun_act1_1) == 16, "");
_Static_assert(sizeof(struct opt_7) == 16, "");
_Static_assert(sizeof(struct fun_act0_1) == 16, "");
_Static_assert(sizeof(struct fun_act1_2) == 16, "");
_Static_assert(sizeof(struct fun_act0_2) == 16, "");
_Static_assert(sizeof(struct fun_act1_3) == 16, "");
_Static_assert(sizeof(struct fun_act1_4) == 8, "");
_Static_assert(sizeof(struct fun_act1_5) == 16, "");
_Static_assert(sizeof(struct choose_task_result) == 56, "");
_Static_assert(sizeof(struct task_or_gc) == 40, "");
_Static_assert(sizeof(struct opt_8) == 16, "");
_Static_assert(sizeof(struct choose_task_in_island_result) == 40, "");
_Static_assert(sizeof(struct pop_task_result) == 40, "");
_Static_assert(sizeof(struct opt_9) == 24, "");
_Static_assert(sizeof(struct opt_10) == 24, "");
_Static_assert(sizeof(struct fun1_2) == 8, "");
_Static_assert(sizeof(struct fun_act1_6) == 16, "");
_Static_assert(sizeof(struct fun_act1_7) == 8, "");
_Static_assert(sizeof(struct fun_act1_8) == 8, "");
_Static_assert(sizeof(struct fun_act1_9) == 16, "");
_Static_assert(sizeof(struct opt_11) == 24, "");
_Static_assert(sizeof(struct fun_act1_10) == 16, "");
_Static_assert(sizeof(struct fun_act2_1) == 16, "");
_Static_assert(sizeof(struct fun_act1_11) == 16, "");
_Static_assert(sizeof(struct result_2) == 24, "");
_Static_assert(sizeof(struct fun0) == 16, "");
_Static_assert(sizeof(struct fun_act1_12) == 16, "");
_Static_assert(sizeof(struct opt_12) == 16, "");
_Static_assert(sizeof(struct fun_act1_13) == 16, "");
_Static_assert(sizeof(struct fun_act1_14) == 16, "");
_Static_assert(sizeof(struct opt_13) == 16, "");
_Static_assert(sizeof(struct opt_14) == 24, "");
_Static_assert(sizeof(struct fun_act1_15) == 16, "");
_Static_assert(sizeof(struct fun_act2_2) == 8, "");
_Static_assert(sizeof(struct fun_act1_16) == 8, "");
_Static_assert(sizeof(struct fun_act1_17) == 16, "");
_Static_assert(sizeof(struct fun_act2_3) == 16, "");
_Static_assert(sizeof(struct fun_act2_4) == 16, "");
_Static_assert(sizeof(struct fun_act2_5) == 16, "");
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
char constantarr_0_10[11];
char constantarr_0_11[16];
char constantarr_0_12[12];
char constantarr_0_13[2];
char constantarr_0_14[27];
char constantarr_0_15[26];
char constantarr_0_16[4];
char constantarr_0_17[15];
char constantarr_0_18[18];
char constantarr_0_19[8];
char constantarr_0_20[36];
char constantarr_0_21[63];
char constantarr_0_22[1];
char constantarr_0_23[14];
char constantarr_0_24[1];
char constantarr_0_25[3];
char constantarr_0_26[4];
char constantarr_0_27[1];
char constantarr_0_28[2];
char constantarr_0_29[3];
char constantarr_0_30[5];
char constantarr_0_31[14];
char constantarr_0_32[9];
char constantarr_0_33[11];
char constantarr_0_34[1];
char constantarr_0_35[23];
char constantarr_0_36[31];
char constantarr_0_37[1];
char constantarr_0_38[1];
char constantarr_0_39[1];
char constantarr_0_40[1];
char constantarr_0_41[1];
char constantarr_0_42[1];
char constantarr_0_43[1];
char constantarr_0_44[1];
char constantarr_0_45[1];
char constantarr_0_46[1];
char constantarr_0_47[1];
char constantarr_0_48[12];
char constantarr_0_49[1];
char constantarr_0_50[14];
char constantarr_0_51[5];
char constantarr_0_52[5];
char constantarr_0_53[20];
char constantarr_0_54[31];
char constantarr_0_55[7];
char constantarr_0_56[7];
char constantarr_0_57[12];
char constantarr_0_58[29];
char constantarr_0_59[30];
char constantarr_0_60[4];
char constantarr_0_61[22];
char constantarr_0_62[9];
char constantarr_0_63[3];
char constantarr_0_64[11];
char constantarr_0_65[7];
char constantarr_0_66[7];
char constantarr_0_67[4];
char constantarr_0_68[10];
char constantarr_0_69[12];
char constantarr_0_70[14];
char constantarr_0_71[8];
char constantarr_0_72[4];
char constantarr_0_73[4];
char constantarr_0_74[4];
char constantarr_0_75[5];
char constantarr_0_76[7];
char constantarr_0_77[7];
char constantarr_0_78[12];
char constantarr_0_79[17];
char constantarr_0_80[1];
char constantarr_0_81[4];
char constantarr_0_82[1];
char constantarr_0_83[3];
char constantarr_0_84[4];
char constantarr_0_85[10];
char constantarr_0_86[5];
char constantarr_0_87[21];
char constantarr_0_88[3];
char constantarr_0_89[14];
char constantarr_0_90[5];
char constantarr_0_91[24];
char constantarr_0_92[4];
char constantarr_0_93[28];
char constantarr_0_94[7];
char constantarr_0_95[6];
char constantarr_0_96[4];
char constantarr_0_97[3];
char constantarr_0_98[15];
char constantarr_0_99[9];
char constantarr_0_100[4];
char constantarr_0_101[14];
char constantarr_0_102[10];
char constantarr_0_103[25];
char constantarr_0_104[8];
char constantarr_0_105[8];
char constantarr_0_106[8];
char constantarr_0_107[12];
char constantarr_0_108[19];
char constantarr_0_109[11];
char constantarr_0_110[3];
char constantarr_0_111[5];
char constantarr_0_112[4];
char constantarr_0_113[6];
char constantarr_0_114[7];
char constantarr_0_115[7];
char constantarr_0_116[11];
char constantarr_0_117[6];
char constantarr_0_118[8];
char constantarr_0_119[11];
char constantarr_0_120[12];
char constantarr_0_121[6];
char constantarr_0_122[17];
char constantarr_0_123[7];
char constantarr_0_124[7];
char constantarr_0_125[5];
char constantarr_0_126[16];
char constantarr_0_127[13];
char constantarr_0_128[2];
char constantarr_0_129[15];
char constantarr_0_130[19];
char constantarr_0_131[10];
char constantarr_0_132[6];
char constantarr_0_133[7];
char constantarr_0_134[10];
char constantarr_0_135[22];
char constantarr_0_136[10];
char constantarr_0_137[11];
char constantarr_0_138[4];
char constantarr_0_139[11];
char constantarr_0_140[9];
char constantarr_0_141[22];
char constantarr_0_142[6];
char constantarr_0_143[10];
char constantarr_0_144[4];
char constantarr_0_145[56];
char constantarr_0_146[11];
char constantarr_0_147[4];
char constantarr_0_148[7];
char constantarr_0_149[35];
char constantarr_0_150[28];
char constantarr_0_151[21];
char constantarr_0_152[6];
char constantarr_0_153[11];
char constantarr_0_154[11];
char constantarr_0_155[10];
char constantarr_0_156[8];
char constantarr_0_157[8];
char constantarr_0_158[18];
char constantarr_0_159[6];
char constantarr_0_160[19];
char constantarr_0_161[12];
char constantarr_0_162[26];
char constantarr_0_163[14];
char constantarr_0_164[25];
char constantarr_0_165[20];
char constantarr_0_166[16];
char constantarr_0_167[13];
char constantarr_0_168[13];
char constantarr_0_169[5];
char constantarr_0_170[21];
char constantarr_0_171[10];
char constantarr_0_172[10];
char constantarr_0_173[7];
char constantarr_0_174[6];
char constantarr_0_175[13];
char constantarr_0_176[10];
char constantarr_0_177[10];
char constantarr_0_178[6];
char constantarr_0_179[9];
char constantarr_0_180[14];
char constantarr_0_181[12];
char constantarr_0_182[12];
char constantarr_0_183[7];
char constantarr_0_184[10];
char constantarr_0_185[15];
char constantarr_0_186[8];
char constantarr_0_187[18];
char constantarr_0_188[6];
char constantarr_0_189[10];
char constantarr_0_190[9];
char constantarr_0_191[17];
char constantarr_0_192[21];
char constantarr_0_193[17];
char constantarr_0_194[7];
char constantarr_0_195[18];
char constantarr_0_196[11];
char constantarr_0_197[20];
char constantarr_0_198[7];
char constantarr_0_199[15];
char constantarr_0_200[9];
char constantarr_0_201[13];
char constantarr_0_202[24];
char constantarr_0_203[34];
char constantarr_0_204[9];
char constantarr_0_205[12];
char constantarr_0_206[8];
char constantarr_0_207[14];
char constantarr_0_208[12];
char constantarr_0_209[8];
char constantarr_0_210[11];
char constantarr_0_211[23];
char constantarr_0_212[12];
char constantarr_0_213[5];
char constantarr_0_214[23];
char constantarr_0_215[9];
char constantarr_0_216[12];
char constantarr_0_217[13];
char constantarr_0_218[9];
char constantarr_0_219[10];
char constantarr_0_220[16];
char constantarr_0_221[2];
char constantarr_0_222[18];
char constantarr_0_223[11];
char constantarr_0_224[18];
char constantarr_0_225[13];
char constantarr_0_226[10];
char constantarr_0_227[8];
char constantarr_0_228[8];
char constantarr_0_229[17];
char constantarr_0_230[11];
char constantarr_0_231[10];
char constantarr_0_232[8];
char constantarr_0_233[8];
char constantarr_0_234[7];
char constantarr_0_235[10];
char constantarr_0_236[6];
char constantarr_0_237[11];
char constantarr_0_238[12];
char constantarr_0_239[12];
char constantarr_0_240[15];
char constantarr_0_241[19];
char constantarr_0_242[9];
char constantarr_0_243[8];
char constantarr_0_244[11];
char constantarr_0_245[10];
char constantarr_0_246[6];
char constantarr_0_247[2];
char constantarr_0_248[10];
char constantarr_0_249[14];
char constantarr_0_250[10];
char constantarr_0_251[13];
char constantarr_0_252[18];
char constantarr_0_253[16];
char constantarr_0_254[34];
char constantarr_0_255[10];
char constantarr_0_256[20];
char constantarr_0_257[14];
char constantarr_0_258[21];
char constantarr_0_259[21];
char constantarr_0_260[9];
char constantarr_0_261[18];
char constantarr_0_262[21];
char constantarr_0_263[13];
char constantarr_0_264[6];
char constantarr_0_265[9];
char constantarr_0_266[15];
char constantarr_0_267[14];
char constantarr_0_268[25];
char constantarr_0_269[7];
char constantarr_0_270[24];
char constantarr_0_271[17];
char constantarr_0_272[5];
char constantarr_0_273[11];
char constantarr_0_274[24];
char constantarr_0_275[12];
char constantarr_0_276[8];
char constantarr_0_277[9];
char constantarr_0_278[13];
char constantarr_0_279[15];
char constantarr_0_280[13];
char constantarr_0_281[15];
char constantarr_0_282[24];
char constantarr_0_283[15];
char constantarr_0_284[10];
char constantarr_0_285[10];
char constantarr_0_286[21];
char constantarr_0_287[20];
char constantarr_0_288[15];
char constantarr_0_289[15];
char constantarr_0_290[14];
char constantarr_0_291[12];
char constantarr_0_292[8];
char constantarr_0_293[5];
char constantarr_0_294[1];
char constantarr_0_295[3];
char constantarr_0_296[7];
char constantarr_0_297[23];
char constantarr_0_298[5];
char constantarr_0_299[8];
char constantarr_0_300[15];
char constantarr_0_301[18];
char constantarr_0_302[6];
char constantarr_0_303[13];
char constantarr_0_304[6];
char constantarr_0_305[14];
char constantarr_0_306[12];
char constantarr_0_307[12];
char constantarr_0_308[13];
char constantarr_0_309[12];
char constantarr_0_310[29];
char constantarr_0_311[14];
char constantarr_0_312[18];
char constantarr_0_313[8];
char constantarr_0_314[14];
char constantarr_0_315[19];
char constantarr_0_316[16];
char constantarr_0_317[6];
char constantarr_0_318[6];
char constantarr_0_319[5];
char constantarr_0_320[14];
char constantarr_0_321[20];
char constantarr_0_322[21];
char constantarr_0_323[19];
char constantarr_0_324[18];
char constantarr_0_325[11];
char constantarr_0_326[11];
char constantarr_0_327[14];
char constantarr_0_328[7];
char constantarr_0_329[13];
char constantarr_0_330[7];
char constantarr_0_331[26];
char constantarr_0_332[30];
char constantarr_0_333[18];
char constantarr_0_334[25];
char constantarr_0_335[19];
char constantarr_0_336[3];
char constantarr_0_337[18];
char constantarr_0_338[12];
char constantarr_0_339[23];
char constantarr_0_340[6];
char constantarr_0_341[12];
char constantarr_0_342[13];
char constantarr_0_343[16];
char constantarr_0_344[8];
char constantarr_0_345[14];
char constantarr_0_346[11];
char constantarr_0_347[11];
char constantarr_0_348[26];
char constantarr_0_349[7];
char constantarr_0_350[22];
char constantarr_0_351[2];
char constantarr_0_352[25];
char constantarr_0_353[19];
char constantarr_0_354[30];
char constantarr_0_355[15];
char constantarr_0_356[79];
char constantarr_0_357[14];
char constantarr_0_358[10];
char constantarr_0_359[16];
char constantarr_0_360[16];
char constantarr_0_361[7];
char constantarr_0_362[23];
char constantarr_0_363[14];
char constantarr_0_364[15];
char constantarr_0_365[17];
char constantarr_0_366[6];
char constantarr_0_367[9];
char constantarr_0_368[13];
char constantarr_0_369[27];
char constantarr_0_370[21];
char constantarr_0_371[8];
char constantarr_0_372[38];
char constantarr_0_373[22];
char constantarr_0_374[6];
char constantarr_0_375[9];
char constantarr_0_376[14];
char constantarr_0_377[22];
char constantarr_0_378[17];
char constantarr_0_379[13];
char constantarr_0_380[21];
char constantarr_0_381[22];
char constantarr_0_382[34];
char constantarr_0_383[29];
char constantarr_0_384[22];
char constantarr_0_385[16];
char constantarr_0_386[30];
char constantarr_0_387[19];
char constantarr_0_388[10];
char constantarr_0_389[6];
char constantarr_0_390[28];
char constantarr_0_391[13];
char constantarr_0_392[25];
char constantarr_0_393[20];
char constantarr_0_394[10];
char constantarr_0_395[17];
char constantarr_0_396[7];
char constantarr_0_397[29];
char constantarr_0_398[8];
char constantarr_0_399[15];
char constantarr_0_400[4];
char constantarr_0_401[10];
char constantarr_0_402[12];
char constantarr_0_403[4];
char constantarr_0_404[10];
char constantarr_0_405[4];
char constantarr_0_406[22];
char constantarr_0_407[4];
char constantarr_0_408[8];
char constantarr_0_409[21];
char constantarr_0_410[4];
char constantarr_0_411[12];
char constantarr_0_412[8];
char constantarr_0_413[5];
char constantarr_0_414[22];
char constantarr_0_415[10];
char constantarr_0_416[9];
char constantarr_0_417[21];
char constantarr_0_418[17];
char constantarr_0_419[4];
char constantarr_0_420[12];
char constantarr_0_421[9];
char constantarr_0_422[11];
char constantarr_0_423[28];
char constantarr_0_424[16];
char constantarr_0_425[11];
char constantarr_0_426[4];
char constantarr_0_427[7];
char constantarr_0_428[7];
char constantarr_0_429[7];
char constantarr_0_430[8];
char constantarr_0_431[15];
char constantarr_0_432[19];
char constantarr_0_433[6];
char constantarr_0_434[24];
char constantarr_0_435[23];
char constantarr_0_436[12];
char constantarr_0_437[36];
char constantarr_0_438[11];
char constantarr_0_439[36];
char constantarr_0_440[28];
char constantarr_0_441[10];
char constantarr_0_442[24];
char constantarr_0_443[15];
char constantarr_0_444[24];
char constantarr_0_445[18];
char constantarr_0_446[7];
char constantarr_0_447[31];
char constantarr_0_448[31];
char constantarr_0_449[23];
char constantarr_0_450[18];
char constantarr_0_451[24];
char constantarr_0_452[20];
char constantarr_0_453[9];
char constantarr_0_454[5];
char constantarr_0_455[14];
char constantarr_0_456[15];
char constantarr_0_457[10];
char constantarr_0_458[40];
char constantarr_0_459[25];
char constantarr_0_460[14];
char constantarr_0_461[18];
char constantarr_0_462[24];
char constantarr_0_463[18];
char constantarr_0_464[14];
char constantarr_0_465[33];
char constantarr_0_466[24];
char constantarr_0_467[5];
char constantarr_0_468[13];
char constantarr_0_469[17];
char constantarr_0_470[8];
char constantarr_0_471[15];
char constantarr_0_472[15];
char constantarr_0_473[10];
char constantarr_0_474[30];
char constantarr_0_475[22];
char constantarr_0_476[22];
char constantarr_0_477[26];
char constantarr_0_478[17];
char constantarr_0_479[14];
char constantarr_0_480[30];
char constantarr_0_481[15];
char constantarr_0_482[80];
char constantarr_0_483[11];
char constantarr_0_484[45];
char constantarr_0_485[19];
char constantarr_0_486[22];
char constantarr_0_487[34];
char constantarr_0_488[11];
char constantarr_0_489[17];
char constantarr_0_490[14];
char constantarr_0_491[9];
char constantarr_0_492[6];
char constantarr_0_493[12];
char constantarr_0_494[16];
char constantarr_0_495[36];
char constantarr_0_496[10];
char constantarr_0_497[19];
char constantarr_0_498[15];
char constantarr_0_499[21];
char constantarr_0_500[10];
char constantarr_0_501[18];
char constantarr_0_502[14];
char constantarr_0_503[28];
char constantarr_0_504[9];
char constantarr_0_505[17];
char constantarr_0_506[6];
char constantarr_0_507[21];
char constantarr_0_508[16];
char constantarr_0_509[11];
char constantarr_0_510[17];
char constantarr_0_511[26];
char constantarr_0_512[14];
char constantarr_0_513[8];
char constantarr_0_514[13];
char constantarr_0_515[15];
char constantarr_0_516[26];
char constantarr_0_517[19];
char constantarr_0_518[6];
char constantarr_0_519[7];
char constantarr_0_520[9];
char constantarr_0_521[22];
char constantarr_0_522[17];
char constantarr_0_523[14];
char constantarr_0_524[21];
char constantarr_0_525[32];
char constantarr_0_526[7];
char constantarr_0_527[7];
char constantarr_0_528[9];
char constantarr_0_529[25];
char constantarr_0_530[28];
char constantarr_0_531[19];
char constantarr_0_532[14];
char constantarr_0_533[13];
char constantarr_0_534[19];
char constantarr_0_535[15];
char constantarr_0_536[9];
char constantarr_0_537[19];
char constantarr_0_538[11];
char constantarr_0_539[10];
char constantarr_0_540[11];
char constantarr_0_541[9];
char constantarr_0_542[38];
char constantarr_0_543[12];
char constantarr_0_544[12];
char constantarr_0_545[17];
char constantarr_0_546[11];
char constantarr_0_547[21];
char constantarr_0_548[11];
char constantarr_0_549[10];
char constantarr_0_550[8];
char constantarr_0_551[8];
char constantarr_0_552[5];
char constantarr_0_553[10];
char constantarr_0_554[15];
char constantarr_0_555[29];
char constantarr_0_556[7];
char constantarr_0_557[11];
char constantarr_0_558[10];
char constantarr_0_559[6];
char constantarr_0_560[12];
char constantarr_0_561[33];
char constantarr_0_562[38];
char constantarr_0_563[8];
char constantarr_0_564[30];
char constantarr_0_565[14];
char constantarr_0_566[10];
char constantarr_0_567[13];
char constantarr_0_568[12];
char constantarr_0_569[46];
char constantarr_0_570[13];
char constantarr_0_571[12];
char constantarr_0_572[8];
char constantarr_0_573[20];
char constantarr_0_574[8];
char constantarr_0_575[14];
char constantarr_0_576[20];
char constantarr_0_577[14];
char constantarr_0_578[14];
char constantarr_0_579[7];
char constantarr_0_580[12];
char constantarr_0_581[9];
char constantarr_0_582[18];
char constantarr_0_583[15];
char constantarr_0_584[27];
char constantarr_0_585[15];
char constantarr_0_586[12];
char constantarr_0_587[27];
char constantarr_0_588[6];
char constantarr_0_589[5];
char constantarr_0_590[20];
char constantarr_0_591[19];
char constantarr_0_592[4];
char constantarr_0_593[35];
char constantarr_0_594[18];
char constantarr_0_595[8];
char constantarr_0_596[25];
char constantarr_0_597[4];
char constantarr_0_598[33];
char constantarr_0_599[27];
char constantarr_0_600[21];
char constantarr_0_601[20];
char constantarr_0_602[19];
char constantarr_0_603[4];
char constantarr_0_604[7];
char constantarr_0_605[18];
char constantarr_0_606[11];
char constantarr_0_607[6];
char constantarr_0_608[35];
char constantarr_0_609[20];
char constantarr_0_610[31];
char constantarr_0_611[22];
char constantarr_0_612[9];
char constantarr_0_613[30];
char constantarr_0_614[12];
char constantarr_0_615[39];
char constantarr_0_616[22];
char constantarr_0_617[30];
char constantarr_0_618[10];
char constantarr_0_619[39];
char constantarr_0_620[12];
char constantarr_0_621[8];
char constantarr_0_622[21];
char constantarr_0_623[11];
char constantarr_0_624[16];
char constantarr_0_625[25];
char constantarr_0_626[19];
char constantarr_0_627[11];
char constantarr_0_628[19];
char constantarr_0_629[22];
char constantarr_0_630[8];
char constantarr_0_631[8];
char constantarr_0_632[8];
char constantarr_0_633[16];
char constantarr_0_634[27];
char constantarr_0_635[5];
char constantarr_0_636[8];
char constantarr_0_637[13];
char constantarr_0_638[13];
char constantarr_0_639[23];
char constantarr_0_640[18];
char constantarr_0_641[18];
char constantarr_0_642[9];
char constantarr_0_643[9];
char constantarr_0_644[13];
char constantarr_0_645[35];
char constantarr_0_646[16];
char constantarr_0_647[35];
char constantarr_0_648[16];
char constantarr_0_649[12];
char constantarr_0_650[12];
char constantarr_0_651[22];
char constantarr_0_652[18];
char constantarr_0_653[14];
char constantarr_0_654[8];
char constantarr_0_655[8];
char constantarr_0_656[20];
char constantarr_0_657[13];
char constantarr_0_658[16];
char constantarr_0_659[30];
char constantarr_0_660[40];
char constantarr_0_661[27];
char constantarr_0_662[8];
char constantarr_0_663[12];
char constantarr_0_664[6];
char constantarr_0_665[18];
char constantarr_0_666[19];
char constantarr_0_667[25];
char constantarr_0_668[15];
char constantarr_0_669[21];
char constantarr_0_670[24];
char constantarr_0_671[30];
char constantarr_0_672[1];
char constantarr_0_673[6];
char constantarr_0_674[14];
char constantarr_0_675[13];
char constantarr_0_676[14];
char constantarr_0_677[7];
char constantarr_0_678[14];
char constantarr_0_679[40];
char constantarr_0_680[16];
char constantarr_0_681[16];
char constantarr_0_682[8];
char constantarr_0_683[5];
char constantarr_0_684[34];
char constantarr_0_685[16];
char constantarr_0_686[24];
char constantarr_0_687[10];
char constantarr_0_688[31];
char constantarr_0_689[14];
char constantarr_0_690[23];
char constantarr_0_691[27];
char constantarr_0_692[9];
char constantarr_0_693[8];
char constantarr_0_694[5];
char constantarr_0_695[19];
char constantarr_0_696[27];
char constantarr_0_697[20];
char constantarr_0_698[30];
char constantarr_0_699[34];
char constantarr_0_700[20];
char constantarr_0_701[41];
char constantarr_0_702[8];
char constantarr_0_703[39];
char constantarr_0_704[33];
char constantarr_0_705[21];
char constantarr_0_706[10];
char constantarr_0_707[9];
char constantarr_0_708[15];
char constantarr_0_709[11];
char constantarr_0_710[11];
char constantarr_0_711[10];
char constantarr_0_712[12];
char constantarr_0_713[12];
char constantarr_0_714[13];
char constantarr_0_715[10];
char constantarr_0_716[7];
char constantarr_0_717[11];
char constantarr_0_718[16];
char constantarr_0_719[15];
char constantarr_0_720[21];
char constantarr_0_721[4];
char constantarr_0_722[24];
char constantarr_0_723[23];
char constantarr_0_724[9];
char constantarr_0_725[27];
char constantarr_0_726[8];
char constantarr_0_727[8];
char constantarr_0_728[22];
char constantarr_0_729[17];
char constantarr_0_730[5];
char constantarr_0_731[20];
char constantarr_0_732[6];
char constantarr_0_733[9];
char constantarr_0_734[6];
char constantarr_0_735[10];
char constantarr_0_736[11];
char constantarr_0_737[30];
char constantarr_0_738[17];
char constantarr_0_739[11];
char constantarr_0_740[19];
char constantarr_0_741[24];
char constantarr_0_742[35];
char constantarr_0_743[26];
char constantarr_0_744[24];
char constantarr_0_745[15];
char constantarr_0_746[7];
char constantarr_0_747[35];
char constantarr_0_748[14];
char constantarr_0_749[42];
char constantarr_0_750[13];
char constantarr_0_751[16];
char constantarr_0_752[14];
char constantarr_0_753[10];
char constantarr_0_754[29];
char constantarr_0_755[18];
char constantarr_0_756[20];
char constantarr_0_757[7];
char constantarr_0_758[8];
char constantarr_0_759[10];
char constantarr_0_760[6];
char constantarr_0_761[4];
char constantarr_0_762[12];
char constantarr_0_763[6];
char constantarr_0_764[17];
char constantarr_0_765[10];
char constantarr_0_766[9];
char constantarr_0_767[7];
char constantarr_0_768[13];
char constantarr_0_769[6];
char constantarr_0_770[7];
char constantarr_0_771[15];
char constantarr_0_772[19];
char constantarr_0_773[8];
char constantarr_0_774[7];
char constantarr_0_775[16];
char constantarr_0_776[36];
char constantarr_0_777[14];
char constantarr_0_778[6];
char constantarr_0_779[8];
char constantarr_0_780[12];
char constantarr_0_781[9];
char constantarr_0_782[18];
char constantarr_0_783[17];
char constantarr_0_784[15];
char constantarr_0_785[13];
char constantarr_0_786[15];
char constantarr_0_787[12];
char constantarr_0_788[14];
char constantarr_0_789[7];
char constantarr_0_790[13];
char constantarr_0_791[15];
char constantarr_0_792[9];
char constantarr_0_793[14];
char constantarr_0_794[28];
char constantarr_0_795[13];
char constantarr_0_796[13];
char constantarr_0_797[10];
char constantarr_0_798[11];
char constantarr_0_799[9];
char constantarr_0_800[18];
char constantarr_0_801[42];
char constantarr_0_802[14];
char constantarr_0_803[10];
char constantarr_0_804[8];
char constantarr_0_805[8];
char constantarr_0_806[9];
char constantarr_0_807[8];
char constantarr_0_808[6];
char constantarr_0_809[16];
char constantarr_0_810[25];
char constantarr_0_811[31];
char constantarr_0_812[13];
char constantarr_0_813[8];
char constantarr_0_814[50];
char constantarr_0_815[18];
char constantarr_0_816[20];
char constantarr_0_817[35];
char constantarr_0_818[25];
char constantarr_0_819[12];
char constantarr_0_820[14];
char constantarr_0_821[21];
char constantarr_0_822[26];
char constantarr_0_823[21];
char constantarr_0_824[29];
char constantarr_0_825[8];
char constantarr_0_826[7];
char constantarr_0_827[10];
char constantarr_0_828[5];
char constantarr_0_829[4];
char constantarr_0_830[26];
char constantarr_0_831[29];
char constantarr_0_832[33];
char constantarr_0_833[10];
char constantarr_0_834[32];
char constantarr_0_835[9];
char constantarr_0_836[11];
char constantarr_0_837[11];
char constantarr_0_838[16];
char constantarr_0_839[5];
char constantarr_0_840[14];
char constantarr_0_841[12];
char constantarr_0_842[23];
char constantarr_0_843[6];
char constantarr_0_844[6];
char constantarr_0_845[21];
char constantarr_0_846[16];
char constantarr_0_847[14];
char constantarr_0_848[14];
char constantarr_0_849[21];
char constantarr_0_850[13];
char constantarr_0_851[16];
char constantarr_0_852[4];
char constantarr_0_853[14];
char constantarr_0_854[7];
char constantarr_0_855[11];
char constantarr_0_856[15];
char constantarr_0_857[9];
char constantarr_0_858[24];
char constantarr_0_859[13];
char constantarr_0_860[4];
char constantarr_0_861[27];
char constantarr_0_862[20];
char constantarr_0_863[2];
char constantarr_0_864[12];
char constantarr_0_865[7];
char constantarr_0_866[12];
char constantarr_0_867[7];
char constantarr_0_868[12];
char constantarr_0_869[7];
char constantarr_0_870[12];
char constantarr_0_871[7];
char constantarr_0_872[13];
char constantarr_0_873[8];
char constantarr_0_874[21];
char constantarr_0_875[4];
char constantarr_0_876[11];
char constantarr_0_877[8];
char constantarr_0_878[22];
char constantarr_0_879[7];
char constantarr_0_880[11];
char constantarr_0_881[10];
char constantarr_0_882[13];
char constantarr_0_883[15];
char constantarr_0_884[8];
char constantarr_0_885[11];
char constantarr_0_886[22];
char constantarr_0_887[13];
char constantarr_0_888[3];
char constantarr_0_889[10];
char constantarr_0_890[3];
char constantarr_0_891[6];
char constantarr_0_892[3];
char constantarr_0_893[12];
char constantarr_0_894[14];
char constantarr_0_895[14];
char constantarr_0_896[18];
char constantarr_0_897[12];
char constantarr_0_898[12];
char constantarr_0_899[25];
char constantarr_0_900[33];
char constantarr_0_901[20];
char constantarr_0_902[15];
char constantarr_0_903[19];
char constantarr_0_904[26];
char constantarr_0_905[13];
char constantarr_0_906[23];
char constantarr_0_907[23];
char constantarr_0_908[20];
char constantarr_0_909[9];
char constantarr_0_910[16];
char constantarr_0_911[13];
char constantarr_0_912[13];
char constantarr_0_913[4];
char constantarr_0_914[8];
char constantarr_0_915[20];
char constantarr_0_916[5];
char constantarr_0_917[8];
char constantarr_0_918[8];
char constantarr_0_919[20];
char constantarr_0_920[10];
char constantarr_0_921[9];
char constantarr_0_922[7];
char constantarr_0_923[14];
char constantarr_0_924[8];
char constantarr_0_925[15];
char constantarr_0_926[21];
char constantarr_0_927[7];
char constantarr_0_928[8];
char constantarr_0_929[7];
char constantarr_0_930[7];
char constantarr_0_931[7];
char constantarr_0_932[17];
char constantarr_0_933[13];
char constantarr_0_934[19];
char constantarr_0_935[21];
char constantarr_0_936[8];
char constantarr_0_937[17];
char constantarr_0_938[20];
char constantarr_0_939[12];
char constantarr_0_940[18];
char constantarr_0_941[8];
char constantarr_0_942[28];
char constantarr_0_943[24];
char constantarr_0_944[17];
char constantarr_0_945[10];
char constantarr_0_946[19];
char constantarr_0_947[22];
char constantarr_0_948[13];
char constantarr_0_949[17];
char constantarr_0_950[23];
char constantarr_0_951[15];
char constantarr_0_952[4];
char constantarr_0_953[19];
char constantarr_0_954[19];
char constantarr_0_955[20];
char constantarr_0_956[18];
char constantarr_0_957[16];
char constantarr_0_958[27];
char constantarr_0_959[27];
char constantarr_0_960[25];
char constantarr_0_961[17];
char constantarr_0_962[18];
char constantarr_0_963[27];
char constantarr_0_964[9];
char constantarr_0_965[9];
char constantarr_0_966[26];
char constantarr_0_967[25];
char constantarr_0_968[24];
char constantarr_0_969[5];
char constantarr_0_970[9];
char constantarr_0_971[21];
char constantarr_0_972[9];
char constantarr_0_973[13];
char constantarr_0_974[22];
char constantarr_0_975[9];
char constantarr_0_976[19];
char constantarr_0_977[25];
char constantarr_0_978[8];
char constantarr_0_979[6];
char constantarr_0_980[8];
char constantarr_0_981[15];
char constantarr_0_982[17];
char constantarr_0_983[12];
char constantarr_0_984[15];
char constantarr_0_985[14];
char constantarr_0_986[13];
char constantarr_0_987[10];
char constantarr_0_988[4];
char constantarr_0_989[11];
char constantarr_0_990[22];
char constantarr_0_991[19];
struct arr_0 constantarr_1_0[3];
struct arr_0 constantarr_1_1[4];
struct arr_0 constantarr_1_2[6];
struct arr_0 constantarr_1_3[4];
struct arr_0 constantarr_1_4[6];
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
char constantarr_0_10[11] = "print-tests";
char constantarr_0_11[16] = "overwrite-output";
char constantarr_0_12[12] = "max-failures";
char constantarr_0_13[2] = "--";
char constantarr_0_14[27] = "tried to force empty option";
char constantarr_0_15[26] = "Should be no nameless args";
char constantarr_0_16[4] = "help";
char constantarr_0_17[15] = "Unexpected arg ";
char constantarr_0_18[18] = "test -- runs tests";
char constantarr_0_19[8] = "options:";
char constantarr_0_20[36] = "\t--print-tests: print every test run";
char constantarr_0_21[63] = "\t--max-failures: stop after this many failures. Defaults to 10.";
char constantarr_0_22[1] = "\0";
char constantarr_0_23[14] = "/proc/self/exe";
char constantarr_0_24[1] = "/";
char constantarr_0_25[3] = "bin";
char constantarr_0_26[4] = "crow";
char constantarr_0_27[1] = ".";
char constantarr_0_28[2] = "..";
char constantarr_0_29[3] = "ast";
char constantarr_0_30[5] = "model";
char constantarr_0_31[14] = "concrete-model";
char constantarr_0_32[9] = "low-model";
char constantarr_0_33[11] = "crow print ";
char constantarr_0_34[1] = " ";
char constantarr_0_35[23] = "spawn-and-wait-result: ";
char constantarr_0_36[31] = "Process terminated with signal ";
char constantarr_0_37[1] = "0";
char constantarr_0_38[1] = "1";
char constantarr_0_39[1] = "2";
char constantarr_0_40[1] = "3";
char constantarr_0_41[1] = "4";
char constantarr_0_42[1] = "5";
char constantarr_0_43[1] = "6";
char constantarr_0_44[1] = "7";
char constantarr_0_45[1] = "8";
char constantarr_0_46[1] = "9";
char constantarr_0_47[1] = "-";
char constantarr_0_48[12] = "WAIT STOPPED";
char constantarr_0_49[1] = "=";
char constantarr_0_50[14] = " is not a file";
char constantarr_0_51[5] = "print";
char constantarr_0_52[5] = ".repr";
char constantarr_0_53[20] = "failed to open file ";
char constantarr_0_54[31] = "failed to open file for write: ";
char constantarr_0_55[7] = "errno: ";
char constantarr_0_56[7] = "flags: ";
char constantarr_0_57[12] = "permission: ";
char constantarr_0_58[29] = " does not exist. actual was:\n";
char constantarr_0_59[30] = " was not as expected. actual:\n";
char constantarr_0_60[4] = ".err";
char constantarr_0_61[22] = "unexpected exit code: ";
char constantarr_0_62[9] = "crow run ";
char constantarr_0_63[3] = "run";
char constantarr_0_64[11] = "--interpret";
char constantarr_0_65[7] = ".stdout";
char constantarr_0_66[7] = ".stderr";
char constantarr_0_67[4] = "ran ";
char constantarr_0_68[10] = " tests in ";
char constantarr_0_69[12] = "parse-errors";
char constantarr_0_70[14] = "compile-errors";
char constantarr_0_71[8] = "runnable";
char constantarr_0_72[4] = ".bmp";
char constantarr_0_73[4] = ".png";
char constantarr_0_74[4] = ".ttf";
char constantarr_0_75[5] = ".wasm";
char constantarr_0_76[7] = "dyncall";
char constantarr_0_77[7] = "libfirm";
char constantarr_0_78[12] = "node_modules";
char constantarr_0_79[17] = "package-lock.json";
char constantarr_0_80[1] = "c";
char constantarr_0_81[4] = "data";
char constantarr_0_82[1] = "o";
char constantarr_0_83[3] = "out";
char constantarr_0_84[4] = "repr";
char constantarr_0_85[10] = "tmLanguage";
char constantarr_0_86[5] = "lint ";
char constantarr_0_87[21] = "file does not exist: ";
char constantarr_0_88[3] = "err";
char constantarr_0_89[14] = "sublime-syntax";
char constantarr_0_90[5] = "line ";
char constantarr_0_91[24] = " contains a double space";
char constantarr_0_92[4] = " is ";
char constantarr_0_93[28] = " columns long, should be <= ";
char constantarr_0_94[7] = "linted ";
char constantarr_0_95[6] = " files";
char constantarr_0_96[4] = "\x1b[1m";
char constantarr_0_97[3] = "\x1b[m";
char constantarr_0_98[15] = "hit maximum of ";
char constantarr_0_99[9] = " failures";
char constantarr_0_100[4] = "mark";
char constantarr_0_101[14] = "words-of-bytes";
char constantarr_0_102[10] = "unsafe-div";
char constantarr_0_103[25] = "round-up-to-multiple-of-8";
char constantarr_0_104[8] = "bits-and";
char constantarr_0_105[8] = "wrap-add";
char constantarr_0_106[8] = "bits-not";
char constantarr_0_107[12] = "as<ptr<nat>>";
char constantarr_0_108[19] = "ptr-cast<nat, nat8>";
char constantarr_0_109[11] = "hard-assert";
char constantarr_0_110[3] = "not";
char constantarr_0_111[5] = "false";
char constantarr_0_112[4] = "true";
char constantarr_0_113[6] = "abort!";
char constantarr_0_114[7] = "==<nat>";
char constantarr_0_115[7] = "<=><?t>";
char constantarr_0_116[11] = "to-nat<nat>";
char constantarr_0_117[6] = "-<nat>";
char constantarr_0_118[8] = "wrap-sub";
char constantarr_0_119[11] = "size-of<?t>";
char constantarr_0_120[12] = "memory-start";
char constantarr_0_121[6] = "<<nat>";
char constantarr_0_122[17] = "memory-size-words";
char constantarr_0_123[7] = "<=<nat>";
char constantarr_0_124[7] = "+<bool>";
char constantarr_0_125[5] = "marks";
char constantarr_0_126[16] = "mark-range-recur";
char constantarr_0_127[13] = "ptr-eq?<bool>";
char constantarr_0_128[2] = "or";
char constantarr_0_129[15] = "subscript<bool>";
char constantarr_0_130[19] = "set-subscript<bool>";
char constantarr_0_131[10] = "incr<bool>";
char constantarr_0_132[6] = "><nat>";
char constantarr_0_133[7] = "rt-main";
char constantarr_0_134[10] = "get-nprocs";
char constantarr_0_135[22] = "as<by-val<global-ctx>>";
char constantarr_0_136[10] = "global-ctx";
char constantarr_0_137[11] = "lock-by-val";
char constantarr_0_138[4] = "lock";
char constantarr_0_139[11] = "atomic-bool";
char constantarr_0_140[9] = "condition";
char constantarr_0_141[22] = "ref-of-val<global-ctx>";
char constantarr_0_142[6] = "island";
char constantarr_0_143[10] = "task-queue";
char constantarr_0_144[4] = "none";
char constantarr_0_145[56] = "mut-list-by-val-with-capacity-from-unmanaged-memory<nat>";
char constantarr_0_146[11] = "mut-arr<?t>";
char constantarr_0_147[4] = "void";
char constantarr_0_148[7] = "arr<?t>";
char constantarr_0_149[35] = "unmanaged-alloc-zeroed-elements<?t>";
char constantarr_0_150[28] = "unmanaged-alloc-elements<?t>";
char constantarr_0_151[21] = "unmanaged-alloc-bytes";
char constantarr_0_152[6] = "malloc";
char constantarr_0_153[11] = "hard-forbid";
char constantarr_0_154[11] = "null?<nat8>";
char constantarr_0_155[10] = "to-nat<?t>";
char constantarr_0_156[8] = "null<?t>";
char constantarr_0_157[8] = "wrap-mul";
char constantarr_0_158[18] = "set-zero-range<?t>";
char constantarr_0_159[6] = "memset";
char constantarr_0_160[19] = "as-any-ptr<ptr<?t>>";
char constantarr_0_161[12] = "mut-list<?t>";
char constantarr_0_162[26] = "as<by-val<island-gc-root>>";
char constantarr_0_163[14] = "island-gc-root";
char constantarr_0_164[25] = "default-exception-handler";
char constantarr_0_165[20] = "print-err-no-newline";
char constantarr_0_166[16] = "write-no-newline";
char constantarr_0_167[13] = "size-of<char>";
char constantarr_0_168[13] = "size-of<nat8>";
char constantarr_0_169[5] = "write";
char constantarr_0_170[21] = "as-any-ptr<ptr<char>>";
char constantarr_0_171[10] = "data<char>";
char constantarr_0_172[10] = "size<char>";
char constantarr_0_173[7] = "!=<int>";
char constantarr_0_174[6] = "==<?t>";
char constantarr_0_175[13] = "unsafe-to-int";
char constantarr_0_176[10] = "todo<void>";
char constantarr_0_177[10] = "zeroed<?t>";
char constantarr_0_178[6] = "stderr";
char constantarr_0_179[9] = "print-err";
char constantarr_0_180[14] = "show-exception";
char constantarr_0_181[12] = "?<arr<char>>";
char constantarr_0_182[12] = "empty?<char>";
char constantarr_0_183[7] = "message";
char constantarr_0_184[10] = "join<char>";
char constantarr_0_185[15] = "empty?<arr<?t>>";
char constantarr_0_186[8] = "size<?t>";
char constantarr_0_187[18] = "subscript<arr<?t>>";
char constantarr_0_188[6] = "assert";
char constantarr_0_189[10] = "fail<void>";
char constantarr_0_190[9] = "throw<?t>";
char constantarr_0_191[17] = "get-exception-ctx";
char constantarr_0_192[21] = "as-ref<exception-ctx>";
char constantarr_0_193[17] = "exception-ctx-ptr";
char constantarr_0_194[7] = "get-ctx";
char constantarr_0_195[18] = "null?<jmp-buf-tag>";
char constantarr_0_196[11] = "jmp-buf-ptr";
char constantarr_0_197[20] = "set-thrown-exception";
char constantarr_0_198[7] = "longjmp";
char constantarr_0_199[15] = "number-to-throw";
char constantarr_0_200[9] = "exception";
char constantarr_0_201[13] = "get-backtrace";
char constantarr_0_202[24] = "try-alloc-backtrace-arrs";
char constantarr_0_203[34] = "try-alloc-uninitialized<ptr<nat8>>";
char constantarr_0_204[9] = "try-alloc";
char constantarr_0_205[12] = "try-gc-alloc";
char constantarr_0_206[8] = "acquire!";
char constantarr_0_207[14] = "acquire-recur!";
char constantarr_0_208[12] = "try-acquire!";
char constantarr_0_209[8] = "try-set!";
char constantarr_0_210[11] = "try-change!";
char constantarr_0_211[23] = "compare-exchange-strong";
char constantarr_0_212[12] = "ptr-to<bool>";
char constantarr_0_213[5] = "value";
char constantarr_0_214[23] = "ref-of-val<atomic-bool>";
char constantarr_0_215[9] = "is-locked";
char constantarr_0_216[12] = "yield-thread";
char constantarr_0_217[13] = "pthread-yield";
char constantarr_0_218[9] = "==<int32>";
char constantarr_0_219[10] = "noctx-incr";
char constantarr_0_220[16] = "ref-of-val<lock>";
char constantarr_0_221[2] = "lk";
char constantarr_0_222[18] = "try-gc-alloc-recur";
char constantarr_0_223[11] = "validate-gc";
char constantarr_0_224[18] = "ptr-less-eq?<bool>";
char constantarr_0_225[13] = "ptr-less?<?t>";
char constantarr_0_226[10] = "mark-begin";
char constantarr_0_227[8] = "mark-cur";
char constantarr_0_228[8] = "mark-end";
char constantarr_0_229[17] = "ptr-less-eq?<nat>";
char constantarr_0_230[11] = "ptr-eq?<?t>";
char constantarr_0_231[10] = "data-begin";
char constantarr_0_232[8] = "data-cur";
char constantarr_0_233[8] = "data-end";
char constantarr_0_234[7] = "-<bool>";
char constantarr_0_235[10] = "size-words";
char constantarr_0_236[6] = "+<nat>";
char constantarr_0_237[11] = "range-free?";
char constantarr_0_238[12] = "set-mark-cur";
char constantarr_0_239[12] = "set-data-cur";
char constantarr_0_240[15] = "some<ptr<nat8>>";
char constantarr_0_241[19] = "ptr-cast<nat8, nat>";
char constantarr_0_242[9] = "incr<nat>";
char constantarr_0_243[8] = "release!";
char constantarr_0_244[11] = "must-unset!";
char constantarr_0_245[10] = "try-unset!";
char constantarr_0_246[6] = "get-gc";
char constantarr_0_247[2] = "gc";
char constantarr_0_248[10] = "get-gc-ctx";
char constantarr_0_249[14] = "as-ref<gc-ctx>";
char constantarr_0_250[10] = "gc-ctx-ptr";
char constantarr_0_251[13] = "some<ptr<?t>>";
char constantarr_0_252[18] = "ptr-cast<?t, nat8>";
char constantarr_0_253[16] = "value<ptr<nat8>>";
char constantarr_0_254[34] = "try-alloc-uninitialized<arr<char>>";
char constantarr_0_255[10] = "funs-count";
char constantarr_0_256[20] = "some<backtrace-arrs>";
char constantarr_0_257[14] = "backtrace-arrs";
char constantarr_0_258[21] = "value<ptr<ptr<nat8>>>";
char constantarr_0_259[21] = "value<ptr<arr<char>>>";
char constantarr_0_260[9] = "backtrace";
char constantarr_0_261[18] = "as<arr<arr<char>>>";
char constantarr_0_262[21] = "value<backtrace-arrs>";
char constantarr_0_263[13] = "unsafe-to-nat";
char constantarr_0_264[6] = "to-int";
char constantarr_0_265[9] = "code-ptrs";
char constantarr_0_266[15] = "unsafe-to-int32";
char constantarr_0_267[14] = "code-ptrs-size";
char constantarr_0_268[25] = "fill-fun-ptrs-names-recur";
char constantarr_0_269[7] = "!=<nat>";
char constantarr_0_270[24] = "set-subscript<ptr<nat8>>";
char constantarr_0_271[17] = "set-subscript<?t>";
char constantarr_0_272[5] = "+<?t>";
char constantarr_0_273[11] = "get-fun-ptr";
char constantarr_0_274[24] = "set-subscript<arr<char>>";
char constantarr_0_275[12] = "get-fun-name";
char constantarr_0_276[8] = "fun-ptrs";
char constantarr_0_277[9] = "fun-names";
char constantarr_0_278[13] = "sort-together";
char constantarr_0_279[15] = "swap<ptr<nat8>>";
char constantarr_0_280[13] = "subscript<?t>";
char constantarr_0_281[15] = "swap<arr<char>>";
char constantarr_0_282[24] = "partition-recur-together";
char constantarr_0_283[15] = "ptr-less?<nat8>";
char constantarr_0_284[10] = "noctx-decr";
char constantarr_0_285[10] = "code-names";
char constantarr_0_286[21] = "fill-code-names-recur";
char constantarr_0_287[20] = "ptr-less?<arr<char>>";
char constantarr_0_288[15] = "incr<ptr<nat8>>";
char constantarr_0_289[15] = "incr<arr<char>>";
char constantarr_0_290[14] = "arr<arr<char>>";
char constantarr_0_291[12] = "noctx-at<?t>";
char constantarr_0_292[8] = "data<?t>";
char constantarr_0_293[5] = "~<?t>";
char constantarr_0_294[1] = "+";
char constantarr_0_295[3] = "and";
char constantarr_0_296[7] = ">=<nat>";
char constantarr_0_297[23] = "alloc-uninitialized<?t>";
char constantarr_0_298[5] = "alloc";
char constantarr_0_299[8] = "gc-alloc";
char constantarr_0_300[15] = "todo<ptr<nat8>>";
char constantarr_0_301[18] = "copy-data-from<?t>";
char constantarr_0_302[6] = "memcpy";
char constantarr_0_303[13] = "tail<arr<?t>>";
char constantarr_0_304[6] = "forbid";
char constantarr_0_305[14] = "from<nat, nat>";
char constantarr_0_306[12] = "to<nat, nat>";
char constantarr_0_307[12] = "-><nat, nat>";
char constantarr_0_308[13] = "arrow<?a, ?b>";
char constantarr_0_309[12] = "return-stack";
char constantarr_0_310[29] = "set-any-unhandled-exceptions?";
char constantarr_0_311[14] = "get-global-ctx";
char constantarr_0_312[18] = "as-ref<global-ctx>";
char constantarr_0_313[8] = "gctx-ptr";
char constantarr_0_314[14] = "island.lambda0";
char constantarr_0_315[19] = "default-log-handler";
char constantarr_0_316[16] = "print-no-newline";
char constantarr_0_317[6] = "stdout";
char constantarr_0_318[6] = "to-str";
char constantarr_0_319[5] = "level";
char constantarr_0_320[14] = "island.lambda1";
char constantarr_0_321[20] = "ptr-cast<bool, nat8>";
char constantarr_0_322[21] = "as-any-ptr<ptr<bool>>";
char constantarr_0_323[19] = "thread-safe-counter";
char constantarr_0_324[18] = "ref-of-val<island>";
char constantarr_0_325[11] = "set-islands";
char constantarr_0_326[11] = "arr<island>";
char constantarr_0_327[14] = "ptr-to<island>";
char constantarr_0_328[7] = "do-main";
char constantarr_0_329[13] = "exception-ctx";
char constantarr_0_330[7] = "log-ctx";
char constantarr_0_331[26] = "zeroed<fun1<void, logged>>";
char constantarr_0_332[30] = "as<by-val<thread-local-stuff>>";
char constantarr_0_333[18] = "thread-local-stuff";
char constantarr_0_334[25] = "ref-of-val<exception-ctx>";
char constantarr_0_335[19] = "ref-of-val<log-ctx>";
char constantarr_0_336[3] = "ctx";
char constantarr_0_337[18] = "as-any-ptr<gc-ctx>";
char constantarr_0_338[12] = "context-head";
char constantarr_0_339[23] = "size-of<by-val<gc-ctx>>";
char constantarr_0_340[6] = "set-gc";
char constantarr_0_341[12] = "set-next-ctx";
char constantarr_0_342[13] = "value<gc-ctx>";
char constantarr_0_343[16] = "set-context-head";
char constantarr_0_344[8] = "next-ctx";
char constantarr_0_345[14] = "ref-of-val<gc>";
char constantarr_0_346[11] = "set-handler";
char constantarr_0_347[11] = "log-handler";
char constantarr_0_348[26] = "ref-of-val<island-gc-root>";
char constantarr_0_349[7] = "gc-root";
char constantarr_0_350[22] = "as-any-ptr<global-ctx>";
char constantarr_0_351[2] = "id";
char constantarr_0_352[25] = "as-any-ptr<exception-ctx>";
char constantarr_0_353[19] = "as-any-ptr<log-ctx>";
char constantarr_0_354[30] = "ref-of-val<thread-local-stuff>";
char constantarr_0_355[15] = "ref-of-val<ctx>";
char constantarr_0_356[79] = "as<fun-act2<fut<nat>, arr<ptr<char>>, fun-ptr2<fut<nat>, ctx, arr<arr<char>>>>>";
char constantarr_0_357[14] = "add-first-task";
char constantarr_0_358[10] = "then2<nat>";
char constantarr_0_359[16] = "then<?out, void>";
char constantarr_0_360[16] = "unresolved<?out>";
char constantarr_0_361[7] = "fut<?t>";
char constantarr_0_362[23] = "fut-state-callbacks<?t>";
char constantarr_0_363[14] = "callback!<?in>";
char constantarr_0_364[15] = "with-lock<void>";
char constantarr_0_365[17] = "call-with-ctx<?r>";
char constantarr_0_366[6] = "lk<?t>";
char constantarr_0_367[9] = "state<?t>";
char constantarr_0_368[13] = "set-state<?t>";
char constantarr_0_369[27] = "some<fut-callback-node<?t>>";
char constantarr_0_370[21] = "fut-callback-node<?t>";
char constantarr_0_371[8] = "head<?t>";
char constantarr_0_372[38] = "subscript<void, result<?t, exception>>";
char constantarr_0_373[22] = "call-with-ctx<?r, ?p0>";
char constantarr_0_374[6] = "ok<?t>";
char constantarr_0_375[9] = "value<?t>";
char constantarr_0_376[14] = "err<exception>";
char constantarr_0_377[22] = "callback!<?in>.lambda0";
char constantarr_0_378[17] = "forward-to!<?out>";
char constantarr_0_379[13] = "callback!<?t>";
char constantarr_0_380[21] = "callback!<?t>.lambda0";
char constantarr_0_381[22] = "resolve-or-reject!<?t>";
char constantarr_0_382[34] = "with-lock<fut-state-callbacks<?t>>";
char constantarr_0_383[29] = "todo<fut-state-callbacks<?t>>";
char constantarr_0_384[22] = "fut-state-resolved<?t>";
char constantarr_0_385[16] = "value<exception>";
char constantarr_0_386[30] = "resolve-or-reject!<?t>.lambda0";
char constantarr_0_387[19] = "call-callbacks!<?t>";
char constantarr_0_388[10] = "drop<void>";
char constantarr_0_389[6] = "cb<?t>";
char constantarr_0_390[28] = "value<fut-callback-node<?t>>";
char constantarr_0_391[13] = "next-node<?t>";
char constantarr_0_392[25] = "forward-to!<?out>.lambda0";
char constantarr_0_393[20] = "subscript<?out, ?in>";
char constantarr_0_394[10] = "get-island";
char constantarr_0_395[17] = "subscript<island>";
char constantarr_0_396[7] = "islands";
char constantarr_0_397[29] = "island-and-exclusion<?r, ?p0>";
char constantarr_0_398[8] = "add-task";
char constantarr_0_399[15] = "task-queue-node";
char constantarr_0_400[4] = "task";
char constantarr_0_401[10] = "tasks-lock";
char constantarr_0_402[12] = "insert-task!";
char constantarr_0_403[4] = "size";
char constantarr_0_404[10] = "size-recur";
char constantarr_0_405[4] = "next";
char constantarr_0_406[22] = "value<task-queue-node>";
char constantarr_0_407[4] = "head";
char constantarr_0_408[8] = "set-head";
char constantarr_0_409[21] = "some<task-queue-node>";
char constantarr_0_410[4] = "time";
char constantarr_0_411[12] = "insert-recur";
char constantarr_0_412[8] = "set-next";
char constantarr_0_413[5] = "tasks";
char constantarr_0_414[22] = "ref-of-val<task-queue>";
char constantarr_0_415[10] = "broadcast!";
char constantarr_0_416[9] = "set-value";
char constantarr_0_417[21] = "ref-of-val<condition>";
char constantarr_0_418[17] = "may-be-work-to-do";
char constantarr_0_419[4] = "gctx";
char constantarr_0_420[12] = "no-timestamp";
char constantarr_0_421[9] = "exclusion";
char constantarr_0_422[11] = "catch<void>";
char constantarr_0_423[28] = "catch-with-exception-ctx<?t>";
char constantarr_0_424[16] = "thrown-exception";
char constantarr_0_425[11] = "jmp-buf-tag";
char constantarr_0_426[4] = "zero";
char constantarr_0_427[7] = "bytes64";
char constantarr_0_428[7] = "bytes32";
char constantarr_0_429[7] = "bytes16";
char constantarr_0_430[8] = "bytes128";
char constantarr_0_431[15] = "set-jmp-buf-ptr";
char constantarr_0_432[19] = "ptr-to<jmp-buf-tag>";
char constantarr_0_433[6] = "setjmp";
char constantarr_0_434[24] = "subscript<?t, exception>";
char constantarr_0_435[23] = "subscript<fut<?r>, ?p0>";
char constantarr_0_436[12] = "fun<?r, ?p0>";
char constantarr_0_437[36] = "subscript<?out, ?in>.lambda0.lambda0";
char constantarr_0_438[11] = "reject!<?r>";
char constantarr_0_439[36] = "subscript<?out, ?in>.lambda0.lambda1";
char constantarr_0_440[28] = "subscript<?out, ?in>.lambda0";
char constantarr_0_441[10] = "value<?in>";
char constantarr_0_442[24] = "then<?out, void>.lambda0";
char constantarr_0_443[15] = "subscript<?out>";
char constantarr_0_444[24] = "island-and-exclusion<?r>";
char constantarr_0_445[18] = "subscript<fut<?r>>";
char constantarr_0_446[7] = "fun<?r>";
char constantarr_0_447[31] = "subscript<?out>.lambda0.lambda0";
char constantarr_0_448[31] = "subscript<?out>.lambda0.lambda1";
char constantarr_0_449[23] = "subscript<?out>.lambda0";
char constantarr_0_450[18] = "then2<nat>.lambda0";
char constantarr_0_451[24] = "cur-island-and-exclusion";
char constantarr_0_452[20] = "island-and-exclusion";
char constantarr_0_453[9] = "island-id";
char constantarr_0_454[5] = "delay";
char constantarr_0_455[14] = "resolved<void>";
char constantarr_0_456[15] = "tail<ptr<char>>";
char constantarr_0_457[10] = "empty?<?t>";
char constantarr_0_458[40] = "subscript<fut<nat>, ctx, arr<arr<char>>>";
char constantarr_0_459[25] = "map<arr<char>, ptr<char>>";
char constantarr_0_460[14] = "make-arr<?out>";
char constantarr_0_461[18] = "fill-ptr-range<?t>";
char constantarr_0_462[24] = "fill-ptr-range-recur<?t>";
char constantarr_0_463[18] = "subscript<?t, nat>";
char constantarr_0_464[14] = "subscript<?in>";
char constantarr_0_465[33] = "map<arr<char>, ptr<char>>.lambda0";
char constantarr_0_466[24] = "arr-from-begin-end<char>";
char constantarr_0_467[5] = "-<?t>";
char constantarr_0_468[13] = "find-cstr-end";
char constantarr_0_469[17] = "find-char-in-cstr";
char constantarr_0_470[8] = "==<char>";
char constantarr_0_471[15] = "subscript<char>";
char constantarr_0_472[15] = "todo<ptr<char>>";
char constantarr_0_473[10] = "incr<char>";
char constantarr_0_474[30] = "add-first-task.lambda0.lambda0";
char constantarr_0_475[22] = "add-first-task.lambda0";
char constantarr_0_476[22] = "handle-exceptions<nat>";
char constantarr_0_477[26] = "subscript<void, exception>";
char constantarr_0_478[17] = "exception-handler";
char constantarr_0_479[14] = "get-cur-island";
char constantarr_0_480[30] = "handle-exceptions<nat>.lambda0";
char constantarr_0_481[15] = "do-main.lambda0";
char constantarr_0_482[80] = "call-with-ctx<fut<nat>, arr<ptr<char>>, fun-ptr2<fut<nat>, ctx, arr<arr<char>>>>";
char constantarr_0_483[11] = "run-threads";
char constantarr_0_484[45] = "unmanaged-alloc-elements<by-val<thread-args>>";
char constantarr_0_485[19] = "start-threads-recur";
char constantarr_0_486[22] = "+<by-val<thread-args>>";
char constantarr_0_487[34] = "set-subscript<by-val<thread-args>>";
char constantarr_0_488[11] = "thread-args";
char constantarr_0_489[17] = "create-one-thread";
char constantarr_0_490[14] = "pthread-create";
char constantarr_0_491[9] = "!=<int32>";
char constantarr_0_492[6] = "eagain";
char constantarr_0_493[12] = "as-cell<nat>";
char constantarr_0_494[16] = "as-ref<cell<?t>>";
char constantarr_0_495[36] = "as-any-ptr<ptr<by-val<thread-args>>>";
char constantarr_0_496[10] = "thread-fun";
char constantarr_0_497[19] = "as-ref<thread-args>";
char constantarr_0_498[15] = "thread-function";
char constantarr_0_499[21] = "thread-function-recur";
char constantarr_0_500[10] = "shut-down?";
char constantarr_0_501[18] = "set-n-live-threads";
char constantarr_0_502[14] = "n-live-threads";
char constantarr_0_503[28] = "assert-islands-are-shut-down";
char constantarr_0_504[9] = "needs-gc?";
char constantarr_0_505[17] = "n-threads-running";
char constantarr_0_506[6] = "empty?";
char constantarr_0_507[21] = "has?<task-queue-node>";
char constantarr_0_508[16] = "get-last-checked";
char constantarr_0_509[11] = "choose-task";
char constantarr_0_510[17] = "get-monotime-nsec";
char constantarr_0_511[26] = "as<by-val<cell<timespec>>>";
char constantarr_0_512[14] = "cell<timespec>";
char constantarr_0_513[8] = "timespec";
char constantarr_0_514[13] = "clock-gettime";
char constantarr_0_515[15] = "clock-monotonic";
char constantarr_0_516[26] = "ref-of-val<cell<timespec>>";
char constantarr_0_517[19] = "subscript<timespec>";
char constantarr_0_518[6] = "tv-sec";
char constantarr_0_519[7] = "tv-nsec";
char constantarr_0_520[9] = "todo<nat>";
char constantarr_0_521[22] = "as<choose-task-result>";
char constantarr_0_522[17] = "choose-task-recur";
char constantarr_0_523[14] = "no-chosen-task";
char constantarr_0_524[21] = "choose-task-in-island";
char constantarr_0_525[32] = "as<choose-task-in-island-result>";
char constantarr_0_526[7] = "do-a-gc";
char constantarr_0_527[7] = "no-task";
char constantarr_0_528[9] = "pop-task!";
char constantarr_0_529[25] = "ref-of-val<mut-list<nat>>";
char constantarr_0_530[28] = "currently-running-exclusions";
char constantarr_0_531[19] = "as<pop-task-result>";
char constantarr_0_532[14] = "contains?<nat>";
char constantarr_0_533[13] = "contains?<?t>";
char constantarr_0_534[19] = "contains-recur?<?t>";
char constantarr_0_535[15] = "temp-as-arr<?t>";
char constantarr_0_536[9] = "inner<?t>";
char constantarr_0_537[19] = "temp-as-mut-arr<?t>";
char constantarr_0_538[11] = "backing<?t>";
char constantarr_0_539[10] = "pop-recur!";
char constantarr_0_540[11] = "to-opt-time";
char constantarr_0_541[9] = "some<nat>";
char constantarr_0_542[38] = "push-capacity-must-be-sufficient!<nat>";
char constantarr_0_543[12] = "capacity<?t>";
char constantarr_0_544[12] = "set-size<?t>";
char constantarr_0_545[17] = "noctx-set-at!<?t>";
char constantarr_0_546[11] = "is-no-task?";
char constantarr_0_547[21] = "set-n-threads-running";
char constantarr_0_548[11] = "chosen-task";
char constantarr_0_549[10] = "any-tasks?";
char constantarr_0_550[8] = "min-time";
char constantarr_0_551[8] = "min<nat>";
char constantarr_0_552[5] = "?<?t>";
char constantarr_0_553[10] = "value<nat>";
char constantarr_0_554[15] = "first-task-time";
char constantarr_0_555[29] = "no-tasks-and-last-thread-out?";
char constantarr_0_556[7] = "do-task";
char constantarr_0_557[11] = "task-island";
char constantarr_0_558[10] = "task-or-gc";
char constantarr_0_559[6] = "action";
char constantarr_0_560[12] = "return-task!";
char constantarr_0_561[33] = "noctx-must-remove-unordered!<nat>";
char constantarr_0_562[38] = "noctx-must-remove-unordered-recur!<?t>";
char constantarr_0_563[8] = "drop<?t>";
char constantarr_0_564[30] = "noctx-remove-unordered-at!<?t>";
char constantarr_0_565[14] = "noctx-last<?t>";
char constantarr_0_566[10] = "return-ctx";
char constantarr_0_567[13] = "return-gc-ctx";
char constantarr_0_568[12] = "some<gc-ctx>";
char constantarr_0_569[46] = "run-garbage-collection<by-val<island-gc-root>>";
char constantarr_0_570[13] = "set-needs-gc?";
char constantarr_0_571[12] = "set-gc-count";
char constantarr_0_572[8] = "gc-count";
char constantarr_0_573[20] = "as<by-val<mark-ctx>>";
char constantarr_0_574[8] = "mark-ctx";
char constantarr_0_575[14] = "mark-visit<?a>";
char constantarr_0_576[20] = "ref-of-val<mark-ctx>";
char constantarr_0_577[14] = "clear-free-mem";
char constantarr_0_578[14] = "set-shut-down?";
char constantarr_0_579[7] = "wait-on";
char constantarr_0_580[12] = "before-time?";
char constantarr_0_581[9] = "thread-id";
char constantarr_0_582[18] = "join-threads-recur";
char constantarr_0_583[15] = "join-one-thread";
char constantarr_0_584[27] = "as<by-val<cell<ptr<nat8>>>>";
char constantarr_0_585[15] = "cell<ptr<nat8>>";
char constantarr_0_586[12] = "pthread-join";
char constantarr_0_587[27] = "ref-of-val<cell<ptr<nat8>>>";
char constantarr_0_588[6] = "einval";
char constantarr_0_589[5] = "esrch";
char constantarr_0_590[20] = "subscript<ptr<nat8>>";
char constantarr_0_591[19] = "unmanaged-free<nat>";
char constantarr_0_592[4] = "free";
char constantarr_0_593[35] = "unmanaged-free<by-val<thread-args>>";
char constantarr_0_594[18] = "ptr-cast<nat8, ?t>";
char constantarr_0_595[8] = "?<int32>";
char constantarr_0_596[25] = "any-unhandled-exceptions?";
char constantarr_0_597[4] = "main";
char constantarr_0_598[33] = "parse-cmd-line-args<test-options>";
char constantarr_0_599[27] = "parse-cmd-line-args-dynamic";
char constantarr_0_600[21] = "find-index<arr<char>>";
char constantarr_0_601[20] = "find-index-recur<?t>";
char constantarr_0_602[19] = "subscript<bool, ?t>";
char constantarr_0_603[4] = "incr";
char constantarr_0_604[7] = "max-nat";
char constantarr_0_605[18] = "starts-with?<char>";
char constantarr_0_606[11] = "arr-eq?<?t>";
char constantarr_0_607[6] = "!=<?t>";
char constantarr_0_608[35] = "parse-cmd-line-args-dynamic.lambda0";
char constantarr_0_609[20] = "parsed-cmd-line-args";
char constantarr_0_610[31] = "dict<arr<char>, arr<arr<char>>>";
char constantarr_0_611[22] = "map<?k, arrow<?k, ?v>>";
char constantarr_0_612[9] = "size<?in>";
char constantarr_0_613[30] = "map<?k, arrow<?k, ?v>>.lambda0";
char constantarr_0_614[12] = "from<?k, ?v>";
char constantarr_0_615[39] = "dict<arr<char>, arr<arr<char>>>.lambda0";
char constantarr_0_616[22] = "map<?v, arrow<?k, ?v>>";
char constantarr_0_617[30] = "map<?v, arrow<?k, ?v>>.lambda0";
char constantarr_0_618[10] = "to<?k, ?v>";
char constantarr_0_619[39] = "dict<arr<char>, arr<arr<char>>>.lambda1";
char constantarr_0_620[12] = "dict<?k, ?v>";
char constantarr_0_621[8] = "size<?v>";
char constantarr_0_622[21] = "sort-by-first<?k, ?v>";
char constantarr_0_623[11] = "mut-arr<?a>";
char constantarr_0_624[16] = "make-mut-arr<?t>";
char constantarr_0_625[25] = "uninitialized-mut-arr<?t>";
char constantarr_0_626[19] = "mut-arr<?a>.lambda0";
char constantarr_0_627[11] = "mut-arr<?b>";
char constantarr_0_628[19] = "mut-arr<?b>.lambda0";
char constantarr_0_629[22] = "sort-by-first!<?a, ?b>";
char constantarr_0_630[8] = "size<?a>";
char constantarr_0_631[8] = "size<?b>";
char constantarr_0_632[8] = "swap<?a>";
char constantarr_0_633[16] = "noctx-set-at<?t>";
char constantarr_0_634[27] = "partition-by-first!<?a, ?b>";
char constantarr_0_635[5] = "<<?a>";
char constantarr_0_636[8] = "swap<?b>";
char constantarr_0_637[13] = "subscript<?a>";
char constantarr_0_638[13] = "subscript<?b>";
char constantarr_0_639[23] = "sorted-by-first<?a, ?b>";
char constantarr_0_640[18] = "cast-immutable<?a>";
char constantarr_0_641[18] = "cast-immutable<?b>";
char constantarr_0_642[9] = "a<?k, ?v>";
char constantarr_0_643[9] = "b<?k, ?v>";
char constantarr_0_644[13] = "==<arr<char>>";
char constantarr_0_645[35] = "parse-cmd-line-args-dynamic.lambda1";
char constantarr_0_646[16] = "parse-named-args";
char constantarr_0_647[35] = "mut-dict<arr<char>, arr<arr<char>>>";
char constantarr_0_648[16] = "mut-dict<?k, ?v>";
char constantarr_0_649[12] = "mut-list<?k>";
char constantarr_0_650[12] = "mut-list<?v>";
char constantarr_0_651[22] = "parse-named-args-recur";
char constantarr_0_652[18] = "remove-start<char>";
char constantarr_0_653[14] = "force<arr<?t>>";
char constantarr_0_654[8] = "fail<?t>";
char constantarr_0_655[8] = "todo<?t>";
char constantarr_0_656[20] = "try-remove-start<?t>";
char constantarr_0_657[13] = "some<arr<?t>>";
char constantarr_0_658[16] = "first<arr<char>>";
char constantarr_0_659[30] = "parse-named-args-recur.lambda0";
char constantarr_0_660[40] = "set-subscript<arr<char>, arr<arr<char>>>";
char constantarr_0_661[27] = "set-subscript-recur<?k, ?v>";
char constantarr_0_662[8] = "size<?k>";
char constantarr_0_663[12] = "keys<?k, ?v>";
char constantarr_0_664[6] = "~=<?k>";
char constantarr_0_665[18] = "incr-capacity!<?t>";
char constantarr_0_666[19] = "ensure-capacity<?t>";
char constantarr_0_667[25] = "increase-capacity-to!<?t>";
char constantarr_0_668[15] = "set-backing<?t>";
char constantarr_0_669[21] = "set-zero-elements<?t>";
char constantarr_0_670[24] = "round-up-to-power-of-two";
char constantarr_0_671[30] = "round-up-to-power-of-two-recur";
char constantarr_0_672[1] = "*";
char constantarr_0_673[6] = "~=<?v>";
char constantarr_0_674[14] = "values<?k, ?v>";
char constantarr_0_675[13] = "subscript<?k>";
char constantarr_0_676[14] = "insert-at!<?k>";
char constantarr_0_677[7] = "memmove";
char constantarr_0_678[14] = "insert-at!<?v>";
char constantarr_0_679[40] = "move-to-dict!<arr<char>, arr<arr<char>>>";
char constantarr_0_680[16] = "move-to-arr!<?k>";
char constantarr_0_681[16] = "move-to-arr!<?v>";
char constantarr_0_682[8] = "nameless";
char constantarr_0_683[5] = "after";
char constantarr_0_684[34] = "fill-mut-list<opt<arr<arr<char>>>>";
char constantarr_0_685[16] = "fill-mut-arr<?t>";
char constantarr_0_686[24] = "fill-mut-arr<?t>.lambda0";
char constantarr_0_687[10] = "cell<bool>";
char constantarr_0_688[31] = "each<arr<char>, arr<arr<char>>>";
char constantarr_0_689[14] = "empty?<?k, ?v>";
char constantarr_0_690[23] = "subscript<void, ?k, ?v>";
char constantarr_0_691[27] = "call-with-ctx<?r, ?p0, ?p1>";
char constantarr_0_692[9] = "first<?v>";
char constantarr_0_693[8] = "tail<?v>";
char constantarr_0_694[5] = "named";
char constantarr_0_695[19] = "index-of<arr<char>>";
char constantarr_0_696[27] = "index-of<arr<char>>.lambda0";
char constantarr_0_697[20] = "has?<arr<arr<char>>>";
char constantarr_0_698[30] = "subscript<opt<arr<arr<char>>>>";
char constantarr_0_699[34] = "set-subscript<opt<arr<arr<char>>>>";
char constantarr_0_700[20] = "some<arr<arr<char>>>";
char constantarr_0_701[41] = "parse-cmd-line-args<test-options>.lambda0";
char constantarr_0_702[8] = "some<?t>";
char constantarr_0_703[39] = "subscript<?t, arr<opt<arr<arr<char>>>>>";
char constantarr_0_704[33] = "move-to-arr!<opt<arr<arr<char>>>>";
char constantarr_0_705[21] = "value<arr<arr<char>>>";
char constantarr_0_706[10] = "force<nat>";
char constantarr_0_707[9] = "parse-nat";
char constantarr_0_708[15] = "parse-nat-recur";
char constantarr_0_709[11] = "char-to-nat";
char constantarr_0_710[11] = "first<char>";
char constantarr_0_711[10] = "tail<char>";
char constantarr_0_712[12] = "test-options";
char constantarr_0_713[12] = "main.lambda0";
char constantarr_0_714[13] = "resolved<nat>";
char constantarr_0_715[10] = "print-help";
char constantarr_0_716[7] = "do-test";
char constantarr_0_717[11] = "parent-path";
char constantarr_0_718[16] = "r-index-of<char>";
char constantarr_0_719[15] = "find-rindex<?t>";
char constantarr_0_720[21] = "find-rindex-recur<?t>";
char constantarr_0_721[4] = "decr";
char constantarr_0_722[24] = "r-index-of<char>.lambda0";
char constantarr_0_723[23] = "current-executable-path";
char constantarr_0_724[9] = "read-link";
char constantarr_0_725[27] = "uninitialized-mut-arr<char>";
char constantarr_0_726[8] = "readlink";
char constantarr_0_727[8] = "to-c-str";
char constantarr_0_728[22] = "check-errno-if-neg-one";
char constantarr_0_729[17] = "check-posix-error";
char constantarr_0_730[5] = "errno";
char constantarr_0_731[20] = "cast-immutable<char>";
char constantarr_0_732[6] = "to-nat";
char constantarr_0_733[9] = "negative?";
char constantarr_0_734[6] = "<<int>";
char constantarr_0_735[10] = "child-path";
char constantarr_0_736[11] = "get-environ";
char constantarr_0_737[30] = "mut-dict<arr<char>, arr<char>>";
char constantarr_0_738[17] = "get-environ-recur";
char constantarr_0_739[11] = "null?<char>";
char constantarr_0_740[19] = "parse-environ-entry";
char constantarr_0_741[24] = "-><arr<char>, arr<char>>";
char constantarr_0_742[35] = "set-subscript<arr<char>, arr<char>>";
char constantarr_0_743[26] = "from<arr<char>, arr<char>>";
char constantarr_0_744[24] = "to<arr<char>, arr<char>>";
char constantarr_0_745[15] = "incr<ptr<char>>";
char constantarr_0_746[7] = "environ";
char constantarr_0_747[35] = "move-to-dict!<arr<char>, arr<char>>";
char constantarr_0_748[14] = "first-failures";
char constantarr_0_749[42] = "subscript<result<arr<char>, arr<failure>>>";
char constantarr_0_750[13] = "ok<arr<char>>";
char constantarr_0_751[16] = "value<arr<char>>";
char constantarr_0_752[14] = "run-crow-tests";
char constantarr_0_753[10] = "list-tests";
char constantarr_0_754[29] = "as<fun-act1<bool, arr<char>>>";
char constantarr_0_755[18] = "list-tests.lambda0";
char constantarr_0_756[20] = "each-child-recursive";
char constantarr_0_757[7] = "is-dir?";
char constantarr_0_758[8] = "get-stat";
char constantarr_0_759[10] = "empty-stat";
char constantarr_0_760[6] = "stat-t";
char constantarr_0_761[4] = "stat";
char constantarr_0_762[12] = "some<stat-t>";
char constantarr_0_763[6] = "enoent";
char constantarr_0_764[17] = "todo<opt<stat-t>>";
char constantarr_0_765[10] = "todo<bool>";
char constantarr_0_766[9] = "==<nat32>";
char constantarr_0_767[7] = "st-mode";
char constantarr_0_768[13] = "value<stat-t>";
char constantarr_0_769[6] = "s-ifmt";
char constantarr_0_770[7] = "s-ifdir";
char constantarr_0_771[15] = "each<arr<char>>";
char constantarr_0_772[19] = "subscript<void, ?t>";
char constantarr_0_773[8] = "read-dir";
char constantarr_0_774[7] = "opendir";
char constantarr_0_775[16] = "null?<ptr<nat8>>";
char constantarr_0_776[36] = "ptr-cast-from-extern<ptr<nat8>, dir>";
char constantarr_0_777[14] = "read-dir-recur";
char constantarr_0_778[6] = "dirent";
char constantarr_0_779[8] = "bytes256";
char constantarr_0_780[12] = "cell<dirent>";
char constantarr_0_781[9] = "readdir-r";
char constantarr_0_782[18] = "as-any-ptr<dirent>";
char constantarr_0_783[17] = "subscript<dirent>";
char constantarr_0_784[15] = "ref-eq?<dirent>";
char constantarr_0_785[13] = "ptr-eq?<nat8>";
char constantarr_0_786[15] = "get-dirent-name";
char constantarr_0_787[12] = "size-of<int>";
char constantarr_0_788[14] = "size-of<nat16>";
char constantarr_0_789[7] = "+<nat8>";
char constantarr_0_790[13] = "!=<arr<char>>";
char constantarr_0_791[15] = "sort<arr<char>>";
char constantarr_0_792[9] = "sort!<?t>";
char constantarr_0_793[14] = "partition!<?t>";
char constantarr_0_794[28] = "each-child-recursive.lambda0";
char constantarr_0_795[13] = "get-extension";
char constantarr_0_796[13] = "last-index-of";
char constantarr_0_797[10] = "last<char>";
char constantarr_0_798[11] = "rtail<char>";
char constantarr_0_799[9] = "base-name";
char constantarr_0_800[18] = "list-tests.lambda1";
char constantarr_0_801[42] = "flat-map-with-max-size<failure, arr<char>>";
char constantarr_0_802[14] = "mut-list<?out>";
char constantarr_0_803[10] = "size<?out>";
char constantarr_0_804[8] = "~=<?out>";
char constantarr_0_805[8] = "each<?t>";
char constantarr_0_806[9] = "first<?t>";
char constantarr_0_807[8] = "tail<?t>";
char constantarr_0_808[6] = "~=<?t>";
char constantarr_0_809[16] = "~=<?out>.lambda0";
char constantarr_0_810[25] = "subscript<arr<?out>, ?in>";
char constantarr_0_811[31] = "reduce-size-if-more-than!<?out>";
char constantarr_0_812[13] = "drop<opt<?t>>";
char constantarr_0_813[8] = "pop!<?t>";
char constantarr_0_814[50] = "flat-map-with-max-size<failure, arr<char>>.lambda0";
char constantarr_0_815[18] = "move-to-arr!<?out>";
char constantarr_0_816[20] = "run-single-crow-test";
char constantarr_0_817[35] = "first-some<arr<failure>, arr<char>>";
char constantarr_0_818[25] = "subscript<opt<?out>, ?in>";
char constantarr_0_819[12] = "print-tests?";
char constantarr_0_820[14] = "run-print-test";
char constantarr_0_821[21] = "spawn-and-wait-result";
char constantarr_0_822[26] = "fold<arr<char>, arr<char>>";
char constantarr_0_823[21] = "subscript<?a, ?a, ?b>";
char constantarr_0_824[29] = "spawn-and-wait-result.lambda0";
char constantarr_0_825[8] = "is-file?";
char constantarr_0_826[7] = "s-ifreg";
char constantarr_0_827[10] = "make-pipes";
char constantarr_0_828[5] = "pipes";
char constantarr_0_829[4] = "pipe";
char constantarr_0_830[26] = "posix-spawn-file-actions-t";
char constantarr_0_831[29] = "posix-spawn-file-actions-init";
char constantarr_0_832[33] = "posix-spawn-file-actions-addclose";
char constantarr_0_833[10] = "write-pipe";
char constantarr_0_834[32] = "posix-spawn-file-actions-adddup2";
char constantarr_0_835[9] = "read-pipe";
char constantarr_0_836[11] = "cell<int32>";
char constantarr_0_837[11] = "posix-spawn";
char constantarr_0_838[16] = "subscript<int32>";
char constantarr_0_839[5] = "close";
char constantarr_0_840[14] = "mut-list<char>";
char constantarr_0_841[12] = "keep-polling";
char constantarr_0_842[23] = "as<arr<by-val<pollfd>>>";
char constantarr_0_843[6] = "pollfd";
char constantarr_0_844[6] = "pollin";
char constantarr_0_845[21] = "ref-of-val-at<pollfd>";
char constantarr_0_846[16] = "size<by-val<?t>>";
char constantarr_0_847[14] = "ref-of-ptr<?t>";
char constantarr_0_848[14] = "ref-of-val<?t>";
char constantarr_0_849[21] = "subscript<by-val<?t>>";
char constantarr_0_850[13] = "+<by-val<?t>>";
char constantarr_0_851[16] = "data<by-val<?t>>";
char constantarr_0_852[4] = "poll";
char constantarr_0_853[14] = "handle-revents";
char constantarr_0_854[7] = "revents";
char constantarr_0_855[11] = "has-pollin?";
char constantarr_0_856[15] = "bits-intersect?";
char constantarr_0_857[9] = "==<int16>";
char constantarr_0_858[24] = "read-to-buffer-until-eof";
char constantarr_0_859[13] = "reserve<char>";
char constantarr_0_860[4] = "read";
char constantarr_0_861[27] = "unsafe-increase-size!<char>";
char constantarr_0_862[20] = "unsafe-set-size!<?t>";
char constantarr_0_863[2] = "fd";
char constantarr_0_864[12] = "has-pollhup?";
char constantarr_0_865[7] = "pollhup";
char constantarr_0_866[12] = "has-pollpri?";
char constantarr_0_867[7] = "pollpri";
char constantarr_0_868[12] = "has-pollout?";
char constantarr_0_869[7] = "pollout";
char constantarr_0_870[12] = "has-pollerr?";
char constantarr_0_871[7] = "pollerr";
char constantarr_0_872[13] = "has-pollnval?";
char constantarr_0_873[8] = "pollnval";
char constantarr_0_874[21] = "handle-revents-result";
char constantarr_0_875[4] = "any?";
char constantarr_0_876[11] = "had-pollin?";
char constantarr_0_877[8] = "hung-up?";
char constantarr_0_878[22] = "wait-and-get-exit-code";
char constantarr_0_879[7] = "waitpid";
char constantarr_0_880[11] = "w-if-exited";
char constantarr_0_881[10] = "w-term-sig";
char constantarr_0_882[13] = "w-exit-status";
char constantarr_0_883[15] = "bit-shift-right";
char constantarr_0_884[8] = "<<int32>";
char constantarr_0_885[11] = "todo<int32>";
char constantarr_0_886[22] = "unsafe-bit-shift-right";
char constantarr_0_887[13] = "w-if-signaled";
char constantarr_0_888[3] = "mod";
char constantarr_0_889[10] = "unsafe-mod";
char constantarr_0_890[3] = "abs";
char constantarr_0_891[6] = "?<int>";
char constantarr_0_892[3] = "neg";
char constantarr_0_893[12] = "w-if-stopped";
char constantarr_0_894[14] = "w-if-continued";
char constantarr_0_895[14] = "process-result";
char constantarr_0_896[18] = "move-to-arr!<char>";
char constantarr_0_897[12] = "convert-args";
char constantarr_0_898[12] = "~<ptr<char>>";
char constantarr_0_899[25] = "map<ptr<char>, arr<char>>";
char constantarr_0_900[33] = "map<ptr<char>, arr<char>>.lambda0";
char constantarr_0_901[20] = "convert-args.lambda0";
char constantarr_0_902[15] = "convert-environ";
char constantarr_0_903[19] = "mut-list<ptr<char>>";
char constantarr_0_904[26] = "each<arr<char>, arr<char>>";
char constantarr_0_905[13] = "~=<ptr<char>>";
char constantarr_0_906[23] = "convert-environ.lambda0";
char constantarr_0_907[23] = "move-to-arr!<ptr<char>>";
char constantarr_0_908[20] = "fail<process-result>";
char constantarr_0_909[9] = "exit-code";
char constantarr_0_910[16] = "as<arr<failure>>";
char constantarr_0_911[13] = "handle-output";
char constantarr_0_912[13] = "try-read-file";
char constantarr_0_913[4] = "open";
char constantarr_0_914[8] = "o-rdonly";
char constantarr_0_915[20] = "todo<opt<arr<char>>>";
char constantarr_0_916[5] = "lseek";
char constantarr_0_917[8] = "seek-end";
char constantarr_0_918[8] = "seek-set";
char constantarr_0_919[20] = "ptr-cast<nat8, char>";
char constantarr_0_920[10] = "write-file";
char constantarr_0_921[9] = "as<nat32>";
char constantarr_0_922[7] = "bits-or";
char constantarr_0_923[14] = "bit-shift-left";
char constantarr_0_924[8] = "<<nat32>";
char constantarr_0_925[15] = "unsafe-to-nat32";
char constantarr_0_926[21] = "unsafe-bit-shift-left";
char constantarr_0_927[7] = "o-creat";
char constantarr_0_928[8] = "o-wronly";
char constantarr_0_929[7] = "o-trunc";
char constantarr_0_930[7] = "max-int";
char constantarr_0_931[7] = "failure";
char constantarr_0_932[17] = "print-test-result";
char constantarr_0_933[13] = "remove-colors";
char constantarr_0_934[19] = "remove-colors-recur";
char constantarr_0_935[21] = "remove-colors-recur-2";
char constantarr_0_936[8] = "~=<char>";
char constantarr_0_937[17] = "overwrite-output?";
char constantarr_0_938[20] = "?<opt<arr<failure>>>";
char constantarr_0_939[12] = "should-stop?";
char constantarr_0_940[18] = "some<arr<failure>>";
char constantarr_0_941[8] = "failures";
char constantarr_0_942[28] = "run-single-crow-test.lambda0";
char constantarr_0_943[24] = "run-single-runnable-test";
char constantarr_0_944[17] = "?<arr<arr<char>>>";
char constantarr_0_945[10] = "~<failure>";
char constantarr_0_946[19] = "value<arr<failure>>";
char constantarr_0_947[22] = "run-crow-tests.lambda0";
char constantarr_0_948[13] = "has?<failure>";
char constantarr_0_949[17] = "err<arr<failure>>";
char constantarr_0_950[23] = "do-test.lambda0.lambda0";
char constantarr_0_951[15] = "do-test.lambda0";
char constantarr_0_952[4] = "lint";
char constantarr_0_953[19] = "list-lintable-files";
char constantarr_0_954[19] = "excluded-from-lint?";
char constantarr_0_955[20] = "contains?<arr<char>>";
char constantarr_0_956[18] = "exists?<arr<char>>";
char constantarr_0_957[16] = "ends-with?<char>";
char constantarr_0_958[27] = "excluded-from-lint?.lambda0";
char constantarr_0_959[27] = "list-lintable-files.lambda0";
char constantarr_0_960[25] = "ignore-extension-of-name?";
char constantarr_0_961[17] = "ignore-extension?";
char constantarr_0_962[18] = "ignored-extensions";
char constantarr_0_963[27] = "list-lintable-files.lambda1";
char constantarr_0_964[9] = "lint-file";
char constantarr_0_965[9] = "read-file";
char constantarr_0_966[26] = "each-with-index<arr<char>>";
char constantarr_0_967[25] = "each-with-index-recur<?t>";
char constantarr_0_968[24] = "subscript<void, ?t, nat>";
char constantarr_0_969[5] = "lines";
char constantarr_0_970[9] = "cell<nat>";
char constantarr_0_971[21] = "each-with-index<char>";
char constantarr_0_972[9] = "swap<nat>";
char constantarr_0_973[13] = "lines.lambda0";
char constantarr_0_974[22] = "contains-subseq?<char>";
char constantarr_0_975[9] = "has?<nat>";
char constantarr_0_976[19] = "index-of-subseq<?t>";
char constantarr_0_977[25] = "index-of-subseq-recur<?t>";
char constantarr_0_978[8] = "line-len";
char constantarr_0_979[6] = "n-tabs";
char constantarr_0_980[8] = "tab-size";
char constantarr_0_981[15] = "max-line-length";
char constantarr_0_982[17] = "lint-file.lambda0";
char constantarr_0_983[12] = "lint.lambda0";
char constantarr_0_984[15] = "do-test.lambda1";
char constantarr_0_985[14] = "print-failures";
char constantarr_0_986[13] = "print-failure";
char constantarr_0_987[10] = "print-bold";
char constantarr_0_988[4] = "path";
char constantarr_0_989[11] = "print-reset";
char constantarr_0_990[22] = "print-failures.lambda0";
char constantarr_0_991[19] = "value<test-options>";
struct arr_0 constantarr_1_0[3] = {{11, constantarr_0_10}, {16, constantarr_0_11}, {12, constantarr_0_12}};
struct arr_0 constantarr_1_1[4] = {{3, constantarr_0_29}, {5, constantarr_0_30}, {14, constantarr_0_31}, {9, constantarr_0_32}};
struct arr_0 constantarr_1_2[6] = {{4, constantarr_0_72}, {4, constantarr_0_60}, {4, constantarr_0_73}, {5, constantarr_0_52}, {4, constantarr_0_74}, {5, constantarr_0_75}};
struct arr_0 constantarr_1_3[4] = {{7, constantarr_0_76}, {7, constantarr_0_77}, {12, constantarr_0_78}, {17, constantarr_0_79}};
struct arr_0 constantarr_1_4[6] = {{1, constantarr_0_80}, {4, constantarr_0_81}, {1, constantarr_0_82}, {3, constantarr_0_83}, {4, constantarr_0_84}, {10, constantarr_0_85}};
uint8_t mark(struct mark_ctx* ctx, uint8_t* ptr_any, uint64_t size_bytes);
uint64_t words_of_bytes(uint64_t size_bytes);
uint64_t round_up_to_multiple_of_8(uint64_t n);
struct void_ hard_assert(uint8_t condition);
uint8_t not(uint8_t a);
extern void abort(void);
uint8_t _equal_0(uint64_t a, uint64_t b);
struct comparison compare_7(uint64_t a, uint64_t b);
uint64_t _minus_0(uint64_t* a, uint64_t* b);
uint8_t _less_0(uint64_t a, uint64_t b);
uint8_t _lessOrEqual(uint64_t a, uint64_t b);
uint8_t mark_range_recur(uint8_t marked_anything__q, uint8_t* cur, uint8_t* end);
uint8_t* incr_0(uint8_t* p);
uint8_t _greater(uint64_t a, uint64_t b);
int32_t rt_main(int32_t argc, char** argv, fun_ptr2 main_ptr);
extern uint64_t get_nprocs(void);
struct lock lock_by_val(void);
struct _atomic_bool _atomic_bool(void);
struct condition condition(void);
struct island island(struct global_ctx* gctx, uint64_t id, uint64_t max_threads);
struct task_queue task_queue(uint64_t max_threads);
struct mut_list_0 mut_list_by_val_with_capacity_from_unmanaged_memory(uint64_t capacity);
struct mut_arr_0 mut_arr_0(uint64_t size, uint64_t* data);
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
struct arr_0 join(struct ctx* ctx, struct arr_1 a, struct arr_0 joiner);
uint8_t empty__q_1(struct arr_1 a);
struct arr_0 subscript_0(struct ctx* ctx, struct arr_1 a, uint64_t index);
struct void_ assert_0(struct ctx* ctx, uint8_t condition);
struct void_ fail_0(struct ctx* ctx, struct arr_0 reason);
struct void_ throw_0(struct ctx* ctx, struct exception e);
struct exception_ctx* get_exception_ctx(struct ctx* ctx);
uint8_t null__q_1(struct jmp_buf_tag* a);
extern void longjmp(struct jmp_buf_tag* env, int32_t val);
int32_t number_to_throw(struct ctx* ctx);
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
struct comparison compare_66(int32_t a, int32_t b);
uint64_t noctx_incr(uint64_t n);
struct opt_5 try_gc_alloc_recur(struct gc* gc, uint64_t size_bytes);
struct void_ validate_gc(struct gc* gc);
uint8_t ptr_less_eq__q_0(uint8_t* a, uint8_t* b);
uint8_t ptr_less_eq__q_1(uint64_t* a, uint64_t* b);
uint64_t _minus_1(uint8_t* a, uint8_t* b);
uint8_t range_free__q(uint8_t* mark, uint8_t* end);
uint64_t* incr_1(uint64_t* p);
struct void_ release__e(struct lock* a);
struct void_ must_unset__e(struct _atomic_bool* a);
uint8_t try_unset__e(struct _atomic_bool* a);
struct gc* get_gc(struct ctx* ctx);
struct gc_ctx* get_gc_ctx_0(struct ctx* ctx);
struct opt_6 try_alloc_uninitialized_1(struct ctx* ctx, uint64_t size);
uint64_t funs_count_81(void);
extern int32_t backtrace(uint8_t** array, int32_t size);
uint64_t code_ptrs_size(struct ctx* ctx);
struct void_ fill_fun_ptrs_names_recur(struct ctx* ctx, uint64_t i, uint8_t** fun_ptrs, struct arr_0* fun_names);
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
struct arr_0 get_fun_name(struct ctx* ctx, uint8_t* code_ptr, uint8_t** fun_ptrs, struct arr_0* fun_names, uint64_t size);
uint8_t** incr_2(uint8_t** p);
struct arr_0* incr_3(struct arr_0* p);
struct arr_0 noctx_at_0(struct arr_1 a, uint64_t index);
struct arr_0 _concat_0(struct ctx* ctx, struct arr_0 a, struct arr_0 b);
uint64_t _plus(struct ctx* ctx, uint64_t a, uint64_t b);
uint8_t _greaterOrEqual(uint64_t a, uint64_t b);
char* alloc_uninitialized_0(struct ctx* ctx, uint64_t size);
uint8_t* alloc(struct ctx* ctx, uint64_t size_bytes);
uint8_t* gc_alloc(struct ctx* ctx, struct gc* gc, uint64_t size);
uint8_t* todo_1(void);
struct void_ copy_data_from_0(struct ctx* ctx, char* to, char* from, uint64_t len);
extern void memcpy(uint8_t* dest, uint8_t* src, uint64_t size);
struct arr_1 tail_0(struct ctx* ctx, struct arr_1 a);
struct void_ forbid_0(struct ctx* ctx, uint8_t condition);
struct void_ forbid_1(struct ctx* ctx, uint8_t condition, struct arr_0 message);
struct arr_1 subscript_3(struct ctx* ctx, struct arr_1 a, struct arrow_0 range);
uint64_t _minus_2(struct ctx* ctx, uint64_t a, uint64_t b);
struct arrow_0 _arrow_0(struct ctx* ctx, uint64_t from, uint64_t to);
struct global_ctx* get_global_ctx(struct ctx* ctx);
struct void_ island__lambda0(struct ctx* ctx, struct void_ _closure, struct exception it);
struct void_ default_log_handler(struct ctx* ctx, struct logged* a);
struct void_ print(struct arr_0 a);
struct void_ print_no_newline(struct arr_0 a);
int32_t stdout(void);
struct arr_0 to_str_0(struct ctx* ctx, struct log_level a);
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
struct fut_0* then2(struct ctx* ctx, struct fut_1* f, struct fun_ref0 cb);
struct fut_0* then(struct ctx* ctx, struct fut_1* f, struct fun_ref1 cb);
struct fut_0* unresolved(struct ctx* ctx);
struct void_ callback__e_0(struct ctx* ctx, struct fut_1* f, struct fun_act1_1 cb);
struct void_ with_lock_0(struct ctx* ctx, struct lock* a, struct fun_act0_0 f);
struct void_ subscript_4(struct ctx* ctx, struct fun_act0_0 a);
struct void_ call_w_ctx_140(struct fun_act0_0 a, struct ctx* ctx);
struct void_ subscript_5(struct ctx* ctx, struct fun_act1_1 a, struct result_1 p0);
struct void_ call_w_ctx_142(struct fun_act1_1 a, struct ctx* ctx, struct result_1 p0);
struct void_ callback__e_0__lambda0(struct ctx* ctx, struct callback__e_0__lambda0* _closure);
struct void_ forward_to__e(struct ctx* ctx, struct fut_0* from, struct fut_0* to);
struct void_ callback__e_1(struct ctx* ctx, struct fut_0* f, struct fun_act1_0 cb);
struct void_ subscript_6(struct ctx* ctx, struct fun_act1_0 a, struct result_0 p0);
struct void_ call_w_ctx_147(struct fun_act1_0 a, struct ctx* ctx, struct result_0 p0);
struct void_ callback__e_1__lambda0(struct ctx* ctx, struct callback__e_1__lambda0* _closure);
struct void_ resolve_or_reject__e(struct ctx* ctx, struct fut_0* f, struct result_0 result);
struct fut_state_callbacks_0 with_lock_1(struct ctx* ctx, struct lock* a, struct fun_act0_2 f);
struct fut_state_callbacks_0 subscript_7(struct ctx* ctx, struct fun_act0_2 a);
struct fut_state_callbacks_0 call_w_ctx_152(struct fun_act0_2 a, struct ctx* ctx);
struct fut_state_callbacks_0 todo_2(void);
struct fut_state_callbacks_0 resolve_or_reject__e__lambda0(struct ctx* ctx, struct resolve_or_reject__e__lambda0* _closure);
struct void_ call_callbacks__e(struct ctx* ctx, struct opt_0 node, struct result_0 value);
struct void_ drop_0(struct void_ _p0);
struct void_ forward_to__e__lambda0(struct ctx* ctx, struct forward_to__e__lambda0* _closure, struct result_0 it);
struct fut_0* subscript_8(struct ctx* ctx, struct fun_ref1 f, struct void_ p0);
struct island* get_island(struct ctx* ctx, uint64_t island_id);
struct island* subscript_9(struct ctx* ctx, struct arr_3 a, uint64_t index);
struct island* noctx_at_1(struct arr_3 a, uint64_t index);
struct island* subscript_10(struct island** a, uint64_t n);
struct void_ add_task_0(struct ctx* ctx, struct island* a, uint64_t exclusion, struct fun_act0_0 action);
struct void_ add_task_1(struct ctx* ctx, struct island* a, uint64_t timestamp, uint64_t exclusion, struct fun_act0_0 action);
struct task_queue_node* task_queue_node(struct ctx* ctx, struct task task);
struct void_ insert_task__e(struct task_queue* a, struct task_queue_node* inserted);
uint64_t size_0(struct task_queue* a);
uint64_t size_recur(struct opt_2 node, uint64_t acc);
struct void_ insert_recur(struct task_queue_node* prev, struct task_queue_node* inserted);
struct task_queue* tasks(struct island* a);
struct void_ broadcast__e(struct condition* c);
uint64_t no_timestamp(void);
struct void_ catch(struct ctx* ctx, struct fun_act0_0 try, struct fun_act1_3 catcher);
struct void_ catch_with_exception_ctx(struct ctx* ctx, struct exception_ctx* ec, struct fun_act0_0 try, struct fun_act1_3 catcher);
struct bytes64 zero_0(void);
struct bytes32 zero_1(void);
struct bytes16 zero_2(void);
struct bytes128 zero_3(void);
extern int32_t setjmp(struct jmp_buf_tag* env);
struct void_ subscript_11(struct ctx* ctx, struct fun_act1_3 a, struct exception p0);
struct void_ call_w_ctx_181(struct fun_act1_3 a, struct ctx* ctx, struct exception p0);
struct fut_0* subscript_12(struct ctx* ctx, struct fun_act1_2 a, struct void_ p0);
struct fut_0* call_w_ctx_183(struct fun_act1_2 a, struct ctx* ctx, struct void_ p0);
struct void_ subscript_8__lambda0__lambda0(struct ctx* ctx, struct subscript_8__lambda0__lambda0* _closure);
struct void_ reject__e(struct ctx* ctx, struct fut_0* f, struct exception e);
struct void_ subscript_8__lambda0__lambda1(struct ctx* ctx, struct subscript_8__lambda0__lambda1* _closure, struct exception it);
struct void_ subscript_8__lambda0(struct ctx* ctx, struct subscript_8__lambda0* _closure);
struct void_ then__lambda0(struct ctx* ctx, struct then__lambda0* _closure, struct result_1 result);
struct fut_0* subscript_13(struct ctx* ctx, struct fun_ref0 f);
struct fut_0* subscript_14(struct ctx* ctx, struct fun_act0_1 a);
struct fut_0* call_w_ctx_191(struct fun_act0_1 a, struct ctx* ctx);
struct void_ subscript_13__lambda0__lambda0(struct ctx* ctx, struct subscript_13__lambda0__lambda0* _closure);
struct void_ subscript_13__lambda0__lambda1(struct ctx* ctx, struct subscript_13__lambda0__lambda1* _closure, struct exception it);
struct void_ subscript_13__lambda0(struct ctx* ctx, struct subscript_13__lambda0* _closure);
struct fut_0* then2__lambda0(struct ctx* ctx, struct then2__lambda0* _closure, struct void_ ignore);
struct island_and_exclusion cur_island_and_exclusion(struct ctx* ctx);
struct fut_1* delay(struct ctx* ctx);
struct fut_1* resolved_0(struct ctx* ctx, struct void_ value);
struct arr_4 tail_1(struct ctx* ctx, struct arr_4 a);
uint8_t empty__q_2(struct arr_4 a);
struct arr_4 subscript_15(struct ctx* ctx, struct arr_4 a, struct arrow_0 range);
struct arr_1 map_0(struct ctx* ctx, struct arr_4 a, struct fun_act1_4 mapper);
struct arr_1 make_arr_0(struct ctx* ctx, uint64_t size, struct fun_act1_5 f);
struct arr_0* alloc_uninitialized_1(struct ctx* ctx, uint64_t size);
struct void_ fill_ptr_range_0(struct ctx* ctx, struct arr_0* begin, uint64_t size, struct fun_act1_5 f);
struct void_ fill_ptr_range_recur_0(struct ctx* ctx, struct arr_0* begin, uint64_t i, uint64_t size, struct fun_act1_5 f);
struct arr_0 subscript_16(struct ctx* ctx, struct fun_act1_5 a, uint64_t p0);
struct arr_0 call_w_ctx_208(struct fun_act1_5 a, struct ctx* ctx, uint64_t p0);
struct arr_0 subscript_17(struct ctx* ctx, struct fun_act1_4 a, char* p0);
struct arr_0 call_w_ctx_210(struct fun_act1_4 a, struct ctx* ctx, char* p0);
char* subscript_18(struct ctx* ctx, struct arr_4 a, uint64_t index);
char* noctx_at_2(struct arr_4 a, uint64_t index);
char* subscript_19(char** a, uint64_t n);
struct arr_0 map_0__lambda0(struct ctx* ctx, struct map_0__lambda0* _closure, uint64_t i);
struct arr_0 to_str_1(char* a);
struct arr_0 arr_from_begin_end(char* begin, char* end);
uint64_t _minus_3(char* a, char* b);
char* find_cstr_end(char* a);
char* find_char_in_cstr(char* a, char c);
uint8_t _equal_3(char a, char b);
struct comparison compare_221(char a, char b);
char* todo_3(void);
char* incr_4(char* p);
struct arr_0 add_first_task__lambda0__lambda0(struct ctx* ctx, struct void_ _closure, char* it);
struct fut_0* add_first_task__lambda0(struct ctx* ctx, struct add_first_task__lambda0* _closure);
struct void_ handle_exceptions(struct ctx* ctx, struct fut_0* a);
struct void_ subscript_20(struct ctx* ctx, struct fun1_0 a, struct exception p0);
struct void_ call_w_ctx_228(struct fun1_0 a, struct ctx* ctx, struct exception p0);
struct fun1_0 exception_handler(struct ctx* ctx, struct island* a);
struct island* get_cur_island(struct ctx* ctx);
struct void_ handle_exceptions__lambda0(struct ctx* ctx, struct void_ _closure, struct result_0 result);
struct fut_0* do_main__lambda0(struct ctx* ctx, struct void_ _closure, struct arr_4 all_args, fun_ptr2 main_ptr);
struct fut_0* call_w_ctx_233(struct fun_act2_0 a, struct ctx* ctx, struct arr_4 p0, fun_ptr2 p1);
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
uint8_t has__q_0(struct opt_2 a);
uint8_t empty__q_4(struct opt_2 a);
uint64_t get_last_checked(struct condition* a);
struct choose_task_result choose_task(struct global_ctx* gctx);
uint64_t get_monotime_nsec(void);
extern int32_t clock_gettime(int32_t clock_id, struct cell_1* timespec);
int32_t clock_monotonic(void);
uint64_t todo_4(void);
struct choose_task_result choose_task_recur(struct arr_3 islands, uint64_t i, uint64_t cur_time, uint8_t any_tasks__q, struct opt_8 first_task_time);
struct choose_task_in_island_result choose_task_in_island(struct island* island, uint64_t cur_time);
struct pop_task_result pop_task__e(struct task_queue* a, uint64_t cur_time);
uint8_t contains__q_0(struct mut_list_0* a, uint64_t value);
uint8_t contains__q_1(struct arr_2 a, uint64_t value);
uint8_t contains_recur__q_0(struct arr_2 a, uint64_t value, uint64_t i);
uint64_t noctx_at_3(struct arr_2 a, uint64_t index);
uint64_t subscript_21(uint64_t* a, uint64_t n);
struct arr_2 temp_as_arr_0(struct mut_list_0* a);
struct arr_2 temp_as_arr_1(struct mut_arr_0 a);
struct mut_arr_0 temp_as_mut_arr(struct mut_list_0* a);
uint64_t* data_0(struct mut_list_0* a);
uint64_t* data_1(struct mut_arr_0 a);
struct pop_task_result pop_recur__e(struct task_queue_node* prev, struct mut_list_0* exclusions, uint64_t cur_time, struct opt_8 first_task_time);
struct opt_8 to_opt_time(uint64_t a);
struct void_ push_capacity_must_be_sufficient__e(struct mut_list_0* a, uint64_t value);
uint64_t capacity_0(struct mut_list_0* a);
uint64_t size_1(struct mut_arr_0 a);
struct void_ noctx_set_at__e_0(struct mut_list_0* a, uint64_t index, uint64_t value);
struct void_ set_subscript_2(uint64_t* a, uint64_t n, uint64_t value);
uint8_t is_no_task__q(struct choose_task_in_island_result a);
struct opt_8 min_time(struct opt_8 a, struct opt_8 b);
uint64_t min(uint64_t a, uint64_t b);
struct void_ do_task(struct global_ctx* gctx, struct thread_local_stuff* tls, struct chosen_task chosen_task);
struct void_ return_task__e(struct task_queue* a, struct task task);
struct void_ noctx_must_remove_unordered__e(struct mut_list_0* a, uint64_t value);
struct void_ noctx_must_remove_unordered_recur__e(struct mut_list_0* a, uint64_t index, uint64_t value);
uint64_t noctx_at_4(struct mut_list_0* a, uint64_t index);
struct void_ drop_1(uint64_t _p0);
uint64_t noctx_remove_unordered_at__e(struct mut_list_0* a, uint64_t index);
uint64_t noctx_last(struct mut_list_0* a);
uint8_t empty__q_5(struct mut_list_0* a);
struct void_ return_ctx(struct ctx* c);
struct void_ return_gc_ctx(struct gc_ctx* gc_ctx);
struct void_ run_garbage_collection(struct gc* gc, struct island_gc_root gc_root);
struct void_ mark_visit_290(struct mark_ctx* mark_ctx, struct island_gc_root value);
struct void_ mark_visit_291(struct mark_ctx* mark_ctx, struct task_queue value);
struct void_ mark_visit_292(struct mark_ctx* mark_ctx, struct opt_2 value);
struct void_ mark_visit_293(struct mark_ctx* mark_ctx, struct some_2 value);
struct void_ mark_visit_294(struct mark_ctx* mark_ctx, struct task_queue_node value);
struct void_ mark_visit_295(struct mark_ctx* mark_ctx, struct task value);
struct void_ mark_visit_296(struct mark_ctx* mark_ctx, struct fun_act0_0 value);
struct void_ mark_visit_297(struct mark_ctx* mark_ctx, struct callback__e_0__lambda0 value);
struct void_ mark_visit_298(struct mark_ctx* mark_ctx, struct fut_1 value);
struct void_ mark_visit_299(struct mark_ctx* mark_ctx, struct fut_state_1 value);
struct void_ mark_visit_300(struct mark_ctx* mark_ctx, struct fut_state_callbacks_1 value);
struct void_ mark_visit_301(struct mark_ctx* mark_ctx, struct opt_7 value);
struct void_ mark_visit_302(struct mark_ctx* mark_ctx, struct some_7 value);
struct void_ mark_visit_303(struct mark_ctx* mark_ctx, struct fut_callback_node_1 value);
struct void_ mark_visit_304(struct mark_ctx* mark_ctx, struct fun_act1_1 value);
struct void_ mark_visit_305(struct mark_ctx* mark_ctx, struct then__lambda0 value);
struct void_ mark_visit_306(struct mark_ctx* mark_ctx, struct fun_ref1 value);
struct void_ mark_visit_307(struct mark_ctx* mark_ctx, struct fun_act1_2 value);
struct void_ mark_visit_308(struct mark_ctx* mark_ctx, struct then2__lambda0 value);
struct void_ mark_visit_309(struct mark_ctx* mark_ctx, struct fun_ref0 value);
struct void_ mark_visit_310(struct mark_ctx* mark_ctx, struct fun_act0_1 value);
struct void_ mark_visit_311(struct mark_ctx* mark_ctx, struct add_first_task__lambda0 value);
struct void_ mark_arr_312(struct mark_ctx* mark_ctx, struct arr_4 a);
struct void_ mark_visit_313(struct mark_ctx* mark_ctx, struct add_first_task__lambda0* value);
struct void_ mark_visit_314(struct mark_ctx* mark_ctx, struct then2__lambda0* value);
struct void_ mark_visit_315(struct mark_ctx* mark_ctx, struct fut_0 value);
struct void_ mark_visit_316(struct mark_ctx* mark_ctx, struct fut_state_0 value);
struct void_ mark_visit_317(struct mark_ctx* mark_ctx, struct fut_state_callbacks_0 value);
struct void_ mark_visit_318(struct mark_ctx* mark_ctx, struct opt_0 value);
struct void_ mark_visit_319(struct mark_ctx* mark_ctx, struct some_0 value);
struct void_ mark_visit_320(struct mark_ctx* mark_ctx, struct fut_callback_node_0 value);
struct void_ mark_visit_321(struct mark_ctx* mark_ctx, struct fun_act1_0 value);
struct void_ mark_visit_322(struct mark_ctx* mark_ctx, struct forward_to__e__lambda0 value);
struct void_ mark_visit_323(struct mark_ctx* mark_ctx, struct fut_0* value);
struct void_ mark_visit_324(struct mark_ctx* mark_ctx, struct forward_to__e__lambda0* value);
struct void_ mark_visit_325(struct mark_ctx* mark_ctx, struct fut_callback_node_0* value);
struct void_ mark_visit_326(struct mark_ctx* mark_ctx, struct exception value);
struct void_ mark_arr_327(struct mark_ctx* mark_ctx, struct arr_0 a);
struct void_ mark_visit_328(struct mark_ctx* mark_ctx, struct backtrace value);
struct void_ mark_elems_329(struct mark_ctx* mark_ctx, struct arr_0* cur, struct arr_0* end);
struct void_ mark_arr_330(struct mark_ctx* mark_ctx, struct arr_1 a);
struct void_ mark_visit_331(struct mark_ctx* mark_ctx, struct then__lambda0* value);
struct void_ mark_visit_332(struct mark_ctx* mark_ctx, struct fut_callback_node_1* value);
struct void_ mark_visit_333(struct mark_ctx* mark_ctx, struct fut_1* value);
struct void_ mark_visit_334(struct mark_ctx* mark_ctx, struct callback__e_0__lambda0* value);
struct void_ mark_visit_335(struct mark_ctx* mark_ctx, struct callback__e_1__lambda0 value);
struct void_ mark_visit_336(struct mark_ctx* mark_ctx, struct callback__e_1__lambda0* value);
struct void_ mark_visit_337(struct mark_ctx* mark_ctx, struct subscript_8__lambda0__lambda0 value);
struct void_ mark_visit_338(struct mark_ctx* mark_ctx, struct subscript_8__lambda0__lambda0* value);
struct void_ mark_visit_339(struct mark_ctx* mark_ctx, struct subscript_8__lambda0 value);
struct void_ mark_visit_340(struct mark_ctx* mark_ctx, struct subscript_8__lambda0* value);
struct void_ mark_visit_341(struct mark_ctx* mark_ctx, struct subscript_13__lambda0__lambda0 value);
struct void_ mark_visit_342(struct mark_ctx* mark_ctx, struct subscript_13__lambda0__lambda0* value);
struct void_ mark_visit_343(struct mark_ctx* mark_ctx, struct subscript_13__lambda0 value);
struct void_ mark_visit_344(struct mark_ctx* mark_ctx, struct subscript_13__lambda0* value);
struct void_ mark_visit_345(struct mark_ctx* mark_ctx, struct task_queue_node* value);
struct void_ mark_visit_346(struct mark_ctx* mark_ctx, struct mut_list_0 value);
struct void_ mark_visit_347(struct mark_ctx* mark_ctx, struct mut_arr_0 value);
struct void_ mark_arr_348(struct mark_ctx* mark_ctx, struct arr_2 a);
struct void_ clear_free_mem(uint8_t* mark_ptr, uint8_t* mark_end, uint64_t* data_ptr);
struct void_ wait_on(struct condition* cond, struct opt_8 until_time, uint64_t last_checked);
uint8_t before_time__q(struct opt_8 until_time);
struct void_ join_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads);
struct void_ join_one_thread(uint64_t tid);
extern int32_t pthread_join(uint64_t thread, struct cell_2* thread_return);
int32_t einval(void);
int32_t esrch(void);
struct void_ unmanaged_free_0(uint64_t* p);
extern void free(uint8_t* p);
struct void_ unmanaged_free_1(struct thread_args* p);
struct fut_0* main_0(struct ctx* ctx, struct arr_1 args);
struct opt_9 parse_cmd_line_args(struct ctx* ctx, struct arr_1 args, struct arr_1 t_names, struct fun1_2 make_t);
struct parsed_cmd_line_args* parse_cmd_line_args_dynamic(struct ctx* ctx, struct arr_1 args);
struct opt_8 find_index(struct ctx* ctx, struct arr_1 a, struct fun_act1_6 pred);
struct opt_8 find_index_recur(struct ctx* ctx, struct arr_1 a, uint64_t index, struct fun_act1_6 pred);
uint8_t subscript_22(struct ctx* ctx, struct fun_act1_6 a, struct arr_0 p0);
uint8_t call_w_ctx_366(struct fun_act1_6 a, struct ctx* ctx, struct arr_0 p0);
uint64_t incr_5(struct ctx* ctx, uint64_t n);
uint64_t max_nat(void);
uint8_t starts_with__q(struct ctx* ctx, struct arr_0 a, struct arr_0 start);
uint8_t arr_eq__q(struct ctx* ctx, struct arr_0 a, struct arr_0 b);
uint8_t _notEqual_3(char a, char b);
char subscript_23(struct ctx* ctx, struct arr_0 a, uint64_t index);
char noctx_at_5(struct arr_0 a, uint64_t index);
char subscript_24(char* a, uint64_t n);
struct arr_0 subscript_25(struct ctx* ctx, struct arr_0 a, struct arrow_0 range);
uint8_t parse_cmd_line_args_dynamic__lambda0(struct ctx* ctx, struct void_ _closure, struct arr_0 it);
struct dict_0* dict_0(struct ctx* ctx, struct arr_7 pairs);
struct arr_1 map_1(struct ctx* ctx, struct arr_7 a, struct fun_act1_7 mapper);
struct arr_0 subscript_26(struct ctx* ctx, struct fun_act1_7 a, struct arrow_1* p0);
struct arr_0 call_w_ctx_380(struct fun_act1_7 a, struct ctx* ctx, struct arrow_1* p0);
struct arrow_1* subscript_27(struct ctx* ctx, struct arr_7 a, uint64_t index);
struct arrow_1* noctx_at_6(struct arr_7 a, uint64_t index);
struct arrow_1* subscript_28(struct arrow_1** a, uint64_t n);
struct arr_0 map_1__lambda0(struct ctx* ctx, struct map_1__lambda0* _closure, uint64_t i);
struct arr_0 dict_0__lambda0(struct ctx* ctx, struct void_ _closure, struct arrow_1* it);
struct arr_6 map_2(struct ctx* ctx, struct arr_7 a, struct fun_act1_8 mapper);
struct arr_6 make_arr_1(struct ctx* ctx, uint64_t size, struct fun_act1_9 f);
struct arr_1* alloc_uninitialized_2(struct ctx* ctx, uint64_t size);
struct void_ fill_ptr_range_1(struct ctx* ctx, struct arr_1* begin, uint64_t size, struct fun_act1_9 f);
struct void_ fill_ptr_range_recur_1(struct ctx* ctx, struct arr_1* begin, uint64_t i, uint64_t size, struct fun_act1_9 f);
struct void_ set_subscript_3(struct arr_1* a, uint64_t n, struct arr_1 value);
struct arr_1 subscript_29(struct ctx* ctx, struct fun_act1_9 a, uint64_t p0);
struct arr_1 call_w_ctx_393(struct fun_act1_9 a, struct ctx* ctx, uint64_t p0);
struct arr_1 subscript_30(struct ctx* ctx, struct fun_act1_8 a, struct arrow_1* p0);
struct arr_1 call_w_ctx_395(struct fun_act1_8 a, struct ctx* ctx, struct arrow_1* p0);
struct arr_1 map_2__lambda0(struct ctx* ctx, struct map_2__lambda0* _closure, uint64_t i);
struct arr_1 dict_0__lambda1(struct ctx* ctx, struct void_ _closure, struct arrow_1* it);
struct dict_0* dict_1(struct ctx* ctx, struct arr_1 keys, struct arr_6 values);
struct sorted_by_first_0* sort_by_first_0(struct ctx* ctx, struct arr_1 a, struct arr_6 b);
struct mut_arr_1 mut_arr_1(struct ctx* ctx, struct arr_1 a);
struct mut_arr_1 make_mut_arr_0(struct ctx* ctx, uint64_t size, struct fun_act1_5 f);
struct mut_arr_1 uninitialized_mut_arr_0(struct ctx* ctx, uint64_t size);
struct mut_arr_1 mut_arr_2(uint64_t size, struct arr_0* data);
struct arr_0* data_2(struct mut_arr_1 a);
struct arr_0 mut_arr_1__lambda0(struct ctx* ctx, struct mut_arr_1__lambda0* _closure, uint64_t it);
struct mut_arr_2 mut_arr_3(struct ctx* ctx, struct arr_6 a);
struct mut_arr_2 make_mut_arr_1(struct ctx* ctx, uint64_t size, struct fun_act1_9 f);
struct mut_arr_2 uninitialized_mut_arr_1(struct ctx* ctx, uint64_t size);
struct mut_arr_2 mut_arr_4(uint64_t size, struct arr_1* data);
struct arr_1* data_3(struct mut_arr_2 a);
struct arr_1 subscript_31(struct ctx* ctx, struct arr_6 a, uint64_t index);
struct arr_1 noctx_at_7(struct arr_6 a, uint64_t index);
struct arr_1 subscript_32(struct arr_1* a, uint64_t n);
struct arr_1 mut_arr_3__lambda0(struct ctx* ctx, struct mut_arr_3__lambda0* _closure, uint64_t it);
struct void_ sort_by_first__e_0(struct ctx* ctx, struct mut_arr_1 a, struct mut_arr_2 b);
uint64_t size_2(struct mut_arr_1 a);
uint64_t size_3(struct mut_arr_2 a);
struct void_ swap_2(struct ctx* ctx, struct mut_arr_1 a, uint64_t x, uint64_t y);
struct arr_0 subscript_33(struct ctx* ctx, struct mut_arr_1 a, uint64_t index);
struct void_ set_subscript_4(struct ctx* ctx, struct mut_arr_1 a, uint64_t index, struct arr_0 value);
struct void_ noctx_set_at_0(struct mut_arr_1 a, uint64_t index, struct arr_0 value);
uint64_t _divide(struct ctx* ctx, uint64_t a, uint64_t b);
uint64_t partition_by_first__e_0(struct ctx* ctx, struct mut_arr_1 a, struct mut_arr_2 b, struct arr_0 pivot, uint64_t l, uint64_t r);
uint8_t _less_1(struct arr_0 a, struct arr_0 b);
struct comparison compare_425(struct arr_0 a, struct arr_0 b);
struct void_ swap_3(struct ctx* ctx, struct mut_arr_2 a, uint64_t x, uint64_t y);
struct arr_1 subscript_34(struct ctx* ctx, struct mut_arr_2 a, uint64_t index);
struct void_ set_subscript_5(struct ctx* ctx, struct mut_arr_2 a, uint64_t index, struct arr_1 value);
struct void_ noctx_set_at_1(struct mut_arr_2 a, uint64_t index, struct arr_1 value);
struct mut_arr_1 subscript_35(struct ctx* ctx, struct mut_arr_1 a, struct arrow_0 range);
struct mut_arr_2 subscript_36(struct ctx* ctx, struct mut_arr_2 a, struct arrow_0 range);
struct arr_6 subscript_37(struct ctx* ctx, struct arr_6 a, struct arrow_0 range);
struct arr_1 cast_immutable_0(struct mut_arr_1 a);
struct arr_6 cast_immutable_1(struct mut_arr_2 a);
uint8_t _equal_4(struct arr_0 a, struct arr_0 b);
uint8_t parse_cmd_line_args_dynamic__lambda1(struct ctx* ctx, struct void_ _closure, struct arr_0 it);
struct dict_0* parse_named_args(struct ctx* ctx, struct arr_1 args);
struct mut_dict_0* mut_dict_0(struct ctx* ctx);
struct mut_list_1* mut_list_0(struct ctx* ctx);
struct mut_arr_1 mut_arr_5(void);
struct mut_list_2* mut_list_1(struct ctx* ctx);
struct mut_arr_2 mut_arr_6(void);
struct void_ parse_named_args_recur(struct ctx* ctx, struct arr_1 args, struct mut_dict_0* builder);
struct arr_0 remove_start(struct ctx* ctx, struct arr_0 a, struct arr_0 start);
struct arr_0 force_0(struct ctx* ctx, struct opt_11 a);
struct arr_0 fail_1(struct ctx* ctx, struct arr_0 reason);
struct arr_0 throw_1(struct ctx* ctx, struct exception e);
struct arr_0 todo_5(void);
struct opt_11 try_remove_start(struct ctx* ctx, struct arr_0 a, struct arr_0 start);
struct arr_0 first_0(struct ctx* ctx, struct arr_1 a);
uint8_t parse_named_args_recur__lambda0(struct ctx* ctx, struct void_ _closure, struct arr_0 it);
struct void_ set_subscript_6(struct ctx* ctx, struct mut_dict_0* a, struct arr_0 key, struct arr_1 value);
struct void_ set_subscript_recur_0(struct ctx* ctx, struct mut_dict_0* a, uint64_t idx, struct arr_0 key, struct arr_1 value);
struct void_ _concatEquals_0(struct ctx* ctx, struct mut_list_1* a, struct arr_0 value);
struct void_ incr_capacity__e_0(struct ctx* ctx, struct mut_list_1* a);
struct void_ ensure_capacity_0(struct ctx* ctx, struct mut_list_1* a, uint64_t min_capacity);
uint64_t capacity_1(struct mut_list_1* a);
struct void_ increase_capacity_to__e_0(struct ctx* ctx, struct mut_list_1* a, uint64_t new_capacity);
struct arr_0* data_4(struct mut_list_1* a);
struct void_ copy_data_from_1(struct ctx* ctx, struct arr_0* to, struct arr_0* from, uint64_t len);
struct void_ set_zero_elements_0(struct mut_arr_1 a);
struct void_ set_zero_range_1(struct arr_0* begin, uint64_t size);
uint64_t round_up_to_power_of_two(struct ctx* ctx, uint64_t n);
uint64_t round_up_to_power_of_two_recur(struct ctx* ctx, uint64_t acc, uint64_t n);
uint64_t _times_0(struct ctx* ctx, uint64_t a, uint64_t b);
struct void_ _concatEquals_1(struct ctx* ctx, struct mut_list_2* a, struct arr_1 value);
struct void_ incr_capacity__e_1(struct ctx* ctx, struct mut_list_2* a);
struct void_ ensure_capacity_1(struct ctx* ctx, struct mut_list_2* a, uint64_t min_capacity);
uint64_t capacity_2(struct mut_list_2* a);
struct void_ increase_capacity_to__e_1(struct ctx* ctx, struct mut_list_2* a, uint64_t new_capacity);
struct arr_1* data_5(struct mut_list_2* a);
struct void_ copy_data_from_2(struct ctx* ctx, struct arr_1* to, struct arr_1* from, uint64_t len);
struct void_ set_zero_elements_1(struct mut_arr_2 a);
struct void_ set_zero_range_2(struct arr_1* begin, uint64_t size);
struct arr_0 subscript_38(struct ctx* ctx, struct mut_list_1* a, uint64_t index);
struct arr_0 noctx_at_8(struct mut_list_1* a, uint64_t index);
struct void_ insert_at__e_0(struct ctx* ctx, struct mut_list_1* a, uint64_t index, struct arr_0 value);
extern void memmove(uint8_t* dest, uint8_t* src, uint64_t size);
struct void_ set_subscript_7(struct ctx* ctx, struct mut_list_1* a, uint64_t index, struct arr_0 value);
struct void_ noctx_set_at__e_1(struct mut_list_1* a, uint64_t index, struct arr_0 value);
struct void_ insert_at__e_1(struct ctx* ctx, struct mut_list_2* a, uint64_t index, struct arr_1 value);
struct void_ set_subscript_8(struct ctx* ctx, struct mut_list_2* a, uint64_t index, struct arr_1 value);
struct void_ noctx_set_at__e_2(struct mut_list_2* a, uint64_t index, struct arr_1 value);
struct dict_0* move_to_dict__e_0(struct ctx* ctx, struct mut_dict_0* m);
struct arr_1 move_to_arr__e_0(struct mut_list_1* a);
struct arr_6 move_to_arr__e_1(struct mut_list_2* a);
struct void_ assert_1(struct ctx* ctx, uint8_t condition, struct arr_0 message);
struct mut_list_3* fill_mut_list(struct ctx* ctx, uint64_t size, struct opt_10 value);
struct mut_arr_3 fill_mut_arr(struct ctx* ctx, uint64_t size, struct opt_10 value);
struct mut_arr_3 make_mut_arr_2(struct ctx* ctx, uint64_t size, struct fun_act1_10 f);
struct mut_arr_3 uninitialized_mut_arr_2(struct ctx* ctx, uint64_t size);
struct mut_arr_3 mut_arr_7(uint64_t size, struct opt_10* data);
struct opt_10* alloc_uninitialized_3(struct ctx* ctx, uint64_t size);
struct void_ fill_ptr_range_2(struct ctx* ctx, struct opt_10* begin, uint64_t size, struct fun_act1_10 f);
struct void_ fill_ptr_range_recur_2(struct ctx* ctx, struct opt_10* begin, uint64_t i, uint64_t size, struct fun_act1_10 f);
struct void_ set_subscript_9(struct opt_10* a, uint64_t n, struct opt_10 value);
struct opt_10 subscript_39(struct ctx* ctx, struct fun_act1_10 a, uint64_t p0);
struct opt_10 call_w_ctx_498(struct fun_act1_10 a, struct ctx* ctx, uint64_t p0);
struct opt_10* data_6(struct mut_arr_3 a);
struct opt_10 fill_mut_arr__lambda0(struct ctx* ctx, struct fill_mut_arr__lambda0* _closure, uint64_t ignore);
struct void_ each_0(struct ctx* ctx, struct dict_0* d, struct fun_act2_1 f);
uint8_t empty__q_6(struct ctx* ctx, struct dict_0* d);
struct void_ subscript_40(struct ctx* ctx, struct fun_act2_1 a, struct arr_0 p0, struct arr_1 p1);
struct void_ call_w_ctx_504(struct fun_act2_1 a, struct ctx* ctx, struct arr_0 p0, struct arr_1 p1);
struct arr_1 first_1(struct ctx* ctx, struct arr_6 a);
uint8_t empty__q_7(struct arr_6 a);
struct arr_6 tail_2(struct ctx* ctx, struct arr_6 a);
struct opt_8 index_of(struct ctx* ctx, struct arr_1 a, struct arr_0 value);
uint8_t index_of__lambda0(struct ctx* ctx, struct index_of__lambda0* _closure, struct arr_0 it);
uint8_t has__q_1(struct opt_10 a);
uint8_t empty__q_8(struct opt_10 a);
struct opt_10 subscript_41(struct ctx* ctx, struct mut_list_3* a, uint64_t index);
struct opt_10 noctx_at_9(struct mut_list_3* a, uint64_t index);
struct opt_10 subscript_42(struct opt_10* a, uint64_t n);
struct opt_10* data_7(struct mut_list_3* a);
struct void_ set_subscript_10(struct ctx* ctx, struct mut_list_3* a, uint64_t index, struct opt_10 value);
struct void_ noctx_set_at__e_3(struct mut_list_3* a, uint64_t index, struct opt_10 value);
struct void_ parse_cmd_line_args__lambda0(struct ctx* ctx, struct parse_cmd_line_args__lambda0* _closure, struct arr_0 key, struct arr_1 value);
struct test_options subscript_43(struct ctx* ctx, struct fun1_2 a, struct arr_5 p0);
struct test_options call_w_ctx_520(struct fun1_2 a, struct ctx* ctx, struct arr_5 p0);
struct arr_5 move_to_arr__e_2(struct mut_list_3* a);
struct mut_arr_3 mut_arr_8(void);
struct opt_10 subscript_44(struct ctx* ctx, struct arr_5 a, uint64_t index);
struct opt_10 noctx_at_10(struct arr_5 a, uint64_t index);
uint64_t force_1(struct ctx* ctx, struct opt_8 a);
uint64_t fail_2(struct ctx* ctx, struct arr_0 reason);
uint64_t throw_2(struct ctx* ctx, struct exception e);
struct opt_8 parse_nat(struct ctx* ctx, struct arr_0 a);
struct opt_8 parse_nat_recur(struct ctx* ctx, struct arr_0 a, uint64_t accum);
struct opt_8 char_to_nat(struct ctx* ctx, char c);
char first_2(struct ctx* ctx, struct arr_0 a);
struct arr_0 tail_3(struct ctx* ctx, struct arr_0 a);
struct test_options main_0__lambda0(struct ctx* ctx, struct void_ _closure, struct arr_5 values);
struct fut_0* resolved_1(struct ctx* ctx, uint64_t value);
struct void_ print_help(struct ctx* ctx);
uint64_t do_test(struct ctx* ctx, struct test_options options);
struct arr_0 parent_path(struct ctx* ctx, struct arr_0 a);
struct opt_8 r_index_of(struct ctx* ctx, struct arr_0 a, char value);
struct opt_8 find_rindex(struct ctx* ctx, struct arr_0 a, struct fun_act1_11 pred);
struct opt_8 find_rindex_recur(struct ctx* ctx, struct arr_0 a, uint64_t index, struct fun_act1_11 pred);
uint8_t subscript_45(struct ctx* ctx, struct fun_act1_11 a, char p0);
uint8_t call_w_ctx_542(struct fun_act1_11 a, struct ctx* ctx, char p0);
uint64_t decr(struct ctx* ctx, uint64_t a);
uint8_t r_index_of__lambda0(struct ctx* ctx, struct r_index_of__lambda0* _closure, char it);
struct arr_0 current_executable_path(struct ctx* ctx);
struct arr_0 read_link(struct ctx* ctx, struct arr_0 path);
struct mut_arr_4 uninitialized_mut_arr_3(struct ctx* ctx, uint64_t size);
struct mut_arr_4 mut_arr_9(uint64_t size, char* data);
extern int64_t readlink(char* path, char* buf, uint64_t len);
char* to_c_str(struct ctx* ctx, struct arr_0 a);
char* data_8(struct mut_arr_4 a);
uint64_t size_4(struct mut_arr_4 a);
struct void_ check_errno_if_neg_one(struct ctx* ctx, int64_t e);
struct void_ check_posix_error(struct ctx* ctx, int32_t e);
extern int32_t errno;
struct arr_0 cast_immutable_2(struct mut_arr_4 a);
uint64_t to_nat_0(struct ctx* ctx, int64_t i);
uint8_t negative__q(struct ctx* ctx, int64_t i);
uint8_t _less_2(int64_t a, int64_t b);
struct arr_0 child_path(struct ctx* ctx, struct arr_0 a, struct arr_0 child_name);
struct dict_1* get_environ(struct ctx* ctx);
struct mut_dict_1* mut_dict_1(struct ctx* ctx);
struct void_ get_environ_recur(struct ctx* ctx, char** env, struct mut_dict_1* res);
uint8_t null__q_2(char* a);
struct arrow_2* parse_environ_entry(struct ctx* ctx, char* entry);
struct arrow_2* _arrow_1(struct ctx* ctx, struct arr_0 from, struct arr_0 to);
struct void_ set_subscript_11(struct ctx* ctx, struct mut_dict_1* a, struct arr_0 key, struct arr_0 value);
struct void_ set_subscript_recur_1(struct ctx* ctx, struct mut_dict_1* a, uint64_t idx, struct arr_0 key, struct arr_0 value);
char** incr_6(char** p);
extern char** environ;
struct dict_1* move_to_dict__e_1(struct ctx* ctx, struct mut_dict_1* m);
struct dict_1* dict_2(struct ctx* ctx, struct arr_1 keys, struct arr_1 values);
struct sorted_by_first_1* sort_by_first_1(struct ctx* ctx, struct arr_1 a, struct arr_1 b);
struct void_ sort_by_first__e_1(struct ctx* ctx, struct mut_arr_1 a, struct mut_arr_1 b);
uint64_t partition_by_first__e_1(struct ctx* ctx, struct mut_arr_1 a, struct mut_arr_1 b, struct arr_0 pivot, uint64_t l, uint64_t r);
struct result_2 first_failures(struct ctx* ctx, struct result_2 a, struct fun0 b);
struct result_2 subscript_46(struct ctx* ctx, struct fun0 a);
struct result_2 call_w_ctx_578(struct fun0 a, struct ctx* ctx);
struct result_2 run_crow_tests(struct ctx* ctx, struct arr_0 path, struct arr_0 path_to_crow, struct dict_1* env, struct test_options options);
struct arr_1 list_tests(struct ctx* ctx, struct arr_0 path);
uint8_t list_tests__lambda0(struct ctx* ctx, struct void_ _closure, struct arr_0 s);
struct void_ each_child_recursive(struct ctx* ctx, struct arr_0 path, struct fun_act1_6 filter, struct fun_act1_12 f);
uint8_t is_dir__q_0(struct ctx* ctx, struct arr_0 path);
uint8_t is_dir__q_1(struct ctx* ctx, char* path);
struct opt_12 get_stat(struct ctx* ctx, char* path);
struct stat_t* empty_stat(struct ctx* ctx);
extern int32_t stat(char* path, struct stat_t* buf);
int32_t enoent(void);
struct opt_12 todo_6(void);
uint8_t todo_7(void);
uint8_t _equal_5(uint32_t a, uint32_t b);
struct comparison compare_592(uint32_t a, uint32_t b);
uint32_t s_ifmt(struct ctx* ctx);
uint32_t s_ifdir(struct ctx* ctx);
struct void_ each_1(struct ctx* ctx, struct arr_1 a, struct fun_act1_12 f);
struct void_ subscript_47(struct ctx* ctx, struct fun_act1_12 a, struct arr_0 p0);
struct void_ call_w_ctx_597(struct fun_act1_12 a, struct ctx* ctx, struct arr_0 p0);
struct arr_1 read_dir_0(struct ctx* ctx, struct arr_0 path);
struct arr_1 read_dir_1(struct ctx* ctx, char* path);
extern struct dir* opendir(char* name);
uint8_t null__q_3(uint8_t** a);
struct void_ read_dir_recur(struct ctx* ctx, struct dir* dirp, struct mut_list_1* res);
struct bytes256 zero_4(void);
extern int32_t readdir_r(struct dir* dirp, struct dirent* entry, struct cell_4* result);
uint8_t ref_eq__q(struct dirent* a, struct dirent* b);
struct arr_0 get_dirent_name(struct dirent* d);
uint8_t _notEqual_4(struct arr_0 a, struct arr_0 b);
struct arr_1 sort(struct ctx* ctx, struct arr_1 a);
struct void_ sort__e(struct ctx* ctx, struct mut_arr_1 a);
uint64_t partition__e(struct ctx* ctx, struct mut_arr_1 a, struct arr_0 pivot, uint64_t l, uint64_t r);
struct void_ each_child_recursive__lambda0(struct ctx* ctx, struct each_child_recursive__lambda0* _closure, struct arr_0 child_name);
struct opt_11 get_extension(struct ctx* ctx, struct arr_0 name);
struct opt_8 last_index_of(struct ctx* ctx, struct arr_0 s, char c);
char last(struct ctx* ctx, struct arr_0 a);
struct arr_0 rtail(struct ctx* ctx, struct arr_0 a);
struct arr_0 base_name(struct ctx* ctx, struct arr_0 path);
struct void_ list_tests__lambda1(struct ctx* ctx, struct list_tests__lambda1* _closure, struct arr_0 child);
struct arr_8 flat_map_with_max_size(struct ctx* ctx, struct arr_1 a, uint64_t max_size, struct fun_act1_13 mapper);
struct mut_list_4* mut_list_2(struct ctx* ctx);
struct mut_arr_5 mut_arr_10(void);
struct void_ _concatEquals_2(struct ctx* ctx, struct mut_list_4* a, struct arr_8 values);
struct void_ each_2(struct ctx* ctx, struct arr_8 a, struct fun_act1_14 f);
uint8_t empty__q_9(struct arr_8 a);
struct void_ subscript_48(struct ctx* ctx, struct fun_act1_14 a, struct failure* p0);
struct void_ call_w_ctx_625(struct fun_act1_14 a, struct ctx* ctx, struct failure* p0);
struct failure* first_3(struct ctx* ctx, struct arr_8 a);
struct failure* subscript_49(struct ctx* ctx, struct arr_8 a, uint64_t index);
struct failure* noctx_at_11(struct arr_8 a, uint64_t index);
struct failure* subscript_50(struct failure** a, uint64_t n);
struct arr_8 tail_4(struct ctx* ctx, struct arr_8 a);
struct arr_8 subscript_51(struct ctx* ctx, struct arr_8 a, struct arrow_0 range);
struct void_ _concatEquals_3(struct ctx* ctx, struct mut_list_4* a, struct failure* value);
struct void_ incr_capacity__e_2(struct ctx* ctx, struct mut_list_4* a);
struct void_ ensure_capacity_2(struct ctx* ctx, struct mut_list_4* a, uint64_t min_capacity);
uint64_t capacity_3(struct mut_list_4* a);
uint64_t size_5(struct mut_arr_5 a);
struct void_ increase_capacity_to__e_2(struct ctx* ctx, struct mut_list_4* a, uint64_t new_capacity);
struct failure** data_9(struct mut_list_4* a);
struct failure** data_10(struct mut_arr_5 a);
struct mut_arr_5 mut_arr_11(uint64_t size, struct failure** data);
struct failure** alloc_uninitialized_4(struct ctx* ctx, uint64_t size);
struct void_ copy_data_from_3(struct ctx* ctx, struct failure** to, struct failure** from, uint64_t len);
struct void_ set_zero_elements_2(struct mut_arr_5 a);
struct void_ set_zero_range_3(struct failure** begin, uint64_t size);
struct mut_arr_5 subscript_52(struct ctx* ctx, struct mut_arr_5 a, struct arrow_0 range);
struct void_ set_subscript_12(struct failure** a, uint64_t n, struct failure* value);
struct void_ _concatEquals_2__lambda0(struct ctx* ctx, struct _concatEquals_2__lambda0* _closure, struct failure* it);
struct arr_8 subscript_53(struct ctx* ctx, struct fun_act1_13 a, struct arr_0 p0);
struct arr_8 call_w_ctx_649(struct fun_act1_13 a, struct ctx* ctx, struct arr_0 p0);
struct void_ reduce_size_if_more_than__e(struct ctx* ctx, struct mut_list_4* a, uint64_t new_size);
struct void_ drop_2(struct opt_13 _p0);
struct opt_13 pop__e(struct ctx* ctx, struct mut_list_4* a);
uint8_t empty__q_10(struct mut_list_4* a);
struct failure* subscript_54(struct ctx* ctx, struct mut_list_4* a, uint64_t index);
struct failure* noctx_at_12(struct mut_list_4* a, uint64_t index);
struct void_ set_subscript_13(struct ctx* ctx, struct mut_list_4* a, uint64_t index, struct failure* value);
struct void_ noctx_set_at__e_4(struct mut_list_4* a, uint64_t index, struct failure* value);
struct void_ flat_map_with_max_size__lambda0(struct ctx* ctx, struct flat_map_with_max_size__lambda0* _closure, struct arr_0 x);
struct arr_8 move_to_arr__e_3(struct mut_list_4* a);
struct arr_8 run_single_crow_test(struct ctx* ctx, struct arr_0 path_to_crow, struct dict_1* env, struct arr_0 path, struct test_options options);
struct opt_14 first_some(struct ctx* ctx, struct arr_1 a, struct fun_act1_15 cb);
struct opt_14 subscript_55(struct ctx* ctx, struct fun_act1_15 a, struct arr_0 p0);
struct opt_14 call_w_ctx_663(struct fun_act1_15 a, struct ctx* ctx, struct arr_0 p0);
struct print_test_result* run_print_test(struct ctx* ctx, struct arr_0 print_kind, struct arr_0 path_to_crow, struct dict_1* env, struct arr_0 path, uint8_t overwrite_output__q);
struct process_result* spawn_and_wait_result_0(struct ctx* ctx, struct arr_0 exe, struct arr_1 args, struct dict_1* environ);
struct arr_0 fold(struct ctx* ctx, struct arr_0 val, struct arr_1 a, struct fun_act2_2 combine);
struct arr_0 subscript_56(struct ctx* ctx, struct fun_act2_2 a, struct arr_0 p0, struct arr_0 p1);
struct arr_0 call_w_ctx_668(struct fun_act2_2 a, struct ctx* ctx, struct arr_0 p0, struct arr_0 p1);
struct arr_0 spawn_and_wait_result_0__lambda0(struct ctx* ctx, struct void_ _closure, struct arr_0 a, struct arr_0 b);
uint8_t is_file__q_0(struct ctx* ctx, struct arr_0 path);
uint8_t is_file__q_1(struct ctx* ctx, char* path);
uint32_t s_ifreg(struct ctx* ctx);
struct process_result* spawn_and_wait_result_1(struct ctx* ctx, char* exe, char** args, char** environ);
struct pipes* make_pipes(struct ctx* ctx);
extern int32_t pipe(struct pipes* pipes);
extern int32_t posix_spawn_file_actions_init(struct posix_spawn_file_actions_t* file_actions);
extern int32_t posix_spawn_file_actions_addclose(struct posix_spawn_file_actions_t* file_actions, int32_t fd);
extern int32_t posix_spawn_file_actions_adddup2(struct posix_spawn_file_actions_t* file_actions, int32_t fd, int32_t new_fd);
extern int32_t posix_spawn(struct cell_5* pid, char* executable_path, struct posix_spawn_file_actions_t* file_actions, uint8_t* attrp, char** argv, char** environ);
extern int32_t close(int32_t fd);
struct mut_list_5* mut_list_3(struct ctx* ctx);
struct mut_arr_4 mut_arr_12(void);
struct void_ keep_polling(struct ctx* ctx, int32_t stdout_pipe, int32_t stderr_pipe, struct mut_list_5* stdout_builder, struct mut_list_5* stderr_builder);
int16_t pollin(struct ctx* ctx);
struct pollfd* ref_of_val_at(struct ctx* ctx, struct arr_9 a, uint64_t index);
struct pollfd* ref_of_ptr(struct pollfd* p);
extern int32_t poll(struct pollfd* fds, uint64_t n_fds, int32_t timeout);
struct handle_revents_result handle_revents(struct ctx* ctx, struct pollfd* pollfd, struct mut_list_5* builder);
uint8_t has_pollin__q(struct ctx* ctx, int16_t revents);
uint8_t bits_intersect__q(int16_t a, int16_t b);
uint8_t _equal_6(int16_t a, int16_t b);
struct comparison compare_692(int16_t a, int16_t b);
struct void_ read_to_buffer_until_eof(struct ctx* ctx, int32_t fd, struct mut_list_5* buffer);
struct void_ reserve(struct ctx* ctx, struct mut_list_5* a, uint64_t reserved);
struct void_ ensure_capacity_3(struct ctx* ctx, struct mut_list_5* a, uint64_t min_capacity);
uint64_t capacity_4(struct mut_list_5* a);
struct void_ increase_capacity_to__e_3(struct ctx* ctx, struct mut_list_5* a, uint64_t new_capacity);
char* data_11(struct mut_list_5* a);
struct void_ set_zero_elements_3(struct mut_arr_4 a);
struct void_ set_zero_range_4(char* begin, uint64_t size);
struct mut_arr_4 subscript_57(struct ctx* ctx, struct mut_arr_4 a, struct arrow_0 range);
extern int64_t read(int32_t fd, uint8_t* buff, uint64_t n_bytes);
struct void_ unsafe_increase_size__e(struct ctx* ctx, struct mut_list_5* a, uint64_t increase_by);
struct void_ unsafe_set_size__e(struct ctx* ctx, struct mut_list_5* a, uint64_t new_size);
uint8_t has_pollhup__q(struct ctx* ctx, int16_t revents);
int16_t pollhup(struct ctx* ctx);
uint8_t has_pollpri__q(struct ctx* ctx, int16_t revents);
int16_t pollpri(struct ctx* ctx);
uint8_t has_pollout__q(struct ctx* ctx, int16_t revents);
int16_t pollout(struct ctx* ctx);
uint8_t has_pollerr__q(struct ctx* ctx, int16_t revents);
int16_t pollerr(struct ctx* ctx);
uint8_t has_pollnval__q(struct ctx* ctx, int16_t revents);
int16_t pollnval(struct ctx* ctx);
uint64_t to_nat_1(uint8_t b);
uint8_t any__q(struct ctx* ctx, struct handle_revents_result r);
uint64_t to_nat_2(struct ctx* ctx, int32_t i);
int32_t wait_and_get_exit_code(struct ctx* ctx, int32_t pid);
extern int32_t waitpid(int32_t pid, struct cell_5* wait_status, int32_t options);
uint8_t w_if_exited(struct ctx* ctx, int32_t status);
int32_t w_term_sig(struct ctx* ctx, int32_t status);
int32_t w_exit_status(struct ctx* ctx, int32_t status);
int32_t bit_shift_right(int32_t a, int32_t b);
uint8_t _less_3(int32_t a, int32_t b);
int32_t todo_8(void);
uint8_t w_if_signaled(struct ctx* ctx, int32_t status);
struct arr_0 to_str_2(struct ctx* ctx, int32_t i);
struct arr_0 to_str_3(struct ctx* ctx, int64_t i);
struct arr_0 to_str_4(struct ctx* ctx, uint64_t n);
uint64_t mod(struct ctx* ctx, uint64_t a, uint64_t b);
uint64_t abs(struct ctx* ctx, int64_t i);
int64_t neg(struct ctx* ctx, int64_t i);
int64_t _times_1(struct ctx* ctx, int64_t a, int64_t b);
uint8_t w_if_stopped(struct ctx* ctx, int32_t status);
uint8_t w_if_continued(struct ctx* ctx, int32_t status);
struct arr_0 move_to_arr__e_4(struct mut_list_5* a);
char** convert_args(struct ctx* ctx, char* exe_c_str, struct arr_1 args);
struct arr_4 _concat_1(struct ctx* ctx, struct arr_4 a, struct arr_4 b);
char** alloc_uninitialized_5(struct ctx* ctx, uint64_t size);
struct void_ copy_data_from_4(struct ctx* ctx, char** to, char** from, uint64_t len);
struct arr_4 map_3(struct ctx* ctx, struct arr_1 a, struct fun_act1_16 mapper);
struct arr_4 make_arr_2(struct ctx* ctx, uint64_t size, struct fun_act1_17 f);
struct void_ fill_ptr_range_3(struct ctx* ctx, char** begin, uint64_t size, struct fun_act1_17 f);
struct void_ fill_ptr_range_recur_3(struct ctx* ctx, char** begin, uint64_t i, uint64_t size, struct fun_act1_17 f);
struct void_ set_subscript_14(char** a, uint64_t n, char* value);
char* subscript_58(struct ctx* ctx, struct fun_act1_17 a, uint64_t p0);
char* call_w_ctx_747(struct fun_act1_17 a, struct ctx* ctx, uint64_t p0);
char* subscript_59(struct ctx* ctx, struct fun_act1_16 a, struct arr_0 p0);
char* call_w_ctx_749(struct fun_act1_16 a, struct ctx* ctx, struct arr_0 p0);
char* map_3__lambda0(struct ctx* ctx, struct map_3__lambda0* _closure, uint64_t i);
char* convert_args__lambda0(struct ctx* ctx, struct void_ _closure, struct arr_0 it);
char** convert_environ(struct ctx* ctx, struct dict_1* environ);
struct mut_list_6* mut_list_4(struct ctx* ctx);
struct mut_arr_6 mut_arr_13(void);
struct void_ each_3(struct ctx* ctx, struct dict_1* d, struct fun_act2_3 f);
uint8_t empty__q_11(struct ctx* ctx, struct dict_1* d);
struct void_ subscript_60(struct ctx* ctx, struct fun_act2_3 a, struct arr_0 p0, struct arr_0 p1);
struct void_ call_w_ctx_758(struct fun_act2_3 a, struct ctx* ctx, struct arr_0 p0, struct arr_0 p1);
struct void_ _concatEquals_4(struct ctx* ctx, struct mut_list_6* a, char* value);
struct void_ incr_capacity__e_3(struct ctx* ctx, struct mut_list_6* a);
struct void_ ensure_capacity_4(struct ctx* ctx, struct mut_list_6* a, uint64_t min_capacity);
uint64_t capacity_5(struct mut_list_6* a);
uint64_t size_6(struct mut_arr_6 a);
struct void_ increase_capacity_to__e_4(struct ctx* ctx, struct mut_list_6* a, uint64_t new_capacity);
char** data_12(struct mut_list_6* a);
char** data_13(struct mut_arr_6 a);
struct mut_arr_6 mut_arr_14(uint64_t size, char** data);
struct void_ set_zero_elements_4(struct mut_arr_6 a);
struct void_ set_zero_range_5(char** begin, uint64_t size);
struct mut_arr_6 subscript_61(struct ctx* ctx, struct mut_arr_6 a, struct arrow_0 range);
struct void_ convert_environ__lambda0(struct ctx* ctx, struct convert_environ__lambda0* _closure, struct arr_0 key, struct arr_0 value);
struct arr_4 move_to_arr__e_5(struct mut_list_6* a);
struct process_result* fail_3(struct ctx* ctx, struct arr_0 reason);
struct process_result* throw_3(struct ctx* ctx, struct exception e);
struct process_result* todo_9(void);
struct arr_8 handle_output(struct ctx* ctx, struct arr_0 original_path, struct arr_0 output_path, struct arr_0 actual, uint8_t overwrite_output__q);
struct opt_11 try_read_file_0(struct ctx* ctx, struct arr_0 path);
struct opt_11 try_read_file_1(struct ctx* ctx, char* path);
extern int32_t open(char* path, int32_t oflag, uint32_t permission);
int32_t o_rdonly(void);
struct opt_11 todo_10(void);
extern int64_t lseek(int32_t f, int64_t offset, int32_t whence);
int32_t seek_end(struct ctx* ctx);
int32_t seek_set(struct ctx* ctx);
struct void_ write_file_0(struct ctx* ctx, struct arr_0 path, struct arr_0 content);
struct void_ write_file_1(struct ctx* ctx, char* path, struct arr_0 content);
uint32_t bit_shift_left(uint32_t a, uint32_t b);
uint8_t _less_4(uint32_t a, uint32_t b);
int32_t o_creat(void);
int32_t o_wronly(void);
int32_t o_trunc(void);
struct arr_0 to_str_5(struct ctx* ctx, uint32_t n);
int64_t to_int(struct ctx* ctx, uint64_t n);
int64_t max_int(void);
struct arr_0 remove_colors(struct ctx* ctx, struct arr_0 s);
struct void_ remove_colors_recur(struct ctx* ctx, struct arr_0 s, struct mut_list_5* out);
struct void_ remove_colors_recur_2(struct ctx* ctx, struct arr_0 s, struct mut_list_5* out);
struct void_ _concatEquals_5(struct ctx* ctx, struct mut_list_5* a, char value);
struct void_ incr_capacity__e_4(struct ctx* ctx, struct mut_list_5* a);
struct void_ set_subscript_15(char* a, uint64_t n, char value);
struct opt_14 run_single_crow_test__lambda0(struct ctx* ctx, struct run_single_crow_test__lambda0* _closure, struct arr_0 print_kind);
struct arr_8 run_single_runnable_test(struct ctx* ctx, struct arr_0 path_to_crow, struct dict_1* env, struct arr_0 path, uint8_t interpret__q, uint8_t overwrite_output__q);
struct arr_8 _concat_2(struct ctx* ctx, struct arr_8 a, struct arr_8 b);
struct arr_8 run_crow_tests__lambda0(struct ctx* ctx, struct run_crow_tests__lambda0* _closure, struct arr_0 test);
uint8_t has__q_2(struct arr_8 a);
struct result_2 do_test__lambda0__lambda0(struct ctx* ctx, struct do_test__lambda0__lambda0* _closure);
struct result_2 do_test__lambda0(struct ctx* ctx, struct do_test__lambda0* _closure);
struct result_2 lint(struct ctx* ctx, struct arr_0 path, struct test_options options);
struct arr_1 list_lintable_files(struct ctx* ctx, struct arr_0 path);
uint8_t excluded_from_lint__q(struct ctx* ctx, struct arr_0 name);
uint8_t contains__q_2(struct arr_1 a, struct arr_0 value);
uint8_t contains_recur__q_1(struct arr_1 a, struct arr_0 value, uint64_t i);
uint8_t exists__q(struct ctx* ctx, struct arr_1 a, struct fun_act1_6 pred);
uint8_t ends_with__q(struct ctx* ctx, struct arr_0 a, struct arr_0 end);
uint8_t excluded_from_lint__q__lambda0(struct ctx* ctx, struct excluded_from_lint__q__lambda0* _closure, struct arr_0 it);
uint8_t list_lintable_files__lambda0(struct ctx* ctx, struct void_ _closure, struct arr_0 it);
uint8_t ignore_extension_of_name__q(struct ctx* ctx, struct arr_0 name);
uint8_t ignore_extension__q(struct ctx* ctx, struct arr_0 ext);
struct arr_1 ignored_extensions(struct ctx* ctx);
struct void_ list_lintable_files__lambda1(struct ctx* ctx, struct list_lintable_files__lambda1* _closure, struct arr_0 child);
struct arr_8 lint_file(struct ctx* ctx, struct arr_0 path);
struct arr_0 read_file(struct ctx* ctx, struct arr_0 path);
struct void_ each_with_index_0(struct ctx* ctx, struct arr_1 a, struct fun_act2_4 f);
struct void_ each_with_index_recur_0(struct ctx* ctx, struct arr_1 a, struct fun_act2_4 f, uint64_t n);
struct void_ subscript_62(struct ctx* ctx, struct fun_act2_4 a, struct arr_0 p0, uint64_t p1);
struct void_ call_w_ctx_826(struct fun_act2_4 a, struct ctx* ctx, struct arr_0 p0, uint64_t p1);
struct arr_1 lines(struct ctx* ctx, struct arr_0 s);
struct void_ each_with_index_1(struct ctx* ctx, struct arr_0 a, struct fun_act2_5 f);
struct void_ each_with_index_recur_1(struct ctx* ctx, struct arr_0 a, struct fun_act2_5 f, uint64_t n);
struct void_ subscript_63(struct ctx* ctx, struct fun_act2_5 a, char p0, uint64_t p1);
struct void_ call_w_ctx_831(struct fun_act2_5 a, struct ctx* ctx, char p0, uint64_t p1);
uint64_t swap_4(struct cell_0* c, uint64_t v);
struct void_ lines__lambda0(struct ctx* ctx, struct lines__lambda0* _closure, char c, uint64_t index);
uint8_t contains_subseq__q(struct ctx* ctx, struct arr_0 a, struct arr_0 subseq);
uint8_t has__q_3(struct opt_8 a);
uint8_t empty__q_12(struct opt_8 a);
struct opt_8 index_of_subseq(struct ctx* ctx, struct arr_0 a, struct arr_0 subseq);
struct opt_8 index_of_subseq_recur(struct ctx* ctx, struct arr_0 a, struct arr_0 subseq, uint64_t i);
uint64_t line_len(struct ctx* ctx, struct arr_0 line);
uint64_t n_tabs(struct ctx* ctx, struct arr_0 line);
uint64_t tab_size(struct ctx* ctx);
uint64_t max_line_length(struct ctx* ctx);
struct void_ lint_file__lambda0(struct ctx* ctx, struct lint_file__lambda0* _closure, struct arr_0 line, uint64_t line_num);
struct arr_8 lint__lambda0(struct ctx* ctx, struct lint__lambda0* _closure, struct arr_0 file);
struct result_2 do_test__lambda1(struct ctx* ctx, struct do_test__lambda1* _closure);
uint64_t print_failures(struct ctx* ctx, struct result_2 failures, struct test_options options);
struct void_ print_failure(struct ctx* ctx, struct failure* failure);
struct void_ print_bold(struct ctx* ctx);
struct void_ print_reset(struct ctx* ctx);
struct void_ print_failures__lambda0(struct ctx* ctx, struct void_ _closure, struct failure* it);
int32_t main(int32_t argc, char** argv);
/* mark bool(ctx mark-ctx, ptr-any ptr<nat8>, size-bytes nat) */
uint8_t mark(struct mark_ctx* ctx, uint8_t* ptr_any, uint64_t size_bytes) {
	uint64_t size_words0;
	size_words0 = words_of_bytes(size_bytes);
	
	uint64_t* ptr1;
	ptr1 = (uint64_t*) ptr_any;
	
	uint8_t _0 = _equal_0(((uint64_t) ptr1 & 7u), 0u);
	hard_assert(_0);
	uint64_t index2;
	index2 = _minus_0(ptr1, ctx->memory_start);
	
	uint8_t gc_memory__q3;
	gc_memory__q3 = _less_0(index2, ctx->memory_size_words);
	
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
/* words-of-bytes nat(size-bytes nat) */
uint64_t words_of_bytes(uint64_t size_bytes) {
	uint64_t _0 = round_up_to_multiple_of_8(size_bytes);
	return (_0 / 8u);
}
/* round-up-to-multiple-of-8 nat(n nat) */
uint64_t round_up_to_multiple_of_8(uint64_t n) {
	return ((n + 7u) & ~7u);
}
/* hard-assert void(condition bool) */
struct void_ hard_assert(uint8_t condition) {
	uint8_t _0 = not(condition);
	if (_0) {
		return (abort(), (struct void_) {});
	} else {
		return (struct void_) {};
	}
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
/* ==<nat> bool(a nat, b nat) */
uint8_t _equal_0(uint64_t a, uint64_t b) {
	struct comparison _0 = compare_7(a, b);
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
struct comparison compare_7(uint64_t a, uint64_t b) {
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
/* -<nat> nat(a ptr<nat>, b ptr<nat>) */
uint64_t _minus_0(uint64_t* a, uint64_t* b) {
	return (((uint64_t) a - (uint64_t) b) / sizeof(uint64_t));
}
/* <<nat> bool(a nat, b nat) */
uint8_t _less_0(uint64_t a, uint64_t b) {
	struct comparison _0 = compare_7(a, b);
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
	uint8_t _0 = _less_0(b, a);
	return not(_0);
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
			new_marked_anything__q0 = not(*cur);
		}
		
		*cur = 1;
		uint8_t* _1 = incr_0(cur);
		marked_anything__q = new_marked_anything__q0;
		cur = _1;
		end = end;
		goto top;
	}
}
/* incr<bool> ptr<bool>(p ptr<bool>) */
uint8_t* incr_0(uint8_t* p) {
	return (p + 1u);
}
/* ><nat> bool(a nat, b nat) */
uint8_t _greater(uint64_t a, uint64_t b) {
	return _less_0(b, a);
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
			struct fut_state_resolved_0 r6 = _2.as1;
			
			uint8_t _3 = gctx2->any_unhandled_exceptions__q;
			if (_3) {
				return 1;
			} else {
				return (int32_t) (int64_t) r6.value;
			}
		}
		case 2: {
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
/* mut-arr<?t> mut-arr<nat>(size nat, data ptr<nat>) */
struct mut_arr_0 mut_arr_0(uint64_t size, uint64_t* data) {
	return (struct mut_arr_0) {(struct void_) {}, (struct arr_2) {size, data}};
}
/* unmanaged-alloc-zeroed-elements<?t> ptr<nat>(size-elements nat) */
uint64_t* unmanaged_alloc_zeroed_elements(uint64_t size_elements) {
	uint64_t* res0;
	res0 = unmanaged_alloc_elements_0(size_elements);
	
	set_zero_range_0(res0, size_elements);
	return res0;
}
/* unmanaged-alloc-elements<?t> ptr<nat>(size-elements nat) */
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
	uint8_t _0 = not(condition);
	return hard_assert(_0);
}
/* null?<nat8> bool(a ptr<nat8>) */
uint8_t null__q_0(uint8_t* a) {
	return _equal_0((uint64_t) a, (uint64_t) NULL);
}
/* set-zero-range<?t> void(begin ptr<nat>, size nat) */
struct void_ set_zero_range_0(uint64_t* begin, uint64_t size) {
	return (memset((uint8_t*) begin, 0u, (size * sizeof(uint64_t))), (struct void_) {});
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
	res0 = write(fd, (uint8_t*) a.data, a.size);
	
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
/* ==<?t> bool(a int, b int) */
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
	bt1 = join(ctx, a.backtrace.return_stack, (struct arr_0) {5, constantarr_0_6});
	
	struct arr_0 _1 = _concat_0(ctx, msg0, (struct arr_0) {5, constantarr_0_6});
	return _concat_0(ctx, _1, bt1);
}
/* empty?<char> bool(a arr<char>) */
uint8_t empty__q_0(struct arr_0 a) {
	return _equal_0(a.size, 0u);
}
/* join<char> arr<char>(a arr<arr<char>>, joiner arr<char>) */
struct arr_0 join(struct ctx* ctx, struct arr_1 a, struct arr_0 joiner) {
	uint8_t _0 = empty__q_1(a);
	if (_0) {
		return (struct arr_0) {0u, NULL};
	} else {
		uint8_t _1 = _equal_0(a.size, 1u);
		if (_1) {
			return subscript_0(ctx, a, 0u);
		} else {
			struct arr_0 _2 = subscript_0(ctx, a, 0u);
			struct arr_0 _3 = _concat_0(ctx, _2, joiner);
			struct arr_1 _4 = tail_0(ctx, a);
			struct arr_0 _5 = join(ctx, _4, joiner);
			return _concat_0(ctx, _3, _5);
		}
	}
}
/* empty?<arr<?t>> bool(a arr<arr<char>>) */
uint8_t empty__q_1(struct arr_1 a) {
	return _equal_0(a.size, 0u);
}
/* subscript<arr<?t>> arr<char>(a arr<arr<char>>, index nat) */
struct arr_0 subscript_0(struct ctx* ctx, struct arr_1 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	return noctx_at_0(a, index);
}
/* assert void(condition bool) */
struct void_ assert_0(struct ctx* ctx, uint8_t condition) {
	uint8_t _0 = not(condition);
	if (_0) {
		return fail_0(ctx, (struct arr_0) {13, constantarr_0_4});
	} else {
		return (struct void_) {};
	}
}
/* fail<void> void(reason arr<char>) */
struct void_ fail_0(struct ctx* ctx, struct arr_0 reason) {
	struct backtrace _0 = get_backtrace(ctx);
	return throw_0(ctx, (struct exception) {reason, _0});
}
/* throw<?t> void(e exception) */
struct void_ throw_0(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx0;
	exn_ctx0 = get_exception_ctx(ctx);
	
	uint8_t _0 = null__q_1(exn_ctx0->jmp_buf_ptr);
	hard_forbid(_0);
	exn_ctx0->thrown_exception = e;
	int32_t _1 = number_to_throw(ctx);
	(longjmp(exn_ctx0->jmp_buf_ptr, _1), (struct void_) {});
	return todo_0();
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
			fill_fun_ptrs_names_recur(ctx, 0u, arrs1->fun_ptrs, arrs1->fun_names);
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
	struct comparison _0 = compare_66(a, b);
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
struct comparison compare_66(int32_t a, int32_t b) {
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
	uint8_t _0 = _less_0(n, 18446744073709551615u);
	hard_assert(_0);
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
			uint8_t* _2 = incr_0(gc->mark_cur);
			gc->mark_cur = _2;
			uint64_t* _3 = incr_1(gc->data_cur);
			gc->data_cur = _3;
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
	uint8_t _0 = ptr_less_eq__q_0(gc->mark_begin, gc->mark_cur);
	hard_assert(_0);
	uint8_t _1 = ptr_less_eq__q_0(gc->mark_cur, gc->mark_end);
	hard_assert(_1);
	uint8_t _2 = ptr_less_eq__q_1(gc->data_begin, gc->data_cur);
	hard_assert(_2);
	uint8_t _3 = ptr_less_eq__q_1(gc->data_cur, gc->data_end);
	hard_assert(_3);
	uint64_t mark_idx0;
	mark_idx0 = _minus_1(gc->mark_cur, gc->mark_begin);
	
	uint64_t data_idx1;
	data_idx1 = _minus_0(gc->data_cur, gc->data_begin);
	
	uint64_t _4 = _minus_1(gc->mark_end, gc->mark_begin);
	uint8_t _5 = _equal_0(_4, gc->size_words);
	hard_assert(_5);
	uint64_t _6 = _minus_0(gc->data_end, gc->data_begin);
	uint8_t _7 = _equal_0(_6, gc->size_words);
	hard_assert(_7);
	uint8_t _8 = _equal_0(mark_idx0, data_idx1);
	return hard_assert(_8);
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
		uint8_t _1 = *mark;
		if (_1) {
			return 0;
		} else {
			uint8_t* _2 = incr_0(mark);
			mark = _2;
			end = end;
			goto top;
		}
	}
}
/* incr<nat> ptr<nat>(p ptr<nat>) */
uint64_t* incr_1(uint64_t* p) {
	return (p + 1u);
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
	return 851u;
}
/* code-ptrs-size nat() */
uint64_t code_ptrs_size(struct ctx* ctx) {
	return 8u;
}
/* fill-fun-ptrs-names-recur void(i nat, fun-ptrs ptr<ptr<nat8>>, fun-names ptr<arr<char>>) */
struct void_ fill_fun_ptrs_names_recur(struct ctx* ctx, uint64_t i, uint8_t** fun_ptrs, struct arr_0* fun_names) {
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
			return (uint8_t*) words_of_bytes;
		}
		case 2: {
			return (uint8_t*) round_up_to_multiple_of_8;
		}
		case 3: {
			return (uint8_t*) hard_assert;
		}
		case 4: {
			return (uint8_t*) not;
		}
		case 5: {
			return (uint8_t*) abort;
		}
		case 6: {
			return (uint8_t*) _equal_0;
		}
		case 7: {
			return (uint8_t*) compare_7;
		}
		case 8: {
			return (uint8_t*) _minus_0;
		}
		case 9: {
			return (uint8_t*) _less_0;
		}
		case 10: {
			return (uint8_t*) _lessOrEqual;
		}
		case 11: {
			return (uint8_t*) mark_range_recur;
		}
		case 12: {
			return (uint8_t*) incr_0;
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
			return (uint8_t*) join;
		}
		case 44: {
			return (uint8_t*) empty__q_1;
		}
		case 45: {
			return (uint8_t*) subscript_0;
		}
		case 46: {
			return (uint8_t*) assert_0;
		}
		case 47: {
			return (uint8_t*) fail_0;
		}
		case 48: {
			return (uint8_t*) throw_0;
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
			return (uint8_t*) get_backtrace;
		}
		case 54: {
			return (uint8_t*) try_alloc_backtrace_arrs;
		}
		case 55: {
			return (uint8_t*) try_alloc_uninitialized_0;
		}
		case 56: {
			return (uint8_t*) try_alloc;
		}
		case 57: {
			return (uint8_t*) try_gc_alloc;
		}
		case 58: {
			return (uint8_t*) acquire__e;
		}
		case 59: {
			return (uint8_t*) acquire_recur__e;
		}
		case 60: {
			return (uint8_t*) try_acquire__e;
		}
		case 61: {
			return (uint8_t*) try_set__e;
		}
		case 62: {
			return (uint8_t*) try_change__e;
		}
		case 63: {
			return (uint8_t*) yield_thread;
		}
		case 64: {
			return (uint8_t*) pthread_yield;
		}
		case 65: {
			return (uint8_t*) _equal_2;
		}
		case 66: {
			return (uint8_t*) compare_66;
		}
		case 67: {
			return (uint8_t*) noctx_incr;
		}
		case 68: {
			return (uint8_t*) try_gc_alloc_recur;
		}
		case 69: {
			return (uint8_t*) validate_gc;
		}
		case 70: {
			return (uint8_t*) ptr_less_eq__q_0;
		}
		case 71: {
			return (uint8_t*) ptr_less_eq__q_1;
		}
		case 72: {
			return (uint8_t*) _minus_1;
		}
		case 73: {
			return (uint8_t*) range_free__q;
		}
		case 74: {
			return (uint8_t*) incr_1;
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
			return (uint8_t*) incr_2;
		}
		case 100: {
			return (uint8_t*) incr_3;
		}
		case 101: {
			return (uint8_t*) noctx_at_0;
		}
		case 102: {
			return (uint8_t*) _concat_0;
		}
		case 103: {
			return (uint8_t*) _plus;
		}
		case 104: {
			return (uint8_t*) _greaterOrEqual;
		}
		case 105: {
			return (uint8_t*) alloc_uninitialized_0;
		}
		case 106: {
			return (uint8_t*) alloc;
		}
		case 107: {
			return (uint8_t*) gc_alloc;
		}
		case 108: {
			return (uint8_t*) todo_1;
		}
		case 109: {
			return (uint8_t*) copy_data_from_0;
		}
		case 110: {
			return (uint8_t*) memcpy;
		}
		case 111: {
			return (uint8_t*) tail_0;
		}
		case 112: {
			return (uint8_t*) forbid_0;
		}
		case 113: {
			return (uint8_t*) forbid_1;
		}
		case 114: {
			return (uint8_t*) subscript_3;
		}
		case 115: {
			return (uint8_t*) _minus_2;
		}
		case 116: {
			return (uint8_t*) _arrow_0;
		}
		case 117: {
			return (uint8_t*) get_global_ctx;
		}
		case 118: {
			return (uint8_t*) island__lambda0;
		}
		case 119: {
			return (uint8_t*) default_log_handler;
		}
		case 120: {
			return (uint8_t*) print;
		}
		case 121: {
			return (uint8_t*) print_no_newline;
		}
		case 122: {
			return (uint8_t*) stdout;
		}
		case 123: {
			return (uint8_t*) to_str_0;
		}
		case 124: {
			return (uint8_t*) island__lambda1;
		}
		case 125: {
			return (uint8_t*) gc;
		}
		case 126: {
			return (uint8_t*) thread_safe_counter_0;
		}
		case 127: {
			return (uint8_t*) thread_safe_counter_1;
		}
		case 128: {
			return (uint8_t*) do_main;
		}
		case 129: {
			return (uint8_t*) exception_ctx;
		}
		case 130: {
			return (uint8_t*) log_ctx;
		}
		case 131: {
			return (uint8_t*) ctx;
		}
		case 132: {
			return (uint8_t*) get_gc_ctx_1;
		}
		case 133: {
			return (uint8_t*) add_first_task;
		}
		case 134: {
			return (uint8_t*) then2;
		}
		case 135: {
			return (uint8_t*) then;
		}
		case 136: {
			return (uint8_t*) unresolved;
		}
		case 137: {
			return (uint8_t*) callback__e_0;
		}
		case 138: {
			return (uint8_t*) with_lock_0;
		}
		case 139: {
			return (uint8_t*) subscript_4;
		}
		case 140: {
			return (uint8_t*) call_w_ctx_140;
		}
		case 141: {
			return (uint8_t*) subscript_5;
		}
		case 142: {
			return (uint8_t*) call_w_ctx_142;
		}
		case 143: {
			return (uint8_t*) callback__e_0__lambda0;
		}
		case 144: {
			return (uint8_t*) forward_to__e;
		}
		case 145: {
			return (uint8_t*) callback__e_1;
		}
		case 146: {
			return (uint8_t*) subscript_6;
		}
		case 147: {
			return (uint8_t*) call_w_ctx_147;
		}
		case 148: {
			return (uint8_t*) callback__e_1__lambda0;
		}
		case 149: {
			return (uint8_t*) resolve_or_reject__e;
		}
		case 150: {
			return (uint8_t*) with_lock_1;
		}
		case 151: {
			return (uint8_t*) subscript_7;
		}
		case 152: {
			return (uint8_t*) call_w_ctx_152;
		}
		case 153: {
			return (uint8_t*) todo_2;
		}
		case 154: {
			return (uint8_t*) resolve_or_reject__e__lambda0;
		}
		case 155: {
			return (uint8_t*) call_callbacks__e;
		}
		case 156: {
			return (uint8_t*) drop_0;
		}
		case 157: {
			return (uint8_t*) forward_to__e__lambda0;
		}
		case 158: {
			return (uint8_t*) subscript_8;
		}
		case 159: {
			return (uint8_t*) get_island;
		}
		case 160: {
			return (uint8_t*) subscript_9;
		}
		case 161: {
			return (uint8_t*) noctx_at_1;
		}
		case 162: {
			return (uint8_t*) subscript_10;
		}
		case 163: {
			return (uint8_t*) add_task_0;
		}
		case 164: {
			return (uint8_t*) add_task_1;
		}
		case 165: {
			return (uint8_t*) task_queue_node;
		}
		case 166: {
			return (uint8_t*) insert_task__e;
		}
		case 167: {
			return (uint8_t*) size_0;
		}
		case 168: {
			return (uint8_t*) size_recur;
		}
		case 169: {
			return (uint8_t*) insert_recur;
		}
		case 170: {
			return (uint8_t*) tasks;
		}
		case 171: {
			return (uint8_t*) broadcast__e;
		}
		case 172: {
			return (uint8_t*) no_timestamp;
		}
		case 173: {
			return (uint8_t*) catch;
		}
		case 174: {
			return (uint8_t*) catch_with_exception_ctx;
		}
		case 175: {
			return (uint8_t*) zero_0;
		}
		case 176: {
			return (uint8_t*) zero_1;
		}
		case 177: {
			return (uint8_t*) zero_2;
		}
		case 178: {
			return (uint8_t*) zero_3;
		}
		case 179: {
			return (uint8_t*) setjmp;
		}
		case 180: {
			return (uint8_t*) subscript_11;
		}
		case 181: {
			return (uint8_t*) call_w_ctx_181;
		}
		case 182: {
			return (uint8_t*) subscript_12;
		}
		case 183: {
			return (uint8_t*) call_w_ctx_183;
		}
		case 184: {
			return (uint8_t*) subscript_8__lambda0__lambda0;
		}
		case 185: {
			return (uint8_t*) reject__e;
		}
		case 186: {
			return (uint8_t*) subscript_8__lambda0__lambda1;
		}
		case 187: {
			return (uint8_t*) subscript_8__lambda0;
		}
		case 188: {
			return (uint8_t*) then__lambda0;
		}
		case 189: {
			return (uint8_t*) subscript_13;
		}
		case 190: {
			return (uint8_t*) subscript_14;
		}
		case 191: {
			return (uint8_t*) call_w_ctx_191;
		}
		case 192: {
			return (uint8_t*) subscript_13__lambda0__lambda0;
		}
		case 193: {
			return (uint8_t*) subscript_13__lambda0__lambda1;
		}
		case 194: {
			return (uint8_t*) subscript_13__lambda0;
		}
		case 195: {
			return (uint8_t*) then2__lambda0;
		}
		case 196: {
			return (uint8_t*) cur_island_and_exclusion;
		}
		case 197: {
			return (uint8_t*) delay;
		}
		case 198: {
			return (uint8_t*) resolved_0;
		}
		case 199: {
			return (uint8_t*) tail_1;
		}
		case 200: {
			return (uint8_t*) empty__q_2;
		}
		case 201: {
			return (uint8_t*) subscript_15;
		}
		case 202: {
			return (uint8_t*) map_0;
		}
		case 203: {
			return (uint8_t*) make_arr_0;
		}
		case 204: {
			return (uint8_t*) alloc_uninitialized_1;
		}
		case 205: {
			return (uint8_t*) fill_ptr_range_0;
		}
		case 206: {
			return (uint8_t*) fill_ptr_range_recur_0;
		}
		case 207: {
			return (uint8_t*) subscript_16;
		}
		case 208: {
			return (uint8_t*) call_w_ctx_208;
		}
		case 209: {
			return (uint8_t*) subscript_17;
		}
		case 210: {
			return (uint8_t*) call_w_ctx_210;
		}
		case 211: {
			return (uint8_t*) subscript_18;
		}
		case 212: {
			return (uint8_t*) noctx_at_2;
		}
		case 213: {
			return (uint8_t*) subscript_19;
		}
		case 214: {
			return (uint8_t*) map_0__lambda0;
		}
		case 215: {
			return (uint8_t*) to_str_1;
		}
		case 216: {
			return (uint8_t*) arr_from_begin_end;
		}
		case 217: {
			return (uint8_t*) _minus_3;
		}
		case 218: {
			return (uint8_t*) find_cstr_end;
		}
		case 219: {
			return (uint8_t*) find_char_in_cstr;
		}
		case 220: {
			return (uint8_t*) _equal_3;
		}
		case 221: {
			return (uint8_t*) compare_221;
		}
		case 222: {
			return (uint8_t*) todo_3;
		}
		case 223: {
			return (uint8_t*) incr_4;
		}
		case 224: {
			return (uint8_t*) add_first_task__lambda0__lambda0;
		}
		case 225: {
			return (uint8_t*) add_first_task__lambda0;
		}
		case 226: {
			return (uint8_t*) handle_exceptions;
		}
		case 227: {
			return (uint8_t*) subscript_20;
		}
		case 228: {
			return (uint8_t*) call_w_ctx_228;
		}
		case 229: {
			return (uint8_t*) exception_handler;
		}
		case 230: {
			return (uint8_t*) get_cur_island;
		}
		case 231: {
			return (uint8_t*) handle_exceptions__lambda0;
		}
		case 232: {
			return (uint8_t*) do_main__lambda0;
		}
		case 233: {
			return (uint8_t*) call_w_ctx_233;
		}
		case 234: {
			return (uint8_t*) run_threads;
		}
		case 235: {
			return (uint8_t*) unmanaged_alloc_elements_1;
		}
		case 236: {
			return (uint8_t*) start_threads_recur;
		}
		case 237: {
			return (uint8_t*) create_one_thread;
		}
		case 238: {
			return (uint8_t*) pthread_create;
		}
		case 239: {
			return (uint8_t*) _notEqual_2;
		}
		case 240: {
			return (uint8_t*) eagain;
		}
		case 241: {
			return (uint8_t*) as_cell;
		}
		case 242: {
			return (uint8_t*) thread_fun;
		}
		case 243: {
			return (uint8_t*) thread_function;
		}
		case 244: {
			return (uint8_t*) thread_function_recur;
		}
		case 245: {
			return (uint8_t*) assert_islands_are_shut_down;
		}
		case 246: {
			return (uint8_t*) empty__q_3;
		}
		case 247: {
			return (uint8_t*) has__q_0;
		}
		case 248: {
			return (uint8_t*) empty__q_4;
		}
		case 249: {
			return (uint8_t*) get_last_checked;
		}
		case 250: {
			return (uint8_t*) choose_task;
		}
		case 251: {
			return (uint8_t*) get_monotime_nsec;
		}
		case 252: {
			return (uint8_t*) clock_gettime;
		}
		case 253: {
			return (uint8_t*) clock_monotonic;
		}
		case 254: {
			return (uint8_t*) todo_4;
		}
		case 255: {
			return (uint8_t*) choose_task_recur;
		}
		case 256: {
			return (uint8_t*) choose_task_in_island;
		}
		case 257: {
			return (uint8_t*) pop_task__e;
		}
		case 258: {
			return (uint8_t*) contains__q_0;
		}
		case 259: {
			return (uint8_t*) contains__q_1;
		}
		case 260: {
			return (uint8_t*) contains_recur__q_0;
		}
		case 261: {
			return (uint8_t*) noctx_at_3;
		}
		case 262: {
			return (uint8_t*) subscript_21;
		}
		case 263: {
			return (uint8_t*) temp_as_arr_0;
		}
		case 264: {
			return (uint8_t*) temp_as_arr_1;
		}
		case 265: {
			return (uint8_t*) temp_as_mut_arr;
		}
		case 266: {
			return (uint8_t*) data_0;
		}
		case 267: {
			return (uint8_t*) data_1;
		}
		case 268: {
			return (uint8_t*) pop_recur__e;
		}
		case 269: {
			return (uint8_t*) to_opt_time;
		}
		case 270: {
			return (uint8_t*) push_capacity_must_be_sufficient__e;
		}
		case 271: {
			return (uint8_t*) capacity_0;
		}
		case 272: {
			return (uint8_t*) size_1;
		}
		case 273: {
			return (uint8_t*) noctx_set_at__e_0;
		}
		case 274: {
			return (uint8_t*) set_subscript_2;
		}
		case 275: {
			return (uint8_t*) is_no_task__q;
		}
		case 276: {
			return (uint8_t*) min_time;
		}
		case 277: {
			return (uint8_t*) min;
		}
		case 278: {
			return (uint8_t*) do_task;
		}
		case 279: {
			return (uint8_t*) return_task__e;
		}
		case 280: {
			return (uint8_t*) noctx_must_remove_unordered__e;
		}
		case 281: {
			return (uint8_t*) noctx_must_remove_unordered_recur__e;
		}
		case 282: {
			return (uint8_t*) noctx_at_4;
		}
		case 283: {
			return (uint8_t*) drop_1;
		}
		case 284: {
			return (uint8_t*) noctx_remove_unordered_at__e;
		}
		case 285: {
			return (uint8_t*) noctx_last;
		}
		case 286: {
			return (uint8_t*) empty__q_5;
		}
		case 287: {
			return (uint8_t*) return_ctx;
		}
		case 288: {
			return (uint8_t*) return_gc_ctx;
		}
		case 289: {
			return (uint8_t*) run_garbage_collection;
		}
		case 290: {
			return (uint8_t*) mark_visit_290;
		}
		case 291: {
			return (uint8_t*) mark_visit_291;
		}
		case 292: {
			return (uint8_t*) mark_visit_292;
		}
		case 293: {
			return (uint8_t*) mark_visit_293;
		}
		case 294: {
			return (uint8_t*) mark_visit_294;
		}
		case 295: {
			return (uint8_t*) mark_visit_295;
		}
		case 296: {
			return (uint8_t*) mark_visit_296;
		}
		case 297: {
			return (uint8_t*) mark_visit_297;
		}
		case 298: {
			return (uint8_t*) mark_visit_298;
		}
		case 299: {
			return (uint8_t*) mark_visit_299;
		}
		case 300: {
			return (uint8_t*) mark_visit_300;
		}
		case 301: {
			return (uint8_t*) mark_visit_301;
		}
		case 302: {
			return (uint8_t*) mark_visit_302;
		}
		case 303: {
			return (uint8_t*) mark_visit_303;
		}
		case 304: {
			return (uint8_t*) mark_visit_304;
		}
		case 305: {
			return (uint8_t*) mark_visit_305;
		}
		case 306: {
			return (uint8_t*) mark_visit_306;
		}
		case 307: {
			return (uint8_t*) mark_visit_307;
		}
		case 308: {
			return (uint8_t*) mark_visit_308;
		}
		case 309: {
			return (uint8_t*) mark_visit_309;
		}
		case 310: {
			return (uint8_t*) mark_visit_310;
		}
		case 311: {
			return (uint8_t*) mark_visit_311;
		}
		case 312: {
			return (uint8_t*) mark_arr_312;
		}
		case 313: {
			return (uint8_t*) mark_visit_313;
		}
		case 314: {
			return (uint8_t*) mark_visit_314;
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
			return (uint8_t*) mark_arr_327;
		}
		case 328: {
			return (uint8_t*) mark_visit_328;
		}
		case 329: {
			return (uint8_t*) mark_elems_329;
		}
		case 330: {
			return (uint8_t*) mark_arr_330;
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
			return (uint8_t*) mark_visit_334;
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
			return (uint8_t*) clear_free_mem;
		}
		case 350: {
			return (uint8_t*) wait_on;
		}
		case 351: {
			return (uint8_t*) before_time__q;
		}
		case 352: {
			return (uint8_t*) join_threads_recur;
		}
		case 353: {
			return (uint8_t*) join_one_thread;
		}
		case 354: {
			return (uint8_t*) pthread_join;
		}
		case 355: {
			return (uint8_t*) einval;
		}
		case 356: {
			return (uint8_t*) esrch;
		}
		case 357: {
			return (uint8_t*) unmanaged_free_0;
		}
		case 358: {
			return (uint8_t*) free;
		}
		case 359: {
			return (uint8_t*) unmanaged_free_1;
		}
		case 360: {
			return (uint8_t*) main_0;
		}
		case 361: {
			return (uint8_t*) parse_cmd_line_args;
		}
		case 362: {
			return (uint8_t*) parse_cmd_line_args_dynamic;
		}
		case 363: {
			return (uint8_t*) find_index;
		}
		case 364: {
			return (uint8_t*) find_index_recur;
		}
		case 365: {
			return (uint8_t*) subscript_22;
		}
		case 366: {
			return (uint8_t*) call_w_ctx_366;
		}
		case 367: {
			return (uint8_t*) incr_5;
		}
		case 368: {
			return (uint8_t*) max_nat;
		}
		case 369: {
			return (uint8_t*) starts_with__q;
		}
		case 370: {
			return (uint8_t*) arr_eq__q;
		}
		case 371: {
			return (uint8_t*) _notEqual_3;
		}
		case 372: {
			return (uint8_t*) subscript_23;
		}
		case 373: {
			return (uint8_t*) noctx_at_5;
		}
		case 374: {
			return (uint8_t*) subscript_24;
		}
		case 375: {
			return (uint8_t*) subscript_25;
		}
		case 376: {
			return (uint8_t*) parse_cmd_line_args_dynamic__lambda0;
		}
		case 377: {
			return (uint8_t*) dict_0;
		}
		case 378: {
			return (uint8_t*) map_1;
		}
		case 379: {
			return (uint8_t*) subscript_26;
		}
		case 380: {
			return (uint8_t*) call_w_ctx_380;
		}
		case 381: {
			return (uint8_t*) subscript_27;
		}
		case 382: {
			return (uint8_t*) noctx_at_6;
		}
		case 383: {
			return (uint8_t*) subscript_28;
		}
		case 384: {
			return (uint8_t*) map_1__lambda0;
		}
		case 385: {
			return (uint8_t*) dict_0__lambda0;
		}
		case 386: {
			return (uint8_t*) map_2;
		}
		case 387: {
			return (uint8_t*) make_arr_1;
		}
		case 388: {
			return (uint8_t*) alloc_uninitialized_2;
		}
		case 389: {
			return (uint8_t*) fill_ptr_range_1;
		}
		case 390: {
			return (uint8_t*) fill_ptr_range_recur_1;
		}
		case 391: {
			return (uint8_t*) set_subscript_3;
		}
		case 392: {
			return (uint8_t*) subscript_29;
		}
		case 393: {
			return (uint8_t*) call_w_ctx_393;
		}
		case 394: {
			return (uint8_t*) subscript_30;
		}
		case 395: {
			return (uint8_t*) call_w_ctx_395;
		}
		case 396: {
			return (uint8_t*) map_2__lambda0;
		}
		case 397: {
			return (uint8_t*) dict_0__lambda1;
		}
		case 398: {
			return (uint8_t*) dict_1;
		}
		case 399: {
			return (uint8_t*) sort_by_first_0;
		}
		case 400: {
			return (uint8_t*) mut_arr_1;
		}
		case 401: {
			return (uint8_t*) make_mut_arr_0;
		}
		case 402: {
			return (uint8_t*) uninitialized_mut_arr_0;
		}
		case 403: {
			return (uint8_t*) mut_arr_2;
		}
		case 404: {
			return (uint8_t*) data_2;
		}
		case 405: {
			return (uint8_t*) mut_arr_1__lambda0;
		}
		case 406: {
			return (uint8_t*) mut_arr_3;
		}
		case 407: {
			return (uint8_t*) make_mut_arr_1;
		}
		case 408: {
			return (uint8_t*) uninitialized_mut_arr_1;
		}
		case 409: {
			return (uint8_t*) mut_arr_4;
		}
		case 410: {
			return (uint8_t*) data_3;
		}
		case 411: {
			return (uint8_t*) subscript_31;
		}
		case 412: {
			return (uint8_t*) noctx_at_7;
		}
		case 413: {
			return (uint8_t*) subscript_32;
		}
		case 414: {
			return (uint8_t*) mut_arr_3__lambda0;
		}
		case 415: {
			return (uint8_t*) sort_by_first__e_0;
		}
		case 416: {
			return (uint8_t*) size_2;
		}
		case 417: {
			return (uint8_t*) size_3;
		}
		case 418: {
			return (uint8_t*) swap_2;
		}
		case 419: {
			return (uint8_t*) subscript_33;
		}
		case 420: {
			return (uint8_t*) set_subscript_4;
		}
		case 421: {
			return (uint8_t*) noctx_set_at_0;
		}
		case 422: {
			return (uint8_t*) _divide;
		}
		case 423: {
			return (uint8_t*) partition_by_first__e_0;
		}
		case 424: {
			return (uint8_t*) _less_1;
		}
		case 425: {
			return (uint8_t*) compare_425;
		}
		case 426: {
			return (uint8_t*) swap_3;
		}
		case 427: {
			return (uint8_t*) subscript_34;
		}
		case 428: {
			return (uint8_t*) set_subscript_5;
		}
		case 429: {
			return (uint8_t*) noctx_set_at_1;
		}
		case 430: {
			return (uint8_t*) subscript_35;
		}
		case 431: {
			return (uint8_t*) subscript_36;
		}
		case 432: {
			return (uint8_t*) subscript_37;
		}
		case 433: {
			return (uint8_t*) cast_immutable_0;
		}
		case 434: {
			return (uint8_t*) cast_immutable_1;
		}
		case 435: {
			return (uint8_t*) _equal_4;
		}
		case 436: {
			return (uint8_t*) parse_cmd_line_args_dynamic__lambda1;
		}
		case 437: {
			return (uint8_t*) parse_named_args;
		}
		case 438: {
			return (uint8_t*) mut_dict_0;
		}
		case 439: {
			return (uint8_t*) mut_list_0;
		}
		case 440: {
			return (uint8_t*) mut_arr_5;
		}
		case 441: {
			return (uint8_t*) mut_list_1;
		}
		case 442: {
			return (uint8_t*) mut_arr_6;
		}
		case 443: {
			return (uint8_t*) parse_named_args_recur;
		}
		case 444: {
			return (uint8_t*) remove_start;
		}
		case 445: {
			return (uint8_t*) force_0;
		}
		case 446: {
			return (uint8_t*) fail_1;
		}
		case 447: {
			return (uint8_t*) throw_1;
		}
		case 448: {
			return (uint8_t*) todo_5;
		}
		case 449: {
			return (uint8_t*) try_remove_start;
		}
		case 450: {
			return (uint8_t*) first_0;
		}
		case 451: {
			return (uint8_t*) parse_named_args_recur__lambda0;
		}
		case 452: {
			return (uint8_t*) set_subscript_6;
		}
		case 453: {
			return (uint8_t*) set_subscript_recur_0;
		}
		case 454: {
			return (uint8_t*) _concatEquals_0;
		}
		case 455: {
			return (uint8_t*) incr_capacity__e_0;
		}
		case 456: {
			return (uint8_t*) ensure_capacity_0;
		}
		case 457: {
			return (uint8_t*) capacity_1;
		}
		case 458: {
			return (uint8_t*) increase_capacity_to__e_0;
		}
		case 459: {
			return (uint8_t*) data_4;
		}
		case 460: {
			return (uint8_t*) copy_data_from_1;
		}
		case 461: {
			return (uint8_t*) set_zero_elements_0;
		}
		case 462: {
			return (uint8_t*) set_zero_range_1;
		}
		case 463: {
			return (uint8_t*) round_up_to_power_of_two;
		}
		case 464: {
			return (uint8_t*) round_up_to_power_of_two_recur;
		}
		case 465: {
			return (uint8_t*) _times_0;
		}
		case 466: {
			return (uint8_t*) _concatEquals_1;
		}
		case 467: {
			return (uint8_t*) incr_capacity__e_1;
		}
		case 468: {
			return (uint8_t*) ensure_capacity_1;
		}
		case 469: {
			return (uint8_t*) capacity_2;
		}
		case 470: {
			return (uint8_t*) increase_capacity_to__e_1;
		}
		case 471: {
			return (uint8_t*) data_5;
		}
		case 472: {
			return (uint8_t*) copy_data_from_2;
		}
		case 473: {
			return (uint8_t*) set_zero_elements_1;
		}
		case 474: {
			return (uint8_t*) set_zero_range_2;
		}
		case 475: {
			return (uint8_t*) subscript_38;
		}
		case 476: {
			return (uint8_t*) noctx_at_8;
		}
		case 477: {
			return (uint8_t*) insert_at__e_0;
		}
		case 478: {
			return (uint8_t*) memmove;
		}
		case 479: {
			return (uint8_t*) set_subscript_7;
		}
		case 480: {
			return (uint8_t*) noctx_set_at__e_1;
		}
		case 481: {
			return (uint8_t*) insert_at__e_1;
		}
		case 482: {
			return (uint8_t*) set_subscript_8;
		}
		case 483: {
			return (uint8_t*) noctx_set_at__e_2;
		}
		case 484: {
			return (uint8_t*) move_to_dict__e_0;
		}
		case 485: {
			return (uint8_t*) move_to_arr__e_0;
		}
		case 486: {
			return (uint8_t*) move_to_arr__e_1;
		}
		case 487: {
			return (uint8_t*) assert_1;
		}
		case 488: {
			return (uint8_t*) fill_mut_list;
		}
		case 489: {
			return (uint8_t*) fill_mut_arr;
		}
		case 490: {
			return (uint8_t*) make_mut_arr_2;
		}
		case 491: {
			return (uint8_t*) uninitialized_mut_arr_2;
		}
		case 492: {
			return (uint8_t*) mut_arr_7;
		}
		case 493: {
			return (uint8_t*) alloc_uninitialized_3;
		}
		case 494: {
			return (uint8_t*) fill_ptr_range_2;
		}
		case 495: {
			return (uint8_t*) fill_ptr_range_recur_2;
		}
		case 496: {
			return (uint8_t*) set_subscript_9;
		}
		case 497: {
			return (uint8_t*) subscript_39;
		}
		case 498: {
			return (uint8_t*) call_w_ctx_498;
		}
		case 499: {
			return (uint8_t*) data_6;
		}
		case 500: {
			return (uint8_t*) fill_mut_arr__lambda0;
		}
		case 501: {
			return (uint8_t*) each_0;
		}
		case 502: {
			return (uint8_t*) empty__q_6;
		}
		case 503: {
			return (uint8_t*) subscript_40;
		}
		case 504: {
			return (uint8_t*) call_w_ctx_504;
		}
		case 505: {
			return (uint8_t*) first_1;
		}
		case 506: {
			return (uint8_t*) empty__q_7;
		}
		case 507: {
			return (uint8_t*) tail_2;
		}
		case 508: {
			return (uint8_t*) index_of;
		}
		case 509: {
			return (uint8_t*) index_of__lambda0;
		}
		case 510: {
			return (uint8_t*) has__q_1;
		}
		case 511: {
			return (uint8_t*) empty__q_8;
		}
		case 512: {
			return (uint8_t*) subscript_41;
		}
		case 513: {
			return (uint8_t*) noctx_at_9;
		}
		case 514: {
			return (uint8_t*) subscript_42;
		}
		case 515: {
			return (uint8_t*) data_7;
		}
		case 516: {
			return (uint8_t*) set_subscript_10;
		}
		case 517: {
			return (uint8_t*) noctx_set_at__e_3;
		}
		case 518: {
			return (uint8_t*) parse_cmd_line_args__lambda0;
		}
		case 519: {
			return (uint8_t*) subscript_43;
		}
		case 520: {
			return (uint8_t*) call_w_ctx_520;
		}
		case 521: {
			return (uint8_t*) move_to_arr__e_2;
		}
		case 522: {
			return (uint8_t*) mut_arr_8;
		}
		case 523: {
			return (uint8_t*) subscript_44;
		}
		case 524: {
			return (uint8_t*) noctx_at_10;
		}
		case 525: {
			return (uint8_t*) force_1;
		}
		case 526: {
			return (uint8_t*) fail_2;
		}
		case 527: {
			return (uint8_t*) throw_2;
		}
		case 528: {
			return (uint8_t*) parse_nat;
		}
		case 529: {
			return (uint8_t*) parse_nat_recur;
		}
		case 530: {
			return (uint8_t*) char_to_nat;
		}
		case 531: {
			return (uint8_t*) first_2;
		}
		case 532: {
			return (uint8_t*) tail_3;
		}
		case 533: {
			return (uint8_t*) main_0__lambda0;
		}
		case 534: {
			return (uint8_t*) resolved_1;
		}
		case 535: {
			return (uint8_t*) print_help;
		}
		case 536: {
			return (uint8_t*) do_test;
		}
		case 537: {
			return (uint8_t*) parent_path;
		}
		case 538: {
			return (uint8_t*) r_index_of;
		}
		case 539: {
			return (uint8_t*) find_rindex;
		}
		case 540: {
			return (uint8_t*) find_rindex_recur;
		}
		case 541: {
			return (uint8_t*) subscript_45;
		}
		case 542: {
			return (uint8_t*) call_w_ctx_542;
		}
		case 543: {
			return (uint8_t*) decr;
		}
		case 544: {
			return (uint8_t*) r_index_of__lambda0;
		}
		case 545: {
			return (uint8_t*) current_executable_path;
		}
		case 546: {
			return (uint8_t*) read_link;
		}
		case 547: {
			return (uint8_t*) uninitialized_mut_arr_3;
		}
		case 548: {
			return (uint8_t*) mut_arr_9;
		}
		case 549: {
			return (uint8_t*) readlink;
		}
		case 550: {
			return (uint8_t*) to_c_str;
		}
		case 551: {
			return (uint8_t*) data_8;
		}
		case 552: {
			return (uint8_t*) size_4;
		}
		case 553: {
			return (uint8_t*) check_errno_if_neg_one;
		}
		case 554: {
			return (uint8_t*) check_posix_error;
		}
		case 555: {
			return NULL;
		}
		case 556: {
			return (uint8_t*) cast_immutable_2;
		}
		case 557: {
			return (uint8_t*) to_nat_0;
		}
		case 558: {
			return (uint8_t*) negative__q;
		}
		case 559: {
			return (uint8_t*) _less_2;
		}
		case 560: {
			return (uint8_t*) child_path;
		}
		case 561: {
			return (uint8_t*) get_environ;
		}
		case 562: {
			return (uint8_t*) mut_dict_1;
		}
		case 563: {
			return (uint8_t*) get_environ_recur;
		}
		case 564: {
			return (uint8_t*) null__q_2;
		}
		case 565: {
			return (uint8_t*) parse_environ_entry;
		}
		case 566: {
			return (uint8_t*) _arrow_1;
		}
		case 567: {
			return (uint8_t*) set_subscript_11;
		}
		case 568: {
			return (uint8_t*) set_subscript_recur_1;
		}
		case 569: {
			return (uint8_t*) incr_6;
		}
		case 570: {
			return NULL;
		}
		case 571: {
			return (uint8_t*) move_to_dict__e_1;
		}
		case 572: {
			return (uint8_t*) dict_2;
		}
		case 573: {
			return (uint8_t*) sort_by_first_1;
		}
		case 574: {
			return (uint8_t*) sort_by_first__e_1;
		}
		case 575: {
			return (uint8_t*) partition_by_first__e_1;
		}
		case 576: {
			return (uint8_t*) first_failures;
		}
		case 577: {
			return (uint8_t*) subscript_46;
		}
		case 578: {
			return (uint8_t*) call_w_ctx_578;
		}
		case 579: {
			return (uint8_t*) run_crow_tests;
		}
		case 580: {
			return (uint8_t*) list_tests;
		}
		case 581: {
			return (uint8_t*) list_tests__lambda0;
		}
		case 582: {
			return (uint8_t*) each_child_recursive;
		}
		case 583: {
			return (uint8_t*) is_dir__q_0;
		}
		case 584: {
			return (uint8_t*) is_dir__q_1;
		}
		case 585: {
			return (uint8_t*) get_stat;
		}
		case 586: {
			return (uint8_t*) empty_stat;
		}
		case 587: {
			return (uint8_t*) stat;
		}
		case 588: {
			return (uint8_t*) enoent;
		}
		case 589: {
			return (uint8_t*) todo_6;
		}
		case 590: {
			return (uint8_t*) todo_7;
		}
		case 591: {
			return (uint8_t*) _equal_5;
		}
		case 592: {
			return (uint8_t*) compare_592;
		}
		case 593: {
			return (uint8_t*) s_ifmt;
		}
		case 594: {
			return (uint8_t*) s_ifdir;
		}
		case 595: {
			return (uint8_t*) each_1;
		}
		case 596: {
			return (uint8_t*) subscript_47;
		}
		case 597: {
			return (uint8_t*) call_w_ctx_597;
		}
		case 598: {
			return (uint8_t*) read_dir_0;
		}
		case 599: {
			return (uint8_t*) read_dir_1;
		}
		case 600: {
			return (uint8_t*) opendir;
		}
		case 601: {
			return (uint8_t*) null__q_3;
		}
		case 602: {
			return (uint8_t*) read_dir_recur;
		}
		case 603: {
			return (uint8_t*) zero_4;
		}
		case 604: {
			return (uint8_t*) readdir_r;
		}
		case 605: {
			return (uint8_t*) ref_eq__q;
		}
		case 606: {
			return (uint8_t*) get_dirent_name;
		}
		case 607: {
			return (uint8_t*) _notEqual_4;
		}
		case 608: {
			return (uint8_t*) sort;
		}
		case 609: {
			return (uint8_t*) sort__e;
		}
		case 610: {
			return (uint8_t*) partition__e;
		}
		case 611: {
			return (uint8_t*) each_child_recursive__lambda0;
		}
		case 612: {
			return (uint8_t*) get_extension;
		}
		case 613: {
			return (uint8_t*) last_index_of;
		}
		case 614: {
			return (uint8_t*) last;
		}
		case 615: {
			return (uint8_t*) rtail;
		}
		case 616: {
			return (uint8_t*) base_name;
		}
		case 617: {
			return (uint8_t*) list_tests__lambda1;
		}
		case 618: {
			return (uint8_t*) flat_map_with_max_size;
		}
		case 619: {
			return (uint8_t*) mut_list_2;
		}
		case 620: {
			return (uint8_t*) mut_arr_10;
		}
		case 621: {
			return (uint8_t*) _concatEquals_2;
		}
		case 622: {
			return (uint8_t*) each_2;
		}
		case 623: {
			return (uint8_t*) empty__q_9;
		}
		case 624: {
			return (uint8_t*) subscript_48;
		}
		case 625: {
			return (uint8_t*) call_w_ctx_625;
		}
		case 626: {
			return (uint8_t*) first_3;
		}
		case 627: {
			return (uint8_t*) subscript_49;
		}
		case 628: {
			return (uint8_t*) noctx_at_11;
		}
		case 629: {
			return (uint8_t*) subscript_50;
		}
		case 630: {
			return (uint8_t*) tail_4;
		}
		case 631: {
			return (uint8_t*) subscript_51;
		}
		case 632: {
			return (uint8_t*) _concatEquals_3;
		}
		case 633: {
			return (uint8_t*) incr_capacity__e_2;
		}
		case 634: {
			return (uint8_t*) ensure_capacity_2;
		}
		case 635: {
			return (uint8_t*) capacity_3;
		}
		case 636: {
			return (uint8_t*) size_5;
		}
		case 637: {
			return (uint8_t*) increase_capacity_to__e_2;
		}
		case 638: {
			return (uint8_t*) data_9;
		}
		case 639: {
			return (uint8_t*) data_10;
		}
		case 640: {
			return (uint8_t*) mut_arr_11;
		}
		case 641: {
			return (uint8_t*) alloc_uninitialized_4;
		}
		case 642: {
			return (uint8_t*) copy_data_from_3;
		}
		case 643: {
			return (uint8_t*) set_zero_elements_2;
		}
		case 644: {
			return (uint8_t*) set_zero_range_3;
		}
		case 645: {
			return (uint8_t*) subscript_52;
		}
		case 646: {
			return (uint8_t*) set_subscript_12;
		}
		case 647: {
			return (uint8_t*) _concatEquals_2__lambda0;
		}
		case 648: {
			return (uint8_t*) subscript_53;
		}
		case 649: {
			return (uint8_t*) call_w_ctx_649;
		}
		case 650: {
			return (uint8_t*) reduce_size_if_more_than__e;
		}
		case 651: {
			return (uint8_t*) drop_2;
		}
		case 652: {
			return (uint8_t*) pop__e;
		}
		case 653: {
			return (uint8_t*) empty__q_10;
		}
		case 654: {
			return (uint8_t*) subscript_54;
		}
		case 655: {
			return (uint8_t*) noctx_at_12;
		}
		case 656: {
			return (uint8_t*) set_subscript_13;
		}
		case 657: {
			return (uint8_t*) noctx_set_at__e_4;
		}
		case 658: {
			return (uint8_t*) flat_map_with_max_size__lambda0;
		}
		case 659: {
			return (uint8_t*) move_to_arr__e_3;
		}
		case 660: {
			return (uint8_t*) run_single_crow_test;
		}
		case 661: {
			return (uint8_t*) first_some;
		}
		case 662: {
			return (uint8_t*) subscript_55;
		}
		case 663: {
			return (uint8_t*) call_w_ctx_663;
		}
		case 664: {
			return (uint8_t*) run_print_test;
		}
		case 665: {
			return (uint8_t*) spawn_and_wait_result_0;
		}
		case 666: {
			return (uint8_t*) fold;
		}
		case 667: {
			return (uint8_t*) subscript_56;
		}
		case 668: {
			return (uint8_t*) call_w_ctx_668;
		}
		case 669: {
			return (uint8_t*) spawn_and_wait_result_0__lambda0;
		}
		case 670: {
			return (uint8_t*) is_file__q_0;
		}
		case 671: {
			return (uint8_t*) is_file__q_1;
		}
		case 672: {
			return (uint8_t*) s_ifreg;
		}
		case 673: {
			return (uint8_t*) spawn_and_wait_result_1;
		}
		case 674: {
			return (uint8_t*) make_pipes;
		}
		case 675: {
			return (uint8_t*) pipe;
		}
		case 676: {
			return (uint8_t*) posix_spawn_file_actions_init;
		}
		case 677: {
			return (uint8_t*) posix_spawn_file_actions_addclose;
		}
		case 678: {
			return (uint8_t*) posix_spawn_file_actions_adddup2;
		}
		case 679: {
			return (uint8_t*) posix_spawn;
		}
		case 680: {
			return (uint8_t*) close;
		}
		case 681: {
			return (uint8_t*) mut_list_3;
		}
		case 682: {
			return (uint8_t*) mut_arr_12;
		}
		case 683: {
			return (uint8_t*) keep_polling;
		}
		case 684: {
			return (uint8_t*) pollin;
		}
		case 685: {
			return (uint8_t*) ref_of_val_at;
		}
		case 686: {
			return (uint8_t*) ref_of_ptr;
		}
		case 687: {
			return (uint8_t*) poll;
		}
		case 688: {
			return (uint8_t*) handle_revents;
		}
		case 689: {
			return (uint8_t*) has_pollin__q;
		}
		case 690: {
			return (uint8_t*) bits_intersect__q;
		}
		case 691: {
			return (uint8_t*) _equal_6;
		}
		case 692: {
			return (uint8_t*) compare_692;
		}
		case 693: {
			return (uint8_t*) read_to_buffer_until_eof;
		}
		case 694: {
			return (uint8_t*) reserve;
		}
		case 695: {
			return (uint8_t*) ensure_capacity_3;
		}
		case 696: {
			return (uint8_t*) capacity_4;
		}
		case 697: {
			return (uint8_t*) increase_capacity_to__e_3;
		}
		case 698: {
			return (uint8_t*) data_11;
		}
		case 699: {
			return (uint8_t*) set_zero_elements_3;
		}
		case 700: {
			return (uint8_t*) set_zero_range_4;
		}
		case 701: {
			return (uint8_t*) subscript_57;
		}
		case 702: {
			return (uint8_t*) read;
		}
		case 703: {
			return (uint8_t*) unsafe_increase_size__e;
		}
		case 704: {
			return (uint8_t*) unsafe_set_size__e;
		}
		case 705: {
			return (uint8_t*) has_pollhup__q;
		}
		case 706: {
			return (uint8_t*) pollhup;
		}
		case 707: {
			return (uint8_t*) has_pollpri__q;
		}
		case 708: {
			return (uint8_t*) pollpri;
		}
		case 709: {
			return (uint8_t*) has_pollout__q;
		}
		case 710: {
			return (uint8_t*) pollout;
		}
		case 711: {
			return (uint8_t*) has_pollerr__q;
		}
		case 712: {
			return (uint8_t*) pollerr;
		}
		case 713: {
			return (uint8_t*) has_pollnval__q;
		}
		case 714: {
			return (uint8_t*) pollnval;
		}
		case 715: {
			return (uint8_t*) to_nat_1;
		}
		case 716: {
			return (uint8_t*) any__q;
		}
		case 717: {
			return (uint8_t*) to_nat_2;
		}
		case 718: {
			return (uint8_t*) wait_and_get_exit_code;
		}
		case 719: {
			return (uint8_t*) waitpid;
		}
		case 720: {
			return (uint8_t*) w_if_exited;
		}
		case 721: {
			return (uint8_t*) w_term_sig;
		}
		case 722: {
			return (uint8_t*) w_exit_status;
		}
		case 723: {
			return (uint8_t*) bit_shift_right;
		}
		case 724: {
			return (uint8_t*) _less_3;
		}
		case 725: {
			return (uint8_t*) todo_8;
		}
		case 726: {
			return (uint8_t*) w_if_signaled;
		}
		case 727: {
			return (uint8_t*) to_str_2;
		}
		case 728: {
			return (uint8_t*) to_str_3;
		}
		case 729: {
			return (uint8_t*) to_str_4;
		}
		case 730: {
			return (uint8_t*) mod;
		}
		case 731: {
			return (uint8_t*) abs;
		}
		case 732: {
			return (uint8_t*) neg;
		}
		case 733: {
			return (uint8_t*) _times_1;
		}
		case 734: {
			return (uint8_t*) w_if_stopped;
		}
		case 735: {
			return (uint8_t*) w_if_continued;
		}
		case 736: {
			return (uint8_t*) move_to_arr__e_4;
		}
		case 737: {
			return (uint8_t*) convert_args;
		}
		case 738: {
			return (uint8_t*) _concat_1;
		}
		case 739: {
			return (uint8_t*) alloc_uninitialized_5;
		}
		case 740: {
			return (uint8_t*) copy_data_from_4;
		}
		case 741: {
			return (uint8_t*) map_3;
		}
		case 742: {
			return (uint8_t*) make_arr_2;
		}
		case 743: {
			return (uint8_t*) fill_ptr_range_3;
		}
		case 744: {
			return (uint8_t*) fill_ptr_range_recur_3;
		}
		case 745: {
			return (uint8_t*) set_subscript_14;
		}
		case 746: {
			return (uint8_t*) subscript_58;
		}
		case 747: {
			return (uint8_t*) call_w_ctx_747;
		}
		case 748: {
			return (uint8_t*) subscript_59;
		}
		case 749: {
			return (uint8_t*) call_w_ctx_749;
		}
		case 750: {
			return (uint8_t*) map_3__lambda0;
		}
		case 751: {
			return (uint8_t*) convert_args__lambda0;
		}
		case 752: {
			return (uint8_t*) convert_environ;
		}
		case 753: {
			return (uint8_t*) mut_list_4;
		}
		case 754: {
			return (uint8_t*) mut_arr_13;
		}
		case 755: {
			return (uint8_t*) each_3;
		}
		case 756: {
			return (uint8_t*) empty__q_11;
		}
		case 757: {
			return (uint8_t*) subscript_60;
		}
		case 758: {
			return (uint8_t*) call_w_ctx_758;
		}
		case 759: {
			return (uint8_t*) _concatEquals_4;
		}
		case 760: {
			return (uint8_t*) incr_capacity__e_3;
		}
		case 761: {
			return (uint8_t*) ensure_capacity_4;
		}
		case 762: {
			return (uint8_t*) capacity_5;
		}
		case 763: {
			return (uint8_t*) size_6;
		}
		case 764: {
			return (uint8_t*) increase_capacity_to__e_4;
		}
		case 765: {
			return (uint8_t*) data_12;
		}
		case 766: {
			return (uint8_t*) data_13;
		}
		case 767: {
			return (uint8_t*) mut_arr_14;
		}
		case 768: {
			return (uint8_t*) set_zero_elements_4;
		}
		case 769: {
			return (uint8_t*) set_zero_range_5;
		}
		case 770: {
			return (uint8_t*) subscript_61;
		}
		case 771: {
			return (uint8_t*) convert_environ__lambda0;
		}
		case 772: {
			return (uint8_t*) move_to_arr__e_5;
		}
		case 773: {
			return (uint8_t*) fail_3;
		}
		case 774: {
			return (uint8_t*) throw_3;
		}
		case 775: {
			return (uint8_t*) todo_9;
		}
		case 776: {
			return (uint8_t*) handle_output;
		}
		case 777: {
			return (uint8_t*) try_read_file_0;
		}
		case 778: {
			return (uint8_t*) try_read_file_1;
		}
		case 779: {
			return (uint8_t*) open;
		}
		case 780: {
			return (uint8_t*) o_rdonly;
		}
		case 781: {
			return (uint8_t*) todo_10;
		}
		case 782: {
			return (uint8_t*) lseek;
		}
		case 783: {
			return (uint8_t*) seek_end;
		}
		case 784: {
			return (uint8_t*) seek_set;
		}
		case 785: {
			return (uint8_t*) write_file_0;
		}
		case 786: {
			return (uint8_t*) write_file_1;
		}
		case 787: {
			return (uint8_t*) bit_shift_left;
		}
		case 788: {
			return (uint8_t*) _less_4;
		}
		case 789: {
			return (uint8_t*) o_creat;
		}
		case 790: {
			return (uint8_t*) o_wronly;
		}
		case 791: {
			return (uint8_t*) o_trunc;
		}
		case 792: {
			return (uint8_t*) to_str_5;
		}
		case 793: {
			return (uint8_t*) to_int;
		}
		case 794: {
			return (uint8_t*) max_int;
		}
		case 795: {
			return (uint8_t*) remove_colors;
		}
		case 796: {
			return (uint8_t*) remove_colors_recur;
		}
		case 797: {
			return (uint8_t*) remove_colors_recur_2;
		}
		case 798: {
			return (uint8_t*) _concatEquals_5;
		}
		case 799: {
			return (uint8_t*) incr_capacity__e_4;
		}
		case 800: {
			return (uint8_t*) set_subscript_15;
		}
		case 801: {
			return (uint8_t*) run_single_crow_test__lambda0;
		}
		case 802: {
			return (uint8_t*) run_single_runnable_test;
		}
		case 803: {
			return (uint8_t*) _concat_2;
		}
		case 804: {
			return (uint8_t*) run_crow_tests__lambda0;
		}
		case 805: {
			return (uint8_t*) has__q_2;
		}
		case 806: {
			return (uint8_t*) do_test__lambda0__lambda0;
		}
		case 807: {
			return (uint8_t*) do_test__lambda0;
		}
		case 808: {
			return (uint8_t*) lint;
		}
		case 809: {
			return (uint8_t*) list_lintable_files;
		}
		case 810: {
			return (uint8_t*) excluded_from_lint__q;
		}
		case 811: {
			return (uint8_t*) contains__q_2;
		}
		case 812: {
			return (uint8_t*) contains_recur__q_1;
		}
		case 813: {
			return (uint8_t*) exists__q;
		}
		case 814: {
			return (uint8_t*) ends_with__q;
		}
		case 815: {
			return (uint8_t*) excluded_from_lint__q__lambda0;
		}
		case 816: {
			return (uint8_t*) list_lintable_files__lambda0;
		}
		case 817: {
			return (uint8_t*) ignore_extension_of_name__q;
		}
		case 818: {
			return (uint8_t*) ignore_extension__q;
		}
		case 819: {
			return (uint8_t*) ignored_extensions;
		}
		case 820: {
			return (uint8_t*) list_lintable_files__lambda1;
		}
		case 821: {
			return (uint8_t*) lint_file;
		}
		case 822: {
			return (uint8_t*) read_file;
		}
		case 823: {
			return (uint8_t*) each_with_index_0;
		}
		case 824: {
			return (uint8_t*) each_with_index_recur_0;
		}
		case 825: {
			return (uint8_t*) subscript_62;
		}
		case 826: {
			return (uint8_t*) call_w_ctx_826;
		}
		case 827: {
			return (uint8_t*) lines;
		}
		case 828: {
			return (uint8_t*) each_with_index_1;
		}
		case 829: {
			return (uint8_t*) each_with_index_recur_1;
		}
		case 830: {
			return (uint8_t*) subscript_63;
		}
		case 831: {
			return (uint8_t*) call_w_ctx_831;
		}
		case 832: {
			return (uint8_t*) swap_4;
		}
		case 833: {
			return (uint8_t*) lines__lambda0;
		}
		case 834: {
			return (uint8_t*) contains_subseq__q;
		}
		case 835: {
			return (uint8_t*) has__q_3;
		}
		case 836: {
			return (uint8_t*) empty__q_12;
		}
		case 837: {
			return (uint8_t*) index_of_subseq;
		}
		case 838: {
			return (uint8_t*) index_of_subseq_recur;
		}
		case 839: {
			return (uint8_t*) line_len;
		}
		case 840: {
			return (uint8_t*) n_tabs;
		}
		case 841: {
			return (uint8_t*) tab_size;
		}
		case 842: {
			return (uint8_t*) max_line_length;
		}
		case 843: {
			return (uint8_t*) lint_file__lambda0;
		}
		case 844: {
			return (uint8_t*) lint__lambda0;
		}
		case 845: {
			return (uint8_t*) do_test__lambda1;
		}
		case 846: {
			return (uint8_t*) print_failures;
		}
		case 847: {
			return (uint8_t*) print_failure;
		}
		case 848: {
			return (uint8_t*) print_bold;
		}
		case 849: {
			return (uint8_t*) print_reset;
		}
		case 850: {
			return (uint8_t*) print_failures__lambda0;
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
			return (struct arr_0) {4, constantarr_0_100};
		}
		case 1: {
			return (struct arr_0) {14, constantarr_0_101};
		}
		case 2: {
			return (struct arr_0) {25, constantarr_0_103};
		}
		case 3: {
			return (struct arr_0) {11, constantarr_0_109};
		}
		case 4: {
			return (struct arr_0) {3, constantarr_0_110};
		}
		case 5: {
			return (struct arr_0) {6, constantarr_0_113};
		}
		case 6: {
			return (struct arr_0) {7, constantarr_0_114};
		}
		case 7: {
			return (struct arr_0) {0u, NULL};
		}
		case 8: {
			return (struct arr_0) {6, constantarr_0_117};
		}
		case 9: {
			return (struct arr_0) {6, constantarr_0_121};
		}
		case 10: {
			return (struct arr_0) {7, constantarr_0_123};
		}
		case 11: {
			return (struct arr_0) {16, constantarr_0_126};
		}
		case 12: {
			return (struct arr_0) {10, constantarr_0_131};
		}
		case 13: {
			return (struct arr_0) {6, constantarr_0_132};
		}
		case 14: {
			return (struct arr_0) {7, constantarr_0_133};
		}
		case 15: {
			return (struct arr_0) {10, constantarr_0_134};
		}
		case 16: {
			return (struct arr_0) {11, constantarr_0_137};
		}
		case 17: {
			return (struct arr_0) {11, constantarr_0_139};
		}
		case 18: {
			return (struct arr_0) {9, constantarr_0_140};
		}
		case 19: {
			return (struct arr_0) {6, constantarr_0_142};
		}
		case 20: {
			return (struct arr_0) {10, constantarr_0_143};
		}
		case 21: {
			return (struct arr_0) {56, constantarr_0_145};
		}
		case 22: {
			return (struct arr_0) {11, constantarr_0_146};
		}
		case 23: {
			return (struct arr_0) {35, constantarr_0_149};
		}
		case 24: {
			return (struct arr_0) {28, constantarr_0_150};
		}
		case 25: {
			return (struct arr_0) {21, constantarr_0_151};
		}
		case 26: {
			return (struct arr_0) {6, constantarr_0_152};
		}
		case 27: {
			return (struct arr_0) {11, constantarr_0_153};
		}
		case 28: {
			return (struct arr_0) {11, constantarr_0_154};
		}
		case 29: {
			return (struct arr_0) {18, constantarr_0_158};
		}
		case 30: {
			return (struct arr_0) {6, constantarr_0_159};
		}
		case 31: {
			return (struct arr_0) {25, constantarr_0_164};
		}
		case 32: {
			return (struct arr_0) {20, constantarr_0_165};
		}
		case 33: {
			return (struct arr_0) {16, constantarr_0_166};
		}
		case 34: {
			return (struct arr_0) {5, constantarr_0_169};
		}
		case 35: {
			return (struct arr_0) {7, constantarr_0_173};
		}
		case 36: {
			return (struct arr_0) {6, constantarr_0_174};
		}
		case 37: {
			return (struct arr_0) {0u, NULL};
		}
		case 38: {
			return (struct arr_0) {10, constantarr_0_176};
		}
		case 39: {
			return (struct arr_0) {6, constantarr_0_178};
		}
		case 40: {
			return (struct arr_0) {9, constantarr_0_179};
		}
		case 41: {
			return (struct arr_0) {14, constantarr_0_180};
		}
		case 42: {
			return (struct arr_0) {12, constantarr_0_182};
		}
		case 43: {
			return (struct arr_0) {10, constantarr_0_184};
		}
		case 44: {
			return (struct arr_0) {15, constantarr_0_185};
		}
		case 45: {
			return (struct arr_0) {18, constantarr_0_187};
		}
		case 46: {
			return (struct arr_0) {6, constantarr_0_188};
		}
		case 47: {
			return (struct arr_0) {10, constantarr_0_189};
		}
		case 48: {
			return (struct arr_0) {9, constantarr_0_190};
		}
		case 49: {
			return (struct arr_0) {17, constantarr_0_191};
		}
		case 50: {
			return (struct arr_0) {18, constantarr_0_195};
		}
		case 51: {
			return (struct arr_0) {7, constantarr_0_198};
		}
		case 52: {
			return (struct arr_0) {15, constantarr_0_199};
		}
		case 53: {
			return (struct arr_0) {13, constantarr_0_201};
		}
		case 54: {
			return (struct arr_0) {24, constantarr_0_202};
		}
		case 55: {
			return (struct arr_0) {34, constantarr_0_203};
		}
		case 56: {
			return (struct arr_0) {9, constantarr_0_204};
		}
		case 57: {
			return (struct arr_0) {12, constantarr_0_205};
		}
		case 58: {
			return (struct arr_0) {8, constantarr_0_206};
		}
		case 59: {
			return (struct arr_0) {14, constantarr_0_207};
		}
		case 60: {
			return (struct arr_0) {12, constantarr_0_208};
		}
		case 61: {
			return (struct arr_0) {8, constantarr_0_209};
		}
		case 62: {
			return (struct arr_0) {11, constantarr_0_210};
		}
		case 63: {
			return (struct arr_0) {12, constantarr_0_216};
		}
		case 64: {
			return (struct arr_0) {13, constantarr_0_217};
		}
		case 65: {
			return (struct arr_0) {9, constantarr_0_218};
		}
		case 66: {
			return (struct arr_0) {0u, NULL};
		}
		case 67: {
			return (struct arr_0) {10, constantarr_0_219};
		}
		case 68: {
			return (struct arr_0) {18, constantarr_0_222};
		}
		case 69: {
			return (struct arr_0) {11, constantarr_0_223};
		}
		case 70: {
			return (struct arr_0) {18, constantarr_0_224};
		}
		case 71: {
			return (struct arr_0) {17, constantarr_0_229};
		}
		case 72: {
			return (struct arr_0) {7, constantarr_0_234};
		}
		case 73: {
			return (struct arr_0) {11, constantarr_0_237};
		}
		case 74: {
			return (struct arr_0) {9, constantarr_0_242};
		}
		case 75: {
			return (struct arr_0) {8, constantarr_0_243};
		}
		case 76: {
			return (struct arr_0) {11, constantarr_0_244};
		}
		case 77: {
			return (struct arr_0) {10, constantarr_0_245};
		}
		case 78: {
			return (struct arr_0) {6, constantarr_0_246};
		}
		case 79: {
			return (struct arr_0) {10, constantarr_0_248};
		}
		case 80: {
			return (struct arr_0) {34, constantarr_0_254};
		}
		case 81: {
			return (struct arr_0) {0u, NULL};
		}
		case 82: {
			return (struct arr_0) {9, constantarr_0_260};
		}
		case 83: {
			return (struct arr_0) {14, constantarr_0_267};
		}
		case 84: {
			return (struct arr_0) {25, constantarr_0_268};
		}
		case 85: {
			return (struct arr_0) {7, constantarr_0_269};
		}
		case 86: {
			return (struct arr_0) {24, constantarr_0_270};
		}
		case 87: {
			return (struct arr_0) {0u, NULL};
		}
		case 88: {
			return (struct arr_0) {24, constantarr_0_274};
		}
		case 89: {
			return (struct arr_0) {0u, NULL};
		}
		case 90: {
			return (struct arr_0) {13, constantarr_0_278};
		}
		case 91: {
			return (struct arr_0) {15, constantarr_0_279};
		}
		case 92: {
			return (struct arr_0) {13, constantarr_0_280};
		}
		case 93: {
			return (struct arr_0) {15, constantarr_0_281};
		}
		case 94: {
			return (struct arr_0) {13, constantarr_0_280};
		}
		case 95: {
			return (struct arr_0) {24, constantarr_0_282};
		}
		case 96: {
			return (struct arr_0) {10, constantarr_0_284};
		}
		case 97: {
			return (struct arr_0) {21, constantarr_0_286};
		}
		case 98: {
			return (struct arr_0) {12, constantarr_0_275};
		}
		case 99: {
			return (struct arr_0) {15, constantarr_0_288};
		}
		case 100: {
			return (struct arr_0) {15, constantarr_0_289};
		}
		case 101: {
			return (struct arr_0) {12, constantarr_0_291};
		}
		case 102: {
			return (struct arr_0) {5, constantarr_0_293};
		}
		case 103: {
			return (struct arr_0) {1, constantarr_0_294};
		}
		case 104: {
			return (struct arr_0) {7, constantarr_0_296};
		}
		case 105: {
			return (struct arr_0) {23, constantarr_0_297};
		}
		case 106: {
			return (struct arr_0) {5, constantarr_0_298};
		}
		case 107: {
			return (struct arr_0) {8, constantarr_0_299};
		}
		case 108: {
			return (struct arr_0) {15, constantarr_0_300};
		}
		case 109: {
			return (struct arr_0) {18, constantarr_0_301};
		}
		case 110: {
			return (struct arr_0) {6, constantarr_0_302};
		}
		case 111: {
			return (struct arr_0) {13, constantarr_0_303};
		}
		case 112: {
			return (struct arr_0) {6, constantarr_0_304};
		}
		case 113: {
			return (struct arr_0) {6, constantarr_0_304};
		}
		case 114: {
			return (struct arr_0) {13, constantarr_0_280};
		}
		case 115: {
			return (struct arr_0) {1, constantarr_0_47};
		}
		case 116: {
			return (struct arr_0) {12, constantarr_0_307};
		}
		case 117: {
			return (struct arr_0) {14, constantarr_0_311};
		}
		case 118: {
			return (struct arr_0) {14, constantarr_0_314};
		}
		case 119: {
			return (struct arr_0) {19, constantarr_0_315};
		}
		case 120: {
			return (struct arr_0) {5, constantarr_0_51};
		}
		case 121: {
			return (struct arr_0) {16, constantarr_0_316};
		}
		case 122: {
			return (struct arr_0) {6, constantarr_0_317};
		}
		case 123: {
			return (struct arr_0) {6, constantarr_0_318};
		}
		case 124: {
			return (struct arr_0) {14, constantarr_0_320};
		}
		case 125: {
			return (struct arr_0) {2, constantarr_0_247};
		}
		case 126: {
			return (struct arr_0) {19, constantarr_0_323};
		}
		case 127: {
			return (struct arr_0) {19, constantarr_0_323};
		}
		case 128: {
			return (struct arr_0) {7, constantarr_0_328};
		}
		case 129: {
			return (struct arr_0) {13, constantarr_0_329};
		}
		case 130: {
			return (struct arr_0) {7, constantarr_0_330};
		}
		case 131: {
			return (struct arr_0) {3, constantarr_0_336};
		}
		case 132: {
			return (struct arr_0) {10, constantarr_0_248};
		}
		case 133: {
			return (struct arr_0) {14, constantarr_0_357};
		}
		case 134: {
			return (struct arr_0) {10, constantarr_0_358};
		}
		case 135: {
			return (struct arr_0) {16, constantarr_0_359};
		}
		case 136: {
			return (struct arr_0) {16, constantarr_0_360};
		}
		case 137: {
			return (struct arr_0) {14, constantarr_0_363};
		}
		case 138: {
			return (struct arr_0) {15, constantarr_0_364};
		}
		case 139: {
			return (struct arr_0) {13, constantarr_0_280};
		}
		case 140: {
			return (struct arr_0) {0u, NULL};
		}
		case 141: {
			return (struct arr_0) {38, constantarr_0_372};
		}
		case 142: {
			return (struct arr_0) {0u, NULL};
		}
		case 143: {
			return (struct arr_0) {22, constantarr_0_377};
		}
		case 144: {
			return (struct arr_0) {17, constantarr_0_378};
		}
		case 145: {
			return (struct arr_0) {13, constantarr_0_379};
		}
		case 146: {
			return (struct arr_0) {38, constantarr_0_372};
		}
		case 147: {
			return (struct arr_0) {0u, NULL};
		}
		case 148: {
			return (struct arr_0) {21, constantarr_0_380};
		}
		case 149: {
			return (struct arr_0) {22, constantarr_0_381};
		}
		case 150: {
			return (struct arr_0) {34, constantarr_0_382};
		}
		case 151: {
			return (struct arr_0) {13, constantarr_0_280};
		}
		case 152: {
			return (struct arr_0) {0u, NULL};
		}
		case 153: {
			return (struct arr_0) {29, constantarr_0_383};
		}
		case 154: {
			return (struct arr_0) {30, constantarr_0_386};
		}
		case 155: {
			return (struct arr_0) {19, constantarr_0_387};
		}
		case 156: {
			return (struct arr_0) {10, constantarr_0_388};
		}
		case 157: {
			return (struct arr_0) {25, constantarr_0_392};
		}
		case 158: {
			return (struct arr_0) {20, constantarr_0_393};
		}
		case 159: {
			return (struct arr_0) {10, constantarr_0_394};
		}
		case 160: {
			return (struct arr_0) {17, constantarr_0_395};
		}
		case 161: {
			return (struct arr_0) {12, constantarr_0_291};
		}
		case 162: {
			return (struct arr_0) {13, constantarr_0_280};
		}
		case 163: {
			return (struct arr_0) {8, constantarr_0_398};
		}
		case 164: {
			return (struct arr_0) {8, constantarr_0_398};
		}
		case 165: {
			return (struct arr_0) {15, constantarr_0_399};
		}
		case 166: {
			return (struct arr_0) {12, constantarr_0_402};
		}
		case 167: {
			return (struct arr_0) {4, constantarr_0_403};
		}
		case 168: {
			return (struct arr_0) {10, constantarr_0_404};
		}
		case 169: {
			return (struct arr_0) {12, constantarr_0_411};
		}
		case 170: {
			return (struct arr_0) {5, constantarr_0_413};
		}
		case 171: {
			return (struct arr_0) {10, constantarr_0_415};
		}
		case 172: {
			return (struct arr_0) {12, constantarr_0_420};
		}
		case 173: {
			return (struct arr_0) {11, constantarr_0_422};
		}
		case 174: {
			return (struct arr_0) {28, constantarr_0_423};
		}
		case 175: {
			return (struct arr_0) {4, constantarr_0_426};
		}
		case 176: {
			return (struct arr_0) {4, constantarr_0_426};
		}
		case 177: {
			return (struct arr_0) {4, constantarr_0_426};
		}
		case 178: {
			return (struct arr_0) {4, constantarr_0_426};
		}
		case 179: {
			return (struct arr_0) {6, constantarr_0_433};
		}
		case 180: {
			return (struct arr_0) {24, constantarr_0_434};
		}
		case 181: {
			return (struct arr_0) {0u, NULL};
		}
		case 182: {
			return (struct arr_0) {23, constantarr_0_435};
		}
		case 183: {
			return (struct arr_0) {0u, NULL};
		}
		case 184: {
			return (struct arr_0) {36, constantarr_0_437};
		}
		case 185: {
			return (struct arr_0) {11, constantarr_0_438};
		}
		case 186: {
			return (struct arr_0) {36, constantarr_0_439};
		}
		case 187: {
			return (struct arr_0) {28, constantarr_0_440};
		}
		case 188: {
			return (struct arr_0) {24, constantarr_0_442};
		}
		case 189: {
			return (struct arr_0) {15, constantarr_0_443};
		}
		case 190: {
			return (struct arr_0) {18, constantarr_0_445};
		}
		case 191: {
			return (struct arr_0) {0u, NULL};
		}
		case 192: {
			return (struct arr_0) {31, constantarr_0_447};
		}
		case 193: {
			return (struct arr_0) {31, constantarr_0_448};
		}
		case 194: {
			return (struct arr_0) {23, constantarr_0_449};
		}
		case 195: {
			return (struct arr_0) {18, constantarr_0_450};
		}
		case 196: {
			return (struct arr_0) {24, constantarr_0_451};
		}
		case 197: {
			return (struct arr_0) {5, constantarr_0_454};
		}
		case 198: {
			return (struct arr_0) {14, constantarr_0_455};
		}
		case 199: {
			return (struct arr_0) {15, constantarr_0_456};
		}
		case 200: {
			return (struct arr_0) {10, constantarr_0_457};
		}
		case 201: {
			return (struct arr_0) {13, constantarr_0_280};
		}
		case 202: {
			return (struct arr_0) {25, constantarr_0_459};
		}
		case 203: {
			return (struct arr_0) {14, constantarr_0_460};
		}
		case 204: {
			return (struct arr_0) {23, constantarr_0_297};
		}
		case 205: {
			return (struct arr_0) {18, constantarr_0_461};
		}
		case 206: {
			return (struct arr_0) {24, constantarr_0_462};
		}
		case 207: {
			return (struct arr_0) {18, constantarr_0_463};
		}
		case 208: {
			return (struct arr_0) {0u, NULL};
		}
		case 209: {
			return (struct arr_0) {20, constantarr_0_393};
		}
		case 210: {
			return (struct arr_0) {0u, NULL};
		}
		case 211: {
			return (struct arr_0) {14, constantarr_0_464};
		}
		case 212: {
			return (struct arr_0) {12, constantarr_0_291};
		}
		case 213: {
			return (struct arr_0) {13, constantarr_0_280};
		}
		case 214: {
			return (struct arr_0) {33, constantarr_0_465};
		}
		case 215: {
			return (struct arr_0) {6, constantarr_0_318};
		}
		case 216: {
			return (struct arr_0) {24, constantarr_0_466};
		}
		case 217: {
			return (struct arr_0) {5, constantarr_0_467};
		}
		case 218: {
			return (struct arr_0) {13, constantarr_0_468};
		}
		case 219: {
			return (struct arr_0) {17, constantarr_0_469};
		}
		case 220: {
			return (struct arr_0) {8, constantarr_0_470};
		}
		case 221: {
			return (struct arr_0) {0u, NULL};
		}
		case 222: {
			return (struct arr_0) {15, constantarr_0_472};
		}
		case 223: {
			return (struct arr_0) {10, constantarr_0_473};
		}
		case 224: {
			return (struct arr_0) {30, constantarr_0_474};
		}
		case 225: {
			return (struct arr_0) {22, constantarr_0_475};
		}
		case 226: {
			return (struct arr_0) {22, constantarr_0_476};
		}
		case 227: {
			return (struct arr_0) {26, constantarr_0_477};
		}
		case 228: {
			return (struct arr_0) {0u, NULL};
		}
		case 229: {
			return (struct arr_0) {17, constantarr_0_478};
		}
		case 230: {
			return (struct arr_0) {14, constantarr_0_479};
		}
		case 231: {
			return (struct arr_0) {30, constantarr_0_480};
		}
		case 232: {
			return (struct arr_0) {15, constantarr_0_481};
		}
		case 233: {
			return (struct arr_0) {0u, NULL};
		}
		case 234: {
			return (struct arr_0) {11, constantarr_0_483};
		}
		case 235: {
			return (struct arr_0) {45, constantarr_0_484};
		}
		case 236: {
			return (struct arr_0) {19, constantarr_0_485};
		}
		case 237: {
			return (struct arr_0) {17, constantarr_0_489};
		}
		case 238: {
			return (struct arr_0) {14, constantarr_0_490};
		}
		case 239: {
			return (struct arr_0) {9, constantarr_0_491};
		}
		case 240: {
			return (struct arr_0) {6, constantarr_0_492};
		}
		case 241: {
			return (struct arr_0) {12, constantarr_0_493};
		}
		case 242: {
			return (struct arr_0) {10, constantarr_0_496};
		}
		case 243: {
			return (struct arr_0) {15, constantarr_0_498};
		}
		case 244: {
			return (struct arr_0) {21, constantarr_0_499};
		}
		case 245: {
			return (struct arr_0) {28, constantarr_0_503};
		}
		case 246: {
			return (struct arr_0) {6, constantarr_0_506};
		}
		case 247: {
			return (struct arr_0) {21, constantarr_0_507};
		}
		case 248: {
			return (struct arr_0) {10, constantarr_0_457};
		}
		case 249: {
			return (struct arr_0) {16, constantarr_0_508};
		}
		case 250: {
			return (struct arr_0) {11, constantarr_0_509};
		}
		case 251: {
			return (struct arr_0) {17, constantarr_0_510};
		}
		case 252: {
			return (struct arr_0) {13, constantarr_0_514};
		}
		case 253: {
			return (struct arr_0) {15, constantarr_0_515};
		}
		case 254: {
			return (struct arr_0) {9, constantarr_0_520};
		}
		case 255: {
			return (struct arr_0) {17, constantarr_0_522};
		}
		case 256: {
			return (struct arr_0) {21, constantarr_0_524};
		}
		case 257: {
			return (struct arr_0) {9, constantarr_0_528};
		}
		case 258: {
			return (struct arr_0) {14, constantarr_0_532};
		}
		case 259: {
			return (struct arr_0) {13, constantarr_0_533};
		}
		case 260: {
			return (struct arr_0) {19, constantarr_0_534};
		}
		case 261: {
			return (struct arr_0) {12, constantarr_0_291};
		}
		case 262: {
			return (struct arr_0) {13, constantarr_0_280};
		}
		case 263: {
			return (struct arr_0) {15, constantarr_0_535};
		}
		case 264: {
			return (struct arr_0) {15, constantarr_0_535};
		}
		case 265: {
			return (struct arr_0) {19, constantarr_0_537};
		}
		case 266: {
			return (struct arr_0) {8, constantarr_0_292};
		}
		case 267: {
			return (struct arr_0) {8, constantarr_0_292};
		}
		case 268: {
			return (struct arr_0) {10, constantarr_0_539};
		}
		case 269: {
			return (struct arr_0) {11, constantarr_0_540};
		}
		case 270: {
			return (struct arr_0) {38, constantarr_0_542};
		}
		case 271: {
			return (struct arr_0) {12, constantarr_0_543};
		}
		case 272: {
			return (struct arr_0) {8, constantarr_0_186};
		}
		case 273: {
			return (struct arr_0) {17, constantarr_0_545};
		}
		case 274: {
			return (struct arr_0) {17, constantarr_0_271};
		}
		case 275: {
			return (struct arr_0) {11, constantarr_0_546};
		}
		case 276: {
			return (struct arr_0) {8, constantarr_0_550};
		}
		case 277: {
			return (struct arr_0) {8, constantarr_0_551};
		}
		case 278: {
			return (struct arr_0) {7, constantarr_0_556};
		}
		case 279: {
			return (struct arr_0) {12, constantarr_0_560};
		}
		case 280: {
			return (struct arr_0) {33, constantarr_0_561};
		}
		case 281: {
			return (struct arr_0) {38, constantarr_0_562};
		}
		case 282: {
			return (struct arr_0) {12, constantarr_0_291};
		}
		case 283: {
			return (struct arr_0) {8, constantarr_0_563};
		}
		case 284: {
			return (struct arr_0) {30, constantarr_0_564};
		}
		case 285: {
			return (struct arr_0) {14, constantarr_0_565};
		}
		case 286: {
			return (struct arr_0) {10, constantarr_0_457};
		}
		case 287: {
			return (struct arr_0) {10, constantarr_0_566};
		}
		case 288: {
			return (struct arr_0) {13, constantarr_0_567};
		}
		case 289: {
			return (struct arr_0) {46, constantarr_0_569};
		}
		case 290: {
			return (struct arr_0) {0u, NULL};
		}
		case 291: {
			return (struct arr_0) {0u, NULL};
		}
		case 292: {
			return (struct arr_0) {0u, NULL};
		}
		case 293: {
			return (struct arr_0) {0u, NULL};
		}
		case 294: {
			return (struct arr_0) {0u, NULL};
		}
		case 295: {
			return (struct arr_0) {0u, NULL};
		}
		case 296: {
			return (struct arr_0) {0u, NULL};
		}
		case 297: {
			return (struct arr_0) {0u, NULL};
		}
		case 298: {
			return (struct arr_0) {0u, NULL};
		}
		case 299: {
			return (struct arr_0) {0u, NULL};
		}
		case 300: {
			return (struct arr_0) {0u, NULL};
		}
		case 301: {
			return (struct arr_0) {0u, NULL};
		}
		case 302: {
			return (struct arr_0) {0u, NULL};
		}
		case 303: {
			return (struct arr_0) {0u, NULL};
		}
		case 304: {
			return (struct arr_0) {0u, NULL};
		}
		case 305: {
			return (struct arr_0) {0u, NULL};
		}
		case 306: {
			return (struct arr_0) {0u, NULL};
		}
		case 307: {
			return (struct arr_0) {0u, NULL};
		}
		case 308: {
			return (struct arr_0) {0u, NULL};
		}
		case 309: {
			return (struct arr_0) {0u, NULL};
		}
		case 310: {
			return (struct arr_0) {0u, NULL};
		}
		case 311: {
			return (struct arr_0) {0u, NULL};
		}
		case 312: {
			return (struct arr_0) {0u, NULL};
		}
		case 313: {
			return (struct arr_0) {0u, NULL};
		}
		case 314: {
			return (struct arr_0) {0u, NULL};
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
			return (struct arr_0) {14, constantarr_0_577};
		}
		case 350: {
			return (struct arr_0) {7, constantarr_0_579};
		}
		case 351: {
			return (struct arr_0) {12, constantarr_0_580};
		}
		case 352: {
			return (struct arr_0) {18, constantarr_0_582};
		}
		case 353: {
			return (struct arr_0) {15, constantarr_0_583};
		}
		case 354: {
			return (struct arr_0) {12, constantarr_0_586};
		}
		case 355: {
			return (struct arr_0) {6, constantarr_0_588};
		}
		case 356: {
			return (struct arr_0) {5, constantarr_0_589};
		}
		case 357: {
			return (struct arr_0) {19, constantarr_0_591};
		}
		case 358: {
			return (struct arr_0) {4, constantarr_0_592};
		}
		case 359: {
			return (struct arr_0) {35, constantarr_0_593};
		}
		case 360: {
			return (struct arr_0) {4, constantarr_0_597};
		}
		case 361: {
			return (struct arr_0) {33, constantarr_0_598};
		}
		case 362: {
			return (struct arr_0) {27, constantarr_0_599};
		}
		case 363: {
			return (struct arr_0) {21, constantarr_0_600};
		}
		case 364: {
			return (struct arr_0) {20, constantarr_0_601};
		}
		case 365: {
			return (struct arr_0) {19, constantarr_0_602};
		}
		case 366: {
			return (struct arr_0) {0u, NULL};
		}
		case 367: {
			return (struct arr_0) {4, constantarr_0_603};
		}
		case 368: {
			return (struct arr_0) {7, constantarr_0_604};
		}
		case 369: {
			return (struct arr_0) {18, constantarr_0_605};
		}
		case 370: {
			return (struct arr_0) {11, constantarr_0_606};
		}
		case 371: {
			return (struct arr_0) {6, constantarr_0_607};
		}
		case 372: {
			return (struct arr_0) {13, constantarr_0_280};
		}
		case 373: {
			return (struct arr_0) {12, constantarr_0_291};
		}
		case 374: {
			return (struct arr_0) {13, constantarr_0_280};
		}
		case 375: {
			return (struct arr_0) {13, constantarr_0_280};
		}
		case 376: {
			return (struct arr_0) {35, constantarr_0_608};
		}
		case 377: {
			return (struct arr_0) {31, constantarr_0_610};
		}
		case 378: {
			return (struct arr_0) {22, constantarr_0_611};
		}
		case 379: {
			return (struct arr_0) {20, constantarr_0_393};
		}
		case 380: {
			return (struct arr_0) {0u, NULL};
		}
		case 381: {
			return (struct arr_0) {14, constantarr_0_464};
		}
		case 382: {
			return (struct arr_0) {12, constantarr_0_291};
		}
		case 383: {
			return (struct arr_0) {13, constantarr_0_280};
		}
		case 384: {
			return (struct arr_0) {30, constantarr_0_613};
		}
		case 385: {
			return (struct arr_0) {39, constantarr_0_615};
		}
		case 386: {
			return (struct arr_0) {22, constantarr_0_616};
		}
		case 387: {
			return (struct arr_0) {14, constantarr_0_460};
		}
		case 388: {
			return (struct arr_0) {23, constantarr_0_297};
		}
		case 389: {
			return (struct arr_0) {18, constantarr_0_461};
		}
		case 390: {
			return (struct arr_0) {24, constantarr_0_462};
		}
		case 391: {
			return (struct arr_0) {17, constantarr_0_271};
		}
		case 392: {
			return (struct arr_0) {18, constantarr_0_463};
		}
		case 393: {
			return (struct arr_0) {0u, NULL};
		}
		case 394: {
			return (struct arr_0) {20, constantarr_0_393};
		}
		case 395: {
			return (struct arr_0) {0u, NULL};
		}
		case 396: {
			return (struct arr_0) {30, constantarr_0_617};
		}
		case 397: {
			return (struct arr_0) {39, constantarr_0_619};
		}
		case 398: {
			return (struct arr_0) {12, constantarr_0_620};
		}
		case 399: {
			return (struct arr_0) {21, constantarr_0_622};
		}
		case 400: {
			return (struct arr_0) {11, constantarr_0_623};
		}
		case 401: {
			return (struct arr_0) {16, constantarr_0_624};
		}
		case 402: {
			return (struct arr_0) {25, constantarr_0_625};
		}
		case 403: {
			return (struct arr_0) {11, constantarr_0_146};
		}
		case 404: {
			return (struct arr_0) {8, constantarr_0_292};
		}
		case 405: {
			return (struct arr_0) {19, constantarr_0_626};
		}
		case 406: {
			return (struct arr_0) {11, constantarr_0_627};
		}
		case 407: {
			return (struct arr_0) {16, constantarr_0_624};
		}
		case 408: {
			return (struct arr_0) {25, constantarr_0_625};
		}
		case 409: {
			return (struct arr_0) {11, constantarr_0_146};
		}
		case 410: {
			return (struct arr_0) {8, constantarr_0_292};
		}
		case 411: {
			return (struct arr_0) {13, constantarr_0_280};
		}
		case 412: {
			return (struct arr_0) {12, constantarr_0_291};
		}
		case 413: {
			return (struct arr_0) {13, constantarr_0_280};
		}
		case 414: {
			return (struct arr_0) {19, constantarr_0_628};
		}
		case 415: {
			return (struct arr_0) {22, constantarr_0_629};
		}
		case 416: {
			return (struct arr_0) {8, constantarr_0_630};
		}
		case 417: {
			return (struct arr_0) {8, constantarr_0_631};
		}
		case 418: {
			return (struct arr_0) {8, constantarr_0_632};
		}
		case 419: {
			return (struct arr_0) {13, constantarr_0_280};
		}
		case 420: {
			return (struct arr_0) {17, constantarr_0_271};
		}
		case 421: {
			return (struct arr_0) {16, constantarr_0_633};
		}
		case 422: {
			return (struct arr_0) {1, constantarr_0_24};
		}
		case 423: {
			return (struct arr_0) {27, constantarr_0_634};
		}
		case 424: {
			return (struct arr_0) {5, constantarr_0_635};
		}
		case 425: {
			return (struct arr_0) {0u, NULL};
		}
		case 426: {
			return (struct arr_0) {8, constantarr_0_636};
		}
		case 427: {
			return (struct arr_0) {13, constantarr_0_280};
		}
		case 428: {
			return (struct arr_0) {17, constantarr_0_271};
		}
		case 429: {
			return (struct arr_0) {16, constantarr_0_633};
		}
		case 430: {
			return (struct arr_0) {13, constantarr_0_637};
		}
		case 431: {
			return (struct arr_0) {13, constantarr_0_638};
		}
		case 432: {
			return (struct arr_0) {13, constantarr_0_280};
		}
		case 433: {
			return (struct arr_0) {18, constantarr_0_640};
		}
		case 434: {
			return (struct arr_0) {18, constantarr_0_641};
		}
		case 435: {
			return (struct arr_0) {13, constantarr_0_644};
		}
		case 436: {
			return (struct arr_0) {35, constantarr_0_645};
		}
		case 437: {
			return (struct arr_0) {16, constantarr_0_646};
		}
		case 438: {
			return (struct arr_0) {35, constantarr_0_647};
		}
		case 439: {
			return (struct arr_0) {12, constantarr_0_649};
		}
		case 440: {
			return (struct arr_0) {11, constantarr_0_146};
		}
		case 441: {
			return (struct arr_0) {12, constantarr_0_650};
		}
		case 442: {
			return (struct arr_0) {11, constantarr_0_146};
		}
		case 443: {
			return (struct arr_0) {22, constantarr_0_651};
		}
		case 444: {
			return (struct arr_0) {18, constantarr_0_652};
		}
		case 445: {
			return (struct arr_0) {14, constantarr_0_653};
		}
		case 446: {
			return (struct arr_0) {8, constantarr_0_654};
		}
		case 447: {
			return (struct arr_0) {9, constantarr_0_190};
		}
		case 448: {
			return (struct arr_0) {8, constantarr_0_655};
		}
		case 449: {
			return (struct arr_0) {20, constantarr_0_656};
		}
		case 450: {
			return (struct arr_0) {16, constantarr_0_658};
		}
		case 451: {
			return (struct arr_0) {30, constantarr_0_659};
		}
		case 452: {
			return (struct arr_0) {40, constantarr_0_660};
		}
		case 453: {
			return (struct arr_0) {27, constantarr_0_661};
		}
		case 454: {
			return (struct arr_0) {6, constantarr_0_664};
		}
		case 455: {
			return (struct arr_0) {18, constantarr_0_665};
		}
		case 456: {
			return (struct arr_0) {19, constantarr_0_666};
		}
		case 457: {
			return (struct arr_0) {12, constantarr_0_543};
		}
		case 458: {
			return (struct arr_0) {25, constantarr_0_667};
		}
		case 459: {
			return (struct arr_0) {8, constantarr_0_292};
		}
		case 460: {
			return (struct arr_0) {18, constantarr_0_301};
		}
		case 461: {
			return (struct arr_0) {21, constantarr_0_669};
		}
		case 462: {
			return (struct arr_0) {18, constantarr_0_158};
		}
		case 463: {
			return (struct arr_0) {24, constantarr_0_670};
		}
		case 464: {
			return (struct arr_0) {30, constantarr_0_671};
		}
		case 465: {
			return (struct arr_0) {1, constantarr_0_672};
		}
		case 466: {
			return (struct arr_0) {6, constantarr_0_673};
		}
		case 467: {
			return (struct arr_0) {18, constantarr_0_665};
		}
		case 468: {
			return (struct arr_0) {19, constantarr_0_666};
		}
		case 469: {
			return (struct arr_0) {12, constantarr_0_543};
		}
		case 470: {
			return (struct arr_0) {25, constantarr_0_667};
		}
		case 471: {
			return (struct arr_0) {8, constantarr_0_292};
		}
		case 472: {
			return (struct arr_0) {18, constantarr_0_301};
		}
		case 473: {
			return (struct arr_0) {21, constantarr_0_669};
		}
		case 474: {
			return (struct arr_0) {18, constantarr_0_158};
		}
		case 475: {
			return (struct arr_0) {13, constantarr_0_675};
		}
		case 476: {
			return (struct arr_0) {12, constantarr_0_291};
		}
		case 477: {
			return (struct arr_0) {14, constantarr_0_676};
		}
		case 478: {
			return (struct arr_0) {7, constantarr_0_677};
		}
		case 479: {
			return (struct arr_0) {17, constantarr_0_271};
		}
		case 480: {
			return (struct arr_0) {17, constantarr_0_545};
		}
		case 481: {
			return (struct arr_0) {14, constantarr_0_678};
		}
		case 482: {
			return (struct arr_0) {17, constantarr_0_271};
		}
		case 483: {
			return (struct arr_0) {17, constantarr_0_545};
		}
		case 484: {
			return (struct arr_0) {40, constantarr_0_679};
		}
		case 485: {
			return (struct arr_0) {16, constantarr_0_680};
		}
		case 486: {
			return (struct arr_0) {16, constantarr_0_681};
		}
		case 487: {
			return (struct arr_0) {6, constantarr_0_188};
		}
		case 488: {
			return (struct arr_0) {34, constantarr_0_684};
		}
		case 489: {
			return (struct arr_0) {16, constantarr_0_685};
		}
		case 490: {
			return (struct arr_0) {16, constantarr_0_624};
		}
		case 491: {
			return (struct arr_0) {25, constantarr_0_625};
		}
		case 492: {
			return (struct arr_0) {11, constantarr_0_146};
		}
		case 493: {
			return (struct arr_0) {23, constantarr_0_297};
		}
		case 494: {
			return (struct arr_0) {18, constantarr_0_461};
		}
		case 495: {
			return (struct arr_0) {24, constantarr_0_462};
		}
		case 496: {
			return (struct arr_0) {17, constantarr_0_271};
		}
		case 497: {
			return (struct arr_0) {18, constantarr_0_463};
		}
		case 498: {
			return (struct arr_0) {0u, NULL};
		}
		case 499: {
			return (struct arr_0) {8, constantarr_0_292};
		}
		case 500: {
			return (struct arr_0) {24, constantarr_0_686};
		}
		case 501: {
			return (struct arr_0) {31, constantarr_0_688};
		}
		case 502: {
			return (struct arr_0) {14, constantarr_0_689};
		}
		case 503: {
			return (struct arr_0) {23, constantarr_0_690};
		}
		case 504: {
			return (struct arr_0) {0u, NULL};
		}
		case 505: {
			return (struct arr_0) {9, constantarr_0_692};
		}
		case 506: {
			return (struct arr_0) {10, constantarr_0_457};
		}
		case 507: {
			return (struct arr_0) {8, constantarr_0_693};
		}
		case 508: {
			return (struct arr_0) {19, constantarr_0_695};
		}
		case 509: {
			return (struct arr_0) {27, constantarr_0_696};
		}
		case 510: {
			return (struct arr_0) {20, constantarr_0_697};
		}
		case 511: {
			return (struct arr_0) {10, constantarr_0_457};
		}
		case 512: {
			return (struct arr_0) {30, constantarr_0_698};
		}
		case 513: {
			return (struct arr_0) {12, constantarr_0_291};
		}
		case 514: {
			return (struct arr_0) {13, constantarr_0_280};
		}
		case 515: {
			return (struct arr_0) {8, constantarr_0_292};
		}
		case 516: {
			return (struct arr_0) {34, constantarr_0_699};
		}
		case 517: {
			return (struct arr_0) {17, constantarr_0_545};
		}
		case 518: {
			return (struct arr_0) {41, constantarr_0_701};
		}
		case 519: {
			return (struct arr_0) {39, constantarr_0_703};
		}
		case 520: {
			return (struct arr_0) {0u, NULL};
		}
		case 521: {
			return (struct arr_0) {33, constantarr_0_704};
		}
		case 522: {
			return (struct arr_0) {11, constantarr_0_146};
		}
		case 523: {
			return (struct arr_0) {30, constantarr_0_698};
		}
		case 524: {
			return (struct arr_0) {12, constantarr_0_291};
		}
		case 525: {
			return (struct arr_0) {10, constantarr_0_706};
		}
		case 526: {
			return (struct arr_0) {8, constantarr_0_654};
		}
		case 527: {
			return (struct arr_0) {9, constantarr_0_190};
		}
		case 528: {
			return (struct arr_0) {9, constantarr_0_707};
		}
		case 529: {
			return (struct arr_0) {15, constantarr_0_708};
		}
		case 530: {
			return (struct arr_0) {11, constantarr_0_709};
		}
		case 531: {
			return (struct arr_0) {11, constantarr_0_710};
		}
		case 532: {
			return (struct arr_0) {10, constantarr_0_711};
		}
		case 533: {
			return (struct arr_0) {12, constantarr_0_713};
		}
		case 534: {
			return (struct arr_0) {13, constantarr_0_714};
		}
		case 535: {
			return (struct arr_0) {10, constantarr_0_715};
		}
		case 536: {
			return (struct arr_0) {7, constantarr_0_716};
		}
		case 537: {
			return (struct arr_0) {11, constantarr_0_717};
		}
		case 538: {
			return (struct arr_0) {16, constantarr_0_718};
		}
		case 539: {
			return (struct arr_0) {15, constantarr_0_719};
		}
		case 540: {
			return (struct arr_0) {21, constantarr_0_720};
		}
		case 541: {
			return (struct arr_0) {19, constantarr_0_602};
		}
		case 542: {
			return (struct arr_0) {0u, NULL};
		}
		case 543: {
			return (struct arr_0) {4, constantarr_0_721};
		}
		case 544: {
			return (struct arr_0) {24, constantarr_0_722};
		}
		case 545: {
			return (struct arr_0) {23, constantarr_0_723};
		}
		case 546: {
			return (struct arr_0) {9, constantarr_0_724};
		}
		case 547: {
			return (struct arr_0) {27, constantarr_0_725};
		}
		case 548: {
			return (struct arr_0) {11, constantarr_0_146};
		}
		case 549: {
			return (struct arr_0) {8, constantarr_0_726};
		}
		case 550: {
			return (struct arr_0) {8, constantarr_0_727};
		}
		case 551: {
			return (struct arr_0) {10, constantarr_0_171};
		}
		case 552: {
			return (struct arr_0) {10, constantarr_0_172};
		}
		case 553: {
			return (struct arr_0) {22, constantarr_0_728};
		}
		case 554: {
			return (struct arr_0) {17, constantarr_0_729};
		}
		case 555: {
			return (struct arr_0) {5, constantarr_0_730};
		}
		case 556: {
			return (struct arr_0) {20, constantarr_0_731};
		}
		case 557: {
			return (struct arr_0) {6, constantarr_0_732};
		}
		case 558: {
			return (struct arr_0) {9, constantarr_0_733};
		}
		case 559: {
			return (struct arr_0) {6, constantarr_0_734};
		}
		case 560: {
			return (struct arr_0) {10, constantarr_0_735};
		}
		case 561: {
			return (struct arr_0) {11, constantarr_0_736};
		}
		case 562: {
			return (struct arr_0) {30, constantarr_0_737};
		}
		case 563: {
			return (struct arr_0) {17, constantarr_0_738};
		}
		case 564: {
			return (struct arr_0) {11, constantarr_0_739};
		}
		case 565: {
			return (struct arr_0) {19, constantarr_0_740};
		}
		case 566: {
			return (struct arr_0) {24, constantarr_0_741};
		}
		case 567: {
			return (struct arr_0) {35, constantarr_0_742};
		}
		case 568: {
			return (struct arr_0) {27, constantarr_0_661};
		}
		case 569: {
			return (struct arr_0) {15, constantarr_0_745};
		}
		case 570: {
			return (struct arr_0) {7, constantarr_0_746};
		}
		case 571: {
			return (struct arr_0) {35, constantarr_0_747};
		}
		case 572: {
			return (struct arr_0) {12, constantarr_0_620};
		}
		case 573: {
			return (struct arr_0) {21, constantarr_0_622};
		}
		case 574: {
			return (struct arr_0) {22, constantarr_0_629};
		}
		case 575: {
			return (struct arr_0) {27, constantarr_0_634};
		}
		case 576: {
			return (struct arr_0) {14, constantarr_0_748};
		}
		case 577: {
			return (struct arr_0) {42, constantarr_0_749};
		}
		case 578: {
			return (struct arr_0) {0u, NULL};
		}
		case 579: {
			return (struct arr_0) {14, constantarr_0_752};
		}
		case 580: {
			return (struct arr_0) {10, constantarr_0_753};
		}
		case 581: {
			return (struct arr_0) {18, constantarr_0_755};
		}
		case 582: {
			return (struct arr_0) {20, constantarr_0_756};
		}
		case 583: {
			return (struct arr_0) {7, constantarr_0_757};
		}
		case 584: {
			return (struct arr_0) {7, constantarr_0_757};
		}
		case 585: {
			return (struct arr_0) {8, constantarr_0_758};
		}
		case 586: {
			return (struct arr_0) {10, constantarr_0_759};
		}
		case 587: {
			return (struct arr_0) {4, constantarr_0_761};
		}
		case 588: {
			return (struct arr_0) {6, constantarr_0_763};
		}
		case 589: {
			return (struct arr_0) {17, constantarr_0_764};
		}
		case 590: {
			return (struct arr_0) {10, constantarr_0_765};
		}
		case 591: {
			return (struct arr_0) {9, constantarr_0_766};
		}
		case 592: {
			return (struct arr_0) {0u, NULL};
		}
		case 593: {
			return (struct arr_0) {6, constantarr_0_769};
		}
		case 594: {
			return (struct arr_0) {7, constantarr_0_770};
		}
		case 595: {
			return (struct arr_0) {15, constantarr_0_771};
		}
		case 596: {
			return (struct arr_0) {19, constantarr_0_772};
		}
		case 597: {
			return (struct arr_0) {0u, NULL};
		}
		case 598: {
			return (struct arr_0) {8, constantarr_0_773};
		}
		case 599: {
			return (struct arr_0) {8, constantarr_0_773};
		}
		case 600: {
			return (struct arr_0) {7, constantarr_0_774};
		}
		case 601: {
			return (struct arr_0) {16, constantarr_0_775};
		}
		case 602: {
			return (struct arr_0) {14, constantarr_0_777};
		}
		case 603: {
			return (struct arr_0) {4, constantarr_0_426};
		}
		case 604: {
			return (struct arr_0) {9, constantarr_0_781};
		}
		case 605: {
			return (struct arr_0) {15, constantarr_0_784};
		}
		case 606: {
			return (struct arr_0) {15, constantarr_0_786};
		}
		case 607: {
			return (struct arr_0) {13, constantarr_0_790};
		}
		case 608: {
			return (struct arr_0) {15, constantarr_0_791};
		}
		case 609: {
			return (struct arr_0) {9, constantarr_0_792};
		}
		case 610: {
			return (struct arr_0) {14, constantarr_0_793};
		}
		case 611: {
			return (struct arr_0) {28, constantarr_0_794};
		}
		case 612: {
			return (struct arr_0) {13, constantarr_0_795};
		}
		case 613: {
			return (struct arr_0) {13, constantarr_0_796};
		}
		case 614: {
			return (struct arr_0) {10, constantarr_0_797};
		}
		case 615: {
			return (struct arr_0) {11, constantarr_0_798};
		}
		case 616: {
			return (struct arr_0) {9, constantarr_0_799};
		}
		case 617: {
			return (struct arr_0) {18, constantarr_0_800};
		}
		case 618: {
			return (struct arr_0) {42, constantarr_0_801};
		}
		case 619: {
			return (struct arr_0) {14, constantarr_0_802};
		}
		case 620: {
			return (struct arr_0) {11, constantarr_0_146};
		}
		case 621: {
			return (struct arr_0) {8, constantarr_0_804};
		}
		case 622: {
			return (struct arr_0) {8, constantarr_0_805};
		}
		case 623: {
			return (struct arr_0) {10, constantarr_0_457};
		}
		case 624: {
			return (struct arr_0) {19, constantarr_0_772};
		}
		case 625: {
			return (struct arr_0) {0u, NULL};
		}
		case 626: {
			return (struct arr_0) {9, constantarr_0_806};
		}
		case 627: {
			return (struct arr_0) {13, constantarr_0_280};
		}
		case 628: {
			return (struct arr_0) {12, constantarr_0_291};
		}
		case 629: {
			return (struct arr_0) {13, constantarr_0_280};
		}
		case 630: {
			return (struct arr_0) {8, constantarr_0_807};
		}
		case 631: {
			return (struct arr_0) {13, constantarr_0_280};
		}
		case 632: {
			return (struct arr_0) {6, constantarr_0_808};
		}
		case 633: {
			return (struct arr_0) {18, constantarr_0_665};
		}
		case 634: {
			return (struct arr_0) {19, constantarr_0_666};
		}
		case 635: {
			return (struct arr_0) {12, constantarr_0_543};
		}
		case 636: {
			return (struct arr_0) {8, constantarr_0_186};
		}
		case 637: {
			return (struct arr_0) {25, constantarr_0_667};
		}
		case 638: {
			return (struct arr_0) {8, constantarr_0_292};
		}
		case 639: {
			return (struct arr_0) {8, constantarr_0_292};
		}
		case 640: {
			return (struct arr_0) {11, constantarr_0_146};
		}
		case 641: {
			return (struct arr_0) {23, constantarr_0_297};
		}
		case 642: {
			return (struct arr_0) {18, constantarr_0_301};
		}
		case 643: {
			return (struct arr_0) {21, constantarr_0_669};
		}
		case 644: {
			return (struct arr_0) {18, constantarr_0_158};
		}
		case 645: {
			return (struct arr_0) {13, constantarr_0_280};
		}
		case 646: {
			return (struct arr_0) {17, constantarr_0_271};
		}
		case 647: {
			return (struct arr_0) {16, constantarr_0_809};
		}
		case 648: {
			return (struct arr_0) {25, constantarr_0_810};
		}
		case 649: {
			return (struct arr_0) {0u, NULL};
		}
		case 650: {
			return (struct arr_0) {31, constantarr_0_811};
		}
		case 651: {
			return (struct arr_0) {13, constantarr_0_812};
		}
		case 652: {
			return (struct arr_0) {8, constantarr_0_813};
		}
		case 653: {
			return (struct arr_0) {10, constantarr_0_457};
		}
		case 654: {
			return (struct arr_0) {13, constantarr_0_280};
		}
		case 655: {
			return (struct arr_0) {12, constantarr_0_291};
		}
		case 656: {
			return (struct arr_0) {17, constantarr_0_271};
		}
		case 657: {
			return (struct arr_0) {17, constantarr_0_545};
		}
		case 658: {
			return (struct arr_0) {50, constantarr_0_814};
		}
		case 659: {
			return (struct arr_0) {18, constantarr_0_815};
		}
		case 660: {
			return (struct arr_0) {20, constantarr_0_816};
		}
		case 661: {
			return (struct arr_0) {35, constantarr_0_817};
		}
		case 662: {
			return (struct arr_0) {25, constantarr_0_818};
		}
		case 663: {
			return (struct arr_0) {0u, NULL};
		}
		case 664: {
			return (struct arr_0) {14, constantarr_0_820};
		}
		case 665: {
			return (struct arr_0) {21, constantarr_0_821};
		}
		case 666: {
			return (struct arr_0) {26, constantarr_0_822};
		}
		case 667: {
			return (struct arr_0) {21, constantarr_0_823};
		}
		case 668: {
			return (struct arr_0) {0u, NULL};
		}
		case 669: {
			return (struct arr_0) {29, constantarr_0_824};
		}
		case 670: {
			return (struct arr_0) {8, constantarr_0_825};
		}
		case 671: {
			return (struct arr_0) {8, constantarr_0_825};
		}
		case 672: {
			return (struct arr_0) {7, constantarr_0_826};
		}
		case 673: {
			return (struct arr_0) {21, constantarr_0_821};
		}
		case 674: {
			return (struct arr_0) {10, constantarr_0_827};
		}
		case 675: {
			return (struct arr_0) {4, constantarr_0_829};
		}
		case 676: {
			return (struct arr_0) {29, constantarr_0_831};
		}
		case 677: {
			return (struct arr_0) {33, constantarr_0_832};
		}
		case 678: {
			return (struct arr_0) {32, constantarr_0_834};
		}
		case 679: {
			return (struct arr_0) {11, constantarr_0_837};
		}
		case 680: {
			return (struct arr_0) {5, constantarr_0_839};
		}
		case 681: {
			return (struct arr_0) {14, constantarr_0_840};
		}
		case 682: {
			return (struct arr_0) {11, constantarr_0_146};
		}
		case 683: {
			return (struct arr_0) {12, constantarr_0_841};
		}
		case 684: {
			return (struct arr_0) {6, constantarr_0_844};
		}
		case 685: {
			return (struct arr_0) {21, constantarr_0_845};
		}
		case 686: {
			return (struct arr_0) {14, constantarr_0_847};
		}
		case 687: {
			return (struct arr_0) {4, constantarr_0_852};
		}
		case 688: {
			return (struct arr_0) {14, constantarr_0_853};
		}
		case 689: {
			return (struct arr_0) {11, constantarr_0_855};
		}
		case 690: {
			return (struct arr_0) {15, constantarr_0_856};
		}
		case 691: {
			return (struct arr_0) {9, constantarr_0_857};
		}
		case 692: {
			return (struct arr_0) {0u, NULL};
		}
		case 693: {
			return (struct arr_0) {24, constantarr_0_858};
		}
		case 694: {
			return (struct arr_0) {13, constantarr_0_859};
		}
		case 695: {
			return (struct arr_0) {19, constantarr_0_666};
		}
		case 696: {
			return (struct arr_0) {12, constantarr_0_543};
		}
		case 697: {
			return (struct arr_0) {25, constantarr_0_667};
		}
		case 698: {
			return (struct arr_0) {8, constantarr_0_292};
		}
		case 699: {
			return (struct arr_0) {21, constantarr_0_669};
		}
		case 700: {
			return (struct arr_0) {18, constantarr_0_158};
		}
		case 701: {
			return (struct arr_0) {13, constantarr_0_280};
		}
		case 702: {
			return (struct arr_0) {4, constantarr_0_860};
		}
		case 703: {
			return (struct arr_0) {27, constantarr_0_861};
		}
		case 704: {
			return (struct arr_0) {20, constantarr_0_862};
		}
		case 705: {
			return (struct arr_0) {12, constantarr_0_864};
		}
		case 706: {
			return (struct arr_0) {7, constantarr_0_865};
		}
		case 707: {
			return (struct arr_0) {12, constantarr_0_866};
		}
		case 708: {
			return (struct arr_0) {7, constantarr_0_867};
		}
		case 709: {
			return (struct arr_0) {12, constantarr_0_868};
		}
		case 710: {
			return (struct arr_0) {7, constantarr_0_869};
		}
		case 711: {
			return (struct arr_0) {12, constantarr_0_870};
		}
		case 712: {
			return (struct arr_0) {7, constantarr_0_871};
		}
		case 713: {
			return (struct arr_0) {13, constantarr_0_872};
		}
		case 714: {
			return (struct arr_0) {8, constantarr_0_873};
		}
		case 715: {
			return (struct arr_0) {6, constantarr_0_732};
		}
		case 716: {
			return (struct arr_0) {4, constantarr_0_875};
		}
		case 717: {
			return (struct arr_0) {6, constantarr_0_732};
		}
		case 718: {
			return (struct arr_0) {22, constantarr_0_878};
		}
		case 719: {
			return (struct arr_0) {7, constantarr_0_879};
		}
		case 720: {
			return (struct arr_0) {11, constantarr_0_880};
		}
		case 721: {
			return (struct arr_0) {10, constantarr_0_881};
		}
		case 722: {
			return (struct arr_0) {13, constantarr_0_882};
		}
		case 723: {
			return (struct arr_0) {15, constantarr_0_883};
		}
		case 724: {
			return (struct arr_0) {8, constantarr_0_884};
		}
		case 725: {
			return (struct arr_0) {11, constantarr_0_885};
		}
		case 726: {
			return (struct arr_0) {13, constantarr_0_887};
		}
		case 727: {
			return (struct arr_0) {6, constantarr_0_318};
		}
		case 728: {
			return (struct arr_0) {6, constantarr_0_318};
		}
		case 729: {
			return (struct arr_0) {6, constantarr_0_318};
		}
		case 730: {
			return (struct arr_0) {3, constantarr_0_888};
		}
		case 731: {
			return (struct arr_0) {3, constantarr_0_890};
		}
		case 732: {
			return (struct arr_0) {3, constantarr_0_892};
		}
		case 733: {
			return (struct arr_0) {1, constantarr_0_672};
		}
		case 734: {
			return (struct arr_0) {12, constantarr_0_893};
		}
		case 735: {
			return (struct arr_0) {14, constantarr_0_894};
		}
		case 736: {
			return (struct arr_0) {18, constantarr_0_896};
		}
		case 737: {
			return (struct arr_0) {12, constantarr_0_897};
		}
		case 738: {
			return (struct arr_0) {12, constantarr_0_898};
		}
		case 739: {
			return (struct arr_0) {23, constantarr_0_297};
		}
		case 740: {
			return (struct arr_0) {18, constantarr_0_301};
		}
		case 741: {
			return (struct arr_0) {25, constantarr_0_899};
		}
		case 742: {
			return (struct arr_0) {14, constantarr_0_460};
		}
		case 743: {
			return (struct arr_0) {18, constantarr_0_461};
		}
		case 744: {
			return (struct arr_0) {24, constantarr_0_462};
		}
		case 745: {
			return (struct arr_0) {17, constantarr_0_271};
		}
		case 746: {
			return (struct arr_0) {18, constantarr_0_463};
		}
		case 747: {
			return (struct arr_0) {0u, NULL};
		}
		case 748: {
			return (struct arr_0) {20, constantarr_0_393};
		}
		case 749: {
			return (struct arr_0) {0u, NULL};
		}
		case 750: {
			return (struct arr_0) {33, constantarr_0_900};
		}
		case 751: {
			return (struct arr_0) {20, constantarr_0_901};
		}
		case 752: {
			return (struct arr_0) {15, constantarr_0_902};
		}
		case 753: {
			return (struct arr_0) {19, constantarr_0_903};
		}
		case 754: {
			return (struct arr_0) {11, constantarr_0_146};
		}
		case 755: {
			return (struct arr_0) {26, constantarr_0_904};
		}
		case 756: {
			return (struct arr_0) {14, constantarr_0_689};
		}
		case 757: {
			return (struct arr_0) {23, constantarr_0_690};
		}
		case 758: {
			return (struct arr_0) {0u, NULL};
		}
		case 759: {
			return (struct arr_0) {13, constantarr_0_905};
		}
		case 760: {
			return (struct arr_0) {18, constantarr_0_665};
		}
		case 761: {
			return (struct arr_0) {19, constantarr_0_666};
		}
		case 762: {
			return (struct arr_0) {12, constantarr_0_543};
		}
		case 763: {
			return (struct arr_0) {8, constantarr_0_186};
		}
		case 764: {
			return (struct arr_0) {25, constantarr_0_667};
		}
		case 765: {
			return (struct arr_0) {8, constantarr_0_292};
		}
		case 766: {
			return (struct arr_0) {8, constantarr_0_292};
		}
		case 767: {
			return (struct arr_0) {11, constantarr_0_146};
		}
		case 768: {
			return (struct arr_0) {21, constantarr_0_669};
		}
		case 769: {
			return (struct arr_0) {18, constantarr_0_158};
		}
		case 770: {
			return (struct arr_0) {13, constantarr_0_280};
		}
		case 771: {
			return (struct arr_0) {23, constantarr_0_906};
		}
		case 772: {
			return (struct arr_0) {23, constantarr_0_907};
		}
		case 773: {
			return (struct arr_0) {20, constantarr_0_908};
		}
		case 774: {
			return (struct arr_0) {9, constantarr_0_190};
		}
		case 775: {
			return (struct arr_0) {8, constantarr_0_655};
		}
		case 776: {
			return (struct arr_0) {13, constantarr_0_911};
		}
		case 777: {
			return (struct arr_0) {13, constantarr_0_912};
		}
		case 778: {
			return (struct arr_0) {13, constantarr_0_912};
		}
		case 779: {
			return (struct arr_0) {4, constantarr_0_913};
		}
		case 780: {
			return (struct arr_0) {8, constantarr_0_914};
		}
		case 781: {
			return (struct arr_0) {20, constantarr_0_915};
		}
		case 782: {
			return (struct arr_0) {5, constantarr_0_916};
		}
		case 783: {
			return (struct arr_0) {8, constantarr_0_917};
		}
		case 784: {
			return (struct arr_0) {8, constantarr_0_918};
		}
		case 785: {
			return (struct arr_0) {10, constantarr_0_920};
		}
		case 786: {
			return (struct arr_0) {10, constantarr_0_920};
		}
		case 787: {
			return (struct arr_0) {14, constantarr_0_923};
		}
		case 788: {
			return (struct arr_0) {8, constantarr_0_924};
		}
		case 789: {
			return (struct arr_0) {7, constantarr_0_927};
		}
		case 790: {
			return (struct arr_0) {8, constantarr_0_928};
		}
		case 791: {
			return (struct arr_0) {7, constantarr_0_929};
		}
		case 792: {
			return (struct arr_0) {6, constantarr_0_318};
		}
		case 793: {
			return (struct arr_0) {6, constantarr_0_264};
		}
		case 794: {
			return (struct arr_0) {7, constantarr_0_930};
		}
		case 795: {
			return (struct arr_0) {13, constantarr_0_933};
		}
		case 796: {
			return (struct arr_0) {19, constantarr_0_934};
		}
		case 797: {
			return (struct arr_0) {21, constantarr_0_935};
		}
		case 798: {
			return (struct arr_0) {8, constantarr_0_936};
		}
		case 799: {
			return (struct arr_0) {18, constantarr_0_665};
		}
		case 800: {
			return (struct arr_0) {17, constantarr_0_271};
		}
		case 801: {
			return (struct arr_0) {28, constantarr_0_942};
		}
		case 802: {
			return (struct arr_0) {24, constantarr_0_943};
		}
		case 803: {
			return (struct arr_0) {10, constantarr_0_945};
		}
		case 804: {
			return (struct arr_0) {22, constantarr_0_947};
		}
		case 805: {
			return (struct arr_0) {13, constantarr_0_948};
		}
		case 806: {
			return (struct arr_0) {23, constantarr_0_950};
		}
		case 807: {
			return (struct arr_0) {15, constantarr_0_951};
		}
		case 808: {
			return (struct arr_0) {4, constantarr_0_952};
		}
		case 809: {
			return (struct arr_0) {19, constantarr_0_953};
		}
		case 810: {
			return (struct arr_0) {19, constantarr_0_954};
		}
		case 811: {
			return (struct arr_0) {20, constantarr_0_955};
		}
		case 812: {
			return (struct arr_0) {19, constantarr_0_534};
		}
		case 813: {
			return (struct arr_0) {18, constantarr_0_956};
		}
		case 814: {
			return (struct arr_0) {16, constantarr_0_957};
		}
		case 815: {
			return (struct arr_0) {27, constantarr_0_958};
		}
		case 816: {
			return (struct arr_0) {27, constantarr_0_959};
		}
		case 817: {
			return (struct arr_0) {25, constantarr_0_960};
		}
		case 818: {
			return (struct arr_0) {17, constantarr_0_961};
		}
		case 819: {
			return (struct arr_0) {18, constantarr_0_962};
		}
		case 820: {
			return (struct arr_0) {27, constantarr_0_963};
		}
		case 821: {
			return (struct arr_0) {9, constantarr_0_964};
		}
		case 822: {
			return (struct arr_0) {9, constantarr_0_965};
		}
		case 823: {
			return (struct arr_0) {26, constantarr_0_966};
		}
		case 824: {
			return (struct arr_0) {25, constantarr_0_967};
		}
		case 825: {
			return (struct arr_0) {24, constantarr_0_968};
		}
		case 826: {
			return (struct arr_0) {0u, NULL};
		}
		case 827: {
			return (struct arr_0) {5, constantarr_0_969};
		}
		case 828: {
			return (struct arr_0) {21, constantarr_0_971};
		}
		case 829: {
			return (struct arr_0) {25, constantarr_0_967};
		}
		case 830: {
			return (struct arr_0) {24, constantarr_0_968};
		}
		case 831: {
			return (struct arr_0) {0u, NULL};
		}
		case 832: {
			return (struct arr_0) {9, constantarr_0_972};
		}
		case 833: {
			return (struct arr_0) {13, constantarr_0_973};
		}
		case 834: {
			return (struct arr_0) {22, constantarr_0_974};
		}
		case 835: {
			return (struct arr_0) {9, constantarr_0_975};
		}
		case 836: {
			return (struct arr_0) {10, constantarr_0_457};
		}
		case 837: {
			return (struct arr_0) {19, constantarr_0_976};
		}
		case 838: {
			return (struct arr_0) {25, constantarr_0_977};
		}
		case 839: {
			return (struct arr_0) {8, constantarr_0_978};
		}
		case 840: {
			return (struct arr_0) {6, constantarr_0_979};
		}
		case 841: {
			return (struct arr_0) {8, constantarr_0_980};
		}
		case 842: {
			return (struct arr_0) {15, constantarr_0_981};
		}
		case 843: {
			return (struct arr_0) {17, constantarr_0_982};
		}
		case 844: {
			return (struct arr_0) {12, constantarr_0_983};
		}
		case 845: {
			return (struct arr_0) {15, constantarr_0_984};
		}
		case 846: {
			return (struct arr_0) {14, constantarr_0_985};
		}
		case 847: {
			return (struct arr_0) {13, constantarr_0_986};
		}
		case 848: {
			return (struct arr_0) {10, constantarr_0_987};
		}
		case 849: {
			return (struct arr_0) {11, constantarr_0_989};
		}
		case 850: {
			return (struct arr_0) {22, constantarr_0_990};
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
		after_pivot0 = partition_recur_together(ctx, a, b, *a, 1u, _1);
		
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
/* subscript<?t> ptr<nat8>(a ptr<ptr<nat8>>, n nat) */
uint8_t* subscript_1(uint8_t** a, uint64_t n) {
	return *(a + n);
}
/* swap<arr<char>> void(a ptr<arr<char>>, lo nat, hi nat) */
struct void_ swap_1(struct ctx* ctx, struct arr_0* a, uint64_t lo, uint64_t hi) {
	struct arr_0 temp0;
	temp0 = subscript_2(a, lo);
	
	struct arr_0 _0 = subscript_2(a, hi);
	set_subscript_1(a, lo, _0);
	return set_subscript_1(a, hi, temp0);
}
/* subscript<?t> arr<char>(a ptr<arr<char>>, n nat) */
struct arr_0 subscript_2(struct arr_0* a, uint64_t n) {
	return *(a + n);
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
		struct arr_0 _2 = get_fun_name(ctx, *code_ptrs, fun_ptrs, fun_names, _1);
		*code_names = _2;
		uint8_t** _3 = incr_2(code_ptrs);
		code_names = (code_names + 1u);
		end_code_names = end_code_names;
		code_ptrs = _3;
		fun_ptrs = fun_ptrs;
		fun_names = fun_names;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* get-fun-name arr<char>(code-ptr ptr<nat8>, fun-ptrs ptr<ptr<nat8>>, fun-names ptr<arr<char>>, size nat) */
struct arr_0 get_fun_name(struct ctx* ctx, uint8_t* code_ptr, uint8_t** fun_ptrs, struct arr_0* fun_names, uint64_t size) {
	top:;
	uint8_t _0 = _less_0(size, 2u);
	if (_0) {
		return (struct arr_0) {11, constantarr_0_3};
	} else {
		uint8_t* _1 = subscript_1(fun_ptrs, 1u);
		uint8_t _2 = (code_ptr < _1);
		if (_2) {
			return *fun_names;
		} else {
			uint8_t** _3 = incr_2(fun_ptrs);
			struct arr_0* _4 = incr_3(fun_names);
			uint64_t _5 = noctx_decr(size);
			code_ptr = code_ptr;
			fun_ptrs = _3;
			fun_names = _4;
			size = _5;
			goto top;
		}
	}
}
/* incr<ptr<nat8>> ptr<ptr<nat8>>(p ptr<ptr<nat8>>) */
uint8_t** incr_2(uint8_t** p) {
	return (p + 1u);
}
/* incr<arr<char>> ptr<arr<char>>(p ptr<arr<char>>) */
struct arr_0* incr_3(struct arr_0* p) {
	return (p + 1u);
}
/* noctx-at<?t> arr<char>(a arr<arr<char>>, index nat) */
struct arr_0 noctx_at_0(struct arr_1 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	hard_assert(_0);
	return subscript_2(a.data, index);
}
/* ~<?t> arr<char>(a arr<char>, b arr<char>) */
struct arr_0 _concat_0(struct ctx* ctx, struct arr_0 a, struct arr_0 b) {
	uint64_t res_size0;
	res_size0 = _plus(ctx, a.size, b.size);
	
	char* res1;
	res1 = alloc_uninitialized_0(ctx, res_size0);
	
	copy_data_from_0(ctx, res1, a.data, a.size);
	copy_data_from_0(ctx, (res1 + a.size), b.data, b.size);
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
	assert_0(ctx, _1);
	return res0;
}
/* >=<nat> bool(a nat, b nat) */
uint8_t _greaterOrEqual(uint64_t a, uint64_t b) {
	uint8_t _0 = _less_0(a, b);
	return not(_0);
}
/* alloc-uninitialized<?t> ptr<char>(size nat) */
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
/* copy-data-from<?t> void(to ptr<char>, from ptr<char>, len nat) */
struct void_ copy_data_from_0(struct ctx* ctx, char* to, char* from, uint64_t len) {
	return (memcpy((uint8_t*) to, (uint8_t*) from, (len * sizeof(char))), (struct void_) {});
}
/* tail<arr<?t>> arr<arr<char>>(a arr<arr<char>>) */
struct arr_1 tail_0(struct ctx* ctx, struct arr_1 a) {
	uint8_t _0 = empty__q_1(a);
	forbid_0(ctx, _0);
	struct arrow_0 _1 = _arrow_0(ctx, 1u, a.size);
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
		return fail_0(ctx, message);
	} else {
		return (struct void_) {};
	}
}
/* subscript<?t> arr<arr<char>>(a arr<arr<char>>, range arrow<nat, nat>) */
struct arr_1 subscript_3(struct ctx* ctx, struct arr_1 a, struct arrow_0 range) {
	uint8_t _0 = _lessOrEqual(range.from, range.to);
	assert_0(ctx, _0);
	uint8_t _1 = _lessOrEqual(range.to, a.size);
	assert_0(ctx, _1);
	uint64_t _2 = _minus_2(ctx, range.to, range.from);
	return (struct arr_1) {_2, (a.data + range.from)};
}
/* - nat(a nat, b nat) */
uint64_t _minus_2(struct ctx* ctx, uint64_t a, uint64_t b) {
	uint8_t _0 = _greaterOrEqual(a, b);
	assert_0(ctx, _0);
	return (a - b);
}
/* -><nat, nat> arrow<nat, nat>(from nat, to nat) */
struct arrow_0 _arrow_0(struct ctx* ctx, uint64_t from, uint64_t to) {
	return (struct arrow_0) {from, to};
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
	struct arr_0 _0 = to_str_0(ctx, a->level);
	struct arr_0 _1 = _concat_0(ctx, _0, (struct arr_0) {2, constantarr_0_9});
	struct arr_0 _2 = _concat_0(ctx, _1, a->message);
	return print(_2);
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
struct arr_0 to_str_0(struct ctx* ctx, struct log_level a) {
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
/* island.lambda1 void(log logged) */
struct void_ island__lambda1(struct ctx* ctx, struct void_ _closure, struct logged* log) {
	return default_log_handler(ctx, log);
}
/* gc gc() */
struct gc gc(void) {
	uint8_t* mark_begin0;
	uint8_t* _0 = malloc(16777216u);
	mark_begin0 = (uint8_t*) _0;
	
	uint8_t* mark_end1;
	mark_end1 = (mark_begin0 + 16777216u);
	
	uint64_t* data_begin2;
	uint8_t* _1 = malloc((16777216u * sizeof(uint64_t)));
	data_begin2 = (uint64_t*) _1;
	
	uint64_t* data_end3;
	data_end3 = (data_begin2 + 16777216u);
	
	(memset((uint8_t*) mark_begin0, 0u, 16777216u), (struct void_) {});
	struct lock _2 = lock_by_val();
	return (struct gc) {_2, 0u, (struct opt_1) {0, .as0 = (struct none) {}}, 0, 16777216u, mark_begin0, mark_begin0, mark_end1, data_begin2, data_begin2, data_end3};
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
	
	struct fun_act2_0 add5;
	add5 = (struct fun_act2_0) {0, .as0 = (struct void_) {}};
	
	struct arr_4 all_args6;
	all_args6 = (struct arr_4) {(uint64_t) (int64_t) argc, argv};
	
	return call_w_ctx_233(add5, ctx4, all_args6, main_ptr);
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
	gc_ctx0 = (uint8_t*) _0;
	
	struct exception_ctx* exception_ctx1;
	exception_ctx1 = tls->exception_ctx;
	
	struct log_ctx* log_ctx2;
	log_ctx2 = tls->log_ctx;
	
	log_ctx2->handler = (&island->gc_root)->log_handler;
	return (struct ctx) {(uint8_t*) gctx, island->id, exclusion, gc_ctx0, (uint8_t*) exception_ctx1, (uint8_t*) log_ctx2};
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
	res0 = then2(ctx, _0, (struct fun_ref0) {_1, (struct fun_act0_1) {0, .as0 = temp0}});
	
	handle_exceptions(ctx, res0);
	return res0;
}
/* then2<nat> fut<nat>(f fut<void>, cb fun-ref0<nat>) */
struct fut_0* then2(struct ctx* ctx, struct fut_1* f, struct fun_ref0 cb) {
	struct island_and_exclusion _0 = cur_island_and_exclusion(ctx);
	struct then2__lambda0* temp0;
	uint8_t* _1 = alloc(ctx, sizeof(struct then2__lambda0));
	temp0 = (struct then2__lambda0*) _1;
	
	*temp0 = (struct then2__lambda0) {cb};
	return then(ctx, f, (struct fun_ref1) {_0, (struct fun_act1_2) {0, .as0 = temp0}});
}
/* then<?out, void> fut<nat>(f fut<void>, cb fun-ref1<nat, void>) */
struct fut_0* then(struct ctx* ctx, struct fut_1* f, struct fun_ref1 cb) {
	struct fut_0* res0;
	res0 = unresolved(ctx);
	
	struct then__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct then__lambda0));
	temp0 = (struct then__lambda0*) _0;
	
	*temp0 = (struct then__lambda0) {cb, res0};
	callback__e_0(ctx, f, (struct fun_act1_1) {0, .as0 = temp0});
	return res0;
}
/* unresolved<?out> fut<nat>() */
struct fut_0* unresolved(struct ctx* ctx) {
	struct fut_0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct fut_0));
	temp0 = (struct fut_0*) _0;
	
	struct lock _1 = lock_by_val();
	*temp0 = (struct fut_0) {_1, (struct fut_state_0) {0, .as0 = (struct fut_state_callbacks_0) {(struct opt_0) {0, .as0 = (struct none) {}}}}};
	return temp0;
}
/* callback!<?in> void(f fut<void>, cb fun-act1<void, result<void, exception>>) */
struct void_ callback__e_0(struct ctx* ctx, struct fut_1* f, struct fun_act1_1 cb) {
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
	res0 = subscript_4(ctx, f);
	
	release__e(a);
	return res0;
}
/* subscript<?t> void(a fun-act0<void>) */
struct void_ subscript_4(struct ctx* ctx, struct fun_act0_0 a) {
	return call_w_ctx_140(a, ctx);
}
/* call-w-ctx<void> (generated) (generated) */
struct void_ call_w_ctx_140(struct fun_act0_0 a, struct ctx* ctx) {
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
			struct subscript_8__lambda0__lambda0* closure2 = _0.as2;
			
			return subscript_8__lambda0__lambda0(ctx, closure2);
		}
		case 3: {
			struct subscript_8__lambda0* closure3 = _0.as3;
			
			return subscript_8__lambda0(ctx, closure3);
		}
		case 4: {
			struct subscript_13__lambda0__lambda0* closure4 = _0.as4;
			
			return subscript_13__lambda0__lambda0(ctx, closure4);
		}
		case 5: {
			struct subscript_13__lambda0* closure5 = _0.as5;
			
			return subscript_13__lambda0(ctx, closure5);
		}
		default:
			return (struct void_) {};
	}
}
/* subscript<void, result<?t, exception>> void(a fun-act1<void, result<void, exception>>, p0 result<void, exception>) */
struct void_ subscript_5(struct ctx* ctx, struct fun_act1_1 a, struct result_1 p0) {
	return call_w_ctx_142(a, ctx, p0);
}
/* call-w-ctx<void, result<void, exception>> (generated) (generated) */
struct void_ call_w_ctx_142(struct fun_act1_1 a, struct ctx* ctx, struct result_1 p0) {
	struct fun_act1_1 _0 = a;
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
			struct fut_state_callbacks_1 cbs0 = _0.as0;
			
			struct fut_callback_node_1* temp0;
			uint8_t* _1 = alloc(ctx, sizeof(struct fut_callback_node_1));
			temp0 = (struct fut_callback_node_1*) _1;
			
			*temp0 = (struct fut_callback_node_1) {_closure->cb, cbs0.head};
			return (_closure->f->state = (struct fut_state_1) {0, .as0 = (struct fut_state_callbacks_1) {(struct opt_7) {1, .as1 = (struct some_7) {temp0}}}}, (struct void_) {});
		}
		case 1: {
			struct fut_state_resolved_1 r1 = _0.as1;
			
			return subscript_5(ctx, _closure->cb, (struct result_1) {0, .as0 = (struct ok_1) {r1.value}});
		}
		case 2: {
			struct exception e2 = _0.as2;
			
			return subscript_5(ctx, _closure->cb, (struct result_1) {1, .as1 = (struct err_0) {e2}});
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
/* callback!<?t> void(f fut<nat>, cb fun-act1<void, result<nat, exception>>) */
struct void_ callback__e_1(struct ctx* ctx, struct fut_0* f, struct fun_act1_0 cb) {
	struct callback__e_1__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct callback__e_1__lambda0));
	temp0 = (struct callback__e_1__lambda0*) _0;
	
	*temp0 = (struct callback__e_1__lambda0) {f, cb};
	return with_lock_0(ctx, (&f->lk), (struct fun_act0_0) {1, .as1 = temp0});
}
/* subscript<void, result<?t, exception>> void(a fun-act1<void, result<nat, exception>>, p0 result<nat, exception>) */
struct void_ subscript_6(struct ctx* ctx, struct fun_act1_0 a, struct result_0 p0) {
	return call_w_ctx_147(a, ctx, p0);
}
/* call-w-ctx<void, result<nat, exception>> (generated) (generated) */
struct void_ call_w_ctx_147(struct fun_act1_0 a, struct ctx* ctx, struct result_0 p0) {
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
/* callback!<?t>.lambda0 void() */
struct void_ callback__e_1__lambda0(struct ctx* ctx, struct callback__e_1__lambda0* _closure) {
	struct fut_state_0 _0 = _closure->f->state;
	switch (_0.kind) {
		case 0: {
			struct fut_state_callbacks_0 cbs0 = _0.as0;
			
			struct fut_callback_node_0* temp0;
			uint8_t* _1 = alloc(ctx, sizeof(struct fut_callback_node_0));
			temp0 = (struct fut_callback_node_0*) _1;
			
			*temp0 = (struct fut_callback_node_0) {_closure->cb, cbs0.head};
			return (_closure->f->state = (struct fut_state_0) {0, .as0 = (struct fut_state_callbacks_0) {(struct opt_0) {1, .as1 = (struct some_0) {temp0}}}}, (struct void_) {});
		}
		case 1: {
			struct fut_state_resolved_0 r1 = _0.as1;
			
			return subscript_6(ctx, _closure->cb, (struct result_0) {0, .as0 = (struct ok_0) {r1.value}});
		}
		case 2: {
			struct exception e2 = _0.as2;
			
			return subscript_6(ctx, _closure->cb, (struct result_0) {1, .as1 = (struct err_0) {e2}});
		}
		default:
			return (struct void_) {};
	}
}
/* resolve-or-reject!<?t> void(f fut<nat>, result result<nat, exception>) */
struct void_ resolve_or_reject__e(struct ctx* ctx, struct fut_0* f, struct result_0 result) {
	struct fut_state_callbacks_0 callbacks0;
	struct resolve_or_reject__e__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct resolve_or_reject__e__lambda0));
	temp0 = (struct resolve_or_reject__e__lambda0*) _0;
	
	*temp0 = (struct resolve_or_reject__e__lambda0) {f, result};
	callbacks0 = with_lock_1(ctx, (&f->lk), (struct fun_act0_2) {0, .as0 = temp0});
	
	return call_callbacks__e(ctx, callbacks0.head, result);
}
/* with-lock<fut-state-callbacks<?t>> fut-state-callbacks<nat>(a lock, f fun-act0<fut-state-callbacks<nat>>) */
struct fut_state_callbacks_0 with_lock_1(struct ctx* ctx, struct lock* a, struct fun_act0_2 f) {
	acquire__e(a);
	struct fut_state_callbacks_0 res0;
	res0 = subscript_7(ctx, f);
	
	release__e(a);
	return res0;
}
/* subscript<?t> fut-state-callbacks<nat>(a fun-act0<fut-state-callbacks<nat>>) */
struct fut_state_callbacks_0 subscript_7(struct ctx* ctx, struct fun_act0_2 a) {
	return call_w_ctx_152(a, ctx);
}
/* call-w-ctx<fut-state-callbacks<nat>> (generated) (generated) */
struct fut_state_callbacks_0 call_w_ctx_152(struct fun_act0_2 a, struct ctx* ctx) {
	struct fun_act0_2 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct resolve_or_reject__e__lambda0* closure0 = _0.as0;
			
			return resolve_or_reject__e__lambda0(ctx, closure0);
		}
		default:
			return (struct fut_state_callbacks_0) {(struct opt_0) {0}};
	}
}
/* todo<fut-state-callbacks<?t>> fut-state-callbacks<nat>() */
struct fut_state_callbacks_0 todo_2(void) {
	(abort(), (struct void_) {});
	return (struct fut_state_callbacks_0) {(struct opt_0) {0}};
}
/* resolve-or-reject!<?t>.lambda0 fut-state-callbacks<nat>() */
struct fut_state_callbacks_0 resolve_or_reject__e__lambda0(struct ctx* ctx, struct resolve_or_reject__e__lambda0* _closure) {
	struct fut_state_callbacks_0 callbacks1;
	struct fut_state_0 _0 = _closure->f->state;
	switch (_0.kind) {
		case 0: {
			struct fut_state_callbacks_0 cbs0 = _0.as0;
			
			callbacks1 = cbs0;
			break;
		}
		case 1: {
			callbacks1 = todo_2();
			break;
		}
		case 2: {
			callbacks1 = todo_2();
			break;
		}
		default:
			(struct fut_state_callbacks_0) {(struct opt_0) {0}};
	}
	
	struct result_0 _1 = _closure->result;struct fut_state_0 _2;
	
	switch (_1.kind) {
		case 0: {
			struct ok_0 o2 = _1.as0;
			
			_2 = (struct fut_state_0) {1, .as1 = (struct fut_state_resolved_0) {o2.value}};
			break;
		}
		case 1: {
			struct err_0 e3 = _1.as1;
			
			struct exception ex4;
			ex4 = e3.value;
			
			_2 = (struct fut_state_0) {2, .as2 = ex4};
			break;
		}
		default:
			(struct fut_state_0) {0};
	}
	_closure->f->state = _2;
	return callbacks1;
}
/* call-callbacks!<?t> void(node opt<fut-callback-node<nat>>, value result<nat, exception>) */
struct void_ call_callbacks__e(struct ctx* ctx, struct opt_0 node, struct result_0 value) {
	top:;
	struct opt_0 _0 = node;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct some_0 s0 = _0.as1;
			
			struct void_ _1 = subscript_6(ctx, s0.value->cb, value);
			drop_0(_1);
			node = s0.value->next_node;
			value = value;
			goto top;
		}
		default:
			return (struct void_) {};
	}
}
/* drop<void> void(_ void) */
struct void_ drop_0(struct void_ _p0) {
	return (struct void_) {};
}
/* forward-to!<?out>.lambda0 void(it result<nat, exception>) */
struct void_ forward_to__e__lambda0(struct ctx* ctx, struct forward_to__e__lambda0* _closure, struct result_0 it) {
	return resolve_or_reject__e(ctx, _closure->to, it);
}
/* subscript<?out, ?in> fut<nat>(f fun-ref1<nat, void>, p0 void) */
struct fut_0* subscript_8(struct ctx* ctx, struct fun_ref1 f, struct void_ p0) {
	struct island* island0;
	island0 = get_island(ctx, f.island_and_exclusion.island);
	
	struct fut_0* res1;
	res1 = unresolved(ctx);
	
	struct subscript_8__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct subscript_8__lambda0));
	temp0 = (struct subscript_8__lambda0*) _0;
	
	*temp0 = (struct subscript_8__lambda0) {f, p0, res1};
	add_task_0(ctx, island0, f.island_and_exclusion.exclusion, (struct fun_act0_0) {3, .as3 = temp0});
	return res1;
}
/* get-island island(island-id nat) */
struct island* get_island(struct ctx* ctx, uint64_t island_id) {
	struct global_ctx* _0 = get_global_ctx(ctx);
	return subscript_9(ctx, _0->islands, island_id);
}
/* subscript<island> island(a arr<island>, index nat) */
struct island* subscript_9(struct ctx* ctx, struct arr_3 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	return noctx_at_1(a, index);
}
/* noctx-at<?t> island(a arr<island>, index nat) */
struct island* noctx_at_1(struct arr_3 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	hard_assert(_0);
	return subscript_10(a.data, index);
}
/* subscript<?t> island(a ptr<island>, n nat) */
struct island* subscript_10(struct island** a, uint64_t n) {
	return *(a + n);
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
	size_before0 = size_0(a);
	
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
	size_after3 = size_0(a);
	
	uint8_t _2 = _equal_0((size_before0 + 1u), size_after3);
	return hard_assert(_2);
}
/* size nat(a task-queue) */
uint64_t size_0(struct task_queue* a) {
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
struct void_ catch(struct ctx* ctx, struct fun_act0_0 try, struct fun_act1_3 catcher) {
	struct exception_ctx* _0 = get_exception_ctx(ctx);
	return catch_with_exception_ctx(ctx, _0, try, catcher);
}
/* catch-with-exception-ctx<?t> void(ec exception-ctx, try fun-act0<void>, catcher fun-act1<void, exception>) */
struct void_ catch_with_exception_ctx(struct ctx* ctx, struct exception_ctx* ec, struct fun_act0_0 try, struct fun_act1_3 catcher) {
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
		res4 = subscript_4(ctx, try);
		
		ec->jmp_buf_ptr = old_jmp_buf1;
		ec->thrown_exception = old_thrown_exception0;
		return res4;
	} else {
		int32_t _3 = number_to_throw(ctx);
		uint8_t _4 = _equal_2(setjmp_result3, _3);
		assert_0(ctx, _4);
		struct exception thrown_exception5;
		thrown_exception5 = ec->thrown_exception;
		
		ec->jmp_buf_ptr = old_jmp_buf1;
		ec->thrown_exception = old_thrown_exception0;
		return subscript_11(ctx, catcher, thrown_exception5);
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
/* subscript<?t, exception> void(a fun-act1<void, exception>, p0 exception) */
struct void_ subscript_11(struct ctx* ctx, struct fun_act1_3 a, struct exception p0) {
	return call_w_ctx_181(a, ctx, p0);
}
/* call-w-ctx<void, exception> (generated) (generated) */
struct void_ call_w_ctx_181(struct fun_act1_3 a, struct ctx* ctx, struct exception p0) {
	struct fun_act1_3 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct subscript_8__lambda0__lambda1* closure0 = _0.as0;
			
			return subscript_8__lambda0__lambda1(ctx, closure0, p0);
		}
		case 1: {
			struct subscript_13__lambda0__lambda1* closure1 = _0.as1;
			
			return subscript_13__lambda0__lambda1(ctx, closure1, p0);
		}
		default:
			return (struct void_) {};
	}
}
/* subscript<fut<?r>, ?p0> fut<nat>(a fun-act1<fut<nat>, void>, p0 void) */
struct fut_0* subscript_12(struct ctx* ctx, struct fun_act1_2 a, struct void_ p0) {
	return call_w_ctx_183(a, ctx, p0);
}
/* call-w-ctx<gc-ptr(fut<nat>), void> (generated) (generated) */
struct fut_0* call_w_ctx_183(struct fun_act1_2 a, struct ctx* ctx, struct void_ p0) {
	struct fun_act1_2 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct then2__lambda0* closure0 = _0.as0;
			
			return then2__lambda0(ctx, closure0, p0);
		}
		default:
			return NULL;
	}
}
/* subscript<?out, ?in>.lambda0.lambda0 void() */
struct void_ subscript_8__lambda0__lambda0(struct ctx* ctx, struct subscript_8__lambda0__lambda0* _closure) {
	struct fut_0* _0 = subscript_12(ctx, _closure->f.fun, _closure->p0);
	return forward_to__e(ctx, _0, _closure->res);
}
/* reject!<?r> void(f fut<nat>, e exception) */
struct void_ reject__e(struct ctx* ctx, struct fut_0* f, struct exception e) {
	return resolve_or_reject__e(ctx, f, (struct result_0) {1, .as1 = (struct err_0) {e}});
}
/* subscript<?out, ?in>.lambda0.lambda1 void(it exception) */
struct void_ subscript_8__lambda0__lambda1(struct ctx* ctx, struct subscript_8__lambda0__lambda1* _closure, struct exception it) {
	return reject__e(ctx, _closure->res, it);
}
/* subscript<?out, ?in>.lambda0 void() */
struct void_ subscript_8__lambda0(struct ctx* ctx, struct subscript_8__lambda0* _closure) {
	struct subscript_8__lambda0__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct subscript_8__lambda0__lambda0));
	temp0 = (struct subscript_8__lambda0__lambda0*) _0;
	
	*temp0 = (struct subscript_8__lambda0__lambda0) {_closure->f, _closure->p0, _closure->res};
	struct subscript_8__lambda0__lambda1* temp1;
	uint8_t* _1 = alloc(ctx, sizeof(struct subscript_8__lambda0__lambda1));
	temp1 = (struct subscript_8__lambda0__lambda1*) _1;
	
	*temp1 = (struct subscript_8__lambda0__lambda1) {_closure->res};
	return catch(ctx, (struct fun_act0_0) {2, .as2 = temp0}, (struct fun_act1_3) {0, .as0 = temp1});
}
/* then<?out, void>.lambda0 void(result result<void, exception>) */
struct void_ then__lambda0(struct ctx* ctx, struct then__lambda0* _closure, struct result_1 result) {
	struct result_1 _0 = result;
	switch (_0.kind) {
		case 0: {
			struct ok_1 o0 = _0.as0;
			
			struct fut_0* _1 = subscript_8(ctx, _closure->cb, o0.value);
			return forward_to__e(ctx, _1, _closure->res);
		}
		case 1: {
			struct err_0 e1 = _0.as1;
			
			return reject__e(ctx, _closure->res, e1.value);
		}
		default:
			return (struct void_) {};
	}
}
/* subscript<?out> fut<nat>(f fun-ref0<nat>) */
struct fut_0* subscript_13(struct ctx* ctx, struct fun_ref0 f) {
	struct fut_0* res0;
	res0 = unresolved(ctx);
	
	struct island* _0 = get_island(ctx, f.island_and_exclusion.island);
	struct subscript_13__lambda0* temp0;
	uint8_t* _1 = alloc(ctx, sizeof(struct subscript_13__lambda0));
	temp0 = (struct subscript_13__lambda0*) _1;
	
	*temp0 = (struct subscript_13__lambda0) {f, res0};
	add_task_0(ctx, _0, f.island_and_exclusion.exclusion, (struct fun_act0_0) {5, .as5 = temp0});
	return res0;
}
/* subscript<fut<?r>> fut<nat>(a fun-act0<fut<nat>>) */
struct fut_0* subscript_14(struct ctx* ctx, struct fun_act0_1 a) {
	return call_w_ctx_191(a, ctx);
}
/* call-w-ctx<gc-ptr(fut<nat>)> (generated) (generated) */
struct fut_0* call_w_ctx_191(struct fun_act0_1 a, struct ctx* ctx) {
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
struct void_ subscript_13__lambda0__lambda0(struct ctx* ctx, struct subscript_13__lambda0__lambda0* _closure) {
	struct fut_0* _0 = subscript_14(ctx, _closure->f.fun);
	return forward_to__e(ctx, _0, _closure->res);
}
/* subscript<?out>.lambda0.lambda1 void(it exception) */
struct void_ subscript_13__lambda0__lambda1(struct ctx* ctx, struct subscript_13__lambda0__lambda1* _closure, struct exception it) {
	return reject__e(ctx, _closure->res, it);
}
/* subscript<?out>.lambda0 void() */
struct void_ subscript_13__lambda0(struct ctx* ctx, struct subscript_13__lambda0* _closure) {
	struct subscript_13__lambda0__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct subscript_13__lambda0__lambda0));
	temp0 = (struct subscript_13__lambda0__lambda0*) _0;
	
	*temp0 = (struct subscript_13__lambda0__lambda0) {_closure->f, _closure->res};
	struct subscript_13__lambda0__lambda1* temp1;
	uint8_t* _1 = alloc(ctx, sizeof(struct subscript_13__lambda0__lambda1));
	temp1 = (struct subscript_13__lambda0__lambda1*) _1;
	
	*temp1 = (struct subscript_13__lambda0__lambda1) {_closure->res};
	return catch(ctx, (struct fun_act0_0) {4, .as4 = temp0}, (struct fun_act1_3) {1, .as1 = temp1});
}
/* then2<nat>.lambda0 fut<nat>(ignore void) */
struct fut_0* then2__lambda0(struct ctx* ctx, struct then2__lambda0* _closure, struct void_ ignore) {
	return subscript_13(ctx, _closure->cb);
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
	*temp0 = (struct fut_1) {_1, (struct fut_state_1) {1, .as1 = (struct fut_state_resolved_1) {value}}};
	return temp0;
}
/* tail<ptr<char>> arr<ptr<char>>(a arr<ptr<char>>) */
struct arr_4 tail_1(struct ctx* ctx, struct arr_4 a) {
	uint8_t _0 = empty__q_2(a);
	forbid_0(ctx, _0);
	struct arrow_0 _1 = _arrow_0(ctx, 1u, a.size);
	return subscript_15(ctx, a, _1);
}
/* empty?<?t> bool(a arr<ptr<char>>) */
uint8_t empty__q_2(struct arr_4 a) {
	return _equal_0(a.size, 0u);
}
/* subscript<?t> arr<ptr<char>>(a arr<ptr<char>>, range arrow<nat, nat>) */
struct arr_4 subscript_15(struct ctx* ctx, struct arr_4 a, struct arrow_0 range) {
	uint8_t _0 = _lessOrEqual(range.from, range.to);
	assert_0(ctx, _0);
	uint8_t _1 = _lessOrEqual(range.to, a.size);
	assert_0(ctx, _1);
	uint64_t _2 = _minus_2(ctx, range.to, range.from);
	return (struct arr_4) {_2, (a.data + range.from)};
}
/* map<arr<char>, ptr<char>> arr<arr<char>>(a arr<ptr<char>>, mapper fun-act1<arr<char>, ptr<char>>) */
struct arr_1 map_0(struct ctx* ctx, struct arr_4 a, struct fun_act1_4 mapper) {
	struct map_0__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct map_0__lambda0));
	temp0 = (struct map_0__lambda0*) _0;
	
	*temp0 = (struct map_0__lambda0) {mapper, a};
	return make_arr_0(ctx, a.size, (struct fun_act1_5) {0, .as0 = temp0});
}
/* make-arr<?out> arr<arr<char>>(size nat, f fun-act1<arr<char>, nat>) */
struct arr_1 make_arr_0(struct ctx* ctx, uint64_t size, struct fun_act1_5 f) {
	struct arr_0* data0;
	data0 = alloc_uninitialized_1(ctx, size);
	
	fill_ptr_range_0(ctx, data0, size, f);
	return (struct arr_1) {size, data0};
}
/* alloc-uninitialized<?t> ptr<arr<char>>(size nat) */
struct arr_0* alloc_uninitialized_1(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(struct arr_0)));
	return (struct arr_0*) _0;
}
/* fill-ptr-range<?t> void(begin ptr<arr<char>>, size nat, f fun-act1<arr<char>, nat>) */
struct void_ fill_ptr_range_0(struct ctx* ctx, struct arr_0* begin, uint64_t size, struct fun_act1_5 f) {
	return fill_ptr_range_recur_0(ctx, begin, 0u, size, f);
}
/* fill-ptr-range-recur<?t> void(begin ptr<arr<char>>, i nat, size nat, f fun-act1<arr<char>, nat>) */
struct void_ fill_ptr_range_recur_0(struct ctx* ctx, struct arr_0* begin, uint64_t i, uint64_t size, struct fun_act1_5 f) {
	top:;
	uint8_t _0 = _notEqual_1(i, size);
	if (_0) {
		struct arr_0 _1 = subscript_16(ctx, f, i);
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
/* subscript<?t, nat> arr<char>(a fun-act1<arr<char>, nat>, p0 nat) */
struct arr_0 subscript_16(struct ctx* ctx, struct fun_act1_5 a, uint64_t p0) {
	return call_w_ctx_208(a, ctx, p0);
}
/* call-w-ctx<arr<char>, nat-64> (generated) (generated) */
struct arr_0 call_w_ctx_208(struct fun_act1_5 a, struct ctx* ctx, uint64_t p0) {
	struct fun_act1_5 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct map_0__lambda0* closure0 = _0.as0;
			
			return map_0__lambda0(ctx, closure0, p0);
		}
		case 1: {
			struct map_1__lambda0* closure1 = _0.as1;
			
			return map_1__lambda0(ctx, closure1, p0);
		}
		case 2: {
			struct mut_arr_1__lambda0* closure2 = _0.as2;
			
			return mut_arr_1__lambda0(ctx, closure2, p0);
		}
		default:
			return (struct arr_0) {0, NULL};
	}
}
/* subscript<?out, ?in> arr<char>(a fun-act1<arr<char>, ptr<char>>, p0 ptr<char>) */
struct arr_0 subscript_17(struct ctx* ctx, struct fun_act1_4 a, char* p0) {
	return call_w_ctx_210(a, ctx, p0);
}
/* call-w-ctx<arr<char>, raw-ptr(char)> (generated) (generated) */
struct arr_0 call_w_ctx_210(struct fun_act1_4 a, struct ctx* ctx, char* p0) {
	struct fun_act1_4 _0 = a;
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
char* subscript_18(struct ctx* ctx, struct arr_4 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	return noctx_at_2(a, index);
}
/* noctx-at<?t> ptr<char>(a arr<ptr<char>>, index nat) */
char* noctx_at_2(struct arr_4 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	hard_assert(_0);
	return subscript_19(a.data, index);
}
/* subscript<?t> ptr<char>(a ptr<ptr<char>>, n nat) */
char* subscript_19(char** a, uint64_t n) {
	return *(a + n);
}
/* map<arr<char>, ptr<char>>.lambda0 arr<char>(i nat) */
struct arr_0 map_0__lambda0(struct ctx* ctx, struct map_0__lambda0* _closure, uint64_t i) {
	char* _0 = subscript_18(ctx, _closure->a, i);
	return subscript_17(ctx, _closure->mapper, _0);
}
/* to-str arr<char>(a ptr<char>) */
struct arr_0 to_str_1(char* a) {
	char* _0 = find_cstr_end(a);
	return arr_from_begin_end(a, _0);
}
/* arr-from-begin-end<char> arr<char>(begin ptr<char>, end ptr<char>) */
struct arr_0 arr_from_begin_end(char* begin, char* end) {
	uint64_t _0 = _minus_3(end, begin);
	return (struct arr_0) {_0, begin};
}
/* -<?t> nat(a ptr<char>, b ptr<char>) */
uint64_t _minus_3(char* a, char* b) {
	return (((uint64_t) a - (uint64_t) b) / sizeof(char));
}
/* find-cstr-end ptr<char>(a ptr<char>) */
char* find_cstr_end(char* a) {
	return find_char_in_cstr(a, 0u);
}
/* find-char-in-cstr ptr<char>(a ptr<char>, c char) */
char* find_char_in_cstr(char* a, char c) {
	top:;
	uint8_t _0 = _equal_3(*a, c);
	if (_0) {
		return a;
	} else {
		uint8_t _1 = _equal_3(*a, 0u);
		if (_1) {
			return todo_3();
		} else {
			char* _2 = incr_4(a);
			a = _2;
			c = c;
			goto top;
		}
	}
}
/* ==<char> bool(a char, b char) */
uint8_t _equal_3(char a, char b) {
	struct comparison _0 = compare_221(a, b);
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
struct comparison compare_221(char a, char b) {
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
/* todo<ptr<char>> ptr<char>() */
char* todo_3(void) {
	(abort(), (struct void_) {});
	return NULL;
}
/* incr<char> ptr<char>(p ptr<char>) */
char* incr_4(char* p) {
	return (p + 1u);
}
/* add-first-task.lambda0.lambda0 arr<char>(it ptr<char>) */
struct arr_0 add_first_task__lambda0__lambda0(struct ctx* ctx, struct void_ _closure, char* it) {
	return to_str_1(it);
}
/* add-first-task.lambda0 fut<nat>() */
struct fut_0* add_first_task__lambda0(struct ctx* ctx, struct add_first_task__lambda0* _closure) {
	struct arr_4 args0;
	args0 = tail_1(ctx, _closure->all_args);
	
	struct arr_1 _0 = map_0(ctx, args0, (struct fun_act1_4) {0, .as0 = (struct void_) {}});
	return _closure->main_ptr(ctx, _0);
}
/* handle-exceptions<nat> void(a fut<nat>) */
struct void_ handle_exceptions(struct ctx* ctx, struct fut_0* a) {
	return callback__e_1(ctx, a, (struct fun_act1_0) {1, .as1 = (struct void_) {}});
}
/* subscript<void, exception> void(a fun1<void, exception>, p0 exception) */
struct void_ subscript_20(struct ctx* ctx, struct fun1_0 a, struct exception p0) {
	return call_w_ctx_228(a, ctx, p0);
}
/* call-w-ctx<void, exception> (generated) (generated) */
struct void_ call_w_ctx_228(struct fun1_0 a, struct ctx* ctx, struct exception p0) {
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
			struct err_0 e0 = _0.as1;
			
			struct island* _1 = get_cur_island(ctx);
			struct fun1_0 _2 = exception_handler(ctx, _1);
			return subscript_20(ctx, _2, e0.value);
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
struct fut_0* call_w_ctx_233(struct fun_act2_0 a, struct ctx* ctx, struct arr_4 p0, fun_ptr2 p1) {
	struct fun_act2_0 _0 = a;
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
		create_one_thread(_1, (uint8_t*) thread_arg_ptr0, thread_fun);
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
	uint8_t _0 = has__q_0(a->head);
	return not(_0);
}
/* has?<task-queue-node> bool(a opt<task-queue-node>) */
uint8_t has__q_0(struct opt_2 a) {
	uint8_t _0 = empty__q_4(a);
	return not(_0);
}
/* empty?<?t> bool(a opt<task-queue-node>) */
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
	struct choose_task_result _0 = choose_task_recur(gctx->islands, 0u, cur_time0, 0, (struct opt_8) {0, .as0 = (struct none) {}});
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
		return todo_4();
	}
}
/* clock-monotonic int32() */
int32_t clock_monotonic(void) {
	return 1;
}
/* todo<nat> nat() */
uint64_t todo_4(void) {
	(abort(), (struct void_) {});
	return 0;
}
/* choose-task-recur choose-task-result(islands arr<island>, i nat, cur-time nat, any-tasks? bool, first-task-time opt<nat>) */
struct choose_task_result choose_task_recur(struct arr_3 islands, uint64_t i, uint64_t cur_time, uint8_t any_tasks__q, struct opt_8 first_task_time) {
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
				
				struct opt_8 new_first_task_time5;
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
			res2 = (struct choose_task_in_island_result) {2, .as2 = (struct no_task) {1, (struct opt_8) {0, .as0 = (struct none) {}}}};
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
			res4 = (struct pop_task_result) {1, .as1 = (struct no_task) {0, (struct opt_8) {0, .as0 = (struct none) {}}}};
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
					struct opt_8 _3 = to_opt_time(task3.time);
					res4 = pop_recur__e(head2, exclusions0, cur_time, _3);
				} else {
					a->head = head2->next;
					res4 = (struct pop_task_result) {0, .as0 = head2->task};
				}
			} else {
				res4 = (struct pop_task_result) {1, .as1 = (struct no_task) {1, (struct opt_8) {1, .as1 = (struct some_8) {task3.time}}}};
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
/* contains?<?t> bool(a arr<nat>, value nat) */
uint8_t contains__q_1(struct arr_2 a, uint64_t value) {
	return contains_recur__q_0(a, value, 0u);
}
/* contains-recur?<?t> bool(a arr<nat>, value nat, i nat) */
uint8_t contains_recur__q_0(struct arr_2 a, uint64_t value, uint64_t i) {
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
/* noctx-at<?t> nat(a arr<nat>, index nat) */
uint64_t noctx_at_3(struct arr_2 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	hard_assert(_0);
	return subscript_21(a.data, index);
}
/* subscript<?t> nat(a ptr<nat>, n nat) */
uint64_t subscript_21(uint64_t* a, uint64_t n) {
	return *(a + n);
}
/* temp-as-arr<?t> arr<nat>(a mut-list<nat>) */
struct arr_2 temp_as_arr_0(struct mut_list_0* a) {
	struct mut_arr_0 _0 = temp_as_mut_arr(a);
	return temp_as_arr_1(_0);
}
/* temp-as-arr<?t> arr<nat>(a mut-arr<nat>) */
struct arr_2 temp_as_arr_1(struct mut_arr_0 a) {
	return a.inner;
}
/* temp-as-mut-arr<?t> mut-arr<nat>(a mut-list<nat>) */
struct mut_arr_0 temp_as_mut_arr(struct mut_list_0* a) {
	uint64_t* _0 = data_0(a);
	return mut_arr_0(a->size, _0);
}
/* data<?t> ptr<nat>(a mut-list<nat>) */
uint64_t* data_0(struct mut_list_0* a) {
	return data_1(a->backing);
}
/* data<?t> ptr<nat>(a mut-arr<nat>) */
uint64_t* data_1(struct mut_arr_0 a) {
	return a.inner.data;
}
/* pop-recur! pop-task-result(prev task-queue-node, exclusions mut-list<nat>, cur-time nat, first-task-time opt<nat>) */
struct pop_task_result pop_recur__e(struct task_queue_node* prev, struct mut_list_0* exclusions, uint64_t cur_time, struct opt_8 first_task_time) {
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
					struct opt_8 _3 = first_task_time;struct opt_8 _4;
					
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
							(struct opt_8) {0};
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
				return (struct pop_task_result) {1, .as1 = (struct no_task) {1, (struct opt_8) {1, .as1 = (struct some_8) {task2.time}}}};
			}
		}
		default:
			return (struct pop_task_result) {0};
	}
}
/* to-opt-time opt<nat>(a nat) */
struct opt_8 to_opt_time(uint64_t a) {
	uint64_t _0 = no_timestamp();
	uint8_t _1 = _equal_0(a, _0);
	if (_1) {
		return (struct opt_8) {0, .as0 = (struct none) {}};
	} else {
		return (struct opt_8) {1, .as1 = (struct some_8) {a}};
	}
}
/* push-capacity-must-be-sufficient!<nat> void(a mut-list<nat>, value nat) */
struct void_ push_capacity_must_be_sufficient__e(struct mut_list_0* a, uint64_t value) {
	uint64_t _0 = capacity_0(a);
	uint8_t _1 = _less_0(a->size, _0);
	hard_assert(_1);
	uint64_t old_size0;
	old_size0 = a->size;
	
	uint64_t _2 = noctx_incr(old_size0);
	a->size = _2;
	return noctx_set_at__e_0(a, old_size0, value);
}
/* capacity<?t> nat(a mut-list<nat>) */
uint64_t capacity_0(struct mut_list_0* a) {
	return size_1(a->backing);
}
/* size<?t> nat(a mut-arr<nat>) */
uint64_t size_1(struct mut_arr_0 a) {
	return a.inner.size;
}
/* noctx-set-at!<?t> void(a mut-list<nat>, index nat, value nat) */
struct void_ noctx_set_at__e_0(struct mut_list_0* a, uint64_t index, uint64_t value) {
	uint8_t _0 = _less_0(index, a->size);
	hard_assert(_0);
	uint64_t* _1 = data_0(a);
	return set_subscript_2(_1, index, value);
}
/* set-subscript<?t> void(a ptr<nat>, n nat, value nat) */
struct void_ set_subscript_2(uint64_t* a, uint64_t n, uint64_t value) {
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
struct opt_8 min_time(struct opt_8 a, struct opt_8 b) {
	struct opt_8 _0 = a;
	switch (_0.kind) {
		case 0: {
			return b;
		}
		case 1: {
			struct some_8 sa0 = _0.as1;
			
			struct opt_8 _1 = b;
			switch (_1.kind) {
				case 0: {
					return a;
				}
				case 1: {
					struct some_8 sb1 = _1.as1;
					
					uint64_t _2 = min(sa0.value, sb1.value);
					return (struct opt_8) {1, .as1 = (struct some_8) {_2}};
				}
				default:
					return (struct opt_8) {0};
			}
		}
		default:
			return (struct opt_8) {0};
	}
}
/* min<nat> nat(a nat, b nat) */
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
			
			call_w_ctx_140(task1.action, (&ctx2));
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
/* noctx-must-remove-unordered-recur!<?t> void(a mut-list<nat>, index nat, value nat) */
struct void_ noctx_must_remove_unordered_recur__e(struct mut_list_0* a, uint64_t index, uint64_t value) {
	top:;
	uint8_t _0 = _equal_0(index, a->size);
	if (_0) {
		return todo_0();
	} else {
		uint64_t _1 = noctx_at_4(a, index);
		uint8_t _2 = _equal_0(_1, value);
		if (_2) {
			uint64_t _3 = noctx_remove_unordered_at__e(a, index);
			return drop_1(_3);
		} else {
			uint64_t _4 = noctx_incr(index);
			a = a;
			index = _4;
			value = value;
			goto top;
		}
	}
}
/* noctx-at<?t> nat(a mut-list<nat>, index nat) */
uint64_t noctx_at_4(struct mut_list_0* a, uint64_t index) {
	uint8_t _0 = _less_0(index, a->size);
	hard_assert(_0);
	uint64_t* _1 = data_0(a);
	return subscript_21(_1, index);
}
/* drop<?t> void(_ nat) */
struct void_ drop_1(uint64_t _p0) {
	return (struct void_) {};
}
/* noctx-remove-unordered-at!<?t> nat(a mut-list<nat>, index nat) */
uint64_t noctx_remove_unordered_at__e(struct mut_list_0* a, uint64_t index) {
	uint64_t res0;
	res0 = noctx_at_4(a, index);
	
	uint64_t _0 = noctx_last(a);
	noctx_set_at__e_0(a, index, _0);
	uint64_t _1 = noctx_decr(a->size);
	a->size = _1;
	return res0;
}
/* noctx-last<?t> nat(a mut-list<nat>) */
uint64_t noctx_last(struct mut_list_0* a) {
	uint8_t _0 = empty__q_5(a);
	hard_forbid(_0);
	uint64_t _1 = noctx_decr(a->size);
	return noctx_at_4(a, _1);
}
/* empty?<?t> bool(a mut-list<nat>) */
uint8_t empty__q_5(struct mut_list_0* a) {
	return _equal_0(a->size, 0u);
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
	(memset((uint8_t*) gc->mark_begin, 0u, gc->size_words), (struct void_) {});
	struct mark_ctx mark_ctx0;
	mark_ctx0 = (struct mark_ctx) {gc->size_words, gc->mark_begin, gc->data_begin};
	
	mark_visit_290((&mark_ctx0), gc_root);
	gc->mark_cur = gc->mark_begin;
	gc->data_cur = gc->data_begin;
	clear_free_mem(gc->mark_begin, gc->mark_end, gc->data_begin);
	return validate_gc(gc);
}
/* mark-visit<island-gc-root> (generated) (generated) */
struct void_ mark_visit_290(struct mark_ctx* mark_ctx, struct island_gc_root value) {
	return mark_visit_291(mark_ctx, value.tasks);
}
/* mark-visit<task-queue> (generated) (generated) */
struct void_ mark_visit_291(struct mark_ctx* mark_ctx, struct task_queue value) {
	mark_visit_292(mark_ctx, value.head);
	return mark_visit_346(mark_ctx, value.currently_running_exclusions);
}
/* mark-visit<opt<task-queue-node>> (generated) (generated) */
struct void_ mark_visit_292(struct mark_ctx* mark_ctx, struct opt_2 value) {
	struct opt_2 _0 = value;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct some_2 value1 = _0.as1;
			
			return mark_visit_293(mark_ctx, value1);
		}
		default:
			return (struct void_) {};
	}
}
/* mark-visit<some<task-queue-node>> (generated) (generated) */
struct void_ mark_visit_293(struct mark_ctx* mark_ctx, struct some_2 value) {
	return mark_visit_345(mark_ctx, value.value);
}
/* mark-visit<task-queue-node> (generated) (generated) */
struct void_ mark_visit_294(struct mark_ctx* mark_ctx, struct task_queue_node value) {
	mark_visit_295(mark_ctx, value.task);
	return mark_visit_292(mark_ctx, value.next);
}
/* mark-visit<task> (generated) (generated) */
struct void_ mark_visit_295(struct mark_ctx* mark_ctx, struct task value) {
	return mark_visit_296(mark_ctx, value.action);
}
/* mark-visit<fun-act0<void>> (generated) (generated) */
struct void_ mark_visit_296(struct mark_ctx* mark_ctx, struct fun_act0_0 value) {
	struct fun_act0_0 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct callback__e_0__lambda0* value0 = _0.as0;
			
			return mark_visit_334(mark_ctx, value0);
		}
		case 1: {
			struct callback__e_1__lambda0* value1 = _0.as1;
			
			return mark_visit_336(mark_ctx, value1);
		}
		case 2: {
			struct subscript_8__lambda0__lambda0* value2 = _0.as2;
			
			return mark_visit_338(mark_ctx, value2);
		}
		case 3: {
			struct subscript_8__lambda0* value3 = _0.as3;
			
			return mark_visit_340(mark_ctx, value3);
		}
		case 4: {
			struct subscript_13__lambda0__lambda0* value4 = _0.as4;
			
			return mark_visit_342(mark_ctx, value4);
		}
		case 5: {
			struct subscript_13__lambda0* value5 = _0.as5;
			
			return mark_visit_344(mark_ctx, value5);
		}
		default:
			return (struct void_) {};
	}
}
/* mark-visit<callback!<?in>.lambda0> (generated) (generated) */
struct void_ mark_visit_297(struct mark_ctx* mark_ctx, struct callback__e_0__lambda0 value) {
	mark_visit_333(mark_ctx, value.f);
	return mark_visit_304(mark_ctx, value.cb);
}
/* mark-visit<fut<void>> (generated) (generated) */
struct void_ mark_visit_298(struct mark_ctx* mark_ctx, struct fut_1 value) {
	return mark_visit_299(mark_ctx, value.state);
}
/* mark-visit<fut-state<void>> (generated) (generated) */
struct void_ mark_visit_299(struct mark_ctx* mark_ctx, struct fut_state_1 value) {
	struct fut_state_1 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct fut_state_callbacks_1 value0 = _0.as0;
			
			return mark_visit_300(mark_ctx, value0);
		}
		case 1: {
			return (struct void_) {};
		}
		case 2: {
			struct exception value2 = _0.as2;
			
			return mark_visit_326(mark_ctx, value2);
		}
		default:
			return (struct void_) {};
	}
}
/* mark-visit<fut-state-callbacks<void>> (generated) (generated) */
struct void_ mark_visit_300(struct mark_ctx* mark_ctx, struct fut_state_callbacks_1 value) {
	return mark_visit_301(mark_ctx, value.head);
}
/* mark-visit<opt<fut-callback-node<void>>> (generated) (generated) */
struct void_ mark_visit_301(struct mark_ctx* mark_ctx, struct opt_7 value) {
	struct opt_7 _0 = value;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct some_7 value1 = _0.as1;
			
			return mark_visit_302(mark_ctx, value1);
		}
		default:
			return (struct void_) {};
	}
}
/* mark-visit<some<fut-callback-node<void>>> (generated) (generated) */
struct void_ mark_visit_302(struct mark_ctx* mark_ctx, struct some_7 value) {
	return mark_visit_332(mark_ctx, value.value);
}
/* mark-visit<fut-callback-node<void>> (generated) (generated) */
struct void_ mark_visit_303(struct mark_ctx* mark_ctx, struct fut_callback_node_1 value) {
	mark_visit_304(mark_ctx, value.cb);
	return mark_visit_301(mark_ctx, value.next_node);
}
/* mark-visit<fun-act1<void, result<void, exception>>> (generated) (generated) */
struct void_ mark_visit_304(struct mark_ctx* mark_ctx, struct fun_act1_1 value) {
	struct fun_act1_1 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct then__lambda0* value0 = _0.as0;
			
			return mark_visit_331(mark_ctx, value0);
		}
		default:
			return (struct void_) {};
	}
}
/* mark-visit<then<?out, void>.lambda0> (generated) (generated) */
struct void_ mark_visit_305(struct mark_ctx* mark_ctx, struct then__lambda0 value) {
	mark_visit_306(mark_ctx, value.cb);
	return mark_visit_323(mark_ctx, value.res);
}
/* mark-visit<fun-ref1<nat, void>> (generated) (generated) */
struct void_ mark_visit_306(struct mark_ctx* mark_ctx, struct fun_ref1 value) {
	return mark_visit_307(mark_ctx, value.fun);
}
/* mark-visit<fun-act1<fut<nat>, void>> (generated) (generated) */
struct void_ mark_visit_307(struct mark_ctx* mark_ctx, struct fun_act1_2 value) {
	struct fun_act1_2 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct then2__lambda0* value0 = _0.as0;
			
			return mark_visit_314(mark_ctx, value0);
		}
		default:
			return (struct void_) {};
	}
}
/* mark-visit<then2<nat>.lambda0> (generated) (generated) */
struct void_ mark_visit_308(struct mark_ctx* mark_ctx, struct then2__lambda0 value) {
	return mark_visit_309(mark_ctx, value.cb);
}
/* mark-visit<fun-ref0<nat>> (generated) (generated) */
struct void_ mark_visit_309(struct mark_ctx* mark_ctx, struct fun_ref0 value) {
	return mark_visit_310(mark_ctx, value.fun);
}
/* mark-visit<fun-act0<fut<nat>>> (generated) (generated) */
struct void_ mark_visit_310(struct mark_ctx* mark_ctx, struct fun_act0_1 value) {
	struct fun_act0_1 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct add_first_task__lambda0* value0 = _0.as0;
			
			return mark_visit_313(mark_ctx, value0);
		}
		default:
			return (struct void_) {};
	}
}
/* mark-visit<add-first-task.lambda0> (generated) (generated) */
struct void_ mark_visit_311(struct mark_ctx* mark_ctx, struct add_first_task__lambda0 value) {
	return mark_arr_312(mark_ctx, value.all_args);
}
/* mark-arr<raw-ptr(char)> (generated) (generated) */
struct void_ mark_arr_312(struct mark_ctx* mark_ctx, struct arr_4 a) {
	uint8_t dropped0;
	dropped0 = mark(mark_ctx, (uint8_t*) a.data, (a.size * sizeof(char*)));
	
	return (struct void_) {};
}
/* mark-visit<gc-ptr(add-first-task.lambda0)> (generated) (generated) */
struct void_ mark_visit_313(struct mark_ctx* mark_ctx, struct add_first_task__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, (uint8_t*) value, sizeof(struct add_first_task__lambda0));
	if (_0) {
		return mark_visit_311(mark_ctx, *value);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(then2<nat>.lambda0)> (generated) (generated) */
struct void_ mark_visit_314(struct mark_ctx* mark_ctx, struct then2__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, (uint8_t*) value, sizeof(struct then2__lambda0));
	if (_0) {
		return mark_visit_308(mark_ctx, *value);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<fut<nat>> (generated) (generated) */
struct void_ mark_visit_315(struct mark_ctx* mark_ctx, struct fut_0 value) {
	return mark_visit_316(mark_ctx, value.state);
}
/* mark-visit<fut-state<nat>> (generated) (generated) */
struct void_ mark_visit_316(struct mark_ctx* mark_ctx, struct fut_state_0 value) {
	struct fut_state_0 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct fut_state_callbacks_0 value0 = _0.as0;
			
			return mark_visit_317(mark_ctx, value0);
		}
		case 1: {
			return (struct void_) {};
		}
		case 2: {
			struct exception value2 = _0.as2;
			
			return mark_visit_326(mark_ctx, value2);
		}
		default:
			return (struct void_) {};
	}
}
/* mark-visit<fut-state-callbacks<nat>> (generated) (generated) */
struct void_ mark_visit_317(struct mark_ctx* mark_ctx, struct fut_state_callbacks_0 value) {
	return mark_visit_318(mark_ctx, value.head);
}
/* mark-visit<opt<fut-callback-node<nat>>> (generated) (generated) */
struct void_ mark_visit_318(struct mark_ctx* mark_ctx, struct opt_0 value) {
	struct opt_0 _0 = value;
	switch (_0.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct some_0 value1 = _0.as1;
			
			return mark_visit_319(mark_ctx, value1);
		}
		default:
			return (struct void_) {};
	}
}
/* mark-visit<some<fut-callback-node<nat>>> (generated) (generated) */
struct void_ mark_visit_319(struct mark_ctx* mark_ctx, struct some_0 value) {
	return mark_visit_325(mark_ctx, value.value);
}
/* mark-visit<fut-callback-node<nat>> (generated) (generated) */
struct void_ mark_visit_320(struct mark_ctx* mark_ctx, struct fut_callback_node_0 value) {
	mark_visit_321(mark_ctx, value.cb);
	return mark_visit_318(mark_ctx, value.next_node);
}
/* mark-visit<fun-act1<void, result<nat, exception>>> (generated) (generated) */
struct void_ mark_visit_321(struct mark_ctx* mark_ctx, struct fun_act1_0 value) {
	struct fun_act1_0 _0 = value;
	switch (_0.kind) {
		case 0: {
			struct forward_to__e__lambda0* value0 = _0.as0;
			
			return mark_visit_324(mark_ctx, value0);
		}
		case 1: {
			return (struct void_) {};
		}
		default:
			return (struct void_) {};
	}
}
/* mark-visit<forward-to!<?out>.lambda0> (generated) (generated) */
struct void_ mark_visit_322(struct mark_ctx* mark_ctx, struct forward_to__e__lambda0 value) {
	return mark_visit_323(mark_ctx, value.to);
}
/* mark-visit<gc-ptr(fut<nat>)> (generated) (generated) */
struct void_ mark_visit_323(struct mark_ctx* mark_ctx, struct fut_0* value) {
	uint8_t _0 = mark(mark_ctx, (uint8_t*) value, sizeof(struct fut_0));
	if (_0) {
		return mark_visit_315(mark_ctx, *value);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(forward-to!<?out>.lambda0)> (generated) (generated) */
struct void_ mark_visit_324(struct mark_ctx* mark_ctx, struct forward_to__e__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, (uint8_t*) value, sizeof(struct forward_to__e__lambda0));
	if (_0) {
		return mark_visit_322(mark_ctx, *value);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(fut-callback-node<nat>)> (generated) (generated) */
struct void_ mark_visit_325(struct mark_ctx* mark_ctx, struct fut_callback_node_0* value) {
	uint8_t _0 = mark(mark_ctx, (uint8_t*) value, sizeof(struct fut_callback_node_0));
	if (_0) {
		return mark_visit_320(mark_ctx, *value);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<exception> (generated) (generated) */
struct void_ mark_visit_326(struct mark_ctx* mark_ctx, struct exception value) {
	mark_arr_327(mark_ctx, value.message);
	return mark_visit_328(mark_ctx, value.backtrace);
}
/* mark-arr<char> (generated) (generated) */
struct void_ mark_arr_327(struct mark_ctx* mark_ctx, struct arr_0 a) {
	uint8_t dropped0;
	dropped0 = mark(mark_ctx, (uint8_t*) a.data, (a.size * sizeof(char)));
	
	return (struct void_) {};
}
/* mark-visit<backtrace> (generated) (generated) */
struct void_ mark_visit_328(struct mark_ctx* mark_ctx, struct backtrace value) {
	return mark_arr_330(mark_ctx, value.return_stack);
}
/* mark-elems<arr<char>> (generated) (generated) */
struct void_ mark_elems_329(struct mark_ctx* mark_ctx, struct arr_0* cur, struct arr_0* end) {
	top:;
	uint8_t _0 = (cur == end);
	if (_0) {
		return (struct void_) {};
	} else {
		mark_arr_327(mark_ctx, *cur);
		mark_ctx = mark_ctx;
		cur = (cur + 1u);
		end = end;
		goto top;
	}
}
/* mark-arr<arr<char>> (generated) (generated) */
struct void_ mark_arr_330(struct mark_ctx* mark_ctx, struct arr_1 a) {
	uint8_t _0 = mark(mark_ctx, (uint8_t*) a.data, (a.size * sizeof(struct arr_0)));
	if (_0) {
		return mark_elems_329(mark_ctx, a.data, (a.data + a.size));
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(then<?out, void>.lambda0)> (generated) (generated) */
struct void_ mark_visit_331(struct mark_ctx* mark_ctx, struct then__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, (uint8_t*) value, sizeof(struct then__lambda0));
	if (_0) {
		return mark_visit_305(mark_ctx, *value);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(fut-callback-node<void>)> (generated) (generated) */
struct void_ mark_visit_332(struct mark_ctx* mark_ctx, struct fut_callback_node_1* value) {
	uint8_t _0 = mark(mark_ctx, (uint8_t*) value, sizeof(struct fut_callback_node_1));
	if (_0) {
		return mark_visit_303(mark_ctx, *value);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(fut<void>)> (generated) (generated) */
struct void_ mark_visit_333(struct mark_ctx* mark_ctx, struct fut_1* value) {
	uint8_t _0 = mark(mark_ctx, (uint8_t*) value, sizeof(struct fut_1));
	if (_0) {
		return mark_visit_298(mark_ctx, *value);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(callback!<?in>.lambda0)> (generated) (generated) */
struct void_ mark_visit_334(struct mark_ctx* mark_ctx, struct callback__e_0__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, (uint8_t*) value, sizeof(struct callback__e_0__lambda0));
	if (_0) {
		return mark_visit_297(mark_ctx, *value);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<callback!<?t>.lambda0> (generated) (generated) */
struct void_ mark_visit_335(struct mark_ctx* mark_ctx, struct callback__e_1__lambda0 value) {
	mark_visit_323(mark_ctx, value.f);
	return mark_visit_321(mark_ctx, value.cb);
}
/* mark-visit<gc-ptr(callback!<?t>.lambda0)> (generated) (generated) */
struct void_ mark_visit_336(struct mark_ctx* mark_ctx, struct callback__e_1__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, (uint8_t*) value, sizeof(struct callback__e_1__lambda0));
	if (_0) {
		return mark_visit_335(mark_ctx, *value);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<subscript<?out, ?in>.lambda0.lambda0> (generated) (generated) */
struct void_ mark_visit_337(struct mark_ctx* mark_ctx, struct subscript_8__lambda0__lambda0 value) {
	mark_visit_306(mark_ctx, value.f);
	return mark_visit_323(mark_ctx, value.res);
}
/* mark-visit<gc-ptr(subscript<?out, ?in>.lambda0.lambda0)> (generated) (generated) */
struct void_ mark_visit_338(struct mark_ctx* mark_ctx, struct subscript_8__lambda0__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, (uint8_t*) value, sizeof(struct subscript_8__lambda0__lambda0));
	if (_0) {
		return mark_visit_337(mark_ctx, *value);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<subscript<?out, ?in>.lambda0> (generated) (generated) */
struct void_ mark_visit_339(struct mark_ctx* mark_ctx, struct subscript_8__lambda0 value) {
	mark_visit_306(mark_ctx, value.f);
	return mark_visit_323(mark_ctx, value.res);
}
/* mark-visit<gc-ptr(subscript<?out, ?in>.lambda0)> (generated) (generated) */
struct void_ mark_visit_340(struct mark_ctx* mark_ctx, struct subscript_8__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, (uint8_t*) value, sizeof(struct subscript_8__lambda0));
	if (_0) {
		return mark_visit_339(mark_ctx, *value);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<subscript<?out>.lambda0.lambda0> (generated) (generated) */
struct void_ mark_visit_341(struct mark_ctx* mark_ctx, struct subscript_13__lambda0__lambda0 value) {
	mark_visit_309(mark_ctx, value.f);
	return mark_visit_323(mark_ctx, value.res);
}
/* mark-visit<gc-ptr(subscript<?out>.lambda0.lambda0)> (generated) (generated) */
struct void_ mark_visit_342(struct mark_ctx* mark_ctx, struct subscript_13__lambda0__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, (uint8_t*) value, sizeof(struct subscript_13__lambda0__lambda0));
	if (_0) {
		return mark_visit_341(mark_ctx, *value);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<subscript<?out>.lambda0> (generated) (generated) */
struct void_ mark_visit_343(struct mark_ctx* mark_ctx, struct subscript_13__lambda0 value) {
	mark_visit_309(mark_ctx, value.f);
	return mark_visit_323(mark_ctx, value.res);
}
/* mark-visit<gc-ptr(subscript<?out>.lambda0)> (generated) (generated) */
struct void_ mark_visit_344(struct mark_ctx* mark_ctx, struct subscript_13__lambda0* value) {
	uint8_t _0 = mark(mark_ctx, (uint8_t*) value, sizeof(struct subscript_13__lambda0));
	if (_0) {
		return mark_visit_343(mark_ctx, *value);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<gc-ptr(task-queue-node)> (generated) (generated) */
struct void_ mark_visit_345(struct mark_ctx* mark_ctx, struct task_queue_node* value) {
	uint8_t _0 = mark(mark_ctx, (uint8_t*) value, sizeof(struct task_queue_node));
	if (_0) {
		return mark_visit_294(mark_ctx, *value);
	} else {
		return (struct void_) {};
	}
}
/* mark-visit<mut-list<nat>> (generated) (generated) */
struct void_ mark_visit_346(struct mark_ctx* mark_ctx, struct mut_list_0 value) {
	return mark_visit_347(mark_ctx, value.backing);
}
/* mark-visit<mut-arr<nat>> (generated) (generated) */
struct void_ mark_visit_347(struct mark_ctx* mark_ctx, struct mut_arr_0 value) {
	return mark_arr_348(mark_ctx, value.inner);
}
/* mark-arr<nat-64> (generated) (generated) */
struct void_ mark_arr_348(struct mark_ctx* mark_ctx, struct arr_2 a) {
	uint8_t dropped0;
	dropped0 = mark(mark_ctx, (uint8_t*) a.data, (a.size * sizeof(uint64_t)));
	
	return (struct void_) {};
}
/* clear-free-mem void(mark-ptr ptr<bool>, mark-end ptr<bool>, data-ptr ptr<nat>) */
struct void_ clear_free_mem(uint8_t* mark_ptr, uint8_t* mark_end, uint64_t* data_ptr) {
	top:;
	uint8_t _0 = not((mark_ptr == mark_end));
	if (_0) {
		uint8_t _1 = not(*mark_ptr);
		if (_1) {
			*data_ptr = 18077161789910350558u;
		} else {
			(struct void_) {};
		}
		uint8_t* _2 = incr_0(mark_ptr);
		mark_ptr = _2;
		mark_end = mark_end;
		data_ptr = data_ptr;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* wait-on void(cond condition, until-time opt<nat>, last-checked nat) */
struct void_ wait_on(struct condition* cond, struct opt_8 until_time, uint64_t last_checked) {
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
uint8_t before_time__q(struct opt_8 until_time) {
	struct opt_8 _0 = until_time;
	switch (_0.kind) {
		case 0: {
			return 1;
		}
		case 1: {
			struct some_8 s0 = _0.as1;
			
			uint64_t _1 = get_monotime_nsec();
			return _less_0(_1, s0.value);
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
		uint64_t _1 = subscript_21(threads, i);
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
/* main fut<nat>(args arr<arr<char>>) */
struct fut_0* main_0(struct ctx* ctx, struct arr_1 args) {
	struct opt_9 options0;
	options0 = parse_cmd_line_args(ctx, args, (struct arr_1) {3, constantarr_1_0}, (struct fun1_2) {0, .as0 = (struct void_) {}});
	
	struct opt_9 _0 = options0;uint64_t _1;
	
	switch (_0.kind) {
		case 0: {
			print_help(ctx);
			_1 = 1u;
			break;
		}
		case 1: {
			struct some_9 s1 = _0.as1;
			
			_1 = do_test(ctx, s1.value);
			break;
		}
		default:
			0;
	}
	return resolved_1(ctx, _1);
}
/* parse-cmd-line-args<test-options> opt<test-options>(args arr<arr<char>>, t-names arr<arr<char>>, make-t fun1<test-options, arr<opt<arr<arr<char>>>>>) */
struct opt_9 parse_cmd_line_args(struct ctx* ctx, struct arr_1 args, struct arr_1 t_names, struct fun1_2 make_t) {
	struct parsed_cmd_line_args* parsed0;
	parsed0 = parse_cmd_line_args_dynamic(ctx, args);
	
	uint8_t _0 = empty__q_1(parsed0->nameless);
	assert_1(ctx, _0, (struct arr_0) {26, constantarr_0_15});
	uint8_t _1 = empty__q_1(parsed0->after);
	assert_0(ctx, _1);
	struct mut_list_3* values1;
	values1 = fill_mut_list(ctx, t_names.size, (struct opt_10) {0, .as0 = (struct none) {}});
	
	struct cell_3* help2;
	struct cell_3* temp0;
	uint8_t* _2 = alloc(ctx, sizeof(struct cell_3));
	temp0 = (struct cell_3*) _2;
	
	*temp0 = (struct cell_3) {0};
	help2 = temp0;
	
	struct parse_cmd_line_args__lambda0* temp1;
	uint8_t* _3 = alloc(ctx, sizeof(struct parse_cmd_line_args__lambda0));
	temp1 = (struct parse_cmd_line_args__lambda0*) _3;
	
	*temp1 = (struct parse_cmd_line_args__lambda0) {t_names, help2, values1};
	each_0(ctx, parsed0->named, (struct fun_act2_1) {0, .as0 = temp1});
	uint8_t _4 = help2->subscript;
	if (_4) {
		return (struct opt_9) {0, .as0 = (struct none) {}};
	} else {
		struct arr_5 _5 = move_to_arr__e_2(values1);
		struct test_options _6 = subscript_43(ctx, make_t, _5);
		return (struct opt_9) {1, .as1 = (struct some_9) {_6}};
	}
}
/* parse-cmd-line-args-dynamic parsed-cmd-line-args(args arr<arr<char>>) */
struct parsed_cmd_line_args* parse_cmd_line_args_dynamic(struct ctx* ctx, struct arr_1 args) {
	struct opt_8 _0 = find_index(ctx, args, (struct fun_act1_6) {0, .as0 = (struct void_) {}});
	switch (_0.kind) {
		case 0: {
			struct parsed_cmd_line_args* temp0;
			uint8_t* _1 = alloc(ctx, sizeof(struct parsed_cmd_line_args));
			temp0 = (struct parsed_cmd_line_args*) _1;
			
			struct dict_0* _2 = dict_0(ctx, (struct arr_7) {0u, NULL});
			*temp0 = (struct parsed_cmd_line_args) {args, _2, (struct arr_1) {0u, NULL}};
			return temp0;
		}
		case 1: {
			struct some_8 s0 = _0.as1;
			
			uint64_t first_named_arg_index1;
			first_named_arg_index1 = s0.value;
			
			struct arr_1 nameless2;
			struct arrow_0 _3 = _arrow_0(ctx, 0u, first_named_arg_index1);
			nameless2 = subscript_3(ctx, args, _3);
			
			struct arr_1 rest3;
			struct arrow_0 _4 = _arrow_0(ctx, first_named_arg_index1, args.size);
			rest3 = subscript_3(ctx, args, _4);
			
			struct opt_8 _5 = find_index(ctx, rest3, (struct fun_act1_6) {1, .as1 = (struct void_) {}});
			switch (_5.kind) {
				case 0: {
					struct parsed_cmd_line_args* temp1;
					uint8_t* _6 = alloc(ctx, sizeof(struct parsed_cmd_line_args));
					temp1 = (struct parsed_cmd_line_args*) _6;
					
					struct dict_0* _7 = parse_named_args(ctx, rest3);
					*temp1 = (struct parsed_cmd_line_args) {nameless2, _7, (struct arr_1) {0u, NULL}};
					return temp1;
				}
				case 1: {
					struct some_8 s24 = _5.as1;
					
					uint64_t sep_index5;
					sep_index5 = s24.value;
					
					struct dict_0* named_args6;
					struct arrow_0 _8 = _arrow_0(ctx, 0u, sep_index5);
					struct arr_1 _9 = subscript_3(ctx, rest3, _8);
					named_args6 = parse_named_args(ctx, _9);
					
					struct parsed_cmd_line_args* temp2;
					uint8_t* _10 = alloc(ctx, sizeof(struct parsed_cmd_line_args));
					temp2 = (struct parsed_cmd_line_args*) _10;
					
					uint64_t _11 = _plus(ctx, sep_index5, 1u);
					struct arrow_0 _12 = _arrow_0(ctx, _11, rest3.size);
					struct arr_1 _13 = subscript_3(ctx, rest3, _12);
					*temp2 = (struct parsed_cmd_line_args) {nameless2, named_args6, _13};
					return temp2;
				}
				default:
					return NULL;
			}
		}
		default:
			return NULL;
	}
}
/* find-index<arr<char>> opt<nat>(a arr<arr<char>>, pred fun-act1<bool, arr<char>>) */
struct opt_8 find_index(struct ctx* ctx, struct arr_1 a, struct fun_act1_6 pred) {
	return find_index_recur(ctx, a, 0u, pred);
}
/* find-index-recur<?t> opt<nat>(a arr<arr<char>>, index nat, pred fun-act1<bool, arr<char>>) */
struct opt_8 find_index_recur(struct ctx* ctx, struct arr_1 a, uint64_t index, struct fun_act1_6 pred) {
	top:;
	uint8_t _0 = _equal_0(index, a.size);
	if (_0) {
		return (struct opt_8) {0, .as0 = (struct none) {}};
	} else {
		struct arr_0 _1 = subscript_0(ctx, a, index);
		uint8_t _2 = subscript_22(ctx, pred, _1);
		if (_2) {
			return (struct opt_8) {1, .as1 = (struct some_8) {index}};
		} else {
			uint64_t _3 = incr_5(ctx, index);
			a = a;
			index = _3;
			pred = pred;
			goto top;
		}
	}
}
/* subscript<bool, ?t> bool(a fun-act1<bool, arr<char>>, p0 arr<char>) */
uint8_t subscript_22(struct ctx* ctx, struct fun_act1_6 a, struct arr_0 p0) {
	return call_w_ctx_366(a, ctx, p0);
}
/* call-w-ctx<bool, arr<char>> (generated) (generated) */
uint8_t call_w_ctx_366(struct fun_act1_6 a, struct ctx* ctx, struct arr_0 p0) {
	struct fun_act1_6 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return parse_cmd_line_args_dynamic__lambda0(ctx, closure0, p0);
		}
		case 1: {
			struct void_ closure1 = _0.as1;
			
			return parse_cmd_line_args_dynamic__lambda1(ctx, closure1, p0);
		}
		case 2: {
			struct void_ closure2 = _0.as2;
			
			return parse_named_args_recur__lambda0(ctx, closure2, p0);
		}
		case 3: {
			struct index_of__lambda0* closure3 = _0.as3;
			
			return index_of__lambda0(ctx, closure3, p0);
		}
		case 4: {
			struct void_ closure4 = _0.as4;
			
			return list_tests__lambda0(ctx, closure4, p0);
		}
		case 5: {
			struct excluded_from_lint__q__lambda0* closure5 = _0.as5;
			
			return excluded_from_lint__q__lambda0(ctx, closure5, p0);
		}
		case 6: {
			struct void_ closure6 = _0.as6;
			
			return list_lintable_files__lambda0(ctx, closure6, p0);
		}
		default:
			return 0;
	}
}
/* incr nat(n nat) */
uint64_t incr_5(struct ctx* ctx, uint64_t n) {
	uint64_t _0 = max_nat();
	uint8_t _1 = _equal_0(n, _0);
	forbid_0(ctx, _1);
	return (n + 1u);
}
/* max-nat nat() */
uint64_t max_nat(void) {
	return 18446744073709551615u;
}
/* starts-with?<char> bool(a arr<char>, start arr<char>) */
uint8_t starts_with__q(struct ctx* ctx, struct arr_0 a, struct arr_0 start) {
	uint8_t _0 = _greaterOrEqual(a.size, start.size);
	if (_0) {
		struct arrow_0 _1 = _arrow_0(ctx, 0u, start.size);
		struct arr_0 _2 = subscript_25(ctx, a, _1);
		return arr_eq__q(ctx, _2, start);
	} else {
		return 0;
	}
}
/* arr-eq?<?t> bool(a arr<char>, b arr<char>) */
uint8_t arr_eq__q(struct ctx* ctx, struct arr_0 a, struct arr_0 b) {
	top:;
	uint8_t _0 = _notEqual_1(a.size, b.size);
	if (_0) {
		return 0;
	} else {
		uint8_t _1 = empty__q_0(a);
		if (_1) {
			return 1;
		} else {
			char _2 = subscript_23(ctx, a, 0u);
			char _3 = subscript_23(ctx, b, 0u);
			uint8_t _4 = _notEqual_3(_2, _3);
			if (_4) {
				return 0;
			} else {
				struct arrow_0 _5 = _arrow_0(ctx, 1u, a.size);
				struct arr_0 _6 = subscript_25(ctx, a, _5);
				struct arrow_0 _7 = _arrow_0(ctx, 1u, b.size);
				struct arr_0 _8 = subscript_25(ctx, b, _7);
				a = _6;
				b = _8;
				goto top;
			}
		}
	}
}
/* !=<?t> bool(a char, b char) */
uint8_t _notEqual_3(char a, char b) {
	uint8_t _0 = _equal_3(a, b);
	return not(_0);
}
/* subscript<?t> char(a arr<char>, index nat) */
char subscript_23(struct ctx* ctx, struct arr_0 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	return noctx_at_5(a, index);
}
/* noctx-at<?t> char(a arr<char>, index nat) */
char noctx_at_5(struct arr_0 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	hard_assert(_0);
	return subscript_24(a.data, index);
}
/* subscript<?t> char(a ptr<char>, n nat) */
char subscript_24(char* a, uint64_t n) {
	return *(a + n);
}
/* subscript<?t> arr<char>(a arr<char>, range arrow<nat, nat>) */
struct arr_0 subscript_25(struct ctx* ctx, struct arr_0 a, struct arrow_0 range) {
	uint8_t _0 = _lessOrEqual(range.from, range.to);
	assert_0(ctx, _0);
	uint8_t _1 = _lessOrEqual(range.to, a.size);
	assert_0(ctx, _1);
	uint64_t _2 = _minus_2(ctx, range.to, range.from);
	return (struct arr_0) {_2, (a.data + range.from)};
}
/* parse-cmd-line-args-dynamic.lambda0 bool(it arr<char>) */
uint8_t parse_cmd_line_args_dynamic__lambda0(struct ctx* ctx, struct void_ _closure, struct arr_0 it) {
	return starts_with__q(ctx, it, (struct arr_0) {2, constantarr_0_13});
}
/* dict<arr<char>, arr<arr<char>>> dict<arr<char>, arr<arr<char>>>(pairs arr<arrow<arr<char>, arr<arr<char>>>>) */
struct dict_0* dict_0(struct ctx* ctx, struct arr_7 pairs) {
	struct arr_1 keys0;
	keys0 = map_1(ctx, pairs, (struct fun_act1_7) {0, .as0 = (struct void_) {}});
	
	struct arr_6 values1;
	values1 = map_2(ctx, pairs, (struct fun_act1_8) {0, .as0 = (struct void_) {}});
	
	return dict_1(ctx, keys0, values1);
}
/* map<?k, arrow<?k, ?v>> arr<arr<char>>(a arr<arrow<arr<char>, arr<arr<char>>>>, mapper fun-act1<arr<char>, arrow<arr<char>, arr<arr<char>>>>) */
struct arr_1 map_1(struct ctx* ctx, struct arr_7 a, struct fun_act1_7 mapper) {
	struct map_1__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct map_1__lambda0));
	temp0 = (struct map_1__lambda0*) _0;
	
	*temp0 = (struct map_1__lambda0) {mapper, a};
	return make_arr_0(ctx, a.size, (struct fun_act1_5) {1, .as1 = temp0});
}
/* subscript<?out, ?in> arr<char>(a fun-act1<arr<char>, arrow<arr<char>, arr<arr<char>>>>, p0 arrow<arr<char>, arr<arr<char>>>) */
struct arr_0 subscript_26(struct ctx* ctx, struct fun_act1_7 a, struct arrow_1* p0) {
	return call_w_ctx_380(a, ctx, p0);
}
/* call-w-ctx<arr<char>, gc-ptr(arrow<arr<char>, arr<arr<char>>>)> (generated) (generated) */
struct arr_0 call_w_ctx_380(struct fun_act1_7 a, struct ctx* ctx, struct arrow_1* p0) {
	struct fun_act1_7 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return dict_0__lambda0(ctx, closure0, p0);
		}
		default:
			return (struct arr_0) {0, NULL};
	}
}
/* subscript<?in> arrow<arr<char>, arr<arr<char>>>(a arr<arrow<arr<char>, arr<arr<char>>>>, index nat) */
struct arrow_1* subscript_27(struct ctx* ctx, struct arr_7 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	return noctx_at_6(a, index);
}
/* noctx-at<?t> arrow<arr<char>, arr<arr<char>>>(a arr<arrow<arr<char>, arr<arr<char>>>>, index nat) */
struct arrow_1* noctx_at_6(struct arr_7 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	hard_assert(_0);
	return subscript_28(a.data, index);
}
/* subscript<?t> arrow<arr<char>, arr<arr<char>>>(a ptr<arrow<arr<char>, arr<arr<char>>>>, n nat) */
struct arrow_1* subscript_28(struct arrow_1** a, uint64_t n) {
	return *(a + n);
}
/* map<?k, arrow<?k, ?v>>.lambda0 arr<char>(i nat) */
struct arr_0 map_1__lambda0(struct ctx* ctx, struct map_1__lambda0* _closure, uint64_t i) {
	struct arrow_1* _0 = subscript_27(ctx, _closure->a, i);
	return subscript_26(ctx, _closure->mapper, _0);
}
/* dict<arr<char>, arr<arr<char>>>.lambda0 arr<char>(it arrow<arr<char>, arr<arr<char>>>) */
struct arr_0 dict_0__lambda0(struct ctx* ctx, struct void_ _closure, struct arrow_1* it) {
	return it->from;
}
/* map<?v, arrow<?k, ?v>> arr<arr<arr<char>>>(a arr<arrow<arr<char>, arr<arr<char>>>>, mapper fun-act1<arr<arr<char>>, arrow<arr<char>, arr<arr<char>>>>) */
struct arr_6 map_2(struct ctx* ctx, struct arr_7 a, struct fun_act1_8 mapper) {
	struct map_2__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct map_2__lambda0));
	temp0 = (struct map_2__lambda0*) _0;
	
	*temp0 = (struct map_2__lambda0) {mapper, a};
	return make_arr_1(ctx, a.size, (struct fun_act1_9) {0, .as0 = temp0});
}
/* make-arr<?out> arr<arr<arr<char>>>(size nat, f fun-act1<arr<arr<char>>, nat>) */
struct arr_6 make_arr_1(struct ctx* ctx, uint64_t size, struct fun_act1_9 f) {
	struct arr_1* data0;
	data0 = alloc_uninitialized_2(ctx, size);
	
	fill_ptr_range_1(ctx, data0, size, f);
	return (struct arr_6) {size, data0};
}
/* alloc-uninitialized<?t> ptr<arr<arr<char>>>(size nat) */
struct arr_1* alloc_uninitialized_2(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(struct arr_1)));
	return (struct arr_1*) _0;
}
/* fill-ptr-range<?t> void(begin ptr<arr<arr<char>>>, size nat, f fun-act1<arr<arr<char>>, nat>) */
struct void_ fill_ptr_range_1(struct ctx* ctx, struct arr_1* begin, uint64_t size, struct fun_act1_9 f) {
	return fill_ptr_range_recur_1(ctx, begin, 0u, size, f);
}
/* fill-ptr-range-recur<?t> void(begin ptr<arr<arr<char>>>, i nat, size nat, f fun-act1<arr<arr<char>>, nat>) */
struct void_ fill_ptr_range_recur_1(struct ctx* ctx, struct arr_1* begin, uint64_t i, uint64_t size, struct fun_act1_9 f) {
	top:;
	uint8_t _0 = _notEqual_1(i, size);
	if (_0) {
		struct arr_1 _1 = subscript_29(ctx, f, i);
		set_subscript_3(begin, i, _1);
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
/* set-subscript<?t> void(a ptr<arr<arr<char>>>, n nat, value arr<arr<char>>) */
struct void_ set_subscript_3(struct arr_1* a, uint64_t n, struct arr_1 value) {
	return (*(a + n) = value, (struct void_) {});
}
/* subscript<?t, nat> arr<arr<char>>(a fun-act1<arr<arr<char>>, nat>, p0 nat) */
struct arr_1 subscript_29(struct ctx* ctx, struct fun_act1_9 a, uint64_t p0) {
	return call_w_ctx_393(a, ctx, p0);
}
/* call-w-ctx<arr<arr<char>>, nat-64> (generated) (generated) */
struct arr_1 call_w_ctx_393(struct fun_act1_9 a, struct ctx* ctx, uint64_t p0) {
	struct fun_act1_9 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct map_2__lambda0* closure0 = _0.as0;
			
			return map_2__lambda0(ctx, closure0, p0);
		}
		case 1: {
			struct mut_arr_3__lambda0* closure1 = _0.as1;
			
			return mut_arr_3__lambda0(ctx, closure1, p0);
		}
		default:
			return (struct arr_1) {0, NULL};
	}
}
/* subscript<?out, ?in> arr<arr<char>>(a fun-act1<arr<arr<char>>, arrow<arr<char>, arr<arr<char>>>>, p0 arrow<arr<char>, arr<arr<char>>>) */
struct arr_1 subscript_30(struct ctx* ctx, struct fun_act1_8 a, struct arrow_1* p0) {
	return call_w_ctx_395(a, ctx, p0);
}
/* call-w-ctx<arr<arr<char>>, gc-ptr(arrow<arr<char>, arr<arr<char>>>)> (generated) (generated) */
struct arr_1 call_w_ctx_395(struct fun_act1_8 a, struct ctx* ctx, struct arrow_1* p0) {
	struct fun_act1_8 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return dict_0__lambda1(ctx, closure0, p0);
		}
		default:
			return (struct arr_1) {0, NULL};
	}
}
/* map<?v, arrow<?k, ?v>>.lambda0 arr<arr<char>>(i nat) */
struct arr_1 map_2__lambda0(struct ctx* ctx, struct map_2__lambda0* _closure, uint64_t i) {
	struct arrow_1* _0 = subscript_27(ctx, _closure->a, i);
	return subscript_30(ctx, _closure->mapper, _0);
}
/* dict<arr<char>, arr<arr<char>>>.lambda1 arr<arr<char>>(it arrow<arr<char>, arr<arr<char>>>) */
struct arr_1 dict_0__lambda1(struct ctx* ctx, struct void_ _closure, struct arrow_1* it) {
	return it->to;
}
/* dict<?k, ?v> dict<arr<char>, arr<arr<char>>>(keys arr<arr<char>>, values arr<arr<arr<char>>>) */
struct dict_0* dict_1(struct ctx* ctx, struct arr_1 keys, struct arr_6 values) {
	uint8_t _0 = _equal_0(keys.size, values.size);
	assert_0(ctx, _0);
	struct sorted_by_first_0* sorted0;
	sorted0 = sort_by_first_0(ctx, keys, values);
	
	struct dict_0* temp0;
	uint8_t* _1 = alloc(ctx, sizeof(struct dict_0));
	temp0 = (struct dict_0*) _1;
	
	*temp0 = (struct dict_0) {(struct void_) {}, sorted0->a, sorted0->b};
	return temp0;
}
/* sort-by-first<?k, ?v> sorted-by-first<arr<char>, arr<arr<char>>>(a arr<arr<char>>, b arr<arr<arr<char>>>) */
struct sorted_by_first_0* sort_by_first_0(struct ctx* ctx, struct arr_1 a, struct arr_6 b) {
	struct mut_arr_1 mut_a0;
	mut_a0 = mut_arr_1(ctx, a);
	
	struct mut_arr_2 mut_b1;
	mut_b1 = mut_arr_3(ctx, b);
	
	sort_by_first__e_0(ctx, mut_a0, mut_b1);
	struct sorted_by_first_0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct sorted_by_first_0));
	temp0 = (struct sorted_by_first_0*) _0;
	
	struct arr_1 _1 = cast_immutable_0(mut_a0);
	struct arr_6 _2 = cast_immutable_1(mut_b1);
	*temp0 = (struct sorted_by_first_0) {_1, _2};
	return temp0;
}
/* mut-arr<?a> mut-arr<arr<char>>(a arr<arr<char>>) */
struct mut_arr_1 mut_arr_1(struct ctx* ctx, struct arr_1 a) {
	struct mut_arr_1__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_arr_1__lambda0));
	temp0 = (struct mut_arr_1__lambda0*) _0;
	
	*temp0 = (struct mut_arr_1__lambda0) {a};
	return make_mut_arr_0(ctx, a.size, (struct fun_act1_5) {2, .as2 = temp0});
}
/* make-mut-arr<?t> mut-arr<arr<char>>(size nat, f fun-act1<arr<char>, nat>) */
struct mut_arr_1 make_mut_arr_0(struct ctx* ctx, uint64_t size, struct fun_act1_5 f) {
	struct mut_arr_1 res0;
	res0 = uninitialized_mut_arr_0(ctx, size);
	
	struct arr_0* _0 = data_2(res0);
	fill_ptr_range_0(ctx, _0, size, f);
	return res0;
}
/* uninitialized-mut-arr<?t> mut-arr<arr<char>>(size nat) */
struct mut_arr_1 uninitialized_mut_arr_0(struct ctx* ctx, uint64_t size) {
	struct arr_0* _0 = alloc_uninitialized_1(ctx, size);
	return mut_arr_2(size, _0);
}
/* mut-arr<?t> mut-arr<arr<char>>(size nat, data ptr<arr<char>>) */
struct mut_arr_1 mut_arr_2(uint64_t size, struct arr_0* data) {
	return (struct mut_arr_1) {(struct void_) {}, (struct arr_1) {size, data}};
}
/* data<?t> ptr<arr<char>>(a mut-arr<arr<char>>) */
struct arr_0* data_2(struct mut_arr_1 a) {
	return a.inner.data;
}
/* mut-arr<?a>.lambda0 arr<char>(it nat) */
struct arr_0 mut_arr_1__lambda0(struct ctx* ctx, struct mut_arr_1__lambda0* _closure, uint64_t it) {
	return subscript_0(ctx, _closure->a, it);
}
/* mut-arr<?b> mut-arr<arr<arr<char>>>(a arr<arr<arr<char>>>) */
struct mut_arr_2 mut_arr_3(struct ctx* ctx, struct arr_6 a) {
	struct mut_arr_3__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_arr_3__lambda0));
	temp0 = (struct mut_arr_3__lambda0*) _0;
	
	*temp0 = (struct mut_arr_3__lambda0) {a};
	return make_mut_arr_1(ctx, a.size, (struct fun_act1_9) {1, .as1 = temp0});
}
/* make-mut-arr<?t> mut-arr<arr<arr<char>>>(size nat, f fun-act1<arr<arr<char>>, nat>) */
struct mut_arr_2 make_mut_arr_1(struct ctx* ctx, uint64_t size, struct fun_act1_9 f) {
	struct mut_arr_2 res0;
	res0 = uninitialized_mut_arr_1(ctx, size);
	
	struct arr_1* _0 = data_3(res0);
	fill_ptr_range_1(ctx, _0, size, f);
	return res0;
}
/* uninitialized-mut-arr<?t> mut-arr<arr<arr<char>>>(size nat) */
struct mut_arr_2 uninitialized_mut_arr_1(struct ctx* ctx, uint64_t size) {
	struct arr_1* _0 = alloc_uninitialized_2(ctx, size);
	return mut_arr_4(size, _0);
}
/* mut-arr<?t> mut-arr<arr<arr<char>>>(size nat, data ptr<arr<arr<char>>>) */
struct mut_arr_2 mut_arr_4(uint64_t size, struct arr_1* data) {
	return (struct mut_arr_2) {(struct void_) {}, (struct arr_6) {size, data}};
}
/* data<?t> ptr<arr<arr<char>>>(a mut-arr<arr<arr<char>>>) */
struct arr_1* data_3(struct mut_arr_2 a) {
	return a.inner.data;
}
/* subscript<?t> arr<arr<char>>(a arr<arr<arr<char>>>, index nat) */
struct arr_1 subscript_31(struct ctx* ctx, struct arr_6 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	return noctx_at_7(a, index);
}
/* noctx-at<?t> arr<arr<char>>(a arr<arr<arr<char>>>, index nat) */
struct arr_1 noctx_at_7(struct arr_6 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	hard_assert(_0);
	return subscript_32(a.data, index);
}
/* subscript<?t> arr<arr<char>>(a ptr<arr<arr<char>>>, n nat) */
struct arr_1 subscript_32(struct arr_1* a, uint64_t n) {
	return *(a + n);
}
/* mut-arr<?b>.lambda0 arr<arr<char>>(it nat) */
struct arr_1 mut_arr_3__lambda0(struct ctx* ctx, struct mut_arr_3__lambda0* _closure, uint64_t it) {
	return subscript_31(ctx, _closure->a, it);
}
/* sort-by-first!<?a, ?b> void(a mut-arr<arr<char>>, b mut-arr<arr<arr<char>>>) */
struct void_ sort_by_first__e_0(struct ctx* ctx, struct mut_arr_1 a, struct mut_arr_2 b) {
	top:;
	uint64_t _0 = size_2(a);
	uint64_t _1 = size_3(b);
	uint8_t _2 = _equal_0(_0, _1);
	assert_0(ctx, _2);
	uint64_t _3 = size_2(a);
	uint8_t _4 = _greater(_3, 1u);
	if (_4) {
		uint64_t _5 = size_2(a);
		uint64_t _6 = _divide(ctx, _5, 2u);
		swap_2(ctx, a, 0u, _6);
		struct arr_0 pivot0;
		pivot0 = subscript_33(ctx, a, 0u);
		
		uint64_t new_pivot_index1;
		uint64_t _7 = size_2(a);
		uint64_t _8 = _minus_2(ctx, _7, 1u);
		uint64_t _9 = partition_by_first__e_0(ctx, a, b, pivot0, 1u, _8);
		new_pivot_index1 = _minus_2(ctx, _9, 1u);
		
		swap_2(ctx, a, 0u, new_pivot_index1);
		swap_3(ctx, b, 0u, new_pivot_index1);
		struct arrow_0 _10 = _arrow_0(ctx, 0u, new_pivot_index1);
		struct mut_arr_1 _11 = subscript_35(ctx, a, _10);
		struct arrow_0 _12 = _arrow_0(ctx, 0u, new_pivot_index1);
		struct mut_arr_2 _13 = subscript_36(ctx, b, _12);
		sort_by_first__e_0(ctx, _11, _13);
		uint64_t _14 = _plus(ctx, new_pivot_index1, 1u);
		uint64_t _15 = size_2(a);
		struct arrow_0 _16 = _arrow_0(ctx, _14, _15);
		struct mut_arr_1 _17 = subscript_35(ctx, a, _16);
		uint64_t _18 = _plus(ctx, new_pivot_index1, 1u);
		uint64_t _19 = size_3(b);
		struct arrow_0 _20 = _arrow_0(ctx, _18, _19);
		struct mut_arr_2 _21 = subscript_36(ctx, b, _20);
		a = _17;
		b = _21;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* size<?a> nat(a mut-arr<arr<char>>) */
uint64_t size_2(struct mut_arr_1 a) {
	return a.inner.size;
}
/* size<?b> nat(a mut-arr<arr<arr<char>>>) */
uint64_t size_3(struct mut_arr_2 a) {
	return a.inner.size;
}
/* swap<?a> void(a mut-arr<arr<char>>, x nat, y nat) */
struct void_ swap_2(struct ctx* ctx, struct mut_arr_1 a, uint64_t x, uint64_t y) {
	struct arr_0 old_x0;
	old_x0 = subscript_33(ctx, a, x);
	
	struct arr_0 _0 = subscript_33(ctx, a, y);
	set_subscript_4(ctx, a, x, _0);
	return set_subscript_4(ctx, a, y, old_x0);
}
/* subscript<?t> arr<char>(a mut-arr<arr<char>>, index nat) */
struct arr_0 subscript_33(struct ctx* ctx, struct mut_arr_1 a, uint64_t index) {
	return subscript_0(ctx, a.inner, index);
}
/* set-subscript<?t> void(a mut-arr<arr<char>>, index nat, value arr<char>) */
struct void_ set_subscript_4(struct ctx* ctx, struct mut_arr_1 a, uint64_t index, struct arr_0 value) {
	uint64_t _0 = size_2(a);
	uint8_t _1 = _less_0(index, _0);
	assert_0(ctx, _1);
	return noctx_set_at_0(a, index, value);
}
/* noctx-set-at<?t> void(a mut-arr<arr<char>>, index nat, value arr<char>) */
struct void_ noctx_set_at_0(struct mut_arr_1 a, uint64_t index, struct arr_0 value) {
	uint64_t _0 = size_2(a);
	uint8_t _1 = _less_0(index, _0);
	hard_assert(_1);
	struct arr_0* _2 = data_2(a);
	return set_subscript_1(_2, index, value);
}
/* / nat(a nat, b nat) */
uint64_t _divide(struct ctx* ctx, uint64_t a, uint64_t b) {
	uint8_t _0 = _equal_0(b, 0u);
	forbid_0(ctx, _0);
	return (a / b);
}
/* partition-by-first!<?a, ?b> nat(a mut-arr<arr<char>>, b mut-arr<arr<arr<char>>>, pivot arr<char>, l nat, r nat) */
uint64_t partition_by_first__e_0(struct ctx* ctx, struct mut_arr_1 a, struct mut_arr_2 b, struct arr_0 pivot, uint64_t l, uint64_t r) {
	top:;
	uint64_t _0 = size_2(a);
	uint8_t _1 = _lessOrEqual(l, _0);
	assert_0(ctx, _1);
	uint64_t _2 = size_2(a);
	uint8_t _3 = _less_0(r, _2);
	assert_0(ctx, _3);
	uint8_t _4 = _lessOrEqual(l, r);
	if (_4) {
		struct arr_0 _5 = subscript_33(ctx, a, l);
		uint8_t _6 = _less_1(_5, pivot);
		if (_6) {
			uint64_t _7 = _plus(ctx, l, 1u);
			a = a;
			b = b;
			pivot = pivot;
			l = _7;
			r = r;
			goto top;
		} else {
			swap_2(ctx, a, l, r);
			swap_3(ctx, b, l, r);
			uint64_t _8 = _minus_2(ctx, r, 1u);
			a = a;
			b = b;
			pivot = pivot;
			l = l;
			r = _8;
			goto top;
		}
	} else {
		return l;
	}
}
/* <<?a> bool(a arr<char>, b arr<char>) */
uint8_t _less_1(struct arr_0 a, struct arr_0 b) {
	struct comparison _0 = compare_425(a, b);
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
/* compare<arr<char>> (generated) (generated) */
struct comparison compare_425(struct arr_0 a, struct arr_0 b) {
	top:;
	uint8_t _0 = (a.size == 0u);
	if (_0) {
		uint8_t _1 = (b.size == 0u);
		if (_1) {
			return (struct comparison) {1, .as1 = (struct equal) {}};
		} else {
			return (struct comparison) {0, .as0 = (struct less) {}};
		}
	} else {
		uint8_t _2 = (b.size == 0u);
		if (_2) {
			return (struct comparison) {2, .as2 = (struct greater) {}};
		} else {
			struct comparison _3 = compare_221(*a.data, *b.data);
			switch (_3.kind) {
				case 0: {
					return (struct comparison) {0, .as0 = (struct less) {}};
				}
				case 1: {
					a = (struct arr_0) {(a.size - 1u), (a.data + 1u)};
					b = (struct arr_0) {(b.size - 1u), (b.data + 1u)};
					goto top;
				}
				case 2: {
					return (struct comparison) {2, .as2 = (struct greater) {}};
				}
				default:
					return (struct comparison) {0};
			}
		}
	}
}
/* swap<?b> void(a mut-arr<arr<arr<char>>>, x nat, y nat) */
struct void_ swap_3(struct ctx* ctx, struct mut_arr_2 a, uint64_t x, uint64_t y) {
	struct arr_1 old_x0;
	old_x0 = subscript_34(ctx, a, x);
	
	struct arr_1 _0 = subscript_34(ctx, a, y);
	set_subscript_5(ctx, a, x, _0);
	return set_subscript_5(ctx, a, y, old_x0);
}
/* subscript<?t> arr<arr<char>>(a mut-arr<arr<arr<char>>>, index nat) */
struct arr_1 subscript_34(struct ctx* ctx, struct mut_arr_2 a, uint64_t index) {
	return subscript_31(ctx, a.inner, index);
}
/* set-subscript<?t> void(a mut-arr<arr<arr<char>>>, index nat, value arr<arr<char>>) */
struct void_ set_subscript_5(struct ctx* ctx, struct mut_arr_2 a, uint64_t index, struct arr_1 value) {
	uint64_t _0 = size_3(a);
	uint8_t _1 = _less_0(index, _0);
	assert_0(ctx, _1);
	return noctx_set_at_1(a, index, value);
}
/* noctx-set-at<?t> void(a mut-arr<arr<arr<char>>>, index nat, value arr<arr<char>>) */
struct void_ noctx_set_at_1(struct mut_arr_2 a, uint64_t index, struct arr_1 value) {
	uint64_t _0 = size_3(a);
	uint8_t _1 = _less_0(index, _0);
	hard_assert(_1);
	struct arr_1* _2 = data_3(a);
	return set_subscript_3(_2, index, value);
}
/* subscript<?a> mut-arr<arr<char>>(a mut-arr<arr<char>>, range arrow<nat, nat>) */
struct mut_arr_1 subscript_35(struct ctx* ctx, struct mut_arr_1 a, struct arrow_0 range) {
	struct arr_1 _0 = subscript_3(ctx, a.inner, range);
	return (struct mut_arr_1) {(struct void_) {}, _0};
}
/* subscript<?b> mut-arr<arr<arr<char>>>(a mut-arr<arr<arr<char>>>, range arrow<nat, nat>) */
struct mut_arr_2 subscript_36(struct ctx* ctx, struct mut_arr_2 a, struct arrow_0 range) {
	struct arr_6 _0 = subscript_37(ctx, a.inner, range);
	return (struct mut_arr_2) {(struct void_) {}, _0};
}
/* subscript<?t> arr<arr<arr<char>>>(a arr<arr<arr<char>>>, range arrow<nat, nat>) */
struct arr_6 subscript_37(struct ctx* ctx, struct arr_6 a, struct arrow_0 range) {
	uint8_t _0 = _lessOrEqual(range.from, range.to);
	assert_0(ctx, _0);
	uint8_t _1 = _lessOrEqual(range.to, a.size);
	assert_0(ctx, _1);
	uint64_t _2 = _minus_2(ctx, range.to, range.from);
	return (struct arr_6) {_2, (a.data + range.from)};
}
/* cast-immutable<?a> arr<arr<char>>(a mut-arr<arr<char>>) */
struct arr_1 cast_immutable_0(struct mut_arr_1 a) {
	return a.inner;
}
/* cast-immutable<?b> arr<arr<arr<char>>>(a mut-arr<arr<arr<char>>>) */
struct arr_6 cast_immutable_1(struct mut_arr_2 a) {
	return a.inner;
}
/* ==<arr<char>> bool(a arr<char>, b arr<char>) */
uint8_t _equal_4(struct arr_0 a, struct arr_0 b) {
	struct comparison _0 = compare_425(a, b);
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
/* parse-cmd-line-args-dynamic.lambda1 bool(it arr<char>) */
uint8_t parse_cmd_line_args_dynamic__lambda1(struct ctx* ctx, struct void_ _closure, struct arr_0 it) {
	return _equal_4(it, (struct arr_0) {2, constantarr_0_13});
}
/* parse-named-args dict<arr<char>, arr<arr<char>>>(args arr<arr<char>>) */
struct dict_0* parse_named_args(struct ctx* ctx, struct arr_1 args) {
	struct mut_dict_0* res0;
	res0 = mut_dict_0(ctx);
	
	parse_named_args_recur(ctx, args, res0);
	return move_to_dict__e_0(ctx, res0);
}
/* mut-dict<arr<char>, arr<arr<char>>> mut-dict<arr<char>, arr<arr<char>>>() */
struct mut_dict_0* mut_dict_0(struct ctx* ctx) {
	struct mut_dict_0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_dict_0));
	temp0 = (struct mut_dict_0*) _0;
	
	struct mut_list_1* _1 = mut_list_0(ctx);
	struct mut_list_2* _2 = mut_list_1(ctx);
	*temp0 = (struct mut_dict_0) {(struct void_) {}, _1, _2};
	return temp0;
}
/* mut-list<?k> mut-list<arr<char>>() */
struct mut_list_1* mut_list_0(struct ctx* ctx) {
	struct mut_list_1* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_list_1));
	temp0 = (struct mut_list_1*) _0;
	
	struct mut_arr_1 _1 = mut_arr_5();
	*temp0 = (struct mut_list_1) {_1, 0u};
	return temp0;
}
/* mut-arr<?t> mut-arr<arr<char>>() */
struct mut_arr_1 mut_arr_5(void) {
	return (struct mut_arr_1) {(struct void_) {}, (struct arr_1) {0u, NULL}};
}
/* mut-list<?v> mut-list<arr<arr<char>>>() */
struct mut_list_2* mut_list_1(struct ctx* ctx) {
	struct mut_list_2* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_list_2));
	temp0 = (struct mut_list_2*) _0;
	
	struct mut_arr_2 _1 = mut_arr_6();
	*temp0 = (struct mut_list_2) {_1, 0u};
	return temp0;
}
/* mut-arr<?t> mut-arr<arr<arr<char>>>() */
struct mut_arr_2 mut_arr_6(void) {
	return (struct mut_arr_2) {(struct void_) {}, (struct arr_6) {0u, NULL}};
}
/* parse-named-args-recur void(args arr<arr<char>>, builder mut-dict<arr<char>, arr<arr<char>>>) */
struct void_ parse_named_args_recur(struct ctx* ctx, struct arr_1 args, struct mut_dict_0* builder) {
	top:;
	struct arr_0 first_name0;
	struct arr_0 _0 = first_0(ctx, args);
	first_name0 = remove_start(ctx, _0, (struct arr_0) {2, constantarr_0_13});
	
	struct arr_1 tl1;
	tl1 = tail_0(ctx, args);
	
	struct opt_8 _1 = find_index(ctx, tl1, (struct fun_act1_6) {2, .as2 = (struct void_) {}});
	switch (_1.kind) {
		case 0: {
			return set_subscript_6(ctx, builder, first_name0, tl1);
		}
		case 1: {
			struct some_8 s2 = _1.as1;
			
			uint64_t next_named_arg_index3;
			next_named_arg_index3 = s2.value;
			
			struct arrow_0 _2 = _arrow_0(ctx, 0u, next_named_arg_index3);
			struct arr_1 _3 = subscript_3(ctx, tl1, _2);
			set_subscript_6(ctx, builder, first_name0, _3);
			struct arrow_0 _4 = _arrow_0(ctx, next_named_arg_index3, args.size);
			struct arr_1 _5 = subscript_3(ctx, args, _4);
			args = _5;
			builder = builder;
			goto top;
		}
		default:
			return (struct void_) {};
	}
}
/* remove-start<char> arr<char>(a arr<char>, start arr<char>) */
struct arr_0 remove_start(struct ctx* ctx, struct arr_0 a, struct arr_0 start) {
	struct opt_11 _0 = try_remove_start(ctx, a, start);
	return force_0(ctx, _0);
}
/* force<arr<?t>> arr<char>(a opt<arr<char>>) */
struct arr_0 force_0(struct ctx* ctx, struct opt_11 a) {
	struct opt_11 _0 = a;
	switch (_0.kind) {
		case 0: {
			return fail_1(ctx, (struct arr_0) {27, constantarr_0_14});
		}
		case 1: {
			struct some_11 s0 = _0.as1;
			
			return s0.value;
		}
		default:
			return (struct arr_0) {0, NULL};
	}
}
/* fail<?t> arr<char>(reason arr<char>) */
struct arr_0 fail_1(struct ctx* ctx, struct arr_0 reason) {
	struct backtrace _0 = get_backtrace(ctx);
	return throw_1(ctx, (struct exception) {reason, _0});
}
/* throw<?t> arr<char>(e exception) */
struct arr_0 throw_1(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx0;
	exn_ctx0 = get_exception_ctx(ctx);
	
	uint8_t _0 = null__q_1(exn_ctx0->jmp_buf_ptr);
	hard_forbid(_0);
	exn_ctx0->thrown_exception = e;
	int32_t _1 = number_to_throw(ctx);
	(longjmp(exn_ctx0->jmp_buf_ptr, _1), (struct void_) {});
	return todo_5();
}
/* todo<?t> arr<char>() */
struct arr_0 todo_5(void) {
	(abort(), (struct void_) {});
	return (struct arr_0) {0, NULL};
}
/* try-remove-start<?t> opt<arr<char>>(a arr<char>, start arr<char>) */
struct opt_11 try_remove_start(struct ctx* ctx, struct arr_0 a, struct arr_0 start) {
	uint8_t _0 = starts_with__q(ctx, a, start);
	if (_0) {
		struct arrow_0 _1 = _arrow_0(ctx, start.size, a.size);
		struct arr_0 _2 = subscript_25(ctx, a, _1);
		return (struct opt_11) {1, .as1 = (struct some_11) {_2}};
	} else {
		return (struct opt_11) {0, .as0 = (struct none) {}};
	}
}
/* first<arr<char>> arr<char>(a arr<arr<char>>) */
struct arr_0 first_0(struct ctx* ctx, struct arr_1 a) {
	uint8_t _0 = empty__q_1(a);
	forbid_0(ctx, _0);
	return subscript_0(ctx, a, 0u);
}
/* parse-named-args-recur.lambda0 bool(it arr<char>) */
uint8_t parse_named_args_recur__lambda0(struct ctx* ctx, struct void_ _closure, struct arr_0 it) {
	return starts_with__q(ctx, it, (struct arr_0) {2, constantarr_0_13});
}
/* set-subscript<arr<char>, arr<arr<char>>> void(a mut-dict<arr<char>, arr<arr<char>>>, key arr<char>, value arr<arr<char>>) */
struct void_ set_subscript_6(struct ctx* ctx, struct mut_dict_0* a, struct arr_0 key, struct arr_1 value) {
	return set_subscript_recur_0(ctx, a, 0u, key, value);
}
/* set-subscript-recur<?k, ?v> void(a mut-dict<arr<char>, arr<arr<char>>>, idx nat, key arr<char>, value arr<arr<char>>) */
struct void_ set_subscript_recur_0(struct ctx* ctx, struct mut_dict_0* a, uint64_t idx, struct arr_0 key, struct arr_1 value) {
	top:;
	uint8_t _0 = _equal_0(idx, a->keys->size);
	if (_0) {
		_concatEquals_0(ctx, a->keys, key);
		return _concatEquals_1(ctx, a->values, value);
	} else {
		struct arr_0 _1 = subscript_38(ctx, a->keys, idx);
		struct comparison _2 = compare_425(key, _1);
		switch (_2.kind) {
			case 0: {
				insert_at__e_0(ctx, a->keys, idx, key);
				return insert_at__e_1(ctx, a->values, idx, value);
			}
			case 1: {
				return set_subscript_8(ctx, a->values, idx, value);
			}
			case 2: {
				uint64_t _3 = _plus(ctx, idx, 1u);
				a = a;
				idx = _3;
				key = key;
				value = value;
				goto top;
			}
			default:
				return (struct void_) {};
		}
	}
}
/* ~=<?k> void(a mut-list<arr<char>>, value arr<char>) */
struct void_ _concatEquals_0(struct ctx* ctx, struct mut_list_1* a, struct arr_0 value) {
	incr_capacity__e_0(ctx, a);
	uint64_t _0 = capacity_1(a);
	uint8_t _1 = _less_0(a->size, _0);
	assert_0(ctx, _1);
	struct arr_0* _2 = data_4(a);
	set_subscript_1(_2, a->size, value);
	uint64_t _3 = incr_5(ctx, a->size);
	return (a->size = _3, (struct void_) {});
}
/* incr-capacity!<?t> void(a mut-list<arr<char>>) */
struct void_ incr_capacity__e_0(struct ctx* ctx, struct mut_list_1* a) {
	uint64_t _0 = incr_5(ctx, a->size);
	uint64_t _1 = round_up_to_power_of_two(ctx, _0);
	return ensure_capacity_0(ctx, a, _1);
}
/* ensure-capacity<?t> void(a mut-list<arr<char>>, min-capacity nat) */
struct void_ ensure_capacity_0(struct ctx* ctx, struct mut_list_1* a, uint64_t min_capacity) {
	uint64_t _0 = capacity_1(a);
	uint8_t _1 = _less_0(_0, min_capacity);
	if (_1) {
		return increase_capacity_to__e_0(ctx, a, min_capacity);
	} else {
		return (struct void_) {};
	}
}
/* capacity<?t> nat(a mut-list<arr<char>>) */
uint64_t capacity_1(struct mut_list_1* a) {
	return size_2(a->backing);
}
/* increase-capacity-to!<?t> void(a mut-list<arr<char>>, new-capacity nat) */
struct void_ increase_capacity_to__e_0(struct ctx* ctx, struct mut_list_1* a, uint64_t new_capacity) {
	uint64_t _0 = capacity_1(a);
	uint8_t _1 = _greater(new_capacity, _0);
	assert_0(ctx, _1);
	struct arr_0* old_data0;
	old_data0 = data_4(a);
	
	struct arr_0* _2 = alloc_uninitialized_1(ctx, new_capacity);
	struct mut_arr_1 _3 = mut_arr_2(new_capacity, _2);
	a->backing = _3;
	struct arr_0* _4 = data_4(a);
	copy_data_from_1(ctx, _4, old_data0, a->size);
	uint64_t _5 = _plus(ctx, a->size, 1u);
	uint64_t _6 = size_2(a->backing);
	struct arrow_0 _7 = _arrow_0(ctx, _5, _6);
	struct mut_arr_1 _8 = subscript_35(ctx, a->backing, _7);
	return set_zero_elements_0(_8);
}
/* data<?t> ptr<arr<char>>(a mut-list<arr<char>>) */
struct arr_0* data_4(struct mut_list_1* a) {
	return data_2(a->backing);
}
/* copy-data-from<?t> void(to ptr<arr<char>>, from ptr<arr<char>>, len nat) */
struct void_ copy_data_from_1(struct ctx* ctx, struct arr_0* to, struct arr_0* from, uint64_t len) {
	return (memcpy((uint8_t*) to, (uint8_t*) from, (len * sizeof(struct arr_0))), (struct void_) {});
}
/* set-zero-elements<?t> void(a mut-arr<arr<char>>) */
struct void_ set_zero_elements_0(struct mut_arr_1 a) {
	struct arr_0* _0 = data_2(a);
	uint64_t _1 = size_2(a);
	return set_zero_range_1(_0, _1);
}
/* set-zero-range<?t> void(begin ptr<arr<char>>, size nat) */
struct void_ set_zero_range_1(struct arr_0* begin, uint64_t size) {
	return (memset((uint8_t*) begin, 0u, (size * sizeof(struct arr_0))), (struct void_) {});
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
		uint64_t _1 = _times_0(ctx, acc, 2u);
		acc = _1;
		n = n;
		goto top;
	}
}
/* * nat(a nat, b nat) */
uint64_t _times_0(struct ctx* ctx, uint64_t a, uint64_t b) {
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
		assert_0(ctx, _3);
		uint64_t _4 = _divide(ctx, res0, a);
		uint8_t _5 = _equal_0(_4, b);
		assert_0(ctx, _5);
		return res0;
	}
}
/* ~=<?v> void(a mut-list<arr<arr<char>>>, value arr<arr<char>>) */
struct void_ _concatEquals_1(struct ctx* ctx, struct mut_list_2* a, struct arr_1 value) {
	incr_capacity__e_1(ctx, a);
	uint64_t _0 = capacity_2(a);
	uint8_t _1 = _less_0(a->size, _0);
	assert_0(ctx, _1);
	struct arr_1* _2 = data_5(a);
	set_subscript_3(_2, a->size, value);
	uint64_t _3 = incr_5(ctx, a->size);
	return (a->size = _3, (struct void_) {});
}
/* incr-capacity!<?t> void(a mut-list<arr<arr<char>>>) */
struct void_ incr_capacity__e_1(struct ctx* ctx, struct mut_list_2* a) {
	uint64_t _0 = incr_5(ctx, a->size);
	uint64_t _1 = round_up_to_power_of_two(ctx, _0);
	return ensure_capacity_1(ctx, a, _1);
}
/* ensure-capacity<?t> void(a mut-list<arr<arr<char>>>, min-capacity nat) */
struct void_ ensure_capacity_1(struct ctx* ctx, struct mut_list_2* a, uint64_t min_capacity) {
	uint64_t _0 = capacity_2(a);
	uint8_t _1 = _less_0(_0, min_capacity);
	if (_1) {
		return increase_capacity_to__e_1(ctx, a, min_capacity);
	} else {
		return (struct void_) {};
	}
}
/* capacity<?t> nat(a mut-list<arr<arr<char>>>) */
uint64_t capacity_2(struct mut_list_2* a) {
	return size_3(a->backing);
}
/* increase-capacity-to!<?t> void(a mut-list<arr<arr<char>>>, new-capacity nat) */
struct void_ increase_capacity_to__e_1(struct ctx* ctx, struct mut_list_2* a, uint64_t new_capacity) {
	uint64_t _0 = capacity_2(a);
	uint8_t _1 = _greater(new_capacity, _0);
	assert_0(ctx, _1);
	struct arr_1* old_data0;
	old_data0 = data_5(a);
	
	struct arr_1* _2 = alloc_uninitialized_2(ctx, new_capacity);
	struct mut_arr_2 _3 = mut_arr_4(new_capacity, _2);
	a->backing = _3;
	struct arr_1* _4 = data_5(a);
	copy_data_from_2(ctx, _4, old_data0, a->size);
	uint64_t _5 = _plus(ctx, a->size, 1u);
	uint64_t _6 = size_3(a->backing);
	struct arrow_0 _7 = _arrow_0(ctx, _5, _6);
	struct mut_arr_2 _8 = subscript_36(ctx, a->backing, _7);
	return set_zero_elements_1(_8);
}
/* data<?t> ptr<arr<arr<char>>>(a mut-list<arr<arr<char>>>) */
struct arr_1* data_5(struct mut_list_2* a) {
	return data_3(a->backing);
}
/* copy-data-from<?t> void(to ptr<arr<arr<char>>>, from ptr<arr<arr<char>>>, len nat) */
struct void_ copy_data_from_2(struct ctx* ctx, struct arr_1* to, struct arr_1* from, uint64_t len) {
	return (memcpy((uint8_t*) to, (uint8_t*) from, (len * sizeof(struct arr_1))), (struct void_) {});
}
/* set-zero-elements<?t> void(a mut-arr<arr<arr<char>>>) */
struct void_ set_zero_elements_1(struct mut_arr_2 a) {
	struct arr_1* _0 = data_3(a);
	uint64_t _1 = size_3(a);
	return set_zero_range_2(_0, _1);
}
/* set-zero-range<?t> void(begin ptr<arr<arr<char>>>, size nat) */
struct void_ set_zero_range_2(struct arr_1* begin, uint64_t size) {
	return (memset((uint8_t*) begin, 0u, (size * sizeof(struct arr_1))), (struct void_) {});
}
/* subscript<?k> arr<char>(a mut-list<arr<char>>, index nat) */
struct arr_0 subscript_38(struct ctx* ctx, struct mut_list_1* a, uint64_t index) {
	uint8_t _0 = _less_0(index, a->size);
	assert_0(ctx, _0);
	return noctx_at_8(a, index);
}
/* noctx-at<?t> arr<char>(a mut-list<arr<char>>, index nat) */
struct arr_0 noctx_at_8(struct mut_list_1* a, uint64_t index) {
	uint8_t _0 = _less_0(index, a->size);
	hard_assert(_0);
	struct arr_0* _1 = data_4(a);
	return subscript_2(_1, index);
}
/* insert-at!<?k> void(a mut-list<arr<char>>, index nat, value arr<char>) */
struct void_ insert_at__e_0(struct ctx* ctx, struct mut_list_1* a, uint64_t index, struct arr_0 value) {
	uint8_t _0 = _lessOrEqual(index, a->size);
	assert_0(ctx, _0);
	incr_capacity__e_0(ctx, a);
	struct arr_0* dest0;
	struct arr_0* _1 = data_4(a);
	dest0 = ((_1 + index) + 1u);
	
	struct arr_0* src1;
	struct arr_0* _2 = data_4(a);
	src1 = (_2 + index);
	
	uint64_t n2;
	n2 = _minus_2(ctx, a->size, index);
	
	uint64_t _3 = _times_0(ctx, n2, sizeof(struct arr_0));
	(memmove((uint8_t*) dest0, (uint8_t*) src1, _3), (struct void_) {});
	set_subscript_7(ctx, a, index, value);
	uint64_t _4 = _plus(ctx, a->size, 1u);
	a->size = _4;
	uint64_t _5 = capacity_1(a);
	uint8_t _6 = _lessOrEqual(a->size, _5);
	return assert_0(ctx, _6);
}
/* set-subscript<?t> void(a mut-list<arr<char>>, index nat, value arr<char>) */
struct void_ set_subscript_7(struct ctx* ctx, struct mut_list_1* a, uint64_t index, struct arr_0 value) {
	uint8_t _0 = _less_0(index, a->size);
	assert_0(ctx, _0);
	return noctx_set_at__e_1(a, index, value);
}
/* noctx-set-at!<?t> void(a mut-list<arr<char>>, index nat, value arr<char>) */
struct void_ noctx_set_at__e_1(struct mut_list_1* a, uint64_t index, struct arr_0 value) {
	uint8_t _0 = _less_0(index, a->size);
	hard_assert(_0);
	struct arr_0* _1 = data_4(a);
	return set_subscript_1(_1, index, value);
}
/* insert-at!<?v> void(a mut-list<arr<arr<char>>>, index nat, value arr<arr<char>>) */
struct void_ insert_at__e_1(struct ctx* ctx, struct mut_list_2* a, uint64_t index, struct arr_1 value) {
	uint8_t _0 = _lessOrEqual(index, a->size);
	assert_0(ctx, _0);
	incr_capacity__e_1(ctx, a);
	struct arr_1* dest0;
	struct arr_1* _1 = data_5(a);
	dest0 = ((_1 + index) + 1u);
	
	struct arr_1* src1;
	struct arr_1* _2 = data_5(a);
	src1 = (_2 + index);
	
	uint64_t n2;
	n2 = _minus_2(ctx, a->size, index);
	
	uint64_t _3 = _times_0(ctx, n2, sizeof(struct arr_1));
	(memmove((uint8_t*) dest0, (uint8_t*) src1, _3), (struct void_) {});
	set_subscript_8(ctx, a, index, value);
	uint64_t _4 = _plus(ctx, a->size, 1u);
	a->size = _4;
	uint64_t _5 = capacity_2(a);
	uint8_t _6 = _lessOrEqual(a->size, _5);
	return assert_0(ctx, _6);
}
/* set-subscript<?t> void(a mut-list<arr<arr<char>>>, index nat, value arr<arr<char>>) */
struct void_ set_subscript_8(struct ctx* ctx, struct mut_list_2* a, uint64_t index, struct arr_1 value) {
	uint8_t _0 = _less_0(index, a->size);
	assert_0(ctx, _0);
	return noctx_set_at__e_2(a, index, value);
}
/* noctx-set-at!<?t> void(a mut-list<arr<arr<char>>>, index nat, value arr<arr<char>>) */
struct void_ noctx_set_at__e_2(struct mut_list_2* a, uint64_t index, struct arr_1 value) {
	uint8_t _0 = _less_0(index, a->size);
	hard_assert(_0);
	struct arr_1* _1 = data_5(a);
	return set_subscript_3(_1, index, value);
}
/* move-to-dict!<arr<char>, arr<arr<char>>> dict<arr<char>, arr<arr<char>>>(m mut-dict<arr<char>, arr<arr<char>>>) */
struct dict_0* move_to_dict__e_0(struct ctx* ctx, struct mut_dict_0* m) {
	struct arr_1 _0 = move_to_arr__e_0(m->keys);
	struct arr_6 _1 = move_to_arr__e_1(m->values);
	return dict_1(ctx, _0, _1);
}
/* move-to-arr!<?k> arr<arr<char>>(a mut-list<arr<char>>) */
struct arr_1 move_to_arr__e_0(struct mut_list_1* a) {
	struct arr_1 res0;
	struct arr_0* _0 = data_4(a);
	res0 = (struct arr_1) {a->size, _0};
	
	struct mut_arr_1 _1 = mut_arr_5();
	a->backing = _1;
	a->size = 0u;
	return res0;
}
/* move-to-arr!<?v> arr<arr<arr<char>>>(a mut-list<arr<arr<char>>>) */
struct arr_6 move_to_arr__e_1(struct mut_list_2* a) {
	struct arr_6 res0;
	struct arr_1* _0 = data_5(a);
	res0 = (struct arr_6) {a->size, _0};
	
	struct mut_arr_2 _1 = mut_arr_6();
	a->backing = _1;
	a->size = 0u;
	return res0;
}
/* assert void(condition bool, message arr<char>) */
struct void_ assert_1(struct ctx* ctx, uint8_t condition, struct arr_0 message) {
	uint8_t _0 = not(condition);
	if (_0) {
		return fail_0(ctx, message);
	} else {
		return (struct void_) {};
	}
}
/* fill-mut-list<opt<arr<arr<char>>>> mut-list<opt<arr<arr<char>>>>(size nat, value opt<arr<arr<char>>>) */
struct mut_list_3* fill_mut_list(struct ctx* ctx, uint64_t size, struct opt_10 value) {
	struct mut_arr_3 backing0;
	backing0 = fill_mut_arr(ctx, size, value);
	
	struct mut_list_3* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_list_3));
	temp0 = (struct mut_list_3*) _0;
	
	*temp0 = (struct mut_list_3) {backing0, size};
	return temp0;
}
/* fill-mut-arr<?t> mut-arr<opt<arr<arr<char>>>>(size nat, value opt<arr<arr<char>>>) */
struct mut_arr_3 fill_mut_arr(struct ctx* ctx, uint64_t size, struct opt_10 value) {
	struct fill_mut_arr__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct fill_mut_arr__lambda0));
	temp0 = (struct fill_mut_arr__lambda0*) _0;
	
	*temp0 = (struct fill_mut_arr__lambda0) {value};
	return make_mut_arr_2(ctx, size, (struct fun_act1_10) {0, .as0 = temp0});
}
/* make-mut-arr<?t> mut-arr<opt<arr<arr<char>>>>(size nat, f fun-act1<opt<arr<arr<char>>>, nat>) */
struct mut_arr_3 make_mut_arr_2(struct ctx* ctx, uint64_t size, struct fun_act1_10 f) {
	struct mut_arr_3 res0;
	res0 = uninitialized_mut_arr_2(ctx, size);
	
	struct opt_10* _0 = data_6(res0);
	fill_ptr_range_2(ctx, _0, size, f);
	return res0;
}
/* uninitialized-mut-arr<?t> mut-arr<opt<arr<arr<char>>>>(size nat) */
struct mut_arr_3 uninitialized_mut_arr_2(struct ctx* ctx, uint64_t size) {
	struct opt_10* _0 = alloc_uninitialized_3(ctx, size);
	return mut_arr_7(size, _0);
}
/* mut-arr<?t> mut-arr<opt<arr<arr<char>>>>(size nat, data ptr<opt<arr<arr<char>>>>) */
struct mut_arr_3 mut_arr_7(uint64_t size, struct opt_10* data) {
	return (struct mut_arr_3) {(struct void_) {}, (struct arr_5) {size, data}};
}
/* alloc-uninitialized<?t> ptr<opt<arr<arr<char>>>>(size nat) */
struct opt_10* alloc_uninitialized_3(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(struct opt_10)));
	return (struct opt_10*) _0;
}
/* fill-ptr-range<?t> void(begin ptr<opt<arr<arr<char>>>>, size nat, f fun-act1<opt<arr<arr<char>>>, nat>) */
struct void_ fill_ptr_range_2(struct ctx* ctx, struct opt_10* begin, uint64_t size, struct fun_act1_10 f) {
	return fill_ptr_range_recur_2(ctx, begin, 0u, size, f);
}
/* fill-ptr-range-recur<?t> void(begin ptr<opt<arr<arr<char>>>>, i nat, size nat, f fun-act1<opt<arr<arr<char>>>, nat>) */
struct void_ fill_ptr_range_recur_2(struct ctx* ctx, struct opt_10* begin, uint64_t i, uint64_t size, struct fun_act1_10 f) {
	top:;
	uint8_t _0 = _notEqual_1(i, size);
	if (_0) {
		struct opt_10 _1 = subscript_39(ctx, f, i);
		set_subscript_9(begin, i, _1);
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
/* set-subscript<?t> void(a ptr<opt<arr<arr<char>>>>, n nat, value opt<arr<arr<char>>>) */
struct void_ set_subscript_9(struct opt_10* a, uint64_t n, struct opt_10 value) {
	return (*(a + n) = value, (struct void_) {});
}
/* subscript<?t, nat> opt<arr<arr<char>>>(a fun-act1<opt<arr<arr<char>>>, nat>, p0 nat) */
struct opt_10 subscript_39(struct ctx* ctx, struct fun_act1_10 a, uint64_t p0) {
	return call_w_ctx_498(a, ctx, p0);
}
/* call-w-ctx<opt<arr<arr<char>>>, nat-64> (generated) (generated) */
struct opt_10 call_w_ctx_498(struct fun_act1_10 a, struct ctx* ctx, uint64_t p0) {
	struct fun_act1_10 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct fill_mut_arr__lambda0* closure0 = _0.as0;
			
			return fill_mut_arr__lambda0(ctx, closure0, p0);
		}
		default:
			return (struct opt_10) {0};
	}
}
/* data<?t> ptr<opt<arr<arr<char>>>>(a mut-arr<opt<arr<arr<char>>>>) */
struct opt_10* data_6(struct mut_arr_3 a) {
	return a.inner.data;
}
/* fill-mut-arr<?t>.lambda0 opt<arr<arr<char>>>(ignore nat) */
struct opt_10 fill_mut_arr__lambda0(struct ctx* ctx, struct fill_mut_arr__lambda0* _closure, uint64_t ignore) {
	return _closure->value;
}
/* each<arr<char>, arr<arr<char>>> void(d dict<arr<char>, arr<arr<char>>>, f fun-act2<void, arr<char>, arr<arr<char>>>) */
struct void_ each_0(struct ctx* ctx, struct dict_0* d, struct fun_act2_1 f) {
	top:;
	uint8_t _0 = empty__q_6(ctx, d);
	uint8_t _1 = not(_0);
	if (_1) {
		struct arr_0 _2 = first_0(ctx, d->keys);
		struct arr_1 _3 = first_1(ctx, d->values);
		subscript_40(ctx, f, _2, _3);
		struct arr_1 _4 = tail_0(ctx, d->keys);
		struct arr_6 _5 = tail_2(ctx, d->values);
		struct dict_0* _6 = dict_1(ctx, _4, _5);
		d = _6;
		f = f;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* empty?<?k, ?v> bool(d dict<arr<char>, arr<arr<char>>>) */
uint8_t empty__q_6(struct ctx* ctx, struct dict_0* d) {
	return empty__q_1(d->keys);
}
/* subscript<void, ?k, ?v> void(a fun-act2<void, arr<char>, arr<arr<char>>>, p0 arr<char>, p1 arr<arr<char>>) */
struct void_ subscript_40(struct ctx* ctx, struct fun_act2_1 a, struct arr_0 p0, struct arr_1 p1) {
	return call_w_ctx_504(a, ctx, p0, p1);
}
/* call-w-ctx<void, arr<char>, arr<arr<char>>> (generated) (generated) */
struct void_ call_w_ctx_504(struct fun_act2_1 a, struct ctx* ctx, struct arr_0 p0, struct arr_1 p1) {
	struct fun_act2_1 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct parse_cmd_line_args__lambda0* closure0 = _0.as0;
			
			return parse_cmd_line_args__lambda0(ctx, closure0, p0, p1);
		}
		default:
			return (struct void_) {};
	}
}
/* first<?v> arr<arr<char>>(a arr<arr<arr<char>>>) */
struct arr_1 first_1(struct ctx* ctx, struct arr_6 a) {
	uint8_t _0 = empty__q_7(a);
	forbid_0(ctx, _0);
	return subscript_31(ctx, a, 0u);
}
/* empty?<?t> bool(a arr<arr<arr<char>>>) */
uint8_t empty__q_7(struct arr_6 a) {
	return _equal_0(a.size, 0u);
}
/* tail<?v> arr<arr<arr<char>>>(a arr<arr<arr<char>>>) */
struct arr_6 tail_2(struct ctx* ctx, struct arr_6 a) {
	uint8_t _0 = empty__q_7(a);
	forbid_0(ctx, _0);
	struct arrow_0 _1 = _arrow_0(ctx, 1u, a.size);
	return subscript_37(ctx, a, _1);
}
/* index-of<arr<char>> opt<nat>(a arr<arr<char>>, value arr<char>) */
struct opt_8 index_of(struct ctx* ctx, struct arr_1 a, struct arr_0 value) {
	struct index_of__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct index_of__lambda0));
	temp0 = (struct index_of__lambda0*) _0;
	
	*temp0 = (struct index_of__lambda0) {value};
	return find_index(ctx, a, (struct fun_act1_6) {3, .as3 = temp0});
}
/* index-of<arr<char>>.lambda0 bool(it arr<char>) */
uint8_t index_of__lambda0(struct ctx* ctx, struct index_of__lambda0* _closure, struct arr_0 it) {
	return _equal_4(it, _closure->value);
}
/* has?<arr<arr<char>>> bool(a opt<arr<arr<char>>>) */
uint8_t has__q_1(struct opt_10 a) {
	uint8_t _0 = empty__q_8(a);
	return not(_0);
}
/* empty?<?t> bool(a opt<arr<arr<char>>>) */
uint8_t empty__q_8(struct opt_10 a) {
	struct opt_10 _0 = a;
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
/* subscript<opt<arr<arr<char>>>> opt<arr<arr<char>>>(a mut-list<opt<arr<arr<char>>>>, index nat) */
struct opt_10 subscript_41(struct ctx* ctx, struct mut_list_3* a, uint64_t index) {
	uint8_t _0 = _less_0(index, a->size);
	assert_0(ctx, _0);
	return noctx_at_9(a, index);
}
/* noctx-at<?t> opt<arr<arr<char>>>(a mut-list<opt<arr<arr<char>>>>, index nat) */
struct opt_10 noctx_at_9(struct mut_list_3* a, uint64_t index) {
	uint8_t _0 = _less_0(index, a->size);
	hard_assert(_0);
	struct opt_10* _1 = data_7(a);
	return subscript_42(_1, index);
}
/* subscript<?t> opt<arr<arr<char>>>(a ptr<opt<arr<arr<char>>>>, n nat) */
struct opt_10 subscript_42(struct opt_10* a, uint64_t n) {
	return *(a + n);
}
/* data<?t> ptr<opt<arr<arr<char>>>>(a mut-list<opt<arr<arr<char>>>>) */
struct opt_10* data_7(struct mut_list_3* a) {
	return data_6(a->backing);
}
/* set-subscript<opt<arr<arr<char>>>> void(a mut-list<opt<arr<arr<char>>>>, index nat, value opt<arr<arr<char>>>) */
struct void_ set_subscript_10(struct ctx* ctx, struct mut_list_3* a, uint64_t index, struct opt_10 value) {
	uint8_t _0 = _less_0(index, a->size);
	assert_0(ctx, _0);
	return noctx_set_at__e_3(a, index, value);
}
/* noctx-set-at!<?t> void(a mut-list<opt<arr<arr<char>>>>, index nat, value opt<arr<arr<char>>>) */
struct void_ noctx_set_at__e_3(struct mut_list_3* a, uint64_t index, struct opt_10 value) {
	uint8_t _0 = _less_0(index, a->size);
	hard_assert(_0);
	struct opt_10* _1 = data_7(a);
	return set_subscript_9(_1, index, value);
}
/* parse-cmd-line-args<test-options>.lambda0 void(key arr<char>, value arr<arr<char>>) */
struct void_ parse_cmd_line_args__lambda0(struct ctx* ctx, struct parse_cmd_line_args__lambda0* _closure, struct arr_0 key, struct arr_1 value) {
	struct opt_8 _0 = index_of(ctx, _closure->t_names, key);
	switch (_0.kind) {
		case 0: {
			uint8_t _1 = _equal_4(key, (struct arr_0) {4, constantarr_0_16});
			if (_1) {
				return (_closure->help->subscript = 1, (struct void_) {});
			} else {
				struct arr_0 _2 = _concat_0(ctx, (struct arr_0) {15, constantarr_0_17}, key);
				return fail_0(ctx, _2);
			}
		}
		case 1: {
			struct some_8 s0 = _0.as1;
			
			uint64_t idx1;
			idx1 = s0.value;
			
			struct opt_10 _3 = subscript_41(ctx, _closure->values, idx1);
			uint8_t _4 = has__q_1(_3);
			forbid_0(ctx, _4);
			return set_subscript_10(ctx, _closure->values, idx1, (struct opt_10) {1, .as1 = (struct some_10) {value}});
		}
		default:
			return (struct void_) {};
	}
}
/* subscript<?t, arr<opt<arr<arr<char>>>>> test-options(a fun1<test-options, arr<opt<arr<arr<char>>>>>, p0 arr<opt<arr<arr<char>>>>) */
struct test_options subscript_43(struct ctx* ctx, struct fun1_2 a, struct arr_5 p0) {
	return call_w_ctx_520(a, ctx, p0);
}
/* call-w-ctx<test-options, arr<opt<arr<arr<char>>>>> (generated) (generated) */
struct test_options call_w_ctx_520(struct fun1_2 a, struct ctx* ctx, struct arr_5 p0) {
	struct fun1_2 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return main_0__lambda0(ctx, closure0, p0);
		}
		default:
			return (struct test_options) {0, 0, 0};
	}
}
/* move-to-arr!<opt<arr<arr<char>>>> arr<opt<arr<arr<char>>>>(a mut-list<opt<arr<arr<char>>>>) */
struct arr_5 move_to_arr__e_2(struct mut_list_3* a) {
	struct arr_5 res0;
	struct opt_10* _0 = data_7(a);
	res0 = (struct arr_5) {a->size, _0};
	
	struct mut_arr_3 _1 = mut_arr_8();
	a->backing = _1;
	a->size = 0u;
	return res0;
}
/* mut-arr<?t> mut-arr<opt<arr<arr<char>>>>() */
struct mut_arr_3 mut_arr_8(void) {
	return (struct mut_arr_3) {(struct void_) {}, (struct arr_5) {0u, NULL}};
}
/* subscript<opt<arr<arr<char>>>> opt<arr<arr<char>>>(a arr<opt<arr<arr<char>>>>, index nat) */
struct opt_10 subscript_44(struct ctx* ctx, struct arr_5 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	return noctx_at_10(a, index);
}
/* noctx-at<?t> opt<arr<arr<char>>>(a arr<opt<arr<arr<char>>>>, index nat) */
struct opt_10 noctx_at_10(struct arr_5 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	hard_assert(_0);
	return subscript_42(a.data, index);
}
/* force<nat> nat(a opt<nat>) */
uint64_t force_1(struct ctx* ctx, struct opt_8 a) {
	struct opt_8 _0 = a;
	switch (_0.kind) {
		case 0: {
			return fail_2(ctx, (struct arr_0) {27, constantarr_0_14});
		}
		case 1: {
			struct some_8 s0 = _0.as1;
			
			return s0.value;
		}
		default:
			return 0;
	}
}
/* fail<?t> nat(reason arr<char>) */
uint64_t fail_2(struct ctx* ctx, struct arr_0 reason) {
	struct backtrace _0 = get_backtrace(ctx);
	return throw_2(ctx, (struct exception) {reason, _0});
}
/* throw<?t> nat(e exception) */
uint64_t throw_2(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx0;
	exn_ctx0 = get_exception_ctx(ctx);
	
	uint8_t _0 = null__q_1(exn_ctx0->jmp_buf_ptr);
	hard_forbid(_0);
	exn_ctx0->thrown_exception = e;
	int32_t _1 = number_to_throw(ctx);
	(longjmp(exn_ctx0->jmp_buf_ptr, _1), (struct void_) {});
	return todo_4();
}
/* parse-nat opt<nat>(a arr<char>) */
struct opt_8 parse_nat(struct ctx* ctx, struct arr_0 a) {
	uint8_t _0 = empty__q_0(a);
	if (_0) {
		return (struct opt_8) {0, .as0 = (struct none) {}};
	} else {
		return parse_nat_recur(ctx, a, 0u);
	}
}
/* parse-nat-recur opt<nat>(a arr<char>, accum nat) */
struct opt_8 parse_nat_recur(struct ctx* ctx, struct arr_0 a, uint64_t accum) {
	top:;
	uint8_t _0 = empty__q_0(a);
	if (_0) {
		return (struct opt_8) {1, .as1 = (struct some_8) {accum}};
	} else {
		char _1 = first_2(ctx, a);
		struct opt_8 _2 = char_to_nat(ctx, _1);
		switch (_2.kind) {
			case 0: {
				return (struct opt_8) {0, .as0 = (struct none) {}};
			}
			case 1: {
				struct some_8 s0 = _2.as1;
				
				struct arr_0 _3 = tail_3(ctx, a);
				uint64_t _4 = _times_0(ctx, accum, 10u);
				uint64_t _5 = _plus(ctx, _4, s0.value);
				a = _3;
				accum = _5;
				goto top;
			}
			default:
				return (struct opt_8) {0};
		}
	}
}
/* char-to-nat opt<nat>(c char) */
struct opt_8 char_to_nat(struct ctx* ctx, char c) {
	uint8_t _0 = _equal_3(c, 48u);
	if (_0) {
		return (struct opt_8) {1, .as1 = (struct some_8) {0u}};
	} else {
		uint8_t _1 = _equal_3(c, 49u);
		if (_1) {
			return (struct opt_8) {1, .as1 = (struct some_8) {1u}};
		} else {
			uint8_t _2 = _equal_3(c, 50u);
			if (_2) {
				return (struct opt_8) {1, .as1 = (struct some_8) {2u}};
			} else {
				uint8_t _3 = _equal_3(c, 51u);
				if (_3) {
					return (struct opt_8) {1, .as1 = (struct some_8) {3u}};
				} else {
					uint8_t _4 = _equal_3(c, 52u);
					if (_4) {
						return (struct opt_8) {1, .as1 = (struct some_8) {4u}};
					} else {
						uint8_t _5 = _equal_3(c, 53u);
						if (_5) {
							return (struct opt_8) {1, .as1 = (struct some_8) {5u}};
						} else {
							uint8_t _6 = _equal_3(c, 54u);
							if (_6) {
								return (struct opt_8) {1, .as1 = (struct some_8) {6u}};
							} else {
								uint8_t _7 = _equal_3(c, 55u);
								if (_7) {
									return (struct opt_8) {1, .as1 = (struct some_8) {7u}};
								} else {
									uint8_t _8 = _equal_3(c, 56u);
									if (_8) {
										return (struct opt_8) {1, .as1 = (struct some_8) {8u}};
									} else {
										uint8_t _9 = _equal_3(c, 57u);
										if (_9) {
											return (struct opt_8) {1, .as1 = (struct some_8) {9u}};
										} else {
											return (struct opt_8) {0, .as0 = (struct none) {}};
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
/* first<char> char(a arr<char>) */
char first_2(struct ctx* ctx, struct arr_0 a) {
	uint8_t _0 = empty__q_0(a);
	forbid_0(ctx, _0);
	return subscript_23(ctx, a, 0u);
}
/* tail<char> arr<char>(a arr<char>) */
struct arr_0 tail_3(struct ctx* ctx, struct arr_0 a) {
	uint8_t _0 = empty__q_0(a);
	forbid_0(ctx, _0);
	struct arrow_0 _1 = _arrow_0(ctx, 1u, a.size);
	return subscript_25(ctx, a, _1);
}
/* main.lambda0 test-options(values arr<opt<arr<arr<char>>>>) */
struct test_options main_0__lambda0(struct ctx* ctx, struct void_ _closure, struct arr_5 values) {
	struct opt_10 print_tests_strs0;
	print_tests_strs0 = subscript_44(ctx, values, 0u);
	
	struct opt_10 overwrite_output_strs1;
	overwrite_output_strs1 = subscript_44(ctx, values, 1u);
	
	struct opt_10 max_failures_strs2;
	max_failures_strs2 = subscript_44(ctx, values, 2u);
	
	uint8_t print_tests__q3;
	print_tests__q3 = has__q_1(print_tests_strs0);
	
	uint8_t overwrite_output__q5;
	struct opt_10 _0 = overwrite_output_strs1;
	switch (_0.kind) {
		case 0: {
			overwrite_output__q5 = 0;
			break;
		}
		case 1: {
			struct some_10 s4 = _0.as1;
			
			uint8_t _1 = empty__q_1(s4.value);
			assert_0(ctx, _1);
			overwrite_output__q5 = 1;
			break;
		}
		default:
			0;
	}
	
	uint64_t max_failures8;
	struct opt_10 _2 = max_failures_strs2;
	switch (_2.kind) {
		case 0: {
			max_failures8 = 100u;
			break;
		}
		case 1: {
			struct some_10 s6 = _2.as1;
			
			struct arr_1 strs7;
			strs7 = s6.value;
			
			uint8_t _3 = _equal_0(strs7.size, 1u);
			assert_0(ctx, _3);
			struct arr_0 _4 = first_0(ctx, strs7);
			struct opt_8 _5 = parse_nat(ctx, _4);
			max_failures8 = force_1(ctx, _5);
			break;
		}
		default:
			0;
	}
	
	return (struct test_options) {print_tests__q3, overwrite_output__q5, max_failures8};
}
/* resolved<nat> fut<nat>(value nat) */
struct fut_0* resolved_1(struct ctx* ctx, uint64_t value) {
	struct fut_0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct fut_0));
	temp0 = (struct fut_0*) _0;
	
	struct lock _1 = lock_by_val();
	*temp0 = (struct fut_0) {_1, (struct fut_state_0) {1, .as1 = (struct fut_state_resolved_0) {value}}};
	return temp0;
}
/* print-help void() */
struct void_ print_help(struct ctx* ctx) {
	print((struct arr_0) {18, constantarr_0_18});
	print((struct arr_0) {8, constantarr_0_19});
	print((struct arr_0) {36, constantarr_0_20});
	return print((struct arr_0) {63, constantarr_0_21});
}
/* do-test nat(options test-options) */
uint64_t do_test(struct ctx* ctx, struct test_options options) {
	struct arr_0 test_path0;
	struct arr_0 _0 = current_executable_path(ctx);
	test_path0 = parent_path(ctx, _0);
	
	struct arr_0 crow_path1;
	crow_path1 = parent_path(ctx, test_path0);
	
	struct arr_0 crow_exe2;
	struct arr_0 _1 = child_path(ctx, crow_path1, (struct arr_0) {3, constantarr_0_25});
	crow_exe2 = child_path(ctx, _1, (struct arr_0) {4, constantarr_0_26});
	
	struct dict_1* env3;
	env3 = get_environ(ctx);
	
	struct result_2 crow_failures4;
	struct arr_0 _2 = child_path(ctx, test_path0, (struct arr_0) {12, constantarr_0_69});
	struct result_2 _3 = run_crow_tests(ctx, _2, crow_exe2, env3, options);
	struct do_test__lambda0* temp0;
	uint8_t* _4 = alloc(ctx, sizeof(struct do_test__lambda0));
	temp0 = (struct do_test__lambda0*) _4;
	
	*temp0 = (struct do_test__lambda0) {test_path0, crow_exe2, env3, options};
	crow_failures4 = first_failures(ctx, _3, (struct fun0) {1, .as1 = temp0});
	
	struct result_2 all_failures5;
	struct do_test__lambda1* temp1;
	uint8_t* _5 = alloc(ctx, sizeof(struct do_test__lambda1));
	temp1 = (struct do_test__lambda1*) _5;
	
	*temp1 = (struct do_test__lambda1) {crow_path1, options};
	all_failures5 = first_failures(ctx, crow_failures4, (struct fun0) {2, .as2 = temp1});
	
	return print_failures(ctx, all_failures5, options);
}
/* parent-path arr<char>(a arr<char>) */
struct arr_0 parent_path(struct ctx* ctx, struct arr_0 a) {
	struct opt_8 _0 = r_index_of(ctx, a, 47u);
	switch (_0.kind) {
		case 0: {
			return (struct arr_0) {0u, NULL};
		}
		case 1: {
			struct some_8 s0 = _0.as1;
			
			struct arrow_0 _1 = _arrow_0(ctx, 0u, s0.value);
			return subscript_25(ctx, a, _1);
		}
		default:
			return (struct arr_0) {0, NULL};
	}
}
/* r-index-of<char> opt<nat>(a arr<char>, value char) */
struct opt_8 r_index_of(struct ctx* ctx, struct arr_0 a, char value) {
	struct r_index_of__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct r_index_of__lambda0));
	temp0 = (struct r_index_of__lambda0*) _0;
	
	*temp0 = (struct r_index_of__lambda0) {value};
	return find_rindex(ctx, a, (struct fun_act1_11) {0, .as0 = temp0});
}
/* find-rindex<?t> opt<nat>(a arr<char>, pred fun-act1<bool, char>) */
struct opt_8 find_rindex(struct ctx* ctx, struct arr_0 a, struct fun_act1_11 pred) {
	uint8_t _0 = empty__q_0(a);
	if (_0) {
		return (struct opt_8) {0, .as0 = (struct none) {}};
	} else {
		uint64_t _1 = decr(ctx, a.size);
		return find_rindex_recur(ctx, a, _1, pred);
	}
}
/* find-rindex-recur<?t> opt<nat>(a arr<char>, index nat, pred fun-act1<bool, char>) */
struct opt_8 find_rindex_recur(struct ctx* ctx, struct arr_0 a, uint64_t index, struct fun_act1_11 pred) {
	top:;
	char _0 = subscript_23(ctx, a, index);
	uint8_t _1 = subscript_45(ctx, pred, _0);
	if (_1) {
		return (struct opt_8) {1, .as1 = (struct some_8) {index}};
	} else {
		uint8_t _2 = _equal_0(index, 0u);
		if (_2) {
			return (struct opt_8) {0, .as0 = (struct none) {}};
		} else {
			uint64_t _3 = decr(ctx, index);
			a = a;
			index = _3;
			pred = pred;
			goto top;
		}
	}
}
/* subscript<bool, ?t> bool(a fun-act1<bool, char>, p0 char) */
uint8_t subscript_45(struct ctx* ctx, struct fun_act1_11 a, char p0) {
	return call_w_ctx_542(a, ctx, p0);
}
/* call-w-ctx<bool, char> (generated) (generated) */
uint8_t call_w_ctx_542(struct fun_act1_11 a, struct ctx* ctx, char p0) {
	struct fun_act1_11 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct r_index_of__lambda0* closure0 = _0.as0;
			
			return r_index_of__lambda0(ctx, closure0, p0);
		}
		default:
			return 0;
	}
}
/* decr nat(a nat) */
uint64_t decr(struct ctx* ctx, uint64_t a) {
	return _minus_2(ctx, a, 1u);
}
/* r-index-of<char>.lambda0 bool(it char) */
uint8_t r_index_of__lambda0(struct ctx* ctx, struct r_index_of__lambda0* _closure, char it) {
	return _equal_3(it, _closure->value);
}
/* current-executable-path arr<char>() */
struct arr_0 current_executable_path(struct ctx* ctx) {
	return read_link(ctx, (struct arr_0) {14, constantarr_0_23});
}
/* read-link arr<char>(path arr<char>) */
struct arr_0 read_link(struct ctx* ctx, struct arr_0 path) {
	struct mut_arr_4 buff0;
	buff0 = uninitialized_mut_arr_3(ctx, 1000u);
	
	int64_t size1;
	char* _0 = to_c_str(ctx, path);
	char* _1 = data_8(buff0);
	uint64_t _2 = size_4(buff0);
	size1 = readlink(_0, _1, _2);
	
	check_errno_if_neg_one(ctx, size1);
	struct arr_0 _3 = cast_immutable_2(buff0);
	uint64_t _4 = to_nat_0(ctx, size1);
	struct arrow_0 _5 = _arrow_0(ctx, 0u, _4);
	return subscript_25(ctx, _3, _5);
}
/* uninitialized-mut-arr<char> mut-arr<char>(size nat) */
struct mut_arr_4 uninitialized_mut_arr_3(struct ctx* ctx, uint64_t size) {
	char* _0 = alloc_uninitialized_0(ctx, size);
	return mut_arr_9(size, _0);
}
/* mut-arr<?t> mut-arr<char>(size nat, data ptr<char>) */
struct mut_arr_4 mut_arr_9(uint64_t size, char* data) {
	return (struct mut_arr_4) {(struct void_) {}, (struct arr_0) {size, data}};
}
/* to-c-str ptr<char>(a arr<char>) */
char* to_c_str(struct ctx* ctx, struct arr_0 a) {
	struct arr_0 _0 = _concat_0(ctx, a, (struct arr_0) {1, constantarr_0_22});
	return _0.data;
}
/* data<char> ptr<char>(a mut-arr<char>) */
char* data_8(struct mut_arr_4 a) {
	return a.inner.data;
}
/* size<char> nat(a mut-arr<char>) */
uint64_t size_4(struct mut_arr_4 a) {
	return a.inner.size;
}
/* check-errno-if-neg-one void(e int) */
struct void_ check_errno_if_neg_one(struct ctx* ctx, int64_t e) {
	uint8_t _0 = _equal_1(e, -1);
	if (_0) {
		int32_t _1 = errno;
		return check_posix_error(ctx, _1);
	} else {
		return (struct void_) {};
	}
}
/* check-posix-error void(e int32) */
struct void_ check_posix_error(struct ctx* ctx, int32_t e) {
	uint8_t _0 = _equal_2(e, 0);
	return assert_0(ctx, _0);
}
/* cast-immutable<char> arr<char>(a mut-arr<char>) */
struct arr_0 cast_immutable_2(struct mut_arr_4 a) {
	return a.inner;
}
/* to-nat nat(i int) */
uint64_t to_nat_0(struct ctx* ctx, int64_t i) {
	uint8_t _0 = negative__q(ctx, i);
	forbid_0(ctx, _0);
	return (uint64_t) i;
}
/* negative? bool(i int) */
uint8_t negative__q(struct ctx* ctx, int64_t i) {
	return _less_2(i, 0);
}
/* <<int> bool(a int, b int) */
uint8_t _less_2(int64_t a, int64_t b) {
	struct comparison _0 = compare_37(a, b);
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
/* child-path arr<char>(a arr<char>, child-name arr<char>) */
struct arr_0 child_path(struct ctx* ctx, struct arr_0 a, struct arr_0 child_name) {
	struct arr_0 _0 = _concat_0(ctx, a, (struct arr_0) {1, constantarr_0_24});
	return _concat_0(ctx, _0, child_name);
}
/* get-environ dict<arr<char>, arr<char>>() */
struct dict_1* get_environ(struct ctx* ctx) {
	struct mut_dict_1* res0;
	res0 = mut_dict_1(ctx);
	
	char** _0 = environ;
	get_environ_recur(ctx, _0, res0);
	return move_to_dict__e_1(ctx, res0);
}
/* mut-dict<arr<char>, arr<char>> mut-dict<arr<char>, arr<char>>() */
struct mut_dict_1* mut_dict_1(struct ctx* ctx) {
	struct mut_dict_1* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_dict_1));
	temp0 = (struct mut_dict_1*) _0;
	
	struct mut_list_1* _1 = mut_list_0(ctx);
	struct mut_list_1* _2 = mut_list_0(ctx);
	*temp0 = (struct mut_dict_1) {(struct void_) {}, _1, _2};
	return temp0;
}
/* get-environ-recur void(env ptr<ptr<char>>, res mut-dict<arr<char>, arr<char>>) */
struct void_ get_environ_recur(struct ctx* ctx, char** env, struct mut_dict_1* res) {
	top:;
	uint8_t _0 = null__q_2(*env);
	uint8_t _1 = not(_0);
	if (_1) {
		struct arrow_2* entry0;
		entry0 = parse_environ_entry(ctx, *env);
		
		set_subscript_11(ctx, res, entry0->from, entry0->to);
		char** _2 = incr_6(env);
		env = _2;
		res = res;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* null?<char> bool(a ptr<char>) */
uint8_t null__q_2(char* a) {
	return _equal_0((uint64_t) a, (uint64_t) NULL);
}
/* parse-environ-entry arrow<arr<char>, arr<char>>(entry ptr<char>) */
struct arrow_2* parse_environ_entry(struct ctx* ctx, char* entry) {
	char* key_end0;
	key_end0 = find_char_in_cstr(entry, 61u);
	
	struct arr_0 key1;
	key1 = arr_from_begin_end(entry, key_end0);
	
	char* value_begin2;
	value_begin2 = incr_4(key_end0);
	
	char* value_end3;
	value_end3 = find_cstr_end(value_begin2);
	
	struct arr_0 value4;
	value4 = arr_from_begin_end(value_begin2, value_end3);
	
	return _arrow_1(ctx, key1, value4);
}
/* -><arr<char>, arr<char>> arrow<arr<char>, arr<char>>(from arr<char>, to arr<char>) */
struct arrow_2* _arrow_1(struct ctx* ctx, struct arr_0 from, struct arr_0 to) {
	struct arrow_2* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct arrow_2));
	temp0 = (struct arrow_2*) _0;
	
	*temp0 = (struct arrow_2) {from, to};
	return temp0;
}
/* set-subscript<arr<char>, arr<char>> void(a mut-dict<arr<char>, arr<char>>, key arr<char>, value arr<char>) */
struct void_ set_subscript_11(struct ctx* ctx, struct mut_dict_1* a, struct arr_0 key, struct arr_0 value) {
	return set_subscript_recur_1(ctx, a, 0u, key, value);
}
/* set-subscript-recur<?k, ?v> void(a mut-dict<arr<char>, arr<char>>, idx nat, key arr<char>, value arr<char>) */
struct void_ set_subscript_recur_1(struct ctx* ctx, struct mut_dict_1* a, uint64_t idx, struct arr_0 key, struct arr_0 value) {
	top:;
	uint8_t _0 = _equal_0(idx, a->keys->size);
	if (_0) {
		_concatEquals_0(ctx, a->keys, key);
		return _concatEquals_0(ctx, a->values, value);
	} else {
		struct arr_0 _1 = subscript_38(ctx, a->keys, idx);
		struct comparison _2 = compare_425(key, _1);
		switch (_2.kind) {
			case 0: {
				insert_at__e_0(ctx, a->keys, idx, key);
				return insert_at__e_0(ctx, a->values, idx, value);
			}
			case 1: {
				return set_subscript_7(ctx, a->values, idx, value);
			}
			case 2: {
				uint64_t _3 = _plus(ctx, idx, 1u);
				a = a;
				idx = _3;
				key = key;
				value = value;
				goto top;
			}
			default:
				return (struct void_) {};
		}
	}
}
/* incr<ptr<char>> ptr<ptr<char>>(p ptr<ptr<char>>) */
char** incr_6(char** p) {
	return (p + 1u);
}
/* move-to-dict!<arr<char>, arr<char>> dict<arr<char>, arr<char>>(m mut-dict<arr<char>, arr<char>>) */
struct dict_1* move_to_dict__e_1(struct ctx* ctx, struct mut_dict_1* m) {
	struct arr_1 _0 = move_to_arr__e_0(m->keys);
	struct arr_1 _1 = move_to_arr__e_0(m->values);
	return dict_2(ctx, _0, _1);
}
/* dict<?k, ?v> dict<arr<char>, arr<char>>(keys arr<arr<char>>, values arr<arr<char>>) */
struct dict_1* dict_2(struct ctx* ctx, struct arr_1 keys, struct arr_1 values) {
	uint8_t _0 = _equal_0(keys.size, values.size);
	assert_0(ctx, _0);
	struct sorted_by_first_1* sorted0;
	sorted0 = sort_by_first_1(ctx, keys, values);
	
	struct dict_1* temp0;
	uint8_t* _1 = alloc(ctx, sizeof(struct dict_1));
	temp0 = (struct dict_1*) _1;
	
	*temp0 = (struct dict_1) {(struct void_) {}, sorted0->a, sorted0->b};
	return temp0;
}
/* sort-by-first<?k, ?v> sorted-by-first<arr<char>, arr<char>>(a arr<arr<char>>, b arr<arr<char>>) */
struct sorted_by_first_1* sort_by_first_1(struct ctx* ctx, struct arr_1 a, struct arr_1 b) {
	struct mut_arr_1 mut_a0;
	mut_a0 = mut_arr_1(ctx, a);
	
	struct mut_arr_1 mut_b1;
	mut_b1 = mut_arr_1(ctx, b);
	
	sort_by_first__e_1(ctx, mut_a0, mut_b1);
	struct sorted_by_first_1* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct sorted_by_first_1));
	temp0 = (struct sorted_by_first_1*) _0;
	
	struct arr_1 _1 = cast_immutable_0(mut_a0);
	struct arr_1 _2 = cast_immutable_0(mut_b1);
	*temp0 = (struct sorted_by_first_1) {_1, _2};
	return temp0;
}
/* sort-by-first!<?a, ?b> void(a mut-arr<arr<char>>, b mut-arr<arr<char>>) */
struct void_ sort_by_first__e_1(struct ctx* ctx, struct mut_arr_1 a, struct mut_arr_1 b) {
	top:;
	uint64_t _0 = size_2(a);
	uint64_t _1 = size_2(b);
	uint8_t _2 = _equal_0(_0, _1);
	assert_0(ctx, _2);
	uint64_t _3 = size_2(a);
	uint8_t _4 = _greater(_3, 1u);
	if (_4) {
		uint64_t _5 = size_2(a);
		uint64_t _6 = _divide(ctx, _5, 2u);
		swap_2(ctx, a, 0u, _6);
		struct arr_0 pivot0;
		pivot0 = subscript_33(ctx, a, 0u);
		
		uint64_t new_pivot_index1;
		uint64_t _7 = size_2(a);
		uint64_t _8 = _minus_2(ctx, _7, 1u);
		uint64_t _9 = partition_by_first__e_1(ctx, a, b, pivot0, 1u, _8);
		new_pivot_index1 = _minus_2(ctx, _9, 1u);
		
		swap_2(ctx, a, 0u, new_pivot_index1);
		swap_2(ctx, b, 0u, new_pivot_index1);
		struct arrow_0 _10 = _arrow_0(ctx, 0u, new_pivot_index1);
		struct mut_arr_1 _11 = subscript_35(ctx, a, _10);
		struct arrow_0 _12 = _arrow_0(ctx, 0u, new_pivot_index1);
		struct mut_arr_1 _13 = subscript_35(ctx, b, _12);
		sort_by_first__e_1(ctx, _11, _13);
		uint64_t _14 = _plus(ctx, new_pivot_index1, 1u);
		uint64_t _15 = size_2(a);
		struct arrow_0 _16 = _arrow_0(ctx, _14, _15);
		struct mut_arr_1 _17 = subscript_35(ctx, a, _16);
		uint64_t _18 = _plus(ctx, new_pivot_index1, 1u);
		uint64_t _19 = size_2(b);
		struct arrow_0 _20 = _arrow_0(ctx, _18, _19);
		struct mut_arr_1 _21 = subscript_35(ctx, b, _20);
		a = _17;
		b = _21;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* partition-by-first!<?a, ?b> nat(a mut-arr<arr<char>>, b mut-arr<arr<char>>, pivot arr<char>, l nat, r nat) */
uint64_t partition_by_first__e_1(struct ctx* ctx, struct mut_arr_1 a, struct mut_arr_1 b, struct arr_0 pivot, uint64_t l, uint64_t r) {
	top:;
	uint64_t _0 = size_2(a);
	uint8_t _1 = _lessOrEqual(l, _0);
	assert_0(ctx, _1);
	uint64_t _2 = size_2(a);
	uint8_t _3 = _less_0(r, _2);
	assert_0(ctx, _3);
	uint8_t _4 = _lessOrEqual(l, r);
	if (_4) {
		struct arr_0 _5 = subscript_33(ctx, a, l);
		uint8_t _6 = _less_1(_5, pivot);
		if (_6) {
			uint64_t _7 = _plus(ctx, l, 1u);
			a = a;
			b = b;
			pivot = pivot;
			l = _7;
			r = r;
			goto top;
		} else {
			swap_2(ctx, a, l, r);
			swap_2(ctx, b, l, r);
			uint64_t _8 = _minus_2(ctx, r, 1u);
			a = a;
			b = b;
			pivot = pivot;
			l = l;
			r = _8;
			goto top;
		}
	} else {
		return l;
	}
}
/* first-failures result<arr<char>, arr<failure>>(a result<arr<char>, arr<failure>>, b fun0<result<arr<char>, arr<failure>>>) */
struct result_2 first_failures(struct ctx* ctx, struct result_2 a, struct fun0 b) {
	struct result_2 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct ok_2 ok_a0 = _0.as0;
			
			struct result_2 _1 = subscript_46(ctx, b);
			switch (_1.kind) {
				case 0: {
					struct ok_2 ok_b1 = _1.as0;
					
					struct arr_0 _2 = _concat_0(ctx, ok_a0.value, (struct arr_0) {1, constantarr_0_1});
					struct arr_0 _3 = _concat_0(ctx, _2, ok_b1.value);
					return (struct result_2) {0, .as0 = (struct ok_2) {_3}};
				}
				case 1: {
					struct err_1 e2 = _1.as1;
					
					return (struct result_2) {1, .as1 = e2};
				}
				default:
					return (struct result_2) {0};
			}
		}
		case 1: {
			struct err_1 e3 = _0.as1;
			
			return (struct result_2) {1, .as1 = e3};
		}
		default:
			return (struct result_2) {0};
	}
}
/* subscript<result<arr<char>, arr<failure>>> result<arr<char>, arr<failure>>(a fun0<result<arr<char>, arr<failure>>>) */
struct result_2 subscript_46(struct ctx* ctx, struct fun0 a) {
	return call_w_ctx_578(a, ctx);
}
/* call-w-ctx<result<arr<char>, arr<failure>>> (generated) (generated) */
struct result_2 call_w_ctx_578(struct fun0 a, struct ctx* ctx) {
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
			return (struct result_2) {0};
	}
}
/* run-crow-tests result<arr<char>, arr<failure>>(path arr<char>, path-to-crow arr<char>, env dict<arr<char>, arr<char>>, options test-options) */
struct result_2 run_crow_tests(struct ctx* ctx, struct arr_0 path, struct arr_0 path_to_crow, struct dict_1* env, struct test_options options) {
	struct arr_1 tests0;
	tests0 = list_tests(ctx, path);
	
	struct arr_8 failures1;
	struct run_crow_tests__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct run_crow_tests__lambda0));
	temp0 = (struct run_crow_tests__lambda0*) _0;
	
	*temp0 = (struct run_crow_tests__lambda0) {path_to_crow, env, options};
	failures1 = flat_map_with_max_size(ctx, tests0, options.max_failures, (struct fun_act1_13) {0, .as0 = temp0});
	
	uint8_t _1 = has__q_2(failures1);
	if (_1) {
		return (struct result_2) {1, .as1 = (struct err_1) {failures1}};
	} else {
		struct arr_0 _2 = to_str_4(ctx, tests0.size);
		struct arr_0 _3 = _concat_0(ctx, (struct arr_0) {4, constantarr_0_67}, _2);
		struct arr_0 _4 = _concat_0(ctx, _3, (struct arr_0) {10, constantarr_0_68});
		struct arr_0 _5 = _concat_0(ctx, _4, path);
		return (struct result_2) {0, .as0 = (struct ok_2) {_5}};
	}
}
/* list-tests arr<arr<char>>(path arr<char>) */
struct arr_1 list_tests(struct ctx* ctx, struct arr_0 path) {
	struct mut_list_1* res0;
	res0 = mut_list_0(ctx);
	
	struct fun_act1_6 filter1;
	filter1 = (struct fun_act1_6) {4, .as4 = (struct void_) {}};
	
	struct list_tests__lambda1* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct list_tests__lambda1));
	temp0 = (struct list_tests__lambda1*) _0;
	
	*temp0 = (struct list_tests__lambda1) {res0};
	each_child_recursive(ctx, path, filter1, (struct fun_act1_12) {1, .as1 = temp0});
	return move_to_arr__e_0(res0);
}
/* list-tests.lambda0 bool(s arr<char>) */
uint8_t list_tests__lambda0(struct ctx* ctx, struct void_ _closure, struct arr_0 s) {
	return 1;
}
/* each-child-recursive void(path arr<char>, filter fun-act1<bool, arr<char>>, f fun-act1<void, arr<char>>) */
struct void_ each_child_recursive(struct ctx* ctx, struct arr_0 path, struct fun_act1_6 filter, struct fun_act1_12 f) {
	uint8_t _0 = is_dir__q_0(ctx, path);
	if (_0) {
		struct arr_1 _1 = read_dir_0(ctx, path);
		struct each_child_recursive__lambda0* temp0;
		uint8_t* _2 = alloc(ctx, sizeof(struct each_child_recursive__lambda0));
		temp0 = (struct each_child_recursive__lambda0*) _2;
		
		*temp0 = (struct each_child_recursive__lambda0) {filter, path, f};
		return each_1(ctx, _1, (struct fun_act1_12) {0, .as0 = temp0});
	} else {
		return subscript_47(ctx, f, path);
	}
}
/* is-dir? bool(path arr<char>) */
uint8_t is_dir__q_0(struct ctx* ctx, struct arr_0 path) {
	char* _0 = to_c_str(ctx, path);
	return is_dir__q_1(ctx, _0);
}
/* is-dir? bool(path ptr<char>) */
uint8_t is_dir__q_1(struct ctx* ctx, char* path) {
	struct opt_12 _0 = get_stat(ctx, path);
	switch (_0.kind) {
		case 0: {
			return todo_7();
		}
		case 1: {
			struct some_12 s0 = _0.as1;
			
			uint32_t _1 = s_ifmt(ctx);
			uint32_t _2 = s_ifdir(ctx);
			return _equal_5((s0.value->st_mode & _1), _2);
		}
		default:
			return 0;
	}
}
/* get-stat opt<stat-t>(path ptr<char>) */
struct opt_12 get_stat(struct ctx* ctx, char* path) {
	struct stat_t* s0;
	s0 = empty_stat(ctx);
	
	int32_t err1;
	err1 = stat(path, s0);
	
	uint8_t _0 = _equal_2(err1, 0);
	if (_0) {
		return (struct opt_12) {1, .as1 = (struct some_12) {s0}};
	} else {
		uint8_t _1 = _equal_2(err1, -1);
		assert_0(ctx, _1);
		int32_t _2 = errno;
		int32_t _3 = enoent();
		uint8_t _4 = _equal_2(_2, _3);
		if (_4) {
			return (struct opt_12) {0, .as0 = (struct none) {}};
		} else {
			return todo_6();
		}
	}
}
/* empty-stat stat-t() */
struct stat_t* empty_stat(struct ctx* ctx) {
	struct stat_t* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct stat_t));
	temp0 = (struct stat_t*) _0;
	
	*temp0 = (struct stat_t) {0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u};
	return temp0;
}
/* enoent int32() */
int32_t enoent(void) {
	return 2;
}
/* todo<opt<stat-t>> opt<stat-t>() */
struct opt_12 todo_6(void) {
	(abort(), (struct void_) {});
	return (struct opt_12) {0};
}
/* todo<bool> bool() */
uint8_t todo_7(void) {
	(abort(), (struct void_) {});
	return 0;
}
/* ==<nat32> bool(a nat32, b nat32) */
uint8_t _equal_5(uint32_t a, uint32_t b) {
	struct comparison _0 = compare_592(a, b);
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
/* compare<nat-32> (generated) (generated) */
struct comparison compare_592(uint32_t a, uint32_t b) {
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
/* s-ifmt nat32() */
uint32_t s_ifmt(struct ctx* ctx) {
	return 61440u;
}
/* s-ifdir nat32() */
uint32_t s_ifdir(struct ctx* ctx) {
	return 16384u;
}
/* each<arr<char>> void(a arr<arr<char>>, f fun-act1<void, arr<char>>) */
struct void_ each_1(struct ctx* ctx, struct arr_1 a, struct fun_act1_12 f) {
	top:;
	uint8_t _0 = empty__q_1(a);
	uint8_t _1 = not(_0);
	if (_1) {
		struct arr_0 _2 = first_0(ctx, a);
		subscript_47(ctx, f, _2);
		struct arr_1 _3 = tail_0(ctx, a);
		a = _3;
		f = f;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* subscript<void, ?t> void(a fun-act1<void, arr<char>>, p0 arr<char>) */
struct void_ subscript_47(struct ctx* ctx, struct fun_act1_12 a, struct arr_0 p0) {
	return call_w_ctx_597(a, ctx, p0);
}
/* call-w-ctx<void, arr<char>> (generated) (generated) */
struct void_ call_w_ctx_597(struct fun_act1_12 a, struct ctx* ctx, struct arr_0 p0) {
	struct fun_act1_12 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct each_child_recursive__lambda0* closure0 = _0.as0;
			
			return each_child_recursive__lambda0(ctx, closure0, p0);
		}
		case 1: {
			struct list_tests__lambda1* closure1 = _0.as1;
			
			return list_tests__lambda1(ctx, closure1, p0);
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
			return (struct void_) {};
	}
}
/* read-dir arr<arr<char>>(path arr<char>) */
struct arr_1 read_dir_0(struct ctx* ctx, struct arr_0 path) {
	char* _0 = to_c_str(ctx, path);
	return read_dir_1(ctx, _0);
}
/* read-dir arr<arr<char>>(path ptr<char>) */
struct arr_1 read_dir_1(struct ctx* ctx, char* path) {
	struct dir* dirp0;
	dirp0 = opendir(path);
	
	uint8_t _0 = null__q_3((uint8_t**) dirp0);
	forbid_0(ctx, _0);
	struct mut_list_1* res1;
	res1 = mut_list_0(ctx);
	
	read_dir_recur(ctx, dirp0, res1);
	struct arr_1 _1 = move_to_arr__e_0(res1);
	return sort(ctx, _1);
}
/* null?<ptr<nat8>> bool(a ptr<ptr<nat8>>) */
uint8_t null__q_3(uint8_t** a) {
	return _equal_0((uint64_t) a, (uint64_t) NULL);
}
/* read-dir-recur void(dirp dir, res mut-list<arr<char>>) */
struct void_ read_dir_recur(struct ctx* ctx, struct dir* dirp, struct mut_list_1* res) {
	top:;
	struct dirent* entry0;
	struct dirent* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct dirent));
	temp0 = (struct dirent*) _0;
	
	struct bytes256 _1 = zero_4();
	*temp0 = (struct dirent) {0u, 0, 0u, 0u, _1};
	entry0 = temp0;
	
	struct cell_4* result1;
	struct cell_4* temp1;
	uint8_t* _2 = alloc(ctx, sizeof(struct cell_4));
	temp1 = (struct cell_4*) _2;
	
	*temp1 = (struct cell_4) {entry0};
	result1 = temp1;
	
	int32_t err2;
	err2 = readdir_r(dirp, entry0, result1);
	
	uint8_t _3 = _equal_2(err2, 0);
	assert_0(ctx, _3);
	uint8_t _4 = null__q_0((uint8_t*) result1->subscript);
	uint8_t _5 = not(_4);
	if (_5) {
		uint8_t _6 = ref_eq__q(result1->subscript, entry0);
		assert_0(ctx, _6);
		struct arr_0 name3;
		name3 = get_dirent_name(entry0);
		
		uint8_t _7 = _notEqual_4(name3, (struct arr_0) {1, constantarr_0_27});uint8_t _8;
		
		if (_7) {
			_8 = _notEqual_4(name3, (struct arr_0) {2, constantarr_0_28});
		} else {
			_8 = 0;
		}
		if (_8) {
			struct arr_0 _9 = get_dirent_name(entry0);
			_concatEquals_0(ctx, res, _9);
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
/* ref-eq?<dirent> bool(a dirent, b dirent) */
uint8_t ref_eq__q(struct dirent* a, struct dirent* b) {
	return ((uint8_t*) a == (uint8_t*) b);
}
/* get-dirent-name arr<char>(d dirent) */
struct arr_0 get_dirent_name(struct dirent* d) {
	uint64_t name_offset0;
	name_offset0 = (((sizeof(uint64_t) + sizeof(int64_t)) + sizeof(uint16_t)) + sizeof(char));
	
	uint8_t* name_ptr1;
	name_ptr1 = ((uint8_t*) d + name_offset0);
	
	return to_str_1((char*) name_ptr1);
}
/* !=<arr<char>> bool(a arr<char>, b arr<char>) */
uint8_t _notEqual_4(struct arr_0 a, struct arr_0 b) {
	uint8_t _0 = _equal_4(a, b);
	return not(_0);
}
/* sort<arr<char>> arr<arr<char>>(a arr<arr<char>>) */
struct arr_1 sort(struct ctx* ctx, struct arr_1 a) {
	struct mut_arr_1 res0;
	res0 = mut_arr_1(ctx, a);
	
	sort__e(ctx, res0);
	return cast_immutable_0(res0);
}
/* sort!<?t> void(a mut-arr<arr<char>>) */
struct void_ sort__e(struct ctx* ctx, struct mut_arr_1 a) {
	top:;
	uint64_t _0 = size_2(a);
	uint8_t _1 = _greater(_0, 1u);
	if (_1) {
		uint64_t _2 = size_2(a);
		uint64_t _3 = _divide(ctx, _2, 2u);
		swap_2(ctx, a, 0u, _3);
		struct arr_0 pivot0;
		pivot0 = subscript_33(ctx, a, 0u);
		
		uint64_t new_pivot_index1;
		uint64_t _4 = size_2(a);
		uint64_t _5 = _minus_2(ctx, _4, 1u);
		uint64_t _6 = partition__e(ctx, a, pivot0, 1u, _5);
		new_pivot_index1 = _minus_2(ctx, _6, 1u);
		
		swap_2(ctx, a, 0u, new_pivot_index1);
		struct arrow_0 _7 = _arrow_0(ctx, 0u, new_pivot_index1);
		struct mut_arr_1 _8 = subscript_35(ctx, a, _7);
		sort__e(ctx, _8);
		uint64_t _9 = _plus(ctx, new_pivot_index1, 1u);
		uint64_t _10 = size_2(a);
		struct arrow_0 _11 = _arrow_0(ctx, _9, _10);
		struct mut_arr_1 _12 = subscript_35(ctx, a, _11);
		a = _12;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* partition!<?t> nat(a mut-arr<arr<char>>, pivot arr<char>, l nat, r nat) */
uint64_t partition__e(struct ctx* ctx, struct mut_arr_1 a, struct arr_0 pivot, uint64_t l, uint64_t r) {
	top:;
	uint64_t _0 = size_2(a);
	uint8_t _1 = _lessOrEqual(l, _0);
	assert_0(ctx, _1);
	uint64_t _2 = size_2(a);
	uint8_t _3 = _less_0(r, _2);
	assert_0(ctx, _3);
	uint8_t _4 = _lessOrEqual(l, r);
	if (_4) {
		struct arr_0 _5 = subscript_33(ctx, a, l);
		uint8_t _6 = _less_1(_5, pivot);
		if (_6) {
			uint64_t _7 = _plus(ctx, l, 1u);
			a = a;
			pivot = pivot;
			l = _7;
			r = r;
			goto top;
		} else {
			swap_2(ctx, a, l, r);
			uint64_t _8 = _minus_2(ctx, r, 1u);
			a = a;
			pivot = pivot;
			l = l;
			r = _8;
			goto top;
		}
	} else {
		return l;
	}
}
/* each-child-recursive.lambda0 void(child-name arr<char>) */
struct void_ each_child_recursive__lambda0(struct ctx* ctx, struct each_child_recursive__lambda0* _closure, struct arr_0 child_name) {
	uint8_t _0 = subscript_22(ctx, _closure->filter, child_name);
	if (_0) {
		struct arr_0 _1 = child_path(ctx, _closure->path, child_name);
		return each_child_recursive(ctx, _1, _closure->filter, _closure->f);
	} else {
		return (struct void_) {};
	}
}
/* get-extension opt<arr<char>>(name arr<char>) */
struct opt_11 get_extension(struct ctx* ctx, struct arr_0 name) {
	struct opt_8 _0 = last_index_of(ctx, name, 46u);
	switch (_0.kind) {
		case 0: {
			return (struct opt_11) {0, .as0 = (struct none) {}};
		}
		case 1: {
			struct some_8 s0 = _0.as1;
			
			uint64_t _1 = _plus(ctx, s0.value, 1u);
			struct arrow_0 _2 = _arrow_0(ctx, _1, name.size);
			struct arr_0 _3 = subscript_25(ctx, name, _2);
			return (struct opt_11) {1, .as1 = (struct some_11) {_3}};
		}
		default:
			return (struct opt_11) {0};
	}
}
/* last-index-of opt<nat>(s arr<char>, c char) */
struct opt_8 last_index_of(struct ctx* ctx, struct arr_0 s, char c) {
	top:;
	uint8_t _0 = empty__q_0(s);
	if (_0) {
		return (struct opt_8) {0, .as0 = (struct none) {}};
	} else {
		char _1 = last(ctx, s);
		uint8_t _2 = _equal_3(_1, c);
		if (_2) {
			uint64_t _3 = _minus_2(ctx, s.size, 1u);
			return (struct opt_8) {1, .as1 = (struct some_8) {_3}};
		} else {
			struct arr_0 _4 = rtail(ctx, s);
			s = _4;
			c = c;
			goto top;
		}
	}
}
/* last<char> char(a arr<char>) */
char last(struct ctx* ctx, struct arr_0 a) {
	uint8_t _0 = empty__q_0(a);
	forbid_0(ctx, _0);
	uint64_t _1 = decr(ctx, a.size);
	return subscript_23(ctx, a, _1);
}
/* rtail<char> arr<char>(a arr<char>) */
struct arr_0 rtail(struct ctx* ctx, struct arr_0 a) {
	uint8_t _0 = empty__q_0(a);
	forbid_0(ctx, _0);
	uint64_t _1 = _minus_2(ctx, a.size, 1u);
	struct arrow_0 _2 = _arrow_0(ctx, 0u, _1);
	return subscript_25(ctx, a, _2);
}
/* base-name arr<char>(path arr<char>) */
struct arr_0 base_name(struct ctx* ctx, struct arr_0 path) {
	struct opt_8 i0;
	i0 = last_index_of(ctx, path, 47u);
	
	struct opt_8 _0 = i0;
	switch (_0.kind) {
		case 0: {
			return path;
		}
		case 1: {
			struct some_8 s1 = _0.as1;
			
			uint64_t _1 = _plus(ctx, s1.value, 1u);
			struct arrow_0 _2 = _arrow_0(ctx, _1, path.size);
			return subscript_25(ctx, path, _2);
		}
		default:
			return (struct arr_0) {0, NULL};
	}
}
/* list-tests.lambda1 void(child arr<char>) */
struct void_ list_tests__lambda1(struct ctx* ctx, struct list_tests__lambda1* _closure, struct arr_0 child) {
	struct arr_0 _0 = base_name(ctx, child);
	struct opt_11 _1 = get_extension(ctx, _0);
	switch (_1.kind) {
		case 0: {
			return (struct void_) {};
		}
		case 1: {
			struct some_11 s0 = _1.as1;
			
			uint8_t _2 = _equal_4(s0.value, (struct arr_0) {4, constantarr_0_26});
			if (_2) {
				return _concatEquals_0(ctx, _closure->res, child);
			} else {
				return (struct void_) {};
			}
		}
		default:
			return (struct void_) {};
	}
}
/* flat-map-with-max-size<failure, arr<char>> arr<failure>(a arr<arr<char>>, max-size nat, mapper fun-act1<arr<failure>, arr<char>>) */
struct arr_8 flat_map_with_max_size(struct ctx* ctx, struct arr_1 a, uint64_t max_size, struct fun_act1_13 mapper) {
	struct mut_list_4* res0;
	res0 = mut_list_2(ctx);
	
	struct flat_map_with_max_size__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct flat_map_with_max_size__lambda0));
	temp0 = (struct flat_map_with_max_size__lambda0*) _0;
	
	*temp0 = (struct flat_map_with_max_size__lambda0) {res0, max_size, mapper};
	each_1(ctx, a, (struct fun_act1_12) {2, .as2 = temp0});
	return move_to_arr__e_3(res0);
}
/* mut-list<?out> mut-list<failure>() */
struct mut_list_4* mut_list_2(struct ctx* ctx) {
	struct mut_list_4* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_list_4));
	temp0 = (struct mut_list_4*) _0;
	
	struct mut_arr_5 _1 = mut_arr_10();
	*temp0 = (struct mut_list_4) {_1, 0u};
	return temp0;
}
/* mut-arr<?t> mut-arr<failure>() */
struct mut_arr_5 mut_arr_10(void) {
	return (struct mut_arr_5) {(struct void_) {}, (struct arr_8) {0u, NULL}};
}
/* ~=<?out> void(a mut-list<failure>, values arr<failure>) */
struct void_ _concatEquals_2(struct ctx* ctx, struct mut_list_4* a, struct arr_8 values) {
	struct _concatEquals_2__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct _concatEquals_2__lambda0));
	temp0 = (struct _concatEquals_2__lambda0*) _0;
	
	*temp0 = (struct _concatEquals_2__lambda0) {a};
	return each_2(ctx, values, (struct fun_act1_14) {0, .as0 = temp0});
}
/* each<?t> void(a arr<failure>, f fun-act1<void, failure>) */
struct void_ each_2(struct ctx* ctx, struct arr_8 a, struct fun_act1_14 f) {
	top:;
	uint8_t _0 = empty__q_9(a);
	uint8_t _1 = not(_0);
	if (_1) {
		struct failure* _2 = first_3(ctx, a);
		subscript_48(ctx, f, _2);
		struct arr_8 _3 = tail_4(ctx, a);
		a = _3;
		f = f;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* empty?<?t> bool(a arr<failure>) */
uint8_t empty__q_9(struct arr_8 a) {
	return _equal_0(a.size, 0u);
}
/* subscript<void, ?t> void(a fun-act1<void, failure>, p0 failure) */
struct void_ subscript_48(struct ctx* ctx, struct fun_act1_14 a, struct failure* p0) {
	return call_w_ctx_625(a, ctx, p0);
}
/* call-w-ctx<void, gc-ptr(failure)> (generated) (generated) */
struct void_ call_w_ctx_625(struct fun_act1_14 a, struct ctx* ctx, struct failure* p0) {
	struct fun_act1_14 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct _concatEquals_2__lambda0* closure0 = _0.as0;
			
			return _concatEquals_2__lambda0(ctx, closure0, p0);
		}
		case 1: {
			struct void_ closure1 = _0.as1;
			
			return print_failures__lambda0(ctx, closure1, p0);
		}
		default:
			return (struct void_) {};
	}
}
/* first<?t> failure(a arr<failure>) */
struct failure* first_3(struct ctx* ctx, struct arr_8 a) {
	uint8_t _0 = empty__q_9(a);
	forbid_0(ctx, _0);
	return subscript_49(ctx, a, 0u);
}
/* subscript<?t> failure(a arr<failure>, index nat) */
struct failure* subscript_49(struct ctx* ctx, struct arr_8 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	return noctx_at_11(a, index);
}
/* noctx-at<?t> failure(a arr<failure>, index nat) */
struct failure* noctx_at_11(struct arr_8 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	hard_assert(_0);
	return subscript_50(a.data, index);
}
/* subscript<?t> failure(a ptr<failure>, n nat) */
struct failure* subscript_50(struct failure** a, uint64_t n) {
	return *(a + n);
}
/* tail<?t> arr<failure>(a arr<failure>) */
struct arr_8 tail_4(struct ctx* ctx, struct arr_8 a) {
	uint8_t _0 = empty__q_9(a);
	forbid_0(ctx, _0);
	struct arrow_0 _1 = _arrow_0(ctx, 1u, a.size);
	return subscript_51(ctx, a, _1);
}
/* subscript<?t> arr<failure>(a arr<failure>, range arrow<nat, nat>) */
struct arr_8 subscript_51(struct ctx* ctx, struct arr_8 a, struct arrow_0 range) {
	uint8_t _0 = _lessOrEqual(range.from, range.to);
	assert_0(ctx, _0);
	uint8_t _1 = _lessOrEqual(range.to, a.size);
	assert_0(ctx, _1);
	uint64_t _2 = _minus_2(ctx, range.to, range.from);
	return (struct arr_8) {_2, (a.data + range.from)};
}
/* ~=<?t> void(a mut-list<failure>, value failure) */
struct void_ _concatEquals_3(struct ctx* ctx, struct mut_list_4* a, struct failure* value) {
	incr_capacity__e_2(ctx, a);
	uint64_t _0 = capacity_3(a);
	uint8_t _1 = _less_0(a->size, _0);
	assert_0(ctx, _1);
	struct failure** _2 = data_9(a);
	set_subscript_12(_2, a->size, value);
	uint64_t _3 = incr_5(ctx, a->size);
	return (a->size = _3, (struct void_) {});
}
/* incr-capacity!<?t> void(a mut-list<failure>) */
struct void_ incr_capacity__e_2(struct ctx* ctx, struct mut_list_4* a) {
	uint64_t _0 = incr_5(ctx, a->size);
	uint64_t _1 = round_up_to_power_of_two(ctx, _0);
	return ensure_capacity_2(ctx, a, _1);
}
/* ensure-capacity<?t> void(a mut-list<failure>, min-capacity nat) */
struct void_ ensure_capacity_2(struct ctx* ctx, struct mut_list_4* a, uint64_t min_capacity) {
	uint64_t _0 = capacity_3(a);
	uint8_t _1 = _less_0(_0, min_capacity);
	if (_1) {
		return increase_capacity_to__e_2(ctx, a, min_capacity);
	} else {
		return (struct void_) {};
	}
}
/* capacity<?t> nat(a mut-list<failure>) */
uint64_t capacity_3(struct mut_list_4* a) {
	return size_5(a->backing);
}
/* size<?t> nat(a mut-arr<failure>) */
uint64_t size_5(struct mut_arr_5 a) {
	return a.inner.size;
}
/* increase-capacity-to!<?t> void(a mut-list<failure>, new-capacity nat) */
struct void_ increase_capacity_to__e_2(struct ctx* ctx, struct mut_list_4* a, uint64_t new_capacity) {
	uint64_t _0 = capacity_3(a);
	uint8_t _1 = _greater(new_capacity, _0);
	assert_0(ctx, _1);
	struct failure** old_data0;
	old_data0 = data_9(a);
	
	struct failure** _2 = alloc_uninitialized_4(ctx, new_capacity);
	struct mut_arr_5 _3 = mut_arr_11(new_capacity, _2);
	a->backing = _3;
	struct failure** _4 = data_9(a);
	copy_data_from_3(ctx, _4, old_data0, a->size);
	uint64_t _5 = _plus(ctx, a->size, 1u);
	uint64_t _6 = size_5(a->backing);
	struct arrow_0 _7 = _arrow_0(ctx, _5, _6);
	struct mut_arr_5 _8 = subscript_52(ctx, a->backing, _7);
	return set_zero_elements_2(_8);
}
/* data<?t> ptr<failure>(a mut-list<failure>) */
struct failure** data_9(struct mut_list_4* a) {
	return data_10(a->backing);
}
/* data<?t> ptr<failure>(a mut-arr<failure>) */
struct failure** data_10(struct mut_arr_5 a) {
	return a.inner.data;
}
/* mut-arr<?t> mut-arr<failure>(size nat, data ptr<failure>) */
struct mut_arr_5 mut_arr_11(uint64_t size, struct failure** data) {
	return (struct mut_arr_5) {(struct void_) {}, (struct arr_8) {size, data}};
}
/* alloc-uninitialized<?t> ptr<failure>(size nat) */
struct failure** alloc_uninitialized_4(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(struct failure*)));
	return (struct failure**) _0;
}
/* copy-data-from<?t> void(to ptr<failure>, from ptr<failure>, len nat) */
struct void_ copy_data_from_3(struct ctx* ctx, struct failure** to, struct failure** from, uint64_t len) {
	return (memcpy((uint8_t*) to, (uint8_t*) from, (len * sizeof(struct failure*))), (struct void_) {});
}
/* set-zero-elements<?t> void(a mut-arr<failure>) */
struct void_ set_zero_elements_2(struct mut_arr_5 a) {
	struct failure** _0 = data_10(a);
	uint64_t _1 = size_5(a);
	return set_zero_range_3(_0, _1);
}
/* set-zero-range<?t> void(begin ptr<failure>, size nat) */
struct void_ set_zero_range_3(struct failure** begin, uint64_t size) {
	return (memset((uint8_t*) begin, 0u, (size * sizeof(struct failure*))), (struct void_) {});
}
/* subscript<?t> mut-arr<failure>(a mut-arr<failure>, range arrow<nat, nat>) */
struct mut_arr_5 subscript_52(struct ctx* ctx, struct mut_arr_5 a, struct arrow_0 range) {
	struct arr_8 _0 = subscript_51(ctx, a.inner, range);
	return (struct mut_arr_5) {(struct void_) {}, _0};
}
/* set-subscript<?t> void(a ptr<failure>, n nat, value failure) */
struct void_ set_subscript_12(struct failure** a, uint64_t n, struct failure* value) {
	return (*(a + n) = value, (struct void_) {});
}
/* ~=<?out>.lambda0 void(it failure) */
struct void_ _concatEquals_2__lambda0(struct ctx* ctx, struct _concatEquals_2__lambda0* _closure, struct failure* it) {
	return _concatEquals_3(ctx, _closure->a, it);
}
/* subscript<arr<?out>, ?in> arr<failure>(a fun-act1<arr<failure>, arr<char>>, p0 arr<char>) */
struct arr_8 subscript_53(struct ctx* ctx, struct fun_act1_13 a, struct arr_0 p0) {
	return call_w_ctx_649(a, ctx, p0);
}
/* call-w-ctx<arr<failure>, arr<char>> (generated) (generated) */
struct arr_8 call_w_ctx_649(struct fun_act1_13 a, struct ctx* ctx, struct arr_0 p0) {
	struct fun_act1_13 _0 = a;
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
			return (struct arr_8) {0, NULL};
	}
}
/* reduce-size-if-more-than!<?out> void(a mut-list<failure>, new-size nat) */
struct void_ reduce_size_if_more_than__e(struct ctx* ctx, struct mut_list_4* a, uint64_t new_size) {
	top:;
	uint8_t _0 = _less_0(new_size, a->size);
	if (_0) {
		struct opt_13 _1 = pop__e(ctx, a);
		drop_2(_1);
		a = a;
		new_size = new_size;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* drop<opt<?t>> void(_ opt<failure>) */
struct void_ drop_2(struct opt_13 _p0) {
	return (struct void_) {};
}
/* pop!<?t> opt<failure>(a mut-list<failure>) */
struct opt_13 pop__e(struct ctx* ctx, struct mut_list_4* a) {
	uint8_t _0 = empty__q_10(a);
	if (_0) {
		return (struct opt_13) {0, .as0 = (struct none) {}};
	} else {
		uint64_t new_size0;
		new_size0 = noctx_decr(a->size);
		
		struct failure* res1;
		res1 = subscript_54(ctx, a, new_size0);
		
		set_subscript_13(ctx, a, new_size0, NULL);
		a->size = new_size0;
		return (struct opt_13) {1, .as1 = (struct some_13) {res1}};
	}
}
/* empty?<?t> bool(a mut-list<failure>) */
uint8_t empty__q_10(struct mut_list_4* a) {
	return _equal_0(a->size, 0u);
}
/* subscript<?t> failure(a mut-list<failure>, index nat) */
struct failure* subscript_54(struct ctx* ctx, struct mut_list_4* a, uint64_t index) {
	uint8_t _0 = _less_0(index, a->size);
	assert_0(ctx, _0);
	return noctx_at_12(a, index);
}
/* noctx-at<?t> failure(a mut-list<failure>, index nat) */
struct failure* noctx_at_12(struct mut_list_4* a, uint64_t index) {
	uint8_t _0 = _less_0(index, a->size);
	hard_assert(_0);
	struct failure** _1 = data_9(a);
	return subscript_50(_1, index);
}
/* set-subscript<?t> void(a mut-list<failure>, index nat, value failure) */
struct void_ set_subscript_13(struct ctx* ctx, struct mut_list_4* a, uint64_t index, struct failure* value) {
	uint8_t _0 = _less_0(index, a->size);
	assert_0(ctx, _0);
	return noctx_set_at__e_4(a, index, value);
}
/* noctx-set-at!<?t> void(a mut-list<failure>, index nat, value failure) */
struct void_ noctx_set_at__e_4(struct mut_list_4* a, uint64_t index, struct failure* value) {
	uint8_t _0 = _less_0(index, a->size);
	hard_assert(_0);
	struct failure** _1 = data_9(a);
	return set_subscript_12(_1, index, value);
}
/* flat-map-with-max-size<failure, arr<char>>.lambda0 void(x arr<char>) */
struct void_ flat_map_with_max_size__lambda0(struct ctx* ctx, struct flat_map_with_max_size__lambda0* _closure, struct arr_0 x) {
	uint8_t _0 = _less_0(_closure->res->size, _closure->max_size);
	if (_0) {
		struct arr_8 _1 = subscript_53(ctx, _closure->mapper, x);
		_concatEquals_2(ctx, _closure->res, _1);
		return reduce_size_if_more_than__e(ctx, _closure->res, _closure->max_size);
	} else {
		return (struct void_) {};
	}
}
/* move-to-arr!<?out> arr<failure>(a mut-list<failure>) */
struct arr_8 move_to_arr__e_3(struct mut_list_4* a) {
	struct arr_8 res0;
	struct failure** _0 = data_9(a);
	res0 = (struct arr_8) {a->size, _0};
	
	struct mut_arr_5 _1 = mut_arr_10();
	a->backing = _1;
	a->size = 0u;
	return res0;
}
/* run-single-crow-test arr<failure>(path-to-crow arr<char>, env dict<arr<char>, arr<char>>, path arr<char>, options test-options) */
struct arr_8 run_single_crow_test(struct ctx* ctx, struct arr_0 path_to_crow, struct dict_1* env, struct arr_0 path, struct test_options options) {
	struct opt_14 op0;
	struct run_single_crow_test__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct run_single_crow_test__lambda0));
	temp0 = (struct run_single_crow_test__lambda0*) _0;
	
	*temp0 = (struct run_single_crow_test__lambda0) {options, path, path_to_crow, env};
	op0 = first_some(ctx, (struct arr_1) {4, constantarr_1_1}, (struct fun_act1_15) {0, .as0 = temp0});
	
	struct opt_14 _1 = op0;
	switch (_1.kind) {
		case 0: {
			uint8_t _2 = options.print_tests__q;
			if (_2) {
				struct arr_0 _3 = _concat_0(ctx, (struct arr_0) {9, constantarr_0_62}, path);
				print(_3);
			} else {
				(struct void_) {};
			}
			struct arr_8 interpret_failures1;
			interpret_failures1 = run_single_runnable_test(ctx, path_to_crow, env, path, 1, options.overwrite_output__q);
			
			uint8_t _4 = empty__q_9(interpret_failures1);
			if (_4) {
				return run_single_runnable_test(ctx, path_to_crow, env, path, 0, options.overwrite_output__q);
			} else {
				return interpret_failures1;
			}
		}
		case 1: {
			struct some_14 s2 = _1.as1;
			
			return s2.value;
		}
		default:
			return (struct arr_8) {0, NULL};
	}
}
/* first-some<arr<failure>, arr<char>> opt<arr<failure>>(a arr<arr<char>>, cb fun-act1<opt<arr<failure>>, arr<char>>) */
struct opt_14 first_some(struct ctx* ctx, struct arr_1 a, struct fun_act1_15 cb) {
	top:;
	uint8_t _0 = empty__q_1(a);
	if (_0) {
		return (struct opt_14) {0, .as0 = (struct none) {}};
	} else {
		struct arr_0 _1 = first_0(ctx, a);
		struct opt_14 _2 = subscript_55(ctx, cb, _1);
		switch (_2.kind) {
			case 0: {
				struct arr_1 _3 = tail_0(ctx, a);
				a = _3;
				cb = cb;
				goto top;
			}
			case 1: {
				struct some_14 s0 = _2.as1;
				
				return (struct opt_14) {1, .as1 = s0};
			}
			default:
				return (struct opt_14) {0};
		}
	}
}
/* subscript<opt<?out>, ?in> opt<arr<failure>>(a fun-act1<opt<arr<failure>>, arr<char>>, p0 arr<char>) */
struct opt_14 subscript_55(struct ctx* ctx, struct fun_act1_15 a, struct arr_0 p0) {
	return call_w_ctx_663(a, ctx, p0);
}
/* call-w-ctx<opt<arr<failure>>, arr<char>> (generated) (generated) */
struct opt_14 call_w_ctx_663(struct fun_act1_15 a, struct ctx* ctx, struct arr_0 p0) {
	struct fun_act1_15 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct run_single_crow_test__lambda0* closure0 = _0.as0;
			
			return run_single_crow_test__lambda0(ctx, closure0, p0);
		}
		default:
			return (struct opt_14) {0};
	}
}
/* run-print-test print-test-result(print-kind arr<char>, path-to-crow arr<char>, env dict<arr<char>, arr<char>>, path arr<char>, overwrite-output? bool) */
struct print_test_result* run_print_test(struct ctx* ctx, struct arr_0 print_kind, struct arr_0 path_to_crow, struct dict_1* env, struct arr_0 path, uint8_t overwrite_output__q) {
	struct process_result* res0;
	struct arr_0* temp0;
	uint8_t* _0 = alloc(ctx, (sizeof(struct arr_0) * 3u));
	temp0 = (struct arr_0*) _0;
	
	*(temp0 + 0u) = (struct arr_0) {5, constantarr_0_51};
	*(temp0 + 1u) = print_kind;
	*(temp0 + 2u) = path;
	res0 = spawn_and_wait_result_0(ctx, path_to_crow, (struct arr_1) {3u, temp0}, env);
	
	struct arr_0 output_path1;
	struct arr_0 _1 = _concat_0(ctx, path, (struct arr_0) {1, constantarr_0_27});
	struct arr_0 _2 = _concat_0(ctx, _1, print_kind);
	output_path1 = _concat_0(ctx, _2, (struct arr_0) {5, constantarr_0_52});
	
	struct arr_8 output_failures2;
	uint8_t _3 = empty__q_0(res0->stdout);uint8_t _4;
	
	if (_3) {
		_4 = _notEqual_2(res0->exit_code, 0);
	} else {
		_4 = 0;
	}
	if (_4) {
		output_failures2 = (struct arr_8) {0u, NULL};
	} else {
		output_failures2 = handle_output(ctx, path, output_path1, res0->stdout, overwrite_output__q);
	}
	
	uint8_t _5 = empty__q_9(output_failures2);
	uint8_t _6 = not(_5);
	if (_6) {
		struct print_test_result* temp1;
		uint8_t* _7 = alloc(ctx, sizeof(struct print_test_result));
		temp1 = (struct print_test_result*) _7;
		
		*temp1 = (struct print_test_result) {1, output_failures2};
		return temp1;
	} else {
		uint8_t _8 = _equal_2(res0->exit_code, 0);
		if (_8) {
			uint8_t _9 = _equal_4(res0->stderr, (struct arr_0) {0u, NULL});
			assert_0(ctx, _9);
			struct print_test_result* temp2;
			uint8_t* _10 = alloc(ctx, sizeof(struct print_test_result));
			temp2 = (struct print_test_result*) _10;
			
			*temp2 = (struct print_test_result) {0, (struct arr_8) {0u, NULL}};
			return temp2;
		} else {
			uint8_t _11 = _equal_2(res0->exit_code, 1);
			if (_11) {
				struct arr_0 stderr_no_color3;
				stderr_no_color3 = remove_colors(ctx, res0->stderr);
				
				struct print_test_result* temp3;
				uint8_t* _12 = alloc(ctx, sizeof(struct print_test_result));
				temp3 = (struct print_test_result*) _12;
				
				struct arr_0 _13 = _concat_0(ctx, output_path1, (struct arr_0) {4, constantarr_0_60});
				struct arr_8 _14 = handle_output(ctx, path, _13, stderr_no_color3, overwrite_output__q);
				*temp3 = (struct print_test_result) {1, _14};
				return temp3;
			} else {
				struct arr_0 message4;
				struct arr_0 _15 = to_str_2(ctx, res0->exit_code);
				message4 = _concat_0(ctx, (struct arr_0) {22, constantarr_0_61}, _15);
				
				struct print_test_result* temp6;
				uint8_t* _16 = alloc(ctx, sizeof(struct print_test_result));
				temp6 = (struct print_test_result*) _16;
				
				struct failure** temp4;
				uint8_t* _17 = alloc(ctx, (sizeof(struct failure*) * 1u));
				temp4 = (struct failure**) _17;
				
				struct failure* temp5;
				uint8_t* _18 = alloc(ctx, sizeof(struct failure));
				temp5 = (struct failure*) _18;
				
				*temp5 = (struct failure) {path, message4};
				*(temp4 + 0u) = temp5;
				*temp6 = (struct print_test_result) {1, (struct arr_8) {1u, temp4}};
				return temp6;
			}
		}
	}
}
/* spawn-and-wait-result process-result(exe arr<char>, args arr<arr<char>>, environ dict<arr<char>, arr<char>>) */
struct process_result* spawn_and_wait_result_0(struct ctx* ctx, struct arr_0 exe, struct arr_1 args, struct dict_1* environ) {
	struct arr_0 _0 = _concat_0(ctx, (struct arr_0) {23, constantarr_0_35}, exe);
	struct arr_0 _1 = fold(ctx, _0, args, (struct fun_act2_2) {0, .as0 = (struct void_) {}});
	print(_1);
	uint8_t _2 = is_file__q_0(ctx, exe);
	if (_2) {
		char* exe_c_str0;
		exe_c_str0 = to_c_str(ctx, exe);
		
		char** _3 = convert_args(ctx, exe_c_str0, args);
		char** _4 = convert_environ(ctx, environ);
		return spawn_and_wait_result_1(ctx, exe_c_str0, _3, _4);
	} else {
		struct arr_0 _5 = _concat_0(ctx, exe, (struct arr_0) {14, constantarr_0_50});
		return fail_3(ctx, _5);
	}
}
/* fold<arr<char>, arr<char>> arr<char>(val arr<char>, a arr<arr<char>>, combine fun-act2<arr<char>, arr<char>, arr<char>>) */
struct arr_0 fold(struct ctx* ctx, struct arr_0 val, struct arr_1 a, struct fun_act2_2 combine) {
	top:;
	uint8_t _0 = empty__q_1(a);
	if (_0) {
		return val;
	} else {
		struct arr_0 _1 = first_0(ctx, a);
		struct arr_0 _2 = subscript_56(ctx, combine, val, _1);
		struct arr_1 _3 = tail_0(ctx, a);
		val = _2;
		a = _3;
		combine = combine;
		goto top;
	}
}
/* subscript<?a, ?a, ?b> arr<char>(a fun-act2<arr<char>, arr<char>, arr<char>>, p0 arr<char>, p1 arr<char>) */
struct arr_0 subscript_56(struct ctx* ctx, struct fun_act2_2 a, struct arr_0 p0, struct arr_0 p1) {
	return call_w_ctx_668(a, ctx, p0, p1);
}
/* call-w-ctx<arr<char>, arr<char>, arr<char>> (generated) (generated) */
struct arr_0 call_w_ctx_668(struct fun_act2_2 a, struct ctx* ctx, struct arr_0 p0, struct arr_0 p1) {
	struct fun_act2_2 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return spawn_and_wait_result_0__lambda0(ctx, closure0, p0, p1);
		}
		default:
			return (struct arr_0) {0, NULL};
	}
}
/* spawn-and-wait-result.lambda0 arr<char>(a arr<char>, b arr<char>) */
struct arr_0 spawn_and_wait_result_0__lambda0(struct ctx* ctx, struct void_ _closure, struct arr_0 a, struct arr_0 b) {
	struct arr_0 _0 = _concat_0(ctx, a, (struct arr_0) {1, constantarr_0_34});
	return _concat_0(ctx, _0, b);
}
/* is-file? bool(path arr<char>) */
uint8_t is_file__q_0(struct ctx* ctx, struct arr_0 path) {
	char* _0 = to_c_str(ctx, path);
	return is_file__q_1(ctx, _0);
}
/* is-file? bool(path ptr<char>) */
uint8_t is_file__q_1(struct ctx* ctx, char* path) {
	struct opt_12 _0 = get_stat(ctx, path);
	switch (_0.kind) {
		case 0: {
			return 0;
		}
		case 1: {
			struct some_12 s0 = _0.as1;
			
			uint32_t _1 = s_ifmt(ctx);
			uint32_t _2 = s_ifreg(ctx);
			return _equal_5((s0.value->st_mode & _1), _2);
		}
		default:
			return 0;
	}
}
/* s-ifreg nat32() */
uint32_t s_ifreg(struct ctx* ctx) {
	return 32768u;
}
/* spawn-and-wait-result process-result(exe ptr<char>, args ptr<ptr<char>>, environ ptr<ptr<char>>) */
struct process_result* spawn_and_wait_result_1(struct ctx* ctx, char* exe, char** args, char** environ) {
	struct pipes* stdout_pipes0;
	stdout_pipes0 = make_pipes(ctx);
	
	struct pipes* stderr_pipes1;
	stderr_pipes1 = make_pipes(ctx);
	
	struct posix_spawn_file_actions_t* actions2;
	struct posix_spawn_file_actions_t* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct posix_spawn_file_actions_t));
	temp0 = (struct posix_spawn_file_actions_t*) _0;
	
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
	temp1 = (struct cell_5*) _11;
	
	*temp1 = (struct cell_5) {0};
	pid_cell3 = temp1;
	
	int32_t _12 = posix_spawn(pid_cell3, exe, actions2, NULL, args, environ);
	check_posix_error(ctx, _12);
	int32_t pid4;
	pid4 = pid_cell3->subscript;
	
	int32_t _13 = close(stdout_pipes0->read_pipe);
	check_posix_error(ctx, _13);
	int32_t _14 = close(stderr_pipes1->read_pipe);
	check_posix_error(ctx, _14);
	struct mut_list_5* stdout_builder5;
	stdout_builder5 = mut_list_3(ctx);
	
	struct mut_list_5* stderr_builder6;
	stderr_builder6 = mut_list_3(ctx);
	
	keep_polling(ctx, stdout_pipes0->write_pipe, stderr_pipes1->write_pipe, stdout_builder5, stderr_builder6);
	int32_t exit_code7;
	exit_code7 = wait_and_get_exit_code(ctx, pid4);
	
	struct process_result* temp2;
	uint8_t* _15 = alloc(ctx, sizeof(struct process_result));
	temp2 = (struct process_result*) _15;
	
	struct arr_0 _16 = move_to_arr__e_4(stdout_builder5);
	struct arr_0 _17 = move_to_arr__e_4(stderr_builder6);
	*temp2 = (struct process_result) {exit_code7, _16, _17};
	return temp2;
}
/* make-pipes pipes() */
struct pipes* make_pipes(struct ctx* ctx) {
	struct pipes* res0;
	struct pipes* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct pipes));
	temp0 = (struct pipes*) _0;
	
	*temp0 = (struct pipes) {0, 0};
	res0 = temp0;
	
	int32_t _1 = pipe(res0);
	check_posix_error(ctx, _1);
	return res0;
}
/* mut-list<char> mut-list<char>() */
struct mut_list_5* mut_list_3(struct ctx* ctx) {
	struct mut_list_5* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_list_5));
	temp0 = (struct mut_list_5*) _0;
	
	struct mut_arr_4 _1 = mut_arr_12();
	*temp0 = (struct mut_list_5) {_1, 0u};
	return temp0;
}
/* mut-arr<?t> mut-arr<char>() */
struct mut_arr_4 mut_arr_12(void) {
	return (struct mut_arr_4) {(struct void_) {}, (struct arr_0) {0u, NULL}};
}
/* keep-polling void(stdout-pipe int32, stderr-pipe int32, stdout-builder mut-list<char>, stderr-builder mut-list<char>) */
struct void_ keep_polling(struct ctx* ctx, int32_t stdout_pipe, int32_t stderr_pipe, struct mut_list_5* stdout_builder, struct mut_list_5* stderr_builder) {
	top:;
	struct arr_9 poll_fds0;
	struct pollfd* temp0;
	uint8_t* _0 = alloc(ctx, (sizeof(struct pollfd) * 2u));
	temp0 = (struct pollfd*) _0;
	
	int16_t _1 = pollin(ctx);
	*(temp0 + 0u) = (struct pollfd) {stdout_pipe, _1, 0};
	int16_t _2 = pollin(ctx);
	*(temp0 + 1u) = (struct pollfd) {stderr_pipe, _2, 0};
	poll_fds0 = (struct arr_9) {2u, temp0};
	
	struct pollfd* stdout_pollfd1;
	stdout_pollfd1 = ref_of_val_at(ctx, poll_fds0, 0u);
	
	struct pollfd* stderr_pollfd2;
	stderr_pollfd2 = ref_of_val_at(ctx, poll_fds0, 1u);
	
	int32_t n_pollfds_with_events3;
	n_pollfds_with_events3 = poll(poll_fds0.data, poll_fds0.size, -1);
	
	uint8_t _3 = _equal_2(n_pollfds_with_events3, 0);
	if (_3) {
		return (struct void_) {};
	} else {
		struct handle_revents_result a4;
		a4 = handle_revents(ctx, stdout_pollfd1, stdout_builder);
		
		struct handle_revents_result b5;
		b5 = handle_revents(ctx, stderr_pollfd2, stderr_builder);
		
		uint8_t _4 = any__q(ctx, a4);
		uint64_t _5 = to_nat_1(_4);
		uint8_t _6 = any__q(ctx, b5);
		uint64_t _7 = to_nat_1(_6);
		uint64_t _8 = _plus(ctx, _5, _7);
		uint64_t _9 = to_nat_2(ctx, n_pollfds_with_events3);
		uint8_t _10 = _equal_0(_8, _9);
		assert_0(ctx, _10);uint8_t _11;
		
		if (a4.hung_up__q) {
			_11 = b5.hung_up__q;
		} else {
			_11 = 0;
		}
		uint8_t _12 = not(_11);
		if (_12) {
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
/* pollin int16() */
int16_t pollin(struct ctx* ctx) {
	return 1;
}
/* ref-of-val-at<pollfd> pollfd(a arr<pollfd>, index nat) */
struct pollfd* ref_of_val_at(struct ctx* ctx, struct arr_9 a, uint64_t index) {
	uint8_t _0 = _less_0(index, a.size);
	assert_0(ctx, _0);
	return ref_of_ptr((a.data + index));
}
/* ref-of-ptr<?t> pollfd(p ptr<pollfd>) */
struct pollfd* ref_of_ptr(struct pollfd* p) {
	return (&(*p));
}
/* handle-revents handle-revents-result(pollfd pollfd, builder mut-list<char>) */
struct handle_revents_result handle_revents(struct ctx* ctx, struct pollfd* pollfd, struct mut_list_5* builder) {
	int16_t revents0;
	revents0 = pollfd->revents;
	
	uint8_t had_pollin__q1;
	had_pollin__q1 = has_pollin__q(ctx, revents0);
	
	uint8_t _0 = had_pollin__q1;
	if (_0) {
		read_to_buffer_until_eof(ctx, pollfd->fd, builder);
	} else {
		(struct void_) {};
	}
	uint8_t hung_up__q2;
	hung_up__q2 = has_pollhup__q(ctx, revents0);
	
	uint8_t _1 = has_pollpri__q(ctx, revents0);uint8_t _2;
	
	if (_1) {
		_2 = 1;
	} else {
		_2 = has_pollout__q(ctx, revents0);
	}uint8_t _3;
	
	if (_2) {
		_3 = 1;
	} else {
		_3 = has_pollerr__q(ctx, revents0);
	}uint8_t _4;
	
	if (_3) {
		_4 = 1;
	} else {
		_4 = has_pollnval__q(ctx, revents0);
	}
	if (_4) {
		todo_0();
	} else {
		(struct void_) {};
	}
	return (struct handle_revents_result) {had_pollin__q1, hung_up__q2};
}
/* has-pollin? bool(revents int16) */
uint8_t has_pollin__q(struct ctx* ctx, int16_t revents) {
	int16_t _0 = pollin(ctx);
	return bits_intersect__q(revents, _0);
}
/* bits-intersect? bool(a int16, b int16) */
uint8_t bits_intersect__q(int16_t a, int16_t b) {
	uint8_t _0 = _equal_6((a & b), 0);
	return not(_0);
}
/* ==<int16> bool(a int16, b int16) */
uint8_t _equal_6(int16_t a, int16_t b) {
	struct comparison _0 = compare_692(a, b);
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
/* compare<int-16> (generated) (generated) */
struct comparison compare_692(int16_t a, int16_t b) {
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
/* read-to-buffer-until-eof void(fd int32, buffer mut-list<char>) */
struct void_ read_to_buffer_until_eof(struct ctx* ctx, int32_t fd, struct mut_list_5* buffer) {
	top:;
	uint64_t _0 = _plus(ctx, buffer->size, 1024u);
	reserve(ctx, buffer, _0);
	char* add_data_to0;
	char* _1 = data_11(buffer);
	add_data_to0 = (_1 + buffer->size);
	
	int64_t n_bytes_read1;
	n_bytes_read1 = read(fd, (uint8_t*) add_data_to0, 1024u);
	
	uint8_t _2 = _equal_1(n_bytes_read1, -1);
	if (_2) {
		return todo_0();
	} else {
		uint8_t _3 = _equal_1(n_bytes_read1, 0);
		if (_3) {
			return (struct void_) {};
		} else {
			uint64_t _4 = to_nat_0(ctx, n_bytes_read1);
			uint8_t _5 = _lessOrEqual(_4, 1024u);
			assert_0(ctx, _5);
			uint64_t _6 = to_nat_0(ctx, n_bytes_read1);
			unsafe_increase_size__e(ctx, buffer, _6);
			fd = fd;
			buffer = buffer;
			goto top;
		}
	}
}
/* reserve<char> void(a mut-list<char>, reserved nat) */
struct void_ reserve(struct ctx* ctx, struct mut_list_5* a, uint64_t reserved) {
	uint64_t _0 = round_up_to_power_of_two(ctx, reserved);
	return ensure_capacity_3(ctx, a, _0);
}
/* ensure-capacity<?t> void(a mut-list<char>, min-capacity nat) */
struct void_ ensure_capacity_3(struct ctx* ctx, struct mut_list_5* a, uint64_t min_capacity) {
	uint64_t _0 = capacity_4(a);
	uint8_t _1 = _less_0(_0, min_capacity);
	if (_1) {
		return increase_capacity_to__e_3(ctx, a, min_capacity);
	} else {
		return (struct void_) {};
	}
}
/* capacity<?t> nat(a mut-list<char>) */
uint64_t capacity_4(struct mut_list_5* a) {
	return size_4(a->backing);
}
/* increase-capacity-to!<?t> void(a mut-list<char>, new-capacity nat) */
struct void_ increase_capacity_to__e_3(struct ctx* ctx, struct mut_list_5* a, uint64_t new_capacity) {
	uint64_t _0 = capacity_4(a);
	uint8_t _1 = _greater(new_capacity, _0);
	assert_0(ctx, _1);
	char* old_data0;
	old_data0 = data_11(a);
	
	char* _2 = alloc_uninitialized_0(ctx, new_capacity);
	struct mut_arr_4 _3 = mut_arr_9(new_capacity, _2);
	a->backing = _3;
	char* _4 = data_11(a);
	copy_data_from_0(ctx, _4, old_data0, a->size);
	uint64_t _5 = _plus(ctx, a->size, 1u);
	uint64_t _6 = size_4(a->backing);
	struct arrow_0 _7 = _arrow_0(ctx, _5, _6);
	struct mut_arr_4 _8 = subscript_57(ctx, a->backing, _7);
	return set_zero_elements_3(_8);
}
/* data<?t> ptr<char>(a mut-list<char>) */
char* data_11(struct mut_list_5* a) {
	return data_8(a->backing);
}
/* set-zero-elements<?t> void(a mut-arr<char>) */
struct void_ set_zero_elements_3(struct mut_arr_4 a) {
	char* _0 = data_8(a);
	uint64_t _1 = size_4(a);
	return set_zero_range_4(_0, _1);
}
/* set-zero-range<?t> void(begin ptr<char>, size nat) */
struct void_ set_zero_range_4(char* begin, uint64_t size) {
	return (memset((uint8_t*) begin, 0u, (size * sizeof(char))), (struct void_) {});
}
/* subscript<?t> mut-arr<char>(a mut-arr<char>, range arrow<nat, nat>) */
struct mut_arr_4 subscript_57(struct ctx* ctx, struct mut_arr_4 a, struct arrow_0 range) {
	struct arr_0 _0 = subscript_25(ctx, a.inner, range);
	return (struct mut_arr_4) {(struct void_) {}, _0};
}
/* unsafe-increase-size!<char> void(a mut-list<char>, increase-by nat) */
struct void_ unsafe_increase_size__e(struct ctx* ctx, struct mut_list_5* a, uint64_t increase_by) {
	uint64_t _0 = _plus(ctx, a->size, increase_by);
	return unsafe_set_size__e(ctx, a, _0);
}
/* unsafe-set-size!<?t> void(a mut-list<char>, new-size nat) */
struct void_ unsafe_set_size__e(struct ctx* ctx, struct mut_list_5* a, uint64_t new_size) {
	uint64_t _0 = capacity_4(a);
	uint8_t _1 = _lessOrEqual(new_size, _0);
	assert_0(ctx, _1);
	return (a->size = new_size, (struct void_) {});
}
/* has-pollhup? bool(revents int16) */
uint8_t has_pollhup__q(struct ctx* ctx, int16_t revents) {
	int16_t _0 = pollhup(ctx);
	return bits_intersect__q(revents, _0);
}
/* pollhup int16() */
int16_t pollhup(struct ctx* ctx) {
	return 16;
}
/* has-pollpri? bool(revents int16) */
uint8_t has_pollpri__q(struct ctx* ctx, int16_t revents) {
	int16_t _0 = pollpri(ctx);
	return bits_intersect__q(revents, _0);
}
/* pollpri int16() */
int16_t pollpri(struct ctx* ctx) {
	return 2;
}
/* has-pollout? bool(revents int16) */
uint8_t has_pollout__q(struct ctx* ctx, int16_t revents) {
	int16_t _0 = pollout(ctx);
	return bits_intersect__q(revents, _0);
}
/* pollout int16() */
int16_t pollout(struct ctx* ctx) {
	return 4;
}
/* has-pollerr? bool(revents int16) */
uint8_t has_pollerr__q(struct ctx* ctx, int16_t revents) {
	int16_t _0 = pollerr(ctx);
	return bits_intersect__q(revents, _0);
}
/* pollerr int16() */
int16_t pollerr(struct ctx* ctx) {
	return 8;
}
/* has-pollnval? bool(revents int16) */
uint8_t has_pollnval__q(struct ctx* ctx, int16_t revents) {
	int16_t _0 = pollnval(ctx);
	return bits_intersect__q(revents, _0);
}
/* pollnval int16() */
int16_t pollnval(struct ctx* ctx) {
	return 32;
}
/* to-nat nat(b bool) */
uint64_t to_nat_1(uint8_t b) {
	uint8_t _0 = b;
	if (_0) {
		return 1u;
	} else {
		return 0u;
	}
}
/* any? bool(r handle-revents-result) */
uint8_t any__q(struct ctx* ctx, struct handle_revents_result r) {
	if (r.had_pollin__q) {
		return 1;
	} else {
		return r.hung_up__q;
	}
}
/* to-nat nat(i int32) */
uint64_t to_nat_2(struct ctx* ctx, int32_t i) {
	return to_nat_0(ctx, (int64_t) i);
}
/* wait-and-get-exit-code int32(pid int32) */
int32_t wait_and_get_exit_code(struct ctx* ctx, int32_t pid) {
	struct cell_5* wait_status_cell0;
	struct cell_5* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct cell_5));
	temp0 = (struct cell_5*) _0;
	
	*temp0 = (struct cell_5) {0};
	wait_status_cell0 = temp0;
	
	int32_t res_pid1;
	res_pid1 = waitpid(pid, wait_status_cell0, 0);
	
	int32_t wait_status2;
	wait_status2 = wait_status_cell0->subscript;
	
	uint8_t _1 = _equal_2(res_pid1, pid);
	assert_0(ctx, _1);
	uint8_t _2 = w_if_exited(ctx, wait_status2);
	if (_2) {
		return w_exit_status(ctx, wait_status2);
	} else {
		uint8_t _3 = w_if_signaled(ctx, wait_status2);
		if (_3) {
			int32_t signal3;
			signal3 = w_term_sig(ctx, wait_status2);
			
			struct arr_0 _4 = to_str_2(ctx, signal3);
			struct arr_0 _5 = _concat_0(ctx, (struct arr_0) {31, constantarr_0_36}, _4);
			print(_5);
			return todo_8();
		} else {
			uint8_t _6 = w_if_stopped(ctx, wait_status2);
			if (_6) {
				print((struct arr_0) {12, constantarr_0_48});
				return todo_8();
			} else {
				uint8_t _7 = w_if_continued(ctx, wait_status2);
				if (_7) {
					return todo_8();
				} else {
					return todo_8();
				}
			}
		}
	}
}
/* w-if-exited bool(status int32) */
uint8_t w_if_exited(struct ctx* ctx, int32_t status) {
	int32_t _0 = w_term_sig(ctx, status);
	return _equal_2(_0, 0);
}
/* w-term-sig int32(status int32) */
int32_t w_term_sig(struct ctx* ctx, int32_t status) {
	return (status & 127);
}
/* w-exit-status int32(status int32) */
int32_t w_exit_status(struct ctx* ctx, int32_t status) {
	return bit_shift_right((status & 65280), 8);
}
/* bit-shift-right int32(a int32, b int32) */
int32_t bit_shift_right(int32_t a, int32_t b) {
	uint8_t _0 = _less_3(a, 0);
	if (_0) {
		return todo_8();
	} else {
		uint8_t _1 = _less_3(b, 0);
		if (_1) {
			return todo_8();
		} else {
			uint8_t _2 = _less_3(b, 32);
			if (_2) {
				return (int32_t) (int64_t) ((uint64_t) (int64_t) a >> (uint64_t) (int64_t) b);
			} else {
				return todo_8();
			}
		}
	}
}
/* <<int32> bool(a int32, b int32) */
uint8_t _less_3(int32_t a, int32_t b) {
	struct comparison _0 = compare_66(a, b);
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
/* todo<int32> int32() */
int32_t todo_8(void) {
	(abort(), (struct void_) {});
	return 0;
}
/* w-if-signaled bool(status int32) */
uint8_t w_if_signaled(struct ctx* ctx, int32_t status) {
	int32_t ts0;
	ts0 = w_term_sig(ctx, status);
	
	uint8_t _0 = _notEqual_2(ts0, 0);
	if (_0) {
		return _notEqual_2(ts0, 127);
	} else {
		return 0;
	}
}
/* to-str arr<char>(i int32) */
struct arr_0 to_str_2(struct ctx* ctx, int32_t i) {
	return to_str_3(ctx, (int64_t) i);
}
/* to-str arr<char>(i int) */
struct arr_0 to_str_3(struct ctx* ctx, int64_t i) {
	struct arr_0 a0;
	uint64_t _0 = abs(ctx, i);
	a0 = to_str_4(ctx, _0);
	
	uint8_t _1 = negative__q(ctx, i);
	if (_1) {
		return _concat_0(ctx, (struct arr_0) {1, constantarr_0_47}, a0);
	} else {
		return a0;
	}
}
/* to-str arr<char>(n nat) */
struct arr_0 to_str_4(struct ctx* ctx, uint64_t n) {
	uint8_t _0 = _equal_0(n, 0u);
	if (_0) {
		return (struct arr_0) {1, constantarr_0_37};
	} else {
		uint8_t _1 = _equal_0(n, 1u);
		if (_1) {
			return (struct arr_0) {1, constantarr_0_38};
		} else {
			uint8_t _2 = _equal_0(n, 2u);
			if (_2) {
				return (struct arr_0) {1, constantarr_0_39};
			} else {
				uint8_t _3 = _equal_0(n, 3u);
				if (_3) {
					return (struct arr_0) {1, constantarr_0_40};
				} else {
					uint8_t _4 = _equal_0(n, 4u);
					if (_4) {
						return (struct arr_0) {1, constantarr_0_41};
					} else {
						uint8_t _5 = _equal_0(n, 5u);
						if (_5) {
							return (struct arr_0) {1, constantarr_0_42};
						} else {
							uint8_t _6 = _equal_0(n, 6u);
							if (_6) {
								return (struct arr_0) {1, constantarr_0_43};
							} else {
								uint8_t _7 = _equal_0(n, 7u);
								if (_7) {
									return (struct arr_0) {1, constantarr_0_44};
								} else {
									uint8_t _8 = _equal_0(n, 8u);
									if (_8) {
										return (struct arr_0) {1, constantarr_0_45};
									} else {
										uint8_t _9 = _equal_0(n, 9u);
										if (_9) {
											return (struct arr_0) {1, constantarr_0_46};
										} else {
											struct arr_0 hi0;
											uint64_t _10 = _divide(ctx, n, 10u);
											hi0 = to_str_4(ctx, _10);
											
											struct arr_0 lo1;
											uint64_t _11 = mod(ctx, n, 10u);
											lo1 = to_str_4(ctx, _11);
											
											return _concat_0(ctx, hi0, lo1);
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
/* mod nat(a nat, b nat) */
uint64_t mod(struct ctx* ctx, uint64_t a, uint64_t b) {
	uint8_t _0 = _equal_0(b, 0u);
	forbid_0(ctx, _0);
	return (a % b);
}
/* abs nat(i int) */
uint64_t abs(struct ctx* ctx, int64_t i) {
	int64_t i_abs0;
	uint8_t _0 = negative__q(ctx, i);
	if (_0) {
		i_abs0 = neg(ctx, i);
	} else {
		i_abs0 = i;
	}
	
	return to_nat_0(ctx, i_abs0);
}
/* neg int(i int) */
int64_t neg(struct ctx* ctx, int64_t i) {
	return _times_1(ctx, i, -1);
}
/* * int(a int, b int) */
int64_t _times_1(struct ctx* ctx, int64_t a, int64_t b) {
	return (a * b);
}
/* w-if-stopped bool(status int32) */
uint8_t w_if_stopped(struct ctx* ctx, int32_t status) {
	return _equal_2((status & 255), 127);
}
/* w-if-continued bool(status int32) */
uint8_t w_if_continued(struct ctx* ctx, int32_t status) {
	return _equal_2(status, 65535);
}
/* move-to-arr!<char> arr<char>(a mut-list<char>) */
struct arr_0 move_to_arr__e_4(struct mut_list_5* a) {
	struct arr_0 res0;
	char* _0 = data_11(a);
	res0 = (struct arr_0) {a->size, _0};
	
	struct mut_arr_4 _1 = mut_arr_12();
	a->backing = _1;
	a->size = 0u;
	return res0;
}
/* convert-args ptr<ptr<char>>(exe-c-str ptr<char>, args arr<arr<char>>) */
char** convert_args(struct ctx* ctx, char* exe_c_str, struct arr_1 args) {
	char** temp0;
	uint8_t* _0 = alloc(ctx, (sizeof(char*) * 1u));
	temp0 = (char**) _0;
	
	*(temp0 + 0u) = exe_c_str;
	struct arr_4 _1 = map_3(ctx, args, (struct fun_act1_16) {0, .as0 = (struct void_) {}});
	struct arr_4 _2 = _concat_1(ctx, (struct arr_4) {1u, temp0}, _1);
	char** temp1;
	uint8_t* _3 = alloc(ctx, (sizeof(char*) * 1u));
	temp1 = (char**) _3;
	
	*(temp1 + 0u) = NULL;
	struct arr_4 _4 = _concat_1(ctx, _2, (struct arr_4) {1u, temp1});
	return _4.data;
}
/* ~<ptr<char>> arr<ptr<char>>(a arr<ptr<char>>, b arr<ptr<char>>) */
struct arr_4 _concat_1(struct ctx* ctx, struct arr_4 a, struct arr_4 b) {
	uint64_t res_size0;
	res_size0 = _plus(ctx, a.size, b.size);
	
	char** res1;
	res1 = alloc_uninitialized_5(ctx, res_size0);
	
	copy_data_from_4(ctx, res1, a.data, a.size);
	copy_data_from_4(ctx, (res1 + a.size), b.data, b.size);
	return (struct arr_4) {res_size0, res1};
}
/* alloc-uninitialized<?t> ptr<ptr<char>>(size nat) */
char** alloc_uninitialized_5(struct ctx* ctx, uint64_t size) {
	uint8_t* _0 = alloc(ctx, (size * sizeof(char*)));
	return (char**) _0;
}
/* copy-data-from<?t> void(to ptr<ptr<char>>, from ptr<ptr<char>>, len nat) */
struct void_ copy_data_from_4(struct ctx* ctx, char** to, char** from, uint64_t len) {
	return (memcpy((uint8_t*) to, (uint8_t*) from, (len * sizeof(char*))), (struct void_) {});
}
/* map<ptr<char>, arr<char>> arr<ptr<char>>(a arr<arr<char>>, mapper fun-act1<ptr<char>, arr<char>>) */
struct arr_4 map_3(struct ctx* ctx, struct arr_1 a, struct fun_act1_16 mapper) {
	struct map_3__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct map_3__lambda0));
	temp0 = (struct map_3__lambda0*) _0;
	
	*temp0 = (struct map_3__lambda0) {mapper, a};
	return make_arr_2(ctx, a.size, (struct fun_act1_17) {0, .as0 = temp0});
}
/* make-arr<?out> arr<ptr<char>>(size nat, f fun-act1<ptr<char>, nat>) */
struct arr_4 make_arr_2(struct ctx* ctx, uint64_t size, struct fun_act1_17 f) {
	char** data0;
	data0 = alloc_uninitialized_5(ctx, size);
	
	fill_ptr_range_3(ctx, data0, size, f);
	return (struct arr_4) {size, data0};
}
/* fill-ptr-range<?t> void(begin ptr<ptr<char>>, size nat, f fun-act1<ptr<char>, nat>) */
struct void_ fill_ptr_range_3(struct ctx* ctx, char** begin, uint64_t size, struct fun_act1_17 f) {
	return fill_ptr_range_recur_3(ctx, begin, 0u, size, f);
}
/* fill-ptr-range-recur<?t> void(begin ptr<ptr<char>>, i nat, size nat, f fun-act1<ptr<char>, nat>) */
struct void_ fill_ptr_range_recur_3(struct ctx* ctx, char** begin, uint64_t i, uint64_t size, struct fun_act1_17 f) {
	top:;
	uint8_t _0 = _notEqual_1(i, size);
	if (_0) {
		char* _1 = subscript_58(ctx, f, i);
		set_subscript_14(begin, i, _1);
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
/* set-subscript<?t> void(a ptr<ptr<char>>, n nat, value ptr<char>) */
struct void_ set_subscript_14(char** a, uint64_t n, char* value) {
	return (*(a + n) = value, (struct void_) {});
}
/* subscript<?t, nat> ptr<char>(a fun-act1<ptr<char>, nat>, p0 nat) */
char* subscript_58(struct ctx* ctx, struct fun_act1_17 a, uint64_t p0) {
	return call_w_ctx_747(a, ctx, p0);
}
/* call-w-ctx<raw-ptr(char), nat-64> (generated) (generated) */
char* call_w_ctx_747(struct fun_act1_17 a, struct ctx* ctx, uint64_t p0) {
	struct fun_act1_17 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct map_3__lambda0* closure0 = _0.as0;
			
			return map_3__lambda0(ctx, closure0, p0);
		}
		default:
			return NULL;
	}
}
/* subscript<?out, ?in> ptr<char>(a fun-act1<ptr<char>, arr<char>>, p0 arr<char>) */
char* subscript_59(struct ctx* ctx, struct fun_act1_16 a, struct arr_0 p0) {
	return call_w_ctx_749(a, ctx, p0);
}
/* call-w-ctx<raw-ptr(char), arr<char>> (generated) (generated) */
char* call_w_ctx_749(struct fun_act1_16 a, struct ctx* ctx, struct arr_0 p0) {
	struct fun_act1_16 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct void_ closure0 = _0.as0;
			
			return convert_args__lambda0(ctx, closure0, p0);
		}
		default:
			return NULL;
	}
}
/* map<ptr<char>, arr<char>>.lambda0 ptr<char>(i nat) */
char* map_3__lambda0(struct ctx* ctx, struct map_3__lambda0* _closure, uint64_t i) {
	struct arr_0 _0 = subscript_0(ctx, _closure->a, i);
	return subscript_59(ctx, _closure->mapper, _0);
}
/* convert-args.lambda0 ptr<char>(it arr<char>) */
char* convert_args__lambda0(struct ctx* ctx, struct void_ _closure, struct arr_0 it) {
	return to_c_str(ctx, it);
}
/* convert-environ ptr<ptr<char>>(environ dict<arr<char>, arr<char>>) */
char** convert_environ(struct ctx* ctx, struct dict_1* environ) {
	struct mut_list_6* res0;
	res0 = mut_list_4(ctx);
	
	struct convert_environ__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct convert_environ__lambda0));
	temp0 = (struct convert_environ__lambda0*) _0;
	
	*temp0 = (struct convert_environ__lambda0) {res0};
	each_3(ctx, environ, (struct fun_act2_3) {0, .as0 = temp0});
	_concatEquals_4(ctx, res0, NULL);
	struct arr_4 _1 = move_to_arr__e_5(res0);
	return _1.data;
}
/* mut-list<ptr<char>> mut-list<ptr<char>>() */
struct mut_list_6* mut_list_4(struct ctx* ctx) {
	struct mut_list_6* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct mut_list_6));
	temp0 = (struct mut_list_6*) _0;
	
	struct mut_arr_6 _1 = mut_arr_13();
	*temp0 = (struct mut_list_6) {_1, 0u};
	return temp0;
}
/* mut-arr<?t> mut-arr<ptr<char>>() */
struct mut_arr_6 mut_arr_13(void) {
	return (struct mut_arr_6) {(struct void_) {}, (struct arr_4) {0u, NULL}};
}
/* each<arr<char>, arr<char>> void(d dict<arr<char>, arr<char>>, f fun-act2<void, arr<char>, arr<char>>) */
struct void_ each_3(struct ctx* ctx, struct dict_1* d, struct fun_act2_3 f) {
	top:;
	uint8_t _0 = empty__q_11(ctx, d);
	uint8_t _1 = not(_0);
	if (_1) {
		struct arr_0 _2 = first_0(ctx, d->keys);
		struct arr_0 _3 = first_0(ctx, d->values);
		subscript_60(ctx, f, _2, _3);
		struct arr_1 _4 = tail_0(ctx, d->keys);
		struct arr_1 _5 = tail_0(ctx, d->values);
		struct dict_1* _6 = dict_2(ctx, _4, _5);
		d = _6;
		f = f;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* empty?<?k, ?v> bool(d dict<arr<char>, arr<char>>) */
uint8_t empty__q_11(struct ctx* ctx, struct dict_1* d) {
	return empty__q_1(d->keys);
}
/* subscript<void, ?k, ?v> void(a fun-act2<void, arr<char>, arr<char>>, p0 arr<char>, p1 arr<char>) */
struct void_ subscript_60(struct ctx* ctx, struct fun_act2_3 a, struct arr_0 p0, struct arr_0 p1) {
	return call_w_ctx_758(a, ctx, p0, p1);
}
/* call-w-ctx<void, arr<char>, arr<char>> (generated) (generated) */
struct void_ call_w_ctx_758(struct fun_act2_3 a, struct ctx* ctx, struct arr_0 p0, struct arr_0 p1) {
	struct fun_act2_3 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct convert_environ__lambda0* closure0 = _0.as0;
			
			return convert_environ__lambda0(ctx, closure0, p0, p1);
		}
		default:
			return (struct void_) {};
	}
}
/* ~=<ptr<char>> void(a mut-list<ptr<char>>, value ptr<char>) */
struct void_ _concatEquals_4(struct ctx* ctx, struct mut_list_6* a, char* value) {
	incr_capacity__e_3(ctx, a);
	uint64_t _0 = capacity_5(a);
	uint8_t _1 = _less_0(a->size, _0);
	assert_0(ctx, _1);
	char** _2 = data_12(a);
	set_subscript_14(_2, a->size, value);
	uint64_t _3 = incr_5(ctx, a->size);
	return (a->size = _3, (struct void_) {});
}
/* incr-capacity!<?t> void(a mut-list<ptr<char>>) */
struct void_ incr_capacity__e_3(struct ctx* ctx, struct mut_list_6* a) {
	uint64_t _0 = incr_5(ctx, a->size);
	uint64_t _1 = round_up_to_power_of_two(ctx, _0);
	return ensure_capacity_4(ctx, a, _1);
}
/* ensure-capacity<?t> void(a mut-list<ptr<char>>, min-capacity nat) */
struct void_ ensure_capacity_4(struct ctx* ctx, struct mut_list_6* a, uint64_t min_capacity) {
	uint64_t _0 = capacity_5(a);
	uint8_t _1 = _less_0(_0, min_capacity);
	if (_1) {
		return increase_capacity_to__e_4(ctx, a, min_capacity);
	} else {
		return (struct void_) {};
	}
}
/* capacity<?t> nat(a mut-list<ptr<char>>) */
uint64_t capacity_5(struct mut_list_6* a) {
	return size_6(a->backing);
}
/* size<?t> nat(a mut-arr<ptr<char>>) */
uint64_t size_6(struct mut_arr_6 a) {
	return a.inner.size;
}
/* increase-capacity-to!<?t> void(a mut-list<ptr<char>>, new-capacity nat) */
struct void_ increase_capacity_to__e_4(struct ctx* ctx, struct mut_list_6* a, uint64_t new_capacity) {
	uint64_t _0 = capacity_5(a);
	uint8_t _1 = _greater(new_capacity, _0);
	assert_0(ctx, _1);
	char** old_data0;
	old_data0 = data_12(a);
	
	char** _2 = alloc_uninitialized_5(ctx, new_capacity);
	struct mut_arr_6 _3 = mut_arr_14(new_capacity, _2);
	a->backing = _3;
	char** _4 = data_12(a);
	copy_data_from_4(ctx, _4, old_data0, a->size);
	uint64_t _5 = _plus(ctx, a->size, 1u);
	uint64_t _6 = size_6(a->backing);
	struct arrow_0 _7 = _arrow_0(ctx, _5, _6);
	struct mut_arr_6 _8 = subscript_61(ctx, a->backing, _7);
	return set_zero_elements_4(_8);
}
/* data<?t> ptr<ptr<char>>(a mut-list<ptr<char>>) */
char** data_12(struct mut_list_6* a) {
	return data_13(a->backing);
}
/* data<?t> ptr<ptr<char>>(a mut-arr<ptr<char>>) */
char** data_13(struct mut_arr_6 a) {
	return a.inner.data;
}
/* mut-arr<?t> mut-arr<ptr<char>>(size nat, data ptr<ptr<char>>) */
struct mut_arr_6 mut_arr_14(uint64_t size, char** data) {
	return (struct mut_arr_6) {(struct void_) {}, (struct arr_4) {size, data}};
}
/* set-zero-elements<?t> void(a mut-arr<ptr<char>>) */
struct void_ set_zero_elements_4(struct mut_arr_6 a) {
	char** _0 = data_13(a);
	uint64_t _1 = size_6(a);
	return set_zero_range_5(_0, _1);
}
/* set-zero-range<?t> void(begin ptr<ptr<char>>, size nat) */
struct void_ set_zero_range_5(char** begin, uint64_t size) {
	return (memset((uint8_t*) begin, 0u, (size * sizeof(char*))), (struct void_) {});
}
/* subscript<?t> mut-arr<ptr<char>>(a mut-arr<ptr<char>>, range arrow<nat, nat>) */
struct mut_arr_6 subscript_61(struct ctx* ctx, struct mut_arr_6 a, struct arrow_0 range) {
	struct arr_4 _0 = subscript_15(ctx, a.inner, range);
	return (struct mut_arr_6) {(struct void_) {}, _0};
}
/* convert-environ.lambda0 void(key arr<char>, value arr<char>) */
struct void_ convert_environ__lambda0(struct ctx* ctx, struct convert_environ__lambda0* _closure, struct arr_0 key, struct arr_0 value) {
	struct arr_0 _0 = _concat_0(ctx, key, (struct arr_0) {1, constantarr_0_49});
	struct arr_0 _1 = _concat_0(ctx, _0, value);
	char* _2 = to_c_str(ctx, _1);
	return _concatEquals_4(ctx, _closure->res, _2);
}
/* move-to-arr!<ptr<char>> arr<ptr<char>>(a mut-list<ptr<char>>) */
struct arr_4 move_to_arr__e_5(struct mut_list_6* a) {
	struct arr_4 res0;
	char** _0 = data_12(a);
	res0 = (struct arr_4) {a->size, _0};
	
	struct mut_arr_6 _1 = mut_arr_13();
	a->backing = _1;
	a->size = 0u;
	return res0;
}
/* fail<process-result> process-result(reason arr<char>) */
struct process_result* fail_3(struct ctx* ctx, struct arr_0 reason) {
	struct backtrace _0 = get_backtrace(ctx);
	return throw_3(ctx, (struct exception) {reason, _0});
}
/* throw<?t> process-result(e exception) */
struct process_result* throw_3(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx0;
	exn_ctx0 = get_exception_ctx(ctx);
	
	uint8_t _0 = null__q_1(exn_ctx0->jmp_buf_ptr);
	hard_forbid(_0);
	exn_ctx0->thrown_exception = e;
	int32_t _1 = number_to_throw(ctx);
	(longjmp(exn_ctx0->jmp_buf_ptr, _1), (struct void_) {});
	return todo_9();
}
/* todo<?t> process-result() */
struct process_result* todo_9(void) {
	(abort(), (struct void_) {});
	return NULL;
}
/* handle-output arr<failure>(original-path arr<char>, output-path arr<char>, actual arr<char>, overwrite-output? bool) */
struct arr_8 handle_output(struct ctx* ctx, struct arr_0 original_path, struct arr_0 output_path, struct arr_0 actual, uint8_t overwrite_output__q) {
	struct opt_11 _0 = try_read_file_0(ctx, output_path);
	switch (_0.kind) {
		case 0: {
			uint8_t _1 = overwrite_output__q;
			if (_1) {
				write_file_0(ctx, output_path, actual);
				return (struct arr_8) {0u, NULL};
			} else {
				struct failure** temp0;
				uint8_t* _2 = alloc(ctx, (sizeof(struct failure*) * 1u));
				temp0 = (struct failure**) _2;
				
				struct failure* temp1;
				uint8_t* _3 = alloc(ctx, sizeof(struct failure));
				temp1 = (struct failure*) _3;
				
				struct arr_0 _4 = base_name(ctx, output_path);
				struct arr_0 _5 = _concat_0(ctx, _4, (struct arr_0) {29, constantarr_0_58});
				struct arr_0 _6 = _concat_0(ctx, _5, actual);
				*temp1 = (struct failure) {original_path, _6};
				*(temp0 + 0u) = temp1;
				return (struct arr_8) {1u, temp0};
			}
		}
		case 1: {
			struct some_11 s0 = _0.as1;
			
			uint8_t _7 = _equal_4(s0.value, actual);
			if (_7) {
				return (struct arr_8) {0u, NULL};
			} else {
				uint8_t _8 = overwrite_output__q;
				if (_8) {
					write_file_0(ctx, output_path, actual);
					return (struct arr_8) {0u, NULL};
				} else {
					struct arr_0 message1;
					struct arr_0 _9 = base_name(ctx, output_path);
					struct arr_0 _10 = _concat_0(ctx, _9, (struct arr_0) {30, constantarr_0_59});
					message1 = _concat_0(ctx, _10, actual);
					
					struct failure** temp2;
					uint8_t* _11 = alloc(ctx, (sizeof(struct failure*) * 1u));
					temp2 = (struct failure**) _11;
					
					struct failure* temp3;
					uint8_t* _12 = alloc(ctx, sizeof(struct failure));
					temp3 = (struct failure*) _12;
					
					*temp3 = (struct failure) {original_path, message1};
					*(temp2 + 0u) = temp3;
					return (struct arr_8) {1u, temp2};
				}
			}
		}
		default:
			return (struct arr_8) {0, NULL};
	}
}
/* try-read-file opt<arr<char>>(path arr<char>) */
struct opt_11 try_read_file_0(struct ctx* ctx, struct arr_0 path) {
	char* _0 = to_c_str(ctx, path);
	return try_read_file_1(ctx, _0);
}
/* try-read-file opt<arr<char>>(path ptr<char>) */
struct opt_11 try_read_file_1(struct ctx* ctx, char* path) {
	uint8_t _0 = is_file__q_1(ctx, path);
	if (_0) {
		int32_t fd0;
		int32_t _1 = o_rdonly();
		fd0 = open(path, _1, 0u);
		
		uint8_t _2 = _equal_2(fd0, -1);
		if (_2) {
			int32_t _3 = errno;
			int32_t _4 = enoent();
			uint8_t _5 = _equal_2(_3, _4);
			if (_5) {
				return (struct opt_11) {0, .as0 = (struct none) {}};
			} else {
				struct arr_0 _6 = to_str_1(path);
				struct arr_0 _7 = _concat_0(ctx, (struct arr_0) {20, constantarr_0_53}, _6);
				print(_7);
				return todo_10();
			}
		} else {
			int64_t file_size1;
			int32_t _8 = seek_end(ctx);
			file_size1 = lseek(fd0, 0, _8);
			
			uint8_t _9 = _equal_1(file_size1, -1);
			forbid_0(ctx, _9);
			uint8_t _10 = _less_2(file_size1, 1000000000);
			assert_0(ctx, _10);
			uint8_t _11 = _equal_1(file_size1, 0);
			if (_11) {
				return (struct opt_11) {1, .as1 = (struct some_11) {(struct arr_0) {0u, NULL}}};
			} else {
				int64_t off2;
				int32_t _12 = seek_set(ctx);
				off2 = lseek(fd0, 0, _12);
				
				uint8_t _13 = _equal_1(off2, 0);
				assert_0(ctx, _13);
				uint64_t file_size_nat3;
				file_size_nat3 = to_nat_0(ctx, file_size1);
				
				struct mut_arr_4 res4;
				res4 = uninitialized_mut_arr_3(ctx, file_size_nat3);
				
				int64_t n_bytes_read5;
				char* _14 = data_8(res4);
				n_bytes_read5 = read(fd0, (uint8_t*) _14, file_size_nat3);
				
				uint8_t _15 = _equal_1(n_bytes_read5, -1);
				forbid_0(ctx, _15);
				uint8_t _16 = _equal_1(n_bytes_read5, file_size1);
				assert_0(ctx, _16);
				int32_t _17 = close(fd0);
				check_posix_error(ctx, _17);
				struct arr_0 _18 = cast_immutable_2(res4);
				return (struct opt_11) {1, .as1 = (struct some_11) {_18}};
			}
		}
	} else {
		return (struct opt_11) {0, .as0 = (struct none) {}};
	}
}
/* o-rdonly int32() */
int32_t o_rdonly(void) {
	return 0;
}
/* todo<opt<arr<char>>> opt<arr<char>>() */
struct opt_11 todo_10(void) {
	(abort(), (struct void_) {});
	return (struct opt_11) {0};
}
/* seek-end int32() */
int32_t seek_end(struct ctx* ctx) {
	return 2;
}
/* seek-set int32() */
int32_t seek_set(struct ctx* ctx) {
	return 0;
}
/* write-file void(path arr<char>, content arr<char>) */
struct void_ write_file_0(struct ctx* ctx, struct arr_0 path, struct arr_0 content) {
	char* _0 = to_c_str(ctx, path);
	return write_file_1(ctx, _0, content);
}
/* write-file void(path ptr<char>, content arr<char>) */
struct void_ write_file_1(struct ctx* ctx, char* path, struct arr_0 content) {
	uint32_t permission_rdwr0;
	permission_rdwr0 = 6u;
	
	uint32_t permission_rd1;
	permission_rd1 = 4u;
	
	uint32_t permission2;
	uint32_t _0 = bit_shift_left(permission_rdwr0, 6u);
	uint32_t _1 = bit_shift_left(permission_rd1, 3u);
	permission2 = ((_0 | _1) | permission_rd1);
	
	int32_t flags3;
	int32_t _2 = o_creat();
	int32_t _3 = o_wronly();
	int32_t _4 = o_trunc();
	flags3 = ((_2 | _3) | _4);
	
	int32_t fd4;
	fd4 = open(path, flags3, permission2);
	
	uint8_t _5 = _equal_2(fd4, -1);
	if (_5) {
		struct arr_0 _6 = to_str_1(path);
		struct arr_0 _7 = _concat_0(ctx, (struct arr_0) {31, constantarr_0_54}, _6);
		print(_7);
		int32_t _8 = errno;
		struct arr_0 _9 = to_str_2(ctx, _8);
		struct arr_0 _10 = _concat_0(ctx, (struct arr_0) {7, constantarr_0_55}, _9);
		print(_10);
		struct arr_0 _11 = to_str_2(ctx, flags3);
		struct arr_0 _12 = _concat_0(ctx, (struct arr_0) {7, constantarr_0_56}, _11);
		print(_12);
		struct arr_0 _13 = to_str_5(ctx, permission2);
		struct arr_0 _14 = _concat_0(ctx, (struct arr_0) {12, constantarr_0_57}, _13);
		print(_14);
		return todo_0();
	} else {
		int64_t wrote_bytes5;
		wrote_bytes5 = write(fd4, (uint8_t*) content.data, content.size);
		
		int64_t _15 = to_int(ctx, content.size);
		uint8_t _16 = _notEqual_0(wrote_bytes5, _15);
		if (_16) {
			uint8_t _17 = _equal_1(wrote_bytes5, -1);
			if (_17) {
				todo_0();
			} else {
				todo_0();
			}
		} else {
			(struct void_) {};
		}
		int32_t err6;
		err6 = close(fd4);
		
		uint8_t _18 = _notEqual_2(err6, 0);
		if (_18) {
			return todo_0();
		} else {
			return (struct void_) {};
		}
	}
}
/* bit-shift-left nat32(a nat32, b nat32) */
uint32_t bit_shift_left(uint32_t a, uint32_t b) {
	uint8_t _0 = _less_4(b, 32u);
	if (_0) {
		return (uint32_t) ((uint64_t) a << (uint64_t) b);
	} else {
		return 0u;
	}
}
/* <<nat32> bool(a nat32, b nat32) */
uint8_t _less_4(uint32_t a, uint32_t b) {
	struct comparison _0 = compare_592(a, b);
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
/* o-creat int32() */
int32_t o_creat(void) {
	return 64;
}
/* o-wronly int32() */
int32_t o_wronly(void) {
	return 1;
}
/* o-trunc int32() */
int32_t o_trunc(void) {
	return 512;
}
/* to-str arr<char>(n nat32) */
struct arr_0 to_str_5(struct ctx* ctx, uint32_t n) {
	return to_str_4(ctx, (uint64_t) n);
}
/* to-int int(n nat) */
int64_t to_int(struct ctx* ctx, uint64_t n) {
	int64_t _0 = max_int();
	uint64_t _1 = to_nat_0(ctx, _0);
	uint8_t _2 = _less_0(n, _1);
	assert_0(ctx, _2);
	return (int64_t) n;
}
/* max-int int() */
int64_t max_int(void) {
	return 9223372036854775807;
}
/* remove-colors arr<char>(s arr<char>) */
struct arr_0 remove_colors(struct ctx* ctx, struct arr_0 s) {
	struct mut_list_5* res0;
	res0 = mut_list_3(ctx);
	
	remove_colors_recur(ctx, s, res0);
	return move_to_arr__e_4(res0);
}
/* remove-colors-recur void(s arr<char>, out mut-list<char>) */
struct void_ remove_colors_recur(struct ctx* ctx, struct arr_0 s, struct mut_list_5* out) {
	top:;
	uint8_t _0 = empty__q_0(s);
	if (_0) {
		return (struct void_) {};
	} else {
		char _1 = first_2(ctx, s);
		uint8_t _2 = _equal_3(_1, 27u);
		if (_2) {
			struct arr_0 _3 = tail_3(ctx, s);
			return remove_colors_recur_2(ctx, _3, out);
		} else {
			char _4 = first_2(ctx, s);
			_concatEquals_5(ctx, out, _4);
			struct arr_0 _5 = tail_3(ctx, s);
			s = _5;
			out = out;
			goto top;
		}
	}
}
/* remove-colors-recur-2 void(s arr<char>, out mut-list<char>) */
struct void_ remove_colors_recur_2(struct ctx* ctx, struct arr_0 s, struct mut_list_5* out) {
	top:;
	uint8_t _0 = empty__q_0(s);
	if (_0) {
		return (struct void_) {};
	} else {
		char _1 = first_2(ctx, s);
		uint8_t _2 = _equal_3(_1, 109u);
		if (_2) {
			struct arr_0 _3 = tail_3(ctx, s);
			return remove_colors_recur(ctx, _3, out);
		} else {
			struct arr_0 _4 = tail_3(ctx, s);
			s = _4;
			out = out;
			goto top;
		}
	}
}
/* ~=<char> void(a mut-list<char>, value char) */
struct void_ _concatEquals_5(struct ctx* ctx, struct mut_list_5* a, char value) {
	incr_capacity__e_4(ctx, a);
	uint64_t _0 = capacity_4(a);
	uint8_t _1 = _less_0(a->size, _0);
	assert_0(ctx, _1);
	char* _2 = data_11(a);
	set_subscript_15(_2, a->size, value);
	uint64_t _3 = incr_5(ctx, a->size);
	return (a->size = _3, (struct void_) {});
}
/* incr-capacity!<?t> void(a mut-list<char>) */
struct void_ incr_capacity__e_4(struct ctx* ctx, struct mut_list_5* a) {
	uint64_t _0 = incr_5(ctx, a->size);
	uint64_t _1 = round_up_to_power_of_two(ctx, _0);
	return ensure_capacity_3(ctx, a, _1);
}
/* set-subscript<?t> void(a ptr<char>, n nat, value char) */
struct void_ set_subscript_15(char* a, uint64_t n, char value) {
	return (*(a + n) = value, (struct void_) {});
}
/* run-single-crow-test.lambda0 opt<arr<failure>>(print-kind arr<char>) */
struct opt_14 run_single_crow_test__lambda0(struct ctx* ctx, struct run_single_crow_test__lambda0* _closure, struct arr_0 print_kind) {
	uint8_t _0 = _closure->options.print_tests__q;
	if (_0) {
		struct arr_0 _1 = _concat_0(ctx, (struct arr_0) {11, constantarr_0_33}, print_kind);
		struct arr_0 _2 = _concat_0(ctx, _1, (struct arr_0) {1, constantarr_0_34});
		struct arr_0 _3 = _concat_0(ctx, _2, _closure->path);
		print(_3);
	} else {
		(struct void_) {};
	}
	struct print_test_result* res0;
	res0 = run_print_test(ctx, print_kind, _closure->path_to_crow, _closure->env, _closure->path, _closure->options.overwrite_output__q);
	
	uint8_t _4 = res0->should_stop__q;
	if (_4) {
		return (struct opt_14) {1, .as1 = (struct some_14) {res0->failures}};
	} else {
		return (struct opt_14) {0, .as0 = (struct none) {}};
	}
}
/* run-single-runnable-test arr<failure>(path-to-crow arr<char>, env dict<arr<char>, arr<char>>, path arr<char>, interpret? bool, overwrite-output? bool) */
struct arr_8 run_single_runnable_test(struct ctx* ctx, struct arr_0 path_to_crow, struct dict_1* env, struct arr_0 path, uint8_t interpret__q, uint8_t overwrite_output__q) {
	struct arr_1 args0;
	uint8_t _0 = interpret__q;
	if (_0) {
		struct arr_0* temp0;
		uint8_t* _1 = alloc(ctx, (sizeof(struct arr_0) * 3u));
		temp0 = (struct arr_0*) _1;
		
		*(temp0 + 0u) = (struct arr_0) {3, constantarr_0_63};
		*(temp0 + 1u) = path;
		*(temp0 + 2u) = (struct arr_0) {11, constantarr_0_64};
		args0 = (struct arr_1) {3u, temp0};
	} else {
		struct arr_0* temp1;
		uint8_t* _2 = alloc(ctx, (sizeof(struct arr_0) * 2u));
		temp1 = (struct arr_0*) _2;
		
		*(temp1 + 0u) = (struct arr_0) {3, constantarr_0_63};
		*(temp1 + 1u) = path;
		args0 = (struct arr_1) {2u, temp1};
	}
	
	struct process_result* res1;
	res1 = spawn_and_wait_result_0(ctx, path_to_crow, args0, env);
	
	struct arr_8 stdout_failures2;
	struct arr_0 _3 = _concat_0(ctx, path, (struct arr_0) {7, constantarr_0_65});
	stdout_failures2 = handle_output(ctx, path, _3, res1->stdout, overwrite_output__q);
	
	struct arr_8 stderr_failures3;
	uint8_t _4 = _equal_2(res1->exit_code, 0);uint8_t _5;
	
	if (_4) {
		_5 = _equal_4(res1->stderr, (struct arr_0) {0u, NULL});
	} else {
		_5 = 0;
	}
	if (_5) {
		stderr_failures3 = (struct arr_8) {0u, NULL};
	} else {
		struct arr_0 _6 = _concat_0(ctx, path, (struct arr_0) {7, constantarr_0_66});
		stderr_failures3 = handle_output(ctx, path, _6, res1->stderr, overwrite_output__q);
	}
	
	return _concat_2(ctx, stdout_failures2, stderr_failures3);
}
/* ~<failure> arr<failure>(a arr<failure>, b arr<failure>) */
struct arr_8 _concat_2(struct ctx* ctx, struct arr_8 a, struct arr_8 b) {
	uint64_t res_size0;
	res_size0 = _plus(ctx, a.size, b.size);
	
	struct failure** res1;
	res1 = alloc_uninitialized_4(ctx, res_size0);
	
	copy_data_from_3(ctx, res1, a.data, a.size);
	copy_data_from_3(ctx, (res1 + a.size), b.data, b.size);
	return (struct arr_8) {res_size0, res1};
}
/* run-crow-tests.lambda0 arr<failure>(test arr<char>) */
struct arr_8 run_crow_tests__lambda0(struct ctx* ctx, struct run_crow_tests__lambda0* _closure, struct arr_0 test) {
	return run_single_crow_test(ctx, _closure->path_to_crow, _closure->env, test, _closure->options);
}
/* has?<failure> bool(a arr<failure>) */
uint8_t has__q_2(struct arr_8 a) {
	uint8_t _0 = empty__q_9(a);
	return not(_0);
}
/* do-test.lambda0.lambda0 result<arr<char>, arr<failure>>() */
struct result_2 do_test__lambda0__lambda0(struct ctx* ctx, struct do_test__lambda0__lambda0* _closure) {
	struct arr_0 _0 = child_path(ctx, _closure->test_path, (struct arr_0) {8, constantarr_0_71});
	return run_crow_tests(ctx, _0, _closure->crow_exe, _closure->env, _closure->options);
}
/* do-test.lambda0 result<arr<char>, arr<failure>>() */
struct result_2 do_test__lambda0(struct ctx* ctx, struct do_test__lambda0* _closure) {
	struct arr_0 _0 = child_path(ctx, _closure->test_path, (struct arr_0) {14, constantarr_0_70});
	struct result_2 _1 = run_crow_tests(ctx, _0, _closure->crow_exe, _closure->env, _closure->options);
	struct do_test__lambda0__lambda0* temp0;
	uint8_t* _2 = alloc(ctx, sizeof(struct do_test__lambda0__lambda0));
	temp0 = (struct do_test__lambda0__lambda0*) _2;
	
	*temp0 = (struct do_test__lambda0__lambda0) {_closure->test_path, _closure->crow_exe, _closure->env, _closure->options};
	return first_failures(ctx, _1, (struct fun0) {0, .as0 = temp0});
}
/* lint result<arr<char>, arr<failure>>(path arr<char>, options test-options) */
struct result_2 lint(struct ctx* ctx, struct arr_0 path, struct test_options options) {
	struct arr_1 files0;
	files0 = list_lintable_files(ctx, path);
	
	struct arr_8 failures1;
	struct lint__lambda0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct lint__lambda0));
	temp0 = (struct lint__lambda0*) _0;
	
	*temp0 = (struct lint__lambda0) {options};
	failures1 = flat_map_with_max_size(ctx, files0, options.max_failures, (struct fun_act1_13) {1, .as1 = temp0});
	
	uint8_t _1 = has__q_2(failures1);
	if (_1) {
		return (struct result_2) {1, .as1 = (struct err_1) {failures1}};
	} else {
		struct arr_0 _2 = to_str_4(ctx, files0.size);
		struct arr_0 _3 = _concat_0(ctx, (struct arr_0) {7, constantarr_0_94}, _2);
		struct arr_0 _4 = _concat_0(ctx, _3, (struct arr_0) {6, constantarr_0_95});
		return (struct result_2) {0, .as0 = (struct ok_2) {_4}};
	}
}
/* list-lintable-files arr<arr<char>>(path arr<char>) */
struct arr_1 list_lintable_files(struct ctx* ctx, struct arr_0 path) {
	struct mut_list_1* res0;
	res0 = mut_list_0(ctx);
	
	struct list_lintable_files__lambda1* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct list_lintable_files__lambda1));
	temp0 = (struct list_lintable_files__lambda1*) _0;
	
	*temp0 = (struct list_lintable_files__lambda1) {res0};
	each_child_recursive(ctx, path, (struct fun_act1_6) {6, .as6 = (struct void_) {}}, (struct fun_act1_12) {3, .as3 = temp0});
	return move_to_arr__e_0(res0);
}
/* excluded-from-lint? bool(name arr<char>) */
uint8_t excluded_from_lint__q(struct ctx* ctx, struct arr_0 name) {
	char _0 = first_2(ctx, name);
	uint8_t _1 = _equal_3(_0, 46u);
	if (_1) {
		return 1;
	} else {
		uint8_t _2 = contains__q_2((struct arr_1) {4, constantarr_1_3}, name);
		if (_2) {
			return 1;
		} else {
			struct excluded_from_lint__q__lambda0* temp0;
			uint8_t* _3 = alloc(ctx, sizeof(struct excluded_from_lint__q__lambda0));
			temp0 = (struct excluded_from_lint__q__lambda0*) _3;
			
			*temp0 = (struct excluded_from_lint__q__lambda0) {name};
			return exists__q(ctx, (struct arr_1) {6, constantarr_1_2}, (struct fun_act1_6) {5, .as5 = temp0});
		}
	}
}
/* contains?<arr<char>> bool(a arr<arr<char>>, value arr<char>) */
uint8_t contains__q_2(struct arr_1 a, struct arr_0 value) {
	return contains_recur__q_1(a, value, 0u);
}
/* contains-recur?<?t> bool(a arr<arr<char>>, value arr<char>, i nat) */
uint8_t contains_recur__q_1(struct arr_1 a, struct arr_0 value, uint64_t i) {
	top:;
	uint8_t _0 = _equal_0(i, a.size);
	if (_0) {
		return 0;
	} else {
		struct arr_0 _1 = noctx_at_0(a, i);
		uint8_t _2 = _equal_4(_1, value);
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
/* exists?<arr<char>> bool(a arr<arr<char>>, pred fun-act1<bool, arr<char>>) */
uint8_t exists__q(struct ctx* ctx, struct arr_1 a, struct fun_act1_6 pred) {
	top:;
	uint8_t _0 = empty__q_1(a);
	if (_0) {
		return 0;
	} else {
		struct arr_0 _1 = first_0(ctx, a);
		uint8_t _2 = subscript_22(ctx, pred, _1);
		if (_2) {
			return 1;
		} else {
			struct arr_1 _3 = tail_0(ctx, a);
			a = _3;
			pred = pred;
			goto top;
		}
	}
}
/* ends-with?<char> bool(a arr<char>, end arr<char>) */
uint8_t ends_with__q(struct ctx* ctx, struct arr_0 a, struct arr_0 end) {
	uint8_t _0 = _greaterOrEqual(a.size, end.size);
	if (_0) {
		uint64_t _1 = _minus_2(ctx, a.size, end.size);
		struct arrow_0 _2 = _arrow_0(ctx, _1, a.size);
		struct arr_0 _3 = subscript_25(ctx, a, _2);
		return arr_eq__q(ctx, _3, end);
	} else {
		return 0;
	}
}
/* excluded-from-lint?.lambda0 bool(it arr<char>) */
uint8_t excluded_from_lint__q__lambda0(struct ctx* ctx, struct excluded_from_lint__q__lambda0* _closure, struct arr_0 it) {
	return ends_with__q(ctx, _closure->name, it);
}
/* list-lintable-files.lambda0 bool(it arr<char>) */
uint8_t list_lintable_files__lambda0(struct ctx* ctx, struct void_ _closure, struct arr_0 it) {
	uint8_t _0 = excluded_from_lint__q(ctx, it);
	return not(_0);
}
/* ignore-extension-of-name? bool(name arr<char>) */
uint8_t ignore_extension_of_name__q(struct ctx* ctx, struct arr_0 name) {
	struct opt_11 _0 = get_extension(ctx, name);
	switch (_0.kind) {
		case 0: {
			return 1;
		}
		case 1: {
			struct some_11 s0 = _0.as1;
			
			return ignore_extension__q(ctx, s0.value);
		}
		default:
			return 0;
	}
}
/* ignore-extension? bool(ext arr<char>) */
uint8_t ignore_extension__q(struct ctx* ctx, struct arr_0 ext) {
	struct arr_1 _0 = ignored_extensions(ctx);
	return contains__q_2(_0, ext);
}
/* ignored-extensions arr<arr<char>>() */
struct arr_1 ignored_extensions(struct ctx* ctx) {
	return (struct arr_1) {6, constantarr_1_4};
}
/* list-lintable-files.lambda1 void(child arr<char>) */
struct void_ list_lintable_files__lambda1(struct ctx* ctx, struct list_lintable_files__lambda1* _closure, struct arr_0 child) {
	struct arr_0 _0 = base_name(ctx, child);
	uint8_t _1 = ignore_extension_of_name__q(ctx, _0);
	uint8_t _2 = not(_1);
	if (_2) {
		return _concatEquals_0(ctx, _closure->res, child);
	} else {
		return (struct void_) {};
	}
}
/* lint-file arr<failure>(path arr<char>) */
struct arr_8 lint_file(struct ctx* ctx, struct arr_0 path) {
	struct arr_0 text0;
	text0 = read_file(ctx, path);
	
	struct mut_list_4* res1;
	res1 = mut_list_2(ctx);
	
	struct arr_0 ext2;
	struct opt_11 _0 = get_extension(ctx, path);
	ext2 = force_0(ctx, _0);
	
	uint8_t allow_double_space__q3;
	uint8_t _1 = _equal_4(ext2, (struct arr_0) {3, constantarr_0_88});
	if (_1) {
		allow_double_space__q3 = 1;
	} else {
		allow_double_space__q3 = _equal_4(ext2, (struct arr_0) {14, constantarr_0_89});
	}
	
	struct arr_1 _2 = lines(ctx, text0);
	struct lint_file__lambda0* temp0;
	uint8_t* _3 = alloc(ctx, sizeof(struct lint_file__lambda0));
	temp0 = (struct lint_file__lambda0*) _3;
	
	*temp0 = (struct lint_file__lambda0) {allow_double_space__q3, res1, path};
	each_with_index_0(ctx, _2, (struct fun_act2_4) {0, .as0 = temp0});
	return move_to_arr__e_3(res1);
}
/* read-file arr<char>(path arr<char>) */
struct arr_0 read_file(struct ctx* ctx, struct arr_0 path) {
	struct opt_11 _0 = try_read_file_0(ctx, path);
	switch (_0.kind) {
		case 0: {
			struct arr_0 _1 = _concat_0(ctx, (struct arr_0) {21, constantarr_0_87}, path);
			print(_1);
			return (struct arr_0) {0u, NULL};
		}
		case 1: {
			struct some_11 s0 = _0.as1;
			
			return s0.value;
		}
		default:
			return (struct arr_0) {0, NULL};
	}
}
/* each-with-index<arr<char>> void(a arr<arr<char>>, f fun-act2<void, arr<char>, nat>) */
struct void_ each_with_index_0(struct ctx* ctx, struct arr_1 a, struct fun_act2_4 f) {
	return each_with_index_recur_0(ctx, a, f, 0u);
}
/* each-with-index-recur<?t> void(a arr<arr<char>>, f fun-act2<void, arr<char>, nat>, n nat) */
struct void_ each_with_index_recur_0(struct ctx* ctx, struct arr_1 a, struct fun_act2_4 f, uint64_t n) {
	top:;
	uint8_t _0 = _notEqual_1(n, a.size);
	if (_0) {
		struct arr_0 _1 = subscript_0(ctx, a, n);
		subscript_62(ctx, f, _1, n);
		uint64_t _2 = incr_5(ctx, n);
		a = a;
		f = f;
		n = _2;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* subscript<void, ?t, nat> void(a fun-act2<void, arr<char>, nat>, p0 arr<char>, p1 nat) */
struct void_ subscript_62(struct ctx* ctx, struct fun_act2_4 a, struct arr_0 p0, uint64_t p1) {
	return call_w_ctx_826(a, ctx, p0, p1);
}
/* call-w-ctx<void, arr<char>, nat-64> (generated) (generated) */
struct void_ call_w_ctx_826(struct fun_act2_4 a, struct ctx* ctx, struct arr_0 p0, uint64_t p1) {
	struct fun_act2_4 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct lint_file__lambda0* closure0 = _0.as0;
			
			return lint_file__lambda0(ctx, closure0, p0, p1);
		}
		default:
			return (struct void_) {};
	}
}
/* lines arr<arr<char>>(s arr<char>) */
struct arr_1 lines(struct ctx* ctx, struct arr_0 s) {
	struct mut_list_1* res0;
	res0 = mut_list_0(ctx);
	
	struct cell_0* last_nl1;
	struct cell_0* temp0;
	uint8_t* _0 = alloc(ctx, sizeof(struct cell_0));
	temp0 = (struct cell_0*) _0;
	
	*temp0 = (struct cell_0) {0u};
	last_nl1 = temp0;
	
	struct lines__lambda0* temp1;
	uint8_t* _1 = alloc(ctx, sizeof(struct lines__lambda0));
	temp1 = (struct lines__lambda0*) _1;
	
	*temp1 = (struct lines__lambda0) {last_nl1, res0, s};
	each_with_index_1(ctx, s, (struct fun_act2_5) {0, .as0 = temp1});
	struct arrow_0 _2 = _arrow_0(ctx, last_nl1->subscript, s.size);
	struct arr_0 _3 = subscript_25(ctx, s, _2);
	_concatEquals_0(ctx, res0, _3);
	return move_to_arr__e_0(res0);
}
/* each-with-index<char> void(a arr<char>, f fun-act2<void, char, nat>) */
struct void_ each_with_index_1(struct ctx* ctx, struct arr_0 a, struct fun_act2_5 f) {
	return each_with_index_recur_1(ctx, a, f, 0u);
}
/* each-with-index-recur<?t> void(a arr<char>, f fun-act2<void, char, nat>, n nat) */
struct void_ each_with_index_recur_1(struct ctx* ctx, struct arr_0 a, struct fun_act2_5 f, uint64_t n) {
	top:;
	uint8_t _0 = _notEqual_1(n, a.size);
	if (_0) {
		char _1 = subscript_23(ctx, a, n);
		subscript_63(ctx, f, _1, n);
		uint64_t _2 = incr_5(ctx, n);
		a = a;
		f = f;
		n = _2;
		goto top;
	} else {
		return (struct void_) {};
	}
}
/* subscript<void, ?t, nat> void(a fun-act2<void, char, nat>, p0 char, p1 nat) */
struct void_ subscript_63(struct ctx* ctx, struct fun_act2_5 a, char p0, uint64_t p1) {
	return call_w_ctx_831(a, ctx, p0, p1);
}
/* call-w-ctx<void, char, nat-64> (generated) (generated) */
struct void_ call_w_ctx_831(struct fun_act2_5 a, struct ctx* ctx, char p0, uint64_t p1) {
	struct fun_act2_5 _0 = a;
	switch (_0.kind) {
		case 0: {
			struct lines__lambda0* closure0 = _0.as0;
			
			return lines__lambda0(ctx, closure0, p0, p1);
		}
		default:
			return (struct void_) {};
	}
}
/* swap<nat> nat(c cell<nat>, v nat) */
uint64_t swap_4(struct cell_0* c, uint64_t v) {
	uint64_t res0;
	res0 = c->subscript;
	
	c->subscript = v;
	return res0;
}
/* lines.lambda0 void(c char, index nat) */
struct void_ lines__lambda0(struct ctx* ctx, struct lines__lambda0* _closure, char c, uint64_t index) {
	uint8_t _0 = _equal_3(c, 10u);
	if (_0) {
		uint64_t nl0;
		uint64_t _1 = incr_5(ctx, index);
		nl0 = swap_4(_closure->last_nl, _1);
		
		struct arrow_0 _2 = _arrow_0(ctx, nl0, index);
		struct arr_0 _3 = subscript_25(ctx, _closure->s, _2);
		return _concatEquals_0(ctx, _closure->res, _3);
	} else {
		return (struct void_) {};
	}
}
/* contains-subseq?<char> bool(a arr<char>, subseq arr<char>) */
uint8_t contains_subseq__q(struct ctx* ctx, struct arr_0 a, struct arr_0 subseq) {
	struct opt_8 _0 = index_of_subseq(ctx, a, subseq);
	return has__q_3(_0);
}
/* has?<nat> bool(a opt<nat>) */
uint8_t has__q_3(struct opt_8 a) {
	uint8_t _0 = empty__q_12(a);
	return not(_0);
}
/* empty?<?t> bool(a opt<nat>) */
uint8_t empty__q_12(struct opt_8 a) {
	struct opt_8 _0 = a;
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
/* index-of-subseq<?t> opt<nat>(a arr<char>, subseq arr<char>) */
struct opt_8 index_of_subseq(struct ctx* ctx, struct arr_0 a, struct arr_0 subseq) {
	return index_of_subseq_recur(ctx, a, subseq, 0u);
}
/* index-of-subseq-recur<?t> opt<nat>(a arr<char>, subseq arr<char>, i nat) */
struct opt_8 index_of_subseq_recur(struct ctx* ctx, struct arr_0 a, struct arr_0 subseq, uint64_t i) {
	top:;
	uint8_t _0 = _equal_0(i, a.size);
	if (_0) {
		return (struct opt_8) {0, .as0 = (struct none) {}};
	} else {
		struct arrow_0 _1 = _arrow_0(ctx, i, a.size);
		struct arr_0 _2 = subscript_25(ctx, a, _1);
		uint8_t _3 = starts_with__q(ctx, _2, subseq);
		if (_3) {
			return (struct opt_8) {1, .as1 = (struct some_8) {i}};
		} else {
			uint64_t _4 = incr_5(ctx, i);
			a = a;
			subseq = subseq;
			i = _4;
			goto top;
		}
	}
}
/* line-len nat(line arr<char>) */
uint64_t line_len(struct ctx* ctx, struct arr_0 line) {
	uint64_t _0 = n_tabs(ctx, line);
	uint64_t _1 = tab_size(ctx);
	uint64_t _2 = _minus_2(ctx, _1, 1u);
	uint64_t _3 = _times_0(ctx, _0, _2);
	return _plus(ctx, _3, line.size);
}
/* n-tabs nat(line arr<char>) */
uint64_t n_tabs(struct ctx* ctx, struct arr_0 line) {
	uint8_t _0 = empty__q_0(line);
	uint8_t _1 = not(_0);uint8_t _2;
	
	if (_1) {
		char _3 = first_2(ctx, line);
		_2 = _equal_3(_3, 9u);
	} else {
		_2 = 0;
	}
	if (_2) {
		struct arr_0 _4 = tail_3(ctx, line);
		uint64_t _5 = n_tabs(ctx, _4);
		return incr_5(ctx, _5);
	} else {
		return 0u;
	}
}
/* tab-size nat() */
uint64_t tab_size(struct ctx* ctx) {
	return 4u;
}
/* max-line-length nat() */
uint64_t max_line_length(struct ctx* ctx) {
	return 120u;
}
/* lint-file.lambda0 void(line arr<char>, line-num nat) */
struct void_ lint_file__lambda0(struct ctx* ctx, struct lint_file__lambda0* _closure, struct arr_0 line, uint64_t line_num) {
	struct arr_0 ln0;
	uint64_t _0 = incr_5(ctx, line_num);
	ln0 = to_str_4(ctx, _0);
	
	struct arr_0 space_space1;
	space_space1 = _concat_0(ctx, (struct arr_0) {1, constantarr_0_34}, (struct arr_0) {1, constantarr_0_34});
	
	uint8_t _1 = not(_closure->allow_double_space__q);uint8_t _2;
	
	if (_1) {
		_2 = contains_subseq__q(ctx, line, space_space1);
	} else {
		_2 = 0;
	}
	if (_2) {
		struct arr_0 message2;
		struct arr_0 _3 = _concat_0(ctx, (struct arr_0) {5, constantarr_0_90}, ln0);
		message2 = _concat_0(ctx, _3, (struct arr_0) {24, constantarr_0_91});
		
		struct failure* temp0;
		uint8_t* _4 = alloc(ctx, sizeof(struct failure));
		temp0 = (struct failure*) _4;
		
		*temp0 = (struct failure) {_closure->path, message2};
		_concatEquals_3(ctx, _closure->res, temp0);
	} else {
		(struct void_) {};
	}
	uint64_t width3;
	width3 = line_len(ctx, line);
	
	uint64_t _5 = max_line_length(ctx);
	uint8_t _6 = _greater(width3, _5);
	if (_6) {
		struct arr_0 message4;
		struct arr_0 _7 = _concat_0(ctx, (struct arr_0) {5, constantarr_0_90}, ln0);
		struct arr_0 _8 = _concat_0(ctx, _7, (struct arr_0) {4, constantarr_0_92});
		struct arr_0 _9 = to_str_4(ctx, width3);
		struct arr_0 _10 = _concat_0(ctx, _8, _9);
		struct arr_0 _11 = _concat_0(ctx, _10, (struct arr_0) {28, constantarr_0_93});
		uint64_t _12 = max_line_length(ctx);
		struct arr_0 _13 = to_str_4(ctx, _12);
		message4 = _concat_0(ctx, _11, _13);
		
		struct failure* temp1;
		uint8_t* _14 = alloc(ctx, sizeof(struct failure));
		temp1 = (struct failure*) _14;
		
		*temp1 = (struct failure) {_closure->path, message4};
		return _concatEquals_3(ctx, _closure->res, temp1);
	} else {
		return (struct void_) {};
	}
}
/* lint.lambda0 arr<failure>(file arr<char>) */
struct arr_8 lint__lambda0(struct ctx* ctx, struct lint__lambda0* _closure, struct arr_0 file) {
	uint8_t _0 = _closure->options.print_tests__q;
	if (_0) {
		struct arr_0 _1 = _concat_0(ctx, (struct arr_0) {5, constantarr_0_86}, file);
		print(_1);
	} else {
		(struct void_) {};
	}
	return lint_file(ctx, file);
}
/* do-test.lambda1 result<arr<char>, arr<failure>>() */
struct result_2 do_test__lambda1(struct ctx* ctx, struct do_test__lambda1* _closure) {
	return lint(ctx, _closure->crow_path, _closure->options);
}
/* print-failures nat(failures result<arr<char>, arr<failure>>, options test-options) */
uint64_t print_failures(struct ctx* ctx, struct result_2 failures, struct test_options options) {
	struct result_2 _0 = failures;
	switch (_0.kind) {
		case 0: {
			struct ok_2 o0 = _0.as0;
			
			print(o0.value);
			return 0u;
		}
		case 1: {
			struct err_1 e1 = _0.as1;
			
			each_2(ctx, e1.value, (struct fun_act1_14) {1, .as1 = (struct void_) {}});
			uint64_t n_failures2;
			n_failures2 = e1.value.size;
			
			uint8_t _1 = _equal_0(n_failures2, options.max_failures);struct arr_0 _2;
			
			if (_1) {
				struct arr_0 _3 = to_str_4(ctx, options.max_failures);
				struct arr_0 _4 = _concat_0(ctx, (struct arr_0) {15, constantarr_0_98}, _3);
				_2 = _concat_0(ctx, _4, (struct arr_0) {9, constantarr_0_99});
			} else {
				struct arr_0 _5 = to_str_4(ctx, n_failures2);
				_2 = _concat_0(ctx, _5, (struct arr_0) {9, constantarr_0_99});
			}
			print(_2);
			return n_failures2;
		}
		default:
			return 0;
	}
}
/* print-failure void(failure failure) */
struct void_ print_failure(struct ctx* ctx, struct failure* failure) {
	print_bold(ctx);
	print_no_newline(failure->path);
	print_reset(ctx);
	print_no_newline((struct arr_0) {1, constantarr_0_34});
	return print(failure->message);
}
/* print-bold void() */
struct void_ print_bold(struct ctx* ctx) {
	return print_no_newline((struct arr_0) {4, constantarr_0_96});
}
/* print-reset void() */
struct void_ print_reset(struct ctx* ctx) {
	return print_no_newline((struct arr_0) {3, constantarr_0_97});
}
/* print-failures.lambda0 void(it failure) */
struct void_ print_failures__lambda0(struct ctx* ctx, struct void_ _closure, struct failure* it) {
	return print_failure(ctx, it);
}
/* main (generated) (generated) */
int32_t main(int32_t argc, char** argv) {
	return rt_main(argc, argv, main_0);
}
