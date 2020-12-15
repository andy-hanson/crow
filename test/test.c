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
struct task;
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
struct fun_ref1;
struct then_0__lambda0;
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
struct some_4 {
	uint8_t* value;
};
struct map_0__lambda0;
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
struct some_11 {
	uint64_t value;
};
struct mut_dict_0;
struct mut_arr_2 {
	uint8_t frozen__q;
	uint64_t size;
	uint64_t capacity;
	struct arr_1* data;
};
struct some_12 {
	struct arr_0 value;
};
struct mut_arr_3;
struct fill_mut_arr__lambda0;
struct cell_2 {
	uint8_t value;
};
struct parse_cmd_line_args__lambda0 {
	struct arr_1 t_names;
	struct cell_2* help;
	struct mut_arr_3* values;
};
struct index_of__lambda0 {
	struct arr_0 value;
};
struct mut_arr_4 {
	uint8_t frozen__q;
	uint64_t size;
	uint64_t capacity;
	char* data;
};
struct _op_plus_1__lambda0 {
	struct arr_0 a;
	struct arr_0 b;
};
struct r_index_of__lambda0 {
	char value;
};
struct dict_1 {
	struct arr_1 keys;
	struct arr_1 values;
};
struct mut_dict_1 {
	struct mut_arr_1* keys;
	struct mut_arr_1* values;
};
struct key_value_pair {
	struct arr_0 key;
	struct arr_0 value;
};
struct failure {
	struct arr_0 path;
	struct arr_0 message;
};
struct arr_7 {
	uint64_t size;
	struct failure** data;
};
struct ok_3 {
	struct arr_0 value;
};
struct err_2 {
	struct arr_7 value;
};
struct first_failures__lambda0;
struct first_failures__lambda0__lambda0 {
	struct arr_0 a_descr;
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
struct some_13 {
	struct stat_t* value;
};
struct dirent;
struct bytes256;
struct cell_3 {
	struct dirent* value;
};
struct to_mut_arr__lambda0 {
	struct arr_1 a;
};
struct mut_slice {
	struct mut_arr_1* backing;
	uint64_t size;
	uint64_t begin;
};
struct each_child_recursive__lambda0;
struct list_tests__lambda1 {
	struct mut_arr_1* res;
};
struct mut_arr_5 {
	uint8_t frozen__q;
	uint64_t size;
	uint64_t capacity;
	struct failure** data;
};
struct flat_map_with_max_size__lambda0;
struct push_all__lambda0 {
	struct mut_arr_5* a;
};
struct run_noze_tests__lambda0 {
	struct arr_0 path_to_noze;
	struct dict_1* env;
	struct test_options options;
};
struct some_14 {
	struct arr_7 value;
};
struct run_single_noze_test__lambda0 {
	struct test_options options;
	struct arr_0 path;
	struct arr_0 path_to_noze;
	struct dict_1* env;
};
struct print_test_result {
	uint8_t should_stop__q;
	struct arr_7 failures;
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
struct cell_4 {
	int32_t value;
};
struct pollfd {
	int32_t fd;
	int16_t events;
	int16_t revents;
};
struct arr_8 {
	uint64_t size;
	struct pollfd* data;
};
struct handle_revents_result {
	uint8_t had_pollin__q;
	uint8_t hung_up__q;
};
struct mut_arr_6 {
	uint8_t frozen__q;
	uint64_t size;
	uint64_t capacity;
	char** data;
};
struct _op_plus_2__lambda0 {
	struct arr_3 a;
	struct arr_3 b;
};
struct map_1__lambda0;
struct convert_environ__lambda0 {
	struct mut_arr_6* res;
};
struct do_test__lambda0 {
	struct arr_0 test_path;
	struct arr_0 noze_exe;
	struct dict_1* env;
	struct test_options options;
};
struct do_test__lambda0__lambda0 {
	struct arr_0 test_path;
	struct arr_0 noze_exe;
	struct dict_1* env;
	struct test_options options;
};
struct do_test__lambda1 {
	struct arr_0 noze_path;
	struct test_options options;
};
struct excluded_from_lint__q__lambda0 {
	struct arr_0 name;
};
struct list_lintable_files__lambda1 {
	struct mut_arr_1* res;
};
struct lint__lambda0 {
	struct test_options options;
};
struct lines__lambda0 {
	struct mut_arr_1* res;
	struct arr_0 s;
	struct cell_0* last_nl;
};
struct lint_file__lambda0 {
	uint8_t err_file__q;
	struct mut_arr_5* res;
	struct arr_0 path;
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
struct fun_mut1_0 {
	int kind;
	union {
		struct forward_to__lambda0* as0;
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
struct fun_mut0_0 {
	int kind;
	union {
		struct call_ref_0__lambda0__lambda0* as0;
		struct call_ref_0__lambda0* as1;
		struct call_ref_1__lambda0__lambda0* as2;
		struct call_ref_1__lambda0* as3;
	};
};
struct opt_2 {
	int kind;
	union {
		struct none as0;
		struct some_2 as1;
	};
};
struct fun_mut1_1 {
	int kind;
	union {
		uint8_t as0;
		struct call_ref_0__lambda0__lambda1* as1;
		struct call_ref_1__lambda0__lambda1* as2;
	};
};
struct fun2 {
	int kind;
	union {
		uint8_t as0;
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
struct fun_mut1_2 {
	int kind;
	union {
		struct then_0__lambda0* as0;
	};
};
struct opt_3 {
	int kind;
	union {
		struct none as0;
		struct some_3 as1;
	};
};
struct fun_mut0_1 {
	int kind;
	union {
		struct add_first_task__lambda0* as0;
	};
};
struct fun_mut1_3 {
	int kind;
	union {
		struct then2__lambda0* as0;
	};
};
struct fun_mut1_4 {
	int kind;
	union {
		uint8_t as0;
	};
};
struct fun_mut1_5 {
	int kind;
	union {
		struct map_0__lambda0* as0;
		struct to_mut_arr__lambda0* as1;
	};
};
struct opt_4 {
	int kind;
	union {
		struct none as0;
		struct some_4 as1;
	};
};
struct opt_5;
struct result_2;
struct opt_6;
struct opt_7;
struct opt_8;
struct opt_9 {
	int kind;
	union {
		struct none as0;
		struct some_9 as1;
	};
};
struct opt_10 {
	int kind;
	union {
		struct none as0;
		struct some_10 as1;
	};
};
struct fun1 {
	int kind;
	union {
		uint8_t as0;
	};
};
struct opt_11 {
	int kind;
	union {
		struct none as0;
		struct some_11 as1;
	};
};
struct fun_mut1_6 {
	int kind;
	union {
		uint8_t as0;
		uint8_t as1;
		uint8_t as2;
		struct index_of__lambda0* as3;
		uint8_t as4;
		struct excluded_from_lint__q__lambda0* as5;
		uint8_t as6;
	};
};
struct opt_12 {
	int kind;
	union {
		struct none as0;
		struct some_12 as1;
	};
};
struct fun_mut1_7 {
	int kind;
	union {
		struct fill_mut_arr__lambda0* as0;
	};
};
struct fun_mut2_0 {
	int kind;
	union {
		struct parse_cmd_line_args__lambda0* as0;
	};
};
struct fun_mut1_8 {
	int kind;
	union {
		struct _op_plus_1__lambda0* as0;
	};
};
struct fun_mut1_9 {
	int kind;
	union {
		struct r_index_of__lambda0* as0;
	};
};
struct result_3 {
	int kind;
	union {
		struct ok_3 as0;
		struct err_2 as1;
	};
};
struct fun0 {
	int kind;
	union {
		struct do_test__lambda0__lambda0* as0;
		struct do_test__lambda0* as1;
		struct do_test__lambda1* as2;
	};
};
struct fun_mut1_10 {
	int kind;
	union {
		struct first_failures__lambda0__lambda0* as0;
		struct first_failures__lambda0* as1;
	};
};
struct fun_mut1_11 {
	int kind;
	union {
		struct each_child_recursive__lambda0* as0;
		struct list_tests__lambda1* as1;
		struct flat_map_with_max_size__lambda0* as2;
		struct list_lintable_files__lambda1* as3;
	};
};
struct opt_13 {
	int kind;
	union {
		struct none as0;
		struct some_13 as1;
	};
};
struct fun_mut1_12 {
	int kind;
	union {
		struct run_noze_tests__lambda0* as0;
		struct lint__lambda0* as1;
	};
};
struct fun_mut1_13 {
	int kind;
	union {
		struct push_all__lambda0* as0;
		uint8_t as1;
	};
};
struct opt_14 {
	int kind;
	union {
		struct none as0;
		struct some_14 as1;
	};
};
struct fun_mut1_14 {
	int kind;
	union {
		struct run_single_noze_test__lambda0* as0;
	};
};
struct fun_mut2_1 {
	int kind;
	union {
		uint8_t as0;
	};
};
struct fun_mut1_15 {
	int kind;
	union {
		struct _op_plus_2__lambda0* as0;
		struct map_1__lambda0* as1;
	};
};
struct fun_mut1_16 {
	int kind;
	union {
		uint8_t as0;
	};
};
struct fun_mut2_2 {
	int kind;
	union {
		struct convert_environ__lambda0* as0;
	};
};
struct fun_mut2_3 {
	int kind;
	union {
		struct lint_file__lambda0* as0;
	};
};
struct fun_mut2_4 {
	int kind;
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
	struct fun_mut1_0 cb;
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
	struct fun_mut1_2 cb;
	struct opt_3 next_node;
};
struct fun_ref0 {
	struct island_and_exclusion island_and_exclusion;
	struct fun_mut0_1 fun;
};
struct fun_ref1 {
	struct island_and_exclusion island_and_exclusion;
	struct fun_mut1_3 fun;
};
struct then_0__lambda0 {
	struct fun_ref1 cb;
	struct fut_0* res;
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
struct map_0__lambda0 {
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
	struct arr_1 keys;
	struct arr_6 values;
};
struct mut_dict_0 {
	struct mut_arr_1* keys;
	struct mut_arr_2* values;
};
struct mut_arr_3 {
	uint8_t frozen__q;
	uint64_t size;
	uint64_t capacity;
	struct opt_10* data;
};
struct fill_mut_arr__lambda0 {
	struct opt_10 value;
};
struct first_failures__lambda0 {
	struct fun0 b;
};
struct dirent;
struct bytes256;
struct each_child_recursive__lambda0 {
	struct fun_mut1_6 filter;
	struct arr_0 path;
	struct fun_mut1_11 f;
};
struct flat_map_with_max_size__lambda0 {
	struct mut_arr_5* res;
	uint64_t max_size;
	struct fun_mut1_12 mapper;
};
struct posix_spawn_file_actions_t;
struct map_1__lambda0 {
	struct fun_mut1_16 mapper;
	struct arr_1 a;
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
	struct fun_mut1_1 exception_handler;
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
struct dirent {
	uint64_t d_ino;
	int64_t d_off;
	uint16_t d_reclen;
	char d_type;
	struct bytes256 d_name;
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
char constantarr_0_12[11];
char constantarr_0_13[16];
char constantarr_0_14[12];
char constantarr_0_15[2];
char constantarr_0_16[27];
char constantarr_0_17[26];
char constantarr_0_18[4];
char constantarr_0_19[15];
char constantarr_0_20[18];
char constantarr_0_21[8];
char constantarr_0_22[38];
char constantarr_0_23[64];
char constantarr_0_24[1];
char constantarr_0_25[14];
char constantarr_0_26[1];
char constantarr_0_27[3];
char constantarr_0_28[4];
char constantarr_0_29[1];
char constantarr_0_30[2];
char constantarr_0_31[2];
char constantarr_0_32[3];
char constantarr_0_33[5];
char constantarr_0_34[14];
char constantarr_0_35[9];
char constantarr_0_36[11];
char constantarr_0_37[1];
char constantarr_0_38[23];
char constantarr_0_39[31];
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
char constantarr_0_51[12];
char constantarr_0_52[1];
char constantarr_0_53[14];
char constantarr_0_54[5];
char constantarr_0_55[5];
char constantarr_0_56[20];
char constantarr_0_57[31];
char constantarr_0_58[7];
char constantarr_0_59[7];
char constantarr_0_60[12];
char constantarr_0_61[29];
char constantarr_0_62[30];
char constantarr_0_63[4];
char constantarr_0_64[22];
char constantarr_0_65[9];
char constantarr_0_66[3];
char constantarr_0_67[11];
char constantarr_0_68[7];
char constantarr_0_69[8];
char constantarr_0_70[9];
char constantarr_0_71[8];
char constantarr_0_72[4];
char constantarr_0_73[10];
char constantarr_0_74[12];
char constantarr_0_75[14];
char constantarr_0_76[8];
char constantarr_0_77[4];
char constantarr_0_78[4];
char constantarr_0_79[5];
char constantarr_0_80[7];
char constantarr_0_81[7];
char constantarr_0_82[12];
char constantarr_0_83[17];
char constantarr_0_84[1];
char constantarr_0_85[4];
char constantarr_0_86[1];
char constantarr_0_87[3];
char constantarr_0_88[4];
char constantarr_0_89[10];
char constantarr_0_90[5];
char constantarr_0_91[21];
char constantarr_0_92[3];
char constantarr_0_93[2];
char constantarr_0_94[5];
char constantarr_0_95[24];
char constantarr_0_96[4];
char constantarr_0_97[28];
char constantarr_0_98[7];
char constantarr_0_99[6];
char constantarr_0_100[4];
char constantarr_0_101[3];
char constantarr_0_102[15];
char constantarr_0_103[9];
struct arr_0 constantarr_1_0[3];
struct arr_0 constantarr_1_1[4];
struct arr_0 constantarr_1_2[5];
struct arr_0 constantarr_1_3[4];
struct arr_0 constantarr_1_4[6];
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
char constantarr_0_12[11] = "print-tests";
char constantarr_0_13[16] = "overwrite-output";
char constantarr_0_14[12] = "max-failures";
char constantarr_0_15[2] = "--";
char constantarr_0_16[27] = "tried to force empty option";
char constantarr_0_17[26] = "Should be no nameless args";
char constantarr_0_18[4] = "help";
char constantarr_0_19[15] = "Unexpected arg ";
char constantarr_0_20[18] = "test -- runs tests";
char constantarr_0_21[8] = "options:";
char constantarr_0_22[38] = "\t--print-tests  : print every test run";
char constantarr_0_23[64] = "\t--max-failures : stop after this many failures. Defaults to 10.";
char constantarr_0_24[1] = "\0";
char constantarr_0_25[14] = "/proc/self/exe";
char constantarr_0_26[1] = "/";
char constantarr_0_27[3] = "bin";
char constantarr_0_28[4] = "noze";
char constantarr_0_29[1] = ".";
char constantarr_0_30[2] = "..";
char constantarr_0_31[2] = "nz";
char constantarr_0_32[3] = "ast";
char constantarr_0_33[5] = "model";
char constantarr_0_34[14] = "concrete-model";
char constantarr_0_35[9] = "low-model";
char constantarr_0_36[11] = "noze print ";
char constantarr_0_37[1] = " ";
char constantarr_0_38[23] = "spawn-and-wait-result: ";
char constantarr_0_39[31] = "Process terminated with signal ";
char constantarr_0_40[1] = "0";
char constantarr_0_41[1] = "1";
char constantarr_0_42[1] = "2";
char constantarr_0_43[1] = "3";
char constantarr_0_44[1] = "4";
char constantarr_0_45[1] = "5";
char constantarr_0_46[1] = "6";
char constantarr_0_47[1] = "7";
char constantarr_0_48[1] = "8";
char constantarr_0_49[1] = "9";
char constantarr_0_50[1] = "-";
char constantarr_0_51[12] = "WAIT STOPPED";
char constantarr_0_52[1] = "=";
char constantarr_0_53[14] = " is not a file";
char constantarr_0_54[5] = "print";
char constantarr_0_55[5] = ".tata";
char constantarr_0_56[20] = "failed to open file ";
char constantarr_0_57[31] = "failed to open file for write: ";
char constantarr_0_58[7] = "errno: ";
char constantarr_0_59[7] = "flags: ";
char constantarr_0_60[12] = "permission: ";
char constantarr_0_61[29] = " does not exist. actual was:\n";
char constantarr_0_62[30] = " was not as expected. actual:\n";
char constantarr_0_63[4] = ".err";
char constantarr_0_64[22] = "unexpected exit code: ";
char constantarr_0_65[9] = "noze run ";
char constantarr_0_66[3] = "run";
char constantarr_0_67[11] = "--interpret";
char constantarr_0_68[7] = ".stdout";
char constantarr_0_69[8] = "status: ";
char constantarr_0_70[9] = "\nstdout:\n";
char constantarr_0_71[8] = "stderr:\n";
char constantarr_0_72[4] = "ran ";
char constantarr_0_73[10] = " tests in ";
char constantarr_0_74[12] = "parse-errors";
char constantarr_0_75[14] = "compile-errors";
char constantarr_0_76[8] = "runnable";
char constantarr_0_77[4] = ".bmp";
char constantarr_0_78[4] = ".png";
char constantarr_0_79[5] = ".wasm";
char constantarr_0_80[7] = "dyncall";
char constantarr_0_81[7] = "libfirm";
char constantarr_0_82[12] = "node_modules";
char constantarr_0_83[17] = "package-lock.json";
char constantarr_0_84[1] = "c";
char constantarr_0_85[4] = "data";
char constantarr_0_86[1] = "o";
char constantarr_0_87[3] = "out";
char constantarr_0_88[4] = "tata";
char constantarr_0_89[10] = "tmLanguage";
char constantarr_0_90[5] = "lint ";
char constantarr_0_91[21] = "file does not exist: ";
char constantarr_0_92[3] = "err";
char constantarr_0_93[2] = "  ";
char constantarr_0_94[5] = "line ";
char constantarr_0_95[24] = " contains a double space";
char constantarr_0_96[4] = " is ";
char constantarr_0_97[28] = " columns long, should be <= ";
char constantarr_0_98[7] = "linted ";
char constantarr_0_99[6] = " files";
char constantarr_0_100[4] = "\x1b[1m";
char constantarr_0_101[3] = "\x1b[m";
char constantarr_0_102[15] = "hit maximum of ";
char constantarr_0_103[9] = " failures";
struct arr_0 constantarr_1_0[3] = {{11, constantarr_0_12}, {16, constantarr_0_13}, {12, constantarr_0_14}};
struct arr_0 constantarr_1_1[4] = {{3, constantarr_0_32}, {5, constantarr_0_33}, {14, constantarr_0_34}, {9, constantarr_0_35}};
struct arr_0 constantarr_1_2[5] = {{4, constantarr_0_77}, {4, constantarr_0_63}, {4, constantarr_0_78}, {5, constantarr_0_55}, {5, constantarr_0_79}};
struct arr_0 constantarr_1_3[4] = {{7, constantarr_0_80}, {7, constantarr_0_81}, {12, constantarr_0_82}, {17, constantarr_0_83}};
struct arr_0 constantarr_1_4[6] = {{1, constantarr_0_84}, {4, constantarr_0_85}, {1, constantarr_0_86}, {3, constantarr_0_87}, {4, constantarr_0_88}, {10, constantarr_0_89}};
uint8_t mark(struct mark_ctx* ctx, uint8_t* ptr_any, uint64_t size_bytes);
uint64_t words_of_bytes(uint64_t size_bytes);
uint64_t round_up_to_multiple_of_8(uint64_t n);
uint8_t hard_assert(uint8_t condition);
uint8_t _op_equal_equal_0(uint64_t a, uint64_t b);
struct comparison compare_5(uint64_t a, uint64_t b);
uint64_t _op_minus_0(uint64_t* a, uint64_t* b);
uint8_t _op_less_0(uint64_t a, uint64_t b);
uint8_t _op_less_equal(uint64_t a, uint64_t b);
uint8_t mark_range_recur(uint8_t* p, uint64_t size);
uint8_t _op_bang_equal_0(uint64_t a, uint64_t b);
uint8_t* incr_0(uint8_t* p);
uint64_t noctx_decr(uint64_t n);
uint8_t hard_forbid(uint8_t condition);
int32_t rt_main(int32_t argc, char** argv, fun_ptr2 main_ptr);
uint8_t drop_0(struct arr_0 t);
struct arr_0 to_str_0(char* a);
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
struct arr_2 empty_arr_0(void);
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
uint8_t new_island__lambda0(struct ctx* ctx, uint8_t _closure, struct exception it);
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
struct fut_0* then_0(struct ctx* ctx, struct fut_1* f, struct fun_ref1 cb);
struct fut_0* new_unresolved_fut(struct ctx* ctx);
uint8_t then_void_0(struct ctx* ctx, struct fut_1* f, struct fun_mut1_2 cb);
uint8_t call_0(struct ctx* ctx, struct fun_mut1_2 a, struct result_1 p0);
uint8_t call_w_ctx_78(struct fun_mut1_2 a, struct ctx* ctx, struct result_1 p0);
uint8_t forward_to(struct ctx* ctx, struct fut_0* from, struct fut_0* to);
uint8_t then_void_1(struct ctx* ctx, struct fut_0* f, struct fun_mut1_0 cb);
uint8_t call_1(struct ctx* ctx, struct fun_mut1_0 a, struct result_0 p0);
uint8_t call_w_ctx_82(struct fun_mut1_0 a, struct ctx* ctx, struct result_0 p0);
uint8_t resolve_or_reject(struct ctx* ctx, struct fut_0* f, struct result_0 result);
uint8_t resolve_or_reject_recur(struct ctx* ctx, struct opt_0 node, struct result_0 value);
uint8_t drop_1(uint8_t t);
uint8_t forward_to__lambda0(struct ctx* ctx, struct forward_to__lambda0* _closure, struct result_0 it);
struct fut_0* call_ref_0(struct ctx* ctx, struct fun_ref1 f, uint8_t p0);
struct island* get_island(struct ctx* ctx, uint64_t island_id);
struct island* at_0(struct ctx* ctx, struct arr_2 a, uint64_t index);
uint8_t assert_0(struct ctx* ctx, uint8_t condition);
uint8_t assert_1(struct ctx* ctx, uint8_t condition, struct arr_0 message);
uint8_t fail_0(struct ctx* ctx, struct arr_0 reason);
uint8_t throw_0(struct ctx* ctx, struct exception e);
struct exception_ctx* get_exception_ctx(struct ctx* ctx);
uint8_t null__q_1(struct jmp_buf_tag* a);
extern void longjmp(struct jmp_buf_tag* env, int32_t val);
int32_t number_to_throw(struct ctx* ctx);
struct island* noctx_at_0(struct arr_2 a, uint64_t index);
uint8_t add_task(struct ctx* ctx, struct island* a, struct task t);
struct mut_bag_node* new_mut_bag_node(struct ctx* ctx, struct task value);
uint8_t add_0(struct mut_bag* bag, struct mut_bag_node* node);
struct mut_bag* tasks(struct island* a);
uint8_t broadcast(struct condition* c);
uint8_t catch(struct ctx* ctx, struct fun_mut0_0 try, struct fun_mut1_1 catcher);
uint8_t catch_with_exception_ctx(struct ctx* ctx, struct exception_ctx* ec, struct fun_mut0_0 try, struct fun_mut1_1 catcher);
struct bytes64 zero_0(void);
struct bytes32 zero_1(void);
struct bytes16 zero_2(void);
struct bytes128 zero_3(void);
extern int32_t setjmp(struct jmp_buf_tag* env);
uint8_t call_2(struct ctx* ctx, struct fun_mut0_0 a);
uint8_t call_w_ctx_112(struct fun_mut0_0 a, struct ctx* ctx);
uint8_t call_3(struct ctx* ctx, struct fun_mut1_1 a, struct exception p0);
uint8_t call_w_ctx_114(struct fun_mut1_1 a, struct ctx* ctx, struct exception p0);
struct fut_0* call_4(struct ctx* ctx, struct fun_mut1_3 a, uint8_t p0);
struct fut_0* call_w_ctx_116(struct fun_mut1_3 a, struct ctx* ctx, uint8_t p0);
uint8_t call_ref_0__lambda0__lambda0(struct ctx* ctx, struct call_ref_0__lambda0__lambda0* _closure);
uint8_t reject(struct ctx* ctx, struct fut_0* f, struct exception e);
uint8_t call_ref_0__lambda0__lambda1(struct ctx* ctx, struct call_ref_0__lambda0__lambda1* _closure, struct exception it);
uint8_t call_ref_0__lambda0(struct ctx* ctx, struct call_ref_0__lambda0* _closure);
uint8_t then_0__lambda0(struct ctx* ctx, struct then_0__lambda0* _closure, struct result_1 result);
struct fut_0* call_ref_1(struct ctx* ctx, struct fun_ref0 f);
struct fut_0* call_5(struct ctx* ctx, struct fun_mut0_1 a);
struct fut_0* call_w_ctx_124(struct fun_mut0_1 a, struct ctx* ctx);
uint8_t call_ref_1__lambda0__lambda0(struct ctx* ctx, struct call_ref_1__lambda0__lambda0* _closure);
uint8_t call_ref_1__lambda0__lambda1(struct ctx* ctx, struct call_ref_1__lambda0__lambda1* _closure, struct exception it);
uint8_t call_ref_1__lambda0(struct ctx* ctx, struct call_ref_1__lambda0* _closure);
struct fut_0* then2__lambda0(struct ctx* ctx, struct then2__lambda0* _closure, uint8_t ignore);
struct island_and_exclusion cur_island_and_exclusion(struct ctx* ctx);
struct fut_1* delay(struct ctx* ctx);
struct fut_1* resolved_0(struct ctx* ctx, uint8_t value);
struct arr_3 tail_0(struct ctx* ctx, struct arr_3 a);
uint8_t forbid_0(struct ctx* ctx, uint8_t condition);
uint8_t forbid_1(struct ctx* ctx, uint8_t condition, struct arr_0 message);
uint8_t empty__q_1(struct arr_3 a);
struct arr_3 slice_starting_at_0(struct ctx* ctx, struct arr_3 a, uint64_t begin);
struct arr_3 slice_0(struct ctx* ctx, struct arr_3 a, uint64_t begin, uint64_t size);
uint64_t _op_plus_0(struct ctx* ctx, uint64_t a, uint64_t b);
uint8_t _op_greater_equal(uint64_t a, uint64_t b);
uint64_t _op_minus_2(struct ctx* ctx, uint64_t a, uint64_t b);
struct arr_1 map_0(struct ctx* ctx, struct arr_3 a, struct fun_mut1_4 mapper);
struct arr_1 make_arr_0(struct ctx* ctx, uint64_t size, struct fun_mut1_5 f);
struct arr_1 freeze_0(struct mut_arr_1* a);
struct arr_1 unsafe_as_arr_0(struct mut_arr_1* a);
struct mut_arr_1* make_mut_arr_0(struct ctx* ctx, uint64_t size, struct fun_mut1_5 f);
struct mut_arr_1* new_uninitialized_mut_arr_0(struct ctx* ctx, uint64_t size);
struct arr_0* uninitialized_data_0(struct ctx* ctx, uint64_t size);
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
uint8_t make_mut_arr_worker_0(struct ctx* ctx, struct mut_arr_1* m, uint64_t i, struct fun_mut1_5 f);
uint8_t set_at_0(struct ctx* ctx, struct mut_arr_1* a, uint64_t index, struct arr_0 value);
uint8_t noctx_set_at_0(struct mut_arr_1* a, uint64_t index, struct arr_0 value);
struct arr_0 call_6(struct ctx* ctx, struct fun_mut1_5 a, uint64_t p0);
struct arr_0 call_w_ctx_164(struct fun_mut1_5 a, struct ctx* ctx, uint64_t p0);
uint64_t incr_3(struct ctx* ctx, uint64_t n);
struct arr_0 call_7(struct ctx* ctx, struct fun_mut1_4 a, char* p0);
struct arr_0 call_w_ctx_167(struct fun_mut1_4 a, struct ctx* ctx, char* p0);
char* at_1(struct ctx* ctx, struct arr_3 a, uint64_t index);
char* noctx_at_1(struct arr_3 a, uint64_t index);
struct arr_0 map_0__lambda0(struct ctx* ctx, struct map_0__lambda0* _closure, uint64_t i);
struct arr_0 add_first_task__lambda0__lambda0(struct ctx* ctx, uint8_t _closure, char* it);
struct fut_0* add_first_task__lambda0(struct ctx* ctx, struct add_first_task__lambda0* _closure);
struct fut_0* do_main__lambda0(struct ctx* ctx, uint8_t _closure, struct arr_3 all_args, fun_ptr2 main_ptr);
struct fut_0* call_w_ctx_174(struct fun2 a, struct ctx* ctx, struct arr_3 p0, fun_ptr2 p1);
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
uint8_t contains__q_0(struct mut_arr_0* a, uint64_t value);
uint8_t contains_recur__q_0(struct arr_4 a, uint64_t value, uint64_t i);
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
uint8_t* get_0(struct cell_1* c);
uint8_t unmanaged_free_0(uint64_t* p);
extern void free(uint8_t* p);
uint8_t unmanaged_free_1(struct thread_args* p);
struct result_0 must_be_resolved(struct fut_0* f);
struct result_0 hard_unreachable_0(void);
struct fut_0* main_0(struct ctx* ctx, struct arr_1 args);
struct opt_9 parse_cmd_line_args(struct ctx* ctx, struct arr_1 args, struct arr_1 t_names, struct fun1 make_t);
struct parsed_cmd_line_args* parse_cmd_line_args_dynamic(struct ctx* ctx, struct arr_1 args);
struct opt_11 find_index(struct ctx* ctx, struct arr_1 a, struct fun_mut1_6 pred);
struct opt_11 find_index_recur(struct ctx* ctx, struct arr_1 a, uint64_t index, struct fun_mut1_6 pred);
uint8_t call_8(struct ctx* ctx, struct fun_mut1_6 a, struct arr_0 p0);
uint8_t call_w_ctx_231(struct fun_mut1_6 a, struct ctx* ctx, struct arr_0 p0);
struct arr_0 at_2(struct ctx* ctx, struct arr_1 a, uint64_t index);
struct arr_0 noctx_at_4(struct arr_1 a, uint64_t index);
uint8_t starts_with__q(struct ctx* ctx, struct arr_0 a, struct arr_0 start);
uint8_t arr_eq__q(struct ctx* ctx, struct arr_0 a, struct arr_0 b);
char first_0(struct ctx* ctx, struct arr_0 a);
char at_3(struct ctx* ctx, struct arr_0 a, uint64_t index);
char noctx_at_5(struct arr_0 a, uint64_t index);
struct arr_0 tail_1(struct ctx* ctx, struct arr_0 a);
struct arr_0 slice_starting_at_1(struct ctx* ctx, struct arr_0 a, uint64_t begin);
struct arr_0 slice_1(struct ctx* ctx, struct arr_0 a, uint64_t begin, uint64_t size);
uint8_t parse_cmd_line_args_dynamic__lambda0(struct ctx* ctx, uint8_t _closure, struct arr_0 it);
struct dict_0* empty_dict(struct ctx* ctx);
struct arr_1 empty_arr_1(void);
struct arr_6 empty_arr_2(void);
struct arr_1 slice_up_to_0(struct ctx* ctx, struct arr_1 a, uint64_t size);
struct arr_1 slice_2(struct ctx* ctx, struct arr_1 a, uint64_t begin, uint64_t size);
struct arr_1 slice_starting_at_2(struct ctx* ctx, struct arr_1 a, uint64_t begin);
uint8_t _op_equal_equal_4(struct arr_0 a, struct arr_0 b);
struct comparison compare_250(struct arr_0 a, struct arr_0 b);
uint8_t parse_cmd_line_args_dynamic__lambda1(struct ctx* ctx, uint8_t _closure, struct arr_0 it);
struct dict_0* parse_named_args(struct ctx* ctx, struct arr_1 args);
struct mut_dict_0 new_mut_dict_0(struct ctx* ctx);
struct mut_arr_1* new_mut_arr_0(struct ctx* ctx);
struct mut_arr_2* new_mut_arr_1(struct ctx* ctx);
uint8_t parse_named_args_recur(struct ctx* ctx, struct arr_1 args, struct mut_dict_0 builder);
struct arr_0 remove_start(struct ctx* ctx, struct arr_0 a, struct arr_0 start);
struct arr_0 force_0(struct ctx* ctx, struct opt_12 a);
struct arr_0 fail_1(struct ctx* ctx, struct arr_0 reason);
struct arr_0 throw_1(struct ctx* ctx, struct exception e);
struct arr_0 todo_3(void);
struct opt_12 try_remove_start(struct ctx* ctx, struct arr_0 a, struct arr_0 start);
struct arr_0 first_1(struct ctx* ctx, struct arr_1 a);
uint8_t empty__q_6(struct arr_1 a);
struct arr_1 tail_2(struct ctx* ctx, struct arr_1 a);
uint8_t parse_named_args_recur__lambda0(struct ctx* ctx, uint8_t _closure, struct arr_0 it);
uint8_t add_1(struct ctx* ctx, struct mut_dict_0 m, struct arr_0 key, struct arr_1 value);
uint8_t has__q_0(struct ctx* ctx, struct mut_dict_0 d, struct arr_0 key);
uint8_t has__q_1(struct ctx* ctx, struct dict_0* d, struct arr_0 key);
uint8_t has__q_2(struct opt_10 a);
uint8_t empty__q_7(struct opt_10 a);
struct opt_10 get_1(struct ctx* ctx, struct dict_0* d, struct arr_0 key);
struct opt_10 get_recursive_0(struct ctx* ctx, struct arr_1 keys, struct arr_6 values, uint64_t idx, struct arr_0 key);
struct arr_1 at_4(struct ctx* ctx, struct arr_6 a, uint64_t index);
struct arr_1 noctx_at_6(struct arr_6 a, uint64_t index);
struct dict_0* unsafe_as_dict_0(struct ctx* ctx, struct mut_dict_0 m);
struct arr_6 unsafe_as_arr_1(struct mut_arr_2* a);
uint8_t push_0(struct ctx* ctx, struct mut_arr_1* a, struct arr_0 value);
uint8_t increase_capacity_to_0(struct ctx* ctx, struct mut_arr_1* a, uint64_t new_capacity);
uint8_t copy_data_from_0(struct ctx* ctx, struct arr_0* to, struct arr_0* from, uint64_t len);
uint8_t copy_data_from_small_0(struct ctx* ctx, struct arr_0* to, struct arr_0* from, uint64_t len);
struct arr_0* incr_4(struct arr_0* p);
uint64_t decr(struct ctx* ctx, uint64_t a);
uint64_t wrap_decr(uint64_t a);
uint64_t _op_div(struct ctx* ctx, uint64_t a, uint64_t b);
uint64_t _op_times_0(struct ctx* ctx, uint64_t a, uint64_t b);
uint8_t ensure_capacity_0(struct ctx* ctx, struct mut_arr_1* a, uint64_t capacity);
uint64_t round_up_to_power_of_two(struct ctx* ctx, uint64_t n);
uint64_t round_up_to_power_of_two_recur(struct ctx* ctx, uint64_t acc, uint64_t n);
uint8_t push_1(struct ctx* ctx, struct mut_arr_2* a, struct arr_1 value);
uint8_t increase_capacity_to_1(struct ctx* ctx, struct mut_arr_2* a, uint64_t new_capacity);
struct arr_1* uninitialized_data_1(struct ctx* ctx, uint64_t size);
uint8_t copy_data_from_1(struct ctx* ctx, struct arr_1* to, struct arr_1* from, uint64_t len);
uint8_t copy_data_from_small_1(struct ctx* ctx, struct arr_1* to, struct arr_1* from, uint64_t len);
struct arr_1* incr_5(struct arr_1* p);
uint8_t ensure_capacity_1(struct ctx* ctx, struct mut_arr_2* a, uint64_t capacity);
struct dict_0* freeze_1(struct ctx* ctx, struct mut_dict_0 m);
struct arr_6 freeze_2(struct mut_arr_2* a);
struct arr_1 slice_after_0(struct ctx* ctx, struct arr_1 a, uint64_t before_begin);
struct mut_arr_3* fill_mut_arr(struct ctx* ctx, uint64_t size, struct opt_10 value);
struct mut_arr_3* make_mut_arr_1(struct ctx* ctx, uint64_t size, struct fun_mut1_7 f);
struct mut_arr_3* new_uninitialized_mut_arr_1(struct ctx* ctx, uint64_t size);
struct opt_10* uninitialized_data_2(struct ctx* ctx, uint64_t size);
uint8_t make_mut_arr_worker_1(struct ctx* ctx, struct mut_arr_3* m, uint64_t i, struct fun_mut1_7 f);
uint8_t set_at_1(struct ctx* ctx, struct mut_arr_3* a, uint64_t index, struct opt_10 value);
uint8_t noctx_set_at_2(struct mut_arr_3* a, uint64_t index, struct opt_10 value);
struct opt_10 call_9(struct ctx* ctx, struct fun_mut1_7 a, uint64_t p0);
struct opt_10 call_w_ctx_308(struct fun_mut1_7 a, struct ctx* ctx, uint64_t p0);
struct opt_10 fill_mut_arr__lambda0(struct ctx* ctx, struct fill_mut_arr__lambda0* _closure, uint64_t ignore);
uint8_t each_0(struct ctx* ctx, struct dict_0* d, struct fun_mut2_0 f);
uint8_t empty__q_8(struct ctx* ctx, struct dict_0* d);
uint8_t call_10(struct ctx* ctx, struct fun_mut2_0 a, struct arr_0 p0, struct arr_1 p1);
uint8_t call_w_ctx_313(struct fun_mut2_0 a, struct ctx* ctx, struct arr_0 p0, struct arr_1 p1);
struct arr_1 first_2(struct ctx* ctx, struct arr_6 a);
uint8_t empty__q_9(struct arr_6 a);
struct arr_6 tail_3(struct ctx* ctx, struct arr_6 a);
struct arr_6 slice_starting_at_3(struct ctx* ctx, struct arr_6 a, uint64_t begin);
struct arr_6 slice_3(struct ctx* ctx, struct arr_6 a, uint64_t begin, uint64_t size);
struct opt_11 index_of(struct ctx* ctx, struct arr_1 a, struct arr_0 value);
uint8_t index_of__lambda0(struct ctx* ctx, struct index_of__lambda0* _closure, struct arr_0 it);
uint8_t set_0(struct cell_2* c, uint8_t v);
struct arr_0 _op_plus_1(struct ctx* ctx, struct arr_0 a, struct arr_0 b);
struct arr_0 make_arr_1(struct ctx* ctx, uint64_t size, struct fun_mut1_8 f);
struct arr_0 freeze_3(struct mut_arr_4* a);
struct arr_0 unsafe_as_arr_2(struct mut_arr_4* a);
struct mut_arr_4* make_mut_arr_2(struct ctx* ctx, uint64_t size, struct fun_mut1_8 f);
struct mut_arr_4* new_uninitialized_mut_arr_2(struct ctx* ctx, uint64_t size);
char* uninitialized_data_3(struct ctx* ctx, uint64_t size);
uint8_t make_mut_arr_worker_2(struct ctx* ctx, struct mut_arr_4* m, uint64_t i, struct fun_mut1_8 f);
uint8_t set_at_2(struct ctx* ctx, struct mut_arr_4* a, uint64_t index, char value);
uint8_t noctx_set_at_3(struct mut_arr_4* a, uint64_t index, char value);
char call_11(struct ctx* ctx, struct fun_mut1_8 a, uint64_t p0);
char call_w_ctx_333(struct fun_mut1_8 a, struct ctx* ctx, uint64_t p0);
char _op_plus_1__lambda0(struct ctx* ctx, struct _op_plus_1__lambda0* _closure, uint64_t i);
struct opt_10 at_5(struct ctx* ctx, struct mut_arr_3* a, uint64_t index);
struct opt_10 noctx_at_7(struct mut_arr_3* a, uint64_t index);
uint8_t parse_cmd_line_args__lambda0(struct ctx* ctx, struct parse_cmd_line_args__lambda0* _closure, struct arr_0 key, struct arr_1 value);
uint8_t get_2(struct cell_2* c);
struct test_options call_12(struct ctx* ctx, struct fun1 a, struct arr_5 p0);
struct test_options call_w_ctx_340(struct fun1 a, struct ctx* ctx, struct arr_5 p0);
struct arr_5 freeze_4(struct mut_arr_3* a);
struct arr_5 unsafe_as_arr_3(struct mut_arr_3* a);
struct opt_10 at_6(struct ctx* ctx, struct arr_5 a, uint64_t index);
struct opt_10 noctx_at_8(struct arr_5 a, uint64_t index);
uint64_t force_1(struct ctx* ctx, struct opt_11 a);
uint64_t fail_2(struct ctx* ctx, struct arr_0 reason);
uint64_t throw_2(struct ctx* ctx, struct exception e);
uint64_t todo_4(void);
struct opt_11 parse_nat(struct ctx* ctx, struct arr_0 a);
struct opt_11 parse_nat_recur(struct ctx* ctx, struct arr_0 a, uint64_t accum);
struct opt_11 char_to_nat(struct ctx* ctx, char c);
struct test_options main_0__lambda0(struct ctx* ctx, uint8_t _closure, struct arr_5 values);
struct fut_0* resolved_1(struct ctx* ctx, int32_t value);
uint8_t print_help(struct ctx* ctx);
uint8_t print(struct arr_0 a);
uint8_t print_no_newline(struct arr_0 a);
int32_t stdout_fd(void);
int32_t do_test(struct ctx* ctx, struct test_options options);
struct arr_0 parent_path(struct ctx* ctx, struct arr_0 a);
struct opt_11 r_index_of(struct ctx* ctx, struct arr_0 a, char value);
struct opt_11 find_rindex(struct ctx* ctx, struct arr_0 a, struct fun_mut1_9 pred);
struct opt_11 find_rindex_recur(struct ctx* ctx, struct arr_0 a, uint64_t index, struct fun_mut1_9 pred);
uint8_t call_13(struct ctx* ctx, struct fun_mut1_9 a, char p0);
uint8_t call_w_ctx_364(struct fun_mut1_9 a, struct ctx* ctx, char p0);
uint8_t r_index_of__lambda0(struct ctx* ctx, struct r_index_of__lambda0* _closure, char it);
struct arr_0 slice_up_to_1(struct ctx* ctx, struct arr_0 a, uint64_t size);
struct arr_0 current_executable_path(struct ctx* ctx);
struct arr_0 read_link(struct ctx* ctx, struct arr_0 path);
extern int64_t readlink(char* path, char* buf, uint64_t len);
char* to_c_str(struct ctx* ctx, struct arr_0 a);
uint8_t check_errno_if_neg_one(struct ctx* ctx, int64_t e);
uint8_t check_posix_error(struct ctx* ctx, int32_t e);
extern int32_t errno;
uint8_t hard_unreachable_1(void);
uint64_t to_nat_0(struct ctx* ctx, int64_t i);
uint8_t negative__q(struct ctx* ctx, int64_t i);
uint8_t _op_less_1(int64_t a, int64_t b);
struct arr_0 child_path(struct ctx* ctx, struct arr_0 a, struct arr_0 child_name);
struct dict_1* get_environ(struct ctx* ctx);
struct mut_dict_1 new_mut_dict_1(struct ctx* ctx);
uint8_t get_environ_recur(struct ctx* ctx, char** env, struct mut_dict_1 res);
uint8_t null__q_2(char* a);
uint8_t add_2(struct ctx* ctx, struct mut_dict_1 m, struct key_value_pair* pair);
uint8_t add_3(struct ctx* ctx, struct mut_dict_1 m, struct arr_0 key, struct arr_0 value);
uint8_t has__q_3(struct ctx* ctx, struct mut_dict_1 d, struct arr_0 key);
uint8_t has__q_4(struct ctx* ctx, struct dict_1* d, struct arr_0 key);
uint8_t has__q_5(struct opt_12 a);
uint8_t empty__q_10(struct opt_12 a);
struct opt_12 get_3(struct ctx* ctx, struct dict_1* d, struct arr_0 key);
struct opt_12 get_recursive_1(struct ctx* ctx, struct arr_1 keys, struct arr_1 values, uint64_t idx, struct arr_0 key);
struct dict_1* unsafe_as_dict_1(struct ctx* ctx, struct mut_dict_1 m);
struct key_value_pair* parse_environ_entry(struct ctx* ctx, char* entry);
char** incr_6(char** p);
extern char** environ;
struct dict_1* freeze_5(struct ctx* ctx, struct mut_dict_1 m);
struct result_3 first_failures(struct ctx* ctx, struct result_3 a, struct fun0 b);
struct result_3 then_1(struct ctx* ctx, struct result_3 a, struct fun_mut1_10 f);
struct result_3 call_14(struct ctx* ctx, struct fun_mut1_10 a, struct arr_0 p0);
struct result_3 call_w_ctx_399(struct fun_mut1_10 a, struct ctx* ctx, struct arr_0 p0);
struct result_3 call_15(struct ctx* ctx, struct fun0 a);
struct result_3 call_w_ctx_401(struct fun0 a, struct ctx* ctx);
struct result_3 first_failures__lambda0__lambda0(struct ctx* ctx, struct first_failures__lambda0__lambda0* _closure, struct arr_0 b_descr);
struct result_3 first_failures__lambda0(struct ctx* ctx, struct first_failures__lambda0* _closure, struct arr_0 a_descr);
struct result_3 run_noze_tests(struct ctx* ctx, struct arr_0 path, struct arr_0 path_to_noze, struct dict_1* env, struct test_options options);
struct arr_1 list_tests(struct ctx* ctx, struct arr_0 path);
uint8_t list_tests__lambda0(struct ctx* ctx, uint8_t _closure, struct arr_0 s);
uint8_t each_child_recursive(struct ctx* ctx, struct arr_0 path, struct fun_mut1_6 filter, struct fun_mut1_11 f);
uint8_t is_dir__q_0(struct ctx* ctx, struct arr_0 path);
uint8_t is_dir__q_1(struct ctx* ctx, char* path);
struct opt_13 get_stat(struct ctx* ctx, char* path);
struct stat_t* empty_stat(struct ctx* ctx);
extern int32_t stat(char* path, struct stat_t* buf);
int32_t enoent(void);
struct opt_13 todo_5(void);
uint8_t todo_6(void);
uint8_t _op_equal_equal_5(uint32_t a, uint32_t b);
struct comparison compare_417(uint32_t a, uint32_t b);
uint32_t s_ifmt(struct ctx* ctx);
uint32_t s_ifdir(struct ctx* ctx);
uint8_t each_1(struct ctx* ctx, struct arr_1 a, struct fun_mut1_11 f);
uint8_t call_16(struct ctx* ctx, struct fun_mut1_11 a, struct arr_0 p0);
uint8_t call_w_ctx_422(struct fun_mut1_11 a, struct ctx* ctx, struct arr_0 p0);
struct arr_1 read_dir_0(struct ctx* ctx, struct arr_0 path);
struct arr_1 read_dir_1(struct ctx* ctx, char* path);
extern uint8_t* opendir(char* name);
uint8_t read_dir_recur(struct ctx* ctx, uint8_t* dirp, struct mut_arr_1* res);
struct bytes256 zero_4(void);
extern int32_t readdir_r(uint8_t* dirp, struct dirent* entry, struct cell_3* result);
struct dirent* get_4(struct cell_3* c);
uint8_t ref_eq__q(struct dirent* a, struct dirent* b);
struct arr_0 get_dirent_name(struct dirent* d);
uint8_t _op_bang_equal_3(struct arr_0 a, struct arr_0 b);
struct arr_1 sort_0(struct ctx* ctx, struct arr_1 a);
struct mut_arr_1* to_mut_arr(struct ctx* ctx, struct arr_1 a);
struct arr_0 to_mut_arr__lambda0(struct ctx* ctx, struct to_mut_arr__lambda0* _closure, uint64_t i);
uint8_t sort_1(struct ctx* ctx, struct mut_arr_1* a);
uint8_t sort_2(struct ctx* ctx, struct mut_slice* a);
uint8_t swap_0(struct ctx* ctx, struct mut_slice* a, uint64_t lo, uint64_t hi);
struct arr_0 at_7(struct ctx* ctx, struct mut_slice* a, uint64_t index);
struct arr_0 at_8(struct ctx* ctx, struct mut_arr_1* a, uint64_t index);
struct arr_0 noctx_at_9(struct mut_arr_1* a, uint64_t index);
uint8_t set_at_3(struct ctx* ctx, struct mut_slice* a, uint64_t index, struct arr_0 value);
uint64_t partition_recur(struct ctx* ctx, struct mut_slice* a, struct arr_0 pivot, uint64_t l, uint64_t r);
uint8_t _op_less_2(struct arr_0 a, struct arr_0 b);
struct mut_slice* slice_4(struct ctx* ctx, struct mut_slice* a, uint64_t lo, uint64_t size);
struct mut_slice* slice_5(struct ctx* ctx, struct mut_slice* a, uint64_t lo);
struct mut_slice* to_mut_slice(struct ctx* ctx, struct mut_arr_1* a);
uint8_t each_child_recursive__lambda0(struct ctx* ctx, struct each_child_recursive__lambda0* _closure, struct arr_0 child_name);
struct opt_12 get_extension(struct ctx* ctx, struct arr_0 name);
struct opt_11 last_index_of(struct ctx* ctx, struct arr_0 s, char c);
char last(struct ctx* ctx, struct arr_0 a);
struct arr_0 rtail(struct ctx* ctx, struct arr_0 a);
struct arr_0 slice_after_1(struct ctx* ctx, struct arr_0 a, uint64_t before_begin);
struct arr_0 base_name(struct ctx* ctx, struct arr_0 path);
uint8_t list_tests__lambda1(struct ctx* ctx, struct list_tests__lambda1* _closure, struct arr_0 child);
struct arr_7 flat_map_with_max_size(struct ctx* ctx, struct arr_1 a, uint64_t max_size, struct fun_mut1_12 mapper);
struct mut_arr_5* new_mut_arr_2(struct ctx* ctx);
uint8_t push_all(struct ctx* ctx, struct mut_arr_5* a, struct arr_7 values);
uint8_t each_2(struct ctx* ctx, struct arr_7 a, struct fun_mut1_13 f);
uint8_t empty__q_11(struct arr_7 a);
uint8_t call_17(struct ctx* ctx, struct fun_mut1_13 a, struct failure* p0);
uint8_t call_w_ctx_462(struct fun_mut1_13 a, struct ctx* ctx, struct failure* p0);
struct failure* first_3(struct ctx* ctx, struct arr_7 a);
struct failure* at_9(struct ctx* ctx, struct arr_7 a, uint64_t index);
struct failure* noctx_at_10(struct arr_7 a, uint64_t index);
struct arr_7 tail_4(struct ctx* ctx, struct arr_7 a);
struct arr_7 slice_starting_at_4(struct ctx* ctx, struct arr_7 a, uint64_t begin);
struct arr_7 slice_6(struct ctx* ctx, struct arr_7 a, uint64_t begin, uint64_t size);
uint8_t push_2(struct ctx* ctx, struct mut_arr_5* a, struct failure* value);
uint8_t increase_capacity_to_2(struct ctx* ctx, struct mut_arr_5* a, uint64_t new_capacity);
struct failure** uninitialized_data_4(struct ctx* ctx, uint64_t size);
uint8_t copy_data_from_2(struct ctx* ctx, struct failure** to, struct failure** from, uint64_t len);
uint8_t copy_data_from_small_2(struct ctx* ctx, struct failure** to, struct failure** from, uint64_t len);
struct failure** incr_7(struct failure** p);
uint8_t ensure_capacity_2(struct ctx* ctx, struct mut_arr_5* a, uint64_t capacity);
uint8_t push_all__lambda0(struct ctx* ctx, struct push_all__lambda0* _closure, struct failure* it);
struct arr_7 call_18(struct ctx* ctx, struct fun_mut1_12 a, struct arr_0 p0);
struct arr_7 call_w_ctx_478(struct fun_mut1_12 a, struct ctx* ctx, struct arr_0 p0);
uint8_t reduce_size_if_more_than(struct ctx* ctx, struct mut_arr_5* a, uint64_t new_size);
uint8_t flat_map_with_max_size__lambda0(struct ctx* ctx, struct flat_map_with_max_size__lambda0* _closure, struct arr_0 x);
struct arr_7 freeze_6(struct mut_arr_5* a);
struct arr_7 unsafe_as_arr_4(struct mut_arr_5* a);
struct arr_7 run_single_noze_test(struct ctx* ctx, struct arr_0 path_to_noze, struct dict_1* env, struct arr_0 path, struct test_options options);
struct opt_14 first_some(struct ctx* ctx, struct arr_1 a, struct fun_mut1_14 cb);
struct opt_14 call_19(struct ctx* ctx, struct fun_mut1_14 a, struct arr_0 p0);
struct opt_14 call_w_ctx_486(struct fun_mut1_14 a, struct ctx* ctx, struct arr_0 p0);
struct print_test_result* run_print_test(struct ctx* ctx, struct arr_0 print_kind, struct arr_0 path_to_noze, struct dict_1* env, struct arr_0 path, uint8_t overwrite_output__q);
struct process_result* spawn_and_wait_result_0(struct ctx* ctx, struct arr_0 exe, struct arr_1 args, struct dict_1* environ);
struct arr_0 fold(struct ctx* ctx, struct arr_0 val, struct arr_1 a, struct fun_mut2_1 combine);
struct arr_0 call_20(struct ctx* ctx, struct fun_mut2_1 a, struct arr_0 p0, struct arr_0 p1);
struct arr_0 call_w_ctx_491(struct fun_mut2_1 a, struct ctx* ctx, struct arr_0 p0, struct arr_0 p1);
struct arr_0 spawn_and_wait_result_0__lambda0(struct ctx* ctx, uint8_t _closure, struct arr_0 a, struct arr_0 b);
uint8_t is_file__q_0(struct ctx* ctx, struct arr_0 path);
uint8_t is_file__q_1(struct ctx* ctx, char* path);
uint32_t s_ifreg(struct ctx* ctx);
struct process_result* spawn_and_wait_result_1(struct ctx* ctx, char* exe, char** args, char** environ);
struct pipes* make_pipes(struct ctx* ctx);
extern int32_t pipe(struct pipes* pipes);
extern int32_t posix_spawn_file_actions_init(struct posix_spawn_file_actions_t* file_actions);
extern int32_t posix_spawn_file_actions_addclose(struct posix_spawn_file_actions_t* file_actions, int32_t fd);
extern int32_t posix_spawn_file_actions_adddup2(struct posix_spawn_file_actions_t* file_actions, int32_t fd, int32_t new_fd);
extern int32_t posix_spawn(struct cell_4* pid, char* executable_path, struct posix_spawn_file_actions_t* file_actions, uint8_t* attrp, char** argv, char** environ);
int32_t get_5(struct cell_4* c);
extern int32_t close(int32_t fd);
struct mut_arr_4* new_mut_arr_3(struct ctx* ctx);
uint8_t keep_polling(struct ctx* ctx, int32_t stdout_pipe, int32_t stderr_pipe, struct mut_arr_4* stdout_builder, struct mut_arr_4* stderr_builder);
int16_t pollin(struct ctx* ctx);
struct pollfd* ref_of_val_at(struct ctx* ctx, struct arr_8 a, uint64_t index);
struct pollfd* ref_of_ptr(struct pollfd* p);
extern int32_t poll(struct pollfd* fds, uint64_t n_fds, int32_t timeout);
struct handle_revents_result handle_revents(struct ctx* ctx, struct pollfd* pollfd, struct mut_arr_4* builder);
uint8_t has_pollin__q(struct ctx* ctx, int16_t revents);
uint8_t bits_intersect__q(int16_t a, int16_t b);
uint8_t _op_equal_equal_6(int16_t a, int16_t b);
struct comparison compare_515(int16_t a, int16_t b);
uint8_t read_to_buffer_until_eof(struct ctx* ctx, int32_t fd, struct mut_arr_4* buffer);
uint8_t ensure_capacity_3(struct ctx* ctx, struct mut_arr_4* a, uint64_t capacity);
uint8_t increase_capacity_to_3(struct ctx* ctx, struct mut_arr_4* a, uint64_t new_capacity);
uint8_t copy_data_from_3(struct ctx* ctx, char* to, char* from, uint64_t len);
uint8_t copy_data_from_small_3(struct ctx* ctx, char* to, char* from, uint64_t len);
extern int64_t read(int32_t fd, uint8_t* buff, uint64_t n_bytes);
uint8_t unsafe_increase_size(struct ctx* ctx, struct mut_arr_4* a, uint64_t increase_by);
uint8_t unsafe_set_size(struct ctx* ctx, struct mut_arr_4* a, uint64_t new_size);
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
uint64_t to_nat_1(struct ctx* ctx, uint8_t b);
uint8_t any__q(struct ctx* ctx, struct handle_revents_result r);
uint64_t to_nat_2(struct ctx* ctx, int32_t i);
int32_t wait_and_get_exit_code(struct ctx* ctx, int32_t pid);
extern int32_t waitpid(int32_t pid, struct cell_4* wait_status, int32_t options);
uint8_t w_if_exited(struct ctx* ctx, int32_t status);
int32_t w_term_sig(struct ctx* ctx, int32_t status);
int32_t w_exit_status(struct ctx* ctx, int32_t status);
int32_t bit_shift_right(int32_t a, int32_t b);
uint8_t _op_less_3(int32_t a, int32_t b);
int32_t todo_7(void);
uint8_t w_if_signaled(struct ctx* ctx, int32_t status);
struct arr_0 to_str_1(struct ctx* ctx, int32_t i);
struct arr_0 to_str_2(struct ctx* ctx, int64_t i);
struct arr_0 to_str_3(struct ctx* ctx, uint64_t n);
uint64_t mod(struct ctx* ctx, uint64_t a, uint64_t b);
uint64_t abs(struct ctx* ctx, int64_t i);
int64_t neg(struct ctx* ctx, int64_t i);
int64_t _op_times_1(struct ctx* ctx, int64_t a, int64_t b);
uint8_t w_if_stopped(struct ctx* ctx, int32_t status);
uint8_t w_if_continued(struct ctx* ctx, int32_t status);
char** convert_args(struct ctx* ctx, char* exe_c_str, struct arr_1 args);
struct arr_3 prepend(struct ctx* ctx, char* a, struct arr_3 b);
struct arr_3 _op_plus_2(struct ctx* ctx, struct arr_3 a, struct arr_3 b);
struct arr_3 make_arr_2(struct ctx* ctx, uint64_t size, struct fun_mut1_15 f);
struct arr_3 freeze_7(struct mut_arr_6* a);
struct arr_3 unsafe_as_arr_5(struct mut_arr_6* a);
struct mut_arr_6* make_mut_arr_3(struct ctx* ctx, uint64_t size, struct fun_mut1_15 f);
struct mut_arr_6* new_uninitialized_mut_arr_3(struct ctx* ctx, uint64_t size);
char** uninitialized_data_5(struct ctx* ctx, uint64_t size);
uint8_t make_mut_arr_worker_3(struct ctx* ctx, struct mut_arr_6* m, uint64_t i, struct fun_mut1_15 f);
uint8_t set_at_4(struct ctx* ctx, struct mut_arr_6* a, uint64_t index, char* value);
uint8_t noctx_set_at_4(struct mut_arr_6* a, uint64_t index, char* value);
char* call_21(struct ctx* ctx, struct fun_mut1_15 a, uint64_t p0);
char* call_w_ctx_568(struct fun_mut1_15 a, struct ctx* ctx, uint64_t p0);
char* _op_plus_2__lambda0(struct ctx* ctx, struct _op_plus_2__lambda0* _closure, uint64_t i);
struct arr_3 append(struct ctx* ctx, struct arr_3 a, char* b);
struct arr_3 map_1(struct ctx* ctx, struct arr_1 a, struct fun_mut1_16 mapper);
char* call_22(struct ctx* ctx, struct fun_mut1_16 a, struct arr_0 p0);
char* call_w_ctx_573(struct fun_mut1_16 a, struct ctx* ctx, struct arr_0 p0);
char* map_1__lambda0(struct ctx* ctx, struct map_1__lambda0* _closure, uint64_t i);
char* convert_args__lambda0(struct ctx* ctx, uint8_t _closure, struct arr_0 it);
char** convert_environ(struct ctx* ctx, struct dict_1* environ);
struct mut_arr_6* new_mut_arr_4(struct ctx* ctx);
uint8_t each_3(struct ctx* ctx, struct dict_1* d, struct fun_mut2_2 f);
uint8_t empty__q_12(struct ctx* ctx, struct dict_1* d);
uint8_t call_23(struct ctx* ctx, struct fun_mut2_2 a, struct arr_0 p0, struct arr_0 p1);
uint8_t call_w_ctx_581(struct fun_mut2_2 a, struct ctx* ctx, struct arr_0 p0, struct arr_0 p1);
uint8_t push_3(struct ctx* ctx, struct mut_arr_6* a, char* value);
uint8_t increase_capacity_to_4(struct ctx* ctx, struct mut_arr_6* a, uint64_t new_capacity);
uint8_t copy_data_from_4(struct ctx* ctx, char** to, char** from, uint64_t len);
uint8_t copy_data_from_small_4(struct ctx* ctx, char** to, char** from, uint64_t len);
uint8_t ensure_capacity_4(struct ctx* ctx, struct mut_arr_6* a, uint64_t capacity);
uint8_t convert_environ__lambda0(struct ctx* ctx, struct convert_environ__lambda0* _closure, struct arr_0 key, struct arr_0 value);
struct process_result* fail_3(struct ctx* ctx, struct arr_0 reason);
struct process_result* throw_3(struct ctx* ctx, struct exception e);
struct process_result* todo_8(void);
struct arr_7 empty_arr_3(void);
struct arr_7 handle_output(struct ctx* ctx, struct arr_0 original_path, struct arr_0 output_path, struct arr_0 actual, uint8_t overwrite_output__q);
struct opt_12 try_read_file_0(struct ctx* ctx, struct arr_0 path);
struct opt_12 try_read_file_1(struct ctx* ctx, char* path);
extern int32_t open(char* path, uint32_t oflag, uint32_t permission);
uint32_t o_rdonly(struct ctx* ctx);
struct opt_12 todo_9(void);
extern int64_t lseek(int32_t f, int64_t offset, int32_t whence);
int32_t seek_end(struct ctx* ctx);
int32_t seek_set(struct ctx* ctx);
uint8_t write_file_0(struct ctx* ctx, struct arr_0 path, struct arr_0 content);
uint8_t write_file_1(struct ctx* ctx, char* path, struct arr_0 content);
uint32_t bit_shift_left(uint32_t a, uint32_t b);
uint8_t _op_less_4(uint32_t a, uint32_t b);
uint32_t o_creat(struct ctx* ctx);
uint32_t o_wronly(struct ctx* ctx);
uint32_t o_trunc(struct ctx* ctx);
struct arr_0 to_str_4(struct ctx* ctx, uint32_t n);
int64_t to_int(struct ctx* ctx, uint64_t n);
int64_t max_int(void);
struct arr_0 remove_colors(struct ctx* ctx, struct arr_0 s);
uint8_t remove_colors_recur(struct ctx* ctx, struct arr_0 s, struct mut_arr_4* out);
uint8_t remove_colors_recur_2(struct ctx* ctx, struct arr_0 s, struct mut_arr_4* out);
uint8_t push_4(struct ctx* ctx, struct mut_arr_4* a, char value);
struct opt_14 run_single_noze_test__lambda0(struct ctx* ctx, struct run_single_noze_test__lambda0* _closure, struct arr_0 print_kind);
struct arr_7 run_single_runnable_test(struct ctx* ctx, struct arr_0 path_to_noze, struct dict_1* env, struct arr_0 path, uint8_t interpret__q, uint8_t overwrite_output__q);
struct arr_7 run_noze_tests__lambda0(struct ctx* ctx, struct run_noze_tests__lambda0* _closure, struct arr_0 test);
uint8_t has__q_6(struct arr_7 a);
struct result_3 do_test__lambda0__lambda0(struct ctx* ctx, struct do_test__lambda0__lambda0* _closure);
struct result_3 do_test__lambda0(struct ctx* ctx, struct do_test__lambda0* _closure);
struct result_3 lint(struct ctx* ctx, struct arr_0 path, struct test_options options);
struct arr_1 list_lintable_files(struct ctx* ctx, struct arr_0 path);
uint8_t excluded_from_lint__q(struct ctx* ctx, struct arr_0 name);
uint8_t contains__q_1(struct arr_1 a, struct arr_0 value);
uint8_t contains_recur__q_1(struct arr_1 a, struct arr_0 value, uint64_t i);
uint8_t some__q(struct ctx* ctx, struct arr_1 a, struct fun_mut1_6 pred);
uint8_t ends_with__q(struct ctx* ctx, struct arr_0 a, struct arr_0 end);
uint8_t excluded_from_lint__q__lambda0(struct ctx* ctx, struct excluded_from_lint__q__lambda0* _closure, struct arr_0 it);
uint8_t list_lintable_files__lambda0(struct ctx* ctx, uint8_t _closure, struct arr_0 it);
uint8_t ignore_extension_of_name__q(struct ctx* ctx, struct arr_0 name);
uint8_t ignore_extension__q(struct ctx* ctx, struct arr_0 ext);
struct arr_1 ignored_extensions(struct ctx* ctx);
uint8_t list_lintable_files__lambda1(struct ctx* ctx, struct list_lintable_files__lambda1* _closure, struct arr_0 child);
struct arr_7 lint_file(struct ctx* ctx, struct arr_0 path);
struct arr_0 read_file(struct ctx* ctx, struct arr_0 path);
uint8_t each_with_index_0(struct ctx* ctx, struct arr_1 a, struct fun_mut2_3 f);
uint8_t each_with_index_recur_0(struct ctx* ctx, struct arr_1 a, struct fun_mut2_3 f, uint64_t n);
uint8_t call_24(struct ctx* ctx, struct fun_mut2_3 a, struct arr_0 p0, uint64_t p1);
uint8_t call_w_ctx_639(struct fun_mut2_3 a, struct ctx* ctx, struct arr_0 p0, uint64_t p1);
struct arr_1 lines(struct ctx* ctx, struct arr_0 s);
uint8_t each_with_index_1(struct ctx* ctx, struct arr_0 a, struct fun_mut2_4 f);
uint8_t each_with_index_recur_1(struct ctx* ctx, struct arr_0 a, struct fun_mut2_4 f, uint64_t n);
uint8_t call_25(struct ctx* ctx, struct fun_mut2_4 a, char p0, uint64_t p1);
uint8_t call_w_ctx_644(struct fun_mut2_4 a, struct ctx* ctx, char p0, uint64_t p1);
struct arr_0 slice_from_to(struct ctx* ctx, struct arr_0 a, uint64_t begin, uint64_t end);
uint64_t swap_1(struct cell_0* c, uint64_t v);
uint64_t get_6(struct cell_0* c);
uint8_t set_1(struct cell_0* c, uint64_t v);
uint8_t lines__lambda0(struct ctx* ctx, struct lines__lambda0* _closure, char c, uint64_t index);
uint8_t contains_subsequence__q(struct ctx* ctx, struct arr_0 a, struct arr_0 subseq);
uint8_t has__q_7(struct arr_0 a);
struct arr_0 lstrip(struct ctx* ctx, struct arr_0 a);
uint64_t line_len(struct ctx* ctx, struct arr_0 line);
uint64_t n_tabs(struct ctx* ctx, struct arr_0 line);
uint64_t tab_size(struct ctx* ctx);
uint64_t max_line_length(struct ctx* ctx);
uint8_t lint_file__lambda0(struct ctx* ctx, struct lint_file__lambda0* _closure, struct arr_0 line, uint64_t line_num);
struct arr_7 lint__lambda0(struct ctx* ctx, struct lint__lambda0* _closure, struct arr_0 file);
struct result_3 do_test__lambda1(struct ctx* ctx, struct do_test__lambda1* _closure);
int32_t print_failures(struct ctx* ctx, struct result_3 failures, struct test_options options);
uint8_t print_failure(struct ctx* ctx, struct failure* failure);
uint8_t print_bold(struct ctx* ctx);
uint8_t print_reset(struct ctx* ctx);
uint8_t print_failures__lambda0(struct ctx* ctx, uint8_t _closure, struct failure* it);
int32_t to_int32(struct ctx* ctx, uint64_t n);
int32_t max_int32(void);
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
	gc_memory__q3 = _op_less_0(index2, ctx->memory_size_words);
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
uint8_t _op_less_0(uint64_t a, uint64_t b) {
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
	return !_op_less_0(b, a);
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
	drop_0(to_str_0((*(argv))));
	gctx_by_val0 = (struct global_ctx) {new_lock(), empty_arr_0(), 1u, new_condition(), 0, 0};
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
struct arr_0 to_str_0(char* a) {
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
struct arr_2 empty_arr_0(void) {
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
	gc_root1 = (struct island_gc_root) {new_mut_bag(), (struct fun_mut1_1) {0, .as0 = 0}};
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
uint8_t new_island__lambda0(struct ctx* ctx, uint8_t _closure, struct exception it) {
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
	struct fun2 add4;
	struct arr_3 all_args5;
	ectx0 = new_exception_ctx();
	tls1 = (struct thread_local_stuff) {(&(ectx0))};
	ctx_by_val2 = new_ctx(gctx, (&(tls1)), island, 0u);
	ctx3 = (&(ctx_by_val2));
	add4 = (struct fun2) {0, .as0 = 0};
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
	hard_assert(_op_less_0(n, max_nat()));
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
	return then2(ctx, delay(ctx), (struct fun_ref0) {cur_island_and_exclusion(ctx), (struct fun_mut0_1) {0, .as0 = (temp0 = (struct add_first_task__lambda0*) alloc(ctx, sizeof(struct add_first_task__lambda0)), ((*(temp0) = (struct add_first_task__lambda0) {all_args, main_ptr}, 0), temp0))}});
}
/* then2<int32> fut<int32>(f fut<void>, cb fun-ref0<int32>) */
struct fut_0* then2(struct ctx* ctx, struct fut_1* f, struct fun_ref0 cb) {
	struct then2__lambda0* temp0;
	return then_0(ctx, f, (struct fun_ref1) {cur_island_and_exclusion(ctx), (struct fun_mut1_3) {0, .as0 = (temp0 = (struct then2__lambda0*) alloc(ctx, sizeof(struct then2__lambda0)), ((*(temp0) = (struct then2__lambda0) {cb}, 0), temp0))}});
}
/* then<?out, void> fut<int32>(f fut<void>, cb fun-ref1<int32, void>) */
struct fut_0* then_0(struct ctx* ctx, struct fut_1* f, struct fun_ref1 cb) {
	struct fut_0* res0;
	struct then_0__lambda0* temp0;
	res0 = new_unresolved_fut(ctx);
	then_void_0(ctx, f, (struct fun_mut1_2) {0, .as0 = (temp0 = (struct then_0__lambda0*) alloc(ctx, sizeof(struct then_0__lambda0)), ((*(temp0) = (struct then_0__lambda0) {cb, res0}, 0), temp0))});
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
uint8_t then_void_0(struct ctx* ctx, struct fut_1* f, struct fun_mut1_2 cb) {
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
uint8_t call_0(struct ctx* ctx, struct fun_mut1_2 a, struct result_1 p0) {
	return call_w_ctx_78(a, ctx, p0);
}
/* call-w-ctx<void, result<void, exception>> (generated) (generated) */
uint8_t call_w_ctx_78(struct fun_mut1_2 a, struct ctx* ctx, struct result_1 p0) {
	struct fun_mut1_2 match_fun1;
	struct then_0__lambda0* closure0;
	match_fun1 = a;
	switch (match_fun1.kind) {
		case 0:
			closure0 = match_fun1.as0;
			return then_0__lambda0(ctx, closure0, p0);
		default:
			return (assert(0),0);
	}
}
/* forward-to<?out> void(from fut<int32>, to fut<int32>) */
uint8_t forward_to(struct ctx* ctx, struct fut_0* from, struct fut_0* to) {
	struct forward_to__lambda0* temp0;
	return then_void_1(ctx, from, (struct fun_mut1_0) {0, .as0 = (temp0 = (struct forward_to__lambda0*) alloc(ctx, sizeof(struct forward_to__lambda0)), ((*(temp0) = (struct forward_to__lambda0) {to}, 0), temp0))});
}
/* then-void<?t> void(f fut<int32>, cb fun-mut1<void, result<int32, exception>>) */
uint8_t then_void_1(struct ctx* ctx, struct fut_0* f, struct fun_mut1_0 cb) {
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
uint8_t call_1(struct ctx* ctx, struct fun_mut1_0 a, struct result_0 p0) {
	return call_w_ctx_82(a, ctx, p0);
}
/* call-w-ctx<void, result<int32, exception>> (generated) (generated) */
uint8_t call_w_ctx_82(struct fun_mut1_0 a, struct ctx* ctx, struct result_0 p0) {
	struct fun_mut1_0 match_fun1;
	struct forward_to__lambda0* closure0;
	match_fun1 = a;
	switch (match_fun1.kind) {
		case 0:
			closure0 = match_fun1.as0;
			return forward_to__lambda0(ctx, closure0, p0);
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
	add_task(ctx, island0, (struct task) {f.island_and_exclusion.exclusion, (struct fun_mut0_0) {1, .as1 = (temp0 = (struct call_ref_0__lambda0*) alloc(ctx, sizeof(struct call_ref_0__lambda0)), ((*(temp0) = (struct call_ref_0__lambda0) {f, p0, res1}, 0), temp0))}});
	return res1;
}
/* get-island island(island-id nat) */
struct island* get_island(struct ctx* ctx, uint64_t island_id) {
	return at_0(ctx, get_gctx(ctx)->islands, island_id);
}
/* at<island> island(a arr<island>, index nat) */
struct island* at_0(struct ctx* ctx, struct arr_2 a, uint64_t index) {
	assert_0(ctx, _op_less_0(index, a.size));
	return noctx_at_0(a, index);
}
/* assert void(condition bool) */
uint8_t assert_0(struct ctx* ctx, uint8_t condition) {
	return assert_1(ctx, condition, (struct arr_0) {13, constantarr_0_7});
}
/* assert void(condition bool, message arr<char>) */
uint8_t assert_1(struct ctx* ctx, uint8_t condition, struct arr_0 message) {
	if (!condition) {
		return fail_0(ctx, message);
	} else {
		return 0;
	}
}
/* fail<void> void(reason arr<char>) */
uint8_t fail_0(struct ctx* ctx, struct arr_0 reason) {
	return throw_0(ctx, (struct exception) {reason});
}
/* throw<?t> void(e exception) */
uint8_t throw_0(struct ctx* ctx, struct exception e) {
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
	hard_assert(_op_less_0(index, a.size));
	return (*((a.data + index)));
}
/* add-task void(a island, t task) */
uint8_t add_task(struct ctx* ctx, struct island* a, struct task t) {
	struct mut_bag_node* node0;
	node0 = new_mut_bag_node(ctx, t);
	acquire_lock((&(a->tasks_lock)));
	add_0(tasks(a), node0);
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
uint8_t add_0(struct mut_bag* bag, struct mut_bag_node* node) {
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
uint8_t catch(struct ctx* ctx, struct fun_mut0_0 try, struct fun_mut1_1 catcher) {
	return catch_with_exception_ctx(ctx, get_exception_ctx(ctx), try, catcher);
}
/* catch-with-exception-ctx<?t> void(ec exception-ctx, try fun-mut0<void>, catcher fun-mut1<void, exception>) */
uint8_t catch_with_exception_ctx(struct ctx* ctx, struct exception_ctx* ec, struct fun_mut0_0 try, struct fun_mut1_1 catcher) {
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
uint8_t call_2(struct ctx* ctx, struct fun_mut0_0 a) {
	return call_w_ctx_112(a, ctx);
}
/* call-w-ctx<void> (generated) (generated) */
uint8_t call_w_ctx_112(struct fun_mut0_0 a, struct ctx* ctx) {
	struct fun_mut0_0 match_fun4;
	struct call_ref_0__lambda0__lambda0* closure0;
	struct call_ref_0__lambda0* closure1;
	struct call_ref_1__lambda0__lambda0* closure2;
	struct call_ref_1__lambda0* closure3;
	match_fun4 = a;
	switch (match_fun4.kind) {
		case 0:
			closure0 = match_fun4.as0;
			return call_ref_0__lambda0__lambda0(ctx, closure0);
		case 1:
			closure1 = match_fun4.as1;
			return call_ref_0__lambda0(ctx, closure1);
		case 2:
			closure2 = match_fun4.as2;
			return call_ref_1__lambda0__lambda0(ctx, closure2);
		case 3:
			closure3 = match_fun4.as3;
			return call_ref_1__lambda0(ctx, closure3);
		default:
			return (assert(0),0);
	}
}
/* call<?t, exception> void(a fun-mut1<void, exception>, p0 exception) */
uint8_t call_3(struct ctx* ctx, struct fun_mut1_1 a, struct exception p0) {
	return call_w_ctx_114(a, ctx, p0);
}
/* call-w-ctx<void, exception> (generated) (generated) */
uint8_t call_w_ctx_114(struct fun_mut1_1 a, struct ctx* ctx, struct exception p0) {
	struct fun_mut1_1 match_fun3;
	uint8_t closure0;
	struct call_ref_0__lambda0__lambda1* closure1;
	struct call_ref_1__lambda0__lambda1* closure2;
	match_fun3 = a;
	switch (match_fun3.kind) {
		case 0:
			closure0 = match_fun3.as0;
			return new_island__lambda0(ctx, closure0, p0);
		case 1:
			closure1 = match_fun3.as1;
			return call_ref_0__lambda0__lambda1(ctx, closure1, p0);
		case 2:
			closure2 = match_fun3.as2;
			return call_ref_1__lambda0__lambda1(ctx, closure2, p0);
		default:
			return (assert(0),0);
	}
}
/* call<fut<?r>, ?p0> fut<int32>(a fun-mut1<fut<int32>, void>, p0 void) */
struct fut_0* call_4(struct ctx* ctx, struct fun_mut1_3 a, uint8_t p0) {
	return call_w_ctx_116(a, ctx, p0);
}
/* call-w-ctx<gc-ptr(fut<int32>), void> (generated) (generated) */
struct fut_0* call_w_ctx_116(struct fun_mut1_3 a, struct ctx* ctx, uint8_t p0) {
	struct fun_mut1_3 match_fun1;
	struct then2__lambda0* closure0;
	match_fun1 = a;
	switch (match_fun1.kind) {
		case 0:
			closure0 = match_fun1.as0;
			return then2__lambda0(ctx, closure0, p0);
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
	return catch(ctx, (struct fun_mut0_0) {0, .as0 = (temp0 = (struct call_ref_0__lambda0__lambda0*) alloc(ctx, sizeof(struct call_ref_0__lambda0__lambda0)), ((*(temp0) = (struct call_ref_0__lambda0__lambda0) {_closure->f, _closure->p0, _closure->res}, 0), temp0))}, (struct fun_mut1_1) {1, .as1 = (temp1 = (struct call_ref_0__lambda0__lambda1*) alloc(ctx, sizeof(struct call_ref_0__lambda0__lambda1)), ((*(temp1) = (struct call_ref_0__lambda0__lambda1) {_closure->res}, 0), temp1))});
}
/* then<?out, void>.lambda0 void(result result<void, exception>) */
uint8_t then_0__lambda0(struct ctx* ctx, struct then_0__lambda0* _closure, struct result_1 result) {
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
	add_task(ctx, island0, (struct task) {f.island_and_exclusion.exclusion, (struct fun_mut0_0) {3, .as3 = (temp0 = (struct call_ref_1__lambda0*) alloc(ctx, sizeof(struct call_ref_1__lambda0)), ((*(temp0) = (struct call_ref_1__lambda0) {f, res1}, 0), temp0))}});
	return res1;
}
/* call<fut<?r>> fut<int32>(a fun-mut0<fut<int32>>) */
struct fut_0* call_5(struct ctx* ctx, struct fun_mut0_1 a) {
	return call_w_ctx_124(a, ctx);
}
/* call-w-ctx<gc-ptr(fut<int32>)> (generated) (generated) */
struct fut_0* call_w_ctx_124(struct fun_mut0_1 a, struct ctx* ctx) {
	struct fun_mut0_1 match_fun1;
	struct add_first_task__lambda0* closure0;
	match_fun1 = a;
	switch (match_fun1.kind) {
		case 0:
			closure0 = match_fun1.as0;
			return add_first_task__lambda0(ctx, closure0);
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
	return catch(ctx, (struct fun_mut0_0) {2, .as2 = (temp0 = (struct call_ref_1__lambda0__lambda0*) alloc(ctx, sizeof(struct call_ref_1__lambda0__lambda0)), ((*(temp0) = (struct call_ref_1__lambda0__lambda0) {_closure->f, _closure->res}, 0), temp0))}, (struct fun_mut1_1) {2, .as2 = (temp1 = (struct call_ref_1__lambda0__lambda1*) alloc(ctx, sizeof(struct call_ref_1__lambda0__lambda1)), ((*(temp1) = (struct call_ref_1__lambda0__lambda1) {_closure->res}, 0), temp1))});
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
struct arr_3 tail_0(struct ctx* ctx, struct arr_3 a) {
	forbid_0(ctx, empty__q_1(a));
	return slice_starting_at_0(ctx, a, 1u);
}
/* forbid void(condition bool) */
uint8_t forbid_0(struct ctx* ctx, uint8_t condition) {
	return forbid_1(ctx, condition, (struct arr_0) {13, constantarr_0_8});
}
/* forbid void(condition bool, message arr<char>) */
uint8_t forbid_1(struct ctx* ctx, uint8_t condition, struct arr_0 message) {
	if (condition) {
		return fail_0(ctx, message);
	} else {
		return 0;
	}
}
/* empty?<?t> bool(a arr<ptr<char>>) */
uint8_t empty__q_1(struct arr_3 a) {
	return _op_equal_equal_0(a.size, 0u);
}
/* slice-starting-at<?t> arr<ptr<char>>(a arr<ptr<char>>, begin nat) */
struct arr_3 slice_starting_at_0(struct ctx* ctx, struct arr_3 a, uint64_t begin) {
	assert_0(ctx, _op_less_equal(begin, a.size));
	return slice_0(ctx, a, begin, _op_minus_2(ctx, a.size, begin));
}
/* slice<?t> arr<ptr<char>>(a arr<ptr<char>>, begin nat, size nat) */
struct arr_3 slice_0(struct ctx* ctx, struct arr_3 a, uint64_t begin, uint64_t size) {
	assert_0(ctx, _op_less_equal(_op_plus_0(ctx, begin, size), a.size));
	return (struct arr_3) {size, (a.data + begin)};
}
/* + nat(a nat, b nat) */
uint64_t _op_plus_0(struct ctx* ctx, uint64_t a, uint64_t b) {
	uint64_t res0;
	res0 = (a + b);
	assert_0(ctx, (_op_greater_equal(res0, a) && _op_greater_equal(res0, b)));
	return res0;
}
/* >=<nat> bool(a nat, b nat) */
uint8_t _op_greater_equal(uint64_t a, uint64_t b) {
	return !_op_less_0(a, b);
}
/* - nat(a nat, b nat) */
uint64_t _op_minus_2(struct ctx* ctx, uint64_t a, uint64_t b) {
	assert_0(ctx, _op_greater_equal(a, b));
	return (a - b);
}
/* map<arr<char>, ptr<char>> arr<arr<char>>(a arr<ptr<char>>, mapper fun-mut1<arr<char>, ptr<char>>) */
struct arr_1 map_0(struct ctx* ctx, struct arr_3 a, struct fun_mut1_4 mapper) {
	struct map_0__lambda0* temp0;
	return make_arr_0(ctx, a.size, (struct fun_mut1_5) {0, .as0 = (temp0 = (struct map_0__lambda0*) alloc(ctx, sizeof(struct map_0__lambda0)), ((*(temp0) = (struct map_0__lambda0) {mapper, a}, 0), temp0))});
}
/* make-arr<?out> arr<arr<char>>(size nat, f fun-mut1<arr<char>, nat>) */
struct arr_1 make_arr_0(struct ctx* ctx, uint64_t size, struct fun_mut1_5 f) {
	return freeze_0(make_mut_arr_0(ctx, size, f));
}
/* freeze<?t> arr<arr<char>>(a mut-arr<arr<char>>) */
struct arr_1 freeze_0(struct mut_arr_1* a) {
	(a->frozen__q = 1, 0);
	return unsafe_as_arr_0(a);
}
/* unsafe-as-arr<?t> arr<arr<char>>(a mut-arr<arr<char>>) */
struct arr_1 unsafe_as_arr_0(struct mut_arr_1* a) {
	return (struct arr_1) {a->size, a->data};
}
/* make-mut-arr<?t> mut-arr<arr<char>>(size nat, f fun-mut1<arr<char>, nat>) */
struct mut_arr_1* make_mut_arr_0(struct ctx* ctx, uint64_t size, struct fun_mut1_5 f) {
	struct mut_arr_1* res0;
	res0 = new_uninitialized_mut_arr_0(ctx, size);
	make_mut_arr_worker_0(ctx, res0, 0u, f);
	return res0;
}
/* new-uninitialized-mut-arr<?t> mut-arr<arr<char>>(size nat) */
struct mut_arr_1* new_uninitialized_mut_arr_0(struct ctx* ctx, uint64_t size) {
	struct mut_arr_1* temp0;
	temp0 = (struct mut_arr_1*) alloc(ctx, sizeof(struct mut_arr_1));
	(*(temp0) = (struct mut_arr_1) {0, size, size, uninitialized_data_0(ctx, size)}, 0);
	return temp0;
}
/* uninitialized-data<?t> ptr<arr<char>>(size nat) */
struct arr_0* uninitialized_data_0(struct ctx* ctx, uint64_t size) {
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
uint8_t make_mut_arr_worker_0(struct ctx* ctx, struct mut_arr_1* m, uint64_t i, struct fun_mut1_5 f) {
	struct mut_arr_1* _tailCallm;
	uint64_t _tailCalli;
	struct fun_mut1_5 _tailCallf;
	top:
	if (_op_bang_equal_0(i, m->size)) {
		set_at_0(ctx, m, i, call_6(ctx, f, i));
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
uint8_t set_at_0(struct ctx* ctx, struct mut_arr_1* a, uint64_t index, struct arr_0 value) {
	assert_0(ctx, _op_less_0(index, a->size));
	return noctx_set_at_0(a, index, value);
}
/* noctx-set-at<?t> void(a mut-arr<arr<char>>, index nat, value arr<char>) */
uint8_t noctx_set_at_0(struct mut_arr_1* a, uint64_t index, struct arr_0 value) {
	hard_assert(_op_less_0(index, a->size));
	return (*((a->data + index)) = value, 0);
}
/* call<?t, nat> arr<char>(a fun-mut1<arr<char>, nat>, p0 nat) */
struct arr_0 call_6(struct ctx* ctx, struct fun_mut1_5 a, uint64_t p0) {
	return call_w_ctx_164(a, ctx, p0);
}
/* call-w-ctx<arr<char>, nat-64> (generated) (generated) */
struct arr_0 call_w_ctx_164(struct fun_mut1_5 a, struct ctx* ctx, uint64_t p0) {
	struct fun_mut1_5 match_fun2;
	struct map_0__lambda0* closure0;
	struct to_mut_arr__lambda0* closure1;
	match_fun2 = a;
	switch (match_fun2.kind) {
		case 0:
			closure0 = match_fun2.as0;
			return map_0__lambda0(ctx, closure0, p0);
		case 1:
			closure1 = match_fun2.as1;
			return to_mut_arr__lambda0(ctx, closure1, p0);
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
struct arr_0 call_7(struct ctx* ctx, struct fun_mut1_4 a, char* p0) {
	return call_w_ctx_167(a, ctx, p0);
}
/* call-w-ctx<arr<char>, raw-ptr(char)> (generated) (generated) */
struct arr_0 call_w_ctx_167(struct fun_mut1_4 a, struct ctx* ctx, char* p0) {
	struct fun_mut1_4 match_fun1;
	uint8_t closure0;
	match_fun1 = a;
	switch (match_fun1.kind) {
		case 0:
			closure0 = match_fun1.as0;
			return add_first_task__lambda0__lambda0(ctx, closure0, p0);
		default:
			return (assert(0),(struct arr_0) {0, NULL});
	}
}
/* at<?in> ptr<char>(a arr<ptr<char>>, index nat) */
char* at_1(struct ctx* ctx, struct arr_3 a, uint64_t index) {
	assert_0(ctx, _op_less_0(index, a.size));
	return noctx_at_1(a, index);
}
/* noctx-at<?t> ptr<char>(a arr<ptr<char>>, index nat) */
char* noctx_at_1(struct arr_3 a, uint64_t index) {
	hard_assert(_op_less_0(index, a.size));
	return (*((a.data + index)));
}
/* map<arr<char>, ptr<char>>.lambda0 arr<char>(i nat) */
struct arr_0 map_0__lambda0(struct ctx* ctx, struct map_0__lambda0* _closure, uint64_t i) {
	return call_7(ctx, _closure->mapper, at_1(ctx, _closure->a, i));
}
/* add-first-task.lambda0.lambda0 arr<char>(it ptr<char>) */
struct arr_0 add_first_task__lambda0__lambda0(struct ctx* ctx, uint8_t _closure, char* it) {
	return to_str_0(it);
}
/* add-first-task.lambda0 fut<int32>() */
struct fut_0* add_first_task__lambda0(struct ctx* ctx, struct add_first_task__lambda0* _closure) {
	struct arr_3 args0;
	args0 = tail_0(ctx, _closure->all_args);
	return _closure->main_ptr(ctx, map_0(ctx, args0, (struct fun_mut1_4) {0, .as0 = 0}));
}
/* do-main.lambda0 fut<int32>(all-args arr<ptr<char>>, main-ptr fun-ptr2<fut<int32>, ctx, arr<arr<char>>>) */
struct fut_0* do_main__lambda0(struct ctx* ctx, uint8_t _closure, struct arr_3 all_args, fun_ptr2 main_ptr) {
	return add_first_task(ctx, all_args, main_ptr);
}
/* call-w-ctx<gc-ptr(fut<int32>), arr<ptr<char>>, some fun ptr type> (generated) (generated) */
struct fut_0* call_w_ctx_174(struct fun2 a, struct ctx* ctx, struct arr_3 p0, fun_ptr2 p1) {
	struct fun2 match_fun1;
	uint8_t closure0;
	match_fun1 = a;
	switch (match_fun1.kind) {
		case 0:
			closure0 = match_fun1.as0;
			return do_main__lambda0(ctx, closure0, p0, p1);
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
			task_ok4 = (contains__q_0(exclusions3, task2.exclusion) ? 0 : (push_capacity_must_be_sufficient(exclusions3, task2.exclusion), 1));
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
uint8_t contains__q_0(struct mut_arr_0* a, uint64_t value) {
	return contains_recur__q_0(temp_as_arr(a), value, 0u);
}
/* contains-recur?<?t> bool(a arr<nat>, value nat, i nat) */
uint8_t contains_recur__q_0(struct arr_4 a, uint64_t value, uint64_t i) {
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
	hard_assert(_op_less_0(index, a.size));
	return (*((a.data + index)));
}
/* temp-as-arr<?t> arr<nat>(a mut-arr<nat>) */
struct arr_4 temp_as_arr(struct mut_arr_0* a) {
	return (struct arr_4) {a->size, a->data};
}
/* push-capacity-must-be-sufficient<nat> void(a mut-arr<nat>, value nat) */
uint8_t push_capacity_must_be_sufficient(struct mut_arr_0* a, uint64_t value) {
	uint64_t old_size0;
	hard_assert(_op_less_0(a->size, a->capacity));
	old_size0 = a->size;
	(a->size = noctx_incr(old_size0), 0);
	return noctx_set_at_1(a, old_size0, value);
}
/* noctx-set-at<?t> void(a mut-arr<nat>, index nat, value nat) */
uint8_t noctx_set_at_1(struct mut_arr_0* a, uint64_t index, uint64_t value) {
	hard_assert(_op_less_0(index, a->size));
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
	hard_assert(_op_less_0(index, a->size));
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
	return hard_assert(null__q_0(get_0((&(thread_return0)))));
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
uint8_t* get_0(struct cell_1* c) {
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
			return hard_unreachable_0();
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
struct result_0 hard_unreachable_0(void) {
	return (assert(0),(struct result_0) {0});
}
/* main fut<int32>(args arr<arr<char>>) */
struct fut_0* main_0(struct ctx* ctx, struct arr_1 args) {
	struct opt_9 options0;
	struct opt_9 temp0;
	struct some_9 s1;
	options0 = parse_cmd_line_args(ctx, args, (struct arr_1) {3, constantarr_1_0}, (struct fun1) {0, .as0 = 0});
	return resolved_1(ctx, (temp0 = options0, temp0.kind == 0 ? (print_help(ctx), 1) : temp0.kind == 1 ? (s1 = temp0.as1, do_test(ctx, s1.value)) : (assert(0),0)));
}
/* parse-cmd-line-args<test-options> opt<test-options>(args arr<arr<char>>, t-names arr<arr<char>>, make-t fun1<test-options, arr<opt<arr<arr<char>>>>>) */
struct opt_9 parse_cmd_line_args(struct ctx* ctx, struct arr_1 args, struct arr_1 t_names, struct fun1 make_t) {
	struct parsed_cmd_line_args* parsed0;
	struct mut_arr_3* values1;
	struct cell_2* help2;
	struct cell_2* temp0;
	struct parse_cmd_line_args__lambda0* temp1;
	parsed0 = parse_cmd_line_args_dynamic(ctx, args);
	assert_1(ctx, empty__q_6(parsed0->nameless), (struct arr_0) {26, constantarr_0_17});
	assert_0(ctx, empty__q_6(parsed0->after));
	values1 = fill_mut_arr(ctx, t_names.size, (struct opt_10) {0, .as0 = (struct none) {0}});
	help2 = (temp0 = (struct cell_2*) alloc(ctx, sizeof(struct cell_2)), ((*(temp0) = (struct cell_2) {0}, 0), temp0));
	each_0(ctx, parsed0->named, (struct fun_mut2_0) {0, .as0 = (temp1 = (struct parse_cmd_line_args__lambda0*) alloc(ctx, sizeof(struct parse_cmd_line_args__lambda0)), ((*(temp1) = (struct parse_cmd_line_args__lambda0) {t_names, help2, values1}, 0), temp1))});
	if (get_2(help2)) {
		return (struct opt_9) {0, .as0 = (struct none) {0}};
	} else {
		return (struct opt_9) {1, .as1 = (struct some_9) {call_12(ctx, make_t, freeze_4(values1))}};
	}
}
/* parse-cmd-line-args-dynamic parsed-cmd-line-args(args arr<arr<char>>) */
struct parsed_cmd_line_args* parse_cmd_line_args_dynamic(struct ctx* ctx, struct arr_1 args) {
	struct opt_11 temp0;
	struct parsed_cmd_line_args* temp1;
	struct some_11 s0;
	uint64_t first_named_arg_index1;
	struct arr_1 nameless2;
	struct arr_1 rest3;
	struct opt_11 temp2;
	struct parsed_cmd_line_args* temp3;
	struct some_11 s24;
	uint64_t sep_index5;
	struct dict_0* named_args6;
	struct parsed_cmd_line_args* temp4;
	temp0 = find_index(ctx, args, (struct fun_mut1_6) {0, .as0 = 0});
	switch (temp0.kind) {
		case 0:
			temp1 = (struct parsed_cmd_line_args*) alloc(ctx, sizeof(struct parsed_cmd_line_args));
			(*(temp1) = (struct parsed_cmd_line_args) {args, empty_dict(ctx), empty_arr_1()}, 0);
			return temp1;
		case 1:
			s0 = temp0.as1;
			first_named_arg_index1 = s0.value;
			nameless2 = slice_up_to_0(ctx, args, first_named_arg_index1);
			rest3 = slice_starting_at_2(ctx, args, first_named_arg_index1);
			temp2 = find_index(ctx, rest3, (struct fun_mut1_6) {1, .as1 = 0});
			switch (temp2.kind) {
				case 0:
					temp3 = (struct parsed_cmd_line_args*) alloc(ctx, sizeof(struct parsed_cmd_line_args));
					(*(temp3) = (struct parsed_cmd_line_args) {nameless2, parse_named_args(ctx, rest3), empty_arr_1()}, 0);
					return temp3;
				case 1:
					s24 = temp2.as1;
					sep_index5 = s24.value;
					named_args6 = parse_named_args(ctx, slice_up_to_0(ctx, rest3, sep_index5));
					temp4 = (struct parsed_cmd_line_args*) alloc(ctx, sizeof(struct parsed_cmd_line_args));
					(*(temp4) = (struct parsed_cmd_line_args) {nameless2, named_args6, slice_after_0(ctx, rest3, sep_index5)}, 0);
					return temp4;
				default:
					return (assert(0),NULL);
			}
		default:
			return (assert(0),NULL);
	}
}
/* find-index<arr<char>> opt<nat>(a arr<arr<char>>, pred fun-mut1<bool, arr<char>>) */
struct opt_11 find_index(struct ctx* ctx, struct arr_1 a, struct fun_mut1_6 pred) {
	return find_index_recur(ctx, a, 0u, pred);
}
/* find-index-recur<?t> opt<nat>(a arr<arr<char>>, index nat, pred fun-mut1<bool, arr<char>>) */
struct opt_11 find_index_recur(struct ctx* ctx, struct arr_1 a, uint64_t index, struct fun_mut1_6 pred) {
	struct arr_1 _tailCalla;
	uint64_t _tailCallindex;
	struct fun_mut1_6 _tailCallpred;
	top:
	if (_op_equal_equal_0(index, a.size)) {
		return (struct opt_11) {0, .as0 = (struct none) {0}};
	} else {
		if (call_8(ctx, pred, at_2(ctx, a, index))) {
			return (struct opt_11) {1, .as1 = (struct some_11) {index}};
		} else {
			_tailCalla = a;
			_tailCallindex = incr_3(ctx, index);
			_tailCallpred = pred;
			a = _tailCalla;
			index = _tailCallindex;
			pred = _tailCallpred;
			goto top;
		}
	}
}
/* call<bool, ?t> bool(a fun-mut1<bool, arr<char>>, p0 arr<char>) */
uint8_t call_8(struct ctx* ctx, struct fun_mut1_6 a, struct arr_0 p0) {
	return call_w_ctx_231(a, ctx, p0);
}
/* call-w-ctx<bool, arr<char>> (generated) (generated) */
uint8_t call_w_ctx_231(struct fun_mut1_6 a, struct ctx* ctx, struct arr_0 p0) {
	struct fun_mut1_6 match_fun7;
	uint8_t closure0;
	uint8_t closure1;
	uint8_t closure2;
	struct index_of__lambda0* closure3;
	uint8_t closure4;
	struct excluded_from_lint__q__lambda0* closure5;
	uint8_t closure6;
	match_fun7 = a;
	switch (match_fun7.kind) {
		case 0:
			closure0 = match_fun7.as0;
			return parse_cmd_line_args_dynamic__lambda0(ctx, closure0, p0);
		case 1:
			closure1 = match_fun7.as1;
			return parse_cmd_line_args_dynamic__lambda1(ctx, closure1, p0);
		case 2:
			closure2 = match_fun7.as2;
			return parse_named_args_recur__lambda0(ctx, closure2, p0);
		case 3:
			closure3 = match_fun7.as3;
			return index_of__lambda0(ctx, closure3, p0);
		case 4:
			closure4 = match_fun7.as4;
			return list_tests__lambda0(ctx, closure4, p0);
		case 5:
			closure5 = match_fun7.as5;
			return excluded_from_lint__q__lambda0(ctx, closure5, p0);
		case 6:
			closure6 = match_fun7.as6;
			return list_lintable_files__lambda0(ctx, closure6, p0);
		default:
			return (assert(0),0);
	}
}
/* at<?t> arr<char>(a arr<arr<char>>, index nat) */
struct arr_0 at_2(struct ctx* ctx, struct arr_1 a, uint64_t index) {
	assert_0(ctx, _op_less_0(index, a.size));
	return noctx_at_4(a, index);
}
/* noctx-at<?t> arr<char>(a arr<arr<char>>, index nat) */
struct arr_0 noctx_at_4(struct arr_1 a, uint64_t index) {
	hard_assert(_op_less_0(index, a.size));
	return (*((a.data + index)));
}
/* starts-with?<char> bool(a arr<char>, start arr<char>) */
uint8_t starts_with__q(struct ctx* ctx, struct arr_0 a, struct arr_0 start) {
	return (_op_greater_equal(a.size, start.size) && arr_eq__q(ctx, slice_1(ctx, a, 0u, start.size), start));
}
/* arr-eq?<?t> bool(a arr<char>, b arr<char>) */
uint8_t arr_eq__q(struct ctx* ctx, struct arr_0 a, struct arr_0 b) {
	struct arr_0 _tailCalla;
	struct arr_0 _tailCallb;
	top:
	if (_op_equal_equal_0(a.size, b.size)) {
		if (empty__q_0(a)) {
			return 1;
		} else {
			if (_op_equal_equal_1(first_0(ctx, a), first_0(ctx, b))) {
				_tailCalla = tail_1(ctx, a);
				_tailCallb = tail_1(ctx, b);
				a = _tailCalla;
				b = _tailCallb;
				goto top;
			} else {
				return 0;
			}
		}
	} else {
		return 0;
	}
}
/* first<?t> char(a arr<char>) */
char first_0(struct ctx* ctx, struct arr_0 a) {
	forbid_0(ctx, empty__q_0(a));
	return at_3(ctx, a, 0u);
}
/* at<?t> char(a arr<char>, index nat) */
char at_3(struct ctx* ctx, struct arr_0 a, uint64_t index) {
	assert_0(ctx, _op_less_0(index, a.size));
	return noctx_at_5(a, index);
}
/* noctx-at<?t> char(a arr<char>, index nat) */
char noctx_at_5(struct arr_0 a, uint64_t index) {
	hard_assert(_op_less_0(index, a.size));
	return (*((a.data + index)));
}
/* tail<?t> arr<char>(a arr<char>) */
struct arr_0 tail_1(struct ctx* ctx, struct arr_0 a) {
	forbid_0(ctx, empty__q_0(a));
	return slice_starting_at_1(ctx, a, 1u);
}
/* slice-starting-at<?t> arr<char>(a arr<char>, begin nat) */
struct arr_0 slice_starting_at_1(struct ctx* ctx, struct arr_0 a, uint64_t begin) {
	assert_0(ctx, _op_less_equal(begin, a.size));
	return slice_1(ctx, a, begin, _op_minus_2(ctx, a.size, begin));
}
/* slice<?t> arr<char>(a arr<char>, begin nat, size nat) */
struct arr_0 slice_1(struct ctx* ctx, struct arr_0 a, uint64_t begin, uint64_t size) {
	assert_0(ctx, _op_less_equal(_op_plus_0(ctx, begin, size), a.size));
	return (struct arr_0) {size, (a.data + begin)};
}
/* parse-cmd-line-args-dynamic.lambda0 bool(it arr<char>) */
uint8_t parse_cmd_line_args_dynamic__lambda0(struct ctx* ctx, uint8_t _closure, struct arr_0 it) {
	return starts_with__q(ctx, it, (struct arr_0) {2, constantarr_0_15});
}
/* empty-dict<arr<char>, arr<arr<char>>> dict<arr<char>, arr<arr<char>>>() */
struct dict_0* empty_dict(struct ctx* ctx) {
	struct dict_0* temp0;
	temp0 = (struct dict_0*) alloc(ctx, sizeof(struct dict_0));
	(*(temp0) = (struct dict_0) {empty_arr_1(), empty_arr_2()}, 0);
	return temp0;
}
/* empty-arr<?k> arr<arr<char>>() */
struct arr_1 empty_arr_1(void) {
	return (struct arr_1) {0u, NULL};
}
/* empty-arr<?v> arr<arr<arr<char>>>() */
struct arr_6 empty_arr_2(void) {
	return (struct arr_6) {0u, NULL};
}
/* slice-up-to<arr<char>> arr<arr<char>>(a arr<arr<char>>, size nat) */
struct arr_1 slice_up_to_0(struct ctx* ctx, struct arr_1 a, uint64_t size) {
	assert_0(ctx, _op_less_0(size, a.size));
	return slice_2(ctx, a, 0u, size);
}
/* slice<?t> arr<arr<char>>(a arr<arr<char>>, begin nat, size nat) */
struct arr_1 slice_2(struct ctx* ctx, struct arr_1 a, uint64_t begin, uint64_t size) {
	assert_0(ctx, _op_less_equal(_op_plus_0(ctx, begin, size), a.size));
	return (struct arr_1) {size, (a.data + begin)};
}
/* slice-starting-at<arr<char>> arr<arr<char>>(a arr<arr<char>>, begin nat) */
struct arr_1 slice_starting_at_2(struct ctx* ctx, struct arr_1 a, uint64_t begin) {
	assert_0(ctx, _op_less_equal(begin, a.size));
	return slice_2(ctx, a, begin, _op_minus_2(ctx, a.size, begin));
}
/* ==<arr<char>> bool(a arr<char>, b arr<char>) */
uint8_t _op_equal_equal_4(struct arr_0 a, struct arr_0 b) {
	struct comparison temp0;
	temp0 = compare_250(a, b);
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
/* compare<arr<char>> (generated) (generated) */
struct comparison compare_250(struct arr_0 a, struct arr_0 b) {
	struct comparison temp0;
	struct arr_0 _tailCalla;
	struct arr_0 _tailCallb;
	top:
	if ((a.size == 0u)) {
		if ((b.size == 0u)) {
			return (struct comparison) {1, .as1 = (struct equal) {0}};
		} else {
			return (struct comparison) {0, .as0 = (struct less) {0}};
		}
	} else {
		if ((b.size == 0u)) {
			return (struct comparison) {2, .as2 = (struct greater) {0}};
		} else {
			temp0 = compare_22((*(a.data)), (*(b.data)));
			switch (temp0.kind) {
				case 0:
					return (struct comparison) {0, .as0 = (struct less) {0}};
				case 1:
					_tailCalla = (struct arr_0) {(a.size - 1u), (a.data + 1u)};
					_tailCallb = (struct arr_0) {(b.size - 1u), (b.data + 1u)};
					a = _tailCalla;
					b = _tailCallb;
					goto top;
				case 2:
					return (struct comparison) {2, .as2 = (struct greater) {0}};
				default:
					return (assert(0),(struct comparison) {0});
			}
		}
	}
}
/* parse-cmd-line-args-dynamic.lambda1 bool(it arr<char>) */
uint8_t parse_cmd_line_args_dynamic__lambda1(struct ctx* ctx, uint8_t _closure, struct arr_0 it) {
	return _op_equal_equal_4(it, (struct arr_0) {2, constantarr_0_15});
}
/* parse-named-args dict<arr<char>, arr<arr<char>>>(args arr<arr<char>>) */
struct dict_0* parse_named_args(struct ctx* ctx, struct arr_1 args) {
	struct mut_dict_0 b0;
	b0 = new_mut_dict_0(ctx);
	parse_named_args_recur(ctx, args, b0);
	return freeze_1(ctx, b0);
}
/* new-mut-dict<arr<char>, arr<arr<char>>> mut-dict<arr<char>, arr<arr<char>>>() */
struct mut_dict_0 new_mut_dict_0(struct ctx* ctx) {
	return (struct mut_dict_0) {new_mut_arr_0(ctx), new_mut_arr_1(ctx)};
}
/* new-mut-arr<?k> mut-arr<arr<char>>() */
struct mut_arr_1* new_mut_arr_0(struct ctx* ctx) {
	struct mut_arr_1* temp0;
	temp0 = (struct mut_arr_1*) alloc(ctx, sizeof(struct mut_arr_1));
	(*(temp0) = (struct mut_arr_1) {0, 0u, 0u, NULL}, 0);
	return temp0;
}
/* new-mut-arr<?v> mut-arr<arr<arr<char>>>() */
struct mut_arr_2* new_mut_arr_1(struct ctx* ctx) {
	struct mut_arr_2* temp0;
	temp0 = (struct mut_arr_2*) alloc(ctx, sizeof(struct mut_arr_2));
	(*(temp0) = (struct mut_arr_2) {0, 0u, 0u, NULL}, 0);
	return temp0;
}
/* parse-named-args-recur void(args arr<arr<char>>, builder mut-dict<arr<char>, arr<arr<char>>>) */
uint8_t parse_named_args_recur(struct ctx* ctx, struct arr_1 args, struct mut_dict_0 builder) {
	struct arr_0 first_name0;
	struct arr_1 tl1;
	struct opt_11 temp0;
	struct some_11 s2;
	uint64_t next_named_arg_index3;
	struct arr_1 _tailCallargs;
	struct mut_dict_0 _tailCallbuilder;
	top:
	first_name0 = remove_start(ctx, first_1(ctx, args), (struct arr_0) {2, constantarr_0_15});
	tl1 = tail_2(ctx, args);
	temp0 = find_index(ctx, tl1, (struct fun_mut1_6) {2, .as2 = 0});
	switch (temp0.kind) {
		case 0:
			return add_1(ctx, builder, first_name0, tl1);
		case 1:
			s2 = temp0.as1;
			next_named_arg_index3 = s2.value;
			add_1(ctx, builder, first_name0, slice_up_to_0(ctx, tl1, next_named_arg_index3));
			_tailCallargs = slice_starting_at_2(ctx, args, next_named_arg_index3);
			_tailCallbuilder = builder;
			args = _tailCallargs;
			builder = _tailCallbuilder;
			goto top;
		default:
			return (assert(0),0);
	}
}
/* remove-start<char> arr<char>(a arr<char>, start arr<char>) */
struct arr_0 remove_start(struct ctx* ctx, struct arr_0 a, struct arr_0 start) {
	return force_0(ctx, try_remove_start(ctx, a, start));
}
/* force<arr<?t>> arr<char>(a opt<arr<char>>) */
struct arr_0 force_0(struct ctx* ctx, struct opt_12 a) {
	struct opt_12 temp0;
	struct some_12 s0;
	temp0 = a;
	switch (temp0.kind) {
		case 0:
			return fail_1(ctx, (struct arr_0) {27, constantarr_0_16});
		case 1:
			s0 = temp0.as1;
			return s0.value;
		default:
			return (assert(0),(struct arr_0) {0, NULL});
	}
}
/* fail<?t> arr<char>(reason arr<char>) */
struct arr_0 fail_1(struct ctx* ctx, struct arr_0 reason) {
	return throw_1(ctx, (struct exception) {reason});
}
/* throw<?t> arr<char>(e exception) */
struct arr_0 throw_1(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx0;
	exn_ctx0 = get_exception_ctx(ctx);
	hard_forbid(null__q_1(exn_ctx0->jmp_buf_ptr));
	(exn_ctx0->thrown_exception = e, 0);
	(longjmp(exn_ctx0->jmp_buf_ptr, number_to_throw(ctx)), 0);
	return todo_3();
}
/* todo<?t> arr<char>() */
struct arr_0 todo_3(void) {
	return (assert(0),(struct arr_0) {0, NULL});
}
/* try-remove-start<?t> opt<arr<char>>(a arr<char>, start arr<char>) */
struct opt_12 try_remove_start(struct ctx* ctx, struct arr_0 a, struct arr_0 start) {
	if (starts_with__q(ctx, a, start)) {
		return (struct opt_12) {1, .as1 = (struct some_12) {slice_starting_at_1(ctx, a, start.size)}};
	} else {
		return (struct opt_12) {0, .as0 = (struct none) {0}};
	}
}
/* first<arr<char>> arr<char>(a arr<arr<char>>) */
struct arr_0 first_1(struct ctx* ctx, struct arr_1 a) {
	forbid_0(ctx, empty__q_6(a));
	return at_2(ctx, a, 0u);
}
/* empty?<?t> bool(a arr<arr<char>>) */
uint8_t empty__q_6(struct arr_1 a) {
	return _op_equal_equal_0(a.size, 0u);
}
/* tail<arr<char>> arr<arr<char>>(a arr<arr<char>>) */
struct arr_1 tail_2(struct ctx* ctx, struct arr_1 a) {
	forbid_0(ctx, empty__q_6(a));
	return slice_starting_at_2(ctx, a, 1u);
}
/* parse-named-args-recur.lambda0 bool(it arr<char>) */
uint8_t parse_named_args_recur__lambda0(struct ctx* ctx, uint8_t _closure, struct arr_0 it) {
	return starts_with__q(ctx, it, (struct arr_0) {2, constantarr_0_15});
}
/* add<arr<char>, arr<arr<char>>> void(m mut-dict<arr<char>, arr<arr<char>>>, key arr<char>, value arr<arr<char>>) */
uint8_t add_1(struct ctx* ctx, struct mut_dict_0 m, struct arr_0 key, struct arr_1 value) {
	forbid_0(ctx, has__q_0(ctx, m, key));
	push_0(ctx, m.keys, key);
	return push_1(ctx, m.values, value);
}
/* has?<?k, ?v> bool(d mut-dict<arr<char>, arr<arr<char>>>, key arr<char>) */
uint8_t has__q_0(struct ctx* ctx, struct mut_dict_0 d, struct arr_0 key) {
	return has__q_1(ctx, unsafe_as_dict_0(ctx, d), key);
}
/* has?<?k, ?v> bool(d dict<arr<char>, arr<arr<char>>>, key arr<char>) */
uint8_t has__q_1(struct ctx* ctx, struct dict_0* d, struct arr_0 key) {
	return has__q_2(get_1(ctx, d, key));
}
/* has?<?v> bool(a opt<arr<arr<char>>>) */
uint8_t has__q_2(struct opt_10 a) {
	return !empty__q_7(a);
}
/* empty?<?t> bool(a opt<arr<arr<char>>>) */
uint8_t empty__q_7(struct opt_10 a) {
	struct opt_10 temp0;
	struct none n0;
	struct some_10 s1;
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
/* get<?v, ?k> opt<arr<arr<char>>>(d dict<arr<char>, arr<arr<char>>>, key arr<char>) */
struct opt_10 get_1(struct ctx* ctx, struct dict_0* d, struct arr_0 key) {
	return get_recursive_0(ctx, d->keys, d->values, 0u, key);
}
/* get-recursive<?k, ?v> opt<arr<arr<char>>>(keys arr<arr<char>>, values arr<arr<arr<char>>>, idx nat, key arr<char>) */
struct opt_10 get_recursive_0(struct ctx* ctx, struct arr_1 keys, struct arr_6 values, uint64_t idx, struct arr_0 key) {
	struct arr_1 _tailCallkeys;
	struct arr_6 _tailCallvalues;
	uint64_t _tailCallidx;
	struct arr_0 _tailCallkey;
	top:
	if (_op_equal_equal_0(idx, keys.size)) {
		return (struct opt_10) {0, .as0 = (struct none) {0}};
	} else {
		if (_op_equal_equal_4(key, at_2(ctx, keys, idx))) {
			return (struct opt_10) {1, .as1 = (struct some_10) {at_4(ctx, values, idx)}};
		} else {
			_tailCallkeys = keys;
			_tailCallvalues = values;
			_tailCallidx = incr_3(ctx, idx);
			_tailCallkey = key;
			keys = _tailCallkeys;
			values = _tailCallvalues;
			idx = _tailCallidx;
			key = _tailCallkey;
			goto top;
		}
	}
}
/* at<?v> arr<arr<char>>(a arr<arr<arr<char>>>, index nat) */
struct arr_1 at_4(struct ctx* ctx, struct arr_6 a, uint64_t index) {
	assert_0(ctx, _op_less_0(index, a.size));
	return noctx_at_6(a, index);
}
/* noctx-at<?t> arr<arr<char>>(a arr<arr<arr<char>>>, index nat) */
struct arr_1 noctx_at_6(struct arr_6 a, uint64_t index) {
	hard_assert(_op_less_0(index, a.size));
	return (*((a.data + index)));
}
/* unsafe-as-dict<?k, ?v> dict<arr<char>, arr<arr<char>>>(m mut-dict<arr<char>, arr<arr<char>>>) */
struct dict_0* unsafe_as_dict_0(struct ctx* ctx, struct mut_dict_0 m) {
	struct dict_0* temp0;
	temp0 = (struct dict_0*) alloc(ctx, sizeof(struct dict_0));
	(*(temp0) = (struct dict_0) {unsafe_as_arr_0(m.keys), unsafe_as_arr_1(m.values)}, 0);
	return temp0;
}
/* unsafe-as-arr<?v> arr<arr<arr<char>>>(a mut-arr<arr<arr<char>>>) */
struct arr_6 unsafe_as_arr_1(struct mut_arr_2* a) {
	return (struct arr_6) {a->size, a->data};
}
/* push<?k> void(a mut-arr<arr<char>>, value arr<char>) */
uint8_t push_0(struct ctx* ctx, struct mut_arr_1* a, struct arr_0 value) {
	if (_op_equal_equal_0(a->size, a->capacity)) {
		increase_capacity_to_0(ctx, a, (_op_equal_equal_0(a->size, 0u) ? 4u : _op_times_0(ctx, a->size, 2u)));
	} else {
		0;
	}
	ensure_capacity_0(ctx, a, round_up_to_power_of_two(ctx, incr_3(ctx, a->size)));
	assert_0(ctx, _op_less_0(a->size, a->capacity));
	(*((a->data + a->size)) = value, 0);
	return (a->size = incr_3(ctx, a->size), 0);
}
/* increase-capacity-to<?t> void(a mut-arr<arr<char>>, new-capacity nat) */
uint8_t increase_capacity_to_0(struct ctx* ctx, struct mut_arr_1* a, uint64_t new_capacity) {
	struct arr_0* old_data0;
	assert_0(ctx, _op_greater(new_capacity, a->capacity));
	old_data0 = a->data;
	(a->capacity = new_capacity, 0);
	(a->data = uninitialized_data_0(ctx, new_capacity), 0);
	return copy_data_from_0(ctx, a->data, old_data0, a->size);
}
/* copy-data-from<?t> void(to ptr<arr<char>>, from ptr<arr<char>>, len nat) */
uint8_t copy_data_from_0(struct ctx* ctx, struct arr_0* to, struct arr_0* from, uint64_t len) {
	uint64_t hl0;
	struct arr_0* _tailCallto;
	struct arr_0* _tailCallfrom;
	uint64_t _tailCalllen;
	top:
	if (_op_less_0(len, 8u)) {
		return copy_data_from_small_0(ctx, to, from, len);
	} else {
		hl0 = _op_div(ctx, len, 2u);
		copy_data_from_0(ctx, to, from, hl0);
		_tailCallto = (to + hl0);
		_tailCallfrom = (from + hl0);
		_tailCalllen = _op_minus_2(ctx, len, hl0);
		to = _tailCallto;
		from = _tailCallfrom;
		len = _tailCalllen;
		goto top;
	}
}
/* copy-data-from-small<?t> void(to ptr<arr<char>>, from ptr<arr<char>>, len nat) */
uint8_t copy_data_from_small_0(struct ctx* ctx, struct arr_0* to, struct arr_0* from, uint64_t len) {
	if (_op_bang_equal_0(len, 0u)) {
		(*(to) = (*(from)), 0);
		return copy_data_from_0(ctx, incr_4(to), incr_4(from), decr(ctx, len));
	} else {
		return 0;
	}
}
/* incr<?t> ptr<arr<char>>(p ptr<arr<char>>) */
struct arr_0* incr_4(struct arr_0* p) {
	return (p + 1u);
}
/* decr nat(a nat) */
uint64_t decr(struct ctx* ctx, uint64_t a) {
	forbid_0(ctx, _op_equal_equal_0(a, 0u));
	return wrap_decr(a);
}
/* wrap-decr nat(a nat) */
uint64_t wrap_decr(uint64_t a) {
	return (a - 1u);
}
/* / nat(a nat, b nat) */
uint64_t _op_div(struct ctx* ctx, uint64_t a, uint64_t b) {
	forbid_0(ctx, _op_equal_equal_0(b, 0u));
	return (a / b);
}
/* * nat(a nat, b nat) */
uint64_t _op_times_0(struct ctx* ctx, uint64_t a, uint64_t b) {
	uint64_t res0;
	if ((_op_equal_equal_0(a, 0u) || _op_equal_equal_0(b, 0u))) {
		return 0u;
	} else {
		res0 = (a * b);
		assert_0(ctx, _op_equal_equal_0(_op_div(ctx, res0, b), a));
		assert_0(ctx, _op_equal_equal_0(_op_div(ctx, res0, a), b));
		return res0;
	}
}
/* ensure-capacity<?t> void(a mut-arr<arr<char>>, capacity nat) */
uint8_t ensure_capacity_0(struct ctx* ctx, struct mut_arr_1* a, uint64_t capacity) {
	if (_op_less_0(a->capacity, capacity)) {
		return increase_capacity_to_0(ctx, a, round_up_to_power_of_two(ctx, capacity));
	} else {
		return 0;
	}
}
/* round-up-to-power-of-two nat(n nat) */
uint64_t round_up_to_power_of_two(struct ctx* ctx, uint64_t n) {
	return round_up_to_power_of_two_recur(ctx, 1u, n);
}
/* round-up-to-power-of-two-recur nat(acc nat, n nat) */
uint64_t round_up_to_power_of_two_recur(struct ctx* ctx, uint64_t acc, uint64_t n) {
	uint64_t _tailCallacc;
	uint64_t _tailCalln;
	top:
	if (_op_greater_equal(acc, n)) {
		return acc;
	} else {
		_tailCallacc = _op_times_0(ctx, acc, 2u);
		_tailCalln = n;
		acc = _tailCallacc;
		n = _tailCalln;
		goto top;
	}
}
/* push<?v> void(a mut-arr<arr<arr<char>>>, value arr<arr<char>>) */
uint8_t push_1(struct ctx* ctx, struct mut_arr_2* a, struct arr_1 value) {
	if (_op_equal_equal_0(a->size, a->capacity)) {
		increase_capacity_to_1(ctx, a, (_op_equal_equal_0(a->size, 0u) ? 4u : _op_times_0(ctx, a->size, 2u)));
	} else {
		0;
	}
	ensure_capacity_1(ctx, a, round_up_to_power_of_two(ctx, incr_3(ctx, a->size)));
	assert_0(ctx, _op_less_0(a->size, a->capacity));
	(*((a->data + a->size)) = value, 0);
	return (a->size = incr_3(ctx, a->size), 0);
}
/* increase-capacity-to<?t> void(a mut-arr<arr<arr<char>>>, new-capacity nat) */
uint8_t increase_capacity_to_1(struct ctx* ctx, struct mut_arr_2* a, uint64_t new_capacity) {
	struct arr_1* old_data0;
	assert_0(ctx, _op_greater(new_capacity, a->capacity));
	old_data0 = a->data;
	(a->capacity = new_capacity, 0);
	(a->data = uninitialized_data_1(ctx, new_capacity), 0);
	return copy_data_from_1(ctx, a->data, old_data0, a->size);
}
/* uninitialized-data<?t> ptr<arr<arr<char>>>(size nat) */
struct arr_1* uninitialized_data_1(struct ctx* ctx, uint64_t size) {
	uint8_t* bptr0;
	bptr0 = alloc(ctx, (size * sizeof(struct arr_1)));
	return (struct arr_1*) bptr0;
}
/* copy-data-from<?t> void(to ptr<arr<arr<char>>>, from ptr<arr<arr<char>>>, len nat) */
uint8_t copy_data_from_1(struct ctx* ctx, struct arr_1* to, struct arr_1* from, uint64_t len) {
	uint64_t hl0;
	struct arr_1* _tailCallto;
	struct arr_1* _tailCallfrom;
	uint64_t _tailCalllen;
	top:
	if (_op_less_0(len, 8u)) {
		return copy_data_from_small_1(ctx, to, from, len);
	} else {
		hl0 = _op_div(ctx, len, 2u);
		copy_data_from_1(ctx, to, from, hl0);
		_tailCallto = (to + hl0);
		_tailCallfrom = (from + hl0);
		_tailCalllen = _op_minus_2(ctx, len, hl0);
		to = _tailCallto;
		from = _tailCallfrom;
		len = _tailCalllen;
		goto top;
	}
}
/* copy-data-from-small<?t> void(to ptr<arr<arr<char>>>, from ptr<arr<arr<char>>>, len nat) */
uint8_t copy_data_from_small_1(struct ctx* ctx, struct arr_1* to, struct arr_1* from, uint64_t len) {
	if (_op_bang_equal_0(len, 0u)) {
		(*(to) = (*(from)), 0);
		return copy_data_from_1(ctx, incr_5(to), incr_5(from), decr(ctx, len));
	} else {
		return 0;
	}
}
/* incr<?t> ptr<arr<arr<char>>>(p ptr<arr<arr<char>>>) */
struct arr_1* incr_5(struct arr_1* p) {
	return (p + 1u);
}
/* ensure-capacity<?t> void(a mut-arr<arr<arr<char>>>, capacity nat) */
uint8_t ensure_capacity_1(struct ctx* ctx, struct mut_arr_2* a, uint64_t capacity) {
	if (_op_less_0(a->capacity, capacity)) {
		return increase_capacity_to_1(ctx, a, round_up_to_power_of_two(ctx, capacity));
	} else {
		return 0;
	}
}
/* freeze<arr<char>, arr<arr<char>>> dict<arr<char>, arr<arr<char>>>(m mut-dict<arr<char>, arr<arr<char>>>) */
struct dict_0* freeze_1(struct ctx* ctx, struct mut_dict_0 m) {
	struct dict_0* temp0;
	temp0 = (struct dict_0*) alloc(ctx, sizeof(struct dict_0));
	(*(temp0) = (struct dict_0) {freeze_0(m.keys), freeze_2(m.values)}, 0);
	return temp0;
}
/* freeze<?v> arr<arr<arr<char>>>(a mut-arr<arr<arr<char>>>) */
struct arr_6 freeze_2(struct mut_arr_2* a) {
	(a->frozen__q = 1, 0);
	return unsafe_as_arr_1(a);
}
/* slice-after<arr<char>> arr<arr<char>>(a arr<arr<char>>, before-begin nat) */
struct arr_1 slice_after_0(struct ctx* ctx, struct arr_1 a, uint64_t before_begin) {
	return slice_starting_at_2(ctx, a, incr_3(ctx, before_begin));
}
/* fill-mut-arr<opt<arr<arr<char>>>> mut-arr<opt<arr<arr<char>>>>(size nat, value opt<arr<arr<char>>>) */
struct mut_arr_3* fill_mut_arr(struct ctx* ctx, uint64_t size, struct opt_10 value) {
	struct fill_mut_arr__lambda0* temp0;
	return make_mut_arr_1(ctx, size, (struct fun_mut1_7) {0, .as0 = (temp0 = (struct fill_mut_arr__lambda0*) alloc(ctx, sizeof(struct fill_mut_arr__lambda0)), ((*(temp0) = (struct fill_mut_arr__lambda0) {value}, 0), temp0))});
}
/* make-mut-arr<?t> mut-arr<opt<arr<arr<char>>>>(size nat, f fun-mut1<opt<arr<arr<char>>>, nat>) */
struct mut_arr_3* make_mut_arr_1(struct ctx* ctx, uint64_t size, struct fun_mut1_7 f) {
	struct mut_arr_3* res0;
	res0 = new_uninitialized_mut_arr_1(ctx, size);
	make_mut_arr_worker_1(ctx, res0, 0u, f);
	return res0;
}
/* new-uninitialized-mut-arr<?t> mut-arr<opt<arr<arr<char>>>>(size nat) */
struct mut_arr_3* new_uninitialized_mut_arr_1(struct ctx* ctx, uint64_t size) {
	struct mut_arr_3* temp0;
	temp0 = (struct mut_arr_3*) alloc(ctx, sizeof(struct mut_arr_3));
	(*(temp0) = (struct mut_arr_3) {0, size, size, uninitialized_data_2(ctx, size)}, 0);
	return temp0;
}
/* uninitialized-data<?t> ptr<opt<arr<arr<char>>>>(size nat) */
struct opt_10* uninitialized_data_2(struct ctx* ctx, uint64_t size) {
	uint8_t* bptr0;
	bptr0 = alloc(ctx, (size * sizeof(struct opt_10)));
	return (struct opt_10*) bptr0;
}
/* make-mut-arr-worker<?t> void(m mut-arr<opt<arr<arr<char>>>>, i nat, f fun-mut1<opt<arr<arr<char>>>, nat>) */
uint8_t make_mut_arr_worker_1(struct ctx* ctx, struct mut_arr_3* m, uint64_t i, struct fun_mut1_7 f) {
	struct mut_arr_3* _tailCallm;
	uint64_t _tailCalli;
	struct fun_mut1_7 _tailCallf;
	top:
	if (_op_bang_equal_0(i, m->size)) {
		set_at_1(ctx, m, i, call_9(ctx, f, i));
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
/* set-at<?t> void(a mut-arr<opt<arr<arr<char>>>>, index nat, value opt<arr<arr<char>>>) */
uint8_t set_at_1(struct ctx* ctx, struct mut_arr_3* a, uint64_t index, struct opt_10 value) {
	assert_0(ctx, _op_less_0(index, a->size));
	return noctx_set_at_2(a, index, value);
}
/* noctx-set-at<?t> void(a mut-arr<opt<arr<arr<char>>>>, index nat, value opt<arr<arr<char>>>) */
uint8_t noctx_set_at_2(struct mut_arr_3* a, uint64_t index, struct opt_10 value) {
	hard_assert(_op_less_0(index, a->size));
	return (*((a->data + index)) = value, 0);
}
/* call<?t, nat> opt<arr<arr<char>>>(a fun-mut1<opt<arr<arr<char>>>, nat>, p0 nat) */
struct opt_10 call_9(struct ctx* ctx, struct fun_mut1_7 a, uint64_t p0) {
	return call_w_ctx_308(a, ctx, p0);
}
/* call-w-ctx<opt<arr<arr<char>>>, nat-64> (generated) (generated) */
struct opt_10 call_w_ctx_308(struct fun_mut1_7 a, struct ctx* ctx, uint64_t p0) {
	struct fun_mut1_7 match_fun1;
	struct fill_mut_arr__lambda0* closure0;
	match_fun1 = a;
	switch (match_fun1.kind) {
		case 0:
			closure0 = match_fun1.as0;
			return fill_mut_arr__lambda0(ctx, closure0, p0);
		default:
			return (assert(0),(struct opt_10) {0});
	}
}
/* fill-mut-arr<opt<arr<arr<char>>>>.lambda0 opt<arr<arr<char>>>(ignore nat) */
struct opt_10 fill_mut_arr__lambda0(struct ctx* ctx, struct fill_mut_arr__lambda0* _closure, uint64_t ignore) {
	return _closure->value;
}
/* each<arr<char>, arr<arr<char>>> void(d dict<arr<char>, arr<arr<char>>>, f fun-mut2<void, arr<char>, arr<arr<char>>>) */
uint8_t each_0(struct ctx* ctx, struct dict_0* d, struct fun_mut2_0 f) {
	struct dict_0* temp0;
	struct dict_0* _tailCalld;
	struct fun_mut2_0 _tailCallf;
	top:
	if (!empty__q_8(ctx, d)) {
		call_10(ctx, f, first_1(ctx, d->keys), first_2(ctx, d->values));
		_tailCalld = (temp0 = (struct dict_0*) alloc(ctx, sizeof(struct dict_0)), ((*(temp0) = (struct dict_0) {tail_2(ctx, d->keys), tail_3(ctx, d->values)}, 0), temp0));
		_tailCallf = f;
		d = _tailCalld;
		f = _tailCallf;
		goto top;
	} else {
		return 0;
	}
}
/* empty?<?k, ?v> bool(d dict<arr<char>, arr<arr<char>>>) */
uint8_t empty__q_8(struct ctx* ctx, struct dict_0* d) {
	return empty__q_6(d->keys);
}
/* call<void, ?k, ?v> void(a fun-mut2<void, arr<char>, arr<arr<char>>>, p0 arr<char>, p1 arr<arr<char>>) */
uint8_t call_10(struct ctx* ctx, struct fun_mut2_0 a, struct arr_0 p0, struct arr_1 p1) {
	return call_w_ctx_313(a, ctx, p0, p1);
}
/* call-w-ctx<void, arr<char>, arr<arr<char>>> (generated) (generated) */
uint8_t call_w_ctx_313(struct fun_mut2_0 a, struct ctx* ctx, struct arr_0 p0, struct arr_1 p1) {
	struct fun_mut2_0 match_fun1;
	struct parse_cmd_line_args__lambda0* closure0;
	match_fun1 = a;
	switch (match_fun1.kind) {
		case 0:
			closure0 = match_fun1.as0;
			return parse_cmd_line_args__lambda0(ctx, closure0, p0, p1);
		default:
			return (assert(0),0);
	}
}
/* first<?v> arr<arr<char>>(a arr<arr<arr<char>>>) */
struct arr_1 first_2(struct ctx* ctx, struct arr_6 a) {
	forbid_0(ctx, empty__q_9(a));
	return at_4(ctx, a, 0u);
}
/* empty?<?t> bool(a arr<arr<arr<char>>>) */
uint8_t empty__q_9(struct arr_6 a) {
	return _op_equal_equal_0(a.size, 0u);
}
/* tail<?v> arr<arr<arr<char>>>(a arr<arr<arr<char>>>) */
struct arr_6 tail_3(struct ctx* ctx, struct arr_6 a) {
	forbid_0(ctx, empty__q_9(a));
	return slice_starting_at_3(ctx, a, 1u);
}
/* slice-starting-at<?t> arr<arr<arr<char>>>(a arr<arr<arr<char>>>, begin nat) */
struct arr_6 slice_starting_at_3(struct ctx* ctx, struct arr_6 a, uint64_t begin) {
	assert_0(ctx, _op_less_equal(begin, a.size));
	return slice_3(ctx, a, begin, _op_minus_2(ctx, a.size, begin));
}
/* slice<?t> arr<arr<arr<char>>>(a arr<arr<arr<char>>>, begin nat, size nat) */
struct arr_6 slice_3(struct ctx* ctx, struct arr_6 a, uint64_t begin, uint64_t size) {
	assert_0(ctx, _op_less_equal(_op_plus_0(ctx, begin, size), a.size));
	return (struct arr_6) {size, (a.data + begin)};
}
/* index-of<arr<char>> opt<nat>(a arr<arr<char>>, value arr<char>) */
struct opt_11 index_of(struct ctx* ctx, struct arr_1 a, struct arr_0 value) {
	struct index_of__lambda0* temp0;
	return find_index(ctx, a, (struct fun_mut1_6) {3, .as3 = (temp0 = (struct index_of__lambda0*) alloc(ctx, sizeof(struct index_of__lambda0)), ((*(temp0) = (struct index_of__lambda0) {value}, 0), temp0))});
}
/* index-of<arr<char>>.lambda0 bool(it arr<char>) */
uint8_t index_of__lambda0(struct ctx* ctx, struct index_of__lambda0* _closure, struct arr_0 it) {
	return _op_equal_equal_4(it, _closure->value);
}
/* set<bool> void(c cell<bool>, v bool) */
uint8_t set_0(struct cell_2* c, uint8_t v) {
	return (c->value = v, 0);
}
/* +<char> arr<char>(a arr<char>, b arr<char>) */
struct arr_0 _op_plus_1(struct ctx* ctx, struct arr_0 a, struct arr_0 b) {
	struct _op_plus_1__lambda0* temp0;
	return make_arr_1(ctx, _op_plus_0(ctx, a.size, b.size), (struct fun_mut1_8) {0, .as0 = (temp0 = (struct _op_plus_1__lambda0*) alloc(ctx, sizeof(struct _op_plus_1__lambda0)), ((*(temp0) = (struct _op_plus_1__lambda0) {a, b}, 0), temp0))});
}
/* make-arr<?t> arr<char>(size nat, f fun-mut1<char, nat>) */
struct arr_0 make_arr_1(struct ctx* ctx, uint64_t size, struct fun_mut1_8 f) {
	return freeze_3(make_mut_arr_2(ctx, size, f));
}
/* freeze<?t> arr<char>(a mut-arr<char>) */
struct arr_0 freeze_3(struct mut_arr_4* a) {
	(a->frozen__q = 1, 0);
	return unsafe_as_arr_2(a);
}
/* unsafe-as-arr<?t> arr<char>(a mut-arr<char>) */
struct arr_0 unsafe_as_arr_2(struct mut_arr_4* a) {
	return (struct arr_0) {a->size, a->data};
}
/* make-mut-arr<?t> mut-arr<char>(size nat, f fun-mut1<char, nat>) */
struct mut_arr_4* make_mut_arr_2(struct ctx* ctx, uint64_t size, struct fun_mut1_8 f) {
	struct mut_arr_4* res0;
	res0 = new_uninitialized_mut_arr_2(ctx, size);
	make_mut_arr_worker_2(ctx, res0, 0u, f);
	return res0;
}
/* new-uninitialized-mut-arr<?t> mut-arr<char>(size nat) */
struct mut_arr_4* new_uninitialized_mut_arr_2(struct ctx* ctx, uint64_t size) {
	struct mut_arr_4* temp0;
	temp0 = (struct mut_arr_4*) alloc(ctx, sizeof(struct mut_arr_4));
	(*(temp0) = (struct mut_arr_4) {0, size, size, uninitialized_data_3(ctx, size)}, 0);
	return temp0;
}
/* uninitialized-data<?t> ptr<char>(size nat) */
char* uninitialized_data_3(struct ctx* ctx, uint64_t size) {
	uint8_t* bptr0;
	bptr0 = alloc(ctx, (size * sizeof(char)));
	return (char*) bptr0;
}
/* make-mut-arr-worker<?t> void(m mut-arr<char>, i nat, f fun-mut1<char, nat>) */
uint8_t make_mut_arr_worker_2(struct ctx* ctx, struct mut_arr_4* m, uint64_t i, struct fun_mut1_8 f) {
	struct mut_arr_4* _tailCallm;
	uint64_t _tailCalli;
	struct fun_mut1_8 _tailCallf;
	top:
	if (_op_bang_equal_0(i, m->size)) {
		set_at_2(ctx, m, i, call_11(ctx, f, i));
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
/* set-at<?t> void(a mut-arr<char>, index nat, value char) */
uint8_t set_at_2(struct ctx* ctx, struct mut_arr_4* a, uint64_t index, char value) {
	assert_0(ctx, _op_less_0(index, a->size));
	return noctx_set_at_3(a, index, value);
}
/* noctx-set-at<?t> void(a mut-arr<char>, index nat, value char) */
uint8_t noctx_set_at_3(struct mut_arr_4* a, uint64_t index, char value) {
	hard_assert(_op_less_0(index, a->size));
	return (*((a->data + index)) = value, 0);
}
/* call<?t, nat> char(a fun-mut1<char, nat>, p0 nat) */
char call_11(struct ctx* ctx, struct fun_mut1_8 a, uint64_t p0) {
	return call_w_ctx_333(a, ctx, p0);
}
/* call-w-ctx<char, nat-64> (generated) (generated) */
char call_w_ctx_333(struct fun_mut1_8 a, struct ctx* ctx, uint64_t p0) {
	struct fun_mut1_8 match_fun1;
	struct _op_plus_1__lambda0* closure0;
	match_fun1 = a;
	switch (match_fun1.kind) {
		case 0:
			closure0 = match_fun1.as0;
			return _op_plus_1__lambda0(ctx, closure0, p0);
		default:
			return (assert(0),0);
	}
}
/* +<char>.lambda0 char(i nat) */
char _op_plus_1__lambda0(struct ctx* ctx, struct _op_plus_1__lambda0* _closure, uint64_t i) {
	if (_op_less_0(i, _closure->a.size)) {
		return at_3(ctx, _closure->a, i);
	} else {
		return at_3(ctx, _closure->b, _op_minus_2(ctx, i, _closure->a.size));
	}
}
/* at<opt<arr<arr<char>>>> opt<arr<arr<char>>>(a mut-arr<opt<arr<arr<char>>>>, index nat) */
struct opt_10 at_5(struct ctx* ctx, struct mut_arr_3* a, uint64_t index) {
	assert_0(ctx, _op_less_0(index, a->size));
	return noctx_at_7(a, index);
}
/* noctx-at<?t> opt<arr<arr<char>>>(a mut-arr<opt<arr<arr<char>>>>, index nat) */
struct opt_10 noctx_at_7(struct mut_arr_3* a, uint64_t index) {
	hard_assert(_op_less_0(index, a->size));
	return (*((a->data + index)));
}
/* parse-cmd-line-args<test-options>.lambda0 void(key arr<char>, value arr<arr<char>>) */
uint8_t parse_cmd_line_args__lambda0(struct ctx* ctx, struct parse_cmd_line_args__lambda0* _closure, struct arr_0 key, struct arr_1 value) {
	struct opt_11 temp0;
	struct some_11 s0;
	uint64_t idx1;
	temp0 = index_of(ctx, _closure->t_names, key);
	switch (temp0.kind) {
		case 0:
			if (_op_equal_equal_4(key, (struct arr_0) {4, constantarr_0_18})) {
				return set_0(_closure->help, 1);
			} else {
				return fail_0(ctx, _op_plus_1(ctx, (struct arr_0) {15, constantarr_0_19}, key));
			}
		case 1:
			s0 = temp0.as1;
			idx1 = s0.value;
			forbid_0(ctx, has__q_2(at_5(ctx, _closure->values, idx1)));
			return set_at_1(ctx, _closure->values, idx1, (struct opt_10) {1, .as1 = (struct some_10) {value}});
		default:
			return (assert(0),0);
	}
}
/* get<bool> bool(c cell<bool>) */
uint8_t get_2(struct cell_2* c) {
	return c->value;
}
/* call<?t, arr<opt<arr<arr<char>>>>> test-options(a fun1<test-options, arr<opt<arr<arr<char>>>>>, p0 arr<opt<arr<arr<char>>>>) */
struct test_options call_12(struct ctx* ctx, struct fun1 a, struct arr_5 p0) {
	return call_w_ctx_340(a, ctx, p0);
}
/* call-w-ctx<test-options, arr<opt<arr<arr<char>>>>> (generated) (generated) */
struct test_options call_w_ctx_340(struct fun1 a, struct ctx* ctx, struct arr_5 p0) {
	struct fun1 match_fun1;
	uint8_t closure0;
	match_fun1 = a;
	switch (match_fun1.kind) {
		case 0:
			closure0 = match_fun1.as0;
			return main_0__lambda0(ctx, closure0, p0);
		default:
			return (assert(0),(struct test_options) {0, 0, 0});
	}
}
/* freeze<opt<arr<arr<char>>>> arr<opt<arr<arr<char>>>>(a mut-arr<opt<arr<arr<char>>>>) */
struct arr_5 freeze_4(struct mut_arr_3* a) {
	(a->frozen__q = 1, 0);
	return unsafe_as_arr_3(a);
}
/* unsafe-as-arr<?t> arr<opt<arr<arr<char>>>>(a mut-arr<opt<arr<arr<char>>>>) */
struct arr_5 unsafe_as_arr_3(struct mut_arr_3* a) {
	return (struct arr_5) {a->size, a->data};
}
/* at<opt<arr<arr<char>>>> opt<arr<arr<char>>>(a arr<opt<arr<arr<char>>>>, index nat) */
struct opt_10 at_6(struct ctx* ctx, struct arr_5 a, uint64_t index) {
	assert_0(ctx, _op_less_0(index, a.size));
	return noctx_at_8(a, index);
}
/* noctx-at<?t> opt<arr<arr<char>>>(a arr<opt<arr<arr<char>>>>, index nat) */
struct opt_10 noctx_at_8(struct arr_5 a, uint64_t index) {
	hard_assert(_op_less_0(index, a.size));
	return (*((a.data + index)));
}
/* force<nat> nat(a opt<nat>) */
uint64_t force_1(struct ctx* ctx, struct opt_11 a) {
	struct opt_11 temp0;
	struct some_11 s0;
	temp0 = a;
	switch (temp0.kind) {
		case 0:
			return fail_2(ctx, (struct arr_0) {27, constantarr_0_16});
		case 1:
			s0 = temp0.as1;
			return s0.value;
		default:
			return (assert(0),0);
	}
}
/* fail<?t> nat(reason arr<char>) */
uint64_t fail_2(struct ctx* ctx, struct arr_0 reason) {
	return throw_2(ctx, (struct exception) {reason});
}
/* throw<?t> nat(e exception) */
uint64_t throw_2(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx0;
	exn_ctx0 = get_exception_ctx(ctx);
	hard_forbid(null__q_1(exn_ctx0->jmp_buf_ptr));
	(exn_ctx0->thrown_exception = e, 0);
	(longjmp(exn_ctx0->jmp_buf_ptr, number_to_throw(ctx)), 0);
	return todo_4();
}
/* todo<?t> nat() */
uint64_t todo_4(void) {
	return (assert(0),0);
}
/* parse-nat opt<nat>(a arr<char>) */
struct opt_11 parse_nat(struct ctx* ctx, struct arr_0 a) {
	if (empty__q_0(a)) {
		return (struct opt_11) {0, .as0 = (struct none) {0}};
	} else {
		return parse_nat_recur(ctx, a, 0u);
	}
}
/* parse-nat-recur opt<nat>(a arr<char>, accum nat) */
struct opt_11 parse_nat_recur(struct ctx* ctx, struct arr_0 a, uint64_t accum) {
	struct opt_11 temp0;
	struct some_11 s0;
	struct arr_0 _tailCalla;
	uint64_t _tailCallaccum;
	top:
	if (empty__q_0(a)) {
		return (struct opt_11) {1, .as1 = (struct some_11) {accum}};
	} else {
		temp0 = char_to_nat(ctx, first_0(ctx, a));
		switch (temp0.kind) {
			case 0:
				return (struct opt_11) {0, .as0 = (struct none) {0}};
			case 1:
				s0 = temp0.as1;
				_tailCalla = tail_1(ctx, a);
				_tailCallaccum = _op_plus_0(ctx, _op_times_0(ctx, accum, 10u), s0.value);
				a = _tailCalla;
				accum = _tailCallaccum;
				goto top;
			default:
				return (assert(0),(struct opt_11) {0});
		}
	}
}
/* char-to-nat opt<nat>(c char) */
struct opt_11 char_to_nat(struct ctx* ctx, char c) {
	if (_op_equal_equal_1(c, 48u)) {
		return (struct opt_11) {1, .as1 = (struct some_11) {0u}};
	} else {
		if (_op_equal_equal_1(c, 49u)) {
			return (struct opt_11) {1, .as1 = (struct some_11) {1u}};
		} else {
			if (_op_equal_equal_1(c, 50u)) {
				return (struct opt_11) {1, .as1 = (struct some_11) {2u}};
			} else {
				if (_op_equal_equal_1(c, 51u)) {
					return (struct opt_11) {1, .as1 = (struct some_11) {3u}};
				} else {
					if (_op_equal_equal_1(c, 52u)) {
						return (struct opt_11) {1, .as1 = (struct some_11) {4u}};
					} else {
						if (_op_equal_equal_1(c, 53u)) {
							return (struct opt_11) {1, .as1 = (struct some_11) {5u}};
						} else {
							if (_op_equal_equal_1(c, 54u)) {
								return (struct opt_11) {1, .as1 = (struct some_11) {6u}};
							} else {
								if (_op_equal_equal_1(c, 55u)) {
									return (struct opt_11) {1, .as1 = (struct some_11) {7u}};
								} else {
									if (_op_equal_equal_1(c, 56u)) {
										return (struct opt_11) {1, .as1 = (struct some_11) {8u}};
									} else {
										if (_op_equal_equal_1(c, 57u)) {
											return (struct opt_11) {1, .as1 = (struct some_11) {9u}};
										} else {
											return (struct opt_11) {0, .as0 = (struct none) {0}};
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
/* main.lambda0 test-options(values arr<opt<arr<arr<char>>>>) */
struct test_options main_0__lambda0(struct ctx* ctx, uint8_t _closure, struct arr_5 values) {
	struct opt_10 print_tests_strs0;
	struct opt_10 overwrite_output_strs1;
	struct opt_10 max_failures_strs2;
	uint8_t print_tests__q3;
	uint8_t overwrite_output__q5;
	struct opt_10 temp0;
	struct some_10 s4;
	uint64_t max_failures8;
	struct opt_10 temp1;
	struct some_10 s6;
	struct arr_1 strs7;
	print_tests_strs0 = at_6(ctx, values, 0u);
	overwrite_output_strs1 = at_6(ctx, values, 1u);
	max_failures_strs2 = at_6(ctx, values, 2u);
	print_tests__q3 = has__q_2(print_tests_strs0);
	overwrite_output__q5 = (temp0 = overwrite_output_strs1, temp0.kind == 0 ? 0 : temp0.kind == 1 ? (s4 = temp0.as1, (assert_0(ctx, empty__q_6(s4.value)), 1)) : (assert(0),0));
	max_failures8 = (temp1 = max_failures_strs2, temp1.kind == 0 ? 100u : temp1.kind == 1 ? (s6 = temp1.as1, (strs7 = s6.value, (assert_0(ctx, _op_equal_equal_0(strs7.size, 1u)), force_1(ctx, parse_nat(ctx, first_1(ctx, strs7)))))) : (assert(0),0));
	return (struct test_options) {print_tests__q3, overwrite_output__q5, max_failures8};
}
/* resolved<int32> fut<int32>(value int32) */
struct fut_0* resolved_1(struct ctx* ctx, int32_t value) {
	struct fut_0* temp0;
	temp0 = (struct fut_0*) alloc(ctx, sizeof(struct fut_0));
	(*(temp0) = (struct fut_0) {new_lock(), (struct fut_state_0) {1, .as1 = (struct fut_state_resolved_0) {value}}}, 0);
	return temp0;
}
/* print-help void() */
uint8_t print_help(struct ctx* ctx) {
	print((struct arr_0) {18, constantarr_0_20});
	print((struct arr_0) {8, constantarr_0_21});
	print((struct arr_0) {38, constantarr_0_22});
	return print((struct arr_0) {64, constantarr_0_23});
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
/* do-test int32(options test-options) */
int32_t do_test(struct ctx* ctx, struct test_options options) {
	struct arr_0 test_path0;
	struct arr_0 noze_path1;
	struct arr_0 noze_exe2;
	struct dict_1* env3;
	struct result_3 noze_failures4;
	struct do_test__lambda0* temp0;
	struct result_3 all_failures5;
	struct do_test__lambda1* temp1;
	test_path0 = parent_path(ctx, current_executable_path(ctx));
	noze_path1 = parent_path(ctx, test_path0);
	noze_exe2 = child_path(ctx, child_path(ctx, noze_path1, (struct arr_0) {3, constantarr_0_27}), (struct arr_0) {4, constantarr_0_28});
	env3 = get_environ(ctx);
	noze_failures4 = first_failures(ctx, run_noze_tests(ctx, child_path(ctx, test_path0, (struct arr_0) {12, constantarr_0_74}), noze_exe2, env3, options), (struct fun0) {1, .as1 = (temp0 = (struct do_test__lambda0*) alloc(ctx, sizeof(struct do_test__lambda0)), ((*(temp0) = (struct do_test__lambda0) {test_path0, noze_exe2, env3, options}, 0), temp0))});
	all_failures5 = first_failures(ctx, noze_failures4, (struct fun0) {2, .as2 = (temp1 = (struct do_test__lambda1*) alloc(ctx, sizeof(struct do_test__lambda1)), ((*(temp1) = (struct do_test__lambda1) {noze_path1, options}, 0), temp1))});
	return print_failures(ctx, all_failures5, options);
}
/* parent-path arr<char>(a arr<char>) */
struct arr_0 parent_path(struct ctx* ctx, struct arr_0 a) {
	struct opt_11 temp0;
	struct some_11 s0;
	temp0 = r_index_of(ctx, a, 47u);
	switch (temp0.kind) {
		case 0:
			return (struct arr_0) {0u, NULL};
		case 1:
			s0 = temp0.as1;
			return slice_up_to_1(ctx, a, s0.value);
		default:
			return (assert(0),(struct arr_0) {0, NULL});
	}
}
/* r-index-of<char> opt<nat>(a arr<char>, value char) */
struct opt_11 r_index_of(struct ctx* ctx, struct arr_0 a, char value) {
	struct r_index_of__lambda0* temp0;
	return find_rindex(ctx, a, (struct fun_mut1_9) {0, .as0 = (temp0 = (struct r_index_of__lambda0*) alloc(ctx, sizeof(struct r_index_of__lambda0)), ((*(temp0) = (struct r_index_of__lambda0) {value}, 0), temp0))});
}
/* find-rindex<?t> opt<nat>(a arr<char>, pred fun-mut1<bool, char>) */
struct opt_11 find_rindex(struct ctx* ctx, struct arr_0 a, struct fun_mut1_9 pred) {
	if (empty__q_0(a)) {
		return (struct opt_11) {0, .as0 = (struct none) {0}};
	} else {
		return find_rindex_recur(ctx, a, decr(ctx, a.size), pred);
	}
}
/* find-rindex-recur<?t> opt<nat>(a arr<char>, index nat, pred fun-mut1<bool, char>) */
struct opt_11 find_rindex_recur(struct ctx* ctx, struct arr_0 a, uint64_t index, struct fun_mut1_9 pred) {
	struct arr_0 _tailCalla;
	uint64_t _tailCallindex;
	struct fun_mut1_9 _tailCallpred;
	top:
	if (call_13(ctx, pred, at_3(ctx, a, index))) {
		return (struct opt_11) {1, .as1 = (struct some_11) {index}};
	} else {
		if (_op_equal_equal_0(index, 0u)) {
			return (struct opt_11) {0, .as0 = (struct none) {0}};
		} else {
			_tailCalla = a;
			_tailCallindex = decr(ctx, index);
			_tailCallpred = pred;
			a = _tailCalla;
			index = _tailCallindex;
			pred = _tailCallpred;
			goto top;
		}
	}
}
/* call<bool, ?t> bool(a fun-mut1<bool, char>, p0 char) */
uint8_t call_13(struct ctx* ctx, struct fun_mut1_9 a, char p0) {
	return call_w_ctx_364(a, ctx, p0);
}
/* call-w-ctx<bool, char> (generated) (generated) */
uint8_t call_w_ctx_364(struct fun_mut1_9 a, struct ctx* ctx, char p0) {
	struct fun_mut1_9 match_fun1;
	struct r_index_of__lambda0* closure0;
	match_fun1 = a;
	switch (match_fun1.kind) {
		case 0:
			closure0 = match_fun1.as0;
			return r_index_of__lambda0(ctx, closure0, p0);
		default:
			return (assert(0),0);
	}
}
/* r-index-of<char>.lambda0 bool(it char) */
uint8_t r_index_of__lambda0(struct ctx* ctx, struct r_index_of__lambda0* _closure, char it) {
	return _op_equal_equal_1(it, _closure->value);
}
/* slice-up-to<char> arr<char>(a arr<char>, size nat) */
struct arr_0 slice_up_to_1(struct ctx* ctx, struct arr_0 a, uint64_t size) {
	assert_0(ctx, _op_less_0(size, a.size));
	return slice_1(ctx, a, 0u, size);
}
/* current-executable-path arr<char>() */
struct arr_0 current_executable_path(struct ctx* ctx) {
	return read_link(ctx, (struct arr_0) {14, constantarr_0_25});
}
/* read-link arr<char>(path arr<char>) */
struct arr_0 read_link(struct ctx* ctx, struct arr_0 path) {
	struct mut_arr_4* buff0;
	int64_t size1;
	buff0 = new_uninitialized_mut_arr_2(ctx, 1000u);
	size1 = readlink(to_c_str(ctx, path), buff0->data, buff0->size);
	check_errno_if_neg_one(ctx, size1);
	return slice_up_to_1(ctx, freeze_3(buff0), to_nat_0(ctx, size1));
}
/* to-c-str ptr<char>(a arr<char>) */
char* to_c_str(struct ctx* ctx, struct arr_0 a) {
	return _op_plus_1(ctx, a, (struct arr_0) {1, constantarr_0_24}).data;
}
/* check-errno-if-neg-one void(e int) */
uint8_t check_errno_if_neg_one(struct ctx* ctx, int64_t e) {
	if (_op_equal_equal_2(e, -1)) {
		check_posix_error(ctx, errno);
		return hard_unreachable_1();
	} else {
		return 0;
	}
}
/* check-posix-error void(e int32) */
uint8_t check_posix_error(struct ctx* ctx, int32_t e) {
	return assert_0(ctx, _op_equal_equal_3(e, 0));
}
/* hard-unreachable<void> void() */
uint8_t hard_unreachable_1(void) {
	return (assert(0),0);
}
/* to-nat nat(i int) */
uint64_t to_nat_0(struct ctx* ctx, int64_t i) {
	forbid_0(ctx, negative__q(ctx, i));
	return i;
}
/* negative? bool(i int) */
uint8_t negative__q(struct ctx* ctx, int64_t i) {
	return _op_less_1(i, 0);
}
/* <<int> bool(a int, b int) */
uint8_t _op_less_1(int64_t a, int64_t b) {
	struct comparison temp0;
	temp0 = compare_42(a, b);
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
/* child-path arr<char>(a arr<char>, child-name arr<char>) */
struct arr_0 child_path(struct ctx* ctx, struct arr_0 a, struct arr_0 child_name) {
	return _op_plus_1(ctx, _op_plus_1(ctx, a, (struct arr_0) {1, constantarr_0_26}), child_name);
}
/* get-environ dict<arr<char>, arr<char>>() */
struct dict_1* get_environ(struct ctx* ctx) {
	struct mut_dict_1 res0;
	res0 = new_mut_dict_1(ctx);
	get_environ_recur(ctx, environ, res0);
	return freeze_5(ctx, res0);
}
/* new-mut-dict<arr<char>, arr<char>> mut-dict<arr<char>, arr<char>>() */
struct mut_dict_1 new_mut_dict_1(struct ctx* ctx) {
	return (struct mut_dict_1) {new_mut_arr_0(ctx), new_mut_arr_0(ctx)};
}
/* get-environ-recur void(env ptr<ptr<char>>, res mut-dict<arr<char>, arr<char>>) */
uint8_t get_environ_recur(struct ctx* ctx, char** env, struct mut_dict_1 res) {
	char** _tailCallenv;
	struct mut_dict_1 _tailCallres;
	top:
	if (!null__q_2((*(env)))) {
		add_2(ctx, res, parse_environ_entry(ctx, (*(env))));
		_tailCallenv = incr_6(env);
		_tailCallres = res;
		env = _tailCallenv;
		res = _tailCallres;
		goto top;
	} else {
		return 0;
	}
}
/* null?<char> bool(a ptr<char>) */
uint8_t null__q_2(char* a) {
	return _op_equal_equal_0((uint64_t) a, (uint64_t) NULL);
}
/* add<arr<char>, arr<char>> void(m mut-dict<arr<char>, arr<char>>, pair key-value-pair<arr<char>, arr<char>>) */
uint8_t add_2(struct ctx* ctx, struct mut_dict_1 m, struct key_value_pair* pair) {
	return add_3(ctx, m, pair->key, pair->value);
}
/* add<?k, ?v> void(m mut-dict<arr<char>, arr<char>>, key arr<char>, value arr<char>) */
uint8_t add_3(struct ctx* ctx, struct mut_dict_1 m, struct arr_0 key, struct arr_0 value) {
	forbid_0(ctx, has__q_3(ctx, m, key));
	push_0(ctx, m.keys, key);
	return push_0(ctx, m.values, value);
}
/* has?<?k, ?v> bool(d mut-dict<arr<char>, arr<char>>, key arr<char>) */
uint8_t has__q_3(struct ctx* ctx, struct mut_dict_1 d, struct arr_0 key) {
	return has__q_4(ctx, unsafe_as_dict_1(ctx, d), key);
}
/* has?<?k, ?v> bool(d dict<arr<char>, arr<char>>, key arr<char>) */
uint8_t has__q_4(struct ctx* ctx, struct dict_1* d, struct arr_0 key) {
	return has__q_5(get_3(ctx, d, key));
}
/* has?<?v> bool(a opt<arr<char>>) */
uint8_t has__q_5(struct opt_12 a) {
	return !empty__q_10(a);
}
/* empty?<?t> bool(a opt<arr<char>>) */
uint8_t empty__q_10(struct opt_12 a) {
	struct opt_12 temp0;
	struct none n0;
	struct some_12 s1;
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
/* get<?v, ?k> opt<arr<char>>(d dict<arr<char>, arr<char>>, key arr<char>) */
struct opt_12 get_3(struct ctx* ctx, struct dict_1* d, struct arr_0 key) {
	return get_recursive_1(ctx, d->keys, d->values, 0u, key);
}
/* get-recursive<?k, ?v> opt<arr<char>>(keys arr<arr<char>>, values arr<arr<char>>, idx nat, key arr<char>) */
struct opt_12 get_recursive_1(struct ctx* ctx, struct arr_1 keys, struct arr_1 values, uint64_t idx, struct arr_0 key) {
	struct arr_1 _tailCallkeys;
	struct arr_1 _tailCallvalues;
	uint64_t _tailCallidx;
	struct arr_0 _tailCallkey;
	top:
	if (_op_equal_equal_0(idx, keys.size)) {
		return (struct opt_12) {0, .as0 = (struct none) {0}};
	} else {
		if (_op_equal_equal_4(key, at_2(ctx, keys, idx))) {
			return (struct opt_12) {1, .as1 = (struct some_12) {at_2(ctx, values, idx)}};
		} else {
			_tailCallkeys = keys;
			_tailCallvalues = values;
			_tailCallidx = incr_3(ctx, idx);
			_tailCallkey = key;
			keys = _tailCallkeys;
			values = _tailCallvalues;
			idx = _tailCallidx;
			key = _tailCallkey;
			goto top;
		}
	}
}
/* unsafe-as-dict<?k, ?v> dict<arr<char>, arr<char>>(m mut-dict<arr<char>, arr<char>>) */
struct dict_1* unsafe_as_dict_1(struct ctx* ctx, struct mut_dict_1 m) {
	struct dict_1* temp0;
	temp0 = (struct dict_1*) alloc(ctx, sizeof(struct dict_1));
	(*(temp0) = (struct dict_1) {unsafe_as_arr_0(m.keys), unsafe_as_arr_0(m.values)}, 0);
	return temp0;
}
/* parse-environ-entry key-value-pair<arr<char>, arr<char>>(entry ptr<char>) */
struct key_value_pair* parse_environ_entry(struct ctx* ctx, char* entry) {
	char* key_end0;
	struct arr_0 key1;
	char* value_begin2;
	char* value_end3;
	struct arr_0 value4;
	struct key_value_pair* temp0;
	key_end0 = find_char_in_cstr(entry, 61u);
	key1 = arr_from_begin_end(entry, key_end0);
	value_begin2 = incr_1(key_end0);
	value_end3 = find_cstr_end(value_begin2);
	value4 = arr_from_begin_end(value_begin2, value_end3);
	temp0 = (struct key_value_pair*) alloc(ctx, sizeof(struct key_value_pair));
	(*(temp0) = (struct key_value_pair) {key1, value4}, 0);
	return temp0;
}
/* incr<ptr<char>> ptr<ptr<char>>(p ptr<ptr<char>>) */
char** incr_6(char** p) {
	return (p + 1u);
}
/* freeze<arr<char>, arr<char>> dict<arr<char>, arr<char>>(m mut-dict<arr<char>, arr<char>>) */
struct dict_1* freeze_5(struct ctx* ctx, struct mut_dict_1 m) {
	struct dict_1* temp0;
	temp0 = (struct dict_1*) alloc(ctx, sizeof(struct dict_1));
	(*(temp0) = (struct dict_1) {freeze_0(m.keys), freeze_0(m.values)}, 0);
	return temp0;
}
/* first-failures result<arr<char>, arr<failure>>(a result<arr<char>, arr<failure>>, b fun0<result<arr<char>, arr<failure>>>) */
struct result_3 first_failures(struct ctx* ctx, struct result_3 a, struct fun0 b) {
	struct first_failures__lambda0* temp0;
	return then_1(ctx, a, (struct fun_mut1_10) {1, .as1 = (temp0 = (struct first_failures__lambda0*) alloc(ctx, sizeof(struct first_failures__lambda0)), ((*(temp0) = (struct first_failures__lambda0) {b}, 0), temp0))});
}
/* then<arr<char>, arr<failure>, arr<char>> result<arr<char>, arr<failure>>(a result<arr<char>, arr<failure>>, f fun-mut1<result<arr<char>, arr<failure>>, arr<char>>) */
struct result_3 then_1(struct ctx* ctx, struct result_3 a, struct fun_mut1_10 f) {
	struct result_3 temp0;
	struct ok_3 o0;
	struct err_2 e1;
	temp0 = a;
	switch (temp0.kind) {
		case 0:
			o0 = temp0.as0;
			return call_14(ctx, f, o0.value);
		case 1:
			e1 = temp0.as1;
			return (struct result_3) {1, .as1 = e1};
		default:
			return (assert(0),(struct result_3) {0});
	}
}
/* call<result<?ok-out, ?err>, ?ok-in> result<arr<char>, arr<failure>>(a fun-mut1<result<arr<char>, arr<failure>>, arr<char>>, p0 arr<char>) */
struct result_3 call_14(struct ctx* ctx, struct fun_mut1_10 a, struct arr_0 p0) {
	return call_w_ctx_399(a, ctx, p0);
}
/* call-w-ctx<result<arr<char>, arr<failure>>, arr<char>> (generated) (generated) */
struct result_3 call_w_ctx_399(struct fun_mut1_10 a, struct ctx* ctx, struct arr_0 p0) {
	struct fun_mut1_10 match_fun2;
	struct first_failures__lambda0__lambda0* closure0;
	struct first_failures__lambda0* closure1;
	match_fun2 = a;
	switch (match_fun2.kind) {
		case 0:
			closure0 = match_fun2.as0;
			return first_failures__lambda0__lambda0(ctx, closure0, p0);
		case 1:
			closure1 = match_fun2.as1;
			return first_failures__lambda0(ctx, closure1, p0);
		default:
			return (assert(0),(struct result_3) {0});
	}
}
/* call<result<arr<char>, arr<failure>>> result<arr<char>, arr<failure>>(a fun0<result<arr<char>, arr<failure>>>) */
struct result_3 call_15(struct ctx* ctx, struct fun0 a) {
	return call_w_ctx_401(a, ctx);
}
/* call-w-ctx<result<arr<char>, arr<failure>>> (generated) (generated) */
struct result_3 call_w_ctx_401(struct fun0 a, struct ctx* ctx) {
	struct fun0 match_fun3;
	struct do_test__lambda0__lambda0* closure0;
	struct do_test__lambda0* closure1;
	struct do_test__lambda1* closure2;
	match_fun3 = a;
	switch (match_fun3.kind) {
		case 0:
			closure0 = match_fun3.as0;
			return do_test__lambda0__lambda0(ctx, closure0);
		case 1:
			closure1 = match_fun3.as1;
			return do_test__lambda0(ctx, closure1);
		case 2:
			closure2 = match_fun3.as2;
			return do_test__lambda1(ctx, closure2);
		default:
			return (assert(0),(struct result_3) {0});
	}
}
/* first-failures.lambda0.lambda0 result<arr<char>, arr<failure>>(b-descr arr<char>) */
struct result_3 first_failures__lambda0__lambda0(struct ctx* ctx, struct first_failures__lambda0__lambda0* _closure, struct arr_0 b_descr) {
	return (struct result_3) {0, .as0 = (struct ok_3) {_op_plus_1(ctx, _op_plus_1(ctx, _closure->a_descr, (struct arr_0) {1, constantarr_0_3}), b_descr)}};
}
/* first-failures.lambda0 result<arr<char>, arr<failure>>(a-descr arr<char>) */
struct result_3 first_failures__lambda0(struct ctx* ctx, struct first_failures__lambda0* _closure, struct arr_0 a_descr) {
	struct first_failures__lambda0__lambda0* temp0;
	return then_1(ctx, call_15(ctx, _closure->b), (struct fun_mut1_10) {0, .as0 = (temp0 = (struct first_failures__lambda0__lambda0*) alloc(ctx, sizeof(struct first_failures__lambda0__lambda0)), ((*(temp0) = (struct first_failures__lambda0__lambda0) {a_descr}, 0), temp0))});
}
/* run-noze-tests result<arr<char>, arr<failure>>(path arr<char>, path-to-noze arr<char>, env dict<arr<char>, arr<char>>, options test-options) */
struct result_3 run_noze_tests(struct ctx* ctx, struct arr_0 path, struct arr_0 path_to_noze, struct dict_1* env, struct test_options options) {
	struct arr_1 tests0;
	struct arr_7 failures1;
	struct run_noze_tests__lambda0* temp0;
	tests0 = list_tests(ctx, path);
	failures1 = flat_map_with_max_size(ctx, tests0, options.max_failures, (struct fun_mut1_12) {0, .as0 = (temp0 = (struct run_noze_tests__lambda0*) alloc(ctx, sizeof(struct run_noze_tests__lambda0)), ((*(temp0) = (struct run_noze_tests__lambda0) {path_to_noze, env, options}, 0), temp0))});
	if (has__q_6(failures1)) {
		return (struct result_3) {1, .as1 = (struct err_2) {failures1}};
	} else {
		return (struct result_3) {0, .as0 = (struct ok_3) {_op_plus_1(ctx, _op_plus_1(ctx, _op_plus_1(ctx, (struct arr_0) {4, constantarr_0_72}, to_str_3(ctx, tests0.size)), (struct arr_0) {10, constantarr_0_73}), path)}};
	}
}
/* list-tests arr<arr<char>>(path arr<char>) */
struct arr_1 list_tests(struct ctx* ctx, struct arr_0 path) {
	struct mut_arr_1* res0;
	struct fun_mut1_6 filter1;
	struct list_tests__lambda1* temp0;
	res0 = new_mut_arr_0(ctx);
	filter1 = (struct fun_mut1_6) {4, .as4 = 0};
	each_child_recursive(ctx, path, filter1, (struct fun_mut1_11) {1, .as1 = (temp0 = (struct list_tests__lambda1*) alloc(ctx, sizeof(struct list_tests__lambda1)), ((*(temp0) = (struct list_tests__lambda1) {res0}, 0), temp0))});
	return freeze_0(res0);
}
/* list-tests.lambda0 bool(s arr<char>) */
uint8_t list_tests__lambda0(struct ctx* ctx, uint8_t _closure, struct arr_0 s) {
	return 1;
}
/* each-child-recursive void(path arr<char>, filter fun-mut1<bool, arr<char>>, f fun-mut1<void, arr<char>>) */
uint8_t each_child_recursive(struct ctx* ctx, struct arr_0 path, struct fun_mut1_6 filter, struct fun_mut1_11 f) {
	struct each_child_recursive__lambda0* temp0;
	if (is_dir__q_0(ctx, path)) {
		return each_1(ctx, read_dir_0(ctx, path), (struct fun_mut1_11) {0, .as0 = (temp0 = (struct each_child_recursive__lambda0*) alloc(ctx, sizeof(struct each_child_recursive__lambda0)), ((*(temp0) = (struct each_child_recursive__lambda0) {filter, path, f}, 0), temp0))});
	} else {
		return call_16(ctx, f, path);
	}
}
/* is-dir? bool(path arr<char>) */
uint8_t is_dir__q_0(struct ctx* ctx, struct arr_0 path) {
	return is_dir__q_1(ctx, to_c_str(ctx, path));
}
/* is-dir? bool(path ptr<char>) */
uint8_t is_dir__q_1(struct ctx* ctx, char* path) {
	struct opt_13 temp0;
	struct some_13 s0;
	temp0 = get_stat(ctx, path);
	switch (temp0.kind) {
		case 0:
			return todo_6();
		case 1:
			s0 = temp0.as1;
			return _op_equal_equal_5((s0.value->st_mode & s_ifmt(ctx)), s_ifdir(ctx));
		default:
			return (assert(0),0);
	}
}
/* get-stat opt<stat-t>(path ptr<char>) */
struct opt_13 get_stat(struct ctx* ctx, char* path) {
	struct stat_t* s0;
	int32_t err1;
	s0 = empty_stat(ctx);
	err1 = stat(path, s0);
	if (_op_equal_equal_3(err1, 0)) {
		return (struct opt_13) {1, .as1 = (struct some_13) {s0}};
	} else {
		assert_0(ctx, _op_equal_equal_3(err1, -1));
		if (_op_equal_equal_3(errno, enoent())) {
			return (struct opt_13) {0, .as0 = (struct none) {0}};
		} else {
			return todo_5();
		}
	}
}
/* empty-stat stat-t() */
struct stat_t* empty_stat(struct ctx* ctx) {
	struct stat_t* temp0;
	temp0 = (struct stat_t*) alloc(ctx, sizeof(struct stat_t));
	(*(temp0) = (struct stat_t) {0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u}, 0);
	return temp0;
}
/* enoent int32() */
int32_t enoent(void) {
	return 2;
}
/* todo<opt<stat-t>> opt<stat-t>() */
struct opt_13 todo_5(void) {
	return (assert(0),(struct opt_13) {0});
}
/* todo<bool> bool() */
uint8_t todo_6(void) {
	return (assert(0),0);
}
/* ==<nat32> bool(a nat32, b nat32) */
uint8_t _op_equal_equal_5(uint32_t a, uint32_t b) {
	struct comparison temp0;
	temp0 = compare_417(a, b);
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
/* compare<nat-32> (generated) (generated) */
struct comparison compare_417(uint32_t a, uint32_t b) {
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
/* s-ifmt nat32() */
uint32_t s_ifmt(struct ctx* ctx) {
	return 61440u;
}
/* s-ifdir nat32() */
uint32_t s_ifdir(struct ctx* ctx) {
	return 16384u;
}
/* each<arr<char>> void(a arr<arr<char>>, f fun-mut1<void, arr<char>>) */
uint8_t each_1(struct ctx* ctx, struct arr_1 a, struct fun_mut1_11 f) {
	struct arr_1 _tailCalla;
	struct fun_mut1_11 _tailCallf;
	top:
	if (!empty__q_6(a)) {
		call_16(ctx, f, first_1(ctx, a));
		_tailCalla = tail_2(ctx, a);
		_tailCallf = f;
		a = _tailCalla;
		f = _tailCallf;
		goto top;
	} else {
		return 0;
	}
}
/* call<void, ?t> void(a fun-mut1<void, arr<char>>, p0 arr<char>) */
uint8_t call_16(struct ctx* ctx, struct fun_mut1_11 a, struct arr_0 p0) {
	return call_w_ctx_422(a, ctx, p0);
}
/* call-w-ctx<void, arr<char>> (generated) (generated) */
uint8_t call_w_ctx_422(struct fun_mut1_11 a, struct ctx* ctx, struct arr_0 p0) {
	struct fun_mut1_11 match_fun4;
	struct each_child_recursive__lambda0* closure0;
	struct list_tests__lambda1* closure1;
	struct flat_map_with_max_size__lambda0* closure2;
	struct list_lintable_files__lambda1* closure3;
	match_fun4 = a;
	switch (match_fun4.kind) {
		case 0:
			closure0 = match_fun4.as0;
			return each_child_recursive__lambda0(ctx, closure0, p0);
		case 1:
			closure1 = match_fun4.as1;
			return list_tests__lambda1(ctx, closure1, p0);
		case 2:
			closure2 = match_fun4.as2;
			return flat_map_with_max_size__lambda0(ctx, closure2, p0);
		case 3:
			closure3 = match_fun4.as3;
			return list_lintable_files__lambda1(ctx, closure3, p0);
		default:
			return (assert(0),0);
	}
}
/* read-dir arr<arr<char>>(path arr<char>) */
struct arr_1 read_dir_0(struct ctx* ctx, struct arr_0 path) {
	return read_dir_1(ctx, to_c_str(ctx, path));
}
/* read-dir arr<arr<char>>(path ptr<char>) */
struct arr_1 read_dir_1(struct ctx* ctx, char* path) {
	uint8_t* dirp0;
	struct mut_arr_1* res1;
	dirp0 = opendir(path);
	forbid_0(ctx, null__q_0(dirp0));
	res1 = new_mut_arr_0(ctx);
	read_dir_recur(ctx, dirp0, res1);
	return sort_0(ctx, freeze_0(res1));
}
/* read-dir-recur void(dirp ptr<nat8>, res mut-arr<arr<char>>) */
uint8_t read_dir_recur(struct ctx* ctx, uint8_t* dirp, struct mut_arr_1* res) {
	struct dirent* entry0;
	struct dirent* temp0;
	struct cell_3* result1;
	struct cell_3* temp1;
	int32_t err2;
	struct arr_0 name3;
	uint8_t* _tailCalldirp;
	struct mut_arr_1* _tailCallres;
	top:
	entry0 = (temp0 = (struct dirent*) alloc(ctx, sizeof(struct dirent)), ((*(temp0) = (struct dirent) {0u, 0, 0u, 0u, zero_4()}, 0), temp0));
	result1 = (temp1 = (struct cell_3*) alloc(ctx, sizeof(struct cell_3)), ((*(temp1) = (struct cell_3) {entry0}, 0), temp1));
	err2 = readdir_r(dirp, entry0, result1);
	assert_0(ctx, _op_equal_equal_3(err2, 0));
	if (!null__q_0((uint8_t*) get_4(result1))) {
		assert_0(ctx, ref_eq__q(get_4(result1), entry0));
		name3 = get_dirent_name(entry0);
		if ((_op_bang_equal_3(name3, (struct arr_0) {1, constantarr_0_29}) && _op_bang_equal_3(name3, (struct arr_0) {2, constantarr_0_30}))) {
			push_0(ctx, res, get_dirent_name(entry0));
		} else {
			0;
		}
		_tailCalldirp = dirp;
		_tailCallres = res;
		dirp = _tailCalldirp;
		res = _tailCallres;
		goto top;
	} else {
		return 0;
	}
}
/* zero bytes256() */
struct bytes256 zero_4(void) {
	return (struct bytes256) {zero_3(), zero_3()};
}
/* get<dirent> dirent(c cell<dirent>) */
struct dirent* get_4(struct cell_3* c) {
	return c->value;
}
/* ref-eq?<dirent> bool(a dirent, b dirent) */
uint8_t ref_eq__q(struct dirent* a, struct dirent* b) {
	return ((uint8_t*) a == (uint8_t*) b);
}
/* get-dirent-name arr<char>(d dirent) */
struct arr_0 get_dirent_name(struct dirent* d) {
	uint64_t name_offset0;
	uint8_t* name_ptr1;
	name_offset0 = (((sizeof(uint64_t) + sizeof(int64_t)) + sizeof(uint16_t)) + sizeof(char));
	name_ptr1 = ((uint8_t*) d + name_offset0);
	return to_str_0((char*) name_ptr1);
}
/* !=<arr<char>> bool(a arr<char>, b arr<char>) */
uint8_t _op_bang_equal_3(struct arr_0 a, struct arr_0 b) {
	return !_op_equal_equal_4(a, b);
}
/* sort<arr<char>> arr<arr<char>>(a arr<arr<char>>) */
struct arr_1 sort_0(struct ctx* ctx, struct arr_1 a) {
	struct mut_arr_1* m0;
	m0 = to_mut_arr(ctx, a);
	sort_1(ctx, m0);
	return freeze_0(m0);
}
/* to-mut-arr<?t> mut-arr<arr<char>>(a arr<arr<char>>) */
struct mut_arr_1* to_mut_arr(struct ctx* ctx, struct arr_1 a) {
	struct to_mut_arr__lambda0* temp0;
	return make_mut_arr_0(ctx, a.size, (struct fun_mut1_5) {1, .as1 = (temp0 = (struct to_mut_arr__lambda0*) alloc(ctx, sizeof(struct to_mut_arr__lambda0)), ((*(temp0) = (struct to_mut_arr__lambda0) {a}, 0), temp0))});
}
/* to-mut-arr<?t>.lambda0 arr<char>(i nat) */
struct arr_0 to_mut_arr__lambda0(struct ctx* ctx, struct to_mut_arr__lambda0* _closure, uint64_t i) {
	return at_2(ctx, _closure->a, i);
}
/* sort<?t> void(a mut-arr<arr<char>>) */
uint8_t sort_1(struct ctx* ctx, struct mut_arr_1* a) {
	return sort_2(ctx, to_mut_slice(ctx, a));
}
/* sort<?t> void(a mut-slice<arr<char>>) */
uint8_t sort_2(struct ctx* ctx, struct mut_slice* a) {
	struct arr_0 pivot0;
	uint64_t index_of_first_value_gt_pivot1;
	uint64_t new_pivot_index2;
	struct mut_slice* _tailCalla;
	top:
	if (_op_greater(a->size, 1u)) {
		swap_0(ctx, a, 0u, _op_div(ctx, a->size, 2u));
		pivot0 = at_7(ctx, a, 0u);
		index_of_first_value_gt_pivot1 = partition_recur(ctx, a, pivot0, 1u, decr(ctx, a->size));
		new_pivot_index2 = decr(ctx, index_of_first_value_gt_pivot1);
		swap_0(ctx, a, 0u, new_pivot_index2);
		sort_2(ctx, slice_4(ctx, a, 0u, new_pivot_index2));
		_tailCalla = slice_5(ctx, a, incr_3(ctx, new_pivot_index2));
		a = _tailCalla;
		goto top;
	} else {
		return 0;
	}
}
/* swap<?t> void(a mut-slice<arr<char>>, lo nat, hi nat) */
uint8_t swap_0(struct ctx* ctx, struct mut_slice* a, uint64_t lo, uint64_t hi) {
	struct arr_0 old_lo0;
	old_lo0 = at_7(ctx, a, lo);
	set_at_3(ctx, a, lo, at_7(ctx, a, hi));
	return set_at_3(ctx, a, hi, old_lo0);
}
/* at<?t> arr<char>(a mut-slice<arr<char>>, index nat) */
struct arr_0 at_7(struct ctx* ctx, struct mut_slice* a, uint64_t index) {
	assert_0(ctx, _op_less_0(index, a->size));
	return at_8(ctx, a->backing, _op_plus_0(ctx, a->begin, index));
}
/* at<?t> arr<char>(a mut-arr<arr<char>>, index nat) */
struct arr_0 at_8(struct ctx* ctx, struct mut_arr_1* a, uint64_t index) {
	assert_0(ctx, _op_less_0(index, a->size));
	return noctx_at_9(a, index);
}
/* noctx-at<?t> arr<char>(a mut-arr<arr<char>>, index nat) */
struct arr_0 noctx_at_9(struct mut_arr_1* a, uint64_t index) {
	hard_assert(_op_less_0(index, a->size));
	return (*((a->data + index)));
}
/* set-at<?t> void(a mut-slice<arr<char>>, index nat, value arr<char>) */
uint8_t set_at_3(struct ctx* ctx, struct mut_slice* a, uint64_t index, struct arr_0 value) {
	assert_0(ctx, _op_less_0(index, a->size));
	return set_at_0(ctx, a->backing, _op_plus_0(ctx, a->begin, index), value);
}
/* partition-recur<?t> nat(a mut-slice<arr<char>>, pivot arr<char>, l nat, r nat) */
uint64_t partition_recur(struct ctx* ctx, struct mut_slice* a, struct arr_0 pivot, uint64_t l, uint64_t r) {
	struct arr_0 em0;
	struct mut_slice* _tailCalla;
	struct arr_0 _tailCallpivot;
	uint64_t _tailCalll;
	uint64_t _tailCallr;
	top:
	assert_0(ctx, _op_less_equal(l, a->size));
	assert_0(ctx, _op_less_0(r, a->size));
	if (_op_less_equal(l, r)) {
		em0 = at_7(ctx, a, l);
		if (_op_less_2(em0, pivot)) {
			_tailCalla = a;
			_tailCallpivot = pivot;
			_tailCalll = incr_3(ctx, l);
			_tailCallr = r;
			a = _tailCalla;
			pivot = _tailCallpivot;
			l = _tailCalll;
			r = _tailCallr;
			goto top;
		} else {
			swap_0(ctx, a, l, r);
			_tailCalla = a;
			_tailCallpivot = pivot;
			_tailCalll = l;
			_tailCallr = decr(ctx, r);
			a = _tailCalla;
			pivot = _tailCallpivot;
			l = _tailCalll;
			r = _tailCallr;
			goto top;
		}
	} else {
		return l;
	}
}
/* <<?t> bool(a arr<char>, b arr<char>) */
uint8_t _op_less_2(struct arr_0 a, struct arr_0 b) {
	struct comparison temp0;
	temp0 = compare_250(a, b);
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
/* slice<?t> mut-slice<arr<char>>(a mut-slice<arr<char>>, lo nat, size nat) */
struct mut_slice* slice_4(struct ctx* ctx, struct mut_slice* a, uint64_t lo, uint64_t size) {
	struct mut_slice* temp0;
	assert_0(ctx, _op_less_equal(_op_plus_0(ctx, lo, size), a->size));
	temp0 = (struct mut_slice*) alloc(ctx, sizeof(struct mut_slice));
	(*(temp0) = (struct mut_slice) {a->backing, size, _op_plus_0(ctx, a->begin, lo)}, 0);
	return temp0;
}
/* slice<?t> mut-slice<arr<char>>(a mut-slice<arr<char>>, lo nat) */
struct mut_slice* slice_5(struct ctx* ctx, struct mut_slice* a, uint64_t lo) {
	assert_0(ctx, _op_less_equal(lo, a->size));
	return slice_4(ctx, a, lo, _op_minus_2(ctx, a->size, lo));
}
/* to-mut-slice<?t> mut-slice<arr<char>>(a mut-arr<arr<char>>) */
struct mut_slice* to_mut_slice(struct ctx* ctx, struct mut_arr_1* a) {
	struct mut_slice* temp0;
	forbid_0(ctx, a->frozen__q);
	temp0 = (struct mut_slice*) alloc(ctx, sizeof(struct mut_slice));
	(*(temp0) = (struct mut_slice) {a, a->size, 0u}, 0);
	return temp0;
}
/* each-child-recursive.lambda0 void(child-name arr<char>) */
uint8_t each_child_recursive__lambda0(struct ctx* ctx, struct each_child_recursive__lambda0* _closure, struct arr_0 child_name) {
	if (call_8(ctx, _closure->filter, child_name)) {
		return each_child_recursive(ctx, child_path(ctx, _closure->path, child_name), _closure->filter, _closure->f);
	} else {
		return 0;
	}
}
/* get-extension opt<arr<char>>(name arr<char>) */
struct opt_12 get_extension(struct ctx* ctx, struct arr_0 name) {
	struct opt_11 temp0;
	struct some_11 s0;
	temp0 = last_index_of(ctx, name, 46u);
	switch (temp0.kind) {
		case 0:
			return (struct opt_12) {0, .as0 = (struct none) {0}};
		case 1:
			s0 = temp0.as1;
			return (struct opt_12) {1, .as1 = (struct some_12) {slice_after_1(ctx, name, s0.value)}};
		default:
			return (assert(0),(struct opt_12) {0});
	}
}
/* last-index-of opt<nat>(s arr<char>, c char) */
struct opt_11 last_index_of(struct ctx* ctx, struct arr_0 s, char c) {
	struct arr_0 _tailCalls;
	char _tailCallc;
	top:
	if (empty__q_0(s)) {
		return (struct opt_11) {0, .as0 = (struct none) {0}};
	} else {
		if (_op_equal_equal_1(last(ctx, s), c)) {
			return (struct opt_11) {1, .as1 = (struct some_11) {decr(ctx, s.size)}};
		} else {
			_tailCalls = rtail(ctx, s);
			_tailCallc = c;
			s = _tailCalls;
			c = _tailCallc;
			goto top;
		}
	}
}
/* last<char> char(a arr<char>) */
char last(struct ctx* ctx, struct arr_0 a) {
	forbid_0(ctx, empty__q_0(a));
	return at_3(ctx, a, decr(ctx, a.size));
}
/* rtail<char> arr<char>(a arr<char>) */
struct arr_0 rtail(struct ctx* ctx, struct arr_0 a) {
	forbid_0(ctx, empty__q_0(a));
	return slice_1(ctx, a, 0u, decr(ctx, a.size));
}
/* slice-after<char> arr<char>(a arr<char>, before-begin nat) */
struct arr_0 slice_after_1(struct ctx* ctx, struct arr_0 a, uint64_t before_begin) {
	return slice_starting_at_1(ctx, a, incr_3(ctx, before_begin));
}
/* base-name arr<char>(path arr<char>) */
struct arr_0 base_name(struct ctx* ctx, struct arr_0 path) {
	struct opt_11 i0;
	struct opt_11 temp0;
	struct some_11 s1;
	i0 = last_index_of(ctx, path, 47u);
	temp0 = i0;
	switch (temp0.kind) {
		case 0:
			return path;
		case 1:
			s1 = temp0.as1;
			return slice_after_1(ctx, path, s1.value);
		default:
			return (assert(0),(struct arr_0) {0, NULL});
	}
}
/* list-tests.lambda1 void(child arr<char>) */
uint8_t list_tests__lambda1(struct ctx* ctx, struct list_tests__lambda1* _closure, struct arr_0 child) {
	struct opt_12 temp0;
	struct some_12 s0;
	temp0 = get_extension(ctx, base_name(ctx, child));
	switch (temp0.kind) {
		case 0:
			return 0;
		case 1:
			s0 = temp0.as1;
			if (_op_equal_equal_4(s0.value, (struct arr_0) {2, constantarr_0_31})) {
				return push_0(ctx, _closure->res, child);
			} else {
				return 0;
			}
		default:
			return (assert(0),0);
	}
}
/* flat-map-with-max-size<failure, arr<char>> arr<failure>(a arr<arr<char>>, max-size nat, mapper fun-mut1<arr<failure>, arr<char>>) */
struct arr_7 flat_map_with_max_size(struct ctx* ctx, struct arr_1 a, uint64_t max_size, struct fun_mut1_12 mapper) {
	struct mut_arr_5* res0;
	struct flat_map_with_max_size__lambda0* temp0;
	res0 = new_mut_arr_2(ctx);
	each_1(ctx, a, (struct fun_mut1_11) {2, .as2 = (temp0 = (struct flat_map_with_max_size__lambda0*) alloc(ctx, sizeof(struct flat_map_with_max_size__lambda0)), ((*(temp0) = (struct flat_map_with_max_size__lambda0) {res0, max_size, mapper}, 0), temp0))});
	return freeze_6(res0);
}
/* new-mut-arr<?out> mut-arr<failure>() */
struct mut_arr_5* new_mut_arr_2(struct ctx* ctx) {
	struct mut_arr_5* temp0;
	temp0 = (struct mut_arr_5*) alloc(ctx, sizeof(struct mut_arr_5));
	(*(temp0) = (struct mut_arr_5) {0, 0u, 0u, NULL}, 0);
	return temp0;
}
/* push-all<?out> void(a mut-arr<failure>, values arr<failure>) */
uint8_t push_all(struct ctx* ctx, struct mut_arr_5* a, struct arr_7 values) {
	struct push_all__lambda0* temp0;
	return each_2(ctx, values, (struct fun_mut1_13) {0, .as0 = (temp0 = (struct push_all__lambda0*) alloc(ctx, sizeof(struct push_all__lambda0)), ((*(temp0) = (struct push_all__lambda0) {a}, 0), temp0))});
}
/* each<?t> void(a arr<failure>, f fun-mut1<void, failure>) */
uint8_t each_2(struct ctx* ctx, struct arr_7 a, struct fun_mut1_13 f) {
	struct arr_7 _tailCalla;
	struct fun_mut1_13 _tailCallf;
	top:
	if (!empty__q_11(a)) {
		call_17(ctx, f, first_3(ctx, a));
		_tailCalla = tail_4(ctx, a);
		_tailCallf = f;
		a = _tailCalla;
		f = _tailCallf;
		goto top;
	} else {
		return 0;
	}
}
/* empty?<?t> bool(a arr<failure>) */
uint8_t empty__q_11(struct arr_7 a) {
	return _op_equal_equal_0(a.size, 0u);
}
/* call<void, ?t> void(a fun-mut1<void, failure>, p0 failure) */
uint8_t call_17(struct ctx* ctx, struct fun_mut1_13 a, struct failure* p0) {
	return call_w_ctx_462(a, ctx, p0);
}
/* call-w-ctx<void, gc-ptr(failure)> (generated) (generated) */
uint8_t call_w_ctx_462(struct fun_mut1_13 a, struct ctx* ctx, struct failure* p0) {
	struct fun_mut1_13 match_fun2;
	struct push_all__lambda0* closure0;
	uint8_t closure1;
	match_fun2 = a;
	switch (match_fun2.kind) {
		case 0:
			closure0 = match_fun2.as0;
			return push_all__lambda0(ctx, closure0, p0);
		case 1:
			closure1 = match_fun2.as1;
			return print_failures__lambda0(ctx, closure1, p0);
		default:
			return (assert(0),0);
	}
}
/* first<?t> failure(a arr<failure>) */
struct failure* first_3(struct ctx* ctx, struct arr_7 a) {
	forbid_0(ctx, empty__q_11(a));
	return at_9(ctx, a, 0u);
}
/* at<?t> failure(a arr<failure>, index nat) */
struct failure* at_9(struct ctx* ctx, struct arr_7 a, uint64_t index) {
	assert_0(ctx, _op_less_0(index, a.size));
	return noctx_at_10(a, index);
}
/* noctx-at<?t> failure(a arr<failure>, index nat) */
struct failure* noctx_at_10(struct arr_7 a, uint64_t index) {
	hard_assert(_op_less_0(index, a.size));
	return (*((a.data + index)));
}
/* tail<?t> arr<failure>(a arr<failure>) */
struct arr_7 tail_4(struct ctx* ctx, struct arr_7 a) {
	forbid_0(ctx, empty__q_11(a));
	return slice_starting_at_4(ctx, a, 1u);
}
/* slice-starting-at<?t> arr<failure>(a arr<failure>, begin nat) */
struct arr_7 slice_starting_at_4(struct ctx* ctx, struct arr_7 a, uint64_t begin) {
	assert_0(ctx, _op_less_equal(begin, a.size));
	return slice_6(ctx, a, begin, _op_minus_2(ctx, a.size, begin));
}
/* slice<?t> arr<failure>(a arr<failure>, begin nat, size nat) */
struct arr_7 slice_6(struct ctx* ctx, struct arr_7 a, uint64_t begin, uint64_t size) {
	assert_0(ctx, _op_less_equal(_op_plus_0(ctx, begin, size), a.size));
	return (struct arr_7) {size, (a.data + begin)};
}
/* push<?t> void(a mut-arr<failure>, value failure) */
uint8_t push_2(struct ctx* ctx, struct mut_arr_5* a, struct failure* value) {
	if (_op_equal_equal_0(a->size, a->capacity)) {
		increase_capacity_to_2(ctx, a, (_op_equal_equal_0(a->size, 0u) ? 4u : _op_times_0(ctx, a->size, 2u)));
	} else {
		0;
	}
	ensure_capacity_2(ctx, a, round_up_to_power_of_two(ctx, incr_3(ctx, a->size)));
	assert_0(ctx, _op_less_0(a->size, a->capacity));
	(*((a->data + a->size)) = value, 0);
	return (a->size = incr_3(ctx, a->size), 0);
}
/* increase-capacity-to<?t> void(a mut-arr<failure>, new-capacity nat) */
uint8_t increase_capacity_to_2(struct ctx* ctx, struct mut_arr_5* a, uint64_t new_capacity) {
	struct failure** old_data0;
	assert_0(ctx, _op_greater(new_capacity, a->capacity));
	old_data0 = a->data;
	(a->capacity = new_capacity, 0);
	(a->data = uninitialized_data_4(ctx, new_capacity), 0);
	return copy_data_from_2(ctx, a->data, old_data0, a->size);
}
/* uninitialized-data<?t> ptr<failure>(size nat) */
struct failure** uninitialized_data_4(struct ctx* ctx, uint64_t size) {
	uint8_t* bptr0;
	bptr0 = alloc(ctx, (size * sizeof(struct failure*)));
	return (struct failure**) bptr0;
}
/* copy-data-from<?t> void(to ptr<failure>, from ptr<failure>, len nat) */
uint8_t copy_data_from_2(struct ctx* ctx, struct failure** to, struct failure** from, uint64_t len) {
	uint64_t hl0;
	struct failure** _tailCallto;
	struct failure** _tailCallfrom;
	uint64_t _tailCalllen;
	top:
	if (_op_less_0(len, 8u)) {
		return copy_data_from_small_2(ctx, to, from, len);
	} else {
		hl0 = _op_div(ctx, len, 2u);
		copy_data_from_2(ctx, to, from, hl0);
		_tailCallto = (to + hl0);
		_tailCallfrom = (from + hl0);
		_tailCalllen = _op_minus_2(ctx, len, hl0);
		to = _tailCallto;
		from = _tailCallfrom;
		len = _tailCalllen;
		goto top;
	}
}
/* copy-data-from-small<?t> void(to ptr<failure>, from ptr<failure>, len nat) */
uint8_t copy_data_from_small_2(struct ctx* ctx, struct failure** to, struct failure** from, uint64_t len) {
	if (_op_bang_equal_0(len, 0u)) {
		(*(to) = (*(from)), 0);
		return copy_data_from_2(ctx, incr_7(to), incr_7(from), decr(ctx, len));
	} else {
		return 0;
	}
}
/* incr<?t> ptr<failure>(p ptr<failure>) */
struct failure** incr_7(struct failure** p) {
	return (p + 1u);
}
/* ensure-capacity<?t> void(a mut-arr<failure>, capacity nat) */
uint8_t ensure_capacity_2(struct ctx* ctx, struct mut_arr_5* a, uint64_t capacity) {
	if (_op_less_0(a->capacity, capacity)) {
		return increase_capacity_to_2(ctx, a, round_up_to_power_of_two(ctx, capacity));
	} else {
		return 0;
	}
}
/* push-all<?out>.lambda0 void(it failure) */
uint8_t push_all__lambda0(struct ctx* ctx, struct push_all__lambda0* _closure, struct failure* it) {
	return push_2(ctx, _closure->a, it);
}
/* call<arr<?out>, ?in> arr<failure>(a fun-mut1<arr<failure>, arr<char>>, p0 arr<char>) */
struct arr_7 call_18(struct ctx* ctx, struct fun_mut1_12 a, struct arr_0 p0) {
	return call_w_ctx_478(a, ctx, p0);
}
/* call-w-ctx<arr<failure>, arr<char>> (generated) (generated) */
struct arr_7 call_w_ctx_478(struct fun_mut1_12 a, struct ctx* ctx, struct arr_0 p0) {
	struct fun_mut1_12 match_fun2;
	struct run_noze_tests__lambda0* closure0;
	struct lint__lambda0* closure1;
	match_fun2 = a;
	switch (match_fun2.kind) {
		case 0:
			closure0 = match_fun2.as0;
			return run_noze_tests__lambda0(ctx, closure0, p0);
		case 1:
			closure1 = match_fun2.as1;
			return lint__lambda0(ctx, closure1, p0);
		default:
			return (assert(0),(struct arr_7) {0, NULL});
	}
}
/* reduce-size-if-more-than<?out> void(a mut-arr<failure>, new-size nat) */
uint8_t reduce_size_if_more_than(struct ctx* ctx, struct mut_arr_5* a, uint64_t new_size) {
	if (_op_less_0(new_size, a->size)) {
		return (a->size = new_size, 0);
	} else {
		return 0;
	}
}
/* flat-map-with-max-size<failure, arr<char>>.lambda0 void(x arr<char>) */
uint8_t flat_map_with_max_size__lambda0(struct ctx* ctx, struct flat_map_with_max_size__lambda0* _closure, struct arr_0 x) {
	if (_op_less_0(_closure->res->size, _closure->max_size)) {
		push_all(ctx, _closure->res, call_18(ctx, _closure->mapper, x));
		return reduce_size_if_more_than(ctx, _closure->res, _closure->max_size);
	} else {
		return 0;
	}
}
/* freeze<?out> arr<failure>(a mut-arr<failure>) */
struct arr_7 freeze_6(struct mut_arr_5* a) {
	(a->frozen__q = 1, 0);
	return unsafe_as_arr_4(a);
}
/* unsafe-as-arr<?t> arr<failure>(a mut-arr<failure>) */
struct arr_7 unsafe_as_arr_4(struct mut_arr_5* a) {
	return (struct arr_7) {a->size, a->data};
}
/* run-single-noze-test arr<failure>(path-to-noze arr<char>, env dict<arr<char>, arr<char>>, path arr<char>, options test-options) */
struct arr_7 run_single_noze_test(struct ctx* ctx, struct arr_0 path_to_noze, struct dict_1* env, struct arr_0 path, struct test_options options) {
	struct opt_14 op0;
	struct run_single_noze_test__lambda0* temp0;
	struct opt_14 temp1;
	struct arr_7 interpret_failures1;
	struct some_14 s2;
	op0 = first_some(ctx, (struct arr_1) {4, constantarr_1_1}, (struct fun_mut1_14) {0, .as0 = (temp0 = (struct run_single_noze_test__lambda0*) alloc(ctx, sizeof(struct run_single_noze_test__lambda0)), ((*(temp0) = (struct run_single_noze_test__lambda0) {options, path, path_to_noze, env}, 0), temp0))});
	temp1 = op0;
	switch (temp1.kind) {
		case 0:
			if (options.print_tests__q) {
				print(_op_plus_1(ctx, (struct arr_0) {9, constantarr_0_65}, path));
			} else {
				0;
			}
			interpret_failures1 = run_single_runnable_test(ctx, path_to_noze, env, path, 1, options.overwrite_output__q);
			if (empty__q_11(interpret_failures1)) {
				return run_single_runnable_test(ctx, path_to_noze, env, path, 0, options.overwrite_output__q);
			} else {
				return interpret_failures1;
			}
		case 1:
			s2 = temp1.as1;
			return s2.value;
		default:
			return (assert(0),(struct arr_7) {0, NULL});
	}
}
/* first-some<arr<failure>, arr<char>> opt<arr<failure>>(a arr<arr<char>>, cb fun-mut1<opt<arr<failure>>, arr<char>>) */
struct opt_14 first_some(struct ctx* ctx, struct arr_1 a, struct fun_mut1_14 cb) {
	struct opt_14 temp0;
	struct some_14 s0;
	struct arr_1 _tailCalla;
	struct fun_mut1_14 _tailCallcb;
	top:
	if (empty__q_6(a)) {
		return (struct opt_14) {0, .as0 = (struct none) {0}};
	} else {
		temp0 = call_19(ctx, cb, first_1(ctx, a));
		switch (temp0.kind) {
			case 0:
				_tailCalla = tail_2(ctx, a);
				_tailCallcb = cb;
				a = _tailCalla;
				cb = _tailCallcb;
				goto top;
			case 1:
				s0 = temp0.as1;
				return (struct opt_14) {1, .as1 = s0};
			default:
				return (assert(0),(struct opt_14) {0});
		}
	}
}
/* call<opt<?out>, ?in> opt<arr<failure>>(a fun-mut1<opt<arr<failure>>, arr<char>>, p0 arr<char>) */
struct opt_14 call_19(struct ctx* ctx, struct fun_mut1_14 a, struct arr_0 p0) {
	return call_w_ctx_486(a, ctx, p0);
}
/* call-w-ctx<opt<arr<failure>>, arr<char>> (generated) (generated) */
struct opt_14 call_w_ctx_486(struct fun_mut1_14 a, struct ctx* ctx, struct arr_0 p0) {
	struct fun_mut1_14 match_fun1;
	struct run_single_noze_test__lambda0* closure0;
	match_fun1 = a;
	switch (match_fun1.kind) {
		case 0:
			closure0 = match_fun1.as0;
			return run_single_noze_test__lambda0(ctx, closure0, p0);
		default:
			return (assert(0),(struct opt_14) {0});
	}
}
/* run-print-test print-test-result(print-kind arr<char>, path-to-noze arr<char>, env dict<arr<char>, arr<char>>, path arr<char>, overwrite-output? bool) */
struct print_test_result* run_print_test(struct ctx* ctx, struct arr_0 print_kind, struct arr_0 path_to_noze, struct dict_1* env, struct arr_0 path, uint8_t overwrite_output__q) {
	struct process_result* res0;
	struct arr_0* temp0;
	struct arr_0 output_path1;
	struct arr_7 output_failures2;
	struct print_test_result* temp1;
	struct print_test_result* temp2;
	struct arr_0 stderr_no_color3;
	struct print_test_result* temp3;
	struct arr_0 message4;
	struct print_test_result* temp6;
	struct failure** temp4;
	struct failure* temp5;
	res0 = spawn_and_wait_result_0(ctx, path_to_noze, (temp0 = (struct arr_0*) alloc(ctx, (sizeof(struct arr_0) * 3u)), ((*((temp0 + 0u)) = (struct arr_0) {5, constantarr_0_54}, 0), ((*((temp0 + 1u)) = print_kind, 0), ((*((temp0 + 2u)) = path, 0), (struct arr_1) {3u, temp0})))), env);
	output_path1 = _op_plus_1(ctx, _op_plus_1(ctx, _op_plus_1(ctx, path, (struct arr_0) {1, constantarr_0_29}), print_kind), (struct arr_0) {5, constantarr_0_55});
	output_failures2 = ((empty__q_0(res0->stdout) && _op_bang_equal_2(res0->exit_code, 0)) ? empty_arr_3() : handle_output(ctx, path, output_path1, res0->stdout, overwrite_output__q));
	if (!empty__q_11(output_failures2)) {
		temp1 = (struct print_test_result*) alloc(ctx, sizeof(struct print_test_result));
		(*(temp1) = (struct print_test_result) {1, output_failures2}, 0);
		return temp1;
	} else {
		if (_op_equal_equal_3(res0->exit_code, 0)) {
			assert_0(ctx, _op_equal_equal_4(res0->stderr, (struct arr_0) {0u, NULL}));
			temp2 = (struct print_test_result*) alloc(ctx, sizeof(struct print_test_result));
			(*(temp2) = (struct print_test_result) {0, empty_arr_3()}, 0);
			return temp2;
		} else {
			if (_op_equal_equal_3(res0->exit_code, 1)) {
				stderr_no_color3 = remove_colors(ctx, res0->stderr);
				temp3 = (struct print_test_result*) alloc(ctx, sizeof(struct print_test_result));
				(*(temp3) = (struct print_test_result) {1, handle_output(ctx, path, _op_plus_1(ctx, output_path1, (struct arr_0) {4, constantarr_0_63}), stderr_no_color3, overwrite_output__q)}, 0);
				return temp3;
			} else {
				message4 = _op_plus_1(ctx, (struct arr_0) {22, constantarr_0_64}, to_str_1(ctx, res0->exit_code));
				temp6 = (struct print_test_result*) alloc(ctx, sizeof(struct print_test_result));
				(*(temp6) = (struct print_test_result) {1, (temp4 = (struct failure**) alloc(ctx, (sizeof(struct failure*) * 1u)), ((*((temp4 + 0u)) = (temp5 = (struct failure*) alloc(ctx, sizeof(struct failure)), ((*(temp5) = (struct failure) {path, message4}, 0), temp5)), 0), (struct arr_7) {1u, temp4}))}, 0);
				return temp6;
			}
		}
	}
}
/* spawn-and-wait-result process-result(exe arr<char>, args arr<arr<char>>, environ dict<arr<char>, arr<char>>) */
struct process_result* spawn_and_wait_result_0(struct ctx* ctx, struct arr_0 exe, struct arr_1 args, struct dict_1* environ) {
	char* exe_c_str0;
	print(fold(ctx, _op_plus_1(ctx, (struct arr_0) {23, constantarr_0_38}, exe), args, (struct fun_mut2_1) {0, .as0 = 0}));
	if (is_file__q_0(ctx, exe)) {
		exe_c_str0 = to_c_str(ctx, exe);
		return spawn_and_wait_result_1(ctx, exe_c_str0, convert_args(ctx, exe_c_str0, args), convert_environ(ctx, environ));
	} else {
		return fail_3(ctx, _op_plus_1(ctx, exe, (struct arr_0) {14, constantarr_0_53}));
	}
}
/* fold<arr<char>, arr<char>> arr<char>(val arr<char>, a arr<arr<char>>, combine fun-mut2<arr<char>, arr<char>, arr<char>>) */
struct arr_0 fold(struct ctx* ctx, struct arr_0 val, struct arr_1 a, struct fun_mut2_1 combine) {
	struct arr_0 _tailCallval;
	struct arr_1 _tailCalla;
	struct fun_mut2_1 _tailCallcombine;
	top:
	if (empty__q_6(a)) {
		return val;
	} else {
		_tailCallval = call_20(ctx, combine, val, first_1(ctx, a));
		_tailCalla = tail_2(ctx, a);
		_tailCallcombine = combine;
		val = _tailCallval;
		a = _tailCalla;
		combine = _tailCallcombine;
		goto top;
	}
}
/* call<?a, ?a, ?b> arr<char>(a fun-mut2<arr<char>, arr<char>, arr<char>>, p0 arr<char>, p1 arr<char>) */
struct arr_0 call_20(struct ctx* ctx, struct fun_mut2_1 a, struct arr_0 p0, struct arr_0 p1) {
	return call_w_ctx_491(a, ctx, p0, p1);
}
/* call-w-ctx<arr<char>, arr<char>, arr<char>> (generated) (generated) */
struct arr_0 call_w_ctx_491(struct fun_mut2_1 a, struct ctx* ctx, struct arr_0 p0, struct arr_0 p1) {
	struct fun_mut2_1 match_fun1;
	uint8_t closure0;
	match_fun1 = a;
	switch (match_fun1.kind) {
		case 0:
			closure0 = match_fun1.as0;
			return spawn_and_wait_result_0__lambda0(ctx, closure0, p0, p1);
		default:
			return (assert(0),(struct arr_0) {0, NULL});
	}
}
/* spawn-and-wait-result.lambda0 arr<char>(a arr<char>, b arr<char>) */
struct arr_0 spawn_and_wait_result_0__lambda0(struct ctx* ctx, uint8_t _closure, struct arr_0 a, struct arr_0 b) {
	return _op_plus_1(ctx, _op_plus_1(ctx, a, (struct arr_0) {1, constantarr_0_37}), b);
}
/* is-file? bool(path arr<char>) */
uint8_t is_file__q_0(struct ctx* ctx, struct arr_0 path) {
	return is_file__q_1(ctx, to_c_str(ctx, path));
}
/* is-file? bool(path ptr<char>) */
uint8_t is_file__q_1(struct ctx* ctx, char* path) {
	struct opt_13 temp0;
	struct some_13 s0;
	temp0 = get_stat(ctx, path);
	switch (temp0.kind) {
		case 0:
			return 0;
		case 1:
			s0 = temp0.as1;
			return _op_equal_equal_5((s0.value->st_mode & s_ifmt(ctx)), s_ifreg(ctx));
		default:
			return (assert(0),0);
	}
}
/* s-ifreg nat32() */
uint32_t s_ifreg(struct ctx* ctx) {
	return 32768u;
}
/* spawn-and-wait-result process-result(exe ptr<char>, args ptr<ptr<char>>, environ ptr<ptr<char>>) */
struct process_result* spawn_and_wait_result_1(struct ctx* ctx, char* exe, char** args, char** environ) {
	struct pipes* stdout_pipes0;
	struct pipes* stderr_pipes1;
	struct posix_spawn_file_actions_t* actions2;
	struct posix_spawn_file_actions_t* temp0;
	struct cell_4* pid_cell3;
	struct cell_4* temp1;
	int32_t pid4;
	struct mut_arr_4* stdout_builder5;
	struct mut_arr_4* stderr_builder6;
	int32_t exit_code7;
	struct process_result* temp2;
	stdout_pipes0 = make_pipes(ctx);
	stderr_pipes1 = make_pipes(ctx);
	actions2 = (temp0 = (struct posix_spawn_file_actions_t*) alloc(ctx, sizeof(struct posix_spawn_file_actions_t)), ((*(temp0) = (struct posix_spawn_file_actions_t) {0, 0, NULL, zero_0()}, 0), temp0));
	check_posix_error(ctx, posix_spawn_file_actions_init(actions2));
	check_posix_error(ctx, posix_spawn_file_actions_addclose(actions2, stdout_pipes0->write_pipe));
	check_posix_error(ctx, posix_spawn_file_actions_addclose(actions2, stderr_pipes1->write_pipe));
	check_posix_error(ctx, posix_spawn_file_actions_adddup2(actions2, stdout_pipes0->read_pipe, stdout_fd()));
	check_posix_error(ctx, posix_spawn_file_actions_adddup2(actions2, stderr_pipes1->read_pipe, stderr_fd()));
	check_posix_error(ctx, posix_spawn_file_actions_addclose(actions2, stdout_pipes0->read_pipe));
	check_posix_error(ctx, posix_spawn_file_actions_addclose(actions2, stderr_pipes1->read_pipe));
	pid_cell3 = (temp1 = (struct cell_4*) alloc(ctx, sizeof(struct cell_4)), ((*(temp1) = (struct cell_4) {0}, 0), temp1));
	check_posix_error(ctx, posix_spawn(pid_cell3, exe, actions2, NULL, args, environ));
	pid4 = get_5(pid_cell3);
	check_posix_error(ctx, close(stdout_pipes0->read_pipe));
	check_posix_error(ctx, close(stderr_pipes1->read_pipe));
	stdout_builder5 = new_mut_arr_3(ctx);
	stderr_builder6 = new_mut_arr_3(ctx);
	keep_polling(ctx, stdout_pipes0->write_pipe, stderr_pipes1->write_pipe, stdout_builder5, stderr_builder6);
	exit_code7 = wait_and_get_exit_code(ctx, pid4);
	temp2 = (struct process_result*) alloc(ctx, sizeof(struct process_result));
	(*(temp2) = (struct process_result) {exit_code7, freeze_3(stdout_builder5), freeze_3(stderr_builder6)}, 0);
	return temp2;
}
/* make-pipes pipes() */
struct pipes* make_pipes(struct ctx* ctx) {
	struct pipes* res0;
	struct pipes* temp0;
	res0 = (temp0 = (struct pipes*) alloc(ctx, sizeof(struct pipes)), ((*(temp0) = (struct pipes) {0, 0}, 0), temp0));
	check_posix_error(ctx, pipe(res0));
	return res0;
}
/* get<int32> int32(c cell<int32>) */
int32_t get_5(struct cell_4* c) {
	return c->value;
}
/* new-mut-arr<char> mut-arr<char>() */
struct mut_arr_4* new_mut_arr_3(struct ctx* ctx) {
	struct mut_arr_4* temp0;
	temp0 = (struct mut_arr_4*) alloc(ctx, sizeof(struct mut_arr_4));
	(*(temp0) = (struct mut_arr_4) {0, 0u, 0u, NULL}, 0);
	return temp0;
}
/* keep-polling void(stdout-pipe int32, stderr-pipe int32, stdout-builder mut-arr<char>, stderr-builder mut-arr<char>) */
uint8_t keep_polling(struct ctx* ctx, int32_t stdout_pipe, int32_t stderr_pipe, struct mut_arr_4* stdout_builder, struct mut_arr_4* stderr_builder) {
	struct arr_8 poll_fds0;
	struct pollfd* temp0;
	struct pollfd* stdout_pollfd1;
	struct pollfd* stderr_pollfd2;
	int32_t n_pollfds_with_events3;
	struct handle_revents_result a4;
	struct handle_revents_result b5;
	int32_t _tailCallstdout_pipe;
	int32_t _tailCallstderr_pipe;
	struct mut_arr_4* _tailCallstdout_builder;
	struct mut_arr_4* _tailCallstderr_builder;
	top:
	poll_fds0 = (temp0 = (struct pollfd*) alloc(ctx, (sizeof(struct pollfd) * 2u)), ((*((temp0 + 0u)) = (struct pollfd) {stdout_pipe, pollin(ctx), 0}, 0), ((*((temp0 + 1u)) = (struct pollfd) {stderr_pipe, pollin(ctx), 0}, 0), (struct arr_8) {2u, temp0})));
	stdout_pollfd1 = ref_of_val_at(ctx, poll_fds0, 0u);
	stderr_pollfd2 = ref_of_val_at(ctx, poll_fds0, 1u);
	n_pollfds_with_events3 = poll(poll_fds0.data, poll_fds0.size, -1);
	if (_op_equal_equal_3(n_pollfds_with_events3, 0)) {
		return 0;
	} else {
		a4 = handle_revents(ctx, stdout_pollfd1, stdout_builder);
		b5 = handle_revents(ctx, stderr_pollfd2, stderr_builder);
		assert_0(ctx, _op_equal_equal_0(_op_plus_0(ctx, to_nat_1(ctx, any__q(ctx, a4)), to_nat_1(ctx, any__q(ctx, b5))), to_nat_2(ctx, n_pollfds_with_events3)));
		if (!(a4.hung_up__q && b5.hung_up__q)) {
			_tailCallstdout_pipe = stdout_pipe;
			_tailCallstderr_pipe = stderr_pipe;
			_tailCallstdout_builder = stdout_builder;
			_tailCallstderr_builder = stderr_builder;
			stdout_pipe = _tailCallstdout_pipe;
			stderr_pipe = _tailCallstderr_pipe;
			stdout_builder = _tailCallstdout_builder;
			stderr_builder = _tailCallstderr_builder;
			goto top;
		} else {
			return 0;
		}
	}
}
/* pollin int16() */
int16_t pollin(struct ctx* ctx) {
	return 1;
}
/* ref-of-val-at<pollfd> pollfd(a arr<pollfd>, index nat) */
struct pollfd* ref_of_val_at(struct ctx* ctx, struct arr_8 a, uint64_t index) {
	assert_0(ctx, _op_less_0(index, a.size));
	return ref_of_ptr((a.data + index));
}
/* ref-of-ptr<?t> pollfd(p ptr<pollfd>) */
struct pollfd* ref_of_ptr(struct pollfd* p) {
	return (&((*(p))));
}
/* handle-revents handle-revents-result(pollfd pollfd, builder mut-arr<char>) */
struct handle_revents_result handle_revents(struct ctx* ctx, struct pollfd* pollfd, struct mut_arr_4* builder) {
	int16_t revents0;
	uint8_t had_pollin__q1;
	uint8_t hung_up__q2;
	revents0 = pollfd->revents;
	had_pollin__q1 = has_pollin__q(ctx, revents0);
	if (had_pollin__q1) {
		read_to_buffer_until_eof(ctx, pollfd->fd, builder);
	} else {
		0;
	}
	hung_up__q2 = has_pollhup__q(ctx, revents0);
	if ((((has_pollpri__q(ctx, revents0) || has_pollout__q(ctx, revents0)) || has_pollerr__q(ctx, revents0)) || has_pollnval__q(ctx, revents0))) {
		todo_1();
	} else {
		0;
	}
	return (struct handle_revents_result) {had_pollin__q1, hung_up__q2};
}
/* has-pollin? bool(revents int16) */
uint8_t has_pollin__q(struct ctx* ctx, int16_t revents) {
	return bits_intersect__q(revents, pollin(ctx));
}
/* bits-intersect? bool(a int16, b int16) */
uint8_t bits_intersect__q(int16_t a, int16_t b) {
	return !_op_equal_equal_6((a & b), 0);
}
/* ==<int16> bool(a int16, b int16) */
uint8_t _op_equal_equal_6(int16_t a, int16_t b) {
	struct comparison temp0;
	temp0 = compare_515(a, b);
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
/* compare<int-16> (generated) (generated) */
struct comparison compare_515(int16_t a, int16_t b) {
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
/* read-to-buffer-until-eof void(fd int32, buffer mut-arr<char>) */
uint8_t read_to_buffer_until_eof(struct ctx* ctx, int32_t fd, struct mut_arr_4* buffer) {
	char* add_data_to0;
	int64_t n_bytes_read1;
	int32_t _tailCallfd;
	struct mut_arr_4* _tailCallbuffer;
	top:
	ensure_capacity_3(ctx, buffer, _op_plus_0(ctx, buffer->size, 1024u));
	add_data_to0 = (buffer->data + buffer->size);
	n_bytes_read1 = read(fd, (uint8_t*) add_data_to0, 1024u);
	if (_op_equal_equal_2(n_bytes_read1, -1)) {
		return todo_1();
	} else {
		if (_op_equal_equal_2(n_bytes_read1, 0)) {
			return 0;
		} else {
			assert_0(ctx, _op_less_equal(to_nat_0(ctx, n_bytes_read1), 1024u));
			unsafe_increase_size(ctx, buffer, to_nat_0(ctx, n_bytes_read1));
			_tailCallfd = fd;
			_tailCallbuffer = buffer;
			fd = _tailCallfd;
			buffer = _tailCallbuffer;
			goto top;
		}
	}
}
/* ensure-capacity<char> void(a mut-arr<char>, capacity nat) */
uint8_t ensure_capacity_3(struct ctx* ctx, struct mut_arr_4* a, uint64_t capacity) {
	if (_op_less_0(a->capacity, capacity)) {
		return increase_capacity_to_3(ctx, a, round_up_to_power_of_two(ctx, capacity));
	} else {
		return 0;
	}
}
/* increase-capacity-to<?t> void(a mut-arr<char>, new-capacity nat) */
uint8_t increase_capacity_to_3(struct ctx* ctx, struct mut_arr_4* a, uint64_t new_capacity) {
	char* old_data0;
	assert_0(ctx, _op_greater(new_capacity, a->capacity));
	old_data0 = a->data;
	(a->capacity = new_capacity, 0);
	(a->data = uninitialized_data_3(ctx, new_capacity), 0);
	return copy_data_from_3(ctx, a->data, old_data0, a->size);
}
/* copy-data-from<?t> void(to ptr<char>, from ptr<char>, len nat) */
uint8_t copy_data_from_3(struct ctx* ctx, char* to, char* from, uint64_t len) {
	uint64_t hl0;
	char* _tailCallto;
	char* _tailCallfrom;
	uint64_t _tailCalllen;
	top:
	if (_op_less_0(len, 8u)) {
		return copy_data_from_small_3(ctx, to, from, len);
	} else {
		hl0 = _op_div(ctx, len, 2u);
		copy_data_from_3(ctx, to, from, hl0);
		_tailCallto = (to + hl0);
		_tailCallfrom = (from + hl0);
		_tailCalllen = _op_minus_2(ctx, len, hl0);
		to = _tailCallto;
		from = _tailCallfrom;
		len = _tailCalllen;
		goto top;
	}
}
/* copy-data-from-small<?t> void(to ptr<char>, from ptr<char>, len nat) */
uint8_t copy_data_from_small_3(struct ctx* ctx, char* to, char* from, uint64_t len) {
	if (_op_bang_equal_0(len, 0u)) {
		(*(to) = (*(from)), 0);
		return copy_data_from_3(ctx, incr_1(to), incr_1(from), decr(ctx, len));
	} else {
		return 0;
	}
}
/* unsafe-increase-size<char> void(a mut-arr<char>, increase-by nat) */
uint8_t unsafe_increase_size(struct ctx* ctx, struct mut_arr_4* a, uint64_t increase_by) {
	return unsafe_set_size(ctx, a, _op_plus_0(ctx, a->size, increase_by));
}
/* unsafe-set-size<?t> void(a mut-arr<char>, new-size nat) */
uint8_t unsafe_set_size(struct ctx* ctx, struct mut_arr_4* a, uint64_t new_size) {
	assert_0(ctx, _op_less_equal(new_size, a->capacity));
	return (a->size = new_size, 0);
}
/* has-pollhup? bool(revents int16) */
uint8_t has_pollhup__q(struct ctx* ctx, int16_t revents) {
	return bits_intersect__q(revents, pollhup(ctx));
}
/* pollhup int16() */
int16_t pollhup(struct ctx* ctx) {
	return 16;
}
/* has-pollpri? bool(revents int16) */
uint8_t has_pollpri__q(struct ctx* ctx, int16_t revents) {
	return bits_intersect__q(revents, pollpri(ctx));
}
/* pollpri int16() */
int16_t pollpri(struct ctx* ctx) {
	return 2;
}
/* has-pollout? bool(revents int16) */
uint8_t has_pollout__q(struct ctx* ctx, int16_t revents) {
	return bits_intersect__q(revents, pollout(ctx));
}
/* pollout int16() */
int16_t pollout(struct ctx* ctx) {
	return 4;
}
/* has-pollerr? bool(revents int16) */
uint8_t has_pollerr__q(struct ctx* ctx, int16_t revents) {
	return bits_intersect__q(revents, pollerr(ctx));
}
/* pollerr int16() */
int16_t pollerr(struct ctx* ctx) {
	return 8;
}
/* has-pollnval? bool(revents int16) */
uint8_t has_pollnval__q(struct ctx* ctx, int16_t revents) {
	return bits_intersect__q(revents, pollnval(ctx));
}
/* pollnval int16() */
int16_t pollnval(struct ctx* ctx) {
	return 32;
}
/* to-nat nat(b bool) */
uint64_t to_nat_1(struct ctx* ctx, uint8_t b) {
	if (b) {
		return 1u;
	} else {
		return 0u;
	}
}
/* any? bool(r handle-revents-result) */
uint8_t any__q(struct ctx* ctx, struct handle_revents_result r) {
	return (r.had_pollin__q || r.hung_up__q);
}
/* to-nat nat(i int32) */
uint64_t to_nat_2(struct ctx* ctx, int32_t i) {
	return to_nat_0(ctx, i);
}
/* wait-and-get-exit-code int32(pid int32) */
int32_t wait_and_get_exit_code(struct ctx* ctx, int32_t pid) {
	struct cell_4* wait_status_cell0;
	struct cell_4* temp0;
	int32_t res_pid1;
	int32_t wait_status2;
	int32_t signal3;
	wait_status_cell0 = (temp0 = (struct cell_4*) alloc(ctx, sizeof(struct cell_4)), ((*(temp0) = (struct cell_4) {0}, 0), temp0));
	res_pid1 = waitpid(pid, wait_status_cell0, 0);
	wait_status2 = get_5(wait_status_cell0);
	assert_0(ctx, _op_equal_equal_3(res_pid1, pid));
	if (w_if_exited(ctx, wait_status2)) {
		return w_exit_status(ctx, wait_status2);
	} else {
		if (w_if_signaled(ctx, wait_status2)) {
			signal3 = w_term_sig(ctx, wait_status2);
			print(_op_plus_1(ctx, (struct arr_0) {31, constantarr_0_39}, to_str_1(ctx, signal3)));
			return todo_7();
		} else {
			if (w_if_stopped(ctx, wait_status2)) {
				print((struct arr_0) {12, constantarr_0_51});
				return todo_7();
			} else {
				if (w_if_continued(ctx, wait_status2)) {
					return todo_7();
				} else {
					return todo_7();
				}
			}
		}
	}
}
/* w-if-exited bool(status int32) */
uint8_t w_if_exited(struct ctx* ctx, int32_t status) {
	return _op_equal_equal_3(w_term_sig(ctx, status), 0);
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
	if (_op_less_3(a, 0)) {
		return todo_7();
	} else {
		if (_op_less_3(b, 0)) {
			return todo_7();
		} else {
			if (_op_less_3(b, 32)) {
				return (a >> b);
			} else {
				return todo_7();
			}
		}
	}
}
/* <<int32> bool(a int32, b int32) */
uint8_t _op_less_3(int32_t a, int32_t b) {
	struct comparison temp0;
	temp0 = compare_65(a, b);
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
/* todo<int32> int32() */
int32_t todo_7(void) {
	return (assert(0),0);
}
/* w-if-signaled bool(status int32) */
uint8_t w_if_signaled(struct ctx* ctx, int32_t status) {
	int32_t ts0;
	ts0 = w_term_sig(ctx, status);
	return (_op_bang_equal_2(ts0, 0) && _op_bang_equal_2(ts0, 127));
}
/* to-str arr<char>(i int32) */
struct arr_0 to_str_1(struct ctx* ctx, int32_t i) {
	return to_str_2(ctx, i);
}
/* to-str arr<char>(i int) */
struct arr_0 to_str_2(struct ctx* ctx, int64_t i) {
	struct arr_0 a0;
	a0 = to_str_3(ctx, abs(ctx, i));
	if (negative__q(ctx, i)) {
		return _op_plus_1(ctx, (struct arr_0) {1, constantarr_0_50}, a0);
	} else {
		return a0;
	}
}
/* to-str arr<char>(n nat) */
struct arr_0 to_str_3(struct ctx* ctx, uint64_t n) {
	struct arr_0 hi0;
	struct arr_0 lo1;
	if (_op_equal_equal_0(n, 0u)) {
		return (struct arr_0) {1, constantarr_0_40};
	} else {
		if (_op_equal_equal_0(n, 1u)) {
			return (struct arr_0) {1, constantarr_0_41};
		} else {
			if (_op_equal_equal_0(n, 2u)) {
				return (struct arr_0) {1, constantarr_0_42};
			} else {
				if (_op_equal_equal_0(n, 3u)) {
					return (struct arr_0) {1, constantarr_0_43};
				} else {
					if (_op_equal_equal_0(n, 4u)) {
						return (struct arr_0) {1, constantarr_0_44};
					} else {
						if (_op_equal_equal_0(n, 5u)) {
							return (struct arr_0) {1, constantarr_0_45};
						} else {
							if (_op_equal_equal_0(n, 6u)) {
								return (struct arr_0) {1, constantarr_0_46};
							} else {
								if (_op_equal_equal_0(n, 7u)) {
									return (struct arr_0) {1, constantarr_0_47};
								} else {
									if (_op_equal_equal_0(n, 8u)) {
										return (struct arr_0) {1, constantarr_0_48};
									} else {
										if (_op_equal_equal_0(n, 9u)) {
											return (struct arr_0) {1, constantarr_0_49};
										} else {
											hi0 = to_str_3(ctx, _op_div(ctx, n, 10u));
											lo1 = to_str_3(ctx, mod(ctx, n, 10u));
											return _op_plus_1(ctx, hi0, lo1);
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
	forbid_0(ctx, _op_equal_equal_0(b, 0u));
	return (a % b);
}
/* abs nat(i int) */
uint64_t abs(struct ctx* ctx, int64_t i) {
	int64_t i_abs0;
	i_abs0 = (negative__q(ctx, i) ? neg(ctx, i) : i);
	return to_nat_0(ctx, i_abs0);
}
/* neg int(i int) */
int64_t neg(struct ctx* ctx, int64_t i) {
	return _op_times_1(ctx, i, -1);
}
/* * int(a int, b int) */
int64_t _op_times_1(struct ctx* ctx, int64_t a, int64_t b) {
	return (a * b);
}
/* w-if-stopped bool(status int32) */
uint8_t w_if_stopped(struct ctx* ctx, int32_t status) {
	return _op_equal_equal_3((status & 255), 127);
}
/* w-if-continued bool(status int32) */
uint8_t w_if_continued(struct ctx* ctx, int32_t status) {
	return _op_equal_equal_3(status, 65535);
}
/* convert-args ptr<ptr<char>>(exe-c-str ptr<char>, args arr<arr<char>>) */
char** convert_args(struct ctx* ctx, char* exe_c_str, struct arr_1 args) {
	return prepend(ctx, exe_c_str, append(ctx, map_1(ctx, args, (struct fun_mut1_16) {0, .as0 = 0}), NULL)).data;
}
/* prepend<ptr<char>> arr<ptr<char>>(a ptr<char>, b arr<ptr<char>>) */
struct arr_3 prepend(struct ctx* ctx, char* a, struct arr_3 b) {
	char** temp0;
	return _op_plus_2(ctx, (temp0 = (char**) alloc(ctx, (sizeof(char*) * 1u)), ((*((temp0 + 0u)) = a, 0), (struct arr_3) {1u, temp0})), b);
}
/* +<?t> arr<ptr<char>>(a arr<ptr<char>>, b arr<ptr<char>>) */
struct arr_3 _op_plus_2(struct ctx* ctx, struct arr_3 a, struct arr_3 b) {
	struct _op_plus_2__lambda0* temp0;
	return make_arr_2(ctx, _op_plus_0(ctx, a.size, b.size), (struct fun_mut1_15) {0, .as0 = (temp0 = (struct _op_plus_2__lambda0*) alloc(ctx, sizeof(struct _op_plus_2__lambda0)), ((*(temp0) = (struct _op_plus_2__lambda0) {a, b}, 0), temp0))});
}
/* make-arr<?t> arr<ptr<char>>(size nat, f fun-mut1<ptr<char>, nat>) */
struct arr_3 make_arr_2(struct ctx* ctx, uint64_t size, struct fun_mut1_15 f) {
	return freeze_7(make_mut_arr_3(ctx, size, f));
}
/* freeze<?t> arr<ptr<char>>(a mut-arr<ptr<char>>) */
struct arr_3 freeze_7(struct mut_arr_6* a) {
	(a->frozen__q = 1, 0);
	return unsafe_as_arr_5(a);
}
/* unsafe-as-arr<?t> arr<ptr<char>>(a mut-arr<ptr<char>>) */
struct arr_3 unsafe_as_arr_5(struct mut_arr_6* a) {
	return (struct arr_3) {a->size, a->data};
}
/* make-mut-arr<?t> mut-arr<ptr<char>>(size nat, f fun-mut1<ptr<char>, nat>) */
struct mut_arr_6* make_mut_arr_3(struct ctx* ctx, uint64_t size, struct fun_mut1_15 f) {
	struct mut_arr_6* res0;
	res0 = new_uninitialized_mut_arr_3(ctx, size);
	make_mut_arr_worker_3(ctx, res0, 0u, f);
	return res0;
}
/* new-uninitialized-mut-arr<?t> mut-arr<ptr<char>>(size nat) */
struct mut_arr_6* new_uninitialized_mut_arr_3(struct ctx* ctx, uint64_t size) {
	struct mut_arr_6* temp0;
	temp0 = (struct mut_arr_6*) alloc(ctx, sizeof(struct mut_arr_6));
	(*(temp0) = (struct mut_arr_6) {0, size, size, uninitialized_data_5(ctx, size)}, 0);
	return temp0;
}
/* uninitialized-data<?t> ptr<ptr<char>>(size nat) */
char** uninitialized_data_5(struct ctx* ctx, uint64_t size) {
	uint8_t* bptr0;
	bptr0 = alloc(ctx, (size * sizeof(char*)));
	return (char**) bptr0;
}
/* make-mut-arr-worker<?t> void(m mut-arr<ptr<char>>, i nat, f fun-mut1<ptr<char>, nat>) */
uint8_t make_mut_arr_worker_3(struct ctx* ctx, struct mut_arr_6* m, uint64_t i, struct fun_mut1_15 f) {
	struct mut_arr_6* _tailCallm;
	uint64_t _tailCalli;
	struct fun_mut1_15 _tailCallf;
	top:
	if (_op_bang_equal_0(i, m->size)) {
		set_at_4(ctx, m, i, call_21(ctx, f, i));
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
/* set-at<?t> void(a mut-arr<ptr<char>>, index nat, value ptr<char>) */
uint8_t set_at_4(struct ctx* ctx, struct mut_arr_6* a, uint64_t index, char* value) {
	assert_0(ctx, _op_less_0(index, a->size));
	return noctx_set_at_4(a, index, value);
}
/* noctx-set-at<?t> void(a mut-arr<ptr<char>>, index nat, value ptr<char>) */
uint8_t noctx_set_at_4(struct mut_arr_6* a, uint64_t index, char* value) {
	hard_assert(_op_less_0(index, a->size));
	return (*((a->data + index)) = value, 0);
}
/* call<?t, nat> ptr<char>(a fun-mut1<ptr<char>, nat>, p0 nat) */
char* call_21(struct ctx* ctx, struct fun_mut1_15 a, uint64_t p0) {
	return call_w_ctx_568(a, ctx, p0);
}
/* call-w-ctx<raw-ptr(char), nat-64> (generated) (generated) */
char* call_w_ctx_568(struct fun_mut1_15 a, struct ctx* ctx, uint64_t p0) {
	struct fun_mut1_15 match_fun2;
	struct _op_plus_2__lambda0* closure0;
	struct map_1__lambda0* closure1;
	match_fun2 = a;
	switch (match_fun2.kind) {
		case 0:
			closure0 = match_fun2.as0;
			return _op_plus_2__lambda0(ctx, closure0, p0);
		case 1:
			closure1 = match_fun2.as1;
			return map_1__lambda0(ctx, closure1, p0);
		default:
			return (assert(0),NULL);
	}
}
/* +<?t>.lambda0 ptr<char>(i nat) */
char* _op_plus_2__lambda0(struct ctx* ctx, struct _op_plus_2__lambda0* _closure, uint64_t i) {
	if (_op_less_0(i, _closure->a.size)) {
		return at_1(ctx, _closure->a, i);
	} else {
		return at_1(ctx, _closure->b, _op_minus_2(ctx, i, _closure->a.size));
	}
}
/* append<ptr<char>> arr<ptr<char>>(a arr<ptr<char>>, b ptr<char>) */
struct arr_3 append(struct ctx* ctx, struct arr_3 a, char* b) {
	char** temp0;
	return _op_plus_2(ctx, a, (temp0 = (char**) alloc(ctx, (sizeof(char*) * 1u)), ((*((temp0 + 0u)) = b, 0), (struct arr_3) {1u, temp0})));
}
/* map<ptr<char>, arr<char>> arr<ptr<char>>(a arr<arr<char>>, mapper fun-mut1<ptr<char>, arr<char>>) */
struct arr_3 map_1(struct ctx* ctx, struct arr_1 a, struct fun_mut1_16 mapper) {
	struct map_1__lambda0* temp0;
	return make_arr_2(ctx, a.size, (struct fun_mut1_15) {1, .as1 = (temp0 = (struct map_1__lambda0*) alloc(ctx, sizeof(struct map_1__lambda0)), ((*(temp0) = (struct map_1__lambda0) {mapper, a}, 0), temp0))});
}
/* call<?out, ?in> ptr<char>(a fun-mut1<ptr<char>, arr<char>>, p0 arr<char>) */
char* call_22(struct ctx* ctx, struct fun_mut1_16 a, struct arr_0 p0) {
	return call_w_ctx_573(a, ctx, p0);
}
/* call-w-ctx<raw-ptr(char), arr<char>> (generated) (generated) */
char* call_w_ctx_573(struct fun_mut1_16 a, struct ctx* ctx, struct arr_0 p0) {
	struct fun_mut1_16 match_fun1;
	uint8_t closure0;
	match_fun1 = a;
	switch (match_fun1.kind) {
		case 0:
			closure0 = match_fun1.as0;
			return convert_args__lambda0(ctx, closure0, p0);
		default:
			return (assert(0),NULL);
	}
}
/* map<ptr<char>, arr<char>>.lambda0 ptr<char>(i nat) */
char* map_1__lambda0(struct ctx* ctx, struct map_1__lambda0* _closure, uint64_t i) {
	return call_22(ctx, _closure->mapper, at_2(ctx, _closure->a, i));
}
/* convert-args.lambda0 ptr<char>(it arr<char>) */
char* convert_args__lambda0(struct ctx* ctx, uint8_t _closure, struct arr_0 it) {
	return to_c_str(ctx, it);
}
/* convert-environ ptr<ptr<char>>(environ dict<arr<char>, arr<char>>) */
char** convert_environ(struct ctx* ctx, struct dict_1* environ) {
	struct mut_arr_6* res0;
	struct convert_environ__lambda0* temp0;
	res0 = new_mut_arr_4(ctx);
	each_3(ctx, environ, (struct fun_mut2_2) {0, .as0 = (temp0 = (struct convert_environ__lambda0*) alloc(ctx, sizeof(struct convert_environ__lambda0)), ((*(temp0) = (struct convert_environ__lambda0) {res0}, 0), temp0))});
	push_3(ctx, res0, NULL);
	return freeze_7(res0).data;
}
/* new-mut-arr<ptr<char>> mut-arr<ptr<char>>() */
struct mut_arr_6* new_mut_arr_4(struct ctx* ctx) {
	struct mut_arr_6* temp0;
	temp0 = (struct mut_arr_6*) alloc(ctx, sizeof(struct mut_arr_6));
	(*(temp0) = (struct mut_arr_6) {0, 0u, 0u, NULL}, 0);
	return temp0;
}
/* each<arr<char>, arr<char>> void(d dict<arr<char>, arr<char>>, f fun-mut2<void, arr<char>, arr<char>>) */
uint8_t each_3(struct ctx* ctx, struct dict_1* d, struct fun_mut2_2 f) {
	struct dict_1* temp0;
	struct dict_1* _tailCalld;
	struct fun_mut2_2 _tailCallf;
	top:
	if (!empty__q_12(ctx, d)) {
		call_23(ctx, f, first_1(ctx, d->keys), first_1(ctx, d->values));
		_tailCalld = (temp0 = (struct dict_1*) alloc(ctx, sizeof(struct dict_1)), ((*(temp0) = (struct dict_1) {tail_2(ctx, d->keys), tail_2(ctx, d->values)}, 0), temp0));
		_tailCallf = f;
		d = _tailCalld;
		f = _tailCallf;
		goto top;
	} else {
		return 0;
	}
}
/* empty?<?k, ?v> bool(d dict<arr<char>, arr<char>>) */
uint8_t empty__q_12(struct ctx* ctx, struct dict_1* d) {
	return empty__q_6(d->keys);
}
/* call<void, ?k, ?v> void(a fun-mut2<void, arr<char>, arr<char>>, p0 arr<char>, p1 arr<char>) */
uint8_t call_23(struct ctx* ctx, struct fun_mut2_2 a, struct arr_0 p0, struct arr_0 p1) {
	return call_w_ctx_581(a, ctx, p0, p1);
}
/* call-w-ctx<void, arr<char>, arr<char>> (generated) (generated) */
uint8_t call_w_ctx_581(struct fun_mut2_2 a, struct ctx* ctx, struct arr_0 p0, struct arr_0 p1) {
	struct fun_mut2_2 match_fun1;
	struct convert_environ__lambda0* closure0;
	match_fun1 = a;
	switch (match_fun1.kind) {
		case 0:
			closure0 = match_fun1.as0;
			return convert_environ__lambda0(ctx, closure0, p0, p1);
		default:
			return (assert(0),0);
	}
}
/* push<ptr<char>> void(a mut-arr<ptr<char>>, value ptr<char>) */
uint8_t push_3(struct ctx* ctx, struct mut_arr_6* a, char* value) {
	if (_op_equal_equal_0(a->size, a->capacity)) {
		increase_capacity_to_4(ctx, a, (_op_equal_equal_0(a->size, 0u) ? 4u : _op_times_0(ctx, a->size, 2u)));
	} else {
		0;
	}
	ensure_capacity_4(ctx, a, round_up_to_power_of_two(ctx, incr_3(ctx, a->size)));
	assert_0(ctx, _op_less_0(a->size, a->capacity));
	(*((a->data + a->size)) = value, 0);
	return (a->size = incr_3(ctx, a->size), 0);
}
/* increase-capacity-to<?t> void(a mut-arr<ptr<char>>, new-capacity nat) */
uint8_t increase_capacity_to_4(struct ctx* ctx, struct mut_arr_6* a, uint64_t new_capacity) {
	char** old_data0;
	assert_0(ctx, _op_greater(new_capacity, a->capacity));
	old_data0 = a->data;
	(a->capacity = new_capacity, 0);
	(a->data = uninitialized_data_5(ctx, new_capacity), 0);
	return copy_data_from_4(ctx, a->data, old_data0, a->size);
}
/* copy-data-from<?t> void(to ptr<ptr<char>>, from ptr<ptr<char>>, len nat) */
uint8_t copy_data_from_4(struct ctx* ctx, char** to, char** from, uint64_t len) {
	uint64_t hl0;
	char** _tailCallto;
	char** _tailCallfrom;
	uint64_t _tailCalllen;
	top:
	if (_op_less_0(len, 8u)) {
		return copy_data_from_small_4(ctx, to, from, len);
	} else {
		hl0 = _op_div(ctx, len, 2u);
		copy_data_from_4(ctx, to, from, hl0);
		_tailCallto = (to + hl0);
		_tailCallfrom = (from + hl0);
		_tailCalllen = _op_minus_2(ctx, len, hl0);
		to = _tailCallto;
		from = _tailCallfrom;
		len = _tailCalllen;
		goto top;
	}
}
/* copy-data-from-small<?t> void(to ptr<ptr<char>>, from ptr<ptr<char>>, len nat) */
uint8_t copy_data_from_small_4(struct ctx* ctx, char** to, char** from, uint64_t len) {
	if (_op_bang_equal_0(len, 0u)) {
		(*(to) = (*(from)), 0);
		return copy_data_from_4(ctx, incr_6(to), incr_6(from), decr(ctx, len));
	} else {
		return 0;
	}
}
/* ensure-capacity<?t> void(a mut-arr<ptr<char>>, capacity nat) */
uint8_t ensure_capacity_4(struct ctx* ctx, struct mut_arr_6* a, uint64_t capacity) {
	if (_op_less_0(a->capacity, capacity)) {
		return increase_capacity_to_4(ctx, a, round_up_to_power_of_two(ctx, capacity));
	} else {
		return 0;
	}
}
/* convert-environ.lambda0 void(key arr<char>, value arr<char>) */
uint8_t convert_environ__lambda0(struct ctx* ctx, struct convert_environ__lambda0* _closure, struct arr_0 key, struct arr_0 value) {
	return push_3(ctx, _closure->res, to_c_str(ctx, _op_plus_1(ctx, _op_plus_1(ctx, key, (struct arr_0) {1, constantarr_0_52}), value)));
}
/* fail<process-result> process-result(reason arr<char>) */
struct process_result* fail_3(struct ctx* ctx, struct arr_0 reason) {
	return throw_3(ctx, (struct exception) {reason});
}
/* throw<?t> process-result(e exception) */
struct process_result* throw_3(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx0;
	exn_ctx0 = get_exception_ctx(ctx);
	hard_forbid(null__q_1(exn_ctx0->jmp_buf_ptr));
	(exn_ctx0->thrown_exception = e, 0);
	(longjmp(exn_ctx0->jmp_buf_ptr, number_to_throw(ctx)), 0);
	return todo_8();
}
/* todo<?t> process-result() */
struct process_result* todo_8(void) {
	return (assert(0),NULL);
}
/* empty-arr<failure> arr<failure>() */
struct arr_7 empty_arr_3(void) {
	return (struct arr_7) {0u, NULL};
}
/* handle-output arr<failure>(original-path arr<char>, output-path arr<char>, actual arr<char>, overwrite-output? bool) */
struct arr_7 handle_output(struct ctx* ctx, struct arr_0 original_path, struct arr_0 output_path, struct arr_0 actual, uint8_t overwrite_output__q) {
	struct opt_12 temp0;
	struct failure** temp1;
	struct failure* temp2;
	struct some_12 s0;
	struct arr_0 message1;
	struct failure** temp3;
	struct failure* temp4;
	temp0 = try_read_file_0(ctx, output_path);
	switch (temp0.kind) {
		case 0:
			if (overwrite_output__q) {
				write_file_0(ctx, output_path, actual);
				return empty_arr_3();
			} else {
				temp1 = (struct failure**) alloc(ctx, (sizeof(struct failure*) * 1u));
				(*((temp1 + 0u)) = (temp2 = (struct failure*) alloc(ctx, sizeof(struct failure)), ((*(temp2) = (struct failure) {original_path, _op_plus_1(ctx, _op_plus_1(ctx, base_name(ctx, output_path), (struct arr_0) {29, constantarr_0_61}), actual)}, 0), temp2)), 0);
				return (struct arr_7) {1u, temp1};
			}
		case 1:
			s0 = temp0.as1;
			if (_op_equal_equal_4(s0.value, actual)) {
				return empty_arr_3();
			} else {
				if (overwrite_output__q) {
					write_file_0(ctx, output_path, actual);
					return empty_arr_3();
				} else {
					message1 = _op_plus_1(ctx, _op_plus_1(ctx, base_name(ctx, output_path), (struct arr_0) {30, constantarr_0_62}), actual);
					temp3 = (struct failure**) alloc(ctx, (sizeof(struct failure*) * 1u));
					(*((temp3 + 0u)) = (temp4 = (struct failure*) alloc(ctx, sizeof(struct failure)), ((*(temp4) = (struct failure) {original_path, message1}, 0), temp4)), 0);
					return (struct arr_7) {1u, temp3};
				}
			}
		default:
			return (assert(0),(struct arr_7) {0, NULL});
	}
}
/* try-read-file opt<arr<char>>(path arr<char>) */
struct opt_12 try_read_file_0(struct ctx* ctx, struct arr_0 path) {
	return try_read_file_1(ctx, to_c_str(ctx, path));
}
/* try-read-file opt<arr<char>>(path ptr<char>) */
struct opt_12 try_read_file_1(struct ctx* ctx, char* path) {
	int32_t fd0;
	int64_t file_size1;
	int64_t off2;
	uint64_t file_size_nat3;
	struct mut_arr_4* res4;
	int64_t n_bytes_read5;
	if (is_file__q_1(ctx, path)) {
		fd0 = open(path, o_rdonly(ctx), 0u);
		if (_op_equal_equal_3(fd0, -1)) {
			if (_op_equal_equal_3(errno, enoent())) {
				return (struct opt_12) {0, .as0 = (struct none) {0}};
			} else {
				print(_op_plus_1(ctx, (struct arr_0) {20, constantarr_0_56}, to_str_0(path)));
				return todo_9();
			}
		} else {
			file_size1 = lseek(fd0, 0, seek_end(ctx));
			forbid_0(ctx, _op_equal_equal_2(file_size1, -1));
			assert_0(ctx, _op_less_1(file_size1, 1000000000));
			forbid_0(ctx, _op_equal_equal_2(file_size1, 0));
			off2 = lseek(fd0, 0, seek_set(ctx));
			assert_0(ctx, _op_equal_equal_2(off2, 0));
			file_size_nat3 = to_nat_0(ctx, file_size1);
			res4 = new_uninitialized_mut_arr_2(ctx, file_size_nat3);
			n_bytes_read5 = read(fd0, (uint8_t*) res4->data, file_size_nat3);
			forbid_0(ctx, _op_equal_equal_2(n_bytes_read5, -1));
			assert_0(ctx, _op_equal_equal_2(n_bytes_read5, file_size1));
			check_posix_error(ctx, close(fd0));
			return (struct opt_12) {1, .as1 = (struct some_12) {freeze_3(res4)}};
		}
	} else {
		return (struct opt_12) {0, .as0 = (struct none) {0}};
	}
}
/* o-rdonly nat32() */
uint32_t o_rdonly(struct ctx* ctx) {
	return 0u;
}
/* todo<opt<arr<char>>> opt<arr<char>>() */
struct opt_12 todo_9(void) {
	return (assert(0),(struct opt_12) {0});
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
uint8_t write_file_0(struct ctx* ctx, struct arr_0 path, struct arr_0 content) {
	return write_file_1(ctx, to_c_str(ctx, path), content);
}
/* write-file void(path ptr<char>, content arr<char>) */
uint8_t write_file_1(struct ctx* ctx, char* path, struct arr_0 content) {
	uint32_t permission_rdwr0;
	uint32_t permission_rd1;
	uint32_t permission2;
	uint32_t flags3;
	int32_t fd4;
	int64_t wrote_bytes5;
	int32_t err6;
	permission_rdwr0 = 6u;
	permission_rd1 = 4u;
	permission2 = ((bit_shift_left(permission_rdwr0, 6u) | bit_shift_left(permission_rd1, 3u)) | permission_rd1);
	flags3 = ((o_creat(ctx) | o_wronly(ctx)) | o_trunc(ctx));
	fd4 = open(path, flags3, permission2);
	if (_op_equal_equal_3(fd4, -1)) {
		print(_op_plus_1(ctx, (struct arr_0) {31, constantarr_0_57}, to_str_0(path)));
		print(_op_plus_1(ctx, (struct arr_0) {7, constantarr_0_58}, to_str_1(ctx, errno)));
		print(_op_plus_1(ctx, (struct arr_0) {7, constantarr_0_59}, to_str_4(ctx, flags3)));
		print(_op_plus_1(ctx, (struct arr_0) {12, constantarr_0_60}, to_str_4(ctx, permission2)));
		return todo_1();
	} else {
		wrote_bytes5 = write(fd4, (uint8_t*) content.data, content.size);
		if (_op_bang_equal_1(wrote_bytes5, to_int(ctx, content.size))) {
			if (_op_equal_equal_2(wrote_bytes5, -1)) {
				todo_1();
			} else {
				todo_1();
			}
		} else {
			0;
		}
		err6 = close(fd4);
		if (_op_bang_equal_2(err6, 0)) {
			return todo_1();
		} else {
			return 0;
		}
	}
}
/* bit-shift-left nat32(a nat32, b nat32) */
uint32_t bit_shift_left(uint32_t a, uint32_t b) {
	if (_op_less_4(b, 32u)) {
		return (a << b);
	} else {
		return 0u;
	}
}
/* <<nat32> bool(a nat32, b nat32) */
uint8_t _op_less_4(uint32_t a, uint32_t b) {
	struct comparison temp0;
	temp0 = compare_417(a, b);
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
/* o-creat nat32() */
uint32_t o_creat(struct ctx* ctx) {
	return bit_shift_left(1u, 6u);
}
/* o-wronly nat32() */
uint32_t o_wronly(struct ctx* ctx) {
	return 1u;
}
/* o-trunc nat32() */
uint32_t o_trunc(struct ctx* ctx) {
	return bit_shift_left(1u, 9u);
}
/* to-str arr<char>(n nat32) */
struct arr_0 to_str_4(struct ctx* ctx, uint32_t n) {
	return to_str_3(ctx, n);
}
/* to-int int(n nat) */
int64_t to_int(struct ctx* ctx, uint64_t n) {
	assert_0(ctx, _op_less_0(n, to_nat_0(ctx, max_int())));
	return n;
}
/* max-int int() */
int64_t max_int(void) {
	return 9223372036854775807;
}
/* remove-colors arr<char>(s arr<char>) */
struct arr_0 remove_colors(struct ctx* ctx, struct arr_0 s) {
	struct mut_arr_4* out0;
	out0 = new_mut_arr_3(ctx);
	remove_colors_recur(ctx, s, out0);
	return freeze_3(out0);
}
/* remove-colors-recur void(s arr<char>, out mut-arr<char>) */
uint8_t remove_colors_recur(struct ctx* ctx, struct arr_0 s, struct mut_arr_4* out) {
	struct arr_0 _tailCalls;
	struct mut_arr_4* _tailCallout;
	top:
	if (empty__q_0(s)) {
		return 0;
	} else {
		if (_op_equal_equal_1(first_0(ctx, s), 27u)) {
			return remove_colors_recur_2(ctx, tail_1(ctx, s), out);
		} else {
			push_4(ctx, out, first_0(ctx, s));
			_tailCalls = tail_1(ctx, s);
			_tailCallout = out;
			s = _tailCalls;
			out = _tailCallout;
			goto top;
		}
	}
}
/* remove-colors-recur-2 void(s arr<char>, out mut-arr<char>) */
uint8_t remove_colors_recur_2(struct ctx* ctx, struct arr_0 s, struct mut_arr_4* out) {
	struct arr_0 _tailCalls;
	struct mut_arr_4* _tailCallout;
	top:
	if (empty__q_0(s)) {
		return 0;
	} else {
		if (_op_equal_equal_1(first_0(ctx, s), 109u)) {
			return remove_colors_recur(ctx, tail_1(ctx, s), out);
		} else {
			_tailCalls = tail_1(ctx, s);
			_tailCallout = out;
			s = _tailCalls;
			out = _tailCallout;
			goto top;
		}
	}
}
/* push<char> void(a mut-arr<char>, value char) */
uint8_t push_4(struct ctx* ctx, struct mut_arr_4* a, char value) {
	if (_op_equal_equal_0(a->size, a->capacity)) {
		increase_capacity_to_3(ctx, a, (_op_equal_equal_0(a->size, 0u) ? 4u : _op_times_0(ctx, a->size, 2u)));
	} else {
		0;
	}
	ensure_capacity_3(ctx, a, round_up_to_power_of_two(ctx, incr_3(ctx, a->size)));
	assert_0(ctx, _op_less_0(a->size, a->capacity));
	(*((a->data + a->size)) = value, 0);
	return (a->size = incr_3(ctx, a->size), 0);
}
/* run-single-noze-test.lambda0 opt<arr<failure>>(print-kind arr<char>) */
struct opt_14 run_single_noze_test__lambda0(struct ctx* ctx, struct run_single_noze_test__lambda0* _closure, struct arr_0 print_kind) {
	struct print_test_result* res0;
	if (_closure->options.print_tests__q) {
		print(_op_plus_1(ctx, _op_plus_1(ctx, _op_plus_1(ctx, (struct arr_0) {11, constantarr_0_36}, print_kind), (struct arr_0) {1, constantarr_0_37}), _closure->path));
	} else {
		0;
	}
	res0 = run_print_test(ctx, print_kind, _closure->path_to_noze, _closure->env, _closure->path, _closure->options.overwrite_output__q);
	if (res0->should_stop__q) {
		return (struct opt_14) {1, .as1 = (struct some_14) {res0->failures}};
	} else {
		return (struct opt_14) {0, .as0 = (struct none) {0}};
	}
}
/* run-single-runnable-test arr<failure>(path-to-noze arr<char>, env dict<arr<char>, arr<char>>, path arr<char>, interpret? bool, overwrite-output? bool) */
struct arr_7 run_single_runnable_test(struct ctx* ctx, struct arr_0 path_to_noze, struct dict_1* env, struct arr_0 path, uint8_t interpret__q, uint8_t overwrite_output__q) {
	struct arr_1 args0;
	struct arr_0* temp0;
	struct arr_0* temp1;
	struct process_result* res1;
	struct arr_0 message2;
	struct failure** temp2;
	struct failure* temp3;
	args0 = (interpret__q ? (temp0 = (struct arr_0*) alloc(ctx, (sizeof(struct arr_0) * 3u)), ((*((temp0 + 0u)) = (struct arr_0) {3, constantarr_0_66}, 0), ((*((temp0 + 1u)) = path, 0), ((*((temp0 + 2u)) = (struct arr_0) {11, constantarr_0_67}, 0), (struct arr_1) {3u, temp0})))) : (temp1 = (struct arr_0*) alloc(ctx, (sizeof(struct arr_0) * 2u)), ((*((temp1 + 0u)) = (struct arr_0) {3, constantarr_0_66}, 0), ((*((temp1 + 1u)) = path, 0), (struct arr_1) {2u, temp1}))));
	res1 = spawn_and_wait_result_0(ctx, path_to_noze, args0, env);
	if ((_op_equal_equal_3(res1->exit_code, 0) && _op_equal_equal_4(res1->stderr, (struct arr_0) {0u, NULL}))) {
		return handle_output(ctx, path, _op_plus_1(ctx, path, (struct arr_0) {7, constantarr_0_68}), res1->stdout, overwrite_output__q);
	} else {
		message2 = _op_plus_1(ctx, _op_plus_1(ctx, _op_plus_1(ctx, _op_plus_1(ctx, _op_plus_1(ctx, (struct arr_0) {8, constantarr_0_69}, to_str_1(ctx, res1->exit_code)), (struct arr_0) {9, constantarr_0_70}), res1->stdout), (struct arr_0) {8, constantarr_0_71}), res1->stderr);
		temp2 = (struct failure**) alloc(ctx, (sizeof(struct failure*) * 1u));
		(*((temp2 + 0u)) = (temp3 = (struct failure*) alloc(ctx, sizeof(struct failure)), ((*(temp3) = (struct failure) {path, message2}, 0), temp3)), 0);
		return (struct arr_7) {1u, temp2};
	}
}
/* run-noze-tests.lambda0 arr<failure>(test arr<char>) */
struct arr_7 run_noze_tests__lambda0(struct ctx* ctx, struct run_noze_tests__lambda0* _closure, struct arr_0 test) {
	return run_single_noze_test(ctx, _closure->path_to_noze, _closure->env, test, _closure->options);
}
/* has?<failure> bool(a arr<failure>) */
uint8_t has__q_6(struct arr_7 a) {
	return !empty__q_11(a);
}
/* do-test.lambda0.lambda0 result<arr<char>, arr<failure>>() */
struct result_3 do_test__lambda0__lambda0(struct ctx* ctx, struct do_test__lambda0__lambda0* _closure) {
	return run_noze_tests(ctx, child_path(ctx, _closure->test_path, (struct arr_0) {8, constantarr_0_76}), _closure->noze_exe, _closure->env, _closure->options);
}
/* do-test.lambda0 result<arr<char>, arr<failure>>() */
struct result_3 do_test__lambda0(struct ctx* ctx, struct do_test__lambda0* _closure) {
	struct do_test__lambda0__lambda0* temp0;
	return first_failures(ctx, run_noze_tests(ctx, child_path(ctx, _closure->test_path, (struct arr_0) {14, constantarr_0_75}), _closure->noze_exe, _closure->env, _closure->options), (struct fun0) {0, .as0 = (temp0 = (struct do_test__lambda0__lambda0*) alloc(ctx, sizeof(struct do_test__lambda0__lambda0)), ((*(temp0) = (struct do_test__lambda0__lambda0) {_closure->test_path, _closure->noze_exe, _closure->env, _closure->options}, 0), temp0))});
}
/* lint result<arr<char>, arr<failure>>(path arr<char>, options test-options) */
struct result_3 lint(struct ctx* ctx, struct arr_0 path, struct test_options options) {
	struct arr_1 files0;
	struct arr_7 failures1;
	struct lint__lambda0* temp0;
	files0 = list_lintable_files(ctx, path);
	failures1 = flat_map_with_max_size(ctx, files0, options.max_failures, (struct fun_mut1_12) {1, .as1 = (temp0 = (struct lint__lambda0*) alloc(ctx, sizeof(struct lint__lambda0)), ((*(temp0) = (struct lint__lambda0) {options}, 0), temp0))});
	if (has__q_6(failures1)) {
		return (struct result_3) {1, .as1 = (struct err_2) {failures1}};
	} else {
		return (struct result_3) {0, .as0 = (struct ok_3) {_op_plus_1(ctx, _op_plus_1(ctx, (struct arr_0) {7, constantarr_0_98}, to_str_3(ctx, files0.size)), (struct arr_0) {6, constantarr_0_99})}};
	}
}
/* list-lintable-files arr<arr<char>>(path arr<char>) */
struct arr_1 list_lintable_files(struct ctx* ctx, struct arr_0 path) {
	struct mut_arr_1* res0;
	struct list_lintable_files__lambda1* temp0;
	res0 = new_mut_arr_0(ctx);
	each_child_recursive(ctx, path, (struct fun_mut1_6) {6, .as6 = 0}, (struct fun_mut1_11) {3, .as3 = (temp0 = (struct list_lintable_files__lambda1*) alloc(ctx, sizeof(struct list_lintable_files__lambda1)), ((*(temp0) = (struct list_lintable_files__lambda1) {res0}, 0), temp0))});
	return freeze_0(res0);
}
/* excluded-from-lint? bool(name arr<char>) */
uint8_t excluded_from_lint__q(struct ctx* ctx, struct arr_0 name) {
	struct excluded_from_lint__q__lambda0* temp0;
	return (_op_equal_equal_1(first_0(ctx, name), 46u) || (contains__q_1((struct arr_1) {4, constantarr_1_3}, name) || some__q(ctx, (struct arr_1) {5, constantarr_1_2}, (struct fun_mut1_6) {5, .as5 = (temp0 = (struct excluded_from_lint__q__lambda0*) alloc(ctx, sizeof(struct excluded_from_lint__q__lambda0)), ((*(temp0) = (struct excluded_from_lint__q__lambda0) {name}, 0), temp0))})));
}
/* contains?<arr<char>> bool(a arr<arr<char>>, value arr<char>) */
uint8_t contains__q_1(struct arr_1 a, struct arr_0 value) {
	return contains_recur__q_1(a, value, 0u);
}
/* contains-recur?<?t> bool(a arr<arr<char>>, value arr<char>, i nat) */
uint8_t contains_recur__q_1(struct arr_1 a, struct arr_0 value, uint64_t i) {
	struct arr_1 _tailCalla;
	struct arr_0 _tailCallvalue;
	uint64_t _tailCalli;
	top:
	if (_op_equal_equal_0(i, a.size)) {
		return 0;
	} else {
		if (_op_equal_equal_4(noctx_at_4(a, i), value)) {
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
/* some?<arr<char>> bool(a arr<arr<char>>, pred fun-mut1<bool, arr<char>>) */
uint8_t some__q(struct ctx* ctx, struct arr_1 a, struct fun_mut1_6 pred) {
	struct arr_1 _tailCalla;
	struct fun_mut1_6 _tailCallpred;
	top:
	if (!empty__q_6(a)) {
		if (call_8(ctx, pred, first_1(ctx, a))) {
			return 1;
		} else {
			_tailCalla = tail_2(ctx, a);
			_tailCallpred = pred;
			a = _tailCalla;
			pred = _tailCallpred;
			goto top;
		}
	} else {
		return 0;
	}
}
/* ends-with?<char> bool(a arr<char>, end arr<char>) */
uint8_t ends_with__q(struct ctx* ctx, struct arr_0 a, struct arr_0 end) {
	return (_op_greater_equal(a.size, end.size) && arr_eq__q(ctx, slice_1(ctx, a, _op_minus_2(ctx, a.size, end.size), end.size), end));
}
/* excluded-from-lint?.lambda0 bool(it arr<char>) */
uint8_t excluded_from_lint__q__lambda0(struct ctx* ctx, struct excluded_from_lint__q__lambda0* _closure, struct arr_0 it) {
	return ends_with__q(ctx, _closure->name, it);
}
/* list-lintable-files.lambda0 bool(it arr<char>) */
uint8_t list_lintable_files__lambda0(struct ctx* ctx, uint8_t _closure, struct arr_0 it) {
	return !excluded_from_lint__q(ctx, it);
}
/* ignore-extension-of-name? bool(name arr<char>) */
uint8_t ignore_extension_of_name__q(struct ctx* ctx, struct arr_0 name) {
	struct opt_12 temp0;
	struct some_12 s0;
	temp0 = get_extension(ctx, name);
	switch (temp0.kind) {
		case 0:
			return 1;
		case 1:
			s0 = temp0.as1;
			return ignore_extension__q(ctx, s0.value);
		default:
			return (assert(0),0);
	}
}
/* ignore-extension? bool(ext arr<char>) */
uint8_t ignore_extension__q(struct ctx* ctx, struct arr_0 ext) {
	return contains__q_1(ignored_extensions(ctx), ext);
}
/* ignored-extensions arr<arr<char>>() */
struct arr_1 ignored_extensions(struct ctx* ctx) {
	return (struct arr_1) {6, constantarr_1_4};
}
/* list-lintable-files.lambda1 void(child arr<char>) */
uint8_t list_lintable_files__lambda1(struct ctx* ctx, struct list_lintable_files__lambda1* _closure, struct arr_0 child) {
	if (!ignore_extension_of_name__q(ctx, base_name(ctx, child))) {
		return push_0(ctx, _closure->res, child);
	} else {
		return 0;
	}
}
/* lint-file arr<failure>(path arr<char>) */
struct arr_7 lint_file(struct ctx* ctx, struct arr_0 path) {
	struct arr_0 text0;
	struct mut_arr_5* res1;
	uint8_t err_file__q2;
	struct lint_file__lambda0* temp0;
	text0 = read_file(ctx, path);
	res1 = new_mut_arr_2(ctx);
	err_file__q2 = _op_equal_equal_4(force_0(ctx, get_extension(ctx, path)), (struct arr_0) {3, constantarr_0_92});
	each_with_index_0(ctx, lines(ctx, text0), (struct fun_mut2_3) {0, .as0 = (temp0 = (struct lint_file__lambda0*) alloc(ctx, sizeof(struct lint_file__lambda0)), ((*(temp0) = (struct lint_file__lambda0) {err_file__q2, res1, path}, 0), temp0))});
	return freeze_6(res1);
}
/* read-file arr<char>(path arr<char>) */
struct arr_0 read_file(struct ctx* ctx, struct arr_0 path) {
	struct opt_12 temp0;
	struct some_12 s0;
	temp0 = try_read_file_0(ctx, path);
	switch (temp0.kind) {
		case 0:
			print(_op_plus_1(ctx, (struct arr_0) {21, constantarr_0_91}, path));
			return (struct arr_0) {0u, NULL};
		case 1:
			s0 = temp0.as1;
			return s0.value;
		default:
			return (assert(0),(struct arr_0) {0, NULL});
	}
}
/* each-with-index<arr<char>> void(a arr<arr<char>>, f fun-mut2<void, arr<char>, nat>) */
uint8_t each_with_index_0(struct ctx* ctx, struct arr_1 a, struct fun_mut2_3 f) {
	return each_with_index_recur_0(ctx, a, f, 0u);
}
/* each-with-index-recur<?t> void(a arr<arr<char>>, f fun-mut2<void, arr<char>, nat>, n nat) */
uint8_t each_with_index_recur_0(struct ctx* ctx, struct arr_1 a, struct fun_mut2_3 f, uint64_t n) {
	struct arr_1 _tailCalla;
	struct fun_mut2_3 _tailCallf;
	uint64_t _tailCalln;
	top:
	if (_op_bang_equal_0(n, a.size)) {
		call_24(ctx, f, at_2(ctx, a, n), n);
		_tailCalla = a;
		_tailCallf = f;
		_tailCalln = incr_3(ctx, n);
		a = _tailCalla;
		f = _tailCallf;
		n = _tailCalln;
		goto top;
	} else {
		return 0;
	}
}
/* call<void, ?t, nat> void(a fun-mut2<void, arr<char>, nat>, p0 arr<char>, p1 nat) */
uint8_t call_24(struct ctx* ctx, struct fun_mut2_3 a, struct arr_0 p0, uint64_t p1) {
	return call_w_ctx_639(a, ctx, p0, p1);
}
/* call-w-ctx<void, arr<char>, nat-64> (generated) (generated) */
uint8_t call_w_ctx_639(struct fun_mut2_3 a, struct ctx* ctx, struct arr_0 p0, uint64_t p1) {
	struct fun_mut2_3 match_fun1;
	struct lint_file__lambda0* closure0;
	match_fun1 = a;
	switch (match_fun1.kind) {
		case 0:
			closure0 = match_fun1.as0;
			return lint_file__lambda0(ctx, closure0, p0, p1);
		default:
			return (assert(0),0);
	}
}
/* lines arr<arr<char>>(s arr<char>) */
struct arr_1 lines(struct ctx* ctx, struct arr_0 s) {
	struct mut_arr_1* res0;
	struct cell_0* last_nl1;
	struct cell_0* temp0;
	struct lines__lambda0* temp1;
	res0 = new_mut_arr_0(ctx);
	last_nl1 = (temp0 = (struct cell_0*) alloc(ctx, sizeof(struct cell_0)), ((*(temp0) = (struct cell_0) {0u}, 0), temp0));
	each_with_index_1(ctx, s, (struct fun_mut2_4) {0, .as0 = (temp1 = (struct lines__lambda0*) alloc(ctx, sizeof(struct lines__lambda0)), ((*(temp1) = (struct lines__lambda0) {res0, s, last_nl1}, 0), temp1))});
	push_0(ctx, res0, slice_from_to(ctx, s, get_6(last_nl1), s.size));
	return freeze_0(res0);
}
/* each-with-index<char> void(a arr<char>, f fun-mut2<void, char, nat>) */
uint8_t each_with_index_1(struct ctx* ctx, struct arr_0 a, struct fun_mut2_4 f) {
	return each_with_index_recur_1(ctx, a, f, 0u);
}
/* each-with-index-recur<?t> void(a arr<char>, f fun-mut2<void, char, nat>, n nat) */
uint8_t each_with_index_recur_1(struct ctx* ctx, struct arr_0 a, struct fun_mut2_4 f, uint64_t n) {
	struct arr_0 _tailCalla;
	struct fun_mut2_4 _tailCallf;
	uint64_t _tailCalln;
	top:
	if (_op_bang_equal_0(n, a.size)) {
		call_25(ctx, f, at_3(ctx, a, n), n);
		_tailCalla = a;
		_tailCallf = f;
		_tailCalln = incr_3(ctx, n);
		a = _tailCalla;
		f = _tailCallf;
		n = _tailCalln;
		goto top;
	} else {
		return 0;
	}
}
/* call<void, ?t, nat> void(a fun-mut2<void, char, nat>, p0 char, p1 nat) */
uint8_t call_25(struct ctx* ctx, struct fun_mut2_4 a, char p0, uint64_t p1) {
	return call_w_ctx_644(a, ctx, p0, p1);
}
/* call-w-ctx<void, char, nat-64> (generated) (generated) */
uint8_t call_w_ctx_644(struct fun_mut2_4 a, struct ctx* ctx, char p0, uint64_t p1) {
	struct fun_mut2_4 match_fun1;
	struct lines__lambda0* closure0;
	match_fun1 = a;
	switch (match_fun1.kind) {
		case 0:
			closure0 = match_fun1.as0;
			return lines__lambda0(ctx, closure0, p0, p1);
		default:
			return (assert(0),0);
	}
}
/* slice-from-to<char> arr<char>(a arr<char>, begin nat, end nat) */
struct arr_0 slice_from_to(struct ctx* ctx, struct arr_0 a, uint64_t begin, uint64_t end) {
	assert_0(ctx, _op_less_equal(begin, end));
	return slice_1(ctx, a, begin, _op_minus_2(ctx, end, begin));
}
/* swap<nat> nat(c cell<nat>, v nat) */
uint64_t swap_1(struct cell_0* c, uint64_t v) {
	uint64_t res0;
	res0 = get_6(c);
	set_1(c, v);
	return res0;
}
/* get<?t> nat(c cell<nat>) */
uint64_t get_6(struct cell_0* c) {
	return c->value;
}
/* set<?t> void(c cell<nat>, v nat) */
uint8_t set_1(struct cell_0* c, uint64_t v) {
	return (c->value = v, 0);
}
/* lines.lambda0 void(c char, index nat) */
uint8_t lines__lambda0(struct ctx* ctx, struct lines__lambda0* _closure, char c, uint64_t index) {
	if (_op_equal_equal_1(c, 10u)) {
		return push_0(ctx, _closure->res, slice_from_to(ctx, _closure->s, swap_1(_closure->last_nl, incr_3(ctx, index)), index));
	} else {
		return 0;
	}
}
/* contains-subsequence?<char> bool(a arr<char>, subseq arr<char>) */
uint8_t contains_subsequence__q(struct ctx* ctx, struct arr_0 a, struct arr_0 subseq) {
	return (starts_with__q(ctx, a, subseq) || (has__q_7(a) && starts_with__q(ctx, tail_1(ctx, a), subseq)));
}
/* has?<?t> bool(a arr<char>) */
uint8_t has__q_7(struct arr_0 a) {
	return !empty__q_0(a);
}
/* lstrip arr<char>(a arr<char>) */
struct arr_0 lstrip(struct ctx* ctx, struct arr_0 a) {
	struct arr_0 _tailCalla;
	top:
	if ((has__q_7(a) && _op_equal_equal_1(first_0(ctx, a), 32u))) {
		_tailCalla = tail_1(ctx, a);
		a = _tailCalla;
		goto top;
	} else {
		return a;
	}
}
/* line-len nat(line arr<char>) */
uint64_t line_len(struct ctx* ctx, struct arr_0 line) {
	return _op_plus_0(ctx, _op_times_0(ctx, n_tabs(ctx, line), _op_minus_2(ctx, tab_size(ctx), 1u)), line.size);
}
/* n-tabs nat(line arr<char>) */
uint64_t n_tabs(struct ctx* ctx, struct arr_0 line) {
	if ((!empty__q_0(line) && _op_equal_equal_1(first_0(ctx, line), 9u))) {
		return incr_3(ctx, n_tabs(ctx, tail_1(ctx, line)));
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
uint8_t lint_file__lambda0(struct ctx* ctx, struct lint_file__lambda0* _closure, struct arr_0 line, uint64_t line_num) {
	struct arr_0 ln0;
	struct arr_0 message1;
	struct failure* temp0;
	uint64_t width2;
	struct arr_0 message3;
	struct failure* temp1;
	ln0 = to_str_3(ctx, incr_3(ctx, line_num));
	if ((!_closure->err_file__q && contains_subsequence__q(ctx, lstrip(ctx, line), (struct arr_0) {2, constantarr_0_93}))) {
		message1 = _op_plus_1(ctx, _op_plus_1(ctx, (struct arr_0) {5, constantarr_0_94}, ln0), (struct arr_0) {24, constantarr_0_95});
		push_2(ctx, _closure->res, (temp0 = (struct failure*) alloc(ctx, sizeof(struct failure)), ((*(temp0) = (struct failure) {_closure->path, message1}, 0), temp0)));
	} else {
		0;
	}
	width2 = line_len(ctx, line);
	if (_op_greater(width2, max_line_length(ctx))) {
		message3 = _op_plus_1(ctx, _op_plus_1(ctx, _op_plus_1(ctx, _op_plus_1(ctx, _op_plus_1(ctx, (struct arr_0) {5, constantarr_0_94}, ln0), (struct arr_0) {4, constantarr_0_96}), to_str_3(ctx, width2)), (struct arr_0) {28, constantarr_0_97}), to_str_3(ctx, max_line_length(ctx)));
		return push_2(ctx, _closure->res, (temp1 = (struct failure*) alloc(ctx, sizeof(struct failure)), ((*(temp1) = (struct failure) {_closure->path, message3}, 0), temp1)));
	} else {
		return 0;
	}
}
/* lint.lambda0 arr<failure>(file arr<char>) */
struct arr_7 lint__lambda0(struct ctx* ctx, struct lint__lambda0* _closure, struct arr_0 file) {
	if (_closure->options.print_tests__q) {
		print(_op_plus_1(ctx, (struct arr_0) {5, constantarr_0_90}, file));
	} else {
		0;
	}
	return lint_file(ctx, file);
}
/* do-test.lambda1 result<arr<char>, arr<failure>>() */
struct result_3 do_test__lambda1(struct ctx* ctx, struct do_test__lambda1* _closure) {
	return lint(ctx, _closure->noze_path, _closure->options);
}
/* print-failures int32(failures result<arr<char>, arr<failure>>, options test-options) */
int32_t print_failures(struct ctx* ctx, struct result_3 failures, struct test_options options) {
	struct result_3 temp0;
	struct ok_3 o0;
	struct err_2 e1;
	uint64_t n_failures2;
	temp0 = failures;
	switch (temp0.kind) {
		case 0:
			o0 = temp0.as0;
			print(o0.value);
			return 0;
		case 1:
			e1 = temp0.as1;
			each_2(ctx, e1.value, (struct fun_mut1_13) {1, .as1 = 0});
			n_failures2 = e1.value.size;
			print((_op_equal_equal_0(n_failures2, options.max_failures) ? _op_plus_1(ctx, _op_plus_1(ctx, (struct arr_0) {15, constantarr_0_102}, to_str_3(ctx, options.max_failures)), (struct arr_0) {9, constantarr_0_103}) : _op_plus_1(ctx, to_str_3(ctx, n_failures2), (struct arr_0) {9, constantarr_0_103})));
			return to_int32(ctx, n_failures2);
		default:
			return (assert(0),0);
	}
}
/* print-failure void(failure failure) */
uint8_t print_failure(struct ctx* ctx, struct failure* failure) {
	print_bold(ctx);
	print_no_newline(failure->path);
	print_reset(ctx);
	print_no_newline((struct arr_0) {1, constantarr_0_37});
	return print(failure->message);
}
/* print-bold void() */
uint8_t print_bold(struct ctx* ctx) {
	return print_no_newline((struct arr_0) {4, constantarr_0_100});
}
/* print-reset void() */
uint8_t print_reset(struct ctx* ctx) {
	return print_no_newline((struct arr_0) {3, constantarr_0_101});
}
/* print-failures.lambda0 void(it failure) */
uint8_t print_failures__lambda0(struct ctx* ctx, uint8_t _closure, struct failure* it) {
	return print_failure(ctx, it);
}
/* to-int32 int32(n nat) */
int32_t to_int32(struct ctx* ctx, uint64_t n) {
	assert_0(ctx, _op_less_0(n, to_nat_2(ctx, max_int32())));
	return n;
}
/* max-int32 int32() */
int32_t max_int32(void) {
	return 2147483647;
}
/* main (generated) (generated) */
int32_t main(int32_t argc, char** argv) {
	return rt_main(argc, argv, main_0);
}
