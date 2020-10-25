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
struct less {
	uint8_t __mustBeNonEmpty;
};
struct equal {
	uint8_t __mustBeNonEmpty;
};
struct greater {
	uint8_t __mustBeNonEmpty;
};
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
struct some_4 {
	uint8_t* value;
};
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
struct thread_args;
struct cell_0 {
	uint64_t value;
};
struct cell_1 {
	uint8_t* value;
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
struct fun1;
struct parsed_cmd_line_args;
struct dict_0;
struct arr_6 {
	uint64_t size;
	struct arr_1* data;
};
struct some_11 {
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
struct some_12 {
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
struct some_14 {
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
struct comparison {
	int kind;
	union {
		struct less as0;
		struct equal as1;
		struct greater as2;
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
struct opt_11 {
	int kind;
	union {
		struct none as0;
		struct some_11 as1;
	};
};
struct opt_12 {
	int kind;
	union {
		struct none as0;
		struct some_12 as1;
	};
};
struct result_3 {
	int kind;
	union {
		struct ok_3 as0;
		struct err_2 as1;
	};
};
struct opt_13 {
	int kind;
	union {
		struct none as0;
		struct some_13 as1;
	};
};
struct opt_14 {
	int kind;
	union {
		struct none as0;
		struct some_14 as1;
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
typedef uint8_t (*fun_ptr2_3)(uint64_t, struct global_ctx*);
typedef struct test_options (*fun_ptr3_6)(struct ctx*, uint8_t*, struct arr_5);
typedef uint8_t (*fun_ptr3_7)(struct ctx*, uint8_t*, struct arr_0);
typedef struct opt_10 (*fun_ptr3_8)(struct ctx*, uint8_t*, uint64_t);
typedef uint8_t (*fun_ptr4_1)(struct ctx*, uint8_t*, struct arr_0, struct arr_1);
typedef char (*fun_ptr3_9)(struct ctx*, uint8_t*, uint64_t);
typedef uint8_t (*fun_ptr3_10)(struct ctx*, uint8_t*, char);
typedef struct result_3 (*fun_ptr2_4)(struct ctx*, uint8_t*);
typedef struct result_3 (*fun_ptr3_11)(struct ctx*, uint8_t*, struct arr_0);
typedef uint8_t (*fun_ptr3_12)(struct ctx*, uint8_t*, struct arr_0);
typedef struct arr_7 (*fun_ptr3_13)(struct ctx*, uint8_t*, struct arr_0);
typedef uint8_t (*fun_ptr3_14)(struct ctx*, uint8_t*, struct failure*);
typedef struct opt_14 (*fun_ptr3_15)(struct ctx*, uint8_t*, struct arr_0);
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
struct thread_args {
	fun_ptr2_3 fun;
	uint64_t thread_id;
	struct global_ctx* arg;
};
struct chosen_task;
struct some_5;
struct ok_2;
struct some_6;
struct some_7;
struct task_and_nodes;
struct some_8;
struct arr_5 {
	uint64_t size;
	struct opt_10* data;
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
	struct opt_10* data;
};
struct fun_mut1_7 {
	fun_ptr3_8 fun_ptr;
	uint8_t* closure;
};
struct fill_mut_arr__lambda0 {
	struct opt_10 value;
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
	fun_ptr2_4 fun_ptr;
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
struct opt_5;
struct result_2;
struct opt_6;
struct opt_7;
struct opt_8;
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
struct jmp_buf_tag {
	struct bytes64 jmp_buf;
	int32_t mask_was_saved;
	struct bytes128 saved_mask;
};
struct chosen_task {
	struct vat* vat;
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

int32_t rt_main(int32_t argc, char** argv, fun_ptr2_0 main_ptr);
uint64_t two_0();
uint64_t wrap_incr_0(uint64_t a);
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
uint8_t hard_assert(uint8_t condition);
uint8_t null__q_0(uint8_t* a);
uint8_t _op_equal_equal_0(uint64_t a, uint64_t b);
struct comparison compare_16(uint64_t a, uint64_t b);
struct gc new_gc();
struct none none();
struct mut_bag new_mut_bag();
struct thread_safe_counter new_thread_safe_counter_0();
struct thread_safe_counter new_thread_safe_counter_1(uint64_t init);
uint8_t* null_any();
uint8_t default_exception_handler(struct ctx* ctx, struct exception e);
uint8_t print_err_sync_no_newline(struct arr_0 s);
uint8_t write_sync_no_newline(int32_t fd, struct arr_0 s);
extern int64_t write(int32_t fd, uint8_t* buff, uint64_t n_bytes);
uint8_t _op_equal_equal_1(int64_t a, int64_t b);
struct comparison compare_28(int64_t a, int64_t b);
uint8_t todo_0();
int32_t stderr_fd();
int32_t two_1();
int32_t wrap_incr_1(int32_t a);
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
uint64_t nine_0();
uint64_t eight_0();
uint64_t seven_0();
uint64_t six_0();
uint64_t five_0();
uint64_t four_0();
uint64_t three_0();
uint8_t yield_thread();
extern int32_t pthread_yield();
extern void usleep(uint64_t micro_seconds);
uint8_t zero__q_1(int32_t i);
uint8_t _op_equal_equal_2(int32_t a, int32_t b);
struct comparison compare_62(int32_t a, int32_t b);
uint64_t noctx_incr(uint64_t n);
uint8_t _op_less_0(uint64_t a, uint64_t b);
uint64_t billion_0();
uint64_t million_0();
uint8_t release_lock(struct lock* l);
uint8_t must_unset(struct _atomic_bool* a);
uint8_t try_unset(struct _atomic_bool* a);
struct fut_0* add_first_task(struct ctx* ctx, struct arr_3 all_args, fun_ptr2_0 main_ptr);
struct fut_0* then2(struct ctx* ctx, struct fut_1* f, struct fun_ref0 cb);
struct fut_0* then_0(struct ctx* ctx, struct fut_1* f, struct fun_ref1 cb);
struct fut_0* new_unresolved_fut(struct ctx* ctx);
uint8_t* alloc(struct ctx* ctx, uint64_t size);
uint8_t* gc_alloc(struct ctx* ctx, struct gc* gc, uint64_t size);
struct opt_4 try_gc_alloc(struct gc* gc, uint64_t size);
struct some_4 some_0(uint8_t* t);
uint8_t* todo_1();
struct gc* get_gc(struct ctx* ctx);
struct gc_ctx* get_gc_ctx_1(struct ctx* ctx);
uint8_t then_void_0(struct ctx* ctx, struct fut_1* f, struct fun_mut1_2 cb);
struct some_3 some_1(struct fut_callback_node_1* t);
uint8_t call_0(struct ctx* ctx, struct fun_mut1_2 f, struct result_1 p0);
uint8_t call_with_ctx_0(struct ctx* c, struct fun_mut1_2 f, struct result_1 p0);
struct ok_1 ok_0(uint8_t t);
struct err_0 err_0(struct exception t);
uint8_t forward_to(struct ctx* ctx, struct fut_0* from, struct fut_0* to);
uint8_t then_void_1(struct ctx* ctx, struct fut_0* f, struct fun_mut1_0 cb);
struct some_0 some_2(struct fut_callback_node_0* t);
uint8_t call_1(struct ctx* ctx, struct fun_mut1_0 f, struct result_0 p0);
uint8_t call_with_ctx_1(struct ctx* c, struct fun_mut1_0 f, struct result_0 p0);
struct ok_0 ok_1(int32_t t);
uint8_t resolve_or_reject(struct ctx* ctx, struct fut_0* f, struct result_0 result);
uint8_t resolve_or_reject_recur(struct ctx* ctx, struct opt_0 node, struct result_0 value);
uint8_t drop_0(uint8_t t);
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
struct vat* noctx_at_0(struct arr_2 a, uint64_t index);
uint8_t add_task(struct ctx* ctx, struct vat* v, struct task t);
struct mut_bag_node* new_mut_bag_node(struct ctx* ctx, struct task value);
uint8_t add_0(struct mut_bag* bag, struct mut_bag_node* node);
struct some_2 some_3(struct mut_bag_node* t);
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
uint64_t _op_minus_0(struct ctx* ctx, uint64_t a, uint64_t b);
struct arr_1 map_0(struct ctx* ctx, struct arr_3 a, struct fun_mut1_4 mapper);
struct arr_1 make_arr_0(struct ctx* ctx, uint64_t size, struct fun_mut1_5 f);
struct arr_1 freeze_0(struct mut_arr_1* a);
struct arr_1 unsafe_as_arr_0(struct mut_arr_1* a);
struct mut_arr_1* make_mut_arr_0(struct ctx* ctx, uint64_t size, struct fun_mut1_5 f);
struct mut_arr_1* new_uninitialized_mut_arr_0(struct ctx* ctx, uint64_t size);
struct arr_0* uninitialized_data_0(struct ctx* ctx, uint64_t size);
uint8_t make_mut_arr_worker_0(struct ctx* ctx, struct mut_arr_1* m, uint64_t i, struct fun_mut1_5 f);
uint8_t set_at_0(struct ctx* ctx, struct mut_arr_1* a, uint64_t index, struct arr_0 value);
uint8_t noctx_set_at_0(struct mut_arr_1* a, uint64_t index, struct arr_0 value);
struct arr_0 call_8(struct ctx* ctx, struct fun_mut1_5 f, uint64_t p0);
struct arr_0 call_with_ctx_6(struct ctx* c, struct fun_mut1_5 f, uint64_t p0);
uint64_t incr_0(struct ctx* ctx, uint64_t n);
struct arr_0 call_9(struct ctx* ctx, struct fun_mut1_4 f, char* p0);
struct arr_0 call_with_ctx_7(struct ctx* c, struct fun_mut1_4 f, char* p0);
char* at_1(struct ctx* ctx, struct arr_3 a, uint64_t index);
char* noctx_at_1(struct arr_3 a, uint64_t index);
struct arr_0 map_0__lambda0(struct ctx* ctx, struct map_0__lambda0* _closure, uint64_t i);
struct arr_0 to_str_0(char* a);
struct arr_0 arr_from_begin_end(char* begin, char* end);
uint64_t _op_minus_1(char* a, char* b);
char* find_cstr_end(char* a);
char* find_char_in_cstr(char* a, char c);
uint8_t _op_equal_equal_3(char a, char b);
struct comparison compare_180(char a, char b);
char literal_0(struct arr_0 a);
char noctx_at_2(struct arr_0 a, uint64_t index);
char* todo_2();
char* incr_1(char* p);
struct arr_0 add_first_task__lambda0__lambda0(struct ctx* ctx, uint8_t* _closure, char* it);
struct fut_0* add_first_task__lambda0(struct ctx* ctx, struct add_first_task__lambda0* _closure);
struct fut_0* do_main__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr_3 all_args, fun_ptr2_0 main_ptr);
struct fut_0* call_with_ctx_8(struct ctx* c, struct fun2 f, struct arr_3 p0, fun_ptr2_0 p1);
uint8_t run_threads(uint64_t n_threads, struct global_ctx* arg, fun_ptr2_3 fun);
struct thread_args* unmanaged_alloc_elements_1(uint64_t size_elements);
uint8_t run_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads, struct thread_args* thread_args, struct global_ctx* arg, fun_ptr2_3 fun);
uint8_t* thread_fun(uint8_t* args_ptr);
uint8_t* run_threads_recur__lambda0(uint8_t* args_ptr);
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
uint8_t thread_function(uint64_t thread_id, struct global_ctx* gctx);
uint8_t thread_function_recur(uint64_t thread_id, struct global_ctx* gctx, struct thread_local_stuff* tls);
uint64_t noctx_decr_0(uint64_t n);
uint8_t assert_vats_are_shut_down(uint64_t i, struct arr_2 vats);
uint8_t empty__q_2(struct mut_bag* m);
uint8_t empty__q_3(struct opt_2 a);
uint8_t _op_greater_0(uint64_t a, uint64_t b);
uint64_t get_last_checked(struct condition* c);
struct result_2 choose_task(struct global_ctx* gctx);
struct opt_6 choose_task_recur(struct arr_2 vats, uint64_t i);
struct opt_7 choose_task_in_vat(struct vat* vat);
struct some_7 some_4(struct opt_5 t);
struct opt_5 find_and_remove_first_doable_task(struct vat* vat);
struct opt_8 find_and_remove_first_doable_task_recur(struct vat* vat, struct opt_2 opt_node);
uint8_t contains__q_0(struct mut_arr_0* a, uint64_t value);
uint8_t contains_recur__q_0(struct arr_4 a, uint64_t value, uint64_t i);
uint64_t noctx_at_3(struct arr_4 a, uint64_t index);
struct arr_4 temp_as_arr(struct mut_arr_0* a);
uint8_t push_capacity_must_be_sufficient(struct mut_arr_0* a, uint64_t value);
uint8_t noctx_set_at_1(struct mut_arr_0* a, uint64_t index, uint64_t value);
struct some_8 some_5(struct task_and_nodes t);
struct some_5 some_6(struct task t);
uint8_t empty__q_4(struct opt_7 a);
struct some_6 some_7(struct chosen_task t);
struct err_1 err_1(struct no_chosen_task t);
struct ok_2 ok_2(struct chosen_task t);
uint8_t do_task(struct global_ctx* gctx, struct thread_local_stuff* tls, struct chosen_task chosen_task);
uint8_t noctx_must_remove_unordered(struct mut_arr_0* a, uint64_t value);
uint8_t noctx_must_remove_unordered_recur(struct mut_arr_0* a, uint64_t index, uint64_t value);
uint64_t noctx_at_4(struct mut_arr_0* a, uint64_t index);
uint8_t drop_1(uint64_t t);
uint64_t noctx_remove_unordered_at_index(struct mut_arr_0* a, uint64_t index);
uint64_t noctx_last(struct mut_arr_0* a);
uint8_t empty__q_5(struct mut_arr_0* a);
uint8_t return_ctx(struct ctx* c);
uint8_t return_gc_ctx(struct gc_ctx* gc_ctx);
struct some_1 some_8(struct gc_ctx* t);
uint8_t wait_on(struct condition* c, uint64_t last_checked);
uint8_t rt_main__lambda0(uint64_t thread_id, struct global_ctx* gctx);
struct result_0 must_be_resolved(struct fut_0* f);
struct result_0 hard_unreachable_0();
struct fut_0* main_0(struct ctx* ctx, struct arr_1 args);
struct opt_9 parse_cmd_line_args(struct ctx* ctx, struct arr_1 args, struct arr_1 t_names, struct fun1 make_t);
struct parsed_cmd_line_args* parse_cmd_line_args_dynamic(struct ctx* ctx, struct arr_1 args);
struct opt_11 find_index(struct ctx* ctx, struct arr_1 a, struct fun_mut1_6 pred);
struct opt_11 find_index_recur(struct ctx* ctx, struct arr_1 a, uint64_t index, struct fun_mut1_6 pred);
uint8_t call_10(struct ctx* ctx, struct fun_mut1_6 f, struct arr_0 p0);
uint8_t call_with_ctx_9(struct ctx* c, struct fun_mut1_6 f, struct arr_0 p0);
struct arr_0 at_2(struct ctx* ctx, struct arr_1 a, uint64_t index);
struct arr_0 noctx_at_5(struct arr_1 a, uint64_t index);
struct some_11 some_9(uint64_t t);
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
struct comparison compare_273(struct arr_0 a, struct arr_0 b);
uint8_t parse_cmd_line_args_dynamic__lambda1(struct ctx* ctx, uint8_t* _closure, struct arr_0 it);
struct dict_0* parse_named_args(struct ctx* ctx, struct arr_1 args);
struct mut_dict_0 new_mut_dict_0(struct ctx* ctx);
struct mut_arr_1* new_mut_arr_0(struct ctx* ctx);
struct mut_arr_2* new_mut_arr_1(struct ctx* ctx);
uint8_t parse_named_args_recur(struct ctx* ctx, struct arr_1 args, struct mut_dict_0 builder);
struct arr_0 remove_start(struct ctx* ctx, struct arr_0 a, struct arr_0 start);
struct arr_0 force(struct ctx* ctx, struct opt_12 a);
struct arr_0 fail_1(struct ctx* ctx, struct arr_0 reason);
struct arr_0 throw_1(struct ctx* ctx, struct exception e);
struct arr_0 todo_3();
struct opt_12 try_remove_start(struct ctx* ctx, struct arr_0 a, struct arr_0 start);
struct some_12 some_10(struct arr_0 t);
struct arr_0 first_1(struct ctx* ctx, struct arr_1 a);
uint8_t empty__q_6(struct arr_1 a);
struct arr_1 tail_2(struct ctx* ctx, struct arr_1 a);
uint8_t parse_named_args_recur__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr_0 it);
uint8_t add_1(struct ctx* ctx, struct mut_dict_0 m, struct arr_0 key, struct arr_1 value);
uint8_t has__q_0(struct ctx* ctx, struct mut_dict_0 d, struct arr_0 key);
uint8_t has__q_1(struct ctx* ctx, struct dict_0* d, struct arr_0 key);
uint8_t has__q_2(struct opt_10 a);
uint8_t empty__q_7(struct opt_10 a);
struct opt_10 get_1(struct ctx* ctx, struct dict_0* d, struct arr_0 key);
struct opt_10 get_recursive_0(struct ctx* ctx, struct arr_1 keys, struct arr_6 values, uint64_t idx, struct arr_0 key);
struct some_10 some_11(struct arr_1 t);
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
struct mut_arr_3* fill_mut_arr(struct ctx* ctx, uint64_t size, struct opt_10 value);
struct mut_arr_3* make_mut_arr_1(struct ctx* ctx, uint64_t size, struct fun_mut1_7 f);
struct mut_arr_3* new_uninitialized_mut_arr_1(struct ctx* ctx, uint64_t size);
struct opt_10* uninitialized_data_2(struct ctx* ctx, uint64_t size);
uint8_t make_mut_arr_worker_1(struct ctx* ctx, struct mut_arr_3* m, uint64_t i, struct fun_mut1_7 f);
uint8_t set_at_1(struct ctx* ctx, struct mut_arr_3* a, uint64_t index, struct opt_10 value);
uint8_t noctx_set_at_2(struct mut_arr_3* a, uint64_t index, struct opt_10 value);
struct opt_10 call_11(struct ctx* ctx, struct fun_mut1_7 f, uint64_t p0);
struct opt_10 call_with_ctx_10(struct ctx* c, struct fun_mut1_7 f, uint64_t p0);
struct opt_10 fill_mut_arr__lambda0(struct ctx* ctx, struct fill_mut_arr__lambda0* _closure, uint64_t ignore);
struct cell_2* new_cell_0(struct ctx* ctx, uint8_t value);
uint8_t each_0(struct ctx* ctx, struct dict_0* d, struct fun_mut2_0 f);
uint8_t empty__q_8(struct ctx* ctx, struct dict_0* d);
uint8_t call_12(struct ctx* ctx, struct fun_mut2_0 f, struct arr_0 p0, struct arr_1 p1);
uint8_t call_with_ctx_11(struct ctx* c, struct fun_mut2_0 f, struct arr_0 p0, struct arr_1 p1);
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
char call_13(struct ctx* ctx, struct fun_mut1_8 f, uint64_t p0);
char call_with_ctx_12(struct ctx* c, struct fun_mut1_8 f, uint64_t p0);
char _op_plus_1__lambda0(struct ctx* ctx, struct _op_plus_1__lambda0* _closure, uint64_t i);
struct opt_10 at_5(struct ctx* ctx, struct mut_arr_3* a, uint64_t index);
struct opt_10 noctx_at_7(struct mut_arr_3* a, uint64_t index);
uint8_t parse_cmd_line_args__lambda0(struct ctx* ctx, struct parse_cmd_line_args__lambda0* _closure, struct arr_0 key, struct arr_1 value);
uint8_t get_2(struct cell_2* c);
struct some_9 some_12(struct test_options t);
struct test_options call_14(struct ctx* ctx, struct fun1 f, struct arr_5 p0);
struct test_options call_with_ctx_13(struct ctx* c, struct fun1 f, struct arr_5 p0);
struct arr_5 freeze_4(struct mut_arr_3* a);
struct arr_5 unsafe_as_arr_3(struct mut_arr_3* a);
struct opt_10 at_6(struct ctx* ctx, struct arr_5 a, uint64_t index);
struct opt_10 noctx_at_8(struct arr_5 a, uint64_t index);
uint64_t literal_1(struct ctx* ctx, struct arr_0 s);
struct arr_0 rtail(struct ctx* ctx, struct arr_0 a);
uint64_t char_to_nat(char c);
uint64_t todo_4();
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
struct opt_11 r_index_of(struct ctx* ctx, struct arr_0 a, char value);
struct opt_11 find_rindex(struct ctx* ctx, struct arr_0 a, struct fun_mut1_9 pred);
struct opt_11 find_rindex_recur(struct ctx* ctx, struct arr_0 a, uint64_t index, struct fun_mut1_9 pred);
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
uint8_t has__q_5(struct opt_12 a);
uint8_t empty__q_10(struct opt_12 a);
struct opt_12 get_3(struct ctx* ctx, struct dict_1* d, struct arr_0 key);
struct opt_12 get_recursive_1(struct ctx* ctx, struct arr_1 keys, struct arr_1 values, uint64_t idx, struct arr_0 key);
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
struct ok_3 ok_3(struct arr_0 t);
struct result_3 first_failures__lambda0__lambda0(struct ctx* ctx, struct first_failures__lambda0__lambda0* _closure, struct arr_0 b_descr);
struct result_3 first_failures__lambda0(struct ctx* ctx, struct first_failures__lambda0* _closure, struct arr_0 a_descr);
struct result_3 run_noze_tests(struct ctx* ctx, struct arr_0 path, struct arr_0 path_to_noze, struct dict_1* env, struct test_options options);
struct arr_1 list_tests(struct ctx* ctx, struct arr_0 path);
uint8_t list_tests__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr_0 s);
uint8_t each_child_recursive(struct ctx* ctx, struct arr_0 path, struct fun_mut1_6 filter, struct fun_mut1_11 f);
uint8_t is_dir__q_0(struct ctx* ctx, struct arr_0 path);
uint8_t is_dir__q_1(struct ctx* ctx, char* path);
struct opt_13 get_stat(struct ctx* ctx, char* path);
struct stat_t* empty_stat(struct ctx* ctx);
extern int32_t stat(char* path, struct stat_t* buf);
struct some_13 some_13(struct stat_t* t);
int32_t neg_one_1();
int32_t enoent();
struct opt_13 todo_5();
uint8_t todo_6();
uint8_t _op_equal_equal_5(uint32_t a, uint32_t b);
struct comparison compare_467(uint32_t a, uint32_t b);
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
struct cell_3* new_cell_1(struct ctx* ctx, struct dirent* value);
extern int32_t readdir_r(uint8_t* dirp, struct dirent* entry, struct cell_3* result);
struct dirent* get_4(struct cell_3* c);
uint8_t ref_eq(struct dirent* a, struct dirent* b);
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
struct opt_12 get_extension(struct ctx* ctx, struct arr_0 name);
struct opt_11 last_index_of(struct ctx* ctx, struct arr_0 s, char c);
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
struct opt_14 first_some(struct ctx* ctx, struct arr_1 a, struct fun_mut1_14 cb);
struct opt_14 call_21(struct ctx* ctx, struct fun_mut1_14 f, struct arr_0 p0);
struct opt_14 call_with_ctx_20(struct ctx* c, struct fun_mut1_14 f, struct arr_0 p0);
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
struct cell_4* new_cell_2(struct ctx* ctx, int32_t value);
extern int32_t posix_spawn(struct cell_4* pid, char* executable_path, struct posix_spawn_file_actions_t* file_actions, uint8_t* attrp, char** argv, char** environ);
int32_t get_5(struct cell_4* c);
extern int32_t close(int32_t fd);
struct mut_arr_4* new_mut_arr_3(struct ctx* ctx);
uint8_t keep_polling(struct ctx* ctx, int32_t stdout_pipe, int32_t stderr_pipe, struct mut_arr_4* stdout_builder, struct mut_arr_4* stderr_builder);
int16_t pollin(struct ctx* ctx);
int16_t two_pow_1(int16_t pow);
uint8_t zero__q_3(int16_t a);
uint8_t _op_equal_equal_6(int16_t a, int16_t b);
struct comparison compare_574(int16_t a, int16_t b);
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
int32_t todo_7();
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
struct arr_3 cons(struct ctx* ctx, char* a, struct arr_3 b);
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
struct arr_3 rcons(struct ctx* ctx, struct arr_3 a, char* b);
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
struct process_result* todo_8();
struct arr_7 empty_arr_3();
struct arr_7 handle_output(struct ctx* ctx, struct arr_0 original_path, struct arr_0 output_path, struct arr_0 actual, uint8_t overwrite_output__q);
struct opt_12 try_read_file_0(struct ctx* ctx, struct arr_0 path);
struct opt_12 try_read_file_1(struct ctx* ctx, char* path);
extern int32_t open(char* path, uint32_t oflag, uint32_t permission);
uint32_t o_rdonly(struct ctx* ctx);
uint32_t literal_4(struct ctx* ctx, struct arr_0 s);
struct opt_12 todo_9();
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
struct some_14 some_14(struct arr_7 t);
struct opt_14 run_single_noze_test__lambda0(struct ctx* ctx, struct run_single_noze_test__lambda0* _closure, struct arr_0 print_kind);
struct arr_7 run_single_runnable_test(struct ctx* ctx, struct arr_0 path_to_noze, struct dict_1* env, struct arr_0 path, uint8_t overwrite_output__q);
struct arr_7 run_noze_tests__lambda0(struct ctx* ctx, struct run_noze_tests__lambda0* _closure, struct arr_0 test);
uint8_t has__q_6(struct arr_7 a);
struct err_2 err_2(struct arr_7 t);
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
struct cell_0* new_cell_3(struct ctx* ctx, uint64_t value);
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
	uint64_t n_threads;
	struct global_ctx gctx_by_val;
	struct global_ctx* gctx;
	struct vat vat_by_val;
	struct vat* vat;
	struct fut_0* main_fut;
	struct ok_0 o;
	struct err_0 e;
	struct result_0 matched;
	n_threads = two_0();
	gctx_by_val = (struct global_ctx) {new_lock(), empty_arr_0(), n_threads, new_condition(), 0, 0};
	gctx = (&(gctx_by_val));
	vat_by_val = new_vat(gctx, 0, n_threads);
	vat = (&(vat_by_val));
	(gctx->vats = (struct arr_2) {1, (&(vat))}, 0);
	main_fut = do_main(gctx, vat, argc, argv, main_ptr);
	run_threads(n_threads, gctx, rt_main__lambda0);
	if (gctx->any_unhandled_exceptions__q) {
		return 1;
	} else {
		matched = must_be_resolved(main_fut);
		switch (matched.kind) {
			case 0:
				o = matched.as0;
				return o.value;
			case 1:
				e = matched.as1;
				print_err_sync_no_newline((struct arr_0) {13, "main failed: "});
				print_err_sync(e.value.message);
				return 1;
			default:
				return (assert(0),0);
		}
	}
}
uint64_t two_0() {
	return wrap_incr_0(1);
}
uint64_t wrap_incr_0(uint64_t a) {
	return (a + 1);
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
	struct mut_arr_0 actors;
	actors = new_mut_arr_by_val_with_capacity_from_unmanaged_memory(max_threads);
	return (struct vat) {gctx, id, new_gc(), new_lock(), new_mut_bag(), actors, 0, new_thread_safe_counter_0(), (struct fun_mut1_1) {(fun_ptr3_1) new_vat__lambda0, (uint8_t*) null_any()}};
}
struct mut_arr_0 new_mut_arr_by_val_with_capacity_from_unmanaged_memory(uint64_t capacity) {
	return (struct mut_arr_0) {0, 0, capacity, unmanaged_alloc_elements_0(capacity)};
}
uint64_t* unmanaged_alloc_elements_0(uint64_t size_elements) {
	uint8_t* bytes;
	bytes = unmanaged_alloc_bytes((size_elements * sizeof(uint64_t)));
	return (uint64_t*) bytes;
}
uint8_t* unmanaged_alloc_bytes(uint64_t size) {
	uint8_t* res;
	res = malloc(size);
	hard_forbid(null__q_0(res));
	return res;
}
uint8_t hard_forbid(uint8_t condition) {
	return hard_assert(!condition);
}
uint8_t hard_assert(uint8_t condition) {
	if (condition) {
		return 0;
	} else {
		return (assert(0),0);
	}
}
uint8_t null__q_0(uint8_t* a) {
	return _op_equal_equal_0((uint64_t) a, (uint64_t) NULL);
}
uint8_t _op_equal_equal_0(uint64_t a, uint64_t b) {
	struct comparison matched;
	matched = compare_16(a, b);
	switch (matched.kind) {
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
struct comparison compare_16(uint64_t a, uint64_t b) {
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
struct gc new_gc() {
	return (struct gc) {new_lock(), (struct opt_1) {0, .as0 = none()}, 0, 0, NULL, NULL};
}
struct none none() {
	return (struct none) {0};
}
struct mut_bag new_mut_bag() {
	return (struct mut_bag) {(struct opt_2) {0, .as0 = none()}};
}
struct thread_safe_counter new_thread_safe_counter_0() {
	return new_thread_safe_counter_1(0);
}
struct thread_safe_counter new_thread_safe_counter_1(uint64_t init) {
	return (struct thread_safe_counter) {new_lock(), init};
}
uint8_t* null_any() {
	return NULL;
}
uint8_t default_exception_handler(struct ctx* ctx, struct exception e) {
	print_err_sync_no_newline((struct arr_0) {20, "uncaught exception: "});
	print_err_sync((empty__q_0(e.message) ? (struct arr_0) {17, "<<empty message>>"} : e.message));
	return (get_gctx(ctx)->any_unhandled_exceptions__q = 1, 0);
}
uint8_t print_err_sync_no_newline(struct arr_0 s) {
	return write_sync_no_newline(stderr_fd(), s);
}
uint8_t write_sync_no_newline(int32_t fd, struct arr_0 s) {
	int64_t res;
	hard_assert(_op_equal_equal_0(sizeof(char), sizeof(uint8_t)));
	res = write(fd, (uint8_t*) s.data, s.size);
	if (_op_equal_equal_1(res, s.size)) {
		return 0;
	} else {
		return todo_0();
	}
}
uint8_t _op_equal_equal_1(int64_t a, int64_t b) {
	struct comparison matched;
	matched = compare_28(a, b);
	switch (matched.kind) {
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
struct comparison compare_28(int64_t a, int64_t b) {
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
uint8_t todo_0() {
	return (assert(0),0);
}
int32_t stderr_fd() {
	return two_1();
}
int32_t two_1() {
	return wrap_incr_1(1);
}
int32_t wrap_incr_1(int32_t a) {
	return (a + 1);
}
uint8_t print_err_sync(struct arr_0 s) {
	print_err_sync_no_newline(s);
	return print_err_sync_no_newline((struct arr_0) {1, "\n"});
}
uint8_t empty__q_0(struct arr_0 a) {
	return zero__q_0(a.size);
}
uint8_t zero__q_0(uint64_t n) {
	return _op_equal_equal_0(n, 0);
}
struct global_ctx* get_gctx(struct ctx* ctx) {
	return (struct global_ctx*) ctx->gctx_ptr;
}
uint8_t new_vat__lambda0(struct ctx* ctx, uint8_t* _closure, struct exception it) {
	return default_exception_handler(ctx, it);
}
struct fut_0* do_main(struct global_ctx* gctx, struct vat* vat, int32_t argc, char** argv, fun_ptr2_0 main_ptr) {
	struct exception_ctx ectx;
	struct thread_local_stuff tls;
	struct ctx ctx_by_val;
	struct ctx* ctx;
	struct fun2 add;
	struct arr_3 all_args;
	ectx = new_exception_ctx();
	tls = (struct thread_local_stuff) {(&(ectx))};
	ctx_by_val = new_ctx(gctx, (&(tls)), vat, 0);
	ctx = (&(ctx_by_val));
	add = (struct fun2) {(fun_ptr4_0) do_main__lambda0, (uint8_t*) null_any()};
	all_args = (struct arr_3) {argc, argv};
	return call_with_ctx_8(ctx, add, all_args, main_ptr);
}
struct exception_ctx new_exception_ctx() {
	return (struct exception_ctx) {NULL, (struct exception) {(struct arr_0) {0, ""}}};
}
struct ctx new_ctx(struct global_ctx* gctx, struct thread_local_stuff* tls, struct vat* vat, uint64_t actor_id) {
	return (struct ctx) {(uint8_t*) gctx, vat->id, actor_id, (uint8_t*) get_gc_ctx_0((&(vat->gc))), (uint8_t*) tls->exception_ctx};
}
struct gc_ctx* get_gc_ctx_0(struct gc* gc) {
	struct gc_ctx* c;
	struct some_1 s;
	struct gc_ctx* c1;
	struct opt_1 matched;
	struct gc_ctx* res;
	acquire_lock((&(gc->lk)));
	res = (matched = gc->context_head, matched.kind == 0 ? (c = (struct gc_ctx*) malloc(sizeof(struct gc_ctx*)), (((c->gc = gc, 0), (c->next_ctx = (struct opt_1) {0, .as0 = none()}, 0)), c)) : matched.kind == 1 ? (s = matched.as1, (c1 = s.value, (((gc->context_head = c1->next_ctx, 0), (c1->next_ctx = (struct opt_1) {0, .as0 = none()}, 0)), c1))) : (assert(0),NULL));
	release_lock((&(gc->lk)));
	return res;
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
		if (_op_equal_equal_0(n_tries, thousand_0())) {
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
	return wrap_incr_0(nine_0());
}
uint64_t nine_0() {
	return wrap_incr_0(eight_0());
}
uint64_t eight_0() {
	return wrap_incr_0(seven_0());
}
uint64_t seven_0() {
	return wrap_incr_0(six_0());
}
uint64_t six_0() {
	return wrap_incr_0(five_0());
}
uint64_t five_0() {
	return wrap_incr_0(four_0());
}
uint64_t four_0() {
	return wrap_incr_0(three_0());
}
uint64_t three_0() {
	return wrap_incr_0(two_0());
}
uint8_t yield_thread() {
	int32_t err;
	err = pthread_yield();
	(usleep(thousand_0()), 0);
	return hard_assert(zero__q_1(err));
}
uint8_t zero__q_1(int32_t i) {
	return _op_equal_equal_2(i, 0);
}
uint8_t _op_equal_equal_2(int32_t a, int32_t b) {
	struct comparison matched;
	matched = compare_62(a, b);
	switch (matched.kind) {
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
struct comparison compare_62(int32_t a, int32_t b) {
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
	return wrap_incr_0(n);
}
uint8_t _op_less_0(uint64_t a, uint64_t b) {
	struct comparison matched;
	matched = compare_16(a, b);
	switch (matched.kind) {
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
	uint8_t did_unset;
	did_unset = try_unset(a);
	return hard_assert(did_unset);
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
	struct fut_0* res;
	struct then_0__lambda0* temp0;
	res = new_unresolved_fut(ctx);
	then_void_0(ctx, f, (struct fun_mut1_2) {(fun_ptr3_2) then_0__lambda0, (uint8_t*) (temp0 = (struct then_0__lambda0*) alloc(ctx, sizeof(struct then_0__lambda0)), ((*(temp0) = (struct then_0__lambda0) {cb, res}, 0), temp0))});
	return res;
}
struct fut_0* new_unresolved_fut(struct ctx* ctx) {
	struct fut_0* temp0;
	temp0 = (struct fut_0*) alloc(ctx, sizeof(struct fut_0));
	(*(temp0) = (struct fut_0) {new_lock(), (struct fut_state_0) {0, .as0 = (struct fut_state_callbacks_0) {(struct opt_0) {0, .as0 = none()}}}}, 0);
	return temp0;
}
uint8_t* alloc(struct ctx* ctx, uint64_t size) {
	return gc_alloc(ctx, get_gc(ctx), size);
}
uint8_t* gc_alloc(struct ctx* ctx, struct gc* gc, uint64_t size) {
	struct some_4 s;
	struct opt_4 matched;
	matched = try_gc_alloc(gc, size);
	switch (matched.kind) {
		case 0:
			return todo_1();
		case 1:
			s = matched.as1;
			return s.value;
		default:
			return (assert(0),NULL);
	}
}
struct opt_4 try_gc_alloc(struct gc* gc, uint64_t size) {
	return (struct opt_4) {1, .as1 = some_0(unmanaged_alloc_bytes(size))};
}
struct some_4 some_0(uint8_t* t) {
	return (struct some_4) {t};
}
uint8_t* todo_1() {
	return (assert(0),NULL);
}
struct gc* get_gc(struct ctx* ctx) {
	return get_gc_ctx_1(ctx)->gc;
}
struct gc_ctx* get_gc_ctx_1(struct ctx* ctx) {
	return (struct gc_ctx*) ctx->gc_ctx_ptr;
}
uint8_t then_void_0(struct ctx* ctx, struct fut_1* f, struct fun_mut1_2 cb) {
	struct fut_state_callbacks_1 cbs;
	struct fut_state_resolved_1 r;
	struct exception e;
	struct fut_state_1 matched;
	struct fut_callback_node_1* temp0;
	acquire_lock((&(f->lk)));
	matched = f->state;
	switch (matched.kind) {
		case 0:
			cbs = matched.as0;
			(f->state = (struct fut_state_1) {0, .as0 = (struct fut_state_callbacks_1) {(struct opt_3) {1, .as1 = some_1((temp0 = (struct fut_callback_node_1*) alloc(ctx, sizeof(struct fut_callback_node_1)), ((*(temp0) = (struct fut_callback_node_1) {cb, cbs.head}, 0), temp0)))}}}, 0);
			break;
		case 1:
			r = matched.as1;
			call_0(ctx, cb, (struct result_1) {0, .as0 = ok_0(r.value)});
			break;
		case 2:
			e = matched.as2;
			call_0(ctx, cb, (struct result_1) {1, .as1 = err_0(e)});
			break;
		default:
			(assert(0),0);
	}
	return release_lock((&(f->lk)));
}
struct some_3 some_1(struct fut_callback_node_1* t) {
	return (struct some_3) {t};
}
uint8_t call_0(struct ctx* ctx, struct fun_mut1_2 f, struct result_1 p0) {
	return call_with_ctx_0(ctx, f, p0);
}
uint8_t call_with_ctx_0(struct ctx* c, struct fun_mut1_2 f, struct result_1 p0) {
	return f.fun_ptr(c, f.closure, p0);
}
struct ok_1 ok_0(uint8_t t) {
	return (struct ok_1) {t};
}
struct err_0 err_0(struct exception t) {
	return (struct err_0) {t};
}
uint8_t forward_to(struct ctx* ctx, struct fut_0* from, struct fut_0* to) {
	struct forward_to__lambda0* temp0;
	return then_void_1(ctx, from, (struct fun_mut1_0) {(fun_ptr3_0) forward_to__lambda0, (uint8_t*) (temp0 = (struct forward_to__lambda0*) alloc(ctx, sizeof(struct forward_to__lambda0)), ((*(temp0) = (struct forward_to__lambda0) {to}, 0), temp0))});
}
uint8_t then_void_1(struct ctx* ctx, struct fut_0* f, struct fun_mut1_0 cb) {
	struct fut_state_callbacks_0 cbs;
	struct fut_state_resolved_0 r;
	struct exception e;
	struct fut_state_0 matched;
	struct fut_callback_node_0* temp0;
	acquire_lock((&(f->lk)));
	matched = f->state;
	switch (matched.kind) {
		case 0:
			cbs = matched.as0;
			(f->state = (struct fut_state_0) {0, .as0 = (struct fut_state_callbacks_0) {(struct opt_0) {1, .as1 = some_2((temp0 = (struct fut_callback_node_0*) alloc(ctx, sizeof(struct fut_callback_node_0)), ((*(temp0) = (struct fut_callback_node_0) {cb, cbs.head}, 0), temp0)))}}}, 0);
			break;
		case 1:
			r = matched.as1;
			call_1(ctx, cb, (struct result_0) {0, .as0 = ok_1(r.value)});
			break;
		case 2:
			e = matched.as2;
			call_1(ctx, cb, (struct result_0) {1, .as1 = err_0(e)});
			break;
		default:
			(assert(0),0);
	}
	return release_lock((&(f->lk)));
}
struct some_0 some_2(struct fut_callback_node_0* t) {
	return (struct some_0) {t};
}
uint8_t call_1(struct ctx* ctx, struct fun_mut1_0 f, struct result_0 p0) {
	return call_with_ctx_1(ctx, f, p0);
}
uint8_t call_with_ctx_1(struct ctx* c, struct fun_mut1_0 f, struct result_0 p0) {
	return f.fun_ptr(c, f.closure, p0);
}
struct ok_0 ok_1(int32_t t) {
	return (struct ok_0) {t};
}
uint8_t resolve_or_reject(struct ctx* ctx, struct fut_0* f, struct result_0 result) {
	struct fut_state_callbacks_0 cbs;
	struct fut_state_0 matched;
	struct ok_0 o;
	struct err_0 e;
	struct result_0 matched1;
	acquire_lock((&(f->lk)));
	matched = f->state;
	switch (matched.kind) {
		case 0:
			cbs = matched.as0;
			resolve_or_reject_recur(ctx, cbs.head, result);
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
	(f->state = (matched1 = result, matched1.kind == 0 ? (o = matched1.as0, (struct fut_state_0) {1, .as1 = (struct fut_state_resolved_0) {o.value}}) : matched1.kind == 1 ? (e = matched1.as1, (struct fut_state_0) {2, .as2 = e.value}) : (assert(0),(struct fut_state_0) {0})), 0);
	return release_lock((&(f->lk)));
}
uint8_t resolve_or_reject_recur(struct ctx* ctx, struct opt_0 node, struct result_0 value) {
	struct some_0 s;
	struct opt_0 matched;
	struct ctx* _tailCallctx;
	struct opt_0 _tailCallnode;
	struct result_0 _tailCallvalue;
	top:
	matched = node;
	switch (matched.kind) {
		case 0:
			return 0;
		case 1:
			s = matched.as1;
			drop_0(call_1(ctx, s.value->cb, value));
			_tailCallctx = ctx;
			_tailCallnode = s.value->next_node;
			_tailCallvalue = value;
			ctx = _tailCallctx;
			node = _tailCallnode;
			value = _tailCallvalue;
			goto top;
		default:
			return (assert(0),0);
	}
}
uint8_t drop_0(uint8_t t) {
	return 0;
}
uint8_t forward_to__lambda0(struct ctx* ctx, struct forward_to__lambda0* _closure, struct result_0 it) {
	return resolve_or_reject(ctx, _closure->to, it);
}
struct fut_0* call_2(struct ctx* ctx, struct fun_ref1 f, uint8_t p0) {
	struct vat* vat;
	struct fut_0* res;
	struct call_2__lambda0* temp0;
	vat = get_vat(ctx, f.vat_and_actor.vat);
	res = new_unresolved_fut(ctx);
	add_task(ctx, vat, (struct task) {f.vat_and_actor.actor, (struct fun_mut0_0) {(fun_ptr2_1) call_2__lambda0, (uint8_t*) (temp0 = (struct call_2__lambda0*) alloc(ctx, sizeof(struct call_2__lambda0)), ((*(temp0) = (struct call_2__lambda0) {f, p0, res}, 0), temp0))}});
	return res;
}
struct vat* get_vat(struct ctx* ctx, uint64_t vat_id) {
	return at_0(ctx, get_gctx(ctx)->vats, vat_id);
}
struct vat* at_0(struct ctx* ctx, struct arr_2 a, uint64_t index) {
	assert_0(ctx, _op_less_0(index, a.size));
	return noctx_at_0(a, index);
}
uint8_t assert_0(struct ctx* ctx, uint8_t condition) {
	return assert_1(ctx, condition, (struct arr_0) {13, "assert failed"});
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
	struct exception_ctx* exn_ctx;
	exn_ctx = get_exception_ctx(ctx);
	hard_forbid(null__q_1(exn_ctx->jmp_buf_ptr));
	(exn_ctx->thrown_exception = e, 0);
	(longjmp(exn_ctx->jmp_buf_ptr, number_to_throw(ctx)), 0);
	return todo_0();
}
struct exception_ctx* get_exception_ctx(struct ctx* ctx) {
	return (struct exception_ctx*) ctx->exception_ctx_ptr;
}
uint8_t null__q_1(struct jmp_buf_tag* a) {
	return _op_equal_equal_0((uint64_t) a, (uint64_t) NULL);
}
int32_t number_to_throw(struct ctx* ctx) {
	return seven_1();
}
int32_t seven_1() {
	return wrap_incr_1(six_1());
}
int32_t six_1() {
	return wrap_incr_1(five_1());
}
int32_t five_1() {
	return wrap_incr_1(four_1());
}
int32_t four_1() {
	return wrap_incr_1(three_1());
}
int32_t three_1() {
	return wrap_incr_1(two_1());
}
struct vat* noctx_at_0(struct arr_2 a, uint64_t index) {
	hard_assert(_op_less_0(index, a.size));
	return (*((a.data + index)));
}
uint8_t add_task(struct ctx* ctx, struct vat* v, struct task t) {
	struct mut_bag_node* node;
	node = new_mut_bag_node(ctx, t);
	acquire_lock((&(v->tasks_lock)));
	add_0((&(v->tasks)), node);
	release_lock((&(v->tasks_lock)));
	return broadcast((&(v->gctx->may_be_work_to_do)));
}
struct mut_bag_node* new_mut_bag_node(struct ctx* ctx, struct task value) {
	struct mut_bag_node* temp0;
	temp0 = (struct mut_bag_node*) alloc(ctx, sizeof(struct mut_bag_node));
	(*(temp0) = (struct mut_bag_node) {value, (struct opt_2) {0, .as0 = none()}}, 0);
	return temp0;
}
uint8_t add_0(struct mut_bag* bag, struct mut_bag_node* node) {
	(node->next_node = bag->head, 0);
	return (bag->head = (struct opt_2) {1, .as1 = some_3(node)}, 0);
}
struct some_2 some_3(struct mut_bag_node* t) {
	return (struct some_2) {t};
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
	struct exception old_thrown_exception;
	struct jmp_buf_tag* old_jmp_buf;
	struct jmp_buf_tag store;
	int32_t setjmp_result;
	uint8_t res;
	struct exception thrown_exception;
	old_thrown_exception = ec->thrown_exception;
	old_jmp_buf = ec->jmp_buf_ptr;
	store = (struct jmp_buf_tag) {zero_0(), 0, zero_3()};
	(ec->jmp_buf_ptr = (&(store)), 0);
	setjmp_result = setjmp(ec->jmp_buf_ptr);
	if (_op_equal_equal_2(setjmp_result, 0)) {
		res = call_3(ctx, try);
		(ec->jmp_buf_ptr = old_jmp_buf, 0);
		(ec->thrown_exception = old_thrown_exception, 0);
		return res;
	} else {
		assert_0(ctx, _op_equal_equal_2(setjmp_result, number_to_throw(ctx)));
		thrown_exception = ec->thrown_exception;
		(ec->jmp_buf_ptr = old_jmp_buf, 0);
		(ec->thrown_exception = old_thrown_exception, 0);
		return call_4(ctx, catcher, thrown_exception);
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
uint8_t then_0__lambda0(struct ctx* ctx, struct then_0__lambda0* _closure, struct result_1 result) {
	struct ok_1 o;
	struct err_0 e;
	struct result_1 matched;
	matched = result;
	switch (matched.kind) {
		case 0:
			o = matched.as0;
			return forward_to(ctx, call_2(ctx, _closure->cb, o.value), _closure->res);
		case 1:
			e = matched.as1;
			return reject(ctx, _closure->res, e.value);
		default:
			return (assert(0),0);
	}
}
struct fut_0* call_6(struct ctx* ctx, struct fun_ref0 f) {
	struct vat* vat;
	struct fut_0* res;
	struct call_6__lambda0* temp0;
	vat = get_vat(ctx, f.vat_and_actor.vat);
	res = new_unresolved_fut(ctx);
	add_task(ctx, vat, (struct task) {f.vat_and_actor.actor, (struct fun_mut0_0) {(fun_ptr2_1) call_6__lambda0, (uint8_t*) (temp0 = (struct call_6__lambda0*) alloc(ctx, sizeof(struct call_6__lambda0)), ((*(temp0) = (struct call_6__lambda0) {f, res}, 0), temp0))}});
	return res;
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
	struct ctx* c;
	c = ctx;
	return (struct vat_and_actor_id) {c->vat_id, c->actor_id};
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
	return forbid_1(ctx, condition, (struct arr_0) {13, "forbid failed"});
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
	return slice_0(ctx, a, begin, _op_minus_0(ctx, a.size, begin));
}
uint8_t _op_less_equal_0(uint64_t a, uint64_t b) {
	return !_op_less_0(b, a);
}
struct arr_3 slice_0(struct ctx* ctx, struct arr_3 a, uint64_t begin, uint64_t size) {
	assert_0(ctx, _op_less_equal_0(_op_plus_0(ctx, begin, size), a.size));
	return (struct arr_3) {size, (a.data + begin)};
}
uint64_t _op_plus_0(struct ctx* ctx, uint64_t a, uint64_t b) {
	uint64_t res;
	res = (a + b);
	assert_0(ctx, (_op_greater_equal(res, a) && _op_greater_equal(res, b)));
	return res;
}
uint8_t _op_greater_equal(uint64_t a, uint64_t b) {
	return !_op_less_0(a, b);
}
uint64_t _op_minus_0(struct ctx* ctx, uint64_t a, uint64_t b) {
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
	struct mut_arr_1* res;
	res = new_uninitialized_mut_arr_0(ctx, size);
	make_mut_arr_worker_0(ctx, res, 0, f);
	return res;
}
struct mut_arr_1* new_uninitialized_mut_arr_0(struct ctx* ctx, uint64_t size) {
	struct mut_arr_1* temp0;
	temp0 = (struct mut_arr_1*) alloc(ctx, sizeof(struct mut_arr_1));
	(*(temp0) = (struct mut_arr_1) {0, size, size, uninitialized_data_0(ctx, size)}, 0);
	return temp0;
}
struct arr_0* uninitialized_data_0(struct ctx* ctx, uint64_t size) {
	uint8_t* bptr;
	bptr = alloc(ctx, (size * sizeof(struct arr_0)));
	return (struct arr_0*) bptr;
}
uint8_t make_mut_arr_worker_0(struct ctx* ctx, struct mut_arr_1* m, uint64_t i, struct fun_mut1_5 f) {
	struct ctx* _tailCallctx;
	struct mut_arr_1* _tailCallm;
	uint64_t _tailCalli;
	struct fun_mut1_5 _tailCallf;
	top:
	if (_op_equal_equal_0(i, m->size)) {
		return 0;
	} else {
		set_at_0(ctx, m, i, call_8(ctx, f, i));
		_tailCallctx = ctx;
		_tailCallm = m;
		_tailCalli = incr_0(ctx, i);
		_tailCallf = f;
		ctx = _tailCallctx;
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
uint64_t incr_0(struct ctx* ctx, uint64_t n) {
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
	return noctx_at_1(a, index);
}
char* noctx_at_1(struct arr_3 a, uint64_t index) {
	hard_assert(_op_less_0(index, a.size));
	return (*((a.data + index)));
}
struct arr_0 map_0__lambda0(struct ctx* ctx, struct map_0__lambda0* _closure, uint64_t i) {
	return call_9(ctx, _closure->mapper, at_1(ctx, _closure->a, i));
}
struct arr_0 to_str_0(char* a) {
	return arr_from_begin_end(a, find_cstr_end(a));
}
struct arr_0 arr_from_begin_end(char* begin, char* end) {
	return (struct arr_0) {_op_minus_1(end, begin), begin};
}
uint64_t _op_minus_1(char* a, char* b) {
	return (uint64_t) (a - (uint64_t) b);
}
char* find_cstr_end(char* a) {
	return find_char_in_cstr(a, literal_0((struct arr_0) {1, "\0"}));
}
char* find_char_in_cstr(char* a, char c) {
	char* _tailCalla;
	char _tailCallc;
	top:
	if (_op_equal_equal_3((*(a)), c)) {
		return a;
	} else {
		if (_op_equal_equal_3((*(a)), literal_0((struct arr_0) {1, "\0"}))) {
			return todo_2();
		} else {
			_tailCalla = incr_1(a);
			_tailCallc = c;
			a = _tailCalla;
			c = _tailCallc;
			goto top;
		}
	}
}
uint8_t _op_equal_equal_3(char a, char b) {
	struct comparison matched;
	matched = compare_180(a, b);
	switch (matched.kind) {
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
struct comparison compare_180(char a, char b) {
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
	return noctx_at_2(a, 0);
}
char noctx_at_2(struct arr_0 a, uint64_t index) {
	hard_assert(_op_less_0(index, a.size));
	return (*((a.data + index)));
}
char* todo_2() {
	return (assert(0),NULL);
}
char* incr_1(char* p) {
	return (p + 1);
}
struct arr_0 add_first_task__lambda0__lambda0(struct ctx* ctx, uint8_t* _closure, char* it) {
	return to_str_0(it);
}
struct fut_0* add_first_task__lambda0(struct ctx* ctx, struct add_first_task__lambda0* _closure) {
	struct arr_3 args;
	args = tail_0(ctx, _closure->all_args);
	return _closure->main_ptr(ctx, map_0(ctx, args, (struct fun_mut1_4) {(fun_ptr3_4) add_first_task__lambda0__lambda0, (uint8_t*) null_any()}));
}
struct fut_0* do_main__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr_3 all_args, fun_ptr2_0 main_ptr) {
	return add_first_task(ctx, all_args, main_ptr);
}
struct fut_0* call_with_ctx_8(struct ctx* c, struct fun2 f, struct arr_3 p0, fun_ptr2_0 p1) {
	return f.fun_ptr(c, f.closure, p0, p1);
}
uint8_t run_threads(uint64_t n_threads, struct global_ctx* arg, fun_ptr2_3 fun) {
	uint64_t* threads;
	struct thread_args* thread_args;
	threads = unmanaged_alloc_elements_0(n_threads);
	thread_args = unmanaged_alloc_elements_1(n_threads);
	run_threads_recur(0, n_threads, threads, thread_args, arg, fun);
	join_threads_recur(0, n_threads, threads);
	unmanaged_free_0(threads);
	return unmanaged_free_1(thread_args);
}
struct thread_args* unmanaged_alloc_elements_1(uint64_t size_elements) {
	uint8_t* bytes;
	bytes = unmanaged_alloc_bytes((size_elements * sizeof(struct thread_args)));
	return (struct thread_args*) bytes;
}
uint8_t run_threads_recur(uint64_t i, uint64_t n_threads, uint64_t* threads, struct thread_args* thread_args, struct global_ctx* arg, fun_ptr2_3 fun) {
	struct thread_args* thread_arg_ptr;
	uint64_t* thread_ptr;
	fun_ptr1 fn;
	int32_t err;
	uint64_t _tailCalli;
	uint64_t _tailCalln_threads;
	uint64_t* _tailCallthreads;
	struct thread_args* _tailCallthread_args;
	struct global_ctx* _tailCallarg;
	fun_ptr2_3 _tailCallfun;
	top:
	if (_op_equal_equal_0(i, n_threads)) {
		return 0;
	} else {
		thread_arg_ptr = (thread_args + i);
		(*(thread_arg_ptr) = (struct thread_args) {fun, i, arg}, 0);
		thread_ptr = (threads + i);
		fn = run_threads_recur__lambda0;
		err = pthread_create(as_cell(thread_ptr), NULL, fn, (uint8_t*) thread_arg_ptr);
		if (zero__q_1(err)) {
			_tailCalli = noctx_incr(i);
			_tailCalln_threads = n_threads;
			_tailCallthreads = threads;
			_tailCallthread_args = thread_args;
			_tailCallarg = arg;
			_tailCallfun = fun;
			i = _tailCalli;
			n_threads = _tailCalln_threads;
			threads = _tailCallthreads;
			thread_args = _tailCallthread_args;
			arg = _tailCallarg;
			fun = _tailCallfun;
			goto top;
		} else {
			if (_op_equal_equal_2(err, eagain())) {
				return todo_0();
			} else {
				return todo_0();
			}
		}
	}
}
uint8_t* thread_fun(uint8_t* args_ptr) {
	struct thread_args* args;
	args = (struct thread_args*) args_ptr;
	args->fun(args->thread_id, args->arg);
	return NULL;
}
uint8_t* run_threads_recur__lambda0(uint8_t* args_ptr) {
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
	if (_op_equal_equal_0(i, n_threads)) {
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
	struct cell_1 thread_return;
	int32_t err;
	thread_return = (struct cell_1) {NULL};
	err = pthread_join(tid, (&(thread_return)));
	if (zero__q_1(err)) {
		0;
	} else {
		if (_op_equal_equal_2(err, einval())) {
			todo_0();
		} else {
			if (_op_equal_equal_2(err, esrch())) {
				todo_0();
			} else {
				todo_0();
			}
		}
	}
	return hard_assert(null__q_0(get_0((&(thread_return)))));
}
int32_t einval() {
	return ((ten_1() + ten_1()) + two_1());
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
uint8_t thread_function(uint64_t thread_id, struct global_ctx* gctx) {
	struct exception_ctx ectx;
	struct thread_local_stuff tls;
	ectx = new_exception_ctx();
	tls = (struct thread_local_stuff) {(&(ectx))};
	return thread_function_recur(thread_id, gctx, (&(tls)));
}
uint8_t thread_function_recur(uint64_t thread_id, struct global_ctx* gctx, struct thread_local_stuff* tls) {
	uint64_t last_checked;
	struct ok_2 ok_chosen_task;
	struct err_1 e;
	struct result_2 matched;
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
		last_checked = get_last_checked((&(gctx->may_be_work_to_do)));
		matched = choose_task(gctx);
		switch (matched.kind) {
			case 0:
				ok_chosen_task = matched.as0;
				do_task(gctx, tls, ok_chosen_task.value);
				break;
			case 1:
				e = matched.as1;
				if (e.value.last_thread_out) {
					hard_forbid(gctx->is_shut_down);
					(gctx->is_shut_down = 1, 0);
					broadcast((&(gctx->may_be_work_to_do)));
				} else {
					wait_on((&(gctx->may_be_work_to_do)), last_checked);
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
uint64_t noctx_decr_0(uint64_t n) {
	hard_forbid(zero__q_0(n));
	return (n - 1);
}
uint8_t assert_vats_are_shut_down(uint64_t i, struct arr_2 vats) {
	struct vat* vat;
	uint64_t _tailCalli;
	struct arr_2 _tailCallvats;
	top:
	if (_op_equal_equal_0(i, vats.size)) {
		return 0;
	} else {
		vat = noctx_at_0(vats, i);
		acquire_lock((&(vat->tasks_lock)));
		hard_forbid((&(vat->gc))->needs_gc);
		hard_assert(zero__q_0(vat->n_threads_running));
		hard_assert(empty__q_2((&(vat->tasks))));
		release_lock((&(vat->tasks_lock)));
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
	struct none n;
	struct some_2 s;
	struct opt_2 matched;
	matched = a;
	switch (matched.kind) {
		case 0:
			n = matched.as0;
			return 1;
		case 1:
			s = matched.as1;
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
	struct some_6 s;
	struct opt_6 matched;
	struct result_2 res;
	acquire_lock((&(gctx->lk)));
	res = (matched = choose_task_recur(gctx->vats, 0), matched.kind == 0 ? ((gctx->n_live_threads = noctx_decr_0(gctx->n_live_threads), 0), (struct result_2) {1, .as1 = err_1((struct no_chosen_task) {zero__q_0(gctx->n_live_threads)})}) : matched.kind == 1 ? (s = matched.as1, (struct result_2) {0, .as0 = ok_2(s.value)}) : (assert(0),(struct result_2) {0}));
	release_lock((&(gctx->lk)));
	return res;
}
struct opt_6 choose_task_recur(struct arr_2 vats, uint64_t i) {
	struct vat* vat;
	struct some_7 s;
	struct opt_7 matched;
	struct arr_2 _tailCallvats;
	uint64_t _tailCalli;
	top:
	if (_op_equal_equal_0(i, vats.size)) {
		return (struct opt_6) {0, .as0 = none()};
	} else {
		vat = noctx_at_0(vats, i);
		matched = choose_task_in_vat(vat);
		switch (matched.kind) {
			case 0:
				_tailCallvats = vats;
				_tailCalli = noctx_incr(i);
				vats = _tailCallvats;
				i = _tailCalli;
				goto top;
			case 1:
				s = matched.as1;
				return (struct opt_6) {1, .as1 = some_7((struct chosen_task) {vat, s.value})};
			default:
				return (assert(0),(struct opt_6) {0});
		}
	}
}
struct opt_7 choose_task_in_vat(struct vat* vat) {
	struct some_5 s;
	struct opt_5 matched;
	struct opt_7 res;
	acquire_lock((&(vat->tasks_lock)));
	res = ((&(vat->gc))->needs_gc ? (zero__q_0(vat->n_threads_running) ? (struct opt_7) {1, .as1 = some_4((struct opt_5) {0, .as0 = none()})} : (struct opt_7) {0, .as0 = none()}) : (matched = find_and_remove_first_doable_task(vat), matched.kind == 0 ? (struct opt_7) {0, .as0 = none()} : matched.kind == 1 ? (s = matched.as1, (struct opt_7) {1, .as1 = some_4((struct opt_5) {1, .as1 = some_6(s.value)})}) : (assert(0),(struct opt_7) {0})));
	if (empty__q_4(res)) {
		0;
	} else {
		(vat->n_threads_running = noctx_incr(vat->n_threads_running), 0);
	}
	release_lock((&(vat->tasks_lock)));
	return res;
}
struct some_7 some_4(struct opt_5 t) {
	return (struct some_7) {t};
}
struct opt_5 find_and_remove_first_doable_task(struct vat* vat) {
	struct mut_bag* tasks;
	struct opt_8 res;
	struct some_8 s;
	struct opt_8 matched;
	tasks = (&(vat->tasks));
	res = find_and_remove_first_doable_task_recur(vat, tasks->head);
	matched = res;
	switch (matched.kind) {
		case 0:
			return (struct opt_5) {0, .as0 = none()};
		case 1:
			s = matched.as1;
			(tasks->head = s.value.nodes, 0);
			return (struct opt_5) {1, .as1 = some_6(s.value.task)};
		default:
			return (assert(0),(struct opt_5) {0});
	}
}
struct opt_8 find_and_remove_first_doable_task_recur(struct vat* vat, struct opt_2 opt_node) {
	struct some_2 s;
	struct mut_bag_node* node;
	struct task task;
	struct mut_arr_0* actors;
	uint8_t task_ok;
	struct some_8 ss;
	struct task_and_nodes tn;
	struct opt_8 matched;
	struct opt_2 matched1;
	matched1 = opt_node;
	switch (matched1.kind) {
		case 0:
			return (struct opt_8) {0, .as0 = none()};
		case 1:
			s = matched1.as1;
			node = s.value;
			task = node->value;
			actors = (&(vat->currently_running_actors));
			task_ok = (contains__q_0(actors, task.actor_id) ? 0 : (push_capacity_must_be_sufficient(actors, task.actor_id), 1));
			if (task_ok) {
				return (struct opt_8) {1, .as1 = some_5((struct task_and_nodes) {task, node->next_node})};
			} else {
				matched = find_and_remove_first_doable_task_recur(vat, node->next_node);
				switch (matched.kind) {
					case 0:
						return (struct opt_8) {0, .as0 = none()};
					case 1:
						ss = matched.as1;
						tn = ss.value;
						(node->next_node = tn.nodes, 0);
						return (struct opt_8) {1, .as1 = some_5((struct task_and_nodes) {tn.task, (struct opt_2) {1, .as1 = some_3(node)}})};
					default:
						return (assert(0),(struct opt_8) {0});
				}
			}
		default:
			return (assert(0),(struct opt_8) {0});
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
	if (_op_equal_equal_0(i, a.size)) {
		return 0;
	} else {
		if (_op_equal_equal_0(noctx_at_3(a, i), value)) {
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
	uint64_t old_size;
	hard_assert(_op_less_0(a->size, a->capacity));
	old_size = a->size;
	(a->size = noctx_incr(old_size), 0);
	return noctx_set_at_1(a, old_size, value);
}
uint8_t noctx_set_at_1(struct mut_arr_0* a, uint64_t index, uint64_t value) {
	hard_assert(_op_less_0(index, a->size));
	return (*((a->data + index)) = value, 0);
}
struct some_8 some_5(struct task_and_nodes t) {
	return (struct some_8) {t};
}
struct some_5 some_6(struct task t) {
	return (struct some_5) {t};
}
uint8_t empty__q_4(struct opt_7 a) {
	struct none n;
	struct some_7 s;
	struct opt_7 matched;
	matched = a;
	switch (matched.kind) {
		case 0:
			n = matched.as0;
			return 1;
		case 1:
			s = matched.as1;
			return 0;
		default:
			return (assert(0),0);
	}
}
struct some_6 some_7(struct chosen_task t) {
	return (struct some_6) {t};
}
struct err_1 err_1(struct no_chosen_task t) {
	return (struct err_1) {t};
}
struct ok_2 ok_2(struct chosen_task t) {
	return (struct ok_2) {t};
}
uint8_t do_task(struct global_ctx* gctx, struct thread_local_stuff* tls, struct chosen_task chosen_task) {
	struct vat* vat;
	struct some_5 some_task;
	struct task task;
	struct ctx ctx;
	struct opt_5 matched;
	vat = chosen_task.vat;
	matched = chosen_task.task_or_gc;
	switch (matched.kind) {
		case 0:
			todo_0();
			broadcast((&(gctx->may_be_work_to_do)));
			break;
		case 1:
			some_task = matched.as1;
			task = some_task.value;
			ctx = new_ctx(gctx, tls, vat, task.actor_id);
			call_with_ctx_2((&(ctx)), task.fun);
			acquire_lock((&(vat->tasks_lock)));
			noctx_must_remove_unordered((&(vat->currently_running_actors)), task.actor_id);
			release_lock((&(vat->tasks_lock)));
			return_ctx((&(ctx)));
			break;
		default:
			(assert(0),0);
	}
	acquire_lock((&(vat->tasks_lock)));
	(vat->n_threads_running = noctx_decr_0(vat->n_threads_running), 0);
	return release_lock((&(vat->tasks_lock)));
}
uint8_t noctx_must_remove_unordered(struct mut_arr_0* a, uint64_t value) {
	return noctx_must_remove_unordered_recur(a, 0, value);
}
uint8_t noctx_must_remove_unordered_recur(struct mut_arr_0* a, uint64_t index, uint64_t value) {
	struct mut_arr_0* _tailCalla;
	uint64_t _tailCallindex;
	uint64_t _tailCallvalue;
	top:
	if (_op_equal_equal_0(index, a->size)) {
		return (assert(0),0);
	} else {
		if (_op_equal_equal_0(noctx_at_4(a, index), value)) {
			return drop_1(noctx_remove_unordered_at_index(a, index));
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
uint8_t drop_1(uint64_t t) {
	return 0;
}
uint64_t noctx_remove_unordered_at_index(struct mut_arr_0* a, uint64_t index) {
	uint64_t res;
	res = noctx_at_4(a, index);
	noctx_set_at_1(a, index, noctx_last(a));
	(a->size = noctx_decr_0(a->size), 0);
	return res;
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
	struct gc* gc;
	gc = gc_ctx->gc;
	acquire_lock((&(gc->lk)));
	(gc_ctx->next_ctx = gc->context_head, 0);
	(gc->context_head = (struct opt_1) {1, .as1 = some_8(gc_ctx)}, 0);
	return release_lock((&(gc->lk)));
}
struct some_1 some_8(struct gc_ctx* t) {
	return (struct some_1) {t};
}
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
uint8_t rt_main__lambda0(uint64_t thread_id, struct global_ctx* gctx) {
	return thread_function(thread_id, gctx);
}
struct result_0 must_be_resolved(struct fut_0* f) {
	struct fut_state_resolved_0 r;
	struct exception e;
	struct fut_state_0 matched;
	matched = f->state;
	switch (matched.kind) {
		case 0:
			return hard_unreachable_0();
		case 1:
			r = matched.as1;
			return (struct result_0) {0, .as0 = ok_1(r.value)};
		case 2:
			e = matched.as2;
			return (struct result_0) {1, .as1 = err_0(e)};
		default:
			return (assert(0),(struct result_0) {0});
	}
}
struct result_0 hard_unreachable_0() {
	return (assert(0),(struct result_0) {0});
}
struct fut_0* main_0(struct ctx* ctx, struct arr_1 args) {
	struct arr_1 arr;
	struct arr_1 option_names;
	struct opt_9 options;
	struct some_9 s;
	struct opt_9 matched;
	struct arr_0* temp0;
	option_names = (temp0 = (struct arr_0*) alloc(ctx, (sizeof(struct arr_0) * 3)), ((*((temp0 + 0)) = (struct arr_0) {11, "print-tests"}, 0), ((*((temp0 + 1)) = (struct arr_0) {16, "overwrite-output"}, 0), ((*((temp0 + 2)) = (struct arr_0) {12, "max-failures"}, 0), (struct arr_1) {3, temp0}))));
	options = parse_cmd_line_args(ctx, args, option_names, (struct fun1) {(fun_ptr3_6) main_0__lambda0, (uint8_t*) null_any()});
	return resolved_1(ctx, (matched = options, matched.kind == 0 ? (print_help(ctx), literal_2(ctx, (struct arr_0) {1, "1"})) : matched.kind == 1 ? (s = matched.as1, do_test(ctx, s.value)) : (assert(0),0)));
}
struct opt_9 parse_cmd_line_args(struct ctx* ctx, struct arr_1 args, struct arr_1 t_names, struct fun1 make_t) {
	struct parsed_cmd_line_args* parsed;
	struct mut_arr_3* values;
	struct cell_2* help;
	struct parse_cmd_line_args__lambda0* temp0;
	parsed = parse_cmd_line_args_dynamic(ctx, args);
	assert_1(ctx, empty__q_6(parsed->nameless), (struct arr_0) {26, "Should be no nameless args"});
	assert_0(ctx, empty__q_6(parsed->after));
	values = fill_mut_arr(ctx, t_names.size, (struct opt_10) {0, .as0 = none()});
	help = new_cell_0(ctx, 0);
	each_0(ctx, parsed->named, (struct fun_mut2_0) {(fun_ptr4_1) parse_cmd_line_args__lambda0, (uint8_t*) (temp0 = (struct parse_cmd_line_args__lambda0*) alloc(ctx, sizeof(struct parse_cmd_line_args__lambda0)), ((*(temp0) = (struct parse_cmd_line_args__lambda0) {t_names, help, values}, 0), temp0))});
	if (get_2(help)) {
		return (struct opt_9) {0, .as0 = none()};
	} else {
		return (struct opt_9) {1, .as1 = some_12(call_14(ctx, make_t, freeze_4(values)))};
	}
}
struct parsed_cmd_line_args* parse_cmd_line_args_dynamic(struct ctx* ctx, struct arr_1 args) {
	struct some_11 s;
	uint64_t first_named_arg_index;
	struct arr_1 nameless;
	struct arr_1 rest;
	struct some_11 s2;
	uint64_t sep_index;
	struct opt_11 matched;
	struct opt_11 matched1;
	struct parsed_cmd_line_args* temp0;
	struct parsed_cmd_line_args* temp1;
	struct parsed_cmd_line_args* temp2;
	matched1 = find_index(ctx, args, (struct fun_mut1_6) {(fun_ptr3_7) parse_cmd_line_args_dynamic__lambda0, (uint8_t*) null_any()});
	switch (matched1.kind) {
		case 0:
			temp0 = (struct parsed_cmd_line_args*) alloc(ctx, sizeof(struct parsed_cmd_line_args));
			(*(temp0) = (struct parsed_cmd_line_args) {args, empty_dict(ctx), empty_arr_1()}, 0);
			return temp0;
		case 1:
			s = matched1.as1;
			first_named_arg_index = s.value;
			nameless = slice_up_to_0(ctx, args, first_named_arg_index);
			rest = slice_starting_at_2(ctx, args, first_named_arg_index);
			matched = find_index(ctx, rest, (struct fun_mut1_6) {(fun_ptr3_7) parse_cmd_line_args_dynamic__lambda1, (uint8_t*) null_any()});
			switch (matched.kind) {
				case 0:
					temp1 = (struct parsed_cmd_line_args*) alloc(ctx, sizeof(struct parsed_cmd_line_args));
					(*(temp1) = (struct parsed_cmd_line_args) {nameless, parse_named_args(ctx, rest), empty_arr_1()}, 0);
					return temp1;
				case 1:
					s2 = matched.as1;
					sep_index = s2.value;
					temp2 = (struct parsed_cmd_line_args*) alloc(ctx, sizeof(struct parsed_cmd_line_args));
					(*(temp2) = (struct parsed_cmd_line_args) {nameless, parse_named_args(ctx, slice_up_to_0(ctx, rest, sep_index)), slice_after_0(ctx, rest, sep_index)}, 0);
					return temp2;
				default:
					return (assert(0),NULL);
			}
		default:
			return (assert(0),NULL);
	}
}
struct opt_11 find_index(struct ctx* ctx, struct arr_1 a, struct fun_mut1_6 pred) {
	return find_index_recur(ctx, a, 0, pred);
}
struct opt_11 find_index_recur(struct ctx* ctx, struct arr_1 a, uint64_t index, struct fun_mut1_6 pred) {
	struct ctx* _tailCallctx;
	struct arr_1 _tailCalla;
	uint64_t _tailCallindex;
	struct fun_mut1_6 _tailCallpred;
	top:
	if (_op_equal_equal_0(index, a.size)) {
		return (struct opt_11) {0, .as0 = none()};
	} else {
		if (call_10(ctx, pred, at_2(ctx, a, index))) {
			return (struct opt_11) {1, .as1 = some_9(index)};
		} else {
			_tailCallctx = ctx;
			_tailCalla = a;
			_tailCallindex = incr_0(ctx, index);
			_tailCallpred = pred;
			ctx = _tailCallctx;
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
struct some_11 some_9(uint64_t t) {
	return (struct some_11) {t};
}
uint8_t starts_with__q(struct ctx* ctx, struct arr_0 a, struct arr_0 start) {
	return (_op_greater_equal(a.size, start.size) && arr_eq__q(ctx, slice_1(ctx, a, 0, start.size), start));
}
uint8_t arr_eq__q(struct ctx* ctx, struct arr_0 a, struct arr_0 b) {
	struct ctx* _tailCallctx;
	struct arr_0 _tailCalla;
	struct arr_0 _tailCallb;
	top:
	if (_op_equal_equal_0(a.size, b.size)) {
		if (empty__q_0(a)) {
			return 1;
		} else {
			if (_op_equal_equal_3(first_0(ctx, a), first_0(ctx, b))) {
				_tailCallctx = ctx;
				_tailCalla = tail_1(ctx, a);
				_tailCallb = tail_1(ctx, b);
				ctx = _tailCallctx;
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
	return noctx_at_2(a, index);
}
struct arr_0 tail_1(struct ctx* ctx, struct arr_0 a) {
	forbid_0(ctx, empty__q_0(a));
	return slice_starting_at_1(ctx, a, 1);
}
struct arr_0 slice_starting_at_1(struct ctx* ctx, struct arr_0 a, uint64_t begin) {
	assert_0(ctx, _op_less_equal_0(begin, a.size));
	return slice_1(ctx, a, begin, _op_minus_0(ctx, a.size, begin));
}
struct arr_0 slice_1(struct ctx* ctx, struct arr_0 a, uint64_t begin, uint64_t size) {
	assert_0(ctx, _op_less_equal_0(_op_plus_0(ctx, begin, size), a.size));
	return (struct arr_0) {size, (a.data + begin)};
}
uint8_t parse_cmd_line_args_dynamic__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr_0 it) {
	return starts_with__q(ctx, it, (struct arr_0) {2, "--"});
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
	return slice_2(ctx, a, begin, _op_minus_0(ctx, a.size, begin));
}
uint8_t _op_equal_equal_4(struct arr_0 a, struct arr_0 b) {
	struct comparison matched;
	matched = compare_273(a, b);
	switch (matched.kind) {
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
struct comparison compare_273(struct arr_0 a, struct arr_0 b) {
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
			temp0 = compare_180((*(a.data)), (*(b.data)));
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
	return _op_equal_equal_4(it, (struct arr_0) {2, "--"});
}
struct dict_0* parse_named_args(struct ctx* ctx, struct arr_1 args) {
	struct mut_dict_0 b;
	b = new_mut_dict_0(ctx);
	parse_named_args_recur(ctx, args, b);
	return freeze_1(ctx, b);
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
	struct arr_0 first_name;
	struct arr_1 tl;
	struct some_11 s;
	uint64_t next_named_arg_index;
	struct opt_11 matched;
	struct ctx* _tailCallctx;
	struct arr_1 _tailCallargs;
	struct mut_dict_0 _tailCallbuilder;
	top:
	first_name = remove_start(ctx, first_1(ctx, args), (struct arr_0) {2, "--"});
	tl = tail_2(ctx, args);
	matched = find_index(ctx, tl, (struct fun_mut1_6) {(fun_ptr3_7) parse_named_args_recur__lambda0, (uint8_t*) null_any()});
	switch (matched.kind) {
		case 0:
			return add_1(ctx, builder, first_name, tl);
		case 1:
			s = matched.as1;
			next_named_arg_index = s.value;
			add_1(ctx, builder, first_name, slice_up_to_0(ctx, tl, next_named_arg_index));
			_tailCallctx = ctx;
			_tailCallargs = slice_starting_at_2(ctx, args, next_named_arg_index);
			_tailCallbuilder = builder;
			ctx = _tailCallctx;
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
struct arr_0 force(struct ctx* ctx, struct opt_12 a) {
	struct none n;
	struct some_12 s;
	struct opt_12 matched;
	matched = a;
	switch (matched.kind) {
		case 0:
			n = matched.as0;
			return fail_1(ctx, (struct arr_0) {27, "tried to force empty option"});
		case 1:
			s = matched.as1;
			return s.value;
		default:
			return (assert(0),(struct arr_0) {0, NULL});
	}
}
struct arr_0 fail_1(struct ctx* ctx, struct arr_0 reason) {
	return throw_1(ctx, (struct exception) {reason});
}
struct arr_0 throw_1(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx;
	exn_ctx = get_exception_ctx(ctx);
	hard_forbid(null__q_1(exn_ctx->jmp_buf_ptr));
	(exn_ctx->thrown_exception = e, 0);
	(longjmp(exn_ctx->jmp_buf_ptr, number_to_throw(ctx)), 0);
	return todo_3();
}
struct arr_0 todo_3() {
	return (assert(0),(struct arr_0) {0, NULL});
}
struct opt_12 try_remove_start(struct ctx* ctx, struct arr_0 a, struct arr_0 start) {
	if (starts_with__q(ctx, a, start)) {
		return (struct opt_12) {1, .as1 = some_10(slice_starting_at_1(ctx, a, start.size))};
	} else {
		return (struct opt_12) {0, .as0 = none()};
	}
}
struct some_12 some_10(struct arr_0 t) {
	return (struct some_12) {t};
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
	return starts_with__q(ctx, it, (struct arr_0) {2, "--"});
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
uint8_t has__q_2(struct opt_10 a) {
	return !empty__q_7(a);
}
uint8_t empty__q_7(struct opt_10 a) {
	struct none n;
	struct some_10 s;
	struct opt_10 matched;
	matched = a;
	switch (matched.kind) {
		case 0:
			n = matched.as0;
			return 1;
		case 1:
			s = matched.as1;
			return 0;
		default:
			return (assert(0),0);
	}
}
struct opt_10 get_1(struct ctx* ctx, struct dict_0* d, struct arr_0 key) {
	return get_recursive_0(ctx, d->keys, d->values, 0, key);
}
struct opt_10 get_recursive_0(struct ctx* ctx, struct arr_1 keys, struct arr_6 values, uint64_t idx, struct arr_0 key) {
	struct ctx* _tailCallctx;
	struct arr_1 _tailCallkeys;
	struct arr_6 _tailCallvalues;
	uint64_t _tailCallidx;
	struct arr_0 _tailCallkey;
	top:
	if (_op_equal_equal_0(idx, keys.size)) {
		return (struct opt_10) {0, .as0 = none()};
	} else {
		if (_op_equal_equal_4(key, at_2(ctx, keys, idx))) {
			return (struct opt_10) {1, .as1 = some_11(at_4(ctx, values, idx))};
		} else {
			_tailCallctx = ctx;
			_tailCallkeys = keys;
			_tailCallvalues = values;
			_tailCallidx = incr_0(ctx, idx);
			_tailCallkey = key;
			ctx = _tailCallctx;
			keys = _tailCallkeys;
			values = _tailCallvalues;
			idx = _tailCallidx;
			key = _tailCallkey;
			goto top;
		}
	}
}
struct some_10 some_11(struct arr_1 t) {
	return (struct some_10) {t};
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
	if (_op_equal_equal_0(a->size, a->capacity)) {
		increase_capacity_to_0(ctx, a, (zero__q_0(a->size) ? four_0() : _op_times_0(ctx, a->size, two_0())));
	} else {
		0;
	}
	ensure_capacity_0(ctx, a, round_up_to_power_of_two(ctx, incr_0(ctx, a->size)));
	assert_0(ctx, _op_less_0(a->size, a->capacity));
	(*((a->data + a->size)) = value, 0);
	return (a->size = incr_0(ctx, a->size), 0);
}
uint8_t increase_capacity_to_0(struct ctx* ctx, struct mut_arr_1* a, uint64_t new_capacity) {
	struct arr_0* old_data;
	assert_0(ctx, _op_greater_0(new_capacity, a->capacity));
	old_data = a->data;
	(a->capacity = new_capacity, 0);
	(a->data = uninitialized_data_0(ctx, new_capacity), 0);
	return copy_data_from_0(ctx, a->data, old_data, a->size);
}
uint8_t copy_data_from_0(struct ctx* ctx, struct arr_0* to, struct arr_0* from, uint64_t len) {
	uint64_t hl;
	struct ctx* _tailCallctx;
	struct arr_0* _tailCallto;
	struct arr_0* _tailCallfrom;
	uint64_t _tailCalllen;
	top:
	if (_op_less_0(len, eight_0())) {
		return copy_data_from_small_0(ctx, to, from, len);
	} else {
		hl = _op_div(ctx, len, two_0());
		copy_data_from_0(ctx, to, from, hl);
		_tailCallctx = ctx;
		_tailCallto = (to + hl);
		_tailCallfrom = (from + hl);
		_tailCalllen = _op_minus_0(ctx, len, hl);
		ctx = _tailCallctx;
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
	uint64_t res;
	if ((zero__q_0(a) || zero__q_0(b))) {
		return 0;
	} else {
		res = (a * b);
		assert_0(ctx, _op_equal_equal_0(_op_div(ctx, res, b), a));
		assert_0(ctx, _op_equal_equal_0(_op_div(ctx, res, a), b));
		return res;
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
	struct ctx* _tailCallctx;
	uint64_t _tailCallacc;
	uint64_t _tailCalln;
	top:
	if (_op_greater_equal(acc, n)) {
		return acc;
	} else {
		_tailCallctx = ctx;
		_tailCallacc = _op_times_0(ctx, acc, two_0());
		_tailCalln = n;
		ctx = _tailCallctx;
		acc = _tailCallacc;
		n = _tailCalln;
		goto top;
	}
}
uint8_t push_1(struct ctx* ctx, struct mut_arr_2* a, struct arr_1 value) {
	if (_op_equal_equal_0(a->size, a->capacity)) {
		increase_capacity_to_1(ctx, a, (zero__q_0(a->size) ? four_0() : _op_times_0(ctx, a->size, two_0())));
	} else {
		0;
	}
	ensure_capacity_1(ctx, a, round_up_to_power_of_two(ctx, incr_0(ctx, a->size)));
	assert_0(ctx, _op_less_0(a->size, a->capacity));
	(*((a->data + a->size)) = value, 0);
	return (a->size = incr_0(ctx, a->size), 0);
}
uint8_t increase_capacity_to_1(struct ctx* ctx, struct mut_arr_2* a, uint64_t new_capacity) {
	struct arr_1* old_data;
	assert_0(ctx, _op_greater_0(new_capacity, a->capacity));
	old_data = a->data;
	(a->capacity = new_capacity, 0);
	(a->data = uninitialized_data_1(ctx, new_capacity), 0);
	return copy_data_from_1(ctx, a->data, old_data, a->size);
}
struct arr_1* uninitialized_data_1(struct ctx* ctx, uint64_t size) {
	uint8_t* bptr;
	bptr = alloc(ctx, (size * sizeof(struct arr_1)));
	return (struct arr_1*) bptr;
}
uint8_t copy_data_from_1(struct ctx* ctx, struct arr_1* to, struct arr_1* from, uint64_t len) {
	uint64_t hl;
	struct ctx* _tailCallctx;
	struct arr_1* _tailCallto;
	struct arr_1* _tailCallfrom;
	uint64_t _tailCalllen;
	top:
	if (_op_less_0(len, eight_0())) {
		return copy_data_from_small_1(ctx, to, from, len);
	} else {
		hl = _op_div(ctx, len, two_0());
		copy_data_from_1(ctx, to, from, hl);
		_tailCallctx = ctx;
		_tailCallto = (to + hl);
		_tailCallfrom = (from + hl);
		_tailCalllen = _op_minus_0(ctx, len, hl);
		ctx = _tailCallctx;
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
	return slice_starting_at_2(ctx, a, incr_0(ctx, before_begin));
}
struct mut_arr_3* fill_mut_arr(struct ctx* ctx, uint64_t size, struct opt_10 value) {
	struct fill_mut_arr__lambda0* temp0;
	return make_mut_arr_1(ctx, size, (struct fun_mut1_7) {(fun_ptr3_8) fill_mut_arr__lambda0, (uint8_t*) (temp0 = (struct fill_mut_arr__lambda0*) alloc(ctx, sizeof(struct fill_mut_arr__lambda0)), ((*(temp0) = (struct fill_mut_arr__lambda0) {value}, 0), temp0))});
}
struct mut_arr_3* make_mut_arr_1(struct ctx* ctx, uint64_t size, struct fun_mut1_7 f) {
	struct mut_arr_3* res;
	res = new_uninitialized_mut_arr_1(ctx, size);
	make_mut_arr_worker_1(ctx, res, 0, f);
	return res;
}
struct mut_arr_3* new_uninitialized_mut_arr_1(struct ctx* ctx, uint64_t size) {
	struct mut_arr_3* temp0;
	temp0 = (struct mut_arr_3*) alloc(ctx, sizeof(struct mut_arr_3));
	(*(temp0) = (struct mut_arr_3) {0, size, size, uninitialized_data_2(ctx, size)}, 0);
	return temp0;
}
struct opt_10* uninitialized_data_2(struct ctx* ctx, uint64_t size) {
	uint8_t* bptr;
	bptr = alloc(ctx, (size * sizeof(struct opt_10)));
	return (struct opt_10*) bptr;
}
uint8_t make_mut_arr_worker_1(struct ctx* ctx, struct mut_arr_3* m, uint64_t i, struct fun_mut1_7 f) {
	struct ctx* _tailCallctx;
	struct mut_arr_3* _tailCallm;
	uint64_t _tailCalli;
	struct fun_mut1_7 _tailCallf;
	top:
	if (_op_equal_equal_0(i, m->size)) {
		return 0;
	} else {
		set_at_1(ctx, m, i, call_11(ctx, f, i));
		_tailCallctx = ctx;
		_tailCallm = m;
		_tailCalli = incr_0(ctx, i);
		_tailCallf = f;
		ctx = _tailCallctx;
		m = _tailCallm;
		i = _tailCalli;
		f = _tailCallf;
		goto top;
	}
}
uint8_t set_at_1(struct ctx* ctx, struct mut_arr_3* a, uint64_t index, struct opt_10 value) {
	assert_0(ctx, _op_less_0(index, a->size));
	return noctx_set_at_2(a, index, value);
}
uint8_t noctx_set_at_2(struct mut_arr_3* a, uint64_t index, struct opt_10 value) {
	hard_assert(_op_less_0(index, a->size));
	return (*((a->data + index)) = value, 0);
}
struct opt_10 call_11(struct ctx* ctx, struct fun_mut1_7 f, uint64_t p0) {
	return call_with_ctx_10(ctx, f, p0);
}
struct opt_10 call_with_ctx_10(struct ctx* c, struct fun_mut1_7 f, uint64_t p0) {
	return f.fun_ptr(c, f.closure, p0);
}
struct opt_10 fill_mut_arr__lambda0(struct ctx* ctx, struct fill_mut_arr__lambda0* _closure, uint64_t ignore) {
	return _closure->value;
}
struct cell_2* new_cell_0(struct ctx* ctx, uint8_t value) {
	struct cell_2* temp0;
	temp0 = (struct cell_2*) alloc(ctx, sizeof(struct cell_2));
	(*(temp0) = (struct cell_2) {value}, 0);
	return temp0;
}
uint8_t each_0(struct ctx* ctx, struct dict_0* d, struct fun_mut2_0 f) {
	struct dict_0* temp0;
	struct ctx* _tailCallctx;
	struct dict_0* _tailCalld;
	struct fun_mut2_0 _tailCallf;
	top:
	if (empty__q_8(ctx, d)) {
		return 0;
	} else {
		call_12(ctx, f, first_1(ctx, d->keys), first_2(ctx, d->values));
		_tailCallctx = ctx;
		_tailCalld = (temp0 = (struct dict_0*) alloc(ctx, sizeof(struct dict_0)), ((*(temp0) = (struct dict_0) {tail_2(ctx, d->keys), tail_3(ctx, d->values)}, 0), temp0));
		_tailCallf = f;
		ctx = _tailCallctx;
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
	return slice_3(ctx, a, begin, _op_minus_0(ctx, a.size, begin));
}
struct arr_6 slice_3(struct ctx* ctx, struct arr_6 a, uint64_t begin, uint64_t size) {
	assert_0(ctx, _op_less_equal_0(_op_plus_0(ctx, begin, size), a.size));
	return (struct arr_6) {size, (a.data + begin)};
}
struct opt_11 index_of(struct ctx* ctx, struct arr_1 a, struct arr_0 value) {
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
	struct mut_arr_4* res;
	res = new_uninitialized_mut_arr_2(ctx, size);
	make_mut_arr_worker_2(ctx, res, 0, f);
	return res;
}
struct mut_arr_4* new_uninitialized_mut_arr_2(struct ctx* ctx, uint64_t size) {
	struct mut_arr_4* temp0;
	temp0 = (struct mut_arr_4*) alloc(ctx, sizeof(struct mut_arr_4));
	(*(temp0) = (struct mut_arr_4) {0, size, size, uninitialized_data_3(ctx, size)}, 0);
	return temp0;
}
char* uninitialized_data_3(struct ctx* ctx, uint64_t size) {
	uint8_t* bptr;
	bptr = alloc(ctx, (size * sizeof(char)));
	return (char*) bptr;
}
uint8_t make_mut_arr_worker_2(struct ctx* ctx, struct mut_arr_4* m, uint64_t i, struct fun_mut1_8 f) {
	struct ctx* _tailCallctx;
	struct mut_arr_4* _tailCallm;
	uint64_t _tailCalli;
	struct fun_mut1_8 _tailCallf;
	top:
	if (_op_equal_equal_0(i, m->size)) {
		return 0;
	} else {
		set_at_2(ctx, m, i, call_13(ctx, f, i));
		_tailCallctx = ctx;
		_tailCallm = m;
		_tailCalli = incr_0(ctx, i);
		_tailCallf = f;
		ctx = _tailCallctx;
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
		return at_3(ctx, _closure->b, _op_minus_0(ctx, i, _closure->a.size));
	}
}
struct opt_10 at_5(struct ctx* ctx, struct mut_arr_3* a, uint64_t index) {
	assert_0(ctx, _op_less_0(index, a->size));
	return noctx_at_7(a, index);
}
struct opt_10 noctx_at_7(struct mut_arr_3* a, uint64_t index) {
	hard_assert(_op_less_0(index, a->size));
	return (*((a->data + index)));
}
uint8_t parse_cmd_line_args__lambda0(struct ctx* ctx, struct parse_cmd_line_args__lambda0* _closure, struct arr_0 key, struct arr_1 value) {
	struct some_11 s;
	uint64_t idx;
	struct opt_11 matched;
	matched = index_of(ctx, _closure->t_names, key);
	switch (matched.kind) {
		case 0:
			if (_op_equal_equal_4(key, (struct arr_0) {4, "help"})) {
				return set_0(_closure->help, 1);
			} else {
				return fail_0(ctx, _op_plus_1(ctx, (struct arr_0) {15, "Unexpected arg "}, key));
			}
		case 1:
			s = matched.as1;
			idx = s.value;
			forbid_0(ctx, has__q_2(at_5(ctx, _closure->values, idx)));
			return set_at_1(ctx, _closure->values, idx, (struct opt_10) {1, .as1 = some_11(value)});
		default:
			return (assert(0),0);
	}
}
uint8_t get_2(struct cell_2* c) {
	return c->value;
}
struct some_9 some_12(struct test_options t) {
	return (struct some_9) {t};
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
struct opt_10 at_6(struct ctx* ctx, struct arr_5 a, uint64_t index) {
	assert_0(ctx, _op_less_0(index, a.size));
	return noctx_at_8(a, index);
}
struct opt_10 noctx_at_8(struct arr_5 a, uint64_t index) {
	hard_assert(_op_less_0(index, a.size));
	return (*((a.data + index)));
}
uint64_t literal_1(struct ctx* ctx, struct arr_0 s) {
	uint64_t higher_digits;
	if (empty__q_0(s)) {
		return 0;
	} else {
		higher_digits = literal_1(ctx, rtail(ctx, s));
		return _op_plus_0(ctx, _op_times_0(ctx, higher_digits, ten_0()), char_to_nat(last(ctx, s)));
	}
}
struct arr_0 rtail(struct ctx* ctx, struct arr_0 a) {
	forbid_0(ctx, empty__q_0(a));
	return slice_1(ctx, a, 0, decr(ctx, a.size));
}
uint64_t char_to_nat(char c) {
	if (_op_equal_equal_3(c, literal_0((struct arr_0) {1, "0"}))) {
		return 0;
	} else {
		if (_op_equal_equal_3(c, literal_0((struct arr_0) {1, "1"}))) {
			return 1;
		} else {
			if (_op_equal_equal_3(c, literal_0((struct arr_0) {1, "2"}))) {
				return two_0();
			} else {
				if (_op_equal_equal_3(c, literal_0((struct arr_0) {1, "3"}))) {
					return three_0();
				} else {
					if (_op_equal_equal_3(c, literal_0((struct arr_0) {1, "4"}))) {
						return four_0();
					} else {
						if (_op_equal_equal_3(c, literal_0((struct arr_0) {1, "5"}))) {
							return five_0();
						} else {
							if (_op_equal_equal_3(c, literal_0((struct arr_0) {1, "6"}))) {
								return six_0();
							} else {
								if (_op_equal_equal_3(c, literal_0((struct arr_0) {1, "7"}))) {
									return seven_0();
								} else {
									if (_op_equal_equal_3(c, literal_0((struct arr_0) {1, "8"}))) {
										return eight_0();
									} else {
										if (_op_equal_equal_3(c, literal_0((struct arr_0) {1, "9"}))) {
											return nine_0();
										} else {
											return todo_4();
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
uint64_t todo_4() {
	return (assert(0),0);
}
char last(struct ctx* ctx, struct arr_0 a) {
	forbid_0(ctx, empty__q_0(a));
	return at_3(ctx, a, decr(ctx, a.size));
}
struct test_options main_0__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr_5 values) {
	struct opt_10 print_tests_strs;
	struct opt_10 overwrite_output_strs;
	struct opt_10 max_failures_strs;
	uint8_t print_tests__q;
	struct some_10 s;
	struct opt_10 matched;
	uint8_t overwrite_output__q;
	struct some_10 s1;
	struct arr_1 strs;
	struct opt_10 matched1;
	uint64_t max_failures;
	print_tests_strs = at_6(ctx, values, literal_1(ctx, (struct arr_0) {1, "0"}));
	overwrite_output_strs = at_6(ctx, values, literal_1(ctx, (struct arr_0) {1, "1"}));
	max_failures_strs = at_6(ctx, values, literal_1(ctx, (struct arr_0) {1, "2"}));
	print_tests__q = has__q_2(print_tests_strs);
	overwrite_output__q = (matched = overwrite_output_strs, matched.kind == 0 ? 0 : matched.kind == 1 ? (s = matched.as1, (assert_0(ctx, empty__q_6(s.value)), 1)) : (assert(0),0));
	max_failures = (matched1 = max_failures_strs, matched1.kind == 0 ? literal_1(ctx, (struct arr_0) {3, "100"}) : matched1.kind == 1 ? (s1 = matched1.as1, (strs = s1.value, (assert_0(ctx, _op_equal_equal_0(strs.size, literal_1(ctx, (struct arr_0) {1, "1"}))), literal_1(ctx, first_1(ctx, strs))))) : (assert(0),0));
	return (struct test_options) {print_tests__q, overwrite_output__q, max_failures};
}
struct fut_0* resolved_1(struct ctx* ctx, int32_t value) {
	struct fut_0* temp0;
	temp0 = (struct fut_0*) alloc(ctx, sizeof(struct fut_0));
	(*(temp0) = (struct fut_0) {new_lock(), (struct fut_state_0) {1, .as1 = (struct fut_state_resolved_0) {value}}}, 0);
	return temp0;
}
uint8_t print_help(struct ctx* ctx) {
	print_sync((struct arr_0) {18, "test -- runs tests"});
	print_sync((struct arr_0) {8, "options:"});
	print_sync((struct arr_0) {38, "\t--print-tests  : print every test run"});
	return print_sync((struct arr_0) {64, "\t--max-failures : stop after this many failures. Defaults to 10."});
}
uint8_t print_sync(struct arr_0 s) {
	print_sync_no_newline(s);
	return print_sync_no_newline((struct arr_0) {1, "\n"});
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
	char fst;
	uint64_t n;
	fst = at_3(ctx, s, 0);
	if (_op_equal_equal_3(fst, literal_0((struct arr_0) {1, "-"}))) {
		n = literal_1(ctx, tail_1(ctx, s));
		return neg_0(ctx, n);
	} else {
		if (_op_equal_equal_3(fst, literal_0((struct arr_0) {1, "+"}))) {
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
	struct comparison matched;
	matched = compare_28(a, b);
	switch (matched.kind) {
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
	struct arr_0 test_path;
	struct arr_0 noze_path;
	struct arr_0 noze_exe;
	struct dict_1* env;
	struct result_3 noze_failures;
	struct result_3 all_failures;
	struct do_test__lambda0* temp0;
	struct do_test__lambda1* temp1;
	test_path = parent_path(ctx, current_executable_path(ctx));
	noze_path = parent_path(ctx, test_path);
	noze_exe = child_path(ctx, child_path(ctx, noze_path, (struct arr_0) {3, "bin"}), (struct arr_0) {4, "noze"});
	env = get_environ(ctx);
	noze_failures = first_failures(ctx, run_noze_tests(ctx, child_path(ctx, test_path, (struct arr_0) {12, "parse-errors"}), noze_exe, env, options), (struct fun0) {(fun_ptr2_4) do_test__lambda0, (uint8_t*) (temp0 = (struct do_test__lambda0*) alloc(ctx, sizeof(struct do_test__lambda0)), ((*(temp0) = (struct do_test__lambda0) {test_path, noze_exe, env, options}, 0), temp0))});
	all_failures = first_failures(ctx, noze_failures, (struct fun0) {(fun_ptr2_4) do_test__lambda1, (uint8_t*) (temp1 = (struct do_test__lambda1*) alloc(ctx, sizeof(struct do_test__lambda1)), ((*(temp1) = (struct do_test__lambda1) {noze_path, options}, 0), temp1))});
	return print_failures(ctx, all_failures, options);
}
struct arr_0 parent_path(struct ctx* ctx, struct arr_0 a) {
	struct some_11 s;
	struct opt_11 matched;
	matched = r_index_of(ctx, a, literal_0((struct arr_0) {1, "/"}));
	switch (matched.kind) {
		case 0:
			return (struct arr_0) {0, ""};
		case 1:
			s = matched.as1;
			return slice_up_to_1(ctx, a, s.value);
		default:
			return (assert(0),(struct arr_0) {0, NULL});
	}
}
struct opt_11 r_index_of(struct ctx* ctx, struct arr_0 a, char value) {
	struct r_index_of__lambda0* temp0;
	return find_rindex(ctx, a, (struct fun_mut1_9) {(fun_ptr3_10) r_index_of__lambda0, (uint8_t*) (temp0 = (struct r_index_of__lambda0*) alloc(ctx, sizeof(struct r_index_of__lambda0)), ((*(temp0) = (struct r_index_of__lambda0) {value}, 0), temp0))});
}
struct opt_11 find_rindex(struct ctx* ctx, struct arr_0 a, struct fun_mut1_9 pred) {
	if (empty__q_0(a)) {
		return (struct opt_11) {0, .as0 = none()};
	} else {
		return find_rindex_recur(ctx, a, decr(ctx, a.size), pred);
	}
}
struct opt_11 find_rindex_recur(struct ctx* ctx, struct arr_0 a, uint64_t index, struct fun_mut1_9 pred) {
	struct ctx* _tailCallctx;
	struct arr_0 _tailCalla;
	uint64_t _tailCallindex;
	struct fun_mut1_9 _tailCallpred;
	top:
	if (call_15(ctx, pred, at_3(ctx, a, index))) {
		return (struct opt_11) {1, .as1 = some_9(index)};
	} else {
		if (zero__q_0(index)) {
			return (struct opt_11) {0, .as0 = none()};
		} else {
			_tailCallctx = ctx;
			_tailCalla = a;
			_tailCallindex = decr(ctx, index);
			_tailCallpred = pred;
			ctx = _tailCallctx;
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
	return _op_equal_equal_3(it, _closure->value);
}
struct arr_0 slice_up_to_1(struct ctx* ctx, struct arr_0 a, uint64_t size) {
	assert_0(ctx, _op_less_0(size, a.size));
	return slice_1(ctx, a, 0, size);
}
struct arr_0 current_executable_path(struct ctx* ctx) {
	return read_link(ctx, (struct arr_0) {14, "/proc/self/exe"});
}
struct arr_0 read_link(struct ctx* ctx, struct arr_0 path) {
	struct mut_arr_4* buff;
	int64_t size;
	buff = new_uninitialized_mut_arr_2(ctx, thousand_0());
	size = readlink(to_c_str(ctx, path), buff->data, buff->size);
	check_errno_if_neg_one(ctx, size);
	return slice_up_to_1(ctx, freeze_3(buff), to_nat_0(ctx, size));
}
char* to_c_str(struct ctx* ctx, struct arr_0 a) {
	return _op_plus_1(ctx, a, (struct arr_0) {1, "\0"}).data;
}
uint8_t check_errno_if_neg_one(struct ctx* ctx, int64_t e) {
	if (_op_equal_equal_1(e, neg_one_0())) {
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
	return _op_plus_1(ctx, _op_plus_1(ctx, a, (struct arr_0) {1, "/"}), child_name);
}
struct dict_1* get_environ(struct ctx* ctx) {
	struct mut_dict_1 res;
	res = new_mut_dict_1(ctx);
	get_environ_recur(ctx, environ, res);
	return freeze_5(ctx, res);
}
struct mut_dict_1 new_mut_dict_1(struct ctx* ctx) {
	return (struct mut_dict_1) {new_mut_arr_0(ctx), new_mut_arr_0(ctx)};
}
uint8_t get_environ_recur(struct ctx* ctx, char** env, struct mut_dict_1 res) {
	struct ctx* _tailCallctx;
	char** _tailCallenv;
	struct mut_dict_1 _tailCallres;
	top:
	if (null__q_2((*(env)))) {
		return 0;
	} else {
		add_2(ctx, res, parse_environ_entry(ctx, (*(env))));
		_tailCallctx = ctx;
		_tailCallenv = incr_4(env);
		_tailCallres = res;
		ctx = _tailCallctx;
		env = _tailCallenv;
		res = _tailCallres;
		goto top;
	}
}
uint8_t null__q_2(char* a) {
	return _op_equal_equal_0((uint64_t) a, (uint64_t) NULL);
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
uint8_t has__q_5(struct opt_12 a) {
	return !empty__q_10(a);
}
uint8_t empty__q_10(struct opt_12 a) {
	struct none n;
	struct some_12 s;
	struct opt_12 matched;
	matched = a;
	switch (matched.kind) {
		case 0:
			n = matched.as0;
			return 1;
		case 1:
			s = matched.as1;
			return 0;
		default:
			return (assert(0),0);
	}
}
struct opt_12 get_3(struct ctx* ctx, struct dict_1* d, struct arr_0 key) {
	return get_recursive_1(ctx, d->keys, d->values, 0, key);
}
struct opt_12 get_recursive_1(struct ctx* ctx, struct arr_1 keys, struct arr_1 values, uint64_t idx, struct arr_0 key) {
	struct ctx* _tailCallctx;
	struct arr_1 _tailCallkeys;
	struct arr_1 _tailCallvalues;
	uint64_t _tailCallidx;
	struct arr_0 _tailCallkey;
	top:
	if (_op_equal_equal_0(idx, keys.size)) {
		return (struct opt_12) {0, .as0 = none()};
	} else {
		if (_op_equal_equal_4(key, at_2(ctx, keys, idx))) {
			return (struct opt_12) {1, .as1 = some_10(at_2(ctx, values, idx))};
		} else {
			_tailCallctx = ctx;
			_tailCallkeys = keys;
			_tailCallvalues = values;
			_tailCallidx = incr_0(ctx, idx);
			_tailCallkey = key;
			ctx = _tailCallctx;
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
	char* key_end;
	struct arr_0 key;
	char* value_begin;
	char* value_end;
	struct arr_0 value;
	struct key_value_pair* temp0;
	key_end = find_char_in_cstr(entry, literal_0((struct arr_0) {1, "="}));
	key = arr_from_begin_end(entry, key_end);
	value_begin = incr_1(key_end);
	value_end = find_cstr_end(value_begin);
	value = arr_from_begin_end(value_begin, value_end);
	temp0 = (struct key_value_pair*) alloc(ctx, sizeof(struct key_value_pair));
	(*(temp0) = (struct key_value_pair) {key, value}, 0);
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
	struct ok_3 o;
	struct err_2 e;
	struct result_3 matched;
	matched = a;
	switch (matched.kind) {
		case 0:
			o = matched.as0;
			return call_16(ctx, f, o.value);
		case 1:
			e = matched.as1;
			return (struct result_3) {1, .as1 = e};
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
struct ok_3 ok_3(struct arr_0 t) {
	return (struct ok_3) {t};
}
struct result_3 first_failures__lambda0__lambda0(struct ctx* ctx, struct first_failures__lambda0__lambda0* _closure, struct arr_0 b_descr) {
	return (struct result_3) {0, .as0 = ok_3(_op_plus_1(ctx, _op_plus_1(ctx, _closure->a_descr, (struct arr_0) {1, "\n"}), b_descr))};
}
struct result_3 first_failures__lambda0(struct ctx* ctx, struct first_failures__lambda0* _closure, struct arr_0 a_descr) {
	struct first_failures__lambda0__lambda0* temp0;
	return then_1(ctx, call_17(ctx, _closure->b), (struct fun_mut1_10) {(fun_ptr3_11) first_failures__lambda0__lambda0, (uint8_t*) (temp0 = (struct first_failures__lambda0__lambda0*) alloc(ctx, sizeof(struct first_failures__lambda0__lambda0)), ((*(temp0) = (struct first_failures__lambda0__lambda0) {a_descr}, 0), temp0))});
}
struct result_3 run_noze_tests(struct ctx* ctx, struct arr_0 path, struct arr_0 path_to_noze, struct dict_1* env, struct test_options options) {
	struct arr_1 tests;
	struct arr_7 failures;
	struct run_noze_tests__lambda0* temp0;
	tests = list_tests(ctx, path);
	failures = flat_map_with_max_size(ctx, tests, options.max_failures, (struct fun_mut1_12) {(fun_ptr3_13) run_noze_tests__lambda0, (uint8_t*) (temp0 = (struct run_noze_tests__lambda0*) alloc(ctx, sizeof(struct run_noze_tests__lambda0)), ((*(temp0) = (struct run_noze_tests__lambda0) {path_to_noze, env, options}, 0), temp0))});
	if (has__q_6(failures)) {
		return (struct result_3) {1, .as1 = err_2(failures)};
	} else {
		return (struct result_3) {0, .as0 = ok_3(_op_plus_1(ctx, _op_plus_1(ctx, _op_plus_1(ctx, (struct arr_0) {4, "ran "}, to_str_3(ctx, tests.size)), (struct arr_0) {10, " tests in "}), path))};
	}
}
struct arr_1 list_tests(struct ctx* ctx, struct arr_0 path) {
	struct mut_arr_1* res;
	struct fun_mut1_6 filter;
	struct list_tests__lambda1* temp0;
	res = new_mut_arr_0(ctx);
	filter = (struct fun_mut1_6) {(fun_ptr3_7) list_tests__lambda0, (uint8_t*) null_any()};
	each_child_recursive(ctx, path, filter, (struct fun_mut1_11) {(fun_ptr3_12) list_tests__lambda1, (uint8_t*) (temp0 = (struct list_tests__lambda1*) alloc(ctx, sizeof(struct list_tests__lambda1)), ((*(temp0) = (struct list_tests__lambda1) {res}, 0), temp0))});
	return freeze_0(res);
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
	struct some_13 s;
	struct opt_13 matched;
	matched = get_stat(ctx, path);
	switch (matched.kind) {
		case 0:
			return todo_6();
		case 1:
			s = matched.as1;
			return _op_equal_equal_5((s.value->st_mode & s_ifmt(ctx)), s_ifdir(ctx));
		default:
			return (assert(0),0);
	}
}
struct opt_13 get_stat(struct ctx* ctx, char* path) {
	struct stat_t* s;
	int32_t err;
	int32_t errno;
	s = empty_stat(ctx);
	err = stat(path, s);
	if (_op_equal_equal_2(err, 0)) {
		return (struct opt_13) {1, .as1 = some_13(s)};
	} else {
		assert_0(ctx, _op_equal_equal_2(err, neg_one_1()));
		errno = errno;
		if (_op_equal_equal_2(errno, enoent())) {
			return (struct opt_13) {0, .as0 = none()};
		} else {
			return todo_5();
		}
	}
}
struct stat_t* empty_stat(struct ctx* ctx) {
	struct stat_t* temp0;
	temp0 = (struct stat_t*) alloc(ctx, sizeof(struct stat_t));
	(*(temp0) = (struct stat_t) {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, 0);
	return temp0;
}
struct some_13 some_13(struct stat_t* t) {
	return (struct some_13) {t};
}
int32_t neg_one_1() {
	return (0 - 1);
}
int32_t enoent() {
	return two_1();
}
struct opt_13 todo_5() {
	return (assert(0),(struct opt_13) {0});
}
uint8_t todo_6() {
	return (assert(0),0);
}
uint8_t _op_equal_equal_5(uint32_t a, uint32_t b) {
	struct comparison matched;
	matched = compare_467(a, b);
	switch (matched.kind) {
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
struct comparison compare_467(uint32_t a, uint32_t b) {
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
	struct ctx* _tailCallctx;
	struct arr_1 _tailCalla;
	struct fun_mut1_11 _tailCallf;
	top:
	if (empty__q_6(a)) {
		return 0;
	} else {
		call_18(ctx, f, first_1(ctx, a));
		_tailCallctx = ctx;
		_tailCalla = tail_2(ctx, a);
		_tailCallf = f;
		ctx = _tailCallctx;
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
	uint8_t* dirp;
	struct mut_arr_1* res;
	dirp = opendir(path);
	forbid_0(ctx, null__q_0(dirp));
	res = new_mut_arr_0(ctx);
	read_dir_recur(ctx, dirp, res);
	return sort_0(ctx, freeze_0(res));
}
uint8_t read_dir_recur(struct ctx* ctx, uint8_t* dirp, struct mut_arr_1* res) {
	struct dirent* entry;
	struct cell_3* result;
	int32_t err;
	struct arr_0 name;
	struct dirent* temp0;
	struct ctx* _tailCallctx;
	uint8_t* _tailCalldirp;
	struct mut_arr_1* _tailCallres;
	top:
	entry = (temp0 = (struct dirent*) alloc(ctx, sizeof(struct dirent)), ((*(temp0) = (struct dirent) {0, 0, 0, literal_0((struct arr_0) {1, "\0"}), zero_4()}, 0), temp0));
	result = new_cell_1(ctx, entry);
	err = readdir_r(dirp, entry, result);
	assert_0(ctx, zero__q_1(err));
	if (null__q_0((uint8_t*) get_4(result))) {
		return 0;
	} else {
		assert_0(ctx, ref_eq(get_4(result), entry));
		name = get_dirent_name(entry);
		if ((_op_equal_equal_4(name, (struct arr_0) {1, "."}) || _op_equal_equal_4(name, (struct arr_0) {2, ".."}))) {
			0;
		} else {
			push_0(ctx, res, get_dirent_name(entry));
		}
		_tailCallctx = ctx;
		_tailCalldirp = dirp;
		_tailCallres = res;
		ctx = _tailCallctx;
		dirp = _tailCalldirp;
		res = _tailCallres;
		goto top;
	}
}
struct bytes256 zero_4() {
	return (struct bytes256) {zero_3(), zero_3()};
}
struct cell_3* new_cell_1(struct ctx* ctx, struct dirent* value) {
	struct cell_3* temp0;
	temp0 = (struct cell_3*) alloc(ctx, sizeof(struct cell_3));
	(*(temp0) = (struct cell_3) {value}, 0);
	return temp0;
}
struct dirent* get_4(struct cell_3* c) {
	return c->value;
}
uint8_t ref_eq(struct dirent* a, struct dirent* b) {
	return ((uint8_t*) a == (uint8_t*) b);
}
struct arr_0 get_dirent_name(struct dirent* d) {
	uint64_t name_offset;
	uint8_t* name_ptr;
	name_offset = (((sizeof(uint64_t) + sizeof(int64_t)) + sizeof(uint16_t)) + sizeof(char));
	name_ptr = ((uint8_t*) d + name_offset);
	return to_str_0((char*) name_ptr);
}
struct arr_1 sort_0(struct ctx* ctx, struct arr_1 a) {
	struct mut_arr_1* m;
	m = to_mut_arr(ctx, a);
	sort_1(ctx, m);
	return freeze_0(m);
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
	struct arr_0 pivot;
	uint64_t index_of_first_value_gt_pivot;
	uint64_t new_pivot_index;
	struct ctx* _tailCallctx;
	struct mut_slice* _tailCalla;
	top:
	if (_op_less_equal_0(a->size, 1)) {
		return 0;
	} else {
		swap_0(ctx, a, 0, _op_div(ctx, a->size, two_0()));
		pivot = at_7(ctx, a, 0);
		index_of_first_value_gt_pivot = partition_recur(ctx, a, pivot, 1, decr(ctx, a->size));
		new_pivot_index = decr(ctx, index_of_first_value_gt_pivot);
		swap_0(ctx, a, 0, new_pivot_index);
		sort_2(ctx, slice_4(ctx, a, 0, new_pivot_index));
		_tailCallctx = ctx;
		_tailCalla = slice_5(ctx, a, incr_0(ctx, new_pivot_index));
		ctx = _tailCallctx;
		a = _tailCalla;
		goto top;
	}
}
uint8_t swap_0(struct ctx* ctx, struct mut_slice* a, uint64_t lo, uint64_t hi) {
	struct arr_0 old_lo;
	old_lo = at_7(ctx, a, lo);
	set_at_3(ctx, a, lo, at_7(ctx, a, hi));
	return set_at_3(ctx, a, hi, old_lo);
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
	struct arr_0 em;
	struct ctx* _tailCallctx;
	struct mut_slice* _tailCalla;
	struct arr_0 _tailCallpivot;
	uint64_t _tailCalll;
	uint64_t _tailCallr;
	top:
	assert_0(ctx, _op_less_equal_0(l, a->size));
	assert_0(ctx, _op_less_0(r, a->size));
	if (_op_less_equal_0(l, r)) {
		em = at_7(ctx, a, l);
		if (_op_less_2(em, pivot)) {
			_tailCallctx = ctx;
			_tailCalla = a;
			_tailCallpivot = pivot;
			_tailCalll = incr_0(ctx, l);
			_tailCallr = r;
			ctx = _tailCallctx;
			a = _tailCalla;
			pivot = _tailCallpivot;
			l = _tailCalll;
			r = _tailCallr;
			goto top;
		} else {
			swap_0(ctx, a, l, r);
			_tailCallctx = ctx;
			_tailCalla = a;
			_tailCallpivot = pivot;
			_tailCalll = l;
			_tailCallr = decr(ctx, r);
			ctx = _tailCallctx;
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
	struct comparison matched;
	matched = compare_273(a, b);
	switch (matched.kind) {
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
	return slice_4(ctx, a, lo, _op_minus_0(ctx, a->size, lo));
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
struct opt_12 get_extension(struct ctx* ctx, struct arr_0 name) {
	struct some_11 s;
	struct opt_11 matched;
	matched = last_index_of(ctx, name, literal_0((struct arr_0) {1, "."}));
	switch (matched.kind) {
		case 0:
			return (struct opt_12) {0, .as0 = none()};
		case 1:
			s = matched.as1;
			return (struct opt_12) {1, .as1 = some_10(slice_after_1(ctx, name, s.value))};
		default:
			return (assert(0),(struct opt_12) {0});
	}
}
struct opt_11 last_index_of(struct ctx* ctx, struct arr_0 s, char c) {
	struct ctx* _tailCallctx;
	struct arr_0 _tailCalls;
	char _tailCallc;
	top:
	if (empty__q_0(s)) {
		return (struct opt_11) {0, .as0 = none()};
	} else {
		if (_op_equal_equal_3(last(ctx, s), c)) {
			return (struct opt_11) {1, .as1 = some_9(decr(ctx, s.size))};
		} else {
			_tailCallctx = ctx;
			_tailCalls = rtail(ctx, s);
			_tailCallc = c;
			ctx = _tailCallctx;
			s = _tailCalls;
			c = _tailCallc;
			goto top;
		}
	}
}
struct arr_0 slice_after_1(struct ctx* ctx, struct arr_0 a, uint64_t before_begin) {
	return slice_starting_at_1(ctx, a, incr_0(ctx, before_begin));
}
struct arr_0 base_name(struct ctx* ctx, struct arr_0 path) {
	struct opt_11 i;
	struct some_11 s;
	struct opt_11 matched;
	i = last_index_of(ctx, path, literal_0((struct arr_0) {1, "/"}));
	matched = i;
	switch (matched.kind) {
		case 0:
			return path;
		case 1:
			s = matched.as1;
			return slice_after_1(ctx, path, s.value);
		default:
			return (assert(0),(struct arr_0) {0, NULL});
	}
}
uint8_t list_tests__lambda1(struct ctx* ctx, struct list_tests__lambda1* _closure, struct arr_0 child) {
	struct some_12 s;
	struct opt_12 matched;
	matched = get_extension(ctx, base_name(ctx, child));
	switch (matched.kind) {
		case 0:
			return 0;
		case 1:
			s = matched.as1;
			if (_op_equal_equal_4(s.value, (struct arr_0) {2, "nz"})) {
				return push_0(ctx, _closure->res, child);
			} else {
				return 0;
			}
		default:
			return (assert(0),0);
	}
}
struct arr_7 flat_map_with_max_size(struct ctx* ctx, struct arr_1 a, uint64_t max_size, struct fun_mut1_12 mapper) {
	struct mut_arr_5* res;
	struct flat_map_with_max_size__lambda0* temp0;
	res = new_mut_arr_2(ctx);
	each_1(ctx, a, (struct fun_mut1_11) {(fun_ptr3_12) flat_map_with_max_size__lambda0, (uint8_t*) (temp0 = (struct flat_map_with_max_size__lambda0*) alloc(ctx, sizeof(struct flat_map_with_max_size__lambda0)), ((*(temp0) = (struct flat_map_with_max_size__lambda0) {res, max_size, mapper}, 0), temp0))});
	return freeze_6(res);
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
	struct ctx* _tailCallctx;
	struct arr_7 _tailCalla;
	struct fun_mut1_13 _tailCallf;
	top:
	if (empty__q_11(a)) {
		return 0;
	} else {
		call_19(ctx, f, first_3(ctx, a));
		_tailCallctx = ctx;
		_tailCalla = tail_4(ctx, a);
		_tailCallf = f;
		ctx = _tailCallctx;
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
	return slice_6(ctx, a, begin, _op_minus_0(ctx, a.size, begin));
}
struct arr_7 slice_6(struct ctx* ctx, struct arr_7 a, uint64_t begin, uint64_t size) {
	assert_0(ctx, _op_less_equal_0(_op_plus_0(ctx, begin, size), a.size));
	return (struct arr_7) {size, (a.data + begin)};
}
uint8_t push_2(struct ctx* ctx, struct mut_arr_5* a, struct failure* value) {
	if (_op_equal_equal_0(a->size, a->capacity)) {
		increase_capacity_to_2(ctx, a, (zero__q_0(a->size) ? four_0() : _op_times_0(ctx, a->size, two_0())));
	} else {
		0;
	}
	ensure_capacity_2(ctx, a, round_up_to_power_of_two(ctx, incr_0(ctx, a->size)));
	assert_0(ctx, _op_less_0(a->size, a->capacity));
	(*((a->data + a->size)) = value, 0);
	return (a->size = incr_0(ctx, a->size), 0);
}
uint8_t increase_capacity_to_2(struct ctx* ctx, struct mut_arr_5* a, uint64_t new_capacity) {
	struct failure** old_data;
	assert_0(ctx, _op_greater_0(new_capacity, a->capacity));
	old_data = a->data;
	(a->capacity = new_capacity, 0);
	(a->data = uninitialized_data_4(ctx, new_capacity), 0);
	return copy_data_from_2(ctx, a->data, old_data, a->size);
}
struct failure** uninitialized_data_4(struct ctx* ctx, uint64_t size) {
	uint8_t* bptr;
	bptr = alloc(ctx, (size * sizeof(struct failure*)));
	return (struct failure**) bptr;
}
uint8_t copy_data_from_2(struct ctx* ctx, struct failure** to, struct failure** from, uint64_t len) {
	uint64_t hl;
	struct ctx* _tailCallctx;
	struct failure** _tailCallto;
	struct failure** _tailCallfrom;
	uint64_t _tailCalllen;
	top:
	if (_op_less_0(len, eight_0())) {
		return copy_data_from_small_2(ctx, to, from, len);
	} else {
		hl = _op_div(ctx, len, two_0());
		copy_data_from_2(ctx, to, from, hl);
		_tailCallctx = ctx;
		_tailCallto = (to + hl);
		_tailCallfrom = (from + hl);
		_tailCalllen = _op_minus_0(ctx, len, hl);
		ctx = _tailCallctx;
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
	struct arr_1 arr;
	struct opt_14 op;
	struct some_14 s;
	struct opt_14 matched;
	struct arr_0* temp0;
	struct run_single_noze_test__lambda0* temp1;
	op = first_some(ctx, (temp0 = (struct arr_0*) alloc(ctx, (sizeof(struct arr_0) * 4)), ((*((temp0 + 0)) = (struct arr_0) {3, "ast"}, 0), ((*((temp0 + 1)) = (struct arr_0) {5, "model"}, 0), ((*((temp0 + 2)) = (struct arr_0) {14, "concrete-model"}, 0), ((*((temp0 + 3)) = (struct arr_0) {9, "low-model"}, 0), (struct arr_1) {4, temp0}))))), (struct fun_mut1_14) {(fun_ptr3_15) run_single_noze_test__lambda0, (uint8_t*) (temp1 = (struct run_single_noze_test__lambda0*) alloc(ctx, sizeof(struct run_single_noze_test__lambda0)), ((*(temp1) = (struct run_single_noze_test__lambda0) {options, path, path_to_noze, env}, 0), temp1))});
	matched = op;
	switch (matched.kind) {
		case 0:
			if (options.print_tests__q) {
				print_sync(_op_plus_1(ctx, (struct arr_0) {9, "noze run "}, path));
			} else {
				0;
			}
			return run_single_runnable_test(ctx, path_to_noze, env, path, options.overwrite_output__q);
		case 1:
			s = matched.as1;
			return s.value;
		default:
			return (assert(0),(struct arr_7) {0, NULL});
	}
}
struct opt_14 first_some(struct ctx* ctx, struct arr_1 a, struct fun_mut1_14 cb) {
	struct some_14 s;
	struct opt_14 matched;
	struct ctx* _tailCallctx;
	struct arr_1 _tailCalla;
	struct fun_mut1_14 _tailCallcb;
	top:
	if (empty__q_6(a)) {
		return (struct opt_14) {0, .as0 = none()};
	} else {
		matched = call_21(ctx, cb, first_1(ctx, a));
		switch (matched.kind) {
			case 0:
				_tailCallctx = ctx;
				_tailCalla = tail_2(ctx, a);
				_tailCallcb = cb;
				ctx = _tailCallctx;
				a = _tailCalla;
				cb = _tailCallcb;
				goto top;
			case 1:
				s = matched.as1;
				return (struct opt_14) {1, .as1 = s};
			default:
				return (assert(0),(struct opt_14) {0});
		}
	}
}
struct opt_14 call_21(struct ctx* ctx, struct fun_mut1_14 f, struct arr_0 p0) {
	return call_with_ctx_20(ctx, f, p0);
}
struct opt_14 call_with_ctx_20(struct ctx* c, struct fun_mut1_14 f, struct arr_0 p0) {
	return f.fun_ptr(c, f.closure, p0);
}
struct print_test_result* run_print_test(struct ctx* ctx, struct arr_0 print_kind, struct arr_0 path_to_noze, struct dict_1* env, struct arr_0 path, uint8_t overwrite_output__q) {
	struct arr_1 arr;
	struct process_result* res;
	struct arr_0 output_path;
	struct arr_7 output_failures;
	struct arr_0 stderr_no_color;
	struct arr_0 message;
	struct arr_7 arr1;
	struct arr_0* temp0;
	struct print_test_result* temp1;
	struct print_test_result* temp2;
	struct print_test_result* temp3;
	struct failure** temp4;
	struct failure* temp5;
	struct print_test_result* temp6;
	res = spawn_and_wait_result_0(ctx, path_to_noze, (temp0 = (struct arr_0*) alloc(ctx, (sizeof(struct arr_0) * 3)), ((*((temp0 + 0)) = (struct arr_0) {5, "print"}, 0), ((*((temp0 + 1)) = print_kind, 0), ((*((temp0 + 2)) = path, 0), (struct arr_1) {3, temp0})))), env);
	output_path = _op_plus_1(ctx, _op_plus_1(ctx, _op_plus_1(ctx, path, (struct arr_0) {1, "."}), print_kind), (struct arr_0) {5, ".tata"});
	output_failures = ((empty__q_0(res->stdout) && _op_bang_equal(res->exit_code, literal_2(ctx, (struct arr_0) {1, "0"}))) ? empty_arr_3() : handle_output(ctx, path, output_path, res->stdout, overwrite_output__q));
	if (!empty__q_11(output_failures)) {
		temp1 = (struct print_test_result*) alloc(ctx, sizeof(struct print_test_result));
		(*(temp1) = (struct print_test_result) {1, output_failures}, 0);
		return temp1;
	} else {
		if (_op_equal_equal_2(res->exit_code, literal_2(ctx, (struct arr_0) {1, "0"}))) {
			assert_0(ctx, _op_equal_equal_4(res->stderr, (struct arr_0) {0, ""}));
			temp2 = (struct print_test_result*) alloc(ctx, sizeof(struct print_test_result));
			(*(temp2) = (struct print_test_result) {0, empty_arr_3()}, 0);
			return temp2;
		} else {
			if (_op_equal_equal_2(res->exit_code, literal_2(ctx, (struct arr_0) {1, "1"}))) {
				stderr_no_color = remove_colors(ctx, res->stderr);
				temp3 = (struct print_test_result*) alloc(ctx, sizeof(struct print_test_result));
				(*(temp3) = (struct print_test_result) {1, handle_output(ctx, path, _op_plus_1(ctx, output_path, (struct arr_0) {4, ".err"}), stderr_no_color, overwrite_output__q)}, 0);
				return temp3;
			} else {
				message = _op_plus_1(ctx, (struct arr_0) {22, "unexpected exit code: "}, to_str_1(ctx, res->exit_code));
				temp6 = (struct print_test_result*) alloc(ctx, sizeof(struct print_test_result));
				(*(temp6) = (struct print_test_result) {1, (temp4 = (struct failure**) alloc(ctx, (sizeof(struct failure*) * 1)), ((*((temp4 + 0)) = (temp5 = (struct failure*) alloc(ctx, sizeof(struct failure)), ((*(temp5) = (struct failure) {path, message}, 0), temp5)), 0), (struct arr_7) {1, temp4}))}, 0);
				return temp6;
			}
		}
	}
}
struct process_result* spawn_and_wait_result_0(struct ctx* ctx, struct arr_0 exe, struct arr_1 args, struct dict_1* environ) {
	char* exe_c_str;
	print_sync(fold(ctx, _op_plus_1(ctx, (struct arr_0) {23, "spawn-and-wait-result: "}, exe), args, (struct fun_mut2_1) {(fun_ptr4_2) spawn_and_wait_result_0__lambda0, (uint8_t*) null_any()}));
	if (is_file__q_0(ctx, exe)) {
		exe_c_str = to_c_str(ctx, exe);
		return spawn_and_wait_result_1(ctx, exe_c_str, convert_args(ctx, exe_c_str, args), convert_environ(ctx, environ));
	} else {
		return fail_2(ctx, _op_plus_1(ctx, exe, (struct arr_0) {14, " is not a file"}));
	}
}
struct arr_0 fold(struct ctx* ctx, struct arr_0 val, struct arr_1 a, struct fun_mut2_1 combine) {
	struct ctx* _tailCallctx;
	struct arr_0 _tailCallval;
	struct arr_1 _tailCalla;
	struct fun_mut2_1 _tailCallcombine;
	top:
	if (empty__q_6(a)) {
		return val;
	} else {
		_tailCallctx = ctx;
		_tailCallval = call_22(ctx, combine, val, first_1(ctx, a));
		_tailCalla = tail_2(ctx, a);
		_tailCallcombine = combine;
		ctx = _tailCallctx;
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
	return _op_plus_1(ctx, _op_plus_1(ctx, a, (struct arr_0) {1, " "}), b);
}
uint8_t is_file__q_0(struct ctx* ctx, struct arr_0 path) {
	return is_file__q_1(ctx, to_c_str(ctx, path));
}
uint8_t is_file__q_1(struct ctx* ctx, char* path) {
	struct some_13 s;
	struct opt_13 matched;
	matched = get_stat(ctx, path);
	switch (matched.kind) {
		case 0:
			return 0;
		case 1:
			s = matched.as1;
			return _op_equal_equal_5((s.value->st_mode & s_ifmt(ctx)), s_ifreg(ctx));
		default:
			return (assert(0),0);
	}
}
uint32_t s_ifreg(struct ctx* ctx) {
	return two_pow_0(fifteen());
}
struct process_result* spawn_and_wait_result_1(struct ctx* ctx, char* exe, char** args, char** environ) {
	struct pipes* stdout_pipes;
	struct pipes* stderr_pipes;
	struct posix_spawn_file_actions_t* actions;
	struct cell_4* pid_cell;
	int32_t pid;
	struct mut_arr_4* stdout_builder;
	struct mut_arr_4* stderr_builder;
	int32_t exit_code;
	struct posix_spawn_file_actions_t* temp0;
	struct process_result* temp1;
	stdout_pipes = make_pipes(ctx);
	stderr_pipes = make_pipes(ctx);
	actions = (temp0 = (struct posix_spawn_file_actions_t*) alloc(ctx, sizeof(struct posix_spawn_file_actions_t)), ((*(temp0) = (struct posix_spawn_file_actions_t) {0, 0, NULL, zero_0()}, 0), temp0));
	check_posix_error(ctx, posix_spawn_file_actions_init(actions));
	check_posix_error(ctx, posix_spawn_file_actions_addclose(actions, stdout_pipes->write_pipe));
	check_posix_error(ctx, posix_spawn_file_actions_addclose(actions, stderr_pipes->write_pipe));
	check_posix_error(ctx, posix_spawn_file_actions_adddup2(actions, stdout_pipes->read_pipe, stdout_fd()));
	check_posix_error(ctx, posix_spawn_file_actions_adddup2(actions, stderr_pipes->read_pipe, stderr_fd()));
	check_posix_error(ctx, posix_spawn_file_actions_addclose(actions, stdout_pipes->read_pipe));
	check_posix_error(ctx, posix_spawn_file_actions_addclose(actions, stderr_pipes->read_pipe));
	pid_cell = new_cell_2(ctx, 0);
	check_posix_error(ctx, posix_spawn(pid_cell, exe, actions, NULL, args, environ));
	pid = get_5(pid_cell);
	check_posix_error(ctx, close(stdout_pipes->read_pipe));
	check_posix_error(ctx, close(stderr_pipes->read_pipe));
	stdout_builder = new_mut_arr_3(ctx);
	stderr_builder = new_mut_arr_3(ctx);
	keep_polling(ctx, stdout_pipes->write_pipe, stderr_pipes->write_pipe, stdout_builder, stderr_builder);
	exit_code = wait_and_get_exit_code(ctx, pid);
	temp1 = (struct process_result*) alloc(ctx, sizeof(struct process_result));
	(*(temp1) = (struct process_result) {exit_code, freeze_3(stdout_builder), freeze_3(stderr_builder)}, 0);
	return temp1;
}
struct pipes* make_pipes(struct ctx* ctx) {
	struct pipes* res;
	struct pipes* temp0;
	res = (temp0 = (struct pipes*) alloc(ctx, sizeof(struct pipes)), ((*(temp0) = (struct pipes) {0, 0}, 0), temp0));
	check_posix_error(ctx, pipe(res));
	return res;
}
struct cell_4* new_cell_2(struct ctx* ctx, int32_t value) {
	struct cell_4* temp0;
	temp0 = (struct cell_4*) alloc(ctx, sizeof(struct cell_4));
	(*(temp0) = (struct cell_4) {value}, 0);
	return temp0;
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
	struct arr_8 arr;
	struct arr_8 poll_fds;
	struct pollfd* stdout_pollfd;
	struct pollfd* stderr_pollfd;
	int32_t n_pollfds_with_events;
	struct handle_revents_result a;
	struct handle_revents_result b;
	struct pollfd* temp0;
	struct ctx* _tailCallctx;
	int32_t _tailCallstdout_pipe;
	int32_t _tailCallstderr_pipe;
	struct mut_arr_4* _tailCallstdout_builder;
	struct mut_arr_4* _tailCallstderr_builder;
	top:
	poll_fds = (temp0 = (struct pollfd*) alloc(ctx, (sizeof(struct pollfd) * 2)), ((*((temp0 + 0)) = (struct pollfd) {stdout_pipe, pollin(ctx), 0}, 0), ((*((temp0 + 1)) = (struct pollfd) {stderr_pipe, pollin(ctx), 0}, 0), (struct arr_8) {2, temp0})));
	stdout_pollfd = ref_of_val_at(ctx, poll_fds, 0);
	stderr_pollfd = ref_of_val_at(ctx, poll_fds, 1);
	n_pollfds_with_events = poll(poll_fds.data, poll_fds.size, neg_one_1());
	if (zero__q_1(n_pollfds_with_events)) {
		return 0;
	} else {
		a = handle_revents(ctx, stdout_pollfd, stdout_builder);
		b = handle_revents(ctx, stderr_pollfd, stderr_builder);
		assert_0(ctx, _op_equal_equal_0(_op_plus_0(ctx, to_nat_1(ctx, any__q(ctx, a)), to_nat_1(ctx, any__q(ctx, b))), to_nat_2(ctx, n_pollfds_with_events)));
		if ((a.hung_up__q && b.hung_up__q)) {
			return 0;
		} else {
			_tailCallctx = ctx;
			_tailCallstdout_pipe = stdout_pipe;
			_tailCallstderr_pipe = stderr_pipe;
			_tailCallstdout_builder = stdout_builder;
			_tailCallstderr_builder = stderr_builder;
			ctx = _tailCallctx;
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
	struct comparison matched;
	matched = compare_574(a, b);
	switch (matched.kind) {
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
struct comparison compare_574(int16_t a, int16_t b) {
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
	int16_t revents;
	uint8_t had_pollin__q;
	uint8_t hung_up__q;
	revents = pollfd->revents;
	had_pollin__q = has_pollin__q(ctx, revents);
	if (had_pollin__q) {
		read_to_buffer_until_eof(ctx, pollfd->fd, builder);
	} else {
		0;
	}
	hung_up__q = has_pollhup__q(ctx, revents);
	if ((((has_pollpri__q(ctx, revents) || has_pollout__q(ctx, revents)) || has_pollerr__q(ctx, revents)) || has_pollnval__q(ctx, revents))) {
		todo_0();
	} else {
		0;
	}
	return (struct handle_revents_result) {had_pollin__q, hung_up__q};
}
uint8_t has_pollin__q(struct ctx* ctx, int16_t revents) {
	return bits_intersect__q(revents, pollin(ctx));
}
uint8_t bits_intersect__q(int16_t a, int16_t b) {
	return !zero__q_3((a & b));
}
uint8_t read_to_buffer_until_eof(struct ctx* ctx, int32_t fd, struct mut_arr_4* buffer) {
	uint64_t read_max;
	char* add_data_to;
	int64_t n_bytes_read;
	struct ctx* _tailCallctx;
	int32_t _tailCallfd;
	struct mut_arr_4* _tailCallbuffer;
	top:
	read_max = two_pow_2(ten_0());
	ensure_capacity_3(ctx, buffer, _op_plus_0(ctx, buffer->size, read_max));
	add_data_to = (buffer->data + buffer->size);
	n_bytes_read = read(fd, (uint8_t*) add_data_to, read_max);
	if (_op_equal_equal_1(n_bytes_read, neg_one_0())) {
		return todo_0();
	} else {
		if (_op_equal_equal_1(n_bytes_read, 0)) {
			return 0;
		} else {
			assert_0(ctx, _op_less_equal_0(to_nat_0(ctx, n_bytes_read), read_max));
			unsafe_increase_size(ctx, buffer, to_nat_0(ctx, n_bytes_read));
			_tailCallctx = ctx;
			_tailCallfd = fd;
			_tailCallbuffer = buffer;
			ctx = _tailCallctx;
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
		return (two_pow_2(wrap_decr_0(pow)) * two_0());
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
	char* old_data;
	assert_0(ctx, _op_greater_0(new_capacity, a->capacity));
	old_data = a->data;
	(a->capacity = new_capacity, 0);
	(a->data = uninitialized_data_3(ctx, new_capacity), 0);
	return copy_data_from_3(ctx, a->data, old_data, a->size);
}
uint8_t copy_data_from_3(struct ctx* ctx, char* to, char* from, uint64_t len) {
	uint64_t hl;
	struct ctx* _tailCallctx;
	char* _tailCallto;
	char* _tailCallfrom;
	uint64_t _tailCalllen;
	top:
	if (_op_less_0(len, eight_0())) {
		return copy_data_from_small_3(ctx, to, from, len);
	} else {
		hl = _op_div(ctx, len, two_0());
		copy_data_from_3(ctx, to, from, hl);
		_tailCallctx = ctx;
		_tailCallto = (to + hl);
		_tailCallfrom = (from + hl);
		_tailCalllen = _op_minus_0(ctx, len, hl);
		ctx = _tailCallctx;
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
		return copy_data_from_3(ctx, incr_1(to), incr_1(from), decr(ctx, len));
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
	struct cell_4* wait_status_cell;
	int32_t res_pid;
	int32_t wait_status;
	int32_t signal;
	wait_status_cell = new_cell_2(ctx, 0);
	res_pid = waitpid(pid, wait_status_cell, 0);
	wait_status = get_5(wait_status_cell);
	assert_0(ctx, _op_equal_equal_2(res_pid, pid));
	if (w_if_exited(ctx, wait_status)) {
		return w_exit_status(ctx, wait_status);
	} else {
		if (w_if_signaled(ctx, wait_status)) {
			signal = w_term_sig(ctx, wait_status);
			print_sync(_op_plus_1(ctx, (struct arr_0) {31, "Process terminated with signal "}, to_str_1(ctx, signal)));
			return todo_7();
		} else {
			if (w_if_stopped(ctx, wait_status)) {
				print_sync((struct arr_0) {12, "WAIT STOPPED"});
				return todo_7();
			} else {
				if (w_if_continued(ctx, wait_status)) {
					return todo_7();
				} else {
					return todo_7();
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
		return (two_pow_3(wrap_decr_3(pow)) * two_1());
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
		return todo_7();
	} else {
		if (_op_less_3(b, 0)) {
			return todo_7();
		} else {
			if (_op_less_3(b, thirty_two_0())) {
				return (a >> b);
			} else {
				return todo_7();
			}
		}
	}
}
uint8_t _op_less_3(int32_t a, int32_t b) {
	struct comparison matched;
	matched = compare_62(a, b);
	switch (matched.kind) {
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
int32_t todo_7() {
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
	int32_t ts;
	ts = w_term_sig(ctx, status);
	return (_op_bang_equal(ts, 0) && _op_bang_equal(ts, x7f()));
}
uint8_t _op_bang_equal(int32_t a, int32_t b) {
	return !_op_equal_equal_2(a, b);
}
struct arr_0 to_str_1(struct ctx* ctx, int32_t i) {
	return to_str_2(ctx, i);
}
struct arr_0 to_str_2(struct ctx* ctx, int64_t i) {
	struct arr_0 a;
	a = to_str_3(ctx, abs(ctx, i));
	if (negative__q(ctx, i)) {
		return _op_plus_1(ctx, (struct arr_0) {1, "-"}, a);
	} else {
		return a;
	}
}
struct arr_0 to_str_3(struct ctx* ctx, uint64_t n) {
	struct arr_0 hi;
	struct arr_0 lo;
	if (_op_equal_equal_0(n, literal_1(ctx, (struct arr_0) {1, "0"}))) {
		return (struct arr_0) {1, "0"};
	} else {
		if (_op_equal_equal_0(n, literal_1(ctx, (struct arr_0) {1, "1"}))) {
			return (struct arr_0) {1, "1"};
		} else {
			if (_op_equal_equal_0(n, literal_1(ctx, (struct arr_0) {1, "2"}))) {
				return (struct arr_0) {1, "2"};
			} else {
				if (_op_equal_equal_0(n, literal_1(ctx, (struct arr_0) {1, "3"}))) {
					return (struct arr_0) {1, "3"};
				} else {
					if (_op_equal_equal_0(n, literal_1(ctx, (struct arr_0) {1, "4"}))) {
						return (struct arr_0) {1, "4"};
					} else {
						if (_op_equal_equal_0(n, literal_1(ctx, (struct arr_0) {1, "5"}))) {
							return (struct arr_0) {1, "5"};
						} else {
							if (_op_equal_equal_0(n, literal_1(ctx, (struct arr_0) {1, "6"}))) {
								return (struct arr_0) {1, "6"};
							} else {
								if (_op_equal_equal_0(n, literal_1(ctx, (struct arr_0) {1, "7"}))) {
									return (struct arr_0) {1, "7"};
								} else {
									if (_op_equal_equal_0(n, literal_1(ctx, (struct arr_0) {1, "8"}))) {
										return (struct arr_0) {1, "8"};
									} else {
										if (_op_equal_equal_0(n, literal_1(ctx, (struct arr_0) {1, "9"}))) {
											return (struct arr_0) {1, "9"};
										} else {
											hi = to_str_3(ctx, _op_div(ctx, n, ten_0()));
											lo = to_str_3(ctx, mod(ctx, n, ten_0()));
											return _op_plus_1(ctx, hi, lo);
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
	int64_t i_abs;
	i_abs = (negative__q(ctx, i) ? neg_1(ctx, i) : i);
	return to_nat_0(ctx, i_abs);
}
uint8_t w_if_stopped(struct ctx* ctx, int32_t status) {
	return _op_equal_equal_2((status & xff()), x7f());
}
uint8_t w_if_continued(struct ctx* ctx, int32_t status) {
	return _op_equal_equal_2(status, xffff());
}
char** convert_args(struct ctx* ctx, char* exe_c_str, struct arr_1 args) {
	return cons(ctx, exe_c_str, rcons(ctx, map_1(ctx, args, (struct fun_mut1_16) {(fun_ptr3_17) convert_args__lambda0, (uint8_t*) null_any()}), NULL)).data;
}
struct arr_3 cons(struct ctx* ctx, char* a, struct arr_3 b) {
	struct arr_3 arr;
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
	struct mut_arr_6* res;
	res = new_uninitialized_mut_arr_3(ctx, size);
	make_mut_arr_worker_3(ctx, res, 0, f);
	return res;
}
struct mut_arr_6* new_uninitialized_mut_arr_3(struct ctx* ctx, uint64_t size) {
	struct mut_arr_6* temp0;
	temp0 = (struct mut_arr_6*) alloc(ctx, sizeof(struct mut_arr_6));
	(*(temp0) = (struct mut_arr_6) {0, size, size, uninitialized_data_5(ctx, size)}, 0);
	return temp0;
}
char** uninitialized_data_5(struct ctx* ctx, uint64_t size) {
	uint8_t* bptr;
	bptr = alloc(ctx, (size * sizeof(char*)));
	return (char**) bptr;
}
uint8_t make_mut_arr_worker_3(struct ctx* ctx, struct mut_arr_6* m, uint64_t i, struct fun_mut1_15 f) {
	struct ctx* _tailCallctx;
	struct mut_arr_6* _tailCallm;
	uint64_t _tailCalli;
	struct fun_mut1_15 _tailCallf;
	top:
	if (_op_equal_equal_0(i, m->size)) {
		return 0;
	} else {
		set_at_4(ctx, m, i, call_23(ctx, f, i));
		_tailCallctx = ctx;
		_tailCallm = m;
		_tailCalli = incr_0(ctx, i);
		_tailCallf = f;
		ctx = _tailCallctx;
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
		return at_1(ctx, _closure->b, _op_minus_0(ctx, i, _closure->a.size));
	}
}
struct arr_3 rcons(struct ctx* ctx, struct arr_3 a, char* b) {
	struct arr_3 arr;
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
	struct mut_arr_6* res;
	struct convert_environ__lambda0* temp0;
	res = new_mut_arr_4(ctx);
	each_3(ctx, environ, (struct fun_mut2_2) {(fun_ptr4_3) convert_environ__lambda0, (uint8_t*) (temp0 = (struct convert_environ__lambda0*) alloc(ctx, sizeof(struct convert_environ__lambda0)), ((*(temp0) = (struct convert_environ__lambda0) {res}, 0), temp0))});
	push_3(ctx, res, NULL);
	return freeze_7(res).data;
}
struct mut_arr_6* new_mut_arr_4(struct ctx* ctx) {
	struct mut_arr_6* temp0;
	temp0 = (struct mut_arr_6*) alloc(ctx, sizeof(struct mut_arr_6));
	(*(temp0) = (struct mut_arr_6) {0, 0, 0, NULL}, 0);
	return temp0;
}
uint8_t each_3(struct ctx* ctx, struct dict_1* d, struct fun_mut2_2 f) {
	struct dict_1* temp0;
	struct ctx* _tailCallctx;
	struct dict_1* _tailCalld;
	struct fun_mut2_2 _tailCallf;
	top:
	if (empty__q_12(ctx, d)) {
		return 0;
	} else {
		call_25(ctx, f, first_1(ctx, d->keys), first_1(ctx, d->values));
		_tailCallctx = ctx;
		_tailCalld = (temp0 = (struct dict_1*) alloc(ctx, sizeof(struct dict_1)), ((*(temp0) = (struct dict_1) {tail_2(ctx, d->keys), tail_2(ctx, d->values)}, 0), temp0));
		_tailCallf = f;
		ctx = _tailCallctx;
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
	if (_op_equal_equal_0(a->size, a->capacity)) {
		increase_capacity_to_4(ctx, a, (zero__q_0(a->size) ? four_0() : _op_times_0(ctx, a->size, two_0())));
	} else {
		0;
	}
	ensure_capacity_4(ctx, a, round_up_to_power_of_two(ctx, incr_0(ctx, a->size)));
	assert_0(ctx, _op_less_0(a->size, a->capacity));
	(*((a->data + a->size)) = value, 0);
	return (a->size = incr_0(ctx, a->size), 0);
}
uint8_t increase_capacity_to_4(struct ctx* ctx, struct mut_arr_6* a, uint64_t new_capacity) {
	char** old_data;
	assert_0(ctx, _op_greater_0(new_capacity, a->capacity));
	old_data = a->data;
	(a->capacity = new_capacity, 0);
	(a->data = uninitialized_data_5(ctx, new_capacity), 0);
	return copy_data_from_4(ctx, a->data, old_data, a->size);
}
uint8_t copy_data_from_4(struct ctx* ctx, char** to, char** from, uint64_t len) {
	uint64_t hl;
	struct ctx* _tailCallctx;
	char** _tailCallto;
	char** _tailCallfrom;
	uint64_t _tailCalllen;
	top:
	if (_op_less_0(len, eight_0())) {
		return copy_data_from_small_4(ctx, to, from, len);
	} else {
		hl = _op_div(ctx, len, two_0());
		copy_data_from_4(ctx, to, from, hl);
		_tailCallctx = ctx;
		_tailCallto = (to + hl);
		_tailCallfrom = (from + hl);
		_tailCalllen = _op_minus_0(ctx, len, hl);
		ctx = _tailCallctx;
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
	return push_3(ctx, _closure->res, to_c_str(ctx, _op_plus_1(ctx, _op_plus_1(ctx, key, (struct arr_0) {1, "="}), value)));
}
struct process_result* fail_2(struct ctx* ctx, struct arr_0 reason) {
	return throw_2(ctx, (struct exception) {reason});
}
struct process_result* throw_2(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx;
	exn_ctx = get_exception_ctx(ctx);
	hard_forbid(null__q_1(exn_ctx->jmp_buf_ptr));
	(exn_ctx->thrown_exception = e, 0);
	(longjmp(exn_ctx->jmp_buf_ptr, number_to_throw(ctx)), 0);
	return todo_8();
}
struct process_result* todo_8() {
	return (assert(0),NULL);
}
struct arr_7 empty_arr_3() {
	return (struct arr_7) {0, NULL};
}
struct arr_7 handle_output(struct ctx* ctx, struct arr_0 original_path, struct arr_0 output_path, struct arr_0 actual, uint8_t overwrite_output__q) {
	struct arr_7 arr;
	struct some_12 s;
	struct arr_0 message;
	struct arr_7 arr1;
	struct opt_12 matched;
	struct failure** temp0;
	struct failure* temp1;
	struct failure** temp2;
	struct failure* temp3;
	matched = try_read_file_0(ctx, output_path);
	switch (matched.kind) {
		case 0:
			if (overwrite_output__q) {
				write_file_0(ctx, output_path, actual);
				return empty_arr_3();
			} else {
				temp0 = (struct failure**) alloc(ctx, (sizeof(struct failure*) * 1));
				(*((temp0 + 0)) = (temp1 = (struct failure*) alloc(ctx, sizeof(struct failure)), ((*(temp1) = (struct failure) {original_path, _op_plus_1(ctx, _op_plus_1(ctx, base_name(ctx, output_path), (struct arr_0) {29, " does not exist. actual was:\n"}), actual)}, 0), temp1)), 0);
				return (struct arr_7) {1, temp0};
			}
		case 1:
			s = matched.as1;
			if (_op_equal_equal_4(s.value, actual)) {
				return empty_arr_3();
			} else {
				if (overwrite_output__q) {
					write_file_0(ctx, output_path, actual);
					return empty_arr_3();
				} else {
					message = _op_plus_1(ctx, _op_plus_1(ctx, base_name(ctx, output_path), (struct arr_0) {30, " was not as expected. actual:\n"}), actual);
					temp2 = (struct failure**) alloc(ctx, (sizeof(struct failure*) * 1));
					(*((temp2 + 0)) = (temp3 = (struct failure*) alloc(ctx, sizeof(struct failure)), ((*(temp3) = (struct failure) {original_path, message}, 0), temp3)), 0);
					return (struct arr_7) {1, temp2};
				}
			}
		default:
			return (assert(0),(struct arr_7) {0, NULL});
	}
}
struct opt_12 try_read_file_0(struct ctx* ctx, struct arr_0 path) {
	return try_read_file_1(ctx, to_c_str(ctx, path));
}
struct opt_12 try_read_file_1(struct ctx* ctx, char* path) {
	int32_t fd;
	int32_t errno;
	int64_t file_size;
	int64_t off;
	uint64_t file_size_nat;
	struct mut_arr_4* res;
	int64_t n_bytes_read;
	if (is_file__q_1(ctx, path)) {
		fd = open(path, o_rdonly(ctx), literal_4(ctx, (struct arr_0) {1, "0"}));
		if (_op_equal_equal_2(fd, neg_one_1())) {
			errno = errno;
			if (_op_equal_equal_2(errno, enoent())) {
				return (struct opt_12) {0, .as0 = none()};
			} else {
				print_sync(_op_plus_1(ctx, (struct arr_0) {20, "failed to open file "}, to_str_0(path)));
				return todo_9();
			}
		} else {
			file_size = lseek(fd, 0, seek_end(ctx));
			forbid_0(ctx, _op_equal_equal_1(file_size, neg_one_0()));
			assert_0(ctx, _op_less_1(file_size, billion_1()));
			forbid_0(ctx, zero__q_4(file_size));
			off = lseek(fd, 0, seek_set(ctx));
			assert_0(ctx, _op_equal_equal_1(off, 0));
			file_size_nat = to_nat_0(ctx, file_size);
			res = new_uninitialized_mut_arr_2(ctx, file_size_nat);
			n_bytes_read = read(fd, (uint8_t*) res->data, file_size_nat);
			forbid_0(ctx, _op_equal_equal_1(n_bytes_read, neg_one_0()));
			assert_0(ctx, _op_equal_equal_1(n_bytes_read, file_size));
			check_posix_error(ctx, close(fd));
			return (struct opt_12) {1, .as1 = some_10(freeze_3(res))};
		}
	} else {
		return (struct opt_12) {0, .as0 = none()};
	}
}
uint32_t o_rdonly(struct ctx* ctx) {
	return 0;
}
uint32_t literal_4(struct ctx* ctx, struct arr_0 s) {
	return literal_1(ctx, s);
}
struct opt_12 todo_9() {
	return (assert(0),(struct opt_12) {0});
}
int32_t seek_end(struct ctx* ctx) {
	return two_1();
}
int64_t billion_1() {
	return (million_1() * thousand_1());
}
uint8_t zero__q_4(int64_t i) {
	return _op_equal_equal_1(i, 0);
}
int32_t seek_set(struct ctx* ctx) {
	return 0;
}
uint8_t write_file_0(struct ctx* ctx, struct arr_0 path, struct arr_0 content) {
	return write_file_1(ctx, to_c_str(ctx, path), content);
}
uint8_t write_file_1(struct ctx* ctx, char* path, struct arr_0 content) {
	uint32_t permission_rdwr;
	uint32_t permission_rd;
	uint32_t permission;
	uint32_t flags;
	int32_t fd;
	int32_t errno;
	int64_t wrote_bytes;
	int32_t err;
	permission_rdwr = six_3();
	permission_rd = four_3();
	permission = ((bit_shift_left(permission_rdwr, six_3()) | bit_shift_left(permission_rd, three_3())) | permission_rd);
	flags = ((o_creat(ctx) | o_wronly(ctx)) | o_trunc(ctx));
	fd = open(path, flags, permission);
	if (_op_equal_equal_2(fd, neg_one_1())) {
		errno = errno;
		print_sync(_op_plus_1(ctx, (struct arr_0) {31, "failed to open file for write: "}, to_str_0(path)));
		print_sync(_op_plus_1(ctx, (struct arr_0) {7, "errno: "}, to_str_1(ctx, errno)));
		print_sync(_op_plus_1(ctx, (struct arr_0) {7, "flags: "}, to_str_4(ctx, flags)));
		print_sync(_op_plus_1(ctx, (struct arr_0) {12, "permission: "}, to_str_4(ctx, permission)));
		return todo_0();
	} else {
		wrote_bytes = write(fd, (uint8_t*) content.data, content.size);
		if (_op_equal_equal_1(wrote_bytes, to_int(ctx, content.size))) {
			0;
		} else {
			if (_op_equal_equal_1(wrote_bytes, literal_3(ctx, (struct arr_0) {2, "-1"}))) {
				todo_0();
			} else {
				todo_0();
			}
		}
		err = close(fd);
		if (_op_equal_equal_2(err, 0)) {
			return 0;
		} else {
			return todo_0();
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
	struct comparison matched;
	matched = compare_467(a, b);
	switch (matched.kind) {
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
	struct mut_arr_4* out;
	out = new_mut_arr_3(ctx);
	remove_colors_recur(ctx, s, out);
	return freeze_3(out);
}
uint8_t remove_colors_recur(struct ctx* ctx, struct arr_0 s, struct mut_arr_4* out) {
	struct ctx* _tailCallctx;
	struct arr_0 _tailCalls;
	struct mut_arr_4* _tailCallout;
	top:
	if (empty__q_0(s)) {
		return 0;
	} else {
		if (_op_equal_equal_3(first_0(ctx, s), literal_0((struct arr_0) {1, "\x1b"}))) {
			return remove_colors_recur_2(ctx, tail_1(ctx, s), out);
		} else {
			push_4(ctx, out, first_0(ctx, s));
			_tailCallctx = ctx;
			_tailCalls = tail_1(ctx, s);
			_tailCallout = out;
			ctx = _tailCallctx;
			s = _tailCalls;
			out = _tailCallout;
			goto top;
		}
	}
}
uint8_t remove_colors_recur_2(struct ctx* ctx, struct arr_0 s, struct mut_arr_4* out) {
	struct ctx* _tailCallctx;
	struct arr_0 _tailCalls;
	struct mut_arr_4* _tailCallout;
	top:
	if (empty__q_0(s)) {
		return 0;
	} else {
		if (_op_equal_equal_3(first_0(ctx, s), literal_0((struct arr_0) {1, "m"}))) {
			return remove_colors_recur(ctx, tail_1(ctx, s), out);
		} else {
			_tailCallctx = ctx;
			_tailCalls = tail_1(ctx, s);
			_tailCallout = out;
			ctx = _tailCallctx;
			s = _tailCalls;
			out = _tailCallout;
			goto top;
		}
	}
}
uint8_t push_4(struct ctx* ctx, struct mut_arr_4* a, char value) {
	if (_op_equal_equal_0(a->size, a->capacity)) {
		increase_capacity_to_3(ctx, a, (zero__q_0(a->size) ? four_0() : _op_times_0(ctx, a->size, two_0())));
	} else {
		0;
	}
	ensure_capacity_3(ctx, a, round_up_to_power_of_two(ctx, incr_0(ctx, a->size)));
	assert_0(ctx, _op_less_0(a->size, a->capacity));
	(*((a->data + a->size)) = value, 0);
	return (a->size = incr_0(ctx, a->size), 0);
}
struct some_14 some_14(struct arr_7 t) {
	return (struct some_14) {t};
}
struct opt_14 run_single_noze_test__lambda0(struct ctx* ctx, struct run_single_noze_test__lambda0* _closure, struct arr_0 print_kind) {
	struct print_test_result* res;
	if (_closure->options.print_tests__q) {
		print_sync(_op_plus_1(ctx, _op_plus_1(ctx, _op_plus_1(ctx, (struct arr_0) {11, "noze print "}, print_kind), (struct arr_0) {1, " "}), _closure->path));
	} else {
		0;
	}
	res = run_print_test(ctx, print_kind, _closure->path_to_noze, _closure->env, _closure->path, _closure->options.overwrite_output__q);
	if (res->should_stop__q) {
		return (struct opt_14) {1, .as1 = some_14(res->failures)};
	} else {
		return (struct opt_14) {0, .as0 = none()};
	}
}
struct arr_7 run_single_runnable_test(struct ctx* ctx, struct arr_0 path_to_noze, struct dict_1* env, struct arr_0 path, uint8_t overwrite_output__q) {
	struct arr_1 arr;
	struct process_result* res;
	struct arr_0 message;
	struct arr_7 arr1;
	struct arr_0* temp0;
	struct failure** temp1;
	struct failure* temp2;
	res = spawn_and_wait_result_0(ctx, path_to_noze, (temp0 = (struct arr_0*) alloc(ctx, (sizeof(struct arr_0) * 2)), ((*((temp0 + 0)) = (struct arr_0) {3, "run"}, 0), ((*((temp0 + 1)) = path, 0), (struct arr_1) {2, temp0}))), env);
	if ((_op_equal_equal_2(res->exit_code, literal_2(ctx, (struct arr_0) {1, "0"})) && _op_equal_equal_4(res->stderr, (struct arr_0) {0, ""}))) {
		return handle_output(ctx, path, _op_plus_1(ctx, path, (struct arr_0) {7, ".stdout"}), res->stdout, overwrite_output__q);
	} else {
		message = _op_plus_1(ctx, _op_plus_1(ctx, _op_plus_1(ctx, _op_plus_1(ctx, _op_plus_1(ctx, (struct arr_0) {8, "status: "}, to_str_1(ctx, res->exit_code)), (struct arr_0) {9, "\nstdout:\n"}), res->stdout), (struct arr_0) {8, "stderr:\n"}), res->stderr);
		temp1 = (struct failure**) alloc(ctx, (sizeof(struct failure*) * 1));
		(*((temp1 + 0)) = (temp2 = (struct failure*) alloc(ctx, sizeof(struct failure)), ((*(temp2) = (struct failure) {path, message}, 0), temp2)), 0);
		return (struct arr_7) {1, temp1};
	}
}
struct arr_7 run_noze_tests__lambda0(struct ctx* ctx, struct run_noze_tests__lambda0* _closure, struct arr_0 test) {
	return run_single_noze_test(ctx, _closure->path_to_noze, _closure->env, test, _closure->options);
}
uint8_t has__q_6(struct arr_7 a) {
	return !empty__q_11(a);
}
struct err_2 err_2(struct arr_7 t) {
	return (struct err_2) {t};
}
struct result_3 do_test__lambda0__lambda0(struct ctx* ctx, struct do_test__lambda0__lambda0* _closure) {
	return run_noze_tests(ctx, child_path(ctx, _closure->test_path, (struct arr_0) {8, "runnable"}), _closure->noze_exe, _closure->env, _closure->options);
}
struct result_3 do_test__lambda0(struct ctx* ctx, struct do_test__lambda0* _closure) {
	struct do_test__lambda0__lambda0* temp0;
	return first_failures(ctx, run_noze_tests(ctx, child_path(ctx, _closure->test_path, (struct arr_0) {14, "compile-errors"}), _closure->noze_exe, _closure->env, _closure->options), (struct fun0) {(fun_ptr2_4) do_test__lambda0__lambda0, (uint8_t*) (temp0 = (struct do_test__lambda0__lambda0*) alloc(ctx, sizeof(struct do_test__lambda0__lambda0)), ((*(temp0) = (struct do_test__lambda0__lambda0) {_closure->test_path, _closure->noze_exe, _closure->env, _closure->options}, 0), temp0))});
}
struct result_3 lint(struct ctx* ctx, struct arr_0 path, struct test_options options) {
	struct arr_1 files;
	struct arr_7 failures;
	struct lint__lambda0* temp0;
	files = list_lintable_files(ctx, path);
	failures = flat_map_with_max_size(ctx, files, options.max_failures, (struct fun_mut1_12) {(fun_ptr3_13) lint__lambda0, (uint8_t*) (temp0 = (struct lint__lambda0*) alloc(ctx, sizeof(struct lint__lambda0)), ((*(temp0) = (struct lint__lambda0) {options}, 0), temp0))});
	if (has__q_6(failures)) {
		return (struct result_3) {1, .as1 = err_2(failures)};
	} else {
		return (struct result_3) {0, .as0 = ok_3(_op_plus_1(ctx, _op_plus_1(ctx, (struct arr_0) {7, "linted "}, to_str_3(ctx, files.size)), (struct arr_0) {6, " files"}))};
	}
}
struct arr_1 list_lintable_files(struct ctx* ctx, struct arr_0 path) {
	struct mut_arr_1* res;
	struct list_lintable_files__lambda1* temp0;
	res = new_mut_arr_0(ctx);
	each_child_recursive(ctx, path, (struct fun_mut1_6) {(fun_ptr3_7) list_lintable_files__lambda0, (uint8_t*) null_any()}, (struct fun_mut1_11) {(fun_ptr3_12) list_lintable_files__lambda1, (uint8_t*) (temp0 = (struct list_lintable_files__lambda1*) alloc(ctx, sizeof(struct list_lintable_files__lambda1)), ((*(temp0) = (struct list_lintable_files__lambda1) {res}, 0), temp0))});
	return freeze_0(res);
}
uint8_t excluded_from_lint__q(struct ctx* ctx, struct arr_0 name) {
	struct arr_1 arr;
	struct arr_1 bad_exts;
	struct arr_0* temp0;
	struct excluded_from_lint__q__lambda0* temp1;
	bad_exts = (temp0 = (struct arr_0*) alloc(ctx, (sizeof(struct arr_0) * 5)), ((*((temp0 + 0)) = (struct arr_0) {4, ".bmp"}, 0), ((*((temp0 + 1)) = (struct arr_0) {4, ".err"}, 0), ((*((temp0 + 2)) = (struct arr_0) {4, ".png"}, 0), ((*((temp0 + 3)) = (struct arr_0) {5, ".tata"}, 0), ((*((temp0 + 4)) = (struct arr_0) {5, ".wasm"}, 0), (struct arr_1) {5, temp0}))))));
	return (_op_equal_equal_3(first_0(ctx, name), literal_0((struct arr_0) {1, "."})) || (_op_equal_equal_4(name, (struct arr_0) {7, "libfirm"}) || some__q(ctx, bad_exts, (struct fun_mut1_6) {(fun_ptr3_7) excluded_from_lint__q__lambda0, (uint8_t*) (temp1 = (struct excluded_from_lint__q__lambda0*) alloc(ctx, sizeof(struct excluded_from_lint__q__lambda0)), ((*(temp1) = (struct excluded_from_lint__q__lambda0) {name}, 0), temp1))})));
}
uint8_t some__q(struct ctx* ctx, struct arr_1 a, struct fun_mut1_6 pred) {
	struct ctx* _tailCallctx;
	struct arr_1 _tailCalla;
	struct fun_mut1_6 _tailCallpred;
	top:
	if (!empty__q_6(a)) {
		if (call_10(ctx, pred, first_1(ctx, a))) {
			return 1;
		} else {
			_tailCallctx = ctx;
			_tailCalla = tail_2(ctx, a);
			_tailCallpred = pred;
			ctx = _tailCallctx;
			a = _tailCalla;
			pred = _tailCallpred;
			goto top;
		}
	} else {
		return 0;
	}
}
uint8_t ends_with__q(struct ctx* ctx, struct arr_0 a, struct arr_0 end) {
	return (_op_greater_equal(a.size, end.size) && arr_eq__q(ctx, slice_1(ctx, a, _op_minus_0(ctx, a.size, end.size), end.size), end));
}
uint8_t excluded_from_lint__q__lambda0(struct ctx* ctx, struct excluded_from_lint__q__lambda0* _closure, struct arr_0 it) {
	return ends_with__q(ctx, _closure->name, it);
}
uint8_t list_lintable_files__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr_0 it) {
	return !excluded_from_lint__q(ctx, it);
}
uint8_t ignore_extension_of_name(struct ctx* ctx, struct arr_0 name) {
	struct some_12 s;
	struct opt_12 matched;
	matched = get_extension(ctx, name);
	switch (matched.kind) {
		case 0:
			return 1;
		case 1:
			s = matched.as1;
			return ignore_extension(ctx, s.value);
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
	if (_op_equal_equal_0(i, a.size)) {
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
	struct arr_1 arr;
	struct arr_0* temp0;
	temp0 = (struct arr_0*) alloc(ctx, (sizeof(struct arr_0) * 6));
	(*((temp0 + 0)) = (struct arr_0) {1, "c"}, 0);
	(*((temp0 + 1)) = (struct arr_0) {4, "data"}, 0);
	(*((temp0 + 2)) = (struct arr_0) {1, "o"}, 0);
	(*((temp0 + 3)) = (struct arr_0) {3, "out"}, 0);
	(*((temp0 + 4)) = (struct arr_0) {4, "tata"}, 0);
	(*((temp0 + 5)) = (struct arr_0) {10, "tmLanguage"}, 0);
	return (struct arr_1) {6, temp0};
}
uint8_t list_lintable_files__lambda1(struct ctx* ctx, struct list_lintable_files__lambda1* _closure, struct arr_0 child) {
	if (ignore_extension_of_name(ctx, base_name(ctx, child))) {
		return 0;
	} else {
		return push_0(ctx, _closure->res, child);
	}
}
struct arr_7 lint_file(struct ctx* ctx, struct arr_0 path) {
	struct arr_0 text;
	struct mut_arr_5* res;
	uint8_t err_file__q;
	struct lint_file__lambda0* temp0;
	text = read_file(ctx, path);
	res = new_mut_arr_2(ctx);
	err_file__q = _op_equal_equal_4(force(ctx, get_extension(ctx, path)), (struct arr_0) {3, "err"});
	each_with_index_0(ctx, lines(ctx, text), (struct fun_mut2_3) {(fun_ptr4_4) lint_file__lambda0, (uint8_t*) (temp0 = (struct lint_file__lambda0*) alloc(ctx, sizeof(struct lint_file__lambda0)), ((*(temp0) = (struct lint_file__lambda0) {err_file__q, res, path}, 0), temp0))});
	return freeze_6(res);
}
struct arr_0 read_file(struct ctx* ctx, struct arr_0 path) {
	struct some_12 s;
	struct opt_12 matched;
	matched = try_read_file_0(ctx, path);
	switch (matched.kind) {
		case 0:
			print_sync(_op_plus_1(ctx, (struct arr_0) {21, "file does not exist: "}, path));
			return (struct arr_0) {0, ""};
		case 1:
			s = matched.as1;
			return s.value;
		default:
			return (assert(0),(struct arr_0) {0, NULL});
	}
}
uint8_t each_with_index_0(struct ctx* ctx, struct arr_1 a, struct fun_mut2_3 f) {
	return each_with_index_recur_0(ctx, a, f, 0);
}
uint8_t each_with_index_recur_0(struct ctx* ctx, struct arr_1 a, struct fun_mut2_3 f, uint64_t n) {
	struct ctx* _tailCallctx;
	struct arr_1 _tailCalla;
	struct fun_mut2_3 _tailCallf;
	uint64_t _tailCalln;
	top:
	if (_op_equal_equal_0(n, a.size)) {
		return 0;
	} else {
		call_26(ctx, f, at_2(ctx, a, n), n);
		_tailCallctx = ctx;
		_tailCalla = a;
		_tailCallf = f;
		_tailCalln = incr_0(ctx, n);
		ctx = _tailCallctx;
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
	struct mut_arr_1* res;
	struct cell_0* last_nl;
	struct lines__lambda0* temp0;
	res = new_mut_arr_0(ctx);
	last_nl = new_cell_3(ctx, 0);
	each_with_index_1(ctx, s, (struct fun_mut2_4) {(fun_ptr4_5) lines__lambda0, (uint8_t*) (temp0 = (struct lines__lambda0*) alloc(ctx, sizeof(struct lines__lambda0)), ((*(temp0) = (struct lines__lambda0) {res, s, last_nl}, 0), temp0))});
	push_0(ctx, res, slice_from_to(ctx, s, get_6(last_nl), s.size));
	return freeze_0(res);
}
struct cell_0* new_cell_3(struct ctx* ctx, uint64_t value) {
	struct cell_0* temp0;
	temp0 = (struct cell_0*) alloc(ctx, sizeof(struct cell_0));
	(*(temp0) = (struct cell_0) {value}, 0);
	return temp0;
}
uint8_t each_with_index_1(struct ctx* ctx, struct arr_0 a, struct fun_mut2_4 f) {
	return each_with_index_recur_1(ctx, a, f, 0);
}
uint8_t each_with_index_recur_1(struct ctx* ctx, struct arr_0 a, struct fun_mut2_4 f, uint64_t n) {
	struct ctx* _tailCallctx;
	struct arr_0 _tailCalla;
	struct fun_mut2_4 _tailCallf;
	uint64_t _tailCalln;
	top:
	if (_op_equal_equal_0(n, a.size)) {
		return 0;
	} else {
		call_27(ctx, f, at_3(ctx, a, n), n);
		_tailCallctx = ctx;
		_tailCalla = a;
		_tailCallf = f;
		_tailCalln = incr_0(ctx, n);
		ctx = _tailCallctx;
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
	return slice_1(ctx, a, begin, _op_minus_0(ctx, end, begin));
}
uint64_t swap_1(struct cell_0* c, uint64_t v) {
	uint64_t res;
	res = get_6(c);
	set_1(c, v);
	return res;
}
uint64_t get_6(struct cell_0* c) {
	return c->value;
}
uint8_t set_1(struct cell_0* c, uint64_t v) {
	return (c->value = v, 0);
}
uint8_t lines__lambda0(struct ctx* ctx, struct lines__lambda0* _closure, char c, uint64_t index) {
	if (_op_equal_equal_3(c, literal_0((struct arr_0) {1, "\n"}))) {
		return push_0(ctx, _closure->res, slice_from_to(ctx, _closure->s, swap_1(_closure->last_nl, incr_0(ctx, index)), index));
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
	struct ctx* _tailCallctx;
	struct arr_0 _tailCalla;
	top:
	if ((has__q_7(a) && _op_equal_equal_3(first_0(ctx, a), literal_0((struct arr_0) {1, " "})))) {
		_tailCallctx = ctx;
		_tailCalla = tail_1(ctx, a);
		ctx = _tailCallctx;
		a = _tailCalla;
		goto top;
	} else {
		return a;
	}
}
uint64_t line_len(struct ctx* ctx, struct arr_0 line) {
	return _op_plus_0(ctx, _op_times_0(ctx, n_tabs(ctx, line), _op_minus_0(ctx, tab_size(ctx), literal_1(ctx, (struct arr_0) {1, "1"}))), line.size);
}
uint64_t n_tabs(struct ctx* ctx, struct arr_0 line) {
	if ((!empty__q_0(line) && _op_equal_equal_3(first_0(ctx, line), literal_0((struct arr_0) {1, "\t"})))) {
		return incr_0(ctx, n_tabs(ctx, tail_1(ctx, line)));
	} else {
		return 0;
	}
}
uint64_t tab_size(struct ctx* ctx) {
	return literal_1(ctx, (struct arr_0) {1, "4"});
}
uint64_t max_line_length(struct ctx* ctx) {
	return literal_1(ctx, (struct arr_0) {3, "120"});
}
uint8_t lint_file__lambda0(struct ctx* ctx, struct lint_file__lambda0* _closure, struct arr_0 line, uint64_t line_num) {
	struct arr_0 ln;
	struct arr_0 message;
	uint64_t width;
	struct arr_0 message1;
	struct failure* temp0;
	struct failure* temp1;
	ln = to_str_3(ctx, incr_0(ctx, line_num));
	if ((!_closure->err_file__q && contains_subsequence__q(ctx, lstrip(ctx, line), (struct arr_0) {2, "  "}))) {
		message = _op_plus_1(ctx, _op_plus_1(ctx, (struct arr_0) {5, "line "}, ln), (struct arr_0) {24, " contains a double space"});
		push_2(ctx, _closure->res, (temp0 = (struct failure*) alloc(ctx, sizeof(struct failure)), ((*(temp0) = (struct failure) {_closure->path, message}, 0), temp0)));
	} else {
		0;
	}
	width = line_len(ctx, line);
	if (_op_greater_0(width, max_line_length(ctx))) {
		message1 = _op_plus_1(ctx, _op_plus_1(ctx, _op_plus_1(ctx, _op_plus_1(ctx, _op_plus_1(ctx, (struct arr_0) {5, "line "}, ln), (struct arr_0) {4, " is "}), to_str_3(ctx, width)), (struct arr_0) {28, " columns long, should be <= "}), to_str_3(ctx, max_line_length(ctx)));
		return push_2(ctx, _closure->res, (temp1 = (struct failure*) alloc(ctx, sizeof(struct failure)), ((*(temp1) = (struct failure) {_closure->path, message1}, 0), temp1)));
	} else {
		return 0;
	}
}
struct arr_7 lint__lambda0(struct ctx* ctx, struct lint__lambda0* _closure, struct arr_0 file) {
	if (_closure->options.print_tests__q) {
		print_sync(_op_plus_1(ctx, (struct arr_0) {5, "lint "}, file));
	} else {
		0;
	}
	return lint_file(ctx, file);
}
struct result_3 do_test__lambda1(struct ctx* ctx, struct do_test__lambda1* _closure) {
	return lint(ctx, _closure->noze_path, _closure->options);
}
int32_t print_failures(struct ctx* ctx, struct result_3 failures, struct test_options options) {
	struct ok_3 o;
	struct err_2 e;
	uint64_t n_failures;
	struct result_3 matched;
	matched = failures;
	switch (matched.kind) {
		case 0:
			o = matched.as0;
			print_sync(o.value);
			return literal_2(ctx, (struct arr_0) {1, "0"});
		case 1:
			e = matched.as1;
			each_2(ctx, e.value, (struct fun_mut1_13) {(fun_ptr3_14) print_failures__lambda0, (uint8_t*) null_any()});
			n_failures = e.value.size;
			print_sync((_op_equal_equal_0(n_failures, options.max_failures) ? _op_plus_1(ctx, _op_plus_1(ctx, (struct arr_0) {15, "hit maximum of "}, to_str_3(ctx, options.max_failures)), (struct arr_0) {9, " failures"}) : _op_plus_1(ctx, to_str_3(ctx, n_failures), (struct arr_0) {9, " failures"})));
			return to_int32(ctx, n_failures);
		default:
			return (assert(0),0);
	}
}
uint8_t print_failure(struct ctx* ctx, struct failure* failure) {
	print_bold(ctx);
	print_sync_no_newline(failure->path);
	print_reset(ctx);
	print_sync_no_newline((struct arr_0) {1, " "});
	return print_sync(failure->message);
}
uint8_t print_bold(struct ctx* ctx) {
	return print_sync_no_newline((struct arr_0) {4, "\x1b[1m"});
}
uint8_t print_reset(struct ctx* ctx) {
	return print_sync_no_newline((struct arr_0) {3, "\x1b[m"});
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
