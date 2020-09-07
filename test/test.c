#include <assert.h>
#include <errno.h>
#include <stdatomic.h>
#include <stddef.h>
#include <stdint.h>
typedef uint8_t* (*fun_ptr1__ptr__byte__ptr__byte)(uint8_t*);
struct ctx {
	uint8_t* gctx_ptr;
	uint64_t vat_id;
	uint64_t actor_id;
	uint8_t* gc_ctx_ptr;
	uint8_t* exception_ctx_ptr;
};
struct fut__int32;
struct lock;
struct _atomic_bool {
	uint8_t value;
};
struct fut_state_callbacks__int32;
struct fut_callback_node__int32;
struct exception;
struct arr__char {
	uint64_t size;
	char* data;
};
struct ok__int32 {
	int32_t value;
};
struct err__exception;
struct fun_mut1___void__result__int32__exception;
struct none {
	uint8_t __mustBeNonEmpty;
};
struct some__ptr_fut_callback_node__int32 {
	struct fut_callback_node__int32* value;
};
struct fut_state_resolved__int32 {
	int32_t value;
};
struct arr__arr__char {
	uint64_t size;
	struct arr__char* data;
};
struct global_ctx;
struct vat;
struct gc;
struct gc_ctx;
struct some__ptr_gc_ctx {
	struct gc_ctx* value;
};
struct task;
struct fun_mut0___void;
struct mut_bag__task;
struct mut_bag_node__task;
struct some__ptr_mut_bag_node__task {
	struct mut_bag_node__task* value;
};
struct mut_arr__nat {
	uint8_t frozen__q;
	uint64_t size;
	uint64_t capacity;
	uint64_t* data;
};
struct thread_safe_counter;
struct fun_mut1___void__exception;
struct arr__ptr_vat {
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
struct arr__ptr__char {
	uint64_t size;
	char** data;
};
struct fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char;
struct fut___void;
struct fut_state_callbacks___void;
struct fut_callback_node___void;
struct ok___void {
	uint8_t value;
};
struct fun_mut1___void__result___void__exception;
struct some__ptr_fut_callback_node___void {
	struct fut_callback_node___void* value;
};
struct fut_state_resolved___void {
	uint8_t value;
};
struct fun_ref0__int32;
struct vat_and_actor_id {
	uint64_t vat;
	uint64_t actor;
};
struct fun_mut0__ptr_fut__int32;
struct fun_ref1__int32___void;
struct fun_mut1__ptr_fut__int32___void;
struct some__ptr__byte {
	uint8_t* value;
};
struct then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0___closure;
struct forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0___closure {
	struct fut__int32* to;
};
struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0___closure;
struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0___closure;
struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1___closure {
	struct fut__int32* res;
};
struct then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0___closure;
struct call__ptr_fut__int32__fun_ref0__int32__lambda0___closure;
struct call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0___closure;
struct call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1___closure {
	struct fut__int32* res;
};
struct add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0___closure;
struct fun_mut1__arr__char__ptr__char;
struct fun_mut1__arr__char__nat;
struct mut_arr__arr__char {
	uint8_t frozen__q;
	uint64_t size;
	uint64_t capacity;
	struct arr__char* data;
};
struct map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0___closure;
struct thread_args__ptr_global_ctx;
struct cell__nat {
	uint64_t value;
};
struct cell__ptr__byte {
	uint8_t* value;
};
struct chosen_task;
struct some__task;
struct no_chosen_task {
	uint8_t last_thread_out;
};
struct ok__chosen_task;
struct err__no_chosen_task {
	struct no_chosen_task value;
};
struct some__chosen_task;
struct some__opt__task;
struct task_and_nodes;
struct some__task_and_nodes;
struct arr__nat {
	uint64_t size;
	uint64_t* data;
};
struct test_options {
	uint8_t print_tests__q;
	uint8_t overwrite_output__q;
	uint64_t max_failures;
};
struct some__test_options {
	struct test_options value;
};
struct some__arr__arr__char {
	struct arr__arr__char value;
};
struct arr__opt__arr__arr__char;
struct fun1__test_options__arr__opt__arr__arr__char;
struct parsed_cmd_line_args;
struct dict__arr__char__arr__arr__char;
struct arr__arr__arr__char {
	uint64_t size;
	struct arr__arr__char* data;
};
struct some__nat {
	uint64_t value;
};
struct fun_mut1__bool__arr__char;
struct mut_dict__arr__char__arr__arr__char;
struct mut_arr__arr__arr__char {
	uint8_t frozen__q;
	uint64_t size;
	uint64_t capacity;
	struct arr__arr__char* data;
};
struct some__arr__char {
	struct arr__char value;
};
struct mut_arr__opt__arr__arr__char;
struct fun_mut1__opt__arr__arr__char__nat;
struct fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0___closure;
struct cell__bool {
	uint8_t value;
};
struct fun_mut2___void__arr__char__arr__arr__char;
struct parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char__lambda0___closure {
	struct arr__arr__char t_names;
	struct cell__bool* help;
	struct mut_arr__opt__arr__arr__char* values;
};
struct index_of__opt__nat__arr__arr__char__arr__char__lambda0___closure {
	struct arr__char value;
};
struct fun_mut1__char__nat;
struct mut_arr__char {
	uint8_t frozen__q;
	uint64_t size;
	uint64_t capacity;
	char* data;
};
struct _op_plus__arr__char__arr__char__arr__char__lambda0___closure {
	struct arr__char a;
	struct arr__char b;
};
struct fun_mut1__bool__char;
struct r_index_of__opt__nat__arr__char__char__lambda0___closure {
	char value;
};
struct dict__arr__char__arr__char {
	struct arr__arr__char keys;
	struct arr__arr__char values;
};
struct mut_dict__arr__char__arr__char {
	struct mut_arr__arr__char* keys;
	struct mut_arr__arr__char* values;
};
struct key_value_pair__arr__char__arr__char {
	struct arr__char key;
	struct arr__char value;
};
struct failure {
	struct arr__char path;
	struct arr__char message;
};
struct arr__ptr_failure {
	uint64_t size;
	struct failure** data;
};
struct ok__arr__char {
	struct arr__char value;
};
struct err__arr__ptr_failure {
	struct arr__ptr_failure value;
};
struct fun_mut1___void__arr__char;
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
struct some__ptr_stat_t {
	struct stat_t* value;
};
struct dirent;
struct bytes256;
struct cell__ptr_dirent {
	struct dirent* value;
};
struct to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char__lambda0___closure {
	struct arr__arr__char a;
};
struct mut_slice__arr__char {
	struct mut_arr__arr__char* backing;
	uint64_t size;
	uint64_t begin;
};
struct each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0___closure;
struct list_compile_error_tests__arr__arr__char__arr__char__lambda1___closure {
	struct mut_arr__arr__char* res;
};
struct fun_mut1__arr__ptr_failure__arr__char;
struct mut_arr__ptr_failure {
	uint8_t frozen__q;
	uint64_t size;
	uint64_t capacity;
	struct failure** data;
};
struct flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0___closure;
struct fun_mut1___void__ptr_failure;
struct push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure__lambda0___closure {
	struct mut_arr__ptr_failure* a;
};
struct run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure {
	struct test_options options;
	struct arr__char path_to_noze;
	struct dict__arr__char__arr__char* env;
};
struct process_result {
	int32_t exit_code;
	struct arr__char stdout;
	struct arr__char stderr;
};
struct fun_mut2__arr__char__arr__char__arr__char;
struct pipes {
	int32_t write_pipe;
	int32_t read_pipe;
};
struct posix_spawn_file_actions_t;
struct cell__int32 {
	int32_t value;
};
struct pollfd {
	int32_t fd;
	int16_t events;
	int16_t revents;
};
struct arr__pollfd {
	uint64_t size;
	struct pollfd* data;
};
struct handle_revents_result {
	uint8_t had_pollin__q;
	uint8_t hung_up__q;
};
struct fun_mut1__ptr__char__nat;
struct mut_arr__ptr__char {
	uint8_t frozen__q;
	uint64_t size;
	uint64_t capacity;
	char** data;
};
struct _op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char__lambda0___closure {
	struct arr__ptr__char a;
	struct arr__ptr__char b;
};
struct fun_mut1__ptr__char__arr__char;
struct map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0___closure;
struct fun_mut2___void__arr__char__arr__char;
struct convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char__lambda0___closure {
	struct mut_arr__ptr__char* res;
};
struct fun0__result__arr__char__arr__ptr_failure;
struct fun_mut1__result__arr__char__arr__ptr_failure__arr__char;
struct first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0___closure;
struct first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0__lambda0___closure {
	struct arr__char a_descr;
};
struct do_test__int32__test_options__lambda0___closure {
	struct arr__char test_path;
	struct arr__char noze_exe;
	struct dict__arr__char__arr__char* env;
	struct test_options options;
};
struct list_ast_and_model_tests__arr__arr__char__arr__char__lambda1___closure {
	struct mut_arr__arr__char* res;
};
struct run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure {
	struct test_options options;
	struct arr__char path_to_noze;
	struct dict__arr__char__arr__char* env;
};
struct some__arr__ptr_failure {
	struct arr__ptr_failure value;
};
struct fun_mut1__opt__arr__ptr_failure__arr__char;
struct run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0___closure {
	struct arr__char path_to_noze;
	struct dict__arr__char__arr__char* env;
	struct arr__char test;
	struct test_options options;
};
struct fun_mut0__arr__ptr_failure;
struct do_test__int32__test_options__lambda0__lambda0___closure {
	struct arr__char test_path;
	struct arr__char noze_exe;
	struct dict__arr__char__arr__char* env;
	struct test_options options;
};
struct list_runnable_tests__arr__arr__char__arr__char__lambda1___closure {
	struct mut_arr__arr__char* res;
};
struct run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure {
	struct test_options options;
	struct arr__char path_to_noze;
	struct dict__arr__char__arr__char* env;
};
struct do_test__int32__test_options__lambda1___closure {
	struct arr__char noze_path;
	struct test_options options;
};
struct list_lintable_files__arr__arr__char__arr__char__lambda1___closure {
	struct mut_arr__arr__char* res;
};
struct lint__result__arr__char__arr__ptr_failure__arr__char__test_options__lambda0___closure {
	struct test_options options;
};
struct fun_mut2___void__arr__char__nat;
struct fun_mut2___void__char__nat;
struct lines__arr__arr__char__arr__char__lambda0___closure {
	struct mut_arr__arr__char* res;
	struct arr__char s;
	struct cell__nat* last_nl;
};
struct lint_file__arr__ptr_failure__arr__char__lambda0___closure {
	uint8_t err_file__q;
	struct mut_arr__ptr_failure* res;
	struct arr__char path;
};
struct fut_state__int32;
struct result__int32__exception;
struct opt__ptr_fut_callback_node__int32 {
	int kind;
	union {
		struct none as0;
		struct some__ptr_fut_callback_node__int32 as1;
	};
};
struct opt__ptr_gc_ctx {
	int kind;
	union {
		struct none as0;
		struct some__ptr_gc_ctx as1;
	};
};
struct opt__ptr_mut_bag_node__task {
	int kind;
	union {
		struct none as0;
		struct some__ptr_mut_bag_node__task as1;
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
struct fut_state___void;
struct result___void__exception;
struct opt__ptr_fut_callback_node___void {
	int kind;
	union {
		struct none as0;
		struct some__ptr_fut_callback_node___void as1;
	};
};
struct opt__ptr__byte {
	int kind;
	union {
		struct none as0;
		struct some__ptr__byte as1;
	};
};
struct opt__task;
struct result__chosen_task__no_chosen_task;
struct opt__chosen_task;
struct opt__opt__task;
struct opt__task_and_nodes;
struct opt__test_options {
	int kind;
	union {
		struct none as0;
		struct some__test_options as1;
	};
};
struct opt__arr__arr__char {
	int kind;
	union {
		struct none as0;
		struct some__arr__arr__char as1;
	};
};
struct opt__nat {
	int kind;
	union {
		struct none as0;
		struct some__nat as1;
	};
};
struct opt__arr__char {
	int kind;
	union {
		struct none as0;
		struct some__arr__char as1;
	};
};
struct result__arr__char__arr__ptr_failure {
	int kind;
	union {
		struct ok__arr__char as0;
		struct err__arr__ptr_failure as1;
	};
};
struct opt__ptr_stat_t {
	int kind;
	union {
		struct none as0;
		struct some__ptr_stat_t as1;
	};
};
struct opt__arr__ptr_failure {
	int kind;
	union {
		struct none as0;
		struct some__arr__ptr_failure as1;
	};
};
typedef uint8_t (*fun_ptr3___void__ptr_ctx__ptr__byte__result__int32__exception)(struct ctx*, uint8_t*, struct result__int32__exception);
typedef struct fut__int32* (*fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char)(struct ctx*, struct arr__arr__char);
typedef uint8_t (*fun_ptr2___void__ptr_ctx__ptr__byte)(struct ctx*, uint8_t*);
typedef uint8_t (*fun_ptr3___void__ptr_ctx__ptr__byte__exception)(struct ctx*, uint8_t*, struct exception);
typedef struct fut__int32* (*fun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char)(struct ctx*, uint8_t*, struct arr__ptr__char, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char);
typedef uint8_t (*fun_ptr3___void__ptr_ctx__ptr__byte__result___void__exception)(struct ctx*, uint8_t*, struct result___void__exception);
typedef struct fut__int32* (*fun_ptr2__ptr_fut__int32__ptr_ctx__ptr__byte)(struct ctx*, uint8_t*);
typedef struct fut__int32* (*fun_ptr3__ptr_fut__int32__ptr_ctx__ptr__byte___void)(struct ctx*, uint8_t*, uint8_t);
typedef struct arr__char (*fun_ptr3__arr__char__ptr_ctx__ptr__byte__ptr__char)(struct ctx*, uint8_t*, char*);
typedef struct arr__char (*fun_ptr3__arr__char__ptr_ctx__ptr__byte__nat)(struct ctx*, uint8_t*, uint64_t);
typedef uint8_t (*fun_ptr2___void__nat__ptr_global_ctx)(uint64_t, struct global_ctx*);
typedef struct test_options (*fun_ptr3__test_options__ptr_ctx__ptr__byte__arr__opt__arr__arr__char)(struct ctx*, uint8_t*, struct arr__opt__arr__arr__char);
typedef uint8_t (*fun_ptr3__bool__ptr_ctx__ptr__byte__arr__char)(struct ctx*, uint8_t*, struct arr__char);
typedef struct opt__arr__arr__char (*fun_ptr3__opt__arr__arr__char__ptr_ctx__ptr__byte__nat)(struct ctx*, uint8_t*, uint64_t);
typedef uint8_t (*fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__arr__char)(struct ctx*, uint8_t*, struct arr__char, struct arr__arr__char);
typedef char (*fun_ptr3__char__ptr_ctx__ptr__byte__nat)(struct ctx*, uint8_t*, uint64_t);
typedef uint8_t (*fun_ptr3__bool__ptr_ctx__ptr__byte__char)(struct ctx*, uint8_t*, char);
typedef uint8_t (*fun_ptr3___void__ptr_ctx__ptr__byte__arr__char)(struct ctx*, uint8_t*, struct arr__char);
typedef struct arr__ptr_failure (*fun_ptr3__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char)(struct ctx*, uint8_t*, struct arr__char);
typedef uint8_t (*fun_ptr3___void__ptr_ctx__ptr__byte__ptr_failure)(struct ctx*, uint8_t*, struct failure*);
typedef struct arr__char (*fun_ptr4__arr__char__ptr_ctx__ptr__byte__arr__char__arr__char)(struct ctx*, uint8_t*, struct arr__char, struct arr__char);
typedef char* (*fun_ptr3__ptr__char__ptr_ctx__ptr__byte__nat)(struct ctx*, uint8_t*, uint64_t);
typedef char* (*fun_ptr3__ptr__char__ptr_ctx__ptr__byte__arr__char)(struct ctx*, uint8_t*, struct arr__char);
typedef uint8_t (*fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__char)(struct ctx*, uint8_t*, struct arr__char, struct arr__char);
typedef struct result__arr__char__arr__ptr_failure (*fun_ptr2__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte)(struct ctx*, uint8_t*);
typedef struct result__arr__char__arr__ptr_failure (*fun_ptr3__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char)(struct ctx*, uint8_t*, struct arr__char);
typedef struct opt__arr__ptr_failure (*fun_ptr3__opt__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char)(struct ctx*, uint8_t*, struct arr__char);
typedef struct arr__ptr_failure (*fun_ptr2__arr__ptr_failure__ptr_ctx__ptr__byte)(struct ctx*, uint8_t*);
typedef uint8_t (*fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__nat)(struct ctx*, uint8_t*, struct arr__char, uint64_t);
typedef uint8_t (*fun_ptr4___void__ptr_ctx__ptr__byte__char__nat)(struct ctx*, uint8_t*, char, uint64_t);
struct fut__int32;
struct lock {
	struct _atomic_bool is_locked;
};
struct fut_state_callbacks__int32 {
	struct opt__ptr_fut_callback_node__int32 head;
};
struct fut_callback_node__int32;
struct exception {
	struct arr__char message;
};
struct err__exception {
	struct exception value;
};
struct fun_mut1___void__result__int32__exception {
	fun_ptr3___void__ptr_ctx__ptr__byte__result__int32__exception fun_ptr;
	uint8_t* closure;
};
struct global_ctx;
struct vat;
struct gc {
	struct lock lk;
	struct opt__ptr_gc_ctx context_head;
	uint8_t needs_gc;
	uint8_t is_doing_gc;
	uint8_t* begin;
	uint8_t* next_byte;
};
struct gc_ctx {
	struct gc* gc;
	struct opt__ptr_gc_ctx next_ctx;
};
struct task;
struct fun_mut0___void {
	fun_ptr2___void__ptr_ctx__ptr__byte fun_ptr;
	uint8_t* closure;
};
struct mut_bag__task {
	struct opt__ptr_mut_bag_node__task head;
};
struct mut_bag_node__task;
struct thread_safe_counter {
	struct lock lk;
	uint64_t value;
};
struct fun_mut1___void__exception {
	fun_ptr3___void__ptr_ctx__ptr__byte__exception fun_ptr;
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
struct fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char {
	fun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char fun_ptr;
	uint8_t* closure;
};
struct fut___void;
struct fut_state_callbacks___void {
	struct opt__ptr_fut_callback_node___void head;
};
struct fut_callback_node___void;
struct fun_mut1___void__result___void__exception {
	fun_ptr3___void__ptr_ctx__ptr__byte__result___void__exception fun_ptr;
	uint8_t* closure;
};
struct fun_ref0__int32;
struct fun_mut0__ptr_fut__int32 {
	fun_ptr2__ptr_fut__int32__ptr_ctx__ptr__byte fun_ptr;
	uint8_t* closure;
};
struct fun_ref1__int32___void;
struct fun_mut1__ptr_fut__int32___void {
	fun_ptr3__ptr_fut__int32__ptr_ctx__ptr__byte___void fun_ptr;
	uint8_t* closure;
};
struct then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0___closure;
struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0___closure;
struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0___closure;
struct then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0___closure;
struct call__ptr_fut__int32__fun_ref0__int32__lambda0___closure;
struct call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0___closure;
struct add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0___closure {
	struct arr__ptr__char all_args;
	fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char main_ptr;
};
struct fun_mut1__arr__char__ptr__char {
	fun_ptr3__arr__char__ptr_ctx__ptr__byte__ptr__char fun_ptr;
	uint8_t* closure;
};
struct fun_mut1__arr__char__nat {
	fun_ptr3__arr__char__ptr_ctx__ptr__byte__nat fun_ptr;
	uint8_t* closure;
};
struct map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0___closure {
	struct fun_mut1__arr__char__ptr__char mapper;
	struct arr__ptr__char a;
};
struct thread_args__ptr_global_ctx {
	fun_ptr2___void__nat__ptr_global_ctx fun;
	uint64_t thread_id;
	struct global_ctx* arg;
};
struct chosen_task;
struct some__task;
struct ok__chosen_task;
struct some__chosen_task;
struct some__opt__task;
struct task_and_nodes;
struct some__task_and_nodes;
struct arr__opt__arr__arr__char {
	uint64_t size;
	struct opt__arr__arr__char* data;
};
struct fun1__test_options__arr__opt__arr__arr__char {
	fun_ptr3__test_options__ptr_ctx__ptr__byte__arr__opt__arr__arr__char fun_ptr;
	uint8_t* closure;
};
struct parsed_cmd_line_args {
	struct arr__arr__char nameless;
	struct dict__arr__char__arr__arr__char* named;
	struct arr__arr__char after;
};
struct dict__arr__char__arr__arr__char {
	struct arr__arr__char keys;
	struct arr__arr__arr__char values;
};
struct fun_mut1__bool__arr__char {
	fun_ptr3__bool__ptr_ctx__ptr__byte__arr__char fun_ptr;
	uint8_t* closure;
};
struct mut_dict__arr__char__arr__arr__char {
	struct mut_arr__arr__char* keys;
	struct mut_arr__arr__arr__char* values;
};
struct mut_arr__opt__arr__arr__char {
	uint8_t frozen__q;
	uint64_t size;
	uint64_t capacity;
	struct opt__arr__arr__char* data;
};
struct fun_mut1__opt__arr__arr__char__nat {
	fun_ptr3__opt__arr__arr__char__ptr_ctx__ptr__byte__nat fun_ptr;
	uint8_t* closure;
};
struct fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0___closure {
	struct opt__arr__arr__char value;
};
struct fun_mut2___void__arr__char__arr__arr__char {
	fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__arr__char fun_ptr;
	uint8_t* closure;
};
struct fun_mut1__char__nat {
	fun_ptr3__char__ptr_ctx__ptr__byte__nat fun_ptr;
	uint8_t* closure;
};
struct fun_mut1__bool__char {
	fun_ptr3__bool__ptr_ctx__ptr__byte__char fun_ptr;
	uint8_t* closure;
};
struct fun_mut1___void__arr__char {
	fun_ptr3___void__ptr_ctx__ptr__byte__arr__char fun_ptr;
	uint8_t* closure;
};
struct dirent;
struct bytes256;
struct each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0___closure {
	struct fun_mut1__bool__arr__char filter;
	struct arr__char path;
	struct fun_mut1___void__arr__char f;
};
struct fun_mut1__arr__ptr_failure__arr__char {
	fun_ptr3__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char fun_ptr;
	uint8_t* closure;
};
struct flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0___closure {
	struct mut_arr__ptr_failure* res;
	uint64_t max_size;
	struct fun_mut1__arr__ptr_failure__arr__char mapper;
};
struct fun_mut1___void__ptr_failure {
	fun_ptr3___void__ptr_ctx__ptr__byte__ptr_failure fun_ptr;
	uint8_t* closure;
};
struct fun_mut2__arr__char__arr__char__arr__char {
	fun_ptr4__arr__char__ptr_ctx__ptr__byte__arr__char__arr__char fun_ptr;
	uint8_t* closure;
};
struct posix_spawn_file_actions_t;
struct fun_mut1__ptr__char__nat {
	fun_ptr3__ptr__char__ptr_ctx__ptr__byte__nat fun_ptr;
	uint8_t* closure;
};
struct fun_mut1__ptr__char__arr__char {
	fun_ptr3__ptr__char__ptr_ctx__ptr__byte__arr__char fun_ptr;
	uint8_t* closure;
};
struct map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0___closure {
	struct fun_mut1__ptr__char__arr__char mapper;
	struct arr__arr__char a;
};
struct fun_mut2___void__arr__char__arr__char {
	fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__char fun_ptr;
	uint8_t* closure;
};
struct fun0__result__arr__char__arr__ptr_failure {
	fun_ptr2__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte fun_ptr;
	uint8_t* closure;
};
struct fun_mut1__result__arr__char__arr__ptr_failure__arr__char {
	fun_ptr3__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char fun_ptr;
	uint8_t* closure;
};
struct first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0___closure {
	struct fun0__result__arr__char__arr__ptr_failure b;
};
struct fun_mut1__opt__arr__ptr_failure__arr__char {
	fun_ptr3__opt__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char fun_ptr;
	uint8_t* closure;
};
struct fun_mut0__arr__ptr_failure {
	fun_ptr2__arr__ptr_failure__ptr_ctx__ptr__byte fun_ptr;
	uint8_t* closure;
};
struct fun_mut2___void__arr__char__nat {
	fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__nat fun_ptr;
	uint8_t* closure;
};
struct fun_mut2___void__char__nat {
	fun_ptr4___void__ptr_ctx__ptr__byte__char__nat fun_ptr;
	uint8_t* closure;
};
struct fut_state__int32 {
	int kind;
	union {
		struct fut_state_callbacks__int32 as0;
		struct fut_state_resolved__int32 as1;
		struct exception as2;
	};
};
struct result__int32__exception {
	int kind;
	union {
		struct ok__int32 as0;
		struct err__exception as1;
	};
};
struct fut_state___void {
	int kind;
	union {
		struct fut_state_callbacks___void as0;
		struct fut_state_resolved___void as1;
		struct exception as2;
	};
};
struct result___void__exception {
	int kind;
	union {
		struct ok___void as0;
		struct err__exception as1;
	};
};
struct opt__task;
struct result__chosen_task__no_chosen_task;
struct opt__chosen_task;
struct opt__opt__task;
struct opt__task_and_nodes;
struct fut__int32 {
	struct lock lk;
	struct fut_state__int32 state;
};
struct fut_callback_node__int32 {
	struct fun_mut1___void__result__int32__exception cb;
	struct opt__ptr_fut_callback_node__int32 next_node;
};
struct global_ctx {
	struct lock lk;
	struct arr__ptr_vat vats;
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
	struct mut_bag__task tasks;
	struct mut_arr__nat currently_running_actors;
	uint64_t n_threads_running;
	struct thread_safe_counter next_actor_id;
	struct fun_mut1___void__exception exception_handler;
};
struct task {
	uint64_t actor_id;
	struct fun_mut0___void fun;
};
struct mut_bag_node__task {
	struct task value;
	struct opt__ptr_mut_bag_node__task next_node;
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
struct fut___void {
	struct lock lk;
	struct fut_state___void state;
};
struct fut_callback_node___void {
	struct fun_mut1___void__result___void__exception cb;
	struct opt__ptr_fut_callback_node___void next_node;
};
struct fun_ref0__int32 {
	struct vat_and_actor_id vat_and_actor;
	struct fun_mut0__ptr_fut__int32 fun;
};
struct fun_ref1__int32___void {
	struct vat_and_actor_id vat_and_actor;
	struct fun_mut1__ptr_fut__int32___void fun;
};
struct then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0___closure {
	struct fun_ref1__int32___void cb;
	struct fut__int32* res;
};
struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0___closure {
	struct fun_ref1__int32___void f;
	uint8_t p0;
	struct fut__int32* res;
};
struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0___closure {
	struct fun_ref1__int32___void f;
	uint8_t p0;
	struct fut__int32* res;
};
struct then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0___closure {
	struct fun_ref0__int32 cb;
};
struct call__ptr_fut__int32__fun_ref0__int32__lambda0___closure {
	struct fun_ref0__int32 f;
	struct fut__int32* res;
};
struct call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0___closure {
	struct fun_ref0__int32 f;
	struct fut__int32* res;
};
struct chosen_task;
struct some__task {
	struct task value;
};
struct ok__chosen_task;
struct some__chosen_task;
struct some__opt__task;
struct task_and_nodes {
	struct task task;
	struct opt__ptr_mut_bag_node__task nodes;
};
struct some__task_and_nodes {
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
struct opt__task {
	int kind;
	union {
		struct none as0;
		struct some__task as1;
	};
};
struct result__chosen_task__no_chosen_task;
struct opt__chosen_task;
struct opt__opt__task;
struct opt__task_and_nodes {
	int kind;
	union {
		struct none as0;
		struct some__task_and_nodes as1;
	};
};
struct jmp_buf_tag {
	struct bytes64 jmp_buf;
	int32_t mask_was_saved;
	struct bytes128 saved_mask;
};
struct chosen_task {
	struct vat* vat;
	struct opt__task task_or_gc;
};
struct ok__chosen_task {
	struct chosen_task value;
};
struct some__chosen_task {
	struct chosen_task value;
};
struct some__opt__task {
	struct opt__task value;
};
struct dirent {
	uint64_t d_ino;
	int64_t d_off;
	uint16_t d_reclen;
	char d_type;
	struct bytes256 d_name;
};
struct result__chosen_task__no_chosen_task {
	int kind;
	union {
		struct ok__chosen_task as0;
		struct err__no_chosen_task as1;
	};
};
struct opt__chosen_task {
	int kind;
	union {
		struct none as0;
		struct some__chosen_task as1;
	};
};
struct opt__opt__task {
	int kind;
	union {
		struct none as0;
		struct some__opt__task as1;
	};
};

int32_t rt_main__int32__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(int32_t argc, char** argv, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char main_ptr);
uint64_t two__nat();
uint64_t wrap_incr__nat__nat(uint64_t a);
struct lock new_lock__lock();
struct _atomic_bool new_atomic_bool___atomic_bool();
struct arr__ptr_vat empty_arr__arr__ptr_vat();
struct condition new_condition__condition();
struct vat new_vat__vat__ptr_global_ctx__nat__nat(struct global_ctx* gctx, uint64_t id, uint64_t max_threads);
struct mut_arr__nat new_mut_arr_by_val_with_capacity_from_unmanaged_memory__mut_arr__nat__nat(uint64_t capacity);
uint64_t* unmanaged_alloc_elements__ptr__nat__nat(uint64_t size_elements);
uint8_t* unmanaged_alloc_bytes__ptr__byte__nat(uint64_t size);
extern uint8_t* malloc(uint64_t size);
uint8_t hard_forbid___void__bool(uint8_t condition);
uint8_t hard_assert___void__bool(uint8_t condition);
uint8_t null__q__bool__ptr__byte(uint8_t* a);
uint8_t _op_equal_equal__bool__ptr__byte__ptr__byte(uint8_t* a, uint8_t* b);
struct comparison _op_less_equal_greater__comparison__ptr__byte__ptr__byte(uint8_t* a, uint8_t* b);
struct gc new_gc__gc();
struct none none__none();
struct mut_bag__task new_mut_bag__mut_bag__task();
struct thread_safe_counter new_thread_safe_counter__thread_safe_counter();
struct thread_safe_counter new_thread_safe_counter__thread_safe_counter__nat(uint64_t init);
uint8_t default_exception_handler___void__exception(struct ctx* ctx, struct exception e);
uint8_t print_err_sync_no_newline___void__arr__char(struct arr__char s);
uint8_t write_sync_no_newline___void__int32__arr__char(int32_t fd, struct arr__char s);
uint8_t _op_equal_equal__bool__nat__nat(uint64_t a, uint64_t b);
struct comparison _op_less_equal_greater__comparison__nat__nat(uint64_t a, uint64_t b);
extern int64_t write(int32_t fd, uint8_t* buff, uint64_t n_bytes);
uint8_t _op_equal_equal__bool___int___int(int64_t a, int64_t b);
struct comparison _op_less_equal_greater__comparison___int___int(int64_t a, int64_t b);
uint8_t todo___void();
int32_t stderr_fd__int32();
int32_t two__int32();
int32_t wrap_incr__int32__int32(int32_t a);
uint8_t print_err_sync___void__arr__char(struct arr__char s);
uint8_t empty__q__bool__arr__char(struct arr__char a);
uint8_t zero__q__bool__nat(uint64_t n);
struct global_ctx* get_gctx__ptr_global_ctx(struct ctx* ctx);
uint8_t new_vat__vat__ptr_global_ctx__nat__nat__lambda0(struct ctx* ctx, uint8_t* _closure, struct exception it);
struct exception_ctx new_exception_ctx__exception_ctx();
struct ctx new_ctx__ctx__ptr_global_ctx__ptr_thread_local_stuff__ptr_vat__nat(struct global_ctx* gctx, struct thread_local_stuff* tls, struct vat* vat, uint64_t actor_id);
struct gc_ctx* get_gc_ctx__ptr_gc_ctx__ptr_gc(struct gc* gc);
uint8_t acquire_lock___void__ptr_lock(struct lock* a);
uint8_t acquire_lock_recur___void__ptr_lock__nat(struct lock* a, uint64_t n_tries);
uint8_t try_acquire_lock__bool__ptr_lock(struct lock* a);
uint8_t try_set__bool__ptr__atomic_bool(struct _atomic_bool* a);
uint8_t try_change__bool__ptr__atomic_bool__bool(struct _atomic_bool* a, uint8_t old_value);
uint64_t thousand__nat();
uint64_t hundred__nat();
uint64_t ten__nat();
uint64_t nine__nat();
uint64_t eight__nat();
uint64_t seven__nat();
uint64_t six__nat();
uint64_t five__nat();
uint64_t four__nat();
uint64_t three__nat();
uint8_t yield_thread___void();
extern int32_t pthread_yield();
extern void usleep(uint64_t micro_seconds);
uint8_t zero__q__bool__int32(int32_t i);
uint8_t _op_equal_equal__bool__int32__int32(int32_t a, int32_t b);
struct comparison _op_less_equal_greater__comparison__int32__int32(int32_t a, int32_t b);
uint64_t noctx_incr__nat__nat(uint64_t n);
uint8_t _op_less__bool__nat__nat(uint64_t a, uint64_t b);
uint64_t billion__nat();
uint64_t million__nat();
uint8_t release_lock___void__ptr_lock(struct lock* l);
uint8_t must_unset___void__ptr__atomic_bool(struct _atomic_bool* a);
uint8_t try_unset__bool__ptr__atomic_bool(struct _atomic_bool* a);
struct fut__int32* add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(struct ctx* ctx, struct arr__ptr__char all_args, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char main_ptr);
struct fut__int32* then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32(struct ctx* ctx, struct fut___void* f, struct fun_ref0__int32 cb);
struct fut__int32* then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void(struct ctx* ctx, struct fut___void* f, struct fun_ref1__int32___void cb);
struct fut__int32* new_unresolved_fut__ptr_fut__int32(struct ctx* ctx);
uint8_t* alloc__ptr__byte__nat(struct ctx* ctx, uint64_t size);
uint8_t* gc_alloc__ptr__byte__ptr_gc__nat(struct ctx* ctx, struct gc* gc, uint64_t size);
struct opt__ptr__byte try_gc_alloc__opt__ptr__byte__ptr_gc__nat(struct gc* gc, uint64_t size);
struct some__ptr__byte some__some__ptr__byte__ptr__byte(uint8_t* t);
uint8_t* todo__ptr__byte();
struct gc* get_gc__ptr_gc(struct ctx* ctx);
struct gc_ctx* get_gc_ctx__ptr_gc_ctx(struct ctx* ctx);
uint8_t then_void___void__ptr_fut___void__fun_mut1___void__result___void__exception(struct ctx* ctx, struct fut___void* f, struct fun_mut1___void__result___void__exception cb);
struct some__ptr_fut_callback_node___void some__some__ptr_fut_callback_node___void__ptr_fut_callback_node___void(struct fut_callback_node___void* t);
uint8_t call___void__fun_mut1___void__result___void__exception__result___void__exception(struct ctx* ctx, struct fun_mut1___void__result___void__exception f, struct result___void__exception p0);
uint8_t call_with_ctx___void__ptr_ctx__fun_mut1___void__result___void__exception__result___void__exception(struct ctx* c, struct fun_mut1___void__result___void__exception f, struct result___void__exception p0);
struct ok___void ok__ok___void___void(uint8_t t);
struct err__exception err__err__exception__exception(struct exception t);
uint8_t forward_to___void__ptr_fut__int32__ptr_fut__int32(struct ctx* ctx, struct fut__int32* from, struct fut__int32* to);
uint8_t then_void___void__ptr_fut__int32__fun_mut1___void__result__int32__exception(struct ctx* ctx, struct fut__int32* f, struct fun_mut1___void__result__int32__exception cb);
struct some__ptr_fut_callback_node__int32 some__some__ptr_fut_callback_node__int32__ptr_fut_callback_node__int32(struct fut_callback_node__int32* t);
uint8_t call___void__fun_mut1___void__result__int32__exception__result__int32__exception(struct ctx* ctx, struct fun_mut1___void__result__int32__exception f, struct result__int32__exception p0);
uint8_t call_with_ctx___void__ptr_ctx__fun_mut1___void__result__int32__exception__result__int32__exception(struct ctx* c, struct fun_mut1___void__result__int32__exception f, struct result__int32__exception p0);
struct ok__int32 ok__ok__int32__int32(int32_t t);
uint8_t resolve_or_reject___void__ptr_fut__int32__result__int32__exception(struct ctx* ctx, struct fut__int32* f, struct result__int32__exception result);
uint8_t resolve_or_reject_recur___void__opt__ptr_fut_callback_node__int32__result__int32__exception(struct ctx* ctx, struct opt__ptr_fut_callback_node__int32 node, struct result__int32__exception value);
uint8_t drop___void___void(uint8_t t);
uint8_t forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0(struct ctx* ctx, struct forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0___closure* _closure, struct result__int32__exception it);
struct fut__int32* call__ptr_fut__int32__fun_ref1__int32___void___void(struct ctx* ctx, struct fun_ref1__int32___void f, uint8_t p0);
struct vat* get_vat__ptr_vat__nat(struct ctx* ctx, uint64_t vat_id);
struct vat* at__ptr_vat__arr__ptr_vat__nat(struct ctx* ctx, struct arr__ptr_vat a, uint64_t index);
uint8_t assert___void__bool(struct ctx* ctx, uint8_t condition);
uint8_t assert___void__bool__arr__char(struct ctx* ctx, uint8_t condition, struct arr__char message);
uint8_t fail___void__arr__char(struct ctx* ctx, struct arr__char reason);
uint8_t throw___void__exception(struct ctx* ctx, struct exception e);
struct exception_ctx* get_exception_ctx__ptr_exception_ctx(struct ctx* ctx);
uint8_t _op_equal_equal__bool__ptr__jmp_buf_tag__ptr__jmp_buf_tag(struct jmp_buf_tag* a, struct jmp_buf_tag* b);
struct comparison _op_less_equal_greater__comparison__ptr__jmp_buf_tag__ptr__jmp_buf_tag(struct jmp_buf_tag* a, struct jmp_buf_tag* b);
extern void longjmp(struct jmp_buf_tag* env, int32_t val);
int32_t number_to_throw__int32(struct ctx* ctx);
int32_t seven__int32();
int32_t six__int32();
int32_t five__int32();
int32_t four__int32();
int32_t three__int32();
struct vat* noctx_at__ptr_vat__arr__ptr_vat__nat(struct arr__ptr_vat a, uint64_t index);
uint8_t add_task___void__ptr_vat__task(struct ctx* ctx, struct vat* v, struct task t);
struct mut_bag_node__task* new_mut_bag_node__ptr_mut_bag_node__task__task(struct ctx* ctx, struct task value);
uint8_t add___void__ptr_mut_bag__task__ptr_mut_bag_node__task(struct mut_bag__task* bag, struct mut_bag_node__task* node);
struct some__ptr_mut_bag_node__task some__some__ptr_mut_bag_node__task__ptr_mut_bag_node__task(struct mut_bag_node__task* t);
uint8_t broadcast___void__ptr_condition(struct condition* c);
uint8_t catch___void__fun_mut0___void__fun_mut1___void__exception(struct ctx* ctx, struct fun_mut0___void try, struct fun_mut1___void__exception catcher);
uint8_t catch_with_exception_ctx___void__ptr_exception_ctx__fun_mut0___void__fun_mut1___void__exception(struct ctx* ctx, struct exception_ctx* ec, struct fun_mut0___void try, struct fun_mut1___void__exception catcher);
struct bytes64 zero__bytes64();
struct bytes32 zero__bytes32();
struct bytes16 zero__bytes16();
struct bytes128 zero__bytes128();
extern int32_t setjmp(struct jmp_buf_tag* env);
uint8_t call___void__fun_mut0___void(struct ctx* ctx, struct fun_mut0___void f);
uint8_t call_with_ctx___void__ptr_ctx__fun_mut0___void(struct ctx* c, struct fun_mut0___void f);
uint8_t call___void__fun_mut1___void__exception__exception(struct ctx* ctx, struct fun_mut1___void__exception f, struct exception p0);
uint8_t call_with_ctx___void__ptr_ctx__fun_mut1___void__exception__exception(struct ctx* c, struct fun_mut1___void__exception f, struct exception p0);
struct fut__int32* call__ptr_fut__int32__fun_mut1__ptr_fut__int32___void___void(struct ctx* ctx, struct fun_mut1__ptr_fut__int32___void f, uint8_t p0);
struct fut__int32* call_with_ctx__ptr_fut__int32__ptr_ctx__fun_mut1__ptr_fut__int32___void___void(struct ctx* c, struct fun_mut1__ptr_fut__int32___void f, uint8_t p0);
uint8_t call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0(struct ctx* ctx, struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0___closure* _closure);
uint8_t reject___void__ptr_fut__int32__exception(struct ctx* ctx, struct fut__int32* f, struct exception e);
uint8_t call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1(struct ctx* ctx, struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1___closure* _closure, struct exception it);
uint8_t call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0(struct ctx* ctx, struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0___closure* _closure);
uint8_t then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0(struct ctx* ctx, struct then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0___closure* _closure, struct result___void__exception result);
struct fut__int32* call__ptr_fut__int32__fun_ref0__int32(struct ctx* ctx, struct fun_ref0__int32 f);
struct fut__int32* call__ptr_fut__int32__fun_mut0__ptr_fut__int32(struct ctx* ctx, struct fun_mut0__ptr_fut__int32 f);
struct fut__int32* call_with_ctx__ptr_fut__int32__ptr_ctx__fun_mut0__ptr_fut__int32(struct ctx* c, struct fun_mut0__ptr_fut__int32 f);
uint8_t call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0(struct ctx* ctx, struct call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0___closure* _closure);
uint8_t call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1(struct ctx* ctx, struct call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1___closure* _closure, struct exception it);
uint8_t call__ptr_fut__int32__fun_ref0__int32__lambda0(struct ctx* ctx, struct call__ptr_fut__int32__fun_ref0__int32__lambda0___closure* _closure);
struct fut__int32* then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0(struct ctx* ctx, struct then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0___closure* _closure, uint8_t ignore);
struct vat_and_actor_id cur_actor__vat_and_actor_id(struct ctx* ctx);
struct fut___void* resolved__ptr_fut___void___void(struct ctx* ctx, uint8_t value);
struct arr__ptr__char tail__arr__ptr__char__arr__ptr__char(struct ctx* ctx, struct arr__ptr__char a);
uint8_t forbid___void__bool(struct ctx* ctx, uint8_t condition);
uint8_t forbid___void__bool__arr__char(struct ctx* ctx, uint8_t condition, struct arr__char message);
uint8_t empty__q__bool__arr__ptr__char(struct arr__ptr__char a);
struct arr__ptr__char slice_starting_at__arr__ptr__char__arr__ptr__char__nat(struct ctx* ctx, struct arr__ptr__char a, uint64_t begin);
uint8_t _op_less_equal__bool__nat__nat(uint64_t a, uint64_t b);
struct arr__ptr__char slice__arr__ptr__char__arr__ptr__char__nat__nat(struct ctx* ctx, struct arr__ptr__char a, uint64_t begin, uint64_t size);
uint64_t _op_plus__nat__nat__nat(struct ctx* ctx, uint64_t a, uint64_t b);
uint8_t _op_greater_equal__bool__nat__nat(uint64_t a, uint64_t b);
uint64_t _op_minus__nat__nat__nat(struct ctx* ctx, uint64_t a, uint64_t b);
struct arr__arr__char map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char(struct ctx* ctx, struct arr__ptr__char a, struct fun_mut1__arr__char__ptr__char mapper);
struct arr__arr__char make_arr__arr__arr__char__nat__fun_mut1__arr__char__nat(struct ctx* ctx, uint64_t size, struct fun_mut1__arr__char__nat f);
struct arr__arr__char freeze__arr__arr__char__ptr_mut_arr__arr__char(struct mut_arr__arr__char* a);
struct arr__arr__char unsafe_as_arr__arr__arr__char__ptr_mut_arr__arr__char(struct mut_arr__arr__char* a);
struct mut_arr__arr__char* make_mut_arr__ptr_mut_arr__arr__char__nat__fun_mut1__arr__char__nat(struct ctx* ctx, uint64_t size, struct fun_mut1__arr__char__nat f);
struct mut_arr__arr__char* new_uninitialized_mut_arr__ptr_mut_arr__arr__char__nat(struct ctx* ctx, uint64_t size);
struct arr__char* uninitialized_data__ptr__arr__char__nat(struct ctx* ctx, uint64_t size);
uint8_t make_mut_arr_worker___void__ptr_mut_arr__arr__char__nat__fun_mut1__arr__char__nat(struct ctx* ctx, struct mut_arr__arr__char* m, uint64_t i, struct fun_mut1__arr__char__nat f);
uint8_t set_at___void__ptr_mut_arr__arr__char__nat__arr__char(struct ctx* ctx, struct mut_arr__arr__char* a, uint64_t index, struct arr__char value);
uint8_t noctx_set_at___void__ptr_mut_arr__arr__char__nat__arr__char(struct mut_arr__arr__char* a, uint64_t index, struct arr__char value);
struct arr__char call__arr__char__fun_mut1__arr__char__nat__nat(struct ctx* ctx, struct fun_mut1__arr__char__nat f, uint64_t p0);
struct arr__char call_with_ctx__arr__char__ptr_ctx__fun_mut1__arr__char__nat__nat(struct ctx* c, struct fun_mut1__arr__char__nat f, uint64_t p0);
uint64_t incr__nat__nat(struct ctx* ctx, uint64_t n);
struct arr__char call__arr__char__fun_mut1__arr__char__ptr__char__ptr__char(struct ctx* ctx, struct fun_mut1__arr__char__ptr__char f, char* p0);
struct arr__char call_with_ctx__arr__char__ptr_ctx__fun_mut1__arr__char__ptr__char__ptr__char(struct ctx* c, struct fun_mut1__arr__char__ptr__char f, char* p0);
char* at__ptr__char__arr__ptr__char__nat(struct ctx* ctx, struct arr__ptr__char a, uint64_t index);
char* noctx_at__ptr__char__arr__ptr__char__nat(struct arr__ptr__char a, uint64_t index);
struct arr__char map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0(struct ctx* ctx, struct map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0___closure* _closure, uint64_t i);
struct arr__char to_str__arr__char__ptr__char(char* a);
struct arr__char arr_from_begin_end__arr__char__ptr__char__ptr__char(char* begin, char* end);
uint64_t _op_minus__nat__ptr__char__ptr__char(char* a, char* b);
char* find_cstr_end__ptr__char__ptr__char(char* a);
char* find_char_in_cstr__ptr__char__ptr__char__char(char* a, char c);
uint8_t _op_equal_equal__bool__char__char(char a, char b);
struct comparison _op_less_equal_greater__comparison__char__char(char a, char b);
char literal__char__arr__char(struct arr__char a);
char noctx_at__char__arr__char__nat(struct arr__char a, uint64_t index);
char* todo__ptr__char();
char* incr__ptr__char__ptr__char(char* p);
struct arr__char add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0__lambda0(struct ctx* ctx, uint8_t* _closure, char* it);
struct fut__int32* add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0(struct ctx* ctx, struct add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0___closure* _closure);
struct fut__int32* rt_main__int32__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr__ptr__char all_args, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char main_ptr);
struct fut__int32* call_with_ctx__ptr_fut__int32__ptr_ctx__fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(struct ctx* c, struct fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char f, struct arr__ptr__char p0, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char p1);
uint8_t run_threads___void__nat__ptr_global_ctx__fun_ptr2___void__nat__ptr_global_ctx(uint64_t n_threads, struct global_ctx* arg, fun_ptr2___void__nat__ptr_global_ctx fun);
struct thread_args__ptr_global_ctx* unmanaged_alloc_elements__ptr__thread_args__ptr_global_ctx__nat(uint64_t size_elements);
uint8_t run_threads_recur___void__nat__nat__ptr__nat__ptr__thread_args__ptr_global_ctx__ptr_global_ctx__fun_ptr2___void__nat__ptr_global_ctx(uint64_t i, uint64_t n_threads, uint64_t* threads, struct thread_args__ptr_global_ctx* thread_args, struct global_ctx* arg, fun_ptr2___void__nat__ptr_global_ctx fun);
uint8_t* thread_fun__ptr__byte__ptr__byte(uint8_t* args_ptr);
uint8_t* run_threads_recur___void__nat__nat__ptr__nat__ptr__thread_args__ptr_global_ctx__ptr_global_ctx__fun_ptr2___void__nat__ptr_global_ctx__lambda0(uint8_t* args_ptr);
extern int32_t pthread_create(struct cell__nat* thread, uint8_t* attr, fun_ptr1__ptr__byte__ptr__byte start_routine, uint8_t* arg);
struct cell__nat* as_cell__ptr_cell__nat__ptr__nat(uint64_t* p);
int32_t eagain__int32();
int32_t ten__int32();
int32_t nine__int32();
int32_t eight__int32();
uint8_t join_threads_recur___void__nat__nat__ptr__nat(uint64_t i, uint64_t n_threads, uint64_t* threads);
uint8_t join_one_thread___void__nat(uint64_t tid);
extern int32_t pthread_join(uint64_t thread, struct cell__ptr__byte* thread_return);
int32_t einval__int32();
int32_t esrch__int32();
uint8_t* get__ptr__byte__ptr_cell__ptr__byte(struct cell__ptr__byte* c);
uint8_t unmanaged_free___void__ptr__nat(uint64_t* p);
extern void free(uint8_t* p);
uint8_t unmanaged_free___void__ptr__thread_args__ptr_global_ctx(struct thread_args__ptr_global_ctx* p);
uint8_t thread_function___void__nat__ptr_global_ctx(uint64_t thread_id, struct global_ctx* gctx);
uint8_t thread_function_recur___void__nat__ptr_global_ctx__ptr_thread_local_stuff(uint64_t thread_id, struct global_ctx* gctx, struct thread_local_stuff* tls);
uint64_t noctx_decr__nat__nat(uint64_t n);
uint8_t assert_vats_are_shut_down___void__nat__arr__ptr_vat(uint64_t i, struct arr__ptr_vat vats);
uint8_t empty__q__bool__ptr_mut_bag__task(struct mut_bag__task* m);
uint8_t empty__q__bool__opt__ptr_mut_bag_node__task(struct opt__ptr_mut_bag_node__task a);
uint8_t _op_greater__bool__nat__nat(uint64_t a, uint64_t b);
uint64_t get_last_checked__nat__ptr_condition(struct condition* c);
struct result__chosen_task__no_chosen_task choose_task__result__chosen_task__no_chosen_task__ptr_global_ctx(struct global_ctx* gctx);
struct opt__chosen_task choose_task_recur__opt__chosen_task__arr__ptr_vat__nat(struct arr__ptr_vat vats, uint64_t i);
struct opt__opt__task choose_task_in_vat__opt__opt__task__ptr_vat(struct vat* vat);
struct some__opt__task some__some__opt__task__opt__task(struct opt__task t);
struct opt__task find_and_remove_first_doable_task__opt__task__ptr_vat(struct vat* vat);
struct opt__task_and_nodes find_and_remove_first_doable_task_recur__opt__task_and_nodes__ptr_vat__opt__ptr_mut_bag_node__task(struct vat* vat, struct opt__ptr_mut_bag_node__task opt_node);
uint8_t contains__q__bool__ptr_mut_arr__nat__nat(struct mut_arr__nat* a, uint64_t value);
uint8_t contains_recur__q__bool__arr__nat__nat__nat(struct arr__nat a, uint64_t value, uint64_t i);
uint64_t noctx_at__nat__arr__nat__nat(struct arr__nat a, uint64_t index);
struct arr__nat temp_as_arr__arr__nat__ptr_mut_arr__nat(struct mut_arr__nat* a);
uint8_t push_capacity_must_be_sufficient___void__ptr_mut_arr__nat__nat(struct mut_arr__nat* a, uint64_t value);
uint8_t noctx_set_at___void__ptr_mut_arr__nat__nat__nat(struct mut_arr__nat* a, uint64_t index, uint64_t value);
struct some__task_and_nodes some__some__task_and_nodes__task_and_nodes(struct task_and_nodes t);
struct some__task some__some__task__task(struct task t);
uint8_t empty__q__bool__opt__opt__task(struct opt__opt__task a);
struct some__chosen_task some__some__chosen_task__chosen_task(struct chosen_task t);
struct err__no_chosen_task err__err__no_chosen_task__no_chosen_task(struct no_chosen_task t);
struct ok__chosen_task ok__ok__chosen_task__chosen_task(struct chosen_task t);
uint8_t do_task___void__ptr_global_ctx__ptr_thread_local_stuff__chosen_task(struct global_ctx* gctx, struct thread_local_stuff* tls, struct chosen_task chosen_task);
uint8_t noctx_must_remove_unordered___void__ptr_mut_arr__nat__nat(struct mut_arr__nat* a, uint64_t value);
uint8_t noctx_must_remove_unordered_recur___void__ptr_mut_arr__nat__nat__nat(struct mut_arr__nat* a, uint64_t index, uint64_t value);
uint64_t noctx_at__nat__ptr_mut_arr__nat__nat(struct mut_arr__nat* a, uint64_t index);
uint8_t drop___void__nat(uint64_t t);
uint64_t noctx_remove_unordered_at_index__nat__ptr_mut_arr__nat__nat(struct mut_arr__nat* a, uint64_t index);
uint64_t noctx_last__nat__ptr_mut_arr__nat(struct mut_arr__nat* a);
uint8_t empty__q__bool__ptr_mut_arr__nat(struct mut_arr__nat* a);
uint8_t return_ctx___void__ptr_ctx(struct ctx* c);
uint8_t return_gc_ctx___void__ptr_gc_ctx(struct gc_ctx* gc_ctx);
struct some__ptr_gc_ctx some__some__ptr_gc_ctx__ptr_gc_ctx(struct gc_ctx* t);
uint8_t wait_on___void__ptr_condition__nat(struct condition* c, uint64_t last_checked);
uint8_t rt_main__int32__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda1(uint64_t thread_id, struct global_ctx* gctx);
struct result__int32__exception must_be_resolved__result__int32__exception__ptr_fut__int32(struct fut__int32* f);
struct result__int32__exception hard_unreachable__result__int32__exception();
struct fut__int32* main__ptr_fut__int32__arr__arr__char(struct ctx* ctx, struct arr__arr__char args);
struct opt__test_options parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char(struct ctx* ctx, struct arr__arr__char args, struct arr__arr__char t_names, struct fun1__test_options__arr__opt__arr__arr__char make_t);
struct parsed_cmd_line_args* parse_cmd_line_args_dynamic__ptr_parsed_cmd_line_args__arr__arr__char(struct ctx* ctx, struct arr__arr__char args);
struct opt__nat find_index__opt__nat__arr__arr__char__fun_mut1__bool__arr__char(struct ctx* ctx, struct arr__arr__char a, struct fun_mut1__bool__arr__char pred);
struct opt__nat find_index_recur__opt__nat__arr__arr__char__nat__fun_mut1__bool__arr__char(struct ctx* ctx, struct arr__arr__char a, uint64_t index, struct fun_mut1__bool__arr__char pred);
uint8_t call__bool__fun_mut1__bool__arr__char__arr__char(struct ctx* ctx, struct fun_mut1__bool__arr__char f, struct arr__char p0);
uint8_t call_with_ctx__bool__ptr_ctx__fun_mut1__bool__arr__char__arr__char(struct ctx* c, struct fun_mut1__bool__arr__char f, struct arr__char p0);
struct arr__char at__arr__char__arr__arr__char__nat(struct ctx* ctx, struct arr__arr__char a, uint64_t index);
struct arr__char noctx_at__arr__char__arr__arr__char__nat(struct arr__arr__char a, uint64_t index);
struct some__nat some__some__nat__nat(uint64_t t);
uint8_t starts_with__q__bool__arr__char__arr__char(struct ctx* ctx, struct arr__char a, struct arr__char start);
uint8_t arr_eq__q__bool__arr__char__arr__char(struct ctx* ctx, struct arr__char a, struct arr__char b);
char first__char__arr__char(struct ctx* ctx, struct arr__char a);
char at__char__arr__char__nat(struct ctx* ctx, struct arr__char a, uint64_t index);
struct arr__char tail__arr__char__arr__char(struct ctx* ctx, struct arr__char a);
struct arr__char slice_starting_at__arr__char__arr__char__nat(struct ctx* ctx, struct arr__char a, uint64_t begin);
struct arr__char slice__arr__char__arr__char__nat__nat(struct ctx* ctx, struct arr__char a, uint64_t begin, uint64_t size);
uint8_t parse_cmd_line_args_dynamic__ptr_parsed_cmd_line_args__arr__arr__char__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr__char it);
struct dict__arr__char__arr__arr__char* empty_dict__ptr_dict__arr__char__arr__arr__char(struct ctx* ctx);
struct arr__arr__char empty_arr__arr__arr__char();
struct arr__arr__arr__char empty_arr__arr__arr__arr__char();
struct arr__arr__char slice_up_to__arr__arr__char__arr__arr__char__nat(struct ctx* ctx, struct arr__arr__char a, uint64_t size);
struct arr__arr__char slice__arr__arr__char__arr__arr__char__nat__nat(struct ctx* ctx, struct arr__arr__char a, uint64_t begin, uint64_t size);
struct arr__arr__char slice_starting_at__arr__arr__char__arr__arr__char__nat(struct ctx* ctx, struct arr__arr__char a, uint64_t begin);
uint8_t _op_equal_equal__bool__arr__char__arr__char(struct arr__char a, struct arr__char b);
struct comparison _op_less_equal_greater__comparison__arr__char__arr__char(struct arr__char a, struct arr__char b);
uint8_t parse_cmd_line_args_dynamic__ptr_parsed_cmd_line_args__arr__arr__char__lambda1(struct ctx* ctx, uint8_t* _closure, struct arr__char it);
struct dict__arr__char__arr__arr__char* parse_named_args__ptr_dict__arr__char__arr__arr__char__arr__arr__char(struct ctx* ctx, struct arr__arr__char args);
struct mut_dict__arr__char__arr__arr__char new_mut_dict__mut_dict__arr__char__arr__arr__char(struct ctx* ctx);
struct mut_arr__arr__char* new_mut_arr__ptr_mut_arr__arr__char(struct ctx* ctx);
struct mut_arr__arr__arr__char* new_mut_arr__ptr_mut_arr__arr__arr__char(struct ctx* ctx);
uint8_t parse_named_args_recur___void__arr__arr__char__mut_dict__arr__char__arr__arr__char(struct ctx* ctx, struct arr__arr__char args, struct mut_dict__arr__char__arr__arr__char builder);
struct arr__char remove_start__arr__char__arr__char__arr__char(struct ctx* ctx, struct arr__char a, struct arr__char start);
struct arr__char force__arr__char__opt__arr__char(struct ctx* ctx, struct opt__arr__char a);
struct arr__char fail__arr__char__arr__char(struct ctx* ctx, struct arr__char reason);
struct arr__char throw__arr__char__exception(struct ctx* ctx, struct exception e);
struct arr__char todo__arr__char();
struct opt__arr__char try_remove_start__opt__arr__char__arr__char__arr__char(struct ctx* ctx, struct arr__char a, struct arr__char start);
struct some__arr__char some__some__arr__char__arr__char(struct arr__char t);
struct arr__char first__arr__char__arr__arr__char(struct ctx* ctx, struct arr__arr__char a);
uint8_t empty__q__bool__arr__arr__char(struct arr__arr__char a);
struct arr__arr__char tail__arr__arr__char__arr__arr__char(struct ctx* ctx, struct arr__arr__char a);
uint8_t parse_named_args_recur___void__arr__arr__char__mut_dict__arr__char__arr__arr__char__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr__char it);
uint8_t add___void__mut_dict__arr__char__arr__arr__char__arr__char__arr__arr__char(struct ctx* ctx, struct mut_dict__arr__char__arr__arr__char m, struct arr__char key, struct arr__arr__char value);
uint8_t has__q__bool__mut_dict__arr__char__arr__arr__char__arr__char(struct ctx* ctx, struct mut_dict__arr__char__arr__arr__char d, struct arr__char key);
uint8_t has__q__bool__ptr_dict__arr__char__arr__arr__char__arr__char(struct ctx* ctx, struct dict__arr__char__arr__arr__char* d, struct arr__char key);
uint8_t has__q__bool__opt__arr__arr__char(struct opt__arr__arr__char a);
uint8_t empty__q__bool__opt__arr__arr__char(struct opt__arr__arr__char a);
struct opt__arr__arr__char get__opt__arr__arr__char__ptr_dict__arr__char__arr__arr__char__arr__char(struct ctx* ctx, struct dict__arr__char__arr__arr__char* d, struct arr__char key);
struct opt__arr__arr__char get_recursive__opt__arr__arr__char__arr__arr__char__arr__arr__arr__char__nat__arr__char(struct ctx* ctx, struct arr__arr__char keys, struct arr__arr__arr__char values, uint64_t idx, struct arr__char key);
struct some__arr__arr__char some__some__arr__arr__char__arr__arr__char(struct arr__arr__char t);
struct arr__arr__char at__arr__arr__char__arr__arr__arr__char__nat(struct ctx* ctx, struct arr__arr__arr__char a, uint64_t index);
struct arr__arr__char noctx_at__arr__arr__char__arr__arr__arr__char__nat(struct arr__arr__arr__char a, uint64_t index);
struct dict__arr__char__arr__arr__char* unsafe_as_dict__ptr_dict__arr__char__arr__arr__char__mut_dict__arr__char__arr__arr__char(struct ctx* ctx, struct mut_dict__arr__char__arr__arr__char m);
struct arr__arr__arr__char unsafe_as_arr__arr__arr__arr__char__ptr_mut_arr__arr__arr__char(struct mut_arr__arr__arr__char* a);
uint8_t push___void__ptr_mut_arr__arr__char__arr__char(struct ctx* ctx, struct mut_arr__arr__char* a, struct arr__char value);
uint8_t increase_capacity_to___void__ptr_mut_arr__arr__char__nat(struct ctx* ctx, struct mut_arr__arr__char* a, uint64_t new_capacity);
uint8_t copy_data_from___void__ptr__arr__char__ptr__arr__char__nat(struct ctx* ctx, struct arr__char* to, struct arr__char* from, uint64_t len);
uint8_t copy_data_from_small___void__ptr__arr__char__ptr__arr__char__nat(struct ctx* ctx, struct arr__char* to, struct arr__char* from, uint64_t len);
struct arr__char* incr__ptr__arr__char__ptr__arr__char(struct arr__char* p);
uint64_t decr__nat__nat(struct ctx* ctx, uint64_t a);
uint64_t wrap_decr__nat__nat(uint64_t a);
uint64_t _op_div__nat__nat__nat(struct ctx* ctx, uint64_t a, uint64_t b);
uint64_t _op_times__nat__nat__nat(struct ctx* ctx, uint64_t a, uint64_t b);
uint8_t ensure_capacity___void__ptr_mut_arr__arr__char__nat(struct ctx* ctx, struct mut_arr__arr__char* a, uint64_t capacity);
uint64_t round_up_to_power_of_two__nat__nat(struct ctx* ctx, uint64_t n);
uint64_t round_up_to_power_of_two_recur__nat__nat__nat(struct ctx* ctx, uint64_t acc, uint64_t n);
uint8_t push___void__ptr_mut_arr__arr__arr__char__arr__arr__char(struct ctx* ctx, struct mut_arr__arr__arr__char* a, struct arr__arr__char value);
uint8_t increase_capacity_to___void__ptr_mut_arr__arr__arr__char__nat(struct ctx* ctx, struct mut_arr__arr__arr__char* a, uint64_t new_capacity);
struct arr__arr__char* uninitialized_data__ptr__arr__arr__char__nat(struct ctx* ctx, uint64_t size);
uint8_t copy_data_from___void__ptr__arr__arr__char__ptr__arr__arr__char__nat(struct ctx* ctx, struct arr__arr__char* to, struct arr__arr__char* from, uint64_t len);
uint8_t copy_data_from_small___void__ptr__arr__arr__char__ptr__arr__arr__char__nat(struct ctx* ctx, struct arr__arr__char* to, struct arr__arr__char* from, uint64_t len);
struct arr__arr__char* incr__ptr__arr__arr__char__ptr__arr__arr__char(struct arr__arr__char* p);
uint8_t ensure_capacity___void__ptr_mut_arr__arr__arr__char__nat(struct ctx* ctx, struct mut_arr__arr__arr__char* a, uint64_t capacity);
struct dict__arr__char__arr__arr__char* freeze__ptr_dict__arr__char__arr__arr__char__mut_dict__arr__char__arr__arr__char(struct ctx* ctx, struct mut_dict__arr__char__arr__arr__char m);
struct arr__arr__arr__char freeze__arr__arr__arr__char__ptr_mut_arr__arr__arr__char(struct mut_arr__arr__arr__char* a);
struct arr__arr__char slice_after__arr__arr__char__arr__arr__char__nat(struct ctx* ctx, struct arr__arr__char a, uint64_t before_begin);
struct mut_arr__opt__arr__arr__char* fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char(struct ctx* ctx, uint64_t size, struct opt__arr__arr__char value);
struct mut_arr__opt__arr__arr__char* make_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__fun_mut1__opt__arr__arr__char__nat(struct ctx* ctx, uint64_t size, struct fun_mut1__opt__arr__arr__char__nat f);
struct mut_arr__opt__arr__arr__char* new_uninitialized_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat(struct ctx* ctx, uint64_t size);
struct opt__arr__arr__char* uninitialized_data__ptr__opt__arr__arr__char__nat(struct ctx* ctx, uint64_t size);
uint8_t make_mut_arr_worker___void__ptr_mut_arr__opt__arr__arr__char__nat__fun_mut1__opt__arr__arr__char__nat(struct ctx* ctx, struct mut_arr__opt__arr__arr__char* m, uint64_t i, struct fun_mut1__opt__arr__arr__char__nat f);
uint8_t set_at___void__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char(struct ctx* ctx, struct mut_arr__opt__arr__arr__char* a, uint64_t index, struct opt__arr__arr__char value);
uint8_t noctx_set_at___void__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char(struct mut_arr__opt__arr__arr__char* a, uint64_t index, struct opt__arr__arr__char value);
struct opt__arr__arr__char call__opt__arr__arr__char__fun_mut1__opt__arr__arr__char__nat__nat(struct ctx* ctx, struct fun_mut1__opt__arr__arr__char__nat f, uint64_t p0);
struct opt__arr__arr__char call_with_ctx__opt__arr__arr__char__ptr_ctx__fun_mut1__opt__arr__arr__char__nat__nat(struct ctx* c, struct fun_mut1__opt__arr__arr__char__nat f, uint64_t p0);
struct opt__arr__arr__char fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0(struct ctx* ctx, struct fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0___closure* _closure, uint64_t ignore);
struct cell__bool* new_cell__ptr_cell__bool__bool(struct ctx* ctx, uint8_t value);
uint8_t each___void__ptr_dict__arr__char__arr__arr__char__fun_mut2___void__arr__char__arr__arr__char(struct ctx* ctx, struct dict__arr__char__arr__arr__char* d, struct fun_mut2___void__arr__char__arr__arr__char f);
uint8_t empty__q__bool__ptr_dict__arr__char__arr__arr__char(struct ctx* ctx, struct dict__arr__char__arr__arr__char* d);
uint8_t call___void__fun_mut2___void__arr__char__arr__arr__char__arr__char__arr__arr__char(struct ctx* ctx, struct fun_mut2___void__arr__char__arr__arr__char f, struct arr__char p0, struct arr__arr__char p1);
uint8_t call_with_ctx___void__ptr_ctx__fun_mut2___void__arr__char__arr__arr__char__arr__char__arr__arr__char(struct ctx* c, struct fun_mut2___void__arr__char__arr__arr__char f, struct arr__char p0, struct arr__arr__char p1);
struct arr__arr__char first__arr__arr__char__arr__arr__arr__char(struct ctx* ctx, struct arr__arr__arr__char a);
uint8_t empty__q__bool__arr__arr__arr__char(struct arr__arr__arr__char a);
struct arr__arr__arr__char tail__arr__arr__arr__char__arr__arr__arr__char(struct ctx* ctx, struct arr__arr__arr__char a);
struct arr__arr__arr__char slice_starting_at__arr__arr__arr__char__arr__arr__arr__char__nat(struct ctx* ctx, struct arr__arr__arr__char a, uint64_t begin);
struct arr__arr__arr__char slice__arr__arr__arr__char__arr__arr__arr__char__nat__nat(struct ctx* ctx, struct arr__arr__arr__char a, uint64_t begin, uint64_t size);
struct opt__nat index_of__opt__nat__arr__arr__char__arr__char(struct ctx* ctx, struct arr__arr__char a, struct arr__char value);
uint8_t index_of__opt__nat__arr__arr__char__arr__char__lambda0(struct ctx* ctx, struct index_of__opt__nat__arr__arr__char__arr__char__lambda0___closure* _closure, struct arr__char it);
uint8_t set___void__ptr_cell__bool__bool(struct cell__bool* c, uint8_t v);
struct arr__char _op_plus__arr__char__arr__char__arr__char(struct ctx* ctx, struct arr__char a, struct arr__char b);
struct arr__char make_arr__arr__char__nat__fun_mut1__char__nat(struct ctx* ctx, uint64_t size, struct fun_mut1__char__nat f);
struct arr__char freeze__arr__char__ptr_mut_arr__char(struct mut_arr__char* a);
struct arr__char unsafe_as_arr__arr__char__ptr_mut_arr__char(struct mut_arr__char* a);
struct mut_arr__char* make_mut_arr__ptr_mut_arr__char__nat__fun_mut1__char__nat(struct ctx* ctx, uint64_t size, struct fun_mut1__char__nat f);
struct mut_arr__char* new_uninitialized_mut_arr__ptr_mut_arr__char__nat(struct ctx* ctx, uint64_t size);
char* uninitialized_data__ptr__char__nat(struct ctx* ctx, uint64_t size);
uint8_t make_mut_arr_worker___void__ptr_mut_arr__char__nat__fun_mut1__char__nat(struct ctx* ctx, struct mut_arr__char* m, uint64_t i, struct fun_mut1__char__nat f);
uint8_t set_at___void__ptr_mut_arr__char__nat__char(struct ctx* ctx, struct mut_arr__char* a, uint64_t index, char value);
uint8_t noctx_set_at___void__ptr_mut_arr__char__nat__char(struct mut_arr__char* a, uint64_t index, char value);
char call__char__fun_mut1__char__nat__nat(struct ctx* ctx, struct fun_mut1__char__nat f, uint64_t p0);
char call_with_ctx__char__ptr_ctx__fun_mut1__char__nat__nat(struct ctx* c, struct fun_mut1__char__nat f, uint64_t p0);
char _op_plus__arr__char__arr__char__arr__char__lambda0(struct ctx* ctx, struct _op_plus__arr__char__arr__char__arr__char__lambda0___closure* _closure, uint64_t i);
struct opt__arr__arr__char at__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char__nat(struct ctx* ctx, struct mut_arr__opt__arr__arr__char* a, uint64_t index);
struct opt__arr__arr__char noctx_at__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char__nat(struct mut_arr__opt__arr__arr__char* a, uint64_t index);
uint8_t parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char__lambda0(struct ctx* ctx, struct parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char__lambda0___closure* _closure, struct arr__char key, struct arr__arr__char value);
uint8_t get__bool__ptr_cell__bool(struct cell__bool* c);
struct some__test_options some__some__test_options__test_options(struct test_options t);
struct test_options call__test_options__fun1__test_options__arr__opt__arr__arr__char__arr__opt__arr__arr__char(struct ctx* ctx, struct fun1__test_options__arr__opt__arr__arr__char f, struct arr__opt__arr__arr__char p0);
struct test_options call_with_ctx__test_options__ptr_ctx__fun1__test_options__arr__opt__arr__arr__char__arr__opt__arr__arr__char(struct ctx* c, struct fun1__test_options__arr__opt__arr__arr__char f, struct arr__opt__arr__arr__char p0);
struct arr__opt__arr__arr__char freeze__arr__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char(struct mut_arr__opt__arr__arr__char* a);
struct arr__opt__arr__arr__char unsafe_as_arr__arr__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char(struct mut_arr__opt__arr__arr__char* a);
struct opt__arr__arr__char at__opt__arr__arr__char__arr__opt__arr__arr__char__nat(struct ctx* ctx, struct arr__opt__arr__arr__char a, uint64_t index);
struct opt__arr__arr__char noctx_at__opt__arr__arr__char__arr__opt__arr__arr__char__nat(struct arr__opt__arr__arr__char a, uint64_t index);
uint64_t literal__nat__arr__char(struct ctx* ctx, struct arr__char s);
struct arr__char rtail__arr__char__arr__char(struct ctx* ctx, struct arr__char a);
uint64_t char_to_nat__nat__char(char c);
uint64_t todo__nat();
char last__char__arr__char(struct ctx* ctx, struct arr__char a);
struct test_options main__ptr_fut__int32__arr__arr__char__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr__opt__arr__arr__char values);
struct fut__int32* resolved__ptr_fut__int32__int32(struct ctx* ctx, int32_t value);
uint8_t print_help___void(struct ctx* ctx);
uint8_t print_sync___void__arr__char(struct arr__char s);
uint8_t print_sync_no_newline___void__arr__char(struct arr__char s);
int32_t stdout_fd__int32();
int32_t literal__int32__arr__char(struct ctx* ctx, struct arr__char s);
int64_t literal___int__arr__char(struct ctx* ctx, struct arr__char s);
int64_t neg___int__nat(struct ctx* ctx, uint64_t n);
int64_t neg___int___int(struct ctx* ctx, int64_t i);
int64_t _op_times___int___int___int(struct ctx* ctx, int64_t a, int64_t b);
uint8_t _op_greater__bool___int___int(int64_t a, int64_t b);
uint8_t _op_less_equal__bool___int___int(int64_t a, int64_t b);
uint8_t _op_less__bool___int___int(int64_t a, int64_t b);
int64_t neg_million___int();
int64_t million___int();
int64_t thousand___int();
int64_t hundred___int();
int64_t ten___int();
int64_t wrap_incr___int___int(int64_t a);
int64_t nine___int();
int64_t eight___int();
int64_t seven___int();
int64_t six___int();
int64_t five___int();
int64_t four___int();
int64_t three___int();
int64_t two___int();
int64_t neg_one___int();
int64_t to_int___int__nat(struct ctx* ctx, uint64_t n);
int32_t do_test__int32__test_options(struct ctx* ctx, struct test_options options);
struct arr__char parent_path__arr__char__arr__char(struct ctx* ctx, struct arr__char a);
struct opt__nat r_index_of__opt__nat__arr__char__char(struct ctx* ctx, struct arr__char a, char value);
struct opt__nat find_rindex__opt__nat__arr__char__fun_mut1__bool__char(struct ctx* ctx, struct arr__char a, struct fun_mut1__bool__char pred);
struct opt__nat find_rindex_recur__opt__nat__arr__char__nat__fun_mut1__bool__char(struct ctx* ctx, struct arr__char a, uint64_t index, struct fun_mut1__bool__char pred);
uint8_t call__bool__fun_mut1__bool__char__char(struct ctx* ctx, struct fun_mut1__bool__char f, char p0);
uint8_t call_with_ctx__bool__ptr_ctx__fun_mut1__bool__char__char(struct ctx* c, struct fun_mut1__bool__char f, char p0);
uint8_t r_index_of__opt__nat__arr__char__char__lambda0(struct ctx* ctx, struct r_index_of__opt__nat__arr__char__char__lambda0___closure* _closure, char it);
struct arr__char slice_up_to__arr__char__arr__char__nat(struct ctx* ctx, struct arr__char a, uint64_t size);
struct arr__char current_executable_path__arr__char(struct ctx* ctx);
struct arr__char read_link__arr__char__arr__char(struct ctx* ctx, struct arr__char path);
extern int64_t readlink(char* path, char* buf, uint64_t len);
char* to_c_str__ptr__char__arr__char(struct ctx* ctx, struct arr__char a);
uint8_t check_errno_if_neg_one___void___int(struct ctx* ctx, int64_t e);
uint8_t check_posix_error___void__int32(struct ctx* ctx, int32_t e);
uint8_t hard_unreachable___void();
uint64_t to_nat__nat___int(struct ctx* ctx, int64_t i);
uint8_t negative__q__bool___int(struct ctx* ctx, int64_t i);
struct arr__char child_path__arr__char__arr__char__arr__char(struct ctx* ctx, struct arr__char a, struct arr__char child_name);
struct dict__arr__char__arr__char* get_environ__ptr_dict__arr__char__arr__char(struct ctx* ctx);
struct mut_dict__arr__char__arr__char new_mut_dict__mut_dict__arr__char__arr__char(struct ctx* ctx);
uint8_t get_environ_recur___void__ptr__ptr__char__mut_dict__arr__char__arr__char(struct ctx* ctx, char** env, struct mut_dict__arr__char__arr__char res);
uint8_t null__q__bool__ptr__char(char* a);
uint8_t _op_equal_equal__bool__ptr__char__ptr__char(char* a, char* b);
struct comparison _op_less_equal_greater__comparison__ptr__char__ptr__char(char* a, char* b);
uint8_t add___void__mut_dict__arr__char__arr__char__ptr_key_value_pair__arr__char__arr__char(struct ctx* ctx, struct mut_dict__arr__char__arr__char m, struct key_value_pair__arr__char__arr__char* pair);
uint8_t add___void__mut_dict__arr__char__arr__char__arr__char__arr__char(struct ctx* ctx, struct mut_dict__arr__char__arr__char m, struct arr__char key, struct arr__char value);
uint8_t has__q__bool__mut_dict__arr__char__arr__char__arr__char(struct ctx* ctx, struct mut_dict__arr__char__arr__char d, struct arr__char key);
uint8_t has__q__bool__ptr_dict__arr__char__arr__char__arr__char(struct ctx* ctx, struct dict__arr__char__arr__char* d, struct arr__char key);
uint8_t has__q__bool__opt__arr__char(struct opt__arr__char a);
uint8_t empty__q__bool__opt__arr__char(struct opt__arr__char a);
struct opt__arr__char get__opt__arr__char__ptr_dict__arr__char__arr__char__arr__char(struct ctx* ctx, struct dict__arr__char__arr__char* d, struct arr__char key);
struct opt__arr__char get_recursive__opt__arr__char__arr__arr__char__arr__arr__char__nat__arr__char(struct ctx* ctx, struct arr__arr__char keys, struct arr__arr__char values, uint64_t idx, struct arr__char key);
struct dict__arr__char__arr__char* unsafe_as_dict__ptr_dict__arr__char__arr__char__mut_dict__arr__char__arr__char(struct ctx* ctx, struct mut_dict__arr__char__arr__char m);
struct key_value_pair__arr__char__arr__char* parse_environ_entry__ptr_key_value_pair__arr__char__arr__char__ptr__char(struct ctx* ctx, char* entry);
char** incr__ptr__ptr__char__ptr__ptr__char(char** p);
extern char** environ;
struct dict__arr__char__arr__char* freeze__ptr_dict__arr__char__arr__char__mut_dict__arr__char__arr__char(struct ctx* ctx, struct mut_dict__arr__char__arr__char m);
struct result__arr__char__arr__ptr_failure run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options(struct ctx* ctx, struct arr__char path, struct arr__char path_to_noze, struct dict__arr__char__arr__char* env, struct test_options options);
struct arr__arr__char list_compile_error_tests__arr__arr__char__arr__char(struct ctx* ctx, struct arr__char path);
uint8_t list_compile_error_tests__arr__arr__char__arr__char__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr__char s);
uint8_t each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char(struct ctx* ctx, struct arr__char path, struct fun_mut1__bool__arr__char filter, struct fun_mut1___void__arr__char f);
uint8_t is_dir__q__bool__arr__char(struct ctx* ctx, struct arr__char path);
uint8_t is_dir__q__bool__ptr__char(struct ctx* ctx, char* path);
struct opt__ptr_stat_t get_stat__opt__ptr_stat_t__ptr__char(struct ctx* ctx, char* path);
struct stat_t* empty_stat__ptr_stat_t(struct ctx* ctx);
extern int32_t stat(char* path, struct stat_t* buf);
struct some__ptr_stat_t some__some__ptr_stat_t__ptr_stat_t(struct stat_t* t);
int32_t neg_one__int32();
int32_t enoent__int32();
struct opt__ptr_stat_t todo__opt__ptr_stat_t();
uint8_t todo__bool();
uint8_t _op_equal_equal__bool__nat32__nat32(uint32_t a, uint32_t b);
struct comparison _op_less_equal_greater__comparison__nat32__nat32(uint32_t a, uint32_t b);
uint32_t s_ifmt__nat32(struct ctx* ctx);
uint32_t two_pow__nat32__nat32(uint32_t pow);
uint8_t zero__q__bool__nat32(uint32_t n);
uint32_t wrap_decr__nat32__nat32(uint32_t a);
uint32_t two__nat32();
uint32_t wrap_incr__nat32__nat32(uint32_t a);
uint32_t twelve__nat32();
uint32_t eight__nat32();
uint32_t seven__nat32();
uint32_t six__nat32();
uint32_t five__nat32();
uint32_t four__nat32();
uint32_t three__nat32();
uint32_t fifteen__nat32();
uint32_t fourteen__nat32();
uint32_t s_ifdir__nat32(struct ctx* ctx);
uint8_t each___void__arr__arr__char__fun_mut1___void__arr__char(struct ctx* ctx, struct arr__arr__char a, struct fun_mut1___void__arr__char f);
uint8_t call___void__fun_mut1___void__arr__char__arr__char(struct ctx* ctx, struct fun_mut1___void__arr__char f, struct arr__char p0);
uint8_t call_with_ctx___void__ptr_ctx__fun_mut1___void__arr__char__arr__char(struct ctx* c, struct fun_mut1___void__arr__char f, struct arr__char p0);
struct arr__arr__char read_dir__arr__arr__char__arr__char(struct ctx* ctx, struct arr__char path);
struct arr__arr__char read_dir__arr__arr__char__ptr__char(struct ctx* ctx, char* path);
extern uint8_t* opendir(char* name);
uint8_t read_dir_recur___void__ptr__byte__ptr_mut_arr__arr__char(struct ctx* ctx, uint8_t* dirp, struct mut_arr__arr__char* res);
struct bytes256 zero__bytes256();
struct cell__ptr_dirent* new_cell__ptr_cell__ptr_dirent__ptr_dirent(struct ctx* ctx, struct dirent* value);
extern int32_t readdir_r(uint8_t* dirp, struct dirent* entry, struct cell__ptr_dirent* result);
struct dirent* get__ptr_dirent__ptr_cell__ptr_dirent(struct cell__ptr_dirent* c);
uint8_t ptr_eq__bool__ptr_dirent__ptr_dirent(struct dirent* a, struct dirent* b);
struct arr__char get_dirent_name__arr__char__ptr_dirent(struct dirent* d);
struct arr__arr__char sort__arr__arr__char__arr__arr__char(struct ctx* ctx, struct arr__arr__char a);
struct mut_arr__arr__char* to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char(struct ctx* ctx, struct arr__arr__char a);
struct arr__char to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char__lambda0(struct ctx* ctx, struct to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char__lambda0___closure* _closure, uint64_t i);
uint8_t sort___void__ptr_mut_arr__arr__char(struct ctx* ctx, struct mut_arr__arr__char* a);
uint8_t sort___void__ptr_mut_slice__arr__char(struct ctx* ctx, struct mut_slice__arr__char* a);
uint8_t swap___void__ptr_mut_slice__arr__char__nat__nat(struct ctx* ctx, struct mut_slice__arr__char* a, uint64_t lo, uint64_t hi);
struct arr__char at__arr__char__ptr_mut_slice__arr__char__nat(struct ctx* ctx, struct mut_slice__arr__char* a, uint64_t index);
struct arr__char at__arr__char__ptr_mut_arr__arr__char__nat(struct ctx* ctx, struct mut_arr__arr__char* a, uint64_t index);
struct arr__char noctx_at__arr__char__ptr_mut_arr__arr__char__nat(struct mut_arr__arr__char* a, uint64_t index);
uint8_t set_at___void__ptr_mut_slice__arr__char__nat__arr__char(struct ctx* ctx, struct mut_slice__arr__char* a, uint64_t index, struct arr__char value);
uint64_t partition_recur__nat__ptr_mut_slice__arr__char__arr__char__nat__nat(struct ctx* ctx, struct mut_slice__arr__char* a, struct arr__char pivot, uint64_t l, uint64_t r);
uint8_t _op_less__bool__arr__char__arr__char(struct arr__char a, struct arr__char b);
struct mut_slice__arr__char* slice__ptr_mut_slice__arr__char__ptr_mut_slice__arr__char__nat__nat(struct ctx* ctx, struct mut_slice__arr__char* a, uint64_t lo, uint64_t size);
struct mut_slice__arr__char* slice__ptr_mut_slice__arr__char__ptr_mut_slice__arr__char__nat(struct ctx* ctx, struct mut_slice__arr__char* a, uint64_t lo);
struct mut_slice__arr__char* to_mut_slice__ptr_mut_slice__arr__char__ptr_mut_arr__arr__char(struct ctx* ctx, struct mut_arr__arr__char* a);
uint8_t each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0(struct ctx* ctx, struct each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0___closure* _closure, struct arr__char child_name);
struct opt__arr__char get_extension__opt__arr__char__arr__char(struct ctx* ctx, struct arr__char name);
struct opt__nat last_index_of__opt__nat__arr__char__char(struct ctx* ctx, struct arr__char s, char c);
struct arr__char slice_after__arr__char__arr__char__nat(struct ctx* ctx, struct arr__char a, uint64_t before_begin);
struct arr__char base_name__arr__char__arr__char(struct ctx* ctx, struct arr__char path);
uint8_t list_compile_error_tests__arr__arr__char__arr__char__lambda1(struct ctx* ctx, struct list_compile_error_tests__arr__arr__char__arr__char__lambda1___closure* _closure, struct arr__char child);
struct arr__ptr_failure flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char(struct ctx* ctx, struct arr__arr__char a, uint64_t max_size, struct fun_mut1__arr__ptr_failure__arr__char mapper);
struct mut_arr__ptr_failure* new_mut_arr__ptr_mut_arr__ptr_failure(struct ctx* ctx);
uint8_t push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure(struct ctx* ctx, struct mut_arr__ptr_failure* a, struct arr__ptr_failure values);
uint8_t each___void__arr__ptr_failure__fun_mut1___void__ptr_failure(struct ctx* ctx, struct arr__ptr_failure a, struct fun_mut1___void__ptr_failure f);
uint8_t empty__q__bool__arr__ptr_failure(struct arr__ptr_failure a);
uint8_t call___void__fun_mut1___void__ptr_failure__ptr_failure(struct ctx* ctx, struct fun_mut1___void__ptr_failure f, struct failure* p0);
uint8_t call_with_ctx___void__ptr_ctx__fun_mut1___void__ptr_failure__ptr_failure(struct ctx* c, struct fun_mut1___void__ptr_failure f, struct failure* p0);
struct failure* first__ptr_failure__arr__ptr_failure(struct ctx* ctx, struct arr__ptr_failure a);
struct failure* at__ptr_failure__arr__ptr_failure__nat(struct ctx* ctx, struct arr__ptr_failure a, uint64_t index);
struct failure* noctx_at__ptr_failure__arr__ptr_failure__nat(struct arr__ptr_failure a, uint64_t index);
struct arr__ptr_failure tail__arr__ptr_failure__arr__ptr_failure(struct ctx* ctx, struct arr__ptr_failure a);
struct arr__ptr_failure slice_starting_at__arr__ptr_failure__arr__ptr_failure__nat(struct ctx* ctx, struct arr__ptr_failure a, uint64_t begin);
struct arr__ptr_failure slice__arr__ptr_failure__arr__ptr_failure__nat__nat(struct ctx* ctx, struct arr__ptr_failure a, uint64_t begin, uint64_t size);
uint8_t push___void__ptr_mut_arr__ptr_failure__ptr_failure(struct ctx* ctx, struct mut_arr__ptr_failure* a, struct failure* value);
uint8_t increase_capacity_to___void__ptr_mut_arr__ptr_failure__nat(struct ctx* ctx, struct mut_arr__ptr_failure* a, uint64_t new_capacity);
struct failure** uninitialized_data__ptr__ptr_failure__nat(struct ctx* ctx, uint64_t size);
uint8_t copy_data_from___void__ptr__ptr_failure__ptr__ptr_failure__nat(struct ctx* ctx, struct failure** to, struct failure** from, uint64_t len);
uint8_t copy_data_from_small___void__ptr__ptr_failure__ptr__ptr_failure__nat(struct ctx* ctx, struct failure** to, struct failure** from, uint64_t len);
struct failure** incr__ptr__ptr_failure__ptr__ptr_failure(struct failure** p);
uint8_t ensure_capacity___void__ptr_mut_arr__ptr_failure__nat(struct ctx* ctx, struct mut_arr__ptr_failure* a, uint64_t capacity);
uint8_t push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure__lambda0(struct ctx* ctx, struct push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure__lambda0___closure* _closure, struct failure* it);
struct arr__ptr_failure call__arr__ptr_failure__fun_mut1__arr__ptr_failure__arr__char__arr__char(struct ctx* ctx, struct fun_mut1__arr__ptr_failure__arr__char f, struct arr__char p0);
struct arr__ptr_failure call_with_ctx__arr__ptr_failure__ptr_ctx__fun_mut1__arr__ptr_failure__arr__char__arr__char(struct ctx* c, struct fun_mut1__arr__ptr_failure__arr__char f, struct arr__char p0);
uint8_t reduce_size_if_more_than___void__ptr_mut_arr__ptr_failure__nat(struct ctx* ctx, struct mut_arr__ptr_failure* a, uint64_t new_size);
uint8_t flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0(struct ctx* ctx, struct flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0___closure* _closure, struct arr__char x);
struct arr__ptr_failure freeze__arr__ptr_failure__ptr_mut_arr__ptr_failure(struct mut_arr__ptr_failure* a);
struct arr__ptr_failure unsafe_as_arr__arr__ptr_failure__ptr_mut_arr__ptr_failure(struct mut_arr__ptr_failure* a);
struct arr__ptr_failure run_single_compile_error_test__arr__ptr_failure__arr__char__ptr_dict__arr__char__arr__char__arr__char__bool(struct ctx* ctx, struct arr__char path_to_noze, struct dict__arr__char__arr__char* env, struct arr__char path, uint8_t overwrite_output__q);
struct process_result* spawn_and_wait_result__ptr_process_result__arr__char__arr__arr__char__ptr_dict__arr__char__arr__char(struct ctx* ctx, struct arr__char exe, struct arr__arr__char args, struct dict__arr__char__arr__char* environ);
struct arr__char fold__arr__char__arr__char__arr__arr__char__fun_mut2__arr__char__arr__char__arr__char(struct ctx* ctx, struct arr__char val, struct arr__arr__char a, struct fun_mut2__arr__char__arr__char__arr__char combine);
struct arr__char call__arr__char__fun_mut2__arr__char__arr__char__arr__char__arr__char__arr__char(struct ctx* ctx, struct fun_mut2__arr__char__arr__char__arr__char f, struct arr__char p0, struct arr__char p1);
struct arr__char call_with_ctx__arr__char__ptr_ctx__fun_mut2__arr__char__arr__char__arr__char__arr__char__arr__char(struct ctx* c, struct fun_mut2__arr__char__arr__char__arr__char f, struct arr__char p0, struct arr__char p1);
struct arr__char spawn_and_wait_result__ptr_process_result__arr__char__arr__arr__char__ptr_dict__arr__char__arr__char__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr__char a, struct arr__char b);
uint8_t is_file__q__bool__arr__char(struct ctx* ctx, struct arr__char path);
uint8_t is_file__q__bool__ptr__char(struct ctx* ctx, char* path);
uint32_t s_ifreg__nat32(struct ctx* ctx);
struct process_result* spawn_and_wait_result__ptr_process_result__ptr__char__ptr__ptr__char__ptr__ptr__char(struct ctx* ctx, char* exe, char** args, char** environ);
struct pipes* make_pipes__ptr_pipes(struct ctx* ctx);
extern int32_t pipe(struct pipes* pipes);
extern int32_t posix_spawn_file_actions_init(struct posix_spawn_file_actions_t* file_actions);
extern int32_t posix_spawn_file_actions_addclose(struct posix_spawn_file_actions_t* file_actions, int32_t fd);
extern int32_t posix_spawn_file_actions_adddup2(struct posix_spawn_file_actions_t* file_actions, int32_t fd, int32_t new_fd);
struct cell__int32* new_cell__ptr_cell__int32__int32(struct ctx* ctx, int32_t value);
extern int32_t posix_spawn(struct cell__int32* pid, char* executable_path, struct posix_spawn_file_actions_t* file_actions, uint8_t* attrp, char** argv, char** environ);
int32_t get__int32__ptr_cell__int32(struct cell__int32* c);
extern int32_t close(int32_t fd);
struct mut_arr__char* new_mut_arr__ptr_mut_arr__char(struct ctx* ctx);
uint8_t keep_polling___void__int32__int32__ptr_mut_arr__char__ptr_mut_arr__char(struct ctx* ctx, int32_t stdout_pipe, int32_t stderr_pipe, struct mut_arr__char* stdout_builder, struct mut_arr__char* stderr_builder);
int16_t pollin__int16(struct ctx* ctx);
int16_t two_pow__int16__int16(int16_t pow);
uint8_t zero__q__bool__int16(int16_t a);
uint8_t _op_equal_equal__bool__int16__int16(int16_t a, int16_t b);
struct comparison _op_less_equal_greater__comparison__int16__int16(int16_t a, int16_t b);
int16_t wrap_decr__int16__int16(int16_t a);
int16_t two__int16();
int16_t wrap_incr__int16__int16(int16_t a);
struct pollfd* ref_of_val_at__ptr_pollfd__arr__pollfd__nat(struct ctx* ctx, struct arr__pollfd a, uint64_t index);
struct pollfd* ref_of_ptr__ptr_pollfd__ptr__pollfd(struct pollfd* p);
extern int32_t poll(struct pollfd* fds, uint64_t n_fds, int32_t timeout);
struct handle_revents_result handle_revents__handle_revents_result__ptr_pollfd__ptr_mut_arr__char(struct ctx* ctx, struct pollfd* pollfd, struct mut_arr__char* builder);
uint8_t has_pollin__q__bool__int16(struct ctx* ctx, int16_t revents);
uint8_t bits_intersect__q__bool__int16__int16(int16_t a, int16_t b);
uint8_t read_to_buffer_until_eof___void__int32__ptr_mut_arr__char(struct ctx* ctx, int32_t fd, struct mut_arr__char* buffer);
uint64_t two_pow__nat__nat(uint64_t pow);
uint8_t ensure_capacity___void__ptr_mut_arr__char__nat(struct ctx* ctx, struct mut_arr__char* a, uint64_t capacity);
uint8_t increase_capacity_to___void__ptr_mut_arr__char__nat(struct ctx* ctx, struct mut_arr__char* a, uint64_t new_capacity);
uint8_t copy_data_from___void__ptr__char__ptr__char__nat(struct ctx* ctx, char* to, char* from, uint64_t len);
uint8_t copy_data_from_small___void__ptr__char__ptr__char__nat(struct ctx* ctx, char* to, char* from, uint64_t len);
extern int64_t read(int32_t fd, uint8_t* buff, uint64_t n_bytes);
uint8_t unsafe_increase_size___void__ptr_mut_arr__char__nat(struct ctx* ctx, struct mut_arr__char* a, uint64_t increase_by);
uint8_t unsafe_set_size___void__ptr_mut_arr__char__nat(struct ctx* ctx, struct mut_arr__char* a, uint64_t new_size);
uint8_t has_pollhup__q__bool__int16(struct ctx* ctx, int16_t revents);
int16_t pollhup__int16(struct ctx* ctx);
int16_t four__int16();
int16_t three__int16();
uint8_t has_pollpri__q__bool__int16(struct ctx* ctx, int16_t revents);
int16_t pollpri__int16(struct ctx* ctx);
uint8_t has_pollout__q__bool__int16(struct ctx* ctx, int16_t revents);
int16_t pollout__int16(struct ctx* ctx);
uint8_t has_pollerr__q__bool__int16(struct ctx* ctx, int16_t revents);
int16_t pollerr__int16(struct ctx* ctx);
uint8_t has_pollnval__q__bool__int16(struct ctx* ctx, int16_t revents);
int16_t pollnval__int16(struct ctx* ctx);
int16_t five__int16();
uint64_t to_nat__nat__bool(struct ctx* ctx, uint8_t b);
uint8_t any__q__bool__handle_revents_result(struct ctx* ctx, struct handle_revents_result r);
uint64_t to_nat__nat__int32(struct ctx* ctx, int32_t i);
int32_t wait_and_get_exit_code__int32__int32(struct ctx* ctx, int32_t pid);
extern int32_t waitpid(int32_t pid, struct cell__int32* wait_status, int32_t options);
uint8_t w_if_exited__bool__int32(struct ctx* ctx, int32_t status);
int32_t w_term_sig__int32__int32(struct ctx* ctx, int32_t status);
int32_t x7f__int32();
int32_t noctx_decr__int32__int32(int32_t a);
int32_t two_pow__int32__int32(int32_t pow);
int32_t wrap_decr__int32__int32(int32_t a);
int32_t w_exit_status__int32__int32(struct ctx* ctx, int32_t status);
int32_t xff00__int32();
int32_t xffff__int32();
int32_t sixteen__int32();
int32_t xff__int32();
uint8_t w_if_signaled__bool__int32(struct ctx* ctx, int32_t status);
uint8_t _op_bang_equal__bool__int32__int32(int32_t a, int32_t b);
struct arr__char to_str__arr__char__int32(struct ctx* ctx, int32_t i);
struct arr__char to_str__arr__char___int(struct ctx* ctx, int64_t i);
struct arr__char to_str__arr__char__nat(struct ctx* ctx, uint64_t n);
uint64_t mod__nat__nat__nat(struct ctx* ctx, uint64_t a, uint64_t b);
uint64_t abs__nat___int(struct ctx* ctx, int64_t i);
int32_t todo__int32();
uint8_t w_if_stopped__bool__int32(struct ctx* ctx, int32_t status);
uint8_t w_if_continued__bool__int32(struct ctx* ctx, int32_t status);
char** convert_args__ptr__ptr__char__ptr__char__arr__arr__char(struct ctx* ctx, char* exe_c_str, struct arr__arr__char args);
struct arr__ptr__char cons__arr__ptr__char__ptr__char__arr__ptr__char(struct ctx* ctx, char* a, struct arr__ptr__char b);
struct arr__ptr__char _op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char(struct ctx* ctx, struct arr__ptr__char a, struct arr__ptr__char b);
struct arr__ptr__char make_arr__arr__ptr__char__nat__fun_mut1__ptr__char__nat(struct ctx* ctx, uint64_t size, struct fun_mut1__ptr__char__nat f);
struct arr__ptr__char freeze__arr__ptr__char__ptr_mut_arr__ptr__char(struct mut_arr__ptr__char* a);
struct arr__ptr__char unsafe_as_arr__arr__ptr__char__ptr_mut_arr__ptr__char(struct mut_arr__ptr__char* a);
struct mut_arr__ptr__char* make_mut_arr__ptr_mut_arr__ptr__char__nat__fun_mut1__ptr__char__nat(struct ctx* ctx, uint64_t size, struct fun_mut1__ptr__char__nat f);
struct mut_arr__ptr__char* new_uninitialized_mut_arr__ptr_mut_arr__ptr__char__nat(struct ctx* ctx, uint64_t size);
char** uninitialized_data__ptr__ptr__char__nat(struct ctx* ctx, uint64_t size);
uint8_t make_mut_arr_worker___void__ptr_mut_arr__ptr__char__nat__fun_mut1__ptr__char__nat(struct ctx* ctx, struct mut_arr__ptr__char* m, uint64_t i, struct fun_mut1__ptr__char__nat f);
uint8_t set_at___void__ptr_mut_arr__ptr__char__nat__ptr__char(struct ctx* ctx, struct mut_arr__ptr__char* a, uint64_t index, char* value);
uint8_t noctx_set_at___void__ptr_mut_arr__ptr__char__nat__ptr__char(struct mut_arr__ptr__char* a, uint64_t index, char* value);
char* call__ptr__char__fun_mut1__ptr__char__nat__nat(struct ctx* ctx, struct fun_mut1__ptr__char__nat f, uint64_t p0);
char* call_with_ctx__ptr__char__ptr_ctx__fun_mut1__ptr__char__nat__nat(struct ctx* c, struct fun_mut1__ptr__char__nat f, uint64_t p0);
char* _op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char__lambda0(struct ctx* ctx, struct _op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char__lambda0___closure* _closure, uint64_t i);
struct arr__ptr__char rcons__arr__ptr__char__arr__ptr__char__ptr__char(struct ctx* ctx, struct arr__ptr__char a, char* b);
struct arr__ptr__char map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char(struct ctx* ctx, struct arr__arr__char a, struct fun_mut1__ptr__char__arr__char mapper);
char* call__ptr__char__fun_mut1__ptr__char__arr__char__arr__char(struct ctx* ctx, struct fun_mut1__ptr__char__arr__char f, struct arr__char p0);
char* call_with_ctx__ptr__char__ptr_ctx__fun_mut1__ptr__char__arr__char__arr__char(struct ctx* c, struct fun_mut1__ptr__char__arr__char f, struct arr__char p0);
char* map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0(struct ctx* ctx, struct map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0___closure* _closure, uint64_t i);
char* convert_args__ptr__ptr__char__ptr__char__arr__arr__char__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr__char it);
char** convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char(struct ctx* ctx, struct dict__arr__char__arr__char* environ);
struct mut_arr__ptr__char* new_mut_arr__ptr_mut_arr__ptr__char(struct ctx* ctx);
uint8_t each___void__ptr_dict__arr__char__arr__char__fun_mut2___void__arr__char__arr__char(struct ctx* ctx, struct dict__arr__char__arr__char* d, struct fun_mut2___void__arr__char__arr__char f);
uint8_t empty__q__bool__ptr_dict__arr__char__arr__char(struct ctx* ctx, struct dict__arr__char__arr__char* d);
uint8_t call___void__fun_mut2___void__arr__char__arr__char__arr__char__arr__char(struct ctx* ctx, struct fun_mut2___void__arr__char__arr__char f, struct arr__char p0, struct arr__char p1);
uint8_t call_with_ctx___void__ptr_ctx__fun_mut2___void__arr__char__arr__char__arr__char__arr__char(struct ctx* c, struct fun_mut2___void__arr__char__arr__char f, struct arr__char p0, struct arr__char p1);
uint8_t push___void__ptr_mut_arr__ptr__char__ptr__char(struct ctx* ctx, struct mut_arr__ptr__char* a, char* value);
uint8_t increase_capacity_to___void__ptr_mut_arr__ptr__char__nat(struct ctx* ctx, struct mut_arr__ptr__char* a, uint64_t new_capacity);
uint8_t copy_data_from___void__ptr__ptr__char__ptr__ptr__char__nat(struct ctx* ctx, char** to, char** from, uint64_t len);
uint8_t copy_data_from_small___void__ptr__ptr__char__ptr__ptr__char__nat(struct ctx* ctx, char** to, char** from, uint64_t len);
uint8_t ensure_capacity___void__ptr_mut_arr__ptr__char__nat(struct ctx* ctx, struct mut_arr__ptr__char* a, uint64_t capacity);
uint8_t convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char__lambda0(struct ctx* ctx, struct convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char__lambda0___closure* _closure, struct arr__char key, struct arr__char value);
struct process_result* fail__ptr_process_result__arr__char(struct ctx* ctx, struct arr__char reason);
struct process_result* throw__ptr_process_result__exception(struct ctx* ctx, struct exception e);
struct process_result* todo__ptr_process_result();
struct arr__char remove_colors__arr__char__arr__char(struct ctx* ctx, struct arr__char s);
uint8_t remove_colors_recur___void__arr__char__ptr_mut_arr__char(struct ctx* ctx, struct arr__char s, struct mut_arr__char* out);
uint8_t remove_colors_recur_2___void__arr__char__ptr_mut_arr__char(struct ctx* ctx, struct arr__char s, struct mut_arr__char* out);
uint8_t push___void__ptr_mut_arr__char__char(struct ctx* ctx, struct mut_arr__char* a, char value);
struct arr__ptr_failure handle_output__arr__ptr_failure__arr__char__arr__char__arr__char__bool(struct ctx* ctx, struct arr__char original_path, struct arr__char output_path, struct arr__char actual, uint8_t overwrite_output__q);
struct opt__arr__char try_read_file__opt__arr__char__arr__char(struct ctx* ctx, struct arr__char path);
struct opt__arr__char try_read_file__opt__arr__char__ptr__char(struct ctx* ctx, char* path);
extern int32_t open(char* path, int32_t oflag, int32_t permission);
int32_t o_rdonly__int32(struct ctx* ctx);
struct opt__arr__char todo__opt__arr__char();
extern int64_t lseek(int32_t f, int64_t offset, int32_t whence);
int32_t seek_end__int32(struct ctx* ctx);
int64_t billion___int();
uint8_t zero__q__bool___int(int64_t i);
int32_t seek_set__int32(struct ctx* ctx);
uint8_t write_file___void__arr__char__arr__char(struct ctx* ctx, struct arr__char path, struct arr__char content);
uint8_t write_file___void__ptr__char__arr__char(struct ctx* ctx, char* path, struct arr__char content);
int32_t o_creat__int32(struct ctx* ctx);
int32_t o_wronly__int32(struct ctx* ctx);
int32_t o_trunc__int32(struct ctx* ctx);
struct arr__ptr_failure empty_arr__arr__ptr_failure();
struct arr__ptr_failure run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0(struct ctx* ctx, struct run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure* _closure, struct arr__char test);
uint8_t has__q__bool__arr__ptr_failure(struct arr__ptr_failure a);
struct err__arr__ptr_failure err__err__arr__ptr_failure__arr__ptr_failure(struct arr__ptr_failure t);
struct arr__ptr_failure with_max_size__arr__ptr_failure__arr__ptr_failure__nat(struct ctx* ctx, struct arr__ptr_failure a, uint64_t max_size);
struct ok__arr__char ok__ok__arr__char__arr__char(struct arr__char t);
struct result__arr__char__arr__ptr_failure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure(struct ctx* ctx, struct result__arr__char__arr__ptr_failure a, struct fun0__result__arr__char__arr__ptr_failure b);
struct result__arr__char__arr__ptr_failure then__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun_mut1__result__arr__char__arr__ptr_failure__arr__char(struct ctx* ctx, struct result__arr__char__arr__ptr_failure a, struct fun_mut1__result__arr__char__arr__ptr_failure__arr__char f);
struct result__arr__char__arr__ptr_failure call__result__arr__char__arr__ptr_failure__fun_mut1__result__arr__char__arr__ptr_failure__arr__char__arr__char(struct ctx* ctx, struct fun_mut1__result__arr__char__arr__ptr_failure__arr__char f, struct arr__char p0);
struct result__arr__char__arr__ptr_failure call_with_ctx__result__arr__char__arr__ptr_failure__ptr_ctx__fun_mut1__result__arr__char__arr__ptr_failure__arr__char__arr__char(struct ctx* c, struct fun_mut1__result__arr__char__arr__ptr_failure__arr__char f, struct arr__char p0);
struct result__arr__char__arr__ptr_failure call__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure(struct ctx* ctx, struct fun0__result__arr__char__arr__ptr_failure f);
struct result__arr__char__arr__ptr_failure call_with_ctx__result__arr__char__arr__ptr_failure__ptr_ctx__fun0__result__arr__char__arr__ptr_failure(struct ctx* c, struct fun0__result__arr__char__arr__ptr_failure f);
struct result__arr__char__arr__ptr_failure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0__lambda0(struct ctx* ctx, struct first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0__lambda0___closure* _closure, struct arr__char b_descr);
struct result__arr__char__arr__ptr_failure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0(struct ctx* ctx, struct first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0___closure* _closure, struct arr__char a_descr);
struct result__arr__char__arr__ptr_failure run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options(struct ctx* ctx, struct arr__char path, struct arr__char path_to_noze, struct dict__arr__char__arr__char* env, struct test_options options);
struct arr__arr__char list_ast_and_model_tests__arr__arr__char__arr__char(struct ctx* ctx, struct arr__char path);
uint8_t list_ast_and_model_tests__arr__arr__char__arr__char__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr__char s);
uint8_t list_ast_and_model_tests__arr__arr__char__arr__char__lambda1(struct ctx* ctx, struct list_ast_and_model_tests__arr__arr__char__arr__char__lambda1___closure* _closure, struct arr__char child);
struct opt__arr__ptr_failure first_some__opt__arr__ptr_failure__arr__arr__char__fun_mut1__opt__arr__ptr_failure__arr__char(struct ctx* ctx, struct arr__arr__char a, struct fun_mut1__opt__arr__ptr_failure__arr__char cb);
struct opt__arr__ptr_failure call__opt__arr__ptr_failure__fun_mut1__opt__arr__ptr_failure__arr__char__arr__char(struct ctx* ctx, struct fun_mut1__opt__arr__ptr_failure__arr__char f, struct arr__char p0);
struct opt__arr__ptr_failure call_with_ctx__opt__arr__ptr_failure__ptr_ctx__fun_mut1__opt__arr__ptr_failure__arr__char__arr__char(struct ctx* c, struct fun_mut1__opt__arr__ptr_failure__arr__char f, struct arr__char p0);
struct arr__ptr_failure run_single_ast_or_model_test__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__arr__char__bool(struct ctx* ctx, struct arr__char ast_or_model, struct arr__char path_to_noze, struct dict__arr__char__arr__char* env, struct arr__char path, uint8_t overwrite_output__q);
struct some__arr__ptr_failure some__some__arr__ptr_failure__arr__ptr_failure(struct arr__ptr_failure t);
struct opt__arr__ptr_failure run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0(struct ctx* ctx, struct run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0___closure* _closure, struct arr__char name);
struct arr__ptr_failure opt_or__arr__ptr_failure__opt__arr__ptr_failure__fun_mut0__arr__ptr_failure(struct ctx* ctx, struct opt__arr__ptr_failure a, struct fun_mut0__arr__ptr_failure _default);
struct arr__ptr_failure call__arr__ptr_failure__fun_mut0__arr__ptr_failure(struct ctx* ctx, struct fun_mut0__arr__ptr_failure f);
struct arr__ptr_failure call_with_ctx__arr__ptr_failure__ptr_ctx__fun_mut0__arr__ptr_failure(struct ctx* c, struct fun_mut0__arr__ptr_failure f);
struct arr__ptr_failure run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda1(struct ctx* ctx, uint8_t* _closure);
struct arr__ptr_failure run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0(struct ctx* ctx, struct run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure* _closure, struct arr__char test);
struct result__arr__char__arr__ptr_failure run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options(struct ctx* ctx, struct arr__char path, struct arr__char path_to_noze, struct dict__arr__char__arr__char* env, struct test_options options);
struct arr__arr__char list_runnable_tests__arr__arr__char__arr__char(struct ctx* ctx, struct arr__char path);
uint8_t list_runnable_tests__arr__arr__char__arr__char__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr__char s);
uint8_t list_runnable_tests__arr__arr__char__arr__char__lambda1(struct ctx* ctx, struct list_runnable_tests__arr__arr__char__arr__char__lambda1___closure* _closure, struct arr__char child);
struct arr__ptr_failure run_single_runnable_test__arr__ptr_failure__arr__char__ptr_dict__arr__char__arr__char__arr__char__bool(struct ctx* ctx, struct arr__char path_to_noze, struct dict__arr__char__arr__char* env, struct arr__char path, uint8_t overwrite_output__q);
struct arr__ptr_failure run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0(struct ctx* ctx, struct run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure* _closure, struct arr__char test);
struct result__arr__char__arr__ptr_failure do_test__int32__test_options__lambda0__lambda0(struct ctx* ctx, struct do_test__int32__test_options__lambda0__lambda0___closure* _closure);
struct result__arr__char__arr__ptr_failure do_test__int32__test_options__lambda0(struct ctx* ctx, struct do_test__int32__test_options__lambda0___closure* _closure);
struct result__arr__char__arr__ptr_failure lint__result__arr__char__arr__ptr_failure__arr__char__test_options(struct ctx* ctx, struct arr__char path, struct test_options options);
struct arr__arr__char list_lintable_files__arr__arr__char__arr__char(struct ctx* ctx, struct arr__char path);
uint8_t list_lintable_files__arr__arr__char__arr__char__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr__char it);
uint8_t ignore_extension_of_name__bool__arr__char(struct ctx* ctx, struct arr__char name);
uint8_t ignore_extension__bool__arr__char(struct ctx* ctx, struct arr__char ext);
uint8_t contains__q__bool__arr__arr__char__arr__char(struct arr__arr__char a, struct arr__char value);
uint8_t contains_recur__q__bool__arr__arr__char__arr__char__nat(struct arr__arr__char a, struct arr__char value, uint64_t i);
struct arr__arr__char ignored_extensions__arr__arr__char(struct ctx* ctx);
uint8_t list_lintable_files__arr__arr__char__arr__char__lambda1(struct ctx* ctx, struct list_lintable_files__arr__arr__char__arr__char__lambda1___closure* _closure, struct arr__char child);
struct arr__ptr_failure lint_file__arr__ptr_failure__arr__char(struct ctx* ctx, struct arr__char path);
struct arr__char read_file__arr__char__arr__char(struct ctx* ctx, struct arr__char path);
uint8_t each_with_index___void__arr__arr__char__fun_mut2___void__arr__char__nat(struct ctx* ctx, struct arr__arr__char a, struct fun_mut2___void__arr__char__nat f);
uint8_t each_with_index_recur___void__arr__arr__char__fun_mut2___void__arr__char__nat__nat(struct ctx* ctx, struct arr__arr__char a, struct fun_mut2___void__arr__char__nat f, uint64_t n);
uint8_t call___void__fun_mut2___void__arr__char__nat__arr__char__nat(struct ctx* ctx, struct fun_mut2___void__arr__char__nat f, struct arr__char p0, uint64_t p1);
uint8_t call_with_ctx___void__ptr_ctx__fun_mut2___void__arr__char__nat__arr__char__nat(struct ctx* c, struct fun_mut2___void__arr__char__nat f, struct arr__char p0, uint64_t p1);
struct arr__arr__char lines__arr__arr__char__arr__char(struct ctx* ctx, struct arr__char s);
struct cell__nat* new_cell__ptr_cell__nat__nat(struct ctx* ctx, uint64_t value);
uint8_t each_with_index___void__arr__char__fun_mut2___void__char__nat(struct ctx* ctx, struct arr__char a, struct fun_mut2___void__char__nat f);
uint8_t each_with_index_recur___void__arr__char__fun_mut2___void__char__nat__nat(struct ctx* ctx, struct arr__char a, struct fun_mut2___void__char__nat f, uint64_t n);
uint8_t call___void__fun_mut2___void__char__nat__char__nat(struct ctx* ctx, struct fun_mut2___void__char__nat f, char p0, uint64_t p1);
uint8_t call_with_ctx___void__ptr_ctx__fun_mut2___void__char__nat__char__nat(struct ctx* c, struct fun_mut2___void__char__nat f, char p0, uint64_t p1);
struct arr__char slice_from_to__arr__char__arr__char__nat__nat(struct ctx* ctx, struct arr__char a, uint64_t begin, uint64_t end);
uint64_t swap__nat__ptr_cell__nat__nat(struct cell__nat* c, uint64_t v);
uint64_t get__nat__ptr_cell__nat(struct cell__nat* c);
uint8_t set___void__ptr_cell__nat__nat(struct cell__nat* c, uint64_t v);
uint8_t lines__arr__arr__char__arr__char__lambda0(struct ctx* ctx, struct lines__arr__arr__char__arr__char__lambda0___closure* _closure, char c, uint64_t index);
uint8_t contains_subsequence__q__bool__arr__char__arr__char(struct ctx* ctx, struct arr__char a, struct arr__char subseq);
uint8_t has__q__bool__arr__char(struct arr__char a);
struct arr__char lstrip__arr__char__arr__char(struct ctx* ctx, struct arr__char a);
uint64_t line_len__nat__arr__char(struct ctx* ctx, struct arr__char line);
uint64_t n_tabs__nat__arr__char(struct ctx* ctx, struct arr__char line);
uint64_t tab_size__nat(struct ctx* ctx);
uint64_t max_line_length__nat(struct ctx* ctx);
uint8_t lint_file__arr__ptr_failure__arr__char__lambda0(struct ctx* ctx, struct lint_file__arr__ptr_failure__arr__char__lambda0___closure* _closure, struct arr__char line, uint64_t line_num);
struct arr__ptr_failure lint__result__arr__char__arr__ptr_failure__arr__char__test_options__lambda0(struct ctx* ctx, struct lint__result__arr__char__arr__ptr_failure__arr__char__test_options__lambda0___closure* _closure, struct arr__char file);
struct result__arr__char__arr__ptr_failure do_test__int32__test_options__lambda1(struct ctx* ctx, struct do_test__int32__test_options__lambda1___closure* _closure);
int32_t print_failures__int32__result__arr__char__arr__ptr_failure__test_options(struct ctx* ctx, struct result__arr__char__arr__ptr_failure failures, struct test_options options);
uint8_t print_failure___void__ptr_failure(struct ctx* ctx, struct failure* failure);
uint8_t print_bold___void(struct ctx* ctx);
uint8_t print_reset___void(struct ctx* ctx);
uint8_t print_failures__int32__result__arr__char__arr__ptr_failure__test_options__lambda0(struct ctx* ctx, uint8_t* _closure, struct failure* it);
int32_t to_int32__int32__nat(struct ctx* ctx, uint64_t n);
int32_t rt_main__int32__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(int32_t argc, char** argv, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char main_ptr) {
	uint64_t n_threads;
	struct global_ctx gctx_by_val;
	struct global_ctx* gctx;
	struct vat vat_by_val;
	struct vat* vat;
	struct arr__ptr_vat vats;
	struct exception_ctx ectx;
	struct thread_local_stuff tls;
	struct ctx ctx_by_val;
	struct ctx* ctx;
	struct fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char add;
	struct arr__ptr__char all_args;
	struct fut__int32* main_fut;
	struct ok__int32 o;
	struct err__exception e;
	struct result__int32__exception matched;
	n_threads = two__nat();
	gctx_by_val = (struct global_ctx) {new_lock__lock(), empty_arr__arr__ptr_vat(), n_threads, new_condition__condition(), 0, 0};
	gctx = (&(gctx_by_val));
	vat_by_val = new_vat__vat__ptr_global_ctx__nat__nat(gctx, 0, n_threads);
	vat = (&(vat_by_val));
	vats = (struct arr__ptr_vat) {1, (&(vat))};
	(gctx->vats = vats, 0);
	ectx = new_exception_ctx__exception_ctx();
	tls = (struct thread_local_stuff) {(&(ectx))};
	ctx_by_val = new_ctx__ctx__ptr_global_ctx__ptr_thread_local_stuff__ptr_vat__nat(gctx, (&(tls)), vat, 0);
	ctx = (&(ctx_by_val));
	add = (struct fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char) {(fun_ptr4__ptr_fut__int32__ptr_ctx__ptr__byte__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char) rt_main__int32__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0, (uint8_t*) NULL};
	all_args = (struct arr__ptr__char) {argc, argv};
	main_fut = call_with_ctx__ptr_fut__int32__ptr_ctx__fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(ctx, add, all_args, main_ptr);
	run_threads___void__nat__ptr_global_ctx__fun_ptr2___void__nat__ptr_global_ctx(n_threads, gctx, rt_main__int32__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda1);
	if (gctx->any_unhandled_exceptions__q) {
		return 1;
	} else {
		matched = must_be_resolved__result__int32__exception__ptr_fut__int32(main_fut);
		switch (matched.kind) {
			case 0:
				o = matched.as0;
				return o.value;
			case 1:
				e = matched.as1;
				print_err_sync_no_newline___void__arr__char((struct arr__char) {13, "main failed: "});
				print_err_sync___void__arr__char(e.value.message);
				return 1;
			default:
				return (assert(0),0);
		}
	}
}
uint64_t two__nat() {
	return wrap_incr__nat__nat(1);
}
uint64_t wrap_incr__nat__nat(uint64_t a) {
	return (a + 1);
}
struct lock new_lock__lock() {
	return (struct lock) {new_atomic_bool___atomic_bool()};
}
struct _atomic_bool new_atomic_bool___atomic_bool() {
	return (struct _atomic_bool) {0};
}
struct arr__ptr_vat empty_arr__arr__ptr_vat() {
	return (struct arr__ptr_vat) {0, NULL};
}
struct condition new_condition__condition() {
	return (struct condition) {new_lock__lock(), 0};
}
struct vat new_vat__vat__ptr_global_ctx__nat__nat(struct global_ctx* gctx, uint64_t id, uint64_t max_threads) {
	struct mut_arr__nat actors;
	actors = new_mut_arr_by_val_with_capacity_from_unmanaged_memory__mut_arr__nat__nat(max_threads);
	return (struct vat) {gctx, id, new_gc__gc(), new_lock__lock(), new_mut_bag__mut_bag__task(), actors, 0, new_thread_safe_counter__thread_safe_counter(), (struct fun_mut1___void__exception) {(fun_ptr3___void__ptr_ctx__ptr__byte__exception) new_vat__vat__ptr_global_ctx__nat__nat__lambda0, (uint8_t*) NULL}};
}
struct mut_arr__nat new_mut_arr_by_val_with_capacity_from_unmanaged_memory__mut_arr__nat__nat(uint64_t capacity) {
	return (struct mut_arr__nat) {0, 0, capacity, unmanaged_alloc_elements__ptr__nat__nat(capacity)};
}
uint64_t* unmanaged_alloc_elements__ptr__nat__nat(uint64_t size_elements) {
	uint8_t* bytes;
	bytes = unmanaged_alloc_bytes__ptr__byte__nat((size_elements * sizeof(uint64_t)));
	return (uint64_t*) bytes;
}
uint8_t* unmanaged_alloc_bytes__ptr__byte__nat(uint64_t size) {
	uint8_t* res;
	res = malloc(size);
	hard_forbid___void__bool(null__q__bool__ptr__byte(res));
	return res;
}
uint8_t hard_forbid___void__bool(uint8_t condition) {
	return hard_assert___void__bool(!condition);
}
uint8_t hard_assert___void__bool(uint8_t condition) {
	if (condition) {
		return 0;
	} else {
		return (assert(0),0);
	}
}
uint8_t null__q__bool__ptr__byte(uint8_t* a) {
	return _op_equal_equal__bool__ptr__byte__ptr__byte(a, NULL);
}
uint8_t _op_equal_equal__bool__ptr__byte__ptr__byte(uint8_t* a, uint8_t* b) {
	struct comparison matched;
	matched = _op_less_equal_greater__comparison__ptr__byte__ptr__byte(a, b);
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
struct comparison _op_less_equal_greater__comparison__ptr__byte__ptr__byte(uint8_t* a, uint8_t* b) {
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
struct gc new_gc__gc() {
	return (struct gc) {new_lock__lock(), (struct opt__ptr_gc_ctx) {0, .as0 = none__none()}, 0, 0, NULL, NULL};
}
struct none none__none() {
	return (struct none) {0};
}
struct mut_bag__task new_mut_bag__mut_bag__task() {
	return (struct mut_bag__task) {(struct opt__ptr_mut_bag_node__task) {0, .as0 = none__none()}};
}
struct thread_safe_counter new_thread_safe_counter__thread_safe_counter() {
	return new_thread_safe_counter__thread_safe_counter__nat(0);
}
struct thread_safe_counter new_thread_safe_counter__thread_safe_counter__nat(uint64_t init) {
	return (struct thread_safe_counter) {new_lock__lock(), init};
}
uint8_t default_exception_handler___void__exception(struct ctx* ctx, struct exception e) {
	print_err_sync_no_newline___void__arr__char((struct arr__char) {20, "uncaught exception: "});
	print_err_sync___void__arr__char((empty__q__bool__arr__char(e.message) ? (struct arr__char) {17, "<<empty message>>"} : e.message));
	return (get_gctx__ptr_global_ctx(ctx)->any_unhandled_exceptions__q = 1, 0);
}
uint8_t print_err_sync_no_newline___void__arr__char(struct arr__char s) {
	return write_sync_no_newline___void__int32__arr__char(stderr_fd__int32(), s);
}
uint8_t write_sync_no_newline___void__int32__arr__char(int32_t fd, struct arr__char s) {
	int64_t res;
	hard_assert___void__bool(_op_equal_equal__bool__nat__nat(sizeof(char), sizeof(uint8_t)));
	res = write(fd, (uint8_t*) s.data, s.size);
	if (_op_equal_equal__bool___int___int(res, s.size)) {
		return 0;
	} else {
		return todo___void();
	}
}
uint8_t _op_equal_equal__bool__nat__nat(uint64_t a, uint64_t b) {
	struct comparison matched;
	matched = _op_less_equal_greater__comparison__nat__nat(a, b);
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
struct comparison _op_less_equal_greater__comparison__nat__nat(uint64_t a, uint64_t b) {
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
uint8_t _op_equal_equal__bool___int___int(int64_t a, int64_t b) {
	struct comparison matched;
	matched = _op_less_equal_greater__comparison___int___int(a, b);
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
struct comparison _op_less_equal_greater__comparison___int___int(int64_t a, int64_t b) {
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
uint8_t todo___void() {
	return (assert(0),0);
}
int32_t stderr_fd__int32() {
	return two__int32();
}
int32_t two__int32() {
	return wrap_incr__int32__int32(1);
}
int32_t wrap_incr__int32__int32(int32_t a) {
	return (a + 1);
}
uint8_t print_err_sync___void__arr__char(struct arr__char s) {
	print_err_sync_no_newline___void__arr__char(s);
	return print_err_sync_no_newline___void__arr__char((struct arr__char) {1, "\n"});
}
uint8_t empty__q__bool__arr__char(struct arr__char a) {
	return zero__q__bool__nat(a.size);
}
uint8_t zero__q__bool__nat(uint64_t n) {
	return _op_equal_equal__bool__nat__nat(n, 0);
}
struct global_ctx* get_gctx__ptr_global_ctx(struct ctx* ctx) {
	return (struct global_ctx*) ctx->gctx_ptr;
}
uint8_t new_vat__vat__ptr_global_ctx__nat__nat__lambda0(struct ctx* ctx, uint8_t* _closure, struct exception it) {
	return default_exception_handler___void__exception(ctx, it);
}
struct exception_ctx new_exception_ctx__exception_ctx() {
	return (struct exception_ctx) {NULL, (struct exception) {(struct arr__char) {0, ""}}};
}
struct ctx new_ctx__ctx__ptr_global_ctx__ptr_thread_local_stuff__ptr_vat__nat(struct global_ctx* gctx, struct thread_local_stuff* tls, struct vat* vat, uint64_t actor_id) {
	return (struct ctx) {(uint8_t*) gctx, vat->id, actor_id, (uint8_t*) get_gc_ctx__ptr_gc_ctx__ptr_gc((&(vat->gc))), (uint8_t*) tls->exception_ctx};
}
struct gc_ctx* get_gc_ctx__ptr_gc_ctx__ptr_gc(struct gc* gc) {
	struct gc_ctx* c;
	struct some__ptr_gc_ctx s;
	struct gc_ctx* c1;
	struct opt__ptr_gc_ctx matched;
	struct gc_ctx* res;
	acquire_lock___void__ptr_lock((&(gc->lk)));
	res = (matched = gc->context_head, matched.kind == 0 ? (c = (struct gc_ctx*) malloc(sizeof(struct gc_ctx*)), (((c->gc = gc, 0), (c->next_ctx = (struct opt__ptr_gc_ctx) {0, .as0 = none__none()}, 0)), c)) : matched.kind == 1 ? (s = matched.as1, (c1 = s.value, (((gc->context_head = c1->next_ctx, 0), (c1->next_ctx = (struct opt__ptr_gc_ctx) {0, .as0 = none__none()}, 0)), c1))) : (assert(0),NULL));
	release_lock___void__ptr_lock((&(gc->lk)));
	return res;
}
uint8_t acquire_lock___void__ptr_lock(struct lock* a) {
	return acquire_lock_recur___void__ptr_lock__nat(a, 0);
}
uint8_t acquire_lock_recur___void__ptr_lock__nat(struct lock* a, uint64_t n_tries) {
	struct lock* _tailCalla;
	uint64_t _tailCalln_tries;
	top:
	if (try_acquire_lock__bool__ptr_lock(a)) {
		return 0;
	} else {
		if (_op_equal_equal__bool__nat__nat(n_tries, thousand__nat())) {
			return (assert(0),0);
		} else {
			yield_thread___void();
			_tailCalla = a;
			_tailCalln_tries = noctx_incr__nat__nat(n_tries);
			a = _tailCalla;
			n_tries = _tailCalln_tries;
			goto top;
		}
	}
}
uint8_t try_acquire_lock__bool__ptr_lock(struct lock* a) {
	return try_set__bool__ptr__atomic_bool((&(a->is_locked)));
}
uint8_t try_set__bool__ptr__atomic_bool(struct _atomic_bool* a) {
	return try_change__bool__ptr__atomic_bool__bool(a, 0);
}
uint8_t try_change__bool__ptr__atomic_bool__bool(struct _atomic_bool* a, uint8_t old_value) {
	return atomic_compare_exchange_strong((&(a->value)), (&(old_value)), !old_value);
}
uint64_t thousand__nat() {
	return (hundred__nat() * ten__nat());
}
uint64_t hundred__nat() {
	return (ten__nat() * ten__nat());
}
uint64_t ten__nat() {
	return wrap_incr__nat__nat(nine__nat());
}
uint64_t nine__nat() {
	return wrap_incr__nat__nat(eight__nat());
}
uint64_t eight__nat() {
	return wrap_incr__nat__nat(seven__nat());
}
uint64_t seven__nat() {
	return wrap_incr__nat__nat(six__nat());
}
uint64_t six__nat() {
	return wrap_incr__nat__nat(five__nat());
}
uint64_t five__nat() {
	return wrap_incr__nat__nat(four__nat());
}
uint64_t four__nat() {
	return wrap_incr__nat__nat(three__nat());
}
uint64_t three__nat() {
	return wrap_incr__nat__nat(two__nat());
}
uint8_t yield_thread___void() {
	int32_t err;
	err = pthread_yield();
	(usleep(thousand__nat()), 0);
	return hard_assert___void__bool(zero__q__bool__int32(err));
}
uint8_t zero__q__bool__int32(int32_t i) {
	return _op_equal_equal__bool__int32__int32(i, 0);
}
uint8_t _op_equal_equal__bool__int32__int32(int32_t a, int32_t b) {
	struct comparison matched;
	matched = _op_less_equal_greater__comparison__int32__int32(a, b);
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
struct comparison _op_less_equal_greater__comparison__int32__int32(int32_t a, int32_t b) {
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
uint64_t noctx_incr__nat__nat(uint64_t n) {
	hard_assert___void__bool(_op_less__bool__nat__nat(n, billion__nat()));
	return wrap_incr__nat__nat(n);
}
uint8_t _op_less__bool__nat__nat(uint64_t a, uint64_t b) {
	struct comparison matched;
	matched = _op_less_equal_greater__comparison__nat__nat(a, b);
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
uint64_t billion__nat() {
	return (million__nat() * thousand__nat());
}
uint64_t million__nat() {
	return (thousand__nat() * thousand__nat());
}
uint8_t release_lock___void__ptr_lock(struct lock* l) {
	return must_unset___void__ptr__atomic_bool((&(l->is_locked)));
}
uint8_t must_unset___void__ptr__atomic_bool(struct _atomic_bool* a) {
	uint8_t did_unset;
	did_unset = try_unset__bool__ptr__atomic_bool(a);
	return hard_assert___void__bool(did_unset);
}
uint8_t try_unset__bool__ptr__atomic_bool(struct _atomic_bool* a) {
	return try_change__bool__ptr__atomic_bool__bool(a, 1);
}
struct fut__int32* add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(struct ctx* ctx, struct arr__ptr__char all_args, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char main_ptr) {
	struct add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0___closure* temp0;
	return then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32(ctx, resolved__ptr_fut___void___void(ctx, 0), (struct fun_ref0__int32) {cur_actor__vat_and_actor_id(ctx), (struct fun_mut0__ptr_fut__int32) {(fun_ptr2__ptr_fut__int32__ptr_ctx__ptr__byte) add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0, (uint8_t*) (temp0 = (struct add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0___closure)), ((*(temp0) = (struct add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0___closure) {all_args, main_ptr}, 0), temp0))}});
}
struct fut__int32* then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32(struct ctx* ctx, struct fut___void* f, struct fun_ref0__int32 cb) {
	struct then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0___closure* temp0;
	return then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void(ctx, f, (struct fun_ref1__int32___void) {cur_actor__vat_and_actor_id(ctx), (struct fun_mut1__ptr_fut__int32___void) {(fun_ptr3__ptr_fut__int32__ptr_ctx__ptr__byte___void) then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0, (uint8_t*) (temp0 = (struct then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0___closure)), ((*(temp0) = (struct then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0___closure) {cb}, 0), temp0))}});
}
struct fut__int32* then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void(struct ctx* ctx, struct fut___void* f, struct fun_ref1__int32___void cb) {
	struct fut__int32* res;
	struct then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0___closure* temp0;
	res = new_unresolved_fut__ptr_fut__int32(ctx);
	then_void___void__ptr_fut___void__fun_mut1___void__result___void__exception(ctx, f, (struct fun_mut1___void__result___void__exception) {(fun_ptr3___void__ptr_ctx__ptr__byte__result___void__exception) then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0, (uint8_t*) (temp0 = (struct then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0___closure)), ((*(temp0) = (struct then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0___closure) {cb, res}, 0), temp0))});
	return res;
}
struct fut__int32* new_unresolved_fut__ptr_fut__int32(struct ctx* ctx) {
	struct fut__int32* temp0;
	temp0 = (struct fut__int32*) alloc__ptr__byte__nat(ctx, sizeof(struct fut__int32));
	(*(temp0) = (struct fut__int32) {new_lock__lock(), (struct fut_state__int32) {0, .as0 = (struct fut_state_callbacks__int32) {(struct opt__ptr_fut_callback_node__int32) {0, .as0 = none__none()}}}}, 0);
	return temp0;
}
uint8_t* alloc__ptr__byte__nat(struct ctx* ctx, uint64_t size) {
	return gc_alloc__ptr__byte__ptr_gc__nat(ctx, get_gc__ptr_gc(ctx), size);
}
uint8_t* gc_alloc__ptr__byte__ptr_gc__nat(struct ctx* ctx, struct gc* gc, uint64_t size) {
	struct some__ptr__byte s;
	struct opt__ptr__byte matched;
	matched = try_gc_alloc__opt__ptr__byte__ptr_gc__nat(gc, size);
	switch (matched.kind) {
		case 0:
			return todo__ptr__byte();
		case 1:
			s = matched.as1;
			return s.value;
		default:
			return (assert(0),NULL);
	}
}
struct opt__ptr__byte try_gc_alloc__opt__ptr__byte__ptr_gc__nat(struct gc* gc, uint64_t size) {
	return (struct opt__ptr__byte) {1, .as1 = some__some__ptr__byte__ptr__byte(unmanaged_alloc_bytes__ptr__byte__nat(size))};
}
struct some__ptr__byte some__some__ptr__byte__ptr__byte(uint8_t* t) {
	return (struct some__ptr__byte) {t};
}
uint8_t* todo__ptr__byte() {
	return (assert(0),NULL);
}
struct gc* get_gc__ptr_gc(struct ctx* ctx) {
	return get_gc_ctx__ptr_gc_ctx(ctx)->gc;
}
struct gc_ctx* get_gc_ctx__ptr_gc_ctx(struct ctx* ctx) {
	return (struct gc_ctx*) ctx->gc_ctx_ptr;
}
uint8_t then_void___void__ptr_fut___void__fun_mut1___void__result___void__exception(struct ctx* ctx, struct fut___void* f, struct fun_mut1___void__result___void__exception cb) {
	struct fut_state_callbacks___void cbs;
	struct fut_state_resolved___void r;
	struct exception e;
	struct fut_state___void matched;
	struct fut_callback_node___void* temp0;
	acquire_lock___void__ptr_lock((&(f->lk)));
	matched = f->state;
	switch (matched.kind) {
		case 0:
			cbs = matched.as0;
			(f->state = (struct fut_state___void) {0, .as0 = (struct fut_state_callbacks___void) {(struct opt__ptr_fut_callback_node___void) {1, .as1 = some__some__ptr_fut_callback_node___void__ptr_fut_callback_node___void((temp0 = (struct fut_callback_node___void*) alloc__ptr__byte__nat(ctx, sizeof(struct fut_callback_node___void)), ((*(temp0) = (struct fut_callback_node___void) {cb, cbs.head}, 0), temp0)))}}}, 0);
			break;
		case 1:
			r = matched.as1;
			call___void__fun_mut1___void__result___void__exception__result___void__exception(ctx, cb, (struct result___void__exception) {0, .as0 = ok__ok___void___void(r.value)});
			break;
		case 2:
			e = matched.as2;
			call___void__fun_mut1___void__result___void__exception__result___void__exception(ctx, cb, (struct result___void__exception) {1, .as1 = err__err__exception__exception(e)});
			break;
		default:
			(assert(0),0);
	}
	return release_lock___void__ptr_lock((&(f->lk)));
}
struct some__ptr_fut_callback_node___void some__some__ptr_fut_callback_node___void__ptr_fut_callback_node___void(struct fut_callback_node___void* t) {
	return (struct some__ptr_fut_callback_node___void) {t};
}
uint8_t call___void__fun_mut1___void__result___void__exception__result___void__exception(struct ctx* ctx, struct fun_mut1___void__result___void__exception f, struct result___void__exception p0) {
	return call_with_ctx___void__ptr_ctx__fun_mut1___void__result___void__exception__result___void__exception(ctx, f, p0);
}
uint8_t call_with_ctx___void__ptr_ctx__fun_mut1___void__result___void__exception__result___void__exception(struct ctx* c, struct fun_mut1___void__result___void__exception f, struct result___void__exception p0) {
	return f.fun_ptr(c, f.closure, p0);
}
struct ok___void ok__ok___void___void(uint8_t t) {
	return (struct ok___void) {t};
}
struct err__exception err__err__exception__exception(struct exception t) {
	return (struct err__exception) {t};
}
uint8_t forward_to___void__ptr_fut__int32__ptr_fut__int32(struct ctx* ctx, struct fut__int32* from, struct fut__int32* to) {
	struct forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0___closure* temp0;
	return then_void___void__ptr_fut__int32__fun_mut1___void__result__int32__exception(ctx, from, (struct fun_mut1___void__result__int32__exception) {(fun_ptr3___void__ptr_ctx__ptr__byte__result__int32__exception) forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0, (uint8_t*) (temp0 = (struct forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0___closure)), ((*(temp0) = (struct forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0___closure) {to}, 0), temp0))});
}
uint8_t then_void___void__ptr_fut__int32__fun_mut1___void__result__int32__exception(struct ctx* ctx, struct fut__int32* f, struct fun_mut1___void__result__int32__exception cb) {
	struct fut_state_callbacks__int32 cbs;
	struct fut_state_resolved__int32 r;
	struct exception e;
	struct fut_state__int32 matched;
	struct fut_callback_node__int32* temp0;
	acquire_lock___void__ptr_lock((&(f->lk)));
	matched = f->state;
	switch (matched.kind) {
		case 0:
			cbs = matched.as0;
			(f->state = (struct fut_state__int32) {0, .as0 = (struct fut_state_callbacks__int32) {(struct opt__ptr_fut_callback_node__int32) {1, .as1 = some__some__ptr_fut_callback_node__int32__ptr_fut_callback_node__int32((temp0 = (struct fut_callback_node__int32*) alloc__ptr__byte__nat(ctx, sizeof(struct fut_callback_node__int32)), ((*(temp0) = (struct fut_callback_node__int32) {cb, cbs.head}, 0), temp0)))}}}, 0);
			break;
		case 1:
			r = matched.as1;
			call___void__fun_mut1___void__result__int32__exception__result__int32__exception(ctx, cb, (struct result__int32__exception) {0, .as0 = ok__ok__int32__int32(r.value)});
			break;
		case 2:
			e = matched.as2;
			call___void__fun_mut1___void__result__int32__exception__result__int32__exception(ctx, cb, (struct result__int32__exception) {1, .as1 = err__err__exception__exception(e)});
			break;
		default:
			(assert(0),0);
	}
	return release_lock___void__ptr_lock((&(f->lk)));
}
struct some__ptr_fut_callback_node__int32 some__some__ptr_fut_callback_node__int32__ptr_fut_callback_node__int32(struct fut_callback_node__int32* t) {
	return (struct some__ptr_fut_callback_node__int32) {t};
}
uint8_t call___void__fun_mut1___void__result__int32__exception__result__int32__exception(struct ctx* ctx, struct fun_mut1___void__result__int32__exception f, struct result__int32__exception p0) {
	return call_with_ctx___void__ptr_ctx__fun_mut1___void__result__int32__exception__result__int32__exception(ctx, f, p0);
}
uint8_t call_with_ctx___void__ptr_ctx__fun_mut1___void__result__int32__exception__result__int32__exception(struct ctx* c, struct fun_mut1___void__result__int32__exception f, struct result__int32__exception p0) {
	return f.fun_ptr(c, f.closure, p0);
}
struct ok__int32 ok__ok__int32__int32(int32_t t) {
	return (struct ok__int32) {t};
}
uint8_t resolve_or_reject___void__ptr_fut__int32__result__int32__exception(struct ctx* ctx, struct fut__int32* f, struct result__int32__exception result) {
	struct fut_state_callbacks__int32 cbs;
	struct fut_state__int32 matched;
	struct ok__int32 o;
	struct err__exception e;
	struct result__int32__exception matched1;
	acquire_lock___void__ptr_lock((&(f->lk)));
	matched = f->state;
	switch (matched.kind) {
		case 0:
			cbs = matched.as0;
			resolve_or_reject_recur___void__opt__ptr_fut_callback_node__int32__result__int32__exception(ctx, cbs.head, result);
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
	(f->state = (matched1 = result, matched1.kind == 0 ? (o = matched1.as0, (struct fut_state__int32) {1, .as1 = (struct fut_state_resolved__int32) {o.value}}) : matched1.kind == 1 ? (e = matched1.as1, (struct fut_state__int32) {2, .as2 = e.value}) : (assert(0),(struct fut_state__int32) {0})), 0);
	return release_lock___void__ptr_lock((&(f->lk)));
}
uint8_t resolve_or_reject_recur___void__opt__ptr_fut_callback_node__int32__result__int32__exception(struct ctx* ctx, struct opt__ptr_fut_callback_node__int32 node, struct result__int32__exception value) {
	struct some__ptr_fut_callback_node__int32 s;
	struct opt__ptr_fut_callback_node__int32 matched;
	struct ctx* _tailCallctx;
	struct opt__ptr_fut_callback_node__int32 _tailCallnode;
	struct result__int32__exception _tailCallvalue;
	top:
	matched = node;
	switch (matched.kind) {
		case 0:
			return 0;
		case 1:
			s = matched.as1;
			drop___void___void(call___void__fun_mut1___void__result__int32__exception__result__int32__exception(ctx, s.value->cb, value));
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
uint8_t drop___void___void(uint8_t t) {
	return 0;
}
uint8_t forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0(struct ctx* ctx, struct forward_to___void__ptr_fut__int32__ptr_fut__int32__lambda0___closure* _closure, struct result__int32__exception it) {
	return resolve_or_reject___void__ptr_fut__int32__result__int32__exception(ctx, _closure->to, it);
}
struct fut__int32* call__ptr_fut__int32__fun_ref1__int32___void___void(struct ctx* ctx, struct fun_ref1__int32___void f, uint8_t p0) {
	struct vat* vat;
	struct fut__int32* res;
	struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0___closure* temp0;
	vat = get_vat__ptr_vat__nat(ctx, f.vat_and_actor.vat);
	res = new_unresolved_fut__ptr_fut__int32(ctx);
	add_task___void__ptr_vat__task(ctx, vat, (struct task) {f.vat_and_actor.actor, (struct fun_mut0___void) {(fun_ptr2___void__ptr_ctx__ptr__byte) call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0, (uint8_t*) (temp0 = (struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0___closure)), ((*(temp0) = (struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0___closure) {f, p0, res}, 0), temp0))}});
	return res;
}
struct vat* get_vat__ptr_vat__nat(struct ctx* ctx, uint64_t vat_id) {
	return at__ptr_vat__arr__ptr_vat__nat(ctx, get_gctx__ptr_global_ctx(ctx)->vats, vat_id);
}
struct vat* at__ptr_vat__arr__ptr_vat__nat(struct ctx* ctx, struct arr__ptr_vat a, uint64_t index) {
	assert___void__bool(ctx, _op_less__bool__nat__nat(index, a.size));
	return noctx_at__ptr_vat__arr__ptr_vat__nat(a, index);
}
uint8_t assert___void__bool(struct ctx* ctx, uint8_t condition) {
	return assert___void__bool__arr__char(ctx, condition, (struct arr__char) {13, "assert failed"});
}
uint8_t assert___void__bool__arr__char(struct ctx* ctx, uint8_t condition, struct arr__char message) {
	if (condition) {
		return 0;
	} else {
		return fail___void__arr__char(ctx, message);
	}
}
uint8_t fail___void__arr__char(struct ctx* ctx, struct arr__char reason) {
	return throw___void__exception(ctx, (struct exception) {reason});
}
uint8_t throw___void__exception(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx;
	exn_ctx = get_exception_ctx__ptr_exception_ctx(ctx);
	hard_forbid___void__bool(_op_equal_equal__bool__ptr__jmp_buf_tag__ptr__jmp_buf_tag(exn_ctx->jmp_buf_ptr, NULL));
	(exn_ctx->thrown_exception = e, 0);
	(longjmp(exn_ctx->jmp_buf_ptr, number_to_throw__int32(ctx)), 0);
	return todo___void();
}
struct exception_ctx* get_exception_ctx__ptr_exception_ctx(struct ctx* ctx) {
	return (struct exception_ctx*) ctx->exception_ctx_ptr;
}
uint8_t _op_equal_equal__bool__ptr__jmp_buf_tag__ptr__jmp_buf_tag(struct jmp_buf_tag* a, struct jmp_buf_tag* b) {
	struct comparison matched;
	matched = _op_less_equal_greater__comparison__ptr__jmp_buf_tag__ptr__jmp_buf_tag(a, b);
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
struct comparison _op_less_equal_greater__comparison__ptr__jmp_buf_tag__ptr__jmp_buf_tag(struct jmp_buf_tag* a, struct jmp_buf_tag* b) {
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
int32_t number_to_throw__int32(struct ctx* ctx) {
	return seven__int32();
}
int32_t seven__int32() {
	return wrap_incr__int32__int32(six__int32());
}
int32_t six__int32() {
	return wrap_incr__int32__int32(five__int32());
}
int32_t five__int32() {
	return wrap_incr__int32__int32(four__int32());
}
int32_t four__int32() {
	return wrap_incr__int32__int32(three__int32());
}
int32_t three__int32() {
	return wrap_incr__int32__int32(two__int32());
}
struct vat* noctx_at__ptr_vat__arr__ptr_vat__nat(struct arr__ptr_vat a, uint64_t index) {
	hard_assert___void__bool(_op_less__bool__nat__nat(index, a.size));
	return (*((a.data + index)));
}
uint8_t add_task___void__ptr_vat__task(struct ctx* ctx, struct vat* v, struct task t) {
	struct mut_bag_node__task* node;
	node = new_mut_bag_node__ptr_mut_bag_node__task__task(ctx, t);
	acquire_lock___void__ptr_lock((&(v->tasks_lock)));
	add___void__ptr_mut_bag__task__ptr_mut_bag_node__task((&(v->tasks)), node);
	release_lock___void__ptr_lock((&(v->tasks_lock)));
	return broadcast___void__ptr_condition((&(v->gctx->may_be_work_to_do)));
}
struct mut_bag_node__task* new_mut_bag_node__ptr_mut_bag_node__task__task(struct ctx* ctx, struct task value) {
	struct mut_bag_node__task* temp0;
	temp0 = (struct mut_bag_node__task*) alloc__ptr__byte__nat(ctx, sizeof(struct mut_bag_node__task));
	(*(temp0) = (struct mut_bag_node__task) {value, (struct opt__ptr_mut_bag_node__task) {0, .as0 = none__none()}}, 0);
	return temp0;
}
uint8_t add___void__ptr_mut_bag__task__ptr_mut_bag_node__task(struct mut_bag__task* bag, struct mut_bag_node__task* node) {
	(node->next_node = bag->head, 0);
	return (bag->head = (struct opt__ptr_mut_bag_node__task) {1, .as1 = some__some__ptr_mut_bag_node__task__ptr_mut_bag_node__task(node)}, 0);
}
struct some__ptr_mut_bag_node__task some__some__ptr_mut_bag_node__task__ptr_mut_bag_node__task(struct mut_bag_node__task* t) {
	return (struct some__ptr_mut_bag_node__task) {t};
}
uint8_t broadcast___void__ptr_condition(struct condition* c) {
	acquire_lock___void__ptr_lock((&(c->lk)));
	(c->value = noctx_incr__nat__nat(c->value), 0);
	return release_lock___void__ptr_lock((&(c->lk)));
}
uint8_t catch___void__fun_mut0___void__fun_mut1___void__exception(struct ctx* ctx, struct fun_mut0___void try, struct fun_mut1___void__exception catcher) {
	return catch_with_exception_ctx___void__ptr_exception_ctx__fun_mut0___void__fun_mut1___void__exception(ctx, get_exception_ctx__ptr_exception_ctx(ctx), try, catcher);
}
uint8_t catch_with_exception_ctx___void__ptr_exception_ctx__fun_mut0___void__fun_mut1___void__exception(struct ctx* ctx, struct exception_ctx* ec, struct fun_mut0___void try, struct fun_mut1___void__exception catcher) {
	struct exception old_thrown_exception;
	struct jmp_buf_tag* old_jmp_buf;
	struct jmp_buf_tag store;
	int32_t setjmp_result;
	uint8_t res;
	struct exception thrown_exception;
	old_thrown_exception = ec->thrown_exception;
	old_jmp_buf = ec->jmp_buf_ptr;
	store = (struct jmp_buf_tag) {zero__bytes64(), 0, zero__bytes128()};
	(ec->jmp_buf_ptr = (&(store)), 0);
	setjmp_result = setjmp(ec->jmp_buf_ptr);
	if (_op_equal_equal__bool__int32__int32(setjmp_result, 0)) {
		res = call___void__fun_mut0___void(ctx, try);
		(ec->jmp_buf_ptr = old_jmp_buf, 0);
		(ec->thrown_exception = old_thrown_exception, 0);
		return res;
	} else {
		assert___void__bool(ctx, _op_equal_equal__bool__int32__int32(setjmp_result, number_to_throw__int32(ctx)));
		thrown_exception = ec->thrown_exception;
		(ec->jmp_buf_ptr = old_jmp_buf, 0);
		(ec->thrown_exception = old_thrown_exception, 0);
		return call___void__fun_mut1___void__exception__exception(ctx, catcher, thrown_exception);
	}
}
struct bytes64 zero__bytes64() {
	return (struct bytes64) {zero__bytes32(), zero__bytes32()};
}
struct bytes32 zero__bytes32() {
	return (struct bytes32) {zero__bytes16(), zero__bytes16()};
}
struct bytes16 zero__bytes16() {
	return (struct bytes16) {0, 0};
}
struct bytes128 zero__bytes128() {
	return (struct bytes128) {zero__bytes64(), zero__bytes64()};
}
uint8_t call___void__fun_mut0___void(struct ctx* ctx, struct fun_mut0___void f) {
	return call_with_ctx___void__ptr_ctx__fun_mut0___void(ctx, f);
}
uint8_t call_with_ctx___void__ptr_ctx__fun_mut0___void(struct ctx* c, struct fun_mut0___void f) {
	return f.fun_ptr(c, f.closure);
}
uint8_t call___void__fun_mut1___void__exception__exception(struct ctx* ctx, struct fun_mut1___void__exception f, struct exception p0) {
	return call_with_ctx___void__ptr_ctx__fun_mut1___void__exception__exception(ctx, f, p0);
}
uint8_t call_with_ctx___void__ptr_ctx__fun_mut1___void__exception__exception(struct ctx* c, struct fun_mut1___void__exception f, struct exception p0) {
	return f.fun_ptr(c, f.closure, p0);
}
struct fut__int32* call__ptr_fut__int32__fun_mut1__ptr_fut__int32___void___void(struct ctx* ctx, struct fun_mut1__ptr_fut__int32___void f, uint8_t p0) {
	return call_with_ctx__ptr_fut__int32__ptr_ctx__fun_mut1__ptr_fut__int32___void___void(ctx, f, p0);
}
struct fut__int32* call_with_ctx__ptr_fut__int32__ptr_ctx__fun_mut1__ptr_fut__int32___void___void(struct ctx* c, struct fun_mut1__ptr_fut__int32___void f, uint8_t p0) {
	return f.fun_ptr(c, f.closure, p0);
}
uint8_t call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0(struct ctx* ctx, struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0___closure* _closure) {
	return forward_to___void__ptr_fut__int32__ptr_fut__int32(ctx, call__ptr_fut__int32__fun_mut1__ptr_fut__int32___void___void(ctx, _closure->f.fun, _closure->p0), _closure->res);
}
uint8_t reject___void__ptr_fut__int32__exception(struct ctx* ctx, struct fut__int32* f, struct exception e) {
	return resolve_or_reject___void__ptr_fut__int32__result__int32__exception(ctx, f, (struct result__int32__exception) {1, .as1 = err__err__exception__exception(e)});
}
uint8_t call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1(struct ctx* ctx, struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1___closure* _closure, struct exception it) {
	return reject___void__ptr_fut__int32__exception(ctx, _closure->res, it);
}
uint8_t call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0(struct ctx* ctx, struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0___closure* _closure) {
	struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0___closure* temp0;
	struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1___closure* temp1;
	return catch___void__fun_mut0___void__fun_mut1___void__exception(ctx, (struct fun_mut0___void) {(fun_ptr2___void__ptr_ctx__ptr__byte) call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0, (uint8_t*) (temp0 = (struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0___closure)), ((*(temp0) = (struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda0___closure) {_closure->f, _closure->p0, _closure->res}, 0), temp0))}, (struct fun_mut1___void__exception) {(fun_ptr3___void__ptr_ctx__ptr__byte__exception) call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1, (uint8_t*) (temp1 = (struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1___closure)), ((*(temp1) = (struct call__ptr_fut__int32__fun_ref1__int32___void___void__lambda0__lambda1___closure) {_closure->res}, 0), temp1))});
}
uint8_t then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0(struct ctx* ctx, struct then__ptr_fut__int32__ptr_fut___void__fun_ref1__int32___void__lambda0___closure* _closure, struct result___void__exception result) {
	struct ok___void o;
	struct err__exception e;
	struct result___void__exception matched;
	matched = result;
	switch (matched.kind) {
		case 0:
			o = matched.as0;
			return forward_to___void__ptr_fut__int32__ptr_fut__int32(ctx, call__ptr_fut__int32__fun_ref1__int32___void___void(ctx, _closure->cb, o.value), _closure->res);
		case 1:
			e = matched.as1;
			return reject___void__ptr_fut__int32__exception(ctx, _closure->res, e.value);
		default:
			return (assert(0),0);
	}
}
struct fut__int32* call__ptr_fut__int32__fun_ref0__int32(struct ctx* ctx, struct fun_ref0__int32 f) {
	struct vat* vat;
	struct fut__int32* res;
	struct call__ptr_fut__int32__fun_ref0__int32__lambda0___closure* temp0;
	vat = get_vat__ptr_vat__nat(ctx, f.vat_and_actor.vat);
	res = new_unresolved_fut__ptr_fut__int32(ctx);
	add_task___void__ptr_vat__task(ctx, vat, (struct task) {f.vat_and_actor.actor, (struct fun_mut0___void) {(fun_ptr2___void__ptr_ctx__ptr__byte) call__ptr_fut__int32__fun_ref0__int32__lambda0, (uint8_t*) (temp0 = (struct call__ptr_fut__int32__fun_ref0__int32__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct call__ptr_fut__int32__fun_ref0__int32__lambda0___closure)), ((*(temp0) = (struct call__ptr_fut__int32__fun_ref0__int32__lambda0___closure) {f, res}, 0), temp0))}});
	return res;
}
struct fut__int32* call__ptr_fut__int32__fun_mut0__ptr_fut__int32(struct ctx* ctx, struct fun_mut0__ptr_fut__int32 f) {
	return call_with_ctx__ptr_fut__int32__ptr_ctx__fun_mut0__ptr_fut__int32(ctx, f);
}
struct fut__int32* call_with_ctx__ptr_fut__int32__ptr_ctx__fun_mut0__ptr_fut__int32(struct ctx* c, struct fun_mut0__ptr_fut__int32 f) {
	return f.fun_ptr(c, f.closure);
}
uint8_t call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0(struct ctx* ctx, struct call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0___closure* _closure) {
	return forward_to___void__ptr_fut__int32__ptr_fut__int32(ctx, call__ptr_fut__int32__fun_mut0__ptr_fut__int32(ctx, _closure->f.fun), _closure->res);
}
uint8_t call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1(struct ctx* ctx, struct call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1___closure* _closure, struct exception it) {
	return reject___void__ptr_fut__int32__exception(ctx, _closure->res, it);
}
uint8_t call__ptr_fut__int32__fun_ref0__int32__lambda0(struct ctx* ctx, struct call__ptr_fut__int32__fun_ref0__int32__lambda0___closure* _closure) {
	struct call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0___closure* temp0;
	struct call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1___closure* temp1;
	return catch___void__fun_mut0___void__fun_mut1___void__exception(ctx, (struct fun_mut0___void) {(fun_ptr2___void__ptr_ctx__ptr__byte) call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0, (uint8_t*) (temp0 = (struct call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0___closure)), ((*(temp0) = (struct call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda0___closure) {_closure->f, _closure->res}, 0), temp0))}, (struct fun_mut1___void__exception) {(fun_ptr3___void__ptr_ctx__ptr__byte__exception) call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1, (uint8_t*) (temp1 = (struct call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1___closure)), ((*(temp1) = (struct call__ptr_fut__int32__fun_ref0__int32__lambda0__lambda1___closure) {_closure->res}, 0), temp1))});
}
struct fut__int32* then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0(struct ctx* ctx, struct then2__ptr_fut__int32__ptr_fut___void__fun_ref0__int32__lambda0___closure* _closure, uint8_t ignore) {
	return call__ptr_fut__int32__fun_ref0__int32(ctx, _closure->cb);
}
struct vat_and_actor_id cur_actor__vat_and_actor_id(struct ctx* ctx) {
	struct ctx* c;
	c = ctx;
	return (struct vat_and_actor_id) {c->vat_id, c->actor_id};
}
struct fut___void* resolved__ptr_fut___void___void(struct ctx* ctx, uint8_t value) {
	struct fut___void* temp0;
	temp0 = (struct fut___void*) alloc__ptr__byte__nat(ctx, sizeof(struct fut___void));
	(*(temp0) = (struct fut___void) {new_lock__lock(), (struct fut_state___void) {1, .as1 = (struct fut_state_resolved___void) {value}}}, 0);
	return temp0;
}
struct arr__ptr__char tail__arr__ptr__char__arr__ptr__char(struct ctx* ctx, struct arr__ptr__char a) {
	forbid___void__bool(ctx, empty__q__bool__arr__ptr__char(a));
	return slice_starting_at__arr__ptr__char__arr__ptr__char__nat(ctx, a, 1);
}
uint8_t forbid___void__bool(struct ctx* ctx, uint8_t condition) {
	return forbid___void__bool__arr__char(ctx, condition, (struct arr__char) {13, "forbid failed"});
}
uint8_t forbid___void__bool__arr__char(struct ctx* ctx, uint8_t condition, struct arr__char message) {
	if (condition) {
		return fail___void__arr__char(ctx, message);
	} else {
		return 0;
	}
}
uint8_t empty__q__bool__arr__ptr__char(struct arr__ptr__char a) {
	return zero__q__bool__nat(a.size);
}
struct arr__ptr__char slice_starting_at__arr__ptr__char__arr__ptr__char__nat(struct ctx* ctx, struct arr__ptr__char a, uint64_t begin) {
	assert___void__bool(ctx, _op_less_equal__bool__nat__nat(begin, a.size));
	return slice__arr__ptr__char__arr__ptr__char__nat__nat(ctx, a, begin, _op_minus__nat__nat__nat(ctx, a.size, begin));
}
uint8_t _op_less_equal__bool__nat__nat(uint64_t a, uint64_t b) {
	return !_op_less__bool__nat__nat(b, a);
}
struct arr__ptr__char slice__arr__ptr__char__arr__ptr__char__nat__nat(struct ctx* ctx, struct arr__ptr__char a, uint64_t begin, uint64_t size) {
	assert___void__bool(ctx, _op_less_equal__bool__nat__nat(_op_plus__nat__nat__nat(ctx, begin, size), a.size));
	return (struct arr__ptr__char) {size, (a.data + begin)};
}
uint64_t _op_plus__nat__nat__nat(struct ctx* ctx, uint64_t a, uint64_t b) {
	uint64_t res;
	res = (a + b);
	assert___void__bool(ctx, (_op_greater_equal__bool__nat__nat(res, a) && _op_greater_equal__bool__nat__nat(res, b)));
	return res;
}
uint8_t _op_greater_equal__bool__nat__nat(uint64_t a, uint64_t b) {
	return !_op_less__bool__nat__nat(a, b);
}
uint64_t _op_minus__nat__nat__nat(struct ctx* ctx, uint64_t a, uint64_t b) {
	assert___void__bool(ctx, _op_greater_equal__bool__nat__nat(a, b));
	return (a - b);
}
struct arr__arr__char map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char(struct ctx* ctx, struct arr__ptr__char a, struct fun_mut1__arr__char__ptr__char mapper) {
	struct map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0___closure* temp0;
	return make_arr__arr__arr__char__nat__fun_mut1__arr__char__nat(ctx, a.size, (struct fun_mut1__arr__char__nat) {(fun_ptr3__arr__char__ptr_ctx__ptr__byte__nat) map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0, (uint8_t*) (temp0 = (struct map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0___closure)), ((*(temp0) = (struct map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0___closure) {mapper, a}, 0), temp0))});
}
struct arr__arr__char make_arr__arr__arr__char__nat__fun_mut1__arr__char__nat(struct ctx* ctx, uint64_t size, struct fun_mut1__arr__char__nat f) {
	return freeze__arr__arr__char__ptr_mut_arr__arr__char(make_mut_arr__ptr_mut_arr__arr__char__nat__fun_mut1__arr__char__nat(ctx, size, f));
}
struct arr__arr__char freeze__arr__arr__char__ptr_mut_arr__arr__char(struct mut_arr__arr__char* a) {
	(a->frozen__q = 1, 0);
	return unsafe_as_arr__arr__arr__char__ptr_mut_arr__arr__char(a);
}
struct arr__arr__char unsafe_as_arr__arr__arr__char__ptr_mut_arr__arr__char(struct mut_arr__arr__char* a) {
	return (struct arr__arr__char) {a->size, a->data};
}
struct mut_arr__arr__char* make_mut_arr__ptr_mut_arr__arr__char__nat__fun_mut1__arr__char__nat(struct ctx* ctx, uint64_t size, struct fun_mut1__arr__char__nat f) {
	struct mut_arr__arr__char* res;
	res = new_uninitialized_mut_arr__ptr_mut_arr__arr__char__nat(ctx, size);
	make_mut_arr_worker___void__ptr_mut_arr__arr__char__nat__fun_mut1__arr__char__nat(ctx, res, 0, f);
	return res;
}
struct mut_arr__arr__char* new_uninitialized_mut_arr__ptr_mut_arr__arr__char__nat(struct ctx* ctx, uint64_t size) {
	struct mut_arr__arr__char* temp0;
	temp0 = (struct mut_arr__arr__char*) alloc__ptr__byte__nat(ctx, sizeof(struct mut_arr__arr__char));
	(*(temp0) = (struct mut_arr__arr__char) {0, size, size, uninitialized_data__ptr__arr__char__nat(ctx, size)}, 0);
	return temp0;
}
struct arr__char* uninitialized_data__ptr__arr__char__nat(struct ctx* ctx, uint64_t size) {
	uint8_t* bptr;
	bptr = alloc__ptr__byte__nat(ctx, (size * sizeof(struct arr__char)));
	return (struct arr__char*) bptr;
}
uint8_t make_mut_arr_worker___void__ptr_mut_arr__arr__char__nat__fun_mut1__arr__char__nat(struct ctx* ctx, struct mut_arr__arr__char* m, uint64_t i, struct fun_mut1__arr__char__nat f) {
	struct ctx* _tailCallctx;
	struct mut_arr__arr__char* _tailCallm;
	uint64_t _tailCalli;
	struct fun_mut1__arr__char__nat _tailCallf;
	top:
	if (_op_equal_equal__bool__nat__nat(i, m->size)) {
		return 0;
	} else {
		set_at___void__ptr_mut_arr__arr__char__nat__arr__char(ctx, m, i, call__arr__char__fun_mut1__arr__char__nat__nat(ctx, f, i));
		_tailCallctx = ctx;
		_tailCallm = m;
		_tailCalli = incr__nat__nat(ctx, i);
		_tailCallf = f;
		ctx = _tailCallctx;
		m = _tailCallm;
		i = _tailCalli;
		f = _tailCallf;
		goto top;
	}
}
uint8_t set_at___void__ptr_mut_arr__arr__char__nat__arr__char(struct ctx* ctx, struct mut_arr__arr__char* a, uint64_t index, struct arr__char value) {
	assert___void__bool(ctx, _op_less__bool__nat__nat(index, a->size));
	return noctx_set_at___void__ptr_mut_arr__arr__char__nat__arr__char(a, index, value);
}
uint8_t noctx_set_at___void__ptr_mut_arr__arr__char__nat__arr__char(struct mut_arr__arr__char* a, uint64_t index, struct arr__char value) {
	hard_assert___void__bool(_op_less__bool__nat__nat(index, a->size));
	return (*((a->data + index)) = value, 0);
}
struct arr__char call__arr__char__fun_mut1__arr__char__nat__nat(struct ctx* ctx, struct fun_mut1__arr__char__nat f, uint64_t p0) {
	return call_with_ctx__arr__char__ptr_ctx__fun_mut1__arr__char__nat__nat(ctx, f, p0);
}
struct arr__char call_with_ctx__arr__char__ptr_ctx__fun_mut1__arr__char__nat__nat(struct ctx* c, struct fun_mut1__arr__char__nat f, uint64_t p0) {
	return f.fun_ptr(c, f.closure, p0);
}
uint64_t incr__nat__nat(struct ctx* ctx, uint64_t n) {
	assert___void__bool(ctx, _op_less__bool__nat__nat(n, billion__nat()));
	return (n + 1);
}
struct arr__char call__arr__char__fun_mut1__arr__char__ptr__char__ptr__char(struct ctx* ctx, struct fun_mut1__arr__char__ptr__char f, char* p0) {
	return call_with_ctx__arr__char__ptr_ctx__fun_mut1__arr__char__ptr__char__ptr__char(ctx, f, p0);
}
struct arr__char call_with_ctx__arr__char__ptr_ctx__fun_mut1__arr__char__ptr__char__ptr__char(struct ctx* c, struct fun_mut1__arr__char__ptr__char f, char* p0) {
	return f.fun_ptr(c, f.closure, p0);
}
char* at__ptr__char__arr__ptr__char__nat(struct ctx* ctx, struct arr__ptr__char a, uint64_t index) {
	assert___void__bool(ctx, _op_less__bool__nat__nat(index, a.size));
	return noctx_at__ptr__char__arr__ptr__char__nat(a, index);
}
char* noctx_at__ptr__char__arr__ptr__char__nat(struct arr__ptr__char a, uint64_t index) {
	hard_assert___void__bool(_op_less__bool__nat__nat(index, a.size));
	return (*((a.data + index)));
}
struct arr__char map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0(struct ctx* ctx, struct map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char__lambda0___closure* _closure, uint64_t i) {
	return call__arr__char__fun_mut1__arr__char__ptr__char__ptr__char(ctx, _closure->mapper, at__ptr__char__arr__ptr__char__nat(ctx, _closure->a, i));
}
struct arr__char to_str__arr__char__ptr__char(char* a) {
	return arr_from_begin_end__arr__char__ptr__char__ptr__char(a, find_cstr_end__ptr__char__ptr__char(a));
}
struct arr__char arr_from_begin_end__arr__char__ptr__char__ptr__char(char* begin, char* end) {
	return (struct arr__char) {_op_minus__nat__ptr__char__ptr__char(end, begin), begin};
}
uint64_t _op_minus__nat__ptr__char__ptr__char(char* a, char* b) {
	return (a - b);
}
char* find_cstr_end__ptr__char__ptr__char(char* a) {
	return find_char_in_cstr__ptr__char__ptr__char__char(a, literal__char__arr__char((struct arr__char) {1, "\0"}));
}
char* find_char_in_cstr__ptr__char__ptr__char__char(char* a, char c) {
	char* _tailCalla;
	char _tailCallc;
	top:
	if (_op_equal_equal__bool__char__char((*(a)), c)) {
		return a;
	} else {
		if (_op_equal_equal__bool__char__char((*(a)), literal__char__arr__char((struct arr__char) {1, "\0"}))) {
			return todo__ptr__char();
		} else {
			_tailCalla = incr__ptr__char__ptr__char(a);
			_tailCallc = c;
			a = _tailCalla;
			c = _tailCallc;
			goto top;
		}
	}
}
uint8_t _op_equal_equal__bool__char__char(char a, char b) {
	struct comparison matched;
	matched = _op_less_equal_greater__comparison__char__char(a, b);
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
struct comparison _op_less_equal_greater__comparison__char__char(char a, char b) {
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
char literal__char__arr__char(struct arr__char a) {
	return noctx_at__char__arr__char__nat(a, 0);
}
char noctx_at__char__arr__char__nat(struct arr__char a, uint64_t index) {
	hard_assert___void__bool(_op_less__bool__nat__nat(index, a.size));
	return (*((a.data + index)));
}
char* todo__ptr__char() {
	return (assert(0),NULL);
}
char* incr__ptr__char__ptr__char(char* p) {
	return (p + 1);
}
struct arr__char add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0__lambda0(struct ctx* ctx, uint8_t* _closure, char* it) {
	return to_str__arr__char__ptr__char(it);
}
struct fut__int32* add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0(struct ctx* ctx, struct add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0___closure* _closure) {
	struct arr__ptr__char args;
	args = tail__arr__ptr__char__arr__ptr__char(ctx, _closure->all_args);
	return _closure->main_ptr(ctx, map__arr__arr__char__arr__ptr__char__fun_mut1__arr__char__ptr__char(ctx, args, (struct fun_mut1__arr__char__ptr__char) {(fun_ptr3__arr__char__ptr_ctx__ptr__byte__ptr__char) add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0__lambda0, (uint8_t*) NULL}));
}
struct fut__int32* rt_main__int32__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr__ptr__char all_args, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char main_ptr) {
	return add_first_task__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(ctx, all_args, main_ptr);
}
struct fut__int32* call_with_ctx__ptr_fut__int32__ptr_ctx__fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(struct ctx* c, struct fun2__ptr_fut__int32__arr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char f, struct arr__ptr__char p0, fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char p1) {
	return f.fun_ptr(c, f.closure, p0, p1);
}
uint8_t run_threads___void__nat__ptr_global_ctx__fun_ptr2___void__nat__ptr_global_ctx(uint64_t n_threads, struct global_ctx* arg, fun_ptr2___void__nat__ptr_global_ctx fun) {
	uint64_t* threads;
	struct thread_args__ptr_global_ctx* thread_args;
	threads = unmanaged_alloc_elements__ptr__nat__nat(n_threads);
	thread_args = unmanaged_alloc_elements__ptr__thread_args__ptr_global_ctx__nat(n_threads);
	run_threads_recur___void__nat__nat__ptr__nat__ptr__thread_args__ptr_global_ctx__ptr_global_ctx__fun_ptr2___void__nat__ptr_global_ctx(0, n_threads, threads, thread_args, arg, fun);
	join_threads_recur___void__nat__nat__ptr__nat(0, n_threads, threads);
	unmanaged_free___void__ptr__nat(threads);
	return unmanaged_free___void__ptr__thread_args__ptr_global_ctx(thread_args);
}
struct thread_args__ptr_global_ctx* unmanaged_alloc_elements__ptr__thread_args__ptr_global_ctx__nat(uint64_t size_elements) {
	uint8_t* bytes;
	bytes = unmanaged_alloc_bytes__ptr__byte__nat((size_elements * sizeof(struct thread_args__ptr_global_ctx)));
	return (struct thread_args__ptr_global_ctx*) bytes;
}
uint8_t run_threads_recur___void__nat__nat__ptr__nat__ptr__thread_args__ptr_global_ctx__ptr_global_ctx__fun_ptr2___void__nat__ptr_global_ctx(uint64_t i, uint64_t n_threads, uint64_t* threads, struct thread_args__ptr_global_ctx* thread_args, struct global_ctx* arg, fun_ptr2___void__nat__ptr_global_ctx fun) {
	struct thread_args__ptr_global_ctx* thread_arg_ptr;
	uint64_t* thread_ptr;
	fun_ptr1__ptr__byte__ptr__byte fn;
	int32_t err;
	uint64_t _tailCalli;
	uint64_t _tailCalln_threads;
	uint64_t* _tailCallthreads;
	struct thread_args__ptr_global_ctx* _tailCallthread_args;
	struct global_ctx* _tailCallarg;
	fun_ptr2___void__nat__ptr_global_ctx _tailCallfun;
	top:
	if (_op_equal_equal__bool__nat__nat(i, n_threads)) {
		return 0;
	} else {
		thread_arg_ptr = (thread_args + i);
		(*(thread_arg_ptr) = (struct thread_args__ptr_global_ctx) {fun, i, arg}, 0);
		thread_ptr = (threads + i);
		fn = run_threads_recur___void__nat__nat__ptr__nat__ptr__thread_args__ptr_global_ctx__ptr_global_ctx__fun_ptr2___void__nat__ptr_global_ctx__lambda0;
		err = pthread_create(as_cell__ptr_cell__nat__ptr__nat(thread_ptr), NULL, fn, (uint8_t*) thread_arg_ptr);
		if (zero__q__bool__int32(err)) {
			_tailCalli = noctx_incr__nat__nat(i);
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
			if (_op_equal_equal__bool__int32__int32(err, eagain__int32())) {
				return todo___void();
			} else {
				return todo___void();
			}
		}
	}
}
uint8_t* thread_fun__ptr__byte__ptr__byte(uint8_t* args_ptr) {
	struct thread_args__ptr_global_ctx* args;
	args = (struct thread_args__ptr_global_ctx*) args_ptr;
	args->fun(args->thread_id, args->arg);
	return NULL;
}
uint8_t* run_threads_recur___void__nat__nat__ptr__nat__ptr__thread_args__ptr_global_ctx__ptr_global_ctx__fun_ptr2___void__nat__ptr_global_ctx__lambda0(uint8_t* args_ptr) {
	return thread_fun__ptr__byte__ptr__byte(args_ptr);
}
struct cell__nat* as_cell__ptr_cell__nat__ptr__nat(uint64_t* p) {
	return (struct cell__nat*) (uint8_t*) p;
}
int32_t eagain__int32() {
	return (ten__int32() + 1);
}
int32_t ten__int32() {
	return wrap_incr__int32__int32(nine__int32());
}
int32_t nine__int32() {
	return wrap_incr__int32__int32(eight__int32());
}
int32_t eight__int32() {
	return (four__int32() + four__int32());
}
uint8_t join_threads_recur___void__nat__nat__ptr__nat(uint64_t i, uint64_t n_threads, uint64_t* threads) {
	uint64_t _tailCalli;
	uint64_t _tailCalln_threads;
	uint64_t* _tailCallthreads;
	top:
	if (_op_equal_equal__bool__nat__nat(i, n_threads)) {
		return 0;
	} else {
		join_one_thread___void__nat((*((threads + i))));
		_tailCalli = noctx_incr__nat__nat(i);
		_tailCalln_threads = n_threads;
		_tailCallthreads = threads;
		i = _tailCalli;
		n_threads = _tailCalln_threads;
		threads = _tailCallthreads;
		goto top;
	}
}
uint8_t join_one_thread___void__nat(uint64_t tid) {
	struct cell__ptr__byte thread_return;
	int32_t err;
	thread_return = (struct cell__ptr__byte) {NULL};
	err = pthread_join(tid, (&(thread_return)));
	if (zero__q__bool__int32(err)) {
		0;
	} else {
		if (_op_equal_equal__bool__int32__int32(err, einval__int32())) {
			todo___void();
		} else {
			if (_op_equal_equal__bool__int32__int32(err, esrch__int32())) {
				todo___void();
			} else {
				todo___void();
			}
		}
	}
	return hard_assert___void__bool(_op_equal_equal__bool__ptr__byte__ptr__byte(get__ptr__byte__ptr_cell__ptr__byte((&(thread_return))), NULL));
}
int32_t einval__int32() {
	return ((ten__int32() + ten__int32()) + two__int32());
}
int32_t esrch__int32() {
	return three__int32();
}
uint8_t* get__ptr__byte__ptr_cell__ptr__byte(struct cell__ptr__byte* c) {
	return c->value;
}
uint8_t unmanaged_free___void__ptr__nat(uint64_t* p) {
	return (free((uint8_t*) p), 0);
}
uint8_t unmanaged_free___void__ptr__thread_args__ptr_global_ctx(struct thread_args__ptr_global_ctx* p) {
	return (free((uint8_t*) p), 0);
}
uint8_t thread_function___void__nat__ptr_global_ctx(uint64_t thread_id, struct global_ctx* gctx) {
	struct exception_ctx ectx;
	struct thread_local_stuff tls;
	ectx = new_exception_ctx__exception_ctx();
	tls = (struct thread_local_stuff) {(&(ectx))};
	return thread_function_recur___void__nat__ptr_global_ctx__ptr_thread_local_stuff(thread_id, gctx, (&(tls)));
}
uint8_t thread_function_recur___void__nat__ptr_global_ctx__ptr_thread_local_stuff(uint64_t thread_id, struct global_ctx* gctx, struct thread_local_stuff* tls) {
	uint64_t last_checked;
	struct ok__chosen_task ok_chosen_task;
	struct err__no_chosen_task e;
	struct result__chosen_task__no_chosen_task matched;
	uint64_t _tailCallthread_id;
	struct global_ctx* _tailCallgctx;
	struct thread_local_stuff* _tailCalltls;
	top:
	if (gctx->is_shut_down) {
		acquire_lock___void__ptr_lock((&(gctx->lk)));
		(gctx->n_live_threads = noctx_decr__nat__nat(gctx->n_live_threads), 0);
		assert_vats_are_shut_down___void__nat__arr__ptr_vat(0, gctx->vats);
		return release_lock___void__ptr_lock((&(gctx->lk)));
	} else {
		hard_assert___void__bool(_op_greater__bool__nat__nat(gctx->n_live_threads, 0));
		last_checked = get_last_checked__nat__ptr_condition((&(gctx->may_be_work_to_do)));
		matched = choose_task__result__chosen_task__no_chosen_task__ptr_global_ctx(gctx);
		switch (matched.kind) {
			case 0:
				ok_chosen_task = matched.as0;
				do_task___void__ptr_global_ctx__ptr_thread_local_stuff__chosen_task(gctx, tls, ok_chosen_task.value);
				break;
			case 1:
				e = matched.as1;
				if (e.value.last_thread_out) {
					hard_forbid___void__bool(gctx->is_shut_down);
					(gctx->is_shut_down = 1, 0);
					broadcast___void__ptr_condition((&(gctx->may_be_work_to_do)));
				} else {
					wait_on___void__ptr_condition__nat((&(gctx->may_be_work_to_do)), last_checked);
				}
				acquire_lock___void__ptr_lock((&(gctx->lk)));
				(gctx->n_live_threads = noctx_incr__nat__nat(gctx->n_live_threads), 0);
				release_lock___void__ptr_lock((&(gctx->lk)));
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
uint64_t noctx_decr__nat__nat(uint64_t n) {
	hard_forbid___void__bool(zero__q__bool__nat(n));
	return (n - 1);
}
uint8_t assert_vats_are_shut_down___void__nat__arr__ptr_vat(uint64_t i, struct arr__ptr_vat vats) {
	struct vat* vat;
	uint64_t _tailCalli;
	struct arr__ptr_vat _tailCallvats;
	top:
	if (_op_equal_equal__bool__nat__nat(i, vats.size)) {
		return 0;
	} else {
		vat = noctx_at__ptr_vat__arr__ptr_vat__nat(vats, i);
		acquire_lock___void__ptr_lock((&(vat->tasks_lock)));
		hard_forbid___void__bool((&(vat->gc))->needs_gc);
		hard_assert___void__bool(zero__q__bool__nat(vat->n_threads_running));
		hard_assert___void__bool(empty__q__bool__ptr_mut_bag__task((&(vat->tasks))));
		release_lock___void__ptr_lock((&(vat->tasks_lock)));
		_tailCalli = noctx_incr__nat__nat(i);
		_tailCallvats = vats;
		i = _tailCalli;
		vats = _tailCallvats;
		goto top;
	}
}
uint8_t empty__q__bool__ptr_mut_bag__task(struct mut_bag__task* m) {
	return empty__q__bool__opt__ptr_mut_bag_node__task(m->head);
}
uint8_t empty__q__bool__opt__ptr_mut_bag_node__task(struct opt__ptr_mut_bag_node__task a) {
	struct none n;
	struct some__ptr_mut_bag_node__task s;
	struct opt__ptr_mut_bag_node__task matched;
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
uint8_t _op_greater__bool__nat__nat(uint64_t a, uint64_t b) {
	return !_op_less_equal__bool__nat__nat(a, b);
}
uint64_t get_last_checked__nat__ptr_condition(struct condition* c) {
	return c->value;
}
struct result__chosen_task__no_chosen_task choose_task__result__chosen_task__no_chosen_task__ptr_global_ctx(struct global_ctx* gctx) {
	struct some__chosen_task s;
	struct opt__chosen_task matched;
	struct result__chosen_task__no_chosen_task res;
	acquire_lock___void__ptr_lock((&(gctx->lk)));
	res = (matched = choose_task_recur__opt__chosen_task__arr__ptr_vat__nat(gctx->vats, 0), matched.kind == 0 ? ((gctx->n_live_threads = noctx_decr__nat__nat(gctx->n_live_threads), 0), (struct result__chosen_task__no_chosen_task) {1, .as1 = err__err__no_chosen_task__no_chosen_task((struct no_chosen_task) {zero__q__bool__nat(gctx->n_live_threads)})}) : matched.kind == 1 ? (s = matched.as1, (struct result__chosen_task__no_chosen_task) {0, .as0 = ok__ok__chosen_task__chosen_task(s.value)}) : (assert(0),(struct result__chosen_task__no_chosen_task) {0}));
	release_lock___void__ptr_lock((&(gctx->lk)));
	return res;
}
struct opt__chosen_task choose_task_recur__opt__chosen_task__arr__ptr_vat__nat(struct arr__ptr_vat vats, uint64_t i) {
	struct vat* vat;
	struct some__opt__task s;
	struct opt__opt__task matched;
	struct arr__ptr_vat _tailCallvats;
	uint64_t _tailCalli;
	top:
	if (_op_equal_equal__bool__nat__nat(i, vats.size)) {
		return (struct opt__chosen_task) {0, .as0 = none__none()};
	} else {
		vat = noctx_at__ptr_vat__arr__ptr_vat__nat(vats, i);
		matched = choose_task_in_vat__opt__opt__task__ptr_vat(vat);
		switch (matched.kind) {
			case 0:
				_tailCallvats = vats;
				_tailCalli = noctx_incr__nat__nat(i);
				vats = _tailCallvats;
				i = _tailCalli;
				goto top;
			case 1:
				s = matched.as1;
				return (struct opt__chosen_task) {1, .as1 = some__some__chosen_task__chosen_task((struct chosen_task) {vat, s.value})};
			default:
				return (assert(0),(struct opt__chosen_task) {0});
		}
	}
}
struct opt__opt__task choose_task_in_vat__opt__opt__task__ptr_vat(struct vat* vat) {
	struct some__task s;
	struct opt__task matched;
	struct opt__opt__task res;
	acquire_lock___void__ptr_lock((&(vat->tasks_lock)));
	res = ((&(vat->gc))->needs_gc ? (zero__q__bool__nat(vat->n_threads_running) ? (struct opt__opt__task) {1, .as1 = some__some__opt__task__opt__task((struct opt__task) {0, .as0 = none__none()})} : (struct opt__opt__task) {0, .as0 = none__none()}) : (matched = find_and_remove_first_doable_task__opt__task__ptr_vat(vat), matched.kind == 0 ? (struct opt__opt__task) {0, .as0 = none__none()} : matched.kind == 1 ? (s = matched.as1, (struct opt__opt__task) {1, .as1 = some__some__opt__task__opt__task((struct opt__task) {1, .as1 = some__some__task__task(s.value)})}) : (assert(0),(struct opt__opt__task) {0})));
	if (empty__q__bool__opt__opt__task(res)) {
		0;
	} else {
		(vat->n_threads_running = noctx_incr__nat__nat(vat->n_threads_running), 0);
	}
	release_lock___void__ptr_lock((&(vat->tasks_lock)));
	return res;
}
struct some__opt__task some__some__opt__task__opt__task(struct opt__task t) {
	return (struct some__opt__task) {t};
}
struct opt__task find_and_remove_first_doable_task__opt__task__ptr_vat(struct vat* vat) {
	struct mut_bag__task* tasks;
	struct opt__task_and_nodes res;
	struct some__task_and_nodes s;
	struct opt__task_and_nodes matched;
	tasks = (&(vat->tasks));
	res = find_and_remove_first_doable_task_recur__opt__task_and_nodes__ptr_vat__opt__ptr_mut_bag_node__task(vat, tasks->head);
	matched = res;
	switch (matched.kind) {
		case 0:
			return (struct opt__task) {0, .as0 = none__none()};
		case 1:
			s = matched.as1;
			(tasks->head = s.value.nodes, 0);
			return (struct opt__task) {1, .as1 = some__some__task__task(s.value.task)};
		default:
			return (assert(0),(struct opt__task) {0});
	}
}
struct opt__task_and_nodes find_and_remove_first_doable_task_recur__opt__task_and_nodes__ptr_vat__opt__ptr_mut_bag_node__task(struct vat* vat, struct opt__ptr_mut_bag_node__task opt_node) {
	struct some__ptr_mut_bag_node__task s;
	struct mut_bag_node__task* node;
	struct task task;
	struct mut_arr__nat* actors;
	uint8_t task_ok;
	struct some__task_and_nodes ss;
	struct task_and_nodes tn;
	struct opt__task_and_nodes matched;
	struct opt__ptr_mut_bag_node__task matched1;
	matched1 = opt_node;
	switch (matched1.kind) {
		case 0:
			return (struct opt__task_and_nodes) {0, .as0 = none__none()};
		case 1:
			s = matched1.as1;
			node = s.value;
			task = node->value;
			actors = (&(vat->currently_running_actors));
			task_ok = (contains__q__bool__ptr_mut_arr__nat__nat(actors, task.actor_id) ? 0 : (push_capacity_must_be_sufficient___void__ptr_mut_arr__nat__nat(actors, task.actor_id), 1));
			if (task_ok) {
				return (struct opt__task_and_nodes) {1, .as1 = some__some__task_and_nodes__task_and_nodes((struct task_and_nodes) {task, node->next_node})};
			} else {
				matched = find_and_remove_first_doable_task_recur__opt__task_and_nodes__ptr_vat__opt__ptr_mut_bag_node__task(vat, node->next_node);
				switch (matched.kind) {
					case 0:
						return (struct opt__task_and_nodes) {0, .as0 = none__none()};
					case 1:
						ss = matched.as1;
						tn = ss.value;
						(node->next_node = tn.nodes, 0);
						return (struct opt__task_and_nodes) {1, .as1 = some__some__task_and_nodes__task_and_nodes((struct task_and_nodes) {tn.task, (struct opt__ptr_mut_bag_node__task) {1, .as1 = some__some__ptr_mut_bag_node__task__ptr_mut_bag_node__task(node)}})};
					default:
						return (assert(0),(struct opt__task_and_nodes) {0});
				}
			}
		default:
			return (assert(0),(struct opt__task_and_nodes) {0});
	}
}
uint8_t contains__q__bool__ptr_mut_arr__nat__nat(struct mut_arr__nat* a, uint64_t value) {
	return contains_recur__q__bool__arr__nat__nat__nat(temp_as_arr__arr__nat__ptr_mut_arr__nat(a), value, 0);
}
uint8_t contains_recur__q__bool__arr__nat__nat__nat(struct arr__nat a, uint64_t value, uint64_t i) {
	struct arr__nat _tailCalla;
	uint64_t _tailCallvalue;
	uint64_t _tailCalli;
	top:
	if (_op_equal_equal__bool__nat__nat(i, a.size)) {
		return 0;
	} else {
		if (_op_equal_equal__bool__nat__nat(noctx_at__nat__arr__nat__nat(a, i), value)) {
			return 1;
		} else {
			_tailCalla = a;
			_tailCallvalue = value;
			_tailCalli = noctx_incr__nat__nat(i);
			a = _tailCalla;
			value = _tailCallvalue;
			i = _tailCalli;
			goto top;
		}
	}
}
uint64_t noctx_at__nat__arr__nat__nat(struct arr__nat a, uint64_t index) {
	hard_assert___void__bool(_op_less__bool__nat__nat(index, a.size));
	return (*((a.data + index)));
}
struct arr__nat temp_as_arr__arr__nat__ptr_mut_arr__nat(struct mut_arr__nat* a) {
	return (struct arr__nat) {a->size, a->data};
}
uint8_t push_capacity_must_be_sufficient___void__ptr_mut_arr__nat__nat(struct mut_arr__nat* a, uint64_t value) {
	uint64_t old_size;
	hard_assert___void__bool(_op_less__bool__nat__nat(a->size, a->capacity));
	old_size = a->size;
	(a->size = noctx_incr__nat__nat(old_size), 0);
	return noctx_set_at___void__ptr_mut_arr__nat__nat__nat(a, old_size, value);
}
uint8_t noctx_set_at___void__ptr_mut_arr__nat__nat__nat(struct mut_arr__nat* a, uint64_t index, uint64_t value) {
	hard_assert___void__bool(_op_less__bool__nat__nat(index, a->size));
	return (*((a->data + index)) = value, 0);
}
struct some__task_and_nodes some__some__task_and_nodes__task_and_nodes(struct task_and_nodes t) {
	return (struct some__task_and_nodes) {t};
}
struct some__task some__some__task__task(struct task t) {
	return (struct some__task) {t};
}
uint8_t empty__q__bool__opt__opt__task(struct opt__opt__task a) {
	struct none n;
	struct some__opt__task s;
	struct opt__opt__task matched;
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
struct some__chosen_task some__some__chosen_task__chosen_task(struct chosen_task t) {
	return (struct some__chosen_task) {t};
}
struct err__no_chosen_task err__err__no_chosen_task__no_chosen_task(struct no_chosen_task t) {
	return (struct err__no_chosen_task) {t};
}
struct ok__chosen_task ok__ok__chosen_task__chosen_task(struct chosen_task t) {
	return (struct ok__chosen_task) {t};
}
uint8_t do_task___void__ptr_global_ctx__ptr_thread_local_stuff__chosen_task(struct global_ctx* gctx, struct thread_local_stuff* tls, struct chosen_task chosen_task) {
	struct vat* vat;
	struct some__task some_task;
	struct task task;
	struct ctx ctx;
	struct opt__task matched;
	vat = chosen_task.vat;
	matched = chosen_task.task_or_gc;
	switch (matched.kind) {
		case 0:
			todo___void();
			broadcast___void__ptr_condition((&(gctx->may_be_work_to_do)));
			break;
		case 1:
			some_task = matched.as1;
			task = some_task.value;
			ctx = new_ctx__ctx__ptr_global_ctx__ptr_thread_local_stuff__ptr_vat__nat(gctx, tls, vat, task.actor_id);
			call_with_ctx___void__ptr_ctx__fun_mut0___void((&(ctx)), task.fun);
			acquire_lock___void__ptr_lock((&(vat->tasks_lock)));
			noctx_must_remove_unordered___void__ptr_mut_arr__nat__nat((&(vat->currently_running_actors)), task.actor_id);
			release_lock___void__ptr_lock((&(vat->tasks_lock)));
			return_ctx___void__ptr_ctx((&(ctx)));
			break;
		default:
			(assert(0),0);
	}
	acquire_lock___void__ptr_lock((&(vat->tasks_lock)));
	(vat->n_threads_running = noctx_decr__nat__nat(vat->n_threads_running), 0);
	return release_lock___void__ptr_lock((&(vat->tasks_lock)));
}
uint8_t noctx_must_remove_unordered___void__ptr_mut_arr__nat__nat(struct mut_arr__nat* a, uint64_t value) {
	return noctx_must_remove_unordered_recur___void__ptr_mut_arr__nat__nat__nat(a, 0, value);
}
uint8_t noctx_must_remove_unordered_recur___void__ptr_mut_arr__nat__nat__nat(struct mut_arr__nat* a, uint64_t index, uint64_t value) {
	struct mut_arr__nat* _tailCalla;
	uint64_t _tailCallindex;
	uint64_t _tailCallvalue;
	top:
	if (_op_equal_equal__bool__nat__nat(index, a->size)) {
		return (assert(0),0);
	} else {
		if (_op_equal_equal__bool__nat__nat(noctx_at__nat__ptr_mut_arr__nat__nat(a, index), value)) {
			return drop___void__nat(noctx_remove_unordered_at_index__nat__ptr_mut_arr__nat__nat(a, index));
		} else {
			_tailCalla = a;
			_tailCallindex = noctx_incr__nat__nat(index);
			_tailCallvalue = value;
			a = _tailCalla;
			index = _tailCallindex;
			value = _tailCallvalue;
			goto top;
		}
	}
}
uint64_t noctx_at__nat__ptr_mut_arr__nat__nat(struct mut_arr__nat* a, uint64_t index) {
	hard_assert___void__bool(_op_less__bool__nat__nat(index, a->size));
	return (*((a->data + index)));
}
uint8_t drop___void__nat(uint64_t t) {
	return 0;
}
uint64_t noctx_remove_unordered_at_index__nat__ptr_mut_arr__nat__nat(struct mut_arr__nat* a, uint64_t index) {
	uint64_t res;
	res = noctx_at__nat__ptr_mut_arr__nat__nat(a, index);
	noctx_set_at___void__ptr_mut_arr__nat__nat__nat(a, index, noctx_last__nat__ptr_mut_arr__nat(a));
	(a->size = noctx_decr__nat__nat(a->size), 0);
	return res;
}
uint64_t noctx_last__nat__ptr_mut_arr__nat(struct mut_arr__nat* a) {
	hard_forbid___void__bool(empty__q__bool__ptr_mut_arr__nat(a));
	return noctx_at__nat__ptr_mut_arr__nat__nat(a, noctx_decr__nat__nat(a->size));
}
uint8_t empty__q__bool__ptr_mut_arr__nat(struct mut_arr__nat* a) {
	return zero__q__bool__nat(a->size);
}
uint8_t return_ctx___void__ptr_ctx(struct ctx* c) {
	return return_gc_ctx___void__ptr_gc_ctx((struct gc_ctx*) c->gc_ctx_ptr);
}
uint8_t return_gc_ctx___void__ptr_gc_ctx(struct gc_ctx* gc_ctx) {
	struct gc* gc;
	gc = gc_ctx->gc;
	acquire_lock___void__ptr_lock((&(gc->lk)));
	(gc_ctx->next_ctx = gc->context_head, 0);
	(gc->context_head = (struct opt__ptr_gc_ctx) {1, .as1 = some__some__ptr_gc_ctx__ptr_gc_ctx(gc_ctx)}, 0);
	return release_lock___void__ptr_lock((&(gc->lk)));
}
struct some__ptr_gc_ctx some__some__ptr_gc_ctx__ptr_gc_ctx(struct gc_ctx* t) {
	return (struct some__ptr_gc_ctx) {t};
}
uint8_t wait_on___void__ptr_condition__nat(struct condition* c, uint64_t last_checked) {
	struct condition* _tailCallc;
	uint64_t _tailCalllast_checked;
	top:
	if (_op_equal_equal__bool__nat__nat(c->value, last_checked)) {
		yield_thread___void();
		_tailCallc = c;
		_tailCalllast_checked = last_checked;
		c = _tailCallc;
		last_checked = _tailCalllast_checked;
		goto top;
	} else {
		return 0;
	}
}
uint8_t rt_main__int32__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char__lambda1(uint64_t thread_id, struct global_ctx* gctx) {
	return thread_function___void__nat__ptr_global_ctx(thread_id, gctx);
}
struct result__int32__exception must_be_resolved__result__int32__exception__ptr_fut__int32(struct fut__int32* f) {
	struct fut_state_resolved__int32 r;
	struct exception e;
	struct fut_state__int32 matched;
	matched = f->state;
	switch (matched.kind) {
		case 0:
			return hard_unreachable__result__int32__exception();
		case 1:
			r = matched.as1;
			return (struct result__int32__exception) {0, .as0 = ok__ok__int32__int32(r.value)};
		case 2:
			e = matched.as2;
			return (struct result__int32__exception) {1, .as1 = err__err__exception__exception(e)};
		default:
			return (assert(0),(struct result__int32__exception) {0});
	}
}
struct result__int32__exception hard_unreachable__result__int32__exception() {
	return (assert(0),(struct result__int32__exception) {0});
}
struct fut__int32* main__ptr_fut__int32__arr__arr__char(struct ctx* ctx, struct arr__arr__char args) {
	struct arr__arr__char arr;
	struct arr__arr__char option_names;
	struct opt__test_options options;
	struct some__test_options s;
	struct opt__test_options matched;
	struct arr__char* temp0;
	option_names = (temp0 = (struct arr__char*) alloc__ptr__byte__nat(ctx, (sizeof(struct arr__char) * 3)), ((*((temp0 + 0)) = (struct arr__char) {11, "print-tests"}, 0), ((*((temp0 + 1)) = (struct arr__char) {16, "overwrite-output"}, 0), ((*((temp0 + 2)) = (struct arr__char) {12, "max-failures"}, 0), (struct arr__arr__char) {3, temp0}))));
	options = parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char(ctx, args, option_names, (struct fun1__test_options__arr__opt__arr__arr__char) {(fun_ptr3__test_options__ptr_ctx__ptr__byte__arr__opt__arr__arr__char) main__ptr_fut__int32__arr__arr__char__lambda0, (uint8_t*) NULL});
	return resolved__ptr_fut__int32__int32(ctx, (matched = options, matched.kind == 0 ? (print_help___void(ctx), literal__int32__arr__char(ctx, (struct arr__char) {1, "1"})) : matched.kind == 1 ? (s = matched.as1, do_test__int32__test_options(ctx, s.value)) : (assert(0),0)));
}
struct opt__test_options parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char(struct ctx* ctx, struct arr__arr__char args, struct arr__arr__char t_names, struct fun1__test_options__arr__opt__arr__arr__char make_t) {
	struct parsed_cmd_line_args* parsed;
	struct mut_arr__opt__arr__arr__char* values;
	struct cell__bool* help;
	struct parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char__lambda0___closure* temp0;
	parsed = parse_cmd_line_args_dynamic__ptr_parsed_cmd_line_args__arr__arr__char(ctx, args);
	assert___void__bool__arr__char(ctx, empty__q__bool__arr__arr__char(parsed->nameless), (struct arr__char) {26, "Should be no nameless args"});
	assert___void__bool(ctx, empty__q__bool__arr__arr__char(parsed->after));
	values = fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char(ctx, t_names.size, (struct opt__arr__arr__char) {0, .as0 = none__none()});
	help = new_cell__ptr_cell__bool__bool(ctx, 0);
	each___void__ptr_dict__arr__char__arr__arr__char__fun_mut2___void__arr__char__arr__arr__char(ctx, parsed->named, (struct fun_mut2___void__arr__char__arr__arr__char) {(fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__arr__char) parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char__lambda0, (uint8_t*) (temp0 = (struct parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char__lambda0___closure)), ((*(temp0) = (struct parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char__lambda0___closure) {t_names, help, values}, 0), temp0))});
	if (get__bool__ptr_cell__bool(help)) {
		return (struct opt__test_options) {0, .as0 = none__none()};
	} else {
		return (struct opt__test_options) {1, .as1 = some__some__test_options__test_options(call__test_options__fun1__test_options__arr__opt__arr__arr__char__arr__opt__arr__arr__char(ctx, make_t, freeze__arr__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char(values)))};
	}
}
struct parsed_cmd_line_args* parse_cmd_line_args_dynamic__ptr_parsed_cmd_line_args__arr__arr__char(struct ctx* ctx, struct arr__arr__char args) {
	struct some__nat s;
	uint64_t first_named_arg_index;
	struct arr__arr__char nameless;
	struct arr__arr__char rest;
	struct some__nat s2;
	uint64_t sep_index;
	struct opt__nat matched;
	struct opt__nat matched1;
	struct parsed_cmd_line_args* temp0;
	struct parsed_cmd_line_args* temp1;
	struct parsed_cmd_line_args* temp2;
	matched1 = find_index__opt__nat__arr__arr__char__fun_mut1__bool__arr__char(ctx, args, (struct fun_mut1__bool__arr__char) {(fun_ptr3__bool__ptr_ctx__ptr__byte__arr__char) parse_cmd_line_args_dynamic__ptr_parsed_cmd_line_args__arr__arr__char__lambda0, (uint8_t*) NULL});
	switch (matched1.kind) {
		case 0:
			temp0 = (struct parsed_cmd_line_args*) alloc__ptr__byte__nat(ctx, sizeof(struct parsed_cmd_line_args));
			(*(temp0) = (struct parsed_cmd_line_args) {args, empty_dict__ptr_dict__arr__char__arr__arr__char(ctx), empty_arr__arr__arr__char()}, 0);
			return temp0;
		case 1:
			s = matched1.as1;
			first_named_arg_index = s.value;
			nameless = slice_up_to__arr__arr__char__arr__arr__char__nat(ctx, args, first_named_arg_index);
			rest = slice_starting_at__arr__arr__char__arr__arr__char__nat(ctx, args, first_named_arg_index);
			matched = find_index__opt__nat__arr__arr__char__fun_mut1__bool__arr__char(ctx, rest, (struct fun_mut1__bool__arr__char) {(fun_ptr3__bool__ptr_ctx__ptr__byte__arr__char) parse_cmd_line_args_dynamic__ptr_parsed_cmd_line_args__arr__arr__char__lambda1, (uint8_t*) NULL});
			switch (matched.kind) {
				case 0:
					temp1 = (struct parsed_cmd_line_args*) alloc__ptr__byte__nat(ctx, sizeof(struct parsed_cmd_line_args));
					(*(temp1) = (struct parsed_cmd_line_args) {nameless, parse_named_args__ptr_dict__arr__char__arr__arr__char__arr__arr__char(ctx, rest), empty_arr__arr__arr__char()}, 0);
					return temp1;
				case 1:
					s2 = matched.as1;
					sep_index = s2.value;
					temp2 = (struct parsed_cmd_line_args*) alloc__ptr__byte__nat(ctx, sizeof(struct parsed_cmd_line_args));
					(*(temp2) = (struct parsed_cmd_line_args) {nameless, parse_named_args__ptr_dict__arr__char__arr__arr__char__arr__arr__char(ctx, slice_up_to__arr__arr__char__arr__arr__char__nat(ctx, rest, sep_index)), slice_after__arr__arr__char__arr__arr__char__nat(ctx, rest, sep_index)}, 0);
					return temp2;
				default:
					return (assert(0),NULL);
			}
		default:
			return (assert(0),NULL);
	}
}
struct opt__nat find_index__opt__nat__arr__arr__char__fun_mut1__bool__arr__char(struct ctx* ctx, struct arr__arr__char a, struct fun_mut1__bool__arr__char pred) {
	return find_index_recur__opt__nat__arr__arr__char__nat__fun_mut1__bool__arr__char(ctx, a, 0, pred);
}
struct opt__nat find_index_recur__opt__nat__arr__arr__char__nat__fun_mut1__bool__arr__char(struct ctx* ctx, struct arr__arr__char a, uint64_t index, struct fun_mut1__bool__arr__char pred) {
	struct ctx* _tailCallctx;
	struct arr__arr__char _tailCalla;
	uint64_t _tailCallindex;
	struct fun_mut1__bool__arr__char _tailCallpred;
	top:
	if (_op_equal_equal__bool__nat__nat(index, a.size)) {
		return (struct opt__nat) {0, .as0 = none__none()};
	} else {
		if (call__bool__fun_mut1__bool__arr__char__arr__char(ctx, pred, at__arr__char__arr__arr__char__nat(ctx, a, index))) {
			return (struct opt__nat) {1, .as1 = some__some__nat__nat(index)};
		} else {
			_tailCallctx = ctx;
			_tailCalla = a;
			_tailCallindex = incr__nat__nat(ctx, index);
			_tailCallpred = pred;
			ctx = _tailCallctx;
			a = _tailCalla;
			index = _tailCallindex;
			pred = _tailCallpred;
			goto top;
		}
	}
}
uint8_t call__bool__fun_mut1__bool__arr__char__arr__char(struct ctx* ctx, struct fun_mut1__bool__arr__char f, struct arr__char p0) {
	return call_with_ctx__bool__ptr_ctx__fun_mut1__bool__arr__char__arr__char(ctx, f, p0);
}
uint8_t call_with_ctx__bool__ptr_ctx__fun_mut1__bool__arr__char__arr__char(struct ctx* c, struct fun_mut1__bool__arr__char f, struct arr__char p0) {
	return f.fun_ptr(c, f.closure, p0);
}
struct arr__char at__arr__char__arr__arr__char__nat(struct ctx* ctx, struct arr__arr__char a, uint64_t index) {
	assert___void__bool(ctx, _op_less__bool__nat__nat(index, a.size));
	return noctx_at__arr__char__arr__arr__char__nat(a, index);
}
struct arr__char noctx_at__arr__char__arr__arr__char__nat(struct arr__arr__char a, uint64_t index) {
	hard_assert___void__bool(_op_less__bool__nat__nat(index, a.size));
	return (*((a.data + index)));
}
struct some__nat some__some__nat__nat(uint64_t t) {
	return (struct some__nat) {t};
}
uint8_t starts_with__q__bool__arr__char__arr__char(struct ctx* ctx, struct arr__char a, struct arr__char start) {
	return (_op_greater_equal__bool__nat__nat(a.size, start.size) && arr_eq__q__bool__arr__char__arr__char(ctx, slice__arr__char__arr__char__nat__nat(ctx, a, 0, start.size), start));
}
uint8_t arr_eq__q__bool__arr__char__arr__char(struct ctx* ctx, struct arr__char a, struct arr__char b) {
	struct ctx* _tailCallctx;
	struct arr__char _tailCalla;
	struct arr__char _tailCallb;
	top:
	if (_op_equal_equal__bool__nat__nat(a.size, b.size)) {
		if (empty__q__bool__arr__char(a)) {
			return 1;
		} else {
			if (_op_equal_equal__bool__char__char(first__char__arr__char(ctx, a), first__char__arr__char(ctx, b))) {
				_tailCallctx = ctx;
				_tailCalla = tail__arr__char__arr__char(ctx, a);
				_tailCallb = tail__arr__char__arr__char(ctx, b);
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
char first__char__arr__char(struct ctx* ctx, struct arr__char a) {
	forbid___void__bool(ctx, empty__q__bool__arr__char(a));
	return at__char__arr__char__nat(ctx, a, 0);
}
char at__char__arr__char__nat(struct ctx* ctx, struct arr__char a, uint64_t index) {
	assert___void__bool(ctx, _op_less__bool__nat__nat(index, a.size));
	return noctx_at__char__arr__char__nat(a, index);
}
struct arr__char tail__arr__char__arr__char(struct ctx* ctx, struct arr__char a) {
	forbid___void__bool(ctx, empty__q__bool__arr__char(a));
	return slice_starting_at__arr__char__arr__char__nat(ctx, a, 1);
}
struct arr__char slice_starting_at__arr__char__arr__char__nat(struct ctx* ctx, struct arr__char a, uint64_t begin) {
	assert___void__bool(ctx, _op_less_equal__bool__nat__nat(begin, a.size));
	return slice__arr__char__arr__char__nat__nat(ctx, a, begin, _op_minus__nat__nat__nat(ctx, a.size, begin));
}
struct arr__char slice__arr__char__arr__char__nat__nat(struct ctx* ctx, struct arr__char a, uint64_t begin, uint64_t size) {
	assert___void__bool(ctx, _op_less_equal__bool__nat__nat(_op_plus__nat__nat__nat(ctx, begin, size), a.size));
	return (struct arr__char) {size, (a.data + begin)};
}
uint8_t parse_cmd_line_args_dynamic__ptr_parsed_cmd_line_args__arr__arr__char__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr__char it) {
	return starts_with__q__bool__arr__char__arr__char(ctx, it, (struct arr__char) {2, "--"});
}
struct dict__arr__char__arr__arr__char* empty_dict__ptr_dict__arr__char__arr__arr__char(struct ctx* ctx) {
	struct dict__arr__char__arr__arr__char* temp0;
	temp0 = (struct dict__arr__char__arr__arr__char*) alloc__ptr__byte__nat(ctx, sizeof(struct dict__arr__char__arr__arr__char));
	(*(temp0) = (struct dict__arr__char__arr__arr__char) {empty_arr__arr__arr__char(), empty_arr__arr__arr__arr__char()}, 0);
	return temp0;
}
struct arr__arr__char empty_arr__arr__arr__char() {
	return (struct arr__arr__char) {0, NULL};
}
struct arr__arr__arr__char empty_arr__arr__arr__arr__char() {
	return (struct arr__arr__arr__char) {0, NULL};
}
struct arr__arr__char slice_up_to__arr__arr__char__arr__arr__char__nat(struct ctx* ctx, struct arr__arr__char a, uint64_t size) {
	assert___void__bool(ctx, _op_less__bool__nat__nat(size, a.size));
	return slice__arr__arr__char__arr__arr__char__nat__nat(ctx, a, 0, size);
}
struct arr__arr__char slice__arr__arr__char__arr__arr__char__nat__nat(struct ctx* ctx, struct arr__arr__char a, uint64_t begin, uint64_t size) {
	assert___void__bool(ctx, _op_less_equal__bool__nat__nat(_op_plus__nat__nat__nat(ctx, begin, size), a.size));
	return (struct arr__arr__char) {size, (a.data + begin)};
}
struct arr__arr__char slice_starting_at__arr__arr__char__arr__arr__char__nat(struct ctx* ctx, struct arr__arr__char a, uint64_t begin) {
	assert___void__bool(ctx, _op_less_equal__bool__nat__nat(begin, a.size));
	return slice__arr__arr__char__arr__arr__char__nat__nat(ctx, a, begin, _op_minus__nat__nat__nat(ctx, a.size, begin));
}
uint8_t _op_equal_equal__bool__arr__char__arr__char(struct arr__char a, struct arr__char b) {
	struct comparison matched;
	matched = _op_less_equal_greater__comparison__arr__char__arr__char(a, b);
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
struct comparison _op_less_equal_greater__comparison__arr__char__arr__char(struct arr__char a, struct arr__char b) {
	struct comparison _cmpel;
	struct comparison _matchedel;
	struct arr__char _tailCalla;
	struct arr__char _tailCallb;
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
			_cmpel = _op_less_equal_greater__comparison__char__char((*(a.data)), (*(b.data)));
			_matchedel = _cmpel;
			switch (_matchedel.kind) {
				case 0:
					return _cmpel;
				case 1:
					_tailCalla = (struct arr__char) {(a.size - 1), (a.data + 1)};
					_tailCallb = (struct arr__char) {(b.size - 1), (b.data + 1)};
					a = _tailCalla;
					b = _tailCallb;
					goto top;
				case 2:
					return _cmpel;
				default:
					return (assert(0),(struct comparison) {0});
			}
		}
	}
}
uint8_t parse_cmd_line_args_dynamic__ptr_parsed_cmd_line_args__arr__arr__char__lambda1(struct ctx* ctx, uint8_t* _closure, struct arr__char it) {
	return _op_equal_equal__bool__arr__char__arr__char(it, (struct arr__char) {2, "--"});
}
struct dict__arr__char__arr__arr__char* parse_named_args__ptr_dict__arr__char__arr__arr__char__arr__arr__char(struct ctx* ctx, struct arr__arr__char args) {
	struct mut_dict__arr__char__arr__arr__char b;
	b = new_mut_dict__mut_dict__arr__char__arr__arr__char(ctx);
	parse_named_args_recur___void__arr__arr__char__mut_dict__arr__char__arr__arr__char(ctx, args, b);
	return freeze__ptr_dict__arr__char__arr__arr__char__mut_dict__arr__char__arr__arr__char(ctx, b);
}
struct mut_dict__arr__char__arr__arr__char new_mut_dict__mut_dict__arr__char__arr__arr__char(struct ctx* ctx) {
	return (struct mut_dict__arr__char__arr__arr__char) {new_mut_arr__ptr_mut_arr__arr__char(ctx), new_mut_arr__ptr_mut_arr__arr__arr__char(ctx)};
}
struct mut_arr__arr__char* new_mut_arr__ptr_mut_arr__arr__char(struct ctx* ctx) {
	struct mut_arr__arr__char* temp0;
	temp0 = (struct mut_arr__arr__char*) alloc__ptr__byte__nat(ctx, sizeof(struct mut_arr__arr__char));
	(*(temp0) = (struct mut_arr__arr__char) {0, 0, 0, NULL}, 0);
	return temp0;
}
struct mut_arr__arr__arr__char* new_mut_arr__ptr_mut_arr__arr__arr__char(struct ctx* ctx) {
	struct mut_arr__arr__arr__char* temp0;
	temp0 = (struct mut_arr__arr__arr__char*) alloc__ptr__byte__nat(ctx, sizeof(struct mut_arr__arr__arr__char));
	(*(temp0) = (struct mut_arr__arr__arr__char) {0, 0, 0, NULL}, 0);
	return temp0;
}
uint8_t parse_named_args_recur___void__arr__arr__char__mut_dict__arr__char__arr__arr__char(struct ctx* ctx, struct arr__arr__char args, struct mut_dict__arr__char__arr__arr__char builder) {
	struct arr__char first_name;
	struct arr__arr__char tl;
	struct some__nat s;
	uint64_t next_named_arg_index;
	struct opt__nat matched;
	struct ctx* _tailCallctx;
	struct arr__arr__char _tailCallargs;
	struct mut_dict__arr__char__arr__arr__char _tailCallbuilder;
	top:
	first_name = remove_start__arr__char__arr__char__arr__char(ctx, first__arr__char__arr__arr__char(ctx, args), (struct arr__char) {2, "--"});
	tl = tail__arr__arr__char__arr__arr__char(ctx, args);
	matched = find_index__opt__nat__arr__arr__char__fun_mut1__bool__arr__char(ctx, tl, (struct fun_mut1__bool__arr__char) {(fun_ptr3__bool__ptr_ctx__ptr__byte__arr__char) parse_named_args_recur___void__arr__arr__char__mut_dict__arr__char__arr__arr__char__lambda0, (uint8_t*) NULL});
	switch (matched.kind) {
		case 0:
			return add___void__mut_dict__arr__char__arr__arr__char__arr__char__arr__arr__char(ctx, builder, first_name, tl);
		case 1:
			s = matched.as1;
			next_named_arg_index = s.value;
			add___void__mut_dict__arr__char__arr__arr__char__arr__char__arr__arr__char(ctx, builder, first_name, slice_up_to__arr__arr__char__arr__arr__char__nat(ctx, tl, next_named_arg_index));
			_tailCallctx = ctx;
			_tailCallargs = slice_starting_at__arr__arr__char__arr__arr__char__nat(ctx, args, next_named_arg_index);
			_tailCallbuilder = builder;
			ctx = _tailCallctx;
			args = _tailCallargs;
			builder = _tailCallbuilder;
			goto top;
		default:
			return (assert(0),0);
	}
}
struct arr__char remove_start__arr__char__arr__char__arr__char(struct ctx* ctx, struct arr__char a, struct arr__char start) {
	return force__arr__char__opt__arr__char(ctx, try_remove_start__opt__arr__char__arr__char__arr__char(ctx, a, start));
}
struct arr__char force__arr__char__opt__arr__char(struct ctx* ctx, struct opt__arr__char a) {
	struct none n;
	struct some__arr__char s;
	struct opt__arr__char matched;
	matched = a;
	switch (matched.kind) {
		case 0:
			n = matched.as0;
			return fail__arr__char__arr__char(ctx, (struct arr__char) {27, "tried to force empty option"});
		case 1:
			s = matched.as1;
			return s.value;
		default:
			return (assert(0),(struct arr__char) {0, NULL});
	}
}
struct arr__char fail__arr__char__arr__char(struct ctx* ctx, struct arr__char reason) {
	return throw__arr__char__exception(ctx, (struct exception) {reason});
}
struct arr__char throw__arr__char__exception(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx;
	exn_ctx = get_exception_ctx__ptr_exception_ctx(ctx);
	hard_forbid___void__bool(_op_equal_equal__bool__ptr__jmp_buf_tag__ptr__jmp_buf_tag(exn_ctx->jmp_buf_ptr, NULL));
	(exn_ctx->thrown_exception = e, 0);
	(longjmp(exn_ctx->jmp_buf_ptr, number_to_throw__int32(ctx)), 0);
	return todo__arr__char();
}
struct arr__char todo__arr__char() {
	return (assert(0),(struct arr__char) {0, NULL});
}
struct opt__arr__char try_remove_start__opt__arr__char__arr__char__arr__char(struct ctx* ctx, struct arr__char a, struct arr__char start) {
	if (starts_with__q__bool__arr__char__arr__char(ctx, a, start)) {
		return (struct opt__arr__char) {1, .as1 = some__some__arr__char__arr__char(slice_starting_at__arr__char__arr__char__nat(ctx, a, start.size))};
	} else {
		return (struct opt__arr__char) {0, .as0 = none__none()};
	}
}
struct some__arr__char some__some__arr__char__arr__char(struct arr__char t) {
	return (struct some__arr__char) {t};
}
struct arr__char first__arr__char__arr__arr__char(struct ctx* ctx, struct arr__arr__char a) {
	forbid___void__bool(ctx, empty__q__bool__arr__arr__char(a));
	return at__arr__char__arr__arr__char__nat(ctx, a, 0);
}
uint8_t empty__q__bool__arr__arr__char(struct arr__arr__char a) {
	return zero__q__bool__nat(a.size);
}
struct arr__arr__char tail__arr__arr__char__arr__arr__char(struct ctx* ctx, struct arr__arr__char a) {
	forbid___void__bool(ctx, empty__q__bool__arr__arr__char(a));
	return slice_starting_at__arr__arr__char__arr__arr__char__nat(ctx, a, 1);
}
uint8_t parse_named_args_recur___void__arr__arr__char__mut_dict__arr__char__arr__arr__char__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr__char it) {
	return starts_with__q__bool__arr__char__arr__char(ctx, it, (struct arr__char) {2, "--"});
}
uint8_t add___void__mut_dict__arr__char__arr__arr__char__arr__char__arr__arr__char(struct ctx* ctx, struct mut_dict__arr__char__arr__arr__char m, struct arr__char key, struct arr__arr__char value) {
	forbid___void__bool(ctx, has__q__bool__mut_dict__arr__char__arr__arr__char__arr__char(ctx, m, key));
	push___void__ptr_mut_arr__arr__char__arr__char(ctx, m.keys, key);
	return push___void__ptr_mut_arr__arr__arr__char__arr__arr__char(ctx, m.values, value);
}
uint8_t has__q__bool__mut_dict__arr__char__arr__arr__char__arr__char(struct ctx* ctx, struct mut_dict__arr__char__arr__arr__char d, struct arr__char key) {
	return has__q__bool__ptr_dict__arr__char__arr__arr__char__arr__char(ctx, unsafe_as_dict__ptr_dict__arr__char__arr__arr__char__mut_dict__arr__char__arr__arr__char(ctx, d), key);
}
uint8_t has__q__bool__ptr_dict__arr__char__arr__arr__char__arr__char(struct ctx* ctx, struct dict__arr__char__arr__arr__char* d, struct arr__char key) {
	return has__q__bool__opt__arr__arr__char(get__opt__arr__arr__char__ptr_dict__arr__char__arr__arr__char__arr__char(ctx, d, key));
}
uint8_t has__q__bool__opt__arr__arr__char(struct opt__arr__arr__char a) {
	return !empty__q__bool__opt__arr__arr__char(a);
}
uint8_t empty__q__bool__opt__arr__arr__char(struct opt__arr__arr__char a) {
	struct none n;
	struct some__arr__arr__char s;
	struct opt__arr__arr__char matched;
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
struct opt__arr__arr__char get__opt__arr__arr__char__ptr_dict__arr__char__arr__arr__char__arr__char(struct ctx* ctx, struct dict__arr__char__arr__arr__char* d, struct arr__char key) {
	return get_recursive__opt__arr__arr__char__arr__arr__char__arr__arr__arr__char__nat__arr__char(ctx, d->keys, d->values, 0, key);
}
struct opt__arr__arr__char get_recursive__opt__arr__arr__char__arr__arr__char__arr__arr__arr__char__nat__arr__char(struct ctx* ctx, struct arr__arr__char keys, struct arr__arr__arr__char values, uint64_t idx, struct arr__char key) {
	struct ctx* _tailCallctx;
	struct arr__arr__char _tailCallkeys;
	struct arr__arr__arr__char _tailCallvalues;
	uint64_t _tailCallidx;
	struct arr__char _tailCallkey;
	top:
	if (_op_equal_equal__bool__nat__nat(idx, keys.size)) {
		return (struct opt__arr__arr__char) {0, .as0 = none__none()};
	} else {
		if (_op_equal_equal__bool__arr__char__arr__char(key, at__arr__char__arr__arr__char__nat(ctx, keys, idx))) {
			return (struct opt__arr__arr__char) {1, .as1 = some__some__arr__arr__char__arr__arr__char(at__arr__arr__char__arr__arr__arr__char__nat(ctx, values, idx))};
		} else {
			_tailCallctx = ctx;
			_tailCallkeys = keys;
			_tailCallvalues = values;
			_tailCallidx = incr__nat__nat(ctx, idx);
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
struct some__arr__arr__char some__some__arr__arr__char__arr__arr__char(struct arr__arr__char t) {
	return (struct some__arr__arr__char) {t};
}
struct arr__arr__char at__arr__arr__char__arr__arr__arr__char__nat(struct ctx* ctx, struct arr__arr__arr__char a, uint64_t index) {
	assert___void__bool(ctx, _op_less__bool__nat__nat(index, a.size));
	return noctx_at__arr__arr__char__arr__arr__arr__char__nat(a, index);
}
struct arr__arr__char noctx_at__arr__arr__char__arr__arr__arr__char__nat(struct arr__arr__arr__char a, uint64_t index) {
	hard_assert___void__bool(_op_less__bool__nat__nat(index, a.size));
	return (*((a.data + index)));
}
struct dict__arr__char__arr__arr__char* unsafe_as_dict__ptr_dict__arr__char__arr__arr__char__mut_dict__arr__char__arr__arr__char(struct ctx* ctx, struct mut_dict__arr__char__arr__arr__char m) {
	struct dict__arr__char__arr__arr__char* temp0;
	temp0 = (struct dict__arr__char__arr__arr__char*) alloc__ptr__byte__nat(ctx, sizeof(struct dict__arr__char__arr__arr__char));
	(*(temp0) = (struct dict__arr__char__arr__arr__char) {unsafe_as_arr__arr__arr__char__ptr_mut_arr__arr__char(m.keys), unsafe_as_arr__arr__arr__arr__char__ptr_mut_arr__arr__arr__char(m.values)}, 0);
	return temp0;
}
struct arr__arr__arr__char unsafe_as_arr__arr__arr__arr__char__ptr_mut_arr__arr__arr__char(struct mut_arr__arr__arr__char* a) {
	return (struct arr__arr__arr__char) {a->size, a->data};
}
uint8_t push___void__ptr_mut_arr__arr__char__arr__char(struct ctx* ctx, struct mut_arr__arr__char* a, struct arr__char value) {
	if (_op_equal_equal__bool__nat__nat(a->size, a->capacity)) {
		increase_capacity_to___void__ptr_mut_arr__arr__char__nat(ctx, a, (zero__q__bool__nat(a->size) ? four__nat() : _op_times__nat__nat__nat(ctx, a->size, two__nat())));
	} else {
		0;
	}
	ensure_capacity___void__ptr_mut_arr__arr__char__nat(ctx, a, round_up_to_power_of_two__nat__nat(ctx, incr__nat__nat(ctx, a->size)));
	assert___void__bool(ctx, _op_less__bool__nat__nat(a->size, a->capacity));
	(*((a->data + a->size)) = value, 0);
	return (a->size = incr__nat__nat(ctx, a->size), 0);
}
uint8_t increase_capacity_to___void__ptr_mut_arr__arr__char__nat(struct ctx* ctx, struct mut_arr__arr__char* a, uint64_t new_capacity) {
	struct arr__char* old_data;
	assert___void__bool(ctx, _op_greater__bool__nat__nat(new_capacity, a->capacity));
	old_data = a->data;
	(a->capacity = new_capacity, 0);
	(a->data = uninitialized_data__ptr__arr__char__nat(ctx, new_capacity), 0);
	return copy_data_from___void__ptr__arr__char__ptr__arr__char__nat(ctx, a->data, old_data, a->size);
}
uint8_t copy_data_from___void__ptr__arr__char__ptr__arr__char__nat(struct ctx* ctx, struct arr__char* to, struct arr__char* from, uint64_t len) {
	uint64_t hl;
	struct ctx* _tailCallctx;
	struct arr__char* _tailCallto;
	struct arr__char* _tailCallfrom;
	uint64_t _tailCalllen;
	top:
	if (_op_less__bool__nat__nat(len, eight__nat())) {
		return copy_data_from_small___void__ptr__arr__char__ptr__arr__char__nat(ctx, to, from, len);
	} else {
		hl = _op_div__nat__nat__nat(ctx, len, two__nat());
		copy_data_from___void__ptr__arr__char__ptr__arr__char__nat(ctx, to, from, hl);
		_tailCallctx = ctx;
		_tailCallto = (to + hl);
		_tailCallfrom = (from + hl);
		_tailCalllen = _op_minus__nat__nat__nat(ctx, len, hl);
		ctx = _tailCallctx;
		to = _tailCallto;
		from = _tailCallfrom;
		len = _tailCalllen;
		goto top;
	}
}
uint8_t copy_data_from_small___void__ptr__arr__char__ptr__arr__char__nat(struct ctx* ctx, struct arr__char* to, struct arr__char* from, uint64_t len) {
	if (zero__q__bool__nat(len)) {
		return 0;
	} else {
		(*(to) = (*(from)), 0);
		return copy_data_from___void__ptr__arr__char__ptr__arr__char__nat(ctx, incr__ptr__arr__char__ptr__arr__char(to), incr__ptr__arr__char__ptr__arr__char(from), decr__nat__nat(ctx, len));
	}
}
struct arr__char* incr__ptr__arr__char__ptr__arr__char(struct arr__char* p) {
	return (p + 1);
}
uint64_t decr__nat__nat(struct ctx* ctx, uint64_t a) {
	forbid___void__bool(ctx, zero__q__bool__nat(a));
	return wrap_decr__nat__nat(a);
}
uint64_t wrap_decr__nat__nat(uint64_t a) {
	return (a - 1);
}
uint64_t _op_div__nat__nat__nat(struct ctx* ctx, uint64_t a, uint64_t b) {
	forbid___void__bool(ctx, zero__q__bool__nat(b));
	return (a / b);
}
uint64_t _op_times__nat__nat__nat(struct ctx* ctx, uint64_t a, uint64_t b) {
	uint64_t res;
	if ((zero__q__bool__nat(a) || zero__q__bool__nat(b))) {
		return 0;
	} else {
		res = (a * b);
		assert___void__bool(ctx, _op_equal_equal__bool__nat__nat(_op_div__nat__nat__nat(ctx, res, b), a));
		assert___void__bool(ctx, _op_equal_equal__bool__nat__nat(_op_div__nat__nat__nat(ctx, res, a), b));
		return res;
	}
}
uint8_t ensure_capacity___void__ptr_mut_arr__arr__char__nat(struct ctx* ctx, struct mut_arr__arr__char* a, uint64_t capacity) {
	if (_op_less__bool__nat__nat(a->capacity, capacity)) {
		return increase_capacity_to___void__ptr_mut_arr__arr__char__nat(ctx, a, round_up_to_power_of_two__nat__nat(ctx, capacity));
	} else {
		return 0;
	}
}
uint64_t round_up_to_power_of_two__nat__nat(struct ctx* ctx, uint64_t n) {
	return round_up_to_power_of_two_recur__nat__nat__nat(ctx, 1, n);
}
uint64_t round_up_to_power_of_two_recur__nat__nat__nat(struct ctx* ctx, uint64_t acc, uint64_t n) {
	struct ctx* _tailCallctx;
	uint64_t _tailCallacc;
	uint64_t _tailCalln;
	top:
	if (_op_greater_equal__bool__nat__nat(acc, n)) {
		return acc;
	} else {
		_tailCallctx = ctx;
		_tailCallacc = _op_times__nat__nat__nat(ctx, acc, two__nat());
		_tailCalln = n;
		ctx = _tailCallctx;
		acc = _tailCallacc;
		n = _tailCalln;
		goto top;
	}
}
uint8_t push___void__ptr_mut_arr__arr__arr__char__arr__arr__char(struct ctx* ctx, struct mut_arr__arr__arr__char* a, struct arr__arr__char value) {
	if (_op_equal_equal__bool__nat__nat(a->size, a->capacity)) {
		increase_capacity_to___void__ptr_mut_arr__arr__arr__char__nat(ctx, a, (zero__q__bool__nat(a->size) ? four__nat() : _op_times__nat__nat__nat(ctx, a->size, two__nat())));
	} else {
		0;
	}
	ensure_capacity___void__ptr_mut_arr__arr__arr__char__nat(ctx, a, round_up_to_power_of_two__nat__nat(ctx, incr__nat__nat(ctx, a->size)));
	assert___void__bool(ctx, _op_less__bool__nat__nat(a->size, a->capacity));
	(*((a->data + a->size)) = value, 0);
	return (a->size = incr__nat__nat(ctx, a->size), 0);
}
uint8_t increase_capacity_to___void__ptr_mut_arr__arr__arr__char__nat(struct ctx* ctx, struct mut_arr__arr__arr__char* a, uint64_t new_capacity) {
	struct arr__arr__char* old_data;
	assert___void__bool(ctx, _op_greater__bool__nat__nat(new_capacity, a->capacity));
	old_data = a->data;
	(a->capacity = new_capacity, 0);
	(a->data = uninitialized_data__ptr__arr__arr__char__nat(ctx, new_capacity), 0);
	return copy_data_from___void__ptr__arr__arr__char__ptr__arr__arr__char__nat(ctx, a->data, old_data, a->size);
}
struct arr__arr__char* uninitialized_data__ptr__arr__arr__char__nat(struct ctx* ctx, uint64_t size) {
	uint8_t* bptr;
	bptr = alloc__ptr__byte__nat(ctx, (size * sizeof(struct arr__arr__char)));
	return (struct arr__arr__char*) bptr;
}
uint8_t copy_data_from___void__ptr__arr__arr__char__ptr__arr__arr__char__nat(struct ctx* ctx, struct arr__arr__char* to, struct arr__arr__char* from, uint64_t len) {
	uint64_t hl;
	struct ctx* _tailCallctx;
	struct arr__arr__char* _tailCallto;
	struct arr__arr__char* _tailCallfrom;
	uint64_t _tailCalllen;
	top:
	if (_op_less__bool__nat__nat(len, eight__nat())) {
		return copy_data_from_small___void__ptr__arr__arr__char__ptr__arr__arr__char__nat(ctx, to, from, len);
	} else {
		hl = _op_div__nat__nat__nat(ctx, len, two__nat());
		copy_data_from___void__ptr__arr__arr__char__ptr__arr__arr__char__nat(ctx, to, from, hl);
		_tailCallctx = ctx;
		_tailCallto = (to + hl);
		_tailCallfrom = (from + hl);
		_tailCalllen = _op_minus__nat__nat__nat(ctx, len, hl);
		ctx = _tailCallctx;
		to = _tailCallto;
		from = _tailCallfrom;
		len = _tailCalllen;
		goto top;
	}
}
uint8_t copy_data_from_small___void__ptr__arr__arr__char__ptr__arr__arr__char__nat(struct ctx* ctx, struct arr__arr__char* to, struct arr__arr__char* from, uint64_t len) {
	if (zero__q__bool__nat(len)) {
		return 0;
	} else {
		(*(to) = (*(from)), 0);
		return copy_data_from___void__ptr__arr__arr__char__ptr__arr__arr__char__nat(ctx, incr__ptr__arr__arr__char__ptr__arr__arr__char(to), incr__ptr__arr__arr__char__ptr__arr__arr__char(from), decr__nat__nat(ctx, len));
	}
}
struct arr__arr__char* incr__ptr__arr__arr__char__ptr__arr__arr__char(struct arr__arr__char* p) {
	return (p + 1);
}
uint8_t ensure_capacity___void__ptr_mut_arr__arr__arr__char__nat(struct ctx* ctx, struct mut_arr__arr__arr__char* a, uint64_t capacity) {
	if (_op_less__bool__nat__nat(a->capacity, capacity)) {
		return increase_capacity_to___void__ptr_mut_arr__arr__arr__char__nat(ctx, a, round_up_to_power_of_two__nat__nat(ctx, capacity));
	} else {
		return 0;
	}
}
struct dict__arr__char__arr__arr__char* freeze__ptr_dict__arr__char__arr__arr__char__mut_dict__arr__char__arr__arr__char(struct ctx* ctx, struct mut_dict__arr__char__arr__arr__char m) {
	struct dict__arr__char__arr__arr__char* temp0;
	temp0 = (struct dict__arr__char__arr__arr__char*) alloc__ptr__byte__nat(ctx, sizeof(struct dict__arr__char__arr__arr__char));
	(*(temp0) = (struct dict__arr__char__arr__arr__char) {freeze__arr__arr__char__ptr_mut_arr__arr__char(m.keys), freeze__arr__arr__arr__char__ptr_mut_arr__arr__arr__char(m.values)}, 0);
	return temp0;
}
struct arr__arr__arr__char freeze__arr__arr__arr__char__ptr_mut_arr__arr__arr__char(struct mut_arr__arr__arr__char* a) {
	(a->frozen__q = 1, 0);
	return unsafe_as_arr__arr__arr__arr__char__ptr_mut_arr__arr__arr__char(a);
}
struct arr__arr__char slice_after__arr__arr__char__arr__arr__char__nat(struct ctx* ctx, struct arr__arr__char a, uint64_t before_begin) {
	return slice_starting_at__arr__arr__char__arr__arr__char__nat(ctx, a, incr__nat__nat(ctx, before_begin));
}
struct mut_arr__opt__arr__arr__char* fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char(struct ctx* ctx, uint64_t size, struct opt__arr__arr__char value) {
	struct fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0___closure* temp0;
	return make_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__fun_mut1__opt__arr__arr__char__nat(ctx, size, (struct fun_mut1__opt__arr__arr__char__nat) {(fun_ptr3__opt__arr__arr__char__ptr_ctx__ptr__byte__nat) fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0, (uint8_t*) (temp0 = (struct fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0___closure)), ((*(temp0) = (struct fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0___closure) {value}, 0), temp0))});
}
struct mut_arr__opt__arr__arr__char* make_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__fun_mut1__opt__arr__arr__char__nat(struct ctx* ctx, uint64_t size, struct fun_mut1__opt__arr__arr__char__nat f) {
	struct mut_arr__opt__arr__arr__char* res;
	res = new_uninitialized_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat(ctx, size);
	make_mut_arr_worker___void__ptr_mut_arr__opt__arr__arr__char__nat__fun_mut1__opt__arr__arr__char__nat(ctx, res, 0, f);
	return res;
}
struct mut_arr__opt__arr__arr__char* new_uninitialized_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat(struct ctx* ctx, uint64_t size) {
	struct mut_arr__opt__arr__arr__char* temp0;
	temp0 = (struct mut_arr__opt__arr__arr__char*) alloc__ptr__byte__nat(ctx, sizeof(struct mut_arr__opt__arr__arr__char));
	(*(temp0) = (struct mut_arr__opt__arr__arr__char) {0, size, size, uninitialized_data__ptr__opt__arr__arr__char__nat(ctx, size)}, 0);
	return temp0;
}
struct opt__arr__arr__char* uninitialized_data__ptr__opt__arr__arr__char__nat(struct ctx* ctx, uint64_t size) {
	uint8_t* bptr;
	bptr = alloc__ptr__byte__nat(ctx, (size * sizeof(struct opt__arr__arr__char)));
	return (struct opt__arr__arr__char*) bptr;
}
uint8_t make_mut_arr_worker___void__ptr_mut_arr__opt__arr__arr__char__nat__fun_mut1__opt__arr__arr__char__nat(struct ctx* ctx, struct mut_arr__opt__arr__arr__char* m, uint64_t i, struct fun_mut1__opt__arr__arr__char__nat f) {
	struct ctx* _tailCallctx;
	struct mut_arr__opt__arr__arr__char* _tailCallm;
	uint64_t _tailCalli;
	struct fun_mut1__opt__arr__arr__char__nat _tailCallf;
	top:
	if (_op_equal_equal__bool__nat__nat(i, m->size)) {
		return 0;
	} else {
		set_at___void__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char(ctx, m, i, call__opt__arr__arr__char__fun_mut1__opt__arr__arr__char__nat__nat(ctx, f, i));
		_tailCallctx = ctx;
		_tailCallm = m;
		_tailCalli = incr__nat__nat(ctx, i);
		_tailCallf = f;
		ctx = _tailCallctx;
		m = _tailCallm;
		i = _tailCalli;
		f = _tailCallf;
		goto top;
	}
}
uint8_t set_at___void__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char(struct ctx* ctx, struct mut_arr__opt__arr__arr__char* a, uint64_t index, struct opt__arr__arr__char value) {
	assert___void__bool(ctx, _op_less__bool__nat__nat(index, a->size));
	return noctx_set_at___void__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char(a, index, value);
}
uint8_t noctx_set_at___void__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char(struct mut_arr__opt__arr__arr__char* a, uint64_t index, struct opt__arr__arr__char value) {
	hard_assert___void__bool(_op_less__bool__nat__nat(index, a->size));
	return (*((a->data + index)) = value, 0);
}
struct opt__arr__arr__char call__opt__arr__arr__char__fun_mut1__opt__arr__arr__char__nat__nat(struct ctx* ctx, struct fun_mut1__opt__arr__arr__char__nat f, uint64_t p0) {
	return call_with_ctx__opt__arr__arr__char__ptr_ctx__fun_mut1__opt__arr__arr__char__nat__nat(ctx, f, p0);
}
struct opt__arr__arr__char call_with_ctx__opt__arr__arr__char__ptr_ctx__fun_mut1__opt__arr__arr__char__nat__nat(struct ctx* c, struct fun_mut1__opt__arr__arr__char__nat f, uint64_t p0) {
	return f.fun_ptr(c, f.closure, p0);
}
struct opt__arr__arr__char fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0(struct ctx* ctx, struct fill_mut_arr__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char__lambda0___closure* _closure, uint64_t ignore) {
	return _closure->value;
}
struct cell__bool* new_cell__ptr_cell__bool__bool(struct ctx* ctx, uint8_t value) {
	struct cell__bool* temp0;
	temp0 = (struct cell__bool*) alloc__ptr__byte__nat(ctx, sizeof(struct cell__bool));
	(*(temp0) = (struct cell__bool) {value}, 0);
	return temp0;
}
uint8_t each___void__ptr_dict__arr__char__arr__arr__char__fun_mut2___void__arr__char__arr__arr__char(struct ctx* ctx, struct dict__arr__char__arr__arr__char* d, struct fun_mut2___void__arr__char__arr__arr__char f) {
	struct dict__arr__char__arr__arr__char* temp0;
	struct ctx* _tailCallctx;
	struct dict__arr__char__arr__arr__char* _tailCalld;
	struct fun_mut2___void__arr__char__arr__arr__char _tailCallf;
	top:
	if (empty__q__bool__ptr_dict__arr__char__arr__arr__char(ctx, d)) {
		return 0;
	} else {
		call___void__fun_mut2___void__arr__char__arr__arr__char__arr__char__arr__arr__char(ctx, f, first__arr__char__arr__arr__char(ctx, d->keys), first__arr__arr__char__arr__arr__arr__char(ctx, d->values));
		_tailCallctx = ctx;
		_tailCalld = (temp0 = (struct dict__arr__char__arr__arr__char*) alloc__ptr__byte__nat(ctx, sizeof(struct dict__arr__char__arr__arr__char)), ((*(temp0) = (struct dict__arr__char__arr__arr__char) {tail__arr__arr__char__arr__arr__char(ctx, d->keys), tail__arr__arr__arr__char__arr__arr__arr__char(ctx, d->values)}, 0), temp0));
		_tailCallf = f;
		ctx = _tailCallctx;
		d = _tailCalld;
		f = _tailCallf;
		goto top;
	}
}
uint8_t empty__q__bool__ptr_dict__arr__char__arr__arr__char(struct ctx* ctx, struct dict__arr__char__arr__arr__char* d) {
	return empty__q__bool__arr__arr__char(d->keys);
}
uint8_t call___void__fun_mut2___void__arr__char__arr__arr__char__arr__char__arr__arr__char(struct ctx* ctx, struct fun_mut2___void__arr__char__arr__arr__char f, struct arr__char p0, struct arr__arr__char p1) {
	return call_with_ctx___void__ptr_ctx__fun_mut2___void__arr__char__arr__arr__char__arr__char__arr__arr__char(ctx, f, p0, p1);
}
uint8_t call_with_ctx___void__ptr_ctx__fun_mut2___void__arr__char__arr__arr__char__arr__char__arr__arr__char(struct ctx* c, struct fun_mut2___void__arr__char__arr__arr__char f, struct arr__char p0, struct arr__arr__char p1) {
	return f.fun_ptr(c, f.closure, p0, p1);
}
struct arr__arr__char first__arr__arr__char__arr__arr__arr__char(struct ctx* ctx, struct arr__arr__arr__char a) {
	forbid___void__bool(ctx, empty__q__bool__arr__arr__arr__char(a));
	return at__arr__arr__char__arr__arr__arr__char__nat(ctx, a, 0);
}
uint8_t empty__q__bool__arr__arr__arr__char(struct arr__arr__arr__char a) {
	return zero__q__bool__nat(a.size);
}
struct arr__arr__arr__char tail__arr__arr__arr__char__arr__arr__arr__char(struct ctx* ctx, struct arr__arr__arr__char a) {
	forbid___void__bool(ctx, empty__q__bool__arr__arr__arr__char(a));
	return slice_starting_at__arr__arr__arr__char__arr__arr__arr__char__nat(ctx, a, 1);
}
struct arr__arr__arr__char slice_starting_at__arr__arr__arr__char__arr__arr__arr__char__nat(struct ctx* ctx, struct arr__arr__arr__char a, uint64_t begin) {
	assert___void__bool(ctx, _op_less_equal__bool__nat__nat(begin, a.size));
	return slice__arr__arr__arr__char__arr__arr__arr__char__nat__nat(ctx, a, begin, _op_minus__nat__nat__nat(ctx, a.size, begin));
}
struct arr__arr__arr__char slice__arr__arr__arr__char__arr__arr__arr__char__nat__nat(struct ctx* ctx, struct arr__arr__arr__char a, uint64_t begin, uint64_t size) {
	assert___void__bool(ctx, _op_less_equal__bool__nat__nat(_op_plus__nat__nat__nat(ctx, begin, size), a.size));
	return (struct arr__arr__arr__char) {size, (a.data + begin)};
}
struct opt__nat index_of__opt__nat__arr__arr__char__arr__char(struct ctx* ctx, struct arr__arr__char a, struct arr__char value) {
	struct index_of__opt__nat__arr__arr__char__arr__char__lambda0___closure* temp0;
	return find_index__opt__nat__arr__arr__char__fun_mut1__bool__arr__char(ctx, a, (struct fun_mut1__bool__arr__char) {(fun_ptr3__bool__ptr_ctx__ptr__byte__arr__char) index_of__opt__nat__arr__arr__char__arr__char__lambda0, (uint8_t*) (temp0 = (struct index_of__opt__nat__arr__arr__char__arr__char__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct index_of__opt__nat__arr__arr__char__arr__char__lambda0___closure)), ((*(temp0) = (struct index_of__opt__nat__arr__arr__char__arr__char__lambda0___closure) {value}, 0), temp0))});
}
uint8_t index_of__opt__nat__arr__arr__char__arr__char__lambda0(struct ctx* ctx, struct index_of__opt__nat__arr__arr__char__arr__char__lambda0___closure* _closure, struct arr__char it) {
	return _op_equal_equal__bool__arr__char__arr__char(it, _closure->value);
}
uint8_t set___void__ptr_cell__bool__bool(struct cell__bool* c, uint8_t v) {
	return (c->value = v, 0);
}
struct arr__char _op_plus__arr__char__arr__char__arr__char(struct ctx* ctx, struct arr__char a, struct arr__char b) {
	struct _op_plus__arr__char__arr__char__arr__char__lambda0___closure* temp0;
	return make_arr__arr__char__nat__fun_mut1__char__nat(ctx, _op_plus__nat__nat__nat(ctx, a.size, b.size), (struct fun_mut1__char__nat) {(fun_ptr3__char__ptr_ctx__ptr__byte__nat) _op_plus__arr__char__arr__char__arr__char__lambda0, (uint8_t*) (temp0 = (struct _op_plus__arr__char__arr__char__arr__char__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct _op_plus__arr__char__arr__char__arr__char__lambda0___closure)), ((*(temp0) = (struct _op_plus__arr__char__arr__char__arr__char__lambda0___closure) {a, b}, 0), temp0))});
}
struct arr__char make_arr__arr__char__nat__fun_mut1__char__nat(struct ctx* ctx, uint64_t size, struct fun_mut1__char__nat f) {
	return freeze__arr__char__ptr_mut_arr__char(make_mut_arr__ptr_mut_arr__char__nat__fun_mut1__char__nat(ctx, size, f));
}
struct arr__char freeze__arr__char__ptr_mut_arr__char(struct mut_arr__char* a) {
	(a->frozen__q = 1, 0);
	return unsafe_as_arr__arr__char__ptr_mut_arr__char(a);
}
struct arr__char unsafe_as_arr__arr__char__ptr_mut_arr__char(struct mut_arr__char* a) {
	return (struct arr__char) {a->size, a->data};
}
struct mut_arr__char* make_mut_arr__ptr_mut_arr__char__nat__fun_mut1__char__nat(struct ctx* ctx, uint64_t size, struct fun_mut1__char__nat f) {
	struct mut_arr__char* res;
	res = new_uninitialized_mut_arr__ptr_mut_arr__char__nat(ctx, size);
	make_mut_arr_worker___void__ptr_mut_arr__char__nat__fun_mut1__char__nat(ctx, res, 0, f);
	return res;
}
struct mut_arr__char* new_uninitialized_mut_arr__ptr_mut_arr__char__nat(struct ctx* ctx, uint64_t size) {
	struct mut_arr__char* temp0;
	temp0 = (struct mut_arr__char*) alloc__ptr__byte__nat(ctx, sizeof(struct mut_arr__char));
	(*(temp0) = (struct mut_arr__char) {0, size, size, uninitialized_data__ptr__char__nat(ctx, size)}, 0);
	return temp0;
}
char* uninitialized_data__ptr__char__nat(struct ctx* ctx, uint64_t size) {
	uint8_t* bptr;
	bptr = alloc__ptr__byte__nat(ctx, (size * sizeof(char)));
	return (char*) bptr;
}
uint8_t make_mut_arr_worker___void__ptr_mut_arr__char__nat__fun_mut1__char__nat(struct ctx* ctx, struct mut_arr__char* m, uint64_t i, struct fun_mut1__char__nat f) {
	struct ctx* _tailCallctx;
	struct mut_arr__char* _tailCallm;
	uint64_t _tailCalli;
	struct fun_mut1__char__nat _tailCallf;
	top:
	if (_op_equal_equal__bool__nat__nat(i, m->size)) {
		return 0;
	} else {
		set_at___void__ptr_mut_arr__char__nat__char(ctx, m, i, call__char__fun_mut1__char__nat__nat(ctx, f, i));
		_tailCallctx = ctx;
		_tailCallm = m;
		_tailCalli = incr__nat__nat(ctx, i);
		_tailCallf = f;
		ctx = _tailCallctx;
		m = _tailCallm;
		i = _tailCalli;
		f = _tailCallf;
		goto top;
	}
}
uint8_t set_at___void__ptr_mut_arr__char__nat__char(struct ctx* ctx, struct mut_arr__char* a, uint64_t index, char value) {
	assert___void__bool(ctx, _op_less__bool__nat__nat(index, a->size));
	return noctx_set_at___void__ptr_mut_arr__char__nat__char(a, index, value);
}
uint8_t noctx_set_at___void__ptr_mut_arr__char__nat__char(struct mut_arr__char* a, uint64_t index, char value) {
	hard_assert___void__bool(_op_less__bool__nat__nat(index, a->size));
	return (*((a->data + index)) = value, 0);
}
char call__char__fun_mut1__char__nat__nat(struct ctx* ctx, struct fun_mut1__char__nat f, uint64_t p0) {
	return call_with_ctx__char__ptr_ctx__fun_mut1__char__nat__nat(ctx, f, p0);
}
char call_with_ctx__char__ptr_ctx__fun_mut1__char__nat__nat(struct ctx* c, struct fun_mut1__char__nat f, uint64_t p0) {
	return f.fun_ptr(c, f.closure, p0);
}
char _op_plus__arr__char__arr__char__arr__char__lambda0(struct ctx* ctx, struct _op_plus__arr__char__arr__char__arr__char__lambda0___closure* _closure, uint64_t i) {
	if (_op_less__bool__nat__nat(i, _closure->a.size)) {
		return at__char__arr__char__nat(ctx, _closure->a, i);
	} else {
		return at__char__arr__char__nat(ctx, _closure->b, _op_minus__nat__nat__nat(ctx, i, _closure->a.size));
	}
}
struct opt__arr__arr__char at__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char__nat(struct ctx* ctx, struct mut_arr__opt__arr__arr__char* a, uint64_t index) {
	assert___void__bool(ctx, _op_less__bool__nat__nat(index, a->size));
	return noctx_at__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char__nat(a, index);
}
struct opt__arr__arr__char noctx_at__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char__nat(struct mut_arr__opt__arr__arr__char* a, uint64_t index) {
	hard_assert___void__bool(_op_less__bool__nat__nat(index, a->size));
	return (*((a->data + index)));
}
uint8_t parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char__lambda0(struct ctx* ctx, struct parse_cmd_line_args__opt__test_options__arr__arr__char__arr__arr__char__fun1__test_options__arr__opt__arr__arr__char__lambda0___closure* _closure, struct arr__char key, struct arr__arr__char value) {
	struct some__nat s;
	uint64_t idx;
	struct opt__nat matched;
	matched = index_of__opt__nat__arr__arr__char__arr__char(ctx, _closure->t_names, key);
	switch (matched.kind) {
		case 0:
			if (_op_equal_equal__bool__arr__char__arr__char(key, (struct arr__char) {4, "help"})) {
				return set___void__ptr_cell__bool__bool(_closure->help, 1);
			} else {
				return fail___void__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, (struct arr__char) {15, "Unexpected arg "}, key));
			}
		case 1:
			s = matched.as1;
			idx = s.value;
			forbid___void__bool(ctx, has__q__bool__opt__arr__arr__char(at__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char__nat(ctx, _closure->values, idx)));
			return set_at___void__ptr_mut_arr__opt__arr__arr__char__nat__opt__arr__arr__char(ctx, _closure->values, idx, (struct opt__arr__arr__char) {1, .as1 = some__some__arr__arr__char__arr__arr__char(value)});
		default:
			return (assert(0),0);
	}
}
uint8_t get__bool__ptr_cell__bool(struct cell__bool* c) {
	return c->value;
}
struct some__test_options some__some__test_options__test_options(struct test_options t) {
	return (struct some__test_options) {t};
}
struct test_options call__test_options__fun1__test_options__arr__opt__arr__arr__char__arr__opt__arr__arr__char(struct ctx* ctx, struct fun1__test_options__arr__opt__arr__arr__char f, struct arr__opt__arr__arr__char p0) {
	return call_with_ctx__test_options__ptr_ctx__fun1__test_options__arr__opt__arr__arr__char__arr__opt__arr__arr__char(ctx, f, p0);
}
struct test_options call_with_ctx__test_options__ptr_ctx__fun1__test_options__arr__opt__arr__arr__char__arr__opt__arr__arr__char(struct ctx* c, struct fun1__test_options__arr__opt__arr__arr__char f, struct arr__opt__arr__arr__char p0) {
	return f.fun_ptr(c, f.closure, p0);
}
struct arr__opt__arr__arr__char freeze__arr__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char(struct mut_arr__opt__arr__arr__char* a) {
	(a->frozen__q = 1, 0);
	return unsafe_as_arr__arr__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char(a);
}
struct arr__opt__arr__arr__char unsafe_as_arr__arr__opt__arr__arr__char__ptr_mut_arr__opt__arr__arr__char(struct mut_arr__opt__arr__arr__char* a) {
	return (struct arr__opt__arr__arr__char) {a->size, a->data};
}
struct opt__arr__arr__char at__opt__arr__arr__char__arr__opt__arr__arr__char__nat(struct ctx* ctx, struct arr__opt__arr__arr__char a, uint64_t index) {
	assert___void__bool(ctx, _op_less__bool__nat__nat(index, a.size));
	return noctx_at__opt__arr__arr__char__arr__opt__arr__arr__char__nat(a, index);
}
struct opt__arr__arr__char noctx_at__opt__arr__arr__char__arr__opt__arr__arr__char__nat(struct arr__opt__arr__arr__char a, uint64_t index) {
	hard_assert___void__bool(_op_less__bool__nat__nat(index, a.size));
	return (*((a.data + index)));
}
uint64_t literal__nat__arr__char(struct ctx* ctx, struct arr__char s) {
	uint64_t higher_digits;
	if (empty__q__bool__arr__char(s)) {
		return 0;
	} else {
		higher_digits = literal__nat__arr__char(ctx, rtail__arr__char__arr__char(ctx, s));
		return _op_plus__nat__nat__nat(ctx, _op_times__nat__nat__nat(ctx, higher_digits, ten__nat()), char_to_nat__nat__char(last__char__arr__char(ctx, s)));
	}
}
struct arr__char rtail__arr__char__arr__char(struct ctx* ctx, struct arr__char a) {
	forbid___void__bool(ctx, empty__q__bool__arr__char(a));
	return slice__arr__char__arr__char__nat__nat(ctx, a, 0, decr__nat__nat(ctx, a.size));
}
uint64_t char_to_nat__nat__char(char c) {
	if (_op_equal_equal__bool__char__char(c, literal__char__arr__char((struct arr__char) {1, "0"}))) {
		return 0;
	} else {
		if (_op_equal_equal__bool__char__char(c, literal__char__arr__char((struct arr__char) {1, "1"}))) {
			return 1;
		} else {
			if (_op_equal_equal__bool__char__char(c, literal__char__arr__char((struct arr__char) {1, "2"}))) {
				return two__nat();
			} else {
				if (_op_equal_equal__bool__char__char(c, literal__char__arr__char((struct arr__char) {1, "3"}))) {
					return three__nat();
				} else {
					if (_op_equal_equal__bool__char__char(c, literal__char__arr__char((struct arr__char) {1, "4"}))) {
						return four__nat();
					} else {
						if (_op_equal_equal__bool__char__char(c, literal__char__arr__char((struct arr__char) {1, "5"}))) {
							return five__nat();
						} else {
							if (_op_equal_equal__bool__char__char(c, literal__char__arr__char((struct arr__char) {1, "6"}))) {
								return six__nat();
							} else {
								if (_op_equal_equal__bool__char__char(c, literal__char__arr__char((struct arr__char) {1, "7"}))) {
									return seven__nat();
								} else {
									if (_op_equal_equal__bool__char__char(c, literal__char__arr__char((struct arr__char) {1, "8"}))) {
										return eight__nat();
									} else {
										if (_op_equal_equal__bool__char__char(c, literal__char__arr__char((struct arr__char) {1, "9"}))) {
											return nine__nat();
										} else {
											return todo__nat();
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
uint64_t todo__nat() {
	return (assert(0),0);
}
char last__char__arr__char(struct ctx* ctx, struct arr__char a) {
	forbid___void__bool(ctx, empty__q__bool__arr__char(a));
	return at__char__arr__char__nat(ctx, a, decr__nat__nat(ctx, a.size));
}
struct test_options main__ptr_fut__int32__arr__arr__char__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr__opt__arr__arr__char values) {
	struct opt__arr__arr__char print_tests_strs;
	struct opt__arr__arr__char overwrite_output_strs;
	struct opt__arr__arr__char max_failures_strs;
	uint8_t print_tests__q;
	struct some__arr__arr__char s;
	struct opt__arr__arr__char matched;
	uint8_t overwrite_output__q;
	struct some__arr__arr__char s1;
	struct arr__arr__char strs;
	struct opt__arr__arr__char matched1;
	uint64_t max_failures;
	print_tests_strs = at__opt__arr__arr__char__arr__opt__arr__arr__char__nat(ctx, values, literal__nat__arr__char(ctx, (struct arr__char) {1, "0"}));
	overwrite_output_strs = at__opt__arr__arr__char__arr__opt__arr__arr__char__nat(ctx, values, literal__nat__arr__char(ctx, (struct arr__char) {1, "1"}));
	max_failures_strs = at__opt__arr__arr__char__arr__opt__arr__arr__char__nat(ctx, values, literal__nat__arr__char(ctx, (struct arr__char) {1, "2"}));
	print_tests__q = has__q__bool__opt__arr__arr__char(print_tests_strs);
	overwrite_output__q = (matched = overwrite_output_strs, matched.kind == 0 ? 0 : matched.kind == 1 ? (s = matched.as1, (assert___void__bool(ctx, empty__q__bool__arr__arr__char(s.value)), 1)) : (assert(0),0));
	max_failures = (matched1 = max_failures_strs, matched1.kind == 0 ? literal__nat__arr__char(ctx, (struct arr__char) {3, "100"}) : matched1.kind == 1 ? (s1 = matched1.as1, (strs = s1.value, (assert___void__bool(ctx, _op_equal_equal__bool__nat__nat(strs.size, literal__nat__arr__char(ctx, (struct arr__char) {1, "1"}))), literal__nat__arr__char(ctx, first__arr__char__arr__arr__char(ctx, strs))))) : (assert(0),0));
	return (struct test_options) {print_tests__q, overwrite_output__q, max_failures};
}
struct fut__int32* resolved__ptr_fut__int32__int32(struct ctx* ctx, int32_t value) {
	struct fut__int32* temp0;
	temp0 = (struct fut__int32*) alloc__ptr__byte__nat(ctx, sizeof(struct fut__int32));
	(*(temp0) = (struct fut__int32) {new_lock__lock(), (struct fut_state__int32) {1, .as1 = (struct fut_state_resolved__int32) {value}}}, 0);
	return temp0;
}
uint8_t print_help___void(struct ctx* ctx) {
	print_sync___void__arr__char((struct arr__char) {18, "test -- runs tests"});
	print_sync___void__arr__char((struct arr__char) {8, "options:"});
	print_sync___void__arr__char((struct arr__char) {38, "\t--print-tests  : print every test run"});
	return print_sync___void__arr__char((struct arr__char) {64, "\t--max-failures : stop after this many failures. Defaults to 10."});
}
uint8_t print_sync___void__arr__char(struct arr__char s) {
	print_sync_no_newline___void__arr__char(s);
	return print_sync_no_newline___void__arr__char((struct arr__char) {1, "\n"});
}
uint8_t print_sync_no_newline___void__arr__char(struct arr__char s) {
	return write_sync_no_newline___void__int32__arr__char(stdout_fd__int32(), s);
}
int32_t stdout_fd__int32() {
	return 1;
}
int32_t literal__int32__arr__char(struct ctx* ctx, struct arr__char s) {
	return literal___int__arr__char(ctx, s);
}
int64_t literal___int__arr__char(struct ctx* ctx, struct arr__char s) {
	char fst;
	uint64_t n;
	fst = at__char__arr__char__nat(ctx, s, 0);
	if (_op_equal_equal__bool__char__char(fst, literal__char__arr__char((struct arr__char) {1, "-"}))) {
		n = literal__nat__arr__char(ctx, tail__arr__char__arr__char(ctx, s));
		return neg___int__nat(ctx, n);
	} else {
		if (_op_equal_equal__bool__char__char(fst, literal__char__arr__char((struct arr__char) {1, "+"}))) {
			return to_int___int__nat(ctx, literal__nat__arr__char(ctx, tail__arr__char__arr__char(ctx, s)));
		} else {
			return to_int___int__nat(ctx, literal__nat__arr__char(ctx, s));
		}
	}
}
int64_t neg___int__nat(struct ctx* ctx, uint64_t n) {
	return neg___int___int(ctx, to_int___int__nat(ctx, n));
}
int64_t neg___int___int(struct ctx* ctx, int64_t i) {
	return _op_times___int___int___int(ctx, i, neg_one___int());
}
int64_t _op_times___int___int___int(struct ctx* ctx, int64_t a, int64_t b) {
	assert___void__bool(ctx, _op_greater__bool___int___int(a, neg_million___int()));
	assert___void__bool(ctx, _op_less__bool___int___int(a, million___int()));
	assert___void__bool(ctx, _op_greater__bool___int___int(b, neg_million___int()));
	assert___void__bool(ctx, _op_less__bool___int___int(b, million___int()));
	return (a * b);
}
uint8_t _op_greater__bool___int___int(int64_t a, int64_t b) {
	return !_op_less_equal__bool___int___int(a, b);
}
uint8_t _op_less_equal__bool___int___int(int64_t a, int64_t b) {
	return !_op_less__bool___int___int(b, a);
}
uint8_t _op_less__bool___int___int(int64_t a, int64_t b) {
	struct comparison matched;
	matched = _op_less_equal_greater__comparison___int___int(a, b);
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
int64_t neg_million___int() {
	return (million___int() * neg_one___int());
}
int64_t million___int() {
	return (thousand___int() * thousand___int());
}
int64_t thousand___int() {
	return (hundred___int() * ten___int());
}
int64_t hundred___int() {
	return (ten___int() * ten___int());
}
int64_t ten___int() {
	return wrap_incr___int___int(nine___int());
}
int64_t wrap_incr___int___int(int64_t a) {
	return (a + 1);
}
int64_t nine___int() {
	return wrap_incr___int___int(eight___int());
}
int64_t eight___int() {
	return wrap_incr___int___int(seven___int());
}
int64_t seven___int() {
	return wrap_incr___int___int(six___int());
}
int64_t six___int() {
	return wrap_incr___int___int(five___int());
}
int64_t five___int() {
	return wrap_incr___int___int(four___int());
}
int64_t four___int() {
	return wrap_incr___int___int(three___int());
}
int64_t three___int() {
	return wrap_incr___int___int(two___int());
}
int64_t two___int() {
	return wrap_incr___int___int(1);
}
int64_t neg_one___int() {
	return (0 - 1);
}
int64_t to_int___int__nat(struct ctx* ctx, uint64_t n) {
	assert___void__bool(ctx, _op_less__bool__nat__nat(n, million__nat()));
	return n;
}
int32_t do_test__int32__test_options(struct ctx* ctx, struct test_options options) {
	struct arr__char test_path;
	struct arr__char noze_path;
	struct arr__char noze_exe;
	struct dict__arr__char__arr__char* env;
	struct result__arr__char__arr__ptr_failure compile_failures;
	struct result__arr__char__arr__ptr_failure run_failures;
	struct result__arr__char__arr__ptr_failure all_failures;
	struct do_test__int32__test_options__lambda0___closure* temp0;
	struct do_test__int32__test_options__lambda1___closure* temp1;
	test_path = parent_path__arr__char__arr__char(ctx, current_executable_path__arr__char(ctx));
	noze_path = parent_path__arr__char__arr__char(ctx, test_path);
	noze_exe = child_path__arr__char__arr__char__arr__char(ctx, noze_path, (struct arr__char) {4, "noze"});
	env = get_environ__ptr_dict__arr__char__arr__char(ctx);
	compile_failures = run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options(ctx, child_path__arr__char__arr__char__arr__char(ctx, test_path, (struct arr__char) {14, "compile-errors"}), noze_exe, env, options);
	run_failures = first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure(ctx, compile_failures, (struct fun0__result__arr__char__arr__ptr_failure) {(fun_ptr2__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte) do_test__int32__test_options__lambda0, (uint8_t*) (temp0 = (struct do_test__int32__test_options__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct do_test__int32__test_options__lambda0___closure)), ((*(temp0) = (struct do_test__int32__test_options__lambda0___closure) {test_path, noze_exe, env, options}, 0), temp0))});
	all_failures = first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure(ctx, run_failures, (struct fun0__result__arr__char__arr__ptr_failure) {(fun_ptr2__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte) do_test__int32__test_options__lambda1, (uint8_t*) (temp1 = (struct do_test__int32__test_options__lambda1___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct do_test__int32__test_options__lambda1___closure)), ((*(temp1) = (struct do_test__int32__test_options__lambda1___closure) {noze_path, options}, 0), temp1))});
	return print_failures__int32__result__arr__char__arr__ptr_failure__test_options(ctx, all_failures, options);
}
struct arr__char parent_path__arr__char__arr__char(struct ctx* ctx, struct arr__char a) {
	struct some__nat s;
	struct opt__nat matched;
	matched = r_index_of__opt__nat__arr__char__char(ctx, a, literal__char__arr__char((struct arr__char) {1, "/"}));
	switch (matched.kind) {
		case 0:
			return (struct arr__char) {0, ""};
		case 1:
			s = matched.as1;
			return slice_up_to__arr__char__arr__char__nat(ctx, a, s.value);
		default:
			return (assert(0),(struct arr__char) {0, NULL});
	}
}
struct opt__nat r_index_of__opt__nat__arr__char__char(struct ctx* ctx, struct arr__char a, char value) {
	struct r_index_of__opt__nat__arr__char__char__lambda0___closure* temp0;
	return find_rindex__opt__nat__arr__char__fun_mut1__bool__char(ctx, a, (struct fun_mut1__bool__char) {(fun_ptr3__bool__ptr_ctx__ptr__byte__char) r_index_of__opt__nat__arr__char__char__lambda0, (uint8_t*) (temp0 = (struct r_index_of__opt__nat__arr__char__char__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct r_index_of__opt__nat__arr__char__char__lambda0___closure)), ((*(temp0) = (struct r_index_of__opt__nat__arr__char__char__lambda0___closure) {value}, 0), temp0))});
}
struct opt__nat find_rindex__opt__nat__arr__char__fun_mut1__bool__char(struct ctx* ctx, struct arr__char a, struct fun_mut1__bool__char pred) {
	if (empty__q__bool__arr__char(a)) {
		return (struct opt__nat) {0, .as0 = none__none()};
	} else {
		return find_rindex_recur__opt__nat__arr__char__nat__fun_mut1__bool__char(ctx, a, decr__nat__nat(ctx, a.size), pred);
	}
}
struct opt__nat find_rindex_recur__opt__nat__arr__char__nat__fun_mut1__bool__char(struct ctx* ctx, struct arr__char a, uint64_t index, struct fun_mut1__bool__char pred) {
	struct ctx* _tailCallctx;
	struct arr__char _tailCalla;
	uint64_t _tailCallindex;
	struct fun_mut1__bool__char _tailCallpred;
	top:
	if (call__bool__fun_mut1__bool__char__char(ctx, pred, at__char__arr__char__nat(ctx, a, index))) {
		return (struct opt__nat) {1, .as1 = some__some__nat__nat(index)};
	} else {
		if (zero__q__bool__nat(index)) {
			return (struct opt__nat) {0, .as0 = none__none()};
		} else {
			_tailCallctx = ctx;
			_tailCalla = a;
			_tailCallindex = decr__nat__nat(ctx, index);
			_tailCallpred = pred;
			ctx = _tailCallctx;
			a = _tailCalla;
			index = _tailCallindex;
			pred = _tailCallpred;
			goto top;
		}
	}
}
uint8_t call__bool__fun_mut1__bool__char__char(struct ctx* ctx, struct fun_mut1__bool__char f, char p0) {
	return call_with_ctx__bool__ptr_ctx__fun_mut1__bool__char__char(ctx, f, p0);
}
uint8_t call_with_ctx__bool__ptr_ctx__fun_mut1__bool__char__char(struct ctx* c, struct fun_mut1__bool__char f, char p0) {
	return f.fun_ptr(c, f.closure, p0);
}
uint8_t r_index_of__opt__nat__arr__char__char__lambda0(struct ctx* ctx, struct r_index_of__opt__nat__arr__char__char__lambda0___closure* _closure, char it) {
	return _op_equal_equal__bool__char__char(it, _closure->value);
}
struct arr__char slice_up_to__arr__char__arr__char__nat(struct ctx* ctx, struct arr__char a, uint64_t size) {
	assert___void__bool(ctx, _op_less__bool__nat__nat(size, a.size));
	return slice__arr__char__arr__char__nat__nat(ctx, a, 0, size);
}
struct arr__char current_executable_path__arr__char(struct ctx* ctx) {
	return read_link__arr__char__arr__char(ctx, (struct arr__char) {14, "/proc/self/exe"});
}
struct arr__char read_link__arr__char__arr__char(struct ctx* ctx, struct arr__char path) {
	struct mut_arr__char* buff;
	int64_t size;
	buff = new_uninitialized_mut_arr__ptr_mut_arr__char__nat(ctx, thousand__nat());
	size = readlink(to_c_str__ptr__char__arr__char(ctx, path), buff->data, buff->size);
	check_errno_if_neg_one___void___int(ctx, size);
	return slice_up_to__arr__char__arr__char__nat(ctx, freeze__arr__char__ptr_mut_arr__char(buff), to_nat__nat___int(ctx, size));
}
char* to_c_str__ptr__char__arr__char(struct ctx* ctx, struct arr__char a) {
	return _op_plus__arr__char__arr__char__arr__char(ctx, a, (struct arr__char) {1, "\0"}).data;
}
uint8_t check_errno_if_neg_one___void___int(struct ctx* ctx, int64_t e) {
	if (_op_equal_equal__bool___int___int(e, neg_one___int())) {
		check_posix_error___void__int32(ctx, errno);
		return hard_unreachable___void();
	} else {
		return 0;
	}
}
uint8_t check_posix_error___void__int32(struct ctx* ctx, int32_t e) {
	return assert___void__bool(ctx, zero__q__bool__int32(e));
}
uint8_t hard_unreachable___void() {
	return (assert(0),0);
}
uint64_t to_nat__nat___int(struct ctx* ctx, int64_t i) {
	forbid___void__bool(ctx, negative__q__bool___int(ctx, i));
	return i;
}
uint8_t negative__q__bool___int(struct ctx* ctx, int64_t i) {
	return _op_less__bool___int___int(i, 0);
}
struct arr__char child_path__arr__char__arr__char__arr__char(struct ctx* ctx, struct arr__char a, struct arr__char child_name) {
	return _op_plus__arr__char__arr__char__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, a, (struct arr__char) {1, "/"}), child_name);
}
struct dict__arr__char__arr__char* get_environ__ptr_dict__arr__char__arr__char(struct ctx* ctx) {
	struct mut_dict__arr__char__arr__char res;
	res = new_mut_dict__mut_dict__arr__char__arr__char(ctx);
	get_environ_recur___void__ptr__ptr__char__mut_dict__arr__char__arr__char(ctx, environ, res);
	return freeze__ptr_dict__arr__char__arr__char__mut_dict__arr__char__arr__char(ctx, res);
}
struct mut_dict__arr__char__arr__char new_mut_dict__mut_dict__arr__char__arr__char(struct ctx* ctx) {
	return (struct mut_dict__arr__char__arr__char) {new_mut_arr__ptr_mut_arr__arr__char(ctx), new_mut_arr__ptr_mut_arr__arr__char(ctx)};
}
uint8_t get_environ_recur___void__ptr__ptr__char__mut_dict__arr__char__arr__char(struct ctx* ctx, char** env, struct mut_dict__arr__char__arr__char res) {
	struct ctx* _tailCallctx;
	char** _tailCallenv;
	struct mut_dict__arr__char__arr__char _tailCallres;
	top:
	if (null__q__bool__ptr__char((*(env)))) {
		return 0;
	} else {
		add___void__mut_dict__arr__char__arr__char__ptr_key_value_pair__arr__char__arr__char(ctx, res, parse_environ_entry__ptr_key_value_pair__arr__char__arr__char__ptr__char(ctx, (*(env))));
		_tailCallctx = ctx;
		_tailCallenv = incr__ptr__ptr__char__ptr__ptr__char(env);
		_tailCallres = res;
		ctx = _tailCallctx;
		env = _tailCallenv;
		res = _tailCallres;
		goto top;
	}
}
uint8_t null__q__bool__ptr__char(char* a) {
	return _op_equal_equal__bool__ptr__char__ptr__char(a, NULL);
}
uint8_t _op_equal_equal__bool__ptr__char__ptr__char(char* a, char* b) {
	struct comparison matched;
	matched = _op_less_equal_greater__comparison__ptr__char__ptr__char(a, b);
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
struct comparison _op_less_equal_greater__comparison__ptr__char__ptr__char(char* a, char* b) {
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
uint8_t add___void__mut_dict__arr__char__arr__char__ptr_key_value_pair__arr__char__arr__char(struct ctx* ctx, struct mut_dict__arr__char__arr__char m, struct key_value_pair__arr__char__arr__char* pair) {
	return add___void__mut_dict__arr__char__arr__char__arr__char__arr__char(ctx, m, pair->key, pair->value);
}
uint8_t add___void__mut_dict__arr__char__arr__char__arr__char__arr__char(struct ctx* ctx, struct mut_dict__arr__char__arr__char m, struct arr__char key, struct arr__char value) {
	forbid___void__bool(ctx, has__q__bool__mut_dict__arr__char__arr__char__arr__char(ctx, m, key));
	push___void__ptr_mut_arr__arr__char__arr__char(ctx, m.keys, key);
	return push___void__ptr_mut_arr__arr__char__arr__char(ctx, m.values, value);
}
uint8_t has__q__bool__mut_dict__arr__char__arr__char__arr__char(struct ctx* ctx, struct mut_dict__arr__char__arr__char d, struct arr__char key) {
	return has__q__bool__ptr_dict__arr__char__arr__char__arr__char(ctx, unsafe_as_dict__ptr_dict__arr__char__arr__char__mut_dict__arr__char__arr__char(ctx, d), key);
}
uint8_t has__q__bool__ptr_dict__arr__char__arr__char__arr__char(struct ctx* ctx, struct dict__arr__char__arr__char* d, struct arr__char key) {
	return has__q__bool__opt__arr__char(get__opt__arr__char__ptr_dict__arr__char__arr__char__arr__char(ctx, d, key));
}
uint8_t has__q__bool__opt__arr__char(struct opt__arr__char a) {
	return !empty__q__bool__opt__arr__char(a);
}
uint8_t empty__q__bool__opt__arr__char(struct opt__arr__char a) {
	struct none n;
	struct some__arr__char s;
	struct opt__arr__char matched;
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
struct opt__arr__char get__opt__arr__char__ptr_dict__arr__char__arr__char__arr__char(struct ctx* ctx, struct dict__arr__char__arr__char* d, struct arr__char key) {
	return get_recursive__opt__arr__char__arr__arr__char__arr__arr__char__nat__arr__char(ctx, d->keys, d->values, 0, key);
}
struct opt__arr__char get_recursive__opt__arr__char__arr__arr__char__arr__arr__char__nat__arr__char(struct ctx* ctx, struct arr__arr__char keys, struct arr__arr__char values, uint64_t idx, struct arr__char key) {
	struct ctx* _tailCallctx;
	struct arr__arr__char _tailCallkeys;
	struct arr__arr__char _tailCallvalues;
	uint64_t _tailCallidx;
	struct arr__char _tailCallkey;
	top:
	if (_op_equal_equal__bool__nat__nat(idx, keys.size)) {
		return (struct opt__arr__char) {0, .as0 = none__none()};
	} else {
		if (_op_equal_equal__bool__arr__char__arr__char(key, at__arr__char__arr__arr__char__nat(ctx, keys, idx))) {
			return (struct opt__arr__char) {1, .as1 = some__some__arr__char__arr__char(at__arr__char__arr__arr__char__nat(ctx, values, idx))};
		} else {
			_tailCallctx = ctx;
			_tailCallkeys = keys;
			_tailCallvalues = values;
			_tailCallidx = incr__nat__nat(ctx, idx);
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
struct dict__arr__char__arr__char* unsafe_as_dict__ptr_dict__arr__char__arr__char__mut_dict__arr__char__arr__char(struct ctx* ctx, struct mut_dict__arr__char__arr__char m) {
	struct dict__arr__char__arr__char* temp0;
	temp0 = (struct dict__arr__char__arr__char*) alloc__ptr__byte__nat(ctx, sizeof(struct dict__arr__char__arr__char));
	(*(temp0) = (struct dict__arr__char__arr__char) {unsafe_as_arr__arr__arr__char__ptr_mut_arr__arr__char(m.keys), unsafe_as_arr__arr__arr__char__ptr_mut_arr__arr__char(m.values)}, 0);
	return temp0;
}
struct key_value_pair__arr__char__arr__char* parse_environ_entry__ptr_key_value_pair__arr__char__arr__char__ptr__char(struct ctx* ctx, char* entry) {
	char* key_end;
	struct arr__char key;
	char* value_begin;
	char* value_end;
	struct arr__char value;
	struct key_value_pair__arr__char__arr__char* temp0;
	key_end = find_char_in_cstr__ptr__char__ptr__char__char(entry, literal__char__arr__char((struct arr__char) {1, "="}));
	key = arr_from_begin_end__arr__char__ptr__char__ptr__char(entry, key_end);
	value_begin = incr__ptr__char__ptr__char(key_end);
	value_end = find_cstr_end__ptr__char__ptr__char(value_begin);
	value = arr_from_begin_end__arr__char__ptr__char__ptr__char(value_begin, value_end);
	temp0 = (struct key_value_pair__arr__char__arr__char*) alloc__ptr__byte__nat(ctx, sizeof(struct key_value_pair__arr__char__arr__char));
	(*(temp0) = (struct key_value_pair__arr__char__arr__char) {key, value}, 0);
	return temp0;
}
char** incr__ptr__ptr__char__ptr__ptr__char(char** p) {
	return (p + 1);
}
struct dict__arr__char__arr__char* freeze__ptr_dict__arr__char__arr__char__mut_dict__arr__char__arr__char(struct ctx* ctx, struct mut_dict__arr__char__arr__char m) {
	struct dict__arr__char__arr__char* temp0;
	temp0 = (struct dict__arr__char__arr__char*) alloc__ptr__byte__nat(ctx, sizeof(struct dict__arr__char__arr__char));
	(*(temp0) = (struct dict__arr__char__arr__char) {freeze__arr__arr__char__ptr_mut_arr__arr__char(m.keys), freeze__arr__arr__char__ptr_mut_arr__arr__char(m.values)}, 0);
	return temp0;
}
struct result__arr__char__arr__ptr_failure run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options(struct ctx* ctx, struct arr__char path, struct arr__char path_to_noze, struct dict__arr__char__arr__char* env, struct test_options options) {
	struct arr__arr__char tests;
	struct arr__ptr_failure failures;
	struct run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure* temp0;
	tests = list_compile_error_tests__arr__arr__char__arr__char(ctx, path);
	failures = flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char(ctx, tests, options.max_failures, (struct fun_mut1__arr__ptr_failure__arr__char) {(fun_ptr3__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char) run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0, (uint8_t*) (temp0 = (struct run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure)), ((*(temp0) = (struct run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure) {options, path_to_noze, env}, 0), temp0))});
	if (has__q__bool__arr__ptr_failure(failures)) {
		return (struct result__arr__char__arr__ptr_failure) {1, .as1 = err__err__arr__ptr_failure__arr__ptr_failure(with_max_size__arr__ptr_failure__arr__ptr_failure__nat(ctx, failures, options.max_failures))};
	} else {
		return (struct result__arr__char__arr__ptr_failure) {0, .as0 = ok__ok__arr__char__arr__char(_op_plus__arr__char__arr__char__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, (struct arr__char) {4, "Ran "}, to_str__arr__char__nat(ctx, tests.size)), (struct arr__char) {20, " compile-error tests"}))};
	}
}
struct arr__arr__char list_compile_error_tests__arr__arr__char__arr__char(struct ctx* ctx, struct arr__char path) {
	struct mut_arr__arr__char* res;
	struct fun_mut1__bool__arr__char filter;
	struct list_compile_error_tests__arr__arr__char__arr__char__lambda1___closure* temp0;
	res = new_mut_arr__ptr_mut_arr__arr__char(ctx);
	filter = (struct fun_mut1__bool__arr__char) {(fun_ptr3__bool__ptr_ctx__ptr__byte__arr__char) list_compile_error_tests__arr__arr__char__arr__char__lambda0, (uint8_t*) NULL};
	each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char(ctx, path, filter, (struct fun_mut1___void__arr__char) {(fun_ptr3___void__ptr_ctx__ptr__byte__arr__char) list_compile_error_tests__arr__arr__char__arr__char__lambda1, (uint8_t*) (temp0 = (struct list_compile_error_tests__arr__arr__char__arr__char__lambda1___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct list_compile_error_tests__arr__arr__char__arr__char__lambda1___closure)), ((*(temp0) = (struct list_compile_error_tests__arr__arr__char__arr__char__lambda1___closure) {res}, 0), temp0))});
	return freeze__arr__arr__char__ptr_mut_arr__arr__char(res);
}
uint8_t list_compile_error_tests__arr__arr__char__arr__char__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr__char s) {
	return 1;
}
uint8_t each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char(struct ctx* ctx, struct arr__char path, struct fun_mut1__bool__arr__char filter, struct fun_mut1___void__arr__char f) {
	struct each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0___closure* temp0;
	if (is_dir__q__bool__arr__char(ctx, path)) {
		return each___void__arr__arr__char__fun_mut1___void__arr__char(ctx, read_dir__arr__arr__char__arr__char(ctx, path), (struct fun_mut1___void__arr__char) {(fun_ptr3___void__ptr_ctx__ptr__byte__arr__char) each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0, (uint8_t*) (temp0 = (struct each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0___closure)), ((*(temp0) = (struct each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0___closure) {filter, path, f}, 0), temp0))});
	} else {
		return call___void__fun_mut1___void__arr__char__arr__char(ctx, f, path);
	}
}
uint8_t is_dir__q__bool__arr__char(struct ctx* ctx, struct arr__char path) {
	return is_dir__q__bool__ptr__char(ctx, to_c_str__ptr__char__arr__char(ctx, path));
}
uint8_t is_dir__q__bool__ptr__char(struct ctx* ctx, char* path) {
	struct some__ptr_stat_t s;
	struct opt__ptr_stat_t matched;
	matched = get_stat__opt__ptr_stat_t__ptr__char(ctx, path);
	switch (matched.kind) {
		case 0:
			return todo__bool();
		case 1:
			s = matched.as1;
			return _op_equal_equal__bool__nat32__nat32((s.value->st_mode & s_ifmt__nat32(ctx)), s_ifdir__nat32(ctx));
		default:
			return (assert(0),0);
	}
}
struct opt__ptr_stat_t get_stat__opt__ptr_stat_t__ptr__char(struct ctx* ctx, char* path) {
	struct stat_t* s;
	int32_t err;
	int32_t errno;
	s = empty_stat__ptr_stat_t(ctx);
	err = stat(path, s);
	if (_op_equal_equal__bool__int32__int32(err, 0)) {
		return (struct opt__ptr_stat_t) {1, .as1 = some__some__ptr_stat_t__ptr_stat_t(s)};
	} else {
		assert___void__bool(ctx, _op_equal_equal__bool__int32__int32(err, neg_one__int32()));
		errno = errno;
		if (_op_equal_equal__bool__int32__int32(errno, enoent__int32())) {
			return (struct opt__ptr_stat_t) {0, .as0 = none__none()};
		} else {
			return todo__opt__ptr_stat_t();
		}
	}
}
struct stat_t* empty_stat__ptr_stat_t(struct ctx* ctx) {
	struct stat_t* temp0;
	temp0 = (struct stat_t*) alloc__ptr__byte__nat(ctx, sizeof(struct stat_t));
	(*(temp0) = (struct stat_t) {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, 0);
	return temp0;
}
struct some__ptr_stat_t some__some__ptr_stat_t__ptr_stat_t(struct stat_t* t) {
	return (struct some__ptr_stat_t) {t};
}
int32_t neg_one__int32() {
	return (0 - 1);
}
int32_t enoent__int32() {
	return two__int32();
}
struct opt__ptr_stat_t todo__opt__ptr_stat_t() {
	return (assert(0),(struct opt__ptr_stat_t) {0});
}
uint8_t todo__bool() {
	return (assert(0),0);
}
uint8_t _op_equal_equal__bool__nat32__nat32(uint32_t a, uint32_t b) {
	struct comparison matched;
	matched = _op_less_equal_greater__comparison__nat32__nat32(a, b);
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
struct comparison _op_less_equal_greater__comparison__nat32__nat32(uint32_t a, uint32_t b) {
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
uint32_t s_ifmt__nat32(struct ctx* ctx) {
	return (two_pow__nat32__nat32(twelve__nat32()) * fifteen__nat32());
}
uint32_t two_pow__nat32__nat32(uint32_t pow) {
	if (zero__q__bool__nat32(pow)) {
		return 1;
	} else {
		return (two_pow__nat32__nat32(wrap_decr__nat32__nat32(pow)) * two__nat32());
	}
}
uint8_t zero__q__bool__nat32(uint32_t n) {
	return _op_equal_equal__bool__nat32__nat32(n, 0);
}
uint32_t wrap_decr__nat32__nat32(uint32_t a) {
	return (a - 1);
}
uint32_t two__nat32() {
	return wrap_incr__nat32__nat32(1);
}
uint32_t wrap_incr__nat32__nat32(uint32_t a) {
	return (a + 1);
}
uint32_t twelve__nat32() {
	return (eight__nat32() + four__nat32());
}
uint32_t eight__nat32() {
	return wrap_incr__nat32__nat32(seven__nat32());
}
uint32_t seven__nat32() {
	return wrap_incr__nat32__nat32(six__nat32());
}
uint32_t six__nat32() {
	return wrap_incr__nat32__nat32(five__nat32());
}
uint32_t five__nat32() {
	return wrap_incr__nat32__nat32(four__nat32());
}
uint32_t four__nat32() {
	return wrap_incr__nat32__nat32(three__nat32());
}
uint32_t three__nat32() {
	return wrap_incr__nat32__nat32(two__nat32());
}
uint32_t fifteen__nat32() {
	return wrap_incr__nat32__nat32(fourteen__nat32());
}
uint32_t fourteen__nat32() {
	return (twelve__nat32() + two__nat32());
}
uint32_t s_ifdir__nat32(struct ctx* ctx) {
	return two_pow__nat32__nat32(fourteen__nat32());
}
uint8_t each___void__arr__arr__char__fun_mut1___void__arr__char(struct ctx* ctx, struct arr__arr__char a, struct fun_mut1___void__arr__char f) {
	struct ctx* _tailCallctx;
	struct arr__arr__char _tailCalla;
	struct fun_mut1___void__arr__char _tailCallf;
	top:
	if (empty__q__bool__arr__arr__char(a)) {
		return 0;
	} else {
		call___void__fun_mut1___void__arr__char__arr__char(ctx, f, first__arr__char__arr__arr__char(ctx, a));
		_tailCallctx = ctx;
		_tailCalla = tail__arr__arr__char__arr__arr__char(ctx, a);
		_tailCallf = f;
		ctx = _tailCallctx;
		a = _tailCalla;
		f = _tailCallf;
		goto top;
	}
}
uint8_t call___void__fun_mut1___void__arr__char__arr__char(struct ctx* ctx, struct fun_mut1___void__arr__char f, struct arr__char p0) {
	return call_with_ctx___void__ptr_ctx__fun_mut1___void__arr__char__arr__char(ctx, f, p0);
}
uint8_t call_with_ctx___void__ptr_ctx__fun_mut1___void__arr__char__arr__char(struct ctx* c, struct fun_mut1___void__arr__char f, struct arr__char p0) {
	return f.fun_ptr(c, f.closure, p0);
}
struct arr__arr__char read_dir__arr__arr__char__arr__char(struct ctx* ctx, struct arr__char path) {
	return read_dir__arr__arr__char__ptr__char(ctx, to_c_str__ptr__char__arr__char(ctx, path));
}
struct arr__arr__char read_dir__arr__arr__char__ptr__char(struct ctx* ctx, char* path) {
	uint8_t* dirp;
	struct mut_arr__arr__char* res;
	dirp = opendir(path);
	forbid___void__bool(ctx, null__q__bool__ptr__byte(dirp));
	res = new_mut_arr__ptr_mut_arr__arr__char(ctx);
	read_dir_recur___void__ptr__byte__ptr_mut_arr__arr__char(ctx, dirp, res);
	return sort__arr__arr__char__arr__arr__char(ctx, freeze__arr__arr__char__ptr_mut_arr__arr__char(res));
}
uint8_t read_dir_recur___void__ptr__byte__ptr_mut_arr__arr__char(struct ctx* ctx, uint8_t* dirp, struct mut_arr__arr__char* res) {
	struct dirent* entry;
	struct cell__ptr_dirent* result;
	int32_t err;
	struct arr__char name;
	struct dirent* temp0;
	struct ctx* _tailCallctx;
	uint8_t* _tailCalldirp;
	struct mut_arr__arr__char* _tailCallres;
	top:
	entry = (temp0 = (struct dirent*) alloc__ptr__byte__nat(ctx, sizeof(struct dirent)), ((*(temp0) = (struct dirent) {0, 0, 0, literal__char__arr__char((struct arr__char) {1, "\0"}), zero__bytes256()}, 0), temp0));
	result = new_cell__ptr_cell__ptr_dirent__ptr_dirent(ctx, entry);
	err = readdir_r(dirp, entry, result);
	assert___void__bool(ctx, zero__q__bool__int32(err));
	if (null__q__bool__ptr__byte((uint8_t*) get__ptr_dirent__ptr_cell__ptr_dirent(result))) {
		return 0;
	} else {
		assert___void__bool(ctx, ptr_eq__bool__ptr_dirent__ptr_dirent(get__ptr_dirent__ptr_cell__ptr_dirent(result), entry));
		name = get_dirent_name__arr__char__ptr_dirent(entry);
		if ((_op_equal_equal__bool__arr__char__arr__char(name, (struct arr__char) {1, "."}) || _op_equal_equal__bool__arr__char__arr__char(name, (struct arr__char) {2, ".."}))) {
			0;
		} else {
			push___void__ptr_mut_arr__arr__char__arr__char(ctx, res, get_dirent_name__arr__char__ptr_dirent(entry));
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
struct bytes256 zero__bytes256() {
	return (struct bytes256) {zero__bytes128(), zero__bytes128()};
}
struct cell__ptr_dirent* new_cell__ptr_cell__ptr_dirent__ptr_dirent(struct ctx* ctx, struct dirent* value) {
	struct cell__ptr_dirent* temp0;
	temp0 = (struct cell__ptr_dirent*) alloc__ptr__byte__nat(ctx, sizeof(struct cell__ptr_dirent));
	(*(temp0) = (struct cell__ptr_dirent) {value}, 0);
	return temp0;
}
struct dirent* get__ptr_dirent__ptr_cell__ptr_dirent(struct cell__ptr_dirent* c) {
	return c->value;
}
uint8_t ptr_eq__bool__ptr_dirent__ptr_dirent(struct dirent* a, struct dirent* b) {
	return _op_equal_equal__bool__ptr__byte__ptr__byte((uint8_t*) a, (uint8_t*) b);
}
struct arr__char get_dirent_name__arr__char__ptr_dirent(struct dirent* d) {
	uint64_t name_offset;
	uint8_t* name_ptr;
	name_offset = (((sizeof(uint64_t) + sizeof(int64_t)) + sizeof(uint16_t)) + sizeof(char));
	name_ptr = ((uint8_t*) d + name_offset);
	return to_str__arr__char__ptr__char((char*) name_ptr);
}
struct arr__arr__char sort__arr__arr__char__arr__arr__char(struct ctx* ctx, struct arr__arr__char a) {
	struct mut_arr__arr__char* m;
	m = to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char(ctx, a);
	sort___void__ptr_mut_arr__arr__char(ctx, m);
	return freeze__arr__arr__char__ptr_mut_arr__arr__char(m);
}
struct mut_arr__arr__char* to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char(struct ctx* ctx, struct arr__arr__char a) {
	struct to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char__lambda0___closure* temp0;
	return make_mut_arr__ptr_mut_arr__arr__char__nat__fun_mut1__arr__char__nat(ctx, a.size, (struct fun_mut1__arr__char__nat) {(fun_ptr3__arr__char__ptr_ctx__ptr__byte__nat) to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char__lambda0, (uint8_t*) (temp0 = (struct to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char__lambda0___closure)), ((*(temp0) = (struct to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char__lambda0___closure) {a}, 0), temp0))});
}
struct arr__char to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char__lambda0(struct ctx* ctx, struct to_mut_arr__ptr_mut_arr__arr__char__arr__arr__char__lambda0___closure* _closure, uint64_t i) {
	return at__arr__char__arr__arr__char__nat(ctx, _closure->a, i);
}
uint8_t sort___void__ptr_mut_arr__arr__char(struct ctx* ctx, struct mut_arr__arr__char* a) {
	return sort___void__ptr_mut_slice__arr__char(ctx, to_mut_slice__ptr_mut_slice__arr__char__ptr_mut_arr__arr__char(ctx, a));
}
uint8_t sort___void__ptr_mut_slice__arr__char(struct ctx* ctx, struct mut_slice__arr__char* a) {
	struct arr__char pivot;
	uint64_t index_of_first_value_gt_pivot;
	uint64_t new_pivot_index;
	struct ctx* _tailCallctx;
	struct mut_slice__arr__char* _tailCalla;
	top:
	if (_op_less_equal__bool__nat__nat(a->size, 1)) {
		return 0;
	} else {
		swap___void__ptr_mut_slice__arr__char__nat__nat(ctx, a, 0, _op_div__nat__nat__nat(ctx, a->size, two__nat()));
		pivot = at__arr__char__ptr_mut_slice__arr__char__nat(ctx, a, 0);
		index_of_first_value_gt_pivot = partition_recur__nat__ptr_mut_slice__arr__char__arr__char__nat__nat(ctx, a, pivot, 1, decr__nat__nat(ctx, a->size));
		new_pivot_index = decr__nat__nat(ctx, index_of_first_value_gt_pivot);
		swap___void__ptr_mut_slice__arr__char__nat__nat(ctx, a, 0, new_pivot_index);
		sort___void__ptr_mut_slice__arr__char(ctx, slice__ptr_mut_slice__arr__char__ptr_mut_slice__arr__char__nat__nat(ctx, a, 0, new_pivot_index));
		_tailCallctx = ctx;
		_tailCalla = slice__ptr_mut_slice__arr__char__ptr_mut_slice__arr__char__nat(ctx, a, incr__nat__nat(ctx, new_pivot_index));
		ctx = _tailCallctx;
		a = _tailCalla;
		goto top;
	}
}
uint8_t swap___void__ptr_mut_slice__arr__char__nat__nat(struct ctx* ctx, struct mut_slice__arr__char* a, uint64_t lo, uint64_t hi) {
	struct arr__char old_lo;
	old_lo = at__arr__char__ptr_mut_slice__arr__char__nat(ctx, a, lo);
	set_at___void__ptr_mut_slice__arr__char__nat__arr__char(ctx, a, lo, at__arr__char__ptr_mut_slice__arr__char__nat(ctx, a, hi));
	return set_at___void__ptr_mut_slice__arr__char__nat__arr__char(ctx, a, hi, old_lo);
}
struct arr__char at__arr__char__ptr_mut_slice__arr__char__nat(struct ctx* ctx, struct mut_slice__arr__char* a, uint64_t index) {
	assert___void__bool(ctx, _op_less__bool__nat__nat(index, a->size));
	return at__arr__char__ptr_mut_arr__arr__char__nat(ctx, a->backing, _op_plus__nat__nat__nat(ctx, a->begin, index));
}
struct arr__char at__arr__char__ptr_mut_arr__arr__char__nat(struct ctx* ctx, struct mut_arr__arr__char* a, uint64_t index) {
	assert___void__bool(ctx, _op_less__bool__nat__nat(index, a->size));
	return noctx_at__arr__char__ptr_mut_arr__arr__char__nat(a, index);
}
struct arr__char noctx_at__arr__char__ptr_mut_arr__arr__char__nat(struct mut_arr__arr__char* a, uint64_t index) {
	hard_assert___void__bool(_op_less__bool__nat__nat(index, a->size));
	return (*((a->data + index)));
}
uint8_t set_at___void__ptr_mut_slice__arr__char__nat__arr__char(struct ctx* ctx, struct mut_slice__arr__char* a, uint64_t index, struct arr__char value) {
	assert___void__bool(ctx, _op_less__bool__nat__nat(index, a->size));
	return set_at___void__ptr_mut_arr__arr__char__nat__arr__char(ctx, a->backing, _op_plus__nat__nat__nat(ctx, a->begin, index), value);
}
uint64_t partition_recur__nat__ptr_mut_slice__arr__char__arr__char__nat__nat(struct ctx* ctx, struct mut_slice__arr__char* a, struct arr__char pivot, uint64_t l, uint64_t r) {
	struct arr__char em;
	struct ctx* _tailCallctx;
	struct mut_slice__arr__char* _tailCalla;
	struct arr__char _tailCallpivot;
	uint64_t _tailCalll;
	uint64_t _tailCallr;
	top:
	assert___void__bool(ctx, _op_less_equal__bool__nat__nat(l, a->size));
	assert___void__bool(ctx, _op_less__bool__nat__nat(r, a->size));
	if (_op_less_equal__bool__nat__nat(l, r)) {
		em = at__arr__char__ptr_mut_slice__arr__char__nat(ctx, a, l);
		if (_op_less__bool__arr__char__arr__char(em, pivot)) {
			_tailCallctx = ctx;
			_tailCalla = a;
			_tailCallpivot = pivot;
			_tailCalll = incr__nat__nat(ctx, l);
			_tailCallr = r;
			ctx = _tailCallctx;
			a = _tailCalla;
			pivot = _tailCallpivot;
			l = _tailCalll;
			r = _tailCallr;
			goto top;
		} else {
			swap___void__ptr_mut_slice__arr__char__nat__nat(ctx, a, l, r);
			_tailCallctx = ctx;
			_tailCalla = a;
			_tailCallpivot = pivot;
			_tailCalll = l;
			_tailCallr = decr__nat__nat(ctx, r);
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
uint8_t _op_less__bool__arr__char__arr__char(struct arr__char a, struct arr__char b) {
	struct comparison matched;
	matched = _op_less_equal_greater__comparison__arr__char__arr__char(a, b);
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
struct mut_slice__arr__char* slice__ptr_mut_slice__arr__char__ptr_mut_slice__arr__char__nat__nat(struct ctx* ctx, struct mut_slice__arr__char* a, uint64_t lo, uint64_t size) {
	struct mut_slice__arr__char* temp0;
	assert___void__bool(ctx, _op_less_equal__bool__nat__nat(_op_plus__nat__nat__nat(ctx, lo, size), a->size));
	temp0 = (struct mut_slice__arr__char*) alloc__ptr__byte__nat(ctx, sizeof(struct mut_slice__arr__char));
	(*(temp0) = (struct mut_slice__arr__char) {a->backing, size, _op_plus__nat__nat__nat(ctx, a->begin, lo)}, 0);
	return temp0;
}
struct mut_slice__arr__char* slice__ptr_mut_slice__arr__char__ptr_mut_slice__arr__char__nat(struct ctx* ctx, struct mut_slice__arr__char* a, uint64_t lo) {
	assert___void__bool(ctx, _op_less_equal__bool__nat__nat(lo, a->size));
	return slice__ptr_mut_slice__arr__char__ptr_mut_slice__arr__char__nat__nat(ctx, a, lo, _op_minus__nat__nat__nat(ctx, a->size, lo));
}
struct mut_slice__arr__char* to_mut_slice__ptr_mut_slice__arr__char__ptr_mut_arr__arr__char(struct ctx* ctx, struct mut_arr__arr__char* a) {
	struct mut_slice__arr__char* temp0;
	forbid___void__bool(ctx, a->frozen__q);
	temp0 = (struct mut_slice__arr__char*) alloc__ptr__byte__nat(ctx, sizeof(struct mut_slice__arr__char));
	(*(temp0) = (struct mut_slice__arr__char) {a, a->size, 0}, 0);
	return temp0;
}
uint8_t each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0(struct ctx* ctx, struct each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char__lambda0___closure* _closure, struct arr__char child_name) {
	if (call__bool__fun_mut1__bool__arr__char__arr__char(ctx, _closure->filter, child_name)) {
		return each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char(ctx, child_path__arr__char__arr__char__arr__char(ctx, _closure->path, child_name), _closure->filter, _closure->f);
	} else {
		return 0;
	}
}
struct opt__arr__char get_extension__opt__arr__char__arr__char(struct ctx* ctx, struct arr__char name) {
	struct some__nat s;
	struct opt__nat matched;
	matched = last_index_of__opt__nat__arr__char__char(ctx, name, literal__char__arr__char((struct arr__char) {1, "."}));
	switch (matched.kind) {
		case 0:
			return (struct opt__arr__char) {0, .as0 = none__none()};
		case 1:
			s = matched.as1;
			return (struct opt__arr__char) {1, .as1 = some__some__arr__char__arr__char(slice_after__arr__char__arr__char__nat(ctx, name, s.value))};
		default:
			return (assert(0),(struct opt__arr__char) {0});
	}
}
struct opt__nat last_index_of__opt__nat__arr__char__char(struct ctx* ctx, struct arr__char s, char c) {
	struct ctx* _tailCallctx;
	struct arr__char _tailCalls;
	char _tailCallc;
	top:
	if (empty__q__bool__arr__char(s)) {
		return (struct opt__nat) {0, .as0 = none__none()};
	} else {
		if (_op_equal_equal__bool__char__char(last__char__arr__char(ctx, s), c)) {
			return (struct opt__nat) {1, .as1 = some__some__nat__nat(decr__nat__nat(ctx, s.size))};
		} else {
			_tailCallctx = ctx;
			_tailCalls = rtail__arr__char__arr__char(ctx, s);
			_tailCallc = c;
			ctx = _tailCallctx;
			s = _tailCalls;
			c = _tailCallc;
			goto top;
		}
	}
}
struct arr__char slice_after__arr__char__arr__char__nat(struct ctx* ctx, struct arr__char a, uint64_t before_begin) {
	return slice_starting_at__arr__char__arr__char__nat(ctx, a, incr__nat__nat(ctx, before_begin));
}
struct arr__char base_name__arr__char__arr__char(struct ctx* ctx, struct arr__char path) {
	struct opt__nat i;
	struct some__nat s;
	struct opt__nat matched;
	i = last_index_of__opt__nat__arr__char__char(ctx, path, literal__char__arr__char((struct arr__char) {1, "/"}));
	matched = i;
	switch (matched.kind) {
		case 0:
			return path;
		case 1:
			s = matched.as1;
			return slice_after__arr__char__arr__char__nat(ctx, path, s.value);
		default:
			return (assert(0),(struct arr__char) {0, NULL});
	}
}
uint8_t list_compile_error_tests__arr__arr__char__arr__char__lambda1(struct ctx* ctx, struct list_compile_error_tests__arr__arr__char__arr__char__lambda1___closure* _closure, struct arr__char child) {
	struct arr__char ext;
	ext = force__arr__char__opt__arr__char(ctx, get_extension__opt__arr__char__arr__char(ctx, base_name__arr__char__arr__char(ctx, child)));
	if (_op_equal_equal__bool__arr__char__arr__char(ext, (struct arr__char) {2, "nz"})) {
		return push___void__ptr_mut_arr__arr__char__arr__char(ctx, _closure->res, child);
	} else {
		if (_op_equal_equal__bool__arr__char__arr__char(ext, (struct arr__char) {3, "err"})) {
			return 0;
		} else {
			return todo___void();
		}
	}
}
struct arr__ptr_failure flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char(struct ctx* ctx, struct arr__arr__char a, uint64_t max_size, struct fun_mut1__arr__ptr_failure__arr__char mapper) {
	struct mut_arr__ptr_failure* res;
	struct flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0___closure* temp0;
	res = new_mut_arr__ptr_mut_arr__ptr_failure(ctx);
	each___void__arr__arr__char__fun_mut1___void__arr__char(ctx, a, (struct fun_mut1___void__arr__char) {(fun_ptr3___void__ptr_ctx__ptr__byte__arr__char) flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0, (uint8_t*) (temp0 = (struct flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0___closure)), ((*(temp0) = (struct flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0___closure) {res, max_size, mapper}, 0), temp0))});
	return freeze__arr__ptr_failure__ptr_mut_arr__ptr_failure(res);
}
struct mut_arr__ptr_failure* new_mut_arr__ptr_mut_arr__ptr_failure(struct ctx* ctx) {
	struct mut_arr__ptr_failure* temp0;
	temp0 = (struct mut_arr__ptr_failure*) alloc__ptr__byte__nat(ctx, sizeof(struct mut_arr__ptr_failure));
	(*(temp0) = (struct mut_arr__ptr_failure) {0, 0, 0, NULL}, 0);
	return temp0;
}
uint8_t push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure(struct ctx* ctx, struct mut_arr__ptr_failure* a, struct arr__ptr_failure values) {
	struct push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure__lambda0___closure* temp0;
	return each___void__arr__ptr_failure__fun_mut1___void__ptr_failure(ctx, values, (struct fun_mut1___void__ptr_failure) {(fun_ptr3___void__ptr_ctx__ptr__byte__ptr_failure) push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure__lambda0, (uint8_t*) (temp0 = (struct push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure__lambda0___closure)), ((*(temp0) = (struct push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure__lambda0___closure) {a}, 0), temp0))});
}
uint8_t each___void__arr__ptr_failure__fun_mut1___void__ptr_failure(struct ctx* ctx, struct arr__ptr_failure a, struct fun_mut1___void__ptr_failure f) {
	struct ctx* _tailCallctx;
	struct arr__ptr_failure _tailCalla;
	struct fun_mut1___void__ptr_failure _tailCallf;
	top:
	if (empty__q__bool__arr__ptr_failure(a)) {
		return 0;
	} else {
		call___void__fun_mut1___void__ptr_failure__ptr_failure(ctx, f, first__ptr_failure__arr__ptr_failure(ctx, a));
		_tailCallctx = ctx;
		_tailCalla = tail__arr__ptr_failure__arr__ptr_failure(ctx, a);
		_tailCallf = f;
		ctx = _tailCallctx;
		a = _tailCalla;
		f = _tailCallf;
		goto top;
	}
}
uint8_t empty__q__bool__arr__ptr_failure(struct arr__ptr_failure a) {
	return zero__q__bool__nat(a.size);
}
uint8_t call___void__fun_mut1___void__ptr_failure__ptr_failure(struct ctx* ctx, struct fun_mut1___void__ptr_failure f, struct failure* p0) {
	return call_with_ctx___void__ptr_ctx__fun_mut1___void__ptr_failure__ptr_failure(ctx, f, p0);
}
uint8_t call_with_ctx___void__ptr_ctx__fun_mut1___void__ptr_failure__ptr_failure(struct ctx* c, struct fun_mut1___void__ptr_failure f, struct failure* p0) {
	return f.fun_ptr(c, f.closure, p0);
}
struct failure* first__ptr_failure__arr__ptr_failure(struct ctx* ctx, struct arr__ptr_failure a) {
	forbid___void__bool(ctx, empty__q__bool__arr__ptr_failure(a));
	return at__ptr_failure__arr__ptr_failure__nat(ctx, a, 0);
}
struct failure* at__ptr_failure__arr__ptr_failure__nat(struct ctx* ctx, struct arr__ptr_failure a, uint64_t index) {
	assert___void__bool(ctx, _op_less__bool__nat__nat(index, a.size));
	return noctx_at__ptr_failure__arr__ptr_failure__nat(a, index);
}
struct failure* noctx_at__ptr_failure__arr__ptr_failure__nat(struct arr__ptr_failure a, uint64_t index) {
	hard_assert___void__bool(_op_less__bool__nat__nat(index, a.size));
	return (*((a.data + index)));
}
struct arr__ptr_failure tail__arr__ptr_failure__arr__ptr_failure(struct ctx* ctx, struct arr__ptr_failure a) {
	forbid___void__bool(ctx, empty__q__bool__arr__ptr_failure(a));
	return slice_starting_at__arr__ptr_failure__arr__ptr_failure__nat(ctx, a, 1);
}
struct arr__ptr_failure slice_starting_at__arr__ptr_failure__arr__ptr_failure__nat(struct ctx* ctx, struct arr__ptr_failure a, uint64_t begin) {
	assert___void__bool(ctx, _op_less_equal__bool__nat__nat(begin, a.size));
	return slice__arr__ptr_failure__arr__ptr_failure__nat__nat(ctx, a, begin, _op_minus__nat__nat__nat(ctx, a.size, begin));
}
struct arr__ptr_failure slice__arr__ptr_failure__arr__ptr_failure__nat__nat(struct ctx* ctx, struct arr__ptr_failure a, uint64_t begin, uint64_t size) {
	assert___void__bool(ctx, _op_less_equal__bool__nat__nat(_op_plus__nat__nat__nat(ctx, begin, size), a.size));
	return (struct arr__ptr_failure) {size, (a.data + begin)};
}
uint8_t push___void__ptr_mut_arr__ptr_failure__ptr_failure(struct ctx* ctx, struct mut_arr__ptr_failure* a, struct failure* value) {
	if (_op_equal_equal__bool__nat__nat(a->size, a->capacity)) {
		increase_capacity_to___void__ptr_mut_arr__ptr_failure__nat(ctx, a, (zero__q__bool__nat(a->size) ? four__nat() : _op_times__nat__nat__nat(ctx, a->size, two__nat())));
	} else {
		0;
	}
	ensure_capacity___void__ptr_mut_arr__ptr_failure__nat(ctx, a, round_up_to_power_of_two__nat__nat(ctx, incr__nat__nat(ctx, a->size)));
	assert___void__bool(ctx, _op_less__bool__nat__nat(a->size, a->capacity));
	(*((a->data + a->size)) = value, 0);
	return (a->size = incr__nat__nat(ctx, a->size), 0);
}
uint8_t increase_capacity_to___void__ptr_mut_arr__ptr_failure__nat(struct ctx* ctx, struct mut_arr__ptr_failure* a, uint64_t new_capacity) {
	struct failure** old_data;
	assert___void__bool(ctx, _op_greater__bool__nat__nat(new_capacity, a->capacity));
	old_data = a->data;
	(a->capacity = new_capacity, 0);
	(a->data = uninitialized_data__ptr__ptr_failure__nat(ctx, new_capacity), 0);
	return copy_data_from___void__ptr__ptr_failure__ptr__ptr_failure__nat(ctx, a->data, old_data, a->size);
}
struct failure** uninitialized_data__ptr__ptr_failure__nat(struct ctx* ctx, uint64_t size) {
	uint8_t* bptr;
	bptr = alloc__ptr__byte__nat(ctx, (size * sizeof(struct failure*)));
	return (struct failure**) bptr;
}
uint8_t copy_data_from___void__ptr__ptr_failure__ptr__ptr_failure__nat(struct ctx* ctx, struct failure** to, struct failure** from, uint64_t len) {
	uint64_t hl;
	struct ctx* _tailCallctx;
	struct failure** _tailCallto;
	struct failure** _tailCallfrom;
	uint64_t _tailCalllen;
	top:
	if (_op_less__bool__nat__nat(len, eight__nat())) {
		return copy_data_from_small___void__ptr__ptr_failure__ptr__ptr_failure__nat(ctx, to, from, len);
	} else {
		hl = _op_div__nat__nat__nat(ctx, len, two__nat());
		copy_data_from___void__ptr__ptr_failure__ptr__ptr_failure__nat(ctx, to, from, hl);
		_tailCallctx = ctx;
		_tailCallto = (to + hl);
		_tailCallfrom = (from + hl);
		_tailCalllen = _op_minus__nat__nat__nat(ctx, len, hl);
		ctx = _tailCallctx;
		to = _tailCallto;
		from = _tailCallfrom;
		len = _tailCalllen;
		goto top;
	}
}
uint8_t copy_data_from_small___void__ptr__ptr_failure__ptr__ptr_failure__nat(struct ctx* ctx, struct failure** to, struct failure** from, uint64_t len) {
	if (zero__q__bool__nat(len)) {
		return 0;
	} else {
		(*(to) = (*(from)), 0);
		return copy_data_from___void__ptr__ptr_failure__ptr__ptr_failure__nat(ctx, incr__ptr__ptr_failure__ptr__ptr_failure(to), incr__ptr__ptr_failure__ptr__ptr_failure(from), decr__nat__nat(ctx, len));
	}
}
struct failure** incr__ptr__ptr_failure__ptr__ptr_failure(struct failure** p) {
	return (p + 1);
}
uint8_t ensure_capacity___void__ptr_mut_arr__ptr_failure__nat(struct ctx* ctx, struct mut_arr__ptr_failure* a, uint64_t capacity) {
	if (_op_less__bool__nat__nat(a->capacity, capacity)) {
		return increase_capacity_to___void__ptr_mut_arr__ptr_failure__nat(ctx, a, round_up_to_power_of_two__nat__nat(ctx, capacity));
	} else {
		return 0;
	}
}
uint8_t push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure__lambda0(struct ctx* ctx, struct push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure__lambda0___closure* _closure, struct failure* it) {
	return push___void__ptr_mut_arr__ptr_failure__ptr_failure(ctx, _closure->a, it);
}
struct arr__ptr_failure call__arr__ptr_failure__fun_mut1__arr__ptr_failure__arr__char__arr__char(struct ctx* ctx, struct fun_mut1__arr__ptr_failure__arr__char f, struct arr__char p0) {
	return call_with_ctx__arr__ptr_failure__ptr_ctx__fun_mut1__arr__ptr_failure__arr__char__arr__char(ctx, f, p0);
}
struct arr__ptr_failure call_with_ctx__arr__ptr_failure__ptr_ctx__fun_mut1__arr__ptr_failure__arr__char__arr__char(struct ctx* c, struct fun_mut1__arr__ptr_failure__arr__char f, struct arr__char p0) {
	return f.fun_ptr(c, f.closure, p0);
}
uint8_t reduce_size_if_more_than___void__ptr_mut_arr__ptr_failure__nat(struct ctx* ctx, struct mut_arr__ptr_failure* a, uint64_t new_size) {
	if (_op_less__bool__nat__nat(new_size, a->size)) {
		return (a->size = new_size, 0);
	} else {
		return 0;
	}
}
uint8_t flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0(struct ctx* ctx, struct flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char__lambda0___closure* _closure, struct arr__char x) {
	if (_op_less__bool__nat__nat(_closure->res->size, _closure->max_size)) {
		push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure(ctx, _closure->res, call__arr__ptr_failure__fun_mut1__arr__ptr_failure__arr__char__arr__char(ctx, _closure->mapper, x));
		return reduce_size_if_more_than___void__ptr_mut_arr__ptr_failure__nat(ctx, _closure->res, _closure->max_size);
	} else {
		return 0;
	}
}
struct arr__ptr_failure freeze__arr__ptr_failure__ptr_mut_arr__ptr_failure(struct mut_arr__ptr_failure* a) {
	(a->frozen__q = 1, 0);
	return unsafe_as_arr__arr__ptr_failure__ptr_mut_arr__ptr_failure(a);
}
struct arr__ptr_failure unsafe_as_arr__arr__ptr_failure__ptr_mut_arr__ptr_failure(struct mut_arr__ptr_failure* a) {
	return (struct arr__ptr_failure) {a->size, a->data};
}
struct arr__ptr_failure run_single_compile_error_test__arr__ptr_failure__arr__char__ptr_dict__arr__char__arr__char__arr__char__bool(struct ctx* ctx, struct arr__char path_to_noze, struct dict__arr__char__arr__char* env, struct arr__char path, uint8_t overwrite_output__q) {
	struct mut_arr__ptr_failure* failures;
	struct arr__arr__char arr;
	struct process_result* result;
	struct arr__char message;
	struct arr__char stderr_no_color;
	struct arr__char* temp0;
	struct failure* temp1;
	struct failure* temp2;
	struct failure* temp3;
	failures = new_mut_arr__ptr_mut_arr__ptr_failure(ctx);
	result = spawn_and_wait_result__ptr_process_result__arr__char__arr__arr__char__ptr_dict__arr__char__arr__char(ctx, path_to_noze, (temp0 = (struct arr__char*) alloc__ptr__byte__nat(ctx, (sizeof(struct arr__char) * 2)), ((*((temp0 + 0)) = (struct arr__char) {5, "build"}, 0), ((*((temp0 + 1)) = path, 0), (struct arr__arr__char) {2, temp0}))), env);
	if (_op_equal_equal__bool__int32__int32(result->exit_code, literal__int32__arr__char(ctx, (struct arr__char) {1, "1"}))) {
		0;
	} else {
		message = _op_plus__arr__char__arr__char__arr__char(ctx, (struct arr__char) {59, "Compile error should result in exit code of 1. Instead got "}, to_str__arr__char__int32(ctx, result->exit_code));
		push___void__ptr_mut_arr__ptr_failure__ptr_failure(ctx, failures, (temp1 = (struct failure*) alloc__ptr__byte__nat(ctx, sizeof(struct failure)), ((*(temp1) = (struct failure) {path, message}, 0), temp1)));
	}
	if (_op_equal_equal__bool__arr__char__arr__char(result->stdout, (struct arr__char) {0, ""})) {
		0;
	} else {
		push___void__ptr_mut_arr__ptr_failure__ptr_failure(ctx, failures, (temp2 = (struct failure*) alloc__ptr__byte__nat(ctx, sizeof(struct failure)), ((*(temp2) = (struct failure) {path, _op_plus__arr__char__arr__char__arr__char(ctx, (struct arr__char) {37, "stdout should be empty. Instead got:\n"}, result->stdout)}, 0), temp2)));
	}
	stderr_no_color = remove_colors__arr__char__arr__char(ctx, result->stderr);
	if (_op_equal_equal__bool__arr__char__arr__char(result->stderr, (struct arr__char) {0, ""})) {
		push___void__ptr_mut_arr__ptr_failure__ptr_failure(ctx, failures, (temp3 = (struct failure*) alloc__ptr__byte__nat(ctx, sizeof(struct failure)), ((*(temp3) = (struct failure) {path, (struct arr__char) {15, "stderr is empty"}}, 0), temp3)));
	} else {
		push_all___void__ptr_mut_arr__ptr_failure__arr__ptr_failure(ctx, failures, handle_output__arr__ptr_failure__arr__char__arr__char__arr__char__bool(ctx, path, _op_plus__arr__char__arr__char__arr__char(ctx, path, (struct arr__char) {4, ".err"}), stderr_no_color, overwrite_output__q));
	}
	return freeze__arr__ptr_failure__ptr_mut_arr__ptr_failure(failures);
}
struct process_result* spawn_and_wait_result__ptr_process_result__arr__char__arr__arr__char__ptr_dict__arr__char__arr__char(struct ctx* ctx, struct arr__char exe, struct arr__arr__char args, struct dict__arr__char__arr__char* environ) {
	char* exe_c_str;
	print_sync___void__arr__char(fold__arr__char__arr__char__arr__arr__char__fun_mut2__arr__char__arr__char__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, (struct arr__char) {23, "spawn-and-wait-result: "}, exe), args, (struct fun_mut2__arr__char__arr__char__arr__char) {(fun_ptr4__arr__char__ptr_ctx__ptr__byte__arr__char__arr__char) spawn_and_wait_result__ptr_process_result__arr__char__arr__arr__char__ptr_dict__arr__char__arr__char__lambda0, (uint8_t*) NULL}));
	if (is_file__q__bool__arr__char(ctx, exe)) {
		exe_c_str = to_c_str__ptr__char__arr__char(ctx, exe);
		return spawn_and_wait_result__ptr_process_result__ptr__char__ptr__ptr__char__ptr__ptr__char(ctx, exe_c_str, convert_args__ptr__ptr__char__ptr__char__arr__arr__char(ctx, exe_c_str, args), convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char(ctx, environ));
	} else {
		return fail__ptr_process_result__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, exe, (struct arr__char) {14, " is not a file"}));
	}
}
struct arr__char fold__arr__char__arr__char__arr__arr__char__fun_mut2__arr__char__arr__char__arr__char(struct ctx* ctx, struct arr__char val, struct arr__arr__char a, struct fun_mut2__arr__char__arr__char__arr__char combine) {
	struct ctx* _tailCallctx;
	struct arr__char _tailCallval;
	struct arr__arr__char _tailCalla;
	struct fun_mut2__arr__char__arr__char__arr__char _tailCallcombine;
	top:
	if (empty__q__bool__arr__arr__char(a)) {
		return val;
	} else {
		_tailCallctx = ctx;
		_tailCallval = call__arr__char__fun_mut2__arr__char__arr__char__arr__char__arr__char__arr__char(ctx, combine, val, first__arr__char__arr__arr__char(ctx, a));
		_tailCalla = tail__arr__arr__char__arr__arr__char(ctx, a);
		_tailCallcombine = combine;
		ctx = _tailCallctx;
		val = _tailCallval;
		a = _tailCalla;
		combine = _tailCallcombine;
		goto top;
	}
}
struct arr__char call__arr__char__fun_mut2__arr__char__arr__char__arr__char__arr__char__arr__char(struct ctx* ctx, struct fun_mut2__arr__char__arr__char__arr__char f, struct arr__char p0, struct arr__char p1) {
	return call_with_ctx__arr__char__ptr_ctx__fun_mut2__arr__char__arr__char__arr__char__arr__char__arr__char(ctx, f, p0, p1);
}
struct arr__char call_with_ctx__arr__char__ptr_ctx__fun_mut2__arr__char__arr__char__arr__char__arr__char__arr__char(struct ctx* c, struct fun_mut2__arr__char__arr__char__arr__char f, struct arr__char p0, struct arr__char p1) {
	return f.fun_ptr(c, f.closure, p0, p1);
}
struct arr__char spawn_and_wait_result__ptr_process_result__arr__char__arr__arr__char__ptr_dict__arr__char__arr__char__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr__char a, struct arr__char b) {
	return _op_plus__arr__char__arr__char__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, a, (struct arr__char) {1, " "}), b);
}
uint8_t is_file__q__bool__arr__char(struct ctx* ctx, struct arr__char path) {
	return is_file__q__bool__ptr__char(ctx, to_c_str__ptr__char__arr__char(ctx, path));
}
uint8_t is_file__q__bool__ptr__char(struct ctx* ctx, char* path) {
	struct some__ptr_stat_t s;
	struct opt__ptr_stat_t matched;
	matched = get_stat__opt__ptr_stat_t__ptr__char(ctx, path);
	switch (matched.kind) {
		case 0:
			return 0;
		case 1:
			s = matched.as1;
			return _op_equal_equal__bool__nat32__nat32((s.value->st_mode & s_ifmt__nat32(ctx)), s_ifreg__nat32(ctx));
		default:
			return (assert(0),0);
	}
}
uint32_t s_ifreg__nat32(struct ctx* ctx) {
	return two_pow__nat32__nat32(fifteen__nat32());
}
struct process_result* spawn_and_wait_result__ptr_process_result__ptr__char__ptr__ptr__char__ptr__ptr__char(struct ctx* ctx, char* exe, char** args, char** environ) {
	struct pipes* stdout_pipes;
	struct pipes* stderr_pipes;
	struct posix_spawn_file_actions_t* actions;
	struct cell__int32* pid_cell;
	int32_t pid;
	struct mut_arr__char* stdout_builder;
	struct mut_arr__char* stderr_builder;
	int32_t exit_code;
	struct posix_spawn_file_actions_t* temp0;
	struct process_result* temp1;
	stdout_pipes = make_pipes__ptr_pipes(ctx);
	stderr_pipes = make_pipes__ptr_pipes(ctx);
	actions = (temp0 = (struct posix_spawn_file_actions_t*) alloc__ptr__byte__nat(ctx, sizeof(struct posix_spawn_file_actions_t)), ((*(temp0) = (struct posix_spawn_file_actions_t) {0, 0, NULL, zero__bytes64()}, 0), temp0));
	check_posix_error___void__int32(ctx, posix_spawn_file_actions_init(actions));
	check_posix_error___void__int32(ctx, posix_spawn_file_actions_addclose(actions, stdout_pipes->write_pipe));
	check_posix_error___void__int32(ctx, posix_spawn_file_actions_addclose(actions, stderr_pipes->write_pipe));
	check_posix_error___void__int32(ctx, posix_spawn_file_actions_adddup2(actions, stdout_pipes->read_pipe, stdout_fd__int32()));
	check_posix_error___void__int32(ctx, posix_spawn_file_actions_adddup2(actions, stderr_pipes->read_pipe, stderr_fd__int32()));
	check_posix_error___void__int32(ctx, posix_spawn_file_actions_addclose(actions, stdout_pipes->read_pipe));
	check_posix_error___void__int32(ctx, posix_spawn_file_actions_addclose(actions, stderr_pipes->read_pipe));
	pid_cell = new_cell__ptr_cell__int32__int32(ctx, 0);
	check_posix_error___void__int32(ctx, posix_spawn(pid_cell, exe, actions, NULL, args, environ));
	pid = get__int32__ptr_cell__int32(pid_cell);
	check_posix_error___void__int32(ctx, close(stdout_pipes->read_pipe));
	check_posix_error___void__int32(ctx, close(stderr_pipes->read_pipe));
	stdout_builder = new_mut_arr__ptr_mut_arr__char(ctx);
	stderr_builder = new_mut_arr__ptr_mut_arr__char(ctx);
	keep_polling___void__int32__int32__ptr_mut_arr__char__ptr_mut_arr__char(ctx, stdout_pipes->write_pipe, stderr_pipes->write_pipe, stdout_builder, stderr_builder);
	exit_code = wait_and_get_exit_code__int32__int32(ctx, pid);
	temp1 = (struct process_result*) alloc__ptr__byte__nat(ctx, sizeof(struct process_result));
	(*(temp1) = (struct process_result) {exit_code, freeze__arr__char__ptr_mut_arr__char(stdout_builder), freeze__arr__char__ptr_mut_arr__char(stderr_builder)}, 0);
	return temp1;
}
struct pipes* make_pipes__ptr_pipes(struct ctx* ctx) {
	struct pipes* res;
	struct pipes* temp0;
	res = (temp0 = (struct pipes*) alloc__ptr__byte__nat(ctx, sizeof(struct pipes)), ((*(temp0) = (struct pipes) {0, 0}, 0), temp0));
	check_posix_error___void__int32(ctx, pipe(res));
	return res;
}
struct cell__int32* new_cell__ptr_cell__int32__int32(struct ctx* ctx, int32_t value) {
	struct cell__int32* temp0;
	temp0 = (struct cell__int32*) alloc__ptr__byte__nat(ctx, sizeof(struct cell__int32));
	(*(temp0) = (struct cell__int32) {value}, 0);
	return temp0;
}
int32_t get__int32__ptr_cell__int32(struct cell__int32* c) {
	return c->value;
}
struct mut_arr__char* new_mut_arr__ptr_mut_arr__char(struct ctx* ctx) {
	struct mut_arr__char* temp0;
	temp0 = (struct mut_arr__char*) alloc__ptr__byte__nat(ctx, sizeof(struct mut_arr__char));
	(*(temp0) = (struct mut_arr__char) {0, 0, 0, NULL}, 0);
	return temp0;
}
uint8_t keep_polling___void__int32__int32__ptr_mut_arr__char__ptr_mut_arr__char(struct ctx* ctx, int32_t stdout_pipe, int32_t stderr_pipe, struct mut_arr__char* stdout_builder, struct mut_arr__char* stderr_builder) {
	struct arr__pollfd arr;
	struct arr__pollfd poll_fds;
	struct pollfd* stdout_pollfd;
	struct pollfd* stderr_pollfd;
	int32_t n_pollfds_with_events;
	struct handle_revents_result a;
	struct handle_revents_result b;
	struct pollfd* temp0;
	struct ctx* _tailCallctx;
	int32_t _tailCallstdout_pipe;
	int32_t _tailCallstderr_pipe;
	struct mut_arr__char* _tailCallstdout_builder;
	struct mut_arr__char* _tailCallstderr_builder;
	top:
	poll_fds = (temp0 = (struct pollfd*) alloc__ptr__byte__nat(ctx, (sizeof(struct pollfd) * 2)), ((*((temp0 + 0)) = (struct pollfd) {stdout_pipe, pollin__int16(ctx), 0}, 0), ((*((temp0 + 1)) = (struct pollfd) {stderr_pipe, pollin__int16(ctx), 0}, 0), (struct arr__pollfd) {2, temp0})));
	stdout_pollfd = ref_of_val_at__ptr_pollfd__arr__pollfd__nat(ctx, poll_fds, 0);
	stderr_pollfd = ref_of_val_at__ptr_pollfd__arr__pollfd__nat(ctx, poll_fds, 1);
	n_pollfds_with_events = poll(poll_fds.data, poll_fds.size, neg_one__int32());
	if (zero__q__bool__int32(n_pollfds_with_events)) {
		return 0;
	} else {
		a = handle_revents__handle_revents_result__ptr_pollfd__ptr_mut_arr__char(ctx, stdout_pollfd, stdout_builder);
		b = handle_revents__handle_revents_result__ptr_pollfd__ptr_mut_arr__char(ctx, stderr_pollfd, stderr_builder);
		assert___void__bool(ctx, _op_equal_equal__bool__nat__nat(_op_plus__nat__nat__nat(ctx, to_nat__nat__bool(ctx, any__q__bool__handle_revents_result(ctx, a)), to_nat__nat__bool(ctx, any__q__bool__handle_revents_result(ctx, b))), to_nat__nat__int32(ctx, n_pollfds_with_events)));
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
int16_t pollin__int16(struct ctx* ctx) {
	return two_pow__int16__int16(0);
}
int16_t two_pow__int16__int16(int16_t pow) {
	if (zero__q__bool__int16(pow)) {
		return 1;
	} else {
		return (two_pow__int16__int16(wrap_decr__int16__int16(pow)) * two__int16());
	}
}
uint8_t zero__q__bool__int16(int16_t a) {
	return _op_equal_equal__bool__int16__int16(a, 0);
}
uint8_t _op_equal_equal__bool__int16__int16(int16_t a, int16_t b) {
	struct comparison matched;
	matched = _op_less_equal_greater__comparison__int16__int16(a, b);
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
struct comparison _op_less_equal_greater__comparison__int16__int16(int16_t a, int16_t b) {
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
int16_t wrap_decr__int16__int16(int16_t a) {
	return (a - 1);
}
int16_t two__int16() {
	return wrap_incr__int16__int16(1);
}
int16_t wrap_incr__int16__int16(int16_t a) {
	return (a + 1);
}
struct pollfd* ref_of_val_at__ptr_pollfd__arr__pollfd__nat(struct ctx* ctx, struct arr__pollfd a, uint64_t index) {
	assert___void__bool(ctx, _op_less__bool__nat__nat(index, a.size));
	return ref_of_ptr__ptr_pollfd__ptr__pollfd((a.data + index));
}
struct pollfd* ref_of_ptr__ptr_pollfd__ptr__pollfd(struct pollfd* p) {
	return (&((*(p))));
}
struct handle_revents_result handle_revents__handle_revents_result__ptr_pollfd__ptr_mut_arr__char(struct ctx* ctx, struct pollfd* pollfd, struct mut_arr__char* builder) {
	int16_t revents;
	uint8_t had_pollin__q;
	uint8_t hung_up__q;
	revents = pollfd->revents;
	had_pollin__q = has_pollin__q__bool__int16(ctx, revents);
	if (had_pollin__q) {
		read_to_buffer_until_eof___void__int32__ptr_mut_arr__char(ctx, pollfd->fd, builder);
	} else {
		0;
	}
	hung_up__q = has_pollhup__q__bool__int16(ctx, revents);
	if ((((has_pollpri__q__bool__int16(ctx, revents) || has_pollout__q__bool__int16(ctx, revents)) || has_pollerr__q__bool__int16(ctx, revents)) || has_pollnval__q__bool__int16(ctx, revents))) {
		todo___void();
	} else {
		0;
	}
	return (struct handle_revents_result) {had_pollin__q, hung_up__q};
}
uint8_t has_pollin__q__bool__int16(struct ctx* ctx, int16_t revents) {
	return bits_intersect__q__bool__int16__int16(revents, pollin__int16(ctx));
}
uint8_t bits_intersect__q__bool__int16__int16(int16_t a, int16_t b) {
	return !zero__q__bool__int16((a & b));
}
uint8_t read_to_buffer_until_eof___void__int32__ptr_mut_arr__char(struct ctx* ctx, int32_t fd, struct mut_arr__char* buffer) {
	uint64_t read_max;
	char* add_data_to;
	int64_t n_bytes_read;
	struct ctx* _tailCallctx;
	int32_t _tailCallfd;
	struct mut_arr__char* _tailCallbuffer;
	top:
	read_max = two_pow__nat__nat(ten__nat());
	ensure_capacity___void__ptr_mut_arr__char__nat(ctx, buffer, _op_plus__nat__nat__nat(ctx, buffer->size, read_max));
	add_data_to = (buffer->data + buffer->size);
	n_bytes_read = read(fd, (uint8_t*) add_data_to, read_max);
	if (_op_equal_equal__bool___int___int(n_bytes_read, neg_one___int())) {
		return todo___void();
	} else {
		if (_op_equal_equal__bool___int___int(n_bytes_read, 0)) {
			return 0;
		} else {
			assert___void__bool(ctx, _op_less_equal__bool__nat__nat(to_nat__nat___int(ctx, n_bytes_read), read_max));
			unsafe_increase_size___void__ptr_mut_arr__char__nat(ctx, buffer, to_nat__nat___int(ctx, n_bytes_read));
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
uint64_t two_pow__nat__nat(uint64_t pow) {
	if (zero__q__bool__nat(pow)) {
		return 1;
	} else {
		return (two_pow__nat__nat(wrap_decr__nat__nat(pow)) * two__nat());
	}
}
uint8_t ensure_capacity___void__ptr_mut_arr__char__nat(struct ctx* ctx, struct mut_arr__char* a, uint64_t capacity) {
	if (_op_less__bool__nat__nat(a->capacity, capacity)) {
		return increase_capacity_to___void__ptr_mut_arr__char__nat(ctx, a, round_up_to_power_of_two__nat__nat(ctx, capacity));
	} else {
		return 0;
	}
}
uint8_t increase_capacity_to___void__ptr_mut_arr__char__nat(struct ctx* ctx, struct mut_arr__char* a, uint64_t new_capacity) {
	char* old_data;
	assert___void__bool(ctx, _op_greater__bool__nat__nat(new_capacity, a->capacity));
	old_data = a->data;
	(a->capacity = new_capacity, 0);
	(a->data = uninitialized_data__ptr__char__nat(ctx, new_capacity), 0);
	return copy_data_from___void__ptr__char__ptr__char__nat(ctx, a->data, old_data, a->size);
}
uint8_t copy_data_from___void__ptr__char__ptr__char__nat(struct ctx* ctx, char* to, char* from, uint64_t len) {
	uint64_t hl;
	struct ctx* _tailCallctx;
	char* _tailCallto;
	char* _tailCallfrom;
	uint64_t _tailCalllen;
	top:
	if (_op_less__bool__nat__nat(len, eight__nat())) {
		return copy_data_from_small___void__ptr__char__ptr__char__nat(ctx, to, from, len);
	} else {
		hl = _op_div__nat__nat__nat(ctx, len, two__nat());
		copy_data_from___void__ptr__char__ptr__char__nat(ctx, to, from, hl);
		_tailCallctx = ctx;
		_tailCallto = (to + hl);
		_tailCallfrom = (from + hl);
		_tailCalllen = _op_minus__nat__nat__nat(ctx, len, hl);
		ctx = _tailCallctx;
		to = _tailCallto;
		from = _tailCallfrom;
		len = _tailCalllen;
		goto top;
	}
}
uint8_t copy_data_from_small___void__ptr__char__ptr__char__nat(struct ctx* ctx, char* to, char* from, uint64_t len) {
	if (zero__q__bool__nat(len)) {
		return 0;
	} else {
		(*(to) = (*(from)), 0);
		return copy_data_from___void__ptr__char__ptr__char__nat(ctx, incr__ptr__char__ptr__char(to), incr__ptr__char__ptr__char(from), decr__nat__nat(ctx, len));
	}
}
uint8_t unsafe_increase_size___void__ptr_mut_arr__char__nat(struct ctx* ctx, struct mut_arr__char* a, uint64_t increase_by) {
	return unsafe_set_size___void__ptr_mut_arr__char__nat(ctx, a, _op_plus__nat__nat__nat(ctx, a->size, increase_by));
}
uint8_t unsafe_set_size___void__ptr_mut_arr__char__nat(struct ctx* ctx, struct mut_arr__char* a, uint64_t new_size) {
	assert___void__bool(ctx, _op_less_equal__bool__nat__nat(new_size, a->capacity));
	return (a->size = new_size, 0);
}
uint8_t has_pollhup__q__bool__int16(struct ctx* ctx, int16_t revents) {
	return bits_intersect__q__bool__int16__int16(revents, pollhup__int16(ctx));
}
int16_t pollhup__int16(struct ctx* ctx) {
	return two_pow__int16__int16(four__int16());
}
int16_t four__int16() {
	return wrap_incr__int16__int16(three__int16());
}
int16_t three__int16() {
	return wrap_incr__int16__int16(two__int16());
}
uint8_t has_pollpri__q__bool__int16(struct ctx* ctx, int16_t revents) {
	return bits_intersect__q__bool__int16__int16(revents, pollpri__int16(ctx));
}
int16_t pollpri__int16(struct ctx* ctx) {
	return two_pow__int16__int16(1);
}
uint8_t has_pollout__q__bool__int16(struct ctx* ctx, int16_t revents) {
	return bits_intersect__q__bool__int16__int16(revents, pollout__int16(ctx));
}
int16_t pollout__int16(struct ctx* ctx) {
	return two_pow__int16__int16(two__int16());
}
uint8_t has_pollerr__q__bool__int16(struct ctx* ctx, int16_t revents) {
	return bits_intersect__q__bool__int16__int16(revents, pollerr__int16(ctx));
}
int16_t pollerr__int16(struct ctx* ctx) {
	return two_pow__int16__int16(three__int16());
}
uint8_t has_pollnval__q__bool__int16(struct ctx* ctx, int16_t revents) {
	return bits_intersect__q__bool__int16__int16(revents, pollnval__int16(ctx));
}
int16_t pollnval__int16(struct ctx* ctx) {
	return two_pow__int16__int16(five__int16());
}
int16_t five__int16() {
	return wrap_incr__int16__int16(four__int16());
}
uint64_t to_nat__nat__bool(struct ctx* ctx, uint8_t b) {
	if (b) {
		return 1;
	} else {
		return 0;
	}
}
uint8_t any__q__bool__handle_revents_result(struct ctx* ctx, struct handle_revents_result r) {
	return (r.had_pollin__q || r.hung_up__q);
}
uint64_t to_nat__nat__int32(struct ctx* ctx, int32_t i) {
	return to_nat__nat___int(ctx, i);
}
int32_t wait_and_get_exit_code__int32__int32(struct ctx* ctx, int32_t pid) {
	struct cell__int32* wait_status_cell;
	int32_t res_pid;
	int32_t wait_status;
	int32_t signal;
	wait_status_cell = new_cell__ptr_cell__int32__int32(ctx, 0);
	res_pid = waitpid(pid, wait_status_cell, 0);
	wait_status = get__int32__ptr_cell__int32(wait_status_cell);
	assert___void__bool(ctx, _op_equal_equal__bool__int32__int32(res_pid, pid));
	if (w_if_exited__bool__int32(ctx, wait_status)) {
		return w_exit_status__int32__int32(ctx, wait_status);
	} else {
		if (w_if_signaled__bool__int32(ctx, wait_status)) {
			signal = w_term_sig__int32__int32(ctx, wait_status);
			print_sync___void__arr__char(_op_plus__arr__char__arr__char__arr__char(ctx, (struct arr__char) {31, "Process terminated with signal "}, to_str__arr__char__int32(ctx, signal)));
			return todo__int32();
		} else {
			if (w_if_stopped__bool__int32(ctx, wait_status)) {
				print_sync___void__arr__char((struct arr__char) {12, "WAIT STOPPED"});
				return todo__int32();
			} else {
				if (w_if_continued__bool__int32(ctx, wait_status)) {
					return todo__int32();
				} else {
					return todo__int32();
				}
			}
		}
	}
}
uint8_t w_if_exited__bool__int32(struct ctx* ctx, int32_t status) {
	return zero__q__bool__int32(w_term_sig__int32__int32(ctx, status));
}
int32_t w_term_sig__int32__int32(struct ctx* ctx, int32_t status) {
	return (status & x7f__int32());
}
int32_t x7f__int32() {
	return noctx_decr__int32__int32(two_pow__int32__int32(seven__int32()));
}
int32_t noctx_decr__int32__int32(int32_t a) {
	hard_forbid___void__bool(zero__q__bool__int32(a));
	return (a - 1);
}
int32_t two_pow__int32__int32(int32_t pow) {
	if (zero__q__bool__int32(pow)) {
		return 1;
	} else {
		return (two_pow__int32__int32(wrap_decr__int32__int32(pow)) * two__int32());
	}
}
int32_t wrap_decr__int32__int32(int32_t a) {
	return (a - 1);
}
int32_t w_exit_status__int32__int32(struct ctx* ctx, int32_t status) {
	return ((status & xff00__int32()) >> eight__int32());
}
int32_t xff00__int32() {
	return (xffff__int32() - xff__int32());
}
int32_t xffff__int32() {
	return noctx_decr__int32__int32(two_pow__int32__int32(sixteen__int32()));
}
int32_t sixteen__int32() {
	return (ten__int32() + six__int32());
}
int32_t xff__int32() {
	return noctx_decr__int32__int32(two_pow__int32__int32(eight__int32()));
}
uint8_t w_if_signaled__bool__int32(struct ctx* ctx, int32_t status) {
	int32_t ts;
	ts = w_term_sig__int32__int32(ctx, status);
	return (_op_bang_equal__bool__int32__int32(ts, 0) && _op_bang_equal__bool__int32__int32(ts, x7f__int32()));
}
uint8_t _op_bang_equal__bool__int32__int32(int32_t a, int32_t b) {
	return !_op_equal_equal__bool__int32__int32(a, b);
}
struct arr__char to_str__arr__char__int32(struct ctx* ctx, int32_t i) {
	return to_str__arr__char___int(ctx, i);
}
struct arr__char to_str__arr__char___int(struct ctx* ctx, int64_t i) {
	struct arr__char a;
	a = to_str__arr__char__nat(ctx, abs__nat___int(ctx, i));
	if (negative__q__bool___int(ctx, i)) {
		return _op_plus__arr__char__arr__char__arr__char(ctx, (struct arr__char) {1, "-"}, a);
	} else {
		return a;
	}
}
struct arr__char to_str__arr__char__nat(struct ctx* ctx, uint64_t n) {
	struct arr__char hi;
	struct arr__char lo;
	if (_op_equal_equal__bool__nat__nat(n, literal__nat__arr__char(ctx, (struct arr__char) {1, "0"}))) {
		return (struct arr__char) {1, "0"};
	} else {
		if (_op_equal_equal__bool__nat__nat(n, literal__nat__arr__char(ctx, (struct arr__char) {1, "1"}))) {
			return (struct arr__char) {1, "1"};
		} else {
			if (_op_equal_equal__bool__nat__nat(n, literal__nat__arr__char(ctx, (struct arr__char) {1, "2"}))) {
				return (struct arr__char) {1, "2"};
			} else {
				if (_op_equal_equal__bool__nat__nat(n, literal__nat__arr__char(ctx, (struct arr__char) {1, "3"}))) {
					return (struct arr__char) {1, "3"};
				} else {
					if (_op_equal_equal__bool__nat__nat(n, literal__nat__arr__char(ctx, (struct arr__char) {1, "4"}))) {
						return (struct arr__char) {1, "4"};
					} else {
						if (_op_equal_equal__bool__nat__nat(n, literal__nat__arr__char(ctx, (struct arr__char) {1, "5"}))) {
							return (struct arr__char) {1, "5"};
						} else {
							if (_op_equal_equal__bool__nat__nat(n, literal__nat__arr__char(ctx, (struct arr__char) {1, "6"}))) {
								return (struct arr__char) {1, "6"};
							} else {
								if (_op_equal_equal__bool__nat__nat(n, literal__nat__arr__char(ctx, (struct arr__char) {1, "7"}))) {
									return (struct arr__char) {1, "7"};
								} else {
									if (_op_equal_equal__bool__nat__nat(n, literal__nat__arr__char(ctx, (struct arr__char) {1, "8"}))) {
										return (struct arr__char) {1, "8"};
									} else {
										if (_op_equal_equal__bool__nat__nat(n, literal__nat__arr__char(ctx, (struct arr__char) {1, "9"}))) {
											return (struct arr__char) {1, "9"};
										} else {
											hi = to_str__arr__char__nat(ctx, _op_div__nat__nat__nat(ctx, n, ten__nat()));
											lo = to_str__arr__char__nat(ctx, mod__nat__nat__nat(ctx, n, ten__nat()));
											return _op_plus__arr__char__arr__char__arr__char(ctx, hi, lo);
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
uint64_t mod__nat__nat__nat(struct ctx* ctx, uint64_t a, uint64_t b) {
	forbid___void__bool(ctx, zero__q__bool__nat(b));
	return (a % b);
}
uint64_t abs__nat___int(struct ctx* ctx, int64_t i) {
	int64_t i_abs;
	i_abs = (negative__q__bool___int(ctx, i) ? neg___int___int(ctx, i) : i);
	return to_nat__nat___int(ctx, i_abs);
}
int32_t todo__int32() {
	return (assert(0),0);
}
uint8_t w_if_stopped__bool__int32(struct ctx* ctx, int32_t status) {
	return _op_equal_equal__bool__int32__int32((status & xff__int32()), x7f__int32());
}
uint8_t w_if_continued__bool__int32(struct ctx* ctx, int32_t status) {
	return _op_equal_equal__bool__int32__int32(status, xffff__int32());
}
char** convert_args__ptr__ptr__char__ptr__char__arr__arr__char(struct ctx* ctx, char* exe_c_str, struct arr__arr__char args) {
	return cons__arr__ptr__char__ptr__char__arr__ptr__char(ctx, exe_c_str, rcons__arr__ptr__char__arr__ptr__char__ptr__char(ctx, map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char(ctx, args, (struct fun_mut1__ptr__char__arr__char) {(fun_ptr3__ptr__char__ptr_ctx__ptr__byte__arr__char) convert_args__ptr__ptr__char__ptr__char__arr__arr__char__lambda0, (uint8_t*) NULL}), NULL)).data;
}
struct arr__ptr__char cons__arr__ptr__char__ptr__char__arr__ptr__char(struct ctx* ctx, char* a, struct arr__ptr__char b) {
	struct arr__ptr__char arr;
	char** temp0;
	return _op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char(ctx, (temp0 = (char**) alloc__ptr__byte__nat(ctx, (sizeof(char*) * 1)), ((*((temp0 + 0)) = a, 0), (struct arr__ptr__char) {1, temp0})), b);
}
struct arr__ptr__char _op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char(struct ctx* ctx, struct arr__ptr__char a, struct arr__ptr__char b) {
	struct _op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char__lambda0___closure* temp0;
	return make_arr__arr__ptr__char__nat__fun_mut1__ptr__char__nat(ctx, _op_plus__nat__nat__nat(ctx, a.size, b.size), (struct fun_mut1__ptr__char__nat) {(fun_ptr3__ptr__char__ptr_ctx__ptr__byte__nat) _op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char__lambda0, (uint8_t*) (temp0 = (struct _op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct _op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char__lambda0___closure)), ((*(temp0) = (struct _op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char__lambda0___closure) {a, b}, 0), temp0))});
}
struct arr__ptr__char make_arr__arr__ptr__char__nat__fun_mut1__ptr__char__nat(struct ctx* ctx, uint64_t size, struct fun_mut1__ptr__char__nat f) {
	return freeze__arr__ptr__char__ptr_mut_arr__ptr__char(make_mut_arr__ptr_mut_arr__ptr__char__nat__fun_mut1__ptr__char__nat(ctx, size, f));
}
struct arr__ptr__char freeze__arr__ptr__char__ptr_mut_arr__ptr__char(struct mut_arr__ptr__char* a) {
	(a->frozen__q = 1, 0);
	return unsafe_as_arr__arr__ptr__char__ptr_mut_arr__ptr__char(a);
}
struct arr__ptr__char unsafe_as_arr__arr__ptr__char__ptr_mut_arr__ptr__char(struct mut_arr__ptr__char* a) {
	return (struct arr__ptr__char) {a->size, a->data};
}
struct mut_arr__ptr__char* make_mut_arr__ptr_mut_arr__ptr__char__nat__fun_mut1__ptr__char__nat(struct ctx* ctx, uint64_t size, struct fun_mut1__ptr__char__nat f) {
	struct mut_arr__ptr__char* res;
	res = new_uninitialized_mut_arr__ptr_mut_arr__ptr__char__nat(ctx, size);
	make_mut_arr_worker___void__ptr_mut_arr__ptr__char__nat__fun_mut1__ptr__char__nat(ctx, res, 0, f);
	return res;
}
struct mut_arr__ptr__char* new_uninitialized_mut_arr__ptr_mut_arr__ptr__char__nat(struct ctx* ctx, uint64_t size) {
	struct mut_arr__ptr__char* temp0;
	temp0 = (struct mut_arr__ptr__char*) alloc__ptr__byte__nat(ctx, sizeof(struct mut_arr__ptr__char));
	(*(temp0) = (struct mut_arr__ptr__char) {0, size, size, uninitialized_data__ptr__ptr__char__nat(ctx, size)}, 0);
	return temp0;
}
char** uninitialized_data__ptr__ptr__char__nat(struct ctx* ctx, uint64_t size) {
	uint8_t* bptr;
	bptr = alloc__ptr__byte__nat(ctx, (size * sizeof(char*)));
	return (char**) bptr;
}
uint8_t make_mut_arr_worker___void__ptr_mut_arr__ptr__char__nat__fun_mut1__ptr__char__nat(struct ctx* ctx, struct mut_arr__ptr__char* m, uint64_t i, struct fun_mut1__ptr__char__nat f) {
	struct ctx* _tailCallctx;
	struct mut_arr__ptr__char* _tailCallm;
	uint64_t _tailCalli;
	struct fun_mut1__ptr__char__nat _tailCallf;
	top:
	if (_op_equal_equal__bool__nat__nat(i, m->size)) {
		return 0;
	} else {
		set_at___void__ptr_mut_arr__ptr__char__nat__ptr__char(ctx, m, i, call__ptr__char__fun_mut1__ptr__char__nat__nat(ctx, f, i));
		_tailCallctx = ctx;
		_tailCallm = m;
		_tailCalli = incr__nat__nat(ctx, i);
		_tailCallf = f;
		ctx = _tailCallctx;
		m = _tailCallm;
		i = _tailCalli;
		f = _tailCallf;
		goto top;
	}
}
uint8_t set_at___void__ptr_mut_arr__ptr__char__nat__ptr__char(struct ctx* ctx, struct mut_arr__ptr__char* a, uint64_t index, char* value) {
	assert___void__bool(ctx, _op_less__bool__nat__nat(index, a->size));
	return noctx_set_at___void__ptr_mut_arr__ptr__char__nat__ptr__char(a, index, value);
}
uint8_t noctx_set_at___void__ptr_mut_arr__ptr__char__nat__ptr__char(struct mut_arr__ptr__char* a, uint64_t index, char* value) {
	hard_assert___void__bool(_op_less__bool__nat__nat(index, a->size));
	return (*((a->data + index)) = value, 0);
}
char* call__ptr__char__fun_mut1__ptr__char__nat__nat(struct ctx* ctx, struct fun_mut1__ptr__char__nat f, uint64_t p0) {
	return call_with_ctx__ptr__char__ptr_ctx__fun_mut1__ptr__char__nat__nat(ctx, f, p0);
}
char* call_with_ctx__ptr__char__ptr_ctx__fun_mut1__ptr__char__nat__nat(struct ctx* c, struct fun_mut1__ptr__char__nat f, uint64_t p0) {
	return f.fun_ptr(c, f.closure, p0);
}
char* _op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char__lambda0(struct ctx* ctx, struct _op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char__lambda0___closure* _closure, uint64_t i) {
	if (_op_less__bool__nat__nat(i, _closure->a.size)) {
		return at__ptr__char__arr__ptr__char__nat(ctx, _closure->a, i);
	} else {
		return at__ptr__char__arr__ptr__char__nat(ctx, _closure->b, _op_minus__nat__nat__nat(ctx, i, _closure->a.size));
	}
}
struct arr__ptr__char rcons__arr__ptr__char__arr__ptr__char__ptr__char(struct ctx* ctx, struct arr__ptr__char a, char* b) {
	struct arr__ptr__char arr;
	char** temp0;
	return _op_plus__arr__ptr__char__arr__ptr__char__arr__ptr__char(ctx, a, (temp0 = (char**) alloc__ptr__byte__nat(ctx, (sizeof(char*) * 1)), ((*((temp0 + 0)) = b, 0), (struct arr__ptr__char) {1, temp0})));
}
struct arr__ptr__char map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char(struct ctx* ctx, struct arr__arr__char a, struct fun_mut1__ptr__char__arr__char mapper) {
	struct map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0___closure* temp0;
	return make_arr__arr__ptr__char__nat__fun_mut1__ptr__char__nat(ctx, a.size, (struct fun_mut1__ptr__char__nat) {(fun_ptr3__ptr__char__ptr_ctx__ptr__byte__nat) map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0, (uint8_t*) (temp0 = (struct map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0___closure)), ((*(temp0) = (struct map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0___closure) {mapper, a}, 0), temp0))});
}
char* call__ptr__char__fun_mut1__ptr__char__arr__char__arr__char(struct ctx* ctx, struct fun_mut1__ptr__char__arr__char f, struct arr__char p0) {
	return call_with_ctx__ptr__char__ptr_ctx__fun_mut1__ptr__char__arr__char__arr__char(ctx, f, p0);
}
char* call_with_ctx__ptr__char__ptr_ctx__fun_mut1__ptr__char__arr__char__arr__char(struct ctx* c, struct fun_mut1__ptr__char__arr__char f, struct arr__char p0) {
	return f.fun_ptr(c, f.closure, p0);
}
char* map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0(struct ctx* ctx, struct map__arr__ptr__char__arr__arr__char__fun_mut1__ptr__char__arr__char__lambda0___closure* _closure, uint64_t i) {
	return call__ptr__char__fun_mut1__ptr__char__arr__char__arr__char(ctx, _closure->mapper, at__arr__char__arr__arr__char__nat(ctx, _closure->a, i));
}
char* convert_args__ptr__ptr__char__ptr__char__arr__arr__char__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr__char it) {
	return to_c_str__ptr__char__arr__char(ctx, it);
}
char** convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char(struct ctx* ctx, struct dict__arr__char__arr__char* environ) {
	struct mut_arr__ptr__char* res;
	struct convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char__lambda0___closure* temp0;
	res = new_mut_arr__ptr_mut_arr__ptr__char(ctx);
	each___void__ptr_dict__arr__char__arr__char__fun_mut2___void__arr__char__arr__char(ctx, environ, (struct fun_mut2___void__arr__char__arr__char) {(fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__arr__char) convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char__lambda0, (uint8_t*) (temp0 = (struct convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char__lambda0___closure)), ((*(temp0) = (struct convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char__lambda0___closure) {res}, 0), temp0))});
	push___void__ptr_mut_arr__ptr__char__ptr__char(ctx, res, NULL);
	return freeze__arr__ptr__char__ptr_mut_arr__ptr__char(res).data;
}
struct mut_arr__ptr__char* new_mut_arr__ptr_mut_arr__ptr__char(struct ctx* ctx) {
	struct mut_arr__ptr__char* temp0;
	temp0 = (struct mut_arr__ptr__char*) alloc__ptr__byte__nat(ctx, sizeof(struct mut_arr__ptr__char));
	(*(temp0) = (struct mut_arr__ptr__char) {0, 0, 0, NULL}, 0);
	return temp0;
}
uint8_t each___void__ptr_dict__arr__char__arr__char__fun_mut2___void__arr__char__arr__char(struct ctx* ctx, struct dict__arr__char__arr__char* d, struct fun_mut2___void__arr__char__arr__char f) {
	struct dict__arr__char__arr__char* temp0;
	struct ctx* _tailCallctx;
	struct dict__arr__char__arr__char* _tailCalld;
	struct fun_mut2___void__arr__char__arr__char _tailCallf;
	top:
	if (empty__q__bool__ptr_dict__arr__char__arr__char(ctx, d)) {
		return 0;
	} else {
		call___void__fun_mut2___void__arr__char__arr__char__arr__char__arr__char(ctx, f, first__arr__char__arr__arr__char(ctx, d->keys), first__arr__char__arr__arr__char(ctx, d->values));
		_tailCallctx = ctx;
		_tailCalld = (temp0 = (struct dict__arr__char__arr__char*) alloc__ptr__byte__nat(ctx, sizeof(struct dict__arr__char__arr__char)), ((*(temp0) = (struct dict__arr__char__arr__char) {tail__arr__arr__char__arr__arr__char(ctx, d->keys), tail__arr__arr__char__arr__arr__char(ctx, d->values)}, 0), temp0));
		_tailCallf = f;
		ctx = _tailCallctx;
		d = _tailCalld;
		f = _tailCallf;
		goto top;
	}
}
uint8_t empty__q__bool__ptr_dict__arr__char__arr__char(struct ctx* ctx, struct dict__arr__char__arr__char* d) {
	return empty__q__bool__arr__arr__char(d->keys);
}
uint8_t call___void__fun_mut2___void__arr__char__arr__char__arr__char__arr__char(struct ctx* ctx, struct fun_mut2___void__arr__char__arr__char f, struct arr__char p0, struct arr__char p1) {
	return call_with_ctx___void__ptr_ctx__fun_mut2___void__arr__char__arr__char__arr__char__arr__char(ctx, f, p0, p1);
}
uint8_t call_with_ctx___void__ptr_ctx__fun_mut2___void__arr__char__arr__char__arr__char__arr__char(struct ctx* c, struct fun_mut2___void__arr__char__arr__char f, struct arr__char p0, struct arr__char p1) {
	return f.fun_ptr(c, f.closure, p0, p1);
}
uint8_t push___void__ptr_mut_arr__ptr__char__ptr__char(struct ctx* ctx, struct mut_arr__ptr__char* a, char* value) {
	if (_op_equal_equal__bool__nat__nat(a->size, a->capacity)) {
		increase_capacity_to___void__ptr_mut_arr__ptr__char__nat(ctx, a, (zero__q__bool__nat(a->size) ? four__nat() : _op_times__nat__nat__nat(ctx, a->size, two__nat())));
	} else {
		0;
	}
	ensure_capacity___void__ptr_mut_arr__ptr__char__nat(ctx, a, round_up_to_power_of_two__nat__nat(ctx, incr__nat__nat(ctx, a->size)));
	assert___void__bool(ctx, _op_less__bool__nat__nat(a->size, a->capacity));
	(*((a->data + a->size)) = value, 0);
	return (a->size = incr__nat__nat(ctx, a->size), 0);
}
uint8_t increase_capacity_to___void__ptr_mut_arr__ptr__char__nat(struct ctx* ctx, struct mut_arr__ptr__char* a, uint64_t new_capacity) {
	char** old_data;
	assert___void__bool(ctx, _op_greater__bool__nat__nat(new_capacity, a->capacity));
	old_data = a->data;
	(a->capacity = new_capacity, 0);
	(a->data = uninitialized_data__ptr__ptr__char__nat(ctx, new_capacity), 0);
	return copy_data_from___void__ptr__ptr__char__ptr__ptr__char__nat(ctx, a->data, old_data, a->size);
}
uint8_t copy_data_from___void__ptr__ptr__char__ptr__ptr__char__nat(struct ctx* ctx, char** to, char** from, uint64_t len) {
	uint64_t hl;
	struct ctx* _tailCallctx;
	char** _tailCallto;
	char** _tailCallfrom;
	uint64_t _tailCalllen;
	top:
	if (_op_less__bool__nat__nat(len, eight__nat())) {
		return copy_data_from_small___void__ptr__ptr__char__ptr__ptr__char__nat(ctx, to, from, len);
	} else {
		hl = _op_div__nat__nat__nat(ctx, len, two__nat());
		copy_data_from___void__ptr__ptr__char__ptr__ptr__char__nat(ctx, to, from, hl);
		_tailCallctx = ctx;
		_tailCallto = (to + hl);
		_tailCallfrom = (from + hl);
		_tailCalllen = _op_minus__nat__nat__nat(ctx, len, hl);
		ctx = _tailCallctx;
		to = _tailCallto;
		from = _tailCallfrom;
		len = _tailCalllen;
		goto top;
	}
}
uint8_t copy_data_from_small___void__ptr__ptr__char__ptr__ptr__char__nat(struct ctx* ctx, char** to, char** from, uint64_t len) {
	if (zero__q__bool__nat(len)) {
		return 0;
	} else {
		(*(to) = (*(from)), 0);
		return copy_data_from___void__ptr__ptr__char__ptr__ptr__char__nat(ctx, incr__ptr__ptr__char__ptr__ptr__char(to), incr__ptr__ptr__char__ptr__ptr__char(from), decr__nat__nat(ctx, len));
	}
}
uint8_t ensure_capacity___void__ptr_mut_arr__ptr__char__nat(struct ctx* ctx, struct mut_arr__ptr__char* a, uint64_t capacity) {
	if (_op_less__bool__nat__nat(a->capacity, capacity)) {
		return increase_capacity_to___void__ptr_mut_arr__ptr__char__nat(ctx, a, round_up_to_power_of_two__nat__nat(ctx, capacity));
	} else {
		return 0;
	}
}
uint8_t convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char__lambda0(struct ctx* ctx, struct convert_environ__ptr__ptr__char__ptr_dict__arr__char__arr__char__lambda0___closure* _closure, struct arr__char key, struct arr__char value) {
	return push___void__ptr_mut_arr__ptr__char__ptr__char(ctx, _closure->res, to_c_str__ptr__char__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, key, (struct arr__char) {1, "="}), value)));
}
struct process_result* fail__ptr_process_result__arr__char(struct ctx* ctx, struct arr__char reason) {
	return throw__ptr_process_result__exception(ctx, (struct exception) {reason});
}
struct process_result* throw__ptr_process_result__exception(struct ctx* ctx, struct exception e) {
	struct exception_ctx* exn_ctx;
	exn_ctx = get_exception_ctx__ptr_exception_ctx(ctx);
	hard_forbid___void__bool(_op_equal_equal__bool__ptr__jmp_buf_tag__ptr__jmp_buf_tag(exn_ctx->jmp_buf_ptr, NULL));
	(exn_ctx->thrown_exception = e, 0);
	(longjmp(exn_ctx->jmp_buf_ptr, number_to_throw__int32(ctx)), 0);
	return todo__ptr_process_result();
}
struct process_result* todo__ptr_process_result() {
	return (assert(0),NULL);
}
struct arr__char remove_colors__arr__char__arr__char(struct ctx* ctx, struct arr__char s) {
	struct mut_arr__char* out;
	out = new_mut_arr__ptr_mut_arr__char(ctx);
	remove_colors_recur___void__arr__char__ptr_mut_arr__char(ctx, s, out);
	return freeze__arr__char__ptr_mut_arr__char(out);
}
uint8_t remove_colors_recur___void__arr__char__ptr_mut_arr__char(struct ctx* ctx, struct arr__char s, struct mut_arr__char* out) {
	struct ctx* _tailCallctx;
	struct arr__char _tailCalls;
	struct mut_arr__char* _tailCallout;
	top:
	if (empty__q__bool__arr__char(s)) {
		return 0;
	} else {
		if (_op_equal_equal__bool__char__char(first__char__arr__char(ctx, s), literal__char__arr__char((struct arr__char) {1, "\x1b"}))) {
			return remove_colors_recur_2___void__arr__char__ptr_mut_arr__char(ctx, tail__arr__char__arr__char(ctx, s), out);
		} else {
			push___void__ptr_mut_arr__char__char(ctx, out, first__char__arr__char(ctx, s));
			_tailCallctx = ctx;
			_tailCalls = tail__arr__char__arr__char(ctx, s);
			_tailCallout = out;
			ctx = _tailCallctx;
			s = _tailCalls;
			out = _tailCallout;
			goto top;
		}
	}
}
uint8_t remove_colors_recur_2___void__arr__char__ptr_mut_arr__char(struct ctx* ctx, struct arr__char s, struct mut_arr__char* out) {
	struct ctx* _tailCallctx;
	struct arr__char _tailCalls;
	struct mut_arr__char* _tailCallout;
	top:
	if (empty__q__bool__arr__char(s)) {
		return 0;
	} else {
		if (_op_equal_equal__bool__char__char(first__char__arr__char(ctx, s), literal__char__arr__char((struct arr__char) {1, "m"}))) {
			return remove_colors_recur___void__arr__char__ptr_mut_arr__char(ctx, tail__arr__char__arr__char(ctx, s), out);
		} else {
			_tailCallctx = ctx;
			_tailCalls = tail__arr__char__arr__char(ctx, s);
			_tailCallout = out;
			ctx = _tailCallctx;
			s = _tailCalls;
			out = _tailCallout;
			goto top;
		}
	}
}
uint8_t push___void__ptr_mut_arr__char__char(struct ctx* ctx, struct mut_arr__char* a, char value) {
	if (_op_equal_equal__bool__nat__nat(a->size, a->capacity)) {
		increase_capacity_to___void__ptr_mut_arr__char__nat(ctx, a, (zero__q__bool__nat(a->size) ? four__nat() : _op_times__nat__nat__nat(ctx, a->size, two__nat())));
	} else {
		0;
	}
	ensure_capacity___void__ptr_mut_arr__char__nat(ctx, a, round_up_to_power_of_two__nat__nat(ctx, incr__nat__nat(ctx, a->size)));
	assert___void__bool(ctx, _op_less__bool__nat__nat(a->size, a->capacity));
	(*((a->data + a->size)) = value, 0);
	return (a->size = incr__nat__nat(ctx, a->size), 0);
}
struct arr__ptr_failure handle_output__arr__ptr_failure__arr__char__arr__char__arr__char__bool(struct ctx* ctx, struct arr__char original_path, struct arr__char output_path, struct arr__char actual, uint8_t overwrite_output__q) {
	struct arr__ptr_failure arr;
	struct some__arr__char s;
	struct arr__char message;
	struct arr__ptr_failure arr1;
	struct opt__arr__char matched;
	struct failure** temp0;
	struct failure* temp1;
	struct failure** temp2;
	struct failure* temp3;
	matched = try_read_file__opt__arr__char__arr__char(ctx, output_path);
	switch (matched.kind) {
		case 0:
			if (overwrite_output__q) {
				write_file___void__arr__char__arr__char(ctx, output_path, actual);
				return empty_arr__arr__ptr_failure();
			} else {
				temp0 = (struct failure**) alloc__ptr__byte__nat(ctx, (sizeof(struct failure*) * 1));
				(*((temp0 + 0)) = (temp1 = (struct failure*) alloc__ptr__byte__nat(ctx, sizeof(struct failure)), ((*(temp1) = (struct failure) {original_path, _op_plus__arr__char__arr__char__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, base_name__arr__char__arr__char(ctx, output_path), (struct arr__char) {29, " does not exist. actual was:\n"}), actual)}, 0), temp1)), 0);
				return (struct arr__ptr_failure) {1, temp0};
			}
		case 1:
			s = matched.as1;
			if (_op_equal_equal__bool__arr__char__arr__char(s.value, actual)) {
				return empty_arr__arr__ptr_failure();
			} else {
				if (overwrite_output__q) {
					write_file___void__arr__char__arr__char(ctx, output_path, actual);
					return empty_arr__arr__ptr_failure();
				} else {
					message = _op_plus__arr__char__arr__char__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, base_name__arr__char__arr__char(ctx, output_path), (struct arr__char) {30, " was not as expected. actual:\n"}), actual);
					temp2 = (struct failure**) alloc__ptr__byte__nat(ctx, (sizeof(struct failure*) * 1));
					(*((temp2 + 0)) = (temp3 = (struct failure*) alloc__ptr__byte__nat(ctx, sizeof(struct failure)), ((*(temp3) = (struct failure) {original_path, message}, 0), temp3)), 0);
					return (struct arr__ptr_failure) {1, temp2};
				}
			}
		default:
			return (assert(0),(struct arr__ptr_failure) {0, NULL});
	}
}
struct opt__arr__char try_read_file__opt__arr__char__arr__char(struct ctx* ctx, struct arr__char path) {
	return try_read_file__opt__arr__char__ptr__char(ctx, to_c_str__ptr__char__arr__char(ctx, path));
}
struct opt__arr__char try_read_file__opt__arr__char__ptr__char(struct ctx* ctx, char* path) {
	int32_t fd;
	int32_t errno;
	int64_t file_size;
	int64_t off;
	uint64_t file_size_nat;
	struct mut_arr__char* res;
	int64_t n_bytes_read;
	if (is_file__q__bool__ptr__char(ctx, path)) {
		fd = open(path, o_rdonly__int32(ctx), literal__int32__arr__char(ctx, (struct arr__char) {1, "0"}));
		if (_op_equal_equal__bool__int32__int32(fd, neg_one__int32())) {
			errno = errno;
			if (_op_equal_equal__bool__int32__int32(errno, enoent__int32())) {
				return (struct opt__arr__char) {0, .as0 = none__none()};
			} else {
				print_sync___void__arr__char(_op_plus__arr__char__arr__char__arr__char(ctx, (struct arr__char) {20, "failed to open file "}, to_str__arr__char__ptr__char(path)));
				return todo__opt__arr__char();
			}
		} else {
			file_size = lseek(fd, 0, seek_end__int32(ctx));
			forbid___void__bool(ctx, _op_equal_equal__bool___int___int(file_size, neg_one___int()));
			assert___void__bool(ctx, _op_less__bool___int___int(file_size, billion___int()));
			forbid___void__bool(ctx, zero__q__bool___int(file_size));
			off = lseek(fd, 0, seek_set__int32(ctx));
			assert___void__bool(ctx, _op_equal_equal__bool___int___int(off, 0));
			file_size_nat = to_nat__nat___int(ctx, file_size);
			res = new_uninitialized_mut_arr__ptr_mut_arr__char__nat(ctx, file_size_nat);
			n_bytes_read = read(fd, (uint8_t*) res->data, file_size_nat);
			forbid___void__bool(ctx, _op_equal_equal__bool___int___int(n_bytes_read, neg_one___int()));
			assert___void__bool(ctx, _op_equal_equal__bool___int___int(n_bytes_read, file_size));
			check_posix_error___void__int32(ctx, close(fd));
			return (struct opt__arr__char) {1, .as1 = some__some__arr__char__arr__char(freeze__arr__char__ptr_mut_arr__char(res))};
		}
	} else {
		return (struct opt__arr__char) {0, .as0 = none__none()};
	}
}
int32_t o_rdonly__int32(struct ctx* ctx) {
	return 0;
}
struct opt__arr__char todo__opt__arr__char() {
	return (assert(0),(struct opt__arr__char) {0});
}
int32_t seek_end__int32(struct ctx* ctx) {
	return two__int32();
}
int64_t billion___int() {
	return (million___int() * thousand___int());
}
uint8_t zero__q__bool___int(int64_t i) {
	return _op_equal_equal__bool___int___int(i, 0);
}
int32_t seek_set__int32(struct ctx* ctx) {
	return 0;
}
uint8_t write_file___void__arr__char__arr__char(struct ctx* ctx, struct arr__char path, struct arr__char content) {
	return write_file___void__ptr__char__arr__char(ctx, to_c_str__ptr__char__arr__char(ctx, path), content);
}
uint8_t write_file___void__ptr__char__arr__char(struct ctx* ctx, char* path, struct arr__char content) {
	int32_t permission_rdwr;
	int32_t permission_rd;
	int32_t permission;
	int32_t flags;
	int32_t fd;
	int32_t errno;
	int64_t wrote_bytes;
	int32_t err;
	permission_rdwr = six__int32();
	permission_rd = four__int32();
	permission = (((permission_rdwr << six__int32()) | (permission_rd << three__int32())) | permission_rd);
	flags = ((o_creat__int32(ctx) | o_wronly__int32(ctx)) | o_trunc__int32(ctx));
	fd = open(path, flags, permission);
	if (_op_equal_equal__bool__int32__int32(fd, neg_one__int32())) {
		errno = errno;
		print_sync___void__arr__char(_op_plus__arr__char__arr__char__arr__char(ctx, (struct arr__char) {31, "failed to open file for write: "}, to_str__arr__char__ptr__char(path)));
		print_sync___void__arr__char(_op_plus__arr__char__arr__char__arr__char(ctx, (struct arr__char) {7, "errno: "}, to_str__arr__char__int32(ctx, errno)));
		print_sync___void__arr__char(_op_plus__arr__char__arr__char__arr__char(ctx, (struct arr__char) {7, "flags: "}, to_str__arr__char__int32(ctx, flags)));
		print_sync___void__arr__char(_op_plus__arr__char__arr__char__arr__char(ctx, (struct arr__char) {12, "permission: "}, to_str__arr__char__int32(ctx, permission)));
		return todo___void();
	} else {
		wrote_bytes = write(fd, (uint8_t*) content.data, content.size);
		if (_op_equal_equal__bool___int___int(wrote_bytes, to_int___int__nat(ctx, content.size))) {
			0;
		} else {
			if (_op_equal_equal__bool___int___int(wrote_bytes, literal___int__arr__char(ctx, (struct arr__char) {2, "-1"}))) {
				todo___void();
			} else {
				todo___void();
			}
		}
		err = close(fd);
		if (_op_equal_equal__bool__int32__int32(err, 0)) {
			return 0;
		} else {
			return todo___void();
		}
	}
}
int32_t o_creat__int32(struct ctx* ctx) {
	return (1 << six__int32());
}
int32_t o_wronly__int32(struct ctx* ctx) {
	return 1;
}
int32_t o_trunc__int32(struct ctx* ctx) {
	return (1 << nine__int32());
}
struct arr__ptr_failure empty_arr__arr__ptr_failure() {
	return (struct arr__ptr_failure) {0, NULL};
}
struct arr__ptr_failure run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0(struct ctx* ctx, struct run_compile_error_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure* _closure, struct arr__char test) {
	if (_closure->options.print_tests__q) {
		print_sync___void__arr__char(_op_plus__arr__char__arr__char__arr__char(ctx, (struct arr__char) {11, "noze build "}, test));
	} else {
		0;
	}
	return run_single_compile_error_test__arr__ptr_failure__arr__char__ptr_dict__arr__char__arr__char__arr__char__bool(ctx, _closure->path_to_noze, _closure->env, test, _closure->options.overwrite_output__q);
}
uint8_t has__q__bool__arr__ptr_failure(struct arr__ptr_failure a) {
	return !empty__q__bool__arr__ptr_failure(a);
}
struct err__arr__ptr_failure err__err__arr__ptr_failure__arr__ptr_failure(struct arr__ptr_failure t) {
	return (struct err__arr__ptr_failure) {t};
}
struct arr__ptr_failure with_max_size__arr__ptr_failure__arr__ptr_failure__nat(struct ctx* ctx, struct arr__ptr_failure a, uint64_t max_size) {
	if (_op_greater__bool__nat__nat(a.size, max_size)) {
		return slice__arr__ptr_failure__arr__ptr_failure__nat__nat(ctx, a, 0, max_size);
	} else {
		return a;
	}
}
struct ok__arr__char ok__ok__arr__char__arr__char(struct arr__char t) {
	return (struct ok__arr__char) {t};
}
struct result__arr__char__arr__ptr_failure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure(struct ctx* ctx, struct result__arr__char__arr__ptr_failure a, struct fun0__result__arr__char__arr__ptr_failure b) {
	struct first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0___closure* temp0;
	return then__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun_mut1__result__arr__char__arr__ptr_failure__arr__char(ctx, a, (struct fun_mut1__result__arr__char__arr__ptr_failure__arr__char) {(fun_ptr3__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char) first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0, (uint8_t*) (temp0 = (struct first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0___closure)), ((*(temp0) = (struct first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0___closure) {b}, 0), temp0))});
}
struct result__arr__char__arr__ptr_failure then__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun_mut1__result__arr__char__arr__ptr_failure__arr__char(struct ctx* ctx, struct result__arr__char__arr__ptr_failure a, struct fun_mut1__result__arr__char__arr__ptr_failure__arr__char f) {
	struct ok__arr__char o;
	struct err__arr__ptr_failure e;
	struct result__arr__char__arr__ptr_failure matched;
	matched = a;
	switch (matched.kind) {
		case 0:
			o = matched.as0;
			return call__result__arr__char__arr__ptr_failure__fun_mut1__result__arr__char__arr__ptr_failure__arr__char__arr__char(ctx, f, o.value);
		case 1:
			e = matched.as1;
			return (struct result__arr__char__arr__ptr_failure) {1, .as1 = e};
		default:
			return (assert(0),(struct result__arr__char__arr__ptr_failure) {0});
	}
}
struct result__arr__char__arr__ptr_failure call__result__arr__char__arr__ptr_failure__fun_mut1__result__arr__char__arr__ptr_failure__arr__char__arr__char(struct ctx* ctx, struct fun_mut1__result__arr__char__arr__ptr_failure__arr__char f, struct arr__char p0) {
	return call_with_ctx__result__arr__char__arr__ptr_failure__ptr_ctx__fun_mut1__result__arr__char__arr__ptr_failure__arr__char__arr__char(ctx, f, p0);
}
struct result__arr__char__arr__ptr_failure call_with_ctx__result__arr__char__arr__ptr_failure__ptr_ctx__fun_mut1__result__arr__char__arr__ptr_failure__arr__char__arr__char(struct ctx* c, struct fun_mut1__result__arr__char__arr__ptr_failure__arr__char f, struct arr__char p0) {
	return f.fun_ptr(c, f.closure, p0);
}
struct result__arr__char__arr__ptr_failure call__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure(struct ctx* ctx, struct fun0__result__arr__char__arr__ptr_failure f) {
	return call_with_ctx__result__arr__char__arr__ptr_failure__ptr_ctx__fun0__result__arr__char__arr__ptr_failure(ctx, f);
}
struct result__arr__char__arr__ptr_failure call_with_ctx__result__arr__char__arr__ptr_failure__ptr_ctx__fun0__result__arr__char__arr__ptr_failure(struct ctx* c, struct fun0__result__arr__char__arr__ptr_failure f) {
	return f.fun_ptr(c, f.closure);
}
struct result__arr__char__arr__ptr_failure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0__lambda0(struct ctx* ctx, struct first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0__lambda0___closure* _closure, struct arr__char b_descr) {
	return (struct result__arr__char__arr__ptr_failure) {0, .as0 = ok__ok__arr__char__arr__char(_op_plus__arr__char__arr__char__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, _closure->a_descr, (struct arr__char) {1, "\n"}), b_descr))};
}
struct result__arr__char__arr__ptr_failure first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0(struct ctx* ctx, struct first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0___closure* _closure, struct arr__char a_descr) {
	struct first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0__lambda0___closure* temp0;
	return then__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun_mut1__result__arr__char__arr__ptr_failure__arr__char(ctx, call__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure(ctx, _closure->b), (struct fun_mut1__result__arr__char__arr__ptr_failure__arr__char) {(fun_ptr3__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char) first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0__lambda0, (uint8_t*) (temp0 = (struct first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0__lambda0___closure)), ((*(temp0) = (struct first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure__lambda0__lambda0___closure) {a_descr}, 0), temp0))});
}
struct result__arr__char__arr__ptr_failure run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options(struct ctx* ctx, struct arr__char path, struct arr__char path_to_noze, struct dict__arr__char__arr__char* env, struct test_options options) {
	struct arr__arr__char tests;
	struct arr__ptr_failure failures;
	struct run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure* temp0;
	tests = list_ast_and_model_tests__arr__arr__char__arr__char(ctx, path);
	failures = flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char(ctx, tests, options.max_failures, (struct fun_mut1__arr__ptr_failure__arr__char) {(fun_ptr3__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char) run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0, (uint8_t*) (temp0 = (struct run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure)), ((*(temp0) = (struct run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure) {options, path_to_noze, env}, 0), temp0))});
	if (has__q__bool__arr__ptr_failure(failures)) {
		return (struct result__arr__char__arr__ptr_failure) {1, .as1 = err__err__arr__ptr_failure__arr__ptr_failure(failures)};
	} else {
		return (struct result__arr__char__arr__ptr_failure) {0, .as0 = ok__ok__arr__char__arr__char(_op_plus__arr__char__arr__char__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, (struct arr__char) {4, "ran "}, to_str__arr__char__nat(ctx, tests.size)), (struct arr__char) {10, " ast tests"}))};
	}
}
struct arr__arr__char list_ast_and_model_tests__arr__arr__char__arr__char(struct ctx* ctx, struct arr__char path) {
	struct mut_arr__arr__char* res;
	struct fun_mut1__bool__arr__char filter;
	struct list_ast_and_model_tests__arr__arr__char__arr__char__lambda1___closure* temp0;
	res = new_mut_arr__ptr_mut_arr__arr__char(ctx);
	filter = (struct fun_mut1__bool__arr__char) {(fun_ptr3__bool__ptr_ctx__ptr__byte__arr__char) list_ast_and_model_tests__arr__arr__char__arr__char__lambda0, (uint8_t*) NULL};
	each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char(ctx, path, filter, (struct fun_mut1___void__arr__char) {(fun_ptr3___void__ptr_ctx__ptr__byte__arr__char) list_ast_and_model_tests__arr__arr__char__arr__char__lambda1, (uint8_t*) (temp0 = (struct list_ast_and_model_tests__arr__arr__char__arr__char__lambda1___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct list_ast_and_model_tests__arr__arr__char__arr__char__lambda1___closure)), ((*(temp0) = (struct list_ast_and_model_tests__arr__arr__char__arr__char__lambda1___closure) {res}, 0), temp0))});
	return freeze__arr__arr__char__ptr_mut_arr__arr__char(res);
}
uint8_t list_ast_and_model_tests__arr__arr__char__arr__char__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr__char s) {
	return 1;
}
uint8_t list_ast_and_model_tests__arr__arr__char__arr__char__lambda1(struct ctx* ctx, struct list_ast_and_model_tests__arr__arr__char__arr__char__lambda1___closure* _closure, struct arr__char child) {
	struct some__arr__char s;
	struct opt__arr__char matched;
	matched = get_extension__opt__arr__char__arr__char(ctx, base_name__arr__char__arr__char(ctx, child));
	switch (matched.kind) {
		case 0:
			return 0;
		case 1:
			s = matched.as1;
			if (_op_equal_equal__bool__arr__char__arr__char(s.value, (struct arr__char) {2, "nz"})) {
				return push___void__ptr_mut_arr__arr__char__arr__char(ctx, _closure->res, child);
			} else {
				return 0;
			}
		default:
			return (assert(0),0);
	}
}
struct opt__arr__ptr_failure first_some__opt__arr__ptr_failure__arr__arr__char__fun_mut1__opt__arr__ptr_failure__arr__char(struct ctx* ctx, struct arr__arr__char a, struct fun_mut1__opt__arr__ptr_failure__arr__char cb) {
	struct some__arr__ptr_failure s;
	struct opt__arr__ptr_failure matched;
	struct ctx* _tailCallctx;
	struct arr__arr__char _tailCalla;
	struct fun_mut1__opt__arr__ptr_failure__arr__char _tailCallcb;
	top:
	if (empty__q__bool__arr__arr__char(a)) {
		return (struct opt__arr__ptr_failure) {0, .as0 = none__none()};
	} else {
		matched = call__opt__arr__ptr_failure__fun_mut1__opt__arr__ptr_failure__arr__char__arr__char(ctx, cb, first__arr__char__arr__arr__char(ctx, a));
		switch (matched.kind) {
			case 0:
				_tailCallctx = ctx;
				_tailCalla = tail__arr__arr__char__arr__arr__char(ctx, a);
				_tailCallcb = cb;
				ctx = _tailCallctx;
				a = _tailCalla;
				cb = _tailCallcb;
				goto top;
			case 1:
				s = matched.as1;
				return (struct opt__arr__ptr_failure) {1, .as1 = s};
			default:
				return (assert(0),(struct opt__arr__ptr_failure) {0});
		}
	}
}
struct opt__arr__ptr_failure call__opt__arr__ptr_failure__fun_mut1__opt__arr__ptr_failure__arr__char__arr__char(struct ctx* ctx, struct fun_mut1__opt__arr__ptr_failure__arr__char f, struct arr__char p0) {
	return call_with_ctx__opt__arr__ptr_failure__ptr_ctx__fun_mut1__opt__arr__ptr_failure__arr__char__arr__char(ctx, f, p0);
}
struct opt__arr__ptr_failure call_with_ctx__opt__arr__ptr_failure__ptr_ctx__fun_mut1__opt__arr__ptr_failure__arr__char__arr__char(struct ctx* c, struct fun_mut1__opt__arr__ptr_failure__arr__char f, struct arr__char p0) {
	return f.fun_ptr(c, f.closure, p0);
}
struct arr__ptr_failure run_single_ast_or_model_test__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__arr__char__bool(struct ctx* ctx, struct arr__char ast_or_model, struct arr__char path_to_noze, struct dict__arr__char__arr__char* env, struct arr__char path, uint8_t overwrite_output__q) {
	struct arr__arr__char arr;
	struct process_result* res;
	struct arr__char message;
	struct arr__ptr_failure arr1;
	struct arr__char* temp0;
	struct failure** temp1;
	struct failure* temp2;
	res = spawn_and_wait_result__ptr_process_result__arr__char__arr__arr__char__ptr_dict__arr__char__arr__char(ctx, path_to_noze, (temp0 = (struct arr__char*) alloc__ptr__byte__nat(ctx, (sizeof(struct arr__char) * 3)), ((*((temp0 + 0)) = (struct arr__char) {5, "print"}, 0), ((*((temp0 + 1)) = ast_or_model, 0), ((*((temp0 + 2)) = path, 0), (struct arr__arr__char) {3, temp0})))), env);
	if ((_op_equal_equal__bool__int32__int32(res->exit_code, literal__int32__arr__char(ctx, (struct arr__char) {1, "0"})) && _op_equal_equal__bool__arr__char__arr__char(res->stderr, (struct arr__char) {0, ""}))) {
		return handle_output__arr__ptr_failure__arr__char__arr__char__arr__char__bool(ctx, path, _op_plus__arr__char__arr__char__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, path, (struct arr__char) {1, "."}), ast_or_model), (struct arr__char) {5, ".tata"}), res->stdout, overwrite_output__q);
	} else {
		message = _op_plus__arr__char__arr__char__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, (struct arr__char) {8, "status: "}, to_str__arr__char__int32(ctx, res->exit_code)), (struct arr__char) {9, "\nstdout:\n"}), res->stdout), (struct arr__char) {8, "stderr:\n"}), res->stderr);
		temp1 = (struct failure**) alloc__ptr__byte__nat(ctx, (sizeof(struct failure*) * 1));
		(*((temp1 + 0)) = (temp2 = (struct failure*) alloc__ptr__byte__nat(ctx, sizeof(struct failure)), ((*(temp2) = (struct failure) {path, message}, 0), temp2)), 0);
		return (struct arr__ptr_failure) {1, temp1};
	}
}
struct some__arr__ptr_failure some__some__arr__ptr_failure__arr__ptr_failure(struct arr__ptr_failure t) {
	return (struct some__arr__ptr_failure) {t};
}
struct opt__arr__ptr_failure run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0(struct ctx* ctx, struct run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0___closure* _closure, struct arr__char name) {
	struct arr__ptr_failure a;
	a = run_single_ast_or_model_test__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__arr__char__bool(ctx, name, _closure->path_to_noze, _closure->env, _closure->test, _closure->options.overwrite_output__q);
	if (empty__q__bool__arr__ptr_failure(a)) {
		return (struct opt__arr__ptr_failure) {0, .as0 = none__none()};
	} else {
		return (struct opt__arr__ptr_failure) {1, .as1 = some__some__arr__ptr_failure__arr__ptr_failure(a)};
	}
}
struct arr__ptr_failure opt_or__arr__ptr_failure__opt__arr__ptr_failure__fun_mut0__arr__ptr_failure(struct ctx* ctx, struct opt__arr__ptr_failure a, struct fun_mut0__arr__ptr_failure _default) {
	struct none n;
	struct some__arr__ptr_failure s;
	struct opt__arr__ptr_failure matched;
	matched = a;
	switch (matched.kind) {
		case 0:
			n = matched.as0;
			return call__arr__ptr_failure__fun_mut0__arr__ptr_failure(ctx, _default);
		case 1:
			s = matched.as1;
			return s.value;
		default:
			return (assert(0),(struct arr__ptr_failure) {0, NULL});
	}
}
struct arr__ptr_failure call__arr__ptr_failure__fun_mut0__arr__ptr_failure(struct ctx* ctx, struct fun_mut0__arr__ptr_failure f) {
	return call_with_ctx__arr__ptr_failure__ptr_ctx__fun_mut0__arr__ptr_failure(ctx, f);
}
struct arr__ptr_failure call_with_ctx__arr__ptr_failure__ptr_ctx__fun_mut0__arr__ptr_failure(struct ctx* c, struct fun_mut0__arr__ptr_failure f) {
	return f.fun_ptr(c, f.closure);
}
struct arr__ptr_failure run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda1(struct ctx* ctx, uint8_t* _closure) {
	return empty_arr__arr__ptr_failure();
}
struct arr__ptr_failure run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0(struct ctx* ctx, struct run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure* _closure, struct arr__char test) {
	struct arr__arr__char arr;
	struct opt__arr__ptr_failure op;
	struct arr__char* temp0;
	struct run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0___closure* temp1;
	if (_closure->options.print_tests__q) {
		print_sync___void__arr__char(_op_plus__arr__char__arr__char__arr__char(ctx, (struct arr__char) {9, "noze ast "}, test));
	} else {
		0;
	}
	op = first_some__opt__arr__ptr_failure__arr__arr__char__fun_mut1__opt__arr__ptr_failure__arr__char(ctx, (temp0 = (struct arr__char*) alloc__ptr__byte__nat(ctx, (sizeof(struct arr__char) * 4)), ((*((temp0 + 0)) = (struct arr__char) {3, "ast"}, 0), ((*((temp0 + 1)) = (struct arr__char) {5, "model"}, 0), ((*((temp0 + 2)) = (struct arr__char) {14, "concrete-model"}, 0), ((*((temp0 + 3)) = (struct arr__char) {9, "low-model"}, 0), (struct arr__arr__char) {4, temp0}))))), (struct fun_mut1__opt__arr__ptr_failure__arr__char) {(fun_ptr3__opt__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char) run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0, (uint8_t*) (temp1 = (struct run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0___closure)), ((*(temp1) = (struct run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda0___closure) {_closure->path_to_noze, _closure->env, test, _closure->options}, 0), temp1))});
	return opt_or__arr__ptr_failure__opt__arr__ptr_failure__fun_mut0__arr__ptr_failure(ctx, op, (struct fun_mut0__arr__ptr_failure) {(fun_ptr2__arr__ptr_failure__ptr_ctx__ptr__byte) run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0__lambda1, (uint8_t*) NULL});
}
struct result__arr__char__arr__ptr_failure run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options(struct ctx* ctx, struct arr__char path, struct arr__char path_to_noze, struct dict__arr__char__arr__char* env, struct test_options options) {
	struct arr__arr__char tests;
	struct arr__ptr_failure failures;
	struct run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure* temp0;
	tests = list_runnable_tests__arr__arr__char__arr__char(ctx, path);
	failures = flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char(ctx, tests, options.max_failures, (struct fun_mut1__arr__ptr_failure__arr__char) {(fun_ptr3__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char) run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0, (uint8_t*) (temp0 = (struct run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure)), ((*(temp0) = (struct run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure) {options, path_to_noze, env}, 0), temp0))});
	if (has__q__bool__arr__ptr_failure(failures)) {
		return (struct result__arr__char__arr__ptr_failure) {1, .as1 = err__err__arr__ptr_failure__arr__ptr_failure(failures)};
	} else {
		return (struct result__arr__char__arr__ptr_failure) {0, .as0 = ok__ok__arr__char__arr__char(_op_plus__arr__char__arr__char__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, (struct arr__char) {4, "ran "}, to_str__arr__char__nat(ctx, tests.size)), (struct arr__char) {15, " runnable tests"}))};
	}
}
struct arr__arr__char list_runnable_tests__arr__arr__char__arr__char(struct ctx* ctx, struct arr__char path) {
	struct mut_arr__arr__char* res;
	struct fun_mut1__bool__arr__char filter;
	struct list_runnable_tests__arr__arr__char__arr__char__lambda1___closure* temp0;
	res = new_mut_arr__ptr_mut_arr__arr__char(ctx);
	filter = (struct fun_mut1__bool__arr__char) {(fun_ptr3__bool__ptr_ctx__ptr__byte__arr__char) list_runnable_tests__arr__arr__char__arr__char__lambda0, (uint8_t*) NULL};
	each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char(ctx, path, filter, (struct fun_mut1___void__arr__char) {(fun_ptr3___void__ptr_ctx__ptr__byte__arr__char) list_runnable_tests__arr__arr__char__arr__char__lambda1, (uint8_t*) (temp0 = (struct list_runnable_tests__arr__arr__char__arr__char__lambda1___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct list_runnable_tests__arr__arr__char__arr__char__lambda1___closure)), ((*(temp0) = (struct list_runnable_tests__arr__arr__char__arr__char__lambda1___closure) {res}, 0), temp0))});
	return freeze__arr__arr__char__ptr_mut_arr__arr__char(res);
}
uint8_t list_runnable_tests__arr__arr__char__arr__char__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr__char s) {
	return 1;
}
uint8_t list_runnable_tests__arr__arr__char__arr__char__lambda1(struct ctx* ctx, struct list_runnable_tests__arr__arr__char__arr__char__lambda1___closure* _closure, struct arr__char child) {
	struct some__arr__char s;
	struct opt__arr__char matched;
	matched = get_extension__opt__arr__char__arr__char(ctx, base_name__arr__char__arr__char(ctx, child));
	switch (matched.kind) {
		case 0:
			return 0;
		case 1:
			s = matched.as1;
			if (_op_equal_equal__bool__arr__char__arr__char(s.value, (struct arr__char) {2, "nz"})) {
				return push___void__ptr_mut_arr__arr__char__arr__char(ctx, _closure->res, child);
			} else {
				return 0;
			}
		default:
			return (assert(0),0);
	}
}
struct arr__ptr_failure run_single_runnable_test__arr__ptr_failure__arr__char__ptr_dict__arr__char__arr__char__arr__char__bool(struct ctx* ctx, struct arr__char path_to_noze, struct dict__arr__char__arr__char* env, struct arr__char path, uint8_t overwrite_output__q) {
	struct arr__arr__char arr;
	struct process_result* res;
	struct arr__char message;
	struct arr__ptr_failure arr1;
	struct arr__char* temp0;
	struct failure** temp1;
	struct failure* temp2;
	res = spawn_and_wait_result__ptr_process_result__arr__char__arr__arr__char__ptr_dict__arr__char__arr__char(ctx, path_to_noze, (temp0 = (struct arr__char*) alloc__ptr__byte__nat(ctx, (sizeof(struct arr__char) * 2)), ((*((temp0 + 0)) = (struct arr__char) {3, "run"}, 0), ((*((temp0 + 1)) = path, 0), (struct arr__arr__char) {2, temp0}))), env);
	if ((_op_equal_equal__bool__int32__int32(res->exit_code, literal__int32__arr__char(ctx, (struct arr__char) {1, "0"})) && _op_equal_equal__bool__arr__char__arr__char(res->stderr, (struct arr__char) {0, ""}))) {
		return handle_output__arr__ptr_failure__arr__char__arr__char__arr__char__bool(ctx, path, _op_plus__arr__char__arr__char__arr__char(ctx, path, (struct arr__char) {7, ".stdout"}), res->stdout, overwrite_output__q);
	} else {
		message = _op_plus__arr__char__arr__char__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, (struct arr__char) {8, "status: "}, to_str__arr__char__int32(ctx, res->exit_code)), (struct arr__char) {9, "\nstdout:\n"}), res->stdout), (struct arr__char) {8, "stderr:\n"}), res->stderr);
		temp1 = (struct failure**) alloc__ptr__byte__nat(ctx, (sizeof(struct failure*) * 1));
		(*((temp1 + 0)) = (temp2 = (struct failure*) alloc__ptr__byte__nat(ctx, sizeof(struct failure)), ((*(temp2) = (struct failure) {path, message}, 0), temp2)), 0);
		return (struct arr__ptr_failure) {1, temp1};
	}
}
struct arr__ptr_failure run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0(struct ctx* ctx, struct run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options__lambda0___closure* _closure, struct arr__char test) {
	if (_closure->options.print_tests__q) {
		print_sync___void__arr__char(_op_plus__arr__char__arr__char__arr__char(ctx, (struct arr__char) {9, "noze run "}, test));
	} else {
		0;
	}
	return run_single_runnable_test__arr__ptr_failure__arr__char__ptr_dict__arr__char__arr__char__arr__char__bool(ctx, _closure->path_to_noze, _closure->env, test, _closure->options.overwrite_output__q);
}
struct result__arr__char__arr__ptr_failure do_test__int32__test_options__lambda0__lambda0(struct ctx* ctx, struct do_test__int32__test_options__lambda0__lambda0___closure* _closure) {
	return run_runnable_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options(ctx, child_path__arr__char__arr__char__arr__char(ctx, _closure->test_path, (struct arr__char) {8, "runnable"}), _closure->noze_exe, _closure->env, _closure->options);
}
struct result__arr__char__arr__ptr_failure do_test__int32__test_options__lambda0(struct ctx* ctx, struct do_test__int32__test_options__lambda0___closure* _closure) {
	struct do_test__int32__test_options__lambda0__lambda0___closure* temp0;
	return first_failures__result__arr__char__arr__ptr_failure__result__arr__char__arr__ptr_failure__fun0__result__arr__char__arr__ptr_failure(ctx, run_ast_and_model_tests__result__arr__char__arr__ptr_failure__arr__char__arr__char__ptr_dict__arr__char__arr__char__test_options(ctx, child_path__arr__char__arr__char__arr__char(ctx, _closure->test_path, (struct arr__char) {8, "runnable"}), _closure->noze_exe, _closure->env, _closure->options), (struct fun0__result__arr__char__arr__ptr_failure) {(fun_ptr2__result__arr__char__arr__ptr_failure__ptr_ctx__ptr__byte) do_test__int32__test_options__lambda0__lambda0, (uint8_t*) (temp0 = (struct do_test__int32__test_options__lambda0__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct do_test__int32__test_options__lambda0__lambda0___closure)), ((*(temp0) = (struct do_test__int32__test_options__lambda0__lambda0___closure) {_closure->test_path, _closure->noze_exe, _closure->env, _closure->options}, 0), temp0))});
}
struct result__arr__char__arr__ptr_failure lint__result__arr__char__arr__ptr_failure__arr__char__test_options(struct ctx* ctx, struct arr__char path, struct test_options options) {
	struct arr__arr__char files;
	struct arr__ptr_failure failures;
	struct lint__result__arr__char__arr__ptr_failure__arr__char__test_options__lambda0___closure* temp0;
	files = list_lintable_files__arr__arr__char__arr__char(ctx, path);
	failures = flat_map_with_max_size__arr__ptr_failure__arr__arr__char__nat__fun_mut1__arr__ptr_failure__arr__char(ctx, files, options.max_failures, (struct fun_mut1__arr__ptr_failure__arr__char) {(fun_ptr3__arr__ptr_failure__ptr_ctx__ptr__byte__arr__char) lint__result__arr__char__arr__ptr_failure__arr__char__test_options__lambda0, (uint8_t*) (temp0 = (struct lint__result__arr__char__arr__ptr_failure__arr__char__test_options__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct lint__result__arr__char__arr__ptr_failure__arr__char__test_options__lambda0___closure)), ((*(temp0) = (struct lint__result__arr__char__arr__ptr_failure__arr__char__test_options__lambda0___closure) {options}, 0), temp0))});
	if (has__q__bool__arr__ptr_failure(failures)) {
		return (struct result__arr__char__arr__ptr_failure) {1, .as1 = err__err__arr__ptr_failure__arr__ptr_failure(failures)};
	} else {
		return (struct result__arr__char__arr__ptr_failure) {0, .as0 = ok__ok__arr__char__arr__char(_op_plus__arr__char__arr__char__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, (struct arr__char) {7, "Linted "}, to_str__arr__char__nat(ctx, files.size)), (struct arr__char) {6, " files"}))};
	}
}
struct arr__arr__char list_lintable_files__arr__arr__char__arr__char(struct ctx* ctx, struct arr__char path) {
	struct mut_arr__arr__char* res;
	struct list_lintable_files__arr__arr__char__arr__char__lambda1___closure* temp0;
	res = new_mut_arr__ptr_mut_arr__arr__char(ctx);
	each_child_recursive___void__arr__char__fun_mut1__bool__arr__char__fun_mut1___void__arr__char(ctx, path, (struct fun_mut1__bool__arr__char) {(fun_ptr3__bool__ptr_ctx__ptr__byte__arr__char) list_lintable_files__arr__arr__char__arr__char__lambda0, (uint8_t*) NULL}, (struct fun_mut1___void__arr__char) {(fun_ptr3___void__ptr_ctx__ptr__byte__arr__char) list_lintable_files__arr__arr__char__arr__char__lambda1, (uint8_t*) (temp0 = (struct list_lintable_files__arr__arr__char__arr__char__lambda1___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct list_lintable_files__arr__arr__char__arr__char__lambda1___closure)), ((*(temp0) = (struct list_lintable_files__arr__arr__char__arr__char__lambda1___closure) {res}, 0), temp0))});
	return freeze__arr__arr__char__ptr_mut_arr__arr__char(res);
}
uint8_t list_lintable_files__arr__arr__char__arr__char__lambda0(struct ctx* ctx, uint8_t* _closure, struct arr__char it) {
	return !(_op_equal_equal__bool__char__char(first__char__arr__char(ctx, it), literal__char__arr__char((struct arr__char) {1, "."})) || _op_equal_equal__bool__arr__char__arr__char(it, (struct arr__char) {7, "libfirm"}));
}
uint8_t ignore_extension_of_name__bool__arr__char(struct ctx* ctx, struct arr__char name) {
	struct some__arr__char s;
	struct opt__arr__char matched;
	matched = get_extension__opt__arr__char__arr__char(ctx, name);
	switch (matched.kind) {
		case 0:
			return 1;
		case 1:
			s = matched.as1;
			return ignore_extension__bool__arr__char(ctx, s.value);
		default:
			return (assert(0),0);
	}
}
uint8_t ignore_extension__bool__arr__char(struct ctx* ctx, struct arr__char ext) {
	return contains__q__bool__arr__arr__char__arr__char(ignored_extensions__arr__arr__char(ctx), ext);
}
uint8_t contains__q__bool__arr__arr__char__arr__char(struct arr__arr__char a, struct arr__char value) {
	return contains_recur__q__bool__arr__arr__char__arr__char__nat(a, value, 0);
}
uint8_t contains_recur__q__bool__arr__arr__char__arr__char__nat(struct arr__arr__char a, struct arr__char value, uint64_t i) {
	struct arr__arr__char _tailCalla;
	struct arr__char _tailCallvalue;
	uint64_t _tailCalli;
	top:
	if (_op_equal_equal__bool__nat__nat(i, a.size)) {
		return 0;
	} else {
		if (_op_equal_equal__bool__arr__char__arr__char(noctx_at__arr__char__arr__arr__char__nat(a, i), value)) {
			return 1;
		} else {
			_tailCalla = a;
			_tailCallvalue = value;
			_tailCalli = noctx_incr__nat__nat(i);
			a = _tailCalla;
			value = _tailCallvalue;
			i = _tailCalli;
			goto top;
		}
	}
}
struct arr__arr__char ignored_extensions__arr__arr__char(struct ctx* ctx) {
	struct arr__arr__char arr;
	struct arr__char* temp0;
	temp0 = (struct arr__char*) alloc__ptr__byte__nat(ctx, (sizeof(struct arr__char) * 6));
	(*((temp0 + 0)) = (struct arr__char) {1, "c"}, 0);
	(*((temp0 + 1)) = (struct arr__char) {4, "data"}, 0);
	(*((temp0 + 2)) = (struct arr__char) {1, "o"}, 0);
	(*((temp0 + 3)) = (struct arr__char) {3, "out"}, 0);
	(*((temp0 + 4)) = (struct arr__char) {4, "tata"}, 0);
	(*((temp0 + 5)) = (struct arr__char) {10, "tmLanguage"}, 0);
	return (struct arr__arr__char) {6, temp0};
}
uint8_t list_lintable_files__arr__arr__char__arr__char__lambda1(struct ctx* ctx, struct list_lintable_files__arr__arr__char__arr__char__lambda1___closure* _closure, struct arr__char child) {
	if (ignore_extension_of_name__bool__arr__char(ctx, base_name__arr__char__arr__char(ctx, child))) {
		return 0;
	} else {
		return push___void__ptr_mut_arr__arr__char__arr__char(ctx, _closure->res, child);
	}
}
struct arr__ptr_failure lint_file__arr__ptr_failure__arr__char(struct ctx* ctx, struct arr__char path) {
	struct arr__char text;
	struct mut_arr__ptr_failure* res;
	uint8_t err_file__q;
	struct lint_file__arr__ptr_failure__arr__char__lambda0___closure* temp0;
	text = read_file__arr__char__arr__char(ctx, path);
	res = new_mut_arr__ptr_mut_arr__ptr_failure(ctx);
	err_file__q = _op_equal_equal__bool__arr__char__arr__char(force__arr__char__opt__arr__char(ctx, get_extension__opt__arr__char__arr__char(ctx, path)), (struct arr__char) {3, "err"});
	each_with_index___void__arr__arr__char__fun_mut2___void__arr__char__nat(ctx, lines__arr__arr__char__arr__char(ctx, text), (struct fun_mut2___void__arr__char__nat) {(fun_ptr4___void__ptr_ctx__ptr__byte__arr__char__nat) lint_file__arr__ptr_failure__arr__char__lambda0, (uint8_t*) (temp0 = (struct lint_file__arr__ptr_failure__arr__char__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct lint_file__arr__ptr_failure__arr__char__lambda0___closure)), ((*(temp0) = (struct lint_file__arr__ptr_failure__arr__char__lambda0___closure) {err_file__q, res, path}, 0), temp0))});
	return freeze__arr__ptr_failure__ptr_mut_arr__ptr_failure(res);
}
struct arr__char read_file__arr__char__arr__char(struct ctx* ctx, struct arr__char path) {
	struct some__arr__char s;
	struct opt__arr__char matched;
	matched = try_read_file__opt__arr__char__arr__char(ctx, path);
	switch (matched.kind) {
		case 0:
			print_sync___void__arr__char(_op_plus__arr__char__arr__char__arr__char(ctx, (struct arr__char) {21, "file does not exist: "}, path));
			return (struct arr__char) {0, ""};
		case 1:
			s = matched.as1;
			return s.value;
		default:
			return (assert(0),(struct arr__char) {0, NULL});
	}
}
uint8_t each_with_index___void__arr__arr__char__fun_mut2___void__arr__char__nat(struct ctx* ctx, struct arr__arr__char a, struct fun_mut2___void__arr__char__nat f) {
	return each_with_index_recur___void__arr__arr__char__fun_mut2___void__arr__char__nat__nat(ctx, a, f, 0);
}
uint8_t each_with_index_recur___void__arr__arr__char__fun_mut2___void__arr__char__nat__nat(struct ctx* ctx, struct arr__arr__char a, struct fun_mut2___void__arr__char__nat f, uint64_t n) {
	struct ctx* _tailCallctx;
	struct arr__arr__char _tailCalla;
	struct fun_mut2___void__arr__char__nat _tailCallf;
	uint64_t _tailCalln;
	top:
	if (_op_equal_equal__bool__nat__nat(n, a.size)) {
		return 0;
	} else {
		call___void__fun_mut2___void__arr__char__nat__arr__char__nat(ctx, f, at__arr__char__arr__arr__char__nat(ctx, a, n), n);
		_tailCallctx = ctx;
		_tailCalla = a;
		_tailCallf = f;
		_tailCalln = incr__nat__nat(ctx, n);
		ctx = _tailCallctx;
		a = _tailCalla;
		f = _tailCallf;
		n = _tailCalln;
		goto top;
	}
}
uint8_t call___void__fun_mut2___void__arr__char__nat__arr__char__nat(struct ctx* ctx, struct fun_mut2___void__arr__char__nat f, struct arr__char p0, uint64_t p1) {
	return call_with_ctx___void__ptr_ctx__fun_mut2___void__arr__char__nat__arr__char__nat(ctx, f, p0, p1);
}
uint8_t call_with_ctx___void__ptr_ctx__fun_mut2___void__arr__char__nat__arr__char__nat(struct ctx* c, struct fun_mut2___void__arr__char__nat f, struct arr__char p0, uint64_t p1) {
	return f.fun_ptr(c, f.closure, p0, p1);
}
struct arr__arr__char lines__arr__arr__char__arr__char(struct ctx* ctx, struct arr__char s) {
	struct mut_arr__arr__char* res;
	struct cell__nat* last_nl;
	struct lines__arr__arr__char__arr__char__lambda0___closure* temp0;
	res = new_mut_arr__ptr_mut_arr__arr__char(ctx);
	last_nl = new_cell__ptr_cell__nat__nat(ctx, 0);
	each_with_index___void__arr__char__fun_mut2___void__char__nat(ctx, s, (struct fun_mut2___void__char__nat) {(fun_ptr4___void__ptr_ctx__ptr__byte__char__nat) lines__arr__arr__char__arr__char__lambda0, (uint8_t*) (temp0 = (struct lines__arr__arr__char__arr__char__lambda0___closure*) alloc__ptr__byte__nat(ctx, sizeof(struct lines__arr__arr__char__arr__char__lambda0___closure)), ((*(temp0) = (struct lines__arr__arr__char__arr__char__lambda0___closure) {res, s, last_nl}, 0), temp0))});
	push___void__ptr_mut_arr__arr__char__arr__char(ctx, res, slice_from_to__arr__char__arr__char__nat__nat(ctx, s, get__nat__ptr_cell__nat(last_nl), s.size));
	return freeze__arr__arr__char__ptr_mut_arr__arr__char(res);
}
struct cell__nat* new_cell__ptr_cell__nat__nat(struct ctx* ctx, uint64_t value) {
	struct cell__nat* temp0;
	temp0 = (struct cell__nat*) alloc__ptr__byte__nat(ctx, sizeof(struct cell__nat));
	(*(temp0) = (struct cell__nat) {value}, 0);
	return temp0;
}
uint8_t each_with_index___void__arr__char__fun_mut2___void__char__nat(struct ctx* ctx, struct arr__char a, struct fun_mut2___void__char__nat f) {
	return each_with_index_recur___void__arr__char__fun_mut2___void__char__nat__nat(ctx, a, f, 0);
}
uint8_t each_with_index_recur___void__arr__char__fun_mut2___void__char__nat__nat(struct ctx* ctx, struct arr__char a, struct fun_mut2___void__char__nat f, uint64_t n) {
	struct ctx* _tailCallctx;
	struct arr__char _tailCalla;
	struct fun_mut2___void__char__nat _tailCallf;
	uint64_t _tailCalln;
	top:
	if (_op_equal_equal__bool__nat__nat(n, a.size)) {
		return 0;
	} else {
		call___void__fun_mut2___void__char__nat__char__nat(ctx, f, at__char__arr__char__nat(ctx, a, n), n);
		_tailCallctx = ctx;
		_tailCalla = a;
		_tailCallf = f;
		_tailCalln = incr__nat__nat(ctx, n);
		ctx = _tailCallctx;
		a = _tailCalla;
		f = _tailCallf;
		n = _tailCalln;
		goto top;
	}
}
uint8_t call___void__fun_mut2___void__char__nat__char__nat(struct ctx* ctx, struct fun_mut2___void__char__nat f, char p0, uint64_t p1) {
	return call_with_ctx___void__ptr_ctx__fun_mut2___void__char__nat__char__nat(ctx, f, p0, p1);
}
uint8_t call_with_ctx___void__ptr_ctx__fun_mut2___void__char__nat__char__nat(struct ctx* c, struct fun_mut2___void__char__nat f, char p0, uint64_t p1) {
	return f.fun_ptr(c, f.closure, p0, p1);
}
struct arr__char slice_from_to__arr__char__arr__char__nat__nat(struct ctx* ctx, struct arr__char a, uint64_t begin, uint64_t end) {
	assert___void__bool(ctx, _op_less_equal__bool__nat__nat(begin, end));
	return slice__arr__char__arr__char__nat__nat(ctx, a, begin, _op_minus__nat__nat__nat(ctx, end, begin));
}
uint64_t swap__nat__ptr_cell__nat__nat(struct cell__nat* c, uint64_t v) {
	uint64_t res;
	res = get__nat__ptr_cell__nat(c);
	set___void__ptr_cell__nat__nat(c, v);
	return res;
}
uint64_t get__nat__ptr_cell__nat(struct cell__nat* c) {
	return c->value;
}
uint8_t set___void__ptr_cell__nat__nat(struct cell__nat* c, uint64_t v) {
	return (c->value = v, 0);
}
uint8_t lines__arr__arr__char__arr__char__lambda0(struct ctx* ctx, struct lines__arr__arr__char__arr__char__lambda0___closure* _closure, char c, uint64_t index) {
	if (_op_equal_equal__bool__char__char(c, literal__char__arr__char((struct arr__char) {1, "\n"}))) {
		return push___void__ptr_mut_arr__arr__char__arr__char(ctx, _closure->res, slice_from_to__arr__char__arr__char__nat__nat(ctx, _closure->s, swap__nat__ptr_cell__nat__nat(_closure->last_nl, incr__nat__nat(ctx, index)), index));
	} else {
		return 0;
	}
}
uint8_t contains_subsequence__q__bool__arr__char__arr__char(struct ctx* ctx, struct arr__char a, struct arr__char subseq) {
	return (starts_with__q__bool__arr__char__arr__char(ctx, a, subseq) || (has__q__bool__arr__char(a) && starts_with__q__bool__arr__char__arr__char(ctx, tail__arr__char__arr__char(ctx, a), subseq)));
}
uint8_t has__q__bool__arr__char(struct arr__char a) {
	return !empty__q__bool__arr__char(a);
}
struct arr__char lstrip__arr__char__arr__char(struct ctx* ctx, struct arr__char a) {
	struct ctx* _tailCallctx;
	struct arr__char _tailCalla;
	top:
	if ((has__q__bool__arr__char(a) && _op_equal_equal__bool__char__char(first__char__arr__char(ctx, a), literal__char__arr__char((struct arr__char) {1, " "})))) {
		_tailCallctx = ctx;
		_tailCalla = tail__arr__char__arr__char(ctx, a);
		ctx = _tailCallctx;
		a = _tailCalla;
		goto top;
	} else {
		return a;
	}
}
uint64_t line_len__nat__arr__char(struct ctx* ctx, struct arr__char line) {
	return _op_plus__nat__nat__nat(ctx, _op_times__nat__nat__nat(ctx, n_tabs__nat__arr__char(ctx, line), _op_minus__nat__nat__nat(ctx, tab_size__nat(ctx), literal__nat__arr__char(ctx, (struct arr__char) {1, "1"}))), line.size);
}
uint64_t n_tabs__nat__arr__char(struct ctx* ctx, struct arr__char line) {
	if ((!empty__q__bool__arr__char(line) && _op_equal_equal__bool__char__char(first__char__arr__char(ctx, line), literal__char__arr__char((struct arr__char) {1, "\t"})))) {
		return incr__nat__nat(ctx, n_tabs__nat__arr__char(ctx, tail__arr__char__arr__char(ctx, line)));
	} else {
		return 0;
	}
}
uint64_t tab_size__nat(struct ctx* ctx) {
	return literal__nat__arr__char(ctx, (struct arr__char) {1, "4"});
}
uint64_t max_line_length__nat(struct ctx* ctx) {
	return literal__nat__arr__char(ctx, (struct arr__char) {3, "120"});
}
uint8_t lint_file__arr__ptr_failure__arr__char__lambda0(struct ctx* ctx, struct lint_file__arr__ptr_failure__arr__char__lambda0___closure* _closure, struct arr__char line, uint64_t line_num) {
	struct arr__char ln;
	struct arr__char message;
	uint64_t width;
	struct arr__char message1;
	struct failure* temp0;
	struct failure* temp1;
	ln = to_str__arr__char__nat(ctx, incr__nat__nat(ctx, line_num));
	if ((!_closure->err_file__q && contains_subsequence__q__bool__arr__char__arr__char(ctx, lstrip__arr__char__arr__char(ctx, line), (struct arr__char) {2, "  "}))) {
		message = _op_plus__arr__char__arr__char__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, (struct arr__char) {5, "line "}, ln), (struct arr__char) {24, " contains a double space"});
		push___void__ptr_mut_arr__ptr_failure__ptr_failure(ctx, _closure->res, (temp0 = (struct failure*) alloc__ptr__byte__nat(ctx, sizeof(struct failure)), ((*(temp0) = (struct failure) {_closure->path, message}, 0), temp0)));
	} else {
		0;
	}
	width = line_len__nat__arr__char(ctx, line);
	if (_op_greater__bool__nat__nat(width, max_line_length__nat(ctx))) {
		message1 = _op_plus__arr__char__arr__char__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, (struct arr__char) {5, "line "}, ln), (struct arr__char) {4, " is "}), to_str__arr__char__nat(ctx, width)), (struct arr__char) {28, " columns long, should be <= "}), to_str__arr__char__nat(ctx, max_line_length__nat(ctx)));
		return push___void__ptr_mut_arr__ptr_failure__ptr_failure(ctx, _closure->res, (temp1 = (struct failure*) alloc__ptr__byte__nat(ctx, sizeof(struct failure)), ((*(temp1) = (struct failure) {_closure->path, message1}, 0), temp1)));
	} else {
		return 0;
	}
}
struct arr__ptr_failure lint__result__arr__char__arr__ptr_failure__arr__char__test_options__lambda0(struct ctx* ctx, struct lint__result__arr__char__arr__ptr_failure__arr__char__test_options__lambda0___closure* _closure, struct arr__char file) {
	if (_closure->options.print_tests__q) {
		print_sync___void__arr__char(_op_plus__arr__char__arr__char__arr__char(ctx, (struct arr__char) {5, "lint "}, file));
	} else {
		0;
	}
	return lint_file__arr__ptr_failure__arr__char(ctx, file);
}
struct result__arr__char__arr__ptr_failure do_test__int32__test_options__lambda1(struct ctx* ctx, struct do_test__int32__test_options__lambda1___closure* _closure) {
	return lint__result__arr__char__arr__ptr_failure__arr__char__test_options(ctx, _closure->noze_path, _closure->options);
}
int32_t print_failures__int32__result__arr__char__arr__ptr_failure__test_options(struct ctx* ctx, struct result__arr__char__arr__ptr_failure failures, struct test_options options) {
	struct ok__arr__char o;
	struct err__arr__ptr_failure e;
	uint64_t n_failures;
	struct result__arr__char__arr__ptr_failure matched;
	matched = failures;
	switch (matched.kind) {
		case 0:
			o = matched.as0;
			print_sync___void__arr__char(o.value);
			return literal__int32__arr__char(ctx, (struct arr__char) {1, "0"});
		case 1:
			e = matched.as1;
			each___void__arr__ptr_failure__fun_mut1___void__ptr_failure(ctx, e.value, (struct fun_mut1___void__ptr_failure) {(fun_ptr3___void__ptr_ctx__ptr__byte__ptr_failure) print_failures__int32__result__arr__char__arr__ptr_failure__test_options__lambda0, (uint8_t*) NULL});
			n_failures = e.value.size;
			print_sync___void__arr__char((_op_equal_equal__bool__nat__nat(n_failures, options.max_failures) ? _op_plus__arr__char__arr__char__arr__char(ctx, _op_plus__arr__char__arr__char__arr__char(ctx, (struct arr__char) {15, "hit maximum of "}, to_str__arr__char__nat(ctx, options.max_failures)), (struct arr__char) {9, " failures"}) : _op_plus__arr__char__arr__char__arr__char(ctx, to_str__arr__char__nat(ctx, n_failures), (struct arr__char) {9, " failures"})));
			return to_int32__int32__nat(ctx, n_failures);
		default:
			return (assert(0),0);
	}
}
uint8_t print_failure___void__ptr_failure(struct ctx* ctx, struct failure* failure) {
	print_bold___void(ctx);
	print_sync_no_newline___void__arr__char(failure->path);
	print_reset___void(ctx);
	print_sync_no_newline___void__arr__char((struct arr__char) {1, " "});
	return print_sync___void__arr__char(failure->message);
}
uint8_t print_bold___void(struct ctx* ctx) {
	return print_sync_no_newline___void__arr__char((struct arr__char) {4, "\x1b[1m"});
}
uint8_t print_reset___void(struct ctx* ctx) {
	return print_sync_no_newline___void__arr__char((struct arr__char) {3, "\x1b[m"});
}
uint8_t print_failures__int32__result__arr__char__arr__ptr_failure__test_options__lambda0(struct ctx* ctx, uint8_t* _closure, struct failure* it) {
	return print_failure___void__ptr_failure(ctx, it);
}
int32_t to_int32__int32__nat(struct ctx* ctx, uint64_t n) {
	assert___void__bool(ctx, _op_less__bool__nat__nat(n, million__nat()));
	return n;
}
int32_t main(int32_t argc, char** argv) {
	return rt_main__int32__int32__ptr__ptr__char__fun_ptr2__ptr_fut__int32__ptr_ctx__arr__arr__char(argc, argv, main__ptr_fut__int32__arr__arr__char);
}
