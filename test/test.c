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
struct then_0__lambda0;
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
struct map_0__lambda0;
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
struct test_options {
	uint8_t print_tests__q;
	uint8_t overwrite_output__q;
	uint64_t max_failures;
};
struct some_8 {
	struct test_options value;
};
struct some_9 {
	struct arr_1 value;
};
struct arr_5;
struct fun1;
struct parsed_cmd_line_args;
struct dict_0;
struct arr_6 {
	uint64_t size;
	struct arr_1* data;
};
struct some_10 {
	uint64_t value;
};
struct fun_mut1_6;
struct mut_dict_0;
struct mut_arr_2 {
	uint8_t frozen__q;
	uint64_t size;
	uint64_t capacity;
	struct arr_1* data;
};
struct some_11 {
	struct arr_0 value;
};
struct mut_arr_3;
struct fun_mut1_7;
struct fill_mut_arr__lambda0;
struct cell_2 {
	uint8_t value;
};
struct fun_mut2_0;
struct parse_cmd_line_args__lambda0 {
	struct arr_1 t_names;
	struct cell_2* help;
	struct mut_arr_3* values;
};
struct index_of__lambda0 {
	struct arr_0 value;
};
struct fun_mut1_8;
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
struct fun_mut1_9;
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
struct fun0;
struct fun_mut1_10;
struct first_failures__lambda0;
struct first_failures__lambda0__lambda0 {
	struct arr_0 a_descr;
};
struct fun_mut1_11;
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
struct fun_mut1_12;
struct mut_arr_5 {
	uint8_t frozen__q;
	uint64_t size;
	uint64_t capacity;
	struct failure** data;
};
struct flat_map_with_max_size__lambda0;
struct fun_mut1_13;
struct push_all__lambda0 {
	struct mut_arr_5* a;
};
struct run_noze_tests__lambda0 {
	struct arr_0 path_to_noze;
	struct dict_1* env;
	struct test_options options;
};
struct some_13 {
	struct arr_7 value;
};
struct fun_mut1_14;
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
struct fun_mut2_1;
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
struct fun_mut1_15;
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
struct fun_mut1_16;
struct map_1__lambda0;
struct fun_mut2_2;
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
struct fun_mut2_3;
struct fun_mut2_4;
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
struct opt_8 {
	int kind;
	union {
		struct none as0;
		struct some_8 as1;
	};
};
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
struct opt_11 {
	int kind;
	union {
		struct none as0;
		struct some_11 as1;
	};
};
struct result_3 {
	int kind;
	union {
		struct ok_3 as0;
		struct err_2 as1;
	};
};
struct opt_12 {
	int kind;
	union {
		struct none as0;
		struct some_12 as1;
	};
};
struct opt_13 {
	int kind;
	union {
		struct none as0;
		struct some_13 as1;
	};
};
typedef uint8_t (*fun_ptr3_0)(struct ctx*, uint8_t*, struct result_0);
typedef struct fut_0* (*fun_ptr2_0)(struct ctx*, struct arr_1);
typedef uint8_t (*fun_ptr2_1)(struct ctx*, uint8_t*);
typedef uint8_t (*fun_ptr3_1)(struct ctx*, uint8_t*, struct exception);
typedef struct fut_0* (*fun_ptr4_0)(struct ctx*, uint8_t*, struct arr_3, fun_ptr2_0);
typedef uint8_t (*fun_ptr3_2)(struct ctx*, uint8_t*, struct result_1);
typedef struct fut_0* (*fun_ptr2_2)(struct ctx*, uint8_t*);
typedef struct fut_0* (*fun_ptr3_3)(struct ctx*, uint8_t*, uint8_t);
typedef struct arr_0 (*fun_ptr3_4)(struct ctx*, uint8_t*, char*);
typedef struct arr_0 (*fun_ptr3_5)(struct ctx*, uint8_t*, uint64_t);
typedef struct test_options (*fun_ptr3_6)(struct ctx*, uint8_t*, struct arr_5);
typedef uint8_t (*fun_ptr3_7)(struct ctx*, uint8_t*, struct arr_0);
typedef struct opt_9 (*fun_ptr3_8)(struct ctx*, uint8_t*, uint64_t);
typedef uint8_t (*fun_ptr4_1)(struct ctx*, uint8_t*, struct arr_0, struct arr_1);
typedef char (*fun_ptr3_9)(struct ctx*, uint8_t*, uint64_t);
typedef uint8_t (*fun_ptr3_10)(struct ctx*, uint8_t*, char);
typedef struct result_3 (*fun_ptr2_3)(struct ctx*, uint8_t*);
typedef struct result_3 (*fun_ptr3_11)(struct ctx*, uint8_t*, struct arr_0);
typedef uint8_t (*fun_ptr3_12)(struct ctx*, uint8_t*, struct arr_0);
typedef struct arr_7 (*fun_ptr3_13)(struct ctx*, uint8_t*, struct arr_0);
typedef uint8_t (*fun_ptr3_14)(struct ctx*, uint8_t*, struct failure*);
typedef struct opt_13 (*fun_ptr3_15)(struct ctx*, uint8_t*, struct arr_0);
typedef struct arr_0 (*fun_ptr4_2)(struct ctx*, uint8_t*, struct arr_0, struct arr_0);
typedef char* (*fun_ptr3_16)(struct ctx*, uint8_t*, uint64_t);
typedef char* (*fun_ptr3_17)(struct ctx*, uint8_t*, struct arr_0);
typedef uint8_t (*fun_ptr4_3)(struct ctx*, uint8_t*, struct arr_0, struct arr_0);
typedef uint8_t (*fun_ptr4_4)(struct ctx*, uint8_t*, struct arr_0, uint64_t);
typedef uint8_t (*fun_ptr4_5)(struct ctx*, uint8_t*, char, uint64_t);
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
	fun_ptr4_0 fun_ptr;
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
struct then_0__lambda0;
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
struct map_0__lambda0 {
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
struct arr_5 {
	uint64_t size;
	struct opt_9* data;
};
struct fun1 {
	fun_ptr3_6 fun_ptr;
	uint8_t* closure;
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
struct fun_mut1_6 {
	fun_ptr3_7 fun_ptr;
	uint8_t* closure;
};
struct mut_dict_0 {
	struct mut_arr_1* keys;
	struct mut_arr_2* values;
};
struct mut_arr_3 {
	uint8_t frozen__q;
	uint64_t size;
	uint64_t capacity;
	struct opt_9* data;
};
struct fun_mut1_7 {
	fun_ptr3_8 fun_ptr;
	uint8_t* closure;
};
struct fill_mut_arr__lambda0 {
	struct opt_9 value;
};
struct fun_mut2_0 {
	fun_ptr4_1 fun_ptr;
	uint8_t* closure;
};
struct fun_mut1_8 {
	fun_ptr3_9 fun_ptr;
	uint8_t* closure;
};
struct fun_mut1_9 {
	fun_ptr3_10 fun_ptr;
	uint8_t* closure;
};
struct fun0 {
	fun_ptr2_3 fun_ptr;
	uint8_t* closure;
};
struct fun_mut1_10 {
	fun_ptr3_11 fun_ptr;
	uint8_t* closure;
};
struct first_failures__lambda0 {
	struct fun0 b;
};
struct fun_mut1_11 {
	fun_ptr3_12 fun_ptr;
	uint8_t* closure;
};
struct dirent;
struct bytes256;
struct each_child_recursive__lambda0 {
	struct fun_mut1_6 filter;
	struct arr_0 path;
	struct fun_mut1_11 f;
};
struct fun_mut1_12 {
	fun_ptr3_13 fun_ptr;
	uint8_t* closure;
};
struct flat_map_with_max_size__lambda0 {
	struct mut_arr_5* res;
	uint64_t max_size;
	struct fun_mut1_12 mapper;
};
struct fun_mut1_13 {
	fun_ptr3_14 fun_ptr;
	uint8_t* closure;
};
struct fun_mut1_14 {
	fun_ptr3_15 fun_ptr;
	uint8_t* closure;
};
struct fun_mut2_1 {
	fun_ptr4_2 fun_ptr;
	uint8_t* closure;
};
struct posix_spawn_file_actions_t;
struct fun_mut1_15 {
	fun_ptr3_16 fun_ptr;
	uint8_t* closure;
};
struct fun_mut1_16 {
	fun_ptr3_17 fun_ptr;
	uint8_t* closure;
};
struct map_1__lambda0 {
	struct fun_mut1_16 mapper;
	struct arr_1 a;
};
struct fun_mut2_2 {
	fun_ptr4_3 fun_ptr;
	uint8_t* closure;
};
struct fun_mut2_3 {
	fun_ptr4_4 fun_ptr;
	uint8_t* closure;
};
struct fun_mut2_4 {
	fun_ptr4_5 fun_ptr;
	uint8_t* closure;
};
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
struct then_0__lambda0 {
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
struct dirent {
	uint64_t d_ino;
	int64_t d_off;
	uint16_t d_reclen;
	char d_type;
	struct bytes256 d_name;
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
char constantarr_0_13[11];
char constantarr_0_14[16];
char constantarr_0_15[12];
char constantarr_0_16[2];
char constantarr_0_17[27];
char constantarr_0_18[26];
char constantarr_0_19[4];
char constantarr_0_20[15];
char constantarr_0_21[1];
char constantarr_0_22[1];
char constantarr_0_23[1];
char constantarr_0_24[1];
char constantarr_0_25[1];
char constantarr_0_26[1];
char constantarr_0_27[1];
char constantarr_0_28[1];
char constantarr_0_29[1];
char constantarr_0_30[1];
char constantarr_0_31[3];
char constantarr_0_32[18];
char constantarr_0_33[8];
char constantarr_0_34[38];
char constantarr_0_35[64];
char constantarr_0_36[1];
char constantarr_0_37[1];
char constantarr_0_38[1];
char constantarr_0_39[14];
char constantarr_0_40[3];
char constantarr_0_41[4];
char constantarr_0_42[1];
char constantarr_0_43[1];
char constantarr_0_44[2];
char constantarr_0_45[2];
char constantarr_0_46[3];
char constantarr_0_47[5];
char constantarr_0_48[14];
char constantarr_0_49[9];
char constantarr_0_50[11];
char constantarr_0_51[1];
char constantarr_0_52[23];
char constantarr_0_53[31];
char constantarr_0_54[12];
char constantarr_0_55[14];
char constantarr_0_56[5];
char constantarr_0_57[5];
char constantarr_0_58[20];
char constantarr_0_59[31];
char constantarr_0_60[7];
char constantarr_0_61[7];
char constantarr_0_62[12];
char constantarr_0_63[2];
char constantarr_0_64[29];
char constantarr_0_65[30];
char constantarr_0_66[1];
char constantarr_0_67[1];
char constantarr_0_68[4];
char constantarr_0_69[22];
char constantarr_0_70[9];
char constantarr_0_71[3];
char constantarr_0_72[11];
char constantarr_0_73[7];
char constantarr_0_74[8];
char constantarr_0_75[9];
char constantarr_0_76[8];
char constantarr_0_77[4];
char constantarr_0_78[10];
char constantarr_0_79[12];
char constantarr_0_80[14];
char constantarr_0_81[8];
char constantarr_0_82[4];
char constantarr_0_83[4];
char constantarr_0_84[5];
char constantarr_0_85[7];
char constantarr_0_86[1];
char constantarr_0_87[4];
char constantarr_0_88[1];
char constantarr_0_89[3];
char constantarr_0_90[4];
char constantarr_0_91[10];
char constantarr_0_92[5];
char constantarr_0_93[21];
char constantarr_0_94[3];
char constantarr_0_95[2];
char constantarr_0_96[5];
char constantarr_0_97[24];
char constantarr_0_98[1];
char constantarr_0_99[3];
char constantarr_0_100[4];
char constantarr_0_101[28];
char constantarr_0_102[7];
char constantarr_0_103[6];
char constantarr_0_104[4];
char constantarr_0_105[3];
char constantarr_0_106[15];
char constantarr_0_107[9];
struct arr_0 constantarr_1_0[3];
struct arr_0 constantarr_1_1[4];
struct arr_0 constantarr_1_2[5];
struct arr_0 constantarr_1_3[6];
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
char constantarr_0_13[11] = "print-tests";
char constantarr_0_14[16] = "overwrite-output";
char constantarr_0_15[12] = "max-failures";
char constantarr_0_16[2] = "--";
char constantarr_0_17[27] = "tried to force empty option";
char constantarr_0_18[26] = "Should be no nameless args";
char constantarr_0_19[4] = "help";
char constantarr_0_20[15] = "Unexpected arg ";
char constantarr_0_21[1] = "0";
char constantarr_0_22[1] = "1";
char constantarr_0_23[1] = "2";
char constantarr_0_24[1] = "3";
char constantarr_0_25[1] = "4";
char constantarr_0_26[1] = "5";
char constantarr_0_27[1] = "6";
char constantarr_0_28[1] = "7";
char constantarr_0_29[1] = "8";
char constantarr_0_30[1] = "9";
char constantarr_0_31[3] = "100";
char constantarr_0_32[18] = "test -- runs tests";
char constantarr_0_33[8] = "options:";
char constantarr_0_34[38] = "\t--print-tests  : print every test run";
char constantarr_0_35[64] = "\t--max-failures : stop after this many failures. Defaults to 10.";
char constantarr_0_36[1] = "-";
char constantarr_0_37[1] = "+";
char constantarr_0_38[1] = "/";
char constantarr_0_39[14] = "/proc/self/exe";
char constantarr_0_40[3] = "bin";
char constantarr_0_41[4] = "noze";
char constantarr_0_42[1] = "=";
char constantarr_0_43[1] = ".";
char constantarr_0_44[2] = "..";
char constantarr_0_45[2] = "nz";
char constantarr_0_46[3] = "ast";
char constantarr_0_47[5] = "model";
char constantarr_0_48[14] = "concrete-model";
char constantarr_0_49[9] = "low-model";
char constantarr_0_50[11] = "noze print ";
char constantarr_0_51[1] = " ";
char constantarr_0_52[23] = "spawn-and-wait-result: ";
char constantarr_0_53[31] = "Process terminated with signal ";
char constantarr_0_54[12] = "WAIT STOPPED";
char constantarr_0_55[14] = " is not a file";
char constantarr_0_56[5] = "print";
char constantarr_0_57[5] = ".tata";
char constantarr_0_58[20] = "failed to open file ";
char constantarr_0_59[31] = "failed to open file for write: ";
char constantarr_0_60[7] = "errno: ";
char constantarr_0_61[7] = "flags: ";
char constantarr_0_62[12] = "permission: ";
char constantarr_0_63[2] = "-1";
char constantarr_0_64[29] = " does not exist. actual was:\n";
char constantarr_0_65[30] = " was not as expected. actual:\n";
char constantarr_0_66[1] = "\x1b";
char constantarr_0_67[1] = "m";
char constantarr_0_68[4] = ".err";
char constantarr_0_69[22] = "unexpected exit code: ";
char constantarr_0_70[9] = "noze run ";
char constantarr_0_71[3] = "run";
char constantarr_0_72[11] = "--interpret";
char constantarr_0_73[7] = ".stdout";
char constantarr_0_74[8] = "status: ";
char constantarr_0_75[9] = "\nstdout:\n";
char constantarr_0_76[8] = "stderr:\n";
char constantarr_0_77[4] = "ran ";
char constantarr_0_78[10] = " tests in ";
char constantarr_0_79[12] = "parse-errors";
char constantarr_0_80[14] = "compile-errors";
char constantarr_0_81[8] = "runnable";
char constantarr_0_82[4] = ".bmp";
char constantarr_0_83[4] = ".png";
char constantarr_0_84[5] = ".wasm";
char constantarr_0_85[7] = "libfirm";
char constantarr_0_86[1] = "c";
char constantarr_0_87[4] = "data";
char constantarr_0_88[1] = "o";
char constantarr_0_89[3] = "out";
char constantarr_0_90[4] = "tata";
char constantarr_0_91[10] = "tmLanguage";
char constantarr_0_92[5] = "lint ";
char constantarr_0_93[21] = "file does not exist: ";
char constantarr_0_94[3] = "err";
char constantarr_0_95[2] = "  ";
char constantarr_0_96[5] = "line ";
char constantarr_0_97[24] = " contains a double space";
char constantarr_0_98[1] = "\t";
char constantarr_0_99[3] = "120";
char constantarr_0_100[4] = " is ";
char constantarr_0_101[28] = " columns long, should be <= ";
char constantarr_0_102[7] = "linted ";
char constantarr_0_103[6] = " files";
char constantarr_0_104[4] = "\x1b[1m";
char constantarr_0_105[3] = "\x1b[m";
char constantarr_0_106[15] = "hit maximum of ";
char constantarr_0_107[9] = " failures";
struct arr_0 constantarr_1_0[3] = {{11, constantarr_0_13}, {16, constantarr_0_14}, {12, constantarr_0_15}};
struct arr_0 constantarr_1_1[4] = {{3, constantarr_0_46}, {5, constantarr_0_47}, {14, constantarr_0_48}, {9, constantarr_0_49}};
struct arr_0 constantarr_1_2[5] = {{4, constantarr_0_82}, {4, constantarr_0_68}, {4, constantarr_0_83}, {5, constantarr_0_57}, {5, constantarr_0_84}};
struct arr_0 constantarr_1_3[6] = {{1, constantarr_0_86}, {4, constantarr_0_87}, {1, constantarr_0_88}, {3, constantarr_0_89}, {4, constantarr_0_90}, {10, constantarr_0_91}};
int32_t rt_main(int32_t argc, char** argv, fun_ptr2_0 main_ptr);
uint8_t drop_0(struct arr_0 t);
struct arr_0 to_str_0(char* a);
struct arr_0 arr_from_begin_end(char* begin, char* end);
uint64_t _op_minus_0(char* a, char* b);
char* find_cstr_end(char* a);
char* find_char_in_cstr(char* a, char c);
uint8_t _op_equal_equal_0(char a, char b);
struct comparison compare_8(char a, char b);
char literal_0(struct arr_0 a);
char noctx_at_0(struct arr_0 a, uint64_t index);
uint8_t hard_assert(uint8_t condition);
uint8_t _op_less_0(uint64_t a, uint64_t b);
struct comparison compare_13(uint64_t a, uint64_t b);
char* todo_0();
char* incr_0(char* p);
struct lock new_lock();
struct _atomic_bool new_atomic_bool();
struct arr_2 empty_arr_0();
struct condition new_condition();
struct vat new_vat(struct global_ctx* gctx, uint64_t id, uint64_t max_threads);
struct mut_arr_0 new_mut_arr_by_val_with_capacity_from_unmanaged_memory(uint64_t capacity);
uint64_t* unmanaged_alloc_elements_0(uint64_t size_elements);
uint8_t* unmanaged_alloc_bytes(uint64_t size);
extern uint8_t* malloc(uint64_t size);
uint8_t hard_forbid(uint8_t condition);
uint8_t null__q_0(uint8_t* a);
uint8_t _op_equal_equal_1(uint64_t a, uint64_t b);
struct gc new_gc();
struct mut_bag new_mut_bag();
struct thread_safe_counter new_thread_safe_counter_0();
struct thread_safe_counter new_thread_safe_counter_1(uint64_t init);
uint8_t default_exception_handler(struct ctx* ctx, struct exception e);
uint8_t print_err_sync_no_newline(struct arr_0 s);
uint8_t write_sync_no_newline(int32_t fd, struct arr_0 s);
extern int64_t write(int32_t fd, uint8_t* buff, uint64_t n_bytes);
uint8_t _op_equal_equal_2(int64_t a, int64_t b);
struct comparison compare_37(int64_t a, int64_t b);
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
struct ctx new_ctx(struct global_ctx* gctx, struct thread_local_stuff* tls, struct vat* vat, uint64_t actor_id);
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
struct comparison compare_72(int32_t a, int32_t b);
uint64_t noctx_incr(uint64_t n);
uint64_t billion_0();
uint64_t million_0();
uint8_t release_lock(struct lock* l);
uint8_t must_unset(struct _atomic_bool* a);
uint8_t try_unset(struct _atomic_bool* a);
struct fut_0* add_first_task(struct ctx* ctx, struct arr_3 all_args, fun_ptr2_0 main_ptr);
struct fut_0* then2(struct ctx* ctx, struct fut_1* f, struct fun_ref0 cb);
struct fut_0* then_0(struct ctx* ctx, struct fut_1* f, struct fun_ref1 cb);
struct fut_0* new_unresolved_fut(struct ctx* ctx);
uint8_t then_void_0(struct ctx* ctx, struct fut_1* f, struct fun_mut1_2 cb);
uint8_t call_0(struct ctx* ctx, struct fun_mut1_2 f, struct result_1 p0);
uint8_t call_with_ctx_0(struct ctx* c, struct fun_mut1_2 f, struct result_1 p0);
uint8_t forward_to(struct ctx* ctx, struct fut_0* from, struct fut_0* to);
uint8_t then_void_1(struct ctx* ctx, struct fut_0* f, struct fun_mut1_0 cb);
uint8_t call_1(struct ctx* ctx, struct fun_mut1_0 f, struct result_0 p0);
uint8_t call_with_ctx_1(struct ctx* c, struct fun_mut1_0 f, struct result_0 p0);
uint8_t resolve_or_reject(struct ctx* ctx, struct fut_0* f, struct result_0 result);
uint8_t resolve_or_reject_recur(struct ctx* ctx, struct opt_0 node, struct result_0 value);
uint8_t drop_1(uint8_t t);
uint8_t forward_to__lambda0(struct ctx* ctx, struct forward_to__lambda0* _closure, struct result_0 it);
struct fut_0* call_2(struct ctx* ctx, struct fun_ref1 f, uint8_t p0);
struct vat* get_vat(struct ctx* ctx, uint64_t vat_id);
struct vat* at_0(struct ctx* ctx, struct arr_2 a, uint64_t index);
uint8_t assert_0(struct ctx* ctx, uint8_t condition);
uint8_t assert_1(struct ctx* ctx, uint8_t condition, struct arr_0 message);
uint8_t fail_0(struct ctx* ctx, struct arr_0 reason);
uint8_t throw_0(struct ctx* ctx, struct exception e);
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
uint8_t add_0(struct mut_bag* bag, struct mut_bag_node* node);
uint8_t broadcast(struct condition* c);
uint8_t catch(struct ctx* ctx, struct fun_mut0_0 try, struct fun_mut1_1 catcher);
uint8_t catch_with_exception_ctx(struct ctx* ctx, struct exception_ctx* ec, struct fun_mut0_0 try, struct fun_mut1_1 catcher);
struct bytes64 zero_0();
struct bytes32 zero_1();
struct bytes16 zero_2();
struct bytes128 zero_3();
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
uint8_t then_0__lambda0(struct ctx* ctx, struct then_0__lambda0* _closure, struct result_1 result);
struct fut_0* call_6(struct ctx* ctx, struct fun_ref0 f);
struct fut_0* call_7(struct ctx* ctx, struct fun_mut0_1 f);
struct fut_0* call_with_ctx_5(struct ctx* c, struct fun_mut0_1 f);
uint8_t call_6__lambda0__lambda0(struct ctx* ctx, struct call_6__lambda0__lambda0* _closure);
uint8_t call_6__lambda0__lambda1(struct ctx* ctx, struct call_6__lambda0__lambda1* _closure, struct exception it);
uint8_t call_6__lambda0(struct ctx* ctx, struct call_6__lambda0* _closure);
struct fut_0* then2__lambda0(struct ctx* ctx, struct then2__lambda0* _closure, uint8_t ignore);
struct vat_and_actor_id cur_actor(struct ctx* ctx);
struct fut_1* resolved_0(struct ctx* ctx, uint8_t value);
struct arr_3 tail_0(struct ctx* ctx, struct arr_3 a);
uint8_t forbid_0(struct ctx* ctx, uint8_t condition);
uint8_t forbid_1(struct ctx* ctx, uint8_t condition, struct arr_0 message);
uint8_t empty__q_1(struct arr_3 a);
struct arr_3 slice_starting_at_0(struct ctx* ctx, struct arr_3 a, uint64_t begin);
uint8_t _op_less_equal_0(uint64_t a, uint64_t b);
struct arr_3 slice_0(struct ctx* ctx, struct arr_3 a, uint64_t begin, uint64_t size);
uint64_t _op_plus_0(struct ctx* ctx, uint64_t a, uint64_t b);
uint8_t _op_greater_equal(uint64_t a, uint64_t b);
uint64_t _op_minus_1(struct ctx* ctx, uint64_t a, uint64_t b);
struct arr_1 map_0(struct ctx* ctx, struct arr_3 a, struct fun_mut1_4 mapper);
struct arr_1 make_arr_0(struct ctx* ctx, uint64_t size, struct fun_mut1_5 f);
struct arr_1 freeze_0(struct mut_arr_1* a);
struct arr_1 unsafe_as_arr_0(struct mut_arr_1* a);
struct mut_arr_1* make_mut_arr_0(struct ctx* ctx, uint64_t size, struct fun_mut1_5 f);
struct mut_arr_1* new_uninitialized_mut_arr_0(struct ctx* ctx, uint64_t size);
struct arr_0* uninitialized_data_0(struct ctx* ctx, uint64_t size);
uint8_t* alloc(struct ctx* ctx, uint64_t size);
uint8_t* gc_alloc(struct ctx* ctx, struct gc* gc, uint64_t size);
struct gc* get_gc(struct ctx* ctx);
struct gc_ctx* get_gc_ctx_1(struct ctx* ctx);
uint8_t make_mut_arr_worker_0(struct ctx* ctx, struct mut_arr_1* m, uint64_t i, struct fun_mut1_5 f);
uint8_t set_at_0(struct ctx* ctx, struct mut_arr_1* a, uint64_t index, struct arr_0 value);
uint8_t noctx_set_at_0(struct mut_arr_1* a, uint64_t index, struct arr_0 value);
struct arr_0 call_8(struct ctx* ctx, struct fun_mut1_5 f, uint64_t p0);
struct arr_0 call_with_ctx_6(struct ctx* c, struct fun_mut1_5 f, uint64_t p0);
uint64_t incr_1(struct ctx* ctx, uint64_t n);
struct arr_0 call_9(struct ctx* ctx, struct fun_mut1_4 f, char* p0);
struct arr_0 call_with_ctx_7(struct ctx* c, struct fun_mut1_4 f, char* p0);
char* at_1(struct ctx* ctx, struct arr_3 a, uint64_t index);
char* noctx_at_2(struct arr_3 a, uint64_t index);
struct arr_0 map_0__lambda0(struct ctx* ctx, struct map_0__lambda0* _closure, uint64_t i);
struct arr_0 add_first_task__lambda0__lambda0(struct ctx* ctx, uint8_t* _closure, char* it);
struct fut_0* add_first_task__lambda0(struct ctx* ctx, struct add_first_task__lambda0* _closure);
struct fut_0* do_main__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr_3 all_args, fun_ptr2_0 main_ptr);
struct fut_0* call_with_ctx_8(struct ctx* c, struct fun2 f, struct arr_3 p0, fun_ptr2_0 p1);
uint8_t run_threads(uint64_t n_threads, struct global_ctx* gctx);
struct thread_args* unmanaged_alloc_elements_1(uint64_t size_elements);
uint64_t noctx_decr_0(uint64_t n);
uint8_t start_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads, struct thread_args* thread_args_begin, struct global_ctx* gctx);
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
struct opt_4 find_and_remove_first_doable_task(struct vat* vat);
struct opt_7 find_and_remove_first_doable_task_recur(struct vat* vat, struct opt_2 opt_node);
uint8_t contains__q_0(struct mut_arr_0* a, uint64_t value);
uint8_t contains_recur__q_0(struct arr_4 a, uint64_t value, uint64_t i);
uint64_t noctx_at_3(struct arr_4 a, uint64_t index);
struct arr_4 temp_as_arr(struct mut_arr_0* a);
uint8_t push_capacity_must_be_sufficient(struct mut_arr_0* a, uint64_t value);
uint8_t noctx_set_at_1(struct mut_arr_0* a, uint64_t index, uint64_t value);
uint8_t empty__q_4(struct opt_6 a);
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
uint8_t wait_on(struct condition* c, uint64_t last_checked);
uint8_t* start_threads_recur__lambda0(uint8_t* args_ptr);
extern int32_t pthread_create(struct cell_0* thread, uint8_t* attr, fun_ptr1 start_routine, uint8_t* arg);
struct cell_0* as_cell(uint64_t* p);
int32_t eagain();
int32_t ten_1();
uint8_t join_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads);
uint8_t join_one_thread(uint64_t tid);
extern int32_t pthread_join(uint64_t thread, struct cell_1* thread_return);
int32_t einval();
int32_t esrch();
uint8_t* get_0(struct cell_1* c);
uint8_t unmanaged_free_0(uint64_t* p);
extern void free(uint8_t* p);
uint8_t unmanaged_free_1(struct thread_args* p);
struct result_0 must_be_resolved(struct fut_0* f);
struct result_0 hard_unreachable_0();
struct fut_0* main_0(struct ctx* ctx, struct arr_1 args);
struct opt_8 parse_cmd_line_args(struct ctx* ctx, struct arr_1 args, struct arr_1 t_names, struct fun1 make_t);
struct parsed_cmd_line_args* parse_cmd_line_args_dynamic(struct ctx* ctx, struct arr_1 args);
struct opt_10 find_index(struct ctx* ctx, struct arr_1 a, struct fun_mut1_6 pred);
struct opt_10 find_index_recur(struct ctx* ctx, struct arr_1 a, uint64_t index, struct fun_mut1_6 pred);
uint8_t call_10(struct ctx* ctx, struct fun_mut1_6 f, struct arr_0 p0);
uint8_t call_with_ctx_9(struct ctx* c, struct fun_mut1_6 f, struct arr_0 p0);
struct arr_0 at_2(struct ctx* ctx, struct arr_1 a, uint64_t index);
struct arr_0 noctx_at_5(struct arr_1 a, uint64_t index);
uint8_t starts_with__q(struct ctx* ctx, struct arr_0 a, struct arr_0 start);
uint8_t arr_eq__q(struct ctx* ctx, struct arr_0 a, struct arr_0 b);
char first_0(struct ctx* ctx, struct arr_0 a);
char at_3(struct ctx* ctx, struct arr_0 a, uint64_t index);
struct arr_0 tail_1(struct ctx* ctx, struct arr_0 a);
struct arr_0 slice_starting_at_1(struct ctx* ctx, struct arr_0 a, uint64_t begin);
struct arr_0 slice_1(struct ctx* ctx, struct arr_0 a, uint64_t begin, uint64_t size);
uint8_t parse_cmd_line_args_dynamic__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr_0 it);
struct dict_0* empty_dict(struct ctx* ctx);
struct arr_1 empty_arr_1();
struct arr_6 empty_arr_2();
struct arr_1 slice_up_to_0(struct ctx* ctx, struct arr_1 a, uint64_t size);
struct arr_1 slice_2(struct ctx* ctx, struct arr_1 a, uint64_t begin, uint64_t size);
struct arr_1 slice_starting_at_2(struct ctx* ctx, struct arr_1 a, uint64_t begin);
uint8_t _op_equal_equal_4(struct arr_0 a, struct arr_0 b);
struct comparison compare_253(struct arr_0 a, struct arr_0 b);
uint8_t parse_cmd_line_args_dynamic__lambda1(struct ctx* ctx, uint8_t* _closure, struct arr_0 it);
struct dict_0* parse_named_args(struct ctx* ctx, struct arr_1 args);
struct mut_dict_0 new_mut_dict_0(struct ctx* ctx);
struct mut_arr_1* new_mut_arr_0(struct ctx* ctx);
struct mut_arr_2* new_mut_arr_1(struct ctx* ctx);
uint8_t parse_named_args_recur(struct ctx* ctx, struct arr_1 args, struct mut_dict_0 builder);
struct arr_0 remove_start(struct ctx* ctx, struct arr_0 a, struct arr_0 start);
struct arr_0 force(struct ctx* ctx, struct opt_11 a);
struct arr_0 fail_1(struct ctx* ctx, struct arr_0 reason);
struct arr_0 throw_1(struct ctx* ctx, struct exception e);
struct arr_0 todo_2();
struct opt_11 try_remove_start(struct ctx* ctx, struct arr_0 a, struct arr_0 start);
struct arr_0 first_1(struct ctx* ctx, struct arr_1 a);
uint8_t empty__q_6(struct arr_1 a);
struct arr_1 tail_2(struct ctx* ctx, struct arr_1 a);
uint8_t parse_named_args_recur__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr_0 it);
uint8_t add_1(struct ctx* ctx, struct mut_dict_0 m, struct arr_0 key, struct arr_1 value);
uint8_t has__q_0(struct ctx* ctx, struct mut_dict_0 d, struct arr_0 key);
uint8_t has__q_1(struct ctx* ctx, struct dict_0* d, struct arr_0 key);
uint8_t has__q_2(struct opt_9 a);
uint8_t empty__q_7(struct opt_9 a);
struct opt_9 get_1(struct ctx* ctx, struct dict_0* d, struct arr_0 key);
struct opt_9 get_recursive_0(struct ctx* ctx, struct arr_1 keys, struct arr_6 values, uint64_t idx, struct arr_0 key);
struct arr_1 at_4(struct ctx* ctx, struct arr_6 a, uint64_t index);
struct arr_1 noctx_at_6(struct arr_6 a, uint64_t index);
struct dict_0* unsafe_as_dict_0(struct ctx* ctx, struct mut_dict_0 m);
struct arr_6 unsafe_as_arr_1(struct mut_arr_2* a);
uint8_t push_0(struct ctx* ctx, struct mut_arr_1* a, struct arr_0 value);
uint8_t increase_capacity_to_0(struct ctx* ctx, struct mut_arr_1* a, uint64_t new_capacity);
uint8_t copy_data_from_0(struct ctx* ctx, struct arr_0* to, struct arr_0* from, uint64_t len);
uint8_t copy_data_from_small_0(struct ctx* ctx, struct arr_0* to, struct arr_0* from, uint64_t len);
struct arr_0* incr_2(struct arr_0* p);
uint64_t decr(struct ctx* ctx, uint64_t a);
uint64_t wrap_decr_0(uint64_t a);
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
struct arr_1* incr_3(struct arr_1* p);
uint8_t ensure_capacity_1(struct ctx* ctx, struct mut_arr_2* a, uint64_t capacity);
struct dict_0* freeze_1(struct ctx* ctx, struct mut_dict_0 m);
struct arr_6 freeze_2(struct mut_arr_2* a);
struct arr_1 slice_after_0(struct ctx* ctx, struct arr_1 a, uint64_t before_begin);
struct mut_arr_3* fill_mut_arr(struct ctx* ctx, uint64_t size, struct opt_9 value);
struct mut_arr_3* make_mut_arr_1(struct ctx* ctx, uint64_t size, struct fun_mut1_7 f);
struct mut_arr_3* new_uninitialized_mut_arr_1(struct ctx* ctx, uint64_t size);
struct opt_9* uninitialized_data_2(struct ctx* ctx, uint64_t size);
uint8_t make_mut_arr_worker_1(struct ctx* ctx, struct mut_arr_3* m, uint64_t i, struct fun_mut1_7 f);
uint8_t set_at_1(struct ctx* ctx, struct mut_arr_3* a, uint64_t index, struct opt_9 value);
uint8_t noctx_set_at_2(struct mut_arr_3* a, uint64_t index, struct opt_9 value);
struct opt_9 call_11(struct ctx* ctx, struct fun_mut1_7 f, uint64_t p0);
struct opt_9 call_with_ctx_10(struct ctx* c, struct fun_mut1_7 f, uint64_t p0);
struct opt_9 fill_mut_arr__lambda0(struct ctx* ctx, struct fill_mut_arr__lambda0* _closure, uint64_t ignore);
uint8_t each_0(struct ctx* ctx, struct dict_0* d, struct fun_mut2_0 f);
uint8_t empty__q_8(struct ctx* ctx, struct dict_0* d);
uint8_t call_12(struct ctx* ctx, struct fun_mut2_0 f, struct arr_0 p0, struct arr_1 p1);
uint8_t call_with_ctx_11(struct ctx* c, struct fun_mut2_0 f, struct arr_0 p0, struct arr_1 p1);
struct arr_1 first_2(struct ctx* ctx, struct arr_6 a);
uint8_t empty__q_9(struct arr_6 a);
struct arr_6 tail_3(struct ctx* ctx, struct arr_6 a);
struct arr_6 slice_starting_at_3(struct ctx* ctx, struct arr_6 a, uint64_t begin);
struct arr_6 slice_3(struct ctx* ctx, struct arr_6 a, uint64_t begin, uint64_t size);
struct opt_10 index_of(struct ctx* ctx, struct arr_1 a, struct arr_0 value);
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
char call_13(struct ctx* ctx, struct fun_mut1_8 f, uint64_t p0);
char call_with_ctx_12(struct ctx* c, struct fun_mut1_8 f, uint64_t p0);
char _op_plus_1__lambda0(struct ctx* ctx, struct _op_plus_1__lambda0* _closure, uint64_t i);
struct opt_9 at_5(struct ctx* ctx, struct mut_arr_3* a, uint64_t index);
struct opt_9 noctx_at_7(struct mut_arr_3* a, uint64_t index);
uint8_t parse_cmd_line_args__lambda0(struct ctx* ctx, struct parse_cmd_line_args__lambda0* _closure, struct arr_0 key, struct arr_1 value);
uint8_t get_2(struct cell_2* c);
struct test_options call_14(struct ctx* ctx, struct fun1 f, struct arr_5 p0);
struct test_options call_with_ctx_13(struct ctx* c, struct fun1 f, struct arr_5 p0);
struct arr_5 freeze_4(struct mut_arr_3* a);
struct arr_5 unsafe_as_arr_3(struct mut_arr_3* a);
struct opt_9 at_6(struct ctx* ctx, struct arr_5 a, uint64_t index);
struct opt_9 noctx_at_8(struct arr_5 a, uint64_t index);
uint64_t literal_1(struct ctx* ctx, struct arr_0 s);
struct arr_0 rtail(struct ctx* ctx, struct arr_0 a);
uint64_t char_to_nat(char c);
uint64_t todo_3();
char last(struct ctx* ctx, struct arr_0 a);
struct test_options main_0__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr_5 values);
struct fut_0* resolved_1(struct ctx* ctx, int32_t value);
uint8_t print_help(struct ctx* ctx);
uint8_t print_sync(struct arr_0 s);
uint8_t print_sync_no_newline(struct arr_0 s);
int32_t stdout_fd();
int32_t literal_2(struct ctx* ctx, struct arr_0 s);
int64_t literal_3(struct ctx* ctx, struct arr_0 s);
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
int64_t neg_one_0();
int64_t to_int(struct ctx* ctx, uint64_t n);
int32_t do_test(struct ctx* ctx, struct test_options options);
struct arr_0 parent_path(struct ctx* ctx, struct arr_0 a);
struct opt_10 r_index_of(struct ctx* ctx, struct arr_0 a, char value);
struct opt_10 find_rindex(struct ctx* ctx, struct arr_0 a, struct fun_mut1_9 pred);
struct opt_10 find_rindex_recur(struct ctx* ctx, struct arr_0 a, uint64_t index, struct fun_mut1_9 pred);
uint8_t call_15(struct ctx* ctx, struct fun_mut1_9 f, char p0);
uint8_t call_with_ctx_14(struct ctx* c, struct fun_mut1_9 f, char p0);
uint8_t r_index_of__lambda0(struct ctx* ctx, struct r_index_of__lambda0* _closure, char it);
struct arr_0 slice_up_to_1(struct ctx* ctx, struct arr_0 a, uint64_t size);
struct arr_0 current_executable_path(struct ctx* ctx);
struct arr_0 read_link(struct ctx* ctx, struct arr_0 path);
extern int64_t readlink(char* path, char* buf, uint64_t len);
char* to_c_str(struct ctx* ctx, struct arr_0 a);
uint8_t check_errno_if_neg_one(struct ctx* ctx, int64_t e);
uint8_t check_posix_error(struct ctx* ctx, int32_t e);
extern int32_t errno;
uint8_t hard_unreachable_1();
uint64_t to_nat_0(struct ctx* ctx, int64_t i);
uint8_t negative__q(struct ctx* ctx, int64_t i);
struct arr_0 child_path(struct ctx* ctx, struct arr_0 a, struct arr_0 child_name);
struct dict_1* get_environ(struct ctx* ctx);
struct mut_dict_1 new_mut_dict_1(struct ctx* ctx);
uint8_t get_environ_recur(struct ctx* ctx, char** env, struct mut_dict_1 res);
uint8_t null__q_2(char* a);
uint8_t add_2(struct ctx* ctx, struct mut_dict_1 m, struct key_value_pair* pair);
uint8_t add_3(struct ctx* ctx, struct mut_dict_1 m, struct arr_0 key, struct arr_0 value);
uint8_t has__q_3(struct ctx* ctx, struct mut_dict_1 d, struct arr_0 key);
uint8_t has__q_4(struct ctx* ctx, struct dict_1* d, struct arr_0 key);
uint8_t has__q_5(struct opt_11 a);
uint8_t empty__q_10(struct opt_11 a);
struct opt_11 get_3(struct ctx* ctx, struct dict_1* d, struct arr_0 key);
struct opt_11 get_recursive_1(struct ctx* ctx, struct arr_1 keys, struct arr_1 values, uint64_t idx, struct arr_0 key);
struct dict_1* unsafe_as_dict_1(struct ctx* ctx, struct mut_dict_1 m);
struct key_value_pair* parse_environ_entry(struct ctx* ctx, char* entry);
char** incr_4(char** p);
extern char** environ;
struct dict_1* freeze_5(struct ctx* ctx, struct mut_dict_1 m);
struct result_3 first_failures(struct ctx* ctx, struct result_3 a, struct fun0 b);
struct result_3 then_1(struct ctx* ctx, struct result_3 a, struct fun_mut1_10 f);
struct result_3 call_16(struct ctx* ctx, struct fun_mut1_10 f, struct arr_0 p0);
struct result_3 call_with_ctx_15(struct ctx* c, struct fun_mut1_10 f, struct arr_0 p0);
struct result_3 call_17(struct ctx* ctx, struct fun0 f);
struct result_3 call_with_ctx_16(struct ctx* c, struct fun0 f);
struct result_3 first_failures__lambda0__lambda0(struct ctx* ctx, struct first_failures__lambda0__lambda0* _closure, struct arr_0 b_descr);
struct result_3 first_failures__lambda0(struct ctx* ctx, struct first_failures__lambda0* _closure, struct arr_0 a_descr);
struct result_3 run_noze_tests(struct ctx* ctx, struct arr_0 path, struct arr_0 path_to_noze, struct dict_1* env, struct test_options options);
struct arr_1 list_tests(struct ctx* ctx, struct arr_0 path);
uint8_t list_tests__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr_0 s);
uint8_t each_child_recursive(struct ctx* ctx, struct arr_0 path, struct fun_mut1_6 filter, struct fun_mut1_11 f);
uint8_t is_dir__q_0(struct ctx* ctx, struct arr_0 path);
uint8_t is_dir__q_1(struct ctx* ctx, char* path);
struct opt_12 get_stat(struct ctx* ctx, char* path);
struct stat_t* empty_stat(struct ctx* ctx);
extern int32_t stat(char* path, struct stat_t* buf);
int32_t neg_one_1();
int32_t enoent();
struct opt_12 todo_4();
uint8_t todo_5();
uint8_t _op_equal_equal_5(uint32_t a, uint32_t b);
struct comparison compare_442(uint32_t a, uint32_t b);
uint32_t s_ifmt(struct ctx* ctx);
uint32_t two_pow_0(uint32_t pow);
uint8_t zero__q_2(uint32_t n);
uint32_t wrap_decr_1(uint32_t a);
uint32_t two_3();
uint32_t wrap_incr_3(uint32_t a);
uint32_t twelve();
uint32_t eight_2();
uint32_t seven_3();
uint32_t six_3();
uint32_t five_3();
uint32_t four_3();
uint32_t three_3();
uint32_t fifteen();
uint32_t fourteen();
uint32_t s_ifdir(struct ctx* ctx);
uint8_t each_1(struct ctx* ctx, struct arr_1 a, struct fun_mut1_11 f);
uint8_t call_18(struct ctx* ctx, struct fun_mut1_11 f, struct arr_0 p0);
uint8_t call_with_ctx_17(struct ctx* c, struct fun_mut1_11 f, struct arr_0 p0);
struct arr_1 read_dir_0(struct ctx* ctx, struct arr_0 path);
struct arr_1 read_dir_1(struct ctx* ctx, char* path);
extern uint8_t* opendir(char* name);
uint8_t read_dir_recur(struct ctx* ctx, uint8_t* dirp, struct mut_arr_1* res);
struct bytes256 zero_4();
extern int32_t readdir_r(uint8_t* dirp, struct dirent* entry, struct cell_3* result);
struct dirent* get_4(struct cell_3* c);
uint8_t ref_eq__q(struct dirent* a, struct dirent* b);
struct arr_0 get_dirent_name(struct dirent* d);
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
struct opt_11 get_extension(struct ctx* ctx, struct arr_0 name);
struct opt_10 last_index_of(struct ctx* ctx, struct arr_0 s, char c);
struct arr_0 slice_after_1(struct ctx* ctx, struct arr_0 a, uint64_t before_begin);
struct arr_0 base_name(struct ctx* ctx, struct arr_0 path);
uint8_t list_tests__lambda1(struct ctx* ctx, struct list_tests__lambda1* _closure, struct arr_0 child);
struct arr_7 flat_map_with_max_size(struct ctx* ctx, struct arr_1 a, uint64_t max_size, struct fun_mut1_12 mapper);
struct mut_arr_5* new_mut_arr_2(struct ctx* ctx);
uint8_t push_all(struct ctx* ctx, struct mut_arr_5* a, struct arr_7 values);
uint8_t each_2(struct ctx* ctx, struct arr_7 a, struct fun_mut1_13 f);
uint8_t empty__q_11(struct arr_7 a);
uint8_t call_19(struct ctx* ctx, struct fun_mut1_13 f, struct failure* p0);
uint8_t call_with_ctx_18(struct ctx* c, struct fun_mut1_13 f, struct failure* p0);
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
struct failure** incr_5(struct failure** p);
uint8_t ensure_capacity_2(struct ctx* ctx, struct mut_arr_5* a, uint64_t capacity);
uint8_t push_all__lambda0(struct ctx* ctx, struct push_all__lambda0* _closure, struct failure* it);
struct arr_7 call_20(struct ctx* ctx, struct fun_mut1_12 f, struct arr_0 p0);
struct arr_7 call_with_ctx_19(struct ctx* c, struct fun_mut1_12 f, struct arr_0 p0);
uint8_t reduce_size_if_more_than(struct ctx* ctx, struct mut_arr_5* a, uint64_t new_size);
uint8_t flat_map_with_max_size__lambda0(struct ctx* ctx, struct flat_map_with_max_size__lambda0* _closure, struct arr_0 x);
struct arr_7 freeze_6(struct mut_arr_5* a);
struct arr_7 unsafe_as_arr_4(struct mut_arr_5* a);
struct arr_7 run_single_noze_test(struct ctx* ctx, struct arr_0 path_to_noze, struct dict_1* env, struct arr_0 path, struct test_options options);
struct opt_13 first_some(struct ctx* ctx, struct arr_1 a, struct fun_mut1_14 cb);
struct opt_13 call_21(struct ctx* ctx, struct fun_mut1_14 f, struct arr_0 p0);
struct opt_13 call_with_ctx_20(struct ctx* c, struct fun_mut1_14 f, struct arr_0 p0);
struct print_test_result* run_print_test(struct ctx* ctx, struct arr_0 print_kind, struct arr_0 path_to_noze, struct dict_1* env, struct arr_0 path, uint8_t overwrite_output__q);
struct process_result* spawn_and_wait_result_0(struct ctx* ctx, struct arr_0 exe, struct arr_1 args, struct dict_1* environ);
struct arr_0 fold(struct ctx* ctx, struct arr_0 val, struct arr_1 a, struct fun_mut2_1 combine);
struct arr_0 call_22(struct ctx* ctx, struct fun_mut2_1 f, struct arr_0 p0, struct arr_0 p1);
struct arr_0 call_with_ctx_21(struct ctx* c, struct fun_mut2_1 f, struct arr_0 p0, struct arr_0 p1);
struct arr_0 spawn_and_wait_result_0__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr_0 a, struct arr_0 b);
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
int16_t two_pow_1(int16_t pow);
uint8_t zero__q_3(int16_t a);
uint8_t _op_equal_equal_6(int16_t a, int16_t b);
struct comparison compare_547(int16_t a, int16_t b);
int16_t wrap_decr_2(int16_t a);
int16_t two_4();
int16_t wrap_incr_4(int16_t a);
struct pollfd* ref_of_val_at(struct ctx* ctx, struct arr_8 a, uint64_t index);
struct pollfd* ref_of_ptr(struct pollfd* p);
extern int32_t poll(struct pollfd* fds, uint64_t n_fds, int32_t timeout);
struct handle_revents_result handle_revents(struct ctx* ctx, struct pollfd* pollfd, struct mut_arr_4* builder);
uint8_t has_pollin__q(struct ctx* ctx, int16_t revents);
uint8_t bits_intersect__q(int16_t a, int16_t b);
uint8_t read_to_buffer_until_eof(struct ctx* ctx, int32_t fd, struct mut_arr_4* buffer);
uint64_t two_pow_2(uint64_t pow);
uint8_t ensure_capacity_3(struct ctx* ctx, struct mut_arr_4* a, uint64_t capacity);
uint8_t increase_capacity_to_3(struct ctx* ctx, struct mut_arr_4* a, uint64_t new_capacity);
uint8_t copy_data_from_3(struct ctx* ctx, char* to, char* from, uint64_t len);
uint8_t copy_data_from_small_3(struct ctx* ctx, char* to, char* from, uint64_t len);
extern int64_t read(int32_t fd, uint8_t* buff, uint64_t n_bytes);
uint8_t unsafe_increase_size(struct ctx* ctx, struct mut_arr_4* a, uint64_t increase_by);
uint8_t unsafe_set_size(struct ctx* ctx, struct mut_arr_4* a, uint64_t new_size);
uint8_t has_pollhup__q(struct ctx* ctx, int16_t revents);
int16_t pollhup(struct ctx* ctx);
int16_t four_4();
int16_t three_4();
uint8_t has_pollpri__q(struct ctx* ctx, int16_t revents);
int16_t pollpri(struct ctx* ctx);
uint8_t has_pollout__q(struct ctx* ctx, int16_t revents);
int16_t pollout(struct ctx* ctx);
uint8_t has_pollerr__q(struct ctx* ctx, int16_t revents);
int16_t pollerr(struct ctx* ctx);
uint8_t has_pollnval__q(struct ctx* ctx, int16_t revents);
int16_t pollnval(struct ctx* ctx);
int16_t five_4();
uint64_t to_nat_1(struct ctx* ctx, uint8_t b);
uint8_t any__q(struct ctx* ctx, struct handle_revents_result r);
uint64_t to_nat_2(struct ctx* ctx, int32_t i);
int32_t wait_and_get_exit_code(struct ctx* ctx, int32_t pid);
extern int32_t waitpid(int32_t pid, struct cell_4* wait_status, int32_t options);
uint8_t w_if_exited(struct ctx* ctx, int32_t status);
int32_t w_term_sig(struct ctx* ctx, int32_t status);
int32_t x7f();
int32_t noctx_decr_1(int32_t a);
int32_t two_pow_3(int32_t pow);
int32_t wrap_decr_3(int32_t a);
int32_t w_exit_status(struct ctx* ctx, int32_t status);
int32_t bit_shift_right(int32_t a, int32_t b);
uint8_t _op_less_3(int32_t a, int32_t b);
int32_t todo_6();
int32_t thirty_two_0();
int32_t sixteen_0();
int32_t xff00();
int32_t xffff();
int32_t xff();
int32_t eight_3();
uint8_t w_if_signaled(struct ctx* ctx, int32_t status);
uint8_t _op_bang_equal(int32_t a, int32_t b);
struct arr_0 to_str_1(struct ctx* ctx, int32_t i);
struct arr_0 to_str_2(struct ctx* ctx, int64_t i);
struct arr_0 to_str_3(struct ctx* ctx, uint64_t n);
uint64_t mod(struct ctx* ctx, uint64_t a, uint64_t b);
uint64_t abs(struct ctx* ctx, int64_t i);
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
char* call_23(struct ctx* ctx, struct fun_mut1_15 f, uint64_t p0);
char* call_with_ctx_22(struct ctx* c, struct fun_mut1_15 f, uint64_t p0);
char* _op_plus_2__lambda0(struct ctx* ctx, struct _op_plus_2__lambda0* _closure, uint64_t i);
struct arr_3 append(struct ctx* ctx, struct arr_3 a, char* b);
struct arr_3 map_1(struct ctx* ctx, struct arr_1 a, struct fun_mut1_16 mapper);
char* call_24(struct ctx* ctx, struct fun_mut1_16 f, struct arr_0 p0);
char* call_with_ctx_23(struct ctx* c, struct fun_mut1_16 f, struct arr_0 p0);
char* map_1__lambda0(struct ctx* ctx, struct map_1__lambda0* _closure, uint64_t i);
char* convert_args__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr_0 it);
char** convert_environ(struct ctx* ctx, struct dict_1* environ);
struct mut_arr_6* new_mut_arr_4(struct ctx* ctx);
uint8_t each_3(struct ctx* ctx, struct dict_1* d, struct fun_mut2_2 f);
uint8_t empty__q_12(struct ctx* ctx, struct dict_1* d);
uint8_t call_25(struct ctx* ctx, struct fun_mut2_2 f, struct arr_0 p0, struct arr_0 p1);
uint8_t call_with_ctx_24(struct ctx* c, struct fun_mut2_2 f, struct arr_0 p0, struct arr_0 p1);
uint8_t push_3(struct ctx* ctx, struct mut_arr_6* a, char* value);
uint8_t increase_capacity_to_4(struct ctx* ctx, struct mut_arr_6* a, uint64_t new_capacity);
uint8_t copy_data_from_4(struct ctx* ctx, char** to, char** from, uint64_t len);
uint8_t copy_data_from_small_4(struct ctx* ctx, char** to, char** from, uint64_t len);
uint8_t ensure_capacity_4(struct ctx* ctx, struct mut_arr_6* a, uint64_t capacity);
uint8_t convert_environ__lambda0(struct ctx* ctx, struct convert_environ__lambda0* _closure, struct arr_0 key, struct arr_0 value);
struct process_result* fail_2(struct ctx* ctx, struct arr_0 reason);
struct process_result* throw_2(struct ctx* ctx, struct exception e);
struct process_result* todo_7();
struct arr_7 empty_arr_3();
struct arr_7 handle_output(struct ctx* ctx, struct arr_0 original_path, struct arr_0 output_path, struct arr_0 actual, uint8_t overwrite_output__q);
struct opt_11 try_read_file_0(struct ctx* ctx, struct arr_0 path);
struct opt_11 try_read_file_1(struct ctx* ctx, char* path);
extern int32_t open(char* path, uint32_t oflag, uint32_t permission);
uint32_t o_rdonly(struct ctx* ctx);
uint32_t literal_4(struct ctx* ctx, struct arr_0 s);
struct opt_11 todo_8();
extern int64_t lseek(int32_t f, int64_t offset, int32_t whence);
int32_t seek_end(struct ctx* ctx);
int64_t billion_1();
uint8_t zero__q_4(int64_t i);
int32_t seek_set(struct ctx* ctx);
uint8_t write_file_0(struct ctx* ctx, struct arr_0 path, struct arr_0 content);
uint8_t write_file_1(struct ctx* ctx, char* path, struct arr_0 content);
uint32_t bit_shift_left(uint32_t a, uint32_t b);
uint8_t _op_less_4(uint32_t a, uint32_t b);
uint32_t thirty_two_1();
uint32_t sixteen_1();
uint32_t o_creat(struct ctx* ctx);
uint32_t o_wronly(struct ctx* ctx);
uint32_t o_trunc(struct ctx* ctx);
uint32_t nine_2();
struct arr_0 to_str_4(struct ctx* ctx, uint32_t n);
struct arr_0 remove_colors(struct ctx* ctx, struct arr_0 s);
uint8_t remove_colors_recur(struct ctx* ctx, struct arr_0 s, struct mut_arr_4* out);
uint8_t remove_colors_recur_2(struct ctx* ctx, struct arr_0 s, struct mut_arr_4* out);
uint8_t push_4(struct ctx* ctx, struct mut_arr_4* a, char value);
struct opt_13 run_single_noze_test__lambda0(struct ctx* ctx, struct run_single_noze_test__lambda0* _closure, struct arr_0 print_kind);
struct arr_7 run_single_runnable_test(struct ctx* ctx, struct arr_0 path_to_noze, struct dict_1* env, struct arr_0 path, uint8_t interpret__q, uint8_t overwrite_output__q);
struct arr_7 run_noze_tests__lambda0(struct ctx* ctx, struct run_noze_tests__lambda0* _closure, struct arr_0 test);
uint8_t has__q_6(struct arr_7 a);
struct result_3 do_test__lambda0__lambda0(struct ctx* ctx, struct do_test__lambda0__lambda0* _closure);
struct result_3 do_test__lambda0(struct ctx* ctx, struct do_test__lambda0* _closure);
struct result_3 lint(struct ctx* ctx, struct arr_0 path, struct test_options options);
struct arr_1 list_lintable_files(struct ctx* ctx, struct arr_0 path);
uint8_t excluded_from_lint__q(struct ctx* ctx, struct arr_0 name);
uint8_t some__q(struct ctx* ctx, struct arr_1 a, struct fun_mut1_6 pred);
uint8_t ends_with__q(struct ctx* ctx, struct arr_0 a, struct arr_0 end);
uint8_t excluded_from_lint__q__lambda0(struct ctx* ctx, struct excluded_from_lint__q__lambda0* _closure, struct arr_0 it);
uint8_t list_lintable_files__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr_0 it);
uint8_t ignore_extension_of_name(struct ctx* ctx, struct arr_0 name);
uint8_t ignore_extension(struct ctx* ctx, struct arr_0 ext);
uint8_t contains__q_1(struct arr_1 a, struct arr_0 value);
uint8_t contains_recur__q_1(struct arr_1 a, struct arr_0 value, uint64_t i);
struct arr_1 ignored_extensions(struct ctx* ctx);
uint8_t list_lintable_files__lambda1(struct ctx* ctx, struct list_lintable_files__lambda1* _closure, struct arr_0 child);
struct arr_7 lint_file(struct ctx* ctx, struct arr_0 path);
struct arr_0 read_file(struct ctx* ctx, struct arr_0 path);
uint8_t each_with_index_0(struct ctx* ctx, struct arr_1 a, struct fun_mut2_3 f);
uint8_t each_with_index_recur_0(struct ctx* ctx, struct arr_1 a, struct fun_mut2_3 f, uint64_t n);
uint8_t call_26(struct ctx* ctx, struct fun_mut2_3 f, struct arr_0 p0, uint64_t p1);
uint8_t call_with_ctx_25(struct ctx* c, struct fun_mut2_3 f, struct arr_0 p0, uint64_t p1);
struct arr_1 lines(struct ctx* ctx, struct arr_0 s);
uint8_t each_with_index_1(struct ctx* ctx, struct arr_0 a, struct fun_mut2_4 f);
uint8_t each_with_index_recur_1(struct ctx* ctx, struct arr_0 a, struct fun_mut2_4 f, uint64_t n);
uint8_t call_27(struct ctx* ctx, struct fun_mut2_4 f, char p0, uint64_t p1);
uint8_t call_with_ctx_26(struct ctx* c, struct fun_mut2_4 f, char p0, uint64_t p1);
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
uint8_t print_failures__lambda0(struct ctx* ctx, uint8_t* _closure, struct failure* it);
int32_t to_int32(struct ctx* ctx, uint64_t n);
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
	gctx_by_val1 = (struct global_ctx) {new_lock(), empty_arr_0(), n_threads0, new_condition(), 0, 0};
	gctx2 = (&(gctx_by_val1));
	vat_by_val3 = new_vat(gctx2, 0, n_threads0);
	vat4 = (&(vat_by_val3));
	(gctx2->vats = (struct arr_2) {1, (&(vat4))}, 0);
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
	return (struct arr_0) {_op_minus_0(end, begin), begin};
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
	_matched0 = compare_8(a, b);
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
struct comparison compare_8(char a, char b) {
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
	_matched0 = compare_13(a, b);
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
struct comparison compare_13(uint64_t a, uint64_t b) {
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
struct lock new_lock() {
	return (struct lock) {new_atomic_bool()};
}
struct _atomic_bool new_atomic_bool() {
	return (struct _atomic_bool) {0};
}
struct arr_2 empty_arr_0() {
	return (struct arr_2) {0, NULL};
}
struct condition new_condition() {
	return (struct condition) {new_lock(), 0};
}
struct vat new_vat(struct global_ctx* gctx, uint64_t id, uint64_t max_threads) {
	struct mut_arr_0 actors0;
	actors0 = new_mut_arr_by_val_with_capacity_from_unmanaged_memory(max_threads);
	return (struct vat) {gctx, id, new_gc(), new_lock(), new_mut_bag(), actors0, 0, new_thread_safe_counter_0(), (struct fun_mut1_1) {(fun_ptr3_1) new_vat__lambda0, (uint8_t*) NULL}};
}
struct mut_arr_0 new_mut_arr_by_val_with_capacity_from_unmanaged_memory(uint64_t capacity) {
	return (struct mut_arr_0) {0, 0, capacity, unmanaged_alloc_elements_0(capacity)};
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
	_matched0 = compare_13(a, b);
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
struct gc new_gc() {
	return (struct gc) {new_lock(), (struct opt_1) {0, .as0 = (struct none) {0}}, 0, 0, NULL, NULL};
}
struct mut_bag new_mut_bag() {
	return (struct mut_bag) {(struct opt_2) {0, .as0 = (struct none) {0}}};
}
struct thread_safe_counter new_thread_safe_counter_0() {
	return new_thread_safe_counter_1(0);
}
struct thread_safe_counter new_thread_safe_counter_1(uint64_t init) {
	return (struct thread_safe_counter) {new_lock(), init};
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
	_matched0 = compare_37(a, b);
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
struct comparison compare_37(int64_t a, int64_t b) {
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
	tls1 = (struct thread_local_stuff) {(&(ectx0))};
	ctx_by_val2 = new_ctx(gctx, (&(tls1)), vat, 0);
	ctx3 = (&(ctx_by_val2));
	add4 = (struct fun2) {(fun_ptr4_0) do_main__lambda0, (uint8_t*) NULL};
	all_args5 = (struct arr_3) {argc, argv};
	return call_with_ctx_8(ctx3, add4, all_args5, main_ptr);
}
struct exception_ctx new_exception_ctx() {
	return (struct exception_ctx) {NULL, (struct exception) {(struct arr_0) {0, NULL}}};
}
struct ctx new_ctx(struct global_ctx* gctx, struct thread_local_stuff* tls, struct vat* vat, uint64_t actor_id) {
	return (struct ctx) {(uint8_t*) gctx, vat->id, actor_id, (uint8_t*) get_gc_ctx_0((&(vat->gc))), (uint8_t*) tls->exception_ctx};
}
struct gc_ctx* get_gc_ctx_0(struct gc* gc) {
	struct gc_ctx* res4;
	struct opt_1 _matched3;
	struct gc_ctx* c0;
	struct some_1 s1;
	struct gc_ctx* c2;
	acquire_lock((&(gc->lk)));
	res4 = (_matched3 = gc->context_head, _matched3.kind == 0 ? (c0 = (struct gc_ctx*) malloc(sizeof(struct gc_ctx)), (((c0->gc = gc, 0), (c0->next_ctx = (struct opt_1) {0, .as0 = (struct none) {0}}, 0)), c0)) : _matched3.kind == 1 ? (s1 = _matched3.as1, (c2 = s1.value, (((gc->context_head = c2->next_ctx, 0), (c2->next_ctx = (struct opt_1) {0, .as0 = (struct none) {0}}, 0)), c2))) : (assert(0),NULL));
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
	_matched0 = compare_72(a, b);
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
struct comparison compare_72(int32_t a, int32_t b) {
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
	hard_assert(_op_less_0(n, billion_0()));
	return wrap_incr_1(n);
}
uint64_t billion_0() {
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
	return then_0(ctx, f, (struct fun_ref1) {cur_actor(ctx), (struct fun_mut1_3) {(fun_ptr3_3) then2__lambda0, (uint8_t*) (temp0 = (struct then2__lambda0*) alloc(ctx, sizeof(struct then2__lambda0)), ((*(temp0) = (struct then2__lambda0) {cb}, 0), temp0))}});
}
struct fut_0* then_0(struct ctx* ctx, struct fut_1* f, struct fun_ref1 cb) {
	struct fut_0* res0;
	struct then_0__lambda0* temp0;
	res0 = new_unresolved_fut(ctx);
	then_void_0(ctx, f, (struct fun_mut1_2) {(fun_ptr3_2) then_0__lambda0, (uint8_t*) (temp0 = (struct then_0__lambda0*) alloc(ctx, sizeof(struct then_0__lambda0)), ((*(temp0) = (struct then_0__lambda0) {cb, res0}, 0), temp0))});
	return res0;
}
struct fut_0* new_unresolved_fut(struct ctx* ctx) {
	struct fut_0* temp0;
	temp0 = (struct fut_0*) alloc(ctx, sizeof(struct fut_0));
	(*(temp0) = (struct fut_0) {new_lock(), (struct fut_state_0) {0, .as0 = (struct fut_state_callbacks_0) {(struct opt_0) {0, .as0 = (struct none) {0}}}}}, 0);
	return temp0;
}
uint8_t then_void_0(struct ctx* ctx, struct fut_1* f, struct fun_mut1_2 cb) {
	struct fut_state_1 _matched3;
	struct fut_state_callbacks_1 cbs0;
	struct fut_callback_node_1* temp0;
	struct fut_state_resolved_1 r1;
	struct exception e2;
	acquire_lock((&(f->lk)));
	_matched3 = f->state;
	switch (_matched3.kind) {
		case 0:
			cbs0 = _matched3.as0;
			(f->state = (struct fut_state_1) {0, .as0 = (struct fut_state_callbacks_1) {(struct opt_3) {1, .as1 = (struct some_3) {(temp0 = (struct fut_callback_node_1*) alloc(ctx, sizeof(struct fut_callback_node_1)), ((*(temp0) = (struct fut_callback_node_1) {cb, cbs0.head}, 0), temp0))}}}}, 0);
			break;
		case 1:
			r1 = _matched3.as1;
			call_0(ctx, cb, (struct result_1) {0, .as0 = (struct ok_1) {r1.value}});
			break;
		case 2:
			e2 = _matched3.as2;
			call_0(ctx, cb, (struct result_1) {1, .as1 = (struct err_0) {e2}});
			break;
		default:
			(assert(0),0);
	}
	return release_lock((&(f->lk)));
}
uint8_t call_0(struct ctx* ctx, struct fun_mut1_2 f, struct result_1 p0) {
	return call_with_ctx_0(ctx, f, p0);
}
uint8_t call_with_ctx_0(struct ctx* c, struct fun_mut1_2 f, struct result_1 p0) {
	return f.fun_ptr(c, f.closure, p0);
}
uint8_t forward_to(struct ctx* ctx, struct fut_0* from, struct fut_0* to) {
	struct forward_to__lambda0* temp0;
	return then_void_1(ctx, from, (struct fun_mut1_0) {(fun_ptr3_0) forward_to__lambda0, (uint8_t*) (temp0 = (struct forward_to__lambda0*) alloc(ctx, sizeof(struct forward_to__lambda0)), ((*(temp0) = (struct forward_to__lambda0) {to}, 0), temp0))});
}
uint8_t then_void_1(struct ctx* ctx, struct fut_0* f, struct fun_mut1_0 cb) {
	struct fut_state_0 _matched3;
	struct fut_state_callbacks_0 cbs0;
	struct fut_callback_node_0* temp0;
	struct fut_state_resolved_0 r1;
	struct exception e2;
	acquire_lock((&(f->lk)));
	_matched3 = f->state;
	switch (_matched3.kind) {
		case 0:
			cbs0 = _matched3.as0;
			(f->state = (struct fut_state_0) {0, .as0 = (struct fut_state_callbacks_0) {(struct opt_0) {1, .as1 = (struct some_0) {(temp0 = (struct fut_callback_node_0*) alloc(ctx, sizeof(struct fut_callback_node_0)), ((*(temp0) = (struct fut_callback_node_0) {cb, cbs0.head}, 0), temp0))}}}}, 0);
			break;
		case 1:
			r1 = _matched3.as1;
			call_1(ctx, cb, (struct result_0) {0, .as0 = (struct ok_0) {r1.value}});
			break;
		case 2:
			e2 = _matched3.as2;
			call_1(ctx, cb, (struct result_0) {1, .as1 = (struct err_0) {e2}});
			break;
		default:
			(assert(0),0);
	}
	return release_lock((&(f->lk)));
}
uint8_t call_1(struct ctx* ctx, struct fun_mut1_0 f, struct result_0 p0) {
	return call_with_ctx_1(ctx, f, p0);
}
uint8_t call_with_ctx_1(struct ctx* c, struct fun_mut1_0 f, struct result_0 p0) {
	return f.fun_ptr(c, f.closure, p0);
}
uint8_t resolve_or_reject(struct ctx* ctx, struct fut_0* f, struct result_0 result) {
	struct fut_state_0 _matched1;
	struct fut_state_callbacks_0 cbs0;
	struct result_0 _matched5;
	struct ok_0 o2;
	struct err_0 e3;
	struct exception ex4;
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
	(f->state = (_matched5 = result, _matched5.kind == 0 ? (o2 = _matched5.as0, (struct fut_state_0) {1, .as1 = (struct fut_state_resolved_0) {o2.value}}) : _matched5.kind == 1 ? (e3 = _matched5.as1, (ex4 = e3.value, (struct fut_state_0) {2, .as2 = ex4})) : (assert(0),(struct fut_state_0) {0})), 0);
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
uint8_t forward_to__lambda0(struct ctx* ctx, struct forward_to__lambda0* _closure, struct result_0 it) {
	return resolve_or_reject(ctx, _closure->to, it);
}
struct fut_0* call_2(struct ctx* ctx, struct fun_ref1 f, uint8_t p0) {
	struct vat* vat0;
	struct fut_0* res1;
	struct call_2__lambda0* temp0;
	vat0 = get_vat(ctx, f.vat_and_actor.vat);
	res1 = new_unresolved_fut(ctx);
	add_task(ctx, vat0, (struct task) {f.vat_and_actor.actor, (struct fun_mut0_0) {(fun_ptr2_1) call_2__lambda0, (uint8_t*) (temp0 = (struct call_2__lambda0*) alloc(ctx, sizeof(struct call_2__lambda0)), ((*(temp0) = (struct call_2__lambda0) {f, p0, res1}, 0), temp0))}});
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
		return fail_0(ctx, message);
	}
}
uint8_t fail_0(struct ctx* ctx, struct arr_0 reason) {
	return throw_0(ctx, (struct exception) {reason});
}
uint8_t throw_0(struct ctx* ctx, struct exception e) {
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
	add_0((&(v->tasks)), node0);
	release_lock((&(v->tasks_lock)));
	return broadcast((&(v->gctx->may_be_work_to_do)));
}
struct mut_bag_node* new_mut_bag_node(struct ctx* ctx, struct task value) {
	struct mut_bag_node* temp0;
	temp0 = (struct mut_bag_node*) alloc(ctx, sizeof(struct mut_bag_node));
	(*(temp0) = (struct mut_bag_node) {value, (struct opt_2) {0, .as0 = (struct none) {0}}}, 0);
	return temp0;
}
uint8_t add_0(struct mut_bag* bag, struct mut_bag_node* node) {
	(node->next_node = bag->head, 0);
	return (bag->head = (struct opt_2) {1, .as1 = (struct some_2) {node}}, 0);
}
uint8_t broadcast(struct condition* c) {
	acquire_lock((&(c->lk)));
	(c->value = noctx_incr(c->value), 0);
	return release_lock((&(c->lk)));
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
	store2 = (struct jmp_buf_tag) {zero_0(), 0, zero_3()};
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
struct bytes64 zero_0() {
	return (struct bytes64) {zero_1(), zero_1()};
}
struct bytes32 zero_1() {
	return (struct bytes32) {zero_2(), zero_2()};
}
struct bytes16 zero_2() {
	return (struct bytes16) {0, 0};
}
struct bytes128 zero_3() {
	return (struct bytes128) {zero_0(), zero_0()};
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
	return resolve_or_reject(ctx, f, (struct result_0) {1, .as1 = (struct err_0) {e}});
}
uint8_t call_2__lambda0__lambda1(struct ctx* ctx, struct call_2__lambda0__lambda1* _closure, struct exception it) {
	return reject(ctx, _closure->res, it);
}
uint8_t call_2__lambda0(struct ctx* ctx, struct call_2__lambda0* _closure) {
	struct call_2__lambda0__lambda0* temp0;
	struct call_2__lambda0__lambda1* temp1;
	return catch(ctx, (struct fun_mut0_0) {(fun_ptr2_1) call_2__lambda0__lambda0, (uint8_t*) (temp0 = (struct call_2__lambda0__lambda0*) alloc(ctx, sizeof(struct call_2__lambda0__lambda0)), ((*(temp0) = (struct call_2__lambda0__lambda0) {_closure->f, _closure->p0, _closure->res}, 0), temp0))}, (struct fun_mut1_1) {(fun_ptr3_1) call_2__lambda0__lambda1, (uint8_t*) (temp1 = (struct call_2__lambda0__lambda1*) alloc(ctx, sizeof(struct call_2__lambda0__lambda1)), ((*(temp1) = (struct call_2__lambda0__lambda1) {_closure->res}, 0), temp1))});
}
uint8_t then_0__lambda0(struct ctx* ctx, struct then_0__lambda0* _closure, struct result_1 result) {
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
	add_task(ctx, vat0, (struct task) {f.vat_and_actor.actor, (struct fun_mut0_0) {(fun_ptr2_1) call_6__lambda0, (uint8_t*) (temp0 = (struct call_6__lambda0*) alloc(ctx, sizeof(struct call_6__lambda0)), ((*(temp0) = (struct call_6__lambda0) {f, res1}, 0), temp0))}});
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
	return (struct vat_and_actor_id) {c0->vat_id, c0->actor_id};
}
struct fut_1* resolved_0(struct ctx* ctx, uint8_t value) {
	struct fut_1* temp0;
	temp0 = (struct fut_1*) alloc(ctx, sizeof(struct fut_1));
	(*(temp0) = (struct fut_1) {new_lock(), (struct fut_state_1) {1, .as1 = (struct fut_state_resolved_1) {value}}}, 0);
	return temp0;
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
		return fail_0(ctx, message);
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
	assert_0(ctx, _op_less_equal_0(_op_plus_0(ctx, begin, size), a.size));
	return (struct arr_3) {size, (a.data + begin)};
}
uint64_t _op_plus_0(struct ctx* ctx, uint64_t a, uint64_t b) {
	uint64_t res0;
	res0 = (a + b);
	assert_0(ctx, (_op_greater_equal(res0, a) && _op_greater_equal(res0, b)));
	return res0;
}
uint8_t _op_greater_equal(uint64_t a, uint64_t b) {
	return !_op_less_0(a, b);
}
uint64_t _op_minus_1(struct ctx* ctx, uint64_t a, uint64_t b) {
	assert_0(ctx, _op_greater_equal(a, b));
	return (a - b);
}
struct arr_1 map_0(struct ctx* ctx, struct arr_3 a, struct fun_mut1_4 mapper) {
	struct map_0__lambda0* temp0;
	return make_arr_0(ctx, a.size, (struct fun_mut1_5) {(fun_ptr3_5) map_0__lambda0, (uint8_t*) (temp0 = (struct map_0__lambda0*) alloc(ctx, sizeof(struct map_0__lambda0)), ((*(temp0) = (struct map_0__lambda0) {mapper, a}, 0), temp0))});
}
struct arr_1 make_arr_0(struct ctx* ctx, uint64_t size, struct fun_mut1_5 f) {
	return freeze_0(make_mut_arr_0(ctx, size, f));
}
struct arr_1 freeze_0(struct mut_arr_1* a) {
	(a->frozen__q = 1, 0);
	return unsafe_as_arr_0(a);
}
struct arr_1 unsafe_as_arr_0(struct mut_arr_1* a) {
	return (struct arr_1) {a->size, a->data};
}
struct mut_arr_1* make_mut_arr_0(struct ctx* ctx, uint64_t size, struct fun_mut1_5 f) {
	struct mut_arr_1* res0;
	res0 = new_uninitialized_mut_arr_0(ctx, size);
	make_mut_arr_worker_0(ctx, res0, 0, f);
	return res0;
}
struct mut_arr_1* new_uninitialized_mut_arr_0(struct ctx* ctx, uint64_t size) {
	struct mut_arr_1* temp0;
	temp0 = (struct mut_arr_1*) alloc(ctx, sizeof(struct mut_arr_1));
	(*(temp0) = (struct mut_arr_1) {0, size, size, uninitialized_data_0(ctx, size)}, 0);
	return temp0;
}
struct arr_0* uninitialized_data_0(struct ctx* ctx, uint64_t size) {
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
uint8_t make_mut_arr_worker_0(struct ctx* ctx, struct mut_arr_1* m, uint64_t i, struct fun_mut1_5 f) {
	struct mut_arr_1* _tailCallm;
	uint64_t _tailCalli;
	struct fun_mut1_5 _tailCallf;
	top:
	if (_op_equal_equal_1(i, m->size)) {
		return 0;
	} else {
		set_at_0(ctx, m, i, call_8(ctx, f, i));
		_tailCallm = m;
		_tailCalli = incr_1(ctx, i);
		_tailCallf = f;
		m = _tailCallm;
		i = _tailCalli;
		f = _tailCallf;
		goto top;
	}
}
uint8_t set_at_0(struct ctx* ctx, struct mut_arr_1* a, uint64_t index, struct arr_0 value) {
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
	assert_0(ctx, _op_less_0(n, billion_0()));
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
struct arr_0 map_0__lambda0(struct ctx* ctx, struct map_0__lambda0* _closure, uint64_t i) {
	return call_9(ctx, _closure->mapper, at_1(ctx, _closure->a, i));
}
struct arr_0 add_first_task__lambda0__lambda0(struct ctx* ctx, uint8_t* _closure, char* it) {
	return to_str_0(it);
}
struct fut_0* add_first_task__lambda0(struct ctx* ctx, struct add_first_task__lambda0* _closure) {
	struct arr_3 args0;
	args0 = tail_0(ctx, _closure->all_args);
	return _closure->main_ptr(ctx, map_0(ctx, args0, (struct fun_mut1_4) {(fun_ptr3_4) add_first_task__lambda0__lambda0, (uint8_t*) NULL}));
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
	actual_n_threads2 = noctx_decr_0(n_threads);
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
uint64_t noctx_decr_0(uint64_t n) {
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
		(*(thread_arg_ptr0) = (struct thread_args) {i, gctx}, 0);
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
	tls1 = (struct thread_local_stuff) {(&(ectx0))};
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
		(gctx->n_live_threads = noctx_decr_0(gctx->n_live_threads), 0);
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
	res2 = (_matched1 = choose_task_recur(gctx->vats, 0), _matched1.kind == 0 ? (((gctx->n_live_threads = noctx_decr_0(gctx->n_live_threads), 0), hard_assert(zero__q_0(gctx->n_live_threads))), (struct result_2) {1, .as1 = (struct err_1) {(struct no_chosen_task) {zero__q_0(gctx->n_live_threads)}}}) : _matched1.kind == 1 ? (s0 = _matched1.as1, (struct result_2) {0, .as0 = (struct ok_2) {s0.value}}) : (assert(0),(struct result_2) {0}));
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
		return (struct opt_5) {0, .as0 = (struct none) {0}};
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
				return (struct opt_5) {1, .as1 = (struct some_5) {(struct chosen_task) {vat0, s1.value}}};
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
	res2 = ((&(vat->gc))->needs_gc ? (zero__q_0(vat->n_threads_running) ? (struct opt_6) {1, .as1 = (struct some_6) {(struct opt_4) {0, .as0 = (struct none) {0}}}} : (struct opt_6) {0, .as0 = (struct none) {0}}) : (_matched1 = find_and_remove_first_doable_task(vat), _matched1.kind == 0 ? (struct opt_6) {0, .as0 = (struct none) {0}} : _matched1.kind == 1 ? (s0 = _matched1.as1, (struct opt_6) {1, .as1 = (struct some_6) {(struct opt_4) {1, .as1 = (struct some_4) {s0.value}}}}) : (assert(0),(struct opt_6) {0})));
	if (empty__q_4(res2)) {
		0;
	} else {
		(vat->n_threads_running = noctx_incr(vat->n_threads_running), 0);
	}
	release_lock((&(vat->tasks_lock)));
	return res2;
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
			return (struct opt_4) {0, .as0 = (struct none) {0}};
		case 1:
			s3 = _matched4.as1;
			(tasks0->head = s3.value.nodes, 0);
			return (struct opt_4) {1, .as1 = (struct some_4) {s3.value.task}};
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
			return (struct opt_7) {0, .as0 = (struct none) {0}};
		case 1:
			s0 = _matched8.as1;
			node1 = s0.value;
			task2 = node1->value;
			actors3 = (&(vat->currently_running_actors));
			task_ok4 = (contains__q_0(actors3, task2.actor_id) ? 0 : (push_capacity_must_be_sufficient(actors3, task2.actor_id), 1));
			if (task_ok4) {
				return (struct opt_7) {1, .as1 = (struct some_7) {(struct task_and_nodes) {task2, node1->next_node}}};
			} else {
				_matched7 = find_and_remove_first_doable_task_recur(vat, node1->next_node);
				switch (_matched7.kind) {
					case 0:
						return (struct opt_7) {0, .as0 = (struct none) {0}};
					case 1:
						ss5 = _matched7.as1;
						tn6 = ss5.value;
						(node1->next_node = tn6.nodes, 0);
						return (struct opt_7) {1, .as1 = (struct some_7) {(struct task_and_nodes) {tn6.task, (struct opt_2) {1, .as1 = (struct some_2) {node1}}}}};
					default:
						return (assert(0),(struct opt_7) {0});
				}
			}
		default:
			return (assert(0),(struct opt_7) {0});
	}
}
uint8_t contains__q_0(struct mut_arr_0* a, uint64_t value) {
	return contains_recur__q_0(temp_as_arr(a), value, 0);
}
uint8_t contains_recur__q_0(struct arr_4 a, uint64_t value, uint64_t i) {
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
	return (struct arr_4) {a->size, a->data};
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
	(vat0->n_threads_running = noctx_decr_0(vat0->n_threads_running), 0);
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
	(a->size = noctx_decr_0(a->size), 0);
	return res0;
}
uint64_t noctx_last(struct mut_arr_0* a) {
	hard_forbid(empty__q_5(a));
	return noctx_at_4(a, noctx_decr_0(a->size));
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
	(gc0->context_head = (struct opt_1) {1, .as1 = (struct some_1) {gc_ctx}}, 0);
	return release_lock((&(gc0->lk)));
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
	thread_return0 = (struct cell_1) {NULL};
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
	return hard_assert(null__q_0(get_0((&(thread_return0)))));
}
int32_t einval() {
	return ((ten_1() + ten_1()) + two_0());
}
int32_t esrch() {
	return three_1();
}
uint8_t* get_0(struct cell_1* c) {
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
			return hard_unreachable_0();
		case 1:
			r0 = _matched2.as1;
			return (struct result_0) {0, .as0 = (struct ok_0) {r0.value}};
		case 2:
			e1 = _matched2.as2;
			return (struct result_0) {1, .as1 = (struct err_0) {e1}};
		default:
			return (assert(0),(struct result_0) {0});
	}
}
struct result_0 hard_unreachable_0() {
	return (assert(0),(struct result_0) {0});
}
struct fut_0* main_0(struct ctx* ctx, struct arr_1 args) {
	struct opt_8 options0;
	struct opt_8 _matched2;
	struct some_8 s1;
	options0 = parse_cmd_line_args(ctx, args, (struct arr_1) {3, constantarr_1_0}, (struct fun1) {(fun_ptr3_6) main_0__lambda0, (uint8_t*) NULL});
	return resolved_1(ctx, (_matched2 = options0, _matched2.kind == 0 ? (print_help(ctx), literal_2(ctx, (struct arr_0) {1, constantarr_0_22})) : _matched2.kind == 1 ? (s1 = _matched2.as1, do_test(ctx, s1.value)) : (assert(0),0)));
}
struct opt_8 parse_cmd_line_args(struct ctx* ctx, struct arr_1 args, struct arr_1 t_names, struct fun1 make_t) {
	struct parsed_cmd_line_args* parsed0;
	struct mut_arr_3* values1;
	struct cell_2* help2;
	struct cell_2* temp0;
	struct parse_cmd_line_args__lambda0* temp1;
	parsed0 = parse_cmd_line_args_dynamic(ctx, args);
	assert_1(ctx, empty__q_6(parsed0->nameless), (struct arr_0) {26, constantarr_0_18});
	assert_0(ctx, empty__q_6(parsed0->after));
	values1 = fill_mut_arr(ctx, t_names.size, (struct opt_9) {0, .as0 = (struct none) {0}});
	help2 = (temp0 = (struct cell_2*) alloc(ctx, sizeof(struct cell_2)), ((*(temp0) = (struct cell_2) {0}, 0), temp0));
	each_0(ctx, parsed0->named, (struct fun_mut2_0) {(fun_ptr4_1) parse_cmd_line_args__lambda0, (uint8_t*) (temp1 = (struct parse_cmd_line_args__lambda0*) alloc(ctx, sizeof(struct parse_cmd_line_args__lambda0)), ((*(temp1) = (struct parse_cmd_line_args__lambda0) {t_names, help2, values1}, 0), temp1))});
	if (get_2(help2)) {
		return (struct opt_8) {0, .as0 = (struct none) {0}};
	} else {
		return (struct opt_8) {1, .as1 = (struct some_8) {call_14(ctx, make_t, freeze_4(values1))}};
	}
}
struct parsed_cmd_line_args* parse_cmd_line_args_dynamic(struct ctx* ctx, struct arr_1 args) {
	struct opt_10 _matched8;
	struct parsed_cmd_line_args* temp0;
	struct some_10 s0;
	uint64_t first_named_arg_index1;
	struct arr_1 nameless2;
	struct arr_1 rest3;
	struct opt_10 _matched7;
	struct parsed_cmd_line_args* temp1;
	struct some_10 s24;
	uint64_t sep_index5;
	struct dict_0* named_args6;
	struct parsed_cmd_line_args* temp2;
	_matched8 = find_index(ctx, args, (struct fun_mut1_6) {(fun_ptr3_7) parse_cmd_line_args_dynamic__lambda0, (uint8_t*) NULL});
	switch (_matched8.kind) {
		case 0:
			temp0 = (struct parsed_cmd_line_args*) alloc(ctx, sizeof(struct parsed_cmd_line_args));
			(*(temp0) = (struct parsed_cmd_line_args) {args, empty_dict(ctx), empty_arr_1()}, 0);
			return temp0;
		case 1:
			s0 = _matched8.as1;
			first_named_arg_index1 = s0.value;
			nameless2 = slice_up_to_0(ctx, args, first_named_arg_index1);
			rest3 = slice_starting_at_2(ctx, args, first_named_arg_index1);
			_matched7 = find_index(ctx, rest3, (struct fun_mut1_6) {(fun_ptr3_7) parse_cmd_line_args_dynamic__lambda1, (uint8_t*) NULL});
			switch (_matched7.kind) {
				case 0:
					temp1 = (struct parsed_cmd_line_args*) alloc(ctx, sizeof(struct parsed_cmd_line_args));
					(*(temp1) = (struct parsed_cmd_line_args) {nameless2, parse_named_args(ctx, rest3), empty_arr_1()}, 0);
					return temp1;
				case 1:
					s24 = _matched7.as1;
					sep_index5 = s24.value;
					named_args6 = parse_named_args(ctx, slice_up_to_0(ctx, rest3, sep_index5));
					temp2 = (struct parsed_cmd_line_args*) alloc(ctx, sizeof(struct parsed_cmd_line_args));
					(*(temp2) = (struct parsed_cmd_line_args) {nameless2, named_args6, slice_after_0(ctx, rest3, sep_index5)}, 0);
					return temp2;
				default:
					return (assert(0),NULL);
			}
		default:
			return (assert(0),NULL);
	}
}
struct opt_10 find_index(struct ctx* ctx, struct arr_1 a, struct fun_mut1_6 pred) {
	return find_index_recur(ctx, a, 0, pred);
}
struct opt_10 find_index_recur(struct ctx* ctx, struct arr_1 a, uint64_t index, struct fun_mut1_6 pred) {
	struct arr_1 _tailCalla;
	uint64_t _tailCallindex;
	struct fun_mut1_6 _tailCallpred;
	top:
	if (_op_equal_equal_1(index, a.size)) {
		return (struct opt_10) {0, .as0 = (struct none) {0}};
	} else {
		if (call_10(ctx, pred, at_2(ctx, a, index))) {
			return (struct opt_10) {1, .as1 = (struct some_10) {index}};
		} else {
			_tailCalla = a;
			_tailCallindex = incr_1(ctx, index);
			_tailCallpred = pred;
			a = _tailCalla;
			index = _tailCallindex;
			pred = _tailCallpred;
			goto top;
		}
	}
}
uint8_t call_10(struct ctx* ctx, struct fun_mut1_6 f, struct arr_0 p0) {
	return call_with_ctx_9(ctx, f, p0);
}
uint8_t call_with_ctx_9(struct ctx* c, struct fun_mut1_6 f, struct arr_0 p0) {
	return f.fun_ptr(c, f.closure, p0);
}
struct arr_0 at_2(struct ctx* ctx, struct arr_1 a, uint64_t index) {
	assert_0(ctx, _op_less_0(index, a.size));
	return noctx_at_5(a, index);
}
struct arr_0 noctx_at_5(struct arr_1 a, uint64_t index) {
	hard_assert(_op_less_0(index, a.size));
	return (*((a.data + index)));
}
uint8_t starts_with__q(struct ctx* ctx, struct arr_0 a, struct arr_0 start) {
	return (_op_greater_equal(a.size, start.size) && arr_eq__q(ctx, slice_1(ctx, a, 0, start.size), start));
}
uint8_t arr_eq__q(struct ctx* ctx, struct arr_0 a, struct arr_0 b) {
	struct arr_0 _tailCalla;
	struct arr_0 _tailCallb;
	top:
	if (_op_equal_equal_1(a.size, b.size)) {
		if (empty__q_0(a)) {
			return 1;
		} else {
			if (_op_equal_equal_0(first_0(ctx, a), first_0(ctx, b))) {
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
char first_0(struct ctx* ctx, struct arr_0 a) {
	forbid_0(ctx, empty__q_0(a));
	return at_3(ctx, a, 0);
}
char at_3(struct ctx* ctx, struct arr_0 a, uint64_t index) {
	assert_0(ctx, _op_less_0(index, a.size));
	return noctx_at_0(a, index);
}
struct arr_0 tail_1(struct ctx* ctx, struct arr_0 a) {
	forbid_0(ctx, empty__q_0(a));
	return slice_starting_at_1(ctx, a, 1);
}
struct arr_0 slice_starting_at_1(struct ctx* ctx, struct arr_0 a, uint64_t begin) {
	assert_0(ctx, _op_less_equal_0(begin, a.size));
	return slice_1(ctx, a, begin, _op_minus_1(ctx, a.size, begin));
}
struct arr_0 slice_1(struct ctx* ctx, struct arr_0 a, uint64_t begin, uint64_t size) {
	assert_0(ctx, _op_less_equal_0(_op_plus_0(ctx, begin, size), a.size));
	return (struct arr_0) {size, (a.data + begin)};
}
uint8_t parse_cmd_line_args_dynamic__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr_0 it) {
	return starts_with__q(ctx, it, (struct arr_0) {2, constantarr_0_16});
}
struct dict_0* empty_dict(struct ctx* ctx) {
	struct dict_0* temp0;
	temp0 = (struct dict_0*) alloc(ctx, sizeof(struct dict_0));
	(*(temp0) = (struct dict_0) {empty_arr_1(), empty_arr_2()}, 0);
	return temp0;
}
struct arr_1 empty_arr_1() {
	return (struct arr_1) {0, NULL};
}
struct arr_6 empty_arr_2() {
	return (struct arr_6) {0, NULL};
}
struct arr_1 slice_up_to_0(struct ctx* ctx, struct arr_1 a, uint64_t size) {
	assert_0(ctx, _op_less_0(size, a.size));
	return slice_2(ctx, a, 0, size);
}
struct arr_1 slice_2(struct ctx* ctx, struct arr_1 a, uint64_t begin, uint64_t size) {
	assert_0(ctx, _op_less_equal_0(_op_plus_0(ctx, begin, size), a.size));
	return (struct arr_1) {size, (a.data + begin)};
}
struct arr_1 slice_starting_at_2(struct ctx* ctx, struct arr_1 a, uint64_t begin) {
	assert_0(ctx, _op_less_equal_0(begin, a.size));
	return slice_2(ctx, a, begin, _op_minus_1(ctx, a.size, begin));
}
uint8_t _op_equal_equal_4(struct arr_0 a, struct arr_0 b) {
	struct comparison _matched0;
	_matched0 = compare_253(a, b);
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
struct comparison compare_253(struct arr_0 a, struct arr_0 b) {
	struct comparison temp0;
	struct arr_0 _tailCalla;
	struct arr_0 _tailCallb;
	top:
	if ((a.size == 0)) {
		if ((b.size == 0)) {
			return (struct comparison) {1, .as1 = (struct equal) {0}};
		} else {
			return (struct comparison) {0, .as0 = (struct less) {0}};
		}
	} else {
		if ((b.size == 0)) {
			return (struct comparison) {2, .as2 = (struct greater) {0}};
		} else {
			temp0 = compare_8((*(a.data)), (*(b.data)));
			switch (temp0.kind) {
				case 0:
					return (struct comparison) {0, .as0 = (struct less) {0}};
				case 1:
					_tailCalla = (struct arr_0) {(a.size - 1), (a.data + 1)};
					_tailCallb = (struct arr_0) {(b.size - 1), (b.data + 1)};
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
uint8_t parse_cmd_line_args_dynamic__lambda1(struct ctx* ctx, uint8_t* _closure, struct arr_0 it) {
	return _op_equal_equal_4(it, (struct arr_0) {2, constantarr_0_16});
}
struct dict_0* parse_named_args(struct ctx* ctx, struct arr_1 args) {
	struct mut_dict_0 b0;
	b0 = new_mut_dict_0(ctx);
	parse_named_args_recur(ctx, args, b0);
	return freeze_1(ctx, b0);
}
struct mut_dict_0 new_mut_dict_0(struct ctx* ctx) {
	return (struct mut_dict_0) {new_mut_arr_0(ctx), new_mut_arr_1(ctx)};
}
struct mut_arr_1* new_mut_arr_0(struct ctx* ctx) {
	struct mut_arr_1* temp0;
	temp0 = (struct mut_arr_1*) alloc(ctx, sizeof(struct mut_arr_1));
	(*(temp0) = (struct mut_arr_1) {0, 0, 0, NULL}, 0);
	return temp0;
}
struct mut_arr_2* new_mut_arr_1(struct ctx* ctx) {
	struct mut_arr_2* temp0;
	temp0 = (struct mut_arr_2*) alloc(ctx, sizeof(struct mut_arr_2));
	(*(temp0) = (struct mut_arr_2) {0, 0, 0, NULL}, 0);
	return temp0;
}
uint8_t parse_named_args_recur(struct ctx* ctx, struct arr_1 args, struct mut_dict_0 builder) {
	struct arr_0 first_name0;
	struct arr_1 tl1;
	struct opt_10 _matched4;
	struct some_10 s2;
	uint64_t next_named_arg_index3;
	struct arr_1 _tailCallargs;
	struct mut_dict_0 _tailCallbuilder;
	top:
	first_name0 = remove_start(ctx, first_1(ctx, args), (struct arr_0) {2, constantarr_0_16});
	tl1 = tail_2(ctx, args);
	_matched4 = find_index(ctx, tl1, (struct fun_mut1_6) {(fun_ptr3_7) parse_named_args_recur__lambda0, (uint8_t*) NULL});
	switch (_matched4.kind) {
		case 0:
			return add_1(ctx, builder, first_name0, tl1);
		case 1:
			s2 = _matched4.as1;
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
struct arr_0 remove_start(struct ctx* ctx, struct arr_0 a, struct arr_0 start) {
	return force(ctx, try_remove_start(ctx, a, start));
}
struct arr_0 force(struct ctx* ctx, struct opt_11 a) {
	struct opt_11 _matched2;
	struct none n0;
	struct some_11 s1;
	_matched2 = a;
	switch (_matched2.kind) {
		case 0:
			n0 = _matched2.as0;
			return fail_1(ctx, (struct arr_0) {27, constantarr_0_17});
		case 1:
			s1 = _matched2.as1;
			return s1.value;
		default:
			return (assert(0),(struct arr_0) {0, NULL});
	}
}
struct arr_0 fail_1(struct ctx* ctx, struct arr_0 reason) {
	return throw_1(ctx, (struct exception) {reason});
}
struct arr_0 throw_1(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx0;
	exn_ctx0 = get_exception_ctx(ctx);
	hard_forbid(null__q_1(exn_ctx0->jmp_buf_ptr));
	(exn_ctx0->thrown_exception = e, 0);
	(longjmp(exn_ctx0->jmp_buf_ptr, number_to_throw(ctx)), 0);
	return todo_2();
}
struct arr_0 todo_2() {
	return (assert(0),(struct arr_0) {0, NULL});
}
struct opt_11 try_remove_start(struct ctx* ctx, struct arr_0 a, struct arr_0 start) {
	if (starts_with__q(ctx, a, start)) {
		return (struct opt_11) {1, .as1 = (struct some_11) {slice_starting_at_1(ctx, a, start.size)}};
	} else {
		return (struct opt_11) {0, .as0 = (struct none) {0}};
	}
}
struct arr_0 first_1(struct ctx* ctx, struct arr_1 a) {
	forbid_0(ctx, empty__q_6(a));
	return at_2(ctx, a, 0);
}
uint8_t empty__q_6(struct arr_1 a) {
	return zero__q_0(a.size);
}
struct arr_1 tail_2(struct ctx* ctx, struct arr_1 a) {
	forbid_0(ctx, empty__q_6(a));
	return slice_starting_at_2(ctx, a, 1);
}
uint8_t parse_named_args_recur__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr_0 it) {
	return starts_with__q(ctx, it, (struct arr_0) {2, constantarr_0_16});
}
uint8_t add_1(struct ctx* ctx, struct mut_dict_0 m, struct arr_0 key, struct arr_1 value) {
	forbid_0(ctx, has__q_0(ctx, m, key));
	push_0(ctx, m.keys, key);
	return push_1(ctx, m.values, value);
}
uint8_t has__q_0(struct ctx* ctx, struct mut_dict_0 d, struct arr_0 key) {
	return has__q_1(ctx, unsafe_as_dict_0(ctx, d), key);
}
uint8_t has__q_1(struct ctx* ctx, struct dict_0* d, struct arr_0 key) {
	return has__q_2(get_1(ctx, d, key));
}
uint8_t has__q_2(struct opt_9 a) {
	return !empty__q_7(a);
}
uint8_t empty__q_7(struct opt_9 a) {
	struct opt_9 _matched2;
	struct none n0;
	struct some_9 s1;
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
struct opt_9 get_1(struct ctx* ctx, struct dict_0* d, struct arr_0 key) {
	return get_recursive_0(ctx, d->keys, d->values, 0, key);
}
struct opt_9 get_recursive_0(struct ctx* ctx, struct arr_1 keys, struct arr_6 values, uint64_t idx, struct arr_0 key) {
	struct arr_1 _tailCallkeys;
	struct arr_6 _tailCallvalues;
	uint64_t _tailCallidx;
	struct arr_0 _tailCallkey;
	top:
	if (_op_equal_equal_1(idx, keys.size)) {
		return (struct opt_9) {0, .as0 = (struct none) {0}};
	} else {
		if (_op_equal_equal_4(key, at_2(ctx, keys, idx))) {
			return (struct opt_9) {1, .as1 = (struct some_9) {at_4(ctx, values, idx)}};
		} else {
			_tailCallkeys = keys;
			_tailCallvalues = values;
			_tailCallidx = incr_1(ctx, idx);
			_tailCallkey = key;
			keys = _tailCallkeys;
			values = _tailCallvalues;
			idx = _tailCallidx;
			key = _tailCallkey;
			goto top;
		}
	}
}
struct arr_1 at_4(struct ctx* ctx, struct arr_6 a, uint64_t index) {
	assert_0(ctx, _op_less_0(index, a.size));
	return noctx_at_6(a, index);
}
struct arr_1 noctx_at_6(struct arr_6 a, uint64_t index) {
	hard_assert(_op_less_0(index, a.size));
	return (*((a.data + index)));
}
struct dict_0* unsafe_as_dict_0(struct ctx* ctx, struct mut_dict_0 m) {
	struct dict_0* temp0;
	temp0 = (struct dict_0*) alloc(ctx, sizeof(struct dict_0));
	(*(temp0) = (struct dict_0) {unsafe_as_arr_0(m.keys), unsafe_as_arr_1(m.values)}, 0);
	return temp0;
}
struct arr_6 unsafe_as_arr_1(struct mut_arr_2* a) {
	return (struct arr_6) {a->size, a->data};
}
uint8_t push_0(struct ctx* ctx, struct mut_arr_1* a, struct arr_0 value) {
	if (_op_equal_equal_1(a->size, a->capacity)) {
		increase_capacity_to_0(ctx, a, (zero__q_0(a->size) ? four_0() : _op_times_0(ctx, a->size, two_1())));
	} else {
		0;
	}
	ensure_capacity_0(ctx, a, round_up_to_power_of_two(ctx, incr_1(ctx, a->size)));
	assert_0(ctx, _op_less_0(a->size, a->capacity));
	(*((a->data + a->size)) = value, 0);
	return (a->size = incr_1(ctx, a->size), 0);
}
uint8_t increase_capacity_to_0(struct ctx* ctx, struct mut_arr_1* a, uint64_t new_capacity) {
	struct arr_0* old_data0;
	assert_0(ctx, _op_greater_0(new_capacity, a->capacity));
	old_data0 = a->data;
	(a->capacity = new_capacity, 0);
	(a->data = uninitialized_data_0(ctx, new_capacity), 0);
	return copy_data_from_0(ctx, a->data, old_data0, a->size);
}
uint8_t copy_data_from_0(struct ctx* ctx, struct arr_0* to, struct arr_0* from, uint64_t len) {
	uint64_t hl0;
	struct arr_0* _tailCallto;
	struct arr_0* _tailCallfrom;
	uint64_t _tailCalllen;
	top:
	if (_op_less_0(len, eight_0())) {
		return copy_data_from_small_0(ctx, to, from, len);
	} else {
		hl0 = _op_div(ctx, len, two_1());
		copy_data_from_0(ctx, to, from, hl0);
		_tailCallto = (to + hl0);
		_tailCallfrom = (from + hl0);
		_tailCalllen = _op_minus_1(ctx, len, hl0);
		to = _tailCallto;
		from = _tailCallfrom;
		len = _tailCalllen;
		goto top;
	}
}
uint8_t copy_data_from_small_0(struct ctx* ctx, struct arr_0* to, struct arr_0* from, uint64_t len) {
	if (zero__q_0(len)) {
		return 0;
	} else {
		(*(to) = (*(from)), 0);
		return copy_data_from_0(ctx, incr_2(to), incr_2(from), decr(ctx, len));
	}
}
struct arr_0* incr_2(struct arr_0* p) {
	return (p + 1);
}
uint64_t decr(struct ctx* ctx, uint64_t a) {
	forbid_0(ctx, zero__q_0(a));
	return wrap_decr_0(a);
}
uint64_t wrap_decr_0(uint64_t a) {
	return (a - 1);
}
uint64_t _op_div(struct ctx* ctx, uint64_t a, uint64_t b) {
	forbid_0(ctx, zero__q_0(b));
	return (a / b);
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
uint8_t ensure_capacity_0(struct ctx* ctx, struct mut_arr_1* a, uint64_t capacity) {
	if (_op_less_0(a->capacity, capacity)) {
		return increase_capacity_to_0(ctx, a, round_up_to_power_of_two(ctx, capacity));
	} else {
		return 0;
	}
}
uint64_t round_up_to_power_of_two(struct ctx* ctx, uint64_t n) {
	return round_up_to_power_of_two_recur(ctx, 1, n);
}
uint64_t round_up_to_power_of_two_recur(struct ctx* ctx, uint64_t acc, uint64_t n) {
	uint64_t _tailCallacc;
	uint64_t _tailCalln;
	top:
	if (_op_greater_equal(acc, n)) {
		return acc;
	} else {
		_tailCallacc = _op_times_0(ctx, acc, two_1());
		_tailCalln = n;
		acc = _tailCallacc;
		n = _tailCalln;
		goto top;
	}
}
uint8_t push_1(struct ctx* ctx, struct mut_arr_2* a, struct arr_1 value) {
	if (_op_equal_equal_1(a->size, a->capacity)) {
		increase_capacity_to_1(ctx, a, (zero__q_0(a->size) ? four_0() : _op_times_0(ctx, a->size, two_1())));
	} else {
		0;
	}
	ensure_capacity_1(ctx, a, round_up_to_power_of_two(ctx, incr_1(ctx, a->size)));
	assert_0(ctx, _op_less_0(a->size, a->capacity));
	(*((a->data + a->size)) = value, 0);
	return (a->size = incr_1(ctx, a->size), 0);
}
uint8_t increase_capacity_to_1(struct ctx* ctx, struct mut_arr_2* a, uint64_t new_capacity) {
	struct arr_1* old_data0;
	assert_0(ctx, _op_greater_0(new_capacity, a->capacity));
	old_data0 = a->data;
	(a->capacity = new_capacity, 0);
	(a->data = uninitialized_data_1(ctx, new_capacity), 0);
	return copy_data_from_1(ctx, a->data, old_data0, a->size);
}
struct arr_1* uninitialized_data_1(struct ctx* ctx, uint64_t size) {
	uint8_t* bptr0;
	bptr0 = alloc(ctx, (size * sizeof(struct arr_1)));
	return (struct arr_1*) bptr0;
}
uint8_t copy_data_from_1(struct ctx* ctx, struct arr_1* to, struct arr_1* from, uint64_t len) {
	uint64_t hl0;
	struct arr_1* _tailCallto;
	struct arr_1* _tailCallfrom;
	uint64_t _tailCalllen;
	top:
	if (_op_less_0(len, eight_0())) {
		return copy_data_from_small_1(ctx, to, from, len);
	} else {
		hl0 = _op_div(ctx, len, two_1());
		copy_data_from_1(ctx, to, from, hl0);
		_tailCallto = (to + hl0);
		_tailCallfrom = (from + hl0);
		_tailCalllen = _op_minus_1(ctx, len, hl0);
		to = _tailCallto;
		from = _tailCallfrom;
		len = _tailCalllen;
		goto top;
	}
}
uint8_t copy_data_from_small_1(struct ctx* ctx, struct arr_1* to, struct arr_1* from, uint64_t len) {
	if (zero__q_0(len)) {
		return 0;
	} else {
		(*(to) = (*(from)), 0);
		return copy_data_from_1(ctx, incr_3(to), incr_3(from), decr(ctx, len));
	}
}
struct arr_1* incr_3(struct arr_1* p) {
	return (p + 1);
}
uint8_t ensure_capacity_1(struct ctx* ctx, struct mut_arr_2* a, uint64_t capacity) {
	if (_op_less_0(a->capacity, capacity)) {
		return increase_capacity_to_1(ctx, a, round_up_to_power_of_two(ctx, capacity));
	} else {
		return 0;
	}
}
struct dict_0* freeze_1(struct ctx* ctx, struct mut_dict_0 m) {
	struct dict_0* temp0;
	temp0 = (struct dict_0*) alloc(ctx, sizeof(struct dict_0));
	(*(temp0) = (struct dict_0) {freeze_0(m.keys), freeze_2(m.values)}, 0);
	return temp0;
}
struct arr_6 freeze_2(struct mut_arr_2* a) {
	(a->frozen__q = 1, 0);
	return unsafe_as_arr_1(a);
}
struct arr_1 slice_after_0(struct ctx* ctx, struct arr_1 a, uint64_t before_begin) {
	return slice_starting_at_2(ctx, a, incr_1(ctx, before_begin));
}
struct mut_arr_3* fill_mut_arr(struct ctx* ctx, uint64_t size, struct opt_9 value) {
	struct fill_mut_arr__lambda0* temp0;
	return make_mut_arr_1(ctx, size, (struct fun_mut1_7) {(fun_ptr3_8) fill_mut_arr__lambda0, (uint8_t*) (temp0 = (struct fill_mut_arr__lambda0*) alloc(ctx, sizeof(struct fill_mut_arr__lambda0)), ((*(temp0) = (struct fill_mut_arr__lambda0) {value}, 0), temp0))});
}
struct mut_arr_3* make_mut_arr_1(struct ctx* ctx, uint64_t size, struct fun_mut1_7 f) {
	struct mut_arr_3* res0;
	res0 = new_uninitialized_mut_arr_1(ctx, size);
	make_mut_arr_worker_1(ctx, res0, 0, f);
	return res0;
}
struct mut_arr_3* new_uninitialized_mut_arr_1(struct ctx* ctx, uint64_t size) {
	struct mut_arr_3* temp0;
	temp0 = (struct mut_arr_3*) alloc(ctx, sizeof(struct mut_arr_3));
	(*(temp0) = (struct mut_arr_3) {0, size, size, uninitialized_data_2(ctx, size)}, 0);
	return temp0;
}
struct opt_9* uninitialized_data_2(struct ctx* ctx, uint64_t size) {
	uint8_t* bptr0;
	bptr0 = alloc(ctx, (size * sizeof(struct opt_9)));
	return (struct opt_9*) bptr0;
}
uint8_t make_mut_arr_worker_1(struct ctx* ctx, struct mut_arr_3* m, uint64_t i, struct fun_mut1_7 f) {
	struct mut_arr_3* _tailCallm;
	uint64_t _tailCalli;
	struct fun_mut1_7 _tailCallf;
	top:
	if (_op_equal_equal_1(i, m->size)) {
		return 0;
	} else {
		set_at_1(ctx, m, i, call_11(ctx, f, i));
		_tailCallm = m;
		_tailCalli = incr_1(ctx, i);
		_tailCallf = f;
		m = _tailCallm;
		i = _tailCalli;
		f = _tailCallf;
		goto top;
	}
}
uint8_t set_at_1(struct ctx* ctx, struct mut_arr_3* a, uint64_t index, struct opt_9 value) {
	assert_0(ctx, _op_less_0(index, a->size));
	return noctx_set_at_2(a, index, value);
}
uint8_t noctx_set_at_2(struct mut_arr_3* a, uint64_t index, struct opt_9 value) {
	hard_assert(_op_less_0(index, a->size));
	return (*((a->data + index)) = value, 0);
}
struct opt_9 call_11(struct ctx* ctx, struct fun_mut1_7 f, uint64_t p0) {
	return call_with_ctx_10(ctx, f, p0);
}
struct opt_9 call_with_ctx_10(struct ctx* c, struct fun_mut1_7 f, uint64_t p0) {
	return f.fun_ptr(c, f.closure, p0);
}
struct opt_9 fill_mut_arr__lambda0(struct ctx* ctx, struct fill_mut_arr__lambda0* _closure, uint64_t ignore) {
	return _closure->value;
}
uint8_t each_0(struct ctx* ctx, struct dict_0* d, struct fun_mut2_0 f) {
	struct dict_0* temp0;
	struct dict_0* _tailCalld;
	struct fun_mut2_0 _tailCallf;
	top:
	if (empty__q_8(ctx, d)) {
		return 0;
	} else {
		call_12(ctx, f, first_1(ctx, d->keys), first_2(ctx, d->values));
		_tailCalld = (temp0 = (struct dict_0*) alloc(ctx, sizeof(struct dict_0)), ((*(temp0) = (struct dict_0) {tail_2(ctx, d->keys), tail_3(ctx, d->values)}, 0), temp0));
		_tailCallf = f;
		d = _tailCalld;
		f = _tailCallf;
		goto top;
	}
}
uint8_t empty__q_8(struct ctx* ctx, struct dict_0* d) {
	return empty__q_6(d->keys);
}
uint8_t call_12(struct ctx* ctx, struct fun_mut2_0 f, struct arr_0 p0, struct arr_1 p1) {
	return call_with_ctx_11(ctx, f, p0, p1);
}
uint8_t call_with_ctx_11(struct ctx* c, struct fun_mut2_0 f, struct arr_0 p0, struct arr_1 p1) {
	return f.fun_ptr(c, f.closure, p0, p1);
}
struct arr_1 first_2(struct ctx* ctx, struct arr_6 a) {
	forbid_0(ctx, empty__q_9(a));
	return at_4(ctx, a, 0);
}
uint8_t empty__q_9(struct arr_6 a) {
	return zero__q_0(a.size);
}
struct arr_6 tail_3(struct ctx* ctx, struct arr_6 a) {
	forbid_0(ctx, empty__q_9(a));
	return slice_starting_at_3(ctx, a, 1);
}
struct arr_6 slice_starting_at_3(struct ctx* ctx, struct arr_6 a, uint64_t begin) {
	assert_0(ctx, _op_less_equal_0(begin, a.size));
	return slice_3(ctx, a, begin, _op_minus_1(ctx, a.size, begin));
}
struct arr_6 slice_3(struct ctx* ctx, struct arr_6 a, uint64_t begin, uint64_t size) {
	assert_0(ctx, _op_less_equal_0(_op_plus_0(ctx, begin, size), a.size));
	return (struct arr_6) {size, (a.data + begin)};
}
struct opt_10 index_of(struct ctx* ctx, struct arr_1 a, struct arr_0 value) {
	struct index_of__lambda0* temp0;
	return find_index(ctx, a, (struct fun_mut1_6) {(fun_ptr3_7) index_of__lambda0, (uint8_t*) (temp0 = (struct index_of__lambda0*) alloc(ctx, sizeof(struct index_of__lambda0)), ((*(temp0) = (struct index_of__lambda0) {value}, 0), temp0))});
}
uint8_t index_of__lambda0(struct ctx* ctx, struct index_of__lambda0* _closure, struct arr_0 it) {
	return _op_equal_equal_4(it, _closure->value);
}
uint8_t set_0(struct cell_2* c, uint8_t v) {
	return (c->value = v, 0);
}
struct arr_0 _op_plus_1(struct ctx* ctx, struct arr_0 a, struct arr_0 b) {
	struct _op_plus_1__lambda0* temp0;
	return make_arr_1(ctx, _op_plus_0(ctx, a.size, b.size), (struct fun_mut1_8) {(fun_ptr3_9) _op_plus_1__lambda0, (uint8_t*) (temp0 = (struct _op_plus_1__lambda0*) alloc(ctx, sizeof(struct _op_plus_1__lambda0)), ((*(temp0) = (struct _op_plus_1__lambda0) {a, b}, 0), temp0))});
}
struct arr_0 make_arr_1(struct ctx* ctx, uint64_t size, struct fun_mut1_8 f) {
	return freeze_3(make_mut_arr_2(ctx, size, f));
}
struct arr_0 freeze_3(struct mut_arr_4* a) {
	(a->frozen__q = 1, 0);
	return unsafe_as_arr_2(a);
}
struct arr_0 unsafe_as_arr_2(struct mut_arr_4* a) {
	return (struct arr_0) {a->size, a->data};
}
struct mut_arr_4* make_mut_arr_2(struct ctx* ctx, uint64_t size, struct fun_mut1_8 f) {
	struct mut_arr_4* res0;
	res0 = new_uninitialized_mut_arr_2(ctx, size);
	make_mut_arr_worker_2(ctx, res0, 0, f);
	return res0;
}
struct mut_arr_4* new_uninitialized_mut_arr_2(struct ctx* ctx, uint64_t size) {
	struct mut_arr_4* temp0;
	temp0 = (struct mut_arr_4*) alloc(ctx, sizeof(struct mut_arr_4));
	(*(temp0) = (struct mut_arr_4) {0, size, size, uninitialized_data_3(ctx, size)}, 0);
	return temp0;
}
char* uninitialized_data_3(struct ctx* ctx, uint64_t size) {
	uint8_t* bptr0;
	bptr0 = alloc(ctx, (size * sizeof(char)));
	return (char*) bptr0;
}
uint8_t make_mut_arr_worker_2(struct ctx* ctx, struct mut_arr_4* m, uint64_t i, struct fun_mut1_8 f) {
	struct mut_arr_4* _tailCallm;
	uint64_t _tailCalli;
	struct fun_mut1_8 _tailCallf;
	top:
	if (_op_equal_equal_1(i, m->size)) {
		return 0;
	} else {
		set_at_2(ctx, m, i, call_13(ctx, f, i));
		_tailCallm = m;
		_tailCalli = incr_1(ctx, i);
		_tailCallf = f;
		m = _tailCallm;
		i = _tailCalli;
		f = _tailCallf;
		goto top;
	}
}
uint8_t set_at_2(struct ctx* ctx, struct mut_arr_4* a, uint64_t index, char value) {
	assert_0(ctx, _op_less_0(index, a->size));
	return noctx_set_at_3(a, index, value);
}
uint8_t noctx_set_at_3(struct mut_arr_4* a, uint64_t index, char value) {
	hard_assert(_op_less_0(index, a->size));
	return (*((a->data + index)) = value, 0);
}
char call_13(struct ctx* ctx, struct fun_mut1_8 f, uint64_t p0) {
	return call_with_ctx_12(ctx, f, p0);
}
char call_with_ctx_12(struct ctx* c, struct fun_mut1_8 f, uint64_t p0) {
	return f.fun_ptr(c, f.closure, p0);
}
char _op_plus_1__lambda0(struct ctx* ctx, struct _op_plus_1__lambda0* _closure, uint64_t i) {
	if (_op_less_0(i, _closure->a.size)) {
		return at_3(ctx, _closure->a, i);
	} else {
		return at_3(ctx, _closure->b, _op_minus_1(ctx, i, _closure->a.size));
	}
}
struct opt_9 at_5(struct ctx* ctx, struct mut_arr_3* a, uint64_t index) {
	assert_0(ctx, _op_less_0(index, a->size));
	return noctx_at_7(a, index);
}
struct opt_9 noctx_at_7(struct mut_arr_3* a, uint64_t index) {
	hard_assert(_op_less_0(index, a->size));
	return (*((a->data + index)));
}
uint8_t parse_cmd_line_args__lambda0(struct ctx* ctx, struct parse_cmd_line_args__lambda0* _closure, struct arr_0 key, struct arr_1 value) {
	struct opt_10 _matched2;
	struct some_10 s0;
	uint64_t idx1;
	_matched2 = index_of(ctx, _closure->t_names, key);
	switch (_matched2.kind) {
		case 0:
			if (_op_equal_equal_4(key, (struct arr_0) {4, constantarr_0_19})) {
				return set_0(_closure->help, 1);
			} else {
				return fail_0(ctx, _op_plus_1(ctx, (struct arr_0) {15, constantarr_0_20}, key));
			}
		case 1:
			s0 = _matched2.as1;
			idx1 = s0.value;
			forbid_0(ctx, has__q_2(at_5(ctx, _closure->values, idx1)));
			return set_at_1(ctx, _closure->values, idx1, (struct opt_9) {1, .as1 = (struct some_9) {value}});
		default:
			return (assert(0),0);
	}
}
uint8_t get_2(struct cell_2* c) {
	return c->value;
}
struct test_options call_14(struct ctx* ctx, struct fun1 f, struct arr_5 p0) {
	return call_with_ctx_13(ctx, f, p0);
}
struct test_options call_with_ctx_13(struct ctx* c, struct fun1 f, struct arr_5 p0) {
	return f.fun_ptr(c, f.closure, p0);
}
struct arr_5 freeze_4(struct mut_arr_3* a) {
	(a->frozen__q = 1, 0);
	return unsafe_as_arr_3(a);
}
struct arr_5 unsafe_as_arr_3(struct mut_arr_3* a) {
	return (struct arr_5) {a->size, a->data};
}
struct opt_9 at_6(struct ctx* ctx, struct arr_5 a, uint64_t index) {
	assert_0(ctx, _op_less_0(index, a.size));
	return noctx_at_8(a, index);
}
struct opt_9 noctx_at_8(struct arr_5 a, uint64_t index) {
	hard_assert(_op_less_0(index, a.size));
	return (*((a.data + index)));
}
uint64_t literal_1(struct ctx* ctx, struct arr_0 s) {
	uint64_t higher_digits0;
	if (empty__q_0(s)) {
		return 0;
	} else {
		higher_digits0 = literal_1(ctx, rtail(ctx, s));
		return _op_plus_0(ctx, _op_times_0(ctx, higher_digits0, ten_0()), char_to_nat(last(ctx, s)));
	}
}
struct arr_0 rtail(struct ctx* ctx, struct arr_0 a) {
	forbid_0(ctx, empty__q_0(a));
	return slice_1(ctx, a, 0, decr(ctx, a.size));
}
uint64_t char_to_nat(char c) {
	if (_op_equal_equal_0(c, literal_0((struct arr_0) {1, constantarr_0_21}))) {
		return 0;
	} else {
		if (_op_equal_equal_0(c, literal_0((struct arr_0) {1, constantarr_0_22}))) {
			return 1;
		} else {
			if (_op_equal_equal_0(c, literal_0((struct arr_0) {1, constantarr_0_23}))) {
				return two_1();
			} else {
				if (_op_equal_equal_0(c, literal_0((struct arr_0) {1, constantarr_0_24}))) {
					return three_0();
				} else {
					if (_op_equal_equal_0(c, literal_0((struct arr_0) {1, constantarr_0_25}))) {
						return four_0();
					} else {
						if (_op_equal_equal_0(c, literal_0((struct arr_0) {1, constantarr_0_26}))) {
							return five_0();
						} else {
							if (_op_equal_equal_0(c, literal_0((struct arr_0) {1, constantarr_0_27}))) {
								return six_0();
							} else {
								if (_op_equal_equal_0(c, literal_0((struct arr_0) {1, constantarr_0_28}))) {
									return seven_0();
								} else {
									if (_op_equal_equal_0(c, literal_0((struct arr_0) {1, constantarr_0_29}))) {
										return eight_0();
									} else {
										if (_op_equal_equal_0(c, literal_0((struct arr_0) {1, constantarr_0_30}))) {
											return nine_0();
										} else {
											return todo_3();
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
uint64_t todo_3() {
	return (assert(0),0);
}
char last(struct ctx* ctx, struct arr_0 a) {
	forbid_0(ctx, empty__q_0(a));
	return at_3(ctx, a, decr(ctx, a.size));
}
struct test_options main_0__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr_5 values) {
	struct opt_9 print_tests_strs0;
	struct opt_9 overwrite_output_strs1;
	struct opt_9 max_failures_strs2;
	uint8_t print_tests__q3;
	uint8_t overwrite_output__q6;
	struct opt_9 _matched5;
	struct some_9 s4;
	uint64_t max_failures10;
	struct opt_9 _matched9;
	struct some_9 s7;
	struct arr_1 strs8;
	print_tests_strs0 = at_6(ctx, values, literal_1(ctx, (struct arr_0) {1, constantarr_0_21}));
	overwrite_output_strs1 = at_6(ctx, values, literal_1(ctx, (struct arr_0) {1, constantarr_0_22}));
	max_failures_strs2 = at_6(ctx, values, literal_1(ctx, (struct arr_0) {1, constantarr_0_23}));
	print_tests__q3 = has__q_2(print_tests_strs0);
	overwrite_output__q6 = (_matched5 = overwrite_output_strs1, _matched5.kind == 0 ? 0 : _matched5.kind == 1 ? (s4 = _matched5.as1, (assert_0(ctx, empty__q_6(s4.value)), 1)) : (assert(0),0));
	max_failures10 = (_matched9 = max_failures_strs2, _matched9.kind == 0 ? literal_1(ctx, (struct arr_0) {3, constantarr_0_31}) : _matched9.kind == 1 ? (s7 = _matched9.as1, (strs8 = s7.value, (assert_0(ctx, _op_equal_equal_1(strs8.size, literal_1(ctx, (struct arr_0) {1, constantarr_0_22}))), literal_1(ctx, first_1(ctx, strs8))))) : (assert(0),0));
	return (struct test_options) {print_tests__q3, overwrite_output__q6, max_failures10};
}
struct fut_0* resolved_1(struct ctx* ctx, int32_t value) {
	struct fut_0* temp0;
	temp0 = (struct fut_0*) alloc(ctx, sizeof(struct fut_0));
	(*(temp0) = (struct fut_0) {new_lock(), (struct fut_state_0) {1, .as1 = (struct fut_state_resolved_0) {value}}}, 0);
	return temp0;
}
uint8_t print_help(struct ctx* ctx) {
	print_sync((struct arr_0) {18, constantarr_0_32});
	print_sync((struct arr_0) {8, constantarr_0_33});
	print_sync((struct arr_0) {38, constantarr_0_34});
	return print_sync((struct arr_0) {64, constantarr_0_35});
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
int32_t literal_2(struct ctx* ctx, struct arr_0 s) {
	return literal_3(ctx, s);
}
int64_t literal_3(struct ctx* ctx, struct arr_0 s) {
	char fst0;
	uint64_t n1;
	fst0 = at_3(ctx, s, 0);
	if (_op_equal_equal_0(fst0, literal_0((struct arr_0) {1, constantarr_0_36}))) {
		n1 = literal_1(ctx, tail_1(ctx, s));
		return neg_0(ctx, n1);
	} else {
		if (_op_equal_equal_0(fst0, literal_0((struct arr_0) {1, constantarr_0_37}))) {
			return to_int(ctx, literal_1(ctx, tail_1(ctx, s)));
		} else {
			return to_int(ctx, literal_1(ctx, s));
		}
	}
}
int64_t neg_0(struct ctx* ctx, uint64_t n) {
	return neg_1(ctx, to_int(ctx, n));
}
int64_t neg_1(struct ctx* ctx, int64_t i) {
	return _op_times_1(ctx, i, neg_one_0());
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
	_matched0 = compare_37(a, b);
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
	return (million_1() * neg_one_0());
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
int64_t neg_one_0() {
	return (0 - 1);
}
int64_t to_int(struct ctx* ctx, uint64_t n) {
	assert_0(ctx, _op_less_0(n, million_0()));
	return n;
}
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
	noze_exe2 = child_path(ctx, child_path(ctx, noze_path1, (struct arr_0) {3, constantarr_0_40}), (struct arr_0) {4, constantarr_0_41});
	env3 = get_environ(ctx);
	noze_failures4 = first_failures(ctx, run_noze_tests(ctx, child_path(ctx, test_path0, (struct arr_0) {12, constantarr_0_79}), noze_exe2, env3, options), (struct fun0) {(fun_ptr2_3) do_test__lambda0, (uint8_t*) (temp0 = (struct do_test__lambda0*) alloc(ctx, sizeof(struct do_test__lambda0)), ((*(temp0) = (struct do_test__lambda0) {test_path0, noze_exe2, env3, options}, 0), temp0))});
	all_failures5 = first_failures(ctx, noze_failures4, (struct fun0) {(fun_ptr2_3) do_test__lambda1, (uint8_t*) (temp1 = (struct do_test__lambda1*) alloc(ctx, sizeof(struct do_test__lambda1)), ((*(temp1) = (struct do_test__lambda1) {noze_path1, options}, 0), temp1))});
	return print_failures(ctx, all_failures5, options);
}
struct arr_0 parent_path(struct ctx* ctx, struct arr_0 a) {
	struct opt_10 _matched1;
	struct some_10 s0;
	_matched1 = r_index_of(ctx, a, literal_0((struct arr_0) {1, constantarr_0_38}));
	switch (_matched1.kind) {
		case 0:
			return (struct arr_0) {0, NULL};
		case 1:
			s0 = _matched1.as1;
			return slice_up_to_1(ctx, a, s0.value);
		default:
			return (assert(0),(struct arr_0) {0, NULL});
	}
}
struct opt_10 r_index_of(struct ctx* ctx, struct arr_0 a, char value) {
	struct r_index_of__lambda0* temp0;
	return find_rindex(ctx, a, (struct fun_mut1_9) {(fun_ptr3_10) r_index_of__lambda0, (uint8_t*) (temp0 = (struct r_index_of__lambda0*) alloc(ctx, sizeof(struct r_index_of__lambda0)), ((*(temp0) = (struct r_index_of__lambda0) {value}, 0), temp0))});
}
struct opt_10 find_rindex(struct ctx* ctx, struct arr_0 a, struct fun_mut1_9 pred) {
	if (empty__q_0(a)) {
		return (struct opt_10) {0, .as0 = (struct none) {0}};
	} else {
		return find_rindex_recur(ctx, a, decr(ctx, a.size), pred);
	}
}
struct opt_10 find_rindex_recur(struct ctx* ctx, struct arr_0 a, uint64_t index, struct fun_mut1_9 pred) {
	struct arr_0 _tailCalla;
	uint64_t _tailCallindex;
	struct fun_mut1_9 _tailCallpred;
	top:
	if (call_15(ctx, pred, at_3(ctx, a, index))) {
		return (struct opt_10) {1, .as1 = (struct some_10) {index}};
	} else {
		if (zero__q_0(index)) {
			return (struct opt_10) {0, .as0 = (struct none) {0}};
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
uint8_t call_15(struct ctx* ctx, struct fun_mut1_9 f, char p0) {
	return call_with_ctx_14(ctx, f, p0);
}
uint8_t call_with_ctx_14(struct ctx* c, struct fun_mut1_9 f, char p0) {
	return f.fun_ptr(c, f.closure, p0);
}
uint8_t r_index_of__lambda0(struct ctx* ctx, struct r_index_of__lambda0* _closure, char it) {
	return _op_equal_equal_0(it, _closure->value);
}
struct arr_0 slice_up_to_1(struct ctx* ctx, struct arr_0 a, uint64_t size) {
	assert_0(ctx, _op_less_0(size, a.size));
	return slice_1(ctx, a, 0, size);
}
struct arr_0 current_executable_path(struct ctx* ctx) {
	return read_link(ctx, (struct arr_0) {14, constantarr_0_39});
}
struct arr_0 read_link(struct ctx* ctx, struct arr_0 path) {
	struct mut_arr_4* buff0;
	int64_t size1;
	buff0 = new_uninitialized_mut_arr_2(ctx, thousand_0());
	size1 = readlink(to_c_str(ctx, path), buff0->data, buff0->size);
	check_errno_if_neg_one(ctx, size1);
	return slice_up_to_1(ctx, freeze_3(buff0), to_nat_0(ctx, size1));
}
char* to_c_str(struct ctx* ctx, struct arr_0 a) {
	return _op_plus_1(ctx, a, (struct arr_0) {1, constantarr_0_1}).data;
}
uint8_t check_errno_if_neg_one(struct ctx* ctx, int64_t e) {
	if (_op_equal_equal_2(e, neg_one_0())) {
		check_posix_error(ctx, errno);
		return hard_unreachable_1();
	} else {
		return 0;
	}
}
uint8_t check_posix_error(struct ctx* ctx, int32_t e) {
	return assert_0(ctx, zero__q_1(e));
}
uint8_t hard_unreachable_1() {
	return (assert(0),0);
}
uint64_t to_nat_0(struct ctx* ctx, int64_t i) {
	forbid_0(ctx, negative__q(ctx, i));
	return i;
}
uint8_t negative__q(struct ctx* ctx, int64_t i) {
	return _op_less_1(i, 0);
}
struct arr_0 child_path(struct ctx* ctx, struct arr_0 a, struct arr_0 child_name) {
	return _op_plus_1(ctx, _op_plus_1(ctx, a, (struct arr_0) {1, constantarr_0_38}), child_name);
}
struct dict_1* get_environ(struct ctx* ctx) {
	struct mut_dict_1 res0;
	res0 = new_mut_dict_1(ctx);
	get_environ_recur(ctx, environ, res0);
	return freeze_5(ctx, res0);
}
struct mut_dict_1 new_mut_dict_1(struct ctx* ctx) {
	return (struct mut_dict_1) {new_mut_arr_0(ctx), new_mut_arr_0(ctx)};
}
uint8_t get_environ_recur(struct ctx* ctx, char** env, struct mut_dict_1 res) {
	char** _tailCallenv;
	struct mut_dict_1 _tailCallres;
	top:
	if (null__q_2((*(env)))) {
		return 0;
	} else {
		add_2(ctx, res, parse_environ_entry(ctx, (*(env))));
		_tailCallenv = incr_4(env);
		_tailCallres = res;
		env = _tailCallenv;
		res = _tailCallres;
		goto top;
	}
}
uint8_t null__q_2(char* a) {
	return _op_equal_equal_1((uint64_t) a, (uint64_t) NULL);
}
uint8_t add_2(struct ctx* ctx, struct mut_dict_1 m, struct key_value_pair* pair) {
	return add_3(ctx, m, pair->key, pair->value);
}
uint8_t add_3(struct ctx* ctx, struct mut_dict_1 m, struct arr_0 key, struct arr_0 value) {
	forbid_0(ctx, has__q_3(ctx, m, key));
	push_0(ctx, m.keys, key);
	return push_0(ctx, m.values, value);
}
uint8_t has__q_3(struct ctx* ctx, struct mut_dict_1 d, struct arr_0 key) {
	return has__q_4(ctx, unsafe_as_dict_1(ctx, d), key);
}
uint8_t has__q_4(struct ctx* ctx, struct dict_1* d, struct arr_0 key) {
	return has__q_5(get_3(ctx, d, key));
}
uint8_t has__q_5(struct opt_11 a) {
	return !empty__q_10(a);
}
uint8_t empty__q_10(struct opt_11 a) {
	struct opt_11 _matched2;
	struct none n0;
	struct some_11 s1;
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
struct opt_11 get_3(struct ctx* ctx, struct dict_1* d, struct arr_0 key) {
	return get_recursive_1(ctx, d->keys, d->values, 0, key);
}
struct opt_11 get_recursive_1(struct ctx* ctx, struct arr_1 keys, struct arr_1 values, uint64_t idx, struct arr_0 key) {
	struct arr_1 _tailCallkeys;
	struct arr_1 _tailCallvalues;
	uint64_t _tailCallidx;
	struct arr_0 _tailCallkey;
	top:
	if (_op_equal_equal_1(idx, keys.size)) {
		return (struct opt_11) {0, .as0 = (struct none) {0}};
	} else {
		if (_op_equal_equal_4(key, at_2(ctx, keys, idx))) {
			return (struct opt_11) {1, .as1 = (struct some_11) {at_2(ctx, values, idx)}};
		} else {
			_tailCallkeys = keys;
			_tailCallvalues = values;
			_tailCallidx = incr_1(ctx, idx);
			_tailCallkey = key;
			keys = _tailCallkeys;
			values = _tailCallvalues;
			idx = _tailCallidx;
			key = _tailCallkey;
			goto top;
		}
	}
}
struct dict_1* unsafe_as_dict_1(struct ctx* ctx, struct mut_dict_1 m) {
	struct dict_1* temp0;
	temp0 = (struct dict_1*) alloc(ctx, sizeof(struct dict_1));
	(*(temp0) = (struct dict_1) {unsafe_as_arr_0(m.keys), unsafe_as_arr_0(m.values)}, 0);
	return temp0;
}
struct key_value_pair* parse_environ_entry(struct ctx* ctx, char* entry) {
	char* key_end0;
	struct arr_0 key1;
	char* value_begin2;
	char* value_end3;
	struct arr_0 value4;
	struct key_value_pair* temp0;
	key_end0 = find_char_in_cstr(entry, literal_0((struct arr_0) {1, constantarr_0_42}));
	key1 = arr_from_begin_end(entry, key_end0);
	value_begin2 = incr_0(key_end0);
	value_end3 = find_cstr_end(value_begin2);
	value4 = arr_from_begin_end(value_begin2, value_end3);
	temp0 = (struct key_value_pair*) alloc(ctx, sizeof(struct key_value_pair));
	(*(temp0) = (struct key_value_pair) {key1, value4}, 0);
	return temp0;
}
char** incr_4(char** p) {
	return (p + 1);
}
struct dict_1* freeze_5(struct ctx* ctx, struct mut_dict_1 m) {
	struct dict_1* temp0;
	temp0 = (struct dict_1*) alloc(ctx, sizeof(struct dict_1));
	(*(temp0) = (struct dict_1) {freeze_0(m.keys), freeze_0(m.values)}, 0);
	return temp0;
}
struct result_3 first_failures(struct ctx* ctx, struct result_3 a, struct fun0 b) {
	struct first_failures__lambda0* temp0;
	return then_1(ctx, a, (struct fun_mut1_10) {(fun_ptr3_11) first_failures__lambda0, (uint8_t*) (temp0 = (struct first_failures__lambda0*) alloc(ctx, sizeof(struct first_failures__lambda0)), ((*(temp0) = (struct first_failures__lambda0) {b}, 0), temp0))});
}
struct result_3 then_1(struct ctx* ctx, struct result_3 a, struct fun_mut1_10 f) {
	struct result_3 _matched2;
	struct ok_3 o0;
	struct err_2 e1;
	_matched2 = a;
	switch (_matched2.kind) {
		case 0:
			o0 = _matched2.as0;
			return call_16(ctx, f, o0.value);
		case 1:
			e1 = _matched2.as1;
			return (struct result_3) {1, .as1 = e1};
		default:
			return (assert(0),(struct result_3) {0});
	}
}
struct result_3 call_16(struct ctx* ctx, struct fun_mut1_10 f, struct arr_0 p0) {
	return call_with_ctx_15(ctx, f, p0);
}
struct result_3 call_with_ctx_15(struct ctx* c, struct fun_mut1_10 f, struct arr_0 p0) {
	return f.fun_ptr(c, f.closure, p0);
}
struct result_3 call_17(struct ctx* ctx, struct fun0 f) {
	return call_with_ctx_16(ctx, f);
}
struct result_3 call_with_ctx_16(struct ctx* c, struct fun0 f) {
	return f.fun_ptr(c, f.closure);
}
struct result_3 first_failures__lambda0__lambda0(struct ctx* ctx, struct first_failures__lambda0__lambda0* _closure, struct arr_0 b_descr) {
	return (struct result_3) {0, .as0 = (struct ok_3) {_op_plus_1(ctx, _op_plus_1(ctx, _closure->a_descr, (struct arr_0) {1, constantarr_0_4}), b_descr)}};
}
struct result_3 first_failures__lambda0(struct ctx* ctx, struct first_failures__lambda0* _closure, struct arr_0 a_descr) {
	struct first_failures__lambda0__lambda0* temp0;
	return then_1(ctx, call_17(ctx, _closure->b), (struct fun_mut1_10) {(fun_ptr3_11) first_failures__lambda0__lambda0, (uint8_t*) (temp0 = (struct first_failures__lambda0__lambda0*) alloc(ctx, sizeof(struct first_failures__lambda0__lambda0)), ((*(temp0) = (struct first_failures__lambda0__lambda0) {a_descr}, 0), temp0))});
}
struct result_3 run_noze_tests(struct ctx* ctx, struct arr_0 path, struct arr_0 path_to_noze, struct dict_1* env, struct test_options options) {
	struct arr_1 tests0;
	struct arr_7 failures1;
	struct run_noze_tests__lambda0* temp0;
	tests0 = list_tests(ctx, path);
	failures1 = flat_map_with_max_size(ctx, tests0, options.max_failures, (struct fun_mut1_12) {(fun_ptr3_13) run_noze_tests__lambda0, (uint8_t*) (temp0 = (struct run_noze_tests__lambda0*) alloc(ctx, sizeof(struct run_noze_tests__lambda0)), ((*(temp0) = (struct run_noze_tests__lambda0) {path_to_noze, env, options}, 0), temp0))});
	if (has__q_6(failures1)) {
		return (struct result_3) {1, .as1 = (struct err_2) {failures1}};
	} else {
		return (struct result_3) {0, .as0 = (struct ok_3) {_op_plus_1(ctx, _op_plus_1(ctx, _op_plus_1(ctx, (struct arr_0) {4, constantarr_0_77}, to_str_3(ctx, tests0.size)), (struct arr_0) {10, constantarr_0_78}), path)}};
	}
}
struct arr_1 list_tests(struct ctx* ctx, struct arr_0 path) {
	struct mut_arr_1* res0;
	struct fun_mut1_6 filter1;
	struct list_tests__lambda1* temp0;
	res0 = new_mut_arr_0(ctx);
	filter1 = (struct fun_mut1_6) {(fun_ptr3_7) list_tests__lambda0, (uint8_t*) NULL};
	each_child_recursive(ctx, path, filter1, (struct fun_mut1_11) {(fun_ptr3_12) list_tests__lambda1, (uint8_t*) (temp0 = (struct list_tests__lambda1*) alloc(ctx, sizeof(struct list_tests__lambda1)), ((*(temp0) = (struct list_tests__lambda1) {res0}, 0), temp0))});
	return freeze_0(res0);
}
uint8_t list_tests__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr_0 s) {
	return 1;
}
uint8_t each_child_recursive(struct ctx* ctx, struct arr_0 path, struct fun_mut1_6 filter, struct fun_mut1_11 f) {
	struct each_child_recursive__lambda0* temp0;
	if (is_dir__q_0(ctx, path)) {
		return each_1(ctx, read_dir_0(ctx, path), (struct fun_mut1_11) {(fun_ptr3_12) each_child_recursive__lambda0, (uint8_t*) (temp0 = (struct each_child_recursive__lambda0*) alloc(ctx, sizeof(struct each_child_recursive__lambda0)), ((*(temp0) = (struct each_child_recursive__lambda0) {filter, path, f}, 0), temp0))});
	} else {
		return call_18(ctx, f, path);
	}
}
uint8_t is_dir__q_0(struct ctx* ctx, struct arr_0 path) {
	return is_dir__q_1(ctx, to_c_str(ctx, path));
}
uint8_t is_dir__q_1(struct ctx* ctx, char* path) {
	struct opt_12 _matched1;
	struct some_12 s0;
	_matched1 = get_stat(ctx, path);
	switch (_matched1.kind) {
		case 0:
			return todo_5();
		case 1:
			s0 = _matched1.as1;
			return _op_equal_equal_5((s0.value->st_mode & s_ifmt(ctx)), s_ifdir(ctx));
		default:
			return (assert(0),0);
	}
}
struct opt_12 get_stat(struct ctx* ctx, char* path) {
	struct stat_t* s0;
	int32_t err1;
	s0 = empty_stat(ctx);
	err1 = stat(path, s0);
	if (_op_equal_equal_3(err1, 0)) {
		return (struct opt_12) {1, .as1 = (struct some_12) {s0}};
	} else {
		assert_0(ctx, _op_equal_equal_3(err1, neg_one_1()));
		if (_op_equal_equal_3(errno, enoent())) {
			return (struct opt_12) {0, .as0 = (struct none) {0}};
		} else {
			return todo_4();
		}
	}
}
struct stat_t* empty_stat(struct ctx* ctx) {
	uint64_t z0;
	struct stat_t* temp0;
	z0 = 0;
	temp0 = (struct stat_t*) alloc(ctx, sizeof(struct stat_t));
	(*(temp0) = (struct stat_t) {z0, 0, z0, 0, 0, z0, z0, z0, 0, 0, z0, z0, z0, z0, z0, z0, z0, z0, z0, z0}, 0);
	return temp0;
}
int32_t neg_one_1() {
	return (0 - 1);
}
int32_t enoent() {
	return two_0();
}
struct opt_12 todo_4() {
	return (assert(0),(struct opt_12) {0});
}
uint8_t todo_5() {
	return (assert(0),0);
}
uint8_t _op_equal_equal_5(uint32_t a, uint32_t b) {
	struct comparison _matched0;
	_matched0 = compare_442(a, b);
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
struct comparison compare_442(uint32_t a, uint32_t b) {
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
uint32_t s_ifmt(struct ctx* ctx) {
	return (two_pow_0(twelve()) * fifteen());
}
uint32_t two_pow_0(uint32_t pow) {
	if (zero__q_2(pow)) {
		return 1;
	} else {
		return (two_pow_0(wrap_decr_1(pow)) * two_3());
	}
}
uint8_t zero__q_2(uint32_t n) {
	return _op_equal_equal_5(n, 0);
}
uint32_t wrap_decr_1(uint32_t a) {
	return (a - 1);
}
uint32_t two_3() {
	return wrap_incr_3(1);
}
uint32_t wrap_incr_3(uint32_t a) {
	return (a + 1);
}
uint32_t twelve() {
	return (eight_2() + four_3());
}
uint32_t eight_2() {
	return wrap_incr_3(seven_3());
}
uint32_t seven_3() {
	return wrap_incr_3(six_3());
}
uint32_t six_3() {
	return wrap_incr_3(five_3());
}
uint32_t five_3() {
	return wrap_incr_3(four_3());
}
uint32_t four_3() {
	return wrap_incr_3(three_3());
}
uint32_t three_3() {
	return wrap_incr_3(two_3());
}
uint32_t fifteen() {
	return wrap_incr_3(fourteen());
}
uint32_t fourteen() {
	return (twelve() + two_3());
}
uint32_t s_ifdir(struct ctx* ctx) {
	return two_pow_0(fourteen());
}
uint8_t each_1(struct ctx* ctx, struct arr_1 a, struct fun_mut1_11 f) {
	struct arr_1 _tailCalla;
	struct fun_mut1_11 _tailCallf;
	top:
	if (empty__q_6(a)) {
		return 0;
	} else {
		call_18(ctx, f, first_1(ctx, a));
		_tailCalla = tail_2(ctx, a);
		_tailCallf = f;
		a = _tailCalla;
		f = _tailCallf;
		goto top;
	}
}
uint8_t call_18(struct ctx* ctx, struct fun_mut1_11 f, struct arr_0 p0) {
	return call_with_ctx_17(ctx, f, p0);
}
uint8_t call_with_ctx_17(struct ctx* c, struct fun_mut1_11 f, struct arr_0 p0) {
	return f.fun_ptr(c, f.closure, p0);
}
struct arr_1 read_dir_0(struct ctx* ctx, struct arr_0 path) {
	return read_dir_1(ctx, to_c_str(ctx, path));
}
struct arr_1 read_dir_1(struct ctx* ctx, char* path) {
	uint8_t* dirp0;
	struct mut_arr_1* res1;
	dirp0 = opendir(path);
	forbid_0(ctx, null__q_0(dirp0));
	res1 = new_mut_arr_0(ctx);
	read_dir_recur(ctx, dirp0, res1);
	return sort_0(ctx, freeze_0(res1));
}
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
	entry0 = (temp0 = (struct dirent*) alloc(ctx, sizeof(struct dirent)), ((*(temp0) = (struct dirent) {0, 0, 0, literal_0((struct arr_0) {1, constantarr_0_1}), zero_4()}, 0), temp0));
	result1 = (temp1 = (struct cell_3*) alloc(ctx, sizeof(struct cell_3)), ((*(temp1) = (struct cell_3) {entry0}, 0), temp1));
	err2 = readdir_r(dirp, entry0, result1);
	assert_0(ctx, zero__q_1(err2));
	if (null__q_0((uint8_t*) get_4(result1))) {
		return 0;
	} else {
		assert_0(ctx, ref_eq__q(get_4(result1), entry0));
		name3 = get_dirent_name(entry0);
		if ((_op_equal_equal_4(name3, (struct arr_0) {1, constantarr_0_43}) || _op_equal_equal_4(name3, (struct arr_0) {2, constantarr_0_44}))) {
			0;
		} else {
			push_0(ctx, res, get_dirent_name(entry0));
		}
		_tailCalldirp = dirp;
		_tailCallres = res;
		dirp = _tailCalldirp;
		res = _tailCallres;
		goto top;
	}
}
struct bytes256 zero_4() {
	return (struct bytes256) {zero_3(), zero_3()};
}
struct dirent* get_4(struct cell_3* c) {
	return c->value;
}
uint8_t ref_eq__q(struct dirent* a, struct dirent* b) {
	return ((uint8_t*) a == (uint8_t*) b);
}
struct arr_0 get_dirent_name(struct dirent* d) {
	uint64_t name_offset0;
	uint8_t* name_ptr1;
	name_offset0 = (((sizeof(uint64_t) + sizeof(int64_t)) + sizeof(uint16_t)) + sizeof(char));
	name_ptr1 = ((uint8_t*) d + name_offset0);
	return to_str_0((char*) name_ptr1);
}
struct arr_1 sort_0(struct ctx* ctx, struct arr_1 a) {
	struct mut_arr_1* m0;
	m0 = to_mut_arr(ctx, a);
	sort_1(ctx, m0);
	return freeze_0(m0);
}
struct mut_arr_1* to_mut_arr(struct ctx* ctx, struct arr_1 a) {
	struct to_mut_arr__lambda0* temp0;
	return make_mut_arr_0(ctx, a.size, (struct fun_mut1_5) {(fun_ptr3_5) to_mut_arr__lambda0, (uint8_t*) (temp0 = (struct to_mut_arr__lambda0*) alloc(ctx, sizeof(struct to_mut_arr__lambda0)), ((*(temp0) = (struct to_mut_arr__lambda0) {a}, 0), temp0))});
}
struct arr_0 to_mut_arr__lambda0(struct ctx* ctx, struct to_mut_arr__lambda0* _closure, uint64_t i) {
	return at_2(ctx, _closure->a, i);
}
uint8_t sort_1(struct ctx* ctx, struct mut_arr_1* a) {
	return sort_2(ctx, to_mut_slice(ctx, a));
}
uint8_t sort_2(struct ctx* ctx, struct mut_slice* a) {
	struct arr_0 pivot0;
	uint64_t index_of_first_value_gt_pivot1;
	uint64_t new_pivot_index2;
	struct mut_slice* _tailCalla;
	top:
	if (_op_less_equal_0(a->size, 1)) {
		return 0;
	} else {
		swap_0(ctx, a, 0, _op_div(ctx, a->size, two_1()));
		pivot0 = at_7(ctx, a, 0);
		index_of_first_value_gt_pivot1 = partition_recur(ctx, a, pivot0, 1, decr(ctx, a->size));
		new_pivot_index2 = decr(ctx, index_of_first_value_gt_pivot1);
		swap_0(ctx, a, 0, new_pivot_index2);
		sort_2(ctx, slice_4(ctx, a, 0, new_pivot_index2));
		_tailCalla = slice_5(ctx, a, incr_1(ctx, new_pivot_index2));
		a = _tailCalla;
		goto top;
	}
}
uint8_t swap_0(struct ctx* ctx, struct mut_slice* a, uint64_t lo, uint64_t hi) {
	struct arr_0 old_lo0;
	old_lo0 = at_7(ctx, a, lo);
	set_at_3(ctx, a, lo, at_7(ctx, a, hi));
	return set_at_3(ctx, a, hi, old_lo0);
}
struct arr_0 at_7(struct ctx* ctx, struct mut_slice* a, uint64_t index) {
	assert_0(ctx, _op_less_0(index, a->size));
	return at_8(ctx, a->backing, _op_plus_0(ctx, a->begin, index));
}
struct arr_0 at_8(struct ctx* ctx, struct mut_arr_1* a, uint64_t index) {
	assert_0(ctx, _op_less_0(index, a->size));
	return noctx_at_9(a, index);
}
struct arr_0 noctx_at_9(struct mut_arr_1* a, uint64_t index) {
	hard_assert(_op_less_0(index, a->size));
	return (*((a->data + index)));
}
uint8_t set_at_3(struct ctx* ctx, struct mut_slice* a, uint64_t index, struct arr_0 value) {
	assert_0(ctx, _op_less_0(index, a->size));
	return set_at_0(ctx, a->backing, _op_plus_0(ctx, a->begin, index), value);
}
uint64_t partition_recur(struct ctx* ctx, struct mut_slice* a, struct arr_0 pivot, uint64_t l, uint64_t r) {
	struct arr_0 em0;
	struct mut_slice* _tailCalla;
	struct arr_0 _tailCallpivot;
	uint64_t _tailCalll;
	uint64_t _tailCallr;
	top:
	assert_0(ctx, _op_less_equal_0(l, a->size));
	assert_0(ctx, _op_less_0(r, a->size));
	if (_op_less_equal_0(l, r)) {
		em0 = at_7(ctx, a, l);
		if (_op_less_2(em0, pivot)) {
			_tailCalla = a;
			_tailCallpivot = pivot;
			_tailCalll = incr_1(ctx, l);
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
uint8_t _op_less_2(struct arr_0 a, struct arr_0 b) {
	struct comparison _matched0;
	_matched0 = compare_253(a, b);
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
struct mut_slice* slice_4(struct ctx* ctx, struct mut_slice* a, uint64_t lo, uint64_t size) {
	struct mut_slice* temp0;
	assert_0(ctx, _op_less_equal_0(_op_plus_0(ctx, lo, size), a->size));
	temp0 = (struct mut_slice*) alloc(ctx, sizeof(struct mut_slice));
	(*(temp0) = (struct mut_slice) {a->backing, size, _op_plus_0(ctx, a->begin, lo)}, 0);
	return temp0;
}
struct mut_slice* slice_5(struct ctx* ctx, struct mut_slice* a, uint64_t lo) {
	assert_0(ctx, _op_less_equal_0(lo, a->size));
	return slice_4(ctx, a, lo, _op_minus_1(ctx, a->size, lo));
}
struct mut_slice* to_mut_slice(struct ctx* ctx, struct mut_arr_1* a) {
	struct mut_slice* temp0;
	forbid_0(ctx, a->frozen__q);
	temp0 = (struct mut_slice*) alloc(ctx, sizeof(struct mut_slice));
	(*(temp0) = (struct mut_slice) {a, a->size, 0}, 0);
	return temp0;
}
uint8_t each_child_recursive__lambda0(struct ctx* ctx, struct each_child_recursive__lambda0* _closure, struct arr_0 child_name) {
	if (call_10(ctx, _closure->filter, child_name)) {
		return each_child_recursive(ctx, child_path(ctx, _closure->path, child_name), _closure->filter, _closure->f);
	} else {
		return 0;
	}
}
struct opt_11 get_extension(struct ctx* ctx, struct arr_0 name) {
	struct opt_10 _matched1;
	struct some_10 s0;
	_matched1 = last_index_of(ctx, name, literal_0((struct arr_0) {1, constantarr_0_43}));
	switch (_matched1.kind) {
		case 0:
			return (struct opt_11) {0, .as0 = (struct none) {0}};
		case 1:
			s0 = _matched1.as1;
			return (struct opt_11) {1, .as1 = (struct some_11) {slice_after_1(ctx, name, s0.value)}};
		default:
			return (assert(0),(struct opt_11) {0});
	}
}
struct opt_10 last_index_of(struct ctx* ctx, struct arr_0 s, char c) {
	struct arr_0 _tailCalls;
	char _tailCallc;
	top:
	if (empty__q_0(s)) {
		return (struct opt_10) {0, .as0 = (struct none) {0}};
	} else {
		if (_op_equal_equal_0(last(ctx, s), c)) {
			return (struct opt_10) {1, .as1 = (struct some_10) {decr(ctx, s.size)}};
		} else {
			_tailCalls = rtail(ctx, s);
			_tailCallc = c;
			s = _tailCalls;
			c = _tailCallc;
			goto top;
		}
	}
}
struct arr_0 slice_after_1(struct ctx* ctx, struct arr_0 a, uint64_t before_begin) {
	return slice_starting_at_1(ctx, a, incr_1(ctx, before_begin));
}
struct arr_0 base_name(struct ctx* ctx, struct arr_0 path) {
	struct opt_10 i0;
	struct opt_10 _matched2;
	struct some_10 s1;
	i0 = last_index_of(ctx, path, literal_0((struct arr_0) {1, constantarr_0_38}));
	_matched2 = i0;
	switch (_matched2.kind) {
		case 0:
			return path;
		case 1:
			s1 = _matched2.as1;
			return slice_after_1(ctx, path, s1.value);
		default:
			return (assert(0),(struct arr_0) {0, NULL});
	}
}
uint8_t list_tests__lambda1(struct ctx* ctx, struct list_tests__lambda1* _closure, struct arr_0 child) {
	struct opt_11 _matched1;
	struct some_11 s0;
	_matched1 = get_extension(ctx, base_name(ctx, child));
	switch (_matched1.kind) {
		case 0:
			return 0;
		case 1:
			s0 = _matched1.as1;
			if (_op_equal_equal_4(s0.value, (struct arr_0) {2, constantarr_0_45})) {
				return push_0(ctx, _closure->res, child);
			} else {
				return 0;
			}
		default:
			return (assert(0),0);
	}
}
struct arr_7 flat_map_with_max_size(struct ctx* ctx, struct arr_1 a, uint64_t max_size, struct fun_mut1_12 mapper) {
	struct mut_arr_5* res0;
	struct flat_map_with_max_size__lambda0* temp0;
	res0 = new_mut_arr_2(ctx);
	each_1(ctx, a, (struct fun_mut1_11) {(fun_ptr3_12) flat_map_with_max_size__lambda0, (uint8_t*) (temp0 = (struct flat_map_with_max_size__lambda0*) alloc(ctx, sizeof(struct flat_map_with_max_size__lambda0)), ((*(temp0) = (struct flat_map_with_max_size__lambda0) {res0, max_size, mapper}, 0), temp0))});
	return freeze_6(res0);
}
struct mut_arr_5* new_mut_arr_2(struct ctx* ctx) {
	struct mut_arr_5* temp0;
	temp0 = (struct mut_arr_5*) alloc(ctx, sizeof(struct mut_arr_5));
	(*(temp0) = (struct mut_arr_5) {0, 0, 0, NULL}, 0);
	return temp0;
}
uint8_t push_all(struct ctx* ctx, struct mut_arr_5* a, struct arr_7 values) {
	struct push_all__lambda0* temp0;
	return each_2(ctx, values, (struct fun_mut1_13) {(fun_ptr3_14) push_all__lambda0, (uint8_t*) (temp0 = (struct push_all__lambda0*) alloc(ctx, sizeof(struct push_all__lambda0)), ((*(temp0) = (struct push_all__lambda0) {a}, 0), temp0))});
}
uint8_t each_2(struct ctx* ctx, struct arr_7 a, struct fun_mut1_13 f) {
	struct arr_7 _tailCalla;
	struct fun_mut1_13 _tailCallf;
	top:
	if (empty__q_11(a)) {
		return 0;
	} else {
		call_19(ctx, f, first_3(ctx, a));
		_tailCalla = tail_4(ctx, a);
		_tailCallf = f;
		a = _tailCalla;
		f = _tailCallf;
		goto top;
	}
}
uint8_t empty__q_11(struct arr_7 a) {
	return zero__q_0(a.size);
}
uint8_t call_19(struct ctx* ctx, struct fun_mut1_13 f, struct failure* p0) {
	return call_with_ctx_18(ctx, f, p0);
}
uint8_t call_with_ctx_18(struct ctx* c, struct fun_mut1_13 f, struct failure* p0) {
	return f.fun_ptr(c, f.closure, p0);
}
struct failure* first_3(struct ctx* ctx, struct arr_7 a) {
	forbid_0(ctx, empty__q_11(a));
	return at_9(ctx, a, 0);
}
struct failure* at_9(struct ctx* ctx, struct arr_7 a, uint64_t index) {
	assert_0(ctx, _op_less_0(index, a.size));
	return noctx_at_10(a, index);
}
struct failure* noctx_at_10(struct arr_7 a, uint64_t index) {
	hard_assert(_op_less_0(index, a.size));
	return (*((a.data + index)));
}
struct arr_7 tail_4(struct ctx* ctx, struct arr_7 a) {
	forbid_0(ctx, empty__q_11(a));
	return slice_starting_at_4(ctx, a, 1);
}
struct arr_7 slice_starting_at_4(struct ctx* ctx, struct arr_7 a, uint64_t begin) {
	assert_0(ctx, _op_less_equal_0(begin, a.size));
	return slice_6(ctx, a, begin, _op_minus_1(ctx, a.size, begin));
}
struct arr_7 slice_6(struct ctx* ctx, struct arr_7 a, uint64_t begin, uint64_t size) {
	assert_0(ctx, _op_less_equal_0(_op_plus_0(ctx, begin, size), a.size));
	return (struct arr_7) {size, (a.data + begin)};
}
uint8_t push_2(struct ctx* ctx, struct mut_arr_5* a, struct failure* value) {
	if (_op_equal_equal_1(a->size, a->capacity)) {
		increase_capacity_to_2(ctx, a, (zero__q_0(a->size) ? four_0() : _op_times_0(ctx, a->size, two_1())));
	} else {
		0;
	}
	ensure_capacity_2(ctx, a, round_up_to_power_of_two(ctx, incr_1(ctx, a->size)));
	assert_0(ctx, _op_less_0(a->size, a->capacity));
	(*((a->data + a->size)) = value, 0);
	return (a->size = incr_1(ctx, a->size), 0);
}
uint8_t increase_capacity_to_2(struct ctx* ctx, struct mut_arr_5* a, uint64_t new_capacity) {
	struct failure** old_data0;
	assert_0(ctx, _op_greater_0(new_capacity, a->capacity));
	old_data0 = a->data;
	(a->capacity = new_capacity, 0);
	(a->data = uninitialized_data_4(ctx, new_capacity), 0);
	return copy_data_from_2(ctx, a->data, old_data0, a->size);
}
struct failure** uninitialized_data_4(struct ctx* ctx, uint64_t size) {
	uint8_t* bptr0;
	bptr0 = alloc(ctx, (size * sizeof(struct failure*)));
	return (struct failure**) bptr0;
}
uint8_t copy_data_from_2(struct ctx* ctx, struct failure** to, struct failure** from, uint64_t len) {
	uint64_t hl0;
	struct failure** _tailCallto;
	struct failure** _tailCallfrom;
	uint64_t _tailCalllen;
	top:
	if (_op_less_0(len, eight_0())) {
		return copy_data_from_small_2(ctx, to, from, len);
	} else {
		hl0 = _op_div(ctx, len, two_1());
		copy_data_from_2(ctx, to, from, hl0);
		_tailCallto = (to + hl0);
		_tailCallfrom = (from + hl0);
		_tailCalllen = _op_minus_1(ctx, len, hl0);
		to = _tailCallto;
		from = _tailCallfrom;
		len = _tailCalllen;
		goto top;
	}
}
uint8_t copy_data_from_small_2(struct ctx* ctx, struct failure** to, struct failure** from, uint64_t len) {
	if (zero__q_0(len)) {
		return 0;
	} else {
		(*(to) = (*(from)), 0);
		return copy_data_from_2(ctx, incr_5(to), incr_5(from), decr(ctx, len));
	}
}
struct failure** incr_5(struct failure** p) {
	return (p + 1);
}
uint8_t ensure_capacity_2(struct ctx* ctx, struct mut_arr_5* a, uint64_t capacity) {
	if (_op_less_0(a->capacity, capacity)) {
		return increase_capacity_to_2(ctx, a, round_up_to_power_of_two(ctx, capacity));
	} else {
		return 0;
	}
}
uint8_t push_all__lambda0(struct ctx* ctx, struct push_all__lambda0* _closure, struct failure* it) {
	return push_2(ctx, _closure->a, it);
}
struct arr_7 call_20(struct ctx* ctx, struct fun_mut1_12 f, struct arr_0 p0) {
	return call_with_ctx_19(ctx, f, p0);
}
struct arr_7 call_with_ctx_19(struct ctx* c, struct fun_mut1_12 f, struct arr_0 p0) {
	return f.fun_ptr(c, f.closure, p0);
}
uint8_t reduce_size_if_more_than(struct ctx* ctx, struct mut_arr_5* a, uint64_t new_size) {
	if (_op_less_0(new_size, a->size)) {
		return (a->size = new_size, 0);
	} else {
		return 0;
	}
}
uint8_t flat_map_with_max_size__lambda0(struct ctx* ctx, struct flat_map_with_max_size__lambda0* _closure, struct arr_0 x) {
	if (_op_less_0(_closure->res->size, _closure->max_size)) {
		push_all(ctx, _closure->res, call_20(ctx, _closure->mapper, x));
		return reduce_size_if_more_than(ctx, _closure->res, _closure->max_size);
	} else {
		return 0;
	}
}
struct arr_7 freeze_6(struct mut_arr_5* a) {
	(a->frozen__q = 1, 0);
	return unsafe_as_arr_4(a);
}
struct arr_7 unsafe_as_arr_4(struct mut_arr_5* a) {
	return (struct arr_7) {a->size, a->data};
}
struct arr_7 run_single_noze_test(struct ctx* ctx, struct arr_0 path_to_noze, struct dict_1* env, struct arr_0 path, struct test_options options) {
	struct opt_13 op0;
	struct run_single_noze_test__lambda0* temp0;
	struct opt_13 _matched3;
	struct arr_7 interpret_failures1;
	struct some_13 s2;
	op0 = first_some(ctx, (struct arr_1) {4, constantarr_1_1}, (struct fun_mut1_14) {(fun_ptr3_15) run_single_noze_test__lambda0, (uint8_t*) (temp0 = (struct run_single_noze_test__lambda0*) alloc(ctx, sizeof(struct run_single_noze_test__lambda0)), ((*(temp0) = (struct run_single_noze_test__lambda0) {options, path, path_to_noze, env}, 0), temp0))});
	_matched3 = op0;
	switch (_matched3.kind) {
		case 0:
			if (options.print_tests__q) {
				print_sync(_op_plus_1(ctx, (struct arr_0) {9, constantarr_0_70}, path));
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
			s2 = _matched3.as1;
			return s2.value;
		default:
			return (assert(0),(struct arr_7) {0, NULL});
	}
}
struct opt_13 first_some(struct ctx* ctx, struct arr_1 a, struct fun_mut1_14 cb) {
	struct opt_13 _matched1;
	struct some_13 s0;
	struct arr_1 _tailCalla;
	struct fun_mut1_14 _tailCallcb;
	top:
	if (empty__q_6(a)) {
		return (struct opt_13) {0, .as0 = (struct none) {0}};
	} else {
		_matched1 = call_21(ctx, cb, first_1(ctx, a));
		switch (_matched1.kind) {
			case 0:
				_tailCalla = tail_2(ctx, a);
				_tailCallcb = cb;
				a = _tailCalla;
				cb = _tailCallcb;
				goto top;
			case 1:
				s0 = _matched1.as1;
				return (struct opt_13) {1, .as1 = s0};
			default:
				return (assert(0),(struct opt_13) {0});
		}
	}
}
struct opt_13 call_21(struct ctx* ctx, struct fun_mut1_14 f, struct arr_0 p0) {
	return call_with_ctx_20(ctx, f, p0);
}
struct opt_13 call_with_ctx_20(struct ctx* c, struct fun_mut1_14 f, struct arr_0 p0) {
	return f.fun_ptr(c, f.closure, p0);
}
struct print_test_result* run_print_test(struct ctx* ctx, struct arr_0 print_kind, struct arr_0 path_to_noze, struct dict_1* env, struct arr_0 path, uint8_t overwrite_output__q) {
	struct process_result* res1;
	struct arr_0* temp0;
	struct arr_0 output_path2;
	struct arr_7 output_failures3;
	struct print_test_result* temp1;
	struct print_test_result* temp2;
	struct arr_0 stderr_no_color4;
	struct print_test_result* temp3;
	struct arr_0 message5;
	struct print_test_result* temp6;
	struct failure** temp4;
	struct failure* temp5;
	res1 = spawn_and_wait_result_0(ctx, path_to_noze, (temp0 = (struct arr_0*) alloc(ctx, (sizeof(struct arr_0) * 3)), ((*((temp0 + 0)) = (struct arr_0) {5, constantarr_0_56}, 0), ((*((temp0 + 1)) = print_kind, 0), ((*((temp0 + 2)) = path, 0), (struct arr_1) {3, temp0})))), env);
	output_path2 = _op_plus_1(ctx, _op_plus_1(ctx, _op_plus_1(ctx, path, (struct arr_0) {1, constantarr_0_43}), print_kind), (struct arr_0) {5, constantarr_0_57});
	output_failures3 = ((empty__q_0(res1->stdout) && _op_bang_equal(res1->exit_code, literal_2(ctx, (struct arr_0) {1, constantarr_0_21}))) ? empty_arr_3() : handle_output(ctx, path, output_path2, res1->stdout, overwrite_output__q));
	if (!empty__q_11(output_failures3)) {
		temp1 = (struct print_test_result*) alloc(ctx, sizeof(struct print_test_result));
		(*(temp1) = (struct print_test_result) {1, output_failures3}, 0);
		return temp1;
	} else {
		if (_op_equal_equal_3(res1->exit_code, literal_2(ctx, (struct arr_0) {1, constantarr_0_21}))) {
			assert_0(ctx, _op_equal_equal_4(res1->stderr, (struct arr_0) {0, NULL}));
			temp2 = (struct print_test_result*) alloc(ctx, sizeof(struct print_test_result));
			(*(temp2) = (struct print_test_result) {0, empty_arr_3()}, 0);
			return temp2;
		} else {
			if (_op_equal_equal_3(res1->exit_code, literal_2(ctx, (struct arr_0) {1, constantarr_0_22}))) {
				stderr_no_color4 = remove_colors(ctx, res1->stderr);
				temp3 = (struct print_test_result*) alloc(ctx, sizeof(struct print_test_result));
				(*(temp3) = (struct print_test_result) {1, handle_output(ctx, path, _op_plus_1(ctx, output_path2, (struct arr_0) {4, constantarr_0_68}), stderr_no_color4, overwrite_output__q)}, 0);
				return temp3;
			} else {
				message5 = _op_plus_1(ctx, (struct arr_0) {22, constantarr_0_69}, to_str_1(ctx, res1->exit_code));
				temp6 = (struct print_test_result*) alloc(ctx, sizeof(struct print_test_result));
				(*(temp6) = (struct print_test_result) {1, (temp4 = (struct failure**) alloc(ctx, (sizeof(struct failure*) * 1)), ((*((temp4 + 0)) = (temp5 = (struct failure*) alloc(ctx, sizeof(struct failure)), ((*(temp5) = (struct failure) {path, message5}, 0), temp5)), 0), (struct arr_7) {1, temp4}))}, 0);
				return temp6;
			}
		}
	}
}
struct process_result* spawn_and_wait_result_0(struct ctx* ctx, struct arr_0 exe, struct arr_1 args, struct dict_1* environ) {
	char* exe_c_str0;
	print_sync(fold(ctx, _op_plus_1(ctx, (struct arr_0) {23, constantarr_0_52}, exe), args, (struct fun_mut2_1) {(fun_ptr4_2) spawn_and_wait_result_0__lambda0, (uint8_t*) NULL}));
	if (is_file__q_0(ctx, exe)) {
		exe_c_str0 = to_c_str(ctx, exe);
		return spawn_and_wait_result_1(ctx, exe_c_str0, convert_args(ctx, exe_c_str0, args), convert_environ(ctx, environ));
	} else {
		return fail_2(ctx, _op_plus_1(ctx, exe, (struct arr_0) {14, constantarr_0_55}));
	}
}
struct arr_0 fold(struct ctx* ctx, struct arr_0 val, struct arr_1 a, struct fun_mut2_1 combine) {
	struct arr_0 _tailCallval;
	struct arr_1 _tailCalla;
	struct fun_mut2_1 _tailCallcombine;
	top:
	if (empty__q_6(a)) {
		return val;
	} else {
		_tailCallval = call_22(ctx, combine, val, first_1(ctx, a));
		_tailCalla = tail_2(ctx, a);
		_tailCallcombine = combine;
		val = _tailCallval;
		a = _tailCalla;
		combine = _tailCallcombine;
		goto top;
	}
}
struct arr_0 call_22(struct ctx* ctx, struct fun_mut2_1 f, struct arr_0 p0, struct arr_0 p1) {
	return call_with_ctx_21(ctx, f, p0, p1);
}
struct arr_0 call_with_ctx_21(struct ctx* c, struct fun_mut2_1 f, struct arr_0 p0, struct arr_0 p1) {
	return f.fun_ptr(c, f.closure, p0, p1);
}
struct arr_0 spawn_and_wait_result_0__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr_0 a, struct arr_0 b) {
	return _op_plus_1(ctx, _op_plus_1(ctx, a, (struct arr_0) {1, constantarr_0_51}), b);
}
uint8_t is_file__q_0(struct ctx* ctx, struct arr_0 path) {
	return is_file__q_1(ctx, to_c_str(ctx, path));
}
uint8_t is_file__q_1(struct ctx* ctx, char* path) {
	struct opt_12 _matched1;
	struct some_12 s0;
	_matched1 = get_stat(ctx, path);
	switch (_matched1.kind) {
		case 0:
			return 0;
		case 1:
			s0 = _matched1.as1;
			return _op_equal_equal_5((s0.value->st_mode & s_ifmt(ctx)), s_ifreg(ctx));
		default:
			return (assert(0),0);
	}
}
uint32_t s_ifreg(struct ctx* ctx) {
	return two_pow_0(fifteen());
}
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
struct pipes* make_pipes(struct ctx* ctx) {
	struct pipes* res0;
	struct pipes* temp0;
	res0 = (temp0 = (struct pipes*) alloc(ctx, sizeof(struct pipes)), ((*(temp0) = (struct pipes) {0, 0}, 0), temp0));
	check_posix_error(ctx, pipe(res0));
	return res0;
}
int32_t get_5(struct cell_4* c) {
	return c->value;
}
struct mut_arr_4* new_mut_arr_3(struct ctx* ctx) {
	struct mut_arr_4* temp0;
	temp0 = (struct mut_arr_4*) alloc(ctx, sizeof(struct mut_arr_4));
	(*(temp0) = (struct mut_arr_4) {0, 0, 0, NULL}, 0);
	return temp0;
}
uint8_t keep_polling(struct ctx* ctx, int32_t stdout_pipe, int32_t stderr_pipe, struct mut_arr_4* stdout_builder, struct mut_arr_4* stderr_builder) {
	struct arr_8 poll_fds1;
	struct pollfd* temp0;
	struct pollfd* stdout_pollfd2;
	struct pollfd* stderr_pollfd3;
	int32_t n_pollfds_with_events4;
	struct handle_revents_result a5;
	struct handle_revents_result b6;
	int32_t _tailCallstdout_pipe;
	int32_t _tailCallstderr_pipe;
	struct mut_arr_4* _tailCallstdout_builder;
	struct mut_arr_4* _tailCallstderr_builder;
	top:
	poll_fds1 = (temp0 = (struct pollfd*) alloc(ctx, (sizeof(struct pollfd) * 2)), ((*((temp0 + 0)) = (struct pollfd) {stdout_pipe, pollin(ctx), 0}, 0), ((*((temp0 + 1)) = (struct pollfd) {stderr_pipe, pollin(ctx), 0}, 0), (struct arr_8) {2, temp0})));
	stdout_pollfd2 = ref_of_val_at(ctx, poll_fds1, 0);
	stderr_pollfd3 = ref_of_val_at(ctx, poll_fds1, 1);
	n_pollfds_with_events4 = poll(poll_fds1.data, poll_fds1.size, neg_one_1());
	if (zero__q_1(n_pollfds_with_events4)) {
		return 0;
	} else {
		a5 = handle_revents(ctx, stdout_pollfd2, stdout_builder);
		b6 = handle_revents(ctx, stderr_pollfd3, stderr_builder);
		assert_0(ctx, _op_equal_equal_1(_op_plus_0(ctx, to_nat_1(ctx, any__q(ctx, a5)), to_nat_1(ctx, any__q(ctx, b6))), to_nat_2(ctx, n_pollfds_with_events4)));
		if ((a5.hung_up__q && b6.hung_up__q)) {
			return 0;
		} else {
			_tailCallstdout_pipe = stdout_pipe;
			_tailCallstderr_pipe = stderr_pipe;
			_tailCallstdout_builder = stdout_builder;
			_tailCallstderr_builder = stderr_builder;
			stdout_pipe = _tailCallstdout_pipe;
			stderr_pipe = _tailCallstderr_pipe;
			stdout_builder = _tailCallstdout_builder;
			stderr_builder = _tailCallstderr_builder;
			goto top;
		}
	}
}
int16_t pollin(struct ctx* ctx) {
	return two_pow_1(0);
}
int16_t two_pow_1(int16_t pow) {
	if (zero__q_3(pow)) {
		return 1;
	} else {
		return (two_pow_1(wrap_decr_2(pow)) * two_4());
	}
}
uint8_t zero__q_3(int16_t a) {
	return _op_equal_equal_6(a, 0);
}
uint8_t _op_equal_equal_6(int16_t a, int16_t b) {
	struct comparison _matched0;
	_matched0 = compare_547(a, b);
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
struct comparison compare_547(int16_t a, int16_t b) {
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
int16_t wrap_decr_2(int16_t a) {
	return (a - 1);
}
int16_t two_4() {
	return wrap_incr_4(1);
}
int16_t wrap_incr_4(int16_t a) {
	return (a + 1);
}
struct pollfd* ref_of_val_at(struct ctx* ctx, struct arr_8 a, uint64_t index) {
	assert_0(ctx, _op_less_0(index, a.size));
	return ref_of_ptr((a.data + index));
}
struct pollfd* ref_of_ptr(struct pollfd* p) {
	return (&((*(p))));
}
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
uint8_t has_pollin__q(struct ctx* ctx, int16_t revents) {
	return bits_intersect__q(revents, pollin(ctx));
}
uint8_t bits_intersect__q(int16_t a, int16_t b) {
	return !zero__q_3((a & b));
}
uint8_t read_to_buffer_until_eof(struct ctx* ctx, int32_t fd, struct mut_arr_4* buffer) {
	uint64_t read_max0;
	char* add_data_to1;
	int64_t n_bytes_read2;
	int32_t _tailCallfd;
	struct mut_arr_4* _tailCallbuffer;
	top:
	read_max0 = two_pow_2(ten_0());
	ensure_capacity_3(ctx, buffer, _op_plus_0(ctx, buffer->size, read_max0));
	add_data_to1 = (buffer->data + buffer->size);
	n_bytes_read2 = read(fd, (uint8_t*) add_data_to1, read_max0);
	if (_op_equal_equal_2(n_bytes_read2, neg_one_0())) {
		return todo_1();
	} else {
		if (_op_equal_equal_2(n_bytes_read2, 0)) {
			return 0;
		} else {
			assert_0(ctx, _op_less_equal_0(to_nat_0(ctx, n_bytes_read2), read_max0));
			unsafe_increase_size(ctx, buffer, to_nat_0(ctx, n_bytes_read2));
			_tailCallfd = fd;
			_tailCallbuffer = buffer;
			fd = _tailCallfd;
			buffer = _tailCallbuffer;
			goto top;
		}
	}
}
uint64_t two_pow_2(uint64_t pow) {
	if (zero__q_0(pow)) {
		return 1;
	} else {
		return (two_pow_2(wrap_decr_0(pow)) * two_1());
	}
}
uint8_t ensure_capacity_3(struct ctx* ctx, struct mut_arr_4* a, uint64_t capacity) {
	if (_op_less_0(a->capacity, capacity)) {
		return increase_capacity_to_3(ctx, a, round_up_to_power_of_two(ctx, capacity));
	} else {
		return 0;
	}
}
uint8_t increase_capacity_to_3(struct ctx* ctx, struct mut_arr_4* a, uint64_t new_capacity) {
	char* old_data0;
	assert_0(ctx, _op_greater_0(new_capacity, a->capacity));
	old_data0 = a->data;
	(a->capacity = new_capacity, 0);
	(a->data = uninitialized_data_3(ctx, new_capacity), 0);
	return copy_data_from_3(ctx, a->data, old_data0, a->size);
}
uint8_t copy_data_from_3(struct ctx* ctx, char* to, char* from, uint64_t len) {
	uint64_t hl0;
	char* _tailCallto;
	char* _tailCallfrom;
	uint64_t _tailCalllen;
	top:
	if (_op_less_0(len, eight_0())) {
		return copy_data_from_small_3(ctx, to, from, len);
	} else {
		hl0 = _op_div(ctx, len, two_1());
		copy_data_from_3(ctx, to, from, hl0);
		_tailCallto = (to + hl0);
		_tailCallfrom = (from + hl0);
		_tailCalllen = _op_minus_1(ctx, len, hl0);
		to = _tailCallto;
		from = _tailCallfrom;
		len = _tailCalllen;
		goto top;
	}
}
uint8_t copy_data_from_small_3(struct ctx* ctx, char* to, char* from, uint64_t len) {
	if (zero__q_0(len)) {
		return 0;
	} else {
		(*(to) = (*(from)), 0);
		return copy_data_from_3(ctx, incr_0(to), incr_0(from), decr(ctx, len));
	}
}
uint8_t unsafe_increase_size(struct ctx* ctx, struct mut_arr_4* a, uint64_t increase_by) {
	return unsafe_set_size(ctx, a, _op_plus_0(ctx, a->size, increase_by));
}
uint8_t unsafe_set_size(struct ctx* ctx, struct mut_arr_4* a, uint64_t new_size) {
	assert_0(ctx, _op_less_equal_0(new_size, a->capacity));
	return (a->size = new_size, 0);
}
uint8_t has_pollhup__q(struct ctx* ctx, int16_t revents) {
	return bits_intersect__q(revents, pollhup(ctx));
}
int16_t pollhup(struct ctx* ctx) {
	return two_pow_1(four_4());
}
int16_t four_4() {
	return wrap_incr_4(three_4());
}
int16_t three_4() {
	return wrap_incr_4(two_4());
}
uint8_t has_pollpri__q(struct ctx* ctx, int16_t revents) {
	return bits_intersect__q(revents, pollpri(ctx));
}
int16_t pollpri(struct ctx* ctx) {
	return two_pow_1(1);
}
uint8_t has_pollout__q(struct ctx* ctx, int16_t revents) {
	return bits_intersect__q(revents, pollout(ctx));
}
int16_t pollout(struct ctx* ctx) {
	return two_pow_1(two_4());
}
uint8_t has_pollerr__q(struct ctx* ctx, int16_t revents) {
	return bits_intersect__q(revents, pollerr(ctx));
}
int16_t pollerr(struct ctx* ctx) {
	return two_pow_1(three_4());
}
uint8_t has_pollnval__q(struct ctx* ctx, int16_t revents) {
	return bits_intersect__q(revents, pollnval(ctx));
}
int16_t pollnval(struct ctx* ctx) {
	return two_pow_1(five_4());
}
int16_t five_4() {
	return wrap_incr_4(four_4());
}
uint64_t to_nat_1(struct ctx* ctx, uint8_t b) {
	if (b) {
		return 1;
	} else {
		return 0;
	}
}
uint8_t any__q(struct ctx* ctx, struct handle_revents_result r) {
	return (r.had_pollin__q || r.hung_up__q);
}
uint64_t to_nat_2(struct ctx* ctx, int32_t i) {
	return to_nat_0(ctx, i);
}
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
			print_sync(_op_plus_1(ctx, (struct arr_0) {31, constantarr_0_53}, to_str_1(ctx, signal3)));
			return todo_6();
		} else {
			if (w_if_stopped(ctx, wait_status2)) {
				print_sync((struct arr_0) {12, constantarr_0_54});
				return todo_6();
			} else {
				if (w_if_continued(ctx, wait_status2)) {
					return todo_6();
				} else {
					return todo_6();
				}
			}
		}
	}
}
uint8_t w_if_exited(struct ctx* ctx, int32_t status) {
	return zero__q_1(w_term_sig(ctx, status));
}
int32_t w_term_sig(struct ctx* ctx, int32_t status) {
	return (status & x7f());
}
int32_t x7f() {
	return noctx_decr_1(two_pow_3(seven_1()));
}
int32_t noctx_decr_1(int32_t a) {
	return (a - 1);
}
int32_t two_pow_3(int32_t pow) {
	if (zero__q_1(pow)) {
		return 1;
	} else {
		return (two_pow_3(wrap_decr_3(pow)) * two_0());
	}
}
int32_t wrap_decr_3(int32_t a) {
	return (a - 1);
}
int32_t w_exit_status(struct ctx* ctx, int32_t status) {
	return bit_shift_right((status & xff00()), eight_3());
}
int32_t bit_shift_right(int32_t a, int32_t b) {
	if (_op_less_3(a, 0)) {
		return todo_6();
	} else {
		if (_op_less_3(b, 0)) {
			return todo_6();
		} else {
			if (_op_less_3(b, thirty_two_0())) {
				return (a >> b);
			} else {
				return todo_6();
			}
		}
	}
}
uint8_t _op_less_3(int32_t a, int32_t b) {
	struct comparison _matched0;
	_matched0 = compare_72(a, b);
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
int32_t todo_6() {
	return (assert(0),0);
}
int32_t thirty_two_0() {
	return (sixteen_0() + sixteen_0());
}
int32_t sixteen_0() {
	return (ten_1() + six_1());
}
int32_t xff00() {
	return (xffff() - xff());
}
int32_t xffff() {
	return noctx_decr_1(two_pow_3(sixteen_0()));
}
int32_t xff() {
	return noctx_decr_1(two_pow_3(eight_3()));
}
int32_t eight_3() {
	return (four_1() + four_1());
}
uint8_t w_if_signaled(struct ctx* ctx, int32_t status) {
	int32_t ts0;
	ts0 = w_term_sig(ctx, status);
	return (_op_bang_equal(ts0, 0) && _op_bang_equal(ts0, x7f()));
}
uint8_t _op_bang_equal(int32_t a, int32_t b) {
	return !_op_equal_equal_3(a, b);
}
struct arr_0 to_str_1(struct ctx* ctx, int32_t i) {
	return to_str_2(ctx, i);
}
struct arr_0 to_str_2(struct ctx* ctx, int64_t i) {
	struct arr_0 a0;
	a0 = to_str_3(ctx, abs(ctx, i));
	if (negative__q(ctx, i)) {
		return _op_plus_1(ctx, (struct arr_0) {1, constantarr_0_36}, a0);
	} else {
		return a0;
	}
}
struct arr_0 to_str_3(struct ctx* ctx, uint64_t n) {
	struct arr_0 hi0;
	struct arr_0 lo1;
	if (_op_equal_equal_1(n, literal_1(ctx, (struct arr_0) {1, constantarr_0_21}))) {
		return (struct arr_0) {1, constantarr_0_21};
	} else {
		if (_op_equal_equal_1(n, literal_1(ctx, (struct arr_0) {1, constantarr_0_22}))) {
			return (struct arr_0) {1, constantarr_0_22};
		} else {
			if (_op_equal_equal_1(n, literal_1(ctx, (struct arr_0) {1, constantarr_0_23}))) {
				return (struct arr_0) {1, constantarr_0_23};
			} else {
				if (_op_equal_equal_1(n, literal_1(ctx, (struct arr_0) {1, constantarr_0_24}))) {
					return (struct arr_0) {1, constantarr_0_24};
				} else {
					if (_op_equal_equal_1(n, literal_1(ctx, (struct arr_0) {1, constantarr_0_25}))) {
						return (struct arr_0) {1, constantarr_0_25};
					} else {
						if (_op_equal_equal_1(n, literal_1(ctx, (struct arr_0) {1, constantarr_0_26}))) {
							return (struct arr_0) {1, constantarr_0_26};
						} else {
							if (_op_equal_equal_1(n, literal_1(ctx, (struct arr_0) {1, constantarr_0_27}))) {
								return (struct arr_0) {1, constantarr_0_27};
							} else {
								if (_op_equal_equal_1(n, literal_1(ctx, (struct arr_0) {1, constantarr_0_28}))) {
									return (struct arr_0) {1, constantarr_0_28};
								} else {
									if (_op_equal_equal_1(n, literal_1(ctx, (struct arr_0) {1, constantarr_0_29}))) {
										return (struct arr_0) {1, constantarr_0_29};
									} else {
										if (_op_equal_equal_1(n, literal_1(ctx, (struct arr_0) {1, constantarr_0_30}))) {
											return (struct arr_0) {1, constantarr_0_30};
										} else {
											hi0 = to_str_3(ctx, _op_div(ctx, n, ten_0()));
											lo1 = to_str_3(ctx, mod(ctx, n, ten_0()));
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
uint64_t mod(struct ctx* ctx, uint64_t a, uint64_t b) {
	forbid_0(ctx, zero__q_0(b));
	return (a % b);
}
uint64_t abs(struct ctx* ctx, int64_t i) {
	int64_t i_abs0;
	i_abs0 = (negative__q(ctx, i) ? neg_1(ctx, i) : i);
	return to_nat_0(ctx, i_abs0);
}
uint8_t w_if_stopped(struct ctx* ctx, int32_t status) {
	return _op_equal_equal_3((status & xff()), x7f());
}
uint8_t w_if_continued(struct ctx* ctx, int32_t status) {
	return _op_equal_equal_3(status, xffff());
}
char** convert_args(struct ctx* ctx, char* exe_c_str, struct arr_1 args) {
	return prepend(ctx, exe_c_str, append(ctx, map_1(ctx, args, (struct fun_mut1_16) {(fun_ptr3_17) convert_args__lambda0, (uint8_t*) NULL}), NULL)).data;
}
struct arr_3 prepend(struct ctx* ctx, char* a, struct arr_3 b) {
	char** temp0;
	return _op_plus_2(ctx, (temp0 = (char**) alloc(ctx, (sizeof(char*) * 1)), ((*((temp0 + 0)) = a, 0), (struct arr_3) {1, temp0})), b);
}
struct arr_3 _op_plus_2(struct ctx* ctx, struct arr_3 a, struct arr_3 b) {
	struct _op_plus_2__lambda0* temp0;
	return make_arr_2(ctx, _op_plus_0(ctx, a.size, b.size), (struct fun_mut1_15) {(fun_ptr3_16) _op_plus_2__lambda0, (uint8_t*) (temp0 = (struct _op_plus_2__lambda0*) alloc(ctx, sizeof(struct _op_plus_2__lambda0)), ((*(temp0) = (struct _op_plus_2__lambda0) {a, b}, 0), temp0))});
}
struct arr_3 make_arr_2(struct ctx* ctx, uint64_t size, struct fun_mut1_15 f) {
	return freeze_7(make_mut_arr_3(ctx, size, f));
}
struct arr_3 freeze_7(struct mut_arr_6* a) {
	(a->frozen__q = 1, 0);
	return unsafe_as_arr_5(a);
}
struct arr_3 unsafe_as_arr_5(struct mut_arr_6* a) {
	return (struct arr_3) {a->size, a->data};
}
struct mut_arr_6* make_mut_arr_3(struct ctx* ctx, uint64_t size, struct fun_mut1_15 f) {
	struct mut_arr_6* res0;
	res0 = new_uninitialized_mut_arr_3(ctx, size);
	make_mut_arr_worker_3(ctx, res0, 0, f);
	return res0;
}
struct mut_arr_6* new_uninitialized_mut_arr_3(struct ctx* ctx, uint64_t size) {
	struct mut_arr_6* temp0;
	temp0 = (struct mut_arr_6*) alloc(ctx, sizeof(struct mut_arr_6));
	(*(temp0) = (struct mut_arr_6) {0, size, size, uninitialized_data_5(ctx, size)}, 0);
	return temp0;
}
char** uninitialized_data_5(struct ctx* ctx, uint64_t size) {
	uint8_t* bptr0;
	bptr0 = alloc(ctx, (size * sizeof(char*)));
	return (char**) bptr0;
}
uint8_t make_mut_arr_worker_3(struct ctx* ctx, struct mut_arr_6* m, uint64_t i, struct fun_mut1_15 f) {
	struct mut_arr_6* _tailCallm;
	uint64_t _tailCalli;
	struct fun_mut1_15 _tailCallf;
	top:
	if (_op_equal_equal_1(i, m->size)) {
		return 0;
	} else {
		set_at_4(ctx, m, i, call_23(ctx, f, i));
		_tailCallm = m;
		_tailCalli = incr_1(ctx, i);
		_tailCallf = f;
		m = _tailCallm;
		i = _tailCalli;
		f = _tailCallf;
		goto top;
	}
}
uint8_t set_at_4(struct ctx* ctx, struct mut_arr_6* a, uint64_t index, char* value) {
	assert_0(ctx, _op_less_0(index, a->size));
	return noctx_set_at_4(a, index, value);
}
uint8_t noctx_set_at_4(struct mut_arr_6* a, uint64_t index, char* value) {
	hard_assert(_op_less_0(index, a->size));
	return (*((a->data + index)) = value, 0);
}
char* call_23(struct ctx* ctx, struct fun_mut1_15 f, uint64_t p0) {
	return call_with_ctx_22(ctx, f, p0);
}
char* call_with_ctx_22(struct ctx* c, struct fun_mut1_15 f, uint64_t p0) {
	return f.fun_ptr(c, f.closure, p0);
}
char* _op_plus_2__lambda0(struct ctx* ctx, struct _op_plus_2__lambda0* _closure, uint64_t i) {
	if (_op_less_0(i, _closure->a.size)) {
		return at_1(ctx, _closure->a, i);
	} else {
		return at_1(ctx, _closure->b, _op_minus_1(ctx, i, _closure->a.size));
	}
}
struct arr_3 append(struct ctx* ctx, struct arr_3 a, char* b) {
	char** temp0;
	return _op_plus_2(ctx, a, (temp0 = (char**) alloc(ctx, (sizeof(char*) * 1)), ((*((temp0 + 0)) = b, 0), (struct arr_3) {1, temp0})));
}
struct arr_3 map_1(struct ctx* ctx, struct arr_1 a, struct fun_mut1_16 mapper) {
	struct map_1__lambda0* temp0;
	return make_arr_2(ctx, a.size, (struct fun_mut1_15) {(fun_ptr3_16) map_1__lambda0, (uint8_t*) (temp0 = (struct map_1__lambda0*) alloc(ctx, sizeof(struct map_1__lambda0)), ((*(temp0) = (struct map_1__lambda0) {mapper, a}, 0), temp0))});
}
char* call_24(struct ctx* ctx, struct fun_mut1_16 f, struct arr_0 p0) {
	return call_with_ctx_23(ctx, f, p0);
}
char* call_with_ctx_23(struct ctx* c, struct fun_mut1_16 f, struct arr_0 p0) {
	return f.fun_ptr(c, f.closure, p0);
}
char* map_1__lambda0(struct ctx* ctx, struct map_1__lambda0* _closure, uint64_t i) {
	return call_24(ctx, _closure->mapper, at_2(ctx, _closure->a, i));
}
char* convert_args__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr_0 it) {
	return to_c_str(ctx, it);
}
char** convert_environ(struct ctx* ctx, struct dict_1* environ) {
	struct mut_arr_6* res0;
	struct convert_environ__lambda0* temp0;
	res0 = new_mut_arr_4(ctx);
	each_3(ctx, environ, (struct fun_mut2_2) {(fun_ptr4_3) convert_environ__lambda0, (uint8_t*) (temp0 = (struct convert_environ__lambda0*) alloc(ctx, sizeof(struct convert_environ__lambda0)), ((*(temp0) = (struct convert_environ__lambda0) {res0}, 0), temp0))});
	push_3(ctx, res0, NULL);
	return freeze_7(res0).data;
}
struct mut_arr_6* new_mut_arr_4(struct ctx* ctx) {
	struct mut_arr_6* temp0;
	temp0 = (struct mut_arr_6*) alloc(ctx, sizeof(struct mut_arr_6));
	(*(temp0) = (struct mut_arr_6) {0, 0, 0, NULL}, 0);
	return temp0;
}
uint8_t each_3(struct ctx* ctx, struct dict_1* d, struct fun_mut2_2 f) {
	struct dict_1* temp0;
	struct dict_1* _tailCalld;
	struct fun_mut2_2 _tailCallf;
	top:
	if (empty__q_12(ctx, d)) {
		return 0;
	} else {
		call_25(ctx, f, first_1(ctx, d->keys), first_1(ctx, d->values));
		_tailCalld = (temp0 = (struct dict_1*) alloc(ctx, sizeof(struct dict_1)), ((*(temp0) = (struct dict_1) {tail_2(ctx, d->keys), tail_2(ctx, d->values)}, 0), temp0));
		_tailCallf = f;
		d = _tailCalld;
		f = _tailCallf;
		goto top;
	}
}
uint8_t empty__q_12(struct ctx* ctx, struct dict_1* d) {
	return empty__q_6(d->keys);
}
uint8_t call_25(struct ctx* ctx, struct fun_mut2_2 f, struct arr_0 p0, struct arr_0 p1) {
	return call_with_ctx_24(ctx, f, p0, p1);
}
uint8_t call_with_ctx_24(struct ctx* c, struct fun_mut2_2 f, struct arr_0 p0, struct arr_0 p1) {
	return f.fun_ptr(c, f.closure, p0, p1);
}
uint8_t push_3(struct ctx* ctx, struct mut_arr_6* a, char* value) {
	if (_op_equal_equal_1(a->size, a->capacity)) {
		increase_capacity_to_4(ctx, a, (zero__q_0(a->size) ? four_0() : _op_times_0(ctx, a->size, two_1())));
	} else {
		0;
	}
	ensure_capacity_4(ctx, a, round_up_to_power_of_two(ctx, incr_1(ctx, a->size)));
	assert_0(ctx, _op_less_0(a->size, a->capacity));
	(*((a->data + a->size)) = value, 0);
	return (a->size = incr_1(ctx, a->size), 0);
}
uint8_t increase_capacity_to_4(struct ctx* ctx, struct mut_arr_6* a, uint64_t new_capacity) {
	char** old_data0;
	assert_0(ctx, _op_greater_0(new_capacity, a->capacity));
	old_data0 = a->data;
	(a->capacity = new_capacity, 0);
	(a->data = uninitialized_data_5(ctx, new_capacity), 0);
	return copy_data_from_4(ctx, a->data, old_data0, a->size);
}
uint8_t copy_data_from_4(struct ctx* ctx, char** to, char** from, uint64_t len) {
	uint64_t hl0;
	char** _tailCallto;
	char** _tailCallfrom;
	uint64_t _tailCalllen;
	top:
	if (_op_less_0(len, eight_0())) {
		return copy_data_from_small_4(ctx, to, from, len);
	} else {
		hl0 = _op_div(ctx, len, two_1());
		copy_data_from_4(ctx, to, from, hl0);
		_tailCallto = (to + hl0);
		_tailCallfrom = (from + hl0);
		_tailCalllen = _op_minus_1(ctx, len, hl0);
		to = _tailCallto;
		from = _tailCallfrom;
		len = _tailCalllen;
		goto top;
	}
}
uint8_t copy_data_from_small_4(struct ctx* ctx, char** to, char** from, uint64_t len) {
	if (zero__q_0(len)) {
		return 0;
	} else {
		(*(to) = (*(from)), 0);
		return copy_data_from_4(ctx, incr_4(to), incr_4(from), decr(ctx, len));
	}
}
uint8_t ensure_capacity_4(struct ctx* ctx, struct mut_arr_6* a, uint64_t capacity) {
	if (_op_less_0(a->capacity, capacity)) {
		return increase_capacity_to_4(ctx, a, round_up_to_power_of_two(ctx, capacity));
	} else {
		return 0;
	}
}
uint8_t convert_environ__lambda0(struct ctx* ctx, struct convert_environ__lambda0* _closure, struct arr_0 key, struct arr_0 value) {
	return push_3(ctx, _closure->res, to_c_str(ctx, _op_plus_1(ctx, _op_plus_1(ctx, key, (struct arr_0) {1, constantarr_0_42}), value)));
}
struct process_result* fail_2(struct ctx* ctx, struct arr_0 reason) {
	return throw_2(ctx, (struct exception) {reason});
}
struct process_result* throw_2(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx0;
	exn_ctx0 = get_exception_ctx(ctx);
	hard_forbid(null__q_1(exn_ctx0->jmp_buf_ptr));
	(exn_ctx0->thrown_exception = e, 0);
	(longjmp(exn_ctx0->jmp_buf_ptr, number_to_throw(ctx)), 0);
	return todo_7();
}
struct process_result* todo_7() {
	return (assert(0),NULL);
}
struct arr_7 empty_arr_3() {
	return (struct arr_7) {0, NULL};
}
struct arr_7 handle_output(struct ctx* ctx, struct arr_0 original_path, struct arr_0 output_path, struct arr_0 actual, uint8_t overwrite_output__q) {
	struct opt_11 _matched4;
	struct failure** temp0;
	struct failure* temp1;
	struct some_11 s1;
	struct arr_0 message2;
	struct failure** temp2;
	struct failure* temp3;
	_matched4 = try_read_file_0(ctx, output_path);
	switch (_matched4.kind) {
		case 0:
			if (overwrite_output__q) {
				write_file_0(ctx, output_path, actual);
				return empty_arr_3();
			} else {
				temp0 = (struct failure**) alloc(ctx, (sizeof(struct failure*) * 1));
				(*((temp0 + 0)) = (temp1 = (struct failure*) alloc(ctx, sizeof(struct failure)), ((*(temp1) = (struct failure) {original_path, _op_plus_1(ctx, _op_plus_1(ctx, base_name(ctx, output_path), (struct arr_0) {29, constantarr_0_64}), actual)}, 0), temp1)), 0);
				return (struct arr_7) {1, temp0};
			}
		case 1:
			s1 = _matched4.as1;
			if (_op_equal_equal_4(s1.value, actual)) {
				return empty_arr_3();
			} else {
				if (overwrite_output__q) {
					write_file_0(ctx, output_path, actual);
					return empty_arr_3();
				} else {
					message2 = _op_plus_1(ctx, _op_plus_1(ctx, base_name(ctx, output_path), (struct arr_0) {30, constantarr_0_65}), actual);
					temp2 = (struct failure**) alloc(ctx, (sizeof(struct failure*) * 1));
					(*((temp2 + 0)) = (temp3 = (struct failure*) alloc(ctx, sizeof(struct failure)), ((*(temp3) = (struct failure) {original_path, message2}, 0), temp3)), 0);
					return (struct arr_7) {1, temp2};
				}
			}
		default:
			return (assert(0),(struct arr_7) {0, NULL});
	}
}
struct opt_11 try_read_file_0(struct ctx* ctx, struct arr_0 path) {
	return try_read_file_1(ctx, to_c_str(ctx, path));
}
struct opt_11 try_read_file_1(struct ctx* ctx, char* path) {
	int32_t fd0;
	int64_t file_size1;
	int64_t off2;
	uint64_t file_size_nat3;
	struct mut_arr_4* res4;
	int64_t n_bytes_read5;
	if (is_file__q_1(ctx, path)) {
		fd0 = open(path, o_rdonly(ctx), literal_4(ctx, (struct arr_0) {1, constantarr_0_21}));
		if (_op_equal_equal_3(fd0, neg_one_1())) {
			if (_op_equal_equal_3(errno, enoent())) {
				return (struct opt_11) {0, .as0 = (struct none) {0}};
			} else {
				print_sync(_op_plus_1(ctx, (struct arr_0) {20, constantarr_0_58}, to_str_0(path)));
				return todo_8();
			}
		} else {
			file_size1 = lseek(fd0, 0, seek_end(ctx));
			forbid_0(ctx, _op_equal_equal_2(file_size1, neg_one_0()));
			assert_0(ctx, _op_less_1(file_size1, billion_1()));
			forbid_0(ctx, zero__q_4(file_size1));
			off2 = lseek(fd0, 0, seek_set(ctx));
			assert_0(ctx, _op_equal_equal_2(off2, 0));
			file_size_nat3 = to_nat_0(ctx, file_size1);
			res4 = new_uninitialized_mut_arr_2(ctx, file_size_nat3);
			n_bytes_read5 = read(fd0, (uint8_t*) res4->data, file_size_nat3);
			forbid_0(ctx, _op_equal_equal_2(n_bytes_read5, neg_one_0()));
			assert_0(ctx, _op_equal_equal_2(n_bytes_read5, file_size1));
			check_posix_error(ctx, close(fd0));
			return (struct opt_11) {1, .as1 = (struct some_11) {freeze_3(res4)}};
		}
	} else {
		return (struct opt_11) {0, .as0 = (struct none) {0}};
	}
}
uint32_t o_rdonly(struct ctx* ctx) {
	return 0;
}
uint32_t literal_4(struct ctx* ctx, struct arr_0 s) {
	return literal_1(ctx, s);
}
struct opt_11 todo_8() {
	return (assert(0),(struct opt_11) {0});
}
int32_t seek_end(struct ctx* ctx) {
	return two_0();
}
int64_t billion_1() {
	return (million_1() * thousand_1());
}
uint8_t zero__q_4(int64_t i) {
	return _op_equal_equal_2(i, 0);
}
int32_t seek_set(struct ctx* ctx) {
	return 0;
}
uint8_t write_file_0(struct ctx* ctx, struct arr_0 path, struct arr_0 content) {
	return write_file_1(ctx, to_c_str(ctx, path), content);
}
uint8_t write_file_1(struct ctx* ctx, char* path, struct arr_0 content) {
	uint32_t permission_rdwr0;
	uint32_t permission_rd1;
	uint32_t permission2;
	uint32_t flags3;
	int32_t fd4;
	int64_t wrote_bytes5;
	int32_t err6;
	permission_rdwr0 = six_3();
	permission_rd1 = four_3();
	permission2 = ((bit_shift_left(permission_rdwr0, six_3()) | bit_shift_left(permission_rd1, three_3())) | permission_rd1);
	flags3 = ((o_creat(ctx) | o_wronly(ctx)) | o_trunc(ctx));
	fd4 = open(path, flags3, permission2);
	if (_op_equal_equal_3(fd4, neg_one_1())) {
		print_sync(_op_plus_1(ctx, (struct arr_0) {31, constantarr_0_59}, to_str_0(path)));
		print_sync(_op_plus_1(ctx, (struct arr_0) {7, constantarr_0_60}, to_str_1(ctx, errno)));
		print_sync(_op_plus_1(ctx, (struct arr_0) {7, constantarr_0_61}, to_str_4(ctx, flags3)));
		print_sync(_op_plus_1(ctx, (struct arr_0) {12, constantarr_0_62}, to_str_4(ctx, permission2)));
		return todo_1();
	} else {
		wrote_bytes5 = write(fd4, (uint8_t*) content.data, content.size);
		if (_op_equal_equal_2(wrote_bytes5, to_int(ctx, content.size))) {
			0;
		} else {
			if (_op_equal_equal_2(wrote_bytes5, literal_3(ctx, (struct arr_0) {2, constantarr_0_63}))) {
				todo_1();
			} else {
				todo_1();
			}
		}
		err6 = close(fd4);
		if (_op_equal_equal_3(err6, 0)) {
			return 0;
		} else {
			return todo_1();
		}
	}
}
uint32_t bit_shift_left(uint32_t a, uint32_t b) {
	if (_op_less_4(b, thirty_two_1())) {
		return (a << b);
	} else {
		return 0;
	}
}
uint8_t _op_less_4(uint32_t a, uint32_t b) {
	struct comparison _matched0;
	_matched0 = compare_442(a, b);
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
uint32_t thirty_two_1() {
	return (sixteen_1() + sixteen_1());
}
uint32_t sixteen_1() {
	return wrap_incr_3(fifteen());
}
uint32_t o_creat(struct ctx* ctx) {
	return bit_shift_left(1, six_3());
}
uint32_t o_wronly(struct ctx* ctx) {
	return 1;
}
uint32_t o_trunc(struct ctx* ctx) {
	return bit_shift_left(1, nine_2());
}
uint32_t nine_2() {
	return wrap_incr_3(eight_2());
}
struct arr_0 to_str_4(struct ctx* ctx, uint32_t n) {
	return to_str_3(ctx, n);
}
struct arr_0 remove_colors(struct ctx* ctx, struct arr_0 s) {
	struct mut_arr_4* out0;
	out0 = new_mut_arr_3(ctx);
	remove_colors_recur(ctx, s, out0);
	return freeze_3(out0);
}
uint8_t remove_colors_recur(struct ctx* ctx, struct arr_0 s, struct mut_arr_4* out) {
	struct arr_0 _tailCalls;
	struct mut_arr_4* _tailCallout;
	top:
	if (empty__q_0(s)) {
		return 0;
	} else {
		if (_op_equal_equal_0(first_0(ctx, s), literal_0((struct arr_0) {1, constantarr_0_66}))) {
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
uint8_t remove_colors_recur_2(struct ctx* ctx, struct arr_0 s, struct mut_arr_4* out) {
	struct arr_0 _tailCalls;
	struct mut_arr_4* _tailCallout;
	top:
	if (empty__q_0(s)) {
		return 0;
	} else {
		if (_op_equal_equal_0(first_0(ctx, s), literal_0((struct arr_0) {1, constantarr_0_67}))) {
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
uint8_t push_4(struct ctx* ctx, struct mut_arr_4* a, char value) {
	if (_op_equal_equal_1(a->size, a->capacity)) {
		increase_capacity_to_3(ctx, a, (zero__q_0(a->size) ? four_0() : _op_times_0(ctx, a->size, two_1())));
	} else {
		0;
	}
	ensure_capacity_3(ctx, a, round_up_to_power_of_two(ctx, incr_1(ctx, a->size)));
	assert_0(ctx, _op_less_0(a->size, a->capacity));
	(*((a->data + a->size)) = value, 0);
	return (a->size = incr_1(ctx, a->size), 0);
}
struct opt_13 run_single_noze_test__lambda0(struct ctx* ctx, struct run_single_noze_test__lambda0* _closure, struct arr_0 print_kind) {
	struct print_test_result* res0;
	if (_closure->options.print_tests__q) {
		print_sync(_op_plus_1(ctx, _op_plus_1(ctx, _op_plus_1(ctx, (struct arr_0) {11, constantarr_0_50}, print_kind), (struct arr_0) {1, constantarr_0_51}), _closure->path));
	} else {
		0;
	}
	res0 = run_print_test(ctx, print_kind, _closure->path_to_noze, _closure->env, _closure->path, _closure->options.overwrite_output__q);
	if (res0->should_stop__q) {
		return (struct opt_13) {1, .as1 = (struct some_13) {res0->failures}};
	} else {
		return (struct opt_13) {0, .as0 = (struct none) {0}};
	}
}
struct arr_7 run_single_runnable_test(struct ctx* ctx, struct arr_0 path_to_noze, struct dict_1* env, struct arr_0 path, uint8_t interpret__q, uint8_t overwrite_output__q) {
	struct arr_1 args2;
	struct arr_0* temp0;
	struct arr_0* temp1;
	struct process_result* res3;
	struct arr_0 message4;
	struct failure** temp2;
	struct failure* temp3;
	args2 = (interpret__q ? (temp0 = (struct arr_0*) alloc(ctx, (sizeof(struct arr_0) * 3)), ((*((temp0 + 0)) = (struct arr_0) {3, constantarr_0_71}, 0), ((*((temp0 + 1)) = path, 0), ((*((temp0 + 2)) = (struct arr_0) {11, constantarr_0_72}, 0), (struct arr_1) {3, temp0})))) : (temp1 = (struct arr_0*) alloc(ctx, (sizeof(struct arr_0) * 2)), ((*((temp1 + 0)) = (struct arr_0) {3, constantarr_0_71}, 0), ((*((temp1 + 1)) = path, 0), (struct arr_1) {2, temp1}))));
	res3 = spawn_and_wait_result_0(ctx, path_to_noze, args2, env);
	if ((_op_equal_equal_3(res3->exit_code, literal_2(ctx, (struct arr_0) {1, constantarr_0_21})) && _op_equal_equal_4(res3->stderr, (struct arr_0) {0, NULL}))) {
		return handle_output(ctx, path, _op_plus_1(ctx, path, (struct arr_0) {7, constantarr_0_73}), res3->stdout, overwrite_output__q);
	} else {
		message4 = _op_plus_1(ctx, _op_plus_1(ctx, _op_plus_1(ctx, _op_plus_1(ctx, _op_plus_1(ctx, (struct arr_0) {8, constantarr_0_74}, to_str_1(ctx, res3->exit_code)), (struct arr_0) {9, constantarr_0_75}), res3->stdout), (struct arr_0) {8, constantarr_0_76}), res3->stderr);
		temp2 = (struct failure**) alloc(ctx, (sizeof(struct failure*) * 1));
		(*((temp2 + 0)) = (temp3 = (struct failure*) alloc(ctx, sizeof(struct failure)), ((*(temp3) = (struct failure) {path, message4}, 0), temp3)), 0);
		return (struct arr_7) {1, temp2};
	}
}
struct arr_7 run_noze_tests__lambda0(struct ctx* ctx, struct run_noze_tests__lambda0* _closure, struct arr_0 test) {
	return run_single_noze_test(ctx, _closure->path_to_noze, _closure->env, test, _closure->options);
}
uint8_t has__q_6(struct arr_7 a) {
	return !empty__q_11(a);
}
struct result_3 do_test__lambda0__lambda0(struct ctx* ctx, struct do_test__lambda0__lambda0* _closure) {
	return run_noze_tests(ctx, child_path(ctx, _closure->test_path, (struct arr_0) {8, constantarr_0_81}), _closure->noze_exe, _closure->env, _closure->options);
}
struct result_3 do_test__lambda0(struct ctx* ctx, struct do_test__lambda0* _closure) {
	struct do_test__lambda0__lambda0* temp0;
	return first_failures(ctx, run_noze_tests(ctx, child_path(ctx, _closure->test_path, (struct arr_0) {14, constantarr_0_80}), _closure->noze_exe, _closure->env, _closure->options), (struct fun0) {(fun_ptr2_3) do_test__lambda0__lambda0, (uint8_t*) (temp0 = (struct do_test__lambda0__lambda0*) alloc(ctx, sizeof(struct do_test__lambda0__lambda0)), ((*(temp0) = (struct do_test__lambda0__lambda0) {_closure->test_path, _closure->noze_exe, _closure->env, _closure->options}, 0), temp0))});
}
struct result_3 lint(struct ctx* ctx, struct arr_0 path, struct test_options options) {
	struct arr_1 files0;
	struct arr_7 failures1;
	struct lint__lambda0* temp0;
	files0 = list_lintable_files(ctx, path);
	failures1 = flat_map_with_max_size(ctx, files0, options.max_failures, (struct fun_mut1_12) {(fun_ptr3_13) lint__lambda0, (uint8_t*) (temp0 = (struct lint__lambda0*) alloc(ctx, sizeof(struct lint__lambda0)), ((*(temp0) = (struct lint__lambda0) {options}, 0), temp0))});
	if (has__q_6(failures1)) {
		return (struct result_3) {1, .as1 = (struct err_2) {failures1}};
	} else {
		return (struct result_3) {0, .as0 = (struct ok_3) {_op_plus_1(ctx, _op_plus_1(ctx, (struct arr_0) {7, constantarr_0_102}, to_str_3(ctx, files0.size)), (struct arr_0) {6, constantarr_0_103})}};
	}
}
struct arr_1 list_lintable_files(struct ctx* ctx, struct arr_0 path) {
	struct mut_arr_1* res0;
	struct list_lintable_files__lambda1* temp0;
	res0 = new_mut_arr_0(ctx);
	each_child_recursive(ctx, path, (struct fun_mut1_6) {(fun_ptr3_7) list_lintable_files__lambda0, (uint8_t*) NULL}, (struct fun_mut1_11) {(fun_ptr3_12) list_lintable_files__lambda1, (uint8_t*) (temp0 = (struct list_lintable_files__lambda1*) alloc(ctx, sizeof(struct list_lintable_files__lambda1)), ((*(temp0) = (struct list_lintable_files__lambda1) {res0}, 0), temp0))});
	return freeze_0(res0);
}
uint8_t excluded_from_lint__q(struct ctx* ctx, struct arr_0 name) {
	struct excluded_from_lint__q__lambda0* temp0;
	return (_op_equal_equal_0(first_0(ctx, name), literal_0((struct arr_0) {1, constantarr_0_43})) || (_op_equal_equal_4(name, (struct arr_0) {7, constantarr_0_85}) || some__q(ctx, (struct arr_1) {5, constantarr_1_2}, (struct fun_mut1_6) {(fun_ptr3_7) excluded_from_lint__q__lambda0, (uint8_t*) (temp0 = (struct excluded_from_lint__q__lambda0*) alloc(ctx, sizeof(struct excluded_from_lint__q__lambda0)), ((*(temp0) = (struct excluded_from_lint__q__lambda0) {name}, 0), temp0))})));
}
uint8_t some__q(struct ctx* ctx, struct arr_1 a, struct fun_mut1_6 pred) {
	struct arr_1 _tailCalla;
	struct fun_mut1_6 _tailCallpred;
	top:
	if (!empty__q_6(a)) {
		if (call_10(ctx, pred, first_1(ctx, a))) {
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
uint8_t ends_with__q(struct ctx* ctx, struct arr_0 a, struct arr_0 end) {
	return (_op_greater_equal(a.size, end.size) && arr_eq__q(ctx, slice_1(ctx, a, _op_minus_1(ctx, a.size, end.size), end.size), end));
}
uint8_t excluded_from_lint__q__lambda0(struct ctx* ctx, struct excluded_from_lint__q__lambda0* _closure, struct arr_0 it) {
	return ends_with__q(ctx, _closure->name, it);
}
uint8_t list_lintable_files__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr_0 it) {
	return !excluded_from_lint__q(ctx, it);
}
uint8_t ignore_extension_of_name(struct ctx* ctx, struct arr_0 name) {
	struct opt_11 _matched1;
	struct some_11 s0;
	_matched1 = get_extension(ctx, name);
	switch (_matched1.kind) {
		case 0:
			return 1;
		case 1:
			s0 = _matched1.as1;
			return ignore_extension(ctx, s0.value);
		default:
			return (assert(0),0);
	}
}
uint8_t ignore_extension(struct ctx* ctx, struct arr_0 ext) {
	return contains__q_1(ignored_extensions(ctx), ext);
}
uint8_t contains__q_1(struct arr_1 a, struct arr_0 value) {
	return contains_recur__q_1(a, value, 0);
}
uint8_t contains_recur__q_1(struct arr_1 a, struct arr_0 value, uint64_t i) {
	struct arr_1 _tailCalla;
	struct arr_0 _tailCallvalue;
	uint64_t _tailCalli;
	top:
	if (_op_equal_equal_1(i, a.size)) {
		return 0;
	} else {
		if (_op_equal_equal_4(noctx_at_5(a, i), value)) {
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
struct arr_1 ignored_extensions(struct ctx* ctx) {
	return (struct arr_1) {6, constantarr_1_3};
}
uint8_t list_lintable_files__lambda1(struct ctx* ctx, struct list_lintable_files__lambda1* _closure, struct arr_0 child) {
	if (ignore_extension_of_name(ctx, base_name(ctx, child))) {
		return 0;
	} else {
		return push_0(ctx, _closure->res, child);
	}
}
struct arr_7 lint_file(struct ctx* ctx, struct arr_0 path) {
	struct arr_0 text0;
	struct mut_arr_5* res1;
	uint8_t err_file__q2;
	struct lint_file__lambda0* temp0;
	text0 = read_file(ctx, path);
	res1 = new_mut_arr_2(ctx);
	err_file__q2 = _op_equal_equal_4(force(ctx, get_extension(ctx, path)), (struct arr_0) {3, constantarr_0_94});
	each_with_index_0(ctx, lines(ctx, text0), (struct fun_mut2_3) {(fun_ptr4_4) lint_file__lambda0, (uint8_t*) (temp0 = (struct lint_file__lambda0*) alloc(ctx, sizeof(struct lint_file__lambda0)), ((*(temp0) = (struct lint_file__lambda0) {err_file__q2, res1, path}, 0), temp0))});
	return freeze_6(res1);
}
struct arr_0 read_file(struct ctx* ctx, struct arr_0 path) {
	struct opt_11 _matched1;
	struct some_11 s0;
	_matched1 = try_read_file_0(ctx, path);
	switch (_matched1.kind) {
		case 0:
			print_sync(_op_plus_1(ctx, (struct arr_0) {21, constantarr_0_93}, path));
			return (struct arr_0) {0, NULL};
		case 1:
			s0 = _matched1.as1;
			return s0.value;
		default:
			return (assert(0),(struct arr_0) {0, NULL});
	}
}
uint8_t each_with_index_0(struct ctx* ctx, struct arr_1 a, struct fun_mut2_3 f) {
	return each_with_index_recur_0(ctx, a, f, 0);
}
uint8_t each_with_index_recur_0(struct ctx* ctx, struct arr_1 a, struct fun_mut2_3 f, uint64_t n) {
	struct arr_1 _tailCalla;
	struct fun_mut2_3 _tailCallf;
	uint64_t _tailCalln;
	top:
	if (_op_equal_equal_1(n, a.size)) {
		return 0;
	} else {
		call_26(ctx, f, at_2(ctx, a, n), n);
		_tailCalla = a;
		_tailCallf = f;
		_tailCalln = incr_1(ctx, n);
		a = _tailCalla;
		f = _tailCallf;
		n = _tailCalln;
		goto top;
	}
}
uint8_t call_26(struct ctx* ctx, struct fun_mut2_3 f, struct arr_0 p0, uint64_t p1) {
	return call_with_ctx_25(ctx, f, p0, p1);
}
uint8_t call_with_ctx_25(struct ctx* c, struct fun_mut2_3 f, struct arr_0 p0, uint64_t p1) {
	return f.fun_ptr(c, f.closure, p0, p1);
}
struct arr_1 lines(struct ctx* ctx, struct arr_0 s) {
	struct mut_arr_1* res0;
	struct cell_0* last_nl1;
	struct cell_0* temp0;
	struct lines__lambda0* temp1;
	res0 = new_mut_arr_0(ctx);
	last_nl1 = (temp0 = (struct cell_0*) alloc(ctx, sizeof(struct cell_0)), ((*(temp0) = (struct cell_0) {0}, 0), temp0));
	each_with_index_1(ctx, s, (struct fun_mut2_4) {(fun_ptr4_5) lines__lambda0, (uint8_t*) (temp1 = (struct lines__lambda0*) alloc(ctx, sizeof(struct lines__lambda0)), ((*(temp1) = (struct lines__lambda0) {res0, s, last_nl1}, 0), temp1))});
	push_0(ctx, res0, slice_from_to(ctx, s, get_6(last_nl1), s.size));
	return freeze_0(res0);
}
uint8_t each_with_index_1(struct ctx* ctx, struct arr_0 a, struct fun_mut2_4 f) {
	return each_with_index_recur_1(ctx, a, f, 0);
}
uint8_t each_with_index_recur_1(struct ctx* ctx, struct arr_0 a, struct fun_mut2_4 f, uint64_t n) {
	struct arr_0 _tailCalla;
	struct fun_mut2_4 _tailCallf;
	uint64_t _tailCalln;
	top:
	if (_op_equal_equal_1(n, a.size)) {
		return 0;
	} else {
		call_27(ctx, f, at_3(ctx, a, n), n);
		_tailCalla = a;
		_tailCallf = f;
		_tailCalln = incr_1(ctx, n);
		a = _tailCalla;
		f = _tailCallf;
		n = _tailCalln;
		goto top;
	}
}
uint8_t call_27(struct ctx* ctx, struct fun_mut2_4 f, char p0, uint64_t p1) {
	return call_with_ctx_26(ctx, f, p0, p1);
}
uint8_t call_with_ctx_26(struct ctx* c, struct fun_mut2_4 f, char p0, uint64_t p1) {
	return f.fun_ptr(c, f.closure, p0, p1);
}
struct arr_0 slice_from_to(struct ctx* ctx, struct arr_0 a, uint64_t begin, uint64_t end) {
	assert_0(ctx, _op_less_equal_0(begin, end));
	return slice_1(ctx, a, begin, _op_minus_1(ctx, end, begin));
}
uint64_t swap_1(struct cell_0* c, uint64_t v) {
	uint64_t res0;
	res0 = get_6(c);
	set_1(c, v);
	return res0;
}
uint64_t get_6(struct cell_0* c) {
	return c->value;
}
uint8_t set_1(struct cell_0* c, uint64_t v) {
	return (c->value = v, 0);
}
uint8_t lines__lambda0(struct ctx* ctx, struct lines__lambda0* _closure, char c, uint64_t index) {
	if (_op_equal_equal_0(c, literal_0((struct arr_0) {1, constantarr_0_4}))) {
		return push_0(ctx, _closure->res, slice_from_to(ctx, _closure->s, swap_1(_closure->last_nl, incr_1(ctx, index)), index));
	} else {
		return 0;
	}
}
uint8_t contains_subsequence__q(struct ctx* ctx, struct arr_0 a, struct arr_0 subseq) {
	return (starts_with__q(ctx, a, subseq) || (has__q_7(a) && starts_with__q(ctx, tail_1(ctx, a), subseq)));
}
uint8_t has__q_7(struct arr_0 a) {
	return !empty__q_0(a);
}
struct arr_0 lstrip(struct ctx* ctx, struct arr_0 a) {
	struct arr_0 _tailCalla;
	top:
	if ((has__q_7(a) && _op_equal_equal_0(first_0(ctx, a), literal_0((struct arr_0) {1, constantarr_0_51})))) {
		_tailCalla = tail_1(ctx, a);
		a = _tailCalla;
		goto top;
	} else {
		return a;
	}
}
uint64_t line_len(struct ctx* ctx, struct arr_0 line) {
	return _op_plus_0(ctx, _op_times_0(ctx, n_tabs(ctx, line), _op_minus_1(ctx, tab_size(ctx), literal_1(ctx, (struct arr_0) {1, constantarr_0_22}))), line.size);
}
uint64_t n_tabs(struct ctx* ctx, struct arr_0 line) {
	if ((!empty__q_0(line) && _op_equal_equal_0(first_0(ctx, line), literal_0((struct arr_0) {1, constantarr_0_98})))) {
		return incr_1(ctx, n_tabs(ctx, tail_1(ctx, line)));
	} else {
		return 0;
	}
}
uint64_t tab_size(struct ctx* ctx) {
	return literal_1(ctx, (struct arr_0) {1, constantarr_0_25});
}
uint64_t max_line_length(struct ctx* ctx) {
	return literal_1(ctx, (struct arr_0) {3, constantarr_0_99});
}
uint8_t lint_file__lambda0(struct ctx* ctx, struct lint_file__lambda0* _closure, struct arr_0 line, uint64_t line_num) {
	struct arr_0 ln0;
	struct arr_0 message1;
	struct failure* temp0;
	uint64_t width2;
	struct arr_0 message3;
	struct failure* temp1;
	ln0 = to_str_3(ctx, incr_1(ctx, line_num));
	if ((!_closure->err_file__q && contains_subsequence__q(ctx, lstrip(ctx, line), (struct arr_0) {2, constantarr_0_95}))) {
		message1 = _op_plus_1(ctx, _op_plus_1(ctx, (struct arr_0) {5, constantarr_0_96}, ln0), (struct arr_0) {24, constantarr_0_97});
		push_2(ctx, _closure->res, (temp0 = (struct failure*) alloc(ctx, sizeof(struct failure)), ((*(temp0) = (struct failure) {_closure->path, message1}, 0), temp0)));
	} else {
		0;
	}
	width2 = line_len(ctx, line);
	if (_op_greater_0(width2, max_line_length(ctx))) {
		message3 = _op_plus_1(ctx, _op_plus_1(ctx, _op_plus_1(ctx, _op_plus_1(ctx, _op_plus_1(ctx, (struct arr_0) {5, constantarr_0_96}, ln0), (struct arr_0) {4, constantarr_0_100}), to_str_3(ctx, width2)), (struct arr_0) {28, constantarr_0_101}), to_str_3(ctx, max_line_length(ctx)));
		return push_2(ctx, _closure->res, (temp1 = (struct failure*) alloc(ctx, sizeof(struct failure)), ((*(temp1) = (struct failure) {_closure->path, message3}, 0), temp1)));
	} else {
		return 0;
	}
}
struct arr_7 lint__lambda0(struct ctx* ctx, struct lint__lambda0* _closure, struct arr_0 file) {
	if (_closure->options.print_tests__q) {
		print_sync(_op_plus_1(ctx, (struct arr_0) {5, constantarr_0_92}, file));
	} else {
		0;
	}
	return lint_file(ctx, file);
}
struct result_3 do_test__lambda1(struct ctx* ctx, struct do_test__lambda1* _closure) {
	return lint(ctx, _closure->noze_path, _closure->options);
}
int32_t print_failures(struct ctx* ctx, struct result_3 failures, struct test_options options) {
	struct result_3 _matched3;
	struct ok_3 o0;
	struct err_2 e1;
	uint64_t n_failures2;
	_matched3 = failures;
	switch (_matched3.kind) {
		case 0:
			o0 = _matched3.as0;
			print_sync(o0.value);
			return literal_2(ctx, (struct arr_0) {1, constantarr_0_21});
		case 1:
			e1 = _matched3.as1;
			each_2(ctx, e1.value, (struct fun_mut1_13) {(fun_ptr3_14) print_failures__lambda0, (uint8_t*) NULL});
			n_failures2 = e1.value.size;
			print_sync((_op_equal_equal_1(n_failures2, options.max_failures) ? _op_plus_1(ctx, _op_plus_1(ctx, (struct arr_0) {15, constantarr_0_106}, to_str_3(ctx, options.max_failures)), (struct arr_0) {9, constantarr_0_107}) : _op_plus_1(ctx, to_str_3(ctx, n_failures2), (struct arr_0) {9, constantarr_0_107})));
			return to_int32(ctx, n_failures2);
		default:
			return (assert(0),0);
	}
}
uint8_t print_failure(struct ctx* ctx, struct failure* failure) {
	print_bold(ctx);
	print_sync_no_newline(failure->path);
	print_reset(ctx);
	print_sync_no_newline((struct arr_0) {1, constantarr_0_51});
	return print_sync(failure->message);
}
uint8_t print_bold(struct ctx* ctx) {
	return print_sync_no_newline((struct arr_0) {4, constantarr_0_104});
}
uint8_t print_reset(struct ctx* ctx) {
	return print_sync_no_newline((struct arr_0) {3, constantarr_0_105});
}
uint8_t print_failures__lambda0(struct ctx* ctx, uint8_t* _closure, struct failure* it) {
	return print_failure(ctx, it);
}
int32_t to_int32(struct ctx* ctx, uint64_t n) {
	assert_0(ctx, _op_less_0(n, million_0()));
	return n;
}
int32_t main(int32_t argc, char** argv) {
	return rt_main(argc, argv, main_0);
}
